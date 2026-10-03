// =============================================================================
// VStvecModule.sv —— 虚拟监管态 trap 向量寄存器 vstvec，NewCSR 的 CSR 叶（0 子模块）。
// 本变体：tvec 亚族（共享核 IS_TVEC=1），无 trap 装载口（golden 端口表现读）。
// 机制：{base[63:2], mode[1:0]} 各一个寄存器，异步复位 0；软件写（w_wen）时
//   base 直通 w_wdata[63:2]，mode 是 WARL 字段只收 Direct(0)/Vectored(1)，
//   非法编码（2/3）丢弃 mode 保持旧值、base 同拍照写；rdata = {addr, mode}，
//   regOut_mode/regOut_addr 是供 NewCSR 内部直读的视图。
// 核体见 rtl/backend/xs_CsrEpcTvec_core.sv（epc/tvec 两亚族共用一份）。
// wrapper 端口表与 u_core 连线由 scripts/gen_csrepctvec_leaves7.py 生成（GENERATED 区）。
// =============================================================================

// BEGIN GENERATED(csrepctvec-leaves7)
module VStvecModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [1:0]  regOut_mode,
  output [61:0] regOut_addr
);

  xs_CsrEpcTvec_core #(
    .IS_TVEC (1'b1)
  ) u_core (
    .clock      (clock),
    .reset      (reset),
    .wen        (w_wen),
    .wdata      (w_wdata),
    .trap_valid (1'b0),
    .trap_epc   (63'h0),
    .rdata      (rdata),
    .epc        (),
    .mode       (regOut_mode),
    .addr       (regOut_addr)
  );
endmodule
// END GENERATED
