// =============================================================================
// IntToFP_3 —— 整数 → 浮点功能单元 i2f（FPUPipelineModule，latency = 2）
// -----------------------------------------------------------------------------
// 设计源：src/main/scala/xiangshan/backend/fu/fpu/IntToFP.scala（class IntToFP）
//   + FPUPipelineModule / PipedFuncUnit 的流水控制（valid 移位链、反压链、payload 打拍）。
// 在哪一层：ExeUnit_5（整数 IQ 的 alu/brh/jmp/i2f/vset/i2v 混合执行单元）里的 i2f；
//   覆盖 fcvt.{s,d,h}.{w,wu,l,lu}（真转换）与 fmv.{w,d,h}.x（搬位，wflags=0）。
// 真正的运算在 IntToFPDataModule（已签核重写件，两侧白盒）：本层不碰数据，只做三件事 ——
//   §1 本 FU 的 valid 移位链 vldThisFu[1..2] 与反压链 rdy[0..2]；
//   §2 给数据模块两级寄存器的使能：regEnables(k) = validPipe(k) & 第 k 级 valid & rdy(k)；
//   §3 perfDebugInfo / debug.seqNum 两个调试 payload 随流水打两拍。
//   写回控制字段（robIdx / pdest / fpWen / wflags）不在本层打拍：发射侧已经按 2 拍延迟
//   预打好 ctrlPipe(2)，本层原样转发；写回有效 = validPipe(2) & vldThisFu[2]。
// ★与 FCVT 同一个怪癖（照抄 golden，bug-for-bug）★：valid 移位链没有 ready 门控
//   （validVecThisFu_1 <= io_in_valid），payload 寄存器却按 fire 门控。ExeUnit_5 里 i2f 的
//   io_out_ready 接的是 ExeUnit 的 out.ready，若真会拉低，valid 与 payload 会错相；
//   在当前连接下观测不到，本工程要求一致，不加门控。
// 复位：只有 valid 链异步复位；payload 与数据模块寄存器都不复位。
// golden 对照：G1-canonical/golden-rtl/IntToFP_3.sv
// =============================================================================
package xs_IntToFP_3_pkg;

  // 本 FU 的流水级数：io.in 这拍进，2 拍后写回
  localparam int unsigned LAT = 2;

  // 随流水搬运的调试 / 性能采样信息（10 个字段）
  typedef struct packed {
    logic        eliminatedMove;
    logic [63:0] renameTime;
    logic [63:0] dispatchTime;
    logic [63:0] enqRsTime;
    logic [63:0] selectTime;
    logic [63:0] issueTime;
    logic [63:0] writebackTime;
    logic [63:0] runahead_checkpoint_id;
    logic [63:0] tlbFirstReqTime;
    logic [63:0] tlbRespTime;
  } perf_dbg_t;

  // 指令序号追踪
  typedef struct packed {
    logic [55:0] seqNum;
    logic [7:0]  uopIdx;
  } seq_num_t;

  // 写回端口上的控制信息（取发射侧预打好的 ctrlPipe(2)）
  typedef struct packed {
    logic       robIdx_flag;
    logic [7:0] robIdx_value;
    logic [7:0] pdest;
    logic       fpWen;
    logic       fpu_wflags;
  } wb_ctrl_t;

  // 第 0 拍的浮点控制（送数据模块）
  typedef struct packed {
    logic [1:0] typeTagOut;   // 目的格式：0=f32 1=f64 2=f16
    logic       wflags;       // 1=真转换（更新 fflags）  0=fmv 搬位
    logic [1:0] typ;          // 源：[1]=64 位  [0]=无符号
    logic [2:0] rm;           // 指令 rm（111=动态，取 frm）
  } fp_ctrl_t;

endpackage

// =============================================================================
//  可读核
// =============================================================================
module xs_IntToFP_3_core
  import xs_IntToFP_3_pkg::*;
