// =============================================================================
// IndexableCAMTemplate —— 可按索引写入的 CAM（内容寻址存储器）
//
// 对应 Chisel: utility.IndexableCAMTemplate。香山前端 WrBypass 用它保存
// "最近写过哪些 SRAM 索引"：查询键与全部条目并行比较得到命中位图。
// 行为：
//   - 读：组合逻辑，查询键 r_key 与全部条目并行比较，输出逐条目命中位图；
//   - 写：时钟上升沿，w_valid 时把 w_key 写入第 w_index 项；
//   - 条目寄存器不复位；上电内容未定义，需由上层（如 WrBypass 的 ever_written）
//     屏蔽从未写过的条目的假命中。
//
// 本文件 = 参数化可读核 + golden 同名 wrapper（基础变体 8 项 × 9b 键）。
// 其余单态化变体（IndexableCAMTemplate_32/_33/_41/_43）各自一个薄 wrapper 文件。
// =============================================================================

module xs_IndexableCAMTemplate_core #(
  parameter int unsigned ENTRY_WIDTH = 9,  // 条目（查询键）位宽
  parameter int unsigned NUM_ENTRIES = 8,  // 条目数
  localparam int unsigned IDX_W = (NUM_ENTRIES > 1) ? $clog2(NUM_ENTRIES) : 1
)(
  input  logic                   clock,
  // 读口（组合查询）
  input  logic [ENTRY_WIDTH-1:0] r_key,
  output logic [NUM_ENTRIES-1:0] r_match,   // 逐条目命中位图
  // 写口（同步写入）
  input  logic                   w_valid,
  input  logic [ENTRY_WIDTH-1:0] w_key,
  input  logic [IDX_W-1:0]       w_index
);

  logic [ENTRY_WIDTH-1:0] array [NUM_ENTRIES];

  always_ff @(posedge clock) begin
    if (w_valid)
      array[w_index] <= w_key;
  end

  for (genvar i = 0; i < NUM_ENTRIES; i++) begin : g_match
    assign r_match[i] = (r_key == array[i]);
  end

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：基础变体（WrBypass 使用，8 项 × 9b 键，1 读口）
// ---------------------------------------------------------------------------
module IndexableCAMTemplate(
  input        clock,
  input  [8:0] io_r_req_0_idx,
  output       io_r_resp_0_0,
  output       io_r_resp_0_1,
  output       io_r_resp_0_2,
  output       io_r_resp_0_3,
  output       io_r_resp_0_4,
  output       io_r_resp_0_5,
  output       io_r_resp_0_6,
  output       io_r_resp_0_7,
  input        io_w_valid,
  input  [8:0] io_w_bits_data_idx,
  input  [2:0] io_w_bits_index
);

  logic [7:0] match;

  xs_IndexableCAMTemplate_core #(
    .ENTRY_WIDTH(9), .NUM_ENTRIES(8)
  ) u_core (
    .clock  (clock),
    .r_key  (io_r_req_0_idx),
    .r_match(match),
    .w_valid(io_w_valid),
    .w_key  (io_w_bits_data_idx),
    .w_index(io_w_bits_index)
  );

  assign {io_r_resp_0_7, io_r_resp_0_6, io_r_resp_0_5, io_r_resp_0_4,
          io_r_resp_0_3, io_r_resp_0_2, io_r_resp_0_1, io_r_resp_0_0} = match;

endmodule
