MODULE = HPerfMonitor_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# HPerfMonitor_1(HPM 事件路由 + 例化 5×HPerfCounter_8)。子模块 HPerfCounter_8
# 两侧白盒 elaborate(非黑盒)。可读转写 + eventSelTable 改名。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_hperfmon.sv
WRAPPER_SRCS =
GOLDEN_SRCS  = $(GOLDEN_RTL)/HPerfMonitor_1.sv
TB_SRCS      = variants_xs.sv tb.sv

# HPerfCounter_8 是 golden 侧的依赖(ref)+ 已在 RTL_SRCS 含 impl 侧同名转写。
FM_REF_DEPS_HPerfMonitor_1 = HPerfCounter_8.sv

FM_VARIANTS = HPerfMonitor_1

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
