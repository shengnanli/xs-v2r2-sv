// =============================================================================
//  MulUnit —— 整数乘法功能单元（可读重写核 xs_MulUnit_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/backend/fu/wrapper/MulUnit.scala
//                （class MulUnit extends FuncUnit with HasPipelineReg, latency=2）
//  类型/常量/纯函数集中在 mulunit_pkg（见 mulunit_pkg.sv 文件头）。
//
//  在后端中的位置：属于整数执行簇的一个 FU，承担 RV64 M 扩展的乘法
//    （mul / mulh / mulhsu / mulhu / mulw / mulw7）。是 2 拍定长流水（piped FU）。
//
//  与上下游关系（HasPipelineReg 的流水模型，见 FuncUnit.scala）：
//    · 控制/数据流水 (ctrlPipe / validPipe) 由发射队列+数据通路在 FU 外预先打好拍，
//      逐拍随阵列时延平移送进来；本 FU 只额外维护一条“本 FU 内部 valid 流水”
//      (validVecThisFu) 与 perf 调试信息流水，并用二者的与作为阵列各级寄存器使能。
//    · 因此本 FU 没有 in.ready / out.ready / flush 端口（定长流水、无背压、不自管冲刷）；
//      输出有效 = 外部 validPipe[2] & 本 FU 内部 valid[2]，输出控制取 ctrlPipe[2]。
//
//  本核做的三件事（其余是黑盒乘法阵列 ArrayMulDataModule 的活）：
//    (1) 译码 + 符号扩展：由 fuOpType 译出乘法子操作，把两源扩到 65bit（见 mulunit_pkg）。
//    (2) 控制流水：把 {isW,isHi} 随阵列 2 拍时延打拍（regEnable = validVec[i]）。
//    (3) 结果选择：按末级 {isHi,isW} 从 130bit 乘积选高/低半并做 W 符号扩展。
//
//  端口集合/命名与 golden MulUnit 完全一致，便于 wrapper 直通与 UT/FM 对齐。
// =============================================================================
module xs_MulUnit_core
  import mulunit_pkg::*;
