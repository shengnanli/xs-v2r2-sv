// ICacheCtrlBuffer.sv —— ICache 控制寄存器口（ICacheCtrlUnit 的 TL-UL 从口）上的两级 TileLink 缓冲（FrontendBridge.icachectrl）
//
// 位置：ICache 里有一组可被软件读写的控制寄存器（ECC 开关 / 注入，ICacheCtrlUnit），挂在一个 TL-UL
//   从口上。总线侧的访问经 MemBlock 的 FrontendBridge 转进来。Scala（mem/MemBlock.scala
//   ICacheCtrlBuffer）对 A、D 各套两层 BufferParams.default；只切时序，不改语义。
//   注意方向：这里 in = 总线主端（L2 侧 MMIO 交叉开关），out = ICacheCtrlUnit（从端）。
// 机制：每通道两个首尾相接的 Queue2（2 项、无旁路），in→out 至少 2 拍。
//   A 通道（请求）：所有字段原样走队列；出口不引出 param/corrupt（ICacheCtrlUnit 不读）。
//   D 通道（应答）：ICacheCtrlUnit 只回 opcode/size/source/data，param/sink/denied/corrupt
//     在入口补常量 0 再进队列；入口 D ready 来自主端（不是恒 1）。
// 子模块 Queue2_TLBundleA_10 / Queue2_TLBundleD_11 是已签核的重写件（rtl/uncore），实例名与 golden 一致。

