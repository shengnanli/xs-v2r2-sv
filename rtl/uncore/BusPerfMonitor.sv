// BusPerfMonitor.sv —— L1→L2 TileLink 总线上的性能监视节点（综合配置下是一段直连线）
//
// 位置：XSTile 里 DCache / ICache / PTW 三个 TileLink 主设备汇入 L2 之前各过本节点的一个口
//   （src/main/scala/top/BusPerfMonitor.scala，`out <> in`）。Scala 里它另外按通道与 opcode 统计握手次数、
//   阻塞拍数和请求-应答延迟，全是 XSPerfAccumulate / XSPerfHistogram；G1 golden 是综合配置，这些计数
//   不落地，golden 体里只留下一批没人读的握手线，对端口没有任何影响。
// 所以本模块没有状态、没有逻辑：97 个 output 各自直连对侧同名 input（A/C/E 由 in 到 out，B/D 由 out 到 in，
//   valid/bits 与 ready 方向相反）。无时钟、无复位。
// golden 625 行 / 194 端口；本文件由 scripts/gen_busperfmonitor.py 从 golden 端口表生成（勿手改）。

module BusPerfMonitor (
  output logic auto_in_2_a_ready,
  input  logic auto_in_2_a_valid,
  input  logic [3:0] auto_in_2_a_bits_opcode,
  input  logic [2:0] auto_in_2_a_bits_param,
  input  logic [2:0] auto_in_2_a_bits_size,
  input  logic [3:0] auto_in_2_a_bits_source,
  input  logic [47:0] auto_in_2_a_bits_address,
  input  logic [4:0] auto_in_2_a_bits_user_reqSource,
  input  logic [31:0] auto_in_2_a_bits_mask,
  input  logic [255:0] auto_in_2_a_bits_data,
  input  logic auto_in_2_a_bits_corrupt,
  input  logic auto_in_2_d_ready,
  output logic auto_in_2_d_valid,
  output logic [3:0] auto_in_2_d_bits_opcode,
  output logic [1:0] auto_in_2_d_bits_param,
  output logic [2:0] auto_in_2_d_bits_size,
  output logic [3:0] auto_in_2_d_bits_source,
  output logic [9:0] auto_in_2_d_bits_sink,
  output logic auto_in_2_d_bits_denied,
  output logic [255:0] auto_in_2_d_bits_data,
  output logic auto_in_2_d_bits_corrupt,
  output logic auto_in_1_a_ready,
  input  logic auto_in_1_a_valid,
  input  logic [3:0] auto_in_1_a_bits_opcode,
  input  logic [2:0] auto_in_1_a_bits_param,
  input  logic [2:0] auto_in_1_a_bits_size,
  input  logic [3:0] auto_in_1_a_bits_source,
  input  logic [47:0] auto_in_1_a_bits_address,
  input  logic [1:0] auto_in_1_a_bits_user_alias,
  input  logic [4:0] auto_in_1_a_bits_user_reqSource,
  input  logic auto_in_1_a_bits_user_needHint,
  input  logic [31:0] auto_in_1_a_bits_mask,
  input  logic [255:0] auto_in_1_a_bits_data,
  input  logic auto_in_1_a_bits_corrupt,
  input  logic auto_in_1_d_ready,
  output logic auto_in_1_d_valid,
  output logic [3:0] auto_in_1_d_bits_opcode,
  output logic [1:0] auto_in_1_d_bits_param,
  output logic [2:0] auto_in_1_d_bits_size,
  output logic [3:0] auto_in_1_d_bits_source,
  output logic [9:0] auto_in_1_d_bits_sink,
  output logic auto_in_1_d_bits_denied,
  output logic [255:0] auto_in_1_d_bits_data,
  output logic auto_in_1_d_bits_corrupt,
  output logic auto_in_0_a_ready,
  input  logic auto_in_0_a_valid,
  input  logic [3:0] auto_in_0_a_bits_opcode,
  input  logic [2:0] auto_in_0_a_bits_param,
  input  logic [2:0] auto_in_0_a_bits_size,
  input  logic [5:0] auto_in_0_a_bits_source,
  input  logic [47:0] auto_in_0_a_bits_address,
  input  logic [1:0] auto_in_0_a_bits_user_alias,
  input  logic [43:0] auto_in_0_a_bits_user_vaddr,
  input  logic [4:0] auto_in_0_a_bits_user_reqSource,
  input  logic auto_in_0_a_bits_user_needHint,
  input  logic auto_in_0_a_bits_echo_isKeyword,
  input  logic [31:0] auto_in_0_a_bits_mask,
  input  logic [255:0] auto_in_0_a_bits_data,
  input  logic auto_in_0_a_bits_corrupt,
  input  logic auto_in_0_b_ready,
  output logic auto_in_0_b_valid,
  output logic [2:0] auto_in_0_b_bits_opcode,
  output logic [1:0] auto_in_0_b_bits_param,
  output logic [2:0] auto_in_0_b_bits_size,
  output logic [5:0] auto_in_0_b_bits_source,
  output logic [47:0] auto_in_0_b_bits_address,
  output logic [31:0] auto_in_0_b_bits_mask,
  output logic [255:0] auto_in_0_b_bits_data,
  output logic auto_in_0_b_bits_corrupt,
  output logic auto_in_0_c_ready,
  input  logic auto_in_0_c_valid,
  input  logic [2:0] auto_in_0_c_bits_opcode,
  input  logic [2:0] auto_in_0_c_bits_param,
  input  logic [2:0] auto_in_0_c_bits_size,
  input  logic [5:0] auto_in_0_c_bits_source,
  input  logic [47:0] auto_in_0_c_bits_address,
  input  logic [1:0] auto_in_0_c_bits_user_alias,
  input  logic [43:0] auto_in_0_c_bits_user_vaddr,
  input  logic [4:0] auto_in_0_c_bits_user_reqSource,
  input  logic auto_in_0_c_bits_user_needHint,
  input  logic auto_in_0_c_bits_echo_isKeyword,
  input  logic [255:0] auto_in_0_c_bits_data,
  input  logic auto_in_0_c_bits_corrupt,
  input  logic auto_in_0_d_ready,
  output logic auto_in_0_d_valid,
  output logic [3:0] auto_in_0_d_bits_opcode,
  output logic [1:0] auto_in_0_d_bits_param,
  output logic [2:0] auto_in_0_d_bits_size,
  output logic [5:0] auto_in_0_d_bits_source,
  output logic [9:0] auto_in_0_d_bits_sink,
  output logic auto_in_0_d_bits_denied,
  output logic auto_in_0_d_bits_echo_isKeyword,
  output logic [255:0] auto_in_0_d_bits_data,
  output logic auto_in_0_d_bits_corrupt,
  output logic auto_in_0_e_ready,
  input  logic auto_in_0_e_valid,
  input  logic [9:0] auto_in_0_e_bits_sink,
  input  logic auto_out_2_a_ready,
  output logic auto_out_2_a_valid,
  output logic [3:0] auto_out_2_a_bits_opcode,
  output logic [2:0] auto_out_2_a_bits_param,
  output logic [2:0] auto_out_2_a_bits_size,
  output logic [3:0] auto_out_2_a_bits_source,
  output logic [47:0] auto_out_2_a_bits_address,
  output logic [4:0] auto_out_2_a_bits_user_reqSource,
  output logic [31:0] auto_out_2_a_bits_mask,
  output logic [255:0] auto_out_2_a_bits_data,
  output logic auto_out_2_a_bits_corrupt,
  output logic auto_out_2_d_ready,
  input  logic auto_out_2_d_valid,
  input  logic [3:0] auto_out_2_d_bits_opcode,
  input  logic [1:0] auto_out_2_d_bits_param,
  input  logic [2:0] auto_out_2_d_bits_size,
  input  logic [3:0] auto_out_2_d_bits_source,
  input  logic [9:0] auto_out_2_d_bits_sink,
  input  logic auto_out_2_d_bits_denied,
  input  logic [255:0] auto_out_2_d_bits_data,
  input  logic auto_out_2_d_bits_corrupt,
  input  logic auto_out_1_a_ready,
  output logic auto_out_1_a_valid,
  output logic [3:0] auto_out_1_a_bits_opcode,
  output logic [2:0] auto_out_1_a_bits_param,
  output logic [2:0] auto_out_1_a_bits_size,
  output logic [3:0] auto_out_1_a_bits_source,
  output logic [47:0] auto_out_1_a_bits_address,
  output logic [1:0] auto_out_1_a_bits_user_alias,
  output logic [4:0] auto_out_1_a_bits_user_reqSource,
  output logic auto_out_1_a_bits_user_needHint,
  output logic [31:0] auto_out_1_a_bits_mask,
  output logic [255:0] auto_out_1_a_bits_data,
  output logic auto_out_1_a_bits_corrupt,
  output logic auto_out_1_d_ready,
  input  logic auto_out_1_d_valid,
  input  logic [3:0] auto_out_1_d_bits_opcode,
  input  logic [1:0] auto_out_1_d_bits_param,
  input  logic [2:0] auto_out_1_d_bits_size,
  input  logic [3:0] auto_out_1_d_bits_source,
  input  logic [9:0] auto_out_1_d_bits_sink,
  input  logic auto_out_1_d_bits_denied,
  input  logic [255:0] auto_out_1_d_bits_data,
  input  logic auto_out_1_d_bits_corrupt,
  input  logic auto_out_0_a_ready,
  output logic auto_out_0_a_valid,
  output logic [3:0] auto_out_0_a_bits_opcode,
  output logic [2:0] auto_out_0_a_bits_param,
  output logic [2:0] auto_out_0_a_bits_size,
  output logic [5:0] auto_out_0_a_bits_source,
  output logic [47:0] auto_out_0_a_bits_address,
  output logic [1:0] auto_out_0_a_bits_user_alias,
  output logic [43:0] auto_out_0_a_bits_user_vaddr,
  output logic [4:0] auto_out_0_a_bits_user_reqSource,
  output logic auto_out_0_a_bits_user_needHint,
  output logic auto_out_0_a_bits_echo_isKeyword,
  output logic [31:0] auto_out_0_a_bits_mask,
  output logic [255:0] auto_out_0_a_bits_data,
  output logic auto_out_0_a_bits_corrupt,
  output logic auto_out_0_b_ready,
  input  logic auto_out_0_b_valid,
  input  logic [2:0] auto_out_0_b_bits_opcode,
  input  logic [1:0] auto_out_0_b_bits_param,
  input  logic [2:0] auto_out_0_b_bits_size,
  input  logic [5:0] auto_out_0_b_bits_source,
  input  logic [47:0] auto_out_0_b_bits_address,
  input  logic [31:0] auto_out_0_b_bits_mask,
  input  logic [255:0] auto_out_0_b_bits_data,
  input  logic auto_out_0_b_bits_corrupt,
  input  logic auto_out_0_c_ready,
  output logic auto_out_0_c_valid,
  output logic [2:0] auto_out_0_c_bits_opcode,
  output logic [2:0] auto_out_0_c_bits_param,
  output logic [2:0] auto_out_0_c_bits_size,
  output logic [5:0] auto_out_0_c_bits_source,
  output logic [47:0] auto_out_0_c_bits_address,
  output logic [1:0] auto_out_0_c_bits_user_alias,
  output logic [43:0] auto_out_0_c_bits_user_vaddr,
  output logic [4:0] auto_out_0_c_bits_user_reqSource,
  output logic auto_out_0_c_bits_user_needHint,
  output logic auto_out_0_c_bits_echo_isKeyword,
  output logic [255:0] auto_out_0_c_bits_data,
  output logic auto_out_0_c_bits_corrupt,
  output logic auto_out_0_d_ready,
  input  logic auto_out_0_d_valid,
  input  logic [3:0] auto_out_0_d_bits_opcode,
  input  logic [1:0] auto_out_0_d_bits_param,
  input  logic [2:0] auto_out_0_d_bits_size,
  input  logic [5:0] auto_out_0_d_bits_source,
  input  logic [9:0] auto_out_0_d_bits_sink,
  input  logic auto_out_0_d_bits_denied,
  input  logic auto_out_0_d_bits_echo_isKeyword,
  input  logic [255:0] auto_out_0_d_bits_data,
  input  logic auto_out_0_d_bits_corrupt,
  input  logic auto_out_0_e_ready,
  output logic auto_out_0_e_valid,
  output logic [9:0] auto_out_0_e_bits_sink
);

  // ===== 口 0：DCache（TL-C：A/B/C/D/E 五通道，带 alias/vaddr/needHint/isKeyword） =====
  // ---- A 请求  in -> out ----
  assign auto_in_0_a_ready                = auto_out_0_a_ready;
  assign auto_out_0_a_valid               = auto_in_0_a_valid;
  assign auto_out_0_a_bits_opcode         = auto_in_0_a_bits_opcode;
  assign auto_out_0_a_bits_param          = auto_in_0_a_bits_param;
  assign auto_out_0_a_bits_size           = auto_in_0_a_bits_size;
  assign auto_out_0_a_bits_source         = auto_in_0_a_bits_source;
  assign auto_out_0_a_bits_address        = auto_in_0_a_bits_address;
  assign auto_out_0_a_bits_user_alias     = auto_in_0_a_bits_user_alias;
  assign auto_out_0_a_bits_user_vaddr     = auto_in_0_a_bits_user_vaddr;
  assign auto_out_0_a_bits_user_reqSource = auto_in_0_a_bits_user_reqSource;
  assign auto_out_0_a_bits_user_needHint  = auto_in_0_a_bits_user_needHint;
  assign auto_out_0_a_bits_echo_isKeyword = auto_in_0_a_bits_echo_isKeyword;
  assign auto_out_0_a_bits_mask           = auto_in_0_a_bits_mask;
  assign auto_out_0_a_bits_data           = auto_in_0_a_bits_data;
  assign auto_out_0_a_bits_corrupt        = auto_in_0_a_bits_corrupt;
  // ---- B 探测  out -> in ----
  assign auto_in_0_b_valid        = auto_out_0_b_valid;
  assign auto_in_0_b_bits_opcode  = auto_out_0_b_bits_opcode;
  assign auto_in_0_b_bits_param   = auto_out_0_b_bits_param;
  assign auto_in_0_b_bits_size    = auto_out_0_b_bits_size;
  assign auto_in_0_b_bits_source  = auto_out_0_b_bits_source;
  assign auto_in_0_b_bits_address = auto_out_0_b_bits_address;
  assign auto_in_0_b_bits_mask    = auto_out_0_b_bits_mask;
  assign auto_in_0_b_bits_data    = auto_out_0_b_bits_data;
  assign auto_in_0_b_bits_corrupt = auto_out_0_b_bits_corrupt;
  assign auto_out_0_b_ready       = auto_in_0_b_ready;
  // ---- C 释放  in -> out ----
  assign auto_in_0_c_ready                = auto_out_0_c_ready;
  assign auto_out_0_c_valid               = auto_in_0_c_valid;
  assign auto_out_0_c_bits_opcode         = auto_in_0_c_bits_opcode;
  assign auto_out_0_c_bits_param          = auto_in_0_c_bits_param;
  assign auto_out_0_c_bits_size           = auto_in_0_c_bits_size;
  assign auto_out_0_c_bits_source         = auto_in_0_c_bits_source;
  assign auto_out_0_c_bits_address        = auto_in_0_c_bits_address;
  assign auto_out_0_c_bits_user_alias     = auto_in_0_c_bits_user_alias;
  assign auto_out_0_c_bits_user_vaddr     = auto_in_0_c_bits_user_vaddr;
  assign auto_out_0_c_bits_user_reqSource = auto_in_0_c_bits_user_reqSource;
  assign auto_out_0_c_bits_user_needHint  = auto_in_0_c_bits_user_needHint;
  assign auto_out_0_c_bits_echo_isKeyword = auto_in_0_c_bits_echo_isKeyword;
  assign auto_out_0_c_bits_data           = auto_in_0_c_bits_data;
  assign auto_out_0_c_bits_corrupt        = auto_in_0_c_bits_corrupt;
  // ---- D 应答  out -> in ----
  assign auto_in_0_d_valid               = auto_out_0_d_valid;
  assign auto_in_0_d_bits_opcode         = auto_out_0_d_bits_opcode;
  assign auto_in_0_d_bits_param          = auto_out_0_d_bits_param;
  assign auto_in_0_d_bits_size           = auto_out_0_d_bits_size;
  assign auto_in_0_d_bits_source         = auto_out_0_d_bits_source;
  assign auto_in_0_d_bits_sink           = auto_out_0_d_bits_sink;
  assign auto_in_0_d_bits_denied         = auto_out_0_d_bits_denied;
  assign auto_in_0_d_bits_echo_isKeyword = auto_out_0_d_bits_echo_isKeyword;
  assign auto_in_0_d_bits_data           = auto_out_0_d_bits_data;
  assign auto_in_0_d_bits_corrupt        = auto_out_0_d_bits_corrupt;
  assign auto_out_0_d_ready              = auto_in_0_d_ready;
  // ---- E 确认  in -> out ----
  assign auto_in_0_e_ready      = auto_out_0_e_ready;
  assign auto_out_0_e_valid     = auto_in_0_e_valid;
  assign auto_out_0_e_bits_sink = auto_in_0_e_bits_sink;

  // ===== 口 1：ICache（TL-UH：A/D 两通道） =====
  // ---- A 请求  in -> out ----
  assign auto_in_1_a_ready                = auto_out_1_a_ready;
  assign auto_out_1_a_valid               = auto_in_1_a_valid;
  assign auto_out_1_a_bits_opcode         = auto_in_1_a_bits_opcode;
  assign auto_out_1_a_bits_param          = auto_in_1_a_bits_param;
  assign auto_out_1_a_bits_size           = auto_in_1_a_bits_size;
  assign auto_out_1_a_bits_source         = auto_in_1_a_bits_source;
  assign auto_out_1_a_bits_address        = auto_in_1_a_bits_address;
  assign auto_out_1_a_bits_user_alias     = auto_in_1_a_bits_user_alias;
  assign auto_out_1_a_bits_user_reqSource = auto_in_1_a_bits_user_reqSource;
  assign auto_out_1_a_bits_user_needHint  = auto_in_1_a_bits_user_needHint;
  assign auto_out_1_a_bits_mask           = auto_in_1_a_bits_mask;
  assign auto_out_1_a_bits_data           = auto_in_1_a_bits_data;
  assign auto_out_1_a_bits_corrupt        = auto_in_1_a_bits_corrupt;
  // ---- D 应答  out -> in ----
  assign auto_in_1_d_valid        = auto_out_1_d_valid;
  assign auto_in_1_d_bits_opcode  = auto_out_1_d_bits_opcode;
  assign auto_in_1_d_bits_param   = auto_out_1_d_bits_param;
  assign auto_in_1_d_bits_size    = auto_out_1_d_bits_size;
  assign auto_in_1_d_bits_source  = auto_out_1_d_bits_source;
  assign auto_in_1_d_bits_sink    = auto_out_1_d_bits_sink;
  assign auto_in_1_d_bits_denied  = auto_out_1_d_bits_denied;
  assign auto_in_1_d_bits_data    = auto_out_1_d_bits_data;
  assign auto_in_1_d_bits_corrupt = auto_out_1_d_bits_corrupt;
  assign auto_out_1_d_ready       = auto_in_1_d_ready;

  // ===== 口 2：PTW（L2TLB 的访存口，TL-UH：A/D 两通道） =====
  // ---- A 请求  in -> out ----
  assign auto_in_2_a_ready                = auto_out_2_a_ready;
  assign auto_out_2_a_valid               = auto_in_2_a_valid;
  assign auto_out_2_a_bits_opcode         = auto_in_2_a_bits_opcode;
  assign auto_out_2_a_bits_param          = auto_in_2_a_bits_param;
  assign auto_out_2_a_bits_size           = auto_in_2_a_bits_size;
  assign auto_out_2_a_bits_source         = auto_in_2_a_bits_source;
  assign auto_out_2_a_bits_address        = auto_in_2_a_bits_address;
  assign auto_out_2_a_bits_user_reqSource = auto_in_2_a_bits_user_reqSource;
  assign auto_out_2_a_bits_mask           = auto_in_2_a_bits_mask;
  assign auto_out_2_a_bits_data           = auto_in_2_a_bits_data;
  assign auto_out_2_a_bits_corrupt        = auto_in_2_a_bits_corrupt;
  // ---- D 应答  out -> in ----
  assign auto_in_2_d_valid        = auto_out_2_d_valid;
  assign auto_in_2_d_bits_opcode  = auto_out_2_d_bits_opcode;
  assign auto_in_2_d_bits_param   = auto_out_2_d_bits_param;
  assign auto_in_2_d_bits_size    = auto_out_2_d_bits_size;
  assign auto_in_2_d_bits_source  = auto_out_2_d_bits_source;
  assign auto_in_2_d_bits_sink    = auto_out_2_d_bits_sink;
  assign auto_in_2_d_bits_denied  = auto_out_2_d_bits_denied;
  assign auto_in_2_d_bits_data    = auto_out_2_d_bits_data;
  assign auto_in_2_d_bits_corrupt = auto_out_2_d_bits_corrupt;
  assign auto_out_2_d_ready       = auto_in_2_d_ready;

endmodule