(
  input         clock,
  input         reset,
  // ---- 发射输入（io.in）：本 FU 仅用到下列字段 ----
  input         io_in_valid,                       // 本拍发射有效（s0）
  input  [8:0]  io_in_bits_ctrl_fuOpType,          // 乘法子操作编码
  // 外部预打拍的第 2 级控制（用于输出端透传 robIdx/pdest/rfWen）
  input         io_in_bits_ctrlPipe_2_robIdx_flag,
  input  [7:0]  io_in_bits_ctrlPipe_2_robIdx_value,
  input  [7:0]  io_in_bits_ctrlPipe_2_pdest,
  input         io_in_bits_ctrlPipe_2_rfWen,
  // 外部预打拍的 valid 流水（与本 FU 内部 valid 相与）
  input         io_in_bits_validPipe_0,
  input         io_in_bits_validPipe_1,
  input         io_in_bits_validPipe_2,
  // 两个源操作数
  input  [63:0] io_in_bits_data_src_1,
  input  [63:0] io_in_bits_data_src_0,
  // perf 调试信息（随流水一同搬运，不参与运算）
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  // ---- 写回输出（io.out）----
  output        io_out_valid,
  output        io_out_bits_ctrl_robIdx_flag,
  output [7:0]  io_out_bits_ctrl_robIdx_value,
  output [7:0]  io_out_bits_ctrl_pdest,
  output        io_out_bits_ctrl_rfWen,
  output [63:0] io_out_bits_res_data,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime
);

  // ===========================================================================
  //  S0：译码 + 符号扩展 + 内部 valid 流水
  // ===========================================================================
  // 乘法子操作（mul/mulh/mulhsu/mulhu/mulw7）
  mul_op_e op;
  assign op = getMulOp(io_in_bits_ctrl_fuOpType);

  // 两源按子操作扩到 65bit（符号处理见 mulunit_pkg::cvtMulA/B）
  logic [MUL_LEN-1:0] mul_a, mul_b;
  assign mul_a = cvtMulA(op, io_in_bits_data_src_0);
  assign mul_b = cvtMulB(op, io_in_bits_data_src_1);

  // 本 FU 内部 valid 流水：仅复位敏感的两级寄存器，链路起点是 io_in_valid。
  // 真正的“某级是否搬运”要再和外部 validPipe 相与（见下）。
  logic vld_thisfu_1, vld_thisfu_2;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      vld_thisfu_1 <= 1'b0;
      vld_thisfu_2 <= 1'b0;
    end else begin
      vld_thisfu_1 <= io_in_valid;
      vld_thisfu_2 <= vld_thisfu_1;
    end
  end

  // 各级“真实有效” = 外部 validPipe[i] & 本 FU 内部 valid[i]。
  // regEnable(i) = validVec[i-1]：阵列与控制流水第 i 级的寄存器使能。
  logic [1:0] valid_vec;                  // valid_vec[0] = s0, [1] = s1
  assign valid_vec[0] = io_in_bits_validPipe_0 & io_in_valid;
  assign valid_vec[1] = io_in_bits_validPipe_1 & vld_thisfu_1;

  // ===========================================================================
  //  S0→S2：控制 {isW,isHi} 流水（与阵列 2 拍时延对齐）
  // ===========================================================================
  // s0 译出当拍控制；随后两级在 valid_vec[i] 使能时逐级搬运，
  // 使 s2 末级用的是“当初发起该乘法的那条指令”的控制位。
  mul_ctrl_t ctrl_s0;
  assign ctrl_s0 = decodeMulCtrl(io_in_bits_ctrl_fuOpType);

  mul_ctrl_t ctrl_s1, ctrl_s2;
  always @(posedge clock) begin
    if (valid_vec[0]) ctrl_s1 <= ctrl_s0;   // regEnable(1)
    if (valid_vec[1]) ctrl_s2 <= ctrl_s1;   // regEnable(2)
  end

  // ===========================================================================
  //  perf 调试信息流水（与控制同步，2 级；不参与运算）
  // ===========================================================================
  // 注意 golden 的 perf 流水使能用的是 io_in_valid / vld_thisfu_1（未与外部 validPipe），
  // 与控制流水的使能略有不同，这里保持一致以严格等价。
  logic [63:0] perf_s1_enqRs, perf_s1_select, perf_s1_issue;
  logic [63:0] perf_s2_enqRs, perf_s2_select, perf_s2_issue;
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
  end

  // ===========================================================================
  //  黑盒乘法阵列：ArrayMulDataModule（2 级流水的部分积压缩 + 进位传播加法）
  // ===========================================================================
  // io_a/io_b 为 65bit 扩展后的源；io_regEnables_{0,1} 是阵列两级寄存器使能；
  // io_result 为 130bit 全宽乘积（高/低半由 selMulHiLo 选取）。
  logic [RES_LEN-1:0] mul_result;
  ArrayMulDataModule mulDataModule (
    .clock           (clock),
    .io_a            (mul_a),
    .io_b            (mul_b),
    .io_regEnables_0 (valid_vec[0]),
    .io_regEnables_1 (valid_vec[1]),
    .io_result       (mul_result)
  );

  // ===========================================================================
  //  S2：结果选择（按末级 isHi 选高/低半，再按 isW 做 W 符号扩展）
  // ===========================================================================
  logic [XLEN-1:0] res_hilo;
  assign res_hilo = selMulHiLo(ctrl_s2.isHi, mul_result);
  assign io_out_bits_res_data = finalMulRes(ctrl_s2.isW, res_hilo);

  // ===========================================================================
  //  输出有效 / 控制透传
  // ===========================================================================
  // 输出有效 = 外部 validPipe[2] & 本 FU 内部 valid[2]。
  assign io_out_valid = io_in_bits_validPipe_2 & vld_thisfu_2;

  // 输出控制位直接取外部第 2 级流水（robIdx/pdest/rfWen），本 FU 不另打拍。
  assign io_out_bits_ctrl_robIdx_flag  = io_in_bits_ctrlPipe_2_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = io_in_bits_ctrlPipe_2_robIdx_value;
  assign io_out_bits_ctrl_pdest        = io_in_bits_ctrlPipe_2_pdest;
  assign io_out_bits_ctrl_rfWen        = io_in_bits_ctrlPipe_2_rfWen;

  assign io_out_bits_perfDebugInfo_enqRsTime  = perf_s2_enqRs;
  assign io_out_bits_perfDebugInfo_selectTime = perf_s2_select;
  assign io_out_bits_perfDebugInfo_issueTime  = perf_s2_issue;

endmodule
