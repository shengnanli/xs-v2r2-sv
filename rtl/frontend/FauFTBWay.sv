// =============================================================================
// xs_FauFTBWay —— uFTB（Fault/Fast FTB）单路
//
// 对应 Chisel: xiangshan.frontend.FauFTBWay
// 全相联微 FTB 的一路：寄存一个 FTB 条目(data) + tag + valid。
//   - 读：tag 匹配且 valid → resp_hit；resp = 存储的条目（原样透出）
//   - 更新查询：update_hit = (tag命中且valid) | (本拍写同tag)  —— 写旁路避免重复命中
//   - 写：write_valid 时写入 tag/entry，置 valid
// entry 作为不透明打包数据(ENTRY_W 位)整体存取，字段拼接由外层 wrapper 处理。
// =============================================================================
module xs_FauFTBWay #(
  parameter int unsigned TAG_W   = 16,
  parameter int unsigned ENTRY_W = 1
)(
  input  logic                clock,
  input  logic                reset,
  input  logic [TAG_W-1:0]    io_req_tag,
  output logic [ENTRY_W-1:0]  io_resp,
  output logic                io_resp_hit,
  input  logic [TAG_W-1:0]    io_update_req_tag,
  output logic                io_update_hit,
  input  logic                io_write_valid,
  input  logic [ENTRY_W-1:0]  io_write_entry,
  input  logic [TAG_W-1:0]    io_write_tag
);

  logic [ENTRY_W-1:0] data;
  logic [TAG_W-1:0]   tag;
  logic               valid;

  assign io_resp     = data;
  assign io_resp_hit = (tag == io_req_tag) && valid;
  // 写旁路：本拍写入的 tag 也算更新命中，避免与已存条目产生多重命中
  assign io_update_hit = ((tag == io_update_req_tag) && valid) ||
                         ((io_write_tag == io_update_req_tag) && io_write_valid);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) valid <= 1'b0;
    else if (io_write_valid) valid <= 1'b1;
  end

  always_ff @(posedge clock) begin
    if (io_write_valid) begin
      tag  <= io_write_tag;
      data <= io_write_entry;
    end
  end

endmodule
