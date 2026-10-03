// =============================================================================
// tb —— FP_INCVT UT：golden FP_INCVT 与重写 FP_INCVT_xs 双例化，同时钟同激励逐拍比 io_result / io_fflags；
//   另把 golden 的结果与 tb 内独立 IEEE oracle 对比（只用整数算术，与被测电路无共享代码）：
//     fp->int     ：cvt_tb_pkg::o_fp2int（RISC-V 饱和/NV/NX 语义，rm 0..4）
//     fp->fp      ：本文件 o_fp2fp —— widen / crossHigh 精确；narrow / crossLow 按 IEEE 舍入（rm 0..4 与 6=ROD），
//                   UF 用 RISC-V 的「舍入后」判 tiny，上溢按 rm 给 Inf 或最大有限数（ROD 给最大有限数）
//     fround(nx)  ：本文件 o_fround —— 舍入到整数值、格式不变；NaN->规范 qNaN，0/Inf/已是整数原样；只有 froundnx 报 NX
//     fcvtmod.w.d ：本文件 o_fcvtmod —— RTZ 截断取低 32 位符号扩展；超出 int32 或 NaN/Inf 报 NV（NaN/Inf 结果 0），否则不精确报 NX
//   标量→向量（isFpToVecInst=1）且窄浮点未 NaN-box 时，golden 只把 widen/narrow 两路的 fflags 清零、结果照算 —— oracle 同样建模。
//
// 激励（每拍）：fire 70%；八类事务按权重（fp->int 28% / widen 9% / crossHigh 6% / narrow 15% / crossLow 8% / fround 13% /
//   fcvtmod 9% / 全随机 12%）；源浮点取 cvt_tb_pkg::pick_fp 的定向边界池，narrow / fcvtmod 再加针对目标格式下溢/上溢区、
//   fcvtmod 的 int32 边界与 1075 移位边界的定向值；opType 的无关位、窄浮点源的高位都随机。复位：前 3 拍拉高，之后偶发。
// 复位域：结果/标志寄存器异步复位，s1 里不复位的那几组只在 fire 时写、只在下一拍被用 —— 输出只依赖已写过的寄存器，
//   所以从第 2 拍起每拍全比（+random 档两侧上电值不同也不影响）。
// 覆盖（写进 PASS 判据）：每类 × rm 组合次数、narrow 的非规格/上溢/UF、fp->int 的 NV 饱和、fround 四个分支、
//   fcvtmod 的 NV/NX，以及 64 位结果逐位见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps
module tb import cvt_tb_pkg::*; ();
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, o_checks = 0, o_errors = 0;
  int cyc;
  bit clock = 0;
  always #5 clock = ~clock;

  logic        reset;
  logic        io_fire;
  logic [63:0] io_src;
  logic [7:0]  io_opType;
  logic [2:0]  io_rm;
  logic [3:0]  io_input1H;
  logic [3:0]  io_output1H;
  logic        io_isFpToVecInst;
  logic [1:0]  io_isFround;
  logic        io_isFcvtmod;
  wire  [63:0] g_res, i_res;
  wire  [4:0]  g_ff, i_ff;

  FP_INCVT u_g (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_src(io_src), .io_opType(io_opType), .io_rm(io_rm),
    .io_input1H(io_input1H), .io_output1H(io_output1H), .io_isFpToVecInst(io_isFpToVecInst),
    .io_isFround(io_isFround), .io_isFcvtmod(io_isFcvtmod), .io_result(g_res), .io_fflags(g_ff));
  FP_INCVT_xs u_i (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_src(io_src), .io_opType(io_opType), .io_rm(io_rm),
    .io_input1H(io_input1H), .io_output1H(io_output1H), .io_isFpToVecInst(io_isFpToVecInst),
    .io_isFround(io_isFround), .io_isFcvtmod(io_isFcvtmod), .io_result(i_res), .io_fflags(i_ff));

  // ---------------------------------------------------------------------------
  // 事务种类
  // ---------------------------------------------------------------------------
  typedef enum int { K_F2I, K_WIDEN, K_CROSSH, K_NARROW, K_CROSSL, K_FROUND, K_FCVTMOD, K_RANDOM, K_NUM } kind_e;
  localparam string KNAME [K_NUM] = '{"f2i", "widen", "crossH", "narrow", "crossL", "fround", "fcvtmod", "random"};

  typedef struct {
    bit          valid;
    kind_e       kind;
    logic [63:0] src;
    int          wi, wo;     // 源浮点宽度；目标浮点/整数宽度
    bit          sgn;        // fp->int 有符号
    bit          nxver;      // froundnx
    bit          canon;      // 标量→向量且未 NaN-box
    logic [2:0]  rm;
  } tx_t;
  tx_t pipe [3];

  // ---------------------------------------------------------------------------
  // oracle 公用：把 sig 右移 d 位并按 rm 舍入（rm 0..4 IEEE，6 = round-to-odd）
  // ---------------------------------------------------------------------------
  function automatic void o_rshift_round(input logic [127:0] sig, input int d, input logic [2:0] rm, input bit neg,
                                         output logic [127:0] kept, output bit inexact);
    bit guard, sticky, up;
    if (d <= 0) begin
      kept = sig << (-d); inexact = 0; return;
    end
    if (d > 120) begin
      kept = 0; guard = 0; sticky = (sig != 0);
    end else begin
      kept   = sig >> d;
      guard  = sig[d - 1];
      sticky = (d > 1) ? |(sig & ((128'h1 << (d - 1)) - 1)) : 1'b0;
    end
    inexact = guard | sticky;
    up = (rm == 3'd6) ? (inexact & ~kept[0]) : o_round_up(rm, neg, kept[0], guard, sticky);
    kept = kept + 128'(up);
  endfunction

  function automatic int msb_of(logic [127:0] v);
    for (int k = 127; k >= 0; k--) if (v[k]) return k;
    return -1;
  endfunction

  // 浮点 -> 浮点（wi -> wo），返回 {fflags, result}（result 为 wo 位，高位 0）
  function automatic logic [68:0] o_fp2fp(logic [63:0] x, int wi, int wo, logic [2:0] rm);
    int ewi, fwi, bi, ewo, fwo, bo, e2, msb, E, L, d, be;
    longint unsigned e, emaxi, emaxo;
    logic [63:0] f;
    logic [127:0] sig, kept, kept2;
    bit s, inexact, inexact2, tiny, rmin;
    ewi = f_ew(wi); fwi = f_fw(wi); bi = f_bias(wi);
    ewo = f_ew(wo); fwo = f_fw(wo); bo = f_bias(wo);
    emaxi = (64'h1 << ewi) - 1; emaxo = (64'h1 << ewo) - 1;
    s = x[wi - 1];
    e = (x >> fwi) & emaxi;
    f = x & ((64'h1 << fwi) - 1);
    if (e == emaxi) begin
      if (f != 0) return {~f[fwi - 1], 4'b0000, mk_fp(wo, 0, emaxo, 64'h1 << (fwo - 1))};   // NaN -> 规范 qNaN
      return {5'b0, mk_fp(wo, s, emaxo, 0)};                                                // Inf
    end
    if (e == 0 && f == 0) return {5'b0, mk_fp(wo, s, 0, 0)};
    sig = (e == 0) ? 128'(f) : (128'(f) | (128'h1 << fwi));
    e2  = ((e == 0) ? 1 : int'(e)) - bi - fwi;
    msb = msb_of(sig);
    E   = msb + e2;                                    // 值落在 [2^E, 2^(E+1))
    L   = (E - fwo > 1 - bo - fwo) ? E - fwo : 1 - bo - fwo;   // 结果最低位的权
    d   = L - e2;
    o_rshift_round(sig, d, rm, s, kept, inexact);
    if (kept >= (128'h1 << (fwo + 1))) begin kept = kept >> 1; L++; end
    be = (kept >= (128'h1 << fwo)) ? L + fwo + bo : 0;
    if (be >= int'(emaxo)) begin
      rmin = (rm == 3'd1) || (rm == 3'd2 && !s) || (rm == 3'd3 && s) || (rm == 3'd6);
      return {5'b00101, rmin ? mk_fp(wo, s, emaxo - 1, '1) : mk_fp(wo, s, emaxo, 0)};
    end
    // tiny：按无界指数舍入后仍 < 最小规格数（RISC-V 的 after-rounding 判据）
    o_rshift_round(sig, (E - fwo) - e2, rm, s, kept2, inexact2);
    tiny = ((kept2 >= (128'h1 << (fwo + 1))) ? E + 1 : E) + bo < 1;
    return {2'b00, 1'b0, tiny & inexact, inexact, mk_fp(wo, s, be, kept[63:0])};
  endfunction

  // fround / froundnx（格式 w 不变）
  function automatic logic [68:0] o_fround(logic [63:0] x, int w, logic [2:0] rm, bit nxver);
    int ew, fw, b, e2, msb;
    longint unsigned e, emax;
    logic [63:0] f;
    logic [127:0] sig, ip;
    bit s, inexact;
    ew = f_ew(w); fw = f_fw(w); b = f_bias(w);
    emax = (64'h1 << ew) - 1;
    s = x[w - 1];
    e = (x >> fw) & emax;
    f = x & ((64'h1 << fw) - 1);
    if (e == emax && f != 0) return {~f[fw - 1], 4'b0000, mk_fp(w, 0, emax, 64'h1 << (fw - 1))};
    if (e == emax || (e == 0 && f == 0) || e >= longint'(b + fw)) return {5'b0, x & ((w == 64) ? '1 : ((64'h1 << w) - 1))};
    sig = (e == 0) ? 128'(f) : (128'(f) | (128'h1 << fw));
    e2  = ((e == 0) ? 1 : int'(e)) - b - fw;           // < 0
    o_rshift_round(sig, -e2, rm, s, ip, inexact);
    if (ip == 0) return {4'b0000, nxver & inexact, mk_fp(w, s, 0, 0)};
    msb = msb_of(ip);
    return {4'b0000, nxver & inexact, mk_fp(w, s, msb + b, 64'(ip << (fw - msb)))};
  endfunction

  // fcvtmod.w.d
  function automatic logic [68:0] o_fcvtmod(logic [63:0] x);
    longint unsigned e;
    logic [63:0] f;
    logic [191:0] t;
    logic [127:0] sig;
    logic [31:0] low;
    bit s, lost, nv;
    int e2;
    s = x[63]; e = x[62:52]; f = x[51:0];
    if (e == 2047) return {5'b10000, 64'h0};
    if (e == 0 && f == 0) return {5'b0, 64'h0};
    sig = (e == 0) ? 128'(f) : (128'(f) | (128'h1 << 52));
    e2  = ((e == 0) ? 1 : int'(e)) - 1075;
    if (e2 >= 0) begin
      t = (e2 < 140) ? (192'(sig) << e2) : 192'h0;
      lost = 0;
      nv = (e2 >= 40) || (s ? (t > 192'h8000_0000) : (t > 192'h7FFF_FFFF));
    end else begin
      t    = (-e2 > 120) ? 192'h0 : 192'(sig >> (-e2));
      lost = (-e2 > 120) ? 1'b1 : |(sig & ((128'h1 << (-e2)) - 1));
      nv   = s ? (t > 192'h8000_0000) : (t > 192'h7FFF_FFFF);
    end
    low = s ? 32'(-t[31:0]) : t[31:0];
    return {nv, 3'b000, ~nv & lost, {{32{low[31]}}, low}};
  endfunction

  // ---------------------------------------------------------------------------
  // 覆盖计数
  // ---------------------------------------------------------------------------
  int kind_rm_cov [K_NUM][8];
  int o_kind [K_NUM];
  int c_nar_sub, c_nar_of, c_nar_uf, c_nar_maxfin, c_f2i_nv, c_f2i_sat_neg, c_f2i_nx;
  int c_fr_nan, c_fr_keep, c_fr_lt1, c_fr_norm, c_fr_nx, c_mod_nv, c_mod_nx, c_canon;
  logic [63:0] seen0 = '0, seen1 = '0;

  function automatic int w_of_1h(logic [3:0] h);
    return h[1] ? 16 : h[2] ? 32 : 64;
  endfunction

  task automatic check_oracle(tx_t t);
    logic [68:0] e;
    logic [63:0] m;
    bit ok;
    ok = 1;
    case (t.kind)
      K_F2I:     begin ok = (t.rm <= 4); if (ok) e = o_fp2int(t.src, t.wi, t.wo, t.sgn, t.rm); end
      K_WIDEN, K_CROSSH: e = o_fp2fp(t.src, t.wi, t.wo, t.rm);
      K_NARROW, K_CROSSL: begin ok = (t.rm <= 4) || (t.rm == 6); if (ok) e = o_fp2fp(t.src, t.wi, t.wo, t.rm); end
      K_FROUND:  begin ok = (t.rm <= 4); if (ok) e = o_fround(t.src, t.wi, t.rm, t.nxver); end
      K_FCVTMOD: e = o_fcvtmod(t.src);
      default:   ok = 0;
    endcase
    if (!ok) return;
    if (t.canon && t.kind inside {K_WIDEN, K_CROSSH, K_NARROW, K_CROSSL}) begin e[68:64] = 5'b0; c_canon++; end
    m = (t.kind == K_FCVTMOD || t.wo == 64) ? '1 : ((64'h1 << t.wo) - 1);
    o_checks++;
    o_kind[t.kind]++;
    if (e[63:0] !== (g_res & m) || e[68:64] !== g_ff) begin
      o_errors++;
      if (o_errors <= 20)
        $display("[%0d] ORACLE MISMATCH %s src=%h wi=%0d wo=%0d sgn=%0d rm=%0d golden=%h/%b oracle=%h/%b",
                 cyc, KNAME[t.kind], t.src, t.wi, t.wo, t.sgn, t.rm, g_res, g_ff, e[63:0], e[68:64]);
    end
    // 事件覆盖（以 oracle 的判定为准）
    case (t.kind)
      K_NARROW, K_CROSSL: begin
        if (e[65]) c_nar_uf++;
        if (e[66]) begin
          c_nar_of++;
          if (((e[63:0] >> f_fw(t.wo)) & ((64'h1 << f_ew(t.wo)) - 1)) == (64'h1 << f_ew(t.wo)) - 2) c_nar_maxfin++;
        end
        if (!e[66] && ((e[63:0] >> f_fw(t.wo)) & ((64'h1 << f_ew(t.wo)) - 1)) == 0 && e[63:0] != 0) c_nar_sub++;
      end
      K_F2I: begin
        if (e[68]) begin c_f2i_nv++; if (t.sgn && t.src[t.wi - 1]) c_f2i_sat_neg++; end
        if (e[64]) c_f2i_nx++;
      end
      K_FROUND: begin
        logic [63:0] ex;
        ex = (t.src >> f_fw(t.wi)) & ((64'h1 << f_ew(t.wi)) - 1);
        if (ex == (64'h1 << f_ew(t.wi)) - 1 && (t.src & ((64'h1 << f_fw(t.wi)) - 1)) != 0) c_fr_nan++;
        else if (ex == (64'h1 << f_ew(t.wi)) - 1 || ex >= f_bias(t.wi) + f_fw(t.wi)) c_fr_keep++;
        else if (ex < f_bias(t.wi)) c_fr_lt1++;
        else c_fr_norm++;
        if (e[64]) c_fr_nx++;
      end
      K_FCVTMOD: begin if (e[68]) c_mod_nv++; if (e[64]) c_mod_nx++; end
      default: ;
    endcase
  endtask

  // ---------------------------------------------------------------------------
  // 定向源值
  // ---------------------------------------------------------------------------
  // narrow：源指数落在目标格式的下溢 / 上溢 / 次正规边界附近
  function automatic logic [63:0] pick_narrow_src(int wi, int wo);
    int bi, bo, fwo, eo;
    longint unsigned emaxo;
    logic [63:0] fr;
    bi = f_bias(wi); bo = f_bias(wo); fwo = f_fw(wo);
    emaxo = (64'h1 << f_ew(wo)) - 1;
    fr = rnd64();
    case ($urandom_range(0, 4))
      0: eo = 1 - $urandom_range(0, fwo + 3);                    // 目标次正规区 / 下溢到 0
      1: eo = 1 + $urandom_range(0, 1) - $urandom_range(0, 1);   // 最小规格数附近
      2: eo = int'(emaxo) - 1 + $urandom_range(0, 1);             // 最大有限数 / 上溢
      3: eo = $urandom_range(1, int'(emaxo) - 1);                 // 目标规格区任意
      default: begin eo = 1 - $urandom_range(0, fwo + 3); fr = '1 >> $urandom_range(0, 3); end  // 尾数全 1：舍入进位
    endcase
    if ($urandom_range(0, 3) == 0) fr = fr & ~((64'h1 << $urandom_range(0, f_fw(wi))) - 1);   // 低位清零：恰好 / 半整
    return mk_fp(wi, 1'($urandom), longint'(eo - bo + bi), fr);
  endfunction

  // fcvtmod：int32 边界、1075 移位边界、64 位移出边界
  function automatic logic [63:0] pick_fcvtmod_src();
    longint unsigned e;
    logic [63:0] fr;
    fr = rnd64();
    case ($urandom_range(0, 5))
      0: e = 1023 + 30 + $urandom_range(0, 3);
      1: e = 1075 - 2 + $urandom_range(0, 4);
      2: e = 1075 - 64 - 2 + $urandom_range(0, 4);
      3: e = 1075 + 64 - 2 + $urandom_range(0, 4);
      4: begin e = 1023 + 31; fr = $urandom_range(0, 1) ? 64'h0 : (64'h1 << $urandom_range(0, 51)); end   // ±2^31 附近
      default: e = 1023 - 3 + $urandom_range(0, 40);
    endcase
    return mk_fp(64, 1'($urandom), e, fr);
  endfunction

  function automatic logic [3:0] fp1h(int w); return (w == 16) ? 4'b0010 : (w == 32) ? 4'b0100 : 4'b1000; endfunction
  function automatic logic [3:0] int1h(int w); return (w == 8) ? 4'b0001 : (w == 16) ? 4'b0010 : (w == 32) ? 4'b0100 : 4'b1000; endfunction

  // ---------------------------------------------------------------------------
  // 主循环
  // ---------------------------------------------------------------------------
  initial begin
    int bad, r;
    tx_t t;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1; io_fire = 0; io_src = 0; io_opType = 0; io_rm = 0; io_input1H = 0; io_output1H = 0;
    io_isFpToVecInst = 0; io_isFround = 0; io_isFcvtmod = 0;
    foreach (pipe[k]) pipe[k].valid = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(posedge clock); #1;
      if (cyc >= 2) begin
        checks++;
        if (g_res !== i_res || g_ff !== i_ff) begin
          errors++;
          if (errors <= 30) $display("[%0d] MISMATCH result g=%h i=%h fflags g=%b i=%b", cyc, g_res, i_res, g_ff, i_ff);
        end
        seen1 |= g_res; seen0 |= ~g_res;
      end
      pipe[2] = pipe[1]; pipe[1] = pipe[0];
      if (pipe[2].valid && !reset) check_oracle(pipe[2]);

      // ---- 新激励 ----
      reset = (cyc < 3) || ($urandom_range(0, 19999) == 0);
      io_fire = ($urandom_range(0, 9) < 7);
      r = $urandom_range(0, 99);
      t.kind = (r < 28) ? K_F2I : (r < 37) ? K_WIDEN : (r < 43) ? K_CROSSH : (r < 58) ? K_NARROW :
               (r < 66) ? K_CROSSL : (r < 79) ? K_FROUND : (r < 88) ? K_FCVTMOD : K_RANDOM;
      t.sgn = 0; t.nxver = 0;
      io_opType = 8'($urandom);
      io_isFround = 2'b00; io_isFcvtmod = 1'b0;
      io_rm = ($urandom_range(0, 9) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
      case (t.kind)
        K_F2I: begin
          t.wi = 16 << $urandom_range(0, 2); t.wo = 8 << $urandom_range(0, 3); t.sgn = $urandom;
          io_opType[6] = 1'b0; io_opType[0] = t.sgn;
          t.src = pick_fp(t.wi);
        end
        K_WIDEN: begin
          t.wi = $urandom_range(0, 1) ? 16 : 32; t.wo = t.wi * 2;
          io_opType[6] = 1'b1; io_opType[4:3] = 2'b01;
          t.src = pick_fp(t.wi);
        end
        K_CROSSH: begin
          t.wi = 16; t.wo = 64;
          io_opType[6] = 1'b1; io_opType[4:3] = 2'b11;
          t.src = pick_fp(t.wi);
        end
        K_NARROW: begin
          t.wi = $urandom_range(0, 1) ? 32 : 64; t.wo = t.wi / 2;
          io_opType[6] = 1'b1; io_opType[4:3] = 2'b10;
          if ($urandom_range(0, 9) == 0) io_rm = 3'd6;
          t.src = ($urandom_range(0, 9) < 5) ? pick_narrow_src(t.wi, t.wo) : pick_fp(t.wi);
        end
        K_CROSSL: begin
          t.wi = 64; t.wo = 16;
          io_opType[6] = 1'b1; io_opType[4:3] = 2'b11;
          if ($urandom_range(0, 9) == 0) io_rm = 3'd6;
          t.src = ($urandom_range(0, 9) < 5) ? pick_narrow_src(t.wi, t.wo) : pick_fp(t.wi);
        end
        K_FROUND: begin
          t.wi = 16 << $urandom_range(0, 2); t.wo = t.wi;
          io_opType[6] = 1'b1; io_opType[4:3] = 2'b00;
          t.nxver = $urandom;
          io_isFround = t.nxver ? 2'b10 : 2'b01;
          t.src = pick_fp(t.wi);
        end
        K_FCVTMOD: begin
          t.wi = 64; t.wo = 32; t.sgn = 1;
          io_opType[6] = 1'b0; io_opType[4:3] = 2'b00; io_opType[0] = 1'b1;
          io_isFcvtmod = 1'b1;
          t.src = ($urandom_range(0, 1)) ? pick_fcvtmod_src() : pick_fp(64);
        end
        default: begin
          t.wi = 64; t.wo = 64;
          t.src = rnd64();
          io_isFround = 2'($urandom); io_isFcvtmod = $urandom;
        end
      endcase
      if (t.kind == K_RANDOM) begin
        io_input1H = 4'($urandom); io_output1H = 4'($urandom);
      end else begin
        io_input1H  = fp1h(t.wi);
        io_output1H = (t.kind == K_F2I) ? int1h(t.wo) : (t.kind == K_FCVTMOD) ? 4'($urandom) : fp1h(t.wo);
      end
      // 窄浮点源的高位：标量→向量时一半 NaN-box、一半垃圾；否则随机或 0
      io_isFpToVecInst = ($urandom_range(0, 3) == 0);
      if (t.wi < 64 && t.kind != K_RANDOM) begin
        t.src = t.src & ((64'h1 << t.wi) - 1);
        case ($urandom_range(0, 2))
          0: t.src = t.src | ~((64'h1 << t.wi) - 1);
          1: t.src = t.src | (rnd64() << t.wi);
          default: ;
        endcase
      end
      io_src = t.src;
      t.canon = io_isFpToVecInst & ((t.wi == 16 && io_src[63:16] != '1) || (t.wi == 32 && io_src[63:32] != '1));
      t.rm = io_rm;
      t.valid = io_fire && !reset;
      if (t.valid) kind_rm_cov[t.kind][io_rm]++;
      pipe[0] = t;
      if (reset) pipe[1].valid = 0;
    end

    // ---- 覆盖判据 ----
    bad = 0;
    for (int k = 0; k < K_NUM; k++) for (int m = 0; m < 8; m++) begin
      int need;
      need = (m <= 4) ? 200 : (m == 6 && (k == K_NARROW || k == K_CROSSL)) ? 200 : 20;
      if (kind_rm_cov[k][m] < need) begin bad++; $display("cov LOW %s rm=%0d : %0d", KNAME[k], m, kind_rm_cov[k][m]); end
    end
    if (c_nar_sub < 500 || c_nar_of < 500 || c_nar_uf < 200 || c_nar_maxfin < 100) begin bad++; $display("cov LOW narrow events"); end
    if (c_f2i_nv < 500 || c_f2i_sat_neg < 100 || c_f2i_nx < 500) begin bad++; $display("cov LOW f2i events"); end
    if (c_fr_nan < 100 || c_fr_keep < 300 || c_fr_lt1 < 300 || c_fr_norm < 300 || c_fr_nx < 300) begin bad++; $display("cov LOW fround events"); end
    if (c_mod_nv < 300 || c_mod_nx < 300 || c_canon < 300) begin bad++; $display("cov LOW fcvtmod / canon events"); end
    if (seen0 !== '1 || seen1 !== '1) begin bad++; $display("cov LOW result bits seen0=%h seen1=%h", seen0, seen1); end
    for (int k = 0; k < K_NUM; k++) begin
      string ln;
      ln = $sformatf("cov %-8s oracle=%0d rm:", KNAME[k], o_kind[k]);
      for (int m = 0; m < 8; m++) ln = {ln, $sformatf(" %0d", kind_rm_cov[k][m])};
      $display("%s", ln);
    end
    $display("cov narrow sub=%0d of=%0d maxfinite=%0d uf=%0d | f2i nv=%0d satneg=%0d nx=%0d | fround nan=%0d keep=%0d lt1=%0d norm=%0d nx=%0d | fcvtmod nv=%0d nx=%0d | canon=%0d",
             c_nar_sub, c_nar_of, c_nar_maxfin, c_nar_uf, c_f2i_nv, c_f2i_sat_neg, c_f2i_nx,
             c_fr_nan, c_fr_keep, c_fr_lt1, c_fr_norm, c_fr_nx, c_mod_nv, c_mod_nx, c_canon);
    $display("oracle_checks=%0d oracle_errors=%0d", o_checks, o_errors);
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && o_errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
