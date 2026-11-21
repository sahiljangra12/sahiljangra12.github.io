*==========================================================================
* 6_0_run_nov19.do
* PURPOSE : Runs the analyses requested at the 19 Nov 2026 meeting, one log
*           per step: 6_1 sensitivity (residualized, Prof. Ferraro's code),
*           6_2 de Chaisemartin & D'Haultfoeuille estimators, 6_3 facts
*           asked in the meeting (urban share of dropped rows, Area vs PSI
*           missingness).
*==========================================================================
quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
global T6 "$ROOT/06_Followups_Nov19"
foreach f in tables logs figures data {
    capture mkdir "$T6/`f'"
}
foreach p in gtools did_multiplegt_dyn did_multiplegt_stat sensemakr {
    capture which `p'
    if _rc capture noisily ssc install `p', replace
}
foreach s in 6_1_sensitivity_residualized 6_2_dcdh_estimators 6_3_meeting_facts 6_4_extra_checks {
    capture log close
    log using "$T6/logs/`s'.log", replace text
    capture noisily do "$T6/code/`s'.do"
    if _rc di as err "`s' stopped with error " _rc
    log close
}
