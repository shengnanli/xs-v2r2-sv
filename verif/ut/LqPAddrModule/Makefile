MODULE = LqPAddrModule

# LoadQueueRAR 的 72 项折叠 paddr CAM 阵列（16 位 × 72，3 写口 0 级延迟 + release CAM ×1
# + releaseViolation CAM ×3）。
#
# 子模块（72 个 0 级延迟件 = 直连线）：impl 侧用本仓**已签核的重写件**
# （docs/coverage_three_axis.tsv：DelayN_225 / DelayNWithValid_4 / DelayNWithValid_7 均 PROVEN_DIRECT），
# ref 侧用 golden 同名件，两侧都白盒 elaborate、不设黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/LqPAddrModule.sv \
           $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/xs_DelayNWithValid_core.sv \
           $(RTL_DIR)/common/DelayN_225.sv \
           $(RTL_DIR)/common/DelayNWithValid_4.sv \
           $(RTL_DIR)/common/DelayNWithValid_7.sv
TB_SRCS  = tb.sv

LQPADDR_DELAYS = DelayN_225.sv DelayNWithValid_4.sv DelayNWithValid_7.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LqPAddrModule.sv $(addprefix $(GOLDEN_RTL)/,$(LQPADDR_DELAYS))

FM_VARIANTS = LqPAddrModule
FM_REF_DEPS_LqPAddrModule = $(LQPADDR_DELAYS)

# 关掉 merge_duplicated_registers：与 LqRawCam / LoadQueueRAW 同口径（只有关掉时
# fm_predict 的 passing 模型才严格适用）。这是加强不是放宽。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 写冲突断言调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS
# （tb 也故意制造写冲突来打 Mux1H 的"按位或"语义）。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
# ★本模块全部寄存器不复位★：+random 档两侧初值不同，tb 先暖机写满 72 项再比对。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_lqrar.py --check
