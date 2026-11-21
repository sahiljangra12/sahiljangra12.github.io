*==========================================================================
* 6_4_extra_checks.do
* PURPOSE : Three checks that complete the 19 Nov requests.
*   (1) dCDH with the paper's controls. did_multiplegt_dyn cannot take
*       controls in Stata/BE (2,048-variable limit), so the outcome is first
*       adjusted for the nine controls: their effect is estimated with
*       county and year FE (reghdfe) and subtracted ("covariate-adjusted
*       outcome"). Caveat: the control coefficients are estimated on all
*       county-years.
*   (2) dCDH with solar-plant AREA (km2) as the treatment - the physical
*       treatment the professor suggested - all counties and only counties
*       in the capacity file (true zeros).
*   (3) Did birding grow faster in urban districts? (backs the statement
*       that the urban-rural split drives who goes birding)
*==========================================================================
if "$ROOT" == "" quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
global T6 "$ROOT/06_Followups_Nov19"
global ctrl "Temp Wind Pop Duration Carbon Water Green Farm Grass"

*------------------------------------------------ (1) covariate-adjusted dCDH
use "$T6/data/countyyear_psi.dta", clear
reghdfe shannon_sa $ctrl, absorb(county YEAR) keepsingleton
predict double xbc, xb
gen double shannon_adj = shannon_sa - (xbc - _b[_cons])
label var shannon_adj "Shannon net of the nine controls"
did_multiplegt_dyn shannon_adj county YEAR PI, effects(5) placebo(3) normalized cluster(county) graph_off
did_multiplegt_dyn shannon_adj county YEAR PI if in_PI_file==1, effects(5) placebo(3) normalized cluster(county) graph_off
did_multiplegt_dyn shannon_adj county YEAR PI, effects(5) placebo(3) normalized trends_nonparam(urban) cluster(county) graph_off

*------------------------------------------------ (2) dCDH with Area
preserve
    use "$DATA/IC.dta", clear
    keep id YEAR ICtotal
    gen double Area = ICtotal*1000/0.15/1000000
    tempfile ic
    save `ic'
    keep id
    duplicates drop
    gen byte in_IC_file = 1
    tempfile icid
    save `icid'
restore
use "$T6/data/countyyear_psi.dta", clear
* county -> id link from the analysis sample
preserve
    use "$SAMPLE", clear
    keep county id
    duplicates drop
    tempfile cid
    save `cid'
restore
merge m:1 county using `cid', keep(master match) nogen
merge m:1 id YEAR using `ic', keep(master match) nogen
merge m:1 id using `icid', keep(master match) nogen
replace in_IC_file = 0 if missing(in_IC_file)
replace Area = 0 if missing(Area)
tab in_IC_file
summarize Area, detail
did_multiplegt_dyn shannon_sa county YEAR Area, effects(5) placebo(3) normalized cluster(county) graph_off
did_multiplegt_dyn shannon_sa county YEAR Area if in_IC_file==1, effects(5) placebo(3) normalized cluster(county) graph_off
did_multiplegt_dyn lnBN county YEAR Area, effects(5) placebo(3) normalized cluster(county) graph_off
did_multiplegt_stat shannon_sa county YEAR Area, estimator(was) placebo(1) cluster(county)
did_multiplegt_stat shannon_sa county YEAR Area if in_IC_file==1, estimator(was) placebo(1) cluster(county)

*------------------------------------------------ (3) urban vs rural birding growth
use "$ROOT/05_Followups_Nov13/data/county_month_grid.dta", clear
gen trend = YEAR - 2014
* share of months observed: extra yearly growth in urban districts
reghdfe obs c.trend#i.urban, absorb(county ym) cluster(county)
* number of birdwatchers (records), all grid months (0 if none)
reghdfe lnBN1 c.trend#i.urban, absorb(county ym) cluster(county)
* PSI in the same grid: is PSI higher where birding grew less?
reghdfe obs c.trend#i.urban c.trend#c.PI, absorb(county ym) cluster(county)
