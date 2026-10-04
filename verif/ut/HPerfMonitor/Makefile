# HPerfMonitor 家族 —— utility.HPerfMonitor 的三个参数化实例（Frontend / NewCSR hpmHc / Backend）。
# 同族 HPerfMonitor_3（MemBlock）另有 UT（verif/ut/HPerfMonitor_3，child 是另一个核 xs_HPerfCounter_idx8_core）。
# child：HPerfMonitor → HPerfCounter，HPerfMonitor_1 → HPerfCounter_8，HPerfMonitor_2 → HPerfCounter_13，
#   三者都已签核（PROVEN_DIRECT，共享核 rtl/backend/xs_HPerfCounter_core.sv）：两侧白盒，ref = golden，impl = 重写件。无黑盒。
# UT（gen.py）：三对双例化逐拍比 + 独立参考模型（HardwarePerfMonitor.scala 语义，6 拍延迟对齐）。
MODULE = HPerfMonitor

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_HPerfCounter_core.sv \
           $(RTL_DIR)/backend/HPerfCounter.sv \
           $(RTL_DIR)/backend/HPerfCounter_8.sv \
           $(RTL_DIR)/backend/HPerfCounter_13.sv \
           $(RTL_DIR)/common/HPerfMonitor.sv \
           $(RTL_DIR)/common/HPerfMonitor_1.sv \
           $(RTL_DIR)/common/HPerfMonitor_2.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/HPerfCounter.sv \
              $(GOLDEN_RTL)/HPerfCounter_8.sv \
              $(GOLDEN_RTL)/HPerfCounter_13.sv \
              $(GOLDEN_RTL)/HPerfMonitor.sv \
              $(GOLDEN_RTL)/HPerfMonitor_1.sv \
              $(GOLDEN_RTL)/HPerfMonitor_2.sv

FM_VARIANTS = HPerfMonitor HPerfMonitor_1 HPerfMonitor_2
FM_REF_DEPS_HPerfMonitor   = HPerfCounter.sv
FM_REF_DEPS_HPerfMonitor_1 = HPerfCounter_8.sv
FM_REF_DEPS_HPerfMonitor_2 = HPerfCounter_13.sv

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）只在关掉时严格适用；加强不是放宽
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 全部寄存器无复位（照抄 golden）：tb 暖机 8 拍（最长通路 6 拍）后才比。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_hperfmon.py --check
