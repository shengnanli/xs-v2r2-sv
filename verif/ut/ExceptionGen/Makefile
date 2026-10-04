# ExceptionGen —— ROB 的异常收集器（写回 5 组 + enq 选最老，记住 current）。叶子：无子模块、无黑盒。
# wrapper 由 scripts/gen_exceptiongen.py 从 golden 端口表生成（rtl 文件内 GENERATED 区）。
MODULE = ExceptionGen

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/ExceptionGen.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

GOLDEN_SRCS = $(GOLDEN_RTL)/ExceptionGen.sv

FM_VARIANTS = ExceptionGen
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
