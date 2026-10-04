MODULE = L2TLBWrapper

# L2TLB 的 LazyModule 外壳：端口直通 + 19 个 perf 计数打两拍。文件由 scripts/gen_l2tlbwrapper.py 生成。
#
# ★2026-10-03 第 3 轮（agent/l2tlb-assembly）：L2TLB 从「两侧对称黑盒」改为「两侧白盒」★
#   · ref  = golden L2TLBWrapper + golden L2TLB + golden child 闭包；
#   · impl = 重写 L2TLBWrapper（rtl/mmu/L2TLBWrapper.sv）+ **重写 L2TLB**（rtl/memblock/L2TLB.sv）
#            + 同一份 golden child 闭包（UNCHANGED_GOLDEN_DEP，两侧同源）。
#   原因：green_child 证书路线要求 child 证书 impl_commit == POLICY.freeze_commit，而
#   freeze_commit 仍为 null（fail-closed），L2TLB 无论签没签都背书不了本层；照 CtrlBlock
#   第 2 轮先例改白盒，本证明于是同时覆盖外壳 glue 与 L2TLB 本层 glue（重写件在位）。
#   黑盒只剩 ram_40x47（L2TlbMissQueue 内存储宏行为模型，vendor_boundary.tsv 已审定
#   APPROVED_MEMORY_MACRO_MODEL），两侧各 1 个，声明在 verif/allow/L2TLBWrapper.json。
#   · UT：双例化 golden 外壳(golden L2TLB) vs 重写外壳(重写 L2TLB；derive 改名为 L2TLB_xs)，
#     child 两侧共用 golden 定义。child 内大量不复位寄存器/SRAM 在 +vcs+initreg+random 下按实例
#     各摇各的，与外壳无关地失配，所以按 L2TLB 的先例只跑 INITREG=0 / 1 两个常量档。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/mmu/L2TLBWrapper.sv $(RTL_DIR)/memblock/L2TLB.sv
TB_SRCS  = tb.sv

# L2TLB 的 golden child 传递闭包（与 verif/ut/L2TLB 的 RTL_GOLDEN_DEPS 逐项相同）：两侧共用。
RTL_GOLDEN_DEPS = \
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

GOLDEN_SRCS = $(GOLDEN_RTL)/L2TLBWrapper.sv $(GOLDEN_RTL)/L2TLB.sv $(RTL_GOLDEN_DEPS)
FM_VARIANTS = L2TLBWrapper
# ★字面文件名★（fm_passing_model 不展开 make 函数）
FM_REF_DEPS_L2TLBWrapper = \
  L2TLB.sv \
  Arbiter1_L2TLBImp_Anon.sv \
  Arbiter2_L2TLBImp_Anon.sv \
  Arbiter2_L2TLBImp_Anon_1.sv \
  Arbiter2_L2TlbWithHptwIdBundle.sv \
  Arbiter2_LLPTW_Anon.sv \
  Arbiter2_PtwReq.sv \
  Arbiter3_L2TLBImp_Anon.sv \
  Arbiter3_bitmapReqBundle.sv \
  Arbiter4_L2TlbMemReqBundle.sv \
  Arbiter5_L2TlbWithHptwIdBundle.sv \
  Arbiter8_bitmapCacheReqBundle.sv \
  Bitmap.sv \
  BitmapCache.sv \
  ClockGate.sv \
  DelayN_13.sv \
  DelayN_220.sv \
  DelayN_221.sv \
  HPTW.sv \
  L2TlbMissQueue.sv \
  L2TlbPrefetch.sv \
  LLPTW.sv \
  MbistBitmapCache.sv \
  MbistPipePtwL0.sv \
  MbistPipePtwL1.sv \
  PMP.sv \
  PMPChecker.sv \
  PTW.sv \
  PtwCache.sv \
  Queue40_L2TlbMQBundle.sv \
  RRArbiterInit.sv \
  RRArbiterInit_1.sv \
  RRArbiterInit_4.sv \
  SRAMTemplate_124.sv \
  SRAMTemplate_128.sv \
  SRAMTemplate_129.sv \
  SRAMTemplate_143.sv \
  SplittedSRAM.sv \
  SplittedSRAM_1.sv \
  SplittedSRAM_2.sv \
  array_10.sv \
  array_11.sv \
  array_9.sv \
  ram_40x47.sv \
  sram_array_1p32x90m45s1h0l1b_bitmap.sv \
  sram_array_1p4x786m131s1h0l1b_ptw_l1.sv \
  sram_array_1p64x114m57s1h0l1b_ptw_l0.sv \
  array_10_ext.v \
  array_11_ext.v \
  array_9_ext.v
FM_INTERFACE_ONLY = ram_40x47
# 合并重复寄存器：开（与 verif/ut/L2TLB 同理：重写 L2TLB 的 csr_dup[i]/sfence_dup[i] 每份是完整
# struct，golden 的每份副本被 firtool 按消费者裁成字段子集；不合并则重写侧多出的字段副本无对应）。
FM_MERGE_DUP = true
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

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
