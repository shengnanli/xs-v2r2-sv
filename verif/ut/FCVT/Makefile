MODULE = FCVT

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FCVT.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# FPCVT 及其闭包（fudian 浮点转换器，不是本轮重写目标）：
# 已逐字节核对 G0 与 G1 这 7 个文件完全一致，故两侧同源 elaborate，不设黑盒。
FCVT_LEAVES = FPCVT.sv CVT64.sv FP_INCVT.sv \
              RoundingUnit_3.sv RoundingUnit_4.sv \
              ShiftRightJam.sv CLZ_6.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FCVT.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(FCVT_LEAVES))

FM_VARIANTS = FCVT
FM_REF_DEPS_FCVT = $(FCVT_LEAVES)

# ---------------------------------------------------------------------------
# matched-unread 加强（codex 0146 GO#3）—— ★ 待整合，需与 scripts/ 的一行同时生效
# ---------------------------------------------------------------------------
# 默认（不加强）跑完剩 5 个 matched-unread：
#   fcvt/fcvt/fpcvt/fcvtmodTrueExpReg_reg[4:0]
# 它们在 FPCVT 里，而 FPCVT 是**两侧同源 elaborate** 的（ref 与 impl 读同一个
# golden 文件，见上面 FCVT_LEAVES），两侧路径除 u_core 外逐字相同 —— 严格 5<->5
# 双射，不存在人工强配。打开加强是让 FM **多证 5 个点**，不是 waiver。
# 已用诊断脚本实证（signoff appvar 全同 + 128 pin，仅把本项置 true）：
#   passing 2509 -> 2514, unread 0, failing/unverified/aborted/unmatched 全 0,
#   native Verification SUCCEEDED（0F/0A/2514P/0U）。
#
# 启用需要**两处同时改**，缺一会被 fm_eq.tcl 的精确白名单 fail-closed 挡下：
#   1) 本行取消注释：
#        FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
#   2) scripts/fm_eq.tcl 的白名单加 FCVT（本 owner 无该文件写权限，留给 integrator）：
#        -    if {$top ni {DebugModule DuplicatedTagArray FTBBank ICacheCtrlUnit ...
#        +    if {$top ni {DebugModule DuplicatedTagArray FCVT FTBBank ICacheCtrlUnit ...
# 在两处都改好之前保持注释：现状能跑出 native SUCCEEDED（verdict 因 unread=5 记
# PARTIAL），而单改本行会让 make fm-FCVT 直接 FM_MODE_ERROR 退出。
# 2026-09-14（PARTIAL 收口簇）：白名单已在 scripts/fm_eq.tcl 加上 FCVT，本行同时启用。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

# ---------------------------------------------------------------------------
# FM_MERGE_DUP=false —— ★加强，不是放宽★（2026-09-20，agent/provefleet2 实测）
#
# 为什么动它：跑前登记的模型预期 2652（闭包每个实例的寄存器位 1920 + 顶层 output 732），
# 而 merge_duplicated_registers=true（全仓默认）那一跑实测 **2514**：
#
#     差额 138，可指认项（constant_reg + unread）只有 16 -> ★剩 122 位指认不了★
#
# scripts/fm_predict.py 因为它落在"merge 带"里不判红，但工具自己标了
# 带宽 72.4%、"这条结论近乎无信息" —— merge 打开时 FM 把多少个重复寄存器合并成
# 一个比较点，**从 golden 静态算不出来**，于是那个 passing 数没有可复核的含义。
#
# 关掉之后（同一份 RTL、同一批 appvar、同一份钉点文件，只差这一个 appvar）：
#
#     passing   2514 -> **2625**（多比 111 个点）
#     failing / unverified / aborted / unread_notcompared   全 0
#     unmatched 六项全 0 / 零黑盒 / dont_verify=false / 无放宽 appvar
#     2652(模型) - 2625(实测) = 27 = constant_reg 27   ★逐位指认，余额 0★
#
# 不黑盒、不跳点、不约束 ref，只是要求 FM 逐个而不是合并后比，比较点只增不减
# （先例：verif/ut/MulUnit/Makefile、verif/ut/TXREQ/Makefile，
#  以及 scripts/fm_eq.tcl 里的经验注记）。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 里 `ifndef SYNTHESIS 的断言块调用未定义函数 xs_assert_v2，
# 且随机初始化 initial 块也只在非 SYNTHESIS 下出现——定义 SYNTHESIS 与 FM 侧口径一致。
VCS += +define+SYNTHESIS
