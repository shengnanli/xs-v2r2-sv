// =============================================================================
// fpdiv_r64_block_vector.sv —— 向量浮点除法器的"一拍算 3 个基 4 商位"迭代块（纯组合）
//
// 在哪一层：yunsuan VectorFloatDivider（SRT 基 4 浮点除法，f16/f32/f64 向量）的核心迭代级。
//   父级每拍把当前的冗余余数（sum/carry 两路）、除数和"上一拍预算好的 6/7 位余数片"送进来，
//   本块串联 3 级基 4 迭代（s0/s1/s2），返回 3 个商位、迭代后的余数，以及下一拍 s0/s1
//   商位选择所需的 6 位 / 7 位余数片（提前一拍算好，缩短关键路径）。
// 设计源：yunsuan/vector/VectorFloatDivider.scala class fpdiv_r64_block_vector
//   （参数 S1_SPECULATIVE_QDS=1, S2_SPECULATIVE_QDS=true, QDS_ARCH=2）。golden 里
//   io.is_vec 已被 firtool 折成常量 1（父级 is_vec_q 恒 1），端口表没有它。
//
// 向量通道几何（本文件把 golden 里展开成几百条拼接的位运算收拢为这张表）：
//   格式    通道数  余数宽 REM_W  72 位余数向量里各通道的基位   除数宽 DIV_W  60 位除数向量里的基位
//   f64     1       60            12                              57            3
//   f32     2       31            5, 41                           28            2, 32
//   f16     4       18            0, 18, 36, 54                   15            0, 15, 30, 45
//   余数向量 72 = (3+11+3+1)*4，除数向量 60 = (11+4)*4；通道之间的空隙位恒 0。
//   fp_format_onehot = {f64, f32, f16}，所有按格式的选择都是 Mux1H（按位或），不是优先级。
//
// 一级基 4 迭代（每个通道独立）：
//   商位 q ∈ {+2,+1,0,-1,-2}，one-hot 编码 digit[4:0] = {+2,+1,0,-1,-2}；
//   下一余数 = 4*rem - q*D，用 3:2 CSA 对 5 个 q 各投机算一份（q=0 只是移位），
//   再按本级商位选中一份。除数倍数 ±D/±2D 以 REM_W 位的"扩展除数" ext={2'b0,D,1'b0} 为底：
//   pos1 = ext，pos2 = ext<<1，neg1 = ~ext，neg2 = ~(ext<<1)；补码的 +1 由 mask_one 加在
//   carry 向量的通道最低位上（neg 候选 | mask_one）。f16 四通道在 72 位向量里相邻无空隙，
//   CSA 的进位会跨通道，所以 pos 候选要用 mask_zero 把通道最低位清掉（f16 时）。
// 三级的差别：
//   s0 用一个 200 位 CSA 把三种格式的通道并排一次算完（各通道间隔 3 个 0 位，
//      通道字段 = {余数<<2, 1'b0}，f16 通道 0 没有那个额外低位），算完再按格式抽取、打包；
//   s1/s2 用 72 位 CSA，输入已按格式打包。
//   商位：s0 用 r4_qds_v2（查上一拍送来的 6 位余数片）；s1 用 r4_qds_v2_spec（上一拍送来的
//   7 位余数片 + 除数片，按 s0 商位投机），s2 同样投机，但余数片来自 s0 结果（"S2_SPECULATIVE"）。
//   s1 的商位对 f64/f32 通道各多一套实例（u_r4_qds_s1_4/5/6），按格式选。
// 怪癖（照抄 golden，有些只在非法的多热 fp_format 下才可见，但 FM 在全取值域上比）：
//   - 若干处对 f64 分支用的是已按格式打包（Mux1H 后）的 divisor_mul / 余数向量，而 f32/f16
//     分支用原始 io_divisor_i 片；多热格式下两者不同，本文件逐处保留。
//   - f16 通道 3/2 的 carry 候选（q ∈ {+2,+1,0}）取窗时最低位强制 0，通道 1/0 不强制。
//   - 7 位加法器：通道 0/1 算 (s+c)+d，通道 2/3 算 s+(c+d)（模 2^7 等价，照抄）。
// 子模块（全部为本仓已签核的重写件，实例名与 golden 一致）：
//   CSA3to2_20 ×4（200 位）、CSA3to2_24 ×8（72 位）、r4_qds_v2 ×4、r4_qds_v2_spec ×11。
// golden 对照：G1-canonical/golden-rtl/fpdiv_r64_block_vector.sv
// =============================================================================
module xs_fpdiv_r64_block_vector_core (
  input  logic [2:0]  fmt,                 // {f64, f32, f16} one-hot
  input  logic [71:0] rem_s_in,            // 当前余数 sum 向量
  input  logic [71:0] rem_c_in,            // 当前余数 carry 向量
  input  logic [59:0] divisor_in,          // 除数向量
  input  logic [3:0][5:0]      rem6_for_s0,   // 上一拍预算的 s0 商位余数片（每通道）
  input  logic [3:0][6:0]      rem7_for_s1,   // 上一拍预算的 s1 商位余数片（每通道）
  output logic [3:0][2:0][4:0] quo_dig_out,   // [通道][级] 本拍 3 个商位
  output logic [71:0] rem_s_out,           // 迭代后的余数 sum 向量
  output logic [71:0] rem_c_out,           // 迭代后的余数 carry 向量
  output logic [3:0][5:0]      adder6_out,    // 下一拍 s0 商位用的 6 位余数片
  output logic [3:0][6:0]      adder7_out     // 下一拍 s1 商位用的 7 位余数片
);
  // ---------------------------------------------------------------------------
  // §0 通道几何与小工具
  // ---------------------------------------------------------------------------
  localparam int F16 = 0, F32 = 1, F64 = 2;   // fmt 的位序，也是几何表的下标
  localparam int Q_N2 = 0, Q_N1 = 1, Q_Z = 2, Q_P1 = 3, Q_P2 = 4;   // digit[q] 的位序
  function automatic int rem_w(input int f);
    case (f) F64: rem_w = 60; F32: rem_w = 31; default: rem_w = 18; endcase
  endfunction
  function automatic int div_w(input int f);
    case (f) F64: div_w = 57; F32: div_w = 28; default: div_w = 15; endcase
  endfunction
  function automatic int lanes(input int f);
    case (f) F64: lanes = 1; F32: lanes = 2; default: lanes = 4; endcase
  endfunction
  function automatic int lane_base(input int f, input int k);
    case (f) F64: lane_base = 12; F32: lane_base = (k == 0) ? 5 : 41; default: lane_base = 18 * k; endcase
  endfunction
  function automatic int div_base(input int f, input int k);
    case (f) F64: div_base = 3; F32: div_base = (k == 0) ? 2 : 32; default: div_base = 15 * k; endcase
  endfunction
  // s0 的 200 位 CSA 里各通道字段的起点（字段 = {通道 REM_W 位, 1'b0}；f16 通道 0 无额外低位）
  function automatic int field_shift(input int f, input int k);
    case (f) F64: field_shift = 140; F32: field_shift = (k == 0) ? 76 : 108;
             default: field_shift = (k == 0) ? 0 : 19 * k; endcase
  endfunction

  function automatic logic [59:0] lane_mask(input int f);
    lane_mask = (60'd1 << rem_w(f)) - 60'd1;
  endfunction

  // 从 72 位余数向量里取第 k 通道（右对齐，高位补 0）
  function automatic logic [59:0] lane_of(input logic [71:0] v, input int f, input int k);
    lane_of = 60'(v >> lane_base(f, k)) & lane_mask(f);
  endfunction

  // 把 4 个通道（右对齐）打包回 72 位向量；没有的通道传 0
  function automatic logic [71:0] pack72(input int f, input logic [3:0][59:0] l);
    pack72 = '0;
    for (int k = 0; k < lanes(f); k++)
      pack72 |= 72'(l[k] & lane_mask(f)) << lane_base(f, k);
  endfunction

  // 除数倍数（REM_W 位，右对齐）：q 用 digit 位序
  function automatic logic [59:0] div_mul(input logic [59:0] d, input int q, input int f, input int k);
    logic [56:0] dl;
    logic [59:0] ext, ext2;
    dl   = 57'(d >> div_base(f, k)) & 57'((57'd1 << div_w(f)) - 57'd1);
    ext  = 60'(dl) << 1;                         // {2'b0, D, 1'b0}
    ext2 = (ext << 1) & lane_mask(f);
    case (q)
      Q_P1:    div_mul = ext;
      Q_P2:    div_mul = ext2;
      Q_N1:    div_mul = ~ext  & lane_mask(f);
      default: div_mul = ~ext2 & lane_mask(f);   // Q_N2
    endcase
  endfunction

  // 除数的 7 位 / 8 位高位片（商位选择与下一拍余数片用）：pos2 从 DIV_W-2 起，pos1 从 DIV_W-1 起
  function automatic logic [6:0] div7(input logic [59:0] d, input int q, input int f, input int k);
    logic [56:0] dl;
    dl = 57'(d >> div_base(f, k));
    case (q)
      Q_P2:    div7 = dl[div_w(f)-2 -: 7];
      Q_P1:    div7 = dl[div_w(f)-1 -: 7];
      Q_N1:    div7 = ~dl[div_w(f)-1 -: 7];
      default: div7 = ~dl[div_w(f)-2 -: 7];
    endcase
  endfunction
  function automatic logic [7:0] div8(input logic [59:0] d, input int q, input int f, input int k);
    logic [56:0] dl;
    dl = 57'(d >> div_base(f, k));
    case (q)
      Q_P2:    div8 = dl[div_w(f)-4 -: 8];
      Q_P1:    div8 = dl[div_w(f)-3 -: 8];
      Q_N1:    div8 = ~dl[div_w(f)-3 -: 8];
      default: div8 = ~dl[div_w(f)-4 -: 8];
    endcase
  endfunction

  // 通道余数的 7 位 / 8 位窗（给商位选择 / 下一拍余数片）
  function automatic logic [6:0] win7(input logic [59:0] lane, input int f);
    win7 = lane[rem_w(f)-5 -: 7];
  endfunction
  function automatic logic [7:0] win8(input logic [59:0] lane, input int f);
    win8 = lane[rem_w(f)-7 -: 8];
  endfunction

  // 按格式 Mux1H（按位或）
  function automatic logic [71:0] fmux72(input logic [2:0] f, input logic [71:0] x64, x32, x16);
    fmux72 = ({72{f[F64]}} & x64) | ({72{f[F32]}} & x32) | ({72{f[F16]}} & x16);
  endfunction
  function automatic logic [7:0] fmux8(input logic [2:0] f, input logic [7:0] x64, x32, x16);
    fmux8 = ({8{f[F64]}} & x64) | ({8{f[F32]}} & x32) | ({8{f[F16]}} & x16);
  endfunction
  function automatic logic [4:0] fmux5(input logic [2:0] f, input logic [4:0] x64, x32, x16);
    fmux5 = ({5{f[F64]}} & x64) | ({5{f[F32]}} & x32) | ({5{f[F16]}} & x16);
  endfunction

  // 按商位 one-hot 选候选（按位或）
  function automatic logic [71:0] dmux72(input logic [4:0] dig, input logic [4:0][71:0] c);
    dmux72 = '0;
    for (int q = 0; q < 5; q++) dmux72 |= {72{dig[q]}} & c[q];
  endfunction

  // 通道最低位掩码：f16 时四个通道的最低位（pos 候选清零 / neg 候选置 1 做补码 +1）
  logic [71:0] mask_zero, mask_one;
  always_comb begin
    mask_zero = '1;
    mask_one  = '0;
    for (int k = 0; k < 4; k++) begin
      mask_zero[lane_base(F16, k)] = ~fmt[F16];
      mask_one [lane_base(F16, k)] = fmt[F16];
    end
    mask_one[lane_base(F32, 0)] = fmt[F32];
    mask_one[lane_base(F32, 1)] = fmt[F32];
    mask_one[lane_base(F64, 0)] = fmt[F64];
  end

  // ---------------------------------------------------------------------------
  // §1 除数倍数：按格式打包成 72 位向量（s1/s2 CSA 的第三输入）
  // ---------------------------------------------------------------------------
  logic [4:0][71:0] divisor_mul;   // 下标 = digit 位序；Q_Z 不用
  logic [3:0][59:0] dm64, dm32, dm16;
  always_comb begin
    for (int q = 0; q < 5; q++) begin
      for (int k = 0; k < 4; k++) begin
        dm64[k] = (k < 1) ? div_mul(divisor_in, q, F64, k) : '0;
        dm32[k] = (k < 2) ? div_mul(divisor_in, q, F32, k) : '0;
        dm16[k] = div_mul(divisor_in, q, F16, k);
      end
      divisor_mul[q] = fmux72(fmt, pack72(F64, dm64), pack72(F32, dm32), pack72(F16, dm16));
    end
  end

  // ---------------------------------------------------------------------------
  // §2 s0 级：200 位 CSA，三种格式的通道并排投机
  // ---------------------------------------------------------------------------
  logic [199:0] csa0_in_a, csa0_in_b;
  logic [4:0][199:0] csa0_in_c;
  logic [4:0][199:0] csa0_sum, csa0_car;

  // 字段内容：余数 {rem[REM_W-3:0], 2'b0}（即 4*rem 截断），再附一个 0 位做除数对齐
  function automatic logic [199:0] field200(input logic [59:0] lane, input int f, input int k);
    field200 = 200'(lane & lane_mask(f)) << field_shift(f, k);
  endfunction
  always_comb begin
    csa0_in_a = '0; csa0_in_b = '0;
    for (int f = 0; f < 3; f++)
      for (int k = 0; k < lanes(f); k++) begin
        csa0_in_a |= field200(lane_of(rem_s_in, f, k) << 2, f, k);
        csa0_in_b |= field200(lane_of(rem_c_in, f, k) << 2, f, k);
      end
    for (int q = 0; q < 5; q++) begin
      csa0_in_c[q] = '0;
      for (int f = 0; f < 3; f++)
        for (int k = 0; k < lanes(f); k++)
          csa0_in_c[q] |= field200(div_mul(divisor_in, q, f, k), f, k);
    end
  end

  CSA3to2_20 U_CSA_0_4 (.io_in_a(csa0_in_a), .io_in_b(csa0_in_b), .io_in_c(csa0_in_c[Q_P2]),
                        .io_out_sum(csa0_sum[Q_P2]), .io_out_car(csa0_car[Q_P2]));
  CSA3to2_20 U_CSA_0_3 (.io_in_a(csa0_in_a), .io_in_b(csa0_in_b), .io_in_c(csa0_in_c[Q_P1]),
                        .io_out_sum(csa0_sum[Q_P1]), .io_out_car(csa0_car[Q_P1]));
  CSA3to2_20 U_CSA_0_1 (.io_in_a(csa0_in_a), .io_in_b(csa0_in_b), .io_in_c(csa0_in_c[Q_N1]),
                        .io_out_sum(csa0_sum[Q_N1]), .io_out_car(csa0_car[Q_N1]));
  CSA3to2_20 U_CSA_0_0 (.io_in_a(csa0_in_a), .io_in_b(csa0_in_b), .io_in_c(csa0_in_c[Q_N2]),
                        .io_out_sum(csa0_sum[Q_N2]), .io_out_car(csa0_car[Q_N2]));
  // q=0 候选不走 CSA：直接是 4*rem
  assign csa0_sum[Q_Z] = csa0_in_a;
  assign csa0_car[Q_Z] = csa0_in_b;

  // 按格式/通道从 200 位结果里抽出通道（原始、未按格式合并）：字段去掉附加低位
  logic [2:0][4:0][3:0][59:0] raw0_s, raw0_c;   // [格式][q][通道]
  always_comb begin
    for (int f = 0; f < 3; f++)
      for (int k = 0; k < 4; k++)
        for (int q = 0; q < 5; q++) begin
          raw0_s[f][q][k] = (k < lanes(f)) ? 60'(csa0_sum[q] >> field_shift(f, k)) & lane_mask(f) : '0;
          raw0_c[f][q][k] = (k < lanes(f)) ? 60'(csa0_car[q] >> field_shift(f, k)) & lane_mask(f) : '0;
        end
  end

  // 按格式合并后的 5 个候选（72 位）；neg 候选的 carry 加补码 +1
  logic [4:0][71:0] spec0_s, spec0_c;
  always_comb begin
    for (int q = 0; q < 5; q++) begin
      spec0_s[q] = fmux72(fmt, pack72(F64, raw0_s[F64][q]), pack72(F32, raw0_s[F32][q]), pack72(F16, raw0_s[F16][q]));
      spec0_c[q] = fmux72(fmt, pack72(F64, raw0_c[F64][q]), pack72(F32, raw0_c[F32][q]), pack72(F16, raw0_c[F16][q]));
      if (q == Q_N1 || q == Q_N2) spec0_c[q] |= mask_one;
    end
  end

  // s0 商位：上一拍算好的 6 位余数片直接查表
  logic [3:0][4:0] dig0;
  r4_qds_v2 u_r4_qds_s0_0 (.io_rem_i(rem6_for_s0[0]), .io_quo_dig_o(dig0[0]));
  r4_qds_v2 u_r4_qds_s0_1 (.io_rem_i(rem6_for_s0[1]), .io_quo_dig_o(dig0[1]));
  r4_qds_v2 u_r4_qds_s0_2 (.io_rem_i(rem6_for_s0[2]), .io_quo_dig_o(dig0[2]));
  r4_qds_v2 u_r4_qds_s0_3 (.io_rem_i(rem6_for_s0[3]), .io_quo_dig_o(dig0[3]));

  // 每通道按自己的商位选中候选（整向量选，取窗在后）
  logic [3:0][71:0] sel0_s, sel0_c;
  always_comb
    for (int k = 0; k < 4; k++) begin
      sel0_s[k] = dmux72(dig0[k], spec0_s);
      sel0_c[k] = dmux72(dig0[k], spec0_c);
    end

  // ---------------------------------------------------------------------------
  // §3 级间打包：把各通道选中的余数 ×4 再按格式打包成下一级 72 位 CSA 的 a/b 输入
  //   f16 通道 3/2 的 carry 候选 q ∈ {+2,+1,0} 取窗时最低位强制 0（golden 怪癖，照抄）
  // ---------------------------------------------------------------------------
  function automatic logic [71:0] next_in_a(input logic [2:0] f, input logic [3:0][71:0] sel);
    logic [3:0][59:0] l64, l32, l16;
    for (int k = 0; k < 4; k++) begin
      l64[k] = (k < 1) ? lane_of(sel[k], F64, k) << 2 : '0;
      l32[k] = (k < 2) ? lane_of(sel[k], F32, k) << 2 : '0;
      l16[k] = lane_of(sel[k], F16, k) << 2;
    end
    next_in_a = fmux72(f, pack72(F64, l64), pack72(F32, l32), pack72(F16, l16));
  endfunction
  function automatic logic [71:0] next_in_b(input logic [2:0] f, input logic [3:0][71:0] sel,
                                            input logic [3:0][4:0] dig, input logic [4:0][71:0] cand);
    logic [3:0][59:0] l64, l32, l16;
    logic [59:0] w;
    for (int k = 0; k < 4; k++) begin
      l64[k] = (k < 1) ? lane_of(sel[k], F64, k) << 2 : '0;
      l32[k] = (k < 2) ? lane_of(sel[k], F32, k) << 2 : '0;
      if (k < 2) l16[k] = lane_of(sel[k], F16, k) << 2;
      else begin
        l16[k] = '0;
        for (int q = 0; q < 5; q++) begin
          w = lane_of(cand[q], F16, k);
          if (q >= Q_Z) w[0] = 1'b0;
          l16[k] |= {60{dig[k][q]}} & (w << 2);
        end
      end
    end
    next_in_b = fmux72(f, pack72(F64, l64), pack72(F32, l32), pack72(F16, l16));
  endfunction

  logic [71:0] csa1_in_a, csa1_in_b;
  assign csa1_in_a = next_in_a(fmt, sel0_s);
  assign csa1_in_b = next_in_b(fmt, sel0_c, dig0, spec0_c);

  // ---------------------------------------------------------------------------
  // §4 s1 级：72 位 CSA + 投机商位选择
  // ---------------------------------------------------------------------------
  logic [4:0][71:0] csa1_sum, csa1_car;
  CSA3to2_24 U_CSA_1_4 (.io_in_a(csa1_in_a), .io_in_b(csa1_in_b), .io_in_c(divisor_mul[Q_P2]),
                        .io_out_sum(csa1_sum[Q_P2]), .io_out_car(csa1_car[Q_P2]));
  CSA3to2_24 U_CSA_1_3 (.io_in_a(csa1_in_a), .io_in_b(csa1_in_b), .io_in_c(divisor_mul[Q_P1]),
                        .io_out_sum(csa1_sum[Q_P1]), .io_out_car(csa1_car[Q_P1]));
  CSA3to2_24 U_CSA_1_1 (.io_in_a(csa1_in_a), .io_in_b(csa1_in_b), .io_in_c(divisor_mul[Q_N1]),
                        .io_out_sum(csa1_sum[Q_N1]), .io_out_car(csa1_car[Q_N1]));
  CSA3to2_24 U_CSA_1_0 (.io_in_a(csa1_in_a), .io_in_b(csa1_in_b), .io_in_c(divisor_mul[Q_N2]),
                        .io_out_sum(csa1_sum[Q_N2]), .io_out_car(csa1_car[Q_N2]));
  assign csa1_sum[Q_Z] = csa1_in_a;
  assign csa1_car[Q_Z] = csa1_in_b;

  // 候选：pos 的 carry 清通道最低位，neg 的加补码 +1，q=0 原样
  function automatic logic [71:0] carry_cand(input int q, input logic [71:0] car, input logic [71:0] mz, mo);
    case (q)
      Q_P2, Q_P1: carry_cand = car & mz;
      Q_N1, Q_N2: carry_cand = car | mo;
      default:    carry_cand = car;
    endcase
  endfunction
  logic [4:0][71:0] spec1_s, spec1_c;
  always_comb
    for (int q = 0; q < 5; q++) begin
      spec1_s[q] = csa1_sum[q];
      spec1_c[q] = carry_cand(q, csa1_car[q], mask_zero, mask_one);
    end

  // s1 商位：7 个投机实例——f16 四通道各一个，f32 两通道各一个，f64 一个；再按格式选
  logic [6:0][4:0] dig1_raw;   // 0..3: f16 通道 k；4: f32 通道 0；5: f32 通道 1；6: f64
  r4_qds_v2_spec u_r4_qds_s1_0 (.io_rem_i(rem7_for_s1[0]),
    .io_divisor_mul_pos_2_i(div7(divisor_in, Q_P2, F16, 0)), .io_divisor_mul_pos_1_i(div7(divisor_in, Q_P1, F16, 0)),
    .io_divisor_mul_neg_1_i(div7(divisor_in, Q_N1, F16, 0)), .io_divisor_mul_neg_2_i(div7(divisor_in, Q_N2, F16, 0)),
    .io_prev_quo_dig_i(dig0[0]), .io_quo_dig_o(dig1_raw[0]));
  r4_qds_v2_spec u_r4_qds_s1_1 (.io_rem_i(rem7_for_s1[1]),
    .io_divisor_mul_pos_2_i(div7(divisor_in, Q_P2, F16, 1)), .io_divisor_mul_pos_1_i(div7(divisor_in, Q_P1, F16, 1)),
    .io_divisor_mul_neg_1_i(div7(divisor_in, Q_N1, F16, 1)), .io_divisor_mul_neg_2_i(div7(divisor_in, Q_N2, F16, 1)),
    .io_prev_quo_dig_i(dig0[1]), .io_quo_dig_o(dig1_raw[1]));
  r4_qds_v2_spec u_r4_qds_s1_2 (.io_rem_i(rem7_for_s1[2]),
    .io_divisor_mul_pos_2_i(div7(divisor_in, Q_P2, F16, 2)), .io_divisor_mul_pos_1_i(div7(divisor_in, Q_P1, F16, 2)),
    .io_divisor_mul_neg_1_i(div7(divisor_in, Q_N1, F16, 2)), .io_divisor_mul_neg_2_i(div7(divisor_in, Q_N2, F16, 2)),
    .io_prev_quo_dig_i(dig0[2]), .io_quo_dig_o(dig1_raw[2]));
  r4_qds_v2_spec u_r4_qds_s1_3 (.io_rem_i(rem7_for_s1[3]),
    .io_divisor_mul_pos_2_i(div7(divisor_in, Q_P2, F16, 3)), .io_divisor_mul_pos_1_i(div7(divisor_in, Q_P1, F16, 3)),
    .io_divisor_mul_neg_1_i(div7(divisor_in, Q_N1, F16, 3)), .io_divisor_mul_neg_2_i(div7(divisor_in, Q_N2, F16, 3)),
    .io_prev_quo_dig_i(dig0[3]), .io_quo_dig_o(dig1_raw[3]));
  r4_qds_v2_spec u_r4_qds_s1_4 (.io_rem_i(rem7_for_s1[0]),
    .io_divisor_mul_pos_2_i(div7(divisor_in, Q_P2, F32, 0)), .io_divisor_mul_pos_1_i(div7(divisor_in, Q_P1, F32, 0)),
    .io_divisor_mul_neg_1_i(div7(divisor_in, Q_N1, F32, 0)), .io_divisor_mul_neg_2_i(div7(divisor_in, Q_N2, F32, 0)),
    .io_prev_quo_dig_i(dig0[0]), .io_quo_dig_o(dig1_raw[4]));
  r4_qds_v2_spec u_r4_qds_s1_5 (.io_rem_i(rem7_for_s1[1]),
    .io_divisor_mul_pos_2_i(div7(divisor_in, Q_P2, F32, 1)), .io_divisor_mul_pos_1_i(div7(divisor_in, Q_P1, F32, 1)),
    .io_divisor_mul_neg_1_i(div7(divisor_in, Q_N1, F32, 1)), .io_divisor_mul_neg_2_i(div7(divisor_in, Q_N2, F32, 1)),
    .io_prev_quo_dig_i(dig0[1]), .io_quo_dig_o(dig1_raw[5]));
  r4_qds_v2_spec u_r4_qds_s1_6 (.io_rem_i(rem7_for_s1[0]),
    .io_divisor_mul_pos_2_i(div7(divisor_in, Q_P2, F64, 0)), .io_divisor_mul_pos_1_i(div7(divisor_in, Q_P1, F64, 0)),
    .io_divisor_mul_neg_1_i(div7(divisor_in, Q_N1, F64, 0)), .io_divisor_mul_neg_2_i(div7(divisor_in, Q_N2, F64, 0)),
    .io_prev_quo_dig_i(dig0[0]), .io_quo_dig_o(dig1_raw[6]));

  logic [3:0][4:0] dig1;
  assign dig1[0] = fmux5(fmt, dig1_raw[6], dig1_raw[4], dig1_raw[0]);
  assign dig1[1] = fmt[F32] ? dig1_raw[5] : dig1_raw[1];     // 通道 1 只在 f32/f16 存在
  assign dig1[2] = dig1_raw[2];
  assign dig1[3] = dig1_raw[3];

  logic [3:0][71:0] sel1_s, sel1_c;
  always_comb
    for (int k = 0; k < 4; k++) begin
      sel1_s[k] = dmux72(dig1[k], spec1_s);
      sel1_c[k] = dmux72(dig1[k], spec1_c);
    end

  logic [71:0] csa2_in_a, csa2_in_b;
  assign csa2_in_a = next_in_a(fmt, sel1_s);
  assign csa2_in_b = next_in_b(fmt, sel1_c, dig1, spec1_c);

  // ---------------------------------------------------------------------------
  // §5 s2 级：72 位 CSA；商位由 s0 的结果投机算出（S2_SPECULATIVE_QDS）
  // ---------------------------------------------------------------------------
  logic [4:0][71:0] csa2_sum, csa2_car;
  CSA3to2_24 U_CSA_2_4 (.io_in_a(csa2_in_a), .io_in_b(csa2_in_b), .io_in_c(divisor_mul[Q_P2]),
                        .io_out_sum(csa2_sum[Q_P2]), .io_out_car(csa2_car[Q_P2]));
  CSA3to2_24 U_CSA_2_3 (.io_in_a(csa2_in_a), .io_in_b(csa2_in_b), .io_in_c(divisor_mul[Q_P1]),
                        .io_out_sum(csa2_sum[Q_P1]), .io_out_car(csa2_car[Q_P1]));
  CSA3to2_24 U_CSA_2_1 (.io_in_a(csa2_in_a), .io_in_b(csa2_in_b), .io_in_c(divisor_mul[Q_N1]),
                        .io_out_sum(csa2_sum[Q_N1]), .io_out_car(csa2_car[Q_N1]));
  CSA3to2_24 U_CSA_2_0 (.io_in_a(csa2_in_a), .io_in_b(csa2_in_b), .io_in_c(divisor_mul[Q_N2]),
                        .io_out_sum(csa2_sum[Q_N2]), .io_out_car(csa2_car[Q_N2]));
  assign csa2_sum[Q_Z] = csa2_in_a;
  assign csa2_car[Q_Z] = csa2_in_b;

  logic [4:0][71:0] spec2_s, spec2_c;
  always_comb
    for (int q = 0; q < 5; q++) begin
      spec2_s[q] = csa2_sum[q];
      spec2_c[q] = carry_cand(q, csa2_car[q], mask_zero, mask_one);
    end

  // s2 商位的余数片：s0 各候选在本通道的 7 位窗 sum+carry，按 s0 商位选。
  //   CSA 候选用 200 位 CSA 的原始字段；q=0 候选用按格式合并后的 spec0（golden 如此）。
  logic [3:0][6:0] s2_rem;
  logic [4:0][6:0] s2c7;
  logic [6:0] s2w64, s2w32, s2w16;
  always_comb begin
    for (int k = 0; k < 4; k++) begin
      for (int q = 0; q < 5; q++) begin
        if (q == Q_Z) begin
          s2w64 = 7'(win7(lane_of(spec0_s[q], F64, 0), F64) + win7(lane_of(spec0_c[q], F64, 0), F64));
          s2w32 = 7'(win7(lane_of(spec0_s[q], F32, k), F32) + win7(lane_of(spec0_c[q], F32, k), F32));
          s2w16 = 7'(win7(lane_of(spec0_s[q], F16, k), F16) + win7(lane_of(spec0_c[q], F16, k), F16));
        end else begin
          s2w64 = 7'(win7(raw0_s[F64][q][0], F64) + win7(raw0_c[F64][q][0], F64));
          s2w32 = 7'(win7(raw0_s[F32][q][k], F32) + win7(raw0_c[F32][q][k], F32));
          s2w16 = 7'(win7(raw0_s[F16][q][k], F16) + win7(raw0_c[F16][q][k], F16));
        end
        case (k)
          0:       s2c7[q] = 7'(fmux8(fmt, 8'(s2w64), 8'(s2w32), 8'(s2w16)));
          1:       s2c7[q] = fmt[F32] ? s2w32 : s2w16;
          default: s2c7[q] = s2w16;
        endcase
      end
      s2_rem[k] = '0;
      for (int q = 0; q < 5; q++) s2_rem[k] |= {7{dig0[k][q]}} & s2c7[q];
    end
  end

  // s2 商位用的除数片：通道 0 按格式 Mux1H，通道 1 在 f32/f16 间二选一，通道 2/3 只有 f16
  function automatic logic [6:0] s2_div7(input logic [2:0] f, input logic [59:0] d, input int q, input int k);
    case (k)
      0:       s2_div7 = 7'(fmux8(f, 8'(div7(d, q, F64, 0)), 8'(div7(d, q, F32, 0)), 8'(div7(d, q, F16, 0))));
      1:       s2_div7 = f[F32] ? div7(d, q, F32, 1) : div7(d, q, F16, 1);
      default: s2_div7 = div7(d, q, F16, k);
    endcase
  endfunction

  logic [3:0][4:0] dig2;
  r4_qds_v2_spec u_r4_qds_s2_0 (.io_rem_i(s2_rem[0]),
    .io_divisor_mul_pos_2_i(s2_div7(fmt, divisor_in, Q_P2, 0)), .io_divisor_mul_pos_1_i(s2_div7(fmt, divisor_in, Q_P1, 0)),
    .io_divisor_mul_neg_1_i(s2_div7(fmt, divisor_in, Q_N1, 0)), .io_divisor_mul_neg_2_i(s2_div7(fmt, divisor_in, Q_N2, 0)),
    .io_prev_quo_dig_i(dig1[0]), .io_quo_dig_o(dig2[0]));
  r4_qds_v2_spec u_r4_qds_s2_1 (.io_rem_i(s2_rem[1]),
    .io_divisor_mul_pos_2_i(s2_div7(fmt, divisor_in, Q_P2, 1)), .io_divisor_mul_pos_1_i(s2_div7(fmt, divisor_in, Q_P1, 1)),
    .io_divisor_mul_neg_1_i(s2_div7(fmt, divisor_in, Q_N1, 1)), .io_divisor_mul_neg_2_i(s2_div7(fmt, divisor_in, Q_N2, 1)),
    .io_prev_quo_dig_i(dig1[1]), .io_quo_dig_o(dig2[1]));
  r4_qds_v2_spec u_r4_qds_s2_2 (.io_rem_i(s2_rem[2]),
    .io_divisor_mul_pos_2_i(s2_div7(fmt, divisor_in, Q_P2, 2)), .io_divisor_mul_pos_1_i(s2_div7(fmt, divisor_in, Q_P1, 2)),
    .io_divisor_mul_neg_1_i(s2_div7(fmt, divisor_in, Q_N1, 2)), .io_divisor_mul_neg_2_i(s2_div7(fmt, divisor_in, Q_N2, 2)),
    .io_prev_quo_dig_i(dig1[2]), .io_quo_dig_o(dig2[2]));
  r4_qds_v2_spec u_r4_qds_s2_3 (.io_rem_i(s2_rem[3]),
    .io_divisor_mul_pos_2_i(s2_div7(fmt, divisor_in, Q_P2, 3)), .io_divisor_mul_pos_1_i(s2_div7(fmt, divisor_in, Q_P1, 3)),
    .io_divisor_mul_neg_1_i(s2_div7(fmt, divisor_in, Q_N1, 3)), .io_divisor_mul_neg_2_i(s2_div7(fmt, divisor_in, Q_N2, 3)),
    .io_prev_quo_dig_i(dig1[3]), .io_quo_dig_o(dig2[3]));

  logic [3:0][71:0] sel2_s, sel2_c;
  always_comb
    for (int k = 0; k < 4; k++) begin
      sel2_s[k] = dmux72(dig2[k], spec2_s);
      sel2_c[k] = dmux72(dig2[k], spec2_c);
    end

  // ---------------------------------------------------------------------------
  // §6 输出：商位、迭代后的余数（不再移位，按格式打包）、下一拍的 6/7 位余数片
  // ---------------------------------------------------------------------------
  always_comb
    for (int k = 0; k < 4; k++) begin
      quo_dig_out[k][0] = dig0[k];
      quo_dig_out[k][1] = dig1[k];
      quo_dig_out[k][2] = dig2[k];
    end

  logic [3:0][59:0] o_s64, o_s32, o_s16, o_c64, o_c32, o_c16;
  logic [59:0] o_w;
  always_comb begin
    for (int k = 0; k < 4; k++) begin
      o_s64[k] = (k < 1) ? lane_of(sel2_s[k], F64, k) : '0;
      o_s32[k] = (k < 2) ? lane_of(sel2_s[k], F32, k) : '0;
      o_s16[k] = lane_of(sel2_s[k], F16, k);
      o_c64[k] = (k < 1) ? lane_of(sel2_c[k], F64, k) : '0;
      o_c32[k] = (k < 2) ? lane_of(sel2_c[k], F32, k) : '0;
      if (k < 2) o_c16[k] = lane_of(sel2_c[k], F16, k);
      else begin   // f16 通道 3/2：q ∈ {+2,+1,0} 候选最低位强制 0（同级间打包的怪癖）
        o_c16[k] = '0;
        for (int q = 0; q < 5; q++) begin
          o_w = lane_of(spec2_c[q], F16, k);
          if (q >= Q_Z) o_w[0] = 1'b0;
          o_c16[k] |= {60{dig2[k][q]}} & o_w;
        end
      end
    end
    rem_s_out = fmux72(fmt, pack72(F64, o_s64), pack72(F32, o_s32), pack72(F16, o_s16));
    rem_c_out = fmux72(fmt, pack72(F64, o_c64), pack72(F32, o_c32), pack72(F16, o_c16));
  end

  // 下一拍的余数片：s1 选中余数的 7/8 位窗 (s + c [+ 除数片])，按 s2 商位选，再丢最低位。
  //   f64 分支的除数片取自按格式打包后的 divisor_mul（golden 如此），f32/f16 取原始除数。
  logic [6:0] n_s7, n_c7, n_d7;
  logic [7:0] n_s8, n_c8, n_d8;
  logic [4:0][6:0] n_a7;
  logic [4:0][7:0] n_a8;
  always_comb begin
    for (int k = 0; k < 4; k++) begin
      case (k)
        0: begin
          n_s7 = 7'(fmux8(fmt, 8'(win7(lane_of(sel1_s[0], F64, 0), F64)), 8'(win7(lane_of(sel1_s[0], F32, 0), F32)), 8'(win7(lane_of(sel1_s[0], F16, 0), F16))));
          n_c7 = 7'(fmux8(fmt, 8'(win7(lane_of(sel1_c[0], F64, 0), F64)), 8'(win7(lane_of(sel1_c[0], F32, 0), F32)), 8'(win7(lane_of(sel1_c[0], F16, 0), F16))));
          n_s8 = fmux8(fmt, win8(lane_of(sel1_s[0], F64, 0), F64), win8(lane_of(sel1_s[0], F32, 0), F32), win8(lane_of(sel1_s[0], F16, 0), F16));
          n_c8 = fmux8(fmt, win8(lane_of(sel1_c[0], F64, 0), F64), win8(lane_of(sel1_c[0], F32, 0), F32), win8(lane_of(sel1_c[0], F16, 0), F16));
        end
        1: begin
          n_s7 = fmt[F32] ? win7(lane_of(sel1_s[1], F32, 1), F32) : win7(lane_of(sel1_s[1], F16, 1), F16);
          n_c7 = fmt[F32] ? win7(lane_of(sel1_c[1], F32, 1), F32) : win7(lane_of(sel1_c[1], F16, 1), F16);
          n_s8 = fmt[F32] ? win8(lane_of(sel1_s[1], F32, 1), F32) : win8(lane_of(sel1_s[1], F16, 1), F16);
          n_c8 = fmt[F32] ? win8(lane_of(sel1_c[1], F32, 1), F32) : win8(lane_of(sel1_c[1], F16, 1), F16);
        end
        default: begin
          n_s7 = win7(lane_of(sel1_s[k], F16, k), F16);
          n_c7 = win7(lane_of(sel1_c[k], F16, k), F16);
          n_s8 = win8(lane_of(sel1_s[k], F16, k), F16);
          n_c8 = win8(lane_of(sel1_c[k], F16, k), F16);
        end
      endcase
      for (int q = 0; q < 5; q++) begin
        case (k)
          0: begin
            n_d7 = 7'(fmux8(fmt, 8'(divisor_mul[q][69:63]), 8'(div7(divisor_in, q, F32, 0)), 8'(div7(divisor_in, q, F16, 0))));
            n_d8 = fmux8(fmt, divisor_mul[q][67:60], div8(divisor_in, q, F32, 0), div8(divisor_in, q, F16, 0));
          end
          1: begin
            n_d7 = fmt[F32] ? div7(divisor_in, q, F32, 1) : div7(divisor_in, q, F16, 1);
            n_d8 = fmt[F32] ? div8(divisor_in, q, F32, 1) : div8(divisor_in, q, F16, 1);
          end
          default: begin
            n_d7 = div7(divisor_in, q, F16, k);
            n_d8 = div8(divisor_in, q, F16, k);
          end
        endcase
        if (q == Q_Z) begin
          n_a7[q] = 7'(n_s7 + n_c7);
          n_a8[q] = 8'(n_s8 + n_c8);
        end else if (k < 2) begin
          n_a7[q] = 7'(7'(n_s7 + n_c7) + n_d7);
          n_a8[q] = 8'(8'(n_s8 + n_c8) + n_d8);
        end else begin
          n_a7[q] = 7'(n_s7 + 7'(n_c7 + n_d7));
          n_a8[q] = 8'(n_s8 + 8'(n_c8 + n_d8));
        end
      end
      adder6_out[k] = '0;
      adder7_out[k] = '0;
      for (int q = 0; q < 5; q++) begin
        adder6_out[k] |= {6{dig2[k][q]}} & n_a7[q][6:1];
        adder7_out[k] |= {7{dig2[k][q]}} & n_a8[q][7:1];
      end
    end
  end
