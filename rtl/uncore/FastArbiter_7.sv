// =============================================================================
//  FastArbiter_7 —— MSHRCtl source_b_arb (SourceB probe) 16 路 round-robin 仲裁器 (可读核 xs_FastArbiter_7_core)
// -----------------------------------------------------------------------------
//  L2 slice MSHRCtl 的 16 输入仲裁器: 16 个 MSHR 各出一路请求, 轮转选一路发往下游。
//  与 FastArbiter_1/2/27/28/29/44/46/47 同族 (utility.FastArbiter 带挂起记忆
//  round-robin), NUM=16; 本核用通用循环复刻 golden 的 16 位展平位表达式, 逐位等价:
//    rrSelOH  = lowest_oh(rrGrantMask & pendingMask)
//    chosenOH = (rrSelOH 命中 valid) ? rrSelOH : lowest_oh(valids)
//    pendingMask <= valids & ~chosenOH; rrGrantMask <= gt_mask(chosenOH)  (下游 ready 时)
//  握手: io_in_i_ready = chosenOH[i] & io_out_ready; io_out_valid = |valids。
//  payload 打包成 packed struct 后用胜者 one-hot OR 归约多路选择到 io_out。
//  无输入对应的常量输出字段 (忠实 golden, 全为 |chosenOH 的函数): opcode。
// =============================================================================
module xs_FastArbiter_7_core(
  input clock,
  input reset,
  output io_in_0_ready,
  input io_in_0_valid,
  input [30:0] io_in_0_bits_tag,
  input [8:0] io_in_0_bits_set,
  input [1:0] io_in_0_bits_param,
  input [1:0] io_in_0_bits_alias,
  output io_in_1_ready,
  input io_in_1_valid,
  input [30:0] io_in_1_bits_tag,
  input [8:0] io_in_1_bits_set,
  input [1:0] io_in_1_bits_param,
  input [1:0] io_in_1_bits_alias,
  output io_in_2_ready,
  input io_in_2_valid,
  input [30:0] io_in_2_bits_tag,
  input [8:0] io_in_2_bits_set,
  input [1:0] io_in_2_bits_param,
  input [1:0] io_in_2_bits_alias,
  output io_in_3_ready,
  input io_in_3_valid,
  input [30:0] io_in_3_bits_tag,
  input [8:0] io_in_3_bits_set,
  input [1:0] io_in_3_bits_param,
  input [1:0] io_in_3_bits_alias,
  output io_in_4_ready,
  input io_in_4_valid,
  input [30:0] io_in_4_bits_tag,
  input [8:0] io_in_4_bits_set,
  input [1:0] io_in_4_bits_param,
  input [1:0] io_in_4_bits_alias,
  output io_in_5_ready,
  input io_in_5_valid,
  input [30:0] io_in_5_bits_tag,
  input [8:0] io_in_5_bits_set,
  input [1:0] io_in_5_bits_param,
  input [1:0] io_in_5_bits_alias,
  output io_in_6_ready,
  input io_in_6_valid,
  input [30:0] io_in_6_bits_tag,
  input [8:0] io_in_6_bits_set,
  input [1:0] io_in_6_bits_param,
  input [1:0] io_in_6_bits_alias,
  output io_in_7_ready,
  input io_in_7_valid,
  input [30:0] io_in_7_bits_tag,
  input [8:0] io_in_7_bits_set,
  input [1:0] io_in_7_bits_param,
  input [1:0] io_in_7_bits_alias,
  output io_in_8_ready,
  input io_in_8_valid,
  input [30:0] io_in_8_bits_tag,
  input [8:0] io_in_8_bits_set,
  input [1:0] io_in_8_bits_param,
  input [1:0] io_in_8_bits_alias,
  output io_in_9_ready,
  input io_in_9_valid,
  input [30:0] io_in_9_bits_tag,
  input [8:0] io_in_9_bits_set,
  input [1:0] io_in_9_bits_param,
  input [1:0] io_in_9_bits_alias,
  output io_in_10_ready,
  input io_in_10_valid,
  input [30:0] io_in_10_bits_tag,
  input [8:0] io_in_10_bits_set,
  input [1:0] io_in_10_bits_param,
  input [1:0] io_in_10_bits_alias,
  output io_in_11_ready,
  input io_in_11_valid,
  input [30:0] io_in_11_bits_tag,
  input [8:0] io_in_11_bits_set,
  input [1:0] io_in_11_bits_param,
  input [1:0] io_in_11_bits_alias,
  output io_in_12_ready,
  input io_in_12_valid,
  input [30:0] io_in_12_bits_tag,
  input [8:0] io_in_12_bits_set,
  input [1:0] io_in_12_bits_param,
  input [1:0] io_in_12_bits_alias,
  output io_in_13_ready,
  input io_in_13_valid,
  input [30:0] io_in_13_bits_tag,
  input [8:0] io_in_13_bits_set,
  input [1:0] io_in_13_bits_param,
  input [1:0] io_in_13_bits_alias,
  output io_in_14_ready,
  input io_in_14_valid,
  input [30:0] io_in_14_bits_tag,
  input [8:0] io_in_14_bits_set,
  input [1:0] io_in_14_bits_param,
  input [1:0] io_in_14_bits_alias,
  output io_in_15_ready,
  input io_in_15_valid,
  input [30:0] io_in_15_bits_tag,
  input [8:0] io_in_15_bits_set,
  input [1:0] io_in_15_bits_param,
  input [1:0] io_in_15_bits_alias,
  input io_out_ready,
  output io_out_valid,
  output [30:0] io_out_bits_tag,
  output [8:0] io_out_bits_set,
  output [2:0] io_out_bits_opcode,
  output [1:0] io_out_bits_param,
  output [1:0] io_out_bits_alias
);

  localparam int unsigned NUM = 16;

  // ---- payload (打包成 packed struct, 便于 one-hot OR 多路选择; 字段序 = golden 端口序) ----
  typedef struct packed {
    logic [30:0] tag;
    logic [8:0] set;
    logic [1:0] param;
    logic [1:0] alias_f;
  } flit_t;

  flit_t          pin [NUM];
  logic [NUM-1:0] valids;

  assign valids = {io_in_15_valid, io_in_14_valid, io_in_13_valid, io_in_12_valid, io_in_11_valid, io_in_10_valid, io_in_9_valid, io_in_8_valid, io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid, io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign pin[0] = '{
    tag:io_in_0_bits_tag,
    set:io_in_0_bits_set,
    param:io_in_0_bits_param,
    alias_f:io_in_0_bits_alias
  };
  assign pin[1] = '{
    tag:io_in_1_bits_tag,
    set:io_in_1_bits_set,
    param:io_in_1_bits_param,
    alias_f:io_in_1_bits_alias
  };
  assign pin[2] = '{
    tag:io_in_2_bits_tag,
    set:io_in_2_bits_set,
    param:io_in_2_bits_param,
    alias_f:io_in_2_bits_alias
  };
  assign pin[3] = '{
    tag:io_in_3_bits_tag,
    set:io_in_3_bits_set,
    param:io_in_3_bits_param,
    alias_f:io_in_3_bits_alias
  };
  assign pin[4] = '{
    tag:io_in_4_bits_tag,
    set:io_in_4_bits_set,
    param:io_in_4_bits_param,
    alias_f:io_in_4_bits_alias
  };
  assign pin[5] = '{
    tag:io_in_5_bits_tag,
    set:io_in_5_bits_set,
    param:io_in_5_bits_param,
    alias_f:io_in_5_bits_alias
  };
  assign pin[6] = '{
    tag:io_in_6_bits_tag,
    set:io_in_6_bits_set,
    param:io_in_6_bits_param,
    alias_f:io_in_6_bits_alias
  };
  assign pin[7] = '{
    tag:io_in_7_bits_tag,
    set:io_in_7_bits_set,
    param:io_in_7_bits_param,
    alias_f:io_in_7_bits_alias
  };
  assign pin[8] = '{
    tag:io_in_8_bits_tag,
    set:io_in_8_bits_set,
    param:io_in_8_bits_param,
    alias_f:io_in_8_bits_alias
  };
  assign pin[9] = '{
    tag:io_in_9_bits_tag,
    set:io_in_9_bits_set,
    param:io_in_9_bits_param,
    alias_f:io_in_9_bits_alias
  };
  assign pin[10] = '{
    tag:io_in_10_bits_tag,
    set:io_in_10_bits_set,
    param:io_in_10_bits_param,
    alias_f:io_in_10_bits_alias
  };
  assign pin[11] = '{
    tag:io_in_11_bits_tag,
    set:io_in_11_bits_set,
    param:io_in_11_bits_param,
    alias_f:io_in_11_bits_alias
  };
  assign pin[12] = '{
    tag:io_in_12_bits_tag,
    set:io_in_12_bits_set,
    param:io_in_12_bits_param,
    alias_f:io_in_12_bits_alias
  };
  assign pin[13] = '{
    tag:io_in_13_bits_tag,
    set:io_in_13_bits_set,
    param:io_in_13_bits_param,
    alias_f:io_in_13_bits_alias
  };
  assign pin[14] = '{
    tag:io_in_14_bits_tag,
    set:io_in_14_bits_set,
    param:io_in_14_bits_param,
    alias_f:io_in_14_bits_alias
  };
  assign pin[15] = '{
    tag:io_in_15_bits_tag,
    set:io_in_15_bits_set,
    param:io_in_15_bits_param,
    alias_f:io_in_15_bits_alias
  };

  // ---- round-robin 状态 + 组合选胜 (NUM=16) ----
  reg   [NUM-1:0] pendingMask;
  reg   [NUM-1:0] rrGrantMask;
  logic [NUM-1:0] chosenOH;

  logic [NUM-1:0] cand;
  logic [NUM-1:0] rrSelOH;
  assign cand    = rrGrantMask & pendingMask;
  assign rrSelOH = cand & (~cand + {{(NUM-1){1'b0}}, 1'b1});   // x & -x = 隔离最低置位
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
      pendingMask <= valids & ~chosenOH;   // 没被选中的 valid 转入欠服务
      rrGrantMask <= gtMask;               // 优先区推进到本次胜者之后
    end
  end

  // ---- 胜者 payload 多路选择 (one-hot OR 归约, chosenOH 至多一位置位) ----
  flit_t psel;
  always_comb begin
    psel = '0;
    for (int i = 0; i < NUM; i++)
      if (chosenOH[i]) psel |= pin[i];
  end

  wire anyChosen = |chosenOH;

  // ---- 握手 ----
  assign io_in_0_ready = chosenOH[0] & io_out_ready;
  assign io_in_1_ready = chosenOH[1] & io_out_ready;
  assign io_in_2_ready = chosenOH[2] & io_out_ready;
  assign io_in_3_ready = chosenOH[3] & io_out_ready;
  assign io_in_4_ready = chosenOH[4] & io_out_ready;
  assign io_in_5_ready = chosenOH[5] & io_out_ready;
  assign io_in_6_ready = chosenOH[6] & io_out_ready;
  assign io_in_7_ready = chosenOH[7] & io_out_ready;
  assign io_in_8_ready = chosenOH[8] & io_out_ready;
  assign io_in_9_ready = chosenOH[9] & io_out_ready;
  assign io_in_10_ready = chosenOH[10] & io_out_ready;
  assign io_in_11_ready = chosenOH[11] & io_out_ready;
  assign io_in_12_ready = chosenOH[12] & io_out_ready;
  assign io_in_13_ready = chosenOH[13] & io_out_ready;
  assign io_in_14_ready = chosenOH[14] & io_out_ready;
  assign io_in_15_ready = chosenOH[15] & io_out_ready;

  assign io_out_valid = |valids;

  // ---- 输出 (共有字段来自 psel; 常量字段忠实 golden) ----
  assign io_out_bits_tag = psel.tag;
  assign io_out_bits_set = psel.set;
  assign io_out_bits_opcode = anyChosen ? 3'h6 : 3'h0;
  assign io_out_bits_param = psel.param;
  assign io_out_bits_alias = psel.alias_f;

endmodule
