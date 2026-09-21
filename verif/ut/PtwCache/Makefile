MODULE = PtwCache

RTL_DIR = ../../../rtl
# 重写侧：PtwCache 本体 + 它例化的两个 MBIST 分发级（也是本仓重写件）。
RTL_SRCS = $(RTL_DIR)/mmu/PtwCache.sv \
           $(RTL_DIR)/dft/MbistPipePtwL0.sv \
           $(RTL_DIR)/dft/MbistPipePtwL1.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv
TB_SRCS = tb.sv

# ---------------------------------------------------------------------------
# 边界：SRAM 一路**两侧同源用 golden**，不黑盒
#
# PtwCache 底下挂着 l1/l0 两组 SRAM（SplittedSRAM_1/2 -> SRAMTemplate_* ->
# sram_array_*_ptw_* -> array_10/11 -> array_1x_ext）。本仓没有这一族的重写件。
# 两条路可选：(A) 两侧对称黑盒；(B) 两侧同源读同一份 golden。
# ★这里选 (B)★，理由是 (B) 严格更强、且这一族没有选 (A) 的被迫理由：
#   · L2TlbMissQueue 的 ram_40x47 被迫选 (A) 是因为它 addr 6 位而深度 40，
#     2^6=64 > 40，FM elaborate 直接报 FMR_ELAB-147 越界、link 不起来。
#   · 本族两个存储模型都**地址空间与深度精确相等**（实测，不是外推）：
#       array_10_ext  addr [1:0] / ram [3:0]   -> 2^2 == 4
#       array_11_ext  addr [5:0] / ram [63:0]  -> 2^6 == 64
#     越界在结构上不可能，那条拦路石不存在。
#   · 选 (B) 之后 SRAM 内部也进证明范围，黑盒边界为空，proof_mode 可以是
#     signoff-strict 而不是 assembly。
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ClockGate.sv \
                  $(GOLDEN_RTL)/SplittedSRAM_1.sv \
                  $(GOLDEN_RTL)/SplittedSRAM_2.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_128.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_129.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_143.sv \
                  $(GOLDEN_RTL)/sram_array_1p4x786m131s1h0l1b_ptw_l1.sv \
                  $(GOLDEN_RTL)/sram_array_1p64x114m57s1h0l1b_ptw_l0.sv \
                  $(GOLDEN_RTL)/array_10.sv \
                  $(GOLDEN_RTL)/array_11.sv \
                  $(GOLDEN_RTL)/array_10_ext.v \
                  $(GOLDEN_RTL)/array_11_ext.v

GOLDEN_SRCS = $(GOLDEN_RTL)/PtwCache.sv \
              $(GOLDEN_RTL)/MbistPipePtwL0.sv \
              $(GOLDEN_RTL)/MbistPipePtwL1.sv \
              $(RTL_GOLDEN_DEPS)

FM_VARIANTS = PtwCache
# ref 侧的依赖闭包 = 上面那张同源表 + 两个 MBIST 分发级的 golden 版本
# （impl 侧用 rtl/dft/ 下的重写版，两侧都白盒展开，对称）。
FM_REF_DEPS_PtwCache = ClockGate.sv SplittedSRAM_1.sv SplittedSRAM_2.sv \
                       SRAMTemplate_128.sv SRAMTemplate_129.sv SRAMTemplate_143.sv \
                       sram_array_1p4x786m131s1h0l1b_ptw_l1.sv \
                       sram_array_1p64x114m57s1h0l1b_ptw_l0.sv \
                       array_10.sv array_11.sv array_10_ext.v array_11_ext.v \
                       MbistPipePtwL0.sv MbistPipePtwL1.sv

include ../../../scripts/ut_common.mk

# ★双例化 UT 不许用 +vcs+initreg+random★（L2TLB lane 实测，已进方法学）：
# random 给两个实例**各摇各的**初值，而 PtwCache 有 2749 个不复位寄存器，
# 两侧初态不同 -> 比出来的差异跟重写无关。+0 与 +1 都是常量档，两侧必然同初态、
# 又互不相同，是双例化 UT 能用的两档。
VCS      += +define+SYNTHESIS +vcs+initreg+0
SIM_ARGS += +vcs+initreg+0

# 第二档：make run-initreg1 SEED=<n>
.PHONY: run-initreg1
run-initreg1:
	$(MAKE) run SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+1" SEED=$(SEED)
