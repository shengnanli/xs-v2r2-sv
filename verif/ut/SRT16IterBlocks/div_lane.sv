// =============================================================================
// div_lane —— 整数除法器 UT 的「一条车道」：激励 + 独立 oracle + 双例化比对
//
// 被测对是同一个除法器顶层的两份：golden 原件（g_*）与「换上重写件」的那份（i_*）。
//   · SRT16IterBlocks：golden SRT16Divint{,_4,_6} vs 同一 golden 父级、但其中
//     IterBlock_v4* 子树换成重写件（ut_gen/subst_*.sv，见 Makefile）；
//   · I8DivNr4：golden I8DivNr4 vs 重写 I8DivNr4_xs。
// 判据两条，缺一不可：
//   (1) 逐拍：out_valid 两侧相等；valid 时商/余数全位相等（golden 对拍）；
//   (2) 每次输出握手：商/余数低 n 位（n = 8<<sew）等于**独立 oracle**——按 RISC-V
//       整数除法语义直接用 SV 的 / 与 % 算：除零 → 商全 1、余数 = 被除数；
//       有符号最小值 / -1 → 商 = 最小值、余数 0；其余向零截断。oracle 不看 golden。
// 激励：被除数/除数从角落值表（0、±1、最大/最小、2 的幂、小数、前导零随机）与
//   全随机混合抽取；sign 随机；sew 主要取本车道合法值（00..MAXSEW），少量取越界值
//   （只做对拍，不做 oracle）；flush 在忙时低概率注入（作废当前操作）；out_ready
//   随机反压；忙时随机拉 in_valid（应被忽略）。操作数在一次除法期间保持不变
//   （与 VectorIdiv 用 x_reg/d_reg 喂除法器一致）。
// 驱动在下降沿、采样在下降沿（寄存器输出在上升沿后已稳定）。
// =============================================================================
`timescale 1ns/1ps
module div_lane #(
  parameter int    WIDTH  = 16,
  parameter int    MAXSEW = 1,      // 本车道合法 sew 的上限（8<<sew <= WIDTH）
  parameter string NAME   = "lane",
  parameter bit    HAS_SEW = 1      // 0 = DUT 没有 sew 端口（I8DivNr4），不发越界 sew
) (
  input  logic             clk,
  output logic             rst,
  output logic             sign,
  output logic [WIDTH-1:0] dividend,
  output logic [WIDTH-1:0] divisor,
  output logic             flush,
  output logic [1:0]       sew,
  output logic             in_valid,
  output logic             out_ready,
  input  logic             g_valid,
  input  logic [WIDTH-1:0] g_q,
  input  logic [WIDTH-1:0] g_rem,
  input  logic             i_valid,
  input  logic [WIDTH-1:0] i_q,
  input  logic [WIDTH-1:0] i_rem
);
  longint errors = 0, cmp_checks = 0, oracle_checks = 0;
  // 覆盖计数
  longint ops_started = 0, ops_done = 0, ops_flushed = 0, ops_badsew = 0;
  longint by_sew [4] = '{0, 0, 0, 0};
  longint c_signed = 0, c_dzero = 0, c_ovf = 0, c_negx = 0, c_negd = 0, c_xltd = 0,
          c_xzero = 0, c_qneg = 0, c_remnz = 0, c_backpressure = 0, c_ignored_valid = 0;

  bit   busy = 0, dut_idle = 0, pend_idle = 0, op_badsew = 0;
  int   cyc = 0;
  logic [63:0] exp_q, exp_r, mask;

  // --------------------------------------------------------------------------
  // 独立 oracle（RISC-V M 扩展语义）
  // --------------------------------------------------------------------------
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
      if (sx == smin && sd == -1) begin
        q = xm; r = 0;
      end else begin
        q = 64'(sx / sd) & m; r = 64'(sx % sd) & m;
      end
    end
  endtask

  // --------------------------------------------------------------------------
  // 角落值操作数（n 位有效，其余高位随机垃圾——DUT 必须按 sew 忽略它们）
  // --------------------------------------------------------------------------
  function automatic logic [63:0] rnd64();
    return {$urandom, $urandom};
  endfunction
  function automatic logic [63:0] corner(int n, bit is_divisor);
    logic [63:0] m = nmask(n), v;
    case ($urandom_range(0, 13))
      0:  v = 0;
      1:  v = 1;
      2:  v = m;                                  // -1 / 全 1
      3:  v = 64'd1 << (n - 1);                   // 有符号最小值
      4:  v = (64'd1 << (n - 1)) - 1;             // 有符号最大值
      5:  v = 64'd1 << $urandom_range(0, n - 1);  // 2 的幂
      6:  v = $urandom_range(0, 15);              // 小数
      7:  v = m - $urandom_range(0, 15);          // 小负数
      8:  v = rnd64() >> $urandom_range(0, 63);   // 随机前导零
      9:  v = is_divisor ? 2 : 3;
      default: v = rnd64();
    endcase
    return v & m;
  endfunction

  task automatic start_op();
    int  n;
    logic [63:0] x, d, junk_x, junk_d;
    op_badsew = 0;
    if (HAS_SEW && MAXSEW < 3 && $urandom_range(0, 19) == 0) begin   // 5%：越界 sew，只对拍
      sew = 2'($urandom_range(MAXSEW + 1, 3));
      op_badsew = 1;
      ops_badsew++;
    end else begin
      sew = 2'($urandom_range(0, MAXSEW));
    end
    n    = 8 << (op_badsew ? MAXSEW : sew);
    sign = $urandom_range(0, 1);
    x = corner(n, 0);
    d = corner(n, 1);
    if (sign && $urandom_range(0, 24) == 0) begin           // 4%：最小值 / -1 溢出
      x = 64'd1 << (n - 1);
      d = nmask(n);
    end
    junk_x = rnd64(); junk_d = rnd64();
    dividend = WIDTH'((junk_x & ~nmask(n)) | x);
    divisor  = WIDTH'((junk_d & ~nmask(n)) | d);
    in_valid = 1;
    busy     = 1;
    dut_idle = 0;
    ops_started++;
  endtask

  task automatic account_and_check();
    int n = 8 << sew;
    logic [63:0] m = nmask(n);
    logic [63:0] x = 64'(dividend) & m, d = 64'(divisor) & m;
    oracle(n, sign, x, d, exp_q, exp_r);
    oracle_checks++;
    if ((64'(g_q) & m) !== exp_q || (64'(g_rem) & m) !== exp_r) begin
      errors++;
      if (errors <= 10)
        $display("[%s] ORACLE MISMATCH cyc=%0d sew=%0d sign=%0b x=%h d=%h : golden q=%h r=%h  exp q=%h r=%h",
                 NAME, cyc, sew, sign, x, d, 64'(g_q) & m, 64'(g_rem) & m, exp_q, exp_r);
    end
    ops_done++;
    by_sew[sew]++;
    if (sign) c_signed++;
    if (d == 0) c_dzero++;
    if (x == 0) c_xzero++;
    if (sign && x == (64'd1 << (n - 1)) && d == m) c_ovf++;
    if (sign && x[n-1]) c_negx++;
    if (sign && d[n-1]) c_negd++;
    if (exp_q[n-1] && sign) c_qneg++;
    if (exp_r != 0) c_remnz++;
    if (sign ? ((x[n-1] ? -sext(x, n) : sext(x, n)) < (d[n-1] ? -sext(d, n) : sext(d, n)))
             : (x < d)) c_xltd++;
  endtask

  initial begin
    rst = 1; sign = 0; dividend = '0; divisor = '0; flush = 0; sew = 0;
    in_valid = 0; out_ready = 0;
    repeat (4) @(negedge clk);
    rst = 0;
    dut_idle = 1;
    forever begin
      @(negedge clk);
      cyc++;
      // ---- 对拍（golden vs 重写）----
      cmp_checks++;
      if (g_valid !== i_valid || (g_valid && (g_q !== i_q || g_rem !== i_rem))) begin
        errors++;
        if (errors <= 10)
          $display("[%s] DUAL MISMATCH cyc=%0d valid g=%b i=%b q g=%h i=%h rem g=%h i=%h",
                   NAME, cyc, g_valid, i_valid, g_q, i_q, g_rem, i_rem);
      end
      // ---- 上一个下降沿驱动的控制在刚过去的上升沿已生效；先把一拍脉冲撤掉 ----
      flush    = 0;
      in_valid = 0;
      // ---- 输出握手：先定下本拍要驱动的 out_ready，再判 valid && ready ⇒ 下一个上升沿完成 ----
      // （★先抽 ready 再判★：下一个上升沿采到的是**现在**驱动的值。早先版本用上一拍的
      //   ready 判握手，与 DUT 实际握手错一拍——会漏判/错判握手、让车道与 DUT 失步，
      //   2026-10-03 VectorIdiv UT 暴露后修正。）
      out_ready = ($urandom_range(0, 9) < 6);
      if (g_valid && out_ready && busy) begin
        if (!op_badsew) account_and_check();
        busy = 0;
        pend_idle = 1;           // 握手那一个上升沿之后 DUT 才回 IDLE
      end else if (g_valid && !out_ready) begin
        c_backpressure++;
      end
      // ---- 发起 / 冲刷 / 忙时乱拉 in_valid ----
      if (busy && !(g_valid && out_ready) && $urandom_range(0, 299) == 0) begin
        flush = 1; busy = 0; pend_idle = 1; ops_flushed++;
      end else if (dut_idle && !busy) begin
        if ($urandom_range(0, 9) < 8) start_op();
      end else if (busy && $urandom_range(0, 9) == 0) begin
        in_valid = 1;            // DUT 不在 IDLE，应被忽略
        c_ignored_valid++;
      end
      if (pend_idle) begin dut_idle = 1; pend_idle = 0; end
    end
  end

  function automatic void report();
    $display("[%s] cmp_checks=%0d oracle_checks=%0d errors=%0d | started=%0d done=%0d flushed=%0d badsew=%0d",
             NAME, cmp_checks, oracle_checks, errors, ops_started, ops_done, ops_flushed, ops_badsew);
    $display("[%s] cover: sew0=%0d sew1=%0d sew2=%0d sew3=%0d signed=%0d dzero=%0d xzero=%0d ovf(min/-1)=%0d negx=%0d negd=%0d qneg=%0d remnz=%0d |x|<|d|=%0d backpressure=%0d ignored_in_valid=%0d",
             NAME, by_sew[0], by_sew[1], by_sew[2], by_sew[3], c_signed, c_dzero, c_xzero, c_ovf,
             c_negx, c_negd, c_qneg, c_remnz, c_xltd, c_backpressure, c_ignored_valid);
  endfunction
endmodule
