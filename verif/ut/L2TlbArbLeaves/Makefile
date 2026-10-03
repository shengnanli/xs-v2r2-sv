MODULE = L2TlbArbLeaves

# L2TLB 的 5 个无状态仲裁器叶子（lane l2tlb-leaves）：
#   Arbiter1_L2TLBImp_Anon          outArb(i)，单入口直通
#   Arbiter2_L2TLBImp_Anon_1        hptw_resp_arb，out.ready 恒 1
#   Arbiter3_bitmapReqBundle        bitmap_arb
#   Arbiter4_L2TlbMemReqBundle      mem_arb
#   Arbiter5_L2TlbWithHptwIdBundle  arb2（带 io_chosen）
# 2 路及以上用已签核核 xs_FixedPriorityArbiter_core；薄文件由 scripts/gen_arbiter_l2tlb_leaves.py 生成。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/mmu/Arbiter1_L2TLBImp_Anon.sv \
           $(RTL_DIR)/mmu/Arbiter2_L2TLBImp_Anon_1.sv \
           $(RTL_DIR)/mmu/Arbiter3_bitmapReqBundle.sv \
           $(RTL_DIR)/mmu/Arbiter4_L2TlbMemReqBundle.sv \
           $(RTL_DIR)/mmu/Arbiter5_L2TlbWithHptwIdBundle.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Arbiter1_L2TLBImp_Anon.sv \
              $(GOLDEN_RTL)/Arbiter2_L2TLBImp_Anon_1.sv \
              $(GOLDEN_RTL)/Arbiter3_bitmapReqBundle.sv \
              $(GOLDEN_RTL)/Arbiter4_L2TlbMemReqBundle.sv \
              $(GOLDEN_RTL)/Arbiter5_L2TlbWithHptwIdBundle.sv
FM_VARIANTS = Arbiter1_L2TLBImp_Anon Arbiter2_L2TLBImp_Anon_1 Arbiter3_bitmapReqBundle \
              Arbiter4_L2TlbMemReqBundle Arbiter5_L2TlbWithHptwIdBundle
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
