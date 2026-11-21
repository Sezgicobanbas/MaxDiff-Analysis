# =====================================================================
# MaxDiff (Best-Worst Scaling) -- analysis of real survey data in R
# =====================================================================
# Input : maxdiff_responses.csv  (wide format, one row per respondent x task)
#         RespondentID, AgeGroup, Gender, Task, Item1..Item4, Best, Worst
#
# 0. Load & validate
# 1. Method 1: Counting analysis
# 2. Method 2: Aggregate multinomial logit (conditional logit, survival::clogit)
# 3. Method 3: Hierarchical Bayes (bayesm::rhierMnlRwMixture)
# 4. Rescaling (probability scale / share of preference)
# 5. Validation (hit rate) and segmentation (k-means + demographics)
# 6. Charts and export
# =====================================================================
# install.packages(c("survival", "bayesm", "dplyr", "tidyr", "ggplot2", "writexl"))
library(dplyr)
library(tidyr)
library(ggplot2)
library(survival)   # clogit()
library(bayesm)     # rhierMnlRwMixture()
library(writexl)

set.seed(42)

# ---------------------------------------------------------------------
# 0. LOAD & VALIDATE
# ---------------------------------------------------------------------
csv_path <- "maxdiff_responses.csv"

raw <- read.csv(csv_path, stringsAsFactors = FALSE) |>
  arrange(RespondentID, Task)

item_cols <- grep("^Item", names(raw), value = TRUE)
k     <- length(item_cols)                                   # items shown per task
items <- sort(unique(unlist(raw[item_cols])))                # alphabetical, stable order
K     <- length(items)                                       # total number of items

resp_labels <- unique(raw$RespondentID)
N           <- length(resp_labels)
n_obs       <- nrow(raw)                                     # tasks answered (all respondents)

# Integer matrices at the task level
shown_idx <- sapply(item_cols, function(cn) match(raw[[cn]], items))   # n_obs x k item ids
best_idx  <- match(raw$Best,  items)
worst_idx <- match(raw$Worst, items)
best_pos  <- apply(shown_idx == best_idx,  1, which)                   # position of BEST in the task
worst_pos <- apply(shown_idx == worst_idx, 1, which)                   # position of WORST in the task
resp_idx  <- match(raw$RespondentID, resp_labels)                      # respondent index 1..N

# Sanity checks
stopifnot(!anyNA(raw[c(item_cols, "Best", "Worst")]),
          !anyNA(best_idx), !anyNA(worst_idx),
          is.numeric(best_pos), is.numeric(worst_pos),     # fails if best/worst not among shown items
          all(best_idx != worst_idx),
          all(apply(shown_idx, 1, function(r) length(unique(r))) == k))

cat(sprintf("%d respondents | %d tasks | %d items | %d items per task\n", N, n_obs, K, k))
cat(sprintf("Each item shown %.0f times in total\n\n", mean(tabulate(as.vector(shown_idx), K))))

# Long format: one row per item shown, sorted by resp, task, pos
long <- tibble(
  resp  = rep(resp_idx, each = k),
  task  = rep(raw$Task, each = k),
  tid   = rep(seq_len(n_obs), each = k),                     # unique task id
  pos   = rep(seq_len(k), times = n_obs),
  item  = as.vector(t(shown_idx))
) |>
  mutate(best  = as.integer(item == rep(best_idx,  each = k)),
         worst = as.integer(item == rep(worst_idx, each = k)))

# Respondent-level demographics (for profiling later)
demo <- raw |>
  distinct(RespondentID, .keep_all = TRUE) |>
  select(RespondentID, AgeGroup, Gender)

# ---------------------------------------------------------------------
# 1. METHOD 1 -- COUNTING ANALYSIS
# ---------------------------------------------------------------------
counts <- long |>
  group_by(item) |>
  summarise(shown = n(), best = sum(best), worst = sum(worst), .groups = "drop") |>
  mutate(label          = items[item],
         best_pct       = best / shown,
         worst_pct      = worst / shown,
         bw_score       = (best - worst) / shown,                   # -1 ... +1
         sqrt_ratio     = sqrt(best / worst),
         sqrt_ratio_100 = 100 * sqrt_ratio / max(sqrt_ratio)) |>   # best item = 100
  arrange(desc(bw_score))
