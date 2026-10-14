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
  $(XSSV_HOME)/rtl/common/ClockGate.sv \
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

# FM（codex 0228 问题 2，agent/l2tlb-gc，2026-10-11）：★exact green_child 组合★（照 L2Top / Frontend 先例）。
# L2TLB 的 22 种直接 child（29 个实例）都是已独立 official 证明、持有 tracked 证书的 FM target。其中 21 种（28 个实例）
# 两侧以 -interface_only 读入（对称黑盒）；verif/allow/L2TLB.json 逐实例写死 r/i 路径 + child_target + 证书 sha256。
# ★唯一例外 arb1（Arbiter2_PtwReq，两路 TLB 请求的 2 选 1 组合仲裁器）两侧白盒★：canary 1（worktree）实测唯一的
#   failing 是 arb2.io_in_3_valid —— golden 接 arb1.io_out_ready & arb1.io_out_valid（arb1 输出端），重写核写成
#   arb1 两个输入 fire 之或（tlb0_req_fire | tlb1_req_fire，用到了"仲裁器 out.fire = 某个 in.fire"这条仲裁器语义）。
#   arb1 黑盒时这条语义对 FM 不可见，于是报假不等价；白盒时两侧都看得见仲裁器内部（ref 读 golden、impl 读
#   rtl/mmu/Arbiter2_PtwReq.sv 重写件），等价由 FM 直接证。不改 RTL、不加约束。
# 只有 L2TLB 本层 glue（xs_L2TLB_core：请求仲裁/合并、refill/resp 装配、csr/sfence 复制、perf）与 arb1 白盒受验。
#   ref  = golden L2TLB.sv + 22 个 child 的 golden 定义（21 个只取端口，Arbiter2_PtwReq 白盒）；
#   impl = rtl/memblock/L2TLB.sv + 22 个 child 的重写 wrapper（同上；包文件排在引用它的文件之前）。
# FM_INTERFACE_ONLY 恰为这 21 个 design（= allow 里 green_child 的 design 集合，codex 0224 §1）。
# ★ram_40x47 不在 interface_only 里★（0228 §6）：它在 L2TlbMissQueue 子树内部，随 L2TlbMissQueue 一起成为黑盒
#   内部，本层看不见；边界由 L2TlbMissQueue 自己的证明按 APPROVED_MEMORY_MACRO_MODEL（对称未解析黑盒）承担。
# 上一轮（agent/l2tlb-assembly 第 3 轮）的「child 两侧 golden 白盒 + 147 条钉点」路线作废：那是 POLICY.freeze_commit
# 为 null 时的权宜（green_child 当时过不了闸），0224 rolling current-valid 落地后不再需要；0228 明令不恢复 child 内部配对。
# UT（VCS）不变：RTL_GOLDEN_DEPS 仍是 golden child 全闭包、两侧共用。
FM_VARIANTS = L2TLB
# ★字面文件名★（fm_passing_model 静态解析）：本层 glue 例化到的 22 个 golden child（21 个 interface-only + arb1 白盒）。
FM_REF_DEPS_L2TLB = \
  Arbiter1_L2TLBImp_Anon.sv \
  Arbiter2_L2TLBImp_Anon.sv \
  Arbiter2_L2TLBImp_Anon_1.sv \
  Arbiter2_L2TlbWithHptwIdBundle.sv \
  Arbiter2_PtwReq.sv \
  Arbiter3_bitmapReqBundle.sv \
  Arbiter3_L2TLBImp_Anon.sv \
  Arbiter4_L2TlbMemReqBundle.sv \
  Arbiter5_L2TlbWithHptwIdBundle.sv \
  Bitmap.sv \
  BitmapCache.sv \
  DelayN_13.sv \
  DelayN_220.sv \
  DelayN_221.sv \
  HPTW.sv \
  L2TlbMissQueue.sv \
  L2TlbPrefetch.sv \
  LLPTW.sv \
  PMP.sv \
  PMPChecker.sv \
  PTW.sv \
  PtwCache.sv
