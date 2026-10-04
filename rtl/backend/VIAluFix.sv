// =============================================================================
// VIAluFix.sv —— 向量整数 / 定点 ALU 功能单元外壳（vadd/vsub/vwadd/比较/vmadc/移位/vsadd/vaadd/vnclip/vext/vwsll …，1 拍流水）
//
// 在哪一层：ExeUnit 里的向量整数 ALU FU。一条 uop 的 128 位向量拆成低 / 高两个 64 位 lane，各交给一个 VIntFixpAlu64b；
//   结果在第 1 级按 RVV 的 vstart / vl / 掩码 / vta / vma 语义经 Mgu 合并（产生掩码的指令再经 Mgtu 处理尾部），并给出 vxsat。
//   Scala：VIAluFix extends VecPipedFuncUnit（第 1 级控制 / 数据由发射级预打好，从 ctrlPipe_1 / dataPipe_1 / validPipe_1 进来）。
//
// 数据流：
//   §1 本 FU 的 valid / 反压（LAT=1：rdy0 = ~valid_1 | out_ready）；调试信息随流水搬 1 级（受 ready 门控）。
//   §2 第 0 级译码：VIAluSrcTypeModule 给出 vs2 / vs1 / vd 的元素类型；opcode = fuOpType[5:0] 查 VIntFixpTable 得 isSub / isMisc；
//      加宽（加减类且 vs1 与 vd 宽度不同）、vs2 也加宽（.vv 形式）、vwsll（加宽左移）按结果宽度分三档。
//   §3 两个 lane 的操作数：加宽 / 变窄 / vwsll→64 时取「同 lane 的 32 位块对」(块 i、i+2)，vwsll→32 / →16 取同 lane 的 16 / 8 位块交错，
//      其余取 64 位半边；vext 的 vs2 按 F2 / F4 / F8 取 32 / 16 / 8 位块交错。
//   §4 第 0 级掩码与旧 vd 的切片：v0 按 SEW 切成 8 组（每组本 uop 用的掩码位），掩码组号 = narrow ? vuopIdx[3:1] : vuopIdx[2:0]；
//      再按元素宽度（结果是掩码时按 vs1 宽度）分给两个 lane 各 8 位；旧 vd 同样按 vs1 宽度切片给 vmadc 类用。
//   §5 两个 VIntFixpAlu64b（fire = in_valid，不看 ready）。
//   §6 第 1 级寄存器：vwsll 三档标志（in_valid 使能）、vs1 宽度独热（validPipe_0 & in_valid & rdy0 使能，Scala SNReg）。
//   §7 写回：vwsll 结果按 lane 交错还原元素顺序；比较结果按 vs1 宽度拼成 16 位、vl 之外的位强制 1（尾部一律 agnostic）；
//      Mgu 的输入 vd 三选一（变窄：两 lane 的窄结果拼到旧 vd 的低 / 高半；产生掩码：带尾部的比较位；其余：vd）；
//      Mgu 掩码：vadc/vmadc/vmerge 等不用掩码的指令全 1；vmv.s.x 的 vl 当 1；加宽指令的 eew = vsew+1；
//      vstart >= vl 时结果整个保持旧 vd、vxsat=0。
// ★bug-for-bug 要点★
//   · 第 0 级 srcMask 对 fuOpType 0x84/0x86（vmadc.vv / vmsbc.vv）清 0；第 1 级送 Mgu 的掩码里同样的判断写在「不用掩码 → 全 1」之后，
//     永不命中（golden 原样，本核按其等价语义只保留前者）。
//   · isSub / isMisc 来自 QMC 化简后的译码表（表里有无关项），本核按 golden 化简结果逐码列出，不按 Scala 原表重推。
//   · 比较结果的「尾部」用 9 位比较 elementsComputed + i >= vl（不截断）。
//   · fuOpType==0 的 assert 只在非 SYNTHESIS 下存在，本核不写。
// 子模块（两侧白盒）：VIAluSrcTypeModule typeMod、VecDataSplitModule vs2Split / vs1Split、VIntFixpAlu64b vIntFixpAlus_0 / _1、
//   Mgu mgu、Mgtu mgtu（实例名与 golden 一致；本仓已签核重写件）。
// 设计源：src/main/scala/xiangshan/backend/fu/wrapper/VIAluFix.scala、fu/vector/VecPipedFuncUnit.scala
// golden 对照：G1-canonical/golden-rtl/VIAluFix.sv
// =============================================================================

