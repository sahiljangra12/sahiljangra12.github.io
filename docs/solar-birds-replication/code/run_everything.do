*==========================================================================
* run_everything.do  -  ONE file that runs every analysis of the project
*   Task 1 (reproduction + diagnostics), Task 2 (sensitivity), Task 3
*   (staggered DiD), the 13 Nov follow-ups and the 19 Nov follow-ups.
*   Each part writes its own logs, tables and figures into its folder.
*   Runtime: about 15-25 minutes in Stata/BE.
*==========================================================================
local R "YOUR_PATH/Solar_Birds_Replication"
do "`R'/run_all.do"                                   // Tasks 1-3
do "`R'/05_Followups_Nov13/code/5_0_run_followups.do" // 13 Nov follow-ups
do "`R'/06_Followups_Nov19/code/6_0_run_nov19.do"     // 19 Nov follow-ups
di as res "All analyses finished. Logs are in each folder's logs/ subfolder."
