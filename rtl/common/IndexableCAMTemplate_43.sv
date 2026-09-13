// =============================================================================
// IndexableCAMTemplate_43 —— 可按索引写入的 CAM（xs_IndexableCAMTemplate_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，端口位宽即事实）：
//   查询键 ENTRY_WIDTH = 9 位；条目数 NUM_ENTRIES = 4；
//   写索引口 io_w_bits_index = 2 位 = clog2(4)；
//   端口 8 个（clock + 1 读键 + 4 条命中位 + 写 valid/键/索引）；
//   golden 模块体 = 4 个 9 位无复位寄存器 + 4 条相等比较，无子模块。
//   使用者：WrBypass_43（SC 写旁路，9 位索引键、4 项）。
//
// 结构：golden 同名端口表 -> 设参例化 xs_IndexableCAMTemplate_core
//   （核体见 IndexableCAMTemplate.sv，读/写语义与不变式都在那里讲）。
//   $bits(端口) 作为契约参数传给核：键宽或条目数抄错，time 0 就 $fatal。
// =============================================================================

module IndexableCAMTemplate_43(
  input        clock,
  input  [8:0] io_r_req_0_idx,
  output       io_r_resp_0_0,
  output       io_r_resp_0_1,
  output       io_r_resp_0_2,
  output       io_r_resp_0_3,
  input        io_w_valid,
  input  [8:0] io_w_bits_data_idx,
  input  [1:0] io_w_bits_index
);

  logic [3:0] match;

  xs_IndexableCAMTemplate_core #(
    .ENTRY_WIDTH(9), .NUM_ENTRIES(4),
    .PORT_KEY_W($bits(io_r_req_0_idx)), .PORT_IDX_W($bits(io_w_bits_index))
  ) u_core (
    .clock  (clock),
    .r_key  (io_r_req_0_idx),
    .r_match(match),
    .w_valid(io_w_valid),
    .w_key  (io_w_bits_data_idx),
    .w_index(io_w_bits_index)
  );

  assign {io_r_resp_0_3, io_r_resp_0_2, io_r_resp_0_1, io_r_resp_0_0} = match;

endmodule
