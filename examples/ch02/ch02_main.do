**# 第 2 讲 · 数据处理、探索性分析与样本构造 —— 可运行伴生代码
* --------------------------------------------------------------------------
* 与讲义 lectures/02_data.qmd 各节一一对应（**# / **## 大纲）。
* 可在 VS Code + Stata All in One 中按节导航运行；示例数据默认从 GitHub 读取；Lane 复现包位于本仓库的
* examples/Lane_2025_QJE_paper_codes/。本 do 文件依赖 cleanplots；winsor2 仅用于可选示例。
* --------------------------------------------------------------------------

version 17
clear all
set more off
global GITHUB_RAW "https://raw.githubusercontent.com"
global D "$GITHUB_RAW/lianxhcn/PXa2026a/main/examples/ch02/data"

cd D:\github_lianxh\PXa2026a\examples\ch02\data

// 建议先在 Stata 中 cd 到 examples/ch02，再运行本文件；生成的中间数据会保存在该目录。
// 若使用本地数据，可将上方 global D 改为：
// global D "D:\github_lianxh\PXa2026a\examples\ch02\data"


cap which cleanplots
if _rc {
    net install cleanplots, from("https://tdmize.github.io/data") replace
}
set scheme cleanplots  // 指定绘图模板: 清爽图形风格

**# 认清数据结构：观察单位、粒度、主键
use "$D/firm_finance_2021.dta", clear
describe
summarize

duplicates report stkcd year  // 主键唯一
duplicates report stkcd       // 单独 stkcd 不唯一
isid stkcd year

**## 追加两批财务表
use "$D/firm_finance_2021.dta", clear
append using "$D/firm_finance_2022.dta"

isid stkcd year
tab year

save "firm_finance_2021_2022.dta", replace

**## 横向合并：先清洗键，再 m:1
use "$D/industry_lookup.dta", clear
list
replace indcd = upper(strtrim(indcd))  // "c36 " -> "C36"
list
tab indcd
save "industry_lookup_upper.dta", replace  // 清洗后的行业对照表

use "firm_finance_2021_2022.dta", clear
list stkcd year indcd in 1/10, clean noobs
tab indcd

merge m:1 indcd using "$D/industry_lookup.dta"
tab _merge       // 合并后第一件事：看匹配率
tab indcd

// 正确做法
use "firm_finance_2021_2022.dta", clear
merge m:1 indcd using "industry_lookup_upper.dta"
tab _merge       // 合并后第一件事：看匹配率
tab indcd



**## 聚合：月度市值 -> 公司-年度，再并入
// 下列 begin 到 over 之间的代码必须一次性执行。

preserve                             //-----------begin----
  use "$D/mktcap_monthly.dta", clear
  list, sepby(stkcd)
  gen int year = int(ym/100)
  collapse (mean) mktcap, by(stkcd year)  // 先聚合
  tostring stkcd, replace format(%06.0f)  // 修键：数值 -> 字符，补前导零
  tempfile mk
  save `mk'
restore

cap drop _merge
merge 1:1 stkcd year using `mk'
drop _merge                          //-----------over----


**## 长宽转换示例
use "firm_finance_2021_2022.dta", clear
sort stkcd year
list stkcd year sales in 1/6, sepby(stkcd)

// long --> wide
keep stkcd year sales
reshape wide sales, i(stkcd) j(year)
list in 1/2, clean noobs


**# 缺失、离群与变换
use "firm_finance_2021_2022.dta", clear
mvdecode rd, mv(-99)                       // 还原伪装成 -99 的缺失
summarize sales, detail
graph box sales                            // 先画图看见离群
list stkcd year sales if sales>500000, clean noobs
replace sales = 108000 if stkcd=="000101" & year==2022   // 查明是录入错误，改正
gen double size = ln(at)                   // 对数转换
egen z_size = std(size)                    // 标准化
* winsor2 sales, cuts(1 99)                // 真离群才用缩尾

**# 字符与日期变量
destring lev, gen(lev_num) percent         // 文本型百分比 -> 数值
encode indcd, gen(ind_id)                  // 类别文本 -> 带标签数值
label list ind_id
* 字符日期示例：gen d = date(rptdate,"YMD"); format d %td

**# EDA 与图形诊断
gen double rd_ratio = 100*rd/sales
gen str6 ind_s = cond(indcd=="C39","电子", cond(indcd=="C27","医药","汽车"))
label variable rd_ratio "研发强度(%)"
label variable size     "企业规模 ln(资产)"
// 直方图
histogram rd_ratio, percent kdensity xtitle("研发强度(%)")
// 箱型图
graph box rd_ratio, over(ind_s)
// 散点图
twoway (scatter rd_ratio size) (lfit rd_ratio size), ///
    legend(order(1 "观测值" 2 "拟合线") pos(6) rows(1))
// 分组柱状图
graph bar (mean) rd_ratio, over(ind_s)
// 分组统计量
tabstat rd_ratio, by(ind_s) stat(n mean sd) format(%6.2f)

**# 留痕与可复现
label variable year    "年度"
label variable lev_num "资产负债率"
drop if missing(rd_ratio)                  // 样本筛选：剔除关键变量缺失
codebook stkcd year rd_ratio size lev_num, compact   // 变量字典

**# 复现 Lane 的一小段（数据需从 Dataverse 下载：DOI 10.7910/DVN/VJECHN）
/*
local lane_file "mms_merged_harmonized_panel_cleaned4reg_5digit.dta"
use "replicationpackage/data/input/`lane_file'", clear
describe, short
codebook hci year, compact
gen treat = (hci==1 & year>=1973)          // 目标行业 × 政策启动后
tab treat
*/
