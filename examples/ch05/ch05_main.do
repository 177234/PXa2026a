*==============================================================================
* ch05 伴生脚本：FWL、虚拟变量与固定效应：理解条件比较
*------------------------------------------------------------------------------
* 连享会 2026 暑期班·初级班 · 第 5 讲
* 用法：VS Code + Stata All in One，按 **# / **## 大纲导航分节运行。
* 数据：Stata 自带数据（nlswork / auto）+ 本脚本内模拟数据，无需外部文件。
* 说明：与书稿 lectures/05_FE_intFE.qmd 各节标题一一对应；代码可复跑。
* 依赖命令（如缺，先安装）：ssc install reghdfe ; ssc install center
*==============================================================================

version 17
clear all
set more off

* 数据读取：默认联网直读(无需克隆)；离线时把下一行改成 global D "data"(本 do 同级 data 目录)
global D "https://raw.githubusercontent.com/lianxhcn/PXa2026a/main/examples/ch05/data"
* global D "data"
* xtcs.dta：中国上市公司资本结构面板（老师授权入公开库 2026-07-18）
*   code=公司, year=年份, tl=资产负债率, size=规模, ndts=非债务税盾, tang=有形资产, tobin=Tobin Q, npr=净利率


**# 案例情境：三家公司的一张图（辛普森悖论）

*----------------- 模拟：辛普森悖论与组内去心
  clear
  set seed 20260706
  set obs 3
  gen id    = _n
  gen a_i   = 12 - 3*id            // 个体效应 9,6,3，与规模负相关
  gen size0 = 2  + 3*id            // 初创规模 5,8,11
  expand 100
  gen x = size0 + runiform(0, 4)          // Size = ln(总资产)
  gen y = a_i + 0.5*x + rnormal(0, 0.8)   // DGP：真实 beta = 0.5

  reg  y x                     // 混合回归：斜率为负（被公司间差异污染）
  areg y x, absorb(id)         // 个体固定效应：斜率回到 0.5 附近
  xtset id
  xtreg y x, be                // 对照：组间关系，就是那条负的混合斜率来源

*----------------- 组内去心的图示（需 binscatter2；无则跳过）
  cap which binscatter2
  if _rc==0 {
      binscatter2 y x, n(60) by(id)              // 原始数据：三条内部正斜率 + 整体负
      binscatter2 y x, n(60) by(id) absorb(id)   // 组内去心后
  }


**# 从常数项到虚拟变量：残差化的第一课

**## 常数项 = 去均值：FWL 的最简特例
  clear
  set seed 13599
  set obs 30
  gen x = 2*runiform()
  gen e = rnormal()
  gen y = 5 + 0.6*x + e

  reg y x                                  // 含常数项
  cap which center
  if _rc==0 {
      center y x, prefix(c_)               // 去均值（De-mean）
      reg c_y c_x, noconstant              // 与 reg y x 的斜率相同
  }

**## FWL 定理：先剔除，再回归（三步等价于一步）
  sysuse auto, clear
  * 目标：reg mpg weight foreign 中 weight 的系数
  reg mpg weight foreign                   // 一步到位
  qui reg mpg foreign
  predict eY, res                          // Y 剔除 foreign 的残差
  qui reg weight foreign
  predict eX, res                          // weight 剔除 foreign 的残差
  reg eY eX                                // 残差对残差：weight 系数与上面相同

**## 虚拟变量、基准组与因子变量
  sysuse nlsw88, clear
  * 虚拟变量 = 变截距：种族与工资
  reg wage i.race                          // 自动留基准组（race=1 为基准）
  reg wage ib2.race                        // 指定 race=2（黑人）为基准组
  * 因子变量：虚拟变量 + 连续变量 + 交乘项一行搞定
  reg wage i.race c.hours i.race#c.hours   // 含交乘项
  reg wage i.race##c.hours                 // 与上一行等价的简写


**# 固定效应模型：从虚拟变量到组内去心

**## 组内去心与四种等价写法
  webuse nlswork, clear
  xtset idcode year
  * 注：nlswork 有约 4700 个个体，直接 reg ... i.idcode（LSDV）会生成数千个虚拟变量、
  *     计算极慢——这正是「虚拟变量多到装不下、才需要固定效应」的直观理由（见 HDFE 一节）。
  *     下面三条组内估计量给出与 LSDV 完全相同的斜率，却快得多：
  xtreg   ln_wage tenure hours, fe           // 组内估计量
  areg    ln_wage tenure hours, absorb(idcode)
  reghdfe ln_wage tenure hours, absorb(idcode) cluster(idcode)

