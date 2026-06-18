// =============================================================================
//  FDivSqrt —— 浮点除/开方功能单元（可读重写核 xs_FDivSqrt_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/backend/fu/wrapper/FDivSqrt.scala
//                （class FDivSqrt extends FpNonPipedFuncUnit）
//  类型/常量/纯函数见 fdivsqrt_pkg.sv。
//
//  在后端中的位置：浮点执行簇里**唯一的非定长流水（迭代）浮点 FU**，承担 fdiv / fsqrt。
//  真正的迭代除法/开方在黑盒 FloatDivider 里（多拍，吞吐 <1）。因此本 FU 有完整握手与
//  flush（可被重定向冲刷正在进行的迭代）。
//
//  握手与生命周期（FpNonPipedFuncUnit）：
//    · 入：start_valid=io.in.valid；io.in.ready=start_ready（迭代器空闲才接受新请求）。
//    · 出：io.out.valid=finish_valid；finish_ready=io.out.ready & io.out.valid（出口握手成立）。
//    · 输出侧控制不像定长流水那样外部预打拍，而是本 FU 在 io.in.fire 那拍用 DataHoldBypass
//      锁存（robIdx/pdest/fpWen/wflags/fmt/perf），迭代结束写回时取锁存值。
//    · flush：用「当前正在处理的 robIdx」与重定向比较 needFlush（见 fdivsqrt_pkg.robNeedFlush）；
//      该 robIdx = io.in.fire 时取输入、否则取上次锁存（outCtrl）。
//
//  端口/命名与 golden FDivSqrt 一致。
// =============================================================================
module xs_FDivSqrt_core
  import fdivsqrt_pkg::*;
