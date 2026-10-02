MODULE = CompareLeaves6

RTL_DIR = ../../../rtl
LEAVES = compare_2to1 compare_2to1_2 compare_3to1 compare_3to1_1 \
         compare_3to1_2 compare_3to1_6
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES))) \
              $(GOLDEN_RTL)/Adder_xb.sv $(GOLDEN_RTL)/Adder_xb_3.sv \
              $(GOLDEN_RTL)/Adder_xb_8.sv $(GOLDEN_RTL)/Adder_xb_20.sv
FM_VARIANTS = $(LEAVES)

FM_REF_DEPS_compare_2to1 = Adder_xb_3.sv
FM_REF_DEPS_compare_2to1_2 = Adder_xb_20.sv
FM_REF_DEPS_compare_3to1 = Adder_xb.sv
FM_REF_DEPS_compare_3to1_1 = Adder_xb_3.sv
FM_REF_DEPS_compare_3to1_2 = Adder_xb_8.sv
FM_REF_DEPS_compare_3to1_6 = Adder_xb_20.sv

include ../../../scripts/ut_common.mk

# 两轮 initreg（CONVENTIONS「+vcs+initreg 的正确用法」）：编译期打开机制，运行期选取值。
# 本 UT 是 golden 与 *_xs 双例化：+vcs+initreg+random 会给两个实例各摇各的初值，
# 不复位寄存器两侧初态不同 => 假失配。所以两档用常量：make run INITREG=0 / INITREG=1。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
