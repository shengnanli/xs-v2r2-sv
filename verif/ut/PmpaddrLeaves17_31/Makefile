MODULE = PmpaddrLeaves17_31
RTL_DIR = ../../../rtl
LEAVES = Pmpaddr17Module Pmpaddr18Module Pmpaddr19Module Pmpaddr20Module \
 Pmpaddr21Module Pmpaddr22Module Pmpaddr23Module Pmpaddr24Module \
 Pmpaddr25Module Pmpaddr26Module Pmpaddr27Module Pmpaddr28Module \
 Pmpaddr29Module Pmpaddr30Module Pmpaddr31Module
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk
# 两轮 initreg（CONVENTIONS「+vcs+initreg 的正确用法」）：编译期打开机制，运行期选取值。
# 本 UT 是 golden 与 *_xs 双例化：+vcs+initreg+random 会给两个实例各摇各的初值，
# 不复位寄存器两侧初态不同 => 假失配。所以两档用常量：make run INITREG=0 / INITREG=1。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
