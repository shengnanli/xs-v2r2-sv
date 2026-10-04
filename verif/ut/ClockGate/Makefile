MODULE = ClockGate

# ClockGate：锁存器型时钟门控单元（ICG）行为模型的 standalone UT + FM（codex 0208 选项 B）。
# ref 侧 = golden ClockGate.sv；impl 侧 = rtl/common/ClockGate.sv。
# UT 双例化：重写件经 derive 改名 ClockGate_xs，与 golden ClockGate 同进一个 elaboration。
# CK 是被测时钟输入，不是 tb 时钟：tb 自己按相位推 CK，E/TE 只在远离 CK 沿的时刻变化。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/ClockGate.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ClockGate.sv
FM_VARIANTS = ClockGate
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制；运行期由 SIM_ARGS 选 +0 / +random / +<seed>017 三档。
# （本模块唯一的状态元件是那个锁存器，没有复位；这三档看它上电初值对比较的影响。）
VCS += +vcs+initreg+random
