# 第一轮质量记录

日期：2026-07-20。

## 已读取和核对的材料

- 论文主文 PDF 与 online appendix；
- `replicationpackage/README.md`、`code/README.md`；
- `master.R` 的工作流说明、Stata 主 driver 与主文结果脚本；
- 图 II、表 II 的 PDF 原始页；
- 两份 MMS 主分析面板的 codebook，以及数据文件和输出目录的静态清单。

## 本轮生成的文件

- `replication_notes/01_paper_analysis.md`：论文、识别策略和最小复现集；
- `replication_notes/00_replication_code_map.md`：运行链、数据可得性与执行边界；
- `figs/raw/`：论文图 II 与表 II 的原始页和裁取版本；
- `figs/uploaded-images.md`、`uploaded-images.json`、`uploaded-images.csv`：图片链接清单。

本轮未运行 Stata、R 或 Python 项目代码，未安装 Stata 外部命令，未修改作者提供的代码或
数据。所有新增文件均放在 `../Lane2025-Lian/`。

## 第二轮更新：数据审计

- 已在 Stata 19.5 实际运行 `dofiles/01_data_audit.do`；主日志为
  `logs/01_data_audit.log`。
- 两个 MMS 主面板均通过 `isid id year`；五位面板为 278 个行业 × 17 年，四位面板为
  88 个行业 × 20 年。
- HCI 身份在行业内不变，行业代码在同一 `id` 内不变，`post` 与 `year >= 1973`
  完全一致。
- 五位面板有 40 个行业、四位面板有 2 个行业缺失全部基期控制变量；含控制变量的
  回归必须报告由此引起的样本变化。
- 首次批处理调用使用相对 dofile 路径，Stata 未找到文件。该启动日志已保留为
  `logs/01_data_audit_attempt_1.log`；改用绝对路径和输出目录参数后，审计成功完成。

## 图片处理与链接

| 图片 | 用途 | 图床链接 |
|---|---|---|
| `figure-ii-industrial-output.png` | 论文图 II 的裁取版本，插入第一轮笔记。 | [image](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/figure-ii-industrial-output.png) |
| `table-ii-industrial-development.png` | 论文表 II 的裁取版本，插入第一轮笔记。 | [image](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/table-ii-industrial-development.png) |
| `figure-ii-source-page-20.png` | 图 II 的完整 PDF 页，保留作溯源。 | [image](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/figure-ii-source-page-20.png) |
| `table-ii-source-page-28.png` | 表 II 的完整 PDF 页，保留作溯源。 | [image](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/table-ii-source-page-28.png) |

本机 PicGo-Server 可以连接，上传脚本返回了以上公开链接并生成清单。正文中的图片引用均为
图床链接，没有残留本地图片 Markdown 引用。

## 已识别的边界与风险

- 公开包的核心 MMS 行业面板已是 harmonized/merged/cleaned 分析数据；未提供从原始
  年鉴、原始 Comtrade 提取到最终面板的完整清洗链。
- 受限的 `mms_TFP_micro.dta` 缺失；因此微观 TFP 和相关附录结果不能从头重新估计。
- 顶层 Stata driver 可能默认运行微观模块，完整 `master.R` 不适合直接作为第一条命令。
- 图 II 与表 II 不依赖受限微观数据，是后续 Stata 最小复现的优先目标。

## 第三轮更新：核心回归的 Stata-only 复现

- 已在 Stata 19.5 实际运行 `dofiles/00_stata_dependency_check.do`、
  `dofiles/02a_figure2_stata.do`、`dofiles/02b_table2_probe.do` 和
  `dofiles/02c_table2_stata.do`。日志位于 `logs/`。
- Figure II 的四个 `xtdidregress` 规格已完成，图形位于
  `output/figures/figure-ii-stata-only.png` 和 `.pdf`。政策前联合检验 p 值依次为
  0.3843、0.4491、0.7259、0.8680。
- Table II 的 36 个模型已经完成。`output/intermediate/table-ii-post-avg-all.csv`
  保存每个模型的 `Post_avg`、标准误、p 值和置信区间；点估计与论文表 II 在四位小数下
  完全一致。
- 复现脚本调用与作者相同的 10,000 次 `wboot`，并采用作者 `setup.do` 中的
  `set seed 1312` 和 `set sortseed 1231`。当前 `csdid` 版本的 DR-IPW 标准误仍与论文
  报告值略有差异，最明显的例子是五位行业出货产出：本机为 0.1931，论文为 0.1764。
- `csdid`、`drdid` 和 `regsave` 已可用。`gph2xl` 缺失，但它只用于把 Stata 图形数据
  交给 R；本轮没有安装，也不影响 Stata 的估计和原生图形导出。
- 一次首次绘图尝试错误地把 16 个临时图形副本写到 `D:\` 根目录；已核对正确版本在
  输出目录后，删除了这 16 个确切的临时副本。
- 已删除交付目录根部两份 Stata 批处理自动日志；它们含许可证序列号且与 `logs/` 下的
  正式复现日志重复。其余日志、图形、表格和数据输出均已保留。
- 首次 PicGo 检查超时。用户启动 PicGo 后，已成功上传 Stata Figure II，并将图床链接
  插入 `replication_notes/03_regression_analysis.md` 和 `figs/uploaded-images.md`；JSON 和
  CSV 清单也已同步更新。

## 第四轮预研：稳健性与识别逻辑

- 已精读主文中关于主 DID、DR-DID、跨国 DDD 与 SUTVA 的部分，并核对在线附录
  B、D、G 的文字说明和相关 Stata 脚本。
- 新增 `replication_notes/04_robustness_logic.md`。该报告按识别威胁而非表格顺序，
  解释作者的 SUTVA、跨国 DDD、动态政策前检验、连续处理、贸易保护与投资拥挤出分析。
- 本轮未运行新的 Stata 回归，未修改作者代码或数据；没有生成新的图片，也没有调用 R。

## 本次更新：统一 Stata 路径入口

- 以已跑通的 `dofiles/02a_figure2_stata_Lian.do` 为模板，更新了
  `00_stata_dependency_check.do`、`01_data_audit.do`、
  `02b_table2_probe.do` 和 `02c_table2_stata.do` 的路径入口。
- 四个 dofile 现在都在开头定义同一 `global path`，并据此构造
  `Lane2025-Lian` 输出目录与 `replicationpackage` 数据目录；不再依赖
  当前工作目录或 `supplied_output_root` 参数。
- `02b_table2_probe.do` 的可选参数为 `bootstrap_reps`；
  `02c_table2_stata.do` 的可选参数依次为 `bootstrap_reps` 和
  `outcome_subset`。因此，单结果测试的命令是
  `do "dofiles/02c_table2_stata.do" 10000 l_ship`。
- 已静态核对：旧路径逻辑没有残留，新路径均指向存在的目录，修改的 dofile 没有超过
  76 个字符的代码行。本次没有运行 Stata，结果文件未改变，待用户本机测试。
