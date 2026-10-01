// ============================================================================
// DivUnit.sv —— 整数除法功能单元（ExeUnit_7 内）的 SRT16 除法器包装层
//
// 在哪一层：后端定点 ExeUnit_7 内部，DivUnit 把发射队列来的除法微操作
//   包装后喂给 SRT16DividerDataModule（两侧共用同一份 golden 孩子）。
// IO：io_in_* 是发射口（valid/ready + fuOpType/robIdx/pdest/rfWen + 两个 64 位
//   源操作数 + perfDebugInfo/debug_seqNum 随行payload）；io_out_* 是写回口；
//   io_flush_* 是 ROB flush（按 robIdx 杀死在途/等待中的除法）。
// 核心机制：
//   * 接受（in_valid & in_ready）那一拍把 robIdx/isW/isHi 与全部输出 payload
//     整包打拍 —— 这些寄存器**无复位**（golden 原样，重写不得加复位）；
//   * 32 位操作（fuOpType[2]）时源操作数按符号性（~fuOpType[1]）扩展成 64 位；
//   * kill_w 看当前输入的 robIdx、kill_r 看锁存的 robIdx：level=1 要求索引
//     相等，否则按「flag 异或 value 大小」判新旧；
//   * 数据通路（商/余数迭代）全部在 golden SRT16DividerDataModule 里。
// ============================================================================

