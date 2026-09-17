MODULE = NewDispatch

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/NewDispatch.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# NewDispatch 不是叶子：它例化 7 个子模块，RegCacheTagTable 底下还有 2 个，
# 闭包一共 9 个（35174 行 golden）。这 9 个本仓都还没实现，已拆成 Lane H / Lane I。
# UT 里两侧**共用**这 9 份 golden 定义（derive_ut_impl 只改 NewDispatch 自己的名字），
# 这是 UT 的常规做法；FM 侧它们必须黑盒，且 NewDispatch 只能 assembly 条件绿，
# 要等 Lane H/I 各自 SIGNOFF_PASS 之后才算数。
ND_CHILDREN = BusyTable.sv BusyTable_1.sv BusyTable_2.sv BusyTable_3.sv \
              VlBusyTable.sv LsqEnqCtrl.sv RegCacheTagTable.sv \
              RegCacheTagModule.sv RegCacheTagModule_1.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/NewDispatch.sv $(addprefix $(GOLDEN_RTL)/,$(ND_CHILDREN))

# 这里**不**设 RTL_GOLDEN_DEPS：重写侧一个 golden 子模块都没例化（那 9 个的位
# 目前是故意悬空的）。把它们塞进 impl 侧只会让 receipt 的 impl_closure 里凭空
# 出现 golden-rtl 路径，污染「是否复用 golden 逻辑」这条审计线索。

FM_VARIANTS = NewDispatch
FM_REF_DEPS_NewDispatch = $(ND_CHILDREN)

include ../../../scripts/ut_common.mk

# 210 个不复位寄存器：机制在编译期打开一次，取值在运行期由 plusarg 选
# （`+vcs+initreg+0` 放编译行会 Error-[OBSL_OPT_E]，实测过）。
VCS += +define+SYNTHESIS +vcs+initreg+random

# ★判据 D 的临时放行★：选择通路（uopSelIQ 的 toRenameAllFire/firedVec）要
# LsqEnqCtrl 的 canAccept，Lane I 还没落地，于是重写侧只会选中 lane0/lane1，
# lane2~5 的 payload 根本到不了输出（实测：golden 六条都选，重写只选两条）。
# 这是真覆盖洞，不是 tb 写错，所以显式放行而不是假装没有。
# ★Lane I 落地后必须删掉这一行★，判据 D 会重新变成硬闸。
SIM_ARGS += +known_hole_frozen_select

# ★曾经开过 FM_MERGE_DUP=false，已回退（c35c160 -> 本次）★
# 当时的假设：N=2 的组里 iqSort[0]/iqSort[1] 互补被 merge 掉，导致 55 个点落进
# unread；关掉合并就该归位。★实测证伪，且方向相反★：
#     unmatched unread (impl)   55 -> 67   （预期 0）
#     unmatched compare (ref) 7173 -> 7227 （预期 7118）
#     passing                  589 -> 589  （预期 >589）
# 真相是这 67 个**本来就是 unread**，合并只是先前替我消掉了其中 12 个、让分母显小。
# 「合并掩盖了 12 个」被我误读成「合并制造了 55 个」——排除≠证实。
# 按 40f570f 判据(b)，unmatched 变大 = 自由割点变多 = 后续测量质量下降，
# 一个没有依据又让仪器变钝的配置没有留的理由，故回退默认值(true)。
# 四轮证据都在 evidence/ 里（da07aa52 / cb8a072f / 69a5dfde / c35c1600），证伪过程不丢。
