*==========================================================================
* 6_3_meeting_facts.do
* PURPOSE : Numbers asked for in the 19 Nov meeting.
*   1. Of the 20,364 rows dropped by the real-PSI restriction, how many are
*      urban? What does "83%" mean?
*   2. Are the counties missing Area the same as those missing PSI?
*   3. Does the capacity file (Area) contain true zeros?
*==========================================================================
if "$ROOT" == "" quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
use "$SAMPLE", clear
bysort county: gen nrow = _N
keep if nrow > 1                               // regression sample: 46,371 rows
di as res "rows = " _N
* 1. urban composition
tab urban                                       // 52% of rows are urban
tab urban in_PI_file, row                       // 83.1% of URBAN rows have imputed PSI; 1.2% of rural
tab urban if in_PI_file==0                      // dropped rows: 98.7% urban
tab urban if in_PI_file==1                      // kept (real-PSI) rows: 15.8% urban
egen tagc = tag(county)
tab urban in_PI_file if tagc                    // counties: 694 of 847 urban missing; 9 of 1,497 rural
* 2. Area vs PSI missingness (counties in the analysis file)
preserve
    use "$DATA/IC.dta", clear
    keep id
    duplicates drop
    gen byte in_IC_file = 1
    tempfile ic
    save `ic'
restore
use "$SAMPLE", clear
merge m:1 id using `ic', keep(master match) nogen
replace in_IC_file = 0 if missing(in_IC_file)
egen tagc = tag(county)
tab in_PI_file in_IC_file if tagc               // 1,184 not in IC file; 473 also missing PSI
* 3. true zeros in the capacity file
use "$DATA/IC.dta", clear
count if ICtotal == 0                           // 11,699 of 22,880 county-years are true zeros
count
