// =============================================================================
// xs_IntToFP_3_core —— 可读核, 对应 golden IntToFP_3 顶层胶合逻辑。
// -----------------------------------------------------------------------------
// IntToFP_3 是整数->浮点转换单元的三级流水外壳:
//   - 顶层本身只做 (a) valid 打两拍 (validVecThisFu_1/_2)
//                    (b) perfDebugInfo 打两拍 (perfVec_1/_2, 门控 io_in_valid /
//                        validVecThisFu_1)
//                    (c) 控制位 (robIdx/pdest/fpWen/wflags) 组合直通到 out(第2级
//                        的 validPipe/ctrlPipe 由上游 IssueQueue 侧对齐, 本层直通)
//                    (d) io_out_valid = validPipe_2 & validVecThisFu_2
//   - 真正的 int->fp 转换 datapath 在子模块 IntToFPDataModule dataModule 内
//     (prenorm/postnorm/rounding 递归), 本核例化 golden dataModule (白盒两侧对称
//      elaborate)。regEnables_0/_1 = validPipe_0/_1 与本级 valid 相与, 控制 pipe
//     寄存器更新时机 (省功耗)。
// -----------------------------------------------------------------------------
// FM: 本核 + golden IntToFPDataModule 及其整颗子树 (IntToFP/_1/_2 ->
//     prenorm(LZA/CLZ) + postnorm(RoundingUnit)) 两侧同 elaborate => strict FM
//     无黑盒。IntToFP_3 顶层胶合寄存器 (valid/perf 打拍) 受 FM 逐位验证。
// =============================================================================
module xs_IntToFP_3_core (
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [1:0]  io_in_bits_ctrl_fpu_typeTagOut,
  input         io_in_bits_ctrl_fpu_wflags,
  input  [1:0]  io_in_bits_ctrl_fpu_typ,
  input  [2:0]  io_in_bits_ctrl_fpu_rm,
  input         io_in_bits_ctrlPipe_2_robIdx_flag,
  input  [7:0]  io_in_bits_ctrlPipe_2_robIdx_value,
  input  [7:0]  io_in_bits_ctrlPipe_2_pdest,
  input         io_in_bits_ctrlPipe_2_fpWen,
  input         io_in_bits_ctrlPipe_2_fpu_wflags,
  input         io_in_bits_validPipe_0,
  input         io_in_bits_validPipe_1,
  input         io_in_bits_validPipe_2,
  input  [63:0] io_in_bits_data_src_0,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
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

  // ---- valid 打两拍 (异步 reset 清零) ----
  reg validVecThisFu_1;
  reg validVecThisFu_2;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      validVecThisFu_1 <= 1'h0;
      validVecThisFu_2 <= 1'h0;
    end
    else begin
      validVecThisFu_1 <= io_in_valid;
      validVecThisFu_2 <= validVecThisFu_1;
    end
  end

  // ---- perfDebugInfo 打两拍 (无 reset, 门控更新) ----
  reg [63:0] perfVec_1_enqRsTime;
  reg [63:0] perfVec_1_selectTime;
  reg [63:0] perfVec_1_issueTime;
  reg [63:0] perfVec_2_enqRsTime;
  reg [63:0] perfVec_2_selectTime;
  reg [63:0] perfVec_2_issueTime;
  always @(posedge clock) begin
    if (io_in_valid) begin
      perfVec_1_enqRsTime  <= io_in_bits_perfDebugInfo_enqRsTime;
      perfVec_1_selectTime <= io_in_bits_perfDebugInfo_selectTime;
      perfVec_1_issueTime  <= io_in_bits_perfDebugInfo_issueTime;
    end
    if (validVecThisFu_1) begin
      perfVec_2_enqRsTime  <= perfVec_1_enqRsTime;
      perfVec_2_selectTime <= perfVec_1_selectTime;
      perfVec_2_issueTime  <= perfVec_1_issueTime;
    end
  end

  // ---- int->fp 转换 datapath (golden 子模块, 两侧对称 elaborate) ----
  IntToFPDataModule dataModule (
    .clock                   (clock),
    .io_in_src_0             (io_in_bits_data_src_0),
    .io_in_fpCtrl_typeTagOut (io_in_bits_ctrl_fpu_typeTagOut),
    .io_in_fpCtrl_wflags     (io_in_bits_ctrl_fpu_wflags),
    .io_in_fpCtrl_typ        (io_in_bits_ctrl_fpu_typ),
    .io_in_fpCtrl_rm         (io_in_bits_ctrl_fpu_rm),
    .io_in_rm                (io_frm),
    .io_out_data             (io_out_bits_res_data),
    .io_out_fflags           (io_out_bits_res_fflags),
    .regEnables_0            (io_in_bits_validPipe_0 & io_in_valid),
    .regEnables_1            (io_in_bits_validPipe_1 & validVecThisFu_1)
  );

  // ---- 输出胶合 ----
  assign io_out_valid                        = io_in_bits_validPipe_2 & validVecThisFu_2;
  assign io_out_bits_ctrl_robIdx_flag        = io_in_bits_ctrlPipe_2_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value       = io_in_bits_ctrlPipe_2_robIdx_value;
  assign io_out_bits_ctrl_pdest              = io_in_bits_ctrlPipe_2_pdest;
  assign io_out_bits_ctrl_fpWen              = io_in_bits_ctrlPipe_2_fpWen;
  assign io_out_bits_ctrl_fpu_wflags         = io_in_bits_ctrlPipe_2_fpu_wflags;
  assign io_out_bits_perfDebugInfo_enqRsTime = perfVec_2_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime= perfVec_2_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime = perfVec_2_issueTime;

endmodule
