// =============================================================================
// L2TlbPrefetch.sv —— L2TLB 的"下一行"页表预取器
//
// 对应 Chisel: xiangshan.cache.mmu.L2TlbPrefetch（src/main/scala/xiangshan/cache/mmu/L2TlbPrefetch.scala）
//
// 在 L2TLB 里的位置：
//     arb2 出口（进 page cache 的那一路，且是 itlb/dtlb 真请求）──in(vpn)──> L2TlbPrefetch
//     L2TlbPrefetch ──out──> arb2 第 4 路（Arbiter5_L2TlbWithHptwIdBundle，优先级最低）
//
// 机制（三步，下面的核按这三步分节）：
//   1. 训练：每来一个被访问的 vpn，就猜"下一条页表 cacheline"马上也要用。一条 cacheline
//      装 8 个 PTE（sector = vpn[2:0]），所以 next_line = {vpn[37:3] + 1, 3'b000}。
//      next_req = RegEnable(next_line, in.valid)：只要有输入就打一拍锁下来（不管去没去重）。
//   2. 去重：记住最近 4 条**已经发出去**的预取（old_reqs / old_v，old_index 轮转写）。
//      当拍的 next_line 若和其中某条有效记录同一行，就不再产生预取。
//   3. 发出：v = ValidHold(input_valid, out.fire, flush) —— 产生后一直举着，直到被 arb2 接走或被
//      flush 冲掉；接走那拍把 next_req 记进去重窗口。出口 s2xlate 按当前虚拟化模式现算，
//      source 恒为 prefetchID（=2，被 firtool 折进 arb2，本模块无该端口），isHptwReq/hptwId 同理。
//   flush = sfence 或 satp/vsatp/hgatp/priv.virt 任一变化：去重窗口清空、在途预取作废。
//
// ★注意时序上的一个不对称（照抄 golden）★：去重用的是**当拍组合** next_line，而发出去的是
//   **上一次** in.valid 时锁的 next_req。input_valid 置 v 的那拍 next_req 同时被改写，所以两者在
//   v 拉起时是同一个值；但 v 举着期间若又来 in.valid（去重命中或未命中都会改写 next_req），
//   发出去的就是最新那条 —— 预取器本来就是尽力而为，Chisel 原文如此。
//
// ★与 golden 的一处有意差别：去重窗口只存 35 位"行号" vpn[37:3]★
//   golden 存整 38 位，但低 3 位写入值恒 0（来自 next_line 的补 0）、比较时也不读 —— 写得进、零扇出。
//   本文件只存被比较的 35 位。FM 上 golden 那 12 个死位（old_reqs_0..3_reg[2:0]）在 impl 侧无对应点，
//   逐条声明在 verif/dead_ref/L2TlbPrefetch.json（PASS_DEAD_REF，impl 侧 unread=0）。
//
// golden 214 行 / 16 端口，纯叶子（无子模块）。
// =============================================================================

package l2tlbprefetch_pkg;

  localparam int VPN_W       = 38;               // vpnLen
  localparam int SECTOR_W    = 3;                // sectortlbwidth：一条页表 cacheline 8 个 PTE
  localparam int LINE_W      = VPN_W - SECTOR_W; // 行号 vpn[37:3]，35 位
  localparam int OLD_REC_N   = 4;                // OldRecordSize：去重窗口条数
  localparam int OLD_IDX_W   = 2;                // log2Ceil(OldRecordSize)

  // s2xlate 编码（MMUConst：noS2xlate / onlyStage1 / onlyStage2 / allStage）
  localparam logic [1:0] NO_S2XLATE  = 2'd0;
  localparam logic [1:0] ONLY_STAGE1 = 2'd1;
  localparam logic [1:0] ONLY_STAGE2 = 2'd2;
  localparam logic [1:0] ALL_STAGE   = 2'd3;

endpackage

module xs_L2TlbPrefetch_core
  import l2tlbprefetch_pkg::*;
