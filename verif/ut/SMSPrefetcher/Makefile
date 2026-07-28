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

# ★消黑盒不对称: verification_merge_duplicated_registers=true(fm_eq.tcl 默认)会令 golden
#   侧的 pht 实例被复制成 PatternHistoryTable_2, 从而把独立读入的 standalone
#   PatternHistoryTable 设计遗留为 orphan(其内 pht_ram/array 黑盒被 report_black_boxes
#   额外报告一份)→ ref 侧 2 个 unresolved SRAM 黑盒 vs impl 侧 1 个 = 不对称 → PARTIAL。
#   merge=false 关闭该寄存器合并后, golden pht 直接绑定 standalone PatternHistoryTable(不产
#   _2 副本, 无 orphan)→ 两侧各 1 个对称 SRAM 黑盒。SMSPrefetcher 无 bank 扇出复制寄存器,
#   关合并不引入任何 unmatched(反使 passing 8514→8719, 更多点被真实比对), 是逐位真等价证明。
#   同 AtomicsUnit(同为 memblock AUX, 亦 merge=false + assembly + allow 4 键)。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# 唯一黑盒 = 厂商 SRAM 宏 sram_array_1p32x148m74s1h0l1b_pftch_pht(PatternHistoryTable
# 内 SRAMTemplate_134 的 pht_ram)。厂商宏无源码 → 两侧 unresolved 对称黑盒, 走
# assembly + allow 声明(恰好 4 键, vendor SRAM 入 unresolved_blackbox 对称 pair)。
FM_ALLOWLIST = ../../signoff/allow/SMSPrefetcher.json
FM_MODE = assembly

# UT 编译: 核 + _xs(variants) + 子模块 + SRAM 行为模型 + golden 顶 + tb(不编 golden 同名 wrapper)。
simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) $(RTL_DIR)/memblock/SMSPrefetcher.sv $(DEPS_ABS) $(SRAM_MODEL) $(GOLDEN_RTL)/SMSPrefetcher.sv $(TB_SRCS) -top tb -o simv
