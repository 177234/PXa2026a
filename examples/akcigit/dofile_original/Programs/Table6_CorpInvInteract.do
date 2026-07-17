cap log close
clear 
set more off
program drop _all
file close _all
estimates clear
set matsize 3500

** Table6_CorpInvInteract.do
** Runs inventor level regressions on taxes, interacting with corporate inventor flags.
** Produces the estimates for Table VI, except the bottom "Mobility" row
** which is produced in Table5_MultinomialLogit.do


** FIRST SET UP A GLOBAL POINTING TO THE DIRECTORY IN WHICH THE REPLICATION PACKET IS STORED
** Only need to do this if running this code on its own rather than through 0_main.do
*global projdir "<REPLICATION PATH>"


log using "$projdir/Logs/micro_regs_corpinteraction.log", replace


program main
	#delimit ;
	use "$Data/micro_reg_data" in 1, clear;
			  
	run_regs if !inlist(stateabbr,"LA","","HI","AK") 
				& !mi(state) & inrange(year,1940,2000), 
			  quality_measures(1) qual_cutoffs(10) 
			  lhsvars(pat3yr has_cit3yr lncit3yr) 
			  suffix(_lag3_fullsample_corp_int);
	#delimit cr
	
end

program run_regs
syntax [if], lhsvars(string asis) ///
	quality_measures(string asis) qual_cutoffs(numlist) ///
	[suffix(string asis)]
	
	#delimit ;
	local qualvars;
	foreach qual_measure in `quality_measures' {;
		foreach qual_cutoff in `qual_cutoffs' {;
			local qualvars `qualvars' inv_qual`qual_measure'_top`qual_cutoff'_c;
			};
		};
	use `lhsvars' `qualvars' career_length state mtr90_lag3 mtr50_lag3
		tenure tenure2 agglomeration_lag1 gdppc_lag1 popdens_lag1 rd_credit_lag3 has_corp_pat3yr
		inv_id stateyear year statenum stateabbr base_index_lag3 has_corp_pat3yr top_corp_lag3
		using "$Data/micro_reg_data" `if', clear;
		
	
	gen     base_index_grp = 0 if mi(base_index_lag3);
	replace base_index_grp = 1 if base_index_lag3 < -1;
	replace base_index_grp = 2 if inrange(base_index_lag3,-1,-0.5);
	replace base_index_grp = 3 if inrange(base_index_lag3,-0.5,0);
	replace base_index_grp = 4 if inrange(base_index_lag3,0,0.5);
	replace base_index_grp = 5 if inrange(base_index_lag3,0.5,1);
	replace base_index_grp = 6 if base_index_lag3 > 1 & !mi(base_index_lag3);
		
	gen byte high_base = base_index_lag3 >= 0;
	
	* Generate corporate inventor flag;
	rename has_corp_pat3yr corp_inventor;
	
	foreach qual_measure in `quality_measures' {;
		sort inv_id year;
		* Split individuals into low vs high quality, then assign high quality
		* individuals the tax rate faced by the 90th percentile national earner, and
		* low quality individuals the tax rate faced by the median income individual;
		foreach qual_cutoff in `qual_cutoffs' {;
			gen byte high = L.inv_qual`qual_measure'_top`qual_cutoff'_c == 1;
			summ high;
										  
			gen eff_tax = mtr90_lag3*high + mtr50_lag3*(1-high);
				
			* Put tax variable on a log retention rate scale;
			replace eff_tax = ln(1-eff_tax/100);
			replace top_corp_lag3 = ln(1-top_corp_lag3/100);
			gen eff_tax_corp = eff_tax*corp_inventor;
			gen top_corp_corp = top_corp_lag3*corp_inventor;
			gen eff_tax_noncorp = eff_tax*(1-corp_inventor);
			gen top_corp_noncorp = top_corp_lag3*(1-corp_inventor);
		
			foreach var in `lhsvars' {;
					
					** N.B. Numbers in Table VI correspond to the coefficient on
					** eff_tax_corp, eff_tax_noncorp, top_corp_corp, or top_corp_noncorp
					** when the dependent variable is log citations
					** (i.e. row 3: "# Citations, conditional > 0"). Rows 1 and 2
					** of table VI (# Patents and Pr{Have Patents}) correspond
					** to these coefficients divided by the scalars ymean_corp
					** and ymean_noncorp, which is the mean of the dependent variable 
					** for corporate and non-corporate inventors, respectively.;
					
					eststo `var'_corp: reghdfe `var' eff_tax_corp eff_tax_noncorp top_corp_corp top_corp_noncorp 
									agglomeration_lag1 gdppc_lag1 popdens_lag1 rd_credit_lag3 tenure tenure2
									i.base_index_grp i.base_index_grp#corp_inventor high c.corp_inventor#c.high 
									corp_inventor, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons;
					summ `var' if e(sample) & corp_inventor == 1;
					estadd scalar ymean_corp = r(mean);
					summ `var' if e(sample) & corp_inventor == 0;
					estadd scalar ymean_noncorp = r(mean);
					estadd ysumm;
					
				};
			drop high eff*tax*;
			estwrite * using "$projdir/Results/Regressions/sters/micro_regs_qual`qual_measure'_cut`qual_cutoff'`suffix'${dataset_suffix}.sters", append;
			estimates clear;
			};
		};
	#delimit cr
end


main

log close