(
  input  logic        clock,
  input  logic        reset,

  // ---- io.in ----------------------------------------------------------------
  output logic        io_in_ready,
  input  logic        io_in_valid,
  input  fp_ctrl_t    io_in_fp_ctrl,
  input  wb_ctrl_t    io_in_ctrlPipe,        // = golden ctrlPipe_2
  input  logic [LAT:0] io_in_validPipe,      // = golden validPipe_0..2
  input  logic [63:0] io_in_src_0,
  input  perf_dbg_t   io_in_perfDebugInfo,
  input  seq_num_t    io_in_debug_seqNum,

  // ---- io.out ---------------------------------------------------------------
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output wb_ctrl_t    io_out_ctrl,
  output logic [63:0] io_out_res_data,
  output logic [4:0]  io_out_res_fflags,
  output perf_dbg_t   io_out_perfDebugInfo,
  output seq_num_t    io_out_debug_seqNum,

  // ---- CSR ------------------------------------------------------------------
  input  logic [2:0]  io_frm
);

  // ===========================================================================
  //  §1 valid 移位链 + 反压链
  // ===========================================================================
  // vldThisFu[s] = 「s 拍前本 FU 接了一个请求」；rdy[s] = 第 s 级能否接新活
  logic [LAT:1] vldThisFu;
  logic [LAT:0] rdy;

  always_comb begin
    rdy[LAT] = io_out_ready;
    for (int s = LAT - 1; s >= 0; s--) rdy[s] = ~vldThisFu[s+1] | rdy[s+1];
  end
  assign io_in_ready = rdy[0];

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      vldThisFu <= '0;
    else begin
      vldThisFu[1] <= io_in_valid;                                    // 无 ready 门控（见文件头）
      for (int s = 2; s <= LAT; s++) vldThisFu[s] <= vldThisFu[s-1];
    end
  end

  // ===========================================================================
  //  §2 数据模块：两级寄存器使能 = 外部 validPipe(k) & 本级 valid & 本级 ready
  // ===========================================================================
  logic [LAT-1:0] regEn;
  assign regEn[0] = io_in_validPipe[0] & io_in_valid  & rdy[0];
  assign regEn[1] = io_in_validPipe[1] & vldThisFu[1] & rdy[1];

  IntToFPDataModule dataModule (
    .clock                   (clock),
    .io_in_src_0             (io_in_src_0),
    .io_in_fpCtrl_typeTagOut (io_in_fp_ctrl.typeTagOut),
    .io_in_fpCtrl_wflags     (io_in_fp_ctrl.wflags),
    .io_in_fpCtrl_typ        (io_in_fp_ctrl.typ),
    .io_in_fpCtrl_rm         (io_in_fp_ctrl.rm),
    .io_in_rm                (io_frm),
    .io_out_data             (io_out_res_data),
    .io_out_fflags           (io_out_res_fflags),
    .regEnables_0            (regEn[0]),
    .regEnables_1            (regEn[1])
  );

  // ===========================================================================
  //  §3 调试 payload 打拍（fire 门控，不复位）
  // ===========================================================================
  perf_dbg_t perfVec   [1:LAT];
  seq_num_t  seqNumVec [1:LAT];

  always_ff @(posedge clock) begin
    if (rdy[0] & io_in_valid) begin
      perfVec[1]   <= io_in_perfDebugInfo;
      seqNumVec[1] <= io_in_debug_seqNum;
    end
    for (int s = 2; s <= LAT; s++) begin
      if (rdy[s-1] & vldThisFu[s-1]) begin
        perfVec[s]   <= perfVec[s-1];
        seqNumVec[s] <= seqNumVec[s-1];
      end
    end
  end

  // ===========================================================================
  //  §4 写回
  // ===========================================================================
  assign io_out_valid         = io_in_validPipe[LAT] & vldThisFu[LAT];
  assign io_out_ctrl          = io_in_ctrlPipe;
  assign io_out_perfDebugInfo = perfVec[LAT];
  assign io_out_debug_seqNum  = seqNumVec[LAT];

endmodule

