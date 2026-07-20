*------------------------------------------------------------------------------*
* PURPOSE:
*   This is the MICRO-level robustness analysis for LBD.
*   Dataset is not included in the repo and proprietary.
*
* INPUTS: 
*   - "./data/input/mms_TFP_micro.dta"
*
* OUTPUTS: 
*   - mechanism_prod_micro_robustness_results_estout.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*
capture program drop prep_data
program define prep_data
	args filenameargument 
	use "`filenameargument'", clear 
	egen ksic_id = group( ksic_merged )
end

capture program drop runestaddprogram
program define runestaddprogram
	syntax [, regressorstype(string asis)]

	estadd local plantfe "Yes"
	estadd local timefe "Yes"
    estadd local industryfe "Yes"
    estadd local twowayvce = "`e(N_clust1)' x `e(N_clust2)'"
    estadd local hasplantsize = cond(regexm("`regressorstype'", "l_workers"), "Yes", "No")
    estadd local hascapitalintensity = cond(regexm("`regressorstype'", "l_k_n"), "Yes", "No")
    estadd local hasskillratio = cond(regexm("`regressorstype'", "l_skill_ratio"), "Yes", "No")
    estadd local hasinvestment = cond(regexm("`regressorstype'", "l_i_n"), "Yes", "No")
    estadd local hasintermediates = cond(regexm("`regressorstype'", "l_m_n"), "Yes", "No")
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*
* NOTE: This file is not included in the replication package.
local inputfilemicro "./data/input/mms_TFP_micro.dta"

*------------------------------------------------------------------------------*
* I. - LEARNING-BY-DOING PANEL REGS - FULL REGS ROBUSTNESS.
*------------------------------------------------------------------------------*

* A. GENERAL SETUP FOR (1) AND (2).
estimates clear
local outputfilenameprefix "mechanism_prod_micro_robustness"
local outcomevariablelist l_ucr tfp_acf tfp_lp tfp_w tfp_op
local controls l_workers l_k_n l_skill_ratio l_i_n l_m_n

* Mimic the regression in earlier.
local set i.hci##c.l_experience i.hci##c.l_experience_ksic `controls', absorb( id year i.ksic_id ) 
local regressorstype "`set'"

*------------------------------------------------------------------------------*
* 1. MICRO REGRESSIONS NON NORMALIZED EXPERIENCE.
*------------------------------------------------------------------------------*

* A. PREPARE MAIN VARS FOR REGRESSION
prep_data "`inputfilemicro'"

* B. REGRESSION LOOP

* Loop over outcomes.
foreach variable of local outcomevariablelist {

	* Execute regression.
	reghdfe `variable' `regressorstype' ///
		vce( cluster ksic_id id )

	* ESTOUT: Save regression table, model for estout.
	estimates store output_`variable'_`modelnumber'

	* Add indicators
	runestaddprogram, regressorstype(`regressorstype')

	* Perform linear combination estimate for plants (firm-level experience)
	lincom l_experience + 1.hci#c.l_experience 
	estadd scalar combobeta r(estimate)
	estadd scalar combose r(se)

	* Perform linear combination estimate for plants (industry-level experience)
	capture: lincom l_experience_ksic + 1.hci#c.l_experience_ksic
	if _rc == 0 {
		estadd scalar combobeta_ind r(estimate)
		estadd scalar combose_ind r(se)
	}
	else {
		estadd scalar combobeta_ind .
		estadd scalar combose_ind .
	}

	* Add polynomial indicator
   	estadd local haspoly = "No" 

	* Model counter.
	local modelnumber = `modelnumber' + 1
} // Loop over outcomes.


*------------------------------------------------------------------------------*
* 2. MICRO REGRESSIONS NORMALIZED (BY N WORKERS).
*------------------------------------------------------------------------------*

* A. PREPARE MAIN VARS FOR REGRESSION
* NOTE: This file is not included in the replication package.
prep_data "`inputfilemicro'"

* Rename the variables so they end up on the same lines of estout
* First rename og variables:
rename l_experience l_experience_
rename l_experience_ksic l_experience_ksic_

* Rename worker normalized version to original.
rename l_experience_n l_experience
rename l_experience_ksic_n l_experience_ksic

* B. REGRESSION LOOP

// Start model number.
local modelnumber = 1

* Loop over outcomes.
foreach variable of local outcomevariablelist {


	*** Execute regression.
	reghdfe `variable' `regressorstype' ///
		vce( cluster ksic_id id )

	*** ESTOUT: Save regression table, model for estout.
	estimates store output_`variable'_`modelnumber'

	* Add indicators
	runestaddprogram, regressorstype(`regressorstype')

	* Perform linear combination estimate for plants (firm-level experience)
	lincom l_experience + 1.hci#c.l_experience 
	estadd scalar combobeta r(estimate)
	estadd scalar combose r(se)

	* Perform linear combination estimate for plants (industry-level experience)
	capture: lincom l_experience_ksic + 1.hci#c.l_experience_ksic
	if _rc == 0 {
		estadd scalar combobeta_ind r(estimate)
		estadd scalar combose_ind r(se)
	}
	else {
		estadd scalar combobeta_ind .
		estadd scalar combose_ind .
	}

	* Add polynomial indicator
   	estadd local haspoly = "No" 
	local modelnumber = `modelnumber' + 1
} // Loop over outcomes.

* C. REGRESSION OUTPUTS.
estout output_* ///
	using "./data/included_datasets/`outputfilenameprefix'_results_estout.csv", ///
		replace ///
		cells(b(star fmt(3)) se(par fmt(3))) ///
		starlevels(* 0.10 ** 0.05 *** .01) ///
		stats(hasplantsize hascapitalintensity hasskillratio hasinvestment hasintermediates haspoly plantfe timefe industryfe r2 N twowayvce combobeta combose combobeta_ind combose_ind, layout(@ @ @ @ @ @ @ @ @ @ @ @ @ (@) @ (@)) fmt(%s %s %s %s %s %s %s %s %s 3 0 %9.0g %9.3f %9.3f %9.3f %9.3f) ///
			labels("Control for Plant Size" "Control for Capital" "Control for Skill Ratio" "Control for Investment" "Control for Intermediates" "Polynomial Controls" "Plant Effect" "Year Effect" "Industry Effect" "\(R^2\)" Observations "Clusters (Industry and Plant)" "Linear Combination (Plant-Level)" "(St.Err.)" "Linear Combination (Industry-Level)" "(St.Err.)" )) ///
		numbers ///
		collabels(none) ///
		order(l_experience 1.hci#c.l_experience l_experience_ksic 1.hci#c.l_experience_ksic ) ///
		varlabels(l_experience "Plant Experience" 1.hci#c.l_experience "Targeted x Plant Experience" ///
				  l_experience_ksic "Industry Experience" 1.hci#c.l_experience_ksic "Targeted x Industry Experience") ///
		keep(l_experience* 1.*c.*exp*)

** Small cleaning of estout file.

* Load the estout file.
import delimited using "./data/included_datasets/`outputfilenameprefix'_results_estout.csv", clear 

* Delete blank lines.
foreach var of varlist v* {
	replace `var' = "" if ( strrtrim(`var')=="." | strrtrim(`var')=="(.)" ) 
}

* Save the estout file.
export delimited using "./data/included_datasets/`outputfilenameprefix'_results_estout.csv", replace 
