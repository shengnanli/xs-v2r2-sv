// =============================================================================
// fp64_misc_oracle_pkg —— f64 非加法类指令的独立 oracle（只给 tb 用，不进 RTL、不进 FM）
//
// 用于 verif/ut/FloatAdderF64Pipeline 与 verif/ut/FloatAdderF64WidenPipeline。纯按 IEEE 754 / RISC-V F/D/Zfa
// 语义写，与被测电路没有共享代码：
//   - 分类：NaN / sNaN（尾数最高位 0）/ Inf / 零 / 非规格数；
//   - 比较：-0 == +0；有限数与 Inf 按「符号 + 63 位幅值」整数比较（IEEE 的位模式单调性）；
//   - minNum/maxNum（fmin/fmax：一个 NaN 取另一个，两个 NaN 给 canonical NaN，-0 < +0）；
//     minimum/maximum（Zfa fminm/fmaxm：有 NaN 即 canonical NaN）；
//   - fclass 10 位独热（bit0 = -Inf … bit9 = qNaN）。
// 加减的舍入由 verif/ut/FpAddPathF64W/fp_add_oracle_pkg.sv 的 exact_add 负责。
// =============================================================================
package fp64_misc_oracle_pkg;
  localparam logic [63:0] QNAN64 = 64'h7FF8_0000_0000_0000;

  function automatic bit is_nan (input logic [63:0] x); return (&x[62:52]) && (x[51:0] != 0); endfunction
  function automatic bit is_snan(input logic [63:0] x); return is_nan(x) && !x[51];             endfunction
  function automatic bit is_inf (input logic [63:0] x); return (&x[62:52]) && (x[51:0] == 0); endfunction
  function automatic bit is_zero(input logic [63:0] x); return x[62:0] == 0;                     endfunction
  function automatic bit is_sub (input logic [63:0] x); return (x[62:52] == 0) && (x[51:0] != 0); endfunction

  // a < b（两者都不是 NaN）
  function automatic bit f_lt(input logic [63:0] a, input logic [63:0] b);
    if (is_zero(a) && is_zero(b)) return 0;
    if (a[63] != b[63]) return a[63];
    if (!a[63]) return a[62:0] < b[62:0];
    return a[62:0] > b[62:0];
  endfunction
  function automatic bit f_eq(input logic [63:0] a, input logic [63:0] b);
    if (is_zero(a) && is_zero(b)) return 1;
    return a == b;
  endfunction

  // minNum / maxNum（fmin / fmax）
  function automatic logic [63:0] f_minmax(input logic [63:0] a, input logic [63:0] b, input bit want_max);
    if (is_nan(a) && is_nan(b)) return QNAN64;
    if (is_nan(a)) return b;
    if (is_nan(b)) return a;
    if (is_zero(a) && is_zero(b)) return want_max ? (a[63] ? b : a) : (a[63] ? a : b);
    if (want_max) return f_lt(a, b) ? b : a;
    return f_lt(b, a) ? b : a;
  endfunction
  // minimum / maximum（fminm / fmaxm）
  function automatic logic [63:0] f_minmaxm(input logic [63:0] a, input logic [63:0] b, input bit want_max);
    if (is_nan(a) || is_nan(b)) return QNAN64;
    return f_minmax(a, b, want_max);
  endfunction

  function automatic logic [9:0] f_class(input logic [63:0] a);
    logic [9:0] c = '0;
    if (is_nan(a))       c[a[51] ? 9 : 8] = 1;
    else if (is_inf(a))  c[a[63] ? 0 : 7] = 1;
    else if (is_zero(a)) c[a[63] ? 3 : 4] = 1;
    else if (is_sub(a))  c[a[63] ? 2 : 5] = 1;
    else                 c[a[63] ? 1 : 6] = 1;
    return c;
  endfunction
endpackage
