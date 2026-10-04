// =============================================================================
// VFDivSqrt.sv —— 向量浮点除法 / 开方功能单元外壳（vfdiv / vfrdiv / vfsqrt，多拍非流水）
//
// 在哪一层：ExeUnit_15（向量浮点除法执行单元）的 FU。把一条 vfdiv/vfsqrt uop 交给两个 VectorFloatDivider
//   （128 位向量的低 64 位 / 高 64 位各一个，每个内部按 SEW 并行 1×f64 / 2×f32 / 4×f16），算完按 RVV 的
//   vstart / vl / 掩码 / vta / vma 语义经 Mgu 与旧 vd 合并，并把活跃元素的 fflags 合并成 5 位。
//   Scala：VFDivSqrt extends VecNonPipedFuncUnit（多拍非流水 FU 的公共外壳，与 VIDiv 同一基类）。
//
// 数据流：
//   §1 保持旁路（DataHoldBypass）：握手拍（in.fire）直接用入口值，之后用握手时锁存的副本——Mgu 与 fflags 合并在
//      结果出来那拍要用的控制（fuOpType / vsew / vlmul / vm / vstart / vuopIdx / vta / vma / narrow / dstMask）
//      和数据（vl = src_4、v0 = src_3、旧 vd = src_2）都走这条路。
//   §2 冲刷：本 uop 的 robIdx（in_ready 时看入口、忙时看锁存）比冲刷点年轻，或冲刷 level=1 且正好是这条。
//   §3 两个 VectorFloatDivider：start_valid 都接 in_valid（★不看对外 in_ready★），格式 = vsew，is_sqrt = fuOpType[0]，
//      a = vs2（src_1）、b = vs1（src_0）的各自 64 位半边；in_ready = 两者都空闲；out_valid = 两者都出结果（与）；
//      finish_ready = out_ready & out_valid。
//   §4 写回：Mgu 合并（掩码 = vm ? 全 1 : v0；但 fuOpType 为 vmadc.vv/vmsbc.vv 编码时清 0 —— 公共外壳按 VIAlu 的编码写的，
//      对 vfdiv 类永不命中，照抄）；fflags 用 xs_VecFflagsElemMask 算出 8 组里哪些计入，再按位或。
//   §5 出口控制/调试信息：握手拍锁存，结果出来时原样交回（无复位）。
// ★bug-for-bug 要点★
//   · Mgu 的 vdIdx 与 fflags 的 uop 号都只取 vuopIdx 低 3 位（锁存的 7 位里 [6:3] 两侧都没有读者）。
//   · fuOpType==0xFF（dummy）在非 SYNTHESIS 下有一条 assert；综合口径不含，本核不写（同 VIDiv / FAlu 重写件）。
//   · 与 VIDiv 不同：本外壳没有「vl=0 时整个 vd 保持旧值」的旁路，结果直接是 Mgu 的输出。
// 子模块（两侧白盒）：VectorFloatDivider vfdivs_0 / vfdivs_1、VecDataSplitModule vs2Split / vs1Split、Mgu mgu
//   （实例名与 golden 一致；本仓已签核重写件）；共享辅助件 xs_VecFflagsElemMask（rtl/common）。
// 设计源：src/main/scala/xiangshan/backend/fu/wrapper/VFDivSqrt.scala、fu/vector/VecNonPipedFuncUnit.scala
// golden 对照：G1-canonical/golden-rtl/VFDivSqrt.sv
// =============================================================================

package vfdivsqrt_pkg;
  // 随 uop 搬运、只在出口原样交回的调试/性能信息
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
    logic [55:0] seqNum;
    logic [7:0]  seqNum_uopIdx;
  } debug_info_t;

  localparam logic [8:0] OP_VMADC_VV = 9'h084;   // VialuFixType.vmadc_vv（公共外壳的清掩码判断）
  localparam logic [8:0] OP_VMSBC_VV = 9'h086;   // VialuFixType.vmsbc_vv
endpackage

// -----------------------------------------------------------------------------
// xs_VFDivSqrt_core —— 可读核
// -----------------------------------------------------------------------------
module xs_VFDivSqrt_core
  import vfdivsqrt_pkg::*;