module xs_DivUnit_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        flush_valid,
  input  logic        flush_rob_flag,
  input  logic [7:0]  flush_rob_value,
  input  logic        flush_level,
  output logic        in_ready,
  input  logic        in_valid,
  input  logic [8:0]  in_fu_op_type,
  input  logic        in_rob_flag,
  input  logic [7:0]  in_rob_value,
  input  logic [7:0]  in_pdest,
  input  logic        in_rf_wen,
  input  logic [63:0] in_src0,
  input  logic [63:0] in_src1,
  input  logic        in_perf_eliminated_move,
  input  logic [63:0] in_perf_rename_time,
  input  logic [63:0] in_perf_dispatch_time,
  input  logic [63:0] in_perf_enq_rs_time,
  input  logic [63:0] in_perf_select_time,
  input  logic [63:0] in_perf_issue_time,
  input  logic [63:0] in_perf_writeback_time,
  input  logic [63:0] in_perf_runahead_checkpoint_id,
  input  logic [63:0] in_perf_tlb_first_req_time,
  input  logic [63:0] in_perf_tlb_resp_time,
  input  logic [55:0] in_dbg_seq_num,
  input  logic [7:0]  in_dbg_uop_idx,
  input  logic        out_ready,
  output logic        out_valid,
  output logic        out_rob_flag,
  output logic [7:0]  out_rob_value,
  output logic [7:0]  out_pdest,
  output logic        out_rf_wen,
  output logic [63:0] out_res_data,
  output logic        out_perf_eliminated_move,
  output logic [63:0] out_perf_rename_time,
  output logic [63:0] out_perf_dispatch_time,
  output logic [63:0] out_perf_enq_rs_time,
  output logic [63:0] out_perf_select_time,
  output logic [63:0] out_perf_issue_time,
  output logic [63:0] out_perf_writeback_time,
  output logic [63:0] out_perf_runahead_checkpoint_id,
  output logic [63:0] out_perf_tlb_first_req_time,
  output logic [63:0] out_perf_tlb_resp_time,
  output logic [55:0] out_dbg_seq_num,
  output logic [7:0]  out_dbg_uop_idx
);
  // ---- 接受那一拍整包打拍：robIdx（flush 用）+ isW/isHi（结果选择用）+ payload ----
  // 全部无复位，与 golden 的 always @(posedge clock) 单臂一致。
  logic        div_in_ready;
  wire         accept = div_in_ready & in_valid;

  logic        rob_flag_q;
  logic [7:0]  rob_value_q;
  logic        is_w_q;
  logic        is_hi_q;
  logic        out_rob_flag_q;
  logic [7:0]  out_rob_value_q;
  logic [7:0]  out_pdest_q;
  logic        out_rf_wen_q;
  logic        perf_eliminated_move_q;
  logic [63:0] perf_rename_time_q;
  logic [63:0] perf_dispatch_time_q;
  logic [63:0] perf_enq_rs_time_q;
  logic [63:0] perf_select_time_q;
  logic [63:0] perf_issue_time_q;
  logic [63:0] perf_writeback_time_q;
  logic [63:0] perf_runahead_checkpoint_id_q;
  logic [63:0] perf_tlb_first_req_time_q;
  logic [63:0] perf_tlb_resp_time_q;
  logic [55:0] dbg_seq_num_q;
  logic [7:0]  dbg_uop_idx_q;

  always_ff @(posedge clock) begin
    if (accept) begin
      rob_flag_q                     <= in_rob_flag;
      rob_value_q                    <= in_rob_value;
      is_w_q                         <= in_fu_op_type[2];
      is_hi_q                        <= in_fu_op_type[0];
      out_rob_flag_q                 <= in_rob_flag;
      out_rob_value_q                <= in_rob_value;
      out_pdest_q                    <= in_pdest;
      out_rf_wen_q                   <= in_rf_wen;
      perf_eliminated_move_q         <= in_perf_eliminated_move;
      perf_rename_time_q             <= in_perf_rename_time;
      perf_dispatch_time_q           <= in_perf_dispatch_time;
      perf_enq_rs_time_q             <= in_perf_enq_rs_time;
      perf_select_time_q             <= in_perf_select_time;
      perf_issue_time_q              <= in_perf_issue_time;
      perf_writeback_time_q          <= in_perf_writeback_time;
      perf_runahead_checkpoint_id_q  <= in_perf_runahead_checkpoint_id;
      perf_tlb_first_req_time_q      <= in_perf_tlb_first_req_time;
      perf_tlb_resp_time_q           <= in_perf_tlb_resp_time;
      dbg_seq_num_q                  <= in_dbg_seq_num;
      dbg_uop_idx_q                  <= in_dbg_uop_idx;
    end
  end

  // ---- 源操作数预处理：32 位操作（isW）按符号扩展到 64 位 ----
  wire op_is_w   = in_fu_op_type[2];
  wire op_signed = ~in_fu_op_type[1];
  wire [63:0] src0_ext =
    op_is_w ? {{32{op_signed & in_src0[31]}}, in_src0[31:0]} : in_src0;
  wire [63:0] src1_ext =
    op_is_w ? {{32{op_signed & in_src1[31]}}, in_src1[31:0]} : in_src1;

  // ---- flush 判定：level=1 要求索引相等；否则按新旧（flag 异或 value 大小）----
  wire [8:0] flush_idx      = {flush_rob_flag, flush_rob_value};
  wire       in_idx_equal   = {in_rob_flag, in_rob_value} == flush_idx;
  wire       in_older       = in_rob_flag ^ flush_rob_flag ^ (in_rob_value > flush_rob_value);
  wire       kill_waiting   = flush_valid & (flush_level & in_idx_equal | in_older);
  wire       held_idx_equal = {rob_flag_q, rob_value_q} == flush_idx;
  wire       held_older     = rob_flag_q ^ flush_rob_flag ^ (rob_value_q > flush_rob_value);
  wire       kill_running   =
    ~div_in_ready & flush_valid & (flush_level & held_idx_equal | held_older);

  SRT16DividerDataModule u_div (
    .clock        (clock),
    .reset        (reset),
    .io_src_0     (src0_ext),
    .io_src_1     (src1_ext),
    .io_valid     (in_valid),
    .io_sign      (op_signed),
    .io_kill_w    (kill_waiting),
    .io_kill_r    (kill_running),
    .io_isHi      (is_hi_q),
    .io_isW       (is_w_q),
    .io_in_ready  (div_in_ready),
    .io_out_valid (out_valid),
    .io_out_data  (out_res_data),
    .io_out_ready (out_ready)
  );

  assign in_ready                      = div_in_ready;
  assign out_rob_flag                  = out_rob_flag_q;
  assign out_rob_value                 = out_rob_value_q;
  assign out_pdest                     = out_pdest_q;
  assign out_rf_wen                    = out_rf_wen_q;
  assign out_perf_eliminated_move      = perf_eliminated_move_q;
  assign out_perf_rename_time          = perf_rename_time_q;
  assign out_perf_dispatch_time        = perf_dispatch_time_q;
  assign out_perf_enq_rs_time          = perf_enq_rs_time_q;
  assign out_perf_select_time          = perf_select_time_q;
  assign out_perf_issue_time           = perf_issue_time_q;
  assign out_perf_writeback_time       = perf_writeback_time_q;
  assign out_perf_runahead_checkpoint_id = perf_runahead_checkpoint_id_q;
  assign out_perf_tlb_first_req_time   = perf_tlb_first_req_time_q;
  assign out_perf_tlb_resp_time        = perf_tlb_resp_time_q;
  assign out_dbg_seq_num               = dbg_seq_num_q;
  assign out_dbg_uop_idx               = dbg_uop_idx_q;
endmodule

