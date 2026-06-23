MODULE = ExeUnit_4

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口表 / 逻辑 / 连线 svh)。
RTL_SRCS = $(RTL_DIR)/backend/exeunit_4_pkg.sv \
           $(RTL_DIR)/backend/ExeUnit_4.sv

TB_SRCS = variants_xs.sv tb.sv

# FU(Alu/Mul/...)、Dispatcher(in1ToN)、ClockGate 全部作 golden 黑盒;
# UT 双例化两侧共用同一份定义,只比对 ExeUnit 的分发接线/流水/门控/仲裁 glue。
SUB_DEPS = $(GOLDEN_RTL)/Alu.sv \
           $(GOLDEN_RTL)/Dispatcher_4.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ExeUnit_4.sv $(SUB_DEPS)

# FM:FU/Dispatcher/ClockGate 在 ref 与 impl 两侧都**不提供 RTL**,
# 让 FM 按 hdlin_unresolved_modules=black_box 当作同名同端口的未解析黑盒。
# 这样只比对 ExeUnit 的 glue(流水/门控/仲裁);否则 FM 会读进 ClockGate 内部
# 的使能锁存器(EN_reg),因 impl 多一层 u_core 层次而被不对称常量传播,
# 把同源 ClockGate 锁存器误判为 LAT vs LAT1X 而 fail(同 MulUnit 阵列黑盒思路)。
WRAPPER_SRCS = $(RTL_DIR)/backend/ExeUnit_4_wrapper.sv
FM_VARIANTS = ExeUnit_4
FM_REF_DEPS_ExeUnit_4 =

include ../../../scripts/ut_common.mk

# golden 内含非综合断言;UT/FM 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# FU 黑盒内例化更深的 golden 叶子,用 -y 库目录自动解析。
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
