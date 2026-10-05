MODULE = PBestOffsetPrefetch

# PBestOffsetPrefetch：L2 物理地址 Best-Offset 预取器（本体只有一级预取请求寄存器）。
# child 全部 PROVEN_DIRECT，两侧白盒：ref 读 golden child，impl 读本仓重写件：
#   DelayQueue（xs_DelayQueue_core）/ OffsetScoreTable（xs_OffsetScoreTable_core）/
#   RecentRequestTable（xs_RecentRequestTable_core + SRAMTemplate_146 + xs_SRAMTemplate_core）。
# 厂商 SRAM 宏 sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt / array_13：两侧同读 golden；
# 叶子 array_13_ext 不进 FM（两侧对称黑盒，verif/allow/PBestOffsetPrefetch.json 声明 vendor_macro）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/l2/PBestOffsetPrefetch.sv \
           $(RTL_DIR)/l2/xs_DelayQueue_core.sv \
           $(RTL_DIR)/l2/DelayQueue.sv \
           $(RTL_DIR)/l2/xs_OffsetScoreTable_core.sv \
           $(RTL_DIR)/l2/OffsetScoreTable.sv \
           $(RTL_DIR)/uncore/RecentRequestTable.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_146.sv
RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
                  $(XSSV_HOME)/rtl/common/array_13.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PBestOffsetPrefetch.sv \
              $(GOLDEN_RTL)/DelayQueue.sv \
              $(GOLDEN_RTL)/OffsetScoreTable.sv \
              $(GOLDEN_RTL)/RecentRequestTable.sv \
              $(GOLDEN_RTL)/SRAMTemplate_146.sv \
              $(GOLDEN_RTL)/array_13_ext.v
FM_VARIANTS = PBestOffsetPrefetch
FM_REF_DEPS_PBestOffsetPrefetch = DelayQueue.sv OffsetScoreTable.sv RecentRequestTable.sv \
                                  SRAMTemplate_146.sv sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv array_13.sv
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
