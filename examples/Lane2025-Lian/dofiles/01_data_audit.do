*--------------------------------------------------------------------------*
* Lane (2025, QJE): 第二轮数据审计
* 目的：只读核对两份 MMS 主分析面板的粒度、主键、处理编码和变量缺失。
*
* 使用方法：
*   1. 修改下方 global path；
*   2. 运行 do "dofiles/01_data_audit.do"。
*
* 本脚本不保存或覆盖作者数据；唯一输出是 logs/ 下的日志。
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

* 在开始前检查关键目录和输入数据是否存在。
capture confirm file "`source_root'/README.md"
if _rc {
    di as error "找不到 replicationpackage。"
    di as error "请检查 global path 是否指向两个项目文件夹的父目录。"
    exit 601
}

local input_dir "`source_root'/data/input"
local mms5_name "mms_merged_harmonized_panel_cleaned4reg_5digit.dta"
local mms4_name "mms_merged_harmonized_panel_cleaned4reg_4digit.dta"
local mms5 "`input_dir'/`mms5_name'"
local mms4 "`input_dir'/`mms4_name'"

capture confirm file "`mms5'"
if _rc exit 601

capture confirm file "`mms4'"
if _rc exit 601

log using "`output_root'/logs/01_data_audit.log", text replace

di as text "============================================================"
di as text "Lane (2025): MMS 主分析面板审计"
di as text "运行时间：" c(current_date) " " c(current_time)
di as text "作者包：`source_root'"
di as text "============================================================"

capture program drop audit_mms_panel
program define audit_mms_panel
    args datafile panelname

    di as text _n "{hline 60}"
    di as text "审计对象：`panelname'"
    di as text "文件：`datafile'"
    di as text "{hline 60}"

    * 载入作者已清洗、已协调口径的分析面板；不会写回磁盘。
    use "`datafile'", clear

    * 核对面板单位、年份和处理变量是否存在。
    describe id year hci post l_ship l_valueadded l_grossoutput ///
        l_workers l_ppi l_y_n l_costs_0 l_avg_size_0 l_avg_wages_0

    di as text _n "[1] 面板主键与观测范围"
    count
    di as result "总观测数 = " r(N)

    capture noisily isid id year
    if _rc {
        di as error "警告：id-year 不是唯一主键；后续不能直接设定行业--年份面板。"
    }
    else {
        di as result "通过：id-year 是唯一的行业--年份主键。"
    }

    xtset id year
    xtdescribe

    bysort id: egen first_year = min(year)
    bysort id: egen last_year = max(year)
    quietly summarize first_year
    local earliest_start = r(min)
    local latest_start = r(max)
    quietly summarize last_year
    local earliest_end = r(min)
    local latest_end = r(max)
    di as result "行业起始年份范围：" ///
        `earliest_start' " 至 " `latest_start'
    di as result "行业结束年份范围：" ///
        `earliest_end' " 至 " `latest_end'
    drop first_year last_year

    di as text _n "[2] 处理组、政策期和时间一致性"
    tab hci, missing
    tab post, missing
    tab hci post, missing
    tab year hci, missing

    * HCI 身份应在一个行业内部保持不变。
    bysort id: egen hci_min = min(hci)
    bysort id: egen hci_max = max(hci)
    count if hci_min != hci_max & !missing(hci_min, hci_max)
    di as result "HCI 身份随时间变化的行业数 = " r(N)
    drop hci_min hci_max

    * `code' 是行业代码。若它在同一 id 内变化，扩展合并前需先解释口径变化。
    bysort id (code): gen byte code_changed = code != code[1]
    count if code_changed & !missing(code)
    di as result "同一 id 内行业代码变化的观测数 = " r(N)
    drop code_changed

    * 作者主文以 1973 年为统一首次处理期；这里只检查 post 的编码。
    gen byte expected_post = year >= 1973
    count if post != expected_post & !missing(post)
    di as result "post 与 year >= 1973 不一致的观测数 = " r(N)
    drop expected_post

    count if hci == 1 & year < 1973
    di as result "政策前的 HCI 行业--年份观测数 = " r(N)
    count if hci == 1 & year >= 1973
    di as result "政策后的 HCI 行业--年份观测数 = " r(N)

    di as text _n "[3] 核心结果和基期控制变量"
    misstable summarize l_ship l_valueadded l_grossoutput ///
        l_workers l_ppi l_y_n l_costs_0 l_avg_size_0 l_avg_wages_0 ///
        l_y_n_0

    summarize l_ship l_valueadded l_grossoutput l_workers l_ppi l_y_n, ///
        detail

    summarize l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0, detail

    * 含控制变量的 DID 会删除控制变量不完整的观测；单独报告该风险。
    gen byte missing_baseline = ///
        missing(l_costs_0, l_avg_size_0, l_avg_wages_0, l_y_n_0)
    tab hci missing_baseline, row
    bysort id: egen n_missing_baseline = total(missing_baseline)
    bysort id: gen byte all_missing_baseline = ///
        n_missing_baseline == _N
    egen byte id_tag = tag(id)
    count if id_tag & all_missing_baseline
    di as result "基期控制变量全部缺失的行业数 = " r(N)
    drop missing_baseline n_missing_baseline all_missing_baseline id_tag

    di as text _n "[4] 用于后续 DID 的处理变量"
    gen byte treat = hci == 1 & year >= 1973
    tab treat, missing
    drop treat

    di as text "审计完成：`panelname'"
end

audit_mms_panel "`mms5'" "五位 KSIC 行业--年份面板"
audit_mms_panel "`mms4'" "四位 KSIC 行业--年份面板"

di as text _n "============================================================"
di as result "两份 MMS 主面板的只读审计已完成。"
di as text "请查看：`output_root'/logs/01_data_audit.log"
di as text "============================================================"

log close
