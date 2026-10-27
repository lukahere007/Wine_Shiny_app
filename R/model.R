# Helpers shared by the Shiny app (server.R) and scripts/evaluate_model.R.
# Shiny sources every file in R/ automatically before ui.R and server.R.

suppressPackageStartupMessages({
  library(MASS)
  library(car)
})

load_wine <- function(path = "winequality-red.csv") {
  wine <- read.csv(path, check.names = TRUE)          # "fixed acidity" -> fixed.acidity
  wine$quality <- factor(wine$quality, ordered = TRUE)
  wine
}

# Numeric quality score (3-8). as.numeric() on the factor would give level
# indices (1-6) instead.
quality_score <- function(q) as.numeric(as.character(q))

predictor_names <- function(wine) setdiff(names(wine), "quality")

# Forward stepwise AIC selection of a proportional-odds (ordinal logistic) model.
fit_ordinal_models <- function(wine) {
  null_model <- polr(quality ~ 1, data = wine, Hess = TRUE)
  full_model <- polr(quality ~ ., data = wine, Hess = TRUE)
  forward_model <- stepAIC(null_model,
                           scope = list(lower = null_model, upper = full_model),
                           direction = "forward", trace = FALSE)
  list(null = null_model, full = full_model, forward = forward_model)
}

# Coefficient table with Wald p-values and odds ratios.
coef_table <- function(model) {
  s <- coef(summary(model))
  slopes <- s[names(coef(model)), , drop = FALSE]
  data.frame(
    term       = rownames(slopes),
    estimate   = slopes[, "Value"],
    std_error  = slopes[, "Std. Error"],
    odds_ratio = exp(slopes[, "Value"]),
    p_value    = 2 * pnorm(-abs(slopes[, "t value"])),
    row.names  = NULL
  )
}

# VIFs depend only on the predictors, so compute them from a linear model on the
# predictors. car::vif() on a polr fit has no intercept and inflates the values
# (it reports density ~38 and pH ~29, which is an artefact).
predictor_vif <- function(wine) {
  X <- wine[, predictor_names(wine)]
  X$.y <- quality_score(wine$quality)
  v <- vif(lm(.y ~ ., data = X))
  data.frame(variable = names(v), VIF = as.numeric(v))
}

# Held-out evaluation. Exact duplicate rows are dropped first so the same wine
# cannot sit in both train and test; variable selection is redone on the
# training split only.
evaluate_holdout <- function(wine, test_frac = 0.3, seed = 2025) {
  wine <- wine[!duplicated(wine), ]
  set.seed(seed)
  test_idx <- unlist(lapply(split(seq_len(nrow(wine)), wine$quality), function(i)
    i[sample.int(length(i), round(length(i) * test_frac))]))
  train <- wine[-test_idx, ]
  test  <- wine[test_idx, ]

  fit  <- fit_ordinal_models(train)$forward
  pred <- predict(fit, test, type = "class")

  truth    <- quality_score(test$quality)
  guess    <- quality_score(pred)
  majority <- as.numeric(names(which.max(table(train$quality))))
  list(
    n_unique       = nrow(wine),
    n_train        = nrow(train),
    n_test         = nrow(test),
    selected       = attr(terms(fit), "term.labels"),
    accuracy       = mean(guess == truth),
    within_one     = mean(abs(guess - truth) <= 1),
    baseline_class = majority,
    baseline_acc   = mean(truth == majority),
    mae            = mean(abs(guess - truth)),
    baseline_mae   = mean(abs(majority - truth)),
    confusion      = table(Actual = factor(truth, levels = 3:8),
                           Predicted = factor(guess, levels = 3:8))
  )
}
