
*    
*     
*       ██████ ▄▄▄█████▓ ▄▄▄     ▄▄▄█████▓ ▄▄▄      
*     ▒██    ▒ ▓  ██▒ ▓▒▒████▄   ▓  ██▒ ▓▒▒████▄    
*     ░ ▓██▄   ▒ ▓██░ ▒░▒██  ▀█▄ ▒ ▓██░ ▒░▒██  ▀█▄  
*       ▒   ██▒░ ▓██▓ ░ ░██▄▄▄▄██░ ▓██▓ ░ ░██▄▄▄▄██ 
*     ▒██████▒▒  ▒██▒ ░  ▓█   ▓██▒ ▒██▒ ░  ▓█   ▓██▒
*     ▒ ▒▓▒ ▒ ░  ▒ ░░    ▒▒   ▓▒█░ ▒ ░░    ▒▒   ▓▒█░
*     ░ ░▒  ░ ░    ░      ▒   ▒▒ ░   ░      ▒   ▒▒ ░
*     ░  ░  ░    ░        ░   ▒    ░        ░   ▒   
*           ░                 ░  ░              ░  ░
*                                                         
*     
*                                                       
*       _________________________________________       
*       —————————————————————————————————————————       
*                                                  
*                   学术论文研讨班  
*            
*                连享会 (www.lianxh.cn)
*                         
*                      (2022.5.2)                 
*                                   
*        课程主页：https://gitee.com/lianxh/paper  
*       _________________________________________       
*       —————————————————————————————————————————
*                                                       
*                                                       
*                主讲人：连玉君                   
*                                                       
*        单  位：中山大学岭南学院金融系                
*        电  邮: arlionn@163.com                        
*        
*        主  页: https://www.lianxh.cn (最新推文都在这里, 百度：连享会)
*        知  乎: https://www.zhihu.com/people/arlionn/
*        微  博：http://weibo.com/arlionn               

*        微  信：lianyj45                               
*        公众号：Stata连享会(微信: StataChina)            
		  
		  
		  
		  
		  
*          ===================================
*
*              第 6 讲  所得税与创新 (附录)
*                          
*
*                https://www.lianxh.cn
*          ===================================

*-注意：执行后续命令之前，请先执行如下命令

  global PP     "`c(sysdir_personal)'/PX_C_2022b"  // 课程目录，酌情修改
  
  global path  "$PP/paper_rep/Akcigit_QJE_2022" //本文目录
  global D    "$path/data"         //范例数据
  global R    "$path/refs"         //参考文献
  global Out  "$path/out"          //结果：图形和表格
  adopath +   "$PP/adofiles"       //外部命令
  adopath +   "$path/myado"        //自编命令
  cd "$Out"
  set scheme s2color 
  
*--------------------------------------------------------------------
*-Ufuk Akcigit, John Grigsby, Tom Nicholas, Stefanie Stantcheva,2022, 
*  Tax and Innovation in the Twentieth Centiry,   
*  The Quarterly Journal of Economics, 137 (1): 329-385.
*--------------------------------------------------------------------

  shellout "$R/Akcigit_QJE_2022_Appendix.pdf"   // 附录内容
  
* 本部分是正文的附录内容，查看正文执行下述命令。
  
  doedit "$path\Akcigit_QJE_2022.do"
 
* 我们根据作者提供的有限数据复现了附录中的结果。但是，作者在正文和附录中提供
* 的可用于复现的信息太少，我们无法完全复制作者的结果。因此，我们的附录过程仅
* 仅作为一种思考过程。有兴趣的同学，可以在我们提供的过程基础上，自行调整控制
* 变量的组合，以及核心解释变量的设定形式，实现完整复现作者结果。
  
