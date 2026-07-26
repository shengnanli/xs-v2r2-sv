// SnoopUnit_xs —— UT 用变体(与 SnoopUnit_wrapper 同, 仅模块名改为 SnoopUnit_xs)
// 仅做机械端口打包/拆包, 供 FM 对比与 ST 替换。
module SnoopUnit_xs
  import xs_snoopunit_pkg::*;
(
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [11:0] io_in_bits_set,
  input  [1:0]  io_in_bits_bank,
  input  [27:0] io_in_bits_tag,
  input         io_in_bits_replSnp,
  input         io_in_bits_snpVec_0,
  input  [11:0] io_in_bits_txnID,
  input  [6:0]  io_in_bits_chiOpcode,
  input         io_in_bits_retToSrc,
  input         io_out_ready,
  output        io_out_valid,
  output [11:0] io_out_bits_set,
  output [1:0]  io_out_bits_bank,
  output [27:0] io_out_bits_tag,
  output        io_out_bits_snpVec_0,
  output [11:0] io_out_bits_txnID,
  output [10:0] io_out_bits_fwdNID,
  output [11:0] io_out_bits_fwdTxnID,
  output [6:0]  io_out_bits_chiOpcode,
  output        io_out_bits_retToSrc,
  output        io_out_bits_doNotGoToSD,
  input         io_respInfo_0_valid,
  input  [11:0] io_respInfo_0_bits_set,
  input  [27:0] io_respInfo_0_bits_tag,
  input  [6:0]  io_respInfo_0_bits_opcode,
  input  [11:0] io_respInfo_0_bits_reqID,
  input         io_respInfo_0_bits_w_compack,
  input         io_respInfo_1_valid,
  input  [11:0] io_respInfo_1_bits_set,
  input  [27:0] io_respInfo_1_bits_tag,
  input  [6:0]  io_respInfo_1_bits_opcode,
  input  [11:0] io_respInfo_1_bits_reqID,
  input         io_respInfo_1_bits_w_compack,
  input         io_respInfo_2_valid,
  input  [11:0] io_respInfo_2_bits_set,
  input  [27:0] io_respInfo_2_bits_tag,
  input  [6:0]  io_respInfo_2_bits_opcode,
  input  [11:0] io_respInfo_2_bits_reqID,
  input         io_respInfo_2_bits_w_compack,
  input         io_respInfo_3_valid,
  input  [11:0] io_respInfo_3_bits_set,
  input  [27:0] io_respInfo_3_bits_tag,
  input  [6:0]  io_respInfo_3_bits_opcode,
  input  [11:0] io_respInfo_3_bits_reqID,
  input         io_respInfo_3_bits_w_compack,
  input         io_respInfo_4_valid,
  input  [11:0] io_respInfo_4_bits_set,
  input  [27:0] io_respInfo_4_bits_tag,
  input  [6:0]  io_respInfo_4_bits_opcode,
  input  [11:0] io_respInfo_4_bits_reqID,
  input         io_respInfo_4_bits_w_compack,
  input         io_respInfo_5_valid,
  input  [11:0] io_respInfo_5_bits_set,
  input  [27:0] io_respInfo_5_bits_tag,
  input  [6:0]  io_respInfo_5_bits_opcode,
  input  [11:0] io_respInfo_5_bits_reqID,
  input         io_respInfo_5_bits_w_compack,
  input         io_respInfo_6_valid,
  input  [11:0] io_respInfo_6_bits_set,
  input  [27:0] io_respInfo_6_bits_tag,
  input  [6:0]  io_respInfo_6_bits_opcode,
  input  [11:0] io_respInfo_6_bits_reqID,
  input         io_respInfo_6_bits_w_compack,
  input         io_respInfo_7_valid,
  input  [11:0] io_respInfo_7_bits_set,
  input  [27:0] io_respInfo_7_bits_tag,
  input  [6:0]  io_respInfo_7_bits_opcode,
  input  [11:0] io_respInfo_7_bits_reqID,
  input         io_respInfo_7_bits_w_compack,
  input         io_respInfo_8_valid,
  input  [11:0] io_respInfo_8_bits_set,
  input  [27:0] io_respInfo_8_bits_tag,
  input  [6:0]  io_respInfo_8_bits_opcode,
  input  [11:0] io_respInfo_8_bits_reqID,
  input         io_respInfo_8_bits_w_compack,
  input         io_respInfo_9_valid,
  input  [11:0] io_respInfo_9_bits_set,
  input  [27:0] io_respInfo_9_bits_tag,
  input  [6:0]  io_respInfo_9_bits_opcode,
  input  [11:0] io_respInfo_9_bits_reqID,
  input         io_respInfo_9_bits_w_compack,
  input         io_respInfo_10_valid,
  input  [11:0] io_respInfo_10_bits_set,
  input  [27:0] io_respInfo_10_bits_tag,
  input  [6:0]  io_respInfo_10_bits_opcode,
  input  [11:0] io_respInfo_10_bits_reqID,
  input         io_respInfo_10_bits_w_compack,
  input         io_respInfo_11_valid,
  input  [11:0] io_respInfo_11_bits_set,
  input  [27:0] io_respInfo_11_bits_tag,
  input  [6:0]  io_respInfo_11_bits_opcode,
  input  [11:0] io_respInfo_11_bits_reqID,
  input         io_respInfo_11_bits_w_compack,
  input         io_respInfo_12_valid,
  input  [11:0] io_respInfo_12_bits_set,
  input  [27:0] io_respInfo_12_bits_tag,
  input  [6:0]  io_respInfo_12_bits_opcode,
  input  [11:0] io_respInfo_12_bits_reqID,
  input         io_respInfo_12_bits_w_compack,
  input         io_respInfo_13_valid,
  input  [11:0] io_respInfo_13_bits_set,
  input  [27:0] io_respInfo_13_bits_tag,
  input  [6:0]  io_respInfo_13_bits_opcode,
  input  [11:0] io_respInfo_13_bits_reqID,
  input         io_respInfo_13_bits_w_compack,
  input         io_respInfo_14_valid,
  input  [11:0] io_respInfo_14_bits_set,
  input  [27:0] io_respInfo_14_bits_tag,
  input  [6:0]  io_respInfo_14_bits_opcode,
  input  [11:0] io_respInfo_14_bits_reqID,
  input         io_respInfo_14_bits_w_compack,
  input         io_respInfo_15_valid,
  input  [11:0] io_respInfo_15_bits_set,
  input  [27:0] io_respInfo_15_bits_tag,
  input  [6:0]  io_respInfo_15_bits_opcode,
  input  [11:0] io_respInfo_15_bits_reqID,
  input         io_respInfo_15_bits_w_compack,
  input         io_ack_valid,
  input  [11:0] io_ack_bits_txnID,
  input  [6:0]  io_ack_bits_opcode
);

  // 入站 task 打包(只含 buffer 保存字段; doNotGoToSD 入队后由核内粘住,
  // io_in 无该端口 → 打包为 0, 与 golden 一致)
  snoop_task_t in_task;
  assign in_task = '{
    set:         io_in_bits_set,
    bank:        io_in_bits_bank,
    tag:         io_in_bits_tag,
    replSnp:     io_in_bits_replSnp,
    snpVec_0:    io_in_bits_snpVec_0,
    txnID:       io_in_bits_txnID,
    chiOpcode:   io_in_bits_chiOpcode,
    retToSrc:    io_in_bits_retToSrc,
    doNotGoToSD: 1'b0
  };

  // 16 路 respInfo 打包为数组
  resp_info_t [15:0] respArr;
  assign respArr[0]  = '{valid: io_respInfo_0_valid,  set: io_respInfo_0_bits_set,  tag: io_respInfo_0_bits_tag,  opcode: io_respInfo_0_bits_opcode,  reqID: io_respInfo_0_bits_reqID,  w_compack: io_respInfo_0_bits_w_compack};
  assign respArr[1]  = '{valid: io_respInfo_1_valid,  set: io_respInfo_1_bits_set,  tag: io_respInfo_1_bits_tag,  opcode: io_respInfo_1_bits_opcode,  reqID: io_respInfo_1_bits_reqID,  w_compack: io_respInfo_1_bits_w_compack};
  assign respArr[2]  = '{valid: io_respInfo_2_valid,  set: io_respInfo_2_bits_set,  tag: io_respInfo_2_bits_tag,  opcode: io_respInfo_2_bits_opcode,  reqID: io_respInfo_2_bits_reqID,  w_compack: io_respInfo_2_bits_w_compack};
  assign respArr[3]  = '{valid: io_respInfo_3_valid,  set: io_respInfo_3_bits_set,  tag: io_respInfo_3_bits_tag,  opcode: io_respInfo_3_bits_opcode,  reqID: io_respInfo_3_bits_reqID,  w_compack: io_respInfo_3_bits_w_compack};
  assign respArr[4]  = '{valid: io_respInfo_4_valid,  set: io_respInfo_4_bits_set,  tag: io_respInfo_4_bits_tag,  opcode: io_respInfo_4_bits_opcode,  reqID: io_respInfo_4_bits_reqID,  w_compack: io_respInfo_4_bits_w_compack};
  assign respArr[5]  = '{valid: io_respInfo_5_valid,  set: io_respInfo_5_bits_set,  tag: io_respInfo_5_bits_tag,  opcode: io_respInfo_5_bits_opcode,  reqID: io_respInfo_5_bits_reqID,  w_compack: io_respInfo_5_bits_w_compack};
  assign respArr[6]  = '{valid: io_respInfo_6_valid,  set: io_respInfo_6_bits_set,  tag: io_respInfo_6_bits_tag,  opcode: io_respInfo_6_bits_opcode,  reqID: io_respInfo_6_bits_reqID,  w_compack: io_respInfo_6_bits_w_compack};
  assign respArr[7]  = '{valid: io_respInfo_7_valid,  set: io_respInfo_7_bits_set,  tag: io_respInfo_7_bits_tag,  opcode: io_respInfo_7_bits_opcode,  reqID: io_respInfo_7_bits_reqID,  w_compack: io_respInfo_7_bits_w_compack};
  assign respArr[8]  = '{valid: io_respInfo_8_valid,  set: io_respInfo_8_bits_set,  tag: io_respInfo_8_bits_tag,  opcode: io_respInfo_8_bits_opcode,  reqID: io_respInfo_8_bits_reqID,  w_compack: io_respInfo_8_bits_w_compack};
  assign respArr[9]  = '{valid: io_respInfo_9_valid,  set: io_respInfo_9_bits_set,  tag: io_respInfo_9_bits_tag,  opcode: io_respInfo_9_bits_opcode,  reqID: io_respInfo_9_bits_reqID,  w_compack: io_respInfo_9_bits_w_compack};
  assign respArr[10] = '{valid: io_respInfo_10_valid, set: io_respInfo_10_bits_set, tag: io_respInfo_10_bits_tag, opcode: io_respInfo_10_bits_opcode, reqID: io_respInfo_10_bits_reqID, w_compack: io_respInfo_10_bits_w_compack};
  assign respArr[11] = '{valid: io_respInfo_11_valid, set: io_respInfo_11_bits_set, tag: io_respInfo_11_bits_tag, opcode: io_respInfo_11_bits_opcode, reqID: io_respInfo_11_bits_reqID, w_compack: io_respInfo_11_bits_w_compack};
  assign respArr[12] = '{valid: io_respInfo_12_valid, set: io_respInfo_12_bits_set, tag: io_respInfo_12_bits_tag, opcode: io_respInfo_12_bits_opcode, reqID: io_respInfo_12_bits_reqID, w_compack: io_respInfo_12_bits_w_compack};
  assign respArr[13] = '{valid: io_respInfo_13_valid, set: io_respInfo_13_bits_set, tag: io_respInfo_13_bits_tag, opcode: io_respInfo_13_bits_opcode, reqID: io_respInfo_13_bits_reqID, w_compack: io_respInfo_13_bits_w_compack};
  assign respArr[14] = '{valid: io_respInfo_14_valid, set: io_respInfo_14_bits_set, tag: io_respInfo_14_bits_tag, opcode: io_respInfo_14_bits_opcode, reqID: io_respInfo_14_bits_reqID, w_compack: io_respInfo_14_bits_w_compack};
  assign respArr[15] = '{valid: io_respInfo_15_valid, set: io_respInfo_15_bits_set, tag: io_respInfo_15_bits_tag, opcode: io_respInfo_15_bits_opcode, reqID: io_respInfo_15_bits_reqID, w_compack: io_respInfo_15_bits_w_compack};

  xs_SnoopUnit_core u_core (
    .clock                   (clock),
    .reset                   (reset),
    .io_in_valid             (io_in_valid),
    .io_in_task              (in_task),
    .io_out_ready            (io_out_ready),
    .io_out_valid            (io_out_valid),
    .io_out_bits_set         (io_out_bits_set),
    .io_out_bits_bank        (io_out_bits_bank),
    .io_out_bits_tag         (io_out_bits_tag),
    .io_out_bits_snpVec_0    (io_out_bits_snpVec_0),
    .io_out_bits_txnID       (io_out_bits_txnID),
    .io_out_bits_fwdNID      (io_out_bits_fwdNID),
    .io_out_bits_fwdTxnID    (io_out_bits_fwdTxnID),
    .io_out_bits_chiOpcode   (io_out_bits_chiOpcode),
    .io_out_bits_retToSrc    (io_out_bits_retToSrc),
    .io_out_bits_doNotGoToSD (io_out_bits_doNotGoToSD),
    .io_respInfo             (respArr),
    .io_ack_valid            (io_ack_valid),
    .io_ack_bits_txnID       (io_ack_bits_txnID),
    .io_ack_bits_opcode      (io_ack_bits_opcode)
  );

endmodule
