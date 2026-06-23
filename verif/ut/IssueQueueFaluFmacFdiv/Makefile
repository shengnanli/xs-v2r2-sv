MODULE = EntriesFaluFmacFdiv

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包 + 条目核 + 阵列核(供 UT u_i 侧 + FM impl 侧)。
RTL_SRCS = $(RTL_DIR)/backend/iq_ffmacfdiv_pkg.sv \
           $(RTL_DIR)/backend/IqEntryFfmacFdiv.sv \
           $(RTL_DIR)/backend/EntriesFaluFmacFdiv.sv

# golden 黑盒(两侧共享):EnqPolicy_8(转移策略)、UIntCompressor(exuSources 编码)。
BB_DEPS = EnqPolicy_8.sv UIntCompressor_27_000000000000001010100000000.sv

# golden 单条目(UT u_g 侧 + FM ref 侧)
GOLDEN_LEAVES = EnqEntry_10.sv OthersEntry_104.sv OthersEntry_106.sv

# UT: u_g=golden Entries,u_i=可读核 wrapper(重命名 _xs)。
TB_SRCS = entries_variant_xs.sv entries_tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/EntriesFaluFmacFdiv.sv \
              $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_LEAVES) $(BB_DEPS))

# FM: golden EntriesFaluFmacFdiv vs 可读核 wrapper。黑盒+golden单条目两侧共享。
WRAPPER_SRCS = $(RTL_DIR)/backend/EntriesFaluFmacFdiv_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))
FM_VARIANTS = EntriesFaluFmacFdiv
FM_REF_DEPS_EntriesFaluFmacFdiv = $(GOLDEN_LEAVES) $(BB_DEPS)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# golden(chisel firtool 输出)状态寄存器无 reset,上电为 X;用 initreg 让两侧从 0 上电。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
