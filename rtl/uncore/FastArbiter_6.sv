// =============================================================================
// FastArbiter_6.sv —— FastArbiter 家族薄 wrapper：L2 MSHRCtl 16 个 MSHR 发往 SourceB 的 Probe 请求仲裁
//
// 本变体规模：N=16 路，载荷打平 W=47 位（5 个字段，其中 1 个常量字段）。
//   例化者：MSHRCtl.sv（实例 source_b_arb）。
//   常量字段：每个请求方给这些字段喂的都是同一个常量，firtool 于是删掉了它们
//   的输入端口、把输出折成 `K & |chosenOH`。本文件把常量喂进每一路，核里的
//   Mux1H 自然得出同一结果：
//     opcode                   = 3'h6   —— MSHR.scala:435 ob.opcode := Probe
//   注：bits_alias 去掉 bits_ 前缀后撞上 SV 保留字，struct 成员名加 _f 后缀。
//
// 本文件只做"字段打包 → 核 → 拆包"的端口对位；仲裁逻辑（轮转 + 挂起记忆）
// 在 rtl/common/xs_FastArbiter_core.sv，全家族共一份。
// 本文件由 scripts/gen_fastarbiter_l2.py 生成，勿手改。
// golden 对照：G1-canonical/golden-rtl/FastArbiter_6.sv
// =============================================================================
package fastarbiter_6_pkg;
  // 载荷字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  typedef struct packed {
    logic [30:0] tag;
    logic [8:0]  set;
    logic [2:0]  opcode;  // 常量 3'h6
    logic [1:0]  param;
    logic [1:0]  alias_f;
  } payload_t;
endpackage

