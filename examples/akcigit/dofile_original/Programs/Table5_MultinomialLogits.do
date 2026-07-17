cap log close
clear
set more off, permanent
program drop _all

** Table5_MultinomialLogits.do
** Runs multinomial logit location choice regressions, included in Table V and bottom of Table VI.

** FIRST SET UP A GLOBAL POINTING TO THE DIRECTORY IN WHICH THE REPLICATION PACKET IS STORED
** Only need to do this if running this code on its own rather than through 0_main.do
*global projdir "<REPLICATION PATH>"

log using "$projdir/Logs/multinomial_logits.log", replace
			
set matsize 1000

program main
			
	run_mlogits, suffix(ever_prog)
	
	run_mlogits, suffix(progspells) if(if progspell_lag1 == 1)
			
end

program define get_elasticities
	args  var
	preserve
	quietly{
		* Predict choice probabilities
		cap drop proba
		predict proba, pr
		
		* Calculate total number of people in home and foreign states
		summ proba
		local sum_all=`r(sum)'
		su proba if home_state_flag==1
		local sum_home=`r(sum)'
		su proba if home_state_flag==0
		local sum_nothome=`r(sum)'
		
		* Initialize elasticity locals
		local elast=0
		local elast_se=0
		local elast_home=0
		local elast_home_se=0
		local elast_nothome=0
		local elast_nothome_se=0
		
		* Loop through each state, augment elasticity number by looking at how
		* choice probability of a particular state changes as we change its tax
		* rate, and then add this change in probability to the existing
		* elasticity local weighted by the share of people in that state
		levelsof state_choice_set if e(sample), local(states)
		foreach state in `states' {
			* Overall elasticity calculation
			quietly summ proba [w=proba] if state_choice_set=="`state'"
			local elast_`state'=_b[`var']*(1-`r(mean)')
			local elast_se`state'=_se[`var']*(1-`r(mean)')
			quietly summ proba if state_choice_set=="`state'"
			local w_`state'=`r(sum)' /`sum_all'

			local elast=`elast'+`w_`state''*`elast_`state''
			local elast_se=`elast_se'+`w_`state''*`elast_se`state''
			
			* Elasticity calculation for home state individuals
			quietly summ proba [w=proba] if state_choice_set=="`state'" & home_state_flag == 1
			local elast_h`state'=_b[`var']*(1-`r(mean)')
			local elast_h_se`state'=_se[`var']*(1-`r(mean)')
			quietly summ proba if state_choice_set=="`state'" & home_state_flag == 1
			local w_h`state'=`r(sum)' /`sum_home'

			local elast_home=`elast_home'+`w_h`state''*`elast_h`state''
			local elast_home_se=`elast_home_se'+`w_h`state''*`elast_h_se`state''
			
			* Elasticity calculation for non-home state individuals
			quietly summ proba [w=proba] if state_choice_set=="`state'" & home_state_flag == 0
			local elast_nh`state'=_b[`var']*(1-`r(mean)')
			local elast_nh_se`state'=_se[`var']*(1-`r(mean)')
			quietly summ proba if state_choice_set=="`state'" & home_state_flag == 0
			local w_nh`state'=`r(sum)' /`sum_nothome'

			local elast_nothome=`elast_nothome'+`w_nh`state''*`elast_nh`state''
			local elast_nothome_se=`elast_nothome_se'+`w_nh`state''*`elast_nh_se`state''
			}
		}

	display "epsilon= " `elast' "  se = " `elast_se'
	display "epsilon: home states = " `elast_home' "  se: home states = " `elast_home_se'
	display "epsilon: not-home states = " `elast_nothome' "  se: not home states = " `elast_nothome_se'
end

