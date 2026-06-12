// =============================================================================
// xs_IndexableCAM —— 可按索引写入的 CAM（内容寻址存储器）
//
// 对应 Chisel: utility.IndexableCAMTemplate（香山前端 WrBypass 用法：1 读 1 写）
// 行为：
//   - 读：组合逻辑，将查询键 io_r_req_idx 与全部条目并行比较，输出逐条目命中位图
//   - 写：时钟上升沿，io_w_valid 时把 io_w_bits_data 写入第 io_w_bits_index 项
//   - 条目寄存器不复位；上电内容未定义，需由上层（如 WrBypass 的 ever_written）
//     屏蔽从未写过的条目的假命中
// =============================================================================
module xs_IndexableCAM #(
  parameter int unsigned ENTRY_WIDTH = 9,  // 条目（查询键）位宽
  parameter int unsigned NUM_ENTRIES = 8,  // 条目数
  localparam int unsigned IDX_W = (NUM_ENTRIES > 1) ? $clog2(NUM_ENTRIES) : 1
)(
  input  logic                   clock,
  // 读口（组合查询）
  input  logic [ENTRY_WIDTH-1:0] io_r_req_idx,
  output logic [NUM_ENTRIES-1:0] io_r_resp,      // 逐条目命中位图
  // 写口（同步写入）
  input  logic                   io_w_valid,
  input  logic [ENTRY_WIDTH-1:0] io_w_bits_data,
  input  logic [IDX_W-1:0]       io_w_bits_index
);

  logic [ENTRY_WIDTH-1:0] array [NUM_ENTRIES];

  always_ff @(posedge clock) begin
    if (io_w_valid)
      array[io_w_bits_index] <= io_w_bits_data;
  end

  for (genvar i = 0; i < NUM_ENTRIES; i++) begin : g_match
    assign io_r_resp[i] = (io_r_req_idx == array[i]);
  end

endmodule
