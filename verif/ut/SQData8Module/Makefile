MODULE = SQData8Module

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/SQData8Module.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SQData8Module.sv
FM_VARIANTS = SQData8Module

include ../../../scripts/ut_common.mk

# golden 的两条 assert(StoreQueueData.scala:211/216)禁止同址双写。本 tb **故意**
# 打同址双写来验证写口优先级(FM 要逐位证,不能靠"上游不会这么干"绕过),
# 所以两侧断言一起关掉。副作用:golden 的 ENABLE_INITIAL_REG_ 随机初始化块也一并
# 关闭,两侧不复位寄存器起点都是 X —— tb 用"全条目预热写"把它们写满后才开比对。
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
