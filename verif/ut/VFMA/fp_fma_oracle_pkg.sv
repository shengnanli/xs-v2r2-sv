// =============================================================================
// fp_fma_oracle_pkg —— 浮点乘加 / 乘法的独立 IEEE 754 oracle（只给 tb 用，不进 RTL、不进 FM）
//
// 用于 verif/ut/VFMA（以及以后要复用的向量 FMA 外壳 UT）。纯整数算术，与被测电路没有共享代码：
//   1. 解码：每个操作数按**它自己的格式**（f16 / f32 / f64）分类（NaN / sNaN / Inf / 零），有限数表示成 sig·2^e
//      —— 这个表示与格式无关，所以加宽指令（f16→f32、f32→f64）的源可以直接按源格式解码，不必先换格式；
//   2. 乘积 sig_a·sig_b 精确；与加数对齐时在 base = 最高位 − 400 处截断，截掉的位只留一个粘滞 1
//      （截掉部分严格小于结果舍入位的一半，对五种舍入方向都不改变结果）；
//   3. 规格化到结果格式的 P 位（或非规格数下限），按 RNE / RTZ / RDN / RUP / RMM 舍入（rm 5..7 按 RTZ）；
//      OF 上溢；UF = 舍入后判 tiny（RISC-V）且不精确；NX 不精确。
// 特殊值（RISC-V F/D/Zfh）：任一 NaN → canonical NaN（NV = 有 sNaN）；∞·0 → NaN + NV（即使加数是 qNaN 也置 NV）；
//   ∞ 乘积与反号 ∞ 加数 → NaN + NV；精确零：同号取该号，异号 RDN 取 −0、其余 +0；纯乘法的零取 sign_a ^ sign_b。
// =============================================================================
package fp_fma_oracle_pkg;

  typedef struct {
    bit          nan, snan, inf, zero, sign;
    logic [63:0] sig;          // 有效数（含隐含位）
    int          e;            // 最低位的指数：值 = sig · 2^e
  } fpv_t;

  // fmt：1 = f16，2 = f32，3 = f64（与向量 vsew 编码一致）
  function automatic int EWf(input logic [1:0] fmt); return (fmt == 1) ? 5 : (fmt == 2) ? 8 : 11; endfunction
  function automatic int MWf(input logic [1:0] fmt); return (fmt == 1) ? 10 : (fmt == 2) ? 23 : 52; endfunction

  function automatic fpv_t decode(input logic [63:0] x, input logic [1:0] fmt);
    fpv_t v;
    int ew = EWf(fmt), mw = MWf(fmt);
    longint unsigned E, M, emax;
    int bias = (1 << (ew - 1)) - 1;
    emax = (64'd1 << ew) - 1;
    E = (x >> mw) & emax;
    M = x & ((64'd1 << mw) - 1);
    v.sign = x[ew + mw];
    v.nan  = (E == emax) && (M != 0);
    v.snan = v.nan && !M[mw - 1];
    v.inf  = (E == emax) && (M == 0);
    v.zero = (E == 0) && (M == 0);
    v.sig  = (E == 0) ? M : (M | (64'd1 << mw));
    v.e    = ((E == 0) ? 1 : int'(E)) - bias - mw;
    return v;
  endfunction

  function automatic logic [63:0] qnan(input logic [1:0] fmt);
    return (((64'd1 << EWf(fmt)) - 1) << MWf(fmt)) | (64'd1 << (MWf(fmt) - 1));
  endfunction
  function automatic logic [63:0] inf_of(input bit s, input logic [1:0] fmt);
    return (64'(s) << (EWf(fmt) + MWf(fmt))) | (((64'd1 << EWf(fmt)) - 1) << MWf(fmt));
  endfunction

  function automatic bit round_up(input logic [2:0] rm, input bit sign, input bit lsb, input bit rbit, input bit sticky);
    case (rm)
      3'd0:    return rbit & (sticky | lsb);   // RNE
      3'd2:    return (rbit | sticky) & sign;  // RDN
      3'd3:    return (rbit | sticky) & ~sign; // RUP
      3'd4:    return rbit;                    // RMM
      default: return 0;                       // RTZ（及 5..7）
    endcase
  endfunction

  // 有限非零值 sign · M · 2^e 舍入到 fmt；返回 {结果位, fflags}
  function automatic void round_pack(input bit sign, input logic [511:0] M, input int e, input logic [1:0] fmt,
                                     input logic [2:0] rm, output logic [63:0] res, output logic [4:0] fl);
    int ew = EWf(fmt), mw = MWf(fmt), P = mw + 1;
    int bias = (1 << (ew - 1)) - 1;
    int emin_lsb = 1 - bias - mw;           // 非规格数（及最小规格数）的最低位指数
    int emax_b = (1 << ew) - 1;
    int p, sh, shu, biased;
    logic [511:0] q, qu;
    bit rbit, sticky, up, inexact, tiny, rbu, stu;
    p = 0;
    for (int i = 0; i < 512; i++) if (M[i]) p = i;
    // ---- 无界指数下的舍入（只用来判 tiny：舍入后 |x| < 2^emin）----
    shu = p - (P - 1);
    if (shu <= 0) begin qu = M << (-shu); rbu = 0; stu = 0; end
    else begin
      qu  = M >> shu;
      rbu = M[shu - 1];
      stu = (shu >= 2) ? |(M & ((512'd1 << (shu - 1)) - 1)) : 1'b0;
    end
    qu = qu + 512'(round_up(rm, sign, qu[0], rbu, stu));
    if (qu == (512'd1 << P)) begin qu = qu >> 1; shu = shu + 1; end
    tiny = (e + shu + mw) < (1 - bias);     // 舍入后最高位的指数 < emin
    // ---- 真实舍入（非规格数时指数钉在下限）----
    sh = p - (P - 1);
    if (e + sh < emin_lsb) sh = emin_lsb - e;
    if (sh <= 0) begin q = M << (-sh); rbit = 0; sticky = 0; end
    else begin
      q      = M >> sh;
      rbit   = M[sh - 1];
      sticky = (sh >= 2) ? |(M & ((512'd1 << (sh - 1)) - 1)) : 1'b0;
    end
    inexact = rbit | sticky;
    up = round_up(rm, sign, q[0], rbit, sticky);
    q  = q + 512'(up);
    if (q == (512'd1 << P)) begin q = q >> 1; sh = sh + 1; end
    biased = q[P - 1] ? (e + sh + mw + bias) : 0;
    fl = 5'b0;
    fl[0] = inexact;
    fl[1] = tiny & inexact;
    if (biased >= emax_b) begin
      fl[2] = 1; fl[0] = 1; fl[1] = 0;
      if (rm == 3'd1 || rm > 3'd4 || (rm == 3'd2 && !sign) || (rm == 3'd3 && sign))
        res = (64'(sign) << (ew + mw)) | (64'(emax_b - 1) << mw) | ((64'd1 << mw) - 1);
      else
        res = inf_of(sign, fmt);
      return;
    end
    res = (64'(sign) << (ew + mw)) | (64'(biased) << mw) | 64'(q & ((512'd1 << mw) - 1));
  endfunction

  // 纯乘法 a·b
  function automatic void mul_ref(input fpv_t a, input fpv_t b, input logic [1:0] fmt, input logic [2:0] rm,
                                  output logic [63:0] res, output logic [4:0] fl);
    bit s = a.sign ^ b.sign;
    fl = 0;
    if (a.nan || b.nan) begin res = qnan(fmt); fl[4] = a.snan | b.snan; return; end
    if ((a.inf && b.zero) || (a.zero && b.inf)) begin res = qnan(fmt); fl[4] = 1; return; end
    if (a.inf || b.inf) begin res = inf_of(s, fmt); return; end
    if (a.zero || b.zero) begin res = 64'(s) << (EWf(fmt) + MWf(fmt)); return; end
    round_pack(s, 512'(a.sig) * 512'(b.sig), a.e + b.e, fmt, rm, res, fl);
  endfunction

  // 乘加 a·b + c（a / b / c 的符号已按指令做好取反 / 交换）
  function automatic void fma_ref(input fpv_t a, input fpv_t b, input fpv_t c, input logic [1:0] fmt,
                                  input logic [2:0] rm, output logic [63:0] res, output logic [4:0] fl);
    bit ps = a.sign ^ b.sign;
    bit pinf = a.inf | b.inf, pzero = a.zero | b.zero;
    logic [511:0] P, C, S;
    int Ep, Ec, base, top_p, top_c;
    bit ssum;
    fl = 0;
    if (a.nan || b.nan || c.nan) begin
      res = qnan(fmt);
      fl[4] = a.snan | b.snan | c.snan | ((a.inf && b.zero) || (a.zero && b.inf));
      return;
    end
    if ((a.inf && b.zero) || (a.zero && b.inf)) begin res = qnan(fmt); fl[4] = 1; return; end
    if (pinf) begin
      if (c.inf && c.sign != ps) begin res = qnan(fmt); fl[4] = 1; return; end
      res = inf_of(ps, fmt); return;
    end
    if (c.inf) begin res = inf_of(c.sign, fmt); return; end
    if (pzero && c.zero) begin
      res = 64'((ps == c.sign) ? ps : (rm == 3'd2)) << (EWf(fmt) + MWf(fmt));
      return;
    end
    if (pzero) begin round_pack(c.sign, 512'(c.sig), c.e, fmt, rm, res, fl); return; end
    P  = 512'(a.sig) * 512'(b.sig);
    Ep = a.e + b.e;
    if (c.zero) begin round_pack(ps, P, Ep, fmt, rm, res, fl); return; end
    C  = 512'(c.sig);
    Ec = c.e;
    top_p = Ep + 128;
    top_c = Ec + 64;
    base  = ((top_p > top_c) ? top_p : top_c) - 400;
    // 对齐到 base：低于 base 的部分只留一个粘滞 1
    if (Ep >= base) P = P << (Ep - base);
    else if (base - Ep >= 256) P = 512'(P != 0);
    else P = (P >> (base - Ep)) | 512'((P & ((512'd1 << (base - Ep)) - 1)) != 0);
    if (Ec >= base) C = C << (Ec - base);
    else if (base - Ec >= 256) C = 512'(C != 0);
    else C = (C >> (base - Ec)) | 512'((C & ((512'd1 << (base - Ec)) - 1)) != 0);
    if (ps == c.sign) begin S = P + C; ssum = ps; end
    else if (P > C) begin S = P - C; ssum = ps; end
    else if (C > P) begin S = C - P; ssum = c.sign; end
    else begin res = 64'(rm == 3'd2) << (EWf(fmt) + MWf(fmt)); return; end
    round_pack(ssum, S, base, fmt, rm, res, fl);
  endfunction
endpackage
