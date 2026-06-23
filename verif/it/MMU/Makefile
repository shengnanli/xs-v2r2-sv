MODULE = MMU_IT

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
UT_DIR     = ../../ut

# ===========================================================================
# IT（集成级）MMU 簇：golden L2TLB (u_g) vs 全重写 MMU_it (u_i)
#
#   MMU_it : 顶层端口 = golden L2TLB；互联 body（Arbiter*/DelayN* 结构 glue）保留 golden，
#            7 个重写算法叶子实例全部换成 _xs 适配器（drop-in，端口与 golden 同名模块逐字一致）：
#              PMP->PMP_xs  L2TlbMissQueue->L2TlbMissQueue_xs  PtwCache->PtwCache_xs
#              PTW->PTW_xs  HPTW->HPTW_xs  LLPTW->LLPTW_xs  L2TlbPrefetch->L2TlbPrefetch_xs
#
#   叶子适配器（*_xs，纯端口搬运 + 重写 xs_*_core，无 golden 算法叶子）直接复用
#   各模块 UT 的 verif/ut/<M>/variants_xs.sv（每个文件仅含 1 个适配器模块）。
#
#   叶子边界 = SRAM 模板 / SRAM 宏（存储原语）与结构 arbiter（RRArbiterInit / Arbiter2_LLPTW_Anon）：
#   golden 与 rewrite 共用，非算法，作为共享叶子保留 golden。
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧（u_i 链路）：xs 核 pkg + 核 + 叶子适配器 + IT 装配
# ---------------------------------------------------------------------------
XS_PKGS = \
    $(RTL_DIR)/memblock/pmp_pkg.sv \
    $(RTL_DIR)/memblock/l2tlbmissqueue_pkg.sv \
    $(RTL_DIR)/memblock/ptwcache_pkg.sv \
    $(RTL_DIR)/memblock/ptw_pkg.sv \
    $(RTL_DIR)/memblock/hptw_pkg.sv \
    $(RTL_DIR)/memblock/llptw_pkg.sv \
    $(RTL_DIR)/memblock/l2tlbprefetch_pkg.sv

# -- 重写 xs 核（算法逻辑全部在这里） --
XS_CORES = \
    $(RTL_DIR)/memblock/PMP.sv \
    $(RTL_DIR)/memblock/PMPChecker.sv \
    $(RTL_DIR)/memblock/L2TlbMissQueue.sv \
    $(RTL_DIR)/memblock/PtwCache.sv \
    $(RTL_DIR)/memblock/PTW.sv \
    $(RTL_DIR)/memblock/HPTW.sv \
    $(RTL_DIR)/memblock/LLPTW.sv \
    $(RTL_DIR)/memblock/L2TlbPrefetch.sv

# -- 重写叶子适配器（golden 扁平端口 -> xs 核；复用各模块 UT 的 variants_xs.sv） --
XS_ADAPTERS = \
    $(UT_DIR)/PMP/variants_xs.sv \
    $(UT_DIR)/PMPChecker/variants_xs.sv \
    $(UT_DIR)/L2TlbMissQueue/variants_xs.sv \
    $(UT_DIR)/PtwCache/variants_xs.sv \
    $(UT_DIR)/PTW/variants_xs.sv \
    $(UT_DIR)/HPTW/variants_xs.sv \
    $(UT_DIR)/LLPTW/variants_xs.sv \
    $(UT_DIR)/L2TlbPrefetch/variants_xs.sv

# -- IT 装配（本目录） --
IT_ASSEMBLY = MMU_it.sv

