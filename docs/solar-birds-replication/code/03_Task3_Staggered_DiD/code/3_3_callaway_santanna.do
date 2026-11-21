*==========================================================================
* 3_3_callaway_santanna.do
* PURPOSE : Callaway & Sant'Anna (2021) group-time ATT(g,t), aggregated to
*           an overall ATT and an event study, with NOT-YET-TREATED counties
*           as controls (never-treated included).
* DATA    : county-year panel (monthly Shannon averaged within year after
*           removing month-of-year effects). The panel is UNBALANCED: by default
*           csdid would balance it by dropping every county not observed in all
*           10 years (903 of 939 counties). bal(pair) instead balances each 2x2
*           comparison separately, so every county observed in both years of a
*           comparison is used.
* SPECS   : M1 main sample, unconditional parallel trends
*           M2 main sample, parallel trends conditional on urban
*           P1 paper-style sample (missing-PSI counties = never treated)
* OUTPUT  : tables/3_3_cs_att.csv, tables/3_3_cs_event.csv,
*           figures/3_3_event_study_cs_*.pdf
*==========================================================================
*--------------------------------------------------------------------------
* Helper: aggregate csdid's ATT(g,t) cells. Cells that cannot be estimated
* (tiny cohorts) must be excluded with -dropmissing-; the option syntax differs
* across csdid versions, so each variant is tried and the one used is logged.
* Returns row vectors _B (estimates) and _SE (standard errors).
*--------------------------------------------------------------------------
capture program drop cs_agg
program define cs_agg
    syntax anything(name=type) [, Window(string)]
    local w ""
    if "`window'" != "" local w "window(`window')"
    local used ""
    foreach opt in "post dropmissing" "dropmissing post" "dropmissing" "post" {
        capture noisily estat `type', `w' `opt'
        if _rc == 0 {
            local used "`opt'"
            continue, break
        }
    }
    if "`used'" == "" {
        di as err "estat `type' failed with every option set"
        exit 498
    }
    di as res "estat `type' ran with options: `used'"
    if strpos("`used'", "post") {
        matrix _B = e(b)
        matrix _V = e(V)
    }
    else {
        capture confirm matrix r(b)
        if !_rc {
            matrix _B = r(b)
            matrix _V = r(V)
        }
        else {
            matrix _T = r(table)
            matrix _B = _T[1, 1...]
            matrix _V = diag(_T[2, 1...])
            forvalues i = 1/`=colsof(_V)' {
                matrix _V[`i',`i'] = _V[`i',`i']^2
            }
        }
    }
    matrix _SE = _B
    forvalues i = 1/`=colsof(_B)' {
        matrix _SE[1,`i'] = sqrt(_V[`i',`i'])
    }
    matrix list _B
    matrix list _SE
end

tempname A
postfile `A' str40 spec double(att se N_cy) using "$T3/tables/cs_att.dta", replace
tempname E
postfile `E' str40 spec int event_time double(b se) using "$T3/tables/cs_event.dta", replace

local specs "M1 M2 P1"
local lab_M1 "Main sample, unconditional"
local lab_M2 "Main sample, conditional on urban"
local lab_P1 "Paper-style sample (missing PSI = never)"

foreach s of local specs {
    use "$T3/data/staggered_countyyear.dta", clear
    if "`s'" == "P1" local gv g_paper
    else {
        local gv g_main
        keep if !missing(g_main)
    }
    local x ""
    if "`s'" == "M2" local x "urban"
    di as res _n "================ CS: `lab_`s'' ================"
    * how unbalanced is the panel? (counties observed in all 10 years)
    preserve
        bysort county: gen byte nyears = _N
        egen byte tagc = tag(county)
        count if tagc
        local nc = r(N)
        count if tagc & nyears < 10
        di as res "Counties: `nc'; not observed in all 10 years: " r(N)
    restore

    set seed 20261107
    capture noisily csdid shannon_sa `x', ivar(county) time(YEAR) gvar(`gv') notyet bal(pair) rseed(20261107)
    if _rc csdid shannon_sa `x', ivar(county) time(YEAR) gvar(`gv') notyet bal(pair)
    * number of counties and county-years entering the estimation
    quietly count if e(sample)
    local Ncy = r(N)
    di as res "County-years used: `Ncy'"
    * pre-test of parallel trends (all pre-treatment ATT(g,t) = 0)
    capture noisily estat pretrend
    estimates store cs_full_`s'

    * overall ATT (simple aggregation)
    cs_agg simple
    post `A' ("`lab_`s''") (_B[1,1]) (_SE[1,1]) (`Ncy')
    di "Overall ATT = " %8.4f _B[1,1] "  (SE " %6.4f _SE[1,1] ")"

    * event-study aggregation, window -5..+5
    estimates restore cs_full_`s'
    cs_agg event, window(-5 5)
    local names : colnames _B
    local j = 0
    foreach nm of local names {
        local ++j
        if ustrregexm("`nm'", "^[Tt]m([0-9]+)$") {
            post `E' ("`lab_`s''") (-real(ustrregexs(1))) (_B[1,`j']) (_SE[1,`j'])
        }
        else if ustrregexm("`nm'", "^[Tt]p([0-9]+)$") {
            post `E' ("`lab_`s''") (real(ustrregexs(1))) (_B[1,`j']) (_SE[1,`j'])
        }
        else di "`nm' = " %8.4f _B[1,`j'] "  (SE " %6.4f _SE[1,`j'] ")"
    }

    * cohort-specific ATTs
    estimates restore cs_full_`s'
    capture noisily cs_agg group
}
postclose `A'
postclose `E'

use "$T3/tables/cs_att.dta", clear
list, noobs
export delimited using "$T3/tables/3_3_cs_att.csv", replace

use "$T3/tables/cs_event.dta", clear
gen lo = b - 1.96*se
gen hi = b + 1.96*se
export delimited using "$T3/tables/3_3_cs_event.csv", replace
local i = 0
foreach sp in "Main sample, unconditional" "Main sample, conditional on urban" "Paper-style sample (missing PSI = never)" {
    local ++i
    twoway (rcap hi lo event_time if spec=="`sp'", lcolor(maroon)) ///
           (scatter b event_time if spec=="`sp'", mcolor(maroon)), ///
        yline(0, lpattern(dash)) xline(-0.5, lpattern(dot)) ///
        xtitle("Years relative to first solar policy") ytitle("ATT on Shannon diversity") ///
        title("Callaway-Sant'Anna event study", size(medium)) subtitle("`sp'; 95% CI", size(small)) ///
        xlabel(-5(1)5) legend(off)
    graph export "$T3/figures/3_3_event_study_cs_`i'.pdf", replace
}
