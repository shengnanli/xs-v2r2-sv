// =============================================================================
//  tlbuffer2_pkg —— TLBuffer_2 (TL-UL/UH A/D 两通道 skid 缓冲) 类型包
// -----------------------------------------------------------------------------
//  相对基础 TLBuffer, 本变体是更窄的外设侧总线缓冲: 无 AMBA prot(user) 字段,
//  size 2 位、source 15 位、address 30 位、data 64 位。A/D 各插一个 Queue2
//  (两拍 skid FIFO), 不解释 opcode/param 语义, 只切断 ready/valid 长组合路径。
//    A: client -> manager  请求   (enq=in_a, deq=out_a)
//    D: manager -> client  应答   (enq=out_d, deq=in_d)
// =============================================================================
package tlbuffer2_pkg;
  localparam int TL_NUM_CHANNELS = 2;
  typedef enum int unsigned {
    TL_CH_A = 0,  // client -> manager
    TL_CH_D = 1   // manager -> client
  } tl_channel_e;

  typedef struct packed {
    logic ready;
    logic valid;
  } decoupled_hs_t;

  // A 通道载荷 (无 user)。
  typedef struct packed {
    logic [3:0]  opcode;
    logic [2:0]  param;
    logic [1:0]  size;
    logic [14:0] source;
    logic [29:0] address;
    logic [7:0]  mask;
    logic [63:0] data;
    logic        corrupt;
  } tl_a_bundle_t;

  // D 通道载荷。
  typedef struct packed {
    logic [3:0]  opcode;
    logic [1:0]  param;
    logic [1:0]  size;
    logic [14:0] source;
    logic        sink;
    logic        denied;
    logic [63:0] data;
    logic        corrupt;
  } tl_d_bundle_t;
endpackage

// =============================================================================
//  TLBuffer_2 —— TileLink A/D 两通道时序缓冲 (可读重写核 xs_TLBuffer_2_core)
// -----------------------------------------------------------------------------
//  外设侧的窄总线 skid 缓冲: A 请求 client->manager、D 响应 manager->client 各插一个
//  Queue2 (两拍 FIFO)。本层不解码 TL opcode、不跨通道重排, 只切断 ready/valid 长组合
//  路径并保持单通道顺序。Queue2_* 是 UT/FM 两侧共用的黑盒叶子 (内含 ram_*)。
//  与基础 TLBuffer 的差异: 无 AMBA prot(user), size/source/address/data 更窄 (见 pkg)。
// =============================================================================

module xs_TLBuffer_2_core
  import tlbuffer2_pkg::*;
