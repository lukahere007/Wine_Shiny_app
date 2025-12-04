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
                               tableOutput("modelCompare"),
                               hr(),
                               tableOutput("vifTable")
                        )
                      )
             ),
             
             tabPanel(" Prediction",
                      fluidRow(
                        column(4,
                               wellPanel(
                                 h4("Enter Wine Characteristics"),
                                 sliderInput("alcohol","Alcohol (%)", 8,15, value=10),
                                 sliderInput("volatile","Volatile Acidity",0,1,value=0.5),
                                 sliderInput("sulphates","Sulphates",0,2,value=0.6),
                                 sliderInput("citric","Citric Acid",0,1,value=0.3),
                                 sliderInput("residual","Residual Sugar",0,10,value=2),
                                 sliderInput("density","Density",0.990,1.005,value=0.996),
                                 sliderInput("pH","pH",2.5,4.0,value=3.3),
                                 sliderInput("chlorides","Chlorides",0,0.2,value=0.08),
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
