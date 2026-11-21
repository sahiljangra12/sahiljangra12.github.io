*==========================================================================
* 1_5_twfe_diagnostics.do
* PURPOSE : Probe the identification of the main TWFE estimate.
*   Panel A  Who drives the effect? (missing-PSI counties, urban vs rural)
*   Panel B  Alternative treatment definitions (stock, binary)
*   Panel C  Observer effort (Duration) as a possible "bad control"
*   Panel D  Propensity-score matching with the matching weights APPLIED
* OUTPUT  : tables/1_5_twfe_diagnostics.csv / .rtf
* WHY     : Task 1, item 5 — the TWFE design is only credible if the
*           comparison group is valid; these checks test that directly.
*==========================================================================
use "$SAMPLE", clear

*------------------------------------------------ Panel A
eststo clear
eststo A1: reghdfe ShannonBD PI $control,                        absorb(county year)       cluster(county)
eststo A2: reghdfe ShannonBD PI $control if in_PI_file==1,       absorb(county year)       cluster(county)
eststo A3: reghdfe ShannonBD PI $control if urban==0,            absorb(county year)       cluster(county)
eststo A4: reghdfe ShannonBD PI $control if urban==1,            absorb(county year)       cluster(county)
eststo A5: reghdfe ShannonBD PI $control,                        absorb(county year#urban) cluster(county)
eststo A6: reghdfe ShannonBD PI $control,                        absorb(county year#prov)  cluster(county)
esttab A1 A2 A3 A4 A5 A6, keep(PI) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clust, fmt(0 0) labels("Obs" "Counties")) ///
    mtitles("Baseline" "PSI-data counties" "Rural only" "Urban only" "Urban x YM FE" "Province x YM FE") ///
    title("Panel A. Who drives the TWFE estimate?")
esttab A1 A2 A3 A4 A5 A6 using "$T1/tables/1_5_twfe_diagnostics.rtf", replace keep(PI) b(4) se(4) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust, fmt(0 0) labels("Obs" "Counties")) ///
    mtitles("Baseline" "PSI-data counties" "Rural only" "Urban only" "Urban x YM FE" "Province x YM FE") ///
    title("Panel A. Who drives the TWFE estimate?")

*------------------------------------------------ Panel B
eststo clear
eststo B1: reghdfe ShannonBD PI_stock $control if in_PI_file==1, absorb(county year) cluster(county)
eststo B2: reghdfe ShannonBD any_PSI  $control,                  absorb(county year) cluster(county)
eststo B3: reghdfe ShannonBD any_PSI  $control if in_PI_file==1, absorb(county year) cluster(county)
esttab B1 B2 B3, keep(PI_stock any_PSI) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clust, fmt(0 0)) mtitles("PSI stock (PSI-data)" "Any PSI>0 (all)" "Any PSI>0 (PSI-data)") ///
    title("Panel B. Alternative treatment definitions")
esttab B1 B2 B3 using "$T1/tables/1_5_twfe_diagnostics.rtf", append keep(PI_stock any_PSI) b(4) se(4) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust, fmt(0 0)) ///
    mtitles("PSI stock (PSI-data)" "Any PSI>0 (all)" "Any PSI>0 (PSI-data)") ///
    title("Panel B. Alternative treatment definitions")

*------------------------------------------------ Panel C
eststo clear
eststo C1: reghdfe ShannonBD PI $control_noD, absorb(county year) cluster(county)
eststo C2: reghdfe Duration  PI $control_noD, absorb(county year) cluster(county)
esttab C1 C2, keep(PI) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust, fmt(0 0)) ///
    mtitles("Shannon, no Duration" "Outcome = Duration") title("Panel C. Observer effort")
esttab C1 C2 using "$T1/tables/1_5_twfe_diagnostics.rtf", append keep(PI) b(4) se(4) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust, fmt(0 0)) ///
    mtitles("Shannon, no Duration" "Outcome = Duration") title("Panel C. Observer effort")

*------------------------------------------------ Panel D
* The authors run psmatch2 and then regress on the matched sample WITHOUT
* the weights (if _weight!=.). Here the weights are applied.
gen byte treated = (PI > 0)
eststo clear
psmatch2 treated $control i.year, outcome(ShannonBD) neighbor(1) caliper(0.05) common
eststo D1: reghdfe ShannonBD PI $control [aw=_weight] if _weight!=., absorb(county year) cluster(county)
drop _*
psmatch2 treated $control i.year, outcome(ShannonBD) neighbor(2) caliper(0.05) common
eststo D2: reghdfe ShannonBD PI $control [aw=_weight] if _weight!=., absorb(county year) cluster(county)
drop _*
psmatch2 treated $control i.year, outcome(ShannonBD) kernel common
di _n "Kernel weights of matched controls (far from uniform):"
summarize _weight if treated==0 & _weight!=., detail
eststo D3: reghdfe ShannonBD PI $control [aw=_weight] if _weight!=., absorb(county year) cluster(county)
drop _*
esttab D1 D2 D3, keep(PI) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust, fmt(0 0)) ///
    mtitles("1:1 NN, weighted" "1:2 NN, weighted" "Kernel, weighted") ///
    title("Panel D. Table S11 with matching weights applied")
esttab D1 D2 D3 using "$T1/tables/1_5_twfe_diagnostics.rtf", append keep(PI) b(4) se(4) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust, fmt(0 0)) ///
    mtitles("1:1 NN, weighted" "1:2 NN, weighted" "Kernel, weighted") ///
    title("Panel D. Table S11 with matching weights applied")
