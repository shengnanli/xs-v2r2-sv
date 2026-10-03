MODULE = FCVT

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FCVT.sv \
           $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/backend/ShiftRightJam.sv \
           $(RTL_DIR)/backend/RoundingUnit_3.sv \
           $(RTL_DIR)/backend/RoundingUnit_4.sv \
           $(RTL_DIR)/backend/FP_INCVT.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# FPCVT 子树（FPCVT -> CVT64 -> FP_INCVT -> CLZ_6 / ShiftRightJam / RoundingUnit_3 / RoundingUnit_4）：
#   FPCVT / CVT64 —— PROVEN_IN_CONE、本仓无重写件：两侧同源 golden（RTL_GOLDEN_DEPS），不设黑盒。
#   FP_INCVT 及其 4 个 child —— 2026-10-03 起（agent/fpu-parents，incvt 组）两侧白盒：ref 读 golden，
#     impl 读本仓重写件（RTL_SRCS）。FM：impl 容器里 golden CVT64 例化的 FP_INCVT 解析到重写件 —— 真对比。
#   ★UT 限度★：CVT64 是两侧共用的 golden 定义，它例化的 FP_INCVT 在两侧都解析到 golden 那份
#     （重写件被 derive 改名成 FP_INCVT_xs，没人例化它），所以本 UT 回归不到重写件；
#     重写件的 UT 在 verif/ut/FP_INCVT，本层的替换由 FM 兜底。
#   此前（evidence/80e9b96e8eb6 的 receipt）7 个文件全部两侧同源 golden（已逐字节核对 G0 与 G1 一致）。
FCVT_SHARED = FPCVT.sv CVT64.sv
FCVT_LEAVES = $(FCVT_SHARED) FP_INCVT.sv \
              RoundingUnit_3.sv RoundingUnit_4.sv \
              ShiftRightJam.sv CLZ_6.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FCVT.sv $(GOLDEN_RTL)/FP_INCVT.sv $(GOLDEN_RTL)/RoundingUnit_3.sv \
              $(GOLDEN_RTL)/RoundingUnit_4.sv $(GOLDEN_RTL)/ShiftRightJam.sv $(GOLDEN_RTL)/CLZ_6.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(FCVT_SHARED))

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

# initreg 三档（2026-10-03，agent/fpu-parents 补接）：此前本 UT 没有 initreg 机制，只跑默认上电值。
#   编译期打开机制、运行期选值：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
