// =============================================================================
// RegCacheDataModule_1 —— MemRegCache 的数据存储体（12 项 / 23 读口 / 3 写口）
//
// 薄 wrapper：只设参数并展平端口，核体是 RegCacheDataModule.sv 里的
// xs_RegCacheDataModule_core（机制、越界读第 0 项等怪癖见那里的文件头）。
// =============================================================================
// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden RegCacheDataModule_1.sv 逐位一致（12 项 / 23 读口 / 3 写口）
// ---------------------------------------------------------------------------
module RegCacheDataModule_1 (
  input         clock,
  input         reset,
  input         io_readPorts_0_ren,
  input  [3:0]  io_readPorts_0_addr,
  output [63:0] io_readPorts_0_data,
  input         io_readPorts_1_ren,
  input  [3:0]  io_readPorts_1_addr,
  output [63:0] io_readPorts_1_data,
  input         io_readPorts_2_ren,
  input  [3:0]  io_readPorts_2_addr,
  output [63:0] io_readPorts_2_data,
  input         io_readPorts_3_ren,
  input  [3:0]  io_readPorts_3_addr,
  output [63:0] io_readPorts_3_data,
  input         io_readPorts_4_ren,
  input  [3:0]  io_readPorts_4_addr,
  output [63:0] io_readPorts_4_data,
  input         io_readPorts_5_ren,
  input  [3:0]  io_readPorts_5_addr,
  output [63:0] io_readPorts_5_data,
  input         io_readPorts_6_ren,
  input  [3:0]  io_readPorts_6_addr,
  output [63:0] io_readPorts_6_data,
  input         io_readPorts_7_ren,
  input  [3:0]  io_readPorts_7_addr,
  output [63:0] io_readPorts_7_data,
  input         io_readPorts_8_ren,
  input  [3:0]  io_readPorts_8_addr,
  output [63:0] io_readPorts_8_data,
  input         io_readPorts_9_ren,
  input  [3:0]  io_readPorts_9_addr,
  output [63:0] io_readPorts_9_data,
  input         io_readPorts_10_ren,
  input  [3:0]  io_readPorts_10_addr,
  output [63:0] io_readPorts_10_data,
  input         io_readPorts_11_ren,
  input  [3:0]  io_readPorts_11_addr,
  output [63:0] io_readPorts_11_data,
  input         io_readPorts_12_ren,
  input  [3:0]  io_readPorts_12_addr,
  output [63:0] io_readPorts_12_data,
  input         io_readPorts_13_ren,
  input  [3:0]  io_readPorts_13_addr,
  output [63:0] io_readPorts_13_data,
  input         io_readPorts_14_ren,
  input  [3:0]  io_readPorts_14_addr,
  output [63:0] io_readPorts_14_data,
  input         io_readPorts_15_ren,
  input  [3:0]  io_readPorts_15_addr,
  output [63:0] io_readPorts_15_data,
  input         io_readPorts_16_ren,
  input  [3:0]  io_readPorts_16_addr,
  output [63:0] io_readPorts_16_data,
  input         io_readPorts_17_ren,
  input  [3:0]  io_readPorts_17_addr,
  output [63:0] io_readPorts_17_data,
  input         io_readPorts_18_ren,
  input  [3:0]  io_readPorts_18_addr,
  output [63:0] io_readPorts_18_data,
  input         io_readPorts_19_ren,
  input  [3:0]  io_readPorts_19_addr,
  output [63:0] io_readPorts_19_data,
  input         io_readPorts_20_ren,
  input  [3:0]  io_readPorts_20_addr,
  output [63:0] io_readPorts_20_data,
  input         io_readPorts_21_ren,
  input  [3:0]  io_readPorts_21_addr,
  output [63:0] io_readPorts_21_data,
  input         io_readPorts_22_ren,
  input  [3:0]  io_readPorts_22_addr,
  output [63:0] io_readPorts_22_data,
  input         io_writePorts_0_wen,
  input  [3:0]  io_writePorts_0_addr,
  input  [63:0] io_writePorts_0_data,
  input         io_writePorts_1_wen,
  input  [3:0]  io_writePorts_1_addr,
  input  [63:0] io_writePorts_1_data,
  input         io_writePorts_2_wen,
  input  [3:0]  io_writePorts_2_addr,
  input  [63:0] io_writePorts_2_data,
  output        io_validInfo_0,
  output        io_validInfo_1,
  output        io_validInfo_2,
  output        io_validInfo_3,
  output        io_validInfo_4,
  output        io_validInfo_5,
  output        io_validInfo_6,
  output        io_validInfo_7,
  output        io_validInfo_8,
  output        io_validInfo_9,
  output        io_validInfo_10,
  output        io_validInfo_11
);

  logic [22:0] ren;
  logic [3:0]  raddr [23];
  logic [63:0] rdata [23];
  logic [2:0]  wen;
  logic [3:0]  waddr [3];
  logic [63:0] wdata [3];
  logic [11:0] valid_info;

  assign ren[0]   = io_readPorts_0_ren;
  assign raddr[0] = io_readPorts_0_addr;
  assign ren[1]   = io_readPorts_1_ren;
  assign raddr[1] = io_readPorts_1_addr;
  assign ren[2]   = io_readPorts_2_ren;
  assign raddr[2] = io_readPorts_2_addr;
  assign ren[3]   = io_readPorts_3_ren;
  assign raddr[3] = io_readPorts_3_addr;
  assign ren[4]   = io_readPorts_4_ren;
  assign raddr[4] = io_readPorts_4_addr;
  assign ren[5]   = io_readPorts_5_ren;
  assign raddr[5] = io_readPorts_5_addr;
  assign ren[6]   = io_readPorts_6_ren;
  assign raddr[6] = io_readPorts_6_addr;
  assign ren[7]   = io_readPorts_7_ren;
  assign raddr[7] = io_readPorts_7_addr;
  assign ren[8]   = io_readPorts_8_ren;
  assign raddr[8] = io_readPorts_8_addr;
  assign ren[9]   = io_readPorts_9_ren;
  assign raddr[9] = io_readPorts_9_addr;
  assign ren[10]   = io_readPorts_10_ren;
  assign raddr[10] = io_readPorts_10_addr;
  assign ren[11]   = io_readPorts_11_ren;
  assign raddr[11] = io_readPorts_11_addr;
  assign ren[12]   = io_readPorts_12_ren;
  assign raddr[12] = io_readPorts_12_addr;
  assign ren[13]   = io_readPorts_13_ren;
  assign raddr[13] = io_readPorts_13_addr;
  assign ren[14]   = io_readPorts_14_ren;
  assign raddr[14] = io_readPorts_14_addr;
  assign ren[15]   = io_readPorts_15_ren;
  assign raddr[15] = io_readPorts_15_addr;
  assign ren[16]   = io_readPorts_16_ren;
  assign raddr[16] = io_readPorts_16_addr;
  assign ren[17]   = io_readPorts_17_ren;
  assign raddr[17] = io_readPorts_17_addr;
  assign ren[18]   = io_readPorts_18_ren;
  assign raddr[18] = io_readPorts_18_addr;
  assign ren[19]   = io_readPorts_19_ren;
  assign raddr[19] = io_readPorts_19_addr;
  assign ren[20]   = io_readPorts_20_ren;
  assign raddr[20] = io_readPorts_20_addr;
  assign ren[21]   = io_readPorts_21_ren;
  assign raddr[21] = io_readPorts_21_addr;
  assign ren[22]   = io_readPorts_22_ren;
  assign raddr[22] = io_readPorts_22_addr;
  assign wen[0]   = io_writePorts_0_wen;
  assign waddr[0] = io_writePorts_0_addr;
  assign wdata[0] = io_writePorts_0_data;
  assign wen[1]   = io_writePorts_1_wen;
  assign waddr[1] = io_writePorts_1_addr;
  assign wdata[1] = io_writePorts_1_data;
  assign wen[2]   = io_writePorts_2_wen;
  assign waddr[2] = io_writePorts_2_addr;
  assign wdata[2] = io_writePorts_2_data;

  xs_RegCacheDataModule_core #(
    .N_ENTRY (12),
    .N_READ  (23),
    .N_WRITE (3)
  ) u_core (
    .clock      (clock),
    .reset      (reset),
    .ren        (ren),
    .raddr      (raddr),
    .rdata      (rdata),
    .wen        (wen),
    .waddr      (waddr),
    .wdata      (wdata),
    .valid_info (valid_info)
  );

  assign io_readPorts_0_data = rdata[0];
  assign io_readPorts_1_data = rdata[1];
  assign io_readPorts_2_data = rdata[2];
  assign io_readPorts_3_data = rdata[3];
  assign io_readPorts_4_data = rdata[4];
  assign io_readPorts_5_data = rdata[5];
  assign io_readPorts_6_data = rdata[6];
  assign io_readPorts_7_data = rdata[7];
  assign io_readPorts_8_data = rdata[8];
  assign io_readPorts_9_data = rdata[9];
  assign io_readPorts_10_data = rdata[10];
  assign io_readPorts_11_data = rdata[11];
  assign io_readPorts_12_data = rdata[12];
  assign io_readPorts_13_data = rdata[13];
  assign io_readPorts_14_data = rdata[14];
  assign io_readPorts_15_data = rdata[15];
  assign io_readPorts_16_data = rdata[16];
  assign io_readPorts_17_data = rdata[17];
  assign io_readPorts_18_data = rdata[18];
  assign io_readPorts_19_data = rdata[19];
  assign io_readPorts_20_data = rdata[20];
  assign io_readPorts_21_data = rdata[21];
  assign io_readPorts_22_data = rdata[22];
  assign io_validInfo_0 = valid_info[0];
  assign io_validInfo_1 = valid_info[1];
  assign io_validInfo_2 = valid_info[2];
  assign io_validInfo_3 = valid_info[3];
  assign io_validInfo_4 = valid_info[4];
  assign io_validInfo_5 = valid_info[5];
  assign io_validInfo_6 = valid_info[6];
  assign io_validInfo_7 = valid_info[7];
  assign io_validInfo_8 = valid_info[8];
  assign io_validInfo_9 = valid_info[9];
  assign io_validInfo_10 = valid_info[10];
  assign io_validInfo_11 = valid_info[11];

endmodule
