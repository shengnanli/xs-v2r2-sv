MODULE = DatamoduleResultBuffer

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/DatamoduleResultBuffer.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DatamoduleResultBuffer.sv
FM_VARIANTS = DatamoduleResultBuffer

include ../../../scripts/ut_common.mk

# golden 的 4 条 assert(DatamoduleResultBuffer.scala:63/64/76/77)是 valid/ready
# 前缀契约,本 tb 的激励遵守它。关 SYNTHESIS 是为了两侧初始化行为一致
# (golden 的 ENABLE_INITIAL_REG_ 只在 ifndef SYNTHESIS 下生效),
# 让 +vcs+initreg 对两侧同等作用。
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