print(counts, width = Inf)

# ---------------------------------------------------------------------
# 2. METHOD 2 -- AGGREGATE MULTINOMIAL LOGIT (conditional logit)
# ---------------------------------------------------------------------
# Effects coding: K-1 columns; item K = -(sum of the others), so the K
# utilities are zero-centred automatically.
A <- rbind(diag(K - 1), -1)                                         # K x (K-1)
X <- diag(K)[long$item, ] %*% A                                     # coded row per item shown
colnames(X) <- paste0("b", seq_len(K - 1))

# Every task becomes TWO choice sets:
#   BEST set : design = +X, chosen row = best item
#   WORST set: design = -X (sign flipped), chosen row = worst item
best_set  <- data.frame(stratum = paste(long$tid, "B"), y = long$best,  X)
worst_set <- data.frame(stratum = paste(long$tid, "W"), y = long$worst, -X)
stacked   <- rbind(best_set, worst_set)

form <- reformulate(c(colnames(X), "strata(stratum)"), response = "y")
fit  <- clogit(form, data = stacked)

theta  <- coef(fit)
V      <- vcov(fit)
u_agg  <- as.vector(A %*% theta)                                    # K utilities, zero-centred
se_agg <- sqrt(diag(A %*% V %*% t(A)))                              # delta method (incl. item K)

ll_null <- -2 * n_obs * log(k)                                      # random-choice benchmark
rho2    <- 1 - as.numeric(logLik(fit)) / ll_null                    # McFadden rho^2
cat(sprintf("\nAggregate logit: logLik = %.1f, null = %.1f, rho2 = %.3f\n",
            as.numeric(logLik(fit)), ll_null, rho2))

agg <- tibble(label = items, utility = u_agg, se = se_agg,
              ci_low = u_agg - 1.96 * se_agg, ci_high = u_agg + 1.96 * se_agg) |>
  arrange(desc(utility))
print(agg)

# How to read the table:
#   utility : part-worth, zero-centred. > 0 = preferred over the average item,
#             < 0 = less preferred than average (not necessarily disliked).
#   se      : precision of the estimate (smaller = more precise).
#   ci_low / ci_high : 95% confidence interval. If it crosses 0, the item is
#             statistically indistinguishable from the average.

# ---------------------------------------------------------------------
# 3. METHOD 3 -- HIERARCHICAL BAYES (individual-level utilities)
# ---------------------------------------------------------------------
# bayesm wants, per respondent: y = chosen position in each choice set,
# X = stacked design rows (p = k rows per choice set).
# Sets 1..T = best sets (+X), sets T+1..2T = worst sets (-X).
lgtdata <- lapply(seq_len(N), function(i) {
  rows <- which(raw$RespondentID == resp_labels[i])             # this respondent's tasks (sorted by Task)
  Xi   <- diag(K)[as.vector(t(shown_idx[rows, , drop = FALSE])), ] %*% A   # rows ordered by task, then pos
  list(y = as.integer(c(best_pos[rows], worst_pos[rows])),
       X = rbind(Xi, -Xi))
})

R_iter <- 20000; keep <- 10
out <- rhierMnlRwMixture(
  Data  = list(p = k, lgtdata = lgtdata),
  Prior = list(ncomp = 1),                                          # one normal population distribution
  Mcmc  = list(R = R_iter, keep = keep, nprint = 0)
)

draws <- dim(out$betadraw)[3]                                       # N x (K-1) x draws
burn  <- draws %/% 2                                                # discard first half as burn-in
B_hb  <- apply(out$betadraw[, , (burn + 1):draws], c(1, 2), mean)   # posterior means, N x (K-1)
U_hb  <- B_hb %*% t(A)                                              # back to N x K utilities
colnames(U_hb) <- items

