// =============================================================================
// MepcModule.sv —— 机器态 trap 返回地址寄存器 mepc，NewCSR 的 CSR 叶（0 子模块）。
// 本变体：epc 亚族（共享核 IS_TVEC=0），trap 装载口前缀 trapToM_mepc_*（M 态 trap）。
// 机制：63 位返回地址寄存器，异步复位 0；软件写（w_wen/w_wdata[63:1]）或 trap
//   装载（trapToM_mepc_valid/bits_epc）任一成立即更新，同拍两路按位或合并；
//   rdata = {epc, 1'b0}（bit0 恒 0），regOut_epc 是供 NewCSR 内部直读的视图。
// 核体见 rtl/backend/xs_CsrEpcTvec_core.sv（epc/tvec 两亚族共用一份）。
// wrapper 端口表与 u_core 连线由 scripts/gen_csrepctvec_leaves7.py 生成（GENERATED 区）。
// =============================================================================

// BEGIN GENERATED(csrepctvec-leaves7)
module MepcModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [62:0] regOut_epc,
  input         trapToM_mepc_valid,
  input  [62:0] trapToM_mepc_bits_epc
);

  xs_CsrEpcTvec_core #(
    .IS_TVEC (1'b0)
  ) u_core (
    .clock      (clock),
    .reset      (reset),
    .wen        (w_wen),
    .wdata      (w_wdata),
    .trap_valid (trapToM_mepc_valid),
    .trap_epc   (trapToM_mepc_bits_epc),
    .rdata      (rdata),
    .epc        (regOut_epc),
    .mode       (),
    .addr       ()
  );
endmodule
// END GENERATED
