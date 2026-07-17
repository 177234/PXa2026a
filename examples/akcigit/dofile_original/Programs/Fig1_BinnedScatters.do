cap log close
clear
set more off
program drop _all
file close _all

** Fig2_BinnedScatters.do
** Makes binned scatter plots to reflect our state regressions as shown in Figure 1

** FIRST SET UP A GLOBAL POINTING TO THE DIRECTORY IN WHICH THE REPLICATION PACKET IS STORED.
** Only need to do this if running this code on its own rather than through 0_main.do
*global projdir "<REPLICATION PATH>"

cap mkdir "$projdir/Results/Figures"
cap log close
log using "$projdir/Logs/binned_scatters_stateregs.log", replace


program main
	local lhsvars lnpat ln_inv
	local numquantiles 100

	** Bring in data
	use "$Data/state_data.dta" if inrange(year,1939,2000) & !inlist(stateabbr,"LA","HI","AK","PR",""), clear

	foreach var of varlist mtr90 top_corp {
		replace `var'_lag3 = ln(1-`var'_lag3/100)
		}

	*-common controls
	global contols "l.real_gdp_pc l.population_density rd_credit_lag3 i.statenum"
		
	* Residualize tax rates, weighting regressions by population
	sort statenum year
	areg mtr90_lag3 top_corp_lag3 $controls [aw=pop1940], a(year)
	predict mtr90_resids_weighted, residuals
	areg top_corp_lag3 mtr90_lag3 $controls [aw=pop1940], a(year)
	predict top_corp_resids_weighted, residuals
	
	label var top_corp_lag3 "Ln(1 - Top Corporate MTR)"
	label var mtr90_lag3 "Ln(1 - 90th Percentile Earner Personal Income MTR)"

	* Loop through all dependent variables and make plots for them.
	foreach var in `lhsvars' {
		local label: var label `var'
		
		* Loop through the three tax rate types
		foreach tax in mtr90 top_corp {
			preserve
			local taxlab: var label `tax'
			
			* Generate percentiles of residualized tax rate
			xtile tax_pctiles = `tax'_resids_weighted, nq(`numquantiles')
			if "`tax'" == "top_corp" {
				local residtax mtr90_lag3
				}
			else if "`tax'" == "mtr90" {
				local residtax top_corp_lag3
				}
				
			* Residualize left hand side variable, weighting regressions by population
			areg `var' `residtax' $controls [aw=pop1940], a(year)
			predict `var'_resids, residuals
			
			* Run regression of residuals on residuals after collapse
			reg `var'_resids `tax'_resids_weighted
			
			* Collapse to mean residuals of both taxes and left hand side variables
			* within each tax rate quantile bin. 
			collapse `var'_resids `tax'_resids_weighted [aw=pop1940], by(tax_pctiles) fast
			
			* Make binned scatter plot
			twoway 	(scatter `var'_resids `tax'_resids_weighted, msize(large)) ///
					(lfit `var'_resids `tax'_resids_weighted, lw(medthick) lc(black)), ///
					graphregion(color(white)) legend(off) ///
				ytitle("Residualized `label'") xtitle("Residualized `taxlab'")
			graph export "$projdir/Results/Figures/Figure1_`var'_vs_`tax'.eps", replace
			restore
			}
		}
	
end


main
	
log close
