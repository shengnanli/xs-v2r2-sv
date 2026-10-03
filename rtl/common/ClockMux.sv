// ClockMux.sv —— 二选一时钟选择器（DFT 用：测试时把 SRAM 时钟切到外部辅助时钟）
//
// utility 里的 ClockMux：sel=1 选 clk1，否则 clk0。纯组合，无状态。
// 在 MbistClockGateCell_93 里：clk0 = 门控后的工作时钟，clk1 = dft_ram_aux_clk，
// sel = dft_ram_aux_ckbp（DFT 旁路）。

module ClockMux (
  input  logic clk0,
  input  logic clk1,
  input  logic sel,
  output logic clkout
);

  assign clkout = sel ? clk1 : clk0;

endmodule
