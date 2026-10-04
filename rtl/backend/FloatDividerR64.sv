// =============================================================================
// FloatDividerR64.sv —— 标量浮点除法器（SRT 基 4，每拍 3 个商位 = "R64"），f64 / f32 / f16 各一个元素
//
// 在哪一层：标量 FDivSqrt 功能单元里的除法半边（FloatDivider 父级例化；开方另有模块）。
//   一次算一个 a/b，元素放在操作数的低位（f64 用满 64 位、f32 用 [31:0]、f16 用 [15:0]）。
// 设计源：yunsuan/src/main/scala/yunsuan/fpu/FloatDivider.scala class FloatDividerR64。
//   Scala 里的 is_vec_i 与 f_r_s_q_f64_0 / f_r_c_q_f64_0 等未被读的寄存器已被 firtool 消掉，本文件不写。
//
// 状态机（one-hot fsm_q，6 位）：
//   PRE_0(0) 空闲收数 ──start──┬─ 特殊值（NaN/∞/0 结果）────────────────────→ POST_1
//                              ├─ 除数尾数全 0（2 的幂，商 = 被除数尾数）────→ POST_0
//                              ├─ 有一方指数为 0（要先左规）──→ PRE_1 预缩放 → PRE_2
//                              └─ 其余（PRE_0 当拍就做完预缩放）─────────────→ PRE_2
//   PRE_2(2) 装初始余数与整数商位 → ITER(3) 每拍 3 个商位，共 iter_num+1 拍（f16/f32/f64 = 2/4/9 拍）
//   → POST_0(4) 舍入；结果规格数时本拍就给 finish_valid（等 finish_ready），非规格数转 POST_1
//   → POST_1(5) 非规格数结果的舍入 / 特殊值结果输出，等 finish_ready。flush 随时回 PRE_0。
//
// 算法要点：
//   1. 指数差 = (Ea + bias) − lzd_a − Eb + lzd_b（指数 0 当 1 用；非规格数由 ShiftLeftPriorityWithLZDResult
//      求前导零并左移）。PRE_2 拍若被除数尾数 < 除数尾数（iter_num[0]），指数差再减 1、余数初值左移一位。
//   2. 预缩放：按除数尾数最高 3 位查表，被除数与除数同乘 16/8..9/8，把除数压进 qds 常数表的适用区间。
//   3. 商用 on-the-fly 转换同时维护 Q（quo_iter）与 Q−1（quo_m1_iter）两份，最后按余数符号二选一。
//   4. 非规格数结果右移（移位量封顶 54），在 POST_0 把右移后的商与粘滞位暂存进 quo_m1_iter / frac_divisor
//      两个寄存器，POST_1 再舍入。
//
// 怪癖（全部照抄 golden，FM 在所有寄存器取值上比）：
//   - fsm_q 各寄存器的下一态写成"各状态项按位或"（Chisel 的 Fill/Mux1H 写法），非法多热状态下几项叠加。
//   - 商寄存器 / 除数寄存器在不同状态兼作别的用途（见 §6），2 的幂快速通路下 quo_iter 只在 PRE_0 写入。
//   - 溢出判断只比指数差低 12 位（不看符号位）；非规格数结果的指数取"舍入进位"（0 或 1）。
//   - rm 5..7 不在任何舍入项里：等同 RTZ，上溢取最大有限数。
//   - fp_format=0（非法）时操作数被拆成全 0，按"0/0 → NaN"走，只有差分比较约束它。
//   - fp_aIsFpCanonicalNAN / fp_bIsFpCanonicalNAN（NaN-boxing 失败）把该操作数强制当作 quiet NaN。
// 子模块（golden 同名件，本仓已签核重写件）：ShiftLeftPriorityWithLZDResult ×2，fpdiv_r64_block ×1。
// 寄存器名沿用 golden（便于 FM 按名配对与对照阅读）。
// golden 对照：G1-canonical/golden-rtl/FloatDividerR64.sv
// =============================================================================
module xs_FloatDividerR64_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        start_valid,
  output logic        start_ready,
  input  logic        flush,
  input  logic [1:0]  fp_format,     // 2'b01 f16 / 2'b10 f32 / 2'b11 f64
  input  logic [63:0] opa,           // 被除数
  input  logic [63:0] opb,           // 除数
  input  logic [2:0]  rm,
  input  logic        a_is_canonical_nan,
  input  logic        b_is_canonical_nan,
  output logic        finish_valid,
  input  logic        finish_ready,
  output logic [63:0] fpdiv_res,
  output logic [4:0]  fflags         // {NV, DZ, OF, UF, NX}
);
  // ===========================================================================
  // §0 小工具
  // ===========================================================================
  localparam logic [2:0] RM_RNE = 3'd0, RM_RDN = 3'd2, RM_RUP = 3'd3, RM_RMM = 3'd4;

  // 舍入：最低保留位 lsb、舍入位 rnd、粘滞位 stk，按舍入模式判断是否 +1（RTZ 与 5..7 永不进位）
  function automatic logic need_round_up(input logic [2:0] mode, input logic sign,
                                         input logic lsb, input logic rnd, input logic stk);
    need_round_up = (mode == RM_RNE) & (rnd & stk | lsb & rnd)
                  | (mode == RM_RDN) & (rnd | stk) & sign
                  | (mode == RM_RUP) & (rnd | stk) & ~sign
                  | (mode == RM_RMM) & rnd;
  endfunction

  // 上溢时结果取 ∞（否则取最大有限数）：RNE/RMM 恒取 ∞，RUP 正数、RDN 负数取 ∞
  function automatic logic overflow_goes_inf(input logic [2:0] mode, input logic sign);
    overflow_goes_inf = (mode == RM_RNE) | (mode == RM_RMM)
                      | (mode == RM_RUP) & ~sign | (mode == RM_RDN) & sign;
  endfunction

  // 商的 on-the-fly 转换：本级商位 dig（one-hot，[0]=+2 [1]=+1 [2]=0 [3]=-1 [4]=-2）接在 Q / Q−1 后面。
  //   Q' = 4Q + q，(Q−1)' = Q' − 1；q < 0 时从 Q−1 借位。输入 54 位，输出 56 位（调用方截取）。
  function automatic logic [55:0] otf_quo(input logic [4:0] dig, input logic [53:0] q, input logic [53:0] qm1);
    otf_quo = {56{dig[0]}} & {q,   2'd2} | {56{dig[1]}} & {q,   2'd1} | {56{dig[2]}} & {q, 2'd0}
            | {56{dig[3]}} & {qm1, 2'd3} | {56{dig[4]}} & {qm1, 2'd2};
  endfunction
  function automatic logic [55:0] otf_quo_m1(input logic [4:0] dig, input logic [53:0] q, input logic [53:0] qm1);
    otf_quo_m1 = {56{dig[0]}} & {q,   2'd1} | {56{dig[1]}} & {q,   2'd0} | {56{dig[2]}} & {qm1, 2'd3}
               | {56{dig[3]}} & {qm1, 2'd2} | {56{dig[4]}} & {qm1, 2'd1};
  endfunction

  // 预缩放：x = 1.frac（53 位），按除数尾数最高 3 位 sel 乘一个因子 /8：
  //   sel  0   1   2   3   4   5   6   7
  //   ×    16  14  13  12  11  10  9   9      （= 8 + t1 + t2，t1 ∈ {4,2,0}·x，t2 ∈ {4,1,0}·x）
  function automatic logic [56:0] prescale(input logic [51:0] frac, input logic [2:0] sel);
    logic [56:0] x, t1, t2;
    x = {4'b0, 1'b1, frac};
    case (sel)
      3'd0, 3'd2, 3'd3: t1 = x << 2;
      3'd1, 3'd4, 3'd5: t1 = x << 1;
      default:          t1 = '0;
    endcase
    case (sel)
      3'd0, 3'd1:             t2 = x << 2;
      3'd2, 3'd4, 3'd6, 3'd7: t2 = x;
      default:                t2 = '0;
    endcase
    prescale = (x << 3) + (t1 + t2);
  endfunction

  // 舍入前把不属于本格式的位清掉：f32 的尾数在 [52:30]（[24] 是 f32 的舍入位所在列），
  //   f16 的尾数在 [52:43]（[11] 列）；f64 用满 [52:1]。结果 52 位 = 商去掉最低的舍入位。
  function automatic logic [51:0] mask_by_format(input logic [53:0] x, input logic f32, input logic f16);
    mask_by_format = {x[52:25], ~f32 & x[24], x[23:12], ~f16 & x[11], x[10:1]};
  endfunction

  // ===========================================================================
  // §1 状态机（one-hot）与握手
  // ===========================================================================
  localparam int PRE_0 = 0, PRE_1 = 1, PRE_2 = 2, ITER = 3, POST_0 = 4, POST_1 = 5;
  logic [5:0] fsm_q;
  logic [3:0] iter_num_q;          // PRE_0/PRE_1：[0] = 被除数尾数 < 除数尾数；PRE_2 起：剩余迭代拍数
  logic       res_is_denormal;     // 指数差 ≤ 0：结果是非规格数（§5）
  logic       early_finish;        // 结果是 NaN / ∞ / 精确 0，不用迭代（§3）
  logic       b_frac_zero;         // 除数尾数全 0（2 的幂）（§2）
  logic       any_exp_zero;        // 有一方指数为 0，需先左规（§2）
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                     fsm_q <= 6'b1 << PRE_0;
    else if (flush)                fsm_q <= 6'b1 << PRE_0;
    else if (fsm_q == 6'b1 << PRE_0)
      fsm_q <= !start_valid ? 6'b1 << PRE_0
             : early_finish ? 6'b1 << POST_1
             : b_frac_zero  ? 6'b1 << POST_0
             : any_exp_zero ? 6'b1 << PRE_1
             :                6'b1 << PRE_2;
    else if (fsm_q == 6'b1 << PRE_1) fsm_q <= 6'b1 << PRE_2;
    else if (fsm_q == 6'b1 << PRE_2) fsm_q <= 6'b1 << ITER;
    else if (fsm_q == 6'b1 << ITER)  fsm_q <= (|iter_num_q) ? 6'b1 << ITER : 6'b1 << POST_0;
    else if (fsm_q == 6'b1 << POST_0)
      fsm_q <= res_is_denormal ? 6'b1 << POST_1 : finish_ready ? 6'b1 << PRE_0 : 6'b1 << POST_0;
    else if (fsm_q == 6'b1 << POST_1 && !finish_ready) fsm_q <= 6'b1 << POST_1;
    else                           fsm_q <= 6'b1 << PRE_0;   // POST_1 握手完成，或非法状态
  end
  assign start_ready = fsm_q[PRE_0];

  logic start_hs;                  // 收数握手
  assign start_hs = start_valid & fsm_q[PRE_0];

  // ===========================================================================
  // §2 操作数拆包：按格式取符号 / 指数 / 尾数（尾数左对齐到 52 位，低位补 0）
  // ===========================================================================
  logic in_f16, in_f32, in_f64;
  assign in_f16 = fp_format == 2'd1;
  assign in_f32 = fp_format == 2'd2;
  assign in_f64 = &fp_format;

  logic        a_sign, b_sign;
  logic [10:0] a_exp, b_exp, exp_max;
  logic [51:0] a_frac, b_frac;
  always_comb begin
    a_sign  = in_f64 & opa[63] | in_f32 & opa[31] | in_f16 & opa[15];
    b_sign  = in_f64 & opb[63] | in_f32 & opb[31] | in_f16 & opb[15];
    a_exp   = {11{in_f64}} & opa[62:52] | {11{in_f32}} & {3'b0, opa[30:23]} | {11{in_f16}} & {6'b0, opa[14:10]};
    b_exp   = {11{in_f64}} & opb[62:52] | {11{in_f32}} & {3'b0, opb[30:23]} | {11{in_f16}} & {6'b0, opb[14:10]};
    exp_max = {11{in_f64}} | (in_f32 ? 11'hFF : 11'h0) | (in_f16 ? 11'h1F : 11'h0);
    a_frac  = {52{in_f64}} & opa[51:0] | {52{in_f32}} & {opa[22:0], 29'b0} | {52{in_f16}} & {opa[9:0], 42'b0};
    b_frac  = {52{in_f64}} & opb[51:0] | {52{in_f32}} & {opb[22:0], 29'b0} | {52{in_f16}} & {opb[9:0], 42'b0};
  end

  logic a_exp_zero, b_exp_zero, a_exp_max, b_exp_max, a_frac_zero;
  assign a_exp_zero   = a_exp == '0;
  assign b_exp_zero   = b_exp == '0;
  assign a_exp_max    = a_exp == exp_max;
  assign b_exp_max    = b_exp == exp_max;
  assign a_frac_zero  = ~|a_frac;
  assign b_frac_zero  = ~|b_frac;
  assign any_exp_zero = a_exp_zero | b_exp_zero;

  // ===========================================================================
  // §3 特殊值分类（canonical-NaN 标志强制把该操作数当 quiet NaN）
  // ===========================================================================
  logic a_zero, b_zero, a_inf, b_inf, a_snan, b_snan, a_qnan, b_qnan;
  logic op_invalid, res_nan, res_inf, res_exact_zero, div_by_zero, out_sign;
  always_comb begin
    a_zero = ~a_is_canonical_nan & a_exp_zero & a_frac_zero;
    b_zero = ~b_is_canonical_nan & b_exp_zero & b_frac_zero;
    a_inf  = ~a_is_canonical_nan & a_exp_max & a_frac_zero;
    b_inf  = ~b_is_canonical_nan & b_exp_max & b_frac_zero;
    a_snan = ~a_is_canonical_nan & a_exp_max & ~a_frac[51] & ~a_frac_zero;
    b_snan = ~b_is_canonical_nan & b_exp_max & ~b_frac[51] & ~b_frac_zero;
    a_qnan = a_is_canonical_nan | a_exp_max & a_frac[51];
    b_qnan = b_is_canonical_nan | b_exp_max & b_frac[51];
    op_invalid     = a_inf & b_inf | a_zero & b_zero | a_snan | b_snan;   // ∞/∞、0/0、sNaN
    res_nan        = a_qnan | a_snan | b_qnan | b_snan | op_invalid;
    res_inf        = a_inf | b_zero;                                       // ∞/x、x/0
    res_exact_zero = a_zero | b_inf;                                       // 0/x、x/∞
    div_by_zero    = ~res_nan & ~a_inf & b_zero;
    out_sign       = ~res_nan & (a_sign ^ b_sign);                         // NaN 结果恒正号
  end
  assign early_finish = res_nan | res_inf | res_exact_zero;

  // PRE_0 收数时锁存的标志
  logic       opb_is_power_of_2_q;   // 除数尾数全 0：商就是被除数尾数，不迭代
  logic [2:0] fp_format_onehot_q;    // {f64, f32, f16}
  logic [2:0] rm_q;
  logic       out_sign_q, res_is_nan_q, res_is_inf_q, res_is_exact_zero_q;
  logic       op_invalid_div_q, divided_by_zero_q;
  always_ff @(posedge clock) begin
    if (start_hs) begin
      opb_is_power_of_2_q <= b_frac_zero;
      fp_format_onehot_q  <= {in_f64, in_f32, in_f16};
      rm_q                <= rm;
      out_sign_q          <= out_sign;
      res_is_nan_q        <= res_nan;
      res_is_inf_q        <= res_inf;
      res_is_exact_zero_q <= res_exact_zero;
      op_invalid_div_q    <= op_invalid;
      divided_by_zero_q   <= div_by_zero;
    end
  end
  logic fmt16_q, fmt32_q;
  assign fmt16_q = fp_format_onehot_q[0];
  assign fmt32_q = fp_format_onehot_q[1];

  // ===========================================================================
  // §4 非规格数左规：前导零计数 + 左移（前补 1 个 0 位）
  // ===========================================================================
  logic [52:0] a_lsh, b_lsh;
  logic [5:0]  a_lzd, b_lzd;
  ShiftLeftPriorityWithLZDResult U_Left_Shift_opa_f64_0 (
    .io_src                 ({1'b0, a_frac}),
    .io_priority_shiftValue ({1'b0, a_frac}),
    .io_lshift_result       (a_lsh),
    .io_lzd_result          (a_lzd)
  );
  ShiftLeftPriorityWithLZDResult U_Left_Shift_opb_f64_0 (
    .io_src                 ({1'b0, b_frac}),
    .io_priority_shiftValue ({1'b0, b_frac}),
    .io_lshift_result       (b_lsh),
    .io_lzd_result          (b_lzd)
  );

  // 规格化后的尾数（指数为 0 时取左移结果，去掉隐含 1 那一位）
  logic [51:0] a_norm, b_norm;
  assign a_norm = a_exp_zero ? a_lsh[51:0] : a_frac;
  assign b_norm = b_exp_zero ? b_lsh[51:0] : b_frac;

  // ===========================================================================
  // §5 商的指数差（13 位，最高位当符号）：PRE_0 装初值，PRE_2 再减 iter_num[0]
  // ===========================================================================
  logic [12:0] out_exp_diff_q_f64_0;
  logic [11:0] bias;
  assign bias = in_f16 ? 12'hF : in_f32 ? 12'h7F : 12'h3FF;
  always_ff @(posedge clock) begin
    if (start_hs | fsm_q[PRE_2]) begin
      if (fsm_q[PRE_0])
        out_exp_diff_q_f64_0 <= 13'({1'b0, 12'({1'b0, a_exp | 11'(a_exp_zero)} + bias)})
                              - 13'({6{a_exp_zero}} & a_lzd)
                              - 13'(b_exp | 11'(b_exp_zero))
                              + 13'({6{b_exp_zero}} & b_lzd);
      else
        out_exp_diff_q_f64_0 <= out_exp_diff_q_f64_0 - 13'(iter_num_q[0]);
    end
  end
  assign res_is_denormal = out_exp_diff_q_f64_0[11:0] == '0 | out_exp_diff_q_f64_0[12];

  // ===========================================================================
  // §6 商寄存器 quo_iter（Q）/ quo_m1_iter（Q−1）、除数寄存器，以及预缩放
  //   两个商寄存器在不同状态兼作别的用途：
  //     PRE_0：无需左规 → Q ← 缩放后被除数低 54 位，Q−1 ← 其最高 3 位；
  //            需左规   → Q ← 1.被除数尾数（规格化后），Q−1 ← 1.除数尾数（留给 PRE_1 缩放）；
  //            除数 2 的幂 → Q ← 按格式右对齐的 1.被除数尾数（直接就是商）
  //     PRE_1：Q ← 缩放后被除数低位，Q−1 ← 最高 3 位；除数寄存器 ← 缩放后除数
  //     ITER ：Q / Q−1 每拍做 3 级 on-the-fly 转换
  //     POST_0：Q−1 ← 规格数：舍入后的尾数；非规格数：{余数非零, 右移后的商}；除数寄存器 ← 右移丢掉的位
  // ===========================================================================
  logic [53:0] quo_iter_q_f64_0, quo_m1_iter_q_f64_0;
  logic [59:0] frac_divisor_q_60bit;     // 低 3 位恒 0；[59:3] 是 57 位缩放后除数
  logic [56:0] divisor_q;
  assign divisor_q = frac_divisor_q_60bit[59:3];

  // 预缩放的源：PRE_0 直接取操作数尾数，PRE_1 取寄存器里规格化后的尾数
  logic [51:0] prescale_a_src, prescale_b_src;
  logic [56:0] scaled_a, scaled_b;
  assign prescale_a_src = fsm_q[PRE_0] ? a_frac : quo_iter_q_f64_0[51:0];
  assign prescale_b_src = fsm_q[PRE_0] ? b_frac : quo_m1_iter_q_f64_0[51:0];
  assign scaled_a = prescale(prescale_a_src, prescale_b_src[51:49]);
  assign scaled_b = prescale(prescale_b_src, prescale_b_src[51:49]);

  // 除数 2 的幂时的商：1.被除数尾数按格式右对齐（f32 取高 23 位、f16 取高 10 位）
  logic [53:0] pow2_quo;
  assign pow2_quo = in_f64 ? {2'b01, a_norm}
                  : in_f32 ? {31'b1, a_norm[51:29]}
                  :          {44'b1, a_norm[51:42]};

  // ITER：本拍 3 级商位（prev_quo_dig 来自上拍，dig0/dig1 来自迭代块）
  logic [4:0]  prev_quo_dig_q_f64_0, quo_dig_0, quo_dig_1, quo_dig_2;
  //   第 0 级（接 prev_quo_dig）保留 56 位：收尾时 §8 还要从它取完整商；第 1/2 级只要低 54 位。
  logic [55:0] quo_lv0, quo_m1_lv0;
  logic [53:0] quo_lv1, quo_m1_lv1, quo_lv2, quo_m1_lv2;
  always_comb begin
    quo_lv0    = otf_quo   (prev_quo_dig_q_f64_0, quo_iter_q_f64_0, quo_m1_iter_q_f64_0);
    quo_m1_lv0 = otf_quo_m1(prev_quo_dig_q_f64_0, quo_iter_q_f64_0, quo_m1_iter_q_f64_0);
    quo_lv1    = 54'(otf_quo   (quo_dig_0, quo_lv0[53:0], quo_m1_lv0[53:0]));
    quo_m1_lv1 = 54'(otf_quo_m1(quo_dig_0, quo_lv0[53:0], quo_m1_lv0[53:0]));
    quo_lv2    = 54'(otf_quo   (quo_dig_1, quo_lv1, quo_m1_lv1));
    quo_m1_lv2 = 54'(otf_quo_m1(quo_dig_1, quo_lv1, quo_m1_lv1));
  end

  // POST_0 写回 Q−1 / 除数寄存器所需的值（§8 算出）
  logic        rem_is_not_zero;
  logic [52:0] corr_quo_r_shifted;
  logic [53:0] sticky_without_rem;
  logic [51:0] out_frac_post0_f64;

  always_ff @(posedge clock) begin
    // Q：2 的幂快速通路下只在 PRE_0 写一次（之后保持，POST_0 直接读它）
    if ((start_hs | fsm_q[PRE_1] | fsm_q[PRE_2] | fsm_q[ITER]) & (start_hs | ~opb_is_power_of_2_q))
      quo_iter_q_f64_0 <=
          {54{fsm_q[PRE_0]}} & (b_frac_zero  ? pow2_quo
                              : any_exp_zero ? {2'b01, a_norm}
                              :                scaled_a[53:0])
        | {54{fsm_q[PRE_1]}} & scaled_a[53:0]
        | {54{fsm_q[ITER]}}  & quo_lv2;                // PRE_2 项为 0：清零准备迭代
    if (start_hs | fsm_q[PRE_1] | fsm_q[ITER] | fsm_q[POST_0] & res_is_denormal)
      quo_m1_iter_q_f64_0 <=
          {54{fsm_q[PRE_0]}}  & (any_exp_zero ? {2'b01, b_norm} : {51'b0, scaled_a[56:54]})
        | {54{fsm_q[PRE_1]}}  & {51'b0, scaled_a[56:54]}
        | {54{fsm_q[ITER]}}   & quo_m1_lv2
        | {54{fsm_q[POST_0]}} & (res_is_denormal ? {rem_is_not_zero, corr_quo_r_shifted}
                                                 : {2'b0, out_frac_post0_f64});
    if (start_hs | fsm_q[PRE_1] | fsm_q[PRE_2] | fsm_q[POST_0])
      frac_divisor_q_60bit <= {
        fsm_q[POST_0] & ~res_is_denormal
          ? divisor_q                                  // 规格数结果：保持
          : {57{fsm_q[PRE_0]}}  & (any_exp_zero ? divisor_q : scaled_b)
          | {57{fsm_q[PRE_1]}}  & scaled_b
          | {57{fsm_q[PRE_2]}}  & divisor_q
          | {57{fsm_q[POST_0]}} & {3'b0, sticky_without_rem},
        3'b0};
  end

  // 迭代计数 / 尾数比较位
  always_ff @(posedge clock) begin
    if (start_hs | fsm_q[PRE_1] | fsm_q[PRE_2] | fsm_q[ITER]) begin
      if (fsm_q[PRE_0])      iter_num_q <= {3'b0, a_frac < b_frac};
      else if (fsm_q[PRE_1]) iter_num_q <= {3'b0, quo_iter_q_f64_0[51:0] < quo_m1_iter_q_f64_0[51:0]};
      else if (fsm_q[PRE_2]) iter_num_q <= fmt16_q ? 4'd1 : fmt32_q ? 4'd3 : 4'd8;
      else                   iter_num_q <= iter_num_q - 4'd1;
    end
  end

  // ===========================================================================
  // §7 余数（冗余 sum/carry 两份）与迭代块
  //   PRE_2 装初值：缩放后被除数（尾数较小时左移一位）减去 1 或 2 倍除数（整数商位 +1 / +2），
  //   同时预算下一拍 qds 要用的 6/7 位余数片；ITER 每拍取迭代块的输出。
  // ===========================================================================
  logic [5:0]  nr_f_r_6b_for_nxt_cycle_s0_qds_q_f64_0;
  logic [6:0]  nr_f_r_7b_for_nxt_cycle_s1_qds_q_f64_0;
  logic [71:0] f_r_s_q_72bit, f_r_c_q_72bit;

  logic [57:0] rem_init_s;           // 缩放后被除数（57 位），按 iter_num[0] 左移 0/1 位
  logic        integer_quo_is_pos_2;
  logic [59:0] rem_init_c;           // −2D 或 −D 的反码形式（+1 已并进 sum 的固定 1 位）
  always_comb begin
    rem_init_s = iter_num_q[0] ? {quo_m1_iter_q_f64_0[2:0], quo_iter_q_f64_0, 1'b0}
                               : {1'b0, quo_m1_iter_q_f64_0[2:0], quo_iter_q_f64_0};
    integer_quo_is_pos_2 = rem_init_s[57] | (&rem_init_s[56:55]);
    rem_init_c = integer_quo_is_pos_2 ? {1'b1, ~divisor_q, 2'b11} : {2'b11, ~divisor_q, 1'b1};
  end

  logic [71:0] blk_f_r_s, blk_f_r_c;
  logic [5:0]  blk_adder_6b;
  logic [6:0]  blk_adder_7b;
  fpdiv_r64_block u_r64_block_vector (
    .io_f_r_s_i                             (f_r_s_q_72bit),
    .io_f_r_c_i                             (f_r_c_q_72bit),
    .io_divisor_i                           (frac_divisor_q_60bit),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i    (nr_f_r_6b_for_nxt_cycle_s0_qds_q_f64_0),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i    (nr_f_r_7b_for_nxt_cycle_s1_qds_q_f64_0),
    .io_nxt_quo_dig_o_0_0                   (quo_dig_0),
    .io_nxt_quo_dig_o_0_1                   (quo_dig_1),
    .io_nxt_quo_dig_o_0_2                   (quo_dig_2),
    .io_nxt_f_r_s_o_2                       (blk_f_r_s),
    .io_nxt_f_r_c_o_2                       (blk_f_r_c),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o (blk_adder_6b),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o (blk_adder_7b)
  );

  always_ff @(posedge clock) begin
    if (start_hs | fsm_q[PRE_2] | fsm_q[ITER]) begin
      if (fsm_q[PRE_2]) begin
        nr_f_r_6b_for_nxt_cycle_s0_qds_q_f64_0 <= 6'(rem_init_s[56:51] + rem_init_c[57:52]);
        nr_f_r_7b_for_nxt_cycle_s1_qds_q_f64_0 <= 7'(rem_init_s[54:48] + rem_init_c[55:49]);
        f_r_s_q_72bit        <= {1'b0, rem_init_s, 13'h1000};
        f_r_c_q_72bit        <= {rem_init_c, 12'h0};
        prev_quo_dig_q_f64_0 <= {3'b0, ~integer_quo_is_pos_2, integer_quo_is_pos_2};
      end else begin
        nr_f_r_6b_for_nxt_cycle_s0_qds_q_f64_0 <= blk_adder_6b;
        nr_f_r_7b_for_nxt_cycle_s1_qds_q_f64_0 <= blk_adder_7b;
        f_r_s_q_72bit        <= blk_f_r_s;
        f_r_c_q_72bit        <= blk_f_r_c;
        prev_quo_dig_q_f64_0 <= quo_dig_2;
      end
    end
  end

  // ===========================================================================
  // §8 收尾：最终余数符号 → 选 Q 或 Q−1；非规格数右移；舍入
  // ===========================================================================
  // 最终余数：符号位 = 两份冗余余数相加的最高位；非零 = 和不为 0（用异或/或比较免去全加）
  logic [59:0] rem_sum;
  logic        select_quo_m1;
  always_comb begin
    rem_sum         = 60'(f_r_s_q_72bit[71:12] + f_r_c_q_72bit[71:12]);
    rem_is_not_zero = ~opb_is_power_of_2_q
                    & (rem_sum[59] | (f_r_s_q_72bit[70:13] ^ f_r_c_q_72bit[70:13])
                                     != (f_r_s_q_72bit[69:12] | f_r_c_q_72bit[69:12]));
    select_quo_m1   = rem_sum[59] & ~opb_is_power_of_2_q;      // 余数为负：真商是 Q−1
  end

  // 舍入前的商（54 位，[53:1] 有效尾数，[0] 舍入位）。用的是"最后一拍迭代之后再走一级"：
  //   ITER 末拍写进寄存器的是 Q，此处再接 prev_quo_dig 得到完整商；f32 的商少一位，跳过 [25]。
  logic [53:0] quo_pre_shift, quo_m1_pre_shift;
  always_comb begin
    quo_pre_shift    = opb_is_power_of_2_q
                     ? {quo_iter_q_f64_0[52:0], 1'b0}
                     : {quo_lv0[54:26], fmt32_q ? quo_lv0[24:0] : quo_lv0[25:1]};
    quo_m1_pre_shift = {quo_m1_lv0[54:26], fmt32_q ? quo_m1_lv0[24:0] : quo_m1_lv0[25:1]};
  end

  // 非规格数结果的右移：t = 1 − 指数差；t ≤ 0 不移，0 < t < 54 移 t，否则封顶 54
  logic [12:0]  shift_t, shift_t_minus_limit;
  logic [5:0]   r_shift_num;
  logic [107:0] quo_r_shifted, quo_m1_r_shifted;
  always_comb begin
    shift_t             = 13'(13'd1 - out_exp_diff_q_f64_0);
    shift_t_minus_limit = 13'(shift_t - 13'd54);
    r_shift_num         = shift_t[12] ? 6'd0 : shift_t_minus_limit[12] ? shift_t[5:0] : 6'd54;
    quo_r_shifted       = {quo_pre_shift, 54'b0} >> r_shift_num;
    quo_m1_r_shifted    = {quo_m1_pre_shift, 54'b0} >> r_shift_num;
    corr_quo_r_shifted  = select_quo_m1 ? quo_m1_r_shifted[106:54] : quo_r_shifted[106:54];
    sticky_without_rem  = select_quo_m1 ? quo_m1_r_shifted[53:0]   : quo_r_shifted[53:0];
  end

  // 舍入。POST_0 拍（或规格数）用本拍算出的商；POST_1 拍（非规格数）用 POST_0 暂存进 Q−1 / 除数寄存器的值。
  logic        normal_path;
  logic [51:0] quo_pre_inc, quo_m1_pre_inc, quo_m1_inc_res, quo_m1_rounded, frac_rounded_post0;
  logic [52:0] quo_inc_res, quo_rounded;
  logic        guard_bit, round_bit, sticky_bit, quo_need_rup, quo_m1_need_rup, inexact_quo, inexact;
  logic        carry_after_round, overflow, overflow_to_inf;
  always_comb begin
    normal_path    = fsm_q[POST_0] | ~res_is_denormal;
    quo_pre_inc    = fsm_q[POST_0] ? mask_by_format(quo_pre_shift, fmt32_q, fmt16_q)
                                   : mask_by_format(quo_m1_iter_q_f64_0, fmt32_q, fmt16_q);
    quo_m1_pre_inc = mask_by_format(quo_m1_pre_shift, fmt32_q, fmt16_q);
    quo_inc_res    = 53'({1'b0, quo_pre_inc} + 53'd1);
    // Q−1 + 1 = Q；Q−1 的进位结果直接借用 Q 的 +1（两者最低位相同时）或 Q 本身
    quo_m1_inc_res = (quo_pre_inc[0] == quo_m1_pre_inc[0]) ? quo_inc_res[51:0] : quo_pre_inc;

    guard_bit  = normal_path ? quo_pre_shift[1] : quo_m1_iter_q_f64_0[1];
    round_bit  = normal_path ? quo_pre_shift[0] : quo_m1_iter_q_f64_0[0];
    sticky_bit = normal_path ? rem_is_not_zero
                             : quo_m1_iter_q_f64_0[53] | (|divisor_q);
    quo_need_rup    = need_round_up(rm_q, out_sign_q, guard_bit, round_bit, sticky_bit);
    quo_m1_need_rup = need_round_up(rm_q, out_sign_q, quo_m1_pre_shift[1], quo_m1_pre_shift[0], 1'b1);
    inexact_quo     = round_bit | sticky_bit;
    inexact         = normal_path & select_quo_m1 | inexact_quo;

    quo_rounded        = quo_need_rup ? quo_inc_res : {1'b0, quo_pre_inc};
    quo_m1_rounded     = quo_m1_need_rup ? quo_m1_inc_res : quo_m1_pre_inc;
    frac_rounded_post0 = select_quo_m1 ? quo_m1_rounded : quo_rounded[51:0];
    carry_after_round  = fmt16_q ? quo_rounded[10] : fmt32_q ? quo_rounded[23] : quo_rounded[52];
    overflow           = out_exp_diff_q_f64_0[11:0] >= (fmt16_q ? 12'h1F : fmt32_q ? 12'hFF : 12'h7FF);
    overflow_to_inf    = overflow_goes_inf(rm_q, out_sign_q);
  end

  // ===========================================================================
  // §9 结果拼装
  //   POST_0（规格数）：上溢时取 ∞ 或最大有限数，否则指数差 + 舍入后尾数
  //   POST_1：特殊值（NaN 取正号 quiet NaN）/ 非规格数（指数 = 舍入进位）/ 否则是 POST_0 暂存在 Q−1 的尾数
  //   输出 64 位：[63:32] 恒为 f64 拼法，[31:16] f32 时换成 f32 拼法，[15:0] 按格式选
  // ===========================================================================
  logic        sat_inf, sat_max;
  logic [10:0] post0_exp_f64;
  logic [7:0]  post0_exp_f32;
  logic [4:0]  post0_exp_f16;
  logic [22:0] post0_frac_f32;
  logic [9:0]  post0_frac_f16;
  always_comb begin
    sat_inf = overflow & overflow_to_inf;
    sat_max = overflow & ~overflow_to_inf;
    post0_exp_f64      = sat_inf ? 11'h7FF : sat_max ? 11'h7FE : out_exp_diff_q_f64_0[10:0];
    post0_exp_f32      = sat_inf ? 8'hFF   : sat_max ? 8'hFE   : out_exp_diff_q_f64_0[7:0];
    post0_exp_f16      = sat_inf ? 5'h1F   : sat_max ? 5'h1E   : out_exp_diff_q_f64_0[4:0];
    out_frac_post0_f64 = sat_inf ? '0 : sat_max ? '1 : frac_rounded_post0;
    post0_frac_f32     = sat_inf ? '0 : sat_max ? '1 : frac_rounded_post0[22:0];
    post0_frac_f16     = sat_inf ? '0 : sat_max ? '1 : frac_rounded_post0[9:0];
  end

  logic        post1_special, post1_all_ones_exp, post1_zero_frac;
  logic [10:0] post1_exp_f64;
  logic [7:0]  post1_exp_f32;
  logic [4:0]  post1_exp_f16;
  logic [51:0] post1_frac_f64;
  logic [22:0] post1_frac_f32;
  logic [9:0]  post1_frac_f16;
  always_comb begin
    post1_special      = res_is_denormal | res_is_nan_q | res_is_inf_q | res_is_exact_zero_q;
    post1_all_ones_exp = res_is_nan_q | res_is_inf_q;
    post1_zero_frac    = res_is_inf_q | res_is_exact_zero_q;
    post1_exp_f64  = !post1_special ? post0_exp_f64
                   : post1_all_ones_exp ? 11'h7FF : res_is_exact_zero_q ? 11'h0 : 11'(carry_after_round);
    post1_exp_f32  = !post1_special ? post0_exp_f32
                   : post1_all_ones_exp ? 8'hFF : res_is_exact_zero_q ? 8'h0 : 8'(carry_after_round);
    post1_exp_f16  = !post1_special ? post0_exp_f16
                   : post1_all_ones_exp ? 5'h1F : res_is_exact_zero_q ? 5'h0 : 5'(carry_after_round);
    post1_frac_f64 = !post1_special ? quo_m1_iter_q_f64_0[51:0]
                   : res_is_nan_q ? 52'h8_0000_0000_0000 : post1_zero_frac ? '0 : quo_rounded[51:0];
    post1_frac_f32 = !post1_special ? quo_m1_iter_q_f64_0[22:0]
                   : res_is_nan_q ? 23'h40_0000 : post1_zero_frac ? '0 : quo_rounded[22:0];
    post1_frac_f16 = !post1_special ? quo_m1_iter_q_f64_0[9:0]
                   : res_is_nan_q ? 10'h200 : post1_zero_frac ? '0 : quo_rounded[9:0];
  end

  logic [63:0] res_post0, res_post1;
  always_comb begin
    res_post0 = {out_sign_q, post0_exp_f64, out_frac_post0_f64[51:32],
                 fmt32_q ? {out_sign_q, post0_exp_f32, post0_frac_f32[22:16]} : out_frac_post0_f64[31:16],
                 fmt16_q ? {out_sign_q, post0_exp_f16, post0_frac_f16}
                         : fmt32_q ? post0_frac_f32[15:0] : out_frac_post0_f64[15:0]};
    res_post1 = {out_sign_q, post1_exp_f64, post1_frac_f64[51:32],
                 fmt32_q ? {out_sign_q, post1_exp_f32, post1_frac_f32[22:16]} : post1_frac_f64[31:16],
                 fmt16_q ? {out_sign_q, post1_exp_f16, post1_frac_f16}
                         : fmt32_q ? post1_frac_f32[15:0] : post1_frac_f64[15:0]};
  end
  assign fpdiv_res    = fsm_q[POST_0] ? res_post0 : res_post1;
  assign finish_valid = fsm_q[POST_1] | fsm_q[POST_0] & ~res_is_denormal;

  // 异常标志：NV、DZ 取 PRE_0 锁存值；OF 在 POST_0 拍或（POST_1 且规格数非特殊值）；
  //   UF 只在 POST_1 的非规格数上判（tininess after rounding：舍入后没进位到规格数，
  //   或按"无界指数先舍入"也进不上去）；NX = OF 或非精确，特殊值不报。
  logic not_special, sticky_correct, flag_of, flag_uf, flag_nx;
  always_comb begin
    not_special    = ~res_is_exact_zero_q & ~res_is_inf_q & ~res_is_nan_q;
    sticky_correct = select_quo_m1 | (|sticky_without_rem[52:0]) | rem_is_not_zero;
    flag_of = fsm_q[POST_0] & overflow
            | fsm_q[POST_1] & ~res_is_denormal & overflow & not_special;
    flag_uf = res_is_denormal & fsm_q[POST_1]
            & (~carry_after_round
               | ~(corr_quo_r_shifted[0]
                   & need_round_up(rm_q, out_sign_q, corr_quo_r_shifted[0], sticky_without_rem[53], sticky_correct)))
            & inexact & not_special;
    flag_nx = (flag_of | inexact) & not_special;
  end
  assign fflags = {op_invalid_div_q, divided_by_zero_q, flag_of, flag_uf, flag_nx};
endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper：端口逐位同名，直接连核
// -----------------------------------------------------------------------------
module FloatDividerR64 (
  input  logic        clock,
  input  logic        reset,
  input  logic        io_start_valid_i,
  output logic        io_start_ready_o,
  input  logic        io_flush_i,
  input  logic [1:0]  io_fp_format_i,
  input  logic [63:0] io_opa_i,
  input  logic [63:0] io_opb_i,
  input  logic [2:0]  io_rm_i,
  input  logic        io_fp_aIsFpCanonicalNAN,
  input  logic        io_fp_bIsFpCanonicalNAN,
  output logic        io_finish_valid_o,
  input  logic        io_finish_ready_i,
  output logic [63:0] io_fpdiv_res_o,
  output logic [4:0]  io_fflags_o
);
  xs_FloatDividerR64_core u_core (
    .clock              (clock),
    .reset              (reset),
    .start_valid        (io_start_valid_i),
    .start_ready        (io_start_ready_o),
    .flush              (io_flush_i),
    .fp_format          (io_fp_format_i),
    .opa                (io_opa_i),
    .opb                (io_opb_i),
    .rm                 (io_rm_i),
    .a_is_canonical_nan (io_fp_aIsFpCanonicalNAN),
    .b_is_canonical_nan (io_fp_bIsFpCanonicalNAN),
    .finish_valid       (io_finish_valid_o),
    .finish_ready       (io_finish_ready_i),
    .fpdiv_res          (io_fpdiv_res_o),
    .fflags             (io_fflags_o)
  );
endmodule
