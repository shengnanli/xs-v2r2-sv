MODULE = DCache_IT

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
UT_DIR     = ../../ut

# ===========================================================================
# IT(集成级) DCache 簇: golden DCache (u_g) vs 全重写 DCache_it (u_i)
#
#   DCache_it : 顶层端口 = golden DCache; 集成 glue 用重写核 xs_DCache_core_it
#               (= xs_DCache_core 复刻, inst include 换成 dcache_inst_it.svh:
#                11 个算法叶子实例类型全部换成重写 _xs 适配器)。
#               非重写互联/监视/过滤叶子(CtrlUnit/BloomFilter/CounterFilter/
#               PrefetcherMonitor/FDPrefetcherMonitor/L1PrefetchSourceArray/
#               TreeArbiter/MissReadyGen/Arbiter1_*) 无独立重写核, 保留 golden。
#
#   叶子适配器(*_xs, 纯端口搬运 + 重写核 xs_*_core, 无 golden 算法叶子)直接复用
#   各模块 UT 的 verif/ut/<M>/variants_xs.sv:
#     MainPipe_xs MissQueue_xs WritebackQueue_xs ProbeQueue_xs
#     LoadPipe_xs StorePipe_xs BankedDataArray_xs DuplicatedTagArray_xs
#     L1CohMetaArray_xs L1FlagMetaArray_xs L1FlagMetaArray_1_xs
#
#   叶子边界 = SRAM 模板/宏 + MBIST pipe(存储/DFT 原语) + 各模块 UT 已界定的
#   golden 子-叶子(AMOALU/MissEntry/CMOUnit/WritebackEntry/ProbeEntry/...);
#   golden 与 rewrite 共用, 非本簇重写算法, 作为共享叶子保留 golden。
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧(u_i 链路): xs 核 pkg + 核 + 叶子适配器 + IT 装配
# ---------------------------------------------------------------------------
XS_PKGS = \
    $(RTL_DIR)/memblock/dcache_pkg.sv \
    $(RTL_DIR)/memblock/mainpipe_pkg.sv \
    $(RTL_DIR)/memblock/missqueue_pkg.sv \
    $(RTL_DIR)/memblock/writebackqueue_pkg.sv \
    $(RTL_DIR)/memblock/probequeue_pkg.sv \
    $(RTL_DIR)/memblock/loadpipe_pkg.sv \
    $(RTL_DIR)/memblock/storepipe_pkg.sv \
    $(RTL_DIR)/memblock/bankeddata_pkg.sv \
    $(RTL_DIR)/memblock/dtagarray_pkg.sv \
    $(RTL_DIR)/memblock/l1metaarray_pkg.sv

# -- 重写 xs 核(算法逻辑全部在这里) --
#    MissQueue/WritebackQueue/ProbeQueue 三个核在 rtl 里用**编译单元作用域** `import pkg::*;`
#    (module 之前), 三者各自的 pkg 都定义 IDX_BITS -> 单 $unit 多文件编译时 wildcard 撞名。
#    per-module UT 各自单独编译故不触发; IT 一起编译需消歧。本目录提供 *_it_core.sv:
#    **算法体逐字不变**, 仅把 unit-scope import 改为 module-header import (作用域收窄到本模块,
#    消除 $unit 撞名), 由 scripts 机械生成 (perl 移动 import 行)。
XS_CORES = \
    $(RTL_DIR)/memblock/MainPipe.sv \
    MissQueue_it_core.sv \
    WritebackQueue_it_core.sv \
    ProbeQueue_it_core.sv \
    $(RTL_DIR)/memblock/LoadPipe.sv \
    $(RTL_DIR)/memblock/StorePipe.sv \
    $(RTL_DIR)/memblock/BankedDataArray.sv \
    $(RTL_DIR)/memblock/DuplicatedTagArray.sv \
    $(RTL_DIR)/memblock/L1CohMetaArray.sv \
    $(RTL_DIR)/memblock/L1FlagMetaArray.sv

# -- 重写叶子适配器(golden 扁平端口 -> xs 核; 复用各模块 UT 的 variants_xs.sv) --
XS_ADAPTERS = \
    $(UT_DIR)/MainPipe/variants_xs.sv \
    $(UT_DIR)/MissQueue/variants_xs.sv \
    $(UT_DIR)/WritebackQueue/variants_xs.sv \
    $(UT_DIR)/ProbeQueue/variants_xs.sv \
    $(UT_DIR)/LoadPipe/variants_xs.sv \
    $(UT_DIR)/StorePipe/variants_xs.sv \
    $(UT_DIR)/BankedDataArray/variants_xs.sv \
    $(UT_DIR)/DuplicatedTagArray/variants_xs.sv \
    $(UT_DIR)/L1CohMetaArray/variants_xs.sv \
    $(UT_DIR)/L1FlagMetaArray/variants_xs.sv

# -- IT 装配(本目录: xs_DCache_core_it + 顶层 DCache_it; include dcache_inst_it.svh) --
IT_ASSEMBLY = DCache_it.sv

