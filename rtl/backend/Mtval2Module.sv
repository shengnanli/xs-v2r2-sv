// Mtval2Module.sv —— machine trap value 2 CSR（mtval2）：进入 M 态 trap 时由
// 硬件装载补充 trap 信息（如 guest 缺页的 GPA），与 mtval 配套。
// trap 口 trapToM_mtval2_* 在 trap 时装载；软件口 w_wen/w_wdata 可写整 64 位；
// 两路同拍按位或合并（见共享核）。输出 rdata 与 regOut_ALL 都是整 64 位
// 寄存器的镜像。寄存器本体在共享核 xs_CsrTrapValue_core（异步复位到 0），
// 本文件只做端口改名；golden 同名 wrapper 由
// scripts/gen_csrtrapvalue_leaves8.py 生成（GENERATED 标记区，勿手改）。
module xs_Mtval2Module_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        wen,
  input  logic [63:0] wdata,
  input  logic        trap_valid,
  input  logic [63:0] trap_tval,
  output logic [63:0] rdata,
  output logic [63:0] reg_all
);

  logic [63:0] value;

  xs_CsrTrapValue_core u_value (
    .clock      (clock),
    .reset      (reset),
    .wen        (wen),
    .wdata      (wdata),
    .trap_valid (trap_valid),
    .trap_wdata (trap_tval),
    .value      (value)
  );

  assign rdata   = value;
  assign reg_all = value;

endmodule

// BEGIN GENERATED(csrtrapvalue-leaves8)
module Mtval2Module (
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input logic trapToM_mtval2_valid,
  input logic [63:0] trapToM_mtval2_bits_ALL
);

  xs_Mtval2Module_core u_core (
    .clock              (clock),
    .reset              (reset),
    .wen                (w_wen),
    .wdata              (w_wdata),
    .rdata              (rdata),
    .reg_all            (regOut_ALL),
    .trap_valid         (trapToM_mtval2_valid),
    .trap_tval          (trapToM_mtval2_bits_ALL)
  );

endmodule
// END GENERATED