program run_mlogits
syntax, [if(string asis) suffix(string asis)]
	// Controls to include in all regressions
	local controls home_state_flag agglomeration 
	local controls_interact c.home_state_flag#c.high 
	local base_controls home_state_flag

	// Controls to include that vary at the inventor-year level
	local case_controls tenure tenure2

	local clustvar year // Level at which SEs are clustered

	// Additional variables to bring into datasets
	local additional_vars `clustvar' high multistate_assignee

	use "$Data/MLogit_Data" `if', clear 
	
	* Interact taxes with contemporaneous corporate inventor flags
	gen top_corp_ret_corp = top_corp_retention*has_corp_pat
	gen top_corp_ret_noncorp = top_corp_retention*(1-has_corp_pat)
	gen log_ret_rate_corp = log_retention_rate*has_corp_pat
	gen log_ret_rate_noncorp = log_retention_rate*(1-has_corp_pat)
	
	summ agglomeration
	replace agglomeration = (agglomeration - r(mean))/r(sd)

	fvset base 0 asgn_haspat high


	** Run state + year FE regressions (column 1 of Table V)
	if "`suffix'" == "ever_prog" {
				
		* Including base index control
		eststo plusFE_rr: asclogit  choice  log_retention_rate  `controls' ///
				`controls_interact' c.agglomeration#c.high top_corp_retention rd_credit_lag1 gdppc_lag1 popdens_lag1 base_index_lag1, ///
				case(case_id) alternatives(state_choice_set) ///
				casev(`case_controls') vce(cluster `clustvar')
		*estadd margins, eydx(log_retention_rate) atmeans
		di "Elasticities for State + Year FE with Base Controls "
		get_elasticities log_retention_rate
		get_elasticities top_corp_retention
		
		* Corporate and personal tax rate having separate effect for corporate and non-corporate inventors, contemporaneous corporate inventor definiion
		eststo corp_noncorp_rr: asclogit  choice  log_ret_rate_corp log_ret_rate_noncorp  top_corp_ret_corp top_corp_ret_noncorp `controls' ///
				`controls_interact' c.agglomeration#c.high ///
				rd_credit_lag1 gdppc_lag1 popdens_lag1 base_index_lag1, ///
				case(case_id) alternatives(state_choice_set) ///
				casev(`case_controls' has_corp_pat) vce(cluster `clustvar')
		*estadd margins, eydx(log_retention_rate) atmeans
		di "Elasticities for State + Year FE for corporate vs non-corporate effects separately"
		di "Personal tax: Corp"
		get_elasticities log_ret_rate_corp
		di "Personal tax: Non-Corp"
		get_elasticities log_ret_rate_noncorp
		di "Corporate tax: Corp"
		get_elasticities top_corp_ret_corp
		di "Corporate tax: Non-Corp"
		get_elasticities top_corp_ret_noncorp
		
		estwrite * using "$projdir/Results/Regressions/sters/mlogits`suffix'.sters", append
		
		}
		
	* Run with state x year FE
	else {		
				
		** BASELINE REGRESSIONS (Column 2 of Table V)
		eststo timesFE_rr: asclogit  choice  log_retention_rate  `controls' `controls_interact' c.agglomeration#c.high, ///
				case(case_id) alternatives(state_choice_set) ///
				casev(`case_controls' i.year) vce(cluster `clustvar')

		di "Elasticities for State x Year FE Baseline"
		get_elasticities log_retention_rate
		
		** Run with agglomeration interaction (Column 3 of Table V)
		eststo agglomint_rr: asclogit  choice  log_retention_rate  ///
				c.log_retention_rate#c.agglomeration ///
				c.log_retention_rate#c.lnpat_statewide_lag1 ///
				`controls' `controls_interact', ///
				case(case_id) alternatives(state_choice_set) ///
				casev(`case_controls' i.year) vce(cluster `clustvar')
		di "Elasticities for State x Year FE with agglomeration interaction"
		get_elasticities log_retention_rate
		
		** Run with assignee has at least one pat in state interaction (Column 4 of Table V)
		eststo asgnhasint_rr: asclogit  choice  log_retention_rate  ///
				c.log_retention_rate#c.asgn_haspat c.agglomeration#c.high asgn_haspat ///
				`controls' `controls_interact', ///
				case(case_id) alternatives(state_choice_set) ///
				casev(`case_controls' i.year) vce(cluster `clustvar')
		di "Elasticities for State x Year FE with assignee having patent interaction"
		get_elasticities log_retention_rate
		
		* Run with corporate inventor interaction (Final row of Table VI)
		eststo corp_int_rr: eststo atr_full_corpint: asclogit  choice  log_ret_rate_corp log_ret_rate_noncorp  ///
				c.agglomeration#c.high ///
				`controls' `controls_interact', ///
				case(case_id) alternatives(state_choice_set) ///
				casev(`case_controls' i.year) vce(cluster `clustvar')
		di "Elasticities for State x Year FE for corporate vs non-corporate effects separately"
		di "Personal tax: Corp"
		get_elasticities log_ret_rate_corp
		di "Personal tax: Non-Corp"
		get_elasticities log_ret_rate_noncorp
		}
		
		
	estwrite * using "$projdir/Results/Regressions/sters/mlogits`suffix'.sters", append
	
end

main

log close