# ---------------------------------------------------------------------------
# 共享存储原语 / DFT pipe / golden 子-叶子(两侧共用, _xs 适配器内部也例化这些):
#   BankedDataArray_xs 内部 -> DataSRAMBank* / SRAMTemplate_8* / sram_array_*_dat / array_8 / Mbist
#   DuplicatedTagArray_xs 内部 -> TagArray / TagSRAMBank / SRAMTemplate_114 / sram_array_*_tag / array_9 / Mbist
#   MainPipe_xs -> AMOALU / Arbiter4_MainPipeReq
#   MissQueue_xs -> MissEntry / CMOUnit / FastArbiter
#   WritebackQueue_xs -> WritebackEntry / WritebackEntry_15
#   ProbeQueue_xs -> ProbeEntry / Arbiter8_MainPipeReq
# ---------------------------------------------------------------------------
BANKEDDATA_SRAM = \
    $(GOLDEN_RTL)/DataSRAMBank.sv $(GOLDEN_RTL)/DataSRAMBank_1.sv \
    $(GOLDEN_RTL)/DataSRAMBank_2.sv $(GOLDEN_RTL)/DataSRAMBank_4.sv \
    $(GOLDEN_RTL)/SRAMTemplate_82.sv $(GOLDEN_RTL)/SRAMTemplate_84.sv \
    $(GOLDEN_RTL)/SRAMTemplate_86.sv $(GOLDEN_RTL)/SRAMTemplate_90.sv \
    $(GOLDEN_RTL)/SRAMTemplate_98.sv \
    $(GOLDEN_RTL)/sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv \
    $(GOLDEN_RTL)/array_8.sv $(GOLDEN_RTL)/array_8_ext.v \
    $(GOLDEN_RTL)/MbistPipeDCacheData.sv

TAGARRAY_SRAM = \
    $(GOLDEN_RTL)/TagArray.sv $(GOLDEN_RTL)/TagSRAMBank.sv \
    $(GOLDEN_RTL)/SRAMTemplate_114.sv \
    $(GOLDEN_RTL)/sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv \
    $(GOLDEN_RTL)/array_9.sv $(GOLDEN_RTL)/array_9_ext.v \
    $(GOLDEN_RTL)/MbistPipeDcacheTag.sv

MBIST_CLK = \
    $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

GOLDEN_SUBLEAVES = \
    $(GOLDEN_RTL)/AMOALU.sv $(GOLDEN_RTL)/Arbiter4_MainPipeReq.sv \
    $(GOLDEN_RTL)/MissEntry.sv $(GOLDEN_RTL)/CMOUnit.sv $(GOLDEN_RTL)/FastArbiter.sv \
    $(GOLDEN_RTL)/WritebackEntry.sv $(GOLDEN_RTL)/WritebackEntry_15.sv \
    $(GOLDEN_RTL)/ProbeEntry.sv $(GOLDEN_RTL)/Arbiter8_MainPipeReq.sv

SHARED_LEAVES = $(BANKEDDATA_SRAM) $(TAGARRAY_SRAM) $(MBIST_CLK) $(GOLDEN_SUBLEAVES)

# ---------------------------------------------------------------------------
# DCache_it 与 u_g 共用的非重写互联/监视/过滤/仲裁叶子(无独立重写核):
# ---------------------------------------------------------------------------
BODY_LEAVES = \
    $(GOLDEN_RTL)/CtrlUnit.sv \
    $(GOLDEN_RTL)/Queue1_RegMapperInput_4.sv \
    $(GOLDEN_RTL)/BloomFilter.sv \
    $(GOLDEN_RTL)/CounterFilter.sv \
    $(GOLDEN_RTL)/PrefetcherMonitor.sv \
    $(GOLDEN_RTL)/FDPrefetcherMonitor.sv \
    $(GOLDEN_RTL)/L1PrefetchSourceArray.sv \
    $(GOLDEN_RTL)/TreeArbiter.sv \
    $(GOLDEN_RTL)/MissReadyGen.sv \
    $(GOLDEN_RTL)/Arbiter1_TagWriteReq.sv \
    $(GOLDEN_RTL)/Arbiter1_L1BankedDataWriteReq.sv \
    $(GOLDEN_RTL)/Arbiter1_L1BankedDataWriteReqCtrl.sv

# ---------------------------------------------------------------------------
# u_g 顶层独有: golden DCache 顶层 + 11 个 golden 算法叶子
#   (它们例化的子-叶子/SRAM 已在 SHARED_LEAVES 提供, 避免重复编译)
# ---------------------------------------------------------------------------
GOLD_TOP = \
    $(GOLDEN_RTL)/DCache.sv \
    $(GOLDEN_RTL)/MainPipe.sv \
    $(GOLDEN_RTL)/MissQueue.sv \
    $(GOLDEN_RTL)/WritebackQueue.sv \
    $(GOLDEN_RTL)/ProbeQueue.sv \
    $(GOLDEN_RTL)/LoadPipe.sv \
    $(GOLDEN_RTL)/StorePipe.sv \
    $(GOLDEN_RTL)/BankedDataArray.sv \
    $(GOLDEN_RTL)/DuplicatedTagArray.sv \
    $(GOLDEN_RTL)/L1CohMetaArray.sv \
    $(GOLDEN_RTL)/L1FlagMetaArray.sv \
    $(GOLDEN_RTL)/L1FlagMetaArray_1.sv

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = $(XS_PKGS) $(XS_CORES) $(XS_ADAPTERS) $(IT_ASSEMBLY)

GOLDEN_SRCS = $(GOLD_TOP) $(BODY_LEAVES) $(SHARED_LEAVES)

TB_SRCS = tb.sv

# IT 不做 FM(FM 是 per-module 等价证明的事); 此处置空。
FM_VARIANTS =

include ../../../scripts/ut_common.mk

# +incdir: xs 核含 svh 片段(dcache_*.svh / missqueue_*.svh 等)在 rtl/memblock 下;
#          dcache_inst_it.svh 在本目录(IT)。
VCS += +incdir+$(RTL_DIR)/memblock +incdir+.
# golden 子模块含 `ifndef SYNTHESIS 随机初值/运行时断言; 关掉以免随机激励误触 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
# +vcs+initreg+0(runtime): 无 reset 寄存器清 0, 保证两侧从同一确定态出发。
SIM_ARGS += +vcs+initreg+0
