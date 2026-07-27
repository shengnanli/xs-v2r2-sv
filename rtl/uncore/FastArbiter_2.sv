// =============================================================================
//  FastArbiter_2 —— 4 路 round-robin 仲裁器可读核 (xs_FastArbiter_2_core)
// -----------------------------------------------------------------------------
//  TL2CHICoupledL2 直接子: prefetch 请求通道 4 路 FastArbiter, payload 仅 pfSource
//  (5 位 prefetch 源标签)。算法 = utility.FastArbiter "带挂起记忆的 round-robin":
//    两个 4 位状态寄存器 (复位 0):
//      pendingMask : 上一拍 valid 但未被选中的输入 (本轮欠服务者)。
//      rrGrantMask : 优先区掩码 = 上次胜者下标之后的所有下标。
//    组合选胜:
//      rrSelOH  = lowest_oh(rrGrantMask & pendingMask)  // 欠服务且落优先区里取最低下标
//      chosenOH = (rrSelOH 命中当前 valid) ? rrSelOH : lowest_oh(valids)  // 否则退化固定优先级
//    胜者更新 (下游 ready 且本拍有请求时):
//      pendingMask <= valids & ~chosenOH
//      rrGrantMask <= gt_mask(chosenOH)   // bit[i]=OR(chosenOH[i-1:0]), bit0 恒 0
//  握手: io_in_i_ready = chosenOH[i] & io_out_ready; io_out_valid = |valids。
//  与 golden FastArbiter_2 逐位等价 (同 FastArbiter_1/27/44/46/47, 仅 payload 不同)。
// =============================================================================
module xs_FastArbiter_2_core (
  input        clock,
  input        reset,
  output       io_in_0_ready,
  input        io_in_0_valid,
  input  [4:0] io_in_0_bits_pfSource,
  output       io_in_1_ready,
  input        io_in_1_valid,
  input  [4:0] io_in_1_bits_pfSource,
  output       io_in_2_ready,
  input        io_in_2_valid,
  input  [4:0] io_in_2_bits_pfSource,
  output       io_in_3_ready,
  input        io_in_3_valid,
  input  [4:0] io_in_3_bits_pfSource,
  input        io_out_ready,
  output       io_out_valid,
  output [4:0] io_out_bits_pfSource
);

  localparam int unsigned NUM = 4;

  logic [NUM-1:0] valids;
  logic [4:0]     pin [NUM];

  assign valids = {io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign pin[0] = io_in_0_bits_pfSource;
  assign pin[1] = io_in_1_bits_pfSource;
  assign pin[2] = io_in_2_bits_pfSource;
  assign pin[3] = io_in_3_bits_pfSource;

  // ---- round-robin 状态 + 组合选胜 ----
  reg   [NUM-1:0] pendingMask;
  reg   [NUM-1:0] rrGrantMask;
  logic [NUM-1:0] chosenOH;

  // rrSelOH = lowest_oh(rrGrantMask & pendingMask): 欠服务且落优先区里取下标最小者。
  logic [NUM-1:0] cand;
  logic [NUM-1:0] rrSelOH;
  assign cand    = rrGrantMask & pendingMask;
  assign rrSelOH = cand & (~cand + {{(NUM-1){1'b0}}, 1'b1});   // x & -x = 隔离最低置位
  // chosenOH: rrSelOH 命中 valid 则取之, 否则退化对 valids 取固定优先级最低位。
  logic [NUM-1:0] baseOH;
  assign baseOH   = valids & (~valids + {{(NUM-1){1'b0}}, 1'b1});
  assign chosenOH = (|(rrSelOH & valids)) ? rrSelOH : baseOH;

  // gt_mask(chosenOH): bit[i] = OR(chosenOH[i-1:0]); bit0 恒 0。
  logic [NUM-1:0] gtMask;
  always_comb begin
    gtMask = '0;
    for (int i = 0; i < NUM; i++)
      gtMask[i] = |(chosenOH & ((NUM'(1) << i) - NUM'(1)));
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      pendingMask <= '0;
      rrGrantMask <= '0;
    end else if (io_out_ready & (|valids)) begin
      pendingMask <= valids & ~chosenOH;
      rrGrantMask <= gtMask;
    end
  end

  // ---- 胜者 payload one-hot OR 归约 ----
  logic [4:0] psel;
  always_comb begin
    psel = '0;
    for (int i = 0; i < NUM; i++)
      if (chosenOH[i]) psel |= pin[i];
  end

  assign io_in_0_ready = chosenOH[0] & io_out_ready;
  assign io_in_1_ready = chosenOH[1] & io_out_ready;
  assign io_in_2_ready = chosenOH[2] & io_out_ready;
  assign io_in_3_ready = chosenOH[3] & io_out_ready;

  assign io_out_valid        = |valids;
  assign io_out_bits_pfSource = psel;

endmodule
