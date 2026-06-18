// =============================================================================
//  FCVT —— 浮点转换功能单元（可读重写核 xs_FCVT_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/backend/fu/wrapper/FCVT.scala
//                （class FCVT extends FpPipedFuncUnit, latency=2）
//  类型/常量/纯函数见 fcvt_pkg.sv。
//
//  在后端中的位置：浮点执行簇的一个 FU，承担标量浮点转换：
//    f2i / i2f / f2f(变宽/变窄) / fround / froundnx / fcvtmod / fmv_x_w/d。
//  真正转换在黑盒 FPCVT（2 拍内部流水）。
//
//  延迟与流水（HasPipelineReg, latency=2）：
//    · FPCVT 是 2 拍内部流水；控制/数据流水由 FU 外预打拍送入（validPipe_2/ctrlPipe_2）。
//    · 本 FU 维护本 FU 内部 valid 流水 2 级 + perf 流水 2 级；
//    · 另有几条与 FPCVT 同步的本地流水：
//        - outIs16bits / outIs32bits：输出宽度 one-hot 的 bit 经 2 级寄存器对齐到末级；
//        - result_r → result_r_1：fmv 指令的整数化结果旁路（不经 FPCVT），用
//          io_in_valid → fireReg_last_r 两级使能打到末级；
//        - fireReg_last_r：fire 的延迟有效，作为 result_r_1 的使能。
//    · 输出有效 = 外部 validPipe[2] & 本 FU valid[2]；输出控制取 ctrlPipe_2。
//
//  末级结果决策（按 ctrlPipe_2 的 opType / 宽度 / 整浮点）：
//    · fmv 指令 → 取旁路整数化结果 result_r_1；
//    · 32bit 浮点结果 → 高 32 位补 1（NaN-box）；16bit 浮点结果 → 高 48 位补 1；
//    · f2i 且 32bit 整数结果 → 低 32 位符号扩展回 64bit。
//  端口/命名与 golden FCVT 一致。
// =============================================================================
module xs_FCVT_core
  import fcvt_pkg::*;
