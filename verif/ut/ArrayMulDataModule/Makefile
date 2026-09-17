MODULE = ArrayMulDataModule

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/C22.sv \
           $(RTL_DIR)/backend/CSA3_2.sv \
           $(RTL_DIR)/backend/C32.sv \
           $(RTL_DIR)/backend/C53.sv \
           $(RTL_DIR)/backend/ArrayMulDataModule.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/C22.sv $(GOLDEN_RTL)/CSA3_2.sv $(GOLDEN_RTL)/C32.sv \
              $(GOLDEN_RTL)/C53.sv $(GOLDEN_RTL)/ArrayMulDataModule.sv

# 五个 golden 顶层都在本 UT 里对位（乘法阵列 + 它的三个压缩器 + C53 的子实例 CSA3_2）
FM_VARIANTS = ArrayMulDataModule C22 C32 C53 CSA3_2
FM_REF_DEPS_ArrayMulDataModule = C22.sv C32.sv C53.sv CSA3_2.sv
FM_REF_DEPS_C53                = CSA3_2.sv

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期只负责"打开 initreg 机制"，取值在运行期由 +vcs+initreg+$(INITREG) 选。
# 两处都要给：只给编译期的 +0 会拒编，只给运行期会被静默忽略（Warning-[VICIU]）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
