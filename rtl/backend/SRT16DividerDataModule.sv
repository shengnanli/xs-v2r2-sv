// =============================================================================
// SRT16DividerDataModule —— 64 位整数除法器数据通路：radix-16 SRT（每拍两个 radix-4 商位）
//                           （DivUnit 的子模块，div/divu/rem/remu 及其 W 变体）
//
// 设计源：src/main/scala/xiangshan/backend/fu/SRT16Divider.scala（class SRT16DividerDataModule，
//         len = 64）。CSA3_2_* 与 RightShifter 子模块实例名同 golden，两侧白盒。
//
// 状态机（state 为 7 位独热；kill_r 任何时候回 idle）：
//   s_idle   → 收到 in_fire 且未被 kill_w：锁存 |a|、|d|、符号、原始 a。
//   s_pre_0  ：前导零计数 LZC(|a|)、LZC(|d|)，左移规格化成 aNorm/dNorm；
//              aTooSmall = LZC(d) < LZC(a)（|a| < |d|，商为 0）。
//   s_pre_1  ：特殊情况判定 special = d∈{0,±1}（LZC(d)==63）| d==0 | aTooSmall，直接给出
//              quotSpecial / remSpecial 并跳到 s_post_1；否则预算迭代所需的全部常量：
//              udNeg[q] = -q·d（q∈{-2,-1,0,+1,+2}，68 位），选择常数 -m_k（查表，按 dNorm 的
//              [62:60] 三位），rudPmNeg = -(r·q·d + m_k) 截位、r2udPmNeg = -(r²·q·d + m_k) 截位，
//              迭代次数 iterNum = (LZC 差 + 1) / 4，初始余数（LZC 差为奇数时右移一位对齐）
//              与首个商位 qInit。
//   s_iter   ：每拍做两个 radix-4 步：
//              · 选择块：用余数高位 r²·ws/wc 与 rudPmNeg[qPrev] 的 4 个 CSA 求符号 → qNext；
//              · 推测块：对 5 个可能的 qNext 各自预先算出下一个商位 → qNext2 = qSpec[qNext]；
//              · 两级宽 CSA 更新冗余余数 (rSum, rCarry) ← 16·w - qPrev·4d - qNext·d；
//              · 在线商转换（OTFC）同时维护 quot 与 quot-1。
//              iterNum 为 0 的那拍是最后一拍；LZC 差使总步数为奇时最后一拍只做半步。
//   s_post_0 ：把冗余余数加成非冗余 r 与 r+d（按被除数符号取反码形式）；
//              同时把商按商符号取补（quotIter ← -quot / quotM1Iter ← -(quot-1)）。
//   s_post_1 ：余数符号与被除数不一致（needCorr）时用 r+d 与 quot-1 修正；
//              余数右移 LZC(d) 位还原；锁存最终商 qFinal 与余数 rFinal。
//   s_finish ：out_valid，等 out_ready 回 idle。
// 输出：isHi 选余数否则商；isW 时取低 32 位符号扩展。
//
// 寄存器怪癖（照 golden，不收窄）：
//   * aLZCReg / dLZCReg 是 7 位（Scala aLZC 宽 lzc_width+1），最高位恒 0、无读者。
//   * udNegReg 只存 q≠0 的 4 档（q=0 那档恒 0，golden 不建寄存器）；每档 68 位，
//     最高位 [67] 无读者（读者只取 [65:0] 与 [66:57]）。
//   * PriorityEncoder 全 0 时给 63（最后一个下标），LZC 照此。
// 复位：只有 state 异步复位为 s_idle；其余都是 RegEnable（不复位）。
// =============================================================================
module xs_SRT16DividerDataModule_core (
  input  logic        clock,
  input  logic        reset,
  input  logic [63:0] src_a,          // 被除数
  input  logic [63:0] src_d,          // 除数
  input  logic        in_valid,
  input  logic        sign,           // 有符号除法
  input  logic        kill_w,         // 本拍的新请求被冲刷：不接收
  input  logic        kill_r,         // 在飞的请求被冲刷：回 idle
  input  logic        is_hi,          // 1 = 要余数
  input  logic        is_w,           // 1 = 32 位结果
  output logic        in_ready,
  output logic        out_valid,
  output logic [63:0] out_data,
  input  logic        out_ready
);

  // 状态独热位号
  localparam int S_IDLE   = 0;
  localparam int S_PRE_0  = 1;
  localparam int S_PRE_1  = 2;
  localparam int S_ITER   = 3;
  localparam int S_POST_0 = 4;
  localparam int S_POST_1 = 5;
  localparam int S_FINISH = 6;

  // 商位独热编码位号（与 Scala Enum 同：quot_neg_2 … quot_pos_2）
  localparam int Q_NEG_2 = 0;
  localparam int Q_NEG_1 = 1;
  localparam int Q_ZERO  = 2;
  localparam int Q_POS_1 = 3;
  localparam int Q_POS_2 = 4;

  localparam int ITN_LEN = 68;        // 1 + len + 2 + 1：迭代余数宽度

  logic [6:0] state;
  logic       in_fire;
  assign in_ready = state[S_IDLE];
  assign in_fire  = in_valid & in_ready;

  // ---------------------------------------------------------------------------
  // 寄存器声明
  // ---------------------------------------------------------------------------
  logic [63:0]  aReg;                 // 原始被除数（特殊情况直接用）
  logic         dSignReg;
  logic [63:0]  aAbsReg, dAbsReg;
  logic [63:0]  aNormReg, dNormReg;
  logic [6:0]   aLZCReg, dLZCReg;
  logic         aTooSmall;
  logic         specialReg;
  logic [63:0]  quotSpecialReg, remSpecialReg;
  logic         quotSignReg, rSignReg;
  logic [3:0]   iterNumReg;
  logic [4:0]   qPrevReg;             // 上一步商位（独热）
  logic [ITN_LEN-1:0] rSumReg, rCarryReg;
  logic [ITN_LEN-1:0] udNegReg_0, udNegReg_1, udNegReg_3, udNegReg_4;   // q=0 档恒 0，无寄存器
  logic [9:0]   rudPmNegReg  [5][4];
  logic [12:0]  r2udPmNegReg [5][4];
  logic [63:0]  quotIterReg, quotM1IterReg;
  logic [64:0]  rNextReg, rNextPdReg;
  logic [63:0]  rFinal, qFinal;

  // ---------------------------------------------------------------------------
  // 公共：求补器（idle 时给输入取绝对值，post_0 时给商取补，两处复用）
  // ---------------------------------------------------------------------------
  logic [63:0] a_inverter, d_inverter;
  assign a_inverter = -(state[S_IDLE] ? src_a : quotIterReg);
  assign d_inverter = -(state[S_IDLE] ? src_d : quotM1IterReg);

  logic a_sign, d_sign;
  assign a_sign = sign & src_a[63];
  assign d_sign = sign & src_d[63];

  // ---------------------------------------------------------------------------
  // §1 s_idle：接收请求，锁存绝对值与符号
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (in_fire) begin
      aReg     <= src_a;
      dSignReg <= d_sign;
      aAbsReg  <= a_sign ? a_inverter : src_a;
      dAbsReg  <= d_sign ? d_inverter : src_d;
      rSignReg <= a_sign;                       // 余数与被除数同号
    end
  end

  // ---------------------------------------------------------------------------
  // §2 s_pre_0：前导零计数与规格化
  // ---------------------------------------------------------------------------
  // 最高位起第一个 1 的位置（PriorityEncoder：全 0 时给 63）
  function automatic logic [5:0] lzc64(input logic [63:0] x);
    lzc64 = 6'd63;
    for (int i = 0; i <= 63; i++)
      if (x[i]) lzc64 = 6'(63 - i);             // 循环到高位为止，最后命中的是最高位
  endfunction

  logic [5:0] a_lzc, d_lzc;
  logic [6:0] lzc_wire_diff;                   // LZC(d) - LZC(a)，第 6 位为借位（a 太小）
  assign a_lzc         = lzc64(aAbsReg);
  assign d_lzc         = lzc64(dAbsReg);
  assign lzc_wire_diff = {1'b0, d_lzc} - {1'b0, a_lzc};

  always_ff @(posedge clock) begin
    if (state[S_PRE_0]) begin
      aNormReg  <= aAbsReg << a_lzc;
      dNormReg  <= dAbsReg << d_lzc;
      aLZCReg   <= {1'b0, a_lzc};
      dLZCReg   <= {1'b0, d_lzc};
      aTooSmall <= lzc_wire_diff[6];
    end
  end

  // ---------------------------------------------------------------------------
  // §3 s_pre_1：特殊情况、迭代次数、初始余数与首商位、迭代常量预算
  // ---------------------------------------------------------------------------
  logic d_is_one, d_is_zero, special;
  assign d_is_one  = &d_lzc;                   // |d| ∈ {0, 1}
  assign d_is_zero = (dNormReg == 64'd0);
  assign special   = d_is_one | d_is_zero | aTooSmall;

  logic [63:0] quot_special, rem_special;
  assign quot_special = d_is_zero ? '1 : aTooSmall ? 64'd0 : dSignReg ? -aReg : aReg;
  assign rem_special  = (d_is_zero | aTooSmall) ? aReg : 64'd0;

  logic [5:0] lzc_reg_diff;                    // 只用到低 6 位
  logic       r_shift, odd_iter, final_iter;
  logic [5:0] iter_num_plus1;
  assign lzc_reg_diff   = dLZCReg[5:0] - aLZCReg[5:0];
  assign r_shift        = lzc_reg_diff[0];
  assign odd_iter       = lzc_reg_diff[1] ^ lzc_reg_diff[0];
  assign iter_num_plus1 = lzc_reg_diff + 6'd1;
  assign final_iter     = (iterNumReg == 4'd0);

  // 初始余数：0.001xxx 定点；LZC 差为奇数时多右移一位，使每步两个 radix-4 位对齐
  logic [ITN_LEN-1:0] r_sum_init;
  logic [4:0]         r_sum_init_trunc;
  assign r_sum_init       = {3'b000, r_shift ? {1'b0, aNormReg} : {aNormReg, 1'b0}};
  assign r_sum_init_trunc = {1'b0, r_sum_init[64:61]};

  // 首商位选择阈值（按 dNorm 的第 2..4 位查表）
  logic [2:0] d_index;
  assign d_index = dNormReg[62:60];

  logic [4:0] m_init_pos1, m_init_pos2;
  always_comb begin
    case (d_index)
      3'd0, 3'd1, 3'd2:         m_init_pos1 = 5'b00100;
      3'd3, 3'd4, 3'd5, 3'd6:   m_init_pos1 = 5'b00110;
      default:                  m_init_pos1 = 5'b01000;
    endcase
    case (d_index)
      3'd0:    m_init_pos2 = 5'b01100;
      3'd1:    m_init_pos2 = 5'b01110;
      3'd2:    m_init_pos2 = 5'b01111;
      3'd3:    m_init_pos2 = 5'b10000;
      3'd4:    m_init_pos2 = 5'b10010;
      3'd5:    m_init_pos2 = 5'b10100;
      default: m_init_pos2 = 5'b10110;   // 6, 7
    endcase
  end

  logic [4:0] q_init;
  assign q_init = (r_sum_init_trunc >= m_init_pos2) ? (5'b1 << Q_POS_2)
                : (r_sum_init_trunc >= m_init_pos1) ? (5'b1 << Q_POS_1)
                :                                     (5'b1 << Q_ZERO);

  // 选择常数 -m_k（mLookUpTable2.minus_m，4 张 8 项表）
  logic [6:0] minus_m [4];
  always_comb begin
    case (d_index)
      3'd0: begin minus_m[0] = 7'b00_11010; minus_m[1] = 7'b000_0100; minus_m[2] = 7'b111_1101; minus_m[3] = 7'b11_01000; end
      3'd1: begin minus_m[0] = 7'b00_11110; minus_m[1] = 7'b000_0110; minus_m[2] = 7'b111_1100; minus_m[3] = 7'b11_00100; end
      3'd2: begin minus_m[0] = 7'b01_00000; minus_m[1] = 7'b000_0110; minus_m[2] = 7'b111_1100; minus_m[3] = 7'b11_00010; end
      3'd3: begin minus_m[0] = 7'b01_00100; minus_m[1] = 7'b000_0110; minus_m[2] = 7'b111_1100; minus_m[3] = 7'b10_11110; end
      3'd4: begin minus_m[0] = 7'b01_00110; minus_m[1] = 7'b000_1000; minus_m[2] = 7'b111_1011; minus_m[3] = 7'b10_11100; end
      3'd5: begin minus_m[0] = 7'b01_01010; minus_m[1] = 7'b000_1000; minus_m[2] = 7'b111_1010; minus_m[3] = 7'b10_11000; end
      3'd6: begin minus_m[0] = 7'b01_01100; minus_m[1] = 7'b000_1000; minus_m[2] = 7'b111_1010; minus_m[3] = 7'b10_10110; end
      default: begin
                  minus_m[0] = 7'b01_10000; minus_m[1] = 7'b000_1000; minus_m[2] = 7'b111_1010; minus_m[3] = 7'b10_10010; end
    endcase
  end

  // mNeg：-m_k 对齐成 (6,6) 定点 12 位（-m[-1] / -m[2] 原为 (2,5)，-m[0] / -m[1] 原为 (3,4)）
  logic [11:0] m_neg [4];
  assign m_neg[0] = {{4{minus_m[0][6]}}, minus_m[0], 1'b0};
  assign m_neg[1] = {{3{minus_m[1][6]}}, minus_m[1], 2'b00};
  assign m_neg[2] = {{3{minus_m[2][6]}}, minus_m[2], 2'b00};
  assign m_neg[3] = {{4{minus_m[3][6]}}, minus_m[3], 1'b0};

  // udNeg[q] = -q·d，68 位 (3,65) 定点；q 下标 0..4 对应 -2..+2 的"取负"：
  //   [0] = +2d, [1] = +d, [2] = 0, [3] = -d, [4] = -2d
  logic [64:0]        d_pos, d_neg;
  logic [ITN_LEN-1:0] ud_neg [5];
  assign d_pos     = {1'b0, dNormReg};
  assign d_neg     = -{1'b0, dNormReg};
  assign ud_neg[0] = {{1{d_pos[64]}}, d_pos, 2'b00};
  assign ud_neg[1] = {{2{d_pos[64]}}, d_pos, 1'b0};
  assign ud_neg[2] = '0;
  assign ud_neg[3] = {{2{d_neg[64]}}, d_neg, 1'b0};
  assign ud_neg[4] = {{1{d_neg[64]}}, d_neg, 2'b00};

  // rudPmNeg[q][k] = -(r·q·d + m_k) 截成 10 位；r2udPmNeg[q][k] = -(r²·q·d + m_k) 截成 13 位
  logic [9:0]  rud_pm_neg  [5][4];
  logic [12:0] r2ud_pm_neg [5][4];
  always_comb begin
    for (int q = 0; q < 5; q++)
      for (int k = 0; k < 4; k++) begin
        rud_pm_neg[q][k]  = {ud_neg[q][66], ud_neg[q][66:58]} + m_neg[k][10:1];
        r2ud_pm_neg[q][k] = {ud_neg[q][66], ud_neg[q][66:55]} + {m_neg[k][11], m_neg[k]};
      end
  end

  always_ff @(posedge clock) begin
    if (state[S_PRE_1]) begin
      specialReg     <= special;
      quotSpecialReg <= quot_special;
      remSpecialReg  <= rem_special;
      udNegReg_0     <= ud_neg[0];
      udNegReg_1     <= ud_neg[1];
      udNegReg_3     <= ud_neg[3];
      udNegReg_4     <= ud_neg[4];
      rudPmNegReg    <= rud_pm_neg;
      r2udPmNegReg   <= r2ud_pm_neg;
    end
  end

  // ---------------------------------------------------------------------------
  // §4 s_iter：选择块 / 推测块 / 宽 CSA 余数更新
  // ---------------------------------------------------------------------------
  // 由 4 个比较符号译出独热商位（Scala DetectSign）
  function automatic logic [4:0] detect_sign(input logic [3:0] s);
    detect_sign[Q_NEG_2] =  s[0] &  s[1] &  s[2];
    detect_sign[Q_NEG_1] = ~s[0] &  s[1] &  s[2];
    detect_sign[Q_ZERO]  =  s[2] & ~s[1];
    detect_sign[Q_POS_1] =  s[3] & ~s[2] & ~s[1];
    detect_sign[Q_POS_2] = ~s[3] & ~s[2] & ~s[1];
  endfunction

  // 按 qPrevReg（独热）选常量组
  logic [9:0]  sel_rud_pm  [4];
  logic [12:0] sel_r2ud_pm [4];
  always_comb begin
    for (int k = 0; k < 4; k++) begin
      sel_rud_pm[k]  = '0;
      sel_r2ud_pm[k] = '0;
      for (int q = 0; q < 5; q++)
        if (qPrevReg[q]) begin
          sel_rud_pm[k]  |= rudPmNegReg[q][k];
          sel_r2ud_pm[k] |= r2udPmNegReg[q][k];
        end
    end
  end

  // 4.1 选择块：r²·w + rudPmNeg 的符号 → qNext
  logic [3:0] sel_sign;
  logic [4:0] q_next;
  for (genvar k = 0; k < 4; k++) begin : g_sel
    logic [9:0] csa_sum, csa_carry, total;
    CSA3_2_3956 signs_csa_sel (
      .io_in_0  (rSumReg[67:58]),
      .io_in_1  (rCarryReg[67:58]),
      .io_in_2  (sel_rud_pm[k]),
      .io_out_0 (csa_sum),
      .io_out_1 (csa_carry)
    );
    assign total       = csa_sum + {csa_carry[8:0], 1'b0};
    assign sel_sign[k] = total[9];
  end
  assign q_next = detect_sign(sel_sign);

  // 4.2 推测块：对每个可能的 qNext 预先算出再下一个商位，最后按 qNext 取
  logic [4:0] q_spec [5];
  for (genvar q = 0; q < 5; q++) begin : g_spec
    logic [12:0] spec_in2;
    logic [12:0] s1_sum, s1_carry;
    logic [3:0]  spec_sign;
    case (q)                                   // SignExt(udNegReg[q][66:57], 13)；q=0 档恒 0
      0:       assign spec_in2 = {{3{udNegReg_0[66]}}, udNegReg_0[66:57]};
      1:       assign spec_in2 = {{3{udNegReg_1[66]}}, udNegReg_1[66:57]};
      2:       assign spec_in2 = 13'd0;
      3:       assign spec_in2 = {{3{udNegReg_3[66]}}, udNegReg_3[66:57]};
      default: assign spec_in2 = {{3{udNegReg_4[66]}}, udNegReg_4[66:57]};
    endcase
    CSA3_2_3962 csa_spec (
      .io_in_0  (rSumReg[67:55]),
      .io_in_1  (rCarryReg[67:55]),
      .io_in_2  (spec_in2),
      .io_out_0 (s1_sum),
      .io_out_1 (s1_carry)
    );
    for (genvar k = 0; k < 4; k++) begin : g_k
      logic [12:0] s2_sum, s2_carry, total;
      CSA3_2_3962 signs2_csa_spec (
        .io_in_0  (s1_sum),
        .io_in_1  ({s1_carry[11:0], 1'b0}),
        .io_in_2  (sel_r2ud_pm[k]),
        .io_out_0 (s2_sum),
        .io_out_1 (s2_carry)
      );
      assign total        = s2_sum + {s2_carry[11:0], 1'b0};
      assign spec_sign[k] = total[12];
    end
    assign q_spec[q] = detect_sign(spec_sign);
  end

  logic [4:0] q_next2;
  always_comb begin
    q_next2 = '0;
    for (int q = 0; q < 5; q++)
      if (q_next[q]) q_next2 |= q_spec[q];
  end

  // 4.3 两级宽 CSA：w ← 4·(4·w - qPrev·d) - qNext·d（最后一拍若只做半步则取第一级）
  //   按独热商位选 -q·d（q=0 档恒 0，不参与）
  logic               half_step_last;    // 偶数步且最后一拍：只做第一级
  logic [ITN_LEN-1:0] wide1_sum, wide1_carry, wide2_sum, wide2_carry;
  logic [ITN_LEN-1:0] ud_prev, ud_next;  // -qPrev·d、-qNext·d
  assign half_step_last = ~odd_iter & final_iter;

  always_comb begin
    ud_prev = '0;
    ud_next = '0;
    if (qPrevReg[Q_NEG_2]) ud_prev |= udNegReg_0;
    if (qPrevReg[Q_NEG_1]) ud_prev |= udNegReg_1;
    if (qPrevReg[Q_POS_1]) ud_prev |= udNegReg_3;
    if (qPrevReg[Q_POS_2]) ud_prev |= udNegReg_4;
    if (q_next[Q_NEG_2])   ud_next |= udNegReg_0;
    if (q_next[Q_NEG_1])   ud_next |= udNegReg_1;
    if (q_next[Q_POS_1])   ud_next |= udNegReg_3;
    if (q_next[Q_POS_2])   ud_next |= udNegReg_4;
  end

  CSA3_2_3960 csa_sel_wide_1 (
    .io_in_0  ({rSumReg[65:0], 2'b00}),
    .io_in_1  ({rCarryReg[65:0], 2'b00}),
    .io_in_2  ({ud_prev[65:0], 2'b00}),
    .io_out_0 (wide1_sum),
    .io_out_1 (wide1_carry)
  );
  CSA3_2_3960 csa_sel_wide_2 (
    .io_in_0  ({wide1_sum[65:0], 2'b00}),
    .io_in_1  ({wide1_carry[64:0], 3'b000}),
    .io_in_2  ({ud_next[65:0], 2'b00}),
    .io_out_0 (wide2_sum),
    .io_out_1 (wide2_carry)
  );

  logic [ITN_LEN-1:0] r_sum_iter, r_carry_iter;
  assign r_sum_iter   = half_step_last ? wide1_sum : wide2_sum;
  assign r_carry_iter = half_step_last ? {wide1_carry[66:0], 1'b0} : {wide2_carry[66:0], 1'b0};

  always_ff @(posedge clock) begin
    if (state[S_PRE_1] | state[S_ITER]) begin
      iterNumReg <= state[S_PRE_1] ? iter_num_plus1[5:2] : iterNumReg - 4'd1;
      qPrevReg   <= state[S_PRE_1] ? q_init : q_next2;
      rSumReg    <= state[S_PRE_1] ? r_sum_init : r_sum_iter;
      rCarryReg  <= state[S_PRE_1] ? '0 : r_carry_iter;
    end
  end

  // 4.4 在线商转换（OTFC）：同时维护 quot 与 quot-1，每个 radix-4 位左移 2 位拼入
  function automatic logic [127:0] otfc(input logic [4:0] q, input logic [63:0] quot,
                                        input logic [63:0] quot_m1);
    logic [63:0] nxt, nxt_m1;
    nxt    = '0;
    nxt_m1 = '0;
    if (q[Q_POS_2]) begin nxt |= {quot[61:0], 2'b10};    nxt_m1 |= {quot[61:0], 2'b01};    end
    if (q[Q_POS_1]) begin nxt |= {quot[61:0], 2'b01};    nxt_m1 |= {quot[61:0], 2'b00};    end
    if (q[Q_ZERO])  begin nxt |= {quot[61:0], 2'b00};    nxt_m1 |= {quot_m1[61:0], 2'b11}; end
    if (q[Q_NEG_1]) begin nxt |= {quot_m1[61:0], 2'b11}; nxt_m1 |= {quot_m1[61:0], 2'b10}; end
    if (q[Q_NEG_2]) begin nxt |= {quot_m1[61:0], 2'b10}; nxt_m1 |= {quot_m1[61:0], 2'b01}; end
    return {nxt, nxt_m1};
  endfunction

  logic [63:0] quot_half, quot_m1_half, quot_full, quot_m1_full;
  assign {quot_half, quot_m1_half} = otfc(qPrevReg, quotIterReg, quotM1IterReg);
  assign {quot_full, quot_m1_full} = otfc(q_next, quot_half, quot_m1_half);

  logic [63:0] quot_iter_next, quot_m1_iter_next;
  always_comb begin
    if (state[S_ITER]) begin
      quot_iter_next    = half_step_last ? quot_half    : quot_full;
      quot_m1_iter_next = half_step_last ? quot_m1_half : quot_m1_full;
    end else if (state[S_PRE_1]) begin
      quot_iter_next    = '0;
      quot_m1_iter_next = '0;
    end else if (quotSignReg) begin              // s_post_0：商为负则取补
      quot_iter_next    = a_inverter;
      quot_m1_iter_next = d_inverter;
    end else begin
      quot_iter_next    = quotIterReg;
      quot_m1_iter_next = quotM1IterReg;
    end
  end

  always_ff @(posedge clock) begin
    if (state[S_PRE_1] | state[S_ITER] | state[S_POST_0]) begin
      quotIterReg   <= quot_iter_next;
      quotM1IterReg <= quot_m1_iter_next;
    end
  end

  // 商符号：idle 收请求时 = 两操作数异号。pre_1 发现除数为 0 时再写一次 1——那条路径走
  // special、跳过 s_post_0，这个值实际用不到，照 Scala（"if not s_idle then must be s_pre_1 & dIsZero"）保留。
  always_ff @(posedge clock) begin
    if (in_fire | (state[S_PRE_1] & d_is_zero))
      quotSignReg <= ~state[S_IDLE] | (a_sign ^ d_sign);
  end

  // ---------------------------------------------------------------------------
  // §5 s_post_0：冗余余数求和（被除数为负时按反码形式求 -w）
  // ---------------------------------------------------------------------------
  logic [ITN_LEN-1:0] r_next, r_next_pd;
  always_comb begin
    if (rSignReg) begin
      r_next    = ~rSumReg + ~rCarryReg + 68'd2;
      r_next_pd = ~rSumReg + ~rCarryReg + ~{1'b0, dNormReg, 3'b000} + 68'd3;
    end else begin
      r_next    = rSumReg + rCarryReg;
      r_next_pd = rSumReg + rCarryReg + {1'b0, dNormReg, 3'b000};
    end
  end

  always_ff @(posedge clock) begin
    if (state[S_POST_0]) begin
      rNextReg   <= r_next[67:3];
      rNextPdReg <= r_next_pd[67:3];
    end
  end

  // ---------------------------------------------------------------------------
  // §6 s_post_1：余数符号修正、右移还原，锁存最终结果
  // ---------------------------------------------------------------------------
  logic        need_corr;
  logic [64:0] r_pre_shifted;
  logic [63:0] r_shifted;
  assign need_corr     = rSignReg ? (~rNextReg[64] & (|rNextReg)) : rNextReg[64];
  assign r_pre_shifted = need_corr ? rNextPdReg : rNextReg;

  RightShifter rightShifter (
    .io_shiftNum (dLZCReg[5:0]),
    .io_in       (r_pre_shifted[63:0]),
    .io_msb      ((|r_pre_shifted) & rSignReg),
    .io_out      (r_shifted)
  );

  always_ff @(posedge clock) begin
    if (state[S_POST_1]) begin
      rFinal <= specialReg ? remSpecialReg : r_shifted;
      qFinal <= specialReg ? quotSpecialReg : need_corr ? quotM1IterReg : quotIterReg;
    end
  end

  // ---------------------------------------------------------------------------
  // §7 状态机与输出
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      state <= 7'(1 << S_IDLE);
    else if (kill_r)
      state <= 7'(1 << S_IDLE);
    else if (state[S_IDLE] & in_fire & ~kill_w)
      state <= 7'(1 << S_PRE_0);
    else if (state[S_PRE_0])
      state <= 7'(1 << S_PRE_1);
    else if (state[S_PRE_1])
      state <= special ? 7'(1 << S_POST_1) : 7'(1 << S_ITER);
    else if (state[S_ITER])
      state <= final_iter ? 7'(1 << S_POST_0) : 7'(1 << S_ITER);
    else if (state[S_POST_0])
      state <= 7'(1 << S_POST_1);
    else if (state[S_POST_1])
      state <= 7'(1 << S_FINISH);
    else if (state[S_FINISH] & out_ready)
      state <= 7'(1 << S_IDLE);
  end

  logic [63:0] res;
  assign res       = is_hi ? rFinal : qFinal;
  assign out_valid = state[S_FINISH];
  assign out_data  = is_w ? {{32{res[31]}}, res[31:0]} : res;

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden SRT16DividerDataModule.sv 逐位一致
// （Scala 的 out_validNext 输出在 G1 配置下无读者，golden 已裁掉）
// ---------------------------------------------------------------------------
module SRT16DividerDataModule (
  input         clock,
  input         reset,
  input  [63:0] io_src_0,
  input  [63:0] io_src_1,
  input         io_valid,
  input         io_sign,
  input         io_kill_w,
  input         io_kill_r,
  input         io_isHi,
  input         io_isW,
  output        io_in_ready,
  output        io_out_valid,
  output [63:0] io_out_data,
  input         io_out_ready
);

  xs_SRT16DividerDataModule_core u_core (
    .clock     (clock),
    .reset     (reset),
    .src_a     (io_src_0),
    .src_d     (io_src_1),
    .in_valid  (io_valid),
    .sign      (io_sign),
    .kill_w    (io_kill_w),
    .kill_r    (io_kill_r),
    .is_hi     (io_isHi),
    .is_w      (io_isW),
    .in_ready  (io_in_ready),
    .out_valid (io_out_valid),
    .out_data  (io_out_data),
    .out_ready (io_out_ready)
  );

endmodule
