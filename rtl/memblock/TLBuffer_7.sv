// =============================================================================
//  TLBuffer_7 —— TL-C 五通道 (A/B/C/D/E) 时序缓冲 (可读重写核 xs_TLBuffer_7_core)
// -----------------------------------------------------------------------------
//  缓存一致链路上的 5 通道 skid 缓冲: 每条 TileLink 通道各插一个 Queue2 (两拍 FIFO),
//  只切断 ready/valid 长组合路径、保持单通道顺序, 不解释 opcode/param 语义, 不跨通道
//  仲裁/重排。相对基础 TLBuffer (A/D 两通道) 多了 B/C/E 一致性通道。
//
//  通道方向 (client = CPU/L2 侧, manager = L3 侧), 见 tlbuffer7_pkg:
//    A: client->manager (enq=in_a, deq=out_a)   B: manager->client (enq=out_b, deq=in_b)
//    C: client->manager (enq=in_c, deq=out_c)   D: manager->client (enq=out_d, deq=in_d)
//    E: client->manager (enq=in_e, deq=out_e)
//  Queue2_* 是 UT/FM 两侧共用的黑盒叶子 (内含 ram_*); 本核仅做方向聚合 + 例化连线。
// =============================================================================
module xs_TLBuffer_7_core
  import tlbuffer7_pkg::*;
