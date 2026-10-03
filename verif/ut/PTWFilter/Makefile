MODULE = PTWFilter

# PTWFilter（ITLB → L2TLB 的 miss 请求去重队列，Width=3 / Size=8）。golden 直接 child 1 个：
#   DelayN_1（flush 延迟 2 拍；main 上 PROVEN_DIRECT，rtl/common/DelayN_1.sv + xs_DelayN_core）
# 处置 = 两侧白盒：ref 读 golden DelayN_1.sv，impl 读本仓重写件。无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/mmu/PTWFilter.sv \
           $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/DelayN_1.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PTWFilter.sv $(GOLDEN_RTL)/DelayN_1.sv

FM_VARIANTS = PTWFilter
FM_REF_DEPS_PTWFilter = DelayN_1.sv
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_newifu_lane.py --check
