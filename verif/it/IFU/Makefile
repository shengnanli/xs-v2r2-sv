MODULE = IFU_IT

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
UT_DIR     = ../../ut

# ===========================================================================
# IT（集成级）IFU 簇：golden NewIFU (u_g) vs 全重写 NewIFU_it (u_i)
#
#   NewIFU_it   : 顶层端口 = golden NewIFU（527 口逐字相同）；内部例化 NewIFU_xs
#                 适配器 → xs_NewIFU_core（重写取指流水 glue）。
#   NewIFU_subs_it.sv : xs_NewIFU_core 按名例化的 5 个 xs_newifu_* 子适配器，
#                 IT 版把算法叶子替换为重写核：
#                   xs_newifu_rvcexpander  → xs_RVCExpander_core   （重写）
#                   xs_newifu_predecode    → xs_PreDecode_core     （重写）
#                   xs_newifu_f3predecoder → xs_F3Predecoder_core  （重写）
#                   xs_newifu_predchecker  → golden PredChecker    （工程无独立重写核）
#                   xs_newifu_frontendtrigger → golden FrontendTrigger（工程无独立重写核）
#
#   ★ 与 UT 的关键差异：UT 用 rtl/frontend/NewIFU_subs.sv（叶子全是 golden 黑盒）；
#     IT 用本目录 NewIFU_subs_it.sv（RVCExpander/PreDecode/F3Predecoder 改为重写核），
#     首次让「重写 glue（xs_NewIFU_core）↔ 重写叶子核」边界真实连起来跑。
#
#   叶子边界 = golden PredChecker / FrontendTrigger（工程未提供独立重写核，如实保留 golden）。
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧（u_i 链路）：pkg + 重写叶子核 + xs_NewIFU_core glue + IT 装配
# ---------------------------------------------------------------------------
# -- 共享译码/展开包 --
XS_PKGS = \
    $(RTL_DIR)/frontend/predecode_pkg.sv \
    $(RTL_DIR)/frontend/rvc_expander_pkg.sv

# -- 重写算法叶子核（独立重写核：算法逻辑全在这里） --
XS_LEAVES = \
    $(RTL_DIR)/frontend/PreDecode.sv \
    $(RTL_DIR)/frontend/F3Predecoder.sv \
    $(RTL_DIR)/frontend/RVCExpander.sv

# -- 重写取指流水 glue 核（xs_NewIFU_core，定义 xs_newifu_pkg） --
XS_GLUE = \
    $(RTL_DIR)/frontend/NewIFU.sv

# -- IT 装配（本目录）：重写叶子版子适配器 + 适配器壳 + IT 顶层 --
IT_ASSEMBLY = \
    NewIFU_subs_it.sv \
    $(UT_DIR)/NewIFU/variants_xs.sv \
    NewIFU_it.sv

# ---------------------------------------------------------------------------
# golden 叶子：u_g 用 golden NewIFU + 5 golden 叶子；
#   其中 PredChecker / FrontendTrigger 也被 NewIFU_subs_it.sv（重写侧）共用。
# ---------------------------------------------------------------------------
GOLD_TOP = $(GOLDEN_RTL)/NewIFU.sv
GOLD_LEAVES = \
    $(GOLDEN_RTL)/PreDecode.sv \
    $(GOLDEN_RTL)/RVCExpander.sv \
    $(GOLDEN_RTL)/F3Predecoder.sv \
    $(GOLDEN_RTL)/PredChecker.sv \
    $(GOLDEN_RTL)/FrontendTrigger.sv

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = $(XS_PKGS) $(XS_LEAVES) $(XS_GLUE) $(IT_ASSEMBLY)

GOLDEN_SRCS = $(GOLD_TOP) $(GOLD_LEAVES)

TB_SRCS = tb.sv

# IT 不做 FM（FM 是 per-module 等价证明的事）；此处置空。
FM_VARIANTS =

include ../../../scripts/ut_common.mk

# golden 子模块含 `ifndef SYNTHESIS 随机初值/运行时断言；关掉以免随机激励误触 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
# +vcs+initreg+0（runtime）：无 reset 寄存器清 0，保证两侧从同一确定态出发。
SIM_ARGS += +vcs+initreg+0
