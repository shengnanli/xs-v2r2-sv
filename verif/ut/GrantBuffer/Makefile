MODULE = GrantBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/l2_task_pkg.sv $(RTL_DIR)/uncore/GrantBuffer.sv
# FIFO 叶: UT 用真叶(含行为 ram); FM 用真 Queue 但 ram_* 行为模型不进 FM(其越界
# 索引告警会被 Formality 升级为链接错误), ram 在两侧自动当黑盒。Queue 用真叶可消除
# unread 黑盒输出引脚(io_enq_ready 仅喂被裁剪的 assert)导致的 FM 比对点失配。
QUEUES = $(GOLDEN_RTL)/Queue16_GrantQueueTask.sv \
         $(GOLDEN_RTL)/Queue16_GrantQueueData.sv \
         $(GOLDEN_RTL)/Queue10_GrantBuffer_Anon.sv
RAMS   = $(GOLDEN_RTL)/ram_16x25.sv \
         $(GOLDEN_RTL)/ram_data_16x256.sv \
         $(GOLDEN_RTL)/ram_10x89.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/GrantBuffer_wrapper.sv $(QUEUES)

GOLDEN_SRCS = $(GOLDEN_RTL)/GrantBuffer.sv $(QUEUES) $(RAMS)
TB_SRCS = variants_xs.sv tb.sv

# FM: ref = golden GrantBuffer + 真 Queue 叶; ram_* 厂商宏两侧自动黑盒(不显式加载)
FM_VARIANTS = GrantBuffer
FM_REF_DEPS_GrantBuffer = Queue16_GrantQueueTask.sv Queue16_GrantQueueData.sv \
    Queue10_GrantBuffer_Anon.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
