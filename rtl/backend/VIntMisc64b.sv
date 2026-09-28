// =============================================================================
// VIntMisc64b.sv —— 向量整数"杂项"运算单元（64 位一片，纯组合）
//
// 位置：yunsuan 向量整数 ALU（VIntFixpAlu64b）里与加法器并列的那一半，香山后端
//   VIAlu 的每个 64 位半片各一个。输入是一条向量 uop 的 64 位源操作数片（vs1/vs2）、
//   v0 掩码片、元素宽度（srcType/vdType 低 2 位编 SEW：0/1/2/3 = 8/16/32/64）；
//   输出本片结果 vd，以及交给定点单元的移位中间量（窄化移位 / 舍入位）。
// 负责的指令（按 opcode 分类，结果在 §9 按类 Mux1H 选出）：
//   §2 扩展      vzext/vsext.vf2/vf4/vf8   —— 取 vs2 的 1/2、1/4、1/8 按元素零/符号扩展
//   §3 位逻辑    vand/vnand/vandn/vxor/vor/vnor/vorn/vxnor
//   §4 移位      vsll/vsrl/vsra/vssrl/vssra 及窄化 vnsrl/vnsra（左移 = 反转 → 右移 → 反转）
//   §5 合并/搬移 vmerge / vmv.v / vmv.s.x
//   §6 Zvbb 反转 vbrev/vbrev8/vrev8
//   §7 Zvbb 计数 vclz/vctz/vcpop（8 个 CLZ 子模块，按元素宽度复用）
//   §8 Zvbb 旋转 vrol/vror，宽化左移 vwsll
// 怪癖（照 golden 保留）：
//   · vcpop 的 16 位部分和 pop_16 只有 5 位宽（两个 8 位计数相加后截断）—— 照写；
//     它只在 vcpop 时被选到输出，此时每个加数 <= 8，截断不改变结果（UT 变异 V1 实测不可观测）；
//   · 计数用的 CLZ 输入在短元素时低位补一个"哨兵 1"（如 {byte, 8'h80}），
//     让 16/32/64 位的 CLZ 在全零字节上正好数到 8；
//   · 一切 Mux1H 都是"按位或"语义：没有选中任何一路时结果为 0。
// Chisel 源：yunsuan/src/main/scala/yunsuan/vector/VectorALU/VIntMisc64b.scala（yunsuan@9559211）。
// golden 对照：G1-canonical/golden-rtl/VIntMisc64b.sv；子模块 CLZ_6/7/9/11 用 rtl/common 的重写件。
// =============================================================================
package vintmisc64b_pkg;
  // VAluOpcode（yunsuan VAluDecode.scala），本单元用到的那些
  localparam logic [5:0] OP_VEXT   = 6'd2;
  localparam logic [5:0] OP_VAND   = 6'd7;
  localparam logic [5:0] OP_VNAND  = 6'd8;
  localparam logic [5:0] OP_VANDN  = 6'd9;
  localparam logic [5:0] OP_VXOR   = 6'd10;
  localparam logic [5:0] OP_VOR    = 6'd11;
  localparam logic [5:0] OP_VNOR   = 6'd12;
  localparam logic [5:0] OP_VORN   = 6'd13;
  localparam logic [5:0] OP_VXNOR  = 6'd14;
  localparam logic [5:0] OP_VSLL   = 6'd15;
  localparam logic [5:0] OP_VSRL   = 6'd16;
  localparam logic [5:0] OP_VSRA   = 6'd17;
  localparam logic [5:0] OP_VMERGE = 6'd25;
  localparam logic [5:0] OP_VMV    = 6'd26;
  localparam logic [5:0] OP_VSSRL  = 6'd31;
  localparam logic [5:0] OP_VSSRA  = 6'd32;
  localparam logic [5:0] OP_VCPOP  = 6'd39;
  localparam logic [5:0] OP_VMVSX  = 6'd46;
  localparam logic [5:0] OP_VBREV  = 6'd48;
  localparam logic [5:0] OP_VBREV8 = 6'd49;
  localparam logic [5:0] OP_VREV8  = 6'd50;
  localparam logic [5:0] OP_VCLZ   = 6'd51;
  localparam logic [5:0] OP_VCTZ   = 6'd52;
  localparam logic [5:0] OP_VROL   = 6'd53;
  localparam logic [5:0] OP_VROR   = 6'd54;
  localparam logic [5:0] OP_VWSLL  = 6'd55;

  // 一个元素右移的结果与两位舍入信息（给定点单元的 vssrl/vnclip 用）
  typedef struct packed {
    logic [63:0] data;      // 低 len 位有效，其余为 0
    logic        rnd_high;  // 被移出的最高一位 v[d-1]（d = 移位量；d=0 时为 0）
    logic        rnd_tail;  // 被移出的其余位 v[d-2:0] 全为 0（d<=1 时恒真）
  } shr_t;

  // 元素右移：data 的低 len 位是一个元素，amt 是移位量（调用方已截到 log2(len) 位）。
  // arith=1 时高位补元素符号位。对应 Chisel dynamicShift 按移位量各位逐级右移再折叠
  // 舍入位的做法 —— 逐级折叠的最终结果就是这里的闭式：
  //   rnd_high = data[d-1]，rnd_tail = (data[d-2:0] == 0)。
  function automatic shr_t shr_elem(input logic [63:0] data, input logic [5:0] amt,
                                    input int len, input logic arith);
    logic sign;
    shr_elem = '0;
    sign = arith & data[len-1];
    for (int b = 0; b < 64; b++)
      if (b < len)
        shr_elem.data[b] = (b + int'(amt) < len) ? data[b + int'(amt)] : sign;
    shr_elem.rnd_high = (amt != 6'd0) ? data[int'(amt) - 1] : 1'b0;
    shr_elem.rnd_tail = 1'b1;
    for (int b = 0; b < 64; b++)
      if (b + 1 < int'(amt) && data[b]) shr_elem.rnd_tail = 1'b0;
  endfunction

  // 整体 64 位按位反转
  function automatic logic [63:0] rev64(input logic [63:0] x);
    for (int b = 0; b < 64; b++) rev64[b] = x[63 - b];
  endfunction

  // 每 w 位一个元素，元素内按位反转（w = 8/16/32/64）
  function automatic logic [63:0] bitrev_each(input logic [63:0] x, input int w);
    for (int b = 0; b < 64; b++) bitrev_each[b] = x[(b / w) * w + (w - 1 - b % w)];
  endfunction

  // 每 w 位一个元素，元素内按字节反转（w = 8/16/32/64）
  function automatic logic [63:0] byterev_each(input logic [63:0] x, input int w);
    int nb, e, k;
    nb = w / 8;
    for (int byt = 0; byt < 8; byt++) begin
      e = byt / nb;
      k = byt % nb;
      byterev_each[8*byt +: 8] = x[8*(e*nb + nb - 1 - k) +: 8];
    end
  endfunction

  // 8 位按位反转
  function automatic logic [7:0] rev8b(input logic [7:0] x);
    for (int b = 0; b < 8; b++) rev8b[b] = x[7 - b];
  endfunction

  function automatic logic [3:0] popcount8(input logic [7:0] x);
    popcount8 = '0;
    for (int b = 0; b < 8; b++) popcount8 = popcount8 + 4'(x[b]);
  endfunction
endpackage

module xs_VIntMisc64b_core
  import vintmisc64b_pkg::*;
(
  input  logic [5:0]  op,
  input  logic        vm,          // 1 = 不带掩码（vmv / 无 v0 的 vmerge 形式）
  input  logic [5:0]  uop_idx,
  input  logic [3:0]  vs2_type,    // srcType(0)：[1:0] = SEW，[3:2] = 1 表示有符号
  input  logic [3:0]  vd_type,     // [1:0] = 目的 SEW
  input  logic [63:0] vs1,
  input  logic [63:0] vs2,
  input  logic [7:0]  vmask,       // 本片对应的 v0 掩码位（按元素）
  input  logic        narrow,      // 窄化移位（vnsrl/vnsra/vnclip）
  output logic [63:0] vd,
  output logic [31:0] narrow_vd,
  output logic [63:0] fixp_shift_out,
  output logic [7:0]  fixp_rnd_high,
  output logic [7:0]  fixp_rnd_tail
);

  // ===========================================================================
  // §1 公共译码：目的 SEW 独热、有无符号、扩展倍数、uop 在展开序列里的下标
  // ===========================================================================
  logic vd_is8, vd_is16, vd_is32, vd_is64;
  assign vd_is8  = vd_type[1:0] == 2'd0;
  assign vd_is16 = vd_type[1:0] == 2'd1;
  assign vd_is32 = vd_type[1:0] == 2'd2;
  assign vd_is64 = vd_type[1:0] == 2'd3;

  logic       src_signed;
  logic [1:0] sew_ratio_log;     // log2(目的 SEW / 源 SEW)：扩展是 vf2/vf4/vf8
  logic [2:0] expd_idx;          // 扩展/窄化时本 uop 取源的第几段
  assign src_signed    = vs2_type[3:2] == 2'd1;
  assign sew_ratio_log = vd_type[1:0] - vs2_type[1:0];
  assign expd_idx      = uop_idx[2:0];

  logic op_is_shift, op_is_left_shift, op_is_signed_shift, op_is_bit_logical, op_is_merge_move,
        op_is_rev, op_is_count, op_is_vro, op_is_clz;
  assign op_is_signed_shift = op == OP_VSRA || op == OP_VSSRA;
  assign op_is_shift        = op == OP_VSLL || op == OP_VSRL || op == OP_VSSRL || op_is_signed_shift;
  assign op_is_left_shift   = op == OP_VSLL;
  assign op_is_bit_logical  = op inside {OP_VAND, OP_VNAND, OP_VANDN, OP_VXOR,
                                         OP_VOR, OP_VNOR, OP_VORN, OP_VXNOR};
  assign op_is_merge_move   = op == OP_VMERGE || op == OP_VMV || op == OP_VMVSX;
  assign op_is_rev          = op == OP_VBREV || op == OP_VBREV8 || op == OP_VREV8;
  assign op_is_count        = op == OP_VCLZ || op == OP_VCTZ || op == OP_VCPOP;
  assign op_is_vro          = op == OP_VROL || op == OP_VROR;
  assign op_is_clz          = op == OP_VCLZ;

  // ===========================================================================
  // §2 扩展 vzext/vsext：vf2 取 vs2 的第 expd_idx[0] 个 32 位半、vf4 取第 expd_idx[1:0]
  //    个 16 位、其余（vf8）取第 expd_idx 个字节；按源元素宽度逐个扩到目的宽度。
  // ===========================================================================
  logic [63:0] ext_result;
  always_comb begin
    logic [31:0] half;
    logic [15:0] quarter;
    logic [7:0]  eighth;
    half    = vs2[32*expd_idx[0] +: 32];
    quarter = vs2[16*expd_idx[1:0] +: 16];
    eighth  = vs2[8*expd_idx +: 8];
    if (sew_ratio_log == 2'd1) begin          // vf2：源 SEW = 目的 SEW / 2
      if (vd_is16)
        for (int k = 0; k < 4; k++)
          ext_result[16*k +: 16] = {{8{src_signed & half[8*k+7]}}, half[8*k +: 8]};
      else if (vd_is32)
        for (int k = 0; k < 2; k++)
          ext_result[32*k +: 32] = {{16{src_signed & half[16*k+15]}}, half[16*k +: 16]};
      else
        ext_result = {{32{src_signed & half[31]}}, half};
    end
    else if (sew_ratio_log == 2'd2) begin     // vf4
      if (vd_is32)
        for (int k = 0; k < 2; k++)
          ext_result[32*k +: 32] = {{24{src_signed & quarter[8*k+7]}}, quarter[8*k +: 8]};
      else
        ext_result = {{48{src_signed & quarter[15]}}, quarter};
    end
    else                                      // vf8
      ext_result = {{56{src_signed & eighth[7]}}, eighth};
  end

  // ===========================================================================
  // §3 位逻辑
  // ===========================================================================
  logic [63:0] bit_logical;
  always_comb
    case (op)
      OP_VAND:  bit_logical = vs2 & vs1;
      OP_VNAND: bit_logical = ~(vs2 & vs1);
      OP_VANDN: bit_logical = vs2 & ~vs1;
      OP_VXOR:  bit_logical = vs2 ^ vs1;
      OP_VOR:   bit_logical = vs2 | vs1;
      OP_VNOR:  bit_logical = ~(vs2 | vs1);
      OP_VORN:  bit_logical = vs2 | ~vs1;
      OP_VXNOR: bit_logical = ~(vs2 ^ vs1);
      default:  bit_logical = 64'h0;
    endcase

  // ===========================================================================
  // §4 移位。全部用右移实现：左移时把 vs2 整体按位反转（元素顺序随之倒过来），
  //    移位量 vs1 也按元素倒序，右移后再整体反转回来。
  //    窄化（narrow）时源是 2*SEW，vs1 的第 expd_idx[0] 组 4 个字节各自零扩展成
  //    16 位移位量。移位宽度按 "窄化看目的 SEW 的两倍" 选 32/16/8/64 四档之一。
  //    fixp_* 把未反转的移位结果和舍入位交给定点单元（vssrl/vnclip 舍入用）。
  // ===========================================================================
  logic [63:0] vs2_adjust, vs1_by_elem, vs1_adjust;
  assign vs2_adjust = op_is_left_shift ? rev64(vs2) : vs2;
  always_comb begin
    if (op_is_left_shift && vd_is32)      vs1_by_elem = {vs1[31:0], vs1[63:32]};
    else if (op_is_left_shift && vd_is16) vs1_by_elem = {vs1[15:0], vs1[31:16], vs1[47:32], vs1[63:48]};
    else if (op_is_left_shift && vd_is8)
      for (int k = 0; k < 8; k++) vs1_by_elem[8*k +: 8] = vs1[8*(7-k) +: 8];
    else                                  vs1_by_elem = vs1;
  end
  always_comb begin
    if (narrow)
      for (int k = 0; k < 4; k++)
        vs1_adjust[16*k +: 16] = {8'h0, vs1_by_elem[8*(4*expd_idx[0] + k) +: 8]};
    else
      vs1_adjust = vs1_by_elem;
  end

  shr_t sh8 [8];
  shr_t sh16 [4];
  shr_t sh32 [2];
  shr_t sh64;
  always_comb begin
    for (int k = 0; k < 8; k++)
      sh8[k]  = shr_elem({56'h0, vs2_adjust[8*k +: 8]},   {3'h0, vs1_adjust[8*k +: 3]},  8,  op_is_signed_shift);
    for (int k = 0; k < 4; k++)
      sh16[k] = shr_elem({48'h0, vs2_adjust[16*k +: 16]}, {2'h0, vs1_adjust[16*k +: 4]}, 16, op_is_signed_shift);
    for (int k = 0; k < 2; k++)
      sh32[k] = shr_elem({32'h0, vs2_adjust[32*k +: 32]}, {1'h0, vs1_adjust[32*k +: 5]}, 32, op_is_signed_shift);
    sh64 = shr_elem(vs2_adjust, vs1_adjust[5:0], 64, op_is_signed_shift);
  end

  logic [63:0] shift_out;
  always_comb begin
    if (narrow ? vd_is16 : vd_is32) begin
      for (int k = 0; k < 2; k++) begin
        shift_out[32*k +: 32]    = sh32[k].data[31:0];
        fixp_rnd_high[4*k +: 4]  = {4{sh32[k].rnd_high}};
        fixp_rnd_tail[4*k +: 4]  = {4{sh32[k].rnd_tail}};
      end
    end
    else if (narrow ? vd_is8 : vd_is16) begin
      for (int k = 0; k < 4; k++) begin
        shift_out[16*k +: 16]    = sh16[k].data[15:0];
        fixp_rnd_high[2*k +: 2]  = {2{sh16[k].rnd_high}};
        fixp_rnd_tail[2*k +: 2]  = {2{sh16[k].rnd_tail}};
      end
    end
    else if (!narrow && vd_is8) begin
      for (int k = 0; k < 8; k++) begin
        shift_out[8*k +: 8]      = sh8[k].data[7:0];
        fixp_rnd_high[k]         = sh8[k].rnd_high;
        fixp_rnd_tail[k]         = sh8[k].rnd_tail;
      end
    end
    else begin
      shift_out     = sh64.data;
      fixp_rnd_high = {8{sh64.rnd_high}};
      fixp_rnd_tail = {8{sh64.rnd_tail}};
    end
  end
  assign fixp_shift_out = shift_out;

  logic [63:0] shift_result;
  assign shift_result = op_is_left_shift ? rev64(shift_out) : shift_out;

  // 窄化结果：每个 2*SEW 元素的低 SEW 位拼起来（Mux1H，64 位目的时为 0）
  assign narrow_vd = ({32{vd_is32}} & shift_out[31:0])
                   | ({32{vd_is16}} & {shift_out[47:32], shift_out[15:0]})
                   | ({32{vd_is8}}  & {shift_out[55:48], shift_out[39:32], shift_out[23:16], shift_out[7:0]});

  // ===========================================================================
  // §5 合并/搬移：v0 掩码按元素宽度铺到字节（SEW=32 时 000000ab -> aaaabbbb），
  //    逐字节选 vs1 / vs2；不带掩码或 vmv.s.x 时直接取 vs1。
  // ===========================================================================
  logic [7:0]  vmask_bytes;
  logic [63:0] merge_result, merge_move;
  always_comb begin
    for (int i = 0; i < 8; i++)
      vmask_bytes[i] = (vd_is8  & vmask[i])
                     | (vd_is16 & vmask[i/2])
                     | (vd_is32 & vmask[i/4])
                     | (vd_is64 & vmask[0]);
    for (int i = 0; i < 8; i++)
      merge_result[8*i +: 8] = vmask_bytes[i] ? vs1[8*i +: 8] : vs2[8*i +: 8];
  end
  assign merge_move = (vm || op == OP_VMVSX) ? vs1 : merge_result;

  // ===========================================================================
  // §6 Zvbb 反转：vbrev 元素内按位反转，vbrev8 字节内按位反转，vrev8 元素内按字节反转
  // ===========================================================================
  logic [63:0] rev_result;
  assign rev_result = ({64{op == OP_VBREV  && vd_is8 }} & bitrev_each(vs2, 8))
                    | ({64{op == OP_VBREV  && vd_is16}} & bitrev_each(vs2, 16))
                    | ({64{op == OP_VBREV  && vd_is32}} & bitrev_each(vs2, 32))
                    | ({64{op == OP_VBREV  && vd_is64}} & bitrev_each(vs2, 64))
                    | ({64{op == OP_VBREV8}}            & bitrev_each(vs2, 8))
                    | ({64{op == OP_VREV8  && vd_is8 }} & vs2)
                    | ({64{op == OP_VREV8  && vd_is16}} & byterev_each(vs2, 16))
                    | ({64{op == OP_VREV8  && vd_is32}} & byterev_each(vs2, 32))
                    | ({64{op == OP_VREV8  && vd_is64}} & byterev_each(vs2, 64));

  // ===========================================================================
  // §7 Zvbb 计数。vctz = 先按位反转再数前导零。8 个 CLZ 按"元素落在哪一段"复用：
  //    字节 0..3 各一个 8 位 CLZ；两个 16 位 CLZ 管字节 4/5（SEW=8）或半字 0/1（SEW=16）；
  //    32 位 CLZ 管字节 6 / 半字 2 / 字 0；64 位 CLZ 管字节 7 / 半字 3 / 字 1 / 双字。
  //    短元素放进宽 CLZ 时左对齐，并在紧挨着的下一位放一个哨兵 1，全零时正好数到元素宽。
  //    vcpop 走逐字节 popcount 再逐级相加（pop_16 只有 5 位，照 golden 宽度；vcpop 下不会溢出）。
  // ===========================================================================
  // 取 x（clz）或 x 的按位反转（ctz）
  logic [7:0]  cz_byte [8];
  logic [15:0] cz_half [4];
  logic [31:0] cz_word [2];
  logic [63:0] cz_dword;
  logic [63:0] vs2_rev_in16, vs2_rev_in32;    // 每 16 / 32 位元素内按位反转
  assign vs2_rev_in16 = bitrev_each(vs2, 16);
  assign vs2_rev_in32 = bitrev_each(vs2, 32);
  always_comb begin
    for (int k = 0; k < 8; k++) cz_byte[k] = op_is_clz ? vs2[8*k +: 8] : rev8b(vs2[8*k +: 8]);
    for (int k = 0; k < 4; k++) cz_half[k] = op_is_clz ? vs2[16*k +: 16] : vs2_rev_in16[16*k +: 16];
    for (int k = 0; k < 2; k++) cz_word[k] = op_is_clz ? vs2[32*k +: 32] : vs2_rev_in32[32*k +: 32];
    cz_dword = op_is_clz ? vs2 : rev64(vs2);
  end

  logic [15:0] clz16_in [2];
  logic [31:0] clz32_in;
  logic [63:0] clz64_in;
  always_comb begin
    for (int i = 0; i < 2; i++)
      clz16_in[i] = ({16{vd_is8}}  & {cz_byte[4+i], 8'h80})
                  | ({16{vd_is16}} & cz_half[i]);
    clz32_in = ({32{vd_is8}}  & {cz_byte[6], 24'h80_0000})
             | ({32{vd_is16}} & {cz_half[2], 16'h8000})
             | ({32{vd_is32}} & cz_word[0]);
    clz64_in = ({64{vd_is8}}  & {cz_byte[7], 56'h80_0000_0000_0000})
             | ({64{vd_is16}} & {cz_half[3], 48'h8000_0000_0000})
             | ({64{vd_is32}} & {cz_word[1], 32'h8000_0000})
             | ({64{vd_is64}} & cz_dword);
  end

  logic [3:0] clz8_out [4];
  logic [4:0] clz16_out [2];
  logic [5:0] clz32_out;
  logic [6:0] clz64_out;
  CLZ_11 cnt8_0_clz  (.io_in(cz_byte[0]), .io_out(clz8_out[0]));
  CLZ_11 cnt8_1_clz  (.io_in(cz_byte[1]), .io_out(clz8_out[1]));
  CLZ_11 cnt8_2_clz  (.io_in(cz_byte[2]), .io_out(clz8_out[2]));
  CLZ_11 cnt8_3_clz  (.io_in(cz_byte[3]), .io_out(clz8_out[3]));
  CLZ_7  cnt16_0_tmp_clz (.io_in(clz16_in[0]), .io_out(clz16_out[0]));
  CLZ_7  cnt16_1_tmp_clz (.io_in(clz16_in[1]), .io_out(clz16_out[1]));
  CLZ_9  cnt32_tmp_clz   (.io_in(clz32_in),    .io_out(clz32_out));
  CLZ_6  cnt64_tmp_clz   (.io_in(clz64_in),    .io_out(clz64_out));

  logic        is_cpop;
  logic [7:0]  cnt8 [8];
  logic [4:0]  pop16 [4];      // 5 位：两个 8 位计数之和截断到 5 位（golden 同宽；vcpop 时 <= 16 不溢出）
  logic [5:0]  pop32 [2];
  logic [6:0]  pop64;
  logic [63:0] count_result;
  assign is_cpop = op == OP_VCPOP;
  always_comb begin
    for (int k = 0; k < 4; k++)
      cnt8[k] = is_cpop ? 8'(popcount8(vs2[8*k +: 8])) : 8'(clz8_out[k]);
    cnt8[4] = is_cpop ? 8'(popcount8(vs2[39:32])) : 8'(clz16_out[0]);
    cnt8[5] = is_cpop ? 8'(popcount8(vs2[47:40])) : 8'(clz16_out[1]);
    cnt8[6] = is_cpop ? 8'(popcount8(vs2[55:48])) : 8'(clz32_out);
    cnt8[7] = is_cpop ? 8'(popcount8(vs2[63:56])) : 8'(clz64_out);
    for (int k = 0; k < 4; k++)
      pop16[k] = 5'(cnt8[2*k] + cnt8[2*k+1]);
    for (int k = 0; k < 2; k++)
      pop32[k] = 6'(pop16[2*k]) + 6'(pop16[2*k+1]);
    pop64 = 7'(pop32[0]) + 7'(pop32[1]);
    count_result =
        ({64{op_is_count && vd_is8}}  & {cnt8[7], cnt8[6], cnt8[5], cnt8[4],
                                         cnt8[3], cnt8[2], cnt8[1], cnt8[0]})
      | ({64{op_is_count && vd_is16}} & {16'(is_cpop ? 7'(pop16[3]) : clz64_out),
                                         16'(is_cpop ? 6'(pop16[2]) : clz32_out),
                                         16'(is_cpop ? pop16[1] : clz16_out[1]),
                                         16'(is_cpop ? pop16[0] : clz16_out[0])})
      | ({64{op_is_count && vd_is32}} & {32'(is_cpop ? 7'(pop32[1]) : clz64_out),
                                         32'(is_cpop ? pop32[0] : clz32_out)})
      | ({64{op_is_count && vd_is64}} & 64'(is_cpop ? pop64 : clz64_out));
  end

  // ===========================================================================
  // §8 旋转 vrol/vror（按元素，移位量取 vs1 元素低 log2(SEW) 位），
  //    宽化左移 vwsll（取 vs1/vs2 的第 uop_idx[0] 个 32 位半，元素零扩展到 2*SEW 后左移）。
  // ===========================================================================
  function automatic logic [63:0] rotl_each(input logic [63:0] x, input logic [63:0] amt_src,
                                            input int w, input logic right);
    int a, e;
    for (int b = 0; b < 64; b++) begin
      e = b / w;
      a = int'(amt_src[e*w +: 6]) % w;           // 元素低 log2(w) 位（w | 64，取模即截位）
      if (right) rotl_each[b] = x[e*w + (b % w + a) % w];
      else       rotl_each[b] = x[e*w + (b % w - a + w) % w];
    end
  endfunction

  logic [63:0] vro_result;
  always_comb begin
    logic right;
    right = op == OP_VROR;
    vro_result = ({64{vd_is8 }} & ({64{op_is_vro}} & rotl_each(vs2, vs1, 8,  right)))
               | ({64{vd_is16}} & ({64{op_is_vro}} & rotl_each(vs2, vs1, 16, right)))
               | ({64{vd_is32}} & ({64{op_is_vro}} & rotl_each(vs2, vs1, 32, right)))
               | ({64{vd_is64}} & ({64{op_is_vro}} & rotl_each(vs2, vs1, 64, right)));
  end

  logic [63:0] wsll_result;
  always_comb begin
    logic [31:0] src1, src2;
    logic [63:0] w8, w16, w32;
    src1 = uop_idx[0] ? vs1[63:32] : vs1[31:0];
    src2 = uop_idx[0] ? vs2[63:32] : vs2[31:0];
    for (int k = 0; k < 4; k++) w8[16*k +: 16] = {8'h0, src2[8*k +: 8]} << src1[8*k +: 4];
    for (int k = 0; k < 2; k++) w16[32*k +: 32] = {16'h0, src2[16*k +: 16]} << src1[16*k +: 5];
    w32 = {32'h0, src2} << src1[5:0];
    wsll_result = ({64{op == OP_VWSLL && vd_is16}} & w8)
                | ({64{op == OP_VWSLL && vd_is32}} & w16)
                | ({64{op == OP_VWSLL && vd_is64}} & w32);
  end

  // ===========================================================================
  // §9 输出：按指令类 Mux1H（类互斥；未命中任何一类时为 0）
  // ===========================================================================
  assign vd = ({64{op_is_shift}}        & shift_result)
            | ({64{op == OP_VEXT}}      & ext_result)
            | ({64{op_is_bit_logical}}  & bit_logical)
            | ({64{op_is_merge_move}}   & merge_move)
            | ({64{op_is_rev}}          & rev_result)
            | ({64{op_is_count}}        & count_result)
            | ({64{op_is_vro}}          & vro_result)
            | ({64{op == OP_VWSLL}}     & wsll_result);

endmodule

module VIntMisc64b (
  input  [5:0]  io_opcode_op,
  input         io_info_vm,
  input  [5:0]  io_info_uopIdx,
  input  [3:0]  io_srcType_0,
  input  [3:0]  io_vdType,
  input  [63:0] io_vs1,
  input  [63:0] io_vs2,
  input  [7:0]  io_vmask,
  input         io_narrow,
  output [63:0] io_vd,
  output [31:0] io_narrowVd,
  output [63:0] io_toFixP_shiftOut,
  output [7:0]  io_toFixP_rnd_high,
  output [7:0]  io_toFixP_rnd_tail
);
  xs_VIntMisc64b_core u_core (
    .op             (io_opcode_op),
    .vm             (io_info_vm),
    .uop_idx        (io_info_uopIdx),
    .vs2_type       (io_srcType_0),
    .vd_type        (io_vdType),
    .vs1            (io_vs1),
    .vs2            (io_vs2),
    .vmask          (io_vmask),
    .narrow         (io_narrow),
    .vd             (io_vd),
    .narrow_vd      (io_narrowVd),
    .fixp_shift_out (io_toFixP_shiftOut),
    .fixp_rnd_high  (io_toFixP_rnd_high),
    .fixp_rnd_tail  (io_toFixP_rnd_tail)
  );
endmodule
