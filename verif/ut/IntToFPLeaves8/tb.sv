// IntToFPLeaves8 UT —— IntToFP 转换闭包 8 叶双例化差分 + 独立数学 oracle
//
// 覆盖对象（全部纯组合，golden 闭包无一时钟/复位，故本 tb 不驱动时钟）：
//   LZA / IntToFP_prenorm / IntToFP_postnorm{,_1,_2} / IntToFP{,_1,_2}
//
// 三重检查：
//   1) 8 个模块 golden vs <名>_xs 双例化，每向量逐输出比对；
//   2) 独立 oracle：从 (int, sign, long, rm) 用精确 SV 向量算术直接算出
//      IEEE754 结果与 inexact/overflow（规格化、五种 rm 舍入、零/符号/
//      最大有限值/无穷），对 IntToFP{,_1,_2} 三个顶层端到端逐向量核对；
//   3) postnorm 三级另加**任意**直接激励（lzc/is_zero/norm_int 全随机，
//      不限于 prenorm 能产生的组合），榨干输入自由变量的差分覆盖。
//
// oracle 的适用前提：word 有符号（sign=1, long=0）时高 32 位须是 bit31 的
// 符号扩展（well-formed）。golden 对 garbage-upper 输入的 is_zero/pos_lzc
// 看的是**原始** io_int，那是实现契约之外的输入形态，只走差分（两侧本就
// 逐位比对），不进 oracle。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;
  int oracle_checks = 0;

  // 主激励（顶层三级与 prenorm 共用）
  logic [63:0] stim_int;
  logic        stim_sign, stim_long;
  logic [2:0]  stim_rm;
  // LZA 独立激励
  logic [63:0] stim_lza_b;
  // postnorm 三级独立激励（自由变量全打满）
  logic [62:0] stim_pn_norm;
  logic [5:0]  stim_pn_lzc;
  logic        stim_pn_zero, stim_pn_sign;
  logic [2:0]  stim_pn_rm;

  // ---- LZA ----------------------------------------------------------------
  wire [63:0] lza_f_g, lza_f_i;
  LZA    g_lza (.io_b(stim_lza_b), .io_f(lza_f_g));
  LZA_xs i_lza (.io_b(stim_lza_b), .io_f(lza_f_i));

  // ---- prenorm -------------------------------------------------------------
  wire [62:0] pre_norm_g, pre_norm_i;
  wire [5:0]  pre_lzc_g, pre_lzc_i;
  wire        pre_zero_g, pre_zero_i, pre_sign_g, pre_sign_i;
  IntToFP_prenorm g_pre (
    .io_in_int(stim_int), .io_in_sign(stim_sign), .io_in_long(stim_long),
    .io_out_norm_int(pre_norm_g), .io_out_lzc(pre_lzc_g),
    .io_out_is_zero(pre_zero_g), .io_out_sign(pre_sign_g)
  );
  IntToFP_prenorm_xs i_pre (
    .io_in_int(stim_int), .io_in_sign(stim_sign), .io_in_long(stim_long),
    .io_out_norm_int(pre_norm_i), .io_out_lzc(pre_lzc_i),
    .io_out_is_zero(pre_zero_i), .io_out_sign(pre_sign_i)
  );

  // ---- postnorm f32 / f64 / f16（独立激励） --------------------------------
  wire [31:0] pn32_r_g, pn32_r_i;
  wire [4:0]  pn32_f_g, pn32_f_i;
  IntToFP_postnorm g_pn32 (
    .io_in_norm_int(stim_pn_norm), .io_in_lzc(stim_pn_lzc),
    .io_in_is_zero(stim_pn_zero), .io_in_sign(stim_pn_sign), .io_rm(stim_pn_rm),
    .io_result(pn32_r_g), .io_fflags(pn32_f_g)
  );
  IntToFP_postnorm_xs i_pn32 (
    .io_in_norm_int(stim_pn_norm), .io_in_lzc(stim_pn_lzc),
    .io_in_is_zero(stim_pn_zero), .io_in_sign(stim_pn_sign), .io_rm(stim_pn_rm),
    .io_result(pn32_r_i), .io_fflags(pn32_f_i)
  );

  wire [63:0] pn64_r_g, pn64_r_i;
  wire [4:0]  pn64_f_g, pn64_f_i;
  IntToFP_postnorm_1 g_pn64 (
    .io_in_norm_int(stim_pn_norm), .io_in_lzc(stim_pn_lzc),
    .io_in_is_zero(stim_pn_zero), .io_in_sign(stim_pn_sign), .io_rm(stim_pn_rm),
    .io_result(pn64_r_g), .io_fflags(pn64_f_g)
  );
  IntToFP_postnorm_1_xs i_pn64 (
    .io_in_norm_int(stim_pn_norm), .io_in_lzc(stim_pn_lzc),
    .io_in_is_zero(stim_pn_zero), .io_in_sign(stim_pn_sign), .io_rm(stim_pn_rm),
    .io_result(pn64_r_i), .io_fflags(pn64_f_i)
  );

  wire [15:0] pn16_r_g, pn16_r_i;
  wire [4:0]  pn16_f_g, pn16_f_i;
  IntToFP_postnorm_2 g_pn16 (
    .io_in_norm_int(stim_pn_norm), .io_in_lzc(stim_pn_lzc),
    .io_in_is_zero(stim_pn_zero), .io_in_sign(stim_pn_sign), .io_rm(stim_pn_rm),
    .io_result(pn16_r_g), .io_fflags(pn16_f_g)
  );
  IntToFP_postnorm_2_xs i_pn16 (
    .io_in_norm_int(stim_pn_norm), .io_in_lzc(stim_pn_lzc),
    .io_in_is_zero(stim_pn_zero), .io_in_sign(stim_pn_sign), .io_rm(stim_pn_rm),
    .io_result(pn16_r_i), .io_fflags(pn16_f_i)
  );

  // ---- 顶层 f32 / f64 / f16 -------------------------------------------------
  wire [31:0] t32_r_g, t32_r_i;
  wire [4:0]  t32_f_g, t32_f_i;
  IntToFP g_t32 (
    .io_int(stim_int), .io_sign(stim_sign), .io_long(stim_long),
    .io_rm(stim_rm), .io_result(t32_r_g), .io_fflags(t32_f_g)
  );
  IntToFP_xs i_t32 (
    .io_int(stim_int), .io_sign(stim_sign), .io_long(stim_long),
    .io_rm(stim_rm), .io_result(t32_r_i), .io_fflags(t32_f_i)
  );

  wire [63:0] t64_r_g, t64_r_i;
  wire [4:0]  t64_f_g, t64_f_i;
  IntToFP_1 g_t64 (
    .io_int(stim_int), .io_sign(stim_sign), .io_long(stim_long),
    .io_rm(stim_rm), .io_result(t64_r_g), .io_fflags(t64_f_g)
  );
  IntToFP_1_xs i_t64 (
    .io_int(stim_int), .io_sign(stim_sign), .io_long(stim_long),
    .io_rm(stim_rm), .io_result(t64_r_i), .io_fflags(t64_f_i)
  );

  wire [15:0] t16_r_g, t16_r_i;
  wire [4:0]  t16_f_g, t16_f_i;
  IntToFP_2 g_t16 (
    .io_int(stim_int), .io_sign(stim_sign), .io_long(stim_long),
    .io_rm(stim_rm), .io_result(t16_r_g), .io_fflags(t16_f_g)
  );
  IntToFP_2_xs i_t16 (
    .io_int(stim_int), .io_sign(stim_sign), .io_long(stim_long),
    .io_rm(stim_rm), .io_result(t16_r_i), .io_fflags(t16_f_i)
  );

  function automatic [31:0] random32;
    random32 = $urandom;
  endfunction

  // ---------------------------------------------------------------------------
  // 独立 oracle：从整数输入直接算 IEEE754 结果 + fflags。
  // EW = 指数域宽，PREC = 含隐藏位的总精度（f32: 8/24, f64: 11/53, f16: 5/11）。
  // ---------------------------------------------------------------------------
  task automatic cvt_oracle(
    input  int unsigned EW,
    input  int unsigned PREC,
    input  logic [63:0] int_in,
    input  logic        sgn_en,
    input  logic        lng,
    input  logic [2:0]  rm,
    output logic [63:0] result,
    output logic [4:0]  fflags
  );
    logic         in_sign;
    logic [63:0]  in_raw, mag;
    logic [126:0] shifted;
    logic [62:0]  frac;
    logic [52:0]  kept, kept_r, sig_mask;
    logic         rnd, stky, inexact, up, cout, sel_max, ovf;
    logic [10:0]  expo, exp_mask;
    integer       lz, b;
    begin
      in_sign  = sgn_en & (lng ? int_in[63] : int_in[31]);
      in_raw   = (sgn_en & ~lng) ? {{32{int_in[31]}}, int_in[31:0]} : int_in;
      mag      = in_sign ? (~in_raw + 64'd1) : in_raw;
      sig_mask = (53'd1 << (PREC - 1)) - 53'd1;
      exp_mask = (11'd1 << EW) - 11'd1;
      if (int_in == 64'd0) begin
        result = {63'd0, in_sign} << (EW + PREC - 1);
        fflags = 5'b0;
      end else begin
        // 精确 CLZ（well-formed 输入下 mag != 0）
        lz = 0;
        for (b = 0; b < 64; b = b + 1)
          if (mag[b]) lz = 63 - b;
        shifted = {63'd0, mag} << lz;   // 最高 1 落在 bit63，作隐藏位丢掉
        frac = shifted[62:0];
        kept = '0; rnd = 1'b0; stky = 1'b0;
        for (b = 0; b <= 62; b = b + 1) begin
          if (b >= 64 - PREC)     kept[b - (64 - PREC)] = frac[b];
          else if (b == 63 - PREC) rnd = frac[b];
          else                     stky = stky | frac[b];
        end
        inexact = rnd | stky;
        // golden RoundingUnit 的真值表（含 5/6/7 非法编码不增量）
        case (rm)
          3'h0:    up = rnd & (stky | kept[0]);  // RNE
          3'h2:    up = inexact & in_sign;       // RDN
          3'h3:    up = inexact & ~in_sign;      // RUP
          3'h4:    up = rnd;                     // RMM
          default: up = 1'b0;                    // RTZ 及 5/6/7
        endcase
        cout   = up & ((kept & sig_mask) == sig_mask);
        kept_r = (kept + (up ? 53'd1 : 53'd0)) & sig_mask;
        expo   = (11'd63 - 11'(lz)) + 11'(cout) + ((11'd1 << (EW - 1)) - 11'd1);
        // 上溢谓词按 golden 原文形状：f32/f16 阈值比较，f64 全 1 检测
        if (EW == 11)      ovf = &expo;
        else if (EW == 5)  ovf = expo > 11'h1E;
        else               ovf = expo > 11'hFE;
        sel_max = (rm == 3'h1) | (in_sign & (rm == 3'h3)) | (~in_sign & (rm == 3'h2));
        if (ovf)
          result = (64'(in_sign) << (EW + PREC - 1)) |
                   (sel_max ? ((64'(exp_mask - 11'd1) << (PREC - 1)) | 64'(sig_mask))
                            :  (64'(exp_mask) << (PREC - 1)));
        else
          result = (64'(in_sign) << (EW + PREC - 1)) |
                   (64'(expo & exp_mask) << (PREC - 1)) |
                   64'(kept_r & sig_mask);
        fflags = {2'b0, ovf, 1'b0, ovf | inexact};
      end
    end
  endtask

  task automatic oracle_check;
    logic [63:0] exp_r;
    logic [4:0]  exp_f;
    begin
      // word 有符号且高 32 位非符号扩展：不进 oracle（契约外形态，差分管）
      if (stim_sign && !stim_long && (stim_int[63:32] != {32{stim_int[31]}}))
        return;
      oracle_checks++;
      cvt_oracle(8, 24, stim_int, stim_sign, stim_long, stim_rm, exp_r, exp_f);
      if ({t32_r_i, t32_f_i} !== {exp_r[31:0], exp_f}) begin
        errors++;
        if (errors < 12)
          $display("oracle f32 mismatch: int=%h sign=%b long=%b rm=%0d dut=%h/%b exp=%h/%b",
                   stim_int, stim_sign, stim_long, stim_rm,
                   t32_r_i, t32_f_i, exp_r[31:0], exp_f);
      end
      cvt_oracle(11, 53, stim_int, stim_sign, stim_long, stim_rm, exp_r, exp_f);
      if ({t64_r_i, t64_f_i} !== {exp_r, exp_f}) begin
        errors++;
        if (errors < 12)
          $display("oracle f64 mismatch: int=%h sign=%b long=%b rm=%0d dut=%h/%b exp=%h/%b",
                   stim_int, stim_sign, stim_long, stim_rm,
                   t64_r_i, t64_f_i, exp_r, exp_f);
      end
      cvt_oracle(5, 11, stim_int, stim_sign, stim_long, stim_rm, exp_r, exp_f);
      if ({t16_r_i, t16_f_i} !== {exp_r[15:0], exp_f}) begin
        errors++;
        if (errors < 12)
          $display("oracle f16 mismatch: int=%h sign=%b long=%b rm=%0d dut=%h/%b exp=%h/%b",
                   stim_int, stim_sign, stim_long, stim_rm,
                   t16_r_i, t16_f_i, exp_r[15:0], exp_f);
      end
    end
  endtask

  task automatic compare_now;
    begin
      #1;
      vectors++;
      if (lza_f_g !== lza_f_i) begin
        errors++;
        if (errors < 12)
          $display("LZA mismatch: b=%h g=%h i=%h", stim_lza_b, lza_f_g, lza_f_i);
      end
      if ({pre_norm_g, pre_lzc_g, pre_zero_g, pre_sign_g} !==
          {pre_norm_i, pre_lzc_i, pre_zero_i, pre_sign_i}) begin
        errors++;
        if (errors < 12)
          $display("prenorm mismatch: int=%h sign=%b long=%b", stim_int, stim_sign, stim_long);
      end
      if ({pn32_r_g, pn32_f_g} !== {pn32_r_i, pn32_f_i} ||
          {pn64_r_g, pn64_f_g} !== {pn64_r_i, pn64_f_i} ||
          {pn16_r_g, pn16_f_g} !== {pn16_r_i, pn16_f_i}) begin
        errors++;
        if (errors < 12)
          $display("postnorm mismatch: norm=%h lzc=%0d zero=%b sign=%b rm=%0d",
                   stim_pn_norm, stim_pn_lzc, stim_pn_zero, stim_pn_sign, stim_pn_rm);
      end
      if ({t32_r_g, t32_f_g} !== {t32_r_i, t32_f_i} ||
          {t64_r_g, t64_f_g} !== {t64_r_i, t64_f_i} ||
          {t16_r_g, t16_f_g} !== {t16_r_i, t16_f_i}) begin
        errors++;
        if (errors < 12)
          $display("top mismatch: int=%h sign=%b long=%b rm=%0d",
                   stim_int, stim_sign, stim_long, stim_rm);
      end
      oracle_check();
    end
  endtask

  // 施加一组主激励 + 一组随机 LZA/postnorm 独立激励，然后比对
  task automatic drive(input logic [63:0] v, input logic s,
                       input logic l, input logic [2:0] rm);
    begin
      stim_int  = v;
      stim_sign = s;
      stim_long = l;
      stim_rm   = rm;
      randomize_side();
      compare_now();
    end
  endtask

  task automatic randomize_side;
    begin
      case ($urandom_range(0, 3))
        0: stim_lza_b = {random32(), random32()};
        1: stim_lza_b = {random32(), random32()} & {random32(), random32()};
        2: stim_lza_b = 64'd1 << $urandom_range(0, 63);
        default: stim_lza_b = ~(64'd1 << $urandom_range(0, 63));
      endcase
      stim_pn_norm = {random32(), random32()} >> $urandom_range(0, 31);
      stim_pn_lzc  = $urandom_range(0, 63);
      stim_pn_zero = $urandom_range(0, 3) == 0;
      stim_pn_sign = $urandom_range(0, 1);
      stim_pn_rm   = $urandom_range(0, 7);
    end
  endtask

  // word 有符号的 well-formed 64 位装载（高 32 位 = bit31 符号扩展）
  function automatic [63:0] sext32(input logic [31:0] w);
    sext32 = {{32{w[31]}}, w};
  endfunction

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end

    stim_int = '0; stim_sign = 0; stim_long = 0; stim_rm = 0;
    stim_lza_b = '0;
    stim_pn_norm = '0; stim_pn_lzc = '0; stim_pn_zero = 0;
    stim_pn_sign = 0; stim_pn_rm = 0;

    // ---- LZA 定向：全 0 / 全 1 / 走 1 / 走 0 --------------------------------
    for (int k = -1; k < 64; k++) begin
      stim_lza_b = (k < 0) ? 64'd0 : (64'd1 << k);
      compare_now();
      stim_lza_b = (k < 0) ? {64{1'b1}} : ~(64'd1 << k);
      compare_now();
    end

    // ---- 顶层定向边界 --------------------------------------------------------
    // 特殊值 × (sign,long) 全组合 × rm 0..4
    begin : directed
      logic [63:0] corners [0:13];
      corners[0]  = 64'd0;
      corners[1]  = 64'd1;
      corners[2]  = 64'hFFFF_FFFF_FFFF_FFFF;  // 无符号最大 / -1
      corners[3]  = 64'h8000_0000_0000_0000;  // INT64_MIN
      corners[4]  = 64'h7FFF_FFFF_FFFF_FFFF;  // INT64_MAX
      corners[5]  = 64'h0000_0000_FFFF_FFFF;  // UINT32_MAX
      corners[6]  = sext32(32'h8000_0000);    // INT32_MIN
      corners[7]  = sext32(32'h7FFF_FFFF);    // INT32_MAX
      corners[8]  = 64'h0000_0001_0000_0000;  // 2^32（word 视角高位垃圾=0）
      corners[9]  = 64'd65504;                // f16 最大有限值
      corners[10] = 64'd65520;                // f16 上溢阈值附近（half）
      corners[11] = 64'd65535;
      corners[12] = 64'd16777215;             // f32 精确上限 2^24-1
      corners[13] = 64'd16777217;             // f32 首个不可精确（sticky down）
      for (int c = 0; c < 14; c++)
        for (int s = 0; s < 2; s++)
          for (int l = 0; l < 2; l++)
            for (int r = 0; r < 5; r++)
              drive(corners[c], s[0], l[0], r[2:0]);
    end

    // 2 的幂 ±1：每个精度档的舍入边界（exact / half / up / down）
    begin : pow2_sweep
      int ks [0:16];
      ks = '{0, 1, 9, 10, 11, 12, 23, 24, 25, 31, 32, 51, 52, 53, 54, 62, 63};
      for (int i = 0; i < 17; i++) begin
        for (int r = 0; r < 5; r++) begin
          drive(64'd1 << ks[i],                0, 1, r[2:0]);
          drive((64'd1 << ks[i]) + 64'd1,      0, 1, r[2:0]);
          drive((64'd1 << ks[i]) - 64'd1,      0, 1, r[2:0]);
          drive(64'd0 - (64'd1 << ks[i]),      1, 1, r[2:0]);  // 负的 2 的幂
          drive(64'd0 - (64'd1 << ks[i]) + 64'd1, 1, 1, r[2:0]);
        end
      end
    end

    // f16 上溢区扫描（含 RMM/RNE 进位越界）
    for (int v = 65400; v < 65600; v++)
      for (int r = 0; r < 5; r++)
        drive(64'(v), 0, 0, r[2:0]);

    // ---- 随机 ----------------------------------------------------------------
    repeat (NCYCLES) begin
      logic [63:0] v;
      case ($urandom_range(0, 5))
        0: v = {random32(), random32()};                                    // 全随机
        1: v = {random32(), random32()} & {random32(), random32()};         // 稀疏
        2: v = {random32(), random32()} | {random32(), random32()};         // 稠密
        3: v = 64'($urandom_range(0, 65535));                               // 小整数
        4: v = (64'd1 << $urandom_range(0, 63)) + 64'($urandom_range(0, 7)) - 64'd3; // 近 2 的幂
        default: v = sext32(random32());                                    // well-formed word
      endcase
      drive(v, $urandom_range(0, 1), $urandom_range(0, 1), $urandom_range(0, 7));
    end

    $display("IntToFPLeaves8 UT: vectors=%0d oracle_checks=%0d errors=%0d",
             vectors, oracle_checks, errors);
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
