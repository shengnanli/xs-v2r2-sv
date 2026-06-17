// =============================================================================
//  DivUnit —— 整数除法功能单元（可读重写核 xs_DivUnit_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/backend/fu/wrapper/DivUnit.scala
//                （class DivUnit extends FuncUnit；非定长流水，多周期迭代）
//  类型/常量/纯函数集中在 divunit_pkg（见 divunit_pkg.sv 文件头）。
//
//  在后端中的位置：整数执行簇的一个 FU，承担 RV64 M 扩展的除法/取余
//    （div / divu / rem / remu 及其 W 变体 divw/divuw/remw/remuw）。
//
//  特点：与 MulUnit 的定长流水不同，除法是多周期、可迭代的（基-16 SRT），
//    每次发射要占用除法器若干拍才出结果，因此本 FU 是“非定长流水 FU”：
//      · 有真正的 in.ready / out.ready 握手（in.ready 来自除法器 in_ready）；
//      · 有 flush 端口：迭代途中若该指令被冲刷需要 kill 掉正在算的除法。
//
//  本核做的事（迭代除法阵列 SRT16DividerDataModule 当 golden 黑盒）：
//    (1) 译码 {isW,isHi,sign} + 字操作源扩展（符号处理，见 divunit_pkg）；
//    (2) in.fire 时锁存 robIdx/ctrl（迭代期间冲刷判定与输出控制透传用）；
//    (3) 计算 kill_w（请求拍即被冲刷）/ kill_r（已进入迭代后被冲刷）；
//    (4) connectNonPipedCtrlSingal：in.fire 时把输出控制/perf 打一拍寄存。
//
//  端口集合/命名与 golden DivUnit 完全一致，便于 wrapper 直通与 UT/FM 对齐。
// =============================================================================
module xs_DivUnit_core
  import divunit_pkg::*;
