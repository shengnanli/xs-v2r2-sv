# 自动生成:scripts/gen_xstile.py —— 勿手改
MODULE = XSTile

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/xstile/xstile_pkg.sv \
           $(RTL_DIR)/xstile/XSTile.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 XSTile.sv + 3 子模块(XSCore/L2Top/IntBuffer)的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module,-y 会重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/XSTile.sv

# 子模块顶(FM ref 依赖列表用)。
SUB_DEPS = $(GOLDEN_RTL)/IntBuffer.sv $(GOLDEN_RTL)/L2Top.sv $(GOLDEN_RTL)/XSCore.sv

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次黑盒化 3 子模块。
WRAPPER_SRCS = $(RTL_DIR)/xstile/XSTile_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = XSTile
FM_REF_DEPS_XSTile = IntBuffer.sv L2Top.sv XSCore.sv

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/xstile
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
# golden 叶子全集(传递闭包),-f 显式列出,每文件一次。
VCS += -f golden_filelist.f
VCS += +libext+.sv+.v
VCS += -assert disable
