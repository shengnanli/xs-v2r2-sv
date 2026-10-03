MODULE = LqRawCam

# LoadQueueRAW 的两块 CAM 数据阵列（同一个参数化核的两个薄 wrapper），一个 UT 同测两对：
#   LqMaskModule    —— 32 项 × 16 位字节掩码，CAM = 掩码交叠
#   LqPAddrModule_1 —— 32 项 × 24 位部分 paddr，CAM = 同 cacheline 且（整行 或 同 16B）
#
# 子模块（每个 wrapper 72 个延迟件）：impl 侧一律用本仓**已签核的重写件**
# （docs/coverage_three_axis.tsv：DelayN_13 / DelayNWithValid_52 / _55 / _103 均 PROVEN_DIRECT），
# ref 侧用 golden 同名件，两侧都白盒 elaborate、不设黑盒。于是 FM 证明的是
# "golden 整棵子树 == 重写核 + 重写延迟件"，而不是只证 glue。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_LqRawDataCam_core.sv \
           $(RTL_DIR)/memblock/LqMaskModule.sv \
           $(RTL_DIR)/memblock/LqPAddrModule_1.sv \
           $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/xs_DelayNWithValid_core.sv \
           $(RTL_DIR)/common/DelayN_13.sv \
           $(RTL_DIR)/common/DelayNWithValid_52.sv \
           $(RTL_DIR)/common/DelayNWithValid_55.sv \
           $(RTL_DIR)/common/DelayNWithValid_103.sv
TB_SRCS  = tb.sv

LQRAWCAM_DELAYS_MASK  = DelayN_13.sv DelayNWithValid_52.sv DelayNWithValid_103.sv
LQRAWCAM_DELAYS_PADDR = DelayN_13.sv DelayNWithValid_52.sv DelayNWithValid_55.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LqMaskModule.sv \
              $(GOLDEN_RTL)/LqPAddrModule_1.sv \
              $(GOLDEN_RTL)/DelayN_13.sv \
              $(GOLDEN_RTL)/DelayNWithValid_52.sv \
              $(GOLDEN_RTL)/DelayNWithValid_55.sv \
              $(GOLDEN_RTL)/DelayNWithValid_103.sv

FM_VARIANTS = LqMaskModule LqPAddrModule_1
FM_REF_DEPS_LqMaskModule    = $(LQRAWCAM_DELAYS_MASK)
FM_REF_DEPS_LqPAddrModule_1 = $(LQRAWCAM_DELAYS_PADDR)

# 关掉 merge_duplicated_registers：同一写口的写数据在 8 个 bank 各存一份、逐位恒等，
# 合并后两侧幸存者可能不同（CONVENTIONS「看起来冗余的重复结构」方向二），
# 且只有关掉时 fm_predict 的 passing 模型才严格适用。这是加强不是放宽。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 写冲突断言调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS
# （tb 也故意制造写冲突来打 Mux1H 的"按位或"语义）。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
# ★本模块全部寄存器不复位★：+random 档两侧初值不同，tb 先暖机写满 32 项再比对。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_lqraw.py --check
