// MbistClockGateCell_93.sv —— 带 MBIST / DFT 控制的 SRAM 读时钟门控单元（L2 数据阵列用）
//
// 位置：GatedSplittedSRAM 里每个 SRAM bank 一个（cg / cg_1 / cg_2 / cg_3），给 SRAM 的
// io_mbistCgCtl_rclk 供时钟。只有真要访问 SRAM 的那一拍才放时钟过去，省 L2 数据阵列的功耗。
//
//   时钟使能 E' = (mbist_req ? mbist_readen | mbist_writeen : E) & ~dft_ram_mcp_hold
//     * 正常工作：E = io_en（DataStorage 本拍要读/写数据阵列）
//     * MBIST 测试（mbist_req=1）：改看 MBIST 的读/写使能
//     * DFT 多周期路径保持（mcp_hold）时一律关时钟
//   ClockGate（锁存器型门控单元，golden 同源单元模型，两侧共用）：TE=dft_cgen 强制打开
//   ClockMux：dft_ram_aux_ckbp=1 时整个换成外部辅助时钟 dft_ram_aux_clk
//
// 与 golden 的 MbistClockGateCell（无 _93）相比多了 mcp_hold 与 aux 时钟这两条 DFT 路径。

module MbistClockGateCell_93 (
  input  logic clock,
  input  logic mbist_writeen,
  input  logic mbist_readen,
  input  logic mbist_req,
  input  logic E,
  input  logic dft_ram_mcp_hold,
  input  logic dft_ram_aux_clk,
  input  logic dft_ram_aux_ckbp,
  input  logic dft_cgen,
  output logic out_clock
);

  logic clockEnable;   // 本拍是否放时钟
  logic gatedClock;    // 门控后的工作时钟

  assign clockEnable = (mbist_req ? (mbist_readen | mbist_writeen) : E) & ~dft_ram_mcp_hold;

  ClockGate CG (
    .TE (dft_cgen),
    .E  (clockEnable),
    .CK (clock),
    .Q  (gatedClock)
  );

  ClockMux clockMux (
    .clk0   (gatedClock),
    .clk1   (dft_ram_aux_clk),
    .sel    (dft_ram_aux_ckbp),
    .clkout (out_clock)
  );

endmodule
