// =============================================================================
// xs_TLArbiterRoundRobin —— TileLink 通道仲裁器（rocket-chip TLArbiter.roundRobin 的可读实现）
//
// 位置：共享辅助件（Chisel 把 TLArbiter 内联进使用者，golden 里没有独立模块）。
//   TLXbar 的每个出口通道（A/C 由主口汇入从口，B/D 由从口汇回主口）各用一份；
//   本仓第一批使用者是 TLXbar_5（L2 前的 3 主 × 4 从）与 TLXbar_6（外设总线 2 主 × 3 从）。
//   兄弟件 xs_TLArbiterLowest 是同一骨架的"下标小者优先"策略。
//
// 语义（rocket-chip tilelink/Arbiter.scala，policy = roundRobin）：
//   · 优先级掩码 mask（RegInit 全 1）：被服务过的那一路及它之前的路下一轮降到最低优先级。
//     grant 的算法：filter = {valid & ~mask, valid}（2N 位，高半段是"还没轮到过"的请求）；
//     unready = (rightOR(filter) >> 1) | (mask << N)；grant = ~(unready[2N-1:N] & unready[N-1:0])。
//     直观地说：高半段里有人就只在高半段里取最低下标，否则在全体里取最低下标。
//   · 空闲（beats_left == 0）时每拍重算 winner = grant & valid；sink 接受（latch = 空闲 && sink_ready）
//     时锁住 winner，并把这条消息剩余拍数（src_beats1）装进 beats_left，同时 mask <= leftOR(winner)。
//   · 多拍消息进行中（beats_left != 0）固定服务 state 记住的那一路，每 fire 一拍减 1。
//   · src_ready[k] = sink_ready && (空闲 ? grant[k] : state[k])；
//     sink_valid   = 空闲 ? 任一路 valid : state 那一路的 valid；
//     sink_bits    = Mux1H(空闲 ? winner : state, src_bits)：按位或，无人被选时为 0。
//   复位：beats_left / state 异步复位 0，mask 异步复位全 1（RegInit）。
//
// 参数：N 路，每路载荷 W 位；拍数计数 1 位（本仓两个使用者的消息最多 2 拍：
//   TLXbar_5 数据 256 位、块 512 位；TLXbar_6 全部单拍，src_beats1 接 0 让计数退化）。
// =============================================================================
module xs_TLArbiterRoundRobin #(
  parameter int unsigned N = 2,
  parameter int unsigned W = 1
)(
  input  logic                clock,
  input  logic                reset,
  // 各路源（下标 0 在同优先级时最先）
  input  logic [N-1:0]        src_valid,
  output logic [N-1:0]        src_ready,
  input  logic [N-1:0][W-1:0] src_bits,
  input  logic [N-1:0]        src_beats1,   // 这条消息还有第二拍
  // 汇
  input  logic                sink_ready,
  output logic                sink_valid,
  output logic [W-1:0]        sink_bits
);

  initial begin
    if (N < 1 || W < 1)
      $fatal(1, "xs_TLArbiterRoundRobin: N=%0d W=%0d 不合法", N, W);
  end

  // ---- 前缀 OR 工具（rocket-chip util.leftOR / rightOR）----
  // leftOR(x)[i]  = OR(x[i:0])，把置位向高位传播；
  // rightOR(x)[i] = OR(x[2N-1:i])，把置位向低位传播，Scala 里 cap=N 只做到 log2(N) 步。
  function automatic logic [N-1:0] left_or(input logic [N-1:0] x);
    logic [N-1:0] r;
    r = x;
    for (int s = 1; s < N; s = s << 1) r = r | (r << s);
    return r;
  endfunction

  function automatic logic [2*N-1:0] right_or_capped(input logic [2*N-1:0] x);
    logic [2*N-1:0] r;
    r = x;
    for (int s = 1; s < N; s = s << 1) r = r | (r >> s);
    return r;
  endfunction

  // round-robin 授权：各源 valid 与优先级 mask -> 授权向量（至多一位为 1）
  function automatic logic [N-1:0] rr_grant(input logic [N-1:0] valid, input logic [N-1:0] mask);
    logic [2*N-1:0] filter, unready;
    filter  = {(valid & ~mask), valid};
    unready = (right_or_capped(filter) >> 1) | ({{N{1'b0}}, mask} << N);
    return ~(unready[2*N-1 -: N] & unready[N-1:0]);
  endfunction

  // ---- 仲裁状态 ----
  logic         beats_left;   // 当前消息还剩一拍
  logic [N-1:0] mask;         // 优先级掩码
  logic [N-1:0] state;        // 多拍消息期间锁定的那一路（one-hot）

  wire          idle   = ~beats_left;
  wire          latch  = idle & sink_ready;
  wire [N-1:0]  grant  = rr_grant(src_valid, mask);
  wire [N-1:0]  winner = grant & src_valid;
  wire [N-1:0]  mux_sel = idle ? winner : state;
  wire [N-1:0]  allowed = idle ? grant  : state;

  assign sink_valid = idle ? (|src_valid) : (|(state & src_valid));
  assign src_ready  = {N{sink_ready}} & allowed;

  always_comb begin
    sink_bits = '0;
    for (int k = 0; k < N; k++)
      if (mux_sel[k]) sink_bits |= src_bits[k];
  end

  wire sink_fire = sink_ready & sink_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      beats_left <= 1'b0;
      mask       <= {N{1'b1}};
      state      <= '0;
    end else begin
      beats_left <= latch ? (|(winner & src_beats1)) : (beats_left - sink_fire);
      if (latch & (|src_valid))
        mask <= left_or(winner);
      if (idle)
        state <= winner;
    end
  end

endmodule
