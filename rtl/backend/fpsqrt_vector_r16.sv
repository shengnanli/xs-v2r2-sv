// =============================================================================
// fpsqrt_vector_r16.sv —— 向量浮点开方器顶层（基 16 = 每拍 2 个基 4 根位，f16×4 / f32×2 / f64×1）
//
// 在哪一层：yunsuan VectorFloatDivider 里与除法器并列的开方通路；本件是开方器的控制 + 前后处理，
//   每拍的 SRT 迭代由 child fpsqrt_r16_block（本仓重写件，fpaddpath-sqrtblock lane 签核）完成。
// 设计源：yunsuan/vector/vfsqrt/fpsqrt_vector_r16.scala。golden 里 vector_mode_i 已折成常量 1、
//   fp_aIsFpCanonicalNAN 折成常量 0，于是 res_is_sqrt_2 / early_finish / 标量结果通路全部消失，
//   端口表只剩本文件 wrapper 列出的 12 个。
//
// 四条通道（沿用 golden 的编号，不按位置排）：
//   通道  op_i 里的位置            用于格式         exp 宽  frac 宽  说明
//   0     [63:48]（f64 时 [63:0]）  f64 / f32 高 / f16   11      52      唯一的 f64 通道
//   1     [31:0]（f16 时 [31:16]）  f32 低 / f16         8       23
//   2     [47:32]                   f16                  5       10
//   3     [15:0]                    f16                  5       10
//   fp_format_i：0=f16 1=f32 2=f64（3 非法：三个格式位全 0）；fp_fmt_q = {f64, f32, f16} one-hot 打拍。
//
// 状态机（fsm_q one-hot，异步复位到 PRE_0；其余寄存器都不复位）：
//   PRE_0  空闲/接收：start_valid 握手当拍预解码操作数（分类、指数、前导零），
//          f64 规格数直接做迭代初始化进 ITER；其它（非 f64 或非规格数）进 PRE_1 多花一拍：
//          这一拍把左移后的尾数暂存在 rt_q / rt_m1_q、指数奇偶暂存在 mask_q[3:0]（寄存器复用）。
//   PRE_1  用暂存的尾数做迭代初始化：第一位根（由"指数奇偶 + 尾数最高位"二选一决定 1/2/3 种）、
//          初始冗余余数（sum/carry）、给 child 的首拍商位选择常数（r4_qds_cg）。
//   ITER   每拍 child 算 2 个根位；iter_num_q 倒数到 0（f16 2 / f32 5 / f64 12 拍）。
//   POST_0 结果：余数符号选根或根减一、按 rm 舍入、组装 IEEE 结果与 fflags，finish 握手后回 PRE_0。
// 怪癖（照抄 golden）：
//   - 非 f64 格式 need_2_cycles_init 恒真（vector_mode 常量 1 的后果）。
//   - PRE_0 的 need_2 路径只改写 rt_q[42:0] / rt_m1_q[51:0] / mask_q[3:0] / iter_num_q[1:0]，其余位保留旧值。
//   - 余数非零判断把四条通道并排加（nr_f_r 67 位，通道之间插 1 位"进位挡板"：f16 时为 0 挡住，否则为 1 放行）。
//   - rm 编码 0 RNE / 1 RTZ / 2 RDN / 3 RUP / 4 RMM；RTZ/RDN 与 5..7 都不进位。
// 子模块：lzc / lzc_3 / lzc_4、r4_qds_cg ×4、fpsqrt_r16_block（均为本仓已签核重写件）。
// golden 对照：G1-canonical/golden-rtl/fpsqrt_vector_r16.sv
// =============================================================================
module xs_fpsqrt_vector_r16_core (
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
  output logic [19:0] fflags_o
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
  logic [3:0]  out_sign_q;               // 位 k = 通道 k
  logic [10:0] out_exp_0_q;
  logic [7:0]  out_exp_1_q;
  logic [4:0]  out_exp_2_q, out_exp_3_q;
  logic [3:0]  res_is_nan_q, res_is_inf_q, res_is_exact_zero_q, op_invalid_q;
  logic [55:0] rt_q;                     // 根（4 通道并排；PRE_1 前暂存左移尾数）
  logic [52:0] rt_m1_q;                  // 根减一（PRE_1 前暂存 f64 尾数的粗移位结果）
  logic [12:0] mask_q;                   // 迭代位置掩码（PRE_1 前 [3:0] 暂存各通道指数奇偶）
  logic [63:0] f_r_s_q, f_r_c_q;         // 冗余余数 sum / carry
  logic [3:0][6:0] nr_f_r_7b_q;          // 下一拍 s0 商位选择的余数片
  logic [3:0][8:0] nr_f_r_9b_q;          // 下一拍 s1 商位选择的余数片
  logic [3:0][4:0] m_neg_1_q;            // 下一拍 s0 商位选择常数（r4_qds_cg 输出的截断）
  logic [3:0][3:0] m_neg_0_q;
  logic [3:0][2:0] m_pos_1_q;
  logic [3:0][3:0] m_pos_2_q;

  logic fmt16_i, fmt32_i, fmt64_i;       // 本拍输入格式
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
  logic [10:0] op_exp_0;  logic [7:0] op_exp_1;  logic [4:0] op_exp_2, op_exp_3;
  assign op_exp_0 = ({11{fmt16_i}} & {6'b0, op_i[62:58]}) | ({11{fmt32_i}} & {3'b0, op_i[62:55]}) | ({11{fmt64_i}} & op_i[62:52]);
  assign op_exp_1 = ({8{fmt16_i}} & {3'b0, op_i[30:26]}) | ({8{fmt32_i}} & op_i[30:23]);
  assign op_exp_2 = op_i[46:42];
  assign op_exp_3 = op_i[14:10];
  logic [3:0] op_sign, exp_is_zero, exp_is_max;
  assign op_sign     = {op_i[15], op_i[47], op_i[31], op_i[63]};
  assign exp_is_zero = {op_exp_3 == '0, op_exp_2 == '0, op_exp_1 == '0, op_exp_0 == '0};
  assign exp_is_max  = {&op_exp_3, &op_exp_2,
                        op_exp_1 == (fmt16_i ? 8'h1F : 8'hFF),
                        op_exp_0 == (fmt16_i ? 11'h1F : fmt32_i ? 11'hFF : 11'h7FF)};
  logic need_2_cycles_init;
  assign need_2_cycles_init = ~fmt64_i | exp_is_zero[0];

  // 尾数左对齐到各通道的最大宽度，再数前导零（非规格数要左移规格化）
  logic [52:0] frac_pre_0;  logic [23:0] frac_pre_1;
  assign frac_pre_0 = ({53{fmt16_i}} & {1'b0, op_i[57:48], 42'b0}) | ({53{fmt32_i}} & {1'b0, op_i[54:32], 29'b0})
                    | ({53{fmt64_i}} & {1'b0, op_i[51:0]});
  assign frac_pre_1 = ({24{fmt16_i}} & {1'b0, op_i[25:16], 13'b0}) | ({24{fmt32_i}} & {1'b0, op_i[22:0]});
  logic [5:0] lzc_cnt_0;  logic [4:0] lzc_cnt_1;  logic [3:0] lzc_cnt_2, lzc_cnt_3;
  logic [3:0] frac_is_zero;
  lzc   u_lzc_0 (.in_i(frac_pre_0),          .cnt_o(lzc_cnt_0), .empty_o(frac_is_zero[0]));
  lzc_3 u_lzc_1 (.in_i(frac_pre_1),          .cnt_o(lzc_cnt_1), .empty_o(frac_is_zero[1]));
  lzc_4 u_lzc_2 (.in_i({1'b0, op_i[41:32]}), .cnt_o(lzc_cnt_2), .empty_o(frac_is_zero[2]));
  lzc_4 u_lzc_3 (.in_i({1'b0, op_i[9:0]}),   .cnt_o(lzc_cnt_3), .empty_o(frac_is_zero[3]));
  logic [5:0] lsh_0;  logic [4:0] lsh_1;  logic [3:0] lsh_2, lsh_3;   // 规格化左移量（规格数为 0）
  assign lsh_0 = {6{exp_is_zero[0]}} & lzc_cnt_0;
  assign lsh_1 = {5{exp_is_zero[1]}} & lzc_cnt_1;
  assign lsh_2 = {4{exp_is_zero[2]}} & lzc_cnt_2;
  assign lsh_3 = {4{exp_is_zero[3]}} & lzc_cnt_3;

  // 分类：零 / qNaN / sNaN / 负数无效
  logic [3:0] op_is_zero, op_is_qnan, op_is_snan, op_invalid_d, res_is_nan_d, res_is_inf_d;
  logic [3:0] frac_msb;   // 尾数最高位（qNaN 判定位）
  assign frac_msb = {op_i[9], op_i[41], fmt16_i ? op_i[25] : op_i[22], fmt16_i ? op_i[57] : fmt32_i ? op_i[54] : op_i[51]};
  assign op_is_zero   = exp_is_zero & frac_is_zero;
  assign op_is_qnan   = exp_is_max & frac_msb;
  assign op_is_snan   = exp_is_max & ~frac_is_zero & ~frac_msb;
  assign op_invalid_d = (op_sign & ~op_is_zero & ~op_is_qnan) | op_is_snan;
  assign res_is_nan_d = op_is_qnan | op_is_snan | op_invalid_d;
  assign res_is_inf_d = exp_is_max & frac_is_zero;

  // 结果指数预算：(exp + 奇偶修正 - 左移量) / 2 的高位；低一位丢弃。各格式偏置修正不同。
  logic [11:0] out_exp_pre_0;  logic [8:0] out_exp_pre_1;  logic [5:0] out_exp_pre_2, out_exp_pre_3;
  assign out_exp_pre_0 = 12'({1'b0, op_exp_0[10:1], op_exp_0[0] | exp_is_zero[0]}
                           + {2'b0, ({6{fmt32_i}} & {5'h3, ~lsh_0[4]}) | ({6{fmt64_i}} & {4'hF, ~lsh_0[5:4]}), ~lsh_0[3:0]});
  assign out_exp_pre_1 = 9'({1'b0, op_exp_1[7:1], op_exp_1[0] | exp_is_zero[1]}
                          + {2'b0, {3{fmt32_i}} & {2'b11, ~lsh_1[4]}, ~lsh_1[3:0]});
  assign out_exp_pre_2 = 6'({1'b0, op_exp_2[4:1], op_exp_2[0] | exp_is_zero[2]} + {2'b0, ~lsh_2});
  assign out_exp_pre_3 = 6'({1'b0, op_exp_3[4:1], op_exp_3[0] | exp_is_zero[3]} + {2'b0, ~lsh_3});

  // 规格化后指数是否为奇数（决定第一位根与余数对齐）
  logic [3:0] exp_is_odd_pre;
  assign exp_is_odd_pre = {exp_is_zero[3] ? lsh_3[0] : ~op_exp_3[0], exp_is_zero[2] ? lsh_2[0] : ~op_exp_2[0],
                           exp_is_zero[1] ? lsh_1[0] : ~op_exp_1[0], exp_is_zero[0] ? lsh_0[0] : ~op_exp_0[0]};

  // 非规格数的尾数左移（PRE_0 need_2 路径暂存进 rt_q / rt_m1_q）：通道 0 先按 4 的倍数粗移，细移留到 PRE_1
  logic [51:0] frac_lsh_coarse_0;  logic [22:0] frac_lsh_1;  logic [9:0] frac_lsh_2, frac_lsh_3;
  assign frac_lsh_coarse_0 = 52'(frac_pre_0[51:0] << {lsh_0[5:2], 2'b0});
  assign frac_lsh_1 = 23'(frac_pre_1[22:0] << lsh_1);
  assign frac_lsh_2 = 10'(op_i[41:32] << lsh_2);
  assign frac_lsh_3 = 10'(op_i[9:0] << lsh_3);

  // ---------------------------------------------------------------------------
  // §2 迭代初始化（PRE_0 直通 f64 规格数，或 PRE_1 用暂存值）
  // ---------------------------------------------------------------------------
  logic [3:0]  cur_exp_odd;
  logic [51:0] cur_frac_0;  logic [22:0] cur_frac_1;  logic [9:0] cur_frac_2, cur_frac_3;
  assign cur_exp_odd = in_pre0 ? exp_is_odd_pre : mask_q[3:0];
  assign cur_frac_0  = in_pre0 ? frac_pre_0[51:0] : 52'({3'b0, rt_m1_q[51:0]} << iter_num_q[1:0]);   // 细移 0..3
  assign cur_frac_1  = in_pre0 ? frac_pre_1[22:0] : rt_q[22:0];
  assign cur_frac_2  = in_pre0 ? op_i[41:32]      : rt_q[32:23];
  assign cur_frac_3  = in_pre0 ? op_i[9:0]        : rt_q[42:33];

  // 第一位根：按 {指数奇偶, 尾数最高位} —— 00 → 根 1（编码 "010"），01/10 → 根 1.5（"011"），11 → 根 2（"100"）
  logic [3:0] sel_lo, sel_mid, sel_hi;   // 每通道三选一
  logic [3:0] cur_frac_msb;
  assign cur_frac_msb = {cur_frac_3[9], cur_frac_2[9], cur_frac_1[22], cur_frac_0[51]};
  assign sel_lo  = ~cur_exp_odd & ~cur_frac_msb;
  assign sel_mid =  cur_exp_odd ^  cur_frac_msb;
  assign sel_hi  =  cur_exp_odd &  cur_frac_msb;

  // 通道有效：PRE_0 看本拍格式，PRE_1 看打拍格式
  logic lane1_on, lane23_on, lane0_f64, lane0_not_f64;
  assign lane1_on      = in_pre0 ? (fmt16_i | fmt32_i) : (fmt16_q | fmt32_q);
  assign lane23_on     = in_pre0 ? fmt16_i : fmt16_q;
  assign lane0_f64     = (in_pre0 & fmt64_i) | (in_pre1 & fmt64_q);
  assign lane0_not_f64 = (in_pre0 & ~fmt64_i) | (in_pre1 & ~fmt64_q);
  logic f16_sel, f32_sel;
  assign f16_sel = (in_pre0 & fmt16_i) | (in_pre1 & fmt16_q);
  assign f32_sel = (in_pre0 & fmt32_i) | (in_pre1 & fmt32_q);

  // 根 / 根减一 的初值：各通道只有最高 2/1 位非零，按通道位置打包
  logic [55:0] rt_init;
  logic [52:0] rt_m1_init;
  assign rt_init = {sel_lo[0] | sel_mid[0], sel_mid[0], 12'b0,
                    {2{lane23_on}} & {sel_lo[2] | sel_mid[2], sel_mid[2]}, 12'b0,
                    {2{lane1_on}}  & {sel_lo[1] | sel_mid[1], sel_mid[1]}, 12'b0,
                    {2{lane23_on}} & {sel_lo[3] | sel_mid[3], sel_mid[3]}, 12'b0};
  assign rt_m1_init = {sel_lo[0] | sel_hi[0], 12'b0,
                       lane23_on & (sel_lo[2] | sel_hi[2]), 12'b0,
                       lane1_on  & (sel_lo[1] | sel_hi[1]), 12'b0,
                       lane23_on & (sel_lo[3] | sel_hi[3]), 13'b0};

  // 初始余数：sum = 按指数奇偶对齐的尾数（"1.frac" 或 "1frac0"），carry = 减去第一位根平方的常数
  logic [53:0] s_init_0;  logic [25:0] s_init_1;  logic [13:0] s_init_2, s_init_3;
  assign s_init_0 = cur_exp_odd[0] ? {1'b1, cur_frac_0, 1'b0} : {2'b01, cur_frac_0};
  assign s_init_1 = cur_exp_odd[1] ? {1'b1, cur_frac_1, 2'b0} : {2'b01, cur_frac_1, 1'b0};
  assign s_init_2 = cur_exp_odd[2] ? {1'b1, cur_frac_2, 3'b0} : {2'b01, cur_frac_2, 2'b0};
  assign s_init_3 = cur_exp_odd[3] ? {1'b1, cur_frac_3, 3'b0} : {2'b01, cur_frac_3, 2'b0};
  logic [55:0] c_init_0;  logic [27:0] c_init_1;  logic [15:0] c_init_2, c_init_3;
  assign c_init_0 = ({56{sel_lo[0]}} & 56'hC0000000000000) | ({56{sel_mid[0]}} & 56'h70000000000000);
  assign c_init_1 = ({28{sel_lo[1]}} & 28'hC000000)        | ({28{sel_mid[1]}} & 28'h7000000);
  assign c_init_2 = ({16{sel_lo[2]}} & 16'hC000)           | ({16{sel_mid[2]}} & 16'h7000);
  assign c_init_3 = ({16{sel_lo[3]}} & 16'hC000)           | ({16{sel_mid[3]}} & 16'h7000);

  // 按格式把各通道初始余数打包进 64 位向量（通道 0 的 56 位余数在 f64 下占满 [63:8]）
  logic [63:0] f_r_s_init, f_r_c_init;
  assign f_r_s_init = {s_init_0[53:38],
                       (in_pre1 & fmt16_q) ? {s_init_2, 2'b0} : s_init_0[37:22],
                       ({16{lane0_f64}} & s_init_0[21:6]) | ({16{lane0_not_f64}} & s_init_1[25:10]),
                       ({16{f16_sel}} & {s_init_3, 2'b0}) | ({16{f32_sel}} & {s_init_1[9:0], 6'b0}) | ({16{lane0_f64}} & {s_init_0[5:0], 10'b0})};
  assign f_r_c_init = {c_init_0[55:40],
                       (in_pre1 & fmt16_q) ? c_init_2 : c_init_0[39:24],
                       ({16{lane0_f64}} & c_init_0[23:8]) | ({16{lane0_not_f64}} & c_init_1[27:12]),
                       ({16{f16_sel}} & c_init_3) | ({16{f32_sel}} & {c_init_1[11:0], 4'b0}) | ({16{lane0_f64}} & {c_init_0[7:0], 8'b0})};

  // 首拍商位选择用的余数片（sum 高位加 carry 高位）
  logic [3:0][6:0] nr7_init;
  logic [3:0][8:0] nr9_init;
  assign nr7_init[0] = {4'(s_init_0[53:50] + c_init_0[55:52]), s_init_0[49:47]};
  assign nr7_init[1] = {4'(s_init_1[25:22] + c_init_1[27:24]), s_init_1[21:19]};
  assign nr7_init[2] = {4'(s_init_2[13:10] + c_init_2[15:12]), s_init_2[9:7]};
  assign nr7_init[3] = {4'(s_init_3[13:10] + c_init_3[15:12]), s_init_3[9:7]};
  assign nr9_init[0] = {2'(s_init_0[51:50] + c_init_0[53:52]), s_init_0[49:43]};
  assign nr9_init[1] = {2'(s_init_1[23:22] + c_init_1[25:24]), s_init_1[21:15]};
  assign nr9_init[2] = {2'(s_init_2[11:10] + c_init_2[13:12]), s_init_2[9:3]};
  assign nr9_init[3] = {2'(s_init_3[11:10] + c_init_3[13:12]), s_init_3[9:3]};

  // 首拍商位选择常数：由第一位根的位型算出（a0 = 根 2，a2 = 根 1.5，更低位恒 0）
  logic [3:0][6:0] m_neg_1_init, m_neg_0_init, m_pos_1_init, m_pos_2_init;
  for (genvar k = 0; k < 4; k++) begin : g_qds_cg_init
    r4_qds_cg u_r4_qds_cg_iter_init (
      .a0_i(sel_hi[k]), .a2_i(sel_mid[k]), .a3_i(1'b0), .a4_i(1'b0),
      .m_neg_1_o(m_neg_1_init[k]), .m_neg_0_o(m_neg_0_init[k]),
      .m_pos_1_o(m_pos_1_init[k]), .m_pos_2_o(m_pos_2_init[k]));
  end

  // ---------------------------------------------------------------------------
  // §3 迭代主体（child fpsqrt_r16_block）
  // ---------------------------------------------------------------------------
  logic [55:0] nxt_rt;  logic [52:0] nxt_rt_m1;  logic [63:0] nxt_f_r_s, nxt_f_r_c;
  logic [3:0][6:0] nxt_nr7, nxt_m_neg_1, nxt_m_neg_0, nxt_m_pos_1, nxt_m_pos_2;
  logic [3:0][8:0] nxt_nr9;
  fpsqrt_r16_block u_fpsqrt_r16_block (
    .fp_fmt_i(fp_fmt_q), .f_r_s_i(f_r_s_q), .f_r_c_i(f_r_c_q), .rt_i(rt_q), .rt_m1_i(rt_m1_q), .mask_i(mask_q),
    .nr_f_r_7b_for_nxt_cycle_s0_qds_0_i(nr_f_r_7b_q[0]), .nr_f_r_7b_for_nxt_cycle_s0_qds_1_i(nr_f_r_7b_q[1]),
    .nr_f_r_7b_for_nxt_cycle_s0_qds_2_i(nr_f_r_7b_q[2]), .nr_f_r_7b_for_nxt_cycle_s0_qds_3_i(nr_f_r_7b_q[3]),
    .nr_f_r_9b_for_nxt_cycle_s1_qds_0_i(nr_f_r_9b_q[0]), .nr_f_r_9b_for_nxt_cycle_s1_qds_1_i(nr_f_r_9b_q[1]),
    .nr_f_r_9b_for_nxt_cycle_s1_qds_2_i(nr_f_r_9b_q[2]), .nr_f_r_9b_for_nxt_cycle_s1_qds_3_i(nr_f_r_9b_q[3]),
    .m_neg_1_for_nxt_cycle_s0_qds_0_i(m_neg_1_q[0]), .m_neg_1_for_nxt_cycle_s0_qds_1_i(m_neg_1_q[1]),
    .m_neg_1_for_nxt_cycle_s0_qds_2_i(m_neg_1_q[2]), .m_neg_1_for_nxt_cycle_s0_qds_3_i(m_neg_1_q[3]),
    .m_neg_0_for_nxt_cycle_s0_qds_0_i(m_neg_0_q[0]), .m_neg_0_for_nxt_cycle_s0_qds_1_i(m_neg_0_q[1]),
    .m_neg_0_for_nxt_cycle_s0_qds_2_i(m_neg_0_q[2]), .m_neg_0_for_nxt_cycle_s0_qds_3_i(m_neg_0_q[3]),
    .m_pos_1_for_nxt_cycle_s0_qds_0_i(m_pos_1_q[0]), .m_pos_1_for_nxt_cycle_s0_qds_1_i(m_pos_1_q[1]),
    .m_pos_1_for_nxt_cycle_s0_qds_2_i(m_pos_1_q[2]), .m_pos_1_for_nxt_cycle_s0_qds_3_i(m_pos_1_q[3]),
    .m_pos_2_for_nxt_cycle_s0_qds_0_i(m_pos_2_q[0]), .m_pos_2_for_nxt_cycle_s0_qds_1_i(m_pos_2_q[1]),
    .m_pos_2_for_nxt_cycle_s0_qds_2_i(m_pos_2_q[2]), .m_pos_2_for_nxt_cycle_s0_qds_3_i(m_pos_2_q[3]),
    .nxt_rt_o(nxt_rt), .nxt_rt_m1_o(nxt_rt_m1), .nxt_f_r_s_o(nxt_f_r_s), .nxt_f_r_c_o(nxt_f_r_c),
    .adder_7b_res_for_nxt_cycle_s0_qds_0_o(nxt_nr7[0]), .adder_7b_res_for_nxt_cycle_s0_qds_1_o(nxt_nr7[1]),
    .adder_7b_res_for_nxt_cycle_s0_qds_2_o(nxt_nr7[2]), .adder_7b_res_for_nxt_cycle_s0_qds_3_o(nxt_nr7[3]),
    .adder_9b_res_for_nxt_cycle_s1_qds_0_o(nxt_nr9[0]), .adder_9b_res_for_nxt_cycle_s1_qds_1_o(nxt_nr9[1]),
    .adder_9b_res_for_nxt_cycle_s1_qds_2_o(nxt_nr9[2]), .adder_9b_res_for_nxt_cycle_s1_qds_3_o(nxt_nr9[3]),
    .m_neg_1_to_nxt_cycle_0_o(nxt_m_neg_1[0]), .m_neg_1_to_nxt_cycle_1_o(nxt_m_neg_1[1]),
    .m_neg_1_to_nxt_cycle_2_o(nxt_m_neg_1[2]), .m_neg_1_to_nxt_cycle_3_o(nxt_m_neg_1[3]),
    .m_neg_0_to_nxt_cycle_0_o(nxt_m_neg_0[0]), .m_neg_0_to_nxt_cycle_1_o(nxt_m_neg_0[1]),
    .m_neg_0_to_nxt_cycle_2_o(nxt_m_neg_0[2]), .m_neg_0_to_nxt_cycle_3_o(nxt_m_neg_0[3]),
    .m_pos_1_to_nxt_cycle_0_o(nxt_m_pos_1[0]), .m_pos_1_to_nxt_cycle_1_o(nxt_m_pos_1[1]),
    .m_pos_1_to_nxt_cycle_2_o(nxt_m_pos_1[2]), .m_pos_1_to_nxt_cycle_3_o(nxt_m_pos_1[3]),
    .m_pos_2_to_nxt_cycle_0_o(nxt_m_pos_2[0]), .m_pos_2_to_nxt_cycle_1_o(nxt_m_pos_2[1]),
    .m_pos_2_to_nxt_cycle_2_o(nxt_m_pos_2[2]), .m_pos_2_to_nxt_cycle_3_o(nxt_m_pos_2[3]));

  // ---------------------------------------------------------------------------
  // §4 状态机与寄存器更新
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                       fsm_q <= FSM_PRE_0;
    else if (flush_i)                fsm_q <= FSM_PRE_0;
    else if (fsm_q == FSM_PRE_0)     fsm_q <= start_valid_i ? (need_2_cycles_init ? FSM_PRE_1 : FSM_ITER) : FSM_PRE_0;
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
      if (in_pre0)      iter_num_q <= need_2_cycles_init ? {iter_num_q[3:2], lsh_0[1:0]} : iter_num_fmt_i;
      else if (in_pre1) iter_num_q <= iter_num_fmt_q;
      else              iter_num_q <= iter_num_q - 4'd1;
    end
    if (start_handshaked) begin
      fp_fmt_q            <= {fmt64_i, fmt32_i, fmt16_i};
      rm_q                <= rm_i;
      out_sign_q          <= ~res_is_nan_d & op_sign;
      out_exp_0_q         <= out_exp_pre_0[11:1];
      out_exp_1_q         <= out_exp_pre_1[8:1];
      out_exp_2_q         <= out_exp_pre_2[5:1];
      out_exp_3_q         <= out_exp_pre_3[5:1];
      res_is_nan_q        <= res_is_nan_d;
      res_is_inf_q        <= res_is_inf_d;
      res_is_exact_zero_q <= op_is_zero;
      op_invalid_q        <= op_invalid_d;
    end
    if (data_en) begin
      if (in_pre0)      rt_q <= need_2_cycles_init ? {rt_q[55:43], frac_lsh_3, frac_lsh_2, frac_lsh_1} : rt_init;
      else if (in_pre1) rt_q <= rt_init;
      else              rt_q <= nxt_rt;
      if (in_pre0)      rt_m1_q <= need_2_cycles_init ? {rt_m1_q[52], frac_lsh_coarse_0} : rt_m1_init;
      else if (in_pre1) rt_m1_q <= rt_m1_init;
      else              rt_m1_q <= nxt_rt_m1;
      if (in_pre0)      mask_q <= need_2_cycles_init ? {mask_q[12:4], exp_is_odd_pre} : 13'h1000;
      else if (in_pre1) mask_q <= 13'h1000;
      else              mask_q <= {1'b0, mask_q[12:1]};
      f_r_s_q <= init_phase ? f_r_s_init : nxt_f_r_s;
      f_r_c_q <= init_phase ? f_r_c_init : nxt_f_r_c;
      for (int k = 0; k < 4; k++) begin
        nr_f_r_7b_q[k] <= init_phase ? nr7_init[k] : nxt_nr7[k];
        nr_f_r_9b_q[k] <= init_phase ? nr9_init[k] : nxt_nr9[k];
        m_neg_1_q[k]   <= init_phase ? m_neg_1_init[k][4:0] : nxt_m_neg_1[k][4:0];
        m_neg_0_q[k]   <= init_phase ? m_neg_0_init[k][3:0] : nxt_m_neg_0[k][3:0];
        m_pos_1_q[k]   <= init_phase ? m_pos_1_init[k][2:0] : nxt_m_pos_1[k][2:0];
        m_pos_2_q[k]   <= init_phase ? m_pos_2_init[k][4:1] : nxt_m_pos_2[k][4:1];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §5 后处理：余数符号 / 非零、舍入、结果组装
  // ---------------------------------------------------------------------------
  // 四条通道并排相加求余数符号：通道间插 1 位挡板——f16 时为 0（各算各的），否则为 1 让进位穿过
  logic [66:0] nr_f_r;
  assign nr_f_r = 67'({f_r_s_q[63:48], ~fmt16_q, f_r_s_q[47:32], fmt64_q, f_r_s_q[31:16], ~fmt16_q, f_r_s_q[15:0]}
                    + {f_r_c_q[63:48], 1'b0,     f_r_c_q[47:32], 1'b0,    f_r_c_q[31:16], 1'b0,     f_r_c_q[15:0]});
  logic [3:0] rem_neg;                   // 余数为负 → 真根是 rt - 1
  assign rem_neg = {nr_f_r[15], nr_f_r[49], nr_f_r[32], nr_f_r[66]};
  // 余数非零（sticky）：s+c != 0 当且仅当 (s^c)[i] != (s|c)[i-1] 在某位不等，或和为负
  logic [61:0] f_r_xor, f_r_or;
  assign f_r_xor = f_r_s_q[62:1] ^ f_r_c_q[62:1];
  assign f_r_or  = f_r_s_q[61:0] | f_r_c_q[61:0];
  logic [3:0] sticky;
  assign sticky[0] = rem_neg[0] | (f_r_xor[61:48] != f_r_or[61:48]) | (~fmt16_q & (f_r_xor[47:36] != f_r_or[47:36]))
                   | (fmt64_q & (f_r_xor[35:8] != f_r_or[35:8]));
  assign sticky[1] = rem_neg[1] | (f_r_xor[29:16] != f_r_or[29:16]) | (fmt32_q & (f_r_xor[15:4] != f_r_or[15:4]));
  assign sticky[2] = rem_neg[2] | (f_r_xor[45:32] != f_r_or[45:32]);
  assign sticky[3] = rem_neg[3] | (f_r_xor[13:0] != f_r_or[13:0]);

  // 根的尾数部分（去掉每通道的整数位与保护位），各通道并排；按格式把通道边界位清零再做"加一"
  logic [51:0] rt_pre_inc, rt_inc_lane;
  logic [52:0] rt_inc_res;
  assign rt_pre_inc  = {rt_q[54:42], ~fmt16_q & rt_q[41], rt_q[40:28], ~(fmt16_q | fmt32_q) & rt_q[27],
                        rt_q[26:14], ~fmt16_q & rt_q[13], rt_q[12:3]};
  assign rt_inc_lane = ({52{fmt16_q}} & 52'h4001_0004_001) | ({52{fmt32_q}} & 52'h2000_0002) | {51'b0, fmt64_q};
  assign rt_inc_res  = 53'({1'b0, rt_pre_inc} + {1'b0, rt_inc_lane});

  // 保护位 / 舍入位（根与根减一各一套；通道 0/1 的位置随格式变）
  logic [3:0] guard_rt, round_rt, guard_m1, round_m1;
  assign guard_rt[0] = (fmt16_q & rt_q[45]) | (fmt32_q & rt_q[32]) | (fmt64_q & rt_q[3]);
  assign guard_rt[1] = (fmt16_q & rt_q[17]) | (fmt32_q & rt_q[4]);
  assign guard_rt[2] = rt_q[31];
  assign guard_rt[3] = rt_q[3];
  assign round_rt[0] = (fmt16_q & rt_q[44]) | (fmt32_q & rt_q[31]) | (fmt64_q & rt_q[2]);
  assign round_rt[1] = (fmt16_q & rt_q[16]) | (fmt32_q & rt_q[3]);
  assign round_rt[2] = rt_q[30];
  assign round_rt[3] = rt_q[2];
  assign guard_m1[0] = (fmt16_q & rt_m1_q[43]) | (fmt32_q & rt_m1_q[30]) | (fmt64_q & rt_m1_q[1]);
  assign guard_m1[1] = (fmt16_q & rt_m1_q[17]) | (fmt32_q & rt_m1_q[4]);
  assign guard_m1[2] = rt_m1_q[30];
  assign guard_m1[3] = rt_m1_q[4];
  assign round_m1[0] = (fmt16_q & rt_m1_q[42]) | (fmt32_q & rt_m1_q[29]) | (fmt64_q & rt_m1_q[0]);
  assign round_m1[1] = (fmt16_q & rt_m1_q[16]) | (fmt32_q & rt_m1_q[3]);
  assign round_m1[2] = rt_m1_q[29];
  assign round_m1[3] = rt_m1_q[3];

  // 要不要进位：根按 rm 看舍入位/sticky；根减一（余数为负时的真根）RUP 必进，RNE/RMM 看它自己的舍入位
  logic rm_rne, rm_rup, rm_rmm;
  assign rm_rne = (rm_q == RM_RNE);
  assign rm_rup = (rm_q == RM_RUP);
  assign rm_rmm = (rm_q == RM_RMM);
  logic [3:0] inexact_rt, rt_rup, m1_rup;
  assign inexact_rt = round_rt | sticky;
  assign rt_rup     = (round_rt & {4{rm_rne}}) | (inexact_rt & {4{rm_rup}}) | (round_rt & {4{rm_rmm}});
  assign m1_rup     = {4{rm_rup}} | ({4{rm_rne | rm_rmm}} & round_m1);

  // 各通道舍入后的尾数（含进位位）：余数为负选根减一那套。根减一的"加一"结果复用根的加法器：
  // 两者保护位相同时 rt_m1 + 1 == rt_inc_res，否则 == rt_pre_inc（golden 的巧算，照抄）。
  logic [52:0] frac_rounded_0;  logic [23:0] frac_rounded_1;  logic [10:0] frac_rounded_2, frac_rounded_3;
  assign frac_rounded_0 = rem_neg[0] ? (m1_rup[0] ? ((guard_rt[0] == guard_m1[0]) ? rt_inc_res : {1'b0, rt_pre_inc}) : {1'b0, rt_m1_q[52:1]})
                                     : (rt_rup[0] ? rt_inc_res : {1'b0, rt_pre_inc});
  assign frac_rounded_1 = rem_neg[1] ? (m1_rup[1] ? ((guard_rt[1] == guard_m1[1]) ? rt_inc_res[24:1] : {1'b0, rt_pre_inc[23:1]}) : {1'b0, rt_m1_q[26:4]})
                                     : (rt_rup[1] ? rt_inc_res[24:1] : {1'b0, rt_pre_inc[23:1]});
  assign frac_rounded_2 = rem_neg[2] ? (m1_rup[2] ? ((guard_rt[2] == guard_m1[2]) ? rt_inc_res[38:28] : {1'b0, rt_pre_inc[37:28]}) : {1'b0, rt_m1_q[39:30]})
                                     : (rt_rup[2] ? rt_inc_res[38:28] : {1'b0, rt_pre_inc[37:28]});
  assign frac_rounded_3 = rem_neg[3] ? (m1_rup[3] ? ((guard_rt[3] == guard_m1[3]) ? rt_inc_res[10:0] : {1'b0, rt_pre_inc[9:0]}) : {1'b0, rt_m1_q[13:4]})
                                     : (rt_rup[3] ? rt_inc_res[10:0] : {1'b0, rt_pre_inc[9:0]});
  logic [10:0] exp_rounded_0;  logic [7:0] exp_rounded_1;  logic [4:0] exp_rounded_2, exp_rounded_3;
  assign exp_rounded_0 = frac_rounded_0[52] ? 11'(out_exp_0_q + 11'd1) : out_exp_0_q;
  assign exp_rounded_1 = frac_rounded_1[23] ? 8'(out_exp_1_q + 8'd1)   : out_exp_1_q;
  assign exp_rounded_2 = frac_rounded_2[10] ? 5'(out_exp_2_q + 5'd1)   : out_exp_2_q;
  assign exp_rounded_3 = frac_rounded_3[10] ? 5'(out_exp_3_q + 5'd1)   : out_exp_3_q;

  // 特殊值优先：NaN/Inf → 全 1 指数（NaN 尾数置最高位），零 → 全 0
  logic [3:0] exp_all_ones, frac_zero;
  assign exp_all_ones = res_is_nan_q | res_is_inf_q;
  assign frac_zero    = res_is_inf_q | res_is_exact_zero_q;
  logic [15:0] f16_res_0, f16_res_1, f16_res_2, f16_res_3;
  logic [31:0] f32_res_0, f32_res_1;
  logic [63:0] f64_res_0;
  assign f16_res_0 = {out_sign_q[0], exp_all_ones[0] ? 5'h1F : res_is_exact_zero_q[0] ? 5'h0 : exp_rounded_0[4:0],
                      res_is_nan_q[0] ? 10'h200 : frac_zero[0] ? 10'h0 : frac_rounded_0[51:42]};
  assign f16_res_1 = {out_sign_q[1], exp_all_ones[1] ? 5'h1F : res_is_exact_zero_q[1] ? 5'h0 : exp_rounded_1[4:0],
                      res_is_nan_q[1] ? 10'h200 : frac_zero[1] ? 10'h0 : frac_rounded_1[22:13]};
  assign f16_res_2 = {out_sign_q[2], exp_all_ones[2] ? 5'h1F : res_is_exact_zero_q[2] ? 5'h0 : exp_rounded_2,
                      res_is_nan_q[2] ? 10'h200 : frac_zero[2] ? 10'h0 : frac_rounded_2[9:0]};
  assign f16_res_3 = {out_sign_q[3], exp_all_ones[3] ? 5'h1F : res_is_exact_zero_q[3] ? 5'h0 : exp_rounded_3,
                      res_is_nan_q[3] ? 10'h200 : frac_zero[3] ? 10'h0 : frac_rounded_3[9:0]};
  assign f32_res_0 = {out_sign_q[0], exp_all_ones[0] ? 8'hFF : res_is_exact_zero_q[0] ? 8'h0 : exp_rounded_0[7:0],
                      res_is_nan_q[0] ? 23'h400000 : frac_zero[0] ? 23'h0 : frac_rounded_0[51:29]};
  assign f32_res_1 = {out_sign_q[1], exp_all_ones[1] ? 8'hFF : res_is_exact_zero_q[1] ? 8'h0 : exp_rounded_1,
                      res_is_nan_q[1] ? 23'h400000 : frac_zero[1] ? 23'h0 : frac_rounded_1[22:0]};
  assign f64_res_0 = {out_sign_q[0], exp_all_ones[0] ? 11'h7FF : res_is_exact_zero_q[0] ? 11'h0 : exp_rounded_0,
                      res_is_nan_q[0] ? 52'h8000000000000 : frac_zero[0] ? 52'h0 : frac_rounded_0[51:0]};
  assign fpsqrt_res_o = ({64{fmt16_q}} & {f16_res_0, f16_res_2, f16_res_1, f16_res_3})
                      | ({64{fmt32_q}} & {f32_res_0, f32_res_1})
                      | ({64{fmt64_q}} & f64_res_0);

  // fflags：每通道 5 位 {NV, DZ, OF, UF, NX}，只有 NV 与 NX 可能置位；按格式排列各通道
  logic [3:0] fflags_inexact;
  assign fflags_inexact = (inexact_rt | rem_neg) & ~res_is_nan_q & ~res_is_exact_zero_q;
  logic [3:0][4:0] fl;
  for (genvar k = 0; k < 4; k++) begin : g_fl
    assign fl[k] = {op_invalid_q[k], 3'b0, fflags_inexact[k]};
  end
  assign fflags_o = ({20{fmt16_q}} & {fl[0], fl[2], fl[1], fl[3]})
                  | ({20{fmt32_q}} & {10'b0, fl[0], fl[1]})
                  | ({20{fmt64_q}} & {15'b0, fl[0]});
endmodule

module fpsqrt_vector_r16 (
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
  output logic [19:0] fflags_o
);
  xs_fpsqrt_vector_r16_core u_core (
    .clock          (clock),
    .reset          (reset),
    .start_valid_i  (start_valid_i),
    .start_ready_o  (start_ready_o),
    .flush_i        (flush_i),
    .fp_format_i    (fp_format_i),
    .op_i           (op_i),
    .rm_i           (rm_i),
    .finish_valid_o (finish_valid_o),
    .finish_ready_i (finish_ready_i),
    .fpsqrt_res_o   (fpsqrt_res_o),
    .fflags_o       (fflags_o)
  );
endmodule
