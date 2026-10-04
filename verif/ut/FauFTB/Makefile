MODULE = FauFTB

# uFTB：32 路全相联微 FTB（BPU 链头，S1 零气泡预测）。
# 子模块 FauFTBWay ×32：docs/coverage_three_axis.tsv 为 PROVEN_DIRECT ⇒ 两侧白盒（ref = golden FauFTBWay，
# impl = 本仓重写件 rtl/frontend/FauFTBWay.sv）。无黑盒、无厂商宏。
# 重写核还例化共享辅助件 rtl/common/xs_BpuStagePc.sv（BPU 公共外壳的各级 PC），并用 frontend_common_pkg.sv
# 里的 xs_ftb_pkg（FTB 条目类型与目标重建函数）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/frontend_common_pkg.sv \
           $(RTL_DIR)/common/xs_BpuStagePc.sv \
           $(RTL_DIR)/frontend/FauFTBWay.sv \
           $(RTL_DIR)/frontend/FauFTB.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/FauFTB.sv $(GOLDEN_RTL)/FauFTBWay.sv

FM_VARIANTS = FauFTB
FM_REF_DEPS_FauFTB = FauFTBWay.sv
FM_MERGE_DUP = false

# ★匹配前钉点 fm_pins_pre.tcl（scripts/gen_bpu_stagepc_pins.py 生成）★：BPU 公共外壳 s2/s3 段 PC 400 位，
# 两侧名字不同且 cone-dead（无签名可配），不钉时诊断跑实测 400(400) unmatched unread。只消名差。
# ★vmucp：依据见 verif/fm_target_config/FauFTB.tcl★ —— 566 位 matched_nc + 上述 400 位钉上后的对称死位。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_bpu_stagepc_pins.py --check
	python3 gen.py --check
