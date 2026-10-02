// =============================================================================
//  PrefetchFilter.sv —— SMS 预取器的「预取请求过滤表」（pf_filter）
// -----------------------------------------------------------------------------
//  位置：MemBlock / SMSPrefetcher 里的 pf_filter。上游是 SMS 的模式历史表（PHT），每拍最多送来
//        一条「区域预取请求」io_gen_req：一个 1KB 区域（region_addr = vaddr[49:10] 或已是物理地址）+
//        16 位 region_bits（区域里哪几个 64B 行要预取）+ 是否已是物理地址 + 递减模式。
//  输出：io_tlb_req（把虚拟区域翻成物理区域）、io_l2_pf_addr（发往 L2 的逐行预取地址）。
//
//  核心机制（一条请求一生的顺序）：
//    §1 表项：16 项，每项一个区域：region_tag(11 位哈希) / region_addr / region_bits(要发的行) /
//         filter_bits(已经发过的行) / paddr_valid(region_addr 已是物理地址) / decr_mode。
//    §2 s0 去重：与上一拍同 tag 的请求直接丢；与表中有效项 tag 相同 → 命中（并入 region_bits）；
//         不中 → PLRU 选一项覆盖。正在 s1 被覆盖的那一项不算命中。
//    §3 s1 写表：alloc 整项覆盖 / update 并 region_bits。
//    §4 TLB 查询：还是虚地址、且「最近三拍没发过 TLB 请求」的项轮转仲裁出一个，打一拍发给 TLB；
//         两拍后 TLB 回应，再打一拍（s3）与 PMP 回应一起回填：成功 → 换成物理 region；
//         缺页/访问错/不可缓存/PMP 拒绝 → 作废该项。
//    §5 L2 发出：已是物理地址、还有没发过的行的项轮转仲裁，每次发一行（递增模式取最低行，
//         递减模式取最高行），把它记进 filter_bits。
//
//  怪癖（都照 golden 写）：
//    · 正在被 s1 覆盖的项本拍不参与 TLB / L2 仲裁；若 s1 覆盖的项恰是 s1 刚发 TLB 请求的项，
//      那条 TLB 请求被撤销（io_tlb_req_req_valid 拉低）。
//    · TLB 请求的 bits 是「仲裁器输出打一拍」，除 vaddr 外全是常量（isPrefetch=1，其余 0）；
//      常量字段的寄存器仍在（只在仲裁有效时写一次）。
//    · alias_bits / debug_source_type 在本配置没有出口，golden 已删，本核也不存。
//    · GatedValidRegNext（值变了才打拍）功能上等于普通 RegNext，本核写成普通 RegNext。
//
//  文件结构（单文件规范）：prefetchfilter_pkg → xs_PrefetchFilter_core（可读核）
//    → PrefetchFilter（golden 同名 wrapper，端口逐位同名同序）。
//  子模块：2 个轮转仲裁器 RRArbiterInit_5（TLB，16 路）/ RRArbiterInit_6（L2 预取，16 路），
//    都是本仓已签核的重写件（rtl/common/RRArbiterInit_*.sv，核 rtl/common/RRArbiterInit.sv）。
//    PLRU 用共享辅助件 rtl/common/xs_PlruReplacer.sv（golden 内联为 state_reg）。
//  设计源：src/main/scala/xiangshan/mem/prefetch/SMSPrefetcher.scala（class PrefetchFilter）
// =============================================================================

// =============================================================================
//  prefetchfilter_pkg —— 位宽常量 / 纯函数
// =============================================================================
package prefetchfilter_pkg;

  localparam int VADDR_W   = 50;
  localparam int PADDR_W   = 48;
  localparam int REGION_W  = 40;                 // REGION_ADDR_BITS = VAddrBits - log2(1KB)
  localparam int TAG_W     = 11;                 // REGION_TAG_WIDTH = 6(原样) + 5(哈希)
  localparam int BITVEC_W  = 16;                 // REGION_BLKS
  localparam int LINE_W    = 4;                  // REGION_OFFSET
  localparam int SIZE      = 16;                 // pf_filter_size
  localparam int IDX_W     = 4;

  // 下一条要发的行：pending = region_bits & ~filter_bits；
  //   递增模式取最低置位（PriorityMux，全 0 时落到最后一项 = 15），
  //   递减模式取最高置位（reverse 后 PriorityMux，全 0 时落到 0）。
  function automatic logic [LINE_W-1:0] next_line(input logic [BITVEC_W-1:0] pending, input logic decr);
    if (decr) begin
      for (int k = BITVEC_W - 1; k >= 0; k--)
        if (pending[k]) return LINE_W'(k);
      return '0;
    end else begin
      for (int k = 0; k < BITVEC_W; k++)
        if (pending[k]) return LINE_W'(k);
      return LINE_W'(BITVEC_W - 1);
    end
  endfunction

  // OHToUInt：所有置位下标按位 OR（独热时就是那个下标）
  function automatic logic [IDX_W-1:0] oh_to_uint(input logic [SIZE-1:0] oh);
    logic [IDX_W-1:0] r;
    r = '0;
    for (int k = 0; k < SIZE; k++)
      if (oh[k]) r |= IDX_W'(k);
    return r;
  endfunction

  // Pbmt.isUncache：页表属性 NC(1) 或 IO(2) 都算不可缓存
  function automatic logic pbmt_is_uncache(input logic [1:0] pbmt);
    return (pbmt == 2'd1) | (pbmt == 2'd2);
  endfunction

