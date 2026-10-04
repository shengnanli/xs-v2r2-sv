// MbistClockGateCell.sv —— 带 MBIST 控制的 SRAM 时钟门控单元（无 DFT 旁路的基础款）
//
// Scala：utility/src/main/scala/utility/mbist/MbistClockGateCell.scala，
//   class MbistClockGateCell(mcpCtl = false)。golden 里由 SRAMTemplate / _2 / _44 / _45 / _64 /
//   _68 / _84 / _88 / _116 / _145 等例化，给 SRAM 阵列供时钟；只有真要访问 SRAM 的那一拍才放时钟过去。
//
//   时钟使能 E' = mbist_req ? (mbist_readen | mbist_writeen) : E
//     * 正常工作（mbist_req=0）：E = 本拍是否读/写 SRAM
//     * MBIST 自测（mbist_req=1）：改看 MBIST 控制器给的读/写使能
//   ClockGate（锁存器型门控单元，本仓 rtl/common/ClockGate.sv 已签核）：TE=dft_cgen 强制打开。
//
// 同家族：同一个 Scala 类取 mcpCtl = true 就是 MbistClockGateCell_93（rtl/common/
//   MbistClockGateCell_93.sv，已签核），多两条 DFT 路径——dft_ram_mcp_hold 关时钟、
//   dft_ram_aux_ckbp 切到外部辅助时钟（ClockMux）。本单元 = _93 去掉 "& ~mcp_hold" 与 ClockMux。
//   两者逻辑只有一行 assign，不为此抽公共核（那会改动已签文件 _93）。

module MbistClockGateCell (
  input  clock,
  input  mbist_writeen,
  input  mbist_readen,
  input  mbist_req,
  input  E,
  input  dft_cgen,
  output out_clock
);

  logic clockEnable;   // 本拍是否放时钟

  assign clockEnable = mbist_req ? (mbist_readen | mbist_writeen) : E;

  ClockGate CG (
    .TE (dft_cgen),
    .E  (clockEnable),
    .CK (clock),
    .Q  (out_clock)
  );

endmodule