(
  input  logic         clock,
  input  logic         reset,
  // 冲刷
  input  logic         flush_valid,
  input  logic         flush_robIdx_flag,
  input  logic [7:0]   flush_robIdx_value,
  input  logic         flush_level,
  // 入口
  output logic         in_ready,
  input  logic         in_valid,
  input  logic [8:0]   in_fuOpType,
  input  logic         in_robIdx_flag,
  input  logic [7:0]   in_robIdx_value,
  input  logic [7:0]   in_pdest,
  input  logic         in_vecWen,
  input  logic         in_v0Wen,
  input  logic         in_fpu_wflags,
  input  logic         in_vma,
  input  logic         in_vta,
  input  logic [1:0]   in_vsew,
  input  logic [2:0]   in_vlmul,
  input  logic         in_vm,
  input  logic [7:0]   in_vstart,
  input  logic [6:0]   in_vuopIdx,
  input  logic         in_isNarrow,
  input  logic         in_isDstMask,
  input  logic [7:0]   in_vl,          // src_4
  input  logic [127:0] in_v0,          // src_3：掩码
  input  logic [127:0] in_oldVd,       // src_2
  input  logic [127:0] in_vs2,         // src_1：被除数 / 被开方数
  input  logic [127:0] in_vs1,         // src_0：除数
  input  debug_info_t  in_debug,
  input  logic [2:0]   frm,
  // 出口
  input  logic         out_ready,
  output logic         out_valid,
  output logic         out_robIdx_flag,
  output logic [7:0]   out_robIdx_value,
  output logic [7:0]   out_pdest,
  output logic         out_vecWen,
  output logic         out_v0Wen,
  output logic         out_fpu_wflags,
  output logic [127:0] out_res_data,
  output logic [4:0]   out_res_fflags,
  output debug_info_t  out_debug
);
  logic in_fire;
  assign in_fire = in_ready & in_valid;

  // ---------------------------------------------------------------------------
  // §1 保持旁路（寄存器名同 golden：outCtrl_r_* / outData_r_*，握手拍写入，无复位）
  // ---------------------------------------------------------------------------
  logic [8:0]   outCtrl_r_fuOpType;
  logic         outCtrl_r_robIdx_flag;
  logic [7:0]   outCtrl_r_robIdx_value;
  logic         outCtrl_r_vpu_vma, outCtrl_r_vpu_vta, outCtrl_r_vpu_vm;
  logic [1:0]   outCtrl_r_vpu_vsew;
  logic [2:0]   outCtrl_r_vpu_vlmul;
  logic [7:0]   outCtrl_r_vpu_vstart;
  logic [6:0]   outCtrl_r_vpu_vuopIdx;
  logic         outCtrl_r_vpu_isNarrow, outCtrl_r_vpu_isDstMask;
  logic [7:0]   outData_r_src_4;
  logic [127:0] outData_r_src_3, outData_r_src_2;
  always_ff @(posedge clock) begin
    if (in_fire) begin
      outCtrl_r_fuOpType      <= in_fuOpType;
      outCtrl_r_robIdx_flag   <= in_robIdx_flag;
      outCtrl_r_robIdx_value  <= in_robIdx_value;
      outCtrl_r_vpu_vma       <= in_vma;
      outCtrl_r_vpu_vta       <= in_vta;
      outCtrl_r_vpu_vsew      <= in_vsew;
      outCtrl_r_vpu_vlmul     <= in_vlmul;
      outCtrl_r_vpu_vm        <= in_vm;
      outCtrl_r_vpu_vstart    <= in_vstart;
      outCtrl_r_vpu_vuopIdx   <= in_vuopIdx;
      outCtrl_r_vpu_isNarrow  <= in_isNarrow;
      outCtrl_r_vpu_isDstMask <= in_isDstMask;
      outData_r_src_4         <= in_vl;
      outData_r_src_3         <= in_v0;
      outData_r_src_2         <= in_oldVd;
    end
  end

  logic [8:0]   hold_fuOpType;
  logic [1:0]   hold_vsew;
  logic [2:0]   hold_vlmul;
  logic [2:0]   hold_vuopIdx;     // 只用低 3 位
  logic         hold_vm, hold_vta, hold_vma, hold_isNarrow, hold_isDstMask;
  logic [7:0]   hold_vstart, hold_vl;
  logic [127:0] hold_v0, hold_oldVd;
  assign hold_fuOpType  = in_fire ? in_fuOpType      : outCtrl_r_fuOpType;
  assign hold_vsew      = in_fire ? in_vsew          : outCtrl_r_vpu_vsew;
  assign hold_vlmul     = in_fire ? in_vlmul         : outCtrl_r_vpu_vlmul;
  assign hold_vuopIdx   = in_fire ? in_vuopIdx[2:0]  : outCtrl_r_vpu_vuopIdx[2:0];
  assign hold_vm        = in_fire ? in_vm            : outCtrl_r_vpu_vm;
  assign hold_vta       = in_fire ? in_vta           : outCtrl_r_vpu_vta;
  assign hold_vma       = in_fire ? in_vma           : outCtrl_r_vpu_vma;
  assign hold_isNarrow  = in_fire ? in_isNarrow      : outCtrl_r_vpu_isNarrow;
  assign hold_isDstMask = in_fire ? in_isDstMask     : outCtrl_r_vpu_isDstMask;
  assign hold_vstart    = in_fire ? in_vstart        : outCtrl_r_vpu_vstart;
  assign hold_vl        = in_fire ? in_vl            : outData_r_src_4;
  assign hold_v0        = in_fire ? in_v0            : outData_r_src_3;
  assign hold_oldVd     = in_fire ? in_oldVd         : outData_r_src_2;

  // ---------------------------------------------------------------------------
  // §2 冲刷判定：RobPtr.needFlush —— 比冲刷点年轻，或 level=1 且就是这条
  // ---------------------------------------------------------------------------
  logic       this_flag, need_flush;
  logic [7:0] this_value;
  assign this_flag  = in_ready ? in_robIdx_flag  : outCtrl_r_robIdx_flag;
  assign this_value = in_ready ? in_robIdx_value : outCtrl_r_robIdx_value;
  assign need_flush = flush_valid &
                      ((flush_level & ({this_flag, this_value} == {flush_robIdx_flag, flush_robIdx_value})) |
                       ((this_flag ^ flush_robIdx_flag) ^ (this_value > flush_robIdx_value)));

  // ---------------------------------------------------------------------------
  // §3 两个向量除法/开方器（各管 64 位）
  // ---------------------------------------------------------------------------
  logic [63:0] vs2_half [2], vs1_half [2];
  VecDataSplitModule vs2Split (
    .io_inVecData   (in_vs2),
    .io_outVec8b_0  (), .io_outVec8b_1  (), .io_outVec8b_2  (), .io_outVec8b_3  (),
    .io_outVec8b_4  (), .io_outVec8b_5  (), .io_outVec8b_6  (), .io_outVec8b_7  (),
    .io_outVec8b_8  (), .io_outVec8b_9  (), .io_outVec8b_10 (), .io_outVec8b_11 (),
    .io_outVec8b_12 (), .io_outVec8b_13 (), .io_outVec8b_14 (), .io_outVec8b_15 (),
    .io_outVec16b_0 (), .io_outVec16b_1 (), .io_outVec16b_2 (), .io_outVec16b_3 (),
    .io_outVec16b_4 (), .io_outVec16b_5 (), .io_outVec16b_6 (), .io_outVec16b_7 (),
    .io_outVec32b_0 (), .io_outVec32b_1 (), .io_outVec32b_2 (), .io_outVec32b_3 (),
    .io_outVec64b_0 (vs2_half[0]),
    .io_outVec64b_1 (vs2_half[1])
  );
  VecDataSplitModule vs1Split (
    .io_inVecData   (in_vs1),
    .io_outVec8b_0  (), .io_outVec8b_1  (), .io_outVec8b_2  (), .io_outVec8b_3  (),
    .io_outVec8b_4  (), .io_outVec8b_5  (), .io_outVec8b_6  (), .io_outVec8b_7  (),
    .io_outVec8b_8  (), .io_outVec8b_9  (), .io_outVec8b_10 (), .io_outVec8b_11 (),
    .io_outVec8b_12 (), .io_outVec8b_13 (), .io_outVec8b_14 (), .io_outVec8b_15 (),
    .io_outVec16b_0 (), .io_outVec16b_1 (), .io_outVec16b_2 (), .io_outVec16b_3 (),
    .io_outVec16b_4 (), .io_outVec16b_5 (), .io_outVec16b_6 (), .io_outVec16b_7 (),
    .io_outVec32b_0 (), .io_outVec32b_1 (), .io_outVec32b_2 (), .io_outVec32b_3 (),
    .io_outVec64b_0 (vs1_half[0]),
    .io_outVec64b_1 (vs1_half[1])
  );

  logic        div_start_ready [2], div_finish_valid [2];
  logic [63:0] div_result [2];
  logic [19:0] div_fflags [2];
  logic        div_finish_ready;
  assign div_finish_ready = out_ready & out_valid;

  VectorFloatDivider vfdivs_0 (
    .clock             (clock),
    .reset             (reset),
    .io_start_valid_i  (in_valid),
    .io_start_ready_o  (div_start_ready[0]),
    .io_flush_i        (need_flush),
    .io_fp_format_i    (in_vsew),
    .io_opa_i          (vs2_half[0]),
    .io_opb_i          (vs1_half[0]),
    .io_is_sqrt_i      (in_fuOpType[0]),
    .io_rm_i           (frm),
    .io_finish_valid_o (div_finish_valid[0]),
    .io_finish_ready_i (div_finish_ready),
    .io_fpdiv_res_o    (div_result[0]),
    .io_fflags_o       (div_fflags[0])
  );
  VectorFloatDivider vfdivs_1 (
    .clock             (clock),
    .reset             (reset),
    .io_start_valid_i  (in_valid),
    .io_start_ready_o  (div_start_ready[1]),
    .io_flush_i        (need_flush),
    .io_fp_format_i    (in_vsew),
    .io_opa_i          (vs2_half[1]),
    .io_opb_i          (vs1_half[1]),
    .io_is_sqrt_i      (in_fuOpType[0]),
    .io_rm_i           (frm),
    .io_finish_valid_o (div_finish_valid[1]),
    .io_finish_ready_i (div_finish_ready),
    .io_fpdiv_res_o    (div_result[1]),
    .io_fflags_o       (div_fflags[1])
  );
  assign in_ready  = div_start_ready[0] & div_start_ready[1];
  assign out_valid = div_finish_valid[0] & div_finish_valid[1];

  // ---------------------------------------------------------------------------
  // §4 写回：Mgu 合并 + 活跃元素的 fflags 合并
  // ---------------------------------------------------------------------------
  logic         need_clear_mask;
  logic [127:0] src_mask;
  assign need_clear_mask = (hold_fuOpType == OP_VMADC_VV) | (hold_fuOpType == OP_VMSBC_VV);
  assign src_mask        = need_clear_mask ? '0 : (hold_vm ? '1 : hold_v0);

  Mgu mgu (
    .io_in_vd           ({div_result[1], div_result[0]}),
    .io_in_oldVd        (hold_oldVd),
    .io_in_mask         (src_mask),
    .io_in_info_ta      (hold_vta),
    .io_in_info_ma      (hold_vma),
    .io_in_info_vl      (hold_vl),
    .io_in_info_vstart  (hold_vstart),
    .io_in_info_eew     (hold_vsew),
    .io_in_info_vdIdx   (hold_vuopIdx),
    .io_in_info_narrow  (hold_isNarrow),
    .io_in_info_dstMask (hold_isDstMask),
    .io_out_vd          (out_res_data),
    .io_out_active      ()
  );

  logic [7:0] fflags_en;
  xs_VecFflagsElemMask u_fflags_en (
    .eew        (hold_vsew),
    .vlmul_frac (hold_vlmul[2]),
    .vlmul_fix  (hold_vlmul),
    .uop_idx    (hold_vuopIdx),
    .vl         (hold_vl),
    .mask       (src_mask),
    .elem_en    (fflags_en)
  );
  logic [39:0] all_fflags;       // 8 组：{高 64 位的 4 组, 低 64 位的 4 组}
  assign all_fflags = {div_fflags[1], div_fflags[0]};
  always_comb begin
    out_res_fflags = 5'h0;
    for (int k = 0; k < 8; k++)
      if (fflags_en[k]) out_res_fflags |= all_fflags[5*k +: 5];
  end

  // ---------------------------------------------------------------------------
  // §5 出口控制/调试信息：握手拍锁存，结果出来时原样交回
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (in_fire) begin
      out_robIdx_flag  <= in_robIdx_flag;
      out_robIdx_value <= in_robIdx_value;
      out_pdest        <= in_pdest;
      out_vecWen       <= in_vecWen;
      out_v0Wen        <= in_v0Wen;
      out_fpu_wflags   <= in_fpu_wflags;
      out_debug        <= in_debug;
    end
  end
