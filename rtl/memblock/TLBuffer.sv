// =============================================================================
//  TLBuffer —— TileLink A/D 通道时序缓冲（可读重写核 xs_TLBuffer_core）
// -----------------------------------------------------------------------------
//  A 请求方向 client->manager、D 响应方向 manager->client 各插一个 Queue2。
//  本层不解码 TL opcode、不跨通道重排，只切断 ready/valid 长组合路径并保持
//  单通道 FIFO 顺序。Queue2_* 是 UT/FM 两侧共用的黑盒叶子。
// =============================================================================
module xs_TLBuffer_core
  import tlbuffer_pkg::*;
(
  input         clock,
  input         reset,
  output        auto_in_a_ready,
  input         auto_in_a_valid,
  input  [3:0]  auto_in_a_bits_opcode,
  input  [2:0]  auto_in_a_bits_param,
  input  [2:0]  auto_in_a_bits_size,
  input  [13:0] auto_in_a_bits_source,
  input  [48:0] auto_in_a_bits_address,
  input         auto_in_a_bits_user_amba_prot_bufferable,
  input         auto_in_a_bits_user_amba_prot_modifiable,
  input         auto_in_a_bits_user_amba_prot_readalloc,
  input         auto_in_a_bits_user_amba_prot_writealloc,
  input         auto_in_a_bits_user_amba_prot_privileged,
  input         auto_in_a_bits_user_amba_prot_secure,
  input         auto_in_a_bits_user_amba_prot_fetch,
  input  [7:0]  auto_in_a_bits_mask,
  input  [63:0] auto_in_a_bits_data,
  input         auto_in_a_bits_corrupt,
  input         auto_in_d_ready,
  output        auto_in_d_valid,
  output [3:0]  auto_in_d_bits_opcode,
  output [1:0]  auto_in_d_bits_param,
  output [2:0]  auto_in_d_bits_size,
  output [13:0] auto_in_d_bits_source,
  output        auto_in_d_bits_sink,
  output        auto_in_d_bits_denied,
  output [63:0] auto_in_d_bits_data,
  output        auto_in_d_bits_corrupt,
  input         auto_out_a_ready,
  output        auto_out_a_valid,
  output [3:0]  auto_out_a_bits_opcode,
  output [2:0]  auto_out_a_bits_param,
  output [2:0]  auto_out_a_bits_size,
  output [13:0] auto_out_a_bits_source,
  output [48:0] auto_out_a_bits_address,
  output        auto_out_a_bits_user_amba_prot_bufferable,
  output        auto_out_a_bits_user_amba_prot_modifiable,
  output        auto_out_a_bits_user_amba_prot_readalloc,
  output        auto_out_a_bits_user_amba_prot_writealloc,
  output        auto_out_a_bits_user_amba_prot_privileged,
  output        auto_out_a_bits_user_amba_prot_secure,
  output        auto_out_a_bits_user_amba_prot_fetch,
  output [7:0]  auto_out_a_bits_mask,
  output [63:0] auto_out_a_bits_data,
  output        auto_out_a_bits_corrupt,
  output        auto_out_d_ready,
  input         auto_out_d_valid,
  input  [3:0]  auto_out_d_bits_opcode,
  input  [1:0]  auto_out_d_bits_param,
  input  [2:0]  auto_out_d_bits_size,
  input  [13:0] auto_out_d_bits_source,
  input         auto_out_d_bits_sink,
  input         auto_out_d_bits_denied,
  input  [63:0] auto_out_d_bits_data,
  input         auto_out_d_bits_corrupt
);

  typedef enum logic [0:0] {
    TL_PATH_A_REQUEST  = 1'b0,
    TL_PATH_D_RESPONSE = 1'b1
  } tl_buffer_path_e;

  typedef struct packed {
    logic ready;
    logic valid;
  } decoupled_handshake_t;

  function automatic logic handshake_fire(input decoupled_handshake_t hs);
    return hs.ready & hs.valid;
  endfunction

  // 扁平端口聚合：用 TL 方向命名，而不是按 golden 实例名阅读。
  tl_a_bundle_t client_a;
  tl_d_bundle_t manager_d;

  always_comb begin
    client_a.opcode = auto_in_a_bits_opcode;
    client_a.param = auto_in_a_bits_param;
    client_a.size = auto_in_a_bits_size;
    client_a.source = auto_in_a_bits_source;
    client_a.address = auto_in_a_bits_address;
    client_a.user_amba_prot.bufferable = auto_in_a_bits_user_amba_prot_bufferable;
    client_a.user_amba_prot.modifiable = auto_in_a_bits_user_amba_prot_modifiable;
    client_a.user_amba_prot.readalloc = auto_in_a_bits_user_amba_prot_readalloc;
    client_a.user_amba_prot.writealloc = auto_in_a_bits_user_amba_prot_writealloc;
    client_a.user_amba_prot.privileged = auto_in_a_bits_user_amba_prot_privileged;
    client_a.user_amba_prot.secure = auto_in_a_bits_user_amba_prot_secure;
    client_a.user_amba_prot.fetch = auto_in_a_bits_user_amba_prot_fetch;
    client_a.mask = auto_in_a_bits_mask;
    client_a.data = auto_in_a_bits_data;
    client_a.corrupt = auto_in_a_bits_corrupt;

    manager_d.opcode = auto_out_d_bits_opcode;
    manager_d.param = auto_out_d_bits_param;
    manager_d.size = auto_out_d_bits_size;
    manager_d.source = auto_out_d_bits_source;
    manager_d.sink = auto_out_d_bits_sink;
    manager_d.denied = auto_out_d_bits_denied;
    manager_d.data = auto_out_d_bits_data;
    manager_d.corrupt = auto_out_d_bits_corrupt;
  end

  // A/D 两条被缓冲路径统一放进数组，说明 fire = ready & valid。
  decoupled_handshake_t enqueue_hs [TL_BUFFER_CHANNELS];
  decoupled_handshake_t dequeue_hs [TL_BUFFER_CHANNELS];
  logic [TL_BUFFER_CHANNELS-1:0] enqueue_fire;
  logic [TL_BUFFER_CHANNELS-1:0] dequeue_fire;

  assign enqueue_hs[TL_PATH_A_REQUEST].valid = auto_in_a_valid;
  assign enqueue_hs[TL_PATH_A_REQUEST].ready = auto_in_a_ready;
  assign dequeue_hs[TL_PATH_A_REQUEST].valid = auto_out_a_valid;
  assign dequeue_hs[TL_PATH_A_REQUEST].ready = auto_out_a_ready;

  assign enqueue_hs[TL_PATH_D_RESPONSE].valid = auto_out_d_valid;
  assign enqueue_hs[TL_PATH_D_RESPONSE].ready = auto_out_d_ready;
  assign dequeue_hs[TL_PATH_D_RESPONSE].valid = auto_in_d_valid;
  assign dequeue_hs[TL_PATH_D_RESPONSE].ready = auto_in_d_ready;

  for (genvar channel = 0; channel < TL_BUFFER_CHANNELS; channel++) begin : g_handshake
    assign enqueue_fire[channel] = handshake_fire(enqueue_hs[channel]);
    assign dequeue_fire[channel] = handshake_fire(dequeue_hs[channel]);
  end

  // A 通道：client -> manager。Queue 负责 back-pressure 和两拍容量。
  Queue2_TLBundleA request_queue (
    .clock                                 (clock),
    .reset                                 (reset),
    .io_enq_ready                          (auto_in_a_ready),
    .io_enq_valid                          (auto_in_a_valid),
    .io_enq_bits_opcode                    (client_a.opcode),
    .io_enq_bits_param                     (client_a.param),
    .io_enq_bits_size                      (client_a.size),
    .io_enq_bits_source                    (client_a.source),
    .io_enq_bits_address                   (client_a.address),
    .io_enq_bits_user_amba_prot_bufferable (client_a.user_amba_prot.bufferable),
    .io_enq_bits_user_amba_prot_modifiable (client_a.user_amba_prot.modifiable),
    .io_enq_bits_user_amba_prot_readalloc  (client_a.user_amba_prot.readalloc),
    .io_enq_bits_user_amba_prot_writealloc (client_a.user_amba_prot.writealloc),
    .io_enq_bits_user_amba_prot_privileged (client_a.user_amba_prot.privileged),
    .io_enq_bits_user_amba_prot_secure     (client_a.user_amba_prot.secure),
    .io_enq_bits_user_amba_prot_fetch      (client_a.user_amba_prot.fetch),
    .io_enq_bits_mask                      (client_a.mask),
    .io_enq_bits_data                      (client_a.data),
    .io_enq_bits_corrupt                   (client_a.corrupt),
    .io_deq_ready                          (auto_out_a_ready),
    .io_deq_valid                          (auto_out_a_valid),
    .io_deq_bits_opcode                    (auto_out_a_bits_opcode),
    .io_deq_bits_param                     (auto_out_a_bits_param),
    .io_deq_bits_size                      (auto_out_a_bits_size),
    .io_deq_bits_source                    (auto_out_a_bits_source),
    .io_deq_bits_address                   (auto_out_a_bits_address),
    .io_deq_bits_user_amba_prot_bufferable (auto_out_a_bits_user_amba_prot_bufferable),
    .io_deq_bits_user_amba_prot_modifiable (auto_out_a_bits_user_amba_prot_modifiable),
    .io_deq_bits_user_amba_prot_readalloc  (auto_out_a_bits_user_amba_prot_readalloc),
    .io_deq_bits_user_amba_prot_writealloc (auto_out_a_bits_user_amba_prot_writealloc),
    .io_deq_bits_user_amba_prot_privileged (auto_out_a_bits_user_amba_prot_privileged),
    .io_deq_bits_user_amba_prot_secure     (auto_out_a_bits_user_amba_prot_secure),
    .io_deq_bits_user_amba_prot_fetch      (auto_out_a_bits_user_amba_prot_fetch),
    .io_deq_bits_mask                      (auto_out_a_bits_mask),
    .io_deq_bits_data                      (auto_out_a_bits_data),
    .io_deq_bits_corrupt                   (auto_out_a_bits_corrupt)
  );

  // D 通道：manager -> client。响应方向独立排队，不与 A 通道做任何仲裁。
  Queue2_TLBundleD response_queue (
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
