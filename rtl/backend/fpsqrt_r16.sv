// =============================================================================
// fpsqrt_r16.sv —— 标量浮点开方器（基 16 = 每拍 2 个基 4 根位；f16 / f32 / f64 一次一个数）
//
// 在哪一层：FloatDivider（FDivSqrt 的标量除/开方器）里的开方通路 u_vector_float_sqrt_r16。
//   本件是开方器的控制 + 前后处理；每拍的 SRT 迭代由 child fpsqrt_r16_block 完成（只用它的 lane0，
//   lane1..3 的 QDS 输入接 0、输出不用）。
// 设计源：yunsuan/fpu/fqrt/fpsqrt_r16.scala（与向量版 fpsqrt_vector_r16 同一套算法的标量化）。
//   操作数在 op_i 低位：f16 [15:0]、f32 [31:0]、f64 [63:0]；fp_format_i：0=f16 1=f32 2=f64
//   （3 非法：三个格式位全 0）；fp_fmt_q = {f64, f32, f16} one-hot 打拍。
//
// 状态机（fsm_q one-hot，异步复位到 PRE_0；其余寄存器都不复位）：
//   PRE_0  空闲/接收：start_valid 握手当拍预解码操作数（分类、指数、前导零）。
//          NaN / Inf / 零 / 尾数全 0（结果为 1 或 √2 的幂，直接出）→ 提前结束进 POST_0；
//          规格数 → 当拍做迭代初始化进 ITER；非规格数 → 进 PRE_1 多花一拍：这一拍把按 4 的倍数
//          粗移后的尾数暂存在 rt_m1_q、细移量暂存在 iter_num_q[1:0]、指数奇偶暂存在 mask_q[0]。
//   PRE_1  用暂存值（细移 0..3 位）做迭代初始化。
//   ITER   每拍 child 算 2 个根位；iter_num_q 倒数到 0（f16 2 / f32 5 / f64 12，共 3 / 6 / 13 拍）。
//   POST_0 余数符号选根或根减一、按 rm 舍入、组装 IEEE 结果与 fflags；finish 握手后回 PRE_0。
//
// 迭代初始化（§2）：第一位根由 {指数奇偶, 尾数最高位} 决定——00 → 1（编码 "010"），01/10 → 1.5（"011"），
//   11 → 2（"100"）；余数 sum = 对齐后的被开方数，carry = -（第一位根）²；首拍 QDS 的余数片与比较常数
//   （r4_qds_cg）随之算出。
// 后处理（§5）：
//   - 余数符号与非零：把 64 位 carry-save 余数按 16 位一段并排相加（段间 1 位挡板：f16 时为 0 隔开，
//     否则为 1 放行进位），最高位即 lane0 的符号；非零判断用 (s^c)[i] != (s|c)[i-1]。
//   - 尾数全 0 的操作数（√(4^k) 或 √(2·4^k)）不迭代：结果尾数直接取 0 或 √2 的常数（golden 的 f32 / f16
//     常数里还拼进了 rt_q 的低 3 / 2 位——照抄）。
//   - 舍入：余数非负取根 rt，RNE/RMM 看舍入位、RUP 看 inexact；余数为负取根减一 rt_m1，
//     RUP 必进、RNE/RMM 看它自己的舍入位；rt_m1 的"加一"复用 rt 的加一结果（两者保护位相同时
//     rt_m1 + 1 == rt + 1，否则 == rt 截断，golden 的巧算）。
// 怪癖（照抄 golden）：
//   - 非规格数路径的 PRE_0 把 rt_q 改写成 {42'h0, rt_q[55:43], 1'b0}（旧值的高位搬下来），
//     PRE_1 再整个覆盖；mask_q / iter_num_q / rt_m1_q 也只改写其中一部分位。
//   - res_is_sqrt_2_q / res_is_sqrt_2_odd_q 看的是**原始**指数的最低位（不是规格化后的奇偶）。
//   - fp_aIsFpCanonicalNAN=1 时一律当 qNaN（且不算零 / Inf / sNaN）。
//   - rm 编码 0 RNE / 1 RTZ / 2 RDN / 3 RUP / 4 RMM；RTZ/RDN 与 5..7 都不进位。
// 子模块（实例名与 golden 一致）：lzc（u_lzc_0）、r4_qds_cg（u_r4_qds_cg_iter_init_0）、
//   fpsqrt_r16_block（u_fpsqrt_r16_block）——三者均为本仓重写件。
// golden 对照：G1-canonical/golden-rtl/fpsqrt_r16.sv
// =============================================================================
module xs_fpsqrt_r16_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        start_valid_i,
  output logic        start_ready_o,
  input  logic        flush_i,
  input  logic [1:0]  fp_format_i,
  input  logic [63:0] op_i,
  input  logic [2:0]  rm_i,
  input  logic        op_is_canonical_nan,   // 上游已判为规范 NaN（fp_aIsFpCanonicalNAN）
  output logic        finish_valid_o,
  input  logic        finish_ready_i,
  output logic [63:0] fpsqrt_res_o,
  output logic [4:0]  fflags_o
);
  // ---------------------------------------------------------------------------
  // §0 状态与寄存器声明（集合与位宽逐字对齐 golden）
  // ---------------------------------------------------------------------------
  localparam logic [3:0] FSM_PRE_0 = 4'b0001, FSM_PRE_1 = 4'b0010, FSM_ITER = 4'b0100, FSM_POST_0 = 4'b1000;
  localparam logic [2:0] RM_RNE = 3'd0, RM_RUP = 3'd3, RM_RMM = 3'd4;

  logic [3:0]  fsm_q;
  logic [3:0]  iter_num_q;
  logic [2:0]  fp_fmt_q;                 // {f64, f32, f16}
  logic [2:0]  rm_q;
  logic        out_sign_q;
  logic [10:0] out_exp_q;
  logic        res_is_nan_q, res_is_inf_q, res_is_exact_zero_q, op_invalid_q;
  logic        res_is_sqrt_2_q;          // 尾数全 0 且原始指数为偶：结果尾数为 √2 常数
  logic        res_is_sqrt_2_odd_q;      // 尾数全 0 且原始指数为奇：结果尾数为 0
  logic [55:0] rt_q;                     // 根
  logic [52:0] rt_m1_q;                  // 根减一（PRE_1 前暂存粗移后的尾数）
  logic [12:0] mask_q;                   // 迭代位置掩码（PRE_1 前 [0] 暂存指数奇偶）
  logic [63:0] f_r_s_q, f_r_c_q;         // 冗余余数 sum / carry
  logic [6:0]  nr_f_r_7b_q;              // 下一拍 s0 QDS 的余数片
  logic [8:0]  nr_f_r_9b_q;              // 下一拍 s1 QDS 的余数片
  logic [4:0]  m_neg_1_q;                // 下一拍 s0 QDS 的比较常数（r4_qds_cg 输出的截断）
  logic [3:0]  m_neg_0_q;
  logic [2:0]  m_pos_1_q;
  logic [3:0]  m_pos_2_q;

  logic fmt16_i, fmt32_i, fmt64_i;
  assign fmt16_i = (fp_format_i == 2'd0);
  assign fmt32_i = (fp_format_i == 2'd1);
  assign fmt64_i = (fp_format_i == 2'd2);
  logic fmt16_q, fmt32_q, fmt64_q;
  assign {fmt64_q, fmt32_q, fmt16_q} = fp_fmt_q;

  logic in_pre0, in_pre1, in_iter, in_post;
  assign {in_post, in_iter, in_pre1, in_pre0} = fsm_q;
  logic start_handshaked;
  assign start_ready_o    = in_pre0;
  assign start_handshaked = start_valid_i & in_pre0;
  assign finish_valid_o   = in_post;

  // ---------------------------------------------------------------------------
  // §1 操作数预解码（PRE_0 当拍，组合于 op_i / fp_format_i）
  // ---------------------------------------------------------------------------
  logic        op_sign;
  logic [10:0] op_exp;
  logic        exp_is_zero, exp_is_max;
  assign op_sign = (fmt64_i & op_i[63]) | (fmt32_i & op_i[31]) | (fmt16_i & op_i[15]);
  assign op_exp  = ({11{fmt16_i}} & {6'b0, op_i[14:10]}) | ({11{fmt32_i}} & {3'b0, op_i[30:23]})
                 | ({11{fmt64_i}} & op_i[62:52]);
  assign exp_is_zero = (op_exp == 11'h0);
  assign exp_is_max  = (op_exp == (fmt16_i ? 11'h1F : fmt32_i ? 11'hFF : 11'h7FF));

  // 尾数左对齐到 52 位（最高位补 0），数前导零：非规格数要左移规格化
  logic [52:0] frac_pre;
  logic [5:0]  lzc_cnt;
  logic        frac_is_zero;
  assign frac_pre = ({53{fmt16_i}} & {1'b0, op_i[9:0], 42'b0}) | ({53{fmt32_i}} & {1'b0, op_i[22:0], 29'b0})
                  | ({53{fmt64_i}} & {1'b0, op_i[51:0]});
  lzc u_lzc_0 (
    .in_i    (frac_pre),
    .cnt_o   (lzc_cnt),
    .empty_o (frac_is_zero)
  );
  logic [5:0] lsh;                       // 规格化左移量（规格数为 0）
  assign lsh = {6{exp_is_zero}} & lzc_cnt;

  // 分类
  logic frac_msb, op_is_zero, op_is_inf, op_is_qnan, op_is_snan, op_invalid_d, res_is_nan_d;
  assign frac_msb     = fmt16_i ? op_i[9] : fmt32_i ? op_i[22] : op_i[51];
  assign op_is_zero   = ~op_is_canonical_nan & exp_is_zero & frac_is_zero;
  assign op_is_inf    = ~op_is_canonical_nan & exp_is_max & frac_is_zero;
  assign op_is_qnan   = op_is_canonical_nan | (exp_is_max & frac_msb);
  assign op_is_snan   = ~op_is_canonical_nan & exp_is_max & ~frac_is_zero & ~frac_msb;
  assign op_invalid_d = (op_sign & ~op_is_zero & ~op_is_qnan) | op_is_snan;
  assign res_is_nan_d = op_is_qnan | op_is_snan | op_invalid_d;

  // 结果指数预算：(exp + 奇偶修正 - 左移量 + 偏置修正) / 2，低一位丢弃
  logic [11:0] out_exp_pre;
  assign out_exp_pre = 12'({1'b0, op_exp[10:1], op_exp[0] | exp_is_zero}
                         + {2'b0, ({6{fmt32_i}} & {5'h3, ~lsh[4]}) | ({6{fmt64_i}} & {4'hF, ~lsh[5:4]}), ~lsh[3:0]});

  // 规格化后指数是否为奇数（决定第一位根与余数对齐）
  logic exp_is_odd_pre;
  assign exp_is_odd_pre = exp_is_zero ? lsh[0] : ~op_exp[0];

  // 非规格数：PRE_0 先按 4 的倍数粗移（暂存进 rt_m1_q），PRE_1 再细移 0..3 位
  logic [51:0] frac_lsh_coarse;
  assign frac_lsh_coarse = 52'({63'b0, frac_pre[51:0]} << {lsh[5:2], 2'b0});

  // ---------------------------------------------------------------------------
  // §2 迭代初始化（PRE_0 直通规格数，或 PRE_1 用暂存值）
  // ---------------------------------------------------------------------------
  logic        cur_exp_odd;
  logic [51:0] cur_frac;
  assign cur_exp_odd = in_pre0 ? exp_is_odd_pre : mask_q[0];
  assign cur_frac    = in_pre0 ? frac_pre[51:0] : 52'({3'b0, rt_m1_q[51:0]} << iter_num_q[1:0]);

  // 第一位根：{指数奇偶, 尾数最高位} = 00 → 1，01/10 → 1.5，11 → 2
  logic sel_lo, sel_mid, sel_hi;
  assign sel_lo  = ~cur_exp_odd & ~cur_frac[51];
  assign sel_mid =  cur_exp_odd ^  cur_frac[51];
  assign sel_hi  =  cur_exp_odd &  cur_frac[51];

  logic [55:0] rt_init;
  logic [52:0] rt_m1_init;
  assign rt_init    = {sel_lo | sel_mid, sel_mid, 54'b0};
  assign rt_m1_init = {sel_lo | sel_hi, 52'b0};

  // 初始余数：sum = 对齐后的被开方数（"01.frac" 或 "1frac0"），carry = -（第一位根）²
  logic [53:0] s_init;
  logic [55:0] c_init;
  assign s_init = cur_exp_odd ? {1'b1, cur_frac, 1'b0} : {2'b01, cur_frac};
  assign c_init = ({56{sel_lo}} & 56'hC0_0000_0000_0000) | ({56{sel_mid}} & 56'h70_0000_0000_0000);

  // 打包进 64 位：lane0 在 f64 时占满 [63:8]；f32 时只有 [63:36] 有意义；f16 时 PRE_1 清掉 [47:32]
  logic f64_sel;
  assign f64_sel = (in_pre0 & fmt64_i) | (in_pre1 & fmt64_q);
  logic [63:0] f_r_s_init, f_r_c_init;
  assign f_r_s_init = {s_init[53:38],
                       (in_pre1 & fmt16_q) ? 16'h0 : s_init[37:22],
                       {16{f64_sel}} & s_init[21:6],
                       {16{f64_sel}} & {s_init[5:0], 10'b0}};
  assign f_r_c_init = {c_init[55:40],
                       (in_pre1 & fmt16_q) ? 16'h0 : c_init[39:24],
                       {16{f64_sel}} & c_init[23:8],
                       {16{f64_sel}} & {c_init[7:0], 8'b0}};

  // 首拍 QDS 的余数片（sum 高位 + carry 高位）与比较常数
  logic [6:0] nr7_init;
  logic [8:0] nr9_init;
  assign nr7_init = {4'(s_init[53:50] + c_init[55:52]), s_init[49:47]};
  assign nr9_init = {2'(s_init[51:50] + c_init[53:52]), s_init[49:43]};
  logic [6:0] m_neg_1_init, m_neg_0_init, m_pos_1_init, m_pos_2_init;
  r4_qds_cg u_r4_qds_cg_iter_init_0 (     // a0 = 根 2，a2 = 根 1.5，更低位恒 0
    .a0_i      (sel_hi),
    .a2_i      (sel_mid),
    .a3_i      (1'b0),
    .a4_i      (1'b0),
    .m_neg_1_o (m_neg_1_init),
    .m_neg_0_o (m_neg_0_init),
    .m_pos_1_o (m_pos_1_init),
    .m_pos_2_o (m_pos_2_init)
  );

  // ---------------------------------------------------------------------------
  // §3 迭代主体（child；只用 lane0）
  // ---------------------------------------------------------------------------
  logic [55:0] nxt_rt;
  logic [52:0] nxt_rt_m1;
  logic [63:0] nxt_f_r_s, nxt_f_r_c;
  logic [6:0]  nxt_nr7, nxt_m_neg_1, nxt_m_neg_0, nxt_m_pos_1, nxt_m_pos_2;
  logic [8:0]  nxt_nr9;
  fpsqrt_r16_block u_fpsqrt_r16_block (
    .fp_fmt_i                              (fp_fmt_q),
    .f_r_s_i                               (f_r_s_q),
    .f_r_c_i                               (f_r_c_q),
    .rt_i                                  (rt_q),
    .rt_m1_i                               (rt_m1_q),
    .mask_i                                (mask_q),
    .nr_f_r_7b_for_nxt_cycle_s0_qds_0_i    (nr_f_r_7b_q),
    .nr_f_r_7b_for_nxt_cycle_s0_qds_1_i    (7'h0),
    .nr_f_r_7b_for_nxt_cycle_s0_qds_2_i    (7'h0),
    .nr_f_r_7b_for_nxt_cycle_s0_qds_3_i    (7'h0),
    .nr_f_r_9b_for_nxt_cycle_s1_qds_0_i    (nr_f_r_9b_q),
    .nr_f_r_9b_for_nxt_cycle_s1_qds_1_i    (9'h0),
    .nr_f_r_9b_for_nxt_cycle_s1_qds_2_i    (9'h0),
    .nr_f_r_9b_for_nxt_cycle_s1_qds_3_i    (9'h0),
    .m_neg_1_for_nxt_cycle_s0_qds_0_i      (m_neg_1_q),
    .m_neg_1_for_nxt_cycle_s0_qds_1_i      (5'h0),
    .m_neg_1_for_nxt_cycle_s0_qds_2_i      (5'h0),
    .m_neg_1_for_nxt_cycle_s0_qds_3_i      (5'h0),
    .m_neg_0_for_nxt_cycle_s0_qds_0_i      (m_neg_0_q),
    .m_neg_0_for_nxt_cycle_s0_qds_1_i      (4'h0),
    .m_neg_0_for_nxt_cycle_s0_qds_2_i      (4'h0),
    .m_neg_0_for_nxt_cycle_s0_qds_3_i      (4'h0),
    .m_pos_1_for_nxt_cycle_s0_qds_0_i      (m_pos_1_q),
    .m_pos_1_for_nxt_cycle_s0_qds_1_i      (3'h0),
    .m_pos_1_for_nxt_cycle_s0_qds_2_i      (3'h0),
    .m_pos_1_for_nxt_cycle_s0_qds_3_i      (3'h0),
    .m_pos_2_for_nxt_cycle_s0_qds_0_i      (m_pos_2_q),
    .m_pos_2_for_nxt_cycle_s0_qds_1_i      (4'h0),
    .m_pos_2_for_nxt_cycle_s0_qds_2_i      (4'h0),
    .m_pos_2_for_nxt_cycle_s0_qds_3_i      (4'h0),
    .nxt_rt_o                              (nxt_rt),
    .nxt_rt_m1_o                           (nxt_rt_m1),
    .nxt_f_r_s_o                           (nxt_f_r_s),
    .nxt_f_r_c_o                           (nxt_f_r_c),
    .adder_7b_res_for_nxt_cycle_s0_qds_0_o (nxt_nr7),
    .adder_7b_res_for_nxt_cycle_s0_qds_1_o (),
    .adder_7b_res_for_nxt_cycle_s0_qds_2_o (),
    .adder_7b_res_for_nxt_cycle_s0_qds_3_o (),
    .adder_9b_res_for_nxt_cycle_s1_qds_0_o (nxt_nr9),
    .adder_9b_res_for_nxt_cycle_s1_qds_1_o (),
    .adder_9b_res_for_nxt_cycle_s1_qds_2_o (),
    .adder_9b_res_for_nxt_cycle_s1_qds_3_o (),
    .m_neg_1_to_nxt_cycle_0_o              (nxt_m_neg_1),
    .m_neg_1_to_nxt_cycle_1_o              (),
    .m_neg_1_to_nxt_cycle_2_o              (),
    .m_neg_1_to_nxt_cycle_3_o              (),
    .m_neg_0_to_nxt_cycle_0_o              (nxt_m_neg_0),
    .m_neg_0_to_nxt_cycle_1_o              (),
    .m_neg_0_to_nxt_cycle_2_o              (),
    .m_neg_0_to_nxt_cycle_3_o              (),
    .m_pos_1_to_nxt_cycle_0_o              (nxt_m_pos_1),
    .m_pos_1_to_nxt_cycle_1_o              (),
    .m_pos_1_to_nxt_cycle_2_o              (),
    .m_pos_1_to_nxt_cycle_3_o              (),
    .m_pos_2_to_nxt_cycle_0_o              (nxt_m_pos_2),
    .m_pos_2_to_nxt_cycle_1_o              (),
    .m_pos_2_to_nxt_cycle_2_o              (),
    .m_pos_2_to_nxt_cycle_3_o              ()
  );

  // ---------------------------------------------------------------------------
  // §4 状态机与寄存器更新
  // ---------------------------------------------------------------------------
  logic early_finish;                    // 不用迭代的操作数
  assign early_finish = res_is_nan_d | op_is_inf | op_is_zero | frac_is_zero;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)                       fsm_q <= FSM_PRE_0;
    else if (flush_i)                fsm_q <= FSM_PRE_0;
    else if (fsm_q == FSM_PRE_0)     fsm_q <= start_valid_i ? (early_finish ? FSM_POST_0 : exp_is_zero ? FSM_PRE_1 : FSM_ITER)
                                                            : FSM_PRE_0;
    else if (fsm_q == FSM_PRE_1)     fsm_q <= FSM_ITER;
    else if (fsm_q == FSM_ITER)      fsm_q <= (|iter_num_q) ? FSM_ITER : FSM_POST_0;
    else if (fsm_q != FSM_POST_0 | finish_ready_i) fsm_q <= FSM_PRE_0;
    else                             fsm_q <= FSM_POST_0;
  end

  logic data_en, init_phase;
  assign data_en    = start_handshaked | in_pre1 | in_iter;   // 迭代数据寄存器的使能
  assign init_phase = in_pre0 | in_pre1;                       // 取初值而不是 child 的下一拍值
  logic [3:0] iter_num_fmt_i, iter_num_fmt_q;                 // 迭代拍数：f16 2 / f32 5 / f64 12
  assign iter_num_fmt_i = ({4{fmt16_i}} & 4'd2) | ({4{fmt32_i}} & 4'd5) | ({4{fmt64_i}} & 4'd12);
  assign iter_num_fmt_q = ({4{fmt16_q}} & 4'd2) | ({4{fmt32_q}} & 4'd5) | ({4{fmt64_q}} & 4'd12);

  always_ff @(posedge clock) begin
    if (start_handshaked | in_pre1 | (in_iter & (|iter_num_q))) begin
      if (in_pre0)      iter_num_q <= exp_is_zero ? {iter_num_q[3:2], lsh[1:0]} : iter_num_fmt_i;
      else if (in_pre1) iter_num_q <= iter_num_fmt_q;
      else              iter_num_q <= iter_num_q - 4'd1;
    end
    if (start_handshaked) begin
      fp_fmt_q            <= {fmt64_i, fmt32_i, fmt16_i};
      rm_q                <= rm_i;
      out_sign_q          <= ~res_is_nan_d & op_sign;
      out_exp_q           <= out_exp_pre[11:1];
      res_is_nan_q        <= res_is_nan_d;
      res_is_inf_q        <= op_is_inf;
      res_is_exact_zero_q <= op_is_zero;
      op_invalid_q        <= op_invalid_d;
      res_is_sqrt_2_q     <= frac_is_zero & ~op_exp[0];
      res_is_sqrt_2_odd_q <= frac_is_zero & op_exp[0];
    end
    if (data_en) begin
      if (in_pre0)      rt_q <= exp_is_zero ? {42'b0, rt_q[55:43], 1'b0} : rt_init;
      else if (in_pre1) rt_q <= rt_init;
      else              rt_q <= nxt_rt;
      if (in_pre0)      rt_m1_q <= exp_is_zero ? {rt_m1_q[52], frac_lsh_coarse} : rt_m1_init;
      else if (in_pre1) rt_m1_q <= rt_m1_init;
      else              rt_m1_q <= nxt_rt_m1;
      if (in_pre0)      mask_q <= exp_is_zero ? {mask_q[12:4], 3'b0, exp_is_odd_pre} : 13'h1000;
      else if (in_pre1) mask_q <= 13'h1000;
      else              mask_q <= {1'b0, mask_q[12:1]};
      f_r_s_q     <= init_phase ? f_r_s_init : nxt_f_r_s;
      f_r_c_q     <= init_phase ? f_r_c_init : nxt_f_r_c;
      nr_f_r_7b_q <= init_phase ? nr7_init : nxt_nr7;
      nr_f_r_9b_q <= init_phase ? nr9_init : nxt_nr9;
      m_neg_1_q   <= init_phase ? m_neg_1_init[4:0] : nxt_m_neg_1[4:0];
      m_neg_0_q   <= init_phase ? m_neg_0_init[3:0] : nxt_m_neg_0[3:0];
      m_pos_1_q   <= init_phase ? m_pos_1_init[2:0] : nxt_m_pos_1[2:0];
      m_pos_2_q   <= init_phase ? m_pos_2_init[4:1] : nxt_m_pos_2[4:1];
    end
  end

  // ---------------------------------------------------------------------------
  // §5 后处理：余数符号 / 非零、舍入、结果组装
  // ---------------------------------------------------------------------------
  // 余数 s+c 按 16 位一段并排相加，段间 1 位挡板（f16 时 0 隔开，否则 1 放行；中间那道只有 f64 放行）
  logic [66:0] nr_f_r;
  assign nr_f_r = 67'({f_r_s_q[63:48], ~fmt16_q, f_r_s_q[47:32], fmt64_q, f_r_s_q[31:16], ~fmt16_q, f_r_s_q[15:0]}
                    + {f_r_c_q[63:48], 1'b0,     f_r_c_q[47:32], 1'b0,    f_r_c_q[31:16], 1'b0,     f_r_c_q[15:0]});
  logic rem_neg, select_rt_m1;
  assign rem_neg      = nr_f_r[66];                 // lane0 余数为负 → 真根是 rt - 1
  assign select_rt_m1 = rem_neg & ~res_is_sqrt_2_q;

  // 余数非零：s+c != 0 当且仅当某位 (s^c)[i] != (s|c)[i-1]（只看本格式有效的段）
  logic [53:0] f_r_xor, f_r_or;
  assign f_r_xor = f_r_s_q[62:9] ^ f_r_c_q[62:9];
  assign f_r_or  = f_r_s_q[61:8] | f_r_c_q[61:8];
  logic rem_nonzero;
  assign rem_nonzero = (f_r_xor[53:40] != f_r_or[53:40])
                     | (~fmt16_q & (f_r_xor[39:28] != f_r_or[39:28]))
                     | (fmt64_q & (f_r_xor[27:0] != f_r_or[27:0]));

  // 参与舍入的根：尾数全 0 的偶指数操作数直接用 √2 的常数（f32/f16 常数里拼进 rt_q 的低位，golden 原样）
  logic [52:0] rt_for_inc;
  assign rt_for_inc = res_is_sqrt_2_q
                    ? ({1'b0, {52{fmt64_q}} & 52'hD_413C_CCFE_7799}
                       | ({53{fmt32_q}} & {24'h6A_09E6, rt_q[2:0], 26'h0})
                       | ({53{fmt16_q}} & {11'h350, rt_q[1:0], 40'h0}))
                    : rt_q[54:2];

  // 去掉保护位后的根尾数（按格式把 f16/f32 的段边界位清零），以及"加一个 ulp"
  logic [52:0] rt_truncated, rt_incremented;
  assign rt_truncated   = {1'b0, rt_for_inc[52:40], ~fmt16_q & rt_for_inc[39], rt_for_inc[38:26],
                           ~(fmt16_q | fmt32_q) & rt_for_inc[25], rt_for_inc[24:12],
                           ~fmt16_q & rt_for_inc[11], rt_for_inc[10:1]};
  assign rt_incremented = 53'(rt_truncated + {1'b0, ({52{fmt16_q}} & 52'h4_0010_0040_01)
                                                  | ({52{fmt32_q}} & 52'h2000_0002) | {51'b0, fmt64_q}});

  // 舍入位 / 保护位（根与根减一各一套，位置随格式）
  logic round_rt, guard_rt, round_m1, guard_m1;
  assign round_rt = (fmt16_q & rt_for_inc[42]) | (fmt32_q & rt_for_inc[29]) | (fmt64_q & rt_for_inc[0]);
  assign guard_rt = (fmt16_q & rt_q[45]) | (fmt32_q & rt_q[32]) | (fmt64_q & rt_q[3]);
  assign round_m1 = (fmt16_q & rt_m1_q[42]) | (fmt32_q & rt_m1_q[29]) | (fmt64_q & rt_m1_q[0]);
  assign guard_m1 = (fmt16_q & rt_m1_q[43]) | (fmt32_q & rt_m1_q[30]) | (fmt64_q & rt_m1_q[1]);

  logic rm_rne, rm_rup, rm_rmm, inexact_rt, rt_rup, m1_rup;
  assign rm_rne     = (rm_q == RM_RNE);
  assign rm_rup     = (rm_q == RM_RUP);
  assign rm_rmm     = (rm_q == RM_RMM);
  assign inexact_rt = round_rt | rem_neg | rem_nonzero | res_is_sqrt_2_q;
  assign rt_rup     = (rm_rne & round_rt) | (rm_rup & inexact_rt) | (rm_rmm & round_rt);
  assign m1_rup     = rm_rup | ((rm_rne | rm_rmm) & round_m1);

  logic [52:0] frac_rounded;             // [52] = 舍入进位溢出到指数
  assign frac_rounded = select_rt_m1
                      ? (m1_rup ? ((guard_rt == guard_m1) ? rt_incremented : rt_truncated) : {1'b0, rt_m1_q[52:1]})
                      : (rt_rup ? rt_incremented : rt_truncated);
  logic [10:0] exp_rounded;
  assign exp_rounded = frac_rounded[52] ? 11'(out_exp_q + 11'd1) : out_exp_q;

  // 特殊值优先：NaN/Inf → 全 1 指数（NaN 尾数置最高位），零 → 全 0；尾数全 0 的奇指数操作数尾数为 0
  logic exp_all_ones, frac_forced_zero;
  assign exp_all_ones     = res_is_nan_q | res_is_inf_q;
  assign frac_forced_zero = res_is_inf_q | res_is_exact_zero_q | res_is_sqrt_2_odd_q;
  logic [15:0] f16_res;
  logic [31:0] f32_res;
  logic [63:0] f64_res;
  assign f16_res = {out_sign_q, exp_all_ones ? 5'h1F : res_is_exact_zero_q ? 5'h0 : exp_rounded[4:0],
                    res_is_nan_q ? 10'h200 : frac_forced_zero ? 10'h0 : frac_rounded[51:42]};
  assign f32_res = {out_sign_q, exp_all_ones ? 8'hFF : res_is_exact_zero_q ? 8'h0 : exp_rounded[7:0],
                    res_is_nan_q ? 23'h40_0000 : frac_forced_zero ? 23'h0 : frac_rounded[51:29]};
  assign f64_res = {out_sign_q, exp_all_ones ? 11'h7FF : res_is_exact_zero_q ? 11'h0 : exp_rounded,
                    res_is_nan_q ? 52'h8_0000_0000_0000 : frac_forced_zero ? 52'h0 : frac_rounded[51:0]};
  assign fpsqrt_res_o = ({64{fmt16_q}} & {48'b0, f16_res})
                      | ({64{fmt32_q}} & {32'b0, f32_res})
                      | ({64{fmt64_q}} & f64_res);

  // fflags = {NV, DZ, OF, UF, NX}：只有 NV 与 NX 可能置位
  assign fflags_o = {op_invalid_q, 3'b000, (inexact_rt | select_rt_m1) & ~res_is_nan_q & ~res_is_exact_zero_q};
endmodule

module fpsqrt_r16 (
  input  logic        clock,
  input  logic        reset,
  input  logic        start_valid_i,
  output logic        start_ready_o,
  input  logic        flush_i,
  input  logic [1:0]  fp_format_i,
  input  logic [63:0] op_i,
  input  logic [2:0]  rm_i,
  output logic        finish_valid_o,
  input  logic        finish_ready_i,
  output logic [63:0] fpsqrt_res_o,
  output logic [4:0]  fflags_o,
  input  logic        fp_aIsFpCanonicalNAN
);
  xs_fpsqrt_r16_core u_core (
    .clock               (clock),
    .reset               (reset),
    .start_valid_i       (start_valid_i),
    .start_ready_o       (start_ready_o),
    .flush_i             (flush_i),
    .fp_format_i         (fp_format_i),
    .op_i                (op_i),
    .rm_i                (rm_i),
    .op_is_canonical_nan (fp_aIsFpCanonicalNAN),
    .finish_valid_o      (finish_valid_o),
    .finish_ready_i      (finish_ready_i),
    .fpsqrt_res_o        (fpsqrt_res_o),
    .fflags_o            (fflags_o)
  );
endmodule
