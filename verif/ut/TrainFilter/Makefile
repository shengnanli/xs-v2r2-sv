MODULE = TrainFilter

# L1 预取训练过滤器家族：一个参数化核 xs_TrainFilter_core + 两个薄 wrapper
# （TrainFilter：载荷 pc；TrainFilter_1：载荷 {miss, meta_prefetch} 折成 {miss, pfHitStream}）。
# 一个 UT 同测两对；无子模块、无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_TrainFilter_core.sv \
           $(RTL_DIR)/memblock/TrainFilter.sv \
           $(RTL_DIR)/memblock/TrainFilter_1.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TrainFilter.sv \
              $(GOLDEN_RTL)/TrainFilter_1.sv

FM_VARIANTS = TrainFilter TrainFilter_1
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# ★重排序流水与 FIFO 条目不复位★：+random 档两侧初值不同。tb 复位期间持续送 valid=0 把
# 三级流水冲成全 0；条目内容只在 train_req.valid=1（该项必已写过）时比对。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
