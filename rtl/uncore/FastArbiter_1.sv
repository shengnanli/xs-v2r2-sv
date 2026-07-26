// =============================================================================
//  FastArbiter_1 —— 4 路 round-robin 仲裁器可读核 (xs_FastArbiter_1_core)
// -----------------------------------------------------------------------------
//  TL2CHICoupledL2 直接子: L2 请求通道 4 路 FastArbiter, payload =
//  {tag(33)|set(9)|needT(1)|source(7)|vaddr(44)|reqsource(5)}。算法同 FastArbiter_2
//  (utility.FastArbiter 带挂起记忆 round-robin), 仅 payload 更宽; 见该文件头注释。
//  与 golden FastArbiter_1 逐位等价。
// =============================================================================
module xs_FastArbiter_1_core (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [32:0] io_in_0_bits_tag,
  input  [8:0]  io_in_0_bits_set,
  input         io_in_0_bits_needT,
  input  [6:0]  io_in_0_bits_source,
  input  [43:0] io_in_0_bits_vaddr,
  input  [4:0]  io_in_0_bits_reqsource,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [32:0] io_in_1_bits_tag,
  input  [8:0]  io_in_1_bits_set,
  input         io_in_1_bits_needT,
  input  [6:0]  io_in_1_bits_source,
  input  [43:0] io_in_1_bits_vaddr,
  input  [4:0]  io_in_1_bits_reqsource,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [32:0] io_in_2_bits_tag,
  input  [8:0]  io_in_2_bits_set,
  input         io_in_2_bits_needT,
  input  [6:0]  io_in_2_bits_source,
  input  [43:0] io_in_2_bits_vaddr,
  input  [4:0]  io_in_2_bits_reqsource,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [32:0] io_in_3_bits_tag,
  input  [8:0]  io_in_3_bits_set,
  input         io_in_3_bits_needT,
  input  [6:0]  io_in_3_bits_source,
  input  [43:0] io_in_3_bits_vaddr,
  input  [4:0]  io_in_3_bits_reqsource,
  input         io_out_ready,
  output        io_out_valid,
  output [32:0] io_out_bits_tag,
  output [8:0]  io_out_bits_set,
  output        io_out_bits_needT,
  output [6:0]  io_out_bits_source,
  output [43:0] io_out_bits_vaddr,
  output [4:0]  io_out_bits_reqsource
);

  localparam int unsigned NUM = 4;

  // payload 打包: tag(33)|set(9)|needT(1)|source(7)|vaddr(44)|reqsource(5) = 99 位
  localparam int unsigned W = 99;
  logic [NUM-1:0] valids;
  logic [W-1:0]   pin [NUM];

  assign valids = {io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign pin[0] = {io_in_0_bits_tag, io_in_0_bits_set, io_in_0_bits_needT,
                   io_in_0_bits_source, io_in_0_bits_vaddr, io_in_0_bits_reqsource};
  assign pin[1] = {io_in_1_bits_tag, io_in_1_bits_set, io_in_1_bits_needT,
                   io_in_1_bits_source, io_in_1_bits_vaddr, io_in_1_bits_reqsource};
  assign pin[2] = {io_in_2_bits_tag, io_in_2_bits_set, io_in_2_bits_needT,
                   io_in_2_bits_source, io_in_2_bits_vaddr, io_in_2_bits_reqsource};
  assign pin[3] = {io_in_3_bits_tag, io_in_3_bits_set, io_in_3_bits_needT,
                   io_in_3_bits_source, io_in_3_bits_vaddr, io_in_3_bits_reqsource};

  // ---- round-robin 状态 + 组合选胜 (同 FastArbiter_2) ----
  reg   [NUM-1:0] pendingMask;
  reg   [NUM-1:0] rrGrantMask;
  logic [NUM-1:0] chosenOH;

  logic [NUM-1:0] cand;
  logic [NUM-1:0] rrSelOH;
  assign cand    = rrGrantMask & pendingMask;
  assign rrSelOH = cand & (~cand + {{(NUM-1){1'b0}}, 1'b1});
  logic [NUM-1:0] baseOH;
  assign baseOH   = valids & (~valids + {{(NUM-1){1'b0}}, 1'b1});
  assign chosenOH = (|(rrSelOH & valids)) ? rrSelOH : baseOH;

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
  logic [W-1:0] psel;
  always_comb begin
    psel = '0;
    for (int i = 0; i < NUM; i++)
      if (chosenOH[i]) psel |= pin[i];
  end

  assign io_in_0_ready = chosenOH[0] & io_out_ready;
  assign io_in_1_ready = chosenOH[1] & io_out_ready;
  assign io_in_2_ready = chosenOH[2] & io_out_ready;
  assign io_in_3_ready = chosenOH[3] & io_out_ready;

  assign io_out_valid         = |valids;
  assign io_out_bits_tag       = psel[98:66];
  assign io_out_bits_set       = psel[65:57];
  assign io_out_bits_needT     = psel[56];
  assign io_out_bits_source    = psel[55:49];
  assign io_out_bits_vaddr     = psel[48:5];
  assign io_out_bits_reqsource = psel[4:0];

endmodule
