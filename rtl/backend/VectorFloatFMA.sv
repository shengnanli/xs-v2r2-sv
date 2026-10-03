// =============================================================================
// VectorFloatFMA.sv —— 向量浮点乘加单元（a*b ± c，四拍：三级寄存器，第 3 拍组合出结果）
//
// 位置：向量浮点乘加功能单元（VFMA）里每 64 位数据一个。一个 64 位数据块按结果格式并排放
//   1 个 f64 / 2 个 f32 / 4 个 f16，共 7 条"通道"（f64、f32_0、f32_1、f16_0..3）；
//   乘法阵列（Booth-4 + CSA 压缩树，107 位宽）只有一份，各通道占其中互不重叠的一段。
//   Scala：yunsuan/src/main/scala/yunsuan/vector/VectorFloatFMA.scala。
//
// 输入约定：
//   fp_a = vs2，fp_b = vs1，fp_c = vd（旧值）。op_code 是 VfmaOpCode：
//     vfmul 0 / vfmacc 1 / vfnmacc 2 / vfmsac 3 / vfnmsac 4 / vfmadd 5 / vfnmadd 6 / vfmsub 7 / vfnmsub 8。
//     统一成 "a*b + c"：vf*madd/msub 四个先交换 a 与 c；带 n 的把 a 的符号取反；
//     vfnmacc/vfmsac/vfnmadd/vfmsub 把 c 的符号取反；vfmul 把 c 置成 +0。
//   fp_format 是**结果**格式：1=f16 / 2=f32 / 3=f64（0 与 1 同样按 f16 处理）。
//   res_widening（vfwmul / vfwmacc 等）：乘数来自 widen_a / widen_b，格式是结果格式的一半
//     （f32 结果用 f16 源，f64 结果用 f32 源；f16 结果没有加宽）。父模块把源向量的偶数/奇数元素
//     分别摆在 widen_* 的低/高 32 位，uop_idx 选用哪一半。加宽只换 a、b：窄格式的有效数左对齐补 0，
//     指数换算到宽格式的偏置；c 始终是结果格式。
//   fflags：{f16_3, f16_2, f32_1 或 f16_1, f64 或 f32_0 或 f16_0} 各 5 位 {NV, DZ, OF, UF, NX}。
//
// 流水（fire 是第 0 拍有效；fire_s1 / fire_s2 是它打一拍 / 两拍）：
//   §S0  拆操作数、判特殊值；指数比较，把 c 的有效数按指数差右移对齐到乘积（3W+4 位宽的窗口，
//        乘积在窗口低 2W 位之上留 W+3 位给"c 比乘积大"的情形），减法时按位取反；
//        Booth 编码 + CSA 树前 4 层（树内部在第 5 层前打拍，属于 CSA_Nto2With3to2MainPipeline）。
//   §S1  CSA 树余下几层 -> 与对齐后的 c 的低 2W 位做 3:2 -> 107 位加法；c 的高 W+3 位按低位进位
//        选"原值 / 加 1"；拼上右移移出去的保护位得到 3W+5 位的和。和为负则记下并取反；
//        同时准备前导零检测的输入（取反后的和 | "最多左移到指数为最小值"的掩码）。
//   §S2  前导零计数、规格化左移；取出尾数、guard / round / sticky。
//   §S3  舍入、指数修正、溢出 / 下溢 / 不精确判定，与特殊值（NaN / Inf / 0）的结果多选。
//
// 寄存器组织（照 golden，逐个对齐）：
//   * 只有 fire_s1 / fire_s2 带异步复位；其余全部不复位，由 fire / fire_s1 / fire_s2 使能。
//   * 数据类中间量"按格式复用"同一个寄存器：f64 用整段，f32 把两条通道拼起来，f16 把四条拼起来
//     （xs_VfmaSlotPack，高位补 0）。这类寄存器在核里；每条通道自己独占的 1 位标志寄存器在通道模块里。
//   * 4 位的 guard / round / sticky / 和为负 四个寄存器用的是另一种拼法（pack_overlay）：
//     bit3、bit2 恒取 f16_3、f16_2，bit1 = f32 ? f32_1 : f16_1 —— 即使当前是 f64，高位也装着别的通道
//     算出来的无用值。golden 如此，照搬。
//
// 怪癖（照 golden，不"修"）：
//   1. "共用硬件"有两处，都是 f32_1 借 f64 尺寸的移位器、用格式位二选一输入：
//      (a) S0 的右移器：f64 自己另有一个专用右移器，f32_1 走的是第二个 163 位右移器
//          （输入 = is_fp64 ? f64 的数据 : f32_1 的数据，结果只取低 76 位 + sticky）；
//      (b) S2 的左移器：f64 与 f32_1 真正共用一个 164 位左移器（f32_1 取结果低 77 位）。
//      f32_0 与四条 f16 各有专用的移位器。
//   2. 减法标志 is_sub 的寄存器：f64 一个；f32 / f16 每条通道**两个内容相同的副本**
//      （一个给 CSA 的进位输入用，一个给保护位取负用）——Scala 里写了两次 RegEnable。
//   3. sticky 与 sticky_uf 的第 1 级寄存器同样是两个相同副本。
//   4. 舍入模式在 S0 译成 5 个独热位后各自打三拍；RDN 在 S0 还直接参与"a 或 b 为 0"结果的符号。
//   5. tzd（和的尾随零个数）是把和按位反转后存起来、下一拍用同一个前导零电路数出来的。
//      tzd + lzd 的和按前导零计数的位宽截断（f64 8 位、f32 7 位、f16 6 位）后再比较。
//   6. Scala 端口 frs1 / is_frs1 / is_vec / fp_*IsFpCanonicalNAN 在 golden 里已被常量折叠掉
//      （父模块接的是 is_frs1=0、is_vec=1、CanonicalNAN=0），本文件按 golden 的端口表写。
//   7. 结果恰为 0（和为 0）时符号只看 RDN；fflags 给 0。
//   8. 格式寄存器 is_fp64 / is_fp32 逐级各打一拍，处处按"先 fp64、再 fp32、否则 f16"的优先级用；
//      唯一的例外是 S1 的 c 高段加 1 器：f32_1 的加 1 位只看 is_fp32（不被 is_fp64 压住）。
//
// 子模块：BoothEncoderF64F32F16_3（本仓重写）、CSA3to2（本仓重写）、
//   CSA_Nto2With3to2MainPipeline（27->2 压缩树，内含一级寄存器；本仓未重写，UT / FM 两侧都用 golden 原件）。
// =============================================================================

// 带 sticky 的对数右移器：从低位到高位逐级移 1 / 2 / 4 / ...，被移出去的位或进 sticky。
module xs_VfmaRightShiftSticky #(
  parameter int unsigned W     = 163,
  parameter int unsigned AMT_W = 8
) (
  input  logic [W-1:0]     src,
  input  logic [AMT_W-1:0] amount,
  output logic [W-1:0]     shifted,
  output logic             sticky
);
  always_comb begin
    shifted = src;
    sticky  = 1'b0;
    for (int unsigned i = 0; i < AMT_W; i++) begin
      if (amount[i]) begin
        // 左移 W - 2^i 位后只剩最低的 2^i 位：这一级要移出去的就是它们
        sticky  = sticky | (|(shifted << (W - (1 << i))));
        shifted = shifted >> (1 << i);
      end
    end
  end
endmodule

// 前导零计数：从最高位数起连续 0 的个数；全 0 时等于位宽 W。
module xs_VfmaLzd #(
  parameter int unsigned W     = 164,
  parameter int unsigned CNT_W = 8
) (
  input  logic [W-1:0]     in,
  output logic [CNT_W-1:0] count
);
  always_comb begin
    count = CNT_W'(W);
    for (int unsigned i = 0; i < W; i++) begin
      if (in[i]) count = CNT_W'(W - 1 - i);
    end
  end
endmodule

// 按格式把各通道的同名字段拼进一个共用寄存器的次态：
//   f64 -> lane 0 占 [FW64-1:0]；f32 -> lane 1、2 各占 FW32 位；f16 -> lane 3..6 各占 FW16 位；高位补 0。
module xs_VfmaSlotPack #(
  parameter int unsigned OUT_W = 164,
  parameter int unsigned FW64  = 164,
  parameter int unsigned FW32  = 77,
  parameter int unsigned FW16  = 38
) (
  input  logic                  is_fp64,
  input  logic                  is_fp32,
  input  logic [6:0][OUT_W-1:0] lane_val,   // 每条通道的值，零扩展到 OUT_W
  output logic [OUT_W-1:0]      packed_val
);
  always_comb begin
    packed_val = '0;
    if (is_fp64) begin
      packed_val[FW64-1:0] = lane_val[0][FW64-1:0];
    end else if (is_fp32) begin
      for (int unsigned k = 0; k < 2; k++) packed_val[k*FW32 +: FW32] = lane_val[1+k][FW32-1:0];
    end else begin
      for (int unsigned k = 0; k < 4; k++) packed_val[k*FW16 +: FW16] = lane_val[3+k][FW16-1:0];
    end
  end
endmodule

