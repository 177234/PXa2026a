**# 第 2 讲 · 数据处理、探索性分析与样本构造 —— 可运行伴生代码
* -----------------------------------------------------------------------------
* 与讲义 lectures/02_data.qmd 各节一一对应（**# / **## 大纲，可在 VS Code + Stata All in One
* 中按节导航运行）。本仓库示例数据联网直接读取，无需克隆；Lane 数据需另从 Dataverse 下载。
* 依赖：ssc install cleanplots winsor2
* -----------------------------------------------------------------------------

version 17
clear all
set more off
global D "https://raw.githubusercontent.com/lianxhcn/PXa2026a/main/examples/ch02/data"
cap which cleanplots
if _rc ssc install cleanplots, replace
set scheme cleanplots

**# 2.2 认清数据结构：观察单位、粒度、主键
use "$D/firm_finance_2021.dta", clear
describe
duplicates report stkcd year      // 主键唯一
duplicates report stkcd           // 单独 stkcd 不唯一
isid stkcd year

**# 2.3 合并、追加与聚合
**## 追加两批财务表
use "$D/firm_finance_2021.dta", clear
append using "$D/firm_finance_2022.dta"
isid stkcd year
tab year
tempfile panel
save `panel'

**## 横向合并：先清洗键，再 m:1
use "$D/industry_lookup.dta", clear
replace indcd = upper(strtrim(indcd))     // "c36 " -> "C36"
tempfile look
save `look'
use `panel', clear
merge m:1 indcd using `look'
tab _merge                                // 合并后第一件事：看匹配率
drop if _merge==2
drop _merge

**## 聚合：月度市值 -> 公司-年度，再并入
preserve
  use "$D/mktcap_monthly.dta", clear
  gen int year = int(ym/100)
  collapse (mean) mktcap, by(stkcd year)  // 先聚合
  tostring stkcd, replace format(%06.0f)  // 修键：数值 -> 字符，补前导零
  tempfile mk
  save `mk'
restore
merge 1:1 stkcd year using `mk'
drop _merge

**## 长宽转换示例
preserve
  keep stkcd year sales
  reshape wide sales, i(stkcd) j(year)
  list in 1/6, clean noobs
restore

**# 2.4 缺失、离群与变换
mvdecode rd, mv(-99)                       // 还原伪装成 -99 的缺失
summarize sales, detail
graph box sales                            // 先画图看见离群
list stkcd year sales if sales>500000, clean noobs
replace sales = 108000 if stkcd=="000101" & year==2022   // 查明是录入错误，改正
gen double size = ln(at)                   // 对数转换
egen z_size = std(size)                    // 标准化
* winsor2 sales, cuts(1 99)                // 真离群才用缩尾

**# 2.5 字符与日期变量
destring lev, gen(lev_num) percent         // 文本型百分比 -> 数值
encode indcd, gen(ind_id)                  // 类别文本 -> 带标签数值
label list ind_id
* 字符日期示例：gen d = date(rptdate,"YMD"); format d %td

**# 2.6 EDA 与图形诊断
gen double rd_ratio = 100*rd/sales
gen str6 ind_s = cond(indcd=="C39","电子", cond(indcd=="C27","医药","汽车"))
label variable rd_ratio "研发强度(%)"
label variable size     "企业规模 ln(资产)"
histogram rd_ratio, percent kdensity xtitle("研发强度(%)")
graph box rd_ratio, over(ind_s)
twoway (scatter rd_ratio size) (lfit rd_ratio size), legend(order(1 "观测值" 2 "拟合线") pos(6) rows(1))
graph bar (mean) rd_ratio, over(ind_s)
tabstat rd_ratio, by(ind_s) stat(n mean sd) format(%6.2f)

**# 2.7 留痕与可复现
label variable year    "年度"
label variable lev_num "资产负债率"
drop if missing(rd_ratio)                  // 样本筛选：剔除关键变量缺失
codebook stkcd year rd_ratio size lev_num, compact   // 变量字典

**# 2.8 复现 Lane 的一小段（数据需从 Dataverse 下载：DOI 10.7910/DVN/VJECHN）
/*
use "replicationpackage/data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta", clear
describe, short
codebook hci year, compact
gen treat = (hci==1 & year>=1973)          // 目标行业 × 政策启动后
tab treat
*/
