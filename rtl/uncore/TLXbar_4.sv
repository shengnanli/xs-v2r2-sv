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

  // 数据通路位宽 (A/D 共用)。
  localparam int            DATA_WIDTH      = 64;

  // ---------------------------------------------------------------------------
  //  TileLink 字段位宽 —— 本口的所有位宽只在这里写一次
  // ---------------------------------------------------------------------------
  //  ★ TL_SOURCE_W 是 G0->G1 这一轮唯一改动的位宽：source id 2 → 4 位 ★
  //  source 是 TL 事务标签（谁发的请求，用于把 D 应答对回主口），本层只透传、
  //  不解释它，所以"写窄了"在逻辑上一行都不会错、随机激励也未必打得到高位 ——
  //  UT 照样 errors=0，只有 FM 才炸。下面的 GOLDEN_D_MUX_ZERO_BITS 等式就是
  //  为此设的 elaborate 期防呆闸（详见核里的自检块）。
  localparam int A_OPCODE_W = 4;
  localparam int A_PARAM_W  = 3;
  localparam int A_SIZE_W   = 2;
  localparam int TL_SOURCE_W = 4;   // A/D 共用的 source id 位宽（G0 是 2）
  localparam int D_OPCODE_W = 4;
  localparam int D_PARAM_W  = 2;
  localparam int D_SIZE_W   = 2;
  localparam int MASK_W     = 8;

  // ---------------------------------------------------------------------------
  //  ★ 从 G1 golden 现读的机器可查常量（不是从上面推出来的）★
  //  golden 的 D 通道 one-hot 归约 mux 里，每个**多位**字段各写了一条 `N'h0`
  //  常量（TLXbar_4.sv:285/288/291/294/301），N 就是该字段的位宽：
  //      opcode 4 + param 2 + size 2 + source 4 + data 64 = 76
  //  机械提取方式（可复跑）：
  //      grep -o "assign auto_in_d_bits_[a-z]* =.*" golden/TLXbar_4.sv 里的 N'h0
  //  这是与端口声明**互相独立的第二处 golden 证据**：核里用它做位宽求和等式，
  //  source 写回 2 位 ⇒ 76 变 74 ⇒ elaborate 期 $fatal。
  // ---------------------------------------------------------------------------
  localparam int GOLDEN_D_MUX_ZERO_BITS = 76;

  // D 通道应答载荷 (TileLink-C Grant/AccessAck 等关心的字段)。两个从口字段对称。
  typedef struct packed {
    logic [D_OPCODE_W-1:0]  opcode;
    logic [D_PARAM_W-1:0]   param;
    logic [D_SIZE_W-1:0]    size;
    logic [TL_SOURCE_W-1:0] source;
    logic                   sink;
    logic                   denied;
    logic [DATA_WIDTH-1:0]  data;
    logic                   corrupt;
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

endpackage

// =============================================================================
//  TLXbar_4 —— 香山 V2R2 TileLink-C 交叉开关 (可读重写核 xs_TLXbar_4_core)
// -----------------------------------------------------------------------------
//  源自 rocket-chip TLXbar (src/main/scala/tilelink/Xbar.scala): 1 主口 (in) ×
//  2 从口 (out0=CacheCtrl 寄存器区, out1=默认 catch-all 总线)。从设计意图重写
//  (不是照抄 firtool 优化后的逐位掩码), 算法依据:
//    · A 通道 (主→从): 地址译码 = 该地址落在哪个从口的 AddressSet ⇒ 路由 + 透传。
//      单主口故无 A 仲裁 (Arbiter sources.size==1 退化为直连)。
//    · D 通道 (从→主): TLArbiter.roundRobin 轮转仲裁 (Arbiter.scala) 把两个从口
//      的应答择一回送主口; 配 beat 计数 + 锁定 (本变体单拍, 锁定逻辑退化)。
//
//  ---------------------------------------------------------------------------
//  round-robin 仲裁算法 (Arbiter.scala 的 roundRobin policy, 通用重写, 与 tlxbar3
//  完全同算法, 仅 NUM_OUT/载荷宽度不同):
//    mask   : 优先级掩码寄存器 (RegInit 全 1); 已被服务者下一轮降到最低优先级。
//    filter = {valid & ~mask, valid}            (2N 位)
//    unready= (rightOR(filter)>>1) | (mask<<N)   (前缀 OR, 求"被更高优先者抢占")
//    grant  = ~( unready[2N-1:N] & unready[N-1:0] )   (N 位 one-hot 授权)
//    胜者更新: 若本拍 latch 且有请求, mask <= leftOR(grant & valid)。
//
//  ---------------------------------------------------------------------------
//  验证: golden 同名 TLXbar_4 例化本核 (端口透传)。无子模块 (叶子), UT 双例化逐拍
//  比对全部输出; FM 签名分析证组合/时序等价。
// =============================================================================

module xs_TLXbar_4_core
  import tlxbar4_pkg::*;
#(
  // ---- 位宽参数（默认 = tlxbar4_pkg 的 G1 值）----
  //  参数化的唯一目的：让"错参数必失败"的负测能把 SOURCE_W 传回 G0 旧值 2，
  //  证明下面的宽度等式自检真有牙齿。生产例化一律用默认值。
  parameter int SOURCE_W = TL_SOURCE_W,
  // ---- 自检等式右手边：从 golden 现读的常量（见 tlxbar4_pkg 里的提取说明）----
  parameter int GOLDEN_D_ZERO_BITS = GOLDEN_D_MUX_ZERO_BITS
)(
  input         clock,
  input         reset,

  // ---- 主口 in (上游) : A=请求(入), D=应答(出) ----
  output        auto_in_a_ready,
  input         auto_in_a_valid,
  input  [3:0]  auto_in_a_bits_opcode,
  input  [2:0]  auto_in_a_bits_param,
  input  [1:0]  auto_in_a_bits_size,
  input  [SOURCE_W-1:0] auto_in_a_bits_source,
  input  [47:0] auto_in_a_bits_address,
  input         auto_in_a_bits_user_memPageType_NC,
  input         auto_in_a_bits_user_memBackType_MM,
  input  [7:0]  auto_in_a_bits_mask,
  input  [63:0] auto_in_a_bits_data,
  input         auto_in_a_bits_corrupt,
  input         auto_in_d_ready,
  output        auto_in_d_valid,
  output [3:0]  auto_in_d_bits_opcode,
  output [1:0]  auto_in_d_bits_param,
  output [1:0]  auto_in_d_bits_size,
  output [SOURCE_W-1:0] auto_in_d_bits_source,
  output        auto_in_d_bits_sink,
  output        auto_in_d_bits_denied,
  output [63:0] auto_in_d_bits_data,
  output        auto_in_d_bits_corrupt,

  // ---- 从口 out1 = OUT_DEFAULT (默认 catch-all, 48 位全地址, 携带 user NC/MM) ----
  input         auto_out_1_a_ready,
  output        auto_out_1_a_valid,
  output [3:0]  auto_out_1_a_bits_opcode,
  output [2:0]  auto_out_1_a_bits_param,
  output [1:0]  auto_out_1_a_bits_size,
  output [SOURCE_W-1:0] auto_out_1_a_bits_source,
  output [47:0] auto_out_1_a_bits_address,
  output        auto_out_1_a_bits_user_memBackType_MM,
  output        auto_out_1_a_bits_user_memPageType_NC,
  output [7:0]  auto_out_1_a_bits_mask,
  output [63:0] auto_out_1_a_bits_data,
  output        auto_out_1_a_bits_corrupt,
  output        auto_out_1_d_ready,
  input         auto_out_1_d_valid,
  input  [3:0]  auto_out_1_d_bits_opcode,
  input  [1:0]  auto_out_1_d_bits_param,
  input  [1:0]  auto_out_1_d_bits_size,
  input  [SOURCE_W-1:0] auto_out_1_d_bits_source,
  input         auto_out_1_d_bits_sink,
  input         auto_out_1_d_bits_denied,
  input  [63:0] auto_out_1_d_bits_data,
  input         auto_out_1_d_bits_corrupt,

  // ---- 从口 out0 = OUT_CACHECTRL (缓存控制寄存器区, 30 位地址, 无 user 字段) ----
  input         auto_out_0_a_ready,
  output        auto_out_0_a_valid,
  output [3:0]  auto_out_0_a_bits_opcode,
  output [2:0]  auto_out_0_a_bits_param,
  output [1:0]  auto_out_0_a_bits_size,
  output [SOURCE_W-1:0] auto_out_0_a_bits_source,
  output [29:0] auto_out_0_a_bits_address,
  output [7:0]  auto_out_0_a_bits_mask,
  output [63:0] auto_out_0_a_bits_data,
  output        auto_out_0_a_bits_corrupt,
  output        auto_out_0_d_ready,
  input         auto_out_0_d_valid,
  input  [3:0]  auto_out_0_d_bits_opcode,
  input  [1:0]  auto_out_0_d_bits_param,
  input  [1:0]  auto_out_0_d_bits_size,
  input  [SOURCE_W-1:0] auto_out_0_d_bits_source,
  input         auto_out_0_d_bits_sink,
  input         auto_out_0_d_bits_denied,
  input  [63:0] auto_out_0_d_bits_data,
  input         auto_out_0_d_bits_corrupt
);

  // ===========================================================================
  //  宽度等式自检 —— 把"位宽写错但逻辑全对"变成 elaborate 期硬失败
  // ---------------------------------------------------------------------------
  //  本轮 G0->G1 对 TLXbar_4 的唯一实质改动是 source id 2→4 位（6 个端口）。
  //  这类改动在"剥掉端口表再比模块体"的机械迁移判据下是**隐形**的，而 tb 只驱动
  //  低 2 位时 UT 也照样 errors=0 —— 只有 FM 才炸。下面这条求和等式的右手边是
  //  从 golden 的 D 通道 mux 常量里现读的 76 位（与端口声明相互独立的第二处证据），
  //  source 写回 2 位就立刻 $fatal。
  //  负测见 verif/ut/TLXbar_4/negtest_width.sv（故意传 SOURCE_W=2，必须 $fatal）。
  // ===========================================================================
  initial begin
    if (D_OPCODE_W + D_PARAM_W + D_SIZE_W + SOURCE_W + DATA_WIDTH != GOLDEN_D_ZERO_BITS)
      $fatal(1, "xs_TLXbar_4_core: D 多位字段合计 %0d 位 != golden D-mux 常量合计 %0d 位（source=%0d 写错了？）",
             D_OPCODE_W + D_PARAM_W + D_SIZE_W + SOURCE_W + DATA_WIDTH,
             GOLDEN_D_ZERO_BITS, SOURCE_W);
    if (SOURCE_W != TL_SOURCE_W)
      $fatal(1, "xs_TLXbar_4_core: 端口 SOURCE_W=%0d 与包里 tl_d_bits_t.source 的 %0d 位不一致",
             SOURCE_W, TL_SOURCE_W);
    if (MASK_W * 8 != DATA_WIDTH)
      $fatal(1, "xs_TLXbar_4_core: MASK_W=%0d 与 DATA_WIDTH=%0d 不是字节掩码关系",
             MASK_W, DATA_WIDTH);
  end

  // ===========================================================================
  //  前缀 OR 工具 (rocket-chip util.leftOR / util.rightOR 的通用实现)
  // ---------------------------------------------------------------------------
  //  leftOR(x)[i]  = OR(x[i:0])     —— 把最低置位向高位 (左) 传播;
  //  rightOR(x)[i] = OR(x[..:i])    —— 把置位向低位 (右) 传播。
  //  Scala 中 rightOR(filter, 2N, cap=N) 只做到 log2(N) 步, 故循环上界用 NUM_OUT。
  // ===========================================================================
  function automatic logic [NUM_OUT-1:0] left_or(input logic [NUM_OUT-1:0] x);
    logic [NUM_OUT-1:0] r;
    r = x;
    for (int s = 1; s < NUM_OUT; s = s << 1) r = r | (r << s);
    return r;
  endfunction

  function automatic logic [2*NUM_OUT-1:0] right_or_capped(input logic [2*NUM_OUT-1:0] x);
    logic [2*NUM_OUT-1:0] r;
    r = x;
    for (int s = 1; s < NUM_OUT; s = s << 1) r = r | (r >> s);
    return r;
  endfunction

  // round-robin 授权: 输入各源 valid 与优先级 mask, 输出 one-hot grant。
  function automatic logic [NUM_OUT-1:0] rr_grant(input logic [NUM_OUT-1:0] valid,
                                                  input logic [NUM_OUT-1:0] mask);
    logic [2*NUM_OUT-1:0] filter, unready;
    filter  = {(valid & ~mask), valid};
    unready = (right_or_capped(filter) >> 1)
            | ({{NUM_OUT{1'b0}}, mask} << NUM_OUT);
    return ~(unready[2*NUM_OUT-1 -: NUM_OUT] & unready[NUM_OUT-1:0]);
  endfunction

  // ===========================================================================
  //  A 通道: 地址译码 + 路由
  // ---------------------------------------------------------------------------
  //  request[OUT_CACHECTRL] = 地址 ∈ AddressSet(0x38022000, 0x7f);
  //  request[OUT_DEFAULT]   = 其补集 (默认 catch-all)。
  // ===========================================================================
  wire to_cachectrl =
       (auto_in_a_bits_address & ~CACHECTRL_MASK) == CACHECTRL_BASE;

  logic [NUM_OUT-1:0] request;             // 按从口编号: [OUT_CACHECTRL]/[OUT_DEFAULT]
  assign request[OUT_CACHECTRL] = to_cachectrl;
  assign request[OUT_DEFAULT]   = ~to_cachectrl;

  // 各从口 A 通道 ready (供 in_a_ready 汇聚)。
  logic [NUM_OUT-1:0] out_a_ready;
  assign out_a_ready[OUT_CACHECTRL] = auto_out_0_a_ready;
  assign out_a_ready[OUT_DEFAULT]   = auto_out_1_a_ready;

  // 主口 A ready = 命中从口已就绪 (单主口, 无需仲裁)。
  assign auto_in_a_ready = |(request & out_a_ready);

  // 从口 A valid = 主口有请求且地址命中本口; 载荷透传。
  //  out0 (CacheCtrl): 30 位地址截断, 不携带 user(NC/MM);
  //  out1 (Default)  : 48 位全地址, 携带 user(NC/MM)。
  assign auto_out_0_a_valid        = auto_in_a_valid & request[OUT_CACHECTRL];
  assign auto_out_0_a_bits_opcode  = auto_in_a_bits_opcode;
  assign auto_out_0_a_bits_param   = auto_in_a_bits_param;
  assign auto_out_0_a_bits_size    = auto_in_a_bits_size;
  assign auto_out_0_a_bits_source  = auto_in_a_bits_source;
  assign auto_out_0_a_bits_address = auto_in_a_bits_address[29:0];   // 30 位截断
  assign auto_out_0_a_bits_mask    = auto_in_a_bits_mask;
  assign auto_out_0_a_bits_data    = auto_in_a_bits_data;
  assign auto_out_0_a_bits_corrupt = auto_in_a_bits_corrupt;

  assign auto_out_1_a_valid        = auto_in_a_valid & request[OUT_DEFAULT];
  assign auto_out_1_a_bits_opcode  = auto_in_a_bits_opcode;
  assign auto_out_1_a_bits_param   = auto_in_a_bits_param;
  assign auto_out_1_a_bits_size    = auto_in_a_bits_size;
  assign auto_out_1_a_bits_source  = auto_in_a_bits_source;
  assign auto_out_1_a_bits_address = auto_in_a_bits_address;          // 48 位全址
  assign auto_out_1_a_bits_user_memBackType_MM = auto_in_a_bits_user_memBackType_MM;
  assign auto_out_1_a_bits_user_memPageType_NC = auto_in_a_bits_user_memPageType_NC;
  assign auto_out_1_a_bits_mask    = auto_in_a_bits_mask;
  assign auto_out_1_a_bits_data    = auto_in_a_bits_data;
  assign auto_out_1_a_bits_corrupt = auto_in_a_bits_corrupt;

  // ===========================================================================
  //  D 通道: 把两个从口应答按 round-robin 择一回送主口
  // ---------------------------------------------------------------------------
  //  打包从口 D 信号为 valid 向量 + 载荷结构数组 (两口字段对称), 便于 one-hot 归约。
  // ===========================================================================
  logic [NUM_OUT-1:0] d_valid;
  tl_d_bits_t         d_bits [NUM_OUT];

  assign d_valid[OUT_CACHECTRL] = auto_out_0_d_valid;
  assign d_valid[OUT_DEFAULT]   = auto_out_1_d_valid;
  assign d_bits[OUT_CACHECTRL]  = '{opcode:  auto_out_0_d_bits_opcode,
                                    param:   auto_out_0_d_bits_param,
                                    size:    auto_out_0_d_bits_size,
                                    source:  auto_out_0_d_bits_source,
                                    sink:    auto_out_0_d_bits_sink,
                                    denied:  auto_out_0_d_bits_denied,
                                    data:    auto_out_0_d_bits_data,
                                    corrupt: auto_out_0_d_bits_corrupt};
  assign d_bits[OUT_DEFAULT]    = '{opcode:  auto_out_1_d_bits_opcode,
                                    param:   auto_out_1_d_bits_param,
                                    size:    auto_out_1_d_bits_size,
                                    source:  auto_out_1_d_bits_source,
                                    sink:    auto_out_1_d_bits_sink,
                                    denied:  auto_out_1_d_bits_denied,
                                    data:    auto_out_1_d_bits_data,
                                    corrupt: auto_out_1_d_bits_corrupt};

  // ---- 仲裁状态 ----
  reg                 beatsLeft;       // 当前消息剩余 beat (单拍配置恒 0)
  reg [NUM_OUT-1:0]   prio_mask;       // round-robin 优先级掩码 (RegInit 全 1)
  reg [NUM_OUT-1:0]   lock_state;      // 锁定的胜者 one-hot (多拍用, 本变体不生效)

  wire arb_idle = ~beatsLeft;                         // ARB_IDLE
  wire latch    = arb_idle & auto_in_d_ready;         // 空闲且下游可收 ⇒ 本拍定胜负

  // 本拍授权与胜者 (one-hot)。
  wire [NUM_OUT-1:0] grant  = rr_grant(d_valid, prio_mask);
  wire [NUM_OUT-1:0] winner = grant & d_valid;

  // 锁定后维持上一拍胜者; 空闲时用本拍胜者/授权 (单主单拍下 muxSel==winner)。
  wire [NUM_OUT-1:0] mux_sel = arb_idle ? winner : lock_state;
  wire [NUM_OUT-1:0] allowed = arb_idle ? grant   : lock_state;

  // 主口 D valid: 空闲时只要任一从口有应答; 锁定时仅看被锁从口。
  assign auto_in_d_valid = arb_idle ? (|d_valid) : (|(lock_state & d_valid));

  // 从口 D ready = 主口可收且本口被授权。
  assign auto_out_0_d_ready = auto_in_d_ready & allowed[OUT_CACHECTRL];
  assign auto_out_1_d_ready = auto_in_d_ready & allowed[OUT_DEFAULT];

  // 主口 D 载荷: 按 mux_sel 做 one-hot 选择 (至多一个从口被选, OR 归约即多路选择)。
  tl_d_bits_t d_sel;
  always_comb begin
    d_sel = '0;
    for (int o = 0; o < NUM_OUT; o++)
      if (mux_sel[o]) d_sel |= d_bits[o];
  end
  assign auto_in_d_bits_opcode  = d_sel.opcode;
  assign auto_in_d_bits_param   = d_sel.param;
  assign auto_in_d_bits_size    = d_sel.size;
  assign auto_in_d_bits_source  = d_sel.source;
  assign auto_in_d_bits_sink    = d_sel.sink;
  assign auto_in_d_bits_denied  = d_sel.denied;
  assign auto_in_d_bits_data    = d_sel.data;
  assign auto_in_d_bits_corrupt = d_sel.corrupt;

  // ---- 时序: beat 计数 / 优先级掩码轮转 / 胜者锁定 ----
  //  init_beats = 本拍胜者的 numBeats1; 本口恒单拍 ⇒ 0。
  wire init_beats   = 1'b0;
  wire sink_fire    = auto_in_d_ready & auto_in_d_valid;
  wire any_valid    = |d_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      beatsLeft  <= 1'b0;
      prio_mask  <= {NUM_OUT{1'b1}};                 // 初始全 1 (谁都可先)
      lock_state <= '0;
    end else begin
      beatsLeft  <= latch ? init_beats : (beatsLeft - sink_fire);
      if (latch & any_valid)
        prio_mask <= left_or(grant & d_valid);       // 胜者降为最低优先级
      lock_state <= mux_sel;                          // 空闲锁本拍胜者, 否则维持
    end
  end

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module TLXbar_4(
  input clock,
  input reset,
  output auto_in_a_ready,
  input auto_in_a_valid,
  input [3:0] auto_in_a_bits_opcode,
  input [2:0] auto_in_a_bits_param,
  input [1:0] auto_in_a_bits_size,
  input [3:0] auto_in_a_bits_source,
  input [47:0] auto_in_a_bits_address,
  input auto_in_a_bits_user_memPageType_NC,
  input auto_in_a_bits_user_memBackType_MM,
  input [7:0] auto_in_a_bits_mask,
  input [63:0] auto_in_a_bits_data,
  input auto_in_a_bits_corrupt,
  input auto_in_d_ready,
  output auto_in_d_valid,
  output [3:0] auto_in_d_bits_opcode,
  output [1:0] auto_in_d_bits_param,
  output [1:0] auto_in_d_bits_size,
  output [3:0] auto_in_d_bits_source,
  output auto_in_d_bits_sink,
  output auto_in_d_bits_denied,
  output [63:0] auto_in_d_bits_data,
  output auto_in_d_bits_corrupt,
  input auto_out_1_a_ready,
  output auto_out_1_a_valid,
  output [3:0] auto_out_1_a_bits_opcode,
  output [2:0] auto_out_1_a_bits_param,
  output [1:0] auto_out_1_a_bits_size,
  output [3:0] auto_out_1_a_bits_source,
  output [47:0] auto_out_1_a_bits_address,
  output auto_out_1_a_bits_user_memBackType_MM,
  output auto_out_1_a_bits_user_memPageType_NC,
  output [7:0] auto_out_1_a_bits_mask,
  output [63:0] auto_out_1_a_bits_data,
  output auto_out_1_a_bits_corrupt,
  output auto_out_1_d_ready,
  input auto_out_1_d_valid,
  input [3:0] auto_out_1_d_bits_opcode,
  input [1:0] auto_out_1_d_bits_param,
  input [1:0] auto_out_1_d_bits_size,
  input [3:0] auto_out_1_d_bits_source,
  input auto_out_1_d_bits_sink,
  input auto_out_1_d_bits_denied,
  input [63:0] auto_out_1_d_bits_data,
  input auto_out_1_d_bits_corrupt,
  input auto_out_0_a_ready,
  output auto_out_0_a_valid,
  output [3:0] auto_out_0_a_bits_opcode,
  output [2:0] auto_out_0_a_bits_param,
  output [1:0] auto_out_0_a_bits_size,
  output [3:0] auto_out_0_a_bits_source,
  output [29:0] auto_out_0_a_bits_address,
  output [7:0] auto_out_0_a_bits_mask,
  output [63:0] auto_out_0_a_bits_data,
  output auto_out_0_a_bits_corrupt,
  output auto_out_0_d_ready,
  input auto_out_0_d_valid,
  input [3:0] auto_out_0_d_bits_opcode,
  input [1:0] auto_out_0_d_bits_param,
  input [1:0] auto_out_0_d_bits_size,
  input [3:0] auto_out_0_d_bits_source,
  input auto_out_0_d_bits_sink,
  input auto_out_0_d_bits_denied,
  input [63:0] auto_out_0_d_bits_data,
  input auto_out_0_d_bits_corrupt
);
  xs_TLXbar_4_core u_core (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_param(auto_in_a_bits_param),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_user_memPageType_NC(auto_in_a_bits_user_memPageType_NC),
    .auto_in_a_bits_user_memBackType_MM(auto_in_a_bits_user_memBackType_MM),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(auto_in_a_bits_corrupt),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(auto_in_d_valid),
    .auto_in_d_bits_opcode(auto_in_d_bits_opcode),
    .auto_in_d_bits_param(auto_in_d_bits_param),
    .auto_in_d_bits_size(auto_in_d_bits_size),
    .auto_in_d_bits_source(auto_in_d_bits_source),
    .auto_in_d_bits_sink(auto_in_d_bits_sink),
    .auto_in_d_bits_denied(auto_in_d_bits_denied),
    .auto_in_d_bits_data(auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(auto_in_d_bits_corrupt),
    .auto_out_1_a_ready(auto_out_1_a_ready),
    .auto_out_1_a_valid(auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_param(auto_out_1_a_bits_param),
    .auto_out_1_a_bits_size(auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source(auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address(auto_out_1_a_bits_address),
    .auto_out_1_a_bits_user_memBackType_MM(auto_out_1_a_bits_user_memBackType_MM),
    .auto_out_1_a_bits_user_memPageType_NC(auto_out_1_a_bits_user_memPageType_NC),
    .auto_out_1_a_bits_mask(auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data(auto_out_1_a_bits_data),
    .auto_out_1_a_bits_corrupt(auto_out_1_a_bits_corrupt),
    .auto_out_1_d_ready(auto_out_1_d_ready),
    .auto_out_1_d_valid(auto_out_1_d_valid),
    .auto_out_1_d_bits_opcode(auto_out_1_d_bits_opcode),
    .auto_out_1_d_bits_param(auto_out_1_d_bits_param),
    .auto_out_1_d_bits_size(auto_out_1_d_bits_size),
    .auto_out_1_d_bits_source(auto_out_1_d_bits_source),
    .auto_out_1_d_bits_sink(auto_out_1_d_bits_sink),
    .auto_out_1_d_bits_denied(auto_out_1_d_bits_denied),
    .auto_out_1_d_bits_data(auto_out_1_d_bits_data),
    .auto_out_1_d_bits_corrupt(auto_out_1_d_bits_corrupt),
    .auto_out_0_a_ready(auto_out_0_a_ready),
    .auto_out_0_a_valid(auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param(auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size(auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source(auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address(auto_out_0_a_bits_address),
    .auto_out_0_a_bits_mask(auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data(auto_out_0_a_bits_data),
    .auto_out_0_a_bits_corrupt(auto_out_0_a_bits_corrupt),
    .auto_out_0_d_ready(auto_out_0_d_ready),
    .auto_out_0_d_valid(auto_out_0_d_valid),
    .auto_out_0_d_bits_opcode(auto_out_0_d_bits_opcode),
    .auto_out_0_d_bits_param(auto_out_0_d_bits_param),
    .auto_out_0_d_bits_size(auto_out_0_d_bits_size),
    .auto_out_0_d_bits_source(auto_out_0_d_bits_source),
    .auto_out_0_d_bits_sink(auto_out_0_d_bits_sink),
    .auto_out_0_d_bits_denied(auto_out_0_d_bits_denied),
    .auto_out_0_d_bits_data(auto_out_0_d_bits_data),
    .auto_out_0_d_bits_corrupt(auto_out_0_d_bits_corrupt)
  );
endmodule
