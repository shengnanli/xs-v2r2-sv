// ============================================================================
// VIAluDecoder.sv —— 向量整数归约/掩码类指令的 fuOpType 译码器
//
// 在哪一层：VIPU（向量整数归约/掩码功能单元）入口处，把 8 位 fuOpType
//   （yunsuan VipuType 编码）译成 VIAlu 数据通路要用的 6 位 opcode 和
//   源/目的操作数的元素类型。
// IO：io_in_fuOpType 是指令操作码；io_out_opcode 送给 VIAlu；
//   io_out_srcType2 / io_out_vdType 编码 vs2 / vd 的元素类型
//   （0=uSew, 1=uSew2, 2=sSew, 3=sSew2, 4=mask；sew 由上层另行拼接）。
//   golden 里 srcType1 恒等于 srcType2，被 firtool 当冗余输出消去，故无此端口。
// 核心机制：18 条精确编码的查表译码（Chisel DecodeLogic），未命中输出全 0。
//   opcode 数值与 yunsuan/VAluDecode.scala 的 VAluOpcode 一致
//   （已对 golden 全 256 输入穷举实测核对）。
// 纯组合逻辑：无时钟、无复位、无寄存器。
// ============================================================================

module xs_VIAluDecoder_core (
  input  logic [7:0] fu_op_type,   // VipuType 编码的指令操作码
  output logic [5:0] opcode,       // VIAlu 数据通路操作码（golden 编码，见头注释）
  output logic [2:0] src_type2,    // vs2 元素类型
  output logic [2:0] vd_type       // vd 元素类型
);
  // ---- VipuType 指令编码（yunsuan package.scala，与 golden 逐位一致）----
  localparam logic [7:0] OP_VREDSUM_VS  = 8'h39;
  localparam logic [7:0] OP_VREDMAXU_VS = 8'h3A;
  localparam logic [7:0] OP_VREDMAX_VS  = 8'h3B;
  localparam logic [7:0] OP_VREDMINU_VS = 8'h3C;
  localparam logic [7:0] OP_VREDMIN_VS  = 8'h3D;
  localparam logic [7:0] OP_VREDAND_VS  = 8'h3E;
  localparam logic [7:0] OP_VREDOR_VS   = 8'h3F;
  localparam logic [7:0] OP_VREDXOR_VS  = 8'h40;
  localparam logic [7:0] OP_VWREDSUMU_VS = 8'h41;
  localparam logic [7:0] OP_VWREDSUM_VS  = 8'h42;
  localparam logic [7:0] OP_VCPOP_M     = 8'h4B;
  localparam logic [7:0] OP_VFIRST_M    = 8'h4C;
  localparam logic [7:0] OP_VMSBF_M     = 8'h4D;
  localparam logic [7:0] OP_VMSIF_M     = 8'h4E;
  localparam logic [7:0] OP_VMSOF_M     = 8'h4F;
  localparam logic [7:0] OP_VIOTA_M     = 8'h50;
  localparam logic [7:0] OP_VID_V       = 8'h51;
  localparam logic [7:0] OP_VMV_X_S     = 8'h53;

  // ---- VIAlu opcode（VAluOpcode 编码，与 golden 实测一致）----
  localparam logic [5:0] ALU_VREDSUM = 6'd33;
  localparam logic [5:0] ALU_VREDMAX = 6'd34;
  localparam logic [5:0] ALU_VREDMIN = 6'd35;
  localparam logic [5:0] ALU_VREDAND = 6'd36;
  localparam logic [5:0] ALU_VREDOR  = 6'd37;
  localparam logic [5:0] ALU_VREDXOR = 6'd38;
  localparam logic [5:0] ALU_VCPOP   = 6'd39;
  localparam logic [5:0] ALU_VFIRST  = 6'd40;
  localparam logic [5:0] ALU_VMSBF   = 6'd41;
  localparam logic [5:0] ALU_VMSIF   = 6'd42;
  localparam logic [5:0] ALU_VMSOF   = 6'd43;
  localparam logic [5:0] ALU_VIOTA   = 6'd44;
  localparam logic [5:0] ALU_VID     = 6'd45;
  localparam logic [5:0] ALU_VMVXS   = 6'd47;

  // ---- 元素类型编码 ----
  localparam logic [2:0] ET_U_SEW  = 3'd0;   // 无符号，元素宽 = sew
  localparam logic [2:0] ET_U_SEW2 = 3'd1;   // 无符号，元素宽 = 2*sew（加宽归约的 vd）
  localparam logic [2:0] ET_S_SEW  = 3'd2;   // 有符号，元素宽 = sew
  localparam logic [2:0] ET_S_SEW2 = 3'd3;   // 有符号，元素宽 = 2*sew
  localparam logic [2:0] ET_MASK   = 3'd4;   // 掩码（元素宽 = 1）

  always_comb begin
    opcode    = 6'd0;
    src_type2 = ET_U_SEW;
    vd_type   = ET_U_SEW;
    case (fu_op_type)
      OP_VREDSUM_VS:  begin opcode = ALU_VREDSUM; src_type2 = ET_U_SEW; vd_type = ET_U_SEW;  end
      OP_VREDMAXU_VS: begin opcode = ALU_VREDMAX; src_type2 = ET_U_SEW; vd_type = ET_U_SEW;  end
      OP_VREDMAX_VS:  begin opcode = ALU_VREDMAX; src_type2 = ET_S_SEW; vd_type = ET_S_SEW;  end
      OP_VREDMINU_VS: begin opcode = ALU_VREDMIN; src_type2 = ET_U_SEW; vd_type = ET_U_SEW;  end
      OP_VREDMIN_VS:  begin opcode = ALU_VREDMIN; src_type2 = ET_S_SEW; vd_type = ET_S_SEW;  end
      OP_VREDAND_VS:  begin opcode = ALU_VREDAND; src_type2 = ET_U_SEW; vd_type = ET_U_SEW;  end
      OP_VREDOR_VS:   begin opcode = ALU_VREDOR;  src_type2 = ET_U_SEW; vd_type = ET_U_SEW;  end
      OP_VREDXOR_VS:  begin opcode = ALU_VREDXOR; src_type2 = ET_U_SEW; vd_type = ET_U_SEW;  end
      OP_VWREDSUMU_VS: begin opcode = ALU_VREDSUM; src_type2 = ET_U_SEW; vd_type = ET_U_SEW2; end
      OP_VWREDSUM_VS:  begin opcode = ALU_VREDSUM; src_type2 = ET_S_SEW; vd_type = ET_S_SEW2; end
      OP_VCPOP_M:     begin opcode = ALU_VCPOP;   src_type2 = ET_MASK;  vd_type = ET_U_SEW;  end
      OP_VFIRST_M:    begin opcode = ALU_VFIRST;  src_type2 = ET_MASK;  vd_type = ET_U_SEW;  end
      OP_VMSBF_M:     begin opcode = ALU_VMSBF;   src_type2 = ET_MASK;  vd_type = ET_MASK;   end
      OP_VMSIF_M:     begin opcode = ALU_VMSIF;   src_type2 = ET_MASK;  vd_type = ET_MASK;   end
      OP_VMSOF_M:     begin opcode = ALU_VMSOF;   src_type2 = ET_MASK;  vd_type = ET_MASK;   end
      OP_VIOTA_M:     begin opcode = ALU_VIOTA;   src_type2 = ET_U_SEW; vd_type = ET_U_SEW;  end
      OP_VID_V:       begin opcode = ALU_VID;     src_type2 = ET_U_SEW; vd_type = ET_U_SEW;  end
      OP_VMV_X_S:     begin opcode = ALU_VMVXS;   src_type2 = ET_U_SEW; vd_type = ET_U_SEW;  end
      default: ; // 未命中：DecodeLogic default，全部输出 0（见 always_comb 头部的默认赋值）
    endcase
  end
endmodule

// BEGIN GENERATED(wrapper) —— scripts/gen_arithvec_leaves5.py 生成，勿手改
module VIAluDecoder(
  input  [7:0] io_in_fuOpType,
  output [5:0] io_out_opcode,
  output [2:0] io_out_srcType2,
  output [2:0] io_out_vdType
);

  xs_VIAluDecoder_core u_core (
    .fu_op_type (io_in_fuOpType),
    .opcode (io_out_opcode),
    .src_type2 (io_out_srcType2),
    .vd_type (io_out_vdType)
  );
endmodule
// END GENERATED(wrapper)
