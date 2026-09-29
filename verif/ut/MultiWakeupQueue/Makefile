MODULE = MultiWakeupQueue

# MultiWakeupQueue 家族（4 个变体）。golden 直接 child = PipeWithFlush / _1 / _6 / _7 / _8 / _9 /
# _10 / _11，docs/coverage_three_axis.tsv 里全部 PROVEN_DIRECT（rtl/common/PipeWithFlush*.sv，
# 家族核 xs_PipeWithFlush_core）。处置 = **两侧白盒**：ref 读 golden 同名件，impl 读本仓重写件，
# 无黑盒。证明的是"golden 整棵子树 == 重写整棵子树"。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_MultiWakeupQueue_core.sv \
           $(RTL_DIR)/backend/MultiWakeupQueue.sv \
           $(RTL_DIR)/backend/MultiWakeupQueue_2.sv \
           $(RTL_DIR)/backend/MultiWakeupQueue_4.sv \
           $(RTL_DIR)/backend/MultiWakeupQueue_5.sv \
           $(RTL_DIR)/common/xs_PipeWithFlush_core.sv \
           $(RTL_DIR)/common/PipeWithFlush.sv \
           $(RTL_DIR)/common/PipeWithFlush_1.sv \
           $(RTL_DIR)/common/PipeWithFlush_6.sv \
           $(RTL_DIR)/common/PipeWithFlush_7.sv \
           $(RTL_DIR)/common/PipeWithFlush_8.sv \
           $(RTL_DIR)/common/PipeWithFlush_9.sv \
           $(RTL_DIR)/common/PipeWithFlush_10.sv \
           $(RTL_DIR)/common/PipeWithFlush_11.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,MultiWakeupQueue.sv MultiWakeupQueue_2.sv \
               MultiWakeupQueue_4.sv MultiWakeupQueue_5.sv \
               PipeWithFlush.sv PipeWithFlush_1.sv PipeWithFlush_6.sv PipeWithFlush_7.sv \
               PipeWithFlush_8.sv PipeWithFlush_9.sv PipeWithFlush_10.sv PipeWithFlush_11.sv)

FM_VARIANTS = MultiWakeupQueue MultiWakeupQueue_2 MultiWakeupQueue_4 MultiWakeupQueue_5
FM_REF_DEPS_MultiWakeupQueue   = PipeWithFlush.sv PipeWithFlush_1.sv
FM_REF_DEPS_MultiWakeupQueue_2 = PipeWithFlush.sv
FM_REF_DEPS_MultiWakeupQueue_4 = PipeWithFlush_6.sv PipeWithFlush_7.sv PipeWithFlush_8.sv PipeWithFlush_9.sv
FM_REF_DEPS_MultiWakeupQueue_5 = PipeWithFlush_10.sv PipeWithFlush_11.sv

# 复制件（pdestCopy×6 等）与原件逐位同源，关掉 merge_dup 让每份各成比较点（加强不是放宽；
# fm_predict 的 passing 模型也只在 false 时严格适用）。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块（PopCount 断言调未定义的 xs_assert_v2 + 随机初值）；两侧同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值（INITREG=0 / random / <数值种子>）。
# lastConnect_* 全不复位、流水载荷不复位：tb 在复位释放后第 2 拍才开始比（lastConnect 每拍无条件写）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
