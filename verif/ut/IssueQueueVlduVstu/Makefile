MODULE = EntriesVlduVstu

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包 + 条目核 + 阵列核(供 UT u_i 侧 + FM impl 侧)。
RTL_SRCS = $(RTL_DIR)/backend/iq_vlduvstu_pkg.sv \
           $(RTL_DIR)/backend/IqEntryVlduVstu.sv \
           $(RTL_DIR)/backend/EntriesVlduVstu.sv

# golden 黑盒(两侧共享):EnqPolicy_14(simp/comp 转移策略)。本变体无 UIntCompressor。
BB_DEPS = EnqPolicy_14.sv

# golden 单条目(UT u_g 侧 + FM ref 侧)
GOLDEN_LEAVES = EnqEntryVecMem_2.sv OthersEntryVecMem_14.sv OthersEntryVecMem_16.sv

# UT: u_g=golden Entries,u_i=可读核 wrapper(重命名 _xs)。
TB_SRCS = entries_variant_xs.sv entries_tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/EntriesVlduVstu.sv \
              $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_LEAVES) $(BB_DEPS))

# FM: golden EntriesVlduVstu vs 可读核 wrapper。黑盒+golden单条目两侧共享。
WRAPPER_SRCS = $(RTL_DIR)/backend/EntriesVlduVstu_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))
FM_VARIANTS = EntriesVlduVstu
FM_REF_DEPS_EntriesVlduVstu = $(GOLDEN_LEAVES) $(BB_DEPS)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# golden 状态寄存器无 reset,上电为 X;用 initreg 让两侧寄存器都从 0 上电。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
