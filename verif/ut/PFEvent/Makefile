MODULE = PFEvent

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# PFEvent (性能事件选择 CSR 装配: 24×perfEventsModule)。子模块 perfEventsModule
# 两侧白盒 elaborate(非黑盒, 逻辑子)。可读转写去随机初值。
#
# UT 双例化: golden PFEvent/perfEventsModule (GOLDEN_SRCS) vs 可读核 _xs 变体
# (variants_xs.sv 自包含 PFEvent_xs + perfEventsModule_xs)。为避免 UT 编译期与 golden
# 同名撞名, golden-名可读核 pfevent.sv 只进 FM impl 侧(WRAPPER_SRCS), 不进 UT 编译。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/pfevent.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/PFEvent.sv $(GOLDEN_RTL)/perfEventsModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# perfEventsModule 是 golden 侧依赖(ref)+ WRAPPER_SRCS 的 pfevent.sv 含 impl 侧同名转写。
FM_REF_DEPS_PFEvent = perfEventsModule.sv

FM_VARIANTS = PFEvent

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
