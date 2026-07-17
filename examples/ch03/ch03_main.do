**# 第 3 讲 代码实操：给一份公司-年度面板做「一致性体检」
* -----------------------------------------------------------------------------
* 本讲只做诊断、不做清洗。数据随本讲提供(模拟、可复现，见 data/00_make_ch03_data.do)。
* 研究情境：想研究「研发投入是否提升企业绩效」，但只有披露研发的公司才进得了分析样本。
* 本脚本用四件工具，检查「披露组」与「未披露组」是否可比 —— 即样本选择是否在作怪。
* 运行：Stata 中 do ch03_main.do
* -----------------------------------------------------------------------------

version 17
clear all
set more off

* 数据读取：默认联网直读(无需克隆)；离线时把下一行改成 global D "data"(本 do 同级 data 目录)
global D "https://raw.githubusercontent.com/lianxhcn/PXa2026a/main/examples/ch03/data"
* global D "data"
use "$D/firm_year.dta", clear

**## 1 分组统计量：披露组 vs 未披露组，两组可比吗
* 把两组的关键特征并排摆出来看：规模、盈利、营收、负债率
tabstat size roa sales lev, by(disclose) stat(mean sd) nototal

**## 2 分组 t 检验：组间差异是信号还是抽样波动
* 用 ttable2 一次输出多变量的组间均值、差值与显著性(ssc install ttable2)
cap which ttable2
if _rc ssc install ttable2, replace
ttable2 size roa sales lev, by(disclose)

**## 3 样本筛选表：能进入 rd 分析样本的，是怎么筛出来的
* 初始 = 所有公司-年度；分析样本 = 披露研发(rd 非缺失)者
egen byte tag_firm = tag(stkcd)
qui count
local nobs_all = r(N)
qui count if tag_firm
local nfirm_all = r(N)
qui count if !missing(rd)
local nobs_keep = r(N)
qui count if tag_firm & !missing(rd)
local nfirm_keep = r(N)
local drop_obs  = `nobs_all' - `nobs_keep'

di _n "{txt}样本筛选表(从初始面板到 rd 分析样本)"
di "{hline 58}"
di "步骤" _col(34) "剔除观测" _col(46) "剩余观测" _col(56) "公司"
di "{hline 58}"
di "初始(所有公司-年度)" _col(36) "—" _col(46) %6.0f `nobs_all' _col(56) %4.0f `nfirm_all'
di "剔除未披露研发(rd 不可得)" _col(36) %6.0f `drop_obs' _col(46) %6.0f `nobs_keep' _col(56) %4.0f `nfirm_keep'
di "{hline 58}"

**## 4 密度函数图：企业规模在两组的分布(示例；实践中可交给 AI 生成)
cap set scheme cleanplots
twoway (kdensity size if disclose==1, lwidth(medthick)) ///
       (kdensity size if disclose==0, lpattern(dash) lwidth(medthick)), ///
       legend(order(1 "披露研发" 2 "未披露研发") rows(1) pos(6)) ///
       xtitle("企业规模 size = ln(总资产)") ytitle("核密度") ///
       title("图 3.1  企业规模的分组核密度", size(medium))
capture mkdir "fig"
graph export "fig/g_size_kdensity_by_disclose.png", ///
       width(1200) replace

**## 5 (可选)鱼塘抽样模拟：抽样误差 vs 选择偏误
* 把全体 126 个 size 当作「一整口鱼塘」，看两种捞法估的均值差多远
qui summarize size
local truemean = r(mean)
di _n "真实(全体)平均规模 = " %6.3f `truemean'
* (a) 随机撒网：每次随机抽 30 个，平均值围绕真实值波动(抽样误差)
* (b) 只在披露组捞：无论抽多少，都系统性偏高(选择偏误)
tempname rmean smean
postfile `rmean' double m using "__pond_random.dta", replace
postfile `smean' double m using "__pond_select.dta", replace
forvalues i = 1/500 {
    preserve
        qui sample 30, count
        qui summarize size
        post `rmean' (r(mean))
    restore
    preserve
        qui keep if disclose==1
        qui sample 30, count
        qui summarize size
        post `smean' (r(mean))
    restore
}
postclose `rmean'
postclose `smean'
di "随机撒网(500 次)：均值的均值 / 标准差"
use "__pond_random.dta", clear
summarize m
di "只在披露组捞(500 次)：均值的均值 / 标准差"
use "__pond_select.dta", clear
summarize m
erase "__pond_random.dta"
erase "__pond_select.dta"

di _n "ch03 代码实操运行完毕。"