# ---------------------------------------------------------------------------
# golden 共享叶子（两侧共用，u_i 链路里 _xs 适配器 / xs 核内部也例化这些）：
#   - PtwCache 的 SplittedSRAM 闭包 + SRAM 宏 + MbistPipe + ClockGate
#   - L2TlbMissQueue 的队列存储 ram_40x47（注：xs 核内部自带队列，仅 u_g 侧需要 Queue40）
#   - LLPTW 的结构 arbiter RRArbiterInit / Arbiter2_LLPTW_Anon（xs_LLPTW_core 内部例化）
# ---------------------------------------------------------------------------
PTWCACHE_SRAM = \
    $(GOLDEN_RTL)/SplittedSRAM.sv $(GOLDEN_RTL)/SplittedSRAM_1.sv \
    $(GOLDEN_RTL)/SRAMTemplate_122.sv $(GOLDEN_RTL)/SRAMTemplate_126.sv \
    $(GOLDEN_RTL)/MbistPipePtwL1.sv $(GOLDEN_RTL)/MbistPipePtwL0.sv \
    $(GOLDEN_RTL)/ClockGate.sv \
    $(GOLDEN_RTL)/sram_array_1p8x200m100s1h0l1b_ptw_l1.sv \
    $(GOLDEN_RTL)/sram_array_1p32x228m114s1h0l1b_ptw_l0.sv \
    $(GOLDEN_RTL)/array_10.sv $(GOLDEN_RTL)/array_10_ext.v \
    $(GOLDEN_RTL)/array_11.sv $(GOLDEN_RTL)/array_11_ext.v

LLPTW_STRUCT = \
    $(GOLDEN_RTL)/RRArbiterInit.sv \
    $(GOLDEN_RTL)/Arbiter2_LLPTW_Anon.sv

SHARED_LEAVES = $(PTWCACHE_SRAM) $(LLPTW_STRUCT)

# ---------------------------------------------------------------------------
# golden 簇互联 body 结构件（MMU_it 与 u_g 共用）：Arbiter* / DelayN*
# ---------------------------------------------------------------------------
BODY_GLUE = \
    $(GOLDEN_RTL)/DelayN_221.sv $(GOLDEN_RTL)/DelayN_222.sv $(GOLDEN_RTL)/DelayN_13.sv \
    $(GOLDEN_RTL)/Arbiter1_L2TLBImp_Anon.sv \
    $(GOLDEN_RTL)/Arbiter2_PtwReq.sv \
    $(GOLDEN_RTL)/Arbiter5_L2TlbWithHptwIdBundle.sv \
    $(GOLDEN_RTL)/Arbiter2_L2TLBImp_Anon.sv \
    $(GOLDEN_RTL)/Arbiter2_L2TLBImp_Anon_1.sv \
    $(GOLDEN_RTL)/Arbiter2_L2TlbWithHptwIdBundle.sv \
    $(GOLDEN_RTL)/Arbiter3_L2TLBImp_Anon.sv \
    $(GOLDEN_RTL)/Arbiter3_L2TlbMemReqBundle.sv

# ---------------------------------------------------------------------------
# u_g 顶层独有：golden L2TLB 顶层 + 7 个 golden 算法叶子 + Queue40/ram（missQueue 存储）
# ---------------------------------------------------------------------------
GOLD_TOP = \
    $(GOLDEN_RTL)/L2TLB.sv \
    $(GOLDEN_RTL)/PMP.sv \
    $(GOLDEN_RTL)/PMPChecker.sv \
    $(GOLDEN_RTL)/L2TlbMissQueue.sv \
    $(GOLDEN_RTL)/PtwCache.sv \
    $(GOLDEN_RTL)/PTW.sv \
    $(GOLDEN_RTL)/HPTW.sv \
    $(GOLDEN_RTL)/LLPTW.sv \
    $(GOLDEN_RTL)/L2TlbPrefetch.sv \
    $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv \
    $(GOLDEN_RTL)/ram_40x47.sv

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = $(XS_PKGS) $(XS_CORES) $(XS_ADAPTERS) $(IT_ASSEMBLY)

GOLDEN_SRCS = $(GOLD_TOP) $(BODY_GLUE) $(SHARED_LEAVES)

TB_SRCS = tb.sv

# IT 不做 FM（FM 是 per-module 等价证明的事）；此处置空。
FM_VARIANTS =

include ../../../scripts/ut_common.mk

# +incdir：xs 核含 svh 片段（ptwcache_*.svh 等）在 rtl/memblock 下
VCS += +incdir+$(RTL_DIR)/memblock
# golden 子模块含 `ifndef SYNTHESIS 随机初值/运行时断言；关掉以免随机激励误触 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
# +vcs+initreg+0（runtime）：无 reset 寄存器清 0，保证两侧从同一确定态出发。
SIM_ARGS += +vcs+initreg+0
