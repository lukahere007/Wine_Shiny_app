library(shiny)
library(shinythemes)
library(shinycssloaders)
library(tidyverse)

ui <- fluidPage(
  theme = shinytheme("flatly"),
  
  titlePanel(div(
    style="display:flex; align-items:center;",
    span(" Wine Quality Dashboard", style="font-weight:bold; font-size:28px;")
  )),
  
  fluidRow(
    column(4,
           wellPanel(
             h4("Filters"),
             
             sliderInput("qualityInput", "Quality Range:",
                         min = 3, max = 8, value = c(3,8), step = 1),
             
             selectInput("color_var", "Color By:",
                         choices = c("None","quality","alcohol","sulphates","volatile.acidity"),
                         selected = "quality"),
             
             selectInput("xvar", "X-axis Variable:",
                         choices = c("fixed.acidity","volatile.acidity","citric.acid",
                                     "residual.sugar","chlorides","free.sulfur.dioxide",
                                     "total.sulfur.dioxide","density","pH","sulphates","alcohol"),
                         selected = "alcohol"),
             
             selectInput("yvar", "Y-axis Variable:",
                         choices = c("fixed.acidity","volatile.acidity","citric.acid",
                                     "residual.sugar","chlorides","free.sulfur.dioxide",
                                     "total.sulfur.dioxide","density","pH","sulphates","alcohol"),
                         selected = "sulphates")
           )
    ),
    
    column(8,
           fluidRow(
             column(4, uiOutput("kpi_n")),
             column(4, uiOutput("kpi_mean")),
             column(4, uiOutput("kpi_alcohol"))
           )
    )
  ),
  
  hr(),
  
  fluidRow(               
    column(12,
           
           tabsetPanel(
             
             tabPanel(" Exploration",
                      fluidRow(
                        column(6,
                               h4("Scatter Plot"),
                               plotOutput("scatterPlot", height=350) %>% withSpinner()
                        ),
                        column(6,
                               h4("PCA Projection"),
                               plotOutput("pcaPlot", height=350) %>% withSpinner()
                        )
                      ),
                      hr(),
                      wellPanel(
                        h4(" Key Insights"),
                        textOutput("insightText")
                      )
             ),
             
             tabPanel(" Model",
                      fluidRow(
                        column(12,
                               h3("Ordinal Regression Model"),
                               verbatimTextOutput("modelSummary") %>% withSpinner(),
                               hr(),
                               h4("Model comparison (AIC, lower is better)"),
                               tableOutput("modelCompare"),
                               hr(),
                               h4("How well does it predict unseen wines?"),
                               verbatimTextOutput("holdoutText"),
                               hr(),
                               h4("Variance inflation factors (all 11 predictors)"),
                               tableOutput("vifTable")
                        )
                      )
             ),
             
             tabPanel(" Prediction",
                      fluidRow(
                        column(4,
                               wellPanel(
                                 h4("Enter Wine Characteristics"),
                                 helpText("Ranges match the dataset; defaults are the median wine.",
                                          "These are the seven variables chosen by forward selection."),
                                 sliderInput("alcohol","Alcohol (% vol)", 8.4, 14.9, value=10.2, step=0.1),
                                 sliderInput("volatile","Volatile Acidity (g/L)", 0.12, 1.58, value=0.52, step=0.01),
                                 sliderInput("sulphates","Sulphates (g/L)", 0.33, 2.0, value=0.62, step=0.01),
                                 sliderInput("chlorides","Chlorides (g/L)", 0.012, 0.611, value=0.079, step=0.001),
                                 sliderInput("pH","pH", 2.74, 4.01, value=3.31, step=0.01),
                                 sliderInput("total_so2","Total Sulfur Dioxide (mg/L)", 6, 289, value=38, step=1),
                                 sliderInput("free_so2","Free Sulfur Dioxide (mg/L)", 1, 72, value=14, step=1),
                                 actionButton("predict_btn","Predict Quality",
                                              class="btn btn-success btn-block")
                               )
                        ),
                        column(8,
                               h4("Predicted Quality Probabilities"),
                               plotOutput("probPlot", height=300) %>% withSpinner(),
                               hr(),
                               verbatimTextOutput("summaryText")
                        )
                      )
             )
           )
    )
  )
)
