// =============================================================================
//  TLXbar_1 —— 香山 V2R2 多主 TileLink 交叉开关 (可读重写核 xs_TLXbar_1_core)
// -----------------------------------------------------------------------------
//  源自 rocket-chip TLXbar (src/main/scala/tilelink/Xbar.scala): 2 主口 (in_0/in_1)
//  × 3 从口 (OUT_MEM / OUT_MMIO / OUT_DEV)。从设计意图重写 (非照抄 firtool 优化后
//  的逐位地址掩码与展平命名)。相对 TLXbar_6, 本核多了 burst (多拍) 仲裁锁定。
//
//  A 通道 (主→从): 地址译码 req[in][out] + 每从口对请求它的两主口做轮转仲裁,
//    胜者载荷路由到该从口; 主口 A ready = 命中从口就绪 & 本主口在该从口被授权。
//  D 通道 (从→主): 按 D 的 source 判定应答归属哪个主口 (DOI[out][in]), 每主口对
//    应答它的三从口做轮转仲裁, 胜者载荷回送该主口。
//  burst: 仲裁器空闲 (beatsLeft==0) 且下游 ready 时锁存胜者并按其 size/opcode 装入
//    剩余拍数; 整段 burst 维持 state 不被打断, 每拍 fire 递减 beatsLeft 到 0 再开新仲裁。
//
//  ---------------------------------------------------------------------------
//  round-robin 仲裁算法 (Arbiter.scala 的 roundRobin policy, 通用前缀 OR 重写):
//    filter = {valid & ~mask, valid}; unready=(rightOR(filter,2n,cap=n)>>1)|(mask<<n)
//    grant[i] = ~(unready[i+n] & unready[i]); 胜者: mask <= leftOR(grant & valid)。
//  本核三个 A 仲裁器 n=NUM_IN=2, 两个 D 仲裁器 n=NUM_OUT=3, 共用同组函数 (MAXN=3)。
//
//  验证: golden 同名 TLXbar_1 例化本核 (端口透传)。叶子模块 (无子例化), UT 双例化
//  逐拍比对全部输出; FM 签名分析证组合/时序等价。
// =============================================================================
module xs_TLXbar_1_core
  import tlxbar1_pkg::*;
