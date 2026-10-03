// =============================================================================
// SRT16Divint.sv —— SRT radix-16 整数除法器（16/32/64 位家族参数化核 + 16 位 wrapper）
//
// 在哪一层：VectorIdiv 的 16/32/64 位车道（_16bit_divide_0..3 / _32bit_divide_0..1 /
//   _64bit_divide_0..1）。每个实例除一对整数，sew 选元素宽度（00=8 … 11=64，不超过
//   本实例位宽），sign 选有/无符号。8 位车道另有 I8DivNr4。
//
// 握手与状态机（独热 stateReg，6 位，只有它异步复位；按「整字相等」逐态判断，同 golden）：
//   IDLE --in_valid--> PRE0 --> PRE1 --early_finish--> POST --> OUTPUT --out_ready--> IDLE
//                                  \--否则--> ITER（iter_num 拍）--> POST
//   flush 任意态回 IDLE。golden 无 div_ready / d_zero 输出（父级不用，firtool 删了端口）。
//
// 各级做什么（§2–§6）：
//   握手拍：按 sew 把被除数/除数扩成 64 位（有符号符号扩展），取绝对值存 abs_x/abs_d。
//   PRE0  ：前导零计数 lzc_x/lzc_d；先按 4 的倍数左移做「粗规格化」暂存进 iter_q_A/B，
//           lzc 低 2 位、零判断、d==1、lzc 差等杂项打包存进 iterB_reg（寄存器复用）。
//   PRE1  ：再按 lzc 低 2 位左移完成规格化（d 最高位为 1）；判提前结束（|x|<|d|、d=0、
//           d=1）；按 lzc 差的低 2 位把 x 右对齐成初始余数；查 SRT4qdsCons 得 4 条阈值；
//           预算所有迭代常数（−q·d 的整宽/截断、Sel/Spec 比较常数）存寄存器；迭代拍数
//           = ceil(lzc 差 / 4)（每拍出 4 位商）。
//   ITER  ：IterBlock 每拍出两个 radix-4 商位（见 IterBlock_v4.sv 的 SRT 原理）。
//   POST  ：余数 carry-save 两半相加（被除数为负时取反加 2 = 两个补码取负之和），
//           另备一份 +d 的修正值；商按符号取补（A=Q 与 B=Q−1 两份都取补）。
//   OUTPUT：最终余数符号不对就选「+d 修正后的余数 + Q−1」，余数再按 lzc_d 右移回原位。
//
// ★bug-for-bug 要点★（全部照 Scala/golden，不"修"）
//   · 寄存器复用：iterB_reg 在 PRE0 存 lzc 打包字、PRE1 起存余数；iter_q_A/B 在 PRE0 存
//     粗规格化的 x/d，PRE1 起存 on-the-fly 商 A/B。
//   · 共享取负器 neg_x_q / neg_d_q：握手拍对扩展后的输入取负，其余时刻对 iter_q_A/B 取负。
//   · 前导零计数对全 0 输入给 BIT_WIDTH−1（Chisel PriorityEncoder 的缺省），d=0 与 d=1
//     的 lzc 相同，d_is_one 用「lzc 全 1」判，故 d=0 也会置 d_is_one（再由 d_zero 区分）。
//   · iter_finish 看的是寄存器 iter_num_reg（不是本拍的 iter_num）。
//   · 商位 0 对应的常数（iter_cons[2]、spec_r2ud[2]）恒 0，golden 没有这两个寄存器；
//     本核只存 4 个非零档（*_nz_reg，下标 0..3 = 商位 +2,+1,−1,−2）。
//
// 子模块（两侧白盒，本仓已签核重写件）：SRT4qdsCons ×1；IterBlock_v4 / _4 / _6 ×1（按位宽）。
// 设计源：yunsuan/src/main/scala/yunsuan/vector/VectorIdiv/SRT16Divint.scala (class SRT16Divint)
// golden 对照：G1-canonical/golden-rtl/SRT16Divint{,_4,_6}.sv
// 核内 IterBlock 的扁平端口连线由 scripts/gen_srt16divint.py 生成（GENERATED 区）。
// =============================================================================

