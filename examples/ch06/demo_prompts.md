# 给 AI Agent 的复现任务提示词

**复现对象**：Baker, Callaway, Cunningham, Goodman-Bacon & Sant'Anna (2026). "Difference-in-Differences Designs: A Practitioner's Guide." *Journal of Economic Literature*, 64(2), 498–557. DOI: 10.1257/jel.20251650
**复现包**：<https://github.com/pedrohcgs/JEL-DiD> (Release "Replication files")

本文件含三个版本：A 中文分步演示版 (推荐现场用)；B 中文一次性全自动版；C 英文一次性版。
课堂现场建议用 A 版——每一步停下来等你说「继续」，推进节奏在你手里，每一步都是一个讲解锚点。

---

## A. 中文分步演示版 (推荐)

```
你是一名实证经济学复现助理,现在是课堂现场演示。规则:
- 我们分步进行。每完成一步,停下来等我说"继续"再进入下一步;
- 每步开始前先用两三句话向课堂听众解释这一步在做什么、为什么重要;
- 复现对象与任务范围同下,禁止运行 4_GxT 与 5_honestdid 两个脚本,不得修改估计逻辑。

论文:Baker et al. (2026, JEL 64(2): 498–557),"DiD 实践者指南"。
复现包路径:<在此填写解压后的包根目录>。

步骤1:读 README,复述数据来源、文件结构与运行顺序,给出复现计划。→ 停,等指令。
步骤2:清点 data/,核对县级面板(约 3,143 县 × 2010–2019)与关键变量。→ 停,等指令。
步骤3:设置路径,运行包根目录下的 run_demo.do 中"数据构建 + Table 1"部分。→ 停,等指令。
步骤4:运行 2×2 双重差分部分(Tables 2–7、Figure 1),
      并用一句话解释:表中的 DID 估计量就是 Treat × Post 交叉项的系数。→ 停,等指令。
步骤5:运行事件研究部分(Figures 2–4),打开图,
      解释每个点是"处理组虚拟变量 × 年份虚拟变量"的交叉项系数,
      以及处理前系数接近 0 意味着什么。→ 停,等指令。
步骤6:把跑出的主结果表与论文原表并排对照,逐项报告是否一致,输出一页复现报告。
```

---

## B. 中文一次性全自动版

```
你是一名实证经济学复现助理。请复现下面这篇论文复现包中的核心结果,并全程记录你执行的每一条命令。

论文:Baker, Callaway, Cunningham, Goodman-Bacon & Sant'Anna (2026),
"Difference-in-Differences Designs: A Practitioner's Guide",
Journal of Economic Literature 64(2): 498–557。
复现包已下载解压到本机目录:<在此填写路径>(内含 data/、scripts/、figures/、tables/、README)。

【任务范围——严格遵守】
1. 只复现"课程范围内"的部分:数据构建、政策采纳时点表(Table 1)、
   2×2 双重差分(对应 2_2x2 脚本,产出 Tables 2–7 与 Figure 1)、
   两组多期事件研究(对应 3_2xT 脚本,产出 Figures 2–4)。
2. 明确禁止运行:4_GxT(多期错峰估计)与 5_honestdid(敏感性分析)两个脚本。
3. 不得修改任何估计逻辑;只允许修改路径设定、注释掉联网取数步骤、安装缺失的软件包。

【执行步骤】
第1步 通读 README,向我复述:数据来源、文件结构、运行顺序、软硬件要求,
     并给出你的复现计划(不超过 10 行)。
第2步 清点 data/ 目录,核对主数据 county_mortality_data.csv(及同内容的 .dta):
     确认观测单位为美国县级、样本约 3,143 个县 × 2010–2019 年,列出关键变量名。
     如与 README 描述不符,先报告再继续。
第3步 使用 Stata 路线(若本机无 Stata 则改用 R 路线,并说明):
     打开 scripts/Stata/00_stata_master_did_jel.do,确认全局路径宏的写法,
     然后运行我提供的裁剪版主控脚本 run_demo.do(已放在包根目录),
     它只调用 0→1→2→3 号脚本。
     注意:0 号数据构建脚本若涉及联网取数,按 README 指引使用包内已含的最终数据。
第4步 若报错:先诊断(最常见为缺包→从 SSC 安装、路径未设、写入权限),
     每个错误最多重试 2 次;仍失败则停下,报告错误信息与你的判断,等待我指示。
第5步 运行结束后,列出 figures/ 与 tables/ 中新生成的文件,
     打开 2×2 主结果表与事件研究图,与论文对应表图逐项核对系数、标准误与样本量,
     报告"完全一致 / 数值层面一致(仅舍入差异)/ 不一致(列明差异)"。

【产出物】
- 一份不超过一页的《复现报告》:运行环境、总耗时、执行的脚本清单、
  每个表/图的核对结论、遇到的问题及解决方式。
- 全程命令日志。

【风格】每进入一个步骤前,用一两句话说明你要做什么、为什么;完成后用一句话总结结果。
```

