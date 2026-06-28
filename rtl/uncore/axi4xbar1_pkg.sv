// =============================================================================
//  axi4xbar1_pkg —— AXI4Xbar_1 (1 主 × 5 从 AXI4 交叉开关) 常量与类型
// -----------------------------------------------------------------------------
//  对应 rocket-chip 的 AXI4Xbar (src/main/scala/amba/axi4/Xbar.scala)。本变体是香山
//  仿真外设总线 SimMMIO 的 AXI 交叉开关: 1 个上游主口 (auto_in) 把 5 通道 AXI4 访问
//  (AW 写地址 / W 写数据 / B 写响应 / AR 读地址 / R 读数据) 按地址分发给 5 个从口:
//    out_0 (OUT_UART)    : UART      AddressSet(0x40600000, 0xf)   = 16B  (addr 31 位)
//    out_1 (OUT_FLASH)   : Flash     AddressSet(0x10000000, 0xfffffff) = 256MB (addr 截 29 位)
//    out_2 (OUT_SD)      : SD        AddressSet(0x40002000, 0xfff)  = 4KB  (addr 31 位)
//    out_3 (OUT_INTRGEN) : IntrGen   AddressSet(0x40070000, 0xffff) = 64KB (addr 31 位)
//    out_4 (OUT_ERROR)   : 错误从口  (前四者补集, AXI4Error): B 永远 DECERR, R 永远
//                          {DECERR, last, data=0}; 仅有 id 端口 (回显请求 id)。
//
//  相对单主 TLXbar 的 AXI 关键增量 (本核重点重写的"AXI 通道协议"):
//    1) 五通道, AW/W 分离: W 数据须跟随对应 AW 的从口路由 ⇒ 用一个深度 2 的路由
//       队列 awIn (Queue2_UInt5, 黑盒) 记录每个 AW 命中的从口 one-hot, W 按队首出队的
//       路由分发; latched 寄存器处理 AW 入队与下发从口的握手错拍。
//    2) 按 ID 顺序保持 (per-ID FIFO map): 每个 AXI ID (本变体 4 个) 维护 count(在飞)
//       与 last(锁定从口 tag)。同一 ID 的新请求只允许发往 count==0 (可任选) 或与在飞
//       请求相同从口 (last==tag), 且 count 未满 (flight=7); 防止不同从口的响应交错
//       破坏 AXI 同 ID 响应顺序。
//    3) R / B 响应各做 5 路 round-robin 仲裁 (stall 时 idle 寄存器锁定当拍胜者稳定)。
//
//  验证: golden 同名 AXI4Xbar_1 例化本核 (端口透传) + 黑盒 Queue2_UInt5/ram_2x5。
// =============================================================================
package axi4xbar1_pkg;

  localparam int NUM_OUT = 5;   // 从口数
  localparam int NUM_ID  = 4;   // AXI ID 数 (id 宽 2 位)
  localparam int MAXN    = 5;   // round-robin 通用算法位宽 (= NUM_OUT)
  localparam int FLIGHT  = 7;   // 每 ID 最大在飞数 (count 3 位, 满=7 后拒新请求)

  // 从口编号 (语义命名, 取代 golden 的 out_0..out_4 展平名)。
  typedef enum int unsigned {
    OUT_UART    = 0,  // 0x40600000 / 16B
    OUT_FLASH   = 1,  // 0x10000000 / 256MB (从口地址截到 29 位)
    OUT_SD      = 2,  // 0x40002000 / 4KB
    OUT_INTRGEN = 3,  // 0x40070000 / 64KB
    OUT_ERROR   = 4   // catch-all 错误从口 (返回 DECERR)
  } out_port_e;

  // AW / AR 通道载荷 (地址 31 位; Flash 从口输出时截到低 29 位)。
  typedef struct packed {
    logic [1:0]  id;
    logic [30:0] addr;
    logic [7:0]  len;
    logic [2:0]  size;
    logic [1:0]  burst;
    logic        lock;
    logic [3:0]  cache;
    logic [2:0]  prot;
    logic [3:0]  qos;
  } axi_ax_t;

  // B 通道载荷 (写响应)。
  typedef struct packed {
    logic [1:0]  id;
    logic [1:0]  resp;
  } axi_b_t;

  // R 通道载荷 (读数据)。
  typedef struct packed {
    logic [1:0]  id;
    logic [63:0] data;
    logic [1:0]  resp;
    logic        last;
  } axi_r_t;

  // ---------------------------------------------------------------------------
  //  地址译码常量 (来自 SimMMIO.scala / SoC.scala 的 AddressSet)。错误从口取补集。
  //    UART   : addr[30:4]  == 0x4060000
  //    SD     : addr[30:12] == 0x40002
  //    IntrGen: addr[30:16] == 0x4007
  //    Flash  : addr[30:29] == 0 && addr[28] == 1   ⇔ [0x10000000, 0x1FFFFFFF]
  //  (FM 会把错误从口的"补集"与 golden 展开的 40+ 项 masked-AddressSet OR 逐位证等价。)
  // ---------------------------------------------------------------------------
  localparam logic [26:0] UART_HI = 27'h4060000;   // addr[30:4]
  localparam logic [18:0] SD_HI   = 19'h40002;     // addr[30:12]
  localparam logic [14:0] INTR_HI = 15'h4007;      // addr[30:16]

  localparam logic [1:0]  RESP_DECERR = 2'b11;     // AXI4Error 固定响应

  // ---------------------------------------------------------------------------
  //  错误从口 (OUT_ERROR / AXI4Error) 的地址集合 —— 关键: 它并非"四设备的全补集",
  //  而是补集与"总线可达空间"的交 (rocket-chip diplomacy 给错误节点分配的 AddressSet
  //  列表)。具体: 不含未映射的 SoC 区 [0x38000000, 0x3FFFFFFF] 中除若干被覆盖子段外
  //  的空洞 (那些地址在本 AXI 总线上无人认领, 主口会因 ready 拉低而停等)。
  //  下表是该 AddressSet 列表的 (care, want) 形式: (addr & care)==want 即命中。WANT
  //  列即各 AddressSet 的基址 (如 0x40600010 = UART 之后, 0x40700000 = IntrGen 之后,
  //  0x41000000.. = 设备区上方整段)。已离线核验本表与 golden 的 req4 在 31 位空间逐位
  //  等价 (3M 随机 0 不符), FM 亦会符号级证等价。
  // ---------------------------------------------------------------------------
  localparam int ERR_N = 59;
  localparam logic [30:0] ERR_CARE [ERR_N] = '{
    31'h50000000, 31'h78000000, 31'h7FFFF000, 31'h7FFFE000, 31'h7FFFC000,
    31'h7FFF8000, 31'h7FFFE000, 31'h7FFFC000, 31'h7FFF8000, 31'h7FFF0000,
    31'h7DFC0000, 31'h7DF80000, 31'h7DF00000, 31'h7DE00000, 31'h7DC00000,
    31'h7D800000, 31'h7D000000, 31'h7FFFF000, 31'h7FFFE000, 31'h7FFFC000,
    31'h7FFF8000, 31'h7FFF0000, 31'h7FFE0000, 31'h7FFFE000, 31'h7FFFF000,
    31'h7FFFC000, 31'h7FFF8000, 31'h7FFF0000, 31'h7FFE0000, 31'h7FFE0000,
    31'h7FFF0000, 31'h7FF80000, 31'h7FF00000, 31'h7FE00000, 31'h7FE00000,
    31'h7FFFFFF0, 31'h7FFFFFE0, 31'h7FFFFFC0, 31'h7FFFFF80, 31'h7FFFFF00,
    31'h7FFFFE00, 31'h7FFFFC00, 31'h7FFFF800, 31'h7FFFF000, 31'h7FFFE000,
    31'h7FFFC000, 31'h7FFF8000, 31'h7FFF0000, 31'h7FFE0000, 31'h7FFC0000,
    31'h7FF80000, 31'h7FF00000, 31'h7F800000, 31'h7F000000, 31'h7E000000,
    31'h7C000000, 31'h78000000, 31'h70000000, 31'h60000000};
  localparam logic [30:0] ERR_WANT [ERR_N] = '{
    31'h00000000, 31'h30000000, 31'h38011000, 31'h38012000, 31'h38014000,
    31'h38018000, 31'h38022000, 31'h38024000, 31'h38028000, 31'h38030000,
    31'h38040000, 31'h38080000, 31'h38100000, 31'h38200000, 31'h38400000,
    31'h38800000, 31'h39000000, 31'h3A001000, 31'h3A002000, 31'h3A004000,
    31'h3A008000, 31'h3A010000, 31'h3A020000, 31'h40000000, 31'h40003000,
    31'h40004000, 31'h40008000, 31'h40010000, 31'h40020000, 31'h40040000,
    31'h40060000, 31'h40080000, 31'h40100000, 31'h40200000, 31'h40400000,
    31'h40600010, 31'h40600020, 31'h40600040, 31'h40600080, 31'h40600100,
    31'h40600200, 31'h40600400, 31'h40600800, 31'h40601000, 31'h40602000,
    31'h40604000, 31'h40608000, 31'h40610000, 31'h40620000, 31'h40640000,
    31'h40680000, 31'h40700000, 31'h40800000, 31'h41000000, 31'h42000000,
    31'h44000000, 31'h48000000, 31'h50000000, 31'h60000000};

endpackage
