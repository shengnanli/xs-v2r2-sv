// =============================================================================
// FastArbiter_5.sv —— FastArbiter 家族薄 wrapper：L2 SourceB 4 个 probe 缓冲表项发往上层 B 通道的仲裁
//
// 本变体规模：N=4 路，载荷打平 W=47 位（5 个字段，其中 0 个常量字段）。
//   例化者：SourceB.sv（实例 issueArb）。
//   注：bits_alias 去掉 bits_ 前缀后撞上 SV 保留字，struct 成员名加 _f 后缀。
//
// 本文件只做"字段打包 → 核 → 拆包"的端口对位；仲裁逻辑（轮转 + 挂起记忆）
// 在 rtl/common/xs_FastArbiter_core.sv，全家族共一份。
// 本文件由 scripts/gen_fastarbiter_l2.py 生成，勿手改。
// golden 对照：G1-canonical/golden-rtl/FastArbiter_5.sv
// =============================================================================
package fastarbiter_5_pkg;
  // 载荷字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  typedef struct packed {
    logic [30:0] tag;
    logic [8:0]  set;
    logic [2:0]  opcode;
    logic [1:0]  param;
    logic [1:0]  alias_f;
  } payload_t;
endpackage

module FastArbiter_5 import fastarbiter_5_pkg::*; (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [30:0] io_in_0_bits_tag,
  input  [8:0]  io_in_0_bits_set,
  input  [2:0]  io_in_0_bits_opcode,
  input  [1:0]  io_in_0_bits_param,
  input  [1:0]  io_in_0_bits_alias,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [30:0] io_in_1_bits_tag,
  input  [8:0]  io_in_1_bits_set,
  input  [2:0]  io_in_1_bits_opcode,
  input  [1:0]  io_in_1_bits_param,
  input  [1:0]  io_in_1_bits_alias,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [30:0] io_in_2_bits_tag,
  input  [8:0]  io_in_2_bits_set,
  input  [2:0]  io_in_2_bits_opcode,
  input  [1:0]  io_in_2_bits_param,
  input  [1:0]  io_in_2_bits_alias,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [30:0] io_in_3_bits_tag,
  input  [8:0]  io_in_3_bits_set,
  input  [2:0]  io_in_3_bits_opcode,
  input  [1:0]  io_in_3_bits_param,
  input  [1:0]  io_in_3_bits_alias,
  input         io_out_ready,
  output        io_out_valid,
  output [30:0] io_out_bits_tag,
  output [8:0]  io_out_bits_set,
  output [2:0]  io_out_bits_opcode,
  output [1:0]  io_out_bits_param,
  output [1:0]  io_out_bits_alias
);
  localparam int N = 4;
  localparam int W = $bits(payload_t);

  // ---- 打包：第 i 路的全部字段按字段表拼成一个 payload_t（常量字段每路都喂同一个值）
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = '{
    tag: io_in_0_bits_tag,
    set: io_in_0_bits_set,
    opcode: io_in_0_bits_opcode,
    param: io_in_0_bits_param,
    alias_f: io_in_0_bits_alias
  };
  assign in_payload[1] = '{
    tag: io_in_1_bits_tag,
    set: io_in_1_bits_set,
    opcode: io_in_1_bits_opcode,
    param: io_in_1_bits_param,
    alias_f: io_in_1_bits_alias
  };
  assign in_payload[2] = '{
    tag: io_in_2_bits_tag,
    set: io_in_2_bits_set,
    opcode: io_in_2_bits_opcode,
    param: io_in_2_bits_param,
    alias_f: io_in_2_bits_alias
  };
  assign in_payload[3] = '{
    tag: io_in_3_bits_tag,
    set: io_in_3_bits_set,
    opcode: io_in_3_bits_opcode,
    param: io_in_3_bits_param,
    alias_f: io_in_3_bits_alias
  };

  // ---- 核例化：仲裁逻辑全在 xs_FastArbiter_core
  payload_t out_payload;
  xs_FastArbiter_core #(.N(N), .W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid}),
    .in_bits   (in_payload),
    .in_ready  ({io_in_3_ready, io_in_2_ready, io_in_1_ready, io_in_0_ready}),
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
