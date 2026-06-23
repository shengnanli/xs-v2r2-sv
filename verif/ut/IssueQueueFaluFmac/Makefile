MODULE = EntriesFaluFmac

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包 + 条目核 + 阵列核(供 UT u_i 侧 + FM impl 侧)。
RTL_SRCS = $(RTL_DIR)/backend/iq_ffmac_pkg.sv \
           $(RTL_DIR)/backend/IqEntryFfmac.sv \
           $(RTL_DIR)/backend/EntriesFaluFmac.sv

# golden 黑盒(两侧共享):EnqPolicy_8(转移策略)、UIntCompressor(exuSources 编码)。
BB_DEPS = EnqPolicy_8.sv UIntCompressor_27_000000000000001010100000000.sv

# golden 单条目(UT u_g 侧 + FM ref 侧)
GOLDEN_LEAVES = EnqEntry_12.sv OthersEntry_120.sv OthersEntry_122.sv

# UT: u_g=golden Entries,u_i=可读核 wrapper(重命名 _xs)。
TB_SRCS = entries_variant_xs.sv entries_tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/EntriesFaluFmac.sv \
              $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_LEAVES) $(BB_DEPS))

# FM: golden EntriesFaluFmac vs 可读核 wrapper。黑盒+golden单条目两侧共享。
WRAPPER_SRCS = $(RTL_DIR)/backend/EntriesFaluFmac_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))
FM_VARIANTS = EntriesFaluFmac
FM_REF_DEPS_EntriesFaluFmac = $(GOLDEN_LEAVES) $(BB_DEPS)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# golden(chisel firtool 输出)的状态寄存器无 reset,上电为 X;用 initreg 让两侧寄存器
# 都从 0 上电,消除 golden 上电 X 假象后,带 flush 也逐位匹配(seed1/7/42 errors=0)。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