(
  input         clock,
  input         reset,
  // ---- 冲刷（io.flush）----
  input         io_flush_valid,
  input         io_flush_bits_robIdx_flag,
  input  [7:0]  io_flush_bits_robIdx_value,
  input         io_flush_bits_level,           // flushItself：是否冲刷自身 robIdx
  // ---- 发射输入（io.in，DecoupledIO）----
  output        io_in_ready,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input         io_in_bits_ctrl_robIdx_flag,
  input  [7:0]  io_in_bits_ctrl_robIdx_value,
  input  [7:0]  io_in_bits_ctrl_pdest,
  input         io_in_bits_ctrl_rfWen,
  input  [63:0] io_in_bits_data_src_1,
  input  [63:0] io_in_bits_data_src_0,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  // ---- 写回输出（io.out，DecoupledIO）----
  input         io_out_ready,
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
  //  译码 + 源扩展（符号处理）
  // ===========================================================================
  // 除法子操作（仅低 5bit 有效）：作为可读的“编码字典”，便于波形/调试对照指令名。
  div_op_e   div_op;
  assign div_op = div_op_e'(io_in_bits_ctrl_fuOpType[4:0]);

  div_ctrl_t ctrl;
  assign ctrl = decodeDivCtrl(io_in_bits_ctrl_fuOpType);

  // 字操作时按 sign 做 32→64 符/零扩展，否则原样（见 divunit_pkg::cvtDivSrc）。
  logic [XLEN-1:0] div_src0, div_src1;
  assign div_src0 = cvtDivSrc(ctrl.isW, ctrl.sign, io_in_bits_data_src_0);
  assign div_src1 = cvtDivSrc(ctrl.isW, ctrl.sign, io_in_bits_data_src_1);

  // 除法器握手：in.fire = in_ready & in_valid（in_ready 来自除法器）。
  logic div_in_ready;
  wire  in_fire = div_in_ready & io_in_valid;

  // ===========================================================================
  //  in.fire 锁存：迭代期间冲刷判定用的 robIdx + 控制
  // ===========================================================================
  //  除法器一旦接受一条指令就独占多拍。迭代期间若上游发来冲刷，需要判断“正在算的
  //  这条”是否该被杀掉，因此把它的 robIdx 与 {isW,isHi} 在 in.fire 时锁存下来。
  logic       robIdxReg_flag;
  logic [7:0] robIdxReg_value;
  logic       ctrlReg_isW;
  logic       ctrlReg_isHi;
  always @(posedge clock) begin
    if (in_fire) begin
      robIdxReg_flag  <= io_in_bits_ctrl_robIdx_flag;
      robIdxReg_value <= io_in_bits_ctrl_robIdx_value;
      ctrlReg_isW     <= ctrl.isW;
      ctrlReg_isHi    <= ctrl.isHi;
    end
  end

  // ===========================================================================
  //  冲刷判定：kill_w（请求拍）/ kill_r（迭代中）
  // ===========================================================================
  //  kill_w：本拍进来的请求指令是否被冲刷（用进来的 robIdx 判）。
  //  kill_r：除法器已忙（!in_ready 表示正在迭代）且已锁存的指令被冲刷。
  //          两者分别杀掉“将要进/已经在”除法器里的指令，避免冲刷后还写回脏结果。
  wire kill_w = robNeedFlush(io_flush_valid, io_flush_bits_level,
                             io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value,
                             io_in_bits_ctrl_robIdx_flag, io_in_bits_ctrl_robIdx_value);

  wire kill_r = ~div_in_ready &
                robNeedFlush(io_flush_valid, io_flush_bits_level,
                             io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value,
                             robIdxReg_flag, robIdxReg_value);

  // ===========================================================================
  //  黑盒迭代除法阵列：SRT16DividerDataModule（基-16 SRT 除法器）
  // ===========================================================================
  //  io_sign 直接用当拍 ctrl.sign（请求拍即决定有无符号）；isHi/isW 用锁存值
  //  （结果产出在迭代末尾，取余/字处理依据的是被接受那拍的控制）。
  SRT16DividerDataModule divDataModule (
    .clock        (clock),
    .reset        (reset),
    .io_src_0     (div_src0),
    .io_src_1     (div_src1),
    .io_valid     (io_in_valid),
    .io_sign      (ctrl.sign),
    .io_kill_w    (kill_w),
    .io_kill_r    (kill_r),
    .io_isHi      (ctrlReg_isHi),
    .io_isW       (ctrlReg_isW),
    .io_in_ready  (div_in_ready),
    .io_out_valid (io_out_valid),
    .io_out_data  (io_out_bits_res_data),
    .io_out_ready (io_out_ready)
  );

  assign io_in_ready = div_in_ready;

  // ===========================================================================
  //  connectNonPipedCtrlSingal：in.fire 时把输出控制 / perf 打一拍寄存
  // ===========================================================================
  //  非流水 FU 的输出控制不随每拍平移，而是在指令被接受那拍寄存一次，迭代期间保持，
  //  到结果出来时正好对应。这条副本与上面 robIdxReg/ctrlReg 是相互独立的寄存。
  logic       out_robIdx_flag_r;
  logic [7:0] out_robIdx_value_r;
  logic [7:0] out_pdest_r;
  logic       out_rfWen_r;
  logic [63:0] out_perf_enqRs_r, out_perf_select_r, out_perf_issue_r;
  always @(posedge clock) begin
    if (in_fire) begin
      out_robIdx_flag_r  <= io_in_bits_ctrl_robIdx_flag;
      out_robIdx_value_r <= io_in_bits_ctrl_robIdx_value;
      out_pdest_r        <= io_in_bits_ctrl_pdest;
      out_rfWen_r        <= io_in_bits_ctrl_rfWen;
      out_perf_enqRs_r   <= io_in_bits_perfDebugInfo_enqRsTime;
      out_perf_select_r  <= io_in_bits_perfDebugInfo_selectTime;
      out_perf_issue_r   <= io_in_bits_perfDebugInfo_issueTime;
    end
  end

  assign io_out_bits_ctrl_robIdx_flag  = out_robIdx_flag_r;
  assign io_out_bits_ctrl_robIdx_value = out_robIdx_value_r;
  assign io_out_bits_ctrl_pdest        = out_pdest_r;
  assign io_out_bits_ctrl_rfWen        = out_rfWen_r;
  assign io_out_bits_perfDebugInfo_enqRsTime  = out_perf_enqRs_r;
  assign io_out_bits_perfDebugInfo_selectTime = out_perf_select_r;
  assign io_out_bits_perfDebugInfo_issueTime  = out_perf_issue_r;

endmodule
