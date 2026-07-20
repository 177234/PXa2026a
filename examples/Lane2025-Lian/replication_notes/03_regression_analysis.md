# 第三轮：用 Stata 复现核心回归

本轮已经用 Stata 跑通论文的两项核心结果：Figure II 的动态 DID 与
Table II 的平均 ATT。没有运行作者的 R 脚本，也没有修改作者的代码或数据。

本轮的结论很直接：**公开行业面板足以用 Stata 复现论文的核心点估计。**
Figure II 的 `xtdidregress` 路径可以直接运行；Table II 的 36 个
`Post_avg` 系数与论文在四位小数下完全一致。双重稳健估计的 bootstrap
标准误则与论文有小幅差异，不能把当前环境得到的显著性星号直接当作原文星号。

## 1. 本轮运行的内容

| 对象 | 作者脚本中的实现 | 本轮 Stata-only 实现 | 结果 |
|---|---|---|---|
| Figure II | `xtdidregress`，随后把图形数据交给 R 排版 | `xtdidregress`、`estat trendplots` 与 `estat grangerplot` | 四个规格已估计并导出 PNG/PDF。 |
| Table II | `csdid`、`dripw`、`wboot reps(10000)`、`regsave` | 保留相同的 CSDID 循环与控制变量 | 9 个结果变量 × 2 个口径 × 2 个估计量，共 36 个模型完成。 |

Figure II 的 Stata 图形在
`output/figures/figure-ii-stata-only.png` 和
`output/figures/figure-ii-stata-only.pdf`。它保留了 Stata 原生的图形样式；
与论文 R 图相比，字体、图例和面板留白不同，但估计对象完全相同。

![Stata-only 复现的 Figure II](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/figure-ii-stata-only.png)

## 2. Figure II：动态 DID

作者以 `l_ship` 为结果变量，并把 1972 年设为基期。四个规格分别为：

1. 五位行业口径，不含基期控制变量；
2. 五位行业口径，加入基期控制变量与年份交互；
3. 四位行业口径，不含基期控制变量；
4. 四位行业口径，加入相同控制变量。

估计式可写为：

$$
Y_{it} = \alpha_i + \lambda_t + \sum_{k \ne -1}
\beta_k \mathbf{1}\{t-1973=k\} \times HCI_i
+ X_{i,0}'\Gamma_t + \varepsilon_{it}.
$$

其中，含控制变量的规格加入
`l_costs_0`、`l_avg_size_0`、`l_avg_wages_0` 和 `l_y_n_0`，并让它们与每个
年份交互。`_0` 表示政策前的行业均值，不能改用当期控制变量。

核心 Stata 代码如下：

```stata
* treat 只在 HCI 行业的 1973 年及以后取 1。
gen byte treat = hci == 1 & year >= 1973

xtdidregress ///
    (l_ship c.(l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0)#i.year) ///
    (treat), group(id) time(year) vce(cluster id)

* 联合检验政策前动态系数，并以 1972 年为基期画事件研究图。
estat ptrends
estat grangerplot, baseline(1972) verbose post
```

四个政策前联合检验的结果如下。它们都没有拒绝零假设，但这只是对可检验的
政策前差异的检验，不能单独证明平行趋势。

| 行业口径 | 控制变量 | `estat ptrends` F 值 | p 值 |
|---|---:|---:|---:|
| 五位 | 否 | 0.76 | 0.3843 |
| 五位 | 是 | 0.57 | 0.4491 |
| 四位 | 否 | 0.12 | 0.7259 |
| 四位 | 是 | 0.03 | 0.8680 |

从 1973 年开始，五位行业口径的动态系数迅速转正并扩大。例如，五位、无控制
规格的 1973 年系数约为 0.459，随后在 1978 年约为 1.198。这与论文 Figure II
的主要图形信息一致：被 HCI 瞄准行业的实际出货产出在政策实施后明显高于对照行业。

## 3. Table II：平均政策后 ATT

Table II 不把所有政策后年份压成一个普通的 `post × hci` 系数。作者先估计动态
ATT，再通过 `agg(event)` 取得 `Post_avg`，即政策后各相对时期 ATT 的平均值。
这就是表中每一行所报告的平均效应。

双重稳健列的核心命令为：

```stata
csdid l_ship l_costs_0 l_avg_size_0 l_avg_wages_0 l_y_n_0, ///
    time(year) ivar(id) gvar(gvar) ///
    method(dripw) wboot reps(10000) ///
    agg(event) replace
```

