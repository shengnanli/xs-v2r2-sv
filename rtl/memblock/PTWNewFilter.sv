// =============================================================================
//  PTWNewFilter.sv —— dtlb 与 L2TLB 之间的 PTW 请求过滤器（MemBlock 的 dtlbRepeater）
// -----------------------------------------------------------------------------
//  位置：MemBlock 里三组 dtlb（load 4 lane / store 2 lane / prefetch 2 lane，共 8 条 miss 请求口
//        io_tlb_req_0..7）与 L2TLB（io_ptw）之间。Chisel: new PTWNewFilter(Width = 8, Size, FenceDelay = 2)。
//  它做四件事（本文件按这四件事分节）：
//    ① 入表/去重：三张过滤表各管一组 lane —— load 表（PTWFilterEntry，16 项、带 hint）收 req 0..3，
//       store 表 / prefetch 表（PTWFilterEntry_1，各 8 项）分别收 req 4..5 / 6..7。同一页只向 PTW 要一次。
//    ② 仲裁发出：三张表各自挑一项待发请求，经 3 路轮转仲裁器（RRArbiterInit_12）合成唯一的 io_ptw_req。
//    ③ 响应回填：L2TLB 的响应先在本层打一拍（载荷 RegEnable、valid 每表一份 RegNext），再同时广播给三张表；
//       各表命中即销账并报 refill。io_tlb_resp = 打拍后的响应载荷，valid = 任一表 refill，
//       vector 标出是哪一组 dtlb 的表命中（golden 只剩 vector_0/4/6 三位，即每组的第一个口）。
//       load 表的 hint（"该 lane 去等哪一项" / "哪一项回来了"）再打一拍送给 load 流水线。
//    ④ flush：sfence 或 satp/vsatp/hgatp/virt 变化 → 经 DelayN_1 延迟 2 拍 → 清三张表的 v。
//
//  怪癖（照 golden）：
//    · 响应载荷寄存器无复位、只在 io_ptw_resp.valid 时更新（ready 恒 1，fire == valid）；
//      三张表的 resp.valid 各打一份拍（同值的三个异步复位寄存器，Chisel 的 filter.map(RegNext(...))），一份不少。
//    · io_tlb_resp 的载荷在 valid=0 时照样输出寄存器里的旧值；memidx/getGpa(data) 在本配置被删。
//    · hint.resp.bits 是 RegEnable（只在 load 表 hint.resp.valid 时更新），hint.req 与 hint.resp.valid 是普通 RegNext，
//      都无复位。
//
//  文件结构（单文件规范）：xs_PTWNewFilter_core（可读核）→ PTWNewFilter（golden 同名 wrapper）。
//  共享包 tlbnb_pkg（rtl/memblock/memblock_common_pkg.sv）：ptw_s1_t / ptw_s2_t（PTW 响应的 s1/s2 两半）。
//  子模块（两侧白盒，都已单独签核）：PTWFilterEntry ×1、PTWFilterEntry_1 ×2、DelayN_1、RRArbiterInit_12。
//  机械派生区（wrapper 端口表/打包/展平，核里三张表与仲裁器的逐口连线）由 scripts/gen_ptwnewfilter.py 生成。
//  设计源：src/main/scala/xiangshan/cache/mmu/Repeater.scala（class PTWNewFilter）
// =============================================================================

// =============================================================================
//  xs_PTWNewFilter_core —— 可读核
// -----------------------------------------------------------------------------
//  分节：§1 flush 延迟  §2 PTW 响应打拍  §3 三张过滤表（入表/去重/回填）  §4 仲裁发出
//        §5 回给 dtlb 的响应  §6 load hint 打拍  §7 topdown
// =============================================================================
module xs_PTWNewFilter_core
  import tlbnb_pkg::*;
