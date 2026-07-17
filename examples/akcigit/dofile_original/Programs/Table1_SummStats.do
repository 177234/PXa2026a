cap log close
file close _all
set more off
program drop _all

** Table1_SummStats.do
** Makes table of summary statistics as in Table I. The formatting of the table
** in the paper is manually altered slightly to be easier to read (e.g. table 
** section headers are added)

** FIRST SET UP A GLOBAL POINTING TO THE DIRECTORY IN WHICH THE REPLICATION PACKET IS STORED
** Only need to do this if running this code on its own rather than through 0_main.do
*global projdir "<REPLICATION PATH>"

log using "$projdir/Logs/SummaryStatistics.log", replace

cap mkdir "$projdir/Results"
cap mkdir "$projdir/Results/Tables"

program main
	* Generate dataset of state summary statistics
	state_summstats
	tempfile statestats
	compress
	save `statestats', replace
	
	* Generate dataset of micro summ stats
	micro_summstats
	
	* Append state summ stats
	append using `statestats'
	
	* Generate order of rows
	order_data
	
	* Label variables
	label_variables
	
	* Convert dataset into a latex table
	make_data_table using "$projdir/Results/Tables/Table1.tex", replace labels numbers fmt(%6.2f)
end

program state_summstats
	** State summary statistics
	use "$projdir/Data/state_data" if inrange(year,1940,1999) & !inlist(stateabbr,"LA","AK","HI","PR",""), clear
	
	
	** Generate additional variables
	gen twentyyear = 20*floor(year/20) - 1900
	
	foreach var in mtr50 mtr90 mtrs50 mtrs90 top_corp top_corp_state {
		replace `var' = `var'/100
		}
	
	gen num_patents = exp(lnpat)
	gen num_inventors = exp(ln_inv)
	gen num_citations = exp(lncit)
	
	** Define local of variables to summarize
	local vars num_patents num_inventors num_citations share_assigned ///
			   mtr90 mtrs90 mtr50 mtrs50 progressivity ///
			   top_corp top_corp_state rd_credit
	des `vars'
	
	** Collapse data
	tempfile means
	tempfile sds
	xcollapse `vars' (count) N = statenum, saving(`means', replace)
	xcollapse (sd) `vars', saving(`sds', replace)
	collapse `vars'  (count) N = statenum, by(twentyyear)
	tostring twentyyear, replace
	
	append using `means'
	replace twentyyear = "Mean" if twentyyear == ""
	append using `sds'
	replace twentyyear = "SD" if twentyyear == ""
	foreach var of varlist `vars' N {
		rename `var' v`var'
		}
		
	* Reshape data
	reshape long v, i(twentyyear) j(variable) string
	reshape wide v, i(variable) j(twentyyear) string
	
	* Label variables
	label var v40 "1940-59"
	label var v60 "1960-79"
	label var v80 "1980-99"
	label var vMean "Mean"
	label var vSD "S.D.
	order variable vMean vSD v40 v60 v80
	
	foreach var in vMean vSD v40 v60 v80 {
		replace `var' = `var'/1000 if inlist(variable,"num_patents","num_citations","num_inventors")
		}
		
	format vMean-v80 %6.2f
end

