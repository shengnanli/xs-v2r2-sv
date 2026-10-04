MODULE = ProbeQueue

RTL_DIR = ../../../rtl
# 子模块 ProbeEntry ×8 / Arbiter8_MainPipeReq 已独立签核（agent/fe-mem-misc），两侧白盒：
# ref 读 golden，impl 读重写件（不再两侧同读 golden）。
RTL_SRCS = $(RTL_DIR)/memblock/ProbeEntry.sv \
           $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/memblock/Arbiter8_MainPipeReq.sv \
           $(RTL_DIR)/memblock/ProbeQueue.sv
TB_SRCS = tb.sv


FM_REF_DEPS_ProbeQueue = ProbeEntry.sv Arbiter8_MainPipeReq.sv
FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/ProbeQueue.sv $(GOLDEN_RTL)/ProbeEntry.sv $(GOLDEN_RTL)/Arbiter8_MainPipeReq.sv
FM_VARIANTS = ProbeQueue

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal。
# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
