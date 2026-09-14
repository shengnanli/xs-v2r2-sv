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
