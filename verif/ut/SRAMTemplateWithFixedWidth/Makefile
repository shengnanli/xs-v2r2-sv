# SRAMTemplateWithFixedWidth 家族（4 个变体）—— ICache 数据阵列的定宽切分 SRAM。
# 薄文件由 scripts/gen_sram_fixed_width.py 从 golden 生成。每个变体唯一子模块 SRAMTemplate_4/_8/_16/_32
# 两侧白盒：ref 读 golden、impl 读重写件 rtl/common/SRAMTemplate_<n>.sv（+ xs_SRAMTemplate_core，已签核）；
# 厂商宏链 sram_array_1p256x66m66s1h0l1b_icsh_dat / array_0 两侧同读，宏内叶子 array_0_ext（vendor_macro）
# FM 不读 ⇒ 两侧对称黑盒，精确集合见 verif/allow/<T>.json。
MODULE = SRAMTemplateWithFixedWidth

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_4.sv \
           $(RTL_DIR)/common/SRAMTemplate_8.sv \
           $(RTL_DIR)/common/SRAMTemplate_16.sv \
           $(RTL_DIR)/common/SRAMTemplate_32.sv \
           $(RTL_DIR)/frontend/SRAMTemplateWithFixedWidth.sv \
           $(RTL_DIR)/frontend/SRAMTemplateWithFixedWidth_4.sv \
           $(RTL_DIR)/frontend/SRAMTemplateWithFixedWidth_12.sv \
           $(RTL_DIR)/frontend/SRAMTemplateWithFixedWidth_28.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv \
                  $(GOLDEN_RTL)/array_0.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth.sv \
              $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_4.sv \
              $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_12.sv \
              $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_28.sv \
              $(GOLDEN_RTL)/SRAMTemplate_4.sv \
              $(GOLDEN_RTL)/SRAMTemplate_8.sv \
              $(GOLDEN_RTL)/SRAMTemplate_16.sv \
              $(GOLDEN_RTL)/SRAMTemplate_32.sv \
              $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv \
              $(GOLDEN_RTL)/array_0.sv \
              $(GOLDEN_RTL)/array_0_ext.v

FM_REF_DEPS_SRAMTemplateWithFixedWidth = SRAMTemplate_4.sv sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplateWithFixedWidth_4 = SRAMTemplate_8.sv sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplateWithFixedWidth_12 = SRAMTemplate_16.sv sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplateWithFixedWidth_28 = SRAMTemplate_32.sv sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv

FM_MODE = assembly
FM_ALLOWLIST ?= 0
FM_VARIANTS = SRAMTemplateWithFixedWidth SRAMTemplateWithFixedWidth_4 SRAMTemplateWithFixedWidth_12 SRAMTemplateWithFixedWidth_28
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_sram_fixed_width.py --check
