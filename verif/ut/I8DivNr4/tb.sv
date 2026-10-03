// =============================================================================
// tb —— I8DivNr4（8 位非恢复余数整数除法器）UT
//
// golden I8DivNr4 与重写 I8DivNr4_xs 双例化，由 div_lane（../SRT16IterBlocks/div_lane.sv）
// 驱动真实除法：逐拍对拍（valid 两侧相等、valid 时商/余数全位相等）+ 每次输出握手
// 对照独立 oracle（RISC-V 语义：除零 → 商全 1、余数 = 被除数；-128 / -1 → 商 -128、
// 余数 0；其余向零截断）。I8DivNr4 没有 sew 端口（固定 SEW=8），车道 MAXSEW=0。
// 激励：角落值（0、±1、±127/-128、2 的幂、小数、前导零随机）与全随机混合、
// sign 随机、flush 低概率注入、out_ready 随机反压、忙时乱拉 in_valid。
// 判据：errors=0 且车道完成 >= 5000 次除法才打印 TEST PASSED。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;

  logic       rst, sign, flush, in_valid, out_ready;
  logic [7:0] dividend, divisor;
  logic [1:0] sew;                       // 车道产出，I8DivNr4 无此端口
  wire        g_valid, i_valid;
  wire  [7:0] g_q, g_rem, i_q, i_rem;

  div_lane #(.WIDTH(8), .MAXSEW(0), .NAME("I8DivNr4"), .HAS_SEW(0)) u_lane (
    .clk(clk), .rst(rst), .sign(sign), .dividend(dividend), .divisor(divisor),
    .flush(flush), .sew(sew), .in_valid(in_valid), .out_ready(out_ready),
    .g_valid(g_valid), .g_q(g_q), .g_rem(g_rem),
    .i_valid(i_valid), .i_q(i_q), .i_rem(i_rem));

  I8DivNr4 u_g (
    .clock(clk), .reset(rst), .io_sign(sign), .io_dividend(dividend), .io_divisor(divisor),
    .io_flush(flush), .io_div_in_valid(in_valid), .io_div_out_ready(out_ready),
    .io_div_out_valid(g_valid), .io_div_out_q(g_q), .io_div_out_rem(g_rem));
  I8DivNr4_xs u_i (
    .clock(clk), .reset(rst), .io_sign(sign), .io_dividend(dividend), .io_divisor(divisor),
    .io_flush(flush), .io_div_in_valid(in_valid), .io_div_out_ready(out_ready),
    .io_div_out_valid(i_valid), .io_div_out_q(i_q), .io_div_out_rem(i_rem));

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    repeat (NCYCLES) @(posedge clk);
    @(negedge clk);
    u_lane.report();
    $display("I8DivNr4: checks=%0d oracle_checks=%0d errors=%0d",
             u_lane.cmp_checks, u_lane.oracle_checks, u_lane.errors);
    if (u_lane.errors == 0 && u_lane.ops_done >= 5000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
