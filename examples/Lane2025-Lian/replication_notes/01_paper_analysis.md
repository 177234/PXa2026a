# Lane (2025, QJE)：第一轮论文与识别策略笔记

> 范围：研究问题、因果识别、核心结果与最小复现集。本文只做原文和代码的只读核对，未运行 Stata 或 R。
>
> 核对日期：2026-07-20。主要依据：论文 PDF、online appendix 与作者提供的 replication package。

## 1. 论文研究什么

Nathan Lane 的论文 *Manufacturing Revolutions: Industrial Policy and Industrialization in South Korea* 研究韩国政府在 1973--1979 年推进重化工业 (Heavy and Chemical Industries, HCI) 政策后，被定向行业是否获得了更快的工业增长与出口比较优势。

论文的历史背景是，1973 年韩国在外部安全环境变化下启动 HCI 推进计划；朴正熙遇刺后，政策在 1979 年后实质退出。政策组合包括定向信贷、投资税收优惠及部分进口投入品优惠。作者的核心结论针对这一**政策组合**，不把结果归因于某一项工具，也不直接估计总体福利、财政成本或资源配置效率。

研究对象是韩国制造业行业，而非企业或地区：

- 细分面板为五位 KSIC 行业--年份，1970--1986 年；
- 长面板为四位 KSIC 行业--年份，1968--1986 年；
- 处理组是被 HCI 立法及实施令覆盖的行业，包括钢铁、有色金属、造船、机械、电子和石化；
- 对照组是未被 HCI 立法覆盖的其他韩国制造业行业。

首轮只聚焦工业发展结果：实际出货产出、增加值、就业、价格与劳动生产率。出口、机制和产业关联溢出留到后续轮次。

## 2. 作者怎样构建因果推断设计

### 2.1 基准设计：动态 DID

作者的主设计是行业层面的动态双重差分 (DID)。令 `Targeted_i` 表示行业 $i$ 是否属于 HCI，基准年为 1972 年，则事件研究可写为：

$$
\log(Y_{it})=\alpha_i+\lambda_t+
\sum_{s\ne 1972}\beta_s
\left(Targeted_i\times 1\{t=s\}\right)+
\sum_{s\ne 1972}\Gamma_s
\left(X_i^{pre}\times 1\{t=s\}\right)+\varepsilon_{it}.
$$

其中，$\alpha_i$ 是行业固定效应，$\lambda_t$ 是年份固定效应；$X_i^{pre}$ 包含 1973 年前的行业平均中间投入、工资、厂均规模和劳动生产率，并与年份虚拟变量交互。标准误按行业聚类。$\beta_s$ 衡量 HCI 行业相对于非 HCI 行业、在年份 $s$ 相对于 1972 年的额外变化。

这个设计所需的关键识别假设是：若 HCI 政策没有推出，两类行业的结果变量应具有可比的条件趋势。政策目标行业显然不是随机抽取，因此 1973 年的政策转向本身不能消除 “哪些行业被选中”的问题；政策前的动态系数和加入基期特征后结果是否稳定，只能提供对平行趋势的支持，不能证明反事实必然成立。

作者还需要面对对照组受溢出的风险。例如，非 HCI 行业若因使用 HCI 投入品而受益，处理组与对照组的差距会被压缩。这也是后文产业关联分析和低暴露对照组检验的动机。

### 2.2 表 II 的首选估计量：双重稳健 DID

表 II 的第一列和第三列采用 Callaway--Sant'Anna 框架下的双重稳健 DID。所有 HCI 行业在 1973 年同时进入处理，估计量的目标是被处理行业的平均处理效应 (ATT)。作者将倾向得分模型与未处理结果变化模型结合；在共同支撑和条件平行趋势成立时，只要其中一个辅助模型设定正确，ATT 仍具有一致性。

这比普通 TWFE 多了一层对模型设定的保护，但并不替代识别假设。表 II 同时报出 TWFE 结果，作用是核对结论是否依赖于具体估计量，而不是把 TWFE 当作额外的因果来源。

### 2.3 这篇论文还能提供什么补充证据

