cap log close
set more off
clear
estimates clear
program drop _all
set matsize 800

** Table2C_StateRegs_IV.do
** Runs state level IV regression exploring effect of taxation on innovation.
** Runs regressions underlying Table 2C and Appendix Tables C20-C22

** FIRST SET UP A GLOBAL POINTING TO THE DIRECTORY IN WHICH THE REPLICATION PACKET IS STORED
** Only need to do this if running this code on its own rather than through 0_main.do
*global projdir "<REPLICATION PATH>"
	
log using "$projdir/Logs/state_regs_IV.log", replace
				
global additional_controls L.real_gdp_pc L.population_density
				
global lhsvars 	lnpat lncit ln_inv share_assigned
				
program main			
	
	** MAIN TEXT TABLE 2C and APPENDIX TABLE C.20
	regs, lags(3) minyear(1940) maxyear(2000) suffix(_inclFed_IV_weighted_instr_inclag5_statelag5) ///
		  instr_inclag(5) instr_statelag(5) if(!inlist(stateabbr,"LA","AK","HI","")) weight([aw=pop1940])
		  
end

program regs
syntax, lags(string asis) minyear(numlist) maxyear(numlist) instr_inclag(integer) ///
		instr_statelag(integer) [if(string asis) weight(string asis) suffix(string asis)]
		
	if "`if'" != "" {
		local if & `if'
		}
		
	foreach lag_tax in `lags' {
	
		use "$projdir/Data/state_data" if inrange(year,`minyear' - 1,`maxyear') `if', clear
		
		** Generate progressivity metrics
		sort statenum year
		
		** Generate state x five year variable for clustering
		gen fiveyear = 5*floor(year/5)
		egen statenum_fiveyear = group(statenum fiveyear)
		
		cap rename mtr_inclag`instr_inclag'_statelag`instr_statelag'90_lag`lag_tax'`item' mtr_inc`instr_inclag'_state`instr_statelag'90_lag`lag_tax'`item' 
		
		* If running log-log specification, replace taxes with log retention rate
		* variables (i.e. ln(1-tau))
		foreach var in top_corp_lag`lag_tax' mtr90_lag`lag_tax'`item' ///
					   mtr_inc`instr_inclag'_state`instr_statelag'90_lag`lag_tax'`item' ///
					   top_corp_instrument_lag`lag_tax' {
					   
					   replace `var' = ln(1-`var'/100)
					   
					   }
		
		foreach var in ${lhsvars} {
			#delimit ;
			
			
			******* IV REGRESSIONS;
								
			eststo `var'_p90_rd: ivreg2 `var' 
								(mtr90_lag`lag_tax'`item' top_corp_lag`lag_tax' = 
								mtr_inc`instr_inclag'_state`instr_statelag'90_lag`lag_tax'`item'
								top_corp_instrument_lag`lag_tax')
								${additional_controls} i.statenum i.year rd_credit_lag`lag_tax' `more_controls'
								`weight', first cluster(statenum_fiveyear year);
			estadd ysumm;
			
			
			******* FIRST STAGE REGS;
			// PERSONAL MTRs;
				
			eststo first_mtr90_rd: reghdfe mtr90_lag`lag_tax'`item' mtr_inc`instr_inclag'_state`instr_statelag'90_lag`lag_tax'`item'
								top_corp_instrument_lag`lag_tax' rd_credit_lag`lag_tax' 
								${additional_controls} `more_controls'
								`weight', absorb(statenum year) cluster(statenum_fiveyear year);
			estadd ysumm;	
			
			eststo first_mtr90_corp_rd: reghdfe top_corp_lag`lag_tax' mtr_inc`instr_inclag'_state`instr_statelag'90_lag`lag_tax'`item'
								top_corp_instrument_lag`lag_tax' rd_credit_lag`lag_tax' 
								${additional_controls} `more_controls'
								`weight', absorb(statenum year) cluster(statenum_fiveyear year);
			estadd ysumm;
			
			#delimit cr
			}
		estwrite * using "$projdir/Results/Regressions/sters/state_IV_regs_lag`lag_tax'`suffix'${dataset_suffix}.sters", replace
		estimates clear
		}
end

main

log close