endmodule

module fpdiv_r64_block_vector (
  input  logic [2:0]  io_fp_format_onehot,
  input  logic [71:0] io_f_r_s_i,
  input  logic [71:0] io_f_r_c_i,
  input  logic [59:0] io_divisor_i,
  input  logic [5:0]  io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_0,
  input  logic [5:0]  io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_1,
  input  logic [5:0]  io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_2,
  input  logic [5:0]  io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_3,
  input  logic [6:0]  io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_0,
  input  logic [6:0]  io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_1,
  input  logic [6:0]  io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_2,
  input  logic [6:0]  io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_3,
  output logic [4:0]  io_nxt_quo_dig_o_0_0,
  output logic [4:0]  io_nxt_quo_dig_o_0_1,
  output logic [4:0]  io_nxt_quo_dig_o_0_2,
  output logic [4:0]  io_nxt_quo_dig_o_1_0,
  output logic [4:0]  io_nxt_quo_dig_o_1_1,
  output logic [4:0]  io_nxt_quo_dig_o_1_2,
  output logic [4:0]  io_nxt_quo_dig_o_2_0,
  output logic [4:0]  io_nxt_quo_dig_o_2_1,
  output logic [4:0]  io_nxt_quo_dig_o_2_2,
  output logic [4:0]  io_nxt_quo_dig_o_3_0,
  output logic [4:0]  io_nxt_quo_dig_o_3_1,
  output logic [4:0]  io_nxt_quo_dig_o_3_2,
  output logic [71:0] io_nxt_f_r_s_o_2,
  output logic [71:0] io_nxt_f_r_c_o_2,
  output logic [5:0]  io_adder_6b_res_for_nxt_cycle_s0_qds_o_0,
  output logic [5:0]  io_adder_6b_res_for_nxt_cycle_s0_qds_o_1,
  output logic [5:0]  io_adder_6b_res_for_nxt_cycle_s0_qds_o_2,
  output logic [5:0]  io_adder_6b_res_for_nxt_cycle_s0_qds_o_3,
  output logic [6:0]  io_adder_7b_res_for_nxt_cycle_s1_qds_o_0,
  output logic [6:0]  io_adder_7b_res_for_nxt_cycle_s1_qds_o_1,
  output logic [6:0]  io_adder_7b_res_for_nxt_cycle_s1_qds_o_2,
  output logic [6:0]  io_adder_7b_res_for_nxt_cycle_s1_qds_o_3
);
  logic [3:0][5:0] rem6;
  logic [3:0][6:0] rem7;
  logic [3:0][2:0][4:0] quo;
  logic [3:0][5:0] add6;
  logic [3:0][6:0] add7;

  assign rem6 = {io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_3, io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_2,
                 io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_1, io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_0};
  assign rem7 = {io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_3, io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_2,
                 io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_1, io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_0};

  xs_fpdiv_r64_block_vector_core u_core (
    .fmt         (io_fp_format_onehot),
    .rem_s_in    (io_f_r_s_i),
    .rem_c_in    (io_f_r_c_i),
    .divisor_in  (io_divisor_i),
    .rem6_for_s0 (rem6),
    .rem7_for_s1 (rem7),
    .quo_dig_out (quo),
    .rem_s_out   (io_nxt_f_r_s_o_2),
    .rem_c_out   (io_nxt_f_r_c_o_2),
    .adder6_out  (add6),
    .adder7_out  (add7)
  );

  assign io_nxt_quo_dig_o_0_0 = quo[0][0];
  assign io_nxt_quo_dig_o_0_1 = quo[0][1];
  assign io_nxt_quo_dig_o_0_2 = quo[0][2];
  assign io_nxt_quo_dig_o_1_0 = quo[1][0];
  assign io_nxt_quo_dig_o_1_1 = quo[1][1];
  assign io_nxt_quo_dig_o_1_2 = quo[1][2];
  assign io_nxt_quo_dig_o_2_0 = quo[2][0];
  assign io_nxt_quo_dig_o_2_1 = quo[2][1];
  assign io_nxt_quo_dig_o_2_2 = quo[2][2];
  assign io_nxt_quo_dig_o_3_0 = quo[3][0];
  assign io_nxt_quo_dig_o_3_1 = quo[3][1];
  assign io_nxt_quo_dig_o_3_2 = quo[3][2];
  assign io_adder_6b_res_for_nxt_cycle_s0_qds_o_0 = add6[0];
  assign io_adder_6b_res_for_nxt_cycle_s0_qds_o_1 = add6[1];
  assign io_adder_6b_res_for_nxt_cycle_s0_qds_o_2 = add6[2];
  assign io_adder_6b_res_for_nxt_cycle_s0_qds_o_3 = add6[3];
  assign io_adder_7b_res_for_nxt_cycle_s1_qds_o_0 = add7[0];
  assign io_adder_7b_res_for_nxt_cycle_s1_qds_o_1 = add7[1];
  assign io_adder_7b_res_for_nxt_cycle_s1_qds_o_2 = add7[2];
  assign io_adder_7b_res_for_nxt_cycle_s1_qds_o_3 = add7[3];
endmodule
