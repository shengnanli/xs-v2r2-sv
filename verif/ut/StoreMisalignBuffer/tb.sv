// StoreMisalignBuffer UT —— golden 与重写件（StoreMisalignBuffer_xs）双例化，逐拍比全部 126 个输出口
// 自动生成：scripts/gen_smisalign.py + verif/ut/StoreMisalignBuffer/tb_template.py —— 勿手改
// 激励 / 比对口径 / 覆盖判据见 tb_template.py 文件头。
`timescale 1ns/1ps
`define ENQ_SHAPE(I) \
    io_enq_``I``_req_valid = pct(phase_enq_pct); \
    shape_enq(op, isvec, atype, va); \
    io_enq_``I``_req_bits_uop_fuOpType = op; \
    io_enq_``I``_req_bits_isvec = isvec; \
    io_enq_``I``_req_bits_alignedType = atype; \
    io_enq_``I``_req_bits_vaddr = va; \
    io_enq_``I``_req_bits_uop_uopIdx = 7'($urandom_range(0, 3)); \
    {io_enq_``I``_req_bits_uop_robIdx_flag, io_enq_``I``_req_bits_uop_robIdx_value} = rob_near(3);
module tb;
  int unsigned NCYCLES = 200000;
  int gate_req = 1;
  logic clock = 0, reset = 1;
  int errors = 0, checks = 0, cyc = 0;
  bit req_seen = 0;

  // ---- 输入（两侧共用）----
  logic io_redirect_valid;
  logic io_redirect_bits_robIdx_flag;
  logic [7:0] io_redirect_bits_robIdx_value;
  logic io_redirect_bits_level;
  logic io_enq_0_req_valid;
  logic io_enq_0_req_bits_uop_exceptionVec_0;
  logic io_enq_0_req_bits_uop_exceptionVec_1;
  logic io_enq_0_req_bits_uop_exceptionVec_2;
  logic io_enq_0_req_bits_uop_exceptionVec_4;
  logic io_enq_0_req_bits_uop_exceptionVec_5;
  logic io_enq_0_req_bits_uop_exceptionVec_8;
  logic io_enq_0_req_bits_uop_exceptionVec_9;
  logic io_enq_0_req_bits_uop_exceptionVec_10;
  logic io_enq_0_req_bits_uop_exceptionVec_11;
  logic io_enq_0_req_bits_uop_exceptionVec_12;
  logic io_enq_0_req_bits_uop_exceptionVec_13;
  logic io_enq_0_req_bits_uop_exceptionVec_14;
  logic io_enq_0_req_bits_uop_exceptionVec_16;
  logic io_enq_0_req_bits_uop_exceptionVec_17;
  logic io_enq_0_req_bits_uop_exceptionVec_18;
  logic io_enq_0_req_bits_uop_exceptionVec_19;
  logic io_enq_0_req_bits_uop_exceptionVec_20;
  logic io_enq_0_req_bits_uop_exceptionVec_21;
  logic io_enq_0_req_bits_uop_exceptionVec_22;
  logic [3:0] io_enq_0_req_bits_uop_trigger;
  logic io_enq_0_req_bits_uop_ftqPtr_flag;
  logic [5:0] io_enq_0_req_bits_uop_ftqPtr_value;
  logic [3:0] io_enq_0_req_bits_uop_ftqOffset;
  logic [34:0] io_enq_0_req_bits_uop_fuType;
  logic [8:0] io_enq_0_req_bits_uop_fuOpType;
  logic io_enq_0_req_bits_uop_rfWen;
  logic [7:0] io_enq_0_req_bits_uop_vpu_vstart;
  logic [2:0] io_enq_0_req_bits_uop_vpu_nf;
  logic [1:0] io_enq_0_req_bits_uop_vpu_veew;
  logic [6:0] io_enq_0_req_bits_uop_uopIdx;
  logic [7:0] io_enq_0_req_bits_uop_pdest;
  logic io_enq_0_req_bits_uop_robIdx_flag;
  logic [7:0] io_enq_0_req_bits_uop_robIdx_value;
  logic io_enq_0_req_bits_uop_debugInfo_eliminatedMove;
  logic [63:0] io_enq_0_req_bits_uop_debugInfo_renameTime;
  logic [63:0] io_enq_0_req_bits_uop_debugInfo_dispatchTime;
  logic [63:0] io_enq_0_req_bits_uop_debugInfo_enqRsTime;
  logic [63:0] io_enq_0_req_bits_uop_debugInfo_selectTime;
  logic [63:0] io_enq_0_req_bits_uop_debugInfo_issueTime;
  logic [63:0] io_enq_0_req_bits_uop_debugInfo_writebackTime;
  logic [63:0] io_enq_0_req_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] io_enq_0_req_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] io_enq_0_req_bits_uop_debugInfo_tlbRespTime;
  logic [55:0] io_enq_0_req_bits_uop_debug_seqNum_seqNum;
  logic [7:0] io_enq_0_req_bits_uop_debug_seqNum_uopIdx;
  logic io_enq_0_req_bits_uop_lqIdx_flag;
  logic [6:0] io_enq_0_req_bits_uop_lqIdx_value;
  logic io_enq_0_req_bits_uop_sqIdx_flag;
  logic [5:0] io_enq_0_req_bits_uop_sqIdx_value;
  logic [49:0] io_enq_0_req_bits_vaddr;
  logic [15:0] io_enq_0_req_bits_mask;
  logic io_enq_0_req_bits_isvec;
  logic [7:0] io_enq_0_req_bits_elemIdx;
  logic [2:0] io_enq_0_req_bits_alignedType;
  logic [3:0] io_enq_0_req_bits_mbIndex;
  logic [4:0] io_enq_0_req_bits_splitIndex;
  logic io_enq_0_revoke;
  logic io_enq_1_req_valid;
  logic io_enq_1_req_bits_uop_exceptionVec_0;
  logic io_enq_1_req_bits_uop_exceptionVec_1;
  logic io_enq_1_req_bits_uop_exceptionVec_2;
  logic io_enq_1_req_bits_uop_exceptionVec_4;
  logic io_enq_1_req_bits_uop_exceptionVec_5;
  logic io_enq_1_req_bits_uop_exceptionVec_8;
  logic io_enq_1_req_bits_uop_exceptionVec_9;
  logic io_enq_1_req_bits_uop_exceptionVec_10;
  logic io_enq_1_req_bits_uop_exceptionVec_11;
  logic io_enq_1_req_bits_uop_exceptionVec_12;
  logic io_enq_1_req_bits_uop_exceptionVec_13;
  logic io_enq_1_req_bits_uop_exceptionVec_14;
  logic io_enq_1_req_bits_uop_exceptionVec_16;
  logic io_enq_1_req_bits_uop_exceptionVec_17;
  logic io_enq_1_req_bits_uop_exceptionVec_18;
  logic io_enq_1_req_bits_uop_exceptionVec_19;
  logic io_enq_1_req_bits_uop_exceptionVec_20;
  logic io_enq_1_req_bits_uop_exceptionVec_21;
  logic io_enq_1_req_bits_uop_exceptionVec_22;
  logic [3:0] io_enq_1_req_bits_uop_trigger;
  logic io_enq_1_req_bits_uop_ftqPtr_flag;
  logic [5:0] io_enq_1_req_bits_uop_ftqPtr_value;
  logic [3:0] io_enq_1_req_bits_uop_ftqOffset;
  logic [34:0] io_enq_1_req_bits_uop_fuType;
  logic [8:0] io_enq_1_req_bits_uop_fuOpType;
  logic io_enq_1_req_bits_uop_rfWen;
  logic [7:0] io_enq_1_req_bits_uop_vpu_vstart;
  logic [2:0] io_enq_1_req_bits_uop_vpu_nf;
  logic [1:0] io_enq_1_req_bits_uop_vpu_veew;
  logic [6:0] io_enq_1_req_bits_uop_uopIdx;
  logic [7:0] io_enq_1_req_bits_uop_pdest;
  logic io_enq_1_req_bits_uop_robIdx_flag;
  logic [7:0] io_enq_1_req_bits_uop_robIdx_value;
  logic io_enq_1_req_bits_uop_debugInfo_eliminatedMove;
  logic [63:0] io_enq_1_req_bits_uop_debugInfo_renameTime;
  logic [63:0] io_enq_1_req_bits_uop_debugInfo_dispatchTime;
  logic [63:0] io_enq_1_req_bits_uop_debugInfo_enqRsTime;
  logic [63:0] io_enq_1_req_bits_uop_debugInfo_selectTime;
  logic [63:0] io_enq_1_req_bits_uop_debugInfo_issueTime;
  logic [63:0] io_enq_1_req_bits_uop_debugInfo_writebackTime;
  logic [63:0] io_enq_1_req_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] io_enq_1_req_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] io_enq_1_req_bits_uop_debugInfo_tlbRespTime;
  logic [55:0] io_enq_1_req_bits_uop_debug_seqNum_seqNum;
  logic [7:0] io_enq_1_req_bits_uop_debug_seqNum_uopIdx;
  logic io_enq_1_req_bits_uop_lqIdx_flag;
  logic [6:0] io_enq_1_req_bits_uop_lqIdx_value;
  logic io_enq_1_req_bits_uop_sqIdx_flag;
  logic [5:0] io_enq_1_req_bits_uop_sqIdx_value;
  logic [49:0] io_enq_1_req_bits_vaddr;
  logic [15:0] io_enq_1_req_bits_mask;
  logic io_enq_1_req_bits_isvec;
  logic [7:0] io_enq_1_req_bits_elemIdx;
  logic [2:0] io_enq_1_req_bits_alignedType;
  logic [3:0] io_enq_1_req_bits_mbIndex;
  logic [4:0] io_enq_1_req_bits_splitIndex;
  logic io_enq_1_revoke;
  logic io_rob_pendingst;
  logic io_rob_pendingPtr_flag;
  logic [7:0] io_rob_pendingPtr_value;
  logic io_splitStoreReq_ready;
  logic io_splitStoreResp_valid;
  logic io_splitStoreResp_bits_uop_exceptionVec_3;
  logic io_splitStoreResp_bits_uop_exceptionVec_6;
  logic io_splitStoreResp_bits_uop_exceptionVec_7;
  logic io_splitStoreResp_bits_uop_exceptionVec_15;
  logic io_splitStoreResp_bits_uop_exceptionVec_19;
  logic io_splitStoreResp_bits_uop_exceptionVec_23;
  logic [3:0] io_splitStoreResp_bits_uop_trigger;
  logic io_splitStoreResp_bits_uop_robIdx_flag;
  logic [7:0] io_splitStoreResp_bits_uop_robIdx_value;
  logic [49:0] io_splitStoreResp_bits_vaddr;
  logic io_splitStoreResp_bits_vaNeedExt;
  logic [47:0] io_splitStoreResp_bits_paddr;
  logic [63:0] io_splitStoreResp_bits_gpaddr;
  logic io_splitStoreResp_bits_nc;
  logic io_splitStoreResp_bits_mmio;
  logic io_splitStoreResp_bits_memBackTypeMM;
  logic io_splitStoreResp_bits_isForVSnonLeafPTE;
  logic io_splitStoreResp_bits_vecActive;
  logic io_splitStoreResp_bits_need_rep;
  logic io_writeBack_ready;
  logic io_storeOutValid;
  logic io_storeVecOutValid;
  logic io_sqControl_toStoreMisalignBuffer_sqPtr_flag;
  logic [5:0] io_sqControl_toStoreMisalignBuffer_sqPtr_value;
  logic io_sqControl_toStoreMisalignBuffer_doDeq;
  logic [6:0] io_sqControl_toStoreMisalignBuffer_uop_uopIdx;
  logic io_sqControl_toStoreMisalignBuffer_uop_robIdx_flag;
  logic [7:0] io_sqControl_toStoreMisalignBuffer_uop_robIdx_value;
  // ---- 输出（g_ = golden，i_ = 重写件）----
  wire   g_io_enq_0_req_ready, i_io_enq_0_req_ready;
  wire   g_io_enq_1_req_ready, i_io_enq_1_req_ready;
  wire   g_io_splitStoreReq_valid, i_io_splitStoreReq_valid;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_0, i_io_splitStoreReq_bits_uop_exceptionVec_0;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_1, i_io_splitStoreReq_bits_uop_exceptionVec_1;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_2, i_io_splitStoreReq_bits_uop_exceptionVec_2;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_4, i_io_splitStoreReq_bits_uop_exceptionVec_4;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_5, i_io_splitStoreReq_bits_uop_exceptionVec_5;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_8, i_io_splitStoreReq_bits_uop_exceptionVec_8;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_9, i_io_splitStoreReq_bits_uop_exceptionVec_9;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_10, i_io_splitStoreReq_bits_uop_exceptionVec_10;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_11, i_io_splitStoreReq_bits_uop_exceptionVec_11;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_12, i_io_splitStoreReq_bits_uop_exceptionVec_12;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_13, i_io_splitStoreReq_bits_uop_exceptionVec_13;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_14, i_io_splitStoreReq_bits_uop_exceptionVec_14;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_16, i_io_splitStoreReq_bits_uop_exceptionVec_16;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_17, i_io_splitStoreReq_bits_uop_exceptionVec_17;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_18, i_io_splitStoreReq_bits_uop_exceptionVec_18;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_19, i_io_splitStoreReq_bits_uop_exceptionVec_19;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_20, i_io_splitStoreReq_bits_uop_exceptionVec_20;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_21, i_io_splitStoreReq_bits_uop_exceptionVec_21;
  wire   g_io_splitStoreReq_bits_uop_exceptionVec_22, i_io_splitStoreReq_bits_uop_exceptionVec_22;
  wire  [3:0]  g_io_splitStoreReq_bits_uop_trigger, i_io_splitStoreReq_bits_uop_trigger;
  wire   g_io_splitStoreReq_bits_uop_ftqPtr_flag, i_io_splitStoreReq_bits_uop_ftqPtr_flag;
  wire  [5:0]  g_io_splitStoreReq_bits_uop_ftqPtr_value, i_io_splitStoreReq_bits_uop_ftqPtr_value;
  wire  [3:0]  g_io_splitStoreReq_bits_uop_ftqOffset, i_io_splitStoreReq_bits_uop_ftqOffset;
  wire  [34:0]  g_io_splitStoreReq_bits_uop_fuType, i_io_splitStoreReq_bits_uop_fuType;
  wire  [8:0]  g_io_splitStoreReq_bits_uop_fuOpType, i_io_splitStoreReq_bits_uop_fuOpType;
  wire   g_io_splitStoreReq_bits_uop_rfWen, i_io_splitStoreReq_bits_uop_rfWen;
  wire  [7:0]  g_io_splitStoreReq_bits_uop_vpu_vstart, i_io_splitStoreReq_bits_uop_vpu_vstart;
  wire  [2:0]  g_io_splitStoreReq_bits_uop_vpu_nf, i_io_splitStoreReq_bits_uop_vpu_nf;
  wire  [1:0]  g_io_splitStoreReq_bits_uop_vpu_veew, i_io_splitStoreReq_bits_uop_vpu_veew;
  wire  [6:0]  g_io_splitStoreReq_bits_uop_uopIdx, i_io_splitStoreReq_bits_uop_uopIdx;
  wire  [7:0]  g_io_splitStoreReq_bits_uop_pdest, i_io_splitStoreReq_bits_uop_pdest;
  wire   g_io_splitStoreReq_bits_uop_robIdx_flag, i_io_splitStoreReq_bits_uop_robIdx_flag;
  wire  [7:0]  g_io_splitStoreReq_bits_uop_robIdx_value, i_io_splitStoreReq_bits_uop_robIdx_value;
  wire   g_io_splitStoreReq_bits_uop_debugInfo_eliminatedMove, i_io_splitStoreReq_bits_uop_debugInfo_eliminatedMove;
  wire  [63:0]  g_io_splitStoreReq_bits_uop_debugInfo_renameTime, i_io_splitStoreReq_bits_uop_debugInfo_renameTime;
  wire  [63:0]  g_io_splitStoreReq_bits_uop_debugInfo_dispatchTime, i_io_splitStoreReq_bits_uop_debugInfo_dispatchTime;
  wire  [63:0]  g_io_splitStoreReq_bits_uop_debugInfo_enqRsTime, i_io_splitStoreReq_bits_uop_debugInfo_enqRsTime;
  wire  [63:0]  g_io_splitStoreReq_bits_uop_debugInfo_selectTime, i_io_splitStoreReq_bits_uop_debugInfo_selectTime;
  wire  [63:0]  g_io_splitStoreReq_bits_uop_debugInfo_issueTime, i_io_splitStoreReq_bits_uop_debugInfo_issueTime;
  wire  [63:0]  g_io_splitStoreReq_bits_uop_debugInfo_writebackTime, i_io_splitStoreReq_bits_uop_debugInfo_writebackTime;
  wire  [63:0]  g_io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id, i_io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id;
  wire  [63:0]  g_io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime, i_io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime;
  wire  [63:0]  g_io_splitStoreReq_bits_uop_debugInfo_tlbRespTime, i_io_splitStoreReq_bits_uop_debugInfo_tlbRespTime;
  wire  [55:0]  g_io_splitStoreReq_bits_uop_debug_seqNum_seqNum, i_io_splitStoreReq_bits_uop_debug_seqNum_seqNum;
  wire  [7:0]  g_io_splitStoreReq_bits_uop_debug_seqNum_uopIdx, i_io_splitStoreReq_bits_uop_debug_seqNum_uopIdx;
  wire   g_io_splitStoreReq_bits_uop_lqIdx_flag, i_io_splitStoreReq_bits_uop_lqIdx_flag;
  wire  [6:0]  g_io_splitStoreReq_bits_uop_lqIdx_value, i_io_splitStoreReq_bits_uop_lqIdx_value;
  wire   g_io_splitStoreReq_bits_uop_sqIdx_flag, i_io_splitStoreReq_bits_uop_sqIdx_flag;
  wire  [5:0]  g_io_splitStoreReq_bits_uop_sqIdx_value, i_io_splitStoreReq_bits_uop_sqIdx_value;
  wire  [49:0]  g_io_splitStoreReq_bits_vaddr, i_io_splitStoreReq_bits_vaddr;
  wire  [15:0]  g_io_splitStoreReq_bits_mask, i_io_splitStoreReq_bits_mask;
  wire   g_io_splitStoreReq_bits_isvec, i_io_splitStoreReq_bits_isvec;
  wire   g_io_splitStoreReq_bits_is128bit, i_io_splitStoreReq_bits_is128bit;
  wire   g_io_splitStoreReq_bits_isFinalSplit, i_io_splitStoreReq_bits_isFinalSplit;
  wire   g_io_writeBack_valid, i_io_writeBack_valid;
  wire   g_io_writeBack_bits_uop_exceptionVec_3, i_io_writeBack_bits_uop_exceptionVec_3;
  wire   g_io_writeBack_bits_uop_exceptionVec_6, i_io_writeBack_bits_uop_exceptionVec_6;
  wire   g_io_writeBack_bits_uop_exceptionVec_7, i_io_writeBack_bits_uop_exceptionVec_7;
  wire   g_io_writeBack_bits_uop_exceptionVec_15, i_io_writeBack_bits_uop_exceptionVec_15;
  wire   g_io_writeBack_bits_uop_exceptionVec_19, i_io_writeBack_bits_uop_exceptionVec_19;
  wire   g_io_writeBack_bits_uop_exceptionVec_23, i_io_writeBack_bits_uop_exceptionVec_23;
  wire  [3:0]  g_io_writeBack_bits_uop_trigger, i_io_writeBack_bits_uop_trigger;
  wire   g_io_writeBack_bits_uop_rfWen, i_io_writeBack_bits_uop_rfWen;
  wire  [7:0]  g_io_writeBack_bits_uop_pdest, i_io_writeBack_bits_uop_pdest;
  wire   g_io_writeBack_bits_uop_robIdx_flag, i_io_writeBack_bits_uop_robIdx_flag;
  wire  [7:0]  g_io_writeBack_bits_uop_robIdx_value, i_io_writeBack_bits_uop_robIdx_value;
  wire   g_io_writeBack_bits_uop_debugInfo_eliminatedMove, i_io_writeBack_bits_uop_debugInfo_eliminatedMove;
  wire  [63:0]  g_io_writeBack_bits_uop_debugInfo_renameTime, i_io_writeBack_bits_uop_debugInfo_renameTime;
  wire  [63:0]  g_io_writeBack_bits_uop_debugInfo_dispatchTime, i_io_writeBack_bits_uop_debugInfo_dispatchTime;
  wire  [63:0]  g_io_writeBack_bits_uop_debugInfo_enqRsTime, i_io_writeBack_bits_uop_debugInfo_enqRsTime;
  wire  [63:0]  g_io_writeBack_bits_uop_debugInfo_selectTime, i_io_writeBack_bits_uop_debugInfo_selectTime;
  wire  [63:0]  g_io_writeBack_bits_uop_debugInfo_issueTime, i_io_writeBack_bits_uop_debugInfo_issueTime;
  wire  [63:0]  g_io_writeBack_bits_uop_debugInfo_writebackTime, i_io_writeBack_bits_uop_debugInfo_writebackTime;
  wire  [63:0]  g_io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id, i_io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id;
  wire  [63:0]  g_io_writeBack_bits_uop_debugInfo_tlbFirstReqTime, i_io_writeBack_bits_uop_debugInfo_tlbFirstReqTime;
  wire  [63:0]  g_io_writeBack_bits_uop_debugInfo_tlbRespTime, i_io_writeBack_bits_uop_debugInfo_tlbRespTime;
  wire  [55:0]  g_io_writeBack_bits_uop_debug_seqNum_seqNum, i_io_writeBack_bits_uop_debug_seqNum_seqNum;
  wire  [7:0]  g_io_writeBack_bits_uop_debug_seqNum_uopIdx, i_io_writeBack_bits_uop_debug_seqNum_uopIdx;
  wire   g_io_writeBack_bits_uop_sqIdx_flag, i_io_writeBack_bits_uop_sqIdx_flag;
  wire  [5:0]  g_io_writeBack_bits_uop_sqIdx_value, i_io_writeBack_bits_uop_sqIdx_value;
  wire   g_io_writeBack_bits_debug_isMMIO, i_io_writeBack_bits_debug_isMMIO;
  wire   g_io_writeBack_bits_debug_isNCIO, i_io_writeBack_bits_debug_isNCIO;
  wire  [47:0]  g_io_writeBack_bits_debug_paddr, i_io_writeBack_bits_debug_paddr;
  wire  [49:0]  g_io_writeBack_bits_debug_vaddr, i_io_writeBack_bits_debug_vaddr;
  wire   g_io_vecWriteBack_0_valid, i_io_vecWriteBack_0_valid;
  wire  [3:0]  g_io_vecWriteBack_0_bits_mBIndex, i_io_vecWriteBack_0_bits_mBIndex;
  wire   g_io_vecWriteBack_0_bits_exceptionVec_3, i_io_vecWriteBack_0_bits_exceptionVec_3;
  wire   g_io_vecWriteBack_0_bits_exceptionVec_6, i_io_vecWriteBack_0_bits_exceptionVec_6;
  wire   g_io_vecWriteBack_0_bits_exceptionVec_7, i_io_vecWriteBack_0_bits_exceptionVec_7;
  wire   g_io_vecWriteBack_0_bits_exceptionVec_15, i_io_vecWriteBack_0_bits_exceptionVec_15;
  wire   g_io_vecWriteBack_0_bits_exceptionVec_19, i_io_vecWriteBack_0_bits_exceptionVec_19;
  wire   g_io_vecWriteBack_0_bits_exceptionVec_23, i_io_vecWriteBack_0_bits_exceptionVec_23;
  wire   g_io_vecWriteBack_0_bits_hasException, i_io_vecWriteBack_0_bits_hasException;
  wire  [63:0]  g_io_vecWriteBack_0_bits_vaddr, i_io_vecWriteBack_0_bits_vaddr;
  wire   g_io_vecWriteBack_0_bits_vaNeedExt, i_io_vecWriteBack_0_bits_vaNeedExt;
  wire  [63:0]  g_io_vecWriteBack_0_bits_gpaddr, i_io_vecWriteBack_0_bits_gpaddr;
  wire   g_io_vecWriteBack_0_bits_isForVSnonLeafPTE, i_io_vecWriteBack_0_bits_isForVSnonLeafPTE;
  wire  [7:0]  g_io_vecWriteBack_0_bits_vstart, i_io_vecWriteBack_0_bits_vstart;
  wire  [7:0]  g_io_vecWriteBack_0_bits_elemIdx, i_io_vecWriteBack_0_bits_elemIdx;
  wire  [15:0]  g_io_vecWriteBack_0_bits_mask, i_io_vecWriteBack_0_bits_mask;
  wire  [4:0]  g_io_vecWriteBack_0_bits_splitIndex, i_io_vecWriteBack_0_bits_splitIndex;
  wire   g_io_vecWriteBack_1_valid, i_io_vecWriteBack_1_valid;
  wire  [3:0]  g_io_vecWriteBack_1_bits_mBIndex, i_io_vecWriteBack_1_bits_mBIndex;
  wire   g_io_vecWriteBack_1_bits_exceptionVec_3, i_io_vecWriteBack_1_bits_exceptionVec_3;
  wire   g_io_vecWriteBack_1_bits_exceptionVec_6, i_io_vecWriteBack_1_bits_exceptionVec_6;
  wire   g_io_vecWriteBack_1_bits_exceptionVec_7, i_io_vecWriteBack_1_bits_exceptionVec_7;
  wire   g_io_vecWriteBack_1_bits_exceptionVec_15, i_io_vecWriteBack_1_bits_exceptionVec_15;
  wire   g_io_vecWriteBack_1_bits_exceptionVec_19, i_io_vecWriteBack_1_bits_exceptionVec_19;
  wire   g_io_vecWriteBack_1_bits_exceptionVec_23, i_io_vecWriteBack_1_bits_exceptionVec_23;
  wire   g_io_vecWriteBack_1_bits_hasException, i_io_vecWriteBack_1_bits_hasException;
  wire  [63:0]  g_io_vecWriteBack_1_bits_vaddr, i_io_vecWriteBack_1_bits_vaddr;
  wire   g_io_vecWriteBack_1_bits_vaNeedExt, i_io_vecWriteBack_1_bits_vaNeedExt;
  wire  [63:0]  g_io_vecWriteBack_1_bits_gpaddr, i_io_vecWriteBack_1_bits_gpaddr;
  wire   g_io_vecWriteBack_1_bits_isForVSnonLeafPTE, i_io_vecWriteBack_1_bits_isForVSnonLeafPTE;
  wire  [7:0]  g_io_vecWriteBack_1_bits_vstart, i_io_vecWriteBack_1_bits_vstart;
  wire  [7:0]  g_io_vecWriteBack_1_bits_elemIdx, i_io_vecWriteBack_1_bits_elemIdx;
  wire  [15:0]  g_io_vecWriteBack_1_bits_mask, i_io_vecWriteBack_1_bits_mask;
  wire  [4:0]  g_io_vecWriteBack_1_bits_splitIndex, i_io_vecWriteBack_1_bits_splitIndex;
  wire   g_io_sqControl_toStoreQueue_crossPageWithHit, i_io_sqControl_toStoreQueue_crossPageWithHit;
  wire   g_io_sqControl_toStoreQueue_crossPageCanDeq, i_io_sqControl_toStoreQueue_crossPageCanDeq;
  wire  [47:0]  g_io_sqControl_toStoreQueue_paddr, i_io_sqControl_toStoreQueue_paddr;
  wire   g_io_sqControl_toStoreQueue_withSamePtr, i_io_sqControl_toStoreQueue_withSamePtr;
  wire   g_io_toVecSplit_empty, i_io_toVecSplit_empty;

  StoreMisalignBuffer u_g (
    .clock (clock),
    .reset (reset),
    .io_redirect_valid (io_redirect_valid),
    .io_redirect_bits_robIdx_flag (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level (io_redirect_bits_level),
    .io_enq_0_req_valid (io_enq_0_req_valid),
    .io_enq_0_req_bits_uop_exceptionVec_0 (io_enq_0_req_bits_uop_exceptionVec_0),
    .io_enq_0_req_bits_uop_exceptionVec_1 (io_enq_0_req_bits_uop_exceptionVec_1),
    .io_enq_0_req_bits_uop_exceptionVec_2 (io_enq_0_req_bits_uop_exceptionVec_2),
    .io_enq_0_req_bits_uop_exceptionVec_4 (io_enq_0_req_bits_uop_exceptionVec_4),
    .io_enq_0_req_bits_uop_exceptionVec_5 (io_enq_0_req_bits_uop_exceptionVec_5),
    .io_enq_0_req_bits_uop_exceptionVec_8 (io_enq_0_req_bits_uop_exceptionVec_8),
    .io_enq_0_req_bits_uop_exceptionVec_9 (io_enq_0_req_bits_uop_exceptionVec_9),
    .io_enq_0_req_bits_uop_exceptionVec_10 (io_enq_0_req_bits_uop_exceptionVec_10),
    .io_enq_0_req_bits_uop_exceptionVec_11 (io_enq_0_req_bits_uop_exceptionVec_11),
    .io_enq_0_req_bits_uop_exceptionVec_12 (io_enq_0_req_bits_uop_exceptionVec_12),
    .io_enq_0_req_bits_uop_exceptionVec_13 (io_enq_0_req_bits_uop_exceptionVec_13),
    .io_enq_0_req_bits_uop_exceptionVec_14 (io_enq_0_req_bits_uop_exceptionVec_14),
    .io_enq_0_req_bits_uop_exceptionVec_16 (io_enq_0_req_bits_uop_exceptionVec_16),
    .io_enq_0_req_bits_uop_exceptionVec_17 (io_enq_0_req_bits_uop_exceptionVec_17),
    .io_enq_0_req_bits_uop_exceptionVec_18 (io_enq_0_req_bits_uop_exceptionVec_18),
    .io_enq_0_req_bits_uop_exceptionVec_19 (io_enq_0_req_bits_uop_exceptionVec_19),
    .io_enq_0_req_bits_uop_exceptionVec_20 (io_enq_0_req_bits_uop_exceptionVec_20),
    .io_enq_0_req_bits_uop_exceptionVec_21 (io_enq_0_req_bits_uop_exceptionVec_21),
    .io_enq_0_req_bits_uop_exceptionVec_22 (io_enq_0_req_bits_uop_exceptionVec_22),
    .io_enq_0_req_bits_uop_trigger (io_enq_0_req_bits_uop_trigger),
    .io_enq_0_req_bits_uop_ftqPtr_flag (io_enq_0_req_bits_uop_ftqPtr_flag),
    .io_enq_0_req_bits_uop_ftqPtr_value (io_enq_0_req_bits_uop_ftqPtr_value),
    .io_enq_0_req_bits_uop_ftqOffset (io_enq_0_req_bits_uop_ftqOffset),
    .io_enq_0_req_bits_uop_fuType (io_enq_0_req_bits_uop_fuType),
    .io_enq_0_req_bits_uop_fuOpType (io_enq_0_req_bits_uop_fuOpType),
    .io_enq_0_req_bits_uop_rfWen (io_enq_0_req_bits_uop_rfWen),
    .io_enq_0_req_bits_uop_vpu_vstart (io_enq_0_req_bits_uop_vpu_vstart),
    .io_enq_0_req_bits_uop_vpu_nf (io_enq_0_req_bits_uop_vpu_nf),
    .io_enq_0_req_bits_uop_vpu_veew (io_enq_0_req_bits_uop_vpu_veew),
    .io_enq_0_req_bits_uop_uopIdx (io_enq_0_req_bits_uop_uopIdx),
    .io_enq_0_req_bits_uop_pdest (io_enq_0_req_bits_uop_pdest),
    .io_enq_0_req_bits_uop_robIdx_flag (io_enq_0_req_bits_uop_robIdx_flag),
    .io_enq_0_req_bits_uop_robIdx_value (io_enq_0_req_bits_uop_robIdx_value),
    .io_enq_0_req_bits_uop_debugInfo_eliminatedMove (io_enq_0_req_bits_uop_debugInfo_eliminatedMove),
    .io_enq_0_req_bits_uop_debugInfo_renameTime (io_enq_0_req_bits_uop_debugInfo_renameTime),
    .io_enq_0_req_bits_uop_debugInfo_dispatchTime (io_enq_0_req_bits_uop_debugInfo_dispatchTime),
    .io_enq_0_req_bits_uop_debugInfo_enqRsTime (io_enq_0_req_bits_uop_debugInfo_enqRsTime),
    .io_enq_0_req_bits_uop_debugInfo_selectTime (io_enq_0_req_bits_uop_debugInfo_selectTime),
    .io_enq_0_req_bits_uop_debugInfo_issueTime (io_enq_0_req_bits_uop_debugInfo_issueTime),
    .io_enq_0_req_bits_uop_debugInfo_writebackTime (io_enq_0_req_bits_uop_debugInfo_writebackTime),
    .io_enq_0_req_bits_uop_debugInfo_runahead_checkpoint_id (io_enq_0_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_enq_0_req_bits_uop_debugInfo_tlbFirstReqTime (io_enq_0_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_enq_0_req_bits_uop_debugInfo_tlbRespTime (io_enq_0_req_bits_uop_debugInfo_tlbRespTime),
    .io_enq_0_req_bits_uop_debug_seqNum_seqNum (io_enq_0_req_bits_uop_debug_seqNum_seqNum),
    .io_enq_0_req_bits_uop_debug_seqNum_uopIdx (io_enq_0_req_bits_uop_debug_seqNum_uopIdx),
    .io_enq_0_req_bits_uop_lqIdx_flag (io_enq_0_req_bits_uop_lqIdx_flag),
    .io_enq_0_req_bits_uop_lqIdx_value (io_enq_0_req_bits_uop_lqIdx_value),
    .io_enq_0_req_bits_uop_sqIdx_flag (io_enq_0_req_bits_uop_sqIdx_flag),
    .io_enq_0_req_bits_uop_sqIdx_value (io_enq_0_req_bits_uop_sqIdx_value),
    .io_enq_0_req_bits_vaddr (io_enq_0_req_bits_vaddr),
    .io_enq_0_req_bits_mask (io_enq_0_req_bits_mask),
    .io_enq_0_req_bits_isvec (io_enq_0_req_bits_isvec),
    .io_enq_0_req_bits_elemIdx (io_enq_0_req_bits_elemIdx),
    .io_enq_0_req_bits_alignedType (io_enq_0_req_bits_alignedType),
    .io_enq_0_req_bits_mbIndex (io_enq_0_req_bits_mbIndex),
    .io_enq_0_req_bits_splitIndex (io_enq_0_req_bits_splitIndex),
    .io_enq_0_revoke (io_enq_0_revoke),
    .io_enq_1_req_valid (io_enq_1_req_valid),
    .io_enq_1_req_bits_uop_exceptionVec_0 (io_enq_1_req_bits_uop_exceptionVec_0),
    .io_enq_1_req_bits_uop_exceptionVec_1 (io_enq_1_req_bits_uop_exceptionVec_1),
    .io_enq_1_req_bits_uop_exceptionVec_2 (io_enq_1_req_bits_uop_exceptionVec_2),
    .io_enq_1_req_bits_uop_exceptionVec_4 (io_enq_1_req_bits_uop_exceptionVec_4),
    .io_enq_1_req_bits_uop_exceptionVec_5 (io_enq_1_req_bits_uop_exceptionVec_5),
    .io_enq_1_req_bits_uop_exceptionVec_8 (io_enq_1_req_bits_uop_exceptionVec_8),
    .io_enq_1_req_bits_uop_exceptionVec_9 (io_enq_1_req_bits_uop_exceptionVec_9),
    .io_enq_1_req_bits_uop_exceptionVec_10 (io_enq_1_req_bits_uop_exceptionVec_10),
    .io_enq_1_req_bits_uop_exceptionVec_11 (io_enq_1_req_bits_uop_exceptionVec_11),
    .io_enq_1_req_bits_uop_exceptionVec_12 (io_enq_1_req_bits_uop_exceptionVec_12),
    .io_enq_1_req_bits_uop_exceptionVec_13 (io_enq_1_req_bits_uop_exceptionVec_13),
    .io_enq_1_req_bits_uop_exceptionVec_14 (io_enq_1_req_bits_uop_exceptionVec_14),
    .io_enq_1_req_bits_uop_exceptionVec_16 (io_enq_1_req_bits_uop_exceptionVec_16),
    .io_enq_1_req_bits_uop_exceptionVec_17 (io_enq_1_req_bits_uop_exceptionVec_17),
    .io_enq_1_req_bits_uop_exceptionVec_18 (io_enq_1_req_bits_uop_exceptionVec_18),
    .io_enq_1_req_bits_uop_exceptionVec_19 (io_enq_1_req_bits_uop_exceptionVec_19),
    .io_enq_1_req_bits_uop_exceptionVec_20 (io_enq_1_req_bits_uop_exceptionVec_20),
    .io_enq_1_req_bits_uop_exceptionVec_21 (io_enq_1_req_bits_uop_exceptionVec_21),
    .io_enq_1_req_bits_uop_exceptionVec_22 (io_enq_1_req_bits_uop_exceptionVec_22),
    .io_enq_1_req_bits_uop_trigger (io_enq_1_req_bits_uop_trigger),
    .io_enq_1_req_bits_uop_ftqPtr_flag (io_enq_1_req_bits_uop_ftqPtr_flag),
    .io_enq_1_req_bits_uop_ftqPtr_value (io_enq_1_req_bits_uop_ftqPtr_value),
    .io_enq_1_req_bits_uop_ftqOffset (io_enq_1_req_bits_uop_ftqOffset),
    .io_enq_1_req_bits_uop_fuType (io_enq_1_req_bits_uop_fuType),
    .io_enq_1_req_bits_uop_fuOpType (io_enq_1_req_bits_uop_fuOpType),
    .io_enq_1_req_bits_uop_rfWen (io_enq_1_req_bits_uop_rfWen),
    .io_enq_1_req_bits_uop_vpu_vstart (io_enq_1_req_bits_uop_vpu_vstart),
    .io_enq_1_req_bits_uop_vpu_nf (io_enq_1_req_bits_uop_vpu_nf),
    .io_enq_1_req_bits_uop_vpu_veew (io_enq_1_req_bits_uop_vpu_veew),
    .io_enq_1_req_bits_uop_uopIdx (io_enq_1_req_bits_uop_uopIdx),
    .io_enq_1_req_bits_uop_pdest (io_enq_1_req_bits_uop_pdest),
    .io_enq_1_req_bits_uop_robIdx_flag (io_enq_1_req_bits_uop_robIdx_flag),
    .io_enq_1_req_bits_uop_robIdx_value (io_enq_1_req_bits_uop_robIdx_value),
    .io_enq_1_req_bits_uop_debugInfo_eliminatedMove (io_enq_1_req_bits_uop_debugInfo_eliminatedMove),
    .io_enq_1_req_bits_uop_debugInfo_renameTime (io_enq_1_req_bits_uop_debugInfo_renameTime),
    .io_enq_1_req_bits_uop_debugInfo_dispatchTime (io_enq_1_req_bits_uop_debugInfo_dispatchTime),
    .io_enq_1_req_bits_uop_debugInfo_enqRsTime (io_enq_1_req_bits_uop_debugInfo_enqRsTime),
    .io_enq_1_req_bits_uop_debugInfo_selectTime (io_enq_1_req_bits_uop_debugInfo_selectTime),
    .io_enq_1_req_bits_uop_debugInfo_issueTime (io_enq_1_req_bits_uop_debugInfo_issueTime),
    .io_enq_1_req_bits_uop_debugInfo_writebackTime (io_enq_1_req_bits_uop_debugInfo_writebackTime),
    .io_enq_1_req_bits_uop_debugInfo_runahead_checkpoint_id (io_enq_1_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_enq_1_req_bits_uop_debugInfo_tlbFirstReqTime (io_enq_1_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_enq_1_req_bits_uop_debugInfo_tlbRespTime (io_enq_1_req_bits_uop_debugInfo_tlbRespTime),
    .io_enq_1_req_bits_uop_debug_seqNum_seqNum (io_enq_1_req_bits_uop_debug_seqNum_seqNum),
    .io_enq_1_req_bits_uop_debug_seqNum_uopIdx (io_enq_1_req_bits_uop_debug_seqNum_uopIdx),
    .io_enq_1_req_bits_uop_lqIdx_flag (io_enq_1_req_bits_uop_lqIdx_flag),
    .io_enq_1_req_bits_uop_lqIdx_value (io_enq_1_req_bits_uop_lqIdx_value),
    .io_enq_1_req_bits_uop_sqIdx_flag (io_enq_1_req_bits_uop_sqIdx_flag),
    .io_enq_1_req_bits_uop_sqIdx_value (io_enq_1_req_bits_uop_sqIdx_value),
    .io_enq_1_req_bits_vaddr (io_enq_1_req_bits_vaddr),
    .io_enq_1_req_bits_mask (io_enq_1_req_bits_mask),
    .io_enq_1_req_bits_isvec (io_enq_1_req_bits_isvec),
    .io_enq_1_req_bits_elemIdx (io_enq_1_req_bits_elemIdx),
    .io_enq_1_req_bits_alignedType (io_enq_1_req_bits_alignedType),
    .io_enq_1_req_bits_mbIndex (io_enq_1_req_bits_mbIndex),
    .io_enq_1_req_bits_splitIndex (io_enq_1_req_bits_splitIndex),
    .io_enq_1_revoke (io_enq_1_revoke),
    .io_rob_pendingst (io_rob_pendingst),
    .io_rob_pendingPtr_flag (io_rob_pendingPtr_flag),
    .io_rob_pendingPtr_value (io_rob_pendingPtr_value),
    .io_splitStoreReq_ready (io_splitStoreReq_ready),
    .io_splitStoreResp_valid (io_splitStoreResp_valid),
    .io_splitStoreResp_bits_uop_exceptionVec_3 (io_splitStoreResp_bits_uop_exceptionVec_3),
    .io_splitStoreResp_bits_uop_exceptionVec_6 (io_splitStoreResp_bits_uop_exceptionVec_6),
    .io_splitStoreResp_bits_uop_exceptionVec_7 (io_splitStoreResp_bits_uop_exceptionVec_7),
    .io_splitStoreResp_bits_uop_exceptionVec_15 (io_splitStoreResp_bits_uop_exceptionVec_15),
    .io_splitStoreResp_bits_uop_exceptionVec_19 (io_splitStoreResp_bits_uop_exceptionVec_19),
    .io_splitStoreResp_bits_uop_exceptionVec_23 (io_splitStoreResp_bits_uop_exceptionVec_23),
    .io_splitStoreResp_bits_uop_trigger (io_splitStoreResp_bits_uop_trigger),
    .io_splitStoreResp_bits_uop_robIdx_flag (io_splitStoreResp_bits_uop_robIdx_flag),
    .io_splitStoreResp_bits_uop_robIdx_value (io_splitStoreResp_bits_uop_robIdx_value),
    .io_splitStoreResp_bits_vaddr (io_splitStoreResp_bits_vaddr),
    .io_splitStoreResp_bits_vaNeedExt (io_splitStoreResp_bits_vaNeedExt),
    .io_splitStoreResp_bits_paddr (io_splitStoreResp_bits_paddr),
    .io_splitStoreResp_bits_gpaddr (io_splitStoreResp_bits_gpaddr),
    .io_splitStoreResp_bits_nc (io_splitStoreResp_bits_nc),
    .io_splitStoreResp_bits_mmio (io_splitStoreResp_bits_mmio),
    .io_splitStoreResp_bits_memBackTypeMM (io_splitStoreResp_bits_memBackTypeMM),
    .io_splitStoreResp_bits_isForVSnonLeafPTE (io_splitStoreResp_bits_isForVSnonLeafPTE),
    .io_splitStoreResp_bits_vecActive (io_splitStoreResp_bits_vecActive),
    .io_splitStoreResp_bits_need_rep (io_splitStoreResp_bits_need_rep),
    .io_writeBack_ready (io_writeBack_ready),
    .io_storeOutValid (io_storeOutValid),
    .io_storeVecOutValid (io_storeVecOutValid),
    .io_sqControl_toStoreMisalignBuffer_sqPtr_flag (io_sqControl_toStoreMisalignBuffer_sqPtr_flag),
    .io_sqControl_toStoreMisalignBuffer_sqPtr_value (io_sqControl_toStoreMisalignBuffer_sqPtr_value),
    .io_sqControl_toStoreMisalignBuffer_doDeq (io_sqControl_toStoreMisalignBuffer_doDeq),
    .io_sqControl_toStoreMisalignBuffer_uop_uopIdx (io_sqControl_toStoreMisalignBuffer_uop_uopIdx),
    .io_sqControl_toStoreMisalignBuffer_uop_robIdx_flag (io_sqControl_toStoreMisalignBuffer_uop_robIdx_flag),
    .io_sqControl_toStoreMisalignBuffer_uop_robIdx_value (io_sqControl_toStoreMisalignBuffer_uop_robIdx_value),
    .io_enq_0_req_ready (g_io_enq_0_req_ready),
    .io_enq_1_req_ready (g_io_enq_1_req_ready),
    .io_splitStoreReq_valid (g_io_splitStoreReq_valid),
    .io_splitStoreReq_bits_uop_exceptionVec_0 (g_io_splitStoreReq_bits_uop_exceptionVec_0),
    .io_splitStoreReq_bits_uop_exceptionVec_1 (g_io_splitStoreReq_bits_uop_exceptionVec_1),
    .io_splitStoreReq_bits_uop_exceptionVec_2 (g_io_splitStoreReq_bits_uop_exceptionVec_2),
    .io_splitStoreReq_bits_uop_exceptionVec_4 (g_io_splitStoreReq_bits_uop_exceptionVec_4),
    .io_splitStoreReq_bits_uop_exceptionVec_5 (g_io_splitStoreReq_bits_uop_exceptionVec_5),
    .io_splitStoreReq_bits_uop_exceptionVec_8 (g_io_splitStoreReq_bits_uop_exceptionVec_8),
    .io_splitStoreReq_bits_uop_exceptionVec_9 (g_io_splitStoreReq_bits_uop_exceptionVec_9),
    .io_splitStoreReq_bits_uop_exceptionVec_10 (g_io_splitStoreReq_bits_uop_exceptionVec_10),
    .io_splitStoreReq_bits_uop_exceptionVec_11 (g_io_splitStoreReq_bits_uop_exceptionVec_11),
    .io_splitStoreReq_bits_uop_exceptionVec_12 (g_io_splitStoreReq_bits_uop_exceptionVec_12),
    .io_splitStoreReq_bits_uop_exceptionVec_13 (g_io_splitStoreReq_bits_uop_exceptionVec_13),
    .io_splitStoreReq_bits_uop_exceptionVec_14 (g_io_splitStoreReq_bits_uop_exceptionVec_14),
    .io_splitStoreReq_bits_uop_exceptionVec_16 (g_io_splitStoreReq_bits_uop_exceptionVec_16),
    .io_splitStoreReq_bits_uop_exceptionVec_17 (g_io_splitStoreReq_bits_uop_exceptionVec_17),
    .io_splitStoreReq_bits_uop_exceptionVec_18 (g_io_splitStoreReq_bits_uop_exceptionVec_18),
    .io_splitStoreReq_bits_uop_exceptionVec_19 (g_io_splitStoreReq_bits_uop_exceptionVec_19),
    .io_splitStoreReq_bits_uop_exceptionVec_20 (g_io_splitStoreReq_bits_uop_exceptionVec_20),
    .io_splitStoreReq_bits_uop_exceptionVec_21 (g_io_splitStoreReq_bits_uop_exceptionVec_21),
    .io_splitStoreReq_bits_uop_exceptionVec_22 (g_io_splitStoreReq_bits_uop_exceptionVec_22),
    .io_splitStoreReq_bits_uop_trigger (g_io_splitStoreReq_bits_uop_trigger),
    .io_splitStoreReq_bits_uop_ftqPtr_flag (g_io_splitStoreReq_bits_uop_ftqPtr_flag),
    .io_splitStoreReq_bits_uop_ftqPtr_value (g_io_splitStoreReq_bits_uop_ftqPtr_value),
    .io_splitStoreReq_bits_uop_ftqOffset (g_io_splitStoreReq_bits_uop_ftqOffset),
    .io_splitStoreReq_bits_uop_fuType (g_io_splitStoreReq_bits_uop_fuType),
    .io_splitStoreReq_bits_uop_fuOpType (g_io_splitStoreReq_bits_uop_fuOpType),
    .io_splitStoreReq_bits_uop_rfWen (g_io_splitStoreReq_bits_uop_rfWen),
    .io_splitStoreReq_bits_uop_vpu_vstart (g_io_splitStoreReq_bits_uop_vpu_vstart),
    .io_splitStoreReq_bits_uop_vpu_nf (g_io_splitStoreReq_bits_uop_vpu_nf),
    .io_splitStoreReq_bits_uop_vpu_veew (g_io_splitStoreReq_bits_uop_vpu_veew),
    .io_splitStoreReq_bits_uop_uopIdx (g_io_splitStoreReq_bits_uop_uopIdx),
    .io_splitStoreReq_bits_uop_pdest (g_io_splitStoreReq_bits_uop_pdest),
    .io_splitStoreReq_bits_uop_robIdx_flag (g_io_splitStoreReq_bits_uop_robIdx_flag),
    .io_splitStoreReq_bits_uop_robIdx_value (g_io_splitStoreReq_bits_uop_robIdx_value),
    .io_splitStoreReq_bits_uop_debugInfo_eliminatedMove (g_io_splitStoreReq_bits_uop_debugInfo_eliminatedMove),
    .io_splitStoreReq_bits_uop_debugInfo_renameTime (g_io_splitStoreReq_bits_uop_debugInfo_renameTime),
    .io_splitStoreReq_bits_uop_debugInfo_dispatchTime (g_io_splitStoreReq_bits_uop_debugInfo_dispatchTime),
    .io_splitStoreReq_bits_uop_debugInfo_enqRsTime (g_io_splitStoreReq_bits_uop_debugInfo_enqRsTime),
    .io_splitStoreReq_bits_uop_debugInfo_selectTime (g_io_splitStoreReq_bits_uop_debugInfo_selectTime),
    .io_splitStoreReq_bits_uop_debugInfo_issueTime (g_io_splitStoreReq_bits_uop_debugInfo_issueTime),
    .io_splitStoreReq_bits_uop_debugInfo_writebackTime (g_io_splitStoreReq_bits_uop_debugInfo_writebackTime),
    .io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id (g_io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime (g_io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime),
    .io_splitStoreReq_bits_uop_debugInfo_tlbRespTime (g_io_splitStoreReq_bits_uop_debugInfo_tlbRespTime),
    .io_splitStoreReq_bits_uop_debug_seqNum_seqNum (g_io_splitStoreReq_bits_uop_debug_seqNum_seqNum),
    .io_splitStoreReq_bits_uop_debug_seqNum_uopIdx (g_io_splitStoreReq_bits_uop_debug_seqNum_uopIdx),
    .io_splitStoreReq_bits_uop_lqIdx_flag (g_io_splitStoreReq_bits_uop_lqIdx_flag),
    .io_splitStoreReq_bits_uop_lqIdx_value (g_io_splitStoreReq_bits_uop_lqIdx_value),
    .io_splitStoreReq_bits_uop_sqIdx_flag (g_io_splitStoreReq_bits_uop_sqIdx_flag),
    .io_splitStoreReq_bits_uop_sqIdx_value (g_io_splitStoreReq_bits_uop_sqIdx_value),
    .io_splitStoreReq_bits_vaddr (g_io_splitStoreReq_bits_vaddr),
    .io_splitStoreReq_bits_mask (g_io_splitStoreReq_bits_mask),
    .io_splitStoreReq_bits_isvec (g_io_splitStoreReq_bits_isvec),
    .io_splitStoreReq_bits_is128bit (g_io_splitStoreReq_bits_is128bit),
    .io_splitStoreReq_bits_isFinalSplit (g_io_splitStoreReq_bits_isFinalSplit),
    .io_writeBack_valid (g_io_writeBack_valid),
    .io_writeBack_bits_uop_exceptionVec_3 (g_io_writeBack_bits_uop_exceptionVec_3),
    .io_writeBack_bits_uop_exceptionVec_6 (g_io_writeBack_bits_uop_exceptionVec_6),
    .io_writeBack_bits_uop_exceptionVec_7 (g_io_writeBack_bits_uop_exceptionVec_7),
    .io_writeBack_bits_uop_exceptionVec_15 (g_io_writeBack_bits_uop_exceptionVec_15),
    .io_writeBack_bits_uop_exceptionVec_19 (g_io_writeBack_bits_uop_exceptionVec_19),
    .io_writeBack_bits_uop_exceptionVec_23 (g_io_writeBack_bits_uop_exceptionVec_23),
    .io_writeBack_bits_uop_trigger (g_io_writeBack_bits_uop_trigger),
    .io_writeBack_bits_uop_rfWen (g_io_writeBack_bits_uop_rfWen),
    .io_writeBack_bits_uop_pdest (g_io_writeBack_bits_uop_pdest),
    .io_writeBack_bits_uop_robIdx_flag (g_io_writeBack_bits_uop_robIdx_flag),
    .io_writeBack_bits_uop_robIdx_value (g_io_writeBack_bits_uop_robIdx_value),
    .io_writeBack_bits_uop_debugInfo_eliminatedMove (g_io_writeBack_bits_uop_debugInfo_eliminatedMove),
    .io_writeBack_bits_uop_debugInfo_renameTime (g_io_writeBack_bits_uop_debugInfo_renameTime),
    .io_writeBack_bits_uop_debugInfo_dispatchTime (g_io_writeBack_bits_uop_debugInfo_dispatchTime),
    .io_writeBack_bits_uop_debugInfo_enqRsTime (g_io_writeBack_bits_uop_debugInfo_enqRsTime),
    .io_writeBack_bits_uop_debugInfo_selectTime (g_io_writeBack_bits_uop_debugInfo_selectTime),
    .io_writeBack_bits_uop_debugInfo_issueTime (g_io_writeBack_bits_uop_debugInfo_issueTime),
    .io_writeBack_bits_uop_debugInfo_writebackTime (g_io_writeBack_bits_uop_debugInfo_writebackTime),
    .io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id (g_io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_writeBack_bits_uop_debugInfo_tlbFirstReqTime (g_io_writeBack_bits_uop_debugInfo_tlbFirstReqTime),
    .io_writeBack_bits_uop_debugInfo_tlbRespTime (g_io_writeBack_bits_uop_debugInfo_tlbRespTime),
    .io_writeBack_bits_uop_debug_seqNum_seqNum (g_io_writeBack_bits_uop_debug_seqNum_seqNum),
    .io_writeBack_bits_uop_debug_seqNum_uopIdx (g_io_writeBack_bits_uop_debug_seqNum_uopIdx),
    .io_writeBack_bits_uop_sqIdx_flag (g_io_writeBack_bits_uop_sqIdx_flag),
    .io_writeBack_bits_uop_sqIdx_value (g_io_writeBack_bits_uop_sqIdx_value),
    .io_writeBack_bits_debug_isMMIO (g_io_writeBack_bits_debug_isMMIO),
    .io_writeBack_bits_debug_isNCIO (g_io_writeBack_bits_debug_isNCIO),
    .io_writeBack_bits_debug_paddr (g_io_writeBack_bits_debug_paddr),
    .io_writeBack_bits_debug_vaddr (g_io_writeBack_bits_debug_vaddr),
    .io_vecWriteBack_0_valid (g_io_vecWriteBack_0_valid),
    .io_vecWriteBack_0_bits_mBIndex (g_io_vecWriteBack_0_bits_mBIndex),
    .io_vecWriteBack_0_bits_exceptionVec_3 (g_io_vecWriteBack_0_bits_exceptionVec_3),
    .io_vecWriteBack_0_bits_exceptionVec_6 (g_io_vecWriteBack_0_bits_exceptionVec_6),
    .io_vecWriteBack_0_bits_exceptionVec_7 (g_io_vecWriteBack_0_bits_exceptionVec_7),
    .io_vecWriteBack_0_bits_exceptionVec_15 (g_io_vecWriteBack_0_bits_exceptionVec_15),
    .io_vecWriteBack_0_bits_exceptionVec_19 (g_io_vecWriteBack_0_bits_exceptionVec_19),
    .io_vecWriteBack_0_bits_exceptionVec_23 (g_io_vecWriteBack_0_bits_exceptionVec_23),
    .io_vecWriteBack_0_bits_hasException (g_io_vecWriteBack_0_bits_hasException),
    .io_vecWriteBack_0_bits_vaddr (g_io_vecWriteBack_0_bits_vaddr),
    .io_vecWriteBack_0_bits_vaNeedExt (g_io_vecWriteBack_0_bits_vaNeedExt),
    .io_vecWriteBack_0_bits_gpaddr (g_io_vecWriteBack_0_bits_gpaddr),
    .io_vecWriteBack_0_bits_isForVSnonLeafPTE (g_io_vecWriteBack_0_bits_isForVSnonLeafPTE),
    .io_vecWriteBack_0_bits_vstart (g_io_vecWriteBack_0_bits_vstart),
    .io_vecWriteBack_0_bits_elemIdx (g_io_vecWriteBack_0_bits_elemIdx),
    .io_vecWriteBack_0_bits_mask (g_io_vecWriteBack_0_bits_mask),
    .io_vecWriteBack_0_bits_splitIndex (g_io_vecWriteBack_0_bits_splitIndex),
    .io_vecWriteBack_1_valid (g_io_vecWriteBack_1_valid),
    .io_vecWriteBack_1_bits_mBIndex (g_io_vecWriteBack_1_bits_mBIndex),
    .io_vecWriteBack_1_bits_exceptionVec_3 (g_io_vecWriteBack_1_bits_exceptionVec_3),
    .io_vecWriteBack_1_bits_exceptionVec_6 (g_io_vecWriteBack_1_bits_exceptionVec_6),
    .io_vecWriteBack_1_bits_exceptionVec_7 (g_io_vecWriteBack_1_bits_exceptionVec_7),
    .io_vecWriteBack_1_bits_exceptionVec_15 (g_io_vecWriteBack_1_bits_exceptionVec_15),
    .io_vecWriteBack_1_bits_exceptionVec_19 (g_io_vecWriteBack_1_bits_exceptionVec_19),
    .io_vecWriteBack_1_bits_exceptionVec_23 (g_io_vecWriteBack_1_bits_exceptionVec_23),
    .io_vecWriteBack_1_bits_hasException (g_io_vecWriteBack_1_bits_hasException),
    .io_vecWriteBack_1_bits_vaddr (g_io_vecWriteBack_1_bits_vaddr),
    .io_vecWriteBack_1_bits_vaNeedExt (g_io_vecWriteBack_1_bits_vaNeedExt),
    .io_vecWriteBack_1_bits_gpaddr (g_io_vecWriteBack_1_bits_gpaddr),
    .io_vecWriteBack_1_bits_isForVSnonLeafPTE (g_io_vecWriteBack_1_bits_isForVSnonLeafPTE),
    .io_vecWriteBack_1_bits_vstart (g_io_vecWriteBack_1_bits_vstart),
    .io_vecWriteBack_1_bits_elemIdx (g_io_vecWriteBack_1_bits_elemIdx),
    .io_vecWriteBack_1_bits_mask (g_io_vecWriteBack_1_bits_mask),
    .io_vecWriteBack_1_bits_splitIndex (g_io_vecWriteBack_1_bits_splitIndex),
    .io_sqControl_toStoreQueue_crossPageWithHit (g_io_sqControl_toStoreQueue_crossPageWithHit),
    .io_sqControl_toStoreQueue_crossPageCanDeq (g_io_sqControl_toStoreQueue_crossPageCanDeq),
    .io_sqControl_toStoreQueue_paddr (g_io_sqControl_toStoreQueue_paddr),
    .io_sqControl_toStoreQueue_withSamePtr (g_io_sqControl_toStoreQueue_withSamePtr),
    .io_toVecSplit_empty (g_io_toVecSplit_empty)
  );

  StoreMisalignBuffer_xs u_i (
    .clock (clock),
    .reset (reset),
    .io_redirect_valid (io_redirect_valid),
    .io_redirect_bits_robIdx_flag (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level (io_redirect_bits_level),
    .io_enq_0_req_valid (io_enq_0_req_valid),
    .io_enq_0_req_bits_uop_exceptionVec_0 (io_enq_0_req_bits_uop_exceptionVec_0),
    .io_enq_0_req_bits_uop_exceptionVec_1 (io_enq_0_req_bits_uop_exceptionVec_1),
    .io_enq_0_req_bits_uop_exceptionVec_2 (io_enq_0_req_bits_uop_exceptionVec_2),
    .io_enq_0_req_bits_uop_exceptionVec_4 (io_enq_0_req_bits_uop_exceptionVec_4),
    .io_enq_0_req_bits_uop_exceptionVec_5 (io_enq_0_req_bits_uop_exceptionVec_5),
    .io_enq_0_req_bits_uop_exceptionVec_8 (io_enq_0_req_bits_uop_exceptionVec_8),
    .io_enq_0_req_bits_uop_exceptionVec_9 (io_enq_0_req_bits_uop_exceptionVec_9),
    .io_enq_0_req_bits_uop_exceptionVec_10 (io_enq_0_req_bits_uop_exceptionVec_10),
    .io_enq_0_req_bits_uop_exceptionVec_11 (io_enq_0_req_bits_uop_exceptionVec_11),
    .io_enq_0_req_bits_uop_exceptionVec_12 (io_enq_0_req_bits_uop_exceptionVec_12),
    .io_enq_0_req_bits_uop_exceptionVec_13 (io_enq_0_req_bits_uop_exceptionVec_13),
    .io_enq_0_req_bits_uop_exceptionVec_14 (io_enq_0_req_bits_uop_exceptionVec_14),
    .io_enq_0_req_bits_uop_exceptionVec_16 (io_enq_0_req_bits_uop_exceptionVec_16),
    .io_enq_0_req_bits_uop_exceptionVec_17 (io_enq_0_req_bits_uop_exceptionVec_17),
    .io_enq_0_req_bits_uop_exceptionVec_18 (io_enq_0_req_bits_uop_exceptionVec_18),
    .io_enq_0_req_bits_uop_exceptionVec_19 (io_enq_0_req_bits_uop_exceptionVec_19),
    .io_enq_0_req_bits_uop_exceptionVec_20 (io_enq_0_req_bits_uop_exceptionVec_20),
    .io_enq_0_req_bits_uop_exceptionVec_21 (io_enq_0_req_bits_uop_exceptionVec_21),
    .io_enq_0_req_bits_uop_exceptionVec_22 (io_enq_0_req_bits_uop_exceptionVec_22),
    .io_enq_0_req_bits_uop_trigger (io_enq_0_req_bits_uop_trigger),
    .io_enq_0_req_bits_uop_ftqPtr_flag (io_enq_0_req_bits_uop_ftqPtr_flag),
    .io_enq_0_req_bits_uop_ftqPtr_value (io_enq_0_req_bits_uop_ftqPtr_value),
    .io_enq_0_req_bits_uop_ftqOffset (io_enq_0_req_bits_uop_ftqOffset),
    .io_enq_0_req_bits_uop_fuType (io_enq_0_req_bits_uop_fuType),
    .io_enq_0_req_bits_uop_fuOpType (io_enq_0_req_bits_uop_fuOpType),
    .io_enq_0_req_bits_uop_rfWen (io_enq_0_req_bits_uop_rfWen),
    .io_enq_0_req_bits_uop_vpu_vstart (io_enq_0_req_bits_uop_vpu_vstart),
    .io_enq_0_req_bits_uop_vpu_nf (io_enq_0_req_bits_uop_vpu_nf),
    .io_enq_0_req_bits_uop_vpu_veew (io_enq_0_req_bits_uop_vpu_veew),
    .io_enq_0_req_bits_uop_uopIdx (io_enq_0_req_bits_uop_uopIdx),
    .io_enq_0_req_bits_uop_pdest (io_enq_0_req_bits_uop_pdest),
    .io_enq_0_req_bits_uop_robIdx_flag (io_enq_0_req_bits_uop_robIdx_flag),
    .io_enq_0_req_bits_uop_robIdx_value (io_enq_0_req_bits_uop_robIdx_value),
    .io_enq_0_req_bits_uop_debugInfo_eliminatedMove (io_enq_0_req_bits_uop_debugInfo_eliminatedMove),
    .io_enq_0_req_bits_uop_debugInfo_renameTime (io_enq_0_req_bits_uop_debugInfo_renameTime),
    .io_enq_0_req_bits_uop_debugInfo_dispatchTime (io_enq_0_req_bits_uop_debugInfo_dispatchTime),
    .io_enq_0_req_bits_uop_debugInfo_enqRsTime (io_enq_0_req_bits_uop_debugInfo_enqRsTime),
    .io_enq_0_req_bits_uop_debugInfo_selectTime (io_enq_0_req_bits_uop_debugInfo_selectTime),
    .io_enq_0_req_bits_uop_debugInfo_issueTime (io_enq_0_req_bits_uop_debugInfo_issueTime),
    .io_enq_0_req_bits_uop_debugInfo_writebackTime (io_enq_0_req_bits_uop_debugInfo_writebackTime),
    .io_enq_0_req_bits_uop_debugInfo_runahead_checkpoint_id (io_enq_0_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_enq_0_req_bits_uop_debugInfo_tlbFirstReqTime (io_enq_0_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_enq_0_req_bits_uop_debugInfo_tlbRespTime (io_enq_0_req_bits_uop_debugInfo_tlbRespTime),
    .io_enq_0_req_bits_uop_debug_seqNum_seqNum (io_enq_0_req_bits_uop_debug_seqNum_seqNum),
    .io_enq_0_req_bits_uop_debug_seqNum_uopIdx (io_enq_0_req_bits_uop_debug_seqNum_uopIdx),
    .io_enq_0_req_bits_uop_lqIdx_flag (io_enq_0_req_bits_uop_lqIdx_flag),
    .io_enq_0_req_bits_uop_lqIdx_value (io_enq_0_req_bits_uop_lqIdx_value),
    .io_enq_0_req_bits_uop_sqIdx_flag (io_enq_0_req_bits_uop_sqIdx_flag),
    .io_enq_0_req_bits_uop_sqIdx_value (io_enq_0_req_bits_uop_sqIdx_value),
    .io_enq_0_req_bits_vaddr (io_enq_0_req_bits_vaddr),
    .io_enq_0_req_bits_mask (io_enq_0_req_bits_mask),
    .io_enq_0_req_bits_isvec (io_enq_0_req_bits_isvec),
    .io_enq_0_req_bits_elemIdx (io_enq_0_req_bits_elemIdx),
    .io_enq_0_req_bits_alignedType (io_enq_0_req_bits_alignedType),
    .io_enq_0_req_bits_mbIndex (io_enq_0_req_bits_mbIndex),
    .io_enq_0_req_bits_splitIndex (io_enq_0_req_bits_splitIndex),
    .io_enq_0_revoke (io_enq_0_revoke),
    .io_enq_1_req_valid (io_enq_1_req_valid),
    .io_enq_1_req_bits_uop_exceptionVec_0 (io_enq_1_req_bits_uop_exceptionVec_0),
    .io_enq_1_req_bits_uop_exceptionVec_1 (io_enq_1_req_bits_uop_exceptionVec_1),
    .io_enq_1_req_bits_uop_exceptionVec_2 (io_enq_1_req_bits_uop_exceptionVec_2),
    .io_enq_1_req_bits_uop_exceptionVec_4 (io_enq_1_req_bits_uop_exceptionVec_4),
    .io_enq_1_req_bits_uop_exceptionVec_5 (io_enq_1_req_bits_uop_exceptionVec_5),
    .io_enq_1_req_bits_uop_exceptionVec_8 (io_enq_1_req_bits_uop_exceptionVec_8),
    .io_enq_1_req_bits_uop_exceptionVec_9 (io_enq_1_req_bits_uop_exceptionVec_9),
    .io_enq_1_req_bits_uop_exceptionVec_10 (io_enq_1_req_bits_uop_exceptionVec_10),
    .io_enq_1_req_bits_uop_exceptionVec_11 (io_enq_1_req_bits_uop_exceptionVec_11),
    .io_enq_1_req_bits_uop_exceptionVec_12 (io_enq_1_req_bits_uop_exceptionVec_12),
    .io_enq_1_req_bits_uop_exceptionVec_13 (io_enq_1_req_bits_uop_exceptionVec_13),
    .io_enq_1_req_bits_uop_exceptionVec_14 (io_enq_1_req_bits_uop_exceptionVec_14),
    .io_enq_1_req_bits_uop_exceptionVec_16 (io_enq_1_req_bits_uop_exceptionVec_16),
    .io_enq_1_req_bits_uop_exceptionVec_17 (io_enq_1_req_bits_uop_exceptionVec_17),
    .io_enq_1_req_bits_uop_exceptionVec_18 (io_enq_1_req_bits_uop_exceptionVec_18),
    .io_enq_1_req_bits_uop_exceptionVec_19 (io_enq_1_req_bits_uop_exceptionVec_19),
    .io_enq_1_req_bits_uop_exceptionVec_20 (io_enq_1_req_bits_uop_exceptionVec_20),
    .io_enq_1_req_bits_uop_exceptionVec_21 (io_enq_1_req_bits_uop_exceptionVec_21),
    .io_enq_1_req_bits_uop_exceptionVec_22 (io_enq_1_req_bits_uop_exceptionVec_22),
    .io_enq_1_req_bits_uop_trigger (io_enq_1_req_bits_uop_trigger),
    .io_enq_1_req_bits_uop_ftqPtr_flag (io_enq_1_req_bits_uop_ftqPtr_flag),
    .io_enq_1_req_bits_uop_ftqPtr_value (io_enq_1_req_bits_uop_ftqPtr_value),
    .io_enq_1_req_bits_uop_ftqOffset (io_enq_1_req_bits_uop_ftqOffset),
    .io_enq_1_req_bits_uop_fuType (io_enq_1_req_bits_uop_fuType),
    .io_enq_1_req_bits_uop_fuOpType (io_enq_1_req_bits_uop_fuOpType),
    .io_enq_1_req_bits_uop_rfWen (io_enq_1_req_bits_uop_rfWen),
    .io_enq_1_req_bits_uop_vpu_vstart (io_enq_1_req_bits_uop_vpu_vstart),
    .io_enq_1_req_bits_uop_vpu_nf (io_enq_1_req_bits_uop_vpu_nf),
    .io_enq_1_req_bits_uop_vpu_veew (io_enq_1_req_bits_uop_vpu_veew),
    .io_enq_1_req_bits_uop_uopIdx (io_enq_1_req_bits_uop_uopIdx),
    .io_enq_1_req_bits_uop_pdest (io_enq_1_req_bits_uop_pdest),
    .io_enq_1_req_bits_uop_robIdx_flag (io_enq_1_req_bits_uop_robIdx_flag),
    .io_enq_1_req_bits_uop_robIdx_value (io_enq_1_req_bits_uop_robIdx_value),
    .io_enq_1_req_bits_uop_debugInfo_eliminatedMove (io_enq_1_req_bits_uop_debugInfo_eliminatedMove),
    .io_enq_1_req_bits_uop_debugInfo_renameTime (io_enq_1_req_bits_uop_debugInfo_renameTime),
    .io_enq_1_req_bits_uop_debugInfo_dispatchTime (io_enq_1_req_bits_uop_debugInfo_dispatchTime),
    .io_enq_1_req_bits_uop_debugInfo_enqRsTime (io_enq_1_req_bits_uop_debugInfo_enqRsTime),
    .io_enq_1_req_bits_uop_debugInfo_selectTime (io_enq_1_req_bits_uop_debugInfo_selectTime),
    .io_enq_1_req_bits_uop_debugInfo_issueTime (io_enq_1_req_bits_uop_debugInfo_issueTime),
    .io_enq_1_req_bits_uop_debugInfo_writebackTime (io_enq_1_req_bits_uop_debugInfo_writebackTime),
    .io_enq_1_req_bits_uop_debugInfo_runahead_checkpoint_id (io_enq_1_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_enq_1_req_bits_uop_debugInfo_tlbFirstReqTime (io_enq_1_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_enq_1_req_bits_uop_debugInfo_tlbRespTime (io_enq_1_req_bits_uop_debugInfo_tlbRespTime),
    .io_enq_1_req_bits_uop_debug_seqNum_seqNum (io_enq_1_req_bits_uop_debug_seqNum_seqNum),
    .io_enq_1_req_bits_uop_debug_seqNum_uopIdx (io_enq_1_req_bits_uop_debug_seqNum_uopIdx),
    .io_enq_1_req_bits_uop_lqIdx_flag (io_enq_1_req_bits_uop_lqIdx_flag),
    .io_enq_1_req_bits_uop_lqIdx_value (io_enq_1_req_bits_uop_lqIdx_value),
    .io_enq_1_req_bits_uop_sqIdx_flag (io_enq_1_req_bits_uop_sqIdx_flag),
    .io_enq_1_req_bits_uop_sqIdx_value (io_enq_1_req_bits_uop_sqIdx_value),
    .io_enq_1_req_bits_vaddr (io_enq_1_req_bits_vaddr),
    .io_enq_1_req_bits_mask (io_enq_1_req_bits_mask),
    .io_enq_1_req_bits_isvec (io_enq_1_req_bits_isvec),
    .io_enq_1_req_bits_elemIdx (io_enq_1_req_bits_elemIdx),
    .io_enq_1_req_bits_alignedType (io_enq_1_req_bits_alignedType),
    .io_enq_1_req_bits_mbIndex (io_enq_1_req_bits_mbIndex),
    .io_enq_1_req_bits_splitIndex (io_enq_1_req_bits_splitIndex),
    .io_enq_1_revoke (io_enq_1_revoke),
    .io_rob_pendingst (io_rob_pendingst),
    .io_rob_pendingPtr_flag (io_rob_pendingPtr_flag),
    .io_rob_pendingPtr_value (io_rob_pendingPtr_value),
    .io_splitStoreReq_ready (io_splitStoreReq_ready),
    .io_splitStoreResp_valid (io_splitStoreResp_valid),
    .io_splitStoreResp_bits_uop_exceptionVec_3 (io_splitStoreResp_bits_uop_exceptionVec_3),
    .io_splitStoreResp_bits_uop_exceptionVec_6 (io_splitStoreResp_bits_uop_exceptionVec_6),
    .io_splitStoreResp_bits_uop_exceptionVec_7 (io_splitStoreResp_bits_uop_exceptionVec_7),
    .io_splitStoreResp_bits_uop_exceptionVec_15 (io_splitStoreResp_bits_uop_exceptionVec_15),
    .io_splitStoreResp_bits_uop_exceptionVec_19 (io_splitStoreResp_bits_uop_exceptionVec_19),
    .io_splitStoreResp_bits_uop_exceptionVec_23 (io_splitStoreResp_bits_uop_exceptionVec_23),
    .io_splitStoreResp_bits_uop_trigger (io_splitStoreResp_bits_uop_trigger),
    .io_splitStoreResp_bits_uop_robIdx_flag (io_splitStoreResp_bits_uop_robIdx_flag),
    .io_splitStoreResp_bits_uop_robIdx_value (io_splitStoreResp_bits_uop_robIdx_value),
    .io_splitStoreResp_bits_vaddr (io_splitStoreResp_bits_vaddr),
    .io_splitStoreResp_bits_vaNeedExt (io_splitStoreResp_bits_vaNeedExt),
    .io_splitStoreResp_bits_paddr (io_splitStoreResp_bits_paddr),
    .io_splitStoreResp_bits_gpaddr (io_splitStoreResp_bits_gpaddr),
    .io_splitStoreResp_bits_nc (io_splitStoreResp_bits_nc),
    .io_splitStoreResp_bits_mmio (io_splitStoreResp_bits_mmio),
    .io_splitStoreResp_bits_memBackTypeMM (io_splitStoreResp_bits_memBackTypeMM),
    .io_splitStoreResp_bits_isForVSnonLeafPTE (io_splitStoreResp_bits_isForVSnonLeafPTE),
    .io_splitStoreResp_bits_vecActive (io_splitStoreResp_bits_vecActive),
    .io_splitStoreResp_bits_need_rep (io_splitStoreResp_bits_need_rep),
    .io_writeBack_ready (io_writeBack_ready),
    .io_storeOutValid (io_storeOutValid),
    .io_storeVecOutValid (io_storeVecOutValid),
    .io_sqControl_toStoreMisalignBuffer_sqPtr_flag (io_sqControl_toStoreMisalignBuffer_sqPtr_flag),
    .io_sqControl_toStoreMisalignBuffer_sqPtr_value (io_sqControl_toStoreMisalignBuffer_sqPtr_value),
    .io_sqControl_toStoreMisalignBuffer_doDeq (io_sqControl_toStoreMisalignBuffer_doDeq),
    .io_sqControl_toStoreMisalignBuffer_uop_uopIdx (io_sqControl_toStoreMisalignBuffer_uop_uopIdx),
    .io_sqControl_toStoreMisalignBuffer_uop_robIdx_flag (io_sqControl_toStoreMisalignBuffer_uop_robIdx_flag),
    .io_sqControl_toStoreMisalignBuffer_uop_robIdx_value (io_sqControl_toStoreMisalignBuffer_uop_robIdx_value),
    .io_enq_0_req_ready (i_io_enq_0_req_ready),
    .io_enq_1_req_ready (i_io_enq_1_req_ready),
    .io_splitStoreReq_valid (i_io_splitStoreReq_valid),
    .io_splitStoreReq_bits_uop_exceptionVec_0 (i_io_splitStoreReq_bits_uop_exceptionVec_0),
    .io_splitStoreReq_bits_uop_exceptionVec_1 (i_io_splitStoreReq_bits_uop_exceptionVec_1),
    .io_splitStoreReq_bits_uop_exceptionVec_2 (i_io_splitStoreReq_bits_uop_exceptionVec_2),
    .io_splitStoreReq_bits_uop_exceptionVec_4 (i_io_splitStoreReq_bits_uop_exceptionVec_4),
    .io_splitStoreReq_bits_uop_exceptionVec_5 (i_io_splitStoreReq_bits_uop_exceptionVec_5),
    .io_splitStoreReq_bits_uop_exceptionVec_8 (i_io_splitStoreReq_bits_uop_exceptionVec_8),
    .io_splitStoreReq_bits_uop_exceptionVec_9 (i_io_splitStoreReq_bits_uop_exceptionVec_9),
    .io_splitStoreReq_bits_uop_exceptionVec_10 (i_io_splitStoreReq_bits_uop_exceptionVec_10),
    .io_splitStoreReq_bits_uop_exceptionVec_11 (i_io_splitStoreReq_bits_uop_exceptionVec_11),
    .io_splitStoreReq_bits_uop_exceptionVec_12 (i_io_splitStoreReq_bits_uop_exceptionVec_12),
    .io_splitStoreReq_bits_uop_exceptionVec_13 (i_io_splitStoreReq_bits_uop_exceptionVec_13),
    .io_splitStoreReq_bits_uop_exceptionVec_14 (i_io_splitStoreReq_bits_uop_exceptionVec_14),
    .io_splitStoreReq_bits_uop_exceptionVec_16 (i_io_splitStoreReq_bits_uop_exceptionVec_16),
    .io_splitStoreReq_bits_uop_exceptionVec_17 (i_io_splitStoreReq_bits_uop_exceptionVec_17),
    .io_splitStoreReq_bits_uop_exceptionVec_18 (i_io_splitStoreReq_bits_uop_exceptionVec_18),
    .io_splitStoreReq_bits_uop_exceptionVec_19 (i_io_splitStoreReq_bits_uop_exceptionVec_19),
    .io_splitStoreReq_bits_uop_exceptionVec_20 (i_io_splitStoreReq_bits_uop_exceptionVec_20),
    .io_splitStoreReq_bits_uop_exceptionVec_21 (i_io_splitStoreReq_bits_uop_exceptionVec_21),
    .io_splitStoreReq_bits_uop_exceptionVec_22 (i_io_splitStoreReq_bits_uop_exceptionVec_22),
    .io_splitStoreReq_bits_uop_trigger (i_io_splitStoreReq_bits_uop_trigger),
    .io_splitStoreReq_bits_uop_ftqPtr_flag (i_io_splitStoreReq_bits_uop_ftqPtr_flag),
    .io_splitStoreReq_bits_uop_ftqPtr_value (i_io_splitStoreReq_bits_uop_ftqPtr_value),
    .io_splitStoreReq_bits_uop_ftqOffset (i_io_splitStoreReq_bits_uop_ftqOffset),
    .io_splitStoreReq_bits_uop_fuType (i_io_splitStoreReq_bits_uop_fuType),
    .io_splitStoreReq_bits_uop_fuOpType (i_io_splitStoreReq_bits_uop_fuOpType),
    .io_splitStoreReq_bits_uop_rfWen (i_io_splitStoreReq_bits_uop_rfWen),
    .io_splitStoreReq_bits_uop_vpu_vstart (i_io_splitStoreReq_bits_uop_vpu_vstart),
    .io_splitStoreReq_bits_uop_vpu_nf (i_io_splitStoreReq_bits_uop_vpu_nf),
    .io_splitStoreReq_bits_uop_vpu_veew (i_io_splitStoreReq_bits_uop_vpu_veew),
    .io_splitStoreReq_bits_uop_uopIdx (i_io_splitStoreReq_bits_uop_uopIdx),
    .io_splitStoreReq_bits_uop_pdest (i_io_splitStoreReq_bits_uop_pdest),
    .io_splitStoreReq_bits_uop_robIdx_flag (i_io_splitStoreReq_bits_uop_robIdx_flag),
    .io_splitStoreReq_bits_uop_robIdx_value (i_io_splitStoreReq_bits_uop_robIdx_value),
    .io_splitStoreReq_bits_uop_debugInfo_eliminatedMove (i_io_splitStoreReq_bits_uop_debugInfo_eliminatedMove),
    .io_splitStoreReq_bits_uop_debugInfo_renameTime (i_io_splitStoreReq_bits_uop_debugInfo_renameTime),
    .io_splitStoreReq_bits_uop_debugInfo_dispatchTime (i_io_splitStoreReq_bits_uop_debugInfo_dispatchTime),
    .io_splitStoreReq_bits_uop_debugInfo_enqRsTime (i_io_splitStoreReq_bits_uop_debugInfo_enqRsTime),
    .io_splitStoreReq_bits_uop_debugInfo_selectTime (i_io_splitStoreReq_bits_uop_debugInfo_selectTime),
    .io_splitStoreReq_bits_uop_debugInfo_issueTime (i_io_splitStoreReq_bits_uop_debugInfo_issueTime),
    .io_splitStoreReq_bits_uop_debugInfo_writebackTime (i_io_splitStoreReq_bits_uop_debugInfo_writebackTime),
    .io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id (i_io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime (i_io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime),
    .io_splitStoreReq_bits_uop_debugInfo_tlbRespTime (i_io_splitStoreReq_bits_uop_debugInfo_tlbRespTime),
    .io_splitStoreReq_bits_uop_debug_seqNum_seqNum (i_io_splitStoreReq_bits_uop_debug_seqNum_seqNum),
    .io_splitStoreReq_bits_uop_debug_seqNum_uopIdx (i_io_splitStoreReq_bits_uop_debug_seqNum_uopIdx),
    .io_splitStoreReq_bits_uop_lqIdx_flag (i_io_splitStoreReq_bits_uop_lqIdx_flag),
    .io_splitStoreReq_bits_uop_lqIdx_value (i_io_splitStoreReq_bits_uop_lqIdx_value),
    .io_splitStoreReq_bits_uop_sqIdx_flag (i_io_splitStoreReq_bits_uop_sqIdx_flag),
    .io_splitStoreReq_bits_uop_sqIdx_value (i_io_splitStoreReq_bits_uop_sqIdx_value),
    .io_splitStoreReq_bits_vaddr (i_io_splitStoreReq_bits_vaddr),
    .io_splitStoreReq_bits_mask (i_io_splitStoreReq_bits_mask),
    .io_splitStoreReq_bits_isvec (i_io_splitStoreReq_bits_isvec),
    .io_splitStoreReq_bits_is128bit (i_io_splitStoreReq_bits_is128bit),
    .io_splitStoreReq_bits_isFinalSplit (i_io_splitStoreReq_bits_isFinalSplit),
    .io_writeBack_valid (i_io_writeBack_valid),
    .io_writeBack_bits_uop_exceptionVec_3 (i_io_writeBack_bits_uop_exceptionVec_3),
    .io_writeBack_bits_uop_exceptionVec_6 (i_io_writeBack_bits_uop_exceptionVec_6),
    .io_writeBack_bits_uop_exceptionVec_7 (i_io_writeBack_bits_uop_exceptionVec_7),
    .io_writeBack_bits_uop_exceptionVec_15 (i_io_writeBack_bits_uop_exceptionVec_15),
    .io_writeBack_bits_uop_exceptionVec_19 (i_io_writeBack_bits_uop_exceptionVec_19),
    .io_writeBack_bits_uop_exceptionVec_23 (i_io_writeBack_bits_uop_exceptionVec_23),
    .io_writeBack_bits_uop_trigger (i_io_writeBack_bits_uop_trigger),
    .io_writeBack_bits_uop_rfWen (i_io_writeBack_bits_uop_rfWen),
    .io_writeBack_bits_uop_pdest (i_io_writeBack_bits_uop_pdest),
    .io_writeBack_bits_uop_robIdx_flag (i_io_writeBack_bits_uop_robIdx_flag),
    .io_writeBack_bits_uop_robIdx_value (i_io_writeBack_bits_uop_robIdx_value),
    .io_writeBack_bits_uop_debugInfo_eliminatedMove (i_io_writeBack_bits_uop_debugInfo_eliminatedMove),
    .io_writeBack_bits_uop_debugInfo_renameTime (i_io_writeBack_bits_uop_debugInfo_renameTime),
    .io_writeBack_bits_uop_debugInfo_dispatchTime (i_io_writeBack_bits_uop_debugInfo_dispatchTime),
    .io_writeBack_bits_uop_debugInfo_enqRsTime (i_io_writeBack_bits_uop_debugInfo_enqRsTime),
    .io_writeBack_bits_uop_debugInfo_selectTime (i_io_writeBack_bits_uop_debugInfo_selectTime),
    .io_writeBack_bits_uop_debugInfo_issueTime (i_io_writeBack_bits_uop_debugInfo_issueTime),
    .io_writeBack_bits_uop_debugInfo_writebackTime (i_io_writeBack_bits_uop_debugInfo_writebackTime),
    .io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id (i_io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_writeBack_bits_uop_debugInfo_tlbFirstReqTime (i_io_writeBack_bits_uop_debugInfo_tlbFirstReqTime),
    .io_writeBack_bits_uop_debugInfo_tlbRespTime (i_io_writeBack_bits_uop_debugInfo_tlbRespTime),
    .io_writeBack_bits_uop_debug_seqNum_seqNum (i_io_writeBack_bits_uop_debug_seqNum_seqNum),
    .io_writeBack_bits_uop_debug_seqNum_uopIdx (i_io_writeBack_bits_uop_debug_seqNum_uopIdx),
    .io_writeBack_bits_uop_sqIdx_flag (i_io_writeBack_bits_uop_sqIdx_flag),
    .io_writeBack_bits_uop_sqIdx_value (i_io_writeBack_bits_uop_sqIdx_value),
    .io_writeBack_bits_debug_isMMIO (i_io_writeBack_bits_debug_isMMIO),
    .io_writeBack_bits_debug_isNCIO (i_io_writeBack_bits_debug_isNCIO),
    .io_writeBack_bits_debug_paddr (i_io_writeBack_bits_debug_paddr),
    .io_writeBack_bits_debug_vaddr (i_io_writeBack_bits_debug_vaddr),
    .io_vecWriteBack_0_valid (i_io_vecWriteBack_0_valid),
    .io_vecWriteBack_0_bits_mBIndex (i_io_vecWriteBack_0_bits_mBIndex),
    .io_vecWriteBack_0_bits_exceptionVec_3 (i_io_vecWriteBack_0_bits_exceptionVec_3),
    .io_vecWriteBack_0_bits_exceptionVec_6 (i_io_vecWriteBack_0_bits_exceptionVec_6),
    .io_vecWriteBack_0_bits_exceptionVec_7 (i_io_vecWriteBack_0_bits_exceptionVec_7),
    .io_vecWriteBack_0_bits_exceptionVec_15 (i_io_vecWriteBack_0_bits_exceptionVec_15),
    .io_vecWriteBack_0_bits_exceptionVec_19 (i_io_vecWriteBack_0_bits_exceptionVec_19),
    .io_vecWriteBack_0_bits_exceptionVec_23 (i_io_vecWriteBack_0_bits_exceptionVec_23),
    .io_vecWriteBack_0_bits_hasException (i_io_vecWriteBack_0_bits_hasException),
    .io_vecWriteBack_0_bits_vaddr (i_io_vecWriteBack_0_bits_vaddr),
    .io_vecWriteBack_0_bits_vaNeedExt (i_io_vecWriteBack_0_bits_vaNeedExt),
    .io_vecWriteBack_0_bits_gpaddr (i_io_vecWriteBack_0_bits_gpaddr),
    .io_vecWriteBack_0_bits_isForVSnonLeafPTE (i_io_vecWriteBack_0_bits_isForVSnonLeafPTE),
    .io_vecWriteBack_0_bits_vstart (i_io_vecWriteBack_0_bits_vstart),
    .io_vecWriteBack_0_bits_elemIdx (i_io_vecWriteBack_0_bits_elemIdx),
    .io_vecWriteBack_0_bits_mask (i_io_vecWriteBack_0_bits_mask),
    .io_vecWriteBack_0_bits_splitIndex (i_io_vecWriteBack_0_bits_splitIndex),
    .io_vecWriteBack_1_valid (i_io_vecWriteBack_1_valid),
    .io_vecWriteBack_1_bits_mBIndex (i_io_vecWriteBack_1_bits_mBIndex),
    .io_vecWriteBack_1_bits_exceptionVec_3 (i_io_vecWriteBack_1_bits_exceptionVec_3),
    .io_vecWriteBack_1_bits_exceptionVec_6 (i_io_vecWriteBack_1_bits_exceptionVec_6),
    .io_vecWriteBack_1_bits_exceptionVec_7 (i_io_vecWriteBack_1_bits_exceptionVec_7),
    .io_vecWriteBack_1_bits_exceptionVec_15 (i_io_vecWriteBack_1_bits_exceptionVec_15),
    .io_vecWriteBack_1_bits_exceptionVec_19 (i_io_vecWriteBack_1_bits_exceptionVec_19),
    .io_vecWriteBack_1_bits_exceptionVec_23 (i_io_vecWriteBack_1_bits_exceptionVec_23),
    .io_vecWriteBack_1_bits_hasException (i_io_vecWriteBack_1_bits_hasException),
    .io_vecWriteBack_1_bits_vaddr (i_io_vecWriteBack_1_bits_vaddr),
    .io_vecWriteBack_1_bits_vaNeedExt (i_io_vecWriteBack_1_bits_vaNeedExt),
    .io_vecWriteBack_1_bits_gpaddr (i_io_vecWriteBack_1_bits_gpaddr),
    .io_vecWriteBack_1_bits_isForVSnonLeafPTE (i_io_vecWriteBack_1_bits_isForVSnonLeafPTE),
    .io_vecWriteBack_1_bits_vstart (i_io_vecWriteBack_1_bits_vstart),
    .io_vecWriteBack_1_bits_elemIdx (i_io_vecWriteBack_1_bits_elemIdx),
    .io_vecWriteBack_1_bits_mask (i_io_vecWriteBack_1_bits_mask),
    .io_vecWriteBack_1_bits_splitIndex (i_io_vecWriteBack_1_bits_splitIndex),
    .io_sqControl_toStoreQueue_crossPageWithHit (i_io_sqControl_toStoreQueue_crossPageWithHit),
    .io_sqControl_toStoreQueue_crossPageCanDeq (i_io_sqControl_toStoreQueue_crossPageCanDeq),
    .io_sqControl_toStoreQueue_paddr (i_io_sqControl_toStoreQueue_paddr),
    .io_sqControl_toStoreQueue_withSamePtr (i_io_sqControl_toStoreQueue_withSamePtr),
    .io_toVecSplit_empty (i_io_toVecSplit_empty)
  );

  task automatic randomize_all_inputs();
    io_redirect_valid = 1'($urandom);
    io_redirect_bits_robIdx_flag = 1'($urandom);
    io_redirect_bits_robIdx_value = 8'($urandom);
    io_redirect_bits_level = 1'($urandom);
    io_enq_0_req_valid = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_0 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_1 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_2 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_4 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_5 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_8 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_9 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_10 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_11 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_12 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_13 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_14 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_16 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_17 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_18 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_19 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_20 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_21 = 1'($urandom);
    io_enq_0_req_bits_uop_exceptionVec_22 = 1'($urandom);
    io_enq_0_req_bits_uop_trigger = 4'($urandom);
    io_enq_0_req_bits_uop_ftqPtr_flag = 1'($urandom);
    io_enq_0_req_bits_uop_ftqPtr_value = 6'($urandom);
    io_enq_0_req_bits_uop_ftqOffset = 4'($urandom);
    io_enq_0_req_bits_uop_fuType = 35'({$urandom, $urandom});
    io_enq_0_req_bits_uop_fuOpType = 9'($urandom);
    io_enq_0_req_bits_uop_rfWen = 1'($urandom);
    io_enq_0_req_bits_uop_vpu_vstart = 8'($urandom);
    io_enq_0_req_bits_uop_vpu_nf = 3'($urandom);
    io_enq_0_req_bits_uop_vpu_veew = 2'($urandom);
    io_enq_0_req_bits_uop_uopIdx = 7'($urandom);
    io_enq_0_req_bits_uop_pdest = 8'($urandom);
    io_enq_0_req_bits_uop_robIdx_flag = 1'($urandom);
    io_enq_0_req_bits_uop_robIdx_value = 8'($urandom);
    io_enq_0_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
    io_enq_0_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_enq_0_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
    io_enq_0_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
    io_enq_0_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
    io_enq_0_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
    io_enq_0_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
    io_enq_0_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    io_enq_0_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    io_enq_0_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
    io_enq_0_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_enq_0_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
    io_enq_0_req_bits_uop_lqIdx_flag = 1'($urandom);
    io_enq_0_req_bits_uop_lqIdx_value = 7'($urandom);
    io_enq_0_req_bits_uop_sqIdx_flag = 1'($urandom);
    io_enq_0_req_bits_uop_sqIdx_value = 6'($urandom);
    io_enq_0_req_bits_vaddr = 50'({$urandom, $urandom});
    io_enq_0_req_bits_mask = 16'($urandom);
    io_enq_0_req_bits_isvec = 1'($urandom);
    io_enq_0_req_bits_elemIdx = 8'($urandom);
    io_enq_0_req_bits_alignedType = 3'($urandom);
    io_enq_0_req_bits_mbIndex = 4'($urandom);
    io_enq_0_req_bits_splitIndex = 5'($urandom);
    io_enq_0_revoke = 1'($urandom);
    io_enq_1_req_valid = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_0 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_1 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_2 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_4 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_5 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_8 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_9 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_10 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_11 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_12 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_13 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_14 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_16 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_17 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_18 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_19 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_20 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_21 = 1'($urandom);
    io_enq_1_req_bits_uop_exceptionVec_22 = 1'($urandom);
    io_enq_1_req_bits_uop_trigger = 4'($urandom);
    io_enq_1_req_bits_uop_ftqPtr_flag = 1'($urandom);
    io_enq_1_req_bits_uop_ftqPtr_value = 6'($urandom);
    io_enq_1_req_bits_uop_ftqOffset = 4'($urandom);
    io_enq_1_req_bits_uop_fuType = 35'({$urandom, $urandom});
    io_enq_1_req_bits_uop_fuOpType = 9'($urandom);
    io_enq_1_req_bits_uop_rfWen = 1'($urandom);
    io_enq_1_req_bits_uop_vpu_vstart = 8'($urandom);
    io_enq_1_req_bits_uop_vpu_nf = 3'($urandom);
    io_enq_1_req_bits_uop_vpu_veew = 2'($urandom);
    io_enq_1_req_bits_uop_uopIdx = 7'($urandom);
    io_enq_1_req_bits_uop_pdest = 8'($urandom);
    io_enq_1_req_bits_uop_robIdx_flag = 1'($urandom);
    io_enq_1_req_bits_uop_robIdx_value = 8'($urandom);
    io_enq_1_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
    io_enq_1_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_enq_1_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
    io_enq_1_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
    io_enq_1_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
    io_enq_1_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
    io_enq_1_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
    io_enq_1_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    io_enq_1_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    io_enq_1_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
    io_enq_1_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_enq_1_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
    io_enq_1_req_bits_uop_lqIdx_flag = 1'($urandom);
    io_enq_1_req_bits_uop_lqIdx_value = 7'($urandom);
    io_enq_1_req_bits_uop_sqIdx_flag = 1'($urandom);
    io_enq_1_req_bits_uop_sqIdx_value = 6'($urandom);
    io_enq_1_req_bits_vaddr = 50'({$urandom, $urandom});
    io_enq_1_req_bits_mask = 16'($urandom);
    io_enq_1_req_bits_isvec = 1'($urandom);
    io_enq_1_req_bits_elemIdx = 8'($urandom);
    io_enq_1_req_bits_alignedType = 3'($urandom);
    io_enq_1_req_bits_mbIndex = 4'($urandom);
    io_enq_1_req_bits_splitIndex = 5'($urandom);
    io_enq_1_revoke = 1'($urandom);
    io_rob_pendingst = 1'($urandom);
    io_rob_pendingPtr_flag = 1'($urandom);
    io_rob_pendingPtr_value = 8'($urandom);
    io_splitStoreReq_ready = 1'($urandom);
    io_splitStoreResp_valid = 1'($urandom);
    io_splitStoreResp_bits_uop_exceptionVec_3 = 1'($urandom);
    io_splitStoreResp_bits_uop_exceptionVec_6 = 1'($urandom);
    io_splitStoreResp_bits_uop_exceptionVec_7 = 1'($urandom);
    io_splitStoreResp_bits_uop_exceptionVec_15 = 1'($urandom);
    io_splitStoreResp_bits_uop_exceptionVec_19 = 1'($urandom);
    io_splitStoreResp_bits_uop_exceptionVec_23 = 1'($urandom);
    io_splitStoreResp_bits_uop_trigger = 4'($urandom);
    io_splitStoreResp_bits_uop_robIdx_flag = 1'($urandom);
    io_splitStoreResp_bits_uop_robIdx_value = 8'($urandom);
    io_splitStoreResp_bits_vaddr = 50'({$urandom, $urandom});
    io_splitStoreResp_bits_vaNeedExt = 1'($urandom);
    io_splitStoreResp_bits_paddr = 48'({$urandom, $urandom});
    io_splitStoreResp_bits_gpaddr = 64'({$urandom, $urandom});
    io_splitStoreResp_bits_nc = 1'($urandom);
    io_splitStoreResp_bits_mmio = 1'($urandom);
    io_splitStoreResp_bits_memBackTypeMM = 1'($urandom);
    io_splitStoreResp_bits_isForVSnonLeafPTE = 1'($urandom);
    io_splitStoreResp_bits_vecActive = 1'($urandom);
    io_splitStoreResp_bits_need_rep = 1'($urandom);
    io_writeBack_ready = 1'($urandom);
    io_storeOutValid = 1'($urandom);
    io_storeVecOutValid = 1'($urandom);
    io_sqControl_toStoreMisalignBuffer_sqPtr_flag = 1'($urandom);
    io_sqControl_toStoreMisalignBuffer_sqPtr_value = 6'($urandom);
    io_sqControl_toStoreMisalignBuffer_doDeq = 1'($urandom);
    io_sqControl_toStoreMisalignBuffer_uop_uopIdx = 7'($urandom);
    io_sqControl_toStoreMisalignBuffer_uop_robIdx_flag = 1'($urandom);
    io_sqControl_toStoreMisalignBuffer_uop_robIdx_value = 8'($urandom);
  endtask

  // ---------------------------------------------------------------------------
  // 激励整形（手写）
  // ---------------------------------------------------------------------------
  int          phase_enq_pct;
  logic        rob_flag_base;
  logic [7:0]  rob_base;

  function automatic bit pct(int p);
    return ($urandom_range(0, 99) < p);
  endfunction

  function automatic logic [8:0] rob_near(int span);
    return {rob_flag_base, rob_base} + 9'($urandom_range(0, span));
  endfunction

  task automatic new_phase();
    case ($urandom_range(0, 3))
      0: phase_enq_pct = 3;
      1: phase_enq_pct = 15;
      2: phase_enq_pct = 40;
      default: phase_enq_pct = 80;
    endcase
  endtask

  task automatic shape_enq(output logic [8:0] op, output logic isvec, output logic [2:0] atype,
                           output logic [49:0] vaddr);
    logic [8:0] ops [8] = '{9'h00, 9'h01, 9'h02, 9'h03, 9'h10, 9'h11, 9'h12, 9'h13};
    logic [1:0] sz;
    int nbytes, off;
    op    = pct(95) ? ops[$urandom_range(0, 7)] : 9'($urandom);
    isvec = pct(30);
    sz    = op[1:0];
    if (isvec) begin
      atype = pct(95) ? {1'b0, 2'($urandom)} : 3'($urandom_range(4, 7));
      sz    = atype[1:0];
    end else begin
      atype = 3'($urandom);
    end
    vaddr  = 50'({$urandom, $urandom});
    nbytes = 1 << sz;
    if (pct(80) && nbytes > 1) begin
      do off = $urandom_range(16 - nbytes + 1, 15); while (off % nbytes == 0);
      vaddr[3:0] = 4'(off);
      if (pct(35)) vaddr[11:4] = 8'hFF;     // 同时跨 4KB 页
    end else if (pct(50)) begin
      vaddr[3:0] = 4'($urandom_range(13, 15));
    end
  endtask

  // ---------------------------------------------------------------------------
  // StoreUnit 往返模型：splitStoreReq fire → 隔 1..4 拍回一个 splitStoreResp
  // ---------------------------------------------------------------------------
  typedef struct {
    int         due;
    logic [8:0] rob;
  } pend_t;
  pend_t pend_q [$];

  task automatic drive_resp();
    logic has;
    has = 0;
    io_splitStoreResp_valid = 0;
    if (pend_q.size() > 0 && pend_q[0].due <= cyc) begin
      pend_t p;
      p = pend_q.pop_front();
      has = 1;
      io_splitStoreResp_valid = 1;
      {io_splitStoreResp_bits_uop_robIdx_flag, io_splitStoreResp_bits_uop_robIdx_value} =
        pct(95) ? p.rob : 9'($urandom);
    end else if (pct(3)) begin
      io_splitStoreResp_valid = 1;
      has = 1;
    end
    if (has) begin
      io_splitStoreResp_bits_vecActive = pct(85);
      {io_splitStoreResp_bits_uop_exceptionVec_3, io_splitStoreResp_bits_uop_exceptionVec_6,
       io_splitStoreResp_bits_uop_exceptionVec_7, io_splitStoreResp_bits_uop_exceptionVec_15,
       io_splitStoreResp_bits_uop_exceptionVec_19, io_splitStoreResp_bits_uop_exceptionVec_23} =
        pct(8) ? 6'($urandom) : 6'h0;
      io_splitStoreResp_bits_uop_trigger = pct(3) ? 4'h1 : (pct(50) ? 4'hF : 4'($urandom));
      io_splitStoreResp_bits_mmio     = pct(3);
      io_splitStoreResp_bits_nc       = pct(3);
      io_splitStoreResp_bits_need_rep = pct(15);
    end
  endtask

  task automatic model_update();
    if (g_io_splitStoreReq_valid && io_splitStoreReq_ready) begin
      pend_t p;
      p.due = cyc + $urandom_range(1, 4);
      p.rob = {g_io_splitStoreReq_bits_uop_robIdx_flag, g_io_splitStoreReq_bits_uop_robIdx_value};
      if (pct(97)) pend_q.push_back(p);
    end
  endtask

  task automatic drive_inputs();
    logic [8:0] op; logic isvec; logic [2:0] atype; logic [49:0] va;
    logic [8:0] req_rob;
    randomize_all_inputs();
    req_rob = {u_g.req_uop_robIdx_flag, u_g.req_uop_robIdx_value};
    `ENQ_SHAPE(0)
    `ENQ_SHAPE(1)
    io_enq_0_revoke = pct(10);
    io_enq_1_revoke = pct(10);
    io_splitStoreReq_ready = pct(75);
    drive_resp();
    io_writeBack_ready     = pct(80);
    io_storeOutValid       = pct(15);
    io_storeVecOutValid    = pct(15);
    io_rob_pendingst       = pct(50);
    {io_rob_pendingPtr_flag, io_rob_pendingPtr_value} = pct(60) ? req_rob : rob_near(8);
    io_sqControl_toStoreMisalignBuffer_doDeq = pct(30);
    if (pct(50)) {io_sqControl_toStoreMisalignBuffer_sqPtr_flag, io_sqControl_toStoreMisalignBuffer_sqPtr_value} =
                   {u_g.req_uop_sqIdx_flag, u_g.req_uop_sqIdx_value};
    if (pct(50)) begin
      {io_sqControl_toStoreMisalignBuffer_uop_robIdx_flag, io_sqControl_toStoreMisalignBuffer_uop_robIdx_value} = req_rob;
      io_sqControl_toStoreMisalignBuffer_uop_uopIdx = u_g.req_uop_uopIdx;
    end
    io_redirect_valid = pct(2);
    {io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value} = rob_near(10) - 9'd4;
    if (pct(2)) {rob_flag_base, rob_base} = {rob_flag_base, rob_base} + 9'd1;
  endtask

  // ---------------------------------------------------------------------------
  // 覆盖计数（读 golden 内部）
  // ---------------------------------------------------------------------------
  int cov_state [6];
  int cov_split_combo [4][8];
  int cov_split_nocross, cov_resp_ok, cov_resp_rep, cov_resp_exc, cov_resp_unc, cov_resp_robmiss;
  int cov_delay_to_wb, cov_wb_normal, cov_wb_abort, cov_vec_wb0, cov_vec_wb1, cov_block_release;
  int cov_crosspage, cov_replace, cov_revoke_kill, cov_flush_idle, cov_flush_busy, cov_enq, cov_enq_blocked;

  task automatic cover_sample();
    logic [1:0] sz;
    if (u_g.bufferState < 6) cov_state[u_g.bufferState]++;
    sz = u_g.alignedType;
    if (u_g.bufferState == 1 && u_g.cross16BytesBoundary) cov_split_combo[sz][u_g.req_vaddr[2:0]]++;
    if (u_g.bufferState == 1 && !u_g.cross16BytesBoundary) cov_split_nocross++;
    if (u_g.bufferState == 1 && u_g.isCrossPage) cov_crosspage++;
    if (io_splitStoreResp_valid && u_g.bufferState == 3) begin
      if ({u_g.req_uop_robIdx_flag, u_g.req_uop_robIdx_value}
          != {io_splitStoreResp_bits_uop_robIdx_flag, io_splitStoreResp_bits_uop_robIdx_value})
        cov_resp_robmiss++;
      if (u_g.isUncache) cov_resp_unc++;
      else if (u_g.hasException) cov_resp_exc++;
      else if (io_splitStoreResp_bits_need_rep) cov_resp_rep++;
      else cov_resp_ok++;
    end
    if (u_g.bufferState == 3 && u_g.REG) cov_delay_to_wb++;
    if (g_io_writeBack_valid && io_writeBack_ready) begin
      if (u_g.globalException || u_g.globalUncache) cov_wb_abort++; else cov_wb_normal++;
    end
    if (g_io_vecWriteBack_0_valid) cov_vec_wb0++;
    if (g_io_vecWriteBack_1_valid) cov_vec_wb1++;
    if (u_g.bufferState == 5 && io_sqControl_toStoreMisalignBuffer_doDeq) cov_block_release++;
    if (u_g.req_valid && u_g.cross4KBPageBoundary && (g_io_enq_0_req_ready || g_io_enq_1_req_ready)
        && u_g.canEnq) cov_replace++;
    if (u_g.s2_needRevoke) cov_revoke_kill++;
    if (u_g.flush_probe) begin
      if (u_g.bufferState == 0) cov_flush_idle++; else cov_flush_busy++;
    end
    if (!u_g.req_valid && (io_enq_0_req_valid || io_enq_1_req_valid)) begin
      if (u_g.canEnq) cov_enq++; else cov_enq_blocked++;
    end
  endtask

  function automatic int cover_report();
    int holes;
    holes = 0;
    $display("COVER states: idle=%0d split=%0d req=%0d resp=%0d wb=%0d block=%0d",
             cov_state[0], cov_state[1], cov_state[2], cov_state[3], cov_state[4], cov_state[5]);
    for (int s = 0; s < 6; s++) if (cov_state[s] == 0) holes++;
    $display("COVER split legal combos: H/x=%0d  W/01=%0d W/10=%0d W/11=%0d  D/001..111=%0d %0d %0d %0d %0d %0d %0d",
             cov_split_combo[1][0] + cov_split_combo[1][1] + cov_split_combo[1][2] + cov_split_combo[1][3]
             + cov_split_combo[1][4] + cov_split_combo[1][5] + cov_split_combo[1][6] + cov_split_combo[1][7],
             cov_split_combo[2][1] + cov_split_combo[2][5], cov_split_combo[2][2] + cov_split_combo[2][6],
             cov_split_combo[2][3] + cov_split_combo[2][7],
             cov_split_combo[3][1], cov_split_combo[3][2], cov_split_combo[3][3], cov_split_combo[3][4],
             cov_split_combo[3][5], cov_split_combo[3][6], cov_split_combo[3][7]);
    if (cov_split_combo[1][7] == 0) holes++;
    for (int o = 1; o < 4; o++) if (cov_split_combo[2][o] + cov_split_combo[2][o + 4] == 0) holes++;
    for (int o = 1; o < 8; o++) if (cov_split_combo[3][o] == 0) holes++;
    $display("COVER split_nocross=%0d crosspage_split=%0d resp: ok=%0d rep=%0d exc=%0d uncache=%0d robIdx-mismatch=%0d delay_to_wb=%0d",
             cov_split_nocross, cov_crosspage, cov_resp_ok, cov_resp_rep, cov_resp_exc, cov_resp_unc,
             cov_resp_robmiss, cov_delay_to_wb);
    $display("COVER wb_normal=%0d wb_abort=%0d vec_wb0=%0d vec_wb1=%0d block_release=%0d replace=%0d revoke_kill=%0d flush_idle=%0d flush_busy=%0d enq=%0d enq_blocked=%0d",
             cov_wb_normal, cov_wb_abort, cov_vec_wb0, cov_vec_wb1, cov_block_release, cov_replace,
             cov_revoke_kill, cov_flush_idle, cov_flush_busy, cov_enq, cov_enq_blocked);
    if (cov_split_nocross == 0) holes++;
    if (cov_crosspage == 0) holes++;
    if (cov_resp_ok == 0) holes++;
    if (cov_resp_rep == 0) holes++;
    if (cov_resp_exc == 0) holes++;
    if (cov_resp_unc == 0) holes++;
    if (cov_resp_robmiss == 0) holes++;
    if (cov_delay_to_wb == 0) holes++;
    if (cov_wb_normal == 0) holes++;
    if (cov_wb_abort == 0) holes++;
    if (cov_vec_wb0 == 0) holes++;
    if (cov_vec_wb1 == 0) holes++;
    if (cov_block_release == 0) holes++;
    if (cov_replace == 0) holes++;
    if (cov_revoke_kill == 0) holes++;
    if (cov_flush_idle == 0) holes++;
    if (cov_flush_busy == 0) holes++;
    if (cov_enq == 0) holes++;
    if (cov_enq_blocked == 0) holes++;
    return holes;
  endfunction

  task automatic compare_outputs();
    checks++;
    if (g_io_enq_0_req_ready !== i_io_enq_0_req_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_enq_0_req_ready g=%h i=%h", cyc, g_io_enq_0_req_ready, i_io_enq_0_req_ready);
    end
    if (g_io_enq_1_req_ready !== i_io_enq_1_req_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_enq_1_req_ready g=%h i=%h", cyc, g_io_enq_1_req_ready, i_io_enq_1_req_ready);
    end
    if (g_io_splitStoreReq_valid !== i_io_splitStoreReq_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_valid g=%h i=%h", cyc, g_io_splitStoreReq_valid, i_io_splitStoreReq_valid);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_0 !== i_io_splitStoreReq_bits_uop_exceptionVec_0) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_0 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_0, i_io_splitStoreReq_bits_uop_exceptionVec_0);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_1 !== i_io_splitStoreReq_bits_uop_exceptionVec_1) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_1 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_1, i_io_splitStoreReq_bits_uop_exceptionVec_1);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_2 !== i_io_splitStoreReq_bits_uop_exceptionVec_2) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_2 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_2, i_io_splitStoreReq_bits_uop_exceptionVec_2);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_4 !== i_io_splitStoreReq_bits_uop_exceptionVec_4) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_4 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_4, i_io_splitStoreReq_bits_uop_exceptionVec_4);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_5 !== i_io_splitStoreReq_bits_uop_exceptionVec_5) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_5 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_5, i_io_splitStoreReq_bits_uop_exceptionVec_5);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_8 !== i_io_splitStoreReq_bits_uop_exceptionVec_8) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_8 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_8, i_io_splitStoreReq_bits_uop_exceptionVec_8);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_9 !== i_io_splitStoreReq_bits_uop_exceptionVec_9) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_9 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_9, i_io_splitStoreReq_bits_uop_exceptionVec_9);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_10 !== i_io_splitStoreReq_bits_uop_exceptionVec_10) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_10 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_10, i_io_splitStoreReq_bits_uop_exceptionVec_10);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_11 !== i_io_splitStoreReq_bits_uop_exceptionVec_11) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_11 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_11, i_io_splitStoreReq_bits_uop_exceptionVec_11);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_12 !== i_io_splitStoreReq_bits_uop_exceptionVec_12) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_12 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_12, i_io_splitStoreReq_bits_uop_exceptionVec_12);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_13 !== i_io_splitStoreReq_bits_uop_exceptionVec_13) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_13 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_13, i_io_splitStoreReq_bits_uop_exceptionVec_13);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_14 !== i_io_splitStoreReq_bits_uop_exceptionVec_14) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_14 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_14, i_io_splitStoreReq_bits_uop_exceptionVec_14);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_16 !== i_io_splitStoreReq_bits_uop_exceptionVec_16) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_16 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_16, i_io_splitStoreReq_bits_uop_exceptionVec_16);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_17 !== i_io_splitStoreReq_bits_uop_exceptionVec_17) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_17 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_17, i_io_splitStoreReq_bits_uop_exceptionVec_17);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_18 !== i_io_splitStoreReq_bits_uop_exceptionVec_18) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_18 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_18, i_io_splitStoreReq_bits_uop_exceptionVec_18);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_19 !== i_io_splitStoreReq_bits_uop_exceptionVec_19) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_19 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_19, i_io_splitStoreReq_bits_uop_exceptionVec_19);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_20 !== i_io_splitStoreReq_bits_uop_exceptionVec_20) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_20 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_20, i_io_splitStoreReq_bits_uop_exceptionVec_20);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_21 !== i_io_splitStoreReq_bits_uop_exceptionVec_21) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_21 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_21, i_io_splitStoreReq_bits_uop_exceptionVec_21);
    end
    if (g_io_splitStoreReq_bits_uop_exceptionVec_22 !== i_io_splitStoreReq_bits_uop_exceptionVec_22) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_exceptionVec_22 g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_exceptionVec_22, i_io_splitStoreReq_bits_uop_exceptionVec_22);
    end
    if (g_io_splitStoreReq_bits_uop_trigger !== i_io_splitStoreReq_bits_uop_trigger) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_trigger g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_trigger, i_io_splitStoreReq_bits_uop_trigger);
    end
    if (g_io_splitStoreReq_bits_uop_ftqPtr_flag !== i_io_splitStoreReq_bits_uop_ftqPtr_flag) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_ftqPtr_flag g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_ftqPtr_flag, i_io_splitStoreReq_bits_uop_ftqPtr_flag);
    end
    if (g_io_splitStoreReq_bits_uop_ftqPtr_value !== i_io_splitStoreReq_bits_uop_ftqPtr_value) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_ftqPtr_value g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_ftqPtr_value, i_io_splitStoreReq_bits_uop_ftqPtr_value);
    end
    if (g_io_splitStoreReq_bits_uop_ftqOffset !== i_io_splitStoreReq_bits_uop_ftqOffset) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_ftqOffset g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_ftqOffset, i_io_splitStoreReq_bits_uop_ftqOffset);
    end
    if (g_io_splitStoreReq_bits_uop_fuType !== i_io_splitStoreReq_bits_uop_fuType) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_fuType g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_fuType, i_io_splitStoreReq_bits_uop_fuType);
    end
    if (g_io_splitStoreReq_bits_uop_fuOpType !== i_io_splitStoreReq_bits_uop_fuOpType) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_fuOpType g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_fuOpType, i_io_splitStoreReq_bits_uop_fuOpType);
    end
    if (g_io_splitStoreReq_bits_uop_rfWen !== i_io_splitStoreReq_bits_uop_rfWen) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_rfWen g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_rfWen, i_io_splitStoreReq_bits_uop_rfWen);
    end
    if (g_io_splitStoreReq_bits_uop_vpu_vstart !== i_io_splitStoreReq_bits_uop_vpu_vstart) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_vpu_vstart g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_vpu_vstart, i_io_splitStoreReq_bits_uop_vpu_vstart);
    end
    if (g_io_splitStoreReq_bits_uop_vpu_nf !== i_io_splitStoreReq_bits_uop_vpu_nf) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_vpu_nf g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_vpu_nf, i_io_splitStoreReq_bits_uop_vpu_nf);
    end
    if (g_io_splitStoreReq_bits_uop_vpu_veew !== i_io_splitStoreReq_bits_uop_vpu_veew) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_vpu_veew g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_vpu_veew, i_io_splitStoreReq_bits_uop_vpu_veew);
    end
    if (g_io_splitStoreReq_bits_uop_uopIdx !== i_io_splitStoreReq_bits_uop_uopIdx) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_uopIdx g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_uopIdx, i_io_splitStoreReq_bits_uop_uopIdx);
    end
    if (g_io_splitStoreReq_bits_uop_pdest !== i_io_splitStoreReq_bits_uop_pdest) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_pdest g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_pdest, i_io_splitStoreReq_bits_uop_pdest);
    end
    if (g_io_splitStoreReq_bits_uop_robIdx_flag !== i_io_splitStoreReq_bits_uop_robIdx_flag) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_robIdx_flag g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_robIdx_flag, i_io_splitStoreReq_bits_uop_robIdx_flag);
    end
    if (g_io_splitStoreReq_bits_uop_robIdx_value !== i_io_splitStoreReq_bits_uop_robIdx_value) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_robIdx_value g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_robIdx_value, i_io_splitStoreReq_bits_uop_robIdx_value);
    end
    if (g_io_splitStoreReq_bits_uop_debugInfo_eliminatedMove !== i_io_splitStoreReq_bits_uop_debugInfo_eliminatedMove) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_debugInfo_eliminatedMove g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_debugInfo_eliminatedMove, i_io_splitStoreReq_bits_uop_debugInfo_eliminatedMove);
    end
    if (g_io_splitStoreReq_bits_uop_debugInfo_renameTime !== i_io_splitStoreReq_bits_uop_debugInfo_renameTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_debugInfo_renameTime g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_debugInfo_renameTime, i_io_splitStoreReq_bits_uop_debugInfo_renameTime);
    end
    if (g_io_splitStoreReq_bits_uop_debugInfo_dispatchTime !== i_io_splitStoreReq_bits_uop_debugInfo_dispatchTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_debugInfo_dispatchTime g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_debugInfo_dispatchTime, i_io_splitStoreReq_bits_uop_debugInfo_dispatchTime);
    end
    if (g_io_splitStoreReq_bits_uop_debugInfo_enqRsTime !== i_io_splitStoreReq_bits_uop_debugInfo_enqRsTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_debugInfo_enqRsTime g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_debugInfo_enqRsTime, i_io_splitStoreReq_bits_uop_debugInfo_enqRsTime);
    end
    if (g_io_splitStoreReq_bits_uop_debugInfo_selectTime !== i_io_splitStoreReq_bits_uop_debugInfo_selectTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_debugInfo_selectTime g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_debugInfo_selectTime, i_io_splitStoreReq_bits_uop_debugInfo_selectTime);
    end
    if (g_io_splitStoreReq_bits_uop_debugInfo_issueTime !== i_io_splitStoreReq_bits_uop_debugInfo_issueTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_debugInfo_issueTime g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_debugInfo_issueTime, i_io_splitStoreReq_bits_uop_debugInfo_issueTime);
    end
    if (g_io_splitStoreReq_bits_uop_debugInfo_writebackTime !== i_io_splitStoreReq_bits_uop_debugInfo_writebackTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_debugInfo_writebackTime g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_debugInfo_writebackTime, i_io_splitStoreReq_bits_uop_debugInfo_writebackTime);
    end
    if (g_io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id !== i_io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id, i_io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id);
    end
    if (g_io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime !== i_io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime, i_io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime);
    end
    if (g_io_splitStoreReq_bits_uop_debugInfo_tlbRespTime !== i_io_splitStoreReq_bits_uop_debugInfo_tlbRespTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_debugInfo_tlbRespTime g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_debugInfo_tlbRespTime, i_io_splitStoreReq_bits_uop_debugInfo_tlbRespTime);
    end
    if (g_io_splitStoreReq_bits_uop_debug_seqNum_seqNum !== i_io_splitStoreReq_bits_uop_debug_seqNum_seqNum) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_debug_seqNum_seqNum g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_debug_seqNum_seqNum, i_io_splitStoreReq_bits_uop_debug_seqNum_seqNum);
    end
    if (g_io_splitStoreReq_bits_uop_debug_seqNum_uopIdx !== i_io_splitStoreReq_bits_uop_debug_seqNum_uopIdx) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_debug_seqNum_uopIdx g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_debug_seqNum_uopIdx, i_io_splitStoreReq_bits_uop_debug_seqNum_uopIdx);
    end
    if (g_io_splitStoreReq_bits_uop_lqIdx_flag !== i_io_splitStoreReq_bits_uop_lqIdx_flag) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_lqIdx_flag g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_lqIdx_flag, i_io_splitStoreReq_bits_uop_lqIdx_flag);
    end
    if (g_io_splitStoreReq_bits_uop_lqIdx_value !== i_io_splitStoreReq_bits_uop_lqIdx_value) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_lqIdx_value g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_lqIdx_value, i_io_splitStoreReq_bits_uop_lqIdx_value);
    end
    if (g_io_splitStoreReq_bits_uop_sqIdx_flag !== i_io_splitStoreReq_bits_uop_sqIdx_flag) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_sqIdx_flag g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_sqIdx_flag, i_io_splitStoreReq_bits_uop_sqIdx_flag);
    end
    if (g_io_splitStoreReq_bits_uop_sqIdx_value !== i_io_splitStoreReq_bits_uop_sqIdx_value) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_uop_sqIdx_value g=%h i=%h", cyc, g_io_splitStoreReq_bits_uop_sqIdx_value, i_io_splitStoreReq_bits_uop_sqIdx_value);
    end
    if (g_io_splitStoreReq_bits_vaddr !== i_io_splitStoreReq_bits_vaddr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_vaddr g=%h i=%h", cyc, g_io_splitStoreReq_bits_vaddr, i_io_splitStoreReq_bits_vaddr);
    end
    if (g_io_splitStoreReq_bits_mask !== i_io_splitStoreReq_bits_mask) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_mask g=%h i=%h", cyc, g_io_splitStoreReq_bits_mask, i_io_splitStoreReq_bits_mask);
    end
    if (g_io_splitStoreReq_bits_isvec !== i_io_splitStoreReq_bits_isvec) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_isvec g=%h i=%h", cyc, g_io_splitStoreReq_bits_isvec, i_io_splitStoreReq_bits_isvec);
    end
    if (g_io_splitStoreReq_bits_is128bit !== i_io_splitStoreReq_bits_is128bit) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_is128bit g=%h i=%h", cyc, g_io_splitStoreReq_bits_is128bit, i_io_splitStoreReq_bits_is128bit);
    end
    if (g_io_splitStoreReq_bits_isFinalSplit !== i_io_splitStoreReq_bits_isFinalSplit) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_splitStoreReq_bits_isFinalSplit g=%h i=%h", cyc, g_io_splitStoreReq_bits_isFinalSplit, i_io_splitStoreReq_bits_isFinalSplit);
    end
    if (g_io_writeBack_valid !== i_io_writeBack_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_valid g=%h i=%h", cyc, g_io_writeBack_valid, i_io_writeBack_valid);
    end
    if (g_io_writeBack_bits_uop_exceptionVec_3 !== i_io_writeBack_bits_uop_exceptionVec_3) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_exceptionVec_3 g=%h i=%h", cyc, g_io_writeBack_bits_uop_exceptionVec_3, i_io_writeBack_bits_uop_exceptionVec_3);
    end
    if (g_io_writeBack_bits_uop_exceptionVec_6 !== i_io_writeBack_bits_uop_exceptionVec_6) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_exceptionVec_6 g=%h i=%h", cyc, g_io_writeBack_bits_uop_exceptionVec_6, i_io_writeBack_bits_uop_exceptionVec_6);
    end
    if (g_io_writeBack_bits_uop_exceptionVec_7 !== i_io_writeBack_bits_uop_exceptionVec_7) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_exceptionVec_7 g=%h i=%h", cyc, g_io_writeBack_bits_uop_exceptionVec_7, i_io_writeBack_bits_uop_exceptionVec_7);
    end
    if (g_io_writeBack_bits_uop_exceptionVec_15 !== i_io_writeBack_bits_uop_exceptionVec_15) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_exceptionVec_15 g=%h i=%h", cyc, g_io_writeBack_bits_uop_exceptionVec_15, i_io_writeBack_bits_uop_exceptionVec_15);
    end
    if (g_io_writeBack_bits_uop_exceptionVec_19 !== i_io_writeBack_bits_uop_exceptionVec_19) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_exceptionVec_19 g=%h i=%h", cyc, g_io_writeBack_bits_uop_exceptionVec_19, i_io_writeBack_bits_uop_exceptionVec_19);
    end
    if (g_io_writeBack_bits_uop_exceptionVec_23 !== i_io_writeBack_bits_uop_exceptionVec_23) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_exceptionVec_23 g=%h i=%h", cyc, g_io_writeBack_bits_uop_exceptionVec_23, i_io_writeBack_bits_uop_exceptionVec_23);
    end
    if (g_io_writeBack_bits_uop_trigger !== i_io_writeBack_bits_uop_trigger) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_trigger g=%h i=%h", cyc, g_io_writeBack_bits_uop_trigger, i_io_writeBack_bits_uop_trigger);
    end
    if (g_io_writeBack_bits_uop_rfWen !== i_io_writeBack_bits_uop_rfWen) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_rfWen g=%h i=%h", cyc, g_io_writeBack_bits_uop_rfWen, i_io_writeBack_bits_uop_rfWen);
    end
    if (g_io_writeBack_bits_uop_pdest !== i_io_writeBack_bits_uop_pdest) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_pdest g=%h i=%h", cyc, g_io_writeBack_bits_uop_pdest, i_io_writeBack_bits_uop_pdest);
    end
    if (g_io_writeBack_bits_uop_robIdx_flag !== i_io_writeBack_bits_uop_robIdx_flag) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_robIdx_flag g=%h i=%h", cyc, g_io_writeBack_bits_uop_robIdx_flag, i_io_writeBack_bits_uop_robIdx_flag);
    end
    if (g_io_writeBack_bits_uop_robIdx_value !== i_io_writeBack_bits_uop_robIdx_value) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_robIdx_value g=%h i=%h", cyc, g_io_writeBack_bits_uop_robIdx_value, i_io_writeBack_bits_uop_robIdx_value);
    end
    if (g_io_writeBack_bits_uop_debugInfo_eliminatedMove !== i_io_writeBack_bits_uop_debugInfo_eliminatedMove) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_debugInfo_eliminatedMove g=%h i=%h", cyc, g_io_writeBack_bits_uop_debugInfo_eliminatedMove, i_io_writeBack_bits_uop_debugInfo_eliminatedMove);
    end
    if (g_io_writeBack_bits_uop_debugInfo_renameTime !== i_io_writeBack_bits_uop_debugInfo_renameTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_debugInfo_renameTime g=%h i=%h", cyc, g_io_writeBack_bits_uop_debugInfo_renameTime, i_io_writeBack_bits_uop_debugInfo_renameTime);
    end
    if (g_io_writeBack_bits_uop_debugInfo_dispatchTime !== i_io_writeBack_bits_uop_debugInfo_dispatchTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_debugInfo_dispatchTime g=%h i=%h", cyc, g_io_writeBack_bits_uop_debugInfo_dispatchTime, i_io_writeBack_bits_uop_debugInfo_dispatchTime);
    end
    if (g_io_writeBack_bits_uop_debugInfo_enqRsTime !== i_io_writeBack_bits_uop_debugInfo_enqRsTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_debugInfo_enqRsTime g=%h i=%h", cyc, g_io_writeBack_bits_uop_debugInfo_enqRsTime, i_io_writeBack_bits_uop_debugInfo_enqRsTime);
    end
    if (g_io_writeBack_bits_uop_debugInfo_selectTime !== i_io_writeBack_bits_uop_debugInfo_selectTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_debugInfo_selectTime g=%h i=%h", cyc, g_io_writeBack_bits_uop_debugInfo_selectTime, i_io_writeBack_bits_uop_debugInfo_selectTime);
    end
    if (g_io_writeBack_bits_uop_debugInfo_issueTime !== i_io_writeBack_bits_uop_debugInfo_issueTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_debugInfo_issueTime g=%h i=%h", cyc, g_io_writeBack_bits_uop_debugInfo_issueTime, i_io_writeBack_bits_uop_debugInfo_issueTime);
    end
    if (g_io_writeBack_bits_uop_debugInfo_writebackTime !== i_io_writeBack_bits_uop_debugInfo_writebackTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_debugInfo_writebackTime g=%h i=%h", cyc, g_io_writeBack_bits_uop_debugInfo_writebackTime, i_io_writeBack_bits_uop_debugInfo_writebackTime);
    end
    if (g_io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id !== i_io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id g=%h i=%h", cyc, g_io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id, i_io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id);
    end
    if (g_io_writeBack_bits_uop_debugInfo_tlbFirstReqTime !== i_io_writeBack_bits_uop_debugInfo_tlbFirstReqTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_debugInfo_tlbFirstReqTime g=%h i=%h", cyc, g_io_writeBack_bits_uop_debugInfo_tlbFirstReqTime, i_io_writeBack_bits_uop_debugInfo_tlbFirstReqTime);
    end
    if (g_io_writeBack_bits_uop_debugInfo_tlbRespTime !== i_io_writeBack_bits_uop_debugInfo_tlbRespTime) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_debugInfo_tlbRespTime g=%h i=%h", cyc, g_io_writeBack_bits_uop_debugInfo_tlbRespTime, i_io_writeBack_bits_uop_debugInfo_tlbRespTime);
    end
    if (g_io_writeBack_bits_uop_debug_seqNum_seqNum !== i_io_writeBack_bits_uop_debug_seqNum_seqNum) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_debug_seqNum_seqNum g=%h i=%h", cyc, g_io_writeBack_bits_uop_debug_seqNum_seqNum, i_io_writeBack_bits_uop_debug_seqNum_seqNum);
    end
    if (g_io_writeBack_bits_uop_debug_seqNum_uopIdx !== i_io_writeBack_bits_uop_debug_seqNum_uopIdx) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_debug_seqNum_uopIdx g=%h i=%h", cyc, g_io_writeBack_bits_uop_debug_seqNum_uopIdx, i_io_writeBack_bits_uop_debug_seqNum_uopIdx);
    end
    if (g_io_writeBack_bits_uop_sqIdx_flag !== i_io_writeBack_bits_uop_sqIdx_flag) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_sqIdx_flag g=%h i=%h", cyc, g_io_writeBack_bits_uop_sqIdx_flag, i_io_writeBack_bits_uop_sqIdx_flag);
    end
    if (g_io_writeBack_bits_uop_sqIdx_value !== i_io_writeBack_bits_uop_sqIdx_value) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_uop_sqIdx_value g=%h i=%h", cyc, g_io_writeBack_bits_uop_sqIdx_value, i_io_writeBack_bits_uop_sqIdx_value);
    end
    if (g_io_writeBack_bits_debug_isMMIO !== i_io_writeBack_bits_debug_isMMIO) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_debug_isMMIO g=%h i=%h", cyc, g_io_writeBack_bits_debug_isMMIO, i_io_writeBack_bits_debug_isMMIO);
    end
    if (g_io_writeBack_bits_debug_isNCIO !== i_io_writeBack_bits_debug_isNCIO) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_debug_isNCIO g=%h i=%h", cyc, g_io_writeBack_bits_debug_isNCIO, i_io_writeBack_bits_debug_isNCIO);
    end
    if (g_io_writeBack_bits_debug_paddr !== i_io_writeBack_bits_debug_paddr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_debug_paddr g=%h i=%h", cyc, g_io_writeBack_bits_debug_paddr, i_io_writeBack_bits_debug_paddr);
    end
    if (g_io_writeBack_bits_debug_vaddr !== i_io_writeBack_bits_debug_vaddr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_writeBack_bits_debug_vaddr g=%h i=%h", cyc, g_io_writeBack_bits_debug_vaddr, i_io_writeBack_bits_debug_vaddr);
    end
    if (g_io_vecWriteBack_0_valid !== i_io_vecWriteBack_0_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_valid g=%h i=%h", cyc, g_io_vecWriteBack_0_valid, i_io_vecWriteBack_0_valid);
    end
    if (g_io_vecWriteBack_0_bits_mBIndex !== i_io_vecWriteBack_0_bits_mBIndex) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_mBIndex g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_mBIndex, i_io_vecWriteBack_0_bits_mBIndex);
    end
    if (g_io_vecWriteBack_0_bits_exceptionVec_3 !== i_io_vecWriteBack_0_bits_exceptionVec_3) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_exceptionVec_3 g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_exceptionVec_3, i_io_vecWriteBack_0_bits_exceptionVec_3);
    end
    if (g_io_vecWriteBack_0_bits_exceptionVec_6 !== i_io_vecWriteBack_0_bits_exceptionVec_6) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_exceptionVec_6 g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_exceptionVec_6, i_io_vecWriteBack_0_bits_exceptionVec_6);
    end
    if (g_io_vecWriteBack_0_bits_exceptionVec_7 !== i_io_vecWriteBack_0_bits_exceptionVec_7) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_exceptionVec_7 g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_exceptionVec_7, i_io_vecWriteBack_0_bits_exceptionVec_7);
    end
    if (g_io_vecWriteBack_0_bits_exceptionVec_15 !== i_io_vecWriteBack_0_bits_exceptionVec_15) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_exceptionVec_15 g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_exceptionVec_15, i_io_vecWriteBack_0_bits_exceptionVec_15);
    end
    if (g_io_vecWriteBack_0_bits_exceptionVec_19 !== i_io_vecWriteBack_0_bits_exceptionVec_19) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_exceptionVec_19 g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_exceptionVec_19, i_io_vecWriteBack_0_bits_exceptionVec_19);
    end
    if (g_io_vecWriteBack_0_bits_exceptionVec_23 !== i_io_vecWriteBack_0_bits_exceptionVec_23) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_exceptionVec_23 g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_exceptionVec_23, i_io_vecWriteBack_0_bits_exceptionVec_23);
    end
    if (g_io_vecWriteBack_0_bits_hasException !== i_io_vecWriteBack_0_bits_hasException) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_hasException g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_hasException, i_io_vecWriteBack_0_bits_hasException);
    end
    if (g_io_vecWriteBack_0_bits_vaddr !== i_io_vecWriteBack_0_bits_vaddr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_vaddr g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_vaddr, i_io_vecWriteBack_0_bits_vaddr);
    end
    if (g_io_vecWriteBack_0_bits_vaNeedExt !== i_io_vecWriteBack_0_bits_vaNeedExt) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_vaNeedExt g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_vaNeedExt, i_io_vecWriteBack_0_bits_vaNeedExt);
    end
    if (g_io_vecWriteBack_0_bits_gpaddr !== i_io_vecWriteBack_0_bits_gpaddr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_gpaddr g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_gpaddr, i_io_vecWriteBack_0_bits_gpaddr);
    end
    if (g_io_vecWriteBack_0_bits_isForVSnonLeafPTE !== i_io_vecWriteBack_0_bits_isForVSnonLeafPTE) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_isForVSnonLeafPTE g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_isForVSnonLeafPTE, i_io_vecWriteBack_0_bits_isForVSnonLeafPTE);
    end
    if (g_io_vecWriteBack_0_bits_vstart !== i_io_vecWriteBack_0_bits_vstart) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_vstart g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_vstart, i_io_vecWriteBack_0_bits_vstart);
    end
    if (g_io_vecWriteBack_0_bits_elemIdx !== i_io_vecWriteBack_0_bits_elemIdx) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_elemIdx g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_elemIdx, i_io_vecWriteBack_0_bits_elemIdx);
    end
    if (g_io_vecWriteBack_0_bits_mask !== i_io_vecWriteBack_0_bits_mask) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_mask g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_mask, i_io_vecWriteBack_0_bits_mask);
    end
    if (g_io_vecWriteBack_0_bits_splitIndex !== i_io_vecWriteBack_0_bits_splitIndex) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_0_bits_splitIndex g=%h i=%h", cyc, g_io_vecWriteBack_0_bits_splitIndex, i_io_vecWriteBack_0_bits_splitIndex);
    end
    if (g_io_vecWriteBack_1_valid !== i_io_vecWriteBack_1_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_valid g=%h i=%h", cyc, g_io_vecWriteBack_1_valid, i_io_vecWriteBack_1_valid);
    end
    if (g_io_vecWriteBack_1_bits_mBIndex !== i_io_vecWriteBack_1_bits_mBIndex) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_mBIndex g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_mBIndex, i_io_vecWriteBack_1_bits_mBIndex);
    end
    if (g_io_vecWriteBack_1_bits_exceptionVec_3 !== i_io_vecWriteBack_1_bits_exceptionVec_3) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_exceptionVec_3 g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_exceptionVec_3, i_io_vecWriteBack_1_bits_exceptionVec_3);
    end
    if (g_io_vecWriteBack_1_bits_exceptionVec_6 !== i_io_vecWriteBack_1_bits_exceptionVec_6) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_exceptionVec_6 g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_exceptionVec_6, i_io_vecWriteBack_1_bits_exceptionVec_6);
    end
    if (g_io_vecWriteBack_1_bits_exceptionVec_7 !== i_io_vecWriteBack_1_bits_exceptionVec_7) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_exceptionVec_7 g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_exceptionVec_7, i_io_vecWriteBack_1_bits_exceptionVec_7);
    end
    if (g_io_vecWriteBack_1_bits_exceptionVec_15 !== i_io_vecWriteBack_1_bits_exceptionVec_15) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_exceptionVec_15 g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_exceptionVec_15, i_io_vecWriteBack_1_bits_exceptionVec_15);
    end
    if (g_io_vecWriteBack_1_bits_exceptionVec_19 !== i_io_vecWriteBack_1_bits_exceptionVec_19) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_exceptionVec_19 g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_exceptionVec_19, i_io_vecWriteBack_1_bits_exceptionVec_19);
    end
    if (g_io_vecWriteBack_1_bits_exceptionVec_23 !== i_io_vecWriteBack_1_bits_exceptionVec_23) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_exceptionVec_23 g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_exceptionVec_23, i_io_vecWriteBack_1_bits_exceptionVec_23);
    end
    if (g_io_vecWriteBack_1_bits_hasException !== i_io_vecWriteBack_1_bits_hasException) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_hasException g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_hasException, i_io_vecWriteBack_1_bits_hasException);
    end
    if (g_io_vecWriteBack_1_bits_vaddr !== i_io_vecWriteBack_1_bits_vaddr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_vaddr g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_vaddr, i_io_vecWriteBack_1_bits_vaddr);
    end
    if (g_io_vecWriteBack_1_bits_vaNeedExt !== i_io_vecWriteBack_1_bits_vaNeedExt) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_vaNeedExt g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_vaNeedExt, i_io_vecWriteBack_1_bits_vaNeedExt);
    end
    if (g_io_vecWriteBack_1_bits_gpaddr !== i_io_vecWriteBack_1_bits_gpaddr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_gpaddr g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_gpaddr, i_io_vecWriteBack_1_bits_gpaddr);
    end
    if (g_io_vecWriteBack_1_bits_isForVSnonLeafPTE !== i_io_vecWriteBack_1_bits_isForVSnonLeafPTE) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_isForVSnonLeafPTE g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_isForVSnonLeafPTE, i_io_vecWriteBack_1_bits_isForVSnonLeafPTE);
    end
    if (g_io_vecWriteBack_1_bits_vstart !== i_io_vecWriteBack_1_bits_vstart) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_vstart g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_vstart, i_io_vecWriteBack_1_bits_vstart);
    end
    if (g_io_vecWriteBack_1_bits_elemIdx !== i_io_vecWriteBack_1_bits_elemIdx) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_elemIdx g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_elemIdx, i_io_vecWriteBack_1_bits_elemIdx);
    end
    if (g_io_vecWriteBack_1_bits_mask !== i_io_vecWriteBack_1_bits_mask) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_mask g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_mask, i_io_vecWriteBack_1_bits_mask);
    end
    if (g_io_vecWriteBack_1_bits_splitIndex !== i_io_vecWriteBack_1_bits_splitIndex) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_vecWriteBack_1_bits_splitIndex g=%h i=%h", cyc, g_io_vecWriteBack_1_bits_splitIndex, i_io_vecWriteBack_1_bits_splitIndex);
    end
    if (g_io_sqControl_toStoreQueue_crossPageWithHit !== i_io_sqControl_toStoreQueue_crossPageWithHit) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_sqControl_toStoreQueue_crossPageWithHit g=%h i=%h", cyc, g_io_sqControl_toStoreQueue_crossPageWithHit, i_io_sqControl_toStoreQueue_crossPageWithHit);
    end
    if (g_io_sqControl_toStoreQueue_crossPageCanDeq !== i_io_sqControl_toStoreQueue_crossPageCanDeq) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_sqControl_toStoreQueue_crossPageCanDeq g=%h i=%h", cyc, g_io_sqControl_toStoreQueue_crossPageCanDeq, i_io_sqControl_toStoreQueue_crossPageCanDeq);
    end
    if (g_io_sqControl_toStoreQueue_paddr !== i_io_sqControl_toStoreQueue_paddr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_sqControl_toStoreQueue_paddr g=%h i=%h", cyc, g_io_sqControl_toStoreQueue_paddr, i_io_sqControl_toStoreQueue_paddr);
    end
    if (g_io_sqControl_toStoreQueue_withSamePtr !== i_io_sqControl_toStoreQueue_withSamePtr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_sqControl_toStoreQueue_withSamePtr g=%h i=%h", cyc, g_io_sqControl_toStoreQueue_withSamePtr, i_io_sqControl_toStoreQueue_withSamePtr);
    end
    if (g_io_toVecSplit_empty !== i_io_toVecSplit_empty) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_toVecSplit_empty g=%h i=%h", cyc, g_io_toVecSplit_empty, i_io_toVecSplit_empty);
    end
  endtask

  always #5 clock = ~clock;

  initial begin
    int holes;
    void'($value$plusargs("ncycles=%d", NCYCLES));
    void'($value$plusargs("gate_req=%d", gate_req));
    rob_flag_base = 0; rob_base = 8'($urandom);
    new_phase();
    randomize_all_inputs();
    io_redirect_valid = 0; io_splitStoreResp_valid = 0;
    io_enq_0_req_valid = 0; io_enq_1_req_valid = 0;
    repeat (5) @(negedge clock);
    reset = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (cyc % 1024 == 0) new_phase();
      drive_inputs();
      #1;
      if (!gate_req || req_seen) compare_outputs();
      if (u_g.canEnq) req_seen = 1;
      cover_sample();
      model_update();
    end
    holes = cover_report();
    $display("checks=%0d errors=%0d cover_holes=%0d", checks, errors, holes);
    if (errors == 0 && holes == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
