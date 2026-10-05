MODULE = VIAlu

# 向量整数「归约 / 掩码 / vmv.x.s」ALU（yunsuan VIAlu：Reduction + VMask 两个子单元 + vmv.x.s 两拍 + 出口三选一），
# vector-fu lane。
# child 处置（各自 receipt；两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件）：
#   Reduction（evidence/6038c4afbc60）及其闭包 CSA3to2_124/125/127/132、CSA4to2_15/16、compare_2to1(_2)、
#   compare_3to1(_1/_2/_6)，以及 golden compare_* 内部的 Adder_xb / _3 / _8 / _20（重写件 compare_* 内联，ref 侧依赖）；
#   VMask（evidence/afe9babc7a2e，叶子）。
# tb 另带独立 oracle（归约照抄 verif/ut/Reduction 的整数语义参考 + vmv.x.s 符号扩展）。
RTL_DIR  = ../../../rtl
CHILDREN = CSA3to2_124 CSA3to2_125 CSA3to2_127 CSA3to2_132 CSA4to2_15 CSA4to2_16 \
           compare_2to1 compare_2to1_2 compare_3to1 compare_3to1_1 compare_3to1_2 compare_3to1_6 Reduction VMask
TARGETS  = VIAlu
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_ADDERS = Adder_xb.sv Adder_xb_3.sv Adder_xb_8.sv Adder_xb_20.sv
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)) $(GOLDEN_ADDERS))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = VIAlu
FM_REF_DEPS_VIAlu = CSA3to2_124.sv CSA3to2_125.sv CSA3to2_127.sv CSA3to2_132.sv CSA4to2_15.sv CSA4to2_16.sv \
    compare_2to1.sv compare_2to1_2.sv compare_3to1.sv compare_3to1_1.sv compare_3to1_2.sv compare_3to1_6.sv \
    Adder_xb.sv Adder_xb_3.sv Adder_xb_8.sv Adder_xb_20.sv Reduction.sv VMask.sv

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）严格适用（Reduction 内 vd_vsew_reg_s1 与 vdType_reg_s1[1:0] 逐位恒等）。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：两个子单元里两侧对称的死位（Reduction vdType_reg_s1[3:2]、VMask vs1_reg_s1[127:8]），
# 与子单元各自签核同一组；依据见 verif/fm_target_config/VIAlu.tcl，Reduction 的寄存器名差由本目录 fm_pins_pre.tcl 消掉。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 本层 5 个寄存器全无复位（validS1 = RegNext），子单元大多异步复位；tb 先复位再比（同 verif/ut/Reduction）。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
