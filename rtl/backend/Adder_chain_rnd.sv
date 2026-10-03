// ============================================================================
// Adder_chain_rnd.sv —— 向量定点舍入的 8×8bit 可分段进位链加法器
//
// 在哪一层：后端向量定点单元 VFixPoint64b 内部，对 64 位数据按 8 个 byte lane
//   施加「加舍入增量」：dout[i] = din[i] + cin[i]（每 lane 加数只有 0/1）。
// IO：din/rndInc/dout 按 lane 展开（io_*_0..7）；io_sew_oneHot 给元素位宽
//   （8/16/32/64），io_isNClip 区分 clip 模式；io_cout_0..6 是 lane 0..6 的进位出
//   （cout[i] = (&din[i]) & cin[i]，加数为 1 且本 lane 全 1 才向上进位）；
//   io_all_1s_*/io_all_0s_* 是 lane 1..7 的全 1 / 全 0 检测，供上级饱和判断。
// 核心机制：每 lane 的进位入 cin 二选一 —— 元素起点取本 lane 自己的 rndInc，
//   元素内部接力上一 lane 的 cout。边界规则随 sew/isNClip 变化且奇偶 lane
//   不对称（lane2/6 与 lane4 的判据不同），这是 golden 的本意，原样保留。
// 纯组合逻辑：无时钟、无复位、无寄存器。
// ============================================================================

module xs_Adder_chain_rnd_core (
  input  logic [7:0] din [8],        // 8 个 byte lane 的被加数
  input  logic [7:0] rnd_inc,        // 每 lane 的舍入增量（0/1），在元素起点注入
  input  logic       is_nclip,       // clip 模式选择（参与进位分段判据）
  input  logic [3:0] sew_one_hot,    // 元素位宽 one-hot：[0]=8 [1]=16 [2]=32 [3]=64
  output logic [7:0] dout [8],       // 每 lane 的和（模 256，进位落入 cout）
  output logic [6:0] cout,           // lane 0..6 的进位出
  output logic [6:0] all_ones,       // lane 1..7 「全 1」检测
  output logic [6:0] all_zeros       // lane 1..7 「全 0」检测
);
  logic [7:0] lane_cin;

  assign lane_cin[0] = rnd_inc[0];
  for (genvar l = 1; l < 8; l++) begin : g_carry_in
    if (l % 2 == 1) begin : g_odd
      // 奇数 lane：仅「非 clip 且 8bit 元素」时是元素起点（用本 lane 的 rndInc），
      // 其余情形都接力上一 lane 的进位出。
      assign lane_cin[l] = (~is_nclip & sew_one_hot[0]) ? rnd_inc[l] : cout[l-1];
    end else if (l == 4) begin : g_lane4
      // lane4：clip 模式下 32bit 元素内部才接力；非 clip 模式下仅 64bit 元素内部接力。
      assign lane_cin[l] = (is_nclip ? sew_one_hot[2] : sew_one_hot[3])
                         ? cout[l-1] : rnd_inc[l];
    end else begin : g_lane26
      // lane2/6：clip 模式下 32/16bit、非 clip 模式下 64/32bit 元素内部接力。
      assign lane_cin[l] = (|(is_nclip ? sew_one_hot[2:1] : sew_one_hot[3:2]))
                         ? cout[l-1] : rnd_inc[l];
    end
  end

  for (genvar l = 0; l < 8; l++) begin : g_lane
    assign dout[l] = din[l] + {7'b0, lane_cin[l]};
    if (l < 7) begin : g_detect
      assign cout[l]      = (&din[l]) & lane_cin[l];
      assign all_ones[l]  = &din[l+1];
      assign all_zeros[l] = din[l+1] == 8'h00;
    end
  end
endmodule

// BEGIN GENERATED(wrapper) —— scripts/gen_arithvec_leaves5.py 生成，勿手改
module Adder_chain_rnd(
  input  [7:0] io_din_0,
  input  [7:0] io_din_1,
  input  [7:0] io_din_2,
  input  [7:0] io_din_3,
  input  [7:0] io_din_4,
  input  [7:0] io_din_5,
  input  [7:0] io_din_6,
  input  [7:0] io_din_7,
  input  io_rndInc_0,
  input  io_rndInc_1,
  input  io_rndInc_2,
  input  io_rndInc_3,
  input  io_rndInc_4,
  input  io_rndInc_5,
  input  io_rndInc_6,
  input  io_rndInc_7,
  input  io_isNClip,
  input  [3:0] io_sew_oneHot,
  output [7:0] io_dout_0,
  output [7:0] io_dout_1,
  output [7:0] io_dout_2,
  output [7:0] io_dout_3,
  output [7:0] io_dout_4,
  output [7:0] io_dout_5,
  output [7:0] io_dout_6,
  output [7:0] io_dout_7,
  output io_cout_0,
  output io_cout_1,
  output io_cout_2,
  output io_cout_3,
  output io_cout_4,
  output io_cout_5,
  output io_cout_6,
  output io_all_1s_1,
  output io_all_1s_2,
  output io_all_1s_3,
  output io_all_1s_4,
  output io_all_1s_5,
  output io_all_1s_6,
  output io_all_1s_7,
  output io_all_0s_1,
  output io_all_0s_2,
  output io_all_0s_3,
  output io_all_0s_4,
  output io_all_0s_5,
  output io_all_0s_6,
  output io_all_0s_7
);

  // ---- golden 扁平端口 <-> 核语义端口的拆装（生成）----
  logic [7:0] rnd_inc;
  logic [6:0] cout;
  logic [6:0] all_ones;
  logic [6:0] all_zeros;
  logic [7:0] din [8];
  logic [7:0] dout [8];

  assign rnd_inc = {io_rndInc_7, io_rndInc_6, io_rndInc_5, io_rndInc_4, io_rndInc_3, io_rndInc_2, io_rndInc_1, io_rndInc_0};
  assign {io_cout_6, io_cout_5, io_cout_4, io_cout_3, io_cout_2, io_cout_1, io_cout_0} = cout;
  assign {io_all_1s_7, io_all_1s_6, io_all_1s_5, io_all_1s_4, io_all_1s_3, io_all_1s_2, io_all_1s_1} = all_ones;
  assign {io_all_0s_7, io_all_0s_6, io_all_0s_5, io_all_0s_4, io_all_0s_3, io_all_0s_2, io_all_0s_1} = all_zeros;
  assign din[0] = io_din_0;
  assign din[1] = io_din_1;
  assign din[2] = io_din_2;
  assign din[3] = io_din_3;
  assign din[4] = io_din_4;
  assign din[5] = io_din_5;
  assign din[6] = io_din_6;
  assign din[7] = io_din_7;
  assign io_dout_0 = dout[0];
  assign io_dout_1 = dout[1];
  assign io_dout_2 = dout[2];
  assign io_dout_3 = dout[3];
  assign io_dout_4 = dout[4];
  assign io_dout_5 = dout[5];
  assign io_dout_6 = dout[6];
  assign io_dout_7 = dout[7];

  xs_Adder_chain_rnd_core u_core (
    .din (din),
    .rnd_inc (rnd_inc),
    .is_nclip (io_isNClip),
    .sew_one_hot (io_sew_oneHot),
    .dout (dout),
    .cout (cout),
    .all_ones (all_ones),
    .all_zeros (all_zeros)
  );
endmodule
// END GENERATED(wrapper)
