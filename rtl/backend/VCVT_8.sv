// VCVT_8.sv —— 向量浮点转换功能单元（XiangShan backend/fu/wrapper/VCVT.scala class VCVT，LAT=2）
// -----------------------------------------------------------------------------
// 在哪一层：向量执行簇里的一个 VecPipedFuncUnit，执行 vfcvt / vfwcvt / vfncvt 全家与
//   vfrec7 / vfrsqrt7。下面是 VectorCvtTop（128 位 = 两个 64 位 VectorCvt），再下面是
//   每 64 位 4 条元素通道（CVT64_1 / CVT32 / CVT16×2）。
// 本层自己做的事：
//   §1 本 FU 的 valid 移位链与反压链（rdyVec），payload（perfDebugInfo / seqNum）随流水搬运；
//   §2 opType 译码：RTZ/ROD 编进 opType 低 3 位时覆盖舍入模式，否则用 fcsr.frm；
//      由 {widen, sew} 查表得结果元素宽度 output1H；
//   §3 fflags 按元素使能：本 uop 负责的元素是第 eStart 起的若干个（eStart = vuopIdx × 每寄存器
//      元素数），只有「被掩码选中」且「下标 < min(vl, 本 LMUL 的元素上限)」的元素才把自己的
//      fflags 或进结果；使能位打两拍与数据对齐；
//   §4 写回：结果经 Mgu 按 vstart / vl / 掩码 / vta / vma 与旧 vd 合并；变窄指令两条 uop 各出
//      64 位，按 vuopIdx[0] 拼进旧 vd 的低/高半。
// golden 的 KunminghuV2Config 实例里 isFpToVecInst 恒 0（firtool 已消掉端口），「fmv」「标量
//   f2i 符号扩展」两条通路也一并消失；golden 在非 SYNTHESIS 下对 fuOpType==9'hFF 有一条
//   assert(false)，综合口径下不存在，本核不写（与 FCVT 重写件同口径）。
// 怪癖（照 golden）：
//   - valid 移位链不受 ready 门控，payload 寄存器受 ready 门控（同 FCVT 的说明：本 FU 所在口的
//     io_out_ready 恒 1，两者等价）；
//   - 每 LMUL 元素上限 eNumMax 由独热移位得到，再用 Mux1H 映射成数值 —— 独热时两者就是同一个数；
//   - 两级流水寄存器（outEew / fflagsEnCycle2 / narrow）不复位，第二级用 fire 打一拍
//     （GatedValidRegNext）使能。
// 子模块：VectorCvtTop（本 lane 重写）、Mgu（本仓重写件；签核 receipt 在 agent/fu-atomics-fpdiv-imsic，
//   合入 main 前本目标的 FM 以它为条件）。
// golden 对照：G1-canonical/golden-rtl/VCVT_8.sv
// =============================================================================
package vcvt8_pkg;

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
    logic       fpu_wflags;
  } wb_ctrl_t;

  typedef struct packed {
    wb_ctrl_t   wb;
    logic       vma;
    logic       vta;
    logic       vm;
    logic [7:0] vstart;
    logic [6:0] vuopIdx;
    logic       isDstMask;
  } ctrl_pipe_t;

  // 结果元素宽度独热（[0]=8 [1]=16 [2]=32 [3]=64），{widen, sew} 查表；表外为 0
  function automatic logic [3:0] decodeOutputWidth(input logic [1:0] widen, input logic [1:0] sew);
    case ({widen, sew})
      4'b00_01: decodeOutputWidth = 4'b0010;   // 同宽 16
      4'b00_10: decodeOutputWidth = 4'b0100;   // 同宽 32
      4'b00_11: decodeOutputWidth = 4'b1000;   // 同宽 64
      4'b01_00: decodeOutputWidth = 4'b0010;   // 变宽 -> 16
      4'b01_01: decodeOutputWidth = 4'b0100;   // 变宽 -> 32
      4'b01_10: decodeOutputWidth = 4'b1000;   // 变宽 -> 64
      4'b10_00: decodeOutputWidth = 4'b0001;   // 变窄 -> 8
      4'b10_01: decodeOutputWidth = 4'b0010;   // 变窄 -> 16
      4'b10_10: decodeOutputWidth = 4'b0100;   // 变窄 -> 32
      default:  decodeOutputWidth = 4'b0000;
    endcase
  endfunction

  // 一个 64 位通道里本 uop 负责的元素数（独热：[1]=2 [2]=4 [3]=8；[0] 恒 0），
  // 按 {sew, 是否变宽/变窄} 查表（变宽/变窄时按较宽一侧算）
  function automatic logic [3:0] decodeElemNum(input logic [1:0] sew, input logic wide_or_narrow);
    case ({sew, wide_or_narrow})
      3'b00_1: decodeElemNum = 4'b1000;
      3'b01_0: decodeElemNum = 4'b1000;
      3'b01_1: decodeElemNum = 4'b0100;
      3'b10_0: decodeElemNum = 4'b0100;
      3'b10_1: decodeElemNum = 4'b0010;
      3'b11_0: decodeElemNum = 4'b0010;
      default: decodeElemNum = 4'b0000;
    endcase
  endfunction

