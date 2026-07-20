*--------------------------------------------------------------------------*
* Lane (2025, QJE): 图 II 的 Stata-only 复现
* 目的：保留作者的 xtdidregress 与 post-estimation 图形，不运行 R。
* 输出：8 个 Stata 图形对象，以及 1 个组合 PNG/PDF。
*--------------------------------------------------------------------------*

version 17.0
clear all
set more off
capture log close

global path "D:\github_lianxh\PXa2026a\examples"  //请酌情修改, by YJ Lian
cd $path 

local output_root "$path/Lane2025-Lian"
local source_root "$path/Lane_2025_QJE_paper_codes/replicationpackage"

dis "`output_root'"
dis "`source_root'"


local input_dir "`source_root'/data/input"
local figure_dir "`output_root'/output/figures"
local mms5_name "mms_merged_harmonized_panel_cleaned4reg_5digit.dta"
local mms4_name "mms_merged_harmonized_panel_cleaned4reg_4digit.dta"
local mms5 "`input_dir'/`mms5_name'"
local mms4 "`input_dir'/`mms4_name'"

capture confirm file "`mms5'"
if _rc exit 601

capture confirm file "`mms4'"
if _rc exit 601

log using "`output_root'/logs/02a_figure2_stata.log", text replace

capture program drop run_figure2_cell
program define run_figure2_cell
    args datafile panelname suffix usecontrols figure_dir

    use "`datafile'", clear
    xtset id year
    gen byte treat = hci == 1 & year >= 1973

    local controls ""
    local specname "Baseline"
    if `usecontrols' == 1 {
        local controls ///
            c.(l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0)#i.year
        local specname "Controls"
    }

    di as text "{hline 60}"
    di as text "`panelname'；`specname' specification"

    * 作者图 II 的结果变量：实际出货产出对数。
    xtdidregress (l_ship `controls') (treat), ///
        group(id) time(year) vce(cluster id)

    * 记录政策前联合检验，供复现笔记解释。
    estat ptrends

    * 上排：处理组与对照组的拟合趋势。
    estat trendplots, ltrends noxline
    graph save "`figure_dir'/fig2_`suffix'_trend.gph", replace
    graph export "`figure_dir'/fig2_`suffix'_trend.png", ///
        width(1600) replace

    * 下排：相对于 1972 年的动态 DID 系数和置信区间。
    estat grangerplot, baseline(1972) verbose post
    graph save "`figure_dir'/fig2_`suffix'_event.gph", replace
    graph export "`figure_dir'/fig2_`suffix'_event.png", ///
        width(1600) replace
end

run_figure2_cell "`mms5'" "Five-digit panel" "5d_baseline" 0 ///
    "`figure_dir'"
run_figure2_cell "`mms5'" "Five-digit panel" "5d_controls" 1 ///
    "`figure_dir'"
run_figure2_cell "`mms4'" "Four-digit panel" "4d_baseline" 0 ///
    "`figure_dir'"
run_figure2_cell "`mms4'" "Four-digit panel" "4d_controls" 1 ///
    "`figure_dir'"

* 组合顺序与论文图 II 相同：上排拟合趋势，下排动态 DID。
graph combine ///
    "`figure_dir'/fig2_5d_baseline_trend.gph" ///
    "`figure_dir'/fig2_5d_controls_trend.gph" ///
    "`figure_dir'/fig2_4d_baseline_trend.gph" ///
    "`figure_dir'/fig2_4d_controls_trend.gph" ///
    "`figure_dir'/fig2_5d_baseline_event.gph" ///
    "`figure_dir'/fig2_5d_controls_event.gph" ///
    "`figure_dir'/fig2_4d_baseline_event.gph" ///
    "`figure_dir'/fig2_4d_controls_event.gph", ///
    cols(4) ///
    title("Figure II: Industrial Policy and Industry Output")

graph export "`figure_dir'/figure-ii-stata-only.png", ///
    width(3200) replace
graph export "`figure_dir'/figure-ii-stata-only.pdf", replace

di as result "图 II 的 Stata-only 版本已写入：`figure_dir'"
log close
