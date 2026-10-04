// InstrUncacheBuffer.sv —— 前端 MMIO 取指（InstrUncache）总线上的两级 TileLink 缓冲（MemBlock 侧，FrontendBridge.instr_uncache）
//
// 位置：IFU 取不可缓存（MMIO / NC）指令时，InstrUncache 发 TL-UL Get，经 MemBlock 的 FrontendBridge
//   再到 L2Top。Scala（mem/MemBlock.scala InstrUncacheBuffer）对 A、D 各套两层 BufferParams.default，
//   是"三重缓冲"里 MemBlock 侧的两层；只切时序，不改语义。
// 机制：每通道两个首尾相接的 Queue2（2 项、无旁路），in→out 至少 2 拍。
//   A 通道：取指 MMIO 永远是 8 字节 Get —— 入口常量 opcode=Get(4)、param=0、size=3（8B）、source=0、
//     mask=0xFF、data=0、corrupt=0；只有 address 与 user（memPageType_NC / memBackType_MM）来自
//     InstrUncache。Scala 在缓冲**之后**又把 opcode/size/source/mask/data 重新钉成常量，
//     firtool 于是把这几个出口常量推到父级、端口删掉——所以第二级出口只引出
//     param/address/user/corrupt，其余字段虽在队列里走一遍但无人读。
//   D 通道：InstrUncache 永远接收（第二级 deq_ready 恒 1），只用到 source/data/corrupt。
// 子模块 Queue2_TLBundleA_12 / Queue2_TLBundleD_13 是已签核的重写件（rtl/uncore），实例名与 golden 一致。

