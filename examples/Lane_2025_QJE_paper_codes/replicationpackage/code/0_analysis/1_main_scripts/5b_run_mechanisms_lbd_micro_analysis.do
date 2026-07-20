*------------------------------------------------------------------------------*
* What this does:
*   This is the MICRO-level robustness analysis for LBD.
*
* INPUTS: 
*   - "./data/input/mms_TFP_micro.dta"
*
* Outputs: 
*   mechanism_prod_micro_results_estout.csv  
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

	* Default add FEs
	estadd local plantfe "Yes"
	estadd local timefe "Yes"
    estadd local industryfe "Yes"

	* Add clusters.
    estadd local twowayvce = "`e(N_clust1)' x `e(N_clust2)'"

    // Plant size control
    estadd local hasplantsize = cond(regexm("`regressorstype'", "l_workers"), "Yes", "No")

    // Capital intensity control
    estadd local hascapitalintensity = cond(regexm("`regressorstype'", "l_k_n"), "Yes", "No")

    // Skill ratio control
    estadd local hasskillratio = cond(regexm("`regressorstype'", "l_skill_ratio"), "Yes", "No")

    // Investment control
    estadd local hasinvestment = cond(regexm("`regressorstype'", "l_i_n"), "Yes", "No")
    estadd local hasintermediates = cond(regexm("`regressorstype'", "l_m_n"), "Yes", "No")
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* I. - LEARNING-BY-DOING PANEL REGS - MICRO HCI ONLY.
*------------------------------------------------------------------------------*

* Setup
* NOTE: This file is not included in the replication package.
local inputfilemicro "./data/input/mms_TFP_micro.dta"
prep_data "`inputfilemicro'"
estimates clear

* Loop arguments.
local outputfilenameprefix "mechanism_prod_micro"
local outcomevariablelist l_uc tfp_acf
local controls l_workers l_k_n l_skill_ratio l_i_n l_m_n
local set1 i.hci##c.l_experience `controls'
local set2 i.hci##c.l_experience i.hci##c.l_experience_ksic `controls'
local set3 i.hci##c.l_experience i.hci##c.l_experience_ksic c.(`controls')##c.(`controls')##c.(`controls')


*------------------------------------------------------------------------------*
* 1. MICRO REGRESSIONS NON NORMALIZED EXPERIENCE.
*------------------------------------------------------------------------------*

* Regression loop.
local modelnumber = 1
foreach variable of local outcomevariablelist {

    * Regressors or not.
    foreach regressorstype in "`set1'" "`set2'" "`set3'" {
        
        * Execute regression.
        quietly reghdfe `variable' `regressorstype', ///
                        absorb( id year ksic_id ) ///
                        vce( cluster ksic_id id )        

        * Post regression prep.
        estimates store output_`variable'_`modelnumber'

        * Add indicators
        runestaddprogram, regressorstype(`regressorstype')

        * Linear combination estimate for plants (firm-level experience)
        lincom l_experience + 1.hci#c.l_experience
        estadd scalar combobeta r(estimate)
        estadd scalar combose r(se)

        * Linear combination estimate for plants (industry-level experience)
        capture: lincom l_experience_ksic + 1.hci#c.l_experience_ksic
        if _rc == 0 {
            estadd scalar combobeta_ind r(estimate)
            estadd scalar combose_ind r(se)
        }
        else {
            estadd scalar combobeta_ind .
            estadd scalar combose_ind .
        }

		* Polynomial indicator
    	estadd local haspoly = cond(`modelnumber'==3 | `modelnumber'==6, "Yes", "No")
        local modelnumber = `modelnumber' + 1
    } // Loop of control sets. 
} // End of loop over outcome variables


*------------------------------------------------------------------------------*
* 2. SAVE ESTOUT FOR ALL REGRESSIONS.
*------------------------------------------------------------------------------*
* Export; avoids fantom rc neq 0 after save.
capture estout output_* ///
	using "./data/included_datasets/`outputfilenameprefix'_results_estout.csv", ///
		replace ///
		cells(b(star fmt(3)) se(par fmt(3))) ///
		starlevels(* 0.10 ** 0.05 *** .01) ///
		stats(hasplantsize hascapitalintensity hasskillratio hasinvestment hasintermediates haspoly plantfe timefe industryfe r2 N twowayvce combobeta combose combobeta_ind combose_ind, layout(@ @ @ @ @ @ @ @ @ @ @ @ @ (@) @ (@)) fmt(%s %s %s %s %s %s %s %s %s 3 0 %9.0g %9.3f %9.3f %9.3f %9.3f) ///
			labels("Control for Plant Size" "Control for Capital" "Control for Skill Ratio" "Control for Investment" "Control for Intermediates" "Polynomial Controls" "Plant Effect" "Year Effect" "Industry Effect" "R2" "Observations" "Clusters (Industry and Plant)" "Linear Combination (Plant-Level)" "(St.Err.)" "Linear Combination (Industry-Level)" "(St.Err.)" )) ///
		numbers ///
		collabels(none) ///
		order(l_experience 1.hci#c.l_experience l_experience_ksic 1.hci#c.l_experience_ksic ) ///
		varlabels(l_experience "Plant Experience" 1.hci#c.l_experience "Targeted × Plant Experience" ///
				  l_experience_ksic "Industry Experience" 1.hci#c.l_experience_ksic "Targeted × Industry Experience") ///
		 keep( l_exp* 1*hci*l_exp* )

* Minor clean. 
insheet using "./data/included_datasets/`outputfilenameprefix'_results_estout.csv", clear 
foreach var of varlist v* {
	replace `var' = "" if ( strrtrim(`var')=="." | strrtrim(`var')=="(.)" ) 
}

* Save the estout file.
outsheet using "./data/included_datasets/`outputfilenameprefix'_results_estout.csv", replace 
