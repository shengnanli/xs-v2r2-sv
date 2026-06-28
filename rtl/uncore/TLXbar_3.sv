// =============================================================================
//  TLXbar_3 —— 香山 V2R2 TileLink-UL 交叉开关 (可读重写核 xs_TLXbar_3_core)
// -----------------------------------------------------------------------------
//  源自 rocket-chip TLXbar (src/main/scala/tilelink/Xbar.scala) 的一个最小实例:
//  1 主口 (in) × 2 从口 (out0=主区间, out1=设备小区间)。从设计意图重写 (不是照抄
//  firtool 优化后的位掩码), 算法依据:
//    · A 通道 (主→从): 地址译码 = 该地址落在哪个从口的 AddressSet ⇒ 路由 + 透传。
//      单主口故无 A 仲裁 (Arbiter sources.size==1 退化为直连)。
//    · D 通道 (从→主): TLArbiter.roundRobin 轮转仲裁 (见 Arbiter.scala) 把两个从口
//      的应答择一回送主口; 配 beat 计数 + 锁定 (本变体单拍, 锁定逻辑退化)。
//
//  ---------------------------------------------------------------------------
//  round-robin 仲裁算法 (Arbiter.scala 的 roundRobin policy, 通用重写):
//    mask   : 优先级掩码寄存器 (RegInit 全 1); 已被服务者下一轮降到最低优先级。
//    filter = {valid & ~mask, valid}            (2N 位)
//    unready= (rightOR(filter)>>1) | (mask<<N)   (前缀 OR, 求"被更高优先者抢占")
//    grant  = ~( unready[2N-1:N] & unready[N-1:0] )   (N 位 one-hot 授权)
//    胜者更新: 若本拍 latch 且有请求, mask <= leftOR(grant & valid)。
//  leftOR/rightOR 为前缀 OR (把置位向高/低位传播), 用 for 循环通用实现。
//
//  ---------------------------------------------------------------------------
//  验证: golden 同名 TLXbar_3 例化本核 (端口透传)。无子模块 (叶子), UT 双例化直接
//  比对; FM 签名分析证组合/时序等价。
// =============================================================================
module xs_TLXbar_3_core
  import tlxbar3_pkg::*;
