# Lane (2025)：第二轮数据处理与 Stata 审计

> `paper_type = empirical`。本轮讨论数据从哪里来、每份数据的观察单位是什么，以及
> 作者公开包实际允许复现到哪一步。
>
> 核对日期：2026-07-20。`01_data_audit.do` 已在 Stata 19.5 实际运行；未修改或
> 覆盖作者数据。

## 1. 先给结论：公开包从哪里开始

这份 replication package 不是从原始年鉴扫描件或原始 Comtrade 下载文件开始，而是从已经处理好的分析面板开始。文件名中的 `harmonized`、`merged` 和 `cleaned4reg` 说明了这一点；README 也将这些文件列为 `data/input/` 中的输入数据。

因此，本项目能够复现的链条是：

```text
作者已构造的行业/产品面板
→ Stata 中的处理变量、样本限定与 DID 估计
→ intermediate results CSV
→ R 中的论文图形和表格
```

它不能仅凭当前公开包，从扫描的 MMS 年鉴、原始 KSIC 分类、原始 Comtrade 抽取和行业对照表开始，重建每一次去重、匹配与口径协调。这个边界要在复现报告中保留，不能把“回归跑通”写成“原始数据端完全复现”。

## 2. 数据来源和粒度

### 2.1 最核心的 MMS 行业面板

论文的国内行业分析来自韩国 Economic Planning Board 出版的 Mining and Manufacturing Census & Survey (MMS) 年度卷册。作者将这些公开卷册扫描、数字化并协调跨年行业口径，形成两份主分析面板。

| 文件 | 观测单位 | 实测范围 | 面板结构 | 首轮用途 |
|---|---|---|---|---|
| `mms_merged_harmonized_panel_cleaned4reg_5digit.dta` | 五位 KSIC 行业 × 年份 | 1970--1986 | 278 个行业 × 17 年，4,726 个观测，强平衡 | 图 II 的细分行业结果；表 II 的五位 ATT。 |
| `mms_merged_harmonized_panel_cleaned4reg_4digit.dta` | 四位 KSIC 行业 × 年份 | 1967--1986 | 88 个行业 × 20 年，1,760 个观测，强平衡 | 图 II 的长面板结果；表 II 的四位 ATT。 |

第二份数据的实际起点是 **1967 年**。作者 README 的部分文字写作 1968--1986，但 Stata `xtset id year` 的实际输出和数据文件都显示 1967--1986。后续复现应以实际数据和脚本为准，并在笔记中记录这一文档差异。

两份 MMS 面板共用以下结构：

| 变量类别 | 关键变量 | 含义 |
|---|---|---|
| 面板主键 | `id`、`year` | 复现时的行业--年份主键。实测 `isid id year` 均通过。 |
| 行业代码 | `code` | KSIC 行业代码；实测同一 `id` 内不会随时间变化。 |
| 处理定义 | `hci`、`post` | `hci` 是 HCI 定向行业指示变量；`post` 严格等于 `year >= 1973`。 |
| 主结果 | `l_ship`、`l_valueadded`、`l_grossoutput`、`l_workers`、`l_ppi`、`l_y_n` | 对数出货、增加值、总产出、就业、价格和劳动生产率。 |
| 基期控制 | `l_costs_0`、`l_avg_size_0`、`l_avg_wages_0`、`l_y_n_0` | 1973 年前的行业均值，供作者与年份虚拟变量交互或放入双重稳健 DID。 |
| 网络暴露 | `hci_share_use_tot_0` 等 | 基期投入产出关联暴露，供后续产业关联与 SUTVA 分析使用。 |

### 2.2 贸易、政策和补充数据

