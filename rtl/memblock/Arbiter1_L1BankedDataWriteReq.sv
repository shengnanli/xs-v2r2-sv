// Arbiter1_L1BankedDataWriteReq —— DCache 数据阵列写口前的单入仲裁器（退化为直通）
//
// 位置：DCacheImp 里 `dataWriteArb = Module(new Arbiter(new L1BankedDataWriteReq, 1))`，
//   唯一输入是 MainPipe 的 data_write（refill 整行 / store 合并后的整行写回），
//   输出接 BankedDataArray 的写口。RefillPipe 那一路在 Scala 里已注释掉，只剩 1 个入口。
// 语义：单入 Arbiter = 直通。数据阵列写口 ready 恒 1、上游不读 ready，
//   两根 ready 与 chosen 均被 firtool 删掉。
// 载荷只剩"数据半边"：
//   wmask  —— 8 个 bank 的写使能（一行 64B = 8 bank × 8B，bank i 对应 data_i）；
//   data_i —— 第 i 个 bank 的 64 位数据。
//   写地址（way_en / addr）不在这里：它走 8 份复制的 Arbiter1_L1BankedDataWriteReqCtrl
//   （每 bank 一份，为了扇出时序），所以本件的 L1BankedDataWriteReq 里那两个字段
//   在 golden 端口上被删掉了。
// 本文件自足，不例化任何核（共享核 xs_FixedPriorityArbiter_core 要求 NUM_IN >= 2）。

module Arbiter1_L1BankedDataWriteReq(
  input         io_in_0_valid,
  input  [7:0]  io_in_0_bits_wmask,
  input  [63:0] io_in_0_bits_data_0,
  input  [63:0] io_in_0_bits_data_1,
  input  [63:0] io_in_0_bits_data_2,
  input  [63:0] io_in_0_bits_data_3,
  input  [63:0] io_in_0_bits_data_4,
  input  [63:0] io_in_0_bits_data_5,
  input  [63:0] io_in_0_bits_data_6,
  input  [63:0] io_in_0_bits_data_7,
  output        io_out_valid,
  output [7:0]  io_out_bits_wmask,
  output [63:0] io_out_bits_data_0,
  output [63:0] io_out_bits_data_1,
  output [63:0] io_out_bits_data_2,
  output [63:0] io_out_bits_data_3,
  output [63:0] io_out_bits_data_4,
  output [63:0] io_out_bits_data_5,
  output [63:0] io_out_bits_data_6,
  output [63:0] io_out_bits_data_7
);
  assign io_out_valid       = io_in_0_valid;
  assign io_out_bits_wmask  = io_in_0_bits_wmask;
  assign io_out_bits_data_0 = io_in_0_bits_data_0;
  assign io_out_bits_data_1 = io_in_0_bits_data_1;
  assign io_out_bits_data_2 = io_in_0_bits_data_2;
  assign io_out_bits_data_3 = io_in_0_bits_data_3;
  assign io_out_bits_data_4 = io_in_0_bits_data_4;
  assign io_out_bits_data_5 = io_in_0_bits_data_5;
  assign io_out_bits_data_6 = io_in_0_bits_data_6;
  assign io_out_bits_data_7 = io_in_0_bits_data_7;
endmodule
