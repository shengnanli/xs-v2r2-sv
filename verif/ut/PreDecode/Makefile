MODULE = PreDecode

RTL_DIR = ../../../rtl
# frontend_common_pkg.sv 里的 xs_predecode_pkg 由 PreDecode/F3Predecoder 共用（每个子系统
# 至多一个公共包文件，见 CONVENTIONS.md）。必须排在使用者之前：package 要先于引用它的模块可见。
RTL_SRCS = $(RTL_DIR)/frontend/frontend_common_pkg.sv $(RTL_DIR)/frontend/PreDecode.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PreDecode.sv
FM_VARIANTS = PreDecode

include ../../../scripts/ut_common.mk

# --- ut_overrides/PreDecode.mk (新战役目标级修正) ---
# golden PreDecode 含 xs_assert_v2 断言(sim-verilog sed 产物), 无定义体;
# 同 RASStack/TLPLIC 精确先例: 定义 SYNTHESIS 关断言+随机初值(FM 侧本就带 SYNTHESIS)。
VCS += +define+SYNTHESIS

# +vcs+initreg：编译期 +vcs+initreg+random 只是**打开机制**，取值在运行期由
# ut_common.mk 的 SIM_ARGS 选。编译期不给、只在运行期给，VCS 报 Warning-[VICIU]
# 然后当没看见，那一轮等于没测（2026-09-20 实测）。
# 运行期也必须显式钉值：编译期开了 random 而运行期不选，VCS 取 random ——
# 默认那一轮会悄悄换语义（同日在 TLBuffer_6 上实测到）。
#
# ★这里先把话说死：PreDecode 是**纯组合**件（golden 闭包寄存器位 = 0，
#   fm_predict 模型 regs 0 + outs 1645）。所以两轮 initreg 对被测件的可观测行为
#   ★按构造★不可能有任何差别，两轮都绿证明不了复位域的任何事 —— 它只排除
#   "tb 自己带的状态对上电初值敏感"这一种假绿。别把这两轮读成复位域已验。
#   实测确实两轮都绿：3 seed x (+0 / +random) 6/6，errors=0（2026-09-20）。
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
