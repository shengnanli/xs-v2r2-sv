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

# ★FM_MERGE_DUP=false★（第 3 轮 FM 实测后加，依据如下，不是试出来的）
# 现象：golden 侧 55 个 IQSort_* 是 unmatched **compare point**，
#       impl 侧 55 个 IQSort_*_reg 是 unmatched **unread** point —— 两者
#       类别不同，FM 不会跨类别配对。叶名其实早就一模一样：
#           golden  r:/WORK/NewDispatch/IQSort_alu_0_0_reg
#           impl    i:/WORK/NewDispatch/u_core/IQSort_alu_reg[0][0]
#       与**已经配上**的 uopSelIQ（102 点）完全同构，所以不是命名问题。
# 成因：逐组分解干净得不像巧合 ——
#           N=2 的 6 组：各 4 个，配上 2、剩 2
#           N>=3 的 4 组：各 9/16 个，一个都没配上
#       N=2 时 iqSort[0] 与 iqSort[1] 互补（rank_d[0][i] == ~rank_d[1][i]），
#       verification_merge_duplicated_registers 把每组 4 个合并成 2 个，
#       存活的配上、被合并掉的落进 unread；N>=3 没有两两互补，合并不掉。
# 先例：MulUnit、RenameBuffer 同型（main 40f570f 记了 RenameBuffer 的实测：
#       配对修好后 failing 20->0、passing 651->5825）。
# 这不是政策例外：不是 waiver、不是 dont_verify、不放宽 appvar，
# 只是关掉一个会改变**配对类别**的工具优化。
FM_MERGE_DUP = false
