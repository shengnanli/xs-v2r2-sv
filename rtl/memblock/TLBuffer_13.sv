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
// 本文件导航（共 1911 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L12    TLBuffer_13 由 4 个完全相同的 bank 组成, 每个 bank 是一条 TL-C 五通道 (A/B/C/D/E)
//   L130   xs_TLBuffer_13_bank —— TLBuffer_13 的单个 bank (TL-C 五通道 skid 缓冲)
//   L132   五通道各插一个 Queue2 (两拍 skid FIFO)
//   L366   TLBuffer_13 —— 4×bank TL-C 五通道时序缓冲 (可读重写核 xs_TLBuffer_13_core)
//   L368   golden 把 4 个相同的 bank 扁平展开 (20 个 Queue2 / 374 端口)
//   L1156  golden 同名 wrapper
//
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

// =============================================================================
//  xs_TLBuffer_13_bank —— TLBuffer_13 的单个 bank (TL-C 五通道 skid 缓冲)
// -----------------------------------------------------------------------------
//  五通道各插一个 Queue2 (两拍 skid FIFO)。enq 侧字段来自输入束 bin, deq 侧输出收集到
//  内部线 w_* 后打包进输出束 bout。各 Queue 的 enq/deq 引脚集合严格照 golden 复刻
//  (firtool 已优化掉的字段不连接)。TLBuffer_13 顶层用 genvar 例化 4 份本模块。
// =============================================================================

module xs_TLBuffer_13_bank
  import tlbuffer13_pkg::*;
