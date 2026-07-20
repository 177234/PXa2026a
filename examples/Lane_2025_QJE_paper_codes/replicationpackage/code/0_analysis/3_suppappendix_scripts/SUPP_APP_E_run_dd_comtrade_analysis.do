*------------------------------------------------------------------------------*
* What this does:
*   WORLD TRADE - SUPPLEMENTAL DD TRADE REGRESSIONS. 
*
* Inputs: "comtrade_worldsitc_panel_cleaned4reg_4digit.dta"
*
* Outputs: 
*   - did_largerolling_worldtrade_supp_ppml_rca_results_estout.csv
*   - did_largerolling_worldtrade_supp_ppml_rca_all_results.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

capture program drop prep_data
program define prep_data
	args filenameargument 
	use "`filenameargument'", clear 
	compress
	estimates clear
	capture: estfe . output_*, restore
	capture: drop post
	gen post = 0 
	replace post = 1 if year >= 1973
	keep if hci == 1

end

capture program drop export_reg_results
program define export_reg_results, rclass

	args tmpfile regressiondir outputfilenameprefix estoutoptions
	

	* 1. Save ESTOUT regression table: CSV output.
	estout output_* ///
		using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
			replace cells(b(star fmt(3)) se(par fmt(3))) ///
					starlevels(* 0.10 ** 0.05 *** .01) ///
					stats(rsq N twowayvce Fs ps, fmt(3 0 %9.0g %9.3f %9.3f) ///
						labels("\(R^2\)" Observations "Clusters (Product)" "Joint Test of Pre-Trend (F-Test)" "Joint Test of Pre-Trend (p-values)")) ///
					numbers noomitted nobaselevels ///
					collabels(none) ///
					keep( `estoutoptions' )

	* 2. Regsave
	use "`tmpfile'", clear
	keep if regexm(var,"^1[0-9][0-9][0-9].year.*korea$" ) == 1
	outsheet using  "./data/intermediate_datasets/`outputfilenameprefix'_all_results.csv", ///
			comma replace

	capture: tempfile drop tmpfile
	tempfile tmpfile
end

capture program drop make_pretest_vars
program define make_pretest_vars, rclass
	args regressorlistforloop outcomeargument
	levelsof year if year < 1972 & !missing( `outcomeargument' ) , local(yearlist) clean
	local listofregressorstotest

	foreach yearstring of local yearlist {
		foreach variablestring of local regressorlistforloop {
			local listofregressorstotest `variablestring'#`yearstring'.year `listofregressorstotest'
		} 
	}
	return local result `"`listofregressorstotest'"'	
end

*------------------------------------------------------------------------------*
* 1. - FLEXIBLE REGRESSIONS - PPMLHDFE 
*------------------------------------------------------------------------------*
local inputfile "./data/input/comtrade_worldsitc_panel_cleaned4reg_4digit.dta"

*------------------------------------------------------------------------------*
* A. SETUP REGRESSION PARAMETERS.
*------------------------------------------------------------------------------*
prep_data "`inputfile'"
local outcomevariablelist rca_cdk rca_dummy rca_core h_rca_core
local outputfilenameprefix did_largerolling_worldtrade_supp_ppml_rca
local estoutkeep_rolling "1*year*1*korea"


*------------------------------------------------------------------------------*
* B. - LOOP THROUGH REGRESSION PARAMETERS. 
*------------------------------------------------------------------------------*
local replace "replace"
capture: tempfile drop tmpfile
tempfile tmpfile

* Loop over outcomes.
foreach variable of local outcomevariablelist {
	local modelnumber = 1

	* Loop over each FE-type:
	foreach fixedeffects in "" "reportercode" "i.reportercode#i.code"  {
		* Execute regression.
		if regexm("`variable'", "dummy|cdk|h_") {
			reghdfe `variable' ib(1972).year##i.korea, ///
				absorb( `fixedeffects' ) ///
				vce(cluster reportercode)

			local adjustedr = `e(r2_a)'			
		}
		else {
			ppmlhdfe `variable' ib(1972).year##i.korea, ///
				absorb( `fixedeffects' ) ///
				vce(cluster reportercode)
			local adjustedr = `e(r2_p)'
		}

		* Save and post-reg.
		estimates store output_`variable'_`modelnumber'
		estadd local twowayvce "`e(N_clust1)'"
		estadd scalar rsq = `adjustedr'
		
		if regexm("`variable'", "dummy|cdk|h_") {
			make_pretest_vars "1.korea" "`variable'"
			test `r(result)'
			local pre_ftest = `r(F)'
			local pre_testprob = `r(p)'
			estadd scalar Fs r(F)
			estadd scalar ps r(p)
		}
		else {

			make_pretest_vars "1.korea" "`variable'"

			test `r(result)'
			local pre_ftest = `r(chi2)'
			local pre_testprob = `r(p)'
			estadd scalar Fs r(chi2)
			estadd scalar ps r(p)

		}
		regsave using "`tmpfile'", ci ///
			addlabel(outcome,`variable', fixedeffects,"`fixedeffects'",command,`e(cmd)') `replace'

		local modelnumber = `modelnumber' + 1
		local replace "append"
	} // Loop over fixed effects
} // Loop over outcomes. 

*------------------------------------------------------------------------------*
* C. - SAVE REGRESSION OUTPUT: ESTOUT AND REGSAVE DATASET. 
*------------------------------------------------------------------------------*
export_reg_results `tmpfile' `"./data/intermediate_datasets"' `outputfilenameprefix' `estoutkeep_rolling'
