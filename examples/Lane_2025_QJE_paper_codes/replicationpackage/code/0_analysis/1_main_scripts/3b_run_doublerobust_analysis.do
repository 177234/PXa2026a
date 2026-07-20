*------------------------------------------------------------------------------*
* What this does:
*
*   CSDID regressions.
*   NOTE: That observations are treated differently in CSDID than traditional.
*         Observations match the pre-period obs for CSDID. 
*
* Dependencies: Stata packages:
*   - ssc install csdid 
*   - ssc install drdid 
*   - ssc install ppmlhdfe
*   - ssc install regsave
*
* Inputs: 
*
*   "./data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta"
*   "./data/input/mms_merged_harmonized_panel_cleaned4reg_4digit.dta"
*	"./data/input/mms_policy_5digit.dta"
*   "./data/input/mms_policy_4digit.dta"
*
* Outputs:
*
*   - doublyrobust_all_results.csv
*   - doublyrobust_att.csv
*   
*   - doublyrobust_invest_all_results.csv
*   - doublyrobust_invest_att.csv
*   
*   - doublyrobust_trade_all_results.csv
*   - doublyrobust_trade_att.csv
*
*   * doublyrobust_invest_levels
*------------------------------------------------------------------------------*
set graphics off
*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// PROGRAM: prep_data
capture program drop prep_data
program define prep_data
	args filenameargument 
	use "`filenameargument'", clear 
	estimates clear
	capture: estfe . output_*, clear
	gen gvar = 0
	replace gvar = 1973 if hci == 1
	label var gvar "group variable"
	capture confirm variable code
	if _rc == 0 {
		order id year hci code year gvar
	}
	else {
		order id year hci year gvar
	}
end

// PROGRAM export_reg_results
capture program drop export_reg_results
program define export_reg_results, rclass
	args tmpfile regressiondir outputfilenameprefix
	use "`tmpfile'", clear
	
	* A. FIRST CLEAN REGSAVE FILE. 
	local regex_drop_list ///
			    "^0b.hci$" ///
			    "^1o.hci$" ///
			    "^1[0-9][0-9][0-9](o|b).year" ///
			    "^0b.hci" ///
			    "#(c|co).(l|h)_.*0$" ///
			    "^1o.hci#1972" ///
			    "^1o.hci$" ///
			    "^o.hci|o.hci$" ///
			    "_cons" ///
			    "^(1o|0b).*.post$"

	foreach stringtomatch in `regex_drop_list' {
	    capture drop if regexm(var, `"`stringtomatch'"') == 1 & ///
						regexm(command, "ppmlhdfe") == 1
	}
	capture replace var = "Post_avg" if regexm(var, "^1.hci#.*post") == 1 & regexm(command, "ppmlhdfe") == 1

	* B. SAVE EVENT STUDY OUTPUT. 
	replace var = regexr( var, "^T", "" ) if regexm( command, "csdid" ) == 1
	replace var = regexr( var, "^C", "" ) if regexm( command, "csdid" ) == 1

	* Make pre-post var.
	gen prepost = .
	replace prepost = 0 if regexm( var, "^m" ) == 1
	replace prepost = 1 if regexm( var, "^p" ) == 1

	* Clean up periods for CSDID
	replace var = regexr( var, "^m", "-" ) if regexm( command, "csdid" ) == 1
	replace var = regexr( var, "^p", "" ) if regexm( command, "csdid" ) == 1 

	* Clean and create year var. 
	capture: drop year
	gen year = "" 

	* For CSDID, get the time period (relative periods)
	replace year = regexs(1) if ///
						regexm( var, "([0-9\\-]+)" )==1 & ///
						( command == "csdid" )

	* Make for PPMLHD estimator, if used. (calendar dates)
	replace year = regexs(1) if ///
						regexm( var, "(1[0-9][0-9][0-9])" )==1 & ///
						( command == "ppmlhdfe" )

	* Turn numeric
	destring year, replace 

	* Also adjust prepost indicator for PPMLHDFE
	replace prepost = 1 if year >= 1972 & ///
						( command == "ppmlhdfe" )
	replace prepost = 0 if year < 1972 & ///
						( command == "ppmlhdfe" )

	* Make pre-years, deal with omitted var for CSDID
	replace year = 1973 + year if year >= 0 & ///
						( command == "csdid" )
	replace year = 1972 + year if year < 0 & ///
						( command == "csdid" )


	* Generate within regress_ID number.
	bysort regress_id (year): gen est_id = _n

	* Add omitted year indicator for easier plotting in R.
	expand 2 if year == 1971,  generate(omitted) 
	replace year = 1972 if year == 1971 & omitted == 1
	sort regress_id est_id year

	* Make obs 0 for these obs. 
	foreach variable in coef stderr ci_lower ci_upper {
		replace `variable' = 0 if year == 1972 & omitted == 1
	}
	replace var = "base" if year == 1972 & omitted == 1

	* Clean and save.
	drop omitted
	drop est_id
	order var year prepost coef stderr tstat pval ci_lower* ci_upper* 
	outsheet using  "./data/intermediate_datasets/`outputfilenameprefix'_all_results.csv", ///
			comma replace

	* C. Save ATT only dataset. 

	* Clean ATT specifics.
	keep if regexm( lower(var), "post.*avg" ) == 1
	keep var outcome coef stderr pval regress_id didtype dataset
	order regress_id var outcome coef stderr pval didtype dataset
	
	* Save ATT.
	outsheet using  "./data/intermediate_datasets/`outputfilenameprefix'_att.csv", ///
			comma replace

	capture: tempfile drop tmpfile
	tempfile tmpfile
end
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*
local dataset5 "./data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta"
local dataset4 "./data/input/mms_merged_harmonized_panel_cleaned4reg_4digit.dta"
local dataset5policy "./data/input/mms_policy_5digit.dta"
local dataset4policy "./data/input/mms_policy_4digit.dta"
local datasettrade "./data/input/comtrade_merged_harmonized_panel_cleaned4reg_4digit.dta"


*------------------------------------------------------------------------------*
* PART I. - MAIN INDUSTRIAL ANALYSIS
*------------------------------------------------------------------------------*

* i. SETUP.

* Regression parameters.
local outcomevariablelist l_ship l_valueadded l_grossoutput l_workers ///
							l_ppi l_y_n l_ship_sh l_lab_sh l_est 
local controlset l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0 
local outputfilenameprefix doublyrobust

* Regression setup.
capture: tempfile drop tmpfile
tempfile tmpfile
local replace "replace"
local modelnumber = 1

* iii. Execute regression loop.
foreach variable in `outcomevariablelist' {
	foreach dataset in dataset5 dataset4 {
		prep_data "``dataset''"
		
		* A. Run for DR and OLS
		foreach didtype in dr ols {

			* Execute the regressions (DR or OLS)
			if( regexm("`didtype'","ols") == 1 ){
				csdid `variable' `controlset', ///
					time(year) ivar(id) gvar(gvar) ///
					method(reg) agg(event) replace
			}
			else {
				csdid `variable' `controlset', ///
					time(year) ivar(id) gvar(gvar) ///
					method(dripw) wboot reps(10000) ///
					agg(event) replace	
			}

			* B. Add to regsave file.
			regsave using "`tmpfile'", ci tstat pval ///
				addlabel(outcome,`variable', controls,`controlset',command,`e(cmd)',didtype,`didtype',dataset,`dataset', regress_id, `modelnumber') `replace'
			local modelnumber = `modelnumber' + 1
			local replace "append"
		} // Loop over regression type: DRDID vs. OLS. 
	} // Loop over dataset 
} // Loop over outcomes

