# ActiveGenerationTable —— SMS 预取器的活跃代表（16 项全相联 + PLRU，三级流水）。
# golden 无子模块；重写核例化共享辅助件 rtl/common/xs_PlruReplacer.sv（Chisel 把 PLRU 内联进了使用者，
# golden 里是本模块的 state_reg），无黑盒。
MODULE = ActiveGenerationTable

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/ActiveGenerationTable.sv \
           $(RTL_DIR)/common/xs_PlruReplacer.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/ActiveGenerationTable.sv

FM_VARIANTS = ActiveGenerationTable
FM_MERGE_DUP = false
# vmucp（加强不是放宽）：对称死位的依据与六条证据见 verif/fm_target_config/ActiveGenerationTable.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
