// =============================================================================
// fpsqrt_r16_block —— radix-16 浮点开方的单拍迭代块（两级 radix-4 SRT，四条 lane，纯组合）
//
// 在哪一层：fpsqrt_r16（标量）与 fpsqrt_vector_r16（向量）共用的迭代块，父级状态机每拍把上一拍的
//   部分余数（carry-save 两份）、根 Q 与 Q-ulp、当前位指针 mask、以及"为下一拍预算好的"QDS 输入
//   喂进来，本块算两位 radix-4 根数位（= 一位 radix-16）并给出下一拍的全部状态。
//   设计源：yunsuan/vector/vfsqrt/fpsqrt_r16_block.scala（本例化参数：S0_CSA_SPECULATIVE=1、
//   S0_CSA_MERGED=1 但未生效（MERGED 只在非投机时生效）、S1_QDS_SPECULATIVE=1、S1_CSA_SPECULATIVE=1、
//   RT_DIG_W=5，REM_W=64）。Scala 里另外两种 S0/S1 配置的分支在本例化下不存在，本件不写。
//
// ---- 算法（数位递推开方，radix 4）----
//   记第 j 步根为 Q[j]、部分余数 w[j]。每步选数位 q ∈ {-2,-1,0,+1,+2}，然后
//     w[j+1] = 4·w[j] - q·(2·Q[j] + q·4^-(j+1))           （"部分余数"更新）
//     Q[j+1] = Q[j] + q·4^-(j+1)                          （"on-the-fly 转换"）
//   w 用 carry-save（f_r_s / f_r_c 两份）表示，减去的那一项叫 sqrt_csa_val，经一级 3:2 CSA 并入。
//   为了不在每步做 Q-1 的借位，另外维护 QM = Q - 4^-j（rt_m1），负数位时用它拼：
//     q=+1/+2：Q 的该位填 01/10；q=0：Q 不变；q=-1/-2：取 QM 填 11/10。QM 同理（见 §4）。
//   4^-(j+1) 的位置由 one-hot 的 mask（每步右移两位）指出。
//
// ---- 本块结构（每条 lane 做两级：s0 与 s1）----
//   §1 QDS（数位选择）：s0 的数位由 r4_qds 直接给出（它的 7 位余数估计与比较常数都是上一拍为本拍
//      预算好的输入）；s1 的数位要用到 s0 的结果，为了不串在关键路径上，用 r4_qds_spec 对 s0 的
//      5 种可能数位各算一份再按 s0 实际数位挑（"投机 QDS"）。
//   §2 部分余数（投机 CSA）：每级对 5 个候选数位各做一份 CSA，数位出来后 Mux1H 选一份。
//   §3 比较常数：每个候选的下一个根 Q' 的高位喂 r4_qds_cg，得到下一级 QDS 的 4 个比较常数
//      （s0 的给 s1 的投机 QDS，s1 的选出来给下一拍）。
//   §4 on-the-fly 转换：Q / QM 的 5 个候选也随数位 Mux1H。
//   §5 为下一拍预算：下一拍 s0 要的 7 位余数估计与 s1 要的 9 位估计，在本拍用 s0 的余数高位
//      加上 s1 各候选的 sqrt_csa_val 高位全加（非 carry-save）预先算好，再按 s1 数位挑。
//
// ---- 四条 lane 与格式打包 ----
//   lane0 宽 56（f64），lane1 宽 28（f32），lane2/lane3 宽 16（f16）；f_r_s/f_r_c/rt/rt_m1 的 64/56/53
//   位打包里：f64 只用 lane0；f32 用 lane0 的高 28 位 + lane1；f16 用 lane0/lane1 的高 16 位 + lane2/3。
//   lane0/lane1 里"本元素以下"的低位是别的元素的残留，靠"段切口"隔开：在元素的最低两位（段 LSB 处）
//   让 ×4 移进来的位、以及根移位进来的位都清零，CSA 的进位输入在段 LSB 处强制成本数位的 +1 进位——
//   效果与一条只有元素宽度的独立 lane 完全相同（lane2/3 就是这样的独立 lane，无切口）。
//     lane0：f16 切口在第 40 位（fp_fmt_i[0]），f32 切口在第 28 位（fp_fmt_i[1]）；
//     lane1：f16 切口在第 12 位（fp_fmt_i[0]）。
//   输出按 fp_fmt_i 的 one-hot 位分别打包后按位或（fp_fmt_i 非 one-hot 时照 golden 一并或上）。
//
// 怪癖（照 golden）：
//   - 输入根的打包只存元素根的低位，lane 内的完整根首位由 ~rt_i[元素最高位] 补出，QM 首两位补 01。
//   - mask 的各种派生（<<1、<<2、|）先在 lane0 的 56 / 55 位坐标里做、再按 lane 宽度截高位——
//     不是在窄 lane 里各自移位（两者在截断处的低位不同，见 xs_fpsqrt_r16_step 文件内注释）。
//   - QDS 的比较常数从父级来时被截成 5/4/3/4 位，这里按 Scala 补回 7 位（补 0 / 补 1 / 低位补 0）。
//
// 子模块：r4_qds ×4（s0 数位）、r4_qds_spec ×4（s1 投机数位）、r4_qds_cg ×40（4 lane × 2 级 × 5 候选）。
// golden 对照：G1-canonical/golden-rtl/fpsqrt_r16_block.sv（3575 行，firtool 平铺）。
// =============================================================================

