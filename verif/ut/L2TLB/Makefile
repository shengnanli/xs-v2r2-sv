MODULE = L2TLB

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 复用的 PTW 类型包 + L2TLB 顶层类型包（核 `include 端口/实例/wire/driven/struct）
RTL_SRCS = $(RTL_DIR)/memblock/ptw_pkg.sv \
           $(RTL_DIR)/memblock/l2tlb_pkg.sv \
           $(RTL_DIR)/memblock/L2TLB.sv

TB_SRCS = variants_xs.sv tb.sv

# golden L2TLB 例化的全部子模块（PTW/LLPTW/HPTW/PtwCache/MissQueue/Prefetch/PMP/
# Arbiter/DelayN/SRAM 等）传递闭包共 30 个 golden 文件。UT 双例化两侧共用这批 golden 子模块。
GOLDEN_SRCS = \
  $(GOLDEN_RTL)/L2TLB.sv \
  $(GOLDEN_RTL)/Arbiter1_L2TLBImp_Anon.sv \
  $(GOLDEN_RTL)/Arbiter2_L2TLBImp_Anon.sv \
  $(GOLDEN_RTL)/Arbiter2_L2TLBImp_Anon_1.sv \
  $(GOLDEN_RTL)/Arbiter2_L2TlbWithHptwIdBundle.sv \
  $(GOLDEN_RTL)/Arbiter2_LLPTW_Anon.sv \
  $(GOLDEN_RTL)/Arbiter2_PtwReq.sv \
  $(GOLDEN_RTL)/Arbiter3_L2TLBImp_Anon.sv \
  $(GOLDEN_RTL)/Arbiter3_L2TlbMemReqBundle.sv \
  $(GOLDEN_RTL)/Arbiter5_L2TlbWithHptwIdBundle.sv \
  $(GOLDEN_RTL)/ClockGate.sv \
  $(GOLDEN_RTL)/DelayN_13.sv \
  $(GOLDEN_RTL)/DelayN_221.sv \
  $(GOLDEN_RTL)/DelayN_222.sv \
  $(GOLDEN_RTL)/HPTW.sv \
  $(GOLDEN_RTL)/L2TlbMissQueue.sv \
  $(GOLDEN_RTL)/L2TlbPrefetch.sv \
  $(GOLDEN_RTL)/LLPTW.sv \
  $(GOLDEN_RTL)/MbistPipePtwL0.sv \
  $(GOLDEN_RTL)/MbistPipePtwL1.sv \
  $(GOLDEN_RTL)/PMP.sv \
  $(GOLDEN_RTL)/PMPChecker.sv \
  $(GOLDEN_RTL)/PTW.sv \
  $(GOLDEN_RTL)/PtwCache.sv \
  $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv \
  $(GOLDEN_RTL)/RRArbiterInit.sv \
  $(GOLDEN_RTL)/SRAMTemplate_122.sv \
  $(GOLDEN_RTL)/SRAMTemplate_126.sv \
  $(GOLDEN_RTL)/SplittedSRAM.sv \
  $(GOLDEN_RTL)/SplittedSRAM_1.sv \
  $(GOLDEN_RTL)/array_10.sv \
  $(GOLDEN_RTL)/array_11.sv \
  $(GOLDEN_RTL)/ram_40x47.sv \
  $(GOLDEN_RTL)/sram_array_1p32x228m114s1h0l1b_ptw_l0.sv \
  $(GOLDEN_RTL)/sram_array_1p8x200m100s1h0l1b_ptw_l1.sv \
  $(GOLDEN_RTL)/array_10_ext.v \
  $(GOLDEN_RTL)/array_11_ext.v

# FM：golden 顶层 L2TLB vs 手写同名 wrapper（→ 可读核）。两侧都读入同一批 golden 子模块，
# 使队列/遍历器实化为同一份定义，FM 真正验证本层 glue（CSR/sfence 复制、仲裁装配、访存
# 数据通路、PTE→sector 合并、perf）相对真实子模块输出是否等价。
GOLDEN_SUBS = $(filter-out $(GOLDEN_RTL)/L2TLB.sv,$(GOLDEN_SRCS))
WRAPPER_SRCS = $(RTL_DIR)/memblock/L2TLB_wrapper.sv $(GOLDEN_SUBS)
FM_VARIANTS = L2TLB
FM_REF_DEPS_L2TLB = $(notdir $(GOLDEN_SUBS))

# 子模块里大量结构相同的表项寄存器，关掉“合并同值重复寄存器”pass。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 子模块含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
# 让 `include 找到 rtl/memblock 下的 .svh（端口/实例/wire/driven/struct 等）
VCS += +incdir+$(RTL_DIR)/memblock
