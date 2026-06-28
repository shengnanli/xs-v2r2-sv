// =============================================================================
//  tlbuffer13_pkg —— TLBuffer_13 (4×bank TL-C 五通道 skid 缓冲) 类型包
// -----------------------------------------------------------------------------
//  TLBuffer_13 由 4 个完全相同的 bank 组成, 每个 bank 是一条 TL-C 五通道 (A/B/C/D/E)
//  时序缓冲 (各通道一个 Queue2 两拍 skid FIFO)。本层不解释 opcode/param 语义, 只切断
//  ready/valid 长组合路径并保持单通道 FIFO 顺序。
//  下面两个结构体把"单个 bank"的全部扁平 I/O 聚合成入/出两束, 供外层 genvar banking
//  与 bank 子模块共用; 字段宽度/取舍严格取自 golden TLBuffer_13 端口 (firtool 优化掉的
//  字段不出现)。各通道方向:
//    A (Acquire/Get/Put) client->manager 请求
//    B (Probe)            manager->client 探测
//    C (Release/ProbeAck) client->manager 回写/降级
//    D (Grant/AccessAck)  manager->client 应答
//    E (GrantAck)         client->manager 授权确认
// =============================================================================
package tlbuffer13_pkg;
  localparam int TL_NUM_BANKS = 4;

  // 单个 bank 的"输入束": client A/C/E 的请求 + manager B/D 的应答 + 各通道反向 ready。
  typedef struct packed {
    logic in_a_valid;
    logic [3:0] in_a_bits_opcode;
    logic [2:0] in_a_bits_param;
    logic [2:0] in_a_bits_size;
    logic [6:0] in_a_bits_source;
    logic [47:0] in_a_bits_address;
    logic [4:0] in_a_bits_user_reqSource;
    logic [1:0] in_a_bits_user_alias;
    logic [43:0] in_a_bits_user_vaddr;
    logic in_a_bits_user_needHint;
    logic in_a_bits_echo_isKeyword;
    logic [31:0] in_a_bits_mask;
    logic [255:0] in_a_bits_data;
    logic in_a_bits_corrupt;
    logic in_b_ready;
    logic in_c_valid;
    logic [2:0] in_c_bits_opcode;
    logic [2:0] in_c_bits_param;
    logic [2:0] in_c_bits_size;
    logic [6:0] in_c_bits_source;
    logic [47:0] in_c_bits_address;
    logic [4:0] in_c_bits_user_reqSource;
    logic [1:0] in_c_bits_user_alias;
    logic [43:0] in_c_bits_user_vaddr;
    logic in_c_bits_user_needHint;
    logic in_c_bits_echo_isKeyword;
    logic [255:0] in_c_bits_data;
    logic in_c_bits_corrupt;
    logic in_d_ready;
    logic in_e_valid;
    logic [7:0] in_e_bits_sink;
    logic out_a_ready;
    logic out_b_valid;
    logic [2:0] out_b_bits_opcode;
    logic [1:0] out_b_bits_param;
    logic [47:0] out_b_bits_address;
    logic [255:0] out_b_bits_data;
    logic out_c_ready;
    logic out_d_valid;
    logic [3:0] out_d_bits_opcode;
    logic [1:0] out_d_bits_param;
    logic [6:0] out_d_bits_source;
    logic [7:0] out_d_bits_sink;
    logic out_d_bits_denied;
    logic out_d_bits_echo_isKeyword;
    logic [255:0] out_d_bits_data;
    logic out_d_bits_corrupt;
  } tl_bank_in_t;

  // 单个 bank 的"输出束": 缓冲后送出的各通道 valid/payload + 反向 ready。
  typedef struct packed {
    logic in_a_ready;
    logic in_b_valid;
    logic [2:0] in_b_bits_opcode;
    logic [1:0] in_b_bits_param;
    logic [2:0] in_b_bits_size;
    logic [6:0] in_b_bits_source;
    logic [47:0] in_b_bits_address;
    logic [31:0] in_b_bits_mask;
    logic [255:0] in_b_bits_data;
    logic in_b_bits_corrupt;
    logic in_c_ready;
    logic in_d_valid;
    logic [3:0] in_d_bits_opcode;
    logic [1:0] in_d_bits_param;
    logic [2:0] in_d_bits_size;
    logic [6:0] in_d_bits_source;
    logic [7:0] in_d_bits_sink;
    logic in_d_bits_denied;
    logic in_d_bits_echo_isKeyword;
    logic [255:0] in_d_bits_data;
    logic in_d_bits_corrupt;
    logic in_e_ready;
    logic out_a_valid;
    logic [3:0] out_a_bits_opcode;
    logic [2:0] out_a_bits_param;
    logic [2:0] out_a_bits_size;
    logic [6:0] out_a_bits_source;
    logic [47:0] out_a_bits_address;
    logic [4:0] out_a_bits_user_reqSource;
    logic [1:0] out_a_bits_user_alias;
    logic [43:0] out_a_bits_user_vaddr;
    logic out_a_bits_user_needHint;
    logic out_a_bits_echo_isKeyword;
    logic out_a_bits_corrupt;
    logic out_b_ready;
    logic out_c_valid;
    logic [2:0] out_c_bits_opcode;
    logic [2:0] out_c_bits_param;
    logic [2:0] out_c_bits_size;
    logic [6:0] out_c_bits_source;
    logic [47:0] out_c_bits_address;
    logic [255:0] out_c_bits_data;
    logic out_c_bits_corrupt;
    logic out_d_ready;
    logic out_e_valid;
    logic [7:0] out_e_bits_sink;
  } tl_bank_out_t;
endpackage
