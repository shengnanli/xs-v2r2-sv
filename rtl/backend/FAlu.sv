// =============================================================================
//  FAlu —— 浮点加法/比较功能单元（可读重写核 xs_FAlu_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/backend/fu/wrapper/FALU.scala
//                （class FAlu extends FpPipedFuncUnit, latency=1）
//  类型/常量/纯函数见 falu_pkg.sv。
//
//  在后端中的位置：浮点执行簇的一个 FU，承担标量浮点的
//    加/减/比较(feq/flt/fle...)/选最值(fmin/fmax)/符号注入(fsgnj*)/分类(fclass)/移动 等
//    （opType 由 fuOpType[4:0] 给到黑盒 FloatAdder 内部译码）。
//
//  延迟与流水（HasPipelineReg, latency=1）：
//    · FloatAdder 是 1 拍内部流水：本拍 io.in 直接喂入，结果下一拍出。
//    · 控制/数据流水(ctrlPipe/validPipe)由发射队列+数据通路在 FU 外预打拍送入；
//      本 FU 只额外维护「本 FU 内部 valid 流水」validVecThisFu_1（1 级）与 perf 流水。
//    · 输出有效 = 外部 validPipe[1] & 本 FU valid[1]；输出控制取 ctrlPipe[1]。
//    · 定长流水、无背压、不自管冲刷 → 无 in.ready / out.ready / flush。
//
//  本核做的事（其余是黑盒 FloatAdder 的活）：圆整模式选择、规范 NaN 检测、op_code 透传、
//  1 级 valid/perf 打拍、输出控制透传。端口/命名与 golden FAlu 一致。
// =============================================================================
module xs_FAlu_core
  import falu_pkg::*;
(
  input         clock,
  input         reset,
  // ---- 发射输入（io.in）----
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,          // 浮点子操作（低 5bit 给加法器）
  input  [1:0]  io_in_bits_ctrl_fpu_fmt,           // 浮点格式 fp_fmt
  input  [2:0]  io_in_bits_ctrl_fpu_rm,            // 指令携带圆整模式（7=动态→用 frm）
  // 外部预打拍的第 1 级控制（输出端透传）
  input         io_in_bits_ctrlPipe_1_robIdx_flag,
  input  [7:0]  io_in_bits_ctrlPipe_1_robIdx_value,
  input  [7:0]  io_in_bits_ctrlPipe_1_pdest,
  input         io_in_bits_ctrlPipe_1_rfWen,
  input         io_in_bits_ctrlPipe_1_fpWen,
  input         io_in_bits_ctrlPipe_1_fpu_wflags,
  // 外部预打拍的 valid 流水
  input         io_in_bits_validPipe_1,
  // 两个源操作数
  input  [63:0] io_in_bits_data_src_1,
  input  [63:0] io_in_bits_data_src_0,
  // perf 调试信息（随流水搬运，不参与运算）
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  // ---- 写回输出（io.out）----
  output        io_out_valid,
  output        io_out_bits_ctrl_robIdx_flag,
  output [7:0]  io_out_bits_ctrl_robIdx_value,
  output [7:0]  io_out_bits_ctrl_pdest,
  output        io_out_bits_ctrl_rfWen,
  output        io_out_bits_ctrl_fpWen,
  output        io_out_bits_ctrl_fpu_wflags,
  output [63:0] io_out_bits_res_data,
  output [4:0]  io_out_bits_res_fflags,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  // CSR 动态圆整模式
  input  [2:0]  io_frm
);

  // ===========================================================================
  //  S0：圆整模式 + 规范 NaN 检测（送黑盒加法器的控制）
  // ===========================================================================
  fp_fmt_e fmt;
  assign fmt = fp_fmt_e'(io_in_bits_ctrl_fpu_fmt);

  // rm：指令 rm==7(动态) → 用 CSR frm；否则用指令 rm。
  logic [2:0] round_mode;
  assign round_mode = selRoundMode(io_in_bits_ctrl_fpu_rm, io_frm);

  // 两源的 NaN-boxing 校验（高位非全 1 → 规范 NaN）。
  logic fp_a_canon_nan, fp_b_canon_nan;
  assign fp_a_canon_nan = isFpCanonicalNAN(fmt, io_in_bits_data_src_0);
  assign fp_b_canon_nan = isFpCanonicalNAN(fmt, io_in_bits_data_src_1);

  // ===========================================================================
  //  本 FU 内部 valid 流水（1 级，复位敏感）
  // ===========================================================================
  // 链路起点 io_in_valid；真正「某级是否搬运」要再与外部 validPipe 相与（见输出）。
  logic vld_thisfu_1;
  always @(posedge clock or posedge reset) begin
    if (reset) vld_thisfu_1 <= 1'b0;
    else       vld_thisfu_1 <= io_in_valid;
  end

  // ===========================================================================
  //  perf 调试信息流水（1 级，使能 io_in_valid；不参与运算）
  // ===========================================================================
  logic [63:0] perf_s1_enqRs, perf_s1_select, perf_s1_issue;
  always @(posedge clock) begin
    if (io_in_valid) begin
      perf_s1_enqRs  <= io_in_bits_perfDebugInfo_enqRsTime;
      perf_s1_select <= io_in_bits_perfDebugInfo_selectTime;
      perf_s1_issue  <= io_in_bits_perfDebugInfo_issueTime;
    end
  end

  // ===========================================================================
  //  黑盒浮点加法器 FloatAdder（1 拍内部流水）
  // ===========================================================================
  //  io_fire = io_in_valid（本拍发起）；结果 io_fp_result / io_fflags 下一拍稳定。
  FloatAdder falu (
    .clock                   (clock),
    .io_fire                 (io_in_valid),
    .io_fp_a                 (io_in_bits_data_src_0),
    .io_fp_b                 (io_in_bits_data_src_1),
    .io_round_mode           (round_mode),
    .io_fp_format            (io_in_bits_ctrl_fpu_fmt),
    .io_op_code              (io_in_bits_ctrl_fuOpType[4:0]),
    .io_fp_aIsFpCanonicalNAN (fp_a_canon_nan),
    .io_fp_bIsFpCanonicalNAN (fp_b_canon_nan),
    .io_fp_result            (io_out_bits_res_data),
    .io_fflags               (io_out_bits_res_fflags)
  );

  // ===========================================================================
  //  输出有效 / 控制透传
  // ===========================================================================
  assign io_out_valid = io_in_bits_validPipe_1 & vld_thisfu_1;

  assign io_out_bits_ctrl_robIdx_flag  = io_in_bits_ctrlPipe_1_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = io_in_bits_ctrlPipe_1_robIdx_value;
  assign io_out_bits_ctrl_pdest        = io_in_bits_ctrlPipe_1_pdest;
  assign io_out_bits_ctrl_rfWen        = io_in_bits_ctrlPipe_1_rfWen;
  assign io_out_bits_ctrl_fpWen        = io_in_bits_ctrlPipe_1_fpWen;
  assign io_out_bits_ctrl_fpu_wflags   = io_in_bits_ctrlPipe_1_fpu_wflags;

  assign io_out_bits_perfDebugInfo_enqRsTime  = perf_s1_enqRs;
  assign io_out_bits_perfDebugInfo_selectTime = perf_s1_select;
  assign io_out_bits_perfDebugInfo_issueTime  = perf_s1_issue;

endmodule
