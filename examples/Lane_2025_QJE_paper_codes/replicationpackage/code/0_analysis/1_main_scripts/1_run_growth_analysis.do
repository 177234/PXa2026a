*------------------------------------------------------------------------------*
* What this does:
*
*   CORE differences-in-differences/rolling analysis.
*
*   This takes merged/harmonized MMS/KSIC data & 
*   performs basic OUTPUT ("growth") analysis.
*
*   More specifically, this takes the output (a big, harmonized data file) 
*   from the main "foranalysis" datasets and performs analysis.
*
* Dependencies:
*   - gph2xl to save plots.
*   - xtdidregress
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// PROGRAM: prep_data. Small data cleaning and setup helper function.
capture program drop prep_data
program define prep_data
    args filenameargument 
    use "`filenameargument'", clear 
    xtset id year
    gen treat = (hci == 1 & year >= 1973)

end

// PROGRAM: Data export helper function.
capture program drop export_reg_results
program define export_reg_results, rclass

    * [Args] : Load data and append margins 
    args tmpmargindataset tmpdiddataset regressiondir outputfilenameprefix
    use "`tmpdiddataset'", clear 
    append using "`tmpmargindataset'"

    * Clean and export
    drop if missing(year)
    outsheet using "./data/intermediate_datasets/`outputfilenameprefix'_all_results.csv", ///
        comma replace

end

// PROGRAM: add_metadata
capture program drop add_metadata
program define add_metadata

    * Set program arguments
    args estimatename regressortype

    estadd local id_fe Yes, replace
    estadd local year_fe Yes, replace
    
    if "`regressortype'" == "basic_regressors" {
        estadd local control_indicator Yes, replace
    }
    else {
        estadd local control_indicator No, replace
    }
    
    estadd scalar N_cluster = e(N_clust), replace   
end


// PROGRAM: Prep. margin and dataset.
capture program drop append_plot_data
program define append_plot_data

    * Set program arguments
    args tmpmargin tmpdid variable regressorset modelnumber tmpmargindataset tmpdiddataset

    use "`tmpmargin'", clear
    
    * Variables for R. Cleanup.
    gen outcome = "`variable'"
    gen command = "margins"
    gen regressortype = "`regressorset'" 
    gen modelnumber = `modelnumber'
    rename v_t year  
    rename v_mu coef 
    rename set hci 

    * Append the plot data to the master margin dataset.
    if `modelnumber' == 1 {
        save "`tmpmargindataset'"
    }
    else {
        append using "`tmpmargindataset'"
        save "`tmpmargindataset'", replace
    }
    use "`tmpdid'", clear
    
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
        save "`tmpdiddataset'"
    }
    else {
        append using "`tmpdiddataset'"
        save "`tmpdiddataset'", replace
    }
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

* Arguments
local basic_regressors c.(l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0)#i.year
local outcomevariablelist l_ship l_grossoutput l_valueadded
local estoutoptions cells(b(star fmt(3)) se(par fmt(3))) ///
            starlevels(* 0.10 ** 0.05 *** .01) ///
            stats(id_fe year_fe control_indicator r2 N N_cluster Fs ps, fmt(%9.3f %9.3f %9.3f 3 0 0 %9.3f) ///
                labels("Industry Effects" "Year Effects" "Controls" "\(R^2\)" Observations Clusters "Joint Test of Pre-Trend (F-Test)" "Joint Test of Pre-Trend (p-values)")) ///
            numbers noomitted nobaselevels ///
            mlabels(none) ///
            collabels(none) ///

*------------------------------------------------------------------------------*
* I. 5-DIGIT - CORE OUTPUT REGRESSIONS IN PAPER
*------------------------------------------------------------------------------*
local inputfile "./data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta"

*------------------------------------------------------------------------------*
* A. SETUP REGRESSION PARAMETERS
*------------------------------------------------------------------------------*
local outputfilenameprefix did_largerolling_mainresults_alloutput
tempfile tmpmargindataset // Temporary file for trend plot data
tempfile tmpdiddataset // Temporary file for event study/DiD plot data

