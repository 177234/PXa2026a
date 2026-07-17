################################################################################
# run_demo.R — 课堂演示用裁剪版主控脚本(R 路线)
# 复现对象: Baker, Callaway, Cunningham, Goodman-Bacon & Sant'Anna (2026, JEL 64(2))
#           复现包: https://github.com/pedrohcgs/JEL-DiD
#
# 只运行"初级班范围内"的部分:
#   0_make_data.R       —— 数据构建
#   1_Adoption_Table.R  —— Table 1
#   2_2x2.R             —— 2×2 双重差分: Tables 2–7, Figure 1
#   3_2XT.R             —— 事件研究: Figures 2–4
# 跳过(超纲): 4_GxT.R, 5_honestdid.R
#
# 【重要】本脚本按官方 README 记载的结构编写。README 中数据构建脚本出现过
# 0_make_data.R / 0_data_processing.R 两种写法,下载后以 scripts/R/ 目录里的
# 实际文件名为准,必要时改下面 STEP 0 的文件名。
# 使用方法:推荐直接双击打开包根目录的 DiD_JEL.Rproj(自动设好工作目录),
# 再运行本脚本;或手动 setwd() 到包根目录。
################################################################################

## ------------------ SETUP ---------------------------------------------------
## 若未通过 .Rproj 打开,请取消注释并改路径:
# setwd("C:/path/to/JEL-DiD")

## 依赖恢复:首次运行会按 renv.lock 下载安装全部包,可能需要 5–15 分钟。
## 【务必课前预热】课堂上再次运行时只做校验,几秒即过。
if (requireNamespace("renv", quietly = TRUE)) {
  renv::restore(prompt = FALSE)
} else {
  install.packages("renv"); renv::restore(prompt = FALSE)
}

t0 <- Sys.time()

## ------------------ STEP 0: 数据构建 ----------------------------------------
## 注意:该脚本中有一步会联网调用 Census API 抓取贫困率/收入变量。
## 按 README 的说明,包内已附带含这些变量的最终数据
## (data/county_mortality_data.csv)。课堂断网或网络慢时,
## 打开 0_make_data.R 把 Census API 那一段注释掉再运行本步;
## 或者干脆跳过本步(后续脚本直接读取包内最终数据即可,视脚本写法而定)。
message("===== STEP 0: build analysis data =====")
source("scripts/R/0_make_data.R")

## ------------------ STEP 1: Table 1 -----------------------------------------
message("===== STEP 1: adoption table (Table 1) =====")
source("scripts/R/1_Adoption_Table.R")

## ------------------ STEP 2: 2x2 DID(课程核心) -----------------------------
## 讲解锚点:DID 估计量 = Treat × Post 交叉项的系数(两个虚拟变量的乘积)
message("===== STEP 2: 2x2 DiD (Tables 2-7, Figure 1) =====")
source("scripts/R/2_2x2.R")

## ------------------ STEP 3: 事件研究 ----------------------------------------
## 讲解锚点:每个点 = 处理组虚拟变量 × 年份虚拟变量 的交叉项系数;
## 处理前各期系数接近 0 ⇒ 平行趋势的可视化证据
message("===== STEP 3: event study (Figures 2-4) =====")
source("scripts/R/3_2XT.R")

cat(sprintf("\n===== DEMO RUN COMPLETE in %.1f minutes =====\n",
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))
cat("请查看 tables/ (table1–7_R.tex) 与 figures/ (figure1–4_R.pdf),\n")
cat("并与论文对应表图核对数值。\n")

################################################################################
# 课堂小抄:
# - renv::restore() 卡住 → 课前没预热;应急方案:改用 Stata 路线;
# - 找不到文件 → 确认工作目录是包根目录(getwd() 检查);
# - 只想重跑精华 → 单独 source STEP 2 与 STEP 3 两行。
################################################################################
