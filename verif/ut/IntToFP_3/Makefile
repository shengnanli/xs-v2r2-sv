MODULE = IntToFP_3

# IntToFP_3（i2f 功能单元，latency 2；ExeUnit_5 的 i2f）。tb 由 scripts/gen_exeunits_ut.py 生成。
# 子树 IntToFPDataModule → IntToFP / _1 / _2 → IntToFP_prenorm(LZA, CLZ) / IntToFP_postnorm* (RoundingUnit*)
#   全部是已签核重写件（PROVEN_DIRECT）：两侧白盒 —— impl 读重写件、ref 读 golden；无黑盒。
RTL_DIR  = ../../../rtl
I2F_TREE = backend/IntToFPDataModule.sv \
           backend/IntToFP.sv backend/IntToFP_1.sv backend/IntToFP_2.sv \
           backend/IntToFP_prenorm.sv backend/LZA.sv common/xs_CLZ_core.sv common/CLZ.sv \
           backend/IntToFP_postnorm.sv backend/IntToFP_postnorm_1.sv backend/IntToFP_postnorm_2.sv \
           backend/RoundingUnit.sv backend/RoundingUnit_1.sv backend/RoundingUnit_2.sv
RTL_SRCS = $(RTL_DIR)/backend/IntToFP_3.sv $(addprefix $(RTL_DIR)/,$(I2F_TREE))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/IntToFP_3.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_IntToFP_3))

FM_VARIANTS = IntToFP_3
# golden 闭包逐个写字面文件名（fm_predict 的模型不展开 make 函数）
FM_REF_DEPS_IntToFP_3 = IntToFPDataModule.sv \
                        IntToFP.sv \
                        IntToFP_prenorm.sv \
                        LZA.sv \
                        CLZ.sv \
                        IntToFP_postnorm.sv \
                        RoundingUnit.sv \
                        IntToFP_1.sv \
                        IntToFP_postnorm_1.sv \
                        RoundingUnit_1.sv \
                        IntToFP_2.sv \
                        IntToFP_postnorm_2.sv \
                        RoundingUnit_2.sv
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
