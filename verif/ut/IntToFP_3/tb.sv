// =============================================================================
// tb —— IntToFP_3 双例化 UT（由 scripts/gen_exeunits_ut.py 生成，勿手改）
//   golden IntToFP_3 vs 重写 IntToFP_3_xs；每拍比较全部 21 个输出口（!==）。
//   激励 / 覆盖 / 判据见生成器 TARGETS 里本目标一节。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int WARM = 12;
  localparam int RESET_ODDS = 20000;
  longint errors = 0, checks = 0;
  int cyc;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;

  logic io_in_valid;
  logic [1:0] io_in_bits_ctrl_fpu_typeTagOut;
  logic io_in_bits_ctrl_fpu_wflags;
  logic [1:0] io_in_bits_ctrl_fpu_typ;
  logic [2:0] io_in_bits_ctrl_fpu_rm;
  logic io_in_bits_ctrlPipe_2_robIdx_flag;
  logic [7:0] io_in_bits_ctrlPipe_2_robIdx_value;
  logic [7:0] io_in_bits_ctrlPipe_2_pdest;
  logic io_in_bits_ctrlPipe_2_fpWen;
  logic io_in_bits_ctrlPipe_2_fpu_wflags;
  logic io_in_bits_validPipe_0;
  logic io_in_bits_validPipe_1;
  logic io_in_bits_validPipe_2;
  logic [63:0] io_in_bits_data_src_0;
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
  logic io_out_ready;
  logic [2:0] io_frm;
  wire  g_io_in_ready, i_io_in_ready;
  wire  g_io_out_valid, i_io_out_valid;
  wire  g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag;
  wire  [7:0] g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value;
  wire  [7:0] g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest;
  wire  g_io_out_bits_ctrl_fpWen, i_io_out_bits_ctrl_fpWen;
  wire  g_io_out_bits_ctrl_fpu_wflags, i_io_out_bits_ctrl_fpu_wflags;
  wire  [63:0] g_io_out_bits_res_data, i_io_out_bits_res_data;
  wire  [4:0] g_io_out_bits_res_fflags, i_io_out_bits_res_fflags;
  wire  g_io_out_bits_perfDebugInfo_eliminatedMove, i_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_io_out_bits_perfDebugInfo_renameTime, i_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_dispatchTime, i_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_writebackTime, i_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_tlbRespTime, i_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx;

  longint c_fire = 0, c_out = 0, c_stall = 0, c_cvt = 0, c_fmv = 0, c_f16 = 0, c_f32 = 0, c_f64 = 0, c_dyn = 0;

  IntToFP_3 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fpu_typeTagOut(io_in_bits_ctrl_fpu_typeTagOut),
    .io_in_bits_ctrl_fpu_wflags(io_in_bits_ctrl_fpu_wflags),
    .io_in_bits_ctrl_fpu_typ(io_in_bits_ctrl_fpu_typ),
    .io_in_bits_ctrl_fpu_rm(io_in_bits_ctrl_fpu_rm),
    .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest),
    .io_in_bits_ctrlPipe_2_fpWen(io_in_bits_ctrlPipe_2_fpWen),
    .io_in_bits_ctrlPipe_2_fpu_wflags(io_in_bits_ctrlPipe_2_fpu_wflags),
    .io_in_bits_validPipe_0(io_in_bits_validPipe_0),
    .io_in_bits_validPipe_1(io_in_bits_validPipe_1),
    .io_in_bits_validPipe_2(io_in_bits_validPipe_2),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
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
    .io_out_ready(io_out_ready),
    .io_frm(io_frm),
    .io_in_ready(g_io_in_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(g_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(g_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(g_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen(g_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags(g_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data(g_io_out_bits_res_data),
    .io_out_bits_res_fflags(g_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_io_out_bits_debug_seqNum_uopIdx)
  );
  IntToFP_3_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fpu_typeTagOut(io_in_bits_ctrl_fpu_typeTagOut),
    .io_in_bits_ctrl_fpu_wflags(io_in_bits_ctrl_fpu_wflags),
    .io_in_bits_ctrl_fpu_typ(io_in_bits_ctrl_fpu_typ),
    .io_in_bits_ctrl_fpu_rm(io_in_bits_ctrl_fpu_rm),
    .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest),
    .io_in_bits_ctrlPipe_2_fpWen(io_in_bits_ctrlPipe_2_fpWen),
    .io_in_bits_ctrlPipe_2_fpu_wflags(io_in_bits_ctrlPipe_2_fpu_wflags),
    .io_in_bits_validPipe_0(io_in_bits_validPipe_0),
    .io_in_bits_validPipe_1(io_in_bits_validPipe_1),
    .io_in_bits_validPipe_2(io_in_bits_validPipe_2),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
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
    .io_out_ready(io_out_ready),
    .io_frm(io_frm),
    .io_in_ready(i_io_in_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(i_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(i_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(i_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen(i_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags(i_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data(i_io_out_bits_res_data),
    .io_out_bits_res_fflags(i_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_io_out_bits_debug_seqNum_uopIdx)
  );

  // 每拍激励：先全随机，再按目标语义覆盖
  task automatic drive();
    io_in_valid = 1'($urandom);
    io_in_bits_ctrl_fpu_typeTagOut = 2'($urandom);
    io_in_bits_ctrl_fpu_wflags = 1'($urandom);
    io_in_bits_ctrl_fpu_typ = 2'($urandom);
    io_in_bits_ctrl_fpu_rm = 3'($urandom);
    io_in_bits_ctrlPipe_2_robIdx_flag = 1'($urandom);
    io_in_bits_ctrlPipe_2_robIdx_value = 8'($urandom);
    io_in_bits_ctrlPipe_2_pdest = 8'($urandom);
    io_in_bits_ctrlPipe_2_fpWen = 1'($urandom);
    io_in_bits_ctrlPipe_2_fpu_wflags = 1'($urandom);
    io_in_bits_validPipe_0 = 1'($urandom);
    io_in_bits_validPipe_1 = 1'($urandom);
    io_in_bits_validPipe_2 = 1'($urandom);
    io_in_bits_data_src_0 = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    io_in_bits_perfDebugInfo_renameTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_selectTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_issueTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom(), $urandom()});
    io_in_bits_debug_seqNum_seqNum = 56'({$urandom(), $urandom()});
    io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_out_ready = 1'($urandom);
    io_frm = 3'($urandom);

    io_in_valid  = ($urandom_range(0, 9) < 7);
    io_out_ready = ($urandom_range(0, 9) != 0);           // 10% 反压
    io_in_bits_validPipe_0 = ($urandom_range(0, 9) != 0);
    io_in_bits_validPipe_1 = ($urandom_range(0, 9) != 0);
    io_in_bits_validPipe_2 = ($urandom_range(0, 9) != 0);
    if ($urandom_range(0, 9) != 0) io_in_bits_ctrl_fpu_typeTagOut = 2'($urandom_range(0, 2));
    io_in_bits_ctrl_fpu_rm = ($urandom_range(0, 4) == 0) ? 3'b111 : 3'($urandom_range(0, 4));
    io_frm = 3'($urandom_range(0, 4));
    // 整数源：小值 / 边界值 / 全随机
    case ($urandom_range(0, 5))
      0: io_in_bits_data_src_0 = 64'($urandom_range(0, 255));
      1: io_in_bits_data_src_0 = 64'h8000_0000_0000_0000;
      2: io_in_bits_data_src_0 = {32'($urandom), 32'h8000_0000};
      3: io_in_bits_data_src_0 = -64'($urandom_range(1, 255));
      default: ;
    endcase
    // 暖机：复位撤销后连发有效请求、不反压，把不复位的 payload / 数据寄存器写成确定值
    if (cyc < WARM) begin
      io_in_valid = 1; io_out_ready = 1;
      io_in_bits_validPipe_0 = 1; io_in_bits_validPipe_1 = 1; io_in_bits_validPipe_2 = 1;
    end

  endtask

  task automatic compare();
    checks++; if (g_io_in_ready !== i_io_in_ready) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_in_ready g=%h i=%h", cyc, g_io_in_ready, i_io_in_ready); end
    checks++; if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_valid g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
    checks++; if (g_io_out_bits_ctrl_robIdx_flag !== i_io_out_bits_ctrl_robIdx_flag) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_robIdx_flag g=%h i=%h", cyc, g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag); end
    checks++; if (g_io_out_bits_ctrl_robIdx_value !== i_io_out_bits_ctrl_robIdx_value) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_robIdx_value g=%h i=%h", cyc, g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value); end
    checks++; if (g_io_out_bits_ctrl_pdest !== i_io_out_bits_ctrl_pdest) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_pdest g=%h i=%h", cyc, g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest); end
    checks++; if (g_io_out_bits_ctrl_fpWen !== i_io_out_bits_ctrl_fpWen) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_fpWen g=%h i=%h", cyc, g_io_out_bits_ctrl_fpWen, i_io_out_bits_ctrl_fpWen); end
    checks++; if (g_io_out_bits_ctrl_fpu_wflags !== i_io_out_bits_ctrl_fpu_wflags) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_fpu_wflags g=%h i=%h", cyc, g_io_out_bits_ctrl_fpu_wflags, i_io_out_bits_ctrl_fpu_wflags); end
    checks++; if (g_io_out_bits_res_data !== i_io_out_bits_res_data) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_res_data g=%h i=%h", cyc, g_io_out_bits_res_data, i_io_out_bits_res_data); end
    checks++; if (g_io_out_bits_res_fflags !== i_io_out_bits_res_fflags) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_res_fflags g=%h i=%h", cyc, g_io_out_bits_res_fflags, i_io_out_bits_res_fflags); end
    checks++; if (g_io_out_bits_perfDebugInfo_eliminatedMove !== i_io_out_bits_perfDebugInfo_eliminatedMove) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_eliminatedMove g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_eliminatedMove, i_io_out_bits_perfDebugInfo_eliminatedMove); end
    checks++; if (g_io_out_bits_perfDebugInfo_renameTime !== i_io_out_bits_perfDebugInfo_renameTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_renameTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_renameTime, i_io_out_bits_perfDebugInfo_renameTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_dispatchTime !== i_io_out_bits_perfDebugInfo_dispatchTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_dispatchTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_dispatchTime, i_io_out_bits_perfDebugInfo_dispatchTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_enqRsTime !== i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_enqRsTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_selectTime !== i_io_out_bits_perfDebugInfo_selectTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_selectTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_issueTime !== i_io_out_bits_perfDebugInfo_issueTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_issueTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_writebackTime !== i_io_out_bits_perfDebugInfo_writebackTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_writebackTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_writebackTime, i_io_out_bits_perfDebugInfo_writebackTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_runahead_checkpoint_id !== i_io_out_bits_perfDebugInfo_runahead_checkpoint_id) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_runahead_checkpoint_id g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_io_out_bits_perfDebugInfo_runahead_checkpoint_id); end
    checks++; if (g_io_out_bits_perfDebugInfo_tlbFirstReqTime !== i_io_out_bits_perfDebugInfo_tlbFirstReqTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_tlbFirstReqTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_io_out_bits_perfDebugInfo_tlbFirstReqTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_tlbRespTime !== i_io_out_bits_perfDebugInfo_tlbRespTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_tlbRespTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_tlbRespTime, i_io_out_bits_perfDebugInfo_tlbRespTime); end
    checks++; if (g_io_out_bits_debug_seqNum_seqNum !== i_io_out_bits_debug_seqNum_seqNum) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debug_seqNum_seqNum g=%h i=%h", cyc, g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum); end
    checks++; if (g_io_out_bits_debug_seqNum_uopIdx !== i_io_out_bits_debug_seqNum_uopIdx) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debug_seqNum_uopIdx g=%h i=%h", cyc, g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx); end
  endtask

  task automatic sample_cov();

    if (io_in_valid && g_io_in_ready) begin
      c_fire++;
      if (io_in_bits_ctrl_fpu_wflags) c_cvt++; else c_fmv++;
      if (io_in_bits_ctrl_fpu_typeTagOut == 2) c_f16++;
      if (io_in_bits_ctrl_fpu_typeTagOut == 0) c_f32++;
      if (io_in_bits_ctrl_fpu_typeTagOut == 1) c_f64++;
      if (io_in_bits_ctrl_fpu_rm == 3'b111) c_dyn++;
    end
    if (g_io_out_valid) c_out++;
    if (!g_io_in_ready) c_stall++;

  endtask

  initial begin
    bit ok;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1;
    drive();
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      reset = (cyc < 5) || ($urandom_range(0, RESET_ODDS - 1) == 0);
      drive();
      #4;
      if (cyc >= WARM) compare();
      if (!reset) sample_cov();
    end
    $display("cov fire=%0d out=%0d stall=%0d cvt=%0d fmv=%0d f16/f32/f64=%0d/%0d/%0d dyn=%0d", c_fire, c_out, c_stall, c_cvt, c_fmv, c_f16, c_f32, c_f64, c_dyn);
    ok = (errors == 0) && (checks > 1000);
    if (!(c_fire > 10000)) begin ok = 0; $display("cov LOW: c_fire > 10000"); end
    if (!(c_out > 10000)) begin ok = 0; $display("cov LOW: c_out > 10000"); end
    if (!(c_stall > 1000)) begin ok = 0; $display("cov LOW: c_stall > 1000"); end
    if (!(c_cvt > 1000)) begin ok = 0; $display("cov LOW: c_cvt > 1000"); end
    if (!(c_fmv > 1000)) begin ok = 0; $display("cov LOW: c_fmv > 1000"); end
    if (!(c_f16 > 1000)) begin ok = 0; $display("cov LOW: c_f16 > 1000"); end
    if (!(c_f32 > 1000)) begin ok = 0; $display("cov LOW: c_f32 > 1000"); end
    if (!(c_f64 > 1000)) begin ok = 0; $display("cov LOW: c_f64 > 1000"); end
    if (!(c_dyn > 1000)) begin ok = 0; $display("cov LOW: c_dyn > 1000"); end
    $display("checks=%0d errors=%0d", checks, errors);
    if (ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