program micro_summstats
	use "$projdir/Data/micro_reg_data" if inrange(year,1940,1999) & !inlist(stateabbr,"LA","AK","HI","PR",""), clear
	
	* Put tax rates on 0-1 scale
	foreach var of varlist mtr50_lag3 mtr90_lag3 top_corp_lag3 {
		replace `var' = `var'/100
		}
	
	** Generate additional variables
	gen twentyyear = 20*floor(year/20) - 1900
	
	bysort inv_id (year): egen corp_inventor = max(has_corp_pat)
	gen byte home_state_inventor = stateabbr == home_stateabbr
	
	gen byte high = L.inv_qual1_top10_c == 1
	gen eff_tax = mtr90_lag3*high + mtr50_lag3*(1-high)
	
	gen byte ones = 1
	
	
	** Define local of variables to summarize
	local vars numpat has_pat3yr numcit has10cit_3yr eff_tax top_corp_lag3 home_state_inventor corp_inventor
	des `vars'
	
	** Collapse data
	tempfile means
	tempfile sds
	tempfile patweights
	tempfile patweights_twentyyear
	tempfile citweights
	tempfile citweights_twentyyear
	xcollapse `vars' (count) N = inv_id, by(ones) saving(`means', replace)
	xcollapse corp_patents = corp_inventor home_state_pat = home_state_inventor [aw=numpat], by(ones) saving(`patweights', replace)
	xcollapse corp_cits = corp_inventor home_state_cit = home_state_inventor [aw=numcit], by(ones) saving(`citweights', replace)
	xcollapse (sd) `vars', saving(`sds', replace)
	xcollapse corp_patents = corp_inventor home_state_pat = home_state_inventor [aw=numpat] if year != 2000, by(twentyyear) saving(`patweights_twentyyear', replace)
	xcollapse corp_cits = corp_inventor home_state_cit = home_state_inventor [aw=numcit] if year != 2000, by(twentyyear) saving(`citweights_twentyyear', replace)
	collapse `vars'  (count) N = inv_id if year != 2000, by(twentyyear)
	merge 1:1 twentyyear using `patweights_twentyyear', nogen update
	merge 1:1 twentyyear using `citweights_twentyyear', nogen update
	tostring twentyyear, replace
	
	append using `means'
	merge m:1 ones using `patweights', nogen update
	merge m:1 ones using `citweights', nogen update
	drop ones
	replace twentyyear = "Mean" if twentyyear == ""
	append using `sds'
	replace twentyyear = "SD" if twentyyear == ""
	foreach var of varlist `vars' corp_patents home_state_pat corp_cits home_state_cit N {
		rename `var' v`var'
		}
		
	* Reshape data
	reshape long v, i(twentyyear) j(variable) string
	reshape wide v, i(variable) j(twentyyear) string
	
	* Label variables
	label var v40 "1940-59"
	label var v60 "1960-79"
	label var v80 "1980-99"
	label var vMean "Mean"
	label var vSD "S.D.
	order variable vMean vSD v40 v60 v80
	
	foreach var of varlist vMean-v80 {
		replace `var' = `var'/1000000 if variable == "N"
		}
	replace variable = "N (millions)" if variable == "N"
	
	format vMean-v80 %6.3f
end

program order_data
	// Inventor-level data: outcomes
	gen order = 1 if variable == "numpat"
	replace order = 2 if variable == "has_pat3yr"
	replace order = 3 if variable == "numcit"
	replace order = 4 if variable == "has10cit_3yr"
	
	// Inventor-level data: Taxes
	replace order = 5 if variable == "eff_tax"
	replace order = 6 if variable == "top_corp_lag3"
	replace order = 7 if variable == "N (millions)"
	
	// State-level data: unlogged core outcomes
	replace order = 8 if variable == "num_patents"
	replace order = 9 if variable == "num_inventors"
	replace order = 10 if variable == "num_citations"
	replace order = 11 if variable == "share_assigned"
	
	// State-level data: Taxes
	replace order = 12 if variable == "mtr90"
	replace order = 13 if variable == "mtrs90"
	replace order = 14 if variable == "mtr50"
	replace order = 15 if variable == "mtrs50"
	replace order = 16 if variable == "progressivity"
	replace order = 17 if variable == "top_corp"
	replace order = 18 if variable == "top_corp_state"
	replace order = 19 if variable == "rd_credit"
	replace order = 20 if variable == "N"
	
	// Sample composition
	replace order = 21 if variable == "corp_patents"
	replace order = 22 if variable == "home_state_pat"
	replace order = 23 if variable == "corp_cits"
	replace order = 24 if variable == "home_state_cit"
	replace order = 25 if variable == "corp_inventor"
	replace order = 26 if variable == "home_state_inventor"
	
	* Sort the table to have the right row order
	sort order
	drop order
end

program label_variables
	** Micro variables
	replace variable = "\# annual patents" if variable == "numpat"
	replace variable = "Pr\{Has patent in 3 years\}" if variable == "has_pat3yr"
	replace variable = "\# annual citations" if variable == "numcit"
	replace variable = "Pr\{Has 10+ citations in 3 years\}" if variable == "has10cit_3yr"
	
	replace variable = "Effective marginal tax rate" if variable == "eff_tax"
	replace variable = "Top corporate MTR" if variable == "top_corp_lag3"

	* State Variables
	replace variable = "\# Patents (000s)" if variable == "num_patents"
	replace variable = "\# Inventors (000s)" if variable == "num_inventors"
	replace variable = "\# Citations (000s)" if variable == "num_citations"
	replace variable = "Share Patents Assigned to Corporations" if variable == "share_assigned"
	
	replace variable = "90$^{th}$ Percentile Income MTR" if variable == "mtr90"
	replace variable = "90$^{th}$ Percentile Income State MTR" if variable == "mtrs90"
	replace variable = "Median Income MTR" if variable == "mtr50"
	replace variable = "Median Income State MTR" if variable == "mtrs50"
	replace variable = "Ratio of 90$^{th}$ to Median Income State MTR" if variable == "progressivity"
	replace variable = "Top Corporate MTR" if variable == "top_corp"
	replace variable = "Top State Corporate MTR" if variable == "top_corp_state"
	replace variable = "R\&D Tax Credit (percentage points)" if variable == "rd_credit"
	replace variable = "Observations" if variable == "N"
	
	* Composition
	replace variable = "\% Corporate Inventor" if variable == "corp_inventor"
	replace variable = "\% Home-State Inventor" if variable == "home_state_inventor"
	replace variable = "\% Corporate Patent" if variable == "corp_patents"
	replace variable = "\% Home-State Patent" if variable == "home_state_pat"
	replace variable = "\% Corporate Citations" if variable == "corp_cits"
	replace variable = "\% Home-State Citations" if variable == "home_state_cit"
end

program define make_data_table
	syntax using, [replace labels NONumbers numbers table center fmt(string asis) ///
					title(string asis) tablabel(string asis) headers(string asis) footnote(string asis)]
	
	
	* Open table file
	file open mytab `using', write text `replace'
	
	* Initialize table
	if "`table'" != "" {
		file write mytab "\begin{table}" _n
		}
	if "`center'" != "" {
		file write mytab "\begin{center}" _n
		}
	* Write title if specified
	if "`title'" != "" {
		file write mytab "\caption{`title'}" _n
		}
		
	* Add table latex label if specified
	if "`tablabel'" != "" {
		file write mytab "\label{`label'} _n
		}
		
	* Initialize tabular
	local numvar = c(k)
	file write mytab "\begin{tabular}{"
	forvalues j = 1/`numvar' {
		file write mytab "l"
		}
	file write mytab "}" _n "\hline\hline" _n
	
	** Head columns with variable labels
	if "`labels'" != "" {
		local i = 1
		foreach var of varlist * {
			local lab: var label `var'
			if `i' == 1 {
				file write mytab "`lab'"
				}
			else {
				file write mytab "& `lab'"
				}
			local i = `i'+1
			}
		file write mytab "\\" _n
		}
	
	** Add a header if specified
	if "`header'" != "" {
		file write mytab `header' _n
		}
		
	** Add column numbers
	if "`numbers'" != "" | "`nonumbers'" == "" {
		local i = 1
		foreach var of varlist * {
			if `i' == 1 {
				file write mytab "(`i')"
				}
			else {
				file write mytab "& (`i')"
				}
			local i = `i'+1
			}
		file write mytab "\\" _n
		}
		
	** Add some horizontal lines
	file write mytab "\hline" _n
		
	** Finally write the table: loop through each observation
	local numobs = _N
	forvalues n = 1/`numobs' {
		* Next loop through each variable
		local i = 1
		foreach var of varlist * {
			* Write the value of the variable in the nth observation
			local value = `var'[`n']
			cap di `value'/10
			if "`fmt'" != "" & _rc == 0 {
				local value: di `fmt' `value'
				}
			if `i' == 1 {
				file write mytab "`value'"
				}
			else {
				file write mytab "& `value'"
				}			
			local i = `i'+1
			}
		file write mytab " \\" _n
		}
	
	file write mytab "\hline\hline"
	file write mytab "\end{tabular}" _n
	
	if "`center'" != "" {
		file write mytab "\end{center}" _n
		}
		
	if "`footnote'" != "" {
		file write mytab "\noindent\footnotesize `footnote'" _n
		}
	
	if "`table'" != "" {
		file write mytab "\end{table}" _n
		}
	file close mytab
	
end

main

log close
