// ============================================================================
// FDivSqrt.sv —— 浮点除法/开方功能单元（ExeUnit_9 内）的 FloatDivider 包装层
//
// 在哪一层：后端浮点 ExeUnit_9 内部，把发射队列来的 fdiv/fsqrt 微操作包装后
//   喂给 FloatDivider（两侧共用同一份 golden 孩子）。
// IO：io_in_* 是发射口（valid/ready + fuOpType[0]=is_sqrt + fpu_fmt/fpu_rm +
//   两个 64 位源操作数 + robIdx/pdest/fpWen/wflags + perf/debug 随行 payload）；
//   io_out_* 是写回口（res_data/res_fflags + 打拍后的 payload）；io_frm 是
//   动态舍入模式（fuOpType 里 rm=7 时采用）；io_flush_* 按 robIdx 杀在途操作。
// 核心机制：
//   * 接受（in_valid & start_ready）那一拍把 robIdx/fmt 与全部输出 payload
//     整包打拍 —— 无复位（golden 原样）；
//   * flush 用的 robIdx 取「除法器空闲 ? 当前输入 : 锁存值」，结果 fmt 取
//     「接受拍 ? 当前输入 : 锁存值」（两者门控条件不同，golden 有意如此）；
//   * 窄格式（H/S）结果高位回填全 1（NaN-boxing）；输入侧反过来做
//     「非规范装箱」检测送给 FloatDivider（上游端口名叫 isFpCanonicalNAN，
//     实际为 1 表示高位不全 1，即**不是**规范装箱）。
//   * golden 在 `ifndef SYNTHESIS 下还有一条 fuOpType==9'hFF 的断言，
//     UT/FM 两侧均定义 SYNTHESIS，本重写不含（与 DecodeUnitComp 等先例一致）。
// ============================================================================

