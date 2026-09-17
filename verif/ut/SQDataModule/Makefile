MODULE = SQDataModule

RTL_DIR = ../../../rtl
# 装配壳 + 它例化的子模块,两份都要编(子模块另有自己的 UT)。
RTL_SRCS = $(RTL_DIR)/memblock/SQDataModule.sv $(RTL_DIR)/memblock/SQData8Module.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SQDataModule.sv $(GOLDEN_RTL)/SQData8Module.sv
FM_VARIANTS = SQDataModule
# FM 时 golden 侧 SQDataModule 需要 SQData8Module 一起进 ref。
FM_REF_DEPS_SQDataModule = SQData8Module.sv

include ../../../scripts/ut_common.mk

# 父子各有一对 assert(StoreQueueData.scala:332/337 与 :211/216)禁止同址双写。
# 本 tb 故意打同址双写验优先级,两侧断言一起关。
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
