// =============================================================================
// VIDiv.sv —— 向量整数除法功能单元外壳（vdiv/vdivu/vrem/vremu）
//
// 在哪一层：ExeUnit_17（向量除法执行单元）的 FU。把一条 vdiv 类 uop 交给 VectorIdiv
//   （128 位、按 SEW 拆 16 个除法器并行）去算，算完按 RVV 的 vstart / vl / 掩码 /
//   vta / vma 语义经 Mgu 与旧 vd 合并，连同随 uop 搬运的控制/调试信息一起写回。
//   Scala：VIDiv extends VecNonPipedFuncUnit（多拍非流水 FU 的公共外壳）。
//
// 数据流：
//   入口握手 in.fire = in.valid & in.ready（in.ready = VectorIdiv 空闲）。
//   · VectorIdiv：被除数 vs2 = src_1，除数 vs1 = src_0，sew / sign 直接取自入口
//     （它在握手拍自己锁存）；fuOpType[0]=有符号、[1]=取商（否则取余数）。
//   · 「保持旁路」DataHoldBypass：握手拍直接用入口值，之后用握手时锁存的副本——
//     Mgu 在结果出来那拍要用的 oldVd(src_2) / v0(src_3) / vl(src_4) / vta / vma / vstart /
//     vsew / vuopIdx / narrow / dstMask 都走这条路（out* 信号）。
//   · 冲刷：本 uop 的 robIdx（空闲时看入口的、忙时看锁存的）比冲刷点年轻，或
//     冲刷级别 level=1 且正好是这条 → 冲刷 VectorIdiv。
//   · 出口：out.valid = VectorIdiv 出结果；VectorIdiv 的 out_ready = out.ready & out.valid。
//     vl=0 时整个 vd 保持旧值（不经 Mgu）。
// ★bug-for-bug 要点★
//   · 掩码：vm=1 → 全 1；否则取 v0。但在这之前先判 VialuFixType.needClearMask(fuOpType)
//     （fuOpType 为 vmadc.vv=0x84 或 vmsbc.vv=0x86 时掩码清 0）——这是公共外壳按 VIAlu 的
//     编码写的，对 vdiv 类 opType 永不命中，照抄。
//   · Mgu 的 vdIdx 只取 vuopIdx 低 3 位。
//   · fuOpType==0xFF（dummy）时 golden 在非 SYNTHESIS 下有一条 assert；SYNTHESIS 下该块被
//     裁掉，本核不含对应逻辑（与 FAlu 等重写件同口径）。
//   · 出口的 robIdx/pdest/vecWen/v0Wen 与调试信息在握手拍锁存，无复位。
//
// 子模块（两侧白盒，本仓已签核重写件）：VectorIdiv（实例名 vidiv）、Mgu（实例名 mgu）。
// 设计源：src/main/scala/xiangshan/backend/fu/wrapper/VIDiv.scala、fu/vector/VecNonPipedFuncUnit.scala
// golden 对照：G1-canonical/golden-rtl/VIDiv.sv
// =============================================================================

package vidiv_pkg;
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

  // Mgu 需要的向量控制字段（握手后保持）
  typedef struct packed {
    logic [8:0] fuOpType;
    logic       robIdx_flag;
    logic [7:0] robIdx_value;
    logic       vma;
    logic       vta;
    logic [1:0] vsew;
    logic       vm;
    logic [7:0] vstart;
    logic [6:0] vuopIdx;
    logic       isNarrow;
    logic       isDstMask;
  } vec_ctrl_t;

  localparam logic [8:0] OP_VMADC_VV = 9'h084;   // VialuFixType.vmadc_vv
  localparam logic [8:0] OP_VMSBC_VV = 9'h086;   // VialuFixType.vmsbc_vv
endpackage

