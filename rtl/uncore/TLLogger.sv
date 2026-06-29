// =============================================================================
//  TLLogger —— TileLink 透明监视器 可读重写核 (xs_TLLogger_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/.../TLLogger.scala
//  插在 TileLink 节点 in 与 out 之间的纯透传探针: A/B/C/D/E 五通道的 ready/valid/bits
//  全部 in↔out 直连; 仿真时在 `ifndef SYNTHESIS 下记录事务 (综合/本核不含)。纯组合。
// =============================================================================
module xs_TLLogger_core(
  output         auto_in_a_ready,
  input          auto_in_a_valid,
  input  [3:0]   auto_in_a_bits_opcode,
  input  [2:0]   auto_in_a_bits_param,
  input  [2:0]   auto_in_a_bits_size,
  input  [5:0]   auto_in_a_bits_source,
  input  [47:0]  auto_in_a_bits_address,
  input  [1:0]   auto_in_a_bits_user_alias,
  input  [43:0]  auto_in_a_bits_user_vaddr,
  input  [4:0]   auto_in_a_bits_user_reqSource,
  input          auto_in_a_bits_user_needHint,
  input          auto_in_a_bits_echo_isKeyword,
  input  [31:0]  auto_in_a_bits_mask,
  input  [255:0] auto_in_a_bits_data,
  input          auto_in_a_bits_corrupt,
  input          auto_in_b_ready,
  output         auto_in_b_valid,
  output [2:0]   auto_in_b_bits_opcode,
  output [1:0]   auto_in_b_bits_param,
  output [2:0]   auto_in_b_bits_size,
  output [5:0]   auto_in_b_bits_source,
  output [47:0]  auto_in_b_bits_address,
  output [31:0]  auto_in_b_bits_mask,
  output [255:0] auto_in_b_bits_data,
  output         auto_in_b_bits_corrupt,
  output         auto_in_c_ready,
  input          auto_in_c_valid,
  input  [2:0]   auto_in_c_bits_opcode,
  input  [2:0]   auto_in_c_bits_param,
  input  [2:0]   auto_in_c_bits_size,
  input  [5:0]   auto_in_c_bits_source,
  input  [47:0]  auto_in_c_bits_address,
  input  [1:0]   auto_in_c_bits_user_alias,
  input  [43:0]  auto_in_c_bits_user_vaddr,
  input  [4:0]   auto_in_c_bits_user_reqSource,
  input          auto_in_c_bits_user_needHint,
  input          auto_in_c_bits_echo_isKeyword,
  input  [255:0] auto_in_c_bits_data,
  input          auto_in_c_bits_corrupt,
  input          auto_in_d_ready,
  output         auto_in_d_valid,
  output [3:0]   auto_in_d_bits_opcode,
  output [1:0]   auto_in_d_bits_param,
  output [2:0]   auto_in_d_bits_size,
  output [5:0]   auto_in_d_bits_source,
  output [9:0]   auto_in_d_bits_sink,
  output         auto_in_d_bits_denied,
  output         auto_in_d_bits_echo_isKeyword,
  output [255:0] auto_in_d_bits_data,
  output         auto_in_d_bits_corrupt,
  output         auto_in_e_ready,
  input          auto_in_e_valid,
  input  [9:0]   auto_in_e_bits_sink,
  input          auto_out_a_ready,
  output         auto_out_a_valid,
  output [3:0]   auto_out_a_bits_opcode,
  output [2:0]   auto_out_a_bits_param,
  output [2:0]   auto_out_a_bits_size,
  output [5:0]   auto_out_a_bits_source,
  output [47:0]  auto_out_a_bits_address,
  output [1:0]   auto_out_a_bits_user_alias,
  output [43:0]  auto_out_a_bits_user_vaddr,
  output [4:0]   auto_out_a_bits_user_reqSource,
  output         auto_out_a_bits_user_needHint,
  output         auto_out_a_bits_echo_isKeyword,
  output [31:0]  auto_out_a_bits_mask,
  output [255:0] auto_out_a_bits_data,
  output         auto_out_a_bits_corrupt,
  output         auto_out_b_ready,
  input          auto_out_b_valid,
  input  [2:0]   auto_out_b_bits_opcode,
  input  [1:0]   auto_out_b_bits_param,
  input  [2:0]   auto_out_b_bits_size,
  input  [5:0]   auto_out_b_bits_source,
  input  [47:0]  auto_out_b_bits_address,
  input  [31:0]  auto_out_b_bits_mask,
  input  [255:0] auto_out_b_bits_data,
  input          auto_out_b_bits_corrupt,
  input          auto_out_c_ready,
  output         auto_out_c_valid,
  output [2:0]   auto_out_c_bits_opcode,
  output [2:0]   auto_out_c_bits_param,
  output [2:0]   auto_out_c_bits_size,
  output [5:0]   auto_out_c_bits_source,
  output [47:0]  auto_out_c_bits_address,
  output [1:0]   auto_out_c_bits_user_alias,
  output [43:0]  auto_out_c_bits_user_vaddr,
  output [4:0]   auto_out_c_bits_user_reqSource,
  output         auto_out_c_bits_user_needHint,
  output         auto_out_c_bits_echo_isKeyword,
  output [255:0] auto_out_c_bits_data,
  output         auto_out_c_bits_corrupt,
  output         auto_out_d_ready,
  input          auto_out_d_valid,
  input  [3:0]   auto_out_d_bits_opcode,
  input  [1:0]   auto_out_d_bits_param,
  input  [2:0]   auto_out_d_bits_size,
  input  [5:0]   auto_out_d_bits_source,
  input  [9:0]   auto_out_d_bits_sink,
  input          auto_out_d_bits_denied,
  input          auto_out_d_bits_echo_isKeyword,
  input  [255:0] auto_out_d_bits_data,
  input          auto_out_d_bits_corrupt,
  input          auto_out_e_ready,
  output         auto_out_e_valid,
  output [9:0]   auto_out_e_bits_sink
);

  // 透传连线 (综合可见的全部功能逻辑)
  assign auto_in_a_ready = auto_out_a_ready;
  assign auto_in_b_valid = auto_out_b_valid;
  assign auto_in_b_bits_opcode = auto_out_b_bits_opcode;
  assign auto_in_b_bits_param = auto_out_b_bits_param;
  assign auto_in_b_bits_size = auto_out_b_bits_size;
  assign auto_in_b_bits_source = auto_out_b_bits_source;
  assign auto_in_b_bits_address = auto_out_b_bits_address;
  assign auto_in_b_bits_mask = auto_out_b_bits_mask;
  assign auto_in_b_bits_data = auto_out_b_bits_data;
  assign auto_in_b_bits_corrupt = auto_out_b_bits_corrupt;
  assign auto_in_c_ready = auto_out_c_ready;
  assign auto_in_d_valid = auto_out_d_valid;
  assign auto_in_d_bits_opcode = auto_out_d_bits_opcode;
  assign auto_in_d_bits_param = auto_out_d_bits_param;
  assign auto_in_d_bits_size = auto_out_d_bits_size;
  assign auto_in_d_bits_source = auto_out_d_bits_source;
  assign auto_in_d_bits_sink = auto_out_d_bits_sink;
  assign auto_in_d_bits_denied = auto_out_d_bits_denied;
  assign auto_in_d_bits_echo_isKeyword = auto_out_d_bits_echo_isKeyword;
  assign auto_in_d_bits_data = auto_out_d_bits_data;
  assign auto_in_d_bits_corrupt = auto_out_d_bits_corrupt;
  assign auto_in_e_ready = auto_out_e_ready;
  assign auto_out_a_valid = auto_in_a_valid;
  assign auto_out_a_bits_opcode = auto_in_a_bits_opcode;
  assign auto_out_a_bits_param = auto_in_a_bits_param;
  assign auto_out_a_bits_size = auto_in_a_bits_size;
  assign auto_out_a_bits_source = auto_in_a_bits_source;
  assign auto_out_a_bits_address = auto_in_a_bits_address;
  assign auto_out_a_bits_user_alias = auto_in_a_bits_user_alias;
  assign auto_out_a_bits_user_vaddr = auto_in_a_bits_user_vaddr;
  assign auto_out_a_bits_user_reqSource = auto_in_a_bits_user_reqSource;
  assign auto_out_a_bits_user_needHint = auto_in_a_bits_user_needHint;
  assign auto_out_a_bits_echo_isKeyword = auto_in_a_bits_echo_isKeyword;
  assign auto_out_a_bits_mask = auto_in_a_bits_mask;
  assign auto_out_a_bits_data = auto_in_a_bits_data;
  assign auto_out_a_bits_corrupt = auto_in_a_bits_corrupt;
  assign auto_out_b_ready = auto_in_b_ready;
  assign auto_out_c_valid = auto_in_c_valid;
  assign auto_out_c_bits_opcode = auto_in_c_bits_opcode;
  assign auto_out_c_bits_param = auto_in_c_bits_param;
  assign auto_out_c_bits_size = auto_in_c_bits_size;
  assign auto_out_c_bits_source = auto_in_c_bits_source;
  assign auto_out_c_bits_address = auto_in_c_bits_address;
  assign auto_out_c_bits_user_alias = auto_in_c_bits_user_alias;
  assign auto_out_c_bits_user_vaddr = auto_in_c_bits_user_vaddr;
  assign auto_out_c_bits_user_reqSource = auto_in_c_bits_user_reqSource;
  assign auto_out_c_bits_user_needHint = auto_in_c_bits_user_needHint;
  assign auto_out_c_bits_echo_isKeyword = auto_in_c_bits_echo_isKeyword;
  assign auto_out_c_bits_data = auto_in_c_bits_data;
  assign auto_out_c_bits_corrupt = auto_in_c_bits_corrupt;
  assign auto_out_d_ready = auto_in_d_ready;
  assign auto_out_e_valid = auto_in_e_valid;
  assign auto_out_e_bits_sink = auto_in_e_bits_sink;

endmodule
