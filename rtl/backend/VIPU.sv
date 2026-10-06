// =============================================================================
// VIPU.sv — 向量整数置换类执行单元外壳。
//
// 本模块位于后端向量 FU 入口，负责将 FU opcode 解码并送入 VIAlu，
// 同时维护 golden 中的两级 valid/ready 状态和性能调试信息流水。
// 控制字段按 golden 直接旁路；结果数据由 VIAlu 自身流水产生。
// =============================================================================
module xs_VIPU_core (
  input  logic clock,
  input  logic reset,

  output logic in_ready,
  input  logic in_valid,

  input  logic [8:0] ctrl_fu_op_type,
  input  logic ctrl_vpu_vma,
  input  logic ctrl_vpu_vta,
  input  logic [1:0] ctrl_vpu_vsew,
  input  logic [2:0] ctrl_vpu_vlmul,
  input  logic ctrl_vpu_vm,
  input logic [7:0] ctrl_vpu_vstart,
  input logic [6:0] ctrl_vpu_vuop_idx,

  input  logic ctrl_pipe_2_rob_idx_flag,
  input  logic [7:0] ctrl_pipe_2_rob_idx_value,
  input logic [7:0] ctrl_pipe_2_pdest,
  input logic ctrl_pipe_2_rf_wen,
  input logic ctrl_pipe_2_vec_wen,
  input logic ctrl_pipe_2_v0_wen,
  input logic [7:0] ctrl_pipe_2_vpu_vstart,
  input logic valid_pipe_2,

  input  logic [7:0] data_src_4,
  input logic [127:0] data_src_3,
  input logic [127:0] data_src_2,
  input logic [127:0] data_src_1,
  input logic [127:0] data_src_0,

  input logic perf_in_eliminated_move,
  input logic [63:0] perf_in_rename_time,
  input logic [63:0] perf_in_dispatch_time,
  input logic [63:0] perf_in_enq_rs_time,
  input logic [63:0] perf_in_select_time,
  input logic [63:0] perf_in_issue_time,
  input logic [63:0] perf_in_writeback_time,
  input logic [63:0] perf_in_runahead_checkpoint_id,
  input logic [63:0] perf_in_tlb_first_req_time,
  input logic [63:0] perf_in_tlb_resp_time,
  input logic [55:0] debug_in_seq_num,
  input logic [7:0] debug_in_uop_idx,

  input logic out_ready,

  output logic out_valid,
  output logic out_rob_idx_flag,
  output logic [7:0] out_rob_idx_value,
  output logic [7:0] out_pdest,
  output logic out_rf_wen,
  output logic out_vec_wen,
  output logic out_v0_wen,
  output logic out_exception_vec_2,
  output logic [127:0] out_res_data,

  output logic perf_out_eliminated_move,
  output logic [63:0] perf_out_rename_time,
  output logic [63:0] perf_out_dispatch_time,
  output logic [63:0] perf_out_enq_rs_time,
  output logic [63:0] perf_out_select_time,
  output logic [63:0] perf_out_issue_time,
  output logic [63:0] perf_out_writeback_time,
  output logic [63:0] perf_out_runahead_checkpoint_id,
  output logic [63:0] perf_out_tlb_first_req_time,
  output logic [63:0] perf_out_tlb_resp_time,
  output logic [55:0] debug_out_seq_num,
  output logic [7:0] debug_out_uop_idx
);

  logic valid_stage_1;
  logic valid_stage_2;
  logic ready_stage_1;
  logic ready_stage_0;

  assign ready_stage_1 = ~valid_stage_2 | out_ready;
  assign ready_stage_0 = ~valid_stage_1 | ready_stage_1;
  assign in_ready = ready_stage_0;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      valid_stage_1 <= 1'b0;
      valid_stage_2 <= 1'b0;
    end else begin
      valid_stage_1 <= in_valid;
      valid_stage_2 <= valid_stage_1;
    end
  end

  logic perf_stage_1_eliminated_move;
  logic [63:0] perf_stage_1_rename_time;
  logic [63:0] perf_stage_1_dispatch_time;
  logic [63:0] perf_stage_1_enq_rs_time;
  logic [63:0] perf_stage_1_select_time;
  logic [63:0] perf_stage_1_issue_time;
  logic [63:0] perf_stage_1_writeback_time;
  logic [63:0] perf_stage_1_runahead_checkpoint_id;
  logic [63:0] perf_stage_1_tlb_first_req_time;
  logic [63:0] perf_stage_1_tlb_resp_time;
  logic [55:0] debug_stage_1_seq_num;
  logic [7:0] perf_stage_1_uop_idx;

  logic perf_stage_2_eliminated_move;
  logic [63:0] perf_stage_2_rename_time;
  logic [63:0] perf_stage_2_dispatch_time;
  logic [63:0] perf_stage_2_enq_rs_time;
  logic [63:0] perf_stage_2_select_time;
  logic [63:0] perf_stage_2_issue_time;
  logic [63:0] perf_stage_2_writeback_time;
  logic [63:0] perf_stage_2_runahead_checkpoint_id;
  logic [63:0] perf_stage_2_tlb_first_req_time;
  logic [63:0] perf_stage_2_tlb_resp_time;
  logic [55:0] debug_stage_2_seq_num;
  logic [7:0] perf_stage_2_uop_idx;

  always_ff @(posedge clock) begin
    if (ready_stage_0 & in_valid) begin
      perf_stage_1_eliminated_move <= perf_in_eliminated_move;
      perf_stage_1_rename_time <= perf_in_rename_time;
      perf_stage_1_dispatch_time <= perf_in_dispatch_time;
      perf_stage_1_enq_rs_time <= perf_in_enq_rs_time;
      perf_stage_1_select_time <= perf_in_select_time;
      perf_stage_1_issue_time <= perf_in_issue_time;
      perf_stage_1_writeback_time <= perf_in_writeback_time;
      perf_stage_1_runahead_checkpoint_id <= perf_in_runahead_checkpoint_id;
      perf_stage_1_tlb_first_req_time <= perf_in_tlb_first_req_time;
      perf_stage_1_tlb_resp_time <= perf_in_tlb_resp_time;
      debug_stage_1_seq_num <= debug_in_seq_num;
      perf_stage_1_uop_idx <= debug_in_uop_idx;
    end

    if (ready_stage_1 & valid_stage_1) begin
      perf_stage_2_eliminated_move <= perf_stage_1_eliminated_move;
      perf_stage_2_rename_time <= perf_stage_1_rename_time;
      perf_stage_2_dispatch_time <= perf_stage_1_dispatch_time;
      perf_stage_2_enq_rs_time <= perf_stage_1_enq_rs_time;
      perf_stage_2_select_time <= perf_stage_1_select_time;
      perf_stage_2_issue_time <= perf_stage_1_issue_time;
      perf_stage_2_writeback_time <= perf_stage_1_writeback_time;
      perf_stage_2_runahead_checkpoint_id <= perf_stage_1_runahead_checkpoint_id;
      perf_stage_2_tlb_first_req_time <= perf_stage_1_tlb_first_req_time;
      perf_stage_2_tlb_resp_time <= perf_stage_1_tlb_resp_time;
      debug_stage_2_seq_num <= debug_stage_1_seq_num;
      perf_stage_2_uop_idx <= perf_stage_1_uop_idx;
    end
  end

  logic [5:0] decoder_opcode;
  logic [2:0] decoder_src_type_2;
  logic [2:0] decoder_vd_type;
  logic [3:0] decoded_src_type;
  logic [3:0] decoded_vd_type;
  logic [1:0] src_type_sew_sum;
  logic [1:0] vd_type_sew_sum;

  VIAluDecoder decoder (
    .io_in_fuOpType  (ctrl_fu_op_type[7:0]),
    .io_out_opcode   (decoder_opcode),
    .io_out_srcType2 (decoder_src_type_2),
    .io_out_vdType   (decoder_vd_type)
  );

  assign src_type_sew_sum = ctrl_vpu_vsew + {1'b0, decoder_src_type_2[0]};
  assign vd_type_sew_sum = ctrl_vpu_vsew + {1'b0, decoder_vd_type[0]};

  assign decoded_src_type = {
    decoder_src_type_2[2],
    decoder_src_type_2[1] | decoder_src_type_2[2],
    {2{decoder_src_type_2[2]}} | src_type_sew_sum
  };

  assign decoded_vd_type = {
    decoder_vd_type[2],
    decoder_vd_type[1] | decoder_vd_type[2],
    {2{decoder_vd_type[2]}} | vd_type_sew_sum
  };

  logic [3:0] vlmul_shift_limit;
  logic need_shift_vs1;
  logic clear_vs1_for_special_op;
  logic [127:0] vi_alu_vs1;
  logic [127:0] vi_alu_mask;

  always_comb begin
    case (ctrl_vpu_vlmul)
      3'h3: vlmul_shift_limit = 4'h8;
      3'h2: vlmul_shift_limit = 4'h4;
      3'h1: vlmul_shift_limit = 4'h2;
      default: vlmul_shift_limit = 4'h1;
    endcase
  end

  assign need_shift_vs1 =
      ((ctrl_fu_op_type == 9'h41) | (ctrl_fu_op_type == 9'h42))
      & (ctrl_vpu_vuop_idx < {3'h0, vlmul_shift_limit});

  assign clear_vs1_for_special_op =
      ((ctrl_fu_op_type == 9'h4B) & (ctrl_vpu_vuop_idx == 7'h00))
      | ((ctrl_fu_op_type == 9'h50) & ~(|ctrl_vpu_vuop_idx[6:1]))
      | ((ctrl_fu_op_type == 9'h51) & ~(|ctrl_vpu_vuop_idx[6:1]))
      | need_shift_vs1;

  assign vi_alu_vs1 =
      (need_shift_vs1 ? {64'h0, data_src_0[127:64]} : 128'h0)
      | (clear_vs1_for_special_op ? 128'h0 : data_src_0);

  assign vi_alu_mask =
      ctrl_vpu_vm ? 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF : data_src_3;

  VIAlu vialu (
    .clock                  (clock),
    .reset                  (reset),
    .io_in_valid            (in_valid),
    .io_in_bits_opcode_op   (decoder_opcode),
    .io_in_bits_info_vm     (ctrl_vpu_vm),
    .io_in_bits_info_ma     (ctrl_vpu_vma),
    .io_in_bits_info_ta     (ctrl_vpu_vta),
    .io_in_bits_info_vlmul  (ctrl_vpu_vlmul),
    .io_in_bits_info_vl     (data_src_4),
    .io_in_bits_info_vstart (ctrl_vpu_vstart[6:0]),
    .io_in_bits_info_uopIdx (ctrl_vpu_vuop_idx[5:0]),
    .io_in_bits_srcType_0   (decoded_src_type),
    .io_in_bits_vdType      (decoded_vd_type),
    .io_in_bits_vs1         (vi_alu_vs1),
    .io_in_bits_vs2         (data_src_1),
    .io_in_bits_old_vd      (data_src_2),
    .io_in_bits_mask        (vi_alu_mask),
    .io_out_bits_vd         (out_res_data)
  );

  assign out_valid = valid_pipe_2 & valid_stage_2;
  assign out_rob_idx_flag = ctrl_pipe_2_rob_idx_flag;
  assign out_rob_idx_value = ctrl_pipe_2_rob_idx_value;
  assign out_pdest = ctrl_pipe_2_pdest;
  assign out_rf_wen = ctrl_pipe_2_rf_wen;
  assign out_vec_wen = ctrl_pipe_2_vec_wen;
  assign out_v0_wen = ctrl_pipe_2_v0_wen;
  assign out_exception_vec_2 = |ctrl_pipe_2_vpu_vstart;

  assign perf_out_eliminated_move = perf_stage_2_eliminated_move;
  assign perf_out_rename_time = perf_stage_2_rename_time;
  assign perf_out_dispatch_time = perf_stage_2_dispatch_time;
  assign perf_out_enq_rs_time = perf_stage_2_enq_rs_time;
  assign perf_out_select_time = perf_stage_2_select_time;
  assign perf_out_issue_time = perf_stage_2_issue_time;
  assign perf_out_writeback_time = perf_stage_2_writeback_time;
  assign perf_out_runahead_checkpoint_id = perf_stage_2_runahead_checkpoint_id;
  assign perf_out_tlb_first_req_time = perf_stage_2_tlb_first_req_time;
  assign perf_out_tlb_resp_time = perf_stage_2_tlb_resp_time;
  assign debug_out_seq_num = debug_stage_2_seq_num;
  assign debug_out_uop_idx = perf_stage_2_uop_idx;

endmodule

module VIPU (
  input clock,
  input reset,
  output io_in_ready,
  input io_in_valid,
  input [8:0] io_in_bits_ctrl_fuOpType,
  input io_in_bits_ctrl_vpu_vma,
  input io_in_bits_ctrl_vpu_vta,
  input [1:0] io_in_bits_ctrl_vpu_vsew,
  input [2:0] io_in_bits_ctrl_vpu_vlmul,
  input io_in_bits_ctrl_vpu_vm,
  input [7:0] io_in_bits_ctrl_vpu_vstart,
  input [6:0] io_in_bits_ctrl_vpu_vuopIdx,
  input io_in_bits_ctrlPipe_2_robIdx_flag,
  input [7:0] io_in_bits_ctrlPipe_2_robIdx_value,
  input [7:0] io_in_bits_ctrlPipe_2_pdest,
  input io_in_bits_ctrlPipe_2_rfWen,
  input io_in_bits_ctrlPipe_2_vecWen,
  input io_in_bits_ctrlPipe_2_v0Wen,
  input [7:0] io_in_bits_ctrlPipe_2_vpu_vstart,
  input io_in_bits_validPipe_2,
  input [7:0] io_in_bits_data_src_4,
  input [127:0] io_in_bits_data_src_3,
  input [127:0] io_in_bits_data_src_2,
  input [127:0] io_in_bits_data_src_1,
  input [127:0] io_in_bits_data_src_0,
  input io_in_bits_perfDebugInfo_eliminatedMove,
  input [63:0] io_in_bits_perfDebugInfo_renameTime,
  input [63:0] io_in_bits_perfDebugInfo_dispatchTime,
  input [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input [63:0] io_in_bits_perfDebugInfo_selectTime,
  input [63:0] io_in_bits_perfDebugInfo_issueTime,
  input [63:0] io_in_bits_perfDebugInfo_writebackTime,
  input [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input [63:0] io_in_bits_perfDebugInfo_tlbRespTime,
  input [55:0] io_in_bits_debug_seqNum_seqNum,
  input [7:0] io_in_bits_debug_seqNum_uopIdx,
  input io_out_ready,
  output io_out_valid,
  output io_out_bits_ctrl_robIdx_flag,
  output [7:0] io_out_bits_ctrl_robIdx_value,
  output [7:0] io_out_bits_ctrl_pdest,
  output io_out_bits_ctrl_rfWen,
  output io_out_bits_ctrl_vecWen,
  output io_out_bits_ctrl_v0Wen,
  output io_out_bits_ctrl_exceptionVec_2,
  output [127:0] io_out_bits_res_data,
  output io_out_bits_perfDebugInfo_eliminatedMove,
  output [63:0] io_out_bits_perfDebugInfo_renameTime,
  output [63:0] io_out_bits_perfDebugInfo_dispatchTime,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  output [63:0] io_out_bits_perfDebugInfo_writebackTime,
  output [63:0] io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0] io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0] io_out_bits_perfDebugInfo_tlbRespTime,
  output [55:0] io_out_bits_debug_seqNum_seqNum,
  output [7:0] io_out_bits_debug_seqNum_uopIdx
);

  xs_VIPU_core u_core (
    .clock(clock),
    .reset(reset),
    .in_ready(io_in_ready),
    .in_valid(io_in_valid),
    .ctrl_fu_op_type(io_in_bits_ctrl_fuOpType),
    .ctrl_vpu_vma(io_in_bits_ctrl_vpu_vma),
    .ctrl_vpu_vta(io_in_bits_ctrl_vpu_vta),
    .ctrl_vpu_vsew(io_in_bits_ctrl_vpu_vsew),
    .ctrl_vpu_vlmul(io_in_bits_ctrl_vpu_vlmul),
    .ctrl_vpu_vm(io_in_bits_ctrl_vpu_vm),
    .ctrl_vpu_vstart(io_in_bits_ctrl_vpu_vstart),
    .ctrl_vpu_vuop_idx(io_in_bits_ctrl_vpu_vuopIdx),
    .ctrl_pipe_2_rob_idx_flag(io_in_bits_ctrlPipe_2_robIdx_flag),
    .ctrl_pipe_2_rob_idx_value(io_in_bits_ctrlPipe_2_robIdx_value),
    .ctrl_pipe_2_pdest(io_in_bits_ctrlPipe_2_pdest),
    .ctrl_pipe_2_rf_wen(io_in_bits_ctrlPipe_2_rfWen),
    .ctrl_pipe_2_vec_wen(io_in_bits_ctrlPipe_2_vecWen),
    .ctrl_pipe_2_v0_wen(io_in_bits_ctrlPipe_2_v0Wen),
    .ctrl_pipe_2_vpu_vstart(io_in_bits_ctrlPipe_2_vpu_vstart),
    .valid_pipe_2(io_in_bits_validPipe_2),
    .data_src_4(io_in_bits_data_src_4),
    .data_src_3(io_in_bits_data_src_3),
    .data_src_2(io_in_bits_data_src_2),
    .data_src_1(io_in_bits_data_src_1),
    .data_src_0(io_in_bits_data_src_0),
    .perf_in_eliminated_move(io_in_bits_perfDebugInfo_eliminatedMove),
    .perf_in_rename_time(io_in_bits_perfDebugInfo_renameTime),
    .perf_in_dispatch_time(io_in_bits_perfDebugInfo_dispatchTime),
    .perf_in_enq_rs_time(io_in_bits_perfDebugInfo_enqRsTime),
    .perf_in_select_time(io_in_bits_perfDebugInfo_selectTime),
    .perf_in_issue_time(io_in_bits_perfDebugInfo_issueTime),
    .perf_in_writeback_time(io_in_bits_perfDebugInfo_writebackTime),
    .perf_in_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .perf_in_tlb_first_req_time(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .perf_in_tlb_resp_time(io_in_bits_perfDebugInfo_tlbRespTime),
    .debug_in_seq_num(io_in_bits_debug_seqNum_seqNum),
    .debug_in_uop_idx(io_in_bits_debug_seqNum_uopIdx),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_rob_idx_flag(io_out_bits_ctrl_robIdx_flag),
    .out_rob_idx_value(io_out_bits_ctrl_robIdx_value),
    .out_pdest(io_out_bits_ctrl_pdest),
    .out_rf_wen(io_out_bits_ctrl_rfWen),
    .out_vec_wen(io_out_bits_ctrl_vecWen),
    .out_v0_wen(io_out_bits_ctrl_v0Wen),
    .out_exception_vec_2(io_out_bits_ctrl_exceptionVec_2),
    .out_res_data(io_out_bits_res_data),
    .perf_out_eliminated_move(io_out_bits_perfDebugInfo_eliminatedMove),
    .perf_out_rename_time(io_out_bits_perfDebugInfo_renameTime),
    .perf_out_dispatch_time(io_out_bits_perfDebugInfo_dispatchTime),
    .perf_out_enq_rs_time(io_out_bits_perfDebugInfo_enqRsTime),
    .perf_out_select_time(io_out_bits_perfDebugInfo_selectTime),
    .perf_out_issue_time(io_out_bits_perfDebugInfo_issueTime),
    .perf_out_writeback_time(io_out_bits_perfDebugInfo_writebackTime),
    .perf_out_runahead_checkpoint_id(io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .perf_out_tlb_first_req_time(io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .perf_out_tlb_resp_time(io_out_bits_perfDebugInfo_tlbRespTime),
    .debug_out_seq_num(io_out_bits_debug_seqNum_seqNum),
    .debug_out_uop_idx(io_out_bits_debug_seqNum_uopIdx)
  );

endmodule
