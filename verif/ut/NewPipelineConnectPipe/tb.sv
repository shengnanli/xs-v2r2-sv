// NewPipelineConnectPipe 家族 UT —— 14 个变体一个 tb（golden vs 派生 _xs 双例化）。
//
// 这一族在此之前**一个 UT 都没有**：13 个变体的端口表是照 G0 生成的，缺 G1 新增的
// 透传字段，却没有任何检查看得见——既没 UT、也不在台账里。本 tb 就是补这个洞。
//
// 被测语义（全族共用一个核 xs_PipelineConnect，见 rtl/common/PipelineConnect.sv）：
//   in_ready = out_ready | ~valid            （_23 另或上 isOlder）
//   fire     = in_valid & in_ready
//   valid'   = ~isFlush & (fire | ~rightOutFire & valid)   （异步复位清 0）
//   data     = RegEnable(in_bits, fire)      —— 所有 payload 字段一律打拍，无组合直通
//
// 覆盖闸（流水连接件极易假绿：握手永远畅通、flush 永不触发也能 errors=0），
// 每个变体都必须满足，否则判 FAIL：
//   1. fire  次数足够          —— 真有数据被锁进来过
//   2. 反压拍 in_valid & ~in_ready —— 上游被真的挡过
//   3. flush 命中占用中的表项    —— isFlush 与 valid 同时为 1 过
//   4. hold 拍 valid & ~rightOutFire —— 表项被真的压住过
//   5. payload 每一位都取到过 1、也取到过 0 —— 位宽写窄/字段漏掉不会假绿
//   _23 另加：isOlder 决定性拍（isOlder & ~out_ready & valid）——
//             那些拍 in_ready 全靠 isOlder 才为 1，不打到就等于没测 isOlder。
`timescale 1ns/1ps

`define CHECK(TAG,SIG) begin \
  if (!$isunknown(g_``TAG``_``SIG)) begin \
    checks++; nchk_``TAG``++; \
    if (g_``TAG``_``SIG !== i_``TAG``_``SIG) begin \
      errors++; nerr_``TAG``++; \
      if (errors <= 40) $display("[%0t] MISMATCH %s.%s g=%0h i=%0h", $time, `"TAG`", `"SIG`", \
                                 g_``TAG``_``SIG, i_``TAG``_``SIG); \
    end \
  end \
end

module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  longint checks = 0;
  always #5 clock = ~clock;

  // ==========================================================================
  // NewPipelineConnectPipe —— 20 字段 / 831 位 payload
  // ==========================================================================
  logic v0_io_in_valid;
  logic [34:0] v0_io_in_bits_fuType;
  logic [8:0] v0_io_in_bits_fuOpType;
  logic [63:0] v0_io_in_bits_src_0;
  logic [63:0] v0_io_in_bits_src_1;
  logic v0_io_in_bits_robIdx_flag;
  logic [7:0] v0_io_in_bits_robIdx_value;
  logic [7:0] v0_io_in_bits_pdest;
  logic v0_io_in_bits_rfWen;
  logic v0_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v0_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v0_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v0_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v0_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v0_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v0_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v0_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v0_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v0_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v0_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v0_io_in_bits_debug_seqNum_uopIdx;
  logic v0_io_out_ready;
  logic v0_io_rightOutFire;
  logic v0_io_isFlush;
  wire  g_v0_io_in_ready, i_v0_io_in_ready;
  wire  g_v0_io_out_valid, i_v0_io_out_valid;
  wire  [34:0] g_v0_io_out_bits_fuType, i_v0_io_out_bits_fuType;
  wire  [8:0] g_v0_io_out_bits_fuOpType, i_v0_io_out_bits_fuOpType;
  wire  [63:0] g_v0_io_out_bits_src_0, i_v0_io_out_bits_src_0;
  wire  [63:0] g_v0_io_out_bits_src_1, i_v0_io_out_bits_src_1;
  wire  g_v0_io_out_bits_robIdx_flag, i_v0_io_out_bits_robIdx_flag;
  wire  [7:0] g_v0_io_out_bits_robIdx_value, i_v0_io_out_bits_robIdx_value;
  wire  [7:0] g_v0_io_out_bits_pdest, i_v0_io_out_bits_pdest;
  wire  g_v0_io_out_bits_rfWen, i_v0_io_out_bits_rfWen;
  wire  g_v0_io_out_bits_perfDebugInfo_eliminatedMove, i_v0_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v0_io_out_bits_perfDebugInfo_renameTime, i_v0_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v0_io_out_bits_perfDebugInfo_dispatchTime, i_v0_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v0_io_out_bits_perfDebugInfo_enqRsTime, i_v0_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v0_io_out_bits_perfDebugInfo_selectTime, i_v0_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v0_io_out_bits_perfDebugInfo_issueTime, i_v0_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v0_io_out_bits_perfDebugInfo_writebackTime, i_v0_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v0_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v0_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v0_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v0_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v0_io_out_bits_perfDebugInfo_tlbRespTime, i_v0_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v0_io_out_bits_debug_seqNum_seqNum, i_v0_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v0_io_out_bits_debug_seqNum_uopIdx, i_v0_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v0 = 0; int nerr_v0 = 0;
  longint fire_v0 = 0, bp_v0 = 0, flush_v0 = 0, hold_v0 = 0, ov_v0 = 0;
  logic [830:0] por_v0 = '0, pand_v0 = '1;   // payload 按位或 / 按位与
  wire  [830:0] pcat_v0 = {v0_io_in_bits_fuType, v0_io_in_bits_fuOpType, v0_io_in_bits_src_0, v0_io_in_bits_src_1, v0_io_in_bits_robIdx_flag, v0_io_in_bits_robIdx_value, v0_io_in_bits_pdest, v0_io_in_bits_rfWen, v0_io_in_bits_perfDebugInfo_eliminatedMove, v0_io_in_bits_perfDebugInfo_renameTime, v0_io_in_bits_perfDebugInfo_dispatchTime, v0_io_in_bits_perfDebugInfo_enqRsTime, v0_io_in_bits_perfDebugInfo_selectTime, v0_io_in_bits_perfDebugInfo_issueTime, v0_io_in_bits_perfDebugInfo_writebackTime, v0_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v0_io_in_bits_perfDebugInfo_tlbFirstReqTime, v0_io_in_bits_perfDebugInfo_tlbRespTime, v0_io_in_bits_debug_seqNum_seqNum, v0_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe u_g_v0 (
    .clock(clock), .reset(reset),
    .io_in_valid(v0_io_in_valid),
    .io_in_bits_fuType(v0_io_in_bits_fuType),
    .io_in_bits_fuOpType(v0_io_in_bits_fuOpType),
    .io_in_bits_src_0(v0_io_in_bits_src_0),
    .io_in_bits_src_1(v0_io_in_bits_src_1),
    .io_in_bits_robIdx_flag(v0_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v0_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v0_io_in_bits_pdest),
    .io_in_bits_rfWen(v0_io_in_bits_rfWen),
    .io_in_bits_perfDebugInfo_eliminatedMove(v0_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v0_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v0_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v0_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v0_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v0_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v0_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v0_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v0_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v0_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v0_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v0_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v0_io_out_ready),
    .io_rightOutFire(v0_io_rightOutFire),
    .io_isFlush(v0_io_isFlush),
    .io_in_ready(g_v0_io_in_ready),
    .io_out_valid(g_v0_io_out_valid),
    .io_out_bits_fuType(g_v0_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v0_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v0_io_out_bits_src_0),
    .io_out_bits_src_1(g_v0_io_out_bits_src_1),
    .io_out_bits_robIdx_flag(g_v0_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v0_io_out_bits_robIdx_value),
    .io_out_bits_pdest(g_v0_io_out_bits_pdest),
    .io_out_bits_rfWen(g_v0_io_out_bits_rfWen),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v0_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v0_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v0_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v0_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v0_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v0_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v0_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v0_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v0_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v0_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v0_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v0_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_xs u_i_v0 (
    .clock(clock), .reset(reset),
    .io_in_valid(v0_io_in_valid),
    .io_in_bits_fuType(v0_io_in_bits_fuType),
    .io_in_bits_fuOpType(v0_io_in_bits_fuOpType),
    .io_in_bits_src_0(v0_io_in_bits_src_0),
    .io_in_bits_src_1(v0_io_in_bits_src_1),
    .io_in_bits_robIdx_flag(v0_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v0_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v0_io_in_bits_pdest),
    .io_in_bits_rfWen(v0_io_in_bits_rfWen),
    .io_in_bits_perfDebugInfo_eliminatedMove(v0_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v0_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v0_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v0_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v0_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v0_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v0_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v0_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v0_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v0_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v0_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v0_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v0_io_out_ready),
    .io_rightOutFire(v0_io_rightOutFire),
    .io_isFlush(v0_io_isFlush),
    .io_in_ready(i_v0_io_in_ready),
    .io_out_valid(i_v0_io_out_valid),
    .io_out_bits_fuType(i_v0_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v0_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v0_io_out_bits_src_0),
    .io_out_bits_src_1(i_v0_io_out_bits_src_1),
    .io_out_bits_robIdx_flag(i_v0_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v0_io_out_bits_robIdx_value),
    .io_out_bits_pdest(i_v0_io_out_bits_pdest),
    .io_out_bits_rfWen(i_v0_io_out_bits_rfWen),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v0_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v0_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v0_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v0_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v0_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v0_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v0_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v0_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v0_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v0_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v0_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v0_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_1 —— 33 字段 / 1018 位 payload
  // ==========================================================================
  logic v1_io_in_valid;
  logic [34:0] v1_io_in_bits_fuType;
  logic [8:0] v1_io_in_bits_fuOpType;
  logic [63:0] v1_io_in_bits_src_0;
  logic [63:0] v1_io_in_bits_src_1;
  logic [63:0] v1_io_in_bits_imm;
  logic [4:0] v1_io_in_bits_nextPcOffset;
  logic v1_io_in_bits_robIdx_flag;
  logic [7:0] v1_io_in_bits_robIdx_value;
  logic [7:0] v1_io_in_bits_pdest;
  logic v1_io_in_bits_rfWen;
  logic [49:0] v1_io_in_bits_pc;
  logic v1_io_in_bits_preDecode_valid;
  logic v1_io_in_bits_preDecode_isRVC;
  logic [1:0] v1_io_in_bits_preDecode_brType;
  logic v1_io_in_bits_preDecode_isCall;
  logic v1_io_in_bits_preDecode_isRet;
  logic v1_io_in_bits_ftqIdx_flag;
  logic [5:0] v1_io_in_bits_ftqIdx_value;
  logic [3:0] v1_io_in_bits_ftqOffset;
  logic [49:0] v1_io_in_bits_predictInfo_target;
  logic v1_io_in_bits_predictInfo_taken;
  logic v1_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v1_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v1_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v1_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v1_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v1_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v1_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v1_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v1_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v1_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v1_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v1_io_in_bits_debug_seqNum_uopIdx;
  logic v1_io_out_ready;
  logic v1_io_rightOutFire;
  logic v1_io_isFlush;
  wire  g_v1_io_in_ready, i_v1_io_in_ready;
  wire  g_v1_io_out_valid, i_v1_io_out_valid;
  wire  [34:0] g_v1_io_out_bits_fuType, i_v1_io_out_bits_fuType;
  wire  [8:0] g_v1_io_out_bits_fuOpType, i_v1_io_out_bits_fuOpType;
  wire  [63:0] g_v1_io_out_bits_src_0, i_v1_io_out_bits_src_0;
  wire  [63:0] g_v1_io_out_bits_src_1, i_v1_io_out_bits_src_1;
  wire  [63:0] g_v1_io_out_bits_imm, i_v1_io_out_bits_imm;
  wire  [4:0] g_v1_io_out_bits_nextPcOffset, i_v1_io_out_bits_nextPcOffset;
  wire  g_v1_io_out_bits_robIdx_flag, i_v1_io_out_bits_robIdx_flag;
  wire  [7:0] g_v1_io_out_bits_robIdx_value, i_v1_io_out_bits_robIdx_value;
  wire  [7:0] g_v1_io_out_bits_pdest, i_v1_io_out_bits_pdest;
  wire  g_v1_io_out_bits_rfWen, i_v1_io_out_bits_rfWen;
  wire  [49:0] g_v1_io_out_bits_pc, i_v1_io_out_bits_pc;
  wire  g_v1_io_out_bits_preDecode_valid, i_v1_io_out_bits_preDecode_valid;
  wire  g_v1_io_out_bits_preDecode_isRVC, i_v1_io_out_bits_preDecode_isRVC;
  wire  [1:0] g_v1_io_out_bits_preDecode_brType, i_v1_io_out_bits_preDecode_brType;
  wire  g_v1_io_out_bits_preDecode_isCall, i_v1_io_out_bits_preDecode_isCall;
  wire  g_v1_io_out_bits_preDecode_isRet, i_v1_io_out_bits_preDecode_isRet;
  wire  g_v1_io_out_bits_ftqIdx_flag, i_v1_io_out_bits_ftqIdx_flag;
  wire  [5:0] g_v1_io_out_bits_ftqIdx_value, i_v1_io_out_bits_ftqIdx_value;
  wire  [3:0] g_v1_io_out_bits_ftqOffset, i_v1_io_out_bits_ftqOffset;
  wire  [49:0] g_v1_io_out_bits_predictInfo_target, i_v1_io_out_bits_predictInfo_target;
  wire  g_v1_io_out_bits_predictInfo_taken, i_v1_io_out_bits_predictInfo_taken;
  wire  g_v1_io_out_bits_perfDebugInfo_eliminatedMove, i_v1_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v1_io_out_bits_perfDebugInfo_renameTime, i_v1_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v1_io_out_bits_perfDebugInfo_dispatchTime, i_v1_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v1_io_out_bits_perfDebugInfo_enqRsTime, i_v1_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v1_io_out_bits_perfDebugInfo_selectTime, i_v1_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v1_io_out_bits_perfDebugInfo_issueTime, i_v1_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v1_io_out_bits_perfDebugInfo_writebackTime, i_v1_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v1_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v1_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v1_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v1_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v1_io_out_bits_perfDebugInfo_tlbRespTime, i_v1_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v1_io_out_bits_debug_seqNum_seqNum, i_v1_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v1_io_out_bits_debug_seqNum_uopIdx, i_v1_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v1 = 0; int nerr_v1 = 0;
  longint fire_v1 = 0, bp_v1 = 0, flush_v1 = 0, hold_v1 = 0, ov_v1 = 0;
  logic [1017:0] por_v1 = '0, pand_v1 = '1;   // payload 按位或 / 按位与
  wire  [1017:0] pcat_v1 = {v1_io_in_bits_fuType, v1_io_in_bits_fuOpType, v1_io_in_bits_src_0, v1_io_in_bits_src_1, v1_io_in_bits_imm, v1_io_in_bits_nextPcOffset, v1_io_in_bits_robIdx_flag, v1_io_in_bits_robIdx_value, v1_io_in_bits_pdest, v1_io_in_bits_rfWen, v1_io_in_bits_pc, v1_io_in_bits_preDecode_valid, v1_io_in_bits_preDecode_isRVC, v1_io_in_bits_preDecode_brType, v1_io_in_bits_preDecode_isCall, v1_io_in_bits_preDecode_isRet, v1_io_in_bits_ftqIdx_flag, v1_io_in_bits_ftqIdx_value, v1_io_in_bits_ftqOffset, v1_io_in_bits_predictInfo_target, v1_io_in_bits_predictInfo_taken, v1_io_in_bits_perfDebugInfo_eliminatedMove, v1_io_in_bits_perfDebugInfo_renameTime, v1_io_in_bits_perfDebugInfo_dispatchTime, v1_io_in_bits_perfDebugInfo_enqRsTime, v1_io_in_bits_perfDebugInfo_selectTime, v1_io_in_bits_perfDebugInfo_issueTime, v1_io_in_bits_perfDebugInfo_writebackTime, v1_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v1_io_in_bits_perfDebugInfo_tlbFirstReqTime, v1_io_in_bits_perfDebugInfo_tlbRespTime, v1_io_in_bits_debug_seqNum_seqNum, v1_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe_1 u_g_v1 (
    .clock(clock), .reset(reset),
    .io_in_valid(v1_io_in_valid),
    .io_in_bits_fuType(v1_io_in_bits_fuType),
    .io_in_bits_fuOpType(v1_io_in_bits_fuOpType),
    .io_in_bits_src_0(v1_io_in_bits_src_0),
    .io_in_bits_src_1(v1_io_in_bits_src_1),
    .io_in_bits_imm(v1_io_in_bits_imm),
    .io_in_bits_nextPcOffset(v1_io_in_bits_nextPcOffset),
    .io_in_bits_robIdx_flag(v1_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v1_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v1_io_in_bits_pdest),
    .io_in_bits_rfWen(v1_io_in_bits_rfWen),
    .io_in_bits_pc(v1_io_in_bits_pc),
    .io_in_bits_preDecode_valid(v1_io_in_bits_preDecode_valid),
    .io_in_bits_preDecode_isRVC(v1_io_in_bits_preDecode_isRVC),
    .io_in_bits_preDecode_brType(v1_io_in_bits_preDecode_brType),
    .io_in_bits_preDecode_isCall(v1_io_in_bits_preDecode_isCall),
    .io_in_bits_preDecode_isRet(v1_io_in_bits_preDecode_isRet),
    .io_in_bits_ftqIdx_flag(v1_io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(v1_io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(v1_io_in_bits_ftqOffset),
    .io_in_bits_predictInfo_target(v1_io_in_bits_predictInfo_target),
    .io_in_bits_predictInfo_taken(v1_io_in_bits_predictInfo_taken),
    .io_in_bits_perfDebugInfo_eliminatedMove(v1_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v1_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v1_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v1_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v1_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v1_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v1_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v1_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v1_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v1_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v1_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v1_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v1_io_out_ready),
    .io_rightOutFire(v1_io_rightOutFire),
    .io_isFlush(v1_io_isFlush),
    .io_in_ready(g_v1_io_in_ready),
    .io_out_valid(g_v1_io_out_valid),
    .io_out_bits_fuType(g_v1_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v1_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v1_io_out_bits_src_0),
    .io_out_bits_src_1(g_v1_io_out_bits_src_1),
    .io_out_bits_imm(g_v1_io_out_bits_imm),
    .io_out_bits_nextPcOffset(g_v1_io_out_bits_nextPcOffset),
    .io_out_bits_robIdx_flag(g_v1_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v1_io_out_bits_robIdx_value),
    .io_out_bits_pdest(g_v1_io_out_bits_pdest),
    .io_out_bits_rfWen(g_v1_io_out_bits_rfWen),
    .io_out_bits_pc(g_v1_io_out_bits_pc),
    .io_out_bits_preDecode_valid(g_v1_io_out_bits_preDecode_valid),
    .io_out_bits_preDecode_isRVC(g_v1_io_out_bits_preDecode_isRVC),
    .io_out_bits_preDecode_brType(g_v1_io_out_bits_preDecode_brType),
    .io_out_bits_preDecode_isCall(g_v1_io_out_bits_preDecode_isCall),
    .io_out_bits_preDecode_isRet(g_v1_io_out_bits_preDecode_isRet),
    .io_out_bits_ftqIdx_flag(g_v1_io_out_bits_ftqIdx_flag),
    .io_out_bits_ftqIdx_value(g_v1_io_out_bits_ftqIdx_value),
    .io_out_bits_ftqOffset(g_v1_io_out_bits_ftqOffset),
    .io_out_bits_predictInfo_target(g_v1_io_out_bits_predictInfo_target),
    .io_out_bits_predictInfo_taken(g_v1_io_out_bits_predictInfo_taken),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v1_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v1_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v1_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v1_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v1_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v1_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v1_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v1_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v1_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v1_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v1_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v1_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_1_xs u_i_v1 (
    .clock(clock), .reset(reset),
    .io_in_valid(v1_io_in_valid),
    .io_in_bits_fuType(v1_io_in_bits_fuType),
    .io_in_bits_fuOpType(v1_io_in_bits_fuOpType),
    .io_in_bits_src_0(v1_io_in_bits_src_0),
    .io_in_bits_src_1(v1_io_in_bits_src_1),
    .io_in_bits_imm(v1_io_in_bits_imm),
    .io_in_bits_nextPcOffset(v1_io_in_bits_nextPcOffset),
    .io_in_bits_robIdx_flag(v1_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v1_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v1_io_in_bits_pdest),
    .io_in_bits_rfWen(v1_io_in_bits_rfWen),
    .io_in_bits_pc(v1_io_in_bits_pc),
    .io_in_bits_preDecode_valid(v1_io_in_bits_preDecode_valid),
    .io_in_bits_preDecode_isRVC(v1_io_in_bits_preDecode_isRVC),
    .io_in_bits_preDecode_brType(v1_io_in_bits_preDecode_brType),
    .io_in_bits_preDecode_isCall(v1_io_in_bits_preDecode_isCall),
    .io_in_bits_preDecode_isRet(v1_io_in_bits_preDecode_isRet),
    .io_in_bits_ftqIdx_flag(v1_io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(v1_io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(v1_io_in_bits_ftqOffset),
    .io_in_bits_predictInfo_target(v1_io_in_bits_predictInfo_target),
    .io_in_bits_predictInfo_taken(v1_io_in_bits_predictInfo_taken),
    .io_in_bits_perfDebugInfo_eliminatedMove(v1_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v1_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v1_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v1_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v1_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v1_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v1_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v1_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v1_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v1_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v1_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v1_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v1_io_out_ready),
    .io_rightOutFire(v1_io_rightOutFire),
    .io_isFlush(v1_io_isFlush),
    .io_in_ready(i_v1_io_in_ready),
    .io_out_valid(i_v1_io_out_valid),
    .io_out_bits_fuType(i_v1_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v1_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v1_io_out_bits_src_0),
    .io_out_bits_src_1(i_v1_io_out_bits_src_1),
    .io_out_bits_imm(i_v1_io_out_bits_imm),
    .io_out_bits_nextPcOffset(i_v1_io_out_bits_nextPcOffset),
    .io_out_bits_robIdx_flag(i_v1_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v1_io_out_bits_robIdx_value),
    .io_out_bits_pdest(i_v1_io_out_bits_pdest),
    .io_out_bits_rfWen(i_v1_io_out_bits_rfWen),
    .io_out_bits_pc(i_v1_io_out_bits_pc),
    .io_out_bits_preDecode_valid(i_v1_io_out_bits_preDecode_valid),
    .io_out_bits_preDecode_isRVC(i_v1_io_out_bits_preDecode_isRVC),
    .io_out_bits_preDecode_brType(i_v1_io_out_bits_preDecode_brType),
    .io_out_bits_preDecode_isCall(i_v1_io_out_bits_preDecode_isCall),
    .io_out_bits_preDecode_isRet(i_v1_io_out_bits_preDecode_isRet),
    .io_out_bits_ftqIdx_flag(i_v1_io_out_bits_ftqIdx_flag),
    .io_out_bits_ftqIdx_value(i_v1_io_out_bits_ftqIdx_value),
    .io_out_bits_ftqOffset(i_v1_io_out_bits_ftqOffset),
    .io_out_bits_predictInfo_target(i_v1_io_out_bits_predictInfo_target),
    .io_out_bits_predictInfo_taken(i_v1_io_out_bits_predictInfo_taken),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v1_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v1_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v1_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v1_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v1_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v1_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v1_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v1_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v1_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v1_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v1_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v1_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_5 —— 41 字段 / 1030 位 payload
  // ==========================================================================
  logic v5_io_in_valid;
  logic [34:0] v5_io_in_bits_fuType;
  logic [8:0] v5_io_in_bits_fuOpType;
  logic [63:0] v5_io_in_bits_src_0;
  logic [63:0] v5_io_in_bits_src_1;
  logic [63:0] v5_io_in_bits_imm;
  logic [4:0] v5_io_in_bits_nextPcOffset;
  logic v5_io_in_bits_robIdx_flag;
  logic [7:0] v5_io_in_bits_robIdx_value;
  logic [7:0] v5_io_in_bits_pdest;
  logic v5_io_in_bits_rfWen;
  logic v5_io_in_bits_fpWen;
  logic v5_io_in_bits_vecWen;
  logic v5_io_in_bits_v0Wen;
  logic v5_io_in_bits_vlWen;
  logic [1:0] v5_io_in_bits_fpu_typeTagOut;
  logic v5_io_in_bits_fpu_wflags;
  logic [1:0] v5_io_in_bits_fpu_typ;
  logic [2:0] v5_io_in_bits_fpu_rm;
  logic [49:0] v5_io_in_bits_pc;
  logic v5_io_in_bits_preDecode_valid;
  logic v5_io_in_bits_preDecode_isRVC;
  logic [1:0] v5_io_in_bits_preDecode_brType;
  logic v5_io_in_bits_preDecode_isCall;
  logic v5_io_in_bits_preDecode_isRet;
  logic v5_io_in_bits_ftqIdx_flag;
  logic [5:0] v5_io_in_bits_ftqIdx_value;
  logic [3:0] v5_io_in_bits_ftqOffset;
  logic [49:0] v5_io_in_bits_predictInfo_target;
  logic v5_io_in_bits_predictInfo_taken;
  logic v5_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v5_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v5_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v5_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v5_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v5_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v5_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v5_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v5_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v5_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v5_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v5_io_in_bits_debug_seqNum_uopIdx;
  logic v5_io_out_ready;
  logic v5_io_rightOutFire;
  logic v5_io_isFlush;
  wire  g_v5_io_in_ready, i_v5_io_in_ready;
  wire  g_v5_io_out_valid, i_v5_io_out_valid;
  wire  [34:0] g_v5_io_out_bits_fuType, i_v5_io_out_bits_fuType;
  wire  [8:0] g_v5_io_out_bits_fuOpType, i_v5_io_out_bits_fuOpType;
  wire  [63:0] g_v5_io_out_bits_src_0, i_v5_io_out_bits_src_0;
  wire  [63:0] g_v5_io_out_bits_src_1, i_v5_io_out_bits_src_1;
  wire  [63:0] g_v5_io_out_bits_imm, i_v5_io_out_bits_imm;
  wire  [4:0] g_v5_io_out_bits_nextPcOffset, i_v5_io_out_bits_nextPcOffset;
  wire  g_v5_io_out_bits_robIdx_flag, i_v5_io_out_bits_robIdx_flag;
  wire  [7:0] g_v5_io_out_bits_robIdx_value, i_v5_io_out_bits_robIdx_value;
  wire  [7:0] g_v5_io_out_bits_pdest, i_v5_io_out_bits_pdest;
  wire  g_v5_io_out_bits_rfWen, i_v5_io_out_bits_rfWen;
  wire  g_v5_io_out_bits_fpWen, i_v5_io_out_bits_fpWen;
  wire  g_v5_io_out_bits_vecWen, i_v5_io_out_bits_vecWen;
  wire  g_v5_io_out_bits_v0Wen, i_v5_io_out_bits_v0Wen;
  wire  g_v5_io_out_bits_vlWen, i_v5_io_out_bits_vlWen;
  wire  [1:0] g_v5_io_out_bits_fpu_typeTagOut, i_v5_io_out_bits_fpu_typeTagOut;
  wire  g_v5_io_out_bits_fpu_wflags, i_v5_io_out_bits_fpu_wflags;
  wire  [1:0] g_v5_io_out_bits_fpu_typ, i_v5_io_out_bits_fpu_typ;
  wire  [2:0] g_v5_io_out_bits_fpu_rm, i_v5_io_out_bits_fpu_rm;
  wire  [49:0] g_v5_io_out_bits_pc, i_v5_io_out_bits_pc;
  wire  g_v5_io_out_bits_preDecode_valid, i_v5_io_out_bits_preDecode_valid;
  wire  g_v5_io_out_bits_preDecode_isRVC, i_v5_io_out_bits_preDecode_isRVC;
  wire  [1:0] g_v5_io_out_bits_preDecode_brType, i_v5_io_out_bits_preDecode_brType;
  wire  g_v5_io_out_bits_preDecode_isCall, i_v5_io_out_bits_preDecode_isCall;
  wire  g_v5_io_out_bits_preDecode_isRet, i_v5_io_out_bits_preDecode_isRet;
  wire  g_v5_io_out_bits_ftqIdx_flag, i_v5_io_out_bits_ftqIdx_flag;
  wire  [5:0] g_v5_io_out_bits_ftqIdx_value, i_v5_io_out_bits_ftqIdx_value;
  wire  [3:0] g_v5_io_out_bits_ftqOffset, i_v5_io_out_bits_ftqOffset;
  wire  [49:0] g_v5_io_out_bits_predictInfo_target, i_v5_io_out_bits_predictInfo_target;
  wire  g_v5_io_out_bits_predictInfo_taken, i_v5_io_out_bits_predictInfo_taken;
  wire  g_v5_io_out_bits_perfDebugInfo_eliminatedMove, i_v5_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v5_io_out_bits_perfDebugInfo_renameTime, i_v5_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v5_io_out_bits_perfDebugInfo_dispatchTime, i_v5_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v5_io_out_bits_perfDebugInfo_enqRsTime, i_v5_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v5_io_out_bits_perfDebugInfo_selectTime, i_v5_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v5_io_out_bits_perfDebugInfo_issueTime, i_v5_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v5_io_out_bits_perfDebugInfo_writebackTime, i_v5_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v5_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v5_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v5_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v5_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v5_io_out_bits_perfDebugInfo_tlbRespTime, i_v5_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v5_io_out_bits_debug_seqNum_seqNum, i_v5_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v5_io_out_bits_debug_seqNum_uopIdx, i_v5_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v5 = 0; int nerr_v5 = 0;
  longint fire_v5 = 0, bp_v5 = 0, flush_v5 = 0, hold_v5 = 0, ov_v5 = 0;
  logic [1029:0] por_v5 = '0, pand_v5 = '1;   // payload 按位或 / 按位与
  wire  [1029:0] pcat_v5 = {v5_io_in_bits_fuType, v5_io_in_bits_fuOpType, v5_io_in_bits_src_0, v5_io_in_bits_src_1, v5_io_in_bits_imm, v5_io_in_bits_nextPcOffset, v5_io_in_bits_robIdx_flag, v5_io_in_bits_robIdx_value, v5_io_in_bits_pdest, v5_io_in_bits_rfWen, v5_io_in_bits_fpWen, v5_io_in_bits_vecWen, v5_io_in_bits_v0Wen, v5_io_in_bits_vlWen, v5_io_in_bits_fpu_typeTagOut, v5_io_in_bits_fpu_wflags, v5_io_in_bits_fpu_typ, v5_io_in_bits_fpu_rm, v5_io_in_bits_pc, v5_io_in_bits_preDecode_valid, v5_io_in_bits_preDecode_isRVC, v5_io_in_bits_preDecode_brType, v5_io_in_bits_preDecode_isCall, v5_io_in_bits_preDecode_isRet, v5_io_in_bits_ftqIdx_flag, v5_io_in_bits_ftqIdx_value, v5_io_in_bits_ftqOffset, v5_io_in_bits_predictInfo_target, v5_io_in_bits_predictInfo_taken, v5_io_in_bits_perfDebugInfo_eliminatedMove, v5_io_in_bits_perfDebugInfo_renameTime, v5_io_in_bits_perfDebugInfo_dispatchTime, v5_io_in_bits_perfDebugInfo_enqRsTime, v5_io_in_bits_perfDebugInfo_selectTime, v5_io_in_bits_perfDebugInfo_issueTime, v5_io_in_bits_perfDebugInfo_writebackTime, v5_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v5_io_in_bits_perfDebugInfo_tlbFirstReqTime, v5_io_in_bits_perfDebugInfo_tlbRespTime, v5_io_in_bits_debug_seqNum_seqNum, v5_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe_5 u_g_v5 (
    .clock(clock), .reset(reset),
    .io_in_valid(v5_io_in_valid),
    .io_in_bits_fuType(v5_io_in_bits_fuType),
    .io_in_bits_fuOpType(v5_io_in_bits_fuOpType),
    .io_in_bits_src_0(v5_io_in_bits_src_0),
    .io_in_bits_src_1(v5_io_in_bits_src_1),
    .io_in_bits_imm(v5_io_in_bits_imm),
    .io_in_bits_nextPcOffset(v5_io_in_bits_nextPcOffset),
    .io_in_bits_robIdx_flag(v5_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v5_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v5_io_in_bits_pdest),
    .io_in_bits_rfWen(v5_io_in_bits_rfWen),
    .io_in_bits_fpWen(v5_io_in_bits_fpWen),
    .io_in_bits_vecWen(v5_io_in_bits_vecWen),
    .io_in_bits_v0Wen(v5_io_in_bits_v0Wen),
    .io_in_bits_vlWen(v5_io_in_bits_vlWen),
    .io_in_bits_fpu_typeTagOut(v5_io_in_bits_fpu_typeTagOut),
    .io_in_bits_fpu_wflags(v5_io_in_bits_fpu_wflags),
    .io_in_bits_fpu_typ(v5_io_in_bits_fpu_typ),
    .io_in_bits_fpu_rm(v5_io_in_bits_fpu_rm),
    .io_in_bits_pc(v5_io_in_bits_pc),
    .io_in_bits_preDecode_valid(v5_io_in_bits_preDecode_valid),
    .io_in_bits_preDecode_isRVC(v5_io_in_bits_preDecode_isRVC),
    .io_in_bits_preDecode_brType(v5_io_in_bits_preDecode_brType),
    .io_in_bits_preDecode_isCall(v5_io_in_bits_preDecode_isCall),
    .io_in_bits_preDecode_isRet(v5_io_in_bits_preDecode_isRet),
    .io_in_bits_ftqIdx_flag(v5_io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(v5_io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(v5_io_in_bits_ftqOffset),
    .io_in_bits_predictInfo_target(v5_io_in_bits_predictInfo_target),
    .io_in_bits_predictInfo_taken(v5_io_in_bits_predictInfo_taken),
    .io_in_bits_perfDebugInfo_eliminatedMove(v5_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v5_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v5_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v5_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v5_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v5_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v5_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v5_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v5_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v5_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v5_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v5_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v5_io_out_ready),
    .io_rightOutFire(v5_io_rightOutFire),
    .io_isFlush(v5_io_isFlush),
    .io_in_ready(g_v5_io_in_ready),
    .io_out_valid(g_v5_io_out_valid),
    .io_out_bits_fuType(g_v5_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v5_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v5_io_out_bits_src_0),
    .io_out_bits_src_1(g_v5_io_out_bits_src_1),
    .io_out_bits_imm(g_v5_io_out_bits_imm),
    .io_out_bits_nextPcOffset(g_v5_io_out_bits_nextPcOffset),
    .io_out_bits_robIdx_flag(g_v5_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v5_io_out_bits_robIdx_value),
    .io_out_bits_pdest(g_v5_io_out_bits_pdest),
    .io_out_bits_rfWen(g_v5_io_out_bits_rfWen),
    .io_out_bits_fpWen(g_v5_io_out_bits_fpWen),
    .io_out_bits_vecWen(g_v5_io_out_bits_vecWen),
    .io_out_bits_v0Wen(g_v5_io_out_bits_v0Wen),
    .io_out_bits_vlWen(g_v5_io_out_bits_vlWen),
    .io_out_bits_fpu_typeTagOut(g_v5_io_out_bits_fpu_typeTagOut),
    .io_out_bits_fpu_wflags(g_v5_io_out_bits_fpu_wflags),
    .io_out_bits_fpu_typ(g_v5_io_out_bits_fpu_typ),
    .io_out_bits_fpu_rm(g_v5_io_out_bits_fpu_rm),
    .io_out_bits_pc(g_v5_io_out_bits_pc),
    .io_out_bits_preDecode_valid(g_v5_io_out_bits_preDecode_valid),
    .io_out_bits_preDecode_isRVC(g_v5_io_out_bits_preDecode_isRVC),
    .io_out_bits_preDecode_brType(g_v5_io_out_bits_preDecode_brType),
    .io_out_bits_preDecode_isCall(g_v5_io_out_bits_preDecode_isCall),
    .io_out_bits_preDecode_isRet(g_v5_io_out_bits_preDecode_isRet),
    .io_out_bits_ftqIdx_flag(g_v5_io_out_bits_ftqIdx_flag),
    .io_out_bits_ftqIdx_value(g_v5_io_out_bits_ftqIdx_value),
    .io_out_bits_ftqOffset(g_v5_io_out_bits_ftqOffset),
    .io_out_bits_predictInfo_target(g_v5_io_out_bits_predictInfo_target),
    .io_out_bits_predictInfo_taken(g_v5_io_out_bits_predictInfo_taken),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v5_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v5_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v5_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v5_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v5_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v5_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v5_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v5_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v5_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v5_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v5_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v5_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_5_xs u_i_v5 (
    .clock(clock), .reset(reset),
    .io_in_valid(v5_io_in_valid),
    .io_in_bits_fuType(v5_io_in_bits_fuType),
    .io_in_bits_fuOpType(v5_io_in_bits_fuOpType),
    .io_in_bits_src_0(v5_io_in_bits_src_0),
    .io_in_bits_src_1(v5_io_in_bits_src_1),
    .io_in_bits_imm(v5_io_in_bits_imm),
    .io_in_bits_nextPcOffset(v5_io_in_bits_nextPcOffset),
    .io_in_bits_robIdx_flag(v5_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v5_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v5_io_in_bits_pdest),
    .io_in_bits_rfWen(v5_io_in_bits_rfWen),
    .io_in_bits_fpWen(v5_io_in_bits_fpWen),
    .io_in_bits_vecWen(v5_io_in_bits_vecWen),
    .io_in_bits_v0Wen(v5_io_in_bits_v0Wen),
    .io_in_bits_vlWen(v5_io_in_bits_vlWen),
    .io_in_bits_fpu_typeTagOut(v5_io_in_bits_fpu_typeTagOut),
    .io_in_bits_fpu_wflags(v5_io_in_bits_fpu_wflags),
    .io_in_bits_fpu_typ(v5_io_in_bits_fpu_typ),
    .io_in_bits_fpu_rm(v5_io_in_bits_fpu_rm),
    .io_in_bits_pc(v5_io_in_bits_pc),
    .io_in_bits_preDecode_valid(v5_io_in_bits_preDecode_valid),
    .io_in_bits_preDecode_isRVC(v5_io_in_bits_preDecode_isRVC),
    .io_in_bits_preDecode_brType(v5_io_in_bits_preDecode_brType),
    .io_in_bits_preDecode_isCall(v5_io_in_bits_preDecode_isCall),
    .io_in_bits_preDecode_isRet(v5_io_in_bits_preDecode_isRet),
    .io_in_bits_ftqIdx_flag(v5_io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(v5_io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(v5_io_in_bits_ftqOffset),
    .io_in_bits_predictInfo_target(v5_io_in_bits_predictInfo_target),
    .io_in_bits_predictInfo_taken(v5_io_in_bits_predictInfo_taken),
    .io_in_bits_perfDebugInfo_eliminatedMove(v5_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v5_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v5_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v5_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v5_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v5_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v5_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v5_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v5_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v5_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v5_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v5_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v5_io_out_ready),
    .io_rightOutFire(v5_io_rightOutFire),
    .io_isFlush(v5_io_isFlush),
    .io_in_ready(i_v5_io_in_ready),
    .io_out_valid(i_v5_io_out_valid),
    .io_out_bits_fuType(i_v5_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v5_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v5_io_out_bits_src_0),
    .io_out_bits_src_1(i_v5_io_out_bits_src_1),
    .io_out_bits_imm(i_v5_io_out_bits_imm),
    .io_out_bits_nextPcOffset(i_v5_io_out_bits_nextPcOffset),
    .io_out_bits_robIdx_flag(i_v5_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v5_io_out_bits_robIdx_value),
    .io_out_bits_pdest(i_v5_io_out_bits_pdest),
    .io_out_bits_rfWen(i_v5_io_out_bits_rfWen),
    .io_out_bits_fpWen(i_v5_io_out_bits_fpWen),
    .io_out_bits_vecWen(i_v5_io_out_bits_vecWen),
    .io_out_bits_v0Wen(i_v5_io_out_bits_v0Wen),
    .io_out_bits_vlWen(i_v5_io_out_bits_vlWen),
    .io_out_bits_fpu_typeTagOut(i_v5_io_out_bits_fpu_typeTagOut),
    .io_out_bits_fpu_wflags(i_v5_io_out_bits_fpu_wflags),
    .io_out_bits_fpu_typ(i_v5_io_out_bits_fpu_typ),
    .io_out_bits_fpu_rm(i_v5_io_out_bits_fpu_rm),
    .io_out_bits_pc(i_v5_io_out_bits_pc),
    .io_out_bits_preDecode_valid(i_v5_io_out_bits_preDecode_valid),
    .io_out_bits_preDecode_isRVC(i_v5_io_out_bits_preDecode_isRVC),
    .io_out_bits_preDecode_brType(i_v5_io_out_bits_preDecode_brType),
    .io_out_bits_preDecode_isCall(i_v5_io_out_bits_preDecode_isCall),
    .io_out_bits_preDecode_isRet(i_v5_io_out_bits_preDecode_isRet),
    .io_out_bits_ftqIdx_flag(i_v5_io_out_bits_ftqIdx_flag),
    .io_out_bits_ftqIdx_value(i_v5_io_out_bits_ftqIdx_value),
    .io_out_bits_ftqOffset(i_v5_io_out_bits_ftqOffset),
    .io_out_bits_predictInfo_target(i_v5_io_out_bits_predictInfo_target),
    .io_out_bits_predictInfo_taken(i_v5_io_out_bits_predictInfo_taken),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v5_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v5_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v5_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v5_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v5_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v5_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v5_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v5_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v5_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v5_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v5_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v5_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_7 —— 30 字段 / 913 位 payload
  // ==========================================================================
  logic v7_io_in_valid;
  logic [34:0] v7_io_in_bits_fuType;
  logic [8:0] v7_io_in_bits_fuOpType;
  logic [63:0] v7_io_in_bits_src_0;
  logic [63:0] v7_io_in_bits_src_1;
  logic [63:0] v7_io_in_bits_imm;
  logic v7_io_in_bits_robIdx_flag;
  logic [7:0] v7_io_in_bits_robIdx_value;
  logic [7:0] v7_io_in_bits_pdest;
  logic v7_io_in_bits_rfWen;
  logic v7_io_in_bits_flushPipe;
  logic v7_io_in_bits_preDecode_valid;
  logic v7_io_in_bits_preDecode_isRVC;
  logic [1:0] v7_io_in_bits_preDecode_brType;
  logic v7_io_in_bits_preDecode_isCall;
  logic v7_io_in_bits_preDecode_isRet;
  logic v7_io_in_bits_ftqIdx_flag;
  logic [5:0] v7_io_in_bits_ftqIdx_value;
  logic [3:0] v7_io_in_bits_ftqOffset;
  logic v7_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v7_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v7_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v7_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v7_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v7_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v7_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v7_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v7_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v7_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v7_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v7_io_in_bits_debug_seqNum_uopIdx;
  logic v7_io_out_ready;
  logic v7_io_rightOutFire;
  logic v7_io_isFlush;
  wire  g_v7_io_in_ready, i_v7_io_in_ready;
  wire  g_v7_io_out_valid, i_v7_io_out_valid;
  wire  [34:0] g_v7_io_out_bits_fuType, i_v7_io_out_bits_fuType;
  wire  [8:0] g_v7_io_out_bits_fuOpType, i_v7_io_out_bits_fuOpType;
  wire  [63:0] g_v7_io_out_bits_src_0, i_v7_io_out_bits_src_0;
  wire  [63:0] g_v7_io_out_bits_src_1, i_v7_io_out_bits_src_1;
  wire  [63:0] g_v7_io_out_bits_imm, i_v7_io_out_bits_imm;
  wire  g_v7_io_out_bits_robIdx_flag, i_v7_io_out_bits_robIdx_flag;
  wire  [7:0] g_v7_io_out_bits_robIdx_value, i_v7_io_out_bits_robIdx_value;
  wire  [7:0] g_v7_io_out_bits_pdest, i_v7_io_out_bits_pdest;
  wire  g_v7_io_out_bits_rfWen, i_v7_io_out_bits_rfWen;
  wire  g_v7_io_out_bits_flushPipe, i_v7_io_out_bits_flushPipe;
  wire  g_v7_io_out_bits_preDecode_valid, i_v7_io_out_bits_preDecode_valid;
  wire  g_v7_io_out_bits_preDecode_isRVC, i_v7_io_out_bits_preDecode_isRVC;
  wire  [1:0] g_v7_io_out_bits_preDecode_brType, i_v7_io_out_bits_preDecode_brType;
  wire  g_v7_io_out_bits_preDecode_isCall, i_v7_io_out_bits_preDecode_isCall;
  wire  g_v7_io_out_bits_preDecode_isRet, i_v7_io_out_bits_preDecode_isRet;
  wire  g_v7_io_out_bits_ftqIdx_flag, i_v7_io_out_bits_ftqIdx_flag;
  wire  [5:0] g_v7_io_out_bits_ftqIdx_value, i_v7_io_out_bits_ftqIdx_value;
  wire  [3:0] g_v7_io_out_bits_ftqOffset, i_v7_io_out_bits_ftqOffset;
  wire  g_v7_io_out_bits_perfDebugInfo_eliminatedMove, i_v7_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v7_io_out_bits_perfDebugInfo_renameTime, i_v7_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v7_io_out_bits_perfDebugInfo_dispatchTime, i_v7_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v7_io_out_bits_perfDebugInfo_enqRsTime, i_v7_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v7_io_out_bits_perfDebugInfo_selectTime, i_v7_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v7_io_out_bits_perfDebugInfo_issueTime, i_v7_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v7_io_out_bits_perfDebugInfo_writebackTime, i_v7_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v7_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v7_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v7_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v7_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v7_io_out_bits_perfDebugInfo_tlbRespTime, i_v7_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v7_io_out_bits_debug_seqNum_seqNum, i_v7_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v7_io_out_bits_debug_seqNum_uopIdx, i_v7_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v7 = 0; int nerr_v7 = 0;
  longint fire_v7 = 0, bp_v7 = 0, flush_v7 = 0, hold_v7 = 0, ov_v7 = 0;
  logic [912:0] por_v7 = '0, pand_v7 = '1;   // payload 按位或 / 按位与
  wire  [912:0] pcat_v7 = {v7_io_in_bits_fuType, v7_io_in_bits_fuOpType, v7_io_in_bits_src_0, v7_io_in_bits_src_1, v7_io_in_bits_imm, v7_io_in_bits_robIdx_flag, v7_io_in_bits_robIdx_value, v7_io_in_bits_pdest, v7_io_in_bits_rfWen, v7_io_in_bits_flushPipe, v7_io_in_bits_preDecode_valid, v7_io_in_bits_preDecode_isRVC, v7_io_in_bits_preDecode_brType, v7_io_in_bits_preDecode_isCall, v7_io_in_bits_preDecode_isRet, v7_io_in_bits_ftqIdx_flag, v7_io_in_bits_ftqIdx_value, v7_io_in_bits_ftqOffset, v7_io_in_bits_perfDebugInfo_eliminatedMove, v7_io_in_bits_perfDebugInfo_renameTime, v7_io_in_bits_perfDebugInfo_dispatchTime, v7_io_in_bits_perfDebugInfo_enqRsTime, v7_io_in_bits_perfDebugInfo_selectTime, v7_io_in_bits_perfDebugInfo_issueTime, v7_io_in_bits_perfDebugInfo_writebackTime, v7_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v7_io_in_bits_perfDebugInfo_tlbFirstReqTime, v7_io_in_bits_perfDebugInfo_tlbRespTime, v7_io_in_bits_debug_seqNum_seqNum, v7_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe_7 u_g_v7 (
    .clock(clock), .reset(reset),
    .io_in_valid(v7_io_in_valid),
    .io_in_bits_fuType(v7_io_in_bits_fuType),
    .io_in_bits_fuOpType(v7_io_in_bits_fuOpType),
    .io_in_bits_src_0(v7_io_in_bits_src_0),
    .io_in_bits_src_1(v7_io_in_bits_src_1),
    .io_in_bits_imm(v7_io_in_bits_imm),
    .io_in_bits_robIdx_flag(v7_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v7_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v7_io_in_bits_pdest),
    .io_in_bits_rfWen(v7_io_in_bits_rfWen),
    .io_in_bits_flushPipe(v7_io_in_bits_flushPipe),
    .io_in_bits_preDecode_valid(v7_io_in_bits_preDecode_valid),
    .io_in_bits_preDecode_isRVC(v7_io_in_bits_preDecode_isRVC),
    .io_in_bits_preDecode_brType(v7_io_in_bits_preDecode_brType),
    .io_in_bits_preDecode_isCall(v7_io_in_bits_preDecode_isCall),
    .io_in_bits_preDecode_isRet(v7_io_in_bits_preDecode_isRet),
    .io_in_bits_ftqIdx_flag(v7_io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(v7_io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(v7_io_in_bits_ftqOffset),
    .io_in_bits_perfDebugInfo_eliminatedMove(v7_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v7_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v7_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v7_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v7_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v7_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v7_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v7_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v7_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v7_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v7_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v7_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v7_io_out_ready),
    .io_rightOutFire(v7_io_rightOutFire),
    .io_isFlush(v7_io_isFlush),
    .io_in_ready(g_v7_io_in_ready),
    .io_out_valid(g_v7_io_out_valid),
    .io_out_bits_fuType(g_v7_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v7_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v7_io_out_bits_src_0),
    .io_out_bits_src_1(g_v7_io_out_bits_src_1),
    .io_out_bits_imm(g_v7_io_out_bits_imm),
    .io_out_bits_robIdx_flag(g_v7_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v7_io_out_bits_robIdx_value),
    .io_out_bits_pdest(g_v7_io_out_bits_pdest),
    .io_out_bits_rfWen(g_v7_io_out_bits_rfWen),
    .io_out_bits_flushPipe(g_v7_io_out_bits_flushPipe),
    .io_out_bits_preDecode_valid(g_v7_io_out_bits_preDecode_valid),
    .io_out_bits_preDecode_isRVC(g_v7_io_out_bits_preDecode_isRVC),
    .io_out_bits_preDecode_brType(g_v7_io_out_bits_preDecode_brType),
    .io_out_bits_preDecode_isCall(g_v7_io_out_bits_preDecode_isCall),
    .io_out_bits_preDecode_isRet(g_v7_io_out_bits_preDecode_isRet),
    .io_out_bits_ftqIdx_flag(g_v7_io_out_bits_ftqIdx_flag),
    .io_out_bits_ftqIdx_value(g_v7_io_out_bits_ftqIdx_value),
    .io_out_bits_ftqOffset(g_v7_io_out_bits_ftqOffset),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v7_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v7_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v7_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v7_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v7_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v7_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v7_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v7_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v7_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v7_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v7_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v7_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_7_xs u_i_v7 (
    .clock(clock), .reset(reset),
    .io_in_valid(v7_io_in_valid),
    .io_in_bits_fuType(v7_io_in_bits_fuType),
    .io_in_bits_fuOpType(v7_io_in_bits_fuOpType),
    .io_in_bits_src_0(v7_io_in_bits_src_0),
    .io_in_bits_src_1(v7_io_in_bits_src_1),
    .io_in_bits_imm(v7_io_in_bits_imm),
    .io_in_bits_robIdx_flag(v7_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v7_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v7_io_in_bits_pdest),
    .io_in_bits_rfWen(v7_io_in_bits_rfWen),
    .io_in_bits_flushPipe(v7_io_in_bits_flushPipe),
    .io_in_bits_preDecode_valid(v7_io_in_bits_preDecode_valid),
    .io_in_bits_preDecode_isRVC(v7_io_in_bits_preDecode_isRVC),
    .io_in_bits_preDecode_brType(v7_io_in_bits_preDecode_brType),
    .io_in_bits_preDecode_isCall(v7_io_in_bits_preDecode_isCall),
    .io_in_bits_preDecode_isRet(v7_io_in_bits_preDecode_isRet),
    .io_in_bits_ftqIdx_flag(v7_io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(v7_io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(v7_io_in_bits_ftqOffset),
    .io_in_bits_perfDebugInfo_eliminatedMove(v7_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v7_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v7_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v7_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v7_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v7_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v7_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v7_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v7_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v7_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v7_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v7_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v7_io_out_ready),
    .io_rightOutFire(v7_io_rightOutFire),
    .io_isFlush(v7_io_isFlush),
    .io_in_ready(i_v7_io_in_ready),
    .io_out_valid(i_v7_io_out_valid),
    .io_out_bits_fuType(i_v7_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v7_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v7_io_out_bits_src_0),
    .io_out_bits_src_1(i_v7_io_out_bits_src_1),
    .io_out_bits_imm(i_v7_io_out_bits_imm),
    .io_out_bits_robIdx_flag(i_v7_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v7_io_out_bits_robIdx_value),
    .io_out_bits_pdest(i_v7_io_out_bits_pdest),
    .io_out_bits_rfWen(i_v7_io_out_bits_rfWen),
    .io_out_bits_flushPipe(i_v7_io_out_bits_flushPipe),
    .io_out_bits_preDecode_valid(i_v7_io_out_bits_preDecode_valid),
    .io_out_bits_preDecode_isRVC(i_v7_io_out_bits_preDecode_isRVC),
    .io_out_bits_preDecode_brType(i_v7_io_out_bits_preDecode_brType),
    .io_out_bits_preDecode_isCall(i_v7_io_out_bits_preDecode_isCall),
    .io_out_bits_preDecode_isRet(i_v7_io_out_bits_preDecode_isRet),
    .io_out_bits_ftqIdx_flag(i_v7_io_out_bits_ftqIdx_flag),
    .io_out_bits_ftqIdx_value(i_v7_io_out_bits_ftqIdx_value),
    .io_out_bits_ftqOffset(i_v7_io_out_bits_ftqOffset),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v7_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v7_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v7_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v7_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v7_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v7_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v7_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v7_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v7_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v7_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v7_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v7_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_8 —— 27 字段 / 904 位 payload
  // ==========================================================================
  logic v8_io_in_valid;
  logic [34:0] v8_io_in_bits_fuType;
  logic [8:0] v8_io_in_bits_fuOpType;
  logic [63:0] v8_io_in_bits_src_0;
  logic [63:0] v8_io_in_bits_src_1;
  logic [63:0] v8_io_in_bits_src_2;
  logic v8_io_in_bits_robIdx_flag;
  logic [7:0] v8_io_in_bits_robIdx_value;
  logic [7:0] v8_io_in_bits_pdest;
  logic v8_io_in_bits_rfWen;
  logic v8_io_in_bits_fpWen;
  logic v8_io_in_bits_vecWen;
  logic v8_io_in_bits_v0Wen;
  logic v8_io_in_bits_fpu_wflags;
  logic [1:0] v8_io_in_bits_fpu_fmt;
  logic [2:0] v8_io_in_bits_fpu_rm;
  logic v8_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v8_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v8_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v8_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v8_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v8_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v8_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v8_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v8_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v8_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v8_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v8_io_in_bits_debug_seqNum_uopIdx;
  logic v8_io_out_ready;
  logic v8_io_rightOutFire;
  logic v8_io_isFlush;
  wire  g_v8_io_in_ready, i_v8_io_in_ready;
  wire  g_v8_io_out_valid, i_v8_io_out_valid;
  wire  [34:0] g_v8_io_out_bits_fuType, i_v8_io_out_bits_fuType;
  wire  [8:0] g_v8_io_out_bits_fuOpType, i_v8_io_out_bits_fuOpType;
  wire  [63:0] g_v8_io_out_bits_src_0, i_v8_io_out_bits_src_0;
  wire  [63:0] g_v8_io_out_bits_src_1, i_v8_io_out_bits_src_1;
  wire  [63:0] g_v8_io_out_bits_src_2, i_v8_io_out_bits_src_2;
  wire  g_v8_io_out_bits_robIdx_flag, i_v8_io_out_bits_robIdx_flag;
  wire  [7:0] g_v8_io_out_bits_robIdx_value, i_v8_io_out_bits_robIdx_value;
  wire  [7:0] g_v8_io_out_bits_pdest, i_v8_io_out_bits_pdest;
  wire  g_v8_io_out_bits_rfWen, i_v8_io_out_bits_rfWen;
  wire  g_v8_io_out_bits_fpWen, i_v8_io_out_bits_fpWen;
  wire  g_v8_io_out_bits_vecWen, i_v8_io_out_bits_vecWen;
  wire  g_v8_io_out_bits_v0Wen, i_v8_io_out_bits_v0Wen;
  wire  g_v8_io_out_bits_fpu_wflags, i_v8_io_out_bits_fpu_wflags;
  wire  [1:0] g_v8_io_out_bits_fpu_fmt, i_v8_io_out_bits_fpu_fmt;
  wire  [2:0] g_v8_io_out_bits_fpu_rm, i_v8_io_out_bits_fpu_rm;
  wire  g_v8_io_out_bits_perfDebugInfo_eliminatedMove, i_v8_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v8_io_out_bits_perfDebugInfo_renameTime, i_v8_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v8_io_out_bits_perfDebugInfo_dispatchTime, i_v8_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v8_io_out_bits_perfDebugInfo_enqRsTime, i_v8_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v8_io_out_bits_perfDebugInfo_selectTime, i_v8_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v8_io_out_bits_perfDebugInfo_issueTime, i_v8_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v8_io_out_bits_perfDebugInfo_writebackTime, i_v8_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v8_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v8_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v8_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v8_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v8_io_out_bits_perfDebugInfo_tlbRespTime, i_v8_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v8_io_out_bits_debug_seqNum_seqNum, i_v8_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v8_io_out_bits_debug_seqNum_uopIdx, i_v8_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v8 = 0; int nerr_v8 = 0;
  longint fire_v8 = 0, bp_v8 = 0, flush_v8 = 0, hold_v8 = 0, ov_v8 = 0;
  logic [903:0] por_v8 = '0, pand_v8 = '1;   // payload 按位或 / 按位与
  wire  [903:0] pcat_v8 = {v8_io_in_bits_fuType, v8_io_in_bits_fuOpType, v8_io_in_bits_src_0, v8_io_in_bits_src_1, v8_io_in_bits_src_2, v8_io_in_bits_robIdx_flag, v8_io_in_bits_robIdx_value, v8_io_in_bits_pdest, v8_io_in_bits_rfWen, v8_io_in_bits_fpWen, v8_io_in_bits_vecWen, v8_io_in_bits_v0Wen, v8_io_in_bits_fpu_wflags, v8_io_in_bits_fpu_fmt, v8_io_in_bits_fpu_rm, v8_io_in_bits_perfDebugInfo_eliminatedMove, v8_io_in_bits_perfDebugInfo_renameTime, v8_io_in_bits_perfDebugInfo_dispatchTime, v8_io_in_bits_perfDebugInfo_enqRsTime, v8_io_in_bits_perfDebugInfo_selectTime, v8_io_in_bits_perfDebugInfo_issueTime, v8_io_in_bits_perfDebugInfo_writebackTime, v8_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v8_io_in_bits_perfDebugInfo_tlbFirstReqTime, v8_io_in_bits_perfDebugInfo_tlbRespTime, v8_io_in_bits_debug_seqNum_seqNum, v8_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe_8 u_g_v8 (
    .clock(clock), .reset(reset),
    .io_in_valid(v8_io_in_valid),
    .io_in_bits_fuType(v8_io_in_bits_fuType),
    .io_in_bits_fuOpType(v8_io_in_bits_fuOpType),
    .io_in_bits_src_0(v8_io_in_bits_src_0),
    .io_in_bits_src_1(v8_io_in_bits_src_1),
    .io_in_bits_src_2(v8_io_in_bits_src_2),
    .io_in_bits_robIdx_flag(v8_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v8_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v8_io_in_bits_pdest),
    .io_in_bits_rfWen(v8_io_in_bits_rfWen),
    .io_in_bits_fpWen(v8_io_in_bits_fpWen),
    .io_in_bits_vecWen(v8_io_in_bits_vecWen),
    .io_in_bits_v0Wen(v8_io_in_bits_v0Wen),
    .io_in_bits_fpu_wflags(v8_io_in_bits_fpu_wflags),
    .io_in_bits_fpu_fmt(v8_io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm(v8_io_in_bits_fpu_rm),
    .io_in_bits_perfDebugInfo_eliminatedMove(v8_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v8_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v8_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v8_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v8_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v8_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v8_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v8_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v8_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v8_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v8_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v8_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v8_io_out_ready),
    .io_rightOutFire(v8_io_rightOutFire),
    .io_isFlush(v8_io_isFlush),
    .io_in_ready(g_v8_io_in_ready),
    .io_out_valid(g_v8_io_out_valid),
    .io_out_bits_fuType(g_v8_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v8_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v8_io_out_bits_src_0),
    .io_out_bits_src_1(g_v8_io_out_bits_src_1),
    .io_out_bits_src_2(g_v8_io_out_bits_src_2),
    .io_out_bits_robIdx_flag(g_v8_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v8_io_out_bits_robIdx_value),
    .io_out_bits_pdest(g_v8_io_out_bits_pdest),
    .io_out_bits_rfWen(g_v8_io_out_bits_rfWen),
    .io_out_bits_fpWen(g_v8_io_out_bits_fpWen),
    .io_out_bits_vecWen(g_v8_io_out_bits_vecWen),
    .io_out_bits_v0Wen(g_v8_io_out_bits_v0Wen),
    .io_out_bits_fpu_wflags(g_v8_io_out_bits_fpu_wflags),
    .io_out_bits_fpu_fmt(g_v8_io_out_bits_fpu_fmt),
    .io_out_bits_fpu_rm(g_v8_io_out_bits_fpu_rm),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v8_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v8_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v8_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v8_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v8_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v8_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v8_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v8_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v8_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v8_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v8_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v8_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_8_xs u_i_v8 (
    .clock(clock), .reset(reset),
    .io_in_valid(v8_io_in_valid),
    .io_in_bits_fuType(v8_io_in_bits_fuType),
    .io_in_bits_fuOpType(v8_io_in_bits_fuOpType),
    .io_in_bits_src_0(v8_io_in_bits_src_0),
    .io_in_bits_src_1(v8_io_in_bits_src_1),
    .io_in_bits_src_2(v8_io_in_bits_src_2),
    .io_in_bits_robIdx_flag(v8_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v8_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v8_io_in_bits_pdest),
    .io_in_bits_rfWen(v8_io_in_bits_rfWen),
    .io_in_bits_fpWen(v8_io_in_bits_fpWen),
    .io_in_bits_vecWen(v8_io_in_bits_vecWen),
    .io_in_bits_v0Wen(v8_io_in_bits_v0Wen),
    .io_in_bits_fpu_wflags(v8_io_in_bits_fpu_wflags),
    .io_in_bits_fpu_fmt(v8_io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm(v8_io_in_bits_fpu_rm),
    .io_in_bits_perfDebugInfo_eliminatedMove(v8_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v8_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v8_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v8_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v8_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v8_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v8_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v8_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v8_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v8_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v8_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v8_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v8_io_out_ready),
    .io_rightOutFire(v8_io_rightOutFire),
    .io_isFlush(v8_io_isFlush),
    .io_in_ready(i_v8_io_in_ready),
    .io_out_valid(i_v8_io_out_valid),
    .io_out_bits_fuType(i_v8_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v8_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v8_io_out_bits_src_0),
    .io_out_bits_src_1(i_v8_io_out_bits_src_1),
    .io_out_bits_src_2(i_v8_io_out_bits_src_2),
    .io_out_bits_robIdx_flag(i_v8_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v8_io_out_bits_robIdx_value),
    .io_out_bits_pdest(i_v8_io_out_bits_pdest),
    .io_out_bits_rfWen(i_v8_io_out_bits_rfWen),
    .io_out_bits_fpWen(i_v8_io_out_bits_fpWen),
    .io_out_bits_vecWen(i_v8_io_out_bits_vecWen),
    .io_out_bits_v0Wen(i_v8_io_out_bits_v0Wen),
    .io_out_bits_fpu_wflags(i_v8_io_out_bits_fpu_wflags),
    .io_out_bits_fpu_fmt(i_v8_io_out_bits_fpu_fmt),
    .io_out_bits_fpu_rm(i_v8_io_out_bits_fpu_rm),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v8_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v8_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v8_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v8_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v8_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v8_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v8_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v8_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v8_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v8_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v8_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v8_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_9 —— 23 字段 / 837 位 payload
  // ==========================================================================
  logic v9_io_in_valid;
  logic [34:0] v9_io_in_bits_fuType;
  logic [8:0] v9_io_in_bits_fuOpType;
  logic [63:0] v9_io_in_bits_src_0;
  logic [63:0] v9_io_in_bits_src_1;
  logic v9_io_in_bits_robIdx_flag;
  logic [7:0] v9_io_in_bits_robIdx_value;
  logic [7:0] v9_io_in_bits_pdest;
  logic v9_io_in_bits_fpWen;
  logic v9_io_in_bits_fpu_wflags;
  logic [1:0] v9_io_in_bits_fpu_fmt;
  logic [2:0] v9_io_in_bits_fpu_rm;
  logic v9_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v9_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v9_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v9_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v9_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v9_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v9_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v9_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v9_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v9_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v9_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v9_io_in_bits_debug_seqNum_uopIdx;
  logic v9_io_out_ready;
  logic v9_io_rightOutFire;
  logic v9_io_isFlush;
  wire  g_v9_io_in_ready, i_v9_io_in_ready;
  wire  g_v9_io_out_valid, i_v9_io_out_valid;
  wire  [34:0] g_v9_io_out_bits_fuType, i_v9_io_out_bits_fuType;
  wire  [8:0] g_v9_io_out_bits_fuOpType, i_v9_io_out_bits_fuOpType;
  wire  [63:0] g_v9_io_out_bits_src_0, i_v9_io_out_bits_src_0;
  wire  [63:0] g_v9_io_out_bits_src_1, i_v9_io_out_bits_src_1;
  wire  g_v9_io_out_bits_robIdx_flag, i_v9_io_out_bits_robIdx_flag;
  wire  [7:0] g_v9_io_out_bits_robIdx_value, i_v9_io_out_bits_robIdx_value;
  wire  [7:0] g_v9_io_out_bits_pdest, i_v9_io_out_bits_pdest;
  wire  g_v9_io_out_bits_fpWen, i_v9_io_out_bits_fpWen;
  wire  g_v9_io_out_bits_fpu_wflags, i_v9_io_out_bits_fpu_wflags;
  wire  [1:0] g_v9_io_out_bits_fpu_fmt, i_v9_io_out_bits_fpu_fmt;
  wire  [2:0] g_v9_io_out_bits_fpu_rm, i_v9_io_out_bits_fpu_rm;
  wire  g_v9_io_out_bits_perfDebugInfo_eliminatedMove, i_v9_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v9_io_out_bits_perfDebugInfo_renameTime, i_v9_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v9_io_out_bits_perfDebugInfo_dispatchTime, i_v9_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v9_io_out_bits_perfDebugInfo_enqRsTime, i_v9_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v9_io_out_bits_perfDebugInfo_selectTime, i_v9_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v9_io_out_bits_perfDebugInfo_issueTime, i_v9_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v9_io_out_bits_perfDebugInfo_writebackTime, i_v9_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v9_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v9_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v9_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v9_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v9_io_out_bits_perfDebugInfo_tlbRespTime, i_v9_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v9_io_out_bits_debug_seqNum_seqNum, i_v9_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v9_io_out_bits_debug_seqNum_uopIdx, i_v9_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v9 = 0; int nerr_v9 = 0;
  longint fire_v9 = 0, bp_v9 = 0, flush_v9 = 0, hold_v9 = 0, ov_v9 = 0;
  logic [836:0] por_v9 = '0, pand_v9 = '1;   // payload 按位或 / 按位与
  wire  [836:0] pcat_v9 = {v9_io_in_bits_fuType, v9_io_in_bits_fuOpType, v9_io_in_bits_src_0, v9_io_in_bits_src_1, v9_io_in_bits_robIdx_flag, v9_io_in_bits_robIdx_value, v9_io_in_bits_pdest, v9_io_in_bits_fpWen, v9_io_in_bits_fpu_wflags, v9_io_in_bits_fpu_fmt, v9_io_in_bits_fpu_rm, v9_io_in_bits_perfDebugInfo_eliminatedMove, v9_io_in_bits_perfDebugInfo_renameTime, v9_io_in_bits_perfDebugInfo_dispatchTime, v9_io_in_bits_perfDebugInfo_enqRsTime, v9_io_in_bits_perfDebugInfo_selectTime, v9_io_in_bits_perfDebugInfo_issueTime, v9_io_in_bits_perfDebugInfo_writebackTime, v9_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v9_io_in_bits_perfDebugInfo_tlbFirstReqTime, v9_io_in_bits_perfDebugInfo_tlbRespTime, v9_io_in_bits_debug_seqNum_seqNum, v9_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe_9 u_g_v9 (
    .clock(clock), .reset(reset),
    .io_in_valid(v9_io_in_valid),
    .io_in_bits_fuType(v9_io_in_bits_fuType),
    .io_in_bits_fuOpType(v9_io_in_bits_fuOpType),
    .io_in_bits_src_0(v9_io_in_bits_src_0),
    .io_in_bits_src_1(v9_io_in_bits_src_1),
    .io_in_bits_robIdx_flag(v9_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v9_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v9_io_in_bits_pdest),
    .io_in_bits_fpWen(v9_io_in_bits_fpWen),
    .io_in_bits_fpu_wflags(v9_io_in_bits_fpu_wflags),
    .io_in_bits_fpu_fmt(v9_io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm(v9_io_in_bits_fpu_rm),
    .io_in_bits_perfDebugInfo_eliminatedMove(v9_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v9_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v9_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v9_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v9_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v9_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v9_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v9_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v9_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v9_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v9_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v9_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v9_io_out_ready),
    .io_rightOutFire(v9_io_rightOutFire),
    .io_isFlush(v9_io_isFlush),
    .io_in_ready(g_v9_io_in_ready),
    .io_out_valid(g_v9_io_out_valid),
    .io_out_bits_fuType(g_v9_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v9_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v9_io_out_bits_src_0),
    .io_out_bits_src_1(g_v9_io_out_bits_src_1),
    .io_out_bits_robIdx_flag(g_v9_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v9_io_out_bits_robIdx_value),
    .io_out_bits_pdest(g_v9_io_out_bits_pdest),
    .io_out_bits_fpWen(g_v9_io_out_bits_fpWen),
    .io_out_bits_fpu_wflags(g_v9_io_out_bits_fpu_wflags),
    .io_out_bits_fpu_fmt(g_v9_io_out_bits_fpu_fmt),
    .io_out_bits_fpu_rm(g_v9_io_out_bits_fpu_rm),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v9_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v9_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v9_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v9_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v9_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v9_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v9_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v9_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v9_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v9_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v9_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v9_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_9_xs u_i_v9 (
    .clock(clock), .reset(reset),
    .io_in_valid(v9_io_in_valid),
    .io_in_bits_fuType(v9_io_in_bits_fuType),
    .io_in_bits_fuOpType(v9_io_in_bits_fuOpType),
    .io_in_bits_src_0(v9_io_in_bits_src_0),
    .io_in_bits_src_1(v9_io_in_bits_src_1),
    .io_in_bits_robIdx_flag(v9_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v9_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v9_io_in_bits_pdest),
    .io_in_bits_fpWen(v9_io_in_bits_fpWen),
    .io_in_bits_fpu_wflags(v9_io_in_bits_fpu_wflags),
    .io_in_bits_fpu_fmt(v9_io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm(v9_io_in_bits_fpu_rm),
    .io_in_bits_perfDebugInfo_eliminatedMove(v9_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v9_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v9_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v9_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v9_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v9_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v9_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v9_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v9_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v9_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v9_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v9_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v9_io_out_ready),
    .io_rightOutFire(v9_io_rightOutFire),
    .io_isFlush(v9_io_isFlush),
    .io_in_ready(i_v9_io_in_ready),
    .io_out_valid(i_v9_io_out_valid),
    .io_out_bits_fuType(i_v9_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v9_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v9_io_out_bits_src_0),
    .io_out_bits_src_1(i_v9_io_out_bits_src_1),
    .io_out_bits_robIdx_flag(i_v9_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v9_io_out_bits_robIdx_value),
    .io_out_bits_pdest(i_v9_io_out_bits_pdest),
    .io_out_bits_fpWen(i_v9_io_out_bits_fpWen),
    .io_out_bits_fpu_wflags(i_v9_io_out_bits_fpu_wflags),
    .io_out_bits_fpu_fmt(i_v9_io_out_bits_fpu_fmt),
    .io_out_bits_fpu_rm(i_v9_io_out_bits_fpu_rm),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v9_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v9_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v9_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v9_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v9_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v9_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v9_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v9_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v9_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v9_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v9_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v9_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_10 —— 25 字段 / 902 位 payload
  // ==========================================================================
  logic v10_io_in_valid;
  logic [34:0] v10_io_in_bits_fuType;
  logic [8:0] v10_io_in_bits_fuOpType;
  logic [63:0] v10_io_in_bits_src_0;
  logic [63:0] v10_io_in_bits_src_1;
  logic [63:0] v10_io_in_bits_src_2;
  logic v10_io_in_bits_robIdx_flag;
  logic [7:0] v10_io_in_bits_robIdx_value;
  logic [7:0] v10_io_in_bits_pdest;
  logic v10_io_in_bits_rfWen;
  logic v10_io_in_bits_fpWen;
  logic v10_io_in_bits_fpu_wflags;
  logic [1:0] v10_io_in_bits_fpu_fmt;
  logic [2:0] v10_io_in_bits_fpu_rm;
  logic v10_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v10_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v10_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v10_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v10_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v10_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v10_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v10_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v10_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v10_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v10_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v10_io_in_bits_debug_seqNum_uopIdx;
  logic v10_io_out_ready;
  logic v10_io_rightOutFire;
  logic v10_io_isFlush;
  wire  g_v10_io_in_ready, i_v10_io_in_ready;
  wire  g_v10_io_out_valid, i_v10_io_out_valid;
  wire  [34:0] g_v10_io_out_bits_fuType, i_v10_io_out_bits_fuType;
  wire  [8:0] g_v10_io_out_bits_fuOpType, i_v10_io_out_bits_fuOpType;
  wire  [63:0] g_v10_io_out_bits_src_0, i_v10_io_out_bits_src_0;
  wire  [63:0] g_v10_io_out_bits_src_1, i_v10_io_out_bits_src_1;
  wire  [63:0] g_v10_io_out_bits_src_2, i_v10_io_out_bits_src_2;
  wire  g_v10_io_out_bits_robIdx_flag, i_v10_io_out_bits_robIdx_flag;
  wire  [7:0] g_v10_io_out_bits_robIdx_value, i_v10_io_out_bits_robIdx_value;
  wire  [7:0] g_v10_io_out_bits_pdest, i_v10_io_out_bits_pdest;
  wire  g_v10_io_out_bits_rfWen, i_v10_io_out_bits_rfWen;
  wire  g_v10_io_out_bits_fpWen, i_v10_io_out_bits_fpWen;
  wire  g_v10_io_out_bits_fpu_wflags, i_v10_io_out_bits_fpu_wflags;
  wire  [1:0] g_v10_io_out_bits_fpu_fmt, i_v10_io_out_bits_fpu_fmt;
  wire  [2:0] g_v10_io_out_bits_fpu_rm, i_v10_io_out_bits_fpu_rm;
  wire  g_v10_io_out_bits_perfDebugInfo_eliminatedMove, i_v10_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v10_io_out_bits_perfDebugInfo_renameTime, i_v10_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v10_io_out_bits_perfDebugInfo_dispatchTime, i_v10_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v10_io_out_bits_perfDebugInfo_enqRsTime, i_v10_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v10_io_out_bits_perfDebugInfo_selectTime, i_v10_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v10_io_out_bits_perfDebugInfo_issueTime, i_v10_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v10_io_out_bits_perfDebugInfo_writebackTime, i_v10_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v10_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v10_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v10_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v10_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v10_io_out_bits_perfDebugInfo_tlbRespTime, i_v10_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v10_io_out_bits_debug_seqNum_seqNum, i_v10_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v10_io_out_bits_debug_seqNum_uopIdx, i_v10_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v10 = 0; int nerr_v10 = 0;
  longint fire_v10 = 0, bp_v10 = 0, flush_v10 = 0, hold_v10 = 0, ov_v10 = 0;
  logic [901:0] por_v10 = '0, pand_v10 = '1;   // payload 按位或 / 按位与
  wire  [901:0] pcat_v10 = {v10_io_in_bits_fuType, v10_io_in_bits_fuOpType, v10_io_in_bits_src_0, v10_io_in_bits_src_1, v10_io_in_bits_src_2, v10_io_in_bits_robIdx_flag, v10_io_in_bits_robIdx_value, v10_io_in_bits_pdest, v10_io_in_bits_rfWen, v10_io_in_bits_fpWen, v10_io_in_bits_fpu_wflags, v10_io_in_bits_fpu_fmt, v10_io_in_bits_fpu_rm, v10_io_in_bits_perfDebugInfo_eliminatedMove, v10_io_in_bits_perfDebugInfo_renameTime, v10_io_in_bits_perfDebugInfo_dispatchTime, v10_io_in_bits_perfDebugInfo_enqRsTime, v10_io_in_bits_perfDebugInfo_selectTime, v10_io_in_bits_perfDebugInfo_issueTime, v10_io_in_bits_perfDebugInfo_writebackTime, v10_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v10_io_in_bits_perfDebugInfo_tlbFirstReqTime, v10_io_in_bits_perfDebugInfo_tlbRespTime, v10_io_in_bits_debug_seqNum_seqNum, v10_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe_10 u_g_v10 (
    .clock(clock), .reset(reset),
    .io_in_valid(v10_io_in_valid),
    .io_in_bits_fuType(v10_io_in_bits_fuType),
    .io_in_bits_fuOpType(v10_io_in_bits_fuOpType),
    .io_in_bits_src_0(v10_io_in_bits_src_0),
    .io_in_bits_src_1(v10_io_in_bits_src_1),
    .io_in_bits_src_2(v10_io_in_bits_src_2),
    .io_in_bits_robIdx_flag(v10_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v10_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v10_io_in_bits_pdest),
    .io_in_bits_rfWen(v10_io_in_bits_rfWen),
    .io_in_bits_fpWen(v10_io_in_bits_fpWen),
    .io_in_bits_fpu_wflags(v10_io_in_bits_fpu_wflags),
    .io_in_bits_fpu_fmt(v10_io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm(v10_io_in_bits_fpu_rm),
    .io_in_bits_perfDebugInfo_eliminatedMove(v10_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v10_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v10_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v10_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v10_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v10_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v10_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v10_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v10_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v10_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v10_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v10_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v10_io_out_ready),
    .io_rightOutFire(v10_io_rightOutFire),
    .io_isFlush(v10_io_isFlush),
    .io_in_ready(g_v10_io_in_ready),
    .io_out_valid(g_v10_io_out_valid),
    .io_out_bits_fuType(g_v10_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v10_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v10_io_out_bits_src_0),
    .io_out_bits_src_1(g_v10_io_out_bits_src_1),
    .io_out_bits_src_2(g_v10_io_out_bits_src_2),
    .io_out_bits_robIdx_flag(g_v10_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v10_io_out_bits_robIdx_value),
    .io_out_bits_pdest(g_v10_io_out_bits_pdest),
    .io_out_bits_rfWen(g_v10_io_out_bits_rfWen),
    .io_out_bits_fpWen(g_v10_io_out_bits_fpWen),
    .io_out_bits_fpu_wflags(g_v10_io_out_bits_fpu_wflags),
    .io_out_bits_fpu_fmt(g_v10_io_out_bits_fpu_fmt),
    .io_out_bits_fpu_rm(g_v10_io_out_bits_fpu_rm),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v10_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v10_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v10_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v10_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v10_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v10_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v10_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v10_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v10_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v10_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v10_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v10_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_10_xs u_i_v10 (
    .clock(clock), .reset(reset),
    .io_in_valid(v10_io_in_valid),
    .io_in_bits_fuType(v10_io_in_bits_fuType),
    .io_in_bits_fuOpType(v10_io_in_bits_fuOpType),
    .io_in_bits_src_0(v10_io_in_bits_src_0),
    .io_in_bits_src_1(v10_io_in_bits_src_1),
    .io_in_bits_src_2(v10_io_in_bits_src_2),
    .io_in_bits_robIdx_flag(v10_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v10_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v10_io_in_bits_pdest),
    .io_in_bits_rfWen(v10_io_in_bits_rfWen),
    .io_in_bits_fpWen(v10_io_in_bits_fpWen),
    .io_in_bits_fpu_wflags(v10_io_in_bits_fpu_wflags),
    .io_in_bits_fpu_fmt(v10_io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm(v10_io_in_bits_fpu_rm),
    .io_in_bits_perfDebugInfo_eliminatedMove(v10_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v10_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v10_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v10_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v10_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v10_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v10_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v10_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v10_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v10_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v10_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v10_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v10_io_out_ready),
    .io_rightOutFire(v10_io_rightOutFire),
    .io_isFlush(v10_io_isFlush),
    .io_in_ready(i_v10_io_in_ready),
    .io_out_valid(i_v10_io_out_valid),
    .io_out_bits_fuType(i_v10_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v10_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v10_io_out_bits_src_0),
    .io_out_bits_src_1(i_v10_io_out_bits_src_1),
    .io_out_bits_src_2(i_v10_io_out_bits_src_2),
    .io_out_bits_robIdx_flag(i_v10_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v10_io_out_bits_robIdx_value),
    .io_out_bits_pdest(i_v10_io_out_bits_pdest),
    .io_out_bits_rfWen(i_v10_io_out_bits_rfWen),
    .io_out_bits_fpWen(i_v10_io_out_bits_fpWen),
    .io_out_bits_fpu_wflags(i_v10_io_out_bits_fpu_wflags),
    .io_out_bits_fpu_fmt(i_v10_io_out_bits_fpu_fmt),
    .io_out_bits_fpu_rm(i_v10_io_out_bits_fpu_rm),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v10_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v10_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v10_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v10_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v10_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v10_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v10_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v10_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v10_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v10_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v10_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v10_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_13 —— 36 字段 / 1371 位 payload
  // ==========================================================================
  logic v13_io_in_valid;
  logic [34:0] v13_io_in_bits_fuType;
  logic [8:0] v13_io_in_bits_fuOpType;
  logic [127:0] v13_io_in_bits_src_0;
  logic [127:0] v13_io_in_bits_src_1;
  logic [127:0] v13_io_in_bits_src_2;
  logic [127:0] v13_io_in_bits_src_3;
  logic [127:0] v13_io_in_bits_src_4;
  logic v13_io_in_bits_robIdx_flag;
  logic [7:0] v13_io_in_bits_robIdx_value;
  logic [6:0] v13_io_in_bits_pdest;
  logic v13_io_in_bits_vecWen;
  logic v13_io_in_bits_v0Wen;
  logic v13_io_in_bits_fpu_wflags;
  logic v13_io_in_bits_vpu_vma;
  logic v13_io_in_bits_vpu_vta;
  logic [1:0] v13_io_in_bits_vpu_vsew;
  logic [2:0] v13_io_in_bits_vpu_vlmul;
  logic v13_io_in_bits_vpu_vm;
  logic [7:0] v13_io_in_bits_vpu_vstart;
  logic [6:0] v13_io_in_bits_vpu_vuopIdx;
  logic v13_io_in_bits_vpu_isExt;
  logic v13_io_in_bits_vpu_isNarrow;
  logic v13_io_in_bits_vpu_isDstMask;
  logic v13_io_in_bits_vpu_isOpMask;
  logic v13_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v13_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v13_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v13_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v13_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v13_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v13_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v13_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v13_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v13_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v13_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v13_io_in_bits_debug_seqNum_uopIdx;
  logic v13_io_out_ready;
  logic v13_io_rightOutFire;
  logic v13_io_isFlush;
  wire  g_v13_io_in_ready, i_v13_io_in_ready;
  wire  g_v13_io_out_valid, i_v13_io_out_valid;
  wire  [34:0] g_v13_io_out_bits_fuType, i_v13_io_out_bits_fuType;
  wire  [8:0] g_v13_io_out_bits_fuOpType, i_v13_io_out_bits_fuOpType;
  wire  [127:0] g_v13_io_out_bits_src_0, i_v13_io_out_bits_src_0;
  wire  [127:0] g_v13_io_out_bits_src_1, i_v13_io_out_bits_src_1;
  wire  [127:0] g_v13_io_out_bits_src_2, i_v13_io_out_bits_src_2;
  wire  [127:0] g_v13_io_out_bits_src_3, i_v13_io_out_bits_src_3;
  wire  [127:0] g_v13_io_out_bits_src_4, i_v13_io_out_bits_src_4;
  wire  g_v13_io_out_bits_robIdx_flag, i_v13_io_out_bits_robIdx_flag;
  wire  [7:0] g_v13_io_out_bits_robIdx_value, i_v13_io_out_bits_robIdx_value;
  wire  [6:0] g_v13_io_out_bits_pdest, i_v13_io_out_bits_pdest;
  wire  g_v13_io_out_bits_vecWen, i_v13_io_out_bits_vecWen;
  wire  g_v13_io_out_bits_v0Wen, i_v13_io_out_bits_v0Wen;
  wire  g_v13_io_out_bits_fpu_wflags, i_v13_io_out_bits_fpu_wflags;
  wire  g_v13_io_out_bits_vpu_vma, i_v13_io_out_bits_vpu_vma;
  wire  g_v13_io_out_bits_vpu_vta, i_v13_io_out_bits_vpu_vta;
  wire  [1:0] g_v13_io_out_bits_vpu_vsew, i_v13_io_out_bits_vpu_vsew;
  wire  [2:0] g_v13_io_out_bits_vpu_vlmul, i_v13_io_out_bits_vpu_vlmul;
  wire  g_v13_io_out_bits_vpu_vm, i_v13_io_out_bits_vpu_vm;
  wire  [7:0] g_v13_io_out_bits_vpu_vstart, i_v13_io_out_bits_vpu_vstart;
  wire  [6:0] g_v13_io_out_bits_vpu_vuopIdx, i_v13_io_out_bits_vpu_vuopIdx;
  wire  g_v13_io_out_bits_vpu_isExt, i_v13_io_out_bits_vpu_isExt;
  wire  g_v13_io_out_bits_vpu_isNarrow, i_v13_io_out_bits_vpu_isNarrow;
  wire  g_v13_io_out_bits_vpu_isDstMask, i_v13_io_out_bits_vpu_isDstMask;
  wire  g_v13_io_out_bits_vpu_isOpMask, i_v13_io_out_bits_vpu_isOpMask;
  wire  g_v13_io_out_bits_perfDebugInfo_eliminatedMove, i_v13_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v13_io_out_bits_perfDebugInfo_renameTime, i_v13_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v13_io_out_bits_perfDebugInfo_dispatchTime, i_v13_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v13_io_out_bits_perfDebugInfo_enqRsTime, i_v13_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v13_io_out_bits_perfDebugInfo_selectTime, i_v13_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v13_io_out_bits_perfDebugInfo_issueTime, i_v13_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v13_io_out_bits_perfDebugInfo_writebackTime, i_v13_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v13_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v13_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v13_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v13_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v13_io_out_bits_perfDebugInfo_tlbRespTime, i_v13_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v13_io_out_bits_debug_seqNum_seqNum, i_v13_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v13_io_out_bits_debug_seqNum_uopIdx, i_v13_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v13 = 0; int nerr_v13 = 0;
  longint fire_v13 = 0, bp_v13 = 0, flush_v13 = 0, hold_v13 = 0, ov_v13 = 0;
  logic [1370:0] por_v13 = '0, pand_v13 = '1;   // payload 按位或 / 按位与
  wire  [1370:0] pcat_v13 = {v13_io_in_bits_fuType, v13_io_in_bits_fuOpType, v13_io_in_bits_src_0, v13_io_in_bits_src_1, v13_io_in_bits_src_2, v13_io_in_bits_src_3, v13_io_in_bits_src_4, v13_io_in_bits_robIdx_flag, v13_io_in_bits_robIdx_value, v13_io_in_bits_pdest, v13_io_in_bits_vecWen, v13_io_in_bits_v0Wen, v13_io_in_bits_fpu_wflags, v13_io_in_bits_vpu_vma, v13_io_in_bits_vpu_vta, v13_io_in_bits_vpu_vsew, v13_io_in_bits_vpu_vlmul, v13_io_in_bits_vpu_vm, v13_io_in_bits_vpu_vstart, v13_io_in_bits_vpu_vuopIdx, v13_io_in_bits_vpu_isExt, v13_io_in_bits_vpu_isNarrow, v13_io_in_bits_vpu_isDstMask, v13_io_in_bits_vpu_isOpMask, v13_io_in_bits_perfDebugInfo_eliminatedMove, v13_io_in_bits_perfDebugInfo_renameTime, v13_io_in_bits_perfDebugInfo_dispatchTime, v13_io_in_bits_perfDebugInfo_enqRsTime, v13_io_in_bits_perfDebugInfo_selectTime, v13_io_in_bits_perfDebugInfo_issueTime, v13_io_in_bits_perfDebugInfo_writebackTime, v13_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v13_io_in_bits_perfDebugInfo_tlbFirstReqTime, v13_io_in_bits_perfDebugInfo_tlbRespTime, v13_io_in_bits_debug_seqNum_seqNum, v13_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe_13 u_g_v13 (
    .clock(clock), .reset(reset),
    .io_in_valid(v13_io_in_valid),
    .io_in_bits_fuType(v13_io_in_bits_fuType),
    .io_in_bits_fuOpType(v13_io_in_bits_fuOpType),
    .io_in_bits_src_0(v13_io_in_bits_src_0),
    .io_in_bits_src_1(v13_io_in_bits_src_1),
    .io_in_bits_src_2(v13_io_in_bits_src_2),
    .io_in_bits_src_3(v13_io_in_bits_src_3),
    .io_in_bits_src_4(v13_io_in_bits_src_4),
    .io_in_bits_robIdx_flag(v13_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v13_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v13_io_in_bits_pdest),
    .io_in_bits_vecWen(v13_io_in_bits_vecWen),
    .io_in_bits_v0Wen(v13_io_in_bits_v0Wen),
    .io_in_bits_fpu_wflags(v13_io_in_bits_fpu_wflags),
    .io_in_bits_vpu_vma(v13_io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta(v13_io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew(v13_io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul(v13_io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_vm(v13_io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart(v13_io_in_bits_vpu_vstart),
    .io_in_bits_vpu_vuopIdx(v13_io_in_bits_vpu_vuopIdx),
    .io_in_bits_vpu_isExt(v13_io_in_bits_vpu_isExt),
    .io_in_bits_vpu_isNarrow(v13_io_in_bits_vpu_isNarrow),
    .io_in_bits_vpu_isDstMask(v13_io_in_bits_vpu_isDstMask),
    .io_in_bits_vpu_isOpMask(v13_io_in_bits_vpu_isOpMask),
    .io_in_bits_perfDebugInfo_eliminatedMove(v13_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v13_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v13_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v13_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v13_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v13_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v13_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v13_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v13_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v13_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v13_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v13_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v13_io_out_ready),
    .io_rightOutFire(v13_io_rightOutFire),
    .io_isFlush(v13_io_isFlush),
    .io_in_ready(g_v13_io_in_ready),
    .io_out_valid(g_v13_io_out_valid),
    .io_out_bits_fuType(g_v13_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v13_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v13_io_out_bits_src_0),
    .io_out_bits_src_1(g_v13_io_out_bits_src_1),
    .io_out_bits_src_2(g_v13_io_out_bits_src_2),
    .io_out_bits_src_3(g_v13_io_out_bits_src_3),
    .io_out_bits_src_4(g_v13_io_out_bits_src_4),
    .io_out_bits_robIdx_flag(g_v13_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v13_io_out_bits_robIdx_value),
    .io_out_bits_pdest(g_v13_io_out_bits_pdest),
    .io_out_bits_vecWen(g_v13_io_out_bits_vecWen),
    .io_out_bits_v0Wen(g_v13_io_out_bits_v0Wen),
    .io_out_bits_fpu_wflags(g_v13_io_out_bits_fpu_wflags),
    .io_out_bits_vpu_vma(g_v13_io_out_bits_vpu_vma),
    .io_out_bits_vpu_vta(g_v13_io_out_bits_vpu_vta),
    .io_out_bits_vpu_vsew(g_v13_io_out_bits_vpu_vsew),
    .io_out_bits_vpu_vlmul(g_v13_io_out_bits_vpu_vlmul),
    .io_out_bits_vpu_vm(g_v13_io_out_bits_vpu_vm),
    .io_out_bits_vpu_vstart(g_v13_io_out_bits_vpu_vstart),
    .io_out_bits_vpu_vuopIdx(g_v13_io_out_bits_vpu_vuopIdx),
    .io_out_bits_vpu_isExt(g_v13_io_out_bits_vpu_isExt),
    .io_out_bits_vpu_isNarrow(g_v13_io_out_bits_vpu_isNarrow),
    .io_out_bits_vpu_isDstMask(g_v13_io_out_bits_vpu_isDstMask),
    .io_out_bits_vpu_isOpMask(g_v13_io_out_bits_vpu_isOpMask),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v13_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v13_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v13_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v13_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v13_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v13_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v13_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v13_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v13_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v13_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v13_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v13_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_13_xs u_i_v13 (
    .clock(clock), .reset(reset),
    .io_in_valid(v13_io_in_valid),
    .io_in_bits_fuType(v13_io_in_bits_fuType),
    .io_in_bits_fuOpType(v13_io_in_bits_fuOpType),
    .io_in_bits_src_0(v13_io_in_bits_src_0),
    .io_in_bits_src_1(v13_io_in_bits_src_1),
    .io_in_bits_src_2(v13_io_in_bits_src_2),
    .io_in_bits_src_3(v13_io_in_bits_src_3),
    .io_in_bits_src_4(v13_io_in_bits_src_4),
    .io_in_bits_robIdx_flag(v13_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v13_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v13_io_in_bits_pdest),
    .io_in_bits_vecWen(v13_io_in_bits_vecWen),
    .io_in_bits_v0Wen(v13_io_in_bits_v0Wen),
    .io_in_bits_fpu_wflags(v13_io_in_bits_fpu_wflags),
    .io_in_bits_vpu_vma(v13_io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta(v13_io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew(v13_io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul(v13_io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_vm(v13_io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart(v13_io_in_bits_vpu_vstart),
    .io_in_bits_vpu_vuopIdx(v13_io_in_bits_vpu_vuopIdx),
    .io_in_bits_vpu_isExt(v13_io_in_bits_vpu_isExt),
    .io_in_bits_vpu_isNarrow(v13_io_in_bits_vpu_isNarrow),
    .io_in_bits_vpu_isDstMask(v13_io_in_bits_vpu_isDstMask),
    .io_in_bits_vpu_isOpMask(v13_io_in_bits_vpu_isOpMask),
    .io_in_bits_perfDebugInfo_eliminatedMove(v13_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v13_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v13_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v13_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v13_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v13_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v13_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v13_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v13_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v13_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v13_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v13_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v13_io_out_ready),
    .io_rightOutFire(v13_io_rightOutFire),
    .io_isFlush(v13_io_isFlush),
    .io_in_ready(i_v13_io_in_ready),
    .io_out_valid(i_v13_io_out_valid),
    .io_out_bits_fuType(i_v13_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v13_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v13_io_out_bits_src_0),
    .io_out_bits_src_1(i_v13_io_out_bits_src_1),
    .io_out_bits_src_2(i_v13_io_out_bits_src_2),
    .io_out_bits_src_3(i_v13_io_out_bits_src_3),
    .io_out_bits_src_4(i_v13_io_out_bits_src_4),
    .io_out_bits_robIdx_flag(i_v13_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v13_io_out_bits_robIdx_value),
    .io_out_bits_pdest(i_v13_io_out_bits_pdest),
    .io_out_bits_vecWen(i_v13_io_out_bits_vecWen),
    .io_out_bits_v0Wen(i_v13_io_out_bits_v0Wen),
    .io_out_bits_fpu_wflags(i_v13_io_out_bits_fpu_wflags),
    .io_out_bits_vpu_vma(i_v13_io_out_bits_vpu_vma),
    .io_out_bits_vpu_vta(i_v13_io_out_bits_vpu_vta),
    .io_out_bits_vpu_vsew(i_v13_io_out_bits_vpu_vsew),
    .io_out_bits_vpu_vlmul(i_v13_io_out_bits_vpu_vlmul),
    .io_out_bits_vpu_vm(i_v13_io_out_bits_vpu_vm),
    .io_out_bits_vpu_vstart(i_v13_io_out_bits_vpu_vstart),
    .io_out_bits_vpu_vuopIdx(i_v13_io_out_bits_vpu_vuopIdx),
    .io_out_bits_vpu_isExt(i_v13_io_out_bits_vpu_isExt),
    .io_out_bits_vpu_isNarrow(i_v13_io_out_bits_vpu_isNarrow),
    .io_out_bits_vpu_isDstMask(i_v13_io_out_bits_vpu_isDstMask),
    .io_out_bits_vpu_isOpMask(i_v13_io_out_bits_vpu_isOpMask),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v13_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v13_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v13_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v13_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v13_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v13_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v13_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v13_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v13_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v13_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v13_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v13_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_14 —— 41 字段 / 1377 位 payload
  // ==========================================================================
  logic v14_io_in_valid;
  logic [34:0] v14_io_in_bits_fuType;
  logic [8:0] v14_io_in_bits_fuOpType;
  logic [127:0] v14_io_in_bits_src_0;
  logic [127:0] v14_io_in_bits_src_1;
  logic [127:0] v14_io_in_bits_src_2;
  logic [127:0] v14_io_in_bits_src_3;
  logic [127:0] v14_io_in_bits_src_4;
  logic v14_io_in_bits_robIdx_flag;
  logic [7:0] v14_io_in_bits_robIdx_value;
  logic [7:0] v14_io_in_bits_pdest;
  logic v14_io_in_bits_rfWen;
  logic v14_io_in_bits_fpWen;
  logic v14_io_in_bits_vecWen;
  logic v14_io_in_bits_v0Wen;
  logic v14_io_in_bits_vlWen;
  logic v14_io_in_bits_fpu_wflags;
  logic v14_io_in_bits_vpu_vma;
  logic v14_io_in_bits_vpu_vta;
  logic [1:0] v14_io_in_bits_vpu_vsew;
  logic [2:0] v14_io_in_bits_vpu_vlmul;
  logic v14_io_in_bits_vpu_vm;
  logic [7:0] v14_io_in_bits_vpu_vstart;
  logic v14_io_in_bits_vpu_fpu_isFoldTo1_2;
  logic v14_io_in_bits_vpu_fpu_isFoldTo1_4;
  logic v14_io_in_bits_vpu_fpu_isFoldTo1_8;
  logic [6:0] v14_io_in_bits_vpu_vuopIdx;
  logic v14_io_in_bits_vpu_lastUop;
  logic v14_io_in_bits_vpu_isNarrow;
  logic v14_io_in_bits_vpu_isDstMask;
  logic v14_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v14_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v14_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v14_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v14_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v14_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v14_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v14_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v14_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v14_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v14_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v14_io_in_bits_debug_seqNum_uopIdx;
  logic v14_io_out_ready;
  logic v14_io_rightOutFire;
  logic v14_io_isFlush;
  wire  g_v14_io_in_ready, i_v14_io_in_ready;
  wire  g_v14_io_out_valid, i_v14_io_out_valid;
  wire  [34:0] g_v14_io_out_bits_fuType, i_v14_io_out_bits_fuType;
  wire  [8:0] g_v14_io_out_bits_fuOpType, i_v14_io_out_bits_fuOpType;
  wire  [127:0] g_v14_io_out_bits_src_0, i_v14_io_out_bits_src_0;
  wire  [127:0] g_v14_io_out_bits_src_1, i_v14_io_out_bits_src_1;
  wire  [127:0] g_v14_io_out_bits_src_2, i_v14_io_out_bits_src_2;
  wire  [127:0] g_v14_io_out_bits_src_3, i_v14_io_out_bits_src_3;
  wire  [127:0] g_v14_io_out_bits_src_4, i_v14_io_out_bits_src_4;
  wire  g_v14_io_out_bits_robIdx_flag, i_v14_io_out_bits_robIdx_flag;
  wire  [7:0] g_v14_io_out_bits_robIdx_value, i_v14_io_out_bits_robIdx_value;
  wire  [7:0] g_v14_io_out_bits_pdest, i_v14_io_out_bits_pdest;
  wire  g_v14_io_out_bits_rfWen, i_v14_io_out_bits_rfWen;
  wire  g_v14_io_out_bits_fpWen, i_v14_io_out_bits_fpWen;
  wire  g_v14_io_out_bits_vecWen, i_v14_io_out_bits_vecWen;
  wire  g_v14_io_out_bits_v0Wen, i_v14_io_out_bits_v0Wen;
  wire  g_v14_io_out_bits_vlWen, i_v14_io_out_bits_vlWen;
  wire  g_v14_io_out_bits_fpu_wflags, i_v14_io_out_bits_fpu_wflags;
  wire  g_v14_io_out_bits_vpu_vma, i_v14_io_out_bits_vpu_vma;
  wire  g_v14_io_out_bits_vpu_vta, i_v14_io_out_bits_vpu_vta;
  wire  [1:0] g_v14_io_out_bits_vpu_vsew, i_v14_io_out_bits_vpu_vsew;
  wire  [2:0] g_v14_io_out_bits_vpu_vlmul, i_v14_io_out_bits_vpu_vlmul;
  wire  g_v14_io_out_bits_vpu_vm, i_v14_io_out_bits_vpu_vm;
  wire  [7:0] g_v14_io_out_bits_vpu_vstart, i_v14_io_out_bits_vpu_vstart;
  wire  g_v14_io_out_bits_vpu_fpu_isFoldTo1_2, i_v14_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire  g_v14_io_out_bits_vpu_fpu_isFoldTo1_4, i_v14_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire  g_v14_io_out_bits_vpu_fpu_isFoldTo1_8, i_v14_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire  [6:0] g_v14_io_out_bits_vpu_vuopIdx, i_v14_io_out_bits_vpu_vuopIdx;
  wire  g_v14_io_out_bits_vpu_lastUop, i_v14_io_out_bits_vpu_lastUop;
  wire  g_v14_io_out_bits_vpu_isNarrow, i_v14_io_out_bits_vpu_isNarrow;
  wire  g_v14_io_out_bits_vpu_isDstMask, i_v14_io_out_bits_vpu_isDstMask;
  wire  g_v14_io_out_bits_perfDebugInfo_eliminatedMove, i_v14_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v14_io_out_bits_perfDebugInfo_renameTime, i_v14_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v14_io_out_bits_perfDebugInfo_dispatchTime, i_v14_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v14_io_out_bits_perfDebugInfo_enqRsTime, i_v14_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v14_io_out_bits_perfDebugInfo_selectTime, i_v14_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v14_io_out_bits_perfDebugInfo_issueTime, i_v14_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v14_io_out_bits_perfDebugInfo_writebackTime, i_v14_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v14_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v14_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v14_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v14_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v14_io_out_bits_perfDebugInfo_tlbRespTime, i_v14_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v14_io_out_bits_debug_seqNum_seqNum, i_v14_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v14_io_out_bits_debug_seqNum_uopIdx, i_v14_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v14 = 0; int nerr_v14 = 0;
  longint fire_v14 = 0, bp_v14 = 0, flush_v14 = 0, hold_v14 = 0, ov_v14 = 0;
  logic [1376:0] por_v14 = '0, pand_v14 = '1;   // payload 按位或 / 按位与
  wire  [1376:0] pcat_v14 = {v14_io_in_bits_fuType, v14_io_in_bits_fuOpType, v14_io_in_bits_src_0, v14_io_in_bits_src_1, v14_io_in_bits_src_2, v14_io_in_bits_src_3, v14_io_in_bits_src_4, v14_io_in_bits_robIdx_flag, v14_io_in_bits_robIdx_value, v14_io_in_bits_pdest, v14_io_in_bits_rfWen, v14_io_in_bits_fpWen, v14_io_in_bits_vecWen, v14_io_in_bits_v0Wen, v14_io_in_bits_vlWen, v14_io_in_bits_fpu_wflags, v14_io_in_bits_vpu_vma, v14_io_in_bits_vpu_vta, v14_io_in_bits_vpu_vsew, v14_io_in_bits_vpu_vlmul, v14_io_in_bits_vpu_vm, v14_io_in_bits_vpu_vstart, v14_io_in_bits_vpu_fpu_isFoldTo1_2, v14_io_in_bits_vpu_fpu_isFoldTo1_4, v14_io_in_bits_vpu_fpu_isFoldTo1_8, v14_io_in_bits_vpu_vuopIdx, v14_io_in_bits_vpu_lastUop, v14_io_in_bits_vpu_isNarrow, v14_io_in_bits_vpu_isDstMask, v14_io_in_bits_perfDebugInfo_eliminatedMove, v14_io_in_bits_perfDebugInfo_renameTime, v14_io_in_bits_perfDebugInfo_dispatchTime, v14_io_in_bits_perfDebugInfo_enqRsTime, v14_io_in_bits_perfDebugInfo_selectTime, v14_io_in_bits_perfDebugInfo_issueTime, v14_io_in_bits_perfDebugInfo_writebackTime, v14_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v14_io_in_bits_perfDebugInfo_tlbFirstReqTime, v14_io_in_bits_perfDebugInfo_tlbRespTime, v14_io_in_bits_debug_seqNum_seqNum, v14_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe_14 u_g_v14 (
    .clock(clock), .reset(reset),
    .io_in_valid(v14_io_in_valid),
    .io_in_bits_fuType(v14_io_in_bits_fuType),
    .io_in_bits_fuOpType(v14_io_in_bits_fuOpType),
    .io_in_bits_src_0(v14_io_in_bits_src_0),
    .io_in_bits_src_1(v14_io_in_bits_src_1),
    .io_in_bits_src_2(v14_io_in_bits_src_2),
    .io_in_bits_src_3(v14_io_in_bits_src_3),
    .io_in_bits_src_4(v14_io_in_bits_src_4),
    .io_in_bits_robIdx_flag(v14_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v14_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v14_io_in_bits_pdest),
    .io_in_bits_rfWen(v14_io_in_bits_rfWen),
    .io_in_bits_fpWen(v14_io_in_bits_fpWen),
    .io_in_bits_vecWen(v14_io_in_bits_vecWen),
    .io_in_bits_v0Wen(v14_io_in_bits_v0Wen),
    .io_in_bits_vlWen(v14_io_in_bits_vlWen),
    .io_in_bits_fpu_wflags(v14_io_in_bits_fpu_wflags),
    .io_in_bits_vpu_vma(v14_io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta(v14_io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew(v14_io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul(v14_io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_vm(v14_io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart(v14_io_in_bits_vpu_vstart),
    .io_in_bits_vpu_fpu_isFoldTo1_2(v14_io_in_bits_vpu_fpu_isFoldTo1_2),
    .io_in_bits_vpu_fpu_isFoldTo1_4(v14_io_in_bits_vpu_fpu_isFoldTo1_4),
    .io_in_bits_vpu_fpu_isFoldTo1_8(v14_io_in_bits_vpu_fpu_isFoldTo1_8),
    .io_in_bits_vpu_vuopIdx(v14_io_in_bits_vpu_vuopIdx),
    .io_in_bits_vpu_lastUop(v14_io_in_bits_vpu_lastUop),
    .io_in_bits_vpu_isNarrow(v14_io_in_bits_vpu_isNarrow),
    .io_in_bits_vpu_isDstMask(v14_io_in_bits_vpu_isDstMask),
    .io_in_bits_perfDebugInfo_eliminatedMove(v14_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v14_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v14_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v14_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v14_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v14_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v14_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v14_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v14_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v14_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v14_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v14_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v14_io_out_ready),
    .io_rightOutFire(v14_io_rightOutFire),
    .io_isFlush(v14_io_isFlush),
    .io_in_ready(g_v14_io_in_ready),
    .io_out_valid(g_v14_io_out_valid),
    .io_out_bits_fuType(g_v14_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v14_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v14_io_out_bits_src_0),
    .io_out_bits_src_1(g_v14_io_out_bits_src_1),
    .io_out_bits_src_2(g_v14_io_out_bits_src_2),
    .io_out_bits_src_3(g_v14_io_out_bits_src_3),
    .io_out_bits_src_4(g_v14_io_out_bits_src_4),
    .io_out_bits_robIdx_flag(g_v14_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v14_io_out_bits_robIdx_value),
    .io_out_bits_pdest(g_v14_io_out_bits_pdest),
    .io_out_bits_rfWen(g_v14_io_out_bits_rfWen),
    .io_out_bits_fpWen(g_v14_io_out_bits_fpWen),
    .io_out_bits_vecWen(g_v14_io_out_bits_vecWen),
    .io_out_bits_v0Wen(g_v14_io_out_bits_v0Wen),
    .io_out_bits_vlWen(g_v14_io_out_bits_vlWen),
    .io_out_bits_fpu_wflags(g_v14_io_out_bits_fpu_wflags),
    .io_out_bits_vpu_vma(g_v14_io_out_bits_vpu_vma),
    .io_out_bits_vpu_vta(g_v14_io_out_bits_vpu_vta),
    .io_out_bits_vpu_vsew(g_v14_io_out_bits_vpu_vsew),
    .io_out_bits_vpu_vlmul(g_v14_io_out_bits_vpu_vlmul),
    .io_out_bits_vpu_vm(g_v14_io_out_bits_vpu_vm),
    .io_out_bits_vpu_vstart(g_v14_io_out_bits_vpu_vstart),
    .io_out_bits_vpu_fpu_isFoldTo1_2(g_v14_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_bits_vpu_fpu_isFoldTo1_4(g_v14_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_bits_vpu_fpu_isFoldTo1_8(g_v14_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_bits_vpu_vuopIdx(g_v14_io_out_bits_vpu_vuopIdx),
    .io_out_bits_vpu_lastUop(g_v14_io_out_bits_vpu_lastUop),
    .io_out_bits_vpu_isNarrow(g_v14_io_out_bits_vpu_isNarrow),
    .io_out_bits_vpu_isDstMask(g_v14_io_out_bits_vpu_isDstMask),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v14_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v14_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v14_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v14_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v14_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v14_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v14_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v14_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v14_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v14_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v14_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v14_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_14_xs u_i_v14 (
    .clock(clock), .reset(reset),
    .io_in_valid(v14_io_in_valid),
    .io_in_bits_fuType(v14_io_in_bits_fuType),
    .io_in_bits_fuOpType(v14_io_in_bits_fuOpType),
    .io_in_bits_src_0(v14_io_in_bits_src_0),
    .io_in_bits_src_1(v14_io_in_bits_src_1),
    .io_in_bits_src_2(v14_io_in_bits_src_2),
    .io_in_bits_src_3(v14_io_in_bits_src_3),
    .io_in_bits_src_4(v14_io_in_bits_src_4),
    .io_in_bits_robIdx_flag(v14_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v14_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v14_io_in_bits_pdest),
    .io_in_bits_rfWen(v14_io_in_bits_rfWen),
    .io_in_bits_fpWen(v14_io_in_bits_fpWen),
    .io_in_bits_vecWen(v14_io_in_bits_vecWen),
    .io_in_bits_v0Wen(v14_io_in_bits_v0Wen),
    .io_in_bits_vlWen(v14_io_in_bits_vlWen),
    .io_in_bits_fpu_wflags(v14_io_in_bits_fpu_wflags),
    .io_in_bits_vpu_vma(v14_io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta(v14_io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew(v14_io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul(v14_io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_vm(v14_io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart(v14_io_in_bits_vpu_vstart),
    .io_in_bits_vpu_fpu_isFoldTo1_2(v14_io_in_bits_vpu_fpu_isFoldTo1_2),
    .io_in_bits_vpu_fpu_isFoldTo1_4(v14_io_in_bits_vpu_fpu_isFoldTo1_4),
    .io_in_bits_vpu_fpu_isFoldTo1_8(v14_io_in_bits_vpu_fpu_isFoldTo1_8),
    .io_in_bits_vpu_vuopIdx(v14_io_in_bits_vpu_vuopIdx),
    .io_in_bits_vpu_lastUop(v14_io_in_bits_vpu_lastUop),
    .io_in_bits_vpu_isNarrow(v14_io_in_bits_vpu_isNarrow),
    .io_in_bits_vpu_isDstMask(v14_io_in_bits_vpu_isDstMask),
    .io_in_bits_perfDebugInfo_eliminatedMove(v14_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v14_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v14_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v14_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v14_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v14_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v14_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v14_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v14_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v14_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v14_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v14_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v14_io_out_ready),
    .io_rightOutFire(v14_io_rightOutFire),
    .io_isFlush(v14_io_isFlush),
    .io_in_ready(i_v14_io_in_ready),
    .io_out_valid(i_v14_io_out_valid),
    .io_out_bits_fuType(i_v14_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v14_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v14_io_out_bits_src_0),
    .io_out_bits_src_1(i_v14_io_out_bits_src_1),
    .io_out_bits_src_2(i_v14_io_out_bits_src_2),
    .io_out_bits_src_3(i_v14_io_out_bits_src_3),
    .io_out_bits_src_4(i_v14_io_out_bits_src_4),
    .io_out_bits_robIdx_flag(i_v14_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v14_io_out_bits_robIdx_value),
    .io_out_bits_pdest(i_v14_io_out_bits_pdest),
    .io_out_bits_rfWen(i_v14_io_out_bits_rfWen),
    .io_out_bits_fpWen(i_v14_io_out_bits_fpWen),
    .io_out_bits_vecWen(i_v14_io_out_bits_vecWen),
    .io_out_bits_v0Wen(i_v14_io_out_bits_v0Wen),
    .io_out_bits_vlWen(i_v14_io_out_bits_vlWen),
    .io_out_bits_fpu_wflags(i_v14_io_out_bits_fpu_wflags),
    .io_out_bits_vpu_vma(i_v14_io_out_bits_vpu_vma),
    .io_out_bits_vpu_vta(i_v14_io_out_bits_vpu_vta),
    .io_out_bits_vpu_vsew(i_v14_io_out_bits_vpu_vsew),
    .io_out_bits_vpu_vlmul(i_v14_io_out_bits_vpu_vlmul),
    .io_out_bits_vpu_vm(i_v14_io_out_bits_vpu_vm),
    .io_out_bits_vpu_vstart(i_v14_io_out_bits_vpu_vstart),
    .io_out_bits_vpu_fpu_isFoldTo1_2(i_v14_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_bits_vpu_fpu_isFoldTo1_4(i_v14_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_bits_vpu_fpu_isFoldTo1_8(i_v14_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_bits_vpu_vuopIdx(i_v14_io_out_bits_vpu_vuopIdx),
    .io_out_bits_vpu_lastUop(i_v14_io_out_bits_vpu_lastUop),
    .io_out_bits_vpu_isNarrow(i_v14_io_out_bits_vpu_isNarrow),
    .io_out_bits_vpu_isDstMask(i_v14_io_out_bits_vpu_isDstMask),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v14_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v14_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v14_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v14_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v14_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v14_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v14_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v14_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v14_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v14_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v14_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v14_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_16 —— 39 字段 / 1375 位 payload
  // ==========================================================================
  logic v16_io_in_valid;
  logic [34:0] v16_io_in_bits_fuType;
  logic [8:0] v16_io_in_bits_fuOpType;
  logic [127:0] v16_io_in_bits_src_0;
  logic [127:0] v16_io_in_bits_src_1;
  logic [127:0] v16_io_in_bits_src_2;
  logic [127:0] v16_io_in_bits_src_3;
  logic [127:0] v16_io_in_bits_src_4;
  logic v16_io_in_bits_robIdx_flag;
  logic [7:0] v16_io_in_bits_robIdx_value;
  logic [7:0] v16_io_in_bits_pdest;
  logic v16_io_in_bits_fpWen;
  logic v16_io_in_bits_vecWen;
  logic v16_io_in_bits_v0Wen;
  logic v16_io_in_bits_fpu_wflags;
  logic v16_io_in_bits_vpu_vma;
  logic v16_io_in_bits_vpu_vta;
  logic [1:0] v16_io_in_bits_vpu_vsew;
  logic [2:0] v16_io_in_bits_vpu_vlmul;
  logic v16_io_in_bits_vpu_vm;
  logic [7:0] v16_io_in_bits_vpu_vstart;
  logic v16_io_in_bits_vpu_fpu_isFoldTo1_2;
  logic v16_io_in_bits_vpu_fpu_isFoldTo1_4;
  logic v16_io_in_bits_vpu_fpu_isFoldTo1_8;
  logic [6:0] v16_io_in_bits_vpu_vuopIdx;
  logic v16_io_in_bits_vpu_lastUop;
  logic v16_io_in_bits_vpu_isNarrow;
  logic v16_io_in_bits_vpu_isDstMask;
  logic v16_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v16_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v16_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v16_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v16_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v16_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v16_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v16_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v16_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v16_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v16_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v16_io_in_bits_debug_seqNum_uopIdx;
  logic v16_io_out_ready;
  logic v16_io_rightOutFire;
  logic v16_io_isFlush;
  wire  g_v16_io_in_ready, i_v16_io_in_ready;
  wire  g_v16_io_out_valid, i_v16_io_out_valid;
  wire  [34:0] g_v16_io_out_bits_fuType, i_v16_io_out_bits_fuType;
  wire  [8:0] g_v16_io_out_bits_fuOpType, i_v16_io_out_bits_fuOpType;
  wire  [127:0] g_v16_io_out_bits_src_0, i_v16_io_out_bits_src_0;
  wire  [127:0] g_v16_io_out_bits_src_1, i_v16_io_out_bits_src_1;
  wire  [127:0] g_v16_io_out_bits_src_2, i_v16_io_out_bits_src_2;
  wire  [127:0] g_v16_io_out_bits_src_3, i_v16_io_out_bits_src_3;
  wire  [127:0] g_v16_io_out_bits_src_4, i_v16_io_out_bits_src_4;
  wire  g_v16_io_out_bits_robIdx_flag, i_v16_io_out_bits_robIdx_flag;
  wire  [7:0] g_v16_io_out_bits_robIdx_value, i_v16_io_out_bits_robIdx_value;
  wire  [7:0] g_v16_io_out_bits_pdest, i_v16_io_out_bits_pdest;
  wire  g_v16_io_out_bits_fpWen, i_v16_io_out_bits_fpWen;
  wire  g_v16_io_out_bits_vecWen, i_v16_io_out_bits_vecWen;
  wire  g_v16_io_out_bits_v0Wen, i_v16_io_out_bits_v0Wen;
  wire  g_v16_io_out_bits_fpu_wflags, i_v16_io_out_bits_fpu_wflags;
  wire  g_v16_io_out_bits_vpu_vma, i_v16_io_out_bits_vpu_vma;
  wire  g_v16_io_out_bits_vpu_vta, i_v16_io_out_bits_vpu_vta;
  wire  [1:0] g_v16_io_out_bits_vpu_vsew, i_v16_io_out_bits_vpu_vsew;
  wire  [2:0] g_v16_io_out_bits_vpu_vlmul, i_v16_io_out_bits_vpu_vlmul;
  wire  g_v16_io_out_bits_vpu_vm, i_v16_io_out_bits_vpu_vm;
  wire  [7:0] g_v16_io_out_bits_vpu_vstart, i_v16_io_out_bits_vpu_vstart;
  wire  g_v16_io_out_bits_vpu_fpu_isFoldTo1_2, i_v16_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire  g_v16_io_out_bits_vpu_fpu_isFoldTo1_4, i_v16_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire  g_v16_io_out_bits_vpu_fpu_isFoldTo1_8, i_v16_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire  [6:0] g_v16_io_out_bits_vpu_vuopIdx, i_v16_io_out_bits_vpu_vuopIdx;
  wire  g_v16_io_out_bits_vpu_lastUop, i_v16_io_out_bits_vpu_lastUop;
  wire  g_v16_io_out_bits_vpu_isNarrow, i_v16_io_out_bits_vpu_isNarrow;
  wire  g_v16_io_out_bits_vpu_isDstMask, i_v16_io_out_bits_vpu_isDstMask;
  wire  g_v16_io_out_bits_perfDebugInfo_eliminatedMove, i_v16_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v16_io_out_bits_perfDebugInfo_renameTime, i_v16_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v16_io_out_bits_perfDebugInfo_dispatchTime, i_v16_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v16_io_out_bits_perfDebugInfo_enqRsTime, i_v16_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v16_io_out_bits_perfDebugInfo_selectTime, i_v16_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v16_io_out_bits_perfDebugInfo_issueTime, i_v16_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v16_io_out_bits_perfDebugInfo_writebackTime, i_v16_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v16_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v16_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v16_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v16_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v16_io_out_bits_perfDebugInfo_tlbRespTime, i_v16_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v16_io_out_bits_debug_seqNum_seqNum, i_v16_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v16_io_out_bits_debug_seqNum_uopIdx, i_v16_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v16 = 0; int nerr_v16 = 0;
  longint fire_v16 = 0, bp_v16 = 0, flush_v16 = 0, hold_v16 = 0, ov_v16 = 0;
  logic [1374:0] por_v16 = '0, pand_v16 = '1;   // payload 按位或 / 按位与
  wire  [1374:0] pcat_v16 = {v16_io_in_bits_fuType, v16_io_in_bits_fuOpType, v16_io_in_bits_src_0, v16_io_in_bits_src_1, v16_io_in_bits_src_2, v16_io_in_bits_src_3, v16_io_in_bits_src_4, v16_io_in_bits_robIdx_flag, v16_io_in_bits_robIdx_value, v16_io_in_bits_pdest, v16_io_in_bits_fpWen, v16_io_in_bits_vecWen, v16_io_in_bits_v0Wen, v16_io_in_bits_fpu_wflags, v16_io_in_bits_vpu_vma, v16_io_in_bits_vpu_vta, v16_io_in_bits_vpu_vsew, v16_io_in_bits_vpu_vlmul, v16_io_in_bits_vpu_vm, v16_io_in_bits_vpu_vstart, v16_io_in_bits_vpu_fpu_isFoldTo1_2, v16_io_in_bits_vpu_fpu_isFoldTo1_4, v16_io_in_bits_vpu_fpu_isFoldTo1_8, v16_io_in_bits_vpu_vuopIdx, v16_io_in_bits_vpu_lastUop, v16_io_in_bits_vpu_isNarrow, v16_io_in_bits_vpu_isDstMask, v16_io_in_bits_perfDebugInfo_eliminatedMove, v16_io_in_bits_perfDebugInfo_renameTime, v16_io_in_bits_perfDebugInfo_dispatchTime, v16_io_in_bits_perfDebugInfo_enqRsTime, v16_io_in_bits_perfDebugInfo_selectTime, v16_io_in_bits_perfDebugInfo_issueTime, v16_io_in_bits_perfDebugInfo_writebackTime, v16_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v16_io_in_bits_perfDebugInfo_tlbFirstReqTime, v16_io_in_bits_perfDebugInfo_tlbRespTime, v16_io_in_bits_debug_seqNum_seqNum, v16_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe_16 u_g_v16 (
    .clock(clock), .reset(reset),
    .io_in_valid(v16_io_in_valid),
    .io_in_bits_fuType(v16_io_in_bits_fuType),
    .io_in_bits_fuOpType(v16_io_in_bits_fuOpType),
    .io_in_bits_src_0(v16_io_in_bits_src_0),
    .io_in_bits_src_1(v16_io_in_bits_src_1),
    .io_in_bits_src_2(v16_io_in_bits_src_2),
    .io_in_bits_src_3(v16_io_in_bits_src_3),
    .io_in_bits_src_4(v16_io_in_bits_src_4),
    .io_in_bits_robIdx_flag(v16_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v16_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v16_io_in_bits_pdest),
    .io_in_bits_fpWen(v16_io_in_bits_fpWen),
    .io_in_bits_vecWen(v16_io_in_bits_vecWen),
    .io_in_bits_v0Wen(v16_io_in_bits_v0Wen),
    .io_in_bits_fpu_wflags(v16_io_in_bits_fpu_wflags),
    .io_in_bits_vpu_vma(v16_io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta(v16_io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew(v16_io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul(v16_io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_vm(v16_io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart(v16_io_in_bits_vpu_vstart),
    .io_in_bits_vpu_fpu_isFoldTo1_2(v16_io_in_bits_vpu_fpu_isFoldTo1_2),
    .io_in_bits_vpu_fpu_isFoldTo1_4(v16_io_in_bits_vpu_fpu_isFoldTo1_4),
    .io_in_bits_vpu_fpu_isFoldTo1_8(v16_io_in_bits_vpu_fpu_isFoldTo1_8),
    .io_in_bits_vpu_vuopIdx(v16_io_in_bits_vpu_vuopIdx),
    .io_in_bits_vpu_lastUop(v16_io_in_bits_vpu_lastUop),
    .io_in_bits_vpu_isNarrow(v16_io_in_bits_vpu_isNarrow),
    .io_in_bits_vpu_isDstMask(v16_io_in_bits_vpu_isDstMask),
    .io_in_bits_perfDebugInfo_eliminatedMove(v16_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v16_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v16_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v16_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v16_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v16_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v16_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v16_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v16_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v16_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v16_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v16_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v16_io_out_ready),
    .io_rightOutFire(v16_io_rightOutFire),
    .io_isFlush(v16_io_isFlush),
    .io_in_ready(g_v16_io_in_ready),
    .io_out_valid(g_v16_io_out_valid),
    .io_out_bits_fuType(g_v16_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v16_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v16_io_out_bits_src_0),
    .io_out_bits_src_1(g_v16_io_out_bits_src_1),
    .io_out_bits_src_2(g_v16_io_out_bits_src_2),
    .io_out_bits_src_3(g_v16_io_out_bits_src_3),
    .io_out_bits_src_4(g_v16_io_out_bits_src_4),
    .io_out_bits_robIdx_flag(g_v16_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v16_io_out_bits_robIdx_value),
    .io_out_bits_pdest(g_v16_io_out_bits_pdest),
    .io_out_bits_fpWen(g_v16_io_out_bits_fpWen),
    .io_out_bits_vecWen(g_v16_io_out_bits_vecWen),
    .io_out_bits_v0Wen(g_v16_io_out_bits_v0Wen),
    .io_out_bits_fpu_wflags(g_v16_io_out_bits_fpu_wflags),
    .io_out_bits_vpu_vma(g_v16_io_out_bits_vpu_vma),
    .io_out_bits_vpu_vta(g_v16_io_out_bits_vpu_vta),
    .io_out_bits_vpu_vsew(g_v16_io_out_bits_vpu_vsew),
    .io_out_bits_vpu_vlmul(g_v16_io_out_bits_vpu_vlmul),
    .io_out_bits_vpu_vm(g_v16_io_out_bits_vpu_vm),
    .io_out_bits_vpu_vstart(g_v16_io_out_bits_vpu_vstart),
    .io_out_bits_vpu_fpu_isFoldTo1_2(g_v16_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_bits_vpu_fpu_isFoldTo1_4(g_v16_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_bits_vpu_fpu_isFoldTo1_8(g_v16_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_bits_vpu_vuopIdx(g_v16_io_out_bits_vpu_vuopIdx),
    .io_out_bits_vpu_lastUop(g_v16_io_out_bits_vpu_lastUop),
    .io_out_bits_vpu_isNarrow(g_v16_io_out_bits_vpu_isNarrow),
    .io_out_bits_vpu_isDstMask(g_v16_io_out_bits_vpu_isDstMask),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v16_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v16_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v16_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v16_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v16_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v16_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v16_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v16_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v16_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v16_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v16_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v16_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_16_xs u_i_v16 (
    .clock(clock), .reset(reset),
    .io_in_valid(v16_io_in_valid),
    .io_in_bits_fuType(v16_io_in_bits_fuType),
    .io_in_bits_fuOpType(v16_io_in_bits_fuOpType),
    .io_in_bits_src_0(v16_io_in_bits_src_0),
    .io_in_bits_src_1(v16_io_in_bits_src_1),
    .io_in_bits_src_2(v16_io_in_bits_src_2),
    .io_in_bits_src_3(v16_io_in_bits_src_3),
    .io_in_bits_src_4(v16_io_in_bits_src_4),
    .io_in_bits_robIdx_flag(v16_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v16_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v16_io_in_bits_pdest),
    .io_in_bits_fpWen(v16_io_in_bits_fpWen),
    .io_in_bits_vecWen(v16_io_in_bits_vecWen),
    .io_in_bits_v0Wen(v16_io_in_bits_v0Wen),
    .io_in_bits_fpu_wflags(v16_io_in_bits_fpu_wflags),
    .io_in_bits_vpu_vma(v16_io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta(v16_io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew(v16_io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul(v16_io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_vm(v16_io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart(v16_io_in_bits_vpu_vstart),
    .io_in_bits_vpu_fpu_isFoldTo1_2(v16_io_in_bits_vpu_fpu_isFoldTo1_2),
    .io_in_bits_vpu_fpu_isFoldTo1_4(v16_io_in_bits_vpu_fpu_isFoldTo1_4),
    .io_in_bits_vpu_fpu_isFoldTo1_8(v16_io_in_bits_vpu_fpu_isFoldTo1_8),
    .io_in_bits_vpu_vuopIdx(v16_io_in_bits_vpu_vuopIdx),
    .io_in_bits_vpu_lastUop(v16_io_in_bits_vpu_lastUop),
    .io_in_bits_vpu_isNarrow(v16_io_in_bits_vpu_isNarrow),
    .io_in_bits_vpu_isDstMask(v16_io_in_bits_vpu_isDstMask),
    .io_in_bits_perfDebugInfo_eliminatedMove(v16_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v16_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v16_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v16_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v16_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v16_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v16_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v16_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v16_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v16_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v16_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v16_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v16_io_out_ready),
    .io_rightOutFire(v16_io_rightOutFire),
    .io_isFlush(v16_io_isFlush),
    .io_in_ready(i_v16_io_in_ready),
    .io_out_valid(i_v16_io_out_valid),
    .io_out_bits_fuType(i_v16_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v16_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v16_io_out_bits_src_0),
    .io_out_bits_src_1(i_v16_io_out_bits_src_1),
    .io_out_bits_src_2(i_v16_io_out_bits_src_2),
    .io_out_bits_src_3(i_v16_io_out_bits_src_3),
    .io_out_bits_src_4(i_v16_io_out_bits_src_4),
    .io_out_bits_robIdx_flag(i_v16_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v16_io_out_bits_robIdx_value),
    .io_out_bits_pdest(i_v16_io_out_bits_pdest),
    .io_out_bits_fpWen(i_v16_io_out_bits_fpWen),
    .io_out_bits_vecWen(i_v16_io_out_bits_vecWen),
    .io_out_bits_v0Wen(i_v16_io_out_bits_v0Wen),
    .io_out_bits_fpu_wflags(i_v16_io_out_bits_fpu_wflags),
    .io_out_bits_vpu_vma(i_v16_io_out_bits_vpu_vma),
    .io_out_bits_vpu_vta(i_v16_io_out_bits_vpu_vta),
    .io_out_bits_vpu_vsew(i_v16_io_out_bits_vpu_vsew),
    .io_out_bits_vpu_vlmul(i_v16_io_out_bits_vpu_vlmul),
    .io_out_bits_vpu_vm(i_v16_io_out_bits_vpu_vm),
    .io_out_bits_vpu_vstart(i_v16_io_out_bits_vpu_vstart),
    .io_out_bits_vpu_fpu_isFoldTo1_2(i_v16_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_bits_vpu_fpu_isFoldTo1_4(i_v16_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_bits_vpu_fpu_isFoldTo1_8(i_v16_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_bits_vpu_vuopIdx(i_v16_io_out_bits_vpu_vuopIdx),
    .io_out_bits_vpu_lastUop(i_v16_io_out_bits_vpu_lastUop),
    .io_out_bits_vpu_isNarrow(i_v16_io_out_bits_vpu_isNarrow),
    .io_out_bits_vpu_isDstMask(i_v16_io_out_bits_vpu_isDstMask),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v16_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v16_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v16_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v16_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v16_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v16_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v16_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v16_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v16_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v16_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v16_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v16_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_18 —— 28 字段 / 858 位 payload
  // ==========================================================================
  logic v18_io_in_valid;
  logic [34:0] v18_io_in_bits_fuType;
  logic [8:0] v18_io_in_bits_fuOpType;
  logic [63:0] v18_io_in_bits_src_0;
  logic [63:0] v18_io_in_bits_imm;
  logic v18_io_in_bits_robIdx_flag;
  logic [7:0] v18_io_in_bits_robIdx_value;
  logic v18_io_in_bits_isFirstIssue;
  logic [7:0] v18_io_in_bits_pdest;
  logic v18_io_in_bits_rfWen;
  logic v18_io_in_bits_ftqIdx_flag;
  logic [5:0] v18_io_in_bits_ftqIdx_value;
  logic [3:0] v18_io_in_bits_ftqOffset;
  logic v18_io_in_bits_sqIdx_flag;
  logic [5:0] v18_io_in_bits_sqIdx_value;
  logic v18_io_in_bits_lqIdx_flag;
  logic [6:0] v18_io_in_bits_lqIdx_value;
  logic v18_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v18_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v18_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v18_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v18_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v18_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v18_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v18_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v18_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v18_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v18_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v18_io_in_bits_debug_seqNum_uopIdx;
  logic v18_io_out_ready;
  logic v18_io_rightOutFire;
  logic v18_io_isFlush;
  wire  g_v18_io_in_ready, i_v18_io_in_ready;
  wire  g_v18_io_out_valid, i_v18_io_out_valid;
  wire  [34:0] g_v18_io_out_bits_fuType, i_v18_io_out_bits_fuType;
  wire  [8:0] g_v18_io_out_bits_fuOpType, i_v18_io_out_bits_fuOpType;
  wire  [63:0] g_v18_io_out_bits_src_0, i_v18_io_out_bits_src_0;
  wire  [63:0] g_v18_io_out_bits_imm, i_v18_io_out_bits_imm;
  wire  g_v18_io_out_bits_robIdx_flag, i_v18_io_out_bits_robIdx_flag;
  wire  [7:0] g_v18_io_out_bits_robIdx_value, i_v18_io_out_bits_robIdx_value;
  wire  g_v18_io_out_bits_isFirstIssue, i_v18_io_out_bits_isFirstIssue;
  wire  [7:0] g_v18_io_out_bits_pdest, i_v18_io_out_bits_pdest;
  wire  g_v18_io_out_bits_rfWen, i_v18_io_out_bits_rfWen;
  wire  g_v18_io_out_bits_ftqIdx_flag, i_v18_io_out_bits_ftqIdx_flag;
  wire  [5:0] g_v18_io_out_bits_ftqIdx_value, i_v18_io_out_bits_ftqIdx_value;
  wire  [3:0] g_v18_io_out_bits_ftqOffset, i_v18_io_out_bits_ftqOffset;
  wire  g_v18_io_out_bits_sqIdx_flag, i_v18_io_out_bits_sqIdx_flag;
  wire  [5:0] g_v18_io_out_bits_sqIdx_value, i_v18_io_out_bits_sqIdx_value;
  wire  g_v18_io_out_bits_lqIdx_flag, i_v18_io_out_bits_lqIdx_flag;
  wire  [6:0] g_v18_io_out_bits_lqIdx_value, i_v18_io_out_bits_lqIdx_value;
  wire  g_v18_io_out_bits_perfDebugInfo_eliminatedMove, i_v18_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v18_io_out_bits_perfDebugInfo_renameTime, i_v18_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v18_io_out_bits_perfDebugInfo_dispatchTime, i_v18_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v18_io_out_bits_perfDebugInfo_enqRsTime, i_v18_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v18_io_out_bits_perfDebugInfo_selectTime, i_v18_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v18_io_out_bits_perfDebugInfo_issueTime, i_v18_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v18_io_out_bits_perfDebugInfo_writebackTime, i_v18_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v18_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v18_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v18_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v18_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v18_io_out_bits_perfDebugInfo_tlbRespTime, i_v18_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v18_io_out_bits_debug_seqNum_seqNum, i_v18_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v18_io_out_bits_debug_seqNum_uopIdx, i_v18_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v18 = 0; int nerr_v18 = 0;
  longint fire_v18 = 0, bp_v18 = 0, flush_v18 = 0, hold_v18 = 0, ov_v18 = 0;
  logic [857:0] por_v18 = '0, pand_v18 = '1;   // payload 按位或 / 按位与
  wire  [857:0] pcat_v18 = {v18_io_in_bits_fuType, v18_io_in_bits_fuOpType, v18_io_in_bits_src_0, v18_io_in_bits_imm, v18_io_in_bits_robIdx_flag, v18_io_in_bits_robIdx_value, v18_io_in_bits_isFirstIssue, v18_io_in_bits_pdest, v18_io_in_bits_rfWen, v18_io_in_bits_ftqIdx_flag, v18_io_in_bits_ftqIdx_value, v18_io_in_bits_ftqOffset, v18_io_in_bits_sqIdx_flag, v18_io_in_bits_sqIdx_value, v18_io_in_bits_lqIdx_flag, v18_io_in_bits_lqIdx_value, v18_io_in_bits_perfDebugInfo_eliminatedMove, v18_io_in_bits_perfDebugInfo_renameTime, v18_io_in_bits_perfDebugInfo_dispatchTime, v18_io_in_bits_perfDebugInfo_enqRsTime, v18_io_in_bits_perfDebugInfo_selectTime, v18_io_in_bits_perfDebugInfo_issueTime, v18_io_in_bits_perfDebugInfo_writebackTime, v18_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v18_io_in_bits_perfDebugInfo_tlbFirstReqTime, v18_io_in_bits_perfDebugInfo_tlbRespTime, v18_io_in_bits_debug_seqNum_seqNum, v18_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe_18 u_g_v18 (
    .clock(clock), .reset(reset),
    .io_in_valid(v18_io_in_valid),
    .io_in_bits_fuType(v18_io_in_bits_fuType),
    .io_in_bits_fuOpType(v18_io_in_bits_fuOpType),
    .io_in_bits_src_0(v18_io_in_bits_src_0),
    .io_in_bits_imm(v18_io_in_bits_imm),
    .io_in_bits_robIdx_flag(v18_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v18_io_in_bits_robIdx_value),
    .io_in_bits_isFirstIssue(v18_io_in_bits_isFirstIssue),
    .io_in_bits_pdest(v18_io_in_bits_pdest),
    .io_in_bits_rfWen(v18_io_in_bits_rfWen),
    .io_in_bits_ftqIdx_flag(v18_io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(v18_io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(v18_io_in_bits_ftqOffset),
    .io_in_bits_sqIdx_flag(v18_io_in_bits_sqIdx_flag),
    .io_in_bits_sqIdx_value(v18_io_in_bits_sqIdx_value),
    .io_in_bits_lqIdx_flag(v18_io_in_bits_lqIdx_flag),
    .io_in_bits_lqIdx_value(v18_io_in_bits_lqIdx_value),
    .io_in_bits_perfDebugInfo_eliminatedMove(v18_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v18_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v18_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v18_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v18_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v18_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v18_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v18_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v18_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v18_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v18_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v18_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v18_io_out_ready),
    .io_rightOutFire(v18_io_rightOutFire),
    .io_isFlush(v18_io_isFlush),
    .io_in_ready(g_v18_io_in_ready),
    .io_out_valid(g_v18_io_out_valid),
    .io_out_bits_fuType(g_v18_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v18_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v18_io_out_bits_src_0),
    .io_out_bits_imm(g_v18_io_out_bits_imm),
    .io_out_bits_robIdx_flag(g_v18_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v18_io_out_bits_robIdx_value),
    .io_out_bits_isFirstIssue(g_v18_io_out_bits_isFirstIssue),
    .io_out_bits_pdest(g_v18_io_out_bits_pdest),
    .io_out_bits_rfWen(g_v18_io_out_bits_rfWen),
    .io_out_bits_ftqIdx_flag(g_v18_io_out_bits_ftqIdx_flag),
    .io_out_bits_ftqIdx_value(g_v18_io_out_bits_ftqIdx_value),
    .io_out_bits_ftqOffset(g_v18_io_out_bits_ftqOffset),
    .io_out_bits_sqIdx_flag(g_v18_io_out_bits_sqIdx_flag),
    .io_out_bits_sqIdx_value(g_v18_io_out_bits_sqIdx_value),
    .io_out_bits_lqIdx_flag(g_v18_io_out_bits_lqIdx_flag),
    .io_out_bits_lqIdx_value(g_v18_io_out_bits_lqIdx_value),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v18_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v18_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v18_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v18_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v18_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v18_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v18_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v18_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v18_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v18_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v18_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v18_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_18_xs u_i_v18 (
    .clock(clock), .reset(reset),
    .io_in_valid(v18_io_in_valid),
    .io_in_bits_fuType(v18_io_in_bits_fuType),
    .io_in_bits_fuOpType(v18_io_in_bits_fuOpType),
    .io_in_bits_src_0(v18_io_in_bits_src_0),
    .io_in_bits_imm(v18_io_in_bits_imm),
    .io_in_bits_robIdx_flag(v18_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v18_io_in_bits_robIdx_value),
    .io_in_bits_isFirstIssue(v18_io_in_bits_isFirstIssue),
    .io_in_bits_pdest(v18_io_in_bits_pdest),
    .io_in_bits_rfWen(v18_io_in_bits_rfWen),
    .io_in_bits_ftqIdx_flag(v18_io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(v18_io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(v18_io_in_bits_ftqOffset),
    .io_in_bits_sqIdx_flag(v18_io_in_bits_sqIdx_flag),
    .io_in_bits_sqIdx_value(v18_io_in_bits_sqIdx_value),
    .io_in_bits_lqIdx_flag(v18_io_in_bits_lqIdx_flag),
    .io_in_bits_lqIdx_value(v18_io_in_bits_lqIdx_value),
    .io_in_bits_perfDebugInfo_eliminatedMove(v18_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v18_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v18_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v18_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v18_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v18_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v18_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v18_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v18_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v18_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v18_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v18_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v18_io_out_ready),
    .io_rightOutFire(v18_io_rightOutFire),
    .io_isFlush(v18_io_isFlush),
    .io_in_ready(i_v18_io_in_ready),
    .io_out_valid(i_v18_io_out_valid),
    .io_out_bits_fuType(i_v18_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v18_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v18_io_out_bits_src_0),
    .io_out_bits_imm(i_v18_io_out_bits_imm),
    .io_out_bits_robIdx_flag(i_v18_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v18_io_out_bits_robIdx_value),
    .io_out_bits_isFirstIssue(i_v18_io_out_bits_isFirstIssue),
    .io_out_bits_pdest(i_v18_io_out_bits_pdest),
    .io_out_bits_rfWen(i_v18_io_out_bits_rfWen),
    .io_out_bits_ftqIdx_flag(i_v18_io_out_bits_ftqIdx_flag),
    .io_out_bits_ftqIdx_value(i_v18_io_out_bits_ftqIdx_value),
    .io_out_bits_ftqOffset(i_v18_io_out_bits_ftqOffset),
    .io_out_bits_sqIdx_flag(i_v18_io_out_bits_sqIdx_flag),
    .io_out_bits_sqIdx_value(i_v18_io_out_bits_sqIdx_value),
    .io_out_bits_lqIdx_flag(i_v18_io_out_bits_lqIdx_flag),
    .io_out_bits_lqIdx_value(i_v18_io_out_bits_lqIdx_value),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v18_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v18_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v18_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v18_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v18_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v18_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v18_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v18_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v18_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v18_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v18_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v18_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_20 —— 40 字段 / 931 位 payload
  // ==========================================================================
  logic v20_io_in_valid;
  logic [34:0] v20_io_in_bits_fuType;
  logic [8:0] v20_io_in_bits_fuOpType;
  logic [63:0] v20_io_in_bits_src_0;
  logic [63:0] v20_io_in_bits_imm;
  logic v20_io_in_bits_robIdx_flag;
  logic [7:0] v20_io_in_bits_robIdx_value;
  logic [7:0] v20_io_in_bits_pdest;
  logic v20_io_in_bits_rfWen;
  logic v20_io_in_bits_fpWen;
  logic [49:0] v20_io_in_bits_pc;
  logic v20_io_in_bits_preDecode_valid;
  logic v20_io_in_bits_preDecode_isRVC;
  logic [1:0] v20_io_in_bits_preDecode_brType;
  logic v20_io_in_bits_preDecode_isCall;
  logic v20_io_in_bits_preDecode_isRet;
  logic v20_io_in_bits_ftqIdx_flag;
  logic [5:0] v20_io_in_bits_ftqIdx_value;
  logic [3:0] v20_io_in_bits_ftqOffset;
  logic v20_io_in_bits_loadWaitBit;
  logic v20_io_in_bits_waitForRobIdx_flag;
  logic [7:0] v20_io_in_bits_waitForRobIdx_value;
  logic v20_io_in_bits_storeSetHit;
  logic v20_io_in_bits_loadWaitStrict;
  logic [4:0] v20_io_in_bits_ssid;
  logic v20_io_in_bits_sqIdx_flag;
  logic [5:0] v20_io_in_bits_sqIdx_value;
  logic v20_io_in_bits_lqIdx_flag;
  logic [6:0] v20_io_in_bits_lqIdx_value;
  logic v20_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v20_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v20_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v20_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v20_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v20_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v20_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v20_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v20_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v20_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v20_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v20_io_in_bits_debug_seqNum_uopIdx;
  logic v20_io_out_ready;
  logic v20_io_rightOutFire;
  logic v20_io_isFlush;
  wire  g_v20_io_in_ready, i_v20_io_in_ready;
  wire  g_v20_io_out_valid, i_v20_io_out_valid;
  wire  [34:0] g_v20_io_out_bits_fuType, i_v20_io_out_bits_fuType;
  wire  [8:0] g_v20_io_out_bits_fuOpType, i_v20_io_out_bits_fuOpType;
  wire  [63:0] g_v20_io_out_bits_src_0, i_v20_io_out_bits_src_0;
  wire  [63:0] g_v20_io_out_bits_imm, i_v20_io_out_bits_imm;
  wire  g_v20_io_out_bits_robIdx_flag, i_v20_io_out_bits_robIdx_flag;
  wire  [7:0] g_v20_io_out_bits_robIdx_value, i_v20_io_out_bits_robIdx_value;
  wire  [7:0] g_v20_io_out_bits_pdest, i_v20_io_out_bits_pdest;
  wire  g_v20_io_out_bits_rfWen, i_v20_io_out_bits_rfWen;
  wire  g_v20_io_out_bits_fpWen, i_v20_io_out_bits_fpWen;
  wire  [49:0] g_v20_io_out_bits_pc, i_v20_io_out_bits_pc;
  wire  g_v20_io_out_bits_preDecode_valid, i_v20_io_out_bits_preDecode_valid;
  wire  g_v20_io_out_bits_preDecode_isRVC, i_v20_io_out_bits_preDecode_isRVC;
  wire  [1:0] g_v20_io_out_bits_preDecode_brType, i_v20_io_out_bits_preDecode_brType;
  wire  g_v20_io_out_bits_preDecode_isCall, i_v20_io_out_bits_preDecode_isCall;
  wire  g_v20_io_out_bits_preDecode_isRet, i_v20_io_out_bits_preDecode_isRet;
  wire  g_v20_io_out_bits_ftqIdx_flag, i_v20_io_out_bits_ftqIdx_flag;
  wire  [5:0] g_v20_io_out_bits_ftqIdx_value, i_v20_io_out_bits_ftqIdx_value;
  wire  [3:0] g_v20_io_out_bits_ftqOffset, i_v20_io_out_bits_ftqOffset;
  wire  g_v20_io_out_bits_loadWaitBit, i_v20_io_out_bits_loadWaitBit;
  wire  g_v20_io_out_bits_waitForRobIdx_flag, i_v20_io_out_bits_waitForRobIdx_flag;
  wire  [7:0] g_v20_io_out_bits_waitForRobIdx_value, i_v20_io_out_bits_waitForRobIdx_value;
  wire  g_v20_io_out_bits_storeSetHit, i_v20_io_out_bits_storeSetHit;
  wire  g_v20_io_out_bits_loadWaitStrict, i_v20_io_out_bits_loadWaitStrict;
  wire  [4:0] g_v20_io_out_bits_ssid, i_v20_io_out_bits_ssid;
  wire  g_v20_io_out_bits_sqIdx_flag, i_v20_io_out_bits_sqIdx_flag;
  wire  [5:0] g_v20_io_out_bits_sqIdx_value, i_v20_io_out_bits_sqIdx_value;
  wire  g_v20_io_out_bits_lqIdx_flag, i_v20_io_out_bits_lqIdx_flag;
  wire  [6:0] g_v20_io_out_bits_lqIdx_value, i_v20_io_out_bits_lqIdx_value;
  wire  g_v20_io_out_bits_perfDebugInfo_eliminatedMove, i_v20_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v20_io_out_bits_perfDebugInfo_renameTime, i_v20_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v20_io_out_bits_perfDebugInfo_dispatchTime, i_v20_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v20_io_out_bits_perfDebugInfo_enqRsTime, i_v20_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v20_io_out_bits_perfDebugInfo_selectTime, i_v20_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v20_io_out_bits_perfDebugInfo_issueTime, i_v20_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v20_io_out_bits_perfDebugInfo_writebackTime, i_v20_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v20_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v20_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v20_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v20_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v20_io_out_bits_perfDebugInfo_tlbRespTime, i_v20_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v20_io_out_bits_debug_seqNum_seqNum, i_v20_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v20_io_out_bits_debug_seqNum_uopIdx, i_v20_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v20 = 0; int nerr_v20 = 0;
  longint fire_v20 = 0, bp_v20 = 0, flush_v20 = 0, hold_v20 = 0, ov_v20 = 0;
  logic [930:0] por_v20 = '0, pand_v20 = '1;   // payload 按位或 / 按位与
  wire  [930:0] pcat_v20 = {v20_io_in_bits_fuType, v20_io_in_bits_fuOpType, v20_io_in_bits_src_0, v20_io_in_bits_imm, v20_io_in_bits_robIdx_flag, v20_io_in_bits_robIdx_value, v20_io_in_bits_pdest, v20_io_in_bits_rfWen, v20_io_in_bits_fpWen, v20_io_in_bits_pc, v20_io_in_bits_preDecode_valid, v20_io_in_bits_preDecode_isRVC, v20_io_in_bits_preDecode_brType, v20_io_in_bits_preDecode_isCall, v20_io_in_bits_preDecode_isRet, v20_io_in_bits_ftqIdx_flag, v20_io_in_bits_ftqIdx_value, v20_io_in_bits_ftqOffset, v20_io_in_bits_loadWaitBit, v20_io_in_bits_waitForRobIdx_flag, v20_io_in_bits_waitForRobIdx_value, v20_io_in_bits_storeSetHit, v20_io_in_bits_loadWaitStrict, v20_io_in_bits_ssid, v20_io_in_bits_sqIdx_flag, v20_io_in_bits_sqIdx_value, v20_io_in_bits_lqIdx_flag, v20_io_in_bits_lqIdx_value, v20_io_in_bits_perfDebugInfo_eliminatedMove, v20_io_in_bits_perfDebugInfo_renameTime, v20_io_in_bits_perfDebugInfo_dispatchTime, v20_io_in_bits_perfDebugInfo_enqRsTime, v20_io_in_bits_perfDebugInfo_selectTime, v20_io_in_bits_perfDebugInfo_issueTime, v20_io_in_bits_perfDebugInfo_writebackTime, v20_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v20_io_in_bits_perfDebugInfo_tlbFirstReqTime, v20_io_in_bits_perfDebugInfo_tlbRespTime, v20_io_in_bits_debug_seqNum_seqNum, v20_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe_20 u_g_v20 (
    .clock(clock), .reset(reset),
    .io_in_valid(v20_io_in_valid),
    .io_in_bits_fuType(v20_io_in_bits_fuType),
    .io_in_bits_fuOpType(v20_io_in_bits_fuOpType),
    .io_in_bits_src_0(v20_io_in_bits_src_0),
    .io_in_bits_imm(v20_io_in_bits_imm),
    .io_in_bits_robIdx_flag(v20_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v20_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v20_io_in_bits_pdest),
    .io_in_bits_rfWen(v20_io_in_bits_rfWen),
    .io_in_bits_fpWen(v20_io_in_bits_fpWen),
    .io_in_bits_pc(v20_io_in_bits_pc),
    .io_in_bits_preDecode_valid(v20_io_in_bits_preDecode_valid),
    .io_in_bits_preDecode_isRVC(v20_io_in_bits_preDecode_isRVC),
    .io_in_bits_preDecode_brType(v20_io_in_bits_preDecode_brType),
    .io_in_bits_preDecode_isCall(v20_io_in_bits_preDecode_isCall),
    .io_in_bits_preDecode_isRet(v20_io_in_bits_preDecode_isRet),
    .io_in_bits_ftqIdx_flag(v20_io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(v20_io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(v20_io_in_bits_ftqOffset),
    .io_in_bits_loadWaitBit(v20_io_in_bits_loadWaitBit),
    .io_in_bits_waitForRobIdx_flag(v20_io_in_bits_waitForRobIdx_flag),
    .io_in_bits_waitForRobIdx_value(v20_io_in_bits_waitForRobIdx_value),
    .io_in_bits_storeSetHit(v20_io_in_bits_storeSetHit),
    .io_in_bits_loadWaitStrict(v20_io_in_bits_loadWaitStrict),
    .io_in_bits_ssid(v20_io_in_bits_ssid),
    .io_in_bits_sqIdx_flag(v20_io_in_bits_sqIdx_flag),
    .io_in_bits_sqIdx_value(v20_io_in_bits_sqIdx_value),
    .io_in_bits_lqIdx_flag(v20_io_in_bits_lqIdx_flag),
    .io_in_bits_lqIdx_value(v20_io_in_bits_lqIdx_value),
    .io_in_bits_perfDebugInfo_eliminatedMove(v20_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v20_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v20_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v20_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v20_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v20_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v20_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v20_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v20_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v20_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v20_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v20_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v20_io_out_ready),
    .io_rightOutFire(v20_io_rightOutFire),
    .io_isFlush(v20_io_isFlush),
    .io_in_ready(g_v20_io_in_ready),
    .io_out_valid(g_v20_io_out_valid),
    .io_out_bits_fuType(g_v20_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v20_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v20_io_out_bits_src_0),
    .io_out_bits_imm(g_v20_io_out_bits_imm),
    .io_out_bits_robIdx_flag(g_v20_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v20_io_out_bits_robIdx_value),
    .io_out_bits_pdest(g_v20_io_out_bits_pdest),
    .io_out_bits_rfWen(g_v20_io_out_bits_rfWen),
    .io_out_bits_fpWen(g_v20_io_out_bits_fpWen),
    .io_out_bits_pc(g_v20_io_out_bits_pc),
    .io_out_bits_preDecode_valid(g_v20_io_out_bits_preDecode_valid),
    .io_out_bits_preDecode_isRVC(g_v20_io_out_bits_preDecode_isRVC),
    .io_out_bits_preDecode_brType(g_v20_io_out_bits_preDecode_brType),
    .io_out_bits_preDecode_isCall(g_v20_io_out_bits_preDecode_isCall),
    .io_out_bits_preDecode_isRet(g_v20_io_out_bits_preDecode_isRet),
    .io_out_bits_ftqIdx_flag(g_v20_io_out_bits_ftqIdx_flag),
    .io_out_bits_ftqIdx_value(g_v20_io_out_bits_ftqIdx_value),
    .io_out_bits_ftqOffset(g_v20_io_out_bits_ftqOffset),
    .io_out_bits_loadWaitBit(g_v20_io_out_bits_loadWaitBit),
    .io_out_bits_waitForRobIdx_flag(g_v20_io_out_bits_waitForRobIdx_flag),
    .io_out_bits_waitForRobIdx_value(g_v20_io_out_bits_waitForRobIdx_value),
    .io_out_bits_storeSetHit(g_v20_io_out_bits_storeSetHit),
    .io_out_bits_loadWaitStrict(g_v20_io_out_bits_loadWaitStrict),
    .io_out_bits_ssid(g_v20_io_out_bits_ssid),
    .io_out_bits_sqIdx_flag(g_v20_io_out_bits_sqIdx_flag),
    .io_out_bits_sqIdx_value(g_v20_io_out_bits_sqIdx_value),
    .io_out_bits_lqIdx_flag(g_v20_io_out_bits_lqIdx_flag),
    .io_out_bits_lqIdx_value(g_v20_io_out_bits_lqIdx_value),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v20_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v20_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v20_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v20_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v20_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v20_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v20_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v20_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v20_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v20_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v20_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v20_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_20_xs u_i_v20 (
    .clock(clock), .reset(reset),
    .io_in_valid(v20_io_in_valid),
    .io_in_bits_fuType(v20_io_in_bits_fuType),
    .io_in_bits_fuOpType(v20_io_in_bits_fuOpType),
    .io_in_bits_src_0(v20_io_in_bits_src_0),
    .io_in_bits_imm(v20_io_in_bits_imm),
    .io_in_bits_robIdx_flag(v20_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v20_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v20_io_in_bits_pdest),
    .io_in_bits_rfWen(v20_io_in_bits_rfWen),
    .io_in_bits_fpWen(v20_io_in_bits_fpWen),
    .io_in_bits_pc(v20_io_in_bits_pc),
    .io_in_bits_preDecode_valid(v20_io_in_bits_preDecode_valid),
    .io_in_bits_preDecode_isRVC(v20_io_in_bits_preDecode_isRVC),
    .io_in_bits_preDecode_brType(v20_io_in_bits_preDecode_brType),
    .io_in_bits_preDecode_isCall(v20_io_in_bits_preDecode_isCall),
    .io_in_bits_preDecode_isRet(v20_io_in_bits_preDecode_isRet),
    .io_in_bits_ftqIdx_flag(v20_io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(v20_io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(v20_io_in_bits_ftqOffset),
    .io_in_bits_loadWaitBit(v20_io_in_bits_loadWaitBit),
    .io_in_bits_waitForRobIdx_flag(v20_io_in_bits_waitForRobIdx_flag),
    .io_in_bits_waitForRobIdx_value(v20_io_in_bits_waitForRobIdx_value),
    .io_in_bits_storeSetHit(v20_io_in_bits_storeSetHit),
    .io_in_bits_loadWaitStrict(v20_io_in_bits_loadWaitStrict),
    .io_in_bits_ssid(v20_io_in_bits_ssid),
    .io_in_bits_sqIdx_flag(v20_io_in_bits_sqIdx_flag),
    .io_in_bits_sqIdx_value(v20_io_in_bits_sqIdx_value),
    .io_in_bits_lqIdx_flag(v20_io_in_bits_lqIdx_flag),
    .io_in_bits_lqIdx_value(v20_io_in_bits_lqIdx_value),
    .io_in_bits_perfDebugInfo_eliminatedMove(v20_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v20_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v20_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v20_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v20_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v20_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v20_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v20_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v20_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v20_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v20_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v20_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v20_io_out_ready),
    .io_rightOutFire(v20_io_rightOutFire),
    .io_isFlush(v20_io_isFlush),
    .io_in_ready(i_v20_io_in_ready),
    .io_out_valid(i_v20_io_out_valid),
    .io_out_bits_fuType(i_v20_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v20_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v20_io_out_bits_src_0),
    .io_out_bits_imm(i_v20_io_out_bits_imm),
    .io_out_bits_robIdx_flag(i_v20_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v20_io_out_bits_robIdx_value),
    .io_out_bits_pdest(i_v20_io_out_bits_pdest),
    .io_out_bits_rfWen(i_v20_io_out_bits_rfWen),
    .io_out_bits_fpWen(i_v20_io_out_bits_fpWen),
    .io_out_bits_pc(i_v20_io_out_bits_pc),
    .io_out_bits_preDecode_valid(i_v20_io_out_bits_preDecode_valid),
    .io_out_bits_preDecode_isRVC(i_v20_io_out_bits_preDecode_isRVC),
    .io_out_bits_preDecode_brType(i_v20_io_out_bits_preDecode_brType),
    .io_out_bits_preDecode_isCall(i_v20_io_out_bits_preDecode_isCall),
    .io_out_bits_preDecode_isRet(i_v20_io_out_bits_preDecode_isRet),
    .io_out_bits_ftqIdx_flag(i_v20_io_out_bits_ftqIdx_flag),
    .io_out_bits_ftqIdx_value(i_v20_io_out_bits_ftqIdx_value),
    .io_out_bits_ftqOffset(i_v20_io_out_bits_ftqOffset),
    .io_out_bits_loadWaitBit(i_v20_io_out_bits_loadWaitBit),
    .io_out_bits_waitForRobIdx_flag(i_v20_io_out_bits_waitForRobIdx_flag),
    .io_out_bits_waitForRobIdx_value(i_v20_io_out_bits_waitForRobIdx_value),
    .io_out_bits_storeSetHit(i_v20_io_out_bits_storeSetHit),
    .io_out_bits_loadWaitStrict(i_v20_io_out_bits_loadWaitStrict),
    .io_out_bits_ssid(i_v20_io_out_bits_ssid),
    .io_out_bits_sqIdx_flag(i_v20_io_out_bits_sqIdx_flag),
    .io_out_bits_sqIdx_value(i_v20_io_out_bits_sqIdx_value),
    .io_out_bits_lqIdx_flag(i_v20_io_out_bits_lqIdx_flag),
    .io_out_bits_lqIdx_value(i_v20_io_out_bits_lqIdx_value),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v20_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v20_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v20_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v20_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v20_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v20_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v20_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v20_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v20_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v20_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v20_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v20_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_23 —— 71 字段 / 1583 位 payload，带 isOlder
  // ==========================================================================
  logic v23_io_in_valid;
  logic [34:0] v23_io_in_bits_fuType;
  logic [8:0] v23_io_in_bits_fuOpType;
  logic [127:0] v23_io_in_bits_src_0;
  logic [127:0] v23_io_in_bits_src_1;
  logic [127:0] v23_io_in_bits_src_2;
  logic [127:0] v23_io_in_bits_src_3;
  logic [127:0] v23_io_in_bits_src_4;
  logic v23_io_in_bits_robIdx_flag;
  logic [7:0] v23_io_in_bits_robIdx_value;
  logic [6:0] v23_io_in_bits_pdest;
  logic v23_io_in_bits_vecWen;
  logic v23_io_in_bits_v0Wen;
  logic v23_io_in_bits_vlWen;
  logic v23_io_in_bits_vpu_vill;
  logic v23_io_in_bits_vpu_vma;
  logic v23_io_in_bits_vpu_vta;
  logic [1:0] v23_io_in_bits_vpu_vsew;
  logic [2:0] v23_io_in_bits_vpu_vlmul;
  logic v23_io_in_bits_vpu_specVill;
  logic v23_io_in_bits_vpu_specVma;
  logic v23_io_in_bits_vpu_specVta;
  logic [1:0] v23_io_in_bits_vpu_specVsew;
  logic [2:0] v23_io_in_bits_vpu_specVlmul;
  logic v23_io_in_bits_vpu_vm;
  logic [7:0] v23_io_in_bits_vpu_vstart;
  logic [2:0] v23_io_in_bits_vpu_frm;
  logic v23_io_in_bits_vpu_fpu_isFpToVecInst;
  logic v23_io_in_bits_vpu_fpu_isFP32Instr;
  logic v23_io_in_bits_vpu_fpu_isFP64Instr;
  logic v23_io_in_bits_vpu_fpu_isReduction;
  logic v23_io_in_bits_vpu_fpu_isFoldTo1_2;
  logic v23_io_in_bits_vpu_fpu_isFoldTo1_4;
  logic v23_io_in_bits_vpu_fpu_isFoldTo1_8;
  logic [1:0] v23_io_in_bits_vpu_vxrm;
  logic [6:0] v23_io_in_bits_vpu_vuopIdx;
  logic v23_io_in_bits_vpu_lastUop;
  logic [127:0] v23_io_in_bits_vpu_vmask;
  logic [2:0] v23_io_in_bits_vpu_nf;
  logic [1:0] v23_io_in_bits_vpu_veew;
  logic v23_io_in_bits_vpu_isReverse;
  logic v23_io_in_bits_vpu_isExt;
  logic v23_io_in_bits_vpu_isNarrow;
  logic v23_io_in_bits_vpu_isDstMask;
  logic v23_io_in_bits_vpu_isOpMask;
  logic v23_io_in_bits_vpu_isMove;
  logic v23_io_in_bits_vpu_isDependOldVd;
  logic v23_io_in_bits_vpu_isWritePartVd;
  logic v23_io_in_bits_vpu_isVleff;
  logic v23_io_in_bits_ftqIdx_flag;
  logic [5:0] v23_io_in_bits_ftqIdx_value;
  logic [3:0] v23_io_in_bits_ftqOffset;
  logic [4:0] v23_io_in_bits_numLsElem;
  logic v23_io_in_bits_sqIdx_flag;
  logic [5:0] v23_io_in_bits_sqIdx_value;
  logic v23_io_in_bits_lqIdx_flag;
  logic [6:0] v23_io_in_bits_lqIdx_value;
  logic v23_io_in_bits_isVecPartReplay;
  logic [15:0] v23_io_in_bits_vecReplayMask;
  logic [3:0] v23_io_in_bits_vecReplayMbIdx;
  logic v23_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] v23_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] v23_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] v23_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] v23_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] v23_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] v23_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] v23_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] v23_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] v23_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] v23_io_in_bits_debug_seqNum_seqNum;
  logic [7:0] v23_io_in_bits_debug_seqNum_uopIdx;
  logic v23_io_out_ready;
  logic v23_io_rightOutFire;
  logic v23_io_isFlush;
  logic v23_io_isOlder;
  wire  g_v23_io_in_ready, i_v23_io_in_ready;
  wire  g_v23_io_out_valid, i_v23_io_out_valid;
  wire  [34:0] g_v23_io_out_bits_fuType, i_v23_io_out_bits_fuType;
  wire  [8:0] g_v23_io_out_bits_fuOpType, i_v23_io_out_bits_fuOpType;
  wire  [127:0] g_v23_io_out_bits_src_0, i_v23_io_out_bits_src_0;
  wire  [127:0] g_v23_io_out_bits_src_1, i_v23_io_out_bits_src_1;
  wire  [127:0] g_v23_io_out_bits_src_2, i_v23_io_out_bits_src_2;
  wire  [127:0] g_v23_io_out_bits_src_3, i_v23_io_out_bits_src_3;
  wire  [127:0] g_v23_io_out_bits_src_4, i_v23_io_out_bits_src_4;
  wire  g_v23_io_out_bits_robIdx_flag, i_v23_io_out_bits_robIdx_flag;
  wire  [7:0] g_v23_io_out_bits_robIdx_value, i_v23_io_out_bits_robIdx_value;
  wire  [6:0] g_v23_io_out_bits_pdest, i_v23_io_out_bits_pdest;
  wire  g_v23_io_out_bits_vecWen, i_v23_io_out_bits_vecWen;
  wire  g_v23_io_out_bits_v0Wen, i_v23_io_out_bits_v0Wen;
  wire  g_v23_io_out_bits_vlWen, i_v23_io_out_bits_vlWen;
  wire  g_v23_io_out_bits_vpu_vill, i_v23_io_out_bits_vpu_vill;
  wire  g_v23_io_out_bits_vpu_vma, i_v23_io_out_bits_vpu_vma;
  wire  g_v23_io_out_bits_vpu_vta, i_v23_io_out_bits_vpu_vta;
  wire  [1:0] g_v23_io_out_bits_vpu_vsew, i_v23_io_out_bits_vpu_vsew;
  wire  [2:0] g_v23_io_out_bits_vpu_vlmul, i_v23_io_out_bits_vpu_vlmul;
  wire  g_v23_io_out_bits_vpu_specVill, i_v23_io_out_bits_vpu_specVill;
  wire  g_v23_io_out_bits_vpu_specVma, i_v23_io_out_bits_vpu_specVma;
  wire  g_v23_io_out_bits_vpu_specVta, i_v23_io_out_bits_vpu_specVta;
  wire  [1:0] g_v23_io_out_bits_vpu_specVsew, i_v23_io_out_bits_vpu_specVsew;
  wire  [2:0] g_v23_io_out_bits_vpu_specVlmul, i_v23_io_out_bits_vpu_specVlmul;
  wire  g_v23_io_out_bits_vpu_vm, i_v23_io_out_bits_vpu_vm;
  wire  [7:0] g_v23_io_out_bits_vpu_vstart, i_v23_io_out_bits_vpu_vstart;
  wire  [2:0] g_v23_io_out_bits_vpu_frm, i_v23_io_out_bits_vpu_frm;
  wire  g_v23_io_out_bits_vpu_fpu_isFpToVecInst, i_v23_io_out_bits_vpu_fpu_isFpToVecInst;
  wire  g_v23_io_out_bits_vpu_fpu_isFP32Instr, i_v23_io_out_bits_vpu_fpu_isFP32Instr;
  wire  g_v23_io_out_bits_vpu_fpu_isFP64Instr, i_v23_io_out_bits_vpu_fpu_isFP64Instr;
  wire  g_v23_io_out_bits_vpu_fpu_isReduction, i_v23_io_out_bits_vpu_fpu_isReduction;
  wire  g_v23_io_out_bits_vpu_fpu_isFoldTo1_2, i_v23_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire  g_v23_io_out_bits_vpu_fpu_isFoldTo1_4, i_v23_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire  g_v23_io_out_bits_vpu_fpu_isFoldTo1_8, i_v23_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire  [1:0] g_v23_io_out_bits_vpu_vxrm, i_v23_io_out_bits_vpu_vxrm;
  wire  [6:0] g_v23_io_out_bits_vpu_vuopIdx, i_v23_io_out_bits_vpu_vuopIdx;
  wire  g_v23_io_out_bits_vpu_lastUop, i_v23_io_out_bits_vpu_lastUop;
  wire  [127:0] g_v23_io_out_bits_vpu_vmask, i_v23_io_out_bits_vpu_vmask;
  wire  [2:0] g_v23_io_out_bits_vpu_nf, i_v23_io_out_bits_vpu_nf;
  wire  [1:0] g_v23_io_out_bits_vpu_veew, i_v23_io_out_bits_vpu_veew;
  wire  g_v23_io_out_bits_vpu_isReverse, i_v23_io_out_bits_vpu_isReverse;
  wire  g_v23_io_out_bits_vpu_isExt, i_v23_io_out_bits_vpu_isExt;
  wire  g_v23_io_out_bits_vpu_isNarrow, i_v23_io_out_bits_vpu_isNarrow;
  wire  g_v23_io_out_bits_vpu_isDstMask, i_v23_io_out_bits_vpu_isDstMask;
  wire  g_v23_io_out_bits_vpu_isOpMask, i_v23_io_out_bits_vpu_isOpMask;
  wire  g_v23_io_out_bits_vpu_isMove, i_v23_io_out_bits_vpu_isMove;
  wire  g_v23_io_out_bits_vpu_isDependOldVd, i_v23_io_out_bits_vpu_isDependOldVd;
  wire  g_v23_io_out_bits_vpu_isWritePartVd, i_v23_io_out_bits_vpu_isWritePartVd;
  wire  g_v23_io_out_bits_vpu_isVleff, i_v23_io_out_bits_vpu_isVleff;
  wire  g_v23_io_out_bits_ftqIdx_flag, i_v23_io_out_bits_ftqIdx_flag;
  wire  [5:0] g_v23_io_out_bits_ftqIdx_value, i_v23_io_out_bits_ftqIdx_value;
  wire  [3:0] g_v23_io_out_bits_ftqOffset, i_v23_io_out_bits_ftqOffset;
  wire  [4:0] g_v23_io_out_bits_numLsElem, i_v23_io_out_bits_numLsElem;
  wire  g_v23_io_out_bits_sqIdx_flag, i_v23_io_out_bits_sqIdx_flag;
  wire  [5:0] g_v23_io_out_bits_sqIdx_value, i_v23_io_out_bits_sqIdx_value;
  wire  g_v23_io_out_bits_lqIdx_flag, i_v23_io_out_bits_lqIdx_flag;
  wire  [6:0] g_v23_io_out_bits_lqIdx_value, i_v23_io_out_bits_lqIdx_value;
  wire  g_v23_io_out_bits_isVecPartReplay, i_v23_io_out_bits_isVecPartReplay;
  wire  [15:0] g_v23_io_out_bits_vecReplayMask, i_v23_io_out_bits_vecReplayMask;
  wire  [3:0] g_v23_io_out_bits_vecReplayMbIdx, i_v23_io_out_bits_vecReplayMbIdx;
  wire  g_v23_io_out_bits_perfDebugInfo_eliminatedMove, i_v23_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_v23_io_out_bits_perfDebugInfo_renameTime, i_v23_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_v23_io_out_bits_perfDebugInfo_dispatchTime, i_v23_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_v23_io_out_bits_perfDebugInfo_enqRsTime, i_v23_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_v23_io_out_bits_perfDebugInfo_selectTime, i_v23_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_v23_io_out_bits_perfDebugInfo_issueTime, i_v23_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_v23_io_out_bits_perfDebugInfo_writebackTime, i_v23_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_v23_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_v23_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v23_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_v23_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_v23_io_out_bits_perfDebugInfo_tlbRespTime, i_v23_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_v23_io_out_bits_debug_seqNum_seqNum, i_v23_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_v23_io_out_bits_debug_seqNum_uopIdx, i_v23_io_out_bits_debug_seqNum_uopIdx;
  longint nchk_v23 = 0; int nerr_v23 = 0;
  longint fire_v23 = 0, bp_v23 = 0, flush_v23 = 0, hold_v23 = 0, ov_v23 = 0;
  longint olderdec_v23 = 0;
  logic [1582:0] por_v23 = '0, pand_v23 = '1;   // payload 按位或 / 按位与
  wire  [1582:0] pcat_v23 = {v23_io_in_bits_fuType, v23_io_in_bits_fuOpType, v23_io_in_bits_src_0, v23_io_in_bits_src_1, v23_io_in_bits_src_2, v23_io_in_bits_src_3, v23_io_in_bits_src_4, v23_io_in_bits_robIdx_flag, v23_io_in_bits_robIdx_value, v23_io_in_bits_pdest, v23_io_in_bits_vecWen, v23_io_in_bits_v0Wen, v23_io_in_bits_vlWen, v23_io_in_bits_vpu_vill, v23_io_in_bits_vpu_vma, v23_io_in_bits_vpu_vta, v23_io_in_bits_vpu_vsew, v23_io_in_bits_vpu_vlmul, v23_io_in_bits_vpu_specVill, v23_io_in_bits_vpu_specVma, v23_io_in_bits_vpu_specVta, v23_io_in_bits_vpu_specVsew, v23_io_in_bits_vpu_specVlmul, v23_io_in_bits_vpu_vm, v23_io_in_bits_vpu_vstart, v23_io_in_bits_vpu_frm, v23_io_in_bits_vpu_fpu_isFpToVecInst, v23_io_in_bits_vpu_fpu_isFP32Instr, v23_io_in_bits_vpu_fpu_isFP64Instr, v23_io_in_bits_vpu_fpu_isReduction, v23_io_in_bits_vpu_fpu_isFoldTo1_2, v23_io_in_bits_vpu_fpu_isFoldTo1_4, v23_io_in_bits_vpu_fpu_isFoldTo1_8, v23_io_in_bits_vpu_vxrm, v23_io_in_bits_vpu_vuopIdx, v23_io_in_bits_vpu_lastUop, v23_io_in_bits_vpu_vmask, v23_io_in_bits_vpu_nf, v23_io_in_bits_vpu_veew, v23_io_in_bits_vpu_isReverse, v23_io_in_bits_vpu_isExt, v23_io_in_bits_vpu_isNarrow, v23_io_in_bits_vpu_isDstMask, v23_io_in_bits_vpu_isOpMask, v23_io_in_bits_vpu_isMove, v23_io_in_bits_vpu_isDependOldVd, v23_io_in_bits_vpu_isWritePartVd, v23_io_in_bits_vpu_isVleff, v23_io_in_bits_ftqIdx_flag, v23_io_in_bits_ftqIdx_value, v23_io_in_bits_ftqOffset, v23_io_in_bits_numLsElem, v23_io_in_bits_sqIdx_flag, v23_io_in_bits_sqIdx_value, v23_io_in_bits_lqIdx_flag, v23_io_in_bits_lqIdx_value, v23_io_in_bits_isVecPartReplay, v23_io_in_bits_vecReplayMask, v23_io_in_bits_vecReplayMbIdx, v23_io_in_bits_perfDebugInfo_eliminatedMove, v23_io_in_bits_perfDebugInfo_renameTime, v23_io_in_bits_perfDebugInfo_dispatchTime, v23_io_in_bits_perfDebugInfo_enqRsTime, v23_io_in_bits_perfDebugInfo_selectTime, v23_io_in_bits_perfDebugInfo_issueTime, v23_io_in_bits_perfDebugInfo_writebackTime, v23_io_in_bits_perfDebugInfo_runahead_checkpoint_id, v23_io_in_bits_perfDebugInfo_tlbFirstReqTime, v23_io_in_bits_perfDebugInfo_tlbRespTime, v23_io_in_bits_debug_seqNum_seqNum, v23_io_in_bits_debug_seqNum_uopIdx};
  NewPipelineConnectPipe_23 u_g_v23 (
    .clock(clock), .reset(reset),
    .io_in_valid(v23_io_in_valid),
    .io_in_bits_fuType(v23_io_in_bits_fuType),
    .io_in_bits_fuOpType(v23_io_in_bits_fuOpType),
    .io_in_bits_src_0(v23_io_in_bits_src_0),
    .io_in_bits_src_1(v23_io_in_bits_src_1),
    .io_in_bits_src_2(v23_io_in_bits_src_2),
    .io_in_bits_src_3(v23_io_in_bits_src_3),
    .io_in_bits_src_4(v23_io_in_bits_src_4),
    .io_in_bits_robIdx_flag(v23_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v23_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v23_io_in_bits_pdest),
    .io_in_bits_vecWen(v23_io_in_bits_vecWen),
    .io_in_bits_v0Wen(v23_io_in_bits_v0Wen),
    .io_in_bits_vlWen(v23_io_in_bits_vlWen),
    .io_in_bits_vpu_vill(v23_io_in_bits_vpu_vill),
    .io_in_bits_vpu_vma(v23_io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta(v23_io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew(v23_io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul(v23_io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_specVill(v23_io_in_bits_vpu_specVill),
    .io_in_bits_vpu_specVma(v23_io_in_bits_vpu_specVma),
    .io_in_bits_vpu_specVta(v23_io_in_bits_vpu_specVta),
    .io_in_bits_vpu_specVsew(v23_io_in_bits_vpu_specVsew),
    .io_in_bits_vpu_specVlmul(v23_io_in_bits_vpu_specVlmul),
    .io_in_bits_vpu_vm(v23_io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart(v23_io_in_bits_vpu_vstart),
    .io_in_bits_vpu_frm(v23_io_in_bits_vpu_frm),
    .io_in_bits_vpu_fpu_isFpToVecInst(v23_io_in_bits_vpu_fpu_isFpToVecInst),
    .io_in_bits_vpu_fpu_isFP32Instr(v23_io_in_bits_vpu_fpu_isFP32Instr),
    .io_in_bits_vpu_fpu_isFP64Instr(v23_io_in_bits_vpu_fpu_isFP64Instr),
    .io_in_bits_vpu_fpu_isReduction(v23_io_in_bits_vpu_fpu_isReduction),
    .io_in_bits_vpu_fpu_isFoldTo1_2(v23_io_in_bits_vpu_fpu_isFoldTo1_2),
    .io_in_bits_vpu_fpu_isFoldTo1_4(v23_io_in_bits_vpu_fpu_isFoldTo1_4),
    .io_in_bits_vpu_fpu_isFoldTo1_8(v23_io_in_bits_vpu_fpu_isFoldTo1_8),
    .io_in_bits_vpu_vxrm(v23_io_in_bits_vpu_vxrm),
    .io_in_bits_vpu_vuopIdx(v23_io_in_bits_vpu_vuopIdx),
    .io_in_bits_vpu_lastUop(v23_io_in_bits_vpu_lastUop),
    .io_in_bits_vpu_vmask(v23_io_in_bits_vpu_vmask),
    .io_in_bits_vpu_nf(v23_io_in_bits_vpu_nf),
    .io_in_bits_vpu_veew(v23_io_in_bits_vpu_veew),
    .io_in_bits_vpu_isReverse(v23_io_in_bits_vpu_isReverse),
    .io_in_bits_vpu_isExt(v23_io_in_bits_vpu_isExt),
    .io_in_bits_vpu_isNarrow(v23_io_in_bits_vpu_isNarrow),
    .io_in_bits_vpu_isDstMask(v23_io_in_bits_vpu_isDstMask),
    .io_in_bits_vpu_isOpMask(v23_io_in_bits_vpu_isOpMask),
    .io_in_bits_vpu_isMove(v23_io_in_bits_vpu_isMove),
    .io_in_bits_vpu_isDependOldVd(v23_io_in_bits_vpu_isDependOldVd),
    .io_in_bits_vpu_isWritePartVd(v23_io_in_bits_vpu_isWritePartVd),
    .io_in_bits_vpu_isVleff(v23_io_in_bits_vpu_isVleff),
    .io_in_bits_ftqIdx_flag(v23_io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(v23_io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(v23_io_in_bits_ftqOffset),
    .io_in_bits_numLsElem(v23_io_in_bits_numLsElem),
    .io_in_bits_sqIdx_flag(v23_io_in_bits_sqIdx_flag),
    .io_in_bits_sqIdx_value(v23_io_in_bits_sqIdx_value),
    .io_in_bits_lqIdx_flag(v23_io_in_bits_lqIdx_flag),
    .io_in_bits_lqIdx_value(v23_io_in_bits_lqIdx_value),
    .io_in_bits_isVecPartReplay(v23_io_in_bits_isVecPartReplay),
    .io_in_bits_vecReplayMask(v23_io_in_bits_vecReplayMask),
    .io_in_bits_vecReplayMbIdx(v23_io_in_bits_vecReplayMbIdx),
    .io_in_bits_perfDebugInfo_eliminatedMove(v23_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v23_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v23_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v23_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v23_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v23_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v23_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v23_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v23_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v23_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v23_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v23_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v23_io_out_ready),
    .io_rightOutFire(v23_io_rightOutFire),
    .io_isFlush(v23_io_isFlush),
    .io_isOlder(v23_io_isOlder),
    .io_in_ready(g_v23_io_in_ready),
    .io_out_valid(g_v23_io_out_valid),
    .io_out_bits_fuType(g_v23_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v23_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v23_io_out_bits_src_0),
    .io_out_bits_src_1(g_v23_io_out_bits_src_1),
    .io_out_bits_src_2(g_v23_io_out_bits_src_2),
    .io_out_bits_src_3(g_v23_io_out_bits_src_3),
    .io_out_bits_src_4(g_v23_io_out_bits_src_4),
    .io_out_bits_robIdx_flag(g_v23_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v23_io_out_bits_robIdx_value),
    .io_out_bits_pdest(g_v23_io_out_bits_pdest),
    .io_out_bits_vecWen(g_v23_io_out_bits_vecWen),
    .io_out_bits_v0Wen(g_v23_io_out_bits_v0Wen),
    .io_out_bits_vlWen(g_v23_io_out_bits_vlWen),
    .io_out_bits_vpu_vill(g_v23_io_out_bits_vpu_vill),
    .io_out_bits_vpu_vma(g_v23_io_out_bits_vpu_vma),
    .io_out_bits_vpu_vta(g_v23_io_out_bits_vpu_vta),
    .io_out_bits_vpu_vsew(g_v23_io_out_bits_vpu_vsew),
    .io_out_bits_vpu_vlmul(g_v23_io_out_bits_vpu_vlmul),
    .io_out_bits_vpu_specVill(g_v23_io_out_bits_vpu_specVill),
    .io_out_bits_vpu_specVma(g_v23_io_out_bits_vpu_specVma),
    .io_out_bits_vpu_specVta(g_v23_io_out_bits_vpu_specVta),
    .io_out_bits_vpu_specVsew(g_v23_io_out_bits_vpu_specVsew),
    .io_out_bits_vpu_specVlmul(g_v23_io_out_bits_vpu_specVlmul),
    .io_out_bits_vpu_vm(g_v23_io_out_bits_vpu_vm),
    .io_out_bits_vpu_vstart(g_v23_io_out_bits_vpu_vstart),
    .io_out_bits_vpu_frm(g_v23_io_out_bits_vpu_frm),
    .io_out_bits_vpu_fpu_isFpToVecInst(g_v23_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_bits_vpu_fpu_isFP32Instr(g_v23_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_bits_vpu_fpu_isFP64Instr(g_v23_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_bits_vpu_fpu_isReduction(g_v23_io_out_bits_vpu_fpu_isReduction),
    .io_out_bits_vpu_fpu_isFoldTo1_2(g_v23_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_bits_vpu_fpu_isFoldTo1_4(g_v23_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_bits_vpu_fpu_isFoldTo1_8(g_v23_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_bits_vpu_vxrm(g_v23_io_out_bits_vpu_vxrm),
    .io_out_bits_vpu_vuopIdx(g_v23_io_out_bits_vpu_vuopIdx),
    .io_out_bits_vpu_lastUop(g_v23_io_out_bits_vpu_lastUop),
    .io_out_bits_vpu_vmask(g_v23_io_out_bits_vpu_vmask),
    .io_out_bits_vpu_nf(g_v23_io_out_bits_vpu_nf),
    .io_out_bits_vpu_veew(g_v23_io_out_bits_vpu_veew),
    .io_out_bits_vpu_isReverse(g_v23_io_out_bits_vpu_isReverse),
    .io_out_bits_vpu_isExt(g_v23_io_out_bits_vpu_isExt),
    .io_out_bits_vpu_isNarrow(g_v23_io_out_bits_vpu_isNarrow),
    .io_out_bits_vpu_isDstMask(g_v23_io_out_bits_vpu_isDstMask),
    .io_out_bits_vpu_isOpMask(g_v23_io_out_bits_vpu_isOpMask),
    .io_out_bits_vpu_isMove(g_v23_io_out_bits_vpu_isMove),
    .io_out_bits_vpu_isDependOldVd(g_v23_io_out_bits_vpu_isDependOldVd),
    .io_out_bits_vpu_isWritePartVd(g_v23_io_out_bits_vpu_isWritePartVd),
    .io_out_bits_vpu_isVleff(g_v23_io_out_bits_vpu_isVleff),
    .io_out_bits_ftqIdx_flag(g_v23_io_out_bits_ftqIdx_flag),
    .io_out_bits_ftqIdx_value(g_v23_io_out_bits_ftqIdx_value),
    .io_out_bits_ftqOffset(g_v23_io_out_bits_ftqOffset),
    .io_out_bits_numLsElem(g_v23_io_out_bits_numLsElem),
    .io_out_bits_sqIdx_flag(g_v23_io_out_bits_sqIdx_flag),
    .io_out_bits_sqIdx_value(g_v23_io_out_bits_sqIdx_value),
    .io_out_bits_lqIdx_flag(g_v23_io_out_bits_lqIdx_flag),
    .io_out_bits_lqIdx_value(g_v23_io_out_bits_lqIdx_value),
    .io_out_bits_isVecPartReplay(g_v23_io_out_bits_isVecPartReplay),
    .io_out_bits_vecReplayMask(g_v23_io_out_bits_vecReplayMask),
    .io_out_bits_vecReplayMbIdx(g_v23_io_out_bits_vecReplayMbIdx),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_v23_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_v23_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_v23_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_v23_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_v23_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_v23_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_v23_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_v23_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_v23_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_v23_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_v23_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_v23_io_out_bits_debug_seqNum_uopIdx)
  );
  NewPipelineConnectPipe_23_xs u_i_v23 (
    .clock(clock), .reset(reset),
    .io_in_valid(v23_io_in_valid),
    .io_in_bits_fuType(v23_io_in_bits_fuType),
    .io_in_bits_fuOpType(v23_io_in_bits_fuOpType),
    .io_in_bits_src_0(v23_io_in_bits_src_0),
    .io_in_bits_src_1(v23_io_in_bits_src_1),
    .io_in_bits_src_2(v23_io_in_bits_src_2),
    .io_in_bits_src_3(v23_io_in_bits_src_3),
    .io_in_bits_src_4(v23_io_in_bits_src_4),
    .io_in_bits_robIdx_flag(v23_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v23_io_in_bits_robIdx_value),
    .io_in_bits_pdest(v23_io_in_bits_pdest),
    .io_in_bits_vecWen(v23_io_in_bits_vecWen),
    .io_in_bits_v0Wen(v23_io_in_bits_v0Wen),
    .io_in_bits_vlWen(v23_io_in_bits_vlWen),
    .io_in_bits_vpu_vill(v23_io_in_bits_vpu_vill),
    .io_in_bits_vpu_vma(v23_io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta(v23_io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew(v23_io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul(v23_io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_specVill(v23_io_in_bits_vpu_specVill),
    .io_in_bits_vpu_specVma(v23_io_in_bits_vpu_specVma),
    .io_in_bits_vpu_specVta(v23_io_in_bits_vpu_specVta),
    .io_in_bits_vpu_specVsew(v23_io_in_bits_vpu_specVsew),
    .io_in_bits_vpu_specVlmul(v23_io_in_bits_vpu_specVlmul),
    .io_in_bits_vpu_vm(v23_io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart(v23_io_in_bits_vpu_vstart),
    .io_in_bits_vpu_frm(v23_io_in_bits_vpu_frm),
    .io_in_bits_vpu_fpu_isFpToVecInst(v23_io_in_bits_vpu_fpu_isFpToVecInst),
    .io_in_bits_vpu_fpu_isFP32Instr(v23_io_in_bits_vpu_fpu_isFP32Instr),
    .io_in_bits_vpu_fpu_isFP64Instr(v23_io_in_bits_vpu_fpu_isFP64Instr),
    .io_in_bits_vpu_fpu_isReduction(v23_io_in_bits_vpu_fpu_isReduction),
    .io_in_bits_vpu_fpu_isFoldTo1_2(v23_io_in_bits_vpu_fpu_isFoldTo1_2),
    .io_in_bits_vpu_fpu_isFoldTo1_4(v23_io_in_bits_vpu_fpu_isFoldTo1_4),
    .io_in_bits_vpu_fpu_isFoldTo1_8(v23_io_in_bits_vpu_fpu_isFoldTo1_8),
    .io_in_bits_vpu_vxrm(v23_io_in_bits_vpu_vxrm),
    .io_in_bits_vpu_vuopIdx(v23_io_in_bits_vpu_vuopIdx),
    .io_in_bits_vpu_lastUop(v23_io_in_bits_vpu_lastUop),
    .io_in_bits_vpu_vmask(v23_io_in_bits_vpu_vmask),
    .io_in_bits_vpu_nf(v23_io_in_bits_vpu_nf),
    .io_in_bits_vpu_veew(v23_io_in_bits_vpu_veew),
    .io_in_bits_vpu_isReverse(v23_io_in_bits_vpu_isReverse),
    .io_in_bits_vpu_isExt(v23_io_in_bits_vpu_isExt),
    .io_in_bits_vpu_isNarrow(v23_io_in_bits_vpu_isNarrow),
    .io_in_bits_vpu_isDstMask(v23_io_in_bits_vpu_isDstMask),
    .io_in_bits_vpu_isOpMask(v23_io_in_bits_vpu_isOpMask),
    .io_in_bits_vpu_isMove(v23_io_in_bits_vpu_isMove),
    .io_in_bits_vpu_isDependOldVd(v23_io_in_bits_vpu_isDependOldVd),
    .io_in_bits_vpu_isWritePartVd(v23_io_in_bits_vpu_isWritePartVd),
    .io_in_bits_vpu_isVleff(v23_io_in_bits_vpu_isVleff),
    .io_in_bits_ftqIdx_flag(v23_io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(v23_io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(v23_io_in_bits_ftqOffset),
    .io_in_bits_numLsElem(v23_io_in_bits_numLsElem),
    .io_in_bits_sqIdx_flag(v23_io_in_bits_sqIdx_flag),
    .io_in_bits_sqIdx_value(v23_io_in_bits_sqIdx_value),
    .io_in_bits_lqIdx_flag(v23_io_in_bits_lqIdx_flag),
    .io_in_bits_lqIdx_value(v23_io_in_bits_lqIdx_value),
    .io_in_bits_isVecPartReplay(v23_io_in_bits_isVecPartReplay),
    .io_in_bits_vecReplayMask(v23_io_in_bits_vecReplayMask),
    .io_in_bits_vecReplayMbIdx(v23_io_in_bits_vecReplayMbIdx),
    .io_in_bits_perfDebugInfo_eliminatedMove(v23_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(v23_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(v23_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(v23_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(v23_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(v23_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(v23_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(v23_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(v23_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(v23_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(v23_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(v23_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(v23_io_out_ready),
    .io_rightOutFire(v23_io_rightOutFire),
    .io_isFlush(v23_io_isFlush),
    .io_isOlder(v23_io_isOlder),
    .io_in_ready(i_v23_io_in_ready),
    .io_out_valid(i_v23_io_out_valid),
    .io_out_bits_fuType(i_v23_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v23_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v23_io_out_bits_src_0),
    .io_out_bits_src_1(i_v23_io_out_bits_src_1),
    .io_out_bits_src_2(i_v23_io_out_bits_src_2),
    .io_out_bits_src_3(i_v23_io_out_bits_src_3),
    .io_out_bits_src_4(i_v23_io_out_bits_src_4),
    .io_out_bits_robIdx_flag(i_v23_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v23_io_out_bits_robIdx_value),
    .io_out_bits_pdest(i_v23_io_out_bits_pdest),
    .io_out_bits_vecWen(i_v23_io_out_bits_vecWen),
    .io_out_bits_v0Wen(i_v23_io_out_bits_v0Wen),
    .io_out_bits_vlWen(i_v23_io_out_bits_vlWen),
    .io_out_bits_vpu_vill(i_v23_io_out_bits_vpu_vill),
    .io_out_bits_vpu_vma(i_v23_io_out_bits_vpu_vma),
    .io_out_bits_vpu_vta(i_v23_io_out_bits_vpu_vta),
    .io_out_bits_vpu_vsew(i_v23_io_out_bits_vpu_vsew),
    .io_out_bits_vpu_vlmul(i_v23_io_out_bits_vpu_vlmul),
    .io_out_bits_vpu_specVill(i_v23_io_out_bits_vpu_specVill),
    .io_out_bits_vpu_specVma(i_v23_io_out_bits_vpu_specVma),
    .io_out_bits_vpu_specVta(i_v23_io_out_bits_vpu_specVta),
    .io_out_bits_vpu_specVsew(i_v23_io_out_bits_vpu_specVsew),
    .io_out_bits_vpu_specVlmul(i_v23_io_out_bits_vpu_specVlmul),
    .io_out_bits_vpu_vm(i_v23_io_out_bits_vpu_vm),
    .io_out_bits_vpu_vstart(i_v23_io_out_bits_vpu_vstart),
    .io_out_bits_vpu_frm(i_v23_io_out_bits_vpu_frm),
    .io_out_bits_vpu_fpu_isFpToVecInst(i_v23_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_bits_vpu_fpu_isFP32Instr(i_v23_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_bits_vpu_fpu_isFP64Instr(i_v23_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_bits_vpu_fpu_isReduction(i_v23_io_out_bits_vpu_fpu_isReduction),
    .io_out_bits_vpu_fpu_isFoldTo1_2(i_v23_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_bits_vpu_fpu_isFoldTo1_4(i_v23_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_bits_vpu_fpu_isFoldTo1_8(i_v23_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_bits_vpu_vxrm(i_v23_io_out_bits_vpu_vxrm),
    .io_out_bits_vpu_vuopIdx(i_v23_io_out_bits_vpu_vuopIdx),
    .io_out_bits_vpu_lastUop(i_v23_io_out_bits_vpu_lastUop),
    .io_out_bits_vpu_vmask(i_v23_io_out_bits_vpu_vmask),
    .io_out_bits_vpu_nf(i_v23_io_out_bits_vpu_nf),
    .io_out_bits_vpu_veew(i_v23_io_out_bits_vpu_veew),
    .io_out_bits_vpu_isReverse(i_v23_io_out_bits_vpu_isReverse),
    .io_out_bits_vpu_isExt(i_v23_io_out_bits_vpu_isExt),
    .io_out_bits_vpu_isNarrow(i_v23_io_out_bits_vpu_isNarrow),
    .io_out_bits_vpu_isDstMask(i_v23_io_out_bits_vpu_isDstMask),
    .io_out_bits_vpu_isOpMask(i_v23_io_out_bits_vpu_isOpMask),
    .io_out_bits_vpu_isMove(i_v23_io_out_bits_vpu_isMove),
    .io_out_bits_vpu_isDependOldVd(i_v23_io_out_bits_vpu_isDependOldVd),
    .io_out_bits_vpu_isWritePartVd(i_v23_io_out_bits_vpu_isWritePartVd),
    .io_out_bits_vpu_isVleff(i_v23_io_out_bits_vpu_isVleff),
    .io_out_bits_ftqIdx_flag(i_v23_io_out_bits_ftqIdx_flag),
    .io_out_bits_ftqIdx_value(i_v23_io_out_bits_ftqIdx_value),
    .io_out_bits_ftqOffset(i_v23_io_out_bits_ftqOffset),
    .io_out_bits_numLsElem(i_v23_io_out_bits_numLsElem),
    .io_out_bits_sqIdx_flag(i_v23_io_out_bits_sqIdx_flag),
    .io_out_bits_sqIdx_value(i_v23_io_out_bits_sqIdx_value),
    .io_out_bits_lqIdx_flag(i_v23_io_out_bits_lqIdx_flag),
    .io_out_bits_lqIdx_value(i_v23_io_out_bits_lqIdx_value),
    .io_out_bits_isVecPartReplay(i_v23_io_out_bits_isVecPartReplay),
    .io_out_bits_vecReplayMask(i_v23_io_out_bits_vecReplayMask),
    .io_out_bits_vecReplayMbIdx(i_v23_io_out_bits_vecReplayMbIdx),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_v23_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_v23_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_v23_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_v23_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_v23_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_v23_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_v23_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_v23_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_v23_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_v23_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_v23_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_v23_io_out_bits_debug_seqNum_uopIdx)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_25 —— 7 字段 / 124 位 payload
  // ==========================================================================
  logic v25_io_in_valid;
  logic [34:0] v25_io_in_bits_fuType;
  logic [8:0] v25_io_in_bits_fuOpType;
  logic [63:0] v25_io_in_bits_src_0;
  logic v25_io_in_bits_robIdx_flag;
  logic [7:0] v25_io_in_bits_robIdx_value;
  logic v25_io_in_bits_sqIdx_flag;
  logic [5:0] v25_io_in_bits_sqIdx_value;
  logic v25_io_out_ready;
  logic v25_io_rightOutFire;
  logic v25_io_isFlush;
  wire  g_v25_io_in_ready, i_v25_io_in_ready;
  wire  g_v25_io_out_valid, i_v25_io_out_valid;
  wire  [34:0] g_v25_io_out_bits_fuType, i_v25_io_out_bits_fuType;
  wire  [8:0] g_v25_io_out_bits_fuOpType, i_v25_io_out_bits_fuOpType;
  wire  [63:0] g_v25_io_out_bits_src_0, i_v25_io_out_bits_src_0;
  wire  g_v25_io_out_bits_robIdx_flag, i_v25_io_out_bits_robIdx_flag;
  wire  [7:0] g_v25_io_out_bits_robIdx_value, i_v25_io_out_bits_robIdx_value;
  wire  g_v25_io_out_bits_sqIdx_flag, i_v25_io_out_bits_sqIdx_flag;
  wire  [5:0] g_v25_io_out_bits_sqIdx_value, i_v25_io_out_bits_sqIdx_value;
  longint nchk_v25 = 0; int nerr_v25 = 0;
  longint fire_v25 = 0, bp_v25 = 0, flush_v25 = 0, hold_v25 = 0, ov_v25 = 0;
  logic [123:0] por_v25 = '0, pand_v25 = '1;   // payload 按位或 / 按位与
  wire  [123:0] pcat_v25 = {v25_io_in_bits_fuType, v25_io_in_bits_fuOpType, v25_io_in_bits_src_0, v25_io_in_bits_robIdx_flag, v25_io_in_bits_robIdx_value, v25_io_in_bits_sqIdx_flag, v25_io_in_bits_sqIdx_value};
  NewPipelineConnectPipe_25 u_g_v25 (
    .clock(clock), .reset(reset),
    .io_in_valid(v25_io_in_valid),
    .io_in_bits_fuType(v25_io_in_bits_fuType),
    .io_in_bits_fuOpType(v25_io_in_bits_fuOpType),
    .io_in_bits_src_0(v25_io_in_bits_src_0),
    .io_in_bits_robIdx_flag(v25_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v25_io_in_bits_robIdx_value),
    .io_in_bits_sqIdx_flag(v25_io_in_bits_sqIdx_flag),
    .io_in_bits_sqIdx_value(v25_io_in_bits_sqIdx_value),
    .io_out_ready(v25_io_out_ready),
    .io_rightOutFire(v25_io_rightOutFire),
    .io_isFlush(v25_io_isFlush),
    .io_in_ready(g_v25_io_in_ready),
    .io_out_valid(g_v25_io_out_valid),
    .io_out_bits_fuType(g_v25_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_v25_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_v25_io_out_bits_src_0),
    .io_out_bits_robIdx_flag(g_v25_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_v25_io_out_bits_robIdx_value),
    .io_out_bits_sqIdx_flag(g_v25_io_out_bits_sqIdx_flag),
    .io_out_bits_sqIdx_value(g_v25_io_out_bits_sqIdx_value)
  );
  NewPipelineConnectPipe_25_xs u_i_v25 (
    .clock(clock), .reset(reset),
    .io_in_valid(v25_io_in_valid),
    .io_in_bits_fuType(v25_io_in_bits_fuType),
    .io_in_bits_fuOpType(v25_io_in_bits_fuOpType),
    .io_in_bits_src_0(v25_io_in_bits_src_0),
    .io_in_bits_robIdx_flag(v25_io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(v25_io_in_bits_robIdx_value),
    .io_in_bits_sqIdx_flag(v25_io_in_bits_sqIdx_flag),
    .io_in_bits_sqIdx_value(v25_io_in_bits_sqIdx_value),
    .io_out_ready(v25_io_out_ready),
    .io_rightOutFire(v25_io_rightOutFire),
    .io_isFlush(v25_io_isFlush),
    .io_in_ready(i_v25_io_in_ready),
    .io_out_valid(i_v25_io_out_valid),
    .io_out_bits_fuType(i_v25_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_v25_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_v25_io_out_bits_src_0),
    .io_out_bits_robIdx_flag(i_v25_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_v25_io_out_bits_robIdx_value),
    .io_out_bits_sqIdx_flag(i_v25_io_out_bits_sqIdx_flag),
    .io_out_bits_sqIdx_value(i_v25_io_out_bits_sqIdx_value)
  );

  task automatic drive_all();
    v0_io_in_valid     = ($urandom % 100) < 75;
    v0_io_out_ready    = ($urandom % 100) < 55;
    v0_io_rightOutFire = ($urandom % 100) < 50;
    v0_io_isFlush      = ($urandom % 512) == 0;
    v0_io_in_bits_fuType = 35'({$urandom, $urandom});
    v0_io_in_bits_fuOpType = 9'($urandom);
    v0_io_in_bits_src_0 = 64'({$urandom, $urandom});
    v0_io_in_bits_src_1 = 64'({$urandom, $urandom});
    v0_io_in_bits_robIdx_flag = 1'($urandom);
    v0_io_in_bits_robIdx_value = 8'($urandom);
    v0_io_in_bits_pdest = 8'($urandom);
    v0_io_in_bits_rfWen = 1'($urandom);
    v0_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v0_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v0_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v0_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v0_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v0_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v0_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v0_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v0_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v0_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v0_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v0_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v1_io_in_valid     = ($urandom % 100) < 75;
    v1_io_out_ready    = ($urandom % 100) < 55;
    v1_io_rightOutFire = ($urandom % 100) < 50;
    v1_io_isFlush      = ($urandom % 512) == 0;
    v1_io_in_bits_fuType = 35'({$urandom, $urandom});
    v1_io_in_bits_fuOpType = 9'($urandom);
    v1_io_in_bits_src_0 = 64'({$urandom, $urandom});
    v1_io_in_bits_src_1 = 64'({$urandom, $urandom});
    v1_io_in_bits_imm = 64'({$urandom, $urandom});
    v1_io_in_bits_nextPcOffset = 5'($urandom);
    v1_io_in_bits_robIdx_flag = 1'($urandom);
    v1_io_in_bits_robIdx_value = 8'($urandom);
    v1_io_in_bits_pdest = 8'($urandom);
    v1_io_in_bits_rfWen = 1'($urandom);
    v1_io_in_bits_pc = 50'({$urandom, $urandom});
    v1_io_in_bits_preDecode_valid = 1'($urandom);
    v1_io_in_bits_preDecode_isRVC = 1'($urandom);
    v1_io_in_bits_preDecode_brType = 2'($urandom);
    v1_io_in_bits_preDecode_isCall = 1'($urandom);
    v1_io_in_bits_preDecode_isRet = 1'($urandom);
    v1_io_in_bits_ftqIdx_flag = 1'($urandom);
    v1_io_in_bits_ftqIdx_value = 6'($urandom);
    v1_io_in_bits_ftqOffset = 4'($urandom);
    v1_io_in_bits_predictInfo_target = 50'({$urandom, $urandom});
    v1_io_in_bits_predictInfo_taken = 1'($urandom);
    v1_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v1_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v1_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v1_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v1_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v1_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v1_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v1_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v1_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v1_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v1_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v1_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v5_io_in_valid     = ($urandom % 100) < 75;
    v5_io_out_ready    = ($urandom % 100) < 55;
    v5_io_rightOutFire = ($urandom % 100) < 50;
    v5_io_isFlush      = ($urandom % 512) == 0;
    v5_io_in_bits_fuType = 35'({$urandom, $urandom});
    v5_io_in_bits_fuOpType = 9'($urandom);
    v5_io_in_bits_src_0 = 64'({$urandom, $urandom});
    v5_io_in_bits_src_1 = 64'({$urandom, $urandom});
    v5_io_in_bits_imm = 64'({$urandom, $urandom});
    v5_io_in_bits_nextPcOffset = 5'($urandom);
    v5_io_in_bits_robIdx_flag = 1'($urandom);
    v5_io_in_bits_robIdx_value = 8'($urandom);
    v5_io_in_bits_pdest = 8'($urandom);
    v5_io_in_bits_rfWen = 1'($urandom);
    v5_io_in_bits_fpWen = 1'($urandom);
    v5_io_in_bits_vecWen = 1'($urandom);
    v5_io_in_bits_v0Wen = 1'($urandom);
    v5_io_in_bits_vlWen = 1'($urandom);
    v5_io_in_bits_fpu_typeTagOut = 2'($urandom);
    v5_io_in_bits_fpu_wflags = 1'($urandom);
    v5_io_in_bits_fpu_typ = 2'($urandom);
    v5_io_in_bits_fpu_rm = 3'($urandom);
    v5_io_in_bits_pc = 50'({$urandom, $urandom});
    v5_io_in_bits_preDecode_valid = 1'($urandom);
    v5_io_in_bits_preDecode_isRVC = 1'($urandom);
    v5_io_in_bits_preDecode_brType = 2'($urandom);
    v5_io_in_bits_preDecode_isCall = 1'($urandom);
    v5_io_in_bits_preDecode_isRet = 1'($urandom);
    v5_io_in_bits_ftqIdx_flag = 1'($urandom);
    v5_io_in_bits_ftqIdx_value = 6'($urandom);
    v5_io_in_bits_ftqOffset = 4'($urandom);
    v5_io_in_bits_predictInfo_target = 50'({$urandom, $urandom});
    v5_io_in_bits_predictInfo_taken = 1'($urandom);
    v5_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v5_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v5_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v5_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v5_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v5_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v5_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v5_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v5_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v5_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v5_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v5_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v7_io_in_valid     = ($urandom % 100) < 75;
    v7_io_out_ready    = ($urandom % 100) < 55;
    v7_io_rightOutFire = ($urandom % 100) < 50;
    v7_io_isFlush      = ($urandom % 512) == 0;
    v7_io_in_bits_fuType = 35'({$urandom, $urandom});
    v7_io_in_bits_fuOpType = 9'($urandom);
    v7_io_in_bits_src_0 = 64'({$urandom, $urandom});
    v7_io_in_bits_src_1 = 64'({$urandom, $urandom});
    v7_io_in_bits_imm = 64'({$urandom, $urandom});
    v7_io_in_bits_robIdx_flag = 1'($urandom);
    v7_io_in_bits_robIdx_value = 8'($urandom);
    v7_io_in_bits_pdest = 8'($urandom);
    v7_io_in_bits_rfWen = 1'($urandom);
    v7_io_in_bits_flushPipe = 1'($urandom);
    v7_io_in_bits_preDecode_valid = 1'($urandom);
    v7_io_in_bits_preDecode_isRVC = 1'($urandom);
    v7_io_in_bits_preDecode_brType = 2'($urandom);
    v7_io_in_bits_preDecode_isCall = 1'($urandom);
    v7_io_in_bits_preDecode_isRet = 1'($urandom);
    v7_io_in_bits_ftqIdx_flag = 1'($urandom);
    v7_io_in_bits_ftqIdx_value = 6'($urandom);
    v7_io_in_bits_ftqOffset = 4'($urandom);
    v7_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v7_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v7_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v7_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v7_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v7_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v7_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v7_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v7_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v7_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v7_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v7_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v8_io_in_valid     = ($urandom % 100) < 75;
    v8_io_out_ready    = ($urandom % 100) < 55;
    v8_io_rightOutFire = ($urandom % 100) < 50;
    v8_io_isFlush      = ($urandom % 512) == 0;
    v8_io_in_bits_fuType = 35'({$urandom, $urandom});
    v8_io_in_bits_fuOpType = 9'($urandom);
    v8_io_in_bits_src_0 = 64'({$urandom, $urandom});
    v8_io_in_bits_src_1 = 64'({$urandom, $urandom});
    v8_io_in_bits_src_2 = 64'({$urandom, $urandom});
    v8_io_in_bits_robIdx_flag = 1'($urandom);
    v8_io_in_bits_robIdx_value = 8'($urandom);
    v8_io_in_bits_pdest = 8'($urandom);
    v8_io_in_bits_rfWen = 1'($urandom);
    v8_io_in_bits_fpWen = 1'($urandom);
    v8_io_in_bits_vecWen = 1'($urandom);
    v8_io_in_bits_v0Wen = 1'($urandom);
    v8_io_in_bits_fpu_wflags = 1'($urandom);
    v8_io_in_bits_fpu_fmt = 2'($urandom);
    v8_io_in_bits_fpu_rm = 3'($urandom);
    v8_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v8_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v8_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v8_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v8_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v8_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v8_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v8_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v8_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v8_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v8_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v8_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v9_io_in_valid     = ($urandom % 100) < 75;
    v9_io_out_ready    = ($urandom % 100) < 55;
    v9_io_rightOutFire = ($urandom % 100) < 50;
    v9_io_isFlush      = ($urandom % 512) == 0;
    v9_io_in_bits_fuType = 35'({$urandom, $urandom});
    v9_io_in_bits_fuOpType = 9'($urandom);
    v9_io_in_bits_src_0 = 64'({$urandom, $urandom});
    v9_io_in_bits_src_1 = 64'({$urandom, $urandom});
    v9_io_in_bits_robIdx_flag = 1'($urandom);
    v9_io_in_bits_robIdx_value = 8'($urandom);
    v9_io_in_bits_pdest = 8'($urandom);
    v9_io_in_bits_fpWen = 1'($urandom);
    v9_io_in_bits_fpu_wflags = 1'($urandom);
    v9_io_in_bits_fpu_fmt = 2'($urandom);
    v9_io_in_bits_fpu_rm = 3'($urandom);
    v9_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v9_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v9_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v9_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v9_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v9_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v9_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v9_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v9_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v9_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v9_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v9_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v10_io_in_valid     = ($urandom % 100) < 75;
    v10_io_out_ready    = ($urandom % 100) < 55;
    v10_io_rightOutFire = ($urandom % 100) < 50;
    v10_io_isFlush      = ($urandom % 512) == 0;
    v10_io_in_bits_fuType = 35'({$urandom, $urandom});
    v10_io_in_bits_fuOpType = 9'($urandom);
    v10_io_in_bits_src_0 = 64'({$urandom, $urandom});
    v10_io_in_bits_src_1 = 64'({$urandom, $urandom});
    v10_io_in_bits_src_2 = 64'({$urandom, $urandom});
    v10_io_in_bits_robIdx_flag = 1'($urandom);
    v10_io_in_bits_robIdx_value = 8'($urandom);
    v10_io_in_bits_pdest = 8'($urandom);
    v10_io_in_bits_rfWen = 1'($urandom);
    v10_io_in_bits_fpWen = 1'($urandom);
    v10_io_in_bits_fpu_wflags = 1'($urandom);
    v10_io_in_bits_fpu_fmt = 2'($urandom);
    v10_io_in_bits_fpu_rm = 3'($urandom);
    v10_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v10_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v10_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v10_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v10_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v10_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v10_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v10_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v10_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v10_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v10_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v10_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v13_io_in_valid     = ($urandom % 100) < 75;
    v13_io_out_ready    = ($urandom % 100) < 55;
    v13_io_rightOutFire = ($urandom % 100) < 50;
    v13_io_isFlush      = ($urandom % 512) == 0;
    v13_io_in_bits_fuType = 35'({$urandom, $urandom});
    v13_io_in_bits_fuOpType = 9'($urandom);
    v13_io_in_bits_src_0 = 128'({$urandom, $urandom, $urandom, $urandom});
    v13_io_in_bits_src_1 = 128'({$urandom, $urandom, $urandom, $urandom});
    v13_io_in_bits_src_2 = 128'({$urandom, $urandom, $urandom, $urandom});
    v13_io_in_bits_src_3 = 128'({$urandom, $urandom, $urandom, $urandom});
    v13_io_in_bits_src_4 = 128'({$urandom, $urandom, $urandom, $urandom});
    v13_io_in_bits_robIdx_flag = 1'($urandom);
    v13_io_in_bits_robIdx_value = 8'($urandom);
    v13_io_in_bits_pdest = 7'($urandom);
    v13_io_in_bits_vecWen = 1'($urandom);
    v13_io_in_bits_v0Wen = 1'($urandom);
    v13_io_in_bits_fpu_wflags = 1'($urandom);
    v13_io_in_bits_vpu_vma = 1'($urandom);
    v13_io_in_bits_vpu_vta = 1'($urandom);
    v13_io_in_bits_vpu_vsew = 2'($urandom);
    v13_io_in_bits_vpu_vlmul = 3'($urandom);
    v13_io_in_bits_vpu_vm = 1'($urandom);
    v13_io_in_bits_vpu_vstart = 8'($urandom);
    v13_io_in_bits_vpu_vuopIdx = 7'($urandom);
    v13_io_in_bits_vpu_isExt = 1'($urandom);
    v13_io_in_bits_vpu_isNarrow = 1'($urandom);
    v13_io_in_bits_vpu_isDstMask = 1'($urandom);
    v13_io_in_bits_vpu_isOpMask = 1'($urandom);
    v13_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v13_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v13_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v13_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v13_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v13_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v13_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v13_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v13_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v13_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v13_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v13_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v14_io_in_valid     = ($urandom % 100) < 75;
    v14_io_out_ready    = ($urandom % 100) < 55;
    v14_io_rightOutFire = ($urandom % 100) < 50;
    v14_io_isFlush      = ($urandom % 512) == 0;
    v14_io_in_bits_fuType = 35'({$urandom, $urandom});
    v14_io_in_bits_fuOpType = 9'($urandom);
    v14_io_in_bits_src_0 = 128'({$urandom, $urandom, $urandom, $urandom});
    v14_io_in_bits_src_1 = 128'({$urandom, $urandom, $urandom, $urandom});
    v14_io_in_bits_src_2 = 128'({$urandom, $urandom, $urandom, $urandom});
    v14_io_in_bits_src_3 = 128'({$urandom, $urandom, $urandom, $urandom});
    v14_io_in_bits_src_4 = 128'({$urandom, $urandom, $urandom, $urandom});
    v14_io_in_bits_robIdx_flag = 1'($urandom);
    v14_io_in_bits_robIdx_value = 8'($urandom);
    v14_io_in_bits_pdest = 8'($urandom);
    v14_io_in_bits_rfWen = 1'($urandom);
    v14_io_in_bits_fpWen = 1'($urandom);
    v14_io_in_bits_vecWen = 1'($urandom);
    v14_io_in_bits_v0Wen = 1'($urandom);
    v14_io_in_bits_vlWen = 1'($urandom);
    v14_io_in_bits_fpu_wflags = 1'($urandom);
    v14_io_in_bits_vpu_vma = 1'($urandom);
    v14_io_in_bits_vpu_vta = 1'($urandom);
    v14_io_in_bits_vpu_vsew = 2'($urandom);
    v14_io_in_bits_vpu_vlmul = 3'($urandom);
    v14_io_in_bits_vpu_vm = 1'($urandom);
    v14_io_in_bits_vpu_vstart = 8'($urandom);
    v14_io_in_bits_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    v14_io_in_bits_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    v14_io_in_bits_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    v14_io_in_bits_vpu_vuopIdx = 7'($urandom);
    v14_io_in_bits_vpu_lastUop = 1'($urandom);
    v14_io_in_bits_vpu_isNarrow = 1'($urandom);
    v14_io_in_bits_vpu_isDstMask = 1'($urandom);
    v14_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v14_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v14_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v14_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v14_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v14_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v14_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v14_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v14_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v14_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v14_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v14_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v16_io_in_valid     = ($urandom % 100) < 75;
    v16_io_out_ready    = ($urandom % 100) < 55;
    v16_io_rightOutFire = ($urandom % 100) < 50;
    v16_io_isFlush      = ($urandom % 512) == 0;
    v16_io_in_bits_fuType = 35'({$urandom, $urandom});
    v16_io_in_bits_fuOpType = 9'($urandom);
    v16_io_in_bits_src_0 = 128'({$urandom, $urandom, $urandom, $urandom});
    v16_io_in_bits_src_1 = 128'({$urandom, $urandom, $urandom, $urandom});
    v16_io_in_bits_src_2 = 128'({$urandom, $urandom, $urandom, $urandom});
    v16_io_in_bits_src_3 = 128'({$urandom, $urandom, $urandom, $urandom});
    v16_io_in_bits_src_4 = 128'({$urandom, $urandom, $urandom, $urandom});
    v16_io_in_bits_robIdx_flag = 1'($urandom);
    v16_io_in_bits_robIdx_value = 8'($urandom);
    v16_io_in_bits_pdest = 8'($urandom);
    v16_io_in_bits_fpWen = 1'($urandom);
    v16_io_in_bits_vecWen = 1'($urandom);
    v16_io_in_bits_v0Wen = 1'($urandom);
    v16_io_in_bits_fpu_wflags = 1'($urandom);
    v16_io_in_bits_vpu_vma = 1'($urandom);
    v16_io_in_bits_vpu_vta = 1'($urandom);
    v16_io_in_bits_vpu_vsew = 2'($urandom);
    v16_io_in_bits_vpu_vlmul = 3'($urandom);
    v16_io_in_bits_vpu_vm = 1'($urandom);
    v16_io_in_bits_vpu_vstart = 8'($urandom);
    v16_io_in_bits_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    v16_io_in_bits_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    v16_io_in_bits_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    v16_io_in_bits_vpu_vuopIdx = 7'($urandom);
    v16_io_in_bits_vpu_lastUop = 1'($urandom);
    v16_io_in_bits_vpu_isNarrow = 1'($urandom);
    v16_io_in_bits_vpu_isDstMask = 1'($urandom);
    v16_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v16_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v16_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v16_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v16_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v16_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v16_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v16_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v16_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v16_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v16_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v16_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v18_io_in_valid     = ($urandom % 100) < 75;
    v18_io_out_ready    = ($urandom % 100) < 55;
    v18_io_rightOutFire = ($urandom % 100) < 50;
    v18_io_isFlush      = ($urandom % 512) == 0;
    v18_io_in_bits_fuType = 35'({$urandom, $urandom});
    v18_io_in_bits_fuOpType = 9'($urandom);
    v18_io_in_bits_src_0 = 64'({$urandom, $urandom});
    v18_io_in_bits_imm = 64'({$urandom, $urandom});
    v18_io_in_bits_robIdx_flag = 1'($urandom);
    v18_io_in_bits_robIdx_value = 8'($urandom);
    v18_io_in_bits_isFirstIssue = 1'($urandom);
    v18_io_in_bits_pdest = 8'($urandom);
    v18_io_in_bits_rfWen = 1'($urandom);
    v18_io_in_bits_ftqIdx_flag = 1'($urandom);
    v18_io_in_bits_ftqIdx_value = 6'($urandom);
    v18_io_in_bits_ftqOffset = 4'($urandom);
    v18_io_in_bits_sqIdx_flag = 1'($urandom);
    v18_io_in_bits_sqIdx_value = 6'($urandom);
    v18_io_in_bits_lqIdx_flag = 1'($urandom);
    v18_io_in_bits_lqIdx_value = 7'($urandom);
    v18_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v18_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v18_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v18_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v18_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v18_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v18_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v18_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v18_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v18_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v18_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v18_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v20_io_in_valid     = ($urandom % 100) < 75;
    v20_io_out_ready    = ($urandom % 100) < 55;
    v20_io_rightOutFire = ($urandom % 100) < 50;
    v20_io_isFlush      = ($urandom % 512) == 0;
    v20_io_in_bits_fuType = 35'({$urandom, $urandom});
    v20_io_in_bits_fuOpType = 9'($urandom);
    v20_io_in_bits_src_0 = 64'({$urandom, $urandom});
    v20_io_in_bits_imm = 64'({$urandom, $urandom});
    v20_io_in_bits_robIdx_flag = 1'($urandom);
    v20_io_in_bits_robIdx_value = 8'($urandom);
    v20_io_in_bits_pdest = 8'($urandom);
    v20_io_in_bits_rfWen = 1'($urandom);
    v20_io_in_bits_fpWen = 1'($urandom);
    v20_io_in_bits_pc = 50'({$urandom, $urandom});
    v20_io_in_bits_preDecode_valid = 1'($urandom);
    v20_io_in_bits_preDecode_isRVC = 1'($urandom);
    v20_io_in_bits_preDecode_brType = 2'($urandom);
    v20_io_in_bits_preDecode_isCall = 1'($urandom);
    v20_io_in_bits_preDecode_isRet = 1'($urandom);
    v20_io_in_bits_ftqIdx_flag = 1'($urandom);
    v20_io_in_bits_ftqIdx_value = 6'($urandom);
    v20_io_in_bits_ftqOffset = 4'($urandom);
    v20_io_in_bits_loadWaitBit = 1'($urandom);
    v20_io_in_bits_waitForRobIdx_flag = 1'($urandom);
    v20_io_in_bits_waitForRobIdx_value = 8'($urandom);
    v20_io_in_bits_storeSetHit = 1'($urandom);
    v20_io_in_bits_loadWaitStrict = 1'($urandom);
    v20_io_in_bits_ssid = 5'($urandom);
    v20_io_in_bits_sqIdx_flag = 1'($urandom);
    v20_io_in_bits_sqIdx_value = 6'($urandom);
    v20_io_in_bits_lqIdx_flag = 1'($urandom);
    v20_io_in_bits_lqIdx_value = 7'($urandom);
    v20_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v20_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v20_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v20_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v20_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v20_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v20_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v20_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v20_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v20_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v20_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v20_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v23_io_in_valid     = ($urandom % 100) < 75;
    v23_io_out_ready    = ($urandom % 100) < 55;
    v23_io_rightOutFire = ($urandom % 100) < 50;
    v23_io_isFlush      = ($urandom % 512) == 0;
    v23_io_isOlder      = ($urandom % 100) < 20;
    v23_io_in_bits_fuType = 35'({$urandom, $urandom});
    v23_io_in_bits_fuOpType = 9'($urandom);
    v23_io_in_bits_src_0 = 128'({$urandom, $urandom, $urandom, $urandom});
    v23_io_in_bits_src_1 = 128'({$urandom, $urandom, $urandom, $urandom});
    v23_io_in_bits_src_2 = 128'({$urandom, $urandom, $urandom, $urandom});
    v23_io_in_bits_src_3 = 128'({$urandom, $urandom, $urandom, $urandom});
    v23_io_in_bits_src_4 = 128'({$urandom, $urandom, $urandom, $urandom});
    v23_io_in_bits_robIdx_flag = 1'($urandom);
    v23_io_in_bits_robIdx_value = 8'($urandom);
    v23_io_in_bits_pdest = 7'($urandom);
    v23_io_in_bits_vecWen = 1'($urandom);
    v23_io_in_bits_v0Wen = 1'($urandom);
    v23_io_in_bits_vlWen = 1'($urandom);
    v23_io_in_bits_vpu_vill = 1'($urandom);
    v23_io_in_bits_vpu_vma = 1'($urandom);
    v23_io_in_bits_vpu_vta = 1'($urandom);
    v23_io_in_bits_vpu_vsew = 2'($urandom);
    v23_io_in_bits_vpu_vlmul = 3'($urandom);
    v23_io_in_bits_vpu_specVill = 1'($urandom);
    v23_io_in_bits_vpu_specVma = 1'($urandom);
    v23_io_in_bits_vpu_specVta = 1'($urandom);
    v23_io_in_bits_vpu_specVsew = 2'($urandom);
    v23_io_in_bits_vpu_specVlmul = 3'($urandom);
    v23_io_in_bits_vpu_vm = 1'($urandom);
    v23_io_in_bits_vpu_vstart = 8'($urandom);
    v23_io_in_bits_vpu_frm = 3'($urandom);
    v23_io_in_bits_vpu_fpu_isFpToVecInst = 1'($urandom);
    v23_io_in_bits_vpu_fpu_isFP32Instr = 1'($urandom);
    v23_io_in_bits_vpu_fpu_isFP64Instr = 1'($urandom);
    v23_io_in_bits_vpu_fpu_isReduction = 1'($urandom);
    v23_io_in_bits_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    v23_io_in_bits_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    v23_io_in_bits_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    v23_io_in_bits_vpu_vxrm = 2'($urandom);
    v23_io_in_bits_vpu_vuopIdx = 7'($urandom);
    v23_io_in_bits_vpu_lastUop = 1'($urandom);
    v23_io_in_bits_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
    v23_io_in_bits_vpu_nf = 3'($urandom);
    v23_io_in_bits_vpu_veew = 2'($urandom);
    v23_io_in_bits_vpu_isReverse = 1'($urandom);
    v23_io_in_bits_vpu_isExt = 1'($urandom);
    v23_io_in_bits_vpu_isNarrow = 1'($urandom);
    v23_io_in_bits_vpu_isDstMask = 1'($urandom);
    v23_io_in_bits_vpu_isOpMask = 1'($urandom);
    v23_io_in_bits_vpu_isMove = 1'($urandom);
    v23_io_in_bits_vpu_isDependOldVd = 1'($urandom);
    v23_io_in_bits_vpu_isWritePartVd = 1'($urandom);
    v23_io_in_bits_vpu_isVleff = 1'($urandom);
    v23_io_in_bits_ftqIdx_flag = 1'($urandom);
    v23_io_in_bits_ftqIdx_value = 6'($urandom);
    v23_io_in_bits_ftqOffset = 4'($urandom);
    v23_io_in_bits_numLsElem = 5'($urandom);
    v23_io_in_bits_sqIdx_flag = 1'($urandom);
    v23_io_in_bits_sqIdx_value = 6'($urandom);
    v23_io_in_bits_lqIdx_flag = 1'($urandom);
    v23_io_in_bits_lqIdx_value = 7'($urandom);
    v23_io_in_bits_isVecPartReplay = 1'($urandom);
    v23_io_in_bits_vecReplayMask = 16'($urandom);
    v23_io_in_bits_vecReplayMbIdx = 4'($urandom);
    v23_io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    v23_io_in_bits_perfDebugInfo_renameTime = 64'({$urandom, $urandom});
    v23_io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom, $urandom});
    v23_io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom, $urandom});
    v23_io_in_bits_perfDebugInfo_selectTime = 64'({$urandom, $urandom});
    v23_io_in_bits_perfDebugInfo_issueTime = 64'({$urandom, $urandom});
    v23_io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom, $urandom});
    v23_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v23_io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v23_io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v23_io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v23_io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    v25_io_in_valid     = ($urandom % 100) < 75;
    v25_io_out_ready    = ($urandom % 100) < 55;
    v25_io_rightOutFire = ($urandom % 100) < 50;
    v25_io_isFlush      = ($urandom % 512) == 0;
    v25_io_in_bits_fuType = 35'({$urandom, $urandom});
    v25_io_in_bits_fuOpType = 9'($urandom);
    v25_io_in_bits_src_0 = 64'({$urandom, $urandom});
    v25_io_in_bits_robIdx_flag = 1'($urandom);
    v25_io_in_bits_robIdx_value = 8'($urandom);
    v25_io_in_bits_sqIdx_flag = 1'($urandom);
    v25_io_in_bits_sqIdx_value = 6'($urandom);
  endtask

  task automatic check_all();
    `CHECK(v0,io_in_ready)
    `CHECK(v0,io_out_valid)
    `CHECK(v0,io_out_bits_fuType)
    `CHECK(v0,io_out_bits_fuOpType)
    `CHECK(v0,io_out_bits_src_0)
    `CHECK(v0,io_out_bits_src_1)
    `CHECK(v0,io_out_bits_robIdx_flag)
    `CHECK(v0,io_out_bits_robIdx_value)
    `CHECK(v0,io_out_bits_pdest)
    `CHECK(v0,io_out_bits_rfWen)
    `CHECK(v0,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v0,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v0,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v0,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v0,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v0,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v0,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v0,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v0,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v0,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v0,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v0,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v1,io_in_ready)
    `CHECK(v1,io_out_valid)
    `CHECK(v1,io_out_bits_fuType)
    `CHECK(v1,io_out_bits_fuOpType)
    `CHECK(v1,io_out_bits_src_0)
    `CHECK(v1,io_out_bits_src_1)
    `CHECK(v1,io_out_bits_imm)
    `CHECK(v1,io_out_bits_nextPcOffset)
    `CHECK(v1,io_out_bits_robIdx_flag)
    `CHECK(v1,io_out_bits_robIdx_value)
    `CHECK(v1,io_out_bits_pdest)
    `CHECK(v1,io_out_bits_rfWen)
    `CHECK(v1,io_out_bits_pc)
    `CHECK(v1,io_out_bits_preDecode_valid)
    `CHECK(v1,io_out_bits_preDecode_isRVC)
    `CHECK(v1,io_out_bits_preDecode_brType)
    `CHECK(v1,io_out_bits_preDecode_isCall)
    `CHECK(v1,io_out_bits_preDecode_isRet)
    `CHECK(v1,io_out_bits_ftqIdx_flag)
    `CHECK(v1,io_out_bits_ftqIdx_value)
    `CHECK(v1,io_out_bits_ftqOffset)
    `CHECK(v1,io_out_bits_predictInfo_target)
    `CHECK(v1,io_out_bits_predictInfo_taken)
    `CHECK(v1,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v1,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v1,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v1,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v1,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v1,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v1,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v1,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v1,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v1,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v1,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v1,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v5,io_in_ready)
    `CHECK(v5,io_out_valid)
    `CHECK(v5,io_out_bits_fuType)
    `CHECK(v5,io_out_bits_fuOpType)
    `CHECK(v5,io_out_bits_src_0)
    `CHECK(v5,io_out_bits_src_1)
    `CHECK(v5,io_out_bits_imm)
    `CHECK(v5,io_out_bits_nextPcOffset)
    `CHECK(v5,io_out_bits_robIdx_flag)
    `CHECK(v5,io_out_bits_robIdx_value)
    `CHECK(v5,io_out_bits_pdest)
    `CHECK(v5,io_out_bits_rfWen)
    `CHECK(v5,io_out_bits_fpWen)
    `CHECK(v5,io_out_bits_vecWen)
    `CHECK(v5,io_out_bits_v0Wen)
    `CHECK(v5,io_out_bits_vlWen)
    `CHECK(v5,io_out_bits_fpu_typeTagOut)
    `CHECK(v5,io_out_bits_fpu_wflags)
    `CHECK(v5,io_out_bits_fpu_typ)
    `CHECK(v5,io_out_bits_fpu_rm)
    `CHECK(v5,io_out_bits_pc)
    `CHECK(v5,io_out_bits_preDecode_valid)
    `CHECK(v5,io_out_bits_preDecode_isRVC)
    `CHECK(v5,io_out_bits_preDecode_brType)
    `CHECK(v5,io_out_bits_preDecode_isCall)
    `CHECK(v5,io_out_bits_preDecode_isRet)
    `CHECK(v5,io_out_bits_ftqIdx_flag)
    `CHECK(v5,io_out_bits_ftqIdx_value)
    `CHECK(v5,io_out_bits_ftqOffset)
    `CHECK(v5,io_out_bits_predictInfo_target)
    `CHECK(v5,io_out_bits_predictInfo_taken)
    `CHECK(v5,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v5,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v5,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v5,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v5,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v5,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v5,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v5,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v5,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v5,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v5,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v5,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v7,io_in_ready)
    `CHECK(v7,io_out_valid)
    `CHECK(v7,io_out_bits_fuType)
    `CHECK(v7,io_out_bits_fuOpType)
    `CHECK(v7,io_out_bits_src_0)
    `CHECK(v7,io_out_bits_src_1)
    `CHECK(v7,io_out_bits_imm)
    `CHECK(v7,io_out_bits_robIdx_flag)
    `CHECK(v7,io_out_bits_robIdx_value)
    `CHECK(v7,io_out_bits_pdest)
    `CHECK(v7,io_out_bits_rfWen)
    `CHECK(v7,io_out_bits_flushPipe)
    `CHECK(v7,io_out_bits_preDecode_valid)
    `CHECK(v7,io_out_bits_preDecode_isRVC)
    `CHECK(v7,io_out_bits_preDecode_brType)
    `CHECK(v7,io_out_bits_preDecode_isCall)
    `CHECK(v7,io_out_bits_preDecode_isRet)
    `CHECK(v7,io_out_bits_ftqIdx_flag)
    `CHECK(v7,io_out_bits_ftqIdx_value)
    `CHECK(v7,io_out_bits_ftqOffset)
    `CHECK(v7,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v7,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v7,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v7,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v7,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v7,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v7,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v7,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v7,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v7,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v7,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v7,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v8,io_in_ready)
    `CHECK(v8,io_out_valid)
    `CHECK(v8,io_out_bits_fuType)
    `CHECK(v8,io_out_bits_fuOpType)
    `CHECK(v8,io_out_bits_src_0)
    `CHECK(v8,io_out_bits_src_1)
    `CHECK(v8,io_out_bits_src_2)
    `CHECK(v8,io_out_bits_robIdx_flag)
    `CHECK(v8,io_out_bits_robIdx_value)
    `CHECK(v8,io_out_bits_pdest)
    `CHECK(v8,io_out_bits_rfWen)
    `CHECK(v8,io_out_bits_fpWen)
    `CHECK(v8,io_out_bits_vecWen)
    `CHECK(v8,io_out_bits_v0Wen)
    `CHECK(v8,io_out_bits_fpu_wflags)
    `CHECK(v8,io_out_bits_fpu_fmt)
    `CHECK(v8,io_out_bits_fpu_rm)
    `CHECK(v8,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v8,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v8,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v8,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v8,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v8,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v8,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v8,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v8,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v8,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v8,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v8,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v9,io_in_ready)
    `CHECK(v9,io_out_valid)
    `CHECK(v9,io_out_bits_fuType)
    `CHECK(v9,io_out_bits_fuOpType)
    `CHECK(v9,io_out_bits_src_0)
    `CHECK(v9,io_out_bits_src_1)
    `CHECK(v9,io_out_bits_robIdx_flag)
    `CHECK(v9,io_out_bits_robIdx_value)
    `CHECK(v9,io_out_bits_pdest)
    `CHECK(v9,io_out_bits_fpWen)
    `CHECK(v9,io_out_bits_fpu_wflags)
    `CHECK(v9,io_out_bits_fpu_fmt)
    `CHECK(v9,io_out_bits_fpu_rm)
    `CHECK(v9,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v9,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v9,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v9,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v9,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v9,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v9,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v9,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v9,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v9,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v9,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v9,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v10,io_in_ready)
    `CHECK(v10,io_out_valid)
    `CHECK(v10,io_out_bits_fuType)
    `CHECK(v10,io_out_bits_fuOpType)
    `CHECK(v10,io_out_bits_src_0)
    `CHECK(v10,io_out_bits_src_1)
    `CHECK(v10,io_out_bits_src_2)
    `CHECK(v10,io_out_bits_robIdx_flag)
    `CHECK(v10,io_out_bits_robIdx_value)
    `CHECK(v10,io_out_bits_pdest)
    `CHECK(v10,io_out_bits_rfWen)
    `CHECK(v10,io_out_bits_fpWen)
    `CHECK(v10,io_out_bits_fpu_wflags)
    `CHECK(v10,io_out_bits_fpu_fmt)
    `CHECK(v10,io_out_bits_fpu_rm)
    `CHECK(v10,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v10,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v10,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v10,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v10,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v10,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v10,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v10,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v10,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v10,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v10,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v10,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v13,io_in_ready)
    `CHECK(v13,io_out_valid)
    `CHECK(v13,io_out_bits_fuType)
    `CHECK(v13,io_out_bits_fuOpType)
    `CHECK(v13,io_out_bits_src_0)
    `CHECK(v13,io_out_bits_src_1)
    `CHECK(v13,io_out_bits_src_2)
    `CHECK(v13,io_out_bits_src_3)
    `CHECK(v13,io_out_bits_src_4)
    `CHECK(v13,io_out_bits_robIdx_flag)
    `CHECK(v13,io_out_bits_robIdx_value)
    `CHECK(v13,io_out_bits_pdest)
    `CHECK(v13,io_out_bits_vecWen)
    `CHECK(v13,io_out_bits_v0Wen)
    `CHECK(v13,io_out_bits_fpu_wflags)
    `CHECK(v13,io_out_bits_vpu_vma)
    `CHECK(v13,io_out_bits_vpu_vta)
    `CHECK(v13,io_out_bits_vpu_vsew)
    `CHECK(v13,io_out_bits_vpu_vlmul)
    `CHECK(v13,io_out_bits_vpu_vm)
    `CHECK(v13,io_out_bits_vpu_vstart)
    `CHECK(v13,io_out_bits_vpu_vuopIdx)
    `CHECK(v13,io_out_bits_vpu_isExt)
    `CHECK(v13,io_out_bits_vpu_isNarrow)
    `CHECK(v13,io_out_bits_vpu_isDstMask)
    `CHECK(v13,io_out_bits_vpu_isOpMask)
    `CHECK(v13,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v13,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v13,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v13,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v13,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v13,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v13,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v13,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v13,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v13,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v13,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v13,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v14,io_in_ready)
    `CHECK(v14,io_out_valid)
    `CHECK(v14,io_out_bits_fuType)
    `CHECK(v14,io_out_bits_fuOpType)
    `CHECK(v14,io_out_bits_src_0)
    `CHECK(v14,io_out_bits_src_1)
    `CHECK(v14,io_out_bits_src_2)
    `CHECK(v14,io_out_bits_src_3)
    `CHECK(v14,io_out_bits_src_4)
    `CHECK(v14,io_out_bits_robIdx_flag)
    `CHECK(v14,io_out_bits_robIdx_value)
    `CHECK(v14,io_out_bits_pdest)
    `CHECK(v14,io_out_bits_rfWen)
    `CHECK(v14,io_out_bits_fpWen)
    `CHECK(v14,io_out_bits_vecWen)
    `CHECK(v14,io_out_bits_v0Wen)
    `CHECK(v14,io_out_bits_vlWen)
    `CHECK(v14,io_out_bits_fpu_wflags)
    `CHECK(v14,io_out_bits_vpu_vma)
    `CHECK(v14,io_out_bits_vpu_vta)
    `CHECK(v14,io_out_bits_vpu_vsew)
    `CHECK(v14,io_out_bits_vpu_vlmul)
    `CHECK(v14,io_out_bits_vpu_vm)
    `CHECK(v14,io_out_bits_vpu_vstart)
    `CHECK(v14,io_out_bits_vpu_fpu_isFoldTo1_2)
    `CHECK(v14,io_out_bits_vpu_fpu_isFoldTo1_4)
    `CHECK(v14,io_out_bits_vpu_fpu_isFoldTo1_8)
    `CHECK(v14,io_out_bits_vpu_vuopIdx)
    `CHECK(v14,io_out_bits_vpu_lastUop)
    `CHECK(v14,io_out_bits_vpu_isNarrow)
    `CHECK(v14,io_out_bits_vpu_isDstMask)
    `CHECK(v14,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v14,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v14,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v14,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v14,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v14,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v14,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v14,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v14,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v14,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v14,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v14,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v16,io_in_ready)
    `CHECK(v16,io_out_valid)
    `CHECK(v16,io_out_bits_fuType)
    `CHECK(v16,io_out_bits_fuOpType)
    `CHECK(v16,io_out_bits_src_0)
    `CHECK(v16,io_out_bits_src_1)
    `CHECK(v16,io_out_bits_src_2)
    `CHECK(v16,io_out_bits_src_3)
    `CHECK(v16,io_out_bits_src_4)
    `CHECK(v16,io_out_bits_robIdx_flag)
    `CHECK(v16,io_out_bits_robIdx_value)
    `CHECK(v16,io_out_bits_pdest)
    `CHECK(v16,io_out_bits_fpWen)
    `CHECK(v16,io_out_bits_vecWen)
    `CHECK(v16,io_out_bits_v0Wen)
    `CHECK(v16,io_out_bits_fpu_wflags)
    `CHECK(v16,io_out_bits_vpu_vma)
    `CHECK(v16,io_out_bits_vpu_vta)
    `CHECK(v16,io_out_bits_vpu_vsew)
    `CHECK(v16,io_out_bits_vpu_vlmul)
    `CHECK(v16,io_out_bits_vpu_vm)
    `CHECK(v16,io_out_bits_vpu_vstart)
    `CHECK(v16,io_out_bits_vpu_fpu_isFoldTo1_2)
    `CHECK(v16,io_out_bits_vpu_fpu_isFoldTo1_4)
    `CHECK(v16,io_out_bits_vpu_fpu_isFoldTo1_8)
    `CHECK(v16,io_out_bits_vpu_vuopIdx)
    `CHECK(v16,io_out_bits_vpu_lastUop)
    `CHECK(v16,io_out_bits_vpu_isNarrow)
    `CHECK(v16,io_out_bits_vpu_isDstMask)
    `CHECK(v16,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v16,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v16,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v16,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v16,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v16,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v16,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v16,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v16,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v16,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v16,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v16,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v18,io_in_ready)
    `CHECK(v18,io_out_valid)
    `CHECK(v18,io_out_bits_fuType)
    `CHECK(v18,io_out_bits_fuOpType)
    `CHECK(v18,io_out_bits_src_0)
    `CHECK(v18,io_out_bits_imm)
    `CHECK(v18,io_out_bits_robIdx_flag)
    `CHECK(v18,io_out_bits_robIdx_value)
    `CHECK(v18,io_out_bits_isFirstIssue)
    `CHECK(v18,io_out_bits_pdest)
    `CHECK(v18,io_out_bits_rfWen)
    `CHECK(v18,io_out_bits_ftqIdx_flag)
    `CHECK(v18,io_out_bits_ftqIdx_value)
    `CHECK(v18,io_out_bits_ftqOffset)
    `CHECK(v18,io_out_bits_sqIdx_flag)
    `CHECK(v18,io_out_bits_sqIdx_value)
    `CHECK(v18,io_out_bits_lqIdx_flag)
    `CHECK(v18,io_out_bits_lqIdx_value)
    `CHECK(v18,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v18,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v18,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v18,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v18,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v18,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v18,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v18,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v18,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v18,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v18,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v18,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v20,io_in_ready)
    `CHECK(v20,io_out_valid)
    `CHECK(v20,io_out_bits_fuType)
    `CHECK(v20,io_out_bits_fuOpType)
    `CHECK(v20,io_out_bits_src_0)
    `CHECK(v20,io_out_bits_imm)
    `CHECK(v20,io_out_bits_robIdx_flag)
    `CHECK(v20,io_out_bits_robIdx_value)
    `CHECK(v20,io_out_bits_pdest)
    `CHECK(v20,io_out_bits_rfWen)
    `CHECK(v20,io_out_bits_fpWen)
    `CHECK(v20,io_out_bits_pc)
    `CHECK(v20,io_out_bits_preDecode_valid)
    `CHECK(v20,io_out_bits_preDecode_isRVC)
    `CHECK(v20,io_out_bits_preDecode_brType)
    `CHECK(v20,io_out_bits_preDecode_isCall)
    `CHECK(v20,io_out_bits_preDecode_isRet)
    `CHECK(v20,io_out_bits_ftqIdx_flag)
    `CHECK(v20,io_out_bits_ftqIdx_value)
    `CHECK(v20,io_out_bits_ftqOffset)
    `CHECK(v20,io_out_bits_loadWaitBit)
    `CHECK(v20,io_out_bits_waitForRobIdx_flag)
    `CHECK(v20,io_out_bits_waitForRobIdx_value)
    `CHECK(v20,io_out_bits_storeSetHit)
    `CHECK(v20,io_out_bits_loadWaitStrict)
    `CHECK(v20,io_out_bits_ssid)
    `CHECK(v20,io_out_bits_sqIdx_flag)
    `CHECK(v20,io_out_bits_sqIdx_value)
    `CHECK(v20,io_out_bits_lqIdx_flag)
    `CHECK(v20,io_out_bits_lqIdx_value)
    `CHECK(v20,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v20,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v20,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v20,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v20,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v20,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v20,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v20,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v20,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v20,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v20,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v20,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v23,io_in_ready)
    `CHECK(v23,io_out_valid)
    `CHECK(v23,io_out_bits_fuType)
    `CHECK(v23,io_out_bits_fuOpType)
    `CHECK(v23,io_out_bits_src_0)
    `CHECK(v23,io_out_bits_src_1)
    `CHECK(v23,io_out_bits_src_2)
    `CHECK(v23,io_out_bits_src_3)
    `CHECK(v23,io_out_bits_src_4)
    `CHECK(v23,io_out_bits_robIdx_flag)
    `CHECK(v23,io_out_bits_robIdx_value)
    `CHECK(v23,io_out_bits_pdest)
    `CHECK(v23,io_out_bits_vecWen)
    `CHECK(v23,io_out_bits_v0Wen)
    `CHECK(v23,io_out_bits_vlWen)
    `CHECK(v23,io_out_bits_vpu_vill)
    `CHECK(v23,io_out_bits_vpu_vma)
    `CHECK(v23,io_out_bits_vpu_vta)
    `CHECK(v23,io_out_bits_vpu_vsew)
    `CHECK(v23,io_out_bits_vpu_vlmul)
    `CHECK(v23,io_out_bits_vpu_specVill)
    `CHECK(v23,io_out_bits_vpu_specVma)
    `CHECK(v23,io_out_bits_vpu_specVta)
    `CHECK(v23,io_out_bits_vpu_specVsew)
    `CHECK(v23,io_out_bits_vpu_specVlmul)
    `CHECK(v23,io_out_bits_vpu_vm)
    `CHECK(v23,io_out_bits_vpu_vstart)
    `CHECK(v23,io_out_bits_vpu_frm)
    `CHECK(v23,io_out_bits_vpu_fpu_isFpToVecInst)
    `CHECK(v23,io_out_bits_vpu_fpu_isFP32Instr)
    `CHECK(v23,io_out_bits_vpu_fpu_isFP64Instr)
    `CHECK(v23,io_out_bits_vpu_fpu_isReduction)
    `CHECK(v23,io_out_bits_vpu_fpu_isFoldTo1_2)
    `CHECK(v23,io_out_bits_vpu_fpu_isFoldTo1_4)
    `CHECK(v23,io_out_bits_vpu_fpu_isFoldTo1_8)
    `CHECK(v23,io_out_bits_vpu_vxrm)
    `CHECK(v23,io_out_bits_vpu_vuopIdx)
    `CHECK(v23,io_out_bits_vpu_lastUop)
    `CHECK(v23,io_out_bits_vpu_vmask)
    `CHECK(v23,io_out_bits_vpu_nf)
    `CHECK(v23,io_out_bits_vpu_veew)
    `CHECK(v23,io_out_bits_vpu_isReverse)
    `CHECK(v23,io_out_bits_vpu_isExt)
    `CHECK(v23,io_out_bits_vpu_isNarrow)
    `CHECK(v23,io_out_bits_vpu_isDstMask)
    `CHECK(v23,io_out_bits_vpu_isOpMask)
    `CHECK(v23,io_out_bits_vpu_isMove)
    `CHECK(v23,io_out_bits_vpu_isDependOldVd)
    `CHECK(v23,io_out_bits_vpu_isWritePartVd)
    `CHECK(v23,io_out_bits_vpu_isVleff)
    `CHECK(v23,io_out_bits_ftqIdx_flag)
    `CHECK(v23,io_out_bits_ftqIdx_value)
    `CHECK(v23,io_out_bits_ftqOffset)
    `CHECK(v23,io_out_bits_numLsElem)
    `CHECK(v23,io_out_bits_sqIdx_flag)
    `CHECK(v23,io_out_bits_sqIdx_value)
    `CHECK(v23,io_out_bits_lqIdx_flag)
    `CHECK(v23,io_out_bits_lqIdx_value)
    `CHECK(v23,io_out_bits_isVecPartReplay)
    `CHECK(v23,io_out_bits_vecReplayMask)
    `CHECK(v23,io_out_bits_vecReplayMbIdx)
    `CHECK(v23,io_out_bits_perfDebugInfo_eliminatedMove)
    `CHECK(v23,io_out_bits_perfDebugInfo_renameTime)
    `CHECK(v23,io_out_bits_perfDebugInfo_dispatchTime)
    `CHECK(v23,io_out_bits_perfDebugInfo_enqRsTime)
    `CHECK(v23,io_out_bits_perfDebugInfo_selectTime)
    `CHECK(v23,io_out_bits_perfDebugInfo_issueTime)
    `CHECK(v23,io_out_bits_perfDebugInfo_writebackTime)
    `CHECK(v23,io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHECK(v23,io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHECK(v23,io_out_bits_perfDebugInfo_tlbRespTime)
    `CHECK(v23,io_out_bits_debug_seqNum_seqNum)
    `CHECK(v23,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(v25,io_in_ready)
    `CHECK(v25,io_out_valid)
    `CHECK(v25,io_out_bits_fuType)
    `CHECK(v25,io_out_bits_fuOpType)
    `CHECK(v25,io_out_bits_src_0)
    `CHECK(v25,io_out_bits_robIdx_flag)
    `CHECK(v25,io_out_bits_robIdx_value)
    `CHECK(v25,io_out_bits_sqIdx_flag)
    `CHECK(v25,io_out_bits_sqIdx_value)
  endtask

  // 覆盖采样：ready/valid 一律取 golden 侧（金标准），避免用被测侧自证。
  // 调用时机 = 输入已驱动、posedge 尚未到达，故 g_*_io_in_ready / g_*_io_out_valid
  // 反映的是**这一拍沿前**的状态，与 fire/反压/flush/hold 的定义对齐。
  task automatic sample_cov();
    if (v0_io_in_valid && g_v0_io_in_ready === 1'b1) begin
      fire_v0++; por_v0 |= pcat_v0; pand_v0 &= pcat_v0;
    end
    if (v0_io_in_valid && g_v0_io_in_ready === 1'b0) bp_v0++;
    if (g_v0_io_out_valid === 1'b1) begin
      ov_v0++;
      if (v0_io_isFlush) flush_v0++;
      if (!v0_io_rightOutFire) hold_v0++;
    end
    if (v1_io_in_valid && g_v1_io_in_ready === 1'b1) begin
      fire_v1++; por_v1 |= pcat_v1; pand_v1 &= pcat_v1;
    end
    if (v1_io_in_valid && g_v1_io_in_ready === 1'b0) bp_v1++;
    if (g_v1_io_out_valid === 1'b1) begin
      ov_v1++;
      if (v1_io_isFlush) flush_v1++;
      if (!v1_io_rightOutFire) hold_v1++;
    end
    if (v5_io_in_valid && g_v5_io_in_ready === 1'b1) begin
      fire_v5++; por_v5 |= pcat_v5; pand_v5 &= pcat_v5;
    end
    if (v5_io_in_valid && g_v5_io_in_ready === 1'b0) bp_v5++;
    if (g_v5_io_out_valid === 1'b1) begin
      ov_v5++;
      if (v5_io_isFlush) flush_v5++;
      if (!v5_io_rightOutFire) hold_v5++;
    end
    if (v7_io_in_valid && g_v7_io_in_ready === 1'b1) begin
      fire_v7++; por_v7 |= pcat_v7; pand_v7 &= pcat_v7;
    end
    if (v7_io_in_valid && g_v7_io_in_ready === 1'b0) bp_v7++;
    if (g_v7_io_out_valid === 1'b1) begin
      ov_v7++;
      if (v7_io_isFlush) flush_v7++;
      if (!v7_io_rightOutFire) hold_v7++;
    end
    if (v8_io_in_valid && g_v8_io_in_ready === 1'b1) begin
      fire_v8++; por_v8 |= pcat_v8; pand_v8 &= pcat_v8;
    end
    if (v8_io_in_valid && g_v8_io_in_ready === 1'b0) bp_v8++;
    if (g_v8_io_out_valid === 1'b1) begin
      ov_v8++;
      if (v8_io_isFlush) flush_v8++;
      if (!v8_io_rightOutFire) hold_v8++;
    end
    if (v9_io_in_valid && g_v9_io_in_ready === 1'b1) begin
      fire_v9++; por_v9 |= pcat_v9; pand_v9 &= pcat_v9;
    end
    if (v9_io_in_valid && g_v9_io_in_ready === 1'b0) bp_v9++;
    if (g_v9_io_out_valid === 1'b1) begin
      ov_v9++;
      if (v9_io_isFlush) flush_v9++;
      if (!v9_io_rightOutFire) hold_v9++;
    end
    if (v10_io_in_valid && g_v10_io_in_ready === 1'b1) begin
      fire_v10++; por_v10 |= pcat_v10; pand_v10 &= pcat_v10;
    end
    if (v10_io_in_valid && g_v10_io_in_ready === 1'b0) bp_v10++;
    if (g_v10_io_out_valid === 1'b1) begin
      ov_v10++;
      if (v10_io_isFlush) flush_v10++;
      if (!v10_io_rightOutFire) hold_v10++;
    end
    if (v13_io_in_valid && g_v13_io_in_ready === 1'b1) begin
      fire_v13++; por_v13 |= pcat_v13; pand_v13 &= pcat_v13;
    end
    if (v13_io_in_valid && g_v13_io_in_ready === 1'b0) bp_v13++;
    if (g_v13_io_out_valid === 1'b1) begin
      ov_v13++;
      if (v13_io_isFlush) flush_v13++;
      if (!v13_io_rightOutFire) hold_v13++;
    end
    if (v14_io_in_valid && g_v14_io_in_ready === 1'b1) begin
      fire_v14++; por_v14 |= pcat_v14; pand_v14 &= pcat_v14;
    end
    if (v14_io_in_valid && g_v14_io_in_ready === 1'b0) bp_v14++;
    if (g_v14_io_out_valid === 1'b1) begin
      ov_v14++;
      if (v14_io_isFlush) flush_v14++;
      if (!v14_io_rightOutFire) hold_v14++;
    end
    if (v16_io_in_valid && g_v16_io_in_ready === 1'b1) begin
      fire_v16++; por_v16 |= pcat_v16; pand_v16 &= pcat_v16;
    end
    if (v16_io_in_valid && g_v16_io_in_ready === 1'b0) bp_v16++;
    if (g_v16_io_out_valid === 1'b1) begin
      ov_v16++;
      if (v16_io_isFlush) flush_v16++;
      if (!v16_io_rightOutFire) hold_v16++;
    end
    if (v18_io_in_valid && g_v18_io_in_ready === 1'b1) begin
      fire_v18++; por_v18 |= pcat_v18; pand_v18 &= pcat_v18;
    end
    if (v18_io_in_valid && g_v18_io_in_ready === 1'b0) bp_v18++;
    if (g_v18_io_out_valid === 1'b1) begin
      ov_v18++;
      if (v18_io_isFlush) flush_v18++;
      if (!v18_io_rightOutFire) hold_v18++;
    end
    if (v20_io_in_valid && g_v20_io_in_ready === 1'b1) begin
      fire_v20++; por_v20 |= pcat_v20; pand_v20 &= pcat_v20;
    end
    if (v20_io_in_valid && g_v20_io_in_ready === 1'b0) bp_v20++;
    if (g_v20_io_out_valid === 1'b1) begin
      ov_v20++;
      if (v20_io_isFlush) flush_v20++;
      if (!v20_io_rightOutFire) hold_v20++;
    end
    if (v23_io_in_valid && g_v23_io_in_ready === 1'b1) begin
      fire_v23++; por_v23 |= pcat_v23; pand_v23 &= pcat_v23;
    end
    if (v23_io_in_valid && g_v23_io_in_ready === 1'b0) bp_v23++;
    if (g_v23_io_out_valid === 1'b1) begin
      ov_v23++;
      if (v23_io_isFlush) flush_v23++;
      if (!v23_io_rightOutFire) hold_v23++;
      if (v23_io_isOlder && !v23_io_out_ready) olderdec_v23++;
    end
    if (v25_io_in_valid && g_v25_io_in_ready === 1'b1) begin
      fire_v25++; por_v25 |= pcat_v25; pand_v25 &= pcat_v25;
    end
    if (v25_io_in_valid && g_v25_io_in_ready === 1'b0) bp_v25++;
    if (g_v25_io_out_valid === 1'b1) begin
      ov_v25++;
      if (v25_io_isFlush) flush_v25++;
      if (!v25_io_rightOutFire) hold_v25++;
    end
  endtask

  int cov_fail = 0;
  task automatic gate(string nm, longint got, longint need, string why);
    if (got < need) begin
      $display("COVERAGE HOLE: %s = %0d < %0d —— %s", nm, got, need, why);
      cov_fail++;
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    reset = 1'b1;
    drive_all();
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_all();
      // 覆盖必须在**时钟沿之前**采：in_ready/out_valid 用的是沿前的 valid，
      // 沿后再采就永远看不到 flush（flush 恰恰把 valid 清成 0 了），fire/反压
      // 同理会串到下一拍。第一版就是沿后采，14 个变体 flush 全 0——覆盖闸抓到的。
      #1 sample_cov();
      @(posedge clock);
      #1 check_all();
    end

    $display("\n==== NewPipelineConnectPipe family: checks=%0d errors=%0d (ncycles=%0d) ====", checks, errors, NCYCLES);
    $display("%-32s %10s %8s %10s %8s %8s %8s %6s",
             "variant", "checks", "errors", "fire", "backpr", "flush", "hold", "payld");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe",
             nchk_v0, nerr_v0, fire_v0, bp_v0, flush_v0, hold_v0,
             ((&por_v0) && (pand_v0 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_1",
             nchk_v1, nerr_v1, fire_v1, bp_v1, flush_v1, hold_v1,
             ((&por_v1) && (pand_v1 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_5",
             nchk_v5, nerr_v5, fire_v5, bp_v5, flush_v5, hold_v5,
             ((&por_v5) && (pand_v5 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_7",
             nchk_v7, nerr_v7, fire_v7, bp_v7, flush_v7, hold_v7,
             ((&por_v7) && (pand_v7 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_8",
             nchk_v8, nerr_v8, fire_v8, bp_v8, flush_v8, hold_v8,
             ((&por_v8) && (pand_v8 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_9",
             nchk_v9, nerr_v9, fire_v9, bp_v9, flush_v9, hold_v9,
             ((&por_v9) && (pand_v9 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_10",
             nchk_v10, nerr_v10, fire_v10, bp_v10, flush_v10, hold_v10,
             ((&por_v10) && (pand_v10 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_13",
             nchk_v13, nerr_v13, fire_v13, bp_v13, flush_v13, hold_v13,
             ((&por_v13) && (pand_v13 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_14",
             nchk_v14, nerr_v14, fire_v14, bp_v14, flush_v14, hold_v14,
             ((&por_v14) && (pand_v14 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_16",
             nchk_v16, nerr_v16, fire_v16, bp_v16, flush_v16, hold_v16,
             ((&por_v16) && (pand_v16 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_18",
             nchk_v18, nerr_v18, fire_v18, bp_v18, flush_v18, hold_v18,
             ((&por_v18) && (pand_v18 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_20",
             nchk_v20, nerr_v20, fire_v20, bp_v20, flush_v20, hold_v20,
             ((&por_v20) && (pand_v20 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_23",
             nchk_v23, nerr_v23, fire_v23, bp_v23, flush_v23, hold_v23,
             ((&por_v23) && (pand_v23 == '0)) ? "ok" : "HOLE");
    $display("%-32s %10d %8d %10d %8d %8d %8d %6s", "NewPipelineConnectPipe_25",
             nchk_v25, nerr_v25, fire_v25, bp_v25, flush_v25, hold_v25,
             ((&por_v25) && (pand_v25 == '0)) ? "ok" : "HOLE");
    $display("NewPipelineConnectPipe_23 isOlder 决定性拍 = %0d", olderdec_v23);

    gate("NewPipelineConnectPipe.fire",  fire_v0,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe.backpr", bp_v0,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe.flush", flush_v0,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe.hold",  hold_v0,   100, "表项从没被压住过");
    if (!(&por_v0)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe payload 有位从未取到 1"); cov_fail++; end
    if (pand_v0 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_1.fire",  fire_v1,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_1.backpr", bp_v1,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_1.flush", flush_v1,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_1.hold",  hold_v1,   100, "表项从没被压住过");
    if (!(&por_v1)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_1 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v1 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_1 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_5.fire",  fire_v5,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_5.backpr", bp_v5,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_5.flush", flush_v5,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_5.hold",  hold_v5,   100, "表项从没被压住过");
    if (!(&por_v5)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_5 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v5 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_5 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_7.fire",  fire_v7,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_7.backpr", bp_v7,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_7.flush", flush_v7,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_7.hold",  hold_v7,   100, "表项从没被压住过");
    if (!(&por_v7)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_7 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v7 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_7 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_8.fire",  fire_v8,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_8.backpr", bp_v8,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_8.flush", flush_v8,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_8.hold",  hold_v8,   100, "表项从没被压住过");
    if (!(&por_v8)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_8 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v8 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_8 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_9.fire",  fire_v9,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_9.backpr", bp_v9,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_9.flush", flush_v9,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_9.hold",  hold_v9,   100, "表项从没被压住过");
    if (!(&por_v9)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_9 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v9 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_9 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_10.fire",  fire_v10,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_10.backpr", bp_v10,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_10.flush", flush_v10,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_10.hold",  hold_v10,   100, "表项从没被压住过");
    if (!(&por_v10)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_10 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v10 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_10 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_13.fire",  fire_v13,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_13.backpr", bp_v13,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_13.flush", flush_v13,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_13.hold",  hold_v13,   100, "表项从没被压住过");
    if (!(&por_v13)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_13 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v13 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_13 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_14.fire",  fire_v14,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_14.backpr", bp_v14,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_14.flush", flush_v14,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_14.hold",  hold_v14,   100, "表项从没被压住过");
    if (!(&por_v14)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_14 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v14 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_14 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_16.fire",  fire_v16,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_16.backpr", bp_v16,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_16.flush", flush_v16,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_16.hold",  hold_v16,   100, "表项从没被压住过");
    if (!(&por_v16)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_16 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v16 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_16 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_18.fire",  fire_v18,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_18.backpr", bp_v18,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_18.flush", flush_v18,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_18.hold",  hold_v18,   100, "表项从没被压住过");
    if (!(&por_v18)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_18 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v18 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_18 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_20.fire",  fire_v20,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_20.backpr", bp_v20,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_20.flush", flush_v20,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_20.hold",  hold_v20,   100, "表项从没被压住过");
    if (!(&por_v20)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_20 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v20 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_20 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_23.fire",  fire_v23,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_23.backpr", bp_v23,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_23.flush", flush_v23,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_23.hold",  hold_v23,   100, "表项从没被压住过");
    if (!(&por_v23)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_23 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v23 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_23 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_25.fire",  fire_v25,  1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_25.backpr", bp_v25,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_25.flush", flush_v25,   10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_25.hold",  hold_v25,   100, "表项从没被压住过");
    if (!(&por_v25)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_25 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v25 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_25 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_23.isOlder决定性拍", olderdec_v23, 100,
         "isOlder 从没单独决定过 in_ready —— 那一项等于没测");

    if (cov_fail != 0) begin
      $display("TEST FAILED (%0d 个覆盖闸没过)", cov_fail);
      $fatal(1);
    end
    if (errors == 0 && checks > 100000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
