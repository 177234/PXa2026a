*------------------------------------------------------------------------------*
* NOTES
*------------------------------------------------------------------------------*
* + What this does:
* 	Unido robustness analysis. Only supplemental. UNIDO data is patchy.
*
* + Inputs: 
* 		- /data/input/unido_robustness_dataset.dta
*
* + Outputs: 
* 	did_largerolling_unido_all_results.csv
*------------------------------------------------------------------------------*

capture program drop export_reg_results
program define export_reg_results, rclass
	args tmpfile outputfilenameprefix
	use "`tmpfile'", clear
	keep if regexm( command, "^reg" ) == 1 & ///
			( regexm( var, "^1.hci#19[0-9][0-9].year#1.korea$" ) == 1 | ///
			  regexm( var, "^1o.hci#19[0-9][0-9]b.year#1o.korea$" ) == 1 )

	outsheet using  "./data/included_datasets/`outputfilenameprefix'_all_results.csv", ///
			comma replace
	capture: tempfile drop tmpfile
	tempfile tmpfile
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* I. - RUN UNIDO REGRESSIONS
*------------------------------------------------------------------------------*

* A. Setup before regression.
* NOTE: Source file is not included in the replication package.
local inputfile "./data/input/supp/unido_robustness_dataset.dta"
use "`inputfile'", clear
capture: tempfile drop tmpfile
tempfile tmpfile

* B. Setup regression parameters.
local outputfilenameprefix did_largerolling_unido
local outcomevariablelist l_workers l_grossout l_valueadded l_y_n
local replace "replace"

* C. Loop through regression parameters. 
foreach variable of local outcomevariablelist {
	local modelnumber = 1
	reghdfe `variable' i.hci##ib(1972).year##i.korea , ///
				absorb( i.id#i.year i.industry#i.year i.id#i.industry ) ///
				vce(cluster id industry)
	regsave using "`tmpfile'", ci ///
		addlabel(outcome,`variable',fixedeffects,"`fixedeffects'",command,`e(cmd)') `replace'
	local modelnumber = `modelnumber' + 1
	local replace "append"

} // Loop over outcomes.

* D. Save regression output.
export_reg_results `tmpfile' `outputfilenameprefix'
