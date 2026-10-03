MODULE = VIDiv

# 向量整数除法 FU 外壳：VectorIdiv（16 个标量除法器）+ Mgu（mask/tail 合并）。
# 子模块全部两侧白盒：ref 用 golden 同名件，impl 用本仓已签核重写件。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/CSA3_2.sv \
           $(RTL_DIR)/backend/CSA3_2_3988.sv $(RTL_DIR)/backend/CSA3_2_3992.sv \
           $(RTL_DIR)/backend/CSA3_2_3987.sv $(RTL_DIR)/backend/CSA3_2_4017.sv \
           $(RTL_DIR)/backend/CSA3_2_4111.sv $(RTL_DIR)/backend/CSA3_2_4173.sv \
           $(RTL_DIR)/backend/SignDec.sv $(RTL_DIR)/backend/Conversion.sv \
           $(RTL_DIR)/backend/Conversion_8.sv $(RTL_DIR)/backend/Conversion_12.sv \
           $(RTL_DIR)/backend/SelBlock_v4.sv $(RTL_DIR)/backend/SpecBlock_v4.sv \
           $(RTL_DIR)/backend/IterBlock_v4.sv $(RTL_DIR)/backend/IterBlock_v4_4.sv \
           $(RTL_DIR)/backend/IterBlock_v4_6.sv $(RTL_DIR)/backend/SRT4qdsCons.sv \
           $(RTL_DIR)/backend/SRT16Divint.sv $(RTL_DIR)/backend/SRT16Divint_4.sv \
           $(RTL_DIR)/backend/SRT16Divint_6.sv $(RTL_DIR)/backend/IterBlockI8Nr4.sv \
           $(RTL_DIR)/backend/I8DivNr4.sv $(RTL_DIR)/backend/VectorIdiv.sv \
           $(RTL_DIR)/backend/UIntToContLow1s.sv $(RTL_DIR)/backend/UIntToContLow0s.sv \
           $(RTL_DIR)/backend/MaskExtractor.sv $(RTL_DIR)/backend/ByteMaskTailGen.sv \
           $(RTL_DIR)/backend/Mgu.sv $(RTL_DIR)/backend/VIDiv.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,CSA3_2_3988.sv CSA3_2_3992.sv CSA3_2_3987.sv CSA3_2_4017.sv \
               CSA3_2_4111.sv CSA3_2_4173.sv SignDec.sv Conversion.sv Conversion_8.sv Conversion_12.sv \
               SelBlock_v4.sv SpecBlock_v4.sv IterBlock_v4.sv IterBlock_v4_4.sv IterBlock_v4_6.sv \
               SRT4qdsCons.sv SRT16Divint.sv SRT16Divint_4.sv SRT16Divint_6.sv IterBlockI8Nr4.sv \
               I8DivNr4.sv VectorIdiv.sv UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv \
               ByteMaskTailGen.sv Mgu.sv VIDiv.sv)

# 字面名（fm_predict.py / 台账脚本按行读 Makefile，不展开变量）。
FM_VARIANTS = VIDiv
FM_REF_DEPS_VIDiv = VectorIdiv.sv Mgu.sv ByteMaskTailGen.sv UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv I8DivNr4.sv IterBlockI8Nr4.sv SRT16Divint.sv SRT16Divint_4.sv SRT16Divint_6.sv SRT4qdsCons.sv IterBlock_v4.sv IterBlock_v4_4.sv IterBlock_v4_6.sv SelBlock_v4.sv SpecBlock_v4.sv CSA3_2_3988.sv CSA3_2_3992.sv SignDec.sv CSA3_2_4017.sv CSA3_2_3987.sv CSA3_2_4111.sv CSA3_2_4173.sv Conversion.sv Conversion_8.sv Conversion_12.sv
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。三档：
#   INITREG=0 / INITREG=random（seed 1 下退化为全 1）/ INITREG=<seed>017（真随机数值种子）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
