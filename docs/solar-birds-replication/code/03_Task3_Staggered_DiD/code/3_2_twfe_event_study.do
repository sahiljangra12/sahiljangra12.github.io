*==========================================================================
* 3_2_twfe_event_study.do
* PURPOSE : Conventional ("naive") TWFE estimates on the binary adoption
*           design, as the benchmark that the heterogeneity-robust
*           estimators (3_3-3_5) are compared against.
*   (a) static TWFE:   Shannon on post-adoption dummy
*   (b) dynamic TWFE:  event-time dummies, -5..+5, reference year -1,
*                      endpoints binned
* WHY     : Under staggered timing and heterogeneous effects, TWFE uses
*           already-treated counties as controls ("forbidden comparisons";
*           Goodman-Bacon 2021; Baker et al. 2025), so it can be biased.
* OUTPUT  : tables/3_2_twfe.csv, figures/3_2_event_study_twfe.pdf
*==========================================================================
use "$T3/data/staggered_monthly.dta", clear
keep if !missing(g_main)                       // main sample

*------------------------------------------------ (a) static
reghdfe ShannonBD post $control, absorb(county year) cluster(county)
scalar static_b = _b[post]
scalar static_se = _se[post]
scalar static_N = e(N)

*------------------------------------------------ (b) dynamic
gen ev = rel_year
replace ev = -5 if ev < -5 & !missing(ev)
replace ev =  5 if ev >  5 & !missing(ev)
forvalues k = 5(-1)2 {
    gen byte lead`k' = (ev == -`k')
}
forvalues k = 0/5 {
    gen byte lag`k' = (ev == `k')
}
reghdfe ShannonBD lead5 lead4 lead3 lead2 lag0-lag5 $control, absorb(county year) cluster(county)
test lead5 lead4 lead3 lead2
scalar pre_p = r(p)
di as res "Joint test of pre-trends (leads = 0): p = " %5.3f pre_p

tempname P
postfile `P' str12 estimator int event_time double(b se) using "$T3/tables/es_twfe.dta", replace
forvalues k = 5(-1)2 {
    post `P' ("TWFE") (-`k') (_b[lead`k']) (_se[lead`k'])
}
post `P' ("TWFE") (-1) (0) (0)
forvalues k = 0/5 {
    post `P' ("TWFE") (`k') (_b[lag`k']) (_se[lag`k'])
}
post `P' ("TWFE_static") (99) (static_b) (static_se)
postclose `P'

use "$T3/tables/es_twfe.dta", clear
gen lo = b - 1.96*se
gen hi = b + 1.96*se
export delimited using "$T3/tables/3_2_twfe.csv", replace
twoway (rcap hi lo event_time if estimator=="TWFE", lcolor(navy)) ///
       (scatter b event_time if estimator=="TWFE", mcolor(navy)), ///
    yline(0, lpattern(dash)) xline(-0.5, lpattern(dot)) ///
    xtitle("Years relative to first solar policy") ytitle("Effect on Shannon diversity") ///
    title("Dynamic TWFE event study (PSI-data counties)", size(medium)) ///
    subtitle("Reference year = -1; 95% CI; county-clustered SE", size(small)) ///
    xlabel(-5(1)5) legend(off)
graph export "$T3/figures/3_2_event_study_twfe.pdf", replace