// -----------------------------------------------------------------------------
// xs_fpsqrt_r16_step —— 一级 radix-4 迭代的"除数位选择以外"的全部工作（§2 §3 §4）
//   给定上一级的余数 / 根 / QM，对 5 个候选数位并行算出下一级余数、根、QM 与比较常数，
//   再用本级数位（one-hot：[4]=-2 [3]=-1 [2]=0 [1]=+1 [0]=+2）挑出一份。
// -----------------------------------------------------------------------------
module xs_fpsqrt_r16_step #(
  parameter int W = 56                       // lane 余数宽度；根宽度 W-1
) (
  input  logic [W-1:0]        rem_s,         // 上一级部分余数（carry-save，未 ×4）
  input  logic [W-1:0]        rem_c,
  input  logic [W-2:0]        rt,            // Q
  input  logic [W-2:0]        rt_m1,         // QM = Q - ulp
  input  logic [W-1:0]        seg_lsb,       // 段切口：每个置 1 的位是某个元素的段 LSB
  input  logic [55:0]         mask_ext,      // 本级位指针（lane0 坐标，56 位）
  input  logic [4:0]          digit,         // 本级数位，one-hot
  output logic [4:0][W-1:0]   csa_val,       // 各候选减去的 sqrt_csa_val（[2] 恒 0）
  output logic [W-1:0]        nxt_rem_s,
  output logic [W-1:0]        nxt_rem_c,
  output logic [W-2:0]        nxt_rt,
  output logic [W-2:0]        nxt_rt_m1,
  output logic [4:0][6:0]     cand_m_neg_1,  // 各候选的下一级 QDS 比较常数（r4_qds_cg）
  output logic [4:0][6:0]     cand_m_neg_0,
  output logic [4:0][6:0]     cand_m_pos_1,
  output logic [4:0][6:0]     cand_m_pos_2
);
  localparam int RW = W - 1;                 // 根宽度
  localparam int NEG2 = 4, NEG1 = 3, ZERO = 2, POS1 = 1, POS2 = 0;

  // ---- 位指针的派生：在 lane0 坐标（csa 56 位 / 根 55 位）里移位，再截本 lane 的高 W / W-1 位 ----
  //   截高位而不是在窄坐标里移位：截断处下面一档的指针位会被移进来（golden 原样）。
  logic [55:0] e;
  logic [54:0] r;
  logic [55:0] full_csa_neg2, full_csa_neg1, full_csa_pos1, full_csa_pos2;
  logic [54:0] full_rt_neg2, full_rt_neg1, full_rt_pos1, full_rt_pos2;
  logic [54:0] full_m1_neg2, full_m1_neg1, full_m1_neg0, full_m1_pos2;
  assign e = mask_ext;
  assign r = mask_ext[54:0];
  // sqrt_csa_val 里数位 q 自身的那一项 q²·4^-(j+1)（按 ×2 的余数坐标）
  assign full_csa_neg2 = (e << 2) | (e << 3);
  assign full_csa_neg1 = e | (e << 1) | (e << 2);
  assign full_csa_pos1 = e;
  assign full_csa_pos2 = e << 2;
  // on-the-fly：Q 的候选在指针处填的两位
  assign full_rt_neg2 = r << 1;              // QM + 10
  assign full_rt_neg1 = r | (r << 1);        // QM + 11
  assign full_rt_pos1 = r;                   // Q  + 01
  assign full_rt_pos2 = r << 1;              // Q  + 10
  // on-the-fly：QM 的候选
  assign full_m1_neg2 = r;                   // QM + 01
  assign full_m1_neg1 = r << 1;              // QM + 10
  assign full_m1_neg0 = r | (r << 1);        // QM + 11
  assign full_m1_pos2 = r;                   // Q  + 01   （q=+1 时 QM' = Q）

  logic [W-1:0]  m_csa_neg2, m_csa_neg1, m_csa_pos1, m_csa_pos2;
  logic [RW-1:0] m_rt_neg2, m_rt_neg1, m_rt_pos1, m_rt_pos2;
  logic [RW-1:0] m_m1_neg2, m_m1_neg1, m_m1_neg0, m_m1_pos2;
  assign m_csa_neg2 = full_csa_neg2[55 -: W];
  assign m_csa_neg1 = full_csa_neg1[55 -: W];
  assign m_csa_pos1 = full_csa_pos1[55 -: W];
  assign m_csa_pos2 = full_csa_pos2[55 -: W];
  assign m_rt_neg2  = full_rt_neg2[54 -: RW];
  assign m_rt_neg1  = full_rt_neg1[54 -: RW];
  assign m_rt_pos1  = full_rt_pos1[54 -: RW];
  assign m_rt_pos2  = full_rt_pos2[54 -: RW];
  assign m_m1_neg2  = full_m1_neg2[54 -: RW];
  assign m_m1_neg1  = full_m1_neg1[54 -: RW];
  assign m_m1_neg0  = full_m1_neg0[54 -: RW];
  assign m_m1_pos2  = full_m1_pos2[54 -: RW];

  // ---- §2 部分余数：×4 + 段切口，然后对 4 个非零候选各做一级 CSA ----
  logic [W-1:0]  seg_cut;                    // 段 LSB 及其上一位：×4 移进来的位必须是 0
  logic [RW-1:0] rt_seg_cut;                 // 同一切口在根坐标（余数坐标 - 2）
  logic [W-1:0]  rem_s_x4, rem_c_x4;
  logic [RW-1:0] rt_for_csa, rt_m1_for_csa;
  assign seg_cut       = seg_lsb | (seg_lsb << 1);
  assign rt_seg_cut    = RW'(seg_cut >> 2);
  assign rem_s_x4      = (rem_s << 2) & ~seg_cut;
  assign rem_c_x4      = (rem_c << 2) & ~seg_cut;
  assign rt_for_csa    = rt & ~rt_seg_cut;
  assign rt_m1_for_csa = rt_m1 & ~rt_seg_cut;

  // sqrt_csa_val = -q·(2Q + q·u)，u = 4^-(j+1) 即位指针，QM = Q - 4u：
  //   q=-2：4Q - 4u = 4·QM + 12u（指针处填 1100）；q=-1：2Q - u = 2·QM + 7u（填 111）；
  //   q=+1/+2：-(2Q + u) / -(4Q + 4u) → 取反码，补码的 +1 由 CSA 进位输入 cin 补上。
  assign csa_val[NEG2] = ({1'b0, rt_m1_for_csa} << 2) | m_csa_neg2;
  assign csa_val[NEG1] = ({1'b0, rt_m1_for_csa} << 1) | m_csa_neg1;
  assign csa_val[ZERO] = '0;
  assign csa_val[POS1] = ~(({1'b0, rt_for_csa} << 1) | m_csa_pos1);
  assign csa_val[POS2] = ~(({1'b0, rt_for_csa} << 2) | m_csa_pos2);

  logic [4:0][W-1:0] cand_s, cand_c;
  always_comb begin
    for (int c = 0; c < 5; c++) begin
      if (c == ZERO) begin
        // q = 0：余数只是 ×4，不过 CSA
        cand_s[c] = rem_s_x4;
        cand_c[c] = rem_c_x4;
      end else begin
        logic          cin;                  // 反码 +1：正数位为 1
        logic [W-1:0]  maj;
        cin       = (c == POS1) || (c == POS2);
        maj       = (rem_s_x4 & rem_c_x4) | (rem_s_x4 & csa_val[c]) | (rem_c_x4 & csa_val[c]);
        cand_s[c] = rem_s_x4 ^ rem_c_x4 ^ csa_val[c];
        // 进位左移一位、最低位接 cin；每个段 LSB 也接 cin（段间不传进位）
        cand_c[c] = ({maj[W-2:0], cin} & ~seg_lsb) | (seg_lsb & {W{cin}});
      end
    end
  end

  // ---- §4 on-the-fly 转换：Q / QM 的 5 个候选 ----
  logic [4:0][RW-1:0] cand_rt, cand_rt_m1;
  assign cand_rt[NEG2]    = rt_m1 | m_rt_neg2;
  assign cand_rt[NEG1]    = rt_m1 | m_rt_neg1;
  assign cand_rt[ZERO]    = rt;
  assign cand_rt[POS1]    = rt | m_rt_pos1;
  assign cand_rt[POS2]    = rt | m_rt_pos2;
  assign cand_rt_m1[NEG2] = rt_m1 | m_m1_neg2;
  assign cand_rt_m1[NEG1] = rt_m1 | m_m1_neg1;
  assign cand_rt_m1[ZERO] = rt_m1 | m_m1_neg0;
  assign cand_rt_m1[POS1] = rt;
  assign cand_rt_m1[POS2] = rt | m_m1_pos2;

  // ---- §3 比较常数：r4_qds_cg 按 Q' 的最高位与第 3/4/5 位查表（Scala 原样，第 2 位不参与）----
  for (genvar c = 0; c < 5; c++) begin : g_cg
    r4_qds_cg u_cg (
      .a0_i      (cand_rt[c][RW-1]),
      .a2_i      (cand_rt[c][RW-3]),
      .a3_i      (cand_rt[c][RW-4]),
      .a4_i      (cand_rt[c][RW-5]),
      .m_neg_1_o (cand_m_neg_1[c]),
      .m_neg_0_o (cand_m_neg_0[c]),
      .m_pos_1_o (cand_m_pos_1[c]),
      .m_pos_2_o (cand_m_pos_2[c])
    );
  end

  // ---- 数位出来后 Mux1H 选候选（AND-OR，golden 原样）----
  always_comb begin
    nxt_rem_s = '0;
    nxt_rem_c = '0;
    nxt_rt    = '0;
    nxt_rt_m1 = '0;
    for (int c = 0; c < 5; c++) begin
      nxt_rem_s |= {W{digit[c]}}  & cand_s[c];
      nxt_rem_c |= {W{digit[c]}}  & cand_c[c];
      nxt_rt    |= {RW{digit[c]}} & cand_rt[c];
      nxt_rt_m1 |= {RW{digit[c]}} & cand_rt_m1[c];
    end
  end
endmodule

// -----------------------------------------------------------------------------
// xs_fpsqrt_r16_lane —— 一条 lane 的两级（s0 / s1）迭代 + 为下一拍的预算（§1 §5）
// -----------------------------------------------------------------------------
module xs_fpsqrt_r16_lane #(
  parameter int W = 56
) (
  input  logic [W-1:0] rem_s,
  input  logic [W-1:0] rem_c,
  input  logic [W-2:0] rt,
  input  logic [W-2:0] rt_m1,
  input  logic [W-1:0] seg_lsb,
  input  logic [55:0]  mask_ext_s0,         // s0 的位指针；s1 = 右移两位
  input  logic [6:0]   s0_rem_est,          // 上一拍预算的 s0 余数估计（7 位）
  input  logic [8:0]   s1_rem_est,          // 上一拍预算的 s1 余数估计（9 位，不含 s0 的修正项）
  input  logic [6:0]   s0_m_neg_1,          // s0 的比较常数（已补回 7 位）
  input  logic [6:0]   s0_m_neg_0,
  input  logic [6:0]   s0_m_pos_1,
  input  logic [6:0]   s0_m_pos_2,
  output logic [W-1:0] nxt_rem_s,
  output logic [W-1:0] nxt_rem_c,
  output logic [W-2:0] nxt_rt,
  output logic [W-2:0] nxt_rt_m1,
  output logic [6:0]   nxt_s0_rem_est,      // 给下一拍 s0
  output logic [8:0]   nxt_s1_rem_est,      // 给下一拍 s1
  output logic [6:0]   nxt_m_neg_1,         // 给下一拍 s0 的比较常数
  output logic [6:0]   nxt_m_neg_0,
  output logic [6:0]   nxt_m_pos_1,
  output logic [6:0]   nxt_m_pos_2
);
  // ---- s0：数位 ----
  logic [4:0] s0_digit, s1_digit;
  r4_qds u_r4_qds_s0 (
    .rem_i     (s0_rem_est),
    .m_neg_1_i (s0_m_neg_1),
    .m_neg_0_i (s0_m_neg_0),
    .m_pos_1_i (s0_m_pos_1),
    .m_pos_2_i (s0_m_pos_2),
    .rt_dig_o  (s0_digit)
  );

  // ---- s0：余数 / 根 / 比较常数 ----
  logic [4:0][W-1:0] s0_csa_val, s1_csa_val;
  logic [W-1:0]      s0_rem_s, s0_rem_c;
  logic [W-2:0]      s0_rt, s0_rt_m1;
  logic [4:0][6:0]   s0_cm_neg_1, s0_cm_neg_0, s0_cm_pos_1, s0_cm_pos_2;
  logic [4:0][6:0]   s1_cm_neg_1, s1_cm_neg_0, s1_cm_pos_1, s1_cm_pos_2;
  xs_fpsqrt_r16_step #(.W(W)) u_s0 (
    .rem_s        (rem_s),
    .rem_c        (rem_c),
    .rt           (rt),
    .rt_m1        (rt_m1),
    .seg_lsb      (seg_lsb),
    .mask_ext     (mask_ext_s0),
    .digit        (s0_digit),
    .csa_val      (s0_csa_val),
    .nxt_rem_s    (s0_rem_s),
    .nxt_rem_c    (s0_rem_c),
    .nxt_rt       (s0_rt),
    .nxt_rt_m1    (s0_rt_m1),
    .cand_m_neg_1 (s0_cm_neg_1),
    .cand_m_neg_0 (s0_cm_neg_0),
    .cand_m_pos_1 (s0_cm_pos_1),
    .cand_m_pos_2 (s0_cm_pos_2)
  );

  // ---- s1：投机 QDS——对 s0 的 5 种数位各算一份，按 s0 实际数位挑 ----
  //   每份 = 9 位余数估计 + 该候选 sqrt_csa_val 的高 9 位，再与该候选的 4 个比较常数比较。
  r4_qds_spec u_r4_qds_s1 (
    .rem_i                     (s1_rem_est),
    .sqrt_csa_val_neg_2_msbs_i (s0_csa_val[4][W-1 -: 9]),
    .sqrt_csa_val_neg_1_msbs_i (s0_csa_val[3][W-1 -: 9]),
    .sqrt_csa_val_pos_1_msbs_i (s0_csa_val[1][W-1 -: 9]),
    .sqrt_csa_val_pos_2_msbs_i (s0_csa_val[0][W-1 -: 9]),
    .m_neg_1_neg_2_i           (s0_cm_neg_1[4]),
    .m_neg_0_neg_2_i           (s0_cm_neg_0[4]),
    .m_pos_1_neg_2_i           (s0_cm_pos_1[4]),
    .m_pos_2_neg_2_i           (s0_cm_pos_2[4]),
    .m_neg_1_neg_1_i           (s0_cm_neg_1[3]),
    .m_neg_0_neg_1_i           (s0_cm_neg_0[3]),
    .m_pos_1_neg_1_i           (s0_cm_pos_1[3]),
    .m_pos_2_neg_1_i           (s0_cm_pos_2[3]),
    .m_neg_1_neg_0_i           (s0_cm_neg_1[2]),
    .m_neg_0_neg_0_i           (s0_cm_neg_0[2]),
    .m_pos_1_neg_0_i           (s0_cm_pos_1[2]),
    .m_pos_2_neg_0_i           (s0_cm_pos_2[2]),
    .m_neg_1_pos_1_i           (s0_cm_neg_1[1]),
    .m_neg_0_pos_1_i           (s0_cm_neg_0[1]),
    .m_pos_1_pos_1_i           (s0_cm_pos_1[1]),
    .m_pos_2_pos_1_i           (s0_cm_pos_2[1]),
    .m_neg_1_pos_2_i           (s0_cm_neg_1[0]),
    .m_neg_0_pos_2_i           (s0_cm_neg_0[0]),
    .m_pos_1_pos_2_i           (s0_cm_pos_1[0]),
    .m_pos_2_pos_2_i           (s0_cm_pos_2[0]),
    .prev_rt_dig_i             (s0_digit),
    .rt_dig_o                  (s1_digit)
  );

  // ---- s1：余数 / 根 / 比较常数 ----
  xs_fpsqrt_r16_step #(.W(W)) u_s1 (
    .rem_s        (s0_rem_s),
    .rem_c        (s0_rem_c),
    .rt           (s0_rt),
    .rt_m1        (s0_rt_m1),
    .seg_lsb      (seg_lsb),
    .mask_ext     (mask_ext_s0 >> 2),
    .digit        (s1_digit),
    .csa_val      (s1_csa_val),
    .nxt_rem_s    (nxt_rem_s),
    .nxt_rem_c    (nxt_rem_c),
    .nxt_rt       (nxt_rt),
    .nxt_rt_m1    (nxt_rt_m1),
    .cand_m_neg_1 (s1_cm_neg_1),
    .cand_m_neg_0 (s1_cm_neg_0),
    .cand_m_pos_1 (s1_cm_pos_1),
    .cand_m_pos_2 (s1_cm_pos_2)
  );

  // ---- §5 为下一拍预算余数估计 ----
  //   下一拍 s0 的余数 = 4·(s1 后余数)，其高位 ≈ 4·s0 余数的高位 + s1 候选 sqrt_csa_val 的高位
  //   （全加器，非 carry-save）；9 位窗取到 s0 余数的 [W-3 -: 9]（即 ×4 后的最高 9 位），取 [8:2]
  //   成 7 位。下一拍 s1 的 9 位估计再往下错两位（10 位窗，取 [9:1]）。
  logic [4:0][8:0] est9;
  logic [4:0][9:0] est10;
  always_comb begin
    for (int c = 0; c < 5; c++) begin
      est9[c]  = 9'(s0_rem_s[W-3 -: 9] + s0_rem_c[W-3 -: 9] + s1_csa_val[c][W-1 -: 9]);
      est10[c] = 10'(s0_rem_s[W-5 -: 10] + s0_rem_c[W-5 -: 10] + s1_csa_val[c][W-3 -: 10]);
    end
  end

  // ---- 按 s1 数位挑出下一拍要的东西 ----
  always_comb begin
    nxt_s0_rem_est = '0;
    nxt_s1_rem_est = '0;
    nxt_m_neg_1    = '0;
    nxt_m_neg_0    = '0;
    nxt_m_pos_1    = '0;
    nxt_m_pos_2    = '0;
    for (int c = 0; c < 5; c++) begin
      nxt_s0_rem_est |= {7{s1_digit[c]}} & est9[c][8:2];
      nxt_s1_rem_est |= {9{s1_digit[c]}} & est10[c][9:1];
      nxt_m_neg_1    |= {7{s1_digit[c]}} & s1_cm_neg_1[c];
      nxt_m_neg_0    |= {7{s1_digit[c]}} & s1_cm_neg_0[c];
      nxt_m_pos_1    |= {7{s1_digit[c]}} & s1_cm_pos_1[c];
      nxt_m_pos_2    |= {7{s1_digit[c]}} & s1_cm_pos_2[c];
    end
  end
endmodule

// -----------------------------------------------------------------------------
// xs_fpsqrt_r16_block_core —— 拆包到四条 lane、拼包输出
// -----------------------------------------------------------------------------
module xs_fpsqrt_r16_block_core (
  input  logic [2:0]       fp_fmt,          // one-hot：[0]=f16 [1]=f32 [2]=f64
  input  logic [63:0]      f_r_s,
  input  logic [63:0]      f_r_c,
  input  logic [55:0]      rt_packed,
  input  logic [52:0]      rt_m1_packed,
  input  logic [12:0]      mask,            // 位指针（13 个 4 位一档）
  input  logic [3:0][6:0]  s0_rem_est,      // 每 lane 的上一拍预算
  input  logic [3:0][8:0]  s1_rem_est,
  input  logic [3:0][4:0]  s0_m_neg_1_trunc,
  input  logic [3:0][3:0]  s0_m_neg_0_trunc,
  input  logic [3:0][2:0]  s0_m_pos_1_trunc,
  input  logic [3:0][3:0]  s0_m_pos_2_trunc,
  output logic [55:0]      nxt_rt_packed,
  output logic [52:0]      nxt_rt_m1_packed,
  output logic [63:0]      nxt_f_r_s,
  output logic [63:0]      nxt_f_r_c,
  output logic [3:0][6:0]  nxt_s0_rem_est,
  output logic [3:0][8:0]  nxt_s1_rem_est,
  output logic [3:0][6:0]  nxt_m_neg_1,
  output logic [3:0][6:0]  nxt_m_neg_0,
  output logic [3:0][6:0]  nxt_m_pos_1,
  output logic [3:0][6:0]  nxt_m_pos_2
);
  // ---- 位指针：mask[k] 放在第 2+4k 位（lane0 坐标）----
  logic [55:0] mask_ext;
  always_comb begin
    mask_ext = '0;
    for (int k = 0; k < 13; k++)
      mask_ext[2 + 4*k] = mask[k];
  end

  // ---- 比较常数补回 7 位 ----
  logic [3:0][6:0] m_neg_1, m_neg_0, m_pos_1, m_pos_2;
  always_comb begin
    for (int l = 0; l < 4; l++) begin
      m_neg_1[l] = {2'b00, s0_m_neg_1_trunc[l]};
      m_neg_0[l] = {3'b000, s0_m_neg_0_trunc[l]};
      m_pos_1[l] = {4'b1111, s0_m_pos_1_trunc[l]};
      m_pos_2[l] = {2'b11, s0_m_pos_2_trunc[l], 1'b0};
    end
  end

  // ---- 拆包：每条 lane 的余数（未 ×4）、根（补首位）、QM（补首两位 01）与段切口 ----
  logic [55:0] l0_rem_s, l0_rem_c, l0_seg;
  logic [27:0] l1_rem_s, l1_rem_c, l1_seg;
  logic [15:0] l2_rem_s, l2_rem_c, l3_rem_s, l3_rem_c;
  logic [54:0] l0_rt, l0_rt_m1;
  logic [26:0] l1_rt, l1_rt_m1;
  logic [14:0] l2_rt, l2_rt_m1, l3_rt, l3_rt_m1;
  assign l0_rem_s = f_r_s[63:8];
  assign l0_rem_c = f_r_c[63:8];
  assign l1_rem_s = f_r_s[31:4];
  assign l1_rem_c = f_r_c[31:4];
  assign l2_rem_s = f_r_s[47:32];
  assign l2_rem_c = f_r_c[47:32];
  assign l3_rem_s = f_r_s[15:0];
  assign l3_rem_c = f_r_c[15:0];
  assign l0_rt    = {~rt_packed[55], rt_packed[55:2]};
  assign l1_rt    = {~rt_packed[27], rt_packed[27:2]};
  assign l2_rt    = {~rt_packed[41], rt_packed[41:28]};
  assign l3_rt    = {~rt_packed[13], rt_packed[13:0]};
  assign l0_rt_m1 = {2'b01, rt_m1_packed[52:0]};
  assign l1_rt_m1 = {2'b01, rt_m1_packed[26:2]};
  assign l2_rt_m1 = {2'b01, rt_m1_packed[39:27]};
  assign l3_rt_m1 = {2'b01, rt_m1_packed[13:1]};
  // lane0：f16 时第 40 位、f32 时第 28 位是本元素段 LSB；lane1：f16 时第 12 位
  assign l0_seg = (56'(fp_fmt[0]) << 40) | (56'(fp_fmt[1]) << 28);
  assign l1_seg = 28'(fp_fmt[0]) << 12;

  logic [55:0] l0_nxt_s, l0_nxt_c;
  logic [27:0] l1_nxt_s, l1_nxt_c;
  logic [15:0] l2_nxt_s, l2_nxt_c, l3_nxt_s, l3_nxt_c;
  logic [54:0] l0_nxt_rt, l0_nxt_rt_m1;
  logic [26:0] l1_nxt_rt, l1_nxt_rt_m1;
  logic [14:0] l2_nxt_rt, l2_nxt_rt_m1, l3_nxt_rt, l3_nxt_rt_m1;

  xs_fpsqrt_r16_lane #(.W(56)) u_lane0 (
    .rem_s          (l0_rem_s),
    .rem_c          (l0_rem_c),
    .rt             (l0_rt),
    .rt_m1          (l0_rt_m1),
    .seg_lsb        (l0_seg),
    .mask_ext_s0    (mask_ext),
    .s0_rem_est     (s0_rem_est[0]),
    .s1_rem_est     (s1_rem_est[0]),
    .s0_m_neg_1     (m_neg_1[0]),
    .s0_m_neg_0     (m_neg_0[0]),
    .s0_m_pos_1     (m_pos_1[0]),
    .s0_m_pos_2     (m_pos_2[0]),
    .nxt_rem_s      (l0_nxt_s),
    .nxt_rem_c      (l0_nxt_c),
    .nxt_rt         (l0_nxt_rt),
    .nxt_rt_m1      (l0_nxt_rt_m1),
    .nxt_s0_rem_est (nxt_s0_rem_est[0]),
    .nxt_s1_rem_est (nxt_s1_rem_est[0]),
    .nxt_m_neg_1    (nxt_m_neg_1[0]),
    .nxt_m_neg_0    (nxt_m_neg_0[0]),
    .nxt_m_pos_1    (nxt_m_pos_1[0]),
    .nxt_m_pos_2    (nxt_m_pos_2[0])
  );
  xs_fpsqrt_r16_lane #(.W(28)) u_lane1 (
    .rem_s          (l1_rem_s),
    .rem_c          (l1_rem_c),
    .rt             (l1_rt),
    .rt_m1          (l1_rt_m1),
    .seg_lsb        (l1_seg),
    .mask_ext_s0    (mask_ext),
    .s0_rem_est     (s0_rem_est[1]),
    .s1_rem_est     (s1_rem_est[1]),
    .s0_m_neg_1     (m_neg_1[1]),
    .s0_m_neg_0     (m_neg_0[1]),
    .s0_m_pos_1     (m_pos_1[1]),
    .s0_m_pos_2     (m_pos_2[1]),
    .nxt_rem_s      (l1_nxt_s),
    .nxt_rem_c      (l1_nxt_c),
    .nxt_rt         (l1_nxt_rt),
    .nxt_rt_m1      (l1_nxt_rt_m1),
    .nxt_s0_rem_est (nxt_s0_rem_est[1]),
    .nxt_s1_rem_est (nxt_s1_rem_est[1]),
    .nxt_m_neg_1    (nxt_m_neg_1[1]),
    .nxt_m_neg_0    (nxt_m_neg_0[1]),
    .nxt_m_pos_1    (nxt_m_pos_1[1]),
    .nxt_m_pos_2    (nxt_m_pos_2[1])
  );
  xs_fpsqrt_r16_lane #(.W(16)) u_lane2 (
    .rem_s          (l2_rem_s),
    .rem_c          (l2_rem_c),
    .rt             (l2_rt),
    .rt_m1          (l2_rt_m1),
    .seg_lsb        (16'h0),
    .mask_ext_s0    (mask_ext),
    .s0_rem_est     (s0_rem_est[2]),
    .s1_rem_est     (s1_rem_est[2]),
    .s0_m_neg_1     (m_neg_1[2]),
    .s0_m_neg_0     (m_neg_0[2]),
    .s0_m_pos_1     (m_pos_1[2]),
    .s0_m_pos_2     (m_pos_2[2]),
    .nxt_rem_s      (l2_nxt_s),
    .nxt_rem_c      (l2_nxt_c),
    .nxt_rt         (l2_nxt_rt),
    .nxt_rt_m1      (l2_nxt_rt_m1),
    .nxt_s0_rem_est (nxt_s0_rem_est[2]),
    .nxt_s1_rem_est (nxt_s1_rem_est[2]),
    .nxt_m_neg_1    (nxt_m_neg_1[2]),
    .nxt_m_neg_0    (nxt_m_neg_0[2]),
    .nxt_m_pos_1    (nxt_m_pos_1[2]),
    .nxt_m_pos_2    (nxt_m_pos_2[2])
  );
  xs_fpsqrt_r16_lane #(.W(16)) u_lane3 (
    .rem_s          (l3_rem_s),
    .rem_c          (l3_rem_c),
    .rt             (l3_rt),
    .rt_m1          (l3_rt_m1),
    .seg_lsb        (16'h0),
    .mask_ext_s0    (mask_ext),
    .s0_rem_est     (s0_rem_est[3]),
    .s1_rem_est     (s1_rem_est[3]),
    .s0_m_neg_1     (m_neg_1[3]),
    .s0_m_neg_0     (m_neg_0[3]),
    .s0_m_pos_1     (m_pos_1[3]),
    .s0_m_pos_2     (m_pos_2[3]),
    .nxt_rem_s      (l3_nxt_s),
    .nxt_rem_c      (l3_nxt_c),
    .nxt_rt         (l3_nxt_rt),
    .nxt_rt_m1      (l3_nxt_rt_m1),
    .nxt_s0_rem_est (nxt_s0_rem_est[3]),
    .nxt_s1_rem_est (nxt_s1_rem_est[3]),
    .nxt_m_neg_1    (nxt_m_neg_1[3]),
    .nxt_m_neg_0    (nxt_m_neg_0[3]),
    .nxt_m_pos_1    (nxt_m_pos_1[3]),
    .nxt_m_pos_2    (nxt_m_pos_2[3])
  );

  // ---- 拼包（与拆包同一布局）----
  //   f16：{lane0 高 16, lane2, lane1 高 16, lane3}；f32：{lane0 高 28, 0000, lane1, 0000}；f64：{lane0, 8'b0}
  assign nxt_f_r_s = ({64{fp_fmt[0]}} & {l0_nxt_s[55:40], l2_nxt_s, l1_nxt_s[27:12], l3_nxt_s})
                   | ({64{fp_fmt[1]}} & {l0_nxt_s[55:28], 4'h0, l1_nxt_s, 4'h0})
                   | ({64{fp_fmt[2]}} & {l0_nxt_s, 8'h0});
  assign nxt_f_r_c = ({64{fp_fmt[0]}} & {l0_nxt_c[55:40], l2_nxt_c, l1_nxt_c[27:12], l3_nxt_c})
                   | ({64{fp_fmt[1]}} & {l0_nxt_c[55:28], 4'h0, l1_nxt_c, 4'h0})
                   | ({64{fp_fmt[2]}} & {l0_nxt_c, 8'h0});
  // 根只存去掉首位的低位（f16 每元素 14 位、f32 26 位、f64 54 位）
  assign nxt_rt_packed = ({56{fp_fmt[0]}} & {l0_nxt_rt[53:40], l2_nxt_rt[13:0], l1_nxt_rt[25:12], l3_nxt_rt[13:0]})
                       | ({56{fp_fmt[1]}} & {l0_nxt_rt[53:28], 2'b00, l1_nxt_rt[25:0], 2'b00})
                       | ({56{fp_fmt[2]}} & {l0_nxt_rt[53:0], 2'b00});
  // QM 去掉首两位（f16 每元素 13 位、f32 25 位、f64 53 位）
  assign nxt_rt_m1_packed = ({53{fp_fmt[0]}} & {l0_nxt_rt_m1[52:40], l2_nxt_rt_m1[12:0],
                                                l1_nxt_rt_m1[24:12], l3_nxt_rt_m1[12:0], 1'b0})
                          | ({53{fp_fmt[1]}} & {l0_nxt_rt_m1[52:28], 1'b0, l1_nxt_rt_m1[24:0], 2'b00})
                          | ({53{fp_fmt[2]}} & l0_nxt_rt_m1[52:0]);
endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper：逐 lane 的标量端口 <-> 核的数组端口
// -----------------------------------------------------------------------------
module fpsqrt_r16_block (
  input  logic [2:0]  fp_fmt_i,
  input  logic [63:0] f_r_s_i,
  input  logic [63:0] f_r_c_i,
  input  logic [55:0] rt_i,
  input  logic [52:0] rt_m1_i,
  input  logic [12:0] mask_i,
  input  logic [6:0]  nr_f_r_7b_for_nxt_cycle_s0_qds_0_i,
  input  logic [6:0]  nr_f_r_7b_for_nxt_cycle_s0_qds_1_i,
  input  logic [6:0]  nr_f_r_7b_for_nxt_cycle_s0_qds_2_i,
  input  logic [6:0]  nr_f_r_7b_for_nxt_cycle_s0_qds_3_i,
  input  logic [8:0]  nr_f_r_9b_for_nxt_cycle_s1_qds_0_i,
  input  logic [8:0]  nr_f_r_9b_for_nxt_cycle_s1_qds_1_i,
  input  logic [8:0]  nr_f_r_9b_for_nxt_cycle_s1_qds_2_i,
  input  logic [8:0]  nr_f_r_9b_for_nxt_cycle_s1_qds_3_i,
  input  logic [4:0]  m_neg_1_for_nxt_cycle_s0_qds_0_i,
  input  logic [4:0]  m_neg_1_for_nxt_cycle_s0_qds_1_i,
  input  logic [4:0]  m_neg_1_for_nxt_cycle_s0_qds_2_i,
  input  logic [4:0]  m_neg_1_for_nxt_cycle_s0_qds_3_i,
  input  logic [3:0]  m_neg_0_for_nxt_cycle_s0_qds_0_i,
  input  logic [3:0]  m_neg_0_for_nxt_cycle_s0_qds_1_i,
  input  logic [3:0]  m_neg_0_for_nxt_cycle_s0_qds_2_i,
  input  logic [3:0]  m_neg_0_for_nxt_cycle_s0_qds_3_i,
  input  logic [2:0]  m_pos_1_for_nxt_cycle_s0_qds_0_i,
  input  logic [2:0]  m_pos_1_for_nxt_cycle_s0_qds_1_i,
  input  logic [2:0]  m_pos_1_for_nxt_cycle_s0_qds_2_i,
  input  logic [2:0]  m_pos_1_for_nxt_cycle_s0_qds_3_i,
  input  logic [3:0]  m_pos_2_for_nxt_cycle_s0_qds_0_i,
  input  logic [3:0]  m_pos_2_for_nxt_cycle_s0_qds_1_i,
  input  logic [3:0]  m_pos_2_for_nxt_cycle_s0_qds_2_i,
  input  logic [3:0]  m_pos_2_for_nxt_cycle_s0_qds_3_i,
  output logic [55:0] nxt_rt_o,
  output logic [52:0] nxt_rt_m1_o,
  output logic [63:0] nxt_f_r_s_o,
  output logic [63:0] nxt_f_r_c_o,
  output logic [6:0]  adder_7b_res_for_nxt_cycle_s0_qds_0_o,
  output logic [6:0]  adder_7b_res_for_nxt_cycle_s0_qds_1_o,
  output logic [6:0]  adder_7b_res_for_nxt_cycle_s0_qds_2_o,
  output logic [6:0]  adder_7b_res_for_nxt_cycle_s0_qds_3_o,
  output logic [8:0]  adder_9b_res_for_nxt_cycle_s1_qds_0_o,
  output logic [8:0]  adder_9b_res_for_nxt_cycle_s1_qds_1_o,
  output logic [8:0]  adder_9b_res_for_nxt_cycle_s1_qds_2_o,
  output logic [8:0]  adder_9b_res_for_nxt_cycle_s1_qds_3_o,
  output logic [6:0]  m_neg_1_to_nxt_cycle_0_o,
  output logic [6:0]  m_neg_1_to_nxt_cycle_1_o,
  output logic [6:0]  m_neg_1_to_nxt_cycle_2_o,
  output logic [6:0]  m_neg_1_to_nxt_cycle_3_o,
  output logic [6:0]  m_neg_0_to_nxt_cycle_0_o,
  output logic [6:0]  m_neg_0_to_nxt_cycle_1_o,
  output logic [6:0]  m_neg_0_to_nxt_cycle_2_o,
  output logic [6:0]  m_neg_0_to_nxt_cycle_3_o,
  output logic [6:0]  m_pos_1_to_nxt_cycle_0_o,
  output logic [6:0]  m_pos_1_to_nxt_cycle_1_o,
  output logic [6:0]  m_pos_1_to_nxt_cycle_2_o,
  output logic [6:0]  m_pos_1_to_nxt_cycle_3_o,
  output logic [6:0]  m_pos_2_to_nxt_cycle_0_o,
  output logic [6:0]  m_pos_2_to_nxt_cycle_1_o,
  output logic [6:0]  m_pos_2_to_nxt_cycle_2_o,
  output logic [6:0]  m_pos_2_to_nxt_cycle_3_o
);
  logic [3:0][6:0] nxt_s0_rem_est, nxt_m_neg_1, nxt_m_neg_0, nxt_m_pos_1, nxt_m_pos_2;
  logic [3:0][8:0] nxt_s1_rem_est;

  xs_fpsqrt_r16_block_core u_core (
    .fp_fmt           (fp_fmt_i),
    .f_r_s            (f_r_s_i),
    .f_r_c            (f_r_c_i),
    .rt_packed        (rt_i),
    .rt_m1_packed     (rt_m1_i),
    .mask             (mask_i),
    .s0_rem_est       ({nr_f_r_7b_for_nxt_cycle_s0_qds_3_i, nr_f_r_7b_for_nxt_cycle_s0_qds_2_i,
                        nr_f_r_7b_for_nxt_cycle_s0_qds_1_i, nr_f_r_7b_for_nxt_cycle_s0_qds_0_i}),
    .s1_rem_est       ({nr_f_r_9b_for_nxt_cycle_s1_qds_3_i, nr_f_r_9b_for_nxt_cycle_s1_qds_2_i,
                        nr_f_r_9b_for_nxt_cycle_s1_qds_1_i, nr_f_r_9b_for_nxt_cycle_s1_qds_0_i}),
    .s0_m_neg_1_trunc ({m_neg_1_for_nxt_cycle_s0_qds_3_i, m_neg_1_for_nxt_cycle_s0_qds_2_i,
                        m_neg_1_for_nxt_cycle_s0_qds_1_i, m_neg_1_for_nxt_cycle_s0_qds_0_i}),
    .s0_m_neg_0_trunc ({m_neg_0_for_nxt_cycle_s0_qds_3_i, m_neg_0_for_nxt_cycle_s0_qds_2_i,
                        m_neg_0_for_nxt_cycle_s0_qds_1_i, m_neg_0_for_nxt_cycle_s0_qds_0_i}),
    .s0_m_pos_1_trunc ({m_pos_1_for_nxt_cycle_s0_qds_3_i, m_pos_1_for_nxt_cycle_s0_qds_2_i,
                        m_pos_1_for_nxt_cycle_s0_qds_1_i, m_pos_1_for_nxt_cycle_s0_qds_0_i}),
    .s0_m_pos_2_trunc ({m_pos_2_for_nxt_cycle_s0_qds_3_i, m_pos_2_for_nxt_cycle_s0_qds_2_i,
                        m_pos_2_for_nxt_cycle_s0_qds_1_i, m_pos_2_for_nxt_cycle_s0_qds_0_i}),
    .nxt_rt_packed    (nxt_rt_o),
    .nxt_rt_m1_packed (nxt_rt_m1_o),
    .nxt_f_r_s        (nxt_f_r_s_o),
    .nxt_f_r_c        (nxt_f_r_c_o),
    .nxt_s0_rem_est   (nxt_s0_rem_est),
    .nxt_s1_rem_est   (nxt_s1_rem_est),
    .nxt_m_neg_1      (nxt_m_neg_1),
    .nxt_m_neg_0      (nxt_m_neg_0),
    .nxt_m_pos_1      (nxt_m_pos_1),
    .nxt_m_pos_2      (nxt_m_pos_2)
  );

  assign adder_7b_res_for_nxt_cycle_s0_qds_0_o = nxt_s0_rem_est[0];
  assign adder_7b_res_for_nxt_cycle_s0_qds_1_o = nxt_s0_rem_est[1];
  assign adder_7b_res_for_nxt_cycle_s0_qds_2_o = nxt_s0_rem_est[2];
  assign adder_7b_res_for_nxt_cycle_s0_qds_3_o = nxt_s0_rem_est[3];
  assign adder_9b_res_for_nxt_cycle_s1_qds_0_o = nxt_s1_rem_est[0];
  assign adder_9b_res_for_nxt_cycle_s1_qds_1_o = nxt_s1_rem_est[1];
  assign adder_9b_res_for_nxt_cycle_s1_qds_2_o = nxt_s1_rem_est[2];
  assign adder_9b_res_for_nxt_cycle_s1_qds_3_o = nxt_s1_rem_est[3];
  assign m_neg_1_to_nxt_cycle_0_o = nxt_m_neg_1[0];
  assign m_neg_1_to_nxt_cycle_1_o = nxt_m_neg_1[1];
  assign m_neg_1_to_nxt_cycle_2_o = nxt_m_neg_1[2];
  assign m_neg_1_to_nxt_cycle_3_o = nxt_m_neg_1[3];
  assign m_neg_0_to_nxt_cycle_0_o = nxt_m_neg_0[0];
  assign m_neg_0_to_nxt_cycle_1_o = nxt_m_neg_0[1];
  assign m_neg_0_to_nxt_cycle_2_o = nxt_m_neg_0[2];
  assign m_neg_0_to_nxt_cycle_3_o = nxt_m_neg_0[3];
  assign m_pos_1_to_nxt_cycle_0_o = nxt_m_pos_1[0];
  assign m_pos_1_to_nxt_cycle_1_o = nxt_m_pos_1[1];
  assign m_pos_1_to_nxt_cycle_2_o = nxt_m_pos_1[2];
  assign m_pos_1_to_nxt_cycle_3_o = nxt_m_pos_1[3];
  assign m_pos_2_to_nxt_cycle_0_o = nxt_m_pos_2[0];
  assign m_pos_2_to_nxt_cycle_1_o = nxt_m_pos_2[1];
  assign m_pos_2_to_nxt_cycle_2_o = nxt_m_pos_2[2];
  assign m_pos_2_to_nxt_cycle_3_o = nxt_m_pos_2[3];
endmodule