**## 个体、时间与双向固定效应
  xtreg   ln_wage tenure hours, fe                     // 个体 FE
  xtreg   ln_wage tenure hours i.year, fe              // 双向 FE
  reghdfe ln_wage tenure hours, absorb(idcode year) cluster(idcode)  // 等价双向 FE
  * 时间效应是否显著（LR 检验）
  qui xtreg ln_wage tenure hours, fe
  est store fe
  qui xtreg ln_wage tenure hours i.year, fe
  est store fe_t
  lrtest fe fe_t

**## 常见问题：时不变变量放不进固定效应
  gen black = 2.race                          // 种族虚拟变量（样本期内不随时间变）
  xtreg ln_wage black tenure hours, fe        // black 被 (omitted)
  * 若确要估计时不变变量：改用混合回归 + 控制变量（把个体效应黑盒拆开）
  reg   ln_wage black i.occ_code south collgrad tenure hours, vce(cluster idcode)


**## 真实财务数据：中国上市公司资本结构的双向固定效应
  use "$D/xtcs.dta", clear
  xtset code year
  reg     tl size ndts tang tobin npr                                      // 混合回归 POLS
  xtreg   tl size ndts tang tobin npr, fe cluster(code)                     // 个体 FE
  xtreg   tl size ndts tang tobin npr i.year, fe cluster(code)             // 双向 FE
  reghdfe tl size ndts tang tobin npr, absorb(code year) cluster(code)      // 等价双向 FE
  * 时间效应是否显著
  qui xtreg tl size ndts tang tobin npr, fe
  est store fe0
  qui xtreg tl size ndts tang tobin npr i.year, fe
  est store fe0_t
  lrtest fe0 fe0_t


**# 高维固定效应的基本思想

  webuse nlswork, clear
  xtset idcode year
  * absorb() 吸什么 与 vce(cluster) 聚类到哪，是两个独立决定
  reghdfe ln_wage tenure hours, absorb(idcode year)          cluster(idcode)
  reghdfe ln_wage tenure hours, absorb(idcode year ind_code) cluster(idcode)
  * 处理变量与固定效应同层级会被吸收（示意：ind_code#year 层面的变量放不进 ind#year FE）


**# 双向固定效应与 DID

**## 2×2 DID：还原政策效应
  clear
  set seed 20260708
  set obs 200
  gen id    = _n
  gen treat = id > 100                    // 后 100 个为处理组
  expand 2
  bysort id: gen post = _n - 1            // 0=政策前, 1=政策后
  * DGP：基线 10 + 组间差 2 + 时间趋势 4 + 政策效应 3
  gen y = 10 + 2*treat + 4*post + 3*(treat*post) + rnormal(0,1)

  table post treat, stat(mean y) nformat(%6.2f)   // 四格均值，可手算验证
  reg y i.treat##i.post, vce(robust)              // 1.treat#1.post ≈ 3

**## 从两期到多期：事件研究（平行趋势的直观检验）
  clear
  set seed 20260709
  set obs 300
  gen id    = _n
  gen treat = id > 150
  expand 8
  bysort id: gen year = 2010 + _n - 1     // 8 期
  gen k = year - 2014                     // 相对政策时间（2014 实施）
  gen post = year >= 2014
  * DGP：无事前趋势差异；事后效应逐期走强
  gen y = 5 + 2*treat + 0.3*(year-2010) + (post & treat)*(0.8*(k+1)) + rnormal(0,1)
  xtset id year
  * 事件研究：生成"处理组 × 相对期"虚拟变量，以 k=-1 为基准（不含 k=-1）
  qui forval j = -4/3 {
      local lab = cond(`j'<0, "m" + string(-`j'), "p" + string(`j'))
      gen evt_`lab' = (k==`j') & treat==1
  }
  * 事前 evt_m4..evt_m2 应接近 0（平行趋势）；事后 evt_p0..evt_p3 逐期走强（≈0.8,1.6,2.4,3.2）
  reghdfe y evt_m4 evt_m3 evt_m2 evt_p0 evt_p1 evt_p2 evt_p3, absorb(id year) cluster(id)
  * 如需事件研究图（需 coefplot）：coefplot, vertical yline(0)


*==============================================================================
* 结束。完整概念与解读见 lectures/05_FE_intFE.qmd。
* 现代 DID 估计量（CSDID 等）与 DDML 留高级班：https://www.lianxh.cn/details/1811.html
*==============================================================================
