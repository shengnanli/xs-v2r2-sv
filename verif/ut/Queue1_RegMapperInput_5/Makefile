MODULE = Queue1_RegMapperInput_5

RTL_DIR = ../../../rtl
# 参数化核体 xs_Queue1_RegMapperInput 与它的使用者 ICacheCtrlUnit 同在一个文件里
# （单文件规范：核体跟着父模块走），所以要一起编；本 UT 只例化 Queue1_RegMapperInput_5_xs。
RTL_SRCS = $(RTL_DIR)/frontend/ICacheCtrlUnit.sv \
           $(RTL_DIR)/frontend/Queue1_RegMapperInput_5.sv
TB_SRCS = tb.sv

# G1 的 ICacheCtrlUnit.out_back_q 叫 Queue1_RegMapperInput_5（G0 里叫 _3）。
# ★G1 的 Queue1_RegMapperInput_3 是 MemMisc/TLPMA 的那个队列，不是这个。
GOLDEN_SRCS = $(GOLDEN_RTL)/Queue1_RegMapperInput_5.sv
FM_VARIANTS = Queue1_RegMapperInput_5

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
