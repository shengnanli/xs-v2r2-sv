# PMPChecker 家族 —— PMP/PMA 权限检查器的三个变体（同一个参数化核 xs_PMPChecker_core）：
#   PMPChecker    纯组合（L2TLB 页表访存口）
#   PMPChecker_2  结果打一拍（Frontend 取指口）
#   PMPChecker_12 leaveHitMux，命中位先打一拍（MemBlock 访存口）
# 自足叶子：无子模块、无黑盒。薄 wrapper 由 scripts/gen_pmpchecker.py 生成。
MODULE = PMPChecker

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_PMPChecker_core.sv \
           $(RTL_DIR)/backend/PMPChecker.sv \
           $(RTL_DIR)/backend/PMPChecker_2.sv \
           $(RTL_DIR)/backend/PMPChecker_12.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/PMPChecker.sv \
              $(GOLDEN_RTL)/PMPChecker_2.sv \
              $(GOLDEN_RTL)/PMPChecker_12.sv

FM_VARIANTS = PMPChecker PMPChecker_2 PMPChecker_12
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_pmpchecker.py --check
