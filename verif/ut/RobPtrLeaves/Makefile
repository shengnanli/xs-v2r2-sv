# RobPtrLeaves —— Rob 的三个小子模块：提交卡死计数器、入队指针组、出队（提交）指针组。
# 三个都是自足叶子：无子模块、无黑盒。
MODULE = RobPtrLeaves

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/CommitStuckCounter.sv \
           $(RTL_DIR)/backend/RobEnqPtrWrapper.sv \
           $(RTL_DIR)/backend/NewRobDeqPtrWrapper.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/CommitStuckCounter.sv \
              $(GOLDEN_RTL)/RobEnqPtrWrapper.sv \
              $(GOLDEN_RTL)/NewRobDeqPtrWrapper.sv

FM_VARIANTS = CommitStuckCounter RobEnqPtrWrapper NewRobDeqPtrWrapper
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 寄存器全部异步复位；initreg 三档照跑（复位前的初值在复位拍内被覆盖，比较窗口从复位后开始）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
