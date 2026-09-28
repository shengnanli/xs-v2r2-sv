# MemTrigger —— LoadUnit s1 的调试触发器地址匹配（纯组合，4 个触发器）
# 本件无子模块；LoadUnit 里 loadTrigger 是它的唯一例化（StoreUnit 用的是 MemTrigger_3，不在本 UT）。
MODULE = MemTrigger

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/MemTrigger.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/MemTrigger.sv

FM_VARIANTS = MemTrigger

# 纯组合、无寄存器：merge_dup 无可合并之物；关掉只让 fm_predict 的模型按构造适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 纯组合：两档 initreg 无区分度，但按规矩两档都跑（编译期开机制，运行期 INITREG 选档）。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random
