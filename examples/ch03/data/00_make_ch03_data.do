**# ch03 示例数据生成(模拟)
* -----------------------------------------------------------------------------
* 生成本讲「样本选择」诊断所用的公司-年度面板。全部为模拟数据，非任何真实数据库导出。
* 结构参照上市公司-年度研究数据(与第 2 讲脊柱同构：42 家 × 3 年、C39/C27/C36 三行业)。
* 本讲专用设计：加入「是否披露研发」变量 disclose，其概率随企业规模上升(大公司更可能披露)，
*   且 rd 仅在 disclose==1 时可见 —— 制造「愿意披露研发的公司往往本来就更大、更强」的样本选择结构。
* 本讲只做诊断、不做清洗，故数据本身是干净的(无缺失毛病，缺失仅来自「未披露」这一选择机制)。
* 可复现：set seed 固定随机数。运行：Stata 中 do 00_make_ch03_data.do
* -----------------------------------------------------------------------------

version 17
clear all
set more off
set seed 20260718
local out "."      // 输出到当前目录；请在本文件所在的 examples/ch03/data/ 目录下运行
cap mkdir "`out'"
cd "`out'"

**## 1 公司层面(42 家)：规模、行业、是否披露、盈利

set obs 42
gen int firm = _n
gen str6 stkcd = string(300000 + firm, "%06.0f")          // 300001..300042(与第 2 讲 2000xx 区隔)
gen str5 indcd = cond(mod(firm,3)==0,"C39", cond(mod(firm,3)==1,"C27","C36"))

* 企业规模：ln(总资产)近似对数正态，均值 11、标准差 0.8，形成右偏的资产分布
gen double lnat = rnormal(11, 0.8)
gen double at0  = exp(lnat)

* 是否披露研发：概率随规模上升(logistic)——大公司更可能披露(样本选择的来源)
gen double xb     = -0.2 + 1.3*(lnat - 11)
gen double p_disc = 1/(1+exp(-xb))
gen byte disclose = runiform() < p_disc
label define disc 0 "未披露" 1 "披露"
label values disclose disc

* 盈利能力 roa：随规模略升 + 行业差异 + 噪声(大公司→roa 略高，与披露形成混淆)
gen double roa0 = 0.04 + 0.03*(lnat-11) ///
                + cond(indcd=="C27",0.02, cond(indcd=="C39",0.01,0)) + rnormal(0,0.02)

* 营业收入、资产负债率
gen double sales0 = round(at0*(0.7 + 0.3*runiform()))
gen double lev    = 0.35 + 0.25*runiform()

**## 2 扩成三年面板(2020-2022)，各年小幅波动

expand 3
bysort firm: gen int year = 2019 + _n
gen double at    = round(at0*(1+0.05*(year-2021)))
gen double sales = round(sales0*(1+0.06*(year-2021)))
gen double roa   = roa0 + 0.005*(year-2021) + rnormal(0,0.005)
gen double size  = ln(at)

**## 3 研发：仅披露公司可见；rd_ratio 按行业分化(医药高、电子中、汽车低)

gen double rd_ratio = cond(indcd=="C27",0.09, cond(indcd=="C39",0.06,0.03)) + rnormal(0,0.01)
replace rd_ratio = . if disclose==0
gen double rd = round(sales*rd_ratio)                      // 未披露者自动为缺失

**## 4 整理与标注

keep stkcd year indcd disclose size at sales roa lev rd rd_ratio
order stkcd year indcd disclose size at sales roa lev rd rd_ratio
label variable stkcd    "证券代码"
label variable year     "年度"
label variable indcd    "行业代码"
label variable disclose "是否披露研发"
label variable size     "企业规模 ln(总资产)"
label variable at       "资产总额(万元)"
label variable sales    "营业收入(万元)"
label variable roa      "资产收益率"
label variable lev      "资产负债率"
label variable rd       "研发支出(万元,仅披露者可见)"
label variable rd_ratio "研发强度 rd/sales"
sort stkcd year
save "firm_year.dta", replace

**## 5 生成核对

di _n "==== 面板规模 ===="
count
di "公司数："
codebook stkcd, compact
di _n "==== 披露 vs 未披露：规模与盈利对比 ===="
tabstat size roa at, by(disclose) stat(mean sd n)
di _n "ch03 示例数据生成完毕。"
