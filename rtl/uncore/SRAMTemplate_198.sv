// SRAMTemplate_198 —— L2 SubDirectory meta valid-bit SRAM 叶(可读重写)。
// 配置: SETS=1024, WAYS=10, WIDTH=1(每路 1bit valid)。复用 xs_Simple1PSRAM_core。
module SRAMTemplate_198 (
  input        clock,
  output       io_r_req_ready,
  input        io_r_req_valid,
  input  [9:0] io_r_req_bits_setIdx,
  output       io_r_resp_data_0_0_valid,
  output       io_r_resp_data_1_0_valid,
  output       io_r_resp_data_2_0_valid,
  output       io_r_resp_data_3_0_valid,
  output       io_r_resp_data_4_0_valid,
  output       io_r_resp_data_5_0_valid,
  output       io_r_resp_data_6_0_valid,
  output       io_r_resp_data_7_0_valid,
  output       io_r_resp_data_8_0_valid,
  output       io_r_resp_data_9_0_valid,
  output       io_w_req_ready,
  input        io_w_req_valid,
  input  [9:0] io_w_req_bits_setIdx,
  input        io_w_req_bits_data_0_0_valid,
  input        io_w_req_bits_data_1_0_valid,
  input        io_w_req_bits_data_2_0_valid,
  input        io_w_req_bits_data_3_0_valid,
  input        io_w_req_bits_data_4_0_valid,
  input        io_w_req_bits_data_5_0_valid,
  input        io_w_req_bits_data_6_0_valid,
  input        io_w_req_bits_data_7_0_valid,
  input        io_w_req_bits_data_8_0_valid,
  input        io_w_req_bits_data_9_0_valid,
  input  [9:0] io_w_req_bits_waymask
);
  // 逐路 valid 打包(lane 0 在低位)
  wire [9:0] wdata_packed = {io_w_req_bits_data_9_0_valid, io_w_req_bits_data_8_0_valid,
                             io_w_req_bits_data_7_0_valid, io_w_req_bits_data_6_0_valid,
                             io_w_req_bits_data_5_0_valid, io_w_req_bits_data_4_0_valid,
                             io_w_req_bits_data_3_0_valid, io_w_req_bits_data_2_0_valid,
                             io_w_req_bits_data_1_0_valid, io_w_req_bits_data_0_0_valid};
  wire [9:0] rdata_packed;

  xs_Simple1PSRAM_core #(.SETS(1024), .WAYS(10), .WIDTH(1)) u_core (
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

  assign io_r_resp_data_0_0_valid = rdata_packed[0];
  assign io_r_resp_data_1_0_valid = rdata_packed[1];
  assign io_r_resp_data_2_0_valid = rdata_packed[2];
  assign io_r_resp_data_3_0_valid = rdata_packed[3];
  assign io_r_resp_data_4_0_valid = rdata_packed[4];
  assign io_r_resp_data_5_0_valid = rdata_packed[5];
  assign io_r_resp_data_6_0_valid = rdata_packed[6];
  assign io_r_resp_data_7_0_valid = rdata_packed[7];
  assign io_r_resp_data_8_0_valid = rdata_packed[8];
  assign io_r_resp_data_9_0_valid = rdata_packed[9];
endmodule