| 数据组 | 主要文件与粒度 | 用途 | 是否属于首轮核心 |
|---|---|---|---|
| 韩国 Comtrade--MMS 匹配面板 | `comtrade_merged_harmonized_panel_cleaned4reg_4digit.dta`；韩国 SITC 四位产品 × 年份 | RCA、出口份额等国内出口结果；作者已将 MMS 基期控制变量匹配进去。 | 否，供图 IV 和表 III。 |
| 世界 Comtrade 面板 | `comtrade_worldsitc_panel_cleaned4reg_4digit.dta`；国家 × SITC 四位产品 × 年份 | 跨国 DDD 的对照样本。 | 否。 |
| 政策强度数据 | 银行贷款、税收、法规、关税等 CSV/DTA | 说明 HCI 政策工具与政策机制。 | 否，供机制和政策分析。 |
| 投入产出关联数据 | 已写入 MMS 面板的基期关联变量及附录数据 | 前向、后向关联和溢出分析。 | 否，供第 4 轮。 |
| 厂级 MMS 微观数据 | `mms_TFP_micro.dta` | 厂级 TFP 和微观机制。 | 不可从头复现：文件未公开。 |

MMS 的 KSIC 行业层级和 Comtrade 的 SITC 产品层级不同。公开包没有提供从零构造 KSIC--SITC 对照表的脚本；因此不能把两个文件中的 `id` 或 `code` 视为天然可直接合并的键。

## 3. Stata 实测：主键、处理编码与缺失值

本轮运行的脚本是 [01_data_audit.do](/D:/github_lianxh/PXa2026a/examples/Lane2025-Lian/dofiles/01_data_audit.do)。运行日志在 [01_data_audit.log](/D:/github_lianxh/PXa2026a/examples/Lane2025-Lian/logs/01_data_audit.log)。

审计结果如下。

| 检查项 | 五位 MMS | 四位 MMS | 解释 |
|---|---:|---:|---|
| `id-year` 是否唯一 | 是 | 是 | 可以安全执行 `xtset id year`；后续不应把同一层级的数据错误地复制为多行。 |
| HCI 行业数 | 102 | 33 | `hci` 在行业内部没有变化。 |
| 非 HCI 行业数 | 176 | 55 | 对照组规模与处理组规模固定。 |
| `post` 编码错误 | 0 | 0 | `post` 与 `year >= 1973` 完全一致。 |
| 政策前 HCI 行业--年份观测 | 306 | 198 | 分别等于 102 × 3 和 33 × 6。 |
| 政策后 HCI 行业--年份观测 | 1,428 | 462 | 分别等于 102 × 14 和 33 × 14。 |
| 基期控制变量全缺失的行业数 | 40 | 2 | 含控制变量的回归会产生样本缩减，必须记录。 |

五位面板中，四个基期控制变量至少缺一个的观测占 14.39%；其中 HCI 行业占 16.67%，非 HCI 行业占 13.07%。这对应 17 个 HCI 行业和 23 个非 HCI 行业的整条时间序列缺失。四位面板中的相应比例为 2.27%，即处理组和对照组各有 1 个行业的完整时间序列缺失。

这意味着后续应区分两种样本：

- 不加入基期控制的动态 TWFE，能够保留更多行业；
- 加入四个 `_0` 基期控制或使用双重稳健 DID 时，Stata 会因完整案例要求删除部分行业。

两种结果都值得报告。样本变化不是一个小的技术细节，尤其五位面板中缺失涉及处理组和对照组，而且比例不同。

另外，`l_ship`、`l_valueadded` 等对数结果变量有少量缺失，`l_workers` 在两份主面板中完整。变量的最小值出现 0 并不自动等于经济变量为 0；在不知道作者对对数和原始零值的构造规则前，不应自行把 0 改成缺失值或加常数重算。

## 4. 公开包中的“数据处理”实际做了什么

对全部公开 `.do` 文件的静态检查显示：**没有一个实际执行的 `merge` 命令**。主分析脚本反复读取 `data/input/` 下已经完成清洗和匹配的面板，随后进行的操作主要是：

