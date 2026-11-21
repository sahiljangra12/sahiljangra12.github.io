*==========================================================================
* 3_5_sun_abraham.do
* PURPOSE : Sun & Abraham (2021) interaction-weighted event study on the
*           monthly data, never-treated counties as the control cohort.
*           A third heterogeneity-robust check on the same question.
* OUTPUT  : tables/3_5_sun_abraham.csv, figures/3_5_event_study_sa.pdf
*==========================================================================
use "$T3/data/staggered_monthly.dta", clear
keep if !missing(g_main)

* relative-time indicators for every period except the reference (-1)
summarize rel_year
local mn = -r(min)
local mx = r(max)
local leads ""
forvalues k = 2/`mn' {
    gen byte F`k' = (rel_year == -`k')
    local leads "`leads' F`k'"
}
local lags ""
forvalues k = 0/`mx' {
    gen byte L`k' = (rel_year == `k')
    local lags "`lags' L`k'"
}
gen cohort = cond(g_main == 0, ., g_main)

eventstudyinteract ShannonBD `leads' `lags', cohort(cohort) control_cohort(never_main) ///
    absorb(county year) vce(cluster county)

matrix bb = e(b_iw)
matrix VV = e(V_iw)
tempname S
postfile `S' str12 estimator int event_time double(b se) using "$T3/tables/sa.dta", replace
forvalues k = 5(-1)2 {
    capture post `S' ("SA") (-`k') (bb[1,"F`k'"]) (sqrt(VV["F`k'","F`k'"]))
}
post `S' ("SA") (-1) (0) (0)
forvalues k = 0/5 {
    capture post `S' ("SA") (`k') (bb[1,"L`k'"]) (sqrt(VV["L`k'","L`k'"]))
}
* overall post-adoption effect: simple average of event years 0-5
matrix w = J(1, colsof(bb), 0)
local cn : colnames bb
local j = 0
foreach nm of local cn {
    local ++j
    if inlist("`nm'","L0","L1","L2","L3","L4","L5") matrix w[1,`j'] = 1/6
}
matrix avg  = w*bb'
matrix vavg = w*VV*w'
post `S' ("SA_avg_0_5") (99) (avg[1,1]) (sqrt(vavg[1,1]))
di as res "Sun-Abraham average effect, years 0-5: " %8.4f avg[1,1] "  (SE " %6.4f sqrt(vavg[1,1]) ")"
postclose `S'

use "$T3/tables/sa.dta", clear
gen lo = b - 1.96*se
gen hi = b + 1.96*se
list, noobs sep(0)
export delimited using "$T3/tables/3_5_sun_abraham.csv", replace
twoway (rcap hi lo event_time if event_time != 99, lcolor(dkorange)) ///
       (scatter b event_time if event_time != 99, mcolor(dkorange)), ///
    yline(0, lpattern(dash)) xline(-0.5, lpattern(dot)) ///
    xtitle("Years relative to first solar policy") ytitle("Effect on Shannon diversity") ///
    title("Sun-Abraham event study (PSI-data counties)", size(medium)) ///
    subtitle("Control cohort: never-treated; reference year = -1; 95% CI", size(small)) ///
    xlabel(-5(1)5) legend(off)
graph export "$T3/figures/3_5_event_study_sa.pdf", replace
