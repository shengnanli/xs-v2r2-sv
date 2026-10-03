// VPPU.sv —— 向量置换功能单元（XiangShan backend/fu/wrapper/VPPU.scala class VPPU，LAT=2）
// -----------------------------------------------------------------------------
// 在哪一层：向量执行簇里的一个 VecPipedFuncUnit（ExeUnit_13 内），执行 vslideup/vslidedown/vslide1up/
//   vslide1down/vrgather(ei16)/vcompress/vmv<n>r.v 这一族置换指令。真正的置换逻辑在 child Permutation
//   （yunsuan/vector/perm，两级流水，自带寄存器）；源/目的元素类型由 child VPermSrcTypeModule 按
//   {fuOpType, vsew} 查表给出。
// 本层自己做的事：
//   §1 本 FU 的 valid 移位链与反压链（rdy），payload（perfDebugInfo / seqNum）随流水搬运两级；
//   §2 给 Permutation 准备输入：opcode = fuOpType[2:0]；vmv<n>r.v 用指令里编码的 EMUL
//      （fuOpType[4:3]）顶替 vlmul；vcompress 的前两个 uop（vuopIdx[6:1]==0）把掩码清零；
//   §3 写回：控制信息直接取发射时预打好的第 2 级（ctrlPipe_2 / validPipe_2）；vstart != 0 报
//      exceptionVec(2)（非法指令）。
// 怪癖（照 golden）：
//   - valid 移位链不受 ready 门控，payload 寄存器受 ready 门控（与 VCVT_8 / FCVT 重写件同口径）；
//   - golden 在非 SYNTHESIS 下对 fuOpType==9'hFF（VpermType.dummy）有一条 assert(false)，
//     综合口径下不存在，本核不写；
//   - Scala 里 vxrm / vdType / vxsat 等端口在 KunminghuV2Config 下被 firtool 消掉（父级没接）。
// 子模块：Permutation、VPermSrcTypeModule（均已签核：ref 读 golden 件，impl 读本仓重写件）。
// golden 对照：G1-canonical/golden-rtl/VPPU.sv
// =============================================================================
package vppu_pkg;

  localparam int unsigned LAT = 2;    // 本 FU 的流水级数

  // 随流水搬运的调试/性能采样信息
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

  typedef struct packed {
    logic [55:0] seqNum;
    logic [7:0]  uopIdx;
  } seq_num_t;

  // 写回级（发射时预打好的第 LAT 级）控制信息
  typedef struct packed {
    logic       robIdx_flag;
    logic [7:0] robIdx_value;
    logic [7:0] pdest;
    logic       vecWen;
    logic       v0Wen;
  } wb_ctrl_t;

  // VpermType 编码（yunsuan/package.scala）
  localparam logic [8:0] OP_VCOMPRESS = 9'h026;

  // vmv<n>r.v：fuOpType[2:0]=3'b111 且 fuOpType[7:5]=3'b000，EMUL 编在 fuOpType[4:3]
  function automatic logic isVmvnr(input logic [8:0] fuOpType);
    return (fuOpType[2:0] == 3'b111) && (fuOpType[7:5] == 3'b000);
  endfunction

endpackage

// =============================================================================
//  可读核
// =============================================================================
module xs_VPPU_core
  import vppu_pkg::*;