#(
  parameter int N_REQ  = 8,   // dtlb miss 请求口总数：load 0..3 / store 4..5 / prefetch 6..7
  parameter int N_FILT = 3,   // 过滤表数：0 = load、1 = store、2 = prefetch（也是仲裁器的输入顺序）
  parameter int N_HINT = 3,   // load 表的 hint lane 数（LdExuCnt）
  parameter int HINT_W = 4    // load 表 16 项的下标宽度
)(
  input  logic                        clock,
  input  logic                        reset,
  // flush 源
  input  logic                        sfence_valid,
  input  logic                        satp_changed,
  input  logic                        vsatp_changed,
  input  logic                        hgatp_changed,
  input  logic                        priv_virt_changed,
  input  logic [ASID_W-1:0]           satp_asid,
  input  logic [ASID_W-1:0]           vsatp_asid,
  input  logic [ASID_W-1:0]           hgatp_vmid,
  // dtlb 送来的 miss（8 口）
  input  logic [N_REQ-1:0]            tlb_req_valid,
  input  logic [N_REQ-1:0][VPN_W-1:0] tlb_req_vpn,
  input  logic [N_REQ-1:0][1:0]       tlb_req_s2xlate,
  input  logic [N_REQ-1:0]            tlb_req_get_gpa,
  // 回给 dtlb 的响应
  output logic                        tlb_resp_valid,
  output logic [1:0]                  tlb_resp_s2xlate,
  output ptw_s1_t                     tlb_resp_s1,
  output ptw_s2_t                     tlb_resp_s2,
  output logic [N_FILT-1:0]           tlb_resp_vector,    // 每张表一位：本拍是它命中
  output logic [N_FILT-1:0]           tlb_resp_get_gpa,
  // 发往 L2TLB
  input  logic                        ptw_req_ready,
  output logic                        ptw_req_valid,
  output logic [VPN_W-1:0]            ptw_req_vpn,
  output logic [1:0]                  ptw_req_s2xlate,
  // L2TLB 的响应（ready 恒 1）
  input  logic                        ptw_resp_valid,
  input  logic [1:0]                  ptw_resp_s2xlate,
  input  ptw_s1_t                     ptw_resp_s1,
  input  ptw_s2_t                     ptw_resp_s2,
  // 给 load 流水线的 hint
  output logic [N_HINT-1:0][HINT_W-1:0] hint_req_id,
  output logic [N_HINT-1:0]           hint_req_full,
  output logic                        hint_resp_valid,
  output logic [HINT_W-1:0]           hint_resp_id,
  output logic                        hint_resp_replay_all,
  // topdown
  output logic                        rob_head_miss_in_tlb,
  input  logic                        rob_head_vaddr_valid,
  input  logic [VADDR_W-1:0]          rob_head_vaddr
);

  // ===========================================================================
  // §1 flush：任一种地址空间变化 → 延迟 FenceDelay = 2 拍 → 三张表清 v
  // ===========================================================================
  logic flush;
  DelayN_1 flush_delay (
    .clock  (clock),
    .io_in  (sfence_valid | satp_changed | vsatp_changed | hgatp_changed | priv_virt_changed),
    .io_out (flush)
  );

  // ===========================================================================
  // §2 PTW 响应打拍：载荷在 valid 时锁存（无复位），valid 给每张表各打一拍（异步复位）
  //    三张表看到的都是上一拍的响应；io_tlb_resp 的载荷也直接取这组寄存器。
  // ===========================================================================
  logic [1:0]        resp_s2xlate_q;
  ptw_s1_t           resp_s1_q;
  ptw_s2_t           resp_s2_q;
  logic [N_FILT-1:0] resp_valid_q;    // [0] load 表 / [1] store 表 / [2] prefetch 表，三份同值

  always_ff @(posedge clock) begin
    if (ptw_resp_valid) begin
      resp_s2xlate_q <= ptw_resp_s2xlate;
      resp_s1_q      <= ptw_resp_s1;
      resp_s2_q      <= ptw_resp_s2;
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) resp_valid_q <= '0;
    else       resp_valid_q <= {N_FILT{ptw_resp_valid}};
  end

  // ===========================================================================
  // §3 三张过滤表：入表/去重/发出候选/回填销账都在表内完成（见 PTWFilterEntry.sv 的核）
  //    每张表对外：一个待发请求（filt_req_*）、本拍 refill、refill 那一项的 getGpa、topdown 命中。
  // ===========================================================================
  logic [N_FILT-1:0]            filt_req_valid;
  logic [N_FILT-1:0]            filt_req_ready;     // 仲裁器选中它且下游收下
  logic [N_FILT-1:0][VPN_W-1:0] filt_req_vpn;
  logic [N_FILT-1:0][1:0]       filt_req_s2xlate;
  logic [N_FILT-1:0]            filt_refill;
  logic [N_FILT-1:0]            filt_get_gpa;
  logic [N_FILT-1:0]            filt_rob_head_miss;

  // load 表的 hint（组合），§6 打一拍后输出
  logic [N_HINT-1:0][HINT_W-1:0] load_hint_req_id;
  logic [N_HINT-1:0]             load_hint_req_full;
  logic                          load_hint_resp_valid;
  logic [HINT_W-1:0]             load_hint_resp_id;
  logic                          load_hint_resp_replay_all;

  // ---- load 表：req 0..3，16 项，带 hint ----
  // BEGIN GENERATED(pnf_load_filter) —— scripts/gen_ptwnewfilter.py
  PTWFilterEntry load_filter (
    .clock                              (clock),
    .reset                              (reset),
    .io_csr_satp_asid                   (satp_asid),
    .io_csr_vsatp_asid                  (vsatp_asid),
    .io_csr_hgatp_vmid                  (hgatp_vmid),
    .io_tlb_req_0_valid                 (tlb_req_valid[0]),
    .io_tlb_req_0_bits_vpn              (tlb_req_vpn[0]),
    .io_tlb_req_0_bits_s2xlate          (tlb_req_s2xlate[0]),
    .io_tlb_req_0_bits_getGpa           (tlb_req_get_gpa[0]),
    .io_tlb_req_1_valid                 (tlb_req_valid[1]),
    .io_tlb_req_1_bits_vpn              (tlb_req_vpn[1]),
    .io_tlb_req_1_bits_s2xlate          (tlb_req_s2xlate[1]),
    .io_tlb_req_1_bits_getGpa           (tlb_req_get_gpa[1]),
    .io_tlb_req_2_valid                 (tlb_req_valid[2]),
    .io_tlb_req_2_bits_vpn              (tlb_req_vpn[2]),
    .io_tlb_req_2_bits_s2xlate          (tlb_req_s2xlate[2]),
    .io_tlb_req_2_bits_getGpa           (tlb_req_get_gpa[2]),
    .io_tlb_req_3_valid                 (tlb_req_valid[3]),
    .io_tlb_req_3_bits_vpn              (tlb_req_vpn[3]),
    .io_tlb_req_3_bits_s2xlate          (tlb_req_s2xlate[3]),
    .io_tlb_req_3_bits_getGpa           (tlb_req_get_gpa[3]),
    .io_ptw_req_0_ready                 (filt_req_ready[0]),
    .io_ptw_req_0_valid                 (filt_req_valid[0]),
    .io_ptw_req_0_bits_vpn              (filt_req_vpn[0]),
    .io_ptw_req_0_bits_s2xlate          (filt_req_s2xlate[0]),
    .io_ptw_resp_valid                  (resp_valid_q[0]),
    .io_ptw_resp_bits_s2xlate           (resp_s2xlate_q),
    .io_ptw_resp_bits_s1_entry_tag      (resp_s1_q.entry_tag),
    .io_ptw_resp_bits_s1_entry_asid     (resp_s1_q.entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid     (resp_s1_q.entry_vmid),
    .io_ptw_resp_bits_s1_entry_n        (resp_s1_q.entry_n),
    .io_ptw_resp_bits_s1_entry_perm_g   (resp_s1_q.entry_perm_g),
    .io_ptw_resp_bits_s1_entry_level    (resp_s1_q.entry_level),
    .io_ptw_resp_bits_s1_addr_low       (resp_s1_q.addr_low),
    .io_ptw_resp_bits_s1_valididx_0     (resp_s1_q.valididx[0]),
    .io_ptw_resp_bits_s1_valididx_1     (resp_s1_q.valididx[1]),
    .io_ptw_resp_bits_s1_valididx_2     (resp_s1_q.valididx[2]),
    .io_ptw_resp_bits_s1_valididx_3     (resp_s1_q.valididx[3]),
    .io_ptw_resp_bits_s1_valididx_4     (resp_s1_q.valididx[4]),
    .io_ptw_resp_bits_s1_valididx_5     (resp_s1_q.valididx[5]),
    .io_ptw_resp_bits_s1_valididx_6     (resp_s1_q.valididx[6]),
    .io_ptw_resp_bits_s1_valididx_7     (resp_s1_q.valididx[7]),
    .io_ptw_resp_bits_s2_entry_tag      (resp_s2_q.entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid     (resp_s2_q.entry_vmid),
    .io_ptw_resp_bits_s2_entry_n        (resp_s2_q.entry_n),
    .io_ptw_resp_bits_s2_entry_level    (resp_s2_q.entry_level),
    .io_hint_req_0_id                   (load_hint_req_id[0]),
    .io_hint_req_0_full                 (load_hint_req_full[0]),
    .io_hint_req_1_id                   (load_hint_req_id[1]),
    .io_hint_req_1_full                 (load_hint_req_full[1]),
    .io_hint_req_2_id                   (load_hint_req_id[2]),
    .io_hint_req_2_full                 (load_hint_req_full[2]),
    .io_hint_resp_valid                 (load_hint_resp_valid),
    .io_hint_resp_bits_id               (load_hint_resp_id),
    .io_hint_resp_bits_replay_all       (load_hint_resp_replay_all),
    .io_rob_head_miss_in_tlb            (filt_rob_head_miss[0]),
    .io_debugTopDown_robHeadVaddr_valid (rob_head_vaddr_valid),
    .io_debugTopDown_robHeadVaddr_bits  (rob_head_vaddr),
    .io_flush                           (flush),
    .io_refill                          (filt_refill[0]),
    .io_getGpa                          (filt_get_gpa[0])
  );
  // END GENERATED

  // ---- store 表：req 4..5，8 项 ----
  // BEGIN GENERATED(pnf_store_filter) —— scripts/gen_ptwnewfilter.py
  PTWFilterEntry_1 store_filter (
    .clock                              (clock),
    .reset                              (reset),
    .io_csr_satp_asid                   (satp_asid),
    .io_csr_vsatp_asid                  (vsatp_asid),
    .io_csr_hgatp_vmid                  (hgatp_vmid),
    .io_tlb_req_0_valid                 (tlb_req_valid[4]),
    .io_tlb_req_0_bits_vpn              (tlb_req_vpn[4]),
    .io_tlb_req_0_bits_s2xlate          (tlb_req_s2xlate[4]),
    .io_tlb_req_0_bits_getGpa           (tlb_req_get_gpa[4]),
    .io_tlb_req_1_valid                 (tlb_req_valid[5]),
    .io_tlb_req_1_bits_vpn              (tlb_req_vpn[5]),
    .io_tlb_req_1_bits_s2xlate          (tlb_req_s2xlate[5]),
    .io_tlb_req_1_bits_getGpa           (tlb_req_get_gpa[5]),
    .io_ptw_req_0_ready                 (filt_req_ready[1]),
    .io_ptw_req_0_valid                 (filt_req_valid[1]),
    .io_ptw_req_0_bits_vpn              (filt_req_vpn[1]),
    .io_ptw_req_0_bits_s2xlate          (filt_req_s2xlate[1]),
    .io_ptw_resp_valid                  (resp_valid_q[1]),
    .io_ptw_resp_bits_s2xlate           (resp_s2xlate_q),
    .io_ptw_resp_bits_s1_entry_tag      (resp_s1_q.entry_tag),
    .io_ptw_resp_bits_s1_entry_asid     (resp_s1_q.entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid     (resp_s1_q.entry_vmid),
    .io_ptw_resp_bits_s1_entry_n        (resp_s1_q.entry_n),
    .io_ptw_resp_bits_s1_entry_perm_g   (resp_s1_q.entry_perm_g),
    .io_ptw_resp_bits_s1_entry_level    (resp_s1_q.entry_level),
    .io_ptw_resp_bits_s1_addr_low       (resp_s1_q.addr_low),
    .io_ptw_resp_bits_s1_valididx_0     (resp_s1_q.valididx[0]),
    .io_ptw_resp_bits_s1_valididx_1     (resp_s1_q.valididx[1]),
    .io_ptw_resp_bits_s1_valididx_2     (resp_s1_q.valididx[2]),
    .io_ptw_resp_bits_s1_valididx_3     (resp_s1_q.valididx[3]),
    .io_ptw_resp_bits_s1_valididx_4     (resp_s1_q.valididx[4]),
    .io_ptw_resp_bits_s1_valididx_5     (resp_s1_q.valididx[5]),
    .io_ptw_resp_bits_s1_valididx_6     (resp_s1_q.valididx[6]),
    .io_ptw_resp_bits_s1_valididx_7     (resp_s1_q.valididx[7]),
    .io_ptw_resp_bits_s2_entry_tag      (resp_s2_q.entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid     (resp_s2_q.entry_vmid),
    .io_ptw_resp_bits_s2_entry_n        (resp_s2_q.entry_n),
    .io_ptw_resp_bits_s2_entry_level    (resp_s2_q.entry_level),
    .io_rob_head_miss_in_tlb            (filt_rob_head_miss[1]),
    .io_debugTopDown_robHeadVaddr_valid (rob_head_vaddr_valid),
    .io_debugTopDown_robHeadVaddr_bits  (rob_head_vaddr),
    .io_flush                           (flush),
    .io_refill                          (filt_refill[1]),
    .io_getGpa                          (filt_get_gpa[1])
  );
  // END GENERATED

  // ---- prefetch 表：req 6..7，8 项 ----
  // BEGIN GENERATED(pnf_prefetch_filter) —— scripts/gen_ptwnewfilter.py
  PTWFilterEntry_1 prefetch_filter (
    .clock                              (clock),
    .reset                              (reset),
    .io_csr_satp_asid                   (satp_asid),
    .io_csr_vsatp_asid                  (vsatp_asid),
    .io_csr_hgatp_vmid                  (hgatp_vmid),
    .io_tlb_req_0_valid                 (tlb_req_valid[6]),
    .io_tlb_req_0_bits_vpn              (tlb_req_vpn[6]),
    .io_tlb_req_0_bits_s2xlate          (tlb_req_s2xlate[6]),
    .io_tlb_req_0_bits_getGpa           (tlb_req_get_gpa[6]),
    .io_tlb_req_1_valid                 (tlb_req_valid[7]),
    .io_tlb_req_1_bits_vpn              (tlb_req_vpn[7]),
    .io_tlb_req_1_bits_s2xlate          (tlb_req_s2xlate[7]),
    .io_tlb_req_1_bits_getGpa           (tlb_req_get_gpa[7]),
    .io_ptw_req_0_ready                 (filt_req_ready[2]),
    .io_ptw_req_0_valid                 (filt_req_valid[2]),
    .io_ptw_req_0_bits_vpn              (filt_req_vpn[2]),
    .io_ptw_req_0_bits_s2xlate          (filt_req_s2xlate[2]),
    .io_ptw_resp_valid                  (resp_valid_q[2]),
    .io_ptw_resp_bits_s2xlate           (resp_s2xlate_q),
    .io_ptw_resp_bits_s1_entry_tag      (resp_s1_q.entry_tag),
    .io_ptw_resp_bits_s1_entry_asid     (resp_s1_q.entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid     (resp_s1_q.entry_vmid),
    .io_ptw_resp_bits_s1_entry_n        (resp_s1_q.entry_n),
    .io_ptw_resp_bits_s1_entry_perm_g   (resp_s1_q.entry_perm_g),
    .io_ptw_resp_bits_s1_entry_level    (resp_s1_q.entry_level),
    .io_ptw_resp_bits_s1_addr_low       (resp_s1_q.addr_low),
    .io_ptw_resp_bits_s1_valididx_0     (resp_s1_q.valididx[0]),
    .io_ptw_resp_bits_s1_valididx_1     (resp_s1_q.valididx[1]),
    .io_ptw_resp_bits_s1_valididx_2     (resp_s1_q.valididx[2]),
    .io_ptw_resp_bits_s1_valididx_3     (resp_s1_q.valididx[3]),
    .io_ptw_resp_bits_s1_valididx_4     (resp_s1_q.valididx[4]),
    .io_ptw_resp_bits_s1_valididx_5     (resp_s1_q.valididx[5]),
    .io_ptw_resp_bits_s1_valididx_6     (resp_s1_q.valididx[6]),
    .io_ptw_resp_bits_s1_valididx_7     (resp_s1_q.valididx[7]),
    .io_ptw_resp_bits_s2_entry_tag      (resp_s2_q.entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid     (resp_s2_q.entry_vmid),
    .io_ptw_resp_bits_s2_entry_n        (resp_s2_q.entry_n),
    .io_ptw_resp_bits_s2_entry_level    (resp_s2_q.entry_level),
    .io_rob_head_miss_in_tlb            (filt_rob_head_miss[2]),
    .io_debugTopDown_robHeadVaddr_valid (rob_head_vaddr_valid),
    .io_debugTopDown_robHeadVaddr_bits  (rob_head_vaddr),
    .io_flush                           (flush),
    .io_refill                          (filt_refill[2]),
    .io_getGpa                          (filt_get_gpa[2])
  );
  // END GENERATED

  // ===========================================================================
  // §4 仲裁发出：三张表的待发请求 3 选 1（轮转，复位后从 0 号开始），直连 io_ptw_req
  // ===========================================================================
  // BEGIN GENERATED(pnf_ptw_arb) —— scripts/gen_ptwnewfilter.py
  RRArbiterInit_12 ptw_arb (
    .clock                (clock),
    .reset                (reset),
    .io_in_0_ready        (filt_req_ready[0]),
    .io_in_0_valid        (filt_req_valid[0]),
    .io_in_0_bits_vpn     (filt_req_vpn[0]),
    .io_in_0_bits_s2xlate (filt_req_s2xlate[0]),
    .io_in_1_ready        (filt_req_ready[1]),
    .io_in_1_valid        (filt_req_valid[1]),
    .io_in_1_bits_vpn     (filt_req_vpn[1]),
    .io_in_1_bits_s2xlate (filt_req_s2xlate[1]),
    .io_in_2_ready        (filt_req_ready[2]),
    .io_in_2_valid        (filt_req_valid[2]),
    .io_in_2_bits_vpn     (filt_req_vpn[2]),
    .io_in_2_bits_s2xlate (filt_req_s2xlate[2]),
    .io_out_ready         (ptw_req_ready),
    .io_out_valid         (ptw_req_valid),
    .io_out_bits_vpn      (ptw_req_vpn),
    .io_out_bits_s2xlate  (ptw_req_s2xlate)
  );
  // END GENERATED

  // ===========================================================================
  // §5 回给 dtlb 的响应：载荷 = 打拍后的 PTW 响应；valid = 任一张表本拍 refill
  // ===========================================================================
  assign tlb_resp_valid   = |filt_refill;
  assign tlb_resp_s2xlate = resp_s2xlate_q;
  assign tlb_resp_s1      = resp_s1_q;
  assign tlb_resp_s2      = resp_s2_q;
  assign tlb_resp_vector  = filt_refill;
  assign tlb_resp_get_gpa = filt_get_gpa;

  // ===========================================================================
  // §6 load hint 打拍：req 与 resp.valid 是 RegNext；resp.bits 只在 resp.valid 时更新。都无复位。
  // ===========================================================================
  logic [N_HINT-1:0][HINT_W-1:0] hint_req_id_q;
  logic [N_HINT-1:0]             hint_req_full_q;
  logic                          hint_resp_valid_q;
  logic [HINT_W-1:0]             hint_resp_id_q;
  logic                          hint_resp_replay_all_q;

  always_ff @(posedge clock) begin
    hint_req_id_q     <= load_hint_req_id;
    hint_req_full_q   <= load_hint_req_full;
    hint_resp_valid_q <= load_hint_resp_valid;
    if (load_hint_resp_valid) begin
      hint_resp_id_q         <= load_hint_resp_id;
      hint_resp_replay_all_q <= load_hint_resp_replay_all;
    end
  end

  assign hint_req_id          = hint_req_id_q;
  assign hint_req_full        = hint_req_full_q;
  assign hint_resp_valid      = hint_resp_valid_q;
  assign hint_resp_id         = hint_resp_id_q;
  assign hint_resp_replay_all = hint_resp_replay_all_q;

  // ===========================================================================
  // §7 topdown：ROB 头那条指令的页正卡在任一张表里
  // ===========================================================================
  assign rob_head_miss_in_tlb = |filt_rob_head_miss;

endmodule

// =============================================================================
//  PTWNewFilter —— golden 同名 wrapper：端口逐位同名同序，只做改名/打包/展平
// =============================================================================
module PTWNewFilter
  import tlbnb_pkg::*;
(
  // BEGIN GENERATED(pnf_ports) —— scripts/gen_ptwnewfilter.py
  input         clock,
  input         reset,
  input         io_sfence_valid,
  input  [15:0] io_csr_satp_asid,
  input         io_csr_satp_changed,
  input  [15:0] io_csr_vsatp_asid,
  input         io_csr_vsatp_changed,
  input  [15:0] io_csr_hgatp_vmid,
  input         io_csr_hgatp_changed,
  input         io_csr_priv_virt_changed,
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
  input         io_tlb_req_4_valid,
  input  [37:0] io_tlb_req_4_bits_vpn,
  input  [1:0]  io_tlb_req_4_bits_s2xlate,
  input         io_tlb_req_4_bits_getGpa,
  input         io_tlb_req_5_valid,
  input  [37:0] io_tlb_req_5_bits_vpn,
  input  [1:0]  io_tlb_req_5_bits_s2xlate,
  input         io_tlb_req_5_bits_getGpa,
  input         io_tlb_req_6_valid,
  input  [37:0] io_tlb_req_6_bits_vpn,
  input  [1:0]  io_tlb_req_6_bits_s2xlate,
  input         io_tlb_req_6_bits_getGpa,
  input         io_tlb_req_7_valid,
  input  [37:0] io_tlb_req_7_bits_vpn,
  input  [1:0]  io_tlb_req_7_bits_s2xlate,
  input         io_tlb_req_7_bits_getGpa,
  output        io_tlb_resp_valid,
  output [1:0]  io_tlb_resp_bits_data_s2xlate,
  output [34:0] io_tlb_resp_bits_data_s1_entry_tag,
  output [15:0] io_tlb_resp_bits_data_s1_entry_asid,
  output [13:0] io_tlb_resp_bits_data_s1_entry_vmid,
  output        io_tlb_resp_bits_data_s1_entry_n,
  output [1:0]  io_tlb_resp_bits_data_s1_entry_pbmt,
  output        io_tlb_resp_bits_data_s1_entry_perm_d,
  output        io_tlb_resp_bits_data_s1_entry_perm_a,
  output        io_tlb_resp_bits_data_s1_entry_perm_g,
  output        io_tlb_resp_bits_data_s1_entry_perm_u,
  output        io_tlb_resp_bits_data_s1_entry_perm_x,
  output        io_tlb_resp_bits_data_s1_entry_perm_w,
  output        io_tlb_resp_bits_data_s1_entry_perm_r,
  output [1:0]  io_tlb_resp_bits_data_s1_entry_level,
  output        io_tlb_resp_bits_data_s1_entry_v,
  output [40:0] io_tlb_resp_bits_data_s1_entry_ppn,
  output [2:0]  io_tlb_resp_bits_data_s1_addr_low,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_0,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_1,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_2,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_3,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_4,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_5,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_6,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_7,
  output        io_tlb_resp_bits_data_s1_valididx_0,
  output        io_tlb_resp_bits_data_s1_valididx_1,
  output        io_tlb_resp_bits_data_s1_valididx_2,
  output        io_tlb_resp_bits_data_s1_valididx_3,
  output        io_tlb_resp_bits_data_s1_valididx_4,
  output        io_tlb_resp_bits_data_s1_valididx_5,
  output        io_tlb_resp_bits_data_s1_valididx_6,
  output        io_tlb_resp_bits_data_s1_valididx_7,
  output        io_tlb_resp_bits_data_s1_pteidx_0,
  output        io_tlb_resp_bits_data_s1_pteidx_1,
  output        io_tlb_resp_bits_data_s1_pteidx_2,
  output        io_tlb_resp_bits_data_s1_pteidx_3,
  output        io_tlb_resp_bits_data_s1_pteidx_4,
  output        io_tlb_resp_bits_data_s1_pteidx_5,
  output        io_tlb_resp_bits_data_s1_pteidx_6,
  output        io_tlb_resp_bits_data_s1_pteidx_7,
  output        io_tlb_resp_bits_data_s1_pf,
  output        io_tlb_resp_bits_data_s1_af,
  output [37:0] io_tlb_resp_bits_data_s2_entry_tag,
  output [13:0] io_tlb_resp_bits_data_s2_entry_vmid,
  output        io_tlb_resp_bits_data_s2_entry_n,
  output [1:0]  io_tlb_resp_bits_data_s2_entry_pbmt,
  output [37:0] io_tlb_resp_bits_data_s2_entry_ppn,
  output        io_tlb_resp_bits_data_s2_entry_perm_d,
  output        io_tlb_resp_bits_data_s2_entry_perm_a,
  output        io_tlb_resp_bits_data_s2_entry_perm_g,
  output        io_tlb_resp_bits_data_s2_entry_perm_u,
  output        io_tlb_resp_bits_data_s2_entry_perm_x,
  output        io_tlb_resp_bits_data_s2_entry_perm_w,
  output        io_tlb_resp_bits_data_s2_entry_perm_r,
  output [1:0]  io_tlb_resp_bits_data_s2_entry_level,
  output        io_tlb_resp_bits_data_s2_gpf,
  output        io_tlb_resp_bits_data_s2_gaf,
  output        io_tlb_resp_bits_vector_0,
  output        io_tlb_resp_bits_vector_4,
  output        io_tlb_resp_bits_vector_6,
  output        io_tlb_resp_bits_getGpa_0,
  output        io_tlb_resp_bits_getGpa_4,
  output        io_tlb_resp_bits_getGpa_6,
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
  input  [1:0]  io_ptw_resp_bits_s1_entry_pbmt,
  input         io_ptw_resp_bits_s1_entry_perm_d,
  input         io_ptw_resp_bits_s1_entry_perm_a,
  input         io_ptw_resp_bits_s1_entry_perm_g,
  input         io_ptw_resp_bits_s1_entry_perm_u,
  input         io_ptw_resp_bits_s1_entry_perm_x,
  input         io_ptw_resp_bits_s1_entry_perm_w,
  input         io_ptw_resp_bits_s1_entry_perm_r,
  input  [1:0]  io_ptw_resp_bits_s1_entry_level,
  input         io_ptw_resp_bits_s1_entry_v,
  input  [40:0] io_ptw_resp_bits_s1_entry_ppn,
  input  [2:0]  io_ptw_resp_bits_s1_addr_low,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_0,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_1,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_2,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_3,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_4,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_5,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_6,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_7,
  input         io_ptw_resp_bits_s1_valididx_0,
  input         io_ptw_resp_bits_s1_valididx_1,
  input         io_ptw_resp_bits_s1_valididx_2,
  input         io_ptw_resp_bits_s1_valididx_3,
  input         io_ptw_resp_bits_s1_valididx_4,
  input         io_ptw_resp_bits_s1_valididx_5,
  input         io_ptw_resp_bits_s1_valididx_6,
  input         io_ptw_resp_bits_s1_valididx_7,
  input         io_ptw_resp_bits_s1_pteidx_0,
  input         io_ptw_resp_bits_s1_pteidx_1,
  input         io_ptw_resp_bits_s1_pteidx_2,
  input         io_ptw_resp_bits_s1_pteidx_3,
  input         io_ptw_resp_bits_s1_pteidx_4,
  input         io_ptw_resp_bits_s1_pteidx_5,
  input         io_ptw_resp_bits_s1_pteidx_6,
  input         io_ptw_resp_bits_s1_pteidx_7,
  input         io_ptw_resp_bits_s1_pf,
  input         io_ptw_resp_bits_s1_af,
  input  [37:0] io_ptw_resp_bits_s2_entry_tag,
  input  [13:0] io_ptw_resp_bits_s2_entry_vmid,
  input         io_ptw_resp_bits_s2_entry_n,
  input  [1:0]  io_ptw_resp_bits_s2_entry_pbmt,
  input  [37:0] io_ptw_resp_bits_s2_entry_ppn,
  input         io_ptw_resp_bits_s2_entry_perm_d,
  input         io_ptw_resp_bits_s2_entry_perm_a,
  input         io_ptw_resp_bits_s2_entry_perm_g,
  input         io_ptw_resp_bits_s2_entry_perm_u,
  input         io_ptw_resp_bits_s2_entry_perm_x,
  input         io_ptw_resp_bits_s2_entry_perm_w,
  input         io_ptw_resp_bits_s2_entry_perm_r,
  input  [1:0]  io_ptw_resp_bits_s2_entry_level,
  input         io_ptw_resp_bits_s2_gpf,
  input         io_ptw_resp_bits_s2_gaf,
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
  input  [49:0] io_debugTopDown_robHeadVaddr_bits
  // END GENERATED
);

  // ---- 输入打包：8 个 dtlb 请求口 → 数组；PTW 响应 → s1/s2 两个 struct ----
  logic [7:0]            tlb_req_valid;
  logic [7:0][VPN_W-1:0] tlb_req_vpn;
  logic [7:0][1:0]       tlb_req_s2xlate;
  logic [7:0]            tlb_req_get_gpa;
  ptw_s1_t               ptw_resp_s1;
  ptw_s2_t               ptw_resp_s2;
  // BEGIN GENERATED(pnf_in) —— scripts/gen_ptwnewfilter.py
  assign tlb_req_valid[0] = io_tlb_req_0_valid;
  assign tlb_req_vpn[0] = io_tlb_req_0_bits_vpn;
  assign tlb_req_s2xlate[0] = io_tlb_req_0_bits_s2xlate;
  assign tlb_req_get_gpa[0] = io_tlb_req_0_bits_getGpa;
  assign tlb_req_valid[1] = io_tlb_req_1_valid;
  assign tlb_req_vpn[1] = io_tlb_req_1_bits_vpn;
  assign tlb_req_s2xlate[1] = io_tlb_req_1_bits_s2xlate;
  assign tlb_req_get_gpa[1] = io_tlb_req_1_bits_getGpa;
  assign tlb_req_valid[2] = io_tlb_req_2_valid;
  assign tlb_req_vpn[2] = io_tlb_req_2_bits_vpn;
  assign tlb_req_s2xlate[2] = io_tlb_req_2_bits_s2xlate;
  assign tlb_req_get_gpa[2] = io_tlb_req_2_bits_getGpa;
  assign tlb_req_valid[3] = io_tlb_req_3_valid;
  assign tlb_req_vpn[3] = io_tlb_req_3_bits_vpn;
  assign tlb_req_s2xlate[3] = io_tlb_req_3_bits_s2xlate;
  assign tlb_req_get_gpa[3] = io_tlb_req_3_bits_getGpa;
  assign tlb_req_valid[4] = io_tlb_req_4_valid;
  assign tlb_req_vpn[4] = io_tlb_req_4_bits_vpn;
  assign tlb_req_s2xlate[4] = io_tlb_req_4_bits_s2xlate;
  assign tlb_req_get_gpa[4] = io_tlb_req_4_bits_getGpa;
  assign tlb_req_valid[5] = io_tlb_req_5_valid;
  assign tlb_req_vpn[5] = io_tlb_req_5_bits_vpn;
  assign tlb_req_s2xlate[5] = io_tlb_req_5_bits_s2xlate;
  assign tlb_req_get_gpa[5] = io_tlb_req_5_bits_getGpa;
  assign tlb_req_valid[6] = io_tlb_req_6_valid;
  assign tlb_req_vpn[6] = io_tlb_req_6_bits_vpn;
  assign tlb_req_s2xlate[6] = io_tlb_req_6_bits_s2xlate;
  assign tlb_req_get_gpa[6] = io_tlb_req_6_bits_getGpa;
  assign tlb_req_valid[7] = io_tlb_req_7_valid;
  assign tlb_req_vpn[7] = io_tlb_req_7_bits_vpn;
  assign tlb_req_s2xlate[7] = io_tlb_req_7_bits_s2xlate;
  assign tlb_req_get_gpa[7] = io_tlb_req_7_bits_getGpa;
  assign ptw_resp_s1.entry_tag = io_ptw_resp_bits_s1_entry_tag;
  assign ptw_resp_s1.entry_asid = io_ptw_resp_bits_s1_entry_asid;
  assign ptw_resp_s1.entry_vmid = io_ptw_resp_bits_s1_entry_vmid;
  assign ptw_resp_s1.entry_n = io_ptw_resp_bits_s1_entry_n;
  assign ptw_resp_s1.entry_pbmt = io_ptw_resp_bits_s1_entry_pbmt;
  assign ptw_resp_s1.entry_perm_d = io_ptw_resp_bits_s1_entry_perm_d;
  assign ptw_resp_s1.entry_perm_a = io_ptw_resp_bits_s1_entry_perm_a;
  assign ptw_resp_s1.entry_perm_g = io_ptw_resp_bits_s1_entry_perm_g;
  assign ptw_resp_s1.entry_perm_u = io_ptw_resp_bits_s1_entry_perm_u;
  assign ptw_resp_s1.entry_perm_x = io_ptw_resp_bits_s1_entry_perm_x;
  assign ptw_resp_s1.entry_perm_w = io_ptw_resp_bits_s1_entry_perm_w;
  assign ptw_resp_s1.entry_perm_r = io_ptw_resp_bits_s1_entry_perm_r;
  assign ptw_resp_s1.entry_level = io_ptw_resp_bits_s1_entry_level;
  assign ptw_resp_s1.entry_v = io_ptw_resp_bits_s1_entry_v;
  assign ptw_resp_s1.entry_ppn = io_ptw_resp_bits_s1_entry_ppn;
  assign ptw_resp_s1.addr_low = io_ptw_resp_bits_s1_addr_low;
  assign ptw_resp_s1.ppn_low[0] = io_ptw_resp_bits_s1_ppn_low_0;
  assign ptw_resp_s1.ppn_low[1] = io_ptw_resp_bits_s1_ppn_low_1;
  assign ptw_resp_s1.ppn_low[2] = io_ptw_resp_bits_s1_ppn_low_2;
  assign ptw_resp_s1.ppn_low[3] = io_ptw_resp_bits_s1_ppn_low_3;
  assign ptw_resp_s1.ppn_low[4] = io_ptw_resp_bits_s1_ppn_low_4;
  assign ptw_resp_s1.ppn_low[5] = io_ptw_resp_bits_s1_ppn_low_5;
  assign ptw_resp_s1.ppn_low[6] = io_ptw_resp_bits_s1_ppn_low_6;
  assign ptw_resp_s1.ppn_low[7] = io_ptw_resp_bits_s1_ppn_low_7;
  assign ptw_resp_s1.valididx[0] = io_ptw_resp_bits_s1_valididx_0;
  assign ptw_resp_s1.valididx[1] = io_ptw_resp_bits_s1_valididx_1;
  assign ptw_resp_s1.valididx[2] = io_ptw_resp_bits_s1_valididx_2;
  assign ptw_resp_s1.valididx[3] = io_ptw_resp_bits_s1_valididx_3;
  assign ptw_resp_s1.valididx[4] = io_ptw_resp_bits_s1_valididx_4;
  assign ptw_resp_s1.valididx[5] = io_ptw_resp_bits_s1_valididx_5;
  assign ptw_resp_s1.valididx[6] = io_ptw_resp_bits_s1_valididx_6;
  assign ptw_resp_s1.valididx[7] = io_ptw_resp_bits_s1_valididx_7;
  assign ptw_resp_s1.pteidx[0] = io_ptw_resp_bits_s1_pteidx_0;
  assign ptw_resp_s1.pteidx[1] = io_ptw_resp_bits_s1_pteidx_1;
  assign ptw_resp_s1.pteidx[2] = io_ptw_resp_bits_s1_pteidx_2;
  assign ptw_resp_s1.pteidx[3] = io_ptw_resp_bits_s1_pteidx_3;
  assign ptw_resp_s1.pteidx[4] = io_ptw_resp_bits_s1_pteidx_4;
  assign ptw_resp_s1.pteidx[5] = io_ptw_resp_bits_s1_pteidx_5;
  assign ptw_resp_s1.pteidx[6] = io_ptw_resp_bits_s1_pteidx_6;
  assign ptw_resp_s1.pteidx[7] = io_ptw_resp_bits_s1_pteidx_7;
  assign ptw_resp_s1.pf = io_ptw_resp_bits_s1_pf;
  assign ptw_resp_s1.af = io_ptw_resp_bits_s1_af;
  assign ptw_resp_s2.entry_tag = io_ptw_resp_bits_s2_entry_tag;
  assign ptw_resp_s2.entry_vmid = io_ptw_resp_bits_s2_entry_vmid;
  assign ptw_resp_s2.entry_n = io_ptw_resp_bits_s2_entry_n;
  assign ptw_resp_s2.entry_pbmt = io_ptw_resp_bits_s2_entry_pbmt;
  assign ptw_resp_s2.entry_ppn = io_ptw_resp_bits_s2_entry_ppn;
  assign ptw_resp_s2.entry_perm_d = io_ptw_resp_bits_s2_entry_perm_d;
  assign ptw_resp_s2.entry_perm_a = io_ptw_resp_bits_s2_entry_perm_a;
  assign ptw_resp_s2.entry_perm_g = io_ptw_resp_bits_s2_entry_perm_g;
  assign ptw_resp_s2.entry_perm_u = io_ptw_resp_bits_s2_entry_perm_u;
  assign ptw_resp_s2.entry_perm_x = io_ptw_resp_bits_s2_entry_perm_x;
  assign ptw_resp_s2.entry_perm_w = io_ptw_resp_bits_s2_entry_perm_w;
  assign ptw_resp_s2.entry_perm_r = io_ptw_resp_bits_s2_entry_perm_r;
  assign ptw_resp_s2.entry_level = io_ptw_resp_bits_s2_entry_level;
  assign ptw_resp_s2.gpf = io_ptw_resp_bits_s2_gpf;
  assign ptw_resp_s2.gaf = io_ptw_resp_bits_s2_gaf;
  // END GENERATED

  // ---- 输出展平 ----
  ptw_s1_t               tlb_resp_s1;
  ptw_s2_t               tlb_resp_s2;
  logic [2:0]            tlb_resp_vector;
  logic [2:0]            tlb_resp_get_gpa;
  logic [2:0][3:0]       hint_req_id;
  logic [2:0]            hint_req_full;
  // BEGIN GENERATED(pnf_out) —— scripts/gen_ptwnewfilter.py
  assign io_tlb_resp_bits_data_s1_entry_tag = tlb_resp_s1.entry_tag;
  assign io_tlb_resp_bits_data_s1_entry_asid = tlb_resp_s1.entry_asid;
  assign io_tlb_resp_bits_data_s1_entry_vmid = tlb_resp_s1.entry_vmid;
  assign io_tlb_resp_bits_data_s1_entry_n = tlb_resp_s1.entry_n;
  assign io_tlb_resp_bits_data_s1_entry_pbmt = tlb_resp_s1.entry_pbmt;
  assign io_tlb_resp_bits_data_s1_entry_perm_d = tlb_resp_s1.entry_perm_d;
  assign io_tlb_resp_bits_data_s1_entry_perm_a = tlb_resp_s1.entry_perm_a;
  assign io_tlb_resp_bits_data_s1_entry_perm_g = tlb_resp_s1.entry_perm_g;
  assign io_tlb_resp_bits_data_s1_entry_perm_u = tlb_resp_s1.entry_perm_u;
  assign io_tlb_resp_bits_data_s1_entry_perm_x = tlb_resp_s1.entry_perm_x;
  assign io_tlb_resp_bits_data_s1_entry_perm_w = tlb_resp_s1.entry_perm_w;
  assign io_tlb_resp_bits_data_s1_entry_perm_r = tlb_resp_s1.entry_perm_r;
  assign io_tlb_resp_bits_data_s1_entry_level = tlb_resp_s1.entry_level;
  assign io_tlb_resp_bits_data_s1_entry_v = tlb_resp_s1.entry_v;
  assign io_tlb_resp_bits_data_s1_entry_ppn = tlb_resp_s1.entry_ppn;
  assign io_tlb_resp_bits_data_s1_addr_low = tlb_resp_s1.addr_low;
  assign io_tlb_resp_bits_data_s1_ppn_low_0 = tlb_resp_s1.ppn_low[0];
  assign io_tlb_resp_bits_data_s1_ppn_low_1 = tlb_resp_s1.ppn_low[1];
  assign io_tlb_resp_bits_data_s1_ppn_low_2 = tlb_resp_s1.ppn_low[2];
  assign io_tlb_resp_bits_data_s1_ppn_low_3 = tlb_resp_s1.ppn_low[3];
  assign io_tlb_resp_bits_data_s1_ppn_low_4 = tlb_resp_s1.ppn_low[4];
  assign io_tlb_resp_bits_data_s1_ppn_low_5 = tlb_resp_s1.ppn_low[5];
  assign io_tlb_resp_bits_data_s1_ppn_low_6 = tlb_resp_s1.ppn_low[6];
  assign io_tlb_resp_bits_data_s1_ppn_low_7 = tlb_resp_s1.ppn_low[7];
  assign io_tlb_resp_bits_data_s1_valididx_0 = tlb_resp_s1.valididx[0];
  assign io_tlb_resp_bits_data_s1_valididx_1 = tlb_resp_s1.valididx[1];
  assign io_tlb_resp_bits_data_s1_valididx_2 = tlb_resp_s1.valididx[2];
  assign io_tlb_resp_bits_data_s1_valididx_3 = tlb_resp_s1.valididx[3];
  assign io_tlb_resp_bits_data_s1_valididx_4 = tlb_resp_s1.valididx[4];
  assign io_tlb_resp_bits_data_s1_valididx_5 = tlb_resp_s1.valididx[5];
  assign io_tlb_resp_bits_data_s1_valididx_6 = tlb_resp_s1.valididx[6];
  assign io_tlb_resp_bits_data_s1_valididx_7 = tlb_resp_s1.valididx[7];
  assign io_tlb_resp_bits_data_s1_pteidx_0 = tlb_resp_s1.pteidx[0];
  assign io_tlb_resp_bits_data_s1_pteidx_1 = tlb_resp_s1.pteidx[1];
  assign io_tlb_resp_bits_data_s1_pteidx_2 = tlb_resp_s1.pteidx[2];
  assign io_tlb_resp_bits_data_s1_pteidx_3 = tlb_resp_s1.pteidx[3];
  assign io_tlb_resp_bits_data_s1_pteidx_4 = tlb_resp_s1.pteidx[4];
  assign io_tlb_resp_bits_data_s1_pteidx_5 = tlb_resp_s1.pteidx[5];
  assign io_tlb_resp_bits_data_s1_pteidx_6 = tlb_resp_s1.pteidx[6];
  assign io_tlb_resp_bits_data_s1_pteidx_7 = tlb_resp_s1.pteidx[7];
  assign io_tlb_resp_bits_data_s1_pf = tlb_resp_s1.pf;
  assign io_tlb_resp_bits_data_s1_af = tlb_resp_s1.af;
  assign io_tlb_resp_bits_data_s2_entry_tag = tlb_resp_s2.entry_tag;
  assign io_tlb_resp_bits_data_s2_entry_vmid = tlb_resp_s2.entry_vmid;
  assign io_tlb_resp_bits_data_s2_entry_n = tlb_resp_s2.entry_n;
  assign io_tlb_resp_bits_data_s2_entry_pbmt = tlb_resp_s2.entry_pbmt;
  assign io_tlb_resp_bits_data_s2_entry_ppn = tlb_resp_s2.entry_ppn;
  assign io_tlb_resp_bits_data_s2_entry_perm_d = tlb_resp_s2.entry_perm_d;
  assign io_tlb_resp_bits_data_s2_entry_perm_a = tlb_resp_s2.entry_perm_a;
  assign io_tlb_resp_bits_data_s2_entry_perm_g = tlb_resp_s2.entry_perm_g;
  assign io_tlb_resp_bits_data_s2_entry_perm_u = tlb_resp_s2.entry_perm_u;
  assign io_tlb_resp_bits_data_s2_entry_perm_x = tlb_resp_s2.entry_perm_x;
  assign io_tlb_resp_bits_data_s2_entry_perm_w = tlb_resp_s2.entry_perm_w;
  assign io_tlb_resp_bits_data_s2_entry_perm_r = tlb_resp_s2.entry_perm_r;
  assign io_tlb_resp_bits_data_s2_entry_level = tlb_resp_s2.entry_level;
  assign io_tlb_resp_bits_data_s2_gpf = tlb_resp_s2.gpf;
  assign io_tlb_resp_bits_data_s2_gaf = tlb_resp_s2.gaf;
  assign io_tlb_resp_bits_vector_0 = tlb_resp_vector[0];
  assign io_tlb_resp_bits_vector_4 = tlb_resp_vector[1];
  assign io_tlb_resp_bits_vector_6 = tlb_resp_vector[2];
  assign io_tlb_resp_bits_getGpa_0 = tlb_resp_get_gpa[0];
  assign io_tlb_resp_bits_getGpa_4 = tlb_resp_get_gpa[1];
  assign io_tlb_resp_bits_getGpa_6 = tlb_resp_get_gpa[2];
  assign io_hint_req_0_id = hint_req_id[0];
  assign io_hint_req_0_full = hint_req_full[0];
  assign io_hint_req_1_id = hint_req_id[1];
  assign io_hint_req_1_full = hint_req_full[1];
  assign io_hint_req_2_id = hint_req_id[2];
  assign io_hint_req_2_full = hint_req_full[2];
  // END GENERATED

  xs_PTWNewFilter_core u_core (
    .clock                (clock),
    .reset                (reset),
    .sfence_valid         (io_sfence_valid),
    .satp_changed         (io_csr_satp_changed),
    .vsatp_changed        (io_csr_vsatp_changed),
    .hgatp_changed        (io_csr_hgatp_changed),
    .priv_virt_changed    (io_csr_priv_virt_changed),
    .satp_asid            (io_csr_satp_asid),
    .vsatp_asid           (io_csr_vsatp_asid),
    .hgatp_vmid           (io_csr_hgatp_vmid),
    .tlb_req_valid        (tlb_req_valid),
    .tlb_req_vpn          (tlb_req_vpn),
    .tlb_req_s2xlate      (tlb_req_s2xlate),
    .tlb_req_get_gpa      (tlb_req_get_gpa),
    .tlb_resp_valid       (io_tlb_resp_valid),
    .tlb_resp_s2xlate     (io_tlb_resp_bits_data_s2xlate),
    .tlb_resp_s1          (tlb_resp_s1),
    .tlb_resp_s2          (tlb_resp_s2),
    .tlb_resp_vector      (tlb_resp_vector),
    .tlb_resp_get_gpa     (tlb_resp_get_gpa),
    .ptw_req_ready        (io_ptw_req_0_ready),
    .ptw_req_valid        (io_ptw_req_0_valid),
    .ptw_req_vpn          (io_ptw_req_0_bits_vpn),
    .ptw_req_s2xlate      (io_ptw_req_0_bits_s2xlate),
    .ptw_resp_valid       (io_ptw_resp_valid),
    .ptw_resp_s2xlate     (io_ptw_resp_bits_s2xlate),
    .ptw_resp_s1          (ptw_resp_s1),
    .ptw_resp_s2          (ptw_resp_s2),
    .hint_req_id          (hint_req_id),
    .hint_req_full        (hint_req_full),
    .hint_resp_valid      (io_hint_resp_valid),
    .hint_resp_id         (io_hint_resp_bits_id),
    .hint_resp_replay_all (io_hint_resp_bits_replay_all),
    .rob_head_miss_in_tlb (io_rob_head_miss_in_tlb),
    .rob_head_vaddr_valid (io_debugTopDown_robHeadVaddr_valid),
    .rob_head_vaddr       (io_debugTopDown_robHeadVaddr_bits)
  );

endmodule
