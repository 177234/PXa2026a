# -*- coding: utf-8 -*-
"""第 3 讲概念示意图(可复现)。生成两张图入 images/ch03/：
   1) g_nested_pop_sample_data.png —— 总体 ⊃ 样本 ⊃ 数据 的嵌套集合示意；
   2) g_ci_coverage.png            —— 用有限样本推断总体：重复抽样的 95% 置信区间覆盖。
   运行：python make_ch03_figs.py
"""
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, FancyArrowPatch

# 中文字体(Windows)
plt.rcParams["font.sans-serif"] = ["Microsoft YaHei", "SimHei", "SimSun"]
plt.rcParams["axes.unicode_minus"] = False

# 相对本脚本定位 images/ch03（与运行目录无关）
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "images", "ch03")
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------------------
# 图 1：总体 ⊃ 样本 ⊃ 数据(嵌套集合)
# ---------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(7.2, 5.2))
ax.set_xlim(-6, 6); ax.set_ylim(-4.2, 4.2); ax.set_aspect("equal"); ax.axis("off")

layers = [
    dict(w=10.4, h=7.4, fc="#eaf2fb", ec="#2f6f9f", lab="研究总体\n（所有公司）",   ly=3.05),
    dict(w=6.9,  h=4.9, fc="#dff0e6", ec="#3a8a55", lab="分析样本\n（进入回归的公司）", ly=1.35),
    dict(w=3.5,  h=2.5, fc="#fdeede", ec="#c47f26", lab="数据\n（测量到的 Y、D、X）", ly=0.0),
]
for L in layers:
    ax.add_patch(Ellipse((0, 0), L["w"], L["h"], fc=L["fc"], ec=L["ec"], lw=2, zorder=1))
for L in layers:
    ax.text(0, L["ly"], L["lab"], ha="center", va="center", fontsize=12,
            color="#222", zorder=3, linespacing=1.4)

# 右侧两处传递标注
ax.annotate("抽样 / 样本选择", xy=(4.4, 1.9), xytext=(6.1, 2.8),
            fontsize=11, color="#3a8a55", ha="center",
            arrowprops=dict(arrowstyle="->", color="#3a8a55", lw=1.6))
ax.annotate("测量", xy=(1.55, 0.9), xytext=(5.7, 0.6),
            fontsize=11, color="#c47f26", ha="center",
            arrowprops=dict(arrowstyle="->", color="#c47f26", lw=1.6))
ax.text(0, -3.7, "每一层都可能悄悄偏离上一层：样本若不是随机抽取，就会系统性偏离总体。",
        ha="center", va="center", fontsize=10.5, color="#555")
fig.tight_layout()
fig.savefig(f"{OUT}/g_nested_pop_sample_data.png", dpi=150, bbox_inches="tight")
plt.close(fig)

# ---------------------------------------------------------------------------
# 图 2：置信区间覆盖 —— 用有限样本推断总体
# ---------------------------------------------------------------------------
rng = np.random.default_rng(20260718)
mu = 0.0            # 总体真值
sigma = 1.0
n = 40              # 每次抽样的样本量
K = 20              # 抽样次数
fig, ax = plt.subplots(figsize=(7.2, 5.2))
for k in range(K):
    x = rng.normal(mu, sigma, n)
    m = x.mean()
    se = x.std(ddof=1) / np.sqrt(n)
    lo, hi = m - 1.96 * se, m + 1.96 * se
    covers = lo <= mu <= hi
    col = "#2f6f9f" if covers else "#c0392b"
    y = K - k
    ax.plot([lo, hi], [y, y], color=col, lw=2, zorder=2)
    ax.plot([m], [y], "o", color=col, ms=4, zorder=3)
ax.axvline(mu, color="#444", ls="--", lw=1.5, zorder=1)
ax.text(mu, K + 0.55, "总体真值 θ", ha="center", va="bottom", fontsize=11, color="#444")
ax.set_yticks([]); ax.set_ylim(0.2, K + 1.6)
ax.set_xlabel("估计值", fontsize=11)
ax.set_title("用有限样本推断总体：20 次抽样的 95% 置信区间\n"
             "大多数区间覆盖真值，少数(红色)没盖住——这正是不确定性",
             fontsize=11.5, pad=16)
for s in ["top", "right", "left"]:
    ax.spines[s].set_visible(False)
fig.tight_layout()
fig.savefig(f"{OUT}/g_ci_coverage.png", dpi=150, bbox_inches="tight")
plt.close(fig)

print("figures written to", OUT)
