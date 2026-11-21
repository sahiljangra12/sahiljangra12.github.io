*==========================================================================
* 5_4_missingness_test.do
* PURPOSE : Action item 2 (13 Nov). Does solar policy (PSI) predict WHETHER
*           a county-month has any bird record at all?
* WHY     : The paper only uses county-months where somebody reported birds
*           (about 14% of all possible county-months). If PSI changes the
*           chance that a month is observed, the observed sample is selected
*           by the treatment and the Shannon estimate can be biased.
* DESIGN  : 1. Build the FULL grid: every county with complete controls x
*              all 120 months (2014-2023), observed or not.
*           2. obs = 1 if Bird.dta has a record for that county-month.
*           3. Regress obs on PSI + controls (no Duration: it only exists
*              when somebody went birding) with county and year-month FE.
*           4. Repeat with urban x year-month FE and with real-PSI counties
*              only (the two fair-comparison checks from Task 1).
*           5. County-year version: months observed (0-12) and any month.
*==========================================================================
if "$ROOT" == "" quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
global T5 "$ROOT/05_Followups_Nov13"
cd "$DATA"

*------------------------------------------------ 1. county-year controls
use "Climate.dta", clear
keep id YEAR Avt Wind
rename Avt Temp
merge 1:1 id YEAR using "PD.dta",  keepus(PD)  keep(match) nogen
merge 1:1 id YEAR using "air.dta", keepus(CO2) keep(match) nogen
merge 1:1 id YEAR using "TD.dta",  keepus(Water Green Farm Grass) keep(match) nogen
drop if missing(Temp, Wind, PD, CO2, Water, Green, Farm, Grass)
gen Pop    = ln(PD)
gen Carbon = ln(CO2)
* PSI: authors' rule, missing -> 0; keep a flag for real PSI data
merge 1:1 id YEAR using "PI.dta", keepus(PI) keep(master match)
gen byte in_PI_file = (_merge==3)
bysort id: egen tmp = max(in_PI_file)
replace in_PI_file = tmp
drop tmp _merge
replace PI = 0 if missing(PI)
* solar-plant area (for item 3), missing -> 0 as the authors do
merge 1:1 id YEAR using "IC.dta", keepus(ICtotal) keep(master match) nogen
replace ICtotal = 0 if missing(ICtotal)
gen Area = ICtotal*1000/0.15/1000000
winsor2 PI Area Temp Wind Pop Carbon Water Green Farm Grass, cuts(1 99) replace
gen byte urban = mod(id,100) <= 20
di as res "county-years with complete controls: " _N

*------------------------------------------------ 2. expand to months
* bird records with the number of birdwatchers, keyed by id YEAR month
preserve
    use "Bird.dta", clear
    merge 1:1 id year using "BTN.dta", keepus(BN) keep(master match) nogen
    keep id YEAR month BN
    tempfile birds
    save `birds'
restore
expand 12
bysort id YEAR: gen month = _n
merge 1:1 id YEAR month using `birds', keep(master match)
gen byte obs = (_merge==3)
drop _merge
* number of birdwatchers, 0 when nobody reported
replace BN = 0 if missing(BN)
gen lnBN1 = ln(1 + BN)
gen ym = YEAR*100 + month
egen county = group(id)
bysort id: egen ever_obs = max(obs)
label var obs   "County-month has >= 1 bird record (1) or not (0)"
label var lnBN1 "ln(1 + number of birdwatchers), 0 if no record"
compress
save "$T5/data/county_month_grid.dta", replace
summarize obs
tab YEAR, summarize(obs)
tab urban, summarize(obs)

*------------------------------------------------ 3-4. county-month tests
global cg "Temp Wind Pop Carbon Water Green Farm Grass"
eststo clear
eststo M1: reghdfe obs   PI $cg,                    absorb(county ym)       cluster(county)
eststo M2: reghdfe obs   PI $cg if ever_obs==1,     absorb(county ym)       cluster(county)
eststo M3: reghdfe obs   PI $cg,                    absorb(county ym#urban) cluster(county)
eststo M4: reghdfe obs   PI $cg if in_PI_file==1,   absorb(county ym)       cluster(county)
eststo E1: reghdfe lnBN1 PI $cg,                    absorb(county ym)       cluster(county)
eststo E3: reghdfe lnBN1 PI $cg,                    absorb(county ym#urban) cluster(county)
eststo E4: reghdfe lnBN1 PI $cg if in_PI_file==1,   absorb(county ym)       cluster(county)
eststo A1: reghdfe obs   Area $cg,                  absorb(county ym)       cluster(county)
eststo A3: reghdfe obs   Area $cg,                  absorb(county ym#urban) cluster(county)
esttab M* E* A*, keep(PI Area) cells(b(fmt(5) star) se(fmt(5) par) p(fmt(3) par("[" "]"))) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clust, fmt(0 0)) ///
    mtitles("obs" "obs ever-obs" "obs urbYM" "obs realPSI" "lnBN1" "lnBN1 urbYM" "lnBN1 realPSI" "obs~Area" "obs~Area urbYM") ///
    title("Does the treatment predict whether a county-month is observed?")
esttab M* E* A* using "$T5/tables/5_4_missingness.rtf", replace keep(PI Area) cells(b(fmt(5) star) se(fmt(5) par) p(fmt(3) par("[" "]"))) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust, fmt(0 0))

*------------------------------------------------ 5. county-year version
collapse (sum) nmon = obs (first) PI $cg in_PI_file urban county, by(id YEAR)
gen byte anyobs = nmon > 0
eststo clear
eststo Y1: reghdfe anyobs PI $cg,                  absorb(county YEAR)       cluster(county)
eststo Y2: reghdfe anyobs PI $cg,                  absorb(county YEAR#urban) cluster(county)
eststo Y3: reghdfe anyobs PI $cg if in_PI_file==1, absorb(county YEAR)       cluster(county)
eststo N1: reghdfe nmon   PI $cg,                  absorb(county YEAR)       cluster(county)
eststo N2: reghdfe nmon   PI $cg,                  absorb(county YEAR#urban) cluster(county)
eststo N3: reghdfe nmon   PI $cg if in_PI_file==1, absorb(county YEAR)       cluster(county)
eststo I1: reghdfe nmon   PI $cg if nmon>0,        absorb(county YEAR)       cluster(county)
eststo I2: reghdfe nmon   PI $cg if nmon>0,        absorb(county YEAR#urban) cluster(county)
eststo I3: reghdfe nmon   PI $cg if nmon>0 & in_PI_file==1, absorb(county YEAR) cluster(county)
esttab Y* N* I*, keep(PI) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) star(* 0.10 ** 0.05 *** 0.01) stats(N, fmt(0)) ///
    mtitles("any paper" "any urbY" "any realPSI" "months paper" "months urbY" "months realPSI" ///
            "months|>0 paper" "months|>0 urbY" "months|>0 realPSI") ///
    title("County-year: any month observed / number of months observed")
esttab Y* N* I* using "$T5/tables/5_4_missingness.rtf", append keep(PI) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(N, fmt(0))

* Expected (verified): obs on PSI, paper FE  -0.00549 (se 0.00087)
*                      urban x YM FE         +0.00008 (se 0.00083)
*                      real-PSI only         +0.00022 (se 0.00083)
