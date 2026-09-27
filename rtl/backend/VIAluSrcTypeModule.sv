// VIAluSrcTypeModule —— 向量整数 ALU 的 vs1/vs2/vd 元素类型推导。
// fuOpType[8:7] 选择普通运算的扩宽方向、extension 的缩放倍数，或
// mask 目的类型；fuOpType[6] 是源类型符号属性，vsew 运算按两位回绕。
// isExt 与 isDstMask 在架构上通常互斥，但硬件保留原有按位 OR 组合语义。

module xs_VIAluSrcTypeModule_core (
  input  logic [8:0] fu_op_type,
  input  logic [1:0] vsew,
  input  logic       is_extension,
  input  logic       is_mask_destination,
  output logic [3:0] vs1_type,
  output logic [3:0] vs2_type,
  output logic [3:0] vd_type,
  output logic       extension_factor_2,
  output logic       extension_factor_4,
  output logic       extension_factor_8
);
  logic [1:0] operation_class;
  logic [1:0] sew_plus_one;
  logic [1:0] sew_minus_one;
  logic [1:0] sew_minus_two;
  logic [1:0] normal_vs1_sew;
  logic [1:0] normal_vs2_sew;
  logic [1:0] normal_vd_sew;
  logic [1:0] extension_source_sew;
  logic [1:0] extension_vd_sew;
  logic [3:0] normal_vs1_type;
  logic [3:0] normal_vs2_type;
  logic [3:0] normal_vd_type;
  logic [3:0] extension_source_type;
  logic [3:0] extension_vd_type;
  logic [3:0] mask_vs1_type;
  logic [3:0] mask_vs2_type;
  logic [3:0] mask_vd_type;
  logic       normal_operation;
  logic       is_vector_extension;

  assign operation_class = fu_op_type[8:7];
  assign sew_plus_one  = vsew + 2'd1;
  assign sew_minus_one = vsew - 2'd1;
  assign sew_minus_two = vsew - 2'd2;
  assign normal_operation = ~(is_extension | is_mask_destination);
  assign is_vector_extension = fu_op_type[5:0] == 6'h02;

  always_comb begin
    normal_vs1_sew = vsew;
    normal_vs2_sew = vsew;
    normal_vd_sew  = vsew;
    unique case (operation_class)
      2'd1: normal_vd_sew = sew_plus_one;
      2'd2: begin
        normal_vs2_sew = sew_plus_one;
        normal_vd_sew  = sew_plus_one;
      end
      2'd3: normal_vs2_sew = sew_plus_one;
      default: begin end
    endcase
  end

  always_comb begin
    unique case (operation_class)
      2'd0: begin
        extension_source_sew = sew_minus_one;
        extension_vd_sew = vsew;
      end
      2'd1: begin
        extension_source_sew = sew_minus_two;
        extension_vd_sew = vsew;
      end
      2'd2: begin
        extension_source_sew = sew_plus_one;
        extension_vd_sew = vsew;
      end
      default: begin
        extension_source_sew = 2'b00;
        extension_vd_sew = 2'b00;
      end
    endcase
  end

  assign normal_vs1_type = {1'b0, fu_op_type[6], normal_vs1_sew};
  assign normal_vs2_type = {1'b0, fu_op_type[6], normal_vs2_sew};
  assign normal_vd_type  = {1'b0, fu_op_type[6], normal_vd_sew};
  assign extension_source_type = {1'b0, fu_op_type[6], extension_source_sew};
  assign extension_vd_type = {1'b0, fu_op_type[6], extension_vd_sew};

  always_comb begin
    mask_vs1_type = 4'b0;
    mask_vs2_type = 4'b0;
    mask_vd_type  = 4'b0;
    unique case (operation_class)
      2'd1, 2'd2: begin
        mask_vs1_type = {1'b0, fu_op_type[6], vsew};
        mask_vs2_type = {1'b0, fu_op_type[6], vsew};
        mask_vd_type  = 4'hf;
      end
      2'd3: begin
        mask_vs1_type = 4'hf;
        mask_vs2_type = 4'hf;
        mask_vd_type  = 4'hf;
      end
      default: begin end
    endcase
  end

  assign vs1_type = ({4{normal_operation}} & normal_vs1_type)
                  | ({4{is_extension}} & extension_source_type)
                  | ({4{is_mask_destination}} & mask_vs1_type);
  assign vs2_type = ({4{normal_operation}} & normal_vs2_type)
                  | ({4{is_extension}} & extension_source_type)
                  | ({4{is_mask_destination}} & mask_vs2_type);
  assign vd_type  = ({4{normal_operation}} & normal_vd_type)
                  | ({4{is_extension}} & extension_vd_type)
                  | ({4{is_mask_destination}} & mask_vd_type);

  assign extension_factor_2 = is_vector_extension & (operation_class == 2'd0);
  assign extension_factor_4 = is_vector_extension & (operation_class == 2'd1);
  assign extension_factor_8 = is_vector_extension & (operation_class == 2'd2);
endmodule


module VIAluSrcTypeModule (
  input  logic [8:0] io_in_fuOpType,
  input  logic [1:0] io_in_vsew,
  input  logic       io_in_isExt,
  input  logic       io_in_isDstMask,
  output logic [3:0] io_out_vs1Type,
  output logic [3:0] io_out_vs2Type,
  output logic [3:0] io_out_vdType,
  output logic       io_out_isVextF2,
  output logic       io_out_isVextF4,
  output logic       io_out_isVextF8
);
  xs_VIAluSrcTypeModule_core u_core (
    .fu_op_type         (io_in_fuOpType),
    .vsew               (io_in_vsew),
    .is_extension       (io_in_isExt),
    .is_mask_destination(io_in_isDstMask),
    .vs1_type           (io_out_vs1Type),
    .vs2_type           (io_out_vs2Type),
    .vd_type            (io_out_vdType),
    .extension_factor_2 (io_out_isVextF2),
    .extension_factor_4 (io_out_isVextF4),
    .extension_factor_8 (io_out_isVextF8)
  );
endmodule
