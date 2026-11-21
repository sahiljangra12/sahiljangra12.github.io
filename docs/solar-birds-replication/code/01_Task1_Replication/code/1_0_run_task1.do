*==========================================================================
* 1_0_run_task1.do  —  runs every Task 1 step in order, one log per step
*==========================================================================
do "YOUR_PATH/Solar_Birds_Replication/00_config.do"

foreach step in 1_1_reproduce_authors_results 1_2_build_analysis_sample ///
                1_3_data_structure 1_4_reproduction_check               ///
                1_5_twfe_diagnostics 1_6_iv_exclusion_tests {
    capture log close _all
    log using "$T1/logs/`step'.log", replace text
    di as res _n "================ `step' ================"
    clear
    estimates clear
    do "$ROOT/00_config.do"
    do "$T1/code/`step'.do"
    log close
}
