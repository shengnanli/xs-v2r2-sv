# 自动生成：scripts/gen_ctrlblock_ut.py —— 勿手改
MODULE = CtrlBlock

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包（核通过 `include 引入端口/glue/inst svh）。
RTL_SRCS = $(RTL_DIR)/backend/ctrlblock_pkg.sv \
           $(RTL_DIR)/backend/CtrlBlock.sv

TB_SRCS = variants_xs.sv tb.sv

# 16 个子模块类型作 golden 黑盒；UT 双例化两侧共用同一份 golden 定义。
SUB_DEPS = $(GOLDEN_RTL)/DecodeStage.sv \
           $(GOLDEN_RTL)/DelayN_15.sv \
           $(GOLDEN_RTL)/DelayN_17.sv \
           $(GOLDEN_RTL)/FusionDecoder.sv \
           $(GOLDEN_RTL)/GPAMem.sv \
           $(GOLDEN_RTL)/MemCtrl.sv \
           $(GOLDEN_RTL)/NewDispatch.sv \
           $(GOLDEN_RTL)/PipeGroupConnect.sv \
           $(GOLDEN_RTL)/PipelineConnectPipe.sv \
           $(GOLDEN_RTL)/RedirectGenerator.sv \
           $(GOLDEN_RTL)/Rename.sv \
           $(GOLDEN_RTL)/RenameTableWrapper.sv \
           $(GOLDEN_RTL)/Rob.sv \
           $(GOLDEN_RTL)/SnapshotGenerator_14.sv \
           $(GOLDEN_RTL)/SyncDataModuleTemplate_BackendPC_64entry.sv \
           $(GOLDEN_RTL)/Trace.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/CtrlBlock.sv $(SUB_DEPS)

# FM：impl 侧（wrapper->可读核）与 ref 侧在相同层次黑盒化子模块。
# wrapper 模块须与 golden 同名 CtrlBlock，故用 CtrlBlock_wrapper.sv(module CtrlBlock)
# 而非 variants_xs.sv(module CtrlBlock_xs，UT 双例化专用)。
WRAPPER_SRCS = $(RTL_DIR)/backend/CtrlBlock_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = CtrlBlock
FM_REF_DEPS_CtrlBlock = DecodeStage.sv DelayN_15.sv DelayN_17.sv FusionDecoder.sv GPAMem.sv MemCtrl.sv NewDispatch.sv PipeGroupConnect.sv PipelineConnectPipe.sv RedirectGenerator.sv Rename.sv RenameTableWrapper.sv Rob.sv SnapshotGenerator_14.sv SyncDataModuleTemplate_BackendPC_64entry.sv Trace.sv

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest；UT 关掉并关随机化，处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# 寄存器初值复位为 0（编译开 initreg，运行期 +vcs+initreg+0 经 SIM_ARGS 注入）。
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
# 子模块更深 golden 叶子用 -y 库目录按文件名自动解析（.sv 与 difftest 探针 .v）。
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
