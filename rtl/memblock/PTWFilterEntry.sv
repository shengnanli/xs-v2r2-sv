// =============================================================================
//  PTWFilterEntry.sv —— dtlb 到 L2TLB 之间的"PTW 请求过滤表"（load 那一张）
// -----------------------------------------------------------------------------
//  位置：MemBlock / PTWNewFilter 里的 load_filter（Chisel: new PTWFilterEntry(Width = LdExuCnt+1 = 4,
//        Size = 16, hasHint = true)）。dtlb_ld 的 4 条 lane 每拍可能各丢来一个 miss 的 vpn
//        （io_tlb_req），本表负责：去重（同一页只向 PTW 要一次）、排队、逐个发给 PTW（io_ptw_req）、
//        PTW 回来后销账并通知 load 流水线"可以重发了"（io_hint）。
//
//  核心机制：
//    · 16 项，每项 = {v, sent, vpn, s2xlate, getGpa}。按 lane 分区：lane i 只能分配 [4i, 4i+3] 这 4 项，
//      分配时选该区里**下标最大的**空项（Chisel firstValidIndex 的 when 链，后写者胜）。
//    · 入表前三道去重：① 本拍正好回来的 PTW 响应已经是这一页 → 不入；② 表里已有同页同 s2xlate 的项
//      → 不入，hint id 指向那一项（下标最大的那一个）；③ 本拍更低 lane 也在送同一页 → 不入，
//      借用那条 lane 的 id / canenq（更低 lane 的结果已经是最终值，链式传递）。
//    · 发 PTW：所有 v && !sent 的项里选下标最大的发出，发出即置 sent。
//    · PTW 回来：所有命中的项（PtwRespS2.hit，与 dtlb 同一个判据）一起清 v；有命中即 refill，
//      hint 回给 load 流水线命中项里下标最大的 id，命中不止一项时 replay_all。
//    · flush：清全部 v（sent/vpn 不动）。
//
//  怪癖（照 golden）：
//    · memidx 字段与 io.memidx 输出在本配置被删（父级不接）；tlb.resp 恒无效（该口在 golden 里不存在）。
//    · inflight_counter（发出-收回的在途计数，异步复位）只喂性能计数器和断言，综合口径下无读者，照抄。
//    · hint 只有 LdExuCnt = 3 路（第 4 条 lane 是预取/杂项口，没有 hint）。
//
//  文件结构（单文件规范）：xs_PTWFilterEntry_core（可读核）→ PTWFilterEntry（golden 同名 wrapper）。
//  共享包 tlbnb_pkg（rtl/memblock/memblock_common_pkg.sv）：hit_key_t 与 ptw_hit()（PtwRespS2.hit 的展开）。
//  子模块：无（golden 0 child）。
//  设计源：src/main/scala/xiangshan/cache/mmu/Repeater.scala（class PTWFilterEntry）
// =============================================================================

// =============================================================================
//  xs_PTWFilterEntry_core —— 可读核
// -----------------------------------------------------------------------------
//  分节：§1 表项  §2 PTW 响应命中  §3 入表（分区选项 + 三道去重）  §4 发 PTW  §5 hint 与输出
//        §6 在途计数（死寄存器）
// =============================================================================
module xs_PTWFilterEntry_core
  import tlbnb_pkg::*;