module xs_FDivSqrt_core (
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
  input  logic        in_fp_wen,
  input  logic        in_fpu_wflags,
  input  logic [1:0]  in_fpu_fmt,
  input  logic [2:0]  in_fpu_rm,
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
  output logic        out_fp_wen,
  output logic        out_fpu_wflags,
  output logic [63:0] out_res_data,
  output logic [4:0]  out_res_fflags,
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
  output logic [7:0]  out_dbg_uop_idx,
  input  logic [2:0]  frm
);
  wire        fdiv_start_ready;
  wire        fdiv_finish_valid;
  wire [63:0] fdiv_res;
  wire        in_fire = fdiv_start_ready & in_valid;

  // ---- 接受那一拍整包打拍：robIdx/fmt（flush 与结果装箱用）+ 全部 payload ----
  // 全部无复位，与 golden 的 always @(posedge clock) 单臂一致。
  logic        ctrl_rob_flag_q;
  logic [7:0]  ctrl_rob_value_q;
  logic [1:0]  ctrl_fmt_q;
  logic        out_rob_flag_q;
  logic [7:0]  out_rob_value_q;
  logic [7:0]  out_pdest_q;
  logic        out_fp_wen_q;
  logic        out_fpu_wflags_q;
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
    if (in_fire) begin
      ctrl_rob_flag_q                <= in_rob_flag;
      ctrl_rob_value_q               <= in_rob_value;
      ctrl_fmt_q                     <= in_fpu_fmt;
      out_rob_flag_q                 <= in_rob_flag;
      out_rob_value_q                <= in_rob_value;
      out_pdest_q                    <= in_pdest;
      out_fp_wen_q                   <= in_fp_wen;
      out_fpu_wflags_q               <= in_fpu_wflags;
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

  // ---- flush 用的 robIdx：除法器空闲（start_ready）时用当前输入，否则用锁存 ----
  wire       live_rob_flag  = fdiv_start_ready ? in_rob_flag  : ctrl_rob_flag_q;
  wire [7:0] live_rob_value = fdiv_start_ready ? in_rob_value : ctrl_rob_value_q;
  // ---- 结果装箱用的 fmt：只在「接受拍」用当前输入，其余用锁存 ----
  wire [1:0] result_fmt = in_fire ? in_fpu_fmt : ctrl_fmt_q;

  wire [8:0] flush_idx   = {flush_rob_flag, flush_rob_value};
  wire       idx_equal   = {live_rob_flag, live_rob_value} == flush_idx;
  wire       live_older  = live_rob_flag ^ flush_rob_flag ^ (live_rob_value > flush_rob_value);
  wire       flush_req   = flush_valid & (flush_level & idx_equal | live_older);

  // ---- NaN-boxing 检测：fmt=S(2) 要求高 32 位全 1、fmt=H(1) 要求高 48 位全 1；
  //      不全 1 时置位（端口名沿用上游，实际含义是「非规范装箱」）----
  wire fmt_is_h = in_fpu_fmt == 2'd1;
  wire fmt_is_s = in_fpu_fmt == 2'd2;
  wire opa_box_bad = fmt_is_s & (in_src0[63:32] != 32'hFFFF_FFFF)
                   | fmt_is_h & (in_src0[63:16] != 48'hFFFF_FFFF_FFFF);
  wire opb_box_bad = fmt_is_s & (in_src1[63:32] != 32'hFFFF_FFFF)
                   | fmt_is_h & (in_src1[63:16] != 48'hFFFF_FFFF_FFFF);

  // rm=7 是「动态」，取 io_frm
  wire [2:0] rm_sel = in_fpu_rm != 3'h7 ? in_fpu_rm : frm;

  FloatDivider u_fdiv (
    .clock                   (clock),
    .reset                   (reset),
    .io_start_valid_i        (in_valid),
    .io_start_ready_o        (fdiv_start_ready),
    .io_flush_i              (flush_req),
    .io_fp_format_i          (in_fpu_fmt),
    .io_opa_i                (in_src0),
    .io_opb_i                (in_src1),
    .io_is_sqrt_i            (in_fu_op_type[0]),
    .io_rm_i                 (rm_sel),
    .io_fp_aIsFpCanonicalNAN (opa_box_bad),
    .io_fp_bIsFpCanonicalNAN (opb_box_bad),
    .io_finish_valid_o       (fdiv_finish_valid),
    .io_finish_ready_i       (out_ready & fdiv_finish_valid),
    .io_fpdiv_res_o          (fdiv_res),
    .io_fflags_o             (out_res_fflags)
  );

  assign in_ready  = fdiv_start_ready;
  assign out_valid = fdiv_finish_valid;

  // ---- 结果按格式 NaN-boxing：H 回填高 48 位全 1、S 回填高 32 位全 1、D 直通 ----
  assign out_res_data =
      (result_fmt == 2'd1 ? {48'hFFFF_FFFF_FFFF, fdiv_res[15:0]} : 64'h0)
    | (result_fmt == 2'd2 ? {32'hFFFF_FFFF, fdiv_res[31:0]} : 64'h0)
    | ((&result_fmt) ? fdiv_res : 64'h0);

  assign out_rob_flag                  = out_rob_flag_q;
  assign out_rob_value                 = out_rob_value_q;
  assign out_pdest                     = out_pdest_q;
  assign out_fp_wen                    = out_fp_wen_q;
  assign out_fpu_wflags                = out_fpu_wflags_q;
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
module FDivSqrt(
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
  input  io_in_bits_ctrl_fpWen,
  input  io_in_bits_ctrl_fpu_wflags,
  input  [1:0] io_in_bits_ctrl_fpu_fmt,
  input  [2:0] io_in_bits_ctrl_fpu_rm,
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
  output io_out_bits_ctrl_fpWen,
  output io_out_bits_ctrl_fpu_wflags,
  output [63:0] io_out_bits_res_data,
  output [4:0] io_out_bits_res_fflags,
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
  output [7:0] io_out_bits_debug_seqNum_uopIdx,
  input  [2:0] io_frm
);

  xs_FDivSqrt_core u_core (
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
    .in_fp_wen (io_in_bits_ctrl_fpWen),
    .in_fpu_wflags (io_in_bits_ctrl_fpu_wflags),
    .in_fpu_fmt (io_in_bits_ctrl_fpu_fmt),
    .in_fpu_rm (io_in_bits_ctrl_fpu_rm),
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
    .out_fp_wen (io_out_bits_ctrl_fpWen),
    .out_fpu_wflags (io_out_bits_ctrl_fpu_wflags),
    .out_res_data (io_out_bits_res_data),
    .out_res_fflags (io_out_bits_res_fflags),
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
    .out_dbg_uop_idx (io_out_bits_debug_seqNum_uopIdx),
    .frm (io_frm)
  );
endmodule
// END GENERATED(wrapper)
