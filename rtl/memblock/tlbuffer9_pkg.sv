// =============================================================================
//  tlbuffer9_pkg —— TLBuffer_9 (TileLink A/D 两通道 skid 缓冲) 类型包
// -----------------------------------------------------------------------------
//  TLBuffer_9 是叶子级时序缓冲: A 请求 (client->manager)、D 应答 (manager->client)
//  各插一个 Queue2 (两拍 skid FIFO)。本层不解释 opcode/param 语义, 只切断 ready/valid
//  长组合路径并保持单通道 FIFO 顺序。把 golden 的扁平端口聚合成 A/D 两个 bundle, 便于
//  按 TL 通道方向阅读。
//  本变体特征: 窄总线缓冲: source/size 2 位、address 30 位、data 64 位, 无 user 字段。
//    A: client -> manager  请求   (enq=in_a, deq=out_a)
//    D: manager -> client  应答   (enq=out_d, deq=in_d)
// =============================================================================
package tlbuffer9_pkg;
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
    logic [1:0] size;
    logic [1:0] source;
    logic [29:0] address;
    logic [7:0] mask;
    logic [63:0] data;
    logic corrupt;
  } tl_a_bundle_t;

  // D 通道载荷 (enq=out_d 侧字段, 顺序取自 golden)。
  typedef struct packed {
    logic [3:0] opcode;
    logic [1:0] param;
    logic [1:0] size;
    logic [1:0] source;
    logic sink;
    logic denied;
    logic [63:0] data;
    logic corrupt;
  } tl_d_bundle_t;
endpackage
