MODULE = ArbiterLeaves5

RTL_DIR = ../../../rtl
LEAVES = Arbiter2_L2TLBImp_Anon Arbiter2_PtwReq Arbiter2_LLPTW_Anon \
         Arbiter2_L2TlbWithHptwIdBundle Arbiter4_L2CacheErrorInfo
RTL_SRCS = $(addprefix $(RTL_DIR)/mmu/,$(addsuffix .sv,$(wordlist 1,4,$(LEAVES)))) \
           $(RTL_DIR)/l2/Arbiter4_L2CacheErrorInfo.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 两轮 initreg（CONVENTIONS「+vcs+initreg 的正确用法」）：编译期打开机制，运行期选取值。
# 本 UT 是 golden 与 *_xs 双例化：+vcs+initreg+random 会给两个实例各摇各的初值，
# 不复位寄存器两侧初态不同 => 假失配。所以两档用常量：make run INITREG=0 / INITREG=1。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
