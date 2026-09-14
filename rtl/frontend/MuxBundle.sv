// =============================================================================
// MuxBundle —— 按下标选择的 N 选 1 通道选择器（ICacheMissUnit 的预取 Acquire 出口）
//
// 位置：ICacheMissUnit 里，10 个预取 MSHR 各有一路 Acquire 请求，
//       由上游的空闲队列（FIFOReg）给出"这一拍轮到谁"的下标 io_sel，
//       本模块把那一路的握手与载荷接到唯一的出口上。
//       它与 Arbiter5_MSHRAcquire 的分工：这里先把 10 路预取压成 1 路，
//       再由 Arbiter5 和 4 路取指 Acquire 一起仲裁。
//
// 语义（纯组合、无状态）：
//   in_ready[k] = (sel == k) & out_ready   —— 只有被选中的那一路能握手；
//   out_valid   = in_valid[sel]；
//   out_bits    = in_bits[sel]；
//   out_bits_acquire_source = SOURCE_BASE + sel —— 这是 TileLink 的 source id：
//     取指 MSHR 占 0..3，预取 MSHR 接在后面占 4..13，所以 SOURCE_BASE = 4。
//     golden 把它写成 sel + 4 的常量表（4'h4 … 4'hD）。
//
// ★ golden 的越界行为照抄：sel 是 4 位（0..15），入口只有 10 个。
//   golden 的三元链最后一个 else 分支是"第 0 路"，于是 sel >= 10 时
//   out_valid / out_bits 取第 0 路、source 取 SOURCE_BASE + 0。
//   正常运行 sel 只会是 0..9，但 FM 比全状态空间，这段必须一致。
//
// 本文件 = 参数化可读核 xs_MuxBundle_core + golden 同名 wrapper。
// =============================================================================

