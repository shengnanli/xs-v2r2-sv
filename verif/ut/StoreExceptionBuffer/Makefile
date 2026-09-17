MODULE = StoreExceptionBuffer

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/StoreExceptionBuffer.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/StoreExceptionBuffer.sv
FM_VARIANTS = StoreExceptionBuffer

include ../../../scripts/ut_common.mk

# golden 本身一条 RTL 断言都没有(Scala 里那条 assert 是 Scala 层的 require,
# 不产生 RTL)。这里定义 SYNTHESIS 只是为了关掉 golden 的 ENABLE_INITIAL_REG_
# 随机初始化,让 +vcs+initreg 对两侧同等作用;tb 用"全端口预热"补齐起点。
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
