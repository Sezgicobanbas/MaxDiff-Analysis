"""
MaxDiff (Best-Worst Scaling) -- analysis of real survey data
============================================================
Input : maxdiff_responses.csv  (wide format, one row per respondent x task)
        RespondentID, AgeGroup, Gender, Task, Item1..Item4, Best, Worst

0. Load & validate
1. Method 1: Counting analysis
2. Method 2: Aggregate multinomial logit (conditional logit)
3. Method 3: Hierarchical Bayes (individual-level utilities, PyMC)
4. Rescaling (probability scale / share of preference)
5. Validation (hit rate) and segmentation (k-means + demographics)
6. Charts and export
"""
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from statsmodels.discrete.conditional_models import ConditionalLogit
from sklearn.cluster import KMeans

# ----------------------------------------------------------------------
# 0. LOAD & VALIDATE
# ----------------------------------------------------------------------
CSV_PATH = "maxdiff_responses.csv"
SEED = 42

df = (pd.read_csv(CSV_PATH)
        .sort_values(["RespondentID", "Task"])
        .reset_index(drop=True))

item_cols = [c for c in df.columns if c.startswith("Item")]
k = len(item_cols)                                            # items shown per task
items = sorted(pd.unique(df[item_cols].values.ravel()))       # alphabetical, stable order
K = len(items)                                                # total number of items
item_id = {name: i for i, name in enumerate(items)}

# Respondents are re-indexed 0..N-1 (the PyMC model needs contiguous ids)
resp_codes, resp_labels = pd.factorize(df["RespondentID"])
N = len(resp_labels)
n_obs = len(df)                                               # number of tasks answered (all respondents)

# Integer arrays at the task level
shown_idx = df[item_cols].apply(lambda c: c.map(item_id)).values     # (n_obs, k) item ids
best_idx = df["Best"].map(item_id).values
worst_idx = df["Worst"].map(item_id).values
best_pos = (shown_idx == best_idx[:, None]).argmax(axis=1)           # position of BEST in the task
worst_pos = (shown_idx == worst_idx[:, None]).argmax(axis=1)         # position of WORST in the task
resp_idx = resp_codes                                                # respondent per task
row = np.arange(n_obs)

# Sanity checks
assert df[item_cols + ["Best", "Worst"]].notna().all().all(), "Missing values found"
assert (shown_idx == best_idx[:, None]).any(axis=1).all(), "Best item not among shown items"
assert (shown_idx == worst_idx[:, None]).any(axis=1).all(), "Worst item not among shown items"
assert (best_idx != worst_idx).all(), "Best and Worst are identical in some tasks"
assert (df[item_cols].nunique(axis=1) == k).all(), "Duplicate item within a task"

print(f"{N} respondents | {n_obs} tasks | {K} items | {k} items per task")
print(f"Each item shown {np.bincount(shown_idx.ravel(), minlength=K).mean():.0f} times in total\n")

# Long format (one row per item shown) -- used for the counting analysis
long = pd.DataFrame({
    "resp": np.repeat(resp_idx, k),
    "task": np.repeat(df["Task"].values, k),
    "item": shown_idx.ravel(),
})
long["best"] = (long["item"].values == np.repeat(best_idx, k)).astype(int)
long["worst"] = (long["item"].values == np.repeat(worst_idx, k)).astype(int)

# Respondent-level demographics (for segment profiling later)
demo = df.drop_duplicates("RespondentID").set_index("RespondentID").loc[resp_labels, ["AgeGroup", "Gender"]]


# ----------------------------------------------------------------------
# 1. METHOD 1 -- COUNTING ANALYSIS
# ----------------------------------------------------------------------
cnt = long.groupby("item").agg(shown=("best", "size"), best=("best", "sum"), worst=("worst", "sum"))
cnt["best_pct"] = cnt.best / cnt.shown
cnt["worst_pct"] = cnt.worst / cnt.shown
cnt["bw_score"] = (cnt.best - cnt.worst) / cnt.shown                 # -1 ... +1
ratio = np.sqrt(cnt.best / cnt.worst)                                # square-root-of-ratio score
cnt["sqrt_ratio_100"] = 100 * ratio / ratio.max()                    # best item = 100
cnt.insert(0, "label", items)
print(cnt.round(3).sort_values("bw_score", ascending=False), "\n")


# ----------------------------------------------------------------------
# 2. METHOD 2 -- AGGREGATE MULTINOMIAL LOGIT (CONDITIONAL LOGIT)
# ----------------------------------------------------------------------
# Effects coding: K-1 columns; the last item = -(sum of the others),
# so the K utilities are automatically zero-centred.
A = np.vstack([np.eye(K - 1), -np.ones((1, K - 1))])                 # K x (K-1)
X_item = np.eye(K)[long["item"].values] @ A                          # one coded row per item shown

# Every task becomes TWO choice sets:
#   BEST set : design = +X, chosen row = best item
#   WORST set: design = -X (sign flipped), chosen row = worst item
grp = np.repeat(np.arange(n_obs), k) * 2
stack_y = np.r_[long["best"].values, long["worst"].values]
stack_X = np.vstack([X_item, -X_item])
stack_g = np.r_[grp, grp + 1]

fit = ConditionalLogit(stack_y, stack_X, groups=stack_g).fit(disp=False)
theta, V = fit.params, fit.cov_params()
u_agg = A @ theta                                                    # K utilities (zero-centred)
se_agg = np.sqrt(np.diag(A @ V @ A.T))                               # delta method for the K-th item too

# McFadden rho^2 vs. the null of random choice (1/k per choice set, 2 sets per task)
ll_null = -2 * n_obs * np.log(k)
rho2 = 1 - fit.llf / ll_null
print(f"Aggregate logit: logLik={fit.llf:.1f}, null={ll_null:.1f}, rho2={rho2:.3f}")

