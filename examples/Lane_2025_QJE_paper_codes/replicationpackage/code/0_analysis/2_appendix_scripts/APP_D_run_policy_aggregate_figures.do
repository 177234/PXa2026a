*------------------------------------------------------------------------------*
* What this does:	
*   Generates the main analysis for binscatter corresponding to policy regressions.
*
*   NOTE: This does not take advantage of the pure binscatter 
*   feature of taking averages. Data are already averaged. 
*   Using binscatter to quickly generate plots -> plot data for use in R.
*	
* Outputs: 
*   Binscatter data to reg directory, to plot with R. 
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// Load and prepare the datasets for each chunk.
capture program drop prep_data
program define prep_data
	args filenameargument 
	use "`filenameargument'", clear 
	estimates clear
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*
set graphics off
local mms_input_file "./data/input/agg_policyinput.dta"
local trade_input_file "./data/input/agg_policytrade.dta"

*------------------------------------------------------------------------------*
* 1. Generate graphs.
*------------------------------------------------------------------------------*

* A. Investment. 

* Load and make binscatter.
prep_data "`mms_input_file'"
local invest_binfile "./data/intermediate_datasets/invest_binscatter"
binscatter inv_tot year , by(hci) line(connect) ///
							savedata("`invest_binfile'") replace

* Clean up the dataset.
insheet using "`invest_binfile'.csv", clear

* Clean year.
rename year_by1 year 
drop year_by2

* Clear variable
rename *_by1 value0
rename *_by2 value1

* Make the gen label
gen variable = "inv_tot"

* Reshape...
reshape long value, i(variable year) j(hci)
duplicates drop 

* Save things.
tempfile file1
save "`file1'"


* B. Material Costs. 

* Load and make binscatter.
prep_data "`mms_input_file'"
local costs_binfile "./data/intermediate_datasets/costs_binscatter"
quietly: binscatter costs year , by(hci) line(connect) ///
							savedata("`costs_binfile'") replace

* Clean up the dataset.
insheet using "`costs_binfile'.csv", clear

* Clean year.
rename year_by1 year 
drop year_by2

* Clear variable
rename *_by1 value0
rename *_by2 value1

* Make the gen label
gen variable = "costs"

* Reshape...
reshape long value, i(variable year) j(hci)
duplicates drop 

* Save things.
tempfile file2
save "`file2'"


* C. QR. 

* Load and make binscatter.
prep_data "`trade_input_file'"
local qr_binfile "./data/intermediate_datasets/qr_binscatter"
quietly: binscatter qr_wt year , by(hci) line(connect) ///
							savedata("`qr_binfile'") replace

* Clean up the dataset.
insheet using "`qr_binfile'.csv", clear

* Clean year.
rename year_by1 year 
drop year_by2

* Clear variable
rename *_by1 value0
rename *_by2 value1

* Make the gen label
gen variable = "qr"

* Reshape...
reshape long value, i(variable year) j(hci)
duplicates drop 

* Save things.
tempfile file3
save "`file3'"


* D. Tariffs. 

* Load and make binscatter.
prep_data "`trade_input_file'"
rename tariff_wt tariff // For backwards compatibility. 
local tariff_binfile "./data/intermediate_datasets/tariff_binscatter"
quietly: binscatter tariff year , by(hci) line(connect) ///
							savedata("`tariff_binfile'") replace

* Clean up the dataset.
insheet using "`tariff_binfile'.csv", clear

* Clean year.
rename year_by1 year 
drop year_by2

* Clear variable
rename *_by1 value0
rename *_by2 value1

* Make the gen label
gen variable = "tariff"

* Reshape...
reshape long value, i(variable year) j(hci)
duplicates drop 

* Save things.
tempfile file4
save "`file4'"

*------------------------------------------------------------------------------*
* 2. Cleanup output files for the BINSCATTER output.
*------------------------------------------------------------------------------*

* Append the files above; file 5 in memory.
append using "`file4'"
append using "`file3'"
append using "`file2'"
append using "`file1'"

* Clean numerics for axes
replace value = value/100 if ///
			variable == "inv_tot" | variable == "invent_tot" | variable == "costs"
 
replace value = round( value )  if ///
			variable == "inv_tot" | variable == "invent_tot" | variable == "tariff" | variable == "costs"

* Save, return to baseline graphics.
sort variable year hci 
local binfile "./data/intermediate_datasets/investment_binscatter.csv"
outsheet using "`binfile'", replace 
set graphics on
