// =============================================================================
// FloatFMA.sv —— 标量浮点乘加单元（a*b ± c，f16 / f32 / f64，三级寄存器，第 3 拍组合出结果）
//
// 位置：标量浮点功能单元 FMA（rtl/backend/FMA.sv）里的运算体。每次只算一个元素，
//   格式由 fp_format 选：3=f64 / 2=f32 / 其余=f16；f32 / f16 结果高位补 1（NaN-boxing）。
//   Scala：yunsuan/src/main/scala/yunsuan/fpu/FloatFMA.scala（class FloatFMA）。
//
// 输入约定：
//   fp_a = rs1 / vs2，fp_b = rs2 / vs1，fp_c = rs3 / vd；op_code 是 FmaOpCode：
//     fmul 0 / fmacc 1 / fnmacc 2 / fmsac 3 / fnmsac 4，统一成 "a*b + c"：
//     fnmacc / fnmsac 把 a 的符号取反；fnmacc / fmsac 把 c 的符号取反；fmul 把 c 置成 +0。
//   fp_*IsFpCanonicalNAN：父模块告诉我们该操作数 NaN-boxing 不合法，按规范 NaN 处理（此时它
//     既不算 0、也不算 Inf / sNaN）。
//   fflags = {NV, DZ, OF, UF, NX}。
//
// 算法（三种格式各一条"格式通路" xs_FloatFmaFormat，同一份代码，只差位宽参数；
//   设有效数宽 W = 53 / 24 / 11）：
//   §S0  拆操作数、判特殊值；指数比较。把 c 的有效数放进一个 3W+4 位的"对齐窗口"：乘积 2W 位落在
//        窗口低端，其上留 W+3 位给"c 比乘积大"的情形；c 按指数差右移对齐，移出窗口的位并成 sticky；
//        减法时 c 按位取反（欠的 +1 在 S1 补）。Booth 编码 + CSA 压缩树前 4 层也在这一拍。
//   §S1  压缩树最后一层（树内部的寄存器）-> 与对齐后的 c 的低 2W 位做一次 3:2 -> 107 位加法；
//        c 的高 W+3 位按低位的进位选"原值 / 加 1"；拼上右移移出去的 guard/round，得到 3W+5 位的和。
//        和为负则记下并取反；同时准备前导零计数的输入（|和| 并上"最多左移到指数为最小值"的掩码）。
//   §S2  前导零计数、规格化左移；取出尾数、guard / round / sticky。
//   §S3  舍入、指数修正、溢出 / 下溢 / 不精确判定，与特殊值（NaN / Inf / 0）的结果多选。
//
// 寄存器组织（照 golden，逐个对齐）：
//   * 只有 fire_s1 / fire_s2 带异步复位；其余全部不复位，由 fire / fire_s1 / fire_s2 使能。
//   * "公共寄存器"在核里：一个寄存器按当拍格式装三条通路之一的值（窄格式零扩展），三条通路
//     都从它取自己的那一段。（例：c 的对齐结果、指数、前导零计数的输入、尾数。）
//   * "每格式寄存器"在通路模块里：三条通路各一份、无论当拍是什么格式都照常打拍
//     （符号、sticky、特殊值标志、和本身等）。哪些是公共的、哪些是每格式的，完全照 Scala。
//
// 怪癖（照 golden，不"修"）：
//   1. 减法标志 is_sub 的 S0 寄存器：f64 一个；f32 / f16 各**两个内容相同的副本**
//      （一个给 CSA 的进位输入用，一个给保护位取负用）——Scala 里写了两次 RegEnable。
//   2. 每格式的 sticky 与 sticky_uf 的第 1 级寄存器都存公共 sticky 寄存器的同一个值（6 个副本）。
//   3. 舍入模式在 S0 译成 5 个独热位后各自打三拍；RDN 在 S0 还直接参与"a 或 b 为 0"结果的符号。
//   4. tzd（和的尾随零个数）是把和按位反转后存起来、下一拍用同一个前导零电路数出来的。
//      tzd + lzd 的和按前导零计数的位宽截断（f64 8 位、f32 7 位、f16 6 位）后再比较。
//   5. 结果恰为 0（和为 0）时符号只看 RDN；fflags 给 0。
//   6. S1 的 3:2 进位输入按向量版的通道边界清位：f32 把第 58 位清 0，f16 把第 26 / 58 / 84 位清 0
//      （标量只用最低通道，这些位只影响和的高位）。看似无用，但三条通路的"和"寄存器
//      （adder_s1_q）不论当拍格式都会把整个 107 位加法结果的自己那一段存下来——f64 通路在 f32 /
//      f16 拍里存的就是这个清过位的和。寄存器内容要逐位对齐，所以照搬。
//   7. S1 里"c 的高段加 1"只有一个共用的 59 位加法器，输入按当拍格式三选一（零扩展）；三条通路
//      各取它的低 W+3 位。所以非当拍格式的通路（其"和"寄存器照样打拍）拿到的是别的格式的 c 高段 + 1。
//      与怪癖 6 同理，照搬。（"原值"那一支每条通路直接取自己那段寄存器，不共用。）
//
// 子模块：BoothEncoderF64F32F16（标量 Booth 编码，本仓重写）、CSA_Nto2With3to2MainPipeline
//   （27->2 压缩树，内含一级寄存器，本仓重写）、CSA3to2（本仓重写）。
// =============================================================================

