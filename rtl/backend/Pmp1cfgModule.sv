// Pmp1cfgModule.sv —— NewCSR 的 PMP 配置条目 1（pmpcfg 寄存器字节 1）薄 wrapper
// 位置：父模块 NewCSR 的 pmpcfgs 序列第 1 项；条目索引只体现在模块名与父模块的
//   地址译码上。五个变体 Pmp0..4cfgModule 的 golden 去模块名后逐字节相同（已 diff
//   核实，生成器每次重跑都会再断言一次），故全族共用无参数核，本文件只做端口名转接。
// 核体见 rtl/backend/xs_Pmpcfg_core.sv（WARL：A 写 2 落 3；R=0 且 W=1 时 W 不更新；
//   异步复位清 0；rdata = {L, 2'b0, A, X, W, R}）。
// 端口表在 BEGIN/END GENERATED 区内，由 scripts/gen_pmpcfg_leaves5.py 生成，勿手改。
module Pmp1cfgModule (
// BEGIN GENERATED(pmpcfg_wrapper)
  input  logic         clock,
  input  logic         reset,
  input  logic         w_wen,
  input  logic [63:0]  w_wdata,
  output logic [7:0]   rdata,
  output logic         regOut_R,
  output logic         regOut_W,
  output logic         regOut_X,
  output logic [1:0]   regOut_A,
  output logic         regOut_L
// END GENERATED
);
  xs_Pmpcfg_core u_core (
    .clk     (clock),
    .rst     (reset),
    .wr_en   (w_wen),
    .wr_data (w_wdata),
    .rd_data (rdata),
    .cfg_r   (regOut_R),
    .cfg_w   (regOut_W),
    .cfg_x   (regOut_X),
    .cfg_a   (regOut_A),
    .cfg_l   (regOut_L)
  );
endmodule
