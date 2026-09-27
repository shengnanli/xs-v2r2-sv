// VIMacSrcTypeModule —— 向量整数乘加单元的两个源操作数类型编码器。
// 每个四位类型由“非浮点”标志 0、fuOpType 中的有符号属性位以及
// 当前 vsew 两位组成；vs1 使用 fuOpType[5]，vs2 使用 fuOpType[6]。
// 该叶模块纯组合、无状态，也不解释其余 fuOpType 位。

module xs_VIMacSrcTypeModule_core (
  input  logic [8:0] fu_op_type,
  input  logic [1:0] vsew,
  output logic [3:0] vs1_type,
  output logic [3:0] vs2_type
);
  assign vs1_type = {1'b0, fu_op_type[5], vsew};
  assign vs2_type = {1'b0, fu_op_type[6], vsew};
endmodule


module VIMacSrcTypeModule (
  input  logic [8:0] io_in_fuOpType,
  input  logic [1:0] io_in_vsew,
  output logic [3:0] io_out_vs1Type,
  output logic [3:0] io_out_vs2Type
);
  xs_VIMacSrcTypeModule_core u_core (
    .fu_op_type(io_in_fuOpType),
    .vsew      (io_in_vsew),
    .vs1_type  (io_out_vs1Type),
    .vs2_type  (io_out_vs2Type)
  );
endmodule