---

## C. English version (one-shot)

```
You are a replication assistant for empirical economics. Reproduce the core,
intro-level results from the replication package below, logging every command you run.

Paper: Baker, Callaway, Cunningham, Goodman-Bacon & Sant'Anna (2026),
"Difference-in-Differences Designs: A Practitioner's Guide",
Journal of Economic Literature 64(2): 498–557.
The package has been downloaded and unzipped at: <PATH> (contains data/, scripts/,
figures/, tables/, README).

SCOPE — strict:
1. Reproduce ONLY: data construction; the adoption-timing table (Table 1);
   the 2x2 difference-in-differences analysis (script 2_2x2; Tables 2–7, Figure 1);
   and the two-group event study (script 3_2xT; Figures 2–4).
2. Do NOT run 4_GxT (staggered estimators) or 5_honestdid (sensitivity analysis).
3. Do not alter any estimation logic. You may only edit path settings, comment out
   internet-dependent data pulls (use the shipped final dataset per the README),
   and install missing packages.

STEPS:
1) Read the README; summarize data sources, folder structure, run order, and
   software requirements; propose a replication plan (max 10 lines).
2) Inventory data/; verify the main dataset county_mortality_data.csv (and the
   equivalent .dta): a US county panel, ~3,143 counties x 2010–2019; list key variables.
   Report any mismatch with the README before proceeding.
3) Use the Stata pipeline (fall back to R if Stata is unavailable, and say so).
   Inspect scripts/Stata/00_stata_master_did_jel.do to confirm how the root-path
   global is set, then run the trimmed driver run_demo.do placed at the package
   root, which calls only scripts 0 -> 1 -> 2 -> 3.
4) On any error: diagnose first (most likely a missing SSC package, an unset path,
   or write permissions); retry at most twice; otherwise stop and report.
5) After the run, list newly created files in figures/ and tables/; open the main
   2x2 table and the event-study figures; compare coefficients, standard errors,
   and sample sizes against the published exhibits; classify each as
   "exact match / match up to rounding / mismatch (explain)".

DELIVERABLES: a one-page replication report (environment, total runtime, scripts
executed, per-exhibit verification results, problems and fixes) plus the full
command log. Before each step, explain in 1–2 sentences what you are doing and why.
```

---

## 使用备注

1. 提示词里的 `<在此填写路径>` / `<PATH>` 换成解压后的包根目录；`run_demo.do` (或 R 路线的 `run_demo.R`) 先复制到该根目录。
2. 若用能自己联网的 Agent，也可以把「第 0 步：从 <https://github.com/pedrohcgs/JEL-DiD> 下载 Release 并解压」加回提示词开头——但课堂上更稳的做法是提前下好。
3. 只跑 Stata 或只跑 R 其中一条线即可，另一条留作「回去换语言再复现一次」的作业。