module ICacheCtrlBuffer (
  input  logic        clock,
  input  logic        reset,
  output logic        auto_in_a_ready,
  input  logic        auto_in_a_valid,
  input  logic [3:0]  auto_in_a_bits_opcode,
  input  logic [2:0]  auto_in_a_bits_param,
  input  logic [1:0]  auto_in_a_bits_size,
  input  logic [4:0]  auto_in_a_bits_source,
  input  logic [29:0] auto_in_a_bits_address,
  input  logic [7:0]  auto_in_a_bits_mask,
  input  logic [63:0] auto_in_a_bits_data,
  input  logic        auto_in_a_bits_corrupt,
  input  logic        auto_in_d_ready,
  output logic        auto_in_d_valid,
  output logic [3:0]  auto_in_d_bits_opcode,
  output logic [1:0]  auto_in_d_bits_param,
  output logic [1:0]  auto_in_d_bits_size,
  output logic [4:0]  auto_in_d_bits_source,
  output logic        auto_in_d_bits_sink,
  output logic        auto_in_d_bits_denied,
  output logic [63:0] auto_in_d_bits_data,
  output logic        auto_in_d_bits_corrupt,
  input  logic        auto_out_a_ready,
  output logic        auto_out_a_valid,
  output logic [3:0]  auto_out_a_bits_opcode,
  output logic [1:0]  auto_out_a_bits_size,
  output logic [4:0]  auto_out_a_bits_source,
  output logic [29:0] auto_out_a_bits_address,
  output logic [7:0]  auto_out_a_bits_mask,
  output logic [63:0] auto_out_a_bits_data,
  output logic        auto_out_d_ready,
  input  logic        auto_out_d_valid,
  input  logic [3:0]  auto_out_d_bits_opcode,
  input  logic [1:0]  auto_out_d_bits_size,
  input  logic [4:0]  auto_out_d_bits_source,
  input  logic [63:0] auto_out_d_bits_data
);

  // ---------------------------------------------------------------------------
  // A 通道：总线主端请求 → 第一级 → 第二级 → ICacheCtrlUnit
  // ---------------------------------------------------------------------------
  logic        a_mid_ready;
  logic        a_mid_valid;
  logic [3:0]  a_mid_opcode;
  logic [2:0]  a_mid_param;
  logic [1:0]  a_mid_size;
  logic [4:0]  a_mid_source;
  logic [29:0] a_mid_address;
  logic [7:0]  a_mid_mask;
  logic [63:0] a_mid_data;
  logic        a_mid_corrupt;

  Queue2_TLBundleA_10 nodeOut_a_q (
    .clock               (clock),
    .reset               (reset),
    .io_enq_ready        (auto_in_a_ready),
    .io_enq_valid        (auto_in_a_valid),
    .io_enq_bits_opcode  (auto_in_a_bits_opcode),
    .io_enq_bits_param   (auto_in_a_bits_param),
    .io_enq_bits_size    (auto_in_a_bits_size),
    .io_enq_bits_source  (auto_in_a_bits_source),
    .io_enq_bits_address (auto_in_a_bits_address),
    .io_enq_bits_mask    (auto_in_a_bits_mask),
    .io_enq_bits_data    (auto_in_a_bits_data),
    .io_enq_bits_corrupt (auto_in_a_bits_corrupt),
    .io_deq_ready        (a_mid_ready),
    .io_deq_valid        (a_mid_valid),
    .io_deq_bits_opcode  (a_mid_opcode),
    .io_deq_bits_param   (a_mid_param),
    .io_deq_bits_size    (a_mid_size),
    .io_deq_bits_source  (a_mid_source),
    .io_deq_bits_address (a_mid_address),
    .io_deq_bits_mask    (a_mid_mask),
    .io_deq_bits_data    (a_mid_data),
    .io_deq_bits_corrupt (a_mid_corrupt)
  );

  Queue2_TLBundleA_10 nodeOut_a_q_1 (
    .clock               (clock),
    .reset               (reset),
    .io_enq_ready        (a_mid_ready),
    .io_enq_valid        (a_mid_valid),
    .io_enq_bits_opcode  (a_mid_opcode),
    .io_enq_bits_param   (a_mid_param),
    .io_enq_bits_size    (a_mid_size),
    .io_enq_bits_source  (a_mid_source),
    .io_enq_bits_address (a_mid_address),
    .io_enq_bits_mask    (a_mid_mask),
    .io_enq_bits_data    (a_mid_data),
    .io_enq_bits_corrupt (a_mid_corrupt),
    .io_deq_ready        (auto_out_a_ready),
    .io_deq_valid        (auto_out_a_valid),
    .io_deq_bits_opcode  (auto_out_a_bits_opcode),
    .io_deq_bits_param   (),
    .io_deq_bits_size    (auto_out_a_bits_size),
    .io_deq_bits_source  (auto_out_a_bits_source),
    .io_deq_bits_address (auto_out_a_bits_address),
    .io_deq_bits_mask    (auto_out_a_bits_mask),
    .io_deq_bits_data    (auto_out_a_bits_data),
    .io_deq_bits_corrupt ()
  );

  // ---------------------------------------------------------------------------
  // D 通道：ICacheCtrlUnit 应答 → 第一级 → 第二级 → 总线主端
  //   从端不产生 param/sink/denied/corrupt，入口补 0。
  // ---------------------------------------------------------------------------
  logic        d_mid_ready;
  logic        d_mid_valid;
  logic [3:0]  d_mid_opcode;
  logic [1:0]  d_mid_param;
  logic [1:0]  d_mid_size;
  logic [4:0]  d_mid_source;
  logic        d_mid_sink;
  logic        d_mid_denied;
  logic [63:0] d_mid_data;
  logic        d_mid_corrupt;

  Queue2_TLBundleD_11 nodeIn_d_q (
    .clock               (clock),
    .reset               (reset),
    .io_enq_ready        (auto_out_d_ready),
    .io_enq_valid        (auto_out_d_valid),
    .io_enq_bits_opcode  (auto_out_d_bits_opcode),
    .io_enq_bits_param   (2'h0),
    .io_enq_bits_size    (auto_out_d_bits_size),
    .io_enq_bits_source  (auto_out_d_bits_source),
    .io_enq_bits_sink    (1'b0),
    .io_enq_bits_denied  (1'b0),
    .io_enq_bits_data    (auto_out_d_bits_data),
    .io_enq_bits_corrupt (1'b0),
    .io_deq_ready        (d_mid_ready),
    .io_deq_valid        (d_mid_valid),
    .io_deq_bits_opcode  (d_mid_opcode),
    .io_deq_bits_param   (d_mid_param),
    .io_deq_bits_size    (d_mid_size),
    .io_deq_bits_source  (d_mid_source),
    .io_deq_bits_sink    (d_mid_sink),
    .io_deq_bits_denied  (d_mid_denied),
    .io_deq_bits_data    (d_mid_data),
    .io_deq_bits_corrupt (d_mid_corrupt)
  );

  Queue2_TLBundleD_11 nodeIn_d_q_1 (
    .clock               (clock),
    .reset               (reset),
    .io_enq_ready        (d_mid_ready),
    .io_enq_valid        (d_mid_valid),
    .io_enq_bits_opcode  (d_mid_opcode),
    .io_enq_bits_param   (d_mid_param),
    .io_enq_bits_size    (d_mid_size),
    .io_enq_bits_source  (d_mid_source),
    .io_enq_bits_sink    (d_mid_sink),
    .io_enq_bits_denied  (d_mid_denied),
    .io_enq_bits_data    (d_mid_data),
    .io_enq_bits_corrupt (d_mid_corrupt),
    .io_deq_ready        (auto_in_d_ready),
    .io_deq_valid        (auto_in_d_valid),
    .io_deq_bits_opcode  (auto_in_d_bits_opcode),
    .io_deq_bits_param   (auto_in_d_bits_param),
    .io_deq_bits_size    (auto_in_d_bits_size),
    .io_deq_bits_source  (auto_in_d_bits_source),
    .io_deq_bits_sink    (auto_in_d_bits_sink),
    .io_deq_bits_denied  (auto_in_d_bits_denied),
    .io_deq_bits_data    (auto_in_d_bits_data),
    .io_deq_bits_corrupt (auto_in_d_bits_corrupt)
  );

endmodule
