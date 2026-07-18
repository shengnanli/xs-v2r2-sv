# 自动生成:scripts/gen_xscore.py —— 勿手改
MODULE = XSCore

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/xscore/xscore_pkg.sv \
           $(RTL_DIR)/xscore/XSCore.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 XSCore.sv + 3 子模块(Frontend/Backend/MemBlock)的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module(如 DivUnit.sv 含 divunit_pkg),
# -y 会对其重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/XSCore.sv

# 子模块顶(FM ref 依赖列表用)。
SUB_DEPS = $(GOLDEN_RTL)/Frontend.sv $(GOLDEN_RTL)/Backend.sv $(GOLDEN_RTL)/MemBlock.sv

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次黑盒化 3 子模块。
# (FM 审计 2026-07)golden 已切干净基线(无 difftest 端口),而本核连线含 difftest-glue
# 端口(frontend.io_hartId / cfVec pc·pd_* / debug_seqNum 等,历史于 difftest 基线验证)。
# 若两侧给 Frontend/Backend/MemBlock 干净基线真定义,impl 侧 FE-LINK-7 挂 link
# (impl 引脚在干净定义上不存在)→ FM-046。故两侧均不给 3 个子模块定义,统一走
# hdlin_unresolved_modules=black_box:公共引脚按名配对验证 glue;difftest 增量引脚
# 只在 impl 侧存在,成为 unmatched BBPin(基线漂移的诚实呈现,不参与判定)。
WRAPPER_SRCS = $(RTL_DIR)/xscore/XSCore_wrapper.sv
FM_VARIANTS = XSCore
FM_REF_DEPS_XSCore =

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/xscore
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
# golden 叶子全集(传递闭包),-f 显式列出,每文件一次。
VCS += -f golden_filelist.f
VCS += +libext+.sv+.v
VCS += -assert disable