(
  input         clock,
  input         reset,
  // ---- 发射输入（io.in）----
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input  [1:0]  io_in_bits_ctrl_fpu_fmt,           // sew
  input  [2:0]  io_in_bits_ctrl_fpu_rm,
  // 外部预打拍的第 2 级控制（输出端透传 + 末级结果决策依据）
  input  [8:0]  io_in_bits_ctrlPipe_2_fuOpType,
  input         io_in_bits_ctrlPipe_2_robIdx_flag,
  input  [7:0]  io_in_bits_ctrlPipe_2_robIdx_value,
  input  [7:0]  io_in_bits_ctrlPipe_2_pdest,
  input         io_in_bits_ctrlPipe_2_rfWen,
  input         io_in_bits_ctrlPipe_2_fpWen,
  input         io_in_bits_ctrlPipe_2_fpu_wflags,
  // 外部预打拍的 valid 流水
  input         io_in_bits_validPipe_2,
  // 源操作数（单源）
  input  [63:0] io_in_bits_data_src_0,
  // perf 调试信息
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
  input  [2:0]  io_frm
);

  // ===========================================================================
  //  S0：opType 译码 + 圆整模式 + 输出宽度 one-hot + fmv 整数化
  // ===========================================================================
  fp_fmt_e sew;
  assign sew = fp_fmt_e'(io_in_bits_ctrl_fpu_fmt);

  // 特例操作识别
  logic is_fround, is_froundnx, is_fcvtmod;
  assign is_fround   = (io_in_bits_ctrl_fuOpType == OP_FROUND);
  assign is_froundnx = (io_in_bits_ctrl_fuOpType == OP_FROUNDNX);
  assign is_fcvtmod  = (io_in_bits_ctrl_fuOpType == OP_FCVTMOD);

  // FCVT 专用圆整模式（rtz / rod / 常规）
  logic [2:0] cvt_rm;
  assign cvt_rm = cvtRoundMode(io_in_bits_ctrl_fuOpType, is_fcvtmod,
                               io_in_bits_ctrl_fpu_rm, io_frm);

  // 输出宽度 one-hot：widen = opType[4:3]
  logic [1:0] widen;
  assign widen = io_in_bits_ctrl_fuOpType[4:3];
  logic [3:0] output1H;
  assign output1H = decodeOutputWidth(widen, io_in_bits_ctrl_fpu_fmt);

  // fmv 整数化结果（按 sew 符号扩展），稍后打两拍旁路到末级。
  logic [63:0] fmv_int;
  assign fmv_int = fmvSext(sew, io_in_bits_data_src_0);

  // ===========================================================================
  //  本 FU 内部 valid 流水（2 级）+ fire 延迟有效
  // ===========================================================================
  logic vld_thisfu_1, vld_thisfu_2;
  logic fire_last;                     // fireReg_last_r：fire 的延迟有效（result_r_1 使能）
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      vld_thisfu_1 <= 1'b0;
      vld_thisfu_2 <= 1'b0;
      fire_last    <= 1'b0;
    end else begin
      vld_thisfu_1 <= io_in_valid;
      vld_thisfu_2 <= vld_thisfu_1;
      // 仅在「本拍 fire 或上拍 fire_last 有效」时更新，等价 GatedValidRegNext 的门控
      if (io_in_valid | fire_last) fire_last <= io_in_valid;
    end
  end

  // ===========================================================================
  //  perf 流水 + 输出宽度流水 + fmv 旁路流水（与 FPCVT 2 拍对齐）
  // ===========================================================================
  logic [63:0] perf_s1_enqRs, perf_s1_select, perf_s1_issue;
  logic [63:0] perf_s2_enqRs, perf_s2_select, perf_s2_issue;
  // 输出宽度 one-hot 的 16bit / 32bit 位，2 级寄存器打到末级
  logic outIs16bits_s1, outIs16bits;
  logic outIs32bits_s1, outIs32bits;
  // fmv 整数化结果旁路：result_r (en=io_in_valid) → result_r_1 (en=fire_last)
  logic [63:0] result_r, result_r_1;
  always @(posedge clock) begin
    if (io_in_valid) begin
      perf_s1_enqRs  <= io_in_bits_perfDebugInfo_enqRsTime;
      perf_s1_select <= io_in_bits_perfDebugInfo_selectTime;
      perf_s1_issue  <= io_in_bits_perfDebugInfo_issueTime;
      result_r       <= fmv_int;
    end
    if (vld_thisfu_1) begin
      perf_s2_enqRs  <= perf_s1_enqRs;
      perf_s2_select <= perf_s1_select;
      perf_s2_issue  <= perf_s1_issue;
    end
    // 输出宽度位：每拍无条件搬运（与 golden RegNext(RegNext(...)) 一致）
    outIs16bits_s1 <= output1H[1];
    outIs16bits    <= outIs16bits_s1;
    outIs32bits_s1 <= output1H[2];
    outIs32bits    <= outIs32bits_s1;
    if (fire_last) result_r_1 <= result_r;
  end

  // ===========================================================================
  //  黑盒浮点转换器 FPCVT（2 拍内部流水）
  // ===========================================================================
  logic [63:0] fcvt_result;
  logic [4:0]  fcvt_fflags;
  FPCVT fcvt (
    .clock     (clock),
    .reset     (reset),
    .io_fire   (io_in_valid),
    .io_src    (io_in_bits_data_src_0),
    .io_opType (io_in_bits_ctrl_fuOpType[7:0]),
    .io_sew    (io_in_bits_ctrl_fpu_fmt),
    .io_rm     (cvt_rm),
    .io_isFround ({is_froundnx, is_fround}),       // {froundnx, fround}
    .io_isFcvtmod (is_fcvtmod),
    .io_result (fcvt_result),
    .io_fflags (fcvt_fflags)
  );

  // ===========================================================================
  //  末级结果决策（依据 ctrlPipe_2 的 opType / 宽度 / 整浮点）
  // ===========================================================================
  // outIsInt：fuOpType[6]==0 表示输出是整数（f2i）；outIsMvInst：fmv_x_*。
  logic out_is_int, out_is_mv;
  assign out_is_int = ~io_in_bits_ctrlPipe_2_fuOpType[6];
  assign out_is_mv  = (io_in_bits_ctrlPipe_2_fuOpType == OP_FMVXF);

  // result：fmv → 旁路整数化；32bit 浮点 → 高 32 补 1；16bit 浮点 → 高 48 补 1；否则原值。
  logic [63:0] result;
  always_comb begin
    if (out_is_mv)
      result = result_r_1;
    else if (outIs32bits & ~out_is_int)            // 32bit 浮点结果 NaN-box
      result = {32'hFFFFFFFF, fcvt_result[31:0]};
    else if (outIs16bits & ~out_is_int)            // 16bit 浮点结果 NaN-box
      result = {48'hFFFFFFFFFFFF, fcvt_result[15:0]};
    else
      result = fcvt_result;
  end

  // 最终输出：f2i 且 32bit 整数 → 低 32 位符号扩展回 64bit；否则 result。
  logic is_f2i_32;
  assign is_f2i_32 = outIs32bits & out_is_int;
  assign io_out_bits_res_data = is_f2i_32 ? {{32{result[31]}}, result[31:0]} : result;

  // fflags：fmv 指令不产生异常标志（清 0）。
  assign io_out_bits_res_fflags = out_is_mv ? 5'h0 : fcvt_fflags;

  // ===========================================================================
  //  输出有效 / 控制透传
  // ===========================================================================
  assign io_out_valid = io_in_bits_validPipe_2 & vld_thisfu_2;

  assign io_out_bits_ctrl_robIdx_flag  = io_in_bits_ctrlPipe_2_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = io_in_bits_ctrlPipe_2_robIdx_value;
  assign io_out_bits_ctrl_pdest        = io_in_bits_ctrlPipe_2_pdest;
  assign io_out_bits_ctrl_rfWen        = io_in_bits_ctrlPipe_2_rfWen;
  assign io_out_bits_ctrl_fpWen        = io_in_bits_ctrlPipe_2_fpWen;
  assign io_out_bits_ctrl_fpu_wflags   = io_in_bits_ctrlPipe_2_fpu_wflags;

  assign io_out_bits_perfDebugInfo_enqRsTime  = perf_s2_enqRs;
  assign io_out_bits_perfDebugInfo_selectTime = perf_s2_select;
  assign io_out_bits_perfDebugInfo_issueTime  = perf_s2_issue;

endmodule
