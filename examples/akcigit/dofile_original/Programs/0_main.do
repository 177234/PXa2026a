cap log close
clear
set more off

** main.do
** Runs all programs to reproduce inventor tax project

** Installs necessary user-written adofiles. Remove if statement to install them
if 0 == 1 {
	ssc install reghdfe, replace
	ssc install synth, replace
	ssc install esttab, replace
	ssc install ftools, replace
	}

	
	
** FIRST SET UP A GLOBAL POINTING TO THE DIRECTORY IN WHICH THE REPLICATION PACKET IS STORED
*>>>>>> 请酌情修改 path 的路径, 从地址栏复制即可
  global path "D:/stata/personal/Paper2022/T2_Akcigit_QJE_2022"
*>>>>>>



*>> 以下无需修改 >>
global projdir    "$path/dofile_original"
global Data       "$path/data"
global programdir "$projdir/Programs"

cap mkdir "$projdir/Logs"
cap mkdir "$projdir/Results"

***********************
******* Tables ********
***********************

*do "$programdir/Table1_SummStats" // Table 1

** State regressions **
do "$programdir/Table2AB_StateRegs_OLS"   // Table 2, Panels A and B, plus almost all Tables in Appendix A.3
do "$programdir/Table2C_StateRegs_IV"     // Table 2, Panel C and all Tables in Appendix C.3 which use an IV
do "$programdir/Table3_LongDifferences"   // Table 3
do "$programdir/Table4_MicroRegs"         // Table 4
do "$programdir/Table5_MultinomialLogits" // Table 5 and the location choice piece of Table 6
do "$programdir/Table6_CorpInvInteract"   // Most of Table 6




************************
******* Figures ********
************************

do "$programdir/Fig1_BinnedScatters"         // Figure 1
do "$programdir/Fig2_visualize_IV_variation" // Figure 2
do "$programdir/Fig3_EventStudies"           // Figure 3
do "$programdir/Fig4_DistributedLags"        // Figure 4




