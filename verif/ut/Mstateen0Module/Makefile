MODULE = Mstateen0Module

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 primitive(newcsr_stateen.sv)+ 12 个薄 wrapper(newcsr_stateen_wrappers.sv)。
# stateen family: {M,H,S}stateen{0,1,2,3} = 12 golden 顶层。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_stateen.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_stateen_wrappers.sv
# UT 双例化用到的 golden(5 个含逻辑的代表形态)。
GOLDEN_SRCS  = $(GOLDEN_RTL)/Mstateen0Module.sv $(GOLDEN_RTL)/Mstateen1Module.sv \
               $(GOLDEN_RTL)/Hstateen0Module.sv $(GOLDEN_RTL)/Hstateen1Module.sv \
               $(GOLDEN_RTL)/Sstateen0Module.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: 逐 golden 顶层 vs impl(primitive + wrappers)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = Mstateen0Module Mstateen1Module Mstateen2Module Mstateen3Module \
              Hstateen0Module Hstateen1Module Hstateen2Module Hstateen3Module \
              Sstateen0Module Sstateen1Module Sstateen2Module Sstateen3Module

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值注入；UT 定义 SYNTHESIS 关掉以对齐 reset 语义。
VCS += +define+SYNTHESIS
