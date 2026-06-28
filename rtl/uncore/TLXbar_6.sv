// =============================================================================
//  TLXbar_6 —— 香山 V2R2 多主 TileLink-C 交叉开关 (可读重写核 xs_TLXbar_6_core)
// -----------------------------------------------------------------------------
//  源自 rocket-chip TLXbar (src/main/scala/tilelink/Xbar.scala): 2 主口 (in_0/in_1)
//  × 3 从口 (BEU / CacheCtrl / Default)。从设计意图重写 (非照抄 firtool 优化后的
//  逐位地址掩码与展平命名)。算法依据:
//    · A 通道 (主→从): 地址译码 (req[in][out]) + 每从口对请求它的两主口做轮转仲裁,
//      胜者载荷路由到该从口; 主口 A ready = 命中从口就绪 & 本主口在该从口被授权。
//    · D 通道 (从→主): 按 D 的 source 判定应答归属哪个主口 (路由矩阵 DOI[out][in]),
//      每主口对应答它的三从口做轮转仲裁, 胜者载荷回送该主口。
//
//  ---------------------------------------------------------------------------
//  round-robin 仲裁算法 (Arbiter.scala 的 roundRobin policy, 通用前缀 OR 重写):
//    mask   : 优先级掩码寄存器 (RegInit 全 1); 已被服务者下一轮降到最低优先级。
//    filter = {valid & ~mask, valid}             (2n 位)
//    unready= (rightOR(filter, 2n, cap=n) >> 1) | (mask << n)
//    grant[i] = ~( unready[i+n] & unready[i] )    (n 位 one-hot 授权, i∈[0,n))
//    胜者更新: 若本拍 latch 且有请求, mask <= leftOR(grant & valid)。
//  本核三个 A 仲裁器 n=NUM_IN=2, 两个 D 仲裁器 n=NUM_OUT=3; 同一组函数 (MAXN=3 位宽,
//  运行期传 n) 同时服务两种规模。
//
//  ---------------------------------------------------------------------------
//  验证: golden 同名 TLXbar_6 例化本核 (端口透传)。叶子模块 (无子例化), UT 双例化逐
//  拍比对全部输出; FM 签名分析证组合/时序等价。
// =============================================================================
module xs_TLXbar_6_core
  import tlxbar6_pkg::*;
