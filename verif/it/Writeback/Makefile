MODULE = Writeback_IT

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
UT_DIR     = ../../ut

# ===========================================================================
# IT（集成级）后端 Writeback 簇：
#   golden(WbDataPath u_g + WbFuBusyTable u_g2) vs 全重写 Writeback_it (u_i)
#
#   Writeback_it：顶层端口 = golden WbDataPath 端口 + golden WbFuBusyTable 端口（拼接，
#                 零碰撞，逐字相同），内部并行例化两个写回相关重写核：
#                   WbDataPath_xs    -> xs_WbDataPath_core
#                                       （+ golden 仲裁器/合并/DPIC 写回叶子）
#                   WbFuBusyTable_xs -> xs_WbFuBusyTable_core（纯组合 busy 表）
#
#   装配实现（由 gen_it.py 生成）：
#     Writeback_it.sv : 扁平 wrapper，例化两个 UT _xs 适配器（端口逐字 = golden）
#     tb.sv           : 双例化两侧顶层，喂相同随机激励，逐拍比对全部输出
#
#   => 把两个重写写回核（xs_WbDataPath_core / xs_WbFuBusyTable_core）放进同一 IT 顶层
#      并行整簇对比 golden；xs_WbDataPath_core glue 与其 golden 仲裁器叶子（黑盒边界）
#      整簇连起来跑——per-module UT（各核单独被 golden 包围）覆盖不到的集成边界。
#
#   WbDataPath 的叶子 RealWBCollideChecker×5 / VldMergeUnit×2 / RealWBArbiter / 及其叶子
#   是写回仲裁/合并结构原语，DummyDPICWrapper×26 是 difftest 探针纯 sink——工程未重写、
#   无独立 xs 核，按 IT 规则作两侧共享 golden 叶子保留（DummyDPIC 用本地 stub 黑盒）。
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧（u_i 链路）：两核 pkg + 核 + difftest stub + 各模块 UT 的 _xs 适配器 + IT 装配
# ---------------------------------------------------------------------------
XS_PKGS = \
    $(RTL_DIR)/backend/wbdatapath_pkg.sv \
    $(RTL_DIR)/backend/wbfubusytable_pkg.sv

XS_CORES = \
    $(RTL_DIR)/backend/WbDataPath.sv \
    $(RTL_DIR)/backend/WbDataPath_dpic_stub.sv \
    $(RTL_DIR)/backend/WbFuBusyTable.sv

# 重写叶子适配器（golden 扁平端口 -> xs 核；复用各模块 UT 的 variants_xs.sv）
XS_ADAPTERS = \
    $(UT_DIR)/WbDataPath/variants_xs.sv \
    $(UT_DIR)/WbFuBusyTable/variants_xs.sv

# IT 装配（本目录）
IT_ASSEMBLY = \
    Writeback_it.sv

# ---------------------------------------------------------------------------
# golden 共享叶子（两侧共用）：
#   WbDataPath 真子模块（影响输出）：VldMergeUnit / RealWBCollideChecker / RealWBArbiter 及叶子
#   （DummyDPICWrapper 纯 sink，用 rtl 本地 stub 黑盒，已在 XS_CORES 里）。
# ---------------------------------------------------------------------------
WBDP_DEPS = ByteMaskTailGen.sv MaskExtractor.sv UIntToContLow0s.sv UIntToContLow1s.sv \
            VldMgu.sv VldMergeUnit.sv \
            RealWBArbiter.sv RealWBArbiter_1.sv RealWBArbiter_2.sv RealWBArbiter_3.sv \
            RealWBArbiter_14.sv RealWBArbiter_15.sv RealWBArbiter_20.sv RealWBArbiter_21.sv \
            RealWBArbiter_26.sv \
            RealWBCollideChecker.sv RealWBCollideChecker_1.sv RealWBCollideChecker_2.sv \
            RealWBCollideChecker_3.sv RealWBCollideChecker_4.sv

# u_g 顶层独有：golden WbDataPath 顶层 + golden WbFuBusyTable 顶层（纯叶子）
GOLD_TOP = $(GOLDEN_RTL)/WbDataPath.sv $(GOLDEN_RTL)/WbFuBusyTable.sv

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = $(XS_PKGS) $(XS_CORES) $(XS_ADAPTERS) $(IT_ASSEMBLY)

GOLDEN_SRCS = $(GOLD_TOP) $(addprefix $(GOLDEN_RTL)/,$(WBDP_DEPS))

TB_SRCS = tb.sv

# IT 不做 FM（FM 是 per-module 等价证明的事）；此处置空。
FM_VARIANTS =

include ../../../scripts/ut_common.mk

# golden 子模块/顶层含 XSError/XSPerf/assert（非综合）；关掉以免随机激励误触 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
# +vcs+initreg+0（runtime）：无 reset 寄存器清 0，保证两侧从同一确定态出发。
SIM_ARGS += +vcs+initreg+0