// BEGIN GENERATED(wrapper) —— scripts/gen_arithvec_leaves5.py 生成，勿手改
module DivUnit(
  input  clock,
  input  reset,
  input  io_flush_valid,
  input  io_flush_bits_robIdx_flag,
  input  [7:0] io_flush_bits_robIdx_value,
  input  io_flush_bits_level,
  output io_in_ready,
  input  io_in_valid,
  input  [8:0] io_in_bits_ctrl_fuOpType,
  input  io_in_bits_ctrl_robIdx_flag,
  input  [7:0] io_in_bits_ctrl_robIdx_value,
  input  [7:0] io_in_bits_ctrl_pdest,
  input  io_in_bits_ctrl_rfWen,
  input  [63:0] io_in_bits_data_src_1,
  input  [63:0] io_in_bits_data_src_0,
  input  io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0] io_in_bits_perfDebugInfo_renameTime,
  input  [63:0] io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  [63:0] io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0] io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0] io_in_bits_debug_seqNum_seqNum,
  input  [7:0] io_in_bits_debug_seqNum_uopIdx,
  input  io_out_ready,
  output io_out_valid,
  output io_out_bits_ctrl_robIdx_flag,
  output [7:0] io_out_bits_ctrl_robIdx_value,
  output [7:0] io_out_bits_ctrl_pdest,
  output io_out_bits_ctrl_rfWen,
  output [63:0] io_out_bits_res_data,
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

  xs_DivUnit_core u_core (
    .clock (clock),
    .reset (reset),
    .flush_valid (io_flush_valid),
    .flush_rob_flag (io_flush_bits_robIdx_flag),
    .flush_rob_value (io_flush_bits_robIdx_value),
    .flush_level (io_flush_bits_level),
    .in_ready (io_in_ready),
    .in_valid (io_in_valid),
    .in_fu_op_type (io_in_bits_ctrl_fuOpType),
    .in_rob_flag (io_in_bits_ctrl_robIdx_flag),
    .in_rob_value (io_in_bits_ctrl_robIdx_value),
    .in_pdest (io_in_bits_ctrl_pdest),
    .in_rf_wen (io_in_bits_ctrl_rfWen),
    .in_src0 (io_in_bits_data_src_0),
    .in_src1 (io_in_bits_data_src_1),
    .in_perf_eliminated_move (io_in_bits_perfDebugInfo_eliminatedMove),
    .in_perf_rename_time (io_in_bits_perfDebugInfo_renameTime),
    .in_perf_dispatch_time (io_in_bits_perfDebugInfo_dispatchTime),
    .in_perf_enq_rs_time (io_in_bits_perfDebugInfo_enqRsTime),
    .in_perf_select_time (io_in_bits_perfDebugInfo_selectTime),
    .in_perf_issue_time (io_in_bits_perfDebugInfo_issueTime),
    .in_perf_writeback_time (io_in_bits_perfDebugInfo_writebackTime),
    .in_perf_runahead_checkpoint_id (io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .in_perf_tlb_first_req_time (io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .in_perf_tlb_resp_time (io_in_bits_perfDebugInfo_tlbRespTime),
    .in_dbg_seq_num (io_in_bits_debug_seqNum_seqNum),
    .in_dbg_uop_idx (io_in_bits_debug_seqNum_uopIdx),
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_rob_flag (io_out_bits_ctrl_robIdx_flag),
    .out_rob_value (io_out_bits_ctrl_robIdx_value),
    .out_pdest (io_out_bits_ctrl_pdest),
    .out_rf_wen (io_out_bits_ctrl_rfWen),
    .out_res_data (io_out_bits_res_data),
    .out_perf_eliminated_move (io_out_bits_perfDebugInfo_eliminatedMove),
    .out_perf_rename_time (io_out_bits_perfDebugInfo_renameTime),
    .out_perf_dispatch_time (io_out_bits_perfDebugInfo_dispatchTime),
    .out_perf_enq_rs_time (io_out_bits_perfDebugInfo_enqRsTime),
    .out_perf_select_time (io_out_bits_perfDebugInfo_selectTime),
    .out_perf_issue_time (io_out_bits_perfDebugInfo_issueTime),
    .out_perf_writeback_time (io_out_bits_perfDebugInfo_writebackTime),
    .out_perf_runahead_checkpoint_id (io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .out_perf_tlb_first_req_time (io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .out_perf_tlb_resp_time (io_out_bits_perfDebugInfo_tlbRespTime),
    .out_dbg_seq_num (io_out_bits_debug_seqNum_seqNum),
    .out_dbg_uop_idx (io_out_bits_debug_seqNum_uopIdx)
  );
endmodule
// END GENERATED(wrapper)
