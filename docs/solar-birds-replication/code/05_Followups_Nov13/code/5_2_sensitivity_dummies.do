*==========================================================================
* 5_2_sensitivity_dummies.do
* PURPOSE : Prof. Ferraro's question: is Cinelli-Hazlett valid when the
*           fixed effects are absorbed (reghdfe) instead of entered as dummies?
* ANSWER  : Yes, by the Frisch-Waugh-Lovell theorem the coefficient, its
*           classical SE, t and the residual df are identical, and all C-H
*           statistics depend only on t and df. This file shows it.
* NOTE    : ~2,470 regressors. Stata/BE allows at most ~800 right-hand-side
*           variables, so the dummy-variable regression needs Stata/SE or MP.
*==========================================================================
quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
use "$SAMPLE", clear
bysort county: drop if _N == 1                 // same singletons reghdfe drops

* (a) absorbed fixed effects
reghdfe ShannonBD PI $control, absorb(county year) vce(unadjusted)
di "absorbed:  b = " %10.7f _b[PI] "  se = " %9.7f _se[PI] "  t = " %7.4f _b[PI]/_se[PI] "  df = " e(df_r)

* (b) explicit dummy variables (Stata/SE or MP)
capture noisily {
    regress ShannonBD PI $control i.county i.year
    di "dummies:   b = " %10.7f _b[PI] "  se = " %9.7f _se[PI] "  t = " %7.4f _b[PI]/_se[PI] "  df = " e(df_r)
    sensemakr ShannonBD PI $control i.county i.year, treat(PI) benchmark(Duration) kd(1 2 3)
}
* Expected (verified outside Stata with dummy-variable OLS):
*   b = -0.0125283, classical se = 0.0027334, t = -4.5834, df = 43,898
*   R2(Y~D|X) = 0.000478, RV = 0.02164, RV(alpha=.05) = 0.01244
