MODULE = IntToFPLeaves8

RTL_DIR = ../../../rtl
LEAVES = LZA IntToFP_prenorm IntToFP_postnorm IntToFP_postnorm_1 \
         IntToFP_postnorm_2 IntToFP IntToFP_1 IntToFP_2
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES))) \
           $(RTL_DIR)/common/CLZ.sv \
           $(RTL_DIR)/common/xs_CLZ_core.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# RoundingUnit{,_1,_2} 属 codex 在途 lane（本仓不落任何 rtl 文件）：
# 两侧同源 golden-reuse —— UT 两侧共用同一定义，FM 时并入 impl 侧与 ref 侧
# 同源 elaborate（见 scripts/ut_common.mk 的 RTL_GOLDEN_DEPS 注释与
# verif/ut/Alu/Makefile 的 FM_REF_DEPS 惯例）。
ROUNDING_LEAVES = RoundingUnit.sv RoundingUnit_1.sv RoundingUnit_2.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(ROUNDING_LEAVES))

# golden 闭包（ut_common.mk 会自动对 RTL_GOLDEN_DEPS 去重）
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES))) \
              $(GOLDEN_RTL)/CLZ.sv \
              $(addprefix $(GOLDEN_RTL)/,$(ROUNDING_LEAVES))

FM_VARIANTS = $(LEAVES)
# 每个变体的 golden 侧依赖闭包；LZA 无依赖（不设该行，ut_common 自动为空）。
FM_REF_DEPS_IntToFP_prenorm = CLZ.sv LZA.sv
FM_REF_DEPS_IntToFP_postnorm = RoundingUnit.sv
FM_REF_DEPS_IntToFP_postnorm_1 = RoundingUnit_1.sv
FM_REF_DEPS_IntToFP_postnorm_2 = RoundingUnit_2.sv
FM_REF_DEPS_IntToFP = IntToFP_prenorm.sv IntToFP_postnorm.sv CLZ.sv LZA.sv RoundingUnit.sv
FM_REF_DEPS_IntToFP_1 = IntToFP_prenorm.sv IntToFP_postnorm_1.sv CLZ.sv LZA.sv RoundingUnit_1.sv
FM_REF_DEPS_IntToFP_2 = IntToFP_prenorm.sv IntToFP_postnorm_2.sv CLZ.sv LZA.sv RoundingUnit_2.sv

include ../../../scripts/ut_common.mk

# 两轮 initreg（CONVENTIONS「+vcs+initreg 的正确用法」）：编译期打开机制，运行期选取值。
# 本 UT 是 golden 与 *_xs 双例化：+vcs+initreg+random 会给两个实例各摇各的初值，
# 不复位寄存器两侧初态不同 => 假失配。所以两档用常量：make run INITREG=0 / INITREG=1。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
