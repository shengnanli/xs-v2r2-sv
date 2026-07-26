MODULE = Queue72_CoupledL2Imp_Anon

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

# 手写可读控制核 xs_Queue72_CoupledL2Imp_Anon_core, 只重写指针/full 控制 FSM。
# 存储宏 ram_72x15 在 UT 由 GOLDEN_SRCS 提供(impl 核例化同名, 链接到 golden 实现);
# 在 FM 两侧均**不给 RTL** => hdlin_unresolved_modules=black_box 对称黑盒(其读端口
# 组合表达式 Memory[R0_addr] 因 72 深/7 位地址触发 FMR_ELAB-147, 且存储阵列非控制
# 逻辑等价对象, 故黑盒——两侧同名同接口, ram 输出对称喂两核, 只证指针/full 控制 FSM)。
RTL_SRCS = $(RTL_DIR)/l2/Queue72_CoupledL2Imp_Anon.sv
WRAPPER_SRCS = $(RTL_DIR)/l2/Queue72_CoupledL2Imp_Anon_wrapper.sv
# UT 双例化: golden 顶层 + 其存储宏 ram_72x15(供 golden 与 impl 核共同链接)。
GOLDEN_SRCS = $(GOLDEN_RTL)/Queue72_CoupledL2Imp_Anon.sv $(GOLDEN_RTL)/ram_72x15.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 strict; ram_72x15 两侧均 unresolved => 对称黑盒(不进 FM_REF_DEPS)。
FM_VARIANTS = Queue72_CoupledL2Imp_Anon
FM_REF_DEPS_Queue72_CoupledL2Imp_Anon =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
