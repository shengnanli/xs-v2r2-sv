MODULE = VecExcpDataMergeModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 (bit-exact 改名转写) + 通用延迟核 xs_delayn_core (来自 DelayN.sv)。
# 逻辑子模块 NfMappedElemIdx / GetE8OffsetInVreg 两侧 elaborate (非黑盒)。
# UT 双例化: golden (u_g) vs 可读核 _xs (u_i)。为避免 UT 编译期与 golden 同名撞名,
# golden-名可读核只进 FM impl 侧 (WRAPPER_SRCS); UT 侧用 variants_xs.sv 的 _xs 变体。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/VecExcpDataMergeModule.sv \
               $(RTL_DIR)/backend/DelayN.sv \
               $(GOLDEN_RTL)/NfMappedElemIdx.sv \
               $(GOLDEN_RTL)/GetE8OffsetInVreg.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/VecExcpDataMergeModule.sv \
               $(GOLDEN_RTL)/NfMappedElemIdx.sv \
               $(GOLDEN_RTL)/GetE8OffsetInVreg.sv \
               $(GOLDEN_RTL)/DelayN_13.sv
# variants_xs 的 _xs 核用 xs_delayn_core (来自 DelayN.sv), UT 侧须编译进来。
TB_SRCS      = $(RTL_DIR)/backend/DelayN.sv variants_xs.sv tb.sv

# 逻辑子模块两侧 elaborate; DelayN_13(golden 1 级 1-bit 延迟)也须给 FM ref 侧
# elaborate, 否则 ref 侧 DelayN_13 成黑盒而 impl 侧 xs_delayn_core 已展开 => 失配。
FM_REF_DEPS_VecExcpDataMergeModule = NfMappedElemIdx.sv GetE8OffsetInVreg.sv DelayN_13.sv
FM_VARIANTS = VecExcpDataMergeModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
