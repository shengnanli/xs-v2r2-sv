MODULE = PmpaddrLeaves20
RTL_DIR = ../../../rtl
LEAVES = Pmpaddr33Module Pmpaddr34Module Pmpaddr35Module Pmpaddr36Module \
 Pmpaddr37Module Pmpaddr38Module Pmpaddr39Module Pmpaddr40Module \
 Pmpaddr41Module Pmpaddr42Module Pmpaddr43Module Pmpaddr44Module \
 Pmpaddr45Module Pmpaddr46Module Pmpaddr47Module Pmpaddr48Module \
 Pmpaddr49Module Pmpaddr50Module Pmpaddr51Module Pmpaddr52Module
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