(
  input  logic             clock,
  input  logic             reset,
  input  logic             flush,        // sfence 或任一地址翻译 CSR 变化
  // 虚拟化模式（决定预取请求走几级翻译）
  input  logic             priv_virt,
  input  logic [3:0]       vsatp_mode,
  input  logic [3:0]       hgatp_mode,
  // 训练输入：一次被访问的 vpn
  input  logic             in_valid,
  input  logic [VPN_W-1:0] in_vpn,
  // 预取请求出口
  input  logic             out_ready,
  output logic             out_valid,
  output logic [VPN_W-1:0] out_vpn,
  output logic [1:0]       out_s2xlate
);

  // ---------------------------------------------------------------------------
  // 1. 训练：算出"下一行"，有输入就锁进 next_req
  // ---------------------------------------------------------------------------
  // next_line 的行号 = 访问行号 + 1（35 位回绕加法），sector 位补 0。
  logic [LINE_W-1:0] next_line_no;
  logic [VPN_W-1:0]  next_req;      // 无复位（golden 同），初值靠第一次 in.valid 写入

  assign next_line_no = in_vpn[VPN_W-1:SECTOR_W] + 1'b1;

  always_ff @(posedge clock) begin
    if (in_valid)
      next_req <= {next_line_no, {SECTOR_W{1'b0}}};
  end

  // ---------------------------------------------------------------------------
  // 2. 去重：最近 OLD_REC_N 条已发出的预取行号
  // ---------------------------------------------------------------------------
  // old_line 无复位、old_v 异步复位（golden 同）。old_index 是下一条记录写到哪一槽的轮转指针。
  logic [LINE_W-1:0]    old_line [OLD_REC_N];
  logic [OLD_REC_N-1:0] old_v;
  logic [OLD_IDX_W-1:0] old_index;

  logic already_have;   // 当拍 next_line 已在窗口里
  always_comb begin
    already_have = 1'b0;
    for (int i = 0; i < OLD_REC_N; i++)
      already_have |= old_v[i] && (old_line[i] == next_line_no);
  end

  // 本拍产生一条新的预取
  logic input_valid;
  assign input_valid = in_valid && !flush && !already_have;

  // 预取被 arb2 接走：记进 old_index 那一槽、指针前进；flush 只清有效位（行号留着无所谓）。
  logic out_fire;
  assign out_fire = out_ready && out_valid;

  logic [OLD_REC_N-1:0] write_here;   // 本拍写哪一槽（独热或全 0）
  always_comb begin
    for (int i = 0; i < OLD_REC_N; i++)
      write_here[i] = out_fire && (old_index == OLD_IDX_W'(i));
  end

  always_ff @(posedge clock) begin
    for (int i = 0; i < OLD_REC_N; i++)
      if (write_here[i])
        old_line[i] <= next_req[VPN_W-1:SECTOR_W];
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      old_v <= '0;
    else
      old_v <= flush ? '0 : (old_v | write_here);
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      old_index <= '0;
    else if (out_fire)
      old_index <= (old_index == OLD_IDX_W'(OLD_REC_N - 1)) ? '0 : old_index + 1'b1;
  end

  // ---------------------------------------------------------------------------
  // 3. 发出：ValidHold 举着请求，s2xlate 现算
  // ---------------------------------------------------------------------------
  // ValidHold(infire, outfire, flush)：新请求置位；没新请求时被接走则清；flush 一律清。
  logic v;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      v <= 1'b0;
    else
      v <= !flush && (input_valid || (v && !out_fire));
  end

  // 虚拟化下：VS 级与 G 级都开 = 两级；只开 VS = 只走第一级；只开 G = 只走第二级。
  // 非虚拟化 = 不走二级翻译。（MuxCase 优先级照 Scala 顺序）
  logic vs_on, g_on;
  assign vs_on = priv_virt && (vsatp_mode != 4'd0);
  assign g_on  = priv_virt && (hgatp_mode != 4'd0);

  always_comb begin
    if (vs_on && g_on) out_s2xlate = ALL_STAGE;
    else if (vs_on)    out_s2xlate = ONLY_STAGE1;
    else if (g_on)     out_s2xlate = ONLY_STAGE2;
    else               out_s2xlate = NO_S2XLATE;
  end

  assign out_valid = v;
  assign out_vpn   = next_req;

endmodule

// golden 同名 wrapper：端口逐名逐宽同 golden，只做改名与 flush 五项 OR。
module L2TlbPrefetch (
  input  logic        clock,
  input  logic        reset,
  input  logic        io_sfence_valid,
  input  logic        io_csr_satp_changed,
  input  logic [3:0]  io_csr_vsatp_mode,
  input  logic        io_csr_vsatp_changed,
  input  logic [3:0]  io_csr_hgatp_mode,
  input  logic        io_csr_hgatp_changed,
  input  logic        io_csr_priv_virt,
  input  logic        io_csr_priv_virt_changed,
  input  logic        io_in_valid,
  input  logic [37:0] io_in_bits_vpn,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [37:0] io_out_bits_req_info_vpn,
  output logic [1:0]  io_out_bits_req_info_s2xlate
);

  xs_L2TlbPrefetch_core u_core (
    .clock       (clock),
    .reset       (reset),
    .flush       (io_sfence_valid | io_csr_satp_changed | io_csr_vsatp_changed
                  | io_csr_hgatp_changed | io_csr_priv_virt_changed),
    .priv_virt   (io_csr_priv_virt),
    .vsatp_mode  (io_csr_vsatp_mode),
    .hgatp_mode  (io_csr_hgatp_mode),
    .in_valid    (io_in_valid),
    .in_vpn      (io_in_bits_vpn),
    .out_ready   (io_out_ready),
    .out_valid   (io_out_valid),
    .out_vpn     (io_out_bits_req_info_vpn),
    .out_s2xlate (io_out_bits_req_info_s2xlate)
  );

endmodule