endpackage

// =============================================================================
//  xs_PrefetchFilter_core —— 可读核
// -----------------------------------------------------------------------------
//  分节：§1 表项  §2 s0 去重与选项号  §3 s1 写表  §4 TLB 查询与回填  §5 L2 发出
//  表项用 generate 块 entries[i] 表达（golden 展平名 entries_<i>_<字段>）。
// =============================================================================
module xs_PrefetchFilter_core
  import prefetchfilter_pkg::*;
(
  input  logic                clock,
  input  logic                reset,
  // 上游区域预取请求（PfGenReq 在本配置留下的字段）
  input  logic                gen_req_valid,
  input  logic [TAG_W-1:0]    gen_req_region_tag,
  input  logic [REGION_W-1:0] gen_req_region_addr,
  input  logic [BITVEC_W-1:0] gen_req_region_bits,
  input  logic                gen_req_paddr_valid,
  input  logic                gen_req_decr_mode,
  // TLB 请求（打一拍后的仲裁结果）
  output logic                tlb_req_valid,
  output logic [VADDR_W-1:0]  tlb_req_vaddr,
  output logic [63:0]         tlb_req_fullva,
  output logic                tlb_req_checkfullva,
  output logic [2:0]          tlb_req_cmd,
  output logic                tlb_req_hyperinst,
  output logic                tlb_req_hlvx,
  output logic                tlb_req_kill,
  output logic                tlb_req_isPrefetch,
  output logic                tlb_req_no_translate,
  output logic [PADDR_W-1:0]  tlb_req_pmp_addr,
  output logic                tlb_req_frm_mabuf,
  output logic                tlb_req_debug_robIdx_flag,
  output logic [7:0]          tlb_req_debug_robIdx_value,
  output logic                tlb_req_debug_isFirstIssue,
  // TLB 回应（第 0 份）与 PMP 回应
  input  logic                tlb_resp_valid,
  input  logic [PADDR_W-1:0]  tlb_resp_paddr,
  input  logic [1:0]          tlb_resp_pbmt,
  input  logic                tlb_resp_miss,
  input  logic                tlb_resp_gpf_ld,
  input  logic                tlb_resp_pf_ld,
  input  logic                tlb_resp_af_ld,
  input  logic                pmp_resp_ld,         // PMP 访问错
  input  logic                pmp_resp_mmio,       // PMP 判为 MMIO
  // 发往 L2 的逐行预取
  output logic                l2_pf_valid,
  output logic [PADDR_W-1:0]  l2_pf_addr
);

  // ---------------------------------------------------------------------------
  //  跨节信号
  // ---------------------------------------------------------------------------
  logic                s1_valid_r_last_REG;           // s1 有效
  logic                s1_hit_r;                      // s1 是命中（update）还是不中（alloc）
  logic [SIZE-1:0]     s1_replace_vec_r;              // s1 要覆盖的项（独热）
  logic [SIZE-1:0]     s1_update_vec;                 // s1 要并入的项（命中向量）
  logic [TAG_W-1:0]    s1_gen_req_region_tag;
  logic [REGION_W-1:0] s1_gen_req_region_addr;
  logic [BITVEC_W-1:0] s1_gen_req_region_bits;
  logic                s1_gen_req_paddr_valid;
  logic                s1_gen_req_decr_mode;

  // TLB 请求在最近三拍内由哪一项发出（s1/s2/s3 = 仲裁后第 1/2/3 拍）
  logic [SIZE-1:0]     s1_tlb_fire_vec, s2_tlb_fire_vec, s3_tlb_fire_vec;
  logic                s3_update_valid, s3_drop;
  logic [REGION_W-1:0] s3_paddr_region;
  logic                s3_tlb_resp_miss;

  // 仲裁器接口
  logic [SIZE-1:0]     tlb_arb_in_valid, tlb_arb_in_ready;
  logic [VADDR_W-1:0]  tlb_arb_in_vaddr [SIZE];
  logic                tlb_arb_out_valid;
  logic [VADDR_W-1:0]  tlb_arb_out_vaddr;
  logic [SIZE-1:0]     pf_arb_in_valid, pf_arb_in_ready;
  logic [PADDR_W-1:0]  pf_arb_in_addr [SIZE];
  logic [IDX_W-1:0]    pf_arb_chosen;                 // 本配置没有读者（alias/debug 出口被删）

  // 每一项对外导出的视图
  logic                valids [SIZE];
  logic [SIZE-1:0]     s0_match_vec;

  // 本拍 s1 覆盖的项（alloc）：它不参与 s0 命中，也不参与两个仲裁
  wire [SIZE-1:0] s1_evict_vec = {SIZE{s1_valid_r_last_REG}} & s1_replace_vec_r;
  wire            s1_alloc     = s1_valid_r_last_REG & ~s1_hit_r;
  wire            s1_update    = s1_valid_r_last_REG &  s1_hit_r;

  // ===========================================================================
  //  §1 表项（PrefetchFilterEntry）
  // ---------------------------------------------------------------------------
  //  valid 异步复位；其余字段不复位。同一拍的写入按 Scala 的「后写者胜」：
  //    ① s3 TLB 回填（成功换物理 region；出错作废）
  //    ② s1 update：region_bits 并入新请求的行
  //    ③ L2 仲裁器选中本项：发出的那一行记进 filter_bits
  //    ④ s1 alloc：整项覆盖（压过以上全部）
  // ===========================================================================
  for (genvar i = 0; i < SIZE; i++) begin : entries
    logic [TAG_W-1:0]    region_tag;
    logic [REGION_W-1:0] region_addr;
    logic [BITVEC_W-1:0] region_bits;
    logic [BITVEC_W-1:0] filter_bits;
    logic                paddr_valid;
    logic                decr_mode;

    wire                alloc     = s1_alloc  & s1_replace_vec_r[i];
    wire                update    = s1_update & s1_update_vec[i];
    wire                tlb_fired = s3_tlb_fire_vec[i] & s3_update_valid;
    wire [BITVEC_W-1:0] pending   = region_bits & ~filter_bits;
    wire [LINE_W-1:0]   pf_line   = next_line(pending, decr_mode);
    wire                pf_fired  = pf_arb_in_valid[i] & pf_arb_in_ready[i];

    always_ff @(posedge clock) begin
      if (alloc) begin
        region_tag  <= s1_gen_req_region_tag;
        region_addr <= s1_gen_req_region_addr;
        region_bits <= s1_gen_req_region_bits;
        filter_bits <= '0;
        paddr_valid <= s1_gen_req_paddr_valid;
        decr_mode   <= s1_gen_req_decr_mode;
      end else begin
        if (tlb_fired & ~s3_drop) begin
          paddr_valid <= ~s3_tlb_resp_miss;
          region_addr <= s3_paddr_region;
        end
        if (update)
          region_bits <= region_bits | s1_gen_req_region_bits;
        if (pf_fired)
          filter_bits <= filter_bits | (BITVEC_W'(1) << pf_line);
      end
    end

    always_ff @(posedge clock or posedge reset) begin
      if (reset) valids[i] <= 1'b0;
      else       valids[i] <= alloc | (valids[i] & ~(tlb_fired & s3_drop));
    end

    // ---- 本项对外的视图 ----
    // s0 命中：有效、tag 相同、且不是 s1 正在覆盖的那一项
    assign s0_match_vec[i] = valids[i] & (region_tag == gen_req_region_tag)
                             & ~(s1_alloc & s1_replace_vec_r[i]);
    // TLB 仲裁：还是虚地址、最近三拍没发过 TLB 请求、本拍不被覆盖
    assign tlb_arb_in_valid[i] = valids[i] & ~s1_tlb_fire_vec[i] & ~s2_tlb_fire_vec[i] & ~s3_tlb_fire_vec[i]
                                 & ~paddr_valid & ~s1_evict_vec[i];
    assign tlb_arb_in_vaddr[i] = {region_addr, 10'b0};
    // L2 仲裁：已是物理地址、还有没发过的行、本拍不被覆盖。地址 = Cat(region, 行号, 6'b0) 截到 48 位
    assign pf_arb_in_valid[i]  = valids[i] & (|pending) & paddr_valid & ~s1_evict_vec[i];
    assign pf_arb_in_addr[i]   = {region_addr[37:0], pf_line, 6'b0};
  end

  // ===========================================================================
  //  §2 s0：去重与选项号
  // ---------------------------------------------------------------------------
  //  与上一拍（无论那一拍是否被丢）同 tag 的请求直接丢 —— 上游常连发同一区域。
  //  命中 → update 那一项；不中 → PLRU 替换项。只要 s0 有效就 touch PLRU（命中也 touch）。
  // ===========================================================================
  logic             prev_valid_last_REG;
  logic [TAG_W-1:0] prev_gen_req_region_tag;
  logic [IDX_W-1:0] plru_way;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) prev_valid_last_REG <= 1'b0;
    else       prev_valid_last_REG <= gen_req_valid;
  end
  always_ff @(posedge clock) begin
    if (gen_req_valid) prev_gen_req_region_tag <= gen_req_region_tag;
  end

  wire s0_match_prev    = prev_valid_last_REG & (gen_req_region_tag == prev_gen_req_region_tag);
  wire s0_gen_req_valid = gen_req_valid & ~s0_match_prev;
  wire s0_any_matched   = |s0_match_vec;
  wire s0_hit           = s0_gen_req_valid & s0_any_matched;
  wire [IDX_W-1:0] s0_access_way = s0_any_matched ? oh_to_uint(s0_match_vec) : plru_way;

  // golden 名 state_reg：15 位 PLRU 树，异步复位成 0
  xs_PlruReplacer #(.NUM_WAYS(SIZE)) u_plru (
    .clock       (clock),
    .reset       (reset),
    .touch_valid (s0_gen_req_valid),
    .touch_way   (s0_access_way),
    .replace_way (plru_way)
  );

  // ===========================================================================
  //  §3 s1：写表（实际写入在 §1 各项里）
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid_r_last_REG <= 1'b0;
      s1_hit_r            <= 1'b0;
    end else begin
      s1_valid_r_last_REG <= s0_gen_req_valid;
      if (s0_gen_req_valid) s1_hit_r <= s0_hit;
    end
  end

  always_ff @(posedge clock) begin
    if (s0_gen_req_valid) begin
      s1_gen_req_region_tag  <= gen_req_region_tag;
      s1_gen_req_region_addr <= gen_req_region_addr;
      s1_gen_req_region_bits <= gen_req_region_bits;
      s1_gen_req_paddr_valid <= gen_req_paddr_valid;
      s1_gen_req_decr_mode   <= gen_req_decr_mode;
    end
    if (s0_gen_req_valid & ~s0_hit) s1_replace_vec_r <= SIZE'(1) << plru_way;
    if (s0_gen_req_valid &  s0_hit) s1_update_vec    <= s0_match_vec;
  end

  // ===========================================================================
  //  §4 TLB 查询与回填
  // ---------------------------------------------------------------------------
  //  s0 仲裁 → s1 打一拍发出（若 s1 覆盖的正是发请求的那一项，撤销这条请求）→
  //  TLB 两拍后回应 → 打一拍成 s3，与本拍的 PMP 回应一起判定。
  //  s1/s2/s3_tlb_fire_vec 记「哪一项在 1/2/3 拍前发过 TLB 请求」：既用来挡住重复请求，
  //  也用来确定 s3 回应该回填哪一项。
  // ===========================================================================
  logic s1_tlb_req_valid_last_REG;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_tlb_req_valid_last_REG <= 1'b0;
      s1_tlb_fire_vec           <= '0;
      s2_tlb_fire_vec           <= '0;
      s3_tlb_fire_vec           <= '0;
    end else begin
      s1_tlb_req_valid_last_REG <= tlb_arb_out_valid;           // 仲裁器 out.ready 恒 1
      s1_tlb_fire_vec           <= tlb_arb_in_valid & tlb_arb_in_ready;
      s2_tlb_fire_vec           <= s1_tlb_fire_vec;
      s3_tlb_fire_vec           <= s2_tlb_fire_vec;
    end
  end

  // 打一拍的 TLB 请求：只有 vaddr 来自表项，其余字段是常量（TlbCmd.read=0、isPrefetch=1、DontCare=0）
  logic [VADDR_W-1:0] s1_tlb_req_bits_vaddr;
  logic [63:0]        s1_tlb_req_bits_fullva;
  logic               s1_tlb_req_bits_checkfullva;
  logic [2:0]         s1_tlb_req_bits_cmd;
  logic               s1_tlb_req_bits_hyperinst;
  logic               s1_tlb_req_bits_hlvx;
  logic               s1_tlb_req_bits_kill;
  logic               s1_tlb_req_bits_isPrefetch;
  logic               s1_tlb_req_bits_no_translate;
  logic [PADDR_W-1:0] s1_tlb_req_bits_pmp_addr;
  logic               s1_tlb_req_bits_frm_mabuf;
  logic               s1_tlb_req_bits_debug_robIdx_flag;
  logic [7:0]         s1_tlb_req_bits_debug_robIdx_value;
  logic               s1_tlb_req_bits_debug_isFirstIssue;

  always_ff @(posedge clock) begin
    if (tlb_arb_out_valid) begin
      s1_tlb_req_bits_vaddr              <= tlb_arb_out_vaddr;
      s1_tlb_req_bits_fullva             <= '0;
      s1_tlb_req_bits_checkfullva        <= 1'b0;
      s1_tlb_req_bits_cmd                <= 3'd0;
      s1_tlb_req_bits_hyperinst          <= 1'b0;
      s1_tlb_req_bits_hlvx               <= 1'b0;
      s1_tlb_req_bits_kill               <= 1'b0;
      s1_tlb_req_bits_isPrefetch         <= 1'b1;
      s1_tlb_req_bits_no_translate       <= 1'b0;
      s1_tlb_req_bits_pmp_addr           <= '0;
      s1_tlb_req_bits_frm_mabuf          <= 1'b0;
      s1_tlb_req_bits_debug_robIdx_flag  <= 1'b0;
      s1_tlb_req_bits_debug_robIdx_value <= 8'd0;
      s1_tlb_req_bits_debug_isFirstIssue <= 1'b0;
    end
  end

  assign tlb_req_valid = s1_tlb_req_valid_last_REG & ~((|(s1_tlb_fire_vec & s1_replace_vec_r)) & s1_alloc);
  assign tlb_req_vaddr              = s1_tlb_req_bits_vaddr;
  assign tlb_req_fullva             = s1_tlb_req_bits_fullva;
  assign tlb_req_checkfullva        = s1_tlb_req_bits_checkfullva;
  assign tlb_req_cmd                = s1_tlb_req_bits_cmd;
  assign tlb_req_hyperinst          = s1_tlb_req_bits_hyperinst;
  assign tlb_req_hlvx               = s1_tlb_req_bits_hlvx;
  assign tlb_req_kill               = s1_tlb_req_bits_kill;
  assign tlb_req_isPrefetch         = s1_tlb_req_bits_isPrefetch;
  assign tlb_req_no_translate       = s1_tlb_req_bits_no_translate;
  assign tlb_req_pmp_addr           = s1_tlb_req_bits_pmp_addr;
  assign tlb_req_frm_mabuf          = s1_tlb_req_bits_frm_mabuf;
  assign tlb_req_debug_robIdx_flag  = s1_tlb_req_bits_debug_robIdx_flag;
  assign tlb_req_debug_robIdx_value = s1_tlb_req_bits_debug_robIdx_value;
  assign tlb_req_debug_isFirstIssue = s1_tlb_req_bits_debug_isFirstIssue;

  // s3：TLB 回应打一拍（resp.ready 恒 1，fire = valid；fire 本身不复位）
  logic               s3_tlb_resp_fire;
  logic [PADDR_W-1:0] s3_tlb_resp_paddr_0;
  logic [1:0]         s3_tlb_resp_pbmt_0;
  logic               s3_tlb_resp_excp_0_gpf_ld, s3_tlb_resp_excp_0_pf_ld, s3_tlb_resp_excp_0_af_ld;

  always_ff @(posedge clock) begin
    s3_tlb_resp_fire <= tlb_resp_valid;
    if (tlb_resp_valid) begin
      s3_tlb_resp_paddr_0       <= tlb_resp_paddr;
      s3_tlb_resp_pbmt_0        <= tlb_resp_pbmt;
      s3_tlb_resp_miss          <= tlb_resp_miss;
      s3_tlb_resp_excp_0_gpf_ld <= tlb_resp_gpf_ld;
      s3_tlb_resp_excp_0_pf_ld  <= tlb_resp_pf_ld;
      s3_tlb_resp_excp_0_af_ld  <= tlb_resp_af_ld;
    end
  end

  // 回应有效且命中 TLB 才回填；出错（页错/访问错/不可缓存/PMP 拒绝）则作废该项
  assign s3_update_valid = s3_tlb_resp_fire & ~s3_tlb_resp_miss;
  assign s3_drop = s3_update_valid & (s3_tlb_resp_excp_0_pf_ld | s3_tlb_resp_excp_0_gpf_ld | s3_tlb_resp_excp_0_af_ld |
                                      pmp_resp_mmio | pbmt_is_uncache(s3_tlb_resp_pbmt_0) | pmp_resp_ld);
  assign s3_paddr_region = REGION_W'(s3_tlb_resp_paddr_0[PADDR_W-1:10]);   // region_addr(paddr)，高位补 0

  // ===========================================================================
  //  §5 两个轮转仲裁器（out.ready 恒 1）
  //  端口连线由 scripts/gen_mmuleaf.py 按 golden 子模块端口表生成（逐口认领，fail-closed）。
  // ===========================================================================
  // BEGIN GENERATED(tlb_req_arb) —— scripts/gen_mmuleaf.py
  RRArbiterInit_5 tlb_req_arb (
    .clock               (clock),
    .reset               (reset),
    .io_in_0_ready       (tlb_arb_in_ready[0]),
    .io_in_0_valid       (tlb_arb_in_valid[0]),
    .io_in_0_bits_vaddr  (tlb_arb_in_vaddr[0]),
    .io_in_1_ready       (tlb_arb_in_ready[1]),
    .io_in_1_valid       (tlb_arb_in_valid[1]),
    .io_in_1_bits_vaddr  (tlb_arb_in_vaddr[1]),
    .io_in_2_ready       (tlb_arb_in_ready[2]),
    .io_in_2_valid       (tlb_arb_in_valid[2]),
    .io_in_2_bits_vaddr  (tlb_arb_in_vaddr[2]),
    .io_in_3_ready       (tlb_arb_in_ready[3]),
    .io_in_3_valid       (tlb_arb_in_valid[3]),
    .io_in_3_bits_vaddr  (tlb_arb_in_vaddr[3]),
    .io_in_4_ready       (tlb_arb_in_ready[4]),
    .io_in_4_valid       (tlb_arb_in_valid[4]),
    .io_in_4_bits_vaddr  (tlb_arb_in_vaddr[4]),
    .io_in_5_ready       (tlb_arb_in_ready[5]),
    .io_in_5_valid       (tlb_arb_in_valid[5]),
    .io_in_5_bits_vaddr  (tlb_arb_in_vaddr[5]),
    .io_in_6_ready       (tlb_arb_in_ready[6]),
    .io_in_6_valid       (tlb_arb_in_valid[6]),
    .io_in_6_bits_vaddr  (tlb_arb_in_vaddr[6]),
    .io_in_7_ready       (tlb_arb_in_ready[7]),
    .io_in_7_valid       (tlb_arb_in_valid[7]),
    .io_in_7_bits_vaddr  (tlb_arb_in_vaddr[7]),
    .io_in_8_ready       (tlb_arb_in_ready[8]),
    .io_in_8_valid       (tlb_arb_in_valid[8]),
    .io_in_8_bits_vaddr  (tlb_arb_in_vaddr[8]),
    .io_in_9_ready       (tlb_arb_in_ready[9]),
    .io_in_9_valid       (tlb_arb_in_valid[9]),
    .io_in_9_bits_vaddr  (tlb_arb_in_vaddr[9]),
    .io_in_10_ready      (tlb_arb_in_ready[10]),
    .io_in_10_valid      (tlb_arb_in_valid[10]),
    .io_in_10_bits_vaddr (tlb_arb_in_vaddr[10]),
    .io_in_11_ready      (tlb_arb_in_ready[11]),
    .io_in_11_valid      (tlb_arb_in_valid[11]),
    .io_in_11_bits_vaddr (tlb_arb_in_vaddr[11]),
    .io_in_12_ready      (tlb_arb_in_ready[12]),
    .io_in_12_valid      (tlb_arb_in_valid[12]),
    .io_in_12_bits_vaddr (tlb_arb_in_vaddr[12]),
    .io_in_13_ready      (tlb_arb_in_ready[13]),
    .io_in_13_valid      (tlb_arb_in_valid[13]),
    .io_in_13_bits_vaddr (tlb_arb_in_vaddr[13]),
    .io_in_14_ready      (tlb_arb_in_ready[14]),
    .io_in_14_valid      (tlb_arb_in_valid[14]),
    .io_in_14_bits_vaddr (tlb_arb_in_vaddr[14]),
    .io_in_15_ready      (tlb_arb_in_ready[15]),
    .io_in_15_valid      (tlb_arb_in_valid[15]),
    .io_in_15_bits_vaddr (tlb_arb_in_vaddr[15]),
    .io_out_valid        (tlb_arb_out_valid),
    .io_out_bits_vaddr   (tlb_arb_out_vaddr)
  );
  // END GENERATED

  // BEGIN GENERATED(pf_req_arb) —— scripts/gen_mmuleaf.py
  RRArbiterInit_6 pf_req_arb (
    .clock          (clock),
    .reset          (reset),
    .io_in_0_ready  (pf_arb_in_ready[0]),
    .io_in_0_valid  (pf_arb_in_valid[0]),
    .io_in_0_bits   (pf_arb_in_addr[0]),
    .io_in_1_ready  (pf_arb_in_ready[1]),
    .io_in_1_valid  (pf_arb_in_valid[1]),
    .io_in_1_bits   (pf_arb_in_addr[1]),
    .io_in_2_ready  (pf_arb_in_ready[2]),
    .io_in_2_valid  (pf_arb_in_valid[2]),
    .io_in_2_bits   (pf_arb_in_addr[2]),
    .io_in_3_ready  (pf_arb_in_ready[3]),
    .io_in_3_valid  (pf_arb_in_valid[3]),
    .io_in_3_bits   (pf_arb_in_addr[3]),
    .io_in_4_ready  (pf_arb_in_ready[4]),
    .io_in_4_valid  (pf_arb_in_valid[4]),
    .io_in_4_bits   (pf_arb_in_addr[4]),
    .io_in_5_ready  (pf_arb_in_ready[5]),
    .io_in_5_valid  (pf_arb_in_valid[5]),
    .io_in_5_bits   (pf_arb_in_addr[5]),
    .io_in_6_ready  (pf_arb_in_ready[6]),
    .io_in_6_valid  (pf_arb_in_valid[6]),
    .io_in_6_bits   (pf_arb_in_addr[6]),
    .io_in_7_ready  (pf_arb_in_ready[7]),
    .io_in_7_valid  (pf_arb_in_valid[7]),
    .io_in_7_bits   (pf_arb_in_addr[7]),
    .io_in_8_ready  (pf_arb_in_ready[8]),
    .io_in_8_valid  (pf_arb_in_valid[8]),
    .io_in_8_bits   (pf_arb_in_addr[8]),
    .io_in_9_ready  (pf_arb_in_ready[9]),
    .io_in_9_valid  (pf_arb_in_valid[9]),
    .io_in_9_bits   (pf_arb_in_addr[9]),
    .io_in_10_ready (pf_arb_in_ready[10]),
    .io_in_10_valid (pf_arb_in_valid[10]),
    .io_in_10_bits  (pf_arb_in_addr[10]),
    .io_in_11_ready (pf_arb_in_ready[11]),
    .io_in_11_valid (pf_arb_in_valid[11]),
    .io_in_11_bits  (pf_arb_in_addr[11]),
    .io_in_12_ready (pf_arb_in_ready[12]),
    .io_in_12_valid (pf_arb_in_valid[12]),
    .io_in_12_bits  (pf_arb_in_addr[12]),
    .io_in_13_ready (pf_arb_in_ready[13]),
    .io_in_13_valid (pf_arb_in_valid[13]),
    .io_in_13_bits  (pf_arb_in_addr[13]),
    .io_in_14_ready (pf_arb_in_ready[14]),
    .io_in_14_valid (pf_arb_in_valid[14]),
    .io_in_14_bits  (pf_arb_in_addr[14]),
    .io_in_15_ready (pf_arb_in_ready[15]),
    .io_in_15_valid (pf_arb_in_valid[15]),
    .io_in_15_bits  (pf_arb_in_addr[15]),
    .io_out_valid   (l2_pf_valid),
    .io_out_bits    (l2_pf_addr),
    .io_chosen      (pf_arb_chosen)
  );
  // END GENERATED

endmodule

// =============================================================================
//  PrefetchFilter —— golden 同名 wrapper：端口逐位同名同序，只做改名
// =============================================================================
module PrefetchFilter (
  input         clock,
  input         reset,
  input         io_gen_req_valid,
  input  [10:0] io_gen_req_bits_region_tag,
  input  [39:0] io_gen_req_bits_region_addr,
  input  [15:0] io_gen_req_bits_region_bits,
  input         io_gen_req_bits_paddr_valid,
  input         io_gen_req_bits_decr_mode,
  output        io_tlb_req_req_valid,
  output [49:0] io_tlb_req_req_bits_vaddr,
  output [63:0] io_tlb_req_req_bits_fullva,
  output        io_tlb_req_req_bits_checkfullva,
  output [2:0]  io_tlb_req_req_bits_cmd,
  output        io_tlb_req_req_bits_hyperinst,
  output        io_tlb_req_req_bits_hlvx,
  output        io_tlb_req_req_bits_kill,
  output        io_tlb_req_req_bits_isPrefetch,
  output        io_tlb_req_req_bits_no_translate,
  output [47:0] io_tlb_req_req_bits_pmp_addr,
  output        io_tlb_req_req_bits_frm_mabuf,
  output        io_tlb_req_req_bits_debug_robIdx_flag,
  output [7:0]  io_tlb_req_req_bits_debug_robIdx_value,
  output        io_tlb_req_req_bits_debug_isFirstIssue,
  input         io_tlb_req_resp_valid,
  input  [47:0] io_tlb_req_resp_bits_paddr_0,
  input  [1:0]  io_tlb_req_resp_bits_pbmt_0,
  input         io_tlb_req_resp_bits_miss,
  input         io_tlb_req_resp_bits_excp_0_gpf_ld,
  input         io_tlb_req_resp_bits_excp_0_pf_ld,
  input         io_tlb_req_resp_bits_excp_0_af_ld,
  input         io_pmp_resp_ld,
  input         io_pmp_resp_mmio,
  output        io_l2_pf_addr_valid,
  output [47:0] io_l2_pf_addr_bits
);

  xs_PrefetchFilter_core u_core (
    .clock                      (clock),
    .reset                      (reset),
    .gen_req_valid              (io_gen_req_valid),
    .gen_req_region_tag         (io_gen_req_bits_region_tag),
    .gen_req_region_addr        (io_gen_req_bits_region_addr),
    .gen_req_region_bits        (io_gen_req_bits_region_bits),
    .gen_req_paddr_valid        (io_gen_req_bits_paddr_valid),
    .gen_req_decr_mode          (io_gen_req_bits_decr_mode),
    .tlb_req_valid              (io_tlb_req_req_valid),
    .tlb_req_vaddr              (io_tlb_req_req_bits_vaddr),
    .tlb_req_fullva             (io_tlb_req_req_bits_fullva),
    .tlb_req_checkfullva        (io_tlb_req_req_bits_checkfullva),
    .tlb_req_cmd                (io_tlb_req_req_bits_cmd),
    .tlb_req_hyperinst          (io_tlb_req_req_bits_hyperinst),
    .tlb_req_hlvx               (io_tlb_req_req_bits_hlvx),
    .tlb_req_kill               (io_tlb_req_req_bits_kill),
    .tlb_req_isPrefetch         (io_tlb_req_req_bits_isPrefetch),
    .tlb_req_no_translate       (io_tlb_req_req_bits_no_translate),
    .tlb_req_pmp_addr           (io_tlb_req_req_bits_pmp_addr),
    .tlb_req_frm_mabuf          (io_tlb_req_req_bits_frm_mabuf),
    .tlb_req_debug_robIdx_flag  (io_tlb_req_req_bits_debug_robIdx_flag),
    .tlb_req_debug_robIdx_value (io_tlb_req_req_bits_debug_robIdx_value),
    .tlb_req_debug_isFirstIssue (io_tlb_req_req_bits_debug_isFirstIssue),
    .tlb_resp_valid             (io_tlb_req_resp_valid),
    .tlb_resp_paddr             (io_tlb_req_resp_bits_paddr_0),
    .tlb_resp_pbmt              (io_tlb_req_resp_bits_pbmt_0),
    .tlb_resp_miss              (io_tlb_req_resp_bits_miss),
    .tlb_resp_gpf_ld            (io_tlb_req_resp_bits_excp_0_gpf_ld),
    .tlb_resp_pf_ld             (io_tlb_req_resp_bits_excp_0_pf_ld),
    .tlb_resp_af_ld             (io_tlb_req_resp_bits_excp_0_af_ld),
    .pmp_resp_ld                (io_pmp_resp_ld),
    .pmp_resp_mmio              (io_pmp_resp_mmio),
    .l2_pf_valid                (io_l2_pf_addr_valid),
    .l2_pf_addr                 (io_l2_pf_addr_bits)
  );

endmodule
