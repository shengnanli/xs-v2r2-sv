// =============================================================================
// Arbiter4_L2ToL1Hint —— 4 个 L2 slice 的"refill 提前提示"汇流成一路送给 L1 DCache
//
// 在哪一层：TL2CHICoupledL2 顶层（coupledL2/CoupledL2.scala
//   `l1HintArb = Module(new Arbiter(new L2ToL1Hint(), slices.size))`，slices.size = 4）。
//   每个 slice 在把 Grant 数据交给 L1 之前会先发一拍 L2ToL1Hint（sourceId = 目标 MSHR 的 TL source、
//   isKeyword = 关键字优先），L1 据此提前唤醒等 refill 的 load；同一拍多个 slice 都有提示时只能送一个。
// 语义：Chisel Arbiter —— 固定优先级、编号小者优先、纯组合；一路都没请求时出口给第 3 路的载荷。
//   io_chosen = 赢家编号（无人请求时为 3，同样是"兜底给最后一路"）。
// 结构：golden 端口 -> 拼成 4 路等宽载荷 -> 共享核 xs_FixedPriorityArbiter_core（rtl/frontend，已签核）-> 拆回端口；
//   核不产生 chosen，本文件第 4 节用同一套"编号小者优先"另算（golden 21 个端口里 io_chosen 不属于核的端口恒等式）。
// golden 对照：G1-canonical/golden-rtl/Arbiter4_L2ToL1Hint.sv（132 行 / 21 端口）
// =============================================================================
module Arbiter4_L2ToL1Hint (
  output logic io_in_0_ready,
  input  logic io_in_0_valid,
  input  logic [31:0] io_in_0_bits_sourceId,
  input  logic io_in_0_bits_isKeyword,
  output logic io_in_1_ready,
  input  logic io_in_1_valid,
  input  logic [31:0] io_in_1_bits_sourceId,
  input  logic io_in_1_bits_isKeyword,
  output logic io_in_2_ready,
  input  logic io_in_2_valid,
  input  logic [31:0] io_in_2_bits_sourceId,
  input  logic io_in_2_bits_isKeyword,
  output logic io_in_3_ready,
  input  logic io_in_3_valid,
  input  logic [31:0] io_in_3_bits_sourceId,
  input  logic io_in_3_bits_isKeyword,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [31:0] io_out_bits_sourceId,
  output logic io_out_bits_isKeyword,
  output logic [1:0] io_chosen
);

  localparam int unsigned NUM_IN = 4;
  localparam int unsigned WIDTH  = 33;   // 每路载荷：sourceId(32) + isKeyword(1)

  // ---------------------------------------------------------------------------
  // 1. 入口拼接：位 NUM_IN-1 = 第 0 路（优先级最高），与核的 in_valid 位序一致；
  //    每路载荷按 io_out_bits_* 的端口顺序 MSB 优先拼，缺端口的字段在原位置填常量
  // ---------------------------------------------------------------------------
  logic [NUM_IN-1:0]       in_valid_vec;
  logic [NUM_IN-1:0]       in_ready_vec;
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  logic [WIDTH-1:0]        out_bits_flat;

  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid, io_in_3_valid};
  assign in_bits_flat = {
    {io_in_0_bits_sourceId,
     io_in_0_bits_isKeyword},
    {io_in_1_bits_sourceId,
     io_in_1_bits_isKeyword},
    {io_in_2_bits_sourceId,
     io_in_2_bits_isKeyword},
    {io_in_3_bits_sourceId,
     io_in_3_bits_isKeyword}
  };

  // ---------------------------------------------------------------------------
  // 2. 仲裁核（固定优先级，纯组合；语义见 xs_FixedPriorityArbiter_core 文件头）
  // ---------------------------------------------------------------------------
  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    .PORT_BITS_OUT    ($bits({io_out_bits_sourceId, io_out_bits_isKeyword})),
    .PORT_BITS_LAST_IN($bits({io_in_3_bits_sourceId, io_in_3_bits_isKeyword})),
    .GOLDEN_PORTS     (21 - 1  /* 现存端口，不含 io_chosen */),
    .GOLDEN_BITS_PORTS(10)
  ) u_core (
    .in_valid (in_valid_vec),
    .in_ready (in_ready_vec),
    .in_bits  (in_bits_flat),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_bits (out_bits_flat)
  );

  // ---------------------------------------------------------------------------
  // 3. 出口拆分与各路 ready
  // ---------------------------------------------------------------------------
  assign io_in_0_ready = in_ready_vec[NUM_IN-1-0];
  assign io_in_1_ready = in_ready_vec[NUM_IN-1-1];
  assign io_in_2_ready = in_ready_vec[NUM_IN-1-2];
  assign io_in_3_ready = in_ready_vec[NUM_IN-1-3];
  assign {io_out_bits_sourceId,
          io_out_bits_isKeyword} = out_bits_flat;

  // ---------------------------------------------------------------------------
  // 4. io_chosen：赢家编号。从最低优先级往高扫，后写覆盖先写；无人请求时停在 3
  // ---------------------------------------------------------------------------
  always_comb begin
    io_chosen = 2'd3;
    for (int k = NUM_IN - 1; k >= 0; k--)
      if (in_valid_vec[NUM_IN-1-k])
        io_chosen = 2'(k);
  end
endmodule
