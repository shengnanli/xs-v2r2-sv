MODULE = ICacheMetaArray

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/ICacheMetaArray.sv
TB_SRCS = tb.sv

# closure 对称 + 边界下推（2026-09-14，PARTIAL 收口簇）
# ------------------------------------------------------------------------
# 原状：FM_REF_DEPS 为空、无 RTL_GOLDEN_DEPS，于是 tagArrays_0 / tagArrays_1 /
# mbistPl 三个**设计级**黑盒两侧对称出现。它们是 SplittedSRAMTemplate /
# SplittedSRAMTemplate_1 / MbistPipeIcacheTag —— 既不是厂商硬宏（不在
# verif/vendor_boundary.tsv），也不是独立签核目标（verif/ut/ 下无同名 UT），
# 所以 declare_allow.py 拒绝给它们出声明，assembly 永远卡在 no_allow_decl。
# 处置（与 IMSICGateWay 把 AsyncResetSynchronizerShiftReg 白盒化同法）：
# 把这三棵子树的 golden 源**两侧同源 elaborate**（ref 走 FM_REF_DEPS_*，
# impl 走 RTL_GOLDEN_DEPS，读的是 G1-canonical 下同一份文件），边界因此从
# 「三个功能模块」下推到叶子 array_ext —— 后者是 SRAM 编译器行为模型，已在
# verif/vendor_boundary.tsv 逐条审定（128 深 / 2x37 slice mask / 单口 RW0）。
# ★这是加强证明不是放宽★：SRAM wrapper、MBIST 流水、地址/使能寄存全部进入比对，
# 只剩存储阵列本身作对称黑盒。array_ext.v 两侧都不读（regimeA）。
ICACHEMETA_LEAVES = SplittedSRAMTemplate.sv SplittedSRAMTemplate_1.sv \
                    SRAMTemplate.sv SRAMTemplate_2.sv \
                    sram_array_1p128x74m37s1h0l1b_icsh_tag.sv array.sv \
                    MbistClockGateCell.sv ClockGate.sv MbistPipeIcacheTag.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(ICACHEMETA_LEAVES))
FM_REF_DEPS_ICacheMetaArray = $(ICACHEMETA_LEAVES)
GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheMetaArray.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_1.sv \
              $(GOLDEN_RTL)/SRAMTemplate.sv \
              $(GOLDEN_RTL)/SRAMTemplate_2.sv \
              $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
              $(GOLDEN_RTL)/array.sv \
              $(GOLDEN_RTL)/array_ext.v \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/MbistPipeIcacheTag.sv
# assembly：对称黑盒边界 = array_ext × 4/侧（两 bank × 每 bank 两块 SRAM），
# 逐对象声明见 verif/allow/ICacheMetaArray.json。
# FM_ALLOWLIST 是 **unmatched compare points** 的数字粗筛，与黑盒条数无关；
# 本目标 unmatched 实测为 0，故收紧到 0（原值 3 是老战役继承的松口径）。
FM_MODE = assembly
FM_ALLOWLIST ?= 0
FM_VARIANTS = ICacheMetaArray

include ../../../scripts/ut_common.mk

# golden 含 ifndef SYNTHESIS 的随机初始化/断言；UT 与 FM 均定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS
