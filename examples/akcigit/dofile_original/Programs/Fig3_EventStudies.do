cap log close
program drop _all
file close _all

** Creates event studies at state level (Figure III)

** FIRST SET UP A GLOBAL POINTING TO THE DIRECTORY IN WHICH THE REPLICATION PACKET IS STORED
** Only need to do this if running this code on its own rather than through 0_main.do
*global projdir "<REPLICATION PATH>"

log using "$projdir/Logs/EventStudies.log", replace

global years_after_reform = 4 // Years after reform to include in estimation sample
global years_pre_reform = 4 // Years before reform to include in estimation sample
global years_for_synth_reform 4 // Years before reform to use for synthetic control construction
global large_cutoff = 90 // Percentile cutoff for being a "large" reform
global cutoff_pctile = 1 // Set equal to 1 if want cutoff to be determined by percentiles rather than size of tax change
				
global lhsvars 	lnpat ln_inv
global predvars population_density lngdppc // Variables to match on for synthetic controls

program main
		  
	** Event studies on personal income tax reforms for 90th percentile earners
	regs, years_after_reform(${years_after_reform}) years_pre_reform(${years_pre_reform}) ///
		  taxvars(mtrs90) ///
		  if(if !inlist(stateabbr,"LA","HI","AK","PR","DC") & inrange(year,1939,2000))
	
	** Event studies on corporate income tax reforms
	regs, years_after_reform(${years_after_reform}) years_pre_reform(${years_pre_reform}) ///
		  taxvars(top_corp_state) ///
		  if(if !inlist(stateabbr,"LA","HI","AK","PR","DC") & inrange(year,1939,2000))
	
	
end

