*------------------------------------------------------------------------------*
* What this does:
*
*   WORLD TRADE - Probability of achieving RCA. 
*
* Dependencies: 
*
*   File for processing world trade data only for probabilities.
*   - "9_COMTRADE_prepareforanalysis_allworld_SITC_probability.do"
*
* Inputs: 
*
*   Prepared COMTRADE truncated for these estimates.
*   - "./data/input/comtrade_worldsitc_panel_cleaned4reg_4digit_prob_HCIonly.dta"
*
* Outputs: 
*
*   A single (pre-fix did_probrca...) : ... 
*   - "did_probrca_results_estout.csv"
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* 1 - SETUP THINGS
*------------------------------------------------------------------------------*
local inputfile "./data/input/comtrade_worldsitc_panel_cleaned4reg_4digit_prob_HCIonly.dta"
compress
estimates clear
capture: estfe . output_*, restore
local outputfilenameprefix did_probrca
use "`inputfile'", clear

*------------------------------------------------------------------------------*
* 2 - REGRESSIONS.
*------------------------------------------------------------------------------*

*----- A. Make OLS regressions + output. -----* 

* 1 - REGRESSION
local modelnumber = 1 
reghdfe rca_dummy korea, ///
		absorb(i.code##i.year) ///
		vce(cluster cty code) ///
		

* ESTOUT: Save regression table, model for estout.
estimates store output_`modelnumber'
estadd local twowayvce "`e(N_clust1)' x `e(N_clust2)'"
estadd ysumm, replace
estadd scalar rsq = e(r2_a)


* 2 - REGRESSION
local modelnumber = `modelnumber'+1
reghdfe rca_dummy korea l_gdp_pc, ///
		absorb(i.code##i.year) ///
		vce(cluster cty code) ///
		

* ESTOUT: Save regression table, model for estout.
estimates store output_`modelnumber'
estadd local twowayvce "`e(N_clust1)' x `e(N_clust2)'"
estadd ysumm, replace
estadd scalar rsq = e(r2_a)				


* 3 - REGRESSION
local modelnumber = `modelnumber'+1
reghdfe rca_dummy korea if ///
		(korea == 1 | quantile_neighbor_kor == 1), ///
		absorb(i.code##i.year) ///
		vce(cluster cty code) ///
		

* ESTOUT: Save regression table, model for estout.
estimates store output_`modelnumber'
estadd local twowayvce "`e(N_clust1)' x `e(N_clust2)'"
estadd ysumm, replace
estadd scalar rsq = e(r2_a)				


* 4 - REGRESSION
local modelnumber = `modelnumber'+1
reghdfe rca_dummy korea if ///
		(korea == 1 | quantile_same_kor == 1), ///
		absorb(i.code##i.year) ///
		vce(cluster cty code) ///
		

* ESTOUT: Save regression table, model for estout.
estimates store output_`modelnumber'
estadd local twowayvce "`e(N_clust1)' x `e(N_clust2)'"
estadd ysumm, replace
estadd scalar rsq = e(r2_a)		


*----- B. Make PPML regressions + output. -----* 

* 1 - PPML 
local modelnumber = `modelnumber'+1
ppmlhdfe rca_dummy korea, ///
		absorb(i.code##i.year) ///
		vce(cluster cty code) ///
		


* ESTOUT: Save regression table, model for estout.
estimates store output_`modelnumber'
estadd local twowayvce "`e(N_clust1)' x `e(N_clust2)'"
estadd ysumm, replace
estadd scalar rsq = e(r2_p)		


* 2 -  PPML
local modelnumber = `modelnumber'+1
ppmlhdfe rca_dummy korea l_gdp_pc, ///
			absorb(i.code##i.year) ///
			vce(cluster cty code) ///
			

* ESTOUT: Save regression table, model for estout.
estimates store output_`modelnumber'
estadd local twowayvce "`e(N_clust1)' x `e(N_clust2)'"
estadd ysumm, replace
estadd scalar rsq = e(r2_p)		


* 3 -  PPML
local modelnumber = `modelnumber'+1
ppmlhdfe rca_dummy korea if ///
		(korea == 1 | quantile_neighbor_kor == 1), ///
		absorb(i.code##i.year) ///
		vce(cluster cty code) ///
		

* ESTOUT: Save regression table, model for estout.
estimates store output_`modelnumber'
estadd local twowayvce "`e(N_clust1)' x `e(N_clust2)'"
estadd ysumm, replace
estadd scalar rsq = e(r2_p)		

* 4 -  PPML
local modelnumber = `modelnumber'+1
ppmlhdfe rca_dummy korea if ///
		(korea == 1 | quantile_same_kor == 1), ///
		absorb(i.code##i.year) ///
		vce(cluster cty code) ///
		

* ESTOUT: Save regression table, model for estout.
estimates store output_`modelnumber'
estadd local twowayvce "`e(N_clust1)' x `e(N_clust2)'"
estadd ysumm, replace
estadd scalar rsq = e(r2_p)		

*------------------------------------------------------------------------------*
* 3 - OUTPUT AND SAVE.
*------------------------------------------------------------------------------*
estfe . output_*, labels(code "Industry Effect" year "Year Effect" code#year "Industry X Year Effect" l_gdp_pc "GDP Per Capita")  
return list
estout output_* ///
	using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
		replace cells(b(star fmt(3)) se(par fmt(3))) ///
				stats(rsq N ymean twowayvce, fmt(3 0 3 %9.0g) ///
					labels("\(R^2\)" Observations "Mean of Dependent Variable" "Clusters (Country-Industry)")) numbers ///
				indicate( `r(indicate_fe)') ///
				collabels(none) ///
				keep( *korea* l_gdp_pc )
