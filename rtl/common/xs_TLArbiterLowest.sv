// =============================================================================
// xs_TLArbiterLowest —— TileLink 通道仲裁器（rocket-chip TLArbiter.lowest 的可读实现）
//
// 位置：共享辅助件（Chisel 把 TLArbiter 内联进使用者，golden 里没有独立模块）。
//   本仓第一个使用者是 DCache MissQueue：A 通道（CMOUnit + 流水寄存器 + 16 个 MSHR 共 18 路）
//   与 E 通道（16 个 MSHR 的 GrantAck）各用一份。
//
// 语义（rocket-chip tilelink/Arbiter.scala，policy = lowestIndexFirst）：
//   · 空闲（beats_left == 0）时按"下标小的优先"选出 winner；sink 接受时（latch = 空闲 && sink_ready）
//     锁住这一路，并把它这条消息剩余的拍数（src_beats1）装进 beats_left；
//   · 多拍消息发送期间（beats_left != 0）固定服务 state 记住的那一路，每 fire 一拍减 1；
//   · state <= muxState（空闲时 = 本拍 winner，否则保持）—— 空闲时每拍都会刷新；
//   · src_ready[k] = sink_ready && (空闲 ? 没有更高优先级在请求 : state[k])；
//   · sink_valid   = 空闲 ? 任一路 valid : state 那一路的 valid；
//   · sink_bits    = Mux1H(muxState, src_bits)：按位或，无人被选时为 0。
//   复位：beats_left 与 state 均为异步复位 0（RegInit）。
//
// 参数：N 路，每路载荷 W 位，拍数计数 BEATS_W 位（本配置 1 位：一行最多 2 拍）。
// =============================================================================
module xs_TLArbiterLowest #(
  parameter int unsigned N       = 2,
  parameter int unsigned W       = 1,
  parameter int unsigned BEATS_W = 1
)(
  input  logic                       clock,
  input  logic                       reset,
  // 各路源（下标 0 优先级最高）
  input  logic [N-1:0]               src_valid,
  output logic [N-1:0]               src_ready,
  input  logic [N-1:0][W-1:0]        src_bits,
  input  logic [N-1:0][BEATS_W-1:0]  src_beats1,   // 这条消息的拍数 - 1
  // 汇
  input  logic                       sink_ready,
  output logic                       sink_valid,
  output logic [W-1:0]               sink_bits
);

  logic [BEATS_W-1:0] beats_left;
  logic [N-1:0]       state;        // 上一次锁定的那一路（one-hot）

  wire idle  = beats_left == '0;
  wire latch = idle & sink_ready;

  // lowestIndexFirst：readys[k] = 没有比 k 更小的下标在请求
  logic [N-1:0] readys, winner, mux_state, allowed;
  always_comb begin
    logic any_lower;
    any_lower = 1'b0;
    for (int k = 0; k < N; k++) begin
      readys[k] = ~any_lower;
      any_lower = any_lower | src_valid[k];
    end
  end
  assign winner    = readys & src_valid;
  assign mux_state = idle ? winner : state;
  assign allowed   = idle ? readys : state;
  assign src_ready = allowed & {N{sink_ready}};
  assign sink_valid = idle ? |src_valid : |(state & src_valid);

  // Mux1H(muxState, bits) 与 winner 对应的拍数
  logic [BEATS_W-1:0] init_beats;
  always_comb begin
    sink_bits  = '0;
    init_beats = '0;
    for (int k = 0; k < N; k++) begin
      if (mux_state[k]) sink_bits  = sink_bits | src_bits[k];
      if (winner[k])    init_beats = init_beats | src_beats1[k];
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      beats_left <= '0;
      state      <= '0;
    end else begin
      beats_left <= latch ? init_beats : beats_left - BEATS_W'(sink_ready & sink_valid);
      state      <= mux_state;
    end
  end

endmodule
