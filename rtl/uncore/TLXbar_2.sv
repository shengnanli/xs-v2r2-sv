// =============================================================================
//  TLXbar_2 —— 香山 V2R2 TileLink 外设交叉开关 (可读重写核 xs_TLXbar_2_core)
// -----------------------------------------------------------------------------
//  源自 rocket-chip TLXbar (src/main/scala/tilelink/Xbar.scala): 1 主口 (in) ×
//  5 从口 (out0..out4)。从设计意图重写, 算法依据:
//    · A 通道 (主→从): 地址译码 = 该地址落在哪个从口 ⇒ 路由 + 透传。单主口故无 A
//      仲裁 (Arbiter sources.size==1 退化为直连)。
//    · D 通道 (从→主): TLArbiter.roundRobin 5 路轮转仲裁把某个从口应答回送主口;
//      配 beat 计数 + 锁定 (本变体单拍, 锁定逻辑退化)。
//
//  ---------------------------------------------------------------------------
//  round-robin 仲裁算法 (Arbiter.scala 的 roundRobin policy, 通用重写):
//    mask   : 优先级掩码寄存器 (RegInit 全 1); 已被服务者下一轮降到最低优先级。
//    filter = {valid & ~mask, valid}                  (2N=10 位)
//    unready= (rightOR(filter, 2N, cap=N) >> 1) | (mask<<N)
//    grant  = ~( unready[2N-1:N] & unready[N-1:0] )    (N 位 one-hot 授权)
//    胜者更新: 若本拍 latch 且有请求, mask <= leftOR(grant & valid)。
//  rightOR/leftOR 用 for 循环做前缀 OR; cap=N 令步长只到 s<N (N=5 ⇒ 步 1/2/4),
//  与 firtool 展开的 _GEN_0/_GEN_1 多级或逐位等价。
//
//  ---------------------------------------------------------------------------
//  验证: golden 同名 TLXbar_2 例化本核 (端口透传)。无子模块 (叶子), UT 双例化逐拍
//  比对全部输出; FM 签名分析证组合/时序等价。
// =============================================================================
module xs_TLXbar_2_core
  import tlxbar2_pkg::*;
