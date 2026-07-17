cap log close
set more off
clear
estimates clear
program drop _all

** state_regs.do
** Runs state level regression exploring effect of taxation on innovation. 
** Runs regressions on which Tables 2A, 2B and Appendix Tables C.5-C.19 (excl. C.13)
** are based.


** FIRST SET UP A GLOBAL POINTING TO THE DIRECTORY IN WHICH THE REPLICATION PACKET IS STORED
** Only need to do this if running this code on its own rather than through 0_main.do
*global projdir "<REPLICATION PATH>"
	
cap mkdir "$projdir/Results"
cap mkdir "$projdir/Results/Regressions"
cap mkdir "$projdir/Results/Regressions/sters"
cap mkdir "$projdir/Logs"

log using "$projdir/Logs/state_regs.log", replace

// FINAL SET OF LHS VARIABLES
global lhsvars_maintext lnpat lncit ln_inv share_assigned
				
global lhsvars_tableC6 	lncit_unadj lncorp_pat lnnoncorp_pat lnmean_kpss lnEmpPerEstab ///
						lnVA lnpayroll lnawe lnrpi_pc pctmanu
				
global lhsvars ${lhsvars_maintext} ${lhsvars_appendix}
				
				
// ADDITIONAL STATE - YEAR LEVEL CONTROLS
global additional_controls L.real_gdp_pc L.population_density

program main
	main_text_regs
	appendix_regs
end