*======================================
*--------
*- Section 1 ：Macro-data estimation
*--------
*======================================
 

  local minyear = 1940
  local maxyear = 2000 
  use "$D/state_data" if inrange(year,`minyear' - 1,`maxyear') & !inlist(stateabbr,"","HI","AK","LA"), clear
  
  xtset statenum year
  
  global additional_controls L.real_gdp_pc L.population_density
  global more_controls base_index_lag3 c.base_index_lag3#c.top_corp_lag3
  
  gen mtr90_lag2 = L2.mtr90
  gen top_corp_lag2 = L2.top_corp
  
  local taxvariables mtr90_lag3 top_corp_lag3 mtr50_lag3 mtr_married90_lag3  mtr90_lag3_item mtr90_lag1 top_corp_lag1 atr90_lag3 atr50_lag3 top_corp_ap_lag3 mtr90_lag2 top_corp_lag2 mtr_inclag5_statelag590_lag3 top_corp_instrument_lag3 mtr_inclag5_statelag550_lag3
  foreach var of varlist `taxvariables' {
	cap replace `var' = ln(1-`var'/100)
  }
  
  gen byte miaptax = missing(top_corp_ap_lag3)
  replace top_corp_ap_lag3 = top_corp_lag3 if missing(top_corp_ap_lag3)

  gen fiveyear = 5*floor(year/5)
  egen statenum_fiveyear = group(statenum fiveyear)
 
