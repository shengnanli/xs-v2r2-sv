MODULE = Decode_IT

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
UT_DIR     = ../../ut

# ===========================================================================
# IT(集成级)Decode 簇:golden DecodeStage(u_g) vs 全重写 DecodeStage_it(u_i)
#
#   Decode 簇装配树(golden 顶层 DecodeStage 的子模块):
#     DecodeStage
#      ├─ DecodeUnit ×6   →(重写) → FPDecoder + UopInfoGen  ←(均重写)
#      ├─ DecodeUnitComp  →(未重写, golden) → VecExceptionGen + indexedLSUopTable_*
#      └─ VTypeGen        →(未重写, golden) → VsetModule
#
#   重写链路(u_i, 全部直连重写核, 无 golden 算法叶子):
#     DecodeStage_it           (= xs_DecodeStage_core 改名; glue: 路由/握手/fusion 输出
#                               修正/RAT/trapInstInfo/vtype/perf)
#       └─ DecodeUnit_it ×6    (= golden 同名 wrapper 改名; 扁平端口=golden DecodeUnit)
#            └─ xs_DecodeUnit_core_it  (= xs_DecodeUnit_core 改名; 单条指令译码核)
#                 ├─ FPDecoder_it      (= UT variants_xs 适配器改名 → xs_FPDecoder_core)
#                 └─ UopInfoGen_it     (= UT variants_xs 适配器改名 → xs_UopInfoGen_core)
#     ⇒ 首次把「DecodeStage glue → DecodeUnit → {FPDecoder, UopInfoGen}」这条重写
#       边界全程直连跑。
#
#   共享 golden 叶子(非 Decode glue 算法, 工程未单独重写; README §4 允许; 两侧共用,
#   只编一份):
#     DecodeUnitComp / VTypeGen / VecExceptionGen / VsetModule /
#     indexedLSUopTable_1..7 / indexedLSNumOfUopTable / strdiedLSNumOfUopTable
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧(u_i 链路):类型包 + IT 装配(*_it) + 重写核
# ---------------------------------------------------------------------------
# 类型包(重写核 import)
XS_PKGS = \
    $(RTL_DIR)/backend/decodestage_pkg.sv \
    $(RTL_DIR)/backend/decodeunit_pkg.sv \
    $(RTL_DIR)/backend/fpdecoder_pkg.sv \
    $(RTL_DIR)/backend/uopinfogen_pkg.sv

# IT 装配(本目录;gen_it.py 机械生成的 *_it 改名链)
IT_ASSEMBLY = \
    FPDecoder_it.sv \
    UopInfoGen_it.sv \
    DecodeUnit_core_it.sv \
    DecodeUnit_it.sv \
    DecodeStage_it.sv

# 重写叶子核(名字 xs_*_core 唯一, 不撞 golden; 由 *_it 适配器例化):
#   FPDecoder.sv → xs_FPDecoder_core, UopInfoGen.sv → xs_UopInfoGen_core
# (xs_DecodeUnit_core_it / DecodeStage_it 已含在 IT_ASSEMBLY 的改名副本里)
XS_CORES = \
    $(RTL_DIR)/backend/FPDecoder.sv \
    $(RTL_DIR)/backend/UopInfoGen.sv

# ---------------------------------------------------------------------------
# golden 顶层 + 共享 golden 叶子
# ---------------------------------------------------------------------------
# golden 顶层(只给 u_g)
GOLD_TOP = $(GOLDEN_RTL)/DecodeStage.sv

# 共享 golden 叶子(u_g 与 u_i 重写链都例化这些未重写子模块)
SHARED_GOLDEN = \
    $(GOLDEN_RTL)/DecodeUnitComp.sv \
    $(GOLDEN_RTL)/VTypeGen.sv \
    $(GOLDEN_RTL)/VecExceptionGen.sv \
    $(GOLDEN_RTL)/VsetModule.sv \
    $(GOLDEN_RTL)/strdiedLSNumOfUopTable.sv \
    $(GOLDEN_RTL)/indexedLSNumOfUopTable.sv \
    $(GOLDEN_RTL)/indexedLSUopTable_1.sv \
    $(GOLDEN_RTL)/indexedLSUopTable_2.sv \
    $(GOLDEN_RTL)/indexedLSUopTable_3.sv \
    $(GOLDEN_RTL)/indexedLSUopTable_4.sv \
    $(GOLDEN_RTL)/indexedLSUopTable_5.sv \
    $(GOLDEN_RTL)/indexedLSUopTable_6.sv \
    $(GOLDEN_RTL)/indexedLSUopTable_7.sv

# golden 侧 u_g 还需 golden DecodeUnit/FPDecoder/UopInfoGen(u_i 用重写 _it 链,不读这些)
GOLD_DU = \
    $(GOLDEN_RTL)/DecodeUnit.sv \
    $(GOLDEN_RTL)/FPDecoder.sv \
    $(GOLDEN_RTL)/UopInfoGen.sv

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = $(XS_PKGS) $(XS_CORES) $(IT_ASSEMBLY)

GOLDEN_SRCS = $(GOLD_TOP) $(GOLD_DU) $(SHARED_GOLDEN)

TB_SRCS = tb.sv

# IT 不做 FM(等价证明是 per-module 的事);此处置空。
FM_VARIANTS =

include ../../../scripts/ut_common.mk

# +incdir:DecodeStage_it / DecodeUnit_core_it 的 `include 来自本目录(*_it.svh)与
#         rtl/backend(端口表/拆装/派生 svh)。
VCS += +incdir+. +incdir+$(RTL_DIR)/backend
# golden 子模块含 XSError/XSPerf/assert(非综合);关随机化以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
# +vcs+initreg+0(runtime):无 reset 寄存器清 0,保证两侧从同一确定态出发。
SIM_ARGS += +vcs+initreg+0
