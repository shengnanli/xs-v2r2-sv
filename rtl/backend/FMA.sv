// =============================================================================
//  FMA —— 浮点乘加功能单元（可读重写核 xs_FMA_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/backend/fu/wrapper/FMA.scala
//                （class FMA extends FpPipedFuncUnit, latency=3）
//  类型/常量/纯函数见 fma_pkg.sv。
//
//  在后端中的位置：浮点执行簇的一个 FU，承担标量浮点乘加 a*b±c
//    （fmadd/fmsub/fnmadd/fnmsub）与纯乘 fmul。真正乘加阵列在黑盒 FloatFMA（3 拍流水）。
//
//  延迟与流水（HasPipelineReg, latency=3）：
//    · FloatFMA 是 3 拍内部流水；控制/数据流水由 FU 外预打拍送入（validPipe_3/ctrlPipe_3）。
//    · 本 FU 维护「本 FU 内部 valid 流水」3 级（validVecThisFu_1..3）与 perf 流水 3 级。
//    · 输出有效 = 外部 validPipe[3] & 本 FU valid[3]；输出控制取 ctrlPipe[3]。
//    · 定长流水、无背压、不自管冲刷 → 无 in.ready / out.ready / flush。
//
//  本核做的事（其余是黑盒 FloatFMA 的活）：rm 选择、三源 NaN 检测（c 源额外乘非纯乘）、
//  op_code 透传、3 级 valid/perf 打拍、输出控制透传。端口/命名与 golden FMA 一致。
// =============================================================================
module xs_FMA_core
  import fma_pkg::*;
(
  input         clock,
  input         reset,
  // ---- 发射输入（io.in）----
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,          // 乘加子操作（低 4bit 给阵列）
  input  [1:0]  io_in_bits_ctrl_fpu_fmt,
  input  [2:0]  io_in_bits_ctrl_fpu_rm,
  // 外部预打拍的第 3 级控制（输出端透传）
  input         io_in_bits_ctrlPipe_3_robIdx_flag,
  input  [7:0]  io_in_bits_ctrlPipe_3_robIdx_value,
  input  [7:0]  io_in_bits_ctrlPipe_3_pdest,
  input         io_in_bits_ctrlPipe_3_fpWen,
  input         io_in_bits_ctrlPipe_3_fpu_wflags,
  // 外部预打拍的 valid 流水
  input         io_in_bits_validPipe_3,
  // 三个源操作数 a*b±c
  input  [63:0] io_in_bits_data_src_2,             // c
  input  [63:0] io_in_bits_data_src_1,             // b
  input  [63:0] io_in_bits_data_src_0,             // a
  // perf 调试信息
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  // ---- 写回输出（io.out）----
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
  //  S0：rm + 三源规范 NaN 检测
  // ===========================================================================
  fp_fmt_e fmt;
  assign fmt = fp_fmt_e'(io_in_bits_ctrl_fpu_fmt);

  logic [2:0] round_mode;
  assign round_mode = selRoundMode(io_in_bits_ctrl_fpu_rm, io_frm);

  logic [3:0] opcode4;
  assign opcode4 = io_in_bits_ctrl_fuOpType[3:0];

  // a / b 源恒做 NaN-box 检测；c 源仅在「非纯乘」时检测（纯乘 fmul 不读 c）。
  logic fp_a_canon_nan, fp_b_canon_nan, fp_c_canon_nan;
  assign fp_a_canon_nan = isFpCanonicalNAN(fmt, io_in_bits_data_src_0);
  assign fp_b_canon_nan = isFpCanonicalNAN(fmt, io_in_bits_data_src_1);
  assign fp_c_canon_nan = ~isVfmul(opcode4) & isFpCanonicalNAN(fmt, io_in_bits_data_src_2);

  // ===========================================================================
  //  本 FU 内部 valid 流水（3 级，复位敏感）
  // ===========================================================================
  logic vld_thisfu_1, vld_thisfu_2, vld_thisfu_3;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      vld_thisfu_1 <= 1'b0;
      vld_thisfu_2 <= 1'b0;
      vld_thisfu_3 <= 1'b0;
    end else begin
      vld_thisfu_1 <= io_in_valid;
      vld_thisfu_2 <= vld_thisfu_1;
      vld_thisfu_3 <= vld_thisfu_2;
    end
  end

  // ===========================================================================
  //  perf 调试信息流水（3 级；使能用本 FU valid，不与外部 validPipe）
  // ===========================================================================
  logic [63:0] perf_s1_enqRs, perf_s1_select, perf_s1_issue;
  logic [63:0] perf_s2_enqRs, perf_s2_select, perf_s2_issue;
  logic [63:0] perf_s3_enqRs, perf_s3_select, perf_s3_issue;
  always @(posedge clock) begin
    if (io_in_valid) begin
      perf_s1_enqRs  <= io_in_bits_perfDebugInfo_enqRsTime;
      perf_s1_select <= io_in_bits_perfDebugInfo_selectTime;
      perf_s1_issue  <= io_in_bits_perfDebugInfo_issueTime;
    end
    if (vld_thisfu_1) begin
      perf_s2_enqRs  <= perf_s1_enqRs;
      perf_s2_select <= perf_s1_select;
      perf_s2_issue  <= perf_s1_issue;
    end
    if (vld_thisfu_2) begin
      perf_s3_enqRs  <= perf_s2_enqRs;
      perf_s3_select <= perf_s2_select;
      perf_s3_issue  <= perf_s2_issue;
    end
  end

  // ===========================================================================
  //  黑盒浮点乘加阵列 FloatFMA（3 拍内部流水）
  // ===========================================================================
  FloatFMA fma (
    .clock                   (clock),
    .reset                   (reset),
    .io_fire                 (io_in_valid),
    .io_fp_a                 (io_in_bits_data_src_0),
    .io_fp_b                 (io_in_bits_data_src_1),
    .io_fp_c                 (io_in_bits_data_src_2),
    .io_round_mode           (round_mode),
    .io_fp_format            (io_in_bits_ctrl_fpu_fmt),
    .io_op_code              (opcode4),
    .io_fp_result            (io_out_bits_res_data),
    .io_fflags               (io_out_bits_res_fflags),
    .io_fp_aIsFpCanonicalNAN (fp_a_canon_nan),
    .io_fp_bIsFpCanonicalNAN (fp_b_canon_nan),
    .io_fp_cIsFpCanonicalNAN (fp_c_canon_nan)
  );

  // ===========================================================================
  //  输出有效 / 控制透传
  // ===========================================================================
  assign io_out_valid = io_in_bits_validPipe_3 & vld_thisfu_3;

  assign io_out_bits_ctrl_robIdx_flag  = io_in_bits_ctrlPipe_3_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = io_in_bits_ctrlPipe_3_robIdx_value;
  assign io_out_bits_ctrl_pdest        = io_in_bits_ctrlPipe_3_pdest;
  assign io_out_bits_ctrl_fpWen        = io_in_bits_ctrlPipe_3_fpWen;
  assign io_out_bits_ctrl_fpu_wflags   = io_in_bits_ctrlPipe_3_fpu_wflags;

  assign io_out_bits_perfDebugInfo_enqRsTime  = perf_s3_enqRs;
  assign io_out_bits_perfDebugInfo_selectTime = perf_s3_select;
  assign io_out_bits_perfDebugInfo_issueTime  = perf_s3_issue;

endmodule
