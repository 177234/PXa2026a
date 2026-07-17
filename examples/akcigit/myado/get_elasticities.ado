

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