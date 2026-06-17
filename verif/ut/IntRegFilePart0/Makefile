MODULE = IntRegFilePart0

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包。UT 不编 IntRegFilePart0_wrapper.sv(模块名与 golden 顶层冲突),
# 改用 variants_xs.sv 里的 IntRegFilePart0_xs(同 wrapper 逻辑改名)。
RTL_SRCS = $(RTL_DIR)/backend/regfile_pkg.sv \
           $(RTL_DIR)/backend/RegFilePart.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/IntRegFilePart0.sv

# FM：golden IntRegFilePart0 vs 手写同名 wrapper(→核)。纯寄存器堆叶子,无子模块。
WRAPPER_SRCS = $(RTL_DIR)/backend/regfile_pkg.sv \
               $(RTL_DIR)/backend/RegFilePart.sv \
               $(RTL_DIR)/backend/IntRegFilePart0_wrapper.sv
FM_VARIANTS = IntRegFilePart0

include ../../../scripts/ut_common.mk

# golden 含 $fatal 断言;UT 关掉以免随机激励触发
VCS += +define+SYNTHESIS
