// 自动生成：scripts/gen_dm_wrappers.py（G1 基线驱动）—— 勿手改
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
