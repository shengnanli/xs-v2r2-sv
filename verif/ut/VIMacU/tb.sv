// =============================================================================
// tb —— VIMacU UT：golden VIMacU 与重写件 VIMacU_xs 双例化，同一随机激励，复位后每拍比较全部输出端口；
//       覆盖 fuOpType[2:0] 0..6（vmul..vsmul，7 为未用编码不计）、4 种 sew、vm/ta/ma 8 种组合。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;

  logic reset;
  logic io_in_valid, io_out_ready;
  logic [8:0] io_in_bits_ctrl_fuOpType, io_in_bits_ctrlPipe_2_fuOpType;
  logic [1:0] io_in_bits_ctrl_vpu_vsew, io_in_bits_ctrlPipe_2_vpu_vsew, io_vxrm;
  logic [6:0] io_in_bits_ctrl_vpu_vuopIdx, io_in_bits_ctrlPipe_2_vpu_vuopIdx;
  logic io_in_bits_ctrlPipe_2_robIdx_flag;
  logic io_in_bits_ctrlPipe_2_vecWen, io_in_bits_ctrlPipe_2_v0Wen;
  logic io_in_bits_ctrlPipe_2_vpu_vma, io_in_bits_ctrlPipe_2_vpu_vta;
  logic io_in_bits_ctrlPipe_2_vpu_vm, io_in_bits_validPipe_2;
  logic [7:0] io_in_bits_ctrlPipe_2_robIdx_value;
  logic [7:0] io_in_bits_ctrlPipe_2_pdest;
  logic [7:0] io_in_bits_ctrlPipe_2_vpu_vstart;
  logic [127:0] io_in_bits_data_src_2, io_in_bits_data_src_1, io_in_bits_data_src_0;
  logic [7:0] io_in_bits_dataPipe_2_src_4;
  logic [127:0] io_in_bits_dataPipe_2_src_3, io_in_bits_dataPipe_2_src_2;

  logic io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] io_in_bits_debug_seqNum_seqNum;
  logic [7:0] io_in_bits_debug_seqNum_uopIdx;

  wire g_ready, x_ready, g_valid, x_valid;
  wire g_rf, x_rf, g_vw, x_vw, g_v0w, x_v0w, g_sat, x_sat, g_elim, x_elim;
  wire [7:0] g_robv, x_robv, g_pd, x_pd, g_uop, x_uop;
  wire [127:0] g_data, x_data;
  wire [63:0] g_dbg[0:9], x_dbg[0:9];
  wire [55:0] g_seq, x_seq;

  VIMacU g (
    .clock(clock), .reset(reset),
    .io_in_ready(g_ready), .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_vpu_vsew(io_in_bits_ctrl_vpu_vsew),
    .io_in_bits_ctrl_vpu_vuopIdx(io_in_bits_ctrl_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_2_fuOpType(io_in_bits_ctrlPipe_2_fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest),
    .io_in_bits_ctrlPipe_2_vecWen(io_in_bits_ctrlPipe_2_vecWen),
    .io_in_bits_ctrlPipe_2_v0Wen(io_in_bits_ctrlPipe_2_v0Wen),
    .io_in_bits_ctrlPipe_2_vpu_vma(io_in_bits_ctrlPipe_2_vpu_vma),
    .io_in_bits_ctrlPipe_2_vpu_vta(io_in_bits_ctrlPipe_2_vpu_vta),
    .io_in_bits_ctrlPipe_2_vpu_vsew(io_in_bits_ctrlPipe_2_vpu_vsew),
    .io_in_bits_ctrlPipe_2_vpu_vm(io_in_bits_ctrlPipe_2_vpu_vm),
    .io_in_bits_ctrlPipe_2_vpu_vstart(io_in_bits_ctrlPipe_2_vpu_vstart),
    .io_in_bits_ctrlPipe_2_vpu_vuopIdx(io_in_bits_ctrlPipe_2_vpu_vuopIdx),
    .io_in_bits_validPipe_2(io_in_bits_validPipe_2),
    .io_in_bits_data_src_2(io_in_bits_data_src_2),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_dataPipe_2_src_4(io_in_bits_dataPipe_2_src_4),
    .io_in_bits_dataPipe_2_src_3(io_in_bits_dataPipe_2_src_3),
    .io_in_bits_dataPipe_2_src_2(io_in_bits_dataPipe_2_src_2),
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready), .io_out_valid(g_valid),
    .io_out_bits_ctrl_robIdx_flag(g_rf),
    .io_out_bits_ctrl_robIdx_value(g_robv),
    .io_out_bits_ctrl_pdest(g_pd),
    .io_out_bits_ctrl_vecWen(g_vw),
    .io_out_bits_ctrl_v0Wen(g_v0w),
    .io_out_bits_res_data(g_data),
    .io_out_bits_res_vxsat(g_sat),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_elim),
    .io_out_bits_perfDebugInfo_renameTime(g_dbg[0]),
    .io_out_bits_perfDebugInfo_dispatchTime(g_dbg[1]),
    .io_out_bits_perfDebugInfo_enqRsTime(g_dbg[2]),
    .io_out_bits_perfDebugInfo_selectTime(g_dbg[3]),
    .io_out_bits_perfDebugInfo_issueTime(g_dbg[4]),
    .io_out_bits_perfDebugInfo_writebackTime(g_dbg[5]),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_dbg[6]),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_dbg[7]),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_dbg[8]),
    .io_out_bits_debug_seqNum_seqNum(g_seq),
    .io_out_bits_debug_seqNum_uopIdx(g_uop),
    .io_vxrm(io_vxrm)
  );

  VIMacU_xs x (
    .clock(clock), .reset(reset),
    .io_in_ready(x_ready), .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_vpu_vsew(io_in_bits_ctrl_vpu_vsew),
    .io_in_bits_ctrl_vpu_vuopIdx(io_in_bits_ctrl_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_2_fuOpType(io_in_bits_ctrlPipe_2_fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest),
    .io_in_bits_ctrlPipe_2_vecWen(io_in_bits_ctrlPipe_2_vecWen),
    .io_in_bits_ctrlPipe_2_v0Wen(io_in_bits_ctrlPipe_2_v0Wen),
    .io_in_bits_ctrlPipe_2_vpu_vma(io_in_bits_ctrlPipe_2_vpu_vma),
    .io_in_bits_ctrlPipe_2_vpu_vta(io_in_bits_ctrlPipe_2_vpu_vta),
    .io_in_bits_ctrlPipe_2_vpu_vsew(io_in_bits_ctrlPipe_2_vpu_vsew),
    .io_in_bits_ctrlPipe_2_vpu_vm(io_in_bits_ctrlPipe_2_vpu_vm),
    .io_in_bits_ctrlPipe_2_vpu_vstart(io_in_bits_ctrlPipe_2_vpu_vstart),
    .io_in_bits_ctrlPipe_2_vpu_vuopIdx(io_in_bits_ctrlPipe_2_vpu_vuopIdx),
    .io_in_bits_validPipe_2(io_in_bits_validPipe_2),
    .io_in_bits_data_src_2(io_in_bits_data_src_2),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_dataPipe_2_src_4(io_in_bits_dataPipe_2_src_4),
    .io_in_bits_dataPipe_2_src_3(io_in_bits_dataPipe_2_src_3),
    .io_in_bits_dataPipe_2_src_2(io_in_bits_dataPipe_2_src_2),
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready), .io_out_valid(x_valid),
    .io_out_bits_ctrl_robIdx_flag(x_rf),
    .io_out_bits_ctrl_robIdx_value(x_robv),
    .io_out_bits_ctrl_pdest(x_pd),
    .io_out_bits_ctrl_vecWen(x_vw),
    .io_out_bits_ctrl_v0Wen(x_v0w),
    .io_out_bits_res_data(x_data),
    .io_out_bits_res_vxsat(x_sat),
    .io_out_bits_perfDebugInfo_eliminatedMove(x_elim),
    .io_out_bits_perfDebugInfo_renameTime(x_dbg[0]),
    .io_out_bits_perfDebugInfo_dispatchTime(x_dbg[1]),
    .io_out_bits_perfDebugInfo_enqRsTime(x_dbg[2]),
    .io_out_bits_perfDebugInfo_selectTime(x_dbg[3]),
    .io_out_bits_perfDebugInfo_issueTime(x_dbg[4]),
    .io_out_bits_perfDebugInfo_writebackTime(x_dbg[5]),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(x_dbg[6]),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(x_dbg[7]),
    .io_out_bits_perfDebugInfo_tlbRespTime(x_dbg[8]),
    .io_out_bits_debug_seqNum_seqNum(x_seq),
    .io_out_bits_debug_seqNum_uopIdx(x_uop),
    .io_vxrm(io_vxrm)
  );

  longint unsigned errors = 0;
  longint unsigned checks = 0;
  longint unsigned opcode_cov[8];
  longint unsigned sew_cov[4];
  longint unsigned combo_cov[8];

  task automatic randomize_inputs;
    begin
      io_in_bits_ctrl_fuOpType = $urandom;
      io_in_bits_ctrl_vpu_vsew = $urandom;
      io_in_bits_ctrl_vpu_vuopIdx = $urandom;

      io_in_bits_ctrlPipe_2_fuOpType = io_in_bits_ctrl_fuOpType;
      io_in_bits_ctrlPipe_2_vpu_vsew = io_in_bits_ctrl_vpu_vsew;
      io_in_bits_ctrlPipe_2_vpu_vuopIdx = io_in_bits_ctrl_vpu_vuopIdx;
      io_in_bits_ctrlPipe_2_robIdx_flag = $urandom;
      io_in_bits_ctrlPipe_2_robIdx_value = $urandom;
      io_in_bits_ctrlPipe_2_pdest = $urandom;
      io_in_bits_ctrlPipe_2_vecWen = $urandom;
      io_in_bits_ctrlPipe_2_v0Wen = $urandom;
      io_in_bits_ctrlPipe_2_vpu_vma = $urandom;
      io_in_bits_ctrlPipe_2_vpu_vta = $urandom;
      io_in_bits_ctrlPipe_2_vpu_vm = $urandom;
      io_in_bits_ctrlPipe_2_vpu_vstart = $urandom;

      io_in_bits_data_src_2 = {$urandom, $urandom, $urandom, $urandom};
      io_in_bits_data_src_1 = {$urandom, $urandom, $urandom, $urandom};
      io_in_bits_data_src_0 = {$urandom, $urandom, $urandom, $urandom};
      io_in_bits_dataPipe_2_src_4 = $urandom;
      io_in_bits_dataPipe_2_src_3 = {$urandom, $urandom, $urandom, $urandom};
      io_in_bits_dataPipe_2_src_2 = {$urandom, $urandom, $urandom, $urandom};

      io_in_bits_perfDebugInfo_eliminatedMove = $urandom;
      io_in_bits_perfDebugInfo_renameTime = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_dispatchTime = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_enqRsTime = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_selectTime = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_issueTime = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_writebackTime = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_runahead_checkpoint_id = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_tlbFirstReqTime = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_tlbRespTime = {$urandom, $urandom};
      io_in_bits_debug_seqNum_seqNum = {$urandom, $urandom};
      io_in_bits_debug_seqNum_uopIdx = $urandom;
      io_vxrm = $urandom;
    end
  endtask

  always @(negedge clock) begin
    if (!reset) begin
      checks++;

      if (g_ready !== x_ready ||
          g_valid !== x_valid ||
          (g_valid &&
           ({g_rf, g_robv, g_pd, g_vw, g_v0w, g_data, g_sat, g_elim,
             g_dbg[0], g_dbg[1], g_dbg[2], g_dbg[3], g_dbg[4], g_dbg[5],
             g_dbg[6], g_dbg[7], g_dbg[8], g_seq, g_uop} !==
            {x_rf, x_robv, x_pd, x_vw, x_v0w, x_data, x_sat, x_elim,
             x_dbg[0], x_dbg[1], x_dbg[2], x_dbg[3], x_dbg[4], x_dbg[5],
             x_dbg[6], x_dbg[7], x_dbg[8], x_seq, x_uop}))) begin
        errors++;
        if (errors <= 10)
          $display("VIMacU mismatch at cycle %0d", checks);
      end

      if (io_in_valid && g_ready) begin
        opcode_cov[io_in_bits_ctrl_fuOpType[2:0]]++;
        sew_cov[io_in_bits_ctrl_vpu_vsew]++;
        combo_cov[{io_in_bits_ctrlPipe_2_vpu_vm,
                   io_in_bits_ctrlPipe_2_vpu_vta,
                   io_in_bits_ctrlPipe_2_vpu_vma}]++;
      end
    end
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;

    reset = 1'b1;
    io_in_valid = 1'b0;
    io_in_bits_validPipe_2 = 1'b0;
    io_out_ready = 1'b0;

    for (int i = 0; i < 8; i++) begin
      opcode_cov[i] = 0;
      combo_cov[i] = 0;
    end
    for (int i = 0; i < 4; i++)
      sew_cov[i] = 0;

    randomize_inputs();

    repeat (4) @(negedge clock);
    reset = 1'b0;

    for (int unsigned c = 0; c < NCYCLES; c++) begin
      @(negedge clock);
      randomize_inputs();

      io_in_valid = (c % 17 != 0);
      io_in_bits_ctrl_fuOpType[2:0] = c % 7;
      io_in_bits_ctrl_fuOpType[3] = c[0];
      io_in_bits_ctrl_vpu_vsew = c % 4;

      io_in_bits_ctrlPipe_2_fuOpType = io_in_bits_ctrl_fuOpType;
      io_in_bits_ctrlPipe_2_vpu_vsew = io_in_bits_ctrl_vpu_vsew;
      io_in_bits_ctrlPipe_2_vpu_vuopIdx = io_in_bits_ctrl_vpu_vuopIdx;
      io_in_bits_ctrlPipe_2_vpu_vm = c[2];
      io_in_bits_ctrlPipe_2_vpu_vta = c[3];
      io_in_bits_ctrlPipe_2_vpu_vma = c[4];

      io_in_bits_validPipe_2 = (c % 5 != 0);
      io_out_ready = ($urandom_range(0, 9) != 0);
    end

    repeat (8) @(negedge clock);

    $display("VIMacU: checks=%0d errors=%0d", checks, errors);
    $display("coverage opcode=%p sew=%p mask_tail=%p",
             opcode_cov, sew_cov, combo_cov);

    if (errors == 0 &&
        opcode_cov[0] != 0 && opcode_cov[1] != 0 &&
        opcode_cov[2] != 0 && opcode_cov[3] != 0 &&
        opcode_cov[4] != 0 && opcode_cov[5] != 0 &&
        opcode_cov[6] != 0 &&
        sew_cov[0] != 0 && sew_cov[1] != 0 &&
        sew_cov[2] != 0 && sew_cov[3] != 0 &&
        combo_cov[0] != 0 && combo_cov[1] != 0 &&
        combo_cov[2] != 0 && combo_cov[3] != 0 &&
        combo_cov[4] != 0 && combo_cov[5] != 0 &&
        combo_cov[6] != 0 && combo_cov[7] != 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");

    $finish;
  end
endmodule
