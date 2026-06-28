// =============================================================================
//  tlxbar2_pkg —— TLXbar_2 (1 主 × 5 从 TileLink 外设交叉开关) 常量与类型
// -----------------------------------------------------------------------------
//  对应 rocket-chip 的 TLXbar (src/main/scala/tilelink/Xbar.scala)。本变体是香山
//  外设总线上的一个交叉开关: 1 个上游主口 (in) 把 64 位访问按地址分发给 5 个下游
//  从口 out0..out4。30 位地址 (in/out 同宽, 无截断)。
//
//  从口口径不一 (来自各自的 diplomacy 边参数):
//    out4 : 完整 TileLink-C 从口 —— A 带 param/corrupt, D 带 param/sink/denied/
//           corrupt;
//    out0..out3 : TileLink-UL 从口 —— A 仅 opcode/size/source/address/mask/data,
//           D 仅 opcode/size/source/data (无 param/sink/denied/corrupt)。
//  本重写用统一的 D 载荷结构, 对 UL 从口缺失的字段填 0 —— 与 golden 里
//  "param = muxState_4 ? out4_param : 0" 这类"只有 out4 贡献"的写法逐位等价。
//
//  本口访问恒单拍 (firtool 里 beatsLeft 仅 1 位且 init 恒 0), D 通道仲裁器的 beat
//  计数/锁定逻辑退化 (恒 idle), 仅 5 路 round-robin 公平掩码真正起作用 —— 这是本
//  变体相对 tlxbar3/tlxbar4 的核心看点: 把 firtool 展开的多级前缀 OR (_GEN_0/_GEN_1)
//  还原成参数化 rightOR/leftOR 通用算法。
// =============================================================================
package tlxbar2_pkg;

  // 下游从口数量 (本变体固定 5)。
  localparam int NUM_OUT = 5;

  // 从口编号 (语义命名: out4 是唯一的完整 TL-C 从口)。具体连接的外设由 SoC 地址图
  // 决定, 此处按 golden 端口序保留 out0..out4 的编号语义。
  typedef enum logic [2:0] {
    OUT0 = 3'd0,   // TL-UL 从口 (a26=0 & a25=0 & a17=0)
    OUT1 = 3'd1,   // TL-UL 从口 (a26=1)
    OUT2 = 3'd2,   // TL-UL 从口 (a26=0 & a25=1 & a17=0 & a12=0)
    OUT3 = 3'd3,   // TL-UL 从口 (a26=0 & a25=0 & a17=1 & a12=0)
    OUT4 = 3'd4    // TL-C  从口 (a26=0 & a25=0 & a17=1 & a12=1), 唯一带 param/sink/...
  } out_port_e;

  // D 通道仲裁器相位 (由 beatsLeft 推出): 单拍配置下恒为 ARB_IDLE。
  typedef enum logic {
    ARB_IDLE   = 1'b0,  // 空闲: 每拍重新仲裁
    ARB_LOCKED = 1'b1   // 锁定: 多拍消息进行中, 维持上一拍胜者 (本变体不会进入)
  } arb_phase_e;

  // 统一 D 通道应答载荷。UL 从口 (out0..out3) 的 param/sink/denied/corrupt 打包时填 0。
  typedef struct packed {
    logic [3:0]  opcode;
    logic [1:0]  param;
    logic [1:0]  size;
    logic [14:0] source;
    logic        sink;
    logic        denied;
    logic [63:0] data;
    logic        corrupt;
  } tl_d_bits_t;

  localparam int ADDR_WIDTH   = 30;
  localparam int SOURCE_WIDTH = 15;
  localparam int DATA_WIDTH   = 64;

endpackage
