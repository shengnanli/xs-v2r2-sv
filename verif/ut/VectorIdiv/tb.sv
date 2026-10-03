// =============================================================================
// tb —— VectorIdiv（128 位向量整数除法单元）UT
//
// golden VectorIdiv 与重写 VectorIdiv_xs（整棵子树都是重写件）双例化：
//   (1) 逐拍对拍：in_ready / out_valid 两侧相等；out_valid 时 128 位商、余数全位相等；
//   (2) 每次输出握手按 SEW 分元素对照独立 oracle（元素宽 n = 8<<sew，共 128/n 个元素，
//       逐元素用 RISC-V 语义算商/余数：除零 → 商全 1、余数 = 被除数；最小值 / -1 →
//       商 = 最小值、余数 0；其余向零截断）。oracle 不看 golden。
// 激励：sew 四档均匀、sign 随机；每个元素独立从角落值表（0、±1、最大/最小、2 的幂、小数、
//   前导零随机）与全随机中抽，另有 4% 的向量把一半元素设成最小值 / -1。握手之后输入口
//   立刻换成随机垃圾（DUT 必须已锁存）；忙时随机拉 in_valid（应被忽略）、out_ready 随机反压、
//   低概率 flush（作废当前操作）。
// 判据：errors=0 且完成 >= 3000 条向量（每档 sew 都 >= 500）才打印 TEST PASSED。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;

  logic         rst, sign, flush, in_valid, out_ready;
  logic [1:0]   sew;
  logic [127:0] dividend_v, divisor_v;
  wire          g_in_ready, i_in_ready, g_out_valid, i_out_valid;
  wire  [127:0] g_q, g_rem, i_q, i_rem;

  VectorIdiv u_g (
    .clock(clk), .reset(rst), .io_sew(sew), .io_sign(sign), .io_dividend_v(dividend_v),
    .io_divisor_v(divisor_v), .io_flush(flush), .io_div_in_valid(in_valid),
    .io_div_in_ready(g_in_ready), .io_div_out_ready(out_ready), .io_div_out_valid(g_out_valid),
    .io_div_out_q_v(g_q), .io_div_out_rem_v(g_rem));
  VectorIdiv_xs u_i (
    .clock(clk), .reset(rst), .io_sew(sew), .io_sign(sign), .io_dividend_v(dividend_v),
    .io_divisor_v(divisor_v), .io_flush(flush), .io_div_in_valid(in_valid),
    .io_div_in_ready(i_in_ready), .io_div_out_ready(out_ready), .io_div_out_valid(i_out_valid),
    .io_div_out_q_v(i_q), .io_div_out_rem_v(i_rem));

  longint errors = 0, cmp_checks = 0, elem_checks = 0;
  longint ops_started = 0, ops_done = 0, ops_flushed = 0;
  longint by_sew [4] = '{0, 0, 0, 0};
  longint c_dzero = 0, c_ovf = 0, c_negx = 0, c_negd = 0, c_signed_elems = 0, c_remnz = 0,
          c_backpressure = 0, c_ignored_valid = 0;

  // ---------------- 独立 oracle（与 SRT16IterBlocks/div_lane.sv 同语义）----------------
  function automatic logic [63:0] nmask(int n);
    return (n >= 64) ? 64'hFFFF_FFFF_FFFF_FFFF : ((64'd1 << n) - 64'd1);
  endfunction
  function automatic longint sext(logic [63:0] v, int n);
    logic [63:0] s = v << (64 - n);
    return longint'($signed(s)) >>> (64 - n);
  endfunction
  task automatic oracle(input int n, input bit sgn, input logic [63:0] x, input logic [63:0] d,
                        output logic [63:0] q, output logic [63:0] r);
    logic [63:0] m = nmask(n);
    logic [63:0] xm = x & m, dm = d & m;
    if (dm == 0) begin
      q = m; r = xm;
    end else if (!sgn) begin
      q = xm / dm; r = xm % dm;
    end else begin
      longint sx = sext(xm, n), sd = sext(dm, n);
      longint smin = (n >= 64) ? 64'sh8000_0000_0000_0000 : -(longint'(1) << (n - 1));
      if (sx == smin && sd == -1) begin q = xm; r = 0; end
      else begin q = 64'(sx / sd) & m; r = 64'(sx % sd) & m; end
    end
  endtask
  function automatic logic [63:0] corner(int n);
    logic [63:0] m = nmask(n), v;
    case ($urandom_range(0, 13))
      0:  v = 0;
      1:  v = 1;
      2:  v = m;
      3:  v = 64'd1 << (n - 1);
      4:  v = (64'd1 << (n - 1)) - 1;
      5:  v = 64'd1 << $urandom_range(0, n - 1);
      6:  v = $urandom_range(0, 15);
      7:  v = m - $urandom_range(0, 15);
      8:  v = {$urandom, $urandom} >> $urandom_range(0, 63);
      9:  v = 3;
      default: v = {$urandom, $urandom};
    endcase
    return v & m;
  endfunction

  // 当前操作（握手时锁定的副本，供 oracle 用）
  logic [1:0]   op_sew;
  logic         op_sign;
  logic [127:0] op_x, op_d;
  bit           busy = 0, pend_idle = 0;
  int           cyc = 0;

  task automatic start_op();
    int n;
    bit ovf_vec;
    op_sew  = 2'($urandom_range(0, 3));
    op_sign = $urandom_range(0, 1);
    n = 8 << op_sew;
    ovf_vec = op_sign && ($urandom_range(0, 24) == 0);
    for (int e = 0; e < 128 / n; e++) begin
      logic [63:0] x = corner(n), d = corner(n);
      if (ovf_vec && e[0]) begin x = 64'd1 << (n - 1); d = nmask(n); end
      for (int b = 0; b < n; b++) begin
        op_x[n*e + b] = x[b];
        op_d[n*e + b] = d[b];
      end
    end
    sew = op_sew; sign = op_sign; dividend_v = op_x; divisor_v = op_d;
    in_valid = 1;
    busy = 1;
    ops_started++;
  endtask

  task automatic check_result();
    int n = 8 << op_sew;
    logic [63:0] eq, er, gq, gr, x, d;
    for (int e = 0; e < 128 / n; e++) begin
      x = '0; d = '0; gq = '0; gr = '0;
      for (int b = 0; b < n; b++) begin
        x[b] = op_x[n*e + b]; d[b] = op_d[n*e + b];
        gq[b] = g_q[n*e + b]; gr[b] = g_rem[n*e + b];
      end
      oracle(n, op_sign, x, d, eq, er);
      elem_checks++;
      if (gq !== eq || gr !== er) begin
        errors++;
        if (errors <= 10)
          $display("ORACLE MISMATCH cyc=%0d sew=%0d sign=%0b elem=%0d x=%h d=%h : golden q=%h r=%h exp q=%h r=%h",
                   cyc, op_sew, op_sign, e, x, d, gq, gr, eq, er);
      end
      if (d == 0) c_dzero++;
      if (op_sign) begin
        c_signed_elems++;
        if (x[n-1]) c_negx++;
        if (d[n-1]) c_negd++;
        if (x == (64'd1 << (n - 1)) && d == nmask(n)) c_ovf++;
      end
      if (er != 0) c_remnz++;
    end
    ops_done++;
    by_sew[op_sew]++;
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; sign = 0; sew = 0; flush = 0; in_valid = 0; out_ready = 0;
    dividend_v = '0; divisor_v = '0;
    repeat (4) @(negedge clk);
    rst = 0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      @(negedge clk);
      cyc++;
      // ---- 对拍 ----
      cmp_checks++;
      if (g_in_ready !== i_in_ready || g_out_valid !== i_out_valid ||
          (g_out_valid && (g_q !== i_q || g_rem !== i_rem))) begin
        errors++;
        if (errors <= 10)
          $display("DUAL MISMATCH cyc=%0d ready g=%b i=%b valid g=%b i=%b q g=%h i=%h rem g=%h i=%h",
                   cyc, g_in_ready, i_in_ready, g_out_valid, i_out_valid, g_q, i_q, g_rem, i_rem);
      end
      // ---- 上一个下降沿的一拍脉冲撤掉；握手之后输入口换成垃圾 ----
      if (in_valid) begin
        dividend_v = {$urandom, $urandom, $urandom, $urandom};
        divisor_v  = {$urandom, $urandom, $urandom, $urandom};
        sew = 2'($urandom); sign = $urandom_range(0, 1);
      end
      flush = 0; in_valid = 0;
      // ---- 输出握手：先抽本拍驱动的 out_ready，再判 valid && ready ⇒ 下一个上升沿取走 ----
      out_ready = ($urandom_range(0, 9) < 6);
      if (g_out_valid && out_ready && busy) begin
        check_result();
        busy = 0; pend_idle = 1;
      end else if (g_out_valid && !out_ready) begin
        c_backpressure++;
      end
      // ---- 发起 / 冲刷 / 忙时乱拉 in_valid ----
      if (busy && !(g_out_valid && out_ready) && $urandom_range(0, 499) == 0) begin
        flush = 1; busy = 0; pend_idle = 1; ops_flushed++;
      end else if (!busy && !pend_idle && g_in_ready) begin
        if ($urandom_range(0, 9) < 8) start_op();
      end else if (busy && $urandom_range(0, 9) == 0) begin
        in_valid = 1;            // 不在 IDLE，应被忽略
        c_ignored_valid++;
      end
      pend_idle = 0;
    end
    @(negedge clk);
    $display("VectorIdiv: cmp_checks=%0d elem_checks=%0d errors=%0d | started=%0d done=%0d flushed=%0d",
             cmp_checks, elem_checks, errors, ops_started, ops_done, ops_flushed);
    $display("cover: sew0=%0d sew1=%0d sew2=%0d sew3=%0d dzero_elems=%0d signed_elems=%0d negx=%0d negd=%0d ovf(min/-1)=%0d remnz=%0d backpressure=%0d ignored_in_valid=%0d",
             by_sew[0], by_sew[1], by_sew[2], by_sew[3], c_dzero, c_signed_elems, c_negx, c_negd,
             c_ovf, c_remnz, c_backpressure, c_ignored_valid);
    if (errors == 0 && ops_done >= 3000 && by_sew[0] >= 500 && by_sew[1] >= 500 &&
        by_sew[2] >= 500 && by_sew[3] >= 500)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