(
  input          clock,
  input          reset,
  // ---- 通道 A: client -> manager (in_a 入队, out_a 出队) ----
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
  // ---- 通道 B: manager -> client (out_b 入队, in_b 出队) ----
  input          auto_in_b_ready,
  output         auto_in_b_valid,
  output [2:0]   auto_in_b_bits_opcode,
  output [1:0]   auto_in_b_bits_param,
  output [47:0]  auto_in_b_bits_address,
  output [255:0] auto_in_b_bits_data,
  // ---- 通道 C: client -> manager (in_c 入队, out_c 出队) ----
  output         auto_in_c_ready,
  input          auto_in_c_valid,
  input  [2:0]   auto_in_c_bits_opcode,
  input  [2:0]   auto_in_c_bits_param,
  input  [2:0]   auto_in_c_bits_size,
  input  [5:0]   auto_in_c_bits_source,
  input  [47:0]  auto_in_c_bits_address,
  input  [255:0] auto_in_c_bits_data,
  input          auto_in_c_bits_corrupt,
  // ---- 通道 D: manager -> client (out_d 入队, in_d 出队) ----
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
  // ---- 通道 E: client -> manager (in_e 入队, out_e 出队) ----
  output         auto_in_e_ready,
  input          auto_in_e_valid,
  input  [9:0]   auto_in_e_bits_sink,
  // ---- manager 侧 A 出队 ----
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
  // ---- manager 侧 B 入队 ----
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
  // ---- manager 侧 C 出队 ----
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
  // ---- manager 侧 D 入队 ----
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
  // ---- manager 侧 E 出队 ----
  input          auto_out_e_ready,
  output         auto_out_e_valid,
  output [9:0]   auto_out_e_bits_sink
);

  function automatic logic hs_fire(input decoupled_hs_t hs);
    return hs.ready & hs.valid;
  endfunction

  // ---------------------------------------------------------------------------
  //  enq 侧 payload 聚合 (deq 侧直连输出端口, 见各 Queue 例化)。
  // ---------------------------------------------------------------------------
  tl_a_enq_t a_enq;   // client A
  tl_b_enq_t b_enq;   // manager B
  tl_c_enq_t c_enq;   // client C
  tl_d_enq_t d_enq;   // manager D
  tl_e_enq_t e_enq;   // client E

  always_comb begin
    a_enq = '{opcode: auto_in_a_bits_opcode, param: auto_in_a_bits_param,
              size: auto_in_a_bits_size, source: auto_in_a_bits_source,
              address: auto_in_a_bits_address, user_alias: auto_in_a_bits_user_alias,
              user_vaddr: auto_in_a_bits_user_vaddr, user_reqSource: auto_in_a_bits_user_reqSource,
              user_needHint: auto_in_a_bits_user_needHint,
              echo_isKeyword: auto_in_a_bits_echo_isKeyword, mask: auto_in_a_bits_mask};
    b_enq = '{opcode: auto_out_b_bits_opcode, param: auto_out_b_bits_param,
              size: auto_out_b_bits_size, source: auto_out_b_bits_source,
              address: auto_out_b_bits_address, mask: auto_out_b_bits_mask,
              data: auto_out_b_bits_data, corrupt: auto_out_b_bits_corrupt};
    c_enq = '{opcode: auto_in_c_bits_opcode, param: auto_in_c_bits_param,
              size: auto_in_c_bits_size, source: auto_in_c_bits_source,
              address: auto_in_c_bits_address, data: auto_in_c_bits_data,
              corrupt: auto_in_c_bits_corrupt};
    d_enq = '{opcode: auto_out_d_bits_opcode, param: auto_out_d_bits_param,
              size: auto_out_d_bits_size, source: auto_out_d_bits_source,
              sink: auto_out_d_bits_sink, denied: auto_out_d_bits_denied,
              echo_isKeyword: auto_out_d_bits_echo_isKeyword, data: auto_out_d_bits_data,
              corrupt: auto_out_d_bits_corrupt};
    e_enq = '{sink: auto_in_e_bits_sink};
  end

  // 五通道 enq/deq 握手 (仅说明 skid 缓冲两侧 fire = ready & valid; 队列内部自管深度)。
  decoupled_hs_t enq_hs [TL_NUM_CHANNELS];
  decoupled_hs_t deq_hs [TL_NUM_CHANNELS];
  logic [TL_NUM_CHANNELS-1:0] enq_fire;
  logic [TL_NUM_CHANNELS-1:0] deq_fire;

  assign enq_hs[TL_CH_A] = '{ready: auto_in_a_ready,  valid: auto_in_a_valid};
  assign deq_hs[TL_CH_A] = '{ready: auto_out_a_ready, valid: auto_out_a_valid};
  assign enq_hs[TL_CH_B] = '{ready: auto_out_b_ready, valid: auto_out_b_valid};
  assign deq_hs[TL_CH_B] = '{ready: auto_in_b_ready,  valid: auto_in_b_valid};
  assign enq_hs[TL_CH_C] = '{ready: auto_in_c_ready,  valid: auto_in_c_valid};
  assign deq_hs[TL_CH_C] = '{ready: auto_out_c_ready, valid: auto_out_c_valid};
  assign enq_hs[TL_CH_D] = '{ready: auto_out_d_ready, valid: auto_out_d_valid};
  assign deq_hs[TL_CH_D] = '{ready: auto_in_d_ready,  valid: auto_in_d_valid};
  assign enq_hs[TL_CH_E] = '{ready: auto_in_e_ready,  valid: auto_in_e_valid};
  assign deq_hs[TL_CH_E] = '{ready: auto_out_e_ready, valid: auto_out_e_valid};

  for (genvar ch = 0; ch < TL_NUM_CHANNELS; ch++) begin : g_fire
    assign enq_fire[ch] = hs_fire(enq_hs[ch]);
    assign deq_fire[ch] = hs_fire(deq_hs[ch]);
  end

  // ---------------------------------------------------------------------------
  //  通道 A: client -> manager。
  // ---------------------------------------------------------------------------
  Queue2_TLBundleA_7 nodeOut_a_q (
    .clock                      (clock),
    .reset                      (reset),
    .io_enq_ready               (auto_in_a_ready),
    .io_enq_valid               (auto_in_a_valid),
    .io_enq_bits_opcode         (a_enq.opcode),
    .io_enq_bits_param          (a_enq.param),
    .io_enq_bits_size           (a_enq.size),
    .io_enq_bits_source         (a_enq.source),
    .io_enq_bits_address        (a_enq.address),
    .io_enq_bits_user_alias     (a_enq.user_alias),
    .io_enq_bits_user_vaddr     (a_enq.user_vaddr),
    .io_enq_bits_user_reqSource (a_enq.user_reqSource),
    .io_enq_bits_user_needHint  (a_enq.user_needHint),
    .io_enq_bits_echo_isKeyword (a_enq.echo_isKeyword),
    .io_enq_bits_mask           (a_enq.mask),
    .io_deq_ready               (auto_out_a_ready),
    .io_deq_valid               (auto_out_a_valid),
    .io_deq_bits_opcode         (auto_out_a_bits_opcode),
    .io_deq_bits_param          (auto_out_a_bits_param),
    .io_deq_bits_size           (auto_out_a_bits_size),
    .io_deq_bits_source         (auto_out_a_bits_source),
    .io_deq_bits_address        (auto_out_a_bits_address),
    .io_deq_bits_user_alias     (auto_out_a_bits_user_alias),
    .io_deq_bits_user_vaddr     (auto_out_a_bits_user_vaddr),
    .io_deq_bits_user_reqSource (auto_out_a_bits_user_reqSource),
    .io_deq_bits_user_needHint  (auto_out_a_bits_user_needHint),
    .io_deq_bits_echo_isKeyword (auto_out_a_bits_echo_isKeyword),
    .io_deq_bits_mask           (auto_out_a_bits_mask),
    .io_deq_bits_data           (auto_out_a_bits_data),
    .io_deq_bits_corrupt        (auto_out_a_bits_corrupt)
  );

  // ---------------------------------------------------------------------------
  //  通道 D: manager -> client。
  // ---------------------------------------------------------------------------
  Queue2_TLBundleD_8 nodeIn_d_q (
    .clock                      (clock),
    .reset                      (reset),
    .io_enq_ready               (auto_out_d_ready),
    .io_enq_valid               (auto_out_d_valid),
    .io_enq_bits_opcode         (d_enq.opcode),
    .io_enq_bits_param          (d_enq.param),
    .io_enq_bits_size           (d_enq.size),
    .io_enq_bits_source         (d_enq.source),
    .io_enq_bits_sink           (d_enq.sink),
    .io_enq_bits_denied         (d_enq.denied),
    .io_enq_bits_echo_isKeyword (d_enq.echo_isKeyword),
    .io_enq_bits_data           (d_enq.data),
    .io_enq_bits_corrupt        (d_enq.corrupt),
    .io_deq_ready               (auto_in_d_ready),
    .io_deq_valid               (auto_in_d_valid),
    .io_deq_bits_opcode         (auto_in_d_bits_opcode),
    .io_deq_bits_param          (auto_in_d_bits_param),
    .io_deq_bits_size           (auto_in_d_bits_size),
    .io_deq_bits_source         (auto_in_d_bits_source),
    .io_deq_bits_sink           (auto_in_d_bits_sink),
    .io_deq_bits_denied         (auto_in_d_bits_denied),
    .io_deq_bits_echo_isKeyword (auto_in_d_bits_echo_isKeyword),
    .io_deq_bits_data           (auto_in_d_bits_data),
    .io_deq_bits_corrupt        (auto_in_d_bits_corrupt)
  );

  // ---------------------------------------------------------------------------
  //  通道 B: manager -> client (deq 侧 in_b 仅暴露 opcode/param/address/data)。
  // ---------------------------------------------------------------------------
  Queue2_TLBundleB nodeIn_b_q (
    .clock               (clock),
    .reset               (reset),
    .io_enq_ready        (auto_out_b_ready),
    .io_enq_valid        (auto_out_b_valid),
    .io_enq_bits_opcode  (b_enq.opcode),
    .io_enq_bits_param   (b_enq.param),
    .io_enq_bits_size    (b_enq.size),
    .io_enq_bits_source  (b_enq.source),
    .io_enq_bits_address (b_enq.address),
    .io_enq_bits_mask    (b_enq.mask),
    .io_enq_bits_data    (b_enq.data),
    .io_enq_bits_corrupt (b_enq.corrupt),
    .io_deq_ready        (auto_in_b_ready),
    .io_deq_valid        (auto_in_b_valid),
    .io_deq_bits_opcode  (auto_in_b_bits_opcode),
    .io_deq_bits_param   (auto_in_b_bits_param),
    .io_deq_bits_address (auto_in_b_bits_address),
    .io_deq_bits_data    (auto_in_b_bits_data)
  );

  // ---------------------------------------------------------------------------
  //  通道 C: client -> manager (deq 侧 out_c 额外带 user_*/echo, 由 Queue 透传/补出)。
  // ---------------------------------------------------------------------------
  Queue2_TLBundleC nodeOut_c_q (
    .clock                      (clock),
    .reset                      (reset),
    .io_enq_ready               (auto_in_c_ready),
    .io_enq_valid               (auto_in_c_valid),
    .io_enq_bits_opcode         (c_enq.opcode),
    .io_enq_bits_param          (c_enq.param),
    .io_enq_bits_size           (c_enq.size),
    .io_enq_bits_source         (c_enq.source),
    .io_enq_bits_address        (c_enq.address),
    .io_enq_bits_data           (c_enq.data),
    .io_enq_bits_corrupt        (c_enq.corrupt),
    .io_deq_ready               (auto_out_c_ready),
    .io_deq_valid               (auto_out_c_valid),
    .io_deq_bits_opcode         (auto_out_c_bits_opcode),
    .io_deq_bits_param          (auto_out_c_bits_param),
    .io_deq_bits_size           (auto_out_c_bits_size),
    .io_deq_bits_source         (auto_out_c_bits_source),
    .io_deq_bits_address        (auto_out_c_bits_address),
    .io_deq_bits_user_alias     (auto_out_c_bits_user_alias),
    .io_deq_bits_user_vaddr     (auto_out_c_bits_user_vaddr),
    .io_deq_bits_user_reqSource (auto_out_c_bits_user_reqSource),
    .io_deq_bits_user_needHint  (auto_out_c_bits_user_needHint),
    .io_deq_bits_echo_isKeyword (auto_out_c_bits_echo_isKeyword),
    .io_deq_bits_data           (auto_out_c_bits_data),
    .io_deq_bits_corrupt        (auto_out_c_bits_corrupt)
  );

  // ---------------------------------------------------------------------------
  //  通道 E: client -> manager (仅 sink)。
  // ---------------------------------------------------------------------------
  Queue2_TLBundleE nodeOut_e_q (
    .clock            (clock),
    .reset            (reset),
    .io_enq_ready     (auto_in_e_ready),
    .io_enq_valid     (auto_in_e_valid),
    .io_enq_bits_sink (e_enq.sink),
    .io_deq_ready     (auto_out_e_ready),
    .io_deq_valid     (auto_out_e_valid),
    .io_deq_bits_sink (auto_out_e_bits_sink)
  );

endmodule