(
  input  logic         clock,
  input  logic         reset,
  // ---- io.in ----
  output logic         io_in_ready,
  input  logic         io_in_valid,
  input  logic [8:0]   io_in_bits_ctrl_fuOpType,
  input  logic         io_in_bits_ctrl_vpu_vma,
  input  logic         io_in_bits_ctrl_vpu_vta,
  input  logic [1:0]   io_in_bits_ctrl_vpu_vsew,
  input  logic [2:0]   io_in_bits_ctrl_vpu_vlmul,
  input  logic         io_in_bits_ctrl_vpu_vm,
  input  logic [7:0]   io_in_bits_ctrl_vpu_vstart,
  input  logic [6:0]   io_in_bits_ctrl_vpu_vuopIdx,
  input  wb_ctrl_t     io_in_bits_ctrlPipe_wb,       // = golden ctrlPipe_2 的写回字段
  input  logic [7:0]   io_in_bits_ctrlPipe_vstart,   // = golden ctrlPipe_2_vpu_vstart
  input  logic         io_in_bits_validPipe,         // = golden validPipe_2
  input  logic [7:0]   io_in_bits_data_vl,           // = golden data_src_4（vl）
  input  logic [127:0] io_in_bits_data_v0,           // = golden data_src_3（v0 掩码）
  input  logic [127:0] io_in_bits_data_oldVd,        // = golden data_src_2
  input  logic [127:0] io_in_bits_data_vs2,          // = golden data_src_1
  input  logic [127:0] io_in_bits_data_vs1,          // = golden data_src_0
  input  perf_dbg_t    io_in_bits_perfDebugInfo,
  input  seq_num_t     io_in_bits_debug_seqNum,
  // ---- io.out ----
  input  logic         io_out_ready,
  output logic         io_out_valid,
  output wb_ctrl_t     io_out_bits_ctrl,
  output logic         io_out_bits_ctrl_exceptionVec_2,
  output logic [127:0] io_out_bits_res_data,
  output perf_dbg_t    io_out_bits_perfDebugInfo,
  output seq_num_t     io_out_bits_debug_seqNum
);

  // ===========================================================================
  //  §1 valid 移位链 + 反压链；payload 搬运
  // ===========================================================================
  logic [LAT:1] vldThisFu;        // vldThisFu[s] = s 拍前接了一个请求
  logic [LAT:0] rdy;              // rdy[s] = 第 s 级能接新活；rdy[0] = io_in_ready
  always_comb begin
    rdy[LAT] = io_out_ready;
    for (int s = LAT - 1; s >= 0; s--) rdy[s] = ~vldThisFu[s+1] | rdy[s+1];
  end
  assign io_in_ready = rdy[0];

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      vldThisFu <= '0;
    else begin
      vldThisFu[1] <= io_in_valid;                                    // 不受 ready 门控（照 golden）
      for (int s = 2; s <= LAT; s++) vldThisFu[s] <= vldThisFu[s-1];
    end
  end

  perf_dbg_t perfVec   [1:LAT];
  seq_num_t  seqNumVec [1:LAT];
  always_ff @(posedge clock) begin
    if (rdy[0] & io_in_valid) begin
      perfVec[1]   <= io_in_bits_perfDebugInfo;
      seqNumVec[1] <= io_in_bits_debug_seqNum;
    end
    for (int s = 2; s <= LAT; s++) begin
      if (rdy[s-1] & vldThisFu[s-1]) begin
        perfVec[s]   <= perfVec[s-1];
        seqNumVec[s] <= seqNumVec[s-1];
      end
    end
  end

  // ===========================================================================
  //  §2 Permutation 的输入准备 + 两个 child
  // ===========================================================================
  logic [8:0] fuOpType;
  logic [2:0] perm_vlmul;       // vmv<n>r.v 用指令编码的 EMUL，其余用 vtype 的 vlmul
  logic       clearMask;        // vcompress 的前两个 uop 不用掩码（Permutation 那边按 0 处理）
  logic [127:0] perm_mask;
  assign fuOpType   = io_in_bits_ctrl_fuOpType;
  assign perm_vlmul = isVmvnr(fuOpType) ? {1'b0, fuOpType[4:3]} : io_in_bits_ctrl_vpu_vlmul;
  assign clearMask  = (fuOpType == OP_VCOMPRESS) && (io_in_bits_ctrl_vpu_vuopIdx[6:1] == 6'd0);
  assign perm_mask  = clearMask ? 128'd0 : io_in_bits_data_v0;

  logic [3:0] vs1Type, vs2Type;
  VPermSrcTypeModule u_typeMod (
    .io_in_fuOpType(fuOpType),
    .io_in_vsew(io_in_bits_ctrl_vpu_vsew),
    .io_out_vs1Type(vs1Type),
    .io_out_vs2Type(vs2Type)
  );

  Permutation u_vperms (
    .clock(clock),
    .reset(reset),
    .io_in_valid(io_in_valid),
    .io_in_bits_opcode_op({3'b000, fuOpType[2:0]}),
    .io_in_bits_info_vm(io_in_bits_ctrl_vpu_vm),
    .io_in_bits_info_ma(io_in_bits_ctrl_vpu_vma),
    .io_in_bits_info_ta(io_in_bits_ctrl_vpu_vta),
    .io_in_bits_info_vlmul(perm_vlmul),
    .io_in_bits_info_vl(io_in_bits_data_vl),
    .io_in_bits_info_vstart(io_in_bits_ctrl_vpu_vstart[6:0]),
    .io_in_bits_info_uopIdx(io_in_bits_ctrl_vpu_vuopIdx[5:0]),
    .io_in_bits_srcType_0(vs2Type),
    .io_in_bits_srcType_1(vs1Type),
    .io_in_bits_vs1(io_in_bits_data_vs1),
    .io_in_bits_vs2(io_in_bits_data_vs2),
    .io_in_bits_old_vd(io_in_bits_data_oldVd),
    .io_in_bits_mask(perm_mask),
    .io_out_vd(io_out_bits_res_data)
  );

  // ===========================================================================
  //  §3 写回：控制取第 LAT 级预打拍；vstart != 0 报非法指令
  // ===========================================================================
  assign io_out_valid                    = io_in_bits_validPipe & vldThisFu[LAT];
  assign io_out_bits_ctrl                = io_in_bits_ctrlPipe_wb;
  assign io_out_bits_ctrl_exceptionVec_2 = |io_in_bits_ctrlPipe_vstart;
  assign io_out_bits_perfDebugInfo       = perfVec[LAT];
  assign io_out_bits_debug_seqNum        = seqNumVec[LAT];

endmodule

// =============================================================================
//  golden 同名 wrapper：端口逐位同名，展平 struct
// =============================================================================
module VPPU (
  input          clock,
  input          reset,
  output         io_in_ready,
  input          io_in_valid,
  input  [8:0]   io_in_bits_ctrl_fuOpType,
  input          io_in_bits_ctrl_vpu_vma,
  input          io_in_bits_ctrl_vpu_vta,
  input  [1:0]   io_in_bits_ctrl_vpu_vsew,
  input  [2:0]   io_in_bits_ctrl_vpu_vlmul,
  input          io_in_bits_ctrl_vpu_vm,
  input  [7:0]   io_in_bits_ctrl_vpu_vstart,
  input  [6:0]   io_in_bits_ctrl_vpu_vuopIdx,
  input          io_in_bits_ctrlPipe_2_robIdx_flag,
  input  [7:0]   io_in_bits_ctrlPipe_2_robIdx_value,
  input  [7:0]   io_in_bits_ctrlPipe_2_pdest,
  input          io_in_bits_ctrlPipe_2_vecWen,
  input          io_in_bits_ctrlPipe_2_v0Wen,
  input  [7:0]   io_in_bits_ctrlPipe_2_vpu_vstart,
  input          io_in_bits_validPipe_2,
  input  [7:0]   io_in_bits_data_src_4,
  input  [127:0] io_in_bits_data_src_3,
  input  [127:0] io_in_bits_data_src_2,
  input  [127:0] io_in_bits_data_src_1,
  input  [127:0] io_in_bits_data_src_0,
  input          io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_in_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_in_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_in_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_in_bits_debug_seqNum_seqNum,
  input  [7:0]   io_in_bits_debug_seqNum_uopIdx,
  input          io_out_ready,
  output         io_out_valid,
  output         io_out_bits_ctrl_robIdx_flag,
  output [7:0]   io_out_bits_ctrl_robIdx_value,
  output [7:0]   io_out_bits_ctrl_pdest,
  output         io_out_bits_ctrl_vecWen,
  output         io_out_bits_ctrl_v0Wen,
  output         io_out_bits_ctrl_exceptionVec_2,
  output [127:0] io_out_bits_res_data,
  output         io_out_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_out_bits_perfDebugInfo_renameTime,
  output [63:0]  io_out_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_out_bits_perfDebugInfo_selectTime,
  output [63:0]  io_out_bits_perfDebugInfo_issueTime,
  output [63:0]  io_out_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_out_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_out_bits_debug_seqNum_seqNum,
  output [7:0]   io_out_bits_debug_seqNum_uopIdx
);

  vppu_pkg::wb_ctrl_t  ctrl_in, ctrl_out;
  vppu_pkg::perf_dbg_t perf_in, perf_out;
  vppu_pkg::seq_num_t  seq_in,  seq_out;

  always_comb begin
    ctrl_in.robIdx_flag  = io_in_bits_ctrlPipe_2_robIdx_flag;
    ctrl_in.robIdx_value = io_in_bits_ctrlPipe_2_robIdx_value;
    ctrl_in.pdest        = io_in_bits_ctrlPipe_2_pdest;
    ctrl_in.vecWen       = io_in_bits_ctrlPipe_2_vecWen;
    ctrl_in.v0Wen        = io_in_bits_ctrlPipe_2_v0Wen;

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

  xs_VPPU_core u_core (
    .clock                           (clock),
    .reset                           (reset),
    .io_in_ready                     (io_in_ready),
    .io_in_valid                     (io_in_valid),
    .io_in_bits_ctrl_fuOpType        (io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_vpu_vma         (io_in_bits_ctrl_vpu_vma),
    .io_in_bits_ctrl_vpu_vta         (io_in_bits_ctrl_vpu_vta),
    .io_in_bits_ctrl_vpu_vsew        (io_in_bits_ctrl_vpu_vsew),
    .io_in_bits_ctrl_vpu_vlmul       (io_in_bits_ctrl_vpu_vlmul),
    .io_in_bits_ctrl_vpu_vm          (io_in_bits_ctrl_vpu_vm),
    .io_in_bits_ctrl_vpu_vstart      (io_in_bits_ctrl_vpu_vstart),
    .io_in_bits_ctrl_vpu_vuopIdx     (io_in_bits_ctrl_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_wb          (ctrl_in),
    .io_in_bits_ctrlPipe_vstart      (io_in_bits_ctrlPipe_2_vpu_vstart),
    .io_in_bits_validPipe            (io_in_bits_validPipe_2),
    .io_in_bits_data_vl              (io_in_bits_data_src_4),
    .io_in_bits_data_v0              (io_in_bits_data_src_3),
    .io_in_bits_data_oldVd           (io_in_bits_data_src_2),
    .io_in_bits_data_vs2             (io_in_bits_data_src_1),
    .io_in_bits_data_vs1             (io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo        (perf_in),
    .io_in_bits_debug_seqNum         (seq_in),
    .io_out_ready                    (io_out_ready),
    .io_out_valid                    (io_out_valid),
    .io_out_bits_ctrl                (ctrl_out),
    .io_out_bits_ctrl_exceptionVec_2 (io_out_bits_ctrl_exceptionVec_2),
    .io_out_bits_res_data            (io_out_bits_res_data),
    .io_out_bits_perfDebugInfo       (perf_out),
    .io_out_bits_debug_seqNum        (seq_out)
  );

  assign io_out_bits_ctrl_robIdx_flag  = ctrl_out.robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = ctrl_out.robIdx_value;
  assign io_out_bits_ctrl_pdest        = ctrl_out.pdest;
  assign io_out_bits_ctrl_vecWen       = ctrl_out.vecWen;
  assign io_out_bits_ctrl_v0Wen        = ctrl_out.v0Wen;

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
