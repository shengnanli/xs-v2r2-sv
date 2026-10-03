// =============================================================================
// cvt_tb_pkg —— 向量浮点转换子树（VCVT_8 / VectorCvtTop / VectorCvt / VCVT* / CVT64_1 /
//   CVT32 / CVT16 / INT2FP / Estimate7）各 UT 共用的激励、分类计数与数学 oracle。
//
// 只给 tb 用（不进 RTL、不进 FM）。三块内容：
//   1. 操作选择：yunsuan VfcvtType 的 23 条向量转换 opType × sew，按 RVV 合法组合加权，
//      另留一部分完全随机的 opType/sew（golden 对非法组合也有确定输出，同样要比）。
//   2. 元素生成：浮点按格式取「定向边界池 + 随机」，整数按「定向池 + 随机位长」，
//      保证舍入（round/sticky 位）、上溢、CLZ 各档、rec7/rsqrt7 的边界都能打到。
//   3. oracle：整数 -> 浮点（任意 8/16/32/64 位整数到 f16/f32/f64，五种 IEEE 舍入）与
//      浮点 -> 整数（f16/f32/f64 到 8/16/32/64 位有/无符号，五种舍入，NV/NX 语义按
//      RISC-V 规范：NaN/+Inf/正越界饱和到最大值，-Inf/负越界饱和到最小值且置 NV，
//      无符号负数舍入后非 0 置 NV 给 0）。两者都只用整数算术，与被测电路无共享代码。
// =============================================================================
package cvt_tb_pkg;

  // ---------------------------------------------------------------------------
  // 1. opType（8 位，yunsuan.VfcvtType；[7]=源是浮点 [6]=目的是浮点 [5]=估算 [4:3]=widen）
  // ---------------------------------------------------------------------------
  localparam logic [7:0] VEC_OPS [23] = '{
    8'b10_000000, 8'b10_000001, 8'b01_000010, 8'b01_000011,   // vfcvt.xu.f / x.f / f.xu / f.x
    8'b10_000110, 8'b10_000111,                               // vfcvt.rtz.xu.f / rtz.x.f
    8'b11_100000, 8'b11_100001,                               // vfrsqrt7 / vfrec7
    8'b10_001000, 8'b10_001001, 8'b01_001010, 8'b01_001011,   // vfwcvt.xu.f / x.f / f.xu / f.x
    8'b11_001100, 8'b10_001110, 8'b10_001111,                 // vfwcvt.f.f / rtz.xu.f / rtz.x.f
    8'b10_010000, 8'b10_010001, 8'b01_010010, 8'b01_010011,   // vfncvt.xu.f / x.f / f.xu / f.x
    8'b11_010100, 8'b11_010101,                               // vfncvt.f.f / rod.f.f
    8'b10_010110, 8'b10_010111                                // vfncvt.rtz.xu.f / rtz.x.f
  };

  // 本 opType 在 sew 下是否是 RVV/香山真正会发的组合
  function automatic bit op_legal(logic [7:0] op, logic [1:0] sew);
    logic [1:0] wd;
    bit known;
    known = 0;
    foreach (VEC_OPS[k]) if (VEC_OPS[k] == op) known = 1;
    if (!known) return 0;                                                  // 不在 23 条向量 op 里
    wd = op[4:3];
    if (op[5])               return sew != 2'd0 && wd == 2'b00;            // rec7/rsqrt7: f16/32/64
    if (op[7:6] == 2'b11) begin                                            // f2f
      return (wd == 2'b01 || wd == 2'b10) && (sew == 2'd1 || sew == 2'd2);
    end
    case (wd)
      2'b00: return sew != 2'd0;                                           // 同宽：16/32/64
      2'b01: return (op[7:6] == 2'b01) ? sew != 2'd3 : (sew == 2'd1 || sew == 2'd2);
      2'b10: return (op[7:6] == 2'b10) ? sew != 2'd3 : (sew == 2'd1 || sew == 2'd2);
      default: return 0;
    endcase
  endfunction

  // 源 / 目的元素宽度（位）：single 同 SEW；widen 源 SEW 目的 2SEW；narrow 源 2SEW 目的 SEW
  function automatic int in_width(logic [7:0] op, logic [1:0] sew);
    return (op[4:3] == 2'b10) ? (16 << sew) : (8 << sew);
  endfunction
  function automatic int out_width(logic [7:0] op, logic [1:0] sew);
    return (op[4:3] == 2'b01) ? (16 << sew) : (8 << sew);
  endfunction

  // 转换大类
  typedef enum int { C_I2F, C_F2I, C_F2F, C_REC7, C_RSQRT7, C_OTHER } cls_e;
  function automatic cls_e op_class(logic [7:0] op);
    if (op[5])               return op[0] ? C_REC7 : C_RSQRT7;
    case (op[7:6])
      2'b01:   return C_I2F;
      2'b10:   return C_F2I;
      2'b11:   return C_F2F;
      default: return C_OTHER;
    endcase
  endfunction
  function automatic string cls_name(cls_e c);
    case (c)
      C_I2F: return "i2f";  C_F2I: return "f2i";  C_F2F: return "f2f";
      C_REC7: return "rec7"; C_RSQRT7: return "rsqrt7"; default: return "other";
    endcase
  endfunction

  // 分类计数键：类 × 有无符号/rtz/rod × 源宽 > 目的宽 × rm
  function automatic string op_key(logic [7:0] op, logic [1:0] sew, logic [2:0] rm);
    cls_e c;
    string tag;
    c = op_class(op);
    tag = "";
    if (c == C_I2F || c == C_F2I) tag = op[0] ? ".s" : ".u";
    if (c == C_F2I && op[2:1] == 2'b11) tag = {tag, ".rtz"};
    if (c == C_F2F && op[2:0] == 3'b101) tag = ".rod";
    if (!op_legal(op, sew)) return "illegal";
    return $sformatf("%s%s.%0d>%0d.rm%0d", cls_name(c), tag, in_width(op, sew), out_width(op, sew), rm);
  endfunction

  // 选一个 (opType, sew)：80% 合法组合均匀；10% 向量 op + 任意 sew；10% 完全随机 8 位
  function automatic void pick_op(output logic [7:0] op, output logic [1:0] sew);
    int r;
    r = $urandom_range(0, 99);
    if (r < 80) begin
      do begin
        op  = VEC_OPS[$urandom_range(0, 22)];
        sew = 2'($urandom);
      end while (!op_legal(op, sew));
    end else if (r < 90) begin
      op  = VEC_OPS[$urandom_range(0, 22)];
      sew = 2'($urandom);
    end else begin
      op  = 8'($urandom);
      sew = 2'($urandom);
    end
  endfunction

  // 舍入模式：0..4 合法动态模式各常打；5/7 非法值与 6(ROD) 也留一点
  function automatic logic [2:0] pick_rm();
    int r;
    r = $urandom_range(0, 99);
    if (r < 90) return 3'($urandom_range(0, 4));
    return 3'($urandom_range(5, 7));
  endfunction

  // VectorCvt 的宽度译码（Scala VectorCvt 的两张真值表，供直接驱动 input1H/output1H 的 UT 用）
  function automatic logic [3:0] dec_in1h(logic [7:0] op, logic [1:0] sew);
    case ({op[4:3], sew})
      4'b00_01: return 4'b0010;  4'b00_10: return 4'b0100;  4'b00_11: return 4'b1000;
      4'b01_00: return 4'b0001;  4'b01_01: return 4'b0010;  4'b01_10: return 4'b0100;
      4'b10_00: return 4'b0010;  4'b10_01: return 4'b0100;  4'b10_10: return 4'b1000;
      default:  return 4'b0000;
    endcase
  endfunction
  function automatic logic [3:0] dec_out1h(logic [7:0] op, logic [1:0] sew);
    case ({op[4:3], sew})
      4'b00_01: return 4'b0010;  4'b00_10: return 4'b0100;  4'b00_11: return 4'b1000;
      4'b01_00: return 4'b0010;  4'b01_01: return 4'b0100;  4'b01_10: return 4'b1000;
      4'b10_00: return 4'b0001;  4'b10_01: return 4'b0010;  4'b10_10: return 4'b0100;
      default:  return 4'b0000;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // 2. 元素生成
  // ---------------------------------------------------------------------------
  // 浮点格式参数：w=16/32/64
  function automatic int f_ew(int w);  return (w == 16) ? 5  : (w == 32) ? 8  : 11; endfunction
  function automatic int f_fw(int w);  return (w == 16) ? 10 : (w == 32) ? 23 : 52; endfunction
  function automatic int f_bias(int w); return (1 << (f_ew(w) - 1)) - 1; endfunction

  function automatic logic [63:0] rnd64();
    return {$urandom, $urandom};
  endfunction

  function automatic logic [63:0] mk_fp(int w, logic s, longint unsigned e, logic [63:0] f);
    int ew, fw;
    logic [63:0] m;
    ew = f_ew(w); fw = f_fw(w);
    m  = (64'h1 << fw) - 1;
    return (64'(s) << (w - 1)) | ((64'(e) & ((64'h1 << ew) - 1)) << fw) | (f & m);
  endfunction

  // 一个 w 位浮点（低 w 位有效），类别分布见 case
  function automatic logic [63:0] pick_fp(int w);
    int ew, fw, bias, k;
    longint unsigned emax;
    logic s;
    logic [63:0] f;
    ew = f_ew(w); fw = f_fw(w); bias = f_bias(w);
    emax = (64'h1 << ew) - 1;
    s = 1'($urandom);
    f = rnd64();
    k = $urandom_range(0, 15);
    case (k)
      0:  return mk_fp(w, s, 0, 0);                                   // ±0
      1:  return mk_fp(w, s, emax, 0);                                // ±Inf
      2:  return mk_fp(w, s, emax, (64'h1 << (fw - 1)) | (f >> 3));   // qNaN
      3:  return mk_fp(w, s, emax, ((f >> 3) | 64'h1) & ~(64'h1 << (fw - 1)));  // sNaN
      4:  return mk_fp(w, s, 0, f >> $urandom_range(0, fw));         // 非规格化（随机位长）
      5:  return mk_fp(w, s, 0, (64'h1 << (fw - 1)) >> $urandom_range(0, 3));  // 非规格化，最高 4 位（rec7 溢出边界）
      6, 7, 8: begin                                                    // 指数落在整数转换敏感区 2^-3..2^66
        longint unsigned e;
        e = bias + $urandom_range(0, 69) - 3;
        if (e >= emax) e = emax - 1;
        return mk_fp(w, s, e, (k == 8) ? (f >> $urandom_range(0, fw)) : f);
      end
      9:  return mk_fp(w, s, emax - 1 - $urandom_range(0, 2), f);    // 最大指数附近（rec7 b/b-1/b+1 档）
      10: return mk_fp(w, s, 1 + $urandom_range(0, 2), f);           // 最小规格化附近
      11: return mk_fp(w, s, bias + $urandom_range(0, 1) - 1, 64'h0); // 0.5 / 1.0（正好可表示）
      12: begin                                                       // 半整数：round 位恰为 1，sticky=0
        int ki;
        ki = $urandom_range(1, (fw - 1 < 20) ? fw - 1 : 20);              // 整数部分位数
        return mk_fp(w, s, bias + ki, (f & ~((64'h1 << (fw - ki)) - 1)) | (64'h1 << (fw - ki - 1)));
      end
      13: begin                                                       // f32 -> f16 变窄的敏感区（下溢/上溢）
        longint unsigned e;
        e = (w == 32) ? (127 - 26 + $urandom_range(0, 46)) : (bias + $urandom_range(0, 40) - 20);
        return mk_fp(w, s, e, f);
      end
      14: begin                                                       // 2^(k+1) 的正下方（尾数全 1）：饱和/上溢/舍入进位边界
        longint unsigned e;
        e = bias + $urandom_range(0, 33);
        if (e >= emax) e = emax - 1;
        return mk_fp(w, s, e, ((64'h1 << fw) - 1) >> $urandom_range(0, 2));
      end
      default: return rnd64() & ((w == 64) ? 64'hFFFF_FFFF_FFFF_FFFF : ((64'h1 << w) - 1));
    endcase
  endfunction

  // 一个 w 位整数（低 w 位有效）
  function automatic logic [63:0] pick_int(int w);
    logic [63:0] m, x;
    int k, l;
    m = (w == 64) ? 64'hFFFF_FFFF_FFFF_FFFF : ((64'h1 << w) - 1);
    x = rnd64();
    k = $urandom_range(0, 11);
    case (k)
      0: return 64'h0;
      1: return m;                                        // 全 1（有符号 -1）
      2: return (64'h1 << (w - 1)) & m;                   // 有符号最小
      3: return m >> 1;                                   // 有符号最大
      4: return 64'($urandom_range(1, 255));              // 小正数（精确可表示）
      5: return (m - 64'($urandom_range(0, 255))) & m;    // 小负数
      6: begin l = $urandom_range(0, w - 1); return ((64'h1 << l) + 64'($signed($urandom_range(0, 6)) - 3)) & m; end  // 2^k 附近
      7: return (64'(65504) + 64'($urandom_range(0, 40))) & m;                    // f16 上溢边界
      8, 9: begin l = $urandom_range(1, w); return (l == 64) ? x : (x & ((64'h1 << l) - 1)); end   // 随机位长
      default: return x & m;
    endcase
  endfunction

  // 按 (op, sew) 生成一个源元素（低 in_width 位有效，高位按 1/2 概率填垃圾）
  function automatic logic [63:0] pick_elem(logic [7:0] op, logic [1:0] sew);
    int w;
    logic [63:0] v;
    w = in_width(op, sew);
    if (w > 64) w = 64;
    v = op[7] ? pick_fp((w < 16) ? 16 : w) : pick_int(w);
    if (w < 64) begin
      v = v & ((64'h1 << w) - 1);
      if ($urandom_range(0, 1)) v = v | (rnd64() << w);
    end
    return v;
  endfunction

  // 一个 64 位向量源：按源元素宽度逐个填
  function automatic logic [63:0] pick_vec64(logic [7:0] op, logic [1:0] sew);
    int w;
    logic [63:0] v, e;
    w = in_width(op, sew);
    if (w > 64 || w < 8) w = 64;
    v = '0;
    for (int i = 0; i < 64 / w; i++) begin
      e = op[7] ? pick_fp((w < 16) ? 16 : w) : pick_int(w);
      v = v | ((e & ((w == 64) ? '1 : ((64'h1 << w) - 1))) << (i * w));
    end
    if ($urandom_range(0, 9) == 0) v = rnd64();
    return v;
  endfunction

  // ---------------------------------------------------------------------------
  // 3. oracle
  // ---------------------------------------------------------------------------
  // 舍入判定（IEEE 五种：0 RNE 1 RTZ 2 RDN 3 RUP 4 RMM）
  function automatic bit o_round_up(logic [2:0] rm, bit neg, bit lsb, bit guard, bit sticky);
    case (rm)
      3'd0: return guard & (sticky | lsb);
      3'd1: return 0;
      3'd2: return (guard | sticky) & neg;
      3'd3: return (guard | sticky) & ~neg;
      3'd4: return guard;
      default: return 0;
    endcase
  endfunction

  // 整数 -> 浮点。mag = |x|，neg = 符号，w = 16/32/64。返回 {fflags[4:0], result[63:0]}
  function automatic logic [68:0] o_int2fp(logic [63:0] mag, bit neg, int w, logic [2:0] rm);
    int ew, fw, bias, msb, sh;
    logic [64:0] kept;
    logic [63:0] rem;
    bit guard, sticky, up, of, nx;
    longint unsigned bexp, emax;
    logic [63:0] res;
    ew = f_ew(w); fw = f_fw(w); bias = f_bias(w);
    emax = (64'h1 << ew) - 1;
    if (mag == 0) return {5'b0, 64'(neg) << (w - 1)};
    msb = 63;
    while (!mag[msb]) msb--;
    if (msb > fw) begin
      sh     = msb - fw;
      kept   = 65'(mag >> sh);
      rem    = (sh == 64) ? mag : (mag & ((64'h1 << sh) - 1));
      guard  = rem[sh - 1];
      sticky = (sh > 1) ? |(rem & ((64'h1 << (sh - 1)) - 1)) : 1'b0;
    end else begin
      kept   = 65'(mag) << (fw - msb);
      guard  = 0;
      sticky = 0;
    end
    up   = o_round_up(rm, neg, kept[0], guard, sticky);
    kept = kept + 65'(up);
    bexp = msb + bias;
    if (kept[fw + 1]) begin kept = kept >> 1; bexp++; end
    nx = guard | sticky;
    of = bexp >= emax;
    if (of) begin
      bit rmin;
      rmin = (rm == 3'd1) || (rm == 3'd2 && !neg) || (rm == 3'd3 && neg);
      res = rmin ? mk_fp(w, neg, emax - 1, '1) : mk_fp(w, neg, emax, 0);
      return {2'b00, 1'b1, 1'b0, 1'b1, res};
    end
    res = mk_fp(w, neg, bexp, kept[63:0]);
    return {2'b00, 1'b0, 1'b0, nx, res};
  endfunction

  // 浮点 -> 整数。x 的低 w 位是 f16/f32/f64；iw = 8/16/32/64；sgn = 有符号目标。
  // 返回 {fflags[4:0], result[63:0]}，result 为 iw 位（高位 0）
  function automatic logic [68:0] o_fp2int(logic [63:0] x, int w, int iw, bit sgn, logic [2:0] rm);
    int ew, fw, bias;
    longint unsigned e, emax;
    logic [63:0] f, imask, maxv, minv;
    bit neg, nv, nx, guard, sticky, up;
    logic [127:0] sig, ip;
    int sh;
    ew = f_ew(w); fw = f_fw(w); bias = f_bias(w);
    emax  = (64'h1 << ew) - 1;
    neg   = x[w - 1];
    e     = (x >> fw) & emax;
    f     = x & ((64'h1 << fw) - 1);
    imask = (iw == 64) ? '1 : ((64'h1 << iw) - 1);
    maxv  = sgn ? (imask >> 1) : imask;
    minv  = sgn ? ((64'h1 << (iw - 1)) & imask) : 64'h0;
    if (e == emax) begin                                   // Inf / NaN
      if (f != 0 || !neg) return {5'b10000, maxv};
      return {5'b10000, minv};
    end
    // 值 = sig * 2^(e' - fw)，sig 含隐含位
    sig = (e == 0) ? 128'(f) : (128'(f) | (128'h1 << fw));
    if (e == 0) e = 1;
    sh = int'(e) - bias - fw;                              // 左移位数（负 = 右移）
    if (sh >= 0) begin
      if (sh > 70) ip = '1; else ip = sig << sh;
      guard = 0; sticky = 0;
    end else begin
      int r;
      r = -sh;
      if (r > 120) begin ip = 0; guard = 0; sticky = (sig != 0); end
      else begin
        ip     = sig >> r;
        guard  = sig[r - 1];
        sticky = (r > 1) ? |(sig & ((128'h1 << (r - 1)) - 1)) : 1'b0;
      end
    end
    nx = guard | sticky;
    up = o_round_up(rm, neg, ip[0], guard, sticky);
    ip = ip + 128'(up);
    // 范围检查
    if (!neg) begin
      if (ip > 128'(maxv)) return {5'b10000, maxv};
      return {4'b0000, nx, ip[63:0] & imask};
    end else begin
      if (!sgn) begin
        if (ip != 0) return {5'b10000, 64'h0};
        return {4'b0000, nx, 64'h0};
      end
      if (ip > (128'(maxv) + 1)) return {5'b10000, minv};
      return {4'b0000, nx, (64'(-ip[63:0])) & imask};
    end
  endfunction

  // RVV 规范附录给出的两张 7 位估算表（vfrec7 / vfrsqrt7），按规范原文抄录
  localparam logic [6:0] O_REC7 [128] = '{
    7'd127, 7'd125, 7'd123, 7'd121, 7'd119, 7'd117, 7'd116, 7'd114, 7'd112, 7'd110, 7'd109, 7'd107, 7'd105, 7'd104, 7'd102, 7'd100,
    7'd99, 7'd97, 7'd96, 7'd94, 7'd93, 7'd91, 7'd90, 7'd88, 7'd87, 7'd85, 7'd84, 7'd83, 7'd81, 7'd80, 7'd79, 7'd77,
    7'd76, 7'd75, 7'd74, 7'd72, 7'd71, 7'd70, 7'd69, 7'd68, 7'd66, 7'd65, 7'd64, 7'd63, 7'd62, 7'd61, 7'd60, 7'd59,
    7'd58, 7'd57, 7'd56, 7'd55, 7'd54, 7'd53, 7'd52, 7'd51, 7'd50, 7'd49, 7'd48, 7'd47, 7'd46, 7'd45, 7'd44, 7'd43,
    7'd42, 7'd41, 7'd40, 7'd40, 7'd39, 7'd38, 7'd37, 7'd36, 7'd35, 7'd35, 7'd34, 7'd33, 7'd32, 7'd31, 7'd31, 7'd30,
    7'd29, 7'd28, 7'd28, 7'd27, 7'd26, 7'd25, 7'd25, 7'd24, 7'd23, 7'd23, 7'd22, 7'd21, 7'd21, 7'd20, 7'd19, 7'd19,
    7'd18, 7'd17, 7'd17, 7'd16, 7'd15, 7'd15, 7'd14, 7'd14, 7'd13, 7'd12, 7'd12, 7'd11, 7'd11, 7'd10, 7'd9, 7'd9,
    7'd8, 7'd8, 7'd7, 7'd7, 7'd6, 7'd5, 7'd5, 7'd4, 7'd4, 7'd3, 7'd3, 7'd2, 7'd2, 7'd1, 7'd1, 7'd0
  };
  localparam logic [6:0] O_RSQRT7 [128] = '{
    7'd52, 7'd51, 7'd50, 7'd48, 7'd47, 7'd46, 7'd44, 7'd43, 7'd42, 7'd41, 7'd40, 7'd39, 7'd38, 7'd36, 7'd35, 7'd34,
    7'd33, 7'd32, 7'd31, 7'd30, 7'd30, 7'd29, 7'd28, 7'd27, 7'd26, 7'd25, 7'd24, 7'd23, 7'd23, 7'd22, 7'd21, 7'd20,
    7'd19, 7'd19, 7'd18, 7'd17, 7'd16, 7'd16, 7'd15, 7'd14, 7'd14, 7'd13, 7'd12, 7'd12, 7'd11, 7'd10, 7'd10, 7'd9,
    7'd9, 7'd8, 7'd7, 7'd7, 7'd6, 7'd6, 7'd5, 7'd4, 7'd4, 7'd3, 7'd3, 7'd2, 7'd2, 7'd1, 7'd1, 7'd0,
    7'd127, 7'd125, 7'd123, 7'd121, 7'd119, 7'd118, 7'd116, 7'd114, 7'd113, 7'd111, 7'd109, 7'd108, 7'd106, 7'd105, 7'd103, 7'd102,
    7'd100, 7'd99, 7'd97, 7'd96, 7'd95, 7'd93, 7'd92, 7'd91, 7'd90, 7'd88, 7'd87, 7'd86, 7'd85, 7'd84, 7'd83, 7'd82,
    7'd80, 7'd79, 7'd78, 7'd77, 7'd76, 7'd75, 7'd74, 7'd73, 7'd72, 7'd71, 7'd70, 7'd70, 7'd69, 7'd68, 7'd67, 7'd66,
    7'd65, 7'd64, 7'd63, 7'd63, 7'd62, 7'd61, 7'd60, 7'd59, 7'd59, 7'd58, 7'd57, 7'd56, 7'd56, 7'd55, 7'd54, 7'd53
  };

  // vfrec7 / vfrsqrt7 oracle（RVV 1.0 规范算法）。x 的低 w 位是 f16/f32/f64。
  // 返回 {fflags[4:0], result[63:0]}
  function automatic logic [68:0] o_estimate7(logic [63:0] x, int w, bit is_rec, logic [2:0] rm);
    int ew, fw, bias, lz, e, oe;
    longint unsigned emax;
    logic [63:0] f, fn, sig;
    bit neg, is_nan, is_snan;
    logic [6:0] idx, t;
    ew = f_ew(w); fw = f_fw(w); bias = f_bias(w);
    emax = (64'h1 << ew) - 1;
    neg  = x[w - 1];
    e    = int'((x >> fw) & emax);
    f    = x & ((64'h1 << fw) - 1);
    is_nan  = (e == emax) && (f != 0);
    is_snan = is_nan && !f[fw - 1];
    // 规范 NaN：指数全 1、尾数最高位 1
    if (is_nan) return {is_snan, 4'b0000, mk_fp(w, 0, emax, 64'h1 << (fw - 1))};
    if (is_rec) begin
      if (e == emax) return {5'b0, mk_fp(w, neg, 0, 0)};                 // 1/±Inf = ±0
      if (e == 0 && f == 0) return {5'b01000, mk_fp(w, neg, emax, 0)};  // 1/±0 = ±Inf, DZ
    end else begin
      if (e == 0 && f == 0) return {5'b01000, mk_fp(w, neg, emax, 0)};  // ±0 -> ±Inf, DZ
      if (neg) return {5'b10000, mk_fp(w, 0, emax, 64'h1 << (fw - 1))};   // 负数 -> NaN, NV
      if (e == emax) return {5'b0, 64'h0};                               // +Inf -> +0
    end
    // 规格化
    if (e == 0) begin
      lz = 0;
      while (!f[fw - 1 - lz]) lz++;
      fn = (f << (lz + 1)) & ((64'h1 << fw) - 1);
      e  = -lz;
    end else fn = f;
    if (is_rec) begin
      idx = 7'(fn >> (fw - 7));
      t   = O_REC7[idx];
      oe  = 2 * bias - 1 - e;
      if (oe > int'(emax) - 1) begin                                      // 上溢（极小的非规格化）
        bit rmin;
        rmin = (rm == 3'd1) || (rm == 3'd2 && !neg) || (rm == 3'd3 && neg);
        return {5'b00101, rmin ? mk_fp(w, neg, emax - 1, '1) : mk_fp(w, neg, emax, 0)};
      end
      if (oe <= 0) begin                                                  // 结果非规格化
        sig = ((64'h1 << 7) | 64'(t)) << (fw - 8);
        sig = sig >> (-oe);
        return {5'b0, mk_fp(w, neg, 0, sig)};
      end
      return {5'b0, mk_fp(w, neg, oe, 64'(t) << (fw - 7))};
    end else begin
      idx = {e[0], 6'(fn >> (fw - 6))};
      t   = O_RSQRT7[idx];
      oe  = (3 * bias - 1 - e) / 2;
      return {5'b0, mk_fp(w, 0, oe, 64'(t) << (fw - 7))};
    end
  endfunction

  // 统一入口：对一个元素给出 oracle 期望。适用条件：(op, sew) 合法、rm∈0..4、类属 i2f / f2i /
  // rec7 / rsqrt7（f2f 无 oracle）。rtz_resolved=0 时跳过 opType 编码了 RTZ 的 f2i（那一层
  // 还没把 RTZ 折进 rm）；=1 时按 RTZ 算。x 的低 in_width 位是源元素。
  // 返回 1 = 适用，exp = {fflags, result}，result 只含低 out_width 位（高位 0）。
  function automatic bit oracle_elem(logic [7:0] op, logic [1:0] sew, logic [2:0] rm,
                                     logic [63:0] x, bit rtz_resolved, output logic [68:0] exp);
    int iw, ow;
    cls_e c;
    logic [63:0] m, mag;
    bit neg;
    exp = '0;
    if (!op_legal(op, sew) || rm > 3'd4) return 0;
    c  = op_class(op);
    iw = in_width(op, sew);
    ow = out_width(op, sew);
    m  = (iw == 64) ? '1 : ((64'h1 << iw) - 1);
    x  = x & m;
    case (c)
      C_I2F: begin
        neg = op[0] & x[iw - 1];
        mag = neg ? (64'(-(x | ~m))) : x;
        exp = o_int2fp(mag, neg, ow, rm);
        return 1;
      end
      C_F2I: begin
        if (op[2:1] == 2'b11) begin
          if (!rtz_resolved) return 0;
          rm = 3'd1;
        end
        exp = o_fp2int(x, iw, ow, op[0], rm);
        return 1;
      end
      C_REC7, C_RSQRT7: begin
        exp = o_estimate7(x, iw, c == C_REC7, rm);
        return 1;
      end
      default: return 0;
    endcase
  endfunction

  // 一个 64 位 VectorCvt 内的元素个数（源、目的里较宽一侧决定）
  function automatic int elems64(logic [7:0] op, logic [1:0] sew);
    int iw, ow, mx;
    iw = in_width(op, sew); ow = out_width(op, sew);
    mx = (iw > ow) ? iw : ow;
    return (mx > 64) ? 0 : 64 / mx;
  endfunction

endpackage