module InstrUncacheBuffer (
  input  logic        clock,
  input  logic        reset,
  output logic        auto_in_a_ready,
  input  logic        auto_in_a_valid,
  input  logic [47:0] auto_in_a_bits_address,
  input  logic        auto_in_a_bits_user_memPageType_NC,
  input  logic        auto_in_a_bits_user_memBackType_MM,
  output logic        auto_in_d_valid,
  output logic        auto_in_d_bits_source,
  output logic [63:0] auto_in_d_bits_data,
  output logic        auto_in_d_bits_corrupt,
  input  logic        auto_out_a_ready,
  output logic        auto_out_a_valid,
  output logic [2:0]  auto_out_a_bits_param,
  output logic [47:0] auto_out_a_bits_address,
  output logic        auto_out_a_bits_user_memPageType_NC,
  output logic        auto_out_a_bits_user_memBackType_MM,
  output logic        auto_out_a_bits_corrupt,
  output logic        auto_out_d_ready,
  input  logic        auto_out_d_valid,
  input  logic [3:0]  auto_out_d_bits_opcode,
  input  logic [1:0]  auto_out_d_bits_param,
  input  logic [1:0]  auto_out_d_bits_size,
  input  logic        auto_out_d_bits_source,
  input  logic        auto_out_d_bits_sink,
  input  logic        auto_out_d_bits_denied,
  input  logic [63:0] auto_out_d_bits_data,
  input  logic        auto_out_d_bits_corrupt
);

  // ---------------------------------------------------------------------------
  // A 通道：InstrUncache 的 8 字节 Get → 第一级 → 第二级 → L2Top
  // ---------------------------------------------------------------------------
  localparam logic [3:0] TL_A_OPCODE_GET = 4'h4;
  localparam logic [1:0] MMIO_SIZE_8B    = 2'h3;   // log2(mmioBusBytes = 8)

  logic        a_mid_ready;
  logic        a_mid_valid;
  logic [3:0]  a_mid_opcode;
  logic [2:0]  a_mid_param;
  logic [1:0]  a_mid_size;
  logic        a_mid_source;
  logic [47:0] a_mid_address;
  logic        a_mid_user_memPageType_NC;
  logic        a_mid_user_memBackType_MM;
  logic [7:0]  a_mid_mask;
  logic [63:0] a_mid_data;
  logic        a_mid_corrupt;

  Queue2_TLBundleA_12 nodeOut_a_q (
    .clock                           (clock),
    .reset                           (reset),
    .io_enq_ready                    (auto_in_a_ready),
    .io_enq_valid                    (auto_in_a_valid),
    .io_enq_bits_opcode              (TL_A_OPCODE_GET),
    .io_enq_bits_param               (3'h0),
    .io_enq_bits_size                (MMIO_SIZE_8B),
    .io_enq_bits_source              (1'b0),
    .io_enq_bits_address             (auto_in_a_bits_address),
    .io_enq_bits_user_memPageType_NC (auto_in_a_bits_user_memPageType_NC),
    .io_enq_bits_user_memBackType_MM (auto_in_a_bits_user_memBackType_MM),
    .io_enq_bits_mask                (8'hFF),
    .io_enq_bits_data                (64'h0),
    .io_enq_bits_corrupt             (1'b0),
    .io_deq_ready                    (a_mid_ready),
    .io_deq_valid                    (a_mid_valid),
    .io_deq_bits_opcode              (a_mid_opcode),
    .io_deq_bits_param               (a_mid_param),
    .io_deq_bits_size                (a_mid_size),
    .io_deq_bits_source              (a_mid_source),
    .io_deq_bits_address             (a_mid_address),
    .io_deq_bits_user_memPageType_NC (a_mid_user_memPageType_NC),
    .io_deq_bits_user_memBackType_MM (a_mid_user_memBackType_MM),
    .io_deq_bits_mask                (a_mid_mask),
    .io_deq_bits_data                (a_mid_data),
    .io_deq_bits_corrupt             (a_mid_corrupt)
  );

  // 第二级：opcode/size/source/mask/data 出口被 Scala 重新钉成常量（见文件头），这里不引出。
  Queue2_TLBundleA_12 nodeOut_a_q_1 (
    .clock                           (clock),
    .reset                           (reset),
    .io_enq_ready                    (a_mid_ready),
    .io_enq_valid                    (a_mid_valid),
    .io_enq_bits_opcode              (a_mid_opcode),
    .io_enq_bits_param               (a_mid_param),
    .io_enq_bits_size                (a_mid_size),
    .io_enq_bits_source              (a_mid_source),
    .io_enq_bits_address             (a_mid_address),
    .io_enq_bits_user_memPageType_NC (a_mid_user_memPageType_NC),
    .io_enq_bits_user_memBackType_MM (a_mid_user_memBackType_MM),
    .io_enq_bits_mask                (a_mid_mask),
    .io_enq_bits_data                (a_mid_data),
    .io_enq_bits_corrupt             (a_mid_corrupt),
    .io_deq_ready                    (auto_out_a_ready),
    .io_deq_valid                    (auto_out_a_valid),
    .io_deq_bits_opcode              (),
    .io_deq_bits_param               (auto_out_a_bits_param),
    .io_deq_bits_size                (),
    .io_deq_bits_source              (),
    .io_deq_bits_address             (auto_out_a_bits_address),
    .io_deq_bits_user_memPageType_NC (auto_out_a_bits_user_memPageType_NC),
    .io_deq_bits_user_memBackType_MM (auto_out_a_bits_user_memBackType_MM),
    .io_deq_bits_mask                (),
    .io_deq_bits_data                (),
    .io_deq_bits_corrupt             (auto_out_a_bits_corrupt)
  );

  // ---------------------------------------------------------------------------
  // D 通道：L2Top 应答 → 第一级 → 第二级 → InstrUncache（恒接收）
  // ---------------------------------------------------------------------------
  logic        d_mid_ready;
  logic        d_mid_valid;
  logic [3:0]  d_mid_opcode;
  logic [1:0]  d_mid_param;
  logic [1:0]  d_mid_size;
  logic        d_mid_source;
  logic        d_mid_sink;
  logic        d_mid_denied;
  logic [63:0] d_mid_data;
  logic        d_mid_corrupt;

  Queue2_TLBundleD_13 nodeIn_d_q (
    .clock               (clock),
    .reset               (reset),
    .io_enq_ready        (auto_out_d_ready),
    .io_enq_valid        (auto_out_d_valid),
    .io_enq_bits_opcode  (auto_out_d_bits_opcode),
    .io_enq_bits_param   (auto_out_d_bits_param),
    .io_enq_bits_size    (auto_out_d_bits_size),
    .io_enq_bits_source  (auto_out_d_bits_source),
    .io_enq_bits_sink    (auto_out_d_bits_sink),
    .io_enq_bits_denied  (auto_out_d_bits_denied),
    .io_enq_bits_data    (auto_out_d_bits_data),
    .io_enq_bits_corrupt (auto_out_d_bits_corrupt),
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

  Queue2_TLBundleD_13 nodeIn_d_q_1 (
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
    .io_deq_ready        (1'b1),
    .io_deq_valid        (auto_in_d_valid),
    .io_deq_bits_opcode  (),
    .io_deq_bits_param   (),
    .io_deq_bits_size    (),
    .io_deq_bits_source  (auto_in_d_bits_source),
    .io_deq_bits_sink    (),
    .io_deq_bits_denied  (),
    .io_deq_bits_data    (auto_in_d_bits_data),
    .io_deq_bits_corrupt (auto_in_d_bits_corrupt)
  );

endmodule
