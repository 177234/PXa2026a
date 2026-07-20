*------------------------------------------------------------------------------*
* NOTES
*------------------------------------------------------------------------------*
* + What this does:
* 	Generates supplemental analysis for investment. Disaggregated investment
* 	data is incomplete.
*
* + Inputs: 
* 	mms_supp_inv_5digit.dta
*
* + Outputs: 
* 	did_largerolling_mainpolicydisaggregatedcapital.csv
* 	did_largerolling_mainpolicydisaggregatedcapital_results_papermain.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*
capture program drop prep_data
program define prep_data
	args filenameargument 
	use "`filenameargument'", clear 
	estimates clear
	capture: estfe . output_*, clear
	capture: drop post
	gen post = 0 
	replace post = 1 if year >= 1973
end

*------------------------------------------------------------------------------*
* 1. - REGRESSION LOOP
*------------------------------------------------------------------------------*

* A. Setup arguments.
local inputfile "./data/input/supp/mms_supp_inv.dta"
local outputfilenameprefix did_largerolling_policydisaggregatedcapital
local outcomevariablelist l_inv_eq l_inv_v_t l_inv_b_s l_inv_land

* B. Prepare regression.
prep_data "`inputfile'"
capture: tempfile drop tmpfile
tempfile tmpfile
local replace "replace"

* C. Loop through regression parameters.
foreach variable of local outcomevariablelist {
	local modelnumber = 1

	* Execute regression.
	reghdfe `variable' i.hci##ib(1972).year , ///
			absorb( id year ) ///
		vce(cluster id )

	* Post-regression
	estimates store output_`variable'_`modelnumber'
	estadd scalar N_cluster = e( N_clust )
	estadd local id_fe Yes
	estadd local year_fe Yes

	regsave using "`tmpfile'", ci ///
		addlabel(outcome,`variable',fixedeffects,"id year",command,`e(cmd)') `replace'

	local modelnumber = `modelnumber' + 1
	local replace "append"
}

*------------------------------------------------------------------------------*
* 2. Save regression output: ESTOUT and results dataset.
*------------------------------------------------------------------------------*

* 1. Save ESTOUT regression table: CSV output.
estfe . output_*, labels(year "Year EF" id "Industry EF")
return list 
estout output_* ///
	using "./data/intermediate_datasets/`outputfilenameprefix'.csv" , ///
		replace ///
			cells(b(star fmt(3)) se(par fmt(3))) ///
			starlevels(* 0.10 ** 0.05 *** .01) ///
			stats(r2 N N_cluster, fmt(3 0 0) labels( "\(R^2\)" Observations Clusters )) ///
			numbers ///
			noomitted nobaselevels ///
			indicate( `r(indicate_fe)' ) ///
			mlabels(none) ///
			collabels(none) ///
			keep( 1*hci*year* )

* 2. Clean and save results dataset.
use "`tmpfile'", clear
local regex_list ///
    "^1[0-9][0-9][0-9]*.year" ///
    "^1[0-9][0-9][0-9].year" ///
    "1[0-9][0-9][0-9]o.year" ///
    "_cons" ///
    "^0b.hci" ///
    "#c.(h|l)_(c|avg|y)" ///
    "^1972b.year$" ///
    "^1o.hci$" ///
    "^o.hci" ///
	    "(c(o)?.*_0|o.[_aA-zZ]+_0)" ///
    "0b.post" ///
    "1o.post"
foreach re in `regex_list' {
    drop if regexm(var, `"`re'"') == 1 & regexm(command, "reg") == 1
}

* 3.Out and clean up.
capture drop if (regexm(var, "^1[0-9][0-9][0-9]*.year") == 1 & !regexm(var, "product") == 1 & regexm(command, "reg") == 1)
outsheet using ///
	"./data/intermediate_datasets/`outputfilenameprefix'_results_papermain.csv", ///
	comma replace