# ---------------------------------------------------------------------
# 4. RESCALING
# ---------------------------------------------------------------------
# (a) Probability scale: chance an item is picked BEST from a task of k items
#     when the other k-1 items have average utility (0).
P <- exp(U_hb) / (exp(U_hb) + k - 1)
# (b) Share of preference: sums to 100 % per respondent.
S <- exp(U_hb) / rowSums(exp(U_hb))

result <- tibble(label = items,
                 count_bw         = counts$bw_score[match(seq_len(K), counts$item)],
                 logit_utility    = u_agg,
                 hb_utility       = colMeans(U_hb),
                 `hb_prob_best_%` = 100 * colMeans(P),
                 `hb_share_%`     = 100 * colMeans(S)) |>
  arrange(desc(hb_utility))
print(result, width = Inf)

# ---------------------------------------------------------------------
# 5. VALIDATION & SEGMENTATION
# ---------------------------------------------------------------------
# Hit rate: does the highest-utility item in the task match the actual BEST pick?
u_task <- matrix(U_hb[cbind(rep(resp_idx, times = k), as.vector(shown_idx))], nrow = n_obs, ncol = k)
hit_best  <- mean(max.col(u_task,  ties.method = "first") == best_pos)
hit_worst <- mean(max.col(-u_task, ties.method = "first") == worst_pos)
cat(sprintf("\nHit rate best = %.1f%%, worst = %.1f%% (chance = %.0f%%)\n",
            100 * hit_best, 100 * hit_worst, 100 / k))

# 5a. Data-driven segments: k-means on individual utilities
km  <- kmeans(U_hb, centers = 3, nstart = 25)
seg <- km$cluster
seg_profile <- t(rbind(sapply(1:3, function(s) colMeans(U_hb[seg == s, , drop = FALSE])),
                       n = as.vector(table(seg))))
cat("\nSegment profiles (mean HB utility):\n")
print(round(t(seg_profile), 2))

# 5b. Demographic segments: mean share of preference (%) by Age group and Gender
share_df <- as.data.frame(100 * S)
share_by <- function(var) {
  share_df |>
    mutate(group = demo[[var]]) |>
    group_by(group) |>
    summarise(across(everything(), mean), .groups = "drop") |>
    pivot_longer(-group, names_to = "label", values_to = "share") |>
    pivot_wider(names_from = group, values_from = share) |>
    mutate(across(-label, ~ round(.x, 1)))
}
share_by_age    <- share_by("AgeGroup")
share_by_gender <- share_by("Gender")
cat("\nShare of preference (%) by age group:\n");  print(share_by_age, n = Inf)
cat("\nShare of preference (%) by gender:\n");     print(share_by_gender, n = Inf)

# ---------------------------------------------------------------------
# 6. CHARTS & EXPORT
# ---------------------------------------------------------------------
p1 <- ggplot(result, aes(x = reorder(label, hb_utility), y = hb_utility)) +
  geom_col(fill = "#1f6feb") + coord_flip() +
  labs(x = NULL, y = "HB mean utility (zero-centred)", title = "MaxDiff results") +
  theme_minimal(base_size = 12)
ggsave("maxdiff_results_R.png", p1, width = 8, height = 5, dpi = 150)

p2 <- ggplot(agg, aes(x = utility, y = reorder(label, utility))) +
  geom_vline(xintercept = 0, colour = "grey60") +
  geom_errorbarh(aes(xmin = ci_low, xmax = ci_high), height = 0.25, colour = "#d1242f") +
  geom_point(colour = "#d1242f", size = 2) +
  labs(x = "Aggregate logit utility (95% CI)", y = NULL) +
  theme_minimal(base_size = 12)
ggsave("maxdiff_logit_ci_R.png", p2, width = 8, height = 5, dpi = 150)

individual <- cbind(RespondentID = resp_labels,
                    demo[match(resp_labels, demo$RespondentID), c("AgeGroup", "Gender")],
                    as.data.frame(U_hb), segment = seg)

write_xlsx(list(summary              = result,
                counts               = counts,
                aggregate_logit      = agg,
                share_by_age         = share_by_age,
                share_by_gender      = share_by_gender,
                individual_utilities = individual),
           "maxdiff_results_R.xlsx")
cat("Done.\n")