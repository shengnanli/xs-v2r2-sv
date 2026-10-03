// =============================================================================
//  tlxbar6_pkg —— TLXbar_6（L2Top 的 mmio_xbar：2 主 × 3 从 TileLink-UL 交叉开关）的常量与类型
// -----------------------------------------------------------------------------
//  对应 rocket-chip 的 TLXbar（tilelink/Xbar.scala），在 src/main/scala/xiangshan/L2Top.scala
//  里叫 mmio_xbar：核内两条 uncache 通路的 MMIO 访问（64 位单字、单拍）汇到这里，
//  再按地址分给三个从口：
//    in0 = i_mmio（取指侧 InstrUncache，source 只有 1 位；进入交叉开关后 source 加前缀 4'h8 = 16/17）
//    in1 = d_mmio（访存侧 Uncache，source 4 位；前缀 1'b0 = 0..15）
//    out0 = BEU（总线错误单元寄存器，AddressSet(0x38010000, 0xfff)，30 位地址，无 user 字段）
//    out1 = 缓存控制寄存器区（AddressSet(0x38022000, 0xff)：DCacheCtrl 0x38022000/0x7f +
//           ICacheCtrl 0x38022080/0x7f 合在一个从口，30 位地址，无 user 字段）
//    out2 = mmio_port（其余全部地址，经 TLFilter 去掉核内区间后送往 L3/外设；48 位地址，
//           携带 user 的 memBackType_MM / memPageType_NC）
//  D 通道回程按 source 前缀分流：source == 5'h10 回 in0（in0 的 source 位是 1 位，
//  firtool 只认 16 这一个值 —— 置 1 的那一半（17）回不去，照 golden 不"修"），
//  source[4] == 0 回 in1（0..15）。
//
//  全部消息单拍（数据 64 位、size ≤ 3），各仲裁器的 beat 计数退化（恒处 idle）。
// =============================================================================
package tlxbar6_pkg;

  localparam int NUM_IN  = 2;
  localparam int NUM_OUT = 3;

  typedef enum logic [1:0] {
    IN_IMMIO = 2'd0,   // in0：取指侧 uncache
    IN_DMMIO = 2'd1    // in1：访存侧 uncache
  } in_port_e;

  typedef enum logic [1:0] {
    OUT_BEU       = 2'd0,   // out0：BEU 寄存器
    OUT_CACHECTRL = 2'd1,   // out1：I/D 缓存控制寄存器
    OUT_MMIO      = 2'd2    // out2：默认 catch-all（去 L3/外设）
  } out_port_e;

  localparam int A_OPCODE_W = 4;
  localparam int A_PARAM_W  = 3;
  localparam int A_SIZE_W   = 2;
  localparam int SOURCE_W   = 5;    // 交叉开关内部统一的 source 位宽（含主口前缀）
  localparam int ADDR_W     = 48;
  localparam int MASK_W     = 8;
  localparam int DATA_W     = 64;
  localparam int D_OPCODE_W = 4;
  localparam int D_PARAM_W  = 2;
  localparam int D_SIZE_W   = 2;

  // 主口 source 前缀（TLXbar 把各主口的 source 空间错开：in0 从 16 起、in1 从 0 起）
  localparam logic [SOURCE_W-1:0] IMMIO_SOURCE_BASE = 5'h10;

  // A 通道载荷（从口字段的并集；out0/out1 不带 user 字段、地址截到 30 位）
  typedef struct packed {
    logic [A_OPCODE_W-1:0] opcode;
    logic [A_PARAM_W-1:0]  param;
    logic [A_SIZE_W-1:0]   size;
    logic [SOURCE_W-1:0]   source;
    logic [ADDR_W-1:0]     address;
    logic                  user_memBackType_MM;
    logic                  user_memPageType_NC;
    logic [MASK_W-1:0]     mask;
    logic [DATA_W-1:0]     data;
    logic                  corrupt;
  } tl_a_t;

  // D 通道载荷（三个从口字段对称）
  typedef struct packed {
    logic [D_OPCODE_W-1:0] opcode;
    logic [D_PARAM_W-1:0]  param;
    logic [D_SIZE_W-1:0]   size;
    logic [SOURCE_W-1:0]   source;
    logic                  sink;
    logic                  denied;
    logic [DATA_W-1:0]     data;
    logic                  corrupt;
  } tl_d_t;

  // 地址映射（Scala AddressSet(base, mask)：(addr & ~mask) == base）
  localparam logic [ADDR_W-1:0] BEU_BASE       = 48'h3801_0000;
  localparam logic [ADDR_W-1:0] BEU_MASK       = 48'hFFF;
  localparam logic [ADDR_W-1:0] CACHECTRL_BASE = 48'h3802_2000;
  localparam logic [ADDR_W-1:0] CACHECTRL_MASK = 48'hFF;

