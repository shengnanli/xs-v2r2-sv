// =============================================================================
//  tlbuffer6_pkg —— TLBuffer_6 (TileLink A/D 两通道 skid 缓冲) 类型包
// -----------------------------------------------------------------------------
//  TLBuffer_6 是叶子级时序缓冲: A 请求 (client->manager)、D 应答 (manager->client)
//  各插一个 Queue2 (两拍 skid FIFO)。本层不解释 opcode/param 语义, 只切断 ready/valid
//  长组合路径并保持单通道 FIFO 顺序。把 golden 的扁平端口聚合成 A/D 两个 bundle, 便于
//  按 TL 通道方向阅读。
//  本变体特征: 宽总线外设缓冲: source 3 位、address 48 位、data 256 位、mask 32 位, A 带 user_reqSource(5 位), D 的 sink 为 10 位。
//    A: client -> manager  请求   (enq=in_a, deq=out_a)
//    D: manager -> client  应答   (enq=out_d, deq=in_d)
// =============================================================================
package tlbuffer6_pkg;
  localparam int TL_NUM_CHANNELS = 2;
  typedef enum int unsigned {
    TL_CH_A = 0,  // client -> manager
    TL_CH_D = 1   // manager -> client
  } tl_channel_e;

  // Decoupled 握手对 (ready/valid), fire = ready & valid。
  typedef struct packed {
    logic ready;
    logic valid;
  } decoupled_hs_t;

  // A 通道载荷 (enq=in_a 侧字段, 顺序取自 golden)。
  typedef struct packed {
    logic [3:0] opcode;
    logic [2:0] param;
    logic [2:0] size;
    logic [2:0] source;
    logic [47:0] address;
    logic [4:0] user_reqSource;
    logic [31:0] mask;
    logic [255:0] data;
    logic corrupt;
  } tl_a_bundle_t;

  // D 通道载荷 (enq=out_d 侧字段, 顺序取自 golden)。
  typedef struct packed {
    logic [3:0] opcode;
    logic [1:0] param;
    logic [2:0] size;
    logic [2:0] source;
    logic [9:0] sink;
    logic denied;
    logic [255:0] data;
    logic corrupt;
  } tl_d_bundle_t;
endpackage