- `xtset id year`，声明行业--年份面板；
- 重建 `post = year >= 1973`，或生成 `treat = hci == 1 & year >= 1973`；
- 构造 `gvar = 1973`，供 `csdid` 识别所有 HCI 行业的共同首次处理期；
- 针对不同结果变量、行业粒度和控制变量设定循环估计；
- 对临时回归结果、预测值和作图数据 `append`，再导出 CSV。

这里的 `append` 和少量 `reshape` 服务于回归输出和图形数据，不是在把 MMS 原始数据拼成分析面板。不要将这些结果整理操作误当作原始数据清洗。

例如，图 II 的脚本只做如下处理：

```stata
use "./data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta", ///
    clear
xtset id year
gen treat = hci == 1 & year >= 1973
```

表 II 的脚本同样从预处理面板开始：

```stata
use "./data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta", ///
    clear

gen gvar = 0
replace gvar = 1973 if hci == 1
```

## 5. 如果你扩展数据，合并应遵守什么原则

作者包没有提供原始合并脚本，但你以后把自己的数据接入类似研究时，可以用下面的规则。

1. **先写清观察单位。** MMS 主面板是 `industry × year`，世界 Comtrade 是 `country × product × year`，厂级数据是 `plant × year`。合并前先写出每张表的单位，不按变量名猜测层级。

2. **先验证键，再合并。** 在 MMS 主面板中使用 `isid id year`；外部表也要在其自身层级验证键。不要使用 `merge m:m`，也不要在没有 KSIC--SITC 对照表时把 MMS 与 Comtrade 直接拼接。

3. **保留匹配诊断。** 每次合并都保存 `_merge` 的交叉表，解释未匹配记录。处理组、对照组和政策前后样本都应分别检查匹配率。

4. **冻结政策前变量。** `_0` 变量和投入产出暴露都是事前变量。它们可以与年份交互，不能用政策后的数值回填或重新计算，否则会把处理后的信息带入控制项。

5. **分开保存 4 位与 5 位版本。** 两个面板的产业定义和样本长度不同。除非有明确的分类对照表和加总规则，不要 `append` 为一张表，也不要把其中一个直接当作另一个的子样本。

下面是今后扩展数据时可复用的审计骨架；它不是作者公开包已经执行过的合并步骤：

```stata
* 主面板：行业 × 年份必须唯一。
use "mms_panel.dta", clear
isid id year

* 外部数据也要先在自己的粒度上验证唯一性。
preserve
use "external_industry_year.dta", clear
isid id year
restore

* 只有键和行业口径一致时，才执行一对一合并。
merge 1:1 id year using "external_industry_year.dta"
tab _merge hci post, missing
assert _merge == 3
drop _merge
```

如果外部数据是一行一个行业的基期特征，而主面板是一行一个行业--年份，正确关系通常是 `merge m:1 id`；但前提是基期特征确实行业内唯一，且不会引入政策后的信息。

## 6. 怎样在你的 Stata 中复跑本轮审计

在 Stata 中执行：

```stata
cd "D:/github_lianxh/PXa2026a/examples/Lane2025-Lian"
do "dofiles/01_data_audit.do"
```

若你从其他工作目录调用，可显式传入输出目录：

```stata
local lian_root ///
    "D:/github_lianxh/PXa2026a/examples/Lane2025-Lian"
do "`lian_root'/dofiles/01_data_audit.do" ///
    "D:/github_lianxh/PXa2026a/examples/Lane2025-Lian"
```

第二种写法使用 `lian_root` 拼出完整 dofile 路径。更稳妥的做法仍是先 `cd` 到 `Lane2025-Lian`，再运行第一段代码。审计完成后查看 `logs/01_data_audit.log`；脚本只读取数据，不会保存 `.dta` 文件。

第 3 轮将从这两份经过审计的面板中，先构造 `treat` 和 `gvar`，再逐步复现图 II 与表 II。