(
  input              clock,
  input              reset,
  input  tl_bank_in_t  bin,
  output tl_bank_out_t bout
);

  // Queue 输出 (deq payload / enq ready) 的内部线, 最终打包进 bout。
  logic w_in_a_ready;
  logic w_out_a_valid;
  logic [3:0] w_out_a_bits_opcode;
  logic [2:0] w_out_a_bits_param;
  logic [2:0] w_out_a_bits_size;
  logic [6:0] w_out_a_bits_source;
  logic [47:0] w_out_a_bits_address;
  logic [4:0] w_out_a_bits_user_reqSource;
  logic [1:0] w_out_a_bits_user_alias;
  logic [43:0] w_out_a_bits_user_vaddr;
  logic w_out_a_bits_user_needHint;
  logic w_out_a_bits_echo_isKeyword;
  logic w_out_a_bits_corrupt;
  logic w_out_d_ready;
  logic w_in_d_valid;
  logic [3:0] w_in_d_bits_opcode;
  logic [1:0] w_in_d_bits_param;
  logic [2:0] w_in_d_bits_size;
  logic [6:0] w_in_d_bits_source;
  logic [7:0] w_in_d_bits_sink;
  logic w_in_d_bits_denied;
  logic w_in_d_bits_echo_isKeyword;
  logic [255:0] w_in_d_bits_data;
  logic w_in_d_bits_corrupt;
  logic w_out_b_ready;
  logic w_in_b_valid;
  logic [2:0] w_in_b_bits_opcode;
  logic [1:0] w_in_b_bits_param;
  logic [2:0] w_in_b_bits_size;
  logic [6:0] w_in_b_bits_source;
  logic [47:0] w_in_b_bits_address;
  logic [31:0] w_in_b_bits_mask;
  logic [255:0] w_in_b_bits_data;
  logic w_in_b_bits_corrupt;
  logic w_in_c_ready;
  logic w_out_c_valid;
  logic [2:0] w_out_c_bits_opcode;
  logic [2:0] w_out_c_bits_param;
  logic [2:0] w_out_c_bits_size;
  logic [6:0] w_out_c_bits_source;
  logic [47:0] w_out_c_bits_address;
  logic [255:0] w_out_c_bits_data;
  logic w_out_c_bits_corrupt;
  logic w_in_e_ready;
  logic w_out_e_valid;
  logic [7:0] w_out_e_bits_sink;

  // A (Acquire/Get/Put) client->manager 请求
  Queue2_TLBundleA_19 nodeOut_a_q (
    .clock                      (clock),
    .reset                      (reset),
    .io_enq_ready               (w_in_a_ready),
    .io_enq_valid               (bin.in_a_valid),
    .io_enq_bits_opcode         (bin.in_a_bits_opcode),
    .io_enq_bits_param          (bin.in_a_bits_param),
    .io_enq_bits_size           (bin.in_a_bits_size),
    .io_enq_bits_source         (bin.in_a_bits_source),
    .io_enq_bits_address        (bin.in_a_bits_address),
    .io_enq_bits_user_reqSource (bin.in_a_bits_user_reqSource),
    .io_enq_bits_user_alias     (bin.in_a_bits_user_alias),
    .io_enq_bits_user_vaddr     (bin.in_a_bits_user_vaddr),
    .io_enq_bits_user_needHint  (bin.in_a_bits_user_needHint),
    .io_enq_bits_echo_isKeyword (bin.in_a_bits_echo_isKeyword),
    .io_enq_bits_mask           (bin.in_a_bits_mask),
    .io_enq_bits_data           (bin.in_a_bits_data),
    .io_enq_bits_corrupt        (bin.in_a_bits_corrupt),
    .io_deq_ready               (bin.out_a_ready),
    .io_deq_valid               (w_out_a_valid),
    .io_deq_bits_opcode         (w_out_a_bits_opcode),
    .io_deq_bits_param          (w_out_a_bits_param),
    .io_deq_bits_size           (w_out_a_bits_size),
    .io_deq_bits_source         (w_out_a_bits_source),
    .io_deq_bits_address        (w_out_a_bits_address),
    .io_deq_bits_user_reqSource (w_out_a_bits_user_reqSource),
    .io_deq_bits_user_alias     (w_out_a_bits_user_alias),
    .io_deq_bits_user_vaddr     (w_out_a_bits_user_vaddr),
    .io_deq_bits_user_needHint  (w_out_a_bits_user_needHint),
    .io_deq_bits_echo_isKeyword (w_out_a_bits_echo_isKeyword),
    .io_deq_bits_corrupt        (w_out_a_bits_corrupt)
  );
  // D (Grant/AccessAck)  manager->client 应答
  Queue2_TLBundleD_20 nodeIn_d_q (
    .clock                      (clock),
    .reset                      (reset),
    .io_enq_ready               (w_out_d_ready),
    .io_enq_valid               (bin.out_d_valid),
    .io_enq_bits_opcode         (bin.out_d_bits_opcode),
    .io_enq_bits_param          (bin.out_d_bits_param),
    .io_enq_bits_source         (bin.out_d_bits_source),
    .io_enq_bits_sink           (bin.out_d_bits_sink),
    .io_enq_bits_denied         (bin.out_d_bits_denied),
    .io_enq_bits_echo_isKeyword (bin.out_d_bits_echo_isKeyword),
    .io_enq_bits_data           (bin.out_d_bits_data),
    .io_enq_bits_corrupt        (bin.out_d_bits_corrupt),
    .io_deq_ready               (bin.in_d_ready),
    .io_deq_valid               (w_in_d_valid),
    .io_deq_bits_opcode         (w_in_d_bits_opcode),
    .io_deq_bits_param          (w_in_d_bits_param),
    .io_deq_bits_size           (w_in_d_bits_size),
    .io_deq_bits_source         (w_in_d_bits_source),
    .io_deq_bits_sink           (w_in_d_bits_sink),
    .io_deq_bits_denied         (w_in_d_bits_denied),
    .io_deq_bits_echo_isKeyword (w_in_d_bits_echo_isKeyword),
    .io_deq_bits_data           (w_in_d_bits_data),
    .io_deq_bits_corrupt        (w_in_d_bits_corrupt)
  );
  // B (Probe)            manager->client 探测
  Queue2_TLBundleB_1 nodeIn_b_q (
    .clock               (clock),
    .reset               (reset),
    .io_enq_ready        (w_out_b_ready),
    .io_enq_valid        (bin.out_b_valid),
    .io_enq_bits_opcode  (bin.out_b_bits_opcode),
    .io_enq_bits_param   (bin.out_b_bits_param),
    .io_enq_bits_address (bin.out_b_bits_address),
    .io_enq_bits_data    (bin.out_b_bits_data),
    .io_deq_ready        (bin.in_b_ready),
    .io_deq_valid        (w_in_b_valid),
    .io_deq_bits_opcode  (w_in_b_bits_opcode),
    .io_deq_bits_param   (w_in_b_bits_param),
    .io_deq_bits_size    (w_in_b_bits_size),
    .io_deq_bits_source  (w_in_b_bits_source),
    .io_deq_bits_address (w_in_b_bits_address),
    .io_deq_bits_mask    (w_in_b_bits_mask),
    .io_deq_bits_data    (w_in_b_bits_data),
    .io_deq_bits_corrupt (w_in_b_bits_corrupt)
  );
  // C (Release/ProbeAck) client->manager 回写/降级
  Queue2_TLBundleC_1 nodeOut_c_q (
    .clock                      (clock),
    .reset                      (reset),
    .io_enq_ready               (w_in_c_ready),
    .io_enq_valid               (bin.in_c_valid),
    .io_enq_bits_opcode         (bin.in_c_bits_opcode),
    .io_enq_bits_param          (bin.in_c_bits_param),
    .io_enq_bits_size           (bin.in_c_bits_size),
    .io_enq_bits_source         (bin.in_c_bits_source),
    .io_enq_bits_address        (bin.in_c_bits_address),
    .io_enq_bits_user_reqSource (bin.in_c_bits_user_reqSource),
    .io_enq_bits_user_alias     (bin.in_c_bits_user_alias),
    .io_enq_bits_user_vaddr     (bin.in_c_bits_user_vaddr),
    .io_enq_bits_user_needHint  (bin.in_c_bits_user_needHint),
    .io_enq_bits_echo_isKeyword (bin.in_c_bits_echo_isKeyword),
    .io_enq_bits_data           (bin.in_c_bits_data),
    .io_enq_bits_corrupt        (bin.in_c_bits_corrupt),
    .io_deq_ready               (bin.out_c_ready),
    .io_deq_valid               (w_out_c_valid),
    .io_deq_bits_opcode         (w_out_c_bits_opcode),
    .io_deq_bits_param          (w_out_c_bits_param),
    .io_deq_bits_size           (w_out_c_bits_size),
    .io_deq_bits_source         (w_out_c_bits_source),
    .io_deq_bits_address        (w_out_c_bits_address),
    .io_deq_bits_data           (w_out_c_bits_data),
    .io_deq_bits_corrupt        (w_out_c_bits_corrupt)
  );
  // E (GrantAck)         client->manager 授权确认
  Queue2_TLBundleE_1 nodeOut_e_q (
    .clock            (clock),
    .reset            (reset),
    .io_enq_ready     (w_in_e_ready),
    .io_enq_valid     (bin.in_e_valid),
    .io_enq_bits_sink (bin.in_e_bits_sink),
    .io_deq_valid     (w_out_e_valid),
    .io_deq_bits_sink (w_out_e_bits_sink)
  );

  // 收集五通道输出为输出束。
  assign bout = '{
    in_a_ready: w_in_a_ready,
    in_b_valid: w_in_b_valid,
    in_b_bits_opcode: w_in_b_bits_opcode,
    in_b_bits_param: w_in_b_bits_param,
    in_b_bits_size: w_in_b_bits_size,
    in_b_bits_source: w_in_b_bits_source,
    in_b_bits_address: w_in_b_bits_address,
    in_b_bits_mask: w_in_b_bits_mask,
    in_b_bits_data: w_in_b_bits_data,
    in_b_bits_corrupt: w_in_b_bits_corrupt,
    in_c_ready: w_in_c_ready,
    in_d_valid: w_in_d_valid,
    in_d_bits_opcode: w_in_d_bits_opcode,
    in_d_bits_param: w_in_d_bits_param,
    in_d_bits_size: w_in_d_bits_size,
    in_d_bits_source: w_in_d_bits_source,
    in_d_bits_sink: w_in_d_bits_sink,
    in_d_bits_denied: w_in_d_bits_denied,
    in_d_bits_echo_isKeyword: w_in_d_bits_echo_isKeyword,
    in_d_bits_data: w_in_d_bits_data,
    in_d_bits_corrupt: w_in_d_bits_corrupt,
    in_e_ready: w_in_e_ready,
    out_a_valid: w_out_a_valid,
    out_a_bits_opcode: w_out_a_bits_opcode,
    out_a_bits_param: w_out_a_bits_param,
    out_a_bits_size: w_out_a_bits_size,
    out_a_bits_source: w_out_a_bits_source,
    out_a_bits_address: w_out_a_bits_address,
    out_a_bits_user_reqSource: w_out_a_bits_user_reqSource,
    out_a_bits_user_alias: w_out_a_bits_user_alias,
    out_a_bits_user_vaddr: w_out_a_bits_user_vaddr,
    out_a_bits_user_needHint: w_out_a_bits_user_needHint,
    out_a_bits_echo_isKeyword: w_out_a_bits_echo_isKeyword,
    out_a_bits_corrupt: w_out_a_bits_corrupt,
    out_b_ready: w_out_b_ready,
    out_c_valid: w_out_c_valid,
    out_c_bits_opcode: w_out_c_bits_opcode,
    out_c_bits_param: w_out_c_bits_param,
    out_c_bits_size: w_out_c_bits_size,
    out_c_bits_source: w_out_c_bits_source,
    out_c_bits_address: w_out_c_bits_address,
    out_c_bits_data: w_out_c_bits_data,
    out_c_bits_corrupt: w_out_c_bits_corrupt,
    out_d_ready: w_out_d_ready,
    out_e_valid: w_out_e_valid,
    out_e_bits_sink: w_out_e_bits_sink
  };

