*==========================================================================
* 2_0_run_task2.do  —  runs Task 2 (needs Task 1's analysis_sample.dta)
*==========================================================================
do "YOUR_PATH/Solar_Birds_Replication/00_config.do"
capture log close _all
log using "$T2/logs/2_1_sensitivity_analysis.log", replace text
do "$T2/code/2_1_sensitivity_analysis.do"
log close
