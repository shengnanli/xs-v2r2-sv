// xs_VSegmentUnit_core —— 向量分段访存单元(segment load/store)可读核。
// 手写重写, bug-for-bug 对齐 golden VSegmentUnit.sv(firtool-1.62.1)。
// 状态机遍历 segment×field 逐流(flow)发 dtlb/dcache/sbuffer 请求;
// 8 深 uopq/data/stride 队列(generate-for 数组);数据/掩码按 eew 排列(always_comb)。
// 两个子模块由 wrapper 例化(两侧同 elaborate 的 golden 定义):
//   - segmentTrigger(VSegmentTrigger, 纯组合触发比较)
//   - VSegmentUnitPipelineConnect(NewPipelineConnectPipe_31, sbuffer 打拍)
// 核暴露它们的 glue 端口(seg_trig_action / pc_* / sbufReq_*)。
// _GEN_/_T_ 密度 = 0(仅注释引用 golden 名)。
module xs_VSegmentUnit_core
  import xs_vsegmentunit_pkg::*;
(
  input          clock,
  input          reset,
  input          io_in_valid,
  input  [34:0]  io_in_bits_uop_fuType,
  input  [8:0]   io_in_bits_uop_fuOpType,
  input          io_in_bits_uop_vecWen,
  input          io_in_bits_uop_v0Wen,
  input          io_in_bits_uop_vlWen,
  input          io_in_bits_uop_vpu_vma,
  input          io_in_bits_uop_vpu_vta,
  input  [1:0]   io_in_bits_uop_vpu_vsew,
  input  [2:0]   io_in_bits_uop_vpu_vlmul,
  input          io_in_bits_uop_vpu_vm,
  input  [7:0]   io_in_bits_uop_vpu_vstart,
  input  [6:0]   io_in_bits_uop_vpu_vuopIdx,
  input          io_in_bits_uop_vpu_lastUop,
  input  [2:0]   io_in_bits_uop_vpu_nf,
  input  [1:0]   io_in_bits_uop_vpu_veew,
  input  [7:0]   io_in_bits_uop_pdest,
  input          io_in_bits_uop_robIdx_flag,
  input  [7:0]   io_in_bits_uop_robIdx_value,
  input  [63:0]  io_in_bits_uop_debugInfo_enqRsTime,
  input  [63:0]  io_in_bits_uop_debugInfo_selectTime,
  input  [63:0]  io_in_bits_uop_debugInfo_issueTime,
  input          io_in_bits_uop_lqIdx_flag,
  input  [6:0]   io_in_bits_uop_lqIdx_value,
  input          io_in_bits_uop_sqIdx_flag,
  input  [5:0]   io_in_bits_uop_sqIdx_value,
  input  [127:0] io_in_bits_src_0,
  input  [127:0] io_in_bits_src_1,
  input  [127:0] io_in_bits_src_2,
  input  [127:0] io_in_bits_src_3,
  input  [127:0] io_in_bits_src_4,
  output         io_uopwriteback_valid,
  output         io_uopwriteback_bits_uop_exceptionVec_3,
  output         io_uopwriteback_bits_uop_exceptionVec_5,
  output         io_uopwriteback_bits_uop_exceptionVec_7,
  output         io_uopwriteback_bits_uop_exceptionVec_13,
  output         io_uopwriteback_bits_uop_exceptionVec_15,
  output         io_uopwriteback_bits_uop_exceptionVec_19,
  output         io_uopwriteback_bits_uop_exceptionVec_21,
  output         io_uopwriteback_bits_uop_exceptionVec_23,
  output [3:0]   io_uopwriteback_bits_uop_trigger,
  output [8:0]   io_uopwriteback_bits_uop_fuOpType,
  output         io_uopwriteback_bits_uop_vecWen,
  output         io_uopwriteback_bits_uop_v0Wen,
  output         io_uopwriteback_bits_uop_vlWen,
  output         io_uopwriteback_bits_uop_vpu_vma,
  output         io_uopwriteback_bits_uop_vpu_vta,
  output [1:0]   io_uopwriteback_bits_uop_vpu_vsew,
  output [2:0]   io_uopwriteback_bits_uop_vpu_vlmul,
  output         io_uopwriteback_bits_uop_vpu_vm,
  output [7:0]   io_uopwriteback_bits_uop_vpu_vstart,
  output [6:0]   io_uopwriteback_bits_uop_vpu_vuopIdx,
  output [127:0] io_uopwriteback_bits_uop_vpu_vmask,
  output [7:0]   io_uopwriteback_bits_uop_vpu_vl,
  output [2:0]   io_uopwriteback_bits_uop_vpu_nf,
  output [1:0]   io_uopwriteback_bits_uop_vpu_veew,
  output [7:0]   io_uopwriteback_bits_uop_pdest,
  output         io_uopwriteback_bits_uop_robIdx_flag,
  output [7:0]   io_uopwriteback_bits_uop_robIdx_value,
  output [63:0]  io_uopwriteback_bits_uop_debugInfo_enqRsTime,
  output [63:0]  io_uopwriteback_bits_uop_debugInfo_selectTime,
  output [63:0]  io_uopwriteback_bits_uop_debugInfo_issueTime,
  output [127:0] io_uopwriteback_bits_data,
  output [2:0]   io_uopwriteback_bits_vdIdx,
  output [2:0]   io_uopwriteback_bits_vdIdxInField,
  output         io_uopwriteback_bits_debug_isMMIO,
  output         io_uopwriteback_bits_debug_isNCIO,
  output         io_uopwriteback_bits_debug_isPerfCnt,
  input          io_csrCtrl_cache_error_enable,
  input          io_rdcache_req_ready,
  output         io_rdcache_req_valid,
  output [49:0]  io_rdcache_req_bits_vaddr,
  output [49:0]  io_rdcache_req_bits_vaddr_dup,
  input          io_rdcache_resp_valid,
  input  [127:0] io_rdcache_resp_bits_data_delayed,
  input          io_rdcache_resp_bits_miss,
  input          io_rdcache_resp_bits_error_delayed,
  output         io_rdcache_is128Req,
  output [47:0]  io_rdcache_s1_paddr_dup_lsu,
  output [47:0]  io_rdcache_s1_paddr_dup_dcache,
  input          io_rdcache_s2_bank_conflict,
  input          io_sbuffer_ready,
  // io_sbuffer_valid / io_sbuffer_bits_* 由 pipe io_out_* 直连(wrapper 里接), 不经核。
  output         io_dtlb_req_valid,
  output [49:0]  io_dtlb_req_bits_vaddr,
  output [63:0]  io_dtlb_req_bits_fullva,
  output [2:0]   io_dtlb_req_bits_cmd,
  output         io_dtlb_req_bits_debug_robIdx_flag,
  output [7:0]   io_dtlb_req_bits_debug_robIdx_value,
  input          io_dtlb_resp_valid,
  input  [47:0]  io_dtlb_resp_bits_paddr_0,
  input  [63:0]  io_dtlb_resp_bits_gpaddr_0,
  input  [63:0]  io_dtlb_resp_bits_fullva,
  input  [1:0]   io_dtlb_resp_bits_pbmt_0,
  input          io_dtlb_resp_bits_miss,
  input          io_dtlb_resp_bits_isForVSnonLeafPTE,
  input          io_dtlb_resp_bits_excp_0_gpf_ld,
  input          io_dtlb_resp_bits_excp_0_gpf_st,
  input          io_dtlb_resp_bits_excp_0_pf_ld,
  input          io_dtlb_resp_bits_excp_0_pf_st,
  input          io_dtlb_resp_bits_excp_0_af_ld,
  input          io_dtlb_resp_bits_excp_0_af_st,
  input          io_pmpResp_ld,
  input          io_pmpResp_st,
  input          io_pmpResp_instr,
  input          io_pmpResp_mmio,
  input          io_pmpResp_atomic,
  output         io_flush_sbuffer_valid,
  input          io_flush_sbuffer_empty,
  output         io_feedback_valid,
  output         io_feedback_bits_sqIdx_flag,
  output [5:0]   io_feedback_bits_sqIdx_value,
  output         io_feedback_bits_lqIdx_flag,
  output [6:0]   io_feedback_bits_lqIdx_value,
  output         io_exceptionInfo_valid,
  output [63:0]  io_exceptionInfo_bits_vaddr,
  output [49:0]  io_exceptionInfo_bits_gpaddr,
  output         io_exceptionInfo_bits_isForVSnonLeafPTE,
  // ---- segmentTrigger(VSegmentTrigger) glue ----
  input  [3:0]   seg_trig_action,       // <- tdataVec_io_toLoadStore_triggerAction
  output [49:0]  seg_trig_vaddr,        // -> tdataVec_io_fromLoadStore_vaddr (=dcacheReqVaddr)
  output         seg_trig_memType,      // -> tdataVec_io_memType (=instMicroOp_isVSegLoad)
  // ---- VSegmentUnitPipelineConnect(NewPipelineConnectPipe_31) glue ----
  input          pc_in_ready,           // <- pipe io_in_ready
  input          pc_out_valid,          // <- pipe io_out_valid
  output         pc_in_valid,           // -> pipe io_in_valid
  output [49:0]  pc_in_bits_vaddr,      // -> pipe io_in_bits_vaddr
  output [127:0] pc_in_bits_data,       // -> pipe io_in_bits_data
  output [15:0]  pc_in_bits_mask,       // -> pipe io_in_bits_mask
  output [47:0]  pc_in_bits_addr,       // -> pipe io_in_bits_addr
  output         pc_in_bits_vecValid,   // -> pipe io_in_bits_vecValid
  output         pc_rightOutFire        // -> pipe io_rightOutFire
);

  // ============================================================
  // 寄存器声明(与 golden 同名/同宽)
  // ============================================================
  reg  [63:0]  nextBaseVaddr_r;
  reg  [63:0]  instMicroOp_baseVaddr;
  reg          instMicroOp_uop_exceptionVec_3;
  reg          instMicroOp_uop_exceptionVec_5;
  reg          instMicroOp_uop_exceptionVec_7;
  reg          instMicroOp_uop_exceptionVec_13;
  reg          instMicroOp_uop_exceptionVec_15;
  reg          instMicroOp_uop_exceptionVec_19;
  reg          instMicroOp_uop_exceptionVec_21;
  reg          instMicroOp_uop_exceptionVec_23;
  reg  [3:0]   instMicroOp_uop_trigger;
  reg  [8:0]   instMicroOp_uop_fuOpType;
  reg          instMicroOp_uop_vpu_vma;
  reg          instMicroOp_uop_vpu_vta;
  reg  [1:0]   instMicroOp_uop_vpu_vsew;
  reg  [2:0]   instMicroOp_uop_vpu_vlmul;
  reg          instMicroOp_uop_vpu_vm;
  reg  [7:0]   instMicroOp_uop_vpu_vstart;
  reg  [2:0]   instMicroOp_uop_vpu_nf;
  reg  [1:0]   instMicroOp_uop_vpu_veew;
  reg          instMicroOp_uop_robIdx_flag;
  reg  [7:0]   instMicroOp_uop_robIdx_value;
  reg  [47:0]  instMicroOp_paddr;
  reg  [127:0] instMicroOp_mask;
  reg  [2:0]   instMicroOp_alignedType;
  reg  [7:0]   instMicroOp_vl;
  reg  [7:0]   instMicroOp_uopFlowNumMask;
  reg          instMicroOp_isVSegLoad;
  reg          instMicroOp_isVSegStore;
  reg  [63:0]  instMicroOp_exceptionVaddr;
  reg  [63:0]  instMicroOp_exceptionGpaddr;
  reg          instMicroOp_exceptionIsForVSnonLeafPTE;
  reg  [7:0]   instMicroOp_exceptionVstart;
  reg          instMicroOp_exceptionVl_valid;
  reg  [7:0]   instMicroOp_exceptionVl_bits;
  reg          instMicroOp_isFof;
  reg          instMicroOpValid;

  // 8 深数据/uopq/stride 队列(golden data_0..7 / uopq_0..7_* / stride_0..7)
  reg  [127:0] data      [0:7];
  reg          uopq_vecWen [0:7];
  reg          uopq_v0Wen  [0:7];
  reg          uopq_vlWen  [0:7];
  reg  [6:0]   uopq_vpu_vuopIdx [0:7];
  reg  [7:0]   uopq_pdest [0:7];
  reg  [63:0]  uopq_debugInfo_enqRsTime  [0:7];
  reg  [63:0]  uopq_debugInfo_selectTime [0:7];
  reg  [63:0]  uopq_debugInfo_issueTime  [0:7];
  reg          uopq_lqIdx_flag  [0:7];
  reg  [6:0]   uopq_lqIdx_value [0:7];
  reg          uopq_sqIdx_flag  [0:7];
  reg  [5:0]   uopq_sqIdx_value [0:7];
  reg  [127:0] stride [0:7];

  reg          enqPtr_flag;
  reg  [2:0]   enqPtr_value;
  reg          deqPtr_flag;
  reg  [2:0]   deqPtr_value;
  reg  [2:0]   stridePtrReg_value;
  reg  [7:0]   segmentIdx;
  reg  [3:0]   fieldIdx;
  reg  [63:0]  segmentOffset;
  reg          splitPtr_flag;
  reg  [2:0]   splitPtr_value;
  reg  [49:0]  latchVaddr;
  reg  [49:0]  latchVaddrDup;

  reg  [8:0]   fofBuffer_fuOpType;
  reg          fofBuffer_vecWen;
  reg          fofBuffer_v0Wen;
  reg          fofBuffer_vlWen;
  reg          fofBuffer_vpu_vma;
  reg          fofBuffer_vpu_vta;
  reg  [1:0]   fofBuffer_vpu_vsew;
  reg  [2:0]   fofBuffer_vpu_vlmul;
  reg          fofBuffer_vpu_vm;
  reg  [7:0]   fofBuffer_vpu_vstart;
  reg  [6:0]   fofBuffer_vpu_vuopIdx;
  reg  [2:0]   fofBuffer_vpu_nf;
  reg  [1:0]   fofBuffer_vpu_veew;
  reg  [7:0]   fofBuffer_pdest;
  reg          fofBuffer_robIdx_flag;
  reg  [7:0]   fofBuffer_robIdx_value;
  reg  [63:0]  fofBuffer_debugInfo_enqRsTime;
  reg  [63:0]  fofBuffer_debugInfo_selectTime;
  reg  [63:0]  fofBuffer_debugInfo_issueTime;
  reg          fofBufferValid;
  reg  [3:0]   state;
  reg          curPtr;
  reg          isMisalignReg;
  reg          notCross16ByteReg;
  reg  [63:0]  combinedData;
  reg  [47:0]  lowPagePaddr;
  reg          last_REG;
  reg          instMicroOp_uop_exceptionVec_19_last_REG;

  // 输出流水寄存器(io_uopwriteback / io_feedback 的 REG 级)
  reg          io_uopwriteback_valid_REG;
  reg          wb_uop_exceptionVec_3;
  reg          wb_uop_exceptionVec_5;
  reg          wb_uop_exceptionVec_7;
  reg          wb_uop_exceptionVec_13;
  reg          wb_uop_exceptionVec_15;
  reg          wb_uop_exceptionVec_19;
  reg          wb_uop_exceptionVec_21;
  reg          wb_uop_exceptionVec_23;
  reg  [3:0]   wb_uop_trigger;
  reg  [8:0]   wb_uop_fuOpType;
  reg          wb_uop_vecWen;
  reg          wb_uop_v0Wen;
  reg          wb_uop_vlWen;
  reg          wb_uop_vpu_vma;
  reg          wb_uop_vpu_vta;
  reg  [1:0]   wb_uop_vpu_vsew;
  reg  [2:0]   wb_uop_vpu_vlmul;
  reg          wb_uop_vpu_vm;
  reg  [7:0]   wb_uop_vpu_vstart;
  reg  [6:0]   wb_uop_vpu_vuopIdx;
  reg  [127:0] wb_uop_vpu_vmask;
  reg  [7:0]   wb_uop_vpu_vl;
  reg  [2:0]   wb_uop_vpu_nf;
  reg  [1:0]   wb_uop_vpu_veew;
  reg  [7:0]   wb_uop_pdest;
  reg          wb_uop_robIdx_flag;
  reg  [7:0]   wb_uop_robIdx_value;
  reg  [63:0]  wb_uop_debugInfo_enqRsTime;
  reg  [63:0]  wb_uop_debugInfo_selectTime;
  reg  [63:0]  wb_uop_debugInfo_issueTime;
  reg  [127:0] wb_data;
  reg  [2:0]   wb_vdIdx;
  reg  [2:0]   wb_vdIdxInField;
  reg          io_feedback_valid_REG;
  reg          fb_sqIdx_flag;
  reg  [5:0]   fb_sqIdx_value;
  reg          fb_lqIdx_flag;
  reg  [6:0]   fb_lqIdx_value;

  // ============================================================
  // 组合逻辑(与 golden 一致, 命名尽量沿用 golden)
  // ============================================================
  wire         sbufferOut_valid;
  wire         io_rdcache_req_valid_0;
  wire         exception_pa;
  wire         exception_gpa;
  wire         exception_va;
  wire         canHandleMisalign_T_3;
  wire         canHandleMisalign_T;
  wire         isMisalignWire;
  wire         notCross16ByteWire;

  wire [7:0]   maxSegIdx = 8'(instMicroOp_vl - 8'h1);
  wire         segIdxOverflow  = segmentIdx > maxSegIdx & instMicroOpValid;      // golden _GEN
  wire [3:0]   nf_ext          = {1'h0, instMicroOp_uop_vpu_nf};                  // golden _GEN_0
  wire         fieldIdxOverflow= fieldIdx > nf_ext & instMicroOpValid;           // golden _GEN_1
  wire [2:0]   veew_ext        = {1'h0, instMicroOp_uop_vpu_veew};               // golden _GEN_2
  wire [2:0]   vsew_ext        = {1'h0, instMicroOp_uop_vpu_vsew};               // golden _GEN_3
  wire [2:0]   issueEmul       = 3'(3'(veew_ext - vsew_ext) + instMicroOp_uop_vpu_vlmul);

  // issueIndexIdx: golden segmentIdx & ((1<< (max(issueEmul,0)-4)-veew) - 1)
  wire [2:0]   issueEmulSat    = $signed(issueEmul) > 3'sh0 ? 3'h0 : issueEmul;
  wire [7:0]   issueIndexIdx   =
    segmentIdx & 8'((8'h1 << 3'(3'(issueEmulSat - 3'h4) - veew_ext)) - 8'h1);

  wire [255:0] segmentActive_T = 256'h1 << segmentIdx;
  wire [127:0] segMaskActive   = segmentActive_T[127:0] & instMicroOp_mask;      // golden _GEN_4
  wire         segMaskAny      = |segMaskActive;

  wire         isFof_T         = io_in_bits_uop_fuOpType == 9'h90;
  wire         isEnqFixVlUop   = isFof_T & io_in_valid & io_in_bits_uop_vpu_lastUop;

  // 状态判定
  wire         st_is4  = state == S_TLB_RESP;
  wire         st_is5  = state == S_PMP;
  wire         st_is7  = state == S_CACHE_RESP;
  wire         st_is8  = state == S_MISALIGN;
  wire         st_isD  = state == S_FOF;
  wire         crossMisalign = isMisalignReg & ~notCross16ByteReg;               // golden _GEN_7
  wire         crossMisalignLow = crossMisalign & ~curPtr;                       // golden _GEN_8
  wire         segMaxHit = segmentIdx == maxSegIdx;                              // golden _GEN_11
  wire         fieldMaxHit = fieldIdx == nf_ext;                                 // golden _GEN_12
  wire         segFinishNoActive = segMaxHit & ~segMaskAny;                      // golden _GEN_13
  wire         fieldWriteFire_pre = pc_in_ready & sbufferOut_valid;             // golden _GEN_14

  // 入队差计数(golden _GEN_17[3] 分支)
  wire [3:0]   queueDiff =
    (enqPtr_flag == deqPtr_flag)
      ? {1'h0, 3'(enqPtr_value - deqPtr_value)}
      : 4'(4'({1'h0, enqPtr_value} - 4'h8) - {1'h0, deqPtr_value});

  wire [3:0]   fofStateNext = st_isD & fofBufferValid ? S_FOF : S_IDLE;         // golden _GEN_16

  // stateNext: golden _GEN_17[state] 逐 state 译码
  reg  [3:0]   stateDecoded;
  always_comb begin
    case (state)
      S_IDLE:      stateDecoded = fofStateNext;                    // [0]
      S_FLUSH:     stateDecoded = {3'h1, io_flush_sbuffer_empty};  // [1]
      S_FIRST:     stateDecoded = {3'h1, io_flush_sbuffer_empty};  // [2]
      S_TLB_REQ:   stateDecoded = segMaskAny ? S_TLB_RESP          // [3] _GEN_17[3]
                     : (instMicroOp_isVSegLoad ? S_LD_FINISH : S_ST_FINISH);
      S_TLB_RESP:  stateDecoded = io_dtlb_resp_valid                // [4]
                     ? (io_dtlb_resp_bits_miss ? S_TLB_REQ : S_PMP) : S_TLB_RESP;
      S_PMP:       stateDecoded =                                   // [5]
        (exception_pa | exception_va | exception_gpa)
          ? S_WB
          : (st_is5 & canHandleMisalign_T
             & (|seg_trig_action) & canHandleMisalign_T_3
             & isMisalignWire & ~notCross16ByteWire | crossMisalignLow
             & instMicroOp_isVSegStore)
              ? S_TLB_REQ
              : (instMicroOp_isVSegLoad ? S_CACHE_REQ : S_ST_FINISH);
      S_CACHE_REQ: stateDecoded = {3'h3, io_rdcache_req_ready & io_rdcache_req_valid_0}; // [6]
      S_CACHE_RESP:stateDecoded = io_rdcache_resp_valid              // [7]
        ? (io_rdcache_resp_bits_miss | io_rdcache_s2_bank_conflict
             ? S_CACHE_REQ
             : io_rdcache_resp_bits_error_delayed & last_REG
                 ? S_WB
                 : instMicroOp_isVSegLoad
                     ? {3'h4, ~(isMisalignReg & ~notCross16ByteReg)}
                     : S_ST_FINISH)
        : S_CACHE_RESP;
      S_MISALIGN:  stateDecoded = curPtr ? S_LD_FINISH : S_TLB_REQ;  // [8]
      S_LD_FINISH: stateDecoded =                                    // [9] _GEN_17[9]
        segMaxHit & fieldMaxHit | segFinishNoActive ? S_WB : S_TLB_REQ;
      S_ST_FINISH: stateDecoded =                                    // [A]
        ~fieldWriteFire_pre & segMaskAny | crossMisalignLow
          ? S_ST_FINISH
          : segMaxHit
            & (fieldMaxHit & fieldWriteFire_pre | ~segMaskAny & pc_out_valid & ~io_sbuffer_ready)
              ? S_LAT
              : segFinishNoActive ? S_WB : S_TLB_REQ;
      S_LAT:       stateDecoded =                                    // [B]
        io_sbuffer_ready & pc_out_valid ? S_WB : S_LAT;
      S_WB:        stateDecoded = queueDiff == 4'h0                  // [C]
                     ? (fofBufferValid ? S_FOF : S_IDLE) : S_WB;
      S_FOF:       stateDecoded = fofStateNext;                      // [D]
      default:     stateDecoded = fofStateNext;                     // [E]/[F]
    endcase
  end
  wire [3:0]   stateNext_active = stateDecoded;                              // golden _GEN_18
  // golden _stateNext_T_1: idle 起步 => 队列非空(fof 之类)则进 store finish
  wire [3:0]   stateNextIdle = {3'h0, enqPtr_flag ^ deqPtr_flag ^ enqPtr_value > deqPtr_value};
  wire [3:0]   stateNext = (|state) ? stateNext_active : stateNextIdle;

  // emul(入队时): golden _emul_T_3
  wire [2:0]   emul_in = 3'(3'({1'h0, io_in_bits_uop_vpu_veew} - {1'h0, io_in_bits_uop_vpu_vsew})
                            + io_in_bits_uop_vpu_vlmul);
  wire         enqNew         = io_in_valid & ~instMicroOpValid;   // golden _GEN_19
  wire         enqNewNotFixVl = enqNew & ~isEnqFixVlUop;           // golden _GEN_20
  wire         enqValidNotFixVl = io_in_valid & ~isEnqFixVlUop;    // golden _GEN_21

  // 索引偏移地址(indexed load/store): stride[stridePtrReg] 按 issueIndexIdx 与 veew 取。
  // golden 显式枚举 issueIndexIdx 有效范围(veew=0:0..15, =1:0..7, =2:0..3, =3:0..1),
  // 越界给 0(不用变量 part-select, 避免 OOB X)。
  wire [127:0] strideSel = stride[stridePtrReg_value];             // golden _GEN_23
  reg  [63:0]  indexOffset;
  always_comb begin
    logic [7:0]  e8;
    logic [15:0] e16;
    logic [31:0] e32;
    logic [63:0] e64;
    e8 = 8'h0; e16 = 16'h0; e32 = 32'h0; e64 = 64'h0;
    for (int j = 0; j < 16; j++) if (issueIndexIdx == j[7:0]) e8  = strideSel[8*j  +: 8];
    for (int j = 0; j < 8;  j++) if (issueIndexIdx == j[7:0]) e16 = strideSel[16*j +: 16];
    for (int j = 0; j < 4;  j++) if (issueIndexIdx == j[7:0]) e32 = strideSel[32*j +: 32];
    for (int j = 0; j < 2;  j++) if (issueIndexIdx == j[7:0]) e64 = strideSel[64*j +: 64];
    indexOffset = 64'h0;
    case (instMicroOp_uop_vpu_veew)
      2'h0: indexOffset = {56'h0, e8};
      2'h1: indexOffset = {48'h0, e16};
      2'h2: indexOffset = {32'h0, e32};
      2'h3: indexOffset = e64;
    endcase
  end
  // golden _vaddr_T: indexed(fuOpType[5]) => baseVaddr + indexOffset, 否则 + segmentOffset
  wire [63:0]  vaddr_flow = 64'(nextBaseVaddr_r
                     + (instMicroOp_uop_fuOpType[5] ? indexOffset : segmentOffset));

  wire [46:0]  misalignAddrHi = curPtr ? 47'(latchVaddr[49:3] + 47'h1) : latchVaddr[49:3]; // _GEN_24
  wire [63:0]  tlbReqVaddr    = isMisalignReg ? {14'h0, misalignAddrHi, 3'h0} : vaddr_flow;
  wire         dtlbReq_T      = state == S_TLB_REQ;
  wire [49:0]  dcacheReqVaddr = isMisalignReg ? {misalignAddrHi, 3'h0} : latchVaddr;
  wire         triggerDebugMode = seg_trig_action == 4'h1;

  wire         dtlbResp5 = io_dtlb_resp_valid & st_is4;            // golden _GEN_25
  wire         exception_va_T = instMicroOp_uop_exceptionVec_15 | instMicroOp_uop_exceptionVec_13;
  wire [3:0]   pmp_T = {io_pmpResp_ld, io_pmpResp_st, io_pmpResp_instr, io_pmpResp_mmio}
                     & {4{~(exception_va_T | instMicroOp_uop_exceptionVec_23
                            | instMicroOp_uop_exceptionVec_21)}};
  // 高地址位(判非对齐/跨16B): indexed 用 vsew, 否则 veew
  wire [1:0]   highAddr_ew = instMicroOp_uop_fuOpType[5] ? instMicroOp_uop_vpu_vsew : instMicroOp_uop_vpu_veew;
  wire [4:0]   highAddr_hi =
    5'({2'h0, {1'h0, {1'h0, highAddr_ew == 2'h1} | {2{highAddr_ew == 2'h2}}} | {3{&highAddr_ew}}}
       + vaddr_flow[4:0]);
  wire [1:0]   alignEw = instMicroOp_uop_fuOpType[5] ? instMicroOp_uop_vpu_vsew : instMicroOp_uop_vpu_veew;
  assign notCross16ByteWire = st_is5 & highAddr_hi[4] == vaddr_flow[4];
  assign isMisalignWire =
    st_is5
    & ~(alignEw == 2'h0 | alignEw == 2'h1 & ~vaddr_flow[0]
        | alignEw == 2'h2 & vaddr_flow[1:0] == 2'h0 | (&alignEw) & vaddr_flow[2:0] == 3'h0)
    & ~isMisalignReg;
  assign canHandleMisalign_T   = ~pmp_T[0];
  assign canHandleMisalign_T_3 = ~triggerDebugMode;
  assign exception_va =
    st_is5 & (exception_va_T | instMicroOp_uop_exceptionVec_7 | instMicroOp_uop_exceptionVec_5
              | ~(|seg_trig_action) | triggerDebugMode | pmp_T[0]);
  assign exception_gpa = st_is5 & (instMicroOp_uop_exceptionVec_23 | instMicroOp_uop_exceptionVec_21);
  wire         exceptionAny = exception_va | exception_gpa | exception_pa;      // golden _GEN_26
  wire         canTriggerException = segmentIdx == 8'h0 | ~instMicroOp_isFof;
  wire         pmpExcTriggered = st_is5 & exceptionAny;                          // golden _GEN_80
  wire         misalignSet = st_is5 & isMisalignWire & ~exceptionAny;            // golden _GEN_100
  wire         wbState      = state == S_WB;                                     // _io_exceptionInfo_valid_T
  wire         segInactive9 = state == S_LD_FINISH;                              // _segmentInactiveFinish_T
  wire         segInactiveA = state == S_ST_FINISH;                              // _segmentInactiveFinish_T_1
  wire         stateNextNotA = stateNext != S_ST_FINISH;
  wire         stFinishLeave = segInactiveA & stateNextNotA;                     // golden _GEN_27
  wire         cacheHit7 = st_is7 & io_rdcache_resp_valid & ~io_rdcache_resp_bits_miss
                          & ~io_rdcache_s2_bank_conflict;                        // golden _GEN_28
  assign exception_pa =
    cacheHit7 ? instMicroOp_uop_exceptionVec_19 : st_is5 & (pmp_T[2] | pmp_T[3] | pmp_T[0]);

  // ---- store 侧数据切片/排列(splitData / flowData / mergedData) ----
  wire [127:0] splitEntry = data[splitPtr_value];                               // golden _GEN_30
  wire [3:0]   splitIdx8  = segmentIdx[3:0] & instMicroOp_uopFlowNumMask[3:0];   // golden _splitData_T
  wire [2:0]   splitIdx16 = segmentIdx[2:0] & instMicroOp_uopFlowNumMask[2:0];
  wire [1:0]   splitIdx32 = segmentIdx[1:0] & instMicroOp_uopFlowNumMask[1:0];
  wire         splitIdx64 = segmentIdx[0]   & instMicroOp_uopFlowNumMask[0];
  wire         segFinishActive = segInactive9 & segMaskAny;                      // golden _GEN_31
  // splitData: 从 splitEntry 抽出当前段/eew 对应元素(低位, 高位补 0)
  reg  [127:0] splitData;
  always_comb begin
    case (instMicroOp_alignedType)
      3'h0: splitData = {120'h0, splitEntry[8*splitIdx8  +: 8]};
      3'h1: splitData = {112'h0, splitEntry[16*splitIdx16 +: 16]};
      3'h2: splitData = {96'h0,  splitEntry[32*splitIdx32 +: 32]};
      3'h3: splitData = {64'h0,  splitEntry[64*splitIdx64 +: 64]};
      3'h4: splitData = splitEntry;
      default: splitData = 128'h0;
    endcase
  end
  // flowData: 把元素复制填满 128 位(golden 的 {2{...}} 复制)
  reg  [127:0] flowData;
  always_comb begin
    case (instMicroOp_alignedType)
      3'h0: flowData = {16{splitData[7:0]}};
      3'h1: flowData = {8{splitData[15:0]}};
      3'h2: flowData = {4{splitData[31:0]}};
      3'h3: flowData = {2{splitData[63:0]}};
      3'h4: flowData = splitData;
      default: flowData = 128'h0;
    endcase
  end
  // wmask: golden _wmask_T_13 << latchVaddr[3:0], 再与 |segMaskActive
  wire [7:0]   eByteMask =
    {1'h0, ~(|instMicroOp_alignedType[1:0])} | {2{instMicroOp_alignedType[1:0] == 2'h1}}
    | {4{instMicroOp_alignedType[1:0] == 2'h2}} | {8{&instMicroOp_alignedType[1:0]}};
  wire [22:0]  wmask_T = {15'h0, eByteMask} << latchVaddr[3:0];
  wire [22:0]  wmask   = {7'h0, wmask_T[15:0] & {16{segMaskAny}}};
  wire [47:0]  dcacheReqPaddr =
    isMisalignReg ? {instMicroOp_paddr[47:12], misalignAddrHi[8:0], 3'h0} : instMicroOp_paddr;
  assign io_rdcache_req_valid_0 = state == S_CACHE_REQ & instMicroOp_isVSegLoad;
  // 跨16B store 数据/掩码
  wire [254:0] flowData_ext = {127'h0, flowData};
  wire [254:0] flowData_shift = {248'h0, latchVaddr[3:0], 3'h0};
  wire [254:0] notCross16ByteData = flowData_ext << flowData_shift;
  wire [31:0]  Cross16ByteMask =
    {1'h0, {23'h0, {8{segMaskAny}} & {eByteMask}} << latchVaddr[3:0]};
  wire [254:0] Cross16ByteData = flowData_ext << flowData_shift;
  assign sbufferOut_valid = segInactiveA & segMaskAny;
  wire         fieldWriteFireBase = pc_in_ready & sbufferOut_valid;             // _fieldActiveWirteFinish_T
  wire         fieldActiveWirteFinish = fieldWriteFireBase & segMaskAny;
  wire         fieldWriteFinishNoActive = fieldWriteFireBase & ~segMaskAny;     // golden _GEN_34

  wire         segmentInactiveFinish = (segInactive9 | segInactiveA & stateNextNotA) & ~segMaskAny;
  wire         fieldIdxIsMax = fieldIdx == nf_ext;                              // _fieldIdxWire_T
  wire [8:0]   segmentIdxNext = 9'({1'h0, segmentIdx} + 9'h1);                  // _segmentIdxWire_T_2
  wire [3:0]   deqPtrPacked = {deqPtr_flag, deqPtr_value};                      // _io_exceptionInfo_valid_T_5
  wire [3:0]   enqPtrPacked = {enqPtr_flag, enqPtr_value};                      // _io_exceptionInfo_valid_T_4
  wire         stFinishFieldFire = stFinishLeave & fieldActiveWirteFinish;      // golden _GEN_35
  wire         advanceField = segFinishActive | stFinishFieldFire;             // golden _GEN_36
  wire [3:0]   fieldIdxNext = 4'(fieldIdx + 4'h1);
  wire         fieldWrapCond = fieldIdxIsMax & (segInactive9 | stFinishFieldFire); // golden _GEN_37
  wire         segNotMax = segmentIdx != maxSegIdx;                             // golden _GEN_38
  wire         fofFixVlValid = state == S_FOF & fofBufferValid;

  wire         writebackValid = wbState & enqPtrPacked != deqPtrPacked | fofFixVlValid;
  wire [7:0]   excVec = {instMicroOp_uop_exceptionVec_23, instMicroOp_uop_exceptionVec_21,
                         instMicroOp_uop_exceptionVec_19, instMicroOp_uop_exceptionVec_15,
                         instMicroOp_uop_exceptionVec_13, instMicroOp_uop_exceptionVec_7,
                         instMicroOp_uop_exceptionVec_5,  instMicroOp_uop_exceptionVec_3};
  wire         feedbackValid = wbState & enqPtrPacked != deqPtrPacked;

  // uopFlowNum(入队时算 uopFlowNumMask)
  wire [4:0]   segFlowNum =
    {io_in_bits_uop_vpu_vlmul == 3'h0 | io_in_bits_uop_vpu_vlmul == 3'h1
       | io_in_bits_uop_vpu_vlmul == 3'h2 | io_in_bits_uop_vpu_vlmul == 3'h3,
     &io_in_bits_uop_vpu_vlmul, io_in_bits_uop_vpu_vlmul == 3'h6,
     io_in_bits_uop_vpu_vlmul == 3'h5, 1'h0} >> io_in_bits_uop_vpu_vsew;
  wire         emulIs5 = emul_in == 3'h5;
  wire         emulIs6 = emul_in == 3'h6;
  wire [4:0]   veew_in_ext = {3'h0, io_in_bits_uop_vpu_veew};
  wire         emulLe3 = emul_in == 3'h0 | emul_in == 3'h1 | emul_in == 3'h2 | emul_in == 3'h3;
  wire [4:0]   idxFlowNum = {emulLe3, &emul_in, emulIs6, emulIs5, 1'h0} >> veew_in_ext;

  wire [255:0] vlMask_T    = 256'h1 << instMicroOp_vl;
  wire [255:0] startMask_T = 256'h1 << instMicroOp_uop_vpu_vstart;
  wire         pbmt_nc  = io_dtlb_resp_bits_pbmt_0 == 2'h1;
  wire         pbmt_io  = io_dtlb_resp_bits_pbmt_0 == 2'h2;
  wire [1:0]   realEw   = instMicroOp_uop_fuOpType[5] ? instMicroOp_uop_vpu_vsew : instMicroOp_uop_vpu_veew;

  // ---- maskDataVec: 每 uop(段)对应 16 位掩码, 按 realEw 折叠(golden _GEN_63) ----
  reg  [15:0]  maskDataVec [0:7];
  always_comb begin
    for (int k = 0; k < 8; k++) begin
      logic [15:0] m8;   // eew=8 : 直接取 16 位
      logic [7:0]  m16;  // eew=16: 取 8 位映到偶数位
      logic [3:0]  m32;  // eew=32: 取 4 位
      logic [1:0]  m64;  // eew=64: 取 2 位
      m8  = realEw == 2'h0 ? instMicroOp_mask[16*k +: 16] : 16'h0;
      m16 = m8[7:0] | (realEw == 2'h1 ? instMicroOp_mask[8*k +: 8]  : 8'h0);
      m32 = m16[3:0] | (realEw == 2'h2 ? instMicroOp_mask[4*k +: 4] : 4'h0);
      m64 = m32[1:0] | ((&realEw) ? instMicroOp_mask[2*k +: 2] : 2'h0);
      maskDataVec[k] = {m8[15:8], m16[7:4], m32[3:2], m64};
    end
  end

  // deqPtr 视图取
  wire [6:0]   deqVuopIdx = uopq_vpu_vuopIdx[deqPtr_value];                      // golden _GEN_94
  wire [2:0]   vdIdxInField_ew = io_in_bits_uop_fuOpType[5] ? instMicroOp_uop_vpu_vlmul : issueEmul;
  wire [2:0]   vdIdxInField =
    {1'h0, {1'h0, vdIdxInField_ew == 3'h1 & deqVuopIdx[0]}
       | (vdIdxInField_ew == 3'h2 ? deqVuopIdx[1:0] : 2'h0)}
    | (vdIdxInField_ew == 3'h3 ? deqVuopIdx[2:0] : 3'h0);

  // ---- load 侧 cacheData 抽取(pickData / mergedData) ----
  // 跨16B misalign 路径: 128 位整体右移(golden _shiftData_T_2)。
  wire [127:0] shiftData = io_rdcache_resp_bits_data_delayed >> {121'h0, latchVaddr[3:0], 3'h0};
  // 非 misalign 路径(golden _cacheData_T_56/_GEN_87..92/_pickData_T_8): 两个 64 位半独立
  // 右移后 OR——低半来自 resp[63:0] 右移 latchVaddr*8(latchVaddr>=8 移空), 高半来自
  // resp[127:64] 右移 (latchVaddr-8)*8(latchVaddr<8 不贡献)。★关键: 不是简单 resp>>N
  // ——latchVaddr∈{1..7} 时高字节须为 0(整移会漏入 resp[127:64] 的低位)。
  wire [63:0]  cacheData_lo = io_rdcache_resp_bits_data_delayed[63:0]  >> {latchVaddr[3:0], 3'h0};
  wire [63:0]  cacheData_hi = latchVaddr[3] // latchVaddr[3:0] >= 8
    ? (io_rdcache_resp_bits_data_delayed[127:64] >> {latchVaddr[2:0], 3'h0}) : 64'h0;
  wire [63:0]  cacheData_shift = cacheData_lo | cacheData_hi;
  wire [63:0]  pickData_T =
    isMisalignReg ? (notCross16ByteReg ? shiftData[63:0] : combinedData) : cacheData_shift;
  wire [63:0]  pickData =
    ((|instMicroOp_alignedType[1:0]) ? 64'h0 : {56'h0, pickData_T[7:0]})
    | (instMicroOp_alignedType[1:0] == 2'h1 ? {48'h0, pickData_T[15:0]} : 64'h0)
    | (instMicroOp_alignedType[1:0] == 2'h2 ? {32'h0, pickData_T[31:0]} : 64'h0)
    | ((&instMicroOp_alignedType[1:0]) ? pickData_T : 64'h0);
  // mergedData: 把 pickData 元素写回到 splitEntry 的当前元素位置
  reg  [127:0] mergedData;
  always_comb begin
    logic [127:0] r0, r1, r2, r3;
    r0 = 128'h0; r1 = 128'h0; r2 = 128'h0; r3 = 128'h0;
    for (int e = 0; e < 16; e++)
      r0[8*e +: 8]  = (splitIdx8  == e[3:0]) ? pickData[7:0]  : splitEntry[8*e +: 8];
    for (int e = 0; e < 8; e++)
      r1[16*e +: 16] = (splitIdx16 == e[2:0]) ? pickData[15:0] : splitEntry[16*e +: 16];
    for (int e = 0; e < 4; e++)
      r2[32*e +: 32] = (splitIdx32 == e[1:0]) ? pickData[31:0] : splitEntry[32*e +: 32];
    r3 = {splitIdx64 ? pickData : splitEntry[127:64], splitIdx64 ? splitEntry[63:0] : pickData};
    mergedData =
      ((|instMicroOp_alignedType[1:0]) ? 128'h0 : r0)
      | (instMicroOp_alignedType[1:0] == 2'h1 ? r1 : 128'h0)
      | (instMicroOp_alignedType[1:0] == 2'h2 ? r2 : 128'h0)
      | ((&instMicroOp_alignedType[1:0]) ? r3 : 128'h0);
  end

  // ============================================================
  // 时序块 1: 无 reset 的数据/输出流水更新(golden always @(posedge clock))
  // ============================================================
  wire         enqPtr0 = enqValidNotFixVl & enqPtr_value == 3'h0;                // golden _GEN_72..79
  always @(posedge clock) begin
    if (enqNewNotFixVl) begin
      instMicroOp_baseVaddr    <= io_in_bits_src_0[63:0];
      instMicroOp_uop_fuOpType <= io_in_bits_uop_fuOpType;
      instMicroOp_uop_vpu_vma  <= io_in_bits_uop_vpu_vma;
      instMicroOp_uop_vpu_vta  <= io_in_bits_uop_vpu_vta;
      instMicroOp_uop_vpu_vsew <= io_in_bits_uop_vpu_vsew;
      instMicroOp_uop_vpu_vlmul<= io_in_bits_uop_vpu_vlmul;
      instMicroOp_uop_vpu_vm   <= io_in_bits_uop_vpu_vm;
      instMicroOp_uop_vpu_vstart <= io_in_bits_uop_vpu_vstart;
      instMicroOp_uop_vpu_nf   <= io_in_bits_uop_vpu_nf;
      instMicroOp_uop_vpu_veew <= io_in_bits_uop_vpu_veew;
      instMicroOp_uop_robIdx_flag  <= io_in_bits_uop_robIdx_flag;
      instMicroOp_uop_robIdx_value <= io_in_bits_uop_robIdx_value;
      instMicroOp_mask <=
        (instMicroOp_uop_vpu_vm ? 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF : io_in_bits_src_3)
        & 128'(vlMask_T[127:0] - 128'h1) & ~(128'(startMask_T[127:0] - 128'h1));
      instMicroOp_alignedType <=
        {1'h0, io_in_bits_uop_fuOpType[5] ? io_in_bits_uop_vpu_vsew : io_in_bits_uop_vpu_veew};
      instMicroOp_vl <= io_in_bits_src_4[7:0];
      instMicroOp_uopFlowNumMask <=
        8'({3'h0,
            (io_in_bits_uop_fuOpType[6:5] == 2'h0 ? {emulLe3, &emul_in, emulIs6, emulIs5, 1'h0} >> veew_in_ext : 5'h0)
            | (io_in_bits_uop_fuOpType[6:5] == 2'h2 ? {emulLe3, &emul_in, emulIs6, emulIs5, 1'h0} >> veew_in_ext : 5'h0)
            | (io_in_bits_uop_fuOpType[6:5] == 2'h1 ? segFlowNum : 5'h0)
            | ((&io_in_bits_uop_fuOpType[6:5]) ? segFlowNum : 5'h0)} - 8'h1);
      instMicroOp_isVSegLoad  <= io_in_bits_uop_fuType[33];
      instMicroOp_isVSegStore <= io_in_bits_uop_fuType[34];
      instMicroOp_isFof       <= isFof_T & io_in_bits_uop_fuType[33];
    end
    // 异常向量更新(S_PMP 拍聚合;dtlb 响应拍锁存)
    if (st_is5) begin
      instMicroOp_uop_exceptionVec_3 <= ~(|seg_trig_action) & canTriggerException;
      instMicroOp_uop_exceptionVec_5 <=
        (instMicroOp_uop_exceptionVec_5 | pmp_T[3] | pmp_T[0]) & instMicroOp_isVSegLoad & canTriggerException;
      instMicroOp_uop_exceptionVec_7 <=
        (instMicroOp_uop_exceptionVec_7 | pmp_T[2] | pmp_T[0]) & instMicroOp_isVSegStore & canTriggerException;
      instMicroOp_uop_exceptionVec_13 <= instMicroOp_uop_exceptionVec_13 & instMicroOp_isVSegLoad  & canTriggerException;
      instMicroOp_uop_exceptionVec_15 <= instMicroOp_uop_exceptionVec_15 & instMicroOp_isVSegStore & canTriggerException;
      instMicroOp_uop_exceptionVec_21 <= instMicroOp_uop_exceptionVec_21 & instMicroOp_isVSegLoad  & canTriggerException;
      instMicroOp_uop_exceptionVec_23 <= instMicroOp_uop_exceptionVec_23 & instMicroOp_isVSegStore & canTriggerException;
    end
    else begin
      instMicroOp_uop_exceptionVec_3 <= ~enqNewNotFixVl & instMicroOp_uop_exceptionVec_3;
      if (dtlbResp5) begin
        instMicroOp_uop_exceptionVec_5 <= io_dtlb_resp_bits_excp_0_af_ld | pbmt_nc | pbmt_io;
        instMicroOp_uop_exceptionVec_7 <= io_dtlb_resp_bits_excp_0_af_st | pbmt_nc | pbmt_io;
        instMicroOp_uop_exceptionVec_13 <= io_dtlb_resp_bits_excp_0_pf_ld;
        instMicroOp_uop_exceptionVec_15 <= io_dtlb_resp_bits_excp_0_pf_st;
        instMicroOp_uop_exceptionVec_21 <= io_dtlb_resp_bits_excp_0_gpf_ld;
        instMicroOp_uop_exceptionVec_23 <= io_dtlb_resp_bits_excp_0_gpf_st;
      end
      else begin
        instMicroOp_uop_exceptionVec_5  <= ~enqNewNotFixVl & instMicroOp_uop_exceptionVec_5;
        instMicroOp_uop_exceptionVec_7  <= ~enqNewNotFixVl & instMicroOp_uop_exceptionVec_7;
        instMicroOp_uop_exceptionVec_13 <= ~enqNewNotFixVl & instMicroOp_uop_exceptionVec_13;
        instMicroOp_uop_exceptionVec_15 <= ~enqNewNotFixVl & instMicroOp_uop_exceptionVec_15;
        instMicroOp_uop_exceptionVec_21 <= ~enqNewNotFixVl & instMicroOp_uop_exceptionVec_21;
        instMicroOp_uop_exceptionVec_23 <= ~enqNewNotFixVl & instMicroOp_uop_exceptionVec_23;
      end
    end
    if (cacheHit7)
      instMicroOp_uop_exceptionVec_19 <=
        io_rdcache_resp_bits_error_delayed & instMicroOp_uop_exceptionVec_19_last_REG;
    else
      instMicroOp_uop_exceptionVec_19 <= ~enqNewNotFixVl & instMicroOp_uop_exceptionVec_19;
    if (st_is5 & (instMicroOp_uop_exceptionVec_3 | triggerDebugMode))
      instMicroOp_uop_trigger <= seg_trig_action;
    else if (enqNewNotFixVl)
      instMicroOp_uop_trigger <= 4'h0;
    if (dtlbResp5 & ~io_dtlb_resp_bits_miss) begin
      instMicroOp_paddr <= io_dtlb_resp_bits_paddr_0;
      instMicroOp_exceptionVaddr  <= io_dtlb_resp_bits_fullva;
      instMicroOp_exceptionGpaddr <= io_dtlb_resp_bits_gpaddr_0;
      instMicroOp_exceptionIsForVSnonLeafPTE <= io_dtlb_resp_bits_isForVSnonLeafPTE;
    end
    if (st_is5 & exceptionAny & canTriggerException)
      instMicroOp_exceptionVstart <= segmentIdx;
    instMicroOp_exceptionVl_valid <=
      pmpExcTriggered & ~canTriggerException | ~enqNewNotFixVl & instMicroOp_exceptionVl_valid;
    if (~pmpExcTriggered | canTriggerException) begin
      if (enqNewNotFixVl)
        instMicroOp_exceptionVl_bits <= io_in_bits_src_4[7:0];
    end
    else
      instMicroOp_exceptionVl_bits <= segmentIdx;

    // 8 深 data / uopq / stride 队列写(load 合并 mergedData / 入队 src)
    for (int i = 0; i < 8; i++) begin
      if (segFinishActive & splitPtr_value == i[2:0])
        data[i] <= mergedData;
      else if (enqValidNotFixVl & enqPtr_value == i[2:0])
        data[i] <= io_in_bits_src_2;
    end
    for (int i = 0; i < 8; i++) begin
      if (enqValidNotFixVl & enqPtr_value == i[2:0]) begin
        uopq_vecWen[i] <= io_in_bits_uop_vecWen;
        uopq_v0Wen[i]  <= io_in_bits_uop_v0Wen;
        uopq_vlWen[i]  <= io_in_bits_uop_vlWen;
        uopq_vpu_vuopIdx[i] <= io_in_bits_uop_vpu_vuopIdx;
        uopq_pdest[i]  <= io_in_bits_uop_pdest;
        uopq_debugInfo_enqRsTime[i]  <= io_in_bits_uop_debugInfo_enqRsTime;
        uopq_debugInfo_selectTime[i] <= io_in_bits_uop_debugInfo_selectTime;
        uopq_debugInfo_issueTime[i]  <= io_in_bits_uop_debugInfo_issueTime;
        uopq_lqIdx_flag[i]  <= io_in_bits_uop_lqIdx_flag;
        uopq_lqIdx_value[i] <= io_in_bits_uop_lqIdx_value;
        uopq_sqIdx_flag[i]  <= io_in_bits_uop_sqIdx_flag;
        uopq_sqIdx_value[i] <= io_in_bits_uop_sqIdx_value;
        stride[i] <= io_in_bits_src_1;
      end
    end

    // 写回流水寄存器
    io_uopwriteback_valid_REG <= writebackValid;
    if (writebackValid) begin
      wb_uop_exceptionVec_3  <= ~fofFixVlValid & instMicroOp_uop_exceptionVec_3;
      wb_uop_exceptionVec_5  <= ~fofFixVlValid & instMicroOp_uop_exceptionVec_5;
      wb_uop_exceptionVec_7  <= ~fofFixVlValid & instMicroOp_uop_exceptionVec_7;
      wb_uop_exceptionVec_13 <= ~fofFixVlValid & instMicroOp_uop_exceptionVec_13;
      wb_uop_exceptionVec_15 <= ~fofFixVlValid & instMicroOp_uop_exceptionVec_15;
      wb_uop_exceptionVec_19 <= ~fofFixVlValid & instMicroOp_uop_exceptionVec_19;
      wb_uop_exceptionVec_21 <= ~fofFixVlValid & instMicroOp_uop_exceptionVec_21;
      wb_uop_exceptionVec_23 <= ~fofFixVlValid & instMicroOp_uop_exceptionVec_23;
      wb_uop_trigger  <= fofFixVlValid ? 4'h0 : instMicroOp_uop_trigger;
      wb_uop_fuOpType <= fofFixVlValid ? fofBuffer_fuOpType : instMicroOp_uop_fuOpType;
      wb_uop_vecWen   <= fofFixVlValid ? fofBuffer_vecWen : uopq_vecWen[deqPtr_value];
      wb_uop_v0Wen    <= fofFixVlValid ? fofBuffer_v0Wen  : uopq_v0Wen[deqPtr_value];
      wb_uop_vlWen    <= fofFixVlValid ? fofBuffer_vlWen  : uopq_vlWen[deqPtr_value];
      wb_uop_vpu_vma  <= fofFixVlValid ? fofBuffer_vpu_vma : instMicroOp_uop_vpu_vma;
      wb_uop_vpu_vta  <= fofFixVlValid ? fofBuffer_vpu_vta
                          : ~instMicroOp_exceptionVl_valid & instMicroOp_uop_vpu_vta;
      wb_uop_vpu_vsew <= fofFixVlValid ? fofBuffer_vpu_vsew : instMicroOp_uop_vpu_vsew;
      wb_uop_vpu_vlmul<= fofFixVlValid ? fofBuffer_vpu_vlmul : instMicroOp_uop_vpu_vlmul;
      wb_uop_vpu_vm   <= fofFixVlValid ? fofBuffer_vpu_vm : instMicroOp_uop_vpu_vm;
      wb_uop_vpu_vstart <= fofFixVlValid ? fofBuffer_vpu_vstart
                            : (|excVec) | instMicroOp_uop_trigger == 4'h1
                                ? instMicroOp_exceptionVstart : 8'h0;
      wb_uop_vpu_vuopIdx <= fofFixVlValid ? fofBuffer_vpu_vuopIdx : deqVuopIdx;
      wb_uop_vpu_vmask <= fofFixVlValid
                            ? 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                            : {112'h0, maskDataVec[vdIdxInField]};
      wb_uop_vpu_vl   <= fofFixVlValid | instMicroOp_exceptionVl_valid
                            ? instMicroOp_exceptionVl_bits : instMicroOp_vl;
      wb_uop_vpu_nf   <= fofFixVlValid ? fofBuffer_vpu_nf : instMicroOp_uop_vpu_nf;
      wb_uop_vpu_veew <= fofFixVlValid ? fofBuffer_vpu_veew : instMicroOp_uop_vpu_veew;
      wb_uop_pdest    <= fofFixVlValid ? fofBuffer_pdest : uopq_pdest[deqPtr_value];
      wb_uop_robIdx_flag  <= fofFixVlValid ? fofBuffer_robIdx_flag  : instMicroOp_uop_robIdx_flag;
      wb_uop_robIdx_value <= fofFixVlValid ? fofBuffer_robIdx_value : instMicroOp_uop_robIdx_value;
      wb_uop_debugInfo_enqRsTime  <= fofFixVlValid ? fofBuffer_debugInfo_enqRsTime  : uopq_debugInfo_enqRsTime[deqPtr_value];
      wb_uop_debugInfo_selectTime <= fofFixVlValid ? fofBuffer_debugInfo_selectTime : uopq_debugInfo_selectTime[deqPtr_value];
      wb_uop_debugInfo_issueTime  <= fofFixVlValid ? fofBuffer_debugInfo_issueTime  : uopq_debugInfo_issueTime[deqPtr_value];
      wb_data <= fofFixVlValid ? {120'h0, instMicroOp_exceptionVl_bits} : data[deqPtr_value];
    end
    if (~writebackValid | fofFixVlValid) begin
    end
    else begin
      wb_vdIdx <= vdIdxInField;
      wb_vdIdxInField <= vdIdxInField;
    end
    io_feedback_valid_REG <= feedbackValid;
    if (feedbackValid) begin
      fb_sqIdx_flag  <= uopq_sqIdx_flag[deqPtr_value];
      fb_sqIdx_value <= uopq_sqIdx_value[deqPtr_value];
      fb_lqIdx_flag  <= uopq_lqIdx_flag[deqPtr_value];
      fb_lqIdx_value <= uopq_lqIdx_value[deqPtr_value];
    end
  end

  // combinedData 高半(curPtr=1): golden {resp[...], combinedData[...]} 桶形移位
  reg  [63:0]  combinedDataHi;
  always_comb begin
    combinedDataHi = 64'h0;
    case (latchVaddr[3:0])
      4'h9: combinedDataHi = {io_rdcache_resp_bits_data_delayed[7:0],  combinedData[55:0]};
      4'hA: combinedDataHi = {io_rdcache_resp_bits_data_delayed[15:0], combinedData[47:0]};
      4'hB: combinedDataHi = {io_rdcache_resp_bits_data_delayed[23:0], combinedData[39:0]};
      4'hC: combinedDataHi = {io_rdcache_resp_bits_data_delayed[31:0], combinedData[31:0]};
      4'hD: combinedDataHi = {io_rdcache_resp_bits_data_delayed[39:0], combinedData[23:0]};
      4'hE: combinedDataHi = {io_rdcache_resp_bits_data_delayed[47:0], combinedData[15:0]};
      4'hF: combinedDataHi = {io_rdcache_resp_bits_data_delayed[55:0], combinedData[7:0]};
      default: combinedDataHi = 64'h0;
    endcase
  end
  // combinedData 低半(curPtr=0): golden {8'h0, 桶形移出 resp 高位对齐 latchVaddr[3:0]}
  reg  [63:0]  combinedDataLo;
  always_comb begin
    logic [55:0] acc;
    acc = 56'h0;
    // latchVaddr[3:0] in [9..F] 抽取 resp[127:*], 低于 9 时为 0(golden _misalignLowData_T_15 起)
    case (latchVaddr[3:0])
      4'h9: acc = io_rdcache_resp_bits_data_delayed[127:72];
      4'hA: acc = io_rdcache_resp_bits_data_delayed[127:80];
      4'hB: acc = io_rdcache_resp_bits_data_delayed[127:88];
      4'hC: acc = io_rdcache_resp_bits_data_delayed[127:96];
      4'hD: acc = io_rdcache_resp_bits_data_delayed[127:104];
      4'hE: acc = io_rdcache_resp_bits_data_delayed[127:112];
      4'hF: acc = {48'h0, io_rdcache_resp_bits_data_delayed[127:120]};
      default: acc = 56'h0;
    endcase
    combinedDataLo = {8'h0, acc};
  end

  // ============================================================
  // 时序块 2: 带 reset 的状态/指针更新(golden always @(posedge clock or posedge reset))
  // ============================================================
  wire [3:0]   enqPtrNext = 4'({enqPtr_flag, enqPtr_value} + 4'h1);
  wire [2:0]   sewRealFlowLog2 =
    3'(3'(($signed(instMicroOp_uop_vpu_vlmul) > -3'sh1 ? 3'h0 : instMicroOp_uop_vpu_vlmul) - 3'h4) - vsew_ext);
  wire [7:0]   splitPtrOffset_emul = 8'h1 << emul_in;
  wire [7:0]   splitPtrOffset_lmul = 8'h1 << io_in_bits_uop_vpu_vlmul;
  wire [3:0]   splitPtrNext_new =
    4'({splitPtr_flag, splitPtr_value}
       + (io_in_bits_uop_fuOpType[5]
            ? ($signed(io_in_bits_uop_vpu_vlmul) < 3'sh0 ? 4'h1 : splitPtrOffset_lmul[3:0])
            : $signed(emul_in) < 3'sh0 ? 4'h1 : splitPtrOffset_emul[3:0]));
  wire         updateLatchVaddr = dtlbReq_T & ~isMisalignReg;
  wire         fixVlEnq = isEnqFixVlUop & ~fofBufferValid;                        // golden _GEN_106
  wire [3:0]   deqPtrNext = 4'(deqPtrPacked + 4'h1);
  wire [7:0]   emulShift = {5'h0, 3'(3'(issueEmulSat - 3'h4) - veew_ext)};       // golden _GEN_105
  wire [7:0]   strideOffsetWire =
    (enqNew ? 8'h0 : (fieldWrapCond & segNotMax) ? segmentIdxNext[7:0]
       : (segmentInactiveFinish & segNotMax) ? segmentIdxNext[7:0] : segmentIdx) >> emulShift;
  wire [7:0]   strideOffset = segmentIdx >> emulShift;
  wire [2:0]   splitShift =
    (instMicroOp_uop_fuOpType[6:5] == 2'h0 | instMicroOp_uop_fuOpType[6:5] == 2'h2
       ? 3'(3'(($signed(issueEmul) > -3'sh1 ? 3'h0 : issueEmul) - 3'h4) - veew_ext) : 3'h0)
    | (instMicroOp_uop_fuOpType[6:5] == 2'h1 ? sewRealFlowLog2 : 3'h0)
    | ((&instMicroOp_uop_fuOpType[6:5]) ? sewRealFlowLog2 : 3'h0);
  wire [8:0]   splitPtrNext_shamt = segmentIdxNext >> splitShift;
  wire [3:0]   splitPtrNext_seg = 4'(deqPtrPacked + splitPtrNext_shamt[3:0]);
  wire         wbOrFinish = wbState | segInactive9 | stFinishLeave;              // golden _GEN_101
  wire         crossStorePmp = crossMisalign & st_is5;                          // golden _GEN_102
  wire         stateNextIsA = stateNext == S_ST_FINISH;                         // golden _GEN_103

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      instMicroOpValid <= 1'h0;
      enqPtr_flag <= 1'h0; enqPtr_value <= 3'h0;
      deqPtr_flag <= 1'h0; deqPtr_value <= 3'h0;
      stridePtrReg_value <= 3'h0;
      segmentIdx <= 8'h0; fieldIdx <= 4'h0; segmentOffset <= 64'h0;
      splitPtr_flag <= 1'h0; splitPtr_value <= 3'h0;
      latchVaddr <= 50'h0; latchVaddrDup <= 50'h0;
      fofBuffer_fuOpType <= 9'h0; fofBuffer_vecWen <= 1'h0; fofBuffer_v0Wen <= 1'h0;
      fofBuffer_vlWen <= 1'h0; fofBuffer_vpu_vma <= 1'h0; fofBuffer_vpu_vta <= 1'h0;
      fofBuffer_vpu_vsew <= 2'h0; fofBuffer_vpu_vlmul <= 3'h0; fofBuffer_vpu_vm <= 1'h0;
      fofBuffer_vpu_vstart <= 8'h0; fofBuffer_vpu_vuopIdx <= 7'h0; fofBuffer_vpu_nf <= 3'h0;
      fofBuffer_vpu_veew <= 2'h0; fofBuffer_pdest <= 8'h0; fofBuffer_robIdx_flag <= 1'h0;
      fofBuffer_robIdx_value <= 8'h0; fofBuffer_debugInfo_enqRsTime <= 64'h0;
      fofBuffer_debugInfo_selectTime <= 64'h0; fofBuffer_debugInfo_issueTime <= 64'h0;
      fofBufferValid <= 1'h0;
      state <= 4'h0; curPtr <= 1'h0; isMisalignReg <= 1'h0; notCross16ByteReg <= 1'h0;
      combinedData <= 64'h0; lowPagePaddr <= 48'h0; last_REG <= 1'h0;
      instMicroOp_uop_exceptionVec_19_last_REG <= 1'h0; nextBaseVaddr_r <= 64'h0;
    end
    else begin
      instMicroOpValid <= (|stateNext) & (enqNewNotFixVl | instMicroOpValid);
      if (enqValidNotFixVl) begin
        enqPtr_flag  <= enqPtrNext[3];
        enqPtr_value <= enqPtrNext[2:0];
      end
      if (wbState & enqPtrPacked != deqPtrPacked) begin
        deqPtr_flag  <= deqPtrNext[3];
        deqPtr_value <= deqPtrNext[2:0];
      end
      stridePtrReg_value <=
        3'(deqPtr_value + (instMicroOp_uop_fuOpType[5] ? strideOffsetWire[2:0] : 3'h0));
      if (enqNew | (fieldWrapCond & segNotMax) | (segmentInactiveFinish & segNotMax)) begin
        if (enqNew)
          segmentIdx <= 8'h0;
        else if (fieldWrapCond & segNotMax)
          segmentIdx <= segmentIdxNext[7:0];
        else
          segmentIdx <= segmentIdxNext[7:0];
      end
      if (enqNew | advanceField | segmentInactiveFinish) begin
        if (enqNew)
          fieldIdx <= 4'h0;
        else if (advanceField) begin
          if (fieldIdxIsMax) fieldIdx <= 4'h0;
          else               fieldIdx <= fieldIdxNext;
        end
        else if (segmentInactiveFinish)
          fieldIdx <= 4'h0;
      end
      if (fieldWrapCond | segmentInactiveFinish)
        segmentOffset <=
          64'(segmentOffset
              + (instMicroOp_uop_fuOpType[6:5] == 2'h0
                   ? {57'h0, {3'h0, 4'(nf_ext + 4'h1)} << instMicroOp_uop_vpu_veew}
                   : stride[3'(deqPtr_value + (instMicroOp_uop_fuOpType[5] ? strideOffset[2:0] : 3'h0))][63:0]));
      else if (enqNewNotFixVl)
        segmentOffset <= 64'h0;
      if (segInactive9 | stFinishLeave & (fieldActiveWirteFinish | ~segMaskAny)) begin
        if (fieldIdxIsMax | ~segMaskAny) begin
          splitPtr_flag  <= splitPtrNext_seg[3];
          splitPtr_value <= splitPtrNext_seg[2:0];
        end
        else begin
          splitPtr_flag  <= splitPtrNext_new[3];
          splitPtr_value <= splitPtrNext_new[2:0];
        end
      end
      else if (enqNew) begin
        splitPtr_flag  <= deqPtr_flag;
        splitPtr_value <= deqPtr_value;
      end
      if (updateLatchVaddr) begin
        latchVaddr    <= vaddr_flow[49:0];
        latchVaddrDup <= vaddr_flow[49:0];
      end
      if (fofFixVlValid) begin
        fofBuffer_fuOpType <= 9'h0; fofBuffer_vpu_vsew <= 2'h0; fofBuffer_vpu_vlmul <= 3'h0;
        fofBuffer_vpu_vstart <= 8'h0; fofBuffer_vpu_vuopIdx <= 7'h0; fofBuffer_vpu_nf <= 3'h0;
        fofBuffer_vpu_veew <= 2'h0; fofBuffer_pdest <= 8'h0; fofBuffer_robIdx_value <= 8'h0;
        fofBuffer_debugInfo_enqRsTime <= 64'h0; fofBuffer_debugInfo_selectTime <= 64'h0;
        fofBuffer_debugInfo_issueTime <= 64'h0;
      end
      else if (fixVlEnq) begin
        fofBuffer_fuOpType <= io_in_bits_uop_fuOpType; fofBuffer_vpu_vsew <= io_in_bits_uop_vpu_vsew;
        fofBuffer_vpu_vlmul <= io_in_bits_uop_vpu_vlmul; fofBuffer_vpu_vstart <= io_in_bits_uop_vpu_vstart;
        fofBuffer_vpu_vuopIdx <= io_in_bits_uop_vpu_vuopIdx; fofBuffer_vpu_nf <= io_in_bits_uop_vpu_nf;
        fofBuffer_vpu_veew <= io_in_bits_uop_vpu_veew; fofBuffer_pdest <= io_in_bits_uop_pdest;
        fofBuffer_robIdx_value <= io_in_bits_uop_robIdx_value;
        fofBuffer_debugInfo_enqRsTime <= io_in_bits_uop_debugInfo_enqRsTime;
        fofBuffer_debugInfo_selectTime <= io_in_bits_uop_debugInfo_selectTime;
        fofBuffer_debugInfo_issueTime <= io_in_bits_uop_debugInfo_issueTime;
      end
      fofBuffer_vecWen <= ~fofFixVlValid & (fixVlEnq ? io_in_bits_uop_vecWen : fofBuffer_vecWen);
      fofBuffer_v0Wen  <= ~fofFixVlValid & (fixVlEnq ? io_in_bits_uop_v0Wen  : fofBuffer_v0Wen);
      fofBuffer_vlWen  <= ~fofFixVlValid & (fixVlEnq ? io_in_bits_uop_vlWen  : fofBuffer_vlWen);
      fofBuffer_vpu_vma <= ~fofFixVlValid & (fixVlEnq ? io_in_bits_uop_vpu_vma : fofBuffer_vpu_vma);
      fofBuffer_vpu_vta <= ~fofFixVlValid & (fixVlEnq ? io_in_bits_uop_vpu_vta : fofBuffer_vpu_vta);
      fofBuffer_vpu_vm  <= ~fofFixVlValid & (fixVlEnq ? io_in_bits_uop_vpu_vm  : fofBuffer_vpu_vm);
      fofBuffer_robIdx_flag <= ~fofFixVlValid & (fixVlEnq ? io_in_bits_uop_robIdx_flag : fofBuffer_robIdx_flag);
      fofBufferValid <= ~fofFixVlValid & (fixVlEnq | fofBufferValid);
      if (|state) state <= stateNext_active;
      else        state <= stateNextIdle;
      curPtr <=
        ~wbOrFinish
        & (instMicroOp_isVSegLoad
             ? crossMisalign & st_is8 | curPtr
             : crossStorePmp
                 ? ~curPtr
                 : ~(crossStorePmp & stateNextIsA)
                   & (crossMisalign & segInactiveA & stateNextIsA & fieldWriteFire_pre ^ curPtr));
      isMisalignReg <= ~wbOrFinish & (misalignSet | ~enqNewNotFixVl & isMisalignReg);
      notCross16ByteReg <=
        ~wbOrFinish & (misalignSet ? notCross16ByteWire : ~enqNewNotFixVl & notCross16ByteReg);
      if (st_is8 & segMaskAny) begin
        if (curPtr)
          combinedData <= combinedDataHi;
        else
          combinedData <= combinedDataLo;
      end
      if (dtlbResp5 & ~io_dtlb_resp_bits_miss & isMisalignReg & ~notCross16ByteReg & ~curPtr)
        lowPagePaddr <= io_dtlb_resp_bits_paddr_0;
      last_REG <= io_csrCtrl_cache_error_enable;
      instMicroOp_uop_exceptionVec_19_last_REG <= io_csrCtrl_cache_error_enable;
      if (stateNext == S_TLB_REQ)
        nextBaseVaddr_r <=
          64'(instMicroOp_baseVaddr
              + {53'h0,
                 {7'h0, enqNew ? 4'h0 : advanceField ? (fieldIdxIsMax ? 4'h0 : fieldIdxNext)
                          : segmentInactiveFinish ? 4'h0 : fieldIdx} << instMicroOp_alignedType});
    end
  end

  // ============================================================
  // 输出赋值
  // ============================================================
  // segmentTrigger glue
  assign seg_trig_vaddr   = dcacheReqVaddr;
  assign seg_trig_memType = instMicroOp_isVSegLoad;
  // pipelineConnect glue(io_in payload)
  assign pc_in_valid = sbufferOut_valid;
  assign pc_in_bits_vaddr =
    isMisalignReg
      ? (notCross16ByteReg ? {latchVaddr[49:4], 4'h0}
           : curPtr ? 50'({latchVaddr[49:3], 3'h0} + 50'h8) : {latchVaddr[49:3], 3'h0})
      : latchVaddr;
  assign pc_in_bits_data =
    isMisalignReg
      ? (notCross16ByteReg ? notCross16ByteData[127:0]
           : curPtr ? {1'h0, Cross16ByteData[254:128]} : Cross16ByteData[127:0])
      : flowData;
  assign pc_in_bits_mask =
    ~isMisalignReg | notCross16ByteReg ? wmask[15:0]
      : curPtr ? Cross16ByteMask[31:16] : Cross16ByteMask[15:0];
  assign pc_in_bits_addr =
    isMisalignReg
      ? (notCross16ByteReg ? {instMicroOp_paddr[47:4], 4'h0}
           : {curPtr ? instMicroOp_paddr[47:3] : lowPagePaddr[47:3], 3'h0})
      : instMicroOp_paddr;
  assign pc_in_bits_vecValid = segInactiveA & segMaskAny;
  assign pc_rightOutFire = io_sbuffer_ready & pc_out_valid;

  // uopwriteback
  assign io_uopwriteback_valid = io_uopwriteback_valid_REG;
  assign io_uopwriteback_bits_uop_exceptionVec_3  = wb_uop_exceptionVec_3;
  assign io_uopwriteback_bits_uop_exceptionVec_5  = wb_uop_exceptionVec_5;
  assign io_uopwriteback_bits_uop_exceptionVec_7  = wb_uop_exceptionVec_7;
  assign io_uopwriteback_bits_uop_exceptionVec_13 = wb_uop_exceptionVec_13;
  assign io_uopwriteback_bits_uop_exceptionVec_15 = wb_uop_exceptionVec_15;
  assign io_uopwriteback_bits_uop_exceptionVec_19 = wb_uop_exceptionVec_19;
  assign io_uopwriteback_bits_uop_exceptionVec_21 = wb_uop_exceptionVec_21;
  assign io_uopwriteback_bits_uop_exceptionVec_23 = wb_uop_exceptionVec_23;
  assign io_uopwriteback_bits_uop_trigger  = wb_uop_trigger;
  assign io_uopwriteback_bits_uop_fuOpType = wb_uop_fuOpType;
  assign io_uopwriteback_bits_uop_vecWen   = wb_uop_vecWen;
  assign io_uopwriteback_bits_uop_v0Wen    = wb_uop_v0Wen;
  assign io_uopwriteback_bits_uop_vlWen    = wb_uop_vlWen;
  assign io_uopwriteback_bits_uop_vpu_vma  = wb_uop_vpu_vma;
  assign io_uopwriteback_bits_uop_vpu_vta  = wb_uop_vpu_vta;
  assign io_uopwriteback_bits_uop_vpu_vsew = wb_uop_vpu_vsew;
  assign io_uopwriteback_bits_uop_vpu_vlmul= wb_uop_vpu_vlmul;
  assign io_uopwriteback_bits_uop_vpu_vm   = wb_uop_vpu_vm;
  assign io_uopwriteback_bits_uop_vpu_vstart = wb_uop_vpu_vstart;
  assign io_uopwriteback_bits_uop_vpu_vuopIdx = wb_uop_vpu_vuopIdx;
  assign io_uopwriteback_bits_uop_vpu_vmask = wb_uop_vpu_vmask;
  assign io_uopwriteback_bits_uop_vpu_vl   = wb_uop_vpu_vl;
  assign io_uopwriteback_bits_uop_vpu_nf   = wb_uop_vpu_nf;
  assign io_uopwriteback_bits_uop_vpu_veew = wb_uop_vpu_veew;
  assign io_uopwriteback_bits_uop_pdest    = wb_uop_pdest;
  assign io_uopwriteback_bits_uop_robIdx_flag  = wb_uop_robIdx_flag;
  assign io_uopwriteback_bits_uop_robIdx_value = wb_uop_robIdx_value;
  assign io_uopwriteback_bits_uop_debugInfo_enqRsTime  = wb_uop_debugInfo_enqRsTime;
  assign io_uopwriteback_bits_uop_debugInfo_selectTime = wb_uop_debugInfo_selectTime;
  assign io_uopwriteback_bits_uop_debugInfo_issueTime  = wb_uop_debugInfo_issueTime;
  assign io_uopwriteback_bits_data = wb_data;
  assign io_uopwriteback_bits_vdIdx = wb_vdIdx;
  assign io_uopwriteback_bits_vdIdxInField = wb_vdIdxInField;
  assign io_uopwriteback_bits_debug_isMMIO = 1'h0;
  assign io_uopwriteback_bits_debug_isNCIO = 1'h0;
  assign io_uopwriteback_bits_debug_isPerfCnt = 1'h0;

  // rdcache
  assign io_rdcache_req_valid = io_rdcache_req_valid_0;
  assign io_rdcache_req_bits_vaddr = dcacheReqVaddr;
  assign io_rdcache_req_bits_vaddr_dup =
    isMisalignReg
      ? {curPtr ? 47'(latchVaddrDup[49:3] + 47'h1) : latchVaddrDup[49:3], 3'h0}
      : latchVaddrDup;
  assign io_rdcache_is128Req = notCross16ByteReg;
  assign io_rdcache_s1_paddr_dup_lsu = dcacheReqPaddr;
  assign io_rdcache_s1_paddr_dup_dcache = dcacheReqPaddr;

  // sbuffer io_out 由 wrapper 从 pipe io_out_* 直连(valid=pc_out_valid), 不经核。

  // dtlb
  assign io_dtlb_req_valid = dtlbReq_T & segMaskAny;
  assign io_dtlb_req_bits_vaddr = tlbReqVaddr[49:0];
  assign io_dtlb_req_bits_fullva = tlbReqVaddr;
  assign io_dtlb_req_bits_cmd = {2'h0, ~instMicroOp_isVSegLoad};
  assign io_dtlb_req_bits_debug_robIdx_flag  = instMicroOp_uop_robIdx_flag;
  assign io_dtlb_req_bits_debug_robIdx_value = instMicroOp_uop_robIdx_value;

  assign io_flush_sbuffer_valid = ~io_flush_sbuffer_empty & state == S_FLUSH;

  // feedback
  assign io_feedback_valid = io_feedback_valid_REG;
  assign io_feedback_bits_sqIdx_flag  = fb_sqIdx_flag;
  assign io_feedback_bits_sqIdx_value = fb_sqIdx_value;
  assign io_feedback_bits_lqIdx_flag  = fb_lqIdx_flag;
  assign io_feedback_bits_lqIdx_value = fb_lqIdx_value;

  // exceptionInfo
  assign io_exceptionInfo_valid = wbState & (|excVec) & enqPtrPacked != deqPtrPacked;
  assign io_exceptionInfo_bits_vaddr  = instMicroOp_exceptionVaddr;
  assign io_exceptionInfo_bits_gpaddr = instMicroOp_exceptionGpaddr[49:0];
  assign io_exceptionInfo_bits_isForVSnonLeafPTE = instMicroOp_exceptionIsForVSnonLeafPTE;

endmodule
