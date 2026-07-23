// SRAMTemplate_199 —— L2 SubDirectory SRAM 叶(可读重写, 存储宏作边界)。
// 16 way × 28bit, 深度 2^12; 单口**写优先**(写占口, 读仅在无写时); 外围控制逻辑
// (ready/地址mux/mask/逐路pack)可读且参与证明, 存储阵列 array_21(→array_ext 硬宏)作边界。
module SRAMTemplate_199 (
  input         clock,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [11:0] io_r_req_bits_setIdx,
  output [27:0] io_r_resp_data_0,
  output [27:0] io_r_resp_data_1,
  output [27:0] io_r_resp_data_2,
  output [27:0] io_r_resp_data_3,
  output [27:0] io_r_resp_data_4,
  output [27:0] io_r_resp_data_5,
  output [27:0] io_r_resp_data_6,
  output [27:0] io_r_resp_data_7,
  output [27:0] io_r_resp_data_8,
  output [27:0] io_r_resp_data_9,
  output [27:0] io_r_resp_data_10,
  output [27:0] io_r_resp_data_11,
  output [27:0] io_r_resp_data_12,
  output [27:0] io_r_resp_data_13,
  output [27:0] io_r_resp_data_14,
  output [27:0] io_r_resp_data_15,
  output        io_w_req_ready,
  input         io_w_req_valid,
  input  [11:0] io_w_req_bits_setIdx,
  input  [27:0] io_w_req_bits_data_0,
  input  [27:0] io_w_req_bits_data_1,
  input  [27:0] io_w_req_bits_data_2,
  input  [27:0] io_w_req_bits_data_3,
  input  [27:0] io_w_req_bits_data_4,
  input  [27:0] io_w_req_bits_data_5,
  input  [27:0] io_w_req_bits_data_6,
  input  [27:0] io_w_req_bits_data_7,
  input  [27:0] io_w_req_bits_data_8,
  input  [27:0] io_w_req_bits_data_9,
  input  [27:0] io_w_req_bits_data_10,
  input  [27:0] io_w_req_bits_data_11,
  input  [27:0] io_w_req_bits_data_12,
  input  [27:0] io_w_req_bits_data_13,
  input  [27:0] io_w_req_bits_data_14,
  input  [27:0] io_w_req_bits_data_15,
  input  [15:0] io_w_req_bits_waymask
);
  // 写优先: 写请求占物理口, 读仅在无写时进行(realRen)。
  wire realRen = io_r_req_valid & ~io_w_req_valid;
  wire [447:0] wdata = {io_w_req_bits_data_15, io_w_req_bits_data_14, io_w_req_bits_data_13, io_w_req_bits_data_12, io_w_req_bits_data_11, io_w_req_bits_data_10, io_w_req_bits_data_9, io_w_req_bits_data_8, io_w_req_bits_data_7, io_w_req_bits_data_6, io_w_req_bits_data_5, io_w_req_bits_data_4, io_w_req_bits_data_3, io_w_req_bits_data_2, io_w_req_bits_data_1, io_w_req_bits_data_0};   // lane0 在低位
  wire [447:0] rdata;
  array_21 array (
    .RW0_addr  (io_w_req_valid ? io_w_req_bits_setIdx : io_r_req_bits_setIdx),
    .RW0_en    (realRen | io_w_req_valid),
    .RW0_clk   (clock),
    .RW0_wmode (io_w_req_valid),
    .RW0_wdata (wdata),
    .RW0_rdata (rdata),
    .RW0_wmask (io_w_req_bits_waymask)
  );
  assign io_r_req_ready = ~io_w_req_valid;
  assign io_w_req_ready = 1'b1;
  assign io_r_resp_data_0 = rdata[27:0];
  assign io_r_resp_data_1 = rdata[55:28];
  assign io_r_resp_data_2 = rdata[83:56];
  assign io_r_resp_data_3 = rdata[111:84];
  assign io_r_resp_data_4 = rdata[139:112];
  assign io_r_resp_data_5 = rdata[167:140];
  assign io_r_resp_data_6 = rdata[195:168];
  assign io_r_resp_data_7 = rdata[223:196];
  assign io_r_resp_data_8 = rdata[251:224];
  assign io_r_resp_data_9 = rdata[279:252];
  assign io_r_resp_data_10 = rdata[307:280];
  assign io_r_resp_data_11 = rdata[335:308];
  assign io_r_resp_data_12 = rdata[363:336];
  assign io_r_resp_data_13 = rdata[391:364];
  assign io_r_resp_data_14 = rdata[419:392];
  assign io_r_resp_data_15 = rdata[447:420];
endmodule
