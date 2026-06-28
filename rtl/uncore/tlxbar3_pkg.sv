// =============================================================================
//  tlxbar3_pkg —— TLXbar_3 (1 主 × 2 从 TileLink-UL 交叉开关) 常量与类型
// -----------------------------------------------------------------------------
//  对应 rocket-chip 的 TLXbar (src/main/scala/tilelink/Xbar.scala), 本变体是一个
//  最小 TileLink-UL 外设交叉开关: 1 个上游主口 (in) 把单字 (32 位) 读写按地址
//  分发给 2 个下游从口:
//    out0 (OUT_MAIN) : 默认/主区间, 9 位地址, 应答含 denied/corrupt;
//    out1 (OUT_DEV)  : 一小块设备区间 (16 个地址), 7 位地址, 应答仅 data。
//
//  该口无 size/source/mask 字段 ⇒ 每次访问恒为单拍 (single-beat), D 通道仲裁器的
//  beat 计数/锁定逻辑因而退化 (恒处 idle), 仅 round-robin 公平掩码真正起作用。
// =============================================================================
package tlxbar3_pkg;

  // 下游从口数量 (本变体固定 2)。
  localparam int NUM_OUT = 2;

  // 从口编号 (语义命名, 取代 golden 的 out_0/out_1 展平名)。
  typedef enum logic {
    OUT_MAIN = 1'b0,   // out0: 默认主区间从设备 (catch-all)
    OUT_DEV  = 1'b1    // out1: 专属设备小区间
  } out_port_e;

  // D 通道仲裁器相位 (由 beatsLeft 推出): 单拍配置下恒为 ARB_IDLE。
  typedef enum logic {
    ARB_IDLE   = 1'b0,  // 空闲: 每拍重新仲裁
    ARB_LOCKED = 1'b1   // 锁定: 多拍消息进行中, 维持上一拍胜者 (本变体不会进入)
  } arb_phase_e;

  // D 通道应答载荷 (TileLink-UL 的 AccessAck/AccessAckData 关心的字段)。
  // 设备从口 (OUT_DEV) 无 denied/corrupt, 打包时填 0。
  typedef struct packed {
    logic [31:0] data;     // 读数据 (写应答时无意义)
    logic        denied;   // 访问被拒
    logic        corrupt;  // 数据损坏
  } tl_d_bits_t;

  // ---------------------------------------------------------------------------
  //  out1 (OUT_DEV) 的地址映射 —— 由 Scala 的 AddressSet(base, mask) 解码而来,
  //  在 9 位地址空间内由两段构成 (care-mask 为 1 的位需匹配 base, 为 0 的位任意):
  //    段 a: (addr & 0x1F4) == 0x040  → {0x40-0x43, 0x48-0x4B}  (8 个地址)
  //    段 b: (addr & 0x1F8) == 0x050  → {0x50-0x57}             (8 个地址)
  //  共 16 个地址。其余全部地址路由到 out0 (OUT_MAIN), 即 out0 = 该集合的补集。
  // ---------------------------------------------------------------------------
  localparam int IN_ADDR_WIDTH = 9;
  localparam logic [8:0] DEV_A_MASK = 9'h1F4, DEV_A_BASE = 9'h040;
  localparam logic [8:0] DEV_B_MASK = 9'h1F8, DEV_B_BASE = 9'h050;

  localparam int DATA_WIDTH = 32;

endpackage
