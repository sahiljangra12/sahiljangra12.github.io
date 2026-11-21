*==========================================================================
* 3_1_adoption_timing.do
* PURPOSE : Turn the continuous, annual PSI into a STAGGERED ADOPTION design.
*   Adoption year g = first year (2014-2023) in which a county's PSI > 0,
*   taken from the full annual policy file PI.dta (not only the months in
*   which birds were recorded). Treatment is treated as absorbing: once a
*   county has issued solar policy it stays "treated".
* SAMPLES :
*   main  : counties present in PI.dta (PSI actually measured).
*           never-treated = counties in PI.dta with PSI = 0 in every year.
*   paper : adds the 724 counties absent from PI.dta as never-treated
*           (this is what the authors' "PSI = 0 if missing" implies).
*   Counties already treated in 2014 have no pre-period and are dropped.
* OUTPUT  : data/staggered_monthly.dta, data/staggered_countyyear.dta
*           tables/3_1_cohort_sizes.csv
*==========================================================================
capture mkdir "$T3/data"

*------------------------------------------------ adoption year from PI.dta
use "$DATA/PI.dta", clear
keep id YEAR PI
bysort id: egen first_pos = min(cond(PI > 0, YEAR, .))
bysort id (YEAR): gen byte tag = (_n == 1)
* how often does PSI return to 0 after adoption? (absorbing-treatment check)
count if YEAR > first_pos & !missing(first_pos)
local npost = r(N)
count if YEAR > first_pos & !missing(first_pos) & PI == 0
di as res "Share of post-adoption county-years with PSI = 0: " %5.3f r(N)/`npost'
keep if tag
keep id first_pos
tempfile adopt
save `adopt'

*------------------------------------------------ attach to analysis sample
use "$SAMPLE", clear
merge m:1 id using `adopt', keep(master match) nogen

* g  : adoption year (csdid convention: 0 = never treated)
gen g_main  = cond(in_PI_file==1, cond(missing(first_pos), 0, first_pos), .)
gen g_paper = cond(in_PI_file==1, g_main, 0)
label var g_main  "Adoption year; 0 = never (PSI-data counties only)"
label var g_paper "Adoption year; 0 = never (missing-PSI counties = never)"

* drop counties treated in the first year (no pre-period)
gen byte always_treated = (first_pos == 2014)
egen tagc = tag(county)
count if tagc & always_treated
di as res "Counties already treated in 2014 (dropped): " r(N)
drop if always_treated

* relative time and indicators
gen rel_year = YEAR - first_pos if !missing(first_pos)
gen byte post = (YEAR >= first_pos) if !missing(first_pos)
replace post = 0 if missing(first_pos)
gen byte never_main  = (g_main  == 0) if !missing(g_main)
gen byte never_paper = (g_paper == 0)

* cohort sizes (counties)
preserve
    keep if tagc
    gen sample_main = !missing(g_main)
    collapse (count) counties_paper = id (sum) counties_main = sample_main, by(g_paper)
    rename g_paper adoption_year
    list, noobs sep(0)
    export delimited using "$T3/tables/3_1_cohort_sizes.csv", replace
restore
tab g_main if tagc, missing

* deseasonalised Shannon (removes month-of-year composition before
* aggregating months to county-years)
reg ShannonBD i.month_of_year
predict double sh_res, residuals
summarize ShannonBD, meanonly
gen double shannon_sa = sh_res + r(mean)
drop sh_res
label var shannon_sa "Shannon, month-of-year effects removed"

compress
save "$T3/data/staggered_monthly.dta", replace

*------------------------------------------------ county-year panel (for CS)
collapse (mean) shannon_sa ShannonBD Duration (count) n_months = ShannonBD ///
    (first) g_main g_paper first_pos urban prov in_PI_file, by(county id YEAR)
xtset county YEAR
di as res "County-years: " _N
compress
save "$T3/data/staggered_countyyear.dta", replace
