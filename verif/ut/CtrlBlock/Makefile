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

# ★ FM assembly glue-partition: 把 16 个子模块以 interface-only 读入(仅端口/方向, 不
#   elaborate 巨大子模块体, 免 Rob 220K 行卡死), 两侧对称黑盒. 关键: 若不给方向,
#   FM 把全部黑盒 pin 设为 inout(canary formality.log 76778 条 "direction unknown ->
#   inout"), 导致 driven 黑盒输出被误判 undriven → rename lsrc / rob exception 等 20 个
#   glue-partition 伪 failing. 给 interface(方向已知)后这些伪 failing 消失(见
#   docs/backend/CtrlBlock_partition_plan.md). assembly 边界由 allow/CtrlBlock.json 声明.
FM_INTERFACE_ONLY = DecodeStage DelayN_15 DelayN_17 FusionDecoder GPAMem MemCtrl \
                    NewDispatch PipeGroupConnect PipelineConnectPipe RedirectGenerator \
                    Rename RenameTableWrapper Rob SnapshotGenerator_14 \
                    SyncDataModuleTemplate_BackendPC_64entry Trace
# 本地 make fm 的 fm_verdict.py --allowlist 取**整数**(允许的不对称 unmatched 数);
# 本 glue 证明清零(0 failing / 0(0) unmatched compare) → 0 即可通过本地判定。
# 官方 assembly 边界(16 对称黑盒)由 verif/signoff/allow/CtrlBlock.json 声明, 经
# manifest/fm_sidecar_verdict.py(JSON 路径)在签核 runner 中生效, 与本地整数判定分离。
FM_ALLOWLIST = 0

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
