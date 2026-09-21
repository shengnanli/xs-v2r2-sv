MODULE = TXREQ

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/TXREQ.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Queue16_CHIREQ.sv \
                  $(GOLDEN_RTL)/ram_16x137.sv

FM_REF_DEPS_TXREQ = Queue16_CHIREQ.sv ram_16x137.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TXREQ.sv \
              $(GOLDEN_RTL)/Queue16_CHIREQ.sv \
              $(GOLDEN_RTL)/ram_16x137.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

# ---------------------------------------------------------------------------
# FM_MERGE_DUP=false —— ★加强，不是放宽★（2026-09-20，agent/provefleet2 实测）
#
# 为什么动它：跑前登记的模型预期 2341（= 闭包寄存器位 2201 + 顶层 output 140，
# 其中 2201 位里 2192 位是 ram_16x137 的 `reg [136:0] Memory[0:15]`），
# 而 merge_duplicated_registers=true（全仓默认）那一跑实测只有 **1492**：
#
#     差额 849，可指认项只有 constant_reg 1 -> ★剩 848 位指认不了★
#
# 按 scripts/fm_predict.py 的判据，这落在"merge 带"里所以不判红，但带宽 94.0%
# ——工具自己标了"这条结论近乎无信息"。也就是说 merge=true 那一跑的 passing
# 数**没有任何可复核的含义**：FM 把 16 项存储里重复的位合并掉了多少，
# 从 golden 静态算不出来。
#
# 关掉之后（同一份 RTL、同一批 appvar，只差这一个）：
#
#     passing   1492 -> **2287**（多比 795 个点）
#     failing 0 / unverified 0 / aborted 0 / unread_notcompared 0
#     unmatched 六项全 0 / 零黑盒 / dont_verify=false / 无放宽 appvar
#     2341(模型) - 2287(实测) = 54 = constant_reg 54  ★逐位指认，差额清零★
#
# 不黑盒、不跳点、不约束 ref，只是要求 FM 逐个而不是合并后比，比较点只增不减
# （同 verif/ut/MulUnit/Makefile 的先例与 scripts/fm_eq.tcl 里的经验注记）。
FM_MERGE_DUP = false
FM_VARIANTS = TXREQ

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
