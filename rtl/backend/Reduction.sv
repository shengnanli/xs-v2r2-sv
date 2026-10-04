// =============================================================================
// Reduction.sv —— 向量整数归约单元（VIAlu 里的 vredsum/vredmax(u)/vredmin(u)/vredand/vredor/vredxor
//                 及其加宽版 vwredsum(u)），两级流水，VLEN = 128
//
// 设计源：yunsuan/src/main/scala/yunsuan/vector/VectorALU/Reduction.scala（class Reduction）。
// golden 对照：G1-canonical/golden-rtl/Reduction.sv（1394 行）。
//
// ---- 在哪一层、怎么被用 ----
// 一条向量归约指令被拆成若干 uop。每个 uop 进来的数据是 vs1:vs2 拼成的 256 位 vs12
// （vs2 在低 128 位），vs1 的第 0 个元素同时是归约的标量初值。uop 分三类（只由 vlmul、uopIdx
// 和是否加宽决定，见 §0.2）：
//   * alu uop / widen_alu uop：前几个 uop 只做「两两逐元素合并」——把 vs12 的高半与低半
//     按元素做 加 / max / min / and / or / xor，结果仍是一个 128 位向量（当作下一 uop 的源）；
//     加宽 uop 先把低 128 位里的元素符号/零扩展成 2 倍宽再合并。
//   * reduction uop：最后一个 uop 把 128 位里的全部元素连同 vs1[0] 归约成一个标量，
//     写进 vd 的第 0 个元素，vd 其余位按 ta 取全 1 或保持 old_vd（vl==0 时整体保持 old_vd）。
// 「reduction uop」还负责对 vs12 做 mask / 尾部处理：被 mask 掉的元素和下标 >= 剩余 vl 的元素
// 换成该运算的单位元（sum/or/xor/maxu → 0，and/minu → 全 1，max → 最小负数，min → 最大正数）。
//
// ---- 流水级 ----
//   §1 s0（组合，输入当拍）：译码、算 mask/尾部、把 vs12 的字节换成单位元（vs12m），
//      取 vs1[0] 的零扩展（加法/比较用）与"and 时高位补 1"版（逻辑运算用）。
//   §2 s0→s1 寄存器（in_valid 使能，异步复位）+ fire_reg_s1（不复位，照 golden）。
//   §3 s1（组合）：加宽扩展；三棵并行归约树——加法走 CSA 压缩树（结果是 sum/carry 两个数，
//      留到 s2 再相加）；max/min 走 3 选 1 比较器树的第一层；逻辑运算 64→8 位逐级折半。
//   §4 s1→s2 寄存器（fire_reg_s1 使能，异步复位）：vd_reg 存"树的中间结果"或 alu uop 的高半，
//      old_vd_reg 存 alu uop 的低半（否则存 old_vd）。
//   §5 s2（组合）：alu uop 逐字节加法器（进位链按 vd 元素宽度断开，max/min 时做减法比大小）；
//      归约 uop 把 sum/carry 相加、比较树最后一层；按 ta/vl 做尾部，输出 io_out_vd。
//
// ---- 照抄 golden 的怪癖（bug-for-bug） ----
//   * 单位元只在 in_valid 时非 0（Scala `when(fire)`）；寄存器只在 valid 时装，所以看不出来，但照写。
//   * max 的单位元用 srcType(2) 判有符号，比较器的 signed 却用 srcType(3,2)==1 —— 两个判据不同，照抄。
//   * 加宽只认 vdType(1,0) == srcType(1,0)+1（2 位回绕：sew=3、vd=0 也算"加宽"）。
//   * 归约树一律只吃 vs12m 的低 128 位（vs2 那一半）+ vs1[0]；树宽按 vd 的 sew 选。
//   * vdType_reg_s1 是 4 位寄存器、只用 [1:0]：[3:2] 两侧同为无读者的死位（FM 需 vmucp 配对）。
//   * vd_vsew_reg_s1 与 vdType_reg_s1[1:0] 是同一个值的两份寄存器，各有各的读者，照 golden 都保留。
//   * 寄存器名与 golden 一致（Scala 名），便于对照；子模块实例名也与 golden 一致。
// 子模块（均为本仓已签核重写件，两侧白盒）：CSA3to2_124/125/127/132、CSA4to2_15/16、
//   compare_2to1 / compare_2to1_2 / compare_3to1 / compare_3to1_1 / compare_3to1_2 / compare_3to1_6。
// =============================================================================
module xs_Reduction_core (
  input  logic         clock,
  input  logic         reset,
  input  logic         in_valid,
  input  logic [5:0]   opcode,
  input  logic         vm,
  input  logic         ta,
  input  logic [2:0]   vlmul,
  input  logic [7:0]   vl,
  input  logic [5:0]   uop_idx,
  input  logic [3:0]   src_type,      // srcType(0)：[1:0] = 源 sew，[3:2] == 1 表示有符号
  input  logic [3:0]   vd_type,       // [1:0] = 目的 sew
  input  logic [127:0] vs1,
  input  logic [127:0] vs2,
  input  logic [127:0] old_vd,
  input  logic [127:0] mask,
  output logic [127:0] out_vd
);
  // VAluOpcode（yunsuan/vector/VectorALU/VAluDecode.scala）：vredsum = 33 .. vredxor = 38。
  // vredsum 不单独译码：不是 max/min/and/or/xor 的一律走加法通路。
  localparam logic [5:0] OP_VREDMAX = 6'd34;
  localparam logic [5:0] OP_VREDMIN = 6'd35;
  localparam logic [5:0] OP_VREDAND = 6'd36;
  localparam logic [5:0] OP_VREDOR  = 6'd37;
  localparam logic [5:0] OP_VREDXOR = 6'd38;

  // ---------------------------------------------------------------------------
  // 单位元：sew 宽元素里"不改变归约结果"的那个值（放在 64 位的低 sew 位）。
  // ---------------------------------------------------------------------------
  function automatic logic [63:0] identity_of(input logic [1:0] sew, input logic smax_op,
                                              input logic smin_op, input logic ones_op);
    logic [63:0] ones, sign_bit;
    ones     = 64'hFFFF_FFFF_FFFF_FFFF >> (7'd64 - (7'd8 << sew));
    sign_bit = 64'd1 << ((7'd8 << sew) - 7'd1);
    if (smax_op)      return sign_bit;               // vredmax：最小负数
    else if (smin_op) return ones & ~sign_bit;       // vredmin：最大正数
    else if (ones_op) return ones;                   // vredminu / vredand：全 1
    else              return 64'd0;                  // sum / or / xor / maxu：0
  endfunction

  // 加宽：64 位里的 eew 元素逐个扩展成 2*eew 位（eew_oh = {32,16,8} 位 one-hot；全 0 时得 0）
  function automatic logic [127:0] widen_half(input logic [63:0] x, input logic [2:0] eew_oh,
                                              input logic sgn);
    logic [127:0] w8, w16, w32;
    for (int e = 0; e < 8; e++) w8[16*e +: 16] = {{8{x[8*e+7] & sgn}}, x[8*e +: 8]};
    for (int e = 0; e < 4; e++) w16[32*e +: 32] = {{16{x[16*e+15] & sgn}}, x[16*e +: 16]};
    for (int e = 0; e < 2; e++) w32[64*e +: 64] = {{32{x[32*e+31] & sgn}}, x[32*e +: 32]};
    return (eew_oh[0] ? w8 : 128'd0) | (eew_oh[1] ? w16 : 128'd0) | (eew_oh[2] ? w32 : 128'd0);
  endfunction

  // vs1 的第 0 个元素（按 vd 的 sew），高位补 fill
  function automatic logic [63:0] vs1_elem0(input logic [63:0] x, input logic [1:0] sew,
                                            input logic fill);
    case (sew)
      2'd0:    return {{56{fill}}, x[7:0]};
      2'd1:    return {{48{fill}}, x[15:0]};
      2'd2:    return {{32{fill}}, x[31:0]};
      default: return x;
    endcase
  endfunction

  // ===========================================================================
  // §1 s0：译码 + mask/尾部 → vs12m
  // ===========================================================================
  // ---- §1.1 运算译码 ----
  logic [1:0] vsew, vd_vsew;
  logic       is_signed, widen;
  logic       op_max, op_min, op_and, op_or, op_xor;
  logic       vredmax_vs, vredmin_vs, vredminu_vs;
  assign vsew        = src_type[1:0];
  assign vd_vsew     = vd_type[1:0];
  assign is_signed   = src_type[3:2] == 2'd1;
  assign widen       = vd_vsew == 2'(vsew + 2'd1);
  assign op_max      = opcode == OP_VREDMAX;
  assign op_min      = opcode == OP_VREDMIN;
  assign op_and      = opcode == OP_VREDAND;
  assign op_or       = opcode == OP_VREDOR;
  assign op_xor      = opcode == OP_VREDXOR;
  assign vredmax_vs  = op_max & src_type[2];
  assign vredmin_vs  = op_min & src_type[2];
  assign vredminu_vs = op_min & ~src_type[2];

  // ---- §1.2 uop 分类（前几个 uop 做两两合并，最后的 uop 做归约） ----
  logic reduction_uop, widen_reduction_uop, alu_uop, widen_alu_uop;
  always_comb begin
    reduction_uop       = !widen && (uop_idx == 6'd0
                                     || (vlmul == 3'd2 && uop_idx < 6'd2)
                                     || (vlmul == 3'd3 && uop_idx < 6'd4));
    widen_reduction_uop =  widen && (uop_idx == 6'd0
                                     || (vlmul == 3'd1 && uop_idx < 6'd2)
                                     || (vlmul == 3'd2 && uop_idx < 6'd4)
                                     || (vlmul == 3'd3 && uop_idx < 6'd8));
    alu_uop             = !widen && ((vlmul == 3'd1 && uop_idx < 6'd1)
                                     || (vlmul == 3'd2 && uop_idx < 6'd3)
                                     || (vlmul == 3'd3 && uop_idx < 6'd7));
    widen_alu_uop       =  widen && (uop_idx == 6'd0
                                     || (vlmul == 3'd1 && uop_idx < 6'd3)
                                     || (vlmul == 3'd2 && uop_idx < 6'd7)
                                     || (vlmul == 3'd3 && uop_idx < 6'd15));
  end

  // ---- §1.3 本 uop 负责的元素窗口：起点 shift = uopIdx × (每 uop 的元素数) ----
  // 每 uop 吃 256 位（加宽时 128 位）：元素数 = 2^(vsew_plus1 + 1)（加宽少一位）。
  logic [2:0]   vsew_plus1;
  logic [12:0]  shift;
  logic [7:0]   vl_remain;          // 本 uop 起还剩几个元素（不够减时为 0）
  logic [10:0]  vl_remain_bytes;
  logic [127:0] vmask_bits;         // mask 右移到本 uop 的第 0 个元素
  assign vsew_plus1      = 3'({1'b0, ~vsew} + 3'd1);
  assign shift           = widen ? 13'(uop_idx) << vsew_plus1 : 13'(uop_idx) << 3'(vsew_plus1 + 3'd1);
  assign vl_remain       = 13'(vl) >= shift ? 8'(vl - shift[7:0]) : 8'd0;
  assign vl_remain_bytes = 11'(vl_remain) << vsew;
  assign vmask_bits      = mask >> shift;

  // ---- §1.4 单位元 ----
  logic [63:0] ident;
  assign ident = in_valid ? identity_of(vsew, vredmax_vs, vredmin_vs, vredminu_vs | op_and) : 64'd0;

  // ---- §1.5 vs12m：逐字节把 inactive / 尾部元素换成单位元（只对归约 uop 做） ----
  logic [255:0] vs12, vs12m_bits;
  assign vs12 = {vs1, vs2};
  always_comb begin
    for (int b = 0; b < 32; b++) begin
      logic [4:0] elem;               // 字节 b 属于第几个 sew 元素
      logic [2:0] byte_in_elem;       // 是该元素的第几个字节
      logic       inactive;
      elem         = 5'(b >> vsew);
      byte_in_elem = 3'(b & ((1 << vsew) - 1));
      inactive     = (!vm && !vmask_bits[elem]) || (11'(b) >= vl_remain_bytes);
      vs12m_bits[8*b +: 8] = (inactive && (reduction_uop || widen_reduction_uop))
                             ? ident[8*byte_in_elem +: 8] : vs12[8*b +: 8];
    end
  end

  // ---- §1.6 vs1[0]：加法/比较用零扩展；逻辑运算 and 时高位补 1（不影响 and 结果） ----
  logic [63:0] vs1_zero, vs1_zero_logical;
  assign vs1_zero         = vs1_elem0(vs1[63:0], vd_vsew, 1'b0);
  assign vs1_zero_logical = vs1_elem0(vs1[63:0], vd_vsew, op_and);

  // ===========================================================================
  // §2 s0 → s1 寄存器
  // ===========================================================================
  logic         fire_reg_s1;
  logic [127:0] old_vd_reg_s1;
  logic         ta_reg_s1;
  logic [7:0]   vl_reg_s1;
  logic [1:0]   vd_vsew_reg_s1;
  logic [2:0]   eewVs2_reg_s1;          // 源 sew one-hot {32,16,8}（sew64 时全 0）
  logic         signed_reg_s1;
  logic         vredand_vs_reg_s1, vredor_vs_reg_s1, vredxor_vs_reg_s1;
  logic [3:0]   vdType_reg_s1;          // 只用 [1:0]，[3:2] 为死位（照 golden 保留位宽）
  logic         isVredmax_reg_s1, isVredmin_reg_s1;
  logic [255:0] vs12m_bits_reg_s1;
  logic         widen_reduction_uop_reg_s1, alu_uop_reg_s1, widen_alu_uop_reg_s1;
  logic [63:0]  vs1_zero_reg_s1, vs1_zero_logical_reg_s1;

  // RegNext(fire)：不复位
  always_ff @(posedge clock) fire_reg_s1 <= in_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      old_vd_reg_s1              <= '0;
      ta_reg_s1                  <= 1'b0;
      vl_reg_s1                  <= '0;
      vd_vsew_reg_s1             <= '0;
      eewVs2_reg_s1              <= '0;
      signed_reg_s1              <= 1'b0;
      vredand_vs_reg_s1          <= 1'b0;
      vredor_vs_reg_s1           <= 1'b0;
      vredxor_vs_reg_s1          <= 1'b0;
      vdType_reg_s1              <= '0;
      isVredmax_reg_s1           <= 1'b0;
      isVredmin_reg_s1           <= 1'b0;
      vs12m_bits_reg_s1          <= '0;
      widen_reduction_uop_reg_s1 <= 1'b0;
      alu_uop_reg_s1             <= 1'b0;
      widen_alu_uop_reg_s1       <= 1'b0;
      vs1_zero_reg_s1            <= '0;
      vs1_zero_logical_reg_s1    <= '0;
    end else if (in_valid) begin
      old_vd_reg_s1              <= old_vd;
      ta_reg_s1                  <= ta;
      vl_reg_s1                  <= vl;
      vd_vsew_reg_s1             <= vd_vsew;
      eewVs2_reg_s1              <= {vsew == 2'd2, vsew == 2'd1, vsew == 2'd0};
      signed_reg_s1              <= is_signed;
      vredand_vs_reg_s1          <= op_and;
      vredor_vs_reg_s1           <= op_or;
      vredxor_vs_reg_s1          <= op_xor;
      vdType_reg_s1              <= vd_type;
      isVredmax_reg_s1           <= op_max;
      isVredmin_reg_s1           <= op_min;
      vs12m_bits_reg_s1          <= vs12m_bits;
      widen_reduction_uop_reg_s1 <= widen_reduction_uop;
      alu_uop_reg_s1             <= alu_uop;
      widen_alu_uop_reg_s1       <= widen_alu_uop;
      vs1_zero_reg_s1            <= vs1_zero;
      vs1_zero_logical_reg_s1    <= vs1_zero_logical;
    end
  end

  // ===========================================================================
  // §3 s1：加宽 + 三棵归约树的前半
  // ===========================================================================
  // ---- §3.1 alu uop 的两个操作数：高半 / 低半（加宽 uop 用低 128 位的两半扩展） ----
  logic [127:0] hi_vs, lo_vs;
  assign hi_vs = widen_reduction_uop_reg_s1
               ? widen_half(vs12m_bits_reg_s1[127:64], eewVs2_reg_s1, signed_reg_s1)
               : vs12m_bits_reg_s1[255:128];
  assign lo_vs = widen_reduction_uop_reg_s1
               ? widen_half(vs12m_bits_reg_s1[63:0], eewVs2_reg_s1, signed_reg_s1)
               : vs12m_bits_reg_s1[127:0];

  // ---- §3.2 加法树：vs12m 低 128 位的全部元素 + vs1[0]，CSA 压成 sum/carry 两个数 ----
  // sew64：2 元素 + vs1[0] = 3 个数 → 一个 3:2
  logic [63:0] sum_sew64, carry_sew64;
  CSA3to2_124 csa_3to2_sew64 (
    .io_in_a    (vs12m_bits_reg_s1[63:0]),
    .io_in_b    (vs12m_bits_reg_s1[127:64]),
    .io_in_c    (vs1_zero_reg_s1),
    .io_out_sum (sum_sew64),
    .io_out_car (carry_sew64)
  );

  // sew32：4 元素 + vs1[0] = 5 个数 → 前 3 个做 3:2，后 2 个直接相加，再一个 3:2
  logic [31:0] sum0_sew32, carry0_sew32, sum_add_sew32, sum1_sew32, carry1_sew32;
  assign sum_add_sew32 = vs12m_bits_reg_s1[127:96] + vs1_zero_reg_s1[31:0];
  CSA3to2_125 csa_3to2_sew32_0 (
    .io_in_a    (vs12m_bits_reg_s1[31:0]),
    .io_in_b    (vs12m_bits_reg_s1[63:32]),
    .io_in_c    (vs12m_bits_reg_s1[95:64]),
    .io_out_sum (sum0_sew32),
    .io_out_car (carry0_sew32)
  );
  CSA3to2_125 csa_3to2_sew32_1 (
    .io_in_a    (sum0_sew32),
    .io_in_b    (carry0_sew32),
    .io_in_c    (sum_add_sew32),
    .io_out_sum (sum1_sew32),
    .io_out_car (carry1_sew32)
  );

  // sew16：8 元素 + vs1[0] = 9 个数 → 三个 3:2 → 6 个 → 两个 3:2（carry 组 / sum 组）→ 4 个 → 一个 4:2
  logic [143:0] in0_sew16;
  logic [15:0]  sum0_sew16 [3], carry0_sew16 [3];
  logic [15:0]  sum1_sew16 [2], carry1_sew16 [2];
  logic [15:0]  sum2_sew16, carry2_sew16;
  assign in0_sew16 = {vs1_zero_reg_s1[15:0], vs12m_bits_reg_s1[127:0]};
  CSA3to2_127 csa_3to2_sew16 (
    .io_in_a    (in0_sew16[15:0]),
    .io_in_b    (in0_sew16[31:16]),
    .io_in_c    (in0_sew16[47:32]),
    .io_out_sum (sum0_sew16[0]),
    .io_out_car (carry0_sew16[0])
  );
  CSA3to2_127 csa_3to2_sew16_1 (
    .io_in_a    (in0_sew16[63:48]),
    .io_in_b    (in0_sew16[79:64]),
    .io_in_c    (in0_sew16[95:80]),
    .io_out_sum (sum0_sew16[1]),
    .io_out_car (carry0_sew16[1])
  );
  CSA3to2_127 csa_3to2_sew16_2 (
    .io_in_a    (in0_sew16[111:96]),
    .io_in_b    (in0_sew16[127:112]),
    .io_in_c    (in0_sew16[143:128]),
    .io_out_sum (sum0_sew16[2]),
    .io_out_car (carry0_sew16[2])
  );
  CSA3to2_127 csa_3to2_sew16_3 (           // 第二层：三个 carry 一组
    .io_in_a    (carry0_sew16[0]),
    .io_in_b    (carry0_sew16[1]),
    .io_in_c    (carry0_sew16[2]),
    .io_out_sum (sum1_sew16[0]),
    .io_out_car (carry1_sew16[0])
  );
  CSA3to2_127 csa_3to2_sew16_4 (           // 第二层：三个 sum 一组
    .io_in_a    (sum0_sew16[0]),
    .io_in_b    (sum0_sew16[1]),
    .io_in_c    (sum0_sew16[2]),
    .io_out_sum (sum1_sew16[1]),
    .io_out_car (carry1_sew16[1])
  );
  CSA4to2_15 csa_4to2_sew16 (
    .io_in_a    (carry1_sew16[0]),
    .io_in_b    (carry1_sew16[1]),
    .io_in_c    (sum1_sew16[0]),
    .io_in_d    (sum1_sew16[1]),
    .io_out_sum (sum2_sew16),
    .io_out_car (carry2_sew16)
  );

  // sew8：16 元素 + vs1[0] = 17 个数 → 四个 4:2 → 8 个 + vs1[0] → 三个 3:2 → 6 个
  //       → 两个 3:2（carry 组 / sum 组）→ 4 个 → 一个 4:2
  logic [7:0]  sum0_sew8 [4], carry0_sew8 [4];
  logic [71:0] in1_sew8;                 // {vs1[0], sum0[3..0], carry0[3..0]}
  logic [7:0]  sum1_sew8 [3], carry1_sew8 [3];
  logic [7:0]  sum2_sew8 [2], carry2_sew8 [2];
  logic [7:0]  sum3_sew8, carry3_sew8;
  for (genvar i = 0; i < 4; i++) begin : g_sew8_l0
    CSA4to2_16 csa_4to2_sew8 (
      .io_in_a    (vs12m_bits_reg_s1[32*i +: 8]),
      .io_in_b    (vs12m_bits_reg_s1[32*i+8 +: 8]),
      .io_in_c    (vs12m_bits_reg_s1[32*i+16 +: 8]),
      .io_in_d    (vs12m_bits_reg_s1[32*i+24 +: 8]),
      .io_out_sum (sum0_sew8[i]),
      .io_out_car (carry0_sew8[i])
    );
  end
  assign in1_sew8 = {vs1_zero_reg_s1[7:0],
                     sum0_sew8[3], sum0_sew8[2], sum0_sew8[1], sum0_sew8[0],
                     carry0_sew8[3], carry0_sew8[2], carry0_sew8[1], carry0_sew8[0]};
  for (genvar i = 0; i < 3; i++) begin : g_sew8_l1
    CSA3to2_132 csa_3to2_sew8 (
      .io_in_a    (in1_sew8[24*i +: 8]),
      .io_in_b    (in1_sew8[24*i+8 +: 8]),
      .io_in_c    (in1_sew8[24*i+16 +: 8]),
      .io_out_sum (sum1_sew8[i]),
      .io_out_car (carry1_sew8[i])
    );
  end
  CSA3to2_132 csa_3to2_sew8_3 (            // 第三层：三个 carry 一组
    .io_in_a    (carry1_sew8[0]),
    .io_in_b    (carry1_sew8[1]),
    .io_in_c    (carry1_sew8[2]),
    .io_out_sum (sum2_sew8[0]),
    .io_out_car (carry2_sew8[0])
  );
  CSA3to2_132 csa_3to2_sew8_4 (            // 第三层：三个 sum 一组
    .io_in_a    (sum1_sew8[0]),
    .io_in_b    (sum1_sew8[1]),
    .io_in_c    (sum1_sew8[2]),
    .io_out_sum (sum2_sew8[1]),
    .io_out_car (carry2_sew8[1])
  );
  CSA4to2_16 csa_4to2_sew8_4 (
    .io_in_a    (carry2_sew8[0]),
    .io_in_b    (carry2_sew8[1]),
    .io_in_c    (sum2_sew8[0]),
    .io_in_d    (sum2_sew8[1]),
    .io_out_sum (sum3_sew8),
    .io_out_car (carry3_sew8)
  );

  // ---- §3.3 max/min 树第一层：同样的 17/9/5/3 个数，3 选 1（或 2 选 1）比较器 ----
  logic [63:0] vd_max_sew64;
  compare_3to1 compare_3to1_sew64 (
    .io_a      (vs12m_bits_reg_s1[63:0]),
    .io_b      (vs12m_bits_reg_s1[127:64]),
    .io_c      (vs1_zero_reg_s1),
    .io_max    (isVredmax_reg_s1),
    .io_signed (signed_reg_s1),
    .io_d      (vd_max_sew64)
  );

  logic [31:0] vd0_max_sew32 [2];
  compare_3to1_1 compare_3to1_sew32 (
    .io_a      (vs12m_bits_reg_s1[31:0]),
    .io_b      (vs12m_bits_reg_s1[63:32]),
    .io_c      (vs12m_bits_reg_s1[95:64]),
    .io_max    (isVredmax_reg_s1),
    .io_signed (signed_reg_s1),
    .io_d      (vd0_max_sew32[0])
  );
  compare_2to1 compare0_2to1_sew32 (
    .io_a      (vs12m_bits_reg_s1[127:96]),
    .io_b      (vs1_zero_reg_s1[31:0]),
    .io_max    (isVredmax_reg_s1),
    .io_signed (signed_reg_s1),
    .io_c      (vd0_max_sew32[1])
  );

  logic [15:0] vd0_max_sew16 [3];
  for (genvar i = 0; i < 3; i++) begin : g_max16_l0
    compare_3to1_2 compare_3to1_sew16 (
      .io_a      (in0_sew16[48*i +: 16]),
      .io_b      (in0_sew16[48*i+16 +: 16]),
      .io_c      (in0_sew16[48*i+32 +: 16]),
      .io_max    (isVredmax_reg_s1),
      .io_signed (signed_reg_s1),
      .io_d      (vd0_max_sew16[i])
    );
  end

  logic [7:0] vd0_max_sew8 [6];
  for (genvar i = 0; i < 5; i++) begin : g_max8_l0
    compare_3to1_6 compare_3to1_sew8 (
      .io_a      (vs12m_bits_reg_s1[24*i +: 8]),
      .io_b      (vs12m_bits_reg_s1[24*i+8 +: 8]),
      .io_c      (vs12m_bits_reg_s1[24*i+16 +: 8]),
      .io_max    (isVredmax_reg_s1),
      .io_signed (signed_reg_s1),
      .io_d      (vd0_max_sew8[i])
    );
  end
  compare_2to1_2 compare0_2to1_sew8 (
    .io_a      (vs12m_bits_reg_s1[127:120]),
    .io_b      (vs1_zero_reg_s1[7:0]),
    .io_max    (isVredmax_reg_s1),
    .io_signed (signed_reg_s1),
    .io_c      (vd0_max_sew8[5])
  );

  // ---- §3.4 逻辑运算：64 位 3 输入合并，再逐级对折到 32/16/8 位（and 优先，其次 or、xor） ----
  function automatic logic [63:0] logic_op(input logic [63:0] a, input logic [63:0] b,
                                           input logic is_and, input logic is_or, input logic is_xor);
    if (is_and)      return a & b;
    else if (is_or)  return a | b;
    else if (is_xor) return a ^ b;
    else             return 64'd0;
  endfunction
  logic [63:0] vd_logical [4];     // [0]=64 位, [1]=32 位, [2]=16 位, [3]=8 位（零扩展）
  always_comb begin
    vd_logical[0] = logic_op(logic_op(vs1_zero_logical_reg_s1, vs12m_bits_reg_s1[127:64],
                                      vredand_vs_reg_s1, vredor_vs_reg_s1, vredxor_vs_reg_s1),
                             vs12m_bits_reg_s1[63:0],
                             vredand_vs_reg_s1, vredor_vs_reg_s1, vredxor_vs_reg_s1);
    for (int k = 1; k < 4; k++) begin
      int half;
      half = 64 >> k;
      vd_logical[k] = logic_op((vd_logical[k-1] >> half) & ((64'd1 << half) - 64'd1),
                               vd_logical[k-1] & ((64'd1 << half) - 64'd1),
                               vredand_vs_reg_s1, vredor_vs_reg_s1, vredxor_vs_reg_s1);
    end
  end
  // alu uop 的逻辑运算：高半与低半直接按位合并
  logic [127:0] vd_logical_alu;
  assign vd_logical_alu = vredand_vs_reg_s1 ? vs12m_bits_reg_s1[255:128] & vs12m_bits_reg_s1[127:0]
                        : vredor_vs_reg_s1  ? vs12m_bits_reg_s1[255:128] | vs12m_bits_reg_s1[127:0]
                        : vredxor_vs_reg_s1 ? vs12m_bits_reg_s1[255:128] ^ vs12m_bits_reg_s1[127:0]
                        : 128'd0;

  // ---- §3.5 下一拍 vd_reg / old_vd_reg 的取值 ----
  logic [127:0] vd_next, old_vd_next;
  always_comb begin
    if (vredand_vs_reg_s1 || vredor_vs_reg_s1 || vredxor_vs_reg_s1) begin
      // 逻辑：alu uop 存合并后的向量；归约 uop 存已经折到 vd sew 宽的结果
      vd_next = alu_uop_reg_s1 ? vd_logical_alu
                               : {64'd0, vd_logical[2'(~vdType_reg_s1[1:0])]};
    end else if (isVredmax_reg_s1 || isVredmin_reg_s1) begin
      // max/min：alu uop 存高半（s2 再与低半比）；归约 uop 存第一层比较的结果
      if (alu_uop_reg_s1) vd_next = hi_vs;
      else case (vd_vsew_reg_s1)
        2'd0:    vd_next = {80'd0, vd0_max_sew8[5], vd0_max_sew8[4], vd0_max_sew8[3],
                            vd0_max_sew8[2], vd0_max_sew8[1], vd0_max_sew8[0]};
        2'd1:    vd_next = {80'd0, vd0_max_sew16[2], vd0_max_sew16[1], vd0_max_sew16[0]};
        2'd2:    vd_next = {64'd0, vd0_max_sew32[1], vd0_max_sew32[0]};
        default: vd_next = {64'd0, vd_max_sew64};
      endcase
    end else begin
      // 加法：alu / 加宽 alu uop 存高半；归约 uop 存 CSA 树的 {sum, carry}
      if (alu_uop_reg_s1 || widen_alu_uop_reg_s1) vd_next = hi_vs;
      else case (vd_vsew_reg_s1)
        2'd0:    vd_next = {112'd0, sum3_sew8, carry3_sew8};
        2'd1:    vd_next = {96'd0, sum2_sew16, carry2_sew16};
        2'd2:    vd_next = {64'd0, sum1_sew32, carry1_sew32};
        default: vd_next = {sum_sew64, carry_sew64};
      endcase
    end
    old_vd_next = (alu_uop_reg_s1 || widen_alu_uop_reg_s1) ? lo_vs : old_vd_reg_s1;
  end

  // ===========================================================================
  // §4 s1 → s2 寄存器
  // ===========================================================================
  logic [127:0] vd_reg, old_vd_reg;
  logic         signed_reg;
  logic [1:0]   vd_vsew_reg;
  logic         ta_reg;
  logic [7:0]   vl_reg;
  logic         isVredmax_reg, isVredmin_reg;
  logic         reg_vredand_vs, reg_vredor_vs, reg_vredxor_vs;
  logic         alu_uop_reg, widen_alu_uop_reg;
  logic [1:0]   vdType_reg;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      vd_reg            <= '0;
      old_vd_reg        <= '0;
      signed_reg        <= 1'b0;
      vd_vsew_reg       <= '0;
      ta_reg            <= 1'b0;
      vl_reg            <= '0;
      isVredmax_reg     <= 1'b0;
      isVredmin_reg     <= 1'b0;
      reg_vredand_vs    <= 1'b0;
      reg_vredor_vs     <= 1'b0;
      reg_vredxor_vs    <= 1'b0;
      alu_uop_reg       <= 1'b0;
      widen_alu_uop_reg <= 1'b0;
      vdType_reg        <= '0;
    end else if (fire_reg_s1) begin
      vd_reg            <= vd_next;
      old_vd_reg        <= old_vd_next;
      signed_reg        <= signed_reg_s1;
      vd_vsew_reg       <= vd_vsew_reg_s1;
      ta_reg            <= ta_reg_s1;
      vl_reg            <= vl_reg_s1;
      isVredmax_reg     <= isVredmax_reg_s1;
      isVredmin_reg     <= isVredmin_reg_s1;
      reg_vredand_vs    <= vredand_vs_reg_s1;
      reg_vredor_vs     <= vredor_vs_reg_s1;
      reg_vredxor_vs    <= vredxor_vs_reg_s1;
      alu_uop_reg       <= alu_uop_reg_s1;
      widen_alu_uop_reg <= widen_alu_uop_reg_s1;
      vdType_reg        <= vdType_reg_s1[1:0];
    end
  end

  // ===========================================================================
  // §5 s2：alu uop 的逐元素运算 / 归约树收尾 / 尾部处理
  // ===========================================================================
  logic sub_reg, logical_reg;
  assign sub_reg     = isVredmax_reg | isVredmin_reg;      // max/min 用减法比大小
  assign logical_reg = reg_vredand_vs | reg_vredor_vs | reg_vredxor_vs;

  // ---- §5.1 alu uop：16 个 8 位加法器，进位链在 vd 元素边界断开 ----
  // 加法：vd_reg + old_vd_reg；max/min：vd_reg + ~old_vd_reg + 1（= 高半 − 低半），看借位比大小。
  logic [127:0] vs_lo_adjust;
  logic [7:0]   byte_sum [16];
  logic [15:0]  cout, less, sel_lo;
  logic [127:0] alu_sum_vd, alu_max_vd, alu_vd;
  assign vs_lo_adjust = old_vd_reg ^ {128{sub_reg}};
  // 元素字节掩码：sew=8/16/32/64 → 一个元素占 1/2/4/8 字节，低 vdType 位是"元素内字节序号"
  logic [3:0] elem_byte_mask;
  assign elem_byte_mask = 4'((1 << vdType_reg) - 1);
  // 进位链用 genvar 展开成连续赋值（逐字节一条，不在同一个 always_comb 里自读自写）
  for (genvar i = 0; i < 16; i++) begin : g_alu_byte
    logic cin;                        // 元素最低字节吃 sub（减法的 +1），其余吃下一字节的进位
    if (i == 0) begin : g_first
      assign cin = sub_reg;
    end else begin : g_rest
      assign cin = ((4'(i) & elem_byte_mask) == 4'd0) ? sub_reg : cout[i - 1];
    end
    assign {cout[i], byte_sum[i]} = 9'(vs_lo_adjust[8*i +: 8]) + 9'(vd_reg[8*i +: 8]) + 9'(cin);
    assign less[i]   = signed_reg ? (vd_reg[8*i+7] ^ vs_lo_adjust[8*i+7] ^ cout[i]) : !cout[i];
    assign sel_lo[i] = less[i] == isVredmax_reg;   // max：高半更小就取低半；min 反之
    // 本字节所在元素的最高字节（符号/借位在那里）：4 位下标，恒在 0..15 内
    logic [3:0] top;
    assign top = 4'(i) | elem_byte_mask;
    assign alu_sum_vd[8*i +: 8] = byte_sum[i];
    assign alu_max_vd[8*i +: 8] = sel_lo[top] ? old_vd_reg[8*i +: 8] : vd_reg[8*i +: 8];
  end
  assign alu_vd = logical_reg ? vd_reg : (sub_reg ? alu_max_vd : alu_sum_vd);

  // ---- §5.2 归约 uop：sum + carry 相加；比较树最后一层 ----
  logic [63:0] sum_vd, max_vd;
  always_comb begin
    case (vd_vsew_reg)
      2'd0:    sum_vd = {56'd0, 8'(vd_reg[15:8] + vd_reg[7:0])};
      2'd1:    sum_vd = {48'd0, 16'(vd_reg[31:16] + vd_reg[15:0])};
      2'd2:    sum_vd = {32'd0, 32'(vd_reg[63:32] + vd_reg[31:0])};
      default: sum_vd = 64'(vd_reg[127:64] + vd_reg[63:0]);
    endcase
  end

  logic [31:0] vd1_max_sew32;
  compare_2to1 compare1_2to1_sew32 (
    .io_a      (vd_reg[31:0]),
    .io_b      (vd_reg[63:32]),
    .io_max    (isVredmax_reg),
    .io_signed (signed_reg),
    .io_c      (vd1_max_sew32)
  );
  logic [15:0] vd1_max_sew16;
  compare_3to1_2 compare1_3to1_sew16 (
    .io_a      (vd_reg[15:0]),
    .io_b      (vd_reg[31:16]),
    .io_c      (vd_reg[47:32]),
    .io_max    (isVredmax_reg),
    .io_signed (signed_reg),
    .io_d      (vd1_max_sew16)
  );
  logic [7:0] vd1_max_sew8 [2], vd2_max_sew8;
  compare_3to1_6 compare_3to1_sew8_5 (
    .io_a      (vd_reg[7:0]),
    .io_b      (vd_reg[15:8]),
    .io_c      (vd_reg[23:16]),
    .io_max    (isVredmax_reg),
    .io_signed (signed_reg),
    .io_d      (vd1_max_sew8[0])
  );
  compare_3to1_6 compare_3to1_sew8_6 (
    .io_a      (vd_reg[31:24]),
    .io_b      (vd_reg[39:32]),
    .io_c      (vd_reg[47:40]),
    .io_max    (isVredmax_reg),
    .io_signed (signed_reg),
    .io_d      (vd1_max_sew8[1])
  );
  compare_2to1_2 compare1_2to1_sew8 (
    .io_a      (vd1_max_sew8[1]),
    .io_b      (vd1_max_sew8[0]),
    .io_max    (isVredmax_reg),
    .io_signed (signed_reg),
    .io_c      (vd2_max_sew8)
  );
  always_comb begin
    case (vd_vsew_reg)
      2'd0:    max_vd = {56'd0, vd2_max_sew8};
      2'd1:    max_vd = {48'd0, vd1_max_sew16};
      2'd2:    max_vd = {32'd0, vd1_max_sew32};
      default: max_vd = vd_reg[63:0];          // sew64 在 s1 已经比完
    endcase
  end

  logic [127:0] red_vd;
  assign red_vd = logical_reg ? vd_reg : {64'd0, sub_reg ? max_vd : sum_vd};

  // ---- §5.3 尾部：结果只占 vd 第 0 个元素；其余位 ta ? 全 1 : old_vd；vl==0 整体保持 old_vd ----
  logic [6:0]   vd_vsew_bits_reg;
  logic [127:0] elem0_mask, tail_ones, red_vd_tail;
  assign vd_vsew_bits_reg = 7'd8 << vd_vsew_reg;
  assign elem0_mask       = {128{1'b1}} >> 8'(8'd128 - {1'b0, vd_vsew_bits_reg});
  assign tail_ones        = {128{1'b1}} << vd_vsew_bits_reg;
  assign red_vd_tail      = (vl_reg == 8'd0) ? old_vd_reg
                          : ta_reg ? (tail_ones | (red_vd & elem0_mask))
                          : ((tail_ones & old_vd_reg) | (red_vd & elem0_mask));

  assign out_vd = (alu_uop_reg || widen_alu_uop_reg) ? alu_vd : red_vd_tail;
endmodule

module Reduction (
  input  logic         clock,
  input  logic         reset,
  input  logic         io_in_valid,
  input  logic [5:0]   io_in_bits_opcode_op,
  input  logic         io_in_bits_info_vm,
  input  logic         io_in_bits_info_ta,
  input  logic [2:0]   io_in_bits_info_vlmul,
  input  logic [7:0]   io_in_bits_info_vl,
  input  logic [5:0]   io_in_bits_info_uopIdx,
  input  logic [3:0]   io_in_bits_srcType_0,
  input  logic [3:0]   io_in_bits_vdType,
  input  logic [127:0] io_in_bits_vs1,
  input  logic [127:0] io_in_bits_vs2,
  input  logic [127:0] io_in_bits_old_vd,
  input  logic [127:0] io_in_bits_mask,
  output logic [127:0] io_out_vd
);
  xs_Reduction_core u_core (
    .clock    (clock),
    .reset    (reset),
    .in_valid (io_in_valid),
    .opcode   (io_in_bits_opcode_op),
    .vm       (io_in_bits_info_vm),
    .ta       (io_in_bits_info_ta),
    .vlmul    (io_in_bits_info_vlmul),
    .vl       (io_in_bits_info_vl),
    .uop_idx  (io_in_bits_info_uopIdx),
    .src_type (io_in_bits_srcType_0),
    .vd_type  (io_in_bits_vdType),
    .vs1      (io_in_bits_vs1),
    .vs2      (io_in_bits_vs2),
    .old_vd   (io_in_bits_old_vd),
    .mask     (io_in_bits_mask),
    .out_vd   (io_out_vd)
  );
endmodule
