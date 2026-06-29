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
