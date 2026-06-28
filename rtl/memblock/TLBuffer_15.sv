// =============================================================================
//  TLBuffer_15 —— TileLink A/D 两通道时序缓冲 (可读重写核 xs_TLBuffer_15_core)
// -----------------------------------------------------------------------------
//  A 请求 (client->manager)、D 应答 (manager->client) 各插一个 Queue2 (两拍 FIFO)。
//  本层不解码 TL opcode、不跨通道重排, 只切断 ready/valid 长组合路径并保持单通道顺序。
//  Queue2_* 是 UT/FM 两侧共用的黑盒叶子 (内含 ram_*)。
//  本变体特征: 窄总线缓冲: source 1 位、size 2 位、address 48 位、data 64 位, 无 user 字段。
// =============================================================================
module xs_TLBuffer_15_core
  import tlbuffer15_pkg::*;
(
  input clock,
  input reset,
  output auto_in_a_ready,
  input auto_in_a_valid,
  input [3:0] auto_in_a_bits_opcode,
  input [2:0] auto_in_a_bits_param,
  input [1:0] auto_in_a_bits_size,
  input auto_in_a_bits_source,
  input [47:0] auto_in_a_bits_address,
  input [7:0] auto_in_a_bits_mask,
  input [63:0] auto_in_a_bits_data,
  input auto_in_a_bits_corrupt,
  input auto_in_d_ready,
  output auto_in_d_valid,
  output [3:0] auto_in_d_bits_opcode,
  output [1:0] auto_in_d_bits_param,
  output [1:0] auto_in_d_bits_size,
  output auto_in_d_bits_source,
  output auto_in_d_bits_sink,
  output auto_in_d_bits_denied,
  output [63:0] auto_in_d_bits_data,
  output auto_in_d_bits_corrupt,
  input auto_out_a_ready,
  output auto_out_a_valid,
  output [3:0] auto_out_a_bits_opcode,
  output [2:0] auto_out_a_bits_param,
  output [1:0] auto_out_a_bits_size,
  output auto_out_a_bits_source,
  output [47:0] auto_out_a_bits_address,
  output [7:0] auto_out_a_bits_mask,
  output [63:0] auto_out_a_bits_data,
  output auto_out_a_bits_corrupt,
  output auto_out_d_ready,
  input auto_out_d_valid,
  input [3:0] auto_out_d_bits_opcode,
  input [1:0] auto_out_d_bits_param,
  input [1:0] auto_out_d_bits_size,
  input auto_out_d_bits_source,
  input auto_out_d_bits_sink,
  input auto_out_d_bits_denied,
  input [63:0] auto_out_d_bits_data,
  input auto_out_d_bits_corrupt
);

  function automatic logic hs_fire(input decoupled_hs_t hs);
    return hs.ready & hs.valid;
  endfunction

  // enq 侧 payload 聚合 (deq 侧直连输出端口)。
  tl_a_bundle_t client_a;   // client A
  tl_d_bundle_t manager_d;  // manager D

  always_comb begin
    client_a = '{opcode: auto_in_a_bits_opcode, param: auto_in_a_bits_param,
        size: auto_in_a_bits_size, source: auto_in_a_bits_source,
        address: auto_in_a_bits_address, mask: auto_in_a_bits_mask,
        data: auto_in_a_bits_data, corrupt: auto_in_a_bits_corrupt};
    manager_d = '{opcode: auto_out_d_bits_opcode, param: auto_out_d_bits_param,
        size: auto_out_d_bits_size, source: auto_out_d_bits_source,
        sink: auto_out_d_bits_sink, denied: auto_out_d_bits_denied,
        data: auto_out_d_bits_data, corrupt: auto_out_d_bits_corrupt};
  end

  // A/D 两条被缓冲路径的 enq/deq 握手 (fire = ready & valid; 队列内部自管两拍深度)。
  decoupled_hs_t enq_hs [TL_NUM_CHANNELS];
  decoupled_hs_t deq_hs [TL_NUM_CHANNELS];
  logic [TL_NUM_CHANNELS-1:0] enq_fire;
  logic [TL_NUM_CHANNELS-1:0] deq_fire;

  assign enq_hs[TL_CH_A] = '{ready: auto_in_a_ready,  valid: auto_in_a_valid};
  assign deq_hs[TL_CH_A] = '{ready: auto_out_a_ready, valid: auto_out_a_valid};
  assign enq_hs[TL_CH_D] = '{ready: auto_out_d_ready, valid: auto_out_d_valid};
  assign deq_hs[TL_CH_D] = '{ready: auto_in_d_ready,  valid: auto_in_d_valid};

  for (genvar ch = 0; ch < TL_NUM_CHANNELS; ch++) begin : g_fire
    assign enq_fire[ch] = hs_fire(enq_hs[ch]);
    assign deq_fire[ch] = hs_fire(deq_hs[ch]);
  end

  // A 通道: client -> manager。
  Queue2_TLBundleA_12 nodeOut_a_q (
    .clock               (clock),
    .reset               (reset),
    .io_enq_ready        (auto_in_a_ready),
    .io_enq_valid        (auto_in_a_valid),
    .io_enq_bits_opcode  (client_a.opcode),
    .io_enq_bits_param   (client_a.param),
    .io_enq_bits_size    (client_a.size),
    .io_enq_bits_source  (client_a.source),
    .io_enq_bits_address (client_a.address),
    .io_enq_bits_mask    (client_a.mask),
    .io_enq_bits_data    (client_a.data),
    .io_enq_bits_corrupt (client_a.corrupt),
    .io_deq_ready        (auto_out_a_ready),
    .io_deq_valid        (auto_out_a_valid),
    .io_deq_bits_opcode  (auto_out_a_bits_opcode),
    .io_deq_bits_param   (auto_out_a_bits_param),
    .io_deq_bits_size    (auto_out_a_bits_size),
    .io_deq_bits_source  (auto_out_a_bits_source),
    .io_deq_bits_address (auto_out_a_bits_address),
    .io_deq_bits_mask    (auto_out_a_bits_mask),
    .io_deq_bits_data    (auto_out_a_bits_data),
    .io_deq_bits_corrupt (auto_out_a_bits_corrupt)
  );

  // D 通道: manager -> client。
  Queue2_TLBundleD_13 nodeIn_d_q (
    .clock               (clock),
    .reset               (reset),
    .io_enq_ready        (auto_out_d_ready),
    .io_enq_valid        (auto_out_d_valid),
    .io_enq_bits_opcode  (manager_d.opcode),
    .io_enq_bits_param   (manager_d.param),
    .io_enq_bits_size    (manager_d.size),
    .io_enq_bits_source  (manager_d.source),
    .io_enq_bits_sink    (manager_d.sink),
    .io_enq_bits_denied  (manager_d.denied),
    .io_enq_bits_data    (manager_d.data),
    .io_enq_bits_corrupt (manager_d.corrupt),
    .io_deq_ready        (auto_in_d_ready),
    .io_deq_valid        (auto_in_d_valid),
    .io_deq_bits_opcode  (auto_in_d_bits_opcode),
    .io_deq_bits_param   (auto_in_d_bits_param),
    .io_deq_bits_size    (auto_in_d_bits_size),
    .io_deq_bits_source  (auto_in_d_bits_source),
    .io_deq_bits_sink    (auto_in_d_bits_sink),
    .io_deq_bits_denied  (auto_in_d_bits_denied),
    .io_deq_bits_data    (auto_in_d_bits_data),
    .io_deq_bits_corrupt (auto_in_d_bits_corrupt)
  );

endmodule
