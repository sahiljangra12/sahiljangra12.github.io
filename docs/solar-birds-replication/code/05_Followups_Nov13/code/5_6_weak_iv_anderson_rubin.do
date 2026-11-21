*==========================================================================
* 5_6_weak_iv_anderson_rubin.do
* PURPOSE : Action item 4 (13 Nov). Is the instrument strong enough, and is
*           the IV estimate still significant with inference that remains
*           valid when the instrument is weak?
* MODEL   : ShannonBD = b*PSI + controls + county FE + year-month FE
*           PSI instrumented by Z = Sun_ccpu = ln(sunshine) / city CPU
* PARTS   : 1  2SLS + Kleibergen-Paap F (= Montiel Olea-Pflueger effective F
*              when there is ONE instrument and ONE endogenous variable)
*           2  What is the "F = 8" in Table S10? (joint F, not instrument F)
*           3  Effective F with weakivtest (on FWL-residualized variables)
*           4  Anderson-Rubin (AR) confidence set by test inversion (grid)
*              for county, city and province clustering and the two
*              fair-comparison specifications
*           5  weakiv cross-check (AR, CLR, K)
*           6  "Plausibly exogenous" IV: subtract the direct effect of Z
*              estimated in counties where PSI cannot respond (zero first
*              stage, van Kippersluis & Rietveld 2018)
* NOTE    : The AR test is robust to a WEAK instrument. It does NOT test the
*           exclusion restriction: if Z affects birds directly, AR is wrong too.
*==========================================================================
if "$ROOT" == "" quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
global T5 "$ROOT/05_Followups_Nov13"
use "$SAMPLE", clear
keep if !missing(Sun_ccpu)
di as res "IV sample: " _N " rows"

*------------------------------------------------ 1. 2SLS and KP F
eststo clear
eststo I1: ivreghdfe ShannonBD (PI = Sun_ccpu) $control, absorb(county year)       cluster(county) keepsingleton
eststo I2: ivreghdfe ShannonBD (PI = Sun_ccpu) $control, absorb(county year)       cluster(city)   keepsingleton
eststo I3: ivreghdfe ShannonBD (PI = Sun_ccpu) $control, absorb(county year)       cluster(prov)   keepsingleton
eststo I4: ivreghdfe ShannonBD (PI = Sun_ccpu) $control, absorb(county year#urban) cluster(county) keepsingleton
eststo I5: ivreghdfe ShannonBD (PI = Sun_ccpu) $control, absorb(county year#urban) cluster(city)   keepsingleton
eststo I6: ivreghdfe ShannonBD (PI = Sun_ccpu) $control if in_PI_file==1, absorb(county year) cluster(county) keepsingleton
eststo I7: ivreghdfe ShannonBD (PI = Sun_ccpu) $control if in_PI_file==1, absorb(county year) cluster(city)   keepsingleton
esttab I*, keep(PI) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clust widstat, fmt(0 0 2) labels("Obs" "Clusters" "KP F = effective F")) ///
    mtitles("cl county" "cl city" "cl prov" "urbYM cl county" "urbYM cl city" "realPSI cl county" "realPSI cl city") ///
    title("2SLS and first-stage strength")
esttab I* using "$T5/tables/5_6_weak_iv.rtf", replace keep(PI) cells(b(fmt(4) star) se(fmt(4) par) p(fmt(3) par("[" "]"))) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(N N_clust widstat, fmt(0 0 2))
* Benchmarks for the effective F (5% test, worst-case bias 10% of OLS):
*   Montiel Olea & Pflueger (2013): 23.1.  Old rule of thumb: 10.
*   Lee, McCrary, Moreira & Porter (2022): F must exceed 104.7 for the usual
*   +/-1.96 t-test to have a true 5% size; otherwise use AR.

*------------------------------------------------ 2. Table S10 "F = 8"
* The "F-statistic" row of Table S10 is reghdfe's JOINT F of all 10
* regressors (instrument + 9 controls), not the strength of the instrument.
preserve
    use "$SAMPLE", clear
    keep if !missing(inv_CCPU)
    reghdfe PI inv_CCPU $control, absorb(county year) cluster(county)
    di as res "joint F of all regressors (Table S10 col 4) = " %6.2f e(F)
    test inv_CCPU
    di as res "instrument-only F                            = " %6.2f r(F)
restore
reghdfe PI Sun_ccpu $control, absorb(county year) cluster(county) keepsingleton
di as res "main first stage: joint F = " %6.2f e(F)
test Sun_ccpu
di as res "main first stage: instrument-only F = " %6.2f r(F)

*------------------------------------------------ 3. residualize (FWL)
* Removing the FE and controls from Y, PSI and Z leaves the IV coefficient
* unchanged (Frisch-Waugh-Lovell), so weak-IV commands written for ivreg2
* can be used.
foreach v in ShannonBD PI Sun_ccpu {
    quietly reghdfe `v' $control, absorb(county year) resid(r_`v') keepsingleton
}
ivreg2 r_ShannonBD (r_PI = r_Sun_ccpu), cluster(county) nocons
capture noisily weakivtest
* With one instrument the effective F equals the cluster-robust F above.

*------------------------------------------------ 4. AR confidence set (grid)
* For each candidate effect b0: regress (Y - b0*PSI) on Z. If b0 is the true
* effect, Z should have no effect on Y - b0*PSI. Keep every b0 that is NOT
* rejected at 5%. The kept values form the AR 95% confidence set.
capture program drop ar_grid
program define ar_grid
    syntax , CLuster(varname) [FE(string) SUBset(string) LO(real -1.2) HI(real 0.8) STep(real 0.001)]
    if "`fe'" == "" local fe "county year"
    tempvar ry rp rz yb
    quietly reghdfe ShannonBD $control `subset', absorb(`fe') resid(`ry') keepsingleton
    quietly reghdfe PI        $control `subset', absorb(`fe') resid(`rp') keepsingleton
    quietly reghdfe Sun_ccpu  $control `subset', absorb(`fe') resid(`rz') keepsingleton
    quietly gen double `yb' = .
    local prev = 0
    local start = `lo'
    local segs
    local n = round((`hi'-`lo')/`step')
    forvalues i = 0/`n' {
        local b0 = `lo' + `i'*`step'
        quietly replace `yb' = `ry' - `b0'*`rp'
        quietly regress `yb' `rz' if !missing(`ry'), nocons vce(cluster `cluster')
        quietly test `rz'
        local acc = (r(p) > 0.05)
        if `acc' & !`prev' local start = `b0'
        if !`acc' & `prev' {
            local s1 : display %7.4f `start'
            local s2 : display %7.4f `b0'-`step'
            local segs `"`segs' [`s1', `s2']"'
        }
        local prev = `acc'
    }
    if `prev' {
        local s1 : display %7.4f `start'
        local s2 : display %7.4f `hi'
        local segs `"`segs' [`s1', `s2' = grid edge]"'
    }
    di as res `"AR 95% set, cluster(`cluster') fe(`fe') `subset':`segs'"'
    di as txt "   (a segment ending at the grid edge means the set is unbounded on that side)"
