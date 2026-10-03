// =============================================================================
// VectorFloatDividerR64.sv —— 向量浮点除法器（SRT 基 4，每拍 3 个商位 = "R64"），f64×1 / f32×2 / f16×4
//
// 在哪一层：VFDivSqrt → VectorFloatDivider 里的除法半边（另一半是 fpsqrt_vector_r16 开方）。
//   一条 64 位向量寄存器里装 1 个 f64、2 个 f32 或 4 个 f16，本模块一次算完全部元素的 a/b，
//   多拍状态机：PRE_0 收操作数 → PRE_1 预缩放 → PRE_2 装初始余数 → ITER 迭代 → POST_0 舍入 →
//   POST_1 非规格数补救 + 输出握手。
// 设计源：yunsuan/vector/VectorFloatDivider.scala class VectorFloatDividerR64。golden 里父级把
//   is_vec_i 接成常量 1、is_frs1/is_frs2 接 0（标量 f[rs] 通路与 early_finish / 2 的幂快速通路都被
//   firtool 消掉），所以本模块只有向量通路：每个操作都走满 PRE_0..POST_1 六个状态。
//
// 4 条"通道"（golden 寄存器名的后缀）：
//   通道    装的元素                         尾数宽 FW  商寄存器宽 QW  缩放后宽  余数宽  指数差宽
//   f64_0   f64 / f32 元素 0 / f16 元素 0     52         54           57        60      13
//   f32_1   f32 元素 1 / f16 元素 1           23         25           28        31      10
//   f16_2   f16 元素 2                        10         12           15        18      7
//   f16_3   f16 元素 3                        10         12           15        18      7
//   通道 0/1 是"可变宽"的：装窄格式时尾数左对齐到通道宽度，低位补 0，迭代仍按通道宽度跑
//   （迭代次数按格式取 9/4/2 拍：iter_num 初值 8/3/1）；舍入/移位时用格式掩掉不属于本元素的位。
//   迭代核 fpdiv_r64_block_vector 用一个 72 位余数向量 / 60 位除数向量同时服务三种格式，
//   所以 f_r_s/f_r_c/frac_divisor 这三个寄存器是按格式打包的公共向量，其余寄存器按通道分开。
//
// 算法要点（每条通道相同）：
//   1. 商的指数差 = (Ea + bias) − Eb，非规格数先左规（ShiftLeftPriorityWithLZDResult 求前导零并左移）。
//   2. 预缩放：按除数尾数最高 3 位查表，被除数与除数同乘一个 9/8..16/8 的因子，使除数落进
//      qds 常数表适用的窄区间（之后 s0 商位只需看余数，不必看除数）。
//   3. 装初始余数与"整数商位"（+2 或 +1），随后每拍 3 个基 4 商位；商用 on-the-fly 转换同时维护
//      Q 与 Q−1 两份（quo_iter / quo_m1_iter），最后按余数符号二选一，免去一次减 1 的进位链。
//   4. 结果是非规格数时先右移（移位量封顶 limit），舍入在 POST_0（规格数）或 POST_1（非规格数，
//      借用 quo_m1_iter / frac_divisor 两个寄存器暂存右移后的商与粘滞位）完成。
//
// 怪癖（全部照抄 golden，FM 在所有寄存器取值上比，包括非 one-hot 的状态/格式寄存器）：
//   - 状态机寄存器 fsm_q 是 one-hot，但各寄存器的下一态写成"各状态项按位或"（与 Chisel 的
//     Mux1H/Fill 写法一致），非法多热状态下几项会叠加，本文件逐项保留同样的叠加方式。
//   - f64 通道的预缩放源在 PRE_0 时取操作数、否则取寄存器（其余通道直接取寄存器）。
//   - f64 通道的溢出判断只比指数差的低 12 位（不看符号位），f32/f16 通道比全宽。
//   - 非规格数结果的指数恒取"舍入进位"（0 或 1），由 POST_1 的路径单独给出。
// 子模块（实例名与 golden 一致）：ShiftLeftPriorityWithLZDResult ×2（f64）/ _6 ×2（f32）/ _8 ×4（f16），
//   fpdiv_r64_block_vector ×1——全部为本仓已签核的重写件。
// golden 对照：G1-canonical/golden-rtl/VectorFloatDividerR64.sv
// =============================================================================
module xs_VectorFloatDividerR64_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        start_valid,
  output logic        start_ready,
  input  logic        flush,
  input  logic [1:0]  fp_format,     // 2'b01 f16 / 2'b10 f32 / 2'b11 f64
  input  logic [63:0] opa,           // 被除数向量（vs2）
  input  logic [63:0] opb,           // 除数向量（vs1）
  input  logic [2:0]  rm,
  output logic        finish_valid,
  input  logic        finish_ready,
  output logic [63:0] fpdiv_res,
  output logic [19:0] fflags         // 每元素 5 位 {NV, DZ, OF, UF, NX}，元素 k 在 [5k+4:5k]
);
  // ===========================================================================
  // §0 小工具
  // ===========================================================================
  localparam logic [2:0] RM_RNE = 3'd0, RM_RDN = 3'd2, RM_RUP = 3'd3, RM_RMM = 3'd4;

  // 舍入：给定最低保留位 lsb、舍入位 rnd、粘滞位 stk，按舍入模式判断是否 +1（RTZ 永不进位）
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

  // 商的 on-the-fly 转换：本级商位 dig（one-hot，[0]=+2 [1]=+1 [2]=0 [3]=-1 [4]=-2）接在
  // Q / Q−1 后面。Q' = Q·4 + q，(Q−1)' = Q'−1；q<0 时从 Q−1 借位。输入右对齐，调用方截取宽度。
  function automatic logic [57:0] otf_quo(input logic [4:0] dig, input logic [55:0] q, input logic [55:0] qm1);
    otf_quo = {58{dig[0]}} & {q,   2'd2} | {58{dig[1]}} & {q,   2'd1} | {58{dig[2]}} & {q, 2'd0}
            | {58{dig[3]}} & {qm1, 2'd3} | {58{dig[4]}} & {qm1, 2'd2};
  endfunction
  function automatic logic [57:0] otf_quo_m1(input logic [4:0] dig, input logic [55:0] q, input logic [55:0] qm1);
    otf_quo_m1 = {58{dig[0]}} & {q,   2'd1} | {58{dig[1]}} & {q,   2'd0} | {58{dig[2]}} & {qm1, 2'd3}
               | {58{dig[3]}} & {qm1, 2'd2} | {58{dig[4]}} & {qm1, 2'd1};
  endfunction

  // 预缩放：x = 1.frac（frac 宽 fw，右对齐），按除数尾数最高 3 位 sel 乘一个因子 /8：
  //   sel  0   1   2   3   4   5   6   7
  //   ×    16  14  13  12  11  10  9   9      （= 8 + t1 + t2，t1 ∈ {4,2,0}·x，t2 ∈ {4,1,0}·x）
  // 结果宽 fw+5，调用方截取。
  function automatic logic [56:0] prescale(input logic [51:0] frac, input int fw, input logic [2:0] sel);
    logic [56:0] x, t1, t2;
    x = (57'd1 << fw) | 57'(frac);
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

  // 非规格数结果的右移量：t = 1 − 指数差；t ≤ 0 不移，0 < t < limit 移 t，否则封顶 limit
  //   （t 与 t−limit 都按指数差宽度取模，用各自的最高位判负，照抄 golden）
  function automatic logic [5:0] denorm_shift(input logic t_neg, input logic t_minus_limit_neg,
                                              input logic [5:0] t_low, input logic [5:0] limit);
    denorm_shift = t_neg ? 6'd0 : t_minus_limit_neg ? t_low : limit;
  endfunction

  // ===========================================================================
  // §1 状态机（one-hot）与握手
  //   PRE_0(0) 空闲收数 → PRE_1(1) 预缩放 → PRE_2(2) 初始余数 → ITER(3) 迭代 iter_num+1 拍
  //   → POST_0(4) 舍入 → POST_1(5) 输出，等 finish_ready；flush 随时回 PRE_0
  // ===========================================================================
  localparam int PRE_0 = 0, PRE_1 = 1, PRE_2 = 2, ITER = 3, POST_0 = 4, POST_1 = 5;
  logic [5:0] fsm_q;
  logic [3:0] iter_num_q;          // 每通道一位用作移位选择；整体作为迭代计数器
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                                         fsm_q <= 6'b1 << PRE_0;
    else if (flush)                                    fsm_q <= 6'b1 << PRE_0;
    else if (fsm_q == 6'b1 << PRE_0)                   fsm_q <= start_valid ? 6'b1 << PRE_1 : 6'b1 << PRE_0;
    else if (fsm_q == 6'b1 << PRE_1)                   fsm_q <= 6'b1 << PRE_2;
    else if (fsm_q == 6'b1 << PRE_2)                   fsm_q <= 6'b1 << ITER;
    else if (fsm_q == 6'b1 << ITER)                    fsm_q <= (|iter_num_q) ? 6'b1 << ITER : 6'b1 << POST_0;
    else if (fsm_q == 6'b1 << POST_0)                  fsm_q <= 6'b1 << POST_1;
    else if (fsm_q == 6'b1 << POST_1 && !finish_ready) fsm_q <= 6'b1 << POST_1;
    else                                               fsm_q <= 6'b1 << PRE_0;
  end
  assign start_ready  = fsm_q[PRE_0];
  assign finish_valid = fsm_q[POST_1];

  logic start_hs;                  // 收数握手
  assign start_hs = start_valid & fsm_q[PRE_0];

  // ===========================================================================
  // §2 操作数拆包（按输入格式把各元素装进 4 条通道）
  //   f64 通道 Mux1H：f64 取整个 64 位，f32 取低 32 位元素 0，f16 取低 16 位元素 0（尾数左对齐）
  //   f32 通道：f32 取高 32 位元素 1，f16 取元素 1（[31:16]）；f16_2 / f16_3 恒取元素 2 / 3
  // ===========================================================================
  logic in_f16, in_f32, in_f64;
  assign in_f16 = fp_format == 2'd1;
  assign in_f32 = fp_format == 2'd2;
  assign in_f64 = &fp_format;

  logic        a_sign_0, b_sign_0, a_sign_1, b_sign_1;
  logic [10:0] a_exp_0, b_exp_0;
  logic [7:0]  a_exp_1, b_exp_1;
  logic [4:0]  a_exp_2, b_exp_2, a_exp_3, b_exp_3;
  logic [51:0] a_frac_0, b_frac_0;
  logic [22:0] a_frac_1, b_frac_1;
  logic [9:0]  a_frac_2, b_frac_2, a_frac_3, b_frac_3;
  always_comb begin
    a_sign_0 = in_f64 & opa[63] | in_f32 & opa[31] | in_f16 & opa[15];
    b_sign_0 = in_f64 & opb[63] | in_f32 & opb[31] | in_f16 & opb[15];
    a_sign_1 = in_f32 ? opa[63] : opa[31];
    b_sign_1 = in_f32 ? opb[63] : opb[31];
    a_exp_0  = {11{in_f64}} & opa[62:52] | {11{in_f32}} & {3'b0, opa[30:23]} | {11{in_f16}} & {6'b0, opa[14:10]};
    b_exp_0  = {11{in_f64}} & opb[62:52] | {11{in_f32}} & {3'b0, opb[30:23]} | {11{in_f16}} & {6'b0, opb[14:10]};
    a_exp_1  = in_f32 ? opa[62:55] : {3'b0, opa[30:26]};
    b_exp_1  = in_f32 ? opb[62:55] : {3'b0, opb[30:26]};
    a_exp_2  = opa[46:42];  b_exp_2 = opb[46:42];
    a_exp_3  = opa[62:58];  b_exp_3 = opb[62:58];
    a_frac_0 = {52{in_f64}} & opa[51:0] | {52{in_f32}} & {opa[22:0], 29'b0} | {52{in_f16}} & {opa[9:0], 42'b0};
    b_frac_0 = {52{in_f64}} & opb[51:0] | {52{in_f32}} & {opb[22:0], 29'b0} | {52{in_f16}} & {opb[9:0], 42'b0};
    a_frac_1 = in_f32 ? opa[54:32] : {opa[25:16], 13'b0};
    b_frac_1 = in_f32 ? opb[54:32] : {opb[25:16], 13'b0};
    a_frac_2 = opa[41:32];  b_frac_2 = opb[41:32];
    a_frac_3 = opa[57:48];  b_frac_3 = opb[57:48];
  end

  // 指数全 0（零 / 非规格数）与全 1（∞ / NaN）；通道 0/1 的"全 1"按格式取 7FF/FF/1F
  logic [3:0] a_exp_zero, b_exp_zero, a_exp_max, b_exp_max;
  logic [10:0] exp_max_0;
  logic [7:0]  exp_max_1;
  always_comb begin
    exp_max_0     = {11{in_f64}} | (in_f32 ? 11'hFF : 11'h0) | (in_f16 ? 11'h1F : 11'h0);
    exp_max_1     = in_f32 ? 8'hFF : 8'h1F;
    a_exp_zero[0] = a_exp_0 == '0;   b_exp_zero[0] = b_exp_0 == '0;
    a_exp_zero[1] = a_exp_1 == '0;   b_exp_zero[1] = b_exp_1 == '0;
    a_exp_zero[2] = a_exp_2 == '0;   b_exp_zero[2] = b_exp_2 == '0;
    a_exp_zero[3] = a_exp_3 == '0;   b_exp_zero[3] = b_exp_3 == '0;
    a_exp_max[0]  = a_exp_0 == exp_max_0;  b_exp_max[0] = b_exp_0 == exp_max_0;
    a_exp_max[1]  = a_exp_1 == exp_max_1;  b_exp_max[1] = b_exp_1 == exp_max_1;
    a_exp_max[2]  = &a_exp_2;              b_exp_max[2] = &b_exp_2;
    a_exp_max[3]  = &a_exp_3;              b_exp_max[3] = &b_exp_3;
  end

  // 尾数是否全 0、尾数最高位（quiet 位）
  logic [3:0] a_frac_zero, b_frac_zero, a_frac_msb, b_frac_msb;
  assign a_frac_zero = {~|a_frac_3, ~|a_frac_2, ~|a_frac_1, ~|a_frac_0};
  assign b_frac_zero = {~|b_frac_3, ~|b_frac_2, ~|b_frac_1, ~|b_frac_0};
  assign a_frac_msb  = {a_frac_3[9], a_frac_2[9], a_frac_1[22], a_frac_0[51]};
  assign b_frac_msb  = {b_frac_3[9], b_frac_2[9], b_frac_1[22], b_frac_0[51]};

  // ===========================================================================
  // §3 特殊值分类（每通道 4 位向量，下标 = 通道号）
  // ===========================================================================
  logic [3:0] a_zero, b_zero, a_inf, b_inf, a_snan, b_snan, a_qnan, b_qnan;
  logic [3:0] op_invalid, res_nan, res_inf, res_exact_zero, div_by_zero, out_sign;
  always_comb begin
    a_zero = a_exp_zero & a_frac_zero;            b_zero = b_exp_zero & b_frac_zero;
    a_inf  = a_exp_max & a_frac_zero;             b_inf  = b_exp_max & b_frac_zero;
    a_snan = a_exp_max & ~a_frac_msb & ~a_frac_zero;
    b_snan = b_exp_max & ~b_frac_msb & ~b_frac_zero;
    a_qnan = a_exp_max & a_frac_msb;              b_qnan = b_exp_max & b_frac_msb;
    op_invalid     = a_inf & b_inf | a_zero & b_zero | a_snan | b_snan;     // ∞/∞、0/0、sNaN
    res_nan        = a_qnan | a_snan | b_qnan | b_snan | op_invalid;
    res_inf        = a_inf | b_zero;                                         // ∞/x、x/0
    res_exact_zero = a_zero | b_inf;                                         // 0/x、x/∞
    div_by_zero    = ~res_nan & ~a_inf & b_zero;
    out_sign       = ~res_nan & ({opa[63], opa[47], a_sign_1, a_sign_0} ^ {opb[63], opb[47], b_sign_1, b_sign_0});
  end

  // PRE_0 收数时锁存的标志
  logic [3:0] opb_is_power_of_2_q;   // 除数尾数全 0（2 的幂）：商就是被除数尾数，跳过迭代修正
  logic [2:0] fp_format_onehot_q;    // {f64, f32, f16}
  logic [2:0] rm_q;
  logic [3:0] out_sign_q, res_is_nan_q, res_is_inf_q, res_is_exact_zero_q;
  logic [3:0] op_invalid_div_q, divided_by_zero_q;
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
  logic fmt16_q, fmt32_q, fmt64_q;
  assign {fmt64_q, fmt32_q, fmt16_q} = fp_format_onehot_q;

  // ===========================================================================
  // §4 非规格数左规：前导零计数 + 左移（尾数前补 0 位让全 0 时的移位量落在合法区间）
  // ===========================================================================
  logic [52:0] a_lsh_0, b_lsh_0;  logic [5:0] a_lzd_0, b_lzd_0;
  logic [23:0] a_lsh_1, b_lsh_1;  logic [4:0] a_lzd_1, b_lzd_1;
  logic [10:0] a_lsh_2, b_lsh_2, a_lsh_3, b_lsh_3;
  logic [3:0]  a_lzd_2, b_lzd_2, a_lzd_3, b_lzd_3;
  ShiftLeftPriorityWithLZDResult U_Left_Shift_opa_f64_0 (.io_src({1'b0, a_frac_0}), .io_priority_shiftValue({1'b0, a_frac_0}),
                                                         .io_lshift_result(a_lsh_0), .io_lzd_result(a_lzd_0));
  ShiftLeftPriorityWithLZDResult U_Left_Shift_opb_f64_0 (.io_src({1'b0, b_frac_0}), .io_priority_shiftValue({1'b0, b_frac_0}),
                                                         .io_lshift_result(b_lsh_0), .io_lzd_result(b_lzd_0));
  ShiftLeftPriorityWithLZDResult_6 U_Left_Shift_opa_f32_1 (.io_src({1'b0, a_frac_1}), .io_priority_shiftValue({1'b0, a_frac_1}),
                                                           .io_lshift_result(a_lsh_1), .io_lzd_result(a_lzd_1));
  ShiftLeftPriorityWithLZDResult_6 U_Left_Shift_opb_f32_1 (.io_src({1'b0, b_frac_1}), .io_priority_shiftValue({1'b0, b_frac_1}),
                                                           .io_lshift_result(b_lsh_1), .io_lzd_result(b_lzd_1));
  ShiftLeftPriorityWithLZDResult_8 U_Left_Shift_opa_f16_2 (.io_src({1'b0, a_frac_2}), .io_priority_shiftValue({1'b0, a_frac_2}),
                                                           .io_lshift_result(a_lsh_2), .io_lzd_result(a_lzd_2));
  ShiftLeftPriorityWithLZDResult_8 U_Left_Shift_opb_f16_2 (.io_src({1'b0, b_frac_2}), .io_priority_shiftValue({1'b0, b_frac_2}),
                                                           .io_lshift_result(b_lsh_2), .io_lzd_result(b_lzd_2));
  ShiftLeftPriorityWithLZDResult_8 U_Left_Shift_opa_f16_3 (.io_src({1'b0, a_frac_3}), .io_priority_shiftValue({1'b0, a_frac_3}),
                                                           .io_lshift_result(a_lsh_3), .io_lzd_result(a_lzd_3));
  ShiftLeftPriorityWithLZDResult_8 U_Left_Shift_opb_f16_3 (.io_src({1'b0, b_frac_3}), .io_priority_shiftValue({1'b0, b_frac_3}),
                                                           .io_lshift_result(b_lsh_3), .io_lzd_result(b_lzd_3));

  // 规格化后的尾数（非规格数取左移结果，去掉隐含 1 那一位）
  logic [51:0] a_norm_0, b_norm_0;
  logic [22:0] a_norm_1, b_norm_1;
  logic [9:0]  b_norm_2, b_norm_3;
  always_comb begin
    a_norm_0 = a_exp_zero[0] ? a_lsh_0[51:0] : a_frac_0;
    b_norm_0 = b_exp_zero[0] ? b_lsh_0[51:0] : b_frac_0;
    a_norm_1 = a_exp_zero[1] ? a_lsh_1[22:0] : a_frac_1;
    b_norm_1 = b_exp_zero[1] ? b_lsh_1[22:0] : b_frac_1;
    b_norm_2 = b_exp_zero[2] ? b_lsh_2[9:0]  : b_frac_2;
    b_norm_3 = b_exp_zero[3] ? b_lsh_3[9:0]  : b_frac_3;
  end

  // ===========================================================================
  // §5 商的指数差：PRE_0 算 (Ea' + bias) − lzd_a − Eb' + lzd_b（E' = 指数，0 当 1 用），
  //   之后每个 PRE_2/ITER... 实际只在 PRE_2 拍减去 iter_num 位（被除数尾数 < 除数尾数时商要左移一位）
  // ===========================================================================
  logic [12:0] out_exp_diff_q_f64_0;
  logic [9:0]  out_exp_diff_q_f32_1;
  logic [6:0]  out_exp_diff_q_f16_2, out_exp_diff_q_f16_3;
  logic [11:0] bias_0;
  logic [6:0]  bias_1;
  assign bias_0 = in_f16 ? 12'hF : in_f32 ? 12'h7F : 12'h3FF;
  assign bias_1 = in_f16 ? 7'hF : 7'h7F;
  always_ff @(posedge clock) begin
    if (start_hs | fsm_q[PRE_2]) begin
      if (fsm_q[PRE_0]) begin
        out_exp_diff_q_f64_0 <= 13'({1'b0, 12'({1'b0, a_exp_0 | 11'(a_exp_zero[0])} + bias_0)})
                              - 13'({6{a_exp_zero[0]}} & a_lzd_0)
                              - 13'(b_exp_0 | 11'(b_exp_zero[0]))
                              + 13'({6{b_exp_zero[0]}} & b_lzd_0);
        out_exp_diff_q_f32_1 <= 10'({1'b0, 9'({1'b0, a_exp_1 | 8'(a_exp_zero[1])} + {2'b0, bias_1})})
                              - 10'({5{a_exp_zero[1]}} & a_lzd_1)
                              - 10'(b_exp_1 | 8'(b_exp_zero[1]))
                              + 10'({5{b_exp_zero[1]}} & b_lzd_1);
        out_exp_diff_q_f16_2 <= 7'({1'b0, 6'({1'b0, a_exp_2 | 5'(a_exp_zero[2])} + 6'hF)})
                              - 7'({4{a_exp_zero[2]}} & a_lzd_2)
                              - 7'(b_exp_2 | 5'(b_exp_zero[2]))
                              + 7'({4{b_exp_zero[2]}} & b_lzd_2);
        out_exp_diff_q_f16_3 <= 7'({1'b0, 6'({1'b0, a_exp_3 | 5'(a_exp_zero[3])} + 6'hF)})
                              - 7'({4{a_exp_zero[3]}} & a_lzd_3)
                              - 7'(b_exp_3 | 5'(b_exp_zero[3]))
                              + 7'({4{b_exp_zero[3]}} & b_lzd_3);
      end else begin
        out_exp_diff_q_f64_0 <= out_exp_diff_q_f64_0 - 13'(iter_num_q[0]);
        out_exp_diff_q_f32_1 <= out_exp_diff_q_f32_1 - 10'(iter_num_q[1]);
        out_exp_diff_q_f16_2 <= out_exp_diff_q_f16_2 - 7'(iter_num_q[2]);
        out_exp_diff_q_f16_3 <= out_exp_diff_q_f16_3 - 7'(iter_num_q[3]);
      end
    end
  end

  // 结果为非规格数：指数差 ≤ 0（全 0 或符号位为 1）
  logic [3:0] res_is_denormal;
  assign res_is_denormal = {out_exp_diff_q_f16_3[5:0] == '0 | out_exp_diff_q_f16_3[6],
                            out_exp_diff_q_f16_2[5:0] == '0 | out_exp_diff_q_f16_2[6],
                            out_exp_diff_q_f32_1[8:0] == '0 | out_exp_diff_q_f32_1[9],
                            out_exp_diff_q_f64_0[11:0] == '0 | out_exp_diff_q_f64_0[12]};

  // ===========================================================================
  // §6 商寄存器 quo_iter（Q）/ quo_m1_iter（Q−1）与除数寄存器，以及 PRE_1 的预缩放
  //   这两个商寄存器在不同状态里兼作别的用途：
  //     PRE_0 收数：Q ← 1.被除数尾数（规格化后），Q−1 ← 1.除数尾数
  //     PRE_1 缩放：Q ← 缩放后被除数的低位，Q−1 ← 缩放后被除数的最高 3 位；除数寄存器 ← 缩放后除数
  //     ITER      ：Q / Q−1 按 3 个商位做 on-the-fly 转换
  //     POST_0    ：Q−1 ← 规格数：舍入后的尾数；非规格数：{余数非零, 右移后的商}，除数寄存器 ← 粘滞位
  // ===========================================================================
  logic [53:0] quo_iter_q_f64_0, quo_m1_iter_q_f64_0;
  logic [24:0] quo_iter_q_f32_1, quo_m1_iter_q_f32_1;
  logic [11:0] quo_iter_q_f16_2, quo_m1_iter_q_f16_2, quo_iter_q_f16_3, quo_m1_iter_q_f16_3;
  logic [59:0] frac_divisor_q_60bit;   // 按格式打包：f64 [59:3] / f32 [59:32],[29:2] / f16 [14+15k:15k]

  // 各通道当前的除数（从打包向量里按格式取出，左对齐到通道宽度）
  logic [56:0] frac_divisor_q_f64_0;
  logic [27:0] frac_divisor_q_f32_1;
  logic [14:0] frac_divisor_q_f16_2, frac_divisor_q_f16_3;
  always_comb begin
    frac_divisor_q_f64_0 = {57{fmt64_q}} & frac_divisor_q_60bit[59:3]
                         | {57{fmt32_q}} & {frac_divisor_q_60bit[29:2], 29'b0}
                         | {57{fmt16_q}} & {frac_divisor_q_60bit[14:0], 42'b0};
    frac_divisor_q_f32_1 = fmt32_q ? frac_divisor_q_60bit[59:32] : {frac_divisor_q_60bit[29:15], 13'b0};
    frac_divisor_q_f16_2 = frac_divisor_q_60bit[44:30];
    frac_divisor_q_f16_3 = frac_divisor_q_60bit[59:45];
  end

  // PRE_1 预缩放：被除数、除数同乘由除数尾数最高 3 位决定的因子
  logic [51:0] scale_src_a_0, scale_src_b_0;   // f64 通道：PRE_0 时取操作数，否则取寄存器
  logic [56:0] scaled_a_0, scaled_b_0;
  logic [27:0] scaled_a_1, scaled_b_1;
  logic [14:0] scaled_a_2, scaled_b_2, scaled_a_3, scaled_b_3;
  always_comb begin
    scale_src_a_0 = fsm_q[PRE_0] ? a_frac_0 : quo_iter_q_f64_0[51:0];
    scale_src_b_0 = fsm_q[PRE_0] ? b_frac_0 : quo_m1_iter_q_f64_0[51:0];
    scaled_a_0 = prescale(scale_src_a_0, 52, scale_src_b_0[51:49]);
    scaled_b_0 = prescale(scale_src_b_0, 52, scale_src_b_0[51:49]);
    scaled_a_1 = 28'(prescale(52'(quo_iter_q_f32_1[22:0]),    23, quo_m1_iter_q_f32_1[22:20]));
    scaled_b_1 = 28'(prescale(52'(quo_m1_iter_q_f32_1[22:0]), 23, quo_m1_iter_q_f32_1[22:20]));
    scaled_a_2 = 15'(prescale(52'(quo_iter_q_f16_2[9:0]),     10, quo_m1_iter_q_f16_2[9:7]));
    scaled_b_2 = 15'(prescale(52'(quo_m1_iter_q_f16_2[9:0]),  10, quo_m1_iter_q_f16_2[9:7]));
    scaled_a_3 = 15'(prescale(52'(quo_iter_q_f16_3[9:0]),     10, quo_m1_iter_q_f16_3[9:7]));
    scaled_b_3 = 15'(prescale(52'(quo_m1_iter_q_f16_3[9:0]),  10, quo_m1_iter_q_f16_3[9:7]));
  end

  // ===========================================================================
  // §7 迭代核：每拍 3 个基 4 商位（fpdiv_r64_block_vector），及初始余数（PRE_2）
  // ===========================================================================
  logic [71:0] f_r_s_q_72bit, f_r_c_q_72bit;      // 冗余余数 sum / carry（按格式打包）
  logic [5:0]  nr_f_r_6b_for_nxt_cycle_s0_qds_q_f64_0, nr_f_r_6b_for_nxt_cycle_s0_qds_q_f32_1,
               nr_f_r_6b_for_nxt_cycle_s0_qds_q_f16_2, nr_f_r_6b_for_nxt_cycle_s0_qds_q_f16_3;
  logic [6:0]  nr_f_r_7b_for_nxt_cycle_s1_qds_q_f64_0, nr_f_r_7b_for_nxt_cycle_s1_qds_q_f32_1,
               nr_f_r_7b_for_nxt_cycle_s1_qds_q_f16_2, nr_f_r_7b_for_nxt_cycle_s1_qds_q_f16_3;
  logic [4:0]  prev_quo_dig_q_f64_0, prev_quo_dig_q_f32_1, prev_quo_dig_q_f16_2, prev_quo_dig_q_f16_3;

  logic [3:0][2:0][4:0] blk_quo_dig;              // [通道][级]
  logic [71:0]          blk_f_r_s, blk_f_r_c;
  logic [3:0][5:0]      blk_adder6;
  logic [3:0][6:0]      blk_adder7;
  fpdiv_r64_block_vector u_r64_block_vector (
    .io_fp_format_onehot                   (fp_format_onehot_q),
    .io_f_r_s_i                            (f_r_s_q_72bit),
    .io_f_r_c_i                            (f_r_c_q_72bit),
    .io_divisor_i                          (frac_divisor_q_60bit),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_0 (nr_f_r_6b_for_nxt_cycle_s0_qds_q_f64_0),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_1 (nr_f_r_6b_for_nxt_cycle_s0_qds_q_f32_1),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_2 (nr_f_r_6b_for_nxt_cycle_s0_qds_q_f16_2),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_3 (nr_f_r_6b_for_nxt_cycle_s0_qds_q_f16_3),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_0 (nr_f_r_7b_for_nxt_cycle_s1_qds_q_f64_0),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_1 (nr_f_r_7b_for_nxt_cycle_s1_qds_q_f32_1),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_2 (nr_f_r_7b_for_nxt_cycle_s1_qds_q_f16_2),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_3 (nr_f_r_7b_for_nxt_cycle_s1_qds_q_f16_3),
    .io_nxt_quo_dig_o_0_0 (blk_quo_dig[0][0]), .io_nxt_quo_dig_o_0_1 (blk_quo_dig[0][1]), .io_nxt_quo_dig_o_0_2 (blk_quo_dig[0][2]),
    .io_nxt_quo_dig_o_1_0 (blk_quo_dig[1][0]), .io_nxt_quo_dig_o_1_1 (blk_quo_dig[1][1]), .io_nxt_quo_dig_o_1_2 (blk_quo_dig[1][2]),
    .io_nxt_quo_dig_o_2_0 (blk_quo_dig[2][0]), .io_nxt_quo_dig_o_2_1 (blk_quo_dig[2][1]), .io_nxt_quo_dig_o_2_2 (blk_quo_dig[2][2]),
    .io_nxt_quo_dig_o_3_0 (blk_quo_dig[3][0]), .io_nxt_quo_dig_o_3_1 (blk_quo_dig[3][1]), .io_nxt_quo_dig_o_3_2 (blk_quo_dig[3][2]),
    .io_nxt_f_r_s_o_2     (blk_f_r_s),
    .io_nxt_f_r_c_o_2     (blk_f_r_c),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o_0 (blk_adder6[0]),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o_1 (blk_adder6[1]),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o_2 (blk_adder6[2]),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o_3 (blk_adder6[3]),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o_0 (blk_adder7[0]),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o_1 (blk_adder7[1]),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o_2 (blk_adder7[2]),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o_3 (blk_adder7[3])
  );

  // PRE_2 的初始余数：缩放后被除数 A（Q−1 的低 3 位接 Q），被除数尾数 < 除数尾数（iter_num 位）时
  //   多左移一位；整数商位 = A 的整数部分 ≥ 2 ? +2 : +1，初始余数 = A − 整数商位·D（carry 侧给 −kD 的反码，
  //   补码 +1 在 sum 侧最低位）。
  logic [57:0] rem_init_a_0;   logic [28:0] rem_init_a_1;   logic [15:0] rem_init_a_2, rem_init_a_3;
  logic [3:0]  int_quo_is_2;
  logic [59:0] rem_init_c_0;   logic [30:0] rem_init_c_1;   logic [17:0] rem_init_c_2, rem_init_c_3;
  always_comb begin
    rem_init_a_0 = iter_num_q[0] ? {quo_m1_iter_q_f64_0[2:0], quo_iter_q_f64_0, 1'b0} : {1'b0, quo_m1_iter_q_f64_0[2:0], quo_iter_q_f64_0};
    rem_init_a_1 = iter_num_q[1] ? {quo_m1_iter_q_f32_1[2:0], quo_iter_q_f32_1, 1'b0} : {1'b0, quo_m1_iter_q_f32_1[2:0], quo_iter_q_f32_1};
    rem_init_a_2 = iter_num_q[2] ? {quo_m1_iter_q_f16_2[2:0], quo_iter_q_f16_2, 1'b0} : {1'b0, quo_m1_iter_q_f16_2[2:0], quo_iter_q_f16_2};
    rem_init_a_3 = iter_num_q[3] ? {quo_m1_iter_q_f16_3[2:0], quo_iter_q_f16_3, 1'b0} : {1'b0, quo_m1_iter_q_f16_3[2:0], quo_iter_q_f16_3};
    int_quo_is_2 = {rem_init_a_3[15] | &rem_init_a_3[14:13], rem_init_a_2[15] | &rem_init_a_2[14:13],
                    rem_init_a_1[28] | &rem_init_a_1[27:26], rem_init_a_0[57] | &rem_init_a_0[56:55]};
    rem_init_c_0 = int_quo_is_2[0] ? {1'b1, ~frac_divisor_q_f64_0, 2'b11} : {2'b11, ~frac_divisor_q_f64_0, 1'b1};
    rem_init_c_1 = int_quo_is_2[1] ? {1'b1, ~frac_divisor_q_f32_1, 2'b11} : {2'b11, ~frac_divisor_q_f32_1, 1'b1};
    rem_init_c_2 = int_quo_is_2[2] ? {1'b1, ~frac_divisor_q_f16_2, 2'b11} : {2'b11, ~frac_divisor_q_f16_2, 1'b1};
    rem_init_c_3 = int_quo_is_2[3] ? {1'b1, ~frac_divisor_q_f16_3, 2'b11} : {2'b11, ~frac_divisor_q_f16_3, 1'b1};
  end

  // 初始余数按格式打包进 72 位向量。f64 通道的 sum 在 bit41 / bit28 处或上 f16 / f32 标志：
  //   那两位正是打包布局里 f16 元素 0 / f32 元素 0 的"补码 +1"位置（f64 通道与它们共用这些位）。
  logic [57:0] rem_init_a_0_packed;
  logic        rem_init_a_1_bit12;
  always_comb begin
    rem_init_a_0_packed     = rem_init_a_0;
    rem_init_a_0_packed[41] = rem_init_a_0[41] | fmt16_q;
    rem_init_a_0_packed[28] = rem_init_a_0[28] | fmt32_q;
    rem_init_a_1_bit12      = rem_init_a_1[12] | fmt16_q;
  end
  logic [71:0] f_r_s_init, f_r_c_init;
  always_comb begin
    f_r_s_init = {72{fmt64_q}} & {1'b0, rem_init_a_0_packed, fmt64_q, 12'b0}
               | {72{fmt32_q}} & {1'b0, rem_init_a_1[28:13], rem_init_a_1_bit12, rem_init_a_1[11:0], fmt32_q, 6'b0,
                                  rem_init_a_0_packed[57:28], 5'b0}
               | {72{fmt16_q}} & {1'b0, rem_init_a_3, 2'b10, rem_init_a_2, 2'b10,
                                  rem_init_a_1[28:13], rem_init_a_1_bit12, 1'b0, rem_init_a_0_packed[57:41]};
    f_r_c_init = {72{fmt64_q}} & {rem_init_c_0, 12'b0}
               | {72{fmt32_q}} & {rem_init_c_1, 5'b0, rem_init_c_0[59:29], 5'b0}
               | {72{fmt16_q}} & {rem_init_c_3, rem_init_c_2, rem_init_c_1[30:13], rem_init_c_0[59:42]};
  end

  logic rem_en;    // 余数/余数片/上一商位寄存器的写使能
  assign rem_en = start_hs | fsm_q[PRE_2] | fsm_q[ITER];
  always_ff @(posedge clock) begin
    if (rem_en) begin
      f_r_s_q_72bit <= fsm_q[PRE_2] ? f_r_s_init : blk_f_r_s;
      f_r_c_q_72bit <= fsm_q[PRE_2] ? f_r_c_init : blk_f_r_c;
      // 下一拍 s0 / s1 商位用的余数片：PRE_2 由初始余数直接相加，ITER 由迭代核预算
      nr_f_r_6b_for_nxt_cycle_s0_qds_q_f64_0 <= fsm_q[PRE_2] ? 6'(rem_init_a_0[56:51] + rem_init_c_0[57:52]) : blk_adder6[0];
      nr_f_r_6b_for_nxt_cycle_s0_qds_q_f32_1 <= fsm_q[PRE_2] ? 6'(rem_init_a_1[27:22] + rem_init_c_1[28:23]) : blk_adder6[1];
      nr_f_r_6b_for_nxt_cycle_s0_qds_q_f16_2 <= fsm_q[PRE_2] ? 6'(rem_init_a_2[14:9]  + rem_init_c_2[15:10]) : blk_adder6[2];
      nr_f_r_6b_for_nxt_cycle_s0_qds_q_f16_3 <= fsm_q[PRE_2] ? 6'(rem_init_a_3[14:9]  + rem_init_c_3[15:10]) : blk_adder6[3];
      nr_f_r_7b_for_nxt_cycle_s1_qds_q_f64_0 <= fsm_q[PRE_2] ? 7'(rem_init_a_0[54:48] + rem_init_c_0[55:49]) : blk_adder7[0];
      nr_f_r_7b_for_nxt_cycle_s1_qds_q_f32_1 <= fsm_q[PRE_2] ? 7'(rem_init_a_1[25:19] + rem_init_c_1[26:20]) : blk_adder7[1];
      nr_f_r_7b_for_nxt_cycle_s1_qds_q_f16_2 <= fsm_q[PRE_2] ? 7'(rem_init_a_2[12:6]  + rem_init_c_2[13:7])  : blk_adder7[2];
      nr_f_r_7b_for_nxt_cycle_s1_qds_q_f16_3 <= fsm_q[PRE_2] ? 7'(rem_init_a_3[12:6]  + rem_init_c_3[13:7])  : blk_adder7[3];
      // 上一拍的最后一个商位（s2）；PRE_2 时是整数商位 +2 = 5'b00001 / +1 = 5'b00010
      prev_quo_dig_q_f64_0 <= fsm_q[PRE_2] ? {3'b0, ~int_quo_is_2[0], int_quo_is_2[0]} : blk_quo_dig[0][2];
      prev_quo_dig_q_f32_1 <= fsm_q[PRE_2] ? {3'b0, ~int_quo_is_2[1], int_quo_is_2[1]} : blk_quo_dig[1][2];
      prev_quo_dig_q_f16_2 <= fsm_q[PRE_2] ? {3'b0, ~int_quo_is_2[2], int_quo_is_2[2]} : blk_quo_dig[2][2];
      prev_quo_dig_q_f16_3 <= fsm_q[PRE_2] ? {3'b0, ~int_quo_is_2[3], int_quo_is_2[3]} : blk_quo_dig[3][2];
    end
  end

  // 迭代计数：PRE_1 记录"被除数尾数 < 除数尾数"（每通道一位，PRE_2 用它决定初始左移）；
  //   PRE_2 按格式装迭代拍数−1（f16 1 / f32 3 / f64 8）；ITER 每拍减 1，到 0 进 POST_0
  always_ff @(posedge clock) begin
    if (start_hs | fsm_q[PRE_1] | fsm_q[PRE_2] | fsm_q[ITER]) begin
      if (fsm_q[PRE_1])
        iter_num_q <= {quo_iter_q_f16_3[9:0]  < quo_m1_iter_q_f16_3[9:0],
                       quo_iter_q_f16_2[9:0]  < quo_m1_iter_q_f16_2[9:0],
                       quo_iter_q_f32_1[22:0] < quo_m1_iter_q_f32_1[22:0],
                       quo_iter_q_f64_0[51:0] < quo_m1_iter_q_f64_0[51:0]};
      else if (fsm_q[PRE_2])
        iter_num_q <= fmt16_q ? 4'd1 : fmt32_q ? 4'd3 : 4'd8;
      else
        iter_num_q <= iter_num_q - 4'd1;
    end
  end

  // ===========================================================================
  // §8 商的 on-the-fly 转换（3 级：上一拍的 s2 商位 → 本拍 s0 → s1）
  //   级 0 用寄存器里的 prev_quo_dig；它的结果也直接用于收尾（§9）。
  // ===========================================================================
  logic [54:0] quo_l0_0, quo_m1_l0_0;  logic [51:0] quo_l1_0, quo_m1_l1_0;  logic [53:0] quo_l2_0, quo_m1_l2_0;
  logic [25:0] quo_l0_1, quo_m1_l0_1;  logic [22:0] quo_l1_1, quo_m1_l1_1;  logic [24:0] quo_l2_1, quo_m1_l2_1;
  logic [13:0] quo_l0_2, quo_m1_l0_2;  logic [9:0]  quo_l1_2, quo_m1_l1_2;  logic [11:0] quo_l2_2, quo_m1_l2_2;
  logic [13:0] quo_l0_3, quo_m1_l0_3;  logic [9:0]  quo_l1_3, quo_m1_l1_3;  logic [11:0] quo_l2_3, quo_m1_l2_3;
  always_comb begin
    // f64 通道：级 0 截寄存器低 53 位，级 1 截级 0 低 50 位
    quo_l0_0    = 55'(otf_quo   (prev_quo_dig_q_f64_0, 56'(quo_iter_q_f64_0[52:0]), 56'(quo_m1_iter_q_f64_0[52:0])));
    quo_m1_l0_0 = 55'(otf_quo_m1(prev_quo_dig_q_f64_0, 56'(quo_iter_q_f64_0[52:0]), 56'(quo_m1_iter_q_f64_0[52:0])));
    quo_l1_0    = 52'(otf_quo   (blk_quo_dig[0][0], 56'(quo_l0_0[49:0]), 56'(quo_m1_l0_0[49:0])));
    quo_m1_l1_0 = 52'(otf_quo_m1(blk_quo_dig[0][0], 56'(quo_l0_0[49:0]), 56'(quo_m1_l0_0[49:0])));
    quo_l2_0    = 54'(otf_quo   (blk_quo_dig[0][1], 56'(quo_l1_0), 56'(quo_m1_l1_0)));
    quo_m1_l2_0 = 54'(otf_quo_m1(blk_quo_dig[0][1], 56'(quo_l1_0), 56'(quo_m1_l1_0)));
    // f32 通道
    quo_l0_1    = 26'(otf_quo   (prev_quo_dig_q_f32_1, 56'(quo_iter_q_f32_1[23:0]), 56'(quo_m1_iter_q_f32_1[23:0])));
    quo_m1_l0_1 = 26'(otf_quo_m1(prev_quo_dig_q_f32_1, 56'(quo_iter_q_f32_1[23:0]), 56'(quo_m1_iter_q_f32_1[23:0])));
    quo_l1_1    = 23'(otf_quo   (blk_quo_dig[1][0], 56'(quo_l0_1[20:0]), 56'(quo_m1_l0_1[20:0])));
    quo_m1_l1_1 = 23'(otf_quo_m1(blk_quo_dig[1][0], 56'(quo_l0_1[20:0]), 56'(quo_m1_l0_1[20:0])));
    quo_l2_1    = 25'(otf_quo   (blk_quo_dig[1][1], 56'(quo_l1_1), 56'(quo_m1_l1_1)));
    quo_m1_l2_1 = 25'(otf_quo_m1(blk_quo_dig[1][1], 56'(quo_l1_1), 56'(quo_m1_l1_1)));
    // f16 通道
    quo_l0_2    = 14'(otf_quo   (prev_quo_dig_q_f16_2, 56'(quo_iter_q_f16_2), 56'(quo_m1_iter_q_f16_2)));
    quo_m1_l0_2 = 14'(otf_quo_m1(prev_quo_dig_q_f16_2, 56'(quo_iter_q_f16_2), 56'(quo_m1_iter_q_f16_2)));
    quo_l1_2    = 10'(otf_quo   (blk_quo_dig[2][0], 56'(quo_l0_2[7:0]), 56'(quo_m1_l0_2[7:0])));
    quo_m1_l1_2 = 10'(otf_quo_m1(blk_quo_dig[2][0], 56'(quo_l0_2[7:0]), 56'(quo_m1_l0_2[7:0])));
    quo_l2_2    = 12'(otf_quo   (blk_quo_dig[2][1], 56'(quo_l1_2), 56'(quo_m1_l1_2)));
    quo_m1_l2_2 = 12'(otf_quo_m1(blk_quo_dig[2][1], 56'(quo_l1_2), 56'(quo_m1_l1_2)));
    quo_l0_3    = 14'(otf_quo   (prev_quo_dig_q_f16_3, 56'(quo_iter_q_f16_3), 56'(quo_m1_iter_q_f16_3)));
    quo_m1_l0_3 = 14'(otf_quo_m1(prev_quo_dig_q_f16_3, 56'(quo_iter_q_f16_3), 56'(quo_m1_iter_q_f16_3)));
    quo_l1_3    = 10'(otf_quo   (blk_quo_dig[3][0], 56'(quo_l0_3[7:0]), 56'(quo_m1_l0_3[7:0])));
    quo_m1_l1_3 = 10'(otf_quo_m1(blk_quo_dig[3][0], 56'(quo_l0_3[7:0]), 56'(quo_m1_l0_3[7:0])));
    quo_l2_3    = 12'(otf_quo   (blk_quo_dig[3][1], 56'(quo_l1_3), 56'(quo_m1_l1_3)));
    quo_m1_l2_3 = 12'(otf_quo_m1(blk_quo_dig[3][1], 56'(quo_l1_3), 56'(quo_m1_l1_3)));
  end

  // ===========================================================================
  // §9 收尾：最终余数 → 选 Q 还是 Q−1 → 非规格数右移 → 舍入
  // ===========================================================================
  // 9.1 各通道的最终余数（从打包向量按格式取出）与它的符号、是否为 0
  logic [59:0] rem_s_0, rem_c_0, rem_sum_0;
  logic [30:0] rem_s_1, rem_c_1, rem_sum_1;
  logic [17:0] rem_s_2, rem_c_2, rem_sum_2, rem_s_3, rem_c_3, rem_sum_3;
  logic [3:0]  rem_is_not_zero, select_quo_m1;
  always_comb begin
    rem_s_0 = {60{fmt64_q}} & f_r_s_q_72bit[71:12] | {60{fmt32_q}} & {f_r_s_q_72bit[35:5], 29'b0} | {60{fmt16_q}} & {f_r_s_q_72bit[17:0], 42'b0};
    rem_c_0 = {60{fmt64_q}} & f_r_c_q_72bit[71:12] | {60{fmt32_q}} & {f_r_c_q_72bit[35:5], 29'b0} | {60{fmt16_q}} & {f_r_c_q_72bit[17:0], 42'b0};
    rem_s_1 = fmt32_q ? f_r_s_q_72bit[71:41] : {f_r_s_q_72bit[35:18], 13'b0};
    rem_c_1 = fmt32_q ? f_r_c_q_72bit[71:41] : {f_r_c_q_72bit[35:18], 13'b0};
    rem_s_2 = f_r_s_q_72bit[53:36];  rem_c_2 = f_r_c_q_72bit[53:36];
    rem_s_3 = f_r_s_q_72bit[71:54];  rem_c_3 = f_r_c_q_72bit[71:54];
    rem_sum_0 = rem_s_0 + rem_c_0;
    rem_sum_1 = rem_s_1 + rem_c_1;
    rem_sum_2 = rem_s_2 + rem_c_2;
    rem_sum_3 = rem_s_3 + rem_c_3;
    // 余数非零：和为负，或 s+c 不全零（不做加法的零检测：s+c==0 ⇔ (s^c)>>1 == (s|c) 的低位）
    rem_is_not_zero[0] = ~opb_is_power_of_2_q[0] & (rem_sum_0[59] | (rem_s_0[58:1] ^ rem_c_0[58:1]) != (rem_s_0[57:0] | rem_c_0[57:0]));
    rem_is_not_zero[1] = ~opb_is_power_of_2_q[1] & (rem_sum_1[30] | (rem_s_1[29:1] ^ rem_c_1[29:1]) != (rem_s_1[28:0] | rem_c_1[28:0]));
    rem_is_not_zero[2] = ~opb_is_power_of_2_q[2] & (rem_sum_2[17] | (rem_s_2[16:1] ^ rem_c_2[16:1]) != (rem_s_2[15:0] | rem_c_2[15:0]));
    rem_is_not_zero[3] = ~opb_is_power_of_2_q[3] & (rem_sum_3[17] | (rem_s_3[16:1] ^ rem_c_3[16:1]) != (rem_s_3[15:0] | rem_c_3[15:0]));
    // 余数为负 ⇒ 真商是 Q−1
    select_quo_m1 = {rem_sum_3[17], rem_sum_2[17], rem_sum_1[30], rem_sum_0[59]} & ~opb_is_power_of_2_q;
  end

  // 9.2 移位前的商（Q 与 Q−1，末位是舍入位）。除数是 2 的幂时商就是寄存器里的被除数尾数。
  //   通道 0/1 装 f32/f16 时迭代多出的低位不属于本元素：f32 格式取 [24:0]，否则取 [25:1]
  logic [53:0] quo_pre_shift_0, quo_m1_pre_shift_0;
  logic [24:0] quo_pre_shift_1, quo_m1_pre_shift_1;
  logic [12:0] quo_pre_shift_2, quo_m1_pre_shift_2, quo_pre_shift_3, quo_m1_pre_shift_3;
  always_comb begin
    quo_m1_pre_shift_0 = {quo_m1_l0_0[54:26], fmt32_q ? quo_m1_l0_0[24:0] : quo_m1_l0_0[25:1]};
    quo_pre_shift_0    = opb_is_power_of_2_q[0] ? {quo_iter_q_f64_0[52:0], 1'b0}
                                                : {quo_l0_0[54:26], fmt32_q ? quo_l0_0[24:0] : quo_l0_0[25:1]};
    quo_m1_pre_shift_1 = fmt32_q ? quo_m1_l0_1[24:0] : quo_m1_l0_1[25:1];
    quo_pre_shift_1    = opb_is_power_of_2_q[1] ? {quo_iter_q_f32_1[23:0], 1'b0}
                                                : (fmt32_q ? quo_l0_1[24:0] : quo_l0_1[25:1]);
    quo_m1_pre_shift_2 = quo_m1_l0_2[13:1];
    quo_pre_shift_2    = opb_is_power_of_2_q[2] ? {1'b0, quo_iter_q_f16_2[10:0], 1'b0} : quo_l0_2[13:1];
    quo_m1_pre_shift_3 = quo_m1_l0_3[13:1];
    quo_pre_shift_3    = opb_is_power_of_2_q[3] ? {1'b0, quo_iter_q_f16_3[10:0], 1'b0} : quo_l0_3[13:1];
  end

  // 9.3 非规格数右移：移位量封顶 limit（f64 54 / f32 25 / f16 13；通道 0 的 limit 按格式 Mux1H）
  logic [12:0] rsh_t_0, rsh_tl_0;   logic [9:0] rsh_t_1, rsh_tl_1;
  logic [6:0]  rsh_t_2, rsh_tl_2, rsh_t_3, rsh_tl_3;
  logic [5:0]  rsh_limit_0, rsh_limit_1;
  logic [5:0]  rsh_0, rsh_1, rsh_2, rsh_3;
  always_comb begin
    rsh_limit_0 = (fmt64_q ? 6'd54 : 6'd0) | (fmt32_q ? 6'd25 : 6'd0) | (fmt16_q ? 6'd13 : 6'd0);
    rsh_limit_1 = fmt32_q ? 6'd25 : 6'd13;
    rsh_t_0  = 13'd1 - out_exp_diff_q_f64_0;  rsh_tl_0 = rsh_t_0 - 13'(rsh_limit_0);
    rsh_t_1  = 10'd1 - out_exp_diff_q_f32_1;  rsh_tl_1 = rsh_t_1 - 10'(rsh_limit_1);
    rsh_t_2  = 7'd1 - out_exp_diff_q_f16_2;   rsh_tl_2 = rsh_t_2 - 7'd13;
    rsh_t_3  = 7'd1 - out_exp_diff_q_f16_3;   rsh_tl_3 = rsh_t_3 - 7'd13;
    rsh_0 = denorm_shift(rsh_t_0[12], rsh_tl_0[12], rsh_t_0[5:0],       rsh_limit_0);
    rsh_1 = denorm_shift(rsh_t_1[9],  rsh_tl_1[9],  6'(rsh_t_1[4:0]),   rsh_limit_1);
    rsh_2 = denorm_shift(rsh_t_2[6],  rsh_tl_2[6],  6'(rsh_t_2[3:0]),   6'd13);
    rsh_3 = denorm_shift(rsh_t_3[6],  rsh_tl_3[6],  6'(rsh_t_3[3:0]),   6'd13);
  end
  logic [107:0] quo_rsh_0, quo_m1_rsh_0;
  logic [49:0]  quo_rsh_1, quo_m1_rsh_1;
  logic [25:0]  quo_rsh_2, quo_m1_rsh_2, quo_rsh_3, quo_m1_rsh_3;
  assign quo_rsh_0    = {quo_pre_shift_0,    54'b0} >> rsh_0;
  assign quo_m1_rsh_0 = {quo_m1_pre_shift_0, 54'b0} >> rsh_0;
  assign quo_rsh_1    = {quo_pre_shift_1,    25'b0} >> rsh_1;
  assign quo_m1_rsh_1 = {quo_m1_pre_shift_1, 25'b0} >> rsh_1;
  assign quo_rsh_2    = {quo_pre_shift_2,    13'b0} >> rsh_2;
  assign quo_m1_rsh_2 = {quo_m1_pre_shift_2, 13'b0} >> rsh_2;
  assign quo_rsh_3    = {quo_pre_shift_3,    13'b0} >> rsh_3;
  assign quo_m1_rsh_3 = {quo_m1_pre_shift_3, 13'b0} >> rsh_3;

  // 右移后的正确商（按余数符号选 Q / Q−1），和移出去的那些位（POST_1 的粘滞位来源）
  logic [52:0] corr_quo_0;  logic [23:0] corr_quo_1;  logic [10:0] corr_quo_2, corr_quo_3;
  logic [53:0] sticky_without_rem_0;  logic [24:0] sticky_without_rem_1;
  logic [12:0] sticky_without_rem_2, sticky_without_rem_3;
  always_comb begin
    corr_quo_0 = select_quo_m1[0] ? quo_m1_rsh_0[106:54] : quo_rsh_0[106:54];
    corr_quo_1 = select_quo_m1[1] ? quo_m1_rsh_1[48:25]  : quo_rsh_1[48:25];
    corr_quo_2 = select_quo_m1[2] ? quo_m1_rsh_2[23:13]  : quo_rsh_2[23:13];
    corr_quo_3 = select_quo_m1[3] ? quo_m1_rsh_3[23:13]  : quo_rsh_3[23:13];
    sticky_without_rem_0 = select_quo_m1[0] ? quo_m1_rsh_0[53:0] : quo_rsh_0[53:0];
    sticky_without_rem_1 = select_quo_m1[1] ? quo_m1_rsh_1[24:0] : quo_rsh_1[24:0];
    sticky_without_rem_2 = select_quo_m1[2] ? quo_m1_rsh_2[12:0] : quo_rsh_2[12:0];
    sticky_without_rem_3 = select_quo_m1[3] ? quo_m1_rsh_3[12:0] : quo_rsh_3[12:0];
  end

  // 9.4 舍入。POST_0（或规格数）：对本拍的 Q 舍入；POST_1 的非规格数：对 Q−1 寄存器里暂存的
  //   右移后的商舍入（舍入位 / 粘滞位取寄存器里的低位与 frac_divisor 暂存的粘滞位）。
  //   通道 0/1 装窄格式时，把不属于本元素的那一位（f32 下 bit24、f16 下 bit11）掩掉。
  logic        post0_or_normal [4];
  logic [51:0] quo_pre_inc_0;  logic [22:0] quo_pre_inc_1;  logic [9:0] quo_pre_inc_2, quo_pre_inc_3;
  logic [52:0] quo_inc_0;      logic [23:0] quo_inc_1;      logic [10:0] quo_inc_2, quo_inc_3;
  logic [3:0]  rnd_lsb, rnd_bit, rnd_sticky, inexact_quo, quo_need_rup;
  always_comb begin
    for (int l = 0; l < 4; l++) post0_or_normal[l] = fsm_q[POST_0] | ~res_is_denormal[l];
    quo_pre_inc_0 = fsm_q[POST_0]
      ? {quo_pre_shift_0[52:25], ~fmt32_q & quo_pre_shift_0[24], quo_pre_shift_0[23:12], ~fmt16_q & quo_pre_shift_0[11], quo_pre_shift_0[10:1]}
      : {quo_m1_iter_q_f64_0[52:25], ~fmt32_q & quo_m1_iter_q_f64_0[24], quo_m1_iter_q_f64_0[23:12],
         ~fmt16_q & quo_m1_iter_q_f64_0[11], quo_m1_iter_q_f64_0[10:1]};
    quo_pre_inc_1 = fsm_q[POST_0]
      ? {quo_pre_shift_1[23:12], ~fmt16_q & quo_pre_shift_1[11], quo_pre_shift_1[10:1]}
      : {quo_m1_iter_q_f32_1[23:12], ~fmt16_q & quo_m1_iter_q_f32_1[11], quo_m1_iter_q_f32_1[10:1]};
    quo_pre_inc_2 = fsm_q[POST_0] ? quo_pre_shift_2[10:1] : quo_m1_iter_q_f16_2[10:1];
    quo_pre_inc_3 = fsm_q[POST_0] ? quo_pre_shift_3[10:1] : quo_m1_iter_q_f16_3[10:1];
    quo_inc_0 = {1'b0, quo_pre_inc_0} + 53'd1;
    quo_inc_1 = {1'b0, quo_pre_inc_1} + 24'd1;
    quo_inc_2 = {1'b0, quo_pre_inc_2} + 11'd1;
    quo_inc_3 = {1'b0, quo_pre_inc_3} + 11'd1;
    rnd_lsb = {post0_or_normal[3] ? quo_pre_shift_3[1] : quo_m1_iter_q_f16_3[1],
               post0_or_normal[2] ? quo_pre_shift_2[1] : quo_m1_iter_q_f16_2[1],
               post0_or_normal[1] ? quo_pre_shift_1[1] : quo_m1_iter_q_f32_1[1],
               post0_or_normal[0] ? quo_pre_shift_0[1] : quo_m1_iter_q_f64_0[1]};
    rnd_bit = {post0_or_normal[3] ? quo_pre_shift_3[0] : quo_m1_iter_q_f16_3[0],
               post0_or_normal[2] ? quo_pre_shift_2[0] : quo_m1_iter_q_f16_2[0],
               post0_or_normal[1] ? quo_pre_shift_1[0] : quo_m1_iter_q_f32_1[0],
               post0_or_normal[0] ? quo_pre_shift_0[0] : quo_m1_iter_q_f64_0[0]};
    rnd_sticky = {post0_or_normal[3] ? rem_is_not_zero[3] : quo_m1_iter_q_f16_3[11] | (|frac_divisor_q_f16_3),
                  post0_or_normal[2] ? rem_is_not_zero[2] : quo_m1_iter_q_f16_2[11] | (|frac_divisor_q_f16_2),
                  post0_or_normal[1] ? rem_is_not_zero[1] : quo_m1_iter_q_f32_1[24] | (|frac_divisor_q_f32_1[24:0]),
                  post0_or_normal[0] ? rem_is_not_zero[0] : quo_m1_iter_q_f64_0[53] | (|frac_divisor_q_f64_0)};
    inexact_quo = rnd_bit | rnd_sticky;
    for (int l = 0; l < 4; l++)
      quo_need_rup[l] = need_round_up(rm_q, out_sign_q[l], rnd_lsb[l], rnd_bit[l], rnd_sticky[l]);
  end
  logic [52:0] quo_rounded_0;  logic [23:0] quo_rounded_1;  logic [10:0] quo_rounded_2, quo_rounded_3;
  assign quo_rounded_0 = quo_need_rup[0] ? quo_inc_0 : {1'b0, quo_pre_inc_0};
  assign quo_rounded_1 = quo_need_rup[1] ? quo_inc_1 : {1'b0, quo_pre_inc_1};
  assign quo_rounded_2 = quo_need_rup[2] ? quo_inc_2 : {1'b0, quo_pre_inc_2};
  assign quo_rounded_3 = quo_need_rup[3] ? quo_inc_3 : {1'b0, quo_pre_inc_3};

  logic [3:0] inexact;      // 含"选了 Q−1"（余数为负必非精确）
  always_comb
    for (int l = 0; l < 4; l++) inexact[l] = post0_or_normal[l] & select_quo_m1[l] | inexact_quo[l];

  // 9.5 规格数（POST_0）选 Q−1 时的舍入：Q−1 的舍入位/末位来自 Q−1 自己；进位后的值可以借用 Q 的
  //   +1 结果（Q−1 进位 = Q 本身或 Q+1，取决于两者末位是否相同），不再另做一次加法。
  //   粘滞位恒为 1（余数非零），所以 need_round_up 的 stk 传 1。
  logic [51:0] frac_rounded_0;  logic [22:0] frac_rounded_1;  logic [9:0] frac_rounded_2, frac_rounded_3;
  always_comb begin
    frac_rounded_0 = !select_quo_m1[0] ? quo_rounded_0[51:0]
      : need_round_up(rm_q, out_sign_q[0], quo_m1_pre_shift_0[1], quo_m1_pre_shift_0[0], 1'b1)
        ? (quo_pre_inc_0[0] == quo_m1_pre_shift_0[1] ? quo_inc_0[51:0] : quo_pre_inc_0)
        : {quo_m1_l0_0[53:26], ~fmt32_q & quo_m1_pre_shift_0[24], quo_m1_pre_shift_0[23:12],
           ~fmt16_q & quo_m1_pre_shift_0[11], quo_m1_pre_shift_0[10:1]};
    frac_rounded_1 = !select_quo_m1[1] ? quo_rounded_1[22:0]
      : need_round_up(rm_q, out_sign_q[1], quo_m1_pre_shift_1[1], quo_m1_pre_shift_1[0], 1'b1)
        ? (quo_pre_inc_1[0] == quo_m1_pre_shift_1[1] ? quo_inc_1[22:0] : quo_pre_inc_1)
        : {quo_m1_pre_shift_1[23:12], ~fmt16_q & quo_m1_pre_shift_1[11], quo_m1_pre_shift_1[10:1]};
    frac_rounded_2 = !select_quo_m1[2] ? quo_rounded_2[9:0]
      : need_round_up(rm_q, out_sign_q[2], quo_m1_pre_shift_2[1], quo_m1_pre_shift_2[0], 1'b1)
        ? (quo_pre_inc_2[0] == quo_m1_pre_shift_2[1] ? quo_inc_2[9:0] : quo_pre_inc_2)
        : quo_m1_pre_shift_2[10:1];
    frac_rounded_3 = !select_quo_m1[3] ? quo_rounded_3[9:0]
      : need_round_up(rm_q, out_sign_q[3], quo_m1_pre_shift_3[1], quo_m1_pre_shift_3[0], 1'b1)
        ? (quo_pre_inc_3[0] == quo_m1_pre_shift_3[1] ? quo_inc_3[9:0] : quo_pre_inc_3)
        : quo_m1_pre_shift_3[10:1];
  end

  // 9.6 非规格数舍入后进位到最小规格数（指数变 1）
  logic [3:0] carry_after_round;
  assign carry_after_round = {quo_rounded_3[10], quo_rounded_2[10],
                              fmt16_q ? quo_rounded_1[10] : quo_rounded_1[23],
                              fmt16_q ? quo_rounded_0[10] : fmt32_q ? quo_rounded_0[23] : quo_rounded_0[52]};

  // ===========================================================================
  // §10 上溢与 POST_0 的结果（规格数）
  //   上溢：指数差 ≥ 格式的全 1 指数（通道 0 只比低 12 位）。上溢时按舍入模式给 ∞ 或最大有限数。
  // ===========================================================================
  logic [3:0] overflow, ovf_inf, ovf_max;
  always_comb begin
    overflow[0] = out_exp_diff_q_f64_0[11:0] >= (fmt16_q ? 12'h1F : fmt32_q ? 12'hFF : 12'h7FF);
    overflow[1] = out_exp_diff_q_f32_1 >= (fmt16_q ? 10'h1F : 10'hFF);
    overflow[2] = out_exp_diff_q_f16_2 > 7'h1E;
    overflow[3] = out_exp_diff_q_f16_3 > 7'h1E;
    for (int l = 0; l < 4; l++) begin
      ovf_inf[l] = overflow[l] & overflow_goes_inf(rm_q, out_sign_q[l]);
      ovf_max[l] = overflow[l] & ~overflow_goes_inf(rm_q, out_sign_q[l]);
    end
  end

  // POST_0 各元素的指数/尾数（通道 0 按 f16/f32/f64 三种宽度各给一份，通道 1 按 f16/f32 两份）
  logic [4:0]  post0_exp_f16_0, post0_exp_f16_1, post0_exp_f16_2, post0_exp_f16_3;
  logic [7:0]  post0_exp_f32_0, post0_exp_f32_1;
  logic [10:0] post0_exp_f64_0;
  logic [9:0]  post0_frac_f16_0, post0_frac_f16_1, post0_frac_f16_2, post0_frac_f16_3;
  logic [22:0] post0_frac_f32_0, post0_frac_f32_1;
  logic [51:0] post0_frac_f64_0;
  always_comb begin
    post0_exp_f16_0  = ovf_inf[0] ? 5'h1F  : ovf_max[0] ? 5'h1E  : out_exp_diff_q_f64_0[4:0];
    post0_exp_f32_0  = ovf_inf[0] ? 8'hFF  : ovf_max[0] ? 8'hFE  : out_exp_diff_q_f64_0[7:0];
    post0_exp_f64_0  = ovf_inf[0] ? 11'h7FF : ovf_max[0] ? 11'h7FE : out_exp_diff_q_f64_0[10:0];
    post0_exp_f16_1  = ovf_inf[1] ? 5'h1F  : ovf_max[1] ? 5'h1E  : out_exp_diff_q_f32_1[4:0];
    post0_exp_f32_1  = ovf_inf[1] ? 8'hFF  : ovf_max[1] ? 8'hFE  : out_exp_diff_q_f32_1[7:0];
    post0_exp_f16_2  = ovf_inf[2] ? 5'h1F  : ovf_max[2] ? 5'h1E  : out_exp_diff_q_f16_2[4:0];
    post0_exp_f16_3  = ovf_inf[3] ? 5'h1F  : ovf_max[3] ? 5'h1E  : out_exp_diff_q_f16_3[4:0];
    post0_frac_f16_0 = ovf_inf[0] ? '0 : ovf_max[0] ? '1 : frac_rounded_0[9:0];
    post0_frac_f32_0 = ovf_inf[0] ? '0 : ovf_max[0] ? '1 : frac_rounded_0[22:0];
    post0_frac_f64_0 = ovf_inf[0] ? '0 : ovf_max[0] ? '1 : frac_rounded_0;
    post0_frac_f16_1 = ovf_inf[1] ? '0 : ovf_max[1] ? '1 : frac_rounded_1[9:0];
    post0_frac_f32_1 = ovf_inf[1] ? '0 : ovf_max[1] ? '1 : frac_rounded_1;
    post0_frac_f16_2 = ovf_inf[2] ? '0 : ovf_max[2] ? '1 : frac_rounded_2;
    post0_frac_f16_3 = ovf_inf[3] ? '0 : ovf_max[3] ? '1 : frac_rounded_3;
  end

  // ===========================================================================
  // §11 POST_1 的结果：特殊值（NaN / ∞ / 精确 0）与非规格数在这里给出，规格数照搬 POST_0 存进
  //   quo_m1_iter 的尾数（指数仍由 POST_0 的通路给）
  // ===========================================================================
  logic [3:0] post1_special;
  assign post1_special = res_is_denormal | res_is_nan_q | res_is_inf_q | res_is_exact_zero_q;

  // 特殊值/非规格数的指数：NaN/∞ 全 1，精确 0 为 0，非规格数为舍入进位（0 或 1）
  function automatic logic [10:0] post1_exp(input logic nan, input logic inf, input logic zero,
                                            input logic carry, input logic [10:0] all_ones);
    post1_exp = (nan | inf) ? all_ones : zero ? 11'd0 : 11'(carry);
  endfunction
  // 特殊值/非规格数的尾数：NaN 给 quiet 位，∞/0 给 0，非规格数给舍入后的商
  function automatic logic [51:0] post1_frac(input logic nan, input logic inf_or_zero,
                                             input logic [51:0] quiet, input logic [51:0] rounded);
    post1_frac = nan ? quiet : inf_or_zero ? 52'd0 : rounded;
  endfunction

  logic [4:0]  post1_exp_f16_0, post1_exp_f16_1, post1_exp_f16_2, post1_exp_f16_3;
  logic [7:0]  post1_exp_f32_0, post1_exp_f32_1;
  logic [10:0] post1_exp_f64_0;
  logic [9:0]  post1_frac_f16_0, post1_frac_f16_1, post1_frac_f16_2, post1_frac_f16_3;
  logic [22:0] post1_frac_f32_0, post1_frac_f32_1;
  logic [51:0] post1_frac_f64_0;
  always_comb begin
    post1_exp_f16_0 = post1_special[0] ? 5'(post1_exp(res_is_nan_q[0], res_is_inf_q[0], res_is_exact_zero_q[0], carry_after_round[0], 11'h1F))  : post0_exp_f16_0;
    post1_exp_f32_0 = post1_special[0] ? 8'(post1_exp(res_is_nan_q[0], res_is_inf_q[0], res_is_exact_zero_q[0], carry_after_round[0], 11'hFF))  : post0_exp_f32_0;
    post1_exp_f64_0 = post1_special[0] ?    post1_exp(res_is_nan_q[0], res_is_inf_q[0], res_is_exact_zero_q[0], carry_after_round[0], 11'h7FF) : post0_exp_f64_0;
    post1_exp_f16_1 = post1_special[1] ? 5'(post1_exp(res_is_nan_q[1], res_is_inf_q[1], res_is_exact_zero_q[1], carry_after_round[1], 11'h1F))  : post0_exp_f16_1;
    post1_exp_f32_1 = post1_special[1] ? 8'(post1_exp(res_is_nan_q[1], res_is_inf_q[1], res_is_exact_zero_q[1], carry_after_round[1], 11'hFF))  : post0_exp_f32_1;
    post1_exp_f16_2 = post1_special[2] ? 5'(post1_exp(res_is_nan_q[2], res_is_inf_q[2], res_is_exact_zero_q[2], carry_after_round[2], 11'h1F))  : post0_exp_f16_2;
    post1_exp_f16_3 = post1_special[3] ? 5'(post1_exp(res_is_nan_q[3], res_is_inf_q[3], res_is_exact_zero_q[3], carry_after_round[3], 11'h1F))  : post0_exp_f16_3;
    post1_frac_f16_0 = post1_special[0] ? 10'(post1_frac(res_is_nan_q[0], res_is_inf_q[0] | res_is_exact_zero_q[0], 52'h200, 52'(quo_rounded_0[9:0])))
                                        : quo_m1_iter_q_f64_0[9:0];
    post1_frac_f32_0 = post1_special[0] ? 23'(post1_frac(res_is_nan_q[0], res_is_inf_q[0] | res_is_exact_zero_q[0], 52'h400000, 52'(quo_rounded_0[22:0])))
                                        : quo_m1_iter_q_f64_0[22:0];
    post1_frac_f64_0 = post1_special[0] ? post1_frac(res_is_nan_q[0], res_is_inf_q[0] | res_is_exact_zero_q[0], 52'h8000000000000, quo_rounded_0[51:0])
                                        : quo_m1_iter_q_f64_0[51:0];
    post1_frac_f16_1 = post1_special[1] ? 10'(post1_frac(res_is_nan_q[1], res_is_inf_q[1] | res_is_exact_zero_q[1], 52'h200, 52'(quo_rounded_1[9:0])))
                                        : quo_m1_iter_q_f32_1[9:0];
    post1_frac_f32_1 = post1_special[1] ? 23'(post1_frac(res_is_nan_q[1], res_is_inf_q[1] | res_is_exact_zero_q[1], 52'h400000, 52'(quo_rounded_1[22:0])))
                                        : quo_m1_iter_q_f32_1[22:0];
    post1_frac_f16_2 = post1_special[2] ? 10'(post1_frac(res_is_nan_q[2], res_is_inf_q[2] | res_is_exact_zero_q[2], 52'h200, 52'(quo_rounded_2[9:0])))
                                        : quo_m1_iter_q_f16_2[9:0];
    post1_frac_f16_3 = post1_special[3] ? 10'(post1_frac(res_is_nan_q[3], res_is_inf_q[3] | res_is_exact_zero_q[3], 52'h200, 52'(quo_rounded_3[9:0])))
                                        : quo_m1_iter_q_f16_3[9:0];
  end

  // ===========================================================================
  // §12 商寄存器与除数寄存器的写入（各状态项按位或，见文件头"怪癖"）
  // ===========================================================================
  logic quo_iter_en;
  assign quo_iter_en = start_hs | fsm_q[PRE_1] | fsm_q[PRE_2] | fsm_q[ITER];

  // PRE_0 装入 Q 的被除数尾数 1.frac。f64 通道在除数尾数全 0（2 的幂）时按格式只保留本元素的位；
  //   f32 通道在除数尾数全 0 且两边都不是非规格数时直接取操作数元素（不经左规）。
  logic [53:0] quo_init_0;  logic [24:0] quo_init_1;  logic [11:0] quo_init_2, quo_init_3;
  always_comb begin
    quo_init_0 = (~b_frac_zero[0] | in_f64) ? {2'b01, a_norm_0}
               : in_f32 ? {31'd1, a_norm_0[51:29]} : {44'd1, a_norm_0[51:42]};
    quo_init_1 = (~b_frac_zero[1] | a_exp_zero[1] | b_exp_zero[1])
               ? ((b_frac_zero[1] & (a_exp_zero[1] | b_exp_zero[1]) & in_f16) ? {15'd1, a_norm_1[22:13]} : {2'b01, a_norm_1})
               : (in_f32 ? {2'b01, opa[54:32]} : {15'd1, opa[25:16]});
    quo_init_2 = {2'b01, ((~b_frac_zero[2] | a_exp_zero[2] | b_exp_zero[2]) & a_exp_zero[2]) ? a_lsh_2[9:0] : a_frac_2};
    quo_init_3 = {2'b01, ((~b_frac_zero[3] | a_exp_zero[3] | b_exp_zero[3]) & a_exp_zero[3]) ? a_lsh_3[9:0] : a_frac_3};
  end

  always_ff @(posedge clock) begin
    if (quo_iter_en & (start_hs | ~opb_is_power_of_2_q[0]))
      quo_iter_q_f64_0 <= {54{fsm_q[PRE_0]}} & quo_init_0 | {54{fsm_q[PRE_1]}} & scaled_a_0[53:0] | {54{fsm_q[ITER]}} & quo_l2_0;
    if (quo_iter_en & (start_hs | ~opb_is_power_of_2_q[1]))
      quo_iter_q_f32_1 <= {25{fsm_q[PRE_0]}} & quo_init_1 | {25{fsm_q[PRE_1]}} & scaled_a_1[24:0] | {25{fsm_q[ITER]}} & quo_l2_1;
    if (quo_iter_en & (start_hs | ~opb_is_power_of_2_q[2]))
      quo_iter_q_f16_2 <= {12{fsm_q[PRE_0]}} & quo_init_2 | {12{fsm_q[PRE_1]}} & scaled_a_2[11:0] | {12{fsm_q[ITER]}} & quo_l2_2;
    if (quo_iter_en & (start_hs | ~opb_is_power_of_2_q[3]))
      quo_iter_q_f16_3 <= {12{fsm_q[PRE_0]}} & quo_init_3 | {12{fsm_q[PRE_1]}} & scaled_a_3[11:0] | {12{fsm_q[ITER]}} & quo_l2_3;
  end

  // POST_0 写回 Q−1：非规格数存 {余数非零, 右移后的正确商}，规格数存舍入后的尾数（通道 0/1 按格式）
  logic [53:0] quo_m1_post0_0;  logic [24:0] quo_m1_post0_1;  logic [11:0] quo_m1_post0_2, quo_m1_post0_3;
  always_comb begin
    quo_m1_post0_0 = res_is_denormal[0] ? {rem_is_not_zero[0], corr_quo_0}
                   : {2'b0, fmt64_q ? post0_frac_f64_0 : fmt32_q ? {29'b0, post0_frac_f32_0} : {42'b0, post0_frac_f16_0}};
    quo_m1_post0_1 = res_is_denormal[1] ? {rem_is_not_zero[1], corr_quo_1}
                   : {2'b0, fmt32_q ? post0_frac_f32_1 : {13'b0, post0_frac_f16_1}};
    quo_m1_post0_2 = res_is_denormal[2] ? {rem_is_not_zero[2], corr_quo_2} : {2'b0, post0_frac_f16_2};
    quo_m1_post0_3 = res_is_denormal[3] ? {rem_is_not_zero[3], corr_quo_3} : {2'b0, post0_frac_f16_3};
  end

  always_ff @(posedge clock) begin
    if (start_hs | fsm_q[PRE_1] | fsm_q[ITER] | fsm_q[POST_0]) begin
      quo_m1_iter_q_f64_0 <= {54{fsm_q[PRE_0]}}  & {2'b01, b_norm_0}
                           | {54{fsm_q[PRE_1]}}  & {51'b0, scaled_a_0[56:54]}
                           | {54{fsm_q[ITER]}}   & quo_m1_l2_0
                           | {54{fsm_q[POST_0]}} & quo_m1_post0_0;
      quo_m1_iter_q_f32_1 <= {25{fsm_q[PRE_0]}}  & {2'b01, b_norm_1}
                           | {25{fsm_q[PRE_1]}}  & {22'b0, scaled_a_1[27:25]}
                           | {25{fsm_q[ITER]}}   & quo_m1_l2_1
                           | {25{fsm_q[POST_0]}} & quo_m1_post0_1;
      quo_m1_iter_q_f16_2 <= {12{fsm_q[PRE_0]}}  & {2'b01, b_norm_2}
                           | {12{fsm_q[PRE_1]}}  & {9'b0, scaled_a_2[14:12]}
                           | {12{fsm_q[ITER]}}   & quo_m1_l2_2
                           | {12{fsm_q[POST_0]}} & quo_m1_post0_2;
      quo_m1_iter_q_f16_3 <= {12{fsm_q[PRE_0]}}  & {2'b01, b_norm_3}
                           | {12{fsm_q[PRE_1]}}  & {9'b0, scaled_a_3[14:12]}
                           | {12{fsm_q[ITER]}}   & quo_m1_l2_3
                           | {12{fsm_q[POST_0]}} & quo_m1_post0_3;
    end
  end

  // 除数寄存器：PRE_1 写缩放后的除数；POST_0 的非规格数写右移移出的粘滞位（规格数保持）
  logic [56:0] divisor_next_0;  logic [27:0] divisor_next_1;  logic [14:0] divisor_next_2, divisor_next_3;
  always_comb begin
    divisor_next_0 = (fsm_q[POST_0] & ~res_is_denormal[0]) ? frac_divisor_q_f64_0
                   : {57{fsm_q[PRE_0]}} & frac_divisor_q_f64_0 | {57{fsm_q[PRE_1]}} & scaled_b_0
                   | {57{fsm_q[PRE_2]}} & frac_divisor_q_f64_0 | {57{fsm_q[POST_0]}} & {3'b0, sticky_without_rem_0};
    divisor_next_1 = (fsm_q[POST_0] & ~res_is_denormal[1]) ? frac_divisor_q_f32_1
                   : {28{fsm_q[PRE_0]}} & frac_divisor_q_f32_1 | {28{fsm_q[PRE_1]}} & scaled_b_1
                   | {28{fsm_q[PRE_2]}} & frac_divisor_q_f32_1 | {28{fsm_q[POST_0]}} & {3'b0, sticky_without_rem_1};
    divisor_next_2 = (fsm_q[POST_0] & ~res_is_denormal[2]) ? frac_divisor_q_f16_2
                   : {15{fsm_q[PRE_0]}} & frac_divisor_q_f16_2 | {15{fsm_q[PRE_1]}} & scaled_b_2
                   | {15{fsm_q[PRE_2]}} & frac_divisor_q_f16_2 | {15{fsm_q[POST_0]}} & {2'b0, sticky_without_rem_2};
    divisor_next_3 = (fsm_q[POST_0] & ~res_is_denormal[3]) ? frac_divisor_q_f16_3
                   : {15{fsm_q[PRE_0]}} & frac_divisor_q_f16_3 | {15{fsm_q[PRE_1]}} & scaled_b_3
                   | {15{fsm_q[PRE_2]}} & frac_divisor_q_f16_3 | {15{fsm_q[POST_0]}} & {2'b0, sticky_without_rem_3};
  end
  // 打包：收数拍按输入格式、其余拍按锁存的格式
  always_ff @(posedge clock) begin
    if (start_hs | fsm_q[PRE_1] | fsm_q[PRE_2] | fsm_q[POST_0]) begin
      if (start_hs & in_f64 | ~start_hs & fmt64_q)
        frac_divisor_q_60bit <= {divisor_next_0, 3'b0};
      else if (start_hs & in_f32 | ~start_hs & fmt32_q)
        frac_divisor_q_60bit <= {divisor_next_1, 2'b0, divisor_next_0[56:29], 2'b0};
      else
        frac_divisor_q_60bit <= {divisor_next_3, divisor_next_2, divisor_next_1[27:13], divisor_next_0[56:42]};
    end
  end

  // ===========================================================================
  // §13 输出：结果向量（POST_0 拍组合给出 POST_0 版本，其余拍给 POST_1 版本）与异常标志
  //   f64 格式位为 1 时按 f64 布局拼，但其中的 f32/f16 片段仍受另两位格式位影响（多热格式下可见）
  // ===========================================================================
  logic [63:0] res_post0, res_post1;
  always_comb begin
    res_post0 = fmt64_q
      ? {out_sign_q[0], post0_exp_f64_0, post0_frac_f64_0[51:32],
         fmt32_q ? {out_sign_q[0], post0_exp_f32_0, post0_frac_f32_0[22:16]} : post0_frac_f64_0[31:16],
         fmt16_q ? {out_sign_q[0], post0_exp_f16_0, post0_frac_f16_0}
                 : fmt32_q ? post0_frac_f32_0[15:0] : post0_frac_f64_0[15:0]}
      : {64{fmt32_q}} & {out_sign_q[1], post0_exp_f32_1, post0_frac_f32_1, out_sign_q[0], post0_exp_f32_0, post0_frac_f32_0}
      | {64{fmt16_q}} & {out_sign_q[3], post0_exp_f16_3, post0_frac_f16_3, out_sign_q[2], post0_exp_f16_2, post0_frac_f16_2,
                         out_sign_q[1], post0_exp_f16_1, post0_frac_f16_1, out_sign_q[0], post0_exp_f16_0, post0_frac_f16_0};
    res_post1 = fmt64_q
      ? {out_sign_q[0], post1_exp_f64_0, post1_frac_f64_0[51:32],
         fmt32_q ? {out_sign_q[0], post1_exp_f32_0, post1_frac_f32_0[22:16]} : post1_frac_f64_0[31:16],
         fmt16_q ? {out_sign_q[0], post1_exp_f16_0, post1_frac_f16_0}
                 : fmt32_q ? post1_frac_f32_0[15:0] : post1_frac_f64_0[15:0]}
      : {64{fmt32_q}} & {out_sign_q[1], post1_exp_f32_1, post1_frac_f32_1, out_sign_q[0], post1_exp_f32_0, post1_frac_f32_0}
      | {64{fmt16_q}} & {out_sign_q[3], post1_exp_f16_3, post1_frac_f16_3, out_sign_q[2], post1_exp_f16_2, post1_frac_f16_2,
                         out_sign_q[1], post1_exp_f16_1, post1_frac_f16_1, out_sign_q[0], post1_exp_f16_0, post1_frac_f16_0};
  end
  assign fpdiv_res = fsm_q[POST_0] ? res_post0 : res_post1;

  // 异常标志（每元素）：NV、DZ 直接取 PRE_0 锁存值；OF 在 POST_0 拍或（POST_1 且规格数非特殊值）；
  //   UF 只在 POST_1 的非规格数上判：舍入后没进位到规格数，或"按无界指数先舍入"也进不上去（tininess after rounding）；
  //   NX = OF 或非精确，特殊值不报。
  logic [3:0] flag_of, flag_uf, flag_nx, sticky_correct, uf_round_lsb, uf_round_bit;
  logic [3:0] not_special;
  always_comb begin
    not_special = ~res_is_exact_zero_q & ~res_is_inf_q & ~res_is_nan_q;
    sticky_correct = {select_quo_m1[3] | (|sticky_without_rem_3[11:0]) | rem_is_not_zero[3],
                      select_quo_m1[2] | (|sticky_without_rem_2[11:0]) | rem_is_not_zero[2],
                      select_quo_m1[1] | (|sticky_without_rem_1[23:0]) | rem_is_not_zero[1],
                      select_quo_m1[0] | (|sticky_without_rem_0[52:0]) | rem_is_not_zero[0]};
    uf_round_lsb = {corr_quo_3[0], corr_quo_2[0], corr_quo_1[0], corr_quo_0[0]};
    uf_round_bit = {sticky_without_rem_3[12], sticky_without_rem_2[12], sticky_without_rem_1[24], sticky_without_rem_0[53]};
    for (int l = 0; l < 4; l++) begin
      flag_of[l] = fsm_q[POST_0] & overflow[l]
                 | fsm_q[POST_1] & ~res_is_denormal[l] & overflow[l] & not_special[l];
      flag_uf[l] = res_is_denormal[l] & fsm_q[POST_1]
                 & (~carry_after_round[l]
                    | ~(uf_round_lsb[l] & need_round_up(rm_q, out_sign_q[l], uf_round_lsb[l], uf_round_bit[l], sticky_correct[l])))
                 & inexact[l] & not_special[l];
      flag_nx[l] = (flag_of[l] | inexact[l]) & not_special[l];
    end
  end
  logic [3:0][4:0] lane_flags;
  always_comb
    for (int l = 0; l < 4; l++)
      lane_flags[l] = {op_invalid_div_q[l], divided_by_zero_q[l], flag_of[l], flag_uf[l], flag_nx[l]};
  assign fflags = {fmt16_q ? lane_flags[3] : 5'b0,
                   fmt16_q ? lane_flags[2] : 5'b0,
                   (fmt32_q | fmt16_q) ? lane_flags[1] : 5'b0,
                   lane_flags[0]};
endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper：端口逐位同名，直接连核
// -----------------------------------------------------------------------------
module VectorFloatDividerR64 (
  input  logic        clock,
  input  logic        reset,
  input  logic        io_start_valid_i,
  output logic        io_start_ready_o,
  input  logic        io_flush_i,
  input  logic [1:0]  io_fp_format_i,
  input  logic [63:0] io_opa_i,
  input  logic [63:0] io_opb_i,
  input  logic [2:0]  io_rm_i,
  output logic        io_finish_valid_o,
  input  logic        io_finish_ready_i,
  output logic [63:0] io_fpdiv_res_o,
  output logic [19:0] io_fflags_o
);
  xs_VectorFloatDividerR64_core u_core (
    .clock        (clock),
    .reset        (reset),
    .start_valid  (io_start_valid_i),
    .start_ready  (io_start_ready_o),
    .flush        (io_flush_i),
    .fp_format    (io_fp_format_i),
    .opa          (io_opa_i),
    .opb          (io_opb_i),
    .rm           (io_rm_i),
    .finish_valid (io_finish_valid_o),
    .finish_ready (io_finish_ready_i),
    .fpdiv_res    (io_fpdiv_res_o),
    .fflags       (io_fflags_o)
  );
endmodule