(
  input         clock,
  input         reset,
  // ---- 重定向冲刷 ----
  input         io_flush_valid,
  input         io_flush_bits_robIdx_flag,
  input  [7:0]  io_flush_bits_robIdx_value,
  input         io_flush_bits_level,
  // ---- 发射输入（io.in，带握手）----
  output        io_in_ready,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,          // [0]=is_sqrt
  input         io_in_bits_ctrl_robIdx_flag,
  input  [7:0]  io_in_bits_ctrl_robIdx_value,
  input  [7:0]  io_in_bits_ctrl_pdest,
  input         io_in_bits_ctrl_fpWen,
  input         io_in_bits_ctrl_fpu_wflags,
  input  [1:0]  io_in_bits_ctrl_fpu_fmt,
  input  [2:0]  io_in_bits_ctrl_fpu_rm,
  input  [63:0] io_in_bits_data_src_1,
  input  [63:0] io_in_bits_data_src_0,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  // ---- 写回输出（io.out，带握手）----
  input         io_out_ready,
  output        io_out_valid,
  output        io_out_bits_ctrl_robIdx_flag,
  output [7:0]  io_out_bits_ctrl_robIdx_value,
  output [7:0]  io_out_bits_ctrl_pdest,
  output        io_out_bits_ctrl_fpWen,
  output        io_out_bits_ctrl_fpu_wflags,
  output [63:0] io_out_bits_res_data,
  output [4:0]  io_out_bits_res_fflags,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  [2:0]  io_frm
);

  // ===========================================================================
  //  迭代器握手线
  // ===========================================================================
  logic div_start_ready, div_finish_valid;
  logic [63:0] div_res;

  // io.in.fire：本拍真正接受一条新的 div/sqrt（start_ready & in.valid）。
  logic in_fire;
  assign in_fire = div_start_ready & io_in_valid;

  assign io_in_ready  = div_start_ready;
  assign io_out_valid = div_finish_valid;

  // ===========================================================================
  //  输出侧控制锁存（DataHoldBypass：io.in.fire 锁存，迭代结束写回取锁存值）
  // ===========================================================================
  // robIdx/pdest/fpWen/wflags/fmt/perf 都在接受请求那拍记下，因为迭代要跑多拍，
  // 期间输入端口可能已变（或在处理下一条的等待态）。
  logic        out_robIdx_flag;
  logic [7:0]  out_robIdx_value;
  logic [7:0]  out_pdest;
  logic        out_fpWen;
  logic        out_wflags;
  logic [1:0]  out_fmt_r;
  logic [63:0] out_perf_enqRs, out_perf_select, out_perf_issue;
  always @(posedge clock) begin
    if (in_fire) begin
      out_robIdx_flag  <= io_in_bits_ctrl_robIdx_flag;
      out_robIdx_value <= io_in_bits_ctrl_robIdx_value;
      out_pdest        <= io_in_bits_ctrl_pdest;
      out_fpWen        <= io_in_bits_ctrl_fpWen;
      out_wflags       <= io_in_bits_ctrl_fpu_wflags;
      out_fmt_r        <= io_in_bits_ctrl_fpu_fmt;
      out_perf_enqRs   <= io_in_bits_perfDebugInfo_enqRsTime;
      out_perf_select  <= io_in_bits_perfDebugInfo_selectTime;
      out_perf_issue   <= io_in_bits_perfDebugInfo_issueTime;
    end
  end

  // DataHoldBypass 的组合旁路：io.in.fire 当拍直接看到输入，否则看锁存值。
  // 输出结果的 fmt 选择用它（这样接受请求的当拍也能正确组合出 fmt）。
  fp_fmt_e out_fmt;
  assign out_fmt = fp_fmt_e'(in_fire ? io_in_bits_ctrl_fpu_fmt : out_fmt_r);

  // ===========================================================================
  //  flush 判定：当前正在处理的 robIdx vs 重定向
  // ===========================================================================
  // 正在处理的 robIdx = io.in.fire 取输入、否则取锁存（即当前占用迭代器那条指令）。
  logic        this_robIdx_flag;
  logic [7:0]  this_robIdx_value;
  assign this_robIdx_flag  = in_fire ? io_in_bits_ctrl_robIdx_flag  : out_robIdx_flag;
  assign this_robIdx_value = in_fire ? io_in_bits_ctrl_robIdx_value : out_robIdx_value;

  logic div_flush;
  assign div_flush = robNeedFlush(io_flush_valid, io_flush_bits_level,
                                  io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value,
                                  this_robIdx_flag, this_robIdx_value);

  // ===========================================================================
  //  rm + 两源 NaN 检测（送迭代器）
  // ===========================================================================
  fp_fmt_e in_fmt;
  assign in_fmt = fp_fmt_e'(io_in_bits_ctrl_fpu_fmt);

  logic [2:0] round_mode;
  assign round_mode = selRoundMode(io_in_bits_ctrl_fpu_rm, io_frm);

  logic fp_a_canon_nan, fp_b_canon_nan;
  assign fp_a_canon_nan = isFpCanonicalNAN(in_fmt, io_in_bits_data_src_0);
  assign fp_b_canon_nan = isFpCanonicalNAN(in_fmt, io_in_bits_data_src_1);

  // ===========================================================================
  //  黑盒迭代除/开方器 FloatDivider
  // ===========================================================================
  FloatDivider fdiv (
    .clock                   (clock),
    .reset                   (reset),
    .io_start_valid_i        (io_in_valid),
    .io_start_ready_o        (div_start_ready),
    .io_flush_i              (div_flush),
    .io_fp_format_i          (io_in_bits_ctrl_fpu_fmt),
    .io_opa_i                (io_in_bits_data_src_0),
    .io_opb_i                (io_in_bits_data_src_1),
    .io_is_sqrt_i            (io_in_bits_ctrl_fuOpType[0]),
    .io_rm_i                 (round_mode),
    .io_fp_aIsFpCanonicalNAN (fp_a_canon_nan),
    .io_fp_bIsFpCanonicalNAN (fp_b_canon_nan),
    .io_finish_valid_o       (div_finish_valid),
    .io_finish_ready_i       (io_out_ready & div_finish_valid),
    .io_fpdiv_res_o          (div_res),
    .io_fflags_o             (io_out_bits_res_fflags)
  );

  // ===========================================================================
  //  输出：控制取锁存值；结果按输出 fmt 做 NaN-box
  // ===========================================================================
  assign io_out_bits_ctrl_robIdx_flag  = out_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = out_robIdx_value;
  assign io_out_bits_ctrl_pdest        = out_pdest;
  assign io_out_bits_ctrl_fpWen        = out_fpWen;
  assign io_out_bits_ctrl_fpu_wflags   = out_wflags;

  assign io_out_bits_res_data = boxResult(out_fmt, div_res);

  assign io_out_bits_perfDebugInfo_enqRsTime  = out_perf_enqRs;
  assign io_out_bits_perfDebugInfo_selectTime = out_perf_select;
  assign io_out_bits_perfDebugInfo_issueTime  = out_perf_issue;

endmodule
