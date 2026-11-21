*==========================================================================
* 5_0_run_followups.do
* PURPOSE : Runs every follow-up analysis requested at the 13 Nov 2026
*           meeting with Prof. Ferraro, one log file per step.
*           One failing step does not stop the others.
* ORDER   : 5_1 effort | 5_2 dummies vs absorbed FE | 5_3 sample flow |
*           5_4 missingness | 5_5 solar-plant area | 5_6 weak IV + AR
*==========================================================================
quietly do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
global T5 "$ROOT/05_Followups_Nov13"
foreach f in tables logs figures data {
    capture mkdir "$T5/`f'"
}
* packages used only in this folder
foreach p in weakivtest weakiv {
    capture which `p'
    if _rc capture noisily ssc install `p', replace
}

foreach s in 5_1_effort_test 5_2_sensitivity_dummies 5_3_sample_flow ///
             5_4_missingness_test 5_5_pv_area_treatment 5_6_weak_iv_anderson_rubin {
    capture log close
    log using "$T5/logs/`s'.log", replace text
    capture noisily do "$T5/code/`s'.do"
    if _rc di as err "`s' stopped with error " _rc
    log close
}
