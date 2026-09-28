// VPermSrcTypeModule —— 向量排列单元的源操作数类型编码器。
// 普通排列操作的 vs1 类型由 fuOpType[6] 的符号属性和 vsew 组成；
// 特殊 gather-ei16 操作固定为类型 1，另一类特殊操作固定为 4'hf。
// vs2 始终是无符号、当前 vsew 的向量元素类型。

module xs_VPermSrcTypeModule_core (
  input  logic [8:0] fu_op_type,
  input  logic [1:0] vsew,
  output logic [3:0] vs1_type,
  output logic [3:0] vs2_type
);
  logic gather_index_e16;

  assign gather_index_e16 = fu_op_type[5] & ~fu_op_type[1];

  always_comb begin
    if (gather_index_e16)
      vs1_type = 4'h1;
    else if (fu_op_type[5] & fu_op_type[1])
      vs1_type = 4'hf;
    else
      vs1_type = {{2{fu_op_type[6]}}, vsew};
  end

  assign vs2_type = {2'b00, vsew};
endmodule


module VPermSrcTypeModule (
  input  logic [8:0] io_in_fuOpType,
  input  logic [1:0] io_in_vsew,
  output logic [3:0] io_out_vs1Type,
  output logic [3:0] io_out_vs2Type
);
  xs_VPermSrcTypeModule_core u_core (
    .fu_op_type(io_in_fuOpType),
    .vsew      (io_in_vsew),
    .vs1_type  (io_out_vs1Type),
    .vs2_type  (io_out_vs2Type)
  );
endmodule
