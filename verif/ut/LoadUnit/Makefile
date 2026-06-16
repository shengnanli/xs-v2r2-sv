MODULE = LoadUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 = loadunit_pkg + LoadUnit(xs_LoadUnit_core 拼接体)
RTL_SRCS = $(RTL_DIR)/memblock/loadunit_pkg.sv $(RTL_DIR)/memblock/LoadUnit.sv
# WRAPPER_SRCS 进入 FM 的 impl 侧。除包装层外带上 MemTrigger：可读核内部例化它，
# impl 侧须读入同一份 golden MemTrigger 才能 link（否则被当黑盒）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/LoadUnit_wrapper.sv $(GOLDEN_RTL)/MemTrigger.sv
# golden 顶层 LoadUnit 例化叶子子模块 MemTrigger（断点匹配），UT 两侧共用同一份
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadUnit.sv $(GOLDEN_RTL)/MemTrigger.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = LoadUnit
# golden 与可读核都例化 MemTrigger，FM 时作为两侧共享黑盒
FM_REF_DEPS_LoadUnit = MemTrigger.sv

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言，UT 随机激励下定义 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS
