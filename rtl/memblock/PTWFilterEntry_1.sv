// =============================================================================
//  PTWFilterEntry_1.sv —— PTW 请求过滤表的 store / prefetch 变体（PTWNewFilter 里例化两份）
// -----------------------------------------------------------------------------
//  本变体的参数与规模：Chisel `new PTWFilterEntry(Width = 2, Size = 8)`，hasHint = false。
//    · store_filter：Width = StaCnt = 2，接 dtlb_st 的 2 条 lane（PTWNewFilter 的 tlb_req_4/5）；
//    · prefetch_filter：Width = 2，接 dtlb_pf 的 2 条 lane（tlb_req_6/7）。两者参数相同，firtool 合成同一个模块。
//    · 8 项，按 lane 对半分区：lane 0 只用 [0,3]，lane 1 只用 [4,7]（Scala 的 `Width == 2` 分支，
//      与 Width = 4 时"每 lane 4 项"的通式结果一致，所以复用同一个核）。
//    · golden 1,480 行 / 0 child；寄存器 = v/sent/vpn/s2xlate/getGpa × 8 + 3 位 inflight_counter。
//
//  与 load 那一张（PTWFilterEntry，W=4/SIZE=16/有 hint）的差别只有参数和"没有 hint 口"：
//    入表/去重/发出/回填/flush 的语义完全相同，见核 xs_PTWFilterEntry_core（rtl/memblock/PTWFilterEntry.sv）的头注释。
//  ★hint 怎么处理★：核的 hint 输出按 N_HINT=1 生成，本 wrapper 不接（悬空）。hint 纯组合，
//    只读 enqidx/canenq/命中向量这些本来就要算的量，没有任何寄存器，悬空即被综合删掉 ——
//    golden 里 hasHint=false 时这些线同样不存在。这样就不必为"0 路 hint"去改共享核。
//
//  文件结构：只有 golden 同名 wrapper（变体薄文件，核体在 PTWFilterEntry.sv，不复制）。
//  端口表与 PTW 响应命中键打包在 GENERATED 区（scripts/gen_ptwnewfilter.py）。
//  设计源：src/main/scala/xiangshan/cache/mmu/Repeater.scala（class PTWFilterEntry，Width == 2 分支）
// =============================================================================
module PTWFilterEntry_1
  import tlbnb_pkg::*;
