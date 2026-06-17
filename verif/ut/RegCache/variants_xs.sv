// RegCache_xs —— UT 用可读核包装(与 RegCache_wrapper.sv 逻辑一致,改名以并例化比对)。
module RegCache_xs
  import regcache_pkg::*;
(
  input         clock,
  input         reset,
  input         io_readPorts_0_ren,
  input  [4:0]  io_readPorts_0_addr,
  output [63:0] io_readPorts_0_data,
  input         io_readPorts_1_ren,
  input  [4:0]  io_readPorts_1_addr,
  output [63:0] io_readPorts_1_data,
  input         io_readPorts_2_ren,
  input  [4:0]  io_readPorts_2_addr,
  output [63:0] io_readPorts_2_data,
  input         io_readPorts_3_ren,
  input  [4:0]  io_readPorts_3_addr,
  output [63:0] io_readPorts_3_data,
  input         io_readPorts_4_ren,
  input  [4:0]  io_readPorts_4_addr,
  output [63:0] io_readPorts_4_data,
  input         io_readPorts_5_ren,
  input  [4:0]  io_readPorts_5_addr,
  output [63:0] io_readPorts_5_data,
  input         io_readPorts_6_ren,
  input  [4:0]  io_readPorts_6_addr,
  output [63:0] io_readPorts_6_data,
  input         io_readPorts_7_ren,
  input  [4:0]  io_readPorts_7_addr,
  output [63:0] io_readPorts_7_data,
  input         io_readPorts_8_ren,
  input  [4:0]  io_readPorts_8_addr,
  output [63:0] io_readPorts_8_data,
  input         io_readPorts_9_ren,
  input  [4:0]  io_readPorts_9_addr,
  output [63:0] io_readPorts_9_data,
  input         io_readPorts_10_ren,
  input  [4:0]  io_readPorts_10_addr,
  output [63:0] io_readPorts_10_data,
  input         io_readPorts_11_ren,
  input  [4:0]  io_readPorts_11_addr,
  output [63:0] io_readPorts_11_data,
  input         io_readPorts_12_ren,
  input  [4:0]  io_readPorts_12_addr,
  output [63:0] io_readPorts_12_data,
  input         io_readPorts_13_ren,
  input  [4:0]  io_readPorts_13_addr,
  output [63:0] io_readPorts_13_data,
  input         io_readPorts_14_ren,
  input  [4:0]  io_readPorts_14_addr,
  output [63:0] io_readPorts_14_data,
  input         io_readPorts_15_ren,
  input  [4:0]  io_readPorts_15_addr,
  output [63:0] io_readPorts_15_data,
  input         io_readPorts_16_ren,
  input  [4:0]  io_readPorts_16_addr,
  output [63:0] io_readPorts_16_data,
  input         io_readPorts_17_ren,
  input  [4:0]  io_readPorts_17_addr,
  output [63:0] io_readPorts_17_data,
  input         io_readPorts_18_ren,
  input  [4:0]  io_readPorts_18_addr,
  output [63:0] io_readPorts_18_data,
  input         io_readPorts_19_ren,
  input  [4:0]  io_readPorts_19_addr,
  output [63:0] io_readPorts_19_data,
  input         io_readPorts_20_ren,
  input  [4:0]  io_readPorts_20_addr,
  output [63:0] io_readPorts_20_data,
  input         io_readPorts_21_ren,
  input  [4:0]  io_readPorts_21_addr,
  output [63:0] io_readPorts_21_data,
  input         io_readPorts_22_ren,
  input  [4:0]  io_readPorts_22_addr,
  output [63:0] io_readPorts_22_data,
  input         io_writePorts_0_wen,
  input  [63:0] io_writePorts_0_data,
  input         io_writePorts_1_wen,
  input  [63:0] io_writePorts_1_data,
  input         io_writePorts_2_wen,
  input  [63:0] io_writePorts_2_data,
  input         io_writePorts_3_wen,
  input  [63:0] io_writePorts_3_data,
  input         io_writePorts_4_wen,
  input  [63:0] io_writePorts_4_data,
  input         io_writePorts_5_wen,
  input  [63:0] io_writePorts_5_data,
  input         io_writePorts_6_wen,
  input  [63:0] io_writePorts_6_data,
  output [4:0]  io_toWakeupQueueRCIdx_0,
  output [4:0]  io_toWakeupQueueRCIdx_1,
  output [4:0]  io_toWakeupQueueRCIdx_2,
  output [4:0]  io_toWakeupQueueRCIdx_3,
  output [4:0]  io_toWakeupQueueRCIdx_4,
  output [4:0]  io_toWakeupQueueRCIdx_5,
  output [4:0]  io_toWakeupQueueRCIdx_6
);
  logic              [N_READ-1:0]            rd_ren;
  logic [N_READ-1:0] [IDX_W-1:0]             rd_idx;
  logic [N_READ-1:0] [DATA_W-1:0]            rd_data;
  logic              [N_WRITE-1:0]           wr_wen;
  logic [N_WRITE-1:0][DATA_W-1:0]            wr_data;
  logic [N_WRITE-1:0][IDX_W-1:0]             to_wakeup_idx;
  assign rd_ren[0]  = io_readPorts_0_ren;
  assign rd_idx[0]  = io_readPorts_0_addr;
  assign io_readPorts_0_data = rd_data[0];
  assign rd_ren[1]  = io_readPorts_1_ren;
  assign rd_idx[1]  = io_readPorts_1_addr;
  assign io_readPorts_1_data = rd_data[1];
  assign rd_ren[2]  = io_readPorts_2_ren;
  assign rd_idx[2]  = io_readPorts_2_addr;
  assign io_readPorts_2_data = rd_data[2];
  assign rd_ren[3]  = io_readPorts_3_ren;
  assign rd_idx[3]  = io_readPorts_3_addr;
  assign io_readPorts_3_data = rd_data[3];
  assign rd_ren[4]  = io_readPorts_4_ren;
  assign rd_idx[4]  = io_readPorts_4_addr;
  assign io_readPorts_4_data = rd_data[4];
  assign rd_ren[5]  = io_readPorts_5_ren;
  assign rd_idx[5]  = io_readPorts_5_addr;
  assign io_readPorts_5_data = rd_data[5];
  assign rd_ren[6]  = io_readPorts_6_ren;
  assign rd_idx[6]  = io_readPorts_6_addr;
  assign io_readPorts_6_data = rd_data[6];
  assign rd_ren[7]  = io_readPorts_7_ren;
  assign rd_idx[7]  = io_readPorts_7_addr;
  assign io_readPorts_7_data = rd_data[7];
  assign rd_ren[8]  = io_readPorts_8_ren;
  assign rd_idx[8]  = io_readPorts_8_addr;
  assign io_readPorts_8_data = rd_data[8];
  assign rd_ren[9]  = io_readPorts_9_ren;
  assign rd_idx[9]  = io_readPorts_9_addr;
  assign io_readPorts_9_data = rd_data[9];
  assign rd_ren[10]  = io_readPorts_10_ren;
  assign rd_idx[10]  = io_readPorts_10_addr;
  assign io_readPorts_10_data = rd_data[10];
  assign rd_ren[11]  = io_readPorts_11_ren;
  assign rd_idx[11]  = io_readPorts_11_addr;
  assign io_readPorts_11_data = rd_data[11];
  assign rd_ren[12]  = io_readPorts_12_ren;
  assign rd_idx[12]  = io_readPorts_12_addr;
  assign io_readPorts_12_data = rd_data[12];
  assign rd_ren[13]  = io_readPorts_13_ren;
  assign rd_idx[13]  = io_readPorts_13_addr;
  assign io_readPorts_13_data = rd_data[13];
  assign rd_ren[14]  = io_readPorts_14_ren;
  assign rd_idx[14]  = io_readPorts_14_addr;
  assign io_readPorts_14_data = rd_data[14];
  assign rd_ren[15]  = io_readPorts_15_ren;
  assign rd_idx[15]  = io_readPorts_15_addr;
  assign io_readPorts_15_data = rd_data[15];
  assign rd_ren[16]  = io_readPorts_16_ren;
  assign rd_idx[16]  = io_readPorts_16_addr;
  assign io_readPorts_16_data = rd_data[16];
  assign rd_ren[17]  = io_readPorts_17_ren;
  assign rd_idx[17]  = io_readPorts_17_addr;
  assign io_readPorts_17_data = rd_data[17];
  assign rd_ren[18]  = io_readPorts_18_ren;
  assign rd_idx[18]  = io_readPorts_18_addr;
  assign io_readPorts_18_data = rd_data[18];
  assign rd_ren[19]  = io_readPorts_19_ren;
  assign rd_idx[19]  = io_readPorts_19_addr;
  assign io_readPorts_19_data = rd_data[19];
  assign rd_ren[20]  = io_readPorts_20_ren;
  assign rd_idx[20]  = io_readPorts_20_addr;
  assign io_readPorts_20_data = rd_data[20];
  assign rd_ren[21]  = io_readPorts_21_ren;
  assign rd_idx[21]  = io_readPorts_21_addr;
  assign io_readPorts_21_data = rd_data[21];
  assign rd_ren[22]  = io_readPorts_22_ren;
  assign rd_idx[22]  = io_readPorts_22_addr;
  assign io_readPorts_22_data = rd_data[22];
  assign wr_wen[0]  = io_writePorts_0_wen;
  assign wr_data[0] = io_writePorts_0_data;
  assign io_toWakeupQueueRCIdx_0 = to_wakeup_idx[0];
  assign wr_wen[1]  = io_writePorts_1_wen;
  assign wr_data[1] = io_writePorts_1_data;
  assign io_toWakeupQueueRCIdx_1 = to_wakeup_idx[1];
  assign wr_wen[2]  = io_writePorts_2_wen;
  assign wr_data[2] = io_writePorts_2_data;
  assign io_toWakeupQueueRCIdx_2 = to_wakeup_idx[2];
  assign wr_wen[3]  = io_writePorts_3_wen;
  assign wr_data[3] = io_writePorts_3_data;
  assign io_toWakeupQueueRCIdx_3 = to_wakeup_idx[3];
  assign wr_wen[4]  = io_writePorts_4_wen;
  assign wr_data[4] = io_writePorts_4_data;
  assign io_toWakeupQueueRCIdx_4 = to_wakeup_idx[4];
  assign wr_wen[5]  = io_writePorts_5_wen;
  assign wr_data[5] = io_writePorts_5_data;
  assign io_toWakeupQueueRCIdx_5 = to_wakeup_idx[5];
  assign wr_wen[6]  = io_writePorts_6_wen;
  assign wr_data[6] = io_writePorts_6_data;
  assign io_toWakeupQueueRCIdx_6 = to_wakeup_idx[6];
  xs_regcache_core u_core (
    .clock(clock), .reset(reset),
    .rd_ren(rd_ren), .rd_idx(rd_idx), .rd_data(rd_data),
    .wr_wen(wr_wen), .wr_data(wr_data),
    .to_wakeup_idx(to_wakeup_idx)
  );
endmodule