其中，`gvar` 对 HCI 行业取 1973，对未瞄准行业取 0。作者代码将另一列称为
`ols` 或线性 TWFE，但实际运行的是 `csdid, method(reg)`：这是 CSDID 中的回归
调整版本，不应悄悄替换成一条普通的 `reghdfe` 回归。

完整的机器可读结果在
`output/intermediate/table-ii-post-avg-all.csv`；便于阅读的表格在
`output/tables/table-ii-stata-only.md`。下面列出本机复现的结果。单元格为
系数 (标准误)，为避免混淆，本表没有重算或添加显著性星号。

| 结果变量 | 5 位 DR-IPW | 5 位 `method(reg)` | 4 位 DR-IPW | 4 位 `method(reg)` |
|---|---:|---:|---:|---:|
| 出货产出 (log) | 0.8378 (0.1931) | 0.8235 (0.1846) | 0.5923 (0.2042) | 0.5452 (0.2223) |
| 增加值 (log) | 0.7426 (0.1758) | 0.7292 (0.1742) | 0.5063 (0.2003) | 0.4586 (0.2090) |
| 总产出 (log) | 0.8383 (0.1865) | 0.8236 (0.1852) | 0.5962 (0.2049) | 0.5481 (0.2217) |
| 就业 (log) | 0.5040 (0.1651) | 0.4972 (0.1509) | 0.2941 (0.1902) | 0.2679 (0.1915) |
| 生产者价格 (log) | -0.1002 (0.0215) | -0.1012 (0.0205) | -0.1154 (0.0330) | -0.1152 (0.0304) |
| 劳动生产率 (log) | 0.1608 (0.0659) | 0.1548 (0.0680) | 0.1602 (0.0780) | 0.1371 (0.0829) |
| 出货份额 | 0.0996 (0.0266) | 0.0993 (0.0261) | 0.1072 (0.0534) | 0.0970 (0.0599) |
| 劳动份额 | 0.0979 (0.0296) | 0.0967 (0.0280) | 0.1254 (0.0514) | 0.1160 (0.0495) |
| 企业数 (log) | 0.2970 (0.1038) | 0.2908 (0.1018) | 0.1986 (0.1564) | 0.1831 (0.1549) |

### 3.1 与论文 Table II 的核对

论文 Table II 的 36 个点估计均在四位小数下复现。例如，论文优先报告的五位行业 DR-IPW 产出系数为 0.8378；本机为 0.837844。作者使用 `100 × [exp(\hat\beta - 0.5 \widehat{SE}^{2}) - 1]` 转换后，将其解释为约 128% 的出货产出增长。劳动生产率的对应系数为 0.1608，本机为 0.160769。

当前 Stata 环境下，`method(reg)` 列的标准误与论文按显示精度一致；DR-IPW 列的 10,000 次 wild-bootstrap 标准误则存在小幅差异。例如，产出的五位 DR-IPW 标准误为 论文的 0.1764、本机的 0.1931。作者未在公开包中固定 `csdid` 和 `drdid` 的版本。
由于全部点估计及线性回归调整的标准误吻合，这更像 bootstrap 或命令版本造成的推断差异；这是一项诊断性判断，不能据此断言唯一原因。

## 4. 你在 Stata 中应如何运行

先在每个 dofile 开头把 `global path` 改为包含两个项目文件夹的
父目录；本机示例为 `D:/github_lianxh/PXa2026a/examples`。随后把 Stata
当前目录切换到 `Lane2025-Lian`，依次运行：

```stata
cd "D:/github_lianxh/PXa2026a/examples/Lane2025-Lian"

* 仅检查命令，不会运行回归。
do "dofiles/00_stata_dependency_check.do"

* 运行 Figure II 的 4 个动态 DID 规格。
do "dofiles/02a_figure2_stata_Lian.do"

* 运行 Table II 的 36 个模型；默认 10,000 次 wild bootstrap。
do "dofiles/02c_table2_stata.do"
```

若只想先检查一项结果，可在 Stata 命令窗口运行：

```stata
do "dofiles/02c_table2_stata.do" 10000 l_ship
```

这会只计算 `l_ship` 的四个 Table II 规格。正式复现仍应运行不带参数的完整版本。

## 5. 本轮的边界与第四轮的衔接

这轮已经验证了最核心的主结果，但没有触及受限工厂层数据，也没有运行论文的全部
附录。第四轮建议围绕以下问题选择稳健性与识别检验：替代行业口径、政策前趋势、
处理状态的替代定义、排除特定行业，以及与出口结果和机制结果之间的连贯性。

本轮的 Stata 命令与结果文件均保存于 `../Lane2025-Lian/`，便于你在 Stata 中逐段运行
和修改。
