*       _________________________________________       
*       —————————————————————————————————————————       
*                                                  
*                 Stata 研讨班 (高级)   
*            
*                连享会 (www.lianxh.cn)
*                         
*                   (2024.7.19-21)                 
*                                                         
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
*        b   站：https://space.bilibili.com/546535876 (b站搜索：连享会)

*        微  信：lianyj45                               
*        公众号：连享会 ( ID: lianxh_cn )          
		  

*oooooooooooooooooooooooooooooooooooooooooooooooooooo
*
*                      重现论文
*
*oooooooooooooooooooooooooooooooooooooooooooooooooooo

*--------------------------------------------------------------------
*-Ufuk Akcigit, John Grigsby, Tom Nicholas, Stefanie Stantcheva,2022, 
*  Tax and Innovation in the Twentieth Centiry,   
*  The Quarterly Journal of Economics, 137 (1): 329-385.
*--------------------------------------------------------------------


*-注意：执行后续命令之前，请先执行如下命令

  global P1     "`c(sysdir_personal)'/PX_B_2025a"  // 课程目录，酌情修改
  
  global path0  "$PP/B1_Test/paper"       //本讲目录
  global path1  "$path0/Akcigit_QJE_2022" //本文目录
  
  global D     "$path1/data"           //原始数据, 不可更改，不可删除
  global Dtemp "$path1/data_temp"      //临时中转数据, 随后可以删除
  global R     "$path1/refs"           //参考文献
  global Out   "$path1/out"            //结果：图形和表格
  adopath +    "$P1/adofiles"         //外部命令
  adopath +    "$path1/myado"          //自编命令
  cd "$Out" 
  
*--------------------
* 安装和设置绘图模板 (根据喜好执行)
                                                /*
. set scheme s2color  // Stata 默认, 彩色
. set scheme s2mono   // Stata 默认, 黑白
 *ssc install schemepack, replace  //white_tableau 模板, 已安装
. set scheme white_tableau //设定绘图风格为white_tableau, 更美观
                                                */   
  
*------          ---
*-后文用到的一些简写命令：

*    简写       完整写法
*    #d ;       #delimit ;
*    g, gen     generate
*    qui        quietly
*    mat        matrix

  
*--------------------------------------------------------------------
*-Ufuk Akcigit, John Grigsby, Tom Nicholas, Stefanie Stantcheva,2022, 
*  Tax and Innovation in the Twentieth Centiry,   
*  The Quarterly Journal of Economics, 137 (1): 329-385.
*--------------------------------------------------------------------

   shellout "$R/Akcigit_QJE_2022.pdf"          // PDF 原文

   shellout "$R/Akcigit_QJE_2022_Appendix.pdf" // 附录内容
   
   shellout "$R/Akcigit_2018_wp.pdf"  // 2018 Working paper 对比, 改了啥?
   
   
 *-讲义
   shellout "$path/中文精要_Akcigit_QJE_2022_讲义.pdf"  
   

   
*======================== 特别说明：========================
* by 初稿：李鑫 (云南大学博士生) - 连享会助教  2022/4/11
*    定稿：连玉君  2022/4/26 15:01
* 
* 作者的 dofile 存在一点小瑕疵：不同表格和图形的时间范围和州选择存在一点差异
* 如果我们统一将时间范围限定在1940-2000年，
* 并且删除 LA AK HI PR 和观测值缺失的州
* 那么部分表格和图形将与正文结果存在细微差异 (但不会实质性影响文章的结论)

* 我们猜测作者这样处理的目的是避免使用滞后项时存在大量的缺失值问题。

* 我们以 Table2 为例进行简要说明。
* Table 2 使用的样本区间为 1939-2000年，
* 因而当设定滞后项时，确保在研究区间 1940 年不存在缺失值。

* 若忽略上述问题，不会改变文中的基本结论。

* 主要影响是：个人所得税和公司所得税对创新的产出弹性将变小。
* 如果大家感兴趣，使用描述性统计中的样本估计 Table 2、 Table 3、 
* Figure1、Figure2、Figure3 和 Figure 4 相应的命令。

*--------------------- Notes - Appendix -----------------0-----
* 本 dofile 用于呈现正文中的结果，附录结果请执行以下 dofile：
/*
   doedit "$path/Appendix.do"
*/
*--------------------- Notes - Appendix -----------------1-----

*-安装外部命令, 已安装, 存放于 adofiles 中，后续如需更新，则执行如下命令:
/*
 ssc install xcollapse 
 ssc install tabstatmat
 ssc install reghdfe
*/



*------------------
*-00：数据概况         连享会添加
*------------------

*-个人数据 (发明家)
*-Table 1 A-B: Inventor-level data 

  use "$D/micro_reg_data" if inrange(year,1940,1999) & ///
                             !inlist(stateabbr,"LA","AK","HI","PR",""), clear

/*
. xtset inv_id year
. xtdes
  inv_id:  2226, 3594, ..., 2952694           n =    1667363
    year:  1940, 1941, ..., 1999              T =         60

Distribution of T_i:  min   5%   25%   50%   75%   95%   max
                        1    1     1     1     3    17    60      */
  des 
  
  local xx "year tenure pat3yr cit3yr career* mtr*_lag3 rd* base*"
  local xx "`xx' "
  fsum `xx', label  
                                                                           /*
        Variable |       N   Mean     SD    Min    Max                                                                                                                              
-----------------+------------------------------------
            year | 6211521   1976  17.32   1940   1999  Application Year
          tenure | 6211521   9.73  13.24   0.00     96  首次进入数据库至今年数
          pat3yr | 6211521   1.49   2.58   0.00    461  # 三年专利申请数[t,t+2]
          cit3yr | 6211521  39.27  238.7   0.00  48154  # 三年专利引用数[t,t+2]
   career_length | 6211521  21.20  21.68   0.00    113  # 入库年数 (?)
        mtr50_L3 | 6211389  21.29   6.06   0.00  34.67  MTR, 50th Earner,州居民
        mtr75_L3 | 6211389  27.20   8.27   0.00  44.90  MTR, 75th Earner,州居民
        mtr90_L3 | 6211389  34.57  10.12   3.60  57.58  MTR, 90th Earner,州居民
mtr_married50_L3 | 6095036  21.04   5.66   0.00  38.97  MTR, 50th Earner,已婚
mtr_married90_L3 | 6095036  34.38   9.66   3.60  60.27  MTR, 90th Earner,已婚
    rd_credit_L3 | 6211389   0.87   2.45   0.00  20.00  R&D Tax Credit
   base_index_L3 | 5413879   0.07   0.92  -2.81   1.57  Corporate Tax Base Index
------------------------------------------------------
MP-ITR/MTR: Marginal Personal Income Tax Rate / Marginal Tax Rate
                                                                           */

																		   
*-州数据 (汇总数据)
*-------------
*-Table 1 C-D: State level data 

  use "$D\state_data.dta" if inrange(year,1940,1999) &  ///
       !inlist(stateabbr,"LA","AK","HI","PR",""), clear

  xtset statenum year
  xtdes 
/*
        statenum:  1, 3, ..., 52             n =  48
            year:  1940, 1941, ..., 1999     T =  60
*/
  
  des 

  gen num_patents   = exp(lnpat)   // 专利数
  gen num_inventors = exp(ln_inv)  // 发明家数
  gen num_citations = exp(lncit)   // 专利引用数
  
  local xx "share num* mtr50 mtr90 mtrs50 mtrs90 prog* top_corp top_*e rd_credit base_index"
  fsum `xx', label
                                                                         /*
      Variable |    N   Mean     SD    Min   Max                                                                                                                              
---------------+---------------------------------
share_assigned | 2880   0.66   0.18   0.00  1.00   Share of Patents by Corp (%)
   num_patents | 2879   1024   1616   1.00  24269  
 num_inventors | 2879   1073   1790   1.00  27902  
 num_citations | 2879  21000  63327   1.03  1.34e6  
         mtr50 | 2880  21.65   5.43   0.00  34.67  Combined MTR, 50th
         mtr90 | 2880  33.81   9.71   3.96  57.58  Combined MTR, 90th
        mtrs50 | 2880   2.72   2.60   0.00  10.00     State MTR, 50th
        mtrs90 | 2880   3.54   3.13   0.00  14.11     State MTR, 90th
 progressivity | 2838   1.58   0.34   1.08   6.52  Ratio of Personal Income MTRs
                                                   90th and 50th Pctiles
      top_corp | 2880   46.3   6.62   24.0  58.46  Top Combined Federal 
	                                                 + State Corp Tax Rate (%)
top_corp_state | 2880   4.76   3.19   0.00  12.50  Top State Corp Tax Rate (%)
     rd_credit | 2880   0.46   1.93   0.00  20.00  R&D Tax Credit
    base_index | 2350   0.16   0.90  -2.81   1.57  Corporate Tax Base Index
-------------------------------------------------   
[1] MTR: Marginal Tax Rate
[2] base_index: 税基指标, 越大，表示税基越宽, 
    估算方法：用 [州内公司应税收入/GDP] 对 Xs, State_FE, Year_FE 回归后
	求取 Xs*beta 的预测值，并做标准化处理后得到的
    p.347-348
    To summarize the myriad tax base rules into a low-
    dimensional measure, we follow Su´ arez Serrato and Zidar (2018)
    in constructing an index of "corporate tax base breadth," which
    is larger if the tax base of a state in a given year is broader, as
    explained in detail in Online Appendix A .6.2. State corporate tax
    revenues as a share of GDP are regressed on all tax base and
    apportionment variables, as well as state and year ﬁxed effects.
    The index is the predicted value from this regression, excluding
    state and year ﬁxed effects; it varies by state and year, and is stan-
    dardized to have zero mean and unit standard deviation over our full sample.	
                                                                           */


*-税率的时序特征
  global opt "overlay legend(off) xlabel(1940(5)2000)"
  global sub "mod(statenum,5)==0"
  
  *-个税
  xtline mtr50, $opt // 所有州 
  xtline mtr90, $opt // 所有州 
  
  xtline mtr50 if $sub, $opt 
  xtline mtr90 if $sub, $opt

  *-公司税
  xtline top_corp       if $sub, $opt
  xtline top_corp_state if $sub, $opt
  
  *-补贴 
  xtline rd_credit        , $opt 
  xtline rd_credit if $sub, $opt 
  
  *-税基：有点扯, ^=^
  xtline base_index        , $opt 
  xtline base_index if $sub, $opt   
  
  
  
  
  
  
*======================================
*--------
*-Table 1 ：Statistical description for     >>>>>>>>>>>>>>>>>>>>>
*           marco-data and micro-data
*--------
*======================================

*------------------State summary statistics------------------

* 数据：state_data.dta
* 删除存在离群值的州：Louisiana，Alaska，Hawaii，PR，
* 以及州简称为缺失值的州，并且限定研究区间为 1940-1999 年。

  use "$D\state_data.dta" if inrange(year,1940,1999) &  ///
       !inlist(stateabbr,"LA","AK","HI","PR",""), clear
	
  gen twentyyear = 20*floor(year/20) - 1900  //重新标注时间，如1986->80
      list twentyyear year in 1/62, sepby(twentyyear) // 查看结果
      tab  twentyyear
  
  foreach var in mtr50 mtr90 mtrs50 mtrs90 top_corp top_corp_state {
     replace `var' = `var'/100
  }  
	
  gen num_patents   = exp(lnpat)   // 专利数
  gen num_inventors = exp(ln_inv)  // 发明家数
  gen num_citations = exp(lncit)   // 专利引用数

  foreach var in num_patents num_inventors num_citations {
     replace `var' = `var'/1000    // (000s)
  }
  
