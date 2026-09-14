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

include ../../../scripts/ut_common.mk

# golden 里 `ifndef SYNTHESIS 的断言块调用未定义函数 xs_assert_v2，
# 且随机初始化 initial 块也只在非 SYNTHESIS 下出现——定义 SYNTHESIS 与 FM 侧口径一致。
VCS += +define+SYNTHESIS