(
  input         clock,
  input         reset,

  // ---- 主口 in_1 (source 2 位, 带 user) ----
  output        auto_in_1_a_ready,
  input         auto_in_1_a_valid,
  input  [3:0]  auto_in_1_a_bits_opcode,
  input  [2:0]  auto_in_1_a_bits_param,
  input  [1:0]  auto_in_1_a_bits_size,
  input  [1:0]  auto_in_1_a_bits_source,
  input  [47:0] auto_in_1_a_bits_address,
  input         auto_in_1_a_bits_user_memBackType_MM,
  input         auto_in_1_a_bits_user_memPageType_NC,
  input  [7:0]  auto_in_1_a_bits_mask,
  input  [63:0] auto_in_1_a_bits_data,
  input         auto_in_1_a_bits_corrupt,
  input         auto_in_1_d_ready,
  output        auto_in_1_d_valid,
  output [3:0]  auto_in_1_d_bits_opcode,
  output [1:0]  auto_in_1_d_bits_param,
  output [1:0]  auto_in_1_d_bits_size,
  output [1:0]  auto_in_1_d_bits_source,
  output        auto_in_1_d_bits_sink,
  output        auto_in_1_d_bits_denied,
  output [63:0] auto_in_1_d_bits_data,
  output        auto_in_1_d_bits_corrupt,

  // ---- 主口 in_0 (source 1 位, 无 user; D 无 source) ----
  output        auto_in_0_a_ready,
  input         auto_in_0_a_valid,
  input  [3:0]  auto_in_0_a_bits_opcode,
  input  [2:0]  auto_in_0_a_bits_param,
  input  [1:0]  auto_in_0_a_bits_size,
  input         auto_in_0_a_bits_source,
  input  [47:0] auto_in_0_a_bits_address,
  input  [7:0]  auto_in_0_a_bits_mask,
  input  [63:0] auto_in_0_a_bits_data,
  input         auto_in_0_a_bits_corrupt,
  input         auto_in_0_d_ready,
  output        auto_in_0_d_valid,
  output [3:0]  auto_in_0_d_bits_opcode,
  output [1:0]  auto_in_0_d_bits_param,
  output [1:0]  auto_in_0_d_bits_size,
  output        auto_in_0_d_bits_sink,
  output        auto_in_0_d_bits_denied,
  output [63:0] auto_in_0_d_bits_data,
  output        auto_in_0_d_bits_corrupt,

  // ---- 从口 out_2 = OUT_DEFAULT (48 位全址, 携带 user, source 3 位) ----
  input         auto_out_2_a_ready,
  output        auto_out_2_a_valid,
  output [3:0]  auto_out_2_a_bits_opcode,
  output [2:0]  auto_out_2_a_bits_param,
  output [1:0]  auto_out_2_a_bits_size,
  output [2:0]  auto_out_2_a_bits_source,
  output [47:0] auto_out_2_a_bits_address,
  output        auto_out_2_a_bits_user_memBackType_MM,
  output        auto_out_2_a_bits_user_memPageType_NC,
  output [7:0]  auto_out_2_a_bits_mask,
  output [63:0] auto_out_2_a_bits_data,
  output        auto_out_2_a_bits_corrupt,
  output        auto_out_2_d_ready,
  input         auto_out_2_d_valid,
  input  [3:0]  auto_out_2_d_bits_opcode,
  input  [1:0]  auto_out_2_d_bits_param,
  input  [1:0]  auto_out_2_d_bits_size,
  input  [2:0]  auto_out_2_d_bits_source,
  input         auto_out_2_d_bits_sink,
  input         auto_out_2_d_bits_denied,
  input  [63:0] auto_out_2_d_bits_data,
  input         auto_out_2_d_bits_corrupt,

  // ---- 从口 out_1 = OUT_CACHECTRL (30 位地址, 无 user, source 3 位) ----
  input         auto_out_1_a_ready,
  output        auto_out_1_a_valid,
  output [3:0]  auto_out_1_a_bits_opcode,
  output [2:0]  auto_out_1_a_bits_param,
  output [1:0]  auto_out_1_a_bits_size,
  output [2:0]  auto_out_1_a_bits_source,
  output [29:0] auto_out_1_a_bits_address,
  output [7:0]  auto_out_1_a_bits_mask,
  output [63:0] auto_out_1_a_bits_data,
  output        auto_out_1_a_bits_corrupt,
  output        auto_out_1_d_ready,
  input         auto_out_1_d_valid,
  input  [3:0]  auto_out_1_d_bits_opcode,
  input  [1:0]  auto_out_1_d_bits_param,
  input  [1:0]  auto_out_1_d_bits_size,
  input  [2:0]  auto_out_1_d_bits_source,
  input         auto_out_1_d_bits_sink,
  input         auto_out_1_d_bits_denied,
  input  [63:0] auto_out_1_d_bits_data,
  input         auto_out_1_d_bits_corrupt,

  // ---- 从口 out_0 = OUT_BEU (30 位地址, 无 user, source 3 位) ----
  input         auto_out_0_a_ready,
  output        auto_out_0_a_valid,
  output [3:0]  auto_out_0_a_bits_opcode,
  output [2:0]  auto_out_0_a_bits_param,
  output [1:0]  auto_out_0_a_bits_size,
  output [2:0]  auto_out_0_a_bits_source,
  output [29:0] auto_out_0_a_bits_address,
  output [7:0]  auto_out_0_a_bits_mask,
  output [63:0] auto_out_0_a_bits_data,
  output        auto_out_0_a_bits_corrupt,
  output        auto_out_0_d_ready,
  input         auto_out_0_d_valid,
  input  [3:0]  auto_out_0_d_bits_opcode,
  input  [1:0]  auto_out_0_d_bits_param,
  input  [1:0]  auto_out_0_d_bits_size,
  input  [2:0]  auto_out_0_d_bits_source,
  input         auto_out_0_d_bits_sink,
  input         auto_out_0_d_bits_denied,
  input  [63:0] auto_out_0_d_bits_data,
  input         auto_out_0_d_bits_corrupt
);

  // ===========================================================================
  //  前缀 OR 通用工具 (rocket-chip util.leftOR / util.rightOR)。
  //  位宽统一取 MAXN, 运行期传入实际路数 n; A 侧 n=NUM_IN=2, D 侧 n=NUM_OUT=3。
  //  超出 n 的高位恒 0, 不影响低 n 位结果。
  // ===========================================================================
  // leftOR(x)[i] = OR(x[i:0]) —— 把最低置位向高位 (左) 传播 (用于胜者掩码更新)。
  function automatic logic [MAXN-1:0] left_or(input logic [MAXN-1:0] x,
                                              input int unsigned n);
    left_or = x;
    for (int s = 1; s < n; s = s << 1) left_or = left_or | (left_or << s);
  endfunction

  // rightOR(x, 2n, cap=n)[i] = OR(x[..:i]) —— 置位向低位 (右) 传播, 只做 log2(n) 步。
  function automatic logic [2*MAXN-1:0] right_or_capped(input logic [2*MAXN-1:0] x,
                                                        input int unsigned n);
    right_or_capped = x;
    for (int s = 1; s < n; s = s << 1)
      right_or_capped = right_or_capped | (right_or_capped >> s);
  endfunction

  // round-robin 授权: 各源 valid 与优先级 mask ⇒ n 位 one-hot grant。
  function automatic logic [MAXN-1:0] rr_grant(input logic [MAXN-1:0] valid,
                                               input logic [MAXN-1:0] mask,
                                               input int unsigned      n);
    logic [2*MAXN-1:0] vext, vmext, mext, filter, unready;
    vext    = {{MAXN{1'b0}}, valid};
    vmext   = {{MAXN{1'b0}}, (valid & ~mask)};
    mext    = {{MAXN{1'b0}}, mask};
    filter  = vext | (vmext << n);                 // 低 n 位=valid, 次 n 位=valid&~mask
    unready = (right_or_capped(filter, n) >> 1) | (mext << n);
    rr_grant = '0;
    for (int i = 0; i < n; i++)
      rr_grant[i] = ~(unready[i + n] & unready[i]);
  endfunction

  // ===========================================================================
  //  主口 A 载荷打包 (超集; in_0 无 user 字段填 0, source 做 3 位内部重映射)
  // ===========================================================================
  tl_a_t a_in       [NUM_IN];
  logic  a_in_valid [NUM_IN];

  assign a_in_valid[IN_0] = auto_in_0_a_valid;
  assign a_in_valid[IN_1] = auto_in_1_a_valid;

  // in_0: source 重映射到基址 4 (= {2'b10, s}); 不携带 user。
  assign a_in[IN_0] = '{
    opcode:  auto_in_0_a_bits_opcode,
    param:   auto_in_0_a_bits_param,
    size:    auto_in_0_a_bits_size,
    source:  {2'b10, auto_in_0_a_bits_source},
    address: auto_in_0_a_bits_address,
    user_MM: 1'b0,
    user_NC: 1'b0,
    mask:    auto_in_0_a_bits_mask,
    data:    auto_in_0_a_bits_data,
    corrupt: auto_in_0_a_bits_corrupt
  };
  // in_1: source 重映射到基址 0 (= {1'b0, s}); 携带 user(MM/NC)。
  assign a_in[IN_1] = '{
    opcode:  auto_in_1_a_bits_opcode,
    param:   auto_in_1_a_bits_param,
    size:    auto_in_1_a_bits_size,
    source:  {1'b0, auto_in_1_a_bits_source},
    address: auto_in_1_a_bits_address,
    user_MM: auto_in_1_a_bits_user_memBackType_MM,
    user_NC: auto_in_1_a_bits_user_memPageType_NC,
    mask:    auto_in_1_a_bits_mask,
    data:    auto_in_1_a_bits_data,
    corrupt: auto_in_1_a_bits_corrupt
  };

  // ===========================================================================
  //  A 通道地址译码: req[in][out] —— 该主口此刻的访问命中哪个从口
  // ===========================================================================
  function automatic logic dec_beu      (input logic [47:0] a); return a[47:12] == BEU_ADDR_HI;       endfunction
  function automatic logic dec_cachectrl(input logic [47:0] a); return a[47:8]  == CACHECTRL_ADDR_HI; endfunction

  logic [NUM_OUT-1:0] req [NUM_IN];
  always_comb begin
    for (int i = 0; i < NUM_IN; i++) begin
      req[i][OUT_BEU]       = dec_beu(a_in[i].address);
      req[i][OUT_CACHECTRL] = dec_cachectrl(a_in[i].address);
      req[i][OUT_DEFAULT]   = ~(req[i][OUT_BEU] | req[i][OUT_CACHECTRL]); // catch-all 补集
    end
  end

  // ===========================================================================
  //  从口 D 载荷打包 (三口字段对称) + D→主口路由判据 DOI[out][in]
  // ===========================================================================
  tl_d_t d_out       [NUM_OUT];
  logic  d_out_valid [NUM_OUT];

  assign d_out_valid[OUT_BEU]       = auto_out_0_d_valid;
  assign d_out_valid[OUT_CACHECTRL] = auto_out_1_d_valid;
  assign d_out_valid[OUT_DEFAULT]   = auto_out_2_d_valid;

  assign d_out[OUT_BEU] = '{opcode:  auto_out_0_d_bits_opcode, param: auto_out_0_d_bits_param,
                            size:    auto_out_0_d_bits_size,   source: auto_out_0_d_bits_source,
                            sink:    auto_out_0_d_bits_sink,   denied: auto_out_0_d_bits_denied,
                            data:    auto_out_0_d_bits_data,   corrupt: auto_out_0_d_bits_corrupt};
  assign d_out[OUT_CACHECTRL] = '{opcode:  auto_out_1_d_bits_opcode, param: auto_out_1_d_bits_param,
                                  size:    auto_out_1_d_bits_size,   source: auto_out_1_d_bits_source,
                                  sink:    auto_out_1_d_bits_sink,   denied: auto_out_1_d_bits_denied,
                                  data:    auto_out_1_d_bits_data,   corrupt: auto_out_1_d_bits_corrupt};
  assign d_out[OUT_DEFAULT] = '{opcode:  auto_out_2_d_bits_opcode, param: auto_out_2_d_bits_param,
                                size:    auto_out_2_d_bits_size,   source: auto_out_2_d_bits_source,
                                sink:    auto_out_2_d_bits_sink,   denied: auto_out_2_d_bits_denied,
                                data:    auto_out_2_d_bits_data,   corrupt: auto_out_2_d_bits_corrupt};

  // 应答归属: in_0 基址 4 ⇒ source==4; in_1 基址 0 ⇒ source[2]==0 (取值 0..3)。
  logic DOI [NUM_OUT][NUM_IN];
  always_comb begin
    for (int o = 0; o < NUM_OUT; o++) begin
      DOI[o][IN_0] = (d_out[o].source == IN0_SOURCE_ID);
      DOI[o][IN_1] = ~d_out[o].source[2];
    end
  end

  // ===========================================================================
  //  A 侧仲裁器: 每个从口一个 (NUM_OUT 个), 各对 NUM_IN 个主口轮转仲裁
  // ===========================================================================
  reg              a_beats [NUM_OUT];   // beat 计数 (单拍配置恒 0)
  reg [NUM_IN-1:0] a_mask  [NUM_OUT];   // 优先级掩码 (RegInit 全 1)
  reg [NUM_IN-1:0] a_state [NUM_OUT];   // 锁定胜者 (stall 时维持)

  logic [NUM_IN-1:0] a_valid_vec [NUM_OUT];  // 请求本从口且 valid 的主口集合
  logic [NUM_IN-1:0] a_grant     [NUM_OUT];
  logic [NUM_IN-1:0] a_winner    [NUM_OUT];
  logic [NUM_IN-1:0] a_muxsel    [NUM_OUT];
  logic [NUM_IN-1:0] a_allowed   [NUM_OUT];
  logic              a_out_valid [NUM_OUT];
  tl_a_t             a_sel       [NUM_OUT];

  always_comb begin
    logic [MAXN-1:0] g;
    for (int o = 0; o < NUM_OUT; o++) begin
      for (int i = 0; i < NUM_IN; i++)
        a_valid_vec[o][i] = a_in_valid[i] & req[i][o];
      g            = rr_grant(MAXN'(a_valid_vec[o]), MAXN'(a_mask[o]), NUM_IN);
      a_grant[o]   = g[NUM_IN-1:0];
      a_winner[o]  = a_grant[o] & a_valid_vec[o];
      a_muxsel[o]  = a_beats[o] ? a_state[o] : a_winner[o];
      a_allowed[o] = a_beats[o] ? a_state[o] : a_grant[o];
      a_out_valid[o] = a_beats[o] ? (|(a_state[o] & a_valid_vec[o])) : (|a_valid_vec[o]);
      // one-hot 选择胜者主口的 A 载荷 (至多一位 muxsel, OR 归约即多路选择)。
      a_sel[o] = '0;
      for (int i = 0; i < NUM_IN; i++)
        if (a_muxsel[o][i]) a_sel[o] |= a_in[i];
    end
  end

  // ===========================================================================
  //  D 侧仲裁器: 每个主口一个 (NUM_IN 个), 各对 NUM_OUT 个从口轮转仲裁
  // ===========================================================================
  reg               d_beats [NUM_IN];
  reg [NUM_OUT-1:0] d_mask  [NUM_IN];
  reg [NUM_OUT-1:0] d_state [NUM_IN];

  logic [NUM_OUT-1:0] d_valid_vec [NUM_IN];  // 应答本主口且 valid 的从口集合
  logic [NUM_OUT-1:0] d_grant     [NUM_IN];
  logic [NUM_OUT-1:0] d_winner    [NUM_IN];
  logic [NUM_OUT-1:0] d_muxsel    [NUM_IN];
  logic [NUM_OUT-1:0] d_allowed   [NUM_IN];
  logic               d_in_valid  [NUM_IN];
  tl_d_t              d_sel       [NUM_IN];

  always_comb begin
    logic [MAXN-1:0] g;
    for (int i = 0; i < NUM_IN; i++) begin
      for (int o = 0; o < NUM_OUT; o++)
        d_valid_vec[i][o] = d_out_valid[o] & DOI[o][i];
      g            = rr_grant(MAXN'(d_valid_vec[i]), MAXN'(d_mask[i]), NUM_OUT);
      d_grant[i]   = g[NUM_OUT-1:0];
      d_winner[i]  = d_grant[i] & d_valid_vec[i];
      d_muxsel[i]  = d_beats[i] ? d_state[i] : d_winner[i];
      d_allowed[i] = d_beats[i] ? d_state[i] : d_grant[i];
      d_in_valid[i] = d_beats[i] ? (|(d_state[i] & d_valid_vec[i])) : (|d_valid_vec[i]);
      d_sel[i] = '0;
      for (int o = 0; o < NUM_OUT; o++)
        if (d_muxsel[i][o]) d_sel[i] |= d_out[o];
    end
  end

  // ===========================================================================
  //  主口 A ready / D 输出
  // ===========================================================================
  //  主口 A ready = 命中从口就绪 & 本主口在该从口仲裁中被授权 (allowed)。
  assign auto_in_0_a_ready =
      req[IN_0][OUT_BEU]       & auto_out_0_a_ready & a_allowed[OUT_BEU][IN_0]
    | req[IN_0][OUT_CACHECTRL] & auto_out_1_a_ready & a_allowed[OUT_CACHECTRL][IN_0]
    | req[IN_0][OUT_DEFAULT]   & auto_out_2_a_ready & a_allowed[OUT_DEFAULT][IN_0];
  assign auto_in_1_a_ready =
      req[IN_1][OUT_BEU]       & auto_out_0_a_ready & a_allowed[OUT_BEU][IN_1]
    | req[IN_1][OUT_CACHECTRL] & auto_out_1_a_ready & a_allowed[OUT_CACHECTRL][IN_1]
    | req[IN_1][OUT_DEFAULT]   & auto_out_2_a_ready & a_allowed[OUT_DEFAULT][IN_1];

  // 主口 D: in_0 无 source 端口; in_1 取所选从口 source 的低 2 位。
  assign auto_in_0_d_valid       = d_in_valid[IN_0];
  assign auto_in_0_d_bits_opcode = d_sel[IN_0].opcode;
  assign auto_in_0_d_bits_param  = d_sel[IN_0].param;
  assign auto_in_0_d_bits_size   = d_sel[IN_0].size;
  assign auto_in_0_d_bits_sink   = d_sel[IN_0].sink;
  assign auto_in_0_d_bits_denied = d_sel[IN_0].denied;
  assign auto_in_0_d_bits_data   = d_sel[IN_0].data;
  assign auto_in_0_d_bits_corrupt= d_sel[IN_0].corrupt;

  assign auto_in_1_d_valid       = d_in_valid[IN_1];
  assign auto_in_1_d_bits_opcode = d_sel[IN_1].opcode;
  assign auto_in_1_d_bits_param  = d_sel[IN_1].param;
  assign auto_in_1_d_bits_size   = d_sel[IN_1].size;
  assign auto_in_1_d_bits_source = d_sel[IN_1].source[1:0];
  assign auto_in_1_d_bits_sink   = d_sel[IN_1].sink;
  assign auto_in_1_d_bits_denied = d_sel[IN_1].denied;
  assign auto_in_1_d_bits_data   = d_sel[IN_1].data;
  assign auto_in_1_d_bits_corrupt= d_sel[IN_1].corrupt;

  // ===========================================================================
  //  从口 A 输出 (窄从口截断地址 + 丢 user) / 从口 D ready
  // ===========================================================================
  // out_0 = BEU (30 位地址, source 3 位, 无 user)
  assign auto_out_0_a_valid        = a_out_valid[OUT_BEU];
  assign auto_out_0_a_bits_opcode  = a_sel[OUT_BEU].opcode;
  assign auto_out_0_a_bits_param   = a_sel[OUT_BEU].param;
  assign auto_out_0_a_bits_size    = a_sel[OUT_BEU].size;
  assign auto_out_0_a_bits_source  = a_sel[OUT_BEU].source;
  assign auto_out_0_a_bits_address = a_sel[OUT_BEU].address[29:0];
  assign auto_out_0_a_bits_mask    = a_sel[OUT_BEU].mask;
  assign auto_out_0_a_bits_data    = a_sel[OUT_BEU].data;
  assign auto_out_0_a_bits_corrupt = a_sel[OUT_BEU].corrupt;
  assign auto_out_0_d_ready =
      DOI[OUT_BEU][IN_0] & auto_in_0_d_ready & d_allowed[IN_0][OUT_BEU]
    | DOI[OUT_BEU][IN_1] & auto_in_1_d_ready & d_allowed[IN_1][OUT_BEU];

  // out_1 = CacheCtrl (30 位地址, source 3 位, 无 user)
  assign auto_out_1_a_valid        = a_out_valid[OUT_CACHECTRL];
  assign auto_out_1_a_bits_opcode  = a_sel[OUT_CACHECTRL].opcode;
  assign auto_out_1_a_bits_param   = a_sel[OUT_CACHECTRL].param;
  assign auto_out_1_a_bits_size    = a_sel[OUT_CACHECTRL].size;
  assign auto_out_1_a_bits_source  = a_sel[OUT_CACHECTRL].source;
  assign auto_out_1_a_bits_address = a_sel[OUT_CACHECTRL].address[29:0];
  assign auto_out_1_a_bits_mask    = a_sel[OUT_CACHECTRL].mask;
  assign auto_out_1_a_bits_data    = a_sel[OUT_CACHECTRL].data;
  assign auto_out_1_a_bits_corrupt = a_sel[OUT_CACHECTRL].corrupt;
  assign auto_out_1_d_ready =
      DOI[OUT_CACHECTRL][IN_0] & auto_in_0_d_ready & d_allowed[IN_0][OUT_CACHECTRL]
    | DOI[OUT_CACHECTRL][IN_1] & auto_in_1_d_ready & d_allowed[IN_1][OUT_CACHECTRL];

  // out_2 = Default (48 位全址, source 3 位, 携带 user)
  assign auto_out_2_a_valid        = a_out_valid[OUT_DEFAULT];
  assign auto_out_2_a_bits_opcode  = a_sel[OUT_DEFAULT].opcode;
  assign auto_out_2_a_bits_param   = a_sel[OUT_DEFAULT].param;
  assign auto_out_2_a_bits_size    = a_sel[OUT_DEFAULT].size;
  assign auto_out_2_a_bits_source  = a_sel[OUT_DEFAULT].source;
  assign auto_out_2_a_bits_address = a_sel[OUT_DEFAULT].address;
  assign auto_out_2_a_bits_user_memBackType_MM = a_sel[OUT_DEFAULT].user_MM;
  assign auto_out_2_a_bits_user_memPageType_NC = a_sel[OUT_DEFAULT].user_NC;
  assign auto_out_2_a_bits_mask    = a_sel[OUT_DEFAULT].mask;
  assign auto_out_2_a_bits_data    = a_sel[OUT_DEFAULT].data;
  assign auto_out_2_a_bits_corrupt = a_sel[OUT_DEFAULT].corrupt;
  assign auto_out_2_d_ready =
      DOI[OUT_DEFAULT][IN_0] & auto_in_0_d_ready & d_allowed[IN_0][OUT_DEFAULT]
    | DOI[OUT_DEFAULT][IN_1] & auto_in_1_d_ready & d_allowed[IN_1][OUT_DEFAULT];

  // ===========================================================================
  //  时序: 各仲裁器 beat 计数 / 优先级掩码轮转 / 胜者锁定 (单拍 ⇒ init_beats=0)
  // ===========================================================================
  // A 侧下游 ready / D 侧下游 ready, 供 latch (空闲且下游可收 ⇒ 本拍定胜负)。
  wire [NUM_OUT-1:0] a_ds_ready = {auto_out_2_a_ready, auto_out_1_a_ready, auto_out_0_a_ready};
  wire [NUM_IN-1:0]  d_ds_ready = {auto_in_1_d_ready, auto_in_0_d_ready};

  integer k;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (k = 0; k < NUM_OUT; k = k + 1) begin
        a_beats[k] <= 1'b0;
        a_mask[k]  <= {NUM_IN{1'b1}};
        a_state[k] <= '0;
      end
      for (k = 0; k < NUM_IN; k = k + 1) begin
        d_beats[k] <= 1'b0;
        d_mask[k]  <= {NUM_OUT{1'b1}};
        d_state[k] <= '0;
      end
    end else begin
      // ---- A 仲裁器 (每从口) ----
      for (k = 0; k < NUM_OUT; k = k + 1) begin
        automatic logic latch = ~a_beats[k] & a_ds_ready[k];
        a_beats[k] <= ~latch & (a_beats[k] - (a_ds_ready[k] & a_out_valid[k]));
        if (latch & (|a_valid_vec[k]))
          a_mask[k] <= left_or(MAXN'(a_grant[k] & a_valid_vec[k]), NUM_IN);
        if (~a_beats[k])
          a_state[k] <= a_winner[k];
      end
      // ---- D 仲裁器 (每主口) ----
      for (k = 0; k < NUM_IN; k = k + 1) begin
        automatic logic latch = ~d_beats[k] & d_ds_ready[k];
        d_beats[k] <= ~latch & (d_beats[k] - (d_ds_ready[k] & d_in_valid[k]));
        if (latch & (|d_valid_vec[k]))
          d_mask[k] <= left_or(MAXN'(d_grant[k] & d_valid_vec[k]), NUM_OUT);
        if (~d_beats[k])
          d_state[k] <= d_winner[k];
      end
    end
  end

endmodule
