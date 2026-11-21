*==========================================================================
* 1_4_reproduction_check.do
* PURPOSE : Side-by-side comparison of the paper's published estimates with
*           our re-estimation from the analysis sample.
* OUTPUT  : tables/1_4_reproduction_check.csv / .rtf
* WHY     : Task 1, item 3 — a single table proving the results reproduce.
*           Paper values typed from Zhang et al. (2026), Tables 1, 2, S7, S11.
*==========================================================================
use "$SAMPLE", clear

tempname R
postfile `R' str45 result double(paper_b paper_se our_b our_se our_N) ///
    using "$T1/tables/1_4_tmp.dta", replace

* Table 1 (three columns)
reghdfe ShannonBD PI, absorb(county year) cluster(county)
post `R' ("Table 1 col 1: PSI, no controls") (-0.0157) (0.0037) (_b[PI]) (_se[PI]) (e(N))
reghdfe ShannonBD PI Temp Wind Pop Duration Carbon, absorb(county year) cluster(county)
post `R' ("Table 1 col 2: PSI, 5 controls") (-0.0127) (0.0036) (_b[PI]) (_se[PI]) (e(N))
reghdfe ShannonBD PI $control, absorb(county year) cluster(county)
post `R' ("Table 1 col 3: PSI, 9 controls (MAIN)") (-0.0125) (0.0037) (_b[PI]) (_se[PI]) (e(N))

* Table S7 (IV)
reghdfe PI Sun_ccpu $control, absorb(county year) cluster(county) keepsingleton
post `R' ("Table S7 first stage: Sun_ccpu") (0.0252) (0.0046) (_b[Sun_ccpu]) (_se[Sun_ccpu]) (e(N))
ivreghdfe ShannonBD (PI = Sun_ccpu) $control, absorb(county year) cluster(county) keepsingleton
post `R' ("Table S7 second stage: PSI") (-0.1264) (0.0347) (_b[PI]) (_se[PI]) (e(N))
di "Kleibergen-Paap F = " e(widstat) "   (paper: 30.181)"

* Table S11 (PSM, authors' implementation)
gen treated = (PI > 0)
psmatch2 treated $control i.year, outcome(ShannonBD) neighbor(1) caliper(0.05) common
reghdfe ShannonBD PI $control if _weight != ., absorb(county year) cluster(county)
post `R' ("Table S11 col 1: 1:1 NN matching") (-0.0072) (0.0039) (_b[PI]) (_se[PI]) (e(N))
psmatch2 treated $control i.year, outcome(ShannonBD) neighbor(2) caliper(0.05) common
reghdfe ShannonBD PI $control if _weight != ., absorb(county year) cluster(county)
post `R' ("Table S11 col 2: 1:2 NN matching") (-0.0083) (0.0038) (_b[PI]) (_se[PI]) (e(N))
psmatch2 treated $control i.year, outcome(ShannonBD) kernel common
reghdfe ShannonBD PI $control if _weight != ., absorb(county year) cluster(county)
post `R' ("Table S11 col 3: kernel matching") (-0.0125) (0.0037) (_b[PI]) (_se[PI]) (e(N))
drop treated _*

* Table S12 col 8 (Simpson index)
reghdfe SimpsonBD PI $control, absorb(county year) cluster(county)
post `R' ("Table S12 col 8: SimpsonBD") (-0.0014) (0.0008) (_b[PI]) (_se[PI]) (e(N))
di as res "SimpsonBD: p-value = " %6.4f 2*ttail(e(df_r), abs(_b[PI]/_se[PI])) "  (paper: p < 0.10)"

* Table 2 (mechanisms)
reghdfe Ndvi PI $control, absorb(county year) cluster(county)
post `R' ("Table 2: NDVI") (-0.0609) (0.0138) (_b[PI]) (_se[PI]) (e(N))
reghdfe Nightlight PI $control, absorb(county year) cluster(county)
post `R' ("Table 2: Nightlight") (-0.2220) (0.0256) (_b[PI]) (_se[PI]) (e(N))
reghdfe LAI PI $control, absorb(county year) cluster(county)
post `R' ("Table 2: Leaf area index") (0.0039) (0.0007) (_b[PI]) (_se[PI]) (e(N))

postclose `R'
use "$T1/tables/1_4_tmp.dta", clear
gen diff_b  = round(our_b,  0.0001) - paper_b
gen diff_se = round(our_se, 0.0001) - paper_se
gen match = (abs(diff_b) < 0.00005 & abs(diff_se) < 0.00005)
format paper_b paper_se our_b our_se diff_b diff_se %9.4f
list, noobs sep(0) abbreviate(40)
count if match == 0
di as res "Results NOT matching the paper (to 4 decimals): " r(N)
export delimited using "$T1/tables/1_4_reproduction_check.csv", replace
erase "$T1/tables/1_4_tmp.dta"
