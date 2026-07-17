cap log close
clear 
set more off
program drop _all
estimates clear
set matsize 3500

** Table4_MicroRegs.do
** Runs inventor level regressions on state taxes

** FIRST SET UP A GLOBAL POINTING TO THE DIRECTORY IN WHICH THE REPLICATION PACKET IS STORED
** Only need to do this if running this code on its own rather than through 0_main.do
*global projdir "<REPLICATION PATH>"

log using "$projdir/Logs/MicroRegs.log", replace

program main
	#delimit ;
	use "$Data/micro_reg_data" in 1, clear;
				  
	** TABLE IV: Baseline;
	run_regs if !inlist(stateabbr,"LA","","HI","AK","PR") 
				& !mi(state) & inrange(year,1940,2000), 
			  quality_measures(1) qual_cutoffs(10)
			  additional_controls(agglomeration_lag1 tenure tenure2)
			  additional_controls_stfe(gdppc_lag1 popdens_lag1 top_corp_lag3 rd_credit_lag3)
			  lhsvars(has_pat3yr has10cit_3yr lnpat3yr lncit3yr high_kpss3yr) 
			  suffix(_lag`lag'_fullsample);
	
	#delimit cr
end

program run_regs
syntax [if], lhsvars(string asis) ///
	quality_measures(string asis) qual_cutoffs(numlist) ///
	[suffix(string asis) ADDitional_controls(string asis) ///
	ADDitional_controls_stfe(string asis) home_state married_rate]
	
	
	#delimit ;
	
	use "$Data/micro_reg_data" `if', clear;
	
		
	if "`married_rate'" != "" {;
		local tax_suffix _married;
		};
		
	if "`home_state'" != "" {;
		local homesuffix _home;
		};
				
	replace top_corp_lag3 = ln(1-top_corp_lag3/100);
	replace rd_credit_lag`lag_rd' = ln(1-rd_credit_lag3/100);
	
	foreach qual_measure in `quality_measures' {;
		sort inv_id year;
		* Split individuals into low vs high quality, then assign high quality
		* individuals the tax rate faced by the 90th percentile national earner, and
		* low quality individuals the tax rate faced by the median income individual;
		foreach qual_cutoff in `qual_cutoffs' {;
			* Generate high quality flag;
			gen byte high = L.inv_qual`qual_measure'_top`qual_cutoff'_c == 1;
			
			* Generate persistence of high quality flag reported in text;
			gen byte high_unlagged = inv_qual`qual_measure'_top`qual_cutoff'_c == 1;
			tab high high_unlagged, row col;
			
			* Generate effective personal tax rate;
			gen eff_tax = mtr`tax_suffix'90_lag3`homesuffix'`item'*high
							+ mtr`tax_suffix'50_lag3`homesuffix'`item'*(1-high);
			
			* Put effective tax rate in log retention rate scale;
			replace eff_tax = ln(1-eff_tax/100);
				
			* Interact with agglomeration;
			gen eff_tax_agglom = eff_tax * agglomeration_lag1;
			gen top_corp_agglom = top_corp_lag3 * agglomeration_lag1;
					
			* Label variables;
			label var high "High Quality Inventor";
			label var eff_tax "Effective Marginal Tax Rate";
			label var eff_tax "Log(1 - Effective Marginal Tax Rate)";
			label var top_corp_lag3 "Log(1 - Top Corporate Tax Rate)";				
		
			foreach var in `lhsvars' {;
					
				** State + Year + Inventor FE;					
				eststo `var'_invfe: 
									reghdfe `var' eff_tax high
									`additional_controls' 
									`additional_controls_stfe'
									, absorb(inv_id statenum year) 
									vce(cluster statenum year) keepsingletons;
				estadd ysumm;
				
				** State x Year + Inventor FE.;
				eststo `var'_bakinv: 
									reghdfe `var' eff_tax high
									`additional_controls'
									, absorb(inv_id stateyear)
									vce(cluster statenum year) keepsingletons;
				estadd ysumm;
				
			};
		drop high high_unlagged eff*tax* top_corp_agglom;
		estwrite * using "$projdir/Results/Regressions/sters/micro_regs_qual`qual_measure'_cut`qual_cutoff'`suffix'${dataset_suffix}.sters", append;
		estimates clear;
		};
		};
	#delimit cr
end

main

log close

