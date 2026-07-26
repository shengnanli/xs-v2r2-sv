MODULE = Tdata1Module

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 primitive(newcsr_trigger.sv)+ 10 个薄 wrapper(newcsr_trigger_wrappers.sv)。
# Trigger family: Tdata{1,2} + Trigger{0..3}_Tdata{1,2} = 10 golden 顶层。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_trigger.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_trigger_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/Tdata1Module.sv \
               $(GOLDEN_RTL)/Trigger0_Tdata1Module.sv \
               $(GOLDEN_RTL)/Trigger0_Tdata2Module.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: 逐 golden 顶层 vs impl(primitive + wrappers)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = Tdata1Module Tdata2Module \
              Trigger0_Tdata1Module Trigger1_Tdata1Module \
              Trigger2_Tdata1Module Trigger3_Tdata1Module \
              Trigger0_Tdata2Module Trigger1_Tdata2Module \
              Trigger2_Tdata2Module Trigger3_Tdata2Module

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值注入；UT 定义 SYNTHESIS 关掉以对齐 reset 语义。
VCS += +define+SYNTHESIS
