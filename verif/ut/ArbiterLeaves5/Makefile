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

VCS += +define+SYNTHESIS
