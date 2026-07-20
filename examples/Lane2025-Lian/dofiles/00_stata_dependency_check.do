*--------------------------------------------------------------------------*
* Lane (2025, QJE): 第三轮 Stata 依赖检查
* 目的：检查图 II 和表 II 的 Stata-only 复现所需命令。
*--------------------------------------------------------------------------*

version 17.0
clear all
set more off
capture log close

* 请酌情修改为包含两个项目文件夹的父目录。
global path "D:\github_lianxh\PXa2026a\examples"
cd $path

local output_root "$path/Lane2025-Lian"

dis "`output_root'"

log using "`output_root'/logs/00_stata_dependency_check.log", ///
    text replace

di as text "{hline 60}"
di as text "Lane (2025): Stata-only 依赖检查"
di as text "Stata 版本：" c(stata_version)
di as text "运行时间：" c(current_date) " " c(current_time)
di as text "{hline 60}"

local missing_commands ""
foreach command in csdid drdid regsave {
    capture which `command'
    if _rc {
        di as error "缺少命令：`command'"
        local missing_commands "`missing_commands' `command'"
    }
    else {
        di as result "可用命令：`command'"
    }
}

if "`missing_commands'" != "" {
    di as error "请先安装缺少命令，再运行 02_core_results_stata.do。"
    di as error "建议命令：ssc install `missing_commands', replace"
    log close
    exit 499
}

capture which gph2xl
if _rc {
    di as text "可选命令缺失：gph2xl（只用于把 Stata 图形数据转给 R）。"
    di as text "本轮不依赖该命令，仍使用 Stata 原生命令完成估计和绘图。"
}
else {
    di as result "可选命令可用：gph2xl"
}

di as result "依赖检查通过。图 II 使用 Stata 原生 DID 命令。"
di as result "表 II 可使用 csdid、drdid 和 regsave 复现双重稳健 ATT。"
log close
