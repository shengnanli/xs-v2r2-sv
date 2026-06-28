// =============================================================================
//  tlbuffer7_pkg —— TLBuffer_7 (TL-C 五通道 skid 缓冲) 类型包
// -----------------------------------------------------------------------------
//  TLBuffer_7 是缓存一致 (TL-C) 链路上的 5 通道时序缓冲, 相对基础 TLBuffer (仅 A/D
//  两通道) 多了 B/C/E 一致性通道。每条通道各插一个 Queue2 (两拍 skid FIFO), 不解释
//  opcode/param 语义, 只切断 ready/valid 长组合路径并保持单通道 FIFO 顺序。
//
//  TL 五通道方向 (client = CPU/L2 侧, manager = L3 侧):
//    A (Acquire/Get/Put) : client -> manager  请求      enq=in_a  deq=out_a
//    B (Probe)           : manager -> client  探测      enq=out_b deq=in_b
//    C (Release/ProbeAck) : client -> manager 回写/降级  enq=in_c  deq=out_c
//    D (Grant/AccessAck) : manager -> client  应答      enq=out_d deq=in_d
//    E (GrantAck)        : client -> manager  授权确认   enq=in_e  deq=out_e
//
//  下列结构体仅聚合各通道 *enq 侧* 的 payload 字段 (deq 侧直连输出端口); 字段宽度
//  取自 golden TLBuffer_7 端口。注意 firtool 下个别通道 enq/deq 字段不对称 (如 A 的
//  enq 无 data/corrupt、B 的 deq 仅 opcode/param/address/data), 核内按 golden 原样连接。
// =============================================================================
package tlbuffer7_pkg;
  // 五条 TL 通道编号 (用于 fire 数组的语义索引)。
  localparam int TL_NUM_CHANNELS = 5;
  typedef enum int unsigned {
    TL_CH_A = 0,  // client -> manager
    TL_CH_B = 1,  // manager -> client
    TL_CH_C = 2,  // client -> manager
    TL_CH_D = 3,  // manager -> client
    TL_CH_E = 4   // client -> manager
  } tl_channel_e;

  // Decoupled 握手对 (ready/valid), fire = ready & valid。
  typedef struct packed {
    logic ready;
    logic valid;
  } decoupled_hs_t;

  // ---- A enq (client A): 无 data/corrupt (由 Queue 在 deq 侧补出) ----
  typedef struct packed {
    logic [3:0]  opcode;
    logic [2:0]  param;
    logic [2:0]  size;
    logic [5:0]  source;
    logic [47:0] address;
    logic [1:0]  user_alias;
    logic [43:0] user_vaddr;
    logic [4:0]  user_reqSource;
    logic        user_needHint;
    logic        echo_isKeyword;
    logic [31:0] mask;
  } tl_a_enq_t;

  // ---- B enq (manager B) ----
  typedef struct packed {
    logic [2:0]   opcode;
    logic [1:0]   param;
    logic [2:0]   size;
    logic [5:0]   source;
    logic [47:0]  address;
    logic [31:0]  mask;
    logic [255:0] data;
    logic         corrupt;
  } tl_b_enq_t;

  // ---- C enq (client C) ----
  typedef struct packed {
    logic [2:0]   opcode;
    logic [2:0]   param;
    logic [2:0]   size;
    logic [5:0]   source;
    logic [47:0]  address;
    logic [255:0] data;
    logic         corrupt;
  } tl_c_enq_t;

  // ---- D enq (manager D) ----
  typedef struct packed {
    logic [3:0]   opcode;
    logic [1:0]   param;
    logic [2:0]   size;
    logic [5:0]   source;
    logic [9:0]   sink;
    logic         denied;
    logic         echo_isKeyword;
    logic [255:0] data;
    logic         corrupt;
  } tl_d_enq_t;

  // ---- E enq (client E): 仅 sink ----
  typedef struct packed {
    logic [9:0] sink;
  } tl_e_enq_t;
endpackage
