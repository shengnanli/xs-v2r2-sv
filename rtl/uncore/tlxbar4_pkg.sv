// =============================================================================
//  tlxbar4_pkg —— TLXbar_4 (1 主 × 2 从 TileLink-C 交叉开关) 常量与类型
// -----------------------------------------------------------------------------
//  对应 rocket-chip 的 TLXbar (src/main/scala/tilelink/Xbar.scala)。本变体是香山
//  外设/缓存控制总线上的一个交叉开关: 1 个上游主口 (in) 把 64 位访问按地址分发给
//  2 个下游从口:
//    out0 (OUT_CACHECTRL): L2/L3 缓存控制寄存器区 CacheCtrl, 来自 Scala
//                          AddressSet(0x38022000, 0x7f) —— 128 字节, 30 位地址;
//    out1 (OUT_DEFAULT)  : 默认 catch-all 从口 (主存/其余外设的整条总线),
//                          即 CacheCtrl 区间的补集, 48 位全地址。
//
//  与 tlxbar3 的差异:
//    · 端口是完整 TileLink-C: A 带 param/size/source/mask/corrupt/user(NC/MM),
//      D 带 opcode/param/size/source/sink/denied/data/corrupt;
//    · out0 只是 30 位地址的 UL 风格从口, 不携带 user(NC/MM) 字段; out1 携带;
//    · 两个从口的 D 通道字段对称 (都含 denied/sink/corrupt), 故 D 仲裁载荷统一。
//
//  本口的访问恒为单拍 (firtool 里 beatsLeft 仅 1 位且 init 恒 0), D 通道仲裁器的
//  beat 计数/锁定逻辑退化 (恒处 idle), 仅 round-robin 公平掩码真正起作用。
// =============================================================================
package tlxbar4_pkg;

  // 下游从口数量 (本变体固定 2)。
  localparam int NUM_OUT = 2;

  // 从口编号 (语义命名, 取代 golden 的 out_0/out_1 展平名)。
  typedef enum logic {
    OUT_CACHECTRL = 1'b0,  // out0: 缓存控制寄存器区 (AddressSet 0x38022000/0x7f)
    OUT_DEFAULT   = 1'b1   // out1: 默认 catch-all 从口 (CacheCtrl 的补集)
  } out_port_e;

  // D 通道仲裁器相位 (由 beatsLeft 推出): 单拍配置下恒为 ARB_IDLE。
  typedef enum logic {
    ARB_IDLE   = 1'b0,  // 空闲: 每拍重新仲裁
    ARB_LOCKED = 1'b1   // 锁定: 多拍消息进行中, 维持上一拍胜者 (本变体不会进入)
  } arb_phase_e;

  // D 通道应答载荷 (TileLink-C Grant/AccessAck 等关心的字段)。两个从口字段对称。
  typedef struct packed {
    logic [3:0]  opcode;
    logic [1:0]  param;
    logic [1:0]  size;
    logic [1:0]  source;
    logic        sink;
    logic        denied;
    logic [63:0] data;
    logic        corrupt;
  } tl_d_bits_t;

  // ---------------------------------------------------------------------------
  //  地址映射 —— out0 由 Scala 的 AddressSet(base, mask) 解码:
  //    CacheCtrl: (addr & ~0x7f) == 0x38022000  → [0x38022000, 0x38022080)
  //  out1 = 该集合在 48 位空间内的补集 (默认 catch-all)。firtool 把 out1 展开成一长
  //  串按 2 的幂对齐的 AddressSet 段 (覆盖全空间挖去 CacheCtrl 这 128 字节的洞), 与
  //  "整个 48 位地址空间 \ CacheCtrl" 逐位等价, 故本重写直接取补集 ~request[out0]。
  // ---------------------------------------------------------------------------
  localparam int            ADDR_WIDTH      = 48;
  localparam logic [47:0]   CACHECTRL_MASK  = 48'h7F;          // care = ~mask
  localparam logic [47:0]   CACHECTRL_BASE  = 48'h3802_2000;

  localparam int            DATA_WIDTH      = 64;

endpackage
