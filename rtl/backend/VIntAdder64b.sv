// ============================================================================
// VIntAdder64b.sv —— 向量整数 64 位加法/比较/min-max 数据通路
//
// 在哪一层：VIntFixpAlu64b（向量整数定点 ALU）内部，按元素位宽（8/16/32/64）
//   把 64 位操作数切成 8 个 byte lane 做可分段加法，同时产出比较与 min/max 结果。
// IO：io_opcode_op 是 VIAlu 的 6 位操作码（vadd/vsub/vadc/vmadc/vsbc/vmsbc/
//   vmseq/vmsne/vmslt/vmsle/vmsgt/vmin/vmax）；io_srcType_1/io_vdType 给 vs1/vd
//   的元素类型（[1:0]=元素位宽，[3:2]=符号性）；io_info_vm/ma 与 io_vmask/io_oldVd
//   用于掩码尾部的结果合并；io_widen/io_widen_vs2 控制 32→64 的符号扩展加宽；
//   io_toFixP_* 是给定点通路的分接头（每 byte 的和/进位出/两源操作数的符号位）。
// 核心机制：每 byte 一个 9 位加和 {cout,sum} = vs1a + vs2a + cin；进位链在元素
//   边界处按 opcode 选择「看 vd 宽（vadd/vsub）还是看 vs1 宽（其余）」来决定
//   是注入掩码携带位还是接力上一 byte —— 边界判据奇偶不对称，照 golden 保留。
//   比较器复用同一加和链：lessThan = 符号 ? 两符号位异或 cout : ~cout。
// 纯组合逻辑：无时钟、无复位、无寄存器。
// ============================================================================