// =============================================================================
//  golden 同名层：端口与 G1 golden IntToFP_3.sv 逐位同名，struct 展平
// =============================================================================
module IntToFP_3(
  input         clock,
  input         reset,
  output        io_in_ready,
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
  input         io_in_bits_perfDebugInfo_eliminatedMove,
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
  input  [7:0]  io_in_bits_debug_seqNum_uopIdx,
  input         io_out_ready,
  output        io_out_valid,
  output        io_out_bits_ctrl_robIdx_flag,
  output [7:0]  io_out_bits_ctrl_robIdx_value,
  output [7:0]  io_out_bits_ctrl_pdest,
  output        io_out_bits_ctrl_fpWen,
  output        io_out_bits_ctrl_fpu_wflags,
  output [63:0] io_out_bits_res_data,
  output [4:0]  io_out_bits_res_fflags,
  output        io_out_bits_perfDebugInfo_eliminatedMove,
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
  output [7:0]  io_out_bits_debug_seqNum_uopIdx,
  input  [2:0]  io_frm
);

  xs_IntToFP_3_pkg::fp_ctrl_t  fp_ctrl;
  xs_IntToFP_3_pkg::wb_ctrl_t  ctrl_in, ctrl_out;
  xs_IntToFP_3_pkg::perf_dbg_t perf_in, perf_out;
  xs_IntToFP_3_pkg::seq_num_t  seq_in, seq_out;

  always_comb begin
    fp_ctrl.typeTagOut = io_in_bits_ctrl_fpu_typeTagOut;
    fp_ctrl.wflags     = io_in_bits_ctrl_fpu_wflags;
    fp_ctrl.typ        = io_in_bits_ctrl_fpu_typ;
    fp_ctrl.rm         = io_in_bits_ctrl_fpu_rm;

    ctrl_in.robIdx_flag  = io_in_bits_ctrlPipe_2_robIdx_flag;
    ctrl_in.robIdx_value = io_in_bits_ctrlPipe_2_robIdx_value;
    ctrl_in.pdest        = io_in_bits_ctrlPipe_2_pdest;
    ctrl_in.fpWen        = io_in_bits_ctrlPipe_2_fpWen;
    ctrl_in.fpu_wflags   = io_in_bits_ctrlPipe_2_fpu_wflags;

    perf_in.eliminatedMove         = io_in_bits_perfDebugInfo_eliminatedMove;
    perf_in.renameTime             = io_in_bits_perfDebugInfo_renameTime;
    perf_in.dispatchTime           = io_in_bits_perfDebugInfo_dispatchTime;
    perf_in.enqRsTime              = io_in_bits_perfDebugInfo_enqRsTime;
    perf_in.selectTime             = io_in_bits_perfDebugInfo_selectTime;
    perf_in.issueTime              = io_in_bits_perfDebugInfo_issueTime;
    perf_in.writebackTime          = io_in_bits_perfDebugInfo_writebackTime;
    perf_in.runahead_checkpoint_id = io_in_bits_perfDebugInfo_runahead_checkpoint_id;
    perf_in.tlbFirstReqTime        = io_in_bits_perfDebugInfo_tlbFirstReqTime;
    perf_in.tlbRespTime            = io_in_bits_perfDebugInfo_tlbRespTime;

    seq_in.seqNum = io_in_bits_debug_seqNum_seqNum;
    seq_in.uopIdx = io_in_bits_debug_seqNum_uopIdx;
  end

  xs_IntToFP_3_core u_core (
    .clock                (clock),
    .reset                (reset),
    .io_in_ready          (io_in_ready),
    .io_in_valid          (io_in_valid),
    .io_in_fp_ctrl        (fp_ctrl),
    .io_in_ctrlPipe       (ctrl_in),
    .io_in_validPipe      ({io_in_bits_validPipe_2, io_in_bits_validPipe_1, io_in_bits_validPipe_0}),
    .io_in_src_0          (io_in_bits_data_src_0),
    .io_in_perfDebugInfo  (perf_in),
    .io_in_debug_seqNum   (seq_in),
    .io_out_ready         (io_out_ready),
    .io_out_valid         (io_out_valid),
    .io_out_ctrl          (ctrl_out),
    .io_out_res_data      (io_out_bits_res_data),
    .io_out_res_fflags    (io_out_bits_res_fflags),
    .io_out_perfDebugInfo (perf_out),
    .io_out_debug_seqNum  (seq_out),
    .io_frm               (io_frm)
  );

  assign io_out_bits_ctrl_robIdx_flag  = ctrl_out.robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = ctrl_out.robIdx_value;
  assign io_out_bits_ctrl_pdest        = ctrl_out.pdest;
  assign io_out_bits_ctrl_fpWen        = ctrl_out.fpWen;
  assign io_out_bits_ctrl_fpu_wflags   = ctrl_out.fpu_wflags;

  assign io_out_bits_perfDebugInfo_eliminatedMove         = perf_out.eliminatedMove;
  assign io_out_bits_perfDebugInfo_renameTime             = perf_out.renameTime;
  assign io_out_bits_perfDebugInfo_dispatchTime           = perf_out.dispatchTime;
  assign io_out_bits_perfDebugInfo_enqRsTime              = perf_out.enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime             = perf_out.selectTime;
  assign io_out_bits_perfDebugInfo_issueTime              = perf_out.issueTime;
  assign io_out_bits_perfDebugInfo_writebackTime          = perf_out.writebackTime;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = perf_out.runahead_checkpoint_id;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime        = perf_out.tlbFirstReqTime;
  assign io_out_bits_perfDebugInfo_tlbRespTime            = perf_out.tlbRespTime;

  assign io_out_bits_debug_seqNum_seqNum = seq_out.seqNum;
  assign io_out_bits_debug_seqNum_uopIdx = seq_out.uopIdx;

endmodule