endmodule

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

// 自动生成：xs-v2r2-sv/scripts/gen_tlbuffer13.py —— 该脚本未移植到本轮(它按上一轮规范产出独立 _wrapper.sv)，本文件手工维护

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module TLBuffer_13(
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
  xs_TLBuffer_13_core u_core (
    .clock(clock),
    .reset(reset),
    .auto_in_3_a_ready(auto_in_3_a_ready),
    .auto_in_3_a_valid(auto_in_3_a_valid),
    .auto_in_3_a_bits_opcode(auto_in_3_a_bits_opcode),
    .auto_in_3_a_bits_param(auto_in_3_a_bits_param),
    .auto_in_3_a_bits_size(auto_in_3_a_bits_size),
    .auto_in_3_a_bits_source(auto_in_3_a_bits_source),
    .auto_in_3_a_bits_address(auto_in_3_a_bits_address),
    .auto_in_3_a_bits_user_reqSource(auto_in_3_a_bits_user_reqSource),
    .auto_in_3_a_bits_user_alias(auto_in_3_a_bits_user_alias),
    .auto_in_3_a_bits_user_vaddr(auto_in_3_a_bits_user_vaddr),
    .auto_in_3_a_bits_user_needHint(auto_in_3_a_bits_user_needHint),
    .auto_in_3_a_bits_echo_isKeyword(auto_in_3_a_bits_echo_isKeyword),
    .auto_in_3_a_bits_mask(auto_in_3_a_bits_mask),
    .auto_in_3_a_bits_data(auto_in_3_a_bits_data),
    .auto_in_3_a_bits_corrupt(auto_in_3_a_bits_corrupt),
    .auto_in_3_b_ready(auto_in_3_b_ready),
    .auto_in_3_b_valid(auto_in_3_b_valid),
    .auto_in_3_b_bits_opcode(auto_in_3_b_bits_opcode),
    .auto_in_3_b_bits_param(auto_in_3_b_bits_param),
    .auto_in_3_b_bits_size(auto_in_3_b_bits_size),
    .auto_in_3_b_bits_source(auto_in_3_b_bits_source),
    .auto_in_3_b_bits_address(auto_in_3_b_bits_address),
    .auto_in_3_b_bits_mask(auto_in_3_b_bits_mask),
    .auto_in_3_b_bits_data(auto_in_3_b_bits_data),
    .auto_in_3_b_bits_corrupt(auto_in_3_b_bits_corrupt),
    .auto_in_3_c_ready(auto_in_3_c_ready),
    .auto_in_3_c_valid(auto_in_3_c_valid),
    .auto_in_3_c_bits_opcode(auto_in_3_c_bits_opcode),
    .auto_in_3_c_bits_param(auto_in_3_c_bits_param),
    .auto_in_3_c_bits_size(auto_in_3_c_bits_size),
    .auto_in_3_c_bits_source(auto_in_3_c_bits_source),
    .auto_in_3_c_bits_address(auto_in_3_c_bits_address),
    .auto_in_3_c_bits_user_reqSource(auto_in_3_c_bits_user_reqSource),
    .auto_in_3_c_bits_user_alias(auto_in_3_c_bits_user_alias),
    .auto_in_3_c_bits_user_vaddr(auto_in_3_c_bits_user_vaddr),
    .auto_in_3_c_bits_user_needHint(auto_in_3_c_bits_user_needHint),
    .auto_in_3_c_bits_echo_isKeyword(auto_in_3_c_bits_echo_isKeyword),
    .auto_in_3_c_bits_data(auto_in_3_c_bits_data),
    .auto_in_3_c_bits_corrupt(auto_in_3_c_bits_corrupt),
    .auto_in_3_d_ready(auto_in_3_d_ready),
    .auto_in_3_d_valid(auto_in_3_d_valid),
    .auto_in_3_d_bits_opcode(auto_in_3_d_bits_opcode),
    .auto_in_3_d_bits_param(auto_in_3_d_bits_param),
    .auto_in_3_d_bits_size(auto_in_3_d_bits_size),
    .auto_in_3_d_bits_source(auto_in_3_d_bits_source),
    .auto_in_3_d_bits_sink(auto_in_3_d_bits_sink),
    .auto_in_3_d_bits_denied(auto_in_3_d_bits_denied),
    .auto_in_3_d_bits_echo_isKeyword(auto_in_3_d_bits_echo_isKeyword),
    .auto_in_3_d_bits_data(auto_in_3_d_bits_data),
    .auto_in_3_d_bits_corrupt(auto_in_3_d_bits_corrupt),
    .auto_in_3_e_ready(auto_in_3_e_ready),
    .auto_in_3_e_valid(auto_in_3_e_valid),
    .auto_in_3_e_bits_sink(auto_in_3_e_bits_sink),
    .auto_in_2_a_ready(auto_in_2_a_ready),
    .auto_in_2_a_valid(auto_in_2_a_valid),
    .auto_in_2_a_bits_opcode(auto_in_2_a_bits_opcode),
    .auto_in_2_a_bits_param(auto_in_2_a_bits_param),
    .auto_in_2_a_bits_size(auto_in_2_a_bits_size),
    .auto_in_2_a_bits_source(auto_in_2_a_bits_source),
    .auto_in_2_a_bits_address(auto_in_2_a_bits_address),
    .auto_in_2_a_bits_user_reqSource(auto_in_2_a_bits_user_reqSource),
    .auto_in_2_a_bits_user_alias(auto_in_2_a_bits_user_alias),
    .auto_in_2_a_bits_user_vaddr(auto_in_2_a_bits_user_vaddr),
    .auto_in_2_a_bits_user_needHint(auto_in_2_a_bits_user_needHint),
    .auto_in_2_a_bits_echo_isKeyword(auto_in_2_a_bits_echo_isKeyword),
    .auto_in_2_a_bits_mask(auto_in_2_a_bits_mask),
    .auto_in_2_a_bits_data(auto_in_2_a_bits_data),
    .auto_in_2_a_bits_corrupt(auto_in_2_a_bits_corrupt),
    .auto_in_2_b_ready(auto_in_2_b_ready),
    .auto_in_2_b_valid(auto_in_2_b_valid),
    .auto_in_2_b_bits_opcode(auto_in_2_b_bits_opcode),
    .auto_in_2_b_bits_param(auto_in_2_b_bits_param),
    .auto_in_2_b_bits_size(auto_in_2_b_bits_size),
    .auto_in_2_b_bits_source(auto_in_2_b_bits_source),
    .auto_in_2_b_bits_address(auto_in_2_b_bits_address),
    .auto_in_2_b_bits_mask(auto_in_2_b_bits_mask),
    .auto_in_2_b_bits_data(auto_in_2_b_bits_data),
    .auto_in_2_b_bits_corrupt(auto_in_2_b_bits_corrupt),
    .auto_in_2_c_ready(auto_in_2_c_ready),
    .auto_in_2_c_valid(auto_in_2_c_valid),
    .auto_in_2_c_bits_opcode(auto_in_2_c_bits_opcode),
    .auto_in_2_c_bits_param(auto_in_2_c_bits_param),
    .auto_in_2_c_bits_size(auto_in_2_c_bits_size),
    .auto_in_2_c_bits_source(auto_in_2_c_bits_source),
    .auto_in_2_c_bits_address(auto_in_2_c_bits_address),
    .auto_in_2_c_bits_user_reqSource(auto_in_2_c_bits_user_reqSource),
    .auto_in_2_c_bits_user_alias(auto_in_2_c_bits_user_alias),
    .auto_in_2_c_bits_user_vaddr(auto_in_2_c_bits_user_vaddr),
    .auto_in_2_c_bits_user_needHint(auto_in_2_c_bits_user_needHint),
    .auto_in_2_c_bits_echo_isKeyword(auto_in_2_c_bits_echo_isKeyword),
    .auto_in_2_c_bits_data(auto_in_2_c_bits_data),
    .auto_in_2_c_bits_corrupt(auto_in_2_c_bits_corrupt),
    .auto_in_2_d_ready(auto_in_2_d_ready),
    .auto_in_2_d_valid(auto_in_2_d_valid),
    .auto_in_2_d_bits_opcode(auto_in_2_d_bits_opcode),
    .auto_in_2_d_bits_param(auto_in_2_d_bits_param),
    .auto_in_2_d_bits_size(auto_in_2_d_bits_size),
    .auto_in_2_d_bits_source(auto_in_2_d_bits_source),
    .auto_in_2_d_bits_sink(auto_in_2_d_bits_sink),
    .auto_in_2_d_bits_denied(auto_in_2_d_bits_denied),
    .auto_in_2_d_bits_echo_isKeyword(auto_in_2_d_bits_echo_isKeyword),
    .auto_in_2_d_bits_data(auto_in_2_d_bits_data),
    .auto_in_2_d_bits_corrupt(auto_in_2_d_bits_corrupt),
    .auto_in_2_e_ready(auto_in_2_e_ready),
    .auto_in_2_e_valid(auto_in_2_e_valid),
    .auto_in_2_e_bits_sink(auto_in_2_e_bits_sink),
    .auto_in_1_a_ready(auto_in_1_a_ready),
    .auto_in_1_a_valid(auto_in_1_a_valid),
    .auto_in_1_a_bits_opcode(auto_in_1_a_bits_opcode),
    .auto_in_1_a_bits_param(auto_in_1_a_bits_param),
    .auto_in_1_a_bits_size(auto_in_1_a_bits_size),
    .auto_in_1_a_bits_source(auto_in_1_a_bits_source),
    .auto_in_1_a_bits_address(auto_in_1_a_bits_address),
    .auto_in_1_a_bits_user_reqSource(auto_in_1_a_bits_user_reqSource),
    .auto_in_1_a_bits_user_alias(auto_in_1_a_bits_user_alias),
    .auto_in_1_a_bits_user_vaddr(auto_in_1_a_bits_user_vaddr),
    .auto_in_1_a_bits_user_needHint(auto_in_1_a_bits_user_needHint),
    .auto_in_1_a_bits_echo_isKeyword(auto_in_1_a_bits_echo_isKeyword),
    .auto_in_1_a_bits_mask(auto_in_1_a_bits_mask),
    .auto_in_1_a_bits_data(auto_in_1_a_bits_data),
    .auto_in_1_a_bits_corrupt(auto_in_1_a_bits_corrupt),
    .auto_in_1_b_ready(auto_in_1_b_ready),
    .auto_in_1_b_valid(auto_in_1_b_valid),
    .auto_in_1_b_bits_opcode(auto_in_1_b_bits_opcode),
    .auto_in_1_b_bits_param(auto_in_1_b_bits_param),
    .auto_in_1_b_bits_size(auto_in_1_b_bits_size),
    .auto_in_1_b_bits_source(auto_in_1_b_bits_source),
    .auto_in_1_b_bits_address(auto_in_1_b_bits_address),
    .auto_in_1_b_bits_mask(auto_in_1_b_bits_mask),
    .auto_in_1_b_bits_data(auto_in_1_b_bits_data),
    .auto_in_1_b_bits_corrupt(auto_in_1_b_bits_corrupt),
    .auto_in_1_c_ready(auto_in_1_c_ready),
    .auto_in_1_c_valid(auto_in_1_c_valid),
    .auto_in_1_c_bits_opcode(auto_in_1_c_bits_opcode),
    .auto_in_1_c_bits_param(auto_in_1_c_bits_param),
    .auto_in_1_c_bits_size(auto_in_1_c_bits_size),
    .auto_in_1_c_bits_source(auto_in_1_c_bits_source),
    .auto_in_1_c_bits_address(auto_in_1_c_bits_address),
    .auto_in_1_c_bits_user_reqSource(auto_in_1_c_bits_user_reqSource),
    .auto_in_1_c_bits_user_alias(auto_in_1_c_bits_user_alias),
    .auto_in_1_c_bits_user_vaddr(auto_in_1_c_bits_user_vaddr),
    .auto_in_1_c_bits_user_needHint(auto_in_1_c_bits_user_needHint),
    .auto_in_1_c_bits_echo_isKeyword(auto_in_1_c_bits_echo_isKeyword),
    .auto_in_1_c_bits_data(auto_in_1_c_bits_data),
    .auto_in_1_c_bits_corrupt(auto_in_1_c_bits_corrupt),
    .auto_in_1_d_ready(auto_in_1_d_ready),
    .auto_in_1_d_valid(auto_in_1_d_valid),
    .auto_in_1_d_bits_opcode(auto_in_1_d_bits_opcode),
    .auto_in_1_d_bits_param(auto_in_1_d_bits_param),
    .auto_in_1_d_bits_size(auto_in_1_d_bits_size),
    .auto_in_1_d_bits_source(auto_in_1_d_bits_source),
    .auto_in_1_d_bits_sink(auto_in_1_d_bits_sink),
    .auto_in_1_d_bits_denied(auto_in_1_d_bits_denied),
    .auto_in_1_d_bits_echo_isKeyword(auto_in_1_d_bits_echo_isKeyword),
    .auto_in_1_d_bits_data(auto_in_1_d_bits_data),
    .auto_in_1_d_bits_corrupt(auto_in_1_d_bits_corrupt),
    .auto_in_1_e_ready(auto_in_1_e_ready),
    .auto_in_1_e_valid(auto_in_1_e_valid),
    .auto_in_1_e_bits_sink(auto_in_1_e_bits_sink),
    .auto_in_0_a_ready(auto_in_0_a_ready),
    .auto_in_0_a_valid(auto_in_0_a_valid),
    .auto_in_0_a_bits_opcode(auto_in_0_a_bits_opcode),
    .auto_in_0_a_bits_param(auto_in_0_a_bits_param),
    .auto_in_0_a_bits_size(auto_in_0_a_bits_size),
    .auto_in_0_a_bits_source(auto_in_0_a_bits_source),
    .auto_in_0_a_bits_address(auto_in_0_a_bits_address),
    .auto_in_0_a_bits_user_reqSource(auto_in_0_a_bits_user_reqSource),
    .auto_in_0_a_bits_user_alias(auto_in_0_a_bits_user_alias),
    .auto_in_0_a_bits_user_vaddr(auto_in_0_a_bits_user_vaddr),
    .auto_in_0_a_bits_user_needHint(auto_in_0_a_bits_user_needHint),
    .auto_in_0_a_bits_echo_isKeyword(auto_in_0_a_bits_echo_isKeyword),
    .auto_in_0_a_bits_mask(auto_in_0_a_bits_mask),
    .auto_in_0_a_bits_data(auto_in_0_a_bits_data),
    .auto_in_0_a_bits_corrupt(auto_in_0_a_bits_corrupt),
    .auto_in_0_b_ready(auto_in_0_b_ready),
    .auto_in_0_b_valid(auto_in_0_b_valid),
    .auto_in_0_b_bits_opcode(auto_in_0_b_bits_opcode),
    .auto_in_0_b_bits_param(auto_in_0_b_bits_param),
    .auto_in_0_b_bits_size(auto_in_0_b_bits_size),
    .auto_in_0_b_bits_source(auto_in_0_b_bits_source),
    .auto_in_0_b_bits_address(auto_in_0_b_bits_address),
    .auto_in_0_b_bits_mask(auto_in_0_b_bits_mask),
    .auto_in_0_b_bits_data(auto_in_0_b_bits_data),
    .auto_in_0_b_bits_corrupt(auto_in_0_b_bits_corrupt),
    .auto_in_0_c_ready(auto_in_0_c_ready),
    .auto_in_0_c_valid(auto_in_0_c_valid),
    .auto_in_0_c_bits_opcode(auto_in_0_c_bits_opcode),
    .auto_in_0_c_bits_param(auto_in_0_c_bits_param),
    .auto_in_0_c_bits_size(auto_in_0_c_bits_size),
    .auto_in_0_c_bits_source(auto_in_0_c_bits_source),
    .auto_in_0_c_bits_address(auto_in_0_c_bits_address),
    .auto_in_0_c_bits_user_reqSource(auto_in_0_c_bits_user_reqSource),
    .auto_in_0_c_bits_user_alias(auto_in_0_c_bits_user_alias),
    .auto_in_0_c_bits_user_vaddr(auto_in_0_c_bits_user_vaddr),
    .auto_in_0_c_bits_user_needHint(auto_in_0_c_bits_user_needHint),
    .auto_in_0_c_bits_echo_isKeyword(auto_in_0_c_bits_echo_isKeyword),
    .auto_in_0_c_bits_data(auto_in_0_c_bits_data),
    .auto_in_0_c_bits_corrupt(auto_in_0_c_bits_corrupt),
    .auto_in_0_d_ready(auto_in_0_d_ready),
    .auto_in_0_d_valid(auto_in_0_d_valid),
    .auto_in_0_d_bits_opcode(auto_in_0_d_bits_opcode),
    .auto_in_0_d_bits_param(auto_in_0_d_bits_param),
    .auto_in_0_d_bits_size(auto_in_0_d_bits_size),
    .auto_in_0_d_bits_source(auto_in_0_d_bits_source),
    .auto_in_0_d_bits_sink(auto_in_0_d_bits_sink),
    .auto_in_0_d_bits_denied(auto_in_0_d_bits_denied),
    .auto_in_0_d_bits_echo_isKeyword(auto_in_0_d_bits_echo_isKeyword),
    .auto_in_0_d_bits_data(auto_in_0_d_bits_data),
    .auto_in_0_d_bits_corrupt(auto_in_0_d_bits_corrupt),
    .auto_in_0_e_ready(auto_in_0_e_ready),
    .auto_in_0_e_valid(auto_in_0_e_valid),
    .auto_in_0_e_bits_sink(auto_in_0_e_bits_sink),
    .auto_out_3_a_ready(auto_out_3_a_ready),
    .auto_out_3_a_valid(auto_out_3_a_valid),
    .auto_out_3_a_bits_opcode(auto_out_3_a_bits_opcode),
    .auto_out_3_a_bits_param(auto_out_3_a_bits_param),
    .auto_out_3_a_bits_size(auto_out_3_a_bits_size),
    .auto_out_3_a_bits_source(auto_out_3_a_bits_source),
    .auto_out_3_a_bits_address(auto_out_3_a_bits_address),
    .auto_out_3_a_bits_user_reqSource(auto_out_3_a_bits_user_reqSource),
    .auto_out_3_a_bits_user_alias(auto_out_3_a_bits_user_alias),
    .auto_out_3_a_bits_user_vaddr(auto_out_3_a_bits_user_vaddr),
    .auto_out_3_a_bits_user_needHint(auto_out_3_a_bits_user_needHint),
    .auto_out_3_a_bits_echo_isKeyword(auto_out_3_a_bits_echo_isKeyword),
    .auto_out_3_a_bits_corrupt(auto_out_3_a_bits_corrupt),
    .auto_out_3_b_ready(auto_out_3_b_ready),
    .auto_out_3_b_valid(auto_out_3_b_valid),
    .auto_out_3_b_bits_opcode(auto_out_3_b_bits_opcode),
    .auto_out_3_b_bits_param(auto_out_3_b_bits_param),
    .auto_out_3_b_bits_address(auto_out_3_b_bits_address),
    .auto_out_3_b_bits_data(auto_out_3_b_bits_data),
    .auto_out_3_c_ready(auto_out_3_c_ready),
    .auto_out_3_c_valid(auto_out_3_c_valid),
    .auto_out_3_c_bits_opcode(auto_out_3_c_bits_opcode),
    .auto_out_3_c_bits_param(auto_out_3_c_bits_param),
    .auto_out_3_c_bits_size(auto_out_3_c_bits_size),
    .auto_out_3_c_bits_source(auto_out_3_c_bits_source),
    .auto_out_3_c_bits_address(auto_out_3_c_bits_address),
    .auto_out_3_c_bits_data(auto_out_3_c_bits_data),
    .auto_out_3_c_bits_corrupt(auto_out_3_c_bits_corrupt),
    .auto_out_3_d_ready(auto_out_3_d_ready),
    .auto_out_3_d_valid(auto_out_3_d_valid),
    .auto_out_3_d_bits_opcode(auto_out_3_d_bits_opcode),
    .auto_out_3_d_bits_param(auto_out_3_d_bits_param),
    .auto_out_3_d_bits_source(auto_out_3_d_bits_source),
    .auto_out_3_d_bits_sink(auto_out_3_d_bits_sink),
    .auto_out_3_d_bits_denied(auto_out_3_d_bits_denied),
    .auto_out_3_d_bits_echo_isKeyword(auto_out_3_d_bits_echo_isKeyword),
    .auto_out_3_d_bits_data(auto_out_3_d_bits_data),
    .auto_out_3_d_bits_corrupt(auto_out_3_d_bits_corrupt),
    .auto_out_3_e_valid(auto_out_3_e_valid),
    .auto_out_3_e_bits_sink(auto_out_3_e_bits_sink),
    .auto_out_2_a_ready(auto_out_2_a_ready),
    .auto_out_2_a_valid(auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode(auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_param(auto_out_2_a_bits_param),
    .auto_out_2_a_bits_size(auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source(auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address(auto_out_2_a_bits_address),
    .auto_out_2_a_bits_user_reqSource(auto_out_2_a_bits_user_reqSource),
    .auto_out_2_a_bits_user_alias(auto_out_2_a_bits_user_alias),
    .auto_out_2_a_bits_user_vaddr(auto_out_2_a_bits_user_vaddr),
    .auto_out_2_a_bits_user_needHint(auto_out_2_a_bits_user_needHint),
    .auto_out_2_a_bits_echo_isKeyword(auto_out_2_a_bits_echo_isKeyword),
    .auto_out_2_a_bits_corrupt(auto_out_2_a_bits_corrupt),
    .auto_out_2_b_ready(auto_out_2_b_ready),
    .auto_out_2_b_valid(auto_out_2_b_valid),
    .auto_out_2_b_bits_opcode(auto_out_2_b_bits_opcode),
    .auto_out_2_b_bits_param(auto_out_2_b_bits_param),
    .auto_out_2_b_bits_address(auto_out_2_b_bits_address),
    .auto_out_2_b_bits_data(auto_out_2_b_bits_data),
    .auto_out_2_c_ready(auto_out_2_c_ready),
    .auto_out_2_c_valid(auto_out_2_c_valid),
    .auto_out_2_c_bits_opcode(auto_out_2_c_bits_opcode),
    .auto_out_2_c_bits_param(auto_out_2_c_bits_param),
    .auto_out_2_c_bits_size(auto_out_2_c_bits_size),
    .auto_out_2_c_bits_source(auto_out_2_c_bits_source),
    .auto_out_2_c_bits_address(auto_out_2_c_bits_address),
    .auto_out_2_c_bits_data(auto_out_2_c_bits_data),
    .auto_out_2_c_bits_corrupt(auto_out_2_c_bits_corrupt),
    .auto_out_2_d_ready(auto_out_2_d_ready),
    .auto_out_2_d_valid(auto_out_2_d_valid),
    .auto_out_2_d_bits_opcode(auto_out_2_d_bits_opcode),
    .auto_out_2_d_bits_param(auto_out_2_d_bits_param),
    .auto_out_2_d_bits_source(auto_out_2_d_bits_source),
    .auto_out_2_d_bits_sink(auto_out_2_d_bits_sink),
    .auto_out_2_d_bits_denied(auto_out_2_d_bits_denied),
    .auto_out_2_d_bits_echo_isKeyword(auto_out_2_d_bits_echo_isKeyword),
    .auto_out_2_d_bits_data(auto_out_2_d_bits_data),
    .auto_out_2_d_bits_corrupt(auto_out_2_d_bits_corrupt),
    .auto_out_2_e_valid(auto_out_2_e_valid),
    .auto_out_2_e_bits_sink(auto_out_2_e_bits_sink),
    .auto_out_1_a_ready(auto_out_1_a_ready),
    .auto_out_1_a_valid(auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_param(auto_out_1_a_bits_param),
    .auto_out_1_a_bits_size(auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source(auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address(auto_out_1_a_bits_address),
    .auto_out_1_a_bits_user_reqSource(auto_out_1_a_bits_user_reqSource),
    .auto_out_1_a_bits_user_alias(auto_out_1_a_bits_user_alias),
    .auto_out_1_a_bits_user_vaddr(auto_out_1_a_bits_user_vaddr),
    .auto_out_1_a_bits_user_needHint(auto_out_1_a_bits_user_needHint),
    .auto_out_1_a_bits_echo_isKeyword(auto_out_1_a_bits_echo_isKeyword),
    .auto_out_1_a_bits_corrupt(auto_out_1_a_bits_corrupt),
    .auto_out_1_b_ready(auto_out_1_b_ready),
    .auto_out_1_b_valid(auto_out_1_b_valid),
    .auto_out_1_b_bits_opcode(auto_out_1_b_bits_opcode),
    .auto_out_1_b_bits_param(auto_out_1_b_bits_param),
    .auto_out_1_b_bits_address(auto_out_1_b_bits_address),
    .auto_out_1_b_bits_data(auto_out_1_b_bits_data),
    .auto_out_1_c_ready(auto_out_1_c_ready),
    .auto_out_1_c_valid(auto_out_1_c_valid),
    .auto_out_1_c_bits_opcode(auto_out_1_c_bits_opcode),
    .auto_out_1_c_bits_param(auto_out_1_c_bits_param),
    .auto_out_1_c_bits_size(auto_out_1_c_bits_size),
    .auto_out_1_c_bits_source(auto_out_1_c_bits_source),
    .auto_out_1_c_bits_address(auto_out_1_c_bits_address),
    .auto_out_1_c_bits_data(auto_out_1_c_bits_data),
    .auto_out_1_c_bits_corrupt(auto_out_1_c_bits_corrupt),
    .auto_out_1_d_ready(auto_out_1_d_ready),
    .auto_out_1_d_valid(auto_out_1_d_valid),
    .auto_out_1_d_bits_opcode(auto_out_1_d_bits_opcode),
    .auto_out_1_d_bits_param(auto_out_1_d_bits_param),
    .auto_out_1_d_bits_source(auto_out_1_d_bits_source),
    .auto_out_1_d_bits_sink(auto_out_1_d_bits_sink),
    .auto_out_1_d_bits_denied(auto_out_1_d_bits_denied),
    .auto_out_1_d_bits_echo_isKeyword(auto_out_1_d_bits_echo_isKeyword),
    .auto_out_1_d_bits_data(auto_out_1_d_bits_data),
    .auto_out_1_d_bits_corrupt(auto_out_1_d_bits_corrupt),
    .auto_out_1_e_valid(auto_out_1_e_valid),
    .auto_out_1_e_bits_sink(auto_out_1_e_bits_sink),
    .auto_out_0_a_ready(auto_out_0_a_ready),
    .auto_out_0_a_valid(auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param(auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size(auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source(auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address(auto_out_0_a_bits_address),
    .auto_out_0_a_bits_user_reqSource(auto_out_0_a_bits_user_reqSource),
    .auto_out_0_a_bits_user_alias(auto_out_0_a_bits_user_alias),
    .auto_out_0_a_bits_user_vaddr(auto_out_0_a_bits_user_vaddr),
    .auto_out_0_a_bits_user_needHint(auto_out_0_a_bits_user_needHint),
    .auto_out_0_a_bits_echo_isKeyword(auto_out_0_a_bits_echo_isKeyword),
    .auto_out_0_a_bits_corrupt(auto_out_0_a_bits_corrupt),
    .auto_out_0_b_ready(auto_out_0_b_ready),
    .auto_out_0_b_valid(auto_out_0_b_valid),
    .auto_out_0_b_bits_opcode(auto_out_0_b_bits_opcode),
    .auto_out_0_b_bits_param(auto_out_0_b_bits_param),
    .auto_out_0_b_bits_address(auto_out_0_b_bits_address),
    .auto_out_0_b_bits_data(auto_out_0_b_bits_data),
    .auto_out_0_c_ready(auto_out_0_c_ready),
    .auto_out_0_c_valid(auto_out_0_c_valid),
    .auto_out_0_c_bits_opcode(auto_out_0_c_bits_opcode),
    .auto_out_0_c_bits_param(auto_out_0_c_bits_param),
    .auto_out_0_c_bits_size(auto_out_0_c_bits_size),
    .auto_out_0_c_bits_source(auto_out_0_c_bits_source),
    .auto_out_0_c_bits_address(auto_out_0_c_bits_address),
    .auto_out_0_c_bits_data(auto_out_0_c_bits_data),
    .auto_out_0_c_bits_corrupt(auto_out_0_c_bits_corrupt),
    .auto_out_0_d_ready(auto_out_0_d_ready),
    .auto_out_0_d_valid(auto_out_0_d_valid),
    .auto_out_0_d_bits_opcode(auto_out_0_d_bits_opcode),
    .auto_out_0_d_bits_param(auto_out_0_d_bits_param),
    .auto_out_0_d_bits_source(auto_out_0_d_bits_source),
    .auto_out_0_d_bits_sink(auto_out_0_d_bits_sink),
    .auto_out_0_d_bits_denied(auto_out_0_d_bits_denied),
    .auto_out_0_d_bits_echo_isKeyword(auto_out_0_d_bits_echo_isKeyword),
    .auto_out_0_d_bits_data(auto_out_0_d_bits_data),
    .auto_out_0_d_bits_corrupt(auto_out_0_d_bits_corrupt),
    .auto_out_0_e_valid(auto_out_0_e_valid),
    .auto_out_0_e_bits_sink(auto_out_0_e_bits_sink)
  );
endmodule
