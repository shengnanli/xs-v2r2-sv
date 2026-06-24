MODULE = Exec_IT

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
UT_DIR     = ../../ut

# ===========================================================================
# IT(集成级)后端 Exec 簇：golden ExeUnit(u_g) vs 全重写 ExeUnit_it(u_i)
#
#   选取变体：ExeUnit（整数执行单元容器 = Alu + Mul + Bku），因为这 3 个 FU 算法叶子
#   全部已重写，是「执行单元容器 → FU」重写链路最全、无非重写算法 FU 的变体。
#
#   ExeUnit_it：顶层端口 = golden ExeUnit（逐字相同）。module ExeUnit→ExeUnit_it，
#               内部 xs_ExeUnit_core_it（module xs_ExeUnit_core→_it，
#               include exeunit_connect_it.svh：把 3 个 FU 例化的模块名换成 _xs 适配器）。
#   Alu_xs / Bku_xs / MulUnit_xs：各模块 UT 现成的 _xs 适配器（端口逐字 = golden FU 在
#               ExeUnit 内的实例端口，drop-in），分别例化 xs_Alu_core / xs_Bku_core /
#               xs_MulUnit_core。
#
#   ⇒ 重写链路：xs_ExeUnit_core_it（分发/inPipe 打拍/时钟门控使能/§3 one-hot 仲裁 glue）
#               → xs_Alu_core / xs_MulUnit_core / xs_Bku_core 全程直连，
#               首次跑「执行单元容器 → FU」重写边界（per-module UT 里 FU 全是 golden 黑盒，
#               这条边界从未被两侧重写件一起跑过）。
#
#   共享 golden 结构/存储原语（两侧共用，非算法，不重命名）：
#     · Dispatcher (in1ToN)  —— 按 fuType 路由分发实体（纯结构）
#     · ClockGate            —— 时钟门控锁存器（结构原语）
#     · ArrayMulDataModule + C22/C32/C53/CSA3_2 —— MulUnit 乘法阵列（xs_MulUnit_core
#                               仍例化它，两侧共用同一份运算阵列原语）
#
#   【golden Alu 取真 golden】注意：本仓 golden/chisel-rtl/Alu.sv 当前是「打包」版本
#   （内含 alu_pkg + xs_Alu_core + module Alu(→ 包 xs 核)），并非纯 golden，且与重写侧
#   alu_pkg/xs_Alu_core 同名冲突。本 IT 的 u_g 改用项目内保留的真 golden 备份
#   golden/chisel-rtl/Alu.sv.golden（module Alu → 例化 golden AluDataModule 算法叶子，
#   无 xs 核/无 pkg），并补 AluDataModule 全量叶子，保证 u_g 是真 golden 参考、
#   且与重写侧无命名冲突。Bku.sv / MulUnit.sv 经核对为纯 golden（例化 golden 算法叶子），
#   照常用之。
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧(u_i 链路)：FU pkg + ExeUnit pkg + FU 核 + ExeUnit 装配 + _xs 适配器
# ---------------------------------------------------------------------------
XS_PKGS = \
    $(RTL_DIR)/backend/exeunit_pkg.sv \
    $(RTL_DIR)/backend/alu_pkg.sv \
    $(RTL_DIR)/backend/bku_pkg.sv \
    $(RTL_DIR)/backend/mulunit_pkg.sv

# 重写 FU 算法核（名字 xs_*_core 唯一，不撞 golden）
XS_CORES = \
    $(RTL_DIR)/backend/Alu.sv \
    $(RTL_DIR)/backend/Bku.sv \
    $(RTL_DIR)/backend/MulUnit.sv

# 重写 FU 叶子适配器（golden FU 在 ExeUnit 内实例端口的 drop-in → xs 核）
XS_ADAPTERS = \
    $(UT_DIR)/Alu/variants_xs.sv \
    $(UT_DIR)/Bku/variants_xs.sv \
    $(UT_DIR)/MulUnit/variants_xs.sv

