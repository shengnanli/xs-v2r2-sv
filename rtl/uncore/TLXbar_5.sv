// =============================================================================
//  tlxbar5_pkg —— TLXbar_5（L2Top 的 l1_xbar：3 主 × 4 从 TileLink-C 交叉开关）的常量与类型
// -----------------------------------------------------------------------------
//  对应 rocket-chip 的 TLXbar（tilelink/Xbar.scala），在 src/main/scala/xiangshan/L2Top.scala
//  里叫 l1_xbar：三个 L1 主设备的 TileLink 流量汇到这里，按地址分到 L2 的 4 个 bank
//  （slice），再经 xbar_l2_buffer 进 L2。
//    in0 = DCache（TL-C 全五通道，source 6 位；user 带 alias/vaddr/reqSource/needHint，echo 带 isKeyword）
//    in1 = ICache（TL-UH，A/D 两通道，source 4 位；user 带 alias/reqSource/needHint）
//    in2 = PTW   （TL-UH，A/D 两通道，source 4 位；user 只带 reqSource）
//    out0..out3 = L2 的 4 个 bank，按地址位 [7:6] 交织（64 B 粒度）：bank = address[7:6]
//  source 空间在交叉开关里错开成 7 位：in0 = 0..63（前缀 0）、in1 = 80..95（前缀 3'h5）、
//  in2 = 64..79（前缀 3'h4）；D 应答按前缀回流。sink 空间 10 位：out_k 的 8 位 sink 加前缀
//  2'(3-k)，E 确认按 sink[9:8] 回到对应 bank。
//  数据 256 位、块 512 位：A/D 带数据且 size ≥ 6（64 B）的消息两拍，仲裁器要锁定两拍；
//  B（探测）本配置不带数据，单拍；C/E 只有 in0 一个来源，不需要仲裁。
// =============================================================================
package tlxbar5_pkg;

  localparam int NUM_IN  = 3;
  localparam int NUM_OUT = 4;

  typedef enum logic [1:0] {
    IN_DCACHE = 2'd0,
    IN_ICACHE = 2'd1,
    IN_PTW    = 2'd2
  } in_port_e;

  localparam int SOURCE_W = 7;
  localparam int SINK_W   = 10;
  localparam int ADDR_W   = 48;
  localparam int DATA_W   = 256;
  localparam int MASK_W   = 32;

  // 主口 source 前缀（TLXbar 把各主口的 source 空间错开）
  localparam logic [SOURCE_W-1:0] SOURCE_BASE_DCACHE = 7'h00;
  localparam logic [SOURCE_W-1:0] SOURCE_BASE_ICACHE = 7'h50;
  localparam logic [SOURCE_W-1:0] SOURCE_BASE_PTW    = 7'h40;

  // 从口 sink 前缀：out_k 的 sink 空间从 (3-k)<<8 起
  function automatic logic [SINK_W-1:0] sink_base(input int unsigned k);
    return SINK_W'((NUM_OUT - 1 - k) << 8);
  endfunction

  // A 通道载荷（主口字段的并集；缺的字段由薄文件填 0）
  typedef struct packed {
    logic [3:0]        opcode;
    logic [2:0]        param;
    logic [2:0]        size;
    logic [SOURCE_W-1:0] source;
    logic [ADDR_W-1:0] address;
    logic [4:0]        user_reqSource;
    logic [1:0]        user_alias;
    logic [43:0]       user_vaddr;
    logic              user_needHint;
    logic              echo_isKeyword;
    logic [MASK_W-1:0] mask;
    logic [DATA_W-1:0] data;
    logic              corrupt;
  } tl_a_t;

  typedef struct packed {
    logic [2:0]        opcode;
    logic [1:0]        param;
    logic [2:0]        size;
    logic [SOURCE_W-1:0] source;
    logic [ADDR_W-1:0] address;
    logic [MASK_W-1:0] mask;
    logic [DATA_W-1:0] data;
    logic              corrupt;
  } tl_b_t;

  typedef struct packed {
    logic [2:0]        opcode;
    logic [2:0]        param;
    logic [2:0]        size;
    logic [SOURCE_W-1:0] source;
    logic [ADDR_W-1:0] address;
    logic [4:0]        user_reqSource;
    logic [1:0]        user_alias;
    logic [43:0]       user_vaddr;
    logic              user_needHint;
    logic              echo_isKeyword;
    logic [DATA_W-1:0] data;
    logic              corrupt;
  } tl_c_t;

  typedef struct packed {
    logic [3:0]        opcode;
    logic [1:0]        param;
    logic [2:0]        size;
    logic [SOURCE_W-1:0] source;
    logic [SINK_W-1:0] sink;
    logic              denied;
    logic              echo_isKeyword;
    logic [DATA_W-1:0] data;
    logic              corrupt;
  } tl_d_t;

  typedef struct packed {
    logic [SINK_W-1:0] sink;
  } tl_e_t;

  // 一条消息有没有第二拍：带数据且 size >= 6（64 B = 2 × 256 位）。
  // A 的 opcode[2] == 0 是带数据的操作（Put* / Arithmetic / Logical）；D 的 opcode[0] == 1
  // 是带数据的应答（AccessAckData / GrantData）。(13'h3F << size)[5] 为 0 当且仅当 size >= 6。
  function automatic logic a_has_two_beats(input logic [3:0] opcode, input logic [2:0] size);
    return ~opcode[2] & (size >= 3'd6);
  endfunction
  function automatic logic d_has_two_beats(input logic [3:0] opcode, input logic [2:0] size);
    return opcode[0] & (size >= 3'd6);
  endfunction

endpackage

// =============================================================================
//  xs_TLXbar_5_core —— 可读核
// -----------------------------------------------------------------------------
//  端口按通道打包成 tlxbar5_pkg 的结构体数组（薄文件负责与 golden 平铺端口的拆拼、
//  缺字段填 0、source/sink 前缀）。
//  · A（主→从）：bank = address[7:6]；每个从口一个 3 路 round-robin 仲裁器
//    （xs_TLArbiterRoundRobin），两拍消息锁定两拍。
//  · B（从→主）：只回 in0（source[6] == 0）；一个 4 路 round-robin 仲裁器，单拍。
//  · C（主→从）：只有 in0 发；bank = address[7:6]，直连无仲裁。
//  · D（从→主）：按 source 前缀回 in0/in1/in2；每个主口一个 4 路 round-robin 仲裁器，
//    两拍消息锁定两拍。
//  · E（主→从）：只有 in0 发；bank 由 sink[9:8] 还原，直连无仲裁。
// =============================================================================
module xs_TLXbar_5_core
  import tlxbar5_pkg::*;
(
  input  logic                clock,
  input  logic                reset,
  // ---- 主口 A / D（三个主口都有）----
  input  logic  [NUM_IN-1:0]  in_a_valid,
  output logic  [NUM_IN-1:0]  in_a_ready,
  input  tl_a_t               in_a_bits  [NUM_IN],
  input  logic  [NUM_IN-1:0]  in_d_ready,
  output logic  [NUM_IN-1:0]  in_d_valid,
  output tl_d_t               in_d_bits  [NUM_IN],
  // ---- 主口 B / C / E（只有 in0 = DCache）----
  input  logic                in0_b_ready,
  output logic                in0_b_valid,
  output tl_b_t               in0_b_bits,
  input  logic                in0_c_valid,
  output logic                in0_c_ready,
  input  tl_c_t               in0_c_bits,
  input  logic                in0_e_valid,
  output logic                in0_e_ready,
  input  tl_e_t               in0_e_bits,
  // ---- 从口 A / B / C / D / E（四个 bank）----
  input  logic  [NUM_OUT-1:0] out_a_ready,
  output logic  [NUM_OUT-1:0] out_a_valid,
  output tl_a_t               out_a_bits [NUM_OUT],
  output logic  [NUM_OUT-1:0] out_b_ready,
  input  logic  [NUM_OUT-1:0] out_b_valid,
  input  tl_b_t               out_b_bits [NUM_OUT],
  input  logic  [NUM_OUT-1:0] out_c_ready,
  output logic  [NUM_OUT-1:0] out_c_valid,
  output tl_c_t               out_c_bits [NUM_OUT],
  output logic  [NUM_OUT-1:0] out_d_ready,
  input  logic  [NUM_OUT-1:0] out_d_valid,
  input  tl_d_t               out_d_bits [NUM_OUT],
  input  logic  [NUM_OUT-1:0] out_e_ready,
  output logic  [NUM_OUT-1:0] out_e_valid,
  output tl_e_t               out_e_bits [NUM_OUT]
);

  // ===========================================================================
  //  一、路由判据
  // ===========================================================================
  // bank 选择：地址位 [7:6]
  function automatic logic [NUM_OUT-1:0] bank_of(input logic [ADDR_W-1:0] address);
    logic [NUM_OUT-1:0] r;
    for (int o = 0; o < NUM_OUT; o++) r[o] = (address[7:6] == 2'(o));
    return r;
  endfunction

  // 应答回哪个主口：按 source 前缀
  function automatic logic [NUM_IN-1:0] master_of(input logic [SOURCE_W-1:0] source);
    logic [NUM_IN-1:0] r;
    r[IN_DCACHE] = ~source[6];                      // 0..63
    r[IN_ICACHE] = (source[6:4] == 3'h5);           // 80..95
    r[IN_PTW]    = (source[6:4] == 3'h4);           // 64..79
    return r;
  endfunction

  // request_a[k][o]：主口 k 的 A 要去 bank o；request_d[o][i]：bank o 的 D 要回主口 i
  logic [NUM_OUT-1:0] request_a [NUM_IN];
  logic [NUM_IN-1:0]  request_d [NUM_OUT];
  logic [NUM_OUT-1:0] request_c, request_e;
  logic [NUM_OUT-1:0] b_to_in0;
  always_comb begin
    for (int k = 0; k < NUM_IN; k++)  request_a[k] = bank_of(in_a_bits[k].address);
    for (int o = 0; o < NUM_OUT; o++) request_d[o] = master_of(out_d_bits[o].source);
    for (int o = 0; o < NUM_OUT; o++) b_to_in0[o]  = ~out_b_bits[o].source[6];
    request_c = bank_of(in0_c_bits.address);
    for (int o = 0; o < NUM_OUT; o++) request_e[o] = (in0_e_bits.sink[9:8] == 2'(NUM_OUT - 1 - o));
  end

  // ===========================================================================
  //  二、A：每个 bank 一个 3 路 round-robin 仲裁器（两拍消息锁定）
  // ===========================================================================
  logic [NUM_IN-1:0] arb_a_valid  [NUM_OUT];
  logic [NUM_IN-1:0] arb_a_ready  [NUM_OUT];
  logic [NUM_IN-1:0] a_two_beats;
  always_comb
    for (int k = 0; k < NUM_IN; k++)
      a_two_beats[k] = a_has_two_beats(in_a_bits[k].opcode, in_a_bits[k].size);

  for (genvar o = 0; o < NUM_OUT; o++) begin : g_out_a
    logic [NUM_IN-1:0][$bits(tl_a_t)-1:0] src_bits_flat;
    for (genvar k = 0; k < NUM_IN; k++) begin : g_src
      assign arb_a_valid[o][k] = in_a_valid[k] & request_a[k][o];
      assign src_bits_flat[k]  = in_a_bits[k];
    end
    xs_TLArbiterRoundRobin #(.N(NUM_IN), .W($bits(tl_a_t))) u_arb (
      .clock     (clock),
      .reset     (reset),
      .src_valid (arb_a_valid[o]),
      .src_ready (arb_a_ready[o]),
      .src_bits  (src_bits_flat),
      .src_beats1(a_two_beats),
      .sink_ready(out_a_ready[o]),
      .sink_valid(out_a_valid[o]),
      .sink_bits (out_a_bits[o])
    );
  end

  always_comb begin
    for (int k = 0; k < NUM_IN; k++) begin
      in_a_ready[k] = 1'b0;
      for (int o = 0; o < NUM_OUT; o++)
        in_a_ready[k] |= request_a[k][o] & arb_a_ready[o][k];
    end
  end

  // ===========================================================================
  //  三、B：四个 bank 的探测回 in0，一个 4 路 round-robin 仲裁器（单拍）
  // ===========================================================================
  logic [NUM_OUT-1:0] arb_b_valid, arb_b_ready;
  logic [NUM_OUT-1:0][$bits(tl_b_t)-1:0] b_bits_flat;
  for (genvar o = 0; o < NUM_OUT; o++) begin : g_b_src
    assign arb_b_valid[o] = out_b_valid[o] & b_to_in0[o];
    assign b_bits_flat[o] = out_b_bits[o];
    assign out_b_ready[o] = b_to_in0[o] & arb_b_ready[o];
  end
  xs_TLArbiterRoundRobin #(.N(NUM_OUT), .W($bits(tl_b_t))) u_arb_b (
    .clock     (clock),
    .reset     (reset),
    .src_valid (arb_b_valid),
    .src_ready (arb_b_ready),
    .src_bits  (b_bits_flat),
    .src_beats1('0),
    .sink_ready(in0_b_ready),
    .sink_valid(in0_b_valid),
    .sink_bits (in0_b_bits)
  );

  // ===========================================================================
  //  四、C：只有 in0 发，按 bank 直连
  // ===========================================================================
  always_comb begin
    in0_c_ready = 1'b0;
    for (int o = 0; o < NUM_OUT; o++) begin
      out_c_valid[o] = in0_c_valid & request_c[o];
      out_c_bits[o]  = in0_c_bits;
      in0_c_ready   |= request_c[o] & out_c_ready[o];
    end
  end

  // ===========================================================================
  //  五、D：每个主口一个 4 路 round-robin 仲裁器（两拍消息锁定）
  // ===========================================================================
  logic [NUM_OUT-1:0] arb_d_valid [NUM_IN];
  logic [NUM_OUT-1:0] arb_d_ready [NUM_IN];
  logic [NUM_OUT-1:0] d_two_beats;
  always_comb
    for (int o = 0; o < NUM_OUT; o++)
      d_two_beats[o] = d_has_two_beats(out_d_bits[o].opcode, out_d_bits[o].size);

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
      .src_beats1(d_two_beats),
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

  // ===========================================================================
  //  六、E：只有 in0 发，按 sink 前缀直连
  // ===========================================================================
  always_comb begin
    in0_e_ready = 1'b0;
    for (int o = 0; o < NUM_OUT; o++) begin
      out_e_valid[o] = in0_e_valid & request_e[o];
      out_e_bits[o]  = in0_e_bits;
      in0_e_ready   |= request_e[o] & out_e_ready[o];
    end
  end

endmodule

// =============================================================================
//  TLXbar_5 —— golden 同名 wrapper：平铺端口 <-> 结构体数组的拆拼
// -----------------------------------------------------------------------------
//  规则（全部由 scripts/gen_tlxbar5_wrapper.py 从 golden 端口表机械生成）：
//    · 主口缺的字段填 0（in1 没有 vaddr/isKeyword，in2 还没有 alias/needHint）；
//    · 主口 source 零扩展到 7 位再按 OR 加前缀；从口 D/B 的 source 回到主口时截到主口位宽；
//    · 从口 sink 零扩展到 10 位再加前缀 (3-k)<<8；主口 E 的 sink 送到从口时截到 8 位；
//    · in1/in2 的 D 没有 echo_isKeyword 口，丢弃。
// =============================================================================
// BEGIN GENERATED(tlxbar5_wrapper)
module TLXbar_5
  import tlxbar5_pkg::*;
(
  input  logic clock,
  input  logic reset,
  output logic auto_in_2_a_ready,
  input  logic auto_in_2_a_valid,
  input  logic [3:0] auto_in_2_a_bits_opcode,
  input  logic [2:0] auto_in_2_a_bits_param,
  input  logic [2:0] auto_in_2_a_bits_size,
  input  logic [3:0] auto_in_2_a_bits_source,
  input  logic [47:0] auto_in_2_a_bits_address,
  input  logic [4:0] auto_in_2_a_bits_user_reqSource,
  input  logic [31:0] auto_in_2_a_bits_mask,
  input  logic [255:0] auto_in_2_a_bits_data,
  input  logic auto_in_2_a_bits_corrupt,
  input  logic auto_in_2_d_ready,
  output logic auto_in_2_d_valid,
  output logic [3:0] auto_in_2_d_bits_opcode,
  output logic [1:0] auto_in_2_d_bits_param,
  output logic [2:0] auto_in_2_d_bits_size,
  output logic [3:0] auto_in_2_d_bits_source,
  output logic [9:0] auto_in_2_d_bits_sink,
  output logic auto_in_2_d_bits_denied,
  output logic [255:0] auto_in_2_d_bits_data,
  output logic auto_in_2_d_bits_corrupt,
  output logic auto_in_1_a_ready,
  input  logic auto_in_1_a_valid,
  input  logic [3:0] auto_in_1_a_bits_opcode,
  input  logic [2:0] auto_in_1_a_bits_param,
  input  logic [2:0] auto_in_1_a_bits_size,
  input  logic [3:0] auto_in_1_a_bits_source,
  input  logic [47:0] auto_in_1_a_bits_address,
  input  logic [1:0] auto_in_1_a_bits_user_alias,
  input  logic [4:0] auto_in_1_a_bits_user_reqSource,
  input  logic auto_in_1_a_bits_user_needHint,
  input  logic [31:0] auto_in_1_a_bits_mask,
  input  logic [255:0] auto_in_1_a_bits_data,
  input  logic auto_in_1_a_bits_corrupt,
  input  logic auto_in_1_d_ready,
  output logic auto_in_1_d_valid,
  output logic [3:0] auto_in_1_d_bits_opcode,
  output logic [1:0] auto_in_1_d_bits_param,
  output logic [2:0] auto_in_1_d_bits_size,
  output logic [3:0] auto_in_1_d_bits_source,
  output logic [9:0] auto_in_1_d_bits_sink,
  output logic auto_in_1_d_bits_denied,
  output logic [255:0] auto_in_1_d_bits_data,
  output logic auto_in_1_d_bits_corrupt,
  output logic auto_in_0_a_ready,
  input  logic auto_in_0_a_valid,
  input  logic [3:0] auto_in_0_a_bits_opcode,
  input  logic [2:0] auto_in_0_a_bits_param,
  input  logic [2:0] auto_in_0_a_bits_size,
  input  logic [5:0] auto_in_0_a_bits_source,
  input  logic [47:0] auto_in_0_a_bits_address,
  input  logic [1:0] auto_in_0_a_bits_user_alias,
  input  logic [43:0] auto_in_0_a_bits_user_vaddr,
  input  logic [4:0] auto_in_0_a_bits_user_reqSource,
  input  logic auto_in_0_a_bits_user_needHint,
  input  logic auto_in_0_a_bits_echo_isKeyword,
  input  logic [31:0] auto_in_0_a_bits_mask,
  input  logic [255:0] auto_in_0_a_bits_data,
  input  logic auto_in_0_a_bits_corrupt,
  input  logic auto_in_0_b_ready,
  output logic auto_in_0_b_valid,
  output logic [2:0] auto_in_0_b_bits_opcode,
  output logic [1:0] auto_in_0_b_bits_param,
  output logic [2:0] auto_in_0_b_bits_size,
  output logic [5:0] auto_in_0_b_bits_source,
  output logic [47:0] auto_in_0_b_bits_address,
  output logic [31:0] auto_in_0_b_bits_mask,
  output logic [255:0] auto_in_0_b_bits_data,
  output logic auto_in_0_b_bits_corrupt,
  output logic auto_in_0_c_ready,
  input  logic auto_in_0_c_valid,
  input  logic [2:0] auto_in_0_c_bits_opcode,
  input  logic [2:0] auto_in_0_c_bits_param,
  input  logic [2:0] auto_in_0_c_bits_size,
  input  logic [5:0] auto_in_0_c_bits_source,
  input  logic [47:0] auto_in_0_c_bits_address,
  input  logic [1:0] auto_in_0_c_bits_user_alias,
  input  logic [43:0] auto_in_0_c_bits_user_vaddr,
  input  logic [4:0] auto_in_0_c_bits_user_reqSource,
  input  logic auto_in_0_c_bits_user_needHint,
  input  logic auto_in_0_c_bits_echo_isKeyword,
  input  logic [255:0] auto_in_0_c_bits_data,
  input  logic auto_in_0_c_bits_corrupt,
  input  logic auto_in_0_d_ready,
  output logic auto_in_0_d_valid,
  output logic [3:0] auto_in_0_d_bits_opcode,
  output logic [1:0] auto_in_0_d_bits_param,
  output logic [2:0] auto_in_0_d_bits_size,
  output logic [5:0] auto_in_0_d_bits_source,
  output logic [9:0] auto_in_0_d_bits_sink,
  output logic auto_in_0_d_bits_denied,
  output logic auto_in_0_d_bits_echo_isKeyword,
  output logic [255:0] auto_in_0_d_bits_data,
  output logic auto_in_0_d_bits_corrupt,
  output logic auto_in_0_e_ready,
  input  logic auto_in_0_e_valid,
  input  logic [9:0] auto_in_0_e_bits_sink,
  input  logic auto_out_3_a_ready,
  output logic auto_out_3_a_valid,
  output logic [3:0] auto_out_3_a_bits_opcode,
  output logic [2:0] auto_out_3_a_bits_param,
  output logic [2:0] auto_out_3_a_bits_size,
  output logic [6:0] auto_out_3_a_bits_source,
  output logic [47:0] auto_out_3_a_bits_address,
  output logic [4:0] auto_out_3_a_bits_user_reqSource,
  output logic [1:0] auto_out_3_a_bits_user_alias,
  output logic [43:0] auto_out_3_a_bits_user_vaddr,
  output logic auto_out_3_a_bits_user_needHint,
  output logic auto_out_3_a_bits_echo_isKeyword,
  output logic [31:0] auto_out_3_a_bits_mask,
  output logic [255:0] auto_out_3_a_bits_data,
  output logic auto_out_3_a_bits_corrupt,
  output logic auto_out_3_b_ready,
  input  logic auto_out_3_b_valid,
  input  logic [2:0] auto_out_3_b_bits_opcode,
  input  logic [1:0] auto_out_3_b_bits_param,
  input  logic [2:0] auto_out_3_b_bits_size,
  input  logic [6:0] auto_out_3_b_bits_source,
  input  logic [47:0] auto_out_3_b_bits_address,
  input  logic [31:0] auto_out_3_b_bits_mask,
  input  logic [255:0] auto_out_3_b_bits_data,
  input  logic auto_out_3_b_bits_corrupt,
  input  logic auto_out_3_c_ready,
  output logic auto_out_3_c_valid,
  output logic [2:0] auto_out_3_c_bits_opcode,
  output logic [2:0] auto_out_3_c_bits_param,
  output logic [2:0] auto_out_3_c_bits_size,
  output logic [6:0] auto_out_3_c_bits_source,
  output logic [47:0] auto_out_3_c_bits_address,
  output logic [4:0] auto_out_3_c_bits_user_reqSource,
  output logic [1:0] auto_out_3_c_bits_user_alias,
  output logic [43:0] auto_out_3_c_bits_user_vaddr,
  output logic auto_out_3_c_bits_user_needHint,
  output logic auto_out_3_c_bits_echo_isKeyword,
  output logic [255:0] auto_out_3_c_bits_data,
  output logic auto_out_3_c_bits_corrupt,
  output logic auto_out_3_d_ready,
  input  logic auto_out_3_d_valid,
  input  logic [3:0] auto_out_3_d_bits_opcode,
  input  logic [1:0] auto_out_3_d_bits_param,
  input  logic [2:0] auto_out_3_d_bits_size,
  input  logic [6:0] auto_out_3_d_bits_source,
  input  logic [7:0] auto_out_3_d_bits_sink,
  input  logic auto_out_3_d_bits_denied,
  input  logic auto_out_3_d_bits_echo_isKeyword,
  input  logic [255:0] auto_out_3_d_bits_data,
  input  logic auto_out_3_d_bits_corrupt,
  input  logic auto_out_3_e_ready,
  output logic auto_out_3_e_valid,
  output logic [7:0] auto_out_3_e_bits_sink,
  input  logic auto_out_2_a_ready,
  output logic auto_out_2_a_valid,
  output logic [3:0] auto_out_2_a_bits_opcode,
  output logic [2:0] auto_out_2_a_bits_param,
  output logic [2:0] auto_out_2_a_bits_size,
  output logic [6:0] auto_out_2_a_bits_source,
  output logic [47:0] auto_out_2_a_bits_address,
  output logic [4:0] auto_out_2_a_bits_user_reqSource,
  output logic [1:0] auto_out_2_a_bits_user_alias,
  output logic [43:0] auto_out_2_a_bits_user_vaddr,
  output logic auto_out_2_a_bits_user_needHint,
  output logic auto_out_2_a_bits_echo_isKeyword,
  output logic [31:0] auto_out_2_a_bits_mask,
  output logic [255:0] auto_out_2_a_bits_data,
  output logic auto_out_2_a_bits_corrupt,
  output logic auto_out_2_b_ready,
  input  logic auto_out_2_b_valid,
  input  logic [2:0] auto_out_2_b_bits_opcode,
  input  logic [1:0] auto_out_2_b_bits_param,
  input  logic [2:0] auto_out_2_b_bits_size,
  input  logic [6:0] auto_out_2_b_bits_source,
  input  logic [47:0] auto_out_2_b_bits_address,
  input  logic [31:0] auto_out_2_b_bits_mask,
  input  logic [255:0] auto_out_2_b_bits_data,
  input  logic auto_out_2_b_bits_corrupt,
  input  logic auto_out_2_c_ready,
  output logic auto_out_2_c_valid,
  output logic [2:0] auto_out_2_c_bits_opcode,
  output logic [2:0] auto_out_2_c_bits_param,
  output logic [2:0] auto_out_2_c_bits_size,
  output logic [6:0] auto_out_2_c_bits_source,
  output logic [47:0] auto_out_2_c_bits_address,
  output logic [4:0] auto_out_2_c_bits_user_reqSource,
  output logic [1:0] auto_out_2_c_bits_user_alias,
  output logic [43:0] auto_out_2_c_bits_user_vaddr,
  output logic auto_out_2_c_bits_user_needHint,
  output logic auto_out_2_c_bits_echo_isKeyword,
  output logic [255:0] auto_out_2_c_bits_data,
  output logic auto_out_2_c_bits_corrupt,
  output logic auto_out_2_d_ready,
  input  logic auto_out_2_d_valid,
  input  logic [3:0] auto_out_2_d_bits_opcode,
  input  logic [1:0] auto_out_2_d_bits_param,
  input  logic [2:0] auto_out_2_d_bits_size,
  input  logic [6:0] auto_out_2_d_bits_source,
  input  logic [7:0] auto_out_2_d_bits_sink,
  input  logic auto_out_2_d_bits_denied,
  input  logic auto_out_2_d_bits_echo_isKeyword,
  input  logic [255:0] auto_out_2_d_bits_data,
  input  logic auto_out_2_d_bits_corrupt,
  input  logic auto_out_2_e_ready,
  output logic auto_out_2_e_valid,
  output logic [7:0] auto_out_2_e_bits_sink,
  input  logic auto_out_1_a_ready,
  output logic auto_out_1_a_valid,
  output logic [3:0] auto_out_1_a_bits_opcode,
  output logic [2:0] auto_out_1_a_bits_param,
  output logic [2:0] auto_out_1_a_bits_size,
  output logic [6:0] auto_out_1_a_bits_source,
  output logic [47:0] auto_out_1_a_bits_address,
  output logic [4:0] auto_out_1_a_bits_user_reqSource,
  output logic [1:0] auto_out_1_a_bits_user_alias,
  output logic [43:0] auto_out_1_a_bits_user_vaddr,
  output logic auto_out_1_a_bits_user_needHint,
  output logic auto_out_1_a_bits_echo_isKeyword,
  output logic [31:0] auto_out_1_a_bits_mask,
  output logic [255:0] auto_out_1_a_bits_data,
  output logic auto_out_1_a_bits_corrupt,
  output logic auto_out_1_b_ready,
  input  logic auto_out_1_b_valid,
  input  logic [2:0] auto_out_1_b_bits_opcode,
  input  logic [1:0] auto_out_1_b_bits_param,
  input  logic [2:0] auto_out_1_b_bits_size,
  input  logic [6:0] auto_out_1_b_bits_source,
  input  logic [47:0] auto_out_1_b_bits_address,
  input  logic [31:0] auto_out_1_b_bits_mask,
  input  logic [255:0] auto_out_1_b_bits_data,
  input  logic auto_out_1_b_bits_corrupt,
  input  logic auto_out_1_c_ready,
  output logic auto_out_1_c_valid,
  output logic [2:0] auto_out_1_c_bits_opcode,
  output logic [2:0] auto_out_1_c_bits_param,
  output logic [2:0] auto_out_1_c_bits_size,
  output logic [6:0] auto_out_1_c_bits_source,
  output logic [47:0] auto_out_1_c_bits_address,
  output logic [4:0] auto_out_1_c_bits_user_reqSource,
  output logic [1:0] auto_out_1_c_bits_user_alias,
  output logic [43:0] auto_out_1_c_bits_user_vaddr,
  output logic auto_out_1_c_bits_user_needHint,
  output logic auto_out_1_c_bits_echo_isKeyword,
  output logic [255:0] auto_out_1_c_bits_data,
  output logic auto_out_1_c_bits_corrupt,
  output logic auto_out_1_d_ready,
  input  logic auto_out_1_d_valid,
  input  logic [3:0] auto_out_1_d_bits_opcode,
  input  logic [1:0] auto_out_1_d_bits_param,
  input  logic [2:0] auto_out_1_d_bits_size,
  input  logic [6:0] auto_out_1_d_bits_source,
  input  logic [7:0] auto_out_1_d_bits_sink,
  input  logic auto_out_1_d_bits_denied,
  input  logic auto_out_1_d_bits_echo_isKeyword,
  input  logic [255:0] auto_out_1_d_bits_data,
  input  logic auto_out_1_d_bits_corrupt,
  input  logic auto_out_1_e_ready,
  output logic auto_out_1_e_valid,
  output logic [7:0] auto_out_1_e_bits_sink,
  input  logic auto_out_0_a_ready,
  output logic auto_out_0_a_valid,
  output logic [3:0] auto_out_0_a_bits_opcode,
  output logic [2:0] auto_out_0_a_bits_param,
  output logic [2:0] auto_out_0_a_bits_size,
  output logic [6:0] auto_out_0_a_bits_source,
  output logic [47:0] auto_out_0_a_bits_address,
  output logic [4:0] auto_out_0_a_bits_user_reqSource,
  output logic [1:0] auto_out_0_a_bits_user_alias,
  output logic [43:0] auto_out_0_a_bits_user_vaddr,
  output logic auto_out_0_a_bits_user_needHint,
  output logic auto_out_0_a_bits_echo_isKeyword,
  output logic [31:0] auto_out_0_a_bits_mask,
  output logic [255:0] auto_out_0_a_bits_data,
  output logic auto_out_0_a_bits_corrupt,
  output logic auto_out_0_b_ready,
  input  logic auto_out_0_b_valid,
  input  logic [2:0] auto_out_0_b_bits_opcode,
  input  logic [1:0] auto_out_0_b_bits_param,
  input  logic [2:0] auto_out_0_b_bits_size,
  input  logic [6:0] auto_out_0_b_bits_source,
  input  logic [47:0] auto_out_0_b_bits_address,
  input  logic [31:0] auto_out_0_b_bits_mask,
  input  logic [255:0] auto_out_0_b_bits_data,
  input  logic auto_out_0_b_bits_corrupt,
  input  logic auto_out_0_c_ready,
  output logic auto_out_0_c_valid,
  output logic [2:0] auto_out_0_c_bits_opcode,
  output logic [2:0] auto_out_0_c_bits_param,
  output logic [2:0] auto_out_0_c_bits_size,
  output logic [6:0] auto_out_0_c_bits_source,
  output logic [47:0] auto_out_0_c_bits_address,
  output logic [4:0] auto_out_0_c_bits_user_reqSource,
  output logic [1:0] auto_out_0_c_bits_user_alias,
  output logic [43:0] auto_out_0_c_bits_user_vaddr,
  output logic auto_out_0_c_bits_user_needHint,
  output logic auto_out_0_c_bits_echo_isKeyword,
  output logic [255:0] auto_out_0_c_bits_data,
  output logic auto_out_0_c_bits_corrupt,
  output logic auto_out_0_d_ready,
  input  logic auto_out_0_d_valid,
  input  logic [3:0] auto_out_0_d_bits_opcode,
  input  logic [1:0] auto_out_0_d_bits_param,
  input  logic [2:0] auto_out_0_d_bits_size,
  input  logic [6:0] auto_out_0_d_bits_source,
  input  logic [7:0] auto_out_0_d_bits_sink,
  input  logic auto_out_0_d_bits_denied,
  input  logic auto_out_0_d_bits_echo_isKeyword,
  input  logic [255:0] auto_out_0_d_bits_data,
  input  logic auto_out_0_d_bits_corrupt,
  input  logic auto_out_0_e_ready,
  output logic auto_out_0_e_valid,
  output logic [7:0] auto_out_0_e_bits_sink
);

  logic  [NUM_IN-1:0]  in_a_valid, in_a_ready, in_d_ready, in_d_valid;
  tl_a_t in_a_bits [NUM_IN];
  tl_d_t in_d_bits [NUM_IN];
  logic  in0_b_valid, in0_c_ready, in0_e_ready;
  tl_b_t in0_b_bits;
  tl_c_t in0_c_bits;
  tl_e_t in0_e_bits;
  logic  [NUM_OUT-1:0] out_a_ready, out_a_valid, out_b_ready, out_b_valid, out_c_ready, out_c_valid,
                       out_d_ready, out_d_valid, out_e_ready, out_e_valid;
  tl_a_t out_a_bits [NUM_OUT];
  tl_b_t out_b_bits [NUM_OUT];
  tl_c_t out_c_bits [NUM_OUT];
  tl_d_t out_d_bits [NUM_OUT];
  tl_e_t out_e_bits [NUM_OUT];

  // ===== 主口 in0（DCache，TL-C 五通道） =====
  assign in_a_valid[0] = auto_in_0_a_valid;
  assign auto_in_0_a_ready = in_a_ready[0];
  assign in_a_bits[0] = '{opcode: auto_in_0_a_bits_opcode,
                        param: auto_in_0_a_bits_param,
                        size: auto_in_0_a_bits_size,
                        source: SOURCE_BASE_DCACHE | SOURCE_W'(auto_in_0_a_bits_source),
                        address: auto_in_0_a_bits_address,
                        user_reqSource: auto_in_0_a_bits_user_reqSource,
                        user_alias: auto_in_0_a_bits_user_alias,
                        user_vaddr: auto_in_0_a_bits_user_vaddr,
                        user_needHint: auto_in_0_a_bits_user_needHint,
                        echo_isKeyword: auto_in_0_a_bits_echo_isKeyword,
                        mask: auto_in_0_a_bits_mask,
                        data: auto_in_0_a_bits_data,
                        corrupt: auto_in_0_a_bits_corrupt};
  assign in0_b_ready = auto_in_0_b_ready;
  assign auto_in_0_b_valid = in0_b_valid;
  assign auto_in_0_b_bits_opcode = in0_b_bits.opcode;
  assign auto_in_0_b_bits_param = in0_b_bits.param;
  assign auto_in_0_b_bits_size = in0_b_bits.size;
  assign auto_in_0_b_bits_source = in0_b_bits.source[5:0];
  assign auto_in_0_b_bits_address = in0_b_bits.address;
  assign auto_in_0_b_bits_mask = in0_b_bits.mask;
  assign auto_in_0_b_bits_data = in0_b_bits.data;
  assign auto_in_0_b_bits_corrupt = in0_b_bits.corrupt;
  assign in0_c_valid = auto_in_0_c_valid;
  assign auto_in_0_c_ready = in0_c_ready;
  assign in0_c_bits = '{opcode: auto_in_0_c_bits_opcode,
                      param: auto_in_0_c_bits_param,
                      size: auto_in_0_c_bits_size,
                      source: SOURCE_BASE_DCACHE | SOURCE_W'(auto_in_0_c_bits_source),
                      address: auto_in_0_c_bits_address,
                      user_reqSource: auto_in_0_c_bits_user_reqSource,
                      user_alias: auto_in_0_c_bits_user_alias,
                      user_vaddr: auto_in_0_c_bits_user_vaddr,
                      user_needHint: auto_in_0_c_bits_user_needHint,
                      echo_isKeyword: auto_in_0_c_bits_echo_isKeyword,
                      data: auto_in_0_c_bits_data,
                      corrupt: auto_in_0_c_bits_corrupt};
  assign in_d_ready[0] = auto_in_0_d_ready;
  assign auto_in_0_d_valid = in_d_valid[0];
  assign auto_in_0_d_bits_opcode = in_d_bits[0].opcode;
  assign auto_in_0_d_bits_param = in_d_bits[0].param;
  assign auto_in_0_d_bits_size = in_d_bits[0].size;
  assign auto_in_0_d_bits_source = in_d_bits[0].source[5:0];
  assign auto_in_0_d_bits_sink = in_d_bits[0].sink;
  assign auto_in_0_d_bits_denied = in_d_bits[0].denied;
  assign auto_in_0_d_bits_echo_isKeyword = in_d_bits[0].echo_isKeyword;
  assign auto_in_0_d_bits_data = in_d_bits[0].data;
  assign auto_in_0_d_bits_corrupt = in_d_bits[0].corrupt;
  assign in0_e_valid = auto_in_0_e_valid;
  assign auto_in_0_e_ready = in0_e_ready;
  assign in0_e_bits = '{sink: auto_in_0_e_bits_sink};

  // ===== 主口 in1（ICache） =====
  assign in_a_valid[1] = auto_in_1_a_valid;
  assign auto_in_1_a_ready = in_a_ready[1];
  assign in_a_bits[1] = '{opcode: auto_in_1_a_bits_opcode,
                        param: auto_in_1_a_bits_param,
                        size: auto_in_1_a_bits_size,
                        source: SOURCE_BASE_ICACHE | SOURCE_W'(auto_in_1_a_bits_source),
                        address: auto_in_1_a_bits_address,
                        user_reqSource: auto_in_1_a_bits_user_reqSource,
                        user_alias: auto_in_1_a_bits_user_alias,
                        user_vaddr: '0 /* 本口无 */,
                        user_needHint: auto_in_1_a_bits_user_needHint,
                        echo_isKeyword: '0 /* 本口无 */,
                        mask: auto_in_1_a_bits_mask,
                        data: auto_in_1_a_bits_data,
                        corrupt: auto_in_1_a_bits_corrupt};
  assign in_d_ready[1] = auto_in_1_d_ready;
  assign auto_in_1_d_valid = in_d_valid[1];
  assign auto_in_1_d_bits_opcode = in_d_bits[1].opcode;
  assign auto_in_1_d_bits_param = in_d_bits[1].param;
  assign auto_in_1_d_bits_size = in_d_bits[1].size;
  assign auto_in_1_d_bits_source = in_d_bits[1].source[3:0];
  assign auto_in_1_d_bits_sink = in_d_bits[1].sink;
  assign auto_in_1_d_bits_denied = in_d_bits[1].denied;
  // in_d_bits[1].echo_isKeyword：本口无此输出，丢弃
  assign auto_in_1_d_bits_data = in_d_bits[1].data;
  assign auto_in_1_d_bits_corrupt = in_d_bits[1].corrupt;

  // ===== 主口 in2（PTW） =====
  assign in_a_valid[2] = auto_in_2_a_valid;
  assign auto_in_2_a_ready = in_a_ready[2];
  assign in_a_bits[2] = '{opcode: auto_in_2_a_bits_opcode,
                        param: auto_in_2_a_bits_param,
                        size: auto_in_2_a_bits_size,
                        source: SOURCE_BASE_PTW | SOURCE_W'(auto_in_2_a_bits_source),
                        address: auto_in_2_a_bits_address,
                        user_reqSource: auto_in_2_a_bits_user_reqSource,
                        user_alias: '0 /* 本口无 */,
                        user_vaddr: '0 /* 本口无 */,
                        user_needHint: '0 /* 本口无 */,
                        echo_isKeyword: '0 /* 本口无 */,
                        mask: auto_in_2_a_bits_mask,
                        data: auto_in_2_a_bits_data,
                        corrupt: auto_in_2_a_bits_corrupt};
  assign in_d_ready[2] = auto_in_2_d_ready;
  assign auto_in_2_d_valid = in_d_valid[2];
  assign auto_in_2_d_bits_opcode = in_d_bits[2].opcode;
  assign auto_in_2_d_bits_param = in_d_bits[2].param;
  assign auto_in_2_d_bits_size = in_d_bits[2].size;
  assign auto_in_2_d_bits_source = in_d_bits[2].source[3:0];
  assign auto_in_2_d_bits_sink = in_d_bits[2].sink;
  assign auto_in_2_d_bits_denied = in_d_bits[2].denied;
  // in_d_bits[2].echo_isKeyword：本口无此输出，丢弃
  assign auto_in_2_d_bits_data = in_d_bits[2].data;
  assign auto_in_2_d_bits_corrupt = in_d_bits[2].corrupt;

  // ===== 从口 out0（L2 bank 0：address[7:6] == 0，sink 前缀 3）=====
  assign out_a_ready[0] = auto_out_0_a_ready;
  assign auto_out_0_a_valid = out_a_valid[0];
  assign auto_out_0_a_bits_opcode = out_a_bits[0].opcode;
  assign auto_out_0_a_bits_param = out_a_bits[0].param;
  assign auto_out_0_a_bits_size = out_a_bits[0].size;
  assign auto_out_0_a_bits_source = out_a_bits[0].source;
  assign auto_out_0_a_bits_address = out_a_bits[0].address;
  assign auto_out_0_a_bits_user_reqSource = out_a_bits[0].user_reqSource;
  assign auto_out_0_a_bits_user_alias = out_a_bits[0].user_alias;
  assign auto_out_0_a_bits_user_vaddr = out_a_bits[0].user_vaddr;
  assign auto_out_0_a_bits_user_needHint = out_a_bits[0].user_needHint;
  assign auto_out_0_a_bits_echo_isKeyword = out_a_bits[0].echo_isKeyword;
  assign auto_out_0_a_bits_mask = out_a_bits[0].mask;
  assign auto_out_0_a_bits_data = out_a_bits[0].data;
  assign auto_out_0_a_bits_corrupt = out_a_bits[0].corrupt;
  assign out_b_valid[0] = auto_out_0_b_valid;
  assign auto_out_0_b_ready = out_b_ready[0];
  assign out_b_bits[0] = '{opcode: auto_out_0_b_bits_opcode,
                         param: auto_out_0_b_bits_param,
                         size: auto_out_0_b_bits_size,
                         source: auto_out_0_b_bits_source,
                         address: auto_out_0_b_bits_address,
                         mask: auto_out_0_b_bits_mask,
                         data: auto_out_0_b_bits_data,
                         corrupt: auto_out_0_b_bits_corrupt};
  assign out_c_ready[0] = auto_out_0_c_ready;
  assign auto_out_0_c_valid = out_c_valid[0];
  assign auto_out_0_c_bits_opcode = out_c_bits[0].opcode;
  assign auto_out_0_c_bits_param = out_c_bits[0].param;
  assign auto_out_0_c_bits_size = out_c_bits[0].size;
  assign auto_out_0_c_bits_source = out_c_bits[0].source;
  assign auto_out_0_c_bits_address = out_c_bits[0].address;
  assign auto_out_0_c_bits_user_reqSource = out_c_bits[0].user_reqSource;
  assign auto_out_0_c_bits_user_alias = out_c_bits[0].user_alias;
  assign auto_out_0_c_bits_user_vaddr = out_c_bits[0].user_vaddr;
  assign auto_out_0_c_bits_user_needHint = out_c_bits[0].user_needHint;
  assign auto_out_0_c_bits_echo_isKeyword = out_c_bits[0].echo_isKeyword;
  assign auto_out_0_c_bits_data = out_c_bits[0].data;
  assign auto_out_0_c_bits_corrupt = out_c_bits[0].corrupt;
  assign out_d_valid[0] = auto_out_0_d_valid;
  assign auto_out_0_d_ready = out_d_ready[0];
  assign out_d_bits[0] = '{opcode: auto_out_0_d_bits_opcode,
                         param: auto_out_0_d_bits_param,
                         size: auto_out_0_d_bits_size,
                         source: auto_out_0_d_bits_source,
                         sink: sink_base(0) | SINK_W'(auto_out_0_d_bits_sink),
                         denied: auto_out_0_d_bits_denied,
                         echo_isKeyword: auto_out_0_d_bits_echo_isKeyword,
                         data: auto_out_0_d_bits_data,
                         corrupt: auto_out_0_d_bits_corrupt};
  assign out_e_ready[0] = auto_out_0_e_ready;
  assign auto_out_0_e_valid = out_e_valid[0];
  assign auto_out_0_e_bits_sink = out_e_bits[0].sink[7:0];

  // ===== 从口 out1（L2 bank 1：address[7:6] == 1，sink 前缀 2）=====
  assign out_a_ready[1] = auto_out_1_a_ready;
  assign auto_out_1_a_valid = out_a_valid[1];
  assign auto_out_1_a_bits_opcode = out_a_bits[1].opcode;
  assign auto_out_1_a_bits_param = out_a_bits[1].param;
  assign auto_out_1_a_bits_size = out_a_bits[1].size;
  assign auto_out_1_a_bits_source = out_a_bits[1].source;
  assign auto_out_1_a_bits_address = out_a_bits[1].address;
  assign auto_out_1_a_bits_user_reqSource = out_a_bits[1].user_reqSource;
  assign auto_out_1_a_bits_user_alias = out_a_bits[1].user_alias;
  assign auto_out_1_a_bits_user_vaddr = out_a_bits[1].user_vaddr;
  assign auto_out_1_a_bits_user_needHint = out_a_bits[1].user_needHint;
  assign auto_out_1_a_bits_echo_isKeyword = out_a_bits[1].echo_isKeyword;
  assign auto_out_1_a_bits_mask = out_a_bits[1].mask;
  assign auto_out_1_a_bits_data = out_a_bits[1].data;
  assign auto_out_1_a_bits_corrupt = out_a_bits[1].corrupt;
  assign out_b_valid[1] = auto_out_1_b_valid;
  assign auto_out_1_b_ready = out_b_ready[1];
  assign out_b_bits[1] = '{opcode: auto_out_1_b_bits_opcode,
                         param: auto_out_1_b_bits_param,
                         size: auto_out_1_b_bits_size,
                         source: auto_out_1_b_bits_source,
                         address: auto_out_1_b_bits_address,
                         mask: auto_out_1_b_bits_mask,
                         data: auto_out_1_b_bits_data,
                         corrupt: auto_out_1_b_bits_corrupt};
  assign out_c_ready[1] = auto_out_1_c_ready;
  assign auto_out_1_c_valid = out_c_valid[1];
  assign auto_out_1_c_bits_opcode = out_c_bits[1].opcode;
  assign auto_out_1_c_bits_param = out_c_bits[1].param;
  assign auto_out_1_c_bits_size = out_c_bits[1].size;
  assign auto_out_1_c_bits_source = out_c_bits[1].source;
  assign auto_out_1_c_bits_address = out_c_bits[1].address;
  assign auto_out_1_c_bits_user_reqSource = out_c_bits[1].user_reqSource;
  assign auto_out_1_c_bits_user_alias = out_c_bits[1].user_alias;
  assign auto_out_1_c_bits_user_vaddr = out_c_bits[1].user_vaddr;
  assign auto_out_1_c_bits_user_needHint = out_c_bits[1].user_needHint;
  assign auto_out_1_c_bits_echo_isKeyword = out_c_bits[1].echo_isKeyword;
  assign auto_out_1_c_bits_data = out_c_bits[1].data;
  assign auto_out_1_c_bits_corrupt = out_c_bits[1].corrupt;
  assign out_d_valid[1] = auto_out_1_d_valid;
  assign auto_out_1_d_ready = out_d_ready[1];
  assign out_d_bits[1] = '{opcode: auto_out_1_d_bits_opcode,
                         param: auto_out_1_d_bits_param,
                         size: auto_out_1_d_bits_size,
                         source: auto_out_1_d_bits_source,
                         sink: sink_base(1) | SINK_W'(auto_out_1_d_bits_sink),
                         denied: auto_out_1_d_bits_denied,
                         echo_isKeyword: auto_out_1_d_bits_echo_isKeyword,
                         data: auto_out_1_d_bits_data,
                         corrupt: auto_out_1_d_bits_corrupt};
  assign out_e_ready[1] = auto_out_1_e_ready;
  assign auto_out_1_e_valid = out_e_valid[1];
  assign auto_out_1_e_bits_sink = out_e_bits[1].sink[7:0];

  // ===== 从口 out2（L2 bank 2：address[7:6] == 2，sink 前缀 1）=====
  assign out_a_ready[2] = auto_out_2_a_ready;
  assign auto_out_2_a_valid = out_a_valid[2];
  assign auto_out_2_a_bits_opcode = out_a_bits[2].opcode;
  assign auto_out_2_a_bits_param = out_a_bits[2].param;
  assign auto_out_2_a_bits_size = out_a_bits[2].size;
  assign auto_out_2_a_bits_source = out_a_bits[2].source;
  assign auto_out_2_a_bits_address = out_a_bits[2].address;
  assign auto_out_2_a_bits_user_reqSource = out_a_bits[2].user_reqSource;
  assign auto_out_2_a_bits_user_alias = out_a_bits[2].user_alias;
  assign auto_out_2_a_bits_user_vaddr = out_a_bits[2].user_vaddr;
  assign auto_out_2_a_bits_user_needHint = out_a_bits[2].user_needHint;
  assign auto_out_2_a_bits_echo_isKeyword = out_a_bits[2].echo_isKeyword;
  assign auto_out_2_a_bits_mask = out_a_bits[2].mask;
  assign auto_out_2_a_bits_data = out_a_bits[2].data;
  assign auto_out_2_a_bits_corrupt = out_a_bits[2].corrupt;
  assign out_b_valid[2] = auto_out_2_b_valid;
  assign auto_out_2_b_ready = out_b_ready[2];
  assign out_b_bits[2] = '{opcode: auto_out_2_b_bits_opcode,
                         param: auto_out_2_b_bits_param,
                         size: auto_out_2_b_bits_size,
                         source: auto_out_2_b_bits_source,
                         address: auto_out_2_b_bits_address,
                         mask: auto_out_2_b_bits_mask,
                         data: auto_out_2_b_bits_data,
                         corrupt: auto_out_2_b_bits_corrupt};
  assign out_c_ready[2] = auto_out_2_c_ready;
  assign auto_out_2_c_valid = out_c_valid[2];
  assign auto_out_2_c_bits_opcode = out_c_bits[2].opcode;
  assign auto_out_2_c_bits_param = out_c_bits[2].param;
  assign auto_out_2_c_bits_size = out_c_bits[2].size;
  assign auto_out_2_c_bits_source = out_c_bits[2].source;
  assign auto_out_2_c_bits_address = out_c_bits[2].address;
  assign auto_out_2_c_bits_user_reqSource = out_c_bits[2].user_reqSource;
  assign auto_out_2_c_bits_user_alias = out_c_bits[2].user_alias;
  assign auto_out_2_c_bits_user_vaddr = out_c_bits[2].user_vaddr;
  assign auto_out_2_c_bits_user_needHint = out_c_bits[2].user_needHint;
  assign auto_out_2_c_bits_echo_isKeyword = out_c_bits[2].echo_isKeyword;
  assign auto_out_2_c_bits_data = out_c_bits[2].data;
  assign auto_out_2_c_bits_corrupt = out_c_bits[2].corrupt;
  assign out_d_valid[2] = auto_out_2_d_valid;
  assign auto_out_2_d_ready = out_d_ready[2];
  assign out_d_bits[2] = '{opcode: auto_out_2_d_bits_opcode,
                         param: auto_out_2_d_bits_param,
                         size: auto_out_2_d_bits_size,
                         source: auto_out_2_d_bits_source,
                         sink: sink_base(2) | SINK_W'(auto_out_2_d_bits_sink),
                         denied: auto_out_2_d_bits_denied,
                         echo_isKeyword: auto_out_2_d_bits_echo_isKeyword,
                         data: auto_out_2_d_bits_data,
                         corrupt: auto_out_2_d_bits_corrupt};
  assign out_e_ready[2] = auto_out_2_e_ready;
  assign auto_out_2_e_valid = out_e_valid[2];
  assign auto_out_2_e_bits_sink = out_e_bits[2].sink[7:0];

  // ===== 从口 out3（L2 bank 3：address[7:6] == 3，sink 前缀 0）=====
  assign out_a_ready[3] = auto_out_3_a_ready;
  assign auto_out_3_a_valid = out_a_valid[3];
  assign auto_out_3_a_bits_opcode = out_a_bits[3].opcode;
  assign auto_out_3_a_bits_param = out_a_bits[3].param;
  assign auto_out_3_a_bits_size = out_a_bits[3].size;
  assign auto_out_3_a_bits_source = out_a_bits[3].source;
  assign auto_out_3_a_bits_address = out_a_bits[3].address;
  assign auto_out_3_a_bits_user_reqSource = out_a_bits[3].user_reqSource;
  assign auto_out_3_a_bits_user_alias = out_a_bits[3].user_alias;
  assign auto_out_3_a_bits_user_vaddr = out_a_bits[3].user_vaddr;
  assign auto_out_3_a_bits_user_needHint = out_a_bits[3].user_needHint;
  assign auto_out_3_a_bits_echo_isKeyword = out_a_bits[3].echo_isKeyword;
  assign auto_out_3_a_bits_mask = out_a_bits[3].mask;
  assign auto_out_3_a_bits_data = out_a_bits[3].data;
  assign auto_out_3_a_bits_corrupt = out_a_bits[3].corrupt;
  assign out_b_valid[3] = auto_out_3_b_valid;
  assign auto_out_3_b_ready = out_b_ready[3];
  assign out_b_bits[3] = '{opcode: auto_out_3_b_bits_opcode,
                         param: auto_out_3_b_bits_param,
                         size: auto_out_3_b_bits_size,
                         source: auto_out_3_b_bits_source,
                         address: auto_out_3_b_bits_address,
                         mask: auto_out_3_b_bits_mask,
                         data: auto_out_3_b_bits_data,
                         corrupt: auto_out_3_b_bits_corrupt};
  assign out_c_ready[3] = auto_out_3_c_ready;
  assign auto_out_3_c_valid = out_c_valid[3];
  assign auto_out_3_c_bits_opcode = out_c_bits[3].opcode;
  assign auto_out_3_c_bits_param = out_c_bits[3].param;
  assign auto_out_3_c_bits_size = out_c_bits[3].size;
  assign auto_out_3_c_bits_source = out_c_bits[3].source;
  assign auto_out_3_c_bits_address = out_c_bits[3].address;
  assign auto_out_3_c_bits_user_reqSource = out_c_bits[3].user_reqSource;
  assign auto_out_3_c_bits_user_alias = out_c_bits[3].user_alias;
  assign auto_out_3_c_bits_user_vaddr = out_c_bits[3].user_vaddr;
  assign auto_out_3_c_bits_user_needHint = out_c_bits[3].user_needHint;
  assign auto_out_3_c_bits_echo_isKeyword = out_c_bits[3].echo_isKeyword;
  assign auto_out_3_c_bits_data = out_c_bits[3].data;
  assign auto_out_3_c_bits_corrupt = out_c_bits[3].corrupt;
  assign out_d_valid[3] = auto_out_3_d_valid;
  assign auto_out_3_d_ready = out_d_ready[3];
  assign out_d_bits[3] = '{opcode: auto_out_3_d_bits_opcode,
                         param: auto_out_3_d_bits_param,
                         size: auto_out_3_d_bits_size,
                         source: auto_out_3_d_bits_source,
                         sink: sink_base(3) | SINK_W'(auto_out_3_d_bits_sink),
                         denied: auto_out_3_d_bits_denied,
                         echo_isKeyword: auto_out_3_d_bits_echo_isKeyword,
                         data: auto_out_3_d_bits_data,
                         corrupt: auto_out_3_d_bits_corrupt};
  assign out_e_ready[3] = auto_out_3_e_ready;
  assign auto_out_3_e_valid = out_e_valid[3];
  assign auto_out_3_e_bits_sink = out_e_bits[3].sink[7:0];

  xs_TLXbar_5_core u_core (
    .clock(clock), .reset(reset),
    .in_a_valid(in_a_valid), .in_a_ready(in_a_ready), .in_a_bits(in_a_bits),
    .in_d_ready(in_d_ready), .in_d_valid(in_d_valid), .in_d_bits(in_d_bits),
    .in0_b_ready(auto_in_0_b_ready), .in0_b_valid(in0_b_valid), .in0_b_bits(in0_b_bits),
    .in0_c_valid(auto_in_0_c_valid), .in0_c_ready(in0_c_ready), .in0_c_bits(in0_c_bits),
    .in0_e_valid(auto_in_0_e_valid), .in0_e_ready(in0_e_ready), .in0_e_bits(in0_e_bits),
    .out_a_ready(out_a_ready), .out_a_valid(out_a_valid), .out_a_bits(out_a_bits),
    .out_b_ready(out_b_ready), .out_b_valid(out_b_valid), .out_b_bits(out_b_bits),
    .out_c_ready(out_c_ready), .out_c_valid(out_c_valid), .out_c_bits(out_c_bits),
    .out_d_ready(out_d_ready), .out_d_valid(out_d_valid), .out_d_bits(out_d_bits),
    .out_e_ready(out_e_ready), .out_e_valid(out_e_valid), .out_e_bits(out_e_bits)
  );

endmodule
// END GENERATED
