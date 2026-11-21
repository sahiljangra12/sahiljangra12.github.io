*==========================================================================
* 7_1_spec_grid.do
* PURPOSE : Pre-compute every regression behind the interactive website,
*           so that each choice a reader makes shows a real Stata estimate.
*   (A) Specification grid: outcome x treatment x fixed effects x sample x
*       controls x clustering  (reghdfe)                -> spec_grid.csv
*   (B) Inputs for the Cinelli-Hazlett sensitivity calculator (estimate,
*       SE, df and Duration's partial R2s)              -> sens_inputs.csv
*   (C) Plausibly-exogenous IV: 2SLS for a grid of assumed direct effects
*       (gamma) of the instrument                       -> iv_gamma.csv
*==========================================================================
if "$ROOT" == "" quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
global T7 "$ROOT/07_Interactive"
capture mkdir "$T7"
capture mkdir "$T7/data"

use "$DATA/IC.dta", clear
keep id
duplicates drop
gen byte in_IC_file = 1
tempfile ic
save `ic'

use "$SAMPLE", clear
merge m:1 id using `ic', keep(master match) nogen
replace in_IC_file = 0 if missing(in_IC_file)
gen lnBN = ln(BN)
egen pym = group(prov year)
egen uym = group(urban year)

*------------------------------------------------ (A) specification grid
tempname P
postfile `P' str12 y str6 d str4 fe str8 smp str4 ctrl str6 cl double(b se p N Ncl) ///
    using "$T7/data/spec_grid.dta", replace
local k = 0
foreach y in ShannonBD Richness Evenness lnBN {
  foreach d in PI Area {
    foreach fe in f1 f2 f3 {
      local abs "county year"
      if "`fe'" == "f2" local abs "county uym"
      if "`fe'" == "f3" local abs "county pym"
      foreach s in all realpsi icfile rural {
        local cond ""
        if "`s'" == "realpsi" local cond "if in_PI_file==1"
        if "`s'" == "icfile"  local cond "if in_IC_file==1"
        if "`s'" == "rural"   local cond "if urban==0"
        foreach c in c0 c1 c2 {
          if "`c'" == "c2" & "`y'" == "lnBN" continue
          local X ""
          if "`c'" == "c1" local X "$control"
          if "`c'" == "c1" & "`y'" == "lnBN" local X "$control_noD"
          if "`c'" == "c2" local X "$control lnBN"
          foreach cl in county city prov {
            local ++k
            capture reghdfe `y' `d' `X' `cond', absorb(`abs') cluster(`cl')
            if _rc == 0 {
              post `P' ("`y'") ("`d'") ("`fe'") ("`s'") ("`c'") ("`cl'") ///
                (_b[`d']) (_se[`d']) (2*ttail(e(df_r), abs(_b[`d']/_se[`d']))) (e(N)) (e(N_clust))
            }
            if mod(`k', 50) == 0 di as txt "spec `k' done"
          }
        }
      }
    }
  }
}
postclose `P'

*------------------------------------------------ (B) sensitivity inputs
tempname Q
postfile `Q' str8 spec double(b se df tY_dur dfY tD_dur dfD N) using "$T7/data/sens_inputs.dta", replace
foreach sp in paper urbym realpsi {
    local abs "county year"
    local cond ""
    if "`sp'" == "urbym"   local abs "county uym"
    if "`sp'" == "realpsi" local cond "if in_PI_file==1"
    reghdfe ShannonBD PI $control `cond', absorb(`abs') vce(unadjusted)
    local b = _b[PI]
    local se = _se[PI]
    local df = e(df_r)
    local tY = _b[Duration]/_se[Duration]
    local N = e(N)
    reghdfe PI $control `cond', absorb(`abs') vce(unadjusted)
    post `Q' ("`sp'") (`b') (`se') (`df') (`tY') (`df') (_b[Duration]/_se[Duration]) (e(df_r)) (`N')
}
postclose `Q'

*------------------------------------------------ (C) IV for a grid of gamma
preserve
keep if !missing(Sun_ccpu)
reghdfe ShannonBD Sun_ccpu $control if in_PI_file==0, absorb(county year) cluster(county)
scalar g_hat = _b[Sun_ccpu]
scalar g_se  = _se[Sun_ccpu]
tempname R
postfile `R' str6 cl double(gamma b se N F ghat gse) using "$T7/data/iv_gamma.dta", replace
foreach cl in county city {
    forvalues i = 0/32 {
        local g = -0.006 + `i'*0.00025
        capture drop y_adj
        gen double y_adj = ShannonBD - (`g')*Sun_ccpu
        capture ivreghdfe y_adj (PI = Sun_ccpu) $control, absorb(county year) cluster(`cl') keepsingleton
        if _rc == 0 post `R' ("`cl'") (`g') (_b[PI]) (_se[PI]) (e(N)) (e(widstat)) (g_hat) (g_se)
    }
    capture drop y_adj
    gen double y_adj = ShannonBD - (g_hat)*Sun_ccpu
    capture ivreghdfe y_adj (PI = Sun_ccpu) $control, absorb(county year) cluster(`cl') keepsingleton
    if _rc == 0 post `R' ("`cl'") (g_hat) (_b[PI]) (_se[PI]) (e(N)) (e(widstat)) (g_hat) (g_se)
}
postclose `R'
restore

foreach f in spec_grid sens_inputs iv_gamma {
    use "$T7/data/`f'.dta", clear
    format b se %12.0g
    export delimited using "$T7/data/`f'.csv", replace
}
di as res "7_1 finished"
