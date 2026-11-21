*==========================================================================
* 2_1_sensitivity_analysis.do
* PURPOSE : Cinelli & Hazlett (2020) sensitivity of the TWFE estimate to an
*           unobserved confounder Z, for two specifications:
*             S1  paper's baseline: county + year-month FE
*             S2  urban x year-month FE (Task 1 diagnostic)
* STEPS   : A  sensitivity statistics: partial R2 of PSI with Shannon,
*              robustness values RV_q=1 and RV_q=1,alpha=0.05  (C-H eqs 18-20)
*           B  benchmark bounds: Z "k times as strong" as each of the nine
*              controls (k = 1,2,3), adjusted estimate & t   (C-H eqs 12-13, 21-22)
*           C  group benchmark: Z as strong as urban x year-month trends
*           D  clustered-inference variant (significance threshold scaled by
*              lambda = clustered SE / classical SE)
*           E  contour plots of the adjusted estimate and t-value
*           F  cross-check with the official -sensemakr- on FE-demeaned data
* NOTE    : The ~2,460 fixed effects are absorbed (Frisch-Waugh-Lovell); all
*           statistics use reghdfe's exact residual degrees of freedom.
* OUTPUT  : tables/2_1_robustness_values.csv, 2_1_benchmark_bounds.csv
*           figures/2_1_contour_estimate_S*.pdf, 2_1_contour_tvalue_S*.pdf
*==========================================================================

*--------------------------------------------------------------------------
* Program 1: robustness values from a t-statistic and df   (C-H eqs 18-20)
*--------------------------------------------------------------------------
capture program drop ch_rv
program define ch_rv, rclass
    args t df q alpha lambda
    if "`lambda'" == "" local lambda 1
    tempname f fq fcrit fqa rv rva
    scalar `f'     = abs(`t')/sqrt(`df')                      // partial Cohen f of D with Y
    scalar `fq'    = `q'*`f'
    scalar `rv'    = 0.5*(sqrt(`fq'^4 + 4*`fq'^2) - `fq'^2)   // eq 18
    * lambda = clustered SE / classical SE: inflates only the significance
    * threshold; the confounding-strength scale (partial R2) is unchanged
    scalar `fcrit' = `lambda'*abs(invttail(`df'-1, `alpha'/2))/sqrt(`df'-1)
    scalar `fqa'   = `fq' - `fcrit'                           // eq 19
    if `fqa' <= 0 scalar `rva' = 0
    else {
        scalar `rva' = 0.5*(sqrt(`fqa'^4 + 4*`fqa'^2) - `fqa'^2)   // eq 20
        if `rva' <= 1 - 1/`fq'^2 & `fq' > 1 scalar `rva' = (`fq'^2 - `fcrit'^2)/(1 + `fq'^2)
    }
    return scalar r2yd = `t'^2/(`t'^2 + `df')                 // partial R2 of D with Y
    return scalar rv   = `rv'
    return scalar rva  = `rva'
end

