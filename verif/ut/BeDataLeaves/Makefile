# BeDataLeaves —— 后端五个数据通路叶子/小父：
#   VsetModule（vl/vtype 计算，纯组合）、strdiedLSNumOfUopTable / indexedLSNumOfUopTable
#   （向量访存 uop 数查表，纯组合）、IntToFPDataModule（整数转浮点两级流水，例化
#   IntToFP / _1 / _2）、AluDataModule（ALU 组合数据通路）。
# 子模块一律两侧白盒：ref 侧 golden 闭包，impl 侧本工程已签核（PROVEN_DIRECT）的重写件；无黑盒。
MODULE = BeDataLeaves

RTL_DIR  = ../../../rtl
I2F_IMPL = backend/IntToFP.sv backend/IntToFP_1.sv backend/IntToFP_2.sv \
           backend/IntToFP_prenorm.sv backend/IntToFP_postnorm.sv \
           backend/IntToFP_postnorm_1.sv backend/IntToFP_postnorm_2.sv \
           backend/RoundingUnit.sv backend/RoundingUnit_1.sv backend/RoundingUnit_2.sv \
           backend/LZA.sv common/CLZ.sv common/xs_CLZ_core.sv
RTL_SRCS = $(RTL_DIR)/backend/backend_common_pkg.sv \
           $(RTL_DIR)/backend/VsetModule.sv \
           $(RTL_DIR)/backend/strdiedLSNumOfUopTable.sv \
           $(RTL_DIR)/backend/indexedLSNumOfUopTable.sv \
           $(addprefix $(RTL_DIR)/,$(I2F_IMPL)) \
           $(RTL_DIR)/backend/IntToFPDataModule.sv \
           $(RTL_DIR)/backend/alu_pkg.sv \
           $(RTL_DIR)/backend/Alu.sv \
           $(RTL_DIR)/backend/AluDataModule.sv
TB_SRCS  = tb.sv

I2F_GOLD = IntToFP.sv IntToFP_1.sv IntToFP_2.sv IntToFP_prenorm.sv IntToFP_postnorm.sv \
           IntToFP_postnorm_1.sv IntToFP_postnorm_2.sv RoundingUnit.sv RoundingUnit_1.sv \
           RoundingUnit_2.sv LZA.sv CLZ.sv
ALU_GOLD = AddModule.sv SubModule.sv LeftShiftModule.sv RightShiftModule.sv \
           LeftShiftWordModule.sv RightShiftWordModule.sv ShiftResultSelect.sv \
           MiscResultSelect.sv ConditionalZeroModule.sv WordResultSelect.sv AluResSel.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/VsetModule.sv \
              $(GOLDEN_RTL)/strdiedLSNumOfUopTable.sv \
              $(GOLDEN_RTL)/indexedLSNumOfUopTable.sv \
              $(GOLDEN_RTL)/IntToFPDataModule.sv $(addprefix $(GOLDEN_RTL)/,$(I2F_GOLD)) \
              $(GOLDEN_RTL)/AluDataModule.sv $(addprefix $(GOLDEN_RTL)/,$(ALU_GOLD))

FM_VARIANTS = VsetModule strdiedLSNumOfUopTable indexedLSNumOfUopTable IntToFPDataModule AluDataModule
FM_REF_DEPS_IntToFPDataModule = $(I2F_GOLD)
FM_REF_DEPS_AluDataModule = $(ALU_GOLD)
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# IntToFPDataModule 的 8 个流水寄存器不复位（RegEnable）：两侧初值在 random 档各摇各的，
# tb 用 arm 条件（两级使能各至少打过一次）推迟比较窗口，之后两侧状态一致。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
