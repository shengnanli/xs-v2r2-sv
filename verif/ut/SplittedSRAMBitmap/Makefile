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
# merge_dup 用工具默认（true）：4 块内层 SRAMTemplate_124 用共享核 xs_SRAMTemplate_core，其非 holdRead
# 分支的 rdata_last_REG 在主线上与 respReg 同方程、靠 merge 合并（SRAMTemplate_124 自己签核时同口径）；
# 关掉 merge 它们就成了 golden 没有的 4 个 impl 独占 unread（lane 内诊断跑实测；codex 0206 D1 正在另一条
# lane 把它从核里删掉，合入后本目标随共享核一起重证）。
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
