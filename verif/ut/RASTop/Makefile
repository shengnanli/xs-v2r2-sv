# RASTop —— golden 模块 RAS（BPU 的返回地址栈预测器外层）。
# 目录不叫 RAS：那个名字已被子模块 RASStack 的 UT（verif/ut/RAS，MODULE=RASStack）占用。
# 唯一子模块 RASStack（已独立签核）两侧白盒：ref 读 golden RASStack.sv，impl 读重写件
# rtl/frontend/RASStack.sv。无黑盒。wrapper 与钉点 fm_pins_pre.tcl 由 scripts/gen_ras.py 生成。
MODULE = RAS

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/RASStack.sv \
           $(RTL_DIR)/frontend/RAS.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/RAS.sv \
              $(GOLDEN_RTL)/RASStack.sv

FM_VARIANTS = RAS
FM_REF_DEPS_RAS = RASStack.sv
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_ras.py --check
