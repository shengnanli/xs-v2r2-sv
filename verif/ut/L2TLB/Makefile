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

# PtwCache/PTW/LLPTW/HPTW/L2TlbMissQueue/L2TlbPrefetch 两侧读同一份 golden，用
# interface_only 在边界处黑盒:只保留端口方向、不展开内部。否则 FM 会在
# u_core/u_page_cache 等 6 个子模块与 golden 同名实例之间逐位比对 ~85600 个内部
# 寄存器(u_page_cache 单个就 80882 个)——顶层实例名不同(golden cache/ptw/…
# vs impl u_page_cache/u_ptw/…)+ 内部层次/展平差异令绝大多数无法配对,余下按输入
# 锥比对时因顶层 glue 边界不同而大批误判失配(5000 failing 全在这 6 个子模块内)+
# 剩下的拖成 unverified。L2TLB 是装配层,重写工作在顶层 glue(CSR/sfence 复制、仲裁
# 装配、访存数据通路、PTE→sector 合并、perf);各子模块有独立 UT/FM。黑盒后 FM 只
# 比顶层 glue 相对子模块 边界引脚 的等价 —— 即真正的重写对象。
FM_INTERFACE_ONLY = PtwCache PTW LLPTW HPTW L2TlbMissQueue L2TlbPrefetch PMP

# 子模块 interface_only 黑盒后内部寄存器不再参与比对,反而需要开启「合并同值重复
# 寄存器」:golden 顶层把 CSR/sfence/resp_pte 等 glue 寄存器复制成多副本,impl 合并
# 成单寄存器,开启合并后 golden 多副本归一才能与 impl 单寄存器等价配对。
FM_MERGE_DUP = true

include ../../../scripts/ut_common.mk

# golden 子模块含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
# 让 `include 找到 rtl/memblock 下的 .svh（端口/实例/wire/driven/struct 等）
VCS += +incdir+$(RTL_DIR)/memblock
