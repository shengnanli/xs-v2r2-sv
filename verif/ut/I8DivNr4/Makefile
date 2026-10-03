MODULE = I8DivNr4

# 8 位非恢复余数除法器（VectorIdiv 的 SEW=8 车道）。子模块 IterBlockI8Nr4 两侧白盒：
# ref 用 golden 同名件，impl 用本仓已签核重写件（rtl/backend/IterBlockI8Nr4.sv）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/IterBlockI8Nr4.sv $(RTL_DIR)/backend/I8DivNr4.sv
# 激励/oracle 车道与 SRT16IterBlocks 共用（同一份 RISC-V 除法语义 oracle）。
TB_SRCS  = ../SRT16IterBlocks/div_lane.sv tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/I8DivNr4.sv $(GOLDEN_RTL)/IterBlockI8Nr4.sv

FM_VARIANTS = I8DivNr4
FM_REF_DEPS_I8DivNr4 = IterBlockI8Nr4.sv
# 比较点模型（fm_predict）只在不合并重复寄存器时成立（const_d_reg 四档里有逐位相同的位）。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。三档：
#   INITREG=0 / INITREG=random（seed 1 下退化为全 1）/ INITREG=<seed>017（真随机数值种子）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
