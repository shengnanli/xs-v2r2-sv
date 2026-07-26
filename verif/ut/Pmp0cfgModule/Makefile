MODULE = Pmp0cfgModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 primitive(newcsr_pmpentrycfg.sv)+ 16 个薄 wrapper。
# PmpNcfgModule family: Pmp0cfg..Pmp15cfg golden 逐字节相同(仅模块名不同)。
# 每模块 = 单条 PMP entry 的 8 位 config WARL 合法化(A=NA4→NAPOT, W&~R 丢弃写)。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_pmpentrycfg.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_pmpentrycfg_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/Pmp0cfgModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: 全 16 golden 顶层 vs impl(primitive + wrappers)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = Pmp0cfgModule Pmp1cfgModule Pmp2cfgModule Pmp3cfgModule \
              Pmp4cfgModule Pmp5cfgModule Pmp6cfgModule Pmp7cfgModule \
              Pmp8cfgModule Pmp9cfgModule Pmp10cfgModule Pmp11cfgModule \
              Pmp12cfgModule Pmp13cfgModule Pmp14cfgModule Pmp15cfgModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
