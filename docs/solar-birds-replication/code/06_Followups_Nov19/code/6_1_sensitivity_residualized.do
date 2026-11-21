*==========================================================================
* 6_1_sensitivity_residualized.do
* PURPOSE : Cinelli-Hazlett sensitivity analysis of the TWFE estimate using
*           the residualization approach Prof. Ferraro suggested:
*             reghdfe outcome,   absorb(FE) resid(y_resid)
*             reghdfe treatment, absorb(FE) resid(d_resid)
*             reg y_resid d_resid ..., nocons
*             sensemakr ...
*           (controls are residualized too, so the coefficient is exactly
*            the paper's: Frisch-Waugh-Lovell).
* QUESTION: how much confounding would it take to make the estimate zero,
*           insignificant, or positive?
* SPECS   : S1 = paper (county + year-month FE)
*           S2 = urban x year-month FE (separate monthly shocks urban/rural)
* NOTE    : sensemakr uses df = N - k - 1 and does not subtract the absorbed
*           fixed effects, so its RVs differ slightly from the exact ones in
*           02_Task2 (2.16% / 1.24%). Explicit county dummies cannot be used
*           in Stata/BE (2,344 dummies > 2,048-variable limit) - that is the
*           part that "did not run"; the residualized version below does.
*==========================================================================
if "$ROOT" == "" quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
global T6 "$ROOT/06_Followups_Nov19"

local i = 0
foreach fe in "county year" "county year#urban" {
    local ++i
    use "$SAMPLE", clear
    di _n as res "=================== S`i': absorb(`fe') ==================="
    * 1. the paper's regression, to fix the sample (drops singletons)
    reghdfe ShannonBD PI $control, absorb(`fe') vce(unadjusted)
    keep if e(sample)
    scalar b_S`i' = _b[PI]
    * 2. residualize outcome, treatment and every control on the FE
    foreach v in ShannonBD PI $control {
        quietly reghdfe `v', absorb(`fe') resid(r_`v')
    }
    * 3. same coefficient by OLS on residuals (check)
    reg r_ShannonBD r_PI r_Temp r_Wind r_Pop r_Duration r_Carbon r_Water r_Green r_Farm r_Grass, nocons
    di as res "check: reghdfe b = " %10.7f b_S`i' "   residual OLS b = " %10.7f _b[r_PI]
    * 4. sensemakr: robustness values + bounds benchmarked on Duration
    *    (the strongest observed control) at 1x ... 5x its strength
    sensemakr r_ShannonBD r_PI r_Temp r_Wind r_Pop r_Duration r_Carbon ///
        r_Water r_Green r_Farm r_Grass, treat(r_PI) benchmark(r_Duration) kd(1 2 3 4 5)
    * 5. contour plots (estimate and t-value)
    capture noisily sensemakr r_ShannonBD r_PI r_Temp r_Wind r_Pop r_Duration r_Carbon ///
        r_Water r_Green r_Farm r_Grass, treat(r_PI) benchmark(r_Duration) kd(1 2 3) contourplot
    capture noisily graph export "$T6/figures/6_1_contour_estimate_S`i'.png", replace width(1600)
    capture noisily sensemakr r_ShannonBD r_PI r_Temp r_Wind r_Pop r_Duration r_Carbon ///
        r_Water r_Green r_Farm r_Grass, treat(r_PI) benchmark(r_Duration) kd(1 2 3) tcontourplot
    capture noisily graph export "$T6/figures/6_1_contour_tvalue_S`i'.png", replace width(1600)
}
