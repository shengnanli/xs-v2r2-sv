# 自动生成:scripts/gen_l2top.py —— 勿手改
MODULE = L2Top

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/l2/l2top_pkg.sv \
           $(RTL_DIR)/l2/L2Top.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 L2Top.sv + 15 子模块类型的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module,-y 会重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/L2Top.sv

# 子模块顶(FM ref 依赖列表用)。
SUB_DEPS = $(GOLDEN_RTL)/BusErrorUnit.sv $(GOLDEN_RTL)/BusPerfMonitor.sv $(GOLDEN_RTL)/DelayN_334.sv $(GOLDEN_RTL)/TL2CHICoupledL2.sv $(GOLDEN_RTL)/TLBuffer_13.sv $(GOLDEN_RTL)/TLBuffer_15.sv $(GOLDEN_RTL)/TLBuffer_20.sv $(GOLDEN_RTL)/TLBuffer_22.sv $(GOLDEN_RTL)/TLBuffer_6.sv $(GOLDEN_RTL)/TLBuffer_8.sv $(GOLDEN_RTL)/TLLogger.sv $(GOLDEN_RTL)/TLLogger_1.sv $(GOLDEN_RTL)/TLLogger_2.sv $(GOLDEN_RTL)/TLXbar_5.sv $(GOLDEN_RTL)/TLXbar_6.sv

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次黑盒化子模块。
WRAPPER_SRCS = $(RTL_DIR)/l2/L2Top_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = L2Top
FM_REF_DEPS_L2Top = BusErrorUnit.sv BusPerfMonitor.sv DelayN_334.sv TL2CHICoupledL2.sv TLBuffer_13.sv TLBuffer_15.sv TLBuffer_20.sv TLBuffer_22.sv TLBuffer_6.sv TLBuffer_8.sv TLLogger.sv TLLogger_1.sv TLLogger_2.sv TLXbar_5.sv TLXbar_6.sv

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/l2
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
# golden 叶子全集(传递闭包),-f 显式列出,每文件一次。
VCS += -f golden_filelist.f
VCS += +libext+.sv+.v
VCS += -assert disable
