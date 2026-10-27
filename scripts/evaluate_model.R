# Reproduces the numbers and figures quoted in README.md.
# Run from the repository root:  Rscript scripts/evaluate_model.R
suppressPackageStartupMessages(library(ggplot2))
source("R/model.R")

wine   <- load_wine("winequality-red.csv")
models <- fit_ordinal_models(wine)

cat("Rows:", nrow(wine), " exact duplicate rows:", sum(duplicated(wine)), "\n")
print(table(wine$quality))

cat("\nAIC  null:", round(AIC(models$null), 1),
    " forward:", round(AIC(models$forward), 1),
    " full:", round(AIC(models$full), 1), "\n\n")

ct <- coef_table(models$forward)
print(transform(ct, estimate = round(estimate, 4), std_error = round(std_error, 4),
                odds_ratio = round(odds_ratio, 3), p_value = signif(p_value, 3)),
      row.names = FALSE)

cat("\nVIF (linear model on all 11 predictors):\n")
v <- predictor_vif(wine); print(v[order(-v$VIF), ], row.names = FALSE)
cat("\nVIF as car::vif() reports it on the polr fit (no intercept, misleading):\n")
print(round(suppressWarnings(car::vif(models$full)), 1))

h <- evaluate_holdout(wine)
cat(sprintf("\nHold-out: %d unique wines, train %d, test %d\n", h$n_unique, h$n_train, h$n_test))
cat("Selected on train:", paste(h$selected, collapse = ", "), "\n")
cat(sprintf("Accuracy %.3f | within one %.3f | MAE %.3f\n", h$accuracy, h$within_one, h$mae))
cat(sprintf("Baseline (always %d): accuracy %.3f | MAE %.3f\n",
            h$baseline_class, h$baseline_acc, h$baseline_mae))
print(h$confusion)

# ---- Figures ----
ct$label <- reorder(ct$term, ct$estimate * sapply(wine[ct$term], sd))
ct$std_effect <- ct$estimate * sapply(wine[as.character(ct$term)], sd)
ct$lo <- (ct$estimate - 1.96 * ct$std_error) * sapply(wine[as.character(ct$term)], sd)
ct$hi <- (ct$estimate + 1.96 * ct$std_error) * sapply(wine[as.character(ct$term)], sd)
p1 <- ggplot(ct, aes(x = std_effect, y = label)) +
  geom_vline(xintercept = 0, colour = "grey60") +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.2, colour = "#7f1d1d") +
  geom_point(size = 3, colour = "#7f1d1d") +
  labs(x = "Change in log-odds of a higher quality rating per 1 SD increase (95% CI)",
       y = NULL, title = "Forward-selected ordinal logistic regression (n = 1,599)") +
  theme_minimal(base_size = 12)
ggsave("figures/standardized_effects.png", p1, width = 8, height = 4.5, dpi = 120, bg = "white")

cm <- as.data.frame(h$confusion)
p2 <- ggplot(cm, aes(Predicted, Actual, fill = Freq)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = Freq)) +
  scale_fill_gradient(low = "#fff5f0", high = "#a50f15") +
  labs(title = sprintf("Held-out confusion matrix (n = %d)", h$n_test),
       subtitle = sprintf("Accuracy %.0f%% vs %.0f%% for always predicting %d",
                          100 * h$accuracy, 100 * h$baseline_acc, h$baseline_class)) +
  theme_minimal(base_size = 12) + theme(legend.position = "none")
ggsave("figures/holdout_confusion.png", p2, width = 5.5, height = 4.5, dpi = 120, bg = "white")
