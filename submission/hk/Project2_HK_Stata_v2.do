cd "/Users/hoomankamel/Dropbox/Masters/Project2/Project2_HK/Project2_HK_v2"

capture log close
qui log using "Project2_HK.smcl", replace

/*** 
EDAV Project 2: Regression with Principal Components
===================================================
    
Aim: Visualize relationship between flood characteristics and number of people displaced
----------------------------------------------------------------------------------------
***/

qui log off

insheet using "GlobalFloodsRecord_HK.csv", clear

foreach x in severity affected duration displaced {
	destring `x', replace force
	hist `x', graphregion(color(white)) ylabel(, ang(hor) nogrid)
	graph export "Histogram_`x'.png", replace
	}

qui log on

/***
### 1.	Visualize distribution of variables

* Severity:

![](./Histogram_severity.png)

* Affected area:

![](./Histogram_affected.png)

* Duration:

![](./Histogram_duration.png)

* Number displaced:

![](./Histogram_displaced.png)

### 2.	Center and scale

Except for severity, other variables appear skewed, so log-transform them and then center and scale them.
***/

qui log off

egen std_log_affected = std(log(affected))
egen std_log_duration = std(log(duration))
egen std_log_displaced = std(log(displaced))

qui log on

/*** 
### 3.	Linear regression

Perform multiple linear regression with "displaced" as dependent variable and other three variables as independent variables.  
***/
/***
This model seems to explain ~19% of number of people displaced.
***/

regress std_log_displaced severity std_log_affected std_log_duration

qui log off

predict residual, resid

kdensity residual, normal graphregion(color(white)) ylabel(, ang(hor) nogrid) title("")
graph export "Histogram_kernel_density.png", replace

rvfplot, yline(0) graphregion(color(white)) ylabel(, ang(hor) nogrid)
graph export "Homoscedasticity.png", replace

acprplot severity, lowess lsopts(bwidth(1)) graphregion(color(white)) ylabel(, ang(hor) nogrid)
graph export "Linearity_severity.png", replace

acprplot std_log_affected, lowess lsopts(bwidth(1)) graphregion(color(white)) ylabel(, ang(hor) nogrid)
graph export "Linearity_affected.png", replace

acprplot std_log_duration, lowess lsopts(bwidth(1)) graphregion(color(white)) ylabel(, ang(hor) nogrid)
graph export "Linearity_duration.png", replace

qui log on

/***
Check assumptions of linear regression:

* Assumption of normality of residuals appears satisfied.

![](./Histogram_kernel_density.png)

* Assumption of homoscedasticity of residuals appears satisfied.

![](./Homoscedasticity.png)

* No evidence of significant collinearity (VIF <10).
***/

vif

/***
* Assumption of linearity appears satisfied.

![](./Linearity_severity.png)

![](./Linearity_affected.png)

![](./Linearity_duration.png)

### 4.	Perform principal components analysis on "affected", "severity", and "duration"

Estimate principal components.
***/

pca severity std_log_affected std_log_duration

/***
Component 1 explains ~53% of variance, so compute score of that component (pc1) and regress on that alone. 
***/

qui log off

predict pc1, score

qui log on

/***
As seen, model R2 is similar to earlier model with separate terms for "magnitude" and "duration" (R2 ~0.18 versus ~0.19).
***/

regress std_log_displaced pc1

/***
Regression model with "pc1" appears to be equal to or superior R2 to regression models with "duration" alone or "magnitude" alone.
***/
regress std_log_displaced severity
regress std_log_displaced std_log_affected
regress std_log_displaced std_log_duration

qui log off

regress std_log_displaced pc1

hist residual
kdensity residual, normal

predict residual2, resid

kdensity residual2, normal graphregion(color(white)) ylabel(, ang(hor) nogrid) title("")
graph export "Histogram_kernel_density_2.png", replace

rvfplot, yline(0) graphregion(color(white)) ylabel(, ang(hor) nogrid)
graph export "Homoscedasticity_2.png", replace

acprplot pc1, lowess lsopts(bwidth(1)) graphregion(color(white)) ylabel(, ang(hor) nogrid)
graph export "Linearity_pc1.png", replace

qui log on

/***
Check assumptions of linear regression for model with principal component alone:

* Assumption of normality of residuals appears satisfied.

![](./Histogram_kernel_density_2.png)

* Assumption of homoscedasticity of residuals appears satisfied.

![](./Homoscedasticity_2.png)

* No evidence of significant collinearity (VIF <10).
***/

vif

/***
* Assumption of linearity appears satisfied.

![](./Linearity_pc1.png)

### 5.	Visually assess relationship between multiple flood characteristics and # displaced
***/
/***
Such a visualization would be difficult to perform with traditional linear regression in the presence of multiple independent variables.
***/

qui log off

graph twoway (scatter std_log_displaced pc1) (lfit std_log_displaced pc1), graphregion(color(white)) ylabel(, ang(hor) nogrid)
graph export "Scatter.png", replace

qui log on

/***
![](./Scatter.png)

### 6.	Summmary

Principal components analysis allowed dimension reduction to one dimension, thereby allowing direct visualization. 
***/
/***
Prediction using one principal component was equally predictive as regression limited to one traditional independent variable
and additionally allowed direct visualization between predictor and outcome. However, the disadvantage of this approach is that 
the first principal component is more difficult to conceptually understand than a traditional predictor such as severity. 
***/

qui log close

markdoc Project2_HK.smcl, replace export(pdf)
markdoc Project2_HK.smcl, replace export(docx)
markdoc Project2_HK.smcl, replace export(html) install mathjax                        