(
  input         clock,
  input         reset,
  output        auto_in_a_ready,
  input         auto_in_a_valid,
  input  [3:0]  auto_in_a_bits_opcode,
  input  [2:0]  auto_in_a_bits_param,
  input  [1:0]  auto_in_a_bits_size,
  input  [14:0] auto_in_a_bits_source,
  input  [29:0] auto_in_a_bits_address,
  input  [7:0]  auto_in_a_bits_mask,
  input  [63:0] auto_in_a_bits_data,
  input         auto_in_a_bits_corrupt,
  input         auto_in_d_ready,
  output        auto_in_d_valid,
  output [3:0]  auto_in_d_bits_opcode,
  output [1:0]  auto_in_d_bits_param,
  output [1:0]  auto_in_d_bits_size,
  output [14:0] auto_in_d_bits_source,
  output        auto_in_d_bits_sink,
  output        auto_in_d_bits_denied,
  output [63:0] auto_in_d_bits_data,
  output        auto_in_d_bits_corrupt,
  input         auto_out_a_ready,
  output        auto_out_a_valid,
  output [3:0]  auto_out_a_bits_opcode,
  output [2:0]  auto_out_a_bits_param,
  output [1:0]  auto_out_a_bits_size,
  output [14:0] auto_out_a_bits_source,
  output [29:0] auto_out_a_bits_address,
  output [7:0]  auto_out_a_bits_mask,
  output [63:0] auto_out_a_bits_data,
  output        auto_out_a_bits_corrupt,
  output        auto_out_d_ready,
  input         auto_out_d_valid,
  input  [3:0]  auto_out_d_bits_opcode,
  input  [1:0]  auto_out_d_bits_param,
  input  [1:0]  auto_out_d_bits_size,
  input  [14:0] auto_out_d_bits_source,
  input         auto_out_d_bits_sink,
  input         auto_out_d_bits_denied,
  input  [63:0] auto_out_d_bits_data,
  input         auto_out_d_bits_corrupt
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
  Queue2_TLBundleA_2 nodeOut_a_q (
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
  Queue2_TLBundleD_3 nodeIn_d_q (
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

// 自动生成：xs-v2r2-sv/scripts/gen_tlbuffer2.py —— 该脚本未移植到本轮(它按上一轮规范产出独立 _wrapper.sv)，本文件手工维护

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module TLBuffer_2(
  input clock,
  input reset,
  output auto_in_a_ready,
  input auto_in_a_valid,
  input [3:0] auto_in_a_bits_opcode,
  input [2:0] auto_in_a_bits_param,
  input [1:0] auto_in_a_bits_size,
  input [14:0] auto_in_a_bits_source,
  input [29:0] auto_in_a_bits_address,
  input [7:0] auto_in_a_bits_mask,
  input [63:0] auto_in_a_bits_data,
  input auto_in_a_bits_corrupt,
  input auto_in_d_ready,
  output auto_in_d_valid,
  output [3:0] auto_in_d_bits_opcode,
  output [1:0] auto_in_d_bits_param,
  output [1:0] auto_in_d_bits_size,
  output [14:0] auto_in_d_bits_source,
  output auto_in_d_bits_sink,
  output auto_in_d_bits_denied,
  output [63:0] auto_in_d_bits_data,
  output auto_in_d_bits_corrupt,
  input auto_out_a_ready,
  output auto_out_a_valid,
  output [3:0] auto_out_a_bits_opcode,
  output [2:0] auto_out_a_bits_param,
  output [1:0] auto_out_a_bits_size,
  output [14:0] auto_out_a_bits_source,
  output [29:0] auto_out_a_bits_address,
  output [7:0] auto_out_a_bits_mask,
  output [63:0] auto_out_a_bits_data,
  output auto_out_a_bits_corrupt,
  output auto_out_d_ready,
  input auto_out_d_valid,
  input [3:0] auto_out_d_bits_opcode,
  input [1:0] auto_out_d_bits_param,
  input [1:0] auto_out_d_bits_size,
  input [14:0] auto_out_d_bits_source,
  input auto_out_d_bits_sink,
  input auto_out_d_bits_denied,
  input [63:0] auto_out_d_bits_data,
  input auto_out_d_bits_corrupt
);
  xs_TLBuffer_2_core u_core (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_param(auto_in_a_bits_param),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(auto_in_a_bits_corrupt),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(auto_in_d_valid),
    .auto_in_d_bits_opcode(auto_in_d_bits_opcode),
    .auto_in_d_bits_param(auto_in_d_bits_param),
    .auto_in_d_bits_size(auto_in_d_bits_size),
    .auto_in_d_bits_source(auto_in_d_bits_source),
    .auto_in_d_bits_sink(auto_in_d_bits_sink),
    .auto_in_d_bits_denied(auto_in_d_bits_denied),
    .auto_in_d_bits_data(auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(auto_in_d_bits_corrupt),
    .auto_out_a_ready(auto_out_a_ready),
    .auto_out_a_valid(auto_out_a_valid),
    .auto_out_a_bits_opcode(auto_out_a_bits_opcode),
    .auto_out_a_bits_param(auto_out_a_bits_param),
    .auto_out_a_bits_size(auto_out_a_bits_size),
    .auto_out_a_bits_source(auto_out_a_bits_source),
    .auto_out_a_bits_address(auto_out_a_bits_address),
    .auto_out_a_bits_mask(auto_out_a_bits_mask),
    .auto_out_a_bits_data(auto_out_a_bits_data),
    .auto_out_a_bits_corrupt(auto_out_a_bits_corrupt),
    .auto_out_d_ready(auto_out_d_ready),
    .auto_out_d_valid(auto_out_d_valid),
    .auto_out_d_bits_opcode(auto_out_d_bits_opcode),
    .auto_out_d_bits_param(auto_out_d_bits_param),
    .auto_out_d_bits_size(auto_out_d_bits_size),
    .auto_out_d_bits_source(auto_out_d_bits_source),
    .auto_out_d_bits_sink(auto_out_d_bits_sink),
    .auto_out_d_bits_denied(auto_out_d_bits_denied),
    .auto_out_d_bits_data(auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(auto_out_d_bits_corrupt)
  );
endmodule
