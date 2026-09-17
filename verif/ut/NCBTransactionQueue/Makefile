MODULE = NCBTransactionQueue

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/xs_NCBTransactionQueue_core.sv \
           $(RTL_DIR)/uncore/NCBTransactionQueue.sv \
           $(RTL_DIR)/uncore/NCBTransactionQueue_1.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/NCBTransactionQueue.sv $(GOLDEN_RTL)/NCBTransactionQueue_1.sv

# 两个变体都是自包含叶子（golden 里 0 个子模块例化，子闭包已递归查过），
# 所以没有 FM_REF_DEPS_*，FM 可以两侧完整 elaborate、零黑盒。
FM_VARIANTS = NCBTransactionQueue NCBTransactionQueue_1

PORTLINT_ORDER = fail

# ★matched-unread 加强（不是放宽：FM 把未读点当真比较点去证，passing 必须随之增加）★
# 本家族的 unread 点 = info.ReturnNID(11 位) + info.ReturnTxnID(12 位) = 23 位/槽，
# 两侧同为死位（golden 存了这两个字段，但四个 infoRead 读口的 ParallelMux 只有 38 位
# {QoS,TgtID,SrcID,TxnID}，可读核照抄同一结构），非 Return* 的 unread 点 0 个。
# ★这一族的基线是 unmatched unread 而不是 matched_nc★（736(736) / 1472(1472)），
# FM 自己配不上，必须先由 fm_pins.tcl 按「槽号+字段+位号」1:1 钉成 matched_nc，
# 本开关才有东西可证。白名单在 scripts/fm_eq.tcl（归 coordinator 维护）。
# ★复核判据★：passing 6007 -> 6743（_1，正好 +736）/ 12054 -> 13526（正好 +1472）、
# failing 仍 0、unread 归 0、unmatched unread 0(0)、FM-036 = 0。
# passing 不增而 unread 归 0 = 点被吞掉，按 fail 处理。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true


include ../../../scripts/ut_common.mk

# golden 的随机初值 initial 块只在 `ifndef SYNTHESIS 下出现，与 FM 侧口径一致：
# 两侧都定义 SYNTHESIS，寄存器初值交给 +vcs+initreg。
#
# ★本模块每槽 34 个寄存器里只有 14/15 个在复位域★（逐条数过 golden 的
# `always @(posedge clock or posedge reset)` 复位臂：只有 valid 与 op 位；
# info / 两个地址 / Size / Len / Device / 两组 Critical+Count / order 一个都不复位）。
# 所以 tb 必须先暖机再比较，见 tb.sv 文件头；两轮 initreg 都绿**不**等于复位域正确，
# 把关的是「结构比对 + mutants.py 里的复位域变异体」。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

# 判别力负测：注入真 bug，UT 必须报出来。变异只发生在 neg_build/（已 gitignore），
# 不进库。见 mutants.py 头部说明。
.PHONY: mutants
mutants:
	python3 mutants.py
