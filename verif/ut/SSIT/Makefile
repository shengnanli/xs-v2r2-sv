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
# ★FM 预判：本目标 signoff-strict 大概率停在 PARTIAL(unread != 0)，需要 owner 裁定★
# ---------------------------------------------------------------------------
# 结构性原因（不是写法问题，改写 RTL 也去不掉）：
#   golden SSIT **没有输出端口**（见 rtl/backend/SSIT.sv 文件头），而三组 1024 项
#   影子数组 debug_valid/debug_ssid/debug_strict 在 golden 里是 dontTouch 保下来的
#   3072 个寄存器，它们的扇出**只有自己**：
#     debug_valid_i -> _GEN_4122+i -> _GEN_5146+i -> debug_valid_i
#     debug_ssid_i  -> _GEN_7194+i -> debug_ssid_i
#     debug_strict_i-> _GEN_6170+i -> _GEN_8218+i -> debug_strict_i
#   （自反馈按 FM 的口径不算“被读”。）另加 s2_loadStrict 一点：它唯一的去处是
#   golden 的 _GEN_4119，也就是 XSPerfAccumulate("ssit_update_strict_failed")，
#   模块内无读者。⇒ 预计 **3073 个 matched-unread 比较点**。
#
# 这 3073 点是不是可以加强（vmucp）：判据看着全都成立，但**必须用实跑复核**——
#   * 精确绑定/双射：impl 侧沿用了 golden 的基名 debug_valid/debug_ssid/debug_strict，
#     scripts/fm_eq.tcl 的 auto_match_flattened_arrays 按 `<名>_<i>[_<j>]_reg` 规则
#     自动配对（debug_ssid_reg[1023][4] <-> debug_ssid_1023_reg[4]），是结构性规则
#     不是人工强配；s2_loadStrict 由本目录 fm_pins.tcl 消名差。ref 3073 ↔ impl 3073。
#   * 加强后 passing 必须**增加** 3073、failing 仍 0、unread 归 0 —— 不增即空转，不算过。
# 但 vmucp 白名单硬编码在 scripts/fm_eq.tcl 第 258 行，**本 worker 不许改那个文件**
# （owner 指定的所有权边界）。所以这里只把开关写成注释，由 owner 连同白名单一起决定：
# FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

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
