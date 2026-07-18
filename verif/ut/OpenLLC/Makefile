# 自动生成:scripts/gen_openllc.py —— 勿手改
MODULE = OpenLLC

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/l2/openllc_pkg.sv \
           $(RTL_DIR)/l2/OpenLLC.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 OpenLLC.sv + 8 子模块类型的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module,-y 会重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/OpenLLC.sv

# 子模块顶(FM ref 依赖列表用)。
SUB_DEPS = $(GOLDEN_RTL)/MMIODiverger.sv $(GOLDEN_RTL)/MMIOMerger.sv $(GOLDEN_RTL)/RNLinkMonitor.sv $(GOLDEN_RTL)/RNXbar.sv $(GOLDEN_RTL)/SNLinkMonitor.sv $(GOLDEN_RTL)/SNXbar.sv $(GOLDEN_RTL)/Slice_4.sv $(GOLDEN_RTL)/TopDownMonitor_1.sv

# FM-only 孙子叶子(grandchildren, interface_only 黑盒)—— 消除黑盒引脚方向猜测的
# 196 failing BBPin。golden Slice_4 内部把 RXRSP_4(rxrspUp/rxrspDown)与 RXDAT_4
# (rxdatDown)的部分 output 引脚接到 `/* unused */` 悬空网(io_out_bits_dbID/srcID/
# resp), 另有 MemUnit.io_snRxrsp_bits_dbID 输入由 RXRSP_4 输出驱动。不提供这两个
# 模块定义时 FM 黑盒化, 引脚方向未知 → 把这些 output 位当可验证 BBPin 且 fan-in
# undriven → 196 failing(全 BBPin, 无 DFF)。用 interface_only 只读端口方向、不拉
# 内部逻辑: 悬空 output 变干净黑盒输出(unread, 两侧同源)、memUnit 输入得同一自由
# 变量驱动 → 全部消解。与 TL2CHICoupledL2 的 RequestBuffer interface_only 同法。
# (MemUnit 内部含 FastArbiter, 但 interface_only 不例化内部, 无需其叶子。)
FM_GRANDCHILD_DEPS = RXRSP_4.sv RXDAT_4.sv
FM_INTERFACE_ONLY = RXRSP_4 RXDAT_4

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次黑盒化子模块。
WRAPPER_SRCS = $(RTL_DIR)/l2/OpenLLC_wrapper.sv $(SUB_DEPS) $(addprefix $(GOLDEN_RTL)/,$(FM_GRANDCHILD_DEPS))
FM_VARIANTS = OpenLLC
FM_REF_DEPS_OpenLLC = MMIODiverger.sv MMIOMerger.sv RNLinkMonitor.sv RNXbar.sv SNLinkMonitor.sv SNXbar.sv Slice_4.sv TopDownMonitor_1.sv $(FM_GRANDCHILD_DEPS)

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