// -----------------------------------------------------------------------------
// xs_VIDiv_core —— 可读核
// -----------------------------------------------------------------------------
module xs_VIDiv_core
  import vidiv_pkg::*;
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
  input  vec_ctrl_t    in_ctrl,
  input  logic [7:0]   in_pdest,
  input  logic         in_vecWen,
  input  logic         in_v0Wen,
  input  logic [7:0]   in_vl,          // src_4
  input  logic [127:0] in_v0,          // src_3：掩码
  input  logic [127:0] in_oldVd,       // src_2
  input  logic [127:0] in_vs2,         // src_1：被除数
  input  logic [127:0] in_vs1,         // src_0：除数
  input  debug_info_t  in_debug,
  // 出口
  input  logic         out_ready,
  output logic         out_valid,
  output logic         out_robIdx_flag,
  output logic [7:0]   out_robIdx_value,
  output logic [7:0]   out_pdest,
  output logic         out_vecWen,
  output logic         out_v0Wen,
  output logic [127:0] out_res_data,
  output debug_info_t  out_debug
);

  logic in_fire;
  assign in_fire = in_valid & in_ready;

  // ---------------------------------------------------------------------------
  // §1 保持旁路（DataHoldBypass）：握手拍用入口值，其后用锁存副本
  // ---------------------------------------------------------------------------
  vec_ctrl_t    outCtrl_r, outCtrl;
  logic [7:0]   outData_r_src_4, out_vl;
  logic [127:0] outData_r_src_3, outData_r_src_2, out_v0, out_oldVd;
  always_ff @(posedge clock) begin
    if (in_fire) begin
      outCtrl_r       <= in_ctrl;
      outData_r_src_4 <= in_vl;
      outData_r_src_3 <= in_v0;
      outData_r_src_2 <= in_oldVd;
    end
  end
  assign outCtrl   = in_fire ? in_ctrl  : outCtrl_r;
  assign out_vl    = in_fire ? in_vl    : outData_r_src_4;
  assign out_v0    = in_fire ? in_v0    : outData_r_src_3;
  assign out_oldVd = in_fire ? in_oldVd : outData_r_src_2;

  // ---------------------------------------------------------------------------
  // §2 冲刷判定：RobPtr.needFlush —— 比冲刷点年轻，或 level=1 且就是这条
  //   年轻 = isAfter(this, flush) = (flag 不同) ^ (value 更大)（环形队列指针比较）
  // ---------------------------------------------------------------------------
  logic       this_flag, need_flush;
  logic [7:0] this_value;
  assign this_flag  = in_ready ? in_ctrl.robIdx_flag  : outCtrl_r.robIdx_flag;
  assign this_value = in_ready ? in_ctrl.robIdx_value : outCtrl_r.robIdx_value;
  assign need_flush = flush_valid &
                      (((this_flag ^ flush_robIdx_flag) ^ (this_value > flush_robIdx_value)) |
                       (flush_level & {this_flag, this_value} == {flush_robIdx_flag, flush_robIdx_value}));

  // ---------------------------------------------------------------------------
  // §3 向量除法器
  // ---------------------------------------------------------------------------
  logic         div_out_valid;
  logic [127:0] div_q, div_rem;
  VectorIdiv vidiv (
    .clock            (clock),
    .reset            (reset),
    .io_sew           (in_ctrl.vsew),
    .io_sign          (in_ctrl.fuOpType[0]),     // VidivType.isSigned
    .io_dividend_v    (in_vs2),
    .io_divisor_v     (in_vs1),
    .io_flush         (need_flush),
    .io_div_in_valid  (in_valid),
    .io_div_in_ready  (in_ready),
    .io_div_out_ready (out_ready & div_out_valid),
    .io_div_out_valid (div_out_valid),
    .io_div_out_q_v   (div_q),
    .io_div_out_rem_v (div_rem)
  );
  assign out_valid = div_out_valid;

  // ---------------------------------------------------------------------------
  // §4 Mask/tail 合并（Mgu）与写回数据
  // ---------------------------------------------------------------------------
  logic         need_clear_mask;
  logic [127:0] mgu_mask, mgu_vd;
  assign need_clear_mask = outCtrl.fuOpType == OP_VMADC_VV | outCtrl.fuOpType == OP_VMSBC_VV;
  assign mgu_mask        = need_clear_mask ? '0 : (outCtrl.vm ? '1 : out_v0);

  Mgu mgu (
    .io_in_vd           (outCtrl.fuOpType[1] ? div_q : div_rem),   // VidivType.isDiv
    .io_in_oldVd        (out_oldVd),
    .io_in_mask         (mgu_mask),
    .io_in_info_ta      (outCtrl.vta),
    .io_in_info_ma      (outCtrl.vma),
    .io_in_info_vl      (out_vl),
    .io_in_info_vstart  (outCtrl.vstart),
    .io_in_info_eew     (outCtrl.vsew),
    .io_in_info_vdIdx   (outCtrl.vuopIdx[2:0]),
    .io_in_info_narrow  (outCtrl.isNarrow),
    .io_in_info_dstMask (outCtrl.isDstMask),
    .io_out_vd          (mgu_vd),
    .io_out_active      ()
  );
  assign out_res_data = (out_vl == 8'd0) ? out_oldVd : mgu_vd;   // vl=0：不改 vd

  // ---------------------------------------------------------------------------
  // §5 出口控制/调试信息：握手拍锁存，结果出来时原样交回
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (in_fire) begin
      out_robIdx_flag  <= in_ctrl.robIdx_flag;
      out_robIdx_value <= in_ctrl.robIdx_value;
      out_pdest        <= in_pdest;
      out_vecWen       <= in_vecWen;
      out_v0Wen        <= in_v0Wen;
      out_debug        <= in_debug;
    end
  end
endmodule

// -----------------------------------------------------------------------------
// VIDiv —— golden 同名 wrapper：端口逐位同名，打包成结构体后例化核
// -----------------------------------------------------------------------------
module VIDiv
  import vidiv_pkg::*;
(
  input          clock,
  input          reset,
  input          io_flush_valid,
  input          io_flush_bits_robIdx_flag,
  input  [7:0]   io_flush_bits_robIdx_value,
  input          io_flush_bits_level,
  output         io_in_ready,
  input          io_in_valid,
  input  [8:0]   io_in_bits_ctrl_fuOpType,
  input          io_in_bits_ctrl_robIdx_flag,
  input  [7:0]   io_in_bits_ctrl_robIdx_value,
  input  [7:0]   io_in_bits_ctrl_pdest,
  input          io_in_bits_ctrl_vecWen,
  input          io_in_bits_ctrl_v0Wen,
  input          io_in_bits_ctrl_vpu_vma,
  input          io_in_bits_ctrl_vpu_vta,
  input  [1:0]   io_in_bits_ctrl_vpu_vsew,
  input          io_in_bits_ctrl_vpu_vm,
  input  [7:0]   io_in_bits_ctrl_vpu_vstart,
  input  [6:0]   io_in_bits_ctrl_vpu_vuopIdx,
  input          io_in_bits_ctrl_vpu_isNarrow,
  input          io_in_bits_ctrl_vpu_isDstMask,
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
  vec_ctrl_t   in_ctrl;
  debug_info_t in_debug, out_debug;

  assign in_ctrl = '{
    fuOpType:     io_in_bits_ctrl_fuOpType,
    robIdx_flag:  io_in_bits_ctrl_robIdx_flag,
    robIdx_value: io_in_bits_ctrl_robIdx_value,
    vma:          io_in_bits_ctrl_vpu_vma,
    vta:          io_in_bits_ctrl_vpu_vta,
    vsew:         io_in_bits_ctrl_vpu_vsew,
    vm:           io_in_bits_ctrl_vpu_vm,
    vstart:       io_in_bits_ctrl_vpu_vstart,
    vuopIdx:      io_in_bits_ctrl_vpu_vuopIdx,
    isNarrow:     io_in_bits_ctrl_vpu_isNarrow,
    isDstMask:    io_in_bits_ctrl_vpu_isDstMask
  };
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

  xs_VIDiv_core u_core (
    .clock              (clock),
    .reset              (reset),
    .flush_valid        (io_flush_valid),
    .flush_robIdx_flag  (io_flush_bits_robIdx_flag),
    .flush_robIdx_value (io_flush_bits_robIdx_value),
    .flush_level        (io_flush_bits_level),
    .in_ready           (io_in_ready),
    .in_valid           (io_in_valid),
    .in_ctrl            (in_ctrl),
    .in_pdest           (io_in_bits_ctrl_pdest),
    .in_vecWen          (io_in_bits_ctrl_vecWen),
    .in_v0Wen           (io_in_bits_ctrl_v0Wen),
    .in_vl              (io_in_bits_data_src_4),
    .in_v0              (io_in_bits_data_src_3),
    .in_oldVd           (io_in_bits_data_src_2),
    .in_vs2             (io_in_bits_data_src_1),
    .in_vs1             (io_in_bits_data_src_0),
    .in_debug           (in_debug),
    .out_ready          (io_out_ready),
    .out_valid          (io_out_valid),
    .out_robIdx_flag    (io_out_bits_ctrl_robIdx_flag),
    .out_robIdx_value   (io_out_bits_ctrl_robIdx_value),
    .out_pdest          (io_out_bits_ctrl_pdest),
    .out_vecWen         (io_out_bits_ctrl_vecWen),
    .out_v0Wen          (io_out_bits_ctrl_v0Wen),
    .out_res_data       (io_out_bits_res_data),
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
