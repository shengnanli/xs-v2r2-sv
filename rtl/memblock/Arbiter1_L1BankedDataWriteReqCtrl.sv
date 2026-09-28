// Arbiter1_L1BankedDataWriteReqCtrl —— 数据阵列写口"地址半边"的单入仲裁器（直通）
//
// 位置：DCacheImp 为 8 个数据 bank 各例化一份（dataWriteArb_dup_0..7）：
//   `Module(new Arbiter(new L1BankedDataWriteReqCtrl, 1))`，输入是 MainPipe 的
//   data_write_dup(bank)，输出接 BankedDataArray.io.write_dup(bank)。
//   之所以复制 8 份：写地址要扇出到 8 个 bank × 4 路的 SRAM，复制寄存/连线减轻扇出；
//   golden 里 8 份逻辑完全相同，本件被例化 8 次。
// 语义：单入 Arbiter = 直通。ready/chosen 都被 firtool 删掉（同 Arbiter1_L1BankedDataWriteReq）。
// 载荷：way_en = 4 路独热写使能；addr = 行物理地址（阵列只用其中的 set 下标位）。
// 本文件自足，不例化任何核（共享核 xs_FixedPriorityArbiter_core 要求 NUM_IN >= 2）。

module Arbiter1_L1BankedDataWriteReqCtrl(
  input         io_in_0_valid,
  input  [3:0]  io_in_0_bits_way_en,
  input  [47:0] io_in_0_bits_addr,
  output        io_out_valid,
  output [3:0]  io_out_bits_way_en,
  output [47:0] io_out_bits_addr
);
  assign io_out_valid       = io_in_0_valid;
  assign io_out_bits_way_en = io_in_0_bits_way_en;
  assign io_out_bits_addr   = io_in_0_bits_addr;
endmodule
