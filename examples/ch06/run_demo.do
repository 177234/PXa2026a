********************************************************************************
* run_demo.do — 课堂演示用裁剪版主控脚本
* 复现对象: Baker, Callaway, Cunningham, Goodman-Bacon & Sant'Anna (2026, JEL 64(2))
*           复现包: https://github.com/pedrohcgs/JEL-DiD
*
* 只运行"初级班范围内"的部分:
*   0_stata_Make_data.do      —— 数据构建(使用包内已含数据)
*   1_stata_adoption_table.do —— Table 1(医保扩张采纳时点表)
*   2_stata_2x2.do            —— 2×2 双重差分: Tables 2–7, Figure 1
*   3_stata_2xT.do            —— 两组多期事件研究: Figures 2–4
* 跳过(超出初级班范围):
*   4_stata_GxT.do, 5_stata_honestdid.do
*
* 【重要】本脚本按官方 README 记载的文件结构编写。下载解压后,请先打开
* scripts/Stata/00_stata_master_did_jel.do 对照一眼:若原主控文件中还定义了
* 其他全局宏(如输出路径),请照搬到本脚本 SETUP 区。
* 使用方法:把本文件放到复现包根目录(与 data/、scripts/ 同级),
* 修改下面的 rootdir 后整体运行。
********************************************************************************

clear all
set more off
capture log close
version 15

*=================== SETUP:只需要改这一行 ===================================*
global rootdir "C:/path/to/JEL-DiD"        // ← 改成你的包根目录(正斜杠)
*=============================================================================*

cd "$rootdir"
log using "run_demo_log.smcl", replace

*--- 软件包预装(课前先跑一遍以缓存;课堂断网也不受影响) -------------------*
* 以下为 README 列出的用户命令中、0–3 号脚本可能用到的部分。
* 重复安装无害;首次安装需要联网。
foreach p in drdid csdid regsave estout coefplot grc1leg2 {
    capture which `p'
    if _rc {
        display as text "installing `p' from SSC ..."
        capture ssc install `p', replace
    }
}
* 说明: 2 号脚本的 Table 7(Sant'Anna-Zhao 双重稳健)用 drdid;3 号事件研究用 csdid;
*       故 csdid/drdid 本演示需要。honestdid 仅 5 号脚本用,本演示跳过、不装。
*-----------------------------------------------------------------------------*

*--- 计时开始 ----------------------------------------------------------------*
timer clear 1
timer on 1

* 第0步:数据构建(读取包内 data/county_mortality_data.csv,无需联网)
display as result _n "===== STEP 0: build analysis data ====="
do "scripts/Stata/0_stata_Make_data.do"

* 第1步:Table 1 —— 各州医保扩张采纳时点汇总
display as result _n "===== STEP 1: adoption table (Table 1) ====="
do "scripts/Stata/1_stata_adoption_table.do"

* 第2步:2×2 DID —— 课程核心。DID 估计量 = Treat×Post 交叉项系数
display as result _n "===== STEP 2: 2x2 DiD (Tables 2-7, Figure 1) ====="
do "scripts/Stata/2_stata_2x2.do"

* 第3步:事件研究 —— 处理组虚拟变量 × 年份虚拟变量 的交叉项系数序列
display as result _n "===== STEP 3: event study (Figures 2-4) ====="
do "scripts/Stata/3_stata_2xT.do"

timer off 1
timer list 1

display as result _n "===== DEMO RUN COMPLETE ====="
display as result "请查看 tables/ (table1–7_stata.tex) 与 figures/ (figure1–4_stata.pdf)"
display as result "并与论文对应表图核对数值。"

log close
********************************************************************************
* 课堂小抄:
* - 若某步报错"command not found" → 缺用户包,ssc install 后重跑该步;
* - 若报错找不到文件 → 检查 rootdir 是否正确、是否用正斜杠;
* - 想只重跑最精彩的部分 → 单独执行 STEP 2 与 STEP 3 两行 do 命令即可。
********************************************************************************
