// 自动生成：scripts/gen_regfile.py —— 勿手改
// golden 同名扁平端口 → 可读核 xs_RegFilePart_core 的机械适配层
module IntRegFilePart2(
  input         clock,
  input         reset,
  input  [7:0]  io_readPorts_0_addr,
  output [15:0] io_readPorts_0_data,
  input  [7:0]  io_readPorts_1_addr,
  output [15:0] io_readPorts_1_data,
  input  [7:0]  io_readPorts_2_addr,
  output [15:0] io_readPorts_2_data,
  input  [7:0]  io_readPorts_3_addr,
  output [15:0] io_readPorts_3_data,
  input  [7:0]  io_readPorts_4_addr,
  output [15:0] io_readPorts_4_data,
  input  [7:0]  io_readPorts_5_addr,
  output [15:0] io_readPorts_5_data,
  input  [7:0]  io_readPorts_6_addr,
  output [15:0] io_readPorts_6_data,
  input  [7:0]  io_readPorts_7_addr,
  output [15:0] io_readPorts_7_data,
  input  [7:0]  io_readPorts_8_addr,
  output [15:0] io_readPorts_8_data,
  input  [7:0]  io_readPorts_9_addr,
  output [15:0] io_readPorts_9_data,
  input  [7:0]  io_readPorts_10_addr,
  output [15:0] io_readPorts_10_data,
  input         io_writePorts_0_wen,
  input  [7:0]  io_writePorts_0_addr,
  input  [15:0] io_writePorts_0_data,
  input         io_writePorts_1_wen,
  input  [7:0]  io_writePorts_1_addr,
  input  [15:0] io_writePorts_1_data,
  input         io_writePorts_2_wen,
  input  [7:0]  io_writePorts_2_addr,
  input  [15:0] io_writePorts_2_data,
  input         io_writePorts_3_wen,
  input  [7:0]  io_writePorts_3_addr,
  input  [15:0] io_writePorts_3_data,
  input         io_writePorts_4_wen,
  input  [7:0]  io_writePorts_4_addr,
  input  [15:0] io_writePorts_4_data,
  input         io_writePorts_5_wen,
  input  [7:0]  io_writePorts_5_addr,
  input  [15:0] io_writePorts_5_data,
  input         io_writePorts_6_wen,
  input  [7:0]  io_writePorts_6_addr,
  input  [15:0] io_writePorts_6_data,
  input         io_writePorts_7_wen,
  input  [7:0]  io_writePorts_7_addr,
  input  [15:0] io_writePorts_7_data,
  input  [7:0]  io_debug_rports_0_addr,
  output [15:0] io_debug_rports_0_data,
  input  [7:0]  io_debug_rports_1_addr,
  output [15:0] io_debug_rports_1_data,
  input  [7:0]  io_debug_rports_2_addr,
  output [15:0] io_debug_rports_2_data,
  input  [7:0]  io_debug_rports_3_addr,
  output [15:0] io_debug_rports_3_data,
  input  [7:0]  io_debug_rports_4_addr,
  output [15:0] io_debug_rports_4_data,
  input  [7:0]  io_debug_rports_5_addr,
  output [15:0] io_debug_rports_5_data,
  input  [7:0]  io_debug_rports_6_addr,
  output [15:0] io_debug_rports_6_data,
  input  [7:0]  io_debug_rports_7_addr,
  output [15:0] io_debug_rports_7_data,
  input  [7:0]  io_debug_rports_8_addr,
  output [15:0] io_debug_rports_8_data,
  input  [7:0]  io_debug_rports_9_addr,
  output [15:0] io_debug_rports_9_data,
  input  [7:0]  io_debug_rports_10_addr,
  output [15:0] io_debug_rports_10_data,
  input  [7:0]  io_debug_rports_11_addr,
  output [15:0] io_debug_rports_11_data,
  input  [7:0]  io_debug_rports_12_addr,
  output [15:0] io_debug_rports_12_data,
  input  [7:0]  io_debug_rports_13_addr,
  output [15:0] io_debug_rports_13_data,
  input  [7:0]  io_debug_rports_14_addr,
  output [15:0] io_debug_rports_14_data,
  input  [7:0]  io_debug_rports_15_addr,
  output [15:0] io_debug_rports_15_data,
  input  [7:0]  io_debug_rports_16_addr,
  output [15:0] io_debug_rports_16_data,
  input  [7:0]  io_debug_rports_17_addr,
  output [15:0] io_debug_rports_17_data,
  input  [7:0]  io_debug_rports_18_addr,
  output [15:0] io_debug_rports_18_data,
  input  [7:0]  io_debug_rports_19_addr,
  output [15:0] io_debug_rports_19_data,
  input  [7:0]  io_debug_rports_20_addr,
  output [15:0] io_debug_rports_20_data,
  input  [7:0]  io_debug_rports_21_addr,
  output [15:0] io_debug_rports_21_data,
  input  [7:0]  io_debug_rports_22_addr,
  output [15:0] io_debug_rports_22_data,
  input  [7:0]  io_debug_rports_23_addr,
  output [15:0] io_debug_rports_23_data,
  input  [7:0]  io_debug_rports_24_addr,
  output [15:0] io_debug_rports_24_data,
  input  [7:0]  io_debug_rports_25_addr,
  output [15:0] io_debug_rports_25_data,
  input  [7:0]  io_debug_rports_26_addr,
  output [15:0] io_debug_rports_26_data,
  input  [7:0]  io_debug_rports_27_addr,
  output [15:0] io_debug_rports_27_data,
  input  [7:0]  io_debug_rports_28_addr,
  output [15:0] io_debug_rports_28_data,
  input  [7:0]  io_debug_rports_29_addr,
  output [15:0] io_debug_rports_29_data,
  input  [7:0]  io_debug_rports_30_addr,
  output [15:0] io_debug_rports_30_data,
  input  [7:0]  io_debug_rports_31_addr,
  output [15:0] io_debug_rports_31_data
);
  wire [10:0][7:0] rd_addr = {io_readPorts_10_addr, io_readPorts_9_addr, io_readPorts_8_addr, io_readPorts_7_addr, io_readPorts_6_addr, io_readPorts_5_addr, io_readPorts_4_addr, io_readPorts_3_addr, io_readPorts_2_addr, io_readPorts_1_addr, io_readPorts_0_addr};
  wire [7:0] wr_wen = {io_writePorts_7_wen, io_writePorts_6_wen, io_writePorts_5_wen, io_writePorts_4_wen, io_writePorts_3_wen, io_writePorts_2_wen, io_writePorts_1_wen, io_writePorts_0_wen};
  wire [7:0][7:0] wr_addr = {io_writePorts_7_addr, io_writePorts_6_addr, io_writePorts_5_addr, io_writePorts_4_addr, io_writePorts_3_addr, io_writePorts_2_addr, io_writePorts_1_addr, io_writePorts_0_addr};
  wire [7:0][15:0] wr_data = {io_writePorts_7_data, io_writePorts_6_data, io_writePorts_5_data, io_writePorts_4_data, io_writePorts_3_data, io_writePorts_2_data, io_writePorts_1_data, io_writePorts_0_data};
  wire [31:0][7:0] dbg_addr = {io_debug_rports_31_addr, io_debug_rports_30_addr, io_debug_rports_29_addr, io_debug_rports_28_addr, io_debug_rports_27_addr, io_debug_rports_26_addr, io_debug_rports_25_addr, io_debug_rports_24_addr, io_debug_rports_23_addr, io_debug_rports_22_addr, io_debug_rports_21_addr, io_debug_rports_20_addr, io_debug_rports_19_addr, io_debug_rports_18_addr, io_debug_rports_17_addr, io_debug_rports_16_addr, io_debug_rports_15_addr, io_debug_rports_14_addr, io_debug_rports_13_addr, io_debug_rports_12_addr, io_debug_rports_11_addr, io_debug_rports_10_addr, io_debug_rports_9_addr, io_debug_rports_8_addr, io_debug_rports_7_addr, io_debug_rports_6_addr, io_debug_rports_5_addr, io_debug_rports_4_addr, io_debug_rports_3_addr, io_debug_rports_2_addr, io_debug_rports_1_addr, io_debug_rports_0_addr};
  wire [10:0][15:0] rd_data;
  wire [31:0][15:0] dbg_data;

  xs_RegFilePart_core #(
    .NUM_PREGS(224), .NUM_READ(11), .NUM_WRITE(8),
    .NUM_DEBUG(32), .DATA_WIDTH(16), .ADDR_WIDTH(8),
    .HAS_ZERO(1)
  ) u_core (
    .clock(clock), .reset(reset),
    .read_addr(rd_addr), .read_data(rd_data),
    .write_wen(wr_wen), .write_addr(wr_addr), .write_data(wr_data),
    .debug_addr(dbg_addr), .debug_data(dbg_data)
  );

  assign io_readPorts_0_data = rd_data[0];
  assign io_readPorts_1_data = rd_data[1];
  assign io_readPorts_2_data = rd_data[2];
  assign io_readPorts_3_data = rd_data[3];
  assign io_readPorts_4_data = rd_data[4];
  assign io_readPorts_5_data = rd_data[5];
  assign io_readPorts_6_data = rd_data[6];
  assign io_readPorts_7_data = rd_data[7];
  assign io_readPorts_8_data = rd_data[8];
  assign io_readPorts_9_data = rd_data[9];
  assign io_readPorts_10_data = rd_data[10];
  assign io_debug_rports_0_data = dbg_data[0];
  assign io_debug_rports_1_data = dbg_data[1];
  assign io_debug_rports_2_data = dbg_data[2];
  assign io_debug_rports_3_data = dbg_data[3];
  assign io_debug_rports_4_data = dbg_data[4];
  assign io_debug_rports_5_data = dbg_data[5];
  assign io_debug_rports_6_data = dbg_data[6];
  assign io_debug_rports_7_data = dbg_data[7];
  assign io_debug_rports_8_data = dbg_data[8];
  assign io_debug_rports_9_data = dbg_data[9];
  assign io_debug_rports_10_data = dbg_data[10];
  assign io_debug_rports_11_data = dbg_data[11];
  assign io_debug_rports_12_data = dbg_data[12];
  assign io_debug_rports_13_data = dbg_data[13];
  assign io_debug_rports_14_data = dbg_data[14];
  assign io_debug_rports_15_data = dbg_data[15];
  assign io_debug_rports_16_data = dbg_data[16];
  assign io_debug_rports_17_data = dbg_data[17];
  assign io_debug_rports_18_data = dbg_data[18];
  assign io_debug_rports_19_data = dbg_data[19];
  assign io_debug_rports_20_data = dbg_data[20];
  assign io_debug_rports_21_data = dbg_data[21];
  assign io_debug_rports_22_data = dbg_data[22];
  assign io_debug_rports_23_data = dbg_data[23];
  assign io_debug_rports_24_data = dbg_data[24];
  assign io_debug_rports_25_data = dbg_data[25];
  assign io_debug_rports_26_data = dbg_data[26];
  assign io_debug_rports_27_data = dbg_data[27];
  assign io_debug_rports_28_data = dbg_data[28];
  assign io_debug_rports_29_data = dbg_data[29];
  assign io_debug_rports_30_data = dbg_data[30];
  assign io_debug_rports_31_data = dbg_data[31];
endmodule