* Save regression output: regsave dataset.
export_reg_results `tmpfile' `"./data/intermediate_datasets"' `outputfilenameprefix' 


*------------------------------------------------------------------------------*
* II. INVESTMENT AND COST ANALYSIS
*------------------------------------------------------------------------------*

* i. Setup.

* Regression parameters.
local outcomevariablelist l_costs l_m_n l_inv_tot l_i_n
local controlset l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0 
local outputfilenameprefix doublyrobust_invest

* Regression setup.
capture: tempfile drop tmpfile
tempfile tmpfile
local replace "replace"
local modelnumber = 1

* ii. Execute regression loop.
foreach variable in `outcomevariablelist' {
	foreach dataset in dataset5policy dataset4policy {
		prep_data "``dataset''"
		foreach didtype in dr ols {

			* A. Execute the regression (DR or OLS)
			if( regexm("`didtype'","ols") == 1 ){					
					csdid `variable' `controlset', ///
						time(year) ivar(id) gvar(gvar) ///
						method(reg) agg(event) replace
			}
			else {
					csdid `variable' `controlset', ///
						time(year) ivar(id) gvar(gvar) ///
						method(dripw) wboot reps(10000) ///
						agg(event) replace			
			}

			* B. Add to regsave file.
			regsave using "`tmpfile'", ci tstat pval ///
				addlabel(outcome,`variable', controls,`controlset',command,`e(cmd)',didtype,`didtype',dataset,`dataset', regress_id, `modelnumber') `replace'
			local modelnumber = `modelnumber' + 1
			local replace "append"
		} // Loop over regression type: DRDID vs. OLS. 
	} // Loop over dataset 
} // Loop over outcomes

* Save regression output: regsave dataset.
export_reg_results `tmpfile' `"./data/intermediate_datasets"' `outputfilenameprefix' 


*------------------------------------------------------------------------------*
* 3. TRADE ANALYSIS
*------------------------------------------------------------------------------*

* i. Setup.

* Regression parameters.
local outcomevariablelist rca_core l_rca_core h_rca_core rca_cdk rca_dummy ///
							export_sh l_export_sh h_export_sh
local controlset l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0 
local outputfilenameprefix doublyrobust_trade

* Regression setup.
capture: tempfile drop tmpfile
tempfile tmpfile
local replace "replace"
local modelnumber = 1
local dataset tradedata // Backwards compatibility


* ii. Execute regression loop.
prep_data "`datasettrade'"

foreach variable in `outcomevariablelist' {
	foreach didtype in dr ols ppml {

		** a. Execute the regression (PPML, OLS, DR)
		if( regexm( "`didtype'" , "ppml" ) == 1 ){
			// NOTE: PPML requires manual interactions, clustering. 
			ppmlhdfe `variable' i.hci##i.post ///
				c.(`controlset')##i.year, ///
				absorb( id year ) vce(cluster id)
		}
		else if ( regexm("`didtype'","ols") == 1 ){	
			csdid `variable' `controlset', ///
				time(year) ivar(id) gvar(gvar) ///
				method(reg) agg(event) replace
		}		
		else {
			csdid `variable' `controlset', ///
				time(year) ivar(id) gvar(gvar) ///
				method(dripw) wboot reps(10000) ///
				agg(event) 
		}

		* b. Add to regsave file.
		regsave using "`tmpfile'", ci tstat pval ///
		addlabel(outcome,`variable', controls,`controlset',command,`e(cmd)',didtype,`didtype',dataset,`dataset', regress_id, `modelnumber') `replace'
		local modelnumber = `modelnumber' + 1
		local replace "append"
	} // Loop over regression type. 
} // Loop over outcomes

* Format and save results for use in R.
export_reg_results `tmpfile' `"./data/intermediate_datasets"' `outputfilenameprefix' 

set graphics on
