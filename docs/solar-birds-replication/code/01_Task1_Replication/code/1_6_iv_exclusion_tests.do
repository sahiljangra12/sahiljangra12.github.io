*==========================================================================
* 1_6_iv_exclusion_tests.do
* PURPOSE : Empirical checks on the IV exclusion restriction.
*   Instrument Z = Sun_ccpu = ln(mean sunshine 1984-2013) / city CPU_t
*   Panel A  Reduced form and ZERO-FIRST-STAGE test: in counties where PSI
*            cannot change, Z must have no effect on Shannon if exclusion holds
*            (van Kippersluis & Rietveld 2018).
*   Panel B  Does Z predict other channels (effort, other policies, land)?
*   Panel C  IV under city clustering (level of the shift) and other specs.
* OUTPUT  : tables/1_6_iv_exclusion_tests.rtf
* WHY     : Task 1, item 6 — logic and possible violations of exclusion.
*==========================================================================
use "$SAMPLE", clear
bysort county: egen sdPI = sd(PI)
gen byte PI_constant = (sdPI==0 | missing(sdPI))

*------------------------------------------------ Panel A
eststo clear
eststo A1: reghdfe ShannonBD Sun_ccpu $control,                  absorb(county year) cluster(county)
* first stage is exactly zero where PSI is imputed 0 (PSI does not vary):
reghdfe PI Sun_ccpu $control if in_PI_file==0,                    absorb(county year) cluster(county)
eststo A2: reghdfe ShannonBD Sun_ccpu $control if in_PI_file==0, absorb(county year) cluster(county)
eststo A3: reghdfe ShannonBD Sun_ccpu $control if PI_constant==1,absorb(county year) cluster(county)
eststo A4: reghdfe ShannonBD Sun_ccpu $control if PI_constant==0,absorb(county year) cluster(county)
esttab A1 A2 A3 A4, keep(Sun_ccpu) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clust, fmt(0 0)) ///
    mtitles("Reduced form" "PSI imputed 0" "PSI constant" "PSI varies") ///
    title("Panel A. Reduced form and zero-first-stage tests (outcome: ShannonBD)")
esttab A1 A2 A3 A4 using "$T1/tables/1_6_iv_exclusion_tests.rtf", replace keep(Sun_ccpu) b(4) se(4) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust, fmt(0 0)) ///
    mtitles("Reduced form" "PSI imputed 0" "PSI constant" "PSI varies") ///
    title("Panel A. Reduced form and zero-first-stage tests (outcome: ShannonBD)")

*------------------------------------------------ Panel B
eststo clear
eststo B1: reghdfe Duration Sun_ccpu $control_noD, absorb(county year) cluster(county)
foreach y in CEI Coal Windexp Greenfin Ndvi LAI Nightlight {
    eststo B_`y': reghdfe `y' Sun_ccpu $control, absorb(county year) cluster(county)
}
esttab B1 B_*, keep(Sun_ccpu) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clust, fmt(0 0)) ///
    mtitles("Duration" "CEI" "Coal" "Windexp" "Greenfin" "NDVI" "LAI" "Nightlight") ///
    title("Panel B. Does the instrument predict other channels?")
esttab B1 B_* using "$T1/tables/1_6_iv_exclusion_tests.rtf", append keep(Sun_ccpu) b(4) se(4) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust, fmt(0 0)) ///
    mtitles("Duration" "CEI" "Coal" "Windexp" "Greenfin" "NDVI" "LAI" "Nightlight") ///
    title("Panel B. Does the instrument predict other channels?")

*------------------------------------------------ Panel C
eststo clear
eststo C1: ivreghdfe ShannonBD (PI = Sun_ccpu) $control, absorb(county year) cluster(county) keepsingleton
eststo C2: ivreghdfe ShannonBD (PI = Sun_ccpu) $control, absorb(county year) cluster(city) keepsingleton
eststo C3: ivreghdfe ShannonBD (PI = Sun_ccpu) $control, absorb(county year#urban) cluster(county) keepsingleton
eststo C4: ivreghdfe ShannonBD (PI = Sun_ccpu) $control if in_PI_file==1, absorb(county year) cluster(county) keepsingleton
eststo C5: ivreghdfe ShannonBD (PI = Sun_ccpu) $control_noD, absorb(county year) cluster(county) keepsingleton
esttab C1 C2 C3 C4 C5, keep(PI) b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clust widstat, fmt(0 0 2) labels("Obs" "Clusters" "Kleibergen-Paap F")) ///
    mtitles("Paper" "Cluster city" "Urban x YM FE" "PSI-data only" "No Duration") ///
    title("Panel C. IV estimate: inference and specification")
esttab C1 C2 C3 C4 C5 using "$T1/tables/1_6_iv_exclusion_tests.rtf", append keep(PI) b(4) se(4) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust widstat, fmt(0 0 2) labels("Obs" "Clusters" "Kleibergen-Paap F")) ///
    mtitles("Paper" "Cluster city" "Urban x YM FE" "PSI-data only" "No Duration") ///
    title("Panel C. IV estimate: inference and specification")