(
  input         clock,
  input         reset,

  // ---- 主口 in_1 (精简主口: A 无 param/source/user/corrupt; D 无 source) ----
  output        auto_in_1_a_ready,
  input         auto_in_1_a_valid,
  input  [3:0]  auto_in_1_a_bits_opcode,
  input  [2:0]  auto_in_1_a_bits_size,
  input  [48:0] auto_in_1_a_bits_address,
  input  [7:0]  auto_in_1_a_bits_mask,
  input  [63:0] auto_in_1_a_bits_data,
  input         auto_in_1_d_ready,
  output        auto_in_1_d_valid,
  output [3:0]  auto_in_1_d_bits_opcode,
  output [1:0]  auto_in_1_d_bits_param,
  output [2:0]  auto_in_1_d_bits_size,
  output        auto_in_1_d_bits_sink,
  output        auto_in_1_d_bits_denied,
  output [63:0] auto_in_1_d_bits_data,
  output        auto_in_1_d_bits_corrupt,

  // ---- 主口 in_0 (完整 TL-UH: A 带 param/source/AMBA prot/corrupt; D 带 source) ----
  output        auto_in_0_a_ready,
  input         auto_in_0_a_valid,
  input  [3:0]  auto_in_0_a_bits_opcode,
  input  [2:0]  auto_in_0_a_bits_param,
  input  [2:0]  auto_in_0_a_bits_size,
  input  [13:0] auto_in_0_a_bits_source,
  input  [48:0] auto_in_0_a_bits_address,
  input         auto_in_0_a_bits_user_amba_prot_bufferable,
  input         auto_in_0_a_bits_user_amba_prot_modifiable,
  input         auto_in_0_a_bits_user_amba_prot_readalloc,
  input         auto_in_0_a_bits_user_amba_prot_writealloc,
  input         auto_in_0_a_bits_user_amba_prot_privileged,
  input         auto_in_0_a_bits_user_amba_prot_secure,
  input         auto_in_0_a_bits_user_amba_prot_fetch,
  input  [7:0]  auto_in_0_a_bits_mask,
  input  [63:0] auto_in_0_a_bits_data,
  input         auto_in_0_a_bits_corrupt,
  input         auto_in_0_d_ready,
  output        auto_in_0_d_valid,
  output [3:0]  auto_in_0_d_bits_opcode,
  output [1:0]  auto_in_0_d_bits_param,
  output [2:0]  auto_in_0_d_bits_size,
  output [13:0] auto_in_0_d_bits_source,
  output        auto_in_0_d_bits_sink,
  output        auto_in_0_d_bits_denied,
  output [63:0] auto_in_0_d_bits_data,
  output        auto_in_0_d_bits_corrupt,

  // ---- 从口 out_2 = OUT_DEV (30 位地址, 无 user, size 截 2 位; D 字段最全) ----
  input         auto_out_2_a_ready,
  output        auto_out_2_a_valid,
  output [3:0]  auto_out_2_a_bits_opcode,
  output [2:0]  auto_out_2_a_bits_param,
  output [1:0]  auto_out_2_a_bits_size,
  output [14:0] auto_out_2_a_bits_source,
  output [29:0] auto_out_2_a_bits_address,
  output [7:0]  auto_out_2_a_bits_mask,
  output [63:0] auto_out_2_a_bits_data,
  output        auto_out_2_a_bits_corrupt,
  output        auto_out_2_d_ready,
  input         auto_out_2_d_valid,
  input  [3:0]  auto_out_2_d_bits_opcode,
  input  [1:0]  auto_out_2_d_bits_param,
  input  [1:0]  auto_out_2_d_bits_size,
  input  [14:0] auto_out_2_d_bits_source,
  input         auto_out_2_d_bits_sink,
  input         auto_out_2_d_bits_denied,
  input  [63:0] auto_out_2_d_bits_data,
  input         auto_out_2_d_bits_corrupt,

  // ---- 从口 out_1 = OUT_MMIO (31 位地址, 带 AMBA prot; A 无 param/corrupt; D 无 param/sink) ----
  input         auto_out_1_a_ready,
  output        auto_out_1_a_valid,
  output [3:0]  auto_out_1_a_bits_opcode,
  output [2:0]  auto_out_1_a_bits_size,
  output [14:0] auto_out_1_a_bits_source,
  output [30:0] auto_out_1_a_bits_address,
  output        auto_out_1_a_bits_user_amba_prot_bufferable,
  output        auto_out_1_a_bits_user_amba_prot_modifiable,
  output        auto_out_1_a_bits_user_amba_prot_readalloc,
  output        auto_out_1_a_bits_user_amba_prot_writealloc,
  output        auto_out_1_a_bits_user_amba_prot_privileged,
  output        auto_out_1_a_bits_user_amba_prot_secure,
  output        auto_out_1_a_bits_user_amba_prot_fetch,
  output [7:0]  auto_out_1_a_bits_mask,
  output [63:0] auto_out_1_a_bits_data,
  output        auto_out_1_d_ready,
  input         auto_out_1_d_valid,
  input  [3:0]  auto_out_1_d_bits_opcode,
  input  [2:0]  auto_out_1_d_bits_size,
  input  [14:0] auto_out_1_d_bits_source,
  input         auto_out_1_d_bits_denied,
  input  [63:0] auto_out_1_d_bits_data,
  input         auto_out_1_d_bits_corrupt,

  // ---- 从口 out_0 = OUT_MEM (49 位全址, 无 user; D 极简: denied 恒 1, 无 data/param/sink) ----
  input         auto_out_0_a_ready,
  output        auto_out_0_a_valid,
  output [3:0]  auto_out_0_a_bits_opcode,
  output [2:0]  auto_out_0_a_bits_param,
  output [2:0]  auto_out_0_a_bits_size,
  output [14:0] auto_out_0_a_bits_source,
  output [48:0] auto_out_0_a_bits_address,
  output [7:0]  auto_out_0_a_bits_mask,
  output [63:0] auto_out_0_a_bits_data,
  output        auto_out_0_a_bits_corrupt,
  output        auto_out_0_d_ready,
  input         auto_out_0_d_valid,
  input  [3:0]  auto_out_0_d_bits_opcode,
  input  [2:0]  auto_out_0_d_bits_size,
  input  [14:0] auto_out_0_d_bits_source,
  input         auto_out_0_d_bits_corrupt
);

  // ===========================================================================
  //  前缀 OR 通用工具 (rocket-chip util.leftOR / util.rightOR)。
  //  位宽统一取 MAXN, 运行期传入实际路数 n; A 侧 n=NUM_IN=2, D 侧 n=NUM_OUT=3。
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
  //  burst 拍数-1 计算 (TileLink numBeats-1, 8 字节/拍)。与 golden firtool 逐位等价:
  //    8 拍口  : ~((13'h3F << size)[5:3])      —— A 通道两主口 / D 通道 out_0
  //    4 拍口  : ~((12'h1F << size)[4:3]) 零扩展 —— D 通道 out_1
  //  (size<=3 即 ≤8 字节 ⇒ 0 拍剩余, 单拍传输)
  // ===========================================================================
  function automatic logic [2:0] beats8(input logic [2:0] size);
    logic [12:0] t;
    t = 13'h3F << size;
    beats8 = ~t[5:3];
  endfunction
  function automatic logic [2:0] beats4(input logic [2:0] size);
    logic [11:0] t;
    t = 12'h1F << size;
    beats4 = {1'b0, ~t[4:3]};
  endfunction

  // ===========================================================================
  //  主口 A 载荷打包 (超集; in_1 缺失字段填默认: param=0, source=0x4000,
  //  AMBA prot=privileged+secure, corrupt=0 —— 与 golden out 端默认值一致)
  // ===========================================================================
  tl_a_t a_in       [NUM_IN];
  logic  a_in_valid [NUM_IN];

  assign a_in_valid[IN_0] = auto_in_0_a_valid;
  assign a_in_valid[IN_1] = auto_in_1_a_valid;

  // in_0: source 零扩展到 15 位 (= {1'b0, source}); 携带真实 AMBA prot。
  assign a_in[IN_0] = '{
    opcode:  auto_in_0_a_bits_opcode,
    param:   auto_in_0_a_bits_param,
    size:    auto_in_0_a_bits_size,
    source:  {1'b0, auto_in_0_a_bits_source},
    address: auto_in_0_a_bits_address,
    user:    '{bufferable: auto_in_0_a_bits_user_amba_prot_bufferable,
               modifiable: auto_in_0_a_bits_user_amba_prot_modifiable,
               readalloc:  auto_in_0_a_bits_user_amba_prot_readalloc,
               writealloc: auto_in_0_a_bits_user_amba_prot_writealloc,
               privileged: auto_in_0_a_bits_user_amba_prot_privileged,
               secure:     auto_in_0_a_bits_user_amba_prot_secure,
               fetch:      auto_in_0_a_bits_user_amba_prot_fetch},
    mask:    auto_in_0_a_bits_mask,
    data:    auto_in_0_a_bits_data,
    corrupt: auto_in_0_a_bits_corrupt
  };
  // in_1: source 固定 0x4000; AMBA prot 默认 privileged+secure (其余 0)。
  assign a_in[IN_1] = '{
    opcode:  auto_in_1_a_bits_opcode,
    param:   3'b0,
    size:    auto_in_1_a_bits_size,
    source:  IN1_SOURCE_ID,
    address: auto_in_1_a_bits_address,
    user:    '{privileged: 1'b1, secure: 1'b1, default: 1'b0},
    mask:    auto_in_1_a_bits_mask,
    data:    auto_in_1_a_bits_data,
    corrupt: 1'b0
  };

  // ===========================================================================
  //  A 通道地址译码: req[in][out] —— 该主口此刻命中哪个从口。
  //    OUT_MEM  = address[48]   (高位内存半区);
  //    OUT_MMIO = OR over OUT1 AddressSet; OUT_DEV = OR over OUT2 AddressSet。
  // ===========================================================================
  function automatic logic dec_set(input logic [48:0] a,
                                   input logic [48:0] base,
                                   input logic [48:0] mask);
    return (a & ~mask) == base;
  endfunction
  function automatic logic dec_out_mmio(input logic [48:0] a);
    dec_out_mmio = 1'b0;
    for (int k = 0; k < OUT1_NSETS; k++)
      dec_out_mmio |= dec_set(a, OUT1_BASE[k], OUT1_MASK[k]);
  endfunction
  function automatic logic dec_out_dev(input logic [48:0] a);
    dec_out_dev = 1'b0;
    for (int k = 0; k < OUT2_NSETS; k++)
      dec_out_dev |= dec_set(a, OUT2_BASE[k], OUT2_MASK[k]);
  endfunction

  logic [NUM_OUT-1:0] req [NUM_IN];
  always_comb begin
    for (int i = 0; i < NUM_IN; i++) begin
      req[i][OUT_MEM]  = a_in[i].address[48];
      req[i][OUT_MMIO] = dec_out_mmio(a_in[i].address);
      req[i][OUT_DEV]  = dec_out_dev(a_in[i].address);
    end
  end

  // ===========================================================================
  //  从口 D 载荷打包 (超集; 缺失字段填默认: out_0 denied=1/无 data/param/sink,
  //  out_1 无 param/sink, out_2 size 2→3 位零扩展) + D→主口路由判据 DOI[out][in]
  // ===========================================================================
  tl_d_t d_out       [NUM_OUT];
  logic  d_out_valid [NUM_OUT];

  assign d_out_valid[OUT_MEM]  = auto_out_0_d_valid;
  assign d_out_valid[OUT_MMIO] = auto_out_1_d_valid;
  assign d_out_valid[OUT_DEV]  = auto_out_2_d_valid;

  // out_0: 极简 D —— denied 恒 1, 无 param/sink/data。
  assign d_out[OUT_MEM] = '{opcode:  auto_out_0_d_bits_opcode, param: 2'b0,
                            size:    auto_out_0_d_bits_size,   source: auto_out_0_d_bits_source,
                            sink:    1'b0,                     denied: 1'b1,
                            data:    64'b0,                    corrupt: auto_out_0_d_bits_corrupt};
  // out_1: 无 param/sink。
  assign d_out[OUT_MMIO] = '{opcode:  auto_out_1_d_bits_opcode, param: 2'b0,
                             size:    auto_out_1_d_bits_size,   source: auto_out_1_d_bits_source,
                             sink:    1'b0,                     denied: auto_out_1_d_bits_denied,
                             data:    auto_out_1_d_bits_data,   corrupt: auto_out_1_d_bits_corrupt};
  // out_2: 字段最全 (size 由 2 位零扩展到 3 位)。
  assign d_out[OUT_DEV] = '{opcode:  auto_out_2_d_bits_opcode, param: auto_out_2_d_bits_param,
                            size:    {1'b0, auto_out_2_d_bits_size}, source: auto_out_2_d_bits_source,
                            sink:    auto_out_2_d_bits_sink,   denied: auto_out_2_d_bits_denied,
                            data:    auto_out_2_d_bits_data,   corrupt: auto_out_2_d_bits_corrupt};

  // 应答归属: source[14]==0 ⇒ in_0; source==0x4000 ⇒ in_1 (两者非互补, 忠实 golden)。
  logic DOI [NUM_OUT][NUM_IN];
  always_comb begin
    for (int o = 0; o < NUM_OUT; o++) begin
      DOI[o][IN_0] = ~d_out[o].source[14];
      DOI[o][IN_1] = (d_out[o].source == IN1_SOURCE_ID);
    end
  end

  // ===========================================================================
  //  A 侧仲裁器: 每个从口一个 (NUM_OUT 个), 各对 NUM_IN 个主口轮转仲裁 + burst 锁定
  // ===========================================================================
  reg  [2:0]         a_beats [NUM_OUT];   // 剩余拍数 (==0 即 idle)
  reg  [NUM_IN-1:0]  a_mask  [NUM_OUT];   // 优先级掩码 (RegInit 全 1)
  reg  [NUM_IN-1:0]  a_state [NUM_OUT];   // 锁定胜者 (burst 期间维持)

  logic              a_idle      [NUM_OUT];
  logic [NUM_IN-1:0] a_valid_vec [NUM_OUT];  // 请求本从口且 valid 的主口集合
  logic [NUM_IN-1:0] a_grant     [NUM_OUT];
  logic [NUM_IN-1:0] a_winner    [NUM_OUT];
  logic [NUM_IN-1:0] a_muxsel    [NUM_OUT];
  logic [NUM_IN-1:0] a_allowed   [NUM_OUT];
  logic              a_out_valid [NUM_OUT];
  logic [2:0]        a_latch_beats [NUM_OUT];
  tl_a_t             a_sel       [NUM_OUT];

  always_comb begin
    logic [MAXN-1:0] g;
    for (int o = 0; o < NUM_OUT; o++) begin
      a_idle[o] = (a_beats[o] == 3'h0);
      for (int i = 0; i < NUM_IN; i++)
        a_valid_vec[o][i] = a_in_valid[i] & req[i][o];
      g            = rr_grant(MAXN'(a_valid_vec[o]), MAXN'(a_mask[o]), NUM_IN);
      a_grant[o]   = g[NUM_IN-1:0];
      a_winner[o]  = a_grant[o] & a_valid_vec[o];
      a_muxsel[o]  = a_idle[o] ? a_winner[o] : a_state[o];
      a_allowed[o] = a_idle[o] ? a_grant[o]  : a_state[o];
      a_out_valid[o] = a_idle[o] ? (|a_valid_vec[o]) : (|(a_state[o] & a_valid_vec[o]));
      // one-hot 选择胜者主口的 A 载荷 (至多一位 muxsel, OR 归约即多路选择)。
      a_sel[o] = '0;
      for (int i = 0; i < NUM_IN; i++)
        if (a_muxsel[o][i]) a_sel[o] |= a_in[i];
      // 锁存时的剩余拍数: 仅 Put 类 (opcode[2]==0) 多拍, 两主口同用 8 拍解码。
      a_latch_beats[o] =
          (a_winner[o][IN_0] & ~a_in[IN_0].opcode[2] ? beats8(a_in[IN_0].size) : 3'h0)
        | (a_winner[o][IN_1] & ~a_in[IN_1].opcode[2] ? beats8(a_in[IN_1].size) : 3'h0);
    end
  end

  // ===========================================================================
  //  D 侧仲裁器: 每个主口一个 (NUM_IN 个), 各对 NUM_OUT 个从口轮转仲裁 + burst 锁定
  // ===========================================================================
  reg  [2:0]          d_beats [NUM_IN];
  reg  [NUM_OUT-1:0]  d_mask  [NUM_IN];
  reg  [NUM_OUT-1:0]  d_state [NUM_IN];

  logic               d_idle      [NUM_IN];
  logic [NUM_OUT-1:0] d_valid_vec [NUM_IN];  // 应答本主口且 valid 的从口集合
  logic [NUM_OUT-1:0] d_grant     [NUM_IN];
  logic [NUM_OUT-1:0] d_winner    [NUM_IN];
  logic [NUM_OUT-1:0] d_muxsel    [NUM_IN];
  logic [NUM_OUT-1:0] d_allowed   [NUM_IN];
  logic               d_in_valid  [NUM_IN];
  logic [2:0]         d_latch_beats [NUM_IN];
  tl_d_t              d_sel       [NUM_IN];

  always_comb begin
    logic [MAXN-1:0] g;
    for (int i = 0; i < NUM_IN; i++) begin
      d_idle[i] = (d_beats[i] == 3'h0);
      for (int o = 0; o < NUM_OUT; o++)
        d_valid_vec[i][o] = d_out_valid[o] & DOI[o][i];
      g            = rr_grant(MAXN'(d_valid_vec[i]), MAXN'(d_mask[i]), NUM_OUT);
      d_grant[i]   = g[NUM_OUT-1:0];
      d_winner[i]  = d_grant[i] & d_valid_vec[i];
      d_muxsel[i]  = d_idle[i] ? d_winner[i] : d_state[i];
      d_allowed[i] = d_idle[i] ? d_grant[i]  : d_state[i];
      d_in_valid[i] = d_idle[i] ? (|d_valid_vec[i]) : (|(d_state[i] & d_valid_vec[i]));
      d_sel[i] = '0;
      for (int o = 0; o < NUM_OUT; o++)
        if (d_muxsel[i][o]) d_sel[i] |= d_out[o];
      // 锁存拍数: 仅 *AckData (opcode[0]==1) 多拍; out_0 用 8 拍解码, out_1 用 4 拍,
      // out_2 (片上设备) 恒单拍 (不贡献拍数)。
      d_latch_beats[i] =
          (d_winner[i][OUT_MEM]  & d_out[OUT_MEM].opcode[0]  ? beats8(d_out[OUT_MEM].size)  : 3'h0)
        | (d_winner[i][OUT_MMIO] & d_out[OUT_MMIO].opcode[0] ? beats4(d_out[OUT_MMIO].size) : 3'h0);
    end
  end

  // ===========================================================================
  //  主口 A ready —— 命中从口就绪 & 本主口在该从口仲裁中被授权 (allowed)。
  // ===========================================================================
  assign auto_in_0_a_ready =
      req[IN_0][OUT_MEM]  & auto_out_0_a_ready & a_allowed[OUT_MEM][IN_0]
    | req[IN_0][OUT_MMIO] & auto_out_1_a_ready & a_allowed[OUT_MMIO][IN_0]
    | req[IN_0][OUT_DEV]  & auto_out_2_a_ready & a_allowed[OUT_DEV][IN_0];
  assign auto_in_1_a_ready =
      req[IN_1][OUT_MEM]  & auto_out_0_a_ready & a_allowed[OUT_MEM][IN_1]
    | req[IN_1][OUT_MMIO] & auto_out_1_a_ready & a_allowed[OUT_MMIO][IN_1]
    | req[IN_1][OUT_DEV]  & auto_out_2_a_ready & a_allowed[OUT_DEV][IN_1];

  // ===========================================================================
  //  主口 D 输出 (in_0 带 14 位 source; in_1 无 source 端口)
  // ===========================================================================
  assign auto_in_0_d_valid       = d_in_valid[IN_0];
  assign auto_in_0_d_bits_opcode = d_sel[IN_0].opcode;
  assign auto_in_0_d_bits_param  = d_sel[IN_0].param;
  assign auto_in_0_d_bits_size   = d_sel[IN_0].size;
  assign auto_in_0_d_bits_source = d_sel[IN_0].source[13:0];
  assign auto_in_0_d_bits_sink   = d_sel[IN_0].sink;
  assign auto_in_0_d_bits_denied = d_sel[IN_0].denied;
  assign auto_in_0_d_bits_data   = d_sel[IN_0].data;
  assign auto_in_0_d_bits_corrupt= d_sel[IN_0].corrupt;

  assign auto_in_1_d_valid       = d_in_valid[IN_1];
  assign auto_in_1_d_bits_opcode = d_sel[IN_1].opcode;
  assign auto_in_1_d_bits_param  = d_sel[IN_1].param;
  assign auto_in_1_d_bits_size   = d_sel[IN_1].size;
  assign auto_in_1_d_bits_sink   = d_sel[IN_1].sink;
  assign auto_in_1_d_bits_denied = d_sel[IN_1].denied;
  assign auto_in_1_d_bits_data   = d_sel[IN_1].data;
  assign auto_in_1_d_bits_corrupt= d_sel[IN_1].corrupt;

  // ===========================================================================
  //  从口 A 输出 (窄从口截断地址/size; out_1 带 AMBA prot) / 从口 D ready
  // ===========================================================================
  // out_0 = OUT_MEM (49 位全址, 无 user)
  assign auto_out_0_a_valid        = a_out_valid[OUT_MEM];
  assign auto_out_0_a_bits_opcode  = a_sel[OUT_MEM].opcode;
  assign auto_out_0_a_bits_param   = a_sel[OUT_MEM].param;
  assign auto_out_0_a_bits_size    = a_sel[OUT_MEM].size;
  assign auto_out_0_a_bits_source  = a_sel[OUT_MEM].source;
  assign auto_out_0_a_bits_address = a_sel[OUT_MEM].address;
  assign auto_out_0_a_bits_mask    = a_sel[OUT_MEM].mask;
  assign auto_out_0_a_bits_data    = a_sel[OUT_MEM].data;
  assign auto_out_0_a_bits_corrupt = a_sel[OUT_MEM].corrupt;
  assign auto_out_0_d_ready =
      DOI[OUT_MEM][IN_0] & auto_in_0_d_ready & d_allowed[IN_0][OUT_MEM]
    | DOI[OUT_MEM][IN_1] & auto_in_1_d_ready & d_allowed[IN_1][OUT_MEM];

  // out_1 = OUT_MMIO (31 位地址, 带 AMBA prot, 无 corrupt)
  assign auto_out_1_a_valid        = a_out_valid[OUT_MMIO];
  assign auto_out_1_a_bits_opcode  = a_sel[OUT_MMIO].opcode;
  assign auto_out_1_a_bits_size    = a_sel[OUT_MMIO].size;
  assign auto_out_1_a_bits_source  = a_sel[OUT_MMIO].source;
  assign auto_out_1_a_bits_address = a_sel[OUT_MMIO].address[30:0];
  assign auto_out_1_a_bits_user_amba_prot_bufferable = a_sel[OUT_MMIO].user.bufferable;
  assign auto_out_1_a_bits_user_amba_prot_modifiable = a_sel[OUT_MMIO].user.modifiable;
  assign auto_out_1_a_bits_user_amba_prot_readalloc  = a_sel[OUT_MMIO].user.readalloc;
  assign auto_out_1_a_bits_user_amba_prot_writealloc = a_sel[OUT_MMIO].user.writealloc;
  assign auto_out_1_a_bits_user_amba_prot_privileged = a_sel[OUT_MMIO].user.privileged;
  assign auto_out_1_a_bits_user_amba_prot_secure     = a_sel[OUT_MMIO].user.secure;
  assign auto_out_1_a_bits_user_amba_prot_fetch      = a_sel[OUT_MMIO].user.fetch;
  assign auto_out_1_a_bits_mask    = a_sel[OUT_MMIO].mask;
  assign auto_out_1_a_bits_data    = a_sel[OUT_MMIO].data;
  assign auto_out_1_d_ready =
      DOI[OUT_MMIO][IN_0] & auto_in_0_d_ready & d_allowed[IN_0][OUT_MMIO]
    | DOI[OUT_MMIO][IN_1] & auto_in_1_d_ready & d_allowed[IN_1][OUT_MMIO];

  // out_2 = OUT_DEV (30 位地址, size 截 2 位, 无 user)
  assign auto_out_2_a_valid        = a_out_valid[OUT_DEV];
  assign auto_out_2_a_bits_opcode  = a_sel[OUT_DEV].opcode;
  assign auto_out_2_a_bits_param   = a_sel[OUT_DEV].param;
  assign auto_out_2_a_bits_size    = a_sel[OUT_DEV].size[1:0];
  assign auto_out_2_a_bits_source  = a_sel[OUT_DEV].source;
  assign auto_out_2_a_bits_address = a_sel[OUT_DEV].address[29:0];
  assign auto_out_2_a_bits_mask    = a_sel[OUT_DEV].mask;
  assign auto_out_2_a_bits_data    = a_sel[OUT_DEV].data;
  assign auto_out_2_a_bits_corrupt = a_sel[OUT_DEV].corrupt;
  assign auto_out_2_d_ready =
      DOI[OUT_DEV][IN_0] & auto_in_0_d_ready & d_allowed[IN_0][OUT_DEV]
    | DOI[OUT_DEV][IN_1] & auto_in_1_d_ready & d_allowed[IN_1][OUT_DEV];

  // ===========================================================================
  //  时序: 各仲裁器 beat 计数 / 优先级掩码轮转 / 胜者锁定
  // ===========================================================================
  // A 侧下游 ready (index: [0]=out_0,[1]=out_1,[2]=out_2) / D 侧下游 ready ([0]=in_0,[1]=in_1)。
  wire [NUM_OUT-1:0] a_ds_ready = {auto_out_2_a_ready, auto_out_1_a_ready, auto_out_0_a_ready};
  wire [NUM_IN-1:0]  d_ds_ready = {auto_in_1_d_ready, auto_in_0_d_ready};

  // "本拍开始新一轮传输"标志 (idle 且下游 ready): 纯组合量。必须在 always_comb 里算,
  // 若像原来那样写成 always_ff 内的 automatic 临时变量, 综合/Formality 会把每个循环
  // 迭代的该量各推断成一个无跨拍扇出的死锁存器 (a 侧 NUM_OUT 个 + d 侧 NUM_IN 个)。
  logic [NUM_OUT-1:0] a_load;
  logic [NUM_IN-1:0]  d_load;
  always_comb begin
    for (int j = 0; j < NUM_OUT; j = j + 1) a_load[j] = a_idle[j] & a_ds_ready[j];
    for (int j = 0; j < NUM_IN;  j = j + 1) d_load[j] = d_idle[j] & d_ds_ready[j];
  end

  integer k;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (k = 0; k < NUM_OUT; k = k + 1) begin
        a_beats[k] <= 3'h0;
        a_mask[k]  <= {NUM_IN{1'b1}};
        a_state[k] <= '0;
      end
      for (k = 0; k < NUM_IN; k = k + 1) begin
        d_beats[k] <= 3'h0;
        d_mask[k]  <= {NUM_OUT{1'b1}};
        d_state[k] <= '0;
      end
    end else begin
      // ---- A 仲裁器 (每从口) ----
      for (k = 0; k < NUM_OUT; k = k + 1) begin
        if (a_load[k])
          a_beats[k] <= a_latch_beats[k];
        else
          a_beats[k] <= a_beats[k] - {2'h0, a_ds_ready[k] & a_out_valid[k]};
        if (a_load[k] & (|a_valid_vec[k]))
          a_mask[k] <= left_or(MAXN'(a_winner[k]), NUM_IN);
        if (a_idle[k])
          a_state[k] <= a_winner[k];
      end
      // ---- D 仲裁器 (每主口) ----
      for (k = 0; k < NUM_IN; k = k + 1) begin
        if (d_load[k])
          d_beats[k] <= d_latch_beats[k];
        else
          d_beats[k] <= d_beats[k] - {2'h0, d_ds_ready[k] & d_in_valid[k]};
        if (d_load[k] & (|d_valid_vec[k]))
          d_mask[k] <= left_or(MAXN'(d_winner[k]), NUM_OUT);
        if (d_idle[k])
          d_state[k] <= d_winner[k];
      end
    end
  end

endmodule