# IT 装配（本目录；含 xs_ExeUnit_core_it + ExeUnit_it wrapper）+ 真 golden Alu 本地副本
IT_ASSEMBLY = \
    ExeUnit_it.sv \
    golden_alu.sv

# ---------------------------------------------------------------------------
# 共享 golden 结构/存储原语（u_i 重写链也例化这些 golden 叶子）
#   + 真 golden Alu 的算法叶子树（AluDataModule + 11 个运算叶子；golden_alu.sv 的
#     module Alu 例化它们，仅 u_g 经此叶子树跑 ALU，与重写侧 xs_Alu_core 无冲突）。
# ---------------------------------------------------------------------------
SHARED_STRUCT = \
    $(GOLDEN_RTL)/Dispatcher.sv \
    $(GOLDEN_RTL)/ClockGate.sv \
    $(GOLDEN_RTL)/ArrayMulDataModule.sv \
    $(GOLDEN_RTL)/C22.sv $(GOLDEN_RTL)/C32.sv $(GOLDEN_RTL)/C53.sv \
    $(GOLDEN_RTL)/CSA3_2.sv

# 真 golden Alu 的算法叶子树（AluDataModule + 运算叶子，仅 u_g 用）
GOLD_ALU_LEAVES = \
    $(GOLDEN_RTL)/AluDataModule.sv \
    $(GOLDEN_RTL)/AddModule.sv $(GOLDEN_RTL)/SubModule.sv \
    $(GOLDEN_RTL)/LeftShiftModule.sv $(GOLDEN_RTL)/RightShiftModule.sv \
    $(GOLDEN_RTL)/LeftShiftWordModule.sv $(GOLDEN_RTL)/RightShiftWordModule.sv \
    $(GOLDEN_RTL)/ShiftResultSelect.sv $(GOLDEN_RTL)/MiscResultSelect.sv \
    $(GOLDEN_RTL)/ConditionalZeroModule.sv $(GOLDEN_RTL)/WordResultSelect.sv \
    $(GOLDEN_RTL)/AluResSel.sv

# ---------------------------------------------------------------------------
# golden 顶层 + golden 链独有(只给 u_g)
#   Alu 用本地 golden_alu.sv（真 golden module Alu，见 IT_ASSEMBLY）；
#   Bku/MulUnit 为纯 golden（例化 golden 算法叶子），照常用 golden/chisel-rtl。
# ---------------------------------------------------------------------------
GOLD_TOP = \
    $(GOLDEN_RTL)/ExeUnit.sv \
    $(GOLDEN_RTL)/Bku.sv \
    $(GOLDEN_RTL)/MulUnit.sv

# golden Bku 算法叶子树（仅 u_g 用；重写侧 xs_Bku_core 无子叶，不需要）
GOLD_BKU_LEAVES = \
    $(GOLDEN_RTL)/CountModule.sv $(GOLDEN_RTL)/ClmulModule.sv \
    $(GOLDEN_RTL)/MiscModule.sv $(GOLDEN_RTL)/CryptoModule.sv \
    $(GOLDEN_RTL)/BlockCipherModule.sv $(GOLDEN_RTL)/HashModule.sv

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = $(XS_PKGS) $(XS_CORES) $(XS_ADAPTERS) $(IT_ASSEMBLY)

GOLDEN_SRCS = $(GOLD_TOP) $(SHARED_STRUCT) $(GOLD_ALU_LEAVES) $(GOLD_BKU_LEAVES)

TB_SRCS = tb.sv

# IT 不做 FM(等价证明是 per-module 的事)；此处置空。
FM_VARIANTS =

include ../../../scripts/ut_common.mk

# +incdir：xs_ExeUnit_core_it include rtl/backend 下的 exeunit_{ports,decls,logic}.svh，
#          以及本目录的 exeunit_connect_it.svh。
VCS += +incdir+$(RTL_DIR)/backend +incdir+.
# golden 子模块含 ifndef SYNTHESIS 随机初值/运行时断言；关掉以免随机激励误触 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
# +vcs+initreg+0(runtime)：无 reset 寄存器清 0，保证两侧从同一确定态出发。
SIM_ARGS += +vcs+initreg+0
