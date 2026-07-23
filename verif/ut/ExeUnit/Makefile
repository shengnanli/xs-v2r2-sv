MODULE = ExeUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口表 / 逻辑 / 连线 svh)。
RTL_SRCS = $(RTL_DIR)/backend/exeunit_pkg.sv \
           $(RTL_DIR)/backend/ExeUnit.sv

TB_SRCS = variants_xs.sv tb.sv

# FU(Alu/Mul/...)、Dispatcher(in1ToN)、ClockGate 全部作 golden 黑盒;
# UT 双例化两侧共用同一份定义,只比对 ExeUnit 的分发接线/流水/门控/仲裁 glue。
SUB_DEPS = $(GOLDEN_RTL)/Alu.sv \
           $(GOLDEN_RTL)/Bku.sv \
           $(GOLDEN_RTL)/ClockGate.sv \
           $(GOLDEN_RTL)/Dispatcher.sv \
           $(GOLDEN_RTL)/MulUnit.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ExeUnit.sv $(SUB_DEPS)

# FM 黑盒边界策略(assembly signoff):
#   FU(Alu/Mul/Bku)是独立 FM 目标(305 集, 各自 SIGNOFF_PASS), 在 ExeUnit 里作声明黑盒边界
#   (assembly depends_on 绿 child) —— ref/impl 两侧都不提供 RTL, hdlin_unresolved=black_box。
#   ClockGate / Dispatcher(in1ToN)不是 305 目标, 是小规模非厂商逻辑(时钟门控 latch cell /
#   纯组合路由), 故 **两侧 elaborate** 让 FM 真正比对(白盒), 而非黑盒吸收:
#     - ref 侧: 经 FM_REF_DEPS_ExeUnit 提供 ClockGate.sv + Dispatcher.sv;
#     - impl 侧: 经 WRAPPER_SRCS 提供同一份 golden ClockGate.sv + Dispatcher.sv。
#   两侧同为一字节相同的 golden 定义, u_core 层次差异不再触发不对称常量传播。
WRAPPER_SRCS = $(RTL_DIR)/backend/ExeUnit_wrapper.sv \
               $(GOLDEN_RTL)/ClockGate.sv \
               $(GOLDEN_RTL)/Dispatcher.sv
FM_VARIANTS = ExeUnit
FM_REF_DEPS_ExeUnit = ClockGate.sv Dispatcher.sv

include ../../../scripts/ut_common.mk

# golden 内含非综合断言;UT/FM 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# FU 黑盒内例化更深的 golden 叶子,用 -y 库目录自动解析。
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
