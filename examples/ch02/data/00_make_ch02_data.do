**# ch02 脊柱数据生成（模拟）
* -----------------------------------------------------------------------------
* 生成本讲「跟着一份数据走一遍」所用的原始态数据。全部为模拟数据，非任何真实数据库导出；
* 结构仿照上市公司-年度研究数据（参照 A2_data 中 GTA 家族与 d202 的真实字段与量纲）。
* 设计：6 家「锚点公司」手工设定、承载全部教学毛病（缺失 -99/. 、离群、文本型百分比、前导零）；
* 另 36 家为确定性公式生成、数据完整、取值有真实散布，用于让分布/EDA 图形有说服力。
* 可复现（固定 input + 确定性公式，无随机数）。运行：Stata 中 do 00_make_ch02_data.do
* -----------------------------------------------------------------------------

version 17
clear all
set more off
local out "."      // 输出到当前目录；请在本文件所在的 examples/ch02/data/ 目录下运行
cd "`out'"

**## 1 公司财务表：分两批导出（append 演示）

**### 1.1 锚点公司（6 家）2020–2021：rd 缺失(-99 与 .)、文本型 lev、前导零 stkcd
input str6 stkcd int year double(sales rd at) str8 lev str5 indcd
"000101" 2020  82000   4100  65000 "38.2%" "C39"
"000101" 2021  96000   5200  72000 "41.0%" "C39"
"000102" 2020  51000   3000  40000 "52.4%" "C39"
"000102" 2021  57000   3400  44000 "50.8%" "C39"
"600201" 2020 120000   9600 150000 "33.0%" "C27"
"600201" 2021 138000  11200 168000 "31.5%" "C27"
"600202" 2020  68000    -99  72000 "45.5%" "C27"
"600202" 2021  74000   3900  78000 "44.2%" "C27"
"000301" 2020 210000   6300 260000 "58.7%" "C36"
"000301" 2021 231000   6900 275000 "57.3%" "C36"
"000302" 2020  95000   2800 110000 "49.1%" "C36"
"000302" 2021 101000      . 118000 "48.0%" "C36"
end
tempfile anch1
save `anch1'

**### 1.2 锚点公司 2022：000101 的 sales 多打一个 0（离群）
clear
input str6 stkcd int year double(sales rd at) str8 lev str5 indcd
"000101" 2022 1080000  5900  80000 "43.1%" "C39"
"000102" 2022   60000  3600  47000 "49.5%" "C39"
"600201" 2022  152000 12500 185000 "30.2%" "C27"
"600202" 2022   80000  4300  84000 "43.0%" "C27"
"000301" 2022  245000  7400 290000 "56.1%" "C36"
"000302" 2022  108000  3100 124000 "47.2%" "C36"
end
tempfile anch2
save `anch2'

**### 1.3 扩充公司（36 家 × 3 年，完整、右偏散布）
clear
set obs 36
gen f = _n
gen double base   = round(30000 * 1.06^f)                 // 右偏的规模分布
gen str6  stkcd   = string(200000 + f, "%06.0f")          // 200001..200036
gen str5  indcd   = cond(mod(f,3)==0,"C39", cond(mod(f,3)==1,"C27","C36"))
expand 3
bysort f: gen int year = 2019 + _n                        // 2020,2021,2022
gen double sales = round(base*(1+0.05*(year-2021))*(0.90+0.02*mod(f,6)))
gen double at    = round(sales*(0.80+0.05*mod(f,7)))
* 研发强度按行业分化：医药(C27)高、电子(C39)中、汽车(C36)低，另加公司/年度小幅变化
gen double ratio = cond(indcd=="C27",0.090, cond(indcd=="C39",0.060,0.025)) + 0.004*mod(f,4) + 0.003*mod(year,2)
gen double rd    = round(sales*ratio)
gen levn = 30 + mod(f*13,30)
gen str8 lev = string(levn,"%3.1f") + "%"
keep stkcd year sales rd at lev indcd
preserve
  keep if year<=2021
  tempfile gen1
  save `gen1'
restore
keep if year==2022
tempfile gen2
save `gen2'

**### 1.4 组装：锚点在前，扩充在后
use `anch1', clear
append using `gen1'
label variable stkcd "证券代码"
label variable sales "营业收入(万元)"
label variable rd    "研发支出(万元)"
label variable at    "资产总额(万元)"
label variable lev   "资产负债率(文本)"
label variable indcd "行业代码"
save "firm_finance_2021.dta", replace

use `anch2', clear
append using `gen2'
label variable stkcd "证券代码"
label variable sales "营业收入(万元)"
label variable rd    "研发支出(万元)"
label variable at    "资产总额(万元)"
label variable lev   "资产负债率(文本)"
label variable indcd "行业代码"
save "firm_finance_2022.dta", replace

**## 2 行业代码对照表（m:1 合并键；毛病：C36 的键写成小写带空格 "c36 "）
clear
input str5 indcd str60 indname
"C39" "计算机、通信和其他电子设备制造业"
"C27" "医药制造业"
"c36 " "汽车制造业"
end
label variable indcd   "行业代码"
label variable indname "行业名称"
save "industry_lookup.dta", replace

**## 3 月度市值表（聚合演示；毛病：stkcd 存成数值型、前导零丢失；一年 12 行）
clear
input double stkcd double basecap
101 380
102 210
201 640
202 300
301 880
302 430
end
tempfile mk_anch
save `mk_anch'
clear
set obs 36
gen f = _n
gen double stkcd   = 200000 + f
gen double basecap = round(150 + 20*mod(f,9) + 4*f, 0.1)
drop f
append using `mk_anch'
expand 12
bysort stkcd: gen int mon = _n
gen long ym = 202100 + mon                       // 202101 .. 202112
gen double mktcap = round(basecap * (1 + 0.012*(mon-6)) + mod(stkcd,7)*3, 0.1)
drop basecap mon
label variable stkcd  "证券代码(数值,丢前导零)"
label variable ym     "年月"
label variable mktcap "月末市值(亿元)"
order stkcd ym mktcap
save "mktcap_monthly.dta", replace

**## 4 生成核对
foreach f in firm_finance_2021 firm_finance_2022 industry_lookup mktcap_monthly {
  di _n "==== `f' ===="
  use "`f'.dta", clear
  describe, short
}
di _n "ch02 脊柱数据生成完毕。"