agg = pd.DataFrame({"label": items, "utility": u_agg, "se": se_agg})
agg["ci_low"], agg["ci_high"] = agg.utility - 1.96 * agg.se, agg.utility + 1.96 * agg.se
print(agg.round(3).sort_values("utility", ascending=False), "\n")


# ----------------------------------------------------------------------
# 3. METHOD 3 -- HIERARCHICAL BAYES (individual-level utilities)
# ----------------------------------------------------------------------
import pymc as pm
import pytensor.tensor as pt

with pm.Model() as hb:
    # Upper level: population mean and spread of utilities (K-1 effects-coded)
    mu = pm.Normal("mu", 0, 2, shape=K - 1)
    sigma = pm.HalfNormal("sigma", 1.5, shape=K - 1)
    # Lower level: each respondent = mean + spread * z   (non-centred parameterisation)
    z = pm.Normal("z", 0, 1, shape=(N, K - 1))
    beta = mu + sigma * z
    U = pm.Deterministic("U", pt.concatenate([beta, -beta.sum(axis=1, keepdims=True)], axis=1))  # N x K

    u_shown = U[resp_idx[:, None], shown_idx]                                  # (n_obs, k)
    ll_best = u_shown[row, best_pos] - pm.math.logsumexp(u_shown, axis=1)
    ll_worst = -u_shown[row, worst_pos] - pm.math.logsumexp(-u_shown, axis=1)
    pm.Potential("likelihood", ll_best.sum() + ll_worst.sum())

    idata = pm.sample(draws=1000, tune=1000, chains=4, target_accept=0.9,
                      cores=max(1, min(4, os.cpu_count() or 1)),
                      random_seed=SEED, progressbar=False)

U_hb = idata.posterior["U"].mean(dim=("chain", "draw")).values                 # N x K posterior means
print("Mean HB utilities:", dict(zip(items, U_hb.mean(0).round(2))), "\n")


# ----------------------------------------------------------------------
# 4. RESCALING
# ----------------------------------------------------------------------
# (a) Probability scale: chance an item is picked BEST from a task of k items
#     when the other k-1 items have average utility (0).
P = np.exp(U_hb) / (np.exp(U_hb) + k - 1)
# (b) Share of preference: sums to 100 % per respondent.
S = np.exp(U_hb) / np.exp(U_hb).sum(axis=1, keepdims=True)

result = pd.DataFrame({
    "label": items,
    "count_bw": cnt.bw_score.values,
    "logit_utility": u_agg,
    "hb_utility": U_hb.mean(0),
    "hb_prob_best_%": 100 * P.mean(0),
    "hb_share_%": 100 * S.mean(0),
}).sort_values("hb_utility", ascending=False)
print(result.round(2), "\n")


# ----------------------------------------------------------------------
# 5. VALIDATION & SEGMENTATION
# ----------------------------------------------------------------------
# Hit rate: does the highest-utility item in the task match the actual BEST pick?
u_task = U_hb[resp_idx[:, None], shown_idx]
hit_best = (u_task.argmax(1) == best_pos).mean()
hit_worst = (u_task.argmin(1) == worst_pos).mean()
print(f"Hit rate best={hit_best:.1%}, worst={hit_worst:.1%} (chance = {1 / k:.0%})\n")

# 5a. Data-driven segments: k-means on individual utilities
seg = KMeans(n_clusters=3, n_init=25, random_state=SEED).fit_predict(U_hb)
profile = pd.DataFrame(U_hb, columns=items).groupby(seg).mean().round(2)
profile["n"] = np.bincount(seg)
print("Segment profiles (mean HB utility):")
print(profile.T, "\n")

# 5b. Demographic segments: mean share of preference (%) by Age group and Gender
share_df = pd.DataFrame(100 * S, columns=items)
share_by_age = share_df.groupby(demo["AgeGroup"].values).mean().T.round(1)
share_by_gender = share_df.groupby(demo["Gender"].values).mean().T.round(1)
print("Share of preference (%) by age group:\n", share_by_age, "\n")
print("Share of preference (%) by gender:\n", share_by_gender, "\n")


# ----------------------------------------------------------------------
# 6. CHARTS & EXPORT
# ----------------------------------------------------------------------
order = result.sort_values("hb_utility")
fig, ax = plt.subplots(1, 2, figsize=(13, 6))
ax[0].barh(order.label, order.hb_utility, color="#1f6feb")
ax[0].set_title("HB mean utility (zero-centred)")
a2 = agg.set_index("label").loc[order.label]
ax[1].errorbar(a2.utility, range(K), xerr=1.96 * a2.se, fmt="o", color="#d1242f", capsize=3)
ax[1].set_yticks(range(K), order.label)
ax[1].axvline(0, color="grey", lw=0.8)
ax[1].set_title("Aggregate logit utility, 95% CI")
plt.tight_layout()
plt.savefig("maxdiff_results.png", dpi=150)

with pd.ExcelWriter("maxdiff_results.xlsx") as xw:
    result.to_excel(xw, sheet_name="summary", index=False)
    cnt.to_excel(xw, sheet_name="counts")
    agg.to_excel(xw, sheet_name="aggregate_logit", index=False)
    share_by_age.to_excel(xw, sheet_name="share_by_age")
    share_by_gender.to_excel(xw, sheet_name="share_by_gender")
    (pd.DataFrame(U_hb, columns=items)
       .assign(RespondentID=resp_labels, AgeGroup=demo["AgeGroup"].values,
               Gender=demo["Gender"].values, segment=seg)
       .to_excel(xw, sheet_name="individual_utilities", index=False))
print("Done.")