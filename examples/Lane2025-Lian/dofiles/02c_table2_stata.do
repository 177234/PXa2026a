*--------------------------------------------------------------------------*
* Lane (2025, QJE): 表 II 的 Stata-only 复现
* 目的：按作者的 CSDID 循环，导出动态 DID 的平均政策后 ATT。
* 说明："ols" 是作者代码的名称；实际采用 csdid, method(reg)。
*--------------------------------------------------------------------------*

version 17.0
clear all
set more off
capture log close
set seed 1312
set sortseed 1231
set type double

* 路径设置与已验证的 Figure II dofile 保持一致。
* 请酌情修改为包含两个项目文件夹的父目录。
global path "D:\github_lianxh\PXa2026a\examples"
cd $path

local output_root "$path/Lane2025-Lian"
local source_root "$path/Lane_2025_QJE_paper_codes/replicationpackage"

dis "`output_root'"
dis "`source_root'"

args bootstrap_reps outcome_subset

if `"`bootstrap_reps'"' == "" {
    local bootstrap_reps 10000
}

local input_dir "`source_root'/data/input"
local dataset5 ///
    "`input_dir'/mms_merged_harmonized_panel_cleaned4reg_5digit.dta"
local dataset4 ///
    "`input_dir'/mms_merged_harmonized_panel_cleaned4reg_4digit.dta"
local intermediate_dir "`output_root'/output/intermediate"
local table_dir "`output_root'/output/tables"

capture confirm file "`dataset5'"
if _rc exit 601

capture confirm file "`dataset4'"
if _rc exit 601

local outcomevariablelist ///
    l_ship l_valueadded l_grossoutput l_workers l_ppi l_y_n ///
    l_ship_sh l_lab_sh l_est
if `"`outcome_subset'"' != "" {
    local outcomevariablelist "`outcome_subset'"
    local file_suffix "`outcome_subset'"
}
else {
    local file_suffix "all"
}

log using "`output_root'/logs/02c_table2_stata_`file_suffix'.log", ///
    text replace

di as text "{hline 60}"
di as text "Lane (2025): Table II CSDID replication"
di as text "Wild-bootstrap repetitions: `bootstrap_reps'"
di as text "Outcomes: `outcomevariablelist'"
di as text "{hline 60}"

local controlset l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0
tempfile all_regsave
local replace_option "replace"
local modelnumber = 1

foreach outcome of local outcomevariablelist {
    foreach panel in 5d 4d {
        if "`panel'" == "5d" {
            local input_file "`dataset5'"
        }
        else {
            local input_file "`dataset4'"
        }

        use "`input_file'", clear
        xtset id year
        gen int gvar = 0
        replace gvar = 1973 if hci == 1

        foreach estimator in dr ols {
            di as text "Outcome: `outcome'; panel: `panel'; estimator: " ///
                "`estimator'"

            if "`estimator'" == "dr" {
                csdid `outcome' `controlset', ///
                    time(year) ivar(id) gvar(gvar) ///
                    method(dripw) wboot reps(`bootstrap_reps') ///
                    agg(event) replace
            }
            else {
                csdid `outcome' `controlset', ///
                    time(year) ivar(id) gvar(gvar) ///
                    method(reg) agg(event) replace
            }

            regsave using "`all_regsave'", ///
                ci tstat pval ///
                addlabel(outcome, `outcome', panel, `panel', ///
                    estimator, `estimator', model_id, `modelnumber') ///
                `replace_option'

            local modelnumber = `modelnumber' + 1
            local replace_option "append"
        }
    }
}

use "`all_regsave'", clear
save "`intermediate_dir'/table-ii-all-`file_suffix'.dta", replace
export delimited using ///
    "`intermediate_dir'/table-ii-all-`file_suffix'.csv", replace

keep if lower(var) == "post_avg"
gen str28 estimator_label = "Doubly robust: DR-IPW"
replace estimator_label = "Regression DID: method(reg)" if ///
    estimator == "ols"
gen str20 outcome_label = ""
replace outcome_label = "Log shipments" if outcome == "l_ship"
replace outcome_label = "Log value added" if outcome == "l_valueadded"
replace outcome_label = "Log gross output" if outcome == "l_grossoutput"
replace outcome_label = "Log workers" if outcome == "l_workers"
replace outcome_label = "Log producer prices" if outcome == "l_ppi"
replace outcome_label = "Log labor productivity" if outcome == "l_y_n"
replace outcome_label = "Shipments share" if outcome == "l_ship_sh"
replace outcome_label = "Labor share" if outcome == "l_lab_sh"
replace outcome_label = "Log establishments" if outcome == "l_est"

order outcome outcome_label panel estimator estimator_label ///
    coef stderr pval ci_lower ci_upper tstat
sort outcome panel estimator
format coef stderr pval ci_lower ci_upper %9.4f
save "`intermediate_dir'/table-ii-post-avg-`file_suffix'.dta", replace
export delimited using ///
    "`intermediate_dir'/table-ii-post-avg-`file_suffix'.csv", replace

list outcome_label panel estimator_label coef stderr pval, ///
    noobs sepby(outcome_label)

di as result "结果已写入：`intermediate_dir'"
di as result "结果表在：`table_dir'（Markdown 表格随后由笔记生成）。"
log close
