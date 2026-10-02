MODULE = PmaaddrLeaves30
RTL_DIR = ../../../rtl
LEAVES = Pmaaddr1Module Pmaaddr2Module Pmaaddr3Module Pmaaddr4Module \
 Pmaaddr5Module Pmaaddr6Module Pmaaddr7Module Pmaaddr8Module \
 Pmaaddr9Module Pmaaddr10Module Pmaaddr11Module Pmaaddr12Module \
 Pmaaddr13Module Pmaaddr14Module Pmaaddr15Module Pmaaddr16Module \
 Pmaaddr17Module Pmaaddr18Module Pmaaddr19Module Pmaaddr20Module \
 Pmaaddr21Module Pmaaddr22Module Pmaaddr23Module Pmaaddr24Module \
 Pmaaddr25Module Pmaaddr26Module Pmaaddr27Module Pmaaddr28Module \
 Pmaaddr29Module Pmaaddr30Module
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