module xs_MuxBundle_core #(
  parameter int unsigned WIDTH       = 56,  // 单路载荷位宽（不含 source）
  parameter int unsigned NUM_IN      = 10,  // 入口数
  parameter int unsigned SEL_W       = 4,   // sel 端口位宽
  parameter int unsigned SOURCE_W    = 4,   // source id 位宽
  parameter int unsigned SOURCE_BASE = 4,   // 第 0 路对应的 source id
  // ---- 由 wrapper 从 golden 端口表算出来，只用于自检 ----
  parameter int unsigned PORT_BITS_IN0 = WIDTH,  // = $bits({io_in_0_bits_*})
  parameter int unsigned PORT_BITS_OUT = WIDTH,  // = $bits({io_out_bits_* 去掉 source})
  parameter int unsigned GOLDEN_PORTS  = 0,      // golden 端口总数
  parameter int unsigned IN_FIELDS     = 2       // 每路载荷字段数
)(
  input  logic [SEL_W-1:0]        sel,
  input  logic [NUM_IN-1:0]       in_valid,     // 位 NUM_IN-1 = 第 0 路
  output logic [NUM_IN-1:0]       in_ready,
  input  logic [NUM_IN*WIDTH-1:0] in_bits,      // 与 in_valid 同序
  input  logic                    out_ready,
  output logic                    out_valid,
  output logic [WIDTH-1:0]        out_bits,
  output logic [SOURCE_W-1:0]     out_source
);

  initial begin
    if (NUM_IN < 2 || WIDTH == 0)
      $fatal(1, "xs_MuxBundle_core: NUM_IN=%0d WIDTH=%0d 不合法", NUM_IN, WIDTH);
    // sel 要装得下全部入口
    if (NUM_IN > (1 << SEL_W))
      $fatal(1, "xs_MuxBundle_core: sel 只有 %0d 位，装不下 %0d 个入口", SEL_W, NUM_IN);
    // source id 空间要装得下 SOURCE_BASE .. SOURCE_BASE+NUM_IN-1
    if (SOURCE_BASE + NUM_IN > (1 << SOURCE_W))
      $fatal(1, "xs_MuxBundle_core: source 只有 %0d 位，装不下 %0d..%0d（基址或入口数抄错）",
             SOURCE_W, SOURCE_BASE, SOURCE_BASE + NUM_IN - 1);
    if (PORT_BITS_IN0 != WIDTH || PORT_BITS_OUT != WIDTH)
      $fatal(1, "xs_MuxBundle_core: golden 载荷位宽 in0=%0d out=%0d != WIDTH=%0d（位宽抄错）",
             PORT_BITS_IN0, PORT_BITS_OUT, WIDTH);
    // golden 端口数恒等式：sel 1 根 + 每路 (ready+valid+载荷字段) + out_ready/out_valid
    // + 输出的 (载荷字段 + source)
    if (GOLDEN_PORTS != 1 + NUM_IN * (2 + IN_FIELDS) + 2 + (IN_FIELDS + 1))
      $fatal(1, "xs_MuxBundle_core: golden 端口数 %0d != 1+%0d*(2+%0d)+2+(%0d+1)（入口数或字段数抄错）",
             GOLDEN_PORTS, NUM_IN, IN_FIELDS, IN_FIELDS);
  end

  // hit[k] = 这一拍轮到第 k 路（golden 下标序）
  logic [NUM_IN-1:0] hit;
  for (genvar k = 0; k < NUM_IN; k++) begin : g_hit
    assign hit[k] = (sel == SEL_W'(k));
  end

  for (genvar k = 0; k < NUM_IN; k++) begin : g_ready
    // in_valid/in_bits/in_ready 的位序是"第 0 路在最高位"，所以下标要翻过来
    assign in_ready[NUM_IN-1-k] = hit[k] & out_ready;
  end

  // ★ 这里刻意不写 in_valid[sel] 这类"由信号算出来的下标"。
  //   sel 有 SEL_W=4 位（取值 0..15），而入口只有 NUM_IN=10 个：下标的取值范围
  //   在 RTL 上无法被静态证明落在 [0, NUM_IN-1] 内。Formality 在 link 阶段会为此
  //   报 FMR_ELAB-147（"Index may take values outside array bound"），而这条消息
  //   只要没被抑制就会让 set_top 直接失败（FM-262 → FM-156）——连 implementation
  //   design 都建不起来，证明根本没跑。改成"逐路比较 + 常量下标"后语义完全不变，
  //   FM 链接干净。（这正是本文件历史上让 ICacheMissUnit/MuxBundle 两个目标一起
  //   报 "FM-184 出现 0 次" 的真实根因。）
  //
  //   循环初值取第 0 路，正好覆盖 golden 三元链最后那个 else 分支：
  //   golden 依次比 sel==9 … sel==1，都不中就走第 0 路，于是 sel==0 与
  //   sel>=NUM_IN（越界）都落到第 0 路。
  always_comb begin
    out_valid  = in_valid[NUM_IN-1];
    out_bits   = in_bits[(NUM_IN-1)*WIDTH +: WIDTH];
    out_source = SOURCE_W'(SOURCE_BASE);
    for (int unsigned k = 1; k < NUM_IN; k++) begin
      if (hit[k]) begin
        out_valid  = in_valid[NUM_IN-1-k];
        out_bits   = in_bits[(NUM_IN-1-k)*WIDTH +: WIDTH];
        out_source = SOURCE_W'(SOURCE_BASE + k);
      end
    end
  end

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：ICacheMissUnit 的 10 路预取 Acquire 出口
//   载荷 = {acquire_address 48b, vSetIdx 8b} = 56 位；source = 4 + sel（4..13）
// ---------------------------------------------------------------------------
module MuxBundle(
  input  [3:0]  io_sel,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [47:0] io_in_0_bits_acquire_address,
  input  [7:0]  io_in_0_bits_vSetIdx,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [47:0] io_in_1_bits_acquire_address,
  input  [7:0]  io_in_1_bits_vSetIdx,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [47:0] io_in_2_bits_acquire_address,
  input  [7:0]  io_in_2_bits_vSetIdx,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [47:0] io_in_3_bits_acquire_address,
  input  [7:0]  io_in_3_bits_vSetIdx,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [47:0] io_in_4_bits_acquire_address,
  input  [7:0]  io_in_4_bits_vSetIdx,
  output        io_in_5_ready,
  input         io_in_5_valid,
  input  [47:0] io_in_5_bits_acquire_address,
  input  [7:0]  io_in_5_bits_vSetIdx,
  output        io_in_6_ready,
  input         io_in_6_valid,
  input  [47:0] io_in_6_bits_acquire_address,
  input  [7:0]  io_in_6_bits_vSetIdx,
  output        io_in_7_ready,
  input         io_in_7_valid,
  input  [47:0] io_in_7_bits_acquire_address,
  input  [7:0]  io_in_7_bits_vSetIdx,
  output        io_in_8_ready,
  input         io_in_8_valid,
  input  [47:0] io_in_8_bits_acquire_address,
  input  [7:0]  io_in_8_bits_vSetIdx,
  output        io_in_9_ready,
  input         io_in_9_valid,
  input  [47:0] io_in_9_bits_acquire_address,
  input  [7:0]  io_in_9_bits_vSetIdx,
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_acquire_source,
  output [47:0] io_out_bits_acquire_address,
  output [7:0]  io_out_bits_vSetIdx
);

  localparam int unsigned NUM_IN = 10;
  localparam int unsigned WIDTH  = 56;

  logic [NUM_IN-1:0]       in_valid_vec, in_ready_vec;
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;

  // 位序：第 0 路在最高位（与核里的约定一致）
  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid, io_in_3_valid, io_in_4_valid, io_in_5_valid, io_in_6_valid, io_in_7_valid, io_in_8_valid, io_in_9_valid};
  assign {io_in_0_ready, io_in_1_ready, io_in_2_ready, io_in_3_ready, io_in_4_ready, io_in_5_ready, io_in_6_ready, io_in_7_ready, io_in_8_ready, io_in_9_ready} = in_ready_vec;
  assign in_bits_flat =
    {io_in_0_bits_acquire_address, io_in_0_bits_vSetIdx,
     io_in_1_bits_acquire_address, io_in_1_bits_vSetIdx,
     io_in_2_bits_acquire_address, io_in_2_bits_vSetIdx,
     io_in_3_bits_acquire_address, io_in_3_bits_vSetIdx,
     io_in_4_bits_acquire_address, io_in_4_bits_vSetIdx,
     io_in_5_bits_acquire_address, io_in_5_bits_vSetIdx,
     io_in_6_bits_acquire_address, io_in_6_bits_vSetIdx,
     io_in_7_bits_acquire_address, io_in_7_bits_vSetIdx,
     io_in_8_bits_acquire_address, io_in_8_bits_vSetIdx,
     io_in_9_bits_acquire_address, io_in_9_bits_vSetIdx};

  xs_MuxBundle_core #(
    .WIDTH        (WIDTH),
    .NUM_IN       (NUM_IN),
    .SEL_W        ($bits(io_sel)),
    .SOURCE_W     ($bits(io_out_bits_acquire_source)),
    .SOURCE_BASE  (4),
    // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
    .PORT_BITS_IN0($bits({io_in_0_bits_acquire_address, io_in_0_bits_vSetIdx})),
    .PORT_BITS_OUT($bits({io_out_bits_acquire_address, io_out_bits_vSetIdx})),
    .GOLDEN_PORTS (46),
    .IN_FIELDS    (2)
  ) u_core (
    .sel       (io_sel),
    .in_valid  (in_valid_vec),
    .in_ready  (in_ready_vec),
    .in_bits   (in_bits_flat),
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  ({io_out_bits_acquire_address, io_out_bits_vSetIdx}),
    .out_source(io_out_bits_acquire_source)
  );

endmodule
