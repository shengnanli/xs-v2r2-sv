// 自动生成：scripts/gen_dm_wrappers.py（G1 基线驱动）—— 勿手改
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
