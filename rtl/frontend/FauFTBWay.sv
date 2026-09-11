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

// 自动生成：scripts/gen_fauftbway.py —— 勿手改

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module FauFTBWay(
  input  clock,
  input  reset,
  input  [15:0] io_req_tag,
  output io_resp_isCall,
  output io_resp_isRet,
  output io_resp_isJalr,
  output io_resp_valid,
  output [3:0] io_resp_brSlots_0_offset,
  output io_resp_brSlots_0_sharing,
  output io_resp_brSlots_0_valid,
  output [11:0] io_resp_brSlots_0_lower,
  output [1:0] io_resp_brSlots_0_tarStat,
  output [3:0] io_resp_tailSlot_offset,
  output io_resp_tailSlot_sharing,
  output io_resp_tailSlot_valid,
  output [19:0] io_resp_tailSlot_lower,
  output [1:0] io_resp_tailSlot_tarStat,
  output [3:0] io_resp_pftAddr,
  output io_resp_carry,
  output io_resp_last_may_be_rvi_call,
  output io_resp_strong_bias_0,
  output io_resp_strong_bias_1,
  output io_resp_hit,
  input  [15:0] io_update_req_tag,
  output io_update_hit,
  input  io_write_valid,
  input  io_write_entry_isCall,
  input  io_write_entry_isRet,
  input  io_write_entry_isJalr,
  input  io_write_entry_valid,
  input  [3:0] io_write_entry_brSlots_0_offset,
  input  io_write_entry_brSlots_0_sharing,
  input  io_write_entry_brSlots_0_valid,
  input  [11:0] io_write_entry_brSlots_0_lower,
  input  [1:0] io_write_entry_brSlots_0_tarStat,
  input  [3:0] io_write_entry_tailSlot_offset,
  input  io_write_entry_tailSlot_sharing,
  input  io_write_entry_tailSlot_valid,
  input  [19:0] io_write_entry_tailSlot_lower,
  input  [1:0] io_write_entry_tailSlot_tarStat,
  input  [3:0] io_write_entry_pftAddr,
  input  io_write_entry_carry,
  input  io_write_entry_last_may_be_rvi_call,
  input  io_write_entry_strong_bias_0,
  input  io_write_entry_strong_bias_1,
  input  [15:0] io_write_tag
);
  wire [59:0] resp_packed;
  assign io_resp_isCall = resp_packed[0:0];
  assign io_resp_isRet = resp_packed[1:1];
  assign io_resp_isJalr = resp_packed[2:2];
  assign io_resp_valid = resp_packed[3:3];
  assign io_resp_brSlots_0_offset = resp_packed[7:4];
  assign io_resp_brSlots_0_sharing = resp_packed[8:8];
  assign io_resp_brSlots_0_valid = resp_packed[9:9];
  assign io_resp_brSlots_0_lower = resp_packed[21:10];
  assign io_resp_brSlots_0_tarStat = resp_packed[23:22];
  assign io_resp_tailSlot_offset = resp_packed[27:24];
  assign io_resp_tailSlot_sharing = resp_packed[28:28];
  assign io_resp_tailSlot_valid = resp_packed[29:29];
  assign io_resp_tailSlot_lower = resp_packed[49:30];
  assign io_resp_tailSlot_tarStat = resp_packed[51:50];
  assign io_resp_pftAddr = resp_packed[55:52];
  assign io_resp_carry = resp_packed[56:56];
  assign io_resp_last_may_be_rvi_call = resp_packed[57:57];
  assign io_resp_strong_bias_0 = resp_packed[58:58];
  assign io_resp_strong_bias_1 = resp_packed[59:59];
  xs_FauFTBWay #(.TAG_W(16), .ENTRY_W(60)) u_core (
    .clock(clock), .reset(reset),
    .io_req_tag(io_req_tag), .io_resp(resp_packed), .io_resp_hit(io_resp_hit),
    .io_update_req_tag(io_update_req_tag), .io_update_hit(io_update_hit),
    .io_write_valid(io_write_valid),
    .io_write_entry({io_write_entry_strong_bias_1, io_write_entry_strong_bias_0, io_write_entry_last_may_be_rvi_call, io_write_entry_carry, io_write_entry_pftAddr, io_write_entry_tailSlot_tarStat, io_write_entry_tailSlot_lower, io_write_entry_tailSlot_valid, io_write_entry_tailSlot_sharing, io_write_entry_tailSlot_offset, io_write_entry_brSlots_0_tarStat, io_write_entry_brSlots_0_lower, io_write_entry_brSlots_0_valid, io_write_entry_brSlots_0_sharing, io_write_entry_brSlots_0_offset, io_write_entry_valid, io_write_entry_isJalr, io_write_entry_isRet, io_write_entry_isCall}),
    .io_write_tag(io_write_tag)
  );
endmodule
