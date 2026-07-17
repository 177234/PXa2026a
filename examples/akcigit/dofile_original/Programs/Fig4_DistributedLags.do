cap log close
clear
set more off
program drop _all

* Fig4_DistributedLags.do
* Runs distributed lag regressions and makes plots in Figure IV.


** FIRST SET UP A GLOBAL POINTING TO THE DIRECTORY IN WHICH THE REPLICATION PACKET IS STORED
** Only need to do this if running this code on its own rather than through 0_main.do
*global projdir "<REPLICATION PATH>"


global lhsvars lnpat ln_inv 
global persinctaxvars mtr90 
global corpinctaxvars top_corp 
global controllag 1 // How many years to lag control variables: GDP/capita and population density
global minyear 1940 // Beginning year of sample
global maxyear 2000 // End year of sample
global maxlead 5 // How many years of lags to include
global maxlag  20 // Maximum number of lagged tax changes to include (years after tax change to plot out to)

log using "$projdir/Logs/distributed_lags.log", replace

program main
	figure4
end

program figure4
syntax
	local controls l${controllag}s.real_gdp_pc l${controllag}s.population_density ///
					   l${controllag}s.rd_credit
	use "$projdir/Data/state_data" if inrange(year,${minyear},${maxyear}) & !inlist(stateabbr,"LA","AK","HI","PR"), clear
	
	sort statenum year
	gen  fiveyear = 5*floor(year/5)
	egen statenum_fiveyear = group(statenum fiveyear)
	
	foreach var of varlist $persinctaxvars $corpinctaxvars rd_credit {
		replace `var' = ln(1-`var'/100)
		}
		
	* Label variables 
	label var top_corp "Top Combined Corporate MTR"
	label var mtr90 "90th Percentile Worker Combined MTR"
	
	**************************
	***** WEIGHTED REGS ******
	**************************
	
	* Run regressions, looping through lhs vars and tax variables
	foreach taxvar in ${persinctaxvars} {
		local taxlab: var label `taxvar'
		foreach lhsvar in $lhsvars {
			local ylab: var label `lhsvar'
			gen x = `taxvar' - l.`taxvar'
			
			reghdfe s.`lhsvar' f(1/$maxlead).x l(0/$maxlag).x l${controllag}s.top_corp `controls' [aw=pop1940], vce(cluster statenum) absorb(year)
			make_cumul_effect_plot, yvar(`lhsvar') taxvar(`taxvar') ytitle("Effect of `taxlab'" "on `ylab'") ci_90
			drop x
			}
		}
		
	* Same for corporate taxes
	foreach taxvar in ${corpinctaxvars} {
		local taxlab: var label `taxvar'
		foreach lhsvar in $lhsvars {
			local ylab: var label `lhsvar'
			gen x = `taxvar' - l.`taxvar'
			gen control1 = has_sales_weight - l.has_sales_weight
			gen control2 = sales_wgt - l.sales_wgt
			gen control3 = payroll_wgt - l.payroll_wgt
			gen control4 = lcb - l.lcb
			gen control5 = lcf - l.lcf

			
			#delimit ;
			reghdfe s.`lhsvar'  f(1/$maxlead).x l(0/$maxlag).x 
								f(1/${maxlead}).control1 l(1/${maxlag}).control1 
								f(1/${maxlead}).control2 l(1/${maxlag}).control2 
								f(1/${maxlead}).control3 l(1/${maxlag}).control3 
								f(1/${maxlead}).control4 l(1/${maxlag}).control4 
								f(1/${maxlead}).control5 l(1/${maxlag}).control5 
								l${controllag}s.mtr90 
								`controls' [aw=pop1940], 
								vce(cluster statenum) absorb(year);
								
			make_cumul_effect_plot, yvar(`lhsvar') taxvar(`taxvar') 
					ytitle("Effect of `taxlab'" "on `ylab'") ci_90;
			drop x control*;
			#delimit cr
			}
		}

end

program make_cumul_effect_plot
syntax, yvar(string asis) taxvar(string asis) [ytitle(string asis) ci_90]
	preserve
	
	* Generate local containing test of sum of coefficients
	local firstpoint = $maxlead + 1
	forvalues n = 1/$maxlead {
		local subtract `subtract' - f`n'.x
		}
	lincom `subtract'
	gen betaminus`firstpoint' = r(estimate)
	gen seminus`firstpoint' = r(se)
	
	* Test $maxlead year lead = 0
	lincom f${maxlead}.x `subtract'
	gen betaminus${maxlead} = r(estimate)
	gen seminus${maxlead} = r(se)
	
	* Test sum of coefficients for years before tax change
	local lincomb f${maxlead}.x
	local maxlead_minus1 = ${maxlead} - 1
	local jointtest_lead f${maxlead}.x // Test that leads are jointly 0
	forvalues lead = `maxlead_minus1'(-1)1 {
		local lincomb `lincomb' + f`lead'.x
		local jointtest_lead `jointtest_lead' = f`lead'.x
		lincom `lincomb' `subtract'
		gen betaminus`lead' = r(estimate)
		gen seminus`lead' = r(se)
		}

	* Test sum of coefficients for years after tax change
	local jointtest_lag 0 // Test that lags are jointly 0
	forvalues lag = 0/$maxlag {
		local lincomb `lincomb' + l`lag'.x
		local jointtest_lag `jointtest_lag' = l`lag'.x
		lincom `lincomb' `subtract'
		gen betaplus`lag' = r(estimate)
		gen seplus`lag' = r(se)
		}
	
	* Test that leads and lags are jointly zero
	test `jointtest_lead' = 0
	local Fp_lead: di %5.3f r(p)
	test `jointtest_lag'
	local Fp_lag: di %5.3f r(p)

	* Create dataset of coefficients and SEs
	collapse betaminus`firstpoint'-seplus${maxlag}
	gen byte ones = 1
	reshape long beta se, i(ones) j(rel_yr) string
	replace rel_yr = subinstr(rel_yr,"minus","-",.)
	replace rel_yr = subinstr(rel_yr,"plus","",.)
	destring rel_yr, replace
	replace rel_yr = rel_yr + 1 // Matches Suarez-Serrato and Zidar (2018) timing
	
	* Generate confidence intervals
	if "`ci_90'" != "" {
		gen upper_CI = beta + 1.64*se
		gen lower_CI = beta - 1.64*se
		}
	else {
		gen upper_CI = beta + 1.96*se
		gen lower_CI = beta - 1.96*se
		}
		
	* Make plots
	#delimit ;
	sort rel_yr;
	summ upper_CI;
	local max = r(max);
	local max2 = `max'*0.8;
	twoway  (scatter beta rel_yr, connect(direct) lp(solid) lc(edkblue)) 
			(line upper_CI rel_yr, lp(dash) lc(edkblue) lw(medthick))
			(line lower_CI rel_yr, lp(dash) lc(edkblue) lw(medthick)), 
			yline(0) xline(0, lp(dash)) legend(off)
			graphregion(color(white)) legend(off) ytitle(`ytitle') 
			xtitle("Years Since Tax Change") 
			xlabel(-5(5)20, grid) xtick(-5/20)
			text(`max2' 1 "F-test all lags are 0 has p-value = `Fp_lag'", box just(left) size(small) fcolor(white) margin(medsmall) )
			text(`max' 1 "F-test all leads are 0 has p-value = `Fp_lead'", box just(left) size(small) fcolor(white) margin(medsmall) );
	graph export "$projdir/Results/Figures/Figure4_distLag_`yvar'_`taxvar'.eps", replace;
	
	summ beta if rel_yr > 0;
	#delimit cr
	restore
end

main

log close
