// =============================================================================
// VIAlu.sv —— 向量整数「归约 / 掩码 / vmv.x.s」ALU（两拍流水）
//
// 在哪一层：向量整数 FU 外壳 VIAluFix 之外的另一类向量整数运算核（yunsuan 的 VIAlu，非 Mgu 外壳）：
//   归约（vredsum/vredmax/...，子模块 Reduction）、掩码类（vcpop/vfirst/vmsbf/viota/vid/...，子模块 VMask）、
//   以及 vmv.x.s（取 vs2 第 0 个元素、按 SEW 符号扩展到 64 位）。
// 设计源：yunsuan/vector/VectorALU/VIAlu.scala class VIAlu。
//
// 机制：
//   §1 两个子单元都拿同一份入口（in_valid / opcode / info / vs1 / vs2 / old_vd / mask）同时算，各自两拍出结果。
//   §2 vmv.x.s 自己走两拍：入口拍按 vdType[1:0]（SEW）把 vs2 的元素 0 符号扩展成 64 位锁存（vs2Ext），
//      下一拍随 validS1 再打一拍（vs2ExtS2）；opcode 也同样打两拍（opcodeS1 / opcodeS2）。
//   §3 出口按第 2 拍的 opcode 三选一：vmv.x.s（0x2F）→ {64'b0, vs2ExtS2}；归约（0x21..0x26）→ Reduction；
//      其余 → VMask。
// 怪癖（照 golden）：
//   - validS1 是 RegNext(in_valid)，**无复位**；所有寄存器都无复位（firtool 普通 always）。
//   - vs2Ext 的 Mux1H 按 SEW 四选一（按位或），SEW 两位全覆盖，等价于普通多路选择。
//   - Scala 的 io.out.valid / vxsat 父级没接，firtool 已消掉端口。
// 子模块：Reduction vReduAlu、VMask vMaskAlu（实例名与 golden 一致；本仓已签核重写件）。
// golden 对照：G1-canonical/golden-rtl/VIAlu.sv
// =============================================================================
module xs_VIAlu_core (
  input  logic         clock,
  input  logic         reset,
  input  logic         in_valid,
  input  logic [5:0]   opcode,
  input  logic         vm,
  input  logic         ma,
  input  logic         ta,
  input  logic [2:0]   vlmul,
  input  logic [7:0]   vl,
  input  logic [6:0]   vstart,
  input  logic [5:0]   uop_idx,
  input  logic [3:0]   src_type_vs2,      // srcType(0)
  input  logic [3:0]   vd_type,           // [1:0] = vd 的 SEW
  input  logic [127:0] vs1,
  input  logic [127:0] vs2,
  input  logic [127:0] old_vd,
  input  logic [127:0] mask,
  output logic [127:0] vd
);
  localparam logic [5:0] OP_VMV_X_S = 6'h2F;   // VAluOpcode.vmvxs
  localparam logic [5:0] OP_REDU_LO = 6'h20;   // 归约 opcode 开区间 (0x20, 0x27)
  localparam logic [5:0] OP_REDU_HI = 6'h27;

  // ---------------------------------------------------------------------------
  // §1 两个子单元
  // ---------------------------------------------------------------------------
  logic [127:0] redu_vd, mask_vd;
  Reduction vReduAlu (
    .clock                  (clock),
    .reset                  (reset),
    .io_in_valid            (in_valid),
    .io_in_bits_opcode_op   (opcode),
    .io_in_bits_info_vm     (vm),
    .io_in_bits_info_ta     (ta),
    .io_in_bits_info_vlmul  (vlmul),
    .io_in_bits_info_vl     (vl),
    .io_in_bits_info_uopIdx (uop_idx),
    .io_in_bits_srcType_0   (src_type_vs2),
    .io_in_bits_vdType      (vd_type),
    .io_in_bits_vs1         (vs1),
    .io_in_bits_vs2         (vs2),
    .io_in_bits_old_vd      (old_vd),
    .io_in_bits_mask        (mask),
    .io_out_vd              (redu_vd)
  );
  VMask vMaskAlu (
    .clock                  (clock),
    .reset                  (reset),
    .io_in_valid            (in_valid),
    .io_in_bits_opcode_op   (opcode),
    .io_in_bits_info_vm     (vm),
    .io_in_bits_info_ma     (ma),
    .io_in_bits_info_ta     (ta),
    .io_in_bits_info_vl     (vl),
    .io_in_bits_info_vstart (vstart),
    .io_in_bits_info_uopIdx (uop_idx),
    .io_in_bits_vdType      (vd_type),
    .io_in_bits_vs1         (vs1),
    .io_in_bits_vs2         (vs2),
    .io_in_bits_old_vd      (old_vd),
    .io_in_bits_mask        (mask),
    .io_out_vd              (mask_vd)
  );

  // ---------------------------------------------------------------------------
  // §2 vmv.x.s：vs2 元素 0 按 SEW 符号扩展到 64 位，与 opcode 一起打两拍（寄存器名同 golden，无复位）
  // ---------------------------------------------------------------------------
  logic [63:0] vs2_elem0_sext;
  always_comb begin
    case (vd_type[1:0])
      2'd0:    vs2_elem0_sext = {{56{vs2[7]}},  vs2[7:0]};
      2'd1:    vs2_elem0_sext = {{48{vs2[15]}}, vs2[15:0]};
      2'd2:    vs2_elem0_sext = {{32{vs2[31]}}, vs2[31:0]};
      default: vs2_elem0_sext = vs2[63:0];
    endcase
  end

  logic [63:0] vs2Ext, vs2ExtS2;
  logic [5:0]  opcodeS1_op, opcodeS2_op;
  logic        validS1;
  always_ff @(posedge clock) begin
    if (in_valid) begin
      vs2Ext      <= vs2_elem0_sext;
      opcodeS1_op <= opcode;
    end
    validS1 <= in_valid;
    if (validS1) begin
      opcodeS2_op <= opcodeS1_op;
      vs2ExtS2    <= vs2Ext;
    end
  end

  // ---------------------------------------------------------------------------
  // §3 出口三选一（按第 2 拍的 opcode）
  // ---------------------------------------------------------------------------
  logic is_vmv_x_s, is_reduction;
  assign is_vmv_x_s   = (opcodeS2_op == OP_VMV_X_S);
  assign is_reduction = (opcodeS2_op > OP_REDU_LO) & (opcodeS2_op < OP_REDU_HI);
  assign vd = is_vmv_x_s   ? {64'h0, vs2ExtS2}
            : is_reduction ? redu_vd
            :                mask_vd;
endmodule

module VIAlu (
  input  logic         clock,
  input  logic         reset,
  input  logic         io_in_valid,
  input  logic [5:0]   io_in_bits_opcode_op,
  input  logic         io_in_bits_info_vm,
  input  logic         io_in_bits_info_ma,
  input  logic         io_in_bits_info_ta,
  input  logic [2:0]   io_in_bits_info_vlmul,
  input  logic [7:0]   io_in_bits_info_vl,
  input  logic [6:0]   io_in_bits_info_vstart,
  input  logic [5:0]   io_in_bits_info_uopIdx,
  input  logic [3:0]   io_in_bits_srcType_0,
  input  logic [3:0]   io_in_bits_vdType,
  input  logic [127:0] io_in_bits_vs1,
  input  logic [127:0] io_in_bits_vs2,
  input  logic [127:0] io_in_bits_old_vd,
  input  logic [127:0] io_in_bits_mask,
  output logic [127:0] io_out_bits_vd
);
  xs_VIAlu_core u_core (
    .clock        (clock),
    .reset        (reset),
    .in_valid     (io_in_valid),
    .opcode       (io_in_bits_opcode_op),
    .vm           (io_in_bits_info_vm),
    .ma           (io_in_bits_info_ma),
    .ta           (io_in_bits_info_ta),
    .vlmul        (io_in_bits_info_vlmul),
    .vl           (io_in_bits_info_vl),
    .vstart       (io_in_bits_info_vstart),
    .uop_idx      (io_in_bits_info_uopIdx),
    .src_type_vs2 (io_in_bits_srcType_0),
    .vd_type      (io_in_bits_vdType),
    .vs1          (io_in_bits_vs1),
    .vs2          (io_in_bits_vs2),
    .old_vd       (io_in_bits_old_vd),
    .mask         (io_in_bits_mask),
    .vd           (io_out_bits_vd)
  );
endmodule
