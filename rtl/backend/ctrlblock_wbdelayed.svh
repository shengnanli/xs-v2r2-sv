// ============================================================================
// ctrlblock_wbdelayed.svh —— 写回打拍 bits 的 golden-faithful per-lane 窄化。
// ----------------------------------------------------------------------------
// 由 datapath.svh 块 3-A `include。此文件把 27 路 delayedNotFlushedWriteBack 的
// bits 打拍寄存器**逐路窄化到 golden(firtool DCE 后)实际保留的字段**——即该路
// Rob 真正消费的字段(见 ctrlblock_inst.svh 的 wbDelayedBits[N].<field> 引用;
// golden 保留集与本核消费集逐路逐位一致,证据 verif/ut/CtrlBlock/
// wbdelayed_field_inventory.json)。
//
// 原实现把整个 wb_exu_output_t(474 位/路)寄进 27 路 wbDelayedBits_reg,未被 Rob
// 消费的字段(redirect_bits_fullTarget / cfiUpdate_pc / cfiUpdate_target /
// cfiUpdate_backendI{A,P,G}F / ftqIdx_{flag,value} / ftqOffset / level /
// redirect_bits_robIdx_{flag,value} + 各路稀疏未用的 exceptionVec 高位等)在 golden
// 里被 DCE 掉,而本核寄住了它们 → 7436 位 impl-only cone-dead 寄存器 → FM unread_impl。
//
// 修法:每路**只寄存 golden 保留字段**到窄寄存器 wbd<N>_<field>(RegEnable,enable=
// wbInValid[N],无复位——与原整-struct 打拍时序、lane 映射、接口逐字一致),再由
// always_comb 把这些窄寄存器**重建**成 wb_exu_output_t 视图 wbDelayedBits[N](未消费
// 字段 = 组合常数 0,是 net 而非寄存器)。inst.svh 的 wbDelayedBits[N].<field> 访问不变,
// 消费字段的值/时序逐字不变,只删掉从不被读的死寄存字段。
//
// ★ 严格 golden-faithful:保留字段的 reset(bits 无复位)/enable(wbInValid[N])/lane
//   映射/位宽/取值逐字保留;仅删 golden 也不存的死字段。禁黑盒化/常量化整 struct。
// 本文件为机械派生(scripts/gen_ctrlblock.py 意图),字段清单见 inventory json。
// ============================================================================

  // ---- lane 0: 4 字段 / 200 位(golden 保留)----
  logic [7:0] wbd0_robIdx_value;
  logic [63:0] wbd0_debugInfo_enqRsTime;
  logic [63:0] wbd0_debugInfo_issueTime;
  logic [63:0] wbd0_debugInfo_selectTime;
  always_ff @(posedge clock) if (wbInValid[0]) begin
    wbd0_robIdx_value <= wbInBits[0].robIdx_value;
    wbd0_debugInfo_enqRsTime <= wbInBits[0].debugInfo_enqRsTime;
    wbd0_debugInfo_issueTime <= wbInBits[0].debugInfo_issueTime;
    wbd0_debugInfo_selectTime <= wbInBits[0].debugInfo_selectTime;
  end
  always_comb begin
    wbDelayedBits[0] = '{default:'0};
    wbDelayedBits[0].robIdx_value = wbd0_robIdx_value;
    wbDelayedBits[0].debugInfo_enqRsTime = wbd0_debugInfo_enqRsTime;
    wbDelayedBits[0].debugInfo_issueTime = wbd0_debugInfo_issueTime;
    wbDelayedBits[0].debugInfo_selectTime = wbd0_debugInfo_selectTime;
  end

  // ---- lane 1: 7 字段 / 203 位(golden 保留)----
  logic [7:0] wbd1_robIdx_value;
  logic [63:0] wbd1_debugInfo_enqRsTime;
  logic [63:0] wbd1_debugInfo_issueTime;
  logic [63:0] wbd1_debugInfo_selectTime;
  logic        wbd1_redirect_valid;
  logic        wbd1_redirect_bits_cfiUpdate_isMisPred;
  logic        wbd1_redirect_bits_cfiUpdate_taken;
  always_ff @(posedge clock) if (wbInValid[1]) begin
    wbd1_robIdx_value <= wbInBits[1].robIdx_value;
    wbd1_debugInfo_enqRsTime <= wbInBits[1].debugInfo_enqRsTime;
    wbd1_debugInfo_issueTime <= wbInBits[1].debugInfo_issueTime;
    wbd1_debugInfo_selectTime <= wbInBits[1].debugInfo_selectTime;
    wbd1_redirect_valid <= wbInBits[1].redirect_valid;
    wbd1_redirect_bits_cfiUpdate_isMisPred <= wbInBits[1].redirect_bits_cfiUpdate_isMisPred;
    wbd1_redirect_bits_cfiUpdate_taken <= wbInBits[1].redirect_bits_cfiUpdate_taken;
  end
  always_comb begin
    wbDelayedBits[1] = '{default:'0};
    wbDelayedBits[1].robIdx_value = wbd1_robIdx_value;
    wbDelayedBits[1].debugInfo_enqRsTime = wbd1_debugInfo_enqRsTime;
    wbDelayedBits[1].debugInfo_issueTime = wbd1_debugInfo_issueTime;
    wbDelayedBits[1].debugInfo_selectTime = wbd1_debugInfo_selectTime;
    wbDelayedBits[1].redirect_valid = wbd1_redirect_valid;
    wbDelayedBits[1].redirect_bits_cfiUpdate_isMisPred = wbd1_redirect_bits_cfiUpdate_isMisPred;
    wbDelayedBits[1].redirect_bits_cfiUpdate_taken = wbd1_redirect_bits_cfiUpdate_taken;
  end

  // ---- lane 2: 4 字段 / 200 位(golden 保留)----
  logic [7:0] wbd2_robIdx_value;
  logic [63:0] wbd2_debugInfo_enqRsTime;
  logic [63:0] wbd2_debugInfo_issueTime;
  logic [63:0] wbd2_debugInfo_selectTime;
  always_ff @(posedge clock) if (wbInValid[2]) begin
    wbd2_robIdx_value <= wbInBits[2].robIdx_value;
    wbd2_debugInfo_enqRsTime <= wbInBits[2].debugInfo_enqRsTime;
    wbd2_debugInfo_issueTime <= wbInBits[2].debugInfo_issueTime;
    wbd2_debugInfo_selectTime <= wbInBits[2].debugInfo_selectTime;
  end
  always_comb begin
    wbDelayedBits[2] = '{default:'0};
    wbDelayedBits[2].robIdx_value = wbd2_robIdx_value;
    wbDelayedBits[2].debugInfo_enqRsTime = wbd2_debugInfo_enqRsTime;
    wbDelayedBits[2].debugInfo_issueTime = wbd2_debugInfo_issueTime;
    wbDelayedBits[2].debugInfo_selectTime = wbd2_debugInfo_selectTime;
  end

  // ---- lane 3: 7 字段 / 203 位(golden 保留)----
  logic [7:0] wbd3_robIdx_value;
  logic [63:0] wbd3_debugInfo_enqRsTime;
  logic [63:0] wbd3_debugInfo_issueTime;
  logic [63:0] wbd3_debugInfo_selectTime;
  logic        wbd3_redirect_valid;
  logic        wbd3_redirect_bits_cfiUpdate_isMisPred;
  logic        wbd3_redirect_bits_cfiUpdate_taken;
  always_ff @(posedge clock) if (wbInValid[3]) begin
    wbd3_robIdx_value <= wbInBits[3].robIdx_value;
    wbd3_debugInfo_enqRsTime <= wbInBits[3].debugInfo_enqRsTime;
    wbd3_debugInfo_issueTime <= wbInBits[3].debugInfo_issueTime;
    wbd3_debugInfo_selectTime <= wbInBits[3].debugInfo_selectTime;
    wbd3_redirect_valid <= wbInBits[3].redirect_valid;
    wbd3_redirect_bits_cfiUpdate_isMisPred <= wbInBits[3].redirect_bits_cfiUpdate_isMisPred;
    wbd3_redirect_bits_cfiUpdate_taken <= wbInBits[3].redirect_bits_cfiUpdate_taken;
  end
  always_comb begin
    wbDelayedBits[3] = '{default:'0};
    wbDelayedBits[3].robIdx_value = wbd3_robIdx_value;
    wbDelayedBits[3].debugInfo_enqRsTime = wbd3_debugInfo_enqRsTime;
    wbDelayedBits[3].debugInfo_issueTime = wbd3_debugInfo_issueTime;
    wbDelayedBits[3].debugInfo_selectTime = wbd3_debugInfo_selectTime;
    wbDelayedBits[3].redirect_valid = wbd3_redirect_valid;
    wbDelayedBits[3].redirect_bits_cfiUpdate_isMisPred = wbd3_redirect_bits_cfiUpdate_isMisPred;
    wbDelayedBits[3].redirect_bits_cfiUpdate_taken = wbd3_redirect_bits_cfiUpdate_taken;
  end

  // ---- lane 4: 4 字段 / 200 位(golden 保留)----
  logic [7:0] wbd4_robIdx_value;
  logic [63:0] wbd4_debugInfo_enqRsTime;
  logic [63:0] wbd4_debugInfo_issueTime;
  logic [63:0] wbd4_debugInfo_selectTime;
  always_ff @(posedge clock) if (wbInValid[4]) begin
    wbd4_robIdx_value <= wbInBits[4].robIdx_value;
    wbd4_debugInfo_enqRsTime <= wbInBits[4].debugInfo_enqRsTime;
    wbd4_debugInfo_issueTime <= wbInBits[4].debugInfo_issueTime;
    wbd4_debugInfo_selectTime <= wbInBits[4].debugInfo_selectTime;
  end
  always_comb begin
    wbDelayedBits[4] = '{default:'0};
    wbDelayedBits[4].robIdx_value = wbd4_robIdx_value;
    wbDelayedBits[4].debugInfo_enqRsTime = wbd4_debugInfo_enqRsTime;
    wbDelayedBits[4].debugInfo_issueTime = wbd4_debugInfo_issueTime;
    wbDelayedBits[4].debugInfo_selectTime = wbd4_debugInfo_selectTime;
  end

  // ---- lane 5: 9 字段 / 209 位(golden 保留)----
  logic [7:0] wbd5_robIdx_value;
  logic [4:0] wbd5_fflags;
  logic        wbd5_wflags;
  logic [63:0] wbd5_debugInfo_enqRsTime;
  logic [63:0] wbd5_debugInfo_issueTime;
  logic [63:0] wbd5_debugInfo_selectTime;
  logic        wbd5_redirect_valid;
  logic        wbd5_redirect_bits_cfiUpdate_isMisPred;
  logic        wbd5_redirect_bits_cfiUpdate_taken;
  always_ff @(posedge clock) if (wbInValid[5]) begin
    wbd5_robIdx_value <= wbInBits[5].robIdx_value;
    wbd5_fflags <= wbInBits[5].fflags;
    wbd5_wflags <= wbInBits[5].wflags;
    wbd5_debugInfo_enqRsTime <= wbInBits[5].debugInfo_enqRsTime;
    wbd5_debugInfo_issueTime <= wbInBits[5].debugInfo_issueTime;
    wbd5_debugInfo_selectTime <= wbInBits[5].debugInfo_selectTime;
    wbd5_redirect_valid <= wbInBits[5].redirect_valid;
    wbd5_redirect_bits_cfiUpdate_isMisPred <= wbInBits[5].redirect_bits_cfiUpdate_isMisPred;
    wbd5_redirect_bits_cfiUpdate_taken <= wbInBits[5].redirect_bits_cfiUpdate_taken;
  end
  always_comb begin
    wbDelayedBits[5] = '{default:'0};
    wbDelayedBits[5].robIdx_value = wbd5_robIdx_value;
    wbDelayedBits[5].fflags = wbd5_fflags;
    wbDelayedBits[5].wflags = wbd5_wflags;
    wbDelayedBits[5].debugInfo_enqRsTime = wbd5_debugInfo_enqRsTime;
    wbDelayedBits[5].debugInfo_issueTime = wbd5_debugInfo_issueTime;
    wbDelayedBits[5].debugInfo_selectTime = wbd5_debugInfo_selectTime;
    wbDelayedBits[5].redirect_valid = wbd5_redirect_valid;
    wbDelayedBits[5].redirect_bits_cfiUpdate_isMisPred = wbd5_redirect_bits_cfiUpdate_isMisPred;
    wbDelayedBits[5].redirect_bits_cfiUpdate_taken = wbd5_redirect_bits_cfiUpdate_taken;
  end

  // ---- lane 6: 4 字段 / 200 位(golden 保留)----
  logic [7:0] wbd6_robIdx_value;
  logic [63:0] wbd6_debugInfo_enqRsTime;
  logic [63:0] wbd6_debugInfo_issueTime;
  logic [63:0] wbd6_debugInfo_selectTime;
  always_ff @(posedge clock) if (wbInValid[6]) begin
    wbd6_robIdx_value <= wbInBits[6].robIdx_value;
    wbd6_debugInfo_enqRsTime <= wbInBits[6].debugInfo_enqRsTime;
    wbd6_debugInfo_issueTime <= wbInBits[6].debugInfo_issueTime;
    wbd6_debugInfo_selectTime <= wbInBits[6].debugInfo_selectTime;
  end
  always_comb begin
    wbDelayedBits[6] = '{default:'0};
    wbDelayedBits[6].robIdx_value = wbd6_robIdx_value;
    wbDelayedBits[6].debugInfo_enqRsTime = wbd6_debugInfo_enqRsTime;
    wbDelayedBits[6].debugInfo_issueTime = wbd6_debugInfo_issueTime;
    wbDelayedBits[6].debugInfo_selectTime = wbd6_debugInfo_selectTime;
  end

  // ---- lane 7: 10 字段 / 212 位(golden 保留)----
  logic        wbd7_robIdx_flag;
  logic [7:0] wbd7_robIdx_value;
  logic        wbd7_flushPipe;
  logic        wbd7_debug_isPerfCnt;
  logic [63:0] wbd7_debugInfo_enqRsTime;
  logic [63:0] wbd7_debugInfo_issueTime;
  logic [63:0] wbd7_debugInfo_selectTime;
  logic        wbd7_redirect_valid;
  logic        wbd7_redirect_bits_cfiUpdate_isMisPred;
  logic        wbd7_exceptionVec_2;
  logic        wbd7_exceptionVec_3;
  logic        wbd7_exceptionVec_8;
  logic        wbd7_exceptionVec_9;
  logic        wbd7_exceptionVec_10;
  logic        wbd7_exceptionVec_11;
  logic        wbd7_exceptionVec_22;
  always_ff @(posedge clock) if (wbInValid[7]) begin
    wbd7_robIdx_flag <= wbInBits[7].robIdx_flag;
    wbd7_robIdx_value <= wbInBits[7].robIdx_value;
    wbd7_flushPipe <= wbInBits[7].flushPipe;
    wbd7_debug_isPerfCnt <= wbInBits[7].debug_isPerfCnt;
    wbd7_debugInfo_enqRsTime <= wbInBits[7].debugInfo_enqRsTime;
    wbd7_debugInfo_issueTime <= wbInBits[7].debugInfo_issueTime;
    wbd7_debugInfo_selectTime <= wbInBits[7].debugInfo_selectTime;
    wbd7_redirect_valid <= wbInBits[7].redirect_valid;
    wbd7_redirect_bits_cfiUpdate_isMisPred <= wbInBits[7].redirect_bits_cfiUpdate_isMisPred;
    wbd7_exceptionVec_2 <= wbInBits[7].exceptionVec[2];
    wbd7_exceptionVec_3 <= wbInBits[7].exceptionVec[3];
    wbd7_exceptionVec_8 <= wbInBits[7].exceptionVec[8];
    wbd7_exceptionVec_9 <= wbInBits[7].exceptionVec[9];
    wbd7_exceptionVec_10 <= wbInBits[7].exceptionVec[10];
    wbd7_exceptionVec_11 <= wbInBits[7].exceptionVec[11];
    wbd7_exceptionVec_22 <= wbInBits[7].exceptionVec[22];
  end
  always_comb begin
    wbDelayedBits[7] = '{default:'0};
    wbDelayedBits[7].robIdx_flag = wbd7_robIdx_flag;
    wbDelayedBits[7].robIdx_value = wbd7_robIdx_value;
    wbDelayedBits[7].flushPipe = wbd7_flushPipe;
    wbDelayedBits[7].debug_isPerfCnt = wbd7_debug_isPerfCnt;
    wbDelayedBits[7].debugInfo_enqRsTime = wbd7_debugInfo_enqRsTime;
    wbDelayedBits[7].debugInfo_issueTime = wbd7_debugInfo_issueTime;
    wbDelayedBits[7].debugInfo_selectTime = wbd7_debugInfo_selectTime;
    wbDelayedBits[7].redirect_valid = wbd7_redirect_valid;
    wbDelayedBits[7].redirect_bits_cfiUpdate_isMisPred = wbd7_redirect_bits_cfiUpdate_isMisPred;
    wbDelayedBits[7].exceptionVec[2] = wbd7_exceptionVec_2;
    wbDelayedBits[7].exceptionVec[3] = wbd7_exceptionVec_3;
    wbDelayedBits[7].exceptionVec[8] = wbd7_exceptionVec_8;
    wbDelayedBits[7].exceptionVec[9] = wbd7_exceptionVec_9;
    wbDelayedBits[7].exceptionVec[10] = wbd7_exceptionVec_10;
    wbDelayedBits[7].exceptionVec[11] = wbd7_exceptionVec_11;
    wbDelayedBits[7].exceptionVec[22] = wbd7_exceptionVec_22;
  end

  // ---- lane 8: 6 字段 / 206 位(golden 保留)----
  logic [7:0] wbd8_robIdx_value;
  logic [4:0] wbd8_fflags;
  logic        wbd8_wflags;
  logic [63:0] wbd8_debugInfo_enqRsTime;
  logic [63:0] wbd8_debugInfo_issueTime;
  logic [63:0] wbd8_debugInfo_selectTime;
  always_ff @(posedge clock) if (wbInValid[8]) begin
    wbd8_robIdx_value <= wbInBits[8].robIdx_value;
    wbd8_fflags <= wbInBits[8].fflags;
    wbd8_wflags <= wbInBits[8].wflags;
    wbd8_debugInfo_enqRsTime <= wbInBits[8].debugInfo_enqRsTime;
    wbd8_debugInfo_issueTime <= wbInBits[8].debugInfo_issueTime;
    wbd8_debugInfo_selectTime <= wbInBits[8].debugInfo_selectTime;
  end
  always_comb begin
    wbDelayedBits[8] = '{default:'0};
    wbDelayedBits[8].robIdx_value = wbd8_robIdx_value;
    wbDelayedBits[8].fflags = wbd8_fflags;
    wbDelayedBits[8].wflags = wbd8_wflags;
    wbDelayedBits[8].debugInfo_enqRsTime = wbd8_debugInfo_enqRsTime;
    wbDelayedBits[8].debugInfo_issueTime = wbd8_debugInfo_issueTime;
    wbDelayedBits[8].debugInfo_selectTime = wbd8_debugInfo_selectTime;
  end

  // ---- lane 9: 6 字段 / 206 位(golden 保留)----
  logic [7:0] wbd9_robIdx_value;
  logic [4:0] wbd9_fflags;
  logic        wbd9_wflags;
  logic [63:0] wbd9_debugInfo_enqRsTime;
  logic [63:0] wbd9_debugInfo_issueTime;
  logic [63:0] wbd9_debugInfo_selectTime;
  always_ff @(posedge clock) if (wbInValid[9]) begin
    wbd9_robIdx_value <= wbInBits[9].robIdx_value;
    wbd9_fflags <= wbInBits[9].fflags;
    wbd9_wflags <= wbInBits[9].wflags;
    wbd9_debugInfo_enqRsTime <= wbInBits[9].debugInfo_enqRsTime;
    wbd9_debugInfo_issueTime <= wbInBits[9].debugInfo_issueTime;
    wbd9_debugInfo_selectTime <= wbInBits[9].debugInfo_selectTime;
  end
  always_comb begin
    wbDelayedBits[9] = '{default:'0};
    wbDelayedBits[9].robIdx_value = wbd9_robIdx_value;
    wbDelayedBits[9].fflags = wbd9_fflags;
    wbDelayedBits[9].wflags = wbd9_wflags;
    wbDelayedBits[9].debugInfo_enqRsTime = wbd9_debugInfo_enqRsTime;
    wbDelayedBits[9].debugInfo_issueTime = wbd9_debugInfo_issueTime;
    wbDelayedBits[9].debugInfo_selectTime = wbd9_debugInfo_selectTime;
  end

  // ---- lane 10: 6 字段 / 206 位(golden 保留)----
  logic [7:0] wbd10_robIdx_value;
  logic [4:0] wbd10_fflags;
  logic        wbd10_wflags;
  logic [63:0] wbd10_debugInfo_enqRsTime;
  logic [63:0] wbd10_debugInfo_issueTime;
  logic [63:0] wbd10_debugInfo_selectTime;
  always_ff @(posedge clock) if (wbInValid[10]) begin
    wbd10_robIdx_value <= wbInBits[10].robIdx_value;
    wbd10_fflags <= wbInBits[10].fflags;
    wbd10_wflags <= wbInBits[10].wflags;
    wbd10_debugInfo_enqRsTime <= wbInBits[10].debugInfo_enqRsTime;
    wbd10_debugInfo_issueTime <= wbInBits[10].debugInfo_issueTime;
    wbd10_debugInfo_selectTime <= wbInBits[10].debugInfo_selectTime;
  end
  always_comb begin
    wbDelayedBits[10] = '{default:'0};
    wbDelayedBits[10].robIdx_value = wbd10_robIdx_value;
    wbDelayedBits[10].fflags = wbd10_fflags;
    wbDelayedBits[10].wflags = wbd10_wflags;
    wbDelayedBits[10].debugInfo_enqRsTime = wbd10_debugInfo_enqRsTime;
    wbDelayedBits[10].debugInfo_issueTime = wbd10_debugInfo_issueTime;
    wbDelayedBits[10].debugInfo_selectTime = wbd10_debugInfo_selectTime;
  end

  // ---- lane 11: 6 字段 / 206 位(golden 保留)----
  logic [7:0] wbd11_robIdx_value;
  logic [4:0] wbd11_fflags;
  logic        wbd11_wflags;
  logic [63:0] wbd11_debugInfo_enqRsTime;
  logic [63:0] wbd11_debugInfo_issueTime;
  logic [63:0] wbd11_debugInfo_selectTime;
  always_ff @(posedge clock) if (wbInValid[11]) begin
    wbd11_robIdx_value <= wbInBits[11].robIdx_value;
    wbd11_fflags <= wbInBits[11].fflags;
    wbd11_wflags <= wbInBits[11].wflags;
    wbd11_debugInfo_enqRsTime <= wbInBits[11].debugInfo_enqRsTime;
    wbd11_debugInfo_issueTime <= wbInBits[11].debugInfo_issueTime;
    wbd11_debugInfo_selectTime <= wbInBits[11].debugInfo_selectTime;
  end
  always_comb begin
    wbDelayedBits[11] = '{default:'0};
    wbDelayedBits[11].robIdx_value = wbd11_robIdx_value;
    wbDelayedBits[11].fflags = wbd11_fflags;
    wbDelayedBits[11].wflags = wbd11_wflags;
    wbDelayedBits[11].debugInfo_enqRsTime = wbd11_debugInfo_enqRsTime;
    wbDelayedBits[11].debugInfo_issueTime = wbd11_debugInfo_issueTime;
    wbDelayedBits[11].debugInfo_selectTime = wbd11_debugInfo_selectTime;
  end

  // ---- lane 12: 6 字段 / 206 位(golden 保留)----
  logic [7:0] wbd12_robIdx_value;
  logic [4:0] wbd12_fflags;
  logic        wbd12_wflags;
  logic [63:0] wbd12_debugInfo_enqRsTime;
  logic [63:0] wbd12_debugInfo_issueTime;
  logic [63:0] wbd12_debugInfo_selectTime;
  always_ff @(posedge clock) if (wbInValid[12]) begin
    wbd12_robIdx_value <= wbInBits[12].robIdx_value;
    wbd12_fflags <= wbInBits[12].fflags;
    wbd12_wflags <= wbInBits[12].wflags;
    wbd12_debugInfo_enqRsTime <= wbInBits[12].debugInfo_enqRsTime;
    wbd12_debugInfo_issueTime <= wbInBits[12].debugInfo_issueTime;
    wbd12_debugInfo_selectTime <= wbInBits[12].debugInfo_selectTime;
  end
  always_comb begin
    wbDelayedBits[12] = '{default:'0};
    wbDelayedBits[12].robIdx_value = wbd12_robIdx_value;
    wbDelayedBits[12].fflags = wbd12_fflags;
    wbDelayedBits[12].wflags = wbd12_wflags;
    wbDelayedBits[12].debugInfo_enqRsTime = wbd12_debugInfo_enqRsTime;
    wbDelayedBits[12].debugInfo_issueTime = wbd12_debugInfo_issueTime;
    wbDelayedBits[12].debugInfo_selectTime = wbd12_debugInfo_selectTime;
  end

  // ---- lane 13: 9 字段 / 209 位(golden 保留)----
  logic        wbd13_robIdx_flag;
  logic [7:0] wbd13_robIdx_value;
  logic [4:0] wbd13_fflags;
  logic        wbd13_wflags;
  logic        wbd13_vxsat;
  logic [63:0] wbd13_debugInfo_enqRsTime;
  logic [63:0] wbd13_debugInfo_issueTime;
  logic [63:0] wbd13_debugInfo_selectTime;
  logic        wbd13_exceptionVec_2;
  always_ff @(posedge clock) if (wbInValid[13]) begin
    wbd13_robIdx_flag <= wbInBits[13].robIdx_flag;
    wbd13_robIdx_value <= wbInBits[13].robIdx_value;
    wbd13_fflags <= wbInBits[13].fflags;
    wbd13_wflags <= wbInBits[13].wflags;
    wbd13_vxsat <= wbInBits[13].vxsat;
    wbd13_debugInfo_enqRsTime <= wbInBits[13].debugInfo_enqRsTime;
    wbd13_debugInfo_issueTime <= wbInBits[13].debugInfo_issueTime;
    wbd13_debugInfo_selectTime <= wbInBits[13].debugInfo_selectTime;
    wbd13_exceptionVec_2 <= wbInBits[13].exceptionVec[2];
  end
  always_comb begin
    wbDelayedBits[13] = '{default:'0};
    wbDelayedBits[13].robIdx_flag = wbd13_robIdx_flag;
    wbDelayedBits[13].robIdx_value = wbd13_robIdx_value;
    wbDelayedBits[13].fflags = wbd13_fflags;
    wbDelayedBits[13].wflags = wbd13_wflags;
    wbDelayedBits[13].vxsat = wbd13_vxsat;
    wbDelayedBits[13].debugInfo_enqRsTime = wbd13_debugInfo_enqRsTime;
    wbDelayedBits[13].debugInfo_issueTime = wbd13_debugInfo_issueTime;
    wbDelayedBits[13].debugInfo_selectTime = wbd13_debugInfo_selectTime;
    wbDelayedBits[13].exceptionVec[2] = wbd13_exceptionVec_2;
  end

  // ---- lane 14: 8 字段 / 208 位(golden 保留)----
  logic        wbd14_robIdx_flag;
  logic [7:0] wbd14_robIdx_value;
  logic [4:0] wbd14_fflags;
  logic        wbd14_wflags;
  logic [63:0] wbd14_debugInfo_enqRsTime;
  logic [63:0] wbd14_debugInfo_issueTime;
  logic [63:0] wbd14_debugInfo_selectTime;
  logic        wbd14_exceptionVec_2;
  always_ff @(posedge clock) if (wbInValid[14]) begin
    wbd14_robIdx_flag <= wbInBits[14].robIdx_flag;
    wbd14_robIdx_value <= wbInBits[14].robIdx_value;
    wbd14_fflags <= wbInBits[14].fflags;
    wbd14_wflags <= wbInBits[14].wflags;
    wbd14_debugInfo_enqRsTime <= wbInBits[14].debugInfo_enqRsTime;
    wbd14_debugInfo_issueTime <= wbInBits[14].debugInfo_issueTime;
    wbd14_debugInfo_selectTime <= wbInBits[14].debugInfo_selectTime;
    wbd14_exceptionVec_2 <= wbInBits[14].exceptionVec[2];
  end
  always_comb begin
    wbDelayedBits[14] = '{default:'0};
    wbDelayedBits[14].robIdx_flag = wbd14_robIdx_flag;
    wbDelayedBits[14].robIdx_value = wbd14_robIdx_value;
    wbDelayedBits[14].fflags = wbd14_fflags;
    wbDelayedBits[14].wflags = wbd14_wflags;
    wbDelayedBits[14].debugInfo_enqRsTime = wbd14_debugInfo_enqRsTime;
    wbDelayedBits[14].debugInfo_issueTime = wbd14_debugInfo_issueTime;
    wbDelayedBits[14].debugInfo_selectTime = wbd14_debugInfo_selectTime;
    wbDelayedBits[14].exceptionVec[2] = wbd14_exceptionVec_2;
  end

  // ---- lane 15: 8 字段 / 208 位(golden 保留)----
  logic        wbd15_robIdx_flag;
  logic [7:0] wbd15_robIdx_value;
  logic [4:0] wbd15_fflags;
  logic        wbd15_wflags;
  logic        wbd15_vxsat;
  logic [63:0] wbd15_debugInfo_enqRsTime;
  logic [63:0] wbd15_debugInfo_issueTime;
  logic [63:0] wbd15_debugInfo_selectTime;
  always_ff @(posedge clock) if (wbInValid[15]) begin
    wbd15_robIdx_flag <= wbInBits[15].robIdx_flag;
    wbd15_robIdx_value <= wbInBits[15].robIdx_value;
    wbd15_fflags <= wbInBits[15].fflags;
    wbd15_wflags <= wbInBits[15].wflags;
    wbd15_vxsat <= wbInBits[15].vxsat;
    wbd15_debugInfo_enqRsTime <= wbInBits[15].debugInfo_enqRsTime;
    wbd15_debugInfo_issueTime <= wbInBits[15].debugInfo_issueTime;
    wbd15_debugInfo_selectTime <= wbInBits[15].debugInfo_selectTime;
  end
  always_comb begin
    wbDelayedBits[15] = '{default:'0};
    wbDelayedBits[15].robIdx_flag = wbd15_robIdx_flag;
    wbDelayedBits[15].robIdx_value = wbd15_robIdx_value;
    wbDelayedBits[15].fflags = wbd15_fflags;
    wbDelayedBits[15].wflags = wbd15_wflags;
    wbDelayedBits[15].vxsat = wbd15_vxsat;
    wbDelayedBits[15].debugInfo_enqRsTime = wbd15_debugInfo_enqRsTime;
    wbDelayedBits[15].debugInfo_issueTime = wbd15_debugInfo_issueTime;
    wbDelayedBits[15].debugInfo_selectTime = wbd15_debugInfo_selectTime;
  end

  // ---- lane 16: 7 字段 / 207 位(golden 保留)----
  logic        wbd16_robIdx_flag;
  logic [7:0] wbd16_robIdx_value;
  logic [4:0] wbd16_fflags;
  logic        wbd16_wflags;
  logic [63:0] wbd16_debugInfo_enqRsTime;
  logic [63:0] wbd16_debugInfo_issueTime;
  logic [63:0] wbd16_debugInfo_selectTime;
  always_ff @(posedge clock) if (wbInValid[16]) begin
    wbd16_robIdx_flag <= wbInBits[16].robIdx_flag;
    wbd16_robIdx_value <= wbInBits[16].robIdx_value;
    wbd16_fflags <= wbInBits[16].fflags;
    wbd16_wflags <= wbInBits[16].wflags;
    wbd16_debugInfo_enqRsTime <= wbInBits[16].debugInfo_enqRsTime;
    wbd16_debugInfo_issueTime <= wbInBits[16].debugInfo_issueTime;
    wbd16_debugInfo_selectTime <= wbInBits[16].debugInfo_selectTime;
  end
  always_comb begin
    wbDelayedBits[16] = '{default:'0};
    wbDelayedBits[16].robIdx_flag = wbd16_robIdx_flag;
    wbDelayedBits[16].robIdx_value = wbd16_robIdx_value;
    wbDelayedBits[16].fflags = wbd16_fflags;
    wbDelayedBits[16].wflags = wbd16_wflags;
    wbDelayedBits[16].debugInfo_enqRsTime = wbd16_debugInfo_enqRsTime;
    wbDelayedBits[16].debugInfo_issueTime = wbd16_debugInfo_issueTime;
    wbDelayedBits[16].debugInfo_selectTime = wbd16_debugInfo_selectTime;
  end

  // ---- lane 17: 7 字段 / 207 位(golden 保留)----
  logic        wbd17_robIdx_flag;
  logic [7:0] wbd17_robIdx_value;
  logic [4:0] wbd17_fflags;
  logic        wbd17_wflags;
  logic [63:0] wbd17_debugInfo_enqRsTime;
  logic [63:0] wbd17_debugInfo_issueTime;
  logic [63:0] wbd17_debugInfo_selectTime;
  always_ff @(posedge clock) if (wbInValid[17]) begin
    wbd17_robIdx_flag <= wbInBits[17].robIdx_flag;
    wbd17_robIdx_value <= wbInBits[17].robIdx_value;
    wbd17_fflags <= wbInBits[17].fflags;
    wbd17_wflags <= wbInBits[17].wflags;
    wbd17_debugInfo_enqRsTime <= wbInBits[17].debugInfo_enqRsTime;
    wbd17_debugInfo_issueTime <= wbInBits[17].debugInfo_issueTime;
    wbd17_debugInfo_selectTime <= wbInBits[17].debugInfo_selectTime;
  end
  always_comb begin
    wbDelayedBits[17] = '{default:'0};
    wbDelayedBits[17].robIdx_flag = wbd17_robIdx_flag;
    wbDelayedBits[17].robIdx_value = wbd17_robIdx_value;
    wbDelayedBits[17].fflags = wbd17_fflags;
    wbDelayedBits[17].wflags = wbd17_wflags;
    wbDelayedBits[17].debugInfo_enqRsTime = wbd17_debugInfo_enqRsTime;
    wbDelayedBits[17].debugInfo_issueTime = wbd17_debugInfo_issueTime;
    wbDelayedBits[17].debugInfo_selectTime = wbd17_debugInfo_selectTime;
  end

  // ---- lane 18: 11 字段 / 233 位(golden 保留)----
  logic        wbd18_robIdx_flag;
  logic [7:0] wbd18_robIdx_value;
  logic        wbd18_flushPipe;
  logic [3:0] wbd18_trigger;
  logic        wbd18_debug_isMMIO;
  logic        wbd18_debug_isNCIO;
  logic        wbd18_debug_isPerfCnt;
  logic [63:0] wbd18_debugInfo_enqRsTime;
  logic [63:0] wbd18_debugInfo_issueTime;
  logic [63:0] wbd18_debugInfo_selectTime;
  logic        wbd18_exceptionVec_0;
  logic        wbd18_exceptionVec_1;
  logic        wbd18_exceptionVec_2;
  logic        wbd18_exceptionVec_3;
  logic        wbd18_exceptionVec_4;
  logic        wbd18_exceptionVec_5;
  logic        wbd18_exceptionVec_6;
  logic        wbd18_exceptionVec_7;
  logic        wbd18_exceptionVec_8;
  logic        wbd18_exceptionVec_9;
  logic        wbd18_exceptionVec_10;
  logic        wbd18_exceptionVec_11;
  logic        wbd18_exceptionVec_12;
  logic        wbd18_exceptionVec_13;
  logic        wbd18_exceptionVec_14;
  logic        wbd18_exceptionVec_15;
  logic        wbd18_exceptionVec_16;
  logic        wbd18_exceptionVec_17;
  logic        wbd18_exceptionVec_18;
  logic        wbd18_exceptionVec_19;
  logic        wbd18_exceptionVec_20;
  logic        wbd18_exceptionVec_21;
  logic        wbd18_exceptionVec_22;
  logic        wbd18_exceptionVec_23;
  always_ff @(posedge clock) if (wbInValid[18]) begin
    wbd18_robIdx_flag <= wbInBits[18].robIdx_flag;
    wbd18_robIdx_value <= wbInBits[18].robIdx_value;
    wbd18_flushPipe <= wbInBits[18].flushPipe;
    wbd18_trigger <= wbInBits[18].trigger;
    wbd18_debug_isMMIO <= wbInBits[18].debug_isMMIO;
    wbd18_debug_isNCIO <= wbInBits[18].debug_isNCIO;
    wbd18_debugInfo_enqRsTime <= wbInBits[18].debugInfo_enqRsTime;
    wbd18_debugInfo_issueTime <= wbInBits[18].debugInfo_issueTime;
    wbd18_debugInfo_selectTime <= wbInBits[18].debugInfo_selectTime;
    wbd18_exceptionVec_0 <= wbInBits[18].exceptionVec[0];
    wbd18_exceptionVec_1 <= wbInBits[18].exceptionVec[1];
    wbd18_exceptionVec_2 <= wbInBits[18].exceptionVec[2];
    wbd18_exceptionVec_3 <= wbInBits[18].exceptionVec[3];
    wbd18_exceptionVec_4 <= wbInBits[18].exceptionVec[4];
    wbd18_exceptionVec_5 <= wbInBits[18].exceptionVec[5];
    wbd18_exceptionVec_6 <= wbInBits[18].exceptionVec[6];
    wbd18_exceptionVec_7 <= wbInBits[18].exceptionVec[7];
    wbd18_exceptionVec_8 <= wbInBits[18].exceptionVec[8];
    wbd18_exceptionVec_9 <= wbInBits[18].exceptionVec[9];
    wbd18_exceptionVec_10 <= wbInBits[18].exceptionVec[10];
    wbd18_exceptionVec_11 <= wbInBits[18].exceptionVec[11];
    wbd18_exceptionVec_12 <= wbInBits[18].exceptionVec[12];
    wbd18_exceptionVec_13 <= wbInBits[18].exceptionVec[13];
    wbd18_exceptionVec_14 <= wbInBits[18].exceptionVec[14];
    wbd18_exceptionVec_15 <= wbInBits[18].exceptionVec[15];
    wbd18_exceptionVec_16 <= wbInBits[18].exceptionVec[16];
    wbd18_exceptionVec_17 <= wbInBits[18].exceptionVec[17];
    wbd18_exceptionVec_18 <= wbInBits[18].exceptionVec[18];
    wbd18_exceptionVec_19 <= wbInBits[18].exceptionVec[19];
    wbd18_exceptionVec_20 <= wbInBits[18].exceptionVec[20];
    wbd18_exceptionVec_21 <= wbInBits[18].exceptionVec[21];
    wbd18_exceptionVec_22 <= wbInBits[18].exceptionVec[22];
    wbd18_exceptionVec_23 <= wbInBits[18].exceptionVec[23];
  end
  always_comb begin
    wbDelayedBits[18] = '{default:'0};
    wbDelayedBits[18].robIdx_flag = wbd18_robIdx_flag;
    wbDelayedBits[18].robIdx_value = wbd18_robIdx_value;
    wbDelayedBits[18].flushPipe = wbd18_flushPipe;
    wbDelayedBits[18].trigger = wbd18_trigger;
    wbDelayedBits[18].debug_isMMIO = wbd18_debug_isMMIO;
    wbDelayedBits[18].debug_isNCIO = wbd18_debug_isNCIO;
    wbDelayedBits[18].debug_isPerfCnt = wbd18_debug_isPerfCnt;
    wbDelayedBits[18].debugInfo_enqRsTime = wbd18_debugInfo_enqRsTime;
    wbDelayedBits[18].debugInfo_issueTime = wbd18_debugInfo_issueTime;
    wbDelayedBits[18].debugInfo_selectTime = wbd18_debugInfo_selectTime;
    wbDelayedBits[18].exceptionVec[0] = wbd18_exceptionVec_0;
    wbDelayedBits[18].exceptionVec[1] = wbd18_exceptionVec_1;
    wbDelayedBits[18].exceptionVec[2] = wbd18_exceptionVec_2;
    wbDelayedBits[18].exceptionVec[3] = wbd18_exceptionVec_3;
    wbDelayedBits[18].exceptionVec[4] = wbd18_exceptionVec_4;
    wbDelayedBits[18].exceptionVec[5] = wbd18_exceptionVec_5;
    wbDelayedBits[18].exceptionVec[6] = wbd18_exceptionVec_6;
    wbDelayedBits[18].exceptionVec[7] = wbd18_exceptionVec_7;
    wbDelayedBits[18].exceptionVec[8] = wbd18_exceptionVec_8;
    wbDelayedBits[18].exceptionVec[9] = wbd18_exceptionVec_9;
    wbDelayedBits[18].exceptionVec[10] = wbd18_exceptionVec_10;
    wbDelayedBits[18].exceptionVec[11] = wbd18_exceptionVec_11;
    wbDelayedBits[18].exceptionVec[12] = wbd18_exceptionVec_12;
    wbDelayedBits[18].exceptionVec[13] = wbd18_exceptionVec_13;
    wbDelayedBits[18].exceptionVec[14] = wbd18_exceptionVec_14;
    wbDelayedBits[18].exceptionVec[15] = wbd18_exceptionVec_15;
    wbDelayedBits[18].exceptionVec[16] = wbd18_exceptionVec_16;
    wbDelayedBits[18].exceptionVec[17] = wbd18_exceptionVec_17;
    wbDelayedBits[18].exceptionVec[18] = wbd18_exceptionVec_18;
    wbDelayedBits[18].exceptionVec[19] = wbd18_exceptionVec_19;
    wbDelayedBits[18].exceptionVec[20] = wbd18_exceptionVec_20;
    wbDelayedBits[18].exceptionVec[21] = wbd18_exceptionVec_21;
    wbDelayedBits[18].exceptionVec[22] = wbd18_exceptionVec_22;
    wbDelayedBits[18].exceptionVec[23] = wbd18_exceptionVec_23;
  end

  // ---- lane 19: 9 字段 / 213 位(golden 保留)----
  logic        wbd19_robIdx_flag;
  logic [7:0] wbd19_robIdx_value;
  logic [3:0] wbd19_trigger;
  logic        wbd19_debug_isMMIO;
  logic        wbd19_debug_isNCIO;
  logic [63:0] wbd19_debugInfo_enqRsTime;
  logic [63:0] wbd19_debugInfo_issueTime;
  logic [63:0] wbd19_debugInfo_selectTime;
  logic        wbd19_exceptionVec_3;
  logic        wbd19_exceptionVec_6;
  logic        wbd19_exceptionVec_7;
  logic        wbd19_exceptionVec_15;
  logic        wbd19_exceptionVec_19;
  logic        wbd19_exceptionVec_23;
  always_ff @(posedge clock) if (wbInValid[19]) begin
    wbd19_robIdx_flag <= wbInBits[19].robIdx_flag;
    wbd19_robIdx_value <= wbInBits[19].robIdx_value;
    wbd19_trigger <= wbInBits[19].trigger;
    wbd19_debug_isMMIO <= wbInBits[19].debug_isMMIO;
    wbd19_debug_isNCIO <= wbInBits[19].debug_isNCIO;
    wbd19_debugInfo_enqRsTime <= wbInBits[19].debugInfo_enqRsTime;
    wbd19_debugInfo_issueTime <= wbInBits[19].debugInfo_issueTime;
    wbd19_debugInfo_selectTime <= wbInBits[19].debugInfo_selectTime;
    wbd19_exceptionVec_3 <= wbInBits[19].exceptionVec[3];
    wbd19_exceptionVec_6 <= wbInBits[19].exceptionVec[6];
    wbd19_exceptionVec_7 <= wbInBits[19].exceptionVec[7];
    wbd19_exceptionVec_15 <= wbInBits[19].exceptionVec[15];
    wbd19_exceptionVec_19 <= wbInBits[19].exceptionVec[19];
    wbd19_exceptionVec_23 <= wbInBits[19].exceptionVec[23];
  end
  always_comb begin
    wbDelayedBits[19] = '{default:'0};
    wbDelayedBits[19].robIdx_flag = wbd19_robIdx_flag;
    wbDelayedBits[19].robIdx_value = wbd19_robIdx_value;
    wbDelayedBits[19].trigger = wbd19_trigger;
    wbDelayedBits[19].debug_isMMIO = wbd19_debug_isMMIO;
    wbDelayedBits[19].debug_isNCIO = wbd19_debug_isNCIO;
    wbDelayedBits[19].debugInfo_enqRsTime = wbd19_debugInfo_enqRsTime;
    wbDelayedBits[19].debugInfo_issueTime = wbd19_debugInfo_issueTime;
    wbDelayedBits[19].debugInfo_selectTime = wbd19_debugInfo_selectTime;
    wbDelayedBits[19].exceptionVec[3] = wbd19_exceptionVec_3;
    wbDelayedBits[19].exceptionVec[6] = wbd19_exceptionVec_6;
    wbDelayedBits[19].exceptionVec[7] = wbd19_exceptionVec_7;
    wbDelayedBits[19].exceptionVec[15] = wbd19_exceptionVec_15;
    wbDelayedBits[19].exceptionVec[19] = wbd19_exceptionVec_19;
    wbDelayedBits[19].exceptionVec[23] = wbd19_exceptionVec_23;
  end

  // ---- lane 20: 12 字段 / 234 位(golden 保留)----
  logic        wbd20_robIdx_flag;
  logic [7:0] wbd20_robIdx_value;
  logic        wbd20_flushPipe;
  logic        wbd20_replay;
  logic [3:0] wbd20_trigger;
  logic        wbd20_debug_isMMIO;
  logic        wbd20_debug_isNCIO;
  logic        wbd20_debug_isPerfCnt;
  logic [63:0] wbd20_debugInfo_enqRsTime;
  logic [63:0] wbd20_debugInfo_issueTime;
  logic [63:0] wbd20_debugInfo_selectTime;
  logic        wbd20_exceptionVec_0;
  logic        wbd20_exceptionVec_1;
  logic        wbd20_exceptionVec_2;
  logic        wbd20_exceptionVec_3;
  logic        wbd20_exceptionVec_4;
  logic        wbd20_exceptionVec_5;
  logic        wbd20_exceptionVec_6;
  logic        wbd20_exceptionVec_7;
  logic        wbd20_exceptionVec_8;
  logic        wbd20_exceptionVec_9;
  logic        wbd20_exceptionVec_10;
  logic        wbd20_exceptionVec_11;
  logic        wbd20_exceptionVec_12;
  logic        wbd20_exceptionVec_13;
  logic        wbd20_exceptionVec_14;
  logic        wbd20_exceptionVec_15;
  logic        wbd20_exceptionVec_16;
  logic        wbd20_exceptionVec_17;
  logic        wbd20_exceptionVec_18;
  logic        wbd20_exceptionVec_19;
  logic        wbd20_exceptionVec_20;
  logic        wbd20_exceptionVec_21;
  logic        wbd20_exceptionVec_22;
  logic        wbd20_exceptionVec_23;
  always_ff @(posedge clock) if (wbInValid[20]) begin
    wbd20_robIdx_flag <= wbInBits[20].robIdx_flag;
    wbd20_robIdx_value <= wbInBits[20].robIdx_value;
    wbd20_flushPipe <= wbInBits[20].flushPipe;
    wbd20_replay <= wbInBits[20].replay;
    wbd20_trigger <= wbInBits[20].trigger;
    wbd20_debug_isMMIO <= wbInBits[20].debug_isMMIO;
    wbd20_debug_isNCIO <= wbInBits[20].debug_isNCIO;
    wbd20_debug_isPerfCnt <= wbInBits[20].debug_isPerfCnt;
    wbd20_debugInfo_enqRsTime <= wbInBits[20].debugInfo_enqRsTime;
    wbd20_debugInfo_issueTime <= wbInBits[20].debugInfo_issueTime;
    wbd20_debugInfo_selectTime <= wbInBits[20].debugInfo_selectTime;
    wbd20_exceptionVec_3 <= wbInBits[20].exceptionVec[3];
    wbd20_exceptionVec_4 <= wbInBits[20].exceptionVec[4];
    wbd20_exceptionVec_5 <= wbInBits[20].exceptionVec[5];
    wbd20_exceptionVec_6 <= wbInBits[20].exceptionVec[6];
    wbd20_exceptionVec_7 <= wbInBits[20].exceptionVec[7];
    wbd20_exceptionVec_13 <= wbInBits[20].exceptionVec[13];
    wbd20_exceptionVec_15 <= wbInBits[20].exceptionVec[15];
    wbd20_exceptionVec_19 <= wbInBits[20].exceptionVec[19];
    wbd20_exceptionVec_21 <= wbInBits[20].exceptionVec[21];
    wbd20_exceptionVec_23 <= wbInBits[20].exceptionVec[23];
  end
  always_comb begin
    wbDelayedBits[20] = '{default:'0};
    wbDelayedBits[20].robIdx_flag = wbd20_robIdx_flag;
    wbDelayedBits[20].robIdx_value = wbd20_robIdx_value;
    wbDelayedBits[20].flushPipe = wbd20_flushPipe;
    wbDelayedBits[20].replay = wbd20_replay;
    wbDelayedBits[20].trigger = wbd20_trigger;
    wbDelayedBits[20].debug_isMMIO = wbd20_debug_isMMIO;
    wbDelayedBits[20].debug_isNCIO = wbd20_debug_isNCIO;
    wbDelayedBits[20].debug_isPerfCnt = wbd20_debug_isPerfCnt;
    wbDelayedBits[20].debugInfo_enqRsTime = wbd20_debugInfo_enqRsTime;
    wbDelayedBits[20].debugInfo_issueTime = wbd20_debugInfo_issueTime;
    wbDelayedBits[20].debugInfo_selectTime = wbd20_debugInfo_selectTime;
    wbDelayedBits[20].exceptionVec[0] = wbd20_exceptionVec_0;
    wbDelayedBits[20].exceptionVec[1] = wbd20_exceptionVec_1;
    wbDelayedBits[20].exceptionVec[2] = wbd20_exceptionVec_2;
    wbDelayedBits[20].exceptionVec[3] = wbd20_exceptionVec_3;
    wbDelayedBits[20].exceptionVec[4] = wbd20_exceptionVec_4;
    wbDelayedBits[20].exceptionVec[5] = wbd20_exceptionVec_5;
    wbDelayedBits[20].exceptionVec[6] = wbd20_exceptionVec_6;
    wbDelayedBits[20].exceptionVec[7] = wbd20_exceptionVec_7;
    wbDelayedBits[20].exceptionVec[8] = wbd20_exceptionVec_8;
    wbDelayedBits[20].exceptionVec[9] = wbd20_exceptionVec_9;
    wbDelayedBits[20].exceptionVec[10] = wbd20_exceptionVec_10;
    wbDelayedBits[20].exceptionVec[11] = wbd20_exceptionVec_11;
    wbDelayedBits[20].exceptionVec[12] = wbd20_exceptionVec_12;
    wbDelayedBits[20].exceptionVec[13] = wbd20_exceptionVec_13;
    wbDelayedBits[20].exceptionVec[14] = wbd20_exceptionVec_14;
    wbDelayedBits[20].exceptionVec[15] = wbd20_exceptionVec_15;
    wbDelayedBits[20].exceptionVec[16] = wbd20_exceptionVec_16;
    wbDelayedBits[20].exceptionVec[17] = wbd20_exceptionVec_17;
    wbDelayedBits[20].exceptionVec[18] = wbd20_exceptionVec_18;
    wbDelayedBits[20].exceptionVec[19] = wbd20_exceptionVec_19;
    wbDelayedBits[20].exceptionVec[20] = wbd20_exceptionVec_20;
    wbDelayedBits[20].exceptionVec[21] = wbd20_exceptionVec_21;
    wbDelayedBits[20].exceptionVec[22] = wbd20_exceptionVec_22;
    wbDelayedBits[20].exceptionVec[23] = wbd20_exceptionVec_23;
  end

  // ---- lane 21: 12 字段 / 216 位(golden 保留)----
  logic        wbd21_robIdx_flag;
  logic [7:0] wbd21_robIdx_value;
  logic        wbd21_flushPipe;
  logic        wbd21_replay;
  logic [3:0] wbd21_trigger;
  logic        wbd21_debug_isMMIO;
  logic        wbd21_debug_isNCIO;
  logic        wbd21_debug_isPerfCnt;
  logic [63:0] wbd21_debugInfo_enqRsTime;
  logic [63:0] wbd21_debugInfo_issueTime;
  logic [63:0] wbd21_debugInfo_selectTime;
  logic        wbd21_exceptionVec_3;
  logic        wbd21_exceptionVec_4;
  logic        wbd21_exceptionVec_5;
  logic        wbd21_exceptionVec_13;
  logic        wbd21_exceptionVec_19;
  logic        wbd21_exceptionVec_21;
  always_ff @(posedge clock) if (wbInValid[21]) begin
    wbd21_robIdx_flag <= wbInBits[21].robIdx_flag;
    wbd21_robIdx_value <= wbInBits[21].robIdx_value;
    wbd21_flushPipe <= wbInBits[21].flushPipe;
    wbd21_replay <= wbInBits[21].replay;
    wbd21_trigger <= wbInBits[21].trigger;
    wbd21_debug_isMMIO <= wbInBits[21].debug_isMMIO;
    wbd21_debug_isNCIO <= wbInBits[21].debug_isNCIO;
    wbd21_debug_isPerfCnt <= wbInBits[21].debug_isPerfCnt;
    wbd21_debugInfo_enqRsTime <= wbInBits[21].debugInfo_enqRsTime;
    wbd21_debugInfo_issueTime <= wbInBits[21].debugInfo_issueTime;
    wbd21_debugInfo_selectTime <= wbInBits[21].debugInfo_selectTime;
    wbd21_exceptionVec_3 <= wbInBits[21].exceptionVec[3];
    wbd21_exceptionVec_4 <= wbInBits[21].exceptionVec[4];
    wbd21_exceptionVec_5 <= wbInBits[21].exceptionVec[5];
    wbd21_exceptionVec_13 <= wbInBits[21].exceptionVec[13];
    wbd21_exceptionVec_19 <= wbInBits[21].exceptionVec[19];
    wbd21_exceptionVec_21 <= wbInBits[21].exceptionVec[21];
  end
  always_comb begin
    wbDelayedBits[21] = '{default:'0};
    wbDelayedBits[21].robIdx_flag = wbd21_robIdx_flag;
    wbDelayedBits[21].robIdx_value = wbd21_robIdx_value;
    wbDelayedBits[21].flushPipe = wbd21_flushPipe;
    wbDelayedBits[21].replay = wbd21_replay;
    wbDelayedBits[21].trigger = wbd21_trigger;
    wbDelayedBits[21].debug_isMMIO = wbd21_debug_isMMIO;
    wbDelayedBits[21].debug_isNCIO = wbd21_debug_isNCIO;
    wbDelayedBits[21].debug_isPerfCnt = wbd21_debug_isPerfCnt;
    wbDelayedBits[21].debugInfo_enqRsTime = wbd21_debugInfo_enqRsTime;
    wbDelayedBits[21].debugInfo_issueTime = wbd21_debugInfo_issueTime;
    wbDelayedBits[21].debugInfo_selectTime = wbd21_debugInfo_selectTime;
    wbDelayedBits[21].exceptionVec[3] = wbd21_exceptionVec_3;
    wbDelayedBits[21].exceptionVec[4] = wbd21_exceptionVec_4;
    wbDelayedBits[21].exceptionVec[5] = wbd21_exceptionVec_5;
    wbDelayedBits[21].exceptionVec[13] = wbd21_exceptionVec_13;
    wbDelayedBits[21].exceptionVec[19] = wbd21_exceptionVec_19;
    wbDelayedBits[21].exceptionVec[21] = wbd21_exceptionVec_21;
  end

  // ---- lane 22: 12 字段 / 216 位(golden 保留)----
  logic        wbd22_robIdx_flag;
  logic [7:0] wbd22_robIdx_value;
  logic        wbd22_flushPipe;
  logic        wbd22_replay;
  logic [3:0] wbd22_trigger;
  logic        wbd22_debug_isMMIO;
  logic        wbd22_debug_isNCIO;
  logic        wbd22_debug_isPerfCnt;
  logic [63:0] wbd22_debugInfo_enqRsTime;
  logic [63:0] wbd22_debugInfo_issueTime;
  logic [63:0] wbd22_debugInfo_selectTime;
  logic        wbd22_exceptionVec_3;
  logic        wbd22_exceptionVec_4;
  logic        wbd22_exceptionVec_5;
  logic        wbd22_exceptionVec_13;
  logic        wbd22_exceptionVec_19;
  logic        wbd22_exceptionVec_21;
  always_ff @(posedge clock) if (wbInValid[22]) begin
    wbd22_robIdx_flag <= wbInBits[22].robIdx_flag;
    wbd22_robIdx_value <= wbInBits[22].robIdx_value;
    wbd22_flushPipe <= wbInBits[22].flushPipe;
    wbd22_replay <= wbInBits[22].replay;
    wbd22_trigger <= wbInBits[22].trigger;
    wbd22_debug_isMMIO <= wbInBits[22].debug_isMMIO;
    wbd22_debug_isNCIO <= wbInBits[22].debug_isNCIO;
    wbd22_debug_isPerfCnt <= wbInBits[22].debug_isPerfCnt;
    wbd22_debugInfo_enqRsTime <= wbInBits[22].debugInfo_enqRsTime;
    wbd22_debugInfo_issueTime <= wbInBits[22].debugInfo_issueTime;
    wbd22_debugInfo_selectTime <= wbInBits[22].debugInfo_selectTime;
    wbd22_exceptionVec_3 <= wbInBits[22].exceptionVec[3];
    wbd22_exceptionVec_4 <= wbInBits[22].exceptionVec[4];
    wbd22_exceptionVec_5 <= wbInBits[22].exceptionVec[5];
    wbd22_exceptionVec_13 <= wbInBits[22].exceptionVec[13];
    wbd22_exceptionVec_19 <= wbInBits[22].exceptionVec[19];
    wbd22_exceptionVec_21 <= wbInBits[22].exceptionVec[21];
  end
  always_comb begin
    wbDelayedBits[22] = '{default:'0};
    wbDelayedBits[22].robIdx_flag = wbd22_robIdx_flag;
    wbDelayedBits[22].robIdx_value = wbd22_robIdx_value;
    wbDelayedBits[22].flushPipe = wbd22_flushPipe;
    wbDelayedBits[22].replay = wbd22_replay;
    wbDelayedBits[22].trigger = wbd22_trigger;
    wbDelayedBits[22].debug_isMMIO = wbd22_debug_isMMIO;
    wbDelayedBits[22].debug_isNCIO = wbd22_debug_isNCIO;
    wbDelayedBits[22].debug_isPerfCnt = wbd22_debug_isPerfCnt;
    wbDelayedBits[22].debugInfo_enqRsTime = wbd22_debugInfo_enqRsTime;
    wbDelayedBits[22].debugInfo_issueTime = wbd22_debugInfo_issueTime;
    wbDelayedBits[22].debugInfo_selectTime = wbd22_debugInfo_selectTime;
    wbDelayedBits[22].exceptionVec[3] = wbd22_exceptionVec_3;
    wbDelayedBits[22].exceptionVec[4] = wbd22_exceptionVec_4;
    wbDelayedBits[22].exceptionVec[5] = wbd22_exceptionVec_5;
    wbDelayedBits[22].exceptionVec[13] = wbd22_exceptionVec_13;
    wbDelayedBits[22].exceptionVec[19] = wbd22_exceptionVec_19;
    wbDelayedBits[22].exceptionVec[21] = wbd22_exceptionVec_21;
  end

  // ---- lane 23: 27 字段 / 276 位(golden 保留)----
  logic        wbd23_robIdx_flag;
  logic [7:0] wbd23_robIdx_value;
  logic [6:0] wbd23_pdest;
  logic        wbd23_flushPipe;
  logic        wbd23_replay;
  logic [3:0] wbd23_trigger;
  logic        wbd23_v0Wen;
  logic        wbd23_vecWen;
  logic        wbd23_debug_isMMIO;
  logic        wbd23_debug_isNCIO;
  logic        wbd23_debug_isPerfCnt;
  logic [63:0] wbd23_debugInfo_enqRsTime;
  logic [63:0] wbd23_debugInfo_issueTime;
  logic [63:0] wbd23_debugInfo_selectTime;
  logic        wbd23_vls_isIndexed;
  logic        wbd23_vls_isStrided;
  logic        wbd23_vls_isVecLoad;
  logic        wbd23_vls_isVlm;
  logic        wbd23_vls_isWhole;
  logic [2:0] wbd23_vls_vdIdx;
  logic [2:0] wbd23_vls_vpu_nf;
  logic [1:0] wbd23_vls_vpu_veew;
  logic [2:0] wbd23_vls_vpu_vlmul;
  logic [1:0] wbd23_vls_vpu_vsew;
  logic [7:0] wbd23_vls_vpu_vstart;
  logic [6:0] wbd23_vls_vpu_vuopIdx;
  logic        wbd23_exceptionVec_0;
  logic        wbd23_exceptionVec_1;
  logic        wbd23_exceptionVec_2;
  logic        wbd23_exceptionVec_3;
  logic        wbd23_exceptionVec_4;
  logic        wbd23_exceptionVec_5;
  logic        wbd23_exceptionVec_6;
  logic        wbd23_exceptionVec_7;
  logic        wbd23_exceptionVec_8;
  logic        wbd23_exceptionVec_9;
  logic        wbd23_exceptionVec_10;
  logic        wbd23_exceptionVec_11;
  logic        wbd23_exceptionVec_12;
  logic        wbd23_exceptionVec_13;
  logic        wbd23_exceptionVec_14;
  logic        wbd23_exceptionVec_15;
  logic        wbd23_exceptionVec_16;
  logic        wbd23_exceptionVec_17;
  logic        wbd23_exceptionVec_18;
  logic        wbd23_exceptionVec_19;
  logic        wbd23_exceptionVec_20;
  logic        wbd23_exceptionVec_21;
  logic        wbd23_exceptionVec_22;
  logic        wbd23_exceptionVec_23;
  always_ff @(posedge clock) if (wbInValid[23]) begin
    wbd23_robIdx_flag <= wbInBits[23].robIdx_flag;
    wbd23_robIdx_value <= wbInBits[23].robIdx_value;
    wbd23_pdest <= wbInBits[23].pdest;
    wbd23_flushPipe <= wbInBits[23].flushPipe;
    wbd23_replay <= wbInBits[23].replay;
    wbd23_trigger <= wbInBits[23].trigger;
    wbd23_v0Wen <= wbInBits[23].v0Wen;
    wbd23_vecWen <= wbInBits[23].vecWen;
    wbd23_debug_isMMIO <= wbInBits[23].debug_isMMIO;
    wbd23_debug_isNCIO <= wbInBits[23].debug_isNCIO;
    wbd23_debug_isPerfCnt <= wbInBits[23].debug_isPerfCnt;
    wbd23_debugInfo_enqRsTime <= wbInBits[23].debugInfo_enqRsTime;
    wbd23_debugInfo_issueTime <= wbInBits[23].debugInfo_issueTime;
    wbd23_debugInfo_selectTime <= wbInBits[23].debugInfo_selectTime;
    wbd23_vls_isIndexed <= wbInBits[23].vls_isIndexed;
    wbd23_vls_isStrided <= wbInBits[23].vls_isStrided;
    wbd23_vls_isVecLoad <= wbInBits[23].vls_isVecLoad;
    wbd23_vls_isVlm <= wbInBits[23].vls_isVlm;
    wbd23_vls_isWhole <= wbInBits[23].vls_isWhole;
    wbd23_vls_vdIdx <= wbInBits[23].vls_vdIdx;
    wbd23_vls_vpu_nf <= wbInBits[23].vls_vpu_nf;
    wbd23_vls_vpu_veew <= wbInBits[23].vls_vpu_veew;
    wbd23_vls_vpu_vlmul <= wbInBits[23].vls_vpu_vlmul;
    wbd23_vls_vpu_vsew <= wbInBits[23].vls_vpu_vsew;
    wbd23_vls_vpu_vstart <= wbInBits[23].vls_vpu_vstart;
    wbd23_vls_vpu_vuopIdx <= wbInBits[23].vls_vpu_vuopIdx;
    wbd23_exceptionVec_3 <= wbInBits[23].exceptionVec[3];
    wbd23_exceptionVec_4 <= wbInBits[23].exceptionVec[4];
    wbd23_exceptionVec_5 <= wbInBits[23].exceptionVec[5];
    wbd23_exceptionVec_6 <= wbInBits[23].exceptionVec[6];
    wbd23_exceptionVec_7 <= wbInBits[23].exceptionVec[7];
    wbd23_exceptionVec_13 <= wbInBits[23].exceptionVec[13];
    wbd23_exceptionVec_15 <= wbInBits[23].exceptionVec[15];
    wbd23_exceptionVec_19 <= wbInBits[23].exceptionVec[19];
    wbd23_exceptionVec_21 <= wbInBits[23].exceptionVec[21];
    wbd23_exceptionVec_23 <= wbInBits[23].exceptionVec[23];
  end
  always_comb begin
    wbDelayedBits[23] = '{default:'0};
    wbDelayedBits[23].robIdx_flag = wbd23_robIdx_flag;
    wbDelayedBits[23].robIdx_value = wbd23_robIdx_value;
    wbDelayedBits[23].pdest = wbd23_pdest;
    wbDelayedBits[23].flushPipe = wbd23_flushPipe;
    wbDelayedBits[23].replay = wbd23_replay;
    wbDelayedBits[23].trigger = wbd23_trigger;
    wbDelayedBits[23].v0Wen = wbd23_v0Wen;
    wbDelayedBits[23].vecWen = wbd23_vecWen;
    wbDelayedBits[23].debug_isMMIO = wbd23_debug_isMMIO;
    wbDelayedBits[23].debug_isNCIO = wbd23_debug_isNCIO;
    wbDelayedBits[23].debug_isPerfCnt = wbd23_debug_isPerfCnt;
    wbDelayedBits[23].debugInfo_enqRsTime = wbd23_debugInfo_enqRsTime;
    wbDelayedBits[23].debugInfo_issueTime = wbd23_debugInfo_issueTime;
    wbDelayedBits[23].debugInfo_selectTime = wbd23_debugInfo_selectTime;
    wbDelayedBits[23].vls_isIndexed = wbd23_vls_isIndexed;
    wbDelayedBits[23].vls_isStrided = wbd23_vls_isStrided;
    wbDelayedBits[23].vls_isVecLoad = wbd23_vls_isVecLoad;
    wbDelayedBits[23].vls_isVlm = wbd23_vls_isVlm;
    wbDelayedBits[23].vls_isWhole = wbd23_vls_isWhole;
    wbDelayedBits[23].vls_vdIdx = wbd23_vls_vdIdx;
    wbDelayedBits[23].vls_vpu_nf = wbd23_vls_vpu_nf;
    wbDelayedBits[23].vls_vpu_veew = wbd23_vls_vpu_veew;
    wbDelayedBits[23].vls_vpu_vlmul = wbd23_vls_vpu_vlmul;
    wbDelayedBits[23].vls_vpu_vsew = wbd23_vls_vpu_vsew;
    wbDelayedBits[23].vls_vpu_vstart = wbd23_vls_vpu_vstart;
    wbDelayedBits[23].vls_vpu_vuopIdx = wbd23_vls_vpu_vuopIdx;
    wbDelayedBits[23].exceptionVec[0] = wbd23_exceptionVec_0;
    wbDelayedBits[23].exceptionVec[1] = wbd23_exceptionVec_1;
    wbDelayedBits[23].exceptionVec[2] = wbd23_exceptionVec_2;
    wbDelayedBits[23].exceptionVec[3] = wbd23_exceptionVec_3;
    wbDelayedBits[23].exceptionVec[4] = wbd23_exceptionVec_4;
    wbDelayedBits[23].exceptionVec[5] = wbd23_exceptionVec_5;
    wbDelayedBits[23].exceptionVec[6] = wbd23_exceptionVec_6;
    wbDelayedBits[23].exceptionVec[7] = wbd23_exceptionVec_7;
    wbDelayedBits[23].exceptionVec[8] = wbd23_exceptionVec_8;
    wbDelayedBits[23].exceptionVec[9] = wbd23_exceptionVec_9;
    wbDelayedBits[23].exceptionVec[10] = wbd23_exceptionVec_10;
    wbDelayedBits[23].exceptionVec[11] = wbd23_exceptionVec_11;
    wbDelayedBits[23].exceptionVec[12] = wbd23_exceptionVec_12;
    wbDelayedBits[23].exceptionVec[13] = wbd23_exceptionVec_13;
    wbDelayedBits[23].exceptionVec[14] = wbd23_exceptionVec_14;
    wbDelayedBits[23].exceptionVec[15] = wbd23_exceptionVec_15;
    wbDelayedBits[23].exceptionVec[16] = wbd23_exceptionVec_16;
    wbDelayedBits[23].exceptionVec[17] = wbd23_exceptionVec_17;
    wbDelayedBits[23].exceptionVec[18] = wbd23_exceptionVec_18;
    wbDelayedBits[23].exceptionVec[19] = wbd23_exceptionVec_19;
    wbDelayedBits[23].exceptionVec[20] = wbd23_exceptionVec_20;
    wbDelayedBits[23].exceptionVec[21] = wbd23_exceptionVec_21;
    wbDelayedBits[23].exceptionVec[22] = wbd23_exceptionVec_22;
    wbDelayedBits[23].exceptionVec[23] = wbd23_exceptionVec_23;
  end

  // ---- lane 24: 27 字段 / 262 位(golden 保留)----
  logic        wbd24_robIdx_flag;
  logic [7:0] wbd24_robIdx_value;
  logic [6:0] wbd24_pdest;
  logic        wbd24_flushPipe;
  logic        wbd24_replay;
  logic [3:0] wbd24_trigger;
  logic        wbd24_v0Wen;
  logic        wbd24_vecWen;
  logic        wbd24_debug_isMMIO;
  logic        wbd24_debug_isNCIO;
  logic        wbd24_debug_isPerfCnt;
  logic [63:0] wbd24_debugInfo_enqRsTime;
  logic [63:0] wbd24_debugInfo_issueTime;
  logic [63:0] wbd24_debugInfo_selectTime;
  logic        wbd24_vls_isIndexed;
  logic        wbd24_vls_isStrided;
  logic        wbd24_vls_isVecLoad;
  logic        wbd24_vls_isVlm;
  logic        wbd24_vls_isWhole;
  logic [2:0] wbd24_vls_vdIdx;
  logic [2:0] wbd24_vls_vpu_nf;
  logic [1:0] wbd24_vls_vpu_veew;
  logic [2:0] wbd24_vls_vpu_vlmul;
  logic [1:0] wbd24_vls_vpu_vsew;
  logic [7:0] wbd24_vls_vpu_vstart;
  logic [6:0] wbd24_vls_vpu_vuopIdx;
  logic        wbd24_exceptionVec_3;
  logic        wbd24_exceptionVec_4;
  logic        wbd24_exceptionVec_5;
  logic        wbd24_exceptionVec_6;
  logic        wbd24_exceptionVec_7;
  logic        wbd24_exceptionVec_13;
  logic        wbd24_exceptionVec_15;
  logic        wbd24_exceptionVec_19;
  logic        wbd24_exceptionVec_21;
  logic        wbd24_exceptionVec_23;
  always_ff @(posedge clock) if (wbInValid[24]) begin
    wbd24_robIdx_flag <= wbInBits[24].robIdx_flag;
    wbd24_robIdx_value <= wbInBits[24].robIdx_value;
    wbd24_pdest <= wbInBits[24].pdest;
    wbd24_flushPipe <= wbInBits[24].flushPipe;
    wbd24_replay <= wbInBits[24].replay;
    wbd24_trigger <= wbInBits[24].trigger;
    wbd24_v0Wen <= wbInBits[24].v0Wen;
    wbd24_vecWen <= wbInBits[24].vecWen;
    wbd24_debugInfo_enqRsTime <= wbInBits[24].debugInfo_enqRsTime;
    wbd24_debugInfo_issueTime <= wbInBits[24].debugInfo_issueTime;
    wbd24_debugInfo_selectTime <= wbInBits[24].debugInfo_selectTime;
    wbd24_vls_isIndexed <= wbInBits[24].vls_isIndexed;
    wbd24_vls_isStrided <= wbInBits[24].vls_isStrided;
    wbd24_vls_isVecLoad <= wbInBits[24].vls_isVecLoad;
    wbd24_vls_isVlm <= wbInBits[24].vls_isVlm;
    wbd24_vls_isWhole <= wbInBits[24].vls_isWhole;
    wbd24_vls_vdIdx <= wbInBits[24].vls_vdIdx;
    wbd24_vls_vpu_nf <= wbInBits[24].vls_vpu_nf;
    wbd24_vls_vpu_veew <= wbInBits[24].vls_vpu_veew;
    wbd24_vls_vpu_vlmul <= wbInBits[24].vls_vpu_vlmul;
    wbd24_vls_vpu_vsew <= wbInBits[24].vls_vpu_vsew;
    wbd24_vls_vpu_vstart <= wbInBits[24].vls_vpu_vstart;
    wbd24_vls_vpu_vuopIdx <= wbInBits[24].vls_vpu_vuopIdx;
    wbd24_exceptionVec_3 <= wbInBits[24].exceptionVec[3];
    wbd24_exceptionVec_4 <= wbInBits[24].exceptionVec[4];
    wbd24_exceptionVec_5 <= wbInBits[24].exceptionVec[5];
    wbd24_exceptionVec_6 <= wbInBits[24].exceptionVec[6];
    wbd24_exceptionVec_7 <= wbInBits[24].exceptionVec[7];
    wbd24_exceptionVec_13 <= wbInBits[24].exceptionVec[13];
    wbd24_exceptionVec_15 <= wbInBits[24].exceptionVec[15];
    wbd24_exceptionVec_19 <= wbInBits[24].exceptionVec[19];
    wbd24_exceptionVec_21 <= wbInBits[24].exceptionVec[21];
    wbd24_exceptionVec_23 <= wbInBits[24].exceptionVec[23];
  end
  always_comb begin
    wbDelayedBits[24] = '{default:'0};
    wbDelayedBits[24].robIdx_flag = wbd24_robIdx_flag;
    wbDelayedBits[24].robIdx_value = wbd24_robIdx_value;
    wbDelayedBits[24].pdest = wbd24_pdest;
    wbDelayedBits[24].flushPipe = wbd24_flushPipe;
    wbDelayedBits[24].replay = wbd24_replay;
    wbDelayedBits[24].trigger = wbd24_trigger;
    wbDelayedBits[24].v0Wen = wbd24_v0Wen;
    wbDelayedBits[24].vecWen = wbd24_vecWen;
    wbDelayedBits[24].debug_isMMIO = wbd24_debug_isMMIO;
    wbDelayedBits[24].debug_isNCIO = wbd24_debug_isNCIO;
    wbDelayedBits[24].debug_isPerfCnt = wbd24_debug_isPerfCnt;
    wbDelayedBits[24].debugInfo_enqRsTime = wbd24_debugInfo_enqRsTime;
    wbDelayedBits[24].debugInfo_issueTime = wbd24_debugInfo_issueTime;
    wbDelayedBits[24].debugInfo_selectTime = wbd24_debugInfo_selectTime;
    wbDelayedBits[24].vls_isIndexed = wbd24_vls_isIndexed;
    wbDelayedBits[24].vls_isStrided = wbd24_vls_isStrided;
    wbDelayedBits[24].vls_isVecLoad = wbd24_vls_isVecLoad;
    wbDelayedBits[24].vls_isVlm = wbd24_vls_isVlm;
    wbDelayedBits[24].vls_isWhole = wbd24_vls_isWhole;
    wbDelayedBits[24].vls_vdIdx = wbd24_vls_vdIdx;
    wbDelayedBits[24].vls_vpu_nf = wbd24_vls_vpu_nf;
    wbDelayedBits[24].vls_vpu_veew = wbd24_vls_vpu_veew;
    wbDelayedBits[24].vls_vpu_vlmul = wbd24_vls_vpu_vlmul;
    wbDelayedBits[24].vls_vpu_vsew = wbd24_vls_vpu_vsew;
    wbDelayedBits[24].vls_vpu_vstart = wbd24_vls_vpu_vstart;
    wbDelayedBits[24].vls_vpu_vuopIdx = wbd24_vls_vpu_vuopIdx;
    wbDelayedBits[24].exceptionVec[3] = wbd24_exceptionVec_3;
    wbDelayedBits[24].exceptionVec[4] = wbd24_exceptionVec_4;
    wbDelayedBits[24].exceptionVec[5] = wbd24_exceptionVec_5;
    wbDelayedBits[24].exceptionVec[6] = wbd24_exceptionVec_6;
    wbDelayedBits[24].exceptionVec[7] = wbd24_exceptionVec_7;
    wbDelayedBits[24].exceptionVec[13] = wbd24_exceptionVec_13;
    wbDelayedBits[24].exceptionVec[15] = wbd24_exceptionVec_15;
    wbDelayedBits[24].exceptionVec[19] = wbd24_exceptionVec_19;
    wbDelayedBits[24].exceptionVec[21] = wbd24_exceptionVec_21;
    wbDelayedBits[24].exceptionVec[23] = wbd24_exceptionVec_23;
  end

  // ---- lane 25: 1 字段 / 8 位(golden 保留)----
  logic [7:0] wbd25_robIdx_value;
  always_ff @(posedge clock) if (wbInValid[25]) begin
    wbd25_robIdx_value <= wbInBits[25].robIdx_value;
  end
  always_comb begin
    wbDelayedBits[25] = '{default:'0};
    wbDelayedBits[25].robIdx_value = wbd25_robIdx_value;
  end

  // ---- lane 26: 1 字段 / 8 位(golden 保留)----
  logic [7:0] wbd26_robIdx_value;
  always_ff @(posedge clock) if (wbInValid[26]) begin
    wbd26_robIdx_value <= wbInBits[26].robIdx_value;
  end
  always_comb begin
    wbDelayedBits[26] = '{default:'0};
    wbDelayedBits[26].robIdx_value = wbd26_robIdx_value;
  end

  // ==== [codex 0129 exact-equation] 32 hold-clear 状态改写为 golden 同形方程 ====
  //  golden: reg <= ~io_fromWB_wbData_<N>_valid & reg (无条件, 无 reset, 只清不置)。
  //  原 impl 写法 if(wbInValid[N]) reg <= wbInBits(D经wbpack默认恒0) 状态转移等价, 但
  //  FM 对两种语法常数折叠不同→13 Constrained-0X unmatched。同形后两侧折叠一致。
  always_ff @(posedge clock) begin // lane 18 hold-clear (golden 同形)
    wbd18_debug_isPerfCnt <= ~wbInValid[18] & wbd18_debug_isPerfCnt;
  end
  always_ff @(posedge clock) begin // lane 20 hold-clear (golden 同形)
    wbd20_exceptionVec_0 <= ~wbInValid[20] & wbd20_exceptionVec_0;
    wbd20_exceptionVec_1 <= ~wbInValid[20] & wbd20_exceptionVec_1;
    wbd20_exceptionVec_10 <= ~wbInValid[20] & wbd20_exceptionVec_10;
    wbd20_exceptionVec_11 <= ~wbInValid[20] & wbd20_exceptionVec_11;
    wbd20_exceptionVec_12 <= ~wbInValid[20] & wbd20_exceptionVec_12;
    wbd20_exceptionVec_14 <= ~wbInValid[20] & wbd20_exceptionVec_14;
    wbd20_exceptionVec_16 <= ~wbInValid[20] & wbd20_exceptionVec_16;
    wbd20_exceptionVec_17 <= ~wbInValid[20] & wbd20_exceptionVec_17;
    wbd20_exceptionVec_18 <= ~wbInValid[20] & wbd20_exceptionVec_18;
    wbd20_exceptionVec_2 <= ~wbInValid[20] & wbd20_exceptionVec_2;
    wbd20_exceptionVec_20 <= ~wbInValid[20] & wbd20_exceptionVec_20;
    wbd20_exceptionVec_22 <= ~wbInValid[20] & wbd20_exceptionVec_22;
    wbd20_exceptionVec_8 <= ~wbInValid[20] & wbd20_exceptionVec_8;
    wbd20_exceptionVec_9 <= ~wbInValid[20] & wbd20_exceptionVec_9;
  end
  always_ff @(posedge clock) begin // lane 23 hold-clear (golden 同形)
    wbd23_exceptionVec_0 <= ~wbInValid[23] & wbd23_exceptionVec_0;
    wbd23_exceptionVec_1 <= ~wbInValid[23] & wbd23_exceptionVec_1;
    wbd23_exceptionVec_10 <= ~wbInValid[23] & wbd23_exceptionVec_10;
    wbd23_exceptionVec_11 <= ~wbInValid[23] & wbd23_exceptionVec_11;
    wbd23_exceptionVec_12 <= ~wbInValid[23] & wbd23_exceptionVec_12;
    wbd23_exceptionVec_14 <= ~wbInValid[23] & wbd23_exceptionVec_14;
    wbd23_exceptionVec_16 <= ~wbInValid[23] & wbd23_exceptionVec_16;
    wbd23_exceptionVec_17 <= ~wbInValid[23] & wbd23_exceptionVec_17;
    wbd23_exceptionVec_18 <= ~wbInValid[23] & wbd23_exceptionVec_18;
    wbd23_exceptionVec_2 <= ~wbInValid[23] & wbd23_exceptionVec_2;
    wbd23_exceptionVec_20 <= ~wbInValid[23] & wbd23_exceptionVec_20;
    wbd23_exceptionVec_22 <= ~wbInValid[23] & wbd23_exceptionVec_22;
    wbd23_exceptionVec_8 <= ~wbInValid[23] & wbd23_exceptionVec_8;
    wbd23_exceptionVec_9 <= ~wbInValid[23] & wbd23_exceptionVec_9;
  end
  always_ff @(posedge clock) begin // lane 24 hold-clear (golden 同形)
    wbd24_debug_isMMIO <= ~wbInValid[24] & wbd24_debug_isMMIO;
    wbd24_debug_isNCIO <= ~wbInValid[24] & wbd24_debug_isNCIO;
    wbd24_debug_isPerfCnt <= ~wbInValid[24] & wbd24_debug_isPerfCnt;
  end
