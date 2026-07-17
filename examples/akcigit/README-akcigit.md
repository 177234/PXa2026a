# Akcigit et al. (2022) 扩展案例 · 州级复现材料

本目录是初级班**扩展案例**的复现材料,配套在线讲义
「[扩展案例:Akcigit et al. (2022)](https://lianxhcn.github.io/PXa2026a/appendix/F_akcigit.html)」。
课堂不讲这篇,完全留给课后自学与成品观摩。

> 论文:Akcigit, U., Grigsby, J., Nicholas, T., & Stantcheva, S. (2022). Taxation and Innovation
> in the Twentieth Century. *The Quarterly Journal of Economics*, 137(1), 329–385.
> [Link](https://doi.org/10.1093/qje/qjab022) · 复现包 [Harvard Dataverse](https://doi.org/10.7910/DVN/SR410I)。

## 目录内容

| 文件/目录 | 说明 |
|---|---|
| `Akcigit_QJE_2022.do` | 整合后的主 do 文件(州级宏观部分),**你运行的就是它** |
| `Appendix.do` | 附录结果的 do |
| `Data/state_data.dta` | 州级面板数据(已公开流传,可再分发) |
| `myado/` | 论文用到的两个自定义命令:`get_elasticities`、`make_cumul_effect_plot` |
| `dofile_original/` | 作者最初提供的原始代码(`Programs/`)与 README,供对照"原码 vs 整合版" |

## 如何复现(州级结果)

在 Stata 里:

```stata
* 1. 让 Stata 找到本论文的自定义命令(路径按你克隆的位置调整)
adopath + "examples/akcigit/myado"

* 2. 运行主 do(它会读取 Data/state_data.dta)
do "examples/akcigit/Akcigit_QJE_2022.do"
```

- 州级的**基准回归、长差分、事件研究、分仓散点图、长期累积效应**等主结果即可复现;
- **微观(发明人层面)部分依赖非公开数据,不包含在本目录**,只读不跑。

## 更推荐:让 AI 陪你复现

与其一行行啃代码,不如照在线讲义
「[AI 复现与解读工作流](https://lianxhcn.github.io/PXa2026a/appendix/F_akcigit_ai.html)」的 6 段
提示词,配合课程 skills,让 agent 帮你生成复现路线图、解释代码、整理复现日志。

## 数据与许可

- `state_data.dta` 为州级汇总数据,已在网络公开流传,课件经老师确认可再分发;
- 论文 PDF 属 *QJE* 版权,本目录**不含**,请通过上方链接获取;
- 完整原始复现包见 [Harvard Dataverse](https://doi.org/10.7910/DVN/SR410I)。
