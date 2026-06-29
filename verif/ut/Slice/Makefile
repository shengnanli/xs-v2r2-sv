# 自动生成:scripts/gen_slice.py —— 勿手改
MODULE = Slice

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/l2/slice_pkg.sv \
           $(RTL_DIR)/l2/Slice.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 Slice.sv + 18 子模块类型的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module,-y 会重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/Slice.sv

# 子模块顶(FM ref 依赖列表用)。
SUB_DEPS = $(GOLDEN_RTL)/DataStorage.sv $(GOLDEN_RTL)/Directory.sv $(GOLDEN_RTL)/GrantBuffer.sv $(GOLDEN_RTL)/L2Slice.sv $(GOLDEN_RTL)/MSHRBuffer.sv $(GOLDEN_RTL)/MSHRBuffer_1.sv $(GOLDEN_RTL)/MSHRCtl.sv $(GOLDEN_RTL)/MainPipe_1.sv $(GOLDEN_RTL)/RXDAT.sv $(GOLDEN_RTL)/RXRSP.sv $(GOLDEN_RTL)/RXSNP.sv $(GOLDEN_RTL)/RequestArb.sv $(GOLDEN_RTL)/RequestBuffer.sv $(GOLDEN_RTL)/SinkA.sv $(GOLDEN_RTL)/SinkC.sv $(GOLDEN_RTL)/TXDAT.sv $(GOLDEN_RTL)/TXREQ.sv $(GOLDEN_RTL)/TXRSP.sv

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次黑盒化子模块。
WRAPPER_SRCS = $(RTL_DIR)/l2/Slice_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = Slice
FM_REF_DEPS_Slice = DataStorage.sv Directory.sv GrantBuffer.sv L2Slice.sv MSHRBuffer.sv MSHRBuffer_1.sv MSHRCtl.sv MainPipe_1.sv RXDAT.sv RXRSP.sv RXSNP.sv RequestArb.sv RequestBuffer.sv SinkA.sv SinkC.sv TXDAT.sv TXREQ.sv TXRSP.sv

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
