program make_cumul_effect_plot
syntax, yvar(string asis) taxvar(string asis) [ytitle(string asis) ci_90]
	preserve
	
	* Generate local containing test of sum of coefficients
	local firstpoint = $maxlead + 1
	forvalues n = 1/$maxlead {
		local subtract `subtract' - f`n'.x   
		}
	lincom `subtract'  //  lincom  - f1.x - f2.x - f3.x - f4.x - f5.x
	gen betaminus`firstpoint' = r(estimate) // beta[-6]
	gen seminus`firstpoint' = r(se)         //   se[-6]
	 
	* Test $maxlead year lead = 0
	lincom f${maxlead}.x `subtract'  // lincom f5.x - f1.x - f2.x - f3.x - f4.x - f5.x
	gen betaminus${maxlead} = r(estimate)   // beta[-5]
	gen seminus${maxlead} = r(se)           //   se[-5]
	
	* Test sum of coefficients for years before tax change
	local lincomb f${maxlead}.x             // f5.x
	local maxlead_minus1 = ${maxlead} - 1   // 4
	local jointtest_lead f${maxlead}.x      // f5.x, Test that leads are jointly 0
	forvalues lead = `maxlead_minus1'(-1)1 { // 4 3 2 1
		local lincomb `lincomb' + f`lead'.x  // f5.x f4.x f3.x f2.x f1.x
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
			graphregion(color(white)) legend(off) ytitle(`ytitle', size(8pt)) 
			xtitle("Years Since Tax Change", size(8pt)) 
			xlabel(-5(5)20, grid) xtick(-5/20)
			text(`max2' 1 "F-test all lags are 0, p-value = `Fp_lag'",  box just(center) size(8pt) fcolor(white) margin(medsmall))
			text(`max' 1 "F-test all leads are 0, p-value = `Fp_lead'", box just(center) size(8pt) fcolor(white) margin(medsmall));
*	graph export "$projdir/Results/Figures/Figure4_distLag_`yvar'_`taxvar'.eps", replace;
	
	summ beta if rel_yr > 0;
	#delimit cr
	restore
end