*-------------
*-Table 1 C-D: State level data - summary statistics 

  global vars  ///
         num_patents num_inventors num_citations share_assigned ///
		 mtr90 mtrs90 mtr50 mtrs50 progressivity ///
		 top_corp top_corp_state rd_credit
  des $vars
  
*----------连玉君做法                  ----begin_A----
  tabstat $vars, s(mean sd) f(%4.2f) c(s) save
  tabstatmat vall
  tabstat $vars if twentyyear==40, s(mean) f(%4.2f) c(s) save //1940-1959
  tabstatmat v40
  tabstat $vars if twentyyear==60, s(mean) f(%4.2f) c(s) save //1960-1979
  tabstatmat v60
  tabstat $vars if twentyyear==80, s(mean) f(%4.2f) c(s) save //1980-1999
  tabstatmat v80
  
  matrix Tab1_Inve = (vall', v40', v60', v80')
  mat colnames Tab1_Inve = "Mean" "Std. dev." "1940-59" "1960-79" "1980-99"
  matlist Tab1_Inve, format(%10.2f) names(all)
*----------连玉君做法                  ----over_A---- 

                                                                          /*
             |   Mean   Std. dev.     1940-59     1960-79     1980-99 
-------------+--------------------------------------------------------
 num_patents |   1.02        1.62        0.75        0.97        1.35 
num_invent~s |   1.07        1.79        0.65        0.98        1.59 
num_citati~s |  21.00       63.33        6.68       10.32       45.99 
share_assi~d |   0.66        0.18        0.53        0.71        0.74 
       mtr90 |   0.34        0.10        0.23        0.38        0.40 
      mtrs90 |   0.04        0.03        0.02        0.04        0.05 
       mtr50 |   0.22        0.05        0.18        0.24        0.23 
      mtrs50 |   0.03        0.03        0.01        0.03        0.05 
progressiv~y |   1.58        0.34        1.32        1.60        1.80 
    top_corp |   0.46        0.07        0.45        0.51        0.42 
top_corp_s~e |   0.05        0.03        0.03        0.05        0.07 
   rd_credit |   0.46        1.93        0.00        0.00        1.37 
                                                                          */
 


*------------以下为作者的代码------- 有点繁琐, 炫技 ^=^ 
*
* 用 xcollapse 和 collapse 命令计算州层级变量的均值和标准差。
*
* C1:   均值, N，存入 "Tab1_means" --> Table 1 Col(1) 
* C2: 标准差,    存入 "Tab1_sds"   --> Table 1 Col(2) 
* C3: 分时段计算各个变量的均值和样本数, (40,60,80) --> Table 1 Col(3)-(5)

/* 关键命令，按需执行，查看帮助
    help xcollapse
    help collapse
    help tostring
    help append
    help inlist()
	help export excel
*/
*-相关推文：
    . lianxh excel   // 执行命令查看推文
  *-help export excel
    * Stata转Excel：export-excel-命令详解: 
	  view browse "https://www.lianxh.cn/news/7f3cc4b8b5d52.html"
  *-help 
    * Stata结果输出：Excel结果表变身LaTeX表格: 
	  view browse "https://www.lianxh.cn/news/77e2251d6fbed.html"
	  
	  
  xcollapse $vars (count) N=statenum, saving("Tab1_means", replace) // C1
     preserve  // 查看转换效果, 可以忽略
	   use "Tab1_means", clear
	   list
	 restore 
  
  xcollapse (sd) $vars , saving("Tab1_sds", replace)                // C2
  
  collapse $vars  (count) N=statenum, by(twentyyear)                // C3
  browse  // 查看数据
  
  tostring twentyyear, replace
	
  append using "Tab1_means"
  replace twentyyear = "Mean" if twentyyear == ""
  append using "Tab1_sds"
  replace twentyyear = "SD" if twentyyear == ""
  foreach var of varlist $vars N {
	 rename `var' v`var'
  }
		
* 通过两次数据结构的转化，实现结果形式与 Table 1 一致。
  reshape long v, i(twentyyear) j(variable) string
  reshape wide v, i(variable)   j(twentyyear) string
  
  label var v40 "1940-59"
  label var v60 "1960-79"
  label var v80 "1980-99"
  label var vMean "Mean"
  label var vSD "S.D.
  order variable vMean vSD v40 v60 v80
	
/*
  foreach var in vMean vSD v40 v60 v80 {
	 replace `var' = `var'/1000  ///
	    if inlist(variable,"num_patents","num_citations","num_inventors")
  }
	 */	
  format vMean-v80 %6.2f
  
  *-输出到 Excel 表格 
  export excel using "Tab01_state.xlsx", firstrow(varlabels) keepcellfmt replace 
  *| Note: 选中 Excel 中的内容: 右击-设置单元格属性-数字-小数点后两位 
  
* 州层级的创新产出的水平值、个人所得税和公司所得税
  
*<---------另存一份中间数据----------->  
  save "state_sumstatistic.dta", replace

  
*-------------
*-Table 1 A-B: Inventor-level data - summary statistics 

  use "$D/micro_reg_data" if inrange(year,1940,1999) & ///
                             !inlist(stateabbr,"LA","AK","HI","PR",""), clear
	
* 将税率变动范围限定在0-1之间。

  foreach var of varlist mtr50_lag3 mtr90_lag3 top_corp_lag3 {
	 replace `var' = `var'/100
  }
	
* 构建辅助变量，用于估计创新、个体所得税、公司所得税的均值、方差和样本观测值。

  gen twentyyear = 20*floor(year/20) - 1900   //重新标注时间
  bysort inv_id (year): egen corp_inventor = max(has_corp_pat) //筛选出公司发明最多者
  gen byte home_state_inventor = stateabbr == home_stateabbr	//筛选本州发明家
  gen byte high = L.inv_qual1_top10_c == 1 // 筛选高生产率发明家
  gen eff_tax = mtr90_lag3*high + mtr50_lag3*(1-high) //计算发明家有效税率	
  gen byte ones = 1 // 将整个样本观测值看成是一个组，用于计算均值时的分组

qui{  //-------------begin01----一直选到 【over01】, 然后一起执行------------
  
* 将描述性统计变量赋值给暂元，便于后续估计

  local vars numpat has_pat3yr numcit has10cit_3yr eff_tax top_corp_lag3 home_state_inventor corp_inventor
  des `vars'
	
* 定义临时文件存储描述性统计结果

  tempfile means
  tempfile sds
  tempfile patweights
  tempfile patweights_twentyyear
  tempfile citweights
  tempfile citweights_twentyyear
 
* 个体的均值计算过程与州层级变量相似，差别在于这里计算的是加权平均值。
* 我们以命令 (2) 为例进行说明，其余命令分析过程类似。
* 命令 (2) 中，计算 corp_inventor 和 home_state_inventor 两个变量的均值，
* 并赋值给 corp_patents 和 home_state_pat 变量。
* 
* 选项中的 by(ones) 意味着作者将整体样本看成是一个大的分组，
* [aw=numcit]: 使用专利申请数量作为权重，即反映的是专利申请数非零的个体。

* 描述性统计中的权重含义可参见如下资料
  /*
     . help   weight
	 . lianxh weight
  */
  // 连享会推文: Stata 权重设定-fweight-pweight
     view browse "https://www.lianxh.cn/news/4dbc40eb41c3d.html"
 
* 统计量计算过程

  xcollapse `vars' (count) N = inv_id, by(ones) saving(`means', replace) // (1)
  
  xcollapse corp_patents   = corp_inventor   ///
            home_state_pat = home_state_inventor [aw=numpat], ///
			by(ones) saving(`patweights', replace)                       // (2)
  
  xcollapse      corp_cits = corp_inventor        ///
            home_state_cit = home_state_inventor [aw=numcit], ///
			by(ones) saving(`citweights', replace)                       // (3)
  
  xcollapse (sd) `vars', saving(`sds', replace)                          // (4)
  
  xcollapse   corp_patents = corp_inventor   ///
            home_state_pat = home_state_inventor [aw=numpat] if year!=2000, ///
			by(twentyyear) saving(`patweights_twentyyear', replace)      // (5)
  
  xcollapse      corp_cits = corp_inventor   ///
            home_state_cit = home_state_inventor [aw=numcit] if year!=2000, ///
			by(twentyyear) saving(`citweights_twentyyear', replace)      // (6)
  
  collapse `vars'  (count) N = inv_id if year != 2000, by(twentyyear)    // (7)
  
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
 
  local vlist2 "corp_patents home_state_pat corp_cits home_state_cit N"
  foreach var of varlist `vars' `vlist2'{
	 rename `var' v`var'
  }
		
  reshape long v, i(twentyyear) j(variable)   string
  reshape wide v, i(variable)   j(twentyyear) string
	
  label var v40 "1940-59" 
  label var v60 "1960-79"
  label var v80 "1980-99"
  label var vMean "Mean"
  label var vSD "S.D.
  order variable vMean vSD v40 v60 v80
	
  foreach var of varlist vMean-v80 {
	 replace `var' = `var'/1000000  if variable == "N"
  }
  replace variable = "N (millions)" if variable == "N"
	
  format vMean-v80 %6.3f
}  //---------------------------------【over01】---------------
 
* 个体创新产出、个人所得税和公司所得税。

  browse
  
  save "individual_sumstatistic.dta", replace

* ------------------------- sample composition --------------------
 
* 至此，我们已经得到了 Table 1 中的所有统计量的描述性统计结果。
* 但为了更好地与 Table 1 中的变量名称相对应，我们对上述结果进行适当地修饰。

  use "state_sumstatistic.dta", clear         // State-level    summary
  append using "individual_sumstatistic.dta"  // inventor-level summary

// !!!      执行方法：选中 [begin02]-[over02] 之间的代码，一次性执行
qui{      //------------------------------------------------------begin02-----

* Inventor-level data: outcomes
  gen order = 1 if variable == "numpat"
  replace order = 2 if variable == "has_pat3yr"
  replace order = 3 if variable == "numcit"
  replace order = 4 if variable == "has10cit_3yr"
	
* Inventor-level data: Taxes
  replace order = 5 if variable == "eff_tax"
  replace order = 6 if variable == "top_corp_lag3"
  replace order = 7 if variable == "N (millions)"
	
* State-level data: unlogged core outcomes
  replace order = 8  if variable == "num_patents"
  replace order = 9  if variable == "num_inventors"
  replace order = 10 if variable == "num_citations"
  replace order = 11 if variable == "share_assigned"
	
* State-level data: Taxes
  replace order = 12 if variable == "mtr90"
  replace order = 13 if variable == "mtrs90"
  replace order = 14 if variable == "mtr50"
  replace order = 15 if variable == "mtrs50"
  replace order = 16 if variable == "progressivity"
  replace order = 17 if variable == "top_corp"
  replace order = 18 if variable == "top_corp_state"
  replace order = 19 if variable == "rd_credit"
  replace order = 20 if variable == "N"
	
* Sample composition
  replace order = 21 if variable == "corp_patents"
  replace order = 22 if variable == "home_state_pat"
  replace order = 23 if variable == "corp_cits"
  replace order = 24 if variable == "home_state_cit"
  replace order = 25 if variable == "corp_inventor"
  replace order = 26 if variable == "home_state_inventor"
	
* Sort the table to have the right row order
  sort order
  drop order
	
* Micro variables
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
  replace variable = "\% Corporate Inventor"   if variable == "corp_inventor"
  replace variable = "\% Home-State Inventor"  if variable == "home_state_inventor"
  replace variable = "\% Corporate Patent"     if variable == "corp_patents"
  replace variable = "\% Home-State Patent"    if variable == "home_state_pat"
  replace variable = "\% Corporate Citations"  if variable == "corp_cits"
  replace variable = "\% Home-State Citations" if variable == "home_state_cit"
  
}         //------------------------------------------------------over02-----
  
 browse
 
 
*->>>> 输出到 Excel 表格 <<<<

  export excel using "Table1.xlsx", firstrow(varlabels) keepcellfmt replace 
  
  *| Note: 选中 Excel 中的内容: 右击-设置单元格属性-数字-小数点后两位 
  
  * Note: 亦可进一步使用 excel2latex 命令转换成 LaTeX 格式
                                                              /*
  . lianxh Stata转Excel 变身LaTeX表格  // 推文
                                                              */
  
 save "Table1.dta", replace
 
*---------------------------------------------------Table 1 end-----------

. list, noobs clean

/*
                              variable   vMean    vSD     v40    v60    v80
---------------------------------------------------------------------------
                     \# annual patents    0.68   1.10    0.63   0.65   0.73
           Pr\{Has patent in 3 years\}    0.70   0.46    0.66   0.70   0.72
                   \# annual citations   16.87  98.71    5.60   7.06  27.74
    Pr\{Has 10+ citations in 3 years\}    0.42   0.49    0.30   0.34   0.52
           Effective marginal tax rate    0.23   0.08    0.16   0.24   0.25
                     Top corporate MTR    0.45   0.08    0.42   0.52   0.43
                          N (millions)    6.21      .    1.32   1.85   3.04
                     \# Patents (000s)    1.02   1.62    0.75   0.97   1.35
                   \# Inventors (000s)    1.07   1.79    0.65   0.98   1.59
                   \# Citations (000s)   21.00  63.33    6.68  10.32  45.99
Share Patents Assigned to Corporations    0.66   0.18    0.53   0.71   0.74
       90$^{th}$ Percentile Income MTR    0.34   0.10    0.23   0.38   0.40
 90$^{th}$ Percentile Income State MTR    0.04   0.03    0.02   0.04   0.05
                     Median Income MTR    0.22   0.05    0.18   0.24   0.23
               Median Income State MTR    0.03   0.03    0.01   0.03   0.05
   Ratio of 90th/50th Income State MTR    1.58   0.34    1.32   1.60   1.80 
                     Top Corporate MTR    0.46   0.07    0.45   0.51   0.42
               Top State Corporate MTR    0.05   0.03    0.03   0.05   0.07
   R\&D Tax Credit (percentage points)    0.46   1.93    0.00   0.00   1.37
                          Observations    2880      .     960    960    960
                   \% Corporate Patent    0.86      .    0.75   0.86   0.90
                  \% Home-State Patent    0.86      .    0.86   0.87   0.85
                \% Corporate Citations    0.91      .    0.73   0.85   0.94
               \% Home-State Citations    0.84      .    0.87   0.87   0.84
                 \% Corporate Inventor    0.83   0.37    0.70   0.84   0.89
                \% Home-State Inventor    0.85   0.35    0.86   0.85   0.85
*/








*======================================
*--------
*-Table2 ：Benchmark estimation and IV strategy   >>>>>>>>>>>>>>>>>>>>>
*--------
*======================================
	
* 数据: state_data.dta
* 删除存在离群值的州：Louisiana，Alaska，Hawaii，以及州简称存在缺失值的州，
* 样本区间：1940-2000 年

  local minyear = 1940
  local maxyear = 2000 
  use "$D/state_data" if inrange(year,`minyear' - 1,`maxyear') & ///
                         !inlist(stateabbr,"","HI","AK","LA"), clear
  
  xtset statenum year
  
* common settings   
  global Tax   "mtr90_lag3 top_corp_lag3"
  global Xvars "L.real_gdp_pc L.population_density rd_credit_lag3"
  global Xmore "base_index_lag3 c.base_index_lag3#c.top_corp_lag3"

  global FE2 "absorb(statenum year)"               // Fixed effecs
  global se2 "vce(cluster statenum_fiveyear year)" // clustered SE
  
  *   Y = Tax + Xvars + Xmore + State_FE + Year_FE + u
  
* 作者提供的是所得税税率，我们按照文中公式 (3) 转变为所得税净税率

  local taxvariables  "$Tax mtr_inclag5_statelag590_lag3  top_corp_instrument_lag3"
  foreach var of varlist `taxvariables' {
	  cap replace `var' = ln(1-`var'/100)
  }
  
