// =============================================================================
// xs_OverrideableQueue_core —— "可覆盖"环形队列：入口不看 ready，满了就覆盖最老的表项
//
// 对应 Chisel：utils/OverrideableQueue.scala（OverrideableQueue[T](gen, n)）。
// 在哪一层：MemBlock 的 SMS 预取器 PatternHistoryTable 里两处：
//   lookup_queue（OverrideableQueue，PHT 查询请求排队）与 evict_queue（OverrideableQueue_1，AGT 逐出写回 PHT 排队），
//   都是 n = 4。上游是"有就发、不等"的 ValidIO，所以队列满时新来的会覆盖写指针处的旧表项——
//   预取信息丢几条无所谓，换来入口永不反压。
//
// 机制（逐条对应 Scala）：
//   · 两个指针 wr_ptr / rd_ptr，各 log2(N) 位、自然回绕；in.valid 时 wr_ptr+1，out.fire 时 rd_ptr+1。
//   · 每个表项一个 valid：被读走（rd_ptr 指着它且 out.fire）清 0；被写（wr_ptr 指着它且 in.valid）置 1。
//     ★同一拍既读走又被写时，写赢★（Scala 里写的 when 在后）。
//   · 出口 = rd_ptr 指的那一项：out.valid = valids[rd_ptr]，out.bits = entries[rd_ptr]
//     （Scala 用 Mux1H(r_mask, ...)，r_mask 恒为 one-hot，等价于按 rd_ptr 下标选）。
//   · 覆盖不推进 rd_ptr：满时写进 rd_ptr 处，读出的就是刚写的新值，较老的几项按原顺序继续排着。
// 复位：valids / 两个指针 ★异步★复位到 0；表项数据不复位（golden 为无复位的 always @(posedge clock)，
//   复位期间 in.valid 仍会写数据——所以数据寄存器绝不能放进带复位的 always 块）。
// =============================================================================
module xs_OverrideableQueue_core #(
  parameter int unsigned N = 4,   // 表项数（2 的幂）
  parameter int unsigned W = 1    // 载荷打平后的位宽
)(
  input  logic         clock,
  input  logic         reset,
  input  logic         in_valid,
  input  logic [W-1:0] in_bits,
  input  logic         out_ready,
  output logic         out_valid,
  output logic [W-1:0] out_bits
);

  localparam int unsigned PTR_W = $clog2(N);

  initial begin
    if (N < 2 || (1 << PTR_W) != N)
      $fatal(1, "xs_OverrideableQueue_core: N=%0d 必须是 >=2 的 2 的幂（指针靠自然回绕）", N);
  end

  logic [N-1:0][W-1:0] entries;   // 表项载荷（不复位）
  logic [N-1:0]        valids;    // 表项有效位
  logic [PTR_W-1:0]    rd_ptr;
  logic [PTR_W-1:0]    wr_ptr;

  // ---------------------------------------------------------------------------
  // 1. 出口：rd_ptr 指的那一项
  // ---------------------------------------------------------------------------
  logic out_fire;
  assign out_valid = valids[rd_ptr];
  assign out_bits  = entries[rd_ptr];
  assign out_fire  = out_valid & out_ready;

  // ---------------------------------------------------------------------------
  // 2. 写入：in.valid 就写 wr_ptr 处（不管该项是否还有效——这就是"可覆盖"）
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (in_valid)
      entries[wr_ptr] <= in_bits;
  end

  // ---------------------------------------------------------------------------
  // 3. 有效位与指针：读走清 0，写入置 1，同拍写赢
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      valids <= '0;
      rd_ptr <= '0;
      wr_ptr <= '0;
    end else begin
      for (int unsigned i = 0; i < N; i++) begin
        if (in_valid && wr_ptr == PTR_W'(i))
          valids[i] <= 1'b1;
        else if (out_fire && rd_ptr == PTR_W'(i))
          valids[i] <= 1'b0;
      end
      if (out_fire)
        rd_ptr <= rd_ptr + 1'b1;
      if (in_valid)
        wr_ptr <= wr_ptr + 1'b1;
    end
  end

endmodule
