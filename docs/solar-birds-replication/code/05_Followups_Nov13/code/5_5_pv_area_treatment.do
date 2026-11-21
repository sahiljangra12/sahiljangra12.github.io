*==========================================================================
* 5_5_pv_area_treatment.do
* PURPOSE : Action item 3 (13 Nov). Use the land area of centralized solar
*           (PV) plants as the treatment instead of the policy index PSI.
* WHY     : PSI measures policy documents. What could harm birds is the
*           physical solar plant. The authors run this once (Table S12,
*           column 1); we stress-test it the same way we tested PSI.
* DATA    : Area = ICtotal*1000/0.15/1e6 (km2). ICtotal = cumulative
*           installed capacity (MW) of centralized PV in the county-year,
*           converted with 0.15 kW per m2 (authors' formula). Counties not in
*           IC.dta get Area = 0 (authors' rule) - flag in_IC_file.
* TESTS   : A  paper spec, urban x YM FE, province x YM FE, IC-file counties,
*              real-PSI counties, rural only
*           B  functional form: ln(1+Area), any plant (0/1)
*           C  timing: Area 1 and 2 years earlier, 1 year later (placebo)
*           D  measurement: does Area reduce birdwatchers? does the Shannon
*              effect remain when the number of birdwatchers is held fixed?
*              richness (species count) vs evenness
*           E  is PSI related to Area within a county?
*==========================================================================
if "$ROOT" == "" quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
global T5 "$ROOT/05_Followups_Nov13"

*------------------------------------------------ lags and leads of Area
use "$DATA/IC.dta", clear
keep id YEAR ICtotal
gen Area_raw = ICtotal*1000/0.15/1000000
xtset id YEAR
gen Area_l1 = L1.Area_raw
gen Area_l2 = L2.Area_raw
gen Area_f1 = F1.Area_raw
gen Area_f2 = F2.Area_raw
gen byte one = 1
tempfile icl
save `icl'

use "$SAMPLE", clear
merge m:1 id YEAR using `icl', keepus(Area_l1 Area_l2 Area_f1 one) keep(master match) nogen
gen byte in_IC_file = (one==1)
bysort id: egen tmp = max(in_IC_file)
replace in_IC_file = tmp
drop tmp one
foreach v in Area_l1 Area_l2 Area_f1 {
    replace `v' = 0 if missing(`v')
}
winsor2 Area_l1 Area_l2 Area_f1, cuts(1 99) replace
gen lnArea = ln(1 + Area)
gen byte anyPV = Area > 0
gen lnBN = ln(BN)
egen pym = group(prov year)

* descriptives
summarize Area, detail
tab urban, summarize(anyPV)
egen tagc = tag(county)
tab in_IC_file if tagc
drop tagc

*------------------------------------------------ A. comparison groups
eststo clear
eststo A1: reghdfe ShannonBD Area $control,                  absorb(county year)       cluster(county)
eststo A2: reghdfe ShannonBD Area $control,                  absorb(county year#urban) cluster(county)
eststo A3: reghdfe ShannonBD Area $control,                  absorb(county pym)        cluster(county)
eststo A4: reghdfe ShannonBD Area $control if in_IC_file==1, absorb(county year)       cluster(county)
eststo A5: reghdfe ShannonBD Area $control if in_PI_file==1, absorb(county year)       cluster(county)
eststo A6: reghdfe ShannonBD Area $control if urban==0,      absorb(county year)       cluster(county)
esttab A*, keep(Area) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust, fmt(0 0)) ///
    mtitles("Paper" "Urban x YM" "Prov x YM" "IC-file only" "Real-PSI only" "Rural only") ///
    title("A. Solar-plant area (km2) and ShannonBD")
esttab A* using "$T5/tables/5_5_pv_area.rtf", replace keep(Area) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust, fmt(0 0))

*------------------------------------------------ B. functional form
eststo clear
eststo B1: reghdfe ShannonBD lnArea $control, absorb(county year)       cluster(county)
eststo B2: reghdfe ShannonBD lnArea $control, absorb(county year#urban) cluster(county)
eststo B3: reghdfe ShannonBD anyPV  $control, absorb(county year)       cluster(county)
eststo B4: reghdfe ShannonBD anyPV  $control, absorb(county year#urban) cluster(county)
esttab B*, keep(lnArea anyPV) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) star(* 0.10 ** 0.05 *** 0.01) ///
    title("B. Functional form")
esttab B* using "$T5/tables/5_5_pv_area.rtf", append keep(lnArea anyPV) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) ///
    star(* 0.10 ** 0.05 *** 0.01)

*------------------------------------------------ C. timing
eststo clear
eststo C1: reghdfe ShannonBD Area_l1 $control,      absorb(county year)       cluster(county)
eststo C2: reghdfe ShannonBD Area_l2 $control,      absorb(county year)       cluster(county)
eststo C3: reghdfe ShannonBD Area_f1 $control,      absorb(county year)       cluster(county)
eststo C4: reghdfe ShannonBD Area_f1 $control,      absorb(county year#urban) cluster(county)
eststo C5: reghdfe ShannonBD Area_f1 Area $control, absorb(county year)       cluster(county)
eststo C6: reghdfe ShannonBD Area PI $control,      absorb(county year)       cluster(county)
esttab C*, keep(Area_l1 Area_l2 Area_f1 Area PI) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Lag 1" "Lag 2" "Lead 1" "Lead 1 urbYM" "Lead+current" "Area+PSI") ///
    title("C. Timing and horse race")
esttab C* using "$T5/tables/5_5_pv_area.rtf", append keep(Area_l1 Area_l2 Area_f1 Area PI) ///
    cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) star(* 0.10 ** 0.05 *** 0.01)

*------------------------------------------------ D. measurement (effort)
eststo clear
eststo D1: reghdfe lnBN      Area $control_noD,      absorb(county year)       cluster(county)
eststo D2: reghdfe lnBN      Area $control_noD,      absorb(county year#urban) cluster(county)
eststo D3: reghdfe ShannonBD Area lnBN $control,     absorb(county year)       cluster(county)
eststo D4: reghdfe ShannonBD Area lnBN $control,     absorb(county year#urban) cluster(county)
eststo D5: reghdfe Richness  Area $control,          absorb(county year)       cluster(county)
eststo D6: reghdfe Evenness  Area $control,          absorb(county year)       cluster(county)
eststo D7: reghdfe ShannonBD5 Area $control,         absorb(county year)       cluster(county)
esttab D*, keep(Area) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) star(* 0.10 ** 0.05 *** 0.01) stats(N, fmt(0)) ///
    mtitles("lnBN" "lnBN urbYM" "Shannon|lnBN" "Shannon|lnBN urbYM" "Richness" "Evenness" "Shannon (BT>=5)") ///
    title("D. Is the area effect an effort / measurement effect?")
esttab D* using "$T5/tables/5_5_pv_area.rtf", append keep(Area) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(N, fmt(0))

*------------------------------------------------ E. PSI and Area within county
use "$DATA/IC.dta", clear
keep id YEAR ICtotal
gen Area_raw = ICtotal*1000/0.15/1000000
xtset id YEAR
gen Area_f1 = F1.Area_raw
gen Area_f2 = F2.Area_raw
merge 1:1 id YEAR using "$DATA/PI.dta", keepus(PI) keep(match) nogen
keep if YEAR >= 2014
pwcorr PI Area_raw Area_f1 Area_f2, sig
eststo clear
eststo E1: reghdfe Area_raw PI, absorb(id YEAR) cluster(id)
eststo E2: reghdfe Area_f1  PI, absorb(id YEAR) cluster(id)
eststo E3: reghdfe Area_f2  PI, absorb(id YEAR) cluster(id)
esttab E*, keep(PI) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) mtitles("Area same yr" "Area +1 yr" "Area +2 yr") ///
    title("E. Within-county link between PSI and solar-plant area")

* Expected (verified): A1 -0.0387 (0.0118)  A2 -0.0298 (0.0110)
*   D1 -0.0843  D3 -0.0055 (p=0.62)  D5 -1.83 species  D6 +0.0039 (p=0.13)
*   E1 -0.035  E2 -0.062  E3 -0.054  (all negative)
