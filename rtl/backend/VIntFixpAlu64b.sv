// =============================================================================
// VIntFixpAlu64b.sv —— 向量整数/定点 ALU 的 64 位半片（两拍流水）
//
// 在哪一层：VIAlu（128 位向量整数 ALU）由两个本件拼成，各管 64 位。本件内部：
//   第 1 拍：VIntAdder64b（加减/比较/进位类）与 VIntMisc64b（移位/逻辑/扩展/计数类）并行算；
//   第 2 拍：VFixPoint64b 把 adder/misc 送来的中间量整理成定点结果（饱和/平均/缩放移位/窄化裁剪）。
//   fire 是流水寄存器的使能：所有第 1 拍结果（含送给 VFixPoint64b 的整包控制与数据）在 fire 时打拍。
// 设计源：yunsuan/vector/VectorALU/VIntFixpAlu.scala class VIntFixpAlu64b。
//
// 输出选择（第 2 拍）：
//   vd       = isFixp ? 定点结果 : (isMisc ? misc 结果 : adder 结果)
//   narrowVd = isFixp ? 定点窄化结果 : misc 窄化结果
//   cmpOut   = adder 的比较/进位输出（打一拍）
//   vxsat    = 定点单元的饱和标志（不看 isFixp，由父级按 updateType 过滤）
// 送给定点单元的派生控制：
//   sew_oneHot = SewOH(vdType[1:0])；isSigned = srcType(vs2)[3:2]==1；
//   isNClip   = 缩放移位(vssrl/vssra) 且 vdType[1:0] != srcType(vs2)[1:0]（即结果比源窄）。
// 怪癖（照 golden）：
//   - 所有流水寄存器都不复位（RegEnable），fire=0 时保持。
//   - io_narrow 是 8 位端口，VIntMisc64b 只用 bit0；VIntAdder64b 不接 srcType_0，VIntMisc64b 不接 srcType_1。
//   - VFixPoint64b 收的是 opcode/vxrm 的打拍副本，与第 1 拍的 opcode 不是同一根线。
// 子模块：VIntAdder64b / VIntMisc64b（本仓已签核）、VFixPoint64b（本 lane）。实例名与 golden 一致。
// golden 对照：G1-canonical/golden-rtl/VIntFixpAlu64b.sv
// =============================================================================
module xs_VIntFixpAlu64b_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [5:0]  opcode,
  input  logic        info_vm,
  input  logic        info_ma,
  input  logic [5:0]  info_uop_idx,
  input  logic [1:0]  info_vxrm,
  input  logic [3:0]  src_type_vs2,     // srcType(0)
  input  logic [3:0]  src_type_vs1,     // srcType(1)
  input  logic [3:0]  vd_type,
  input  logic [63:0] vs1,
  input  logic [63:0] vs2_adder,
  input  logic [63:0] vs2_misc,
  input  logic [7:0]  vmask,
  input  logic [7:0]  old_vd,
  input  logic [7:0]  narrow,
  input  logic        is_sub,
  input  logic        is_misc,
  input  logic        is_fixp,
  input  logic        widen,
  input  logic        widen_vs2,
  output logic [63:0] vd,
  output logic [31:0] narrow_vd,
  output logic [7:0]  cmp_out,
  output logic [7:0]  vxsat
);
  localparam logic [5:0] OP_VSSRL = 6'd31, OP_VSSRA = 6'd32;

  // ---- §1 第 1 拍：加减器与杂项单元 ----
  logic [63:0] adder_vd;
  logic [7:0]  adder_cmp_out;
  logic [7:0]  adder_cout, adder_vs2h, adder_vs1h;   // 送定点单元的每字节进位/符号
  logic [63:0] adder_fixp_vd;
  VIntAdder64b vIntAdder64b (
    .io_opcode_op     (opcode),
    .io_info_vm       (info_vm),
    .io_info_ma       (info_ma),
    .io_info_uopIdx   (info_uop_idx),
    .io_srcType_1     (src_type_vs1),
    .io_vdType        (vd_type),
    .io_vs1           (vs1),
    .io_vs2           (vs2_adder),
    .io_vmask         (vmask),
    .io_oldVd         (old_vd),
    .io_isSub         (is_sub),
    .io_widen         (widen),
    .io_widen_vs2     (widen_vs2),
    .io_vd            (adder_vd),
    .io_cmpOut        (adder_cmp_out),
    .io_toFixP_cout_0 (adder_cout[0]), .io_toFixP_cout_1 (adder_cout[1]),
    .io_toFixP_cout_2 (adder_cout[2]), .io_toFixP_cout_3 (adder_cout[3]),
    .io_toFixP_cout_4 (adder_cout[4]), .io_toFixP_cout_5 (adder_cout[5]),
    .io_toFixP_cout_6 (adder_cout[6]), .io_toFixP_cout_7 (adder_cout[7]),
    .io_toFixP_vd_0   (adder_fixp_vd[7:0]),   .io_toFixP_vd_1 (adder_fixp_vd[15:8]),
    .io_toFixP_vd_2   (adder_fixp_vd[23:16]), .io_toFixP_vd_3 (adder_fixp_vd[31:24]),
    .io_toFixP_vd_4   (adder_fixp_vd[39:32]), .io_toFixP_vd_5 (adder_fixp_vd[47:40]),
    .io_toFixP_vd_6   (adder_fixp_vd[55:48]), .io_toFixP_vd_7 (adder_fixp_vd[63:56]),
    .io_toFixP_vs2H_0 (adder_vs2h[0]), .io_toFixP_vs2H_1 (adder_vs2h[1]),
    .io_toFixP_vs2H_2 (adder_vs2h[2]), .io_toFixP_vs2H_3 (adder_vs2h[3]),
    .io_toFixP_vs2H_4 (adder_vs2h[4]), .io_toFixP_vs2H_5 (adder_vs2h[5]),
    .io_toFixP_vs2H_6 (adder_vs2h[6]), .io_toFixP_vs2H_7 (adder_vs2h[7]),
    .io_toFixP_vs1H_0 (adder_vs1h[0]), .io_toFixP_vs1H_1 (adder_vs1h[1]),
    .io_toFixP_vs1H_2 (adder_vs1h[2]), .io_toFixP_vs1H_3 (adder_vs1h[3]),
    .io_toFixP_vs1H_4 (adder_vs1h[4]), .io_toFixP_vs1H_5 (adder_vs1h[5]),
    .io_toFixP_vs1H_6 (adder_vs1h[6]), .io_toFixP_vs1H_7 (adder_vs1h[7])
  );

  logic [63:0] misc_vd;
  logic [31:0] misc_narrow_vd;
  logic [63:0] misc_shift_out;
  logic [7:0]  misc_rnd_high, misc_rnd_tail;
  VIntMisc64b vIntMisc64b (
    .io_opcode_op       (opcode),
    .io_info_vm         (info_vm),
    .io_info_uopIdx     (info_uop_idx),
    .io_srcType_0       (src_type_vs2),
    .io_vdType          (vd_type),
    .io_vs1             (vs1),
    .io_vs2             (vs2_misc),
    .io_vmask           (vmask),
    .io_narrow          (narrow[0]),
    .io_vd              (misc_vd),
    .io_narrowVd        (misc_narrow_vd),
    .io_toFixP_shiftOut (misc_shift_out),
    .io_toFixP_rnd_high (misc_rnd_high),
    .io_toFixP_rnd_tail (misc_rnd_tail)
  );

  // ---- §2 流水寄存器（fire 使能，不复位）----
  logic [63:0] s1_vd_adder, s1_vd_misc;
  logic        s1_is_misc, s1_is_fixp;
  logic [31:0] s1_narrow_vd_misc;
  logic [7:0]  s1_cmp_out;
  // 送定点单元的整包
  logic [5:0]  s1_opcode;
  logic [1:0]  s1_vxrm;
  logic [3:0]  s1_sew_oh;
  logic        s1_is_sub, s1_is_signed, s1_is_nclip;
  logic [7:0]  s1_adder_cout, s1_adder_vs2h, s1_adder_vs1h;
  logic [63:0] s1_adder_vd;
  logic [63:0] s1_misc_shift_out;
  logic [7:0]  s1_misc_rnd_high, s1_misc_rnd_tail;

  logic        is_scaling_shift;
  assign is_scaling_shift = (opcode == OP_VSSRL) | (opcode == OP_VSSRA);

  always_ff @(posedge clock) begin
    if (fire) begin
      s1_vd_adder       <= adder_vd;
      s1_vd_misc        <= misc_vd;
      s1_is_misc        <= is_misc;
      s1_narrow_vd_misc <= misc_narrow_vd;
      s1_cmp_out        <= adder_cmp_out;
      s1_is_fixp        <= is_fixp;
      s1_opcode         <= opcode;
      s1_vxrm           <= info_vxrm;
      s1_sew_oh         <= {vd_type[1:0] == 2'd3, vd_type[1:0] == 2'd2,
                            vd_type[1:0] == 2'd1, vd_type[1:0] == 2'd0};
      s1_is_sub         <= is_sub;
      s1_is_signed      <= (src_type_vs2[3:2] == 2'd1);
      s1_is_nclip       <= is_scaling_shift & (vd_type[1:0] != src_type_vs2[1:0]);
      s1_adder_cout     <= adder_cout;
      s1_adder_vd       <= adder_fixp_vd;
      s1_adder_vs2h     <= adder_vs2h;
      s1_adder_vs1h     <= adder_vs1h;
      s1_misc_shift_out <= misc_shift_out;
      s1_misc_rnd_high  <= misc_rnd_high;
      s1_misc_rnd_tail  <= misc_rnd_tail;
    end
  end

  // ---- §3 第 2 拍：定点单元 ----
  logic [63:0] fixp_vd;
  logic [31:0] fixp_narrow_vd;
  VFixPoint64b vFixPoint64b (
    .io_opcode_op         (s1_opcode),
    .io_info_vxrm         (s1_vxrm),
    .io_sew_oneHot        (s1_sew_oh),
    .io_isSub             (s1_is_sub),
    .io_isSigned          (s1_is_signed),
    .io_isNClip           (s1_is_nclip),
    .io_fromAdder_cout_0  (s1_adder_cout[0]), .io_fromAdder_cout_1 (s1_adder_cout[1]),
    .io_fromAdder_cout_2  (s1_adder_cout[2]), .io_fromAdder_cout_3 (s1_adder_cout[3]),
    .io_fromAdder_cout_4  (s1_adder_cout[4]), .io_fromAdder_cout_5 (s1_adder_cout[5]),
    .io_fromAdder_cout_6  (s1_adder_cout[6]), .io_fromAdder_cout_7 (s1_adder_cout[7]),
    .io_fromAdder_vd_0    (s1_adder_vd[7:0]),   .io_fromAdder_vd_1 (s1_adder_vd[15:8]),
    .io_fromAdder_vd_2    (s1_adder_vd[23:16]), .io_fromAdder_vd_3 (s1_adder_vd[31:24]),
    .io_fromAdder_vd_4    (s1_adder_vd[39:32]), .io_fromAdder_vd_5 (s1_adder_vd[47:40]),
    .io_fromAdder_vd_6    (s1_adder_vd[55:48]), .io_fromAdder_vd_7 (s1_adder_vd[63:56]),
    .io_fromAdder_vs2H_0  (s1_adder_vs2h[0]), .io_fromAdder_vs2H_1 (s1_adder_vs2h[1]),
    .io_fromAdder_vs2H_2  (s1_adder_vs2h[2]), .io_fromAdder_vs2H_3 (s1_adder_vs2h[3]),
    .io_fromAdder_vs2H_4  (s1_adder_vs2h[4]), .io_fromAdder_vs2H_5 (s1_adder_vs2h[5]),
    .io_fromAdder_vs2H_6  (s1_adder_vs2h[6]), .io_fromAdder_vs2H_7 (s1_adder_vs2h[7]),
    .io_fromAdder_vs1H_0  (s1_adder_vs1h[0]), .io_fromAdder_vs1H_1 (s1_adder_vs1h[1]),
    .io_fromAdder_vs1H_2  (s1_adder_vs1h[2]), .io_fromAdder_vs1H_3 (s1_adder_vs1h[3]),
    .io_fromAdder_vs1H_4  (s1_adder_vs1h[4]), .io_fromAdder_vs1H_5 (s1_adder_vs1h[5]),
    .io_fromAdder_vs1H_6  (s1_adder_vs1h[6]), .io_fromAdder_vs1H_7 (s1_adder_vs1h[7]),
    .io_fromMisc_shiftOut (s1_misc_shift_out),
    .io_fromMisc_rnd_high (s1_misc_rnd_high),
    .io_fromMisc_rnd_tail (s1_misc_rnd_tail),
    .io_vd                (fixp_vd),
    .io_narrowVd          (fixp_narrow_vd),
    .io_vxsat             (vxsat)
  );

  // ---- §4 输出选择 ----
  assign vd        = s1_is_fixp ? fixp_vd : (s1_is_misc ? s1_vd_misc : s1_vd_adder);
  assign narrow_vd = s1_is_fixp ? fixp_narrow_vd : s1_narrow_vd_misc;
  assign cmp_out   = s1_cmp_out;
endmodule

module VIntFixpAlu64b (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [5:0]  io_opcode_op,
  input  logic        io_info_vm,
  input  logic        io_info_ma,
  input  logic [5:0]  io_info_uopIdx,
  input  logic [1:0]  io_info_vxrm,
  input  logic [3:0]  io_srcType_0,
  input  logic [3:0]  io_srcType_1,
  input  logic [3:0]  io_vdType,
  input  logic [63:0] io_vs1,
  input  logic [63:0] io_vs2_adder,
  input  logic [63:0] io_vs2_misc,
  input  logic [7:0]  io_vmask,
  input  logic [7:0]  io_oldVd,
  input  logic [7:0]  io_narrow,
  input  logic        io_isSub,
  input  logic        io_isMisc,
  input  logic        io_isFixp,
  input  logic        io_widen,
  input  logic        io_widen_vs2,
  output logic [63:0] io_vd,
  output logic [31:0] io_narrowVd,
  output logic [7:0]  io_cmpOut,
  output logic [7:0]  io_vxsat
);
  xs_VIntFixpAlu64b_core u_core (
    .clock        (clock),
    .fire         (io_fire),
    .opcode       (io_opcode_op),
    .info_vm      (io_info_vm),
    .info_ma      (io_info_ma),
    .info_uop_idx (io_info_uopIdx),
    .info_vxrm    (io_info_vxrm),
    .src_type_vs2 (io_srcType_0),
    .src_type_vs1 (io_srcType_1),
    .vd_type      (io_vdType),
    .vs1          (io_vs1),
    .vs2_adder    (io_vs2_adder),
    .vs2_misc     (io_vs2_misc),
    .vmask        (io_vmask),
    .old_vd       (io_oldVd),
    .narrow       (io_narrow),
    .is_sub       (io_isSub),
    .is_misc      (io_isMisc),
    .is_fixp      (io_isFixp),
    .widen        (io_widen),
    .widen_vs2    (io_widen_vs2),
    .vd           (io_vd),
    .narrow_vd    (io_narrowVd),
    .cmp_out      (io_cmpOut),
    .vxsat        (io_vxsat)
  );
endmodule
