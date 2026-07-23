MODULE = ExeUnit_4

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口表 / 逻辑 / 连线 svh)。
RTL_SRCS = $(RTL_DIR)/backend/exeunit_4_pkg.sv \
           $(RTL_DIR)/backend/ExeUnit_4.sv

TB_SRCS = variants_xs.sv tb.sv

# UT: Alu(FU) 与 Dispatcher_4(in1ToN)两侧共用同一份 golden 定义,
# 只比对 ExeUnit_4 的分发接线/流水/仲裁 glue(本变体单 FU=Alu, 无 ClockGate)。
SUB_DEPS = $(GOLDEN_RTL)/Alu.sv \
           $(GOLDEN_RTL)/Dispatcher_4.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ExeUnit_4.sv $(SUB_DEPS)

# FM 黑盒边界策略(assembly signoff), 与 ExeUnit 模板一致:
#   Alu 是独立 FM 目标(305 集, SIGNOFF_PASS), 在 ExeUnit_4 里作声明黑盒边界
#   (assembly depends_on 绿 child)—— ref/impl 两侧都不提供 RTL, hdlin_unresolved=black_box。
#   Dispatcher_4(in1ToN)不是 305 目标, 是小规模非厂商逻辑(纯组合路由), 故 **两侧
#   elaborate** 让 FM 真正比对(白盒), 而非黑盒吸收:
#     - ref 侧: 经 FM_REF_DEPS_ExeUnit_4 提供 Dispatcher_4.sv;
#     - impl 侧: 经 WRAPPER_SRCS 提供同一份 golden Dispatcher_4.sv。
#   两侧同为一字节相同的 golden 定义, u_core 层次差异不再触发不对称常量传播。
WRAPPER_SRCS = $(RTL_DIR)/backend/ExeUnit_4_wrapper.sv \
               $(GOLDEN_RTL)/Dispatcher_4.sv
FM_VARIANTS = ExeUnit_4
FM_REF_DEPS_ExeUnit_4 = Dispatcher_4.sv

include ../../../scripts/ut_common.mk

# golden 内含非综合断言;UT/FM 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# FU 黑盒内例化更深的 golden 叶子,用 -y 库目录自动解析。
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
