# MaxDiff Study: What Drives the Online Shopping Experience

**Method:** Best-Worst Scaling (MaxDiff) | **Sample:** 300 respondents | **Items:** 12 | **Prepared:** 21 November 2026

---

## 1. Executive Summary

Price, trust and speed decide the shopping experience. Everything else is secondary.

- **Three drivers dominate.** Low prices, Secure payments and Fast delivery take **48%** of total preference.
- **Two more support them.** Free returns and Easy checkout add another 18%.
- **Four features barely register.** Loyalty rewards, Flexible payment options, Personalized recommendations and Eco-friendly packaging share only **12%** between them.
- **Eco-friendly packaging is last.** It is picked as *worst* in 50% of the tasks where it appears, and as *best* in 9%.
- **Wide product range is the one polarising feature.** For the 37% in Segment A it is the top-rated feature. The 18% in Segment C reject it more strongly than any other item.
- **Age and gender change very little.** Shares move by about 3 points or less across groups.

All three analysis methods (counting, aggregate logit, Hierarchical Bayes) produce the **same ranking**. The result is stable.

---

## 2. Study Design

| Parameter | Value |
|---|---|
| Respondents | 300 |
| Tasks per respondent | 9 |
| Items per task | 4 |
| Total items tested | 12 |
| Total choice tasks | 2,700 |
| Exposures per item | 900 (3 per respondent) |
| Respondent profile | Age: 25–34 (92), 35–44 (79), 18–24 (72), 45+ (57). Gender: Male 165, Female 135 |

**Task format.** In each task, respondents saw four features and picked the **most** and **least** important one.

**Items tested:** Low prices, Secure payments, Fast delivery, Free returns, Easy checkout, Wide product range, Product reviews, Customer support, Loyalty rewards, Flexible payment options, Personalized recommendations, Eco-friendly packaging.

### Data quality

| Check | Result |
|---|---|
| Missing values | None |
| Best and Worst picked from the items shown | 100% |
| Best equals Worst in the same task | 0 cases |
| Duplicate items within a task | 0 cases |
| Complete respondents (9 of 9 tasks) | 300 of 300 |
| Item exposure balance | Perfect (900 each) |

---

## 3. Methods

| Method | What it does | Used for |
|---|---|---|
| **Counting analysis** | Compares Best and Worst picks per item. | Fast, transparent baseline |
| **Aggregate logit** | Estimates one utility per item for the whole sample, with 95% confidence intervals. | Significance and uncertainty |
| **Hierarchical Bayes (HB)** | Estimates utilities for each respondent, pooling information across the sample. | Shares of preference, segmentation, demographic cuts |

**How to read the metrics**

- **Utility:** zero-centred. Above 0 is better than the average item, below 0 is worse.
- **Probability of Best:** the chance an item is picked as best in a task of 4, when the other three items are average. Random choice is 25%.
- **Share of preference:** sums to 100% across the 12 items. Read it as the item's slice of total importance.

---

## 4. Results

### 4.1 Overall ranking

| Rank | Feature | Count score (B−W) | Logit utility | HB utility | Prob. of Best | Share of preference |
|---|---|---|---|---|---|---|
| 1 | **Low prices** | +0.36 | 0.96 | 1.06 | 49.2% | **18.6%** |
| 2 | **Secure payments** | +0.32 | 0.83 | 0.92 | 45.8% | **16.4%** |
| 3 | **Fast delivery** | +0.23 | 0.61 | 0.68 | 40.1% | **12.9%** |
| 4 | Free returns | +0.14 | 0.38 | 0.42 | 34.0% | 9.8% |
| 5 | Easy checkout | +0.09 | 0.22 | 0.24 | 30.3% | 8.3% |
| 6 | Wide product range | 0.00 | −0.01 | 0.00 | 29.1% | 10.1% |
| 7 | Product reviews | −0.03 | −0.06 | −0.07 | 24.1% | 6.0% |
| 8 | Customer support | −0.06 | −0.16 | −0.17 | 22.3% | 5.4% |
| 9 | Loyalty rewards | −0.14 | −0.37 | −0.40 | 18.5% | 4.2% |
| 10 | Flexible payment options | −0.19 | −0.50 | −0.55 | 16.4% | 3.7% |
| 11 | Personalized recommendations | −0.31 | −0.82 | −0.91 | 12.1% | 2.6% |
| 12 | Eco-friendly packaging | −0.41 | −1.09 | −1.22 | 9.3% | 1.9% |

### 4.2 Four tiers of importance

| Tier | Features | Combined share | Read |
|---|---|---|---|
| **1. Core drivers** | Low prices, Secure payments, Fast delivery | 48.0% | Each is picked best in 38–46% of its appearances. |
| **2. Strong supporters** | Free returns, Easy checkout | 18.2% | Clearly positive utility. They back up the core. |
| **3. Neutral zone** | Wide product range, Product reviews, Customer support | 21.5% | Utilities near zero. Wide product range is polarising (see 4.4). |
| **4. Low priority** | Loyalty rewards, Flexible payment options, Personalized recommendations, Eco-friendly packaging | 12.4% | Picked worst far more often than best. |