#(
  parameter int W      = 4,     // 请求 lane 数（LdExuCnt + 1）
  parameter int SIZE   = 16,    // 表项数
  parameter int N_HINT = 3,     // 有 hint 的 lane 数（LdExuCnt）
  localparam int IDX_W  = $clog2(SIZE),
  localparam int PART   = SIZE / W   // 每条 lane 的分区大小（Width=4 时 4 项）
)(
  input  logic                    clock,
  input  logic                    reset,
  input  logic [ASID_W-1:0]       satp_asid,
  input  logic [ASID_W-1:0]       vsatp_asid,
  input  logic [ASID_W-1:0]       hgatp_vmid,
  // dtlb 送来的 miss
  input  logic [W-1:0]            tlb_req_valid,
  input  logic [W-1:0][VPN_W-1:0] tlb_req_vpn,
  input  logic [W-1:0][1:0]       tlb_req_s2xlate,
  input  logic [W-1:0]            tlb_req_get_gpa,
  // 发往 PTW
  input  logic                    ptw_req_ready,
  output logic                    ptw_req_valid,
  output logic [VPN_W-1:0]        ptw_req_vpn,
  output logic [1:0]              ptw_req_s2xlate,
  // PTW 回应（只用到 hit() 要看的那几项）
  input  logic                    ptw_resp_valid,
  input  hit_key_t                ptw_resp,
  // 给 load 流水线的提示
  output logic [N_HINT-1:0][IDX_W-1:0] hint_req_id,
  output logic [N_HINT-1:0]       hint_req_full,
  output logic                    hint_resp_valid,
  output logic [IDX_W-1:0]        hint_resp_id,
  output logic                    hint_resp_replay_all,
  // 其它
  output logic                    rob_head_miss_in_tlb,
  input  logic                    rob_head_vaddr_valid,
  input  logic [VADDR_W-1:0]      rob_head_vaddr,
  input  logic                    flush,
  output logic                    refill,
  output logic                    get_gpa
);

  // firstValidIndex(v, true)：Chisel 的 when 链"后写者胜"，所以是**下标最大**的置位项；全 0 时为 0。
  function automatic logic [IDX_W-1:0] last_set_index(input logic [SIZE-1:0] vec);
    logic [IDX_W-1:0] r;
    r = '0;
    for (int k = 0; k < SIZE; k++)
      if (vec[k]) r = IDX_W'(k);
    return r;
  endfunction

  // ===========================================================================
  // §1 表项：v/sent 异步复位，其余不复位
  // ===========================================================================
  logic [SIZE-1:0] v, sent;
  logic [VPN_W-1:0] vpn     [SIZE];
  logic [1:0]       s2xlate [SIZE];
  logic             getGpa  [SIZE];

  // ===========================================================================
  // §2 PTW 响应命中：表里哪些项正是本拍回来的这一页
  // ===========================================================================
  logic [SIZE-1:0] resp_entry_match;
  for (genvar e = 0; e < SIZE; e++) begin : g_resp_match
    assign resp_entry_match[e] = v[e] & (s2xlate[e] == ptw_resp.s2xlate)
                               & ptw_hit(ptw_resp, vpn[e], satp_asid, vsatp_asid, hgatp_vmid);
  end
  wire [IDX_W-1:0] resp_match_first = last_set_index(resp_entry_match);

  // ===========================================================================
  // §3 入表
  // ===========================================================================
  logic [W-1:0]            resp_req_match;   // 本拍回来的 PTW 响应正是这条请求要的页
  logic [W-1:0]            entry_is_match;   // 表里已有同页同 s2xlate 的项
  logic [W-1:0][IDX_W-1:0] entry_match_idx;
  logic [W-1:0]            canenq, enqvalid;
  logic [W-1:0][IDX_W-1:0] enqidx;

  logic [SIZE-1:0]  match;      // 循环内临时量（每条 lane 重算一次）
  logic [PART-1:0]  part_v;
  logic [IDX_W-1:0] free_idx;
  always_comb begin
    match    = '0;
    part_v   = '0;
    free_idx = '0;
    for (int i = 0; i < W; i++) begin
      resp_req_match[i] = ptw_resp_valid & (tlb_req_s2xlate[i] == ptw_resp.s2xlate)
                        & ptw_hit(ptw_resp, tlb_req_vpn[i], satp_asid, vsatp_asid, hgatp_vmid);
      for (int e = 0; e < SIZE; e++)
        match[e] = v[e] & (s2xlate[e] == tlb_req_s2xlate[i]) & (vpn[e] == tlb_req_vpn[i]);
      entry_is_match[i]  = |match;
      entry_match_idx[i] = last_set_index(match);

      // 本 lane 的分区里有没有空项；有就取下标最大的空项
      part_v   = v[i*PART +: PART];
      free_idx = '0;
      for (int k = 0; k < PART; k++)
        if (!part_v[k]) free_idx = IDX_W'(i*PART + k);
      canenq[i]   = ~&part_v;
      enqvalid[i] = tlb_req_valid[i] & ~resp_req_match[i] & ~entry_is_match[i] & canenq[i];
      enqidx[i]   = enqvalid[i] ? free_idx : entry_match_idx[i];

      // 更低 lane 本拍送的是同一页：不入表，借用它的 id 与 canenq（j 越大越后写，越优先）
      for (int j = 0; j < i; j++) begin
        if (tlb_req_valid[j] & (tlb_req_vpn[i] == tlb_req_vpn[j])
            & (tlb_req_s2xlate[i] == tlb_req_s2xlate[j])) begin
          enqidx[i]   = enqidx[j];
          canenq[i]   = canenq[j];
          enqvalid[i] = 1'b0;
        end
      end
    end
  end

  // ===========================================================================
  // §4 发 PTW：v && !sent 的项里选下标最大的
  // ===========================================================================
  wire [SIZE-1:0]  issue_vec   = v & ~sent;
  wire [IDX_W-1:0] issue_index = last_set_index(issue_vec);
  wire             ptw_req_fire = ptw_req_ready & (|issue_vec);

  assign ptw_req_valid   = |issue_vec;
  assign ptw_req_vpn     = vpn[issue_index];
  assign ptw_req_s2xlate = s2xlate[issue_index];

  // ---- 表项状态更新 ----
  //  同一拍的写入顺序（Scala 的后写者胜）：入表（v=1,sent=0）→ 发出（sent=1）→ PTW 回来销账（v=0）→ flush（v 全清）。
  //  入表的项一定是空项、发出/销账的项一定是有效项，所以前三者不会撞在同一项上。
  for (genvar e = 0; e < SIZE; e++) begin : g_entry
    logic enq_here;
    always_comb begin
      enq_here = 1'b0;
      for (int i = 0; i < W; i++)
        if (enqvalid[i] & (enqidx[i] == IDX_W'(e))) enq_here = 1'b1;
    end

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        v[e]    <= 1'b0;
        sent[e] <= 1'b0;
      end else begin
        if (flush | (ptw_resp_valid & resp_entry_match[e])) v[e] <= 1'b0;
        else if (enq_here)                                  v[e] <= 1'b1;
        if (ptw_req_fire & (issue_index == IDX_W'(e)))      sent[e] <= 1'b1;
        else if (enq_here)                                  sent[e] <= 1'b0;
      end
    end

    // 载荷：同一项最多被一条 lane 写（各 lane 的分区不重叠），lane 顺序写即可
    always_ff @(posedge clock) begin
      for (int i = 0; i < W; i++) begin
        if (enqvalid[i] & (enqidx[i] == IDX_W'(e))) begin
          vpn[e]     <= tlb_req_vpn[i];
          s2xlate[e] <= tlb_req_s2xlate[i];
          getGpa[e]  <= tlb_req_get_gpa[i];
        end
      end
    end
  end

  // ===========================================================================
  // §5 hint 与其它输出
  // ===========================================================================
  for (genvar i = 0; i < N_HINT; i++) begin : g_hint
    assign hint_req_id[i]   = enqidx[i];
    assign hint_req_full[i] = ~canenq[i] | resp_req_match[i];   // 表满或已在路上：别等我，直接重发
  end
  assign refill               = (|resp_entry_match) & ptw_resp_valid;
  assign hint_resp_valid      = refill;
  assign hint_resp_id         = resp_match_first;
  assign hint_resp_replay_all = $countones(resp_entry_match) > 1;
  assign get_gpa              = ptw_resp_valid & getGpa[resp_match_first];

  // topdown 调试：ROB 头的那条指令正卡在本表里等 PTW
  always_comb begin
    rob_head_miss_in_tlb = 1'b0;
    for (int e = 0; e < SIZE; e++)
      if (v[e] & rob_head_vaddr_valid & (vpn[e] == rob_head_vaddr[VADDR_W-1:OFF_W]))
        rob_head_miss_in_tlb = 1'b1;
  end

  // ===========================================================================
  // §6 在途计数：发出 +1、收回 -1、flush 清 0。只喂性能计数器与断言，综合口径下无读者（照抄）。
  // ===========================================================================
  logic [IDX_W-1:0] inflight_counter;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      inflight_counter <= '0;
    else if (flush)
      inflight_counter <= '0;
    else if (ptw_req_fire != ptw_resp_valid)
      inflight_counter <= ptw_req_fire ? IDX_W'(inflight_counter + 1'b1)
                                       : IDX_W'(inflight_counter - 1'b1);
  end

endmodule

// =============================================================================
//  PTWFilterEntry —— golden 同名 wrapper：端口逐位同名同序，只做改名/打包
// =============================================================================
module PTWFilterEntry
  import tlbnb_pkg::*;
(
  // BEGIN GENERATED(ptwfe_ports) —— scripts/gen_mmuleaf.py
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
  input         io_tlb_req_2_valid,
  input  [37:0] io_tlb_req_2_bits_vpn,
  input  [1:0]  io_tlb_req_2_bits_s2xlate,
  input         io_tlb_req_2_bits_getGpa,
  input         io_tlb_req_3_valid,
  input  [37:0] io_tlb_req_3_bits_vpn,
  input  [1:0]  io_tlb_req_3_bits_s2xlate,
  input         io_tlb_req_3_bits_getGpa,
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
  output [3:0]  io_hint_req_0_id,
  output        io_hint_req_0_full,
  output [3:0]  io_hint_req_1_id,
  output        io_hint_req_1_full,
  output [3:0]  io_hint_req_2_id,
  output        io_hint_req_2_full,
  output        io_hint_resp_valid,
  output [3:0]  io_hint_resp_bits_id,
  output        io_hint_resp_bits_replay_all,
  output        io_rob_head_miss_in_tlb,
  input         io_debugTopDown_robHeadVaddr_valid,
  input  [49:0] io_debugTopDown_robHeadVaddr_bits,
  input         io_flush,
  output        io_refill,
  output        io_getGpa
  // END GENERATED
);

  hit_key_t ptw_resp;
  // BEGIN GENERATED(ptwfe_resp) —— scripts/gen_mmuleaf.py
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

  xs_PTWFilterEntry_core #(.W(4), .SIZE(16), .N_HINT(3)) u_core (
    .clock                (clock),
    .reset                (reset),
    .satp_asid            (io_csr_satp_asid),
    .vsatp_asid           (io_csr_vsatp_asid),
    .hgatp_vmid           (io_csr_hgatp_vmid),
    .tlb_req_valid        ({io_tlb_req_3_valid, io_tlb_req_2_valid, io_tlb_req_1_valid, io_tlb_req_0_valid}),
    .tlb_req_vpn          ({io_tlb_req_3_bits_vpn, io_tlb_req_2_bits_vpn,
                            io_tlb_req_1_bits_vpn, io_tlb_req_0_bits_vpn}),
    .tlb_req_s2xlate      ({io_tlb_req_3_bits_s2xlate, io_tlb_req_2_bits_s2xlate,
                            io_tlb_req_1_bits_s2xlate, io_tlb_req_0_bits_s2xlate}),
    .tlb_req_get_gpa      ({io_tlb_req_3_bits_getGpa, io_tlb_req_2_bits_getGpa,
                            io_tlb_req_1_bits_getGpa, io_tlb_req_0_bits_getGpa}),
    .ptw_req_ready        (io_ptw_req_0_ready),
    .ptw_req_valid        (io_ptw_req_0_valid),
    .ptw_req_vpn          (io_ptw_req_0_bits_vpn),
    .ptw_req_s2xlate      (io_ptw_req_0_bits_s2xlate),
    .ptw_resp_valid       (io_ptw_resp_valid),
    .ptw_resp             (ptw_resp),
    .hint_req_id          ({io_hint_req_2_id, io_hint_req_1_id, io_hint_req_0_id}),
    .hint_req_full        ({io_hint_req_2_full, io_hint_req_1_full, io_hint_req_0_full}),
    .hint_resp_valid      (io_hint_resp_valid),
    .hint_resp_id         (io_hint_resp_bits_id),
    .hint_resp_replay_all (io_hint_resp_bits_replay_all),
    .rob_head_miss_in_tlb (io_rob_head_miss_in_tlb),
    .rob_head_vaddr_valid (io_debugTopDown_robHeadVaddr_valid),
    .rob_head_vaddr       (io_debugTopDown_robHeadVaddr_bits),
    .flush                (io_flush),
    .refill               (io_refill),
    .get_gpa              (io_getGpa)
  );

endmodule
