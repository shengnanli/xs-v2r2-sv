MODULE = PrefetchFilter

# PrefetchFilter（SMS 预取请求过滤表）。golden 直接 child 2 个：RRArbiterInit_5（TLB 仲裁）/
# RRArbiterInit_6（L2 预取仲裁），docs/coverage_three_axis.tsv 里都是 PROVEN_DIRECT。处置 = 两侧白盒：
# ref 读 golden 同名件，impl 读本仓重写件（家族核 RRArbiterInit.sv + 薄 wrapper）。无黑盒。
# 重写核另用共享辅助件 rtl/common/xs_PlruReplacer.sv（golden 内联为 state_reg）。
# FM「匹配前」钉点 fm_pins_pre.tcl、核里两个仲裁器的例化连线都由 scripts/gen_mmuleaf.py 生成。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_PlruReplacer.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/common/RRArbiterInit_5.sv \
           $(RTL_DIR)/common/RRArbiterInit_6.sv \
           $(RTL_DIR)/memblock/PrefetchFilter.sv
TB_SRCS  = tb.sv

PFF_CHILDREN = RRArbiterInit_5.sv RRArbiterInit_6.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/PrefetchFilter.sv $(addprefix $(GOLDEN_RTL)/,$(PFF_CHILDREN))

FM_VARIANTS = PrefetchFilter
FM_REF_DEPS_PrefetchFilter = $(PFF_CHILDREN)

# 关掉 merge_duplicated_registers：让 FM 逐个比，fm_predict 的 passing 模型也只在关掉时严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/PrefetchFilter.tcl★ —— 10 位两侧对称死位
# （TLB 回应物理地址的区域内偏移 s3_tlb_resp_paddr_0[9:0]），由 fm_pins_pre.tcl 一一钉配。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块两侧统一关掉（与 FM 口径一致）。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
#   INITREG=0 / random / <seed>017（第三个真随机档）
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_mmuleaf.py --check
