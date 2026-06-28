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
