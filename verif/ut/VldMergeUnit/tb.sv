// ============================================================================
// tb —— 向量 load 合并链 UT：UIntToContLow1s / UIntToContLow0s / ByteMaskTailGen /
//        VldMgu / VldMergeUnit 五对 golden vs 重写件，同激励逐拍比全部输出。
//
// 激励有偏：vstart 0..40、vl 0..140（字节号经 <<vsew 后能跨 128 字节整组边界，
// 也能落进 vstart>=vl 的空区间）；vm / vlWen / isIndexed / isMasked 各约 1/4 置位；
// 冲刷口 robIdx 与写回 robIdx 同 flag 且 value 相差 0..3 的概率约 1/2（覆盖「之后 /
// 相等 / 之前」三种比较与翻转位）。VldMergeUnit 无复位：两侧先灌 4 拍 valid 再比。
//
// 本文件由 scripts/gen_vldmergeunit.py 生成，勿手改。
// ============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0; always #5 clock = ~clock;
  longint errors = 0, checks = 0;
  `define CK(g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors < 20) $display("MISMATCH %0t %s golden=%h impl=%h", $time, nm, (g), (i)); \
    end end

  // ---- 共用随机源 ----
  logic [7:0]   u8a, u8b;
  logic [127:0] r128a, r128b, r128c;
  logic [1:0]   r2a, r2b;
  logic [2:0]   r3;
  logic [15:0]  r16;
  logic [7:0]   vstart, vl;
  logic         vma, vta, vm, vlwen, idx, msk;
  logic         wb_valid, fl_valid, fl_level, fl_flag, wb_flag;
  logic [7:0]   fl_value, wb_value;
  logic [1023:0] noise;   // 其余字段的随机位

  logic [254:0] g1_io_dataOut, i1_io_dataOut;
  logic [254:0] g0_io_dataOut, i0_io_dataOut;
  logic [15:0] gB_io_out_activeEn, iB_io_out_activeEn;
  logic [15:0] gB_io_out_agnosticEn, iB_io_out_agnosticEn;
  logic [127:0] gG_io_out_vd, iG_io_out_vd;
  logic [0:0] gM_io_writebackAfterMerge_valid, iM_io_writebackAfterMerge_valid;
  logic [127:0] gM_io_writebackAfterMerge_bits_data_0, iM_io_writebackAfterMerge_bits_data_0;
  logic [6:0] gM_io_writebackAfterMerge_bits_pdest, iM_io_writebackAfterMerge_bits_pdest;
  logic [0:0] gM_io_writebackAfterMerge_bits_robIdx_flag, iM_io_writebackAfterMerge_bits_robIdx_flag;
  logic [7:0] gM_io_writebackAfterMerge_bits_robIdx_value, iM_io_writebackAfterMerge_bits_robIdx_value;
  logic [0:0] gM_io_writebackAfterMerge_bits_vecWen, iM_io_writebackAfterMerge_bits_vecWen;
  logic [0:0] gM_io_writebackAfterMerge_bits_v0Wen, iM_io_writebackAfterMerge_bits_v0Wen;
  logic [0:0] gM_io_writebackAfterMerge_bits_vlWen, iM_io_writebackAfterMerge_bits_vlWen;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_0, iM_io_writebackAfterMerge_bits_exceptionVec_0;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_1, iM_io_writebackAfterMerge_bits_exceptionVec_1;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_2, iM_io_writebackAfterMerge_bits_exceptionVec_2;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_3, iM_io_writebackAfterMerge_bits_exceptionVec_3;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_4, iM_io_writebackAfterMerge_bits_exceptionVec_4;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_5, iM_io_writebackAfterMerge_bits_exceptionVec_5;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_6, iM_io_writebackAfterMerge_bits_exceptionVec_6;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_7, iM_io_writebackAfterMerge_bits_exceptionVec_7;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_8, iM_io_writebackAfterMerge_bits_exceptionVec_8;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_9, iM_io_writebackAfterMerge_bits_exceptionVec_9;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_10, iM_io_writebackAfterMerge_bits_exceptionVec_10;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_11, iM_io_writebackAfterMerge_bits_exceptionVec_11;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_12, iM_io_writebackAfterMerge_bits_exceptionVec_12;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_13, iM_io_writebackAfterMerge_bits_exceptionVec_13;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_14, iM_io_writebackAfterMerge_bits_exceptionVec_14;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_15, iM_io_writebackAfterMerge_bits_exceptionVec_15;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_16, iM_io_writebackAfterMerge_bits_exceptionVec_16;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_17, iM_io_writebackAfterMerge_bits_exceptionVec_17;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_18, iM_io_writebackAfterMerge_bits_exceptionVec_18;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_19, iM_io_writebackAfterMerge_bits_exceptionVec_19;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_20, iM_io_writebackAfterMerge_bits_exceptionVec_20;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_21, iM_io_writebackAfterMerge_bits_exceptionVec_21;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_22, iM_io_writebackAfterMerge_bits_exceptionVec_22;
  logic [0:0] gM_io_writebackAfterMerge_bits_exceptionVec_23, iM_io_writebackAfterMerge_bits_exceptionVec_23;
  logic [0:0] gM_io_writebackAfterMerge_bits_flushPipe, iM_io_writebackAfterMerge_bits_flushPipe;
  logic [0:0] gM_io_writebackAfterMerge_bits_replay, iM_io_writebackAfterMerge_bits_replay;
  logic [3:0] gM_io_writebackAfterMerge_bits_trigger, iM_io_writebackAfterMerge_bits_trigger;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_vill, iM_io_writebackAfterMerge_bits_vls_vpu_vill;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_vma, iM_io_writebackAfterMerge_bits_vls_vpu_vma;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_vta, iM_io_writebackAfterMerge_bits_vls_vpu_vta;
  logic [1:0] gM_io_writebackAfterMerge_bits_vls_vpu_vsew, iM_io_writebackAfterMerge_bits_vls_vpu_vsew;
  logic [2:0] gM_io_writebackAfterMerge_bits_vls_vpu_vlmul, iM_io_writebackAfterMerge_bits_vls_vpu_vlmul;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_specVill, iM_io_writebackAfterMerge_bits_vls_vpu_specVill;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_specVma, iM_io_writebackAfterMerge_bits_vls_vpu_specVma;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_specVta, iM_io_writebackAfterMerge_bits_vls_vpu_specVta;
  logic [1:0] gM_io_writebackAfterMerge_bits_vls_vpu_specVsew, iM_io_writebackAfterMerge_bits_vls_vpu_specVsew;
  logic [2:0] gM_io_writebackAfterMerge_bits_vls_vpu_specVlmul, iM_io_writebackAfterMerge_bits_vls_vpu_specVlmul;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_vm, iM_io_writebackAfterMerge_bits_vls_vpu_vm;
  logic [7:0] gM_io_writebackAfterMerge_bits_vls_vpu_vstart, iM_io_writebackAfterMerge_bits_vls_vpu_vstart;
  logic [2:0] gM_io_writebackAfterMerge_bits_vls_vpu_frm, iM_io_writebackAfterMerge_bits_vls_vpu_frm;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFpToVecInst, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFpToVecInst;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFP32Instr, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFP32Instr;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFP64Instr, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFP64Instr;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isReduction, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isReduction;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_2, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_2;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_4, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_4;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_8, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_8;
  logic [1:0] gM_io_writebackAfterMerge_bits_vls_vpu_vxrm, iM_io_writebackAfterMerge_bits_vls_vpu_vxrm;
  logic [6:0] gM_io_writebackAfterMerge_bits_vls_vpu_vuopIdx, iM_io_writebackAfterMerge_bits_vls_vpu_vuopIdx;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_lastUop, iM_io_writebackAfterMerge_bits_vls_vpu_lastUop;
  logic [127:0] gM_io_writebackAfterMerge_bits_vls_vpu_vmask, iM_io_writebackAfterMerge_bits_vls_vpu_vmask;
  logic [7:0] gM_io_writebackAfterMerge_bits_vls_vpu_vl, iM_io_writebackAfterMerge_bits_vls_vpu_vl;
  logic [2:0] gM_io_writebackAfterMerge_bits_vls_vpu_nf, iM_io_writebackAfterMerge_bits_vls_vpu_nf;
  logic [1:0] gM_io_writebackAfterMerge_bits_vls_vpu_veew, iM_io_writebackAfterMerge_bits_vls_vpu_veew;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_isReverse, iM_io_writebackAfterMerge_bits_vls_vpu_isReverse;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_isExt, iM_io_writebackAfterMerge_bits_vls_vpu_isExt;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_isNarrow, iM_io_writebackAfterMerge_bits_vls_vpu_isNarrow;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_isDstMask, iM_io_writebackAfterMerge_bits_vls_vpu_isDstMask;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_isOpMask, iM_io_writebackAfterMerge_bits_vls_vpu_isOpMask;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_isMove, iM_io_writebackAfterMerge_bits_vls_vpu_isMove;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_isDependOldVd, iM_io_writebackAfterMerge_bits_vls_vpu_isDependOldVd;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_isWritePartVd, iM_io_writebackAfterMerge_bits_vls_vpu_isWritePartVd;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_vpu_isVleff, iM_io_writebackAfterMerge_bits_vls_vpu_isVleff;
  logic [7:0] gM_io_writebackAfterMerge_bits_vls_oldVdPsrc, iM_io_writebackAfterMerge_bits_vls_oldVdPsrc;
  logic [2:0] gM_io_writebackAfterMerge_bits_vls_vdIdx, iM_io_writebackAfterMerge_bits_vls_vdIdx;
  logic [2:0] gM_io_writebackAfterMerge_bits_vls_vdIdxInField, iM_io_writebackAfterMerge_bits_vls_vdIdxInField;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_isIndexed, iM_io_writebackAfterMerge_bits_vls_isIndexed;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_isMasked, iM_io_writebackAfterMerge_bits_vls_isMasked;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_isStrided, iM_io_writebackAfterMerge_bits_vls_isStrided;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_isWhole, iM_io_writebackAfterMerge_bits_vls_isWhole;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_isVecLoad, iM_io_writebackAfterMerge_bits_vls_isVecLoad;
  logic [0:0] gM_io_writebackAfterMerge_bits_vls_isVlm, iM_io_writebackAfterMerge_bits_vls_isVlm;
  logic [0:0] gM_io_writebackAfterMerge_bits_debug_isMMIO, iM_io_writebackAfterMerge_bits_debug_isMMIO;
  logic [0:0] gM_io_writebackAfterMerge_bits_debug_isNCIO, iM_io_writebackAfterMerge_bits_debug_isNCIO;
  logic [0:0] gM_io_writebackAfterMerge_bits_debug_isPerfCnt, iM_io_writebackAfterMerge_bits_debug_isPerfCnt;
  logic [47:0] gM_io_writebackAfterMerge_bits_debug_paddr, iM_io_writebackAfterMerge_bits_debug_paddr;
  logic [49:0] gM_io_writebackAfterMerge_bits_debug_vaddr, iM_io_writebackAfterMerge_bits_debug_vaddr;
  logic [0:0] gM_io_writebackAfterMerge_bits_debugInfo_eliminatedMove, iM_io_writebackAfterMerge_bits_debugInfo_eliminatedMove;
  logic [63:0] gM_io_writebackAfterMerge_bits_debugInfo_renameTime, iM_io_writebackAfterMerge_bits_debugInfo_renameTime;
  logic [63:0] gM_io_writebackAfterMerge_bits_debugInfo_dispatchTime, iM_io_writebackAfterMerge_bits_debugInfo_dispatchTime;
  logic [63:0] gM_io_writebackAfterMerge_bits_debugInfo_enqRsTime, iM_io_writebackAfterMerge_bits_debugInfo_enqRsTime;
  logic [63:0] gM_io_writebackAfterMerge_bits_debugInfo_selectTime, iM_io_writebackAfterMerge_bits_debugInfo_selectTime;
  logic [63:0] gM_io_writebackAfterMerge_bits_debugInfo_issueTime, iM_io_writebackAfterMerge_bits_debugInfo_issueTime;
  logic [63:0] gM_io_writebackAfterMerge_bits_debugInfo_writebackTime, iM_io_writebackAfterMerge_bits_debugInfo_writebackTime;
  logic [63:0] gM_io_writebackAfterMerge_bits_debugInfo_runahead_checkpoint_id, iM_io_writebackAfterMerge_bits_debugInfo_runahead_checkpoint_id;
  logic [63:0] gM_io_writebackAfterMerge_bits_debugInfo_tlbFirstReqTime, iM_io_writebackAfterMerge_bits_debugInfo_tlbFirstReqTime;
  logic [63:0] gM_io_writebackAfterMerge_bits_debugInfo_tlbRespTime, iM_io_writebackAfterMerge_bits_debugInfo_tlbRespTime;
  logic [55:0] gM_io_writebackAfterMerge_bits_debug_seqNum_seqNum, iM_io_writebackAfterMerge_bits_debug_seqNum_seqNum;
  logic [7:0] gM_io_writebackAfterMerge_bits_debug_seqNum_uopIdx, iM_io_writebackAfterMerge_bits_debug_seqNum_uopIdx;

  UIntToContLow1s u_g1 (
    .io_dataIn (u8a),
    .io_dataOut (g1_io_dataOut)
  );
  UIntToContLow1s_xs u_i1 (
    .io_dataIn (u8a),
    .io_dataOut (i1_io_dataOut)
  );
  UIntToContLow0s u_g0 (
    .io_dataIn (u8b),
    .io_dataOut (g0_io_dataOut)
  );
  UIntToContLow0s_xs u_i0 (
    .io_dataIn (u8b),
    .io_dataOut (i0_io_dataOut)
  );
  ByteMaskTailGen u_gB (
    .io_in_begin (vstart),
    .io_in_end (vl),
    .io_in_vma (vma),
    .io_in_vta (vta),
    .io_in_vsew (r2a),
    .io_in_maskUsed (r16),
    .io_in_vdIdx (r3),
    .io_out_activeEn (gB_io_out_activeEn),
    .io_out_agnosticEn (gB_io_out_agnosticEn)
  );
  ByteMaskTailGen_xs u_iB (
    .io_in_begin (vstart),
    .io_in_end (vl),
    .io_in_vma (vma),
    .io_in_vta (vta),
    .io_in_vsew (r2a),
    .io_in_maskUsed (r16),
    .io_in_vdIdx (r3),
    .io_out_activeEn (iB_io_out_activeEn),
    .io_out_agnosticEn (iB_io_out_agnosticEn)
  );
  VldMgu u_gG (
    .io_in_vd (r128a),
    .io_in_oldVd (r128b),
    .io_in_mask (r128c),
    .io_in_info_ta (vta),
    .io_in_info_ma (vma),
    .io_in_info_vl (vl),
    .io_in_info_vstart (vstart),
    .io_in_info_eew (r2a),
    .io_in_info_vsew (r2b),
    .io_in_info_vdIdx (r3),
    .io_in_isIndexedVls (idx),
    .io_out_vd (gG_io_out_vd)
  );
  VldMgu_xs u_iG (
    .io_in_vd (r128a),
    .io_in_oldVd (r128b),
    .io_in_mask (r128c),
    .io_in_info_ta (vta),
    .io_in_info_ma (vma),
    .io_in_info_vl (vl),
    .io_in_info_vstart (vstart),
    .io_in_info_eew (r2a),
    .io_in_info_vsew (r2b),
    .io_in_info_vdIdx (r3),
    .io_in_isIndexedVls (idx),
    .io_out_vd (iG_io_out_vd)
  );
  VldMergeUnit u_gM (
    .clock (clock),
    .io_flush_valid (fl_valid),
    .io_flush_bits_robIdx_flag (fl_flag),
    .io_flush_bits_robIdx_value (fl_value),
    .io_flush_bits_level (fl_level),
    .io_writeback_valid (wb_valid),
    .io_writeback_bits_data_0 (r128a),
    .io_writeback_bits_pdest (noise[0 +: 7]),
    .io_writeback_bits_robIdx_flag (wb_flag),
    .io_writeback_bits_robIdx_value (wb_value),
    .io_writeback_bits_vecWen (noise[7 +: 1]),
    .io_writeback_bits_v0Wen (noise[8 +: 1]),
    .io_writeback_bits_vlWen (vlwen),
    .io_writeback_bits_exceptionVec_0 (noise[9 +: 1]),
    .io_writeback_bits_exceptionVec_1 (noise[10 +: 1]),
    .io_writeback_bits_exceptionVec_2 (noise[11 +: 1]),
    .io_writeback_bits_exceptionVec_3 (noise[12 +: 1]),
    .io_writeback_bits_exceptionVec_4 (noise[13 +: 1]),
    .io_writeback_bits_exceptionVec_5 (noise[14 +: 1]),
    .io_writeback_bits_exceptionVec_6 (noise[15 +: 1]),
    .io_writeback_bits_exceptionVec_7 (noise[16 +: 1]),
    .io_writeback_bits_exceptionVec_8 (noise[17 +: 1]),
    .io_writeback_bits_exceptionVec_9 (noise[18 +: 1]),
    .io_writeback_bits_exceptionVec_10 (noise[19 +: 1]),
    .io_writeback_bits_exceptionVec_11 (noise[20 +: 1]),
    .io_writeback_bits_exceptionVec_12 (noise[21 +: 1]),
    .io_writeback_bits_exceptionVec_13 (noise[22 +: 1]),
    .io_writeback_bits_exceptionVec_14 (noise[23 +: 1]),
    .io_writeback_bits_exceptionVec_15 (noise[24 +: 1]),
    .io_writeback_bits_exceptionVec_16 (noise[25 +: 1]),
    .io_writeback_bits_exceptionVec_17 (noise[26 +: 1]),
    .io_writeback_bits_exceptionVec_18 (noise[27 +: 1]),
    .io_writeback_bits_exceptionVec_19 (noise[28 +: 1]),
    .io_writeback_bits_exceptionVec_20 (noise[29 +: 1]),
    .io_writeback_bits_exceptionVec_21 (noise[30 +: 1]),
    .io_writeback_bits_exceptionVec_22 (noise[31 +: 1]),
    .io_writeback_bits_exceptionVec_23 (noise[32 +: 1]),
    .io_writeback_bits_flushPipe (noise[33 +: 1]),
    .io_writeback_bits_replay (noise[34 +: 1]),
    .io_writeback_bits_trigger (noise[35 +: 4]),
    .io_writeback_bits_vls_vpu_vill (noise[39 +: 1]),
    .io_writeback_bits_vls_vpu_vma (vma),
    .io_writeback_bits_vls_vpu_vta (vta),
    .io_writeback_bits_vls_vpu_vsew (r2b),
    .io_writeback_bits_vls_vpu_vlmul (noise[40 +: 3]),
    .io_writeback_bits_vls_vpu_specVill (noise[43 +: 1]),
    .io_writeback_bits_vls_vpu_specVma (noise[44 +: 1]),
    .io_writeback_bits_vls_vpu_specVta (noise[45 +: 1]),
    .io_writeback_bits_vls_vpu_specVsew (noise[46 +: 2]),
    .io_writeback_bits_vls_vpu_specVlmul (noise[48 +: 3]),
    .io_writeback_bits_vls_vpu_vm (vm),
    .io_writeback_bits_vls_vpu_vstart (vstart),
    .io_writeback_bits_vls_vpu_frm (noise[51 +: 3]),
    .io_writeback_bits_vls_vpu_fpu_isFpToVecInst (noise[54 +: 1]),
    .io_writeback_bits_vls_vpu_fpu_isFP32Instr (noise[55 +: 1]),
    .io_writeback_bits_vls_vpu_fpu_isFP64Instr (noise[56 +: 1]),
    .io_writeback_bits_vls_vpu_fpu_isReduction (noise[57 +: 1]),
    .io_writeback_bits_vls_vpu_fpu_isFoldTo1_2 (noise[58 +: 1]),
    .io_writeback_bits_vls_vpu_fpu_isFoldTo1_4 (noise[59 +: 1]),
    .io_writeback_bits_vls_vpu_fpu_isFoldTo1_8 (noise[60 +: 1]),
    .io_writeback_bits_vls_vpu_vxrm (noise[61 +: 2]),
    .io_writeback_bits_vls_vpu_vuopIdx (noise[63 +: 7]),
    .io_writeback_bits_vls_vpu_lastUop (noise[70 +: 1]),
    .io_writeback_bits_vls_vpu_vmask (r128c),
    .io_writeback_bits_vls_vpu_vl (vl),
    .io_writeback_bits_vls_vpu_nf (noise[71 +: 3]),
    .io_writeback_bits_vls_vpu_veew (r2a),
    .io_writeback_bits_vls_vpu_isReverse (noise[74 +: 1]),
    .io_writeback_bits_vls_vpu_isExt (noise[75 +: 1]),
    .io_writeback_bits_vls_vpu_isNarrow (noise[76 +: 1]),
    .io_writeback_bits_vls_vpu_isDstMask (noise[77 +: 1]),
    .io_writeback_bits_vls_vpu_isOpMask (noise[78 +: 1]),
    .io_writeback_bits_vls_vpu_isMove (noise[79 +: 1]),
    .io_writeback_bits_vls_vpu_isDependOldVd (noise[80 +: 1]),
    .io_writeback_bits_vls_vpu_isWritePartVd (noise[81 +: 1]),
    .io_writeback_bits_vls_vpu_isVleff (noise[82 +: 1]),
    .io_writeback_bits_vls_oldVdPsrc (noise[83 +: 8]),
    .io_writeback_bits_vls_vdIdx (noise[91 +: 3]),
    .io_writeback_bits_vls_vdIdxInField (r3),
    .io_writeback_bits_vls_isIndexed (idx),
    .io_writeback_bits_vls_isMasked (msk),
    .io_writeback_bits_vls_isStrided (noise[94 +: 1]),
    .io_writeback_bits_vls_isWhole (noise[95 +: 1]),
    .io_writeback_bits_vls_isVecLoad (noise[96 +: 1]),
    .io_writeback_bits_vls_isVlm (noise[97 +: 1]),
    .io_writeback_bits_debug_isMMIO (noise[98 +: 1]),
    .io_writeback_bits_debug_isNCIO (noise[99 +: 1]),
    .io_writeback_bits_debug_isPerfCnt (noise[100 +: 1]),
    .io_writeback_bits_debug_paddr (noise[101 +: 48]),
    .io_writeback_bits_debug_vaddr (noise[149 +: 50]),
    .io_writeback_bits_debugInfo_eliminatedMove (noise[199 +: 1]),
    .io_writeback_bits_debugInfo_renameTime (noise[200 +: 64]),
    .io_writeback_bits_debugInfo_dispatchTime (noise[264 +: 64]),
    .io_writeback_bits_debugInfo_enqRsTime (noise[328 +: 64]),
    .io_writeback_bits_debugInfo_selectTime (noise[392 +: 64]),
    .io_writeback_bits_debugInfo_issueTime (noise[456 +: 64]),
    .io_writeback_bits_debugInfo_writebackTime (noise[520 +: 64]),
    .io_writeback_bits_debugInfo_runahead_checkpoint_id (noise[584 +: 64]),
    .io_writeback_bits_debugInfo_tlbFirstReqTime (noise[648 +: 64]),
    .io_writeback_bits_debugInfo_tlbRespTime (noise[712 +: 64]),
    .io_writeback_bits_debug_seqNum_seqNum (noise[776 +: 56]),
    .io_writeback_bits_debug_seqNum_uopIdx (noise[832 +: 8]),
    .io_writebackAfterMerge_valid (gM_io_writebackAfterMerge_valid),
    .io_writebackAfterMerge_bits_data_0 (gM_io_writebackAfterMerge_bits_data_0),
    .io_writebackAfterMerge_bits_pdest (gM_io_writebackAfterMerge_bits_pdest),
    .io_writebackAfterMerge_bits_robIdx_flag (gM_io_writebackAfterMerge_bits_robIdx_flag),
    .io_writebackAfterMerge_bits_robIdx_value (gM_io_writebackAfterMerge_bits_robIdx_value),
    .io_writebackAfterMerge_bits_vecWen (gM_io_writebackAfterMerge_bits_vecWen),
    .io_writebackAfterMerge_bits_v0Wen (gM_io_writebackAfterMerge_bits_v0Wen),
    .io_writebackAfterMerge_bits_vlWen (gM_io_writebackAfterMerge_bits_vlWen),
    .io_writebackAfterMerge_bits_exceptionVec_0 (gM_io_writebackAfterMerge_bits_exceptionVec_0),
    .io_writebackAfterMerge_bits_exceptionVec_1 (gM_io_writebackAfterMerge_bits_exceptionVec_1),
    .io_writebackAfterMerge_bits_exceptionVec_2 (gM_io_writebackAfterMerge_bits_exceptionVec_2),
    .io_writebackAfterMerge_bits_exceptionVec_3 (gM_io_writebackAfterMerge_bits_exceptionVec_3),
    .io_writebackAfterMerge_bits_exceptionVec_4 (gM_io_writebackAfterMerge_bits_exceptionVec_4),
    .io_writebackAfterMerge_bits_exceptionVec_5 (gM_io_writebackAfterMerge_bits_exceptionVec_5),
    .io_writebackAfterMerge_bits_exceptionVec_6 (gM_io_writebackAfterMerge_bits_exceptionVec_6),
    .io_writebackAfterMerge_bits_exceptionVec_7 (gM_io_writebackAfterMerge_bits_exceptionVec_7),
    .io_writebackAfterMerge_bits_exceptionVec_8 (gM_io_writebackAfterMerge_bits_exceptionVec_8),
    .io_writebackAfterMerge_bits_exceptionVec_9 (gM_io_writebackAfterMerge_bits_exceptionVec_9),
    .io_writebackAfterMerge_bits_exceptionVec_10 (gM_io_writebackAfterMerge_bits_exceptionVec_10),
    .io_writebackAfterMerge_bits_exceptionVec_11 (gM_io_writebackAfterMerge_bits_exceptionVec_11),
    .io_writebackAfterMerge_bits_exceptionVec_12 (gM_io_writebackAfterMerge_bits_exceptionVec_12),
    .io_writebackAfterMerge_bits_exceptionVec_13 (gM_io_writebackAfterMerge_bits_exceptionVec_13),
    .io_writebackAfterMerge_bits_exceptionVec_14 (gM_io_writebackAfterMerge_bits_exceptionVec_14),
    .io_writebackAfterMerge_bits_exceptionVec_15 (gM_io_writebackAfterMerge_bits_exceptionVec_15),
    .io_writebackAfterMerge_bits_exceptionVec_16 (gM_io_writebackAfterMerge_bits_exceptionVec_16),
    .io_writebackAfterMerge_bits_exceptionVec_17 (gM_io_writebackAfterMerge_bits_exceptionVec_17),
    .io_writebackAfterMerge_bits_exceptionVec_18 (gM_io_writebackAfterMerge_bits_exceptionVec_18),
    .io_writebackAfterMerge_bits_exceptionVec_19 (gM_io_writebackAfterMerge_bits_exceptionVec_19),
    .io_writebackAfterMerge_bits_exceptionVec_20 (gM_io_writebackAfterMerge_bits_exceptionVec_20),
    .io_writebackAfterMerge_bits_exceptionVec_21 (gM_io_writebackAfterMerge_bits_exceptionVec_21),
    .io_writebackAfterMerge_bits_exceptionVec_22 (gM_io_writebackAfterMerge_bits_exceptionVec_22),
    .io_writebackAfterMerge_bits_exceptionVec_23 (gM_io_writebackAfterMerge_bits_exceptionVec_23),
    .io_writebackAfterMerge_bits_flushPipe (gM_io_writebackAfterMerge_bits_flushPipe),
    .io_writebackAfterMerge_bits_replay (gM_io_writebackAfterMerge_bits_replay),
    .io_writebackAfterMerge_bits_trigger (gM_io_writebackAfterMerge_bits_trigger),
    .io_writebackAfterMerge_bits_vls_vpu_vill (gM_io_writebackAfterMerge_bits_vls_vpu_vill),
    .io_writebackAfterMerge_bits_vls_vpu_vma (gM_io_writebackAfterMerge_bits_vls_vpu_vma),
    .io_writebackAfterMerge_bits_vls_vpu_vta (gM_io_writebackAfterMerge_bits_vls_vpu_vta),
    .io_writebackAfterMerge_bits_vls_vpu_vsew (gM_io_writebackAfterMerge_bits_vls_vpu_vsew),
    .io_writebackAfterMerge_bits_vls_vpu_vlmul (gM_io_writebackAfterMerge_bits_vls_vpu_vlmul),
    .io_writebackAfterMerge_bits_vls_vpu_specVill (gM_io_writebackAfterMerge_bits_vls_vpu_specVill),
    .io_writebackAfterMerge_bits_vls_vpu_specVma (gM_io_writebackAfterMerge_bits_vls_vpu_specVma),
    .io_writebackAfterMerge_bits_vls_vpu_specVta (gM_io_writebackAfterMerge_bits_vls_vpu_specVta),
    .io_writebackAfterMerge_bits_vls_vpu_specVsew (gM_io_writebackAfterMerge_bits_vls_vpu_specVsew),
    .io_writebackAfterMerge_bits_vls_vpu_specVlmul (gM_io_writebackAfterMerge_bits_vls_vpu_specVlmul),
    .io_writebackAfterMerge_bits_vls_vpu_vm (gM_io_writebackAfterMerge_bits_vls_vpu_vm),
    .io_writebackAfterMerge_bits_vls_vpu_vstart (gM_io_writebackAfterMerge_bits_vls_vpu_vstart),
    .io_writebackAfterMerge_bits_vls_vpu_frm (gM_io_writebackAfterMerge_bits_vls_vpu_frm),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isFpToVecInst (gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFpToVecInst),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isFP32Instr (gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFP32Instr),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isFP64Instr (gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFP64Instr),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isReduction (gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isReduction),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_2 (gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_2),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_4 (gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_4),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_8 (gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_8),
    .io_writebackAfterMerge_bits_vls_vpu_vxrm (gM_io_writebackAfterMerge_bits_vls_vpu_vxrm),
    .io_writebackAfterMerge_bits_vls_vpu_vuopIdx (gM_io_writebackAfterMerge_bits_vls_vpu_vuopIdx),
    .io_writebackAfterMerge_bits_vls_vpu_lastUop (gM_io_writebackAfterMerge_bits_vls_vpu_lastUop),
    .io_writebackAfterMerge_bits_vls_vpu_vmask (gM_io_writebackAfterMerge_bits_vls_vpu_vmask),
    .io_writebackAfterMerge_bits_vls_vpu_vl (gM_io_writebackAfterMerge_bits_vls_vpu_vl),
    .io_writebackAfterMerge_bits_vls_vpu_nf (gM_io_writebackAfterMerge_bits_vls_vpu_nf),
    .io_writebackAfterMerge_bits_vls_vpu_veew (gM_io_writebackAfterMerge_bits_vls_vpu_veew),
    .io_writebackAfterMerge_bits_vls_vpu_isReverse (gM_io_writebackAfterMerge_bits_vls_vpu_isReverse),
    .io_writebackAfterMerge_bits_vls_vpu_isExt (gM_io_writebackAfterMerge_bits_vls_vpu_isExt),
    .io_writebackAfterMerge_bits_vls_vpu_isNarrow (gM_io_writebackAfterMerge_bits_vls_vpu_isNarrow),
    .io_writebackAfterMerge_bits_vls_vpu_isDstMask (gM_io_writebackAfterMerge_bits_vls_vpu_isDstMask),
    .io_writebackAfterMerge_bits_vls_vpu_isOpMask (gM_io_writebackAfterMerge_bits_vls_vpu_isOpMask),
    .io_writebackAfterMerge_bits_vls_vpu_isMove (gM_io_writebackAfterMerge_bits_vls_vpu_isMove),
    .io_writebackAfterMerge_bits_vls_vpu_isDependOldVd (gM_io_writebackAfterMerge_bits_vls_vpu_isDependOldVd),
    .io_writebackAfterMerge_bits_vls_vpu_isWritePartVd (gM_io_writebackAfterMerge_bits_vls_vpu_isWritePartVd),
    .io_writebackAfterMerge_bits_vls_vpu_isVleff (gM_io_writebackAfterMerge_bits_vls_vpu_isVleff),
    .io_writebackAfterMerge_bits_vls_oldVdPsrc (gM_io_writebackAfterMerge_bits_vls_oldVdPsrc),
    .io_writebackAfterMerge_bits_vls_vdIdx (gM_io_writebackAfterMerge_bits_vls_vdIdx),
    .io_writebackAfterMerge_bits_vls_vdIdxInField (gM_io_writebackAfterMerge_bits_vls_vdIdxInField),
    .io_writebackAfterMerge_bits_vls_isIndexed (gM_io_writebackAfterMerge_bits_vls_isIndexed),
    .io_writebackAfterMerge_bits_vls_isMasked (gM_io_writebackAfterMerge_bits_vls_isMasked),
    .io_writebackAfterMerge_bits_vls_isStrided (gM_io_writebackAfterMerge_bits_vls_isStrided),
    .io_writebackAfterMerge_bits_vls_isWhole (gM_io_writebackAfterMerge_bits_vls_isWhole),
    .io_writebackAfterMerge_bits_vls_isVecLoad (gM_io_writebackAfterMerge_bits_vls_isVecLoad),
    .io_writebackAfterMerge_bits_vls_isVlm (gM_io_writebackAfterMerge_bits_vls_isVlm),
    .io_writebackAfterMerge_bits_debug_isMMIO (gM_io_writebackAfterMerge_bits_debug_isMMIO),
    .io_writebackAfterMerge_bits_debug_isNCIO (gM_io_writebackAfterMerge_bits_debug_isNCIO),
    .io_writebackAfterMerge_bits_debug_isPerfCnt (gM_io_writebackAfterMerge_bits_debug_isPerfCnt),
    .io_writebackAfterMerge_bits_debug_paddr (gM_io_writebackAfterMerge_bits_debug_paddr),
    .io_writebackAfterMerge_bits_debug_vaddr (gM_io_writebackAfterMerge_bits_debug_vaddr),
    .io_writebackAfterMerge_bits_debugInfo_eliminatedMove (gM_io_writebackAfterMerge_bits_debugInfo_eliminatedMove),
    .io_writebackAfterMerge_bits_debugInfo_renameTime (gM_io_writebackAfterMerge_bits_debugInfo_renameTime),
    .io_writebackAfterMerge_bits_debugInfo_dispatchTime (gM_io_writebackAfterMerge_bits_debugInfo_dispatchTime),
    .io_writebackAfterMerge_bits_debugInfo_enqRsTime (gM_io_writebackAfterMerge_bits_debugInfo_enqRsTime),
    .io_writebackAfterMerge_bits_debugInfo_selectTime (gM_io_writebackAfterMerge_bits_debugInfo_selectTime),
    .io_writebackAfterMerge_bits_debugInfo_issueTime (gM_io_writebackAfterMerge_bits_debugInfo_issueTime),
    .io_writebackAfterMerge_bits_debugInfo_writebackTime (gM_io_writebackAfterMerge_bits_debugInfo_writebackTime),
    .io_writebackAfterMerge_bits_debugInfo_runahead_checkpoint_id (gM_io_writebackAfterMerge_bits_debugInfo_runahead_checkpoint_id),
    .io_writebackAfterMerge_bits_debugInfo_tlbFirstReqTime (gM_io_writebackAfterMerge_bits_debugInfo_tlbFirstReqTime),
    .io_writebackAfterMerge_bits_debugInfo_tlbRespTime (gM_io_writebackAfterMerge_bits_debugInfo_tlbRespTime),
    .io_writebackAfterMerge_bits_debug_seqNum_seqNum (gM_io_writebackAfterMerge_bits_debug_seqNum_seqNum),
    .io_writebackAfterMerge_bits_debug_seqNum_uopIdx (gM_io_writebackAfterMerge_bits_debug_seqNum_uopIdx)
  );
  VldMergeUnit_xs u_iM (
    .clock (clock),
    .io_flush_valid (fl_valid),
    .io_flush_bits_robIdx_flag (fl_flag),
    .io_flush_bits_robIdx_value (fl_value),
    .io_flush_bits_level (fl_level),
    .io_writeback_valid (wb_valid),
    .io_writeback_bits_data_0 (r128a),
    .io_writeback_bits_pdest (noise[0 +: 7]),
    .io_writeback_bits_robIdx_flag (wb_flag),
    .io_writeback_bits_robIdx_value (wb_value),
    .io_writeback_bits_vecWen (noise[7 +: 1]),
    .io_writeback_bits_v0Wen (noise[8 +: 1]),
    .io_writeback_bits_vlWen (vlwen),
    .io_writeback_bits_exceptionVec_0 (noise[9 +: 1]),
    .io_writeback_bits_exceptionVec_1 (noise[10 +: 1]),
    .io_writeback_bits_exceptionVec_2 (noise[11 +: 1]),
    .io_writeback_bits_exceptionVec_3 (noise[12 +: 1]),
    .io_writeback_bits_exceptionVec_4 (noise[13 +: 1]),
    .io_writeback_bits_exceptionVec_5 (noise[14 +: 1]),
    .io_writeback_bits_exceptionVec_6 (noise[15 +: 1]),
    .io_writeback_bits_exceptionVec_7 (noise[16 +: 1]),
    .io_writeback_bits_exceptionVec_8 (noise[17 +: 1]),
    .io_writeback_bits_exceptionVec_9 (noise[18 +: 1]),
    .io_writeback_bits_exceptionVec_10 (noise[19 +: 1]),
    .io_writeback_bits_exceptionVec_11 (noise[20 +: 1]),
    .io_writeback_bits_exceptionVec_12 (noise[21 +: 1]),
    .io_writeback_bits_exceptionVec_13 (noise[22 +: 1]),
    .io_writeback_bits_exceptionVec_14 (noise[23 +: 1]),
    .io_writeback_bits_exceptionVec_15 (noise[24 +: 1]),
    .io_writeback_bits_exceptionVec_16 (noise[25 +: 1]),
    .io_writeback_bits_exceptionVec_17 (noise[26 +: 1]),
    .io_writeback_bits_exceptionVec_18 (noise[27 +: 1]),
    .io_writeback_bits_exceptionVec_19 (noise[28 +: 1]),
    .io_writeback_bits_exceptionVec_20 (noise[29 +: 1]),
    .io_writeback_bits_exceptionVec_21 (noise[30 +: 1]),
    .io_writeback_bits_exceptionVec_22 (noise[31 +: 1]),
    .io_writeback_bits_exceptionVec_23 (noise[32 +: 1]),
    .io_writeback_bits_flushPipe (noise[33 +: 1]),
    .io_writeback_bits_replay (noise[34 +: 1]),
    .io_writeback_bits_trigger (noise[35 +: 4]),
    .io_writeback_bits_vls_vpu_vill (noise[39 +: 1]),
    .io_writeback_bits_vls_vpu_vma (vma),
    .io_writeback_bits_vls_vpu_vta (vta),
    .io_writeback_bits_vls_vpu_vsew (r2b),
    .io_writeback_bits_vls_vpu_vlmul (noise[40 +: 3]),
    .io_writeback_bits_vls_vpu_specVill (noise[43 +: 1]),
    .io_writeback_bits_vls_vpu_specVma (noise[44 +: 1]),
    .io_writeback_bits_vls_vpu_specVta (noise[45 +: 1]),
    .io_writeback_bits_vls_vpu_specVsew (noise[46 +: 2]),
    .io_writeback_bits_vls_vpu_specVlmul (noise[48 +: 3]),
    .io_writeback_bits_vls_vpu_vm (vm),
    .io_writeback_bits_vls_vpu_vstart (vstart),
    .io_writeback_bits_vls_vpu_frm (noise[51 +: 3]),
    .io_writeback_bits_vls_vpu_fpu_isFpToVecInst (noise[54 +: 1]),
    .io_writeback_bits_vls_vpu_fpu_isFP32Instr (noise[55 +: 1]),
    .io_writeback_bits_vls_vpu_fpu_isFP64Instr (noise[56 +: 1]),
    .io_writeback_bits_vls_vpu_fpu_isReduction (noise[57 +: 1]),
    .io_writeback_bits_vls_vpu_fpu_isFoldTo1_2 (noise[58 +: 1]),
    .io_writeback_bits_vls_vpu_fpu_isFoldTo1_4 (noise[59 +: 1]),
    .io_writeback_bits_vls_vpu_fpu_isFoldTo1_8 (noise[60 +: 1]),
    .io_writeback_bits_vls_vpu_vxrm (noise[61 +: 2]),
    .io_writeback_bits_vls_vpu_vuopIdx (noise[63 +: 7]),
    .io_writeback_bits_vls_vpu_lastUop (noise[70 +: 1]),
    .io_writeback_bits_vls_vpu_vmask (r128c),
    .io_writeback_bits_vls_vpu_vl (vl),
    .io_writeback_bits_vls_vpu_nf (noise[71 +: 3]),
    .io_writeback_bits_vls_vpu_veew (r2a),
    .io_writeback_bits_vls_vpu_isReverse (noise[74 +: 1]),
    .io_writeback_bits_vls_vpu_isExt (noise[75 +: 1]),
    .io_writeback_bits_vls_vpu_isNarrow (noise[76 +: 1]),
    .io_writeback_bits_vls_vpu_isDstMask (noise[77 +: 1]),
    .io_writeback_bits_vls_vpu_isOpMask (noise[78 +: 1]),
    .io_writeback_bits_vls_vpu_isMove (noise[79 +: 1]),
    .io_writeback_bits_vls_vpu_isDependOldVd (noise[80 +: 1]),
    .io_writeback_bits_vls_vpu_isWritePartVd (noise[81 +: 1]),
    .io_writeback_bits_vls_vpu_isVleff (noise[82 +: 1]),
    .io_writeback_bits_vls_oldVdPsrc (noise[83 +: 8]),
    .io_writeback_bits_vls_vdIdx (noise[91 +: 3]),
    .io_writeback_bits_vls_vdIdxInField (r3),
    .io_writeback_bits_vls_isIndexed (idx),
    .io_writeback_bits_vls_isMasked (msk),
    .io_writeback_bits_vls_isStrided (noise[94 +: 1]),
    .io_writeback_bits_vls_isWhole (noise[95 +: 1]),
    .io_writeback_bits_vls_isVecLoad (noise[96 +: 1]),
    .io_writeback_bits_vls_isVlm (noise[97 +: 1]),
    .io_writeback_bits_debug_isMMIO (noise[98 +: 1]),
    .io_writeback_bits_debug_isNCIO (noise[99 +: 1]),
    .io_writeback_bits_debug_isPerfCnt (noise[100 +: 1]),
    .io_writeback_bits_debug_paddr (noise[101 +: 48]),
    .io_writeback_bits_debug_vaddr (noise[149 +: 50]),
    .io_writeback_bits_debugInfo_eliminatedMove (noise[199 +: 1]),
    .io_writeback_bits_debugInfo_renameTime (noise[200 +: 64]),
    .io_writeback_bits_debugInfo_dispatchTime (noise[264 +: 64]),
    .io_writeback_bits_debugInfo_enqRsTime (noise[328 +: 64]),
    .io_writeback_bits_debugInfo_selectTime (noise[392 +: 64]),
    .io_writeback_bits_debugInfo_issueTime (noise[456 +: 64]),
    .io_writeback_bits_debugInfo_writebackTime (noise[520 +: 64]),
    .io_writeback_bits_debugInfo_runahead_checkpoint_id (noise[584 +: 64]),
    .io_writeback_bits_debugInfo_tlbFirstReqTime (noise[648 +: 64]),
    .io_writeback_bits_debugInfo_tlbRespTime (noise[712 +: 64]),
    .io_writeback_bits_debug_seqNum_seqNum (noise[776 +: 56]),
    .io_writeback_bits_debug_seqNum_uopIdx (noise[832 +: 8]),
    .io_writebackAfterMerge_valid (iM_io_writebackAfterMerge_valid),
    .io_writebackAfterMerge_bits_data_0 (iM_io_writebackAfterMerge_bits_data_0),
    .io_writebackAfterMerge_bits_pdest (iM_io_writebackAfterMerge_bits_pdest),
    .io_writebackAfterMerge_bits_robIdx_flag (iM_io_writebackAfterMerge_bits_robIdx_flag),
    .io_writebackAfterMerge_bits_robIdx_value (iM_io_writebackAfterMerge_bits_robIdx_value),
    .io_writebackAfterMerge_bits_vecWen (iM_io_writebackAfterMerge_bits_vecWen),
    .io_writebackAfterMerge_bits_v0Wen (iM_io_writebackAfterMerge_bits_v0Wen),
    .io_writebackAfterMerge_bits_vlWen (iM_io_writebackAfterMerge_bits_vlWen),
    .io_writebackAfterMerge_bits_exceptionVec_0 (iM_io_writebackAfterMerge_bits_exceptionVec_0),
    .io_writebackAfterMerge_bits_exceptionVec_1 (iM_io_writebackAfterMerge_bits_exceptionVec_1),
    .io_writebackAfterMerge_bits_exceptionVec_2 (iM_io_writebackAfterMerge_bits_exceptionVec_2),
    .io_writebackAfterMerge_bits_exceptionVec_3 (iM_io_writebackAfterMerge_bits_exceptionVec_3),
    .io_writebackAfterMerge_bits_exceptionVec_4 (iM_io_writebackAfterMerge_bits_exceptionVec_4),
    .io_writebackAfterMerge_bits_exceptionVec_5 (iM_io_writebackAfterMerge_bits_exceptionVec_5),
    .io_writebackAfterMerge_bits_exceptionVec_6 (iM_io_writebackAfterMerge_bits_exceptionVec_6),
    .io_writebackAfterMerge_bits_exceptionVec_7 (iM_io_writebackAfterMerge_bits_exceptionVec_7),
    .io_writebackAfterMerge_bits_exceptionVec_8 (iM_io_writebackAfterMerge_bits_exceptionVec_8),
    .io_writebackAfterMerge_bits_exceptionVec_9 (iM_io_writebackAfterMerge_bits_exceptionVec_9),
    .io_writebackAfterMerge_bits_exceptionVec_10 (iM_io_writebackAfterMerge_bits_exceptionVec_10),
    .io_writebackAfterMerge_bits_exceptionVec_11 (iM_io_writebackAfterMerge_bits_exceptionVec_11),
    .io_writebackAfterMerge_bits_exceptionVec_12 (iM_io_writebackAfterMerge_bits_exceptionVec_12),
    .io_writebackAfterMerge_bits_exceptionVec_13 (iM_io_writebackAfterMerge_bits_exceptionVec_13),
    .io_writebackAfterMerge_bits_exceptionVec_14 (iM_io_writebackAfterMerge_bits_exceptionVec_14),
    .io_writebackAfterMerge_bits_exceptionVec_15 (iM_io_writebackAfterMerge_bits_exceptionVec_15),
    .io_writebackAfterMerge_bits_exceptionVec_16 (iM_io_writebackAfterMerge_bits_exceptionVec_16),
    .io_writebackAfterMerge_bits_exceptionVec_17 (iM_io_writebackAfterMerge_bits_exceptionVec_17),
    .io_writebackAfterMerge_bits_exceptionVec_18 (iM_io_writebackAfterMerge_bits_exceptionVec_18),
    .io_writebackAfterMerge_bits_exceptionVec_19 (iM_io_writebackAfterMerge_bits_exceptionVec_19),
    .io_writebackAfterMerge_bits_exceptionVec_20 (iM_io_writebackAfterMerge_bits_exceptionVec_20),
    .io_writebackAfterMerge_bits_exceptionVec_21 (iM_io_writebackAfterMerge_bits_exceptionVec_21),
    .io_writebackAfterMerge_bits_exceptionVec_22 (iM_io_writebackAfterMerge_bits_exceptionVec_22),
    .io_writebackAfterMerge_bits_exceptionVec_23 (iM_io_writebackAfterMerge_bits_exceptionVec_23),
    .io_writebackAfterMerge_bits_flushPipe (iM_io_writebackAfterMerge_bits_flushPipe),
    .io_writebackAfterMerge_bits_replay (iM_io_writebackAfterMerge_bits_replay),
    .io_writebackAfterMerge_bits_trigger (iM_io_writebackAfterMerge_bits_trigger),
    .io_writebackAfterMerge_bits_vls_vpu_vill (iM_io_writebackAfterMerge_bits_vls_vpu_vill),
    .io_writebackAfterMerge_bits_vls_vpu_vma (iM_io_writebackAfterMerge_bits_vls_vpu_vma),
    .io_writebackAfterMerge_bits_vls_vpu_vta (iM_io_writebackAfterMerge_bits_vls_vpu_vta),
    .io_writebackAfterMerge_bits_vls_vpu_vsew (iM_io_writebackAfterMerge_bits_vls_vpu_vsew),
    .io_writebackAfterMerge_bits_vls_vpu_vlmul (iM_io_writebackAfterMerge_bits_vls_vpu_vlmul),
    .io_writebackAfterMerge_bits_vls_vpu_specVill (iM_io_writebackAfterMerge_bits_vls_vpu_specVill),
    .io_writebackAfterMerge_bits_vls_vpu_specVma (iM_io_writebackAfterMerge_bits_vls_vpu_specVma),
    .io_writebackAfterMerge_bits_vls_vpu_specVta (iM_io_writebackAfterMerge_bits_vls_vpu_specVta),
    .io_writebackAfterMerge_bits_vls_vpu_specVsew (iM_io_writebackAfterMerge_bits_vls_vpu_specVsew),
    .io_writebackAfterMerge_bits_vls_vpu_specVlmul (iM_io_writebackAfterMerge_bits_vls_vpu_specVlmul),
    .io_writebackAfterMerge_bits_vls_vpu_vm (iM_io_writebackAfterMerge_bits_vls_vpu_vm),
    .io_writebackAfterMerge_bits_vls_vpu_vstart (iM_io_writebackAfterMerge_bits_vls_vpu_vstart),
    .io_writebackAfterMerge_bits_vls_vpu_frm (iM_io_writebackAfterMerge_bits_vls_vpu_frm),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isFpToVecInst (iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFpToVecInst),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isFP32Instr (iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFP32Instr),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isFP64Instr (iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFP64Instr),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isReduction (iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isReduction),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_2 (iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_2),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_4 (iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_4),
    .io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_8 (iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_8),
    .io_writebackAfterMerge_bits_vls_vpu_vxrm (iM_io_writebackAfterMerge_bits_vls_vpu_vxrm),
    .io_writebackAfterMerge_bits_vls_vpu_vuopIdx (iM_io_writebackAfterMerge_bits_vls_vpu_vuopIdx),
    .io_writebackAfterMerge_bits_vls_vpu_lastUop (iM_io_writebackAfterMerge_bits_vls_vpu_lastUop),
    .io_writebackAfterMerge_bits_vls_vpu_vmask (iM_io_writebackAfterMerge_bits_vls_vpu_vmask),
    .io_writebackAfterMerge_bits_vls_vpu_vl (iM_io_writebackAfterMerge_bits_vls_vpu_vl),
    .io_writebackAfterMerge_bits_vls_vpu_nf (iM_io_writebackAfterMerge_bits_vls_vpu_nf),
    .io_writebackAfterMerge_bits_vls_vpu_veew (iM_io_writebackAfterMerge_bits_vls_vpu_veew),
    .io_writebackAfterMerge_bits_vls_vpu_isReverse (iM_io_writebackAfterMerge_bits_vls_vpu_isReverse),
    .io_writebackAfterMerge_bits_vls_vpu_isExt (iM_io_writebackAfterMerge_bits_vls_vpu_isExt),
    .io_writebackAfterMerge_bits_vls_vpu_isNarrow (iM_io_writebackAfterMerge_bits_vls_vpu_isNarrow),
    .io_writebackAfterMerge_bits_vls_vpu_isDstMask (iM_io_writebackAfterMerge_bits_vls_vpu_isDstMask),
    .io_writebackAfterMerge_bits_vls_vpu_isOpMask (iM_io_writebackAfterMerge_bits_vls_vpu_isOpMask),
    .io_writebackAfterMerge_bits_vls_vpu_isMove (iM_io_writebackAfterMerge_bits_vls_vpu_isMove),
    .io_writebackAfterMerge_bits_vls_vpu_isDependOldVd (iM_io_writebackAfterMerge_bits_vls_vpu_isDependOldVd),
    .io_writebackAfterMerge_bits_vls_vpu_isWritePartVd (iM_io_writebackAfterMerge_bits_vls_vpu_isWritePartVd),
    .io_writebackAfterMerge_bits_vls_vpu_isVleff (iM_io_writebackAfterMerge_bits_vls_vpu_isVleff),
    .io_writebackAfterMerge_bits_vls_oldVdPsrc (iM_io_writebackAfterMerge_bits_vls_oldVdPsrc),
    .io_writebackAfterMerge_bits_vls_vdIdx (iM_io_writebackAfterMerge_bits_vls_vdIdx),
    .io_writebackAfterMerge_bits_vls_vdIdxInField (iM_io_writebackAfterMerge_bits_vls_vdIdxInField),
    .io_writebackAfterMerge_bits_vls_isIndexed (iM_io_writebackAfterMerge_bits_vls_isIndexed),
    .io_writebackAfterMerge_bits_vls_isMasked (iM_io_writebackAfterMerge_bits_vls_isMasked),
    .io_writebackAfterMerge_bits_vls_isStrided (iM_io_writebackAfterMerge_bits_vls_isStrided),
    .io_writebackAfterMerge_bits_vls_isWhole (iM_io_writebackAfterMerge_bits_vls_isWhole),
    .io_writebackAfterMerge_bits_vls_isVecLoad (iM_io_writebackAfterMerge_bits_vls_isVecLoad),
    .io_writebackAfterMerge_bits_vls_isVlm (iM_io_writebackAfterMerge_bits_vls_isVlm),
    .io_writebackAfterMerge_bits_debug_isMMIO (iM_io_writebackAfterMerge_bits_debug_isMMIO),
    .io_writebackAfterMerge_bits_debug_isNCIO (iM_io_writebackAfterMerge_bits_debug_isNCIO),
    .io_writebackAfterMerge_bits_debug_isPerfCnt (iM_io_writebackAfterMerge_bits_debug_isPerfCnt),
    .io_writebackAfterMerge_bits_debug_paddr (iM_io_writebackAfterMerge_bits_debug_paddr),
    .io_writebackAfterMerge_bits_debug_vaddr (iM_io_writebackAfterMerge_bits_debug_vaddr),
    .io_writebackAfterMerge_bits_debugInfo_eliminatedMove (iM_io_writebackAfterMerge_bits_debugInfo_eliminatedMove),
    .io_writebackAfterMerge_bits_debugInfo_renameTime (iM_io_writebackAfterMerge_bits_debugInfo_renameTime),
    .io_writebackAfterMerge_bits_debugInfo_dispatchTime (iM_io_writebackAfterMerge_bits_debugInfo_dispatchTime),
    .io_writebackAfterMerge_bits_debugInfo_enqRsTime (iM_io_writebackAfterMerge_bits_debugInfo_enqRsTime),
    .io_writebackAfterMerge_bits_debugInfo_selectTime (iM_io_writebackAfterMerge_bits_debugInfo_selectTime),
    .io_writebackAfterMerge_bits_debugInfo_issueTime (iM_io_writebackAfterMerge_bits_debugInfo_issueTime),
    .io_writebackAfterMerge_bits_debugInfo_writebackTime (iM_io_writebackAfterMerge_bits_debugInfo_writebackTime),
    .io_writebackAfterMerge_bits_debugInfo_runahead_checkpoint_id (iM_io_writebackAfterMerge_bits_debugInfo_runahead_checkpoint_id),
    .io_writebackAfterMerge_bits_debugInfo_tlbFirstReqTime (iM_io_writebackAfterMerge_bits_debugInfo_tlbFirstReqTime),
    .io_writebackAfterMerge_bits_debugInfo_tlbRespTime (iM_io_writebackAfterMerge_bits_debugInfo_tlbRespTime),
    .io_writebackAfterMerge_bits_debug_seqNum_seqNum (iM_io_writebackAfterMerge_bits_debug_seqNum_seqNum),
    .io_writebackAfterMerge_bits_debug_seqNum_uopIdx (iM_io_writebackAfterMerge_bits_debug_seqNum_uopIdx)
  );

  // 上一拍送进去的 valid（用于数「被冲刷吃掉」的次数）
  logic wb_valid_q;
  always @(posedge clock) wb_valid_q <= wb_valid;
  // 覆盖计数
  longint c_empty = 0, c_active = 0, c_agn = 0, c_flush_kill = 0, c_vlwen = 0, c_merge_diff = 0;

  task automatic drive();
    u8a = 8'($urandom); u8b = 8'($urandom);
    r128a = {$urandom, $urandom, $urandom, $urandom};
    r128b = {$urandom, $urandom, $urandom, $urandom};
    r128c = {$urandom, $urandom, $urandom, $urandom};
    r2a = 2'($urandom); r2b = 2'($urandom); r3 = 3'($urandom); r16 = 16'($urandom);
    vstart = 8'($urandom_range(0, 40)); vl = 8'($urandom_range(0, 140));
    if ($urandom_range(0, 15) == 0) begin vstart = 8'($urandom); vl = 8'($urandom); end
    vma = $urandom; vta = $urandom;
    vm = ($urandom_range(0, 3) == 0); vlwen = ($urandom_range(0, 3) == 0);
    idx = ($urandom_range(0, 3) == 0); msk = ($urandom_range(0, 3) == 0);
    wb_valid = ($urandom_range(0, 3) != 0);
    wb_flag = $urandom; wb_value = 8'($urandom);
    fl_valid = ($urandom_range(0, 2) == 0); fl_level = $urandom;
    if ($urandom_range(0, 1)) begin
      fl_flag = wb_flag ^ ($urandom_range(0, 7) == 0);
      fl_value = wb_value + 8'($urandom_range(0, 6)) - 8'd3;
    end else begin fl_flag = $urandom; fl_value = 8'($urandom); end
    for (int k = 0; k < 32; k++) noise[k*32 +: 32] = $urandom;
  endtask

  task automatic compare(bit seq_ok);
    `CK(g1_io_dataOut, i1_io_dataOut, "UIntToContLow1s.io_dataOut")
    `CK(g0_io_dataOut, i0_io_dataOut, "UIntToContLow0s.io_dataOut")
    `CK(gB_io_out_activeEn, iB_io_out_activeEn, "ByteMaskTailGen.io_out_activeEn")
    `CK(gB_io_out_agnosticEn, iB_io_out_agnosticEn, "ByteMaskTailGen.io_out_agnosticEn")
    `CK(gG_io_out_vd, iG_io_out_vd, "VldMgu.io_out_vd")
    if (seq_ok) begin
      `CK(gM_io_writebackAfterMerge_valid, iM_io_writebackAfterMerge_valid, "VldMergeUnit.io_writebackAfterMerge_valid")
      `CK(gM_io_writebackAfterMerge_bits_data_0, iM_io_writebackAfterMerge_bits_data_0, "VldMergeUnit.io_writebackAfterMerge_bits_data_0")
      `CK(gM_io_writebackAfterMerge_bits_pdest, iM_io_writebackAfterMerge_bits_pdest, "VldMergeUnit.io_writebackAfterMerge_bits_pdest")
      `CK(gM_io_writebackAfterMerge_bits_robIdx_flag, iM_io_writebackAfterMerge_bits_robIdx_flag, "VldMergeUnit.io_writebackAfterMerge_bits_robIdx_flag")
      `CK(gM_io_writebackAfterMerge_bits_robIdx_value, iM_io_writebackAfterMerge_bits_robIdx_value, "VldMergeUnit.io_writebackAfterMerge_bits_robIdx_value")
      `CK(gM_io_writebackAfterMerge_bits_vecWen, iM_io_writebackAfterMerge_bits_vecWen, "VldMergeUnit.io_writebackAfterMerge_bits_vecWen")
      `CK(gM_io_writebackAfterMerge_bits_v0Wen, iM_io_writebackAfterMerge_bits_v0Wen, "VldMergeUnit.io_writebackAfterMerge_bits_v0Wen")
      `CK(gM_io_writebackAfterMerge_bits_vlWen, iM_io_writebackAfterMerge_bits_vlWen, "VldMergeUnit.io_writebackAfterMerge_bits_vlWen")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_0, iM_io_writebackAfterMerge_bits_exceptionVec_0, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_0")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_1, iM_io_writebackAfterMerge_bits_exceptionVec_1, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_1")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_2, iM_io_writebackAfterMerge_bits_exceptionVec_2, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_2")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_3, iM_io_writebackAfterMerge_bits_exceptionVec_3, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_3")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_4, iM_io_writebackAfterMerge_bits_exceptionVec_4, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_4")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_5, iM_io_writebackAfterMerge_bits_exceptionVec_5, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_5")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_6, iM_io_writebackAfterMerge_bits_exceptionVec_6, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_6")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_7, iM_io_writebackAfterMerge_bits_exceptionVec_7, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_7")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_8, iM_io_writebackAfterMerge_bits_exceptionVec_8, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_8")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_9, iM_io_writebackAfterMerge_bits_exceptionVec_9, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_9")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_10, iM_io_writebackAfterMerge_bits_exceptionVec_10, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_10")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_11, iM_io_writebackAfterMerge_bits_exceptionVec_11, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_11")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_12, iM_io_writebackAfterMerge_bits_exceptionVec_12, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_12")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_13, iM_io_writebackAfterMerge_bits_exceptionVec_13, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_13")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_14, iM_io_writebackAfterMerge_bits_exceptionVec_14, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_14")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_15, iM_io_writebackAfterMerge_bits_exceptionVec_15, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_15")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_16, iM_io_writebackAfterMerge_bits_exceptionVec_16, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_16")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_17, iM_io_writebackAfterMerge_bits_exceptionVec_17, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_17")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_18, iM_io_writebackAfterMerge_bits_exceptionVec_18, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_18")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_19, iM_io_writebackAfterMerge_bits_exceptionVec_19, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_19")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_20, iM_io_writebackAfterMerge_bits_exceptionVec_20, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_20")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_21, iM_io_writebackAfterMerge_bits_exceptionVec_21, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_21")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_22, iM_io_writebackAfterMerge_bits_exceptionVec_22, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_22")
      `CK(gM_io_writebackAfterMerge_bits_exceptionVec_23, iM_io_writebackAfterMerge_bits_exceptionVec_23, "VldMergeUnit.io_writebackAfterMerge_bits_exceptionVec_23")
      `CK(gM_io_writebackAfterMerge_bits_flushPipe, iM_io_writebackAfterMerge_bits_flushPipe, "VldMergeUnit.io_writebackAfterMerge_bits_flushPipe")
      `CK(gM_io_writebackAfterMerge_bits_replay, iM_io_writebackAfterMerge_bits_replay, "VldMergeUnit.io_writebackAfterMerge_bits_replay")
      `CK(gM_io_writebackAfterMerge_bits_trigger, iM_io_writebackAfterMerge_bits_trigger, "VldMergeUnit.io_writebackAfterMerge_bits_trigger")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_vill, iM_io_writebackAfterMerge_bits_vls_vpu_vill, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_vill")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_vma, iM_io_writebackAfterMerge_bits_vls_vpu_vma, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_vma")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_vta, iM_io_writebackAfterMerge_bits_vls_vpu_vta, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_vta")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_vsew, iM_io_writebackAfterMerge_bits_vls_vpu_vsew, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_vsew")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_vlmul, iM_io_writebackAfterMerge_bits_vls_vpu_vlmul, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_vlmul")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_specVill, iM_io_writebackAfterMerge_bits_vls_vpu_specVill, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_specVill")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_specVma, iM_io_writebackAfterMerge_bits_vls_vpu_specVma, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_specVma")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_specVta, iM_io_writebackAfterMerge_bits_vls_vpu_specVta, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_specVta")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_specVsew, iM_io_writebackAfterMerge_bits_vls_vpu_specVsew, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_specVsew")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_specVlmul, iM_io_writebackAfterMerge_bits_vls_vpu_specVlmul, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_specVlmul")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_vm, iM_io_writebackAfterMerge_bits_vls_vpu_vm, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_vm")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_vstart, iM_io_writebackAfterMerge_bits_vls_vpu_vstart, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_vstart")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_frm, iM_io_writebackAfterMerge_bits_vls_vpu_frm, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_frm")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFpToVecInst, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFpToVecInst, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_fpu_isFpToVecInst")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFP32Instr, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFP32Instr, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_fpu_isFP32Instr")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFP64Instr, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFP64Instr, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_fpu_isFP64Instr")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isReduction, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isReduction, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_fpu_isReduction")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_2, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_2, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_2")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_4, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_4, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_4")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_8, iM_io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_8, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_8")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_vxrm, iM_io_writebackAfterMerge_bits_vls_vpu_vxrm, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_vxrm")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_vuopIdx, iM_io_writebackAfterMerge_bits_vls_vpu_vuopIdx, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_vuopIdx")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_lastUop, iM_io_writebackAfterMerge_bits_vls_vpu_lastUop, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_lastUop")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_vmask, iM_io_writebackAfterMerge_bits_vls_vpu_vmask, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_vmask")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_vl, iM_io_writebackAfterMerge_bits_vls_vpu_vl, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_vl")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_nf, iM_io_writebackAfterMerge_bits_vls_vpu_nf, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_nf")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_veew, iM_io_writebackAfterMerge_bits_vls_vpu_veew, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_veew")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_isReverse, iM_io_writebackAfterMerge_bits_vls_vpu_isReverse, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_isReverse")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_isExt, iM_io_writebackAfterMerge_bits_vls_vpu_isExt, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_isExt")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_isNarrow, iM_io_writebackAfterMerge_bits_vls_vpu_isNarrow, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_isNarrow")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_isDstMask, iM_io_writebackAfterMerge_bits_vls_vpu_isDstMask, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_isDstMask")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_isOpMask, iM_io_writebackAfterMerge_bits_vls_vpu_isOpMask, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_isOpMask")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_isMove, iM_io_writebackAfterMerge_bits_vls_vpu_isMove, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_isMove")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_isDependOldVd, iM_io_writebackAfterMerge_bits_vls_vpu_isDependOldVd, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_isDependOldVd")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_isWritePartVd, iM_io_writebackAfterMerge_bits_vls_vpu_isWritePartVd, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_isWritePartVd")
      `CK(gM_io_writebackAfterMerge_bits_vls_vpu_isVleff, iM_io_writebackAfterMerge_bits_vls_vpu_isVleff, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vpu_isVleff")
      `CK(gM_io_writebackAfterMerge_bits_vls_oldVdPsrc, iM_io_writebackAfterMerge_bits_vls_oldVdPsrc, "VldMergeUnit.io_writebackAfterMerge_bits_vls_oldVdPsrc")
      `CK(gM_io_writebackAfterMerge_bits_vls_vdIdx, iM_io_writebackAfterMerge_bits_vls_vdIdx, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vdIdx")
      `CK(gM_io_writebackAfterMerge_bits_vls_vdIdxInField, iM_io_writebackAfterMerge_bits_vls_vdIdxInField, "VldMergeUnit.io_writebackAfterMerge_bits_vls_vdIdxInField")
      `CK(gM_io_writebackAfterMerge_bits_vls_isIndexed, iM_io_writebackAfterMerge_bits_vls_isIndexed, "VldMergeUnit.io_writebackAfterMerge_bits_vls_isIndexed")
      `CK(gM_io_writebackAfterMerge_bits_vls_isMasked, iM_io_writebackAfterMerge_bits_vls_isMasked, "VldMergeUnit.io_writebackAfterMerge_bits_vls_isMasked")
      `CK(gM_io_writebackAfterMerge_bits_vls_isStrided, iM_io_writebackAfterMerge_bits_vls_isStrided, "VldMergeUnit.io_writebackAfterMerge_bits_vls_isStrided")
      `CK(gM_io_writebackAfterMerge_bits_vls_isWhole, iM_io_writebackAfterMerge_bits_vls_isWhole, "VldMergeUnit.io_writebackAfterMerge_bits_vls_isWhole")
      `CK(gM_io_writebackAfterMerge_bits_vls_isVecLoad, iM_io_writebackAfterMerge_bits_vls_isVecLoad, "VldMergeUnit.io_writebackAfterMerge_bits_vls_isVecLoad")
      `CK(gM_io_writebackAfterMerge_bits_vls_isVlm, iM_io_writebackAfterMerge_bits_vls_isVlm, "VldMergeUnit.io_writebackAfterMerge_bits_vls_isVlm")
      `CK(gM_io_writebackAfterMerge_bits_debug_isMMIO, iM_io_writebackAfterMerge_bits_debug_isMMIO, "VldMergeUnit.io_writebackAfterMerge_bits_debug_isMMIO")
      `CK(gM_io_writebackAfterMerge_bits_debug_isNCIO, iM_io_writebackAfterMerge_bits_debug_isNCIO, "VldMergeUnit.io_writebackAfterMerge_bits_debug_isNCIO")
      `CK(gM_io_writebackAfterMerge_bits_debug_isPerfCnt, iM_io_writebackAfterMerge_bits_debug_isPerfCnt, "VldMergeUnit.io_writebackAfterMerge_bits_debug_isPerfCnt")
      `CK(gM_io_writebackAfterMerge_bits_debug_paddr, iM_io_writebackAfterMerge_bits_debug_paddr, "VldMergeUnit.io_writebackAfterMerge_bits_debug_paddr")
      `CK(gM_io_writebackAfterMerge_bits_debug_vaddr, iM_io_writebackAfterMerge_bits_debug_vaddr, "VldMergeUnit.io_writebackAfterMerge_bits_debug_vaddr")
      `CK(gM_io_writebackAfterMerge_bits_debugInfo_eliminatedMove, iM_io_writebackAfterMerge_bits_debugInfo_eliminatedMove, "VldMergeUnit.io_writebackAfterMerge_bits_debugInfo_eliminatedMove")
      `CK(gM_io_writebackAfterMerge_bits_debugInfo_renameTime, iM_io_writebackAfterMerge_bits_debugInfo_renameTime, "VldMergeUnit.io_writebackAfterMerge_bits_debugInfo_renameTime")
      `CK(gM_io_writebackAfterMerge_bits_debugInfo_dispatchTime, iM_io_writebackAfterMerge_bits_debugInfo_dispatchTime, "VldMergeUnit.io_writebackAfterMerge_bits_debugInfo_dispatchTime")
      `CK(gM_io_writebackAfterMerge_bits_debugInfo_enqRsTime, iM_io_writebackAfterMerge_bits_debugInfo_enqRsTime, "VldMergeUnit.io_writebackAfterMerge_bits_debugInfo_enqRsTime")
      `CK(gM_io_writebackAfterMerge_bits_debugInfo_selectTime, iM_io_writebackAfterMerge_bits_debugInfo_selectTime, "VldMergeUnit.io_writebackAfterMerge_bits_debugInfo_selectTime")
      `CK(gM_io_writebackAfterMerge_bits_debugInfo_issueTime, iM_io_writebackAfterMerge_bits_debugInfo_issueTime, "VldMergeUnit.io_writebackAfterMerge_bits_debugInfo_issueTime")
      `CK(gM_io_writebackAfterMerge_bits_debugInfo_writebackTime, iM_io_writebackAfterMerge_bits_debugInfo_writebackTime, "VldMergeUnit.io_writebackAfterMerge_bits_debugInfo_writebackTime")
      `CK(gM_io_writebackAfterMerge_bits_debugInfo_runahead_checkpoint_id, iM_io_writebackAfterMerge_bits_debugInfo_runahead_checkpoint_id, "VldMergeUnit.io_writebackAfterMerge_bits_debugInfo_runahead_checkpoint_id")
      `CK(gM_io_writebackAfterMerge_bits_debugInfo_tlbFirstReqTime, iM_io_writebackAfterMerge_bits_debugInfo_tlbFirstReqTime, "VldMergeUnit.io_writebackAfterMerge_bits_debugInfo_tlbFirstReqTime")
      `CK(gM_io_writebackAfterMerge_bits_debugInfo_tlbRespTime, iM_io_writebackAfterMerge_bits_debugInfo_tlbRespTime, "VldMergeUnit.io_writebackAfterMerge_bits_debugInfo_tlbRespTime")
      `CK(gM_io_writebackAfterMerge_bits_debug_seqNum_seqNum, iM_io_writebackAfterMerge_bits_debug_seqNum_seqNum, "VldMergeUnit.io_writebackAfterMerge_bits_debug_seqNum_seqNum")
      `CK(gM_io_writebackAfterMerge_bits_debug_seqNum_uopIdx, iM_io_writebackAfterMerge_bits_debug_seqNum_uopIdx, "VldMergeUnit.io_writebackAfterMerge_bits_debug_seqNum_uopIdx")
    end
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    for (int unsigned cyc = 0; cyc < NCYCLES; cyc++) begin
      drive();
      if (cyc < 4) wb_valid = 1;          // 无复位：先把寄存器灌成确定值
      #1;
      compare(cyc >= 5);
      if (vstart >= vl) c_empty++;
      if (gB_io_out_activeEn != 0) c_active++;
      if (gB_io_out_agnosticEn != 0) c_agn++;
      if (gM_io_writebackAfterMerge_bits_vlWen) c_vlwen++;
      if (gM_io_writebackAfterMerge_valid && gM_io_writebackAfterMerge_bits_data_0 != u_gM.wbReg_bits_data_0) c_merge_diff++;
      @(posedge clock); #1;
      if (!gM_io_writebackAfterMerge_valid && wb_valid_q) c_flush_kill++;
    end
    $display("COVER empty=%0d active=%0d agnostic=%0d vlwen_out=%0d merge_changed=%0d flush_killed=%0d",
             c_empty, c_active, c_agn, c_vlwen, c_merge_diff, c_flush_kill);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && c_active > 0 && c_agn > 0 && c_merge_diff > 0 && c_flush_kill > 0)
      $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
