# TagArray —— DCache tag 阵列：TagSRAMBank（2 路存储体 + 上电清零）与 TagArray（2 个存储体拼 4 路）。
# 子模块处置：
#   SRAMTemplate_116（docs/coverage_three_axis.tsv = PROVEN_DIRECT）→ 两侧白盒：ref 读 golden，
#     impl 读本仓 rtl/common/SRAMTemplate_116.sv + xs_SRAMTemplate_core；
#   其下 sram_array_1p256x86m43s1h0l1b_dcsh_tag / array_8 / MbistClockGateCell / ClockGate 两侧同源 elaborate
#     （RTL_GOLDEN_DEPS，真受验）；唯一黑盒是厂商 SRAM 编译器叶子 array_8_ext
#     （verif/vendor_boundary.tsv 已审定，FM 两侧都不读 .v ⇒ 对称未解析黑盒）。
# FM_MODE=assembly：黑盒边界逐条声明在 verif/allow/<目标>.json（declare_allow.py 由实跑生成，只含 array_8_ext）。
MODULE = TagArray

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_116.sv \
           $(RTL_DIR)/memblock/TagSRAMBank.sv \
           $(RTL_DIR)/memblock/TagArray.sv
TB_SRCS  = tb.sv

SRAM_DEPS = sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv array_8.sv MbistClockGateCell.sv ClockGate.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(SRAM_DEPS))
GOLDEN_SRCS = $(GOLDEN_RTL)/TagSRAMBank.sv $(GOLDEN_RTL)/TagArray.sv $(GOLDEN_RTL)/SRAMTemplate_116.sv \
              $(RTL_GOLDEN_DEPS) $(GOLDEN_RTL)/array_8_ext.v

FM_VARIANTS = TagSRAMBank TagArray
FM_REF_DEPS_TagSRAMBank = SRAMTemplate_116.sv $(SRAM_DEPS)
FM_REF_DEPS_TagArray    = TagSRAMBank.sv SRAMTemplate_116.sv $(SRAM_DEPS)
FM_MODE = assembly
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
