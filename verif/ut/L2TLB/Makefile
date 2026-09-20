MODULE = L2TLB

RTL_DIR = ../../../rtl
# 单文件规范：package + 可读核 + golden 同名 wrapper 全在 L2TLB.sv 一个文件里。
RTL_SRCS = $(RTL_DIR)/memblock/L2TLB.sv

TB_SRCS = tb.sv

# golden L2TLB 例化的全部子模块（PTW/LLPTW/HPTW/PtwCache/MissQueue/Prefetch/PMP/
# Bitmap/BitmapCache/Arbiter/DelayN/SRAM）的传递闭包：46 个 .sv + 3 个厂商 SRAM 行为
# 模型 .v。UT 双例化两侧共用这批 golden 子模块（同一份定义，不派生不改名）。
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

GOLDEN_SRCS = $(GOLDEN_RTL)/L2TLB.sv $(RTL_GOLDEN_DEPS)

# FM：golden 顶层 L2TLB 为 ref，重写的同名 wrapper 为 impl；两侧读入同一批 golden
# 子模块，于是队列/遍历器/SRAM 在两侧实化成同一份定义，FM 真正验证的是**本层 glue**
# （CSR/sfence 复制扇出、仲裁装配、访存数据通路、PTE→sector 合并、bitmap 接线、perf）。
FM_VARIANTS = L2TLB
FM_REF_DEPS_L2TLB = $(notdir $(RTL_GOLDEN_DEPS))

# ★assembly 模式★：把带内部状态的大子模块在**两侧对称**黑盒（只留端口方向）。
# 理由：L2TLB 是装配层，重写对象是顶层 glue；这些子模块各自是独立 FM target，内部
# 等价由它们自己的证明负责。不黑盒的话 FM 会去逐位配对 PtwCache 一个模块里 8 万多个
# 内部寄存器——顶层实例名与内部层次两侧不同，绝大多数配不上，剩下的按输入锥比会大批
# 误判，证明本身就没意义了。
#
# ★诚实声明★：这批黑盒目前**都还没有本轮的独立签核**（PtwCache / PTW / LLPTW /
# HPTW / L2TlbMissQueue / L2TlbPrefetch / Bitmap / BitmapCache 在本轮台账里
# 都是 MISSING）。所以本目标即便 native SUCCEEDED，也只能算**条件绿**，
# 要等这 8 个 child 各自 SIGNOFF_PASS 之后才能计入闭包。
#
# ★2026-09-20 复核修正：把 PMP 从本表里去掉★
# 落地这份 Makefile 时表里有 9 项（多一个 PMP），而同一个 commit 登记的
# docs/l2tlb_fm_prediction.md 预测的是 **8 个黑盒**，并白纸黑字写着
# 「PMP / PMPChecker / 各 Arbiter / DelayN 是两侧 elaborate（不黑盒），
#   这是照搬 G0 那次成功证明的配置」，预测里 ~1000 条 unread 也全部外推自
# **被展开的** PMP 的 pmaMapping 死寄存器。两者互相矛盾，跑之前必须选一个。
#
# 查 G0 那次证明的原始配置（可复跑核对，不是转述）：
#   $ grep FM_INTERFACE_ONLY /home/eda/xs-env/xs-v2r2-sv/scripts/sidecar/\
#       signoff-evidence-delta2/L2TLB/make.out
#   FM_INTERFACE_ONLY="PtwCache PTW LLPTW HPTW L2TlbMissQueue L2TlbPrefetch"
#   （6 项，**没有 PMP**；同目录 native_facts.json 的 537 条 unread 全是
#    r:/WORK/L2TLB/pmp/pmaMapping_*_reg[*] ↔ i:/.../u_pmp/pmaMapping_*_reg[*]
#    的**配对**点 —— 能配上对，正说明 PMP 当时是两侧展开的。）
#
# 按预测 + G0 实证取 8 项。方向也对：黑盒**少**一个 = 证明**强**一分
# （PMP 内部路径从"只比端口"变成逐位比对），而且 PMP 不是厂商宏、
# 本轮也没有独立签核，按黑盒边界审核判据它本来就不该随手黑盒。
FM_INTERFACE_ONLY = PtwCache PTW LLPTW HPTW L2TlbMissQueue L2TlbPrefetch Bitmap BitmapCache

# 子模块黑盒后内部寄存器不参与比对，需要开「合并同值重复寄存器」：golden 顶层把
# CSR/sfence 复制成 10/11 份，impl 侧同样复制；开启合并让两侧的多副本各自归一后配对。
FM_MERGE_DUP = true

include ../../../scripts/ut_common.mk

# golden 子模块里的 XSError/XSPerf/assert 段（`ifndef SYNTHESIS）调用 xs_assert_v2，
# UT 两侧统一定义 SYNTHESIS 关掉，否则随机激励会触发 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
INITREG ?= random
