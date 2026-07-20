*------------------------------------------------------------------------------*
* What this does:
*
*   CORE differences-in-differences/rolling analysis.
*   This takes merged/harmonized MMS/KSIC data & 
*   performs basic analysis, now for general industrial 
*   development outcomes. 
*
*   Similar to the main growth regressions
*   Uses only the loops with controls, for simplicity.
*
* Dependencies:
*
*   Stata supporting the xtdidregress command
*   SSC install command: gph2xl
*
* Inputs: 
*
*   mms_merged_harmonized_panel_cleaned4reg_4digit.dta
*
* Outputs: 
*
*   Outputs named:
*   did_priceandyn_robust_...
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// PROGRAM: Load and prepare the datasets for each chunk.
capture program drop prep_data
program define prep_data

	args filenameargument 
	
	use "`filenameargument'", clear 
	* Set panel for TWFE DID 
	xtset id year
	gen treat = (hci == 1 & year >= 1973)

end


*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* 1 MAIN FLEXIBLE REG. 
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* A. SETUP REGRESSION AND PARAMETERS.
*------------------------------------------------------------------------------*

* Input file.
local inputfile "./data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta"

* First part of the output file name:
local outputfilenameprefix did_priceandyn_robust

* Define temporary masterfile.
capture: tempfile drop tmpmargindataset
capture: tempfile drop tmpdiddataset
tempfile tmpmargindataset
tempfile tmpdiddataset

* Key outcomes
local outcomevariablelist l_ppi l_y_n

* Key control set 
local basic_regressors c.(l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0)#ib(1972).year


*------------------------------------------------------------------------------*
* B. LOOP THROUGH REGRESSION PARAMETERS.
*------------------------------------------------------------------------------*

* Start model number.
local modelnumber = 1

* Loop over outcomes.
foreach variable of local outcomevariablelist {


	* Loop over specifications with/without covariates:
	foreach regressorset in "" "basic_regressors" {

		*** i. SETUP DATASET.
		

		* Define local temporary file for regression dataset.
		capture: tempfile drop tmpmargin`modelnumber'
		capture: tempfile drop tmpdid`modelnumber'
		tempfile tmpmargin`modelnumber'
		tempfile tmpdid`modelnumber'

		* Load and prepare data.
		prep_data "`inputfile'"

		*** ii. EXECUTE DID REGRESSION
		xtdidregress (`variable' ``regressorset'') (treat), group(id) time(year) vce(cluster id)
	
		*** iii. GENERATE PLOTS FROM REGRESSION.
		// NOTE: These plots are edited in R for rendering in paper.

		** A. Generate the margin plot for DID
		estat trendplots, ltrends noxline
		gph2xl , saving(`tmpmargin`modelnumber'') list 
		capture: serset clear
		capture: graph drop _all

		** B. Generate the event study plits for DID
		estat grangerplot, baseline(1972) 
		gph2xl , saving(`tmpdid`modelnumber'') list 
		capture: serset clear
		capture: graph drop _all

		*** iv. PREPARE STATA PLOT DATA FOR R

		** A. EDIT AND APPENT TO MASTER MARGIN DATASET

		// NOTE: Open MARGIN dataset above, edit and append to master datset.
		use "`tmpmargin`modelnumber''", clear

		* Clean and make variables for R data.
		gen outcome = "`variable'"
		gen command = "margins"
		gen regressortype = "`regressorset'"
		gen modelnumber = `modelnumber'

		* Rename variables from gph2xl
		rename v_t year // Year 
		rename v_mu coef // Mean
		rename set hci // The "sets" are HCI and non.

   	    
	    if `modelnumber' == 1 {
	        // If it's the first iteration, just save without appending
	        
	        save "`tmpmargindataset'"
	    }
	    else {
	        // Append to the master file
	        append using "`tmpmargindataset'"
	        save "`tmpmargindataset'", replace
	    }
		** B. EDIT AND APPENT TO MASTER DID DATASET

		// NOTE: Open MARGIN dataset above, edit and append to master datset.
		use "`tmpdid`modelnumber''", clear

		* Clean and make variables for R data.
		gen outcome = "`variable'"
		gen command = "xtdidregress"
		gen regressortype = "`regressorset'"
		gen modelnumber = `modelnumber'

		* Rename variables from gph2xl
		rename *000 ci_lower 
		rename *001 ci_upper 
		rename *002 year 
		rename *003 coef 

   	    
	    if `modelnumber' == 1 {
	        // If it's the first iteration, just save without appending
	        
	        save "`tmpdiddataset'"
	    }
	    else {
	        // Append to the master file
	        append using "`tmpdiddataset'"
	        save "`tmpdiddataset'", replace
	    }
	
		* Iterate model.
		local modelnumber = `modelnumber' + 1

	} // Loop over no controls v. controls.

} // Loop over outcomes.


*------------------------------------------------------------------------------*
* C. SAVE REGRESSION OUTPUT: ESTOUT AND RESULTS DATASET.
*------------------------------------------------------------------------------*

* Load and clean dataset.
use "`tmpdiddataset'", clear 
append using "`tmpmargindataset'"
drop if missing( year )

* Outsheets.
outsheet using  "./data/intermediate_datasets/`outputfilenameprefix'_all_results.csv", ///
	comma replace