program regs
syntax, years_after_reform(numlist) years_pre_reform(numlist) ///
		taxvars(string asis) [if(string asis)]
	
	** Make a smaller state dataset for easier merging
	qui {
	use statenum stateabbr year lnpat ln_inv mtrs90 top_corp_state ///
		real_gdp_pc population_density using "$projdir/Data/state_data" ///
		if !inlist(stateabbr,"LA","HI","AK","PR","DC"), clear
	
	gen lngdppc = ln(real_gdp_pc)
	label var mtrs90 "90th Pctile Marginal State Tax Rate"
	label var top_corp_state "State Top Corporate Tax Rate"
	tempfile statedata
	compress
	save `statedata', replace
	}
	
	foreach tax in `taxvars' {
		di ""
		di "Producing Event Studies with $large_cutoff percentile cutoff for `tax'"
		di ""
		
		use statenum stateabbr year `tax' using "$projdir/Data/state_data" `if', clear
			
		sort statenum year
		
		* Generate large tax change variables: indicators equal to 1 if change
		* is in the top $large_cutoff% of tax change sizes over the course of the sample.
		* If the option abs_taxchange is specified, then take the top $large_cutoff%
		* of tax changes regardless of whether they're increases or decreases,
		* otherwise define the large tax change cutoff for increases and decreases
		* separately.
		gen `tax'_change = `tax' - L.`tax'
		gen tax_lag = L.`tax'
		replace `tax'_change = 0 if abs(`tax'_change) < 0.01
		
		* Generate indicator for large tax increase
		summ `tax'_change if `tax'_change > 0, d
		gen byte large_inc_`tax' = `tax'_change >= r(p${large_cutoff}) if !mi(`tax'_change)
		
		* Generate indicator for large tax decrease
		summ `tax'_change if `tax'_change < 0, d
		local cutoff2 = 100 - ${large_cutoff}
		gen byte large_dec_`tax' = `tax'_change <= r(p`cutoff2') if !mi(`tax'_change)
		
		** Keep only years with a large tax change
		keep if inlist(1,large_inc_`tax',large_dec_`tax')
		
		* Summarize size of tax changes. Some of these statistics are reported 
		* in the text and used to estimate elasticities
		gen abs_change = abs(`tax'_change)
		di "Distribution of tax change sizes"
		summ abs_change, d
		
		di "Distribution of tax increase sizes"
		summ abs_change if large_inc_`tax' == 1, d
		
		di "Distribution of tax cut sizes"
		summ abs_change if large_dec_`tax' == 1, d
		
		* Only keep tax reforms with no additional reforms within `years_after_reform' years. NOTE COMMENTED OUT BECAUSE HAPPENS IN THE LOOP BELOW
		bys statenum (year): gen byte tokeep = (year[_n-1] < year - ${years_pre_reform} | mi(year[_n-1])) ///
											 & (year[_n+1] > year + ${years_after_reform} | mi(year[_n+1]))
		tab tokeep
		
		* Generate large change variable = 1 if tax increase, and -1 if tax decrease
		gen largechange = large_inc_`tax' - large_dec_`tax' 
		tab year largechange, col
		tab stateabbr largechange, col
		
		* Generate a reform ID
		keep statenum year largechange `tax'_change abs_change tokeep
		gen reformid = _n
		
		* Expand to have years around reform
		local k = `years_after_reform' + 1 + `years_pre_reform'
		expand `k'
		sort reformid year
		
		* Generate relative year dummies
		bys reformid: gen rel_yr = _n-`years_pre_reform'-1
		forvalues i = -`years_pre_reform'/`years_after_reform' {
			local j = `i'+`years_pre_reform'+1
			replace year = year+`i' if rel_yr == `i'
			gen rel_yr`j' = largechange*(rel_yr == `i')
			label var rel_yr`j' "`i'"
			}
		
		** Now loop through each reform and generate synthetic control states.
		** Only include states that have no large reforms in the years surrounding
		** the focal reform
		compress
		tempfile ES_data
		tempfile synth_output
		tempfile reforms
		save `reforms'
		levelsof reformid, local(reformids)
		
		foreach lhsvar in ${lhsvars} {
			foreach reform in `reformids' {
				di "Reform `reform'"
				use `reforms', clear
				
				* Keep only focal reform
				keep if reformid == `reform'
				
				* Merge in all the state data
				merge m:1 statenum year using `statedata'
				
				* Merge in the set of reforms
				merge 1:m statenum year using `reforms', gen(reform_merge)
				
				* Keep only the relevant years around the focal reform
				gen byte focal_reform = reformid == `reform'
				bys year: egen byte relevant_year = max(focal_reform)
				
				* Drop states that had a reform in the relevant period
				replace reform_merge = . if relevant_year == 0
				bys statenum (year): egen maxmerge = max(reform_merge)
				bys statenum (year): egen reform_state = max(focal_reform)
				tab maxmerge reform_state
				drop if maxmerge == 3 & reform_state == 0
				
				// Drop Duplicates From small overlapping periods
				duplicates drop
				
				* Create synthetic control state
				summ year if rel_yr == 0
				local tryear = r(mean)
				local minyear = `tryear' - ${years_for_synth_reform}
				local maxyear = `tryear' - 1
				summ statenum if focal_reform == 1
				local trunit = r(mean)
				keep if inrange(year,`minyear',`tryear'+`years_after_reform')
				synth `lhsvar' `lhsvar' ${predvars}, trunit(`trunit') trperiod(`tryear') keep(`synth_output') replace mspeperiod(`minyear'/`maxyear')
				
				preserve
				use `synth_output', clear
				keep if !mi(_Y_synthetic)
				rename _Y_synthetic `lhsvar'
				rename _time year
				keep year `lhsvar'
				gen statenum = 0
				compress
				save `synth_output', replace
				restore
				
				keep if focal_reform == 1
				append using `synth_output'
				keep if inrange(year,`tryear'-`years_pre_reform',`tryear'+`years_after_reform')
				
				* For the remaining states, zero out the relative year variables
				* for every year.
				foreach var of varlist rel_yr* `tax'_change {
					replace `var' = 0 if mi(`var')
					}
				replace rel_yr = year - `tryear'
					
				* Assign all control states the focal reformid
				qui replace reformid = `reform'
				
				* Make sure the tokeep variable is included everywhere
				bys reformid (statenum year): egen temp = max(tokeep)
				replace tokeep = temp if mi(tokeep)
				drop temp
		
				* Assign whether it's a large increase or decrease to synthetic state
				bys reformid (statenum year): egen temp = max(largechange)
				replace largechange = temp if mi(largechange)
				drop temp
				
				* Clean up and append other data
				drop maxmerge _merge reform_merge focal_reform
				qui compress
				cap append using `ES_data'
				save `ES_data', replace
				}
			keep if tokeep == 1
			drop tokeep
			
			* Generate treatment state indicator
			gen byte treatment = statenum != 0
			
			replace rel_yr1 = 0 // Ensure that initial relative year is dropped to normalize trend
			replace rel_yr`years_pre_reform' = 0 // Ensure that relative year -1 is the one which is dropped
			
			sort statenum year
		
			* Run regressions
			local label: var label `lhsvar'
			local taxlab: var label `tax'
			
			#delimit ;	
			eststo `lhsvar': reghdfe `lhsvar' rel_yr1-rel_yr3 rel_yr4 rel_yr5-rel_yr`j' ,
								absorb(reformid#treatment rel_yr) vce(cluster reformid);
			estadd ysumm;
			summ abs_change if e(sample);
			local elast4yr = -_b[rel_yr9]/r(mean);
			local elast4yr: di %4.1f `elast4yr';
			di "Elasticity for Unweighted Event Study `lhsvar', `taxvar' without Year FE:";
			di _b[rel_yr`j']/r(mean);
			local coeff = _b[rel_yr9];

			** Coefficient Plot;
			coefplot (`lhsvar', msymbol(triangle) mcolor(blue)),
					keep(*rel_yr*) omitted
					xtitle("Years Since Tax Reform") vertical
					legend(off) graphregion(color(white)) yline(0) xline(4, lp(dash))
					ytitle("Effect of Large `taxlab'" "Increase on `label'")
					ciopts(recast(rcap)) 
					connect(direct) msymbol(diamond);
			graph export "$projdir/Results/Figures/Figure3_EventStudy_`lhsvar'_`tax'.eps", replace;
							
			#delimit cr
			}
		}
end



main

log close
