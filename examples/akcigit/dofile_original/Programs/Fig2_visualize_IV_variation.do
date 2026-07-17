cap log close
clear all
set more off
program drop _all

** Creates figures visualizing IV variation (Figure II)


** FIRST SET UP A GLOBAL POINTING TO THE DIRECTORY IN WHICH THE REPLICATION PACKET IS STORED
** Only need to do this if running this code on its own rather than through 0_main.do
*global projdir "<REPLICATION PATH>"
	
cap mkdir "$projdir/Results/Figures"

log using "$projdir/Logs/visualize_IV_variation.log", replace

program main
	figure2
end

program figure2
	use "$projdir/Data/state_data.dta", clear

	* Keep useful variables
	keep stateabbr statenum year mtrfb50 mtrfb90  ///
	     mtr_inclag5_statelag550 mtr_inclag5_statelag590
	des

	*------------------------*
	*      Data Set up       *
	*------------------------*

	sort statenum year

	** Drop states with odd data (Louisiana) and Alaska and Hawaii
	drop if inlist(stateabbr,"LA","AK","HI")

	** Generate variables for the change in percentage points of the instruments 
	gen iv_change_5_550 = mtr_inclag5_statelag550 - L.mtr_inclag5_statelag550
	gen iv_change_5_590 = mtr_inclag5_statelag590 - L.mtr_inclag5_statelag590

	** Collapse the iv_change variables at 90th percetile of the (within year and across states) distribution and temporary save it
	preserve
	collapse (p90) iv_change_5_550 iv_change_5_590, by(year)
	foreach var of varlist iv_change_5_550 iv_change_5_590 {
		rename `var' `var'_pctile90
		}
	tempfile p90
	save "`p90'"
	restore

	** Collapse the iv_change variables at 10th percetile of the (within year and across states) distribution and temporary save it
	preserve 
	collapse (p10) iv_change_5_550 iv_change_5_590, by(year)
	foreach var of varlist iv_change_5_550 iv_change_5_590 {
		rename `var' `var'_pctile10
		}
	tempfile p10
	save "`p10'"
	restore

	preserve
	collapse (sd) iv_change_5_550 iv_change_5_590, by(year)
	foreach var of varlist iv_change_5_550 iv_change_5_590 {
		rename `var' `var'_sd
		}
	tempfile sd
	save "`sd'"
	restore

	** Generate variables for the change in percentage points of the federal tax rates and collapse it at the year level
	gen FedTax_pers50_change = (mtrfb50 - L.mtrfb50) 
	gen FedTax_pers90_change = (mtrfb90 - L.mtrfb90) 
	collapse (mean) FedTax_pers50_change FedTax_pers90_change, by(year)

	** Merge w/ the temporary datasets
	merge 1:1 year using "`p90'", nogen
	merge 1:1 year using "`p10'", nogen
	merge 1:1 year using "`sd'", nogen

	foreach var in iv_change_5_550 iv_change_5_590 {
		gen `var'_range = `var'_pctile90 - `var'_pctile10
		}
	
	keep if inrange(year,1940,2000)
	
	* Summarize for numbers in text
	di "Federal 90th Percentile Personal MTR Change"
	summ *_sd *_range if abs(FedTax_pers90_change) > 0.1

	*------------------------*
	*      Make Plots        *
	*------------------------*

	
	#delimit ;
	** Personal income tax rates at 90th percentile of income distribution: Figure 2A;
	twoway 	(bar FedTax_pers90_change year, color(gs4) fintensity(50) lw(none) )
			(scatter iv_change_5_590_pctile10 year, connect(direct) mc(black) msize(small) msymbol(circle) lc(black) lw(medium) lp(solid) )
			(scatter iv_change_5_590_pctile90 year, connect(stairstep) mc(blue) msize(small) msymbol(square) lc(blue) lw(medium) lp(dash) ),
			graphregion(color(white)) xtitle("")  
			ytitle("Percentage Points")
			xlabel(1940(10)2000) xmtick(1940(5)2000,grid)
			legend(label(2 "10th pctile of Change in Personal Tax Rate Instrument") label(3 "90th pctile of Change in Personal Tax Rate Instrument")  
				   label(1 "Statutory Change in Federal Personal Tax Rate for 90th pctile (% points)") row(3) pos(6));
	graph export "$projdir/Results/Figures/Figure2A.png", replace;
	#delimit cr
	
	** Personal income tax rates at 50th percentile of income distribution: Figure 2B;
	#delimit ;
	twoway 	(bar FedTax_pers50_change year, color(gs4) fintensity(50) lw(none) )
			(scatter iv_change_5_550_pctile10 year, connect(direct) mc(black) msize(small) msymbol(circle) lc(black) lw(medium) lp(solid) )
			(scatter iv_change_5_550_pctile90 year, connect(stairstep) mc(blue) msize(small) msymbol(square) lc(blue) lw(medium) lp(dash) ),
			graphregion(color(white)) xtitle("")  
			ytitle("Percentage Points")
			xlabel(1940(10)2000) xmtick(1940(5)2000,grid)
			legend(label(2 "10th pctile of Change in Personal Tax Rate Instrument") label(3 "90th pctile of Change in Personal Tax Rate Instrument")  
				   label(1 "Statutory Change in Federal Personal Tax Rate for 50th pctile (% points)") row(3) pos(6));
	graph export "$projdir/Results/Figures/Figure2B.png", replace;
	#delimit cr
end

main



log close


