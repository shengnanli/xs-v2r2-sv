MODULE = Pipeline_3

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

# 手写可读核 xs_Pipeline_3_core + 深度1队列核 xs_Queue1_PrefetchResp_core(同文件)。
RTL_SRCS = $(RTL_DIR)/l2/Pipeline_3.sv
WRAPPER_SRCS = $(RTL_DIR)/l2/Pipeline_3_wrapper.sv
# golden 顶层 + 其唯一子模块 Queue1_PrefetchResp(ref 侧例化)。
GOLDEN_SRCS = $(GOLDEN_RTL)/Pipeline_3.sv $(GOLDEN_RTL)/Queue1_PrefetchResp.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 strict; golden 侧依赖 Queue1_PrefetchResp(ref 侧 elaborate)。
# Queue1_PrefetchResp 的 ram 存 tag/set/vaddr 但 deq 只读 pfSource = golden-side
# cone-dead; impl 逐位复刻 ram => 两侧对称 matched-unread(不作为比对点)。
FM_VARIANTS = Pipeline_3
FM_REF_DEPS_Pipeline_3 = Queue1_PrefetchResp.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
