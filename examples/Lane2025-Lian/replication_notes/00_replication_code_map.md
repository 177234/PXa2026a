# Lane (2025) 复现包：代码与可复现边界地图

> 范围：作者提供包的静态检查。未运行 Stata、R 或 Python，未改动作者文件。
>
> 核对日期：2026-07-20。

## 1. 实际运行链

完整流程的总入口是 `replicationpackage/master.R`，而不是单独的 Stata dofile：

```text
master.R
├─ setup/setup.do
├─ code/0_analysis/0_master_run_analysis.do
│  ├─ 1_main_scripts/0_1_master_run_main_analyses.do
│  ├─ 2_appendix_scripts/0_2_master_run_appendix_analyses.do
│  └─ 3_suppappendix_scripts/0_3_master_run_suppappendix_analyses.do
├─ setup/setup.R
├─ code/1_figures/0_master_run_figure.R
├─ code/2_tables/0_master_run_table.R
├─ code/3_appendix/0_master_run_appendix.R
└─ code/4_suppappendix/0_master_run_suppappendix.R
```

作者 README 的建议是：在 `config.yml` 设置 Stata 可执行文件和版本后，从 RStudio 运行 `master.R`。README 要求 R 4.3 以上、Stata 17 以上，并称完整运行至少约 1 小时； `master.R` 注释中则将 Stata 阶段标为约 2--3 小时。

## 2. 与首轮有关的代码

| 目标 | Stata 脚本 | R 排版脚本 | 关键中间文件 |
|---|---|---|---|
| 图 II | `1_main_scripts/1_run_growth_analysis.do` | `1_figures/Figure2.R` | `did_largerolling_mainresults_alloutput*_all_results.csv` |
| 表 II | `1_main_scripts/3b_run_doublerobust_analysis.do` | `2_tables/Table2-4.R` | `doublyrobust_all_results.csv`、`doublyrobust_att.csv` |

图 II 的 Stata 脚本读取已协调口径的 MMS 行业面板，并用 `xtdidregress`、 `estat trendplots` 与 `estat grangerplot` 生成可供 R 作图的数据。表 II 的脚本使用 `csdid`、`drdid` 和 `regsave`，生成双重稳健与回归型 DID 的结果文件；R 脚本将其转为论文中的 LaTeX 表。

## 3. 数据可得性

包内共有约 138 MB 数据。首轮核心面板均在本地：

- `data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta`：1970--1986 年、五位 KSIC 行业--年份面板，4,726 个观测；
- `data/input/mms_merged_harmonized_panel_cleaned4reg_4digit.dta`：1968--1986 年、四位 KSIC 行业--年份面板，1,760 个观测；
- `data/input/comtrade_merged_harmonized_panel_cleaned4reg_4digit.dta`：韩国 SITC 四位产品--年份贸易面板，供出口分析使用。

未提供 `data/input/mms_TFP_micro.dta`。它是受限的厂级 MMS 数据，关联主文 Table I、Table VI 及若干附录。已有的预置 CSV 可以阅读这些结果，但不能重新估计。该限制不影响首轮的图 II 和表 II。

原始 MMS 年鉴数字化、行业口径协调，以及 Comtrade 与 MMS 的匹配已经在提供的分析面板中完成；包内未见可从原始来源重建这些步骤的完整清洗和合并脚本。

## 4. 运行风险与第 3 轮策略

- `setup/setup.do` 会安装 `reghdfe`、`ppmlhdfe`、`regsave`、`estout`、`ftools`、 `csdid`、`drdid`、`erepost`、`binscatter` 与 `gph2xl` 等外部命令，首次运行需要联网。
- 顶层 Stata driver 中 `RUN_MICRO` 的默认值为 `1`，可能触发依赖缺失微观数据的脚本。因而不应直接运行全量 `master.R`。
- README 与部分辅助文档存在目录名、日志名和 bootstrap 文件名不一致的情况。第 3 轮应以实际脚本为准，并先运行仅含图 II 与表 II 的教学 wrapper。

建议的最小执行顺序是：

```text
验证环境与外部命令
→ 1_run_growth_analysis.do（图 II 的 Stata 部分）
→ 3b_run_doublerobust_analysis.do（表 II 的 Stata 部分）
→ 只调用 Figure2.R 与 Table2-4.R 的相应片段
→ 与论文图 II、表 II 核对
```

在第 2 轮完成变量和数据审计前，不直接执行这条链。