出口部分使用跨国、跨行业和时间的三重差分 (DDD)，把韩国 HCI 行业的变化与其他国家相应行业作比较。它提供不同反事实下的补充证据，但不是第一轮的必跑内容。厂级 TFP 结果只从 1979 年后开始，缺少政策前厂级数据；它适合作为退出政策后的相关性证据，不能视作独立的政策前后 DID。

## 3. 首轮应复现的两项核心结果

首轮的最小复现集定为**图 II 与表 II**。二者共同回答“政策前两组行业走势是否可比” 以及“政策期平均效应有多大”。这样可以先闭环复现论文最核心的国内行业证据，不被出口、微观数据和投入产出网络的额外复杂性拖慢。

| 优先级 | 论文结果 | PDF 页码 | 主要回答的问题 | 对应作者代码 |
|---|---|---:|---|---|
| 必做 | Figure II：Industrial Policy and Industry Output | 20 | 动态 DID、政策前趋势、1973 年后变化与 1979 年后持续性。 | `code/0_analysis/1_main_scripts/1_run_growth_analysis.do` → `code/1_figures/Figure2.R` |
| 必做 | Table II：Average Effect of Industrial Policy: Industrial Development | 28 | 五位、四位面板下双重稳健 ATT 与 TWFE 是否给出一致结论。 | `code/0_analysis/1_main_scripts/3b_run_doublerobust_analysis.do` → `code/2_tables/Table2-4.R` |
| 下一步 | Figure IV 与 Table III | 32、29 | 以跨国 DDD 和出口 ATT 检验比较优势的变化。 | `3c_run_worldtrade_analysis.do`、`3b_run_doublerobust_analysis.do` |

图 VI 与表 VII--VIII 的产业关联结果，以及微观 TFP、MRPK、挤出效应等附录分析，留到第 4 轮再讨论。它们的解释需要额外的投入产出暴露度、样本可得性与 SUTVA 判断。

### 3.1 图 II：为什么它是首要图形

![论文图 II：HCI 政策与行业产出](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/figure-ii-industrial-output.png)

图 II 的上排是处理组与对照组的模型预测产出路径，下排是相对 1972 年的动态 DID 系数及 95% 置信区间。左半部分使用 1970 年开始的五位行业面板，右半部分使用 1967 年开始的四位行业面板；每部分均报告不加控制和加入基期特征 × 年份交互的版本。

图中应重点看三点：

- 1973 年前，下排系数接近 0，未显示稳定的事前差异趋势；五位面板的政策前期仅有 1970--1972 年，检验力仍有限。
- 1973 年后，HCI 行业的相对产出系数上升；这与政策期内定向行业的额外扩张一致。
- 1979 年是朴正熙政权结束点。图形呈现的是相对差异在政策退出后仍保持，而不是证明每一年效应都由原政策直接造成。

生成图 II 的核心 Stata 代码位于 `replicationpackage/code/0_analysis/1_main_scripts/1_run_growth_analysis.do`。其最关键的五位行业部分可概括为：

```stata
* 作者读取已经协调口径的行业--年份面板。
use "./data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta", ///
    clear
xtset id year

* 所有 HCI 行业在 1973 年同时进入处理。
gen treat = hci == 1 & year >= 1973

* 基期行业特征分别与年份虚拟变量交互。
local controls ///
    c.(l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0)#i.year

* 动态 DID 的基础估计；图 II 的结果变量是 l_ship。
xtdidregress (l_ship `controls') (treat), ///
    group(id) time(year) vce(cluster id)

