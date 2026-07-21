// SRAMTemplate_197 —— L2 SubDirectory meta SRAM 叶(可读重写)。
// 配置: SETS=1024, WAYS=10, WIDTH=30(端口与 golden SRAMTemplate_197 逐一对应)。
// 薄 wrapper: 逐路 data 打包/拆分, 内部单口写优先 SRAM 逻辑在 xs_Simple1PSRAM_core。
module SRAMTemplate_197 (
  input         clock,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [9:0]  io_r_req_bits_setIdx,
  output [29:0] io_r_resp_data_0,
  output [29:0] io_r_resp_data_1,
  output [29:0] io_r_resp_data_2,
  output [29:0] io_r_resp_data_3,
  output [29:0] io_r_resp_data_4,
  output [29:0] io_r_resp_data_5,
  output [29:0] io_r_resp_data_6,
  output [29:0] io_r_resp_data_7,
  output [29:0] io_r_resp_data_8,
  output [29:0] io_r_resp_data_9,
  output        io_w_req_ready,
  input         io_w_req_valid,
  input  [9:0]  io_w_req_bits_setIdx,
  input  [29:0] io_w_req_bits_data_0,
  input  [29:0] io_w_req_bits_data_1,
  input  [29:0] io_w_req_bits_data_2,
  input  [29:0] io_w_req_bits_data_3,
  input  [29:0] io_w_req_bits_data_4,
  input  [29:0] io_w_req_bits_data_5,
  input  [29:0] io_w_req_bits_data_6,
  input  [29:0] io_w_req_bits_data_7,
  input  [29:0] io_w_req_bits_data_8,
  input  [29:0] io_w_req_bits_data_9,
  input  [9:0]  io_w_req_bits_waymask
);
  // 逐路写数据打包(lane 0 在低位)
  wire [299:0] wdata_packed = {io_w_req_bits_data_9, io_w_req_bits_data_8,
                               io_w_req_bits_data_7, io_w_req_bits_data_6,
                               io_w_req_bits_data_5, io_w_req_bits_data_4,
                               io_w_req_bits_data_3, io_w_req_bits_data_2,
                               io_w_req_bits_data_1, io_w_req_bits_data_0};
  wire [299:0] rdata_packed;

  xs_Simple1PSRAM_core #(.SETS(1024), .WAYS(10), .WIDTH(30)) u_core (
    .clock                 (clock),
    .io_r_req_ready        (io_r_req_ready),
    .io_r_req_valid        (io_r_req_valid),
    .io_r_req_bits_setIdx  (io_r_req_bits_setIdx),
    .io_r_resp_data        (rdata_packed),
    .io_w_req_ready        (io_w_req_ready),
    .io_w_req_valid        (io_w_req_valid),
    .io_w_req_bits_setIdx  (io_w_req_bits_setIdx),
    .io_w_req_bits_data    (wdata_packed),
    .io_w_req_bits_waymask (io_w_req_bits_waymask)
  );

  // 逐路读数据拆分
  assign io_r_resp_data_0 = rdata_packed[29:0];
  assign io_r_resp_data_1 = rdata_packed[59:30];
  assign io_r_resp_data_2 = rdata_packed[89:60];
  assign io_r_resp_data_3 = rdata_packed[119:90];
  assign io_r_resp_data_4 = rdata_packed[149:120];
  assign io_r_resp_data_5 = rdata_packed[179:150];
  assign io_r_resp_data_6 = rdata_packed[209:180];
  assign io_r_resp_data_7 = rdata_packed[239:210];
  assign io_r_resp_data_8 = rdata_packed[269:240];
  assign io_r_resp_data_9 = rdata_packed[299:270];
endmodule