*----Table C.6-----

  reghdfe lncit_unadj mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(clusterstatenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncorp_pat mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(clusterstatenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnnoncorp_pat mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(clusterstatenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnmean_kpss mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(clusterstatenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnEmpPerEstab mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(clusterstatenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnVA mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(clusterstatenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpayroll mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(clusterstatenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnawe mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(clusterstatenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnrpi_pc mtr90_lag3 top_corp_lag3 L.population_density rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(clusterstatenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  
*----Table C.7-----

  reghdfe lnpat mtr50_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit mtr50_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv mtr50_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned mtr50_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat atr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit atr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv atr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned atr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat atr50_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit atr50_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv atr50_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned atr50_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
*----Table C.8----

 reghdfe lnpat mtr90_lag3 mtr50_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit mtr90_lag3 mtr50_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv mtr90_lag3 mtr50_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned mtr90_lag3 mtr50_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
*-----Table C.9-----

 reghdfe lnpat mtr_married90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit mtr_married90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv mtr_married90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned mtr_married90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
*-----Table C.10-----

  reghdfe lnpat mtr90_lag3_item top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit mtr90_lag3_item top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv mtr90_lag3_item top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned mtr90_lag3_item top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
 
*-----Table C.11-----

 reghdfe lnpat mtr90_lag3 top_corp_ap_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit mtr90_lag3 top_corp_ap_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv mtr90_lag3 top_corp_ap_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned mtr90_lag3 top_corp_ap_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
*-----Table C.12-----

reghdfe lnpat mtr90_lag1 top_corp_lag1 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit mtr90_lag1 top_corp_lag1 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv mtr90_lag1 top_corp_lag1 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned mtr90_lag1 top_corp_lag1 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat mtr90_lag2 top_corp_lag2 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit mtr90_lag2 top_corp_lag2 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv mtr90_lag2 top_corp_lag2 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned mtr90_lag2 top_corp_lag2 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)

*-----Table C.14-----

 preserve
 drop if stateabbr == "CA" | stateabbr == "NY"
 
 reghdfe lnpat mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  restore
  

*-----Table C.15-----

 preserve
 drop if inrange(year, 1970,1979)
 
  reghdfe lnpat mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  restore
  
*-----Table C.16-----

  reghdfe lnpat mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 govdem pctdemup pctdemlo [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 govdem pctdemup pctdemlo [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 govdem pctdemup pctdemlo [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 govdem pctdemup pctdemlo [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
*-----Table C.17-----

  reghdfe lnpat mtr90_lag3 top_corp_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit mtr90_lag3 top_corp_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv mtr90_lag3 top_corp_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned mtr90_lag3 top_corp_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  restore
  
*-----Table C.18-----

  reghdfe lnpat mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3, absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lnpat if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3, absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum lncit if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe ln_inv mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3 [aw=pop1940], absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum ln_inv if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe share_assigned mtr90_lag3 top_corp_lag3 $additional_controls rd_credit_lag3, absorb(statenum year) vce(cluster statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  restore
  
*-----Table C19-----
  
  reghdfe mtr90_lag3 mtr_inclag5_statelag590_lag3 top_corp_instrument_lag3 rd_credit_lag3 $additional_controls [aw=pop1940], absorb(statenum year) cluster(statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe top_corp_lag3 mtr_inclag5_statelag590_lag3 top_corp_instrument_lag3 rd_credit_lag3 $additional_controls [aw=pop1940], absorb(statenum year) cluster(statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe mtr50_lag3 mtr_inclag5_statelag550_lag3 top_corp_instrument_lag3 rd_credit_lag3 $additional_controls [aw=pop1940], absorb(statenum year) cluster(statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe top_corp_lag3 mtr_inclag5_statelag550_lag3 top_corp_instrument_lag3 rd_credit_lag3 $additional_controls [aw=pop1940], absorb(statenum year) cluster(statenum_fiveyear year)
  sum share_assigned [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  
*======================================
*--------
*- Section 2 ：Micro-data estimation
*--------
*======================================

  
  local minyear = 1940
  local maxyear = 2000
  use "$D/micro_reg_data" if !inlist(stateabbr,"LA","","HI","AK","PR") & !missing(state) & inrange(year,`minyear',`maxyear'), clear
  xtset inv_id year
 
  global additional_controls agglomeration_lag1 tenure tenure2
  global additional_controls_stfe gdppc_lag1 popdens_lag1 rd_credit_lag3
  
  replace top_corp_lag3 = ln(1-top_corp_lag3/100)
  replace rd_credit_lag3 = ln(1-rd_credit_lag3/100)
  
* 生成有效税率  
  gen byte high = L.inv_qual1_top10_c == 1 // 生成表示高生产率的虚拟变量
  gen eff_tax = mtr90_lag3*high + mtr50_lag3*(1-high)
  replace eff_tax = ln(1-eff_tax/100)
  
  gen byte high_5 = L.inv_qual1_top5_c == 1 // 生成表示高生产率的虚拟变量
  gen eff_tax_5 = mtr90_lag3*high_5 + mtr50_lag3*(1-high_5)
  replace eff_tax_5 = ln(1-eff_tax_5/100)
  
  gen byte high_25 = L.inv_qual1_top25_c == 1 // 生成表示高生产率的虚拟变量
  gen eff_tax_25 = mtr90_lag3*high_25 + mtr50_lag3*(1-high_25)
  replace eff_tax_25 = ln(1-eff_tax_25/100)
  
  gen byte high_10 = L.inv_qual1_top10_c == 1 // 生成表示高生产率的虚拟变量
  gen byte high_10_25 = L.inv_qual1_top25_c == 1 & L.inv_qual1_top10_c1=1
  gen eff_tax_10_25 = mtr90_lag3*high_10 + mr75_lag3*high_10_25 + mtr50_lag3*(1-high_10_25)
  replace eff_tax_10_25 = ln(1-eff_tax_10_25/100)
  
  gen byte high_citation = L.inv_qual1_top10_c == 1 // 生成表示高生产率的虚拟变量
  gen eff_tax_citation = mtr90_lag3*high_citation + mtr50_lag3*(1-high_citation)
  replace eff_tax_citation = ln(1-eff_tax_citation/100)
  
  gen byte high = L.inv_qual1_top10_c == 1 // 生成表示高生产率的虚拟变量
  gen eff_tax_married = mtr_married90_lag3*high + mtr_married50_lag3*(1-high)
  replace eff_tax_married = ln(1-eff_tax_married/100)
  
				
* 生成有效税率与集聚效应的交互项
  gen eff_tax_agglom = eff_tax * agglomeration_lag1
  gen top_corp_agglom = top_corp_lag3 * agglomeration_lag1
  gen eff_tax_state_patent = eff_tax * lnpat_statewide_lag1
  
* 生成时期虚拟变量
  gen year_1970 = inrange(year, 1970, 2000)
					
  label var high "High Quality Inventor"
  label var eff_tax "Log(1 - Effective Marginal Tax Rate)"
  label var top_corp_lag3 "Log(1 - Top Corporate Tax Rate)"
  
  

*------Table C.23-----

  reghdfe has_pat3yr eff_tax_5 high_5 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_5 high_5 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax_5 high_5 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_5 high_5 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax_5 high_5 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax_5 top_corp_lag3 high_5 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_5 top_corp_lag3 high_5 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax_5 top_corp_lag3 high_5 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_5 top_corp_lag3 high_5 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax_5 top_corp_lag3 high_5 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
*-----Table C.24------

  reghdfe has_pat3yr eff_tax_25 high_25 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_25 high_25 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax_25 high_25 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_25 high_25 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax_25 high_25 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax_25 top_corp_lag3 high_25 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_25 top_corp_lag3 high_25 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax_25 top_corp_lag3 high_25 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_25 top_corp_lag3 high_25 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax_25 top_corp_lag3 high_25 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
*------Table C.25------

  reghdfe has_pat3yr eff_tax_10_25 high_10 high_10_25 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_10_25 high_10 high_10_25 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax_10_25 high_10 high_10_25 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_10_25 high_10 high_10_25 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax_10_25 high_10 high_10_25 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax_10_25 high_10 high_10_25 top_corp_lag3 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_10_25 high_10 high_10_25 top_corp_lag3 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax_10_25 high_10 high_10_25 top_corp_lag3 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_10_25 high_10 high_10_25 top_corp_lag3 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax_10_25 high_10 high_10_25 top_corp_lag3 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
*------Table C.26-----

  reghdfe has_pat3yr eff_tax_citation high_citation $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_citation high_citation $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax_citation high_citation $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_citation high_citation $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax_citation high_citation $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax_citation top_corp_lag3 high_citation $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_citation top_corp_lag3 high_citation $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax_citation top_corp_lag3 high_citation $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_citation top_corp_lag3 high_citation $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax_citation top_corp_lag3 high_citation $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
*------Table C.28------

  preserve
  drop if inlist(stateabbr, "CA", "NY")
  reghdfe has_pat3yr eff_tax high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  restore
  
*------Table C.29-----

 preserve
 drop if inrange(year, 1970, 1979)
 reghdfe has_pat3yr eff_tax high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  restore
  
  
*------Table C.30------

  reghdfe has_pat3yr eff_tax, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax top_corp_lag3, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax top_corp_lag3, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax top_corp_lag3, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax top_corp_lag3, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax top_corp_lag3, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax top_corp_lag3, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax top_corp_lag3, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax top_corp_lag3, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  
*------Table C.31------

  reghdfe has_pat3yr eff_tax_married high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_married high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax_married high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_married high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax_married high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax_married top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_married top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax_married top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_married top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax_married top_corp_lag3 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
*------Table C.32------

  reghdfe has_pat3yr eff_tax high $additional_controls, absorb(state*year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax high $additional_controls, absorb(state*year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax high $additional_controls, absorb(state*year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax high $additional_controls, absorb(state*year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax high $additional_controls, absorb(state*year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax top_corp_lag3 high $additional_controls, absorb(state year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax top_corp_lag3 high $additional_controls, absorb(state year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax top_corp_lag3 high $additional_controls, absorb(state year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax top_corp_lag3 high $additional_controls, absorb(state year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax top_corp_lag3 high $additional_controls, absorb(state year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  

*------Table C.35------

 reghdfe has_pat3yr eff_tax c.eff_tax#i.year_1970 high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax c.eff_tax#i.year_1970 high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax c.eff_tax#i.year_1970 high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax c.eff_tax#i.year_1970 high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax c.eff_tax#i.year_1970 high $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax top_corp_lag3 c.eff_tax#i.year_1970 c.top_corp_lag3#i.year_1970 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax top_corp_lag3 c.eff_tax#i.year_1970 c.top_corp_lag3#i.year_1970 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax top_corp_lag3 c.eff_tax#i.year_1970 c.top_corp_lag3#i.year_1970 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax top_corp_lag3 c.eff_tax#i.year_1970 c.top_corp_lag3#i.year_1970 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax top_corp_lag3 c.eff_tax#i.year_1970 c.top_corp_lag3#i.year_1970 high $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
*-------Table C.36------

  reghdfe has_pat3yr eff_tax high eff_tax_agglom eff_tax_state_patent lnpat_statewide_lag1 $additional_controls, absorb(inv_id state*year) vce(cluster inventor statenum*year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax high eff_tax_agglom eff_tax_state_patent lnpat_statewide_lag1 $additional_controls, absorb(inv_id state*year) vce(cluster inventor statenum*year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax high eff_tax_agglom eff_tax_state_patent lnpat_statewide_lag1$additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax high eff_tax_agglom eff_tax_state_patent lnpat_statewide_lag1 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax high eff_tax_agglom eff_tax_state_patent lnpat_statewide_lag1 $additional_controls, absorb(inv_id state*year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax top_corp_lag3 high eff_tax_agglom eff_tax_state_patent lnpat_statewide_lag1 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax top_corp_lag3 high eff_tax_agglom eff_tax_state_patent lnpat_statewide_lag1 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax top_corp_lag3 high eff_tax_agglom eff_tax_state_patent lnpat_statewide_lag1 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax top_corp_lag3 high eff_tax_agglom eff_tax_state_patent lnpat_statewide_lag1 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe high_kpss3yr eff_tax top_corp_lag3 high eff_tax_agglom eff_tax_state_patent lnpat_statewide_lag1 $additional_controls, absorb(inv_id state year) vce(cluster statenum year) keepsingletons
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  
*------Table C.37------

  preserve
  replace eff_tax_90 = ln(1-mtr90_lag3/100)
  replace eff_tax_50 = ln(1-mtr50_lag3/100)
  
  
  reghdfe has_pat3yr eff_tax_90 top_corp_lag3 $additional_controls $additional_controls_stfe, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax_90 eff_tax_50 top_corp_lag3 $additional_controls $additional_controls_stfe, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has_pat3yr eff_tax_90 eff_tax_50 c.eff_tax_90#i.high c.eff_tax_50#i.high top_corp_lag3 $additional_controls $additional_controls_stfe, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd) 
  
  reghdfe lnpat3yr eff_tax_90 top_corp_lag3 $additional_controls $additional_controls_stfe, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax_90 eff_tax_50 top_corp_lag3 $additional_controls $additional_controls_stfe, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lnpat3yr eff_tax_90 eff_tax_50 c.eff_tax_90#i.high c.eff_tax_50#i.high  top_corp_lag3 $additional_controls $additional_controls_stfe, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_90 top_corp_lag3 $additional_controls $additional_controls_stfe, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_90 eff_tax_50 top_corp_lag3 $additional_controls $additional_controls_stfe, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe has10cit_3yr eff_tax_90 eff_tax_50 c.eff_tax_90#i.high c.eff_tax_50#i.high top_corp_lag3 $additional_controls $additional_controls_stfe, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_90 top_corp_lag3 $additional_controls $additional_controls_stfe, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_90 eff_tax_50 top_corp_lag3 $additional_controls $additional_controls_stfe, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  reghdfe lncit3yr eff_tax_90 eff_tax_50 c.eff_tax_90#i.high c.eff_tax_50#i.high  top_corp_lag3 $additional_controls $additional_controls_stfe, absorb(inv_id statenum year) vce(cluster statenum year) keepsingletons
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se = r(sd)
  
  restore
  

  
  
  

  
  

  
  
  
  
  
  
  
  
  
