MODULE = GrantBuffer

# GrantBuffer（L2 slice 的 TileLink D 通道出口）与其 child 队列。
#   GrantBuffer               可读核 xs_GrantBuffer_core 手写；类型 / wrapper / fm_pins_pre.tcl 由 scripts/gen_l2_grantbuf.py 生成
#   Queue10_GrantBuffer_Anon  共享核 xs_ChiselQueue_core + gen_l2_queues.py 薄文件（本 lane 新增）
#   Queue16_GrantQueueTask / Queue16_GrantQueueData 已在 verif/ut/L2Queues 签核，这里两侧白盒同进
# 存储是 golden 的 ram_<D>x<W> 行为级叶子，按 codex 0151 D60 两侧同源 inline elaborate（RTL_GOLDEN_DEPS + FM_REF_DEPS）。
# ★ram_10x89 深度 10 非 2 的幂（4 位地址，越界 10..15），不在 verif/vendor_boundary.tsv 审定表内：
#   inline 会触发 FMR_ELAB-147，本 lane 无权自行登记 —— 两个 FM 目标都挂在这条审定上（见 docs/lanes/l2slice_prereg.md）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/GrantBuffer.sv \
           $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/Queue16_GrantQueueTask.sv $(RTL_DIR)/uncore/Queue16_GrantQueueData.sv \
           $(RTL_DIR)/uncore/Queue10_GrantBuffer_Anon.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_16x25.sv $(GOLDEN_RTL)/ram_data_16x256.sv $(GOLDEN_RTL)/ram_10x89.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/GrantBuffer.sv $(GOLDEN_RTL)/Queue16_GrantQueueTask.sv \
              $(GOLDEN_RTL)/Queue16_GrantQueueData.sv $(GOLDEN_RTL)/Queue10_GrantBuffer_Anon.sv
FM_VARIANTS = Queue10_GrantBuffer_Anon GrantBuffer
FM_REF_DEPS_Queue10_GrantBuffer_Anon = ram_10x89.sv
FM_REF_DEPS_GrantBuffer = Queue16_GrantQueueTask.sv Queue16_GrantQueueData.sv Queue10_GrantBuffer_Anon.sv \
                          ram_16x25.sv ram_data_16x256.sv ram_10x89.sv
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
