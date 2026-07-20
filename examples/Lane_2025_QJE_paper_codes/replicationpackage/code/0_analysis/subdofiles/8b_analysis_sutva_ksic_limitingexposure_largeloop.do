

/*

MAIN Do-file loop (MUST BE "INCLUDED")


NOTE: Main sub-do-file for linkage analysis. 


THIS DO FILE: This loop is more limited than the main linkage analysis. 

*/



* Toggle outside the loop. First time it is run.
local replace "replace"


* Start clean regression dump file2. Must be here.
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile



**** i. Loop over PRE-POST v. ROLLING REG. ****  
foreach didtype in prepost rolling {


	* Analysis name (for output file) estout and others.
	local analysis_name `namesuffix'_`didtype'


	*** ii. Loop over 4 and 5-digit data.
	foreach datatype in 4 5 {


		* Estout/regsave arguments: do for each DID-type.
		local estoutkeep "`estoutkeep_`didtype''"

		* This selects "TYPE" of DID.
		local didinteraction "`did_`didtype''"
		

		* Load and prepare 4 or 5-digit dataset:
		prep_data "`dataset`datatype''"

		* Make exposure measures using linkages. 
		makeexposureindicator


		*** iii. Loop over outcomes. 
		foreach outcome of local outcome_list {

			* Counter by outcomes.
			local modelnumber = 1


			*** iv. Loop over constraints.
			// Foreach constraint: first baseline regs, then limited to HCI plus less than median.
			foreach constraints in "" "if hci_io_lowuse_plus_hci == 1" "if hci_io_lowmake_plus_hci == 1" {


				*** a. RUN REGRESSION. ***

				reghdfe `outcome' `didinteraction'##i.hci `constraints', ///
							absorb( id year ) ///
						vce(cluster id) ///
						verbose(0) ///
						noconstant ///
						vsquish
						

				*** b. SAVE REGRESSION OUTPUT. ***

				* Save results to regsave table.
				regsave using "`temp_regressionfile'", pval ci ///
					addlabel( outcome , `outcome',  didtype, `didtype' , restrictions, `restrictiondummy', fixedeffects, "id year", command,`e(cmd)',datatype,`datatype', constraints, "`constraints'")  `replace'

				* Save regression table, model for estout.
				estimates store `outcome'_`modelnumber'

				* Add number of clusters.
				estadd scalar N_cluster = e(N_clust)


				*** c. MISC: MODEL ITERATION, ETC.

				* Model counter.
				local modelnumber = `modelnumber' + 1

				* Replacement switch for REGSAVE.
				local replace "append"


			} // Loop over constraints.


		*** v. SAVE REGRESSION OUTPUT: ESTOUT DATASET. ***

		
		estfe . `outcome'_*, labels(id "Industry Effects" year "Year Effects") 
		return list

		* Save estout regression table for each group of outcomes AND 4 versus 5-digit:
		estout `outcome'_* ///
			using "./data/intermediate_datasets/`analysis_name'_`outcome'_`datatype'estout.csv" , ///
				replace ///
				cells(b(star fmt(a3)) se(par fmt(a3))) ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(r2 N N_cluster Fs ps Fs2 ps2, fmt(3 0 0) labels("\(R^2\)" Observations Clusters)) ///
				numbers collabels(none) ///
				indicate(`r(indicate_fe)') ///
				keep( `estoutkeep' ) 


		} // Loop over outcomes.

	} // Loop over 4- or 5-digit datasets.

} // Loop over DID-type and regressor type.


