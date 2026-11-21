*==========================================================================
* 1_3_data_structure.do
* PURPOSE : Document the structure of the data and how variables behave.
*           Every fact quoted in the Task 1 report (Section 2) is computed here.
* OUTPUT  : tables/1_3_data_structure_facts.csv  (one row per fact)
* WHY     : Task 1, items 1-2 — understand the panel and the treatment
*           before interpreting any regression.
*==========================================================================
tempname F
postfile `F' str70 fact double value using "$T1/tables/1_3_facts_tmp.dta", replace

*------------------------------------------------ A. The raw bird file
use "$DATA/Bird.dta", clear
post `F' ("Bird.dta: county-month rows") (_N)
egen tagc = tag(id)
count if tagc
post `F' ("Bird.dta: counties") (r(N))
di _n "Records (county-months) per year in Bird.dta:"
tab YEAR
forvalues y = 2014/2023 {
    count if YEAR == `y'
    post `F' ("Bird.dta: county-months in `y'") (r(N))
}

*------------------------------------------------ B. The analysis sample
use "$SAMPLE", clear
post `F' ("Analysis sample: county-months") (_N)
egen tagc = tag(county)
count if tagc
post `F' ("Analysis sample: counties") (r(N))
bysort county: gen nobs = _N
summarize nobs if tagc, detail
post `F' ("Months observed per county: median") (r(p50))
post `F' ("Months observed per county: min") (r(min))
post `F' ("Months observed per county: max") (r(max))
count if tagc & nobs == 1
post `F' ("Singleton counties (1 month only)") (r(N))

*------------------------------------------------ C. The treatment PSI
summarize PI
post `F' ("PSI mean (winsorized)") (r(mean))
post `F' ("PSI SD") (r(sd))
post `F' ("PSI max") (r(max))
count if PI == 0
post `F' ("Share of county-months with PSI = 0") (r(N)/_N)
di _n "PSI by year (median is zero every year):"
tabstat PI, by(YEAR) stats(mean p50 p75 max) format(%6.2f)
forvalues y = 2014/2023 {
    quietly summarize PI if YEAR==`y', detail
    post `F' ("PSI median in `y'") (r(p50))
}
bysort county: egen sdPI = sd(PI)
count if tagc & (sdPI == 0 | missing(sdPI))
post `F' ("Counties whose PSI never changes in sample") (r(N))
corr PI Area
post `F' ("Correlation PSI vs PV area (county-month)") (r(rho))

* PSI is a FLOW: it falls from one year to the next (raw PI.dta)
preserve
    use "$DATA/PI.dta", clear
    xtset id YEAR
    gen dPI = D.PI
    count if dPI < 0
    local ndown = r(N)
    count if !missing(dPI)
    post `F' ("PI.dta: share of county-years where PSI falls") (`ndown'/r(N))
    egen tagp = tag(id)
    count if tagp
    post `F' ("PI.dta: counties covered") (r(N))
    corr PI PI_stock PI_total
restore

*------------------------------------------------ D. Missing PSI coded as zero
count if tagc & in_PI_file == 0
post `F' ("Counties absent from PI.dta (PSI forced to 0)") (r(N))
count if in_PI_file == 0
post `F' ("Share of county-months with PSI imputed 0") (r(N)/_N)
di _n "Coverage of PSI data by unit type:"
tab urban in_PI_file, row
count if urban==1
local nu = r(N)
count if urban==1 & in_PI_file==0
post `F' ("Urban districts: share of obs with PSI imputed 0") (r(N)/`nu')
count if urban==0
local nr = r(N)
count if urban==0 & in_PI_file==0
post `F' ("Rural counties: share of obs with PSI imputed 0") (r(N)/`nr')
count if urban==1
post `F' ("Urban-district observations") (r(N))
count if urban==0
post `F' ("Rural-county observations") (r(N))

* validate the urban code rule with county names (…区 = district)
count if tagc & urban==1
local cu = r(N)
count if tagc & urban==1 & name_is_district==1
post `F' ("Urban-coded units named ...区: share") (r(N)/`cu')
count if tagc & urban==0
local cr = r(N)
count if tagc & urban==0 & name_is_district==1
post `F' ("Rural-coded units named ...区: share") (r(N)/`cr')
count if tagc & in_PI_file==0
local cm = r(N)
count if tagc & in_PI_file==0 & name_is_district==1
post `F' ("Missing-PSI counties named ...区: share") (r(N)/`cm')

* is it a merge failure? do missing counties appear in PI.dta under their NAME?
preserve
    use "$DATA/PI.dta", clear
    keep 县
    duplicates drop
    gen byte name_in_PI = 1
    tempfile pin
    save `pin'
restore
preserve
    keep if tagc & in_PI_file==0
    merge m:1 县 using `pin', keep(master match) nogen
    count if name_in_PI == 1
    post `F' ("Missing-PSI counties whose NAME is in PI.dta") (r(N))
restore

di _n "Missing-PSI share by province:"
tab 省 in_PI_file if tagc, row nofreq

*------------------------------------------------ E. Package and variable facts
local dtafiles : dir "$DATA" files "*.dta"
post `F' ("Number of .dta files in the authors' package") (`: word count `dtafiles'')
tempname fh
file open `fh' using "$ORIG/authors_CODE.do", read text
local nl = 0
file read `fh' line
while r(eof) == 0 {
    local ++nl
    file read `fh' line
}
file close `fh'
post `F' ("Lines in authors' CODE.do") (`nl')
use "$SAMPLE", clear
summarize ShannonBD
post `F' ("ShannonBD mean") (r(mean))
post `F' ("ShannonBD SD") (r(sd))
summarize Nightlight
post `F' ("Nightlight min (winsorized)") (r(min))
post `F' ("Nightlight max (winsorized)") (r(max))
use "$DATA/NL.dta", clear
summarize YEAR
post `F' ("NL.dta first year") (r(min))
post `F' ("NL.dta last year") (r(max))
summarize Nightlight
post `F' ("NL.dta Nightlight max (raw)") (r(max))

postclose `F'
use "$T1/tables/1_3_facts_tmp.dta", clear
format value %14.4f
list, noobs sep(0) abbreviate(70)
export delimited using "$T1/tables/1_3_data_structure_facts.csv", replace
erase "$T1/tables/1_3_facts_tmp.dta"