### 4.3 How certain is the ranking?

From the aggregate logit (95% confidence intervals):

- **Price and Secure payments are statistically close.** Their intervals overlap (0.86–1.06 vs 0.73–0.94). Treat them as joint leaders.
- **Fast delivery is clearly third.** Its interval (0.51–0.71) sits below both leaders.
- **Wide product range is average.** Its interval (−0.11 to 0.10) includes zero.
- **Product reviews and Customer support are indistinguishable.** Their intervals overlap.
- **Eco-friendly packaging is clearly last.** Its interval (−1.20 to −0.99) does not overlap any other item.

Standard errors are tight (about 0.05) across all items.

### 4.4 Wide product range: the polarising feature

Wide product range ranks **6th on average utility** but **4th on share of preference** (10.1%). The average hides two opposing groups: respondents who rank it at or near the top, and those who push it to the bottom. The segmentation below separates them.

---

## 5. Segmentation

K-means clustering on individual HB utilities produced three segments.

| Segment | n | % of sample | Profile |
|---|---|---|---|
| **A. Range seekers** | 110 | 37% | Wide product range is the top feature (+1.11). Price and security come next. |
| **B. Balanced core** | 137 | 46% | Wide product range is slightly negative (−0.26). Price, security and delivery dominate. |
| **C. Range-rejecters** | 53 | 18% | Wide product range is rejected harder than any item (−1.64), below even Eco-friendly packaging. Higher scores on Easy checkout, Free returns and Product reviews. |

**Mean HB utility by segment**

| Feature | A | B | C |
|---|---|---|---|
| Low prices | 0.92 | 1.10 | 1.27 |
| Secure payments | 0.81 | 0.95 | 1.09 |
| Fast delivery | 0.58 | 0.72 | 0.82 |
| Free returns | 0.30 | 0.46 | 0.55 |
| Easy checkout | 0.10 | 0.28 | 0.43 |
| **Wide product range** | **1.11** | **−0.26** | **−1.64** |
| Product reviews | −0.19 | −0.06 | 0.13 |
| Customer support | −0.25 | −0.13 | −0.09 |
| Loyalty rewards | −0.49 | −0.38 | −0.27 |
| Flexible payment options | −0.65 | −0.50 | −0.48 |
| Personalized recommendations | −0.95 | −0.92 | −0.78 |
| Eco-friendly packaging | −1.30 | −1.24 | −1.02 |

**Interpretation**

- **One dimension drives the split.** The segments differ mainly on Wide product range. Utilities are zero-centred, so a strong negative on one item lifts the others. Segment C's higher scores elsewhere are partly this mechanical effect.
- **The core is shared.** Low prices, Secure payments and Fast delivery rank in the top four in every segment.
- **The bottom is shared too.** Apart from Wide product range in Segment C, Eco-friendly packaging and Personalized recommendations sit lowest in every segment.

---

## 6. Demographic Differences

### Share of preference (%) by age group

| Feature | 18–24 | 25–34 | 35–44 | 45+ |
|---|---|---|---|---|
| Low prices | 20.2 | 17.8 | 19.1 | 17.5 |
| Secure payments | 16.3 | 16.4 | 15.7 | 17.7 |
| Fast delivery | 12.6 | 12.8 | 13.3 | 12.9 |
| Free returns | 9.3 | 10.2 | 10.3 | 9.2 |
| Wide product range | 9.1 | 11.0 | 9.4 | 10.7 |
| Easy checkout | 8.5 | 8.3 | 8.6 | 7.8 |
| Product reviews | 6.3 | 5.8 | 5.9 | 6.2 |
| Customer support | 5.2 | 5.4 | 5.2 | 6.0 |
| Loyalty rewards | 4.1 | 4.4 | 4.4 | 3.9 |
| Flexible payment options | 3.7 | 3.5 | 3.7 | 3.7 |
| Personalized recommendations | 2.6 | 2.6 | 2.7 | 2.4 |
| Eco-friendly packaging | 2.2 | 1.8 | 1.8 | 1.9 |

### Share of preference (%) by gender

| Feature | Female | Male |
|---|---|---|
| Low prices | 18.4 | 18.8 |
| Secure payments | 16.8 | 16.2 |
| Fast delivery | 13.4 | 12.5 |
| Free returns | 9.2 | 10.3 |
| Wide product range | 9.9 | 10.2 |
| Easy checkout | 8.5 | 8.2 |
| Product reviews | 5.9 | 6.1 |
| Customer support | 5.4 | 5.4 |
| Loyalty rewards | 4.2 | 4.3 |
| Flexible payment options | 3.7 | 3.6 |
| Personalized recommendations | 2.5 | 2.6 |
| Eco-friendly packaging | 2.0 | 1.9 |

**Findings**

