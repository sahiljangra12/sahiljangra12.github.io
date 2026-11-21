*==========================================================================
* 00_config.do
* Project : Replication of Zhang et al. (2026), "China's solar expansion
*           policy reduces bird diversity", Science 393, 831.
* Purpose : One place for paths, globals and package installation.
*           Every task do-file starts with:  do "<ROOT>/00_config.do"
* Author  : Sahil (Research Assistant, Johns Hopkins University)
*==========================================================================
version 16
set more off
set linesize 120

*---------------------------------------------------------------- paths
global ROOT "YOUR_PATH/Solar_Birds_Replication"
global ORIG "$ROOT/00_Original_Package"
global DATA "$ORIG/DATA"
global T1   "$ROOT/01_Task1_Replication"
global T2   "$ROOT/02_Task2_Sensitivity"
global T3   "$ROOT/03_Task3_Staggered_DiD"

* analysis sample built in Task 1 (used by all tasks)
global SAMPLE "$T1/data/analysis_sample.dta"

*---------------------------------------------------------------- model
* the authors' nine control variables (Table 1, column 3)
global control     "Temp Wind Pop Duration Carbon Water Green Farm Grass"
global control_noD "Temp Wind Pop Carbon Water Green Farm Grass"

*---------------------------------------------------------------- packages
* installed only if missing
foreach p in require ftools reghdfe ivreg2 ranktest ivreghdfe estout winsor2 ///
             psmatch2 binscatter sensemakr drdid csdid did_imputation       ///
             event_plot avar eventstudyinteract {
    capture which `p'
    if _rc {
        di as txt "installing `p' ..."
        capture noisily ssc install `p', replace
    }
}
set scheme s2color
