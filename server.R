library(shiny)
library(tidyverse)
library(MASS)
library(ggfortify)
library(car)
library(shinycssloaders)

# Helpers (load_wine, fit_ordinal_models, ...) live in R/model.R, which Shiny
# sources automatically.

# ---- Load data and fit models once, at app start-up ----
wine   <- load_wine("winequality-red.csv")
models <- fit_ordinal_models(wine)
forward_model <- models$forward
holdout <- evaluate_holdout(wine)

server <- function(input, output, session) {

  # ---- Reactive Filtered Data ----
  filtered_data <- reactive({
    q <- quality_score(wine$quality)
    wine[q >= input$qualityInput[1] & q <= input$qualityInput[2], ]
  })

  # ---- KPI Outputs ----
  output$kpi_n <- renderUI({
    paste("Samples:", nrow(filtered_data()))
  })

  output$kpi_mean <- renderUI({
    paste("Mean Quality:", round(mean(quality_score(filtered_data()$quality)), 2))
  })

  output$kpi_alcohol <- renderUI({
    paste("Avg Alcohol:", round(mean(filtered_data()$alcohol), 2))
  })

  # ---- Insight Text (computed from the current selection) ----
  output$insightText <- renderText({
    df <- filtered_data()
    q  <- quality_score(df$quality)
    if (length(unique(q)) < 2) {
      return("Select at least two quality levels to see how chemistry relates to quality.")
    }
    r <- sapply(c("alcohol", "sulphates", "volatile.acidity"),
                function(v) cor(df[[v]], q, method = "spearman"))
    paste0(
      "Spearman correlation with quality in this selection: alcohol ",
      sprintf("%+.2f", r["alcohol"]), ", sulphates ", sprintf("%+.2f", r["sulphates"]),
      ", volatile acidity ", sprintf("%+.2f", r["volatile.acidity"]), ". ",
      "Average quality: ", round(mean(q), 2),
      " | Avg alcohol: ", round(mean(df$alcohol), 2)
    )
  })

  # ---- Scatter Plot ----
  output$scatterPlot <- renderPlot({
    df <- filtered_data()
    p <- ggplot(df, aes(x = .data[[input$xvar]], y = .data[[input$yvar]]))
    p <- if (input$color_var == "None") {
      p + geom_point(alpha = 0.6, size = 2)
    } else {
      p + geom_point(aes(colour = .data[[input$color_var]]), alpha = 0.6, size = 2)
    }
    p + theme_minimal() +
      labs(x = input$xvar, y = input$yvar,
           title = paste("Relationship between", input$xvar, "and", input$yvar))
  })

  # ---- PCA Plot (chemical variables only; quality is not an input) ----
  output$pcaPlot <- renderPlot({
    df <- filtered_data()
    df_numeric <- df[, predictor_names(df), drop = FALSE]

    if (nrow(df_numeric) < 3) {
      plot.new()
      text(0.5, 0.5, "Not enough wines in this selection for PCA")
      return()
    }

    pca <- prcomp(df_numeric, scale. = TRUE)
    colour <- if (input$color_var == "None") NULL else input$color_var

    autoplot(pca, data = df, colour = colour,
             loadings = TRUE, loadings.label = TRUE) +
      theme_minimal()
  })

  # ---- Model Summary with p-values ----
  output$modelSummary <- renderPrint({
    cat("Forward-selected proportional-odds model (fit on all", nrow(wine), "wines)\n\n")
    tab <- coef_table(forward_model)
    tab[, -1] <- signif(tab[, -1], 4)
    print(tab, row.names = FALSE)
    cat("\nOdds ratio = multiplicative change in the odds of a higher quality rating",
        "per one-unit increase in the variable.\n")
  })

  # ---- Model AIC Table ----
  output$modelCompare <- renderTable({
    tibble(
      Model = c("Null", "Forward Selected", "Full"),
      Predictors = c(0, length(coef(forward_model)), length(coef(models$full))),
      AIC = c(AIC(models$null), AIC(forward_model), AIC(models$full))
    )
  })

  # ---- Held-out performance ----
  output$holdoutText <- renderPrint({
    h <- holdout
    cat(sprintf("Held-out test set: %d wines (%d exact duplicates removed before splitting; 70/30 stratified split).\n\n",
                h$n_test, nrow(wine) - h$n_unique))
    cat(sprintf("Exact accuracy:          %.1f%%   (always predicting %d: %.1f%%)\n",
                100 * h$accuracy, h$baseline_class, 100 * h$baseline_acc))
    cat(sprintf("Within one point:        %.1f%%\n", 100 * h$within_one))
    cat(sprintf("Mean absolute error:     %.2f    (always predicting %d: %.2f)\n\n",
                h$mae, h$baseline_class, h$baseline_mae))
    print(h$confusion)
  })

  # ---- VIF Diagnostics ----
  output$vifTable <- renderTable({
    predictor_vif(wine) %>% arrange(desc(VIF))
  })

  # ---- Prediction ----
  prediction <- eventReactive(input$predict_btn, {
    vars_needed <- attr(terms(forward_model), "term.labels")

    # Start from the median wine, then overwrite with the user's inputs.
    new_wine <- as.data.frame(lapply(wine[, predictor_names(wine)], median))
    new_wine$alcohol              <- input$alcohol
    new_wine$volatile.acidity     <- input$volatile
    new_wine$sulphates            <- input$sulphates
    new_wine$chlorides            <- input$chlorides
    new_wine$pH                   <- input$pH
    new_wine$total.sulfur.dioxide <- input$total_so2
    new_wine$free.sulfur.dioxide  <- input$free_so2

    probs <- predict(forward_model, new_wine[, vars_needed, drop = FALSE], type = "probs")
    data.frame(Quality = names(probs), Probability = as.numeric(probs))
  })

  output$probPlot <- renderPlot({
    probs_long <- prediction()
    ggplot(probs_long, aes(Quality, Probability, fill = Quality)) +
      geom_col() +
      scale_fill_brewer(palette = "Reds") +
      ylim(0, 1) +
      theme_minimal()
  })

  output$summaryText <- renderPrint({
    probs_long <- prediction()
    cat("Most likely quality:", probs_long$Quality[which.max(probs_long$Probability)], "\n")
    cat(sprintf("Expected quality score: %.2f\n\n",
                sum(as.numeric(probs_long$Quality) * probs_long$Probability)))
    print(transform(probs_long, Probability = round(Probability, 3)), row.names = FALSE)
  })
}