* 相对于 1972 年导出动态处理效应和预测趋势。
estat trendplots, ltrends noxline
estat ptrends
estat grangerplot, baseline(1972) verbose post
```

作者脚本会对 `l_ship`、`l_grossoutput` 与 `l_valueadded` 循环，并分别生成有无控制变量、五位与四位面板的结果。随后以 `gph2xl` 导出数据，R 脚本 `Figure2.R` 将其排版为论文图。

### 3.2 表 II：怎样读首选 ATT

![论文表 II：产业发展平均效应](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/table-ii-industrial-development.png)

表 II 的列 (1) 是首选五位行业双重稳健 ATT，列 (2) 是相应的 TWFE；列 (3)--(4) 用较长但较聚合的四位行业面板做同样的比较。所有结果变量均为对数。

最需要记住的三项首选结果来自列 (1)：

- 实际出货产出系数为 `0.8378`，标准误为 `0.1764`。作者按对数正态校正 $100[\exp(\hat\beta-0.5\widehat{SE}^2)-1]$ 换算，约为 **128%** 的相对增长。
- 劳动生产率系数为 `0.1608`，对应约 **17.2%** 的相对提升。
- 产品价格系数为 `-0.1002`，对应约 **9.6%** 的相对下降。

四位行业面板的产出系数较小，但仍显著为正；TWFE 与双重稳健结果也很接近。这说明主结论不只由一个面板粒度或一个估计器驱动，但仍应把它解释为 HCI 行业相对非 HCI 行业的 ATT，而不是整个韩国制造业的平均效应。

表 II 的核心 Stata 实现如下。作者将所有处理行业的首次处理期编码为 `1973`，并在每个结果变量、每种行业粒度下分别运行回归型 DID 与双重稳健 DID；双重稳健标准误使用 10,000 次 wild bootstrap。

```stata
* 处理组首次受政策影响的年份；从未处理组保持为 0。
gen gvar = 0
replace gvar = 1973 if hci == 1

local controls ///
    l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0

* 表 II 列 (1) 的核心思路：以实际出货产出为例。
csdid l_ship `controls', ///
    time(year) ivar(id) gvar(gvar) ///
    method(dripw) wboot reps(10000) ///
    agg(event) replace

* 同一数据上的回归型 DID，对应表 II 的 TWFE 对照列。
csdid l_ship `controls', ///
    time(year) ivar(id) gvar(gvar) ///
    method(reg) agg(event) replace
```

这里的 `agg(event)` 先保留动态事件时间效应；作者的导出程序再从中提取政策后的平均 `Post_avg`，交给 `Table2-4.R` 排版为表 II。第 3 轮将逐行运行并核对这些输出，而不是在第一轮直接运行耗时的 10,000 次 bootstrap。

## 4. 本轮对后续复现的影响

第一轮的结论是：后续 Stata 实操应以“已处理的行业--年份分析面板”为起点，而不是以原始年鉴扫描件为起点。作者提供的包包含以下两份核心输入：

- `data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta`：五位行业--年份面板；
- `data/input/mms_merged_harmonized_panel_cleaned4reg_4digit.dta`：四位行业--年份面板。

包中没有从原始 MMS 年鉴、原始 Comtrade 抽取和逐项行业匹配重建这些面板的完整清洗链。因此，公开包能够复现“预处理面板 → Stata 估计 → R 表图”的部分；它不能单独复现从全部原始来源端开始的数字化、协调口径与合并过程。第 2 轮会把这一区分讲清楚，并以变量、粒度、键和作者已完成的匹配为中心做数据审计。

此外，完整 `master.R` 流程会调用缺失的保密厂级 MMS 数据，并要求先联网安装 Stata 外部命令。图 II 与表 II 不依赖这份微观数据，因此可以设计为独立、可控的 Stata 最小路径。

## 5. 第一轮结论与下一步

这篇论文的核心识别是：将 1973 年 HCI 政策冲击与行业是否被定向相交互，在行业固定效应、年份固定效应和基期特征的条件下，比较目标与非目标制造业行业的差异变化。首选估计量是双重稳健 DID，动态 TWFE 事件研究用于呈现走势和政策前检验。

下一轮建议进入数据审计：先读两份 MMS 主面板和对应 codebook，逐项解释 `id`、`year`、 `hci`、`post`、`l_ship`、`l_costs_0` 等变量的含义，并判断哪些“合并”已经由作者在公开包之外完成。完成后再编写只跑图 II 与表 II 的教学 dofile。

## 参考资料

1. Lane, Nathan. (**2025**). Manufacturing Revolutions: Industrial Policy and Industrialization in South Korea. *The Quarterly Journal of Economics*, 140(3), 1683--1741. [Link](https://academic.oup.com/qje/article/140/3/1683/8152916), [Google](<https://scholar.google.com/scholar?q=Manufacturing+Revolutions+Industrial+Policy+and+Industrialization+in+South+Korea>).

