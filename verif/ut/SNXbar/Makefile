# 自动生成：scripts/gen_zj_ut.py 的配套 Makefile（零判断批 G0->G1 迁移）
MODULE = SNXbar

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/SNXbar.sv
TB_SRCS = tb.sv

# ---------------------------------------------------------------------------
# 结构性修复（agent/diag-structural，2026-09-13）
#
# 症状：native FM FAILED，passing=1322 / failing=20(报告上限) / unmatched=1994。
# 根因：impl 侧只给了 rtl/uncore/SNXbar.sv，wrapper 例化的 FastArbiter_45 /
#       FastArbiter_46 在 impl 侧无定义 → 被 hdlin_unresolved_modules=black_box
#       当黑盒；ref 侧却拿到完整 golden 定义并 elaborate。**两侧建模不对称**。
#       逐位对账：unmatched_impl 1994 = FastArbiter_45 输入 1567 位
#                                     + FastArbiter_46 输入 427 位（BBPin 比对点）；
#                 blackbox_out 501    = 45 的 393 输出位 + 46 的 108 输出位，
#       这 501 位让 SNXbar 的下游输出全部变成 failing（报告只打前 20 个）。
#       不是 RTL 逻辑错。
# 修法：两侧同源 elaborate —— 把子模块 golden 定义放进 RTL_GOLDEN_DEPS，
#       ut_common.mk 会把它同时并入 UT 编译与 FM 的 impl 侧。这是**去黑盒**
#       （比对点变多、证明变强），不是新增黑盒/放宽。机制与 FTBBank、IMSIC
#       等既有目标一致；子模块自身由 FastArbiter_45/_46 各自的目标去证。
# 注：原 GOLDEN_SRCS 里的这两个文件必须挪走，否则 VCS 命令行会出现同一模块的
#     重复定义（RTL_GOLDEN_DEPS 与 GOLDEN_SRCS 都进编译行）。
# ---------------------------------------------------------------------------
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/FastArbiter_45.sv \
                  $(GOLDEN_RTL)/FastArbiter_46.sv

# golden 双例化：golden 顶（子模块闭包见 RTL_GOLDEN_DEPS，两侧共用同一份定义）。
GOLDEN_SRCS = $(GOLDEN_RTL)/SNXbar.sv

# ---------------------------------------------------------------------------
# matched-unread 加强（vmucp，2026-09-14，agent/arb）
#
# strict 首跑：native SUCCEEDED / passing 1839 / failing 0 / unmatched 0，只剩 2 个
# unread 点卡成 PARTIAL。2 点**全部** matched_nc，严格 1:1：
#     r:/WORK/SNXbar/txreqArb/pendingMask_reg[0] ↔ i:/WORK/SNXbar/u_core/txreqArb/...
#     r:/WORK/SNXbar/txdatArb/pendingMask_reg[0] ↔ i:/WORK/SNXbar/u_core/txdatArb/...
# 两点都在 **golden 自己的** FastArbiter_46/_45 内部；这两个模块经 RTL_GOLDEN_DEPS
# 两侧同源 elaborate（同一份 golden 文件、同一实例名），双射是结构性的。
# 死位成因同 RNXbar：轮转仲裁的 rrGrantMask bit0 恒 0（写入值末位是字面量 1'h0），
# 而 pendingMask[0] 的唯一读出点是 rrGrantMask[0] & pendingMask[0] → 无可观测路径。
# 加强（true = 要 FM 多证一些，不是 waiver）：让 FM 实际比较这 2 个 matched-unread 点。
# ---------------------------------------------------------------------------
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = SNXbar
FM_REF_DEPS_SNXbar = FastArbiter_45.sv FastArbiter_46.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