module FastArbiter_6 import fastarbiter_6_pkg::*; (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [30:0] io_in_0_bits_tag,
  input  [8:0]  io_in_0_bits_set,
  input  [1:0]  io_in_0_bits_param,
  input  [1:0]  io_in_0_bits_alias,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [30:0] io_in_1_bits_tag,
  input  [8:0]  io_in_1_bits_set,
  input  [1:0]  io_in_1_bits_param,
  input  [1:0]  io_in_1_bits_alias,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [30:0] io_in_2_bits_tag,
  input  [8:0]  io_in_2_bits_set,
  input  [1:0]  io_in_2_bits_param,
  input  [1:0]  io_in_2_bits_alias,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [30:0] io_in_3_bits_tag,
  input  [8:0]  io_in_3_bits_set,
  input  [1:0]  io_in_3_bits_param,
  input  [1:0]  io_in_3_bits_alias,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [30:0] io_in_4_bits_tag,
  input  [8:0]  io_in_4_bits_set,
  input  [1:0]  io_in_4_bits_param,
  input  [1:0]  io_in_4_bits_alias,
  output        io_in_5_ready,
  input         io_in_5_valid,
  input  [30:0] io_in_5_bits_tag,
  input  [8:0]  io_in_5_bits_set,
  input  [1:0]  io_in_5_bits_param,
  input  [1:0]  io_in_5_bits_alias,
  output        io_in_6_ready,
  input         io_in_6_valid,
  input  [30:0] io_in_6_bits_tag,
  input  [8:0]  io_in_6_bits_set,
  input  [1:0]  io_in_6_bits_param,
  input  [1:0]  io_in_6_bits_alias,
  output        io_in_7_ready,
  input         io_in_7_valid,
  input  [30:0] io_in_7_bits_tag,
  input  [8:0]  io_in_7_bits_set,
  input  [1:0]  io_in_7_bits_param,
  input  [1:0]  io_in_7_bits_alias,
  output        io_in_8_ready,
  input         io_in_8_valid,
  input  [30:0] io_in_8_bits_tag,
  input  [8:0]  io_in_8_bits_set,
  input  [1:0]  io_in_8_bits_param,
  input  [1:0]  io_in_8_bits_alias,
  output        io_in_9_ready,
  input         io_in_9_valid,
  input  [30:0] io_in_9_bits_tag,
  input  [8:0]  io_in_9_bits_set,
  input  [1:0]  io_in_9_bits_param,
  input  [1:0]  io_in_9_bits_alias,
  output        io_in_10_ready,
  input         io_in_10_valid,
  input  [30:0] io_in_10_bits_tag,
  input  [8:0]  io_in_10_bits_set,
  input  [1:0]  io_in_10_bits_param,
  input  [1:0]  io_in_10_bits_alias,
  output        io_in_11_ready,
  input         io_in_11_valid,
  input  [30:0] io_in_11_bits_tag,
  input  [8:0]  io_in_11_bits_set,
  input  [1:0]  io_in_11_bits_param,
  input  [1:0]  io_in_11_bits_alias,
  output        io_in_12_ready,
  input         io_in_12_valid,
  input  [30:0] io_in_12_bits_tag,
  input  [8:0]  io_in_12_bits_set,
  input  [1:0]  io_in_12_bits_param,
  input  [1:0]  io_in_12_bits_alias,
  output        io_in_13_ready,
  input         io_in_13_valid,
  input  [30:0] io_in_13_bits_tag,
  input  [8:0]  io_in_13_bits_set,
  input  [1:0]  io_in_13_bits_param,
  input  [1:0]  io_in_13_bits_alias,
  output        io_in_14_ready,
  input         io_in_14_valid,
  input  [30:0] io_in_14_bits_tag,
  input  [8:0]  io_in_14_bits_set,
  input  [1:0]  io_in_14_bits_param,
  input  [1:0]  io_in_14_bits_alias,
  output        io_in_15_ready,
  input         io_in_15_valid,
  input  [30:0] io_in_15_bits_tag,
  input  [8:0]  io_in_15_bits_set,
  input  [1:0]  io_in_15_bits_param,
  input  [1:0]  io_in_15_bits_alias,
  input         io_out_ready,
  output        io_out_valid,
  output [30:0] io_out_bits_tag,
  output [8:0]  io_out_bits_set,
  output [2:0]  io_out_bits_opcode,
  output [1:0]  io_out_bits_param,
  output [1:0]  io_out_bits_alias
);
  localparam int N = 16;
  localparam int W = $bits(payload_t);

  // ---- 打包：第 i 路的全部字段按字段表拼成一个 payload_t（常量字段每路都喂同一个值）
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = '{
    tag: io_in_0_bits_tag,
    set: io_in_0_bits_set,
    opcode: 3'h6,
    param: io_in_0_bits_param,
    alias_f: io_in_0_bits_alias
  };
  assign in_payload[1] = '{
    tag: io_in_1_bits_tag,
    set: io_in_1_bits_set,
    opcode: 3'h6,
    param: io_in_1_bits_param,
    alias_f: io_in_1_bits_alias
  };
  assign in_payload[2] = '{
    tag: io_in_2_bits_tag,
    set: io_in_2_bits_set,
    opcode: 3'h6,
    param: io_in_2_bits_param,
    alias_f: io_in_2_bits_alias
  };
  assign in_payload[3] = '{
    tag: io_in_3_bits_tag,
    set: io_in_3_bits_set,
    opcode: 3'h6,
    param: io_in_3_bits_param,
    alias_f: io_in_3_bits_alias
  };
  assign in_payload[4] = '{
    tag: io_in_4_bits_tag,
    set: io_in_4_bits_set,
    opcode: 3'h6,
    param: io_in_4_bits_param,
    alias_f: io_in_4_bits_alias
  };
  assign in_payload[5] = '{
    tag: io_in_5_bits_tag,
    set: io_in_5_bits_set,
    opcode: 3'h6,
    param: io_in_5_bits_param,
    alias_f: io_in_5_bits_alias
  };
  assign in_payload[6] = '{
    tag: io_in_6_bits_tag,
    set: io_in_6_bits_set,
    opcode: 3'h6,
    param: io_in_6_bits_param,
    alias_f: io_in_6_bits_alias
  };
  assign in_payload[7] = '{
    tag: io_in_7_bits_tag,
    set: io_in_7_bits_set,
    opcode: 3'h6,
    param: io_in_7_bits_param,
    alias_f: io_in_7_bits_alias
  };
  assign in_payload[8] = '{
    tag: io_in_8_bits_tag,
    set: io_in_8_bits_set,
    opcode: 3'h6,
    param: io_in_8_bits_param,
    alias_f: io_in_8_bits_alias
  };
  assign in_payload[9] = '{
    tag: io_in_9_bits_tag,
    set: io_in_9_bits_set,
    opcode: 3'h6,
    param: io_in_9_bits_param,
    alias_f: io_in_9_bits_alias
  };
  assign in_payload[10] = '{
    tag: io_in_10_bits_tag,
    set: io_in_10_bits_set,
    opcode: 3'h6,
    param: io_in_10_bits_param,
    alias_f: io_in_10_bits_alias
  };
  assign in_payload[11] = '{
    tag: io_in_11_bits_tag,
    set: io_in_11_bits_set,
    opcode: 3'h6,
    param: io_in_11_bits_param,
    alias_f: io_in_11_bits_alias
  };
  assign in_payload[12] = '{
    tag: io_in_12_bits_tag,
    set: io_in_12_bits_set,
    opcode: 3'h6,
    param: io_in_12_bits_param,
    alias_f: io_in_12_bits_alias
  };
  assign in_payload[13] = '{
    tag: io_in_13_bits_tag,
    set: io_in_13_bits_set,
    opcode: 3'h6,
    param: io_in_13_bits_param,
    alias_f: io_in_13_bits_alias
  };
  assign in_payload[14] = '{
    tag: io_in_14_bits_tag,
    set: io_in_14_bits_set,
    opcode: 3'h6,
    param: io_in_14_bits_param,
    alias_f: io_in_14_bits_alias
  };
  assign in_payload[15] = '{
    tag: io_in_15_bits_tag,
    set: io_in_15_bits_set,
    opcode: 3'h6,
    param: io_in_15_bits_param,
    alias_f: io_in_15_bits_alias
  };

  // ---- 核例化：仲裁逻辑全在 xs_FastArbiter_core
  payload_t out_payload;
  xs_FastArbiter_core #(.N(N), .W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_15_valid, io_in_14_valid, io_in_13_valid, io_in_12_valid,
                 io_in_11_valid, io_in_10_valid, io_in_9_valid, io_in_8_valid,
                 io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid,
                 io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid}),
    .in_bits   (in_payload),
    .in_ready  ({io_in_15_ready, io_in_14_ready, io_in_13_ready, io_in_12_ready,
                 io_in_11_ready, io_in_10_ready, io_in_9_ready, io_in_8_ready,
                 io_in_7_ready, io_in_6_ready, io_in_5_ready, io_in_4_ready,
                 io_in_3_ready, io_in_2_ready, io_in_1_ready, io_in_0_ready}),
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_payload)
  );

  // ---- 拆包：与打包共用同一张字段表
  assign io_out_bits_tag = out_payload.tag;
  assign io_out_bits_set = out_payload.set;
  assign io_out_bits_opcode = out_payload.opcode;
  assign io_out_bits_param = out_payload.param;
  assign io_out_bits_alias = out_payload.alias_f;
endmodule