- **The ranking is the same in every group.** The top three and bottom three hold across all age bands and both genders.
- **Younger respondents lean towards price.** Low prices reach 20.2% among 18–24s and 17.5% among 45+.
- **The oldest group leans towards security.** Secure payments reach 17.7% among 45+, the highest of any group.
- **Gender gaps are about a point.** Males score Free returns 1.1 points higher. Females score Fast delivery 0.9 points higher.
- **These differences are small.** No significance tests were run on the demographic cuts. Treat them as directional only.

---

## 7. Model Quality

| Metric | Value | Reading |
|---|---|---|
| Aggregate logit log-likelihood | −6,757.6 (null: −7,486.0) | The model beats random choice. |
| McFadden ρ² | 0.097 | Modest. Expected for a single-utility model that ignores individual differences. |
| HB hit rate, Best | 58.0% | Chance is 25%. |
| HB hit rate, Worst | 58.4% | Chance is 25%. |
| Agreement across methods | Full | Counting, logit and HB give the same ranking. |

The hit rates are in-sample. HB sampling ran with 4 chains and 1,000 draws after 1,000 tuning steps.

---

## 8. Implications

1. **Lead with price, security and delivery.** These three carry nearly half of all preference. They belong in the core proposition and headline messaging.
2. **Use returns and checkout as proof points.** Free returns and Easy checkout reinforce the core and reduce purchase friction.
3. **Segment communication on assortment.** Segment A (37%) responds to breadth of choice. Segment C (18%) rejects it outright. Range messaging should be targeted, not universal.
4. **Do not rely on Tier 4 features to win customers.** Loyalty rewards, Flexible payment options, Personalized recommendations and Eco-friendly packaging each take under 5% of preference.
5. **Do not read low rank as zero value.** MaxDiff measures relative importance. Features like Flexible payment options may still matter as baseline expectations.

---

## 9. Limitations

- **Stated preference.** Respondents chose in a survey. Real purchase behaviour may differ, especially for socially desirable items such as eco-friendly packaging.
- **Relative, not absolute.** MaxDiff ranks features against each other. It does not show whether any feature is "important enough" to change behaviour.
- **Unequal demographic cells.** The 45+ group has 57 respondents. Small differences between groups are not reliable.
- **Segments are single-axis.** The three segments are driven largely by Wide product range. They are not full attitudinal profiles.
- **Convergence diagnostics.** R-hat and effective sample size were not printed in the run output. Check them before publishing HB results.

---

## Appendix: Counting Analysis Detail

| Feature | Shown | Best | Worst | Best % | Worst % | B−W score | Sqrt-ratio (best = 100) |
|---|---|---|---|---|---|---|---|
| Low prices | 900 | 410 | 87 | 45.6% | 9.7% | +0.359 | 100.0 |
| Secure payments | 900 | 377 | 92 | 41.9% | 10.2% | +0.317 | 93.2 |
| Fast delivery | 900 | 339 | 130 | 37.7% | 14.4% | +0.232 | 74.4 |
| Free returns | 900 | 275 | 145 | 30.6% | 16.1% | +0.144 | 63.4 |
| Easy checkout | 900 | 254 | 177 | 28.2% | 19.7% | +0.086 | 55.2 |
| Wide product range | 900 | 217 | 216 | 24.1% | 24.0% | +0.001 | 46.2 |
| Product reviews | 900 | 184 | 208 | 20.4% | 23.1% | −0.027 | 43.3 |
| Customer support | 900 | 169 | 221 | 18.8% | 24.6% | −0.058 | 40.3 |
| Loyalty rewards | 900 | 152 | 279 | 16.9% | 31.0% | −0.141 | 34.0 |
| Flexible payment options | 900 | 128 | 298 | 14.2% | 33.1% | −0.189 | 30.2 |
| Personalized recommendations | 900 | 116 | 396 | 12.9% | 44.0% | −0.311 | 24.9 |
| Eco-friendly packaging | 900 | 79 | 451 | 8.8% | 50.1% | −0.413 | 19.3 |

## Appendix: Aggregate Logit Detail

| Feature | Utility | SE | 95% CI low | 95% CI high |
|---|---|---|---|---|
| Low prices | 0.959 | 0.053 | 0.855 | 1.064 |
| Secure payments | 0.833 | 0.053 | 0.729 | 0.936 |
| Fast delivery | 0.608 | 0.052 | 0.505 | 0.710 |
| Free returns | 0.378 | 0.052 | 0.276 | 0.480 |
| Easy checkout | 0.222 | 0.052 | 0.120 | 0.323 |
| Wide product range | −0.005 | 0.052 | −0.107 | 0.096 |
| Product reviews | −0.060 | 0.052 | −0.162 | 0.042 |
| Customer support | −0.156 | 0.052 | −0.258 | −0.054 |
| Loyalty rewards | −0.369 | 0.052 | −0.470 | −0.267 |
| Flexible payment options | −0.496 | 0.052 | −0.598 | −0.394 |
| Personalized recommendations | −0.820 | 0.053 | −0.924 | −0.717 |
| Eco-friendly packaging | −1.094 | 0.054 | −1.199 | −0.988 |