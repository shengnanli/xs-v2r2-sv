# SplittedSRAMBitmap —— golden 模块 SplittedSRAM（L2TLB bitmap cache 的 4 块切分 SRAM 阵列）。
# 目录不叫 SplittedSRAM：那个名字已被 PtwCache 的 SplittedSRAM_1/_2 家族 UT 占用（不同核，不同闭包）。
# 4 个子模块 SRAMTemplate_124 两侧白盒：ref 读 golden、impl 读重写件 rtl/common/SRAMTemplate_124.sv
# （+ xs_SRAMTemplate_core，已签核）；厂商宏链 sram_array_1p32x90m45s1h0l1b_bitmap / array_9 两侧同读，
# 宏内叶子 array_9_ext（vendor_macro）FM 不读 ⇒ 两侧对称黑盒，精确集合见 verif/allow/SplittedSRAM.json。
MODULE = SplittedSRAM

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_124.sv \
           $(RTL_DIR)/mmu/SplittedSRAM.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/sram_array_1p32x90m45s1h0l1b_bitmap.sv \
                  $(GOLDEN_RTL)/array_9.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SplittedSRAM.sv \
              $(GOLDEN_RTL)/SRAMTemplate_124.sv \
              $(GOLDEN_RTL)/sram_array_1p32x90m45s1h0l1b_bitmap.sv \
              $(GOLDEN_RTL)/array_9.sv \
              $(GOLDEN_RTL)/array_9_ext.v

FM_REF_DEPS_SplittedSRAM = SRAMTemplate_124.sv sram_array_1p32x90m45s1h0l1b_bitmap.sv array_9.sv

FM_MODE = assembly
FM_ALLOWLIST ?= 0
FM_VARIANTS = SplittedSRAM
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
