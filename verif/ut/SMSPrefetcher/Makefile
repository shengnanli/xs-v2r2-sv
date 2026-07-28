MODULE = SMSPrefetcher
RTL_DIR = ../../../rtl
GOLDEN_RTL = /home/eda/xs-env/G0-canonical/golden-rtl

# 可读核 xs_SMSPrefetcher_core = 顶层 glue(s0 特征寄存 bank + 门控 + 输出)。
# 5 子模块 + PatternHistoryTable 内嵌(Arbiter3_PfGenReq/OverrideableQueue×2/SRAMTemplate_134)
# + PrefetchFilter 内嵌(RRArbiterInit_3/_4) 两侧同源 elaborate(纯逻辑非黑盒)。
# SRAMTemplate_134 → 厂商 SRAM 宏 sram_array_1p32x148m74s1h0l1b_pftch_pht = 唯一黑盒
# (FM 不给该宏源码 → 两侧 unresolved 对称黑盒; UT 用行为模型 array_12/array_12_ext)。

# FM 侧 deps(逻辑, 不含厂商 SRAM 宏)
FM_DEPS = SMSTrainFilter.sv ActiveGenerationTable.sv StridePF.sv PatternHistoryTable.sv \
          PrefetchFilter.sv Arbiter3_PfGenReq.sv OverrideableQueue.sv OverrideableQueue_1.sv \
          SRAMTemplate_134.sv MbistClockGateCell.sv ClockGate.sv \
          RRArbiterInit_3.sv RRArbiterInit_4.sv
# UT 侧还需厂商 SRAM 宏行为模型(两侧共用)
SRAM_MODEL = $(GOLDEN_RTL)/sram_array_1p32x148m74s1h0l1b_pftch_pht.sv \
             $(GOLDEN_RTL)/array_12.sv $(GOLDEN_RTL)/array_12_ext.v

DEPS_ABS = $(addprefix $(GOLDEN_RTL)/,$(FM_DEPS))
RTL_SRCS = $(RTL_DIR)/memblock/SMSPrefetcher.sv $(DEPS_ABS)
WRAPPER_SRCS = $(RTL_DIR)/memblock/SMSPrefetcher_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SMSPrefetcher.sv $(DEPS_ABS) $(SRAM_MODEL)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = SMSPrefetcher
FM_REF_DEPS_SMSPrefetcher = $(FM_DEPS)

# 子模块内 cone-dead perf/probe 寄存器(两侧 byte-identical golden 对称双射)预计需 vmucp。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS ?= true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# UT 编译: 核 + _xs(variants) + 子模块 + SRAM 行为模型 + golden 顶 + tb(不编 golden 同名 wrapper)。
simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) $(RTL_DIR)/memblock/SMSPrefetcher.sv $(DEPS_ABS) $(SRAM_MODEL) $(GOLDEN_RTL)/SMSPrefetcher.sv $(TB_SRCS) -top tb -o simv
