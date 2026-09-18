MODULE = RenameBuffer

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/SnapshotGenerator.sv \
           $(RTL_DIR)/backend/RenameBuffer.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/RenameBuffer.sv $(GOLDEN_RTL)/SnapshotGenerator.sv

# RenameBuffer 的子闭包只有 SnapshotGenerator（递归查到底，没有别的子模块），
# 它也是本 worker 的目标，两侧都完整 elaborate ⇒ **零黑盒**。
# SnapshotGenerator 自己的 FM 目标在 verif/ut/SnapshotGenerator/（一个 golden 顶层
# 只由一个 UT 出 receipt，避免两处各出一份说法不一）。
FM_VARIANTS = RenameBuffer
FM_REF_DEPS_RenameBuffer = SnapshotGenerator.sv

PORTLINT_ORDER = fail

# ---------------------------------------------------------------------------
# FM_MERGE_DUP = false —— ★加强，不是放宽★（reviewer 批准；先例 11 个 UT，形状镜像 MulUnit）
# ---------------------------------------------------------------------------
# 病因：enqPtrVec 的 6 个 value 次态是 enqPtrNext_value + 0..5。
#       bit1(v+1) 与 bit1(v+5) 是**同一个函数**（加 4 不影响 bit0/bit1），bit0 同理。
#       merge_duplicated_registers=true 时两侧合并结果差一位：
#           每 index 存活比对点   idx0 idx1 idx2 idx3 idx4 idx5
#             ref                  8    8    7    7    6    6   ← 5[1] 被并进 1[1]
#             impl                 8    8    7    7    6    7   ← 5[1] 没并
#       于是剩下 3 个孤儿（三跑稳定复现，实测 fm_work/RenameBuffer/unmatched.rpt）：
#           Ref  DFF  r:/WORK/RenameBuffer/enqPtrVec_1_value_reg[1]
#           Impl DFF  i:/WORK/RenameBuffer/u_core/enq_ptr_value_q_reg[1][1]
#           Impl DFF  i:/WORK/RenameBuffer/u_core/enq_ptr_value_q_reg[5][1]
#       与 MulUnit 同机制、方向相反（那次是 impl 合了 31 个粘滞常数、ref 一个没合）。
# 下游后果：未配对的比对点在 FM 里是**自由割点** —— ref 侧 p1[1] 与 p5[1] 被强制成
#       同一根线，impl 侧是两根独立自由变量 ⇒ allocatePtrVec_1 与 allocatePtrVec_5
#       可以取到不同值 ⇒ 256 项缓冲表随之失配。实测 20 failing 全落在
#       renameBuffer_175 / renameBuffer_255（撞上 failing_point_limit=20 提前停，
#       所以那 20 个是"最先撞上的"，不是全集）。
# 反证（不依赖 FM 配对）：探针 tb 把两侧 enqPtrVec 的 6 个 value + flag 每拍 force 成
#       **同一组任意值**，逐拍比 256 项缓冲表全部内容；四种压力模式各占 25% 拍
#       （全随机 / 全挤 0..3 制造指针撞车 / 全挤 250..255 打末项与回绕 / 全挤 172..178
#       打 175）。3 seed × 3000 拍 buffer_mismatch=0 ⇒ **缓冲表写逻辑与 golden 等价**，
#       那 20 个 failing 是配对残缺的下游产物，不是边界逻辑写错。
# 为什么是加强：不黑盒、不跳点、不约束 ref、不放宽任何判据，只是要求 FM
#       **逐个而不是合并后比** —— 两侧各保留全部 6×8=48 位、按名 1:1 配对，
#       比对点只增不减。
# 修前基线（三跑稳定，commit db06306 / 7cf965a / 1fc9709）：
#       passing 649→651 / failing 20 / unverified 5149→5147 / unmatched 1(2) / 1593 MB
FM_MERGE_DUP = false