*------------------------------------------------------------------------------*
* B. LOOP THROUGH REGRESSION PARAMETERS
*------------------------------------------------------------------------------*
local modelnumber = 1

* Loop over outcome variables.
foreach variable of local outcomevariablelist {

    * Loop over specifications with/without controls:
    foreach regressorset in "" "basic_regressors" {
                
        * i. Setup
        tempfile tmpmargin`modelnumber'
        tempfile tmpdid`modelnumber'
        prep_data "`inputfile'"

        * ii. xtdidregress
        quietly: xtdidregress (`variable' ``regressorset'') (treat), group(id) time(year) vce(cluster id)
        estimates store did`modelnumber'_`variable'_5d
        add_metadata did`variable'_`modelnumber' "`regressorset'"

        * A. Generate trend plot (see endnote *1)   
        // This plots the predicted outcomes over time 
        // (see endnote *1 for ellaboration and relation with 'margins' command)
        estat trendplots, ltrends noxline

        * Save plot data to temp dataset.
        gph2xl , saving(`tmpmargin`modelnumber'') list 
        capture: serset clear
        capture: graph drop _all

        * Post estimation test
        quietly: estat ptrends
        local pre_ftest = r(F)
        local pre_testprob = r(p)
        estadd scalar Fs = `pre_ftest', replace
        estadd scalar ps = `pre_testprob', replace

        * B. Dynamic plots
        estat grangerplot, baseline(1972) verbose post
        di _n "Regression Output:"
        ereturn list
        estat summarize

        * Store event study estimates, did coefficients
        estimates store event`modelnumber'_`variable'_5d
        add_metadata did`variable'_`modelnumber' "`regressorset'"
        estadd scalar Fs = `pre_ftest', replace
        estadd scalar ps = `pre_testprob', replace

        * Save plot data to temp dataset.
        gph2xl , saving(`tmpdid`modelnumber'') list 

        * Clear plot data and drop any graphs.
        capture: serset clear
        capture: graph drop _all

        * C. Prepare Stata plot data for R
        
        * Append plot data from this model to the master dataset for the plot data from all models.
        append_plot_data "`tmpmargin`modelnumber''" "`tmpdid`modelnumber''" "`variable'" "`regressorset'" `modelnumber' "`tmpmargindataset'" "`tmpdiddataset'"
        
        * Iterate model number.
        local modelnumber = `modelnumber' + 1
	
    } // Loop over no controls v. controls.
} // Loop over outcomes.


*------------------------------------------------------------------------------*
* C. SAVE REGRESSION OUTPUT: RESULTS DATASET
*------------------------------------------------------------------------------*

* Save regression table for event study estimates using estout.
* The event study estimates are just those relating to the DiD coefficients.
estout event*_5d /// 
    using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
            replace ///
            `estoutoptions' ///
            keep(_l*)
* Save the full DID pre/post table.
* This table contains the full results of the DiD regression including all the regression coefficients.
estout did*_5d ///
    using "./data/intermediate_datasets/`outputfilenameprefix'_prepostresults_estout.csv" , ///
            replace ///
            `estoutoptions' ///
            keep(*.treat)
* Format and save graph results for plotting in R.
export_reg_results `tmpmargindataset' `tmpdiddataset' `"./data/intermediate_datasets"' `outputfilenameprefix'

*------------------------------------------------------------------------------*
* II. 4-DIGIT - CORE OUTPUT REGRESSIONS IN PAPER
*------------------------------------------------------------------------------*

* 4-digit input file.
local inputfile "./data/input/mms_merged_harmonized_panel_cleaned4reg_4digit.dta"

* Key outcomes for 1 and 2.
local outcomevariablelist l_ship l_grossoutput l_valueadded

*------------------------------------------------------------------------------*
* A. SETUP REGRESSION PARAMETERS
*------------------------------------------------------------------------------*

* First part of the output file name:
local outputfilenameprefix did_largerolling_mainresults_alloutput_4d

* Define temporary masterfiles.
tempfile tmpmargindataset // Temporary file for trend plot data
tempfile tmpdiddataset // Temporary file for event study/DiD plot data

*------------------------------------------------------------------------------*
* B. LOOP THROUGH REGRESSION PARAMETERS
*------------------------------------------------------------------------------*

* Initialize model number.
local modelnumber = 1

* Loop over outcomes.
foreach variable of local outcomevariablelist {

    * Loop over specifications with/without covariates:
    foreach regressorset in "" "basic_regressors" {
                
        * i. Setup
        tempfile tmpmargin`modelnumber'
        tempfile tmpdid`modelnumber'
        prep_data "`inputfile'"


        * ii. Execute xtdidregress
        quietly: xtdidregress (`variable' ``regressorset'') (treat), group(id) time(year) vce(cluster id)
        estimates store did`modelnumber'_`variable'_4d
        add_metadata did`variable'_`modelnumber' "`regressorset'"
      
        * A. Generate trend plot (see endnote *1)         
        estat trendplots, ltrends noxline

        * Save plot data to temp dataset.
        gph2xl , saving(`tmpmargin`modelnumber'') list 
        capture: serset clear
        capture: graph drop _all

        * Run pre-trend test
        quietly: estat ptrends // Estout pre-trends test for xtdidregress
        local pre_ftest = r(F)
        local pre_testprob = r(p)
        estadd scalar Fs = `pre_ftest', replace
        estadd scalar ps = `pre_testprob', replace

        * B. Event study plot: Cenerate event study plots
        estat grangerplot, baseline(1972) verbose post

        * Save regression results to estout
        di _n "Regression Output:"
        ereturn list
        estat summarize

        * Store the regression results
        estimates store event`modelnumber'_`variable'_4d
        add_metadata did`variable'_`modelnumber' "`regressorset'"
        estadd scalar Fs = `pre_ftest', replace
        estadd scalar ps = `pre_testprob', replace

        * Save plot data to temp dataset.
        gph2xl , saving(`tmpdid`modelnumber'') list 
        capture: serset clear
        capture: graph drop _all

        * C. Prepare Stata plot data for R        
        append_plot_data "`tmpmargin`modelnumber''" "`tmpdid`modelnumber''" "`variable'" "`regressorset'" `modelnumber' "`tmpmargindataset'" "`tmpdiddataset'"
        local modelnumber = `modelnumber' + 1

    } // Loop over no controls v. controls.
} // Loop over outcomes.


*------------------------------------------------------------------------------*
* C. SAVE REGRESSION OUTPUT: RESULTS DATASET
*------------------------------------------------------------------------------*

* Save regression event study table.
estout event*_4d ///
    using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
            replace ///
            `estoutoptions' ///
            keep(_l*)

* Save full data set for pre/post table.
estout did*_4d ///
    using "./data/intermediate_datasets/`outputfilenameprefix'_prepostresults_estout.csv" , ///
            replace ///
            `estoutoptions' ///
            keep(*.treat)

* Format and save graph results for R.
export_reg_results `tmpmargindataset' `tmpdiddataset' `"./data/intermediate_datasets"' `outputfilenameprefix'


* NOTE: 
*
* Trendplot plots the predicted dynamic DID model (at means of controls, when included)
        
* This is basically the predicted outcomes of the model from "grangerplot", which 
* is the traditional DID plot. See Joerg Luedicke's writing for Stata Corp.

* It is equivalent to predicting/ploting using "margins" post-estimating for a TWFE event
* study model, where the treatment effect is interacted with period effects. (Hence, the linear 
* trend wording is ambigious relative to usage in some applied micro applications.)

* This is used in lieu of margin plots, which are more delicate when combined with 
* baseline reghdfe specifications.

