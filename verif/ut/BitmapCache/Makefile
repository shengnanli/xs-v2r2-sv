MODULE = BitmapCache

RTL_DIR = ../../../rtl
# 子模块 SplittedSRAM（+4×SRAMTemplate_124）/ MbistBitmapCache 已独立签核（agent/fe-mem-misc），两侧白盒：
# ref 读 golden、impl 读重写件；再下一层厂商宏链与 ClockGate 两侧同读 golden。
RTL_SRCS = $(RTL_DIR)/mmu/mmu_common_pkg.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_124.sv \
           $(RTL_DIR)/mmu/SplittedSRAM.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/dft/MbistBitmapCache.sv \
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
                  $(GOLDEN_RTL)/sram_array_1p32x90m45s1h0l1b_bitmap.sv \
                  $(GOLDEN_RTL)/array_9.sv \
                  $(GOLDEN_RTL)/array_9_ext.v

GOLDEN_SRCS = $(GOLDEN_RTL)/BitmapCache.sv $(RTL_GOLDEN_DEPS) \
              $(GOLDEN_RTL)/SplittedSRAM.sv $(GOLDEN_RTL)/SRAMTemplate_124.sv $(GOLDEN_RTL)/MbistBitmapCache.sv

FM_VARIANTS = BitmapCache
FM_REF_DEPS_BitmapCache = ClockGate.sv SplittedSRAM.sv SRAMTemplate_124.sv \
                          sram_array_1p32x90m45s1h0l1b_bitmap.sv array_9.sv array_9_ext.v \
                          MbistBitmapCache.sv
# 关掉重复寄存器合并：让 passing 与 fm_predict.py 的模型可逐位对账。
# merge_dup 改用工具默认（true）：impl 改读重写的 SRAMTemplate_124 后，共享核 xs_SRAMTemplate_core 非 holdRead
# 分支的 rdata_last_REG（主线上与 respReg 同方程、靠 merge 合并；SRAMTemplate_124 / SplittedSRAM 单独签核同口径）
# 在 merge 关时成为 4 个 impl 独占 unread（lane 内诊断跑实测）。codex 0206 D1 另有 lane 从核里删它，合入后可回到 false。
# vmucp = true（2026-09-22 打开）：第一次跑（未开）留下 42 个 matched-unread 点，全部是
# golden 自身存了但本锥内无读者的位（data_1_tag 高低位 / data_tag[2:0] / mbist 地址高位 /
# SRAM 模型的 ren 寄存器），42<->42 按后缀逐字双射、无人工强配。打开 = 让 FM 把这 42 点
# 也证一遍（更严，不是放松）。逐条依据在 verif/fm_target_config/BitmapCache.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# ★双例化 UT 的两档 initreg 是 +0 与 +1，不用 +random★（random 按实例各摇各的初值；
# 本模块两级流水载荷 / DataHoldBypass / ramDatas / hitVec 都不复位）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
