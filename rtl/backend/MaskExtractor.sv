// MaskExtractor —— 把元素级谓词 mask 展开成 16 个字节 lane 的使能。
// vsew=0/1/2/3 分别表示每个元素占 1/2/4/8 字节，因此第 byte_lane 位
// 读取输入 mask 的 floor(byte_lane / bytes_per_element) 位。
// 这种按 lane 表达的实现直接展示了 mask 扩展规则，避免手写重复拼接。

module xs_MaskExtractor_core (
  input  logic [15:0] element_mask,
  input  logic [1:0]  vsew,
  output logic [15:0] byte_mask
);
  always_comb begin
    for (int byte_lane = 0; byte_lane < 16; byte_lane++)
      byte_mask[byte_lane] = element_mask[byte_lane >> vsew];
  end
endmodule


module MaskExtractor (
  input  logic [15:0] io_in_mask,
  input  logic [1:0]  io_in_vsew,
  output logic [15:0] io_out_mask
);
  xs_MaskExtractor_core u_core (
    .element_mask(io_in_mask),
    .vsew       (io_in_vsew),
    .byte_mask  (io_out_mask)
  );
endmodule
