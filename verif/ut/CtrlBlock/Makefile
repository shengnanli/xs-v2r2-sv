MODULE = CtrlBlock

RTL_DIR = ../../../rtl
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl

# golden 子模块闭包（83 个），由 gen_ctrlblock_ut.py 从 golden 现场算出
include closure.mk

# impl 侧：本目标 + 已有重写件的 child（UT 用 derive 改名成 *_xs，FM 原名进 impl 容器）
#   Rob                                   两侧白盒（ref 用 golden Rob.sv，impl 用重写件）——CtrlBlock 是它 448 位
#                                         debug_otherPdest 悬空输出的第一个可观测边界（codex 0169 D3）
#   pcMem / DelayN×2 / PipelineConnectPipe / PipeGroupConnect
#                                         已签核绿 child：impl 侧用重写件，FM 两侧对称接口黑盒（FM_INTERFACE_ONLY），allow 记 green_child
#   snpt（SnapshotGenerator_14）          同为绿 child 黑盒，但 impl 侧用 golden 体（重写件的共享核文件与 golden 同名 wrapper 撞名，见 gen_ctrlblock_ut.py）
RTL_SRCS = $(RTL_DIR)/backend/CtrlBlock.sv \
           $(RTL_DIR)/backend/Rob.sv \
           $(RTL_DIR)/common/xs_DataModule.sv \
           $(RTL_DIR)/common/xs_SyncDataModule.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate_BackendPC_64entry.sv \
           $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/DelayN_15.sv \
           $(RTL_DIR)/common/DelayN_17.sv \
           $(RTL_DIR)/backend/PipelineConnectPipe.sv \
           $(RTL_DIR)/backend/PipeGroupConnect.sv

# 两侧同源的 golden child（UNCHANGED_GOLDEN_DEP：DecodeStage/FusionDecoder/Rename/RenameTableWrapper/
# RedirectGenerator/Trace/MemCtrl/GPAMem/NewDispatch 仍由别的 lane 重写中；Rob 的 8 个 child 亦同源）
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_CLOSURE_SHARED))
GOLDEN_SRCS     = $(GOLDEN_RTL)/CtrlBlock.sv $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_CLOSURE_REPLACED)) $(RTL_GOLDEN_DEPS)

TB_SRCS = tb.sv

FM_VARIANTS = CtrlBlock
FM_REF_DEPS_CtrlBlock = $(GOLDEN_CLOSURE_REPLACED) $(GOLDEN_CLOSURE_SHARED)

# assembly 边界（两侧对称接口黑盒，声明在 verif/allow/CtrlBlock.json）：
#   green_child                  已签核绿的 child（证书等 freeze 铸，故意不填 certificate_sha256）
#   APPROVED_MEMORY_MACRO_MODEL  三个 firtool 行为级存储叶子（深度 160/320 非 2 的幂，inline 必触发
#                                FMR_ELAB-147 让 set_top 失败：本 lane 实测 stateBankTags_320x3 FM-262/FM-156）
FM_INTERFACE_ONLY = SyncDataModuleTemplate_BackendPC_64entry SnapshotGenerator_14 DelayN_15 DelayN_17 \
                    PipelineConnectPipe PipeGroupConnect \
                    dt_pcTransType_160x2 diff_rat_state_bank_320x776 stateBankTags_320x3
# ★加强（不是放宽）：逐个比而不是合并重复寄存器后比——Rob 白盒展开后 160 项 debug 阵列的同构次态
# 会让 merge 阶段跑不完（verif/ut/Rob/Makefile 实测 5674 s 仍未到 match）。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 的随机初始化 initial 块与断言只在 `ifndef SYNTHESIS 下；两侧都定义 SYNTHESIS，初值由 +vcs+initreg 给。
# ★双例化不许运行期 random（两个实例各摇各的初值），只用 +0 / +1 两档常量★
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG  ?= +vcs+initreg+0
