MODULE = Alu

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/alu_pkg.sv \
           $(RTL_DIR)/backend/Alu.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
# golden Alu 把每种基本运算拆成一个小 Module，这些叶子是 golden 侧闭包的一部分
# （无黑盒：全部两侧可见地 elaborate 进 ref 容器）。
ALU_LEAVES = AluDataModule.sv AddModule.sv SubModule.sv \
             LeftShiftModule.sv RightShiftModule.sv \
             LeftShiftWordModule.sv RightShiftWordModule.sv \
             ShiftResultSelect.sv MiscResultSelect.sv \
             ConditionalZeroModule.sv WordResultSelect.sv AluResSel.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Alu.sv $(addprefix $(GOLDEN_RTL)/,$(ALU_LEAVES))
# 这里**不**设 RTL_GOLDEN_DEPS：该变量会被一并塞进 FM_IMPL_SRCS（ut_common.mk:137），
# 只应在「impl 真的例化了某个 golden 叶子、需要两侧同源白盒」时才用。可读核
# xs_Alu_core 把这 12 个叶子全部重写成了本文件内的 function/always_comb，一个都没例化，
# 所以把它们放进 impl 侧只会让 receipt 的 impl_closure 里凭空出现 golden-rtl 路径，
# 让「是否复用 golden 逻辑」这条审计线索失真。UT 编译用 GOLDEN_SRCS 已覆盖。

FM_VARIANTS = Alu
FM_REF_DEPS_Alu = $(ALU_LEAVES)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