// 拆一个乘数操作数（a 或 b）：取符号、带隐含位的有效数、修正后的指数（次正规数的指数按 1 算）。
// use_narrow=1 时改从半宽格式的 narrow_word 取：有效数左对齐补 0，指数换算到本格式的偏置
// （{最高位, 3 个最高位的反, 其余位}，等价于 加上两个偏置之差）。
module xs_VfmaUnpack #(
  parameter int unsigned SIG_W     = 53,
  parameter int unsigned EXP_W     = 11,
  parameter bit          HAS_WIDEN = 1'b1,
  parameter int unsigned N_SIG_W   = 24,
  parameter int unsigned N_EXP_W   = 8
) (
  input  logic [SIG_W+EXP_W-1:0]     word,
  input  logic [N_SIG_W+N_EXP_W-1:0] narrow_word,
  input  logic                       use_narrow,
  output logic                       sign,
  output logic [SIG_W-1:0]           sig,
  output logic [EXP_W-1:0]           exp_fix,
  output logic                       exp_all_ones
);
  logic [EXP_W-1:0] exp;
  logic [EXP_W-1:0] own_exp_fix;
  assign exp         = word[SIG_W+EXP_W-2 : SIG_W-1];
  assign own_exp_fix = {exp[EXP_W-1:1], ~(|exp) | exp[0]};

  if (HAS_WIDEN) begin : g_widen
    logic [N_EXP_W-1:0] n_exp;
    logic [N_EXP_W-1:0] n_exp_fix;
    assign n_exp     = narrow_word[N_SIG_W+N_EXP_W-2 : N_SIG_W-1];
    assign n_exp_fix = {n_exp[N_EXP_W-1:1], ~(|n_exp) | n_exp[0]};

    assign sign         = use_narrow ? narrow_word[N_SIG_W+N_EXP_W-1] : word[SIG_W+EXP_W-1];
    assign sig          = use_narrow ? {|n_exp, narrow_word[N_SIG_W-2:0], {(SIG_W-N_SIG_W){1'b0}}}
                                     : {|exp, word[SIG_W-2:0]};
    assign exp_fix      = use_narrow ? {n_exp_fix[N_EXP_W-1], {3{~n_exp_fix[N_EXP_W-1]}}, n_exp_fix[N_EXP_W-2:0]}
                                     : own_exp_fix;
    assign exp_all_ones = use_narrow ? (&n_exp) : (&exp);
  end else begin : g_no_widen
    assign sign         = word[SIG_W+EXP_W-1];
    assign sig          = {|exp, word[SIG_W-2:0]};
    assign exp_fix      = own_exp_fix;
    assign exp_all_ones = &exp;
  end
endmodule

// -----------------------------------------------------------------------------
// 一条通道（一个浮点元素）的全部逻辑。三种格式共用这一份，只差位宽参数。
// 与其它通道共用寄存器 / 共用硬件的量走端口：*_d 是送去寄存的次态，*_q 是寄存器里属于本通道的那一段。
// 本通道独占的 1 位标志寄存器（符号、sticky、特殊值标志等）在模块内，三级各一份。
// -----------------------------------------------------------------------------
module xs_VfmaLane #(
  parameter  int unsigned SIG_W     = 53,   // 有效数位宽（含隐含位）
  parameter  int unsigned EXP_W     = 11,
  parameter  bit          HAS_WIDEN = 1'b1,
  parameter  int unsigned N_SIG_W   = 24,   // 加宽源（半宽格式）的有效数 / 指数位宽
  parameter  int unsigned N_EXP_W   = 8,
  localparam int unsigned FLT_W     = SIG_W + EXP_W,
  localparam int unsigned NFLT_W    = N_SIG_W + N_EXP_W,
  localparam int unsigned RSH_W     = 3 * SIG_W + 4,       // c 的对齐窗口
  localparam int unsigned CAL_W     = RSH_W - 1,           // 对齐后的 c：符号 + 窗口去掉最低两位
  localparam int unsigned ADD_W     = 3 * SIG_W + 5,       // 和（含符号位）
  localparam int unsigned INV_W     = ADD_W - 1,           // 和的绝对值
  localparam int unsigned AMT_W     = $clog2(RSH_W + 1),   // 右移量位宽
  localparam int unsigned LZD_W     = $clog2(ADD_W + 1)    // 前导零计数位宽
) (
  input  logic               clock,
  input  logic               fire,
  input  logic               fire_s1,
  input  logic               fire_s2,

  // ---- S0 ----
  input  logic [FLT_W-1:0]   a_word,         // 已按操作码交换 / 改符号
  input  logic [FLT_W-1:0]   b_word,
  input  logic [FLT_W-1:0]   c_word,         // 已按操作码交换 / 改符号；vfmul 时为 +0
  input  logic [NFLT_W-1:0]  a_narrow,       // 加宽源（已改符号）
  input  logic [NFLT_W-1:0]  b_narrow,
  input  logic               use_narrow,
  input  logic               is_vfmul,
  input  logic               rm_rdn_s0,
  output logic [SIG_W-1:0]   sig_a,          // 送 Booth 编码器
  output logic [SIG_W-1:0]   sig_b,
  output logic [RSH_W-1:0]   rsh_src,        // 右移器在通道外（f32_1 借 f64 尺寸的）
  output logic [AMT_W-1:0]   rsh_amount,
  input  logic [RSH_W-1:0]   rsh_shifted,
  input  logic               rsh_sticky,
  output logic               is_sub_d,
  output logic               guard_d,
  output logic               round_d,
  output logic               sticky_d,
  output logic [CAL_W-1:0]   c_aligned_d,
  output logic [EXP_W:0]     exp_greater_d,
  output logic [EXP_W:0]     lshift_max_d,
  output logic [FLT_W-1:0]   zero_result_d,

  // ---- S1 ----
  input  logic               is_sub_q,
  input  logic               guard_q,
  input  logic               round_q,
  input  logic               sticky_q,
  input  logic [CAL_W-1:0]   c_aligned_q,
  input  logic [EXP_W:0]     lshift_max_q,
  input  logic [2*SIG_W:0]   sum_low,        // 乘积 + c 低 2W 位（最高位是进位）
  input  logic [SIG_W+2:0]   c_high_plus1,   // c 的高 W+3 位加 1
  output logic               adder_neg_d,
  output logic [ADD_W-1:0]   adder_d,
  output logic [ADD_W-1:0]   tzd_src_d,
  output logic [INV_W-1:0]   lzd_src_d,
  output logic               mask_valid_d,

  // ---- S2 ----
  input  logic               adder_neg_s1_q,
  input  logic [ADD_W-1:0]   adder_q,
  input  logic [ADD_W-1:0]   tzd_src_q,
  input  logic [INV_W-1:0]   lzd_src_q,
  input  logic               mask_valid_q,
  output logic [ADD_W-1:0]   lsh_src,        // 左移器在通道外（f64 与 f32_1 共用）
  output logic [LZD_W-1:0]   lsh_amount,
  input  logic [ADD_W-1:0]   lsh_shifted,
  output logic [SIG_W-2:0]   frac_d,
  output logic               is_fix_d,
  output logic [LZD_W-1:0]   lshift_value_d,

  // ---- S3 ----
  input  logic               adder_neg_s2_q,
  input  logic [SIG_W-2:0]   frac_q,
  input  logic               is_fix_q,
  input  logic [LZD_W-1:0]   lshift_value_q,
  input  logic [EXP_W:0]     exp_greater_q,
  input  logic [FLT_W-1:0]   zero_result_q,
  input  logic               rm_rne,
  input  logic               rm_rtz,
  input  logic               rm_rdn,
  input  logic               rm_rup,
  input  logic               rm_rmm,
  output logic [FLT_W-1:0]   result,
  output logic [4:0]         fflags
);
  localparam int unsigned BIAS      = (1 << (EXP_W - 1)) - 1;
  localparam int unsigned RSH_BASIC = SIG_W + 3;   // 指数相等时 c 相对窗口最高位的右移量

  // ===========================================================================
  // §S0 拆操作数、特殊值判定、指数比较与 c 的对齐
  // ===========================================================================
  logic             sign_a, sign_b, sign_c, sign_ab;
  logic [EXP_W-1:0] exp_a_fix, exp_b_fix, exp_c, exp_c_fix;
  logic             exp_a_ones, exp_b_ones, exp_c_ones;
  logic [SIG_W-1:0] sig_c;

  xs_VfmaUnpack #(.SIG_W(SIG_W), .EXP_W(EXP_W), .HAS_WIDEN(HAS_WIDEN), .N_SIG_W(N_SIG_W), .N_EXP_W(N_EXP_W)) u_unpack_a (
    .word         (a_word),
    .narrow_word  (a_narrow),
    .use_narrow   (use_narrow),
    .sign         (sign_a),
    .sig          (sig_a),
    .exp_fix      (exp_a_fix),
    .exp_all_ones (exp_a_ones)
  );
  xs_VfmaUnpack #(.SIG_W(SIG_W), .EXP_W(EXP_W), .HAS_WIDEN(HAS_WIDEN), .N_SIG_W(N_SIG_W), .N_EXP_W(N_EXP_W)) u_unpack_b (
    .word         (b_word),
    .narrow_word  (b_narrow),
    .use_narrow   (use_narrow),
    .sign         (sign_b),
    .sig          (sig_b),
    .exp_fix      (exp_b_fix),
    .exp_all_ones (exp_b_ones)
  );

  assign sign_ab    = sign_a ^ sign_b;
  assign sign_c     = c_word[FLT_W-1];
  assign exp_c      = c_word[FLT_W-2 : SIG_W-1];
  assign exp_c_fix  = {exp_c[EXP_W-1:1], ~(|exp_c) | exp_c[0]};
  assign exp_c_ones = &exp_c;
  assign sig_c      = {|exp_c, c_word[SIG_W-2:0]};
  assign is_sub_d   = sign_ab ^ sign_c;

  // ---- 特殊值 ----
  logic a_is_zero, b_is_zero, c_is_zero;
  logic a_is_nan, b_is_nan, c_is_nan;
  logic a_is_snan, b_is_snan, c_is_snan;
  logic a_is_inf, b_is_inf, c_is_inf;
  assign a_is_zero = ~(|sig_a);
  assign b_is_zero = ~(|sig_b);
  assign c_is_zero = ~(|sig_c);
  assign a_is_nan  = exp_a_ones & (|sig_a[SIG_W-2:0]);
  assign b_is_nan  = exp_b_ones & (|sig_b[SIG_W-2:0]);
  assign c_is_nan  = exp_c_ones & (|sig_c[SIG_W-2:0]);
  assign a_is_snan = exp_a_ones & ~sig_a[SIG_W-2] & (|sig_a[SIG_W-3:0]);
  assign b_is_snan = exp_b_ones & ~sig_b[SIG_W-2] & (|sig_b[SIG_W-3:0]);
  assign c_is_snan = exp_c_ones & ~sig_c[SIG_W-2] & (|sig_c[SIG_W-3:0]);
  assign a_is_inf  = exp_a_ones & ~(|sig_a[SIG_W-2:0]);
  assign b_is_inf  = exp_b_ones & ~(|sig_b[SIG_W-2:0]);
  assign c_is_inf  = exp_c_ones & ~(|sig_c[SIG_W-2:0]);

  logic has_zero_d, has_nan_d, has_nan_nv_d, has_inf_d, has_inf_nv_d, inf_sign_d, ab_zero_d;
  logic inf_times_zero;
  assign inf_times_zero = (a_is_inf & b_is_zero) | (a_is_zero & b_is_inf);
  assign has_zero_d     = a_is_zero | b_is_zero | c_is_zero;
  assign has_nan_d      = a_is_nan | b_is_nan | c_is_nan;
  assign has_nan_nv_d   = a_is_snan | b_is_snan | c_is_snan | inf_times_zero;
  assign has_inf_d      = a_is_inf | b_is_inf | c_is_inf;
  assign has_inf_nv_d   = inf_times_zero | (c_is_inf & (a_is_inf | b_is_inf) & (sign_c ^ sign_ab));   // inf - inf
  assign inf_sign_d     = (a_is_inf | b_is_inf) ? sign_ab : sign_c;
  assign ab_zero_d      = a_is_zero | b_is_zero;

  // a 或 b 为 0 时结果就是 c；c 也为 0 时符号按 IEEE：同号取该号，异号只有 RDN 得 -0；vfmul 取乘积符号。
  logic zero_result_sign;
  assign zero_result_sign = c_is_zero ? (is_vfmul ? sign_ab : ((sign_ab & sign_c) | (rm_rdn_s0 & (sign_ab ^ sign_c))))
                                      : sign_c;
  assign zero_result_d    = {zero_result_sign, c_word[FLT_W-2:0]};

  // ---- 指数比较：rshift_value = Ea + Eb - bias + (W+3) - Ec，补码，EXP_W+2 位不会溢出 ----
  logic [EXP_W+1:0] exp_ab;         // 乘积指数（已加上窗口基准）
  logic [EXP_W+1:0] rshift_value;   // c 相对窗口最高位要右移的位数（可负）
  logic             c_too_big;      // <= 0：c 比窗口还高，不移，乘积全落在 sticky 之下……其实是 c 占满窗口顶
  logic             c_too_small;    // > 窗口宽：c 整个移出窗口，只剩 sticky
  logic             c_medium;
  assign exp_ab       = (EXP_W+2)'(exp_a_fix) + (EXP_W+2)'(exp_b_fix) + (EXP_W+2)'(RSH_BASIC) - (EXP_W+2)'(BIAS);
  assign rshift_value = exp_ab - (EXP_W+2)'(exp_c_fix);
  assign c_too_big    = rshift_value[EXP_W+1] | ~(|rshift_value);
  assign c_too_small  = ~rshift_value[EXP_W+1] & (rshift_value[EXP_W:0] > (EXP_W+1)'(RSH_W));
  assign c_medium     = ~c_too_big & ~c_too_small;

  assign rsh_src    = {sig_c, {(RSH_W-SIG_W){1'b0}}};
  assign rsh_amount = rshift_value[AMT_W-1:0];

  // 窗口最低两位是 guard / round，再往下的并进 sticky
  assign guard_d  = c_medium & rsh_shifted[1];
  assign round_d  = c_medium & rsh_shifted[0];
  assign sticky_d = c_medium ? rsh_sticky : (~c_too_big & (|sig_c));

  logic [RSH_W-3:0] c_shifted;
  assign c_shifted   = c_medium ? rsh_shifted[RSH_W-1:2] : (c_too_big ? rsh_src[RSH_W-1:2] : '0);
  assign c_aligned_d = {is_sub_d, c_shifted ^ {(RSH_W-2){is_sub_d}}};   // 减法：按位取反，欠的 +1 在 S1 补

  // 结果指数的基准取 max(乘积指数, c 指数)；规格化左移不能超过"基准 - 1"（再多指数就小于 1）
  assign exp_greater_d = c_too_big ? {1'b0, exp_c_fix} : exp_ab[EXP_W:0];
  assign lshift_max_d  = c_too_big ? {1'b0, EXP_W'(exp_c_fix - 1'b1)} : (EXP_W+1)'(exp_ab[EXP_W:0] - 1'b1);

  // ---- S0 级独占寄存器（fire 使能，不复位）----
  logic sign_c_s0_q, sign_ab_s0_q;
  logic has_zero_s0_q, has_nan_s0_q, has_nan_nv_s0_q, has_inf_s0_q, has_inf_nv_s0_q, inf_sign_s0_q, ab_zero_s0_q;
  always_ff @(posedge clock) begin
    if (fire) begin
      sign_c_s0_q     <= sign_c;
      sign_ab_s0_q    <= sign_ab;
      has_zero_s0_q   <= has_zero_d;
      has_nan_s0_q    <= has_nan_d;
      has_nan_nv_s0_q <= has_nan_nv_d;
      has_inf_s0_q    <= has_inf_d;
      has_inf_nv_s0_q <= has_inf_nv_d;
      inf_sign_s0_q   <= inf_sign_d;
      ab_zero_s0_q    <= ab_zero_d;
    end
  end

  // ===========================================================================
  // §S1 拼出 3W+5 位的和；判负、取反、算左移上限掩码
  // ===========================================================================
  // 最低两位：右移移出去的 guard / round。减法时 c 是取反表示，{g, r, s} 整体取负后取高两位；
  // 取负产生的进位（g = r = s = 0 时）由核里塞进 CSA 的进位输入。
  logic [2:0] grs_negated;
  logic [1:0] adder_low2;
  assign grs_negated = ~{guard_q, round_q, sticky_q} + 3'd1;
  assign adder_low2  = is_sub_q ? grs_negated[2:1] : {guard_q, round_q};

  // 高 W+3 位：c 的高段，按低 2W 位加法的进位选"原值 / 加 1"
  logic [SIG_W+2:0] c_high;
  logic [ADD_W-1:0] adder;
  assign c_high = c_aligned_q[CAL_W-1 -: SIG_W+3];
  assign adder  = {sum_low[2*SIG_W] ? c_high_plus1 : c_high, sum_low[2*SIG_W-1:0], adder_low2};

  logic [INV_W-1:0] adder_inv;      // 和的绝对值（负数这里只取反，欠的 +1 在 S3 的舍入里补）
  assign adder_neg_d = adder[ADD_W-1];
  assign adder_inv   = adder_neg_d ? ~adder[INV_W-1:0] : adder[INV_W-1:0];

  // 左移上限掩码：从最高位数起第 lshift_max 位及以下全 1。并进去以后前导零计数自然不超过上限。
  logic             lshift_max_overflow;   // 上限超出计数位宽：等于不设限
  logic [INV_W-1:0] lshift_mask;
  if (EXP_W + 1 > LZD_W) begin : g_max_hi
    assign lshift_max_overflow = |lshift_max_q[EXP_W:LZD_W];
  end else begin : g_no_max_hi
    assign lshift_max_overflow = 1'b0;
  end
  assign lshift_mask  = lshift_max_overflow ? '0 : ({INV_W{1'b1}} >> lshift_max_q[LZD_W-1:0]);
  assign lzd_src_d    = adder_inv | lshift_mask;
  assign mask_valid_d = (lzd_src_d == lshift_mask);   // 和的最高有效位没越过上限：左移会被上限截住
  assign adder_d      = adder;
  for (genvar i = 0; i < ADD_W; i++) begin : g_reverse
    assign tzd_src_d[i] = adder[ADD_W-1-i];
  end

  // ---- S1 级独占寄存器（fire_s1 使能，不复位）----
  logic sign_result_s1_q, sticky_s1_q, sticky_uf_s1_q, result_zero_s1_q;
  logic has_zero_s1_q, has_nan_s1_q, has_nan_nv_s1_q, has_inf_s1_q, has_inf_nv_s1_q, inf_sign_s1_q, ab_zero_s1_q;
  always_ff @(posedge clock) begin
    if (fire_s1) begin
      sign_result_s1_q <= adder_neg_d ? sign_c_s0_q : sign_ab_s0_q;
      sticky_s1_q      <= sticky_q;
      sticky_uf_s1_q   <= sticky_q;
      result_zero_s1_q <= ~(|adder);
      has_zero_s1_q    <= has_zero_s0_q;
      has_nan_s1_q     <= has_nan_s0_q;
      has_nan_nv_s1_q  <= has_nan_nv_s0_q;
      has_inf_s1_q     <= has_inf_s0_q;
      has_inf_nv_s1_q  <= has_inf_nv_s0_q;
      inf_sign_s1_q    <= inf_sign_s0_q;
      ab_zero_s1_q     <= ab_zero_s0_q;
    end
  end

  // ===========================================================================
  // §S2 前导零计数、规格化左移、取尾数与舍入位
  // ===========================================================================
  logic [LZD_W-1:0] tzd;   // 和的尾随零个数（对反转后的和数前导零）
  logic [LZD_W-1:0] lzd;   // |和| 并上上限掩码后的前导零个数 = 实际左移量
  xs_VfmaLzd #(.W(ADD_W), .CNT_W(LZD_W)) u_tzd (
    .in    (tzd_src_q),
    .count (tzd)
  );
  xs_VfmaLzd #(.W(INV_W), .CNT_W(LZD_W)) u_lzd (
    .in    (lzd_src_q),
    .count (lzd)
  );
  assign lsh_src        = adder_q;
  assign lsh_amount     = lzd;
  assign lshift_value_d = lzd;

  // 左移的是没取反的和；负数只把高 W+4 位（尾数 + 舍入位所在段）取反
  logic [ADD_W-1:0] shifted_inv;
  assign shifted_inv = {lsh_shifted[ADD_W-1 -: SIG_W+4] ^ {(SIG_W+4){adder_neg_s1_q}}, lsh_shifted[ADD_W-SIG_W-5:0]};

  // tzd + lzd == |和| 的位宽：|和| 只有一个 1（负数取反前是 100..0 之类），取反表示会差一位，少移一位修正
  logic [LZD_W-1:0] tzd_plus_lzd;
  logic [INV_W-1:0] normalized;
  assign tzd_plus_lzd = tzd + lzd;
  assign is_fix_d     = (tzd_plus_lzd == LZD_W'(INV_W));
  assign normalized   = is_fix_d ? shifted_inv[ADD_W-1:1] : shifted_inv[ADD_W-2:0];
  assign frac_d       = normalized[INV_W-2 -: SIG_W-1];   // 最高位是隐含位，其后 W-1 位尾数

  // ---- S2 级独占寄存器（fire_s2 使能，不复位）----
  logic sign_result_s2_q, sticky_s2_q, sticky_uf_s2_q, result_zero_s2_q;
  logic guard_lsh_s2_q, round_lsh_s2_q, round_uf_lsh_s2_q, exp_is_min_s2_q;
  logic has_zero_s2_q, has_nan_s2_q, has_nan_nv_s2_q, has_inf_s2_q, has_inf_nv_s2_q, inf_sign_s2_q, ab_zero_s2_q;
  always_ff @(posedge clock) begin
    if (fire_s2) begin
      sign_result_s2_q  <= sign_result_s1_q;
      // sticky：舍入位以下还有 1。右移时已有的，或者和的尾随零不够多
      sticky_s2_q       <= sticky_s1_q    | (tzd_plus_lzd < LZD_W'(INV_W - SIG_W - 2));
      sticky_uf_s2_q    <= sticky_uf_s1_q | (tzd_plus_lzd < LZD_W'(INV_W - SIG_W - 3));   // 下溢判定用：低一位
      guard_lsh_s2_q    <= normalized[INV_W-1-SIG_W];
      round_lsh_s2_q    <= normalized[INV_W-2-SIG_W];
      round_uf_lsh_s2_q <= normalized[INV_W-3-SIG_W];
      // 左移被上限截住且隐含位仍是 0：结果是次正规数，指数字段为 0
      exp_is_min_s2_q   <= ~normalized[INV_W-1] & mask_valid_q & ~is_fix_d;
      result_zero_s2_q  <= result_zero_s1_q;
      has_zero_s2_q     <= has_zero_s1_q;
      has_nan_s2_q      <= has_nan_s1_q;
      has_nan_nv_s2_q   <= has_nan_nv_s1_q;
      has_inf_s2_q      <= has_inf_s1_q;
      has_inf_nv_s2_q   <= has_inf_nv_s1_q;
      inf_sign_s2_q     <= inf_sign_s1_q;
      ab_zero_s2_q      <= ab_zero_s1_q;
    end
  end

  // ===========================================================================
  // §S3 舍入、指数、标志与结果多选（组合）
  // ===========================================================================
  // 负数是"取反"表示，真值 = 取反 + 1。这个 +1 从 sticky 往上传：sticky 以下全 0 时才会进到 round，
  // round 也为 1 才进到 guard；guard / round / sticky 全 0 时一路进到尾数（见 round_up 最后一项）。
  logic round_bit, guard_bit, round_uf_bit, guard_uf_bit;
  assign round_bit    = adder_neg_s2_q ? (round_lsh_s2_q ^ ~sticky_s2_q) : round_lsh_s2_q;
  assign guard_bit    = adder_neg_s2_q ? (guard_lsh_s2_q ^ (~sticky_s2_q & round_lsh_s2_q)) : guard_lsh_s2_q;
  assign guard_uf_bit = round_bit;
  assign round_uf_bit = adder_neg_s2_q ? (round_uf_lsh_s2_q ^ ~sticky_uf_s2_q) : round_uf_lsh_s2_q;

  logic inexact;
  logic round_up, round_up_uf;
  assign inexact  = guard_bit | round_bit | sticky_s2_q;
  assign round_up = (rm_rne & guard_bit & (frac_q[0] | round_bit | sticky_s2_q))
                  | (rm_rdn & sign_result_s2_q & inexact)
                  | (rm_rup & ~sign_result_s2_q & inexact)
                  | (rm_rmm & guard_bit)
                  | (adder_neg_s2_q & ~guard_bit & ~round_bit & ~sticky_s2_q);
  // 下溢判定要看"指数不受限时"的舍入：舍入位置低一位
  assign round_up_uf = (rm_rne & guard_uf_bit & (guard_bit | round_uf_bit | sticky_uf_s2_q))
                     | (rm_rdn & sign_result_s2_q & (guard_uf_bit | round_uf_bit | sticky_uf_s2_q))
                     | (rm_rup & ~sign_result_s2_q & (guard_uf_bit | round_uf_bit | sticky_uf_s2_q))
                     | (rm_rmm & guard_uf_bit);

  logic             exp_carry;      // 舍入进位进到指数
  logic [SIG_W-2:0] frac_rounded;
  assign exp_carry    = (&frac_q) & round_up;
  assign frac_rounded = round_up ? (frac_q + 1'b1) : frac_q;

  logic [EXP_W:0]   exp_value;      // 基准指数 - 左移量 (+1)
  logic             exp_overflow;
  logic [EXP_W-1:0] exp_result;
  assign exp_value    = exp_greater_q - (EXP_W+1)'(lshift_value_q) + (EXP_W+1)'(exp_carry | is_fix_q);
  assign exp_overflow = exp_value[EXP_W] | (&exp_value[EXP_W-1:0]);
  assign exp_result   = exp_is_min_s2_q ? EXP_W'(exp_carry) : exp_value[EXP_W-1:0];

  logic underflow;
  assign underflow = inexact & exp_is_min_s2_q & (~exp_carry | ~(guard_bit & round_up_uf));

  logic [FLT_W-1:0] normal_result;
  logic             has_zero;
  logic             overflow_to_max;   // 溢出时按舍入方向给最大规格化数而不是无穷
  assign normal_result   = {sign_result_s2_q, exp_result, frac_rounded};
  assign has_zero        = has_zero_s2_q | result_zero_s2_q;
  assign overflow_to_max = rm_rtz | (rm_rdn & ~sign_result_s2_q) | (rm_rup & sign_result_s2_q);

  localparam logic [FLT_W-1:0] QNAN        = {1'b0, {(EXP_W+1){1'b1}}, {(SIG_W-2){1'b0}}};
  localparam logic [FLT_W-2:0] INF_MAG     = {{EXP_W{1'b1}}, {(SIG_W-1){1'b0}}};
  localparam logic [FLT_W-2:0] MAX_MAG     = {{(EXP_W-1){1'b1}}, 1'b0, {(SIG_W-1){1'b1}}};
  localparam logic [4:0]       FLAG_NV     = 5'b10000;
  localparam logic [4:0]       FLAG_OF_NX  = 5'b00101;

  always_comb begin
    if (has_nan_s2_q) begin
      result = QNAN;
      fflags = has_nan_nv_s2_q ? FLAG_NV : 5'b0;
    end else if (has_inf_s2_q) begin
      result = has_inf_nv_s2_q ? QNAN : {inf_sign_s2_q, INF_MAG};
      fflags = has_inf_nv_s2_q ? FLAG_NV : 5'b0;
    end else if (exp_overflow) begin
      result = {sign_result_s2_q, overflow_to_max ? MAX_MAG : INF_MAG};
      fflags = FLAG_OF_NX;
    end else if (has_zero) begin
      if (ab_zero_s2_q) begin
        result = zero_result_q;
        fflags = 5'b0;
      end else if (result_zero_s2_q) begin
        result = {rm_rdn, {(FLT_W-1){1'b0}}};
        fflags = 5'b0;
      end else begin
        result = normal_result;
        fflags = {3'b0, underflow, inexact};
      end
    end else begin
      result = normal_result;
      fflags = {3'b0, underflow, inexact};
    end
  end
endmodule

module xs_VectorFloatFMA_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        fire,
  input  logic [63:0] fp_a,
  input  logic [63:0] fp_b,
  input  logic [63:0] fp_c,
  input  logic        uop_idx,
  input  logic [63:0] widen_a,
  input  logic [63:0] widen_b,
  input  logic [2:0]  round_mode,
  input  logic [1:0]  fp_format,
  input  logic [3:0]  op_code,
  input  logic        res_widening,
  output logic [63:0] fp_result,
  output logic [19:0] fflags
);
  // ---------------------------------------------------------------------------
  // 通道表。通道号：0 = f64；1、2 = f32_0、f32_1；3..6 = f16_0..3。
  // "槽位"是通道在同格式里的序号，决定它在 64 位数据 / 共用寄存器里的位置。
  // ---------------------------------------------------------------------------
  localparam int unsigned NUM_LANE = 7;
  localparam int unsigned LANE_SIG_W   [NUM_LANE] = '{53, 24, 24, 11, 11, 11, 11};
  localparam int unsigned LANE_EXP_W   [NUM_LANE] = '{11,  8,  8,  5,  5,  5,  5};
  localparam int unsigned LANE_SLOT    [NUM_LANE] = '{ 0,  0,  1,  0,  1,  2,  3};
  // 有效数在 Booth 编码器 53 位输入里的起始位 / 乘积在 107 位树里的起始位 / c 高段在 59 位加 1 器里的起始位
  localparam int unsigned LANE_SIG_LSB [NUM_LANE] = '{ 0,  0, 29,  0, 13, 29, 42};
  localparam int unsigned LANE_SUM_LSB [NUM_LANE] = '{ 0,  0, 58,  0, 26, 58, 84};
  localparam int unsigned LANE_CHI_LSB [NUM_LANE] = '{ 0,  0, 32,  0, 15, 30, 45};

  localparam int unsigned SUM_W  = 107;   // 压缩树宽度 = 2*53 + 1
  localparam int unsigned CHI_W  = 59;    // c 高段加 1 器宽度（f32：27 + 5 + 27）
  // f64 通道的各字段宽度 = 共用寄存器宽度
  localparam int unsigned RSH_W  = 163;
  localparam int unsigned CAL_W  = 162;
  localparam int unsigned ADD_W  = 164;
  localparam int unsigned INV_W  = 163;

  // 当前格式下哪些通道在用
  function automatic logic [NUM_LANE-1:0] active_lanes(input logic is_fp64, input logic is_fp32);
    return is_fp64 ? 7'b000_0001 : (is_fp32 ? 7'b000_0110 : 7'b111_1000);
  endfunction

  // 4 位"叠放"拼法（guard / round / sticky / 和为负）：高位不随格式清 0，见文件头。
  function automatic logic [3:0] pack_overlay(input logic is_fp64, input logic is_fp32,
                                              input logic [NUM_LANE-1:0] lane_bit);
    return {lane_bit[6],
            lane_bit[5],
            is_fp32 ? lane_bit[2] : lane_bit[4],
            is_fp64 ? lane_bit[0] : (is_fp32 ? lane_bit[1] : lane_bit[3])};
  endfunction

  // ===========================================================================
  // 有效位链与逐级的格式 / 舍入模式
  // ===========================================================================
  logic fire_s1, fire_s2;   // 只有这两个寄存器带（异步）复位；值变化时才翻转（门控写法照 golden）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fire_s1 <= 1'b0;
      fire_s2 <= 1'b0;
    end else begin
      if (fire | fire_s1)    fire_s1 <= fire;
      if (fire_s1 | fire_s2) fire_s2 <= fire_s1;
    end
  end

  logic is_fp64, is_fp32;
  assign is_fp64 = (fp_format == 2'd3);
  assign is_fp32 = (fp_format == 2'd2);

  logic [4:0] rm_onehot;   // {RMM, RUP, RDN, RTZ, RNE}
  assign rm_onehot = {round_mode == 3'd4, round_mode == 3'd3, round_mode == 3'd2,
                      round_mode == 3'd1, round_mode == 3'd0};

  logic       is_fp64_s0_q, is_fp64_s1_q, is_fp64_s2_q;
  logic       is_fp32_s0_q, is_fp32_s1_q, is_fp32_s2_q;
  logic [4:0] rm_s0_q, rm_s1_q, rm_s2_q;
  always_ff @(posedge clock) begin
    if (fire) begin
      is_fp64_s0_q <= is_fp64;
      is_fp32_s0_q <= is_fp32;
      rm_s0_q      <= rm_onehot;
    end
    if (fire_s1) begin
      is_fp64_s1_q <= is_fp64_s0_q;
      is_fp32_s1_q <= is_fp32_s0_q;
      rm_s1_q      <= rm_s0_q;
    end
    if (fire_s2) begin
      is_fp64_s2_q <= is_fp64_s1_q;
      is_fp32_s2_q <= is_fp32_s1_q;
      rm_s2_q      <= rm_s1_q;
    end
  end

  // ===========================================================================
  // 操作码译码：统一成 a*b + c
  // ===========================================================================
  localparam logic [3:0] OP_VFMUL = 4'd0, OP_VFMACC = 4'd1, OP_VFNMACC = 4'd2, OP_VFMSAC = 4'd3, OP_VFNMSAC = 4'd4,
                         OP_VFMADD = 4'd5, OP_VFNMADD = 4'd6, OP_VFMSUB = 4'd7, OP_VFNMSUB = 4'd8;
  logic is_vfmul, swap_a_c, negate_a, negate_c, negate_widen_a;
  assign is_vfmul       = (op_code == OP_VFMUL);
  assign swap_a_c       = (op_code == OP_VFMADD) || (op_code == OP_VFNMADD) || (op_code == OP_VFMSUB) || (op_code == OP_VFNMSUB);
  assign negate_a       = (op_code == OP_VFNMACC) || (op_code == OP_VFNMSAC) || (op_code == OP_VFNMADD) || (op_code == OP_VFNMSUB);
  assign negate_c       = (op_code == OP_VFNMACC) || (op_code == OP_VFMSAC) || (op_code == OP_VFNMADD) || (op_code == OP_VFMSUB);
  assign negate_widen_a = (op_code == OP_VFNMACC) || (op_code == OP_VFNMSAC);   // 加宽运算没有 madd 类

  logic [63:0] a_src, c_src;   // 交换后的 a / c（符号在各通道自己的最高位上改）
  assign a_src = swap_a_c ? fp_c : fp_a;
  assign c_src = swap_a_c ? fp_a : fp_c;

  // ===========================================================================
  // 共用寄存器（按格式复用）与各通道之间的连线
  // ===========================================================================
  // S0 -> S1
  logic               is_sub_f64_s0_q;
  logic [NUM_LANE-1:1] is_sub_csa_s0_q;     // f32 / f16 通道：给 CSA 进位输入用的副本
  logic [NUM_LANE-1:1] is_sub_adder_s0_q;   //                 给保护位取负用的副本
  logic [3:0]         rsh_guard_s0_q, rsh_round_s0_q, rsh_sticky_s0_q;
  logic [CAL_W-1:0]   c_aligned_s0_q;
  logic [23:0]        exp_greater_s0_q, exp_greater_s1_q, exp_greater_s2_q;
  logic [23:0]        lshift_max_s0_q;
  logic [63:0]        zero_result_s0_q, zero_result_s1_q, zero_result_s2_q;
  // S1 -> S2
  logic [3:0]         adder_neg_s1_q, adder_neg_s2_q;
  logic [ADD_W-1:0]   tzd_src_s1_q;
  logic [INV_W-1:0]   lzd_src_s1_q;
  logic [3:0]         mask_valid_s1_q;
  logic [ADD_W-1:0]   adder_s1_q;
  // S2 -> S3
  logic [51:0]        frac_s2_q;
  logic [3:0]         is_fix_s2_q;
  logic [23:0]        lshift_value_s2_q;

  // 各通道送出的量，零扩展到 f64 通道的宽度，供拼装
  logic [NUM_LANE-1:0][52:0]       lane_sig_a, lane_sig_b;
  logic [NUM_LANE-1:0][RSH_W-1:0]  lane_rsh_src;
  logic [NUM_LANE-1:0][7:0]        lane_rsh_amount;
  logic [NUM_LANE-1:0]             lane_is_sub_d, lane_guard_d, lane_round_d, lane_sticky_d;
  logic [NUM_LANE-1:0][CAL_W-1:0]  lane_c_aligned_d;
  logic [NUM_LANE-1:0][23:0]       lane_exp_greater_d, lane_lshift_max_d;
  logic [NUM_LANE-1:0][63:0]       lane_zero_result_d;
  logic [NUM_LANE-1:0]             lane_carry_in;      // 减法且保护位全 0：取负的进位进到乘积最低位
  logic [NUM_LANE-1:0][SUM_W-1:0]  lane_c_low;         // 对齐后的 c 的低 2W 位
  logic [NUM_LANE-1:0][CHI_W-1:0]  lane_c_high;        // 对齐后的 c 的高 W+3 位
  logic [NUM_LANE-1:0]             lane_adder_neg_d, lane_mask_valid_d;
  logic [NUM_LANE-1:0][ADD_W-1:0]  lane_adder_d, lane_tzd_src_d;
  logic [NUM_LANE-1:0][INV_W-1:0]  lane_lzd_src_d;
  logic [NUM_LANE-1:0][ADD_W-1:0]  lane_lsh_src;
  logic [NUM_LANE-1:0][7:0]        lane_lsh_amount;
  logic [NUM_LANE-1:0][51:0]       lane_frac_d;
  logic [NUM_LANE-1:0]             lane_is_fix_d;
  logic [NUM_LANE-1:0][23:0]       lane_lshift_value_d;
  logic [NUM_LANE-1:0][63:0]       lane_result;
  logic [NUM_LANE-1:0][4:0]        lane_fflags;

  // S1 的公共数据通路（定义在后面）
  logic [SUM_W-1:0] sum_low_all;        // 乘积 + c 低段，各通道占自己那一段
  logic [CHI_W-1:0] c_high_plus1_all;   // 各通道 c 高段各自加 1

  // f64 / f32_1 共用的左移器
  logic [ADD_W-1:0] shared_lsh_shifted;

  // ===========================================================================
  // 七条通道
  // ===========================================================================
  for (genvar l = 0; l < NUM_LANE; l++) begin : g_lane
    localparam int unsigned SIG_W  = LANE_SIG_W[l];
    localparam int unsigned EXP_W  = LANE_EXP_W[l];
    localparam int unsigned FLT_W  = SIG_W + EXP_W;
    localparam int unsigned SLOT   = LANE_SLOT[l];
    localparam bit          WIDEN  = (FLT_W != 16);        // f16 结果没有加宽
    localparam int unsigned NFLT_W = FLT_W / 2;
    localparam int unsigned N_EXP_W = WIDEN ? EXP_W - 3 : 1;
    localparam int unsigned N_SIG_W = NFLT_W - N_EXP_W;
    localparam int unsigned L_RSH_W = 3 * SIG_W + 4;
    localparam int unsigned L_CAL_W = L_RSH_W - 1;
    localparam int unsigned L_ADD_W = 3 * SIG_W + 5;
    localparam int unsigned L_INV_W = L_ADD_W - 1;
    localparam int unsigned L_AMT_W = $clog2(L_RSH_W + 1);
    localparam int unsigned L_LZD_W = $clog2(L_ADD_W + 1);
    localparam int unsigned BASE    = SLOT * FLT_W;        // 本通道在 64 位数据里的起始位

    // ---- S0 输入：切出本通道的操作数，改符号 ----
    logic [FLT_W-1:0]  a_word, b_word, c_word;
    logic [NFLT_W-1:0] a_narrow, b_narrow;
    logic              use_narrow;
    assign a_word = {a_src[BASE+FLT_W-1] ^ negate_a, a_src[BASE +: FLT_W-1]};
    assign b_word = fp_b[BASE +: FLT_W];
    assign c_word = is_vfmul ? '0 : {c_src[BASE+FLT_W-1] ^ negate_c, c_src[BASE +: FLT_W-1]};
    if (WIDEN) begin : g_widen
      // 加宽源：偶数元素在 widen_* 低 32 位、奇数元素在高 32 位，uop_idx 选一半；半内按槽位取
      localparam int unsigned NBASE = SLOT * NFLT_W;
      logic [NFLT_W-1:0] widen_a_sel;
      assign widen_a_sel = uop_idx ? widen_a[32+NBASE +: NFLT_W] : widen_a[NBASE +: NFLT_W];
      assign a_narrow    = {widen_a_sel[NFLT_W-1] ^ negate_widen_a, widen_a_sel[NFLT_W-2:0]};
      assign b_narrow    = uop_idx ? widen_b[32+NBASE +: NFLT_W] : widen_b[NBASE +: NFLT_W];
      assign use_narrow  = res_widening & ((l == 0) ? is_fp64 : is_fp32);
    end else begin : g_no_widen
      assign a_narrow   = '0;
      assign b_narrow   = '0;
      assign use_narrow = 1'b0;
    end

    // ---- 右移器 ----
    logic [SIG_W-1:0]   sig_a, sig_b;
    logic [L_RSH_W-1:0] rsh_src, rsh_shifted;
    logic [L_AMT_W-1:0] rsh_amount;
    logic               rsh_sticky;
    assign lane_rsh_src[l]    = RSH_W'(rsh_src);
    assign lane_rsh_amount[l] = 8'(rsh_amount);
    if (l == 2) begin : g_rsh_f64_sized
      // f32_1：走一个 f64 尺寸的右移器，输入与 f64 通道的数据二选一（怪癖 1a）；结果只取低段
      logic [RSH_W-1:0] wide_shifted;
      xs_VfmaRightShiftSticky #(.W(RSH_W), .AMT_W(8)) u_rsh (
        .src     (is_fp64 ? lane_rsh_src[0] : lane_rsh_src[2]),
        .amount  (is_fp64 ? lane_rsh_amount[0] : lane_rsh_amount[2]),
        .shifted (wide_shifted),
        .sticky  (rsh_sticky)
      );
      assign rsh_shifted = wide_shifted[L_RSH_W-1:0];
    end else begin : g_rsh_own
      xs_VfmaRightShiftSticky #(.W(L_RSH_W), .AMT_W(L_AMT_W)) u_rsh (
        .src     (rsh_src),
        .amount  (rsh_amount),
        .shifted (rsh_shifted),
        .sticky  (rsh_sticky)
      );
    end

    // ---- 左移器 ----
    logic [L_ADD_W-1:0] lsh_src, lsh_shifted;
    logic [L_LZD_W-1:0] lsh_amount;
    assign lane_lsh_src[l]    = ADD_W'(lsh_src);
    assign lane_lsh_amount[l] = 8'(lsh_amount);
    if (l == 0 || l == 2) begin : g_lsh_shared
      assign lsh_shifted = shared_lsh_shifted[L_ADD_W-1:0];   // 怪癖 1b
    end else begin : g_lsh_own
      assign lsh_shifted = lsh_src << lsh_amount;
    end

    // ---- 本通道在共用寄存器里的那一段 ----
    logic               is_sub_d, guard_d, round_d, sticky_d;
    logic [L_CAL_W-1:0] c_aligned_d, c_aligned_q;
    logic [EXP_W:0]     exp_greater_d, lshift_max_d;
    logic [FLT_W-1:0]   zero_result_d;
    logic               is_sub_csa_q, is_sub_adder_q;
    logic               adder_neg_d, mask_valid_d;
    logic [L_ADD_W-1:0] adder_d, tzd_src_d;
    logic [L_INV_W-1:0] lzd_src_d;
    logic [SIG_W-2:0]   frac_d;
    logic               is_fix_d;
    logic [L_LZD_W-1:0] lshift_value_d;
    logic [FLT_W-1:0]   result;

    assign c_aligned_q = c_aligned_s0_q[SLOT*L_CAL_W +: L_CAL_W];
    if (l == 0) begin : g_is_sub_f64
      assign is_sub_csa_q   = is_sub_f64_s0_q;
      assign is_sub_adder_q = is_sub_f64_s0_q;
    end else begin : g_is_sub_dup
      assign is_sub_csa_q   = is_sub_csa_s0_q[l];
      assign is_sub_adder_q = is_sub_adder_s0_q[l];
    end

    assign lane_sig_a[l]          = 53'(sig_a);
    assign lane_sig_b[l]          = 53'(sig_b);
    assign lane_is_sub_d[l]       = is_sub_d;
    assign lane_guard_d[l]        = guard_d;
    assign lane_round_d[l]        = round_d;
    assign lane_sticky_d[l]       = sticky_d;
    assign lane_c_aligned_d[l]    = CAL_W'(c_aligned_d);
    assign lane_exp_greater_d[l]  = 24'(exp_greater_d);
    assign lane_lshift_max_d[l]   = 24'(lshift_max_d);
    assign lane_zero_result_d[l]  = 64'(zero_result_d);
    assign lane_carry_in[l]       = is_sub_csa_q & ~rsh_guard_s0_q[SLOT] & ~rsh_round_s0_q[SLOT] & ~rsh_sticky_s0_q[SLOT];
    assign lane_c_low[l]          = SUM_W'(c_aligned_q[2*SIG_W-1:0]);
    assign lane_c_high[l]         = CHI_W'(c_aligned_q[L_CAL_W-1 -: SIG_W+3]);
    assign lane_adder_neg_d[l]    = adder_neg_d;
    assign lane_mask_valid_d[l]   = mask_valid_d;
    assign lane_adder_d[l]        = ADD_W'(adder_d);
    assign lane_tzd_src_d[l]      = ADD_W'(tzd_src_d);
    assign lane_lzd_src_d[l]      = INV_W'(lzd_src_d);
    assign lane_frac_d[l]         = 52'(frac_d);
    assign lane_is_fix_d[l]       = is_fix_d;
    assign lane_lshift_value_d[l] = 24'(lshift_value_d);
    assign lane_result[l]         = 64'(result);

    xs_VfmaLane #(.SIG_W(SIG_W), .EXP_W(EXP_W), .HAS_WIDEN(WIDEN), .N_SIG_W(N_SIG_W), .N_EXP_W(N_EXP_W)) u_lane (
      .clock          (clock),
      .fire           (fire),
      .fire_s1        (fire_s1),
      .fire_s2        (fire_s2),
      // S0
      .a_word         (a_word),
      .b_word         (b_word),
      .c_word         (c_word),
      .a_narrow       (a_narrow),
      .b_narrow       (b_narrow),
      .use_narrow     (use_narrow),
      .is_vfmul       (is_vfmul),
      .rm_rdn_s0      (rm_onehot[2]),
      .sig_a          (sig_a),
      .sig_b          (sig_b),
      .rsh_src        (rsh_src),
      .rsh_amount     (rsh_amount),
      .rsh_shifted    (rsh_shifted),
      .rsh_sticky     (rsh_sticky),
      .is_sub_d       (is_sub_d),
      .guard_d        (guard_d),
      .round_d        (round_d),
      .sticky_d       (sticky_d),
      .c_aligned_d    (c_aligned_d),
      .exp_greater_d  (exp_greater_d),
      .lshift_max_d   (lshift_max_d),
      .zero_result_d  (zero_result_d),
      // S1
      .is_sub_q       (is_sub_adder_q),
      .guard_q        (rsh_guard_s0_q[SLOT]),
      .round_q        (rsh_round_s0_q[SLOT]),
      .sticky_q       (rsh_sticky_s0_q[SLOT]),
      .c_aligned_q    (c_aligned_q),
      .lshift_max_q   (lshift_max_s0_q[SLOT*(EXP_W+1) +: EXP_W+1]),
      .sum_low        (sum_low_all[LANE_SUM_LSB[l] +: 2*SIG_W+1]),
      .c_high_plus1   (c_high_plus1_all[LANE_CHI_LSB[l] +: SIG_W+3]),
      .adder_neg_d    (adder_neg_d),
      .adder_d        (adder_d),
      .tzd_src_d      (tzd_src_d),
      .lzd_src_d      (lzd_src_d),
      .mask_valid_d   (mask_valid_d),
      // S2
      .adder_neg_s1_q (adder_neg_s1_q[SLOT]),
      .adder_q        (adder_s1_q[SLOT*L_ADD_W +: L_ADD_W]),
      .tzd_src_q      (tzd_src_s1_q[SLOT*L_ADD_W +: L_ADD_W]),
      .lzd_src_q      (lzd_src_s1_q[SLOT*L_INV_W +: L_INV_W]),
      .mask_valid_q   (mask_valid_s1_q[SLOT]),
      .lsh_src        (lsh_src),
      .lsh_amount     (lsh_amount),
      .lsh_shifted    (lsh_shifted),
      .frac_d         (frac_d),
      .is_fix_d       (is_fix_d),
      .lshift_value_d (lshift_value_d),
      // S3
      .adder_neg_s2_q (adder_neg_s2_q[SLOT]),
      .frac_q         (frac_s2_q[SLOT*(SIG_W-1) +: SIG_W-1]),
      .is_fix_q       (is_fix_s2_q[SLOT]),
      .lshift_value_q (lshift_value_s2_q[SLOT*L_LZD_W +: L_LZD_W]),
      .exp_greater_q  (exp_greater_s2_q[SLOT*(EXP_W+1) +: EXP_W+1]),
      .zero_result_q  (zero_result_s2_q[BASE +: FLT_W]),
      .rm_rne         (rm_s2_q[0]),
      .rm_rtz         (rm_s2_q[1]),
      .rm_rdn         (rm_s2_q[2]),
      .rm_rup         (rm_s2_q[3]),
      .rm_rmm         (rm_s2_q[4]),
      .result         (result),
      .fflags         (lane_fflags[l])
    );
  end

  // ===========================================================================
  // §S0 乘法阵列前半 + 把各通道的 S0 结果拼进共用寄存器
  // ===========================================================================
  logic [NUM_LANE-1:0] active_s0;
  assign active_s0 = active_lanes(is_fp64, is_fp32);

  // Booth 编码器输入：在用通道的有效数摆到各自的位置上（通道之间垫 0）
  logic [52:0] booth_in_a, booth_in_b;
  always_comb begin
    booth_in_a = '0;
    booth_in_b = '0;
    for (int unsigned l = 0; l < NUM_LANE; l++) begin
      if (active_s0[l]) begin
        booth_in_a = booth_in_a | (lane_sig_a[l] << LANE_SIG_LSB[l]);
        booth_in_b = booth_in_b | (lane_sig_b[l] << LANE_SIG_LSB[l]);
      end
    end
  end

  logic [26:0][SUM_W-1:0] booth_pp;
  logic [SUM_W-1:0]       tree_sum, tree_carry;   // 27 -> 2 压缩结果（树内部已打一拍：属于 S1）
  BoothEncoderF64F32F16_3 U_BoothEncoder (
    .io_in_a      (booth_in_a),
    .io_in_b      (booth_in_b),
    .io_is_fp64   (is_fp64),
    .io_is_fp32   (is_fp32),
    .io_out_pp_0  (booth_pp[0]),
    .io_out_pp_1  (booth_pp[1]),
    .io_out_pp_2  (booth_pp[2]),
    .io_out_pp_3  (booth_pp[3]),
    .io_out_pp_4  (booth_pp[4]),
    .io_out_pp_5  (booth_pp[5]),
    .io_out_pp_6  (booth_pp[6]),
    .io_out_pp_7  (booth_pp[7]),
    .io_out_pp_8  (booth_pp[8]),
    .io_out_pp_9  (booth_pp[9]),
    .io_out_pp_10 (booth_pp[10]),
    .io_out_pp_11 (booth_pp[11]),
    .io_out_pp_12 (booth_pp[12]),
    .io_out_pp_13 (booth_pp[13]),
    .io_out_pp_14 (booth_pp[14]),
    .io_out_pp_15 (booth_pp[15]),
    .io_out_pp_16 (booth_pp[16]),
    .io_out_pp_17 (booth_pp[17]),
    .io_out_pp_18 (booth_pp[18]),
    .io_out_pp_19 (booth_pp[19]),
    .io_out_pp_20 (booth_pp[20]),
    .io_out_pp_21 (booth_pp[21]),
    .io_out_pp_22 (booth_pp[22]),
    .io_out_pp_23 (booth_pp[23]),
    .io_out_pp_24 (booth_pp[24]),
    .io_out_pp_25 (booth_pp[25]),
    .io_out_pp_26 (booth_pp[26])
  );
  CSA_Nto2With3to2MainPipeline U_CSAnto2 (
    .clock      (clock),
    .io_fire    (fire),
    .io_in_0    (booth_pp[0]),
    .io_in_1    (booth_pp[1]),
    .io_in_2    (booth_pp[2]),
    .io_in_3    (booth_pp[3]),
    .io_in_4    (booth_pp[4]),
    .io_in_5    (booth_pp[5]),
    .io_in_6    (booth_pp[6]),
    .io_in_7    (booth_pp[7]),
    .io_in_8    (booth_pp[8]),
    .io_in_9    (booth_pp[9]),
    .io_in_10   (booth_pp[10]),
    .io_in_11   (booth_pp[11]),
    .io_in_12   (booth_pp[12]),
    .io_in_13   (booth_pp[13]),
    .io_in_14   (booth_pp[14]),
    .io_in_15   (booth_pp[15]),
    .io_in_16   (booth_pp[16]),
    .io_in_17   (booth_pp[17]),
    .io_in_18   (booth_pp[18]),
    .io_in_19   (booth_pp[19]),
    .io_in_20   (booth_pp[20]),
    .io_in_21   (booth_pp[21]),
    .io_in_22   (booth_pp[22]),
    .io_in_23   (booth_pp[23]),
    .io_in_24   (booth_pp[24]),
    .io_in_25   (booth_pp[25]),
    .io_in_26   (booth_pp[26]),
    .io_out_sum (tree_sum),
    .io_out_car (tree_carry)
  );

  logic [CAL_W-1:0] c_aligned_s0_d;
  logic [23:0]      exp_greater_s0_d, lshift_max_s0_d;
  logic [63:0]      zero_result_s0_d;
  xs_VfmaSlotPack #(.OUT_W(CAL_W), .FW64(162), .FW32(75), .FW16(36)) u_pack_c_aligned (
    .is_fp64    (is_fp64),
    .is_fp32    (is_fp32),
    .lane_val   (lane_c_aligned_d),
    .packed_val (c_aligned_s0_d)
  );
  xs_VfmaSlotPack #(.OUT_W(24), .FW64(12), .FW32(9), .FW16(6)) u_pack_exp_greater (
    .is_fp64    (is_fp64),
    .is_fp32    (is_fp32),
    .lane_val   (lane_exp_greater_d),
    .packed_val (exp_greater_s0_d)
  );
  xs_VfmaSlotPack #(.OUT_W(24), .FW64(12), .FW32(9), .FW16(6)) u_pack_lshift_max (
    .is_fp64    (is_fp64),
    .is_fp32    (is_fp32),
    .lane_val   (lane_lshift_max_d),
    .packed_val (lshift_max_s0_d)
  );
  xs_VfmaSlotPack #(.OUT_W(64), .FW64(64), .FW32(32), .FW16(16)) u_pack_zero_result (
    .is_fp64    (is_fp64),
    .is_fp32    (is_fp32),
    .lane_val   (lane_zero_result_d),
    .packed_val (zero_result_s0_d)
  );

  always_ff @(posedge clock) begin
    if (fire) begin
      is_sub_f64_s0_q   <= lane_is_sub_d[0];
      is_sub_csa_s0_q   <= lane_is_sub_d[NUM_LANE-1:1];
      is_sub_adder_s0_q <= lane_is_sub_d[NUM_LANE-1:1];
      rsh_guard_s0_q    <= pack_overlay(is_fp64, is_fp32, lane_guard_d);
      rsh_round_s0_q    <= pack_overlay(is_fp64, is_fp32, lane_round_d);
      rsh_sticky_s0_q   <= pack_overlay(is_fp64, is_fp32, lane_sticky_d);
      c_aligned_s0_q    <= c_aligned_s0_d;
      exp_greater_s0_q  <= exp_greater_s0_d;
      lshift_max_s0_q   <= lshift_max_s0_d;
      zero_result_s0_q  <= zero_result_s0_d;
    end
  end

  // ===========================================================================
  // §S1 乘积 + c：3:2 压缩、107 位加法、c 高段加 1；把各通道的和拼进共用寄存器
  // ===========================================================================
  logic [NUM_LANE-1:0] active_s1;
  assign active_s1 = active_lanes(is_fp64_s0_q, is_fp32_s0_q);

  // 压缩树的进位输出每条通道的最低位恒空着（进位左移一位），正好塞"取负的进位"；
  // 对齐后的 c 的低 2W 位摆到通道自己那一段，作为第三个加数。
  logic [SUM_W-1:0] csa_in_b, csa_in_c;
  logic [CHI_W-1:0] c_high_all, c_high_ones;
  // c 高段"加 1"加在哪些通道的最低位上。★f32_1 那一位只看 is_fp32，不让位给 is_fp64★（怪癖 8）：
  // 两个格式寄存器不会同时为 1，功能上与"在用通道"无差别，但形式验证把它们当独立状态，必须照 golden 写。
  logic [NUM_LANE-1:0] plus1_lanes;
  assign plus1_lanes = {active_s1[6:3], is_fp32_s0_q, active_s1[1:0]};
  always_comb begin
    csa_in_b    = tree_carry;
    csa_in_c    = '0;
    c_high_all  = '0;
    c_high_ones = '0;
    for (int unsigned l = 0; l < NUM_LANE; l++) begin
      if (active_s1[l]) begin
        csa_in_b[LANE_SUM_LSB[l]] = lane_carry_in[l];
        csa_in_c                  = csa_in_c | (lane_c_low[l] << LANE_SUM_LSB[l]);
        c_high_all                = c_high_all | (lane_c_high[l] << LANE_CHI_LSB[l]);
      end
      if (plus1_lanes[l]) c_high_ones[LANE_CHI_LSB[l]] = 1'b1;
    end
  end

  logic [SUM_W-1:0] csa_sum, csa_carry;
  CSA3to2 U_CSA3to2 (
    .io_in_a    (tree_sum),
    .io_in_b    (csa_in_b),
    .io_in_c    (csa_in_c),
    .io_out_sum (csa_sum),
    .io_out_car (csa_carry)
  );

  // 一个 107 位加法器同时给出所有通道的"乘积 + c 低段"（通道之间的空位吸收进位）；
  // 一个 59 位加法器同时给各通道的 c 高段加 1（通道之间至少隔 1 位 0）。
  assign sum_low_all      = csa_sum + csa_carry;
  assign c_high_plus1_all = c_high_all + c_high_ones;

  logic [ADD_W-1:0] tzd_src_s1_d, adder_s1_d;
  logic [INV_W-1:0] lzd_src_s1_d;
  logic [3:0]       mask_valid_s1_d;
  xs_VfmaSlotPack #(.OUT_W(ADD_W), .FW64(164), .FW32(77), .FW16(38)) u_pack_tzd_src (
    .is_fp64    (is_fp64_s0_q),
    .is_fp32    (is_fp32_s0_q),
    .lane_val   (lane_tzd_src_d),
    .packed_val (tzd_src_s1_d)
  );
  xs_VfmaSlotPack #(.OUT_W(ADD_W), .FW64(164), .FW32(77), .FW16(38)) u_pack_adder (
    .is_fp64    (is_fp64_s0_q),
    .is_fp32    (is_fp32_s0_q),
    .lane_val   (lane_adder_d),
    .packed_val (adder_s1_d)
  );
  xs_VfmaSlotPack #(.OUT_W(INV_W), .FW64(163), .FW32(76), .FW16(37)) u_pack_lzd_src (
    .is_fp64    (is_fp64_s0_q),
    .is_fp32    (is_fp32_s0_q),
    .lane_val   (lane_lzd_src_d),
    .packed_val (lzd_src_s1_d)
  );
  assign mask_valid_s1_d = is_fp64_s0_q ? {3'b0, lane_mask_valid_d[0]}
                         : is_fp32_s0_q ? {2'b0, lane_mask_valid_d[2:1]}
                         :                lane_mask_valid_d[6:3];

  always_ff @(posedge clock) begin
    if (fire_s1) begin
      adder_neg_s1_q   <= pack_overlay(is_fp64_s0_q, is_fp32_s0_q, lane_adder_neg_d);
      tzd_src_s1_q     <= tzd_src_s1_d;
      lzd_src_s1_q     <= lzd_src_s1_d;
      mask_valid_s1_q  <= mask_valid_s1_d;
      adder_s1_q       <= adder_s1_d;
      exp_greater_s1_q <= exp_greater_s0_q;
      zero_result_s1_q <= zero_result_s0_q;
    end
  end

  // ===========================================================================
  // §S2 f64 / f32_1 共用的规格化左移器；把各通道的 S2 结果拼进共用寄存器
  // ===========================================================================
  assign shared_lsh_shifted = (is_fp64_s1_q ? lane_lsh_src[0] : lane_lsh_src[2])
                              << (is_fp64_s1_q ? lane_lsh_amount[0] : lane_lsh_amount[2]);

  logic [51:0] frac_s2_d;
  logic [23:0] lshift_value_s2_d;
  logic [3:0]  is_fix_s2_d;
  xs_VfmaSlotPack #(.OUT_W(52), .FW64(52), .FW32(23), .FW16(10)) u_pack_frac (
    .is_fp64    (is_fp64_s1_q),
    .is_fp32    (is_fp32_s1_q),
    .lane_val   (lane_frac_d),
    .packed_val (frac_s2_d)
  );
  xs_VfmaSlotPack #(.OUT_W(24), .FW64(8), .FW32(7), .FW16(6)) u_pack_lshift_value (
    .is_fp64    (is_fp64_s1_q),
    .is_fp32    (is_fp32_s1_q),
    .lane_val   (lane_lshift_value_d),
    .packed_val (lshift_value_s2_d)
  );
  assign is_fix_s2_d = is_fp64_s1_q ? {3'b0, lane_is_fix_d[0]}
                     : is_fp32_s1_q ? {2'b0, lane_is_fix_d[2:1]}
                     :                lane_is_fix_d[6:3];

  always_ff @(posedge clock) begin
    if (fire_s2) begin
      adder_neg_s2_q    <= adder_neg_s1_q;
      frac_s2_q         <= frac_s2_d;
      is_fix_s2_q       <= is_fix_s2_d;
      lshift_value_s2_q <= lshift_value_s2_d;
      exp_greater_s2_q  <= exp_greater_s1_q;
      zero_result_s2_q  <= zero_result_s1_q;
    end
  end

  // ===========================================================================
  // §S3 按格式拼出结果与标志
  // ===========================================================================
  logic is_fp16_s2;
  assign is_fp16_s2 = ~is_fp32_s2_q & ~is_fp64_s2_q;

  assign fp_result = is_fp64_s2_q ? lane_result[0]
                   : is_fp32_s2_q ? {lane_result[2][31:0], lane_result[1][31:0]}
                   :                {lane_result[6][15:0], lane_result[5][15:0], lane_result[4][15:0], lane_result[3][15:0]};

  assign fflags = {{5{is_fp16_s2}} & lane_fflags[6],
                   {5{is_fp16_s2}} & lane_fflags[5],
                   {5{~is_fp64_s2_q}} & (is_fp32_s2_q ? lane_fflags[2] : lane_fflags[4]),
                   is_fp64_s2_q ? lane_fflags[0] : (is_fp32_s2_q ? lane_fflags[1] : lane_fflags[3])};
endmodule

module VectorFloatFMA (
  input         clock,
  input         reset,
  input         io_fire,
  input  [63:0] io_fp_a,
  input  [63:0] io_fp_b,
  input  [63:0] io_fp_c,
  input         io_uop_idx,
  input  [63:0] io_widen_a,
  input  [63:0] io_widen_b,
  input  [2:0]  io_round_mode,
  input  [1:0]  io_fp_format,
  input  [3:0]  io_op_code,
  input         io_res_widening,
  output [63:0] io_fp_result,
  output [19:0] io_fflags
);
  xs_VectorFloatFMA_core u_core (
    .clock        (clock),
    .reset        (reset),
    .fire         (io_fire),
    .fp_a         (io_fp_a),
    .fp_b         (io_fp_b),
    .fp_c         (io_fp_c),
    .uop_idx      (io_uop_idx),
    .widen_a      (io_widen_a),
    .widen_b      (io_widen_b),
    .round_mode   (io_round_mode),
    .fp_format    (io_fp_format),
    .op_code      (io_op_code),
    .res_widening (io_res_widening),
    .fp_result    (io_fp_result),
    .fflags       (io_fflags)
  );
endmodule
