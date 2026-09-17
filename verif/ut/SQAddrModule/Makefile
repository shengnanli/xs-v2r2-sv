MODULE = SQAddrModule

RTL_DIR = ../../../rtl
# 家族两个变体共享 xs_SQAddrModule_core,必须一起编、一起测。
RTL_SRCS = $(RTL_DIR)/memblock/SQAddrModule.sv $(RTL_DIR)/memblock/SQAddrModule_1.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SQAddrModule.sv $(GOLDEN_RTL)/SQAddrModule_1.sv
FM_VARIANTS = SQAddrModule SQAddrModule_1

include ../../../scripts/ut_common.mk

# golden 的 assert(StoreQueueData.scala:88)禁止同址双写。本 tb **故意**打同址双写
# 来验证写口优先级(FM 要逐位证),所以两侧断言一起关。副作用:golden 的
# ENABLE_INITIAL_REG_ 随机初始化也一并关闭 —— tb 用"全条目预热写"补齐起点。
VCS += +define+SYNTHESIS

# ★ +vcs+initreg 必须**编译期与运行期同时**给 ★
# 实测:只在运行期给,VCS 报 Warning-[VICIU] 并静默忽略 —— 那一轮等于没测。
# 用法(两种模式各跑一轮,中间要清干净重编):
#   make clean && make run INITREG=random SEED=1
#   make clean && make run INITREG=0      SEED=1
ifneq ($(INITREG),)
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
endif
