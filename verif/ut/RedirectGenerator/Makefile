# RedirectGenerator —— 后端重定向仲裁两级流水；0 子模块、无厂商宏
MODULE = RedirectGenerator

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/RedirectGenerator.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/RedirectGenerator.sv

FM_VARIANTS = RedirectGenerator
FM_REF_DEPS_RedirectGenerator =

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的随机初值 initial 段两侧统一用 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS

# 两档 initreg。无复位寄存器：s1 的 561 位 redirect 与预译码（RegEnable(oldestValid)）、
# flushAfterCounter、memPred 三个折叠地址寄存器（RegEnable(s1 是 load 回放)）。
# tb 暖机先强制一次 exu 重定向与一次 load 回放把它们写定，之后才开比对窗口。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0 gencheck
run-initreg0:
	$(MAKE) run SEED=$(SEED) SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+0"
gencheck:
	python3 ../../../scripts/gen_redirectgen.py --check