*-Note: 构建聚类标准误的思路：reg y x , vce(cluster statenum_fiveyear)
* o 首先，将研究期间每隔五年分为一类；
* o 其次，将每一个州每隔五年期间划分为一组，
*         目的是控制特定州的时间维度序列相关性和特定时间州之间的空间相关性
*   其余表格采用这种聚类标准误的目的一致。

  gen fiveyear = 5*floor(year/5)
  egen statenum_fiveyear = group(statenum fiveyear)
		  
*********************
*  Part A: Benchmark
*********************

  reghdfe lnpat $Tax $Xvars  [aw=pop1940], $FE2 $se2
  est store Tab2_A_1
  sum lnpat [aw=pop1940] if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar   se   = r(sd)
 
  reghdfe lncit $Tax $Xvars  [aw=pop1940], $FE2 $se2
  est store Tab2_A_2
  sum lncit [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar   se   = r(sd)
 
  reghdfe ln_inv $Tax $Xvars  [aw=pop1940], $FE2 $se2
  est store Tab2_A_3
  sum ln_inv [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar   se   = r(sd)
  
  *-share_assigned: share of patents assigned to companies
  reghdfe share_assigned $Tax $Xvars  [aw=pop1940], $FE2 $se2
  est store Tab2_A_4
  sum share_assigned [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar   se   = r(sd)

*-结果输出  
  local s "using Table2.csv" //执行时选中此行输出 Excel 表格,否则只显示于屏幕
  local m "Tab2_A_1 Tab2_A_2 Tab2_A_3 Tab2_A_4"
  local keep  "$Tax" //呈现于表格中的变量
  local title "Table2 Part A"
  esttab `m' `s', title("`title'") keep(`keep') ///
      coeflabels(   mtr90_lag3 "ln(1-MTR90)"    ///
	             top_corp_lag3 "ln(1-co.MTR)"   ///
			base_index_lag3 "Tax base index"    ///
            c.base_index_lag3#c.top_corp_lag3 "Base index * ln(1-co.MTR)") ///
	  se noconstant obslast stats(mean se)      ///
	  star(* 0.10 ** 0.05 *** 0.01) replace

/*Table2 Part A
--------------------------------------------------------------------
                  (1)         (2)             (3)             (4)   
                lnpat       lncit          ln_inv    share_assi~d   
--------------------------------------------------------------------
ln(1-MTR90)     1.803***    1.516***        1.784***       0.0558   
              (0.450)     (0.507)         (0.427)        (0.0714)   

ln(1-co.MTR)    2.759***    2.382***        2.308***        0.573***
              (0.701)     (0.770)         (0.640)         (0.141)   
--------------------------------------------------------------------
mean            7.067       9.650           7.084           0.720   
se              1.330       1.562           1.344           0.144   
--------------------------------------------------------------------*/
	  
	  
*******************************
*  Part B: Additional controls
*******************************

* Part B 中根据作者原始 dofile 计算的标准误小于文章提供的结果。

  *-新增了 $Xmore
  
  reghdfe lnpat $Tax $Xvars $Xmore  [aw=pop1940], $FE2 $se2
  est store Tab2_B_1
  sum lnpat [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
 
  reghdfe lncit $Tax $Xvars $Xmore  [aw=pop1940], $FE2 $se2
  est store Tab2_B_2
  sum lncit [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
 
  reghdfe ln_inv $Tax $Xvars $Xmore [aw=pop1940], $FE2 $se2
  est store Tab2_B_3
  sum ln_inv [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe share_assigned $Tax $Xvars $Xmore  [aw=pop1940], $FE2 $se2
  est store Tab2_B_4
  sum share_assigned [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
 
*-结果输出
  local s "using Table2.csv" //执行时选中此行输出 Excel 表格,否则只显示于屏幕
  local m "Tab2_B_1 Tab2_B_2 Tab2_B_3 Tab2_B_4"
  local keep  "$Tax base_index_lag3 c.base_index_lag3#c.top_corp_lag3" 
  local title "Table2 Part B"
  esttab `m' `s', title("`title'") keep(`keep') ///
      coeflabels(   mtr90_lag3 "ln(1-MTR90)"    ///
	             top_corp_lag3 "ln(1-co.MTR)"   ///
			base_index_lag3 "Tax base index"    ///
            c.base_index_lag3#c.top_corp_lag3 "Base index * ln(1-co.MTR)") ///
	  se noconstant obslast stats(mean se)      ///
	  star(* 0.10 ** 0.05 *** 0.01) append

/*Table2 Part B
-------------------------------------------------------------------
                 (1)         (2)             (3)             (4)   
               lnpat       lncit          ln_inv    share_assi~d   
-------------------------------------------------------------------
ln(1-MTR90)    1.967***    1.628***        1.896***        0.195***
              (0.391)     (0.466)         (0.383)         (0.0582)   

ln(1-co.MTR)   2.376***    2.307***        2.051***        0.341** 
              (0.733)     (0.830)         (0.681)         (0.128)   

Tax base i~x   0.173**     0.196**         0.216***       0.0230*  
              (0.0825)    (0.0942)        (0.0781)       (0.0122)   

Base ..MTR)    0.220*      0.198           0.279**        0.0261   
              (0.124)     (0.140)         (0.119)        (0.0183)   
-------------------------------------------------------------------
mean           7.171       9.862           7.236           0.760   
se             1.280       1.520           1.292           0.108   
-------------------------------------------------------------------*/
	  
	  
************************
*  Part C IV strategy
************************

* 工具变量-FE-SE 设定
  * >>>>> 请先执行下面三行 >>>>
  global IVs_tab2 "mtr_inclag5_statelag590_lag3   top_corp_instrument_lag3"
  global FEst     "i.statenum i.year"
  global sest     "cluster(statenum_fiveyear year)"

* IV
  des $IVs_tab2  
  
* IV reg (2SLS + HDFE)  
  ivreg2 lnpat  ($Tax = $IVs_tab2) $Xvars $FEst [aw=pop1940], first $sest
  est store Tab2_C_1
  sum lnpat [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  ivreg2 lncit  ($Tax = $IVs_tab2) $Xvars $FEst [aw=pop1940], first $sest
  est store Tab2_C_2
  sum lncit [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  ivreg2 ln_inv ($Tax = $IVs_tab2) $Xvars $FEst [aw=pop1940], first $sest
  est store Tab2_C_3
  sum ln_inv [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  ivreg2 share_assign ($Tax = $IVs_tab2) $Xvars $FEst [aw=pop1940], first $sest
  est store Tab2_C_4
  sum share_assigned [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
*-结果输出
  local s "using Table2.csv" //执行时选中此行输出 Excel 表格,否则只显示于屏幕
  local m "Tab2_C_1 Tab2_C_2 Tab2_C_3 Tab2_C_4"
  local keep  "$Tax" //呈现于表格中的变量
  local title "Table2 Part C"
  esttab `m' `s', title("`title'") keep(`keep') ///
      coeflabels(   mtr90_lag3 "ln(1-MTR90)"    ///
	             top_corp_lag3 "ln(1-co.MTR)")  ///
	  se noconstant obslast stats(mean se)      ///
	  star(* 0.10 ** 0.05 *** 0.01) append

/*Table2 Part C
----------------------------------------------------------------
                  (1)        (2)          (3)             (4)   
                lnpat      lncit       ln_inv    share_assi~d   
----------------------------------------------------------------
ln(1-MTR90)     2.294**    1.976*       2.281**        -0.173   
              (0.956)    (1.083)      (0.893)         (0.150)   

ln(1-co.MTR)    3.540***   2.793***     3.015***        0.665***
              (0.943)    (1.047)      (0.866)         (0.208)   
----------------------------------------------------------------
mean            7.067                   7.084           0.720   
se              1.330                   1.344           0.144   
----------------------------------------------------------------*/
	  
/*
*-说明：随后可以使用 ivreghdfe 命令，更简洁更快，但目前有点小问题
  help ivreghdfe 
  ivreghdfe lnpat ($Tax = $IVs_tab2) $Xvars [aw=pop1940], ///
            first $FE2 cluster(statenum_fiveyear year)	 
*/  
	  
	  

*======================================
*--------
*-Figure1 ：Binned Scatter
*--------
*======================================

*-目的：可视化呈现多元线性回归的系数
*
*   >>>> 基于 FWL 定理，呈现 lny 和 lnx 之间的「干净」关系
*
* (1) 分别用 [个人所得税 Tp] 和 [公司所得税 Tc] 对控制变量回归，得到残差项
* (2) 分别用 [专利数量 Q1] 和 [发明家人数 Q2] 对控制变量回归，得到残差项
*   注意：专利申请数和发明家人数的残差有如下四种模型组合获得，共四个
* Fig1A: 专利申请数对个人所得税回归，控制公司税；    reg lnQ1 Tp | Tc --> eA 
* Fig1B: 专利申请数对公司所得税回归，控制个人税；    reg lnQ1 Tc | Tp --> eB
* Fig1C: 发明家人数对个人所得税进行回归，控制公司税  reg lnQ2 Tp | Tc --> eC
* Fig1D: 发明家人数对公司所得税进行回归，控制个人税  reg lnQ2 Tc | Tp --> eD
*
* (3) 计算散点值时，根据分位点进行分组，组内按照人口数量取加权
*   - 数据:state_data.dta
*   - 删除存在离群值的州：Louisiana, Alaska, Hawaii, PR，以及州简称缺失的州
*   - Range: 1940-2000 年

  local minyear = 1940
  local maxyear = 2000
  use "$D/state_data.dta" if inrange(year,`minyear'-1,`maxyear') & ///
                             !inlist(stateabbr,"LA","HI","AK","PR",""), clear
  xtset statenum year

  foreach var of varlist mtr90 top_corp {
	 replace `var'_lag3 = ln(1-`var'_lag3/100)
  }

*>>>> FWL 定理很重要，参见：
  . lianxh Waugh定理
  
*>>>> 有关 binscatter 介绍，参见：
  . help   binscatter
  . lianxh binscatter
  
  //Controls
  global cx "L.real_gdp_pc L.population_density rd_credit_lag3 i.statenum" 
  
  global T_p "mtr90_lag3"    // 个人税
  global T_c "top_corp_lag3" // 公司税
  
  binscatter lnpat    $T_p  [aw=pop1940],     ///
             controls($T_c $cx)               ///
             absorb(year) nquantiles(100)     ///
			 noaddmean                        ///
			 nofastxtile                      ///
			 savegraph("Fig1A.gph") replace

  binscatter lnpat    $T_c  [aw=pop1940],     ///
             controls($T_p $cx)               ///
             absorb(year) nquantiles(100)     ///
			 noaddmean                        ///
			 nofastxtile                      ///
			 savegraph("Fig1B.gph") replace
			 			 
  binscatter ln_inv   $T_p  [aw=pop1940],     ///
             controls($T_c $cx)               ///
             absorb(year) nquantiles(100)     ///
			 noaddmean                        ///
			 nofastxtile                      ///
			 savegraph("Fig1C.gph") replace		 
			 
  binscatter ln_inv   $T_c  [aw=pop1940],     ///
             controls($T_p $cx)               ///
             absorb(year) nquantiles(100)     ///
			 noaddmean                        ///
			 nofastxtile                      ///
			 savegraph("Fig1D.gph") replace		
			 
  *-组合图片
    graph combine Fig1A.gph Fig1B.gph Fig1C.gph Fig1D.gph, ///
          rows(2) imargin(zero) graphregion(fcolor(white))
  
  *-输出为 png 格式
    graph export "Fig1.png", replace width(1200)
  
  
*>>>>>>>>>>-------- 讨论 --------begin--<<<<<<<<<<<
*-其他设定：TWFE, RD

*--- TWFE: absorb(statenum year) - 以 Fig1D 为例
*          lny = lnx + controls + State_i + Year_t 
  binscatter ln_inv   $T_c  [aw=pop1940],     ///
             controls($T_p $cx  i.year)       ///  //New: i.year
             absorb(statenum) nquantiles(100) ///  //New: statenum
			 noaddmean                        ///
			 nofastxtile                      ///
			 savegraph("Fig1D-1.gph") replace  
			 
*--- 分段, n(40)
  local y "ln_inv"
  *local y "lnpat"
  sum $T_c, d 
  binscatter `y'   $T_c  [aw=pop1940],     ///
             rd(`r(p50)'  `r(p75)')   ///  // NEW, RDD
             controls($T_p $cx)       ///  
             absorb(statenum) nquantiles(100) /// 
			 nofastxtile                       
 
  local y "ln_inv"
  local y "lnpat"
  sum $T_p, d 
  binscatter `y'   $T_p  [aw=pop1940],     ///
             rd(`r(p50)'  `r(p75)')   ///  // NEW, RDD
             controls($T_c $cx)       ///  
             absorb(statenum) nquantiles(40) /// 
			 nofastxtile   
 
*--- TWFE: absorb(statenum_fiveyear year)  // Table II 的设定  ???
  dropvars  fiveyear statenum_fiveyear
  gen fiveyear = 5*floor(year/5)
  egen statenum_fiveyear = group(statenum fiveyear)
  binscatter ln_inv   $T_c  [aw=pop1940],     ///
             rd(0)                            ///
             controls($T_p $cx )              /// //No: i.year
             absorb(statenum_fiveyear) n(100) /// //New: statenum_fiveyear 
			 noaddmean                        ///
			 nofastxtile                      ///
			 linetype(lfit)                   /// //可以试一下：qfit
			 savegraph("Fig1D-2.gph") replace    		 
  *-Note: 此时结果反转了！！！ 
*>>>>>>>>>>-------- 讨论 --------over--<<<<<<<<<<<  

  
*------------------->> 作者的代码 <<----------------begin------
*                       可以忽略
*
* Note: 便于理解原理，可以根据需要做多种设定
*       多数情况下，binscatter 都能满足需要		

  local minyear = 1940
  local maxyear = 2000
  use "$D/state_data.dta" if inrange(year,`minyear'-1,`maxyear') & ///
                             !inlist(stateabbr,"LA","HI","AK","PR",""), clear
  xtset statenum year

  foreach var of varlist mtr90 top_corp {
	 replace `var'_lag3 = ln(1-`var'_lag3/100)
  }
  
* 获得个人所得税和公司所得税的残差
  //Controls
  global cx "L.real_gdp_pc L.population_density rd_credit_lag3 i.statenum" 
*-解释变量残差  
  areg mtr90_lag3 top_corp_lag3 $cx [aw=pop1940], a(year)
  predict mtr90_resids_weighted, residuals // 个人所得税残差
  
  areg top_corp_lag3 mtr90_lag3 $cx [aw=pop1940], a(year)
  predict top_corp_resids_weighted, residuals // 公司所得税残差
  
* 获得被解释变量专利申请数和发明家定居数的残差

  areg lnpat top_corp_lag3  $cx  [aw=pop1940], a(year)
  predict lnpat_resids_top_corp, residuals //figure 1A 的被解释变量
  
  areg lnpat mtr90_lag3     $cx  [aw=pop1940], a(year)
  predict lnpat_resids_mtr90, residuals // figure 1B 的被解释变量
  
  areg ln_inv top_corp_lag3 $cx  [aw=pop1940], a(year)
  predict ln_inv_resids_top_corp, residuals // figure 1C 的被解释变量

  areg ln_inv mtr90_lag3    $cx  [aw=pop1940], a(year)
  predict ln_inv_resids_mtr90, residuals // figure 1D 的被解释变量
			
* 获得 figure 1A, Figure 1B, Figure 1C, Figure 1D 的系数值

  reg  lnpat_resids_top_corp     mtr90_resids_weighted
  
  reg  lnpat_resids_mtr90     top_corp_resids_weighted
  
  reg  ln_inv_resids_top_corp    mtr90_resids_weighted
  
  reg  ln_inv_resids_mtr90    top_corp_resids_weighted
 
  
* 计算个人所得税和公司所得税残差的分位数，构造分组变量

  xtile    tax_pctiles_mtr90 = mtr90_resids_weighted, nq(100)
  xtile tax_pctiles_top_corp = top_corp_resids_weighted, nq(100)
 
* 在计算图中散点值时，我们需要根据分组变量进行分组，然后组内根据人口数量进行加权
* 获取。

* -Figure1A-

preserve
  collapse lnpat_resids_top_corp mtr90_resids_weighted [aw=pop1940],  ///
           by(tax_pctiles_mtr90) fast
  #d ; 
  twoway (scatter lnpat_resids_top_corp mtr90_resids_weighted, msize(large)) 
		 (lfit    lnpat_resids_top_corp mtr90_resids_weighted, 
		          lw(medthick) lc(black)), 
		 graphregion(color(white)) legend(off) 
		 ytitle("Residualized Log Patents") 
		 xtitle("Residualized Combined Marginal Tax Rate for 90th percetile");
  #d cr	 
  graph save Figure1A, replace
restore
  
* -Figure1B-
preserve
  collapse lnpat_resids_mtr90 top_corp_resids_weighted [aw=pop1940],  ///
           by(tax_pctiles_top_corp) fast
  #d ; 
  twoway (scatter lnpat_resids_mtr90 top_corp_resids_weighted, msize(large)) 
		 (lfit    lnpat_resids_mtr90 top_corp_resids_weighted, 
		          lw(medthick) lc(black)), 
		 graphregion(color(white)) legend(off) 
		 ytitle("Residualized Log Patents") 
		 xtitle("Residualized Top Combined Federal + State Tax Rate (%)");
  #d cr	 
  graph save Figure1B, replace
restore
  
* -Figure1C-
preserve
  collapse ln_inv_resids_top_corp mtr90_resids_weighted [aw=pop1940],  ///
           by(tax_pctiles_mtr90) fast
  #d ;    
  twoway (scatter ln_inv_resids_top_corp mtr90_resids_weighted, msize(large)) 
		 (lfit    ln_inv_resids_top_corp mtr90_resids_weighted, 
		          lw(medthick) lc(black)), 
		 graphregion(color(white)) legend(off) 
		 ytitle("Residualized Log Inventor") 
		 xtitle("Residualized Combined Marginal Tax Rate for 90th percetile");
  #d cr	 
  graph save Figure1C, replace
restore
  
* -Figure1D-
preserve
  collapse ln_inv_resids_mtr90 top_corp_resids_weighted [aw=pop1940],  ///
           by(tax_pctiles_top_corp) fast
  #d ; 
  twoway (scatter ln_inv_resids_mtr90 top_corp_resids_weighted, msize(large)) 
		 (lfit    ln_inv_resids_mtr90 top_corp_resids_weighted, 
		          lw(medthick) lc(black)), 
		 graphregion(color(white)) legend(off) 
		 ytitle("Residualized Log Inventor") 
		 xtitle("Residualized Top Combined Federal + State Tax Rate (%)");
  #d cr 
  graph save Figure1D, replace
restore
  
*-组合图片
  graph combine Figure1A.gph Figure1B.gph Figure1C.gph Figure1D.gph, ///
        rows(2) imargin(zero) graphregion(fcolor(white))
  
*-输出为 png 格式
  graph export "Figure1.png", replace width(1200) 
  
* 查看结果

  shellout "Figure1.png"
  
*--------Figure1----------->> 作者的代码 <<----------------over------
	  
	  
	  
	  
	  
 
********************************************
*  Figure2 : IV 的合理性 (or relationship)
********************************************

* 目的: 检验联邦税率的变动是否会导致预测税率 ( eq.(6) 和 (7)) 的变动
*       或曰：联邦税率是否是一个好的工具变量 ？
* 
* 绘制 Figure2 时需要构建联邦税率变动和工具变量 (mtr_inclag5_statelag550 和 
* mtr_inclag5_statelag590) 的变动。
* 由于 Figure2 是检验工具变量的有效性，我们对正文图形呈现次序进行了调整，将其放到
* Figure1 之前展示。
	
* mtr_inclag5_statelag550 和 mtr_inclag5_statelag590 是根据文中公式 (6) 的工具
* 变量。
* 这里需要计算 Figure2 中所需要的工具变量变动率。

  local minyear = 1940
  local maxyear = 2000
  use "$D/state_data.dta" if inrange(year,`minyear'-1,`maxyear') & ///
                             !inlist(stateabbr,"LA","HI","AK","PR",""), clear
  xtset statenum year
  
*>>> 回顾: x 和 IVs 的相关性
  global Tax      "mtr90_lag3 top_corp_lag3" // 内生变量 X
  global IVs_tab2 "mtr_inclag5_statelag590_lag3   top_corp_instrument_lag3" 
  
  fsum  $Tax  $IVs_tab2, label f(%6.1f)
  corr mtr90_lag3  mtr_inclag5_statelag590_lag3 // corr(x, IV), 个税
  corr top_corp_lag3   top_corp_instrument_lag3 // corr(x, IV), 公司税
  
  local taxvariables  "$Tax mtr_inclag5_statelag590_lag3  top_corp_instrument_lag3"
  foreach var of varlist `taxvariables' {
	  cap replace `var' = ln(1-`var'/100)
  }  
  
  
*---------------------------  
*>>>>> 绘制 Fig 2 - 数据处理  --------一起选中，一直执行到 ------ over-2----
*
 gen iv_change_5_550 = mtr_inclag5_statelag550 - L.mtr_inclag5_statelag550
 gen iv_change_5_590 = mtr_inclag5_statelag590 - L.mtr_inclag5_statelag590
		
* 取工具变量变动率的   第90分位点, 第10分位点, 以及标准差，
* 并将其保存在临时文件 p90.dta,    p10.dta       和 sd.dta。
  
  preserve
	 collapse (p90) iv_change_5_550 iv_change_5_590, by(year)
	 foreach var of varlist iv_change_5_550 iv_change_5_590 {
	 	rename `var' `var'_pctile90
	 	}
	 tempfile p90
	 save `p90'
  restore
	
  preserve 
     collapse (p10) iv_change_5_550 iv_change_5_590, by(year)
     foreach var of varlist iv_change_5_550 iv_change_5_590 {
        rename `var' `var'_pctile10
     }
	 tempfile p10
     save `p10'
  restore

  preserve
     collapse (sd) iv_change_5_550 iv_change_5_590, by(year)
     foreach var of varlist iv_change_5_550 iv_change_5_590 {
	      rename `var' `var'_sd
     }
	 tempfile sd
     save `sd'
  restore
	
* 生成联邦税率的变动率，并取分年度取均值

  gen FedTax_pers50_change = (mtrfb50 - L.mtrfb50) 
  gen FedTax_pers90_change = (mtrfb90 - L.mtrfb90) 
  collapse (mean) FedTax_pers50_change FedTax_pers90_change, by(year)

* 合并文件

  merge 1:1 year using `p90', nogen
  merge 1:1 year using `p10', nogen
  merge 1:1 year using `sd' , nogen


  foreach var in iv_change_5_550 iv_change_5_590 {
	  gen `var'_range = `var'_pctile90 - `var'_pctile10
  }
	
  keep if inrange(year,1940,2000)
  
*>>>>> 绘制 Fig 2 - 数据处理  ------------------------------ over-2----  
*----------------------------
   
* - Figure 2A -
  
  #delimit ;
  twoway (bar FedTax_pers90_change year, color(gs4) fintensity(50) lw(none))
		 (scatter iv_change_5_590_pctile10 year, connect(direct) mc(black) 
		  msize(small) msymbol(circle) lc(black) lw(medium) lp(solid))
		 (scatter iv_change_5_590_pctile90 year, connect(stairstep) mc(blue) msize(
		  small) msymbol(square) lc(blue) lw(medium) lp(dash) ),
		  graphregion(color(white)) xtitle("")
		  ytitle("Percentage Points")
		  xlabel(1940(10)2000) xmtick(1940(5)2000,grid)
		legend(label(1 "Statutory Change in Federal Personal Tax 
		                Rate for 90th pctile (% points)") 
		       label(2 "10th pctile of Change in Personal Tax Rate Instrument") 
			   label(3 "90th pctile of Change in Personal Tax Rate Instrument") 
			   row(3) pos(6) symxsize(*.3));
   #delimit cr

  graph export Figure2A.png, replace
	
* - Figure 2B -

  #delimit ;
  twoway (bar FedTax_pers50_change year, color(gs4) fintensity(50) lw(none))
		 (scatter iv_change_5_550_pctile10 year, connect(direct) mc(black) msize(
		  small) msymbol(circle) lc(black) lw(medium) lp(solid) )
		 (scatter iv_change_5_550_pctile90 year, connect(stairstep) mc(blue) msize(
		  small) msymbol(square) lc(blue) lw(medium) lp(dash)),
		  graphregion(color(white)) xtitle("")  
		  ytitle("Percentage Points")
		  xlabel(1940(10)2000) xmtick(1940(5)2000,grid)
	     legend(label(1 "Statutory Change in Federal Personal Tax Rate 
	                     for 50th pctile (% points)") 
	    		label(2 "10th pctile of Change in Personal Tax Rate Instrument") 
	    		label(3 "90th pctile of Change in Personal Tax Rate Instrument") 
	    		row(3) pos(6) symxsize(*.3));
  #delimit cr
  
  graph export Figure2B.png, replace
  
*-查看全部结果

  shellout Table2.csv
  shellout Figure2A.png
  shellout Figure2B.png

*-------------------------------------------------Table2 end--------------










*======================================
*--------
*-Table3 ：long-difference model         <<<<<<<<<<<<<
*--------
*======================================

* 作者原始 dofile 在调入数据时多删除了 PR 州，因而导致结果与文中存在差异。
* 下面命令已对其进行修改，结果与文中一致。
* 我们使用 state_data.dta，删除存在离群值的州：Louisiana，Alaska 和 Hawaii，
* 以及州简称为缺失值的州，并且限定研究区间为 1939-2000 年。

  local minyear = 1940
  local maxyear = 2000
  use "$D/state_data" if inrange(year,`minyear' - 1,`maxyear')  ///
                         & !inlist(stateabbr,"","HI","AK","LA"), clear
  xtset statenum year
	
  gen mibaseindex = mi(base_index)
  replace base_index = 0 if mi(base_index)
  
* 生成差分变量

  foreach var of varlist mtr90 top_corp {
     foreach num of numlist 10 15 20 {
	    gen delta_`var'_`num' = ln(1-`var'/100) - ln(1-L`num'.`var'/100)
	 }
  }
  
  foreach var of varlist lnpat lncit ln_inv share_assigned {
     foreach num of numlist 10 15 20 {
        gen delta_`var'_`num' = `var' - L`num'.`var'
	 }
  }

* 生成滞后的控制变量

  gen popdens_lag1 = L.population_density
  gen gdppc_lag1 = L.real_gdp_pc
  global controls gdppc_lag1 popdens_lag1 rd_credit_lag3 base_index
  
  foreach num of numlist 10 15 20 {
     foreach var of varlist $controls {
	    gen delta_`var'_`num' = `var' - L`num'.`var'
	 }
  }
  
  global LD_cx_20   delta_gdppc_lag1_20 delta_popdens_lag1_20   ///
                    delta_rd_credit_lag3_20 delta_base_index_20
  
  global LD_cx_15   delta_gdppc_lag1_15 delta_popdens_lag1_15   ///
                    delta_rd_credit_lag3_15 delta_base_index_15
  
  global LD_cx_10   delta_gdppc_lag1_10 delta_popdens_lag1_10   ///
                    delta_rd_credit_lag3_10 delta_base_index_10
	
* 生成聚类类别，具体查看 Table 2 

  gen fiveyear = 5*floor(year/5)
  egen state5year = group(statenum fiveyear)
  
********************
*  Part A k = 20
********************
  global ifw "if year>=1940  [aw=pop1940]"
  global opt "absorb(year)  vce(cluster year)"
  
  reghdfe delta_lnpat_20 delta_mtr90_20 delta_top_corp_20  $LD_cx_20 $ifw, $opt
  est store Tab3_A_1
  sum delta_lnpat_20 [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe delta_lncit_20 delta_mtr90_20 delta_top_corp_20  $LD_cx_20 $ifw, $opt
  est store Tab3_A_2
  sum delta_lncit_20 [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe delta_ln_inv_20 delta_mtr90_20 delta_top_corp_20  $LD_cx_20 $ifw, $opt
  est store Tab3_A_3
  sum delta_ln_inv_20 [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe delta_share_assigned_20 delta_mtr90_20 delta_top_corp_20  ///
          $LD_cx_20 $ifw, $opt
  est store Tab3_A_4
  sum delta_share_assigned_20 [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  esttab Tab3_A_1 Tab3_A_2 Tab3_A_3 Tab3_A_4 using "Table3.csv", ///
         keep(delta_mtr90_20 delta_top_corp_20) ///
         coeflabels(   delta_mtr90_20 "delta_ln(1-MTR90)"   ///
                    delta_top_corp_20 "delta_ln(1-co.MTR)") ///
         se noconstant obslast stats(mean se) ///
         title ("Table3 Part A")       ///
         star(* 0.10 ** 0.05 *** 0.01) ///
         replace
  
********************
*  Part B k = 15
********************
 
  reghdfe delta_lnpat_15 delta_mtr90_15 delta_top_corp_15  $LD_cx_15 $ifw, $opt
  est store Tab3_B_1
  sum delta_lnpat_15 [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe delta_lncit_15 delta_mtr90_15 delta_top_corp_15  $LD_cx_15 $ifw, $opt
  est store Tab3_B_2
  sum delta_lncit_15 [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe delta_ln_inv_15 delta_mtr90_15 delta_top_corp_15  $LD_cx_15 $ifw, $opt
  est store Tab3_B_3
  sum delta_ln_inv_15 [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe delta_share_assigned_15 delta_mtr90_15 delta_top_corp_15  ///
          $LD_cx_15 $ifw, $opt
  est store Tab3_B_4
  sum delta_share_assigned_15 [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  esttab Tab3_B_1 Tab3_B_2 Tab3_B_3 Tab3_B_4 using "Table3.csv", ///
         keep(delta_mtr90_15 delta_top_corp_15) ///
         coeflabels   (delta_mtr90_15 "delta_ln(1-MTR90)"   ///
                    delta_top_corp_15 "delta_ln(1-co.MTR)") ///
         se noconstant obslast stats(mean se) ///
         title ("Table3 Part B")       ///
         star(* 0.10 ** 0.05 *** 0.01) ///
         append
  
********************
*  Part C k = 10
********************
 
  reghdfe delta_lnpat_10 delta_mtr90_10 delta_top_corp_10  $LD_cx_10 $ifw, $opt
  est store Tab3_C_1
  sum delta_lnpat_10 [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe delta_lncit_10 delta_mtr90_10 delta_top_corp_10  $LD_cx_10 $ifw, $opt
  est store Tab3_C_2
  sum delta_lncit_10 [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe delta_ln_inv_10 delta_mtr90_10 delta_top_corp_10  $LD_cx_10 $ifw, $opt
  est store Tab3_C_3
  sum delta_ln_inv_10 [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe delta_share_assigned_10 delta_mtr90_10 delta_top_corp_10  ///
          $LD_cx_10 $ifw, $opt
  est store Tab3_C_4
  sum delta_share_assigned_10 [aw=pop1940] if e(sample)==1
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  esttab Tab3_C_1 Tab3_C_2 Tab3_C_3 Tab3_C_4 using "Table3.csv", ///
         keep(delta_mtr90_10 delta_top_corp_10) ///
         coeflabels(    delta_mtr90_10 "delta_ln(1-MTR90)"  ///
                    delta_top_corp_10 "delta_ln(1-co.MTR)") ///
         se noconstant obslast stats(mean se) ///
         title ("Table3 Part C")       ///
         star(* 0.10 ** 0.05 *** 0.01) ///
         append
  
* 查看结果

 shellout "Table3.csv"
 
* ---------------------------------------------- Table3 end --------------








*======================================
*--------
*-Figure3 ：Event Study
*--------
*======================================

* Figure3 绘制的是所得税率发生较大变动 (10%) 对创新产出的动态影响。

* 核心思想：
* 是：(1) 搜索在1940-2000年之间，存在所得税较大变动的时点。以这些时点为新的处理组，
* 进行事件分析。(2) 但是，处理组的窗口期 (-4,4) 和控制组的窗口期存在交叠问题，因此
* 我们难以得到干净的控制组。(3) 因此，作者使用合成控制法，为每一个处理组估计一个“反
* 事实“处理组，并将其作为该处理组的控制组。
* 这样处理的好处是：(1) 能够避免处理组窗口期内无干净的控制组；(2) 提升处理组在样本
* 的占比。
* 注：因为 Figure3 设计到4张图形，共产生200多个的中间数据集。所以，为了
* 减少估计过程中对计算机内存的占用，我们采用设定临时文件的形式进行估计。

*>>>>>> 相关推文：
  . lianxh 事件研究 合成控制 回归控制 DID
  
  
*-Note: 由于需要数据合并，只载入必要的变量，以加快运行速率
  local xx "statenum stateabbr year lnpat ln_inv mtrs90 top_corp_state real_gdp_pc population_density"
  use `xx' using "$D/state_data" ///
      if !inlist(stateabbr,"LA","HI","AK","PR","DC"), clear
	
	gen lngdppc = ln(real_gdp_pc)
	
	label var mtrs90 "90th Pctile Marginal State Tax Rate"
	label var top_corp_state "State Top Corporate Tax Rate"
	tempfile statedata
	compress
	save `statedata', replace
	
* Step1: 搜寻税率变动超过 10% 的时点，并构建事件-时间面板数据
* 
*  (1) 筛选研究期间税率变动超过 10% 的时间点；
*  (2) 在得到的时点基础上，确保窗口期内不存在其他税率变动超过10%的时点；
*  (3) 构建事件-时间面板数据。

	foreach tax in mtrs90 top_corp_state {
		
		use statenum stateabbr year `tax' using "$D\state_data"  ///
		    if !inlist(stateabbr,"LA","HI","AK","PR","DC") ///
			& inrange(year,1939,2000), clear
			
		xtset statenum year
		
		* 重大变动：所得税税率上升 0.01，或者下降 0.01
		gen `tax'_change = `tax' - L.`tax'
		gen tax_lag = L.`tax'
		replace `tax'_change = 0 if abs(`tax'_change) < 0.01
		
		* 定义所得税率增加事件
		sum `tax'_change if `tax'_change > 0, detail
		gen byte large_inc_`tax' = `tax'_change >= r(p90) if !missing(`tax'_change)
		
		* 定义所得税率减少事件
		sum `tax'_change if `tax'_change < 0, detail
		local cutoff2 = 100 - 90
		gen byte large_dec_`tax' = `tax'_change <= r(p`cutoff2') if !missing(`tax'_change)
		
		* 保留所得税率变动超过 10% 的时间点
		keep if inlist(1,large_inc_`tax',large_dec_`tax')
		
		* 文中汇报的描述性统计结果
		gen abs_change = abs(`tax'_change)
		di "Distribution of tax change sizes"
		sum abs_change, detail
		
		di "Distribution of tax increase sizes"
		sum abs_change if large_inc_`tax' == 1, detail
		
		di "Distribution of tax cut sizes"
		sum abs_change if large_dec_`tax' == 1, detail
		
		* 定义在窗口期内 [-4, +4] 其他存在税率较大变动的时间点，
		* 以便挑选出干净事件
		bys statenum (year):                                         ///
		    gen byte tokeep = (year[_n-1] < year-4 | mi(year[_n-1])) ///
			                & (year[_n+1] > year+4 | mi(year[_n+1]))

		gen largechange = large_inc_`tax' - large_dec_`tax' 
		
		* 生成所得税率发生重大变动时间点
		keep statenum year largechange `tax'_change abs_change tokeep
		gen reformid = _n
		
		* 以每一个事件发生时点为基准，扩大 9 倍，构造一个事件-时间的面板数据。
		* 最终得到每一个事件个体均包含干预前和干预后时期。
		local k = 9 // 干预前4期，干预1期，干预后4期
		expand `k'
		sort reformid year
		
		* 生成相对时期虚拟变量
		bys reformid: gen rel_yr = _n- 4 - 1
		forvalues i = -4/4 {
			local j = `i' + 4 + 1
			replace year = year+`i' if rel_yr == `i' // 设定连续性时间，
			                                         // 用于合并数据
			gen rel_yr`j' = largechange*(rel_yr == `i')
			label var rel_yr`j' "`i'"
			}
		
		compress
		tempfile ES_data
		tempfile synth_output
		tempfile reforms
		save `reforms' // 将上述结果保存为 reforms.dta
		levelsof reformid, local(reformids) // 得到所得税税率变动时间
		
    * Step2: 使用合成控制法估计每一个事件的控制组，
	*        确保在每一个时间窗口期内都有一个干净的控制组。  
		foreach lhsvar in lnpat ln_inv {
			foreach reform in `reformids' {
				di "Reform `reform'"
				use `reforms', clear
				
				* 与 statedata.dta 合并，为合成控制法估计提供预测变量
				keep if reformid == `reform'
				
				merge m:1 statenum year using `statedata'
				
				* 与 reforms.dta 数据进行合并，
				* 确定在 statedata.dta 数据中哪一个是处理组
				merge 1:m statenum year using `reforms', gen(reform_merge)
				
				* 设定在事件发生时点，以及窗口期时间
				gen byte focal_reform = reformid == `reform'
				bys year: egen byte relevant_year = max(focal_reform)
				
				* 删除在窗口期内存在税率改革的时点，得到干净的控制组
				replace reform_merge = . if relevant_year == 0
				bys statenum (year): egen maxmerge = max(reform_merge)
				bys statenum (year): egen reform_state = max(focal_reform)
*				tab maxmerge reform_state
				drop if maxmerge == 3 & reform_state == 0
				
				* 删除样本存在时期重叠的观测值
				duplicates drop
				
				
				* 使用合成控制法估计处理组的“反事实”结果，
				* 并将其作为事件分析的控制组
				sum year if rel_yr == 0
				local tryear = r(mean)
				local minyear = `tryear' - 4
				local maxyear = `tryear' - 1
				sum statenum if focal_reform == 1
				local trunit = r(mean)
				keep if inrange(year,`minyear',`tryear' + 4)
				synth `lhsvar' `lhsvar' population_density lngdppc, ///
				      trunit(`trunit')             ///
					  trperiod(`tryear')           ///
					  keep(`synth_output') replace ///
					  mspeperiod(`minyear'/`maxyear')
				
				preserve
				    use `synth_output', clear
				    keep if !mi(_Y_synthetic)
				    rename _Y_synthetic `lhsvar'
				    rename _time year
				    keep year `lhsvar'
				    gen statenum = 0
				    compress
				    save `synth_output', replace
				restore
				
				keep if focal_reform == 1
				append using `synth_output'
				keep if inrange(year,`tryear' - 4,`tryear' + 4)
				
				foreach var of varlist rel_yr* `tax'_change {
					replace `var' = 0 if missing(`var')
					}
				replace rel_yr = year - `tryear'
					
				qui replace reformid = `reform'
				
				* 将 tokeep 变量的缺失值用其最大值进行替代，
				* 以保证每一个处理组都有对应的控制组
				bys reformid (statenum year): egen temp = max(tokeep)
				replace tokeep = temp if missing(tokeep)
				drop temp
		
				* 定义在合成处理组是所得税率增加个体，还是所得税率减少个体
				bys reformid (statenum year): egen temp = max(largechange)
				replace largechange = temp if missing(largechange)
				drop temp
				
				* 删除中间数据集
				drop maxmerge _merge reform_merge focal_reform
				qui compress
				cap append using `ES_data'
				save `ES_data', replace
				}
			keep if tokeep == 1
			drop tokeep
			
			* 生成处理组州
			gen byte treatment = statenum != 0
			
			replace rel_yr1 = 0 // 将初始时间标准化为零
			replace rel_yr4 = 0 // 将相对时间 t=-1 标准化为零
			
   * Step3: 使用得到的干净的控制组样本集进行事件分析
			sort statenum year  // 时间有重复值

			local label: var label `lhsvar'
			local taxlab: var label `tax'
            reghdfe `lhsvar' rel_yr1-rel_yr3 rel_yr4 rel_yr5-rel_yr`j', ///
			        absorb(reformid#treatment rel_yr) vce(cluster reformid)
			est store coef_plot
			estadd ysumm
			sum abs_change if e(sample)==1
			local elast4yr = -_b[rel_yr9]/r(mean)
			local elast4yr: di %4.1f `elast4yr'
 di "Elasticity for Unweighted Event Study `lhsvar', `taxvar' without Year FE:"
			di _b[rel_yr`j']/r(mean)

			* Figure3 四个子图的绘制
			#delimit ;
			coefplot (coef_plot, msymbol(triangle) mcolor(blue)),
					  keep(*rel_yr*) omitted
					  xtitle("Years Since Tax Reform", size(small)) vertical
					  legend(off) 
					  graphregion(color(white)) 
					  yline(0) 
					  xline(4, lp(dash))
					  ytitle("Effect of Large `taxlab'" "Increase on `label'", 
					  size(small))
					  ciopts(recast(rcap)) 
					  connect(direct) 
					  msymbol(diamond);
							
			#delimit cr
			
			graph save Figure3_`lhsvar'_`tax', replace
			}
		}

  graph combine Figure3_lnpat_mtrs90.gph Figure3_ln_inv_mtrs90.gph Figure3_lnpat_top_corp_state.gph Figure3_ln_inv_top_corp_state.gph, rows(2) imargin(zero) graphregion(fcolor(white))
  
  graph export Figure3.png, replace
  
* 查看结果

 shellout Figure3.png
 
*---------------------------------------------Figure3 end--------------
 
 
 
 
		
*======================================
*--------
*-Figure4 ：Lagged Distribution
*--------
*======================================
	
* 作者使用分布滞后模型检验了所得税变动的累积效应。

* 外部命令定义如下：

/*
  doedit "$path/myado/make_cumul_effect_plot.ado"
*/
  			   
  local minyear 1940
  local maxyear 2000
  use "$D/state_data" if inrange(year,`minyear',`maxyear') ///
      & !inlist(stateabbr,"LA","AK","HI","PR"), clear
	
  xtset statenum year
	
  global lhsvars lnpat ln_inv 
  global persinctaxvars mtr90 
  global corpinctaxvars top_corp 
  global minyear 1940 // 研究起始时间
  global maxyear 2000 // 研究终止时间
  global maxlead 5    // 前推阶数，文中设定为5期
  global maxlag  20   // 最大滞后阶数，文中设定为20期
  global controls l${controllag}s.real_gdp_pc l${controllag}s.population_density l${controllag}s.rd_credit
		
  foreach var of varlist mtr90 top_corp rd_credit {
	 replace `var' = ln(1-`var'/100)
  }
		
* 这里定义标签名称的目的是为了绘图使用 
  label var top_corp "Top Combined Corporate MTR"
  label var mtr90 "90th Percentile Worker Combined MTR"
	
	
************************
* Figure4A and Figure4B
************************
	
* 估计个人所得税对专利申请数、发明家定居数的累计弹性
  foreach taxvar of varlist $persinctaxvars {
	 local taxlab: var label `taxvar'
	 foreach var_outcome of varlist $lhsvars {
		local ylab: var label `var_outcome'
		gen x = `taxvar' - l.`taxvar'
			
		reghdfe D.`var_outcome' F(1/$maxlead).x L(0/$maxlag).x LD.top_corp ///
		        $controls [aw=pop1940], vce(cluster statenum) absorb(year)
		make_cumul_effect_plot, yvar(`var_outcome') taxvar(`taxvar') ///
		     ytitle("Effect of `taxlab'" "on `ylab'") ci_90
		drop x
		graph save   Figure4_`taxvar'_`var_outcome', replace
		graph export Figure4_`taxvar'_`var_outcome'.png, replace width(1200)
	  }
  }

  
  
************************
* Figure4C and Figure4D
************************

* 问题：
*  作者原始 dofile 在计算公司所得税的累计弹性时，
*  由于包含控制变量的滞后差分 20 阶和前推 5 阶，
*  导致模型估计时出现观测值不足的问题。
*  因此，我们仅保留控制变量滞后差分 1 阶和前推 2 阶。
*  因而 Figure3C 和 Figure3D 的结果与正文略有不同。

  foreach taxvar of varlist $corpinctaxvars {
	 local taxlab: var label `taxvar'
	 foreach var_outcome of varlist $lhsvars {
		local ylab: var label `var_outcome'
		gen x = `taxvar' - L.`taxvar'
		gen control1 = has_sales_weight - L.has_sales_weight
		gen control2 = sales_wgt - L.sales_wgt
		gen control3 = payroll_wgt - L.payroll_wgt
		gen control4 = lcb - L.lcb
		gen control5 = lcf - L.lcf
			
		reghdfe D.`var_outcome'  ///
		        F(1/$maxlead).x  L(0/$maxlag).x  LD.mtr90 ///
		        $control  F(1/2).control*  LD(1/1).control*    ///
				[aw=pop1940], vce(cluster statenum) absorb(year)
		
*		reghdfe D.`var_outcome'  F(1/$maxlead).x L(0/$maxlag).x LD.mtr90 $control F(1/5).control* LD(1/20).control* [aw=pop1940], vce(cluster statenum) absorb(year)
			
		make_cumul_effect_plot, yvar(`var_outcome') taxvar(`taxvar') ///
		     ytitle("Effect of `taxlab'" "on `ylab'") ci_90
		drop x control*
		graph save   Figure4_`taxvar'_`var_outcome', replace
		graph export Figure4_`taxvar'_`var_outcome'.png, replace
	  }
  }
		
  graph combine Figure4_mtr90_lnpat.gph Figure4_mtr90_ln_inv.gph Figure4_top_corp_lnpat.gph Figure4_top_corp_ln_inv.gph, rows(2) imargin(zero) graphregion(fcolor(white))
   
  graph export Figure4.png, replace
   
* 查看结果

  shellout Figure4.png
  
*------------------------------------------------Figure4 end-----------









* Note: 这部分会使用【micro_reg_data】文件，800多M，
*       可以从 QJE 官网提供的链接下载
*       https://doi.org/10.7910/DVN/SR410I
*       下载后存放于 $D 文件夹下即可




*======================================
*--------
*-Table 4 ：Micro-data Estimation
*--------
*======================================

* 作者使用的是州和年双向固定聚类标准误，而不是与 Table2 相同的聚类标准误。

  local minyear = 1940
  local maxyear = 2000
  use "$D/micro_reg_data" if !inlist(stateabbr,"LA","","HI","AK","PR") ///
      & !missing(state) & inrange(year,`minyear',`maxyear'), clear
  xtset inv_id year
 
  global cx      "high agglomeration_lag1 tenure tenure2"
  global cx_stfe "gdppc_lag1 popdens_lag1 rd_credit_lag3"
  
  replace  top_corp_lag3 = ln(1-top_corp_lag3/100)
  replace rd_credit_lag3 = ln(1-rd_credit_lag3/100)
	
* 生成有效税率
  gen byte high_unlagged = inv_qual1_top10_c == 1 
  gen byte high   = L.inv_qual1_top10_c == 1 // 生成表示高生产率的虚拟变量
  gen eff_tax     = mtr90_lag3*high + mtr50_lag3*(1-high)
  replace eff_tax = ln(1-eff_tax/100)
				
* 生成有效税率与集聚效应的交互项
  gen  eff_tax_agglom = eff_tax * agglomeration_lag1
  gen top_corp_agglom = top_corp_lag3 * agglomeration_lag1
					
  label var high "High Quality Inventor"
  label var eff_tax "Log(1 - Effective Marginal Tax Rate)"
  label var top_corp_lag3 "Log(1 - Top Corporate Tax Rate)"

* 文中结果呈现  
  tab high high_unlagged, row col	
  
/*
      High |
   Quality |     high_unlagged
  Inventor |         0          1 |     Total
-----------+----------------------+----------
         0 | 5,772,556     65,681 | 5,838,237 
           |     98.87       1.13 |    100.00 
           |     99.91       9.55 |     90.30 
-----------+----------------------+----------
         1 |     5,449    621,737 |   627,186 
           |      0.87      99.13 |    100.00 
           |      0.09      90.45 |      9.70 
-----------+----------------------+----------
     Total | 5,778,005    687,418 | 6,465,423 
           |     89.37      10.63 |    100.00 
           |    100.00     100.00 |    100.00 
*/

		   
******************************
* Part A Interactive FE model
******************************

/*
*- 测试时，可以执行如下两条命令：
*  随机抽取 1% 的观察值, 保留 64,654 笔观察值
   set seed 135
   sample 1  
*/

*-common options
  global FExST "absorb(inv_id  state*year)"
  global seOpt "vce(cluster statenum year)  keepsingletons"

*-Interactive TWFE  
  reghdfe has_pat3yr eff_tax   $cx, $FExST  $seOpt
  est store Tab4_A_1
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe has10cit_3yr eff_tax $cx, $FExST  $seOpt
  est store Tab4_A_2
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe lnpat3yr eff_tax     $cx, $FExST  $seOpt
  est store Tab4_A_3
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe lncit3yr eff_tax     $cx, $FExST  $seOpt
  est store Tab4_A_4
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe high_kpss3yr eff_tax $cx, $FExST  $seOpt
  est store Tab4_A_5
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  local s "using Table4.csv"
  esttab Tab4_A_1 Tab4_A_2 Tab4_A_3 Tab4_A_4 Tab4_A_5 `s', ///
         keep(eff_tax) coeflabels(eff_tax "ln(1-personalMTR90)") ///
         se noconstant obslast stats(mean se) r2 ///
         title ("Table4 Part A") star(* 0.10 ** 0.05 *** 0.01) ///
         replace
  
  
******************************
* Part B Two-way FE model
******************************
  
  global FE3d  "absorb(inv_id  statenum  year)"
  global seOpt "vce(cluster statenum year)  keepsingletons"

  reghdfe has_pat3yr eff_tax top_corp_lag3 $cx $cx_stfe, $FE3d  $seOpt
  est store Tab4_B_1
  sum has_pat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe has10cit_3yr eff_tax top_corp_lag3 $cx $cx_stfe, $FE3d  $seOpt
  est store Tab4_B_2
  sum has10cit_3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe lnpat3yr eff_tax top_corp_lag3     $cx $cx_stfe, $FE3d  $seOpt
  est store Tab4_B_3
  sum lnpat3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe lncit3yr eff_tax top_corp_lag3 $cx $cx_stfe, $FE3d  $seOpt
  est store Tab4_B_4
  sum lncit3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  reghdfe high_kpss3yr eff_tax top_corp_lag3 $cx $cx_stfe, $FE3d  $seOpt
  est store Tab4_B_5
  sum high_kpss3yr if e(sample)==1 // 计算回归使用的均值和标准误
  estadd scalar mean = r(mean)
  estadd scalar se   = r(sd)
  
  local s "using Table4.csv"
  esttab Tab4_B_1 Tab4_B_2 Tab4_B_3 Tab4_B_4 Tab4_B_5 `s', ///
         keep(eff_tax top_corp_lag3) ///
         coeflabels(eff_tax "ln(1-personalMTR90)" ///
		            top_corp_lag3 "ln(1-co.MTR)") ///
         se noconstant obslast stats(mean se) r2  ///
         title ("Table4 Part B") star(* 0.10 ** 0.05 *** 0.01) ///
         append
  
*--------------------------------------------Table4 end----------------





*======================================
*--------
*-Table 5 : The effect of migration
*--------
*======================================

* Table5 估计的是所得税净税率-迁移弹性。
* 在计算迁移弹性时，为了提升效率，使用了自编程序 get_elasticities 
* 程序定义如下 (程序已经存入 【myado】文件夹中)

/*
  doedit "$path/myado/get_elasticities.ado"
*/
  
  use "$D/MLogit_Data", clear
  
/*
*- 测试时，可以执行如下两条命令：
*  随机抽取 1% 的观察值, 保留 46,597 笔观察值
   set seed 135
   sample 1  
*/  
  
  gen top_corp_ret_corp = top_corp_retention*has_corp_pat
  gen top_corp_ret_noncorp = top_corp_retention*(1-has_corp_pat)
  gen log_ret_rate_corp = log_retention_rate*has_corp_pat
  gen log_ret_rate_noncorp = log_retention_rate*(1-has_corp_pat)
	
  sum agglomeration
  replace agglomeration = (agglomeration - r(mean))/r(sd)

  fvset base 0 asgn_haspat high // 定义0为基准组
  
  global controls          "home_state_flag agglomeration"
  global controls_interact "c.home_state_flag#c.high" 
  global base_controls     "home_state_flag"
  global case_controls     "tenure tenure2"
  global additional_vars   "year high multistate_assignee"
  
  
****************
*  Column 1 
**************** 
  tab choice
  asclogit choice log_retention_rate top_corp_retention  ///
           $controls $controls_interact ///
		   c.agglomeration#c.high       ///
		   rd_credit_lag1  gdppc_lag1  popdens_lag1  base_index_lag1, ///
		   case(case_id) alternatives(state_choice_set) ///
		   casev($case_controls)  ///
		   vce(cluster year)
  est store Tab5_1c
 
* 计算均值处的弹性
  di "Elasticities for State + Year FE with Base Controls "
  get_elasticities log_retention_rate
  get_elasticities top_corp_retention
  
* 计算均值处的弹性
  di "Elasticities for State + Year FE with Base Controls "
  get_elasticities log_retention_rate
  get_elasticities top_corp_retention
		
* 分别估计个人所得税和公司所得税对受雇于公司发明家、自雇佣发明家的迁移弹性。内容
* 详见正文 P379。

  asclogit choice log_ret_rate_corp log_ret_rate_noncorp ///
           top_corp_ret_corp top_corp_ret_noncorp ///
		   $controls $controls_interact  ///
		   c.agglomeration#c.high ///
		   rd_credit_lag1 gdppc_lag1 popdens_lag1 base_index_lag1, ///
		   case(case_id) alternatives(state_choice_set) ///
		   casev($case_controls has_corp_pat) ///
		   vce(cluster year)

* 计算均值处的弹性
  di "Elasticities for State + Year FE for corporate vs non-corporate effects separately"
  di "Personal tax: Corp"
  get_elasticities log_ret_rate_corp
  di "Personal tax: Non-Corp"
  get_elasticities log_ret_rate_noncorp
  di "Corporate tax: Corp"
  get_elasticities top_corp_ret_corp
  di "Corporate tax: Non-Corp"
  get_elasticities top_corp_ret_noncorp
  
  
****************
*  Column 2 
**************** 

* Table5 中的 Colunm2-Colunm4 与 Colunm1 的观测值取值范围不同。可能是由于需要执行
* 交互固定效应的原因，Colunm2-Colunm4 一直处于迭代中，无法搜寻得到最优解。

  use "$D/MLogit_Data" if progspell_lag1==1, clear 
  
  gen top_corp_ret_corp = top_corp_retention*has_corp_pat
  gen top_corp_ret_noncorp = top_corp_retention*(1-has_corp_pat)
  gen log_ret_rate_corp = log_retention_rate*has_corp_pat
  gen log_ret_rate_noncorp = log_retention_rate*(1-has_corp_pat)
	
  sum agglomeration
  replace agglomeration = (agglomeration - r(mean))/r(sd)

  fvset base 0 asgn_haspat high // 定义0为基准组

  #d ;  
  asclogit choice log_retention_rate $controls $controls_interact 
           c.agglomeration#c.high, case(case_id) 
		   alternatives(state_choice_set) 
		   casev($case_controls i.year) vce(cluster year) ;
  #d cr
  est store Tab5_2c

  di "Elasticities for State x Year FE Baseline"
  get_elasticities log_retention_rate

  
****************
*  Column 3 
**************** 
  #d ;
  asclogit choice log_retention_rate c.log_retention_rate#c.agglomeration 
           c.log_retention_rate#c.lnpat_statewide_lag1 
		   $controls $controls_interact, 
		   case(case_id) alternatives(state_choice_set) 
		   casev($case_controls i.year) vce(cluster year) ;
  #d cr	
  est store Tab5_3c
  
  di "Elasticities for State x Year FE with agglomeration interaction"
  get_elasticities log_retention_rate
		
		
****************
*  Column 4 
**************** 

  asclogit choice log_retention_rate c.log_retention_rate#c.asgn_haspat c.agglomeration#c.high asgn_haspat $controls $controls_interact, case(case_id) alternatives(state_choice_set) casev($case_controls i.year) vce(cluster year)
  est store Tab5_4c
  
  di "Elasticities for State x Year FE with assignee having patent interaction"
  get_elasticities log_retention_rate
  
  #d ; 
  esttab "Tab5_1c Tab5_2c Tab5_3c Tab5_4c using Table5.csv",  
         keep(log_retention_rate top_corp_retention agglomeration 
              home_state_flag c.agglomeration#c.high) 
         coeflabels(log_retention_rate "ln(1-ATR)" 
                    top_corp_retention "ln(1-co.MTR)" 
                    agglomeration "Agglomeration" 
                    home_state_flag "Home-state flag" 
                c.agglomeration#c.high "Interaction coefficients Agglomeration") 
        se noconstant obslast 
        title ("Table5") 
        star(* 0.10 ** 0.05 *** 0.01) 
        replace ;
  #d cr
  
  shellout Table5.csv
		

********************
* Table 6 Row 4  
********************

* 受雇于公司发明家和自雇佣发明家的所得税净税率-迁移弹性。
* 由于 Table6 与 Table4 使用的是相同的数据，我们在此一并进行估计。
* 但是，这里也存在一直搜索最优解的问题：耗时！

  #d ;
  asclogit choice log_ret_rate_corp log_ret_rate_noncorp 
           c.agglomeration#c.high $controls $controls_interact, 
		   case(case_id) alternatives(state_choice_set) 
		   casev($case_controls i.year) vce(cluster year) ;
  #;
  
  di "Elasticities for State x Year FE for corporate vs non-corporate effects separately"
  di "Personal tax: Corp"
  get_elasticities log_ret_rate_corp
  di "Personal tax: Non-Corp"
  get_elasticities log_ret_rate_noncorp
  
*-----------------------------------------------Table5 end----------------





*======================================
*--------
*-Table 6 : Hterogeneous effect for corporate 
*           and non-corporate inventor
*--------
*======================================

* Table6_1r-Table6_3r 均无法得到估计结果。可能需要的电脑配置较高。

  local minyear = 1940
  local maxyear = 2000
  local vars pat3yr has_cit3yr lncit3yr inv_qual1_top10_c career_length state mtr90_lag3 mtr50_lag3 tenure tenure2 agglomeration_lag1 gdppc_lag1 popdens_lag1 rd_credit_lag3 has_corp_pat3yr inv_id stateyear year statenum stateabbr base_index_lag3 has_corp_pat3yr top_corp_lag3
  use  `vars' using "$D/micro_reg_data" ///
       if !inlist(stateabbr,"LA","","HI","AK") ///
	      & !missing(state) ///
		  & inrange(year,`minyear',`maxyear'), clear
  
  xtset inv_id year
    
  gen     base_index_grp = 0 if missing(base_index_lag3)
  replace base_index_grp = 1 if base_index_lag3 < -1
  replace base_index_grp = 2 if inrange(base_index_lag3,-1,-0.5)
  replace base_index_grp = 3 if inrange(base_index_lag3,-0.5,0)
  replace base_index_grp = 4 if inrange(base_index_lag3,0,0.5)
  replace base_index_grp = 5 if inrange(base_index_lag3,0.5,1)
  replace base_index_grp = 6 if base_index_lag3 > 1 & !missing(base_index_lag3)
		
  gen byte high_base = base_index_lag3 >= 0

  rename has_corp_pat3yr corp_inventor
  
  gen byte high = L.inv_qual1_top10_c == 1
  summ high
										  
  gen eff_tax = mtr90_lag3*high + mtr50_lag3*(1-high) // 计算有效税率，P368

  replace eff_tax = ln(1-eff_tax/100)
  replace top_corp_lag3 = ln(1-top_corp_lag3/100)
  gen     eff_tax_corp = eff_tax*corp_inventor
  gen    top_corp_corp = top_corp_lag3*corp_inventor
  gen  eff_tax_noncorp = eff_tax*(1-corp_inventor)
  gen top_corp_noncorp = top_corp_lag3*(1-corp_inventor)
  
	
****************
*   Row 1
****************

  reghdfe pat3yr eff_tax_corp eff_tax_noncorp top_corp_corp  ///
        top_corp_noncorp agglomeration_lag1 gdppc_lag1 popdens_lag1 ///
		rd_credit_lag3 tenure tenure2 ///
        i.base_index_grp i.base_index_grp#corp_inventor high ///
        c.corp_inventor#c.high corp_inventor, ///
        absorb(inv_id statenum year) ///
        vce(cluster statenum year) keepsingletons
  est store Tab6_1r
  
  sum pat3yr if e(sample) & corp_inventor == 1
  estadd scalar ymean_corp = r(mean)
  sum pat3yr if e(sample) & corp_inventor == 0
  estadd scalar ymean_noncorp = r(mean)
  estadd ysumm
  

****************
*   Row 2
****************

  reghdfe has_cit3yr eff_tax_corp eff_tax_noncorp top_corp_corp     ///
        top_corp_noncorp agglomeration_lag1 gdppc_lag1 popdens_lag1 /// 
		rd_credit_lag3 tenure tenure2 ///
        i.base_index_grp i.base_index_grp#corp_inventor high ///
        c.corp_inventor#c.high corp_inventor, ///
        absorb(inv_id statenum year) ///
        vce(cluster statenum year) keepsingletons
  est store Tab6_2r
  
  sum has_cit3yr if e(sample) & corp_inventor == 1
  estadd scalar ymean_corp = r(mean)
  sum has_cit3yr if e(sample) & corp_inventor == 0
  estadd scalar ymean_noncorp = r(mean)
  estadd ysumm
  

****************
*    Row 3
****************

  reghdfe lncit3yr eff_tax_corp eff_tax_noncorp top_corp_corp  ///
        top_corp_noncorp agglomeration_lag1 gdppc_lag1 popdens_lag1 ///
		rd_credit_lag3 tenure tenure2 ///
        i.base_index_grp i.base_index_grp#corp_inventor high ///
        c.corp_inventor#c.high corp_inventor, ///
        absorb(inv_id statenum year) ///
        vce(cluster statenum year) keepsingletons
  est store Tab6_3r
  
  sum lncit3yr if e(sample) & corp_inventor == 1
  estadd scalar ymean_corp = r(mean)
  sum lncit3yr if e(sample) & corp_inventor == 0
  estadd scalar ymean_noncorp = r(mean)
  estadd ysumm
  
  #d ;
  esttab Tab6_1r Tab6_2r Tab6_3r using Table6.csv, 
         keep(eff_tax_corp eff_tax_noncorp top_corp_corp top_corp_noncorp) 
         se noconstant obslast 
         title ("Table6") 
         star(* 0.10 ** 0.05 *** 0.01) 
         replace ;
  #d cr
   
 
 
 
 
*-附录：自编程序  (已经存放于 adofiles 文件夹中)


*------>>>>> get_elasticities.ado <<<<<<

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
 
 

*------>>>>> make_cumul_effect_plot.ado <<<<<<

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
			graphregion(color(white)) legend(off) ytitle(`ytitle', size(8pt)) 
			xtitle("Years Since Tax Change", size(8pt)) 
			xlabel(-5(5)20, grid) xtick(-5/20)
			text(`max2' 1 "F-test all lags are 0 has p-value = `Fp_lag'", box just(center) size(5pt) fcolor(white) margin(medsmall))
			text(`max' 1 "F-test all leads are 0 has p-value = `Fp_lead'", box just(center) size(5pt) fcolor(white) margin(medsmall));
*	graph export "$projdir/Results/Figures/Figure4_distLag_`yvar'_`taxvar'.eps", replace;
	
	summ beta if rel_yr > 0;
	#delimit cr
	restore
end 
  