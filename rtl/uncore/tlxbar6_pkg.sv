// =============================================================================
//  tlxbar6_pkg —— TLXbar_6 (2 主 × 3 从 多主 TileLink-C 交叉开关) 常量与类型
// -----------------------------------------------------------------------------
//  对应 rocket-chip 的 TLXbar (src/main/scala/tilelink/Xbar.scala)。本变体是香山
//  外设/缓存控制总线上的多主交叉开关: 2 个上游主口仲裁后分发给 3 个下游从口。
//
//  主口 (in):
//    in_0: source 1 位 (单 ID); A 通道不携带 user(MM/NC); D 通道无 source 字段。
//          交叉开关内部把它的 source 重映射到 3 位基址 4 (= {2'b10, s}, 取值 4/5)。
//    in_1: source 2 位; A 通道携带 user(memBackType_MM / memPageType_NC); D 带 2 位
//          source。内部重映射到 3 位基址 0 (= {1'b0, s}, 取值 0..3)。
//
//  从口 (out) —— 地址映射来自香山 SoC.scala:
//    out_0 (OUT_BEU)       : Bus Error Unit, AddressSet(0x38010000, 0xfff) = 4KB,
//                            30 位地址, 不携带 user;
//    out_1 (OUT_CACHECTRL) : L3 缓存控制寄存器区 AddressSet(0x38022000, 0x7f) = 256B,
//                            30 位地址, 不携带 user;
//    out_2 (OUT_DEFAULT)   : 默认 catch-all 从口 (主存/CLINT/PLIC 等整条总线),
//                            即 BEU ∪ CacheCtrl 的补集, 48 位全地址, 携带 user。
//
//  多主仲裁 (相对单主 TLXbar_4 的关键增量):
//    · A 通道: 每个从口对"请求它的若干主口"做 TLArbiter.roundRobin 轮转仲裁
//      (NUM_IN=2 路), 胜者的载荷被路由到该从口; 主口 A ready 汇聚命中从口的就绪
//      且本主口在该从口仲裁中被授权 (allowed)。
//    · D 通道: 每个主口对"应答它的若干从口"做轮转仲裁 (NUM_OUT=3 路), 按 D 的
//      source 字段判定该应答属于哪个主口 (路由矩阵)。
//    两侧复用同一套 rr_grant / left_or / right_or_capped 前缀 OR 通用算法 (见核内)。
//
//  本口访问恒为单拍 (firtool 里各 beatsLeft 仅 1 位且 init 恒 0), 仲裁器的 beat 计数/
//  锁定逻辑退化 (恒处 idle); 与下游 stall 配合时 state 寄存器维持当拍胜者稳定。
// =============================================================================
package tlxbar6_pkg;

  // 主口 / 从口数量, 以及前缀 OR 通用算法的最大位宽 (= max(NUM_IN, NUM_OUT))。
  localparam int NUM_IN  = 2;
  localparam int NUM_OUT = 3;
  localparam int MAXN    = 3;

  // 从口编号 (语义命名, 取代 golden 的 out_0/out_1/out_2 展平名)。
  typedef enum int unsigned {
    OUT_BEU       = 0,  // out_0: Bus Error Unit  (AddressSet 0x38010000/0xfff)
    OUT_CACHECTRL = 1,  // out_1: L3 CacheCtrl    (AddressSet 0x38022000/0x7f)
    OUT_DEFAULT   = 2   // out_2: 默认 catch-all  (前两者的补集)
  } out_port_e;

  // 主口编号。
  typedef enum int unsigned {
    IN_0 = 0,   // in_0: source 1 位, 无 user, 内部 source 基址 4
    IN_1 = 1    // in_1: source 2 位, 带 user, 内部 source 基址 0
  } in_port_e;

  // ---------------------------------------------------------------------------
  //  A 通道载荷 (主→从) —— 取两个主口字段的超集; in_0 不带 user 时该位填 0。
  //  source 为内部重映射后的 3 位 ID; address 取 48 位全宽 (窄从口截断到 30 位)。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [3:0]  opcode;
    logic [2:0]  param;
    logic [1:0]  size;
    logic [2:0]  source;
    logic [47:0] address;
    logic        user_MM;   // memBackType_MM (仅 in_1 有效)
    logic        user_NC;   // memPageType_NC (仅 in_1 有效)
    logic [7:0]  mask;
    logic [63:0] data;
    logic        corrupt;
  } tl_a_t;

  // ---------------------------------------------------------------------------
  //  D 通道载荷 (从→主) —— 三个从口字段对称; source 为内部 3 位 ID, 回送主口时
  //  in_1 取低 2 位, in_0 无 source 端口 (丢弃)。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [3:0]  opcode;
    logic [1:0]  param;
    logic [1:0]  size;
    logic [2:0]  source;
    logic        sink;
    logic        denied;
    logic [63:0] data;
    logic        corrupt;
  } tl_d_t;

  // ---------------------------------------------------------------------------
  //  地址译码常量 —— 两个具名从口由 AddressSet(base, mask) 解码, 默认口取补集。
  //    BEU      : (addr & ~0xfff) == 0x38010000  ⇔ addr[47:12] == 0x38010
  //    CacheCtrl: (addr & ~0x07f) == 0x38022000  ⇔ addr[47:8]  == 0x380220
  //  (已离线核验: golden 的 out_2 catch-all 40 项 OR 与 ~(BEU|CacheCtrl) 在 48 位
  //   空间内逐位等价且无地址空洞, 故此处直接取补集。)
  // ---------------------------------------------------------------------------
  localparam logic [35:0] BEU_ADDR_HI       = 36'h38010;   // addr[47:12]
  localparam logic [39:0] CACHECTRL_ADDR_HI = 40'h380220;  // addr[47:8]

  // D 通道 source → 主口路由判据 (源自内部重映射: in_0 基址 4 / in_1 基址 0):
  //   属于 in_0 ⇔ source == 3'h4 ; 属于 in_1 ⇔ source[2] == 0 (取值 0..3)。
  localparam logic [2:0]  IN0_SOURCE_ID = 3'h4;

endpackage