// 带 sticky 的对数右移器：从低位到高位逐级移 1 / 2 / 4 / ...，被移出去的位或进 sticky。
module xs_FloatFmaShiftRightSticky #(
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
module xs_FloatFmaLzd #(
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

// -----------------------------------------------------------------------------
// 一种格式的全部逻辑（f64 / f32 / f16 各例化一份，只差位宽参数）。
// 公共寄存器走端口：*_d 是送去核里寄存的次态，*_q 是公共寄存器里属于本格式的那一段。
// 本格式独占的寄存器（符号、sticky、特殊值标志、和本身等）在模块内。
// -----------------------------------------------------------------------------
module xs_FloatFmaFormat #(
  parameter  int unsigned SIG_W      = 53,   // 有效数位宽（含隐含位）
  parameter  int unsigned EXP_W      = 11,
  parameter  bit          DUP_IS_SUB = 1'b0, // is_sub 的 S0 寄存器有两个副本（f32 / f16，怪癖 1）
  localparam int unsigned FLT_W      = SIG_W + EXP_W,
  localparam int unsigned RSH_W      = 3 * SIG_W + 4,       // c 的对齐窗口
  localparam int unsigned CAL_W      = RSH_W - 1,           // 对齐后的 c：符号 + 窗口去掉最低两位
  localparam int unsigned ADD_W      = 3 * SIG_W + 5,       // 和（含符号位）
  localparam int unsigned INV_W      = ADD_W - 1,           // 和的绝对值
  localparam int unsigned AMT_W      = $clog2(RSH_W + 1),   // 右移量位宽
  localparam int unsigned LZD_W      = $clog2(ADD_W + 1)    // 前导零计数位宽
) (
  input  logic               clock,
  input  logic               fire,
  input  logic               fire_s1,
  input  logic               fire_s2,

  // ---- S0 ----
  input  logic [FLT_W-1:0]   a_word,         // 已按操作码改符号
  input  logic [FLT_W-1:0]   b_word,
  input  logic [FLT_W-1:0]   c_word,         // 已按操作码改符号；fmul 时为 +0
  input  logic               a_canon_nan,    // 操作数 NaN-boxing 不合法：当规范 NaN
  input  logic               b_canon_nan,
  input  logic               c_canon_nan,
  input  logic               is_fmul,
  input  logic               rm_rdn_s0,
  output logic [SIG_W-1:0]   sig_a,          // 送 Booth 编码器
  output logic [SIG_W-1:0]   sig_b,
  output logic               guard_d,
  output logic               round_d,
  output logic               sticky_d,
  output logic [CAL_W-1:0]   c_aligned_d,
  output logic [EXP_W:0]     exp_greater_d,
  output logic [EXP_W:0]     lshift_max_d,
  output logic [FLT_W-1:0]   zero_result_d,

  // ---- S1 ----
  input  logic               guard_q,
  input  logic               round_q,
  input  logic               sticky_q,
  input  logic [CAL_W-1:0]   c_aligned_q,
  input  logic [EXP_W:0]     lshift_max_q,
  input  logic [2*SIG_W:0]   sum_low,        // 乘积 + c 低 2W 位（最高位是进位）
  output logic [SIG_W+2:0]   c_high,         // c 的高 W+3 位（送核里的共用加 1 器）
  input  logic [SIG_W+2:0]   c_high_plus1,   // 共用加 1 器结果的低 W+3 位（怪癖 7）
  output logic               carry_in,       // 送 CSA 的进位输入（减法且保护位全 0）
  output logic               adder_neg_d,
  output logic [ADD_W-1:0]   tzd_src_d,
  output logic [INV_W-1:0]   lzd_src_d,
  output logic               mask_valid_d,

  // ---- S2 ----
  input  logic               adder_neg_s1_q,
  input  logic [ADD_W-1:0]   tzd_src_q,
  input  logic [INV_W-1:0]   lzd_src_q,
  input  logic               mask_valid_q,
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
  logic [EXP_W-1:0] exp_a, exp_b, exp_c;
  logic [EXP_W-1:0] exp_a_fix, exp_b_fix, exp_c_fix;   // 次正规数（指数字段 0）的指数按 1 算
  logic [SIG_W-1:0] sig_c;
  logic             is_sub_d;

  assign sign_a    = a_word[FLT_W-1];
  assign sign_b    = b_word[FLT_W-1];
  assign sign_c    = c_word[FLT_W-1];
  assign sign_ab   = sign_a ^ sign_b;
  assign exp_a     = a_word[FLT_W-2 : SIG_W-1];
  assign exp_b     = b_word[FLT_W-2 : SIG_W-1];
  assign exp_c     = c_word[FLT_W-2 : SIG_W-1];
  assign exp_a_fix = {exp_a[EXP_W-1:1], ~(|exp_a) | exp_a[0]};
  assign exp_b_fix = {exp_b[EXP_W-1:1], ~(|exp_b) | exp_b[0]};
  assign exp_c_fix = {exp_c[EXP_W-1:1], ~(|exp_c) | exp_c[0]};
  assign sig_a     = {|exp_a, a_word[SIG_W-2:0]};      // 隐含位 = 指数非 0
  assign sig_b     = {|exp_b, b_word[SIG_W-2:0]};
  assign sig_c     = {|exp_c, c_word[SIG_W-2:0]};
  assign is_sub_d  = sign_ab ^ sign_c;

  // ---- 特殊值（不合法 NaN-boxing 的操作数一律当规范 NaN）----
  logic a_is_zero, b_is_zero, c_is_zero;
  logic a_is_nan, b_is_nan, c_is_nan;
  logic a_is_snan, b_is_snan, c_is_snan;
  logic a_is_inf, b_is_inf, c_is_inf;
  assign a_is_zero = ~a_canon_nan & ~(|sig_a);
  assign b_is_zero = ~b_canon_nan & ~(|sig_b);
  assign c_is_zero = ~c_canon_nan & ~(|sig_c);
  assign a_is_nan  = a_canon_nan | ((&exp_a) & (|sig_a[SIG_W-2:0]));
  assign b_is_nan  = b_canon_nan | ((&exp_b) & (|sig_b[SIG_W-2:0]));
  assign c_is_nan  = c_canon_nan | ((&exp_c) & (|sig_c[SIG_W-2:0]));
  assign a_is_snan = ~a_canon_nan & (&exp_a) & ~sig_a[SIG_W-2] & (|sig_a[SIG_W-3:0]);
  assign b_is_snan = ~b_canon_nan & (&exp_b) & ~sig_b[SIG_W-2] & (|sig_b[SIG_W-3:0]);
  assign c_is_snan = ~c_canon_nan & (&exp_c) & ~sig_c[SIG_W-2] & (|sig_c[SIG_W-3:0]);
  assign a_is_inf  = ~a_canon_nan & (&exp_a) & ~(|sig_a[SIG_W-2:0]);
  assign b_is_inf  = ~b_canon_nan & (&exp_b) & ~(|sig_b[SIG_W-2:0]);
  assign c_is_inf  = ~c_canon_nan & (&exp_c) & ~(|sig_c[SIG_W-2:0]);

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

  // a 或 b 为 0 时结果就是 c；c 也为 0 时符号按 IEEE：同号取该号，异号只有 RDN 得 -0；fmul 取乘积符号。
  logic zero_result_sign;
  assign zero_result_sign = c_is_zero ? (is_fmul ? sign_ab : ((sign_ab & sign_c) | (rm_rdn_s0 & (sign_ab ^ sign_c))))
                                      : sign_c;
  assign zero_result_d    = {zero_result_sign, c_word[FLT_W-2:0]};

  // ---- 指数比较：rshift_value = Ea + Eb - bias + (W+3) - Ec，补码，EXP_W+2 位不会溢出 ----
  logic [EXP_W+1:0] exp_ab;         // 乘积指数（已加上窗口基准）
  logic [EXP_W+1:0] rshift_value;   // c 相对窗口最高位要右移的位数（可负）
  logic             c_too_big;      // <= 0：c 不比窗口顶低，不移，直接占窗口顶端
  logic             c_too_small;    // > 窗口宽：c 整个移出窗口，只剩 sticky
  logic             c_medium;
  assign exp_ab       = (EXP_W+2)'(exp_a_fix) + (EXP_W+2)'(exp_b_fix) + (EXP_W+2)'(RSH_BASIC) - (EXP_W+2)'(BIAS);
  assign rshift_value = exp_ab - (EXP_W+2)'(exp_c_fix);
  assign c_too_big    = rshift_value[EXP_W+1] | ~(|rshift_value);
  assign c_too_small  = ~rshift_value[EXP_W+1] & (rshift_value[EXP_W:0] > (EXP_W+1)'(RSH_W));
  assign c_medium     = ~c_too_big & ~c_too_small;

  logic [RSH_W-1:0] rsh_src, rsh_shifted;
  logic             rsh_sticky;
  assign rsh_src = {sig_c, {(RSH_W-SIG_W){1'b0}}};
  xs_FloatFmaShiftRightSticky #(.W(RSH_W), .AMT_W(AMT_W)) u_rsh (
    .src     (rsh_src),
    .amount  (rshift_value[AMT_W-1:0]),
    .shifted (rsh_shifted),
    .sticky  (rsh_sticky)
  );

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

  // ---- S0 级本格式寄存器（fire 使能，不复位）----
  logic is_sub_csa_q, is_sub_adder_q;   // 减法标志：给 CSA 进位输入 / 给保护位取负
  logic sign_c_s0_q, sign_ab_s0_q;
  logic has_zero_s0_q, has_nan_s0_q, has_nan_nv_s0_q, has_inf_s0_q, has_inf_nv_s0_q, inf_sign_s0_q, ab_zero_s0_q;
  always_ff @(posedge clock) begin
    if (fire) begin
      is_sub_csa_q    <= is_sub_d;
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
  if (DUP_IS_SUB) begin : g_is_sub_dup
    logic is_sub_dup_q;
    always_ff @(posedge clock) begin
      if (fire) begin
        is_sub_dup_q <= is_sub_d;
      end
    end
    assign is_sub_adder_q = is_sub_dup_q;
  end else begin : g_is_sub_single
    assign is_sub_adder_q = is_sub_csa_q;
  end

  // ===========================================================================
  // §S1 拼出 3W+5 位的和；判负、取反、算左移上限掩码
  // ===========================================================================
  // 减法时 c 是取反表示，{g, r, s} 整体取负；g = r = s = 0 时取负的进位进到乘积最低位（经 CSA）
  assign carry_in = is_sub_csa_q & ~guard_q & ~round_q & ~sticky_q;

  // 最低两位：右移移出去的 guard / round（减法时取负后的高两位）
  logic [2:0] grs_negated;
  logic [1:0] adder_low2;
  assign grs_negated = ~{guard_q, round_q, sticky_q} + 3'd1;
  assign adder_low2  = is_sub_adder_q ? grs_negated[2:1] : {guard_q, round_q};

  // 高 W+3 位：c 的高段，按低 2W 位加法的进位选"原值 / 加 1"（加 1 在核里，见怪癖 7）
  logic [ADD_W-1:0] adder;
  assign c_high       = c_aligned_q[CAL_W-1 -: SIG_W+3];
  assign adder        = {sum_low[2*SIG_W] ? c_high_plus1 : c_high, sum_low[2*SIG_W-1:0], adder_low2};

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
  for (genvar i = 0; i < ADD_W; i++) begin : g_reverse
    assign tzd_src_d[i] = adder[ADD_W-1-i];
  end

  // ---- S1 级本格式寄存器（fire_s1 使能，不复位）----
  logic [ADD_W-1:0] adder_s1_q;   // 本格式的和（不论当拍格式，三份各自打拍）
  logic sign_result_s1_q, sticky_s1_q, sticky_uf_s1_q, result_zero_s1_q;
  logic has_zero_s1_q, has_nan_s1_q, has_nan_nv_s1_q, has_inf_s1_q, has_inf_nv_s1_q, inf_sign_s1_q, ab_zero_s1_q;
  always_ff @(posedge clock) begin
    if (fire_s1) begin
      adder_s1_q       <= adder;
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
  xs_FloatFmaLzd #(.W(ADD_W), .CNT_W(LZD_W)) u_tzd (
    .in    (tzd_src_q),
    .count (tzd)
  );
  xs_FloatFmaLzd #(.W(INV_W), .CNT_W(LZD_W)) u_lzd (
    .in    (lzd_src_q),
    .count (lzd)
  );
  assign lshift_value_d = lzd;

  // 左移的是没取反的和；负数只把高 W+4 位（尾数 + 舍入位所在段）取反
  logic [ADD_W-1:0] shifted, shifted_inv;
  assign shifted     = adder_s1_q << lzd;
  assign shifted_inv = {shifted[ADD_W-1 -: SIG_W+4] ^ {(SIG_W+4){adder_neg_s1_q}}, shifted[ADD_W-SIG_W-5:0]};

  // tzd + lzd == |和| 的位宽：|和| 只有一个 1（负数取反前是 100..0 之类），取反表示会差一位，少移一位修正
  logic [LZD_W-1:0] tzd_plus_lzd;
  logic [INV_W-1:0] normalized;
  assign tzd_plus_lzd = tzd + lzd;
  assign is_fix_d     = (tzd_plus_lzd == LZD_W'(INV_W));
  assign normalized   = is_fix_d ? shifted_inv[ADD_W-1:1] : shifted_inv[ADD_W-2:0];
  assign frac_d       = normalized[INV_W-2 -: SIG_W-1];   // 最高位是隐含位，其后 W-1 位尾数

  // ---- S2 级本格式寄存器（fire_s2 使能，不复位）----
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

module xs_FloatFMA_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        fire,
  input  logic [63:0] fp_a,
  input  logic [63:0] fp_b,
  input  logic [63:0] fp_c,
  input  logic [2:0]  round_mode,
  input  logic [1:0]  fp_format,
  input  logic [3:0]  op_code,
  input  logic        a_canon_nan,
  input  logic        b_canon_nan,
  input  logic        c_canon_nan,
  output logic [63:0] fp_result,
  output logic [4:0]  fflags
);
  localparam int unsigned SUM_W = 107;   // 压缩树宽度 = 2*53 + 1

  // 公共寄存器的宽度 = f64 通路对应字段的宽度
  localparam int unsigned CAL_W = 162;
  localparam int unsigned ADD_W = 164;
  localparam int unsigned INV_W = 163;

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
  localparam logic [3:0] OP_FMUL = 4'd0, OP_FMACC = 4'd1, OP_FNMACC = 4'd2, OP_FMSAC = 4'd3, OP_FNMSAC = 4'd4;
  logic is_fmul, negate_a, negate_c;
  assign is_fmul  = (op_code == OP_FMUL);
  assign negate_a = (op_code == OP_FNMACC) || (op_code == OP_FNMSAC);
  assign negate_c = (op_code == OP_FNMACC) || (op_code == OP_FMSAC);

  // ===========================================================================
  // 公共寄存器（按当拍格式装三条通路之一的值）
  // ===========================================================================
  // S0 -> S1
  logic             rsh_guard_s0_q, rsh_round_s0_q, rsh_sticky_s0_q;
  logic [CAL_W-1:0] c_aligned_s0_q;
  logic [11:0]      exp_greater_s0_q, exp_greater_s1_q, exp_greater_s2_q;
  logic [11:0]      lshift_max_s0_q;
  logic [63:0]      zero_result_s0_q, zero_result_s1_q, zero_result_s2_q;
  // S1 -> S2
  logic             adder_neg_s1_q, adder_neg_s2_q;
  logic [ADD_W-1:0] tzd_src_s1_q;
  logic [INV_W-1:0] lzd_src_s1_q;
  logic             mask_valid_s1_q;
  // S2 -> S3
  logic [51:0]      frac_s2_q;
  logic             is_fix_s2_q;
  logic [7:0]       lshift_value_s2_q;

  // 三条通路送出的量，零扩展到 f64 通路的宽度。下标：0 = f64，1 = f32，2 = f16
  localparam int unsigned F64 = 0, F32 = 1, F16 = 2;
  logic [2:0][52:0]       fmt_sig_a, fmt_sig_b;
  logic [2:0]             fmt_guard_d, fmt_round_d, fmt_sticky_d;
  logic [2:0][CAL_W-1:0]  fmt_c_aligned_d;
  logic [2:0][11:0]       fmt_exp_greater_d, fmt_lshift_max_d;
  logic [2:0][63:0]       fmt_zero_result_d;
  logic [2:0]             fmt_carry_in;
  logic [2:0][SUM_W-1:0]  fmt_c_low;          // 对齐后的 c 的低 2W 位（送 3:2 的第三个输入）
  logic [2:0]             fmt_adder_neg_d, fmt_mask_valid_d;
  logic [2:0][ADD_W-1:0]  fmt_tzd_src_d;
  logic [2:0][INV_W-1:0]  fmt_lzd_src_d;
  logic [2:0][51:0]       fmt_frac_d;
  logic [2:0]             fmt_is_fix_d;
  logic [2:0][7:0]        fmt_lshift_value_d;
  logic [2:0][63:0]       fmt_result;
  logic [2:0][4:0]        fmt_fflags;

  logic [SUM_W-1:0] sum_low_all;        // S1：乘积 + c 低段（107 位加法结果）
  localparam int unsigned CHI_W = 59;   // c 高段共用加 1 器的宽度
  logic [2:0][CHI_W-1:0] fmt_c_high;
  logic [CHI_W-1:0]      c_high_plus1_all;

  // ===========================================================================
  // 三条格式通路
  // ===========================================================================
  localparam int unsigned FMT_SIG_W [3] = '{53, 24, 11};
  localparam int unsigned FMT_EXP_W [3] = '{11,  8,  5};

  for (genvar f = 0; f < 3; f++) begin : g_fmt
    localparam int unsigned SIG_W   = FMT_SIG_W[f];
    localparam int unsigned EXP_W   = FMT_EXP_W[f];
    localparam int unsigned FLT_W   = SIG_W + EXP_W;
    localparam int unsigned L_CAL_W = 3 * SIG_W + 3;
    localparam int unsigned L_ADD_W = 3 * SIG_W + 5;
    localparam int unsigned L_INV_W = L_ADD_W - 1;
    localparam int unsigned L_LZD_W = $clog2(L_ADD_W + 1);

    // ---- S0 输入：取低 FLT_W 位，改符号 ----
    logic [FLT_W-1:0] a_word, b_word, c_word;
    assign a_word = {fp_a[FLT_W-1] ^ negate_a, fp_a[FLT_W-2:0]};
    assign b_word = fp_b[FLT_W-1:0];
    assign c_word = is_fmul ? '0 : {fp_c[FLT_W-1] ^ negate_c, fp_c[FLT_W-2:0]};

    logic [SIG_W-1:0]   sig_a, sig_b;
    logic               guard_d, round_d, sticky_d;
    logic [L_CAL_W-1:0] c_aligned_d, c_aligned_q;
    logic [EXP_W:0]     exp_greater_d, lshift_max_d;
    logic [FLT_W-1:0]   zero_result_d;
    logic               adder_neg_d, mask_valid_d;
    logic [L_ADD_W-1:0] tzd_src_d;
    logic [L_INV_W-1:0] lzd_src_d;
    logic [SIG_W-2:0]   frac_d;
    logic [L_LZD_W-1:0] lshift_value_d;
    logic [FLT_W-1:0]   result;

    assign c_aligned_q = c_aligned_s0_q[L_CAL_W-1:0];

    assign fmt_sig_a[f]          = 53'(sig_a);
    assign fmt_sig_b[f]          = 53'(sig_b);
    assign fmt_guard_d[f]        = guard_d;
    assign fmt_round_d[f]        = round_d;
    assign fmt_sticky_d[f]       = sticky_d;
    assign fmt_c_aligned_d[f]    = CAL_W'(c_aligned_d);
    assign fmt_exp_greater_d[f]  = 12'(exp_greater_d);
    assign fmt_lshift_max_d[f]   = 12'(lshift_max_d);
    assign fmt_zero_result_d[f]  = 64'(zero_result_d);
    assign fmt_c_low[f]          = SUM_W'(c_aligned_q[2*SIG_W-1:0]);
    logic [SIG_W+2:0] c_high;
    assign fmt_c_high[f]         = CHI_W'(c_high);
    assign fmt_adder_neg_d[f]    = adder_neg_d;
    assign fmt_mask_valid_d[f]   = mask_valid_d;
    assign fmt_tzd_src_d[f]      = ADD_W'(tzd_src_d);
    assign fmt_lzd_src_d[f]      = INV_W'(lzd_src_d);
    assign fmt_frac_d[f]         = 52'(frac_d);
    assign fmt_lshift_value_d[f] = 8'(lshift_value_d);
    assign fmt_result[f]         = 64'(result);

    xs_FloatFmaFormat #(.SIG_W(SIG_W), .EXP_W(EXP_W), .DUP_IS_SUB(f != F64)) u_fmt (
      .clock          (clock),
      .fire           (fire),
      .fire_s1        (fire_s1),
      .fire_s2        (fire_s2),
      // S0
      .a_word         (a_word),
      .b_word         (b_word),
      .c_word         (c_word),
      .a_canon_nan    (a_canon_nan),
      .b_canon_nan    (b_canon_nan),
      .c_canon_nan    (c_canon_nan),
      .is_fmul        (is_fmul),
      .rm_rdn_s0      (rm_onehot[2]),
      .sig_a          (sig_a),
      .sig_b          (sig_b),
      .guard_d        (guard_d),
      .round_d        (round_d),
      .sticky_d       (sticky_d),
      .c_aligned_d    (c_aligned_d),
      .exp_greater_d  (exp_greater_d),
      .lshift_max_d   (lshift_max_d),
      .zero_result_d  (zero_result_d),
      // S1
      .guard_q        (rsh_guard_s0_q),
      .round_q        (rsh_round_s0_q),
      .sticky_q       (rsh_sticky_s0_q),
      .c_aligned_q    (c_aligned_q),
      .lshift_max_q   (lshift_max_s0_q[EXP_W:0]),
      .sum_low        (sum_low_all[2*SIG_W:0]),
      .c_high         (c_high),
      .c_high_plus1   (c_high_plus1_all[SIG_W+2:0]),
      .carry_in       (fmt_carry_in[f]),
      .adder_neg_d    (adder_neg_d),
      .tzd_src_d      (tzd_src_d),
      .lzd_src_d      (lzd_src_d),
      .mask_valid_d   (mask_valid_d),
      // S2
      .adder_neg_s1_q (adder_neg_s1_q),
      .tzd_src_q      (tzd_src_s1_q[L_ADD_W-1:0]),
      .lzd_src_q      (lzd_src_s1_q[L_INV_W-1:0]),
      .mask_valid_q   (mask_valid_s1_q),
      .frac_d         (frac_d),
      .is_fix_d       (fmt_is_fix_d[f]),
      .lshift_value_d (lshift_value_d),
      // S3
      .adder_neg_s2_q (adder_neg_s2_q),
      .frac_q         (frac_s2_q[SIG_W-2:0]),
      .is_fix_q       (is_fix_s2_q),
      .lshift_value_q (lshift_value_s2_q[L_LZD_W-1:0]),
      .exp_greater_q  (exp_greater_s2_q[EXP_W:0]),
      .zero_result_q  (zero_result_s2_q[FLT_W-1:0]),
      .rm_rne         (rm_s2_q[0]),
      .rm_rtz         (rm_s2_q[1]),
      .rm_rdn         (rm_s2_q[2]),
      .rm_rup         (rm_s2_q[3]),
      .rm_rmm         (rm_s2_q[4]),
      .result         (result),
      .fflags         (fmt_fflags[f])
    );
  end

  // ===========================================================================
  // §S0 乘法阵列前半 + 公共寄存器装当拍格式的值
  // ===========================================================================
  // 按当拍格式三选一，优先级"先 f64、再 f32、否则 f16"（golden 处处如此）。
  // （写成显式 if 链而不是用格式号去索引 [2:0] 数组：下标位宽 2 位可表示 3，FM 会判越界。）
  logic [52:0]      booth_in_a, booth_in_b;   // 有效数在低位，高位补 0
  logic             guard_sel_s0, round_sel_s0, sticky_sel_s0;
  logic [CAL_W-1:0] c_aligned_sel_s0;
  logic [11:0]      exp_greater_sel_s0, lshift_max_sel_s0;
  logic [63:0]      zero_result_sel_s0;
  always_comb begin
    int unsigned f;
    f = is_fp64 ? F64 : (is_fp32 ? F32 : F16);
    booth_in_a         = '0;
    booth_in_b         = '0;
    guard_sel_s0       = 1'b0;
    round_sel_s0       = 1'b0;
    sticky_sel_s0      = 1'b0;
    c_aligned_sel_s0   = '0;
    exp_greater_sel_s0 = '0;
    lshift_max_sel_s0  = '0;
    zero_result_sel_s0 = '0;
    for (int unsigned k = 0; k < 3; k++) begin
      if (k == f) begin
        booth_in_a         = fmt_sig_a[k];
        booth_in_b         = fmt_sig_b[k];
        guard_sel_s0       = fmt_guard_d[k];
        round_sel_s0       = fmt_round_d[k];
        sticky_sel_s0      = fmt_sticky_d[k];
        c_aligned_sel_s0   = fmt_c_aligned_d[k];
        exp_greater_sel_s0 = fmt_exp_greater_d[k];
        lshift_max_sel_s0  = fmt_lshift_max_d[k];
        zero_result_sel_s0 = fmt_zero_result_d[k];
      end
    end
  end

  logic [26:0][SUM_W-1:0] booth_pp;
  logic [SUM_W-1:0]       tree_sum, tree_carry;   // 27 -> 2 压缩结果（树内部已打一拍：属于 S1）
  BoothEncoderF64F32F16 U_BoothEncoder (
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

  always_ff @(posedge clock) begin
    if (fire) begin
      rsh_guard_s0_q   <= guard_sel_s0;
      rsh_round_s0_q   <= round_sel_s0;
      rsh_sticky_s0_q  <= sticky_sel_s0;
      c_aligned_s0_q   <= c_aligned_sel_s0;
      exp_greater_s0_q <= exp_greater_sel_s0;
      lshift_max_s0_q  <= lshift_max_sel_s0;
      zero_result_s0_q <= zero_result_sel_s0;
    end
  end

  // ===========================================================================
  // §S1 压缩树结果 + 对齐后的 c 低段做 3:2，再做一次 107 位加法
  //   进位输入 = 压缩树的进位，它最低位恒 0，正好放"减法取负"的 +1。
  // ===========================================================================
  logic             carry_in_sel_s1, adder_neg_sel_s1, mask_valid_sel_s1;
  logic [SUM_W-1:0] c_low_sel_s1;
  logic [CHI_W-1:0] c_high_sel_s1;
  logic [ADD_W-1:0] tzd_src_sel_s1;
  logic [INV_W-1:0] lzd_src_sel_s1;
  always_comb begin
    int unsigned f;
    f = is_fp64_s0_q ? F64 : (is_fp32_s0_q ? F32 : F16);
    carry_in_sel_s1   = 1'b0;
    c_low_sel_s1      = '0;
    c_high_sel_s1     = '0;
    adder_neg_sel_s1  = 1'b0;
    tzd_src_sel_s1    = '0;
    lzd_src_sel_s1    = '0;
    mask_valid_sel_s1 = 1'b0;
    for (int unsigned k = 0; k < 3; k++) begin
      if (k == f) begin
        carry_in_sel_s1   = fmt_carry_in[k];
        c_low_sel_s1      = fmt_c_low[k];
        c_high_sel_s1     = fmt_c_high[k];
        adder_neg_sel_s1  = fmt_adder_neg_d[k];
        tzd_src_sel_s1    = fmt_tzd_src_d[k];
        lzd_src_sel_s1    = fmt_lzd_src_d[k];
        mask_valid_sel_s1 = fmt_mask_valid_d[k];
      end
    end
  end

  // 进位输入：压缩树的进位（最低位换成上面的取负进位），并按格式在向量通道边界清位（怪癖 6）
  logic [SUM_W-1:0] carry_lane_mask;
  assign carry_lane_mask = is_fp64_s0_q ? '1
                         : is_fp32_s0_q ? ~(SUM_W'(1) << 58)
                         :                ~((SUM_W'(1) << 84) | (SUM_W'(1) << 58) | (SUM_W'(1) << 26));

  logic [SUM_W-1:0] final_sum, final_carry;
  CSA3to2 U_CSA3to2 (
    .io_in_a    (tree_sum),
    .io_in_b    ({tree_carry[SUM_W-1:1], carry_in_sel_s1} & carry_lane_mask),
    .io_in_c    (c_low_sel_s1),
    .io_out_sum (final_sum),
    .io_out_car (final_carry)
  );
  assign sum_low_all      = final_sum + final_carry;
  assign c_high_plus1_all = c_high_sel_s1 + 1'b1;   // 当拍格式的 c 高段 + 1，三条通路共用（怪癖 7）

  always_ff @(posedge clock) begin
    if (fire_s1) begin
      adder_neg_s1_q   <= adder_neg_sel_s1;
      tzd_src_s1_q     <= tzd_src_sel_s1;
      lzd_src_s1_q     <= lzd_src_sel_s1;
      mask_valid_s1_q  <= mask_valid_sel_s1;
      exp_greater_s1_q <= exp_greater_s0_q;
      zero_result_s1_q <= zero_result_s0_q;
    end
  end

  // ===========================================================================
  // §S2 规格化结果装公共寄存器
  // ===========================================================================
  logic [51:0] frac_sel_s2;
  logic        is_fix_sel_s2;
  logic [7:0]  lshift_value_sel_s2;
  always_comb begin
    int unsigned f;
    f = is_fp64_s1_q ? F64 : (is_fp32_s1_q ? F32 : F16);
    frac_sel_s2         = '0;
    is_fix_sel_s2       = 1'b0;
    lshift_value_sel_s2 = '0;
    for (int unsigned k = 0; k < 3; k++) begin
      if (k == f) begin
        frac_sel_s2         = fmt_frac_d[k];
        is_fix_sel_s2       = fmt_is_fix_d[k];
        lshift_value_sel_s2 = fmt_lshift_value_d[k];
      end
    end
  end

  always_ff @(posedge clock) begin
    if (fire_s2) begin
      adder_neg_s2_q    <= adder_neg_s1_q;
      frac_s2_q         <= frac_sel_s2;
      is_fix_s2_q       <= is_fix_sel_s2;
      lshift_value_s2_q <= lshift_value_sel_s2;
      exp_greater_s2_q  <= exp_greater_s1_q;
      zero_result_s2_q  <= zero_result_s1_q;
    end
  end

  // ===========================================================================
  // §S3 输出：按格式选通路结果；f32 / f16 高位补 1（NaN-boxing）
  // ===========================================================================
  always_comb begin
    if (is_fp64_s2_q) begin
      fp_result = fmt_result[F64];
      fflags    = fmt_fflags[F64];
    end else if (is_fp32_s2_q) begin
      fp_result = {32'hffff_ffff, fmt_result[F32][31:0]};
      fflags    = fmt_fflags[F32];
    end else begin
      fp_result = {48'hffff_ffff_ffff, fmt_result[F16][15:0]};
      fflags    = fmt_fflags[F16];
    end
  end
endmodule

module FloatFMA (
  input         clock,
  input         reset,
  input         io_fire,
  input  [63:0] io_fp_a,
  input  [63:0] io_fp_b,
  input  [63:0] io_fp_c,
  input  [2:0]  io_round_mode,
  input  [1:0]  io_fp_format,
  input  [3:0]  io_op_code,
  output [63:0] io_fp_result,
  output [4:0]  io_fflags,
  input         io_fp_aIsFpCanonicalNAN,
  input         io_fp_bIsFpCanonicalNAN,
  input         io_fp_cIsFpCanonicalNAN
);
  xs_FloatFMA_core u_core (
    .clock       (clock),
    .reset       (reset),
    .fire        (io_fire),
    .fp_a        (io_fp_a),
    .fp_b        (io_fp_b),
    .fp_c        (io_fp_c),
    .round_mode  (io_round_mode),
    .fp_format   (io_fp_format),
    .op_code     (io_op_code),
    .a_canon_nan (io_fp_aIsFpCanonicalNAN),
    .b_canon_nan (io_fp_bIsFpCanonicalNAN),
    .c_canon_nan (io_fp_cIsFpCanonicalNAN),
    .fp_result   (io_fp_result),
    .fflags      (io_fflags)
  );
endmodule