endpackage

// =============================================================================
//  xs_TLXbar_6_core —— 可读核
// -----------------------------------------------------------------------------
//  · A 通道（主→从）：每个主口按地址译码得到 request[k][o]，从口 o 的 A 由一个
//    2 路 round-robin 仲裁器（xs_TLArbiterRoundRobin）在"要去 o 的主口"之间选；
//    主口 ready = 命中从口的仲裁器给本路的 ready。
//  · D 通道（从→主）：每个从口的应答按 source 前缀分流到主口，主口 i 的 D 由一个
//    3 路 round-robin 仲裁器在"要回 i 的从口"之间选；从口 ready 同理汇聚。
//  · 单拍配置：仲裁器 src_beats1 全接 0。
// =============================================================================
module xs_TLXbar_6_core
  import tlxbar6_pkg::*;
(
  input  logic        clock,
  input  logic        reset,
  // ---- in1 = d_mmio ----
  output logic        auto_in_1_a_ready,
  input  logic        auto_in_1_a_valid,
  input  logic [3:0]  auto_in_1_a_bits_opcode,
  input  logic [2:0]  auto_in_1_a_bits_param,
  input  logic [1:0]  auto_in_1_a_bits_size,
  input  logic [3:0]  auto_in_1_a_bits_source,
  input  logic [47:0] auto_in_1_a_bits_address,
  input  logic        auto_in_1_a_bits_user_memBackType_MM,
  input  logic        auto_in_1_a_bits_user_memPageType_NC,
  input  logic [7:0]  auto_in_1_a_bits_mask,
  input  logic [63:0] auto_in_1_a_bits_data,
  input  logic        auto_in_1_a_bits_corrupt,
  input  logic        auto_in_1_d_ready,
  output logic        auto_in_1_d_valid,
  output logic [3:0]  auto_in_1_d_bits_opcode,
  output logic [1:0]  auto_in_1_d_bits_param,
  output logic [1:0]  auto_in_1_d_bits_size,
  output logic [3:0]  auto_in_1_d_bits_source,
  output logic        auto_in_1_d_bits_sink,
  output logic        auto_in_1_d_bits_denied,
  output logic [63:0] auto_in_1_d_bits_data,
  output logic        auto_in_1_d_bits_corrupt,
  // ---- in0 = i_mmio ----
  output logic        auto_in_0_a_ready,
  input  logic        auto_in_0_a_valid,
  input  logic [3:0]  auto_in_0_a_bits_opcode,
  input  logic [2:0]  auto_in_0_a_bits_param,
  input  logic [1:0]  auto_in_0_a_bits_size,
  input  logic        auto_in_0_a_bits_source,
  input  logic [47:0] auto_in_0_a_bits_address,
  input  logic        auto_in_0_a_bits_user_memPageType_NC,
  input  logic        auto_in_0_a_bits_user_memBackType_MM,
  input  logic [7:0]  auto_in_0_a_bits_mask,
  input  logic [63:0] auto_in_0_a_bits_data,
  input  logic        auto_in_0_a_bits_corrupt,
  input  logic        auto_in_0_d_ready,
  output logic        auto_in_0_d_valid,
  output logic [3:0]  auto_in_0_d_bits_opcode,
  output logic [1:0]  auto_in_0_d_bits_param,
  output logic [1:0]  auto_in_0_d_bits_size,
  output logic        auto_in_0_d_bits_sink,
  output logic        auto_in_0_d_bits_denied,
  output logic [63:0] auto_in_0_d_bits_data,
  output logic        auto_in_0_d_bits_corrupt,
  // ---- out2 = mmio_port（48 位地址，带 user）----
  input  logic        auto_out_2_a_ready,
  output logic        auto_out_2_a_valid,
  output logic [3:0]  auto_out_2_a_bits_opcode,
  output logic [2:0]  auto_out_2_a_bits_param,
  output logic [1:0]  auto_out_2_a_bits_size,
  output logic [4:0]  auto_out_2_a_bits_source,
  output logic [47:0] auto_out_2_a_bits_address,
  output logic        auto_out_2_a_bits_user_memBackType_MM,
  output logic        auto_out_2_a_bits_user_memPageType_NC,
  output logic [7:0]  auto_out_2_a_bits_mask,
  output logic [63:0] auto_out_2_a_bits_data,
  output logic        auto_out_2_a_bits_corrupt,
  output logic        auto_out_2_d_ready,
  input  logic        auto_out_2_d_valid,
  input  logic [3:0]  auto_out_2_d_bits_opcode,
  input  logic [1:0]  auto_out_2_d_bits_param,
  input  logic [1:0]  auto_out_2_d_bits_size,
  input  logic [4:0]  auto_out_2_d_bits_source,
  input  logic        auto_out_2_d_bits_sink,
  input  logic        auto_out_2_d_bits_denied,
  input  logic [63:0] auto_out_2_d_bits_data,
  input  logic        auto_out_2_d_bits_corrupt,
  // ---- out1 = 缓存控制寄存器（30 位地址）----
  input  logic        auto_out_1_a_ready,
  output logic        auto_out_1_a_valid,
  output logic [3:0]  auto_out_1_a_bits_opcode,
  output logic [2:0]  auto_out_1_a_bits_param,
  output logic [1:0]  auto_out_1_a_bits_size,
  output logic [4:0]  auto_out_1_a_bits_source,
  output logic [29:0] auto_out_1_a_bits_address,
  output logic [7:0]  auto_out_1_a_bits_mask,
  output logic [63:0] auto_out_1_a_bits_data,
  output logic        auto_out_1_a_bits_corrupt,
  output logic        auto_out_1_d_ready,
  input  logic        auto_out_1_d_valid,
  input  logic [3:0]  auto_out_1_d_bits_opcode,
  input  logic [1:0]  auto_out_1_d_bits_param,
  input  logic [1:0]  auto_out_1_d_bits_size,
  input  logic [4:0]  auto_out_1_d_bits_source,
  input  logic        auto_out_1_d_bits_sink,
  input  logic        auto_out_1_d_bits_denied,
  input  logic [63:0] auto_out_1_d_bits_data,
  input  logic        auto_out_1_d_bits_corrupt,
  // ---- out0 = BEU（30 位地址）----
  input  logic        auto_out_0_a_ready,
  output logic        auto_out_0_a_valid,
  output logic [3:0]  auto_out_0_a_bits_opcode,
  output logic [2:0]  auto_out_0_a_bits_param,
  output logic [1:0]  auto_out_0_a_bits_size,
  output logic [4:0]  auto_out_0_a_bits_source,
  output logic [29:0] auto_out_0_a_bits_address,
  output logic [7:0]  auto_out_0_a_bits_mask,
  output logic [63:0] auto_out_0_a_bits_data,
  output logic        auto_out_0_a_bits_corrupt,
  output logic        auto_out_0_d_ready,
  input  logic        auto_out_0_d_valid,
  input  logic [3:0]  auto_out_0_d_bits_opcode,
  input  logic [1:0]  auto_out_0_d_bits_param,
  input  logic [1:0]  auto_out_0_d_bits_size,
  input  logic [4:0]  auto_out_0_d_bits_source,
  input  logic        auto_out_0_d_bits_sink,
  input  logic        auto_out_0_d_bits_denied,
  input  logic [63:0] auto_out_0_d_bits_data,
  input  logic        auto_out_0_d_bits_corrupt
);

  // ===========================================================================
  //  一、主口 A 打包 + 地址译码
  // ===========================================================================
  logic  [NUM_IN-1:0] in_a_valid;
  tl_a_t              in_a_bits [NUM_IN];
  logic  [NUM_IN-1:0] in_a_ready;

  assign in_a_valid[IN_IMMIO] = auto_in_0_a_valid;
  assign in_a_bits[IN_IMMIO]  = '{opcode:  auto_in_0_a_bits_opcode,
                                  param:   auto_in_0_a_bits_param,
                                  size:    auto_in_0_a_bits_size,
                                  source:  IMMIO_SOURCE_BASE | 5'(auto_in_0_a_bits_source),
                                  address: auto_in_0_a_bits_address,
                                  user_memBackType_MM: auto_in_0_a_bits_user_memBackType_MM,
                                  user_memPageType_NC: auto_in_0_a_bits_user_memPageType_NC,
                                  mask:    auto_in_0_a_bits_mask,
                                  data:    auto_in_0_a_bits_data,
                                  corrupt: auto_in_0_a_bits_corrupt};
  assign in_a_valid[IN_DMMIO] = auto_in_1_a_valid;
  assign in_a_bits[IN_DMMIO]  = '{opcode:  auto_in_1_a_bits_opcode,
                                  param:   auto_in_1_a_bits_param,
                                  size:    auto_in_1_a_bits_size,
                                  source:  5'(auto_in_1_a_bits_source),
                                  address: auto_in_1_a_bits_address,
                                  user_memBackType_MM: auto_in_1_a_bits_user_memBackType_MM,
                                  user_memPageType_NC: auto_in_1_a_bits_user_memPageType_NC,
                                  mask:    auto_in_1_a_bits_mask,
                                  data:    auto_in_1_a_bits_data,
                                  corrupt: auto_in_1_a_bits_corrupt};
  assign auto_in_0_a_ready = in_a_ready[IN_IMMIO];
  assign auto_in_1_a_ready = in_a_ready[IN_DMMIO];

  // request_a[k][o]：主口 k 的地址落在从口 o 的区间里（out2 = 其余全部）
  logic [NUM_OUT-1:0] request_a [NUM_IN];
  always_comb begin
    for (int k = 0; k < NUM_IN; k++) begin
      request_a[k][OUT_BEU]       = (in_a_bits[k].address & ~BEU_MASK)       == BEU_BASE;
      request_a[k][OUT_CACHECTRL] = (in_a_bits[k].address & ~CACHECTRL_MASK) == CACHECTRL_BASE;
      request_a[k][OUT_MMIO]      = ~request_a[k][OUT_BEU] & ~request_a[k][OUT_CACHECTRL];
    end
  end

  // ===========================================================================
  //  二、从口 A：每个从口一个 2 路 round-robin 仲裁器
  // ===========================================================================
  logic  [NUM_OUT-1:0] out_a_ready, out_a_valid;
  tl_a_t               out_a_bits [NUM_OUT];
  assign out_a_ready[OUT_BEU]       = auto_out_0_a_ready;
  assign out_a_ready[OUT_CACHECTRL] = auto_out_1_a_ready;
  assign out_a_ready[OUT_MMIO]      = auto_out_2_a_ready;

  // arb_a_ready[o][k]：从口 o 的仲裁器给主口 k 的 ready
  logic [NUM_IN-1:0] arb_a_valid [NUM_OUT];
  logic [NUM_IN-1:0] arb_a_ready [NUM_OUT];
  for (genvar o = 0; o < NUM_OUT; o++) begin : g_out_a
    tl_a_t src_bits [NUM_IN];
    logic [NUM_IN-1:0][$bits(tl_a_t)-1:0] src_bits_flat;
    for (genvar k = 0; k < NUM_IN; k++) begin : g_src
      assign arb_a_valid[o][k]  = in_a_valid[k] & request_a[k][o];
      assign src_bits_flat[k]   = in_a_bits[k];
    end
    xs_TLArbiterRoundRobin #(.N(NUM_IN), .W($bits(tl_a_t))) u_arb (
      .clock     (clock),
      .reset     (reset),
      .src_valid (arb_a_valid[o]),
      .src_ready (arb_a_ready[o]),
      .src_bits  (src_bits_flat),
      .src_beats1('0),                       // 单拍
      .sink_ready(out_a_ready[o]),
      .sink_valid(out_a_valid[o]),
      .sink_bits (out_a_bits[o])
    );
  end

  // 主口 ready = 命中从口的仲裁器给本路的 ready
  always_comb begin
    for (int k = 0; k < NUM_IN; k++) begin
      in_a_ready[k] = 1'b0;
      for (int o = 0; o < NUM_OUT; o++)
        in_a_ready[k] |= request_a[k][o] & arb_a_ready[o][k];
    end
  end

  // 拆到从口端口：out0/out1 地址截 30 位、不带 user
  assign auto_out_0_a_valid        = out_a_valid[OUT_BEU];
  assign auto_out_0_a_bits_opcode  = out_a_bits[OUT_BEU].opcode;
  assign auto_out_0_a_bits_param   = out_a_bits[OUT_BEU].param;
  assign auto_out_0_a_bits_size    = out_a_bits[OUT_BEU].size;
  assign auto_out_0_a_bits_source  = out_a_bits[OUT_BEU].source;
  assign auto_out_0_a_bits_address = out_a_bits[OUT_BEU].address[29:0];
  assign auto_out_0_a_bits_mask    = out_a_bits[OUT_BEU].mask;
  assign auto_out_0_a_bits_data    = out_a_bits[OUT_BEU].data;
  assign auto_out_0_a_bits_corrupt = out_a_bits[OUT_BEU].corrupt;

  assign auto_out_1_a_valid        = out_a_valid[OUT_CACHECTRL];
  assign auto_out_1_a_bits_opcode  = out_a_bits[OUT_CACHECTRL].opcode;
  assign auto_out_1_a_bits_param   = out_a_bits[OUT_CACHECTRL].param;
  assign auto_out_1_a_bits_size    = out_a_bits[OUT_CACHECTRL].size;
  assign auto_out_1_a_bits_source  = out_a_bits[OUT_CACHECTRL].source;
  assign auto_out_1_a_bits_address = out_a_bits[OUT_CACHECTRL].address[29:0];
  assign auto_out_1_a_bits_mask    = out_a_bits[OUT_CACHECTRL].mask;
  assign auto_out_1_a_bits_data    = out_a_bits[OUT_CACHECTRL].data;
  assign auto_out_1_a_bits_corrupt = out_a_bits[OUT_CACHECTRL].corrupt;

  assign auto_out_2_a_valid        = out_a_valid[OUT_MMIO];
  assign auto_out_2_a_bits_opcode  = out_a_bits[OUT_MMIO].opcode;
  assign auto_out_2_a_bits_param   = out_a_bits[OUT_MMIO].param;
  assign auto_out_2_a_bits_size    = out_a_bits[OUT_MMIO].size;
  assign auto_out_2_a_bits_source  = out_a_bits[OUT_MMIO].source;
  assign auto_out_2_a_bits_address = out_a_bits[OUT_MMIO].address;
  assign auto_out_2_a_bits_user_memBackType_MM = out_a_bits[OUT_MMIO].user_memBackType_MM;
  assign auto_out_2_a_bits_user_memPageType_NC = out_a_bits[OUT_MMIO].user_memPageType_NC;
  assign auto_out_2_a_bits_mask    = out_a_bits[OUT_MMIO].mask;
  assign auto_out_2_a_bits_data    = out_a_bits[OUT_MMIO].data;
  assign auto_out_2_a_bits_corrupt = out_a_bits[OUT_MMIO].corrupt;

  // ===========================================================================
  //  三、从口 D 打包 + 按 source 前缀分流
  // ===========================================================================
  logic  [NUM_OUT-1:0] out_d_valid, out_d_ready;
  tl_d_t               out_d_bits [NUM_OUT];
  assign out_d_valid[OUT_BEU]       = auto_out_0_d_valid;
  assign out_d_valid[OUT_CACHECTRL] = auto_out_1_d_valid;
  assign out_d_valid[OUT_MMIO]      = auto_out_2_d_valid;
  assign out_d_bits[OUT_BEU]        = '{opcode: auto_out_0_d_bits_opcode, param: auto_out_0_d_bits_param,
                                        size: auto_out_0_d_bits_size, source: auto_out_0_d_bits_source,
                                        sink: auto_out_0_d_bits_sink, denied: auto_out_0_d_bits_denied,
                                        data: auto_out_0_d_bits_data, corrupt: auto_out_0_d_bits_corrupt};
  assign out_d_bits[OUT_CACHECTRL]  = '{opcode: auto_out_1_d_bits_opcode, param: auto_out_1_d_bits_param,
                                        size: auto_out_1_d_bits_size, source: auto_out_1_d_bits_source,
                                        sink: auto_out_1_d_bits_sink, denied: auto_out_1_d_bits_denied,
                                        data: auto_out_1_d_bits_data, corrupt: auto_out_1_d_bits_corrupt};
  assign out_d_bits[OUT_MMIO]       = '{opcode: auto_out_2_d_bits_opcode, param: auto_out_2_d_bits_param,
                                        size: auto_out_2_d_bits_size, source: auto_out_2_d_bits_source,
                                        sink: auto_out_2_d_bits_sink, denied: auto_out_2_d_bits_denied,
                                        data: auto_out_2_d_bits_data, corrupt: auto_out_2_d_bits_corrupt};
  assign auto_out_0_d_ready = out_d_ready[OUT_BEU];
  assign auto_out_1_d_ready = out_d_ready[OUT_CACHECTRL];
  assign auto_out_2_d_ready = out_d_ready[OUT_MMIO];

  // request_d[o][i]：从口 o 的应答回主口 i
  logic [NUM_IN-1:0] request_d [NUM_OUT];
  always_comb begin
    for (int o = 0; o < NUM_OUT; o++) begin
      request_d[o][IN_IMMIO] = (out_d_bits[o].source == IMMIO_SOURCE_BASE);   // 只认 16（见包头）
      request_d[o][IN_DMMIO] = ~out_d_bits[o].source[SOURCE_W-1];            // 0..15
    end
  end

  // ===========================================================================
  //  四、主口 D：每个主口一个 3 路 round-robin 仲裁器
  // ===========================================================================
  logic  [NUM_IN-1:0] in_d_ready, in_d_valid;
  tl_d_t              in_d_bits [NUM_IN];
  assign in_d_ready[IN_IMMIO] = auto_in_0_d_ready;
  assign in_d_ready[IN_DMMIO] = auto_in_1_d_ready;

  logic [NUM_OUT-1:0] arb_d_valid [NUM_IN];
  logic [NUM_OUT-1:0] arb_d_ready [NUM_IN];
  for (genvar i = 0; i < NUM_IN; i++) begin : g_in_d
    logic [NUM_OUT-1:0][$bits(tl_d_t)-1:0] src_bits_flat;
    for (genvar o = 0; o < NUM_OUT; o++) begin : g_src
      assign arb_d_valid[i][o] = out_d_valid[o] & request_d[o][i];
      assign src_bits_flat[o]  = out_d_bits[o];
    end
    xs_TLArbiterRoundRobin #(.N(NUM_OUT), .W($bits(tl_d_t))) u_arb (
      .clock     (clock),
      .reset     (reset),
      .src_valid (arb_d_valid[i]),
      .src_ready (arb_d_ready[i]),
      .src_bits  (src_bits_flat),
      .src_beats1('0),
      .sink_ready(in_d_ready[i]),
      .sink_valid(in_d_valid[i]),
      .sink_bits (in_d_bits[i])
    );
  end

  always_comb begin
    for (int o = 0; o < NUM_OUT; o++) begin
      out_d_ready[o] = 1'b0;
      for (int i = 0; i < NUM_IN; i++)
        out_d_ready[o] |= request_d[o][i] & arb_d_ready[i][o];
    end
  end

  // 拆到主口端口：in0 的 D 没有 source 口；in1 的 source 取低 4 位
  assign auto_in_0_d_valid        = in_d_valid[IN_IMMIO];
  assign auto_in_0_d_bits_opcode  = in_d_bits[IN_IMMIO].opcode;
  assign auto_in_0_d_bits_param   = in_d_bits[IN_IMMIO].param;
  assign auto_in_0_d_bits_size    = in_d_bits[IN_IMMIO].size;
  assign auto_in_0_d_bits_sink    = in_d_bits[IN_IMMIO].sink;
  assign auto_in_0_d_bits_denied  = in_d_bits[IN_IMMIO].denied;
  assign auto_in_0_d_bits_data    = in_d_bits[IN_IMMIO].data;
  assign auto_in_0_d_bits_corrupt = in_d_bits[IN_IMMIO].corrupt;

  assign auto_in_1_d_valid        = in_d_valid[IN_DMMIO];
  assign auto_in_1_d_bits_opcode  = in_d_bits[IN_DMMIO].opcode;
  assign auto_in_1_d_bits_param   = in_d_bits[IN_DMMIO].param;
  assign auto_in_1_d_bits_size    = in_d_bits[IN_DMMIO].size;
  assign auto_in_1_d_bits_source  = in_d_bits[IN_DMMIO].source[3:0];
  assign auto_in_1_d_bits_sink    = in_d_bits[IN_DMMIO].sink;
  assign auto_in_1_d_bits_denied  = in_d_bits[IN_DMMIO].denied;
  assign auto_in_1_d_bits_data    = in_d_bits[IN_DMMIO].data;
  assign auto_in_1_d_bits_corrupt = in_d_bits[IN_DMMIO].corrupt;