*--------------------------------------------------------------------------
* Program 2: bound + adjusted estimate for Z "k times" a benchmark
*            (C-H eqs 21-22; supplement section B; = sensemakr's bounds)
*--------------------------------------------------------------------------
capture program drop ch_bound
program define ch_bound, rclass
    args r2dxj r2yxj kd ky est se df
    tempname r2dz r2zxj r2yz bias adj adjse
    scalar `r2dz'  = `kd'*`r2dxj'/(1 - `r2dxj')
    scalar `r2zxj' = `kd'*`r2dxj'^2/((1 - `kd'*`r2dxj')*(1 - `r2dxj'))
    scalar `r2yz'  = ((sqrt(`ky') + sqrt(`r2zxj'))/sqrt(1 - `r2zxj'))^2 * (`r2yxj'/(1 - `r2yxj'))
    if `r2yz' > 1 scalar `r2yz' = 1
    * omitted-variable bias (eq 12) and adjusted SE (eq 13)
    scalar `bias'  = `se'*sqrt(`r2yz'*`r2dz'/(1 - `r2dz')*`df')
    scalar `adj'   = sign(`est')*(abs(`est') - `bias')        // Z pushes toward zero
    scalar `adjse' = `se'*sqrt((1 - `r2yz')/(1 - `r2dz')*`df'/(`df' - 1))
    return scalar r2dz  = `r2dz'
    return scalar r2yz  = `r2yz'
    return scalar adj   = `adj'
    return scalar adjse = `adjse'
    return scalar adjt  = `adj'/`adjse'
end

*--------------------------------------------------------------------------
use "$SAMPLE", clear
local fe1 "county year"
local fe2 "county year#urban"
local nm1 "S1 baseline (county + YM FE)"
local nm2 "S2 urban x YM FE"

tempname RV BD
postfile `RV' str32 spec double(est se_classical t_classical df R2_YD RV_q1 RV_q1_a05 ///
    se_clustered t_clustered G lambda RV_q1_a05_clustered) using "$T2/tables/rv_tmp.dta", replace
postfile `BD' str32 spec str32 benchmark double(k R2_D_X R2_Y_X R2_D_Z R2_Y_Z adj_est adj_se adj_t adj_t_clustered) ///
    using "$T2/tables/bd_tmp.dta", replace

forvalues s = 1/2 {
    di as res _n "======================= `nm`s'' ======================="

    *---------------- clustered SE first (the paper's inference)
    reghdfe ShannonBD PI $control, absorb(`fe`s'') cluster(county)
    keep if e(sample)
    scalar secl_`s' = _se[PI]
    scalar tcl_`s'  = _b[PI]/_se[PI]
    scalar G_`s'    = e(N_clust)

    *---------------- A. sensitivity statistics (classical SE, exact df)
    reghdfe ShannonBD PI $control, absorb(`fe`s'') vce(unadjusted)
    scalar est_`s' = _b[PI]
    scalar se_`s'  = _se[PI]
    scalar df_`s'  = e(df_r)
    scalar t_`s'   = _b[PI]/_se[PI]
    scalar lam_`s' = secl_`s'/se_`s'
    foreach b in $control {
        scalar tY = _b[`b']/_se[`b']
        scalar r2y_`b' = tY^2/(tY^2 + df_`s')        // R2 of Y with Xj | D, X-j, FE
    }
    ch_rv t_`s' df_`s' 1 0.05
    scalar r2yd_`s' = r(r2yd)
    scalar rv_`s'   = r(rv)
    scalar rva_`s'  = r(rva)
    di "Partial R2 of PSI with Shannon : " %9.6f r(r2yd)
    di "Robustness value RV(q=1)       : " %9.6f r(rv)
    di "Robustness value RV(q=1,a=.05) : " %9.6f r(rva)

    reghdfe PI $control, absorb(`fe`s'') vce(unadjusted)
    scalar rssD_`s' = e(rss)
    foreach b in $control {
        scalar tD = _b[`b']/_se[`b']
        scalar r2d_`b' = tD^2/(tD^2 + e(df_r))       // R2 of D with Xj | X-j, FE
    }

    *---------------- B. benchmark bounds
    foreach b in $control {
        foreach k in 1 2 3 {
            ch_bound r2d_`b' r2y_`b' `k' `k' est_`s' se_`s' df_`s'
            post `BD' ("`nm`s''") ("`b'") (`k') (r2d_`b') (r2y_`b') (r(r2dz)) (r(r2yz)) ///
                (r(adj)) (r(adjse)) (r(adjt)) (r(adjt)/lam_`s')
            di "`b' k=`k': R2_DZ=" %7.4f r(r2dz) " R2_YZ=" %7.4f r(r2yz) ///
               " adj.est=" %9.5f r(adj) " adj.t=" %6.2f r(adjt)
        }
    }

    *---------------- D. clustered variant: same partial R2s, significance
    *                   threshold inflated by lambda = clustered/classical SE
    ch_rv t_`s' df_`s' 1 0.05 lam_`s'
    scalar rvacl_`s' = r(rva)
    di "Clustered t = " %6.3f tcl_`s' "  lambda = " %5.3f lam_`s' ///
       "  RV(q=1,a=.05, clustered) = " %8.6f r(rva)

    post `RV' ("`nm`s''") (est_`s') (se_`s') (t_`s') (df_`s') (r2yd_`s') (rv_`s') (rva_`s') ///
        (secl_`s') (tcl_`s') (G_`s') (lam_`s') (rvacl_`s')
    use "$SAMPLE", clear
}

*---------------- C. group benchmark: urban x year-month trends
* partial R2 that urban x YM FE add, beyond county + YM FE and controls,
*   for PSI (treatment model) and for Shannon given PSI (outcome model)
reghdfe PI $control, absorb(county year) vce(unadjusted)
keep if e(sample)
scalar rr = e(rss)
reghdfe PI $control, absorb(county year#urban) vce(unadjusted)
scalar r2d_urb = (rr - e(rss))/rr
reghdfe ShannonBD PI $control, absorb(county year) vce(unadjusted)
scalar rr = e(rss)
reghdfe ShannonBD PI $control, absorb(county year#urban) vce(unadjusted)
scalar r2y_urb = (rr - e(rss))/rr
di as res _n "Urban x YM trends: partial R2 with PSI = " %7.4f r2d_urb "   with Shannon | PSI = " %7.4f r2y_urb
foreach k in 0.25 0.5 1 {
    ch_bound r2d_urb r2y_urb `k' `k' est_1 se_1 df_1
    post `BD' ("`nm1'") ("Urban x YM trends (group)") (`k') (r2d_urb) (r2y_urb) (r(r2dz)) (r(r2yz)) ///
        (r(adj)) (r(adjse)) (r(adjt)) (r(adjt)/lam_1)
    di "urban x YM k=`k': adj.est=" %9.5f r(adj) "  adj.t=" %6.2f r(adjt)
}

postclose `RV'
postclose `BD'

use "$T2/tables/rv_tmp.dta", clear
format est se_classical %9.5f
format R2_YD RV_q1 RV_q1_a05 RV_q1_a05_clustered %9.5f
list, noobs sep(0) abbreviate(20)
export delimited using "$T2/tables/2_1_robustness_values.csv", replace
erase "$T2/tables/rv_tmp.dta"

use "$T2/tables/bd_tmp.dta", clear
format R2_* %8.5f
format adj_est adj_se %9.5f
format adj_t adj_t_clustered %6.2f
list, noobs sep(0) abbreviate(24)
export delimited using "$T2/tables/2_1_benchmark_bounds.csv", replace
save "$T2/tables/bounds_for_plot.dta", replace
erase "$T2/tables/bd_tmp.dta"

*--------------------------------------------------------------------------
* E. Contour plots (adjusted estimate and adjusted t) for each spec
*--------------------------------------------------------------------------
forvalues s = 1/2 {
    clear
    local n = 61
    set obs `=`n'*`n''
    gen r2dz = 0.0025*floor((_n-1)/`n')                 // 0 .. 0.15
    gen r2yz = 0.0025*mod(_n-1, `n')
    replace r2dz = 0.0001 if r2dz == 0
    replace r2yz = 0.0001 if r2yz == 0
    gen bias  = se_`s'*sqrt(r2yz*r2dz/(1 - r2dz)*df_`s')
    gen adj   = sign(est_`s')*(abs(est_`s') - bias)
    gen adjse = se_`s'*sqrt((1 - r2yz)/(1 - r2dz)*df_`s'/(df_`s' - 1))
    gen adjt  = adj/adjse
    * benchmark points (Duration k=1,2,3) for spec 1 only
    if `s' == 1 {
        append using "$T2/tables/bounds_for_plot.dta", keep(benchmark k R2_D_Z R2_Y_Z spec)
        keep if missing(spec) | (strpos(spec,"S1") & (benchmark=="Duration" | strpos(benchmark,"Urban")))
        gen pt_x = R2_D_Z
        gen pt_y = R2_Y_Z
        gen str20 pt_lab = cond(benchmark=="Duration", string(k) + "x Duration", ///
                            cond(benchmark!="", string(k) + "x urban-YM", ""))
        replace pt_x = . if pt_x > 0.15 | pt_y > 0.15
    }
    else {
        gen pt_x = .
        gen pt_y = .
        gen pt_lab = ""
    }
    local e = string(est_`s', "%6.4f")
    * Contours of the adjusted estimate are closed-form: an adjusted estimate
    * equal to share f of the original needs bias = (1-f)|est|, i.e.
    *   R2_YZ = B^2 (1 - R2_DZ) / R2_DZ,   B = (1-f)|est| / (se*sqrt(df))
    local K = se_`s'*sqrt(df_`s')
    local plots ""
    local txt ""
    foreach f in 0.8 0.6 0.4 0.2 0 {
        local B  = (1-`f')*abs(est_`s')/`K'
        local x0 = max(0.0002, `B'^2/(0.15 + `B'^2))
        local col = cond(`f'==0, "red", "navy")
        local pat = cond(`f'==0, "dash", "solid")
        local wid = cond(`f'==0, "thick", "medium")
        local plots `plots' (function y = (`B')^2*(1-x)/x, range(`x0' 0.15) lcolor(`col') lpattern(`pat') lwidth(`wid'))
        local yl = (`B')^2*(0.85)/0.15
        if `yl' <= 0.15 local txt `txt' text(`yl' 0.151 "`=round(100*`f')'% left", place(e) size(vsmall) color(`col'))
    }
    twoway `plots' ///
           (scatter pt_y pt_x, msymbol(D) mcolor(black) mlabel(pt_lab) mlabcolor(black) mlabsize(vsmall)), ///
        `txt' xscale(range(0 0.17)) ///
        xtitle("Partial R{superscript:2} of confounder with PSI") ///
        ytitle("Partial R{superscript:2} of confounder with Shannon") ///
        title("Adjusted PSI estimate: `nm`s''", size(medium)) ///
        subtitle("Estimate = `e'. Curves: share of the estimate left after confounding; red = zero", size(vsmall)) ///
        xlabel(0(0.03)0.15) ylabel(0(0.03)0.15) legend(off)
    graph export "$T2/figures/2_1_contour_estimate_S`s'.pdf", replace
    * t-value: red dashed line where the adjusted t reaches -1.96
    twoway (contourline adjt r2yz r2dz if !missing(r2dz), ccuts(-1.96) ///
                ccolors(red) clwidths(thick) clpatterns(dash)) ///
           (scatter pt_y pt_x, msymbol(D) mcolor(black) mlabel(pt_lab) mlabcolor(black) mlabsize(vsmall)), ///
        xtitle("Partial R{superscript:2} of confounder with PSI") ///
        ytitle("Partial R{superscript:2} of confounder with Shannon") ///
        title("Statistical significance: `nm`s''", size(medium)) ///
        subtitle("Beyond the red dashed line the adjusted estimate is not significant at 5% (classical SE)", size(vsmall)) ///
        xlabel(0(0.03)0.15) ylabel(0(0.03)0.15) legend(off)
    graph export "$T2/figures/2_1_contour_tvalue_S`s'.pdf", replace
}
erase "$T2/tables/bounds_for_plot.dta"

*--------------------------------------------------------------------------
* F. Cross-check with the official sensemakr (Stata) on FE-demeaned data.
*    Point estimate and SE match exactly by FWL; sensemakr's df ignores the
*    absorbed FE (N-k-1), so its RVs differ slightly from Part A.
*--------------------------------------------------------------------------
use "$SAMPLE", clear
reghdfe ShannonBD PI $control, absorb(county year) vce(unadjusted)
keep if e(sample)
foreach v in ShannonBD PI $control {
    quietly reghdfe `v', absorb(county year) resid(r_`v')
}
capture noisily sensemakr r_ShannonBD r_PI r_Temp r_Wind r_Pop r_Duration r_Carbon ///
    r_Water r_Green r_Farm r_Grass, treat(r_PI) benchmark(r_Duration) kd(1 2 3)
if _rc di as err "sensemakr cross-check could not run (rc=" _rc "); Part A results stand."
