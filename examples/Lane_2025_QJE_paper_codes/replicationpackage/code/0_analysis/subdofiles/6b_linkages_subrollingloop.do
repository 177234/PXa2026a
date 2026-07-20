

/*

	MAIN Do-file loop (MUST BE "INCLUDED")


	NOTE: Main sub-do-file for linkage analysis. 


*/


*--------------------------------------------------------*
*. Set parameters.

* Start clean regression dump file. Must be here.
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile


// Toggle outside the loop. First time loop is run.
local replace "replace"


*--------------------------------------------------------*
*. Run regression loop. 


* Loop over PRE-POST and ROLLING regression:
foreach didtype in prepost rolling {


	


	**** i. Setup arguments and filenames for each DID-type. ****


	* Run program to automatically assign name to regressor TYPE (in/out/both)
	nameanalysisfromregressor "`mainregressorlist'"
	local mainregressorlist_name "`r(resultname)'" // Assign regressor "name" for string....
	assert "`mainregressorlist_name'" != "" // Test that it isn't empty

	* Analysis name (for output file) estout and others.
	local analysis_name `namesuffix'_`didtype'_`mainregressorlist_name'
	



	* Estout/regsave arguments, do for each DID-type.

	// NOTE: Local argument for variables to keep.
	local estoutkeep "`estoutkeep_`didtype''"
	

	// NOTE: This selects "TYPE" of DID.
	local didinteraction "`did_`didtype''"



	**** ii. LOOP THROUGH 4 AND 5 DIGIT. **** 
	

	* Loop over 4 and 5-digit versions of the datasets AND TWO variables of interest.
	foreach datatype in 4 5 {


		* If outcome list is made of trade outcomes and datatype is 5, skip.
		if( regexm("`outcome_list'","trade")==1 & `datatype' == 5 ){
			
			continue
		}			


		* Load and prepare data: load and prepare 4 or 5-digit dataset:
		prep_data "`dataset`datatype''"



		**** iii. Loop over outcomes. ****
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

					* Use full sample fixedeffects if no restrictions.
					local fixedeffects `fullsampleabsorb' 

					* Regression
					reghdfe `outcome' `didinteraction'##c.(`mainregressorlist') , /// 
									absorb( `fixedeffects' ``control_set'' ) ///
									vce(cluster id) verbose(0) noconstant vsquish
				
				}
				else {

					// Else, regression for partial samples (restrictiondummy == 0)
					// Take out the HCI dummy. Since data is restricted to HCI or non-HCI.

					* Use full sample fixedeffects if restrictions.
					local fixedeffects `partsampleabsorb' 

					* Regression on restricted sample.
					reghdfe `outcome' `didinteraction'##c.(`mainregressorlist') ///
								if hci == `restrictiondummy' , /// 
							absorb( `fixedeffects' ``control_set'' ) ///
							vce(cluster id) verbose(0) noconstant
				}


				*** b. REGSAVE: regression output and the TEST results:

				* Save results to regsave table.
				
				regsave using "`temp_regressionfile'", pval ci ///
					addlabel( outcome , `outcome',  didtype, `didtype', regressortype , `mainregressorlist' , restrictions, `restrictiondummy' , fixedeffects, "`fixedeffects'" , command,`e(cmd)',datatype,`datatype')  `replace'




				*** c. ESTOUT: Save regression table, model for estout.

				* Save regression table, model for estout.
				estimates store `outcome'_`modelnumber'

				* Add number of clusters.
				estadd scalar N_cluster = e(N_clust)



				*** d. JOINT TEST: Run test -- only coherent for event study.

				// Thus only for rolling regressions.
				if regexm( "`didtype'", "rolling" ) == 1 {

					

					* Tokenize regressor list and perform pre-trend test for each.
					tokenize "`mainregressorlist'"

					* FIRST, with TOKEN 1
					make_pretest_vars "`1'" "`outcome'"

					test `r(result)'
					local pre_ftest = `r(F)'
					local pre_testprob = `r(p)'

					* Add test results to estout.
					estadd scalar Fs r(F)
					estadd scalar ps r(p)


					* SECOND, with TOKEN 2
					make_pretest_vars "`2'" "`outcome'"

					test `r(result)'
					local pre_ftest = `r(F)'
					local pre_testprob = `r(p)'

					* Add test results to estout.
					estadd scalar Fs2 r(F)
					estadd scalar ps2 r(p)


					* Estout labels, fmt, and numbers.
					local estoutlabels `"1st Joint Test of Pre-Trend (F-Test)" "1st Joint Test of Pre-Trend (p-values)" "2nd Joint Test of Pre-Trend (F-Test)" "2nd Joint Test of Pre-Trend (p-values)"' 
					local estoutfmt "%9.3f %9.3f %9.3f %9.3f"
					local estoutstats "Fs ps Fs2 ps2"
				}
				else {

					local estoutlabels ""
					local estoutfmt ""
					local estoutstats ""

				}
				
				*** e. MISC: Model iteration, etc.

				* Model counter.
				local modelnumber = `modelnumber' + 1

				* Replacement switch for REGSAVE.
				local replace "append"


			} // Loop over non-HCI industry sample and full sample.


			**** v. SAVE REGRESSION OUTPUT: ESTOUT DATASET. ***

			// NOTE: Must be in same loop as outcome iterator.

			
			estfe . `outcome'_*, labels(id "Industry Effects" year "Year Effects" hci#year "Targeted X Year") 
			return list


			* Save estout regression table for each group of outcomes AND 4 versus 5-digit:
			estout `outcome'_* ///
				using "./data/intermediate_datasets/`analysis_name'_`outcome'_`datatype'estout.csv" , ///
					replace ///
						cells(b(star fmt(a3)) se(par fmt(a3))) ///
						starlevels(* 0.10 ** 0.05 *** .01) ///
						stats(r2 N N_cluster `estoutstats', fmt(3 0 0 `estoutfmt') ///
								labels("\(R^2\)" Observations Clusters "`estoutlabels'" )) ///
						numbers noomitted nobaselevels ///
						mlabels(none) ///
						collabels(none) ///
						indicate(`r(indicate_fe)') ///
						keep( `estoutkeep' ) 


		} // Loop over regression outcomes. 

	} // Loop over 4 and 5-digit datasets. 

} // Loop over pre-post or event study.

