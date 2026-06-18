MODULE = EntriesAluCsrFenceDiv

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包 + 条目核 + 阵列核 + golden 同名 wrapper(供 FM)。
RTL_SRCS = $(RTL_DIR)/backend/iq_acfd_pkg.sv \
           $(RTL_DIR)/backend/IqEntryAcfd.sv \
           $(RTL_DIR)/backend/EntriesAluCsrFenceDiv.sv

# golden 黑盒(两侧共享):EnqPolicy(转移策略)、UIntCompressor(exuSources 编码)。
BB_DEPS = EnqPolicy.sv UIntCompressor_27_000011100000000000001010101.sv

# golden 单条目(UT u_g 侧 + FM ref 侧)
GOLDEN_LEAVES = EnqEntry_6.sv OthersEntry_66.sv OthersEntry_72.sv

# UT: u_g=golden Entries,u_i=可读核 wrapper(重命名 _xs)。
TB_SRCS = entries_variant_xs.sv entries_tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/EntriesAluCsrFenceDiv.sv \
              $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_LEAVES) $(BB_DEPS))

# FM: golden EntriesAluCsrFenceDiv vs 可读核 wrapper。黑盒+golden单条目两侧共享。
WRAPPER_SRCS = $(RTL_DIR)/backend/EntriesAluCsrFenceDiv_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))
FM_VARIANTS = EntriesAluCsrFenceDiv
FM_REF_DEPS_EntriesAluCsrFenceDiv = $(GOLDEN_LEAVES) $(BB_DEPS)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# golden(chisel firtool 输出)的状态寄存器无 reset,上电为 X;flush 会反复把这些
#   X 衍生值灌进组合输出(deqEntry/cancelDeqVec/EnqSelVec 等空/被冲刷条目的 don't-care 口),
#   造成「golden=defined vs 我=defined」的假阳性。用 initreg 让两侧寄存器都从 0 上电,
#   消除 golden 上电 X 假象后,带 flush 也逐位匹配(seed1/7/42 errors=0)。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