endmodule

// -----------------------------------------------------------------------------
// VFDivSqrt —— golden 同名 wrapper：端口逐位同名，打包结构体后例化核
// -----------------------------------------------------------------------------
module VFDivSqrt
  import vfdivsqrt_pkg::*;
(
  input  logic           clock,
  input  logic           reset,
  input  logic           io_flush_valid,
  input  logic           io_flush_bits_robIdx_flag,
  input  logic [7:0]     io_flush_bits_robIdx_value,
  input  logic           io_flush_bits_level,
  output logic           io_in_ready,
  input  logic           io_in_valid,
  input  logic [8:0]     io_in_bits_ctrl_fuOpType,
  input  logic           io_in_bits_ctrl_robIdx_flag,
  input  logic [7:0]     io_in_bits_ctrl_robIdx_value,
  input  logic [7:0]     io_in_bits_ctrl_pdest,
  input  logic           io_in_bits_ctrl_vecWen,
  input  logic           io_in_bits_ctrl_v0Wen,
  input  logic           io_in_bits_ctrl_fpu_wflags,
  input  logic           io_in_bits_ctrl_vpu_vma,
  input  logic           io_in_bits_ctrl_vpu_vta,
  input  logic [1:0]     io_in_bits_ctrl_vpu_vsew,
  input  logic [2:0]     io_in_bits_ctrl_vpu_vlmul,
  input  logic           io_in_bits_ctrl_vpu_vm,
  input  logic [7:0]     io_in_bits_ctrl_vpu_vstart,
  input  logic [6:0]     io_in_bits_ctrl_vpu_vuopIdx,
  input  logic           io_in_bits_ctrl_vpu_isNarrow,
  input  logic           io_in_bits_ctrl_vpu_isDstMask,
  input  logic [7:0]     io_in_bits_data_src_4,
  input  logic [127:0]   io_in_bits_data_src_3,
  input  logic [127:0]   io_in_bits_data_src_2,
  input  logic [127:0]   io_in_bits_data_src_1,
  input  logic [127:0]   io_in_bits_data_src_0,
  input  logic           io_in_bits_perfDebugInfo_eliminatedMove,
  input  logic [63:0]    io_in_bits_perfDebugInfo_renameTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_dispatchTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_enqRsTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_selectTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_issueTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_writebackTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  logic [63:0]    io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_tlbRespTime,
  input  logic [55:0]    io_in_bits_debug_seqNum_seqNum,
  input  logic [7:0]     io_in_bits_debug_seqNum_uopIdx,
  input  logic           io_out_ready,
  output logic           io_out_valid,
  output logic           io_out_bits_ctrl_robIdx_flag,
  output logic [7:0]     io_out_bits_ctrl_robIdx_value,
  output logic [7:0]     io_out_bits_ctrl_pdest,
  output logic           io_out_bits_ctrl_vecWen,
  output logic           io_out_bits_ctrl_v0Wen,
  output logic           io_out_bits_ctrl_fpu_wflags,
  output logic [127:0]   io_out_bits_res_data,
  output logic [4:0]     io_out_bits_res_fflags,
  output logic           io_out_bits_perfDebugInfo_eliminatedMove,
  output logic [63:0]    io_out_bits_perfDebugInfo_renameTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_dispatchTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_enqRsTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_selectTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_issueTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_writebackTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output logic [63:0]    io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_tlbRespTime,
  output logic [55:0]    io_out_bits_debug_seqNum_seqNum,
  output logic [7:0]     io_out_bits_debug_seqNum_uopIdx,
  input  logic [2:0]     io_frm
);
  debug_info_t in_debug, out_debug;
  assign in_debug = '{
    eliminatedMove:         io_in_bits_perfDebugInfo_eliminatedMove,
    renameTime:             io_in_bits_perfDebugInfo_renameTime,
    dispatchTime:           io_in_bits_perfDebugInfo_dispatchTime,
    enqRsTime:              io_in_bits_perfDebugInfo_enqRsTime,
    selectTime:             io_in_bits_perfDebugInfo_selectTime,
    issueTime:              io_in_bits_perfDebugInfo_issueTime,
    writebackTime:          io_in_bits_perfDebugInfo_writebackTime,
    runahead_checkpoint_id: io_in_bits_perfDebugInfo_runahead_checkpoint_id,
    tlbFirstReqTime:        io_in_bits_perfDebugInfo_tlbFirstReqTime,
    tlbRespTime:            io_in_bits_perfDebugInfo_tlbRespTime,
    seqNum:                 io_in_bits_debug_seqNum_seqNum,
    seqNum_uopIdx:          io_in_bits_debug_seqNum_uopIdx
  };

  xs_VFDivSqrt_core u_core (
    .clock              (clock),
    .reset              (reset),
    .flush_valid        (io_flush_valid),
    .flush_robIdx_flag  (io_flush_bits_robIdx_flag),
    .flush_robIdx_value (io_flush_bits_robIdx_value),
    .flush_level        (io_flush_bits_level),
    .in_ready           (io_in_ready),
    .in_valid           (io_in_valid),
    .in_fuOpType        (io_in_bits_ctrl_fuOpType),
    .in_robIdx_flag     (io_in_bits_ctrl_robIdx_flag),
    .in_robIdx_value    (io_in_bits_ctrl_robIdx_value),
    .in_pdest           (io_in_bits_ctrl_pdest),
    .in_vecWen          (io_in_bits_ctrl_vecWen),
    .in_v0Wen           (io_in_bits_ctrl_v0Wen),
    .in_fpu_wflags      (io_in_bits_ctrl_fpu_wflags),
    .in_vma             (io_in_bits_ctrl_vpu_vma),
    .in_vta             (io_in_bits_ctrl_vpu_vta),
    .in_vsew            (io_in_bits_ctrl_vpu_vsew),
    .in_vlmul           (io_in_bits_ctrl_vpu_vlmul),
    .in_vm              (io_in_bits_ctrl_vpu_vm),
    .in_vstart          (io_in_bits_ctrl_vpu_vstart),
    .in_vuopIdx         (io_in_bits_ctrl_vpu_vuopIdx),
    .in_isNarrow        (io_in_bits_ctrl_vpu_isNarrow),
    .in_isDstMask       (io_in_bits_ctrl_vpu_isDstMask),
    .in_vl              (io_in_bits_data_src_4),
    .in_v0              (io_in_bits_data_src_3),
    .in_oldVd           (io_in_bits_data_src_2),
    .in_vs2             (io_in_bits_data_src_1),
    .in_vs1             (io_in_bits_data_src_0),
    .in_debug           (in_debug),
    .frm                (io_frm),
    .out_ready          (io_out_ready),
    .out_valid          (io_out_valid),
    .out_robIdx_flag    (io_out_bits_ctrl_robIdx_flag),
    .out_robIdx_value   (io_out_bits_ctrl_robIdx_value),
    .out_pdest          (io_out_bits_ctrl_pdest),
    .out_vecWen         (io_out_bits_ctrl_vecWen),
    .out_v0Wen          (io_out_bits_ctrl_v0Wen),
    .out_fpu_wflags     (io_out_bits_ctrl_fpu_wflags),
    .out_res_data       (io_out_bits_res_data),
    .out_res_fflags     (io_out_bits_res_fflags),
    .out_debug          (out_debug)
  );

  assign io_out_bits_perfDebugInfo_eliminatedMove         = out_debug.eliminatedMove;
  assign io_out_bits_perfDebugInfo_renameTime             = out_debug.renameTime;
  assign io_out_bits_perfDebugInfo_dispatchTime           = out_debug.dispatchTime;
  assign io_out_bits_perfDebugInfo_enqRsTime              = out_debug.enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime             = out_debug.selectTime;
  assign io_out_bits_perfDebugInfo_issueTime              = out_debug.issueTime;
  assign io_out_bits_perfDebugInfo_writebackTime          = out_debug.writebackTime;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = out_debug.runahead_checkpoint_id;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime        = out_debug.tlbFirstReqTime;
  assign io_out_bits_perfDebugInfo_tlbRespTime            = out_debug.tlbRespTime;
  assign io_out_bits_debug_seqNum_seqNum                  = out_debug.seqNum;
  assign io_out_bits_debug_seqNum_uopIdx                  = out_debug.seqNum_uopIdx;
endmodule
