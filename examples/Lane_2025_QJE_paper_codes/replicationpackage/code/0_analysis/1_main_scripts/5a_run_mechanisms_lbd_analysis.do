*------------------------------------------------------------------------------*
* PURPOSE:
*   This is the mechanisms analysis file, for LDB estimates. 
*   This is the INDUSTRY-level analysis. 
*
* INPUTS: 
*   - "./data/input/mms_TFP_5digit.dta"
*
* OUTPUTS: 
*   - mechanism_prod_interactions_results_estout.csv
*   - mechanism_prod_interactions_alt_results_estout.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*
capture program drop prep_data
program define prep_data
	args filenameargument 
	use "`filenameargument'", clear 
	keep if year >= 1973
end

capture program drop runestaddprogram
program define runestaddprogram

    * Argument syntax
    syntax [, regressorstype(string asis)]

	estadd local indfe "Yes"
	estadd local timefe "Yes"
	estadd scalar N_cluster = e( N_clust )

    * Add indicator for plant size control
    if( regexm("`regressorstype'","l_avg_size")==1 ){
        estadd local hasplantsize "Yes"
    }
    else {
        estadd local hasplantsize "No"
    }
    * Add indicator for capital intensity control
    if( regexm("`regressorstype'","l_k_n")==1 ){
        estadd local hascapitalintensity "Yes"
    }
    else {
        estadd local hascapitalintensity "No"
    }
    * Add indicator for intermediates
    if( regexm("`regressorstype'","l_m_n")==1 ){
        estadd local hasintermediates "Yes"
    }
    else {
        estadd local hasintermediates "No"
    }
	* Add indicator for investment
    if( regexm("`regressorstype'","l_i_n")==1 ){
        estadd local hasinvestment "Yes"
    }
    else {
        estadd local hasinvestment "No"
    }
    di "(Added estadd indicators)"
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*
local inputfile5 "./data/input/mms_TFP_5digit.dta"

*------------------------------------------------------------------------------*
* I. - BASELINE
*------------------------------------------------------------------------------*
local outcomevariablelist l_ppi l_uc tfp_acf tfp_lp tfp_w


*------------------------------------------------------------------------------*
* IND W INTERACTIONS.
*------------------------------------------------------------------------------*
estimates clear
local outputfilenameprefix = "mechanism_prod_interactions"
prep_data "`inputfile5'"

* Control sets.
local firstset i.hci##c.(l_experience) l_avg_size l_workers  // Size and scale
local secondset i.hci##c.(l_experience) l_workers l_avg_size l_k_n l_m_n l_i_n // Additional

*------------------------------------------------------------------------------*
* REGRESSION LOOP
*------------------------------------------------------------------------------*
foreach variable of local outcomevariablelist {
	local modelnumber = 1
    
    * Loop, controls.
	foreach regressorstype in `"`firstset'"' `"`secondset'"'{

		reghdfe `variable' `regressorstype' , ///
			absorb( id year ) ///
			vce( cluster id ) 

		estimates store output_`variable'_`modelnumber'
		runestaddprogram, regressorstype(`regressorstype')

		* Grab lincombination estimate.
		lincom l_experience + 1.hci#c.l_experience
		estadd scalar combobeta = r(estimate)
		estadd scalar combose = r(se)

		* Model counter.
		local modelnumber = `modelnumber' + 1
	} // Loop over sets of controls
} // Loop  over outcomes.

*------------------------------------------------------------------------------*
* MAKE REGRESSION OUTPUT. 
*------------------------------------------------------------------------------*
estout output_* ///
	using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
		replace ///
		cells(b(star fmt(3)) se(par fmt(3))) ///
		starlevels(* 0.10 ** 0.05 *** .01) ///
		stats( hasplantsize hascapitalintensity hasintermediates hasinvestment indfe timefe r2 N N_cluster combobeta combose, layout(@ @ @ @ @ @ @ @ @ @ (@)) fmt(%s %s %s %s %s %s 3 0 0 %9.3f %9.3f ) ///
			labels( "Controls for Size-Scale" "Controls for Capital Intensity" "Controls for Intermediates" "Controls for Investment" "Industry Effects" "Year Effects" "R2" "Observations" "Clusters" "Linear Combination" "(St.Err.)" )) ///
		numbers ///
		collabels(none) ///
		keep( l_exp* 1*hci*l_exp* )

*------------------------------------------------------------------------------*
* II. - ROBUSTNESS (ALTERNATIVE MEASURES)
*------------------------------------------------------------------------------*
estimates clear
local outputfilenameprefix "mechanism_prod_interactions_alt"

* Regression arguments. 
local outcomevariablelist l_ppi l_uc l_ucr tfp_op tfp_acf tfp_lp tfp_w
local experiencelist l_experience_n l_experience_alt
local controllist l_workers l_avg_size l_k_n l_m_n l_i_n 
local modelnumber = 1

*------------------------------------------------------------------------------*
* REGRESSION LOOP
*------------------------------------------------------------------------------*
foreach variable of local outcomevariablelist {
	prep_data "`inputfile5'"
	drop l_experience

    * Loop, controls.
    foreach experience in `experiencelist' {

        * Rename for estout
        if "`experience'" != "l_experience" {
            rename `experience' l_experience
        }        

        * Execute regression.
        reghdfe `variable' i.hci##c.(l_experience) ///
            `controllist', ///
            absorb( id year ) ///
            vce( cluster id )

        * Post regression prep.
        estimates store output_`variable'_`modelnumber'
        runestaddprogram, regressorstype(`controllist')

        * Linear combination.
        lincom l_experience + 1.hci#c.l_experience
        estadd scalar combobeta = r(estimate)
        estadd scalar combose = r(se)

        estadd local measurelabel "`experience'"

        * Model counter.
        local modelnumber = `modelnumber' + 1

        * Rename for next experience variable.
        if "`experience'" == "l_experience" {
            rename l_experience `experience'_rename
        }
        else {
            * For all other loops, revert to og name.
            rename l_experience `experience'_2
        }
    } // Loop over measures.
} // Loop over outcomes.

*------------------------------------------------------------------------------*
* MAKE REGRESSION OUTPUT. 
*------------------------------------------------------------------------------*
local n_regs : word count `outcomevariablelist'
local n_types : word count `experiencelist'
local n_patterns = `n_regs'*`n_types'

* Dynamic pattern string for mgroups.
local pattern_string ""
forvalues i = 1/`n_patterns' {
    local pattern_string `"`pattern_string' 1 "'
}

* Repeat the list of variables for number of regs
local titlelist
forvalues i = 1/`n_regs' {
    foreach string of local experiencelist {
        local titlelist `titlelist' `string'
    }
}

* Export; avoids fantom rc neq 0 after save.
capture estout output_* ///
    using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
        replace ///
        cells(b(star fmt(3)) se(par fmt(3))) ///
        starlevels(* 0.10 ** 0.05 *** .01) ///
        stats( hasplantsize hascapitalintensity hasintermediates hasinvestment indfe timefe r2 N N_cluster combobeta combose, layout(@ @ @ @ @ @ @ @ @ @ (@)) fmt(%s %s %s %s %s %s 3 0 0 %9.3f %9.3f ) ///
            labels( "Controls for Size" "Controls for Capital Intensity" "Controls for Intermediates" "Controls for Investment" "Industry Effects" "Year Effects" "R2" "Observations" "Clusters" "Linear Combination" "(St.Err.)" )) ///
        nonumbers ///
        collabels(none) ///
        mlabels(, depvar) ///
        mgroups(`titlelist', pattern(`pattern_string')) ///
        keep( l_exp* 1*hci*l_exp* )