end

ar_grid, cluster(county)
ar_grid, cluster(city) subset(if !missing(city))
ar_grid, cluster(prov) lo(-3) hi(3) step(0.005)
ar_grid, cluster(county) fe(county year#urban)
ar_grid, cluster(city)   fe(county year#urban) subset(if !missing(city)) lo(-1.5)
ar_grid, cluster(county) subset(if in_PI_file==1)
ar_grid, cluster(city)   subset(if in_PI_file==1 & !missing(city)) lo(-1.5)

*------------------------------------------------ 5. weakiv cross-check
capture noisily {
    ivreg2 r_ShannonBD (r_PI = r_Sun_ccpu), cluster(county) nocons
    weakiv
    ivreg2 r_ShannonBD (r_PI = r_Sun_ccpu), cluster(city) nocons
    weakiv
}

*------------------------------------------------ 6. plausibly exogenous IV
* gamma = direct effect of Z on Shannon where PSI is imputed 0 (first stage
* is exactly zero there), from 1_6 Panel A column 2.
reghdfe ShannonBD Sun_ccpu $control if in_PI_file==0, absorb(county year) cluster(county)
scalar g_hat = _b[Sun_ccpu]
scalar g_se  = _se[Sun_ccpu]
foreach g in 0 `=g_hat' `=g_hat-1.96*g_se' `=g_hat+1.96*g_se' {
    capture drop y_adj
    gen double y_adj = ShannonBD - (`g')*Sun_ccpu
    quietly ivreghdfe y_adj (PI = Sun_ccpu) $control, absorb(county year) cluster(county) keepsingleton
    di as res "gamma = " %9.6f `g' "   IV b = " %7.4f _b[PI] "  (se " %6.4f _se[PI] ")"
}

* Expected (verified): 2SLS -0.1264; KP F 30.2 (county) 10.8 (city) 2.8 (prov)
*   AR sets: county [-0.217,-0.068]; city [-0.295,-0.037] (131 rows lack a city);
*   province (-inf,-0.028] U [0.586,+inf); urban x YM county [-0.282,-0.072]
*   plausibly exogenous: gamma=-0.00214 -> b = -0.042 (se 0.029)
