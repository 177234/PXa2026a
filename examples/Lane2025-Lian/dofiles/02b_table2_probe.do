*--------------------------------------------------------------------------*
* Lane (2025, QJE): 表 II 的 CSDID 输出探查
* 目的：以五位面板的 l_ship 为例，确认 Post_avg 的矩阵名称和可用结果。
*--------------------------------------------------------------------------*

version 17.0
clear all
set more off
capture log close

* 路径设置与已验证的 Figure II dofile 保持一致。
* 请酌情修改为包含两个项目文件夹的父目录。
global path "D:\github_lianxh\PXa2026a\examples"
cd $path

local output_root "$path/Lane2025-Lian"
local source_root "$path/Lane_2025_QJE_paper_codes/replicationpackage"

dis "`output_root'"
dis "`source_root'"

args bootstrap_reps

if `"`bootstrap_reps'"' == "" {
    local bootstrap_reps 199
}

local input_dir "`source_root'/data/input"
local mms5_name "mms_merged_harmonized_panel_cleaned4reg_5digit.dta"
local mms5 "`input_dir'/`mms5_name'"

capture confirm file "`mms5'"
if _rc exit 601

log using "`output_root'/logs/02b_table2_probe.log", text replace

use "`mms5'", clear
xtset id year
gen int gvar = 0
replace gvar = 1973 if hci == 1

local controls l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0

di as text "{hline 60}"
di as text "CSDID probe: five-digit l_ship"
di as text "Wild bootstrap repetitions: `bootstrap_reps'"
di as text "{hline 60}"

csdid l_ship `controls', ///
    time(year) ivar(id) gvar(gvar) ///
    method(dripw) wboot reps(`bootstrap_reps') ///
    agg(event) replace

ereturn list
matrix list e(b)
matrix list e(V)

di as result "请确认 e(b) 中是否存在 Post_avg。"
log close