(
  // BEGIN GENERATED(ptwfe1_ports) —— scripts/gen_ptwnewfilter.py
  input         clock,
  input         reset,
  input  [15:0] io_csr_satp_asid,
  input  [15:0] io_csr_vsatp_asid,
  input  [15:0] io_csr_hgatp_vmid,
  input         io_tlb_req_0_valid,
  input  [37:0] io_tlb_req_0_bits_vpn,
  input  [1:0]  io_tlb_req_0_bits_s2xlate,
  input         io_tlb_req_0_bits_getGpa,
  input         io_tlb_req_1_valid,
  input  [37:0] io_tlb_req_1_bits_vpn,
  input  [1:0]  io_tlb_req_1_bits_s2xlate,
  input         io_tlb_req_1_bits_getGpa,
  input         io_ptw_req_0_ready,
  output        io_ptw_req_0_valid,
  output [37:0] io_ptw_req_0_bits_vpn,
  output [1:0]  io_ptw_req_0_bits_s2xlate,
  input         io_ptw_resp_valid,
  input  [1:0]  io_ptw_resp_bits_s2xlate,
  input  [34:0] io_ptw_resp_bits_s1_entry_tag,
  input  [15:0] io_ptw_resp_bits_s1_entry_asid,
  input  [13:0] io_ptw_resp_bits_s1_entry_vmid,
  input         io_ptw_resp_bits_s1_entry_n,
  input         io_ptw_resp_bits_s1_entry_perm_g,
  input  [1:0]  io_ptw_resp_bits_s1_entry_level,
  input  [2:0]  io_ptw_resp_bits_s1_addr_low,
  input         io_ptw_resp_bits_s1_valididx_0,
  input         io_ptw_resp_bits_s1_valididx_1,
  input         io_ptw_resp_bits_s1_valididx_2,
  input         io_ptw_resp_bits_s1_valididx_3,
  input         io_ptw_resp_bits_s1_valididx_4,
  input         io_ptw_resp_bits_s1_valididx_5,
  input         io_ptw_resp_bits_s1_valididx_6,
  input         io_ptw_resp_bits_s1_valididx_7,
  input  [37:0] io_ptw_resp_bits_s2_entry_tag,
  input  [13:0] io_ptw_resp_bits_s2_entry_vmid,
  input         io_ptw_resp_bits_s2_entry_n,
  input  [1:0]  io_ptw_resp_bits_s2_entry_level,
  output        io_rob_head_miss_in_tlb,
  input         io_debugTopDown_robHeadVaddr_valid,
  input  [49:0] io_debugTopDown_robHeadVaddr_bits,
  input         io_flush,
  output        io_refill,
  output        io_getGpa
  // END GENERATED
);

  hit_key_t ptw_resp;
  // BEGIN GENERATED(ptwfe1_resp) —— scripts/gen_ptwnewfilter.py
  assign ptw_resp.s2xlate = io_ptw_resp_bits_s2xlate;
  assign ptw_resp.s1_tag = io_ptw_resp_bits_s1_entry_tag;
  assign ptw_resp.s1_asid = io_ptw_resp_bits_s1_entry_asid;
  assign ptw_resp.s1_vmid = io_ptw_resp_bits_s1_entry_vmid;
  assign ptw_resp.s1_n = io_ptw_resp_bits_s1_entry_n;
  assign ptw_resp.s1_perm_g = io_ptw_resp_bits_s1_entry_perm_g;
  assign ptw_resp.s1_level = io_ptw_resp_bits_s1_entry_level;
  assign ptw_resp.s1_addr_low = io_ptw_resp_bits_s1_addr_low;
  assign ptw_resp.s1_valididx[0] = io_ptw_resp_bits_s1_valididx_0;
  assign ptw_resp.s1_valididx[1] = io_ptw_resp_bits_s1_valididx_1;
  assign ptw_resp.s1_valididx[2] = io_ptw_resp_bits_s1_valididx_2;
  assign ptw_resp.s1_valididx[3] = io_ptw_resp_bits_s1_valididx_3;
  assign ptw_resp.s1_valididx[4] = io_ptw_resp_bits_s1_valididx_4;
  assign ptw_resp.s1_valididx[5] = io_ptw_resp_bits_s1_valididx_5;
  assign ptw_resp.s1_valididx[6] = io_ptw_resp_bits_s1_valididx_6;
  assign ptw_resp.s1_valididx[7] = io_ptw_resp_bits_s1_valididx_7;
  assign ptw_resp.s2_tag = io_ptw_resp_bits_s2_entry_tag;
  assign ptw_resp.s2_vmid = io_ptw_resp_bits_s2_entry_vmid;
  assign ptw_resp.s2_n = io_ptw_resp_bits_s2_entry_n;
  assign ptw_resp.s2_level = io_ptw_resp_bits_s2_entry_level;
  // END GENERATED

  // hint 输出：本变体没有 hint 口，接到这里后不再使用（见文件头）
  logic [0:0][2:0] unused_hint_req_id;
  logic [0:0]      unused_hint_req_full;
  logic            unused_hint_resp_valid;
  logic [2:0]      unused_hint_resp_id;
  logic            unused_hint_resp_replay_all;

  xs_PTWFilterEntry_core #(.W(2), .SIZE(8), .N_HINT(1)) u_core (
    .clock                (clock),
    .reset                (reset),
    .satp_asid            (io_csr_satp_asid),
    .vsatp_asid           (io_csr_vsatp_asid),
    .hgatp_vmid           (io_csr_hgatp_vmid),
    .tlb_req_valid        ({io_tlb_req_1_valid, io_tlb_req_0_valid}),
    .tlb_req_vpn          ({io_tlb_req_1_bits_vpn, io_tlb_req_0_bits_vpn}),
    .tlb_req_s2xlate      ({io_tlb_req_1_bits_s2xlate, io_tlb_req_0_bits_s2xlate}),
    .tlb_req_get_gpa      ({io_tlb_req_1_bits_getGpa, io_tlb_req_0_bits_getGpa}),
    .ptw_req_ready        (io_ptw_req_0_ready),
    .ptw_req_valid        (io_ptw_req_0_valid),
    .ptw_req_vpn          (io_ptw_req_0_bits_vpn),
    .ptw_req_s2xlate      (io_ptw_req_0_bits_s2xlate),
    .ptw_resp_valid       (io_ptw_resp_valid),
    .ptw_resp             (ptw_resp),
    .hint_req_id          (unused_hint_req_id),
    .hint_req_full        (unused_hint_req_full),
    .hint_resp_valid      (unused_hint_resp_valid),
    .hint_resp_id         (unused_hint_resp_id),
    .hint_resp_replay_all (unused_hint_resp_replay_all),
    .rob_head_miss_in_tlb (io_rob_head_miss_in_tlb),
    .rob_head_vaddr_valid (io_debugTopDown_robHeadVaddr_valid),
    .rob_head_vaddr       (io_debugTopDown_robHeadVaddr_bits),
    .flush                (io_flush),
    .refill               (io_refill),
    .get_gpa              (io_getGpa)
  );

endmodule
