MODULE = CsrLeaves14

RTL_DIR = ../../../rtl
LEAVES = cycleModule instretModule HipModule HieModule HgeieModule \
         MscratchModule SscratchModule VSscratchModule MnscratchModule \
         Dscratch0Module Dscratch1Module ScontextModule TselectModule \
         PrivilegePermitModule
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
#   INITREG=0 / random / <seed>017（第三个真随机档）
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
