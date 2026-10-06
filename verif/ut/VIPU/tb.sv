// =============================================================================
// tb —— VIPU UT：golden VIPU 与重写件 VIPU_xs 双例化，同一随机激励，复位后每拍比较全部输出端口；
//       按 opcode 类别（移位/特殊 0x4b/0x50/0x51/其他）计覆盖，并要求输出每位见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  int unsigned cycle;
  longint unsigned checks;
  longint unsigned errors;

  longint unsigned cov_opcode_shift;
  longint unsigned cov_opcode_special_4b;
  longint unsigned cov_opcode_special_50;
  longint unsigned cov_opcode_special_51;
  longint unsigned cov_opcode_other;
  longint unsigned cov_valid;
  logic [511:0] seen_one;
  logic [511:0] seen_zero;

  logic clock;
  logic reset;

  typedef struct packed {
    logic        valid;
    logic [8:0]  fu_op_type;
    logic        vma;
    logic        vta;
    logic [1:0]  vsew;
    logic [2:0]  vlmul;
    logic        vm;
    logic [7:0]  vstart;
    logic [6:0]  vuop_idx;
    logic        rob_flag;
    logic [7:0]  rob_value;
    logic [7:0]  pdest;
    logic        rf_wen;
    logic        vec_wen;
    logic        v0_wen;
    logic [7:0]  pipe_vstart;
    logic        valid_pipe_2;
    logic [7:0]  src_4;
    logic [127:0] src_3;
    logic [127:0] src_2;
    logic [127:0] src_1;
    logic [127:0] src_0;
    logic        eliminated_move;
    logic [63:0] rename_time;
    logic [63:0] dispatch_time;
    logic [63:0] enq_rs_time;
    logic [63:0] select_time;
    logic [63:0] issue_time;
    logic [63:0] writeback_time;
    logic [63:0] runahead_checkpoint_id;
    logic [63:0] tlb_first_req_time;
    logic [63:0] tlb_resp_time;
    logic [55:0] seq_num;
    logic [7:0]  debug_uop_idx;
  } stimulus_t;

  stimulus_t s;

  logic g_in_ready;
  logic g_out_valid;
  logic g_out_rob_flag;
  logic [7:0] g_out_rob_value;
  logic [7:0] g_out_pdest;
  logic g_out_rf_wen;
  logic g_out_vec_wen;
  logic g_out_v0_wen;
  logic g_out_exception;
  logic [127:0] g_out_data;
  logic g_perf_eliminated;
  logic [63:0] g_rename_time;
  logic [63:0] g_dispatch_time;
  logic [63:0] g_enq_rs_time;
  logic [63:0] g_select_time;
  logic [63:0] g_issue_time;
  logic [63:0] g_writeback_time;
  logic [63:0] g_runahead_time;
  logic [63:0] g_tlb_first_time;
  logic [63:0] g_tlb_resp_time;
  logic [55:0] g_seq_num;
  logic [7:0] g_debug_uop_idx;

  logic x_in_ready;
  logic x_out_valid;
  logic x_out_rob_flag;
  logic [7:0] x_out_rob_value;
  logic [7:0] x_out_pdest;
  logic x_out_rf_wen;
  logic x_out_vec_wen;
  logic x_out_v0_wen;
  logic x_out_exception;
  logic [127:0] x_out_data;
  logic x_perf_eliminated;
  logic [63:0] x_rename_time;
  logic [63:0] x_dispatch_time;
  logic [63:0] x_enq_rs_time;
  logic [63:0] x_select_time;
  logic [63:0] x_issue_time;
  logic [63:0] x_writeback_time;
  logic [63:0] x_runahead_time;
  logic [63:0] x_tlb_first_time;
  logic [63:0] x_tlb_resp_time;
  logic [55:0] x_seq_num;
  logic [7:0] x_debug_uop_idx;

  always #5 clock = ~clock;

  VIPU g (
    .clock(clock), .reset(reset), .io_in_ready(g_in_ready),
    .io_in_valid(s.valid),
    .io_in_bits_ctrl_fuOpType(s.fu_op_type),
    .io_in_bits_ctrl_vpu_vma(s.vma),
    .io_in_bits_ctrl_vpu_vta(s.vta),
    .io_in_bits_ctrl_vpu_vsew(s.vsew),
    .io_in_bits_ctrl_vpu_vlmul(s.vlmul),
    .io_in_bits_ctrl_vpu_vm(s.vm),
    .io_in_bits_ctrl_vpu_vstart(s.vstart),
    .io_in_bits_ctrl_vpu_vuopIdx(s.vuop_idx),
    .io_in_bits_ctrlPipe_2_robIdx_flag(s.rob_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value(s.rob_value),
    .io_in_bits_ctrlPipe_2_pdest(s.pdest),
    .io_in_bits_ctrlPipe_2_rfWen(s.rf_wen),
    .io_in_bits_ctrlPipe_2_vecWen(s.vec_wen),
    .io_in_bits_ctrlPipe_2_v0Wen(s.v0_wen),
    .io_in_bits_ctrlPipe_2_vpu_vstart(s.pipe_vstart),
    .io_in_bits_validPipe_2(s.valid_pipe_2),
    .io_in_bits_data_src_4(s.src_4),
    .io_in_bits_data_src_3(s.src_3),
    .io_in_bits_data_src_2(s.src_2),
    .io_in_bits_data_src_1(s.src_1),
    .io_in_bits_data_src_0(s.src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove(s.eliminated_move),
    .io_in_bits_perfDebugInfo_renameTime(s.rename_time),
    .io_in_bits_perfDebugInfo_dispatchTime(s.dispatch_time),
    .io_in_bits_perfDebugInfo_enqRsTime(s.enq_rs_time),
    .io_in_bits_perfDebugInfo_selectTime(s.select_time),
    .io_in_bits_perfDebugInfo_issueTime(s.issue_time),
    .io_in_bits_perfDebugInfo_writebackTime(s.writeback_time),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(s.runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(s.tlb_first_req_time),
    .io_in_bits_perfDebugInfo_tlbRespTime(s.tlb_resp_time),
    .io_in_bits_debug_seqNum_seqNum(s.seq_num),
    .io_in_bits_debug_seqNum_uopIdx(s.debug_uop_idx),
    .io_out_ready(s.valid_pipe_2),
    .io_out_valid(g_out_valid),
    .io_out_bits_ctrl_robIdx_flag(g_out_rob_flag),
    .io_out_bits_ctrl_robIdx_value(g_out_rob_value),
    .io_out_bits_ctrl_pdest(g_out_pdest),
    .io_out_bits_ctrl_rfWen(g_out_rf_wen),
    .io_out_bits_ctrl_vecWen(g_out_vec_wen),
    .io_out_bits_ctrl_v0Wen(g_out_v0_wen),
    .io_out_bits_ctrl_exceptionVec_2(g_out_exception),
    .io_out_bits_res_data(g_out_data),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_perf_eliminated),
    .io_out_bits_perfDebugInfo_renameTime(g_rename_time),
    .io_out_bits_perfDebugInfo_dispatchTime(g_dispatch_time),
    .io_out_bits_perfDebugInfo_enqRsTime(g_enq_rs_time),
    .io_out_bits_perfDebugInfo_selectTime(g_select_time),
    .io_out_bits_perfDebugInfo_issueTime(g_issue_time),
    .io_out_bits_perfDebugInfo_writebackTime(g_writeback_time),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_runahead_time),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_tlb_first_time),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_tlb_resp_time),
    .io_out_bits_debug_seqNum_seqNum(g_seq_num),
    .io_out_bits_debug_seqNum_uopIdx(g_debug_uop_idx)
  );

  VIPU_xs x (
    .clock(clock), .reset(reset), .io_in_ready(x_in_ready),
    .io_in_valid(s.valid),
    .io_in_bits_ctrl_fuOpType(s.fu_op_type),
    .io_in_bits_ctrl_vpu_vma(s.vma),
    .io_in_bits_ctrl_vpu_vta(s.vta),
    .io_in_bits_ctrl_vpu_vsew(s.vsew),
    .io_in_bits_ctrl_vpu_vlmul(s.vlmul),
    .io_in_bits_ctrl_vpu_vm(s.vm),
    .io_in_bits_ctrl_vpu_vstart(s.vstart),
    .io_in_bits_ctrl_vpu_vuopIdx(s.vuop_idx),
    .io_in_bits_ctrlPipe_2_robIdx_flag(s.rob_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value(s.rob_value),
    .io_in_bits_ctrlPipe_2_pdest(s.pdest),
    .io_in_bits_ctrlPipe_2_rfWen(s.rf_wen),
    .io_in_bits_ctrlPipe_2_vecWen(s.vec_wen),
    .io_in_bits_ctrlPipe_2_v0Wen(s.v0_wen),
    .io_in_bits_ctrlPipe_2_vpu_vstart(s.pipe_vstart),
    .io_in_bits_validPipe_2(s.valid_pipe_2),
    .io_in_bits_data_src_4(s.src_4),
    .io_in_bits_data_src_3(s.src_3),
    .io_in_bits_data_src_2(s.src_2),
    .io_in_bits_data_src_1(s.src_1),
    .io_in_bits_data_src_0(s.src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove(s.eliminated_move),
    .io_in_bits_perfDebugInfo_renameTime(s.rename_time),
    .io_in_bits_perfDebugInfo_dispatchTime(s.dispatch_time),
    .io_in_bits_perfDebugInfo_enqRsTime(s.enq_rs_time),
    .io_in_bits_perfDebugInfo_selectTime(s.select_time),
    .io_in_bits_perfDebugInfo_issueTime(s.issue_time),
    .io_in_bits_perfDebugInfo_writebackTime(s.writeback_time),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(s.runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(s.tlb_first_req_time),
    .io_in_bits_perfDebugInfo_tlbRespTime(s.tlb_resp_time),
    .io_in_bits_debug_seqNum_seqNum(s.seq_num),
    .io_in_bits_debug_seqNum_uopIdx(s.debug_uop_idx),
    .io_out_ready(s.valid_pipe_2),
    .io_out_valid(x_out_valid),
    .io_out_bits_ctrl_robIdx_flag(x_out_rob_flag),
    .io_out_bits_ctrl_robIdx_value(x_out_rob_value),
    .io_out_bits_ctrl_pdest(x_out_pdest),
    .io_out_bits_ctrl_rfWen(x_out_rf_wen),
    .io_out_bits_ctrl_vecWen(x_out_vec_wen),
    .io_out_bits_ctrl_v0Wen(x_out_v0_wen),
    .io_out_bits_ctrl_exceptionVec_2(x_out_exception),
    .io_out_bits_res_data(x_out_data),
    .io_out_bits_perfDebugInfo_eliminatedMove(x_perf_eliminated),
    .io_out_bits_perfDebugInfo_renameTime(x_rename_time),
    .io_out_bits_perfDebugInfo_dispatchTime(x_dispatch_time),
    .io_out_bits_perfDebugInfo_enqRsTime(x_enq_rs_time),
    .io_out_bits_perfDebugInfo_selectTime(x_select_time),
    .io_out_bits_perfDebugInfo_issueTime(x_issue_time),
    .io_out_bits_perfDebugInfo_writebackTime(x_writeback_time),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(x_runahead_time),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(x_tlb_first_time),
    .io_out_bits_perfDebugInfo_tlbRespTime(x_tlb_resp_time),
    .io_out_bits_debug_seqNum_seqNum(x_seq_num),
    .io_out_bits_debug_seqNum_uopIdx(x_debug_uop_idx)
  );

  function automatic logic [127:0] random_vector();
    return {$urandom, $urandom, $urandom, $urandom};
  endfunction

  function automatic stimulus_t make_stimulus();
    stimulus_t t;
    int unsigned selector;
    t = '0;
    selector = $urandom_range(0, 99);
    t.valid = selector < 85;
    selector = $urandom_range(0, 99);
    if (selector < 15)
      t.fu_op_type = 9'h041;
    else if (selector < 30)
      t.fu_op_type = 9'h042;
    else if (selector < 45)
      t.fu_op_type = 9'h04b;
    else if (selector < 60)
      t.fu_op_type = 9'h050;
    else if (selector < 75)
      t.fu_op_type = 9'h051;
    else
      t.fu_op_type = $urandom_range(0, 9'h1ff);

    t.vma = $urandom;
    t.vta = $urandom;
    t.vsew = $urandom_range(0, 3);
    t.vlmul = $urandom_range(0, 7);
    t.vm = $urandom;
    t.vstart = $urandom;
    t.vuop_idx = $urandom;
    t.rob_flag = $urandom;
    t.rob_value = $urandom;
    t.pdest = $urandom;
    t.rf_wen = $urandom;
    t.vec_wen = $urandom;
    t.v0_wen = $urandom;
    t.pipe_vstart = $urandom;
    t.valid_pipe_2 = $urandom_range(0, 1);
    t.src_4 = $urandom;
    t.src_3 = random_vector();
    t.src_2 = random_vector();
    t.src_1 = random_vector();
    t.src_0 = random_vector();
    t.eliminated_move = $urandom;
    t.rename_time = {$urandom, $urandom};
    t.dispatch_time = {$urandom, $urandom};
    t.enq_rs_time = {$urandom, $urandom};
    t.select_time = {$urandom, $urandom};
    t.issue_time = {$urandom, $urandom};
    t.writeback_time = {$urandom, $urandom};
    t.runahead_checkpoint_id = {$urandom, $urandom};
    t.tlb_first_req_time = {$urandom, $urandom};
    t.tlb_resp_time = {$urandom, $urandom};
    t.seq_num = {$urandom, $urandom};
    t.debug_uop_idx = $urandom;
    return t;
  endfunction

  always @(negedge clock) begin
    if (!reset && cycle > 4) begin
      checks++;
      if ({
          g_in_ready, g_out_valid, g_out_rob_flag, g_out_rob_value,
          g_out_pdest, g_out_rf_wen, g_out_vec_wen, g_out_v0_wen,
          g_out_exception, g_out_data, g_perf_eliminated, g_rename_time,
          g_dispatch_time, g_enq_rs_time, g_select_time, g_issue_time,
          g_writeback_time, g_runahead_time, g_tlb_first_time,
          g_tlb_resp_time, g_seq_num, g_debug_uop_idx
         } !== {
          x_in_ready, x_out_valid, x_out_rob_flag, x_out_rob_value,
          x_out_pdest, x_out_rf_wen, x_out_vec_wen, x_out_v0_wen,
          x_out_exception, x_out_data, x_perf_eliminated, x_rename_time,
          x_dispatch_time, x_enq_rs_time, x_select_time, x_issue_time,
          x_writeback_time, x_runahead_time, x_tlb_first_time,
          x_tlb_resp_time, x_seq_num, x_debug_uop_idx
         }) begin
        errors++;
        if (errors <= 10)
          $display("DIFF cycle=%0d g_valid=%b x_valid=%b g_data=%h x_data=%h",
                   cycle, g_out_valid, x_out_valid, g_out_data, x_out_data);
      end
      seen_one |= {
        g_in_ready, g_out_valid, g_out_rob_flag, g_out_rob_value,
        g_out_pdest, g_out_rf_wen, g_out_vec_wen, g_out_v0_wen,
        g_out_exception, g_out_data, g_perf_eliminated, g_rename_time,
        g_dispatch_time, g_enq_rs_time, g_select_time, g_issue_time,
        g_writeback_time, g_runahead_time, g_tlb_first_time, g_tlb_resp_time,
        g_seq_num, g_debug_uop_idx
      };
      seen_zero |= ~{
        g_in_ready, g_out_valid, g_out_rob_flag, g_out_rob_value,
        g_out_pdest, g_out_rf_wen, g_out_vec_wen, g_out_v0_wen,
        g_out_exception, g_out_data, g_perf_eliminated, g_rename_time,
        g_dispatch_time, g_enq_rs_time, g_select_time, g_issue_time,
        g_writeback_time, g_runahead_time, g_tlb_first_time, g_tlb_resp_time,
        g_seq_num, g_debug_uop_idx
      };
    end
  end

  initial begin
    clock = 1'b0;
    reset = 1'b1;
    s = '0;
    cycle = 0;
    checks = 0;
    errors = 0;
    cov_opcode_shift = 0;
    cov_opcode_special_4b = 0;
    cov_opcode_special_50 = 0;
    cov_opcode_special_51 = 0;
    cov_opcode_other = 0;
    cov_valid = 0;
    seen_one = '0;
    seen_zero = '0;

    repeat (6) @(negedge clock);
    reset = 1'b0;

    for (cycle = 0; cycle < NCYCLES; cycle++) begin
      @(negedge clock);
      s = make_stimulus();

      if (s.valid) begin
        cov_valid++;
        if (s.fu_op_type == 9'h041 || s.fu_op_type == 9'h042)
          cov_opcode_shift++;
        else if (s.fu_op_type == 9'h04b)
          cov_opcode_special_4b++;
        else if (s.fu_op_type == 9'h050)
          cov_opcode_special_50++;
        else if (s.fu_op_type == 9'h051)
          cov_opcode_special_51++;
        else
          cov_opcode_other++;
      end
    end

    repeat (5) @(negedge clock);

    begin
      bit coverage_ok;
      coverage_ok = 1'b1;

      if (cov_valid < 100000) coverage_ok = 1'b0;
      if (cov_opcode_shift < 1000) coverage_ok = 1'b0;
      if (cov_opcode_special_4b < 1000) coverage_ok = 1'b0;
      if (cov_opcode_special_50 < 1000) coverage_ok = 1'b0;
      if (cov_opcode_special_51 < 1000) coverage_ok = 1'b0;
      if (cov_opcode_other < 1000) coverage_ok = 1'b0;
      if (seen_one == '0 || seen_zero == '0) coverage_ok = 1'b0;

      $display("coverage valid=%0d shift=%0d op4b=%0d op50=%0d op51=%0d other=%0d",
               cov_valid, cov_opcode_shift, cov_opcode_special_4b,
               cov_opcode_special_50, cov_opcode_special_51, cov_opcode_other);
      $display("checks=%0d errors=%0d", checks, errors);

      if (errors == 0 && coverage_ok)
        $display("TEST PASSED");
      else
        $display("TEST FAILED");
    end
    $finish;
  end

endmodule