module xs_VIntAdder64b_core (
  input  logic [5:0]  opcode_op,     // VIAlu 操作码（golden 编码）
  input  logic        info_vm,       // 掩码关闭（vm=1 时不看 vmask）
  input  logic        info_ma,       // 掩码尾部 agnostic 策略
  input  logic [5:0]  info_uop_idx,  // 微操作序号；bit0 选 widen 源的高/低 32 位
  input  logic [3:0]  src_type1,     // vs1/vs2 元素类型：[1:0] 位宽档，[3:2]==1 有符号
  input  logic [3:0]  vd_type,       // vd 元素类型（vadd/vsub 的进位边界看它）
  input  logic [63:0] vs1,
  input  logic [63:0] vs2,
  input  logic [7:0]  vmask,         // 每 byte 的掩码位
  input  logic [7:0]  old_vd,        // 旧 vd（掩码关闭且 ma=0 时保留）
  input  logic        is_sub,        // 减法：vs1 取反、进位入取反
  input  logic        widen,         // vs1 32→64 加宽
  input  logic        widen_vs2,     // vs2 32→64 加宽
  output logic [63:0] vd,            // 加和 / min-max 结果
  output logic [7:0]  cmp_out,       // 每 byte 的比较/携带结果（经掩码合并）
  output logic [7:0]  fixp_cout,     // 给定点通路：每 byte 的进位出
  output logic [63:0] fixp_vd,       // 给定点通路：每 byte 的加和
  output logic [7:0]  fixp_vs2h,     // 给定点通路：vs2 每 byte 的符号位
  output logic [7:0]  fixp_vs1h      // 给定点通路：vs1 每 byte 的符号位
);
  // ---- 指令译码（opcode 数值为 golden/VAluOpcode 编码）----
  wire op_vadd  = opcode_op == 6'd0;
  wire op_vsub  = opcode_op == 6'd1;
  wire op_vadc  = opcode_op == 6'd3;
  wire op_vmadc = opcode_op == 6'd4;
  wire op_vsbc  = opcode_op == 6'd5;
  wire op_vmsbc = opcode_op == 6'd6;
  wire op_vmseq = opcode_op == 6'h12;
  wire op_vmsne = opcode_op == 6'h13;
  wire op_vmslt = opcode_op == 6'h14;
  wire op_vmsle = opcode_op == 6'h15;
  wire op_vmsgt = opcode_op == 6'h16;
  wire op_vmin  = opcode_op == 6'h17;
  wire op_vmax  = opcode_op == 6'h18;
  // 不带携带位的普通加减：进位分段边界看 vd 的元素位宽；
  // 带进位/借位指令与比较指令：边界看 vs1 的元素位宽。
  wire plain_add_sub = op_vadd | op_vsub;
  wire add_with_carry = op_vadc | op_vmadc | op_vsbc | op_vmsbc;

  // ---- 元素位宽档（one-hot 展开）与符号性 ----
  wire [1:0] eew     = src_type1[1:0];
  wire [1:0] eew_vd  = vd_type[1:0];
  wire eew8      = eew == 2'd0;
  wire eew16     = eew == 2'd1;
  wire eew32     = eew == 2'd2;
  wire eew64     = &eew;
  wire eew_vd8   = eew_vd == 2'd0;
  wire eew_vd64  = &eew_vd;
  wire is_signed = src_type1[3:2] == 2'd1;

  // ---- widen：把 uopIdx 选出的 32 位半边按元素做符号扩展，拼回 64 位 ----
  wire [31:0] vs2_half = info_uop_idx[0] ? vs2[63:32] : vs2[31:0];
  wire [31:0] vs1_half = info_uop_idx[0] ? vs1[63:32] : vs1[31:0];

  // 元素位宽 eew 下的 32→64 加宽；eew=3（64bit）时无宽可加，golden 给全 0。
  function automatic logic [63:0] widen_elements(input logic [31:0] half,
                                                 input logic [1:0]  elem,
                                                 input logic        sgn);
    logic [63:0] wide;
    wide = 64'h0;
    case (elem)
      2'd0: for (int j = 0; j < 4; j++)
              wide[16*j +: 16] = {{8{half[8*j+7] & sgn}}, half[8*j +: 8]};
      2'd1: for (int j = 0; j < 2; j++)
              wide[32*j +: 32] = {{16{half[16*j+15] & sgn}}, half[16*j +: 16]};
      2'd2: wide = {{32{half[31] & sgn}}, half};
      default: wide = 64'h0;
    endcase
    return wide;
  endfunction

  wire [63:0] vs2_adjust =
    widen_vs2 ? widen_elements(vs2_half, eew, is_signed) : vs2;
  wire [63:0] vs1_adjust =
    (widen ? widen_elements(vs1_half, eew, is_signed) : vs1) ^ {64{is_sub}};

  // ---- vmask 按元素位宽稀疏展开：16bit 元素取偶数位、32bit 取 4 的倍数位 ----
  wire [7:0] vmask_adjust =
      eew16 ? {1'b0, vmask[3], 1'b0, vmask[2], 1'b0, vmask[1], 1'b0, vmask[0]}
    : eew32 ? {3'b000, vmask[1], 3'b000, vmask[0]}
    : vmask;

  // ---- 8 个 byte lane 的可分段加和链 ----
  // 元素起点的 lane 注入「携带指令的掩码位（与 is_sub 异或）」；
  // 元素内部的 lane 接力上一 byte 的进位出。边界判据奇偶不对称（golden 原样）：
  //   奇数 lane：元素宽 8bit 时是起点；
  //   lane 4  ：仅 64bit 元素内部才接力；
  //   lane 2/6：32/64bit 元素内部接力。
  logic [7:0] carry_in;
  logic [7:0] byte_cout;
  logic [7:0] sum_byte [8];
  for (genvar l = 0; l < 8; l++) begin : g_lane
    wire lane_fresh = (add_with_carry & ~info_vm & vmask_adjust[l]) ^ is_sub;
    if (l == 0) begin : g_first
      assign carry_in[0] = lane_fresh;
    end else if (l % 2 == 1) begin : g_odd
      wire elem_start = plain_add_sub ? eew_vd8 : eew8;
      assign carry_in[l] = elem_start ? lane_fresh : byte_cout[l-1];
    end else if (l == 4) begin : g_lane4
      wire elem_inside = plain_add_sub ? eew_vd64 : eew64;
      assign carry_in[l] = elem_inside ? byte_cout[l-1] : lane_fresh;
    end else begin : g_lane26
      wire elem_inside = plain_add_sub ? (eew_vd >= 2'd2) : (eew >= 2'd2);
      assign carry_in[l] = elem_inside ? byte_cout[l-1] : lane_fresh;
    end
    wire [8:0] lane_sum =
      {1'b0, vs1_adjust[8*l +: 8]} + {1'b0, vs2_adjust[8*l +: 8]} + {8'b0, carry_in[l]};
    assign byte_cout[l] = lane_sum[8];
    assign sum_byte[l]  = lane_sum[7:0];
  end

  // ---- 比较器：复用加和链的进位出判大小（无符号 = ~cout）----
  logic [7:0] less_than;
  logic [7:0] equal;
  for (genvar l = 0; l < 8; l++) begin : g_cmp
    assign less_than[l] = is_signed ? vs2[8*l+7] ^ vs1_adjust[8*l+7] ^ byte_cout[l]
                                    : ~byte_cout[l];
    assign equal[l]     = vs2[8*l +: 8] == vs1[8*l +: 8];
  end

  // 相等标志按元素位宽聚合：元素的各 byte 全等才算等
  wire [7:0] cmp_eq =
      eew8  ? equal
    : eew16 ? {{2{&equal[7:6]}}, {2{&equal[5:4]}}, {2{&equal[3:2]}}, {2{&equal[1:0]}}}
    : eew32 ? {{4{&equal[7:4]}}, {4{&equal[3:0]}}}
    : {8{&equal}};

  wire [7:0] cmp_raw =
      add_with_carry
        ? (op_vmsbc ? ~byte_cout : byte_cout)
        : (op_vmseq ? cmp_eq : 8'h0)
        | (op_vmsne ? ~cmp_eq : 8'h0)
        | (op_vmslt ? less_than : 8'h0)
        | (op_vmsle ? (less_than | cmp_eq) : 8'h0)
        | (op_vmsgt ? ~(less_than | cmp_eq) : 8'h0);

  // 比较结果按元素位宽回填：只在元素末 byte 放结果，高位补 1
  wire [7:0] cmp_adjust =
      eew8  ? cmp_raw
    : eew16 ? {4'hF, cmp_raw[7], cmp_raw[5], cmp_raw[3], cmp_raw[1]}
    : eew32 ? {6'h3F, cmp_raw[7], cmp_raw[3]}
    : {7'h7F, cmp_raw[7]};

  for (genvar l = 0; l < 8; l++) begin : g_cmp_out
    assign cmp_out[l] =
      add_with_carry ? cmp_adjust[l]
                     : (info_vm | vmask[l]) ? cmp_adjust[l]
                                            : info_ma | old_vd[l];
  end

  // ---- vd：min/max 选源，否则取加和 ----
  // min/max 的选择位在元素末 byte 的比较结果上（eew16 看奇数 byte、eew32 看
  // 4k+3、eew64 看 byte7）；less==vmax 时取 vs1（vmax 取大者中的 vs1 条件）。
  for (genvar l = 0; l < 8; l++) begin : g_vd
    wire pick_vs1 =
        (eew8  & (less_than[l]     == op_vmax))
      | (eew16 & (less_than[l | 1] == op_vmax))
      | (eew32 & (less_than[l | 3] == op_vmax))
      | (eew64 & (less_than[7]     == op_vmax));
    assign vd[8*l +: 8] =
      (op_vmin | op_vmax) ? (pick_vs1 ? vs1[8*l +: 8] : vs2[8*l +: 8])
                          : sum_byte[l];
  end

  // ---- 给定点通路的分接头 ----
  for (genvar l = 0; l < 8; l++) begin : g_fixp
    assign fixp_cout[l]      = byte_cout[l];
    assign fixp_vd[8*l +: 8] = sum_byte[l];
    assign fixp_vs2h[l]      = vs2[8*l+7];
    assign fixp_vs1h[l]      = vs1[8*l+7];
  end
endmodule

// BEGIN GENERATED(wrapper) —— scripts/gen_arithvec_leaves5.py 生成，勿手改
module VIntAdder64b(
  input  [5:0] io_opcode_op,
  input  io_info_vm,
  input  io_info_ma,
  input  [5:0] io_info_uopIdx,
  input  [3:0] io_srcType_1,
  input  [3:0] io_vdType,
  input  [63:0] io_vs1,
  input  [63:0] io_vs2,
  input  [7:0] io_vmask,
  input  [7:0] io_oldVd,
  input  io_isSub,
  input  io_widen,
  input  io_widen_vs2,
  output [63:0] io_vd,
  output [7:0] io_cmpOut,
  output io_toFixP_cout_0,
  output io_toFixP_cout_1,
  output io_toFixP_cout_2,
  output io_toFixP_cout_3,
  output io_toFixP_cout_4,
  output io_toFixP_cout_5,
  output io_toFixP_cout_6,
  output io_toFixP_cout_7,
  output [7:0] io_toFixP_vd_0,
  output [7:0] io_toFixP_vd_1,
  output [7:0] io_toFixP_vd_2,
  output [7:0] io_toFixP_vd_3,
  output [7:0] io_toFixP_vd_4,
  output [7:0] io_toFixP_vd_5,
  output [7:0] io_toFixP_vd_6,
  output [7:0] io_toFixP_vd_7,
  output io_toFixP_vs2H_0,
  output io_toFixP_vs2H_1,
  output io_toFixP_vs2H_2,
  output io_toFixP_vs2H_3,
  output io_toFixP_vs2H_4,
  output io_toFixP_vs2H_5,
  output io_toFixP_vs2H_6,
  output io_toFixP_vs2H_7,
  output io_toFixP_vs1H_0,
  output io_toFixP_vs1H_1,
  output io_toFixP_vs1H_2,
  output io_toFixP_vs1H_3,
  output io_toFixP_vs1H_4,
  output io_toFixP_vs1H_5,
  output io_toFixP_vs1H_6,
  output io_toFixP_vs1H_7
);

  // ---- golden 扁平端口 <-> 核语义端口的拆装（生成）----
  logic [7:0] fixp_cout;
  logic [63:0] fixp_vd;
  logic [7:0] fixp_vs2h;
  logic [7:0] fixp_vs1h;

  assign {io_toFixP_cout_7, io_toFixP_cout_6, io_toFixP_cout_5, io_toFixP_cout_4, io_toFixP_cout_3, io_toFixP_cout_2, io_toFixP_cout_1, io_toFixP_cout_0} = fixp_cout;
  assign {io_toFixP_vd_7, io_toFixP_vd_6, io_toFixP_vd_5, io_toFixP_vd_4, io_toFixP_vd_3, io_toFixP_vd_2, io_toFixP_vd_1, io_toFixP_vd_0} = fixp_vd;
  assign {io_toFixP_vs2H_7, io_toFixP_vs2H_6, io_toFixP_vs2H_5, io_toFixP_vs2H_4, io_toFixP_vs2H_3, io_toFixP_vs2H_2, io_toFixP_vs2H_1, io_toFixP_vs2H_0} = fixp_vs2h;
  assign {io_toFixP_vs1H_7, io_toFixP_vs1H_6, io_toFixP_vs1H_5, io_toFixP_vs1H_4, io_toFixP_vs1H_3, io_toFixP_vs1H_2, io_toFixP_vs1H_1, io_toFixP_vs1H_0} = fixp_vs1h;

  xs_VIntAdder64b_core u_core (
    .opcode_op (io_opcode_op),
    .info_vm (io_info_vm),
    .info_ma (io_info_ma),
    .info_uop_idx (io_info_uopIdx),
    .src_type1 (io_srcType_1),
    .vd_type (io_vdType),
    .vs1 (io_vs1),
    .vs2 (io_vs2),
    .vmask (io_vmask),
    .old_vd (io_oldVd),
    .is_sub (io_isSub),
    .widen (io_widen),
    .widen_vs2 (io_widen_vs2),
    .vd (io_vd),
    .cmp_out (io_cmpOut),
    .fixp_cout (fixp_cout),
    .fixp_vd (fixp_vd),
    .fixp_vs2h (fixp_vs2h),
    .fixp_vs1h (fixp_vs1h)
  );
endmodule
// END GENERATED(wrapper)
