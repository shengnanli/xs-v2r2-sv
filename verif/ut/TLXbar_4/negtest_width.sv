// negtest_width —— xs_TLXbar_4_core 宽度等式自检的**必失败负测**。
//
// 目的：证明核里那条"D 通道多位字段合计位宽 == golden D-mux 常量合计 76 位"的
// 等式确实有牙齿。本 tb 故意把 SOURCE_W 传回 G0 旧值 2（逻辑一行不改、随机激励
// 也未必打得到高位，正是本轮连出三次的事故形态），核必须在 time 0 $fatal。
//
// 判据（见 Makefile 的 negtest 目标）：日志里必须出现 "Fatal:" 与
// "xs_TLXbar_4_core:" 的宽度报错；跑到 "NEGTEST ESCAPED" 判负测失败。
`timescale 1ns/1ps
module tb;
  bit clock = 0;
  bit reset = 1;
  always #5 clock = ~clock;

  // G0 旧参数下的 source 位宽 = 2；其余端口宽度不变。
  wire         auto_in_a_ready;
  wire         auto_in_d_valid;
  wire [3:0]   auto_in_d_bits_opcode;
  wire [1:0]   auto_in_d_bits_param;
  wire [1:0]   auto_in_d_bits_size;
  wire [1:0]   auto_in_d_bits_source;
  wire         auto_in_d_bits_sink;
  wire         auto_in_d_bits_denied;
  wire [63:0]  auto_in_d_bits_data;
  wire         auto_in_d_bits_corrupt;
  wire         auto_out_1_a_valid;
  wire [3:0]   auto_out_1_a_bits_opcode;
  wire [2:0]   auto_out_1_a_bits_param;
  wire [1:0]   auto_out_1_a_bits_size;
  wire [1:0]   auto_out_1_a_bits_source;
  wire [47:0]  auto_out_1_a_bits_address;
  wire         auto_out_1_a_bits_user_memBackType_MM;
  wire         auto_out_1_a_bits_user_memPageType_NC;
  wire [7:0]   auto_out_1_a_bits_mask;
  wire [63:0]  auto_out_1_a_bits_data;
  wire         auto_out_1_a_bits_corrupt;
  wire         auto_out_1_d_ready;
  wire         auto_out_0_a_valid;
  wire [3:0]   auto_out_0_a_bits_opcode;
  wire [2:0]   auto_out_0_a_bits_param;
  wire [1:0]   auto_out_0_a_bits_size;
  wire [1:0]   auto_out_0_a_bits_source;
  wire [29:0]  auto_out_0_a_bits_address;
  wire [7:0]   auto_out_0_a_bits_mask;
  wire [63:0]  auto_out_0_a_bits_data;
  wire         auto_out_0_a_bits_corrupt;
  wire         auto_out_0_d_ready;

  xs_TLXbar_4_core #(.SOURCE_W(2)) u_bad (
    .clock(clock), .reset(reset),
    .auto_in_a_ready(auto_in_a_ready),
    .auto_in_a_valid(1'b0),
    .auto_in_a_bits_opcode(4'h0),
    .auto_in_a_bits_param(3'h0),
    .auto_in_a_bits_size(2'h0),
    .auto_in_a_bits_source(2'h0),
    .auto_in_a_bits_address(48'h0),
    .auto_in_a_bits_user_memPageType_NC(1'b0),
    .auto_in_a_bits_user_memBackType_MM(1'b0),
    .auto_in_a_bits_mask(8'h0),
    .auto_in_a_bits_data(64'h0),
    .auto_in_a_bits_corrupt(1'b0),
    .auto_in_d_ready(1'b0),
    .auto_in_d_valid(auto_in_d_valid),
    .auto_in_d_bits_opcode(auto_in_d_bits_opcode),
    .auto_in_d_bits_param(auto_in_d_bits_param),
    .auto_in_d_bits_size(auto_in_d_bits_size),
    .auto_in_d_bits_source(auto_in_d_bits_source),
    .auto_in_d_bits_sink(auto_in_d_bits_sink),
    .auto_in_d_bits_denied(auto_in_d_bits_denied),
    .auto_in_d_bits_data(auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(auto_in_d_bits_corrupt),
    .auto_out_1_a_ready(1'b0),
    .auto_out_1_a_valid(auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_param(auto_out_1_a_bits_param),
    .auto_out_1_a_bits_size(auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source(auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address(auto_out_1_a_bits_address),
    .auto_out_1_a_bits_user_memBackType_MM(auto_out_1_a_bits_user_memBackType_MM),
    .auto_out_1_a_bits_user_memPageType_NC(auto_out_1_a_bits_user_memPageType_NC),
    .auto_out_1_a_bits_mask(auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data(auto_out_1_a_bits_data),
    .auto_out_1_a_bits_corrupt(auto_out_1_a_bits_corrupt),
    .auto_out_1_d_ready(auto_out_1_d_ready),
    .auto_out_1_d_valid(1'b0),
    .auto_out_1_d_bits_opcode(4'h0),
    .auto_out_1_d_bits_param(2'h0),
    .auto_out_1_d_bits_size(2'h0),
    .auto_out_1_d_bits_source(2'h0),
    .auto_out_1_d_bits_sink(1'b0),
    .auto_out_1_d_bits_denied(1'b0),
    .auto_out_1_d_bits_data(64'h0),
    .auto_out_1_d_bits_corrupt(1'b0),
    .auto_out_0_a_ready(1'b0),
    .auto_out_0_a_valid(auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param(auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size(auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source(auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address(auto_out_0_a_bits_address),
    .auto_out_0_a_bits_mask(auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data(auto_out_0_a_bits_data),
    .auto_out_0_a_bits_corrupt(auto_out_0_a_bits_corrupt),
    .auto_out_0_d_ready(auto_out_0_d_ready),
    .auto_out_0_d_valid(1'b0),
    .auto_out_0_d_bits_opcode(4'h0),
    .auto_out_0_d_bits_param(2'h0),
    .auto_out_0_d_bits_size(2'h0),
    .auto_out_0_d_bits_source(2'h0),
    .auto_out_0_d_bits_sink(1'b0),
    .auto_out_0_d_bits_denied(1'b0),
    .auto_out_0_d_bits_data(64'h0),
    .auto_out_0_d_bits_corrupt(1'b0)
  );

  initial begin
    #100;
    $display("NEGTEST ESCAPED: SOURCE_W 写回 G0 旧值 2 却没有触发宽度自检 $fatal");
    $fatal(0);
  end
endmodule
