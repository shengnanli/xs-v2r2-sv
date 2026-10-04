MODULE = VIAluFix

# 向量整数 / 定点 ALU FU 外壳（VecPipedFuncUnit，LAT=1：typeMod 译码 + 操作数分组 + 两个 VIntFixpAlu64b + Mgu / Mgtu），vector-fu lane。
# child 处置（各自 receipt；全部两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件）：
#   VIAluSrcTypeModule（evidence/20d19bc5cd93）；VecDataSplitModule（本 lane）；VIntFixpAlu64b（evidence/5a3282d30ab1）+
#   VIntAdder64b / VIntMisc64b / VFixPoint64b / Adder_chain_rnd / CLZ_6/7/9/11（重写侧 CLZ 家族另有核 rtl/common/xs_CLZ_core.sv）；
#   Mgu（evidence/d09e1997840f）+ ByteMaskTailGen / UIntToContLow1s / UIntToContLow0s / MaskExtractor；Mgtu（evidence/cb2892a30a11）。
# tb 另带按元素的独立 oracle（同宽算术 / 逻辑 / 移位 / min-max / vmerge / vmv 与加宽加减；含 mask / tail / vstart）。
RTL_DIR  = ../../../rtl
ALU_TREE = VIntMisc64b VIntAdder64b Adder_chain_rnd VFixPoint64b VIntFixpAlu64b
MGU_TREE = UIntToContLow1s UIntToContLow0s MaskExtractor ByteMaskTailGen Mgu Mgtu
TARGETS  = VIAluFix
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv $(RTL_DIR)/common/CLZ_6.sv $(RTL_DIR)/common/CLZ_7.sv \
           $(RTL_DIR)/common/CLZ_9.sv $(RTL_DIR)/common/CLZ_11.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,VIAluSrcTypeModule VecDataSplitModule $(ALU_TREE) $(MGU_TREE) $(TARGETS)))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,CLZ_6.sv CLZ_7.sv CLZ_9.sv CLZ_11.sv \
               $(addsuffix .sv,VIAluSrcTypeModule VecDataSplitModule $(ALU_TREE) $(MGU_TREE) $(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = VIAluFix
FM_REF_DEPS_VIAluFix = CLZ_6.sv CLZ_7.sv CLZ_9.sv CLZ_11.sv VIAluSrcTypeModule.sv VecDataSplitModule.sv \
    VIntMisc64b.sv VIntAdder64b.sv Adder_chain_rnd.sv VFixPoint64b.sv VIntFixpAlu64b.sv \
    UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv ByteMaskTailGen.sv Mgu.sv Mgtu.sv

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。三档：
#   INITREG=0 / INITREG=random（seed 1 下退化为全 1）/ INITREG=<seed>017（真随机数值种子）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
