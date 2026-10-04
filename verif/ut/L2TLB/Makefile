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
# 子模块（UNCHANGED_GOLDEN_DEP，两侧同源）。
#
# ★2026-10-03 第 3 轮（agent/l2tlb-assembly）：8 个大 child 从「两侧对称黑盒」改为
#  「两侧白盒展开」★
# 原配置把 PtwCache/PTW/LLPTW/HPTW/L2TlbMissQueue/L2TlbPrefetch/Bitmap/BitmapCache
# 两侧黑盒，靠 verif/allow/L2TLB.json 的 green_child 声明挂条件绿。截至 main 3cd47062
# 这 8 个 child 都已各自签核（receipt 闭包与当前字节逐个核过，见
# docs/lanes/l2tlb-assembly_prereg.md），但 green_child 这条路**在本仓当前状态下走不通**：
# proof_certificate.py 要求 child 证书 impl_commit == POLICY.json 的 freeze_commit，
# 而 freeze_commit 仍是 null（fail-closed，全部拒绝）—— 那是 integrator 的冻结动作，
# 不是本 lane 能改的。于是照 CtrlBlock 第 2 轮的先例：child 两侧白盒展开（同一份
# golden 定义），黑盒只剩不可 inline 的存储宏行为模型。
# 这样证明**更强**：child 内部每一个寄存器与输出都进比较，本层 glue 驱动 child 输入
# 的路径不再止于黑盒输入引脚，而是一直比到 child 内部状态。
#
# 唯一保留的黑盒：ram_40x47（L2TlbMissQueue 里 Queue40 的 ram_ext）。
# 深度 40 / 6 位地址，inline 会触发 FMR_ELAB-147（越界静态下标）→ set_top 失败；
# 已在 verif/vendor_boundary.tsv 以 APPROVED_MEMORY_MACRO_MODEL 单条审定
# （codex 0158 §1，symmetric_both_sides_only），本目标两侧各 1 个实例、对称黑盒，
# 声明在 verif/allow/L2TLB.json。L2TlbMissQueue 自己的证明用的是同一条边界。
#
# PMP / PMPChecker / 各 Arbiter / DelayN 与以前一样两侧展开（golden 定义，两侧同源）。
# ★本轮不把 impl 侧 child 换成重写件★（main 6a06215f 曾试把 PMP 换成重写件，FM 不收敛已 revert）。
FM_VARIANTS = L2TLB
# ★字面文件名★（fm_passing_model 不展开 make 函数；与 RTL_GOLDEN_DEPS 逐项相同）
FM_REF_DEPS_L2TLB = \
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

# 合并重复寄存器：开（与以前一样）。golden 把 CSR/sfence 复制成 10/11 份、每份被 firtool
# 按消费者裁成字段子集（csr_dup_0 15 个字段、csr_dup_5 只 4 个……）；重写核 csr_dup[i] /
# sfence_dup[i] 每份都是完整 struct。不合并，重写侧多出来的字段副本在 golden 里没有对应；
# 合并后同输入的副本各自归一，两侧才能配对。代价：fm_predict 模型只给上界带，不给点值。
FM_MERGE_DUP = true

# ★vmucp（verify_matched_unread_compare_points）= true★（2026-09-21 打开）
# 第一次跑（未开）留下 809 个 matched-unread 点，全部是 PMP 内 pmaMapping_* 那批
# 本层锥内无读者的寄存器，ref `pmp/<X>` ↔ impl `u_core/u_pmp/<X>` 后缀逐字相同、
# 809↔809 双射，无任何人工强配。打开 = 让 FM 把这 809 点也证一遍（更严，不是放松）。
# 白名单条目与逐条依据在 verif/fm_target_config/L2TLB.tcl（没有那份文件就不在白名单上）。
# ★第 3 轮（child 白盒化）先关掉跑一遍★：unread 集合会随 8 个 child 展开而变，按 standing
# rule 先拿到不开时的 matched-unread 清单逐条核双射（第 3 次跑 413461528f8f：1288 对，1144 对后缀逐字
# 相同/csr_dup 字段对应 + 144 对 fm_pins.tcl 钉点），再打开并核 passing 正好增 unread 数。
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
