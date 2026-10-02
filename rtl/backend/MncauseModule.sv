// MncauseModule.sv —— RNMI cause CSR（mncause，Smrnmi 扩展）：记录进入
// 可恢复 NMI 的 trap 原因。布局：bit63 = Interrupt（1=中断，0=同步异常），
// bit62:0 = ExceptionCode。trap 口 trapToMN_mncause_* 在 trap 时装载
// {Interrupt, ExceptionCode}；软件口 w_wen/w_wdata 可写整 64 位；
// 两路同拍按位或合并（见共享核）。输出 rdata 是拼回的 64 位读视图，
// regOut_Interrupt/regOut_ExceptionCode 是分字段镜像。寄存器本体在共享核
// xs_CsrTrapValue_core（异步复位到 0），本文件只做字段拼装/切割；
// golden 同名 wrapper 由 scripts/gen_csrtrapvalue_leaves8.py 生成
// （GENERATED 标记区，勿手改）。
module xs_MncauseModule_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        wen,
  input  logic [63:0] wdata,
  input  logic        trap_valid,
  input  logic        trap_interrupt,
  input  logic [62:0] trap_exception_code,
  output logic [63:0] rdata,
  output logic        reg_interrupt,
  output logic [62:0] reg_exception_code
);

  logic [63:0] value;

  xs_CsrTrapValue_core u_value (
    .clock      (clock),
    .reset      (reset),
    .wen        (wen),
    .wdata      (wdata),
    .trap_valid (trap_valid),
    .trap_wdata ({trap_interrupt, trap_exception_code}),
    .value      (value)
  );

  assign rdata              = value;
  assign reg_interrupt      = value[63];
  assign reg_exception_code = value[62:0];

endmodule

// BEGIN GENERATED(csrtrapvalue-leaves8)
module MncauseModule (
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_Interrupt,
  output logic [62:0] regOut_ExceptionCode,
  input logic trapToMN_mncause_valid,
  input logic trapToMN_mncause_bits_Interrupt,
  input logic [62:0] trapToMN_mncause_bits_ExceptionCode
);

  xs_MncauseModule_core u_core (
    .clock              (clock),
    .reset              (reset),
    .wen                (w_wen),
    .wdata              (w_wdata),
    .rdata              (rdata),
    .reg_interrupt      (regOut_Interrupt),
    .reg_exception_code (regOut_ExceptionCode),
    .trap_valid         (trapToMN_mncause_valid),
    .trap_interrupt     (trapToMN_mncause_bits_Interrupt),
    .trap_exception_code(trapToMN_mncause_bits_ExceptionCode)
  );

endmodule
// END GENERATED
