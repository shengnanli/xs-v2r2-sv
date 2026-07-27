MODULE = Pipeline_2

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

# 手写可读核 xs_Pipeline_2_core + 深度1队列核 xs_Queue1_PrefetchTrain_core(复用 uncore)。
RTL_SRCS = $(RTL_DIR)/l2/Pipeline_2.sv $(RTL_DIR)/uncore/Queue1_PrefetchTrain.sv
# FM impl 侧: golden 同名扁平端口包装(不进 UT 编译)。
WRAPPER_SRCS = $(RTL_DIR)/l2/Pipeline_2_wrapper.sv
# golden 顶层 + 其唯一子模块 Queue1_PrefetchTrain(ref 侧例化)。
GOLDEN_SRCS = $(GOLDEN_RTL)/Pipeline_2.sv $(GOLDEN_RTL)/Queue1_PrefetchTrain.sv
# UT 变体: impl 顶层改名 Pipeline_2_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 strict; golden 侧依赖 Queue1_PrefetchTrain(ref 侧 elaborate),
# impl 侧例化可读 xs_Queue1_PrefetchTrain_core, FM 逐位证明整体等价。
# Queue1_PrefetchTrain 的 ram 存 hit/prefetched/pfsource 但 deq 不读 = golden-side
# cone-dead; impl 逐位复刻 ram => 两侧对称 matched-unread(不作为比对点)。
FM_VARIANTS = Pipeline_2
FM_REF_DEPS_Pipeline_2 = Queue1_PrefetchTrain.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
