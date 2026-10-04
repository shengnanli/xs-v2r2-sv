// ICacheBuffer.sv —— L1 ICache ↔ L2 取指总线上的两级 TileLink 缓冲（MemBlock 侧，FrontendBridge.icache）
//
// 位置：前端 ICache 的 TL-UL 取指请求先经 MemBlock 里的 FrontendBridge 再进 L2。Scala
//   （mem/MemBlock.scala ICacheBuffer）对 A、D 两个通道各套两层 BufferParams.default，
//   即"三重缓冲"里 MemBlock 侧的两层（第三层在 L2Top）。只切时序，不改语义。
// 机制：每个通道 = 两个首尾相接的 Queue2（chisel3 Queue(entries=2, pipe=false, flow=false)，
//   每个 2 项、无旁路），所以 in→out 至少 2 拍、最多可缓存 4 笔。
//   A 通道（ICache → L2）：取指只发 Get，edge 把 opcode/size/mask/user 这些字段在入口就定成常量：
//     opcode=Get(4)、param=0、size=6（64B 整行）、mask=全 1、data=0、corrupt=0、
//     user.alias=0、user.reqSource=1（MemReqSource.CPUInst）、user.needHint=0；
//     只有 source（MSHR 号）与 address 来自 ICache。常量照样走队列（golden 如此），出口逐拍取队列里的值。
//   D 通道（L2 → ICache）：ICache 的 D 口没有 ready（MissUnit 永远接收），所以第二级队列
//     的 deq_ready 恒 1；param/sink/denied 在 ICache 侧无人读，出口不引出。
// 子模块 Queue2_TLBundleA_8 / Queue2_TLBundleD_7 是已签核的重写件（rtl/uncore），实例名与 golden 一致。