(
  input         clock,
  input         reset,

  // ---- 主口 in (上游) : A=请求(入), D=应答(出) ----
  output        auto_in_a_ready,
  input         auto_in_a_valid,
  input  [3:0]  auto_in_a_bits_opcode,
  input  [8:0]  auto_in_a_bits_address,
  input  [31:0] auto_in_a_bits_data,
  input         auto_in_d_ready,
  output        auto_in_d_valid,
  output        auto_in_d_bits_denied,
  output [31:0] auto_in_d_bits_data,
  output        auto_in_d_bits_corrupt,

  // ---- 从口 out1 = OUT_DEV (设备小区间, 7 位地址, D 仅 data) ----
  input         auto_out_1_a_ready,
  output        auto_out_1_a_valid,
  output [3:0]  auto_out_1_a_bits_opcode,
  output [6:0]  auto_out_1_a_bits_address,
  output [31:0] auto_out_1_a_bits_data,
  output        auto_out_1_d_ready,
  input         auto_out_1_d_valid,
  input  [31:0] auto_out_1_d_bits_data,

  // ---- 从口 out0 = OUT_MAIN (默认主区间, 9 位地址, D 含 denied/corrupt) ----
  input         auto_out_0_a_ready,
  output        auto_out_0_a_valid,
  output [3:0]  auto_out_0_a_bits_opcode,
  output [8:0]  auto_out_0_a_bits_address,
  output [31:0] auto_out_0_a_bits_data,
  output        auto_out_0_d_ready,
  input         auto_out_0_d_valid,
  input         auto_out_0_d_bits_denied,
  input  [31:0] auto_out_0_d_bits_data,
  input         auto_out_0_d_bits_corrupt
);

  // ===========================================================================
  //  前缀 OR 工具 (rocket-chip util.leftOR / util.rightOR 的通用实现)
  // ---------------------------------------------------------------------------
  //  leftOR(x)[i]  = OR(x[i:0])     —— 把最低置位向高位 (左) 传播;
  //  rightOR(x)[i] = OR(x[..:i])    —— 把置位向低位 (右) 传播。
  //  Scala 中 rightOR(filter, 2N, cap=N): 只做到 log2(N) 步, 故循环上界用 NUM_OUT。
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
  //  request[OUT_DEV]  = 地址 ∈ 设备两段 AddressSet;
  //  request[OUT_MAIN] = 其补集 (默认 catch-all, 与 golden 在 9 位空间内逐一互补)。
  // ===========================================================================
  wire [8:0] a_addr = auto_in_a_bits_address;
  wire to_dev =
       ((a_addr & DEV_A_MASK) == DEV_A_BASE)
     | ((a_addr & DEV_B_MASK) == DEV_B_BASE);

  logic [NUM_OUT-1:0] request;             // 按从口编号: [OUT_MAIN]/[OUT_DEV]
  assign request[OUT_DEV]  = to_dev;
  assign request[OUT_MAIN] = ~to_dev;

  // 各从口 A 通道 ready (供 in_a_ready 汇聚)。
  logic [NUM_OUT-1:0] out_a_ready;
  assign out_a_ready[OUT_MAIN] = auto_out_0_a_ready;
  assign out_a_ready[OUT_DEV]  = auto_out_1_a_ready;

  // 主口 A ready = 命中从口已就绪 (单主口, 无需仲裁)。
  assign auto_in_a_ready = |(request & out_a_ready);

  // 从口 A valid = 主口有请求且地址命中本口; 载荷透传 (out1 仅取低 7 位地址)。
  assign auto_out_0_a_valid       = auto_in_a_valid & request[OUT_MAIN];
  assign auto_out_0_a_bits_opcode = auto_in_a_bits_opcode;
  assign auto_out_0_a_bits_address= auto_in_a_bits_address;        // 9 位全址
  assign auto_out_0_a_bits_data   = auto_in_a_bits_data;
  assign auto_out_1_a_valid       = auto_in_a_valid & request[OUT_DEV];
  assign auto_out_1_a_bits_opcode = auto_in_a_bits_opcode;
  assign auto_out_1_a_bits_address= auto_in_a_bits_address[6:0];   // 设备 7 位址
  assign auto_out_1_a_bits_data   = auto_in_a_bits_data;

  // ===========================================================================
  //  D 通道: 把两个从口应答按 round-robin 择一回送主口
  // ---------------------------------------------------------------------------
  //  打包从口 D 信号为 valid 向量 + 载荷结构数组 (out1 无 denied/corrupt ⇒ 0),
  //  便于 genvar/for 做 one-hot 归约。
  // ===========================================================================
  logic [NUM_OUT-1:0] d_valid;
  tl_d_bits_t         d_bits [NUM_OUT];

  assign d_valid[OUT_MAIN] = auto_out_0_d_valid;
  assign d_valid[OUT_DEV]  = auto_out_1_d_valid;
  assign d_bits[OUT_MAIN]  = '{data: auto_out_0_d_bits_data,
                               denied: auto_out_0_d_bits_denied,
                               corrupt: auto_out_0_d_bits_corrupt};
  assign d_bits[OUT_DEV]   = '{data: auto_out_1_d_bits_data,
                               denied: 1'b0, corrupt: 1'b0};  // 设备口无 denied/corrupt

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
  assign auto_out_0_d_ready = auto_in_d_ready & allowed[OUT_MAIN];
  assign auto_out_1_d_ready = auto_in_d_ready & allowed[OUT_DEV];

  // 主口 D 载荷: 按 mux_sel 做 one-hot 选择 (同时至多一个从口被选, OR 归约即多路选择)。
  tl_d_bits_t d_sel;
  always_comb begin
    d_sel = '0;
    for (int o = 0; o < NUM_OUT; o++)
      if (mux_sel[o]) d_sel |= d_bits[o];
  end
  assign auto_in_d_bits_data    = d_sel.data;
  assign auto_in_d_bits_denied  = d_sel.denied;
  assign auto_in_d_bits_corrupt = d_sel.corrupt;

  // ---- 时序: beat 计数 / 优先级掩码轮转 / 胜者锁定 ----
  //  init_beats = 本拍胜者的 numBeats1; 本口无 size 字段 ⇒ 恒单拍 ⇒ 0。
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
