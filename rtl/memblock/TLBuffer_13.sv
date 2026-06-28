// =============================================================================
//  TLBuffer_13 —— 4×bank TL-C 五通道时序缓冲 (可读重写核 xs_TLBuffer_13_core)
// -----------------------------------------------------------------------------
//  golden 把 4 个相同的 bank 扁平展开 (20 个 Queue2 / 374 端口)。本核做"外层 banking":
//  把每个 bank 的扁平 auto_{in,out}_{bank}_* 端口打包进 tl_bank_in_t/out_t 结构数组,
//  再用 genvar 例化 4 份 xs_TLBuffer_13_bank。bank 内部才是真正的五通道 skid 缓冲。
//  Queue2_* 为 UT/FM 两侧共用的黑盒叶子 (内含 ram_*)。
// =============================================================================
module xs_TLBuffer_13_core
  import tlbuffer13_pkg::*;
(
  input clock,
  input reset,
  output auto_in_3_a_ready,
  input auto_in_3_a_valid,
  input [3:0] auto_in_3_a_bits_opcode,
  input [2:0] auto_in_3_a_bits_param,
  input [2:0] auto_in_3_a_bits_size,
  input [6:0] auto_in_3_a_bits_source,
  input [47:0] auto_in_3_a_bits_address,
  input [4:0] auto_in_3_a_bits_user_reqSource,
  input [1:0] auto_in_3_a_bits_user_alias,
  input [43:0] auto_in_3_a_bits_user_vaddr,
  input auto_in_3_a_bits_user_needHint,
  input auto_in_3_a_bits_echo_isKeyword,
  input [31:0] auto_in_3_a_bits_mask,
  input [255:0] auto_in_3_a_bits_data,
  input auto_in_3_a_bits_corrupt,
  input auto_in_3_b_ready,
  output auto_in_3_b_valid,
  output [2:0] auto_in_3_b_bits_opcode,
  output [1:0] auto_in_3_b_bits_param,
  output [2:0] auto_in_3_b_bits_size,
  output [6:0] auto_in_3_b_bits_source,
  output [47:0] auto_in_3_b_bits_address,
  output [31:0] auto_in_3_b_bits_mask,
  output [255:0] auto_in_3_b_bits_data,
  output auto_in_3_b_bits_corrupt,
  output auto_in_3_c_ready,
  input auto_in_3_c_valid,
  input [2:0] auto_in_3_c_bits_opcode,
  input [2:0] auto_in_3_c_bits_param,
  input [2:0] auto_in_3_c_bits_size,
  input [6:0] auto_in_3_c_bits_source,
  input [47:0] auto_in_3_c_bits_address,
  input [4:0] auto_in_3_c_bits_user_reqSource,
  input [1:0] auto_in_3_c_bits_user_alias,
  input [43:0] auto_in_3_c_bits_user_vaddr,
  input auto_in_3_c_bits_user_needHint,
  input auto_in_3_c_bits_echo_isKeyword,
  input [255:0] auto_in_3_c_bits_data,
  input auto_in_3_c_bits_corrupt,
  input auto_in_3_d_ready,
  output auto_in_3_d_valid,
  output [3:0] auto_in_3_d_bits_opcode,
  output [1:0] auto_in_3_d_bits_param,
  output [2:0] auto_in_3_d_bits_size,
  output [6:0] auto_in_3_d_bits_source,
  output [7:0] auto_in_3_d_bits_sink,
  output auto_in_3_d_bits_denied,
  output auto_in_3_d_bits_echo_isKeyword,
  output [255:0] auto_in_3_d_bits_data,
  output auto_in_3_d_bits_corrupt,
  output auto_in_3_e_ready,
  input auto_in_3_e_valid,
  input [7:0] auto_in_3_e_bits_sink,
  output auto_in_2_a_ready,
  input auto_in_2_a_valid,
  input [3:0] auto_in_2_a_bits_opcode,
  input [2:0] auto_in_2_a_bits_param,
  input [2:0] auto_in_2_a_bits_size,
  input [6:0] auto_in_2_a_bits_source,
  input [47:0] auto_in_2_a_bits_address,
  input [4:0] auto_in_2_a_bits_user_reqSource,
  input [1:0] auto_in_2_a_bits_user_alias,
  input [43:0] auto_in_2_a_bits_user_vaddr,
  input auto_in_2_a_bits_user_needHint,
  input auto_in_2_a_bits_echo_isKeyword,
  input [31:0] auto_in_2_a_bits_mask,
  input [255:0] auto_in_2_a_bits_data,
  input auto_in_2_a_bits_corrupt,
  input auto_in_2_b_ready,
  output auto_in_2_b_valid,
  output [2:0] auto_in_2_b_bits_opcode,
  output [1:0] auto_in_2_b_bits_param,
  output [2:0] auto_in_2_b_bits_size,
  output [6:0] auto_in_2_b_bits_source,
  output [47:0] auto_in_2_b_bits_address,
  output [31:0] auto_in_2_b_bits_mask,
  output [255:0] auto_in_2_b_bits_data,
  output auto_in_2_b_bits_corrupt,
  output auto_in_2_c_ready,
  input auto_in_2_c_valid,
  input [2:0] auto_in_2_c_bits_opcode,
  input [2:0] auto_in_2_c_bits_param,
  input [2:0] auto_in_2_c_bits_size,
  input [6:0] auto_in_2_c_bits_source,
  input [47:0] auto_in_2_c_bits_address,
  input [4:0] auto_in_2_c_bits_user_reqSource,
  input [1:0] auto_in_2_c_bits_user_alias,
  input [43:0] auto_in_2_c_bits_user_vaddr,
  input auto_in_2_c_bits_user_needHint,
  input auto_in_2_c_bits_echo_isKeyword,
  input [255:0] auto_in_2_c_bits_data,
  input auto_in_2_c_bits_corrupt,
  input auto_in_2_d_ready,
  output auto_in_2_d_valid,
  output [3:0] auto_in_2_d_bits_opcode,
  output [1:0] auto_in_2_d_bits_param,
  output [2:0] auto_in_2_d_bits_size,
  output [6:0] auto_in_2_d_bits_source,
  output [7:0] auto_in_2_d_bits_sink,
  output auto_in_2_d_bits_denied,
  output auto_in_2_d_bits_echo_isKeyword,
  output [255:0] auto_in_2_d_bits_data,
  output auto_in_2_d_bits_corrupt,
  output auto_in_2_e_ready,
  input auto_in_2_e_valid,
  input [7:0] auto_in_2_e_bits_sink,
  output auto_in_1_a_ready,
  input auto_in_1_a_valid,
  input [3:0] auto_in_1_a_bits_opcode,
  input [2:0] auto_in_1_a_bits_param,
  input [2:0] auto_in_1_a_bits_size,
  input [6:0] auto_in_1_a_bits_source,
  input [47:0] auto_in_1_a_bits_address,
  input [4:0] auto_in_1_a_bits_user_reqSource,
  input [1:0] auto_in_1_a_bits_user_alias,
  input [43:0] auto_in_1_a_bits_user_vaddr,
  input auto_in_1_a_bits_user_needHint,
  input auto_in_1_a_bits_echo_isKeyword,
  input [31:0] auto_in_1_a_bits_mask,
  input [255:0] auto_in_1_a_bits_data,
  input auto_in_1_a_bits_corrupt,
  input auto_in_1_b_ready,
  output auto_in_1_b_valid,
  output [2:0] auto_in_1_b_bits_opcode,
  output [1:0] auto_in_1_b_bits_param,
  output [2:0] auto_in_1_b_bits_size,
  output [6:0] auto_in_1_b_bits_source,
  output [47:0] auto_in_1_b_bits_address,
  output [31:0] auto_in_1_b_bits_mask,
  output [255:0] auto_in_1_b_bits_data,
  output auto_in_1_b_bits_corrupt,
  output auto_in_1_c_ready,
  input auto_in_1_c_valid,
  input [2:0] auto_in_1_c_bits_opcode,
  input [2:0] auto_in_1_c_bits_param,
  input [2:0] auto_in_1_c_bits_size,
  input [6:0] auto_in_1_c_bits_source,
  input [47:0] auto_in_1_c_bits_address,
  input [4:0] auto_in_1_c_bits_user_reqSource,
  input [1:0] auto_in_1_c_bits_user_alias,
  input [43:0] auto_in_1_c_bits_user_vaddr,
  input auto_in_1_c_bits_user_needHint,
  input auto_in_1_c_bits_echo_isKeyword,
  input [255:0] auto_in_1_c_bits_data,
  input auto_in_1_c_bits_corrupt,
  input auto_in_1_d_ready,
  output auto_in_1_d_valid,
  output [3:0] auto_in_1_d_bits_opcode,
  output [1:0] auto_in_1_d_bits_param,
  output [2:0] auto_in_1_d_bits_size,
  output [6:0] auto_in_1_d_bits_source,
  output [7:0] auto_in_1_d_bits_sink,
  output auto_in_1_d_bits_denied,
  output auto_in_1_d_bits_echo_isKeyword,
  output [255:0] auto_in_1_d_bits_data,
  output auto_in_1_d_bits_corrupt,
  output auto_in_1_e_ready,
  input auto_in_1_e_valid,
  input [7:0] auto_in_1_e_bits_sink,
  output auto_in_0_a_ready,
  input auto_in_0_a_valid,
  input [3:0] auto_in_0_a_bits_opcode,
  input [2:0] auto_in_0_a_bits_param,
  input [2:0] auto_in_0_a_bits_size,
  input [6:0] auto_in_0_a_bits_source,
  input [47:0] auto_in_0_a_bits_address,
  input [4:0] auto_in_0_a_bits_user_reqSource,
  input [1:0] auto_in_0_a_bits_user_alias,
  input [43:0] auto_in_0_a_bits_user_vaddr,
  input auto_in_0_a_bits_user_needHint,
  input auto_in_0_a_bits_echo_isKeyword,
  input [31:0] auto_in_0_a_bits_mask,
  input [255:0] auto_in_0_a_bits_data,
  input auto_in_0_a_bits_corrupt,
  input auto_in_0_b_ready,
  output auto_in_0_b_valid,
  output [2:0] auto_in_0_b_bits_opcode,
  output [1:0] auto_in_0_b_bits_param,
  output [2:0] auto_in_0_b_bits_size,
  output [6:0] auto_in_0_b_bits_source,
  output [47:0] auto_in_0_b_bits_address,
  output [31:0] auto_in_0_b_bits_mask,
  output [255:0] auto_in_0_b_bits_data,
  output auto_in_0_b_bits_corrupt,
  output auto_in_0_c_ready,
  input auto_in_0_c_valid,
  input [2:0] auto_in_0_c_bits_opcode,
  input [2:0] auto_in_0_c_bits_param,
  input [2:0] auto_in_0_c_bits_size,
  input [6:0] auto_in_0_c_bits_source,
  input [47:0] auto_in_0_c_bits_address,
  input [4:0] auto_in_0_c_bits_user_reqSource,
  input [1:0] auto_in_0_c_bits_user_alias,
  input [43:0] auto_in_0_c_bits_user_vaddr,
  input auto_in_0_c_bits_user_needHint,
  input auto_in_0_c_bits_echo_isKeyword,
  input [255:0] auto_in_0_c_bits_data,
  input auto_in_0_c_bits_corrupt,
  input auto_in_0_d_ready,
  output auto_in_0_d_valid,
  output [3:0] auto_in_0_d_bits_opcode,
  output [1:0] auto_in_0_d_bits_param,
  output [2:0] auto_in_0_d_bits_size,
  output [6:0] auto_in_0_d_bits_source,
  output [7:0] auto_in_0_d_bits_sink,
  output auto_in_0_d_bits_denied,
  output auto_in_0_d_bits_echo_isKeyword,
  output [255:0] auto_in_0_d_bits_data,
  output auto_in_0_d_bits_corrupt,
  output auto_in_0_e_ready,
  input auto_in_0_e_valid,
  input [7:0] auto_in_0_e_bits_sink,
  input auto_out_3_a_ready,
  output auto_out_3_a_valid,
  output [3:0] auto_out_3_a_bits_opcode,
  output [2:0] auto_out_3_a_bits_param,
  output [2:0] auto_out_3_a_bits_size,
  output [6:0] auto_out_3_a_bits_source,
  output [47:0] auto_out_3_a_bits_address,
  output [4:0] auto_out_3_a_bits_user_reqSource,
  output [1:0] auto_out_3_a_bits_user_alias,
  output [43:0] auto_out_3_a_bits_user_vaddr,
  output auto_out_3_a_bits_user_needHint,
  output auto_out_3_a_bits_echo_isKeyword,
  output auto_out_3_a_bits_corrupt,
  output auto_out_3_b_ready,
  input auto_out_3_b_valid,
  input [2:0] auto_out_3_b_bits_opcode,
  input [1:0] auto_out_3_b_bits_param,
  input [47:0] auto_out_3_b_bits_address,
  input [255:0] auto_out_3_b_bits_data,
  input auto_out_3_c_ready,
  output auto_out_3_c_valid,
  output [2:0] auto_out_3_c_bits_opcode,
  output [2:0] auto_out_3_c_bits_param,
  output [2:0] auto_out_3_c_bits_size,
  output [6:0] auto_out_3_c_bits_source,
  output [47:0] auto_out_3_c_bits_address,
  output [255:0] auto_out_3_c_bits_data,
  output auto_out_3_c_bits_corrupt,
  output auto_out_3_d_ready,
  input auto_out_3_d_valid,
  input [3:0] auto_out_3_d_bits_opcode,
  input [1:0] auto_out_3_d_bits_param,
  input [6:0] auto_out_3_d_bits_source,
  input [7:0] auto_out_3_d_bits_sink,
  input auto_out_3_d_bits_denied,
  input auto_out_3_d_bits_echo_isKeyword,
  input [255:0] auto_out_3_d_bits_data,
  input auto_out_3_d_bits_corrupt,
  output auto_out_3_e_valid,
  output [7:0] auto_out_3_e_bits_sink,
  input auto_out_2_a_ready,
  output auto_out_2_a_valid,
  output [3:0] auto_out_2_a_bits_opcode,
  output [2:0] auto_out_2_a_bits_param,
  output [2:0] auto_out_2_a_bits_size,
  output [6:0] auto_out_2_a_bits_source,
  output [47:0] auto_out_2_a_bits_address,
  output [4:0] auto_out_2_a_bits_user_reqSource,
  output [1:0] auto_out_2_a_bits_user_alias,
  output [43:0] auto_out_2_a_bits_user_vaddr,
  output auto_out_2_a_bits_user_needHint,
  output auto_out_2_a_bits_echo_isKeyword,
  output auto_out_2_a_bits_corrupt,
  output auto_out_2_b_ready,
  input auto_out_2_b_valid,
  input [2:0] auto_out_2_b_bits_opcode,
  input [1:0] auto_out_2_b_bits_param,
  input [47:0] auto_out_2_b_bits_address,
  input [255:0] auto_out_2_b_bits_data,
  input auto_out_2_c_ready,
  output auto_out_2_c_valid,
  output [2:0] auto_out_2_c_bits_opcode,
  output [2:0] auto_out_2_c_bits_param,
  output [2:0] auto_out_2_c_bits_size,
  output [6:0] auto_out_2_c_bits_source,
  output [47:0] auto_out_2_c_bits_address,
  output [255:0] auto_out_2_c_bits_data,
  output auto_out_2_c_bits_corrupt,
  output auto_out_2_d_ready,
  input auto_out_2_d_valid,
  input [3:0] auto_out_2_d_bits_opcode,
  input [1:0] auto_out_2_d_bits_param,
  input [6:0] auto_out_2_d_bits_source,
  input [7:0] auto_out_2_d_bits_sink,
  input auto_out_2_d_bits_denied,
  input auto_out_2_d_bits_echo_isKeyword,
  input [255:0] auto_out_2_d_bits_data,
  input auto_out_2_d_bits_corrupt,
  output auto_out_2_e_valid,
  output [7:0] auto_out_2_e_bits_sink,
  input auto_out_1_a_ready,
  output auto_out_1_a_valid,
  output [3:0] auto_out_1_a_bits_opcode,
  output [2:0] auto_out_1_a_bits_param,
  output [2:0] auto_out_1_a_bits_size,
  output [6:0] auto_out_1_a_bits_source,
  output [47:0] auto_out_1_a_bits_address,
  output [4:0] auto_out_1_a_bits_user_reqSource,
  output [1:0] auto_out_1_a_bits_user_alias,
  output [43:0] auto_out_1_a_bits_user_vaddr,
  output auto_out_1_a_bits_user_needHint,
  output auto_out_1_a_bits_echo_isKeyword,
  output auto_out_1_a_bits_corrupt,
  output auto_out_1_b_ready,
  input auto_out_1_b_valid,
  input [2:0] auto_out_1_b_bits_opcode,
  input [1:0] auto_out_1_b_bits_param,
  input [47:0] auto_out_1_b_bits_address,
  input [255:0] auto_out_1_b_bits_data,
  input auto_out_1_c_ready,
  output auto_out_1_c_valid,
  output [2:0] auto_out_1_c_bits_opcode,
  output [2:0] auto_out_1_c_bits_param,
  output [2:0] auto_out_1_c_bits_size,
  output [6:0] auto_out_1_c_bits_source,
  output [47:0] auto_out_1_c_bits_address,
  output [255:0] auto_out_1_c_bits_data,
  output auto_out_1_c_bits_corrupt,
  output auto_out_1_d_ready,
  input auto_out_1_d_valid,
  input [3:0] auto_out_1_d_bits_opcode,
  input [1:0] auto_out_1_d_bits_param,
  input [6:0] auto_out_1_d_bits_source,
  input [7:0] auto_out_1_d_bits_sink,
  input auto_out_1_d_bits_denied,
  input auto_out_1_d_bits_echo_isKeyword,
  input [255:0] auto_out_1_d_bits_data,
  input auto_out_1_d_bits_corrupt,
  output auto_out_1_e_valid,
  output [7:0] auto_out_1_e_bits_sink,
  input auto_out_0_a_ready,
  output auto_out_0_a_valid,
  output [3:0] auto_out_0_a_bits_opcode,
  output [2:0] auto_out_0_a_bits_param,
  output [2:0] auto_out_0_a_bits_size,
  output [6:0] auto_out_0_a_bits_source,
  output [47:0] auto_out_0_a_bits_address,
  output [4:0] auto_out_0_a_bits_user_reqSource,
  output [1:0] auto_out_0_a_bits_user_alias,
  output [43:0] auto_out_0_a_bits_user_vaddr,
  output auto_out_0_a_bits_user_needHint,
  output auto_out_0_a_bits_echo_isKeyword,
  output auto_out_0_a_bits_corrupt,
  output auto_out_0_b_ready,
  input auto_out_0_b_valid,
  input [2:0] auto_out_0_b_bits_opcode,
  input [1:0] auto_out_0_b_bits_param,
  input [47:0] auto_out_0_b_bits_address,
  input [255:0] auto_out_0_b_bits_data,
  input auto_out_0_c_ready,
  output auto_out_0_c_valid,
  output [2:0] auto_out_0_c_bits_opcode,
  output [2:0] auto_out_0_c_bits_param,
  output [2:0] auto_out_0_c_bits_size,
  output [6:0] auto_out_0_c_bits_source,
  output [47:0] auto_out_0_c_bits_address,
  output [255:0] auto_out_0_c_bits_data,
  output auto_out_0_c_bits_corrupt,
  output auto_out_0_d_ready,
  input auto_out_0_d_valid,
  input [3:0] auto_out_0_d_bits_opcode,
  input [1:0] auto_out_0_d_bits_param,
  input [6:0] auto_out_0_d_bits_source,
  input [7:0] auto_out_0_d_bits_sink,
  input auto_out_0_d_bits_denied,
  input auto_out_0_d_bits_echo_isKeyword,
  input [255:0] auto_out_0_d_bits_data,
  input auto_out_0_d_bits_corrupt,
  output auto_out_0_e_valid,
  output [7:0] auto_out_0_e_bits_sink
);

  // 每个 bank 的输入/输出束 (按 bank 下标聚合扁平端口)。
  tl_bank_in_t  bank_in  [TL_NUM_BANKS];
  tl_bank_out_t bank_out [TL_NUM_BANKS];

  // 打包: 各 bank 的扁平输入端口 -> 输入束。
  assign bank_in[0] = '{
    in_a_valid: auto_in_0_a_valid,
    in_a_bits_opcode: auto_in_0_a_bits_opcode,
    in_a_bits_param: auto_in_0_a_bits_param,
    in_a_bits_size: auto_in_0_a_bits_size,
    in_a_bits_source: auto_in_0_a_bits_source,
    in_a_bits_address: auto_in_0_a_bits_address,
    in_a_bits_user_reqSource: auto_in_0_a_bits_user_reqSource,
    in_a_bits_user_alias: auto_in_0_a_bits_user_alias,
    in_a_bits_user_vaddr: auto_in_0_a_bits_user_vaddr,
    in_a_bits_user_needHint: auto_in_0_a_bits_user_needHint,
    in_a_bits_echo_isKeyword: auto_in_0_a_bits_echo_isKeyword,
    in_a_bits_mask: auto_in_0_a_bits_mask,
    in_a_bits_data: auto_in_0_a_bits_data,
    in_a_bits_corrupt: auto_in_0_a_bits_corrupt,
    in_b_ready: auto_in_0_b_ready,
    in_c_valid: auto_in_0_c_valid,
    in_c_bits_opcode: auto_in_0_c_bits_opcode,
    in_c_bits_param: auto_in_0_c_bits_param,
    in_c_bits_size: auto_in_0_c_bits_size,
    in_c_bits_source: auto_in_0_c_bits_source,
    in_c_bits_address: auto_in_0_c_bits_address,
    in_c_bits_user_reqSource: auto_in_0_c_bits_user_reqSource,
    in_c_bits_user_alias: auto_in_0_c_bits_user_alias,
    in_c_bits_user_vaddr: auto_in_0_c_bits_user_vaddr,
    in_c_bits_user_needHint: auto_in_0_c_bits_user_needHint,
    in_c_bits_echo_isKeyword: auto_in_0_c_bits_echo_isKeyword,
    in_c_bits_data: auto_in_0_c_bits_data,
    in_c_bits_corrupt: auto_in_0_c_bits_corrupt,
    in_d_ready: auto_in_0_d_ready,
    in_e_valid: auto_in_0_e_valid,
    in_e_bits_sink: auto_in_0_e_bits_sink,
    out_a_ready: auto_out_0_a_ready,
    out_b_valid: auto_out_0_b_valid,
    out_b_bits_opcode: auto_out_0_b_bits_opcode,
    out_b_bits_param: auto_out_0_b_bits_param,
    out_b_bits_address: auto_out_0_b_bits_address,
    out_b_bits_data: auto_out_0_b_bits_data,
    out_c_ready: auto_out_0_c_ready,
    out_d_valid: auto_out_0_d_valid,
    out_d_bits_opcode: auto_out_0_d_bits_opcode,
    out_d_bits_param: auto_out_0_d_bits_param,
    out_d_bits_source: auto_out_0_d_bits_source,
    out_d_bits_sink: auto_out_0_d_bits_sink,
    out_d_bits_denied: auto_out_0_d_bits_denied,
    out_d_bits_echo_isKeyword: auto_out_0_d_bits_echo_isKeyword,
    out_d_bits_data: auto_out_0_d_bits_data,
    out_d_bits_corrupt: auto_out_0_d_bits_corrupt
  };
  assign bank_in[1] = '{
    in_a_valid: auto_in_1_a_valid,
    in_a_bits_opcode: auto_in_1_a_bits_opcode,
    in_a_bits_param: auto_in_1_a_bits_param,
    in_a_bits_size: auto_in_1_a_bits_size,
    in_a_bits_source: auto_in_1_a_bits_source,
    in_a_bits_address: auto_in_1_a_bits_address,
    in_a_bits_user_reqSource: auto_in_1_a_bits_user_reqSource,
    in_a_bits_user_alias: auto_in_1_a_bits_user_alias,
    in_a_bits_user_vaddr: auto_in_1_a_bits_user_vaddr,
    in_a_bits_user_needHint: auto_in_1_a_bits_user_needHint,
    in_a_bits_echo_isKeyword: auto_in_1_a_bits_echo_isKeyword,
    in_a_bits_mask: auto_in_1_a_bits_mask,
    in_a_bits_data: auto_in_1_a_bits_data,
    in_a_bits_corrupt: auto_in_1_a_bits_corrupt,
    in_b_ready: auto_in_1_b_ready,
    in_c_valid: auto_in_1_c_valid,
    in_c_bits_opcode: auto_in_1_c_bits_opcode,
    in_c_bits_param: auto_in_1_c_bits_param,
    in_c_bits_size: auto_in_1_c_bits_size,
    in_c_bits_source: auto_in_1_c_bits_source,
    in_c_bits_address: auto_in_1_c_bits_address,
    in_c_bits_user_reqSource: auto_in_1_c_bits_user_reqSource,
    in_c_bits_user_alias: auto_in_1_c_bits_user_alias,
    in_c_bits_user_vaddr: auto_in_1_c_bits_user_vaddr,
    in_c_bits_user_needHint: auto_in_1_c_bits_user_needHint,
    in_c_bits_echo_isKeyword: auto_in_1_c_bits_echo_isKeyword,
    in_c_bits_data: auto_in_1_c_bits_data,
    in_c_bits_corrupt: auto_in_1_c_bits_corrupt,
    in_d_ready: auto_in_1_d_ready,
    in_e_valid: auto_in_1_e_valid,
    in_e_bits_sink: auto_in_1_e_bits_sink,
    out_a_ready: auto_out_1_a_ready,
    out_b_valid: auto_out_1_b_valid,
    out_b_bits_opcode: auto_out_1_b_bits_opcode,
    out_b_bits_param: auto_out_1_b_bits_param,
    out_b_bits_address: auto_out_1_b_bits_address,
    out_b_bits_data: auto_out_1_b_bits_data,
    out_c_ready: auto_out_1_c_ready,
    out_d_valid: auto_out_1_d_valid,
    out_d_bits_opcode: auto_out_1_d_bits_opcode,
    out_d_bits_param: auto_out_1_d_bits_param,
    out_d_bits_source: auto_out_1_d_bits_source,
    out_d_bits_sink: auto_out_1_d_bits_sink,
    out_d_bits_denied: auto_out_1_d_bits_denied,
    out_d_bits_echo_isKeyword: auto_out_1_d_bits_echo_isKeyword,
    out_d_bits_data: auto_out_1_d_bits_data,
    out_d_bits_corrupt: auto_out_1_d_bits_corrupt
  };
  assign bank_in[2] = '{
    in_a_valid: auto_in_2_a_valid,
    in_a_bits_opcode: auto_in_2_a_bits_opcode,
    in_a_bits_param: auto_in_2_a_bits_param,
    in_a_bits_size: auto_in_2_a_bits_size,
    in_a_bits_source: auto_in_2_a_bits_source,
    in_a_bits_address: auto_in_2_a_bits_address,
    in_a_bits_user_reqSource: auto_in_2_a_bits_user_reqSource,
    in_a_bits_user_alias: auto_in_2_a_bits_user_alias,
    in_a_bits_user_vaddr: auto_in_2_a_bits_user_vaddr,
    in_a_bits_user_needHint: auto_in_2_a_bits_user_needHint,
    in_a_bits_echo_isKeyword: auto_in_2_a_bits_echo_isKeyword,
    in_a_bits_mask: auto_in_2_a_bits_mask,
    in_a_bits_data: auto_in_2_a_bits_data,
    in_a_bits_corrupt: auto_in_2_a_bits_corrupt,
    in_b_ready: auto_in_2_b_ready,
    in_c_valid: auto_in_2_c_valid,
    in_c_bits_opcode: auto_in_2_c_bits_opcode,
    in_c_bits_param: auto_in_2_c_bits_param,
    in_c_bits_size: auto_in_2_c_bits_size,
    in_c_bits_source: auto_in_2_c_bits_source,
    in_c_bits_address: auto_in_2_c_bits_address,
    in_c_bits_user_reqSource: auto_in_2_c_bits_user_reqSource,
    in_c_bits_user_alias: auto_in_2_c_bits_user_alias,
    in_c_bits_user_vaddr: auto_in_2_c_bits_user_vaddr,
    in_c_bits_user_needHint: auto_in_2_c_bits_user_needHint,
    in_c_bits_echo_isKeyword: auto_in_2_c_bits_echo_isKeyword,
    in_c_bits_data: auto_in_2_c_bits_data,
    in_c_bits_corrupt: auto_in_2_c_bits_corrupt,
    in_d_ready: auto_in_2_d_ready,
    in_e_valid: auto_in_2_e_valid,
    in_e_bits_sink: auto_in_2_e_bits_sink,
    out_a_ready: auto_out_2_a_ready,
    out_b_valid: auto_out_2_b_valid,
    out_b_bits_opcode: auto_out_2_b_bits_opcode,
    out_b_bits_param: auto_out_2_b_bits_param,
    out_b_bits_address: auto_out_2_b_bits_address,
    out_b_bits_data: auto_out_2_b_bits_data,
    out_c_ready: auto_out_2_c_ready,
    out_d_valid: auto_out_2_d_valid,
    out_d_bits_opcode: auto_out_2_d_bits_opcode,
    out_d_bits_param: auto_out_2_d_bits_param,
    out_d_bits_source: auto_out_2_d_bits_source,
    out_d_bits_sink: auto_out_2_d_bits_sink,
    out_d_bits_denied: auto_out_2_d_bits_denied,
    out_d_bits_echo_isKeyword: auto_out_2_d_bits_echo_isKeyword,
    out_d_bits_data: auto_out_2_d_bits_data,
    out_d_bits_corrupt: auto_out_2_d_bits_corrupt
  };
  assign bank_in[3] = '{
    in_a_valid: auto_in_3_a_valid,
    in_a_bits_opcode: auto_in_3_a_bits_opcode,
    in_a_bits_param: auto_in_3_a_bits_param,
    in_a_bits_size: auto_in_3_a_bits_size,
    in_a_bits_source: auto_in_3_a_bits_source,
    in_a_bits_address: auto_in_3_a_bits_address,
    in_a_bits_user_reqSource: auto_in_3_a_bits_user_reqSource,
    in_a_bits_user_alias: auto_in_3_a_bits_user_alias,
    in_a_bits_user_vaddr: auto_in_3_a_bits_user_vaddr,
    in_a_bits_user_needHint: auto_in_3_a_bits_user_needHint,
    in_a_bits_echo_isKeyword: auto_in_3_a_bits_echo_isKeyword,
    in_a_bits_mask: auto_in_3_a_bits_mask,
    in_a_bits_data: auto_in_3_a_bits_data,
    in_a_bits_corrupt: auto_in_3_a_bits_corrupt,
    in_b_ready: auto_in_3_b_ready,
    in_c_valid: auto_in_3_c_valid,
    in_c_bits_opcode: auto_in_3_c_bits_opcode,
    in_c_bits_param: auto_in_3_c_bits_param,
    in_c_bits_size: auto_in_3_c_bits_size,
    in_c_bits_source: auto_in_3_c_bits_source,
    in_c_bits_address: auto_in_3_c_bits_address,
    in_c_bits_user_reqSource: auto_in_3_c_bits_user_reqSource,
    in_c_bits_user_alias: auto_in_3_c_bits_user_alias,
    in_c_bits_user_vaddr: auto_in_3_c_bits_user_vaddr,
    in_c_bits_user_needHint: auto_in_3_c_bits_user_needHint,
    in_c_bits_echo_isKeyword: auto_in_3_c_bits_echo_isKeyword,
    in_c_bits_data: auto_in_3_c_bits_data,
    in_c_bits_corrupt: auto_in_3_c_bits_corrupt,
    in_d_ready: auto_in_3_d_ready,
    in_e_valid: auto_in_3_e_valid,
    in_e_bits_sink: auto_in_3_e_bits_sink,
    out_a_ready: auto_out_3_a_ready,
    out_b_valid: auto_out_3_b_valid,
    out_b_bits_opcode: auto_out_3_b_bits_opcode,
    out_b_bits_param: auto_out_3_b_bits_param,
    out_b_bits_address: auto_out_3_b_bits_address,
    out_b_bits_data: auto_out_3_b_bits_data,
    out_c_ready: auto_out_3_c_ready,
    out_d_valid: auto_out_3_d_valid,
    out_d_bits_opcode: auto_out_3_d_bits_opcode,
    out_d_bits_param: auto_out_3_d_bits_param,
    out_d_bits_source: auto_out_3_d_bits_source,
    out_d_bits_sink: auto_out_3_d_bits_sink,
    out_d_bits_denied: auto_out_3_d_bits_denied,
    out_d_bits_echo_isKeyword: auto_out_3_d_bits_echo_isKeyword,
    out_d_bits_data: auto_out_3_d_bits_data,
    out_d_bits_corrupt: auto_out_3_d_bits_corrupt
  };

  // genvar 例化 4 个完全相同的 bank。
  for (genvar b = 0; b < TL_NUM_BANKS; b++) begin : g_bank
    xs_TLBuffer_13_bank u_bank (
      .clock (clock),
      .reset (reset),
      .bin   (bank_in[b]),
      .bout  (bank_out[b])
    );
  end

  // 解包: 各 bank 的输出束 -> 扁平输出端口。
  assign auto_in_0_a_ready = bank_out[0].in_a_ready;
  assign auto_in_0_b_valid = bank_out[0].in_b_valid;
  assign auto_in_0_b_bits_opcode = bank_out[0].in_b_bits_opcode;
  assign auto_in_0_b_bits_param = bank_out[0].in_b_bits_param;
  assign auto_in_0_b_bits_size = bank_out[0].in_b_bits_size;
  assign auto_in_0_b_bits_source = bank_out[0].in_b_bits_source;
  assign auto_in_0_b_bits_address = bank_out[0].in_b_bits_address;
  assign auto_in_0_b_bits_mask = bank_out[0].in_b_bits_mask;
  assign auto_in_0_b_bits_data = bank_out[0].in_b_bits_data;
  assign auto_in_0_b_bits_corrupt = bank_out[0].in_b_bits_corrupt;
  assign auto_in_0_c_ready = bank_out[0].in_c_ready;
  assign auto_in_0_d_valid = bank_out[0].in_d_valid;
  assign auto_in_0_d_bits_opcode = bank_out[0].in_d_bits_opcode;
  assign auto_in_0_d_bits_param = bank_out[0].in_d_bits_param;
  assign auto_in_0_d_bits_size = bank_out[0].in_d_bits_size;
  assign auto_in_0_d_bits_source = bank_out[0].in_d_bits_source;
  assign auto_in_0_d_bits_sink = bank_out[0].in_d_bits_sink;
  assign auto_in_0_d_bits_denied = bank_out[0].in_d_bits_denied;
  assign auto_in_0_d_bits_echo_isKeyword = bank_out[0].in_d_bits_echo_isKeyword;
  assign auto_in_0_d_bits_data = bank_out[0].in_d_bits_data;
  assign auto_in_0_d_bits_corrupt = bank_out[0].in_d_bits_corrupt;
  assign auto_in_0_e_ready = bank_out[0].in_e_ready;
  assign auto_out_0_a_valid = bank_out[0].out_a_valid;
  assign auto_out_0_a_bits_opcode = bank_out[0].out_a_bits_opcode;
  assign auto_out_0_a_bits_param = bank_out[0].out_a_bits_param;
  assign auto_out_0_a_bits_size = bank_out[0].out_a_bits_size;
  assign auto_out_0_a_bits_source = bank_out[0].out_a_bits_source;
  assign auto_out_0_a_bits_address = bank_out[0].out_a_bits_address;
  assign auto_out_0_a_bits_user_reqSource = bank_out[0].out_a_bits_user_reqSource;
  assign auto_out_0_a_bits_user_alias = bank_out[0].out_a_bits_user_alias;
  assign auto_out_0_a_bits_user_vaddr = bank_out[0].out_a_bits_user_vaddr;
  assign auto_out_0_a_bits_user_needHint = bank_out[0].out_a_bits_user_needHint;
  assign auto_out_0_a_bits_echo_isKeyword = bank_out[0].out_a_bits_echo_isKeyword;
  assign auto_out_0_a_bits_corrupt = bank_out[0].out_a_bits_corrupt;
  assign auto_out_0_b_ready = bank_out[0].out_b_ready;
  assign auto_out_0_c_valid = bank_out[0].out_c_valid;
  assign auto_out_0_c_bits_opcode = bank_out[0].out_c_bits_opcode;
  assign auto_out_0_c_bits_param = bank_out[0].out_c_bits_param;
  assign auto_out_0_c_bits_size = bank_out[0].out_c_bits_size;
  assign auto_out_0_c_bits_source = bank_out[0].out_c_bits_source;
  assign auto_out_0_c_bits_address = bank_out[0].out_c_bits_address;
  assign auto_out_0_c_bits_data = bank_out[0].out_c_bits_data;
  assign auto_out_0_c_bits_corrupt = bank_out[0].out_c_bits_corrupt;
  assign auto_out_0_d_ready = bank_out[0].out_d_ready;
  assign auto_out_0_e_valid = bank_out[0].out_e_valid;
  assign auto_out_0_e_bits_sink = bank_out[0].out_e_bits_sink;
  assign auto_in_1_a_ready = bank_out[1].in_a_ready;
  assign auto_in_1_b_valid = bank_out[1].in_b_valid;
  assign auto_in_1_b_bits_opcode = bank_out[1].in_b_bits_opcode;
  assign auto_in_1_b_bits_param = bank_out[1].in_b_bits_param;
  assign auto_in_1_b_bits_size = bank_out[1].in_b_bits_size;
  assign auto_in_1_b_bits_source = bank_out[1].in_b_bits_source;
  assign auto_in_1_b_bits_address = bank_out[1].in_b_bits_address;
  assign auto_in_1_b_bits_mask = bank_out[1].in_b_bits_mask;
  assign auto_in_1_b_bits_data = bank_out[1].in_b_bits_data;
  assign auto_in_1_b_bits_corrupt = bank_out[1].in_b_bits_corrupt;
  assign auto_in_1_c_ready = bank_out[1].in_c_ready;
  assign auto_in_1_d_valid = bank_out[1].in_d_valid;
  assign auto_in_1_d_bits_opcode = bank_out[1].in_d_bits_opcode;
  assign auto_in_1_d_bits_param = bank_out[1].in_d_bits_param;
  assign auto_in_1_d_bits_size = bank_out[1].in_d_bits_size;
  assign auto_in_1_d_bits_source = bank_out[1].in_d_bits_source;
  assign auto_in_1_d_bits_sink = bank_out[1].in_d_bits_sink;
  assign auto_in_1_d_bits_denied = bank_out[1].in_d_bits_denied;
  assign auto_in_1_d_bits_echo_isKeyword = bank_out[1].in_d_bits_echo_isKeyword;
  assign auto_in_1_d_bits_data = bank_out[1].in_d_bits_data;
  assign auto_in_1_d_bits_corrupt = bank_out[1].in_d_bits_corrupt;
  assign auto_in_1_e_ready = bank_out[1].in_e_ready;
  assign auto_out_1_a_valid = bank_out[1].out_a_valid;
  assign auto_out_1_a_bits_opcode = bank_out[1].out_a_bits_opcode;
  assign auto_out_1_a_bits_param = bank_out[1].out_a_bits_param;
  assign auto_out_1_a_bits_size = bank_out[1].out_a_bits_size;
  assign auto_out_1_a_bits_source = bank_out[1].out_a_bits_source;
  assign auto_out_1_a_bits_address = bank_out[1].out_a_bits_address;
  assign auto_out_1_a_bits_user_reqSource = bank_out[1].out_a_bits_user_reqSource;
  assign auto_out_1_a_bits_user_alias = bank_out[1].out_a_bits_user_alias;
  assign auto_out_1_a_bits_user_vaddr = bank_out[1].out_a_bits_user_vaddr;
  assign auto_out_1_a_bits_user_needHint = bank_out[1].out_a_bits_user_needHint;
  assign auto_out_1_a_bits_echo_isKeyword = bank_out[1].out_a_bits_echo_isKeyword;
  assign auto_out_1_a_bits_corrupt = bank_out[1].out_a_bits_corrupt;
  assign auto_out_1_b_ready = bank_out[1].out_b_ready;
  assign auto_out_1_c_valid = bank_out[1].out_c_valid;
  assign auto_out_1_c_bits_opcode = bank_out[1].out_c_bits_opcode;
  assign auto_out_1_c_bits_param = bank_out[1].out_c_bits_param;
  assign auto_out_1_c_bits_size = bank_out[1].out_c_bits_size;
  assign auto_out_1_c_bits_source = bank_out[1].out_c_bits_source;
  assign auto_out_1_c_bits_address = bank_out[1].out_c_bits_address;
  assign auto_out_1_c_bits_data = bank_out[1].out_c_bits_data;
  assign auto_out_1_c_bits_corrupt = bank_out[1].out_c_bits_corrupt;
  assign auto_out_1_d_ready = bank_out[1].out_d_ready;
  assign auto_out_1_e_valid = bank_out[1].out_e_valid;
  assign auto_out_1_e_bits_sink = bank_out[1].out_e_bits_sink;
  assign auto_in_2_a_ready = bank_out[2].in_a_ready;
  assign auto_in_2_b_valid = bank_out[2].in_b_valid;
  assign auto_in_2_b_bits_opcode = bank_out[2].in_b_bits_opcode;
  assign auto_in_2_b_bits_param = bank_out[2].in_b_bits_param;
  assign auto_in_2_b_bits_size = bank_out[2].in_b_bits_size;
  assign auto_in_2_b_bits_source = bank_out[2].in_b_bits_source;
  assign auto_in_2_b_bits_address = bank_out[2].in_b_bits_address;
  assign auto_in_2_b_bits_mask = bank_out[2].in_b_bits_mask;
  assign auto_in_2_b_bits_data = bank_out[2].in_b_bits_data;
  assign auto_in_2_b_bits_corrupt = bank_out[2].in_b_bits_corrupt;
  assign auto_in_2_c_ready = bank_out[2].in_c_ready;
  assign auto_in_2_d_valid = bank_out[2].in_d_valid;
  assign auto_in_2_d_bits_opcode = bank_out[2].in_d_bits_opcode;
  assign auto_in_2_d_bits_param = bank_out[2].in_d_bits_param;
  assign auto_in_2_d_bits_size = bank_out[2].in_d_bits_size;
  assign auto_in_2_d_bits_source = bank_out[2].in_d_bits_source;
  assign auto_in_2_d_bits_sink = bank_out[2].in_d_bits_sink;
  assign auto_in_2_d_bits_denied = bank_out[2].in_d_bits_denied;
  assign auto_in_2_d_bits_echo_isKeyword = bank_out[2].in_d_bits_echo_isKeyword;
  assign auto_in_2_d_bits_data = bank_out[2].in_d_bits_data;
  assign auto_in_2_d_bits_corrupt = bank_out[2].in_d_bits_corrupt;
  assign auto_in_2_e_ready = bank_out[2].in_e_ready;
  assign auto_out_2_a_valid = bank_out[2].out_a_valid;
  assign auto_out_2_a_bits_opcode = bank_out[2].out_a_bits_opcode;
  assign auto_out_2_a_bits_param = bank_out[2].out_a_bits_param;
  assign auto_out_2_a_bits_size = bank_out[2].out_a_bits_size;
  assign auto_out_2_a_bits_source = bank_out[2].out_a_bits_source;
  assign auto_out_2_a_bits_address = bank_out[2].out_a_bits_address;
  assign auto_out_2_a_bits_user_reqSource = bank_out[2].out_a_bits_user_reqSource;
  assign auto_out_2_a_bits_user_alias = bank_out[2].out_a_bits_user_alias;
  assign auto_out_2_a_bits_user_vaddr = bank_out[2].out_a_bits_user_vaddr;
  assign auto_out_2_a_bits_user_needHint = bank_out[2].out_a_bits_user_needHint;
  assign auto_out_2_a_bits_echo_isKeyword = bank_out[2].out_a_bits_echo_isKeyword;
  assign auto_out_2_a_bits_corrupt = bank_out[2].out_a_bits_corrupt;
  assign auto_out_2_b_ready = bank_out[2].out_b_ready;
  assign auto_out_2_c_valid = bank_out[2].out_c_valid;
  assign auto_out_2_c_bits_opcode = bank_out[2].out_c_bits_opcode;
  assign auto_out_2_c_bits_param = bank_out[2].out_c_bits_param;
  assign auto_out_2_c_bits_size = bank_out[2].out_c_bits_size;
  assign auto_out_2_c_bits_source = bank_out[2].out_c_bits_source;
  assign auto_out_2_c_bits_address = bank_out[2].out_c_bits_address;
  assign auto_out_2_c_bits_data = bank_out[2].out_c_bits_data;
  assign auto_out_2_c_bits_corrupt = bank_out[2].out_c_bits_corrupt;
  assign auto_out_2_d_ready = bank_out[2].out_d_ready;
  assign auto_out_2_e_valid = bank_out[2].out_e_valid;
  assign auto_out_2_e_bits_sink = bank_out[2].out_e_bits_sink;
  assign auto_in_3_a_ready = bank_out[3].in_a_ready;
  assign auto_in_3_b_valid = bank_out[3].in_b_valid;
  assign auto_in_3_b_bits_opcode = bank_out[3].in_b_bits_opcode;
  assign auto_in_3_b_bits_param = bank_out[3].in_b_bits_param;
  assign auto_in_3_b_bits_size = bank_out[3].in_b_bits_size;
  assign auto_in_3_b_bits_source = bank_out[3].in_b_bits_source;
  assign auto_in_3_b_bits_address = bank_out[3].in_b_bits_address;
  assign auto_in_3_b_bits_mask = bank_out[3].in_b_bits_mask;
  assign auto_in_3_b_bits_data = bank_out[3].in_b_bits_data;
  assign auto_in_3_b_bits_corrupt = bank_out[3].in_b_bits_corrupt;
  assign auto_in_3_c_ready = bank_out[3].in_c_ready;
  assign auto_in_3_d_valid = bank_out[3].in_d_valid;
  assign auto_in_3_d_bits_opcode = bank_out[3].in_d_bits_opcode;
  assign auto_in_3_d_bits_param = bank_out[3].in_d_bits_param;
  assign auto_in_3_d_bits_size = bank_out[3].in_d_bits_size;
  assign auto_in_3_d_bits_source = bank_out[3].in_d_bits_source;
  assign auto_in_3_d_bits_sink = bank_out[3].in_d_bits_sink;
  assign auto_in_3_d_bits_denied = bank_out[3].in_d_bits_denied;
  assign auto_in_3_d_bits_echo_isKeyword = bank_out[3].in_d_bits_echo_isKeyword;
  assign auto_in_3_d_bits_data = bank_out[3].in_d_bits_data;
  assign auto_in_3_d_bits_corrupt = bank_out[3].in_d_bits_corrupt;
  assign auto_in_3_e_ready = bank_out[3].in_e_ready;
  assign auto_out_3_a_valid = bank_out[3].out_a_valid;
  assign auto_out_3_a_bits_opcode = bank_out[3].out_a_bits_opcode;
  assign auto_out_3_a_bits_param = bank_out[3].out_a_bits_param;
  assign auto_out_3_a_bits_size = bank_out[3].out_a_bits_size;
  assign auto_out_3_a_bits_source = bank_out[3].out_a_bits_source;
  assign auto_out_3_a_bits_address = bank_out[3].out_a_bits_address;
  assign auto_out_3_a_bits_user_reqSource = bank_out[3].out_a_bits_user_reqSource;
  assign auto_out_3_a_bits_user_alias = bank_out[3].out_a_bits_user_alias;
  assign auto_out_3_a_bits_user_vaddr = bank_out[3].out_a_bits_user_vaddr;
  assign auto_out_3_a_bits_user_needHint = bank_out[3].out_a_bits_user_needHint;
  assign auto_out_3_a_bits_echo_isKeyword = bank_out[3].out_a_bits_echo_isKeyword;
  assign auto_out_3_a_bits_corrupt = bank_out[3].out_a_bits_corrupt;
  assign auto_out_3_b_ready = bank_out[3].out_b_ready;
  assign auto_out_3_c_valid = bank_out[3].out_c_valid;
  assign auto_out_3_c_bits_opcode = bank_out[3].out_c_bits_opcode;
  assign auto_out_3_c_bits_param = bank_out[3].out_c_bits_param;
  assign auto_out_3_c_bits_size = bank_out[3].out_c_bits_size;
  assign auto_out_3_c_bits_source = bank_out[3].out_c_bits_source;
  assign auto_out_3_c_bits_address = bank_out[3].out_c_bits_address;
  assign auto_out_3_c_bits_data = bank_out[3].out_c_bits_data;
  assign auto_out_3_c_bits_corrupt = bank_out[3].out_c_bits_corrupt;
  assign auto_out_3_d_ready = bank_out[3].out_d_ready;
  assign auto_out_3_e_valid = bank_out[3].out_e_valid;
  assign auto_out_3_e_bits_sink = bank_out[3].out_e_bits_sink;

endmodule
