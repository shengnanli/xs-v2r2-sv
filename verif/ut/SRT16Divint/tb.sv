// =============================================================================
// tb —— SRT16Divint{,_4,_6} 整数除法器 UT
//
// 三个位宽各一对：golden 原件 vs 重写件（<名>_xs，整棵子树都是重写件），由 div_lane
// （../SRT16IterBlocks/div_lane.sv）跑真实除法：逐拍对拍（valid 两侧相等、valid 时商/余数
// 全位相等）+ 每次输出握手对照独立 oracle（RISC-V 语义：除零 → 商全 1、余数 = 被除数；
// 最小值 / -1 → 商 = 最小值、余数 0；其余向零截断），覆盖本车道全部合法 sew（00..MAXSEW）、
// 有/无符号、0/±1/最大/最小/2 的幂/前导零随机等角落值；越界 sew（5%）只做对拍。
// flush 低概率注入、out_ready 随机反压、忙时乱拉 in_valid（应被忽略）。
// 判据：三车道 errors 合计 0 且每车道完成 >= 5000 次除法才打印 TEST PASSED。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;

  // ---------------- SRT16Divint（16 位，sew 00..01）----------------
  logic        L16_rst, L16_sign, L16_flush, L16_in_valid, L16_out_ready;
  logic [15:0] L16_dividend, L16_divisor;
  logic [1:0]  L16_sew;
  wire         L16_g_valid, L16_i_valid;
  wire  [15:0] L16_g_q, L16_g_rem, L16_i_q, L16_i_rem;
  div_lane #(.WIDTH(16), .MAXSEW(1), .NAME("SRT16Divint")) u_lane16 (
    .clk(clk), .rst(L16_rst), .sign(L16_sign), .dividend(L16_dividend), .divisor(L16_divisor),
    .flush(L16_flush), .sew(L16_sew), .in_valid(L16_in_valid), .out_ready(L16_out_ready),
    .g_valid(L16_g_valid), .g_q(L16_g_q), .g_rem(L16_g_rem),
    .i_valid(L16_i_valid), .i_q(L16_i_q), .i_rem(L16_i_rem));
  SRT16Divint u_g_SRT16Divint (
    .clock(clk), .reset(L16_rst), .io_sign(L16_sign), .io_dividend(L16_dividend),
    .io_divisor(L16_divisor), .io_flush(L16_flush), .io_sew(L16_sew),
    .io_div_in_valid(L16_in_valid), .io_div_out_ready(L16_out_ready),
    .io_div_out_valid(L16_g_valid), .io_div_out_q(L16_g_q), .io_div_out_rem(L16_g_rem));
  SRT16Divint_xs u_i_SRT16Divint (
    .clock(clk), .reset(L16_rst), .io_sign(L16_sign), .io_dividend(L16_dividend),
    .io_divisor(L16_divisor), .io_flush(L16_flush), .io_sew(L16_sew),
    .io_div_in_valid(L16_in_valid), .io_div_out_ready(L16_out_ready),
    .io_div_out_valid(L16_i_valid), .io_div_out_q(L16_i_q), .io_div_out_rem(L16_i_rem));

  // ---------------- SRT16Divint_4（32 位，sew 00..10）----------------
  logic        L32_rst, L32_sign, L32_flush, L32_in_valid, L32_out_ready;
  logic [31:0] L32_dividend, L32_divisor;
  logic [1:0]  L32_sew;
  wire         L32_g_valid, L32_i_valid;
  wire  [31:0] L32_g_q, L32_g_rem, L32_i_q, L32_i_rem;
  div_lane #(.WIDTH(32), .MAXSEW(2), .NAME("SRT16Divint_4")) u_lane32 (
    .clk(clk), .rst(L32_rst), .sign(L32_sign), .dividend(L32_dividend), .divisor(L32_divisor),
    .flush(L32_flush), .sew(L32_sew), .in_valid(L32_in_valid), .out_ready(L32_out_ready),
    .g_valid(L32_g_valid), .g_q(L32_g_q), .g_rem(L32_g_rem),
    .i_valid(L32_i_valid), .i_q(L32_i_q), .i_rem(L32_i_rem));
  SRT16Divint_4 u_g_SRT16Divint_4 (
    .clock(clk), .reset(L32_rst), .io_sign(L32_sign), .io_dividend(L32_dividend),
    .io_divisor(L32_divisor), .io_flush(L32_flush), .io_sew(L32_sew),
    .io_div_in_valid(L32_in_valid), .io_div_out_ready(L32_out_ready),
    .io_div_out_valid(L32_g_valid), .io_div_out_q(L32_g_q), .io_div_out_rem(L32_g_rem));
  SRT16Divint_4_xs u_i_SRT16Divint_4 (
    .clock(clk), .reset(L32_rst), .io_sign(L32_sign), .io_dividend(L32_dividend),
    .io_divisor(L32_divisor), .io_flush(L32_flush), .io_sew(L32_sew),
    .io_div_in_valid(L32_in_valid), .io_div_out_ready(L32_out_ready),
    .io_div_out_valid(L32_i_valid), .io_div_out_q(L32_i_q), .io_div_out_rem(L32_i_rem));

  // ---------------- SRT16Divint_6（64 位，sew 00..11）----------------
  logic        L64_rst, L64_sign, L64_flush, L64_in_valid, L64_out_ready;
  logic [63:0] L64_dividend, L64_divisor;
  logic [1:0]  L64_sew;
  wire         L64_g_valid, L64_i_valid;
  wire  [63:0] L64_g_q, L64_g_rem, L64_i_q, L64_i_rem;
  div_lane #(.WIDTH(64), .MAXSEW(3), .NAME("SRT16Divint_6")) u_lane64 (
    .clk(clk), .rst(L64_rst), .sign(L64_sign), .dividend(L64_dividend), .divisor(L64_divisor),
    .flush(L64_flush), .sew(L64_sew), .in_valid(L64_in_valid), .out_ready(L64_out_ready),
    .g_valid(L64_g_valid), .g_q(L64_g_q), .g_rem(L64_g_rem),
    .i_valid(L64_i_valid), .i_q(L64_i_q), .i_rem(L64_i_rem));
  SRT16Divint_6 u_g_SRT16Divint_6 (
    .clock(clk), .reset(L64_rst), .io_sign(L64_sign), .io_dividend(L64_dividend),
    .io_divisor(L64_divisor), .io_flush(L64_flush), .io_sew(L64_sew),
    .io_div_in_valid(L64_in_valid), .io_div_out_ready(L64_out_ready),
    .io_div_out_valid(L64_g_valid), .io_div_out_q(L64_g_q), .io_div_out_rem(L64_g_rem));
  SRT16Divint_6_xs u_i_SRT16Divint_6 (
    .clock(clk), .reset(L64_rst), .io_sign(L64_sign), .io_dividend(L64_dividend),
    .io_divisor(L64_divisor), .io_flush(L64_flush), .io_sew(L64_sew),
    .io_div_in_valid(L64_in_valid), .io_div_out_ready(L64_out_ready),
    .io_div_out_valid(L64_i_valid), .io_div_out_q(L64_i_q), .io_div_out_rem(L64_i_rem));

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    repeat (NCYCLES) @(posedge clk);
    @(negedge clk);
    u_lane16.report();
    u_lane32.report();
    u_lane64.report();
    $display("SRT16Divint: errors=%0d oracle_checks=%0d",
             u_lane16.errors + u_lane32.errors + u_lane64.errors,
             u_lane16.oracle_checks + u_lane32.oracle_checks + u_lane64.oracle_checks);
    if (u_lane16.errors + u_lane32.errors + u_lane64.errors == 0 &&
        u_lane16.ops_done >= 5000 && u_lane32.ops_done >= 5000 && u_lane64.ops_done >= 5000)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
