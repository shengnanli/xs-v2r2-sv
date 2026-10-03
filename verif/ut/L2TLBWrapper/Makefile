MODULE = L2TLBWrapper

# L2TLB 的 LazyModule 外壳：端口直通 + 19 个 perf 计数打两拍。文件由 scripts/gen_l2tlbwrapper.py 生成。
# 子模块 L2TLB 是独立目标（rtl/memblock/L2TLB.sv，本仓现状：REWRITTEN / FM 条件绿，8 个 child 未签）：
#   · FM：assembly 模式，L2TLB 两侧对称黑盒（FM_INTERFACE_ONLY），声明在 verif/allow/L2TLBWrapper.json；
#     impl 侧只读 golden L2TLB.sv 的接口（RTL_GOLDEN_DEPS），本层只证 glue；
#   · UT：双例化两侧都用 golden L2TLB 闭包（L2TLB_GOLDEN_CLOSURE，不进 FM），只比外壳的 glue。
#     两个 L2TLB 实例内部有大量不复位寄存器/SRAM，+vcs+initreg+random 会让两实例初态不同、与外壳无关地失配，
#     所以本 UT 按 L2TLB 的先例跑 INITREG=0 / 1 两个常量档（外壳自己的 38 个不复位 perf 寄存器在 tb 里对齐初值）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/mmu/L2TLBWrapper.sv
TB_SRCS  = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/L2TLB.sv
L2TLB_GOLDEN_CLOSURE = \
  $(GOLDEN_RTL)/Arbiter1_L2TLBImp_Anon.sv \
  $(GOLDEN_RTL)/Arbiter2_L2TLBImp_Anon.sv \
  $(GOLDEN_RTL)/Arbiter2_L2TLBImp_Anon_1.sv \
  $(GOLDEN_RTL)/Arbiter2_L2TlbWithHptwIdBundle.sv \
  $(GOLDEN_RTL)/Arbiter2_LLPTW_Anon.sv \
  $(GOLDEN_RTL)/Arbiter2_PtwReq.sv \
  $(GOLDEN_RTL)/Arbiter3_L2TLBImp_Anon.sv \
  $(GOLDEN_RTL)/Arbiter3_bitmapReqBundle.sv \
  $(GOLDEN_RTL)/Arbiter4_L2TlbMemReqBundle.sv \
  $(GOLDEN_RTL)/Arbiter5_L2TlbWithHptwIdBundle.sv \
  $(GOLDEN_RTL)/Arbiter8_bitmapCacheReqBundle.sv \
  $(GOLDEN_RTL)/Bitmap.sv \
  $(GOLDEN_RTL)/BitmapCache.sv \
  $(GOLDEN_RTL)/ClockGate.sv \
  $(GOLDEN_RTL)/DelayN_13.sv \
  $(GOLDEN_RTL)/DelayN_220.sv \
  $(GOLDEN_RTL)/DelayN_221.sv \
  $(GOLDEN_RTL)/HPTW.sv \
  $(GOLDEN_RTL)/L2TlbMissQueue.sv \
  $(GOLDEN_RTL)/L2TlbPrefetch.sv \
  $(GOLDEN_RTL)/LLPTW.sv \
  $(GOLDEN_RTL)/MbistBitmapCache.sv \
  $(GOLDEN_RTL)/MbistPipePtwL0.sv \
  $(GOLDEN_RTL)/MbistPipePtwL1.sv \
  $(GOLDEN_RTL)/PMP.sv \
  $(GOLDEN_RTL)/PMPChecker.sv \
  $(GOLDEN_RTL)/PTW.sv \
  $(GOLDEN_RTL)/PtwCache.sv \
  $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv \
  $(GOLDEN_RTL)/RRArbiterInit.sv \
  $(GOLDEN_RTL)/RRArbiterInit_1.sv \
  $(GOLDEN_RTL)/RRArbiterInit_4.sv \
  $(GOLDEN_RTL)/SRAMTemplate_124.sv \
  $(GOLDEN_RTL)/SRAMTemplate_128.sv \
  $(GOLDEN_RTL)/SRAMTemplate_129.sv \
  $(GOLDEN_RTL)/SRAMTemplate_143.sv \
  $(GOLDEN_RTL)/SplittedSRAM.sv \
  $(GOLDEN_RTL)/SplittedSRAM_1.sv \
  $(GOLDEN_RTL)/SplittedSRAM_2.sv \
  $(GOLDEN_RTL)/array_10.sv \
  $(GOLDEN_RTL)/array_11.sv \
  $(GOLDEN_RTL)/array_9.sv \
  $(GOLDEN_RTL)/ram_40x47.sv \
  $(GOLDEN_RTL)/sram_array_1p32x90m45s1h0l1b_bitmap.sv \
  $(GOLDEN_RTL)/sram_array_1p4x786m131s1h0l1b_ptw_l1.sv \
  $(GOLDEN_RTL)/sram_array_1p64x114m57s1h0l1b_ptw_l0.sv \
  $(GOLDEN_RTL)/array_10_ext.v \
  $(GOLDEN_RTL)/array_11_ext.v \
  $(GOLDEN_RTL)/array_9_ext.v

GOLDEN_SRCS = $(GOLDEN_RTL)/L2TLBWrapper.sv $(RTL_GOLDEN_DEPS) $(L2TLB_GOLDEN_CLOSURE)
FM_VARIANTS = L2TLBWrapper
FM_REF_DEPS_L2TLBWrapper = L2TLB.sv
FM_INTERFACE_ONLY = L2TLB
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
