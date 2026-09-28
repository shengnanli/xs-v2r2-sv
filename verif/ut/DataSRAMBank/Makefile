# DataSRAMBank —— DCache 数据阵列 bank 家族（DataSRAMBank / _1 / _2 / _4），4 路 × 单口 SRAMTemplate。
# 可读核 xs_DataSRAMBank_core 在 rtl/memblock/DataSRAMBank.sv；4 个 wrapper 由 scripts/gen_datasrambank.py 生成。
# 子模块处置：SRAMTemplate_84/86/88/92/100（PROVEN_DIRECT）两侧白盒；其下
#   sram_array_1p256x72m72s1h0l1b_dcsh_dat / array_7 / MbistClockGateCell / ClockGate 两侧同源 elaborate；
#   唯一黑盒 = 厂商 SRAM 叶子 array_7_ext（verif/vendor_boundary.tsv 已审定），逐条声明在 verif/allow/<目标>.json。
# merge_dup 保持工具默认（开），理由同 verif/ut/TagArray/Makefile（xs_SRAMTemplate_core 的 rdata_last_REG）。
MODULE = DataSRAMBank

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_84.sv \
           $(RTL_DIR)/common/SRAMTemplate_86.sv \
           $(RTL_DIR)/common/SRAMTemplate_88.sv \
           $(RTL_DIR)/common/SRAMTemplate_92.sv \
           $(RTL_DIR)/common/SRAMTemplate_100.sv \
           $(RTL_DIR)/memblock/DataSRAMBank.sv \
           $(RTL_DIR)/memblock/DataSRAMBank_1.sv \
           $(RTL_DIR)/memblock/DataSRAMBank_2.sv \
           $(RTL_DIR)/memblock/DataSRAMBank_4.sv
TB_SRCS  = tb.sv

SRAM_DEPS = sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv array_7.sv MbistClockGateCell.sv ClockGate.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(SRAM_DEPS))
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,DataSRAMBank.sv DataSRAMBank_1.sv DataSRAMBank_2.sv DataSRAMBank_4.sv \
                SRAMTemplate_84.sv SRAMTemplate_86.sv SRAMTemplate_88.sv SRAMTemplate_92.sv SRAMTemplate_100.sv) \
              $(RTL_GOLDEN_DEPS) $(GOLDEN_RTL)/array_7_ext.v

FM_VARIANTS = DataSRAMBank DataSRAMBank_1 DataSRAMBank_2 DataSRAMBank_4
FM_REF_DEPS_DataSRAMBank   = SRAMTemplate_84.sv SRAMTemplate_86.sv $(SRAM_DEPS)
FM_REF_DEPS_DataSRAMBank_1 = SRAMTemplate_88.sv $(SRAM_DEPS)
FM_REF_DEPS_DataSRAMBank_2 = SRAMTemplate_92.sv $(SRAM_DEPS)
FM_REF_DEPS_DataSRAMBank_4 = SRAMTemplate_100.sv $(SRAM_DEPS)
FM_MODE = assembly
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_datasrambank.py --check
