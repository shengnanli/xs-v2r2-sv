MODULE = PMP

# PMP（L2TLB.pmp：分布式 PMP/PMA 表副本）。golden 0 child。无黑盒。
# wrapper 的端口表与输出展平、FM「匹配前」钉点 fm_pins_pre.tcl 由 scripts/gen_mmuleaf.py 生成
# （72 个 wen 寄存器按 golden 赋值语句里的 CSR 地址逐个对应到 cfg_wen / addr_wen）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/PMP.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PMP.sv

FM_VARIANTS = PMP
FM_REF_DEPS_PMP =

# 关掉 merge_duplicated_registers：让 FM 逐个比，fm_predict 的 passing 模型也只在关掉时严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/PMP.tcl★ —— 64 位两侧对称死位
# （PMP 表 cfg 字节里的保留位 c / atomic），由 fm_pins_pre.tcl 一一钉配。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段两侧统一关掉（与 FM 口径一致）。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
#   INITREG=0 / random / <seed>017（第三个真随机档）
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_mmuleaf.py --check
