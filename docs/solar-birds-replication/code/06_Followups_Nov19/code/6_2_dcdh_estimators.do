*==========================================================================
* 6_2_dcdh_estimators.do
* PURPOSE : de Chaisemartin & D'Haultfoeuille (dCDH) difference-in-
*           differences estimators with PSI as a MULTI-VALUED, NON-ABSORBING
*           treatment (no binarization), as requested on 19 Nov.
*   (A) did_multiplegt_dyn  - de Chaisemartin & D'Haultfoeuille (2024,
*       REStat 108(4)): event-study effects l = 1..5 years after a county's
*       PSI first changes, compared with counties that had the SAME PSI in
*       the first year and have not changed yet; placebos test pre-trends.
*   (B) did_multiplegt_stat - de Chaisemartin, D'Haultfoeuille, Pasquier,
*       Sow & Vazquez-Bare (2024+): average slope (AS / WAS) of the
*       outcome with respect to the treatment for units whose treatment
*       changes, compared with "stayers" whose treatment does not change
*       between two consecutive years (assumes no lagged effects).
* DATA    : county-year panel 2014-2023. Outcome = Shannon with
*           month-of-year effects removed, averaged over the observed months
*           (same outcome as Task 3). PSI is yearly, so the year is the
*           natural time unit.
* SAMPLES : paper-style (all counties; the 724 counties missing from the
*           policy file have PSI = 0 in every year, so they act as stayers)
*           and real-PSI (counties in the policy file only).
*==========================================================================
if "$ROOT" == "" quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
global T6 "$ROOT/06_Followups_Nov19"

foreach p in gtools did_multiplegt_dyn did_multiplegt_stat {
    capture which `p'
    if _rc capture noisily ssc install `p', replace
}

*------------------------------------------------ county-year panel
* Built from the full analysis sample (all 2,501 counties). Unlike Task 3,
* counties already treated in 2014 are KEPT: dCDH compares each county with
* counties that had the same PSI in the first year, so no pre-period with
* PSI = 0 is needed.
use "$SAMPLE", clear
capture confirm variable month
if _rc gen month = month(dofm(year))
reg ShannonBD i.month
predict double sh_res, residuals
summarize ShannonBD, meanonly
gen double shannon_sa = sh_res + r(mean)
drop sh_res
gen lnBN = ln(BN)
collapse (mean) shannon_sa ShannonBD lnBN PI $control (count) n_months = ShannonBD ///
         (first) in_PI_file urban prov, by(county YEAR)
xtset county YEAR
label var shannon_sa "Shannon (month-of-year effects removed), county-year mean"
label var PI "PSI (yearly)"
compress
save "$T6/data/countyyear_psi.dta", replace

* describe the treatment paths (how often PSI changes, stays, goes down)
sort county YEAR
by county: gen dPI = PI - PI[_n-1] if YEAR == YEAR[_n-1] + 1
gen byte up   = dPI > 0  & !missing(dPI)
gen byte down = dPI < 0  & !missing(dPI)
gen byte same = dPI == 0 & !missing(dPI)
tabstat up down same, by(in_PI_file) stat(mean n)
bysort county: egen everchange = max(up | down)
egen tagc = tag(county)
tab in_PI_file everchange if tagc
drop dPI up down same everchange tagc

global ctrl "Temp Wind Pop Duration Carbon Water Green Farm Grass"

*------------------------------------------------ (A) did_multiplegt_dyn
* A1 paper-style sample, no controls
capture noisily did_multiplegt_dyn shannon_sa county YEAR PI, effects(5) placebo(3) cluster(county) graph_off
* A2 normalized: effect per one unit of PSI (weighted over current + lagged doses)
capture noisily did_multiplegt_dyn shannon_sa county YEAR PI, effects(5) placebo(3) normalized cluster(county) graph_off
* A3 with the effort control Duration. NOTE: in Stata/BE any controls() in
*    did_multiplegt_dyn stop with 'no room to add more variables' (2,048 limit);
*    controls are therefore added with did_multiplegt_stat below instead.
capture noisily did_multiplegt_dyn shannon_sa county YEAR PI, effects(5) placebo(3) normalized controls(Duration) cluster(county) graph_off
* A4 comparisons only within urban / within rural (like urban x time FE)
capture noisily did_multiplegt_dyn shannon_sa county YEAR PI, effects(5) placebo(3) trends_nonparam(urban) cluster(county) graph_off
* A5 real-PSI counties only
capture noisily did_multiplegt_dyn shannon_sa county YEAR PI if in_PI_file==1, effects(5) placebo(3) cluster(county) graph_off
* A6 real-PSI, normalized, with the effort control
capture noisily did_multiplegt_dyn shannon_sa county YEAR PI if in_PI_file==1, effects(5) placebo(3) normalized controls(Duration) cluster(county) graph_off
* A7 continuous first-year PSI (polynomial of order 1), bootstrap SEs as the authors recommend
set seed 20261119
* NOT RUN by default: with ~120 different first-year PSI values this ran >12 minutes
* in Stata/BE without finishing. Remove the * to try it on a faster machine.
* capture noisily did_multiplegt_dyn shannon_sa county YEAR PI, effects(5) placebo(3) continuous(1) bootstrap(100, 20261119) normalized cluster(county) graph_off
* A8 event-study graph for the main specification (A1)
capture noisily did_multiplegt_dyn shannon_sa county YEAR PI, effects(5) placebo(3) cluster(county)
capture noisily graph export "$T6/figures/6_2_dcdh_dyn_eventstudy.png", replace width(1600)

*------------------------------------------------ (E) effort checks with dCDH
* E1 does PSI change the number of birdwatchers (checklists)? outcome = mean ln(BN)
capture noisily did_multiplegt_dyn lnBN county YEAR PI, effects(5) placebo(3) normalized cluster(county) graph_off
* E2 same, real-PSI counties
capture noisily did_multiplegt_dyn lnBN county YEAR PI if in_PI_file==1, effects(5) placebo(3) normalized cluster(county) graph_off
* E3 Shannon holding the number of birdwatchers fixed
capture noisily did_multiplegt_dyn shannon_sa county YEAR PI, effects(5) placebo(3) normalized controls(lnBN) cluster(county) graph_off
* E4 WAS for ln(birdwatchers)
capture noisily did_multiplegt_stat lnBN county YEAR PI, estimator(was) placebo(1) cluster(county)
* E5 WAS for Shannon controlling for ln(birdwatchers)
capture noisily did_multiplegt_stat shannon_sa county YEAR PI, estimator(was) placebo(1) controls(lnBN) cluster(county)

*------------------------------------------------ (B) did_multiplegt_stat
* B1 paper-style sample: average slope (AS) and weighted average slope (WAS)
capture noisily did_multiplegt_stat shannon_sa county YEAR PI, estimator(as was) placebo(1) cluster(county)
* B2 real-PSI counties only
capture noisily did_multiplegt_stat shannon_sa county YEAR PI if in_PI_file==1, estimator(as was) placebo(1) cluster(county)
* B3 with controls
capture noisily did_multiplegt_stat shannon_sa county YEAR PI, estimator(was) placebo(1) controls($ctrl) cluster(county)

*------------------------------------------------ benchmark: TWFE on the same county-year panel
reghdfe shannon_sa PI $ctrl, absorb(county YEAR) cluster(county)
reghdfe shannon_sa PI $ctrl if in_PI_file==1, absorb(county YEAR) cluster(county)
