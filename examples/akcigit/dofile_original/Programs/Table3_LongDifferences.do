cap log close
file close _all
set more off, permanently
program drop _all 
estimates clear

** state_regs.do
** Runs state level long-difference regression exploring effect of taxation on innovation. 
** Runs regressions on which Table 3 is based.

** FIRST SET UP A GLOBAL POINTING TO THE DIRECTORY IN WHICH THE REPLICATION PACKET IS STORED
** Only need to do this if running this code on its own rather than through 0_main.do
*global projdir "<REPLICATION PATH>"
	
cap mkdir "$projdir/Results"
cap mkdir "$projdir/Results/Regressions"
cap mkdir "$projdir/Results/Regressions/sters"
cap mkdir "$projdir/Logs"

log using "$projdir/Logs/long_differences.log", replace
	
global lhsvars 	lnpat lncit ln_inv share_assigned
global controls gdppc_lag1 popdens_lag1 rd_credit_lag3 base_index
global minyear 1940
global maxyear 2000

program main
	foreach gap in 10 15 20 {
		global gap `gap'
		regs, weight([aw=pop1940])
		}
	
end

program regs
syntax, [weight(string asis)]

	use "$projdir/Data/state_data" if inrange(year,${minyear}-1,${maxyear}) & !inlist(stateabbr,"LA","AK","HI","PR"), clear
	
	gen mibaseindex = mi(base_index)
	replace base_index = 0 if mi(base_index)

	sort statenum year
	foreach var of varlist mtr90 top_corp {
		gen delta_`var' = ln(1-`var'/100) - ln(1-l${gap}.`var'/100)
		}

	* Lag Control variables
	gen popdens_lag1 = L.population_density
	gen gdppc_lag1 = L.real_gdp_pc
	foreach var of varlist $controls {
		gen delta_`var' = `var' - l${gap}.`var'
		local delta_controls `delta_controls' delta_`var'
		}
	
	* Generate state x five-year variable for clustering
	gen fiveyear = 5*floor(year/5)
	egen state5year = group(statenum fiveyear)
		
	* Generate decadal change in lhs var and run regressions
	foreach lhsvar in $lhsvars {
		gen delta_`lhsvar' = `lhsvar' - l${gap}.`lhsvar'
		
		eststo `lhsvar'D: reghdfe delta_`lhsvar' delta_mtr90 delta_top_corp `delta_controls' ///
				if year >= $minyear  `weight', absorb(year) vce(cluster year)
		estadd ysumm
		}
		
	estwrite * using "$projdir/Results/Regressions/sters/long_diff${gap}.sters", replace
end

main