program main_text_regs
	
	****************************
	**** MAIN TEXT TABLE 2A ****
	****************************
	* Baseline regressions. Note also runs regressions for Tables C.5, C.6, C.7, and C.8
	regs, lags(3) minyear(1940) maxyear(2000) suffix(_inclFed_weighted) ///
		  if(!inlist(stateabbr,"","HI","AK","LA")) weight([aw=pop1940]) baseline
		  
	****************************
	**** MAIN TEXT TABLE 2B ****
	****************************
	** Includes corporate tax base index as additional control
	regs, lags(3) minyear(1940) maxyear(2000) suffix(_inclFed_weighted_baseIndex) ///
		  if(!inlist(stateabbr,"","HI","AK","LA")) weight([aw=pop1940]) ///
		   more_controls(base_index_lag3 c.base_index_lag3#c.top_corp_lag3)

end
	
program appendix_regs
	***********************************
	********* APPENDIX TABLES *********
	***********************************
		  
	** Table C9: Using Personal income tax rates for those married with two dependents
	regs, lags(3) minyear(1940) maxyear(2000) suffix(_inclFed_weighted_married) ///
		  if(!inlist(stateabbr,"","HI","AK","LA")) weight([aw=pop1940]) ///
		  married
		  		
	** Table C10: Forcing itemizing state tax deductions from federal taxes
	regs, lags(3) minyear(1940) maxyear(2000) suffix(_inclFed_weighted_itemized) ///
		  if(!inlist(stateabbr,"","HI","AK","LA")) weight([aw=pop1940]) ///
		  itemized
		  
	** Table C11: Auerbach-Poterba Effective Tax Rates
	regs, lags(3) minyear(1960) maxyear(2000) suffix(_inclFed_weighted_ap) ///
		  if(!inlist(stateabbr,"","HI","AK","LA")) weight([aw=pop1940]) ///
		  auerbach
		   
	** Table C12: Regressions with different lags
	regs, lags(2 1) minyear(1940) maxyear(2000) suffix(_inclFed_weighted) ///
		  if(!inlist(stateabbr,"","HI","AK","LA")) weight([aw=pop1940])
		  
	** Table C14: Excluding CA and NY
	regs, lags(3) minyear(1940) maxyear(2000) suffix(_inclFed_weighted_noCANY) ///
		  if(!inlist(stateabbr,"","HI","AK","LA","CA","NY")) weight([aw=pop1940])
		  
	** Table C15: Excluding 1970s
	regs, lags(3) minyear(1940) maxyear(2000) suffix(_inclFed_weighted_no70s) ///
		  weight([aw=pop1940])  ///
		  if(!inrange(year,1970,1979) & !inlist(stateabbr,"","HI","AK","LA")) 
	
	** Table C16A: Including years through 2010
	regs, lags(3) minyear(1940) maxyear(2010) suffix(_inclFed_weighted_post2000) ///
		  if(!inlist(stateabbr,"","HI","AK","LA")) weight([aw=pop1940])
	
	** Table C17: Political Controls
	regs, lags(3) minyear(1940) maxyear(2000) suffix(_inclFed_weighted_politicalControls) ///
		  if(!inlist(stateabbr,"","HI","AK","LA")) weight([aw=pop1940]) ///
		  more_controls(govdem pctdemup pctdemlo)  
	
	* Table C18: No Controls, but FE
	global additional_controls
	regs, lags(3) minyear(1940) maxyear(2000) suffix(_inclFed_weighted_noControls) ///
		  if(!inlist(stateabbr,"","HI","AK","LA")) weight([aw=pop1940])
		  
	** Table C19: Unweighted
	regs, lags(3) minyear(1940) maxyear(2000) suffix(_inclFed_unweighted) ///
		  if(!inlist(stateabbr,"","HI","AK","LA")) 
		  
		  
		  
end

program regs
syntax, lags(string asis) minyear(numlist) maxyear(numlist) ///
		[if(string asis) suffix(string asis) married baseline ///
		more_controls(string asis) ITEMized weight(string asis) AUERBACHpoterba]
	
	if "`if'" != "" {
		local if & `if'
		}
		
	if "`auerbachpoterba'" != "" {
		local ap _ap
		}
		
	if "`married'" != "" {
		local tax_suffix _married
		}
	
	if "`itemized'" != "" {
		local item _item
		}
	foreach lag_tax in `lags' {
			
		use "$projdir/Data/state_data" if inrange(year,`minyear' - 1,`maxyear') `if', clear
		
		sort statenum year
		* Replace taxes with log retention rate variables (i.e. ln(1-tau))
		foreach var in mtr`tax_suffix'50_lag`lag_tax'`item' top_corp`ap'_lag`lag_tax' ///
					   atr`tax_suffix'50_lag`lag_tax'`item' mtr`tax_suffix'90_lag`lag_tax'`item' ///
					   atr`tax_suffix'90_lag`lag_tax'`item' {
					   
					   cap replace `var' = ln(1-`var'/100)
					   
					   }
					   
		if `lag_tax' == 2 {
			foreach var in mtr90 top_corp rd_credit {
				gen `var'_lag2 = L.`var'_lag1
				}
			}
		
		* Generate Auerbach-Poterba tax rates
		if "`ap'" != "" {
			replace top_corp_lag`lag_tax' = ln(1-top_corp_lag`lag_tax'/100)
			gen byte miaptax = mi(top_corp_ap_lag`lag_tax')
			replace top_corp_ap_lag`lag_tax' = top_corp_lag`lag_tax' if mi(top_corp_ap_lag`lag_tax')
			local more_controls c.top_corp_ap_lag`lag_tax'#c.miaptax miaptax
			}
		
		* Generate state x five-year variable for clustering
		gen fiveyear = 5*floor(year/5)
		egen statenum_fiveyear = group(statenum fiveyear)
		
		foreach var in ${lhsvars} {			
			#delimit ;
			
			** MAIN REGRESSIONS: Corp Tax + 90th Percentile Marginal Personal Tax Rate;
			eststo `var'_p90_rd: reghdfe `var' mtr`tax_suffix'90_lag`lag_tax'`item'
								top_corp`ap'_lag`lag_tax'
								${additional_controls} rd_credit_lag`lag_tax' `more_controls'
								`weight', absorb(statenum year) vce(cluster statenum_fiveyear year);
			estadd ysumm;
			
			if "`baseline'" != "" {;
				**** REGRESSIONS FOR TABLE C.7 - Alternative tax rates;
				eststo `var'_p50_rd: reghdfe `var' mtr`tax_suffix'50_lag`lag_tax'`item'
									top_corp`ap'_lag`lag_tax'
									${additional_controls} rd_credit_lag`lag_tax' `more_controls'
									`weight', absorb(statenum year) vce(cluster statenum_fiveyear year);
				estadd ysumm;
				
				
											
				eststo `var'_p50_av_rd: reghdfe `var' atr`tax_suffix'50_lag`lag_tax'`item'
									top_corp`ap'_lag`lag_tax'
									${additional_controls} rd_credit_lag`lag_tax' `more_controls'
									`weight', absorb(statenum year) vce(cluster statenum_fiveyear year);
				estadd ysumm;
				
				
											
				eststo `var'_p90_av_rd: reghdfe `var' atr`tax_suffix'90_lag`lag_tax'`item'
									top_corp`ap'_lag`lag_tax'
									${additional_controls} rd_credit_lag`lag_tax' `more_controls'
									`weight', absorb(statenum year) vce(cluster statenum_fiveyear year);
				estadd ysumm;
				

				** REGRESSIONS FOR TABLE C.8: Corp Tax + 90th Percentile Marginal Personal Tax Rate + Median marginal personal tax rate;
				eststo `var'_both_rd: reghdfe `var' mtr`tax_suffix'90_lag`lag_tax'`item'
									 mtr`tax_suffix'50_lag`lag_tax'`item'
									 top_corp`ap'_lag`lag_tax'
									${additional_controls} rd_credit_lag`lag_tax' `more_controls'
									`weight', absorb(statenum year) vce(cluster statenum_fiveyear year);
				estadd ysumm;
				};
			
			#delimit cr
			}
		estwrite * using "$projdir/Results/Regressions/sters/state_regs_clusterTwoWay_lag`lag_tax'`suffix'.sters", replace
		estimates clear
		}
end

main

log close
