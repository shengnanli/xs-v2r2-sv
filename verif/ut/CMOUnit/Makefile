# CMOUnit —— DCache MissQueue 里的 CMO（cbo.clean/flush/inval）发送单元
# 重写件 rtl/memblock/CMOUnit.sv（xs_CMOUnit_core + golden 同名 wrapper），golden 是无子模块的叶子。
MODULE = CMOUnit

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/CMOUnit.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/CMOUnit.sv

FM_VARIANTS = CMOUnit

# 逐个比较，不合并重复寄存器（fm_predict 模型严格适用）
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/CMOUnit.tcl★ —— req_address[63:48] 两侧对称死位
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2，两侧统一定义 SYNTHESIS。
# initreg：编译期打开机制，运行期 INITREG 选 +vcs+initreg+0 / random / <seed>017。
# 不复位寄存器只有 req_opcode/req_address，它们只在 SREQ 之后被读，那时已被 req.fire 写定。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gencheck
gencheck:
	python3 gen.py --check
