

/*

	Same as other linkage sub loop. 

	Simplified (controls only specifications) and reduced tests.

*/


*--------------------------------------------------------*
* Set parameters.

// Toggle outside the loop. First time it is run.
local replace "replace"

* Start clean regression dump file. Must be here.
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile
 
*--------------------------------------------------------*
* Run regression loop. 

* Loop over PRE-POST and ROLLING regression types. 
foreach didtype in prepost rolling {

	**** i. Setup arguments and filenames for each DID-type. ****
	nameanalysisfromregressor "`mainregressorlist'"
	local mainregressorlist_name "`r(resultname)'" // Assign regressor "name" for string....
	assert "`mainregressorlist_name'" != "" // Test that it isn't empty

	* Analysis name (for output file) estout and others.
	local analysis_name `namesuffix'_`didtype'_`mainregressorlist_name'
	

	* Estout/regsave arguments, do for each DID-type.

	// NOTE: Local argument for variables to keep.
	local estoutkeep "`estoutkeep_`didtype''"
	local didinteraction "`did_`didtype''"

	**** ii. LOOP THROUGH 4 AND 5 DIGIT. **** 

	* Loop over 4 and 5-digit versions of the datasets AND TWO variables of interest.
	foreach datatype in 4 5 {
		prep_data "`dataset`datatype''"
		estimates clear

		**** iii. Loop over outcomes.
		foreach outcome of local outcome_list {


			* Skip 4-digit for TFP estimates. TFP is only in 5-digit.
			if ( regexm("`outcome'","tfp") == 1 & `datatype' == 4 ){
				
				continue
			}

			* Counter starts. Updated at end of internal loop.
			local modelnumber = 1


			**** iv. Loop over total dataset and nontreated only sample. ****

			// 9 and 0 for now. HCI is redundant 
			// OLD: 9 0 1 (All, Non, HCI)
			foreach restrictiondummy in 9 0 {

				*** a. RUN regressions. ***

				// Regression for full sample (restrictiondummy == 9)
				if `restrictiondummy' > 1 {

					* Use full sample FEs if no restrictions.
					local fixedeffects `fullsampleabsorb' 

					* Regression
					reghdfe `outcome' `didinteraction'##c.(`mainregressorlist') , /// 
									absorb( `fixedeffects' ``control_set'' ) ///
									vce(cluster id) verbose(0) noconstant
				}
				else {

					// Else, regression for partial samples (restrictiondummy == 0)
					// Take out the HCI dummy. Since data is restricted to HCI or non-HCI.

					* Use full sample FEs if restrictions.
					local fixedeffects `partsampleabsorb' 

					* Regression on restricted sample.
					reghdfe `outcome' `didinteraction'##c.(`mainregressorlist') ///
									if hci == `restrictiondummy' , /// 
								absorb( `fixedeffects' ``control_set'' ) ///
								vce(cluster id) verbose(0) noconstant

				}

				*** b. REGSAVE
				regsave using "`temp_regressionfile'", pval ci ///
					addlabel( outcome , `outcome',  didtype, `didtype', regressortype ,`mainregressorlist' , restrictions, `restrictiondummy' , controltype , "`control_set'", fixedeffects, "`fixedeffects'" , command,`e(cmd)',datatype,`datatype')  `replace'


				*** c. ESTOUT: Save regression table, model for estout.
				estimates store `outcome'_`modelnumber'
				estadd scalar N_cluster = e(N_clust)



				*** d. MISC: Model iteration, etc.
				local modelnumber = `modelnumber' + 1
				local replace "append"


			} // Loop over non-HCI industry sample and full sample.


			**** v. SAVE REGRESSION OUTPUT: ESTOUT DATASET. ****
			estfe . `outcome'_*, labels(id "Industry Effects" year "Year Effects" hci#year "Targeted X Year") 
			return list
			estout `outcome'_* ///
				using "./data/intermediate_datasets/`analysis_name'_`outcome'_`datatype'estout.csv" , ///
					replace ///
					cells(b(star fmt(a3)) se(par fmt(a3))) ///
					starlevels(* 0.10 ** 0.05 *** .01) ///
					stats(r2 N N_cluster Fs ps Fs2 ps2, fmt(3 0 0) labels("\(R^2\)" Observations Clusters)) ///
					numbers ///
					collabels(none) ///
					indicate(`r(indicate_fe)') ///
					keep( `estoutkeep' ) 

		} // Loop over regression outcomes. 

	} // Loop over 4 and 5-digit datasets. 

} // Loop over pre-post/rolling regressions. 

