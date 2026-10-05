MODULE = Prefetcher

# Prefetcher：L2 预取总控（coupledL2 prefetch/Prefetcher.scala）。
# impl = rtl/l2/Prefetcher.sv（手写胶合核 xs_Prefetcher_core + golden 同名顶层，7 个 child 实例名同 golden）。
# child 全部 PROVEN_DIRECT，两侧白盒（ref 读 golden，impl 读本仓重写件）：
#   PBestOffsetPrefetch / VBestOffsetPrefetch（及其 DelayQueue*/OffsetScoreTable*/RecentRequestTable*/
#   SRAMTemplate_146/PrefetchReqBuffer/RRArbiterInit_14/_15）、PrefetchReceiver、MbistPipeL2Prefetcher、
#   PrefetchQueue、Pipeline_1（含 Queue1_PrefetchReq）、Arbiter4_PrefetchReq。
# SRAM 行为模型 sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt / array_13 两侧读同一份 golden；
# 厂商叶子 array_13_ext 两侧都不给 = 对称黑盒（verif/vendor_boundary.tsv 已审定）→ assembly + allow。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/l2/Prefetcher.sv \
           $(RTL_DIR)/l2/PBestOffsetPrefetch.sv \
           $(RTL_DIR)/l2/VBestOffsetPrefetch.sv \
           $(RTL_DIR)/l2/xs_DelayQueue_core.sv \
           $(RTL_DIR)/l2/DelayQueue.sv \
           $(RTL_DIR)/l2/DelayQueue_1.sv \
           $(RTL_DIR)/l2/xs_OffsetScoreTable_core.sv \
           $(RTL_DIR)/l2/OffsetScoreTable.sv \
           $(RTL_DIR)/l2/OffsetScoreTable_1.sv \
           $(RTL_DIR)/uncore/RecentRequestTable.sv \
           $(RTL_DIR)/uncore/RecentRequestTable_1.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_146.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/common/RRArbiterInit_14.sv \
           $(RTL_DIR)/common/RRArbiterInit_15.sv \
           $(RTL_DIR)/l2/PrefetchReqBuffer.sv \
           $(RTL_DIR)/l2/PrefetchReceiver.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/dft/MbistPipeL2Prefetcher.sv \
           $(RTL_DIR)/l2/PrefetchQueue.sv \
           $(RTL_DIR)/common/xs_ChiselQueue1_core.sv \
           $(RTL_DIR)/frontend/Queue1_PrefetchReq.sv \
           $(RTL_DIR)/uncore/Pipeline_1.sv \
           $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/frontend/Arbiter4_PrefetchReq.sv
RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
                  $(XSSV_HOME)/rtl/common/array_13.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Prefetcher.sv \
              $(GOLDEN_RTL)/PBestOffsetPrefetch.sv \
              $(GOLDEN_RTL)/VBestOffsetPrefetch.sv \
              $(GOLDEN_RTL)/DelayQueue.sv \
              $(GOLDEN_RTL)/DelayQueue_1.sv \
              $(GOLDEN_RTL)/OffsetScoreTable.sv \
              $(GOLDEN_RTL)/OffsetScoreTable_1.sv \
              $(GOLDEN_RTL)/RecentRequestTable.sv \
              $(GOLDEN_RTL)/RecentRequestTable_1.sv \
              $(GOLDEN_RTL)/SRAMTemplate_146.sv \
              $(GOLDEN_RTL)/PrefetchReqBuffer.sv \
              $(GOLDEN_RTL)/RRArbiterInit_14.sv \
              $(GOLDEN_RTL)/RRArbiterInit_15.sv \
              $(GOLDEN_RTL)/PrefetchReceiver.sv \
              $(GOLDEN_RTL)/MbistPipeL2Prefetcher.sv \
              $(GOLDEN_RTL)/PrefetchQueue.sv \
              $(GOLDEN_RTL)/Pipeline_1.sv \
              $(GOLDEN_RTL)/Queue1_PrefetchReq.sv \
              $(GOLDEN_RTL)/Arbiter4_PrefetchReq.sv \
              $(GOLDEN_RTL)/array_13_ext.v
FM_VARIANTS = Prefetcher
FM_REF_DEPS_Prefetcher = PBestOffsetPrefetch.sv VBestOffsetPrefetch.sv DelayQueue.sv DelayQueue_1.sv \
                         OffsetScoreTable.sv OffsetScoreTable_1.sv RecentRequestTable.sv RecentRequestTable_1.sv \
                         SRAMTemplate_146.sv PrefetchReqBuffer.sv RRArbiterInit_14.sv RRArbiterInit_15.sv \
                         PrefetchReceiver.sv MbistPipeL2Prefetcher.sv PrefetchQueue.sv Pipeline_1.sv \
                         Queue1_PrefetchReq.sv Arbiter4_PrefetchReq.sv \
                         sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv array_13.sv
FM_MODE = assembly
FM_ALLOWLIST ?= 0
# 不合并重复寄存器：比较点 = 寄存器位 + 输出位，fm_predict 模型精确适用。
FM_MERGE_DUP = false
# vmucp（加强不是放宽）：pbop / vbop / pftQueue / mbistPl / 本层 recv_addr 的无读者位两侧对称，
# 钉点 fm_pins_pre.tcl（scripts/gen_prefetcher_pins.py，960 位），依据与六条证据见 verif/fm_target_config/Prefetcher.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
# 三档：INITREG=0（全 0）/ random（seed 1 退化为全 1）/ <seed>017（与 ntb 种子无关的真随机）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_prefetcher_pins.py --check
