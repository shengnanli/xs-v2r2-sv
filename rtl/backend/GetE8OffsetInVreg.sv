// GetE8OffsetInVreg —— 把元素序号换算为 128-bit 向量寄存器内的字节偏移。
// eewOH 依次表示 8/16/32/64 位元素，因此对应把 idx 左移 0/1/2/3 位。
// 硬件接口保留 Chisel Mux1H 的逐项 OR 语义；即使输入不是 one-hot，
// 输出仍等于所有被选择候选值的按位或，而不是优先编码结果。

module xs_GetE8OffsetInVreg_core (
  input  logic [3:0] eew_onehot,
  input  logic [6:0] element_index,
  output logic [3:0] byte_offset
);
  logic [3:0] offset_e8;
  logic [3:0] offset_e16;
  logic [3:0] offset_e32;
  logic [3:0] offset_e64;

  assign offset_e8  = eew_onehot[0] ? element_index[3:0]       : 4'b0;
  assign offset_e16 = eew_onehot[1] ? {element_index[2:0], 1'b0} : 4'b0;
  assign offset_e32 = eew_onehot[2] ? {element_index[1:0], 2'b0} : 4'b0;
  assign offset_e64 = eew_onehot[3] ? {element_index[0],   3'b0} : 4'b0;
  assign byte_offset = offset_e8 | offset_e16 | offset_e32 | offset_e64;
endmodule


module GetE8OffsetInVreg (
  input  logic [3:0] in_eewOH,
  input  logic [6:0] in_idx,
  output logic [3:0] out_offset
);
  xs_GetE8OffsetInVreg_core u_core (
    .eew_onehot  (in_eewOH),
    .element_index(in_idx),
    .byte_offset (out_offset)
  );
endmodule