package viafix_pkg;
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

  localparam logic [8:0] OP_VMADC_VV = 9'h084;   // VialuFixType.vmadc_vv
  localparam logic [8:0] OP_VMSBC_VV = 9'h086;   // VialuFixType.vmsbc_vv
  localparam logic [5:0] OPC_VWSLL   = 6'h37;    // VialuOpcode.vwsll
  localparam logic [5:0] OPC_VMV_S_X = 6'h2E;    // VialuOpcode.vmvsx：vl 当 1

  // VialuFixType.needNoMask：vadc / vmadc / vsbc / vmsbc（带进位借位的整组运算）与 vmerge —— 不用 v0 做掩码
  function automatic logic need_no_mask(input logic [8:0] fu);
    return fu == 9'h003 || fu == 9'h104 || fu == 9'h084 || fu == 9'h005 ||
           fu == 9'h106 || fu == 9'h086 || fu == 9'h019;
  endfunction

  // VIntFixpTable 经 QMC 化简后的 isSub（表里 vmseq / vmsne 与缺省项是无关项，此处是 golden 的取值）
  function automatic logic fixp_is_sub(input logic [5:0] op);
    case (op)
      6'h01, 6'h05, 6'h06, 6'h10, 6'h11, 6'h12, 6'h13, 6'h14, 6'h15, 6'h16, 6'h17, 6'h18,
      6'h1A, 6'h1C, 6'h1E: return 1'b1;
      default:             return 1'b0;
    endcase
  endfunction
  // 同表的 isMisc（golden 化简结果：下列 opcode 为 0，其余为 1）
  function automatic logic fixp_is_misc(input logic [5:0] op);
    case (op)
      6'h00, 6'h01, 6'h03, 6'h04, 6'h05, 6'h06, 6'h12, 6'h13, 6'h14, 6'h15, 6'h16, 6'h17,
      6'h18, 6'h1B, 6'h1C, 6'h1D, 6'h1E: return 1'b0;
      default:                           return 1'b1;
    endcase
  endfunction

  // Utils.VecDataToMaskDataVec 的第 g 组：一个 128 位寄存器按 SEW 能装的元素个数为一组，取第 g 组的掩码位（低位对齐）
  function automatic logic [15:0] mask_group(input logic [127:0] v, input logic [1:0] sew, input logic [2:0] g);
    case (sew)
      2'd0:    return v[g*16 +: 16];
      2'd1:    return {8'h0,  v[g*8 +: 8]};
      2'd2:    return {12'h0, v[g*4 +: 4]};
      default: return {14'h0, v[g*2 +: 2]};
    endcase
  endfunction

  // VIAluFix.splitMask 的第 lane 个 8 位：按元素宽度把一组掩码位分给两个 64 位 lane
  function automatic logic [7:0] lane_mask(input logic [15:0] m, input logic [3:0] sew_oh, input int lane);
    return (sew_oh[0] ? m[lane*8 +: 8]          : 8'h0)
         | (sew_oh[1] ? {4'h0, m[lane*4 +: 4]}  : 8'h0)
         | (sew_oh[2] ? {6'h0, m[lane*2 +: 2]}  : 8'h0)
         | (sew_oh[3] ? {7'h0, m[lane]}         : 8'h0);
  endfunction
endpackage

// -----------------------------------------------------------------------------
// xs_VIAluFix_core —— 可读核
// -----------------------------------------------------------------------------
module xs_VIAluFix_core
  import viafix_pkg::*;
(
  input  logic         clock,
  input  logic         reset,
  // ---- 第 0 级（送进两个 ALU）----
  output logic         in_ready,
  input  logic         in_valid,
  input  logic [8:0]   in_fuOpType,
  input  logic         in_vma,
  input  logic [1:0]   in_vsew,
  input  logic         in_vm,
  input  logic [6:0]   in_vuopIdx,
  input  logic         in_isExt,
  input  logic         in_isNarrow,
  input  logic         in_isDstMask,
  input  logic         in_validPipe0,      // validPipe_0
  input  logic [127:0] in_v0,              // src_3
  input  logic [127:0] in_oldVd,           // src_2
  input  logic [127:0] in_vs2,             // src_1
  input  logic [127:0] in_vs1,             // src_0
  input  perf_dbg_t    in_perf,
  input  seq_num_t     in_seq,
  input  logic [1:0]   vxrm,
  // ---- 第 1 级（发射级预打好的控制 / 数据）----
  input  logic [8:0]   s1_fuOpType,
  input  logic         s1_robIdx_flag,
  input  logic [7:0]   s1_robIdx_value,
  input  logic [7:0]   s1_pdest,
  input  logic         s1_vecWen,
  input  logic         s1_v0Wen,
  input  logic         s1_vma,
  input  logic         s1_vta,
  input  logic [1:0]   s1_vsew,
  input  logic         s1_vm,
  input  logic [7:0]   s1_vstart,
  input  logic [6:0]   s1_vuopIdx,
  input  logic         s1_isExt,
  input  logic         s1_isNarrow,
  input  logic         s1_isDstMask,
  input  logic         s1_isOpMask,
  input  logic         s1_valid,           // validPipe_1
  input  logic [7:0]   s1_vl,              // dataPipe_1 src_4
  input  logic [127:0] s1_v0,              // dataPipe_1 src_3
  input  logic [127:0] s1_oldVd,           // dataPipe_1 src_2
  // ---- 出口 ----
  input  logic         out_ready,
  output logic         out_valid,
  output logic         out_robIdx_flag,
  output logic [7:0]   out_robIdx_value,
  output logic [7:0]   out_pdest,
  output logic         out_vecWen,
  output logic         out_v0Wen,
  output logic [127:0] out_res_data,
  output logic         out_res_vxsat,
  output perf_dbg_t    out_perf,
  output seq_num_t     out_seq
);
  // ---------------------------------------------------------------------------
  // §1 valid / 反压（LAT=1）；调试信息搬 1 级
  // ---------------------------------------------------------------------------
  logic validVecThisFu_1;
  logic rdy0;
  assign rdy0     = ~validVecThisFu_1 | out_ready;
  assign in_ready = rdy0;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) validVecThisFu_1 <= 1'b0;
    else       validVecThisFu_1 <= in_valid;                      // 不受 ready 门控（照 golden）
  end

  perf_dbg_t perf_s1;
  seq_num_t  seq_s1;
  always_ff @(posedge clock) begin
    if (rdy0 & in_valid) begin
      perf_s1 <= in_perf;
      seq_s1  <= in_seq;
    end
  end

  // ---------------------------------------------------------------------------
  // §2 第 0 级译码
  // ---------------------------------------------------------------------------
  logic [5:0] opcode;
  logic [3:0] vs1Type, vs2Type, vdType;
  logic       isVextF2, isVextF4, isVextF8;
  assign opcode = in_fuOpType[5:0];

  VIAluSrcTypeModule typeMod (
    .io_in_fuOpType  (in_fuOpType),
    .io_in_vsew      (in_vsew),
    .io_in_isExt     (in_isExt),
    .io_in_isDstMask (in_isDstMask),
    .io_out_vs1Type  (vs1Type),
    .io_out_vs2Type  (vs2Type),
    .io_out_vdType   (vdType),
    .io_out_isVextF2 (isVextF2),
    .io_out_isVextF4 (isVextF4),
    .io_out_isVextF8 (isVextF8)
  );

  logic is_sub, is_misc, is_fixp, widen, widen_vs2, is_vwsll, vwsll64, vwsll32, vwsll16;
  logic [3:0] eewVs1_oneHot, eewVd_oneHot;
  assign is_sub    = fixp_is_sub(opcode);
  assign is_misc   = fixp_is_misc(opcode);
  // 定点类：misc 时是缩放移位（vssrl/vssra），否则是饱和加减 / 平均加减
  assign is_fixp   = is_misc ? (opcode == 6'h1F || opcode == 6'h20)
                             : (opcode == 6'h1B || opcode == 6'h1C || opcode == 6'h1D || opcode == 6'h1E);
  assign widen     = (opcode == 6'h00 || opcode == 6'h01) && (vs1Type[1:0] != vdType[1:0]);  // 加减且 vs1 比 vd 窄
  assign widen_vs2 = widen && (vs2Type[1:0] != vdType[1:0]);                                 // .vv 形式：vs2 也窄
  assign eewVs1_oneHot = {vs1Type[1:0] == 2'd3, vs1Type[1:0] == 2'd2, vs1Type[1:0] == 2'd1, vs1Type[1:0] == 2'd0};
  assign eewVd_oneHot  = {vdType[1:0] == 2'd3,  vdType[1:0] == 2'd2,  vdType[1:0] == 2'd1,  vdType[1:0] == 2'd0};
  assign is_vwsll  = (opcode == OPC_VWSLL);
  assign vwsll64   = is_vwsll & (vdType[1:0] == 2'd3);
  assign vwsll32   = is_vwsll & (vdType[1:0] == 2'd2);
  assign vwsll16   = is_vwsll & (vdType[1:0] == 2'd1);

  // ---------------------------------------------------------------------------
  // §3 两个 lane 的操作数
  // ---------------------------------------------------------------------------
  logic [7:0]  vs2_8 [16], vs1_8 [16];
  logic [15:0] vs2_16 [8], vs1_16 [8];
  logic [31:0] vs2_32 [4], vs1_32 [4];
  logic [63:0] vs2_64 [2], vs1_64 [2];
  VecDataSplitModule vs2Split (
    .io_inVecData   (in_vs2),
    .io_outVec8b_0  (vs2_8[0]),  .io_outVec8b_1  (vs2_8[1]),  .io_outVec8b_2  (vs2_8[2]),  .io_outVec8b_3  (vs2_8[3]),
    .io_outVec8b_4  (vs2_8[4]),  .io_outVec8b_5  (vs2_8[5]),  .io_outVec8b_6  (vs2_8[6]),  .io_outVec8b_7  (vs2_8[7]),
    .io_outVec8b_8  (vs2_8[8]),  .io_outVec8b_9  (vs2_8[9]),  .io_outVec8b_10 (vs2_8[10]), .io_outVec8b_11 (vs2_8[11]),
    .io_outVec8b_12 (vs2_8[12]), .io_outVec8b_13 (vs2_8[13]), .io_outVec8b_14 (vs2_8[14]), .io_outVec8b_15 (vs2_8[15]),
    .io_outVec16b_0 (vs2_16[0]), .io_outVec16b_1 (vs2_16[1]), .io_outVec16b_2 (vs2_16[2]), .io_outVec16b_3 (vs2_16[3]),
    .io_outVec16b_4 (vs2_16[4]), .io_outVec16b_5 (vs2_16[5]), .io_outVec16b_6 (vs2_16[6]), .io_outVec16b_7 (vs2_16[7]),
    .io_outVec32b_0 (vs2_32[0]), .io_outVec32b_1 (vs2_32[1]), .io_outVec32b_2 (vs2_32[2]), .io_outVec32b_3 (vs2_32[3]),
    .io_outVec64b_0 (vs2_64[0]),
    .io_outVec64b_1 (vs2_64[1])
  );
  VecDataSplitModule vs1Split (
    .io_inVecData   (in_vs1),
    .io_outVec8b_0  (vs1_8[0]),  .io_outVec8b_1  (vs1_8[1]),  .io_outVec8b_2  (vs1_8[2]),  .io_outVec8b_3  (vs1_8[3]),
    .io_outVec8b_4  (vs1_8[4]),  .io_outVec8b_5  (vs1_8[5]),  .io_outVec8b_6  (vs1_8[6]),  .io_outVec8b_7  (vs1_8[7]),
    .io_outVec8b_8  (vs1_8[8]),  .io_outVec8b_9  (vs1_8[9]),  .io_outVec8b_10 (vs1_8[10]), .io_outVec8b_11 (vs1_8[11]),
    .io_outVec8b_12 (vs1_8[12]), .io_outVec8b_13 (vs1_8[13]), .io_outVec8b_14 (vs1_8[14]), .io_outVec8b_15 (vs1_8[15]),
    .io_outVec16b_0 (vs1_16[0]), .io_outVec16b_1 (vs1_16[1]), .io_outVec16b_2 (vs1_16[2]), .io_outVec16b_3 (vs1_16[3]),
    .io_outVec16b_4 (vs1_16[4]), .io_outVec16b_5 (vs1_16[5]), .io_outVec16b_6 (vs1_16[6]), .io_outVec16b_7 (vs1_16[7]),
    .io_outVec32b_0 (vs1_32[0]), .io_outVec32b_1 (vs1_32[1]), .io_outVec32b_2 (vs1_32[2]), .io_outVec32b_3 (vs1_32[3]),
    .io_outVec64b_0 (vs1_64[0]),
    .io_outVec64b_1 (vs1_64[1])
  );

  // 「同 lane 交错」分组：lane i 拿编号与 i 同奇偶的块（Scala groupBy(_ % 2)），高块在高位
  logic [63:0] vs2_grp32 [2], vs2_grp16 [2], vs2_grp8 [2];
  logic [63:0] vs1_grp32 [2], vs1_grp16 [2], vs1_grp8 [2];
  for (genvar i = 0; i < 2; i++) begin : g_group
    assign vs2_grp32[i] = {vs2_32[i+2], vs2_32[i]};
    assign vs1_grp32[i] = {vs1_32[i+2], vs1_32[i]};
    assign vs2_grp16[i] = {vs2_16[i+6], vs2_16[i+4], vs2_16[i+2], vs2_16[i]};
    assign vs1_grp16[i] = {vs1_16[i+6], vs1_16[i+4], vs1_16[i+2], vs1_16[i]};
    assign vs2_grp8[i]  = {vs2_8[i+14], vs2_8[i+12], vs2_8[i+10], vs2_8[i+8], vs2_8[i+6], vs2_8[i+4], vs2_8[i+2], vs2_8[i]};
    assign vs1_grp8[i]  = {vs1_8[i+14], vs1_8[i+12], vs1_8[i+10], vs1_8[i+8], vs1_8[i+6], vs1_8[i+4], vs1_8[i+2], vs1_8[i]};
  end

  logic [63:0] lane_vs1 [2], lane_vs2_adder [2], lane_vs2_misc [2];
  for (genvar i = 0; i < 2; i++) begin : g_operand
    always_comb begin
      if (widen | in_isNarrow | vwsll64) lane_vs1[i] = vs1_grp32[i];
      else if (vwsll32)                  lane_vs1[i] = vs1_grp16[i];
      else if (vwsll16)                  lane_vs1[i] = vs1_grp8[i];
      else                               lane_vs1[i] = vs1_64[i];

      if (isVextF2 | vwsll64)      lane_vs2_misc[i] = vs2_grp32[i];
      else if (isVextF4 | vwsll32) lane_vs2_misc[i] = vs2_grp16[i];
      else if (isVextF8 | vwsll16) lane_vs2_misc[i] = vs2_grp8[i];
      else                         lane_vs2_misc[i] = vs2_64[i];
    end
    assign lane_vs2_adder[i] = widen_vs2 ? vs2_grp32[i] : vs2_64[i];
  end

  // ---------------------------------------------------------------------------
  // §4 第 0 级掩码与旧 vd 切片
  // ---------------------------------------------------------------------------
  logic [127:0] src_mask;
  logic [2:0]   mask_idx;
  logic [15:0]  mask_used_grp, old_vd_grp;
  logic [3:0]   mask_sew_oh;
  assign src_mask      = (in_fuOpType == OP_VMADC_VV || in_fuOpType == OP_VMSBC_VV) ? '0 : (in_vm ? '1 : in_v0);
  assign mask_idx      = in_isNarrow ? in_vuopIdx[3:1] : in_vuopIdx[2:0];
  assign mask_used_grp = mask_group(src_mask, in_vsew, mask_idx);
  assign mask_sew_oh   = (&vdType) ? eewVs1_oneHot : eewVd_oneHot;      // 结果是掩码（vdType=1111）时按 vs1 宽度分
  assign old_vd_grp    = mask_group(in_oldVd, vs1Type[1:0], in_vuopIdx[2:0]);

  // ---------------------------------------------------------------------------
  // §5 两个 64 位整数 / 定点 ALU
  // ---------------------------------------------------------------------------
  logic [63:0] alu_vd [2];
  logic [31:0] alu_narrow_vd [2];
  logic [7:0]  alu_cmp [2], alu_vxsat [2];

  VIntFixpAlu64b vIntFixpAlus_0 (
    .clock          (clock),
    .io_fire        (in_valid),
    .io_opcode_op   (opcode),
    .io_info_vm     (in_vm),
    .io_info_ma     (in_vma),
    .io_info_uopIdx (in_vuopIdx[5:0]),
    .io_info_vxrm   (vxrm),
    .io_srcType_0   (vs2Type),
    .io_srcType_1   (vs1Type),
    .io_vdType      (vdType),
    .io_vs1         (lane_vs1[0]),
    .io_vs2_adder   (lane_vs2_adder[0]),
    .io_vs2_misc    (lane_vs2_misc[0]),
    .io_vmask       (lane_mask(mask_used_grp, mask_sew_oh, 0)),
    .io_oldVd       (lane_mask(old_vd_grp, eewVs1_oneHot, 0)),
    .io_narrow      ({7'h0, in_isNarrow}),
    .io_isSub       (is_sub),
    .io_isMisc      (is_misc),
    .io_isFixp      (is_fixp),
    .io_widen       (widen),
    .io_widen_vs2   (widen_vs2),
    .io_vd          (alu_vd[0]),
    .io_narrowVd    (alu_narrow_vd[0]),
    .io_cmpOut      (alu_cmp[0]),
    .io_vxsat       (alu_vxsat[0])
  );
  VIntFixpAlu64b vIntFixpAlus_1 (
    .clock          (clock),
    .io_fire        (in_valid),
    .io_opcode_op   (opcode),
    .io_info_vm     (in_vm),
    .io_info_ma     (in_vma),
    .io_info_uopIdx (in_vuopIdx[5:0]),
    .io_info_vxrm   (vxrm),
    .io_srcType_0   (vs2Type),
    .io_srcType_1   (vs1Type),
    .io_vdType      (vdType),
    .io_vs1         (lane_vs1[1]),
    .io_vs2_adder   (lane_vs2_adder[1]),
    .io_vs2_misc    (lane_vs2_misc[1]),
    .io_vmask       (lane_mask(mask_used_grp, mask_sew_oh, 1)),
    .io_oldVd       (lane_mask(old_vd_grp, eewVs1_oneHot, 1)),
    .io_narrow      ({7'h0, in_isNarrow}),
    .io_isSub       (is_sub),
    .io_isMisc      (is_misc),
    .io_isFixp      (is_fixp),
    .io_widen       (widen),
    .io_widen_vs2   (widen_vs2),
    .io_vd          (alu_vd[1]),
    .io_narrowVd    (alu_narrow_vd[1]),
    .io_cmpOut      (alu_cmp[1]),
    .io_vxsat       (alu_vxsat[1])
  );

  // ---------------------------------------------------------------------------
  // §6 第 1 级寄存器（无复位；名字同 golden）
  // ---------------------------------------------------------------------------
  logic       outIsVwsll, outIsVwsllEewVdIs64, outIsVwsllEewVdIs32, outIsVwsllEewVdIs16;
  logic [3:0] outEewVs1_oneHot;
  always_ff @(posedge clock) begin
    if (in_valid) begin
      outIsVwsll          <= is_vwsll;
      outIsVwsllEewVdIs64 <= vwsll64;
      outIsVwsllEewVdIs32 <= vwsll32;
      outIsVwsllEewVdIs16 <= vwsll16;
    end
    if (in_validPipe0 & in_valid & rdy0)
      outEewVs1_oneHot <= eewVs1_oneHot;
  end

  // ---------------------------------------------------------------------------
  // §7 写回
  // ---------------------------------------------------------------------------
  // vwsll：两个 lane 各算了「同奇偶」的那些元素，这里交错回原来的元素顺序（Mux1H 按位或）
  logic [127:0] out_vd;
  assign out_vd = ((outIsVwsllEewVdIs64 | ~outIsVwsll) ? {alu_vd[1], alu_vd[0]} : 128'h0)
                | (outIsVwsllEewVdIs32 ? {alu_vd[1][63:32], alu_vd[0][63:32], alu_vd[1][31:0], alu_vd[0][31:0]} : 128'h0)
                | (outIsVwsllEewVdIs16 ? {alu_vd[1][63:48], alu_vd[0][63:48], alu_vd[1][47:32], alu_vd[0][47:32],
                                          alu_vd[1][31:16], alu_vd[0][31:16], alu_vd[1][15:0],  alu_vd[0][15:0]} : 128'h0);

  // 比较结果：按 vs1 宽度把两 lane 的比较位拼成本 uop 的 16 位（元素少时高位为 0）
  logic [15:0] out_cmp;
  assign out_cmp = (outEewVs1_oneHot[0] ? {alu_cmp[1],      alu_cmp[0]}      : 16'h0)
                 | (outEewVs1_oneHot[1] ? {8'h0,  alu_cmp[1][3:0], alu_cmp[0][3:0]} : 16'h0)
                 | (outEewVs1_oneHot[2] ? {12'h0, alu_cmp[1][1:0], alu_cmp[0][1:0]} : 16'h0)
                 | (outEewVs1_oneHot[3] ? {14'h0, alu_cmp[1][0],   alu_cmp[0][0]}   : 16'h0);

  // 本 uop 之前已经算过的元素数 = vdIdx × 每个 uop 的元素数（16 / 8 / 4 / 2，按 vs1 宽度独热按位或）
  logic [4:0]  elems_in_uop;
  logic [7:0]  elements_computed;
  logic [15:0] cmp_with_tail;
  assign elems_in_uop      = {outEewVs1_oneHot[0], outEewVs1_oneHot[1], outEewVs1_oneHot[2], outEewVs1_oneHot[3], 1'b0};
  assign elements_computed = 8'(s1_vuopIdx[2:0] * elems_in_uop);
  for (genvar i = 0; i < 16; i++) begin : g_cmp_tail
    // vl 之外的比较位一律写 1（尾部按 agnostic 处理）
    assign cmp_with_tail[i] = ({1'b0, elements_computed} + 9'(i) >= {1'b0, s1_vl}) | out_cmp[i];
  end

  logic         narrow_need_cat, vstart_ge_vl, out_widen;
  logic [127:0] mgu_in_vd, mgu_mask, mgu_out_vd, mgtu_out_vd;
  logic [15:0]  mgu_active, vxsat_bits, vxsat_real;
  logic [1:0]   out_eew;
  assign narrow_need_cat = s1_vuopIdx[0] & s1_isNarrow;                 // 变窄的第 2 个 uop：结果放高半
  assign vstart_ge_vl    = s1_vstart >= s1_vl;
  assign out_widen       = (s1_fuOpType[8:7] == 2'd1 || s1_fuOpType[8:7] == 2'd2) & ~s1_isExt & ~s1_isDstMask;  // FMT.VVW / WVW
  assign out_eew         = out_widen ? 2'(s1_vsew + 2'd1) : s1_vsew;
  assign mgu_mask        = (need_no_mask(s1_fuOpType) | s1_vm) ? '1 : s1_v0;

  always_comb begin
    if (s1_isNarrow)
      mgu_in_vd = narrow_need_cat ? {alu_narrow_vd[1], alu_narrow_vd[0], s1_oldVd[63:0]}
                                  : {s1_oldVd[127:64], alu_narrow_vd[1], alu_narrow_vd[0]};
    else if (s1_isDstMask)
      mgu_in_vd = {112'h0, cmp_with_tail};
    else
      mgu_in_vd = out_vd;
  end

  Mgu mgu (
    .io_in_vd           (mgu_in_vd),
    .io_in_oldVd        (s1_oldVd),
    .io_in_mask         (mgu_mask),
    .io_in_info_ta      (s1_vta),
    .io_in_info_ma      (s1_vma),
    .io_in_info_vl      ((s1_fuOpType[5:0] == OPC_VMV_S_X) ? 8'd1 : s1_vl),
    .io_in_info_vstart  (s1_vstart),
    .io_in_info_eew     (out_eew),
    .io_in_info_vdIdx   (s1_vuopIdx[2:0]),
    .io_in_info_narrow  (s1_isNarrow),
    .io_in_info_dstMask (s1_isDstMask),
    .io_out_vd          (mgu_out_vd),
    .io_out_active      (mgu_active)
  );
  Mgtu mgtu (
    .io_in_vd  ((s1_isDstMask & ~s1_isOpMask) ? mgu_out_vd : out_vd),
    .io_in_vl  (s1_vl),
    .io_out_vd (mgtu_out_vd)
  );

  // vxsat：每元素饱和位（变窄时每 lane 只有低 4 个），只计 Mgu 判为 active 的字节
  assign vxsat_bits = s1_isNarrow ? {8'h0, alu_vxsat[1][3:0], alu_vxsat[0][3:0]} : {alu_vxsat[1], alu_vxsat[0]};
  assign vxsat_real = narrow_need_cat ? {vxsat_bits[7:0], 8'h0} : vxsat_bits;

  assign out_res_data  = vstart_ge_vl ? s1_oldVd : (s1_isDstMask ? mgtu_out_vd : mgu_out_vd);
  assign out_res_vxsat = ~vstart_ge_vl & (|(vxsat_real & mgu_active));

  assign out_valid        = s1_valid & validVecThisFu_1;
  assign out_robIdx_flag  = s1_robIdx_flag;
  assign out_robIdx_value = s1_robIdx_value;
  assign out_pdest        = s1_pdest;
  assign out_vecWen       = s1_vecWen;
  assign out_v0Wen        = s1_v0Wen;
  assign out_perf         = perf_s1;
  assign out_seq          = seq_s1;
endmodule

// -----------------------------------------------------------------------------
// VIAluFix —— golden 同名 wrapper：端口逐位同名，打包结构体后例化核
// -----------------------------------------------------------------------------
module VIAluFix
  import viafix_pkg::*;
(
  input  logic           clock,
  input  logic           reset,
  output logic           io_in_ready,
  input  logic           io_in_valid,
  input  logic [8:0]     io_in_bits_ctrl_fuOpType,
  input  logic           io_in_bits_ctrl_vpu_vma,
  input  logic [1:0]     io_in_bits_ctrl_vpu_vsew,
  input  logic           io_in_bits_ctrl_vpu_vm,
  input  logic [6:0]     io_in_bits_ctrl_vpu_vuopIdx,
  input  logic           io_in_bits_ctrl_vpu_isExt,
  input  logic           io_in_bits_ctrl_vpu_isNarrow,
  input  logic           io_in_bits_ctrl_vpu_isDstMask,
  input  logic [8:0]     io_in_bits_ctrlPipe_1_fuOpType,
  input  logic           io_in_bits_ctrlPipe_1_robIdx_flag,
  input  logic [7:0]     io_in_bits_ctrlPipe_1_robIdx_value,
  input  logic [7:0]     io_in_bits_ctrlPipe_1_pdest,
  input  logic           io_in_bits_ctrlPipe_1_vecWen,
  input  logic           io_in_bits_ctrlPipe_1_v0Wen,
  input  logic           io_in_bits_ctrlPipe_1_vpu_vma,
  input  logic           io_in_bits_ctrlPipe_1_vpu_vta,
  input  logic [1:0]     io_in_bits_ctrlPipe_1_vpu_vsew,
  input  logic           io_in_bits_ctrlPipe_1_vpu_vm,
  input  logic [7:0]     io_in_bits_ctrlPipe_1_vpu_vstart,
  input  logic [6:0]     io_in_bits_ctrlPipe_1_vpu_vuopIdx,
  input  logic           io_in_bits_ctrlPipe_1_vpu_isExt,
  input  logic           io_in_bits_ctrlPipe_1_vpu_isNarrow,
  input  logic           io_in_bits_ctrlPipe_1_vpu_isDstMask,
  input  logic           io_in_bits_ctrlPipe_1_vpu_isOpMask,
  input  logic           io_in_bits_validPipe_0,
  input  logic           io_in_bits_validPipe_1,
  input  logic [127:0]   io_in_bits_data_src_3,
  input  logic [127:0]   io_in_bits_data_src_2,
  input  logic [127:0]   io_in_bits_data_src_1,
  input  logic [127:0]   io_in_bits_data_src_0,
  input  logic [7:0]     io_in_bits_dataPipe_1_src_4,
  input  logic [127:0]   io_in_bits_dataPipe_1_src_3,
  input  logic [127:0]   io_in_bits_dataPipe_1_src_2,
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
  output logic [127:0]   io_out_bits_res_data,
  output logic           io_out_bits_res_vxsat,
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
  input  logic [1:0]     io_vxrm
);
  perf_dbg_t in_perf, out_perf;
  seq_num_t  in_seq, out_seq;
  assign in_perf = '{
    eliminatedMove:         io_in_bits_perfDebugInfo_eliminatedMove,
    renameTime:             io_in_bits_perfDebugInfo_renameTime,
    dispatchTime:           io_in_bits_perfDebugInfo_dispatchTime,
    enqRsTime:              io_in_bits_perfDebugInfo_enqRsTime,
    selectTime:             io_in_bits_perfDebugInfo_selectTime,
    issueTime:              io_in_bits_perfDebugInfo_issueTime,
    writebackTime:          io_in_bits_perfDebugInfo_writebackTime,
    runahead_checkpoint_id: io_in_bits_perfDebugInfo_runahead_checkpoint_id,
    tlbFirstReqTime:        io_in_bits_perfDebugInfo_tlbFirstReqTime,
    tlbRespTime:            io_in_bits_perfDebugInfo_tlbRespTime
  };
  assign in_seq = '{seqNum: io_in_bits_debug_seqNum_seqNum, uopIdx: io_in_bits_debug_seqNum_uopIdx};

  xs_VIAluFix_core u_core (
    .clock            (clock),
    .reset            (reset),
    .in_ready         (io_in_ready),
    .in_valid         (io_in_valid),
    .in_fuOpType      (io_in_bits_ctrl_fuOpType),
    .in_vma           (io_in_bits_ctrl_vpu_vma),
    .in_vsew          (io_in_bits_ctrl_vpu_vsew),
    .in_vm            (io_in_bits_ctrl_vpu_vm),
    .in_vuopIdx       (io_in_bits_ctrl_vpu_vuopIdx),
    .in_isExt         (io_in_bits_ctrl_vpu_isExt),
    .in_isNarrow      (io_in_bits_ctrl_vpu_isNarrow),
    .in_isDstMask     (io_in_bits_ctrl_vpu_isDstMask),
    .in_validPipe0    (io_in_bits_validPipe_0),
    .in_v0            (io_in_bits_data_src_3),
    .in_oldVd         (io_in_bits_data_src_2),
    .in_vs2           (io_in_bits_data_src_1),
    .in_vs1           (io_in_bits_data_src_0),
    .in_perf          (in_perf),
    .in_seq           (in_seq),
    .vxrm             (io_vxrm),
    .s1_fuOpType      (io_in_bits_ctrlPipe_1_fuOpType),
    .s1_robIdx_flag   (io_in_bits_ctrlPipe_1_robIdx_flag),
    .s1_robIdx_value  (io_in_bits_ctrlPipe_1_robIdx_value),
    .s1_pdest         (io_in_bits_ctrlPipe_1_pdest),
    .s1_vecWen        (io_in_bits_ctrlPipe_1_vecWen),
    .s1_v0Wen         (io_in_bits_ctrlPipe_1_v0Wen),
    .s1_vma           (io_in_bits_ctrlPipe_1_vpu_vma),
    .s1_vta           (io_in_bits_ctrlPipe_1_vpu_vta),
    .s1_vsew          (io_in_bits_ctrlPipe_1_vpu_vsew),
    .s1_vm            (io_in_bits_ctrlPipe_1_vpu_vm),
    .s1_vstart        (io_in_bits_ctrlPipe_1_vpu_vstart),
    .s1_vuopIdx       (io_in_bits_ctrlPipe_1_vpu_vuopIdx),
    .s1_isExt         (io_in_bits_ctrlPipe_1_vpu_isExt),
    .s1_isNarrow      (io_in_bits_ctrlPipe_1_vpu_isNarrow),
    .s1_isDstMask     (io_in_bits_ctrlPipe_1_vpu_isDstMask),
    .s1_isOpMask      (io_in_bits_ctrlPipe_1_vpu_isOpMask),
    .s1_valid         (io_in_bits_validPipe_1),
    .s1_vl            (io_in_bits_dataPipe_1_src_4),
    .s1_v0            (io_in_bits_dataPipe_1_src_3),
    .s1_oldVd         (io_in_bits_dataPipe_1_src_2),
    .out_ready        (io_out_ready),
    .out_valid        (io_out_valid),
    .out_robIdx_flag  (io_out_bits_ctrl_robIdx_flag),
    .out_robIdx_value (io_out_bits_ctrl_robIdx_value),
    .out_pdest        (io_out_bits_ctrl_pdest),
    .out_vecWen       (io_out_bits_ctrl_vecWen),
    .out_v0Wen        (io_out_bits_ctrl_v0Wen),
    .out_res_data     (io_out_bits_res_data),
    .out_res_vxsat    (io_out_bits_res_vxsat),
    .out_perf         (out_perf),
    .out_seq          (out_seq)
  );

  assign io_out_bits_perfDebugInfo_eliminatedMove         = out_perf.eliminatedMove;
  assign io_out_bits_perfDebugInfo_renameTime             = out_perf.renameTime;
  assign io_out_bits_perfDebugInfo_dispatchTime           = out_perf.dispatchTime;
  assign io_out_bits_perfDebugInfo_enqRsTime              = out_perf.enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime             = out_perf.selectTime;
  assign io_out_bits_perfDebugInfo_issueTime              = out_perf.issueTime;
  assign io_out_bits_perfDebugInfo_writebackTime          = out_perf.writebackTime;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = out_perf.runahead_checkpoint_id;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime        = out_perf.tlbFirstReqTime;
  assign io_out_bits_perfDebugInfo_tlbRespTime            = out_perf.tlbRespTime;
  assign io_out_bits_debug_seqNum_seqNum                  = out_seq.seqNum;
  assign io_out_bits_debug_seqNum_uopIdx                  = out_seq.uopIdx;
endmodule