FM_IMPL_RTL = \
  $(XSSV_HOME)/rtl/mmu/mmu_common_pkg.sv \
  $(XSSV_HOME)/rtl/mmu/Arbiter1_L2TLBImp_Anon.sv \
  $(XSSV_HOME)/rtl/mmu/Arbiter2_L2TLBImp_Anon.sv \
  $(XSSV_HOME)/rtl/mmu/Arbiter2_L2TLBImp_Anon_1.sv \
  $(XSSV_HOME)/rtl/mmu/Arbiter2_L2TlbWithHptwIdBundle.sv \
  $(XSSV_HOME)/rtl/mmu/Arbiter2_PtwReq.sv \
  $(XSSV_HOME)/rtl/mmu/Arbiter3_bitmapReqBundle.sv \
  $(XSSV_HOME)/rtl/mmu/Arbiter3_L2TLBImp_Anon.sv \
  $(XSSV_HOME)/rtl/mmu/Arbiter4_L2TlbMemReqBundle.sv \
  $(XSSV_HOME)/rtl/mmu/Arbiter5_L2TlbWithHptwIdBundle.sv \
  $(XSSV_HOME)/rtl/mmu/Bitmap.sv \
  $(XSSV_HOME)/rtl/mmu/BitmapCache.sv \
  $(XSSV_HOME)/rtl/common/DelayN_13.sv \
  $(XSSV_HOME)/rtl/common/DelayN_220.sv \
  $(XSSV_HOME)/rtl/common/DelayN_221.sv \
  $(XSSV_HOME)/rtl/mmu/HPTW.sv \
  $(XSSV_HOME)/rtl/memblock/L2TlbMissQueue.sv \
  $(XSSV_HOME)/rtl/memblock/L2TlbPrefetch.sv \
  $(XSSV_HOME)/rtl/mmu/LLPTW.sv \
  $(XSSV_HOME)/rtl/memblock/PMP.sv \
  $(XSSV_HOME)/rtl/backend/PMPChecker.sv \
  $(XSSV_HOME)/rtl/mmu/PTW.sv \
  $(XSSV_HOME)/rtl/mmu/PtwCache.sv \
  $(XSSV_HOME)/rtl/memblock/L2TLB.sv
fm-L2TLB: RTL_SRCS = $(FM_IMPL_RTL)
fm-L2TLB: RTL_GOLDEN_DEPS =
FM_INTERFACE_ONLY = Arbiter1_L2TLBImp_Anon Arbiter2_L2TLBImp_Anon Arbiter2_L2TLBImp_Anon_1 Arbiter2_L2TlbWithHptwIdBundle Arbiter3_bitmapReqBundle Arbiter3_L2TLBImp_Anon Arbiter4_L2TlbMemReqBundle Arbiter5_L2TlbWithHptwIdBundle Bitmap BitmapCache DelayN_13 DelayN_220 DelayN_221 HPTW L2TlbMissQueue L2TlbPrefetch LLPTW PMP PMPChecker PTW PtwCache
FM_MODE = assembly
# 合并重复寄存器：开（与上一轮同理）。golden 把 CSR/sfence 复制成 10/11 份、每份被 firtool 按消费者裁成字段子集；
# 重写核 csr_dup[i] / sfence_dup[i] 每份都是完整 struct。不合并则重写侧多出来的字段副本在 golden 里没有对应。
# 代价：fm_predict 只给上界带。
FM_MERGE_DUP = true
# vmucp：开（verif/fm_target_config/L2TLB.tcl 有依据）。child 全部黑盒后，上一轮那批 child 内部 matched-unread
# 不复存在；本层若仍有 matched-unread，按 standing rule 逐条核双射后由 vmucp 实开比较。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden 子模块里的 XSError/XSPerf/assert 段（`ifndef SYNTHESIS）调用 xs_assert_v2，
# UT 两侧统一定义 SYNTHESIS 关掉，否则随机激励会触发 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

# ★本 UT 的两档 initreg 是 0 与 1，**不是** 0 与 random★（2026-09-20 实测定的）
#
# 双例化比对的前提是"同激励 + **同初态**"。`+vcs+initreg+random` 是
# **按实例**各摇各的：u_g.ptw 与 u_i.u_core.u_ptw 是两个不同实例，未复位寄存器
# 拿到不同随机值，于是两侧从一开始就不在同一个状态上。实测（seed=2）：
#     P2 g.tag=0dc7f7ee8f i.tag=26ff00d6fe      <- 复位刚撤、暖机之前
#     vec 12 io_tlb_0_resp_bits_s2_entry_tag g=0dc7f7ee8f i=26ff00d6fe
# 一模一样的两个数——失配就是这个未复位寄存器直通到输出：
#     PTW.sv:769  reg [37:0] hptw_resp_entry_tag;   （复位块里没有它）
#     PTW.sv:1991 assign io_resp_bits_h_resp_entry_tag = gvpn_gpf ? gpaddr[49:12]
#                                                      : hptw_resp_entry_tag;
# ★而 PTW 是 **golden 子模块**，两侧例化的是同一份定义★——差异与重写无关，
# 是 harness 的性质。40 seed × 50k 实测：+random 有 21/32 报错，
# 同样这些 seed 在 +0 和 +1 下 errors 全是 0。
#
# +0 / +1 都是常量档：两侧必然同初态，且两档确实不同（实测
#     +0: g.tag=0000000000 i.tag=0000000000
#     +1: g.tag=3fffffffff i.tag=3fffffffff ）
# 用 `make run INITREG=1` / `INITREG=0`，日志分别存成 sim_<seed>_initreg1.log
# 与 sim_<seed>_initreg0.log（ut_common.mk 的 INITREG_TAG 已加 +1 这一档）。
# 探针可复跑：./simv +ntb_random_seed=<n> +ncycles=100 +vcs+initreg+<档> +initreg_probe
INITREG ?= 0
