// =============================================================================
// TLBuffer_15 —— TileLink A/D 两通道时序缓冲（xs_TLBuffer_ad_core 家族的又一个变体）
//
// 位置：L2Top 里 3 处 —— inner_i_mmio_buffer（核的 uncache/MMIO 口）与
//   inner_buffers / inner_buffers_1（另两条 64 位 TL-UL 小口）。都是 rocket-chip
//   TLBuffer(BufferParams.default)：A、D 各串一个 Queue(entries=2) 切断 ready/valid
//   组合路径，代价一拍；不解释 opcode、不重排，单通道严格保序。
//
// 本变体的规模与参数（按 G1 golden 现读）：
//   端口 46 个；golden 模块体只有两条 Queue2 例化，本层无状态、无组合逻辑。
//   A 通道：size 2b、source 1b、address 48b、mask 8b、data 64b，
//           user 附带位 = memPageType_NC(1b) + memBackType_MM(1b)。
//   D 通道：size 2b、source 1b、sink 1b、data 64b。
//   队列：A = Queue2_TLBundleA_12（载荷 133 位，ram_2x133）
//         D = Queue2_TLBundleD_13（载荷 76 位，ram_2x76）
//   两个队列用本仓已签的重写件（rtl/uncore/Queue2_TLBundle{A_12,D_13}.sv，控制在
//   rtl/common/xs_ChiselQueue_core.sv）；只有其中的 ram_2x* 行为级存储叶子两侧同源。
//   G0 -> G1 本变体端口位宽未变（source 一直是 1 位）。
//
// 结构：golden 同名端口表 -> 设参例化已签共享核 xs_TLBuffer_ad_core（不改核）
//   -> 核暴露的 a_q_*/d_q_* 接到上面两个队列。A 通道的 user 位是不透明附带位，
//   缓冲不解释它，直接从端口接到队列，不过核（核只在载荷宽度等式里计它的位数）。
// 端口表/连线首稿由 scripts/gen_tlbuffer_ad_family.py 的 Variant/gen_rtl 现读 golden
//   生成，再改本文件头；本变体不在该生成器 VARIANTS 里（它的 tb 覆盖闸按 source>=8 设计，
//   不适用 1 位 source），本文件手工维护，UT 的 portlint 逐位核对端口。
// =============================================================================
module TLBuffer_15(
  input clock,
  input reset,
  output auto_in_a_ready,
  input auto_in_a_valid,
  input [3:0] auto_in_a_bits_opcode,
  input [2:0] auto_in_a_bits_param,
  input [1:0] auto_in_a_bits_size,
  input auto_in_a_bits_source,
  input [47:0] auto_in_a_bits_address,
  input auto_in_a_bits_user_memPageType_NC,
  input auto_in_a_bits_user_memBackType_MM,
  input [7:0] auto_in_a_bits_mask,
  input [63:0] auto_in_a_bits_data,
  input auto_in_a_bits_corrupt,
  input auto_in_d_ready,
  output auto_in_d_valid,
  output [3:0] auto_in_d_bits_opcode,
  output [1:0] auto_in_d_bits_param,
  output [1:0] auto_in_d_bits_size,
  output auto_in_d_bits_source,
  output auto_in_d_bits_sink,
  output auto_in_d_bits_denied,
  output [63:0] auto_in_d_bits_data,
  output auto_in_d_bits_corrupt,
  input auto_out_a_ready,
  output auto_out_a_valid,
  output [3:0] auto_out_a_bits_opcode,
  output [2:0] auto_out_a_bits_param,
  output [1:0] auto_out_a_bits_size,
  output auto_out_a_bits_source,
  output [47:0] auto_out_a_bits_address,
  output auto_out_a_bits_user_memPageType_NC,
  output auto_out_a_bits_user_memBackType_MM,
  output [7:0] auto_out_a_bits_mask,
  output [63:0] auto_out_a_bits_data,
  output auto_out_a_bits_corrupt,
  output auto_out_d_ready,
  input auto_out_d_valid,
  input [3:0] auto_out_d_bits_opcode,
  input [1:0] auto_out_d_bits_param,
  input [1:0] auto_out_d_bits_size,
  input auto_out_d_bits_source,
  input auto_out_d_bits_sink,
  input auto_out_d_bits_denied,
  input [63:0] auto_out_d_bits_data,
  input auto_out_d_bits_corrupt
);

  // 核 <-> 队列的内部线（A/D 各一组 enq/deq）
  wire a_q_enq_valid;
  wire a_q_enq_ready;
  wire [3:0] a_q_enq_opcode;
  wire [2:0] a_q_enq_param;
  wire [1:0] a_q_enq_size;
  wire a_q_enq_source;
  wire [47:0] a_q_enq_address;
  wire [7:0] a_q_enq_mask;
  wire [63:0] a_q_enq_data;
  wire a_q_enq_corrupt;
  wire a_q_deq_valid;
  wire a_q_deq_ready;
  wire [3:0] a_q_deq_opcode;
  wire [2:0] a_q_deq_param;
  wire [1:0] a_q_deq_size;
  wire a_q_deq_source;
  wire [47:0] a_q_deq_address;
  wire [7:0] a_q_deq_mask;
  wire [63:0] a_q_deq_data;
  wire a_q_deq_corrupt;
  wire d_q_enq_valid;
  wire d_q_enq_ready;
  wire [3:0] d_q_enq_opcode;
  wire [1:0] d_q_enq_param;
  wire [1:0] d_q_enq_size;
  wire d_q_enq_source;
  wire d_q_enq_sink;
  wire d_q_enq_denied;
  wire [63:0] d_q_enq_data;
  wire d_q_enq_corrupt;
  wire d_q_deq_valid;
  wire d_q_deq_ready;
  wire [3:0] d_q_deq_opcode;
  wire [1:0] d_q_deq_param;
  wire [1:0] d_q_deq_size;
  wire d_q_deq_source;
  wire d_q_deq_sink;
  wire d_q_deq_denied;
  wire [63:0] d_q_deq_data;
  wire d_q_deq_corrupt;

  xs_TLBuffer_ad_core #(
    .A_SIZE_W   (2),
    .D_SIZE_W   (2),
    .SOURCE_W   (1),
    .ADDR_W     (48),
    .MASK_W     (8),
    .DATA_W     (64),
    .D_SINK_W   (1),
    .A_USER_W   (2),
    .A_RAM_WIDTH(133),
    .D_RAM_WIDTH(76)
  ) u_core (
    .auto_in_a_ready         (auto_in_a_ready),
    .auto_in_a_valid         (auto_in_a_valid),
    .auto_in_a_bits_opcode   (auto_in_a_bits_opcode),
    .auto_in_a_bits_param    (auto_in_a_bits_param),
    .auto_in_a_bits_size     (auto_in_a_bits_size),
    .auto_in_a_bits_source   (auto_in_a_bits_source),
    .auto_in_a_bits_address  (auto_in_a_bits_address),
    .auto_in_a_bits_mask     (auto_in_a_bits_mask),
    .auto_in_a_bits_data     (auto_in_a_bits_data),
    .auto_in_a_bits_corrupt  (auto_in_a_bits_corrupt),
    .auto_out_a_ready        (auto_out_a_ready),
    .auto_out_a_valid        (auto_out_a_valid),
    .auto_out_a_bits_opcode  (auto_out_a_bits_opcode),
    .auto_out_a_bits_param   (auto_out_a_bits_param),
    .auto_out_a_bits_size    (auto_out_a_bits_size),
    .auto_out_a_bits_source  (auto_out_a_bits_source),
    .auto_out_a_bits_address (auto_out_a_bits_address),
    .auto_out_a_bits_mask    (auto_out_a_bits_mask),
    .auto_out_a_bits_data    (auto_out_a_bits_data),
    .auto_out_a_bits_corrupt (auto_out_a_bits_corrupt),
    .auto_out_d_ready        (auto_out_d_ready),
    .auto_out_d_valid        (auto_out_d_valid),
    .auto_out_d_bits_opcode  (auto_out_d_bits_opcode),
    .auto_out_d_bits_param   (auto_out_d_bits_param),
    .auto_out_d_bits_size    (auto_out_d_bits_size),
    .auto_out_d_bits_source  (auto_out_d_bits_source),
    .auto_out_d_bits_sink    (auto_out_d_bits_sink),
    .auto_out_d_bits_denied  (auto_out_d_bits_denied),
    .auto_out_d_bits_data    (auto_out_d_bits_data),
    .auto_out_d_bits_corrupt (auto_out_d_bits_corrupt),
    .auto_in_d_ready         (auto_in_d_ready),
    .auto_in_d_valid         (auto_in_d_valid),
    .auto_in_d_bits_opcode   (auto_in_d_bits_opcode),
    .auto_in_d_bits_param    (auto_in_d_bits_param),
    .auto_in_d_bits_size     (auto_in_d_bits_size),
    .auto_in_d_bits_source   (auto_in_d_bits_source),
    .auto_in_d_bits_sink     (auto_in_d_bits_sink),
    .auto_in_d_bits_denied   (auto_in_d_bits_denied),
    .auto_in_d_bits_data     (auto_in_d_bits_data),
    .auto_in_d_bits_corrupt  (auto_in_d_bits_corrupt),
    .a_q_enq_valid           (a_q_enq_valid),
    .a_q_enq_ready           (a_q_enq_ready),
    .a_q_enq_opcode          (a_q_enq_opcode),
    .a_q_enq_param           (a_q_enq_param),
    .a_q_enq_size            (a_q_enq_size),
    .a_q_enq_source          (a_q_enq_source),
    .a_q_enq_address         (a_q_enq_address),
    .a_q_enq_mask            (a_q_enq_mask),
    .a_q_enq_data            (a_q_enq_data),
    .a_q_enq_corrupt         (a_q_enq_corrupt),
    .a_q_deq_valid           (a_q_deq_valid),
    .a_q_deq_ready           (a_q_deq_ready),
    .a_q_deq_opcode          (a_q_deq_opcode),
    .a_q_deq_param           (a_q_deq_param),
    .a_q_deq_size            (a_q_deq_size),
    .a_q_deq_source          (a_q_deq_source),
    .a_q_deq_address         (a_q_deq_address),
    .a_q_deq_mask            (a_q_deq_mask),
    .a_q_deq_data            (a_q_deq_data),
    .a_q_deq_corrupt         (a_q_deq_corrupt),
    .d_q_enq_valid           (d_q_enq_valid),
    .d_q_enq_ready           (d_q_enq_ready),
    .d_q_enq_opcode          (d_q_enq_opcode),
    .d_q_enq_param           (d_q_enq_param),
    .d_q_enq_size            (d_q_enq_size),
    .d_q_enq_source          (d_q_enq_source),
    .d_q_enq_sink            (d_q_enq_sink),
    .d_q_enq_denied          (d_q_enq_denied),
    .d_q_enq_data            (d_q_enq_data),
    .d_q_enq_corrupt         (d_q_enq_corrupt),
    .d_q_deq_valid           (d_q_deq_valid),
    .d_q_deq_ready           (d_q_deq_ready),
    .d_q_deq_opcode          (d_q_deq_opcode),
    .d_q_deq_param           (d_q_deq_param),
    .d_q_deq_size            (d_q_deq_size),
    .d_q_deq_source          (d_q_deq_source),
    .d_q_deq_sink            (d_q_deq_sink),
    .d_q_deq_denied          (d_q_deq_denied),
    .d_q_deq_data            (d_q_deq_data),
    .d_q_deq_corrupt         (d_q_deq_corrupt)
  );

  // A 通道队列：client -> manager 的请求打一拍
  Queue2_TLBundleA_12 nodeOut_a_q (
    .clock                           (clock),
    .reset                           (reset),
    .io_enq_ready                    (a_q_enq_ready),
    .io_enq_valid                    (a_q_enq_valid),
    .io_enq_bits_opcode              (a_q_enq_opcode),
    .io_enq_bits_param               (a_q_enq_param),
    .io_enq_bits_size                (a_q_enq_size),
    .io_enq_bits_source              (a_q_enq_source),
    .io_enq_bits_address             (a_q_enq_address),
    .io_enq_bits_user_memPageType_NC (auto_in_a_bits_user_memPageType_NC),
    .io_enq_bits_user_memBackType_MM (auto_in_a_bits_user_memBackType_MM),
    .io_enq_bits_mask                (a_q_enq_mask),
    .io_enq_bits_data                (a_q_enq_data),
    .io_enq_bits_corrupt             (a_q_enq_corrupt),
    .io_deq_ready                    (a_q_deq_ready),
    .io_deq_valid                    (a_q_deq_valid),
    .io_deq_bits_opcode              (a_q_deq_opcode),
    .io_deq_bits_param               (a_q_deq_param),
    .io_deq_bits_size                (a_q_deq_size),
    .io_deq_bits_source              (a_q_deq_source),
    .io_deq_bits_address             (a_q_deq_address),
    .io_deq_bits_user_memPageType_NC (auto_out_a_bits_user_memPageType_NC),
    .io_deq_bits_user_memBackType_MM (auto_out_a_bits_user_memBackType_MM),
    .io_deq_bits_mask                (a_q_deq_mask),
    .io_deq_bits_data                (a_q_deq_data),
    .io_deq_bits_corrupt             (a_q_deq_corrupt)
  );

  // D 通道队列：manager -> client 的应答打一拍
  Queue2_TLBundleD_13 nodeIn_d_q (
    .clock               (clock),
    .reset               (reset),
    .io_enq_ready        (d_q_enq_ready),
    .io_enq_valid        (d_q_enq_valid),
    .io_enq_bits_opcode  (d_q_enq_opcode),
    .io_enq_bits_param   (d_q_enq_param),
    .io_enq_bits_size    (d_q_enq_size),
    .io_enq_bits_source  (d_q_enq_source),
    .io_enq_bits_sink    (d_q_enq_sink),
    .io_enq_bits_denied  (d_q_enq_denied),
    .io_enq_bits_data    (d_q_enq_data),
    .io_enq_bits_corrupt (d_q_enq_corrupt),
    .io_deq_ready        (d_q_deq_ready),
    .io_deq_valid        (d_q_deq_valid),
    .io_deq_bits_opcode  (d_q_deq_opcode),
    .io_deq_bits_param   (d_q_deq_param),
    .io_deq_bits_size    (d_q_deq_size),
    .io_deq_bits_source  (d_q_deq_source),
    .io_deq_bits_sink    (d_q_deq_sink),
    .io_deq_bits_denied  (d_q_deq_denied),
    .io_deq_bits_data    (d_q_deq_data),
    .io_deq_bits_corrupt (d_q_deq_corrupt)
  );

endmodule
