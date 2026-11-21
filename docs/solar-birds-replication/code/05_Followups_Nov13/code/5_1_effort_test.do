*==========================================================================
* 5_1_effort_test.do
* PURPOSE : Prof. Ferraro's question (12 Nov meeting): does solar policy
*           change birdwatching EFFORT? If PSI lowers the number of
*           birdwatchers or total birding time, the Shannon "effect" may be
*           measurement (fewer observers see fewer species), not fewer birds.
* NOTE    : One-way test. A decline suggests an effort/measurement channel;
*           no change does not rule it out (birders may move within a county).
* DATA    : BT = total birdwatching time in the county-month (raw)
*           BN = number of birdwatchers in the county-month (raw)
*           Duration = ln(BT/BN + 1), winsorized (the paper's control)
*==========================================================================
quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
use "$SAMPLE", clear
gen lnBT = ln(BT + 1)          // log total birding time
gen lnBN = ln(BN)              // log number of birdwatchers (BN >= 1)
label var lnBT "ln(total birdwatching time + 1)"
label var lnBN "ln(number of birdwatchers)"

eststo clear
foreach y in lnBT lnBN Duration BN {
    * paper's fixed effects
    eststo `y'_p: reghdfe `y' PI $control_noD, absorb(county year)       cluster(county)
    * urban and rural get their own monthly trends
    eststo `y'_u: reghdfe `y' PI $control_noD, absorb(county year#urban) cluster(county)
    * only counties with real PSI data
    eststo `y'_r: reghdfe `y' PI $control_noD if in_PI_file==1, absorb(county year) cluster(county)
}
esttab lnBT_* lnBN_* , keep(PI) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("lnBT paper" "lnBT urbYM" "lnBT realPSI" "lnBN paper" "lnBN urbYM" "lnBN realPSI")
esttab Duration_* BN_*, keep(PI) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Dur paper" "Dur urbYM" "Dur realPSI" "BN paper" "BN urbYM" "BN realPSI")

* Does the Shannon effect survive holding the number of birdwatchers fixed?
* (Caution: lnBN may itself be affected by policy, i.e. a possible bad control.)
reghdfe ShannonBD PI $control lnBN,      absorb(county year) cluster(county)
reghdfe ShannonBD PI $control lnBN lnBT, absorb(county year) cluster(county)
