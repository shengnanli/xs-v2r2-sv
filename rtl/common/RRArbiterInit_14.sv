// =============================================================================
// RRArbiterInit_14.sv —— 轮转仲裁器家族薄 wrapper：PrefetchReqBuffer 16 个表项的回收请求仲裁
//
// 本变体规模：仲裁宽度 N=16，payload 打平 W=50 位（1 个字段），chosen/lastGrant 4 位。
//   端口面：in_ready 输出有、out_ready 输入★无★、io_chosen 输出无。
//   （golden 里 io_out_ready 被常量 1 折掉了，所以端口表里没有它；本文件给核接 1'b1。）
//   例化者：PrefetchReqBuffer.sv。
//
// 本文件只做参数与端口对位；仲裁逻辑核在 rtl/common/RRArbiterInit.sv
// （模块 xs_RRArbiterInit_core），核体全家族共一份。本文件由
// verif/ut/RRArbiterInitVariants/gen.py 生成，勿手改。
//
// 设计源：rocket-chip util/Arbiters.scala (class LockingRRArbiter)
// golden 对照：G1-canonical/golden-rtl/RRArbiterInit_14.sv
// =============================================================================
module RRArbiterInit_14(
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [49:0] io_in_0_bits_vaddr,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [49:0] io_in_1_bits_vaddr,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [49:0] io_in_2_bits_vaddr,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [49:0] io_in_3_bits_vaddr,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [49:0] io_in_4_bits_vaddr,
  output        io_in_5_ready,
  input         io_in_5_valid,
  input  [49:0] io_in_5_bits_vaddr,
  output        io_in_6_ready,
  input         io_in_6_valid,
  input  [49:0] io_in_6_bits_vaddr,
  output        io_in_7_ready,
  input         io_in_7_valid,
  input  [49:0] io_in_7_bits_vaddr,
  output        io_in_8_ready,
  input         io_in_8_valid,
  input  [49:0] io_in_8_bits_vaddr,
  output        io_in_9_ready,
  input         io_in_9_valid,
  input  [49:0] io_in_9_bits_vaddr,
  output        io_in_10_ready,
  input         io_in_10_valid,
  input  [49:0] io_in_10_bits_vaddr,
  output        io_in_11_ready,
  input         io_in_11_valid,
  input  [49:0] io_in_11_bits_vaddr,
  output        io_in_12_ready,
  input         io_in_12_valid,
  input  [49:0] io_in_12_bits_vaddr,
  output        io_in_13_ready,
  input         io_in_13_valid,
  input  [49:0] io_in_13_bits_vaddr,
  output        io_in_14_ready,
  input         io_in_14_valid,
  input  [49:0] io_in_14_bits_vaddr,
  output        io_in_15_ready,
  input         io_in_15_valid,
  input  [49:0] io_in_15_bits_vaddr,
  output        io_out_valid,
  output [49:0] io_out_bits_vaddr
);
  localparam int N = 16;
  localparam int W = 50;

  // 打包：每一路按字段表顺序拼成 W 位（下面的拆包用同一张表，反过来一次）。
  logic [N-1:0][49:0] in_payload;
  assign in_payload[0] = io_in_0_bits_vaddr;
  assign in_payload[1] = io_in_1_bits_vaddr;
  assign in_payload[2] = io_in_2_bits_vaddr;
  assign in_payload[3] = io_in_3_bits_vaddr;
  assign in_payload[4] = io_in_4_bits_vaddr;
  assign in_payload[5] = io_in_5_bits_vaddr;
  assign in_payload[6] = io_in_6_bits_vaddr;
  assign in_payload[7] = io_in_7_bits_vaddr;
  assign in_payload[8] = io_in_8_bits_vaddr;
  assign in_payload[9] = io_in_9_bits_vaddr;
  assign in_payload[10] = io_in_10_bits_vaddr;
  assign in_payload[11] = io_in_11_bits_vaddr;
  assign in_payload[12] = io_in_12_bits_vaddr;
  assign in_payload[13] = io_in_13_bits_vaddr;
  assign in_payload[14] = io_in_14_bits_vaddr;
  assign in_payload[15] = io_in_15_bits_vaddr;

  logic [49:0] out_payload;
  xs_RRArbiterInit_core #(.N(N), .W(W)) u_core (
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
    .out_ready (1'b1),             // 本变体 golden 无 io_out_ready 端口（恒 1）
    .out_valid (io_out_valid),
    .out_bits  (out_payload),
    .chosen    ()                  // 本变体 golden 无 io_chosen 输出端口
  );

  // 拆包：与上面的打包共用同一张字段表。
  assign io_out_bits_vaddr = out_payload;
endmodule
