// xs_CsrTrapValue_core.sv —— CSR trap 原因/陷阱值寄存器族的共享核（无 wrapper）。
// 使用者：Mcause/Scause/VScause/Mncause（cause 亚族）与 Mtval/Stval/VStval/
// Mtval2（tval 亚族）共 8 个 golden 变体的薄文件，父模块是 NewCSR。
// 机制：一个 64 位寄存器，异步复位到 0；只要「软件写 w_wen」或「trap 装载
// trap_valid」任一成立就更新。两路同拍时新值是两路数据的**按位或**
// （golden 原文即 (trap_valid ? trap_wdata : 0) | (w_wen ? wdata : 0)，
// 是 OR 合并而不是优先级选择，重写必须照搬这一合并语义）。
// cause 亚族把寄存器值切成 {Interrupt[63], ExceptionCode[62:0]} 两个字段、
// trap 装载值由薄文件拼接；tval 亚族整 64 位直通 —— 两亚族的更新逻辑逐位
// 相同，所以共用本核，字段切割/拼装在各自薄文件里做，核体零复制。
module xs_CsrTrapValue_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        wen,         // 软件写使能（CSR 写口）
  input  logic [63:0] wdata,       // 软件写数据
  input  logic        trap_valid,  // trap 装载使能（trap 时硬件写入）
  input  logic [63:0] trap_wdata,  // trap 装载值（cause 变体由薄文件拼成 {Interrupt, ExceptionCode}）
  output logic [63:0] value        // 寄存器当前值（rdata 与各 regOut 字段都从这里切）
);

  logic [63:0] value_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      value_q <= 64'h0;
    end
    else if (wen | trap_valid) begin
      // 写使能是「软件写 或 trap 装载」；同拍竞争时两路按位或合并。
      value_q <= (trap_valid ? trap_wdata : 64'h0)
               | (wen        ? wdata      : 64'h0);
    end
  end

  assign value = value_q;

endmodule
