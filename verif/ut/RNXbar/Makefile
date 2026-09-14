# 自动生成：scripts/gen_zj_ut.py 的配套 Makefile（零判断批 G0->G1 迁移）
MODULE = RNXbar

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/RNXbar.sv
TB_SRCS = tb.sv

# ---------------------------------------------------------------------------
# 结构性修复（agent/diag-structural，2026-09-13）
#
# 症状：native FM FAILED，passing=0 / failing=20(报告上限) / unmatched=4685。
# 根因（与 SNXbar 同源）：impl 侧只给了 rtl/uncore/RNXbar.sv，wrapper 例化的 6 个
#       FastArbiter 在 impl 侧无定义 → 被 hdlin_unresolved_modules=black_box 当黑盒；
#       ref 侧却完整 elaborate。**两侧建模不对称**，不是 set_top 失败、也不是逻辑错。
#       逐位对账 unmatched_impl 4685 = 各黑盒输入位之和：
#         FastArbiter_29 ×4 (163 位)  = 652
#         FastArbiter_35 ×4 ( 41 位)  = 164
#         FastArbiter_30 ×4 (423 位)  = 1692
#         FastArbiter_43 ×1 (355 位)  = 355
#         FastArbiter_26 ×1 (255 位)  = 255
#         FastArbiter_45 ×1 (1567 位) = 1567
#         合计 4685 —— 与实测完全相等。
#       passing=0 是因为 RNXbar 是纯交叉开关：**每一个**输出都经过某个被黑盒的
#       仲裁器，黑盒输出恒为未知 → 全部比对点 failing，没有一个能 passing。
# 修法：两侧同源 elaborate（RTL_GOLDEN_DEPS），去黑盒＝加强，非放宽。
#       6 个 FastArbiter 各有自己的目标去证（rtl/uncore 已有 _30/_35 的重写）。
# ---------------------------------------------------------------------------
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/FastArbiter_26.sv \
                  $(GOLDEN_RTL)/FastArbiter_29.sv \
                  $(GOLDEN_RTL)/FastArbiter_30.sv \
                  $(GOLDEN_RTL)/FastArbiter_35.sv \
                  $(GOLDEN_RTL)/FastArbiter_43.sv \
                  $(GOLDEN_RTL)/FastArbiter_45.sv

# golden 双例化：golden 顶（子模块闭包见 RTL_GOLDEN_DEPS，两侧共用同一份定义）。
GOLDEN_SRCS = $(GOLDEN_RTL)/RNXbar.sv

# ---------------------------------------------------------------------------
# matched-unread 加强（vmucp，2026-09-14，agent/arb）
#
# strict 首跑：native SUCCEEDED / passing 2642 / failing 0 / unmatched 0，只剩 3 个
# unread 点卡成 PARTIAL。3 点**全部** matched_nc，且是严格 1:1（ref 3 点 ↔ impl 3 点，
# 非 matched_nc 项为 0）：
#     r:/WORK/RNXbar/rxsnpArbs_0/pendingMask_reg[0] ↔ i:/WORK/RNXbar/u_core/rxsnpArbs_0/...
#     r:/WORK/RNXbar/rxrspArbs_0/pendingMask_reg[0] ↔ i:/WORK/RNXbar/u_core/rxrspArbs_0/...
#     r:/WORK/RNXbar/rxdatArbs_0/pendingMask_reg[0] ↔ i:/WORK/RNXbar/u_core/rxdatArbs_0/...
# 这 3 点落在 **golden 自己的** FastArbiter_43/_26/_45 里——这三个模块经 RTL_GOLDEN_DEPS
# 两侧同源 elaborate，ref 与 impl 读的是同一份 golden 文件、同一个实例名，所以双射是
# 结构性的而不是人工强配。
# 死位成因（FastArbiter 轮转仲裁）：
#   rrGrantMask <= {|chosenOH[2:0], |chosenOH[1:0], chosenOH[0], 1'h0}  ← bit0 恒 0
#   pendingMask[0] 唯一的读出点是  rrGrantMask[0] & pendingMask[0]
# bit0 的 grant mask 恒 0（轮转起点永远不会"停在自己之前"），于是 pendingMask[0] 虽是
# 真寄存器却无任何可观测路径 → FM cone 分析判 unread。
# 加强（true = 要 FM 多证一些，不是 waiver）：让 FM 实际比较这 3 个 matched-unread 点。
# ---------------------------------------------------------------------------
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = RNXbar
FM_REF_DEPS_RNXbar = FastArbiter_26.sv FastArbiter_29.sv FastArbiter_30.sv FastArbiter_35.sv FastArbiter_43.sv FastArbiter_45.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
