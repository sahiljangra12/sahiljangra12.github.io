*==========================================================================
* 3_0_run_task3.do  —  runs every Task 3 step in order, one log per step
*==========================================================================
do "YOUR_PATH/Solar_Birds_Replication/00_config.do"

foreach step in 3_1_adoption_timing 3_2_twfe_event_study 3_3_callaway_santanna ///
                3_4_imputation_bjs 3_5_sun_abraham {
    capture log close _all
    log using "$T3/logs/`step'.log", replace text
    di as res _n "================ `step' ================"
    clear
    estimates clear
    do "$ROOT/00_config.do"
    capture noisily do "$T3/code/`step'.do"
    if _rc di as err "STEP `step' FAILED with rc = " _rc
    log close
}
