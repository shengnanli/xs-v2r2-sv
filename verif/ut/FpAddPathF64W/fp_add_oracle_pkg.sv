// =============================================================================
// fp_add_oracle_pkg —— 浮点加减的独立 IEEE 754 oracle（只给 tb 用，不进 RTL、不进 FM）
//
// 用于 verif/ut/FpAddPathF64W（f64 close path）与 verif/ut/FloatAdderF32F16MixedPipeline
// （f32/f16 加减）。只用整数算术，与被测电路没有任何共享代码：
//   1. 两个有限数（含 ±0、非规格数）按各自有效指数对齐成大整数（指数差超过 P+3 时，小数只留一个
//      "粘滞 1"——它严格小于大数的半个 guard 位，对五种舍入都不改变结果）；
//   2. 按符号做精确加 / 减；
//   3. 规格化到 P 位有效数（或非规格数的下限），按 RNE/RTZ/RDN/RUP/RMM 舍入，判 NX / OF。
// 精确为 0 的结果：两数同号取该符号，异号取 (rm==RDN)（IEEE 754 §6.3）。
// 加法的 UF 恒为 0：加法的非规格数结果总是精确的（RISC-V 的 UF 要求 tiny 且 inexact）。
// =============================================================================
package fp_add_oracle_pkg;

  localparam int BIGW = 128;           // P <= 53，对齐量 <= P+3：53+56+1 < 128

  typedef struct packed {
    logic [63:0] bits;                 // 结果（本格式，右对齐：{sign, exp, mant}）
    logic        nx;
    logic        of;
  } fp_res_t;

  // 有限数 a + b（b 的符号已按 is_sub 处理好），P = 含隐含位的有效数位数，EW = 指数位数
  function automatic fp_res_t exact_add(input int P, input int EW,
                                        input logic sa, input logic [10:0] ea, input logic [51:0] ma,
                                        input logic sb, input logic [10:0] eb, input logic [51:0] mb,
                                        input logic [2:0] rm);
    fp_res_t r;
    logic [BIGW-1:0] siga, sigb, sig_big, sig_small, A, B, M;
    int Ea, Eb, Ebig, d, D, Emin, msb, sh, emax;
    logic sbig, ssmall, sign, rbit, sticky, up, inexact;
    logic [BIGW-1:0] q;
    int e_field;
    emax = (1 << EW) - 1;
    Ea   = (ea == 0) ? 1 : int'(ea);
    Eb   = (eb == 0) ? 1 : int'(eb);
    siga = BIGW'(ma) | ((ea != 0) ? (BIGW'(1) << (P - 1)) : '0);
    sigb = BIGW'(mb) | ((eb != 0) ? (BIGW'(1) << (P - 1)) : '0);
    if (Ea >= Eb) begin
      sig_big = siga; sig_small = sigb; sbig = sa; ssmall = sb; Ebig = Ea; d = Ea - Eb;
    end else begin
      sig_big = sigb; sig_small = siga; sbig = sb; ssmall = sa; Ebig = Eb; d = Eb - Ea;
    end
    D    = (d > P + 3) ? P + 3 : d;
    A    = sig_big << D;
    B    = (d > P + 3) ? BIGW'(sig_small != 0) : sig_small;
    Emin = Ebig - D;
    // 精确和
    if (sbig == ssmall) begin
      M = A + B; sign = sbig;
    end else if (A > B) begin
      M = A - B; sign = sbig;
    end else if (B > A) begin
      M = B - A; sign = ssmall;
    end else begin
      M = '0; sign = 0;
    end
    r.nx = 0; r.of = 0;
    if (M == 0) begin
      sign = (sa == sb) ? sa : (rm == 3'd2);
      r.bits = 64'(sign) << (EW + P - 1);
      return r;
    end
    msb = 0;
    for (int i = 0; i < BIGW; i++) if (M[i]) msb = i;
    sh = msb - (P - 1);
    if (Emin + sh < 1) sh = 1 - Emin;          // 非规格数：指数钉在下限
    if (sh <= 0) begin
      q = M << (-sh); rbit = 0; sticky = 0;
    end else begin
      q      = M >> sh;
      rbit   = M[sh - 1];
      sticky = (sh >= 2) ? |(M & ((BIGW'(1) << (sh - 1)) - 1)) : 1'b0;
    end
    inexact = rbit | sticky;
    case (rm)
      3'd0:    up = rbit & (sticky | q[0]);    // RNE
      3'd2:    up = inexact & sign;            // RDN
      3'd3:    up = inexact & ~sign;           // RUP
      3'd4:    up = rbit;                      // RMM
      default: up = 0;                         // RTZ
    endcase
    q = q + BIGW'(up);
    if (q == (BIGW'(1) << P)) begin q = q >> 1; sh = sh + 1; end
    e_field = q[P - 1] ? Emin + sh : 0;
    r.nx = inexact;
    if (e_field >= emax) begin                 // 上溢：inf 或最大有限数
      r.of = 1; r.nx = 1;
      if (rm == 3'd1 || (rm == 3'd2 && !sign) || (rm == 3'd3 && sign))
        r.bits = (64'(sign) << (EW + P - 1)) | (64'(emax - 1) << (P - 1)) | ((64'(1) << (P - 1)) - 1);
      else
        r.bits = (64'(sign) << (EW + P - 1)) | (64'(emax) << (P - 1));
      return r;
    end
    r.bits = (64'(sign) << (EW + P - 1)) | (64'(e_field) << (P - 1)) | 64'(q & ((BIGW'(1) << (P - 1)) - 1));
    return r;
  endfunction

endpackage
