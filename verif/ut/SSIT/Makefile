MODULE = SSIT

RTL_DIR = ../../../rtl
# 单文件规范：package ssit_pkg + xs_SSIT_core + golden 同名 wrapper 都在 SSIT.sv 里
RTL_SRCS = $(RTL_DIR)/backend/SSIT.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# 两块同步读存储及其 bank 叶子。本仓 rtl/common/ 里**有**它们的重写件，但那是
# 另外的已签核目标，不是 SSIT 这个目标要证的东西：这里按 TLBuffer 家族的既有做法
# 放 RTL_GOLDEN_DEPS —— UT 两侧共用同一份 golden 定义（各例化一份，内容分叉仍会
# 被 rdata 比对抓到），FM 时与 ref 侧同源 elaborate，**不黑盒**。
SSIT_LEAVES = SyncDataModuleTemplate__1024entry.sv \
              SyncDataModuleTemplate__1024entry_1.sv \
              DataModule__64entry.sv \
              DataModule__64entry_16.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SSIT.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(SSIT_LEAVES))

FM_VARIANTS = SSIT
FM_REF_DEPS_SSIT = $(SSIT_LEAVES)

PORTLINT_ORDER = fail

# ---------------------------------------------------------------------------
# ★matched-unread 加强（vmucp）—— 本目标必须开，理由与实测数字如下★
# ---------------------------------------------------------------------------
# 结构性事实（不是写法问题，改写 RTL 去不掉）：golden SSIT **没有输出端口**，
# 闭包里也**没有任何黑盒**（report_black_boxes: FM-249 No black boxes）。于是整个
# 设计里没有任何可观测点，Formality 把**全部** DFF 判成 unread —— 不只是三组影子
# 数组。关 vmucp 时它直接 `Error: There are no compare points to verify. (FM-334)`，
# 连 verify 都不会跑。
#
# ★我原先预判 3073，实测 14525，差 4.7 倍 —— 记在这里免得下一个人照抄错的推理★
#   错在哪：我以为两块 SyncDataModuleTemplate 的寄存器算"被读"（SSIT 的 s2_* 读它们、
#   又写回它们）。实际判据不是"有没有下游寄存器"，而是"够不够得着可观测点"；
#   一个输出端口都没有 ⇒ 整个锥里没有一个点可观测 ⇒ 全员 unread。
#   实测分布（fm_work/SSIT/unread_points.txt，14525 行）：
#       SSIT 本体      7260 = debug_valid 1024 + debug_ssid 5120 + debug_strict 1024
#                             + resetCounter 20 + resetStepCounter 11 + state 1
#                             + REG 5 + s1_* 21 + s2_* 34
#       data_array     6197 = 1024x6 数据 + 53 个地址/旁路副本
#       valid_array    1068 = 1024x1 数据 + 44 个同上
#
# 两轮实测对比（同一份字节，唯一差别就是这个开关；commit 见 evidence/ 下 receipt）：
#   关 vmucp : Verification NOT RUN / aborted(FM-334)
#              passing 0 / failing 0 / Not-Compared-Unread 14525
#   开 vmucp : Verification SUCCEEDED
#              passing 14525 / failing 0 / unverified 0 / aborted 0 / unread 0
#              unmatched compare 0(0) / unmatched unread 0(0) / bbox 0
#   ⇒ passing 0 -> 14525，**不是空转**。
#
# 为什么它是"加强"不是"放宽"：`verification_verify_unread_compare_points` 仍是
# **false**（没放宽），打开的是 `..._matched_unread_...` —— 让 FM 去**多证** 14525 个
# 本来会被跳过的点。sidecar 的 entry_appvars 原样回读，qualifications 里
# dont_verify_objects / elab147 / relaxed_appvars 三项皆为空。
#
# 双射是结构性的、不是人工强配：基线那一轮 unread_points.txt 的 14525 行**全部**是
# matched_nc（ref 侧独占 0 行、impl 侧独占 0 行），即 ref 14525 <-> impl 14525。
# 其中 14434 对由 scripts/fm_eq.tcl 的 auto_match_flattened_arrays 按
# `<名>_<i>[_<j>]_reg` 规则自动配上（可读核沿用了 golden 的基名），剩下 91 对是
# 15 个标量寄存器的名差，由本目录 fm_pins.tcl 现场读回点名后逐位钉（FM-036 行数 0）。
#
# 白名单：scripts/fm_eq.tcl 的精确白名单已含 SSIT（main commit cf020d5）。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden 的随机初值 initial 块只在 `ifndef SYNTHESIS 下出现，与 FM 侧口径一致：
# 两侧都定义 SYNTHESIS，寄存器初值交给 +vcs+initreg。
# ★SSIT 是「两轮 initreg 真有意义」的那一类★：golden 里只有 debug_valid 与三个
# 计数/状态寄存器带异步复位，debug_ssid[1024]/debug_strict[1024]/REG/s1_*/s2_*
# 以及两块子存储的全部数据寄存器都**不复位**。tb 用两段暖机把它们写成确定值，
# 两轮 initreg 取值（0 / random）检验的正是「暖机确实覆盖到了每一个不复位寄存器」
# ——漏掉哪一个，random 那轮就会分叉而 0 那轮不会。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: tb
tb:
	python3 gen.py

# 判别力负测：注入真 bug，UT 必须报出来。变异只发生在 neg_build/（已 gitignore），
# 不进库。见 mutants.py 头部说明。
.PHONY: mutants
mutants:
	python3 mutants.py
