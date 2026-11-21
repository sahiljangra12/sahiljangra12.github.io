*==========================================================================
* 3_4_imputation_bjs.do
* PURPOSE : Borusyak, Jaravel & Spiess (2024) imputation estimator on the
*           MONTHLY data: county and year-month fixed effects are estimated
*           on untreated observations only, untreated outcomes are imputed
*           for treated observations, and effects are averaged by event year.
* WHY     : Uses the authors' own monthly unit and fixed-effect structure,
*           handles the unbalanced panel, and avoids forbidden comparisons.
* SPECS   : main sample; paper-style sample
* OUTPUT  : tables/3_4_bjs.csv, figures/3_4_event_study_bjs_*.pdf
*==========================================================================
tempname B
postfile `B' str40 spec int event_time double(b se) using "$T3/tables/bjs.dta", replace

foreach s in main paper {
    use "$T3/data/staggered_monthly.dta", clear
    if "`s'" == "main" {
        keep if !missing(g_main)
        gen Ei = cond(g_main == 0, ., g_main)
        local lab "Main sample"
    }
    else {
        gen Ei = cond(g_paper == 0, ., g_paper)
        local lab "Paper-style sample (missing PSI = never)"
    }
    di as res _n "================ BJS: `lab' ================"
    * Imputation needs every county and every year-month to have at least one
    * UNTREATED observation (their fixed effects are estimated on untreated data
    * only). Drop the few that never do, iterating until stable.
    gen byte untreated = missing(Ei) | YEAR < Ei
    local dropped = 1
    while `dropped' > 0 {
        local n0 = _N
        bysort county: egen u_c = max(untreated)
        bysort year:   egen u_t = max(untreated)
        keep if u_c == 1 & u_t == 1
        drop u_c u_t
        local dropped = `n0' - _N
    }

    * overall ATT (all post-adoption observations, equally weighted)
    capture noisily did_imputation ShannonBD county YEAR Ei, fe(county year) cluster(county) autosample
    if _rc {
        di as err "year-month FE not imputable; falling back to county + year FE"
        local fe "county YEAR"
        did_imputation ShannonBD county YEAR Ei, fe(`fe') cluster(county) autosample
    }
    else local fe "county year"
    post `B' ("`lab'") (99) (_b[tau]) (_se[tau])

    * event study: horizons 0-5, pre-trend coefficients for 5 years
    did_imputation ShannonBD county YEAR Ei, fe(`fe') cluster(county) ///
        horizons(0/5) pretrends(5) autosample
    di as res "Fixed effects used: `fe'"
    estimates store bjs_`s'
    forvalues k = 0/5 {
        post `B' ("`lab'") (`k') (_b[tau`k']) (_se[tau`k'])
    }
    forvalues k = 1/5 {
        post `B' ("`lab'") (-`k') (_b[pre`k']) (_se[pre`k'])
    }
    test pre1 pre2 pre3 pre4 pre5
    di as res "Joint pre-trend test p = " %5.3f r(p)
}
postclose `B'

use "$T3/tables/bjs.dta", clear
gen lo = b - 1.96*se
gen hi = b + 1.96*se
list, noobs sep(0)
export delimited using "$T3/tables/3_4_bjs.csv", replace
local i = 0
foreach sp in "Main sample" "Paper-style sample (missing PSI = never)" {
    local ++i
    twoway (rcap hi lo event_time if spec=="`sp'" & event_time != 99, lcolor(dkgreen)) ///
           (scatter b event_time if spec=="`sp'" & event_time != 99, mcolor(dkgreen)), ///
        yline(0, lpattern(dash)) xline(-0.5, lpattern(dot)) ///
        xtitle("Years relative to first solar policy") ytitle("Effect on Shannon diversity") ///
        title("Borusyak-Jaravel-Spiess imputation event study", size(medium)) ///
        subtitle("`sp'; 95% CI", size(small)) xlabel(-5(1)5) legend(off)
    graph export "$T3/figures/3_4_event_study_bjs_`i'.pdf", replace
}
