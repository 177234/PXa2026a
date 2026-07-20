

*------------------------------------------------------------------------------*
* What this does:
*   Generates the analysis for trade policy.
*
* Outputs: 
*   Estout files with prefix: 
*   did_input_tradepolicy_results_estout.csv 
*   did_output_tradepolicy_results_estout.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// PROGRAM: Load and prepare the datasets for each chunk.
capture program drop prep_data
program define prep_data

	args filenameargument 

	
	use "`filenameargument'", clear 

	// Just in case, clear early estimates.
	//* Capture, empty estfe if it has been run already.
	estimates clear
	capture: estfe . output_*, clear
	
	* Replace post for most analysis.
	capture: drop post
	gen post = 0 
	replace post = 1 if year >= 1973
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* 1. RUN TRADE POLICY REGRESSIONS
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* A. SETUP AND PREPARE SMALL PANEL
*------------------------------------------------------------------------------*

* Input file.
local inputfile4d "./data/input/tradepolicy_panel.dta"

* Load and prepare data.
prep_data "`inputfile4d'"

*------------------------------------------------------------------------------*
* B. SETUP REGRESSION PARAMETERS
*------------------------------------------------------------------------------*

local outcomevariablelist_output l_tariff_wt l_qr_wt d.l_qr_wt d.l_tariff_wt
local outcomevariablelist_input l_tariff_input_wt l_qr_input_wt d.l_tariff_input_wt d.l_qr_input_wt

* Key controls.
local basic_regressors l_avg_wages_0 l_avg_size_0 l_y_n_0 l_costs_0

*------------------------------------------------------------------------------*
* C. LOOP OVER THE TYPE OF TRADE POLICY
*------------------------------------------------------------------------------*

* Loop over outcomes variable.
foreach protectiontype in "output" "input" {

	** Setup new table for in/output tariffs.

	* Clear things up
	estimates clear
		
	* Start model number, outside of the loop now.
	local modelnumber = 1

	* First part of the output file name:
	local outputfilenameprefix did_`protectiontype'_tradepolicy

	* Toggle replace local
	local replace "replace"

	* Loop over outcomes variable.
	foreach variable of local outcomevariablelist_`protectiontype' {

		* Loop over different year samples.
		foreach yearconstraint in "" "if year>1973"  {

			* Skip changes for 1973 constraint. We want the early DELTA.
			if "`yearconstraint'" != "" & regexm("`variable'", "^d") == 1 {	
				continue
			}

			* Loop across controls vs no controls.
			foreach regressortype in "" "`basic_regressors'" {

				* Execute regression.
				// USE start year, not 1972.
				reghdfe `variable' hci i.year##c.( `regressortype' ) ///
						`yearconstraint' , ///
					absorb( year ) ///
					vce(cluster id)

				*** ii. ESTOUT: Save regression table, model for estout.

				// Rename outcome to avoid long string length issue.
				local renamevariable = regexr( "`variable'" , "_wt", "" )
				local renamevariable = regexr( "`renamevariable'" , "\.", "" )
				

				estimates store output_`renamevariable'_`modelnumber'				

				** Add indicator of year constraint scalar to ESTOUT ROW:
				
				* Choose right label:
				if "`yearconstraint'" ==  "" {
					local constraintlabel "Full"
				} 						
				else {
					local constraintlabel "Post-1973"
				}

				* Add year constraint to estout.
				estadd local year_constraint "`constraintlabel'"

				* Add number of clusters to estout.
				estadd scalar N_cluster = e( N_clust )

				*** iii. MISC: Model iteration, etc.

				* Model counter.
				local modelnumber = `modelnumber' + 1

				* Replacement switch for REGSAVE.
				local replace "append"

			} // Loop over no controls v. controls.
		} // Loop over different year samples.
	} // Loop over outcomes.

	* Save estout output.
	estout output_* ///
		using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
		replace ///
		cells(b(star fmt(3)) se(par fmt(3))) ///
		starlevels(* 0.10 ** 0.05 *** .01) ///
		stats(year_constraint r2 N N_cluster , fmt(%9.3f 3 0 0) labels(Sample "\(R^2\)" Observations Clusters)) ///
		numbers ///
		indicate( "Year Effect=*.year" "Controls=1974.year#c.*avg_wages_0", labels("Yes" "") ) ///
		collabels(none) ///
		keep( *hci* )

} // Loop over output v input type outcomes.