endmodule

// =============================================================================
//  TLXbar_6 —— golden 同名 wrapper（端口逐名逐宽相同，直接例化核）
// =============================================================================
module TLXbar_6 (
  input  logic        clock,
  input  logic        reset,
  output logic        auto_in_1_a_ready,
  input  logic        auto_in_1_a_valid,
  input  logic [3:0]  auto_in_1_a_bits_opcode,
  input  logic [2:0]  auto_in_1_a_bits_param,
  input  logic [1:0]  auto_in_1_a_bits_size,
  input  logic [3:0]  auto_in_1_a_bits_source,
  input  logic [47:0] auto_in_1_a_bits_address,
  input  logic        auto_in_1_a_bits_user_memBackType_MM,
  input  logic        auto_in_1_a_bits_user_memPageType_NC,
  input  logic [7:0]  auto_in_1_a_bits_mask,
  input  logic [63:0] auto_in_1_a_bits_data,
  input  logic        auto_in_1_a_bits_corrupt,
  input  logic        auto_in_1_d_ready,
  output logic        auto_in_1_d_valid,
  output logic [3:0]  auto_in_1_d_bits_opcode,
  output logic [1:0]  auto_in_1_d_bits_param,
  output logic [1:0]  auto_in_1_d_bits_size,
  output logic [3:0]  auto_in_1_d_bits_source,
  output logic        auto_in_1_d_bits_sink,
  output logic        auto_in_1_d_bits_denied,
  output logic [63:0] auto_in_1_d_bits_data,
  output logic        auto_in_1_d_bits_corrupt,
  output logic        auto_in_0_a_ready,
  input  logic        auto_in_0_a_valid,
  input  logic [3:0]  auto_in_0_a_bits_opcode,
  input  logic [2:0]  auto_in_0_a_bits_param,
  input  logic [1:0]  auto_in_0_a_bits_size,
  input  logic        auto_in_0_a_bits_source,
  input  logic [47:0] auto_in_0_a_bits_address,
  input  logic        auto_in_0_a_bits_user_memPageType_NC,
  input  logic        auto_in_0_a_bits_user_memBackType_MM,
  input  logic [7:0]  auto_in_0_a_bits_mask,
  input  logic [63:0] auto_in_0_a_bits_data,
  input  logic        auto_in_0_a_bits_corrupt,
  input  logic        auto_in_0_d_ready,
  output logic        auto_in_0_d_valid,
  output logic [3:0]  auto_in_0_d_bits_opcode,
  output logic [1:0]  auto_in_0_d_bits_param,
  output logic [1:0]  auto_in_0_d_bits_size,
  output logic        auto_in_0_d_bits_sink,
  output logic        auto_in_0_d_bits_denied,
  output logic [63:0] auto_in_0_d_bits_data,
  output logic        auto_in_0_d_bits_corrupt,
  input  logic        auto_out_2_a_ready,
  output logic        auto_out_2_a_valid,
  output logic [3:0]  auto_out_2_a_bits_opcode,
  output logic [2:0]  auto_out_2_a_bits_param,
  output logic [1:0]  auto_out_2_a_bits_size,
  output logic [4:0]  auto_out_2_a_bits_source,
  output logic [47:0] auto_out_2_a_bits_address,
  output logic        auto_out_2_a_bits_user_memBackType_MM,
  output logic        auto_out_2_a_bits_user_memPageType_NC,
  output logic [7:0]  auto_out_2_a_bits_mask,
  output logic [63:0] auto_out_2_a_bits_data,
  output logic        auto_out_2_a_bits_corrupt,
  output logic        auto_out_2_d_ready,
  input  logic        auto_out_2_d_valid,
  input  logic [3:0]  auto_out_2_d_bits_opcode,
  input  logic [1:0]  auto_out_2_d_bits_param,
  input  logic [1:0]  auto_out_2_d_bits_size,
  input  logic [4:0]  auto_out_2_d_bits_source,
  input  logic        auto_out_2_d_bits_sink,
  input  logic        auto_out_2_d_bits_denied,
  input  logic [63:0] auto_out_2_d_bits_data,
  input  logic        auto_out_2_d_bits_corrupt,
  input  logic        auto_out_1_a_ready,
  output logic        auto_out_1_a_valid,
  output logic [3:0]  auto_out_1_a_bits_opcode,
  output logic [2:0]  auto_out_1_a_bits_param,
  output logic [1:0]  auto_out_1_a_bits_size,
  output logic [4:0]  auto_out_1_a_bits_source,
  output logic [29:0] auto_out_1_a_bits_address,
  output logic [7:0]  auto_out_1_a_bits_mask,
  output logic [63:0] auto_out_1_a_bits_data,
  output logic        auto_out_1_a_bits_corrupt,
  output logic        auto_out_1_d_ready,
  input  logic        auto_out_1_d_valid,
  input  logic [3:0]  auto_out_1_d_bits_opcode,
  input  logic [1:0]  auto_out_1_d_bits_param,
  input  logic [1:0]  auto_out_1_d_bits_size,
  input  logic [4:0]  auto_out_1_d_bits_source,
  input  logic        auto_out_1_d_bits_sink,
  input  logic        auto_out_1_d_bits_denied,
  input  logic [63:0] auto_out_1_d_bits_data,
  input  logic        auto_out_1_d_bits_corrupt,
  input  logic        auto_out_0_a_ready,
  output logic        auto_out_0_a_valid,
  output logic [3:0]  auto_out_0_a_bits_opcode,
  output logic [2:0]  auto_out_0_a_bits_param,
  output logic [1:0]  auto_out_0_a_bits_size,
  output logic [4:0]  auto_out_0_a_bits_source,
  output logic [29:0] auto_out_0_a_bits_address,
  output logic [7:0]  auto_out_0_a_bits_mask,
  output logic [63:0] auto_out_0_a_bits_data,
  output logic        auto_out_0_a_bits_corrupt,
  output logic        auto_out_0_d_ready,
  input  logic        auto_out_0_d_valid,
  input  logic [3:0]  auto_out_0_d_bits_opcode,
  input  logic [1:0]  auto_out_0_d_bits_param,
  input  logic [1:0]  auto_out_0_d_bits_size,
  input  logic [4:0]  auto_out_0_d_bits_source,
  input  logic        auto_out_0_d_bits_sink,
  input  logic        auto_out_0_d_bits_denied,
  input  logic [63:0] auto_out_0_d_bits_data,
  input  logic        auto_out_0_d_bits_corrupt
);

  xs_TLXbar_6_core u_core (.*);

endmodule