// -----------------------------------------------------------------------------
// xs_SRT16Divint_core —— 参数化可读核（BIT_WIDTH = 16 / 32 / 64）
// -----------------------------------------------------------------------------
module xs_SRT16Divint_core #(
  parameter int BIT_WIDTH = 16
) (
  input  logic                 clock,
  input  logic                 reset,          // 异步、高有效（只复位状态机）
  input  logic                 sign,
  input  logic [BIT_WIDTH-1:0] dividend,
  input  logic [BIT_WIDTH-1:0] divisor,
  input  logic                 flush,
  input  logic [1:0]           sew,            // 00=8 01=16 10=32 11=64 位元素
  input  logic                 div_in_valid,
  input  logic                 div_out_ready,
  output logic                 div_out_valid,
  output logic [BIT_WIDTH-1:0] div_out_q,
  output logic [BIT_WIDTH-1:0] div_out_rem
);
  localparam int W        = BIT_WIDTH + 6;           // 余数宽：1 符号 + 2 移位余量 + 3 对齐
  localparam int LZC_W    = $clog2(BIT_WIDTH);       // 前导零计数宽 4/5/6
  localparam int ITER_N_W = LZC_W - 2;               // 迭代计数宽（每拍 4 位商）

  // ---------------------------------------------------------------------------
  // §1 独热状态机（按整字相等逐态判断；无匹配则保持）
  // ---------------------------------------------------------------------------
  localparam int S_IDLE = 0, S_PRE0 = 1, S_PRE1 = 2, S_ITER = 3, S_POST = 4, S_OUTPUT = 5;
  localparam logic [5:0] OH_IDLE   = 6'h01;
  localparam logic [5:0] OH_PRE0   = 6'h02;
  localparam logic [5:0] OH_PRE1   = 6'h04;
  localparam logic [5:0] OH_ITER   = 6'h08;
  localparam logic [5:0] OH_POST   = 6'h10;
  localparam logic [5:0] OH_OUTPUT = 6'h20;

  logic [5:0] stateReg;
  logic       in_pre0, in_pre1, in_iter, in_post, in_handshake;
  logic       early_finish, iter_finish;
  assign in_pre0       = stateReg[S_PRE0];
  assign in_pre1       = stateReg[S_PRE1];
  assign in_iter       = stateReg[S_ITER];
  assign in_post       = stateReg[S_POST];
  assign in_handshake  = div_in_valid & stateReg[S_IDLE];   // div_ready = IDLE
  assign div_out_valid = stateReg[S_OUTPUT];

  always_ff @(posedge clock or posedge reset) begin
    if (reset)      stateReg <= OH_IDLE;
    else if (flush) stateReg <= OH_IDLE;
    else begin
      case (stateReg)
        OH_IDLE:   if (in_handshake) stateReg <= OH_PRE0;
        OH_PRE0:   stateReg <= OH_PRE1;
        OH_PRE1:   stateReg <= early_finish ? OH_POST : OH_ITER;
        OH_ITER:   stateReg <= iter_finish  ? OH_POST : OH_ITER;
        OH_POST:   stateReg <= OH_OUTPUT;
        OH_OUTPUT: if (div_out_ready) stateReg <= OH_IDLE;
        default:   ;
      endcase
    end
  end

  // 全部数据寄存器（无复位），名字与 golden 对齐；Vec 寄存器用数组
  logic                 x_sign_reg, q_sign_reg, zero_d_reg, early_finish_q;
  logic [BIT_WIDTH-1:0] abs_x_reg, abs_d_reg;
  logic [BIT_WIDTH-1:0] iter_q_A_reg, iter_q_B_reg;     // PRE0: 粗规格化 x/d；之后: 商 A/B
  logic [W-1:0]         iterB_reg [0:1];                // PRE0: lzc 打包字；之后: 余数 sum/carry
  logic [LZC_W-1:0]     lzc_d_reg;
  logic [ITER_N_W-1:0]  iter_num_reg;
  logic [7:0]           sel_reg  [0:3][0:1];
  logic [8:0]           spec_reg [0:4][0:3][0:1];
  logic [W-1:0]         iter_cons_nz_reg  [0:3];        // −q·d，q = +2,+1,−1,−2
  logic [10:0]          spec_r2ud_nz_reg  [0:3];        // −16·q·d 截断 11 位
  logic [8:0]           d_trunc_reg       [0:3];        // −4·u·d 截断 9 位（投机用）
  logic [7:0]           sel_cons_reg  [0:4][0:3];
  logic [8:0]           spec_cons_reg [0:4][0:3];
  logic [BIT_WIDTH-1:0] q_A_sign_c_reg, q_B_sign_c_reg;
  logic [W-1:0]         Bypass_final_rem_reg, Bypass_final_rem_plus_d_reg;

  // ---------------------------------------------------------------------------
  // §2 握手拍：按 sew 扩展输入、取绝对值（共享取负器）
  // ---------------------------------------------------------------------------
  // 按元素宽度把输入扩成 64 位（有符号时符号扩展），与 Chisel MuxCase 逐项一致
  function automatic logic [63:0] extend_by_sew(input logic [63:0] v, input logic [1:0] s,
                                                input logic sgn);
    case (s)
      2'd0:    return sgn ? {{56{v[7]}},  v[7:0]}  : {56'd0, v[7:0]};
      2'd1:    return sgn ? {{48{v[15]}}, v[15:0]} : {48'd0, v[15:0]};
      2'd2:    return sgn ? {{32{v[31]}}, v[31:0]} : {32'd0, v[31:0]};
      default: return v;
    endcase
  endfunction
  function automatic logic sign_bit_by_sew(input logic [63:0] v, input logic [1:0] s);
    case (s)
      2'd0:    return v[7];
      2'd1:    return v[15];
      2'd2:    return v[31];
      default: return v[63];
    endcase
  endfunction

  logic [63:0]          x64, d64;
  logic [BIT_WIDTH-1:0] ext_x, ext_d, neg_x_q, neg_d_q, abs_x, abs_d;
  logic                 x_sign, d_sign;
  assign x64     = 64'(dividend);                      // 高位补 0（位宽 < 64 时）
  assign d64     = 64'(divisor);
  assign ext_x   = BIT_WIDTH'(extend_by_sew(x64, sew, sign));
  assign ext_d   = BIT_WIDTH'(extend_by_sew(d64, sew, sign));
  assign x_sign  = sign & sign_bit_by_sew(x64, sew);
  assign d_sign  = sign & sign_bit_by_sew(d64, sew);
  assign neg_x_q = BIT_WIDTH'(0 - (in_handshake ? ext_x : iter_q_A_reg));
  assign neg_d_q = BIT_WIDTH'(0 - (in_handshake ? ext_d : iter_q_B_reg));
  assign abs_x   = x_sign ? neg_x_q : ext_x;
  assign abs_d   = d_sign ? neg_d_q : ext_d;

  always_ff @(posedge clock) begin
    if (in_handshake) begin
      abs_x_reg <= abs_x;
      abs_d_reg <= abs_d;
    end
  end

  // ---------------------------------------------------------------------------
  // §3 PRE0：前导零计数、粗规格化（按 4 的倍数左移）、杂项打包
  // ---------------------------------------------------------------------------
  // 前导零个数；全 0 时给 BIT_WIDTH−1（Chisel PriorityEncoder 缺省取最后一个下标）
  function automatic logic [LZC_W-1:0] lead_zeros(input logic [BIT_WIDTH-1:0] v);
    lead_zeros = LZC_W'(BIT_WIDTH - 1);
    for (int i = 0; i < BIT_WIDTH; i++)
      if (v[i]) lead_zeros = LZC_W'(BIT_WIDTH - 1 - i);
  endfunction

  logic [LZC_W-1:0]     lzc_x, lzc_d;
  logic                 zero_x, zero_d, d_is_one;
  logic [LZC_W:0]       lzc_diff;                       // lzc_d − lzc_x，带 1 位符号
  logic [13:0]          lzc_pre0_all;
  logic [BIT_WIDTH-1:0] norm_x_part, norm_d_part;
  assign lzc_x    = lead_zeros(abs_x_reg);
  assign lzc_d    = lead_zeros(abs_d_reg);
  assign zero_x   = abs_x_reg == '0;
  assign zero_d   = abs_d_reg == '0;
  assign d_is_one = &lzc_d;
  assign lzc_diff = {1'b0, lzc_d} - {1'b0, lzc_x};
  // 打包字（存进 iterB_reg 两份，PRE1 读 [0]）：
  //   [13] zero_x  [12:11] lzc_x 低 2 位  [10] zero_d  [9] d_is_one
  //   [8:7] lzc_d 低 2 位  [6:0] lzc_diff 符号扩展到 7 位
  assign lzc_pre0_all = {zero_x, lzc_x[1:0], zero_d, d_is_one, lzc_d[1:0], 7'($signed(lzc_diff))};
  // 粗规格化：先移 lzc 的 4 的倍数部分（低 2 位留到 PRE1）
  assign norm_x_part  = BIT_WIDTH'(abs_x_reg << {lzc_x[LZC_W-1:2], 2'b00});
  assign norm_d_part  = BIT_WIDTH'(abs_d_reg << {lzc_d[LZC_W-1:2], 2'b00});

  always_ff @(posedge clock) begin
    if (in_pre0) begin
      x_sign_reg <= x_sign;          // 操作数在整个除法期间保持（VectorIdiv 用寄存器喂）
      q_sign_reg <= x_sign ^ d_sign;
      lzc_d_reg  <= lzc_d;
      zero_d_reg <= zero_d;
    end
  end

  // ---------------------------------------------------------------------------
  // §4 PRE1：完成规格化、特殊情况、对齐初始余数、预算常数
  // ---------------------------------------------------------------------------
  logic [1:0]             lzc_x_1_0, lzc_d_1_0;
  logic [LZC_W:0]         lzc_diff_pre_1;
  logic [BIT_WIDTH+2:0]   norm_x, norm_d;              // 规格化后的 x、d（d 最高位为 1）
  logic                   x_small, d_zero, d_one;
  assign lzc_x_1_0      = iterB_reg[0][12:11];
  assign lzc_d_1_0      = iterB_reg[0][8:7];
  assign lzc_diff_pre_1 = iterB_reg[0][LZC_W:0];
  assign norm_x         = {3'b000, iter_q_A_reg} << lzc_x_1_0;
  assign norm_d         = {3'b000, iter_q_B_reg} << lzc_d_1_0;
  assign x_small        = lzc_diff_pre_1[LZC_W];       // lzc_d < lzc_x ⇒ |x| < |d|
  assign d_zero         = iterB_reg[0][10];
  assign d_one          = iterB_reg[0][9];
  assign early_finish   = x_small | d_zero | d_one;

  // 提前结束的商/余数：|x|<|d| → 0 / |x|；d=0 → 全 1 / |x|；d=1 → |x| / 0
  logic [BIT_WIDTH-1:0] early_q;
  logic [W-1:0]         early_rem;
  assign early_q   = x_small ? '0 : (d_zero ? '1 : abs_x_reg);
  assign early_rem = W'((x_small | d_zero) ? {abs_x_reg, 2'b00} : '0);

  // 迭代拍数 = ceil(lzc_diff / 4)；iter_finish 看寄存器（golden 同）
  logic [ITER_N_W-1:0] init_iter, iter_num;
  assign init_iter   = ITER_N_W'((lzc_diff_pre_1 >> 2) + (&lzc_diff_pre_1[1:0]));
  assign iter_num    = in_pre1 ? init_iter : ITER_N_W'(iter_num_reg - 1'b1);
  assign iter_finish = iter_num_reg == '0;

  // 初始余数：x 按 lzc_diff 低 2 位右对齐（使迭代拍数取整到 4 位一拍）；carry 半边为 0
  logic [W-1:0] w_align_init [0:1];
  always_comb begin
    case (lzc_diff_pre_1[1:0])
      2'd0:    w_align_init[0] = {2'b00, norm_x, 1'b0};
      2'd1:    w_align_init[0] = {1'b0, norm_x, 2'b00};
      2'd2:    w_align_init[0] = {norm_x, 3'b000};
      default: w_align_init[0] = {3'b000, norm_x};
    endcase
    w_align_init[1] = '0;
  end

  // 选择阈值 m_{-1}, m_0, m_1, m_2（按规格化 d 的高 3 位查表）
  logic [8:0] neg_m [0:3];
  SRT4qdsCons qds_cons (
    .io_d_trunc_3 (norm_d[BIT_WIDTH-2 -: 3]),
    .io_m_neg_1   (neg_m[0]),
    .io_m_neg_0   (neg_m[1]),
    .io_m_pos_1   (neg_m[2]),
    .io_m_pos_2   (neg_m[3])
  );

  // 迭代常数。iter_cons[u] = −q_u·d（q_u = 2−u），W 位定点 000.xxxx；u=2 恒 0
  logic [BIT_WIDTH+3:0] d_ext, neg_d_ext;
  logic [W-1:0]         iter_cons [0:4];
  logic [8:0]           rud  [0:4];                    // 4·(−q·d)，3+6 截断
  logic [8:0]           r2ud [0:4];                    // 16·(−q·d)，3+6 截断
  logic [10:0]          spec_r2ud [0:4];               // 16·(−q·d)，3+8 截断
  logic [7:0]           sel_cons  [0:4][0:3];          // rud − m_k（Sel 用，3+5）
  logic [8:0]           spec_cons [0:4][0:3];          // r2ud − m_k（Spec 用，3+6）
  assign d_ext        = {1'b0, norm_d};
  assign neg_d_ext    = 0 - d_ext;
  assign iter_cons[0] = {neg_d_ext[BIT_WIDTH+1:0], 4'b0000};   // q=+2：−2d
  assign iter_cons[1] = {neg_d_ext[BIT_WIDTH+2:0], 3'b000};    // q=+1：−d
  assign iter_cons[2] = '0;                                     // q= 0
  assign iter_cons[3] = {d_ext[BIT_WIDTH+2:0], 3'b000};        // q=−1：+d
  assign iter_cons[4] = {d_ext[BIT_WIDTH+1:0], 4'b0000};       // q=−2：+2d
  always_comb begin
    for (int u = 0; u < 5; u++) begin
      rud[u]       = iter_cons[u][W-3 -: 9];
      r2ud[u]      = iter_cons[u][W-5 -: 9];
      spec_r2ud[u] = iter_cons[u][W-5 -: 11];
      for (int k = 0; k < 4; k++) begin
        sel_cons[u][k]  = 8'(rud[u][8:1] + neg_m[k][8:1]);
        spec_cons[u][k] = 9'(r2ud[u] + neg_m[k]);
      end
    end
  end

  // 非零档下标 0..3 ↔ 商位下标 0,1,3,4
  localparam int NZ_DIGIT [0:3] = '{0, 1, 3, 4};

  always_ff @(posedge clock) begin
    if (in_pre1) begin
      early_finish_q <= early_finish;
      for (int n = 0; n < 4; n++) begin
        iter_cons_nz_reg[n] <= iter_cons[NZ_DIGIT[n]];
        spec_r2ud_nz_reg[n] <= spec_r2ud[NZ_DIGIT[n]];
        d_trunc_reg[n]      <= rud[NZ_DIGIT[n]];
      end
      for (int u = 0; u < 5; u++)
        for (int k = 0; k < 4; k++) begin
          sel_cons_reg[u][k]  <= sel_cons[u][k];
          spec_cons_reg[u][k] <= spec_cons[u][k];
        end
    end
  end

  // ---------------------------------------------------------------------------
  // §5 ITER：IterBlock 一拍两商位；PRE1 给迭代寄存器装初值
  //   Sel 初值：4 对 = (初始余数高 8 位, −m_k)；Spec 初值：5×4 对 =
  //   (初始余数 ×4 的高 9 位, {sel_cons[u][k], 0})——首拍 q2 依赖的那份常数已含 −m_k。
  // ---------------------------------------------------------------------------
  logic [BIT_WIDTH-1:0] nxt_q_A, nxt_q_B;
  logic [7:0]           nxt_sel  [0:3][0:1];
  logic [8:0]           nxt_spec [0:4][0:3][0:1];
  logic [W-1:0]         nxt_iterB [0:1];

  always_ff @(posedge clock) begin
    if (in_pre0 | in_pre1 | in_iter) begin
      iter_q_A_reg <= in_pre0 ? norm_x_part : in_pre1 ? (early_finish ? early_q : '0) : nxt_q_A;
      iter_q_B_reg <= in_pre0 ? norm_d_part : in_pre1 ? '0 : nxt_q_B;
      for (int i = 0; i < 2; i++)
        iterB_reg[i] <= in_pre0 ? W'(lzc_pre0_all)
                      : in_pre1 ? (early_finish ? early_rem : w_align_init[i])
                      : nxt_iterB[i];
    end
    if (in_pre1 | in_iter) begin
      iter_num_reg <= iter_num;
      for (int k = 0; k < 4; k++) begin
        sel_reg[k][0] <= in_pre1 ? w_align_init[0][W-1 -: 8] : nxt_sel[k][0];
        sel_reg[k][1] <= in_pre1 ? neg_m[k][8:1]            : nxt_sel[k][1];
      end
      for (int u = 0; u < 5; u++)
        for (int k = 0; k < 4; k++) begin
          spec_reg[u][k][0] <= in_pre1 ? w_align_init[0][W-3 -: 9]   : nxt_spec[u][k][0];
          spec_reg[u][k][1] <= in_pre1 ? {sel_cons[u][k], 1'b0}      : nxt_spec[u][k][1];
        end
    end
  end

  // 按位宽挑 IterBlock 变体（端口扁平，连线由生成器展开）
  // BEGIN GENERATED(srt16divint-iterblock)
  if (BIT_WIDTH == 16) begin : g_w16
    IterBlock_v4 IterBlock (
      .io_Sel_cons_0_0   (sel_cons_reg[0][0]),
      .io_Sel_cons_0_1   (sel_cons_reg[0][1]),
      .io_Sel_cons_0_2   (sel_cons_reg[0][2]),
      .io_Sel_cons_0_3   (sel_cons_reg[0][3]),
      .io_Sel_cons_1_0   (sel_cons_reg[1][0]),
      .io_Sel_cons_1_1   (sel_cons_reg[1][1]),
      .io_Sel_cons_1_2   (sel_cons_reg[1][2]),
      .io_Sel_cons_1_3   (sel_cons_reg[1][3]),
      .io_Sel_cons_2_0   (sel_cons_reg[2][0]),
      .io_Sel_cons_2_1   (sel_cons_reg[2][1]),
      .io_Sel_cons_2_2   (sel_cons_reg[2][2]),
      .io_Sel_cons_2_3   (sel_cons_reg[2][3]),
      .io_Sel_cons_3_0   (sel_cons_reg[3][0]),
      .io_Sel_cons_3_1   (sel_cons_reg[3][1]),
      .io_Sel_cons_3_2   (sel_cons_reg[3][2]),
      .io_Sel_cons_3_3   (sel_cons_reg[3][3]),
      .io_Sel_cons_4_0   (sel_cons_reg[4][0]),
      .io_Sel_cons_4_1   (sel_cons_reg[4][1]),
      .io_Sel_cons_4_2   (sel_cons_reg[4][2]),
      .io_Sel_cons_4_3   (sel_cons_reg[4][3]),
      .io_Spec_cons_0_0  (spec_cons_reg[0][0]),
      .io_Spec_cons_0_1  (spec_cons_reg[0][1]),
      .io_Spec_cons_0_2  (spec_cons_reg[0][2]),
      .io_Spec_cons_0_3  (spec_cons_reg[0][3]),
      .io_Spec_cons_1_0  (spec_cons_reg[1][0]),
      .io_Spec_cons_1_1  (spec_cons_reg[1][1]),
      .io_Spec_cons_1_2  (spec_cons_reg[1][2]),
      .io_Spec_cons_1_3  (spec_cons_reg[1][3]),
      .io_Spec_cons_2_0  (spec_cons_reg[2][0]),
      .io_Spec_cons_2_1  (spec_cons_reg[2][1]),
      .io_Spec_cons_2_2  (spec_cons_reg[2][2]),
      .io_Spec_cons_2_3  (spec_cons_reg[2][3]),
      .io_Spec_cons_3_0  (spec_cons_reg[3][0]),
      .io_Spec_cons_3_1  (spec_cons_reg[3][1]),
      .io_Spec_cons_3_2  (spec_cons_reg[3][2]),
      .io_Spec_cons_3_3  (spec_cons_reg[3][3]),
      .io_Spec_cons_4_0  (spec_cons_reg[4][0]),
      .io_Spec_cons_4_1  (spec_cons_reg[4][1]),
      .io_Spec_cons_4_2  (spec_cons_reg[4][2]),
      .io_Spec_cons_4_3  (spec_cons_reg[4][3]),
      .io_iter_cons_0    (iter_cons_nz_reg[0]),
      .io_iter_cons_1    (iter_cons_nz_reg[1]),
      .io_iter_cons_3    (iter_cons_nz_reg[2]),
      .io_iter_cons_4    (iter_cons_nz_reg[3]),
      .io_d_trunc_0      (d_trunc_reg[0]),
      .io_d_trunc_1      (d_trunc_reg[1]),
      .io_d_trunc_2      (d_trunc_reg[2]),
      .io_d_trunc_3      (d_trunc_reg[3]),
      .io_spec_r2ud_0    (spec_r2ud_nz_reg[0]),
      .io_spec_r2ud_1    (spec_r2ud_nz_reg[1]),
      .io_spec_r2ud_3    (spec_r2ud_nz_reg[2]),
      .io_spec_r2ud_4    (spec_r2ud_nz_reg[3]),
      .io_pre_q_A        (iter_q_A_reg),
      .io_pre_q_B        (iter_q_B_reg),
      .io_nxt_q_A        (nxt_q_A),
      .io_nxt_q_B        (nxt_q_B),
      .io_pre_sel_0_0    (sel_reg[0][0]),
      .io_pre_sel_0_1    (sel_reg[0][1]),
      .io_pre_sel_1_0    (sel_reg[1][0]),
      .io_pre_sel_1_1    (sel_reg[1][1]),
      .io_pre_sel_2_0    (sel_reg[2][0]),
      .io_pre_sel_2_1    (sel_reg[2][1]),
      .io_pre_sel_3_0    (sel_reg[3][0]),
      .io_pre_sel_3_1    (sel_reg[3][1]),
      .io_nxt_sel_0_0    (nxt_sel[0][0]),
      .io_nxt_sel_0_1    (nxt_sel[0][1]),
      .io_nxt_sel_1_0    (nxt_sel[1][0]),
      .io_nxt_sel_1_1    (nxt_sel[1][1]),
      .io_nxt_sel_2_0    (nxt_sel[2][0]),
      .io_nxt_sel_2_1    (nxt_sel[2][1]),
      .io_nxt_sel_3_0    (nxt_sel[3][0]),
      .io_nxt_sel_3_1    (nxt_sel[3][1]),
      .io_pre_spec_0_0_0 (spec_reg[0][0][0]),
      .io_pre_spec_0_0_1 (spec_reg[0][0][1]),
      .io_pre_spec_0_1_0 (spec_reg[0][1][0]),
      .io_pre_spec_0_1_1 (spec_reg[0][1][1]),
      .io_pre_spec_0_2_0 (spec_reg[0][2][0]),
      .io_pre_spec_0_2_1 (spec_reg[0][2][1]),
      .io_pre_spec_0_3_0 (spec_reg[0][3][0]),
      .io_pre_spec_0_3_1 (spec_reg[0][3][1]),
      .io_pre_spec_1_0_0 (spec_reg[1][0][0]),
      .io_pre_spec_1_0_1 (spec_reg[1][0][1]),
      .io_pre_spec_1_1_0 (spec_reg[1][1][0]),
      .io_pre_spec_1_1_1 (spec_reg[1][1][1]),
      .io_pre_spec_1_2_0 (spec_reg[1][2][0]),
      .io_pre_spec_1_2_1 (spec_reg[1][2][1]),
      .io_pre_spec_1_3_0 (spec_reg[1][3][0]),
      .io_pre_spec_1_3_1 (spec_reg[1][3][1]),
      .io_pre_spec_2_0_0 (spec_reg[2][0][0]),
      .io_pre_spec_2_0_1 (spec_reg[2][0][1]),
      .io_pre_spec_2_1_0 (spec_reg[2][1][0]),
      .io_pre_spec_2_1_1 (spec_reg[2][1][1]),
      .io_pre_spec_2_2_0 (spec_reg[2][2][0]),
      .io_pre_spec_2_2_1 (spec_reg[2][2][1]),
      .io_pre_spec_2_3_0 (spec_reg[2][3][0]),
      .io_pre_spec_2_3_1 (spec_reg[2][3][1]),
      .io_pre_spec_3_0_0 (spec_reg[3][0][0]),
      .io_pre_spec_3_0_1 (spec_reg[3][0][1]),
      .io_pre_spec_3_1_0 (spec_reg[3][1][0]),
      .io_pre_spec_3_1_1 (spec_reg[3][1][1]),
      .io_pre_spec_3_2_0 (spec_reg[3][2][0]),
      .io_pre_spec_3_2_1 (spec_reg[3][2][1]),
      .io_pre_spec_3_3_0 (spec_reg[3][3][0]),
      .io_pre_spec_3_3_1 (spec_reg[3][3][1]),
      .io_pre_spec_4_0_0 (spec_reg[4][0][0]),
      .io_pre_spec_4_0_1 (spec_reg[4][0][1]),
      .io_pre_spec_4_1_0 (spec_reg[4][1][0]),
      .io_pre_spec_4_1_1 (spec_reg[4][1][1]),
      .io_pre_spec_4_2_0 (spec_reg[4][2][0]),
      .io_pre_spec_4_2_1 (spec_reg[4][2][1]),
      .io_pre_spec_4_3_0 (spec_reg[4][3][0]),
      .io_pre_spec_4_3_1 (spec_reg[4][3][1]),
      .io_nxt_spec_0_0_0 (nxt_spec[0][0][0]),
      .io_nxt_spec_0_0_1 (nxt_spec[0][0][1]),
      .io_nxt_spec_0_1_0 (nxt_spec[0][1][0]),
      .io_nxt_spec_0_1_1 (nxt_spec[0][1][1]),
      .io_nxt_spec_0_2_0 (nxt_spec[0][2][0]),
      .io_nxt_spec_0_2_1 (nxt_spec[0][2][1]),
      .io_nxt_spec_0_3_0 (nxt_spec[0][3][0]),
      .io_nxt_spec_0_3_1 (nxt_spec[0][3][1]),
      .io_nxt_spec_1_0_0 (nxt_spec[1][0][0]),
      .io_nxt_spec_1_0_1 (nxt_spec[1][0][1]),
      .io_nxt_spec_1_1_0 (nxt_spec[1][1][0]),
      .io_nxt_spec_1_1_1 (nxt_spec[1][1][1]),
      .io_nxt_spec_1_2_0 (nxt_spec[1][2][0]),
      .io_nxt_spec_1_2_1 (nxt_spec[1][2][1]),
      .io_nxt_spec_1_3_0 (nxt_spec[1][3][0]),
      .io_nxt_spec_1_3_1 (nxt_spec[1][3][1]),
      .io_nxt_spec_2_0_0 (nxt_spec[2][0][0]),
      .io_nxt_spec_2_0_1 (nxt_spec[2][0][1]),
      .io_nxt_spec_2_1_0 (nxt_spec[2][1][0]),
      .io_nxt_spec_2_1_1 (nxt_spec[2][1][1]),
      .io_nxt_spec_2_2_0 (nxt_spec[2][2][0]),
      .io_nxt_spec_2_2_1 (nxt_spec[2][2][1]),
      .io_nxt_spec_2_3_0 (nxt_spec[2][3][0]),
      .io_nxt_spec_2_3_1 (nxt_spec[2][3][1]),
      .io_nxt_spec_3_0_0 (nxt_spec[3][0][0]),
      .io_nxt_spec_3_0_1 (nxt_spec[3][0][1]),
      .io_nxt_spec_3_1_0 (nxt_spec[3][1][0]),
      .io_nxt_spec_3_1_1 (nxt_spec[3][1][1]),
      .io_nxt_spec_3_2_0 (nxt_spec[3][2][0]),
      .io_nxt_spec_3_2_1 (nxt_spec[3][2][1]),
      .io_nxt_spec_3_3_0 (nxt_spec[3][3][0]),
      .io_nxt_spec_3_3_1 (nxt_spec[3][3][1]),
      .io_nxt_spec_4_0_0 (nxt_spec[4][0][0]),
      .io_nxt_spec_4_0_1 (nxt_spec[4][0][1]),
      .io_nxt_spec_4_1_0 (nxt_spec[4][1][0]),
      .io_nxt_spec_4_1_1 (nxt_spec[4][1][1]),
      .io_nxt_spec_4_2_0 (nxt_spec[4][2][0]),
      .io_nxt_spec_4_2_1 (nxt_spec[4][2][1]),
      .io_nxt_spec_4_3_0 (nxt_spec[4][3][0]),
      .io_nxt_spec_4_3_1 (nxt_spec[4][3][1]),
      .io_pre_iterB_0    (iterB_reg[0]),
      .io_pre_iterB_1    (iterB_reg[1]),
      .io_nxt_iterB_0    (nxt_iterB[0]),
      .io_nxt_iterB_1    (nxt_iterB[1])
    );
  end else if (BIT_WIDTH == 32) begin : g_w32
    IterBlock_v4_4 IterBlock (
      .io_Sel_cons_0_0   (sel_cons_reg[0][0]),
      .io_Sel_cons_0_1   (sel_cons_reg[0][1]),
      .io_Sel_cons_0_2   (sel_cons_reg[0][2]),
      .io_Sel_cons_0_3   (sel_cons_reg[0][3]),
      .io_Sel_cons_1_0   (sel_cons_reg[1][0]),
      .io_Sel_cons_1_1   (sel_cons_reg[1][1]),
      .io_Sel_cons_1_2   (sel_cons_reg[1][2]),
      .io_Sel_cons_1_3   (sel_cons_reg[1][3]),
      .io_Sel_cons_2_0   (sel_cons_reg[2][0]),
      .io_Sel_cons_2_1   (sel_cons_reg[2][1]),
      .io_Sel_cons_2_2   (sel_cons_reg[2][2]),
      .io_Sel_cons_2_3   (sel_cons_reg[2][3]),
      .io_Sel_cons_3_0   (sel_cons_reg[3][0]),
      .io_Sel_cons_3_1   (sel_cons_reg[3][1]),
      .io_Sel_cons_3_2   (sel_cons_reg[3][2]),
      .io_Sel_cons_3_3   (sel_cons_reg[3][3]),
      .io_Sel_cons_4_0   (sel_cons_reg[4][0]),
      .io_Sel_cons_4_1   (sel_cons_reg[4][1]),
      .io_Sel_cons_4_2   (sel_cons_reg[4][2]),
      .io_Sel_cons_4_3   (sel_cons_reg[4][3]),
      .io_Spec_cons_0_0  (spec_cons_reg[0][0]),
      .io_Spec_cons_0_1  (spec_cons_reg[0][1]),
      .io_Spec_cons_0_2  (spec_cons_reg[0][2]),
      .io_Spec_cons_0_3  (spec_cons_reg[0][3]),
      .io_Spec_cons_1_0  (spec_cons_reg[1][0]),
      .io_Spec_cons_1_1  (spec_cons_reg[1][1]),
      .io_Spec_cons_1_2  (spec_cons_reg[1][2]),
      .io_Spec_cons_1_3  (spec_cons_reg[1][3]),
      .io_Spec_cons_2_0  (spec_cons_reg[2][0]),
      .io_Spec_cons_2_1  (spec_cons_reg[2][1]),
      .io_Spec_cons_2_2  (spec_cons_reg[2][2]),
      .io_Spec_cons_2_3  (spec_cons_reg[2][3]),
      .io_Spec_cons_3_0  (spec_cons_reg[3][0]),
      .io_Spec_cons_3_1  (spec_cons_reg[3][1]),
      .io_Spec_cons_3_2  (spec_cons_reg[3][2]),
      .io_Spec_cons_3_3  (spec_cons_reg[3][3]),
      .io_Spec_cons_4_0  (spec_cons_reg[4][0]),
      .io_Spec_cons_4_1  (spec_cons_reg[4][1]),
      .io_Spec_cons_4_2  (spec_cons_reg[4][2]),
      .io_Spec_cons_4_3  (spec_cons_reg[4][3]),
      .io_iter_cons_0    (iter_cons_nz_reg[0]),
      .io_iter_cons_1    (iter_cons_nz_reg[1]),
      .io_iter_cons_3    (iter_cons_nz_reg[2]),
      .io_iter_cons_4    (iter_cons_nz_reg[3]),
      .io_d_trunc_0      (d_trunc_reg[0]),
      .io_d_trunc_1      (d_trunc_reg[1]),
      .io_d_trunc_2      (d_trunc_reg[2]),
      .io_d_trunc_3      (d_trunc_reg[3]),
      .io_spec_r2ud_0    (spec_r2ud_nz_reg[0]),
      .io_spec_r2ud_1    (spec_r2ud_nz_reg[1]),
      .io_spec_r2ud_3    (spec_r2ud_nz_reg[2]),
      .io_spec_r2ud_4    (spec_r2ud_nz_reg[3]),
      .io_pre_q_A        (iter_q_A_reg),
      .io_pre_q_B        (iter_q_B_reg),
      .io_nxt_q_A        (nxt_q_A),
      .io_nxt_q_B        (nxt_q_B),
      .io_pre_sel_0_0    (sel_reg[0][0]),
      .io_pre_sel_0_1    (sel_reg[0][1]),
      .io_pre_sel_1_0    (sel_reg[1][0]),
      .io_pre_sel_1_1    (sel_reg[1][1]),
      .io_pre_sel_2_0    (sel_reg[2][0]),
      .io_pre_sel_2_1    (sel_reg[2][1]),
      .io_pre_sel_3_0    (sel_reg[3][0]),
      .io_pre_sel_3_1    (sel_reg[3][1]),
      .io_nxt_sel_0_0    (nxt_sel[0][0]),
      .io_nxt_sel_0_1    (nxt_sel[0][1]),
      .io_nxt_sel_1_0    (nxt_sel[1][0]),
      .io_nxt_sel_1_1    (nxt_sel[1][1]),
      .io_nxt_sel_2_0    (nxt_sel[2][0]),
      .io_nxt_sel_2_1    (nxt_sel[2][1]),
      .io_nxt_sel_3_0    (nxt_sel[3][0]),
      .io_nxt_sel_3_1    (nxt_sel[3][1]),
      .io_pre_spec_0_0_0 (spec_reg[0][0][0]),
      .io_pre_spec_0_0_1 (spec_reg[0][0][1]),
      .io_pre_spec_0_1_0 (spec_reg[0][1][0]),
      .io_pre_spec_0_1_1 (spec_reg[0][1][1]),
      .io_pre_spec_0_2_0 (spec_reg[0][2][0]),
      .io_pre_spec_0_2_1 (spec_reg[0][2][1]),
      .io_pre_spec_0_3_0 (spec_reg[0][3][0]),
      .io_pre_spec_0_3_1 (spec_reg[0][3][1]),
      .io_pre_spec_1_0_0 (spec_reg[1][0][0]),
      .io_pre_spec_1_0_1 (spec_reg[1][0][1]),
      .io_pre_spec_1_1_0 (spec_reg[1][1][0]),
      .io_pre_spec_1_1_1 (spec_reg[1][1][1]),
      .io_pre_spec_1_2_0 (spec_reg[1][2][0]),
      .io_pre_spec_1_2_1 (spec_reg[1][2][1]),
      .io_pre_spec_1_3_0 (spec_reg[1][3][0]),
      .io_pre_spec_1_3_1 (spec_reg[1][3][1]),
      .io_pre_spec_2_0_0 (spec_reg[2][0][0]),
      .io_pre_spec_2_0_1 (spec_reg[2][0][1]),
      .io_pre_spec_2_1_0 (spec_reg[2][1][0]),
      .io_pre_spec_2_1_1 (spec_reg[2][1][1]),
      .io_pre_spec_2_2_0 (spec_reg[2][2][0]),
      .io_pre_spec_2_2_1 (spec_reg[2][2][1]),
      .io_pre_spec_2_3_0 (spec_reg[2][3][0]),
      .io_pre_spec_2_3_1 (spec_reg[2][3][1]),
      .io_pre_spec_3_0_0 (spec_reg[3][0][0]),
      .io_pre_spec_3_0_1 (spec_reg[3][0][1]),
      .io_pre_spec_3_1_0 (spec_reg[3][1][0]),
      .io_pre_spec_3_1_1 (spec_reg[3][1][1]),
      .io_pre_spec_3_2_0 (spec_reg[3][2][0]),
      .io_pre_spec_3_2_1 (spec_reg[3][2][1]),
      .io_pre_spec_3_3_0 (spec_reg[3][3][0]),
      .io_pre_spec_3_3_1 (spec_reg[3][3][1]),
      .io_pre_spec_4_0_0 (spec_reg[4][0][0]),
      .io_pre_spec_4_0_1 (spec_reg[4][0][1]),
      .io_pre_spec_4_1_0 (spec_reg[4][1][0]),
      .io_pre_spec_4_1_1 (spec_reg[4][1][1]),
      .io_pre_spec_4_2_0 (spec_reg[4][2][0]),
      .io_pre_spec_4_2_1 (spec_reg[4][2][1]),
      .io_pre_spec_4_3_0 (spec_reg[4][3][0]),
      .io_pre_spec_4_3_1 (spec_reg[4][3][1]),
      .io_nxt_spec_0_0_0 (nxt_spec[0][0][0]),
      .io_nxt_spec_0_0_1 (nxt_spec[0][0][1]),
      .io_nxt_spec_0_1_0 (nxt_spec[0][1][0]),
      .io_nxt_spec_0_1_1 (nxt_spec[0][1][1]),
      .io_nxt_spec_0_2_0 (nxt_spec[0][2][0]),
      .io_nxt_spec_0_2_1 (nxt_spec[0][2][1]),
      .io_nxt_spec_0_3_0 (nxt_spec[0][3][0]),
      .io_nxt_spec_0_3_1 (nxt_spec[0][3][1]),
      .io_nxt_spec_1_0_0 (nxt_spec[1][0][0]),
      .io_nxt_spec_1_0_1 (nxt_spec[1][0][1]),
      .io_nxt_spec_1_1_0 (nxt_spec[1][1][0]),
      .io_nxt_spec_1_1_1 (nxt_spec[1][1][1]),
      .io_nxt_spec_1_2_0 (nxt_spec[1][2][0]),
      .io_nxt_spec_1_2_1 (nxt_spec[1][2][1]),
      .io_nxt_spec_1_3_0 (nxt_spec[1][3][0]),
      .io_nxt_spec_1_3_1 (nxt_spec[1][3][1]),
      .io_nxt_spec_2_0_0 (nxt_spec[2][0][0]),
      .io_nxt_spec_2_0_1 (nxt_spec[2][0][1]),
      .io_nxt_spec_2_1_0 (nxt_spec[2][1][0]),
      .io_nxt_spec_2_1_1 (nxt_spec[2][1][1]),
      .io_nxt_spec_2_2_0 (nxt_spec[2][2][0]),
      .io_nxt_spec_2_2_1 (nxt_spec[2][2][1]),
      .io_nxt_spec_2_3_0 (nxt_spec[2][3][0]),
      .io_nxt_spec_2_3_1 (nxt_spec[2][3][1]),
      .io_nxt_spec_3_0_0 (nxt_spec[3][0][0]),
      .io_nxt_spec_3_0_1 (nxt_spec[3][0][1]),
      .io_nxt_spec_3_1_0 (nxt_spec[3][1][0]),
      .io_nxt_spec_3_1_1 (nxt_spec[3][1][1]),
      .io_nxt_spec_3_2_0 (nxt_spec[3][2][0]),
      .io_nxt_spec_3_2_1 (nxt_spec[3][2][1]),
      .io_nxt_spec_3_3_0 (nxt_spec[3][3][0]),
      .io_nxt_spec_3_3_1 (nxt_spec[3][3][1]),
      .io_nxt_spec_4_0_0 (nxt_spec[4][0][0]),
      .io_nxt_spec_4_0_1 (nxt_spec[4][0][1]),
      .io_nxt_spec_4_1_0 (nxt_spec[4][1][0]),
      .io_nxt_spec_4_1_1 (nxt_spec[4][1][1]),
      .io_nxt_spec_4_2_0 (nxt_spec[4][2][0]),
      .io_nxt_spec_4_2_1 (nxt_spec[4][2][1]),
      .io_nxt_spec_4_3_0 (nxt_spec[4][3][0]),
      .io_nxt_spec_4_3_1 (nxt_spec[4][3][1]),
      .io_pre_iterB_0    (iterB_reg[0]),
      .io_pre_iterB_1    (iterB_reg[1]),
      .io_nxt_iterB_0    (nxt_iterB[0]),
      .io_nxt_iterB_1    (nxt_iterB[1])
    );
  end else if (BIT_WIDTH == 64) begin : g_w64
    IterBlock_v4_6 IterBlock (
      .io_Sel_cons_0_0   (sel_cons_reg[0][0]),
      .io_Sel_cons_0_1   (sel_cons_reg[0][1]),
      .io_Sel_cons_0_2   (sel_cons_reg[0][2]),
      .io_Sel_cons_0_3   (sel_cons_reg[0][3]),
      .io_Sel_cons_1_0   (sel_cons_reg[1][0]),
      .io_Sel_cons_1_1   (sel_cons_reg[1][1]),
      .io_Sel_cons_1_2   (sel_cons_reg[1][2]),
      .io_Sel_cons_1_3   (sel_cons_reg[1][3]),
      .io_Sel_cons_2_0   (sel_cons_reg[2][0]),
      .io_Sel_cons_2_1   (sel_cons_reg[2][1]),
      .io_Sel_cons_2_2   (sel_cons_reg[2][2]),
      .io_Sel_cons_2_3   (sel_cons_reg[2][3]),
      .io_Sel_cons_3_0   (sel_cons_reg[3][0]),
      .io_Sel_cons_3_1   (sel_cons_reg[3][1]),
      .io_Sel_cons_3_2   (sel_cons_reg[3][2]),
      .io_Sel_cons_3_3   (sel_cons_reg[3][3]),
      .io_Sel_cons_4_0   (sel_cons_reg[4][0]),
      .io_Sel_cons_4_1   (sel_cons_reg[4][1]),
      .io_Sel_cons_4_2   (sel_cons_reg[4][2]),
      .io_Sel_cons_4_3   (sel_cons_reg[4][3]),
      .io_Spec_cons_0_0  (spec_cons_reg[0][0]),
      .io_Spec_cons_0_1  (spec_cons_reg[0][1]),
      .io_Spec_cons_0_2  (spec_cons_reg[0][2]),
      .io_Spec_cons_0_3  (spec_cons_reg[0][3]),
      .io_Spec_cons_1_0  (spec_cons_reg[1][0]),
      .io_Spec_cons_1_1  (spec_cons_reg[1][1]),
      .io_Spec_cons_1_2  (spec_cons_reg[1][2]),
      .io_Spec_cons_1_3  (spec_cons_reg[1][3]),
      .io_Spec_cons_2_0  (spec_cons_reg[2][0]),
      .io_Spec_cons_2_1  (spec_cons_reg[2][1]),
      .io_Spec_cons_2_2  (spec_cons_reg[2][2]),
      .io_Spec_cons_2_3  (spec_cons_reg[2][3]),
      .io_Spec_cons_3_0  (spec_cons_reg[3][0]),
      .io_Spec_cons_3_1  (spec_cons_reg[3][1]),
      .io_Spec_cons_3_2  (spec_cons_reg[3][2]),
      .io_Spec_cons_3_3  (spec_cons_reg[3][3]),
      .io_Spec_cons_4_0  (spec_cons_reg[4][0]),
      .io_Spec_cons_4_1  (spec_cons_reg[4][1]),
      .io_Spec_cons_4_2  (spec_cons_reg[4][2]),
      .io_Spec_cons_4_3  (spec_cons_reg[4][3]),
      .io_iter_cons_0    (iter_cons_nz_reg[0]),
      .io_iter_cons_1    (iter_cons_nz_reg[1]),
      .io_iter_cons_3    (iter_cons_nz_reg[2]),
      .io_iter_cons_4    (iter_cons_nz_reg[3]),
      .io_d_trunc_0      (d_trunc_reg[0]),
      .io_d_trunc_1      (d_trunc_reg[1]),
      .io_d_trunc_2      (d_trunc_reg[2]),
      .io_d_trunc_3      (d_trunc_reg[3]),
      .io_spec_r2ud_0    (spec_r2ud_nz_reg[0]),
      .io_spec_r2ud_1    (spec_r2ud_nz_reg[1]),
      .io_spec_r2ud_3    (spec_r2ud_nz_reg[2]),
      .io_spec_r2ud_4    (spec_r2ud_nz_reg[3]),
      .io_pre_q_A        (iter_q_A_reg),
      .io_pre_q_B        (iter_q_B_reg),
      .io_nxt_q_A        (nxt_q_A),
      .io_nxt_q_B        (nxt_q_B),
      .io_pre_sel_0_0    (sel_reg[0][0]),
      .io_pre_sel_0_1    (sel_reg[0][1]),
      .io_pre_sel_1_0    (sel_reg[1][0]),
      .io_pre_sel_1_1    (sel_reg[1][1]),
      .io_pre_sel_2_0    (sel_reg[2][0]),
      .io_pre_sel_2_1    (sel_reg[2][1]),
      .io_pre_sel_3_0    (sel_reg[3][0]),
      .io_pre_sel_3_1    (sel_reg[3][1]),
      .io_nxt_sel_0_0    (nxt_sel[0][0]),
      .io_nxt_sel_0_1    (nxt_sel[0][1]),
      .io_nxt_sel_1_0    (nxt_sel[1][0]),
      .io_nxt_sel_1_1    (nxt_sel[1][1]),
      .io_nxt_sel_2_0    (nxt_sel[2][0]),
      .io_nxt_sel_2_1    (nxt_sel[2][1]),
      .io_nxt_sel_3_0    (nxt_sel[3][0]),
      .io_nxt_sel_3_1    (nxt_sel[3][1]),
      .io_pre_spec_0_0_0 (spec_reg[0][0][0]),
      .io_pre_spec_0_0_1 (spec_reg[0][0][1]),
      .io_pre_spec_0_1_0 (spec_reg[0][1][0]),
      .io_pre_spec_0_1_1 (spec_reg[0][1][1]),
      .io_pre_spec_0_2_0 (spec_reg[0][2][0]),
      .io_pre_spec_0_2_1 (spec_reg[0][2][1]),
      .io_pre_spec_0_3_0 (spec_reg[0][3][0]),
      .io_pre_spec_0_3_1 (spec_reg[0][3][1]),
      .io_pre_spec_1_0_0 (spec_reg[1][0][0]),
      .io_pre_spec_1_0_1 (spec_reg[1][0][1]),
      .io_pre_spec_1_1_0 (spec_reg[1][1][0]),
      .io_pre_spec_1_1_1 (spec_reg[1][1][1]),
      .io_pre_spec_1_2_0 (spec_reg[1][2][0]),
      .io_pre_spec_1_2_1 (spec_reg[1][2][1]),
      .io_pre_spec_1_3_0 (spec_reg[1][3][0]),
      .io_pre_spec_1_3_1 (spec_reg[1][3][1]),
      .io_pre_spec_2_0_0 (spec_reg[2][0][0]),
      .io_pre_spec_2_0_1 (spec_reg[2][0][1]),
      .io_pre_spec_2_1_0 (spec_reg[2][1][0]),
      .io_pre_spec_2_1_1 (spec_reg[2][1][1]),
      .io_pre_spec_2_2_0 (spec_reg[2][2][0]),
      .io_pre_spec_2_2_1 (spec_reg[2][2][1]),
      .io_pre_spec_2_3_0 (spec_reg[2][3][0]),
      .io_pre_spec_2_3_1 (spec_reg[2][3][1]),
      .io_pre_spec_3_0_0 (spec_reg[3][0][0]),
      .io_pre_spec_3_0_1 (spec_reg[3][0][1]),
      .io_pre_spec_3_1_0 (spec_reg[3][1][0]),
      .io_pre_spec_3_1_1 (spec_reg[3][1][1]),
      .io_pre_spec_3_2_0 (spec_reg[3][2][0]),
      .io_pre_spec_3_2_1 (spec_reg[3][2][1]),
      .io_pre_spec_3_3_0 (spec_reg[3][3][0]),
      .io_pre_spec_3_3_1 (spec_reg[3][3][1]),
      .io_pre_spec_4_0_0 (spec_reg[4][0][0]),
      .io_pre_spec_4_0_1 (spec_reg[4][0][1]),
      .io_pre_spec_4_1_0 (spec_reg[4][1][0]),
      .io_pre_spec_4_1_1 (spec_reg[4][1][1]),
      .io_pre_spec_4_2_0 (spec_reg[4][2][0]),
      .io_pre_spec_4_2_1 (spec_reg[4][2][1]),
      .io_pre_spec_4_3_0 (spec_reg[4][3][0]),
      .io_pre_spec_4_3_1 (spec_reg[4][3][1]),
      .io_nxt_spec_0_0_0 (nxt_spec[0][0][0]),
      .io_nxt_spec_0_0_1 (nxt_spec[0][0][1]),
      .io_nxt_spec_0_1_0 (nxt_spec[0][1][0]),
      .io_nxt_spec_0_1_1 (nxt_spec[0][1][1]),
      .io_nxt_spec_0_2_0 (nxt_spec[0][2][0]),
      .io_nxt_spec_0_2_1 (nxt_spec[0][2][1]),
      .io_nxt_spec_0_3_0 (nxt_spec[0][3][0]),
      .io_nxt_spec_0_3_1 (nxt_spec[0][3][1]),
      .io_nxt_spec_1_0_0 (nxt_spec[1][0][0]),
      .io_nxt_spec_1_0_1 (nxt_spec[1][0][1]),
      .io_nxt_spec_1_1_0 (nxt_spec[1][1][0]),
      .io_nxt_spec_1_1_1 (nxt_spec[1][1][1]),
      .io_nxt_spec_1_2_0 (nxt_spec[1][2][0]),
      .io_nxt_spec_1_2_1 (nxt_spec[1][2][1]),
      .io_nxt_spec_1_3_0 (nxt_spec[1][3][0]),
      .io_nxt_spec_1_3_1 (nxt_spec[1][3][1]),
      .io_nxt_spec_2_0_0 (nxt_spec[2][0][0]),
      .io_nxt_spec_2_0_1 (nxt_spec[2][0][1]),
      .io_nxt_spec_2_1_0 (nxt_spec[2][1][0]),
      .io_nxt_spec_2_1_1 (nxt_spec[2][1][1]),
      .io_nxt_spec_2_2_0 (nxt_spec[2][2][0]),
      .io_nxt_spec_2_2_1 (nxt_spec[2][2][1]),
      .io_nxt_spec_2_3_0 (nxt_spec[2][3][0]),
      .io_nxt_spec_2_3_1 (nxt_spec[2][3][1]),
      .io_nxt_spec_3_0_0 (nxt_spec[3][0][0]),
      .io_nxt_spec_3_0_1 (nxt_spec[3][0][1]),
      .io_nxt_spec_3_1_0 (nxt_spec[3][1][0]),
      .io_nxt_spec_3_1_1 (nxt_spec[3][1][1]),
      .io_nxt_spec_3_2_0 (nxt_spec[3][2][0]),
      .io_nxt_spec_3_2_1 (nxt_spec[3][2][1]),
      .io_nxt_spec_3_3_0 (nxt_spec[3][3][0]),
      .io_nxt_spec_3_3_1 (nxt_spec[3][3][1]),
      .io_nxt_spec_4_0_0 (nxt_spec[4][0][0]),
      .io_nxt_spec_4_0_1 (nxt_spec[4][0][1]),
      .io_nxt_spec_4_1_0 (nxt_spec[4][1][0]),
      .io_nxt_spec_4_1_1 (nxt_spec[4][1][1]),
      .io_nxt_spec_4_2_0 (nxt_spec[4][2][0]),
      .io_nxt_spec_4_2_1 (nxt_spec[4][2][1]),
      .io_nxt_spec_4_3_0 (nxt_spec[4][3][0]),
      .io_nxt_spec_4_3_1 (nxt_spec[4][3][1]),
      .io_pre_iterB_0    (iterB_reg[0]),
      .io_pre_iterB_1    (iterB_reg[1]),
      .io_nxt_iterB_0    (nxt_iterB[0]),
      .io_nxt_iterB_1    (nxt_iterB[1])
    );
  end
  // END GENERATED

  // ---------------------------------------------------------------------------
  // §6 POST / OUTPUT：余数合并与修正、商取补、右移还原
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (in_post) begin
      q_A_sign_c_reg <= (q_sign_reg & ~zero_d_reg) ? neg_x_q : iter_q_A_reg;
      q_B_sign_c_reg <= (q_sign_reg & ~zero_d_reg) ? neg_d_q : iter_q_B_reg;
      if (x_sign_reg) begin   // 被除数为负：余数取负 = 两半各取反再 +2
        Bypass_final_rem_reg        <= W'(~iterB_reg[0] + ~iterB_reg[1] + W'(2));
        Bypass_final_rem_plus_d_reg <= W'(~iterB_reg[0] + ~iterB_reg[1]
                                          + (iter_cons_nz_reg[1] << 2) + W'(2));
      end else begin
        Bypass_final_rem_reg        <= W'(iterB_reg[0] + iterB_reg[1]);
        Bypass_final_rem_plus_d_reg <= W'(iterB_reg[0] + iterB_reg[1] + (iter_cons_nz_reg[2] << 2));
      end
    end
  end

  // 余数符号与被除数相反（或被除数为负时余数为正非零）则修正：选 +d 版余数与 Q−1
  logic         rem_is_zero, adjust;
  logic [W-1:0] rem_adjust, rem_adjust_ralign;
  assign rem_is_zero       = Bypass_final_rem_reg == '0;
  assign adjust            = (x_sign_reg ? (~rem_is_zero & ~Bypass_final_rem_reg[W-1])
                                         : Bypass_final_rem_reg[W-1]) & ~early_finish_q;
  assign rem_adjust        = adjust ? Bypass_final_rem_plus_d_reg : Bypass_final_rem_reg;
  // 规格化时 d 左移了 lzc_d 位，余数右移 lzc_d+5 位还原（算术右移）
  assign rem_adjust_ralign = W'($signed(rem_adjust) >>> ({1'b0, lzc_d_reg} + (LZC_W + 1)'(5)));
  assign div_out_q         = adjust ? q_B_sign_c_reg : q_A_sign_c_reg;
  assign div_out_rem       = early_finish_q ? rem_adjust[BIT_WIDTH+2:3] : rem_adjust_ralign[BIT_WIDTH-1:0];
endmodule

// -----------------------------------------------------------------------------
// SRT16Divint —— golden 同名 wrapper（16 位实例）
// -----------------------------------------------------------------------------
module SRT16Divint(
  input         clock,
  input         reset,
  input         io_sign,
  input  [15:0] io_dividend,
  input  [15:0] io_divisor,
  input         io_flush,
  input  [1:0]  io_sew,
  input         io_div_in_valid,
  input         io_div_out_ready,
  output        io_div_out_valid,
  output [15:0] io_div_out_q,
  output [15:0] io_div_out_rem
);
  xs_SRT16Divint_core #(.BIT_WIDTH(16)) u_core (
    .clock         (clock),
    .reset         (reset),
    .sign          (io_sign),
    .dividend      (io_dividend),
    .divisor       (io_divisor),
    .flush         (io_flush),
    .sew           (io_sew),
    .div_in_valid  (io_div_in_valid),
    .div_out_ready (io_div_out_ready),
    .div_out_valid (io_div_out_valid),
    .div_out_q     (io_div_out_q),
    .div_out_rem   (io_div_out_rem)
  );
endmodule
