*==========================================================================
* run_all.do  —  reproduces the whole project from the original data
*   Task 1  Replication of Zhang et al. (2026)        ~6 min
*   Task 2  Cinelli-Hazlett sensitivity analysis      ~1 min
*   Task 3  Staggered difference-in-differences       ~3 min
* Usage (Stata command window):
*   do "YOUR_PATH/Solar_Birds_Replication/run_all.do"
*==========================================================================
clear all
global ROOT "YOUR_PATH/Solar_Birds_Replication"
do "$ROOT/01_Task1_Replication/code/1_0_run_task1.do"
do "$ROOT/02_Task2_Sensitivity/code/2_0_run_task2.do"
do "$ROOT/03_Task3_Staggered_DiD/code/3_0_run_task3.do"
di as res _n "ALL TASKS FINISHED"
