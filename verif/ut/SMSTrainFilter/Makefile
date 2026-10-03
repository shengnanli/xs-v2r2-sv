MODULE = SMSTrainFilter

# SMS 训练过滤器：xs_TrainFilter_core 的第三个变体（深 8、条目复位、无 enable/ready/flush、5 个入队指针）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_TrainFilter_core.sv \
           $(RTL_DIR)/memblock/SMSTrainFilter.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SMSTrainFilter.sv

FM_VARIANTS = SMSTrainFilter
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 重排序流水不复位（条目复位）：tb 复位期间持续送 valid=0 把三级流水冲成全 0。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
