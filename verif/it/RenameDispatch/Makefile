MODULE = RenameDispatch_IT

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
UT_DIR     = ../../ut

# ===========================================================================
# IT(集成级)Rename-Dispatch 簇:golden Rename(u_g) vs 全重写 Rename_it(u_i)
#
#   选层: golden 顶层 Rename —— 它直接例化 CompressUnit + MEFreeList(intFreeList)
#         + StdFreeList{,_1,_2,_3}(fp/vec/v0/vl)。边界清晰且把多个重写叶子连起来跑。
#
#   Rename_it          : golden 同名扁平端口 → 例化重写算法核 xs_Rename_core_it。
#   xs_Rename_core_it  : 复制 rtl/backend Rename.sv 的 xs_Rename_core,把 3 个可重写
#                        叶子实例的模块名重定向到 UT 的 _xs 适配器:
#                          CompressUnit → CompressUnit_xs (→ xs_CompressUnit_core)
#                          MEFreeList   → MEFreeList_xs   (→ xs_MEFreeList_core)
#                          StdFreeList  → StdFreeList_xs  (→ xs_StdFreeList_core) [base/fp]
#   ⇒ 重写链路: xs_Rename_core_it → {CompressUnit_xs, MEFreeList_xs, StdFreeList_xs}
#               全程直连,首次跑"重命名 glue 核 ↔ freelist/压缩叶子核"集成边界。
#
#   诚实保留 golden 的叶子(非重写 / 共享存储原语,两侧共用):
#     - StdFreeList_1/_2/_3 (vec/v0/vl,空闲池 81/21/31):xs_StdFreeList_core 的 SIZE
#       是 pkg localparam(158=fp)无参数化,无法覆盖这 3 个尺寸 → 没有可用重写核,留 golden。
#     - SnapshotGenerator{,_11,_12}: 快照存储原语(memory model),两侧共享 golden。
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧(u_i 链路):类型包 + 重写核 + _xs 叶子适配器 + IT 装配
# ---------------------------------------------------------------------------
XS_PKGS = \
    $(RTL_DIR)/backend/rename_pkg.sv \
    $(RTL_DIR)/backend/compressunit_pkg.sv \
    $(RTL_DIR)/backend/mefreelist_pkg.sv \
    $(RTL_DIR)/backend/stdfreelist_pkg.sv

# 重写叶子核(rtl 原文件,名字 xs_*_core 唯一,不撞 golden)
XS_CORES = \
    $(RTL_DIR)/backend/CompressUnit.sv \
    $(RTL_DIR)/backend/MEFreeList.sv \
    $(RTL_DIR)/backend/StdFreeList.sv

# 叶子 _xs 适配器(UT 现成,纯端口搬运 → xs_*_core,无 golden 算法)
XS_ADAPTERS = \
    $(UT_DIR)/CompressUnit/variants_xs.sv \
    $(UT_DIR)/MEFreeList/variants_xs.sv \
    $(UT_DIR)/StdFreeList/variants_xs.sv

# IT 装配(本目录;gen_it.py 生成)
IT_ASSEMBLY = \
    xs_Rename_core_it.sv \
    Rename_it.sv

# ---------------------------------------------------------------------------
# golden 顶层 + golden 全链(u_g 用)+ 共享存储原语(两侧共用)
# ---------------------------------------------------------------------------
# 共享存储原语(u_i 重写链也例化这些 golden 叶子)
SHARED_STRUCT = \
    $(GOLDEN_RTL)/SnapshotGenerator.sv \
    $(GOLDEN_RTL)/SnapshotGenerator_11.sv \
    $(GOLDEN_RTL)/SnapshotGenerator_12.sv

# golden 顶层 Rename + 其全部 golden 子叶子(只给 u_g);
# StdFreeList_1/_2/_3 同时也被 u_i 链复用(非重写,留 golden)。
GOLD_TOP = \
    $(GOLDEN_RTL)/Rename.sv \
    $(GOLDEN_RTL)/CompressUnit.sv \
    $(GOLDEN_RTL)/MEFreeList.sv \
    $(GOLDEN_RTL)/StdFreeList.sv \
    $(GOLDEN_RTL)/StdFreeList_1.sv \
    $(GOLDEN_RTL)/StdFreeList_2.sv \
    $(GOLDEN_RTL)/StdFreeList_3.sv

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = $(XS_PKGS) $(XS_CORES) $(XS_ADAPTERS) $(IT_ASSEMBLY)

GOLDEN_SRCS = $(GOLD_TOP) $(SHARED_STRUCT)

TB_SRCS = tb.sv

# IT 不做 FM(等价证明是 per-module 的事);此处置空。
FM_VARIANTS =

include ../../../scripts/ut_common.mk

# +incdir:本目录的 _it 文件 / 重写核内的相对 include(若有)。
VCS += +incdir+$(RTL_DIR)/backend +incdir+.
# golden 子模块含 ifndef SYNTHESIS 随机初值 / 运行时断言;关掉以免随机激励误触 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
# +vcs+initreg+0(runtime):无 reset 寄存器清 0,保证两侧从同一确定态出发。
SIM_ARGS += +vcs+initreg+0
