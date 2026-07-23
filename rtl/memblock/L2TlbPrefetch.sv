// =============================================================================
// xs_L2TlbPrefetch_core —— L2TLB 顺序流预取器（可读 SystemVerilog 重写）
//
// 设计意图来自 L2TlbPrefetch.scala class L2TlbPrefetch。它是 L2TLB 前端一个
// 极简的“下一行”页表预取器：每当上游送来一个被访问的 VPN，就推测下一条
// cacheline 的页表项也会很快被用到，于是生成一个指向 next_line 的预取请求
// 注入 L2TLB 的请求仲裁。为避免重复预取，维护一个最近 OLD_REC_N=4 条的
// 预取记录窗口做去重。
//
// 微架构要点（对照 Scala）：
//   1. next_line = get_next_line(in.vpn)：把 VPN 去 sector 位 +1 后补 0，
//      指向下一条 cacheline 的首个页表项。
//   2. 去重 already_have：next_line 与记录窗口中任一“有效且同行”的旧请求
//      命中则丢弃，input_valid 拉低。
//   3. v = ValidHold(input_valid, out.fire, flush)：预取请求一旦产生就保持
//      valid，直到被 L2TLB 接收（out.fire）或被 flush 冲掉。
//   4. s2xlate 按当前虚拟化/vsatp/hgatp 模式选择（allStage/onlyStage1/onlyStage2/noS2）。
//   5. out.fire 时把 next_req 写入记录窗口（环形指针 old_index 轮转），flush 清空窗口。
//
// 注意 next_req 是 next_line 打一拍的版本（RegEnable(next_line, in.valid)），
// 而去重 already_have 与 input_valid 用的是当拍组合 next_line。
// =============================================================================
module xs_L2TlbPrefetch_core
  import xs_l2tlbprefetch_pkg::*;
(
  input  logic              clock,
  input  logic              reset,

  input  logic              sfence_valid,
  input  logic              satp_changed,
  input  logic [3:0]        vsatp_mode,
  input  logic              vsatp_changed,
  input  logic [3:0]        hgatp_mode,
  input  logic              hgatp_changed,
  input  logic              priv_virt,

  input  logic              in_valid,
  input  logic [VPN_W-1:0]  in_vpn,

  input  logic              out_ready,
  output logic              out_valid,
  output l2tlb_req_info_t   out_req_info
);

  genvar gi;

  // ---------------------------------------------------------------------------
  // 最近预取记录窗口（去重）
  // ---------------------------------------------------------------------------
  // old_reqs 只用于去重（same_line 仅比较去 sector 位后的“行 VPN” [37:3]），
  //   而写入值 next_req 的低 sector 位恒 0（get_next_line 补 0）。故 old_reqs[i][2:0]
  //   在两侧都零扇出（golden 存 38 位、低 3 位是 golden-only dead-ref）。这里只存被比较的
  //   行 VPN（35 位），impl 侧不留任何死寄存器位。
  logic [OLD_REC_N-1:0][LINE_VPN_W-1:0] old_reqs;   // 只存行 VPN [37:3]
  logic [OLD_REC_N-1:0]            old_v;
  logic [OLD_IDX_W-1:0]            old_index;
  logic [VPN_W-1:0]                next_req;  // RegEnable(next_line, in_valid)
  logic                            v;         // 预取请求 valid 保持位

  wire flush = sfence_valid || satp_changed || vsatp_changed || hgatp_changed;

  // 当拍计算的“下一行” VPN。
  wire [VPN_W-1:0] next_line = get_next_line(in_vpn);

  // 去重：next_line 是否已在记录窗口中（有效且同行）。old_reqs 已是行 VPN，直接与
  //   next_line 的行段 [37:3] 比较。
  logic already_have;
  always_comb begin
    already_have = 1'b0;
    for (int i = 0; i < OLD_REC_N; i++)
      already_have |= old_v[i] && (old_reqs[i] == next_line[VPN_W-1:SECTOR_BITS]);
  end

  // 本拍是否产生一个新的预取（未被 flush、未重复）。
  wire input_valid = in_valid && !flush && !already_have;

  // 预取请求被 L2TLB 接收。
  wire out_fire = out_valid && out_ready;

  // ---------------------------------------------------------------------------
  // s2xlate 模式选择（MuxCase 优先级：allStage > onlyStage1 > onlyStage2 > noS2）
  // ---------------------------------------------------------------------------
  logic [1:0] s2xlate;
  always_comb begin
    if      (priv_virt && (vsatp_mode != 4'h0) && (hgatp_mode != 4'h0)) s2xlate = ALL_STAGE;
    else if (priv_virt && (vsatp_mode != 4'h0))                          s2xlate = ONLY_STAGE1;
    else if (priv_virt && (hgatp_mode != 4'h0))                          s2xlate = ONLY_STAGE2;
    else                                                                 s2xlate = NO_S2XLATE;
  end

  // ---------------------------------------------------------------------------
  // 输出
  // ---------------------------------------------------------------------------
  assign out_valid          = v;
  assign out_req_info.vpn   = next_req;
  assign out_req_info.s2xlate = s2xlate;
  assign out_req_info.source  = PREFETCH_ID;

  // ---------------------------------------------------------------------------
  // 时序逻辑
  // ---------------------------------------------------------------------------
  // next_req：in.valid 拍锁存 next_line（无复位，与 golden 一致）。
  always_ff @(posedge clock) begin
    if (in_valid)
      next_req <= next_line;
  end

  // 记录窗口写入：out.fire 时把 next_req 写到 old_index 指向的槽。
  // old_reqs 无复位（与 golden 一致），old_v 有复位。
  generate
    for (gi = 0; gi < OLD_REC_N; gi = gi + 1) begin : g_rec
      wire slot_we = out_fire && (old_index == gi[OLD_IDX_W-1:0]);
      always_ff @(posedge clock) begin
        if (slot_we)
          old_reqs[gi] <= next_req[VPN_W-1:SECTOR_BITS];  // 只存行 VPN（低 3 位恒 0，不存）
      end
      always_ff @(posedge clock or posedge reset) begin
        if (reset)
          old_v[gi] <= 1'b0;
        else
          old_v[gi] <= !flush && (slot_we || old_v[gi]);
      end
    end
  endgenerate

  // 环形写指针 old_index：out.fire 时 +1（到顶回 0）。
  // valid 保持 v = ValidHold(input_valid, out.fire, flush)。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      old_index <= '0;
      v         <= 1'b0;
    end else begin
      if (out_fire)
        old_index <= (old_index == OLD_REC_N - 1) ? '0 : old_index + 1'b1;
      v <= !flush && (input_valid || (!out_fire && v));
    end
  end

endmodule
