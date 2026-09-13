# InstrUncache / InstrMMIOEntry / Arbiter1_InsUncacheResp —— MMIO 取指通路三件套
# tb 里两对双例化：entry 级（状态机）+ 顶层级（含 D 通道 source 分发）。
MODULE = InstrUncache

RTL_DIR = ../../../rtl
# InstrMMIOEntry.sv 必须排在最前：里面的 instr_mmio_entry_pkg 要先编译。
RTL_SRCS = $(RTL_DIR)/frontend/InstrMMIOEntry.sv \
           $(RTL_DIR)/frontend/Arbiter1_InsUncacheResp.sv \
           $(RTL_DIR)/frontend/InstrUncache.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/InstrMMIOEntry.sv \
              $(GOLDEN_RTL)/Arbiter1_InsUncacheResp.sv \
              $(GOLDEN_RTL)/InstrUncache.sv

FM_REF_DEPS_InstrUncache = InstrMMIOEntry.sv Arbiter1_InsUncacheResp.sv
FM_VARIANTS = InstrMMIOEntry Arbiter1_InsUncacheResp InstrUncache

include ../../../scripts/ut_common.mk
