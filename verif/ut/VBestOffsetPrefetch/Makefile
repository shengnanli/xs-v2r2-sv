MODULE = VBestOffsetPrefetch

# VBestOffsetPrefetch：L2 虚地址 Best-Offset 预取器（本体只有 s1 一项寄存器 + 出口门控）。
# child 全部 PROVEN_DIRECT，两侧白盒：ref 读 golden child，impl 读本仓重写件：
#   DelayQueue_1（xs_DelayQueue_core）/ OffsetScoreTable_1（xs_OffsetScoreTable_core）/
#   RecentRequestTable_1（xs_RecentRequestTable_core 在 RecentRequestTable.sv 里 + SRAMTemplate_146 + xs_SRAMTemplate_core）/
#   PrefetchReqBuffer（核同文件 + RRArbiterInit_14/_15，家族核在 RRArbiterInit.sv）。
# 厂商 SRAM 宏 sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt / array_13：两侧同读 golden；
# 叶子 array_13_ext 不进 FM（两侧对称黑盒，verif/allow/VBestOffsetPrefetch.json 声明 vendor_macro）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/l2/VBestOffsetPrefetch.sv \
           $(RTL_DIR)/l2/xs_DelayQueue_core.sv \
           $(RTL_DIR)/l2/DelayQueue_1.sv \
           $(RTL_DIR)/l2/xs_OffsetScoreTable_core.sv \
           $(RTL_DIR)/l2/OffsetScoreTable_1.sv \
           $(RTL_DIR)/uncore/RecentRequestTable.sv \
           $(RTL_DIR)/uncore/RecentRequestTable_1.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_146.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/common/RRArbiterInit_14.sv \
           $(RTL_DIR)/common/RRArbiterInit_15.sv \
           $(RTL_DIR)/l2/PrefetchReqBuffer.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
                  $(GOLDEN_RTL)/array_13.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/VBestOffsetPrefetch.sv \
              $(GOLDEN_RTL)/DelayQueue_1.sv \
              $(GOLDEN_RTL)/OffsetScoreTable_1.sv \
              $(GOLDEN_RTL)/RecentRequestTable_1.sv \
              $(GOLDEN_RTL)/SRAMTemplate_146.sv \
              $(GOLDEN_RTL)/PrefetchReqBuffer.sv \
              $(GOLDEN_RTL)/RRArbiterInit_14.sv \
              $(GOLDEN_RTL)/RRArbiterInit_15.sv \
              $(GOLDEN_RTL)/sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
              $(GOLDEN_RTL)/array_13.sv \
              $(GOLDEN_RTL)/array_13_ext.v
FM_VARIANTS = VBestOffsetPrefetch
FM_REF_DEPS_VBestOffsetPrefetch = DelayQueue_1.sv OffsetScoreTable_1.sv RecentRequestTable_1.sv SRAMTemplate_146.sv \
                                  PrefetchReqBuffer.sv RRArbiterInit_14.sv RRArbiterInit_15.sv \
                                  sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv array_13.sv
FM_MODE = assembly
FM_ALLOWLIST ?= 0
FM_MERGE_DUP = false
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