module ICacheBuffer (
  input  logic         clock,
  input  logic         reset,
  output logic         auto_in_a_ready,
  input  logic         auto_in_a_valid,
  input  logic [3:0]   auto_in_a_bits_source,
  input  logic [47:0]  auto_in_a_bits_address,
  output logic         auto_in_d_valid,
  output logic [3:0]   auto_in_d_bits_opcode,
  output logic [2:0]   auto_in_d_bits_size,
  output logic [3:0]   auto_in_d_bits_source,
  output logic [255:0] auto_in_d_bits_data,
  output logic         auto_in_d_bits_corrupt,
  input  logic         auto_out_a_ready,
  output logic         auto_out_a_valid,
  output logic [3:0]   auto_out_a_bits_opcode,
  output logic [2:0]   auto_out_a_bits_param,
  output logic [2:0]   auto_out_a_bits_size,
  output logic [3:0]   auto_out_a_bits_source,
  output logic [47:0]  auto_out_a_bits_address,
  output logic [1:0]   auto_out_a_bits_user_alias,
  output logic [4:0]   auto_out_a_bits_user_reqSource,
  output logic         auto_out_a_bits_user_needHint,
  output logic [31:0]  auto_out_a_bits_mask,
  output logic [255:0] auto_out_a_bits_data,
  output logic         auto_out_a_bits_corrupt,
  output logic         auto_out_d_ready,
  input  logic         auto_out_d_valid,
  input  logic [3:0]   auto_out_d_bits_opcode,
  input  logic [1:0]   auto_out_d_bits_param,
  input  logic [2:0]   auto_out_d_bits_size,
  input  logic [3:0]   auto_out_d_bits_source,
  input  logic [9:0]   auto_out_d_bits_sink,
  input  logic         auto_out_d_bits_denied,
  input  logic [255:0] auto_out_d_bits_data,
  input  logic         auto_out_d_bits_corrupt
);

  // ---------------------------------------------------------------------------
  // A 通道：ICache 取指请求 → 第一级 → 第二级 → L2
  //   入口把 Get 请求的常量字段补齐（取指请求 = 64B 整行 Get，CPUInst 来源）。
  // ---------------------------------------------------------------------------
  localparam logic [3:0]  TL_A_OPCODE_GET     = 4'h4;
  localparam logic [2:0]  FETCH_SIZE_64B      = 3'h6;
  localparam logic [4:0]  REQ_SOURCE_CPU_INST = 5'h1;

  // 第一级出口 / 第二级入口
  logic         a_mid_ready;
  logic         a_mid_valid;
  logic [3:0]   a_mid_opcode;
  logic [2:0]   a_mid_param;
  logic [2:0]   a_mid_size;
  logic [3:0]   a_mid_source;
  logic [47:0]  a_mid_address;
  logic [1:0]   a_mid_user_alias;
  logic [4:0]   a_mid_user_reqSource;
  logic         a_mid_user_needHint;
  logic [31:0]  a_mid_mask;
  logic [255:0] a_mid_data;
  logic         a_mid_corrupt;

  Queue2_TLBundleA_8 nodeOut_a_q (
    .clock                      (clock),
    .reset                      (reset),
    .io_enq_ready               (auto_in_a_ready),
    .io_enq_valid               (auto_in_a_valid),
    .io_enq_bits_opcode         (TL_A_OPCODE_GET),
    .io_enq_bits_param          (3'h0),
    .io_enq_bits_size           (FETCH_SIZE_64B),
    .io_enq_bits_source         (auto_in_a_bits_source),
    .io_enq_bits_address        (auto_in_a_bits_address),
    .io_enq_bits_user_alias     (2'h0),
    .io_enq_bits_user_reqSource (REQ_SOURCE_CPU_INST),
    .io_enq_bits_user_needHint  (1'b0),
    .io_enq_bits_mask           ({32{1'b1}}),
    .io_enq_bits_data           (256'h0),
    .io_enq_bits_corrupt        (1'b0),
    .io_deq_ready               (a_mid_ready),
    .io_deq_valid               (a_mid_valid),
    .io_deq_bits_opcode         (a_mid_opcode),
    .io_deq_bits_param          (a_mid_param),
    .io_deq_bits_size           (a_mid_size),
    .io_deq_bits_source         (a_mid_source),
    .io_deq_bits_address        (a_mid_address),
    .io_deq_bits_user_alias     (a_mid_user_alias),
    .io_deq_bits_user_reqSource (a_mid_user_reqSource),
    .io_deq_bits_user_needHint  (a_mid_user_needHint),
    .io_deq_bits_mask           (a_mid_mask),
    .io_deq_bits_data           (a_mid_data),
    .io_deq_bits_corrupt        (a_mid_corrupt)
  );

  Queue2_TLBundleA_8 nodeOut_a_q_1 (
    .clock                      (clock),
    .reset                      (reset),
    .io_enq_ready               (a_mid_ready),
    .io_enq_valid               (a_mid_valid),
    .io_enq_bits_opcode         (a_mid_opcode),
    .io_enq_bits_param          (a_mid_param),
    .io_enq_bits_size           (a_mid_size),
    .io_enq_bits_source         (a_mid_source),
    .io_enq_bits_address        (a_mid_address),
    .io_enq_bits_user_alias     (a_mid_user_alias),
    .io_enq_bits_user_reqSource (a_mid_user_reqSource),
    .io_enq_bits_user_needHint  (a_mid_user_needHint),
    .io_enq_bits_mask           (a_mid_mask),
    .io_enq_bits_data           (a_mid_data),
    .io_enq_bits_corrupt        (a_mid_corrupt),
    .io_deq_ready               (auto_out_a_ready),
    .io_deq_valid               (auto_out_a_valid),
    .io_deq_bits_opcode         (auto_out_a_bits_opcode),
    .io_deq_bits_param          (auto_out_a_bits_param),
    .io_deq_bits_size           (auto_out_a_bits_size),
    .io_deq_bits_source         (auto_out_a_bits_source),
    .io_deq_bits_address        (auto_out_a_bits_address),
    .io_deq_bits_user_alias     (auto_out_a_bits_user_alias),
    .io_deq_bits_user_reqSource (auto_out_a_bits_user_reqSource),
    .io_deq_bits_user_needHint  (auto_out_a_bits_user_needHint),
    .io_deq_bits_mask           (auto_out_a_bits_mask),
    .io_deq_bits_data           (auto_out_a_bits_data),
    .io_deq_bits_corrupt        (auto_out_a_bits_corrupt)
  );

  // ---------------------------------------------------------------------------
  // D 通道：L2 回填数据 → 第一级 → 第二级 → ICache
  //   ICache 侧恒接收（第二级 deq_ready = 1）；param/sink/denied 无人读，不引出。
  // ---------------------------------------------------------------------------
  logic         d_mid_ready;
  logic         d_mid_valid;
  logic [3:0]   d_mid_opcode;
  logic [1:0]   d_mid_param;
  logic [2:0]   d_mid_size;
  logic [3:0]   d_mid_source;
  logic [9:0]   d_mid_sink;
  logic         d_mid_denied;
  logic [255:0] d_mid_data;
  logic         d_mid_corrupt;

  Queue2_TLBundleD_7 nodeIn_d_q (
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

  Queue2_TLBundleD_7 nodeIn_d_q_1 (
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
    .io_deq_bits_opcode  (auto_in_d_bits_opcode),
    .io_deq_bits_param   (),
    .io_deq_bits_size    (auto_in_d_bits_size),
    .io_deq_bits_source  (auto_in_d_bits_source),
    .io_deq_bits_sink    (),
    .io_deq_bits_denied  (),
    .io_deq_bits_data    (auto_in_d_bits_data),
    .io_deq_bits_corrupt (auto_in_d_bits_corrupt)
  );

endmodule
