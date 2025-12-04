library(shiny)
library(tidyverse)
library(MASS)
library(ggplot2)
library(ggfortify)
library(car)
library(shinycssloaders)

server <- function(input, output) {
  
  # ---- Load Data ----
  wine <- read_csv("path/Data")
  colnames(wine) <- make.names(colnames(wine))
  wine$quality <- factor(wine$quality, ordered = TRUE)
  
  # ---- Reactive Filtered Data ----
  filtered_data <- reactive({
    subset(wine, quality >= input$qualityInput[1] & quality <= input$qualityInput[2])
  })
  
  # ---- KPI Outputs ----
  output$kpi_n <- renderUI({
    paste("Samples:", nrow(filtered_data()))
  })
  
  output$kpi_mean <- renderUI({
    paste("Mean Quality:", round(mean(as.numeric(filtered_data()$quality)),2))
  })
  
  output$kpi_alcohol <- renderUI({
    paste("Avg Alcohol:", round(mean(filtered_data()$alcohol),2))
  })
  
  # ---- Insight Text ----
  output$insightText <- renderText({
    df <- filtered_data()
    paste0(
      "Higher quality wines in this selection tend to have higher alcohol and sulphate levels, ",
      "while lower quality wines show higher volatile acidity. ",
      "Average quality: ",
      round(mean(as.numeric(df$quality)),2),
      " | Avg Alcohol: ",
      round(mean(df$alcohol),2)
    )
  })
  
  # ---- Scatter Plot ----
  output$scatterPlot <- renderPlot({
    df <- filtered_data()
    
    ggplot(df, aes_string(
      x = input$xvar,
      y = input$yvar,
      color = if (input$color_var == "None") NULL else input$color_var
    )) +
      geom_point(alpha=0.6, size=2) +
      theme_minimal() +
      labs(
        x = input$xvar,
        y = input$yvar,
        title = paste("Relationship between", input$xvar, "and", input$yvar)
      )
  })
  
  # ---- PCA Plot ----
  output$pcaPlot <- renderPlot({
    
    df <- filtered_data()
    
    numeric_cols <- sapply(df, is.numeric)
    df_numeric <- df[ , numeric_cols, drop = FALSE]
    
    if (ncol(df_numeric) < 2) {
      plot.new()
      text(0.5, 0.5, "Not enough numeric variables for PCA")
      return()
    }
    
    pca <- prcomp(df_numeric, scale. = TRUE)
    
    autoplot(
      pca,
      data = df,
      colour = input$color_var,
      loadings = TRUE,
      loadings.label = TRUE
    ) + 
      theme_minimal()
  })
  
  # ---- Ordinal Regression Models ----
  null_model <- polr(quality ~ 1, data = wine, Hess=TRUE)
  full_model <- polr(quality ~ ., data = wine, Hess=TRUE)
  
  forward_model <- stepAIC(
    null_model,
    scope=list(lower=null_model, upper=full_model),
    direction="forward",
    trace=FALSE
  )
  
  # ---- Model Summary with p-values ----
  output$modelSummary <- renderPrint({
    sum <- summary(forward_model)
    coefs <- sum$coefficients
    pvals <- 2*(1 - pnorm(abs(coefs[,"t value"])))
    
    print(cbind(coefs, "p value"=pvals))
  })
  
  # ---- Model AIC Table ----
  output$modelCompare <- renderTable({
    tibble(
      Model=c("Null","Forward Selected","Full"),
      AIC=c(AIC(null_model), AIC(forward_model), AIC(full_model))
    )
  })
  
  # ---- VIF Diagnostics ----
  output$vifTable <- renderTable({
    tibble(
      Variable = names(vif(full_model)),
      VIF = as.numeric(vif(full_model))
    )
  })
  
  # ---- Prediction ----
  observeEvent(input$predict_btn, {
    
    vars_needed <- all.vars(formula(forward_model))[-1]
    
    new_wine <- data.frame(
      alcohol = input$alcohol,
      volatile.acidity = input$volatile,
      sulphates = input$sulphates,
      total.sulfur.dioxide = 50,
      chlorides = input$chlorides,
      pH = input$pH,
      free.sulfur.dioxide = 15
    )[vars_needed]
    
    probs <- predict(forward_model, new_wine, type="probs")
    probs_long <- data.frame(
      Quality = names(probs),
      Probability = as.numeric(probs)
    )
    
    predicted_quality <- names(probs)[which.max(probs)]
    
    output$probPlot <- renderPlot({
      ggplot(probs_long, aes(Quality, Probability, fill = Quality)) +
        geom_col() +
        scale_fill_brewer(palette = "Reds") +
        ylim(0, 1)
    })
    
    output$summaryText <- renderPrint({
      cat("Predicted Quality:", predicted_quality, "\n\n")
      print(probs_long)
    })
    
  })   
  
}      