(
  input         clock,
  input         reset,

  // ---- 主口 in (上游) : A=请求(入), D=应答(出), 完整 TL-C 口径 ----
  output        auto_in_a_ready,
  input         auto_in_a_valid,
  input  [3:0]  auto_in_a_bits_opcode,
  input  [2:0]  auto_in_a_bits_param,
  input  [1:0]  auto_in_a_bits_size,
  input  [14:0] auto_in_a_bits_source,
  input  [29:0] auto_in_a_bits_address,
  input  [7:0]  auto_in_a_bits_mask,
  input  [63:0] auto_in_a_bits_data,
  input         auto_in_a_bits_corrupt,
  input         auto_in_d_ready,
  output        auto_in_d_valid,
  output [3:0]  auto_in_d_bits_opcode,
  output [1:0]  auto_in_d_bits_param,
  output [1:0]  auto_in_d_bits_size,
  output [14:0] auto_in_d_bits_source,
  output        auto_in_d_bits_sink,
  output        auto_in_d_bits_denied,
  output [63:0] auto_in_d_bits_data,
  output        auto_in_d_bits_corrupt,

  // ---- 从口 out4 = OUT4 (唯一完整 TL-C 从口, A 带 param/corrupt, D 全字段) ----
  input         auto_out_4_a_ready,
  output        auto_out_4_a_valid,
  output [3:0]  auto_out_4_a_bits_opcode,
  output [2:0]  auto_out_4_a_bits_param,
  output [1:0]  auto_out_4_a_bits_size,
  output [14:0] auto_out_4_a_bits_source,
  output [29:0] auto_out_4_a_bits_address,
  output [7:0]  auto_out_4_a_bits_mask,
  output [63:0] auto_out_4_a_bits_data,
  output        auto_out_4_a_bits_corrupt,
  output        auto_out_4_d_ready,
  input         auto_out_4_d_valid,
  input  [3:0]  auto_out_4_d_bits_opcode,
  input  [1:0]  auto_out_4_d_bits_param,
  input  [1:0]  auto_out_4_d_bits_size,
  input  [14:0] auto_out_4_d_bits_source,
  input         auto_out_4_d_bits_sink,
  input         auto_out_4_d_bits_denied,
  input  [63:0] auto_out_4_d_bits_data,
  input         auto_out_4_d_bits_corrupt,

  // ---- 从口 out3 = OUT3 (TL-UL: A 无 param/corrupt, D 仅 opcode/size/source/data) --
  input         auto_out_3_a_ready,
  output        auto_out_3_a_valid,
  output [3:0]  auto_out_3_a_bits_opcode,
  output [1:0]  auto_out_3_a_bits_size,
  output [14:0] auto_out_3_a_bits_source,
  output [29:0] auto_out_3_a_bits_address,
  output [7:0]  auto_out_3_a_bits_mask,
  output [63:0] auto_out_3_a_bits_data,
  output        auto_out_3_d_ready,
  input         auto_out_3_d_valid,
  input  [3:0]  auto_out_3_d_bits_opcode,
  input  [1:0]  auto_out_3_d_bits_size,
  input  [14:0] auto_out_3_d_bits_source,
  input  [63:0] auto_out_3_d_bits_data,

  // ---- 从口 out2 = OUT2 (TL-UL) ----
  input         auto_out_2_a_ready,
  output        auto_out_2_a_valid,
  output [3:0]  auto_out_2_a_bits_opcode,
  output [1:0]  auto_out_2_a_bits_size,
  output [14:0] auto_out_2_a_bits_source,
  output [29:0] auto_out_2_a_bits_address,
  output [7:0]  auto_out_2_a_bits_mask,
  output [63:0] auto_out_2_a_bits_data,
  output        auto_out_2_d_ready,
  input         auto_out_2_d_valid,
  input  [3:0]  auto_out_2_d_bits_opcode,
  input  [1:0]  auto_out_2_d_bits_size,
  input  [14:0] auto_out_2_d_bits_source,
  input  [63:0] auto_out_2_d_bits_data,

  // ---- 从口 out1 = OUT1 (TL-UL) ----
  input         auto_out_1_a_ready,
  output        auto_out_1_a_valid,
  output [3:0]  auto_out_1_a_bits_opcode,
  output [1:0]  auto_out_1_a_bits_size,
  output [14:0] auto_out_1_a_bits_source,
  output [29:0] auto_out_1_a_bits_address,
  output [7:0]  auto_out_1_a_bits_mask,
  output [63:0] auto_out_1_a_bits_data,
  output        auto_out_1_d_ready,
  input         auto_out_1_d_valid,
  input  [3:0]  auto_out_1_d_bits_opcode,
  input  [1:0]  auto_out_1_d_bits_size,
  input  [14:0] auto_out_1_d_bits_source,
  input  [63:0] auto_out_1_d_bits_data,

  // ---- 从口 out0 = OUT0 (TL-UL) ----
  input         auto_out_0_a_ready,
  output        auto_out_0_a_valid,
  output [3:0]  auto_out_0_a_bits_opcode,
  output [1:0]  auto_out_0_a_bits_size,
  output [14:0] auto_out_0_a_bits_source,
  output [29:0] auto_out_0_a_bits_address,
  output [7:0]  auto_out_0_a_bits_mask,
  output [63:0] auto_out_0_a_bits_data,
  output        auto_out_0_d_ready,
  input         auto_out_0_d_valid,
  input  [3:0]  auto_out_0_d_bits_opcode,
  input  [1:0]  auto_out_0_d_bits_size,
  input  [14:0] auto_out_0_d_bits_source,
  input  [63:0] auto_out_0_d_bits_data
);

  // ===========================================================================
  //  前缀 OR 工具 (rocket-chip util.leftOR / util.rightOR 的通用实现, cap=NUM_OUT)
  // ---------------------------------------------------------------------------
  //  leftOR(x)[i]  = OR(x[i:0])     —— 把最低置位向高位 (左) 传播;
  //  rightOR(x)[i] = OR(x[..:i])    —— 把置位向低位 (右) 传播。
  //  Scala 中 rightOR(filter, 2N, cap=N) 只做到 s<N 的步, 故循环上界用 NUM_OUT。
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
  //  各从口由若干地址位区分 (firtool 已把高位裁掉, 因其在本 xbar 地址窗口内恒定):
  //    out0: a26=0 & a25=0 & a17=0
  //    out1: a26=1
  //    out2: a26=0 & a25=1 & a17=0 & a12=0
  //    out3: a26=0 & a25=0 & a17=1 & a12=0
  //    out4: a26=0 & a25=0 & a17=1 & a12=1
  //  五者互斥 (a26/a25/a17/a12 的不同组合)。
  // ===========================================================================
  wire a12 = auto_in_a_bits_address[12];
  wire a17 = auto_in_a_bits_address[17];
  wire a25 = auto_in_a_bits_address[25];
  wire a26 = auto_in_a_bits_address[26];

  logic [NUM_OUT-1:0] request;
  assign request[OUT0] = ~a26 & ~a25 & ~a17;
  assign request[OUT1] =  a26;
  assign request[OUT2] = ~a26 &  a25 & ~a17 & ~a12;
  assign request[OUT3] = ~a26 & ~a25 &  a17 & ~a12;
  assign request[OUT4] = ~a26 & ~a25 &  a17 &  a12;

  // 各从口 A 通道 ready (供 in_a_ready 汇聚)。
  logic [NUM_OUT-1:0] out_a_ready;
  assign out_a_ready[OUT0] = auto_out_0_a_ready;
  assign out_a_ready[OUT1] = auto_out_1_a_ready;
  assign out_a_ready[OUT2] = auto_out_2_a_ready;
  assign out_a_ready[OUT3] = auto_out_3_a_ready;
  assign out_a_ready[OUT4] = auto_out_4_a_ready;

  // 主口 A ready = 命中从口已就绪 (单主口, 无需仲裁)。
  assign auto_in_a_ready = |(request & out_a_ready);

  // 从口 A valid = 主口有请求且地址命中本口; 载荷透传。out4 额外携带 param/corrupt。
  assign auto_out_0_a_valid        = auto_in_a_valid & request[OUT0];
  assign auto_out_0_a_bits_opcode  = auto_in_a_bits_opcode;
  assign auto_out_0_a_bits_size    = auto_in_a_bits_size;
  assign auto_out_0_a_bits_source  = auto_in_a_bits_source;
  assign auto_out_0_a_bits_address = auto_in_a_bits_address;
  assign auto_out_0_a_bits_mask    = auto_in_a_bits_mask;
  assign auto_out_0_a_bits_data    = auto_in_a_bits_data;

  assign auto_out_1_a_valid        = auto_in_a_valid & request[OUT1];
  assign auto_out_1_a_bits_opcode  = auto_in_a_bits_opcode;
  assign auto_out_1_a_bits_size    = auto_in_a_bits_size;
  assign auto_out_1_a_bits_source  = auto_in_a_bits_source;
  assign auto_out_1_a_bits_address = auto_in_a_bits_address;
  assign auto_out_1_a_bits_mask    = auto_in_a_bits_mask;
  assign auto_out_1_a_bits_data    = auto_in_a_bits_data;

  assign auto_out_2_a_valid        = auto_in_a_valid & request[OUT2];
  assign auto_out_2_a_bits_opcode  = auto_in_a_bits_opcode;
  assign auto_out_2_a_bits_size    = auto_in_a_bits_size;
  assign auto_out_2_a_bits_source  = auto_in_a_bits_source;
  assign auto_out_2_a_bits_address = auto_in_a_bits_address;
  assign auto_out_2_a_bits_mask    = auto_in_a_bits_mask;
  assign auto_out_2_a_bits_data    = auto_in_a_bits_data;

  assign auto_out_3_a_valid        = auto_in_a_valid & request[OUT3];
  assign auto_out_3_a_bits_opcode  = auto_in_a_bits_opcode;
  assign auto_out_3_a_bits_size    = auto_in_a_bits_size;
  assign auto_out_3_a_bits_source  = auto_in_a_bits_source;
  assign auto_out_3_a_bits_address = auto_in_a_bits_address;
  assign auto_out_3_a_bits_mask    = auto_in_a_bits_mask;
  assign auto_out_3_a_bits_data    = auto_in_a_bits_data;

  assign auto_out_4_a_valid        = auto_in_a_valid & request[OUT4];
  assign auto_out_4_a_bits_opcode  = auto_in_a_bits_opcode;
  assign auto_out_4_a_bits_param   = auto_in_a_bits_param;     // out4 独有
  assign auto_out_4_a_bits_size    = auto_in_a_bits_size;
  assign auto_out_4_a_bits_source  = auto_in_a_bits_source;
  assign auto_out_4_a_bits_address = auto_in_a_bits_address;
  assign auto_out_4_a_bits_mask    = auto_in_a_bits_mask;
  assign auto_out_4_a_bits_data    = auto_in_a_bits_data;
  assign auto_out_4_a_bits_corrupt = auto_in_a_bits_corrupt;   // out4 独有

  // ===========================================================================
  //  D 通道: 把 5 个从口应答按 5 路 round-robin 择一回送主口
  // ---------------------------------------------------------------------------
  //  打包从口 D 信号为 valid 向量 + 载荷结构数组; UL 从口缺失的 param/sink/denied/
  //  corrupt 填 0 (与 golden "仅 out4 贡献这些字段" 等价)。
  // ===========================================================================
  logic [NUM_OUT-1:0] d_valid;
  tl_d_bits_t         d_bits [NUM_OUT];

  assign d_valid[OUT0] = auto_out_0_d_valid;
  assign d_valid[OUT1] = auto_out_1_d_valid;
  assign d_valid[OUT2] = auto_out_2_d_valid;
  assign d_valid[OUT3] = auto_out_3_d_valid;
  assign d_valid[OUT4] = auto_out_4_d_valid;

  // UL 从口 (out0..out3): param/sink/denied/corrupt 恒 0。
  assign d_bits[OUT0] = '{opcode:  auto_out_0_d_bits_opcode, param: 2'h0,
                          size:    auto_out_0_d_bits_size,   source: auto_out_0_d_bits_source,
                          sink: 1'b0, denied: 1'b0, data: auto_out_0_d_bits_data, corrupt: 1'b0};
  assign d_bits[OUT1] = '{opcode:  auto_out_1_d_bits_opcode, param: 2'h0,
                          size:    auto_out_1_d_bits_size,   source: auto_out_1_d_bits_source,
                          sink: 1'b0, denied: 1'b0, data: auto_out_1_d_bits_data, corrupt: 1'b0};
  assign d_bits[OUT2] = '{opcode:  auto_out_2_d_bits_opcode, param: 2'h0,
                          size:    auto_out_2_d_bits_size,   source: auto_out_2_d_bits_source,
                          sink: 1'b0, denied: 1'b0, data: auto_out_2_d_bits_data, corrupt: 1'b0};
  assign d_bits[OUT3] = '{opcode:  auto_out_3_d_bits_opcode, param: 2'h0,
                          size:    auto_out_3_d_bits_size,   source: auto_out_3_d_bits_source,
                          sink: 1'b0, denied: 1'b0, data: auto_out_3_d_bits_data, corrupt: 1'b0};
  // out4: 完整字段。
  assign d_bits[OUT4] = '{opcode:  auto_out_4_d_bits_opcode, param: auto_out_4_d_bits_param,
                          size:    auto_out_4_d_bits_size,   source: auto_out_4_d_bits_source,
                          sink:    auto_out_4_d_bits_sink,   denied: auto_out_4_d_bits_denied,
                          data:    auto_out_4_d_bits_data,   corrupt: auto_out_4_d_bits_corrupt};

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
  assign auto_out_0_d_ready = auto_in_d_ready & allowed[OUT0];
  assign auto_out_1_d_ready = auto_in_d_ready & allowed[OUT1];
  assign auto_out_2_d_ready = auto_in_d_ready & allowed[OUT2];
  assign auto_out_3_d_ready = auto_in_d_ready & allowed[OUT3];
  assign auto_out_4_d_ready = auto_in_d_ready & allowed[OUT4];

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
