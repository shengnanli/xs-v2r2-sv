// =============================================================================
// TLBuffer_20 —— TileLink A/D 两通道时序缓冲（xs_TLBuffer_ad_core 家族的一个变体）
//
// 本变体的规模与参数（按 G1 golden 现读，不从上一轮继承）：
//   端口 42 个；golden 模块体只有两条 Queue2 例化，本层无状态、无组合逻辑。
//   A 通道：size 2b、source 5b、address 30b、mask 8b、data 64b，
//           user 附带位 = 无。
//   D 通道：size 2b、source 5b、sink 1b、data 64b。
//   队列型号：A = Queue2_TLBundleA_10（载荷 117 位，内含 ram_2x117）
//             D = Queue2_TLBundleD_11（载荷 80 位，内含 ram_2x80）
//   两个 Queue2 是 golden 叶子，UT/FM 两侧共用同一份定义，本文件只例化不重写。
//
// 结构：golden 同名端口表 -> 设参例化 xs_TLBuffer_ad_core（核体见 xs_TLBuffer_ad_core.sv）
//   -> 核暴露的 a_q_*/d_q_* 接到上面两个队列。A 通道的 user 位是本变体特有的不透明
//   附带位，缓冲不解释它，直接从端口接到队列，不过核。
//
// G0 -> G1 的唯一改动：source 由 3 位加宽到 5 位
//   （auto_in_a / auto_in_d / auto_out_a / auto_out_d 四根 source 端口同改），
//   队列与其 ram 行为模型随之变宽（ram_2x117 / ram_2x80）；装配结构逐字未变。
//   核里的载荷宽度等式会在 elaborate 时兜住"位宽写回旧值"这类静默错误。
// 自动生成：scripts/gen_tlbuffer_ad_family.py —— 勿手改
// =============================================================================
module TLBuffer_20(
  input clock,
  input reset,
  output auto_in_a_ready,
  input auto_in_a_valid,
  input [3:0] auto_in_a_bits_opcode,
  input [2:0] auto_in_a_bits_param,
  input [1:0] auto_in_a_bits_size,
  input [4:0] auto_in_a_bits_source,
  input [29:0] auto_in_a_bits_address,
  input [7:0] auto_in_a_bits_mask,
  input [63:0] auto_in_a_bits_data,
  input auto_in_a_bits_corrupt,
  input auto_in_d_ready,
  output auto_in_d_valid,
  output [3:0] auto_in_d_bits_opcode,
  output [1:0] auto_in_d_bits_param,
  output [1:0] auto_in_d_bits_size,
  output [4:0] auto_in_d_bits_source,
  output auto_in_d_bits_sink,
  output auto_in_d_bits_denied,
  output [63:0] auto_in_d_bits_data,
  output auto_in_d_bits_corrupt,
  input auto_out_a_ready,
  output auto_out_a_valid,
  output [3:0] auto_out_a_bits_opcode,
  output [2:0] auto_out_a_bits_param,
  output [1:0] auto_out_a_bits_size,
  output [4:0] auto_out_a_bits_source,
  output [29:0] auto_out_a_bits_address,
  output [7:0] auto_out_a_bits_mask,
  output [63:0] auto_out_a_bits_data,
  output auto_out_a_bits_corrupt,
  output auto_out_d_ready,
  input auto_out_d_valid,
  input [3:0] auto_out_d_bits_opcode,
  input [1:0] auto_out_d_bits_param,
  input [1:0] auto_out_d_bits_size,
  input [4:0] auto_out_d_bits_source,
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
  wire [4:0] a_q_enq_source;
  wire [29:0] a_q_enq_address;
  wire [7:0] a_q_enq_mask;
  wire [63:0] a_q_enq_data;
  wire a_q_enq_corrupt;
  wire a_q_deq_valid;
  wire a_q_deq_ready;
  wire [3:0] a_q_deq_opcode;
  wire [2:0] a_q_deq_param;
  wire [1:0] a_q_deq_size;
  wire [4:0] a_q_deq_source;
  wire [29:0] a_q_deq_address;
  wire [7:0] a_q_deq_mask;
  wire [63:0] a_q_deq_data;
  wire a_q_deq_corrupt;
  wire d_q_enq_valid;
  wire d_q_enq_ready;
  wire [3:0] d_q_enq_opcode;
  wire [1:0] d_q_enq_param;
  wire [1:0] d_q_enq_size;
  wire [4:0] d_q_enq_source;
  wire d_q_enq_sink;
  wire d_q_enq_denied;
  wire [63:0] d_q_enq_data;
  wire d_q_enq_corrupt;
  wire d_q_deq_valid;
  wire d_q_deq_ready;
  wire [3:0] d_q_deq_opcode;
  wire [1:0] d_q_deq_param;
  wire [1:0] d_q_deq_size;
  wire [4:0] d_q_deq_source;
  wire d_q_deq_sink;
  wire d_q_deq_denied;
  wire [63:0] d_q_deq_data;
  wire d_q_deq_corrupt;

  xs_TLBuffer_ad_core #(
    .A_SIZE_W   (2),
    .D_SIZE_W   (2),
    .SOURCE_W   (5),
    .ADDR_W     (30),
    .MASK_W     (8),
    .DATA_W     (64),
    .D_SINK_W   (1),
    .A_USER_W   (0),
    .A_RAM_WIDTH(117),
    .D_RAM_WIDTH(80)
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
  Queue2_TLBundleA_10 nodeOut_a_q (
    .clock               (clock),
    .reset               (reset),
    .io_enq_ready        (a_q_enq_ready),
    .io_enq_valid        (a_q_enq_valid),
    .io_enq_bits_opcode  (a_q_enq_opcode),
    .io_enq_bits_param   (a_q_enq_param),
    .io_enq_bits_size    (a_q_enq_size),
    .io_enq_bits_source  (a_q_enq_source),
    .io_enq_bits_address (a_q_enq_address),
    .io_enq_bits_mask    (a_q_enq_mask),
    .io_enq_bits_data    (a_q_enq_data),
    .io_enq_bits_corrupt (a_q_enq_corrupt),
    .io_deq_ready        (a_q_deq_ready),
    .io_deq_valid        (a_q_deq_valid),
    .io_deq_bits_opcode  (a_q_deq_opcode),
    .io_deq_bits_param   (a_q_deq_param),
    .io_deq_bits_size    (a_q_deq_size),
    .io_deq_bits_source  (a_q_deq_source),
    .io_deq_bits_address (a_q_deq_address),
    .io_deq_bits_mask    (a_q_deq_mask),
    .io_deq_bits_data    (a_q_deq_data),
    .io_deq_bits_corrupt (a_q_deq_corrupt)
  );

  // D 通道队列：manager -> client 的应答打一拍
  Queue2_TLBundleD_11 nodeIn_d_q (
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
