#  Wine Quality Prediction & Exploration Shiny App  
### Interactive Exploration and Prediction of Wine Quality Using Chemical Profiling  
**Author:** Luke Wamalwa  
**Course:** Applied Statistics & Data Science – Product Development (Module 15)  
**Date:** Fall 2025  

---

##  Project Overview
This Shiny application provides an interactive platform for exploring the UCI Red Wine Quality dataset and predicting wine quality based on physicochemical properties.  
The app includes:

- **Exploratory Data Analysis (EDA)**
- **Visualization tools** (distribution plots, boxplots, correlation views)
- **Ordinal regression modeling**
- **Interactive prediction tool** (predict quality category from chemical inputs)

This repository contains all necessary files to run the app locally and reproduce the analysis and presentation.

---

##  Dataset
**Source:** UCI Machine Learning Repository – Red Wine Quality Dataset  
**Citation:**  
Cortez, Paulo, et al. “Modeling Wine Preferences by Data Mining from Physicochemical Properties.” *Decision Support Systems*, 47(4), 2009, pp. 547–553.

The dataset includes 1,599 red wine samples with 11 chemical features:

- fixed acidity  
- volatile acidity  
- citric acid  
- residual sugar  
- chlorides  
- free sulfur dioxide  
- total sulfur dioxide  
- density  
- pH  
- sulphates  
- alcohol  

**Target variable:** Quality score (3–8)

---

##  Repository Structure

```
Wine_Shiny_app/
│── ui.R                      # Shiny UI file
│── server.R                  # Shiny server logic
│── winequality-red.csv       # Dataset
│── Wine_Quality_Project_Presentation.pptx   # Final presentation
│── README.md                 # Project documentation
```

---

## 🚀 How to Run the App Locally

### **1. Clone the repository**

```bash
git clone https://github.com/YOUR_USERNAME/Wine_Shiny_app.git
cd Wine_Shiny_app
```

### **2. Open R or RStudio and install required packages**

```r
install.packages(c("shiny", "tidyverse", "plotly", "DT", "MASS"))
```

### **3. Run the app**

If files are named `ui.R` and `server.R`, run:

```r
shiny::runApp(".")
```

---

##  Features

### ** EDA Tab**
- Explore distributions of chemical variables  
- Compare chemical profiles across quality categories  
- Boxplots, violin plots, density curves  

### ** Model Tab**
- Ordinal logistic regression  
- Coefficient table  
- AIC comparison  
- Multicollinearity (VIF) analysis  

### ** Prediction Tab**
- Input chemical values  
- Predict probability for each quality class  
- View predicted category  

---

##  Key Insights from the Model

- **Alcohol** is the strongest positive predictor of quality.  
- **Volatile acidity** strongly decreases quality.  
- **Sulphates** improve predicted quality.  
- **High pH, chlorides, and sulfur dioxide decrease quality.**  
- **Density and pH show severe multicollinearity and may be redundant.**

---

##  Limitations

- Class imbalance (most wines rated 5–6) affects prediction accuracy.  
- Multicollinearity inflates coefficient uncertainty.  
- Ordinal logistic regression assumes proportional odds.  
- Does not model human sensory variability.  

---

##  Future Work

- Test tree-based models (Random Forest, XGBoost).  
- Add interactive SHAP value explanations.  
- Explore nonlinear relationships and interaction terms.  

---

##  Deployment

Slides, code, and dataset are stored at:

```
C:\Users\lukew\OneDrive\Desktop\Lukas\Data Visualization and Acquision\Module 15\Code\Wine_Shiny_app
```

To deploy publicly, upload to GitHub and optionally use:

- shinyapps.io  
- Posit Connect  
- Docker container (optional)

---

## References

Cortez, Paulo, et al. “Modeling Wine Preferences by Data Mining from Physicochemical Properties.”  
*Decision Support Systems*, vol. 47, no. 4, 2009, pp. 547–553.

Tufte, Edward R. *The Visual Display of Quantitative Information*. Graphics Press, 1983.

---

## Author

**Luke Wamalwa**  
M.S. in Applied Statistics & Data Science  
University of Kansas Medical Center  
GitHub: https://github.com/lukahere007 