# ---------------------------------------------------------------------------
# FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true —— ★加强证明，不是 waiver★
# ---------------------------------------------------------------------------
# ★两处须同时生效★：这里是本 UT 的一半，另一半是 scripts/fm_eq.tcl 的 vmucp 白名单
# （main 9aa378f 加入 RenameBuffer，依据写在那一行紧邻的注释里）。白名单是 fail-closed 的：
# 非白名单目标开这一项会直接 FM_MODE_ERROR，所以这一行必须等白名单落地之后才加。
#
# ★顺序：先配对，再加强★（main f55397d 写进 fm_eq.tcl 的通用判断）
# 加强只作用于 **matched** unread 点。RenameBuffer 首跑那 51 个是 **unmatched** unread，
# 那时单开本项**必然空转**（TLBFA 实测 passing 一点没增）。所以先有 fm_pins.tcl 把
# 51 对钉上，实测转成 matched_nc 之后，本项才有对象。
#
# 加入依据（实测，fm_work/RenameBuffer/sidecar/native_facts.json）：
#   钉点前：native SUCCEEDED / passing 5825 / failing 0 / unverified 0 / aborted 0 /
#           unmatched 比较点 0(0)，唯一卡点 unmatched unread 51(51)
#   钉点后：unmatched **六项全零**（compare 0/0、unread 0/0、bbout 0/0），
#           matched_unread_notcompared_pairs = 51，
#           ref 唯一点 51 == impl 唯一点 51，**非 matched_nc 的未读项为 0** ⇒ 严格双射
#   三族均为**两侧同为死位**（不是哪一侧漏了逻辑）：
#     A  5 个 deqPtrVec_<i>_flag   / B 40 个 deqPtrVec_<i>_value[<b>]  (i=1..5)
#        deqPtrVec 只有 head 有读者（numValidEntries / deqPtrNext）；提交读口走 deqPtrOH
#        影子寄存器。golden 靠 Rab.scala 的 dontTouch(deqPtrVec) 留着 1..5 号，
#        重写核照抄 golden 的寄存器集合 ⇒ 对称。
#        ★把核收窄成只留 head 反而制造不对称★：golden 那 45 位会变成 golden-only 死位，
#        连双射都没有了，更难签（与 TLBFA「不要收窄 reqVpn」同一条结论）。
#     C  6 个 toVecExcpMod preg 的 bit7 —— 8 位存 pdest、输出端口只有 7 位
#        （golden 自己写的 [6:0]），bit7 无读出路径，两侧同构 bug-for-bug。
#   钉点脚本 fail-closed 且**证明过不空转**：diag/fm_pins_selftest.tcl 打桩
#   report_unmatched_points/set_user_match/exit，喂真实 51 条未读点跑四场景，实测
#     POSITIVE pinned=51 exit=-1 / NEG1 未知形状 exit=3 / NEG2 impl 少一个 exit=3 /
#     NEG3 推出路径不在集合 exit=3        （纯 tclsh 可复跑，不需要 Formality）
#
# ★开启后的验收判据（不达标就不算过，按本仓"passing 不增即空转"）★
#   passing 5825 -> 5876（**正好 +51**）、failing 仍 0、unread 归 0、unmatched 保持全零
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden 的随机初值 initial 块只在 `ifndef SYNTHESIS 下出现，与 FM 侧口径一致：
# 两侧都定义 SYNTHESIS，寄存器初值交给 +vcs+initreg。
# ★本模块有一大批不复位寄存器★（256 项缓冲表 ×8 字段 / walkPtr /
# vecLoadExcp_valid / 6 组 toVecExcpMod 打拍寄存器 / 4 个快照槽），
# 所以 initreg 的两轮取值是**真的有区别**的：tb 先跑 160 拍暖机把它们全写一遍，
# 之后才开比对；暖机若漏了哪一个，random 那轮当场就炸。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

# 判别力负测：注入真 bug，UT 必须报出来。变异只发生在 neg_build/（已 gitignore），
# 不进库。见 mutants.py 头部说明。
.PHONY: mutants
mutants:
	python3 mutants.py
