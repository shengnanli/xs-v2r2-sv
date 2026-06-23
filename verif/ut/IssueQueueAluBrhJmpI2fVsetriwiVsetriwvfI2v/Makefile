MODULE = EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包 + 条目核 + 阵列核 + golden 同名 wrapper(供 FM)。
RTL_SRCS = $(RTL_DIR)/backend/iq_abjivvi_pkg.sv \
           $(RTL_DIR)/backend/IqEntryAbjivvi.sv \
           $(RTL_DIR)/backend/EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv

# golden 黑盒(两侧共享):EnqPolicy(转移策略)、UIntCompressor(exuSources 编码)。
BB_DEPS = EnqPolicy.sv UIntCompressor_27_000011100000000000001010101.sv

# golden 单条目(UT u_g 侧 + FM ref 侧)
GOLDEN_LEAVES = EnqEntry_4.sv OthersEntry_44.sv OthersEntry_50.sv

# UT: u_g=golden Entries,u_i=可读核 wrapper(重命名 _xs)。
TB_SRCS = entries_variant_xs.sv entries_tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv \
              $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_LEAVES) $(BB_DEPS))

# FM: golden EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v vs 可读核 wrapper。黑盒+golden单条目两侧共享。
WRAPPER_SRCS = $(RTL_DIR)/backend/EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))
FM_VARIANTS = EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v
FM_REF_DEPS_EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v = $(GOLDEN_LEAVES) $(BB_DEPS)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# golden(firtool 输出)寄存器无 reset,上电为 X;用 initreg 让两侧都从 0 上电消除假阳性。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