endpackage

// =============================================================================
//  可读核
// =============================================================================
module xs_VCVT_8_core
  import vcvt8_pkg::*;
(
  input  logic         clock,
  input  logic         reset,
  // ---- io.in ----
  output logic         io_in_ready,
  input  logic         io_in_valid,
  input  logic [8:0]   io_in_bits_ctrl_fuOpType,
  input  logic [1:0]   io_in_bits_ctrl_vpu_vsew,
  input  logic [2:0]   io_in_bits_ctrl_vpu_vlmul,
  input  logic         io_in_bits_ctrl_vpu_vm,
  input  logic [6:0]   io_in_bits_ctrl_vpu_vuopIdx,
  input  ctrl_pipe_t   io_in_bits_ctrlPipe,          // = golden ctrlPipe_2
  input  logic         io_in_bits_validPipe,         // = golden validPipe_2
  input  logic [7:0]   io_in_bits_data_vl,           // = golden data_src_4（vl）
  input  logic [127:0] io_in_bits_data_v0,           // = golden data_src_3（v0 掩码）
  input  logic [127:0] io_in_bits_data_vs2,          // = golden data_src_1（被转换的源）
  input  logic [7:0]   io_in_bits_dataPipe_vl,       // = golden dataPipe_2_src_4
  input  logic [127:0] io_in_bits_dataPipe_v0,       // = golden dataPipe_2_src_3
  input  logic [127:0] io_in_bits_dataPipe_oldVd,    // = golden dataPipe_2_src_2
  input  perf_dbg_t    io_in_bits_perfDebugInfo,
  input  seq_num_t     io_in_bits_debug_seqNum,
  // ---- io.out ----
  input  logic         io_out_ready,
  output logic         io_out_valid,
  output wb_ctrl_t     io_out_bits_ctrl,
  output logic [127:0] io_out_bits_res_data,
  output logic [4:0]   io_out_bits_res_fflags,
  output perf_dbg_t    io_out_bits_perfDebugInfo,
  output seq_num_t     io_out_bits_debug_seqNum,
  // ---- CSR ----
  input  logic [2:0]   io_frm
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

  // fire 打一拍（GatedValidRegNext）：第二级流水寄存器的使能
  logic fireReg_last_r;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      fireReg_last_r <= 1'b0;
    else if (io_in_valid | fireReg_last_r)
      fireReg_last_r <= io_in_valid;
  end

  // ===========================================================================
  //  §2 opType 译码：舍入模式 / 宽度
  // ===========================================================================
  logic [8:0] opcode;
  logic       isRtz, isRod, isWidenCvt, isNarrowCvt;
  logic [2:0] vfcvt_rm;
  logic [3:0] output1H;
  assign opcode      = io_in_bits_ctrl_fuOpType;
  assign isRtz       = opcode[2] & opcode[1];                    // *.rtz.* ：向零截断
  assign isRod       = opcode[2] & ~opcode[1] & opcode[0];       // vfncvt.rod.f.f ：就近取奇
  assign isWidenCvt  = ~opcode[4] & opcode[3];
  assign isNarrowCvt = opcode[4] & ~opcode[3];
  assign vfcvt_rm    = (isRtz ? 3'd1 : 3'd0) | (isRod ? 3'd6 : 3'd0) | (~isRtz & ~isRod ? io_frm : 3'd0);
  assign output1H    = decodeOutputWidth(opcode[4:3], io_in_bits_ctrl_vpu_vsew);

  // ===========================================================================
  //  §3 fflags 的按元素使能
  // ===========================================================================
  logic       wide_or_narrow;
  logic [3:0] eNum1H;             // 每 64 位通道的元素数（独热）
  logic [4:0] eNum1HEffect;       // 每个 128 位寄存器的元素数（变宽/变窄按较宽侧，再翻一倍）
  logic [6:0] eNumMax;            // 本 LMUL 下的元素上限（独热即数值）
  logic [7:0] eNumMax_shl;
  logic [4:0] eNumMax_shr;
  logic [7:0] eNumEffectIdx;      // min(vl, eNumMax)
  logic [10:0] eStart;            // 本 uop 第一个元素的下标
  logic [127:0] srcMask, maskPart;
  logic [7:0] mask;
  logic [7:0] fflagsEn;

  assign wide_or_narrow = isWidenCvt | isNarrowCvt;
  assign eNum1H         = decodeElemNum(io_in_bits_ctrl_vpu_vsew, wide_or_narrow);
  assign eNum1HEffect   = wide_or_narrow ? {eNum1H, 1'b0} : {1'b0, eNum1H};
  // vlmul[2]=1 是分数 LMUL（1/2、1/4、1/8）：右移 (-vlmul)；否则左移 vlmul
  assign eNumMax_shl    = 8'(eNum1HEffect) << io_in_bits_ctrl_vpu_vlmul[1:0];
  assign eNumMax_shr    = eNum1HEffect >> 2'(~io_in_bits_ctrl_vpu_vlmul[1:0] + 2'd1);
  assign eNumMax        = io_in_bits_ctrl_vpu_vlmul[2] ? 7'(eNumMax_shr) : eNumMax_shl[6:0];
  assign eNumEffectIdx  = (io_in_bits_data_vl > 8'(eNumMax)) ? 8'(eNumMax) : io_in_bits_data_vl;
  assign eStart         = 11'({4'h0, io_in_bits_ctrl_vpu_vuopIdx} * {7'h0, eNum1H});

  assign srcMask  = io_in_bits_ctrl_vpu_vm ? '1 : io_in_bits_data_v0;
  assign maskPart = srcMask >> eStart;
  assign mask     = (eNum1H[1] ? 8'(maskPart[1:0]) : 8'h0)
                  | (eNum1H[2] ? 8'(maskPart[3:0]) : 8'h0)
                  | (eNum1H[3] ? maskPart[7:0]     : 8'h0);

  always_comb begin
    for (int i = 0; i < 8; i++)
      fflagsEn[i] = mask[i] & (11'(eNumEffectIdx) > 11'(eStart + 11'(i)));
  end

  // 两级对齐（第 1 级 fire 使能，第 2 级 fire 打一拍使能；均不复位）
  logic [1:0] outEew_r, outEew;
  logic [7:0] fflagsEnCycle2_r, fflagsEnCycle2;
  logic       narrow_r, narrow;
  always_ff @(posedge clock) begin
    if (io_in_valid) begin
      outEew_r         <= {output1H[2] | output1H[3], output1H[1] | output1H[3]};   // log2(结果宽/8)
      fflagsEnCycle2_r <= fflagsEn;
      narrow_r         <= isNarrowCvt;
    end
    if (fireReg_last_r) begin
      outEew         <= outEew_r;
      fflagsEnCycle2 <= fflagsEnCycle2_r;
      narrow         <= narrow_r;
    end
  end

  // ===========================================================================
  //  §4 转换器与写回
  // ===========================================================================
  logic [127:0] vfcvt_result;
  logic [39:0]  vfcvt_fflags;     // 8 个元素 × 5 位
  VectorCvtTop vfcvt (
    .clock            (clock),
    .reset            (reset),
    .io_fire          (io_in_valid),
    .io_uopIdx        (io_in_bits_ctrl_vpu_vuopIdx[0]),
    .io_src_0         (io_in_bits_data_vs2[63:0]),
    .io_src_1         (io_in_bits_data_vs2[127:64]),
    .io_opType        (opcode[7:0]),
    .io_sew           (io_in_bits_ctrl_vpu_vsew),
    .io_rm            (vfcvt_rm),
    .io_outputWidth1H (output1H),
    .io_isWiden       (isWidenCvt),
    .io_isNarrow      (isNarrowCvt),
    .io_result        (vfcvt_result),
    .io_fflags        (vfcvt_fflags)
  );

  always_comb begin
    io_out_bits_res_fflags = 5'h0;
    for (int i = 0; i < 8; i++)
      if (fflagsEnCycle2[i]) io_out_bits_res_fflags |= vfcvt_fflags[5*i +: 5];
  end

  // 变窄：一条 uop 只出 64 位结果，vuopIdx[0] 决定放进旧 vd 的低半还是高半
  logic [127:0] oldVd, narrow_vd, mgu_vd;
  assign oldVd     = io_in_bits_dataPipe_oldVd;
  assign narrow_vd = io_in_bits_ctrlPipe.vuopIdx[0] & narrow
                   ? {vfcvt_result[63:0], oldVd[63:0]}
                   : {oldVd[127:64], vfcvt_result[63:0]};
  assign mgu_vd    = narrow ? narrow_vd : vfcvt_result;

  Mgu mgu (
    .io_in_vd           (mgu_vd),
    .io_in_oldVd        (oldVd),
    .io_in_mask         (io_in_bits_ctrlPipe.vm ? '1 : io_in_bits_dataPipe_v0),
    .io_in_info_ta      (io_in_bits_ctrlPipe.vta),
    .io_in_info_ma      (io_in_bits_ctrlPipe.vma),
    .io_in_info_vl      (io_in_bits_dataPipe_vl),
    .io_in_info_vstart  (io_in_bits_ctrlPipe.vstart),
    .io_in_info_eew     (outEew),
    .io_in_info_vdIdx   (io_in_bits_ctrlPipe.vuopIdx[2:0]),
    .io_in_info_narrow  (narrow),
    .io_in_info_dstMask (io_in_bits_ctrlPipe.isDstMask),
    .io_out_vd          (io_out_bits_res_data),
    .io_out_active      ()
  );

  assign io_out_valid              = io_in_bits_validPipe & vldThisFu[LAT];
  assign io_out_bits_ctrl          = io_in_bits_ctrlPipe.wb;
  assign io_out_bits_perfDebugInfo = perfVec[LAT];
  assign io_out_bits_debug_seqNum  = seqNumVec[LAT];

endmodule

// =============================================================================
//  golden 同名层：端口与 firtool 输出逐位同名，例化可读核并把 struct 展平
// =============================================================================
module VCVT_8(
  input          clock,
  input          reset,
  output         io_in_ready,
  input          io_in_valid,
  input  [8:0]   io_in_bits_ctrl_fuOpType,
  input  [1:0]   io_in_bits_ctrl_vpu_vsew,
  input  [2:0]   io_in_bits_ctrl_vpu_vlmul,
  input          io_in_bits_ctrl_vpu_vm,
  input  [6:0]   io_in_bits_ctrl_vpu_vuopIdx,
  input          io_in_bits_ctrlPipe_2_robIdx_flag,
  input  [7:0]   io_in_bits_ctrlPipe_2_robIdx_value,
  input  [7:0]   io_in_bits_ctrlPipe_2_pdest,
  input          io_in_bits_ctrlPipe_2_vecWen,
  input          io_in_bits_ctrlPipe_2_v0Wen,
  input          io_in_bits_ctrlPipe_2_fpu_wflags,
  input          io_in_bits_ctrlPipe_2_vpu_vma,
  input          io_in_bits_ctrlPipe_2_vpu_vta,
  input          io_in_bits_ctrlPipe_2_vpu_vm,
  input  [7:0]   io_in_bits_ctrlPipe_2_vpu_vstart,
  input  [6:0]   io_in_bits_ctrlPipe_2_vpu_vuopIdx,
  input          io_in_bits_ctrlPipe_2_vpu_isDstMask,
  input          io_in_bits_validPipe_2,
  input  [7:0]   io_in_bits_data_src_4,
  input  [127:0] io_in_bits_data_src_3,
  input  [127:0] io_in_bits_data_src_1,
  input  [7:0]   io_in_bits_dataPipe_2_src_4,
  input  [127:0] io_in_bits_dataPipe_2_src_3,
  input  [127:0] io_in_bits_dataPipe_2_src_2,
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
  output         io_out_bits_ctrl_fpu_wflags,
  output [127:0] io_out_bits_res_data,
  output [4:0]   io_out_bits_res_fflags,
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
  output [7:0]   io_out_bits_debug_seqNum_uopIdx,
  input  [2:0]   io_frm
);

  vcvt8_pkg::ctrl_pipe_t ctrl_in;
  vcvt8_pkg::wb_ctrl_t   ctrl_out;
  vcvt8_pkg::perf_dbg_t  perf_in, perf_out;
  vcvt8_pkg::seq_num_t   seq_in,  seq_out;

  always_comb begin
    ctrl_in.wb.robIdx_flag  = io_in_bits_ctrlPipe_2_robIdx_flag;
    ctrl_in.wb.robIdx_value = io_in_bits_ctrlPipe_2_robIdx_value;
    ctrl_in.wb.pdest        = io_in_bits_ctrlPipe_2_pdest;
    ctrl_in.wb.vecWen       = io_in_bits_ctrlPipe_2_vecWen;
    ctrl_in.wb.v0Wen        = io_in_bits_ctrlPipe_2_v0Wen;
    ctrl_in.wb.fpu_wflags   = io_in_bits_ctrlPipe_2_fpu_wflags;
    ctrl_in.vma             = io_in_bits_ctrlPipe_2_vpu_vma;
    ctrl_in.vta             = io_in_bits_ctrlPipe_2_vpu_vta;
    ctrl_in.vm              = io_in_bits_ctrlPipe_2_vpu_vm;
    ctrl_in.vstart          = io_in_bits_ctrlPipe_2_vpu_vstart;
    ctrl_in.vuopIdx         = io_in_bits_ctrlPipe_2_vpu_vuopIdx;
    ctrl_in.isDstMask       = io_in_bits_ctrlPipe_2_vpu_isDstMask;

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

  xs_VCVT_8_core u_core (
    .clock                       (clock),
    .reset                       (reset),
    .io_in_ready                 (io_in_ready),
    .io_in_valid                 (io_in_valid),
    .io_in_bits_ctrl_fuOpType    (io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_vpu_vsew    (io_in_bits_ctrl_vpu_vsew),
    .io_in_bits_ctrl_vpu_vlmul   (io_in_bits_ctrl_vpu_vlmul),
    .io_in_bits_ctrl_vpu_vm      (io_in_bits_ctrl_vpu_vm),
    .io_in_bits_ctrl_vpu_vuopIdx (io_in_bits_ctrl_vpu_vuopIdx),
    .io_in_bits_ctrlPipe         (ctrl_in),
    .io_in_bits_validPipe        (io_in_bits_validPipe_2),
    .io_in_bits_data_vl          (io_in_bits_data_src_4),
    .io_in_bits_data_v0          (io_in_bits_data_src_3),
    .io_in_bits_data_vs2         (io_in_bits_data_src_1),
    .io_in_bits_dataPipe_vl      (io_in_bits_dataPipe_2_src_4),
    .io_in_bits_dataPipe_v0      (io_in_bits_dataPipe_2_src_3),
    .io_in_bits_dataPipe_oldVd   (io_in_bits_dataPipe_2_src_2),
    .io_in_bits_perfDebugInfo    (perf_in),
    .io_in_bits_debug_seqNum     (seq_in),
    .io_out_ready                (io_out_ready),
    .io_out_valid                (io_out_valid),
    .io_out_bits_ctrl            (ctrl_out),
    .io_out_bits_res_data        (io_out_bits_res_data),
    .io_out_bits_res_fflags      (io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo   (perf_out),
    .io_out_bits_debug_seqNum    (seq_out),
    .io_frm                      (io_frm)
  );

  assign io_out_bits_ctrl_robIdx_flag  = ctrl_out.robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = ctrl_out.robIdx_value;
  assign io_out_bits_ctrl_pdest        = ctrl_out.pdest;
  assign io_out_bits_ctrl_vecWen       = ctrl_out.vecWen;
  assign io_out_bits_ctrl_v0Wen        = ctrl_out.v0Wen;
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
