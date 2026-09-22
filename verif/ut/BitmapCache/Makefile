MODULE = BitmapCache

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/mmu/mmu_common_pkg.sv \
           $(RTL_DIR)/mmu/BitmapCache.sv
TB_SRCS = tb.sv

# ---------------------------------------------------------------------------
# 边界：SRAM 一路 + MBIST 分发级 + ClockGate **两侧同源用 golden**，不黑盒
# （与 verif/ut/PtwCache/Makefile 同一取法，理由同：两侧同源严格更强，黑盒边界为空，
#  proof_mode 可以是 signoff-strict 而不是 assembly）。
#   SplittedSRAM -> SRAMTemplate_124 x4 -> sram_array_1p32x90m45s1h0l1b_bitmap -> array_9 -> array_9_ext
#   array_9_ext：addr [4:0] / ram [31:0] -> 2^5 == 32，地址空间与深度精确相等，
#   FMR_ELAB-147 越界在结构上不可能（实测 grep，不是外推）。
#   MbistBitmapCache：utility.mbist.MbistPipeline 单态化的 MBIST 分发级，本仓 rtl/dft
#   尚无它的薄文件（gen_mbist_pipe_family.py 只把它列为 ADJACENT 邻居），故同源用 golden；
#   将来家族生成器把它收进来时，把 impl 侧换成 rtl/dft 版本即可（PtwCache 的 MbistPipePtwL0/L1 就是这么做的）。
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ClockGate.sv \
                  $(GOLDEN_RTL)/SplittedSRAM.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_124.sv \
                  $(GOLDEN_RTL)/sram_array_1p32x90m45s1h0l1b_bitmap.sv \
                  $(GOLDEN_RTL)/array_9.sv \
                  $(GOLDEN_RTL)/array_9_ext.v \
                  $(GOLDEN_RTL)/MbistBitmapCache.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/BitmapCache.sv $(RTL_GOLDEN_DEPS)

FM_VARIANTS = BitmapCache
FM_REF_DEPS_BitmapCache = ClockGate.sv SplittedSRAM.sv SRAMTemplate_124.sv \
                          sram_array_1p32x90m45s1h0l1b_bitmap.sv array_9.sv array_9_ext.v \
                          MbistBitmapCache.sv
# 关掉重复寄存器合并：让 passing 与 fm_predict.py 的模型可逐位对账。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# ★双例化 UT 的两档 initreg 是 +0 与 +1，不用 +random★（random 按实例各摇各的初值；
# 本模块两级流水载荷 / DataHoldBypass / ramDatas / hitVec 都不复位）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
