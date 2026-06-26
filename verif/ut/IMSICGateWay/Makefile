MODULE = IMSICGateWay

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 (进 FM impl 侧)。3 级异步复位同步链不放这里：FM 时 golden 侧把它当黑盒，
# impl 侧也须当黑盒 (二者同名同端口) 才能对齐；故同步链只在 UT 编译里随 GOLDEN_SRCS
# 编入两侧 (行为一致逐拍可比)，FM 不引用 ⇒ 自动黑盒化。
RTL_SRCS = $(RTL_DIR)/uncore/imsic_pkg.sv \
           $(RTL_DIR)/uncore/IMSICGateWay.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化所需 golden RTL：golden GateWay + 真实 3 级同步链 (仅 UT，不进 FM)
GOLDEN_SRCS = $(GOLDEN_RTL)/IMSICGateWay.sv \
              $(GOLDEN_RTL)/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
              $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/IMSICGateWay_wrapper.sv
FM_VARIANTS = IMSICGateWay

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
