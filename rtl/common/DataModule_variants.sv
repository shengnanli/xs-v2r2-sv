// 自动生成：scripts/gen_dm_wrappers.py —— 勿手改
module DataModule_BackendPC_16entry(
  input  clock,
  input  [3:0] io_raddr_0,
  input  [3:0] io_raddr_1,
  input  [3:0] io_raddr_2,
  input  [3:0] io_raddr_3,
  input  [3:0] io_raddr_4,
  input  [3:0] io_raddr_5,
  input  [3:0] io_raddr_6,
  input  [3:0] io_raddr_7,
  input  [3:0] io_raddr_8,
  input  [3:0] io_raddr_9,
  input  [3:0] io_raddr_10,
  input  [3:0] io_raddr_11,
  input  [3:0] io_raddr_12,
  input  [3:0] io_raddr_13,
  input  [3:0] io_raddr_14,
  output [49:0] io_rdata_0_startAddr,
  output [49:0] io_rdata_1_startAddr,
  output [49:0] io_rdata_2_startAddr,
  output [49:0] io_rdata_3_startAddr,
  output [49:0] io_rdata_4_startAddr,
  output [49:0] io_rdata_5_startAddr,
  output [49:0] io_rdata_6_startAddr,
  output [49:0] io_rdata_7_startAddr,
  output [49:0] io_rdata_8_startAddr,
  output [49:0] io_rdata_9_startAddr,
  output [49:0] io_rdata_10_startAddr,
  output [49:0] io_rdata_11_startAddr,
  output [49:0] io_rdata_12_startAddr,
  output [49:0] io_rdata_13_startAddr,
  output [49:0] io_rdata_14_startAddr,
  input  io_wen_0,
  input  [3:0] io_waddr_0,
  input  [49:0] io_wdata_0_startAddr
);
  wire [15-1:0][50-1:0] rdata_bus;
  assign io_rdata_0_startAddr = rdata_bus[0];
  assign io_rdata_1_startAddr = rdata_bus[1];
  assign io_rdata_2_startAddr = rdata_bus[2];
  assign io_rdata_3_startAddr = rdata_bus[3];
  assign io_rdata_4_startAddr = rdata_bus[4];
  assign io_rdata_5_startAddr = rdata_bus[5];
  assign io_rdata_6_startAddr = rdata_bus[6];
  assign io_rdata_7_startAddr = rdata_bus[7];
  assign io_rdata_8_startAddr = rdata_bus[8];
  assign io_rdata_9_startAddr = rdata_bus[9];
  assign io_rdata_10_startAddr = rdata_bus[10];
  assign io_rdata_11_startAddr = rdata_bus[11];
  assign io_rdata_12_startAddr = rdata_bus[12];
  assign io_rdata_13_startAddr = rdata_bus[13];
  assign io_rdata_14_startAddr = rdata_bus[14];
  xs_DataModule #(
    .NUM_ENTRIES(16),
    .NUM_READ(15),
    .NUM_WRITE(1),
    .DATA_WIDTH(50),
    .BYPASS_EN(15'b111111111111111)
  ) u_core (
    .clock(clock),
    .io_raddr({io_raddr_14, io_raddr_13, io_raddr_12, io_raddr_11, io_raddr_10, io_raddr_9, io_raddr_8, io_raddr_7, io_raddr_6, io_raddr_5, io_raddr_4, io_raddr_3, io_raddr_2, io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({io_wdata_0_startAddr})
  );
endmodule

module DataModule_FtqPC_16entry(
  input  clock,
  input  [3:0] io_raddr_0,
  input  [3:0] io_raddr_1,
  input  [3:0] io_raddr_2,
  input  [3:0] io_raddr_3,
  input  [3:0] io_raddr_4,
  input  [3:0] io_raddr_5,
  input  [3:0] io_raddr_6,
  output [49:0] io_rdata_0_startAddr,
  output [49:0] io_rdata_0_nextLineAddr,
  output io_rdata_0_fallThruError,
  output [49:0] io_rdata_1_startAddr,
  output [49:0] io_rdata_1_nextLineAddr,
  output io_rdata_1_fallThruError,
  output [49:0] io_rdata_2_startAddr,
  output [49:0] io_rdata_3_startAddr,
  output [49:0] io_rdata_3_nextLineAddr,
  output [49:0] io_rdata_4_startAddr,
  output [49:0] io_rdata_4_nextLineAddr,
  output [49:0] io_rdata_5_startAddr,
  output [49:0] io_rdata_6_startAddr,
  input  io_wen_0,
  input  [3:0] io_waddr_0,
  input  [49:0] io_wdata_0_startAddr,
  input  [49:0] io_wdata_0_nextLineAddr,
  input  io_wdata_0_fallThruError
);
  wire [7-1:0][101-1:0] rdata_bus;
  assign io_rdata_0_startAddr = rdata_bus[0][49:0];
  assign io_rdata_0_nextLineAddr = rdata_bus[0][99:50];
  assign io_rdata_0_fallThruError = rdata_bus[0][100:100];
  assign io_rdata_1_startAddr = rdata_bus[1][49:0];
  assign io_rdata_1_nextLineAddr = rdata_bus[1][99:50];
  assign io_rdata_1_fallThruError = rdata_bus[1][100:100];
  assign io_rdata_2_startAddr = rdata_bus[2][49:0];
  assign io_rdata_3_startAddr = rdata_bus[3][49:0];
  assign io_rdata_3_nextLineAddr = rdata_bus[3][99:50];
  assign io_rdata_4_startAddr = rdata_bus[4][49:0];
  assign io_rdata_4_nextLineAddr = rdata_bus[4][99:50];
  assign io_rdata_5_startAddr = rdata_bus[5][49:0];
  assign io_rdata_6_startAddr = rdata_bus[6][49:0];
  xs_DataModule #(
    .NUM_ENTRIES(16),
    .NUM_READ(7),
    .NUM_WRITE(1),
    .DATA_WIDTH(101),
    .BYPASS_EN(7'b1111111)
  ) u_core (
    .clock(clock),
    .io_raddr({io_raddr_6, io_raddr_5, io_raddr_4, io_raddr_3, io_raddr_2, io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({{io_wdata_0_fallThruError, io_wdata_0_nextLineAddr, io_wdata_0_startAddr}})
  );
endmodule

module DataModule__64entry(
  input  clock,
  input  [5:0] io_raddr_0,
  input  [5:0] io_raddr_1,
  output io_rdata_0,
  output io_rdata_1,
  input  io_wen_0,
  input  io_wen_1,
  input  [5:0] io_waddr_0,
  input  [5:0] io_waddr_1,
  input  io_wdata_0,
  input  io_wdata_1
);
  wire [2-1:0][1-1:0] rdata_bus;
  assign io_rdata_0 = rdata_bus[0];
  assign io_rdata_1 = rdata_bus[1];
  xs_DataModule #(
    .NUM_ENTRIES(64),
    .NUM_READ(2),
    .NUM_WRITE(2),
    .DATA_WIDTH(1),
    .BYPASS_EN(2'b11)
  ) u_core (
    .clock(clock),
    .io_raddr({io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_1, io_wen_0}),
    .io_waddr({io_waddr_1, io_waddr_0}),
    .io_wdata({io_wdata_1, io_wdata_0})
  );
endmodule

module DataModule__64entry_16(
  input  clock,
  input  [5:0] io_raddr_0,
  input  [5:0] io_raddr_1,
  output [4:0] io_rdata_0_ssid,
  output io_rdata_0_strict,
  output [4:0] io_rdata_1_ssid,
  input  io_wen_0,
  input  io_wen_1,
  input  [5:0] io_waddr_0,
  input  [5:0] io_waddr_1,
  input  [4:0] io_wdata_0_ssid,
  input  io_wdata_0_strict,
  input  [4:0] io_wdata_1_ssid
);
  wire [2-1:0][6-1:0] rdata_bus;
  assign io_rdata_0_ssid = rdata_bus[0][4:0];
  assign io_rdata_0_strict = rdata_bus[0][5:5];
  assign io_rdata_1_ssid = rdata_bus[1][4:0];
  xs_DataModule #(
    .NUM_ENTRIES(64),
    .NUM_READ(2),
    .NUM_WRITE(2),
    .DATA_WIDTH(6),
    .BYPASS_EN(2'b11)
  ) u_core (
    .clock(clock),
    .io_raddr({io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_1, io_wen_0}),
    .io_waddr({io_waddr_1, io_waddr_0}),
    .io_wdata({{1'h0, io_wdata_1_ssid}, {io_wdata_0_strict, io_wdata_0_ssid}})
  );
endmodule

module DataModule__16entry(
  input  clock,
  input  [3:0] io_raddr_0,
  input  [3:0] io_raddr_1,
  input  [3:0] io_raddr_2,
  output io_rdata_0_histPtr_flag,
  output [7:0] io_rdata_0_histPtr_value,
  output [3:0] io_rdata_0_ssp,
  output [2:0] io_rdata_0_sctr,
  output io_rdata_0_TOSW_flag,
  output [4:0] io_rdata_0_TOSW_value,
  output io_rdata_0_TOSR_flag,
  output [4:0] io_rdata_0_TOSR_value,
  output io_rdata_0_NOS_flag,
  output [4:0] io_rdata_0_NOS_value,
  output [49:0] io_rdata_0_topAddr,
  output io_rdata_1_histPtr_flag,
  output [7:0] io_rdata_1_histPtr_value,
  output [3:0] io_rdata_1_ssp,
  output [2:0] io_rdata_1_sctr,
  output io_rdata_1_TOSW_flag,
  output [4:0] io_rdata_1_TOSW_value,
  output io_rdata_1_TOSR_flag,
  output [4:0] io_rdata_1_TOSR_value,
  output io_rdata_1_NOS_flag,
  output [4:0] io_rdata_1_NOS_value,
  output io_rdata_1_sc_disagree_0,
  output io_rdata_1_sc_disagree_1,
  output [7:0] io_rdata_2_histPtr_value,
  input  io_wen_0,
  input  [3:0] io_waddr_0,
  input  io_wdata_0_histPtr_flag,
  input  [7:0] io_wdata_0_histPtr_value,
  input  [3:0] io_wdata_0_ssp,
  input  [2:0] io_wdata_0_sctr,
  input  io_wdata_0_TOSW_flag,
  input  [4:0] io_wdata_0_TOSW_value,
  input  io_wdata_0_TOSR_flag,
  input  [4:0] io_wdata_0_TOSR_value,
  input  io_wdata_0_NOS_flag,
  input  [4:0] io_wdata_0_NOS_value,
  input  [49:0] io_wdata_0_topAddr,
  input  io_wdata_0_sc_disagree_0,
  input  io_wdata_0_sc_disagree_1
);
  wire [3-1:0][86-1:0] rdata_bus;
  assign io_rdata_0_histPtr_flag = rdata_bus[0][0:0];
  assign io_rdata_0_histPtr_value = rdata_bus[0][8:1];
  assign io_rdata_0_ssp = rdata_bus[0][12:9];
  assign io_rdata_0_sctr = rdata_bus[0][15:13];
  assign io_rdata_0_TOSW_flag = rdata_bus[0][16:16];
  assign io_rdata_0_TOSW_value = rdata_bus[0][21:17];
  assign io_rdata_0_TOSR_flag = rdata_bus[0][22:22];
  assign io_rdata_0_TOSR_value = rdata_bus[0][27:23];
  assign io_rdata_0_NOS_flag = rdata_bus[0][28:28];
  assign io_rdata_0_NOS_value = rdata_bus[0][33:29];
  assign io_rdata_0_topAddr = rdata_bus[0][83:34];
  assign io_rdata_1_histPtr_flag = rdata_bus[1][0:0];
  assign io_rdata_1_histPtr_value = rdata_bus[1][8:1];
  assign io_rdata_1_ssp = rdata_bus[1][12:9];
  assign io_rdata_1_sctr = rdata_bus[1][15:13];
  assign io_rdata_1_TOSW_flag = rdata_bus[1][16:16];
  assign io_rdata_1_TOSW_value = rdata_bus[1][21:17];
  assign io_rdata_1_TOSR_flag = rdata_bus[1][22:22];
  assign io_rdata_1_TOSR_value = rdata_bus[1][27:23];
  assign io_rdata_1_NOS_flag = rdata_bus[1][28:28];
  assign io_rdata_1_NOS_value = rdata_bus[1][33:29];
  assign io_rdata_1_sc_disagree_0 = rdata_bus[1][84:84];
  assign io_rdata_1_sc_disagree_1 = rdata_bus[1][85:85];
  assign io_rdata_2_histPtr_value = rdata_bus[2][8:1];
  xs_DataModule #(
    .NUM_ENTRIES(16),
    .NUM_READ(3),
    .NUM_WRITE(1),
    .DATA_WIDTH(86),
    .BYPASS_EN(3'b111)
  ) u_core (
    .clock(clock),
    .io_raddr({io_raddr_2, io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({{io_wdata_0_sc_disagree_1, io_wdata_0_sc_disagree_0, io_wdata_0_topAddr, io_wdata_0_NOS_value, io_wdata_0_NOS_flag, io_wdata_0_TOSR_value, io_wdata_0_TOSR_flag, io_wdata_0_TOSW_value, io_wdata_0_TOSW_flag, io_wdata_0_sctr, io_wdata_0_ssp, io_wdata_0_histPtr_value, io_wdata_0_histPtr_flag}})
  );
endmodule

module DataModule__16entry_4(
  input  clock,
  input  [3:0] io_raddr_0,
  input  [3:0] io_raddr_1,
  output io_rdata_0_isCall,
  output io_rdata_0_isRet,
  output io_rdata_0_isJalr,
  output [3:0] io_rdata_0_brSlots_0_offset,
  output io_rdata_0_brSlots_0_valid,
  output [3:0] io_rdata_0_tailSlot_offset,
  output io_rdata_0_tailSlot_sharing,
  output io_rdata_0_tailSlot_valid,
  output io_rdata_1_isJalr,
  output [3:0] io_rdata_1_brSlots_0_offset,
  output io_rdata_1_brSlots_0_valid,
  output [3:0] io_rdata_1_tailSlot_offset,
  output io_rdata_1_tailSlot_sharing,
  output io_rdata_1_tailSlot_valid,
  input  io_wen_0,
  input  [3:0] io_waddr_0,
  input  io_wdata_0_isCall,
  input  io_wdata_0_isRet,
  input  io_wdata_0_isJalr,
  input  [3:0] io_wdata_0_brSlots_0_offset,
  input  io_wdata_0_brSlots_0_valid,
  input  [3:0] io_wdata_0_tailSlot_offset,
  input  io_wdata_0_tailSlot_sharing,
  input  io_wdata_0_tailSlot_valid
);
  wire [2-1:0][14-1:0] rdata_bus;
  assign io_rdata_0_isCall = rdata_bus[0][0:0];
  assign io_rdata_0_isRet = rdata_bus[0][1:1];
  assign io_rdata_0_isJalr = rdata_bus[0][2:2];
  assign io_rdata_0_brSlots_0_offset = rdata_bus[0][6:3];
  assign io_rdata_0_brSlots_0_valid = rdata_bus[0][7:7];
  assign io_rdata_0_tailSlot_offset = rdata_bus[0][11:8];
  assign io_rdata_0_tailSlot_sharing = rdata_bus[0][12:12];
  assign io_rdata_0_tailSlot_valid = rdata_bus[0][13:13];
  assign io_rdata_1_isJalr = rdata_bus[1][2:2];
  assign io_rdata_1_brSlots_0_offset = rdata_bus[1][6:3];
  assign io_rdata_1_brSlots_0_valid = rdata_bus[1][7:7];
  assign io_rdata_1_tailSlot_offset = rdata_bus[1][11:8];
  assign io_rdata_1_tailSlot_sharing = rdata_bus[1][12:12];
  assign io_rdata_1_tailSlot_valid = rdata_bus[1][13:13];
  xs_DataModule #(
    .NUM_ENTRIES(16),
    .NUM_READ(2),
    .NUM_WRITE(1),
    .DATA_WIDTH(14),
    .BYPASS_EN(2'b11)
  ) u_core (
    .clock(clock),
    .io_raddr({io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({{io_wdata_0_tailSlot_valid, io_wdata_0_tailSlot_sharing, io_wdata_0_tailSlot_offset, io_wdata_0_brSlots_0_valid, io_wdata_0_brSlots_0_offset, io_wdata_0_isJalr, io_wdata_0_isRet, io_wdata_0_isCall}})
  );
endmodule

module DataModule__16entry_8(
  input  clock,
  input  [3:0] io_raddr_0,
  input  [3:0] io_raddr_1,
  output io_rdata_0_brMask_0,
  output io_rdata_0_brMask_1,
  output io_rdata_0_brMask_2,
  output io_rdata_0_brMask_3,
  output io_rdata_0_brMask_4,
  output io_rdata_0_brMask_5,
  output io_rdata_0_brMask_6,
  output io_rdata_0_brMask_7,
  output io_rdata_0_brMask_8,
  output io_rdata_0_brMask_9,
  output io_rdata_0_brMask_10,
  output io_rdata_0_brMask_11,
  output io_rdata_0_brMask_12,
  output io_rdata_0_brMask_13,
  output io_rdata_0_brMask_14,
  output io_rdata_0_brMask_15,
  output io_rdata_0_jmpInfo_valid,
  output io_rdata_0_jmpInfo_bits_0,
  output io_rdata_0_jmpInfo_bits_1,
  output io_rdata_0_jmpInfo_bits_2,
  output [3:0] io_rdata_0_jmpOffset,
  output io_rdata_0_rvcMask_0,
  output io_rdata_0_rvcMask_1,
  output io_rdata_0_rvcMask_2,
  output io_rdata_0_rvcMask_3,
  output io_rdata_0_rvcMask_4,
  output io_rdata_0_rvcMask_5,
  output io_rdata_0_rvcMask_6,
  output io_rdata_0_rvcMask_7,
  output io_rdata_0_rvcMask_8,
  output io_rdata_0_rvcMask_9,
  output io_rdata_0_rvcMask_10,
  output io_rdata_0_rvcMask_11,
  output io_rdata_0_rvcMask_12,
  output io_rdata_0_rvcMask_13,
  output io_rdata_0_rvcMask_14,
  output io_rdata_0_rvcMask_15,
  output io_rdata_1_brMask_0,
  output io_rdata_1_brMask_1,
  output io_rdata_1_brMask_2,
  output io_rdata_1_brMask_3,
  output io_rdata_1_brMask_4,
  output io_rdata_1_brMask_5,
  output io_rdata_1_brMask_6,
  output io_rdata_1_brMask_7,
  output io_rdata_1_brMask_8,
  output io_rdata_1_brMask_9,
  output io_rdata_1_brMask_10,
  output io_rdata_1_brMask_11,
  output io_rdata_1_brMask_12,
  output io_rdata_1_brMask_13,
  output io_rdata_1_brMask_14,
  output io_rdata_1_brMask_15,
  output io_rdata_1_jmpInfo_valid,
  output io_rdata_1_jmpInfo_bits_0,
  output io_rdata_1_jmpInfo_bits_1,
  output io_rdata_1_jmpInfo_bits_2,
  output [3:0] io_rdata_1_jmpOffset,
  output [49:0] io_rdata_1_jalTarget,
  output io_rdata_1_rvcMask_0,
  output io_rdata_1_rvcMask_1,
  output io_rdata_1_rvcMask_2,
  output io_rdata_1_rvcMask_3,
  output io_rdata_1_rvcMask_4,
  output io_rdata_1_rvcMask_5,
  output io_rdata_1_rvcMask_6,
  output io_rdata_1_rvcMask_7,
  output io_rdata_1_rvcMask_8,
  output io_rdata_1_rvcMask_9,
  output io_rdata_1_rvcMask_10,
  output io_rdata_1_rvcMask_11,
  output io_rdata_1_rvcMask_12,
  output io_rdata_1_rvcMask_13,
  output io_rdata_1_rvcMask_14,
  output io_rdata_1_rvcMask_15,
  input  io_wen_0,
  input  [3:0] io_waddr_0,
  input  io_wdata_0_brMask_0,
  input  io_wdata_0_brMask_1,
  input  io_wdata_0_brMask_2,
  input  io_wdata_0_brMask_3,
  input  io_wdata_0_brMask_4,
  input  io_wdata_0_brMask_5,
  input  io_wdata_0_brMask_6,
  input  io_wdata_0_brMask_7,
  input  io_wdata_0_brMask_8,
  input  io_wdata_0_brMask_9,
  input  io_wdata_0_brMask_10,
  input  io_wdata_0_brMask_11,
  input  io_wdata_0_brMask_12,
  input  io_wdata_0_brMask_13,
  input  io_wdata_0_brMask_14,
  input  io_wdata_0_brMask_15,
  input  io_wdata_0_jmpInfo_valid,
  input  io_wdata_0_jmpInfo_bits_0,
  input  io_wdata_0_jmpInfo_bits_1,
  input  io_wdata_0_jmpInfo_bits_2,
  input  [3:0] io_wdata_0_jmpOffset,
  input  [49:0] io_wdata_0_jalTarget,
  input  io_wdata_0_rvcMask_0,
  input  io_wdata_0_rvcMask_1,
  input  io_wdata_0_rvcMask_2,
  input  io_wdata_0_rvcMask_3,
  input  io_wdata_0_rvcMask_4,
  input  io_wdata_0_rvcMask_5,
  input  io_wdata_0_rvcMask_6,
  input  io_wdata_0_rvcMask_7,
  input  io_wdata_0_rvcMask_8,
  input  io_wdata_0_rvcMask_9,
  input  io_wdata_0_rvcMask_10,
  input  io_wdata_0_rvcMask_11,
  input  io_wdata_0_rvcMask_12,
  input  io_wdata_0_rvcMask_13,
  input  io_wdata_0_rvcMask_14,
  input  io_wdata_0_rvcMask_15
);
  wire [2-1:0][90-1:0] rdata_bus;
  assign io_rdata_0_brMask_0 = rdata_bus[0][0:0];
  assign io_rdata_0_brMask_1 = rdata_bus[0][1:1];
  assign io_rdata_0_brMask_2 = rdata_bus[0][2:2];
  assign io_rdata_0_brMask_3 = rdata_bus[0][3:3];
  assign io_rdata_0_brMask_4 = rdata_bus[0][4:4];
  assign io_rdata_0_brMask_5 = rdata_bus[0][5:5];
  assign io_rdata_0_brMask_6 = rdata_bus[0][6:6];
  assign io_rdata_0_brMask_7 = rdata_bus[0][7:7];
  assign io_rdata_0_brMask_8 = rdata_bus[0][8:8];
  assign io_rdata_0_brMask_9 = rdata_bus[0][9:9];
  assign io_rdata_0_brMask_10 = rdata_bus[0][10:10];
  assign io_rdata_0_brMask_11 = rdata_bus[0][11:11];
  assign io_rdata_0_brMask_12 = rdata_bus[0][12:12];
  assign io_rdata_0_brMask_13 = rdata_bus[0][13:13];
  assign io_rdata_0_brMask_14 = rdata_bus[0][14:14];
  assign io_rdata_0_brMask_15 = rdata_bus[0][15:15];
  assign io_rdata_0_jmpInfo_valid = rdata_bus[0][16:16];
  assign io_rdata_0_jmpInfo_bits_0 = rdata_bus[0][17:17];
  assign io_rdata_0_jmpInfo_bits_1 = rdata_bus[0][18:18];
  assign io_rdata_0_jmpInfo_bits_2 = rdata_bus[0][19:19];
  assign io_rdata_0_jmpOffset = rdata_bus[0][23:20];
  assign io_rdata_0_rvcMask_0 = rdata_bus[0][74:74];
  assign io_rdata_0_rvcMask_1 = rdata_bus[0][75:75];
  assign io_rdata_0_rvcMask_2 = rdata_bus[0][76:76];
  assign io_rdata_0_rvcMask_3 = rdata_bus[0][77:77];
  assign io_rdata_0_rvcMask_4 = rdata_bus[0][78:78];
  assign io_rdata_0_rvcMask_5 = rdata_bus[0][79:79];
  assign io_rdata_0_rvcMask_6 = rdata_bus[0][80:80];
  assign io_rdata_0_rvcMask_7 = rdata_bus[0][81:81];
  assign io_rdata_0_rvcMask_8 = rdata_bus[0][82:82];
  assign io_rdata_0_rvcMask_9 = rdata_bus[0][83:83];
  assign io_rdata_0_rvcMask_10 = rdata_bus[0][84:84];
  assign io_rdata_0_rvcMask_11 = rdata_bus[0][85:85];
  assign io_rdata_0_rvcMask_12 = rdata_bus[0][86:86];
  assign io_rdata_0_rvcMask_13 = rdata_bus[0][87:87];
  assign io_rdata_0_rvcMask_14 = rdata_bus[0][88:88];
  assign io_rdata_0_rvcMask_15 = rdata_bus[0][89:89];
  assign io_rdata_1_brMask_0 = rdata_bus[1][0:0];
  assign io_rdata_1_brMask_1 = rdata_bus[1][1:1];
  assign io_rdata_1_brMask_2 = rdata_bus[1][2:2];
  assign io_rdata_1_brMask_3 = rdata_bus[1][3:3];
  assign io_rdata_1_brMask_4 = rdata_bus[1][4:4];
  assign io_rdata_1_brMask_5 = rdata_bus[1][5:5];
  assign io_rdata_1_brMask_6 = rdata_bus[1][6:6];
  assign io_rdata_1_brMask_7 = rdata_bus[1][7:7];
  assign io_rdata_1_brMask_8 = rdata_bus[1][8:8];
  assign io_rdata_1_brMask_9 = rdata_bus[1][9:9];
  assign io_rdata_1_brMask_10 = rdata_bus[1][10:10];
  assign io_rdata_1_brMask_11 = rdata_bus[1][11:11];
  assign io_rdata_1_brMask_12 = rdata_bus[1][12:12];
  assign io_rdata_1_brMask_13 = rdata_bus[1][13:13];
  assign io_rdata_1_brMask_14 = rdata_bus[1][14:14];
  assign io_rdata_1_brMask_15 = rdata_bus[1][15:15];
  assign io_rdata_1_jmpInfo_valid = rdata_bus[1][16:16];
  assign io_rdata_1_jmpInfo_bits_0 = rdata_bus[1][17:17];
  assign io_rdata_1_jmpInfo_bits_1 = rdata_bus[1][18:18];
  assign io_rdata_1_jmpInfo_bits_2 = rdata_bus[1][19:19];
  assign io_rdata_1_jmpOffset = rdata_bus[1][23:20];
  assign io_rdata_1_jalTarget = rdata_bus[1][73:24];
  assign io_rdata_1_rvcMask_0 = rdata_bus[1][74:74];
  assign io_rdata_1_rvcMask_1 = rdata_bus[1][75:75];
  assign io_rdata_1_rvcMask_2 = rdata_bus[1][76:76];
  assign io_rdata_1_rvcMask_3 = rdata_bus[1][77:77];
  assign io_rdata_1_rvcMask_4 = rdata_bus[1][78:78];
  assign io_rdata_1_rvcMask_5 = rdata_bus[1][79:79];
  assign io_rdata_1_rvcMask_6 = rdata_bus[1][80:80];
  assign io_rdata_1_rvcMask_7 = rdata_bus[1][81:81];
  assign io_rdata_1_rvcMask_8 = rdata_bus[1][82:82];
  assign io_rdata_1_rvcMask_9 = rdata_bus[1][83:83];
  assign io_rdata_1_rvcMask_10 = rdata_bus[1][84:84];
  assign io_rdata_1_rvcMask_11 = rdata_bus[1][85:85];
  assign io_rdata_1_rvcMask_12 = rdata_bus[1][86:86];
  assign io_rdata_1_rvcMask_13 = rdata_bus[1][87:87];
  assign io_rdata_1_rvcMask_14 = rdata_bus[1][88:88];
  assign io_rdata_1_rvcMask_15 = rdata_bus[1][89:89];
  xs_DataModule #(
    .NUM_ENTRIES(16),
    .NUM_READ(2),
    .NUM_WRITE(1),
    .DATA_WIDTH(90),
    .BYPASS_EN(2'b11)
  ) u_core (
    .clock(clock),
    .io_raddr({io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({{io_wdata_0_rvcMask_15, io_wdata_0_rvcMask_14, io_wdata_0_rvcMask_13, io_wdata_0_rvcMask_12, io_wdata_0_rvcMask_11, io_wdata_0_rvcMask_10, io_wdata_0_rvcMask_9, io_wdata_0_rvcMask_8, io_wdata_0_rvcMask_7, io_wdata_0_rvcMask_6, io_wdata_0_rvcMask_5, io_wdata_0_rvcMask_4, io_wdata_0_rvcMask_3, io_wdata_0_rvcMask_2, io_wdata_0_rvcMask_1, io_wdata_0_rvcMask_0, io_wdata_0_jalTarget, io_wdata_0_jmpOffset, io_wdata_0_jmpInfo_bits_2, io_wdata_0_jmpInfo_bits_1, io_wdata_0_jmpInfo_bits_0, io_wdata_0_jmpInfo_valid, io_wdata_0_brMask_15, io_wdata_0_brMask_14, io_wdata_0_brMask_13, io_wdata_0_brMask_12, io_wdata_0_brMask_11, io_wdata_0_brMask_10, io_wdata_0_brMask_9, io_wdata_0_brMask_8, io_wdata_0_brMask_7, io_wdata_0_brMask_6, io_wdata_0_brMask_5, io_wdata_0_brMask_4, io_wdata_0_brMask_3, io_wdata_0_brMask_2, io_wdata_0_brMask_1, io_wdata_0_brMask_0}})
  );
endmodule

module DataModule__16entry_12(
  input  clock,
  input  [3:0] io_raddr_0,
  input  [3:0] io_raddr_1,
  input  [3:0] io_raddr_2,
  input  [3:0] io_raddr_3,
  input  [3:0] io_raddr_4,
  input  [3:0] io_raddr_5,
  input  [3:0] io_raddr_6,
  input  [3:0] io_raddr_7,
  output io_rdata_0_vtype_illegal,
  output io_rdata_0_vtype_vma,
  output io_rdata_0_vtype_vta,
  output [1:0] io_rdata_0_vtype_vsew,
  output [2:0] io_rdata_0_vtype_vlmul,
  output io_rdata_0_isVsetvl,
  output io_rdata_1_vtype_illegal,
  output io_rdata_1_vtype_vma,
  output io_rdata_1_vtype_vta,
  output [1:0] io_rdata_1_vtype_vsew,
  output [2:0] io_rdata_1_vtype_vlmul,
  output io_rdata_1_isVsetvl,
  output io_rdata_2_vtype_illegal,
  output io_rdata_2_vtype_vma,
  output io_rdata_2_vtype_vta,
  output [1:0] io_rdata_2_vtype_vsew,
  output [2:0] io_rdata_2_vtype_vlmul,
  output io_rdata_2_isVsetvl,
  output io_rdata_3_vtype_illegal,
  output io_rdata_3_vtype_vma,
  output io_rdata_3_vtype_vta,
  output [1:0] io_rdata_3_vtype_vsew,
  output [2:0] io_rdata_3_vtype_vlmul,
  output io_rdata_3_isVsetvl,
  output io_rdata_4_vtype_illegal,
  output io_rdata_4_vtype_vma,
  output io_rdata_4_vtype_vta,
  output [1:0] io_rdata_4_vtype_vsew,
  output [2:0] io_rdata_4_vtype_vlmul,
  output io_rdata_4_isVsetvl,
  output io_rdata_5_vtype_illegal,
  output io_rdata_5_vtype_vma,
  output io_rdata_5_vtype_vta,
  output [1:0] io_rdata_5_vtype_vsew,
  output [2:0] io_rdata_5_vtype_vlmul,
  output io_rdata_5_isVsetvl,
  output io_rdata_6_vtype_illegal,
  output io_rdata_6_vtype_vma,
  output io_rdata_6_vtype_vta,
  output [1:0] io_rdata_6_vtype_vsew,
  output [2:0] io_rdata_6_vtype_vlmul,
  output io_rdata_6_isVsetvl,
  output io_rdata_7_vtype_illegal,
  output io_rdata_7_vtype_vma,
  output io_rdata_7_vtype_vta,
  output [1:0] io_rdata_7_vtype_vsew,
  output [2:0] io_rdata_7_vtype_vlmul,
  output io_rdata_7_isVsetvl,
  input  io_wen_0,
  input  io_wen_1,
  input  io_wen_2,
  input  io_wen_3,
  input  io_wen_4,
  input  io_wen_5,
  input  [3:0] io_waddr_0,
  input  [3:0] io_waddr_1,
  input  [3:0] io_waddr_2,
  input  [3:0] io_waddr_3,
  input  [3:0] io_waddr_4,
  input  [3:0] io_waddr_5,
  input  io_wdata_0_vtype_illegal,
  input  io_wdata_0_vtype_vma,
  input  io_wdata_0_vtype_vta,
  input  [1:0] io_wdata_0_vtype_vsew,
  input  [2:0] io_wdata_0_vtype_vlmul,
  input  io_wdata_0_isVsetvl,
  input  io_wdata_1_vtype_illegal,
  input  io_wdata_1_vtype_vma,
  input  io_wdata_1_vtype_vta,
  input  [1:0] io_wdata_1_vtype_vsew,
  input  [2:0] io_wdata_1_vtype_vlmul,
  input  io_wdata_1_isVsetvl,
  input  io_wdata_2_vtype_illegal,
  input  io_wdata_2_vtype_vma,
  input  io_wdata_2_vtype_vta,
  input  [1:0] io_wdata_2_vtype_vsew,
  input  [2:0] io_wdata_2_vtype_vlmul,
  input  io_wdata_2_isVsetvl,
  input  io_wdata_3_vtype_illegal,
  input  io_wdata_3_vtype_vma,
  input  io_wdata_3_vtype_vta,
  input  [1:0] io_wdata_3_vtype_vsew,
  input  [2:0] io_wdata_3_vtype_vlmul,
  input  io_wdata_3_isVsetvl,
  input  io_wdata_4_vtype_illegal,
  input  io_wdata_4_vtype_vma,
  input  io_wdata_4_vtype_vta,
  input  [1:0] io_wdata_4_vtype_vsew,
  input  [2:0] io_wdata_4_vtype_vlmul,
  input  io_wdata_4_isVsetvl,
  input  io_wdata_5_vtype_illegal,
  input  io_wdata_5_vtype_vma,
  input  io_wdata_5_vtype_vta,
  input  [1:0] io_wdata_5_vtype_vsew,
  input  [2:0] io_wdata_5_vtype_vlmul,
  input  io_wdata_5_isVsetvl
);
  wire [8-1:0][9-1:0] rdata_bus;
  assign io_rdata_0_vtype_illegal = rdata_bus[0][0:0];
  assign io_rdata_0_vtype_vma = rdata_bus[0][1:1];
  assign io_rdata_0_vtype_vta = rdata_bus[0][2:2];
  assign io_rdata_0_vtype_vsew = rdata_bus[0][4:3];
  assign io_rdata_0_vtype_vlmul = rdata_bus[0][7:5];
  assign io_rdata_0_isVsetvl = rdata_bus[0][8:8];
  assign io_rdata_1_vtype_illegal = rdata_bus[1][0:0];
  assign io_rdata_1_vtype_vma = rdata_bus[1][1:1];
  assign io_rdata_1_vtype_vta = rdata_bus[1][2:2];
  assign io_rdata_1_vtype_vsew = rdata_bus[1][4:3];
  assign io_rdata_1_vtype_vlmul = rdata_bus[1][7:5];
  assign io_rdata_1_isVsetvl = rdata_bus[1][8:8];
  assign io_rdata_2_vtype_illegal = rdata_bus[2][0:0];
  assign io_rdata_2_vtype_vma = rdata_bus[2][1:1];
  assign io_rdata_2_vtype_vta = rdata_bus[2][2:2];
  assign io_rdata_2_vtype_vsew = rdata_bus[2][4:3];
  assign io_rdata_2_vtype_vlmul = rdata_bus[2][7:5];
  assign io_rdata_2_isVsetvl = rdata_bus[2][8:8];
  assign io_rdata_3_vtype_illegal = rdata_bus[3][0:0];
  assign io_rdata_3_vtype_vma = rdata_bus[3][1:1];
  assign io_rdata_3_vtype_vta = rdata_bus[3][2:2];
  assign io_rdata_3_vtype_vsew = rdata_bus[3][4:3];
  assign io_rdata_3_vtype_vlmul = rdata_bus[3][7:5];
  assign io_rdata_3_isVsetvl = rdata_bus[3][8:8];
  assign io_rdata_4_vtype_illegal = rdata_bus[4][0:0];
  assign io_rdata_4_vtype_vma = rdata_bus[4][1:1];
  assign io_rdata_4_vtype_vta = rdata_bus[4][2:2];
  assign io_rdata_4_vtype_vsew = rdata_bus[4][4:3];
  assign io_rdata_4_vtype_vlmul = rdata_bus[4][7:5];
  assign io_rdata_4_isVsetvl = rdata_bus[4][8:8];
  assign io_rdata_5_vtype_illegal = rdata_bus[5][0:0];
  assign io_rdata_5_vtype_vma = rdata_bus[5][1:1];
  assign io_rdata_5_vtype_vta = rdata_bus[5][2:2];
  assign io_rdata_5_vtype_vsew = rdata_bus[5][4:3];
  assign io_rdata_5_vtype_vlmul = rdata_bus[5][7:5];
  assign io_rdata_5_isVsetvl = rdata_bus[5][8:8];
  assign io_rdata_6_vtype_illegal = rdata_bus[6][0:0];
  assign io_rdata_6_vtype_vma = rdata_bus[6][1:1];
  assign io_rdata_6_vtype_vta = rdata_bus[6][2:2];
  assign io_rdata_6_vtype_vsew = rdata_bus[6][4:3];
  assign io_rdata_6_vtype_vlmul = rdata_bus[6][7:5];
  assign io_rdata_6_isVsetvl = rdata_bus[6][8:8];
  assign io_rdata_7_vtype_illegal = rdata_bus[7][0:0];
  assign io_rdata_7_vtype_vma = rdata_bus[7][1:1];
  assign io_rdata_7_vtype_vta = rdata_bus[7][2:2];
  assign io_rdata_7_vtype_vsew = rdata_bus[7][4:3];
  assign io_rdata_7_vtype_vlmul = rdata_bus[7][7:5];
  assign io_rdata_7_isVsetvl = rdata_bus[7][8:8];
  xs_DataModule #(
    .NUM_ENTRIES(16),
    .NUM_READ(8),
    .NUM_WRITE(6),
    .DATA_WIDTH(9),
    .BYPASS_EN(8'b11111111)
  ) u_core (
    .clock(clock),
    .io_raddr({io_raddr_7, io_raddr_6, io_raddr_5, io_raddr_4, io_raddr_3, io_raddr_2, io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_5, io_wen_4, io_wen_3, io_wen_2, io_wen_1, io_wen_0}),
    .io_waddr({io_waddr_5, io_waddr_4, io_waddr_3, io_waddr_2, io_waddr_1, io_waddr_0}),
    .io_wdata({{io_wdata_5_isVsetvl, io_wdata_5_vtype_vlmul, io_wdata_5_vtype_vsew, io_wdata_5_vtype_vta, io_wdata_5_vtype_vma, io_wdata_5_vtype_illegal}, {io_wdata_4_isVsetvl, io_wdata_4_vtype_vlmul, io_wdata_4_vtype_vsew, io_wdata_4_vtype_vta, io_wdata_4_vtype_vma, io_wdata_4_vtype_illegal}, {io_wdata_3_isVsetvl, io_wdata_3_vtype_vlmul, io_wdata_3_vtype_vsew, io_wdata_3_vtype_vta, io_wdata_3_vtype_vma, io_wdata_3_vtype_illegal}, {io_wdata_2_isVsetvl, io_wdata_2_vtype_vlmul, io_wdata_2_vtype_vsew, io_wdata_2_vtype_vta, io_wdata_2_vtype_vma, io_wdata_2_vtype_illegal}, {io_wdata_1_isVsetvl, io_wdata_1_vtype_vlmul, io_wdata_1_vtype_vsew, io_wdata_1_vtype_vta, io_wdata_1_vtype_vma, io_wdata_1_vtype_illegal}, {io_wdata_0_isVsetvl, io_wdata_0_vtype_vlmul, io_wdata_0_vtype_vsew, io_wdata_0_vtype_vta, io_wdata_0_vtype_vma, io_wdata_0_vtype_illegal}})
  );
endmodule

module DataModule__16entry_16(
  input  clock,
  input  [3:0] io_raddr_0,
  output [55:0] io_rdata_0_gpaddr,
  output io_rdata_0_isForVSnonLeafPTE,
  input  io_wen_0,
  input  [3:0] io_waddr_0,
  input  [55:0] io_wdata_0_gpaddr,
  input  io_wdata_0_isForVSnonLeafPTE
);
  wire [1-1:0][57-1:0] rdata_bus;
  assign io_rdata_0_gpaddr = rdata_bus[0][55:0];
  assign io_rdata_0_isForVSnonLeafPTE = rdata_bus[0][56:56];
  xs_DataModule #(
    .NUM_ENTRIES(16),
    .NUM_READ(1),
    .NUM_WRITE(1),
    .DATA_WIDTH(57),
    .BYPASS_EN(1'b1)
  ) u_core (
    .clock(clock),
    .io_raddr({io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({{io_wdata_0_isForVSnonLeafPTE, io_wdata_0_gpaddr}})
  );
endmodule
