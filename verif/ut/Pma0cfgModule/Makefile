MODULE = Pma0cfgModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 primitive(newcsr_pma.sv)+ 34 个薄 wrapper(newcsr_pma_wrappers.sv)。
# PMA family: Pmacfg{0,2} + Pmaaddr{0..15} + Pma{0..15}cfg = 34 golden 顶层。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_pma.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_pma_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/Pma0cfgModule.sv $(GOLDEN_RTL)/Pma14cfgModule.sv \
               $(GOLDEN_RTL)/Pmacfg0Module.sv $(GOLDEN_RTL)/Pmaaddr0Module.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: 逐 golden 顶层 vs impl(primitive + wrappers)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = Pmacfg0Module Pmacfg2Module \
              Pmaaddr0Module Pmaaddr1Module Pmaaddr2Module Pmaaddr3Module \
              Pmaaddr4Module Pmaaddr5Module Pmaaddr6Module Pmaaddr7Module \
              Pmaaddr8Module Pmaaddr9Module Pmaaddr10Module Pmaaddr11Module \
              Pmaaddr12Module Pmaaddr13Module Pmaaddr14Module Pmaaddr15Module \
              Pma0cfgModule Pma1cfgModule Pma2cfgModule Pma3cfgModule \
              Pma4cfgModule Pma5cfgModule Pma6cfgModule Pma7cfgModule \
              Pma8cfgModule Pma9cfgModule Pma10cfgModule Pma11cfgModule \
              Pma12cfgModule Pma13cfgModule Pma14cfgModule Pma15cfgModule

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值注入；UT 定义 SYNTHESIS 关掉以对齐 reset 语义。
VCS += +define+SYNTHESIS
