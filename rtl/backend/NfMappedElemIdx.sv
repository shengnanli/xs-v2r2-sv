// =============================================================================
// NfMappedElemIdx —— 向量分段（segment）load/store 异常时：每个目的寄存器装的是第几号到第几号元素
//
// 在哪一层：后端 VecExcpDataMergeModule（backend/VecExcpDataMergeModule.scala `class NfMappedElemIdx(vlen)`，
//   VLEN = 128）。分段访存 vlseg<nf>e<eew> 出异常要按 vstart 部分合并旧数据，得知道 8 个目的寄存器
//   vd+0..vd+7 各自覆盖的元素下标区间 [from, until)。
// 机制（对着 Scala 读）：
//   · nFields = nf + 1 个字段交错存放，第 vdIdx 个目的寄存器属于第 vrgIdx = vdIdx / nFields 个寄存器组
//     （同一组里的 nFields 个寄存器装的是同一批元素的不同字段，元素下标区间相同）；
//   · 以 8 位元素为基准，一个寄存器 16 个元素：区间 = [16*vrgIdx, 16*(vrgIdx+1))；
//   · 元素更宽时每个寄存器的元素数按 EEW 减半：eewOH 第 i 位（e8/e16/e32/e64）对应把两端都右移 i 位；
//   · eewOH 用 Mux1H 选——不是 one-hot 时各路按位或（照 Scala 的 Mux1H 语义，不当非法输入处理）。
//   · 寄存器 0 的组号恒 0，所以 out_idxRangeVec_0_from 恒 0。
//   idxWidth = log2Up(128+1) = 8 位，最大值 until = 128 正好放得下。
// 无状态、无时钟。golden 对照：G1-canonical/golden-rtl/NfMappedElemIdx.sv（177 行）
// =============================================================================
module NfMappedElemIdx (
  input  logic [2:0] in_nf,
  input  logic [3:0] in_eewOH,
  output logic [7:0] out_idxRangeVec_0_from,
  output logic [7:0] out_idxRangeVec_0_until,
  output logic [7:0] out_idxRangeVec_1_from,
  output logic [7:0] out_idxRangeVec_1_until,
  output logic [7:0] out_idxRangeVec_2_from,
  output logic [7:0] out_idxRangeVec_2_until,
  output logic [7:0] out_idxRangeVec_3_from,
  output logic [7:0] out_idxRangeVec_3_until,
  output logic [7:0] out_idxRangeVec_4_from,
  output logic [7:0] out_idxRangeVec_4_until,
  output logic [7:0] out_idxRangeVec_5_from,
  output logic [7:0] out_idxRangeVec_5_until,
  output logic [7:0] out_idxRangeVec_6_from,
  output logic [7:0] out_idxRangeVec_6_until,
  output logic [7:0] out_idxRangeVec_7_from,
  output logic [7:0] out_idxRangeVec_7_until
);

  localparam int unsigned MAX_ELEM_PER_VREG = 128 / 8;   // vlen / 最小元素宽 = 16

  // 按 eewOH 缩放一个"8 位元素口径"的下标：Mux1H(eewOH(i) -> x >> i)，非 one-hot 时按位或
  function automatic logic [7:0] scale_by_eew(input logic [3:0] eew_oh, input int unsigned idx_e8);
    logic [7:0] result;
    result = '0;
    for (int i = 0; i < 4; i++)
      if (eew_oh[i])
        result |= 8'(idx_e8 >> i);
    return result;
  endfunction

  // ---- 每个目的寄存器的区间：先由 nf 求寄存器组号，再换算成元素下标 ----
  logic [7:0] range_from  [8];
  logic [7:0] range_until [8];

  always_comb begin
    for (int vd = 0; vd < 8; vd++) begin
      int unsigned vrg_idx;
      // vrg_idx = vd / (nf + 1)；nf 只有 8 种取值，逐个比对，除法都是常量除法
      vrg_idx = 0;
      for (int nf = 0; nf < 8; nf++)
        if (in_nf == 3'(nf))
          vrg_idx = vd / (nf + 1);
      range_from[vd]  = scale_by_eew(in_eewOH, MAX_ELEM_PER_VREG * vrg_idx);
      range_until[vd] = scale_by_eew(in_eewOH, MAX_ELEM_PER_VREG * (vrg_idx + 1));
    end
  end

  // ---- 端口展平 ----
  assign out_idxRangeVec_0_from  = range_from[0];
  assign out_idxRangeVec_0_until = range_until[0];
  assign out_idxRangeVec_1_from  = range_from[1];
  assign out_idxRangeVec_1_until = range_until[1];
  assign out_idxRangeVec_2_from  = range_from[2];
  assign out_idxRangeVec_2_until = range_until[2];
  assign out_idxRangeVec_3_from  = range_from[3];
  assign out_idxRangeVec_3_until = range_until[3];
  assign out_idxRangeVec_4_from  = range_from[4];
  assign out_idxRangeVec_4_until = range_until[4];
  assign out_idxRangeVec_5_from  = range_from[5];
  assign out_idxRangeVec_5_until = range_until[5];
  assign out_idxRangeVec_6_from  = range_from[6];
  assign out_idxRangeVec_6_until = range_until[6];
  assign out_idxRangeVec_7_from  = range_from[7];
  assign out_idxRangeVec_7_until = range_until[7];
endmodule
