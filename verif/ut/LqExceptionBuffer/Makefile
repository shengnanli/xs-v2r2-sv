MODULE = LqExceptionBuffer

# LqExceptionBuffer（LoadQueue 的最老异常 load 记录器）：叶子，golden 侧 0 子模块，无黑盒。
# wrapper、钉点与 tb 由 scripts/gen_lqexcbuf.py 生成（--check 幂等）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/LqExceptionBuffer.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LqExceptionBuffer.sv

FM_VARIANTS = LqExceptionBuffer

# 关掉 merge_duplicated_registers：golden 每个入口各有一份值恒等的 RegNext(io.redirect)，
# 合并后两侧幸存者可能不同；且只有关掉时 fm_predict 的 passing 模型才严格适用。加强不是放宽。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：唯一的 unread 点是 perf 用的 RegNext(req_valid)（golden REG），两侧对称死位，
# 依据与六条证据见 verif/fm_target_config/LqExceptionBuffer.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_lqexcbuf.py --check
