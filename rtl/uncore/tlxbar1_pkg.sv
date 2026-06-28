// =============================================================================
//  tlxbar1_pkg —— TLXbar_1 (2 主 × 3 从 多主 TileLink-UL/UH 交叉开关) 常量与类型
// -----------------------------------------------------------------------------
//  对应 rocket-chip 的 TLXbar (src/main/scala/tilelink/Xbar.scala)。本变体是香山
//  SoC 外设/MMIO 总线上的多主交叉开关: 2 个上游主口仲裁后分发给 3 个下游从口,
//  并支持多拍 (burst) 数据传输 —— 这是相对 TLXbar_6 (单拍) 的关键增量。
//
//  主口 (in):
//    in_0: 完整 TL-UH 主口。source 14 位 (内部零扩展到 15 位 = {1'b0, source});
//          A 通道携带 AMBA prot(user) 与 param/corrupt; D 通道带 14 位 source。
//    in_1: 精简主口。A 通道仅 opcode/size/address/mask/data (无 param/source/user/
//          corrupt); 交叉开关内部给它分配固定 15 位 source = 0x4000 (bit14=1),
//          并在路由到带 user 的从口 out_1 时填默认 AMBA prot = {privileged, secure}=1。
//          D 通道无 source 字段。
//
//  从口 (out) —— 地址映射来自香山 SoC.scala (已离线核验, 见下文 OUT1/OUT2 表):
//    out_0: 高位内存口。req = address[48] (49 位地址全宽透传), 无 user;
//           D 通道极简 (仅 opcode/size/source/corrupt) —— denied 恒 1, 无 data/param/sink。
//    out_1: 外设/MMIO 口 (经 AXI 桥)。31 位地址, 携带 AMBA prot(user);
//           D 通道带 denied/data, 无 param/sink。下游地址集见 OUT1_*。
//    out_2: 片上设备口 (CLINT/PLIC 等)。30 位地址, 无 user, size 截到 2 位;
//           D 通道最全 (param/sink/denied/data 齐全)。下游地址集见 OUT2_*。
//
//  多主仲裁 (与 TLXbar_6 同算法, 复用 rr_grant/left_or/right_or_capped 前缀 OR):
//    · A 通道: 每个从口对"请求它的两主口"做 roundRobin 轮转 (NUM_IN=2);
//    · D 通道: 每个主口对"应答它的三从口"做 roundRobin 轮转 (NUM_OUT=3);
//    · burst: 仲裁器空闲(beatsLeft==0)且下游 ready 时锁存胜者, 按胜者 size/opcode
//      算出剩余拍数 beatsLeft, 整段 burst 期间维持胜者 (state) 不被打断。
// =============================================================================
package tlxbar1_pkg;

  // 主口 / 从口数量, 以及前缀 OR 通用算法的最大位宽 (= max(NUM_IN, NUM_OUT))。
  localparam int NUM_IN  = 2;
  localparam int NUM_OUT = 3;
  localparam int MAXN    = 3;

  // 从口编号 (语义命名, 取代 golden 的 out_0/out_1/out_2 展平名)。
  typedef enum int unsigned {
    OUT_MEM = 0,  // out_0: 高位内存口, req = address[48], 49 位全址
    OUT_MMIO= 1,  // out_1: 外设/MMIO 口 (AXI 桥), 31 位地址, 带 AMBA prot
    OUT_DEV = 2   // out_2: 片上设备口 (CLINT/PLIC 等), 30 位地址
  } out_port_e;

  // 主口编号。
  typedef enum int unsigned {
    IN_0 = 0,   // in_0: 完整 TL-UH 主口, source 内部 = {1'b0, source[13:0]}
    IN_1 = 1    // in_1: 精简主口, source 内部 = 0x4000
  } in_port_e;

  // in_1 在交叉开关内部被分配的固定 15 位 source (bit14=1, 用于 D 回程路由判别)。
  localparam logic [14:0] IN1_SOURCE_ID = 15'h4000;

  // ---------------------------------------------------------------------------
  //  AMBA prot(user) 子结构 —— 仅 out_1 携带; in_0 给实值, in_1 默认 priv+secure。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic bufferable;
    logic modifiable;
    logic readalloc;
    logic writealloc;
    logic privileged;
    logic secure;
    logic fetch;
  } amba_prot_t;

  // ---------------------------------------------------------------------------
  //  A 通道载荷 (主→从) —— 取两主口字段的超集; in_1 缺失字段填默认值。
  //  source 为内部 15 位 ID; address 取 49 位全宽 (窄从口截断到 31/30 位)。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [3:0]  opcode;
    logic [2:0]  param;
    logic [2:0]  size;
    logic [14:0] source;
    logic [48:0] address;
    amba_prot_t  user;
    logic [7:0]  mask;
    logic [63:0] data;
    logic        corrupt;
  } tl_a_t;

  // ---------------------------------------------------------------------------
  //  D 通道载荷 (从→主) —— 取三从口字段的超集; 缺失字段填默认值:
  //    out_0: denied 恒 1, 无 data/param/sink (见核内打包);
  //    out_1: 无 param/sink; out_2: 字段最全 (size 由 2 位零扩展到 3 位)。
  //  source 为 15 位; 回送 in_0 取低 14 位, in_1 无 source 端口 (丢弃)。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [3:0]  opcode;
    logic [1:0]  param;
    logic [2:0]  size;
    logic [14:0] source;
    logic        sink;
    logic        denied;
    logic [63:0] data;
    logic        corrupt;
  } tl_d_t;

  // ---------------------------------------------------------------------------
  //  从口地址译码 (AddressSet 列表) —— req[in][OUT_x] = OR_k (addr & ~MASK[k])==BASE[k]
  //
  //  来自 SoC 的下游 manager 地址集, 经 firtool 拆成对齐的 2 的幂子块。这两张表与
  //  golden 的 requestAIO_*_1 / requestAIO_*_2 逐位等价 (离线对 40 万+随机及结构化
  //  地址交叉验证 0 失配), MASK 标记 don't-care 位 (含恒被忽略的 address[47:31])。
  //
  //  OUT_MEM (out_0) 不在此表: 它的 req = address[48] (高位内存半区), 见核内。
  //
  //  OUT1 (out_1, 外设/MMIO) 25 项: 低位内存大区 [0,0x3800_0000) 的 3 个对齐块 +
  //    0x3801_xxxx/0x3803_xxxx (BEU/L3 配置簇) + 0x3a0x_xxxx 簇 + [0x4000_0000,...) 1GB 区。
  // ---------------------------------------------------------------------------
  localparam int OUT1_NSETS = 25;
  localparam logic [48:0] OUT1_BASE [OUT1_NSETS] = '{
    49'h0000000000000,   // [0x0000_0000, 0x2000_0000)  512MB
    49'h0000020000000,   // [0x2000_0000, 0x3000_0000)  256MB
    49'h0000030000000,   // [0x3000_0000, 0x3800_0000)  128MB
    49'h0000038011000,   // 0x3801_1000  4KB
    49'h0000038012000,   // 0x3801_2000  8KB
    49'h0000038014000,   // 0x3801_4000  16KB
    49'h0000038018000,   // 0x3801_8000  32KB
    49'h0000038022000,   // 0x3802_2000  8KB
    49'h0000038024000,   // 0x3802_4000  16KB
    49'h0000038028000,   // 0x3802_8000  32KB
    49'h0000038030000,   // 0x3803_0000  64KB
    49'h0000038040000,   // 0x3804_0000  (含 bit17 don't-care 子块)
    49'h0000038080000,   // 0x3808_0000
    49'h0000038100000,   // 0x3810_0000
    49'h0000038200000,   // 0x3820_0000
    49'h0000038400000,   // 0x3840_0000
    49'h0000038800000,   // 0x3880_0000
    49'h0000039000000,   // 0x3900_0000
    49'h000003a001000,   // 0x3A00_1000  4KB
    49'h000003a002000,   // 0x3A00_2000  8KB
    49'h000003a004000,   // 0x3A00_4000  16KB
    49'h000003a008000,   // 0x3A00_8000  32KB
    49'h000003a010000,   // 0x3A01_0000  64KB
    49'h000003a020000,   // 0x3A02_0000  128KB
    49'h0000040000000    // [0x4000_0000, 0x8000_0000)  1GB (address[30]=1)
  };
  localparam logic [48:0] OUT1_MASK [OUT1_NSETS] = '{  // don't-care 位
    49'h0ffff9fffffff,
    49'h0ffff8fffffff,
    49'h0ffff87ffffff,
    49'h0ffff80000fff,
    49'h0ffff80001fff,
    49'h0ffff80003fff,
    49'h0ffff80007fff,
    49'h0ffff80001fff,
    49'h0ffff80003fff,
    49'h0ffff80007fff,
    49'h0ffff8000ffff,
    49'h0ffff8203ffff,
    49'h0ffff8207ffff,
    49'h0ffff820fffff,
    49'h0ffff821fffff,
    49'h0ffff823fffff,
    49'h0ffff827fffff,
    49'h0ffff82ffffff,
    49'h0ffff80000fff,
    49'h0ffff80001fff,
    49'h0ffff80003fff,
    49'h0ffff80007fff,
    49'h0ffff8000ffff,
    49'h0ffff8001ffff,
    49'h0ffffbfffffff
  };

  // OUT2 (out_2, 片上设备) 4 项: CLINT(0x3800_0000) + 0x3802_0000 + 0x3A00_0000 +
  //   PLIC(0x3C00_0000, 64MB)。
  localparam int OUT2_NSETS = 4;
  localparam logic [48:0] OUT2_BASE [OUT2_NSETS] = '{
    49'h0000038000000,   // 0x3800_0000  64KB
    49'h0000038020000,   // 0x3802_0000  8KB
    49'h000003a000000,   // 0x3A00_0000  4KB
    49'h000003c000000    // [0x3C00_0000, 0x4000_0000)  64MB
  };
  localparam logic [48:0] OUT2_MASK [OUT2_NSETS] = '{  // don't-care 位
    49'h0ffff8000ffff,
    49'h0ffff80001fff,
    49'h0ffff80000fff,
    49'h0ffff83ffffff
  };

endpackage
