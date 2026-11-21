*==========================================================================
* 5_3_sample_flow.do
* PURPOSE : Action items 5 and 6 (13 Nov). Trace every row and county from
*           the raw bird file to the regression sample, and explain the
*           "2,324 vs 2,344 counties" question.
* LOGIC   : Step 0  possible county-months  = counties x 120 months
*           Step 1  Bird.dta                = county-months with >= 1 record
*           Step 2  drop rows missing any control (authors' line
*                   "drop if missing(Temp, Wind, PD, BTN, CO2, ...)")
*           Step 3  reghdfe drops singleton counties (1 row only)
*           Step 4  IV sample: also needs sunshine and city CPU
*==========================================================================
if "$ROOT" == "" quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
global T5 "$ROOT/05_Followups_Nov13"
cd "$DATA"

*------------------------------------------------ Step 0: the universe
use "PD.dta", clear
keep id
duplicates drop
local n_univ = _N
di as res "Step 0: counties with population data = `n_univ'  ->  possible county-months = " `n_univ'*120

*------------------------------------------------ Step 1: raw bird file
use "Bird.dta", clear
local n1 = _N
egen tag = tag(id)
count if tag
local c1 = r(N)
drop tag
di as res "Step 1: Bird.dta rows = `n1', counties = `c1'"

*------------------------------------------------ Step 2: missing controls
* same merges as the authors' CODE.do (only the variables in the drop rule)
merge 1:1 id year using "BTN.dta", keepus(BT BN) keep(master match) nogen
merge m:1 id YEAR using "Climate.dta", keepus(Avt Wind) keep(master match) nogen
rename Avt Temp
merge m:1 id YEAR using "PD.dta",  keepus(PD)  keep(master match) nogen
merge m:1 id YEAR using "air.dta", keepus(CO2) keep(master match) nogen
merge m:1 id YEAR using "TD.dta",  keepus(Water Green Farm Grass) keep(master match) nogen
gen BTN = BT/BN

* which control is missing? (one row can miss several)
foreach v in Temp Wind PD BTN CO2 Water Green Farm Grass {
    quietly count if missing(`v')
    di "   rows missing `v': " r(N)
}
gen byte drop_ctrl = missing(Temp, Wind, PD, BTN, CO2, Water, Green, Farm, Grass)
count if drop_ctrl
local d2 = r(N)
tab YEAR drop_ctrl
* counties that lose ALL their rows
bysort id: egen allgone = min(drop_ctrl)
egen tag = tag(id)
count if tag & allgone
local cgone = r(N)
drop if drop_ctrl
local n2 = _N
drop tag
egen tag = tag(id)
count if tag
local c2 = r(N)
di as res "Step 2: rows dropped for missing controls = `d2'; counties lost entirely = `cgone'"
di as res "        analysis file: rows = `n2', counties = `c2'"

*------------------------------------------------ Step 3: singletons
use "$SAMPLE", clear
bysort county: gen nrow = _N
egen tag = tag(county)
count if tag & nrow==1
local s3 = r(N)
count if nrow > 1
local n3 = r(N)
count if tag & nrow > 1
local c3 = r(N)
di as res "Step 3: singleton counties dropped by reghdfe = `s3' (one row each)"
di as res "        regression sample: rows = `n3', counties = `c3'"
reghdfe ShannonBD PI $control, absorb(county year) cluster(county)
di as res "        check from reghdfe: N = " e(N) ", clusters = " e(N_clust)

*------------------------------------------------ Where does 2,324 come from?
* number of DIFFERENT counties observed in each calendar year
preserve
    contract YEAR county
    contract YEAR, freq(counties_observed)
    list, noobs sep(0)
restore
* -> 2023 has 2,324 counties. It is a one-year count, not a sample size.

*------------------------------------------------ months per county
preserve
    contract county, freq(months)
    summarize months, detail
restore

*------------------------------------------------ Step 4: IV sample
count if !missing(Sun_ccpu)
di as res "Step 4: IV sample rows (sunshine and city CPU available) = " r(N)
count if missing(CCPU)
di "   rows with missing city CPU = " r(N)
count if missing(sun)
di "   rows with missing sunshine = " r(N)

*------------------------------------------------ summary table
clear
input str60 step rows counties
"0 Possible county-months (2,778 counties x 120)" 333360 2778
"1 Bird.dta: county-months with a record"         48900  2561
"2 Drop rows missing a control (authors)"         46528  2501
"3 Drop singleton counties (reghdfe)"             46371  2344
"4 IV sample (needs sunshine and city CPU)"       37503  2077
end
list, noobs sep(0)
export delimited using "$T5/tables/5_3_sample_flow.csv", replace
* Expected numbers (verified): rows dropped in step 2 = 2,372
*   (1,839 missing Temp/Wind because the county is not in Climate.dta,
*    543 missing BTN, 11 missing land/population, 4 missing CO2;
*    overlapping), 60 counties lost entirely.
