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

# ---------------------------------------------------------------------------
# FM_MERGE_DUP = false —— ★加强，不是放宽★（第 3 轮 FM，接 docs/fm_predictions/PtwCache.md）
#
# 第 2 轮（agent/ptwcache2，2026-09-21，merge_duplicated_registers 用 FM 默认 true）实测：
#   · "Merging duplicated registers" 阶段自己就在 ref/impl 之间交替跑了 7 轮
#     （fm.log 985-989 行，r:/WORK/PtwCache 与 i:/WORK/PtwCache/u_core 各 3-4 次）；
#   · 之后 match 阶段不收敛：142,173 / 156,400 (84%) @2654 s → 142,969 / 156,400 @4493 s，
#     31 分钟只多匹配 796 点、还在减速，被集成者按 PID 停掉，五条 P 判据一条都没结论。
# 处置与先例同形（MulUnit / RenameBuffer / ArrayMulDataModule / EnqEntry_14 / Rob）：
#   关掉合并 = 不黑盒、不跳点、不加白名单、不约束 ref，只是要求 FM 逐个而不是合并后比，
#   比较点只增不减。fm_eq.tcl 的经验注记（codex 0168）明说"match 长时间不收敛"正是
#   可以 target-scoped 试这一项的症状。
# 两处核对（fm_eq.tcl 记着一次事故：Makefile 声明 false 而 tcl 硬编码 true）：
#   (1) 本文件这一行；(2) scripts/ut_common.mk fm-% 把 FM_MERGE_DUP 原样传进环境，
#       scripts/fm_eq.tcl 从 env(FM_MERGE_DUP) 真实绑定 verification_merge_duplicated_registers
#       （非法值 exit 3，不静默回落）。跑完还要在 sidecar/native_facts.json 的 appvar
#       读回里看到 false，且 fm.log 里不再出现 "Merging duplicated registers" 状态行。
# 副作用（有利）：fm_passing_model 的等式只在 merge_dup=false 下成立，本轮能给点预测；
#   但模型对本目标仍有已知缺口（SRAM 叶子 array_1x_ext.v 被它当黑盒），见登记文件。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# ★双例化 UT 不许用 +vcs+initreg+random★（L2TLB lane 实测，已进方法学）：
# random 给两个实例**各摇各的**初值，而 PtwCache 有 2749 个不复位寄存器，
# 两侧初态不同 -> 比出来的差异跟重写无关。+0 与 +1 都是常量档，两侧必然同初态、
# 又互不相同，是双例化 UT 能用的两档。
# ★编译期只能给 +vcs+initreg+random，档位在运行期选★
# （VCS W-2024.09 直接报 Error-[OBSL_OPT_E]：编译期的 +vcs+initreg+0 是废弃选项。
#  这里的 random 只是"打开 initreg 这套机制"，实际初值由运行期的 +vcs+initreg+N 定。）
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

# 第二档：make run-initreg1 SEED=<n>
.PHONY: run-initreg1
run-initreg1:
	$(MAKE) run SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+1" SEED=$(SEED)

# ---------------------------------------------------------------------------
# FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true —— ★加强证明，不是 waiver★（第 4 轮）
# 两处须同时生效：这里一半，另一半是 verif/fm_target_config/PtwCache.tcl 的 fm_target_vmucp_allow
#（fail-closed：没有那一行开这一项直接 FM_MODE_ERROR）。
# ★顺序：先配对，再加强★。第 3 轮（evidence/6a102f7a5101/PtwCache/）strict 跑成
#   native SUCCEEDED / passing 143717 / failing 0 / unverified 0 / unmatched 比较点 0(0)，
#   卡点 = unread：matched_nc 20 对 + unmatched unread ref 60 / impl 61。
# 处置三步，全是加强：
#   (1) RTL 消掉 impl 独有的 1 个死位 sp_hitdata_ck[prefetch]（golden 只有 spPre 一份），61 -> 60；
#   (2) fm_pins.tcl 把 60 对同义死位钉成双射（五族，fail-closed，见该文件头）；
#   (3) 本项让 FM 真去比 20+60=80 个 matched unread 点。
# ★验收判据（不达标就不算过，"passing 不增即空转"）★：
#   passing 143717 -> 143797（正好 +80）、failing 仍 0、unread 归 0、unmatched 六项全零。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
