// 自动生成：scripts/gen_fauftbway.py —— 勿手改
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
