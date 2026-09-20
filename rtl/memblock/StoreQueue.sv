// =============================================================================
//  StoreQueue —— 访存子系统的存储队列（G1 golden: StoreQueue.sv, 77145 行 / 1003 端口）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/mem/lsqueue/StoreQueue.scala (1597 行)
//               同目录 StoreQueueData.scala / sbuffer/DatamoduleResultBuffer.scala
//  golden 基线：G1-canonical (XiangShan kunminghu-v2 @ b36a1a2a5, KunminghuV2Config)
//
//  ★★★ 本文件是**考古阶段的骨架**，不是完成的重写 ★★★
//  只有「已在 golden 上实测核对过」的东西才写进来：
//    · 端口契约（1003 根，逐位从 golden 端口表推导，不是手抄）
//    · per-entry 状态清单与**复位域**（async / 不复位，实测分区见 §3）
//    · 多源写同一状态位的**优先级骨架**（条件线名已留，方程未追清的标 TODO）
//    · 5 个子模块的例化形状
//  功能方程绝大部分**尚未追清**，集中列在文件末尾 §9 待办清单。
//  任何人不得据本文件声称 StoreQueue 已重写完成。
//
//  store 的一生：
//    dispatch 入队(分配条目) → sta 写地址(s1/s2 两拍) → std 写数据 → ROB 提交
//    → 读出送 dataBuffer → 写 Sbuffer(可缓存) / 走 uncache(mmio·NC) → 退队
//  并行地，load 通过 forward 端口在队列里做地址 CAM 做 store-to-load 转发。
//
// =============================================================================
// 本文件导航：
//   L38     §1 storequeue_pkg —— 参数、SqPtr 环形指针、各通道结构体
//   L66     §1.1 SqPtr —— 56 项环形指针（★不是 2 的幂，加法是比较-减法★）
//   L95     §1.2 通道结构体（字段集与位宽由 golden 端口表机械推导）
//   L372    §2 xs_StoreQueue_core —— 可读核
//   L668    §3 per-entry 状态 —— ★复位域是 golden 实测，不是照 Chisel 抄★
//   L736    §4 多源写优先级骨架 —— ★条件线名照 golden，方程未追清处标 TODO★
//   L767    §5 子模块例化 —— ★5 个子模块在本仓一个都没有实现★
//   L786    §6 组合输出 —— TODO
//   L792    §7 时序：异步复位块（对应 golden L62202-69650）
//   L823    §8 时序：★不复位★块（对应 golden L20336-58753，2913 个 reg）
//   L832    §9 待办清单 —— ★尚未追清的方程，逐条列明，不许含糊★
//   L875    §10 StoreQueue —— golden 同名 wrapper（1003 根端口，逐位对齐）

// -----------------------------------------------------------------------------
// §1 storequeue_pkg —— 参数、SqPtr 环形指针、各通道结构体
// -----------------------------------------------------------------------------
package storequeue_pkg;

  // 参数取自 Parameters.scala（KunminghuV2Config 未覆盖任何一项），
  // 每一项都已用 golden 的端口下标/位宽反查确认。
  localparam int SQ_SIZE      = 56;  // StoreQueueSize，★非 2 的幂★
  localparam int SQ_IDX_W     = 6;   // = $clog2(64)，指针 value 位宽
  localparam int N_STA        = 2;   // StorePipelineWidth（storeAddrIn/Re）
  localparam int N_STD        = 2;   // 同上（storeDataIn/storeMaskIn）
  localparam int N_FWD        = 3;   // LoadPipelineWidth（forward 查询口）
  localparam int N_ENSBUF     = 2;   // EnsbufferWidth（sbuffer/deq/rdata）
  localparam int N_ENQ        = 6;   // LSQEnqWidth = RenameWidth
  localparam int N_COMMIT     = 8;   // CommitWidth（cmtPtrExt 8 份）
  localparam int N_VECFB      = 2;   // VecLoadPipelineWidth（vecFeedback）
  localparam int N_PERF       = 8;
  localparam int VLEN         = 128;

  // 门限三则，全部按 golden 的字面形式记（不要转写成「<=」再自己换算）：
  //   golden L5190 : allowEnqueue   = validCount  < 6'h35 (53)
  //   golden L69648: io_force_write = valid_cnt   > 6'h33 (51)
  //                  持续条件         valid_cnt   > 6'h2E (46)
  localparam int ALLOW_ENQ_LT      = 53;  // validCount < 53
  localparam int FORCE_WR_SET_GT   = 51;
  localparam int FORCE_WR_HOLD_GT  = 46;


// -----------------------------------------------------------------------------
// §1.1 SqPtr —— 56 项环形指针（★不是 2 的幂，加法是比较-减法★）
// -----------------------------------------------------------------------------
  // CircularQueuePtr：{flag,value}，flag 每绕一圈翻转。因为 56 不是 2 的幂，
  // 「+」必须写成 new=value+v; if (new>=56) {flag=~flag; value=new-56;}，
  // ★绝不能写成对 {flag,value} 整体做计数器自增★。
  typedef struct packed {
    logic                 flag;
    logic [SQ_IDX_W-1:0]  value;
  } sqptr_t;

  function automatic sqptr_t sqptr_add(sqptr_t p, int unsigned v);
    int unsigned nv;
    nv = p.value + v;
    if (nv >= SQ_SIZE) sqptr_add = '{flag: ~p.flag, value: SQ_IDX_W'(nv - SQ_SIZE)};
    else               sqptr_add = '{flag:  p.flag, value: SQ_IDX_W'(nv)};
  endfunction

  // isAfter / distanceBetween 只在「相距不超过一圈」时有效（golden 同）。
  function automatic logic sqptr_after(sqptr_t a, sqptr_t b);
    sqptr_after = (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction

  function automatic logic [SQ_IDX_W:0] sqptr_dist(sqptr_t a, sqptr_t b);
    sqptr_dist = (a.flag == b.flag) ? (a.value - b.value)
                                    : (SQ_SIZE + a.value - b.value);
  endfunction


// -----------------------------------------------------------------------------
// §1.2 通道结构体（字段集与位宽由 golden 端口表机械推导）
// -----------------------------------------------------------------------------
  typedef struct packed {
    logic            valid;
    logic            bits_exceptionVec_0;
    logic            bits_exceptionVec_1;
    logic            bits_exceptionVec_2;
    logic            bits_exceptionVec_3;
    logic            bits_exceptionVec_4;
    logic            bits_exceptionVec_5;
    logic            bits_exceptionVec_6;
    logic            bits_exceptionVec_7;
    logic            bits_exceptionVec_8;
    logic            bits_exceptionVec_9;
    logic            bits_exceptionVec_10;
    logic            bits_exceptionVec_11;
    logic            bits_exceptionVec_12;
    logic            bits_exceptionVec_13;
    logic            bits_exceptionVec_14;
    logic            bits_exceptionVec_15;
    logic            bits_exceptionVec_16;
    logic            bits_exceptionVec_17;
    logic            bits_exceptionVec_18;
    logic            bits_exceptionVec_19;
    logic            bits_exceptionVec_20;
    logic            bits_exceptionVec_21;
    logic            bits_exceptionVec_22;
    logic            bits_exceptionVec_23;
    logic [3:0]      bits_trigger;
    logic [34:0]     bits_fuType;
    logic [8:0]      bits_fuOpType;
    logic            bits_rfWen;
    logic            bits_flushPipe;
    logic [2:0]      bits_vpu_nf;
    logic [1:0]      bits_vpu_veew;
    logic [6:0]      bits_uopIdx;
    logic            bits_lastUop;
    logic [7:0]      bits_pdest;
    logic            bits_robIdx_flag;
    logic [7:0]      bits_robIdx_value;
    logic            bits_debugInfo_eliminatedMove;
    logic [63:0]     bits_debugInfo_renameTime;
    logic [63:0]     bits_debugInfo_dispatchTime;
    logic [63:0]     bits_debugInfo_enqRsTime;
    logic [63:0]     bits_debugInfo_selectTime;
    logic [63:0]     bits_debugInfo_issueTime;
    logic [63:0]     bits_debugInfo_writebackTime;
    logic [63:0]     bits_debugInfo_runahead_checkpoint_id;
    logic [63:0]     bits_debugInfo_tlbFirstReqTime;
    logic [63:0]     bits_debugInfo_tlbRespTime;
    logic [55:0]     bits_debug_seqNum_seqNum;
    logic [7:0]      bits_debug_seqNum_uopIdx;
    logic            bits_sqIdx_flag;
    logic [5:0]      bits_sqIdx_value;
    logic [4:0]      bits_numLsElem;
  } sq_enq_req_t_in;

  typedef struct packed {
    logic            valid;
    logic            bits_uop_exceptionVec_0;
    logic            bits_uop_exceptionVec_1;
    logic            bits_uop_exceptionVec_2;
    logic            bits_uop_exceptionVec_3;
    logic            bits_uop_exceptionVec_4;
    logic            bits_uop_exceptionVec_5;
    logic            bits_uop_exceptionVec_6;
    logic            bits_uop_exceptionVec_7;
    logic            bits_uop_exceptionVec_8;
    logic            bits_uop_exceptionVec_9;
    logic            bits_uop_exceptionVec_10;
    logic            bits_uop_exceptionVec_11;
    logic            bits_uop_exceptionVec_12;
    logic            bits_uop_exceptionVec_13;
    logic            bits_uop_exceptionVec_14;
    logic            bits_uop_exceptionVec_15;
    logic            bits_uop_exceptionVec_16;
    logic            bits_uop_exceptionVec_17;
    logic            bits_uop_exceptionVec_18;
    logic            bits_uop_exceptionVec_19;
    logic            bits_uop_exceptionVec_20;
    logic            bits_uop_exceptionVec_21;
    logic            bits_uop_exceptionVec_22;
    logic            bits_uop_exceptionVec_23;
    logic [3:0]      bits_uop_trigger;
    logic [34:0]     bits_uop_fuType;
    logic [8:0]      bits_uop_fuOpType;
    logic            bits_uop_rfWen;
    logic [2:0]      bits_uop_vpu_nf;
    logic [1:0]      bits_uop_vpu_veew;
    logic [6:0]      bits_uop_uopIdx;
    logic [7:0]      bits_uop_pdest;
    logic            bits_uop_robIdx_flag;
    logic [7:0]      bits_uop_robIdx_value;
    logic            bits_uop_debugInfo_eliminatedMove;
    logic [63:0]     bits_uop_debugInfo_renameTime;
    logic [63:0]     bits_uop_debugInfo_dispatchTime;
    logic [63:0]     bits_uop_debugInfo_enqRsTime;
    logic [63:0]     bits_uop_debugInfo_selectTime;
    logic [63:0]     bits_uop_debugInfo_issueTime;
    logic [63:0]     bits_uop_debugInfo_writebackTime;
    logic [63:0]     bits_uop_debugInfo_runahead_checkpoint_id;
    logic [63:0]     bits_uop_debugInfo_tlbFirstReqTime;
    logic [63:0]     bits_uop_debugInfo_tlbRespTime;
    logic [55:0]     bits_uop_debug_seqNum_seqNum;
    logic [7:0]      bits_uop_debug_seqNum_uopIdx;
    logic [5:0]      bits_uop_sqIdx_value;
    logic [49:0]     bits_vaddr;
    logic [63:0]     bits_fullva;
    logic            bits_vaNeedExt;
    logic [47:0]     bits_paddr;
    logic [63:0]     bits_gpaddr;
    logic [15:0]     bits_mask;
    logic            bits_wlineflag;
    logic            bits_miss;
    logic            bits_nc;
    logic            bits_isHyper;
    logic            bits_isForVSnonLeafPTE;
    logic            bits_isvec;
    logic            bits_isFrmMisAlignBuf;
    logic            bits_isMisalign;
    logic            bits_misalignWith16Byte;
    logic            bits_updateAddrValid;
  } sq_storeAddrIn_t_in;

  typedef struct packed {
    logic            uop_exceptionVec_3;
    logic            uop_exceptionVec_6;
    logic            uop_exceptionVec_15;
    logic            uop_exceptionVec_19;
    logic            uop_exceptionVec_23;
    logic [6:0]      uop_uopIdx;
    logic            uop_robIdx_flag;
    logic [7:0]      uop_robIdx_value;
    logic [63:0]     fullva;
    logic            vaNeedExt;
    logic [63:0]     gpaddr;
    logic            af;
    logic            mmio;
    logic            memBackTypeMM;
    logic            hasException;
    logic            isHyper;
    logic            isForVSnonLeafPTE;
    logic            isvec;
    logic            updateAddrValid;
  } sq_storeAddrInRe_t_in;

  typedef struct packed {
    logic            valid;
    logic [34:0]     bits_uop_fuType;
    logic [8:0]      bits_uop_fuOpType;
    logic [5:0]      bits_uop_sqIdx_value;
    logic [127:0]    bits_data;
    logic [5:0]      bits_vecDebug_offset;
  } sq_storeDataIn_t_in;

  typedef struct packed {
    logic            valid;
    logic [5:0]      bits_sqIdx_value;
    logic [15:0]     bits_mask;
  } sq_storeMaskIn_t_in;

  typedef struct packed {
    logic [49:0]     vaddr;
    logic [47:0]     paddr;
    logic [15:0]     mask;
    logic            uop_waitForRobIdx_flag;
    logic [7:0]      uop_waitForRobIdx_value;
    logic            uop_loadWaitBit;
    logic            uop_loadWaitStrict;
    logic            uop_sqIdx_flag;
    logic [5:0]      uop_sqIdx_value;
    logic            valid;
    logic            sqIdx_flag;
    logic [55:0]     sqIdxMask;
  } sq_forward_t_in;

  typedef struct packed {
    logic            forwardMask_0;
    logic            forwardMask_1;
    logic            forwardMask_2;
    logic            forwardMask_3;
    logic            forwardMask_4;
    logic            forwardMask_5;
    logic            forwardMask_6;
    logic            forwardMask_7;
    logic            forwardMask_8;
    logic            forwardMask_9;
    logic            forwardMask_10;
    logic            forwardMask_11;
    logic            forwardMask_12;
    logic            forwardMask_13;
    logic            forwardMask_14;
    logic            forwardMask_15;
    logic [7:0]      forwardData_0;
    logic [7:0]      forwardData_1;
    logic [7:0]      forwardData_2;
    logic [7:0]      forwardData_3;
    logic [7:0]      forwardData_4;
    logic [7:0]      forwardData_5;
    logic [7:0]      forwardData_6;
    logic [7:0]      forwardData_7;
    logic [7:0]      forwardData_8;
    logic [7:0]      forwardData_9;
    logic [7:0]      forwardData_10;
    logic [7:0]      forwardData_11;
    logic [7:0]      forwardData_12;
    logic [7:0]      forwardData_13;
    logic [7:0]      forwardData_14;
    logic [7:0]      forwardData_15;
    logic            dataInvalid;
    logic            matchInvalid;
    logic            addrInvalid;
    logic            dataInvalidSqIdx_flag;
    logic [5:0]      dataInvalidSqIdx_value;
    logic            addrInvalidSqIdx_flag;
    logic [5:0]      addrInvalidSqIdx_value;
  } sq_forward_t_out;

  typedef struct packed {
    logic            ready;
  } sq_sbuffer_t_in;

  typedef struct packed {
    logic            valid;
    logic [49:0]     bits_vaddr;
    logic [127:0]    bits_data;
    logic [15:0]     bits_mask;
    logic [47:0]     bits_addr;
    logic            bits_wline;
    logic            bits_vecValid;
  } sq_sbuffer_t_out;

  typedef struct packed {
    logic            valid;
    logic            bits_robidx_flag;
    logic [7:0]      bits_robidx_value;
    logic [6:0]      bits_uopidx;
    logic [63:0]     bits_vaddr;
    logic            bits_vaNeedExt;
    logic [63:0]     bits_gpaddr;
    logic            bits_isForVSnonLeafPTE;
    logic            bits_feedback_0;
    logic            bits_feedback_1;
    logic            bits_exceptionVec_3;
    logic            bits_exceptionVec_6;
    logic            bits_exceptionVec_7;
    logic            bits_exceptionVec_15;
    logic            bits_exceptionVec_19;
    logic            bits_exceptionVec_23;
  } sq_vecFeedback_t_in;

  typedef struct packed {
    logic [5:0]      value;
  } sq_perf_t_out;

  typedef struct packed {
    logic [34:0]     uop_fuType;
    logic [8:0]      uop_fuOpType;
    logic [2:0]      uop_vpu_nf;
    logic [1:0]      uop_vpu_veew;
    logic [7:0]      uop_robIdx_value;
    logic [5:0]      offset;
  } sq_diffStore_diffInfo_t_out;

  typedef struct packed {
    logic            valid;
    logic [127:0]    bits_data;
    logic [15:0]     bits_mask;
    logic [47:0]     bits_addr;
    logic            bits_wline;
    logic            bits_vecValid;
  } sq_diffStore_pmaStore_t_out;

endpackage


// -----------------------------------------------------------------------------
// §2 xs_StoreQueue_core —— 可读核
// -----------------------------------------------------------------------------
module xs_StoreQueue_core
  import storequeue_pkg::*;
(
  input  logic                      clock,
  input  logic                      reset,
  input  sq_enq_req_t_in            enq_req_in               [6],
  input  sq_storeAddrIn_t_in        storeAddrIn_in           [2],
  input  sq_storeAddrInRe_t_in      storeAddrInRe_in         [2],
  input  sq_storeDataIn_t_in        storeDataIn_in           [2],
  input  sq_storeMaskIn_t_in        storeMaskIn_in           [2],
  input  sq_forward_t_in            forward_in               [3],
  output sq_forward_t_out           forward_out              [3],
  input  sq_sbuffer_t_in            sbuffer_in               [2],
  output sq_sbuffer_t_out           sbuffer_out              [2],
  input  sq_vecFeedback_t_in        vecFeedback_in           [2],
  output sq_perf_t_out              perf_out                 [8],
  output sq_diffStore_diffInfo_t_out diffStore_diffInfo_out   [2],
  output sq_diffStore_pmaStore_t_out diffStore_pmaStore_out   [2],
  input  logic [5:0]                io_hartId               ,
  output logic                      io_enq_canAccept        ,
  input  logic                      io_enq_lqCanAccept      ,
  input  logic                      io_enq_needAlloc_0      ,
  input  logic                      io_enq_needAlloc_1      ,
  input  logic                      io_enq_needAlloc_2      ,
  input  logic                      io_enq_needAlloc_3      ,
  input  logic                      io_enq_needAlloc_4      ,
  input  logic                      io_brqRedirect_valid    ,
  input  logic                      io_brqRedirect_bits_robIdx_flag,
  input  logic [7:0]                io_brqRedirect_bits_robIdx_value,
  input  logic                      io_brqRedirect_bits_level,
  input  logic                      io_uncacheOutstanding   ,
  input  logic                      io_cmoOpReq_ready       ,
  output logic                      io_cmoOpReq_valid       ,
  output logic [2:0]                io_cmoOpReq_bits_opcode ,
  output logic [63:0]               io_cmoOpReq_bits_address,
  output logic                      io_cmoOpResp_ready      ,
  input  logic                      io_cmoOpResp_valid      ,
  input  logic                      io_cmoOpResp_bits_denied,
  input  logic                      io_cmoOpResp_bits_corrupt,
  input  logic                      io_cboZeroStout_ready   ,
  output logic                      io_cboZeroStout_valid   ,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_0,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_1,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_2,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_3,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_4,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_5,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_6,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_7,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_8,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_9,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_10,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_11,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_12,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_13,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_14,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_15,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_16,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_17,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_18,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_19,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_20,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_21,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_22,
  output logic                      io_cboZeroStout_bits_uop_exceptionVec_23,
  output logic [3:0]                io_cboZeroStout_bits_uop_trigger,
  output logic                      io_cboZeroStout_bits_uop_rfWen,
  output logic                      io_cboZeroStout_bits_uop_flushPipe,
  output logic [7:0]                io_cboZeroStout_bits_uop_pdest,
  output logic                      io_cboZeroStout_bits_uop_robIdx_flag,
  output logic [7:0]                io_cboZeroStout_bits_uop_robIdx_value,
  output logic                      io_cboZeroStout_bits_uop_debugInfo_eliminatedMove,
  output logic [63:0]               io_cboZeroStout_bits_uop_debugInfo_renameTime,
  output logic [63:0]               io_cboZeroStout_bits_uop_debugInfo_dispatchTime,
  output logic [63:0]               io_cboZeroStout_bits_uop_debugInfo_enqRsTime,
  output logic [63:0]               io_cboZeroStout_bits_uop_debugInfo_selectTime,
  output logic [63:0]               io_cboZeroStout_bits_uop_debugInfo_issueTime,
  output logic [63:0]               io_cboZeroStout_bits_uop_debugInfo_writebackTime,
  output logic [63:0]               io_cboZeroStout_bits_uop_debugInfo_runahead_checkpoint_id,
  output logic [63:0]               io_cboZeroStout_bits_uop_debugInfo_tlbFirstReqTime,
  output logic [63:0]               io_cboZeroStout_bits_uop_debugInfo_tlbRespTime,
  output logic [55:0]               io_cboZeroStout_bits_uop_debug_seqNum_seqNum,
  output logic [7:0]                io_cboZeroStout_bits_uop_debug_seqNum_uopIdx,
  output logic                      io_cboZeroStout_bits_uop_sqIdx_flag,
  output logic [5:0]                io_cboZeroStout_bits_uop_sqIdx_value,
  input  logic                      io_mmioStout_ready      ,
  output logic                      io_mmioStout_valid      ,
  output logic                      io_mmioStout_bits_uop_exceptionVec_7,
  output logic                      io_mmioStout_bits_uop_exceptionVec_19,
  output logic                      io_mmioStout_bits_uop_rfWen,
  output logic                      io_mmioStout_bits_uop_flushPipe,
  output logic [7:0]                io_mmioStout_bits_uop_pdest,
  output logic                      io_mmioStout_bits_uop_robIdx_flag,
  output logic [7:0]                io_mmioStout_bits_uop_robIdx_value,
  output logic                      io_mmioStout_bits_uop_debugInfo_eliminatedMove,
  output logic [63:0]               io_mmioStout_bits_uop_debugInfo_renameTime,
  output logic [63:0]               io_mmioStout_bits_uop_debugInfo_dispatchTime,
  output logic [63:0]               io_mmioStout_bits_uop_debugInfo_enqRsTime,
  output logic [63:0]               io_mmioStout_bits_uop_debugInfo_selectTime,
  output logic [63:0]               io_mmioStout_bits_uop_debugInfo_issueTime,
  output logic [63:0]               io_mmioStout_bits_uop_debugInfo_writebackTime,
  output logic [63:0]               io_mmioStout_bits_uop_debugInfo_runahead_checkpoint_id,
  output logic [63:0]               io_mmioStout_bits_uop_debugInfo_tlbFirstReqTime,
  output logic [63:0]               io_mmioStout_bits_uop_debugInfo_tlbRespTime,
  output logic [55:0]               io_mmioStout_bits_uop_debug_seqNum_seqNum,
  output logic [7:0]                io_mmioStout_bits_uop_debug_seqNum_uopIdx,
  output logic                      io_mmioStout_bits_uop_sqIdx_flag,
  output logic [5:0]                io_mmioStout_bits_uop_sqIdx_value,
  output logic [63:0]               io_mmioStout_bits_data  ,
  output logic                      io_mmioStout_bits_debug_isMMIO,
  input  logic [3:0]                io_rob_scommit          ,
  input  logic                      io_rob_pendingst        ,
  input  logic                      io_rob_pendingPtr_flag  ,
  input  logic [7:0]                io_rob_pendingPtr_value ,
  output logic                      io_rob_storeMmio        ,
  output logic [7:0]                io_rob_storeMmioUop_robIdx_value,
  input  logic                      io_uncache_req_ready    ,
  output logic                      io_uncache_req_valid    ,
  output logic                      io_uncache_req_bits_robIdx_flag,
  output logic [7:0]                io_uncache_req_bits_robIdx_value,
  output logic [47:0]               io_uncache_req_bits_addr,
  output logic [49:0]               io_uncache_req_bits_vaddr,
  output logic [63:0]               io_uncache_req_bits_data,
  output logic [7:0]                io_uncache_req_bits_mask,
  output logic [6:0]                io_uncache_req_bits_id  ,
  output logic                      io_uncache_req_bits_nc  ,
  output logic                      io_uncache_req_bits_memBackTypeMM,
  input  logic                      io_uncache_idResp_valid ,
  input  logic [6:0]                io_uncache_idResp_bits_mid,
  input  logic                      io_uncache_idResp_bits_nc,
  input  logic                      io_uncache_resp_valid   ,
  input  logic                      io_uncache_resp_bits_nc ,
  input  logic                      io_uncache_resp_bits_denied,
  input  logic                      io_uncache_resp_bits_corrupt,
  output logic [63:0]               io_exceptionAddr_vaddr  ,
  output logic                      io_exceptionAddr_vaNeedExt,
  output logic                      io_exceptionAddr_isHyper,
  output logic [63:0]               io_exceptionAddr_gpaddr ,
  output logic                      io_exceptionAddr_isForVSnonLeafPTE,
  output logic                      io_flushSbuffer_valid   ,
  input  logic                      io_flushSbuffer_empty   ,
  output logic                      io_sqEmpty              ,
  output logic                      io_stAddrReadySqPtr_flag,
  output logic [5:0]                io_stAddrReadySqPtr_value,
  output logic                      io_stAddrReadyVec_0     ,
  output logic                      io_stAddrReadyVec_1     ,
  output logic                      io_stAddrReadyVec_2     ,
  output logic                      io_stAddrReadyVec_3     ,
  output logic                      io_stAddrReadyVec_4     ,
  output logic                      io_stAddrReadyVec_5     ,
  output logic                      io_stAddrReadyVec_6     ,
  output logic                      io_stAddrReadyVec_7     ,
  output logic                      io_stAddrReadyVec_8     ,
  output logic                      io_stAddrReadyVec_9     ,
  output logic                      io_stAddrReadyVec_10    ,
  output logic                      io_stAddrReadyVec_11    ,
  output logic                      io_stAddrReadyVec_12    ,
  output logic                      io_stAddrReadyVec_13    ,
  output logic                      io_stAddrReadyVec_14    ,
  output logic                      io_stAddrReadyVec_15    ,
  output logic                      io_stAddrReadyVec_16    ,
  output logic                      io_stAddrReadyVec_17    ,
  output logic                      io_stAddrReadyVec_18    ,
  output logic                      io_stAddrReadyVec_19    ,
  output logic                      io_stAddrReadyVec_20    ,
  output logic                      io_stAddrReadyVec_21    ,
  output logic                      io_stAddrReadyVec_22    ,
  output logic                      io_stAddrReadyVec_23    ,
  output logic                      io_stAddrReadyVec_24    ,
  output logic                      io_stAddrReadyVec_25    ,
  output logic                      io_stAddrReadyVec_26    ,
  output logic                      io_stAddrReadyVec_27    ,
  output logic                      io_stAddrReadyVec_28    ,
  output logic                      io_stAddrReadyVec_29    ,
  output logic                      io_stAddrReadyVec_30    ,
  output logic                      io_stAddrReadyVec_31    ,
  output logic                      io_stAddrReadyVec_32    ,
  output logic                      io_stAddrReadyVec_33    ,
  output logic                      io_stAddrReadyVec_34    ,
  output logic                      io_stAddrReadyVec_35    ,
  output logic                      io_stAddrReadyVec_36    ,
  output logic                      io_stAddrReadyVec_37    ,
  output logic                      io_stAddrReadyVec_38    ,
  output logic                      io_stAddrReadyVec_39    ,
  output logic                      io_stAddrReadyVec_40    ,
  output logic                      io_stAddrReadyVec_41    ,
  output logic                      io_stAddrReadyVec_42    ,
  output logic                      io_stAddrReadyVec_43    ,
  output logic                      io_stAddrReadyVec_44    ,
  output logic                      io_stAddrReadyVec_45    ,
  output logic                      io_stAddrReadyVec_46    ,
  output logic                      io_stAddrReadyVec_47    ,
  output logic                      io_stAddrReadyVec_48    ,
  output logic                      io_stAddrReadyVec_49    ,
  output logic                      io_stAddrReadyVec_50    ,
  output logic                      io_stAddrReadyVec_51    ,
  output logic                      io_stAddrReadyVec_52    ,
  output logic                      io_stAddrReadyVec_53    ,
  output logic                      io_stAddrReadyVec_54    ,
  output logic                      io_stAddrReadyVec_55    ,
  output logic                      io_stDataReadySqPtr_flag,
  output logic [5:0]                io_stDataReadySqPtr_value,
  output logic                      io_stDataReadyVec_0     ,
  output logic                      io_stDataReadyVec_1     ,
  output logic                      io_stDataReadyVec_2     ,
  output logic                      io_stDataReadyVec_3     ,
  output logic                      io_stDataReadyVec_4     ,
  output logic                      io_stDataReadyVec_5     ,
  output logic                      io_stDataReadyVec_6     ,
  output logic                      io_stDataReadyVec_7     ,
  output logic                      io_stDataReadyVec_8     ,
  output logic                      io_stDataReadyVec_9     ,
  output logic                      io_stDataReadyVec_10    ,
  output logic                      io_stDataReadyVec_11    ,
  output logic                      io_stDataReadyVec_12    ,
  output logic                      io_stDataReadyVec_13    ,
  output logic                      io_stDataReadyVec_14    ,
  output logic                      io_stDataReadyVec_15    ,
  output logic                      io_stDataReadyVec_16    ,
  output logic                      io_stDataReadyVec_17    ,
  output logic                      io_stDataReadyVec_18    ,
  output logic                      io_stDataReadyVec_19    ,
  output logic                      io_stDataReadyVec_20    ,
  output logic                      io_stDataReadyVec_21    ,
  output logic                      io_stDataReadyVec_22    ,
  output logic                      io_stDataReadyVec_23    ,
  output logic                      io_stDataReadyVec_24    ,
  output logic                      io_stDataReadyVec_25    ,
  output logic                      io_stDataReadyVec_26    ,
  output logic                      io_stDataReadyVec_27    ,
  output logic                      io_stDataReadyVec_28    ,
  output logic                      io_stDataReadyVec_29    ,
  output logic                      io_stDataReadyVec_30    ,
  output logic                      io_stDataReadyVec_31    ,
  output logic                      io_stDataReadyVec_32    ,
  output logic                      io_stDataReadyVec_33    ,
  output logic                      io_stDataReadyVec_34    ,
  output logic                      io_stDataReadyVec_35    ,
  output logic                      io_stDataReadyVec_36    ,
  output logic                      io_stDataReadyVec_37    ,
  output logic                      io_stDataReadyVec_38    ,
  output logic                      io_stDataReadyVec_39    ,
  output logic                      io_stDataReadyVec_40    ,
  output logic                      io_stDataReadyVec_41    ,
  output logic                      io_stDataReadyVec_42    ,
  output logic                      io_stDataReadyVec_43    ,
  output logic                      io_stDataReadyVec_44    ,
  output logic                      io_stDataReadyVec_45    ,
  output logic                      io_stDataReadyVec_46    ,
  output logic                      io_stDataReadyVec_47    ,
  output logic                      io_stDataReadyVec_48    ,
  output logic                      io_stDataReadyVec_49    ,
  output logic                      io_stDataReadyVec_50    ,
  output logic                      io_stDataReadyVec_51    ,
  output logic                      io_stDataReadyVec_52    ,
  output logic                      io_stDataReadyVec_53    ,
  output logic                      io_stDataReadyVec_54    ,
  output logic                      io_stDataReadyVec_55    ,
  output logic                      io_stIssuePtr_flag      ,
  output logic [5:0]                io_stIssuePtr_value     ,
  output logic                      io_sqDeqPtr_flag        ,
  output logic [5:0]                io_sqDeqPtr_value       ,
  output logic                      io_sqCommitPtr_flag     ,
  output logic [5:0]                io_sqCommitPtr_value    ,
  output logic [6:0]                io_sqCommitUopIdx       ,
  output logic                      io_sqCommitRobIdx_flag  ,
  output logic [7:0]                io_sqCommitRobIdx_value ,
  output logic                      io_sqFull               ,
  output logic [5:0]                io_sqCancelCnt          ,
  output logic [1:0]                io_sqDeq                ,
  output logic                      io_sqDeqIsVec           ,
  output logic                      io_force_write          ,
  input  logic                      io_maControl_toStoreQueue_crossPageWithHit,
  input  logic                      io_maControl_toStoreQueue_crossPageCanDeq,
  input  logic [47:0]               io_maControl_toStoreQueue_paddr,
  input  logic                      io_maControl_toStoreQueue_withSamePtr,
  output logic                      io_maControl_toStoreMisalignBuffer_sqPtr_flag,
  output logic [5:0]                io_maControl_toStoreMisalignBuffer_sqPtr_value,
  output logic                      io_maControl_toStoreMisalignBuffer_doDeq,
  output logic [6:0]                io_maControl_toStoreMisalignBuffer_uop_uopIdx,
  output logic                      io_maControl_toStoreMisalignBuffer_uop_robIdx_flag,
  output logic [7:0]                io_maControl_toStoreMisalignBuffer_uop_robIdx_value,
  input  logic                      io_wfi_wfiReq           ,
  output logic                      io_wfi_wfiSafe          ,
  output logic                      io_diffStore_ncStore_valid,
  output logic [47:0]               io_diffStore_ncStore_bits_addr,
  output logic [63:0]               io_diffStore_ncStore_bits_data,
  output logic [7:0]                io_diffStore_ncStore_bits_mask,
  output logic                      io_diffStore_ncStore_bits_memBackTypeMM,
  output logic [72:0]               gatewayIn_packed_48_bore
);


// -----------------------------------------------------------------------------
// §3 per-entry 状态 —— ★复位域是 golden 实测，不是照 Chisel 抄★
// -----------------------------------------------------------------------------
  // golden 只有两个时序块，泾渭分明（scripts/gen_storequeue.py --reset-audit 可复跑）：
  //   always @(posedge clock or posedge reset)  L62202-69650  1076 reg  异步复位
  //   always @(posedge clock)                   L20336-58753  2913 reg  ★完全不复位★
  //   1076 + 2913 = 3989 = golden reg 声明总数（守恒）
  // 把不复位的那 2913 个照抄成「有复位」是真 bug，elaborate 与 lint 都不会报。

  // ---- 异步复位到 0 的 per-entry 标志位（每条 56 位）----
  logic [SQ_SIZE-1:0] allocated;       // 条目已分配（活 store）
  logic [SQ_SIZE-1:0] completed;       // 数据已离开 SQ（可退队），与 committed 不同
  logic [SQ_SIZE-1:0] addrvalid;       // sta 已写入 paddr/vaddr/mask（或被异常强置）
  logic [SQ_SIZE-1:0] datavalid;       // std 已写入数据（fire 后 1 拍）
  logic [SQ_SIZE-1:0] committed;       // ROB 已提交，不可撤销（挡 needCancel）
  logic [SQ_SIZE-1:0] unaligned;       // 非对齐 store
  logic [SQ_SIZE-1:0] cross16Byte;     // 非对齐且跨 16B，需要 2 拍拆分
  logic [SQ_SIZE-1:0] pending;         // mmio，等着走到 ROB 头
  logic [SQ_SIZE-1:0] nc;              // 不可缓存（pbmt NC）
  logic [SQ_SIZE-1:0] mmio;            // mmio
  logic [SQ_SIZE-1:0] memBackTypeMM;   // ★入队时不清★——见 §TRAP-2
  logic [SQ_SIZE-1:0] isVec;           // 向量 store，只在入队时写
  logic [SQ_SIZE-1:0] vecLastFlow;     // 本条目是向量 uop 的最后一个 flow，只在入队时写
  logic [SQ_SIZE-1:0] vecMbCommit;     // 向量 merge buffer 判了 commit/flush
  logic [SQ_SIZE-1:0] hasException;    // 该退队但不许写 sbuffer
  logic [SQ_SIZE-1:0] waitStoreS2;     // 仍在等 store_s2 的 mmio/异常裁决；入队置 1

  // allvalid 在 golden 里是**组合线**，不是寄存器（Chisel SQ:259 是 Wire）。
  logic [SQ_SIZE-1:0] allvalid;
  assign allvalid = addrvalid & datavalid & allocated;

  // ---- 就绪向量输出寄存器（golden r_* / r_1_*）----
  // Chisel 是 GatedValidRegNext：使能 = 「整条 56 位次态 != 现值」，异步复位 0。
  // 该使能与「无条件 RegNext」功能等价（次态等于现值时写不写都一样），
  // 但 golden 里确实是带使能的形式；这里照抄结构，别化简。
  logic [SQ_SIZE-1:0] stAddrReadyVec_q;    // golden `r_*` -> io_stAddrReadyVec_*
  logic [SQ_SIZE-1:0] stDataReadyVec_q;    // golden `r_1_*` -> io_stDataReadyVec_*
  logic [SQ_SIZE-1:0] stAddrReadyVecReg, stDataReadyVecReg; // 组合次态

  // ---- 指针 ----
  // ★DCE 形状必须照抄★（golden 实测，多写出来的就是 unread，FM 判 PARTIAL）：
  //   enqPtrExt   Chisel 6 份，golden **只剩第 0 份**（1..5 flag+value 全死）
  //   cmtPtrExt   Chisel 8 份，golden 保留 8 份 value，但 **只有第 0 份有 flag**
  //   deqPtrExt   2 份，两份的 flag 与 value **都活**
  //               （Chisel 侧分析曾判 deqPtrExt(1).flag 已死 —— golden 实测是活的，
  //                 L69109 的 dataPtrInDeqGroupRangeVec 读它。以 golden 为准。）
  //   rdataPtrExt 2 份全活（第 1 份 flag 经 dataBuffer 逃逸到 cboZeroStout.sqIdx）
  sqptr_t                     enqPtrExt;               // 仅第 0 份
  sqptr_t                     deqPtrExt   [N_ENSBUF];
  sqptr_t                     rdataPtrExt [N_ENSBUF];
  logic [SQ_IDX_W-1:0]        cmtPtrValue [N_COMMIT];  // 8 份 value
  logic                       cmtPtrFlag;              // ★只有第 0 份有 flag★
  sqptr_t                     addrReadyPtrExt, dataReadyPtrExt;

  // ---- 不复位的 per-entry 载荷（golden 的 2913 个无复位 reg 的主体）----
  // 每条目一份 uop 快照：24 位 exceptionVec + 26 个字段。整块**不复位**。
  // ★按「一个字段一个 56 项数组」声明★，不要打包成 struct 数组：上一轮
  //   用 struct 数组导致 FM 与 golden 的扁平标量 allocated_N 约 35K 个寄存器
  //   配对不收敛，大量 unverified（见 xs-v2r2-sv/docs/memblock/StoreQueue.md §7.3）。
  logic [23:0]  uop_exceptionVec [SQ_SIZE];
  logic [34:0]  uop_fuType       [SQ_SIZE];
  logic [8:0]   uop_fuOpType     [SQ_SIZE];
  logic [7:0]   uop_robIdx_value [SQ_SIZE];
  logic         uop_robIdx_flag  [SQ_SIZE];
  logic [6:0]   uop_uopIdx       [SQ_SIZE];
  // TODO(§9-A) 其余 uop 字段照 golden 端口表补全（共 52 个，勿凭记忆列）。


// -----------------------------------------------------------------------------
// §4 多源写优先级骨架 —— ★条件线名照 golden，方程未追清处标 TODO★
// -----------------------------------------------------------------------------
  // golden 实测的写优先级（最高在前）。条件线在 golden 里是 _GEN_*，
  // 这里给它们取回可读名；**方程本身尚未逐条追清**，见 §9。
  //
  //   uop 载荷 / nc / unaligned / cross16Byte：
  //       sta 口1-s1  >  sta 口0-s1  >  入队分配
  //       （golden L20337: if(_GEN_553) else if(_GEN_497) else if(entryCanEnq)；
  //         _GEN_553 = io_storeAddrIn_1_valid & 命中本条目）
  //   addrvalid / mmio / memBackTypeMM / hasException：
  //       口1-s2 > 口1-s1 > 口0-s2 > 口0-s1 > 入队
  //       ★不是「s2 一律压 s1」★——两条流水是展开的，口1 的 s1 压过口0 的 s2。
  //       （golden L63833-63849 的四层 if/else 就是这个形状）
  //   allocated  ：needCancel(冲刷) > 入队置位 > 退队清零
  //   completed  ：needCancel > sbuffer 回执 > 提交时 nc&异常 > cboZero 回写
  //                > mmio 回写 > NC 完成 > 入队清零 > 退队清零
  //   pending    ：mmio 发请求时清零 > 口1-s2 > 口0-s2 > 入队
  //   vecMbCommit：maControl.withSamePtr > 向量反馈 > 入队清零

  // ===================== ★TRAP-2：memBackTypeMM 不清 ★ =====================
  // golden L63835/63843 只在两个 sta-s2 分支里写 memBackTypeMM，最内层 else
  // **没有** `~entryCanEnq & memBackTypeMM` 这一项 —— 而同一组里的 mmio 与
  // hasException 都有。也就是说：入队**不清** memBackTypeMM，它会保留上一个
  // 占用者的值，直到某次 sta-s2 覆盖。Chisel 侧同样确认（入队清零清单里没有它）。
  // 顺手抹平成「入队一起清」是真 bug，UT 极难打到。
  // =======================================================================

  // TODO(§9-B) entryCanEnq / needCancel / 各 _GEN_ 条件的方程


// -----------------------------------------------------------------------------
// §5 子模块例化 —— ★5 个子模块在本仓一个都没有实现★
// -----------------------------------------------------------------------------
  // golden 例化 5 个（G0 与 G1 相同的 5 个，实例名照抄）：
  //   dataModule      SQDataModule   (56,rd2,wr2,fwd3)  内部 16×SQData8Module 按字节分道
  //   paddrModule     SQAddrModule   (dataWidth=48)     物理地址阵列 + 地址 CAM
  //   vaddrModule     SQAddrModule_1 (dataWidth=50)     虚地址阵列 + 地址 CAM（转发用它选）
  //   dataBuffer      DatamoduleResultBuffer            SQ 读出级到 Sbuffer 的 2 项 skid
  //   exceptionBuffer StoreExceptionBuffer              7 口单条目「最老者胜」异常地址锁存
  // paddrModule/vaddrModule 是同一个 Chisel 类的两次不同 dataWidth 例化，
  // 可读实现应写成一个参数化核 + 两个薄 wrapper（家族规则）。
  //
  // ★状态★：这 5 个在 docs/g1_configured_universe.tsv 里都是 new_target，
  //   rtl/ 下**一个都不存在**；docs/g1_universe.tsv 只收了 StoreExceptionBuffer。
  //   docs/migration_plan_199.tsv 的 StoreQueue 行记 n_children_todo=1，
  //   ★漏记了另外 4 个★。StoreQueue 的签核在它们落地前无法闭合。
  // TODO(§9-C) 5 个子模块的例化与绑定


// -----------------------------------------------------------------------------
// §6 组合输出 —— TODO
// -----------------------------------------------------------------------------
  // TODO(§9-D) 全部 399 根输出的驱动


// -----------------------------------------------------------------------------
// §7 时序：异步复位块（对应 golden L62202-69650）
// -----------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      allocated        <= '0;
      completed        <= '0;
      addrvalid        <= '0;
      datavalid        <= '0;
      committed        <= '0;
      unaligned        <= '0;
      cross16Byte      <= '0;
      pending          <= '0;
      nc               <= '0;
      mmio             <= '0;
      memBackTypeMM    <= '0;
      isVec            <= '0;
      vecLastFlow      <= '0;
      vecMbCommit      <= '0;
      hasException     <= '0;
      waitStoreS2      <= '0;
      stAddrReadyVec_q <= '0;
      stDataReadyVec_q <= '0;
      // TODO(§9-E) 指针的复位初值：enq/deq/rdata/cmt 的第 i 份复位成 value=i,flag=0
    end
    else begin
      // TODO(§9-E) 按 §4 的优先级填次态
    end
  end


// -----------------------------------------------------------------------------
// §8 时序：★不复位★块（对应 golden L20336-58753，2913 个 reg）
// -----------------------------------------------------------------------------
  // 这里**故意没有 if (reset)**——golden 这一整块不复位。加上复位就是真 bug。
  always_ff @(posedge clock) begin
    // TODO(§9-A) uop 载荷按「口1-s1 > 口0-s1 > 入队」三级优先级锁存
  end


// -----------------------------------------------------------------------------
// §9 待办清单 —— ★尚未追清的方程，逐条列明，不许含糊★
// -----------------------------------------------------------------------------
//   A. uop 载荷 52 个字段的完整清单与三级优先级锁存（结构已确认，字段未逐条对齐）
//   B. entryCanEnq（6 路 dispatch 的环形区间覆盖判定）与 needCancel（含向量异常旗标的
//      「严格在后」变体）的方程 —— 两者都只从 Chisel 读过，未在 golden 上核对
//   C. 5 个子模块（SQDataModule/SQAddrModule/SQAddrModule_1/DatamoduleResultBuffer/
//      StoreExceptionBuffer）的重写，本仓一个都没有
//   D. 399 根输出的驱动方程，其中这些整块未追：
//      · store-to-load 转发（3 口 CAM、forwardMask1/2 的 deqMask 区间选择、
//        dataInvalid 里「任意已分配的非对齐 store 无条件致 dataInvalid」这条怪规则）
//      · 出队到 dataBuffer/Sbuffer 的三分支（跨 16B 拆分 / 非跨 16B 非对齐 / 常规）
//      · mmio 5 态 FSM 与 NC 4 态 FSM，以及 CBO 分支对 FSM 的**越权覆盖**
//      · cboZero 通路、向量通路（vecExceptionFlag 的 set/clear 优先级）
//      · 跨 4K 页到 StoreMisalignBuffer 的交接
//      · 8 路 perf 计数与 difftest 的 diffStore / gatewayIn_packed_48_bore
//   D2. ★perf 观测探针★：golden 里有 15 个 `*_probe` 线，SimTop 的 perf 台账通过
//      XMR 观测它们（docs/perf_bore_map.tsv 里 21 行绑到 StoreQueue）。本文件一进
//      rtl/，这 21 行就从 T0_UNCHANGED 掉到未绑定 —— 可读核必须**按同名导出**：
//        empty_probe / empty_1_probe / exHalf_probe / exHalf_1_probe
//        _io_sqFull_T_probe / mmioDoReq_probe / validCount_probe
//        perfEvents_0_2_probe / perfEvents_2_2_probe
//        vpmaskNotEqual{,_1,_2}_probe / vaddrMatchFailed{,_1,_2}_probe
//      （★不许接零冒充已绑★，见 docs/perf_bore_unbound.tsv 的口径）
//   E. 全部指针推进方程（sqDeqCnt 的「循环内后写者胜」、readyReadGoVec 的组合链、
//      addrReady/dataReadyPtr 的 stride<=4 推进与冲刷时的强制值）
//   F. ★rdataPtr 与 deqPtr 是两个独立计数器★，RAM 读地址用的是 rdataPtrExtNext（提前一拍），
//      模块内部再寄存一次。这条极易写错，必须在 UT 里单独钉。
//   G. ★读锁存值还是读 live 值★ —— 上一轮在这里出过一个真 bug：
//      io_cmoOpReq_bits_opcode 取了 uop[deqPtr].fuOpType 的**当前值**。
//      本轮已在 G1 golden 上复核（不是凭记忆），钉死如下：
//        StoreQueue.sv:76759  assign io_cmoOpReq_bits_opcode = {1'h0, uncacheUop_fuOpType[1:0]};
//        StoreQueue.sv:12951  reg  [8:0] uncacheUop_fuOpType;      <- 是**寄存器**
//        StoreQueue.sv:58436  uncacheUop_fuOpType <= _GEN_380;     <- 在不复位块里锁存
//                             （always @(posedge clock) 自 L20336 起，条件 _GEN_388）
//      即 golden 读的是**锁存的那一拍**，不是 uop[deqPtr] 的 live 值。
//      uncacheUop_* 这一整族（fuOpType/rfWen/uopIdx/pdest/robIdx_* ...）都是同一个
//      锁存组，写 uncache/CBO 通路时一律读锁存值。这类错只在特定时序下暴露，
//      随机 UT 不保证抓得到，必须**按构造**写对。

endmodule


// -----------------------------------------------------------------------------
// §10 StoreQueue —— golden 同名 wrapper（1003 根端口，逐位对齐）
// -----------------------------------------------------------------------------
module StoreQueue(
  input             clock,
  input             reset,
  input  [5:0]      io_hartId,
  output            io_enq_canAccept,
  input             io_enq_lqCanAccept,
  input             io_enq_needAlloc_0,
  input             io_enq_needAlloc_1,
  input             io_enq_needAlloc_2,
  input             io_enq_needAlloc_3,
  input             io_enq_needAlloc_4,
  input             io_enq_req_0_valid,
  input             io_enq_req_0_bits_exceptionVec_0,
  input             io_enq_req_0_bits_exceptionVec_1,
  input             io_enq_req_0_bits_exceptionVec_2,
  input             io_enq_req_0_bits_exceptionVec_3,
  input             io_enq_req_0_bits_exceptionVec_4,
  input             io_enq_req_0_bits_exceptionVec_5,
  input             io_enq_req_0_bits_exceptionVec_6,
  input             io_enq_req_0_bits_exceptionVec_7,
  input             io_enq_req_0_bits_exceptionVec_8,
  input             io_enq_req_0_bits_exceptionVec_9,
  input             io_enq_req_0_bits_exceptionVec_10,
  input             io_enq_req_0_bits_exceptionVec_11,
  input             io_enq_req_0_bits_exceptionVec_12,
  input             io_enq_req_0_bits_exceptionVec_13,
  input             io_enq_req_0_bits_exceptionVec_14,
  input             io_enq_req_0_bits_exceptionVec_15,
  input             io_enq_req_0_bits_exceptionVec_16,
  input             io_enq_req_0_bits_exceptionVec_17,
  input             io_enq_req_0_bits_exceptionVec_18,
  input             io_enq_req_0_bits_exceptionVec_19,
  input             io_enq_req_0_bits_exceptionVec_20,
  input             io_enq_req_0_bits_exceptionVec_21,
  input             io_enq_req_0_bits_exceptionVec_22,
  input             io_enq_req_0_bits_exceptionVec_23,
  input  [3:0]      io_enq_req_0_bits_trigger,
  input  [34:0]     io_enq_req_0_bits_fuType,
  input  [8:0]      io_enq_req_0_bits_fuOpType,
  input             io_enq_req_0_bits_rfWen,
  input             io_enq_req_0_bits_flushPipe,
  input  [2:0]      io_enq_req_0_bits_vpu_nf,
  input  [1:0]      io_enq_req_0_bits_vpu_veew,
  input  [6:0]      io_enq_req_0_bits_uopIdx,
  input             io_enq_req_0_bits_lastUop,
  input  [7:0]      io_enq_req_0_bits_pdest,
  input             io_enq_req_0_bits_robIdx_flag,
  input  [7:0]      io_enq_req_0_bits_robIdx_value,
  input             io_enq_req_0_bits_debugInfo_eliminatedMove,
  input  [63:0]     io_enq_req_0_bits_debugInfo_renameTime,
  input  [63:0]     io_enq_req_0_bits_debugInfo_dispatchTime,
  input  [63:0]     io_enq_req_0_bits_debugInfo_enqRsTime,
  input  [63:0]     io_enq_req_0_bits_debugInfo_selectTime,
  input  [63:0]     io_enq_req_0_bits_debugInfo_issueTime,
  input  [63:0]     io_enq_req_0_bits_debugInfo_writebackTime,
  input  [63:0]     io_enq_req_0_bits_debugInfo_runahead_checkpoint_id,
  input  [63:0]     io_enq_req_0_bits_debugInfo_tlbFirstReqTime,
  input  [63:0]     io_enq_req_0_bits_debugInfo_tlbRespTime,
  input  [55:0]     io_enq_req_0_bits_debug_seqNum_seqNum,
  input  [7:0]      io_enq_req_0_bits_debug_seqNum_uopIdx,
  input             io_enq_req_0_bits_sqIdx_flag,
  input  [5:0]      io_enq_req_0_bits_sqIdx_value,
  input  [4:0]      io_enq_req_0_bits_numLsElem,
  input             io_enq_req_1_valid,
  input             io_enq_req_1_bits_exceptionVec_0,
  input             io_enq_req_1_bits_exceptionVec_1,
  input             io_enq_req_1_bits_exceptionVec_2,
  input             io_enq_req_1_bits_exceptionVec_3,
  input             io_enq_req_1_bits_exceptionVec_4,
  input             io_enq_req_1_bits_exceptionVec_5,
  input             io_enq_req_1_bits_exceptionVec_6,
  input             io_enq_req_1_bits_exceptionVec_7,
  input             io_enq_req_1_bits_exceptionVec_8,
  input             io_enq_req_1_bits_exceptionVec_9,
  input             io_enq_req_1_bits_exceptionVec_10,
  input             io_enq_req_1_bits_exceptionVec_11,
  input             io_enq_req_1_bits_exceptionVec_12,
  input             io_enq_req_1_bits_exceptionVec_13,
  input             io_enq_req_1_bits_exceptionVec_14,
  input             io_enq_req_1_bits_exceptionVec_15,
  input             io_enq_req_1_bits_exceptionVec_16,
  input             io_enq_req_1_bits_exceptionVec_17,
  input             io_enq_req_1_bits_exceptionVec_18,
  input             io_enq_req_1_bits_exceptionVec_19,
  input             io_enq_req_1_bits_exceptionVec_20,
  input             io_enq_req_1_bits_exceptionVec_21,
  input             io_enq_req_1_bits_exceptionVec_22,
  input             io_enq_req_1_bits_exceptionVec_23,
  input  [3:0]      io_enq_req_1_bits_trigger,
  input  [34:0]     io_enq_req_1_bits_fuType,
  input  [8:0]      io_enq_req_1_bits_fuOpType,
  input             io_enq_req_1_bits_rfWen,
  input             io_enq_req_1_bits_flushPipe,
  input  [2:0]      io_enq_req_1_bits_vpu_nf,
  input  [1:0]      io_enq_req_1_bits_vpu_veew,
  input  [6:0]      io_enq_req_1_bits_uopIdx,
  input             io_enq_req_1_bits_lastUop,
  input  [7:0]      io_enq_req_1_bits_pdest,
  input             io_enq_req_1_bits_robIdx_flag,
  input  [7:0]      io_enq_req_1_bits_robIdx_value,
  input             io_enq_req_1_bits_debugInfo_eliminatedMove,
  input  [63:0]     io_enq_req_1_bits_debugInfo_renameTime,
  input  [63:0]     io_enq_req_1_bits_debugInfo_dispatchTime,
  input  [63:0]     io_enq_req_1_bits_debugInfo_enqRsTime,
  input  [63:0]     io_enq_req_1_bits_debugInfo_selectTime,
  input  [63:0]     io_enq_req_1_bits_debugInfo_issueTime,
  input  [63:0]     io_enq_req_1_bits_debugInfo_writebackTime,
  input  [63:0]     io_enq_req_1_bits_debugInfo_runahead_checkpoint_id,
  input  [63:0]     io_enq_req_1_bits_debugInfo_tlbFirstReqTime,
  input  [63:0]     io_enq_req_1_bits_debugInfo_tlbRespTime,
  input  [55:0]     io_enq_req_1_bits_debug_seqNum_seqNum,
  input  [7:0]      io_enq_req_1_bits_debug_seqNum_uopIdx,
  input             io_enq_req_1_bits_sqIdx_flag,
  input  [5:0]      io_enq_req_1_bits_sqIdx_value,
  input  [4:0]      io_enq_req_1_bits_numLsElem,
  input             io_enq_req_2_valid,
  input             io_enq_req_2_bits_exceptionVec_0,
  input             io_enq_req_2_bits_exceptionVec_1,
  input             io_enq_req_2_bits_exceptionVec_2,
  input             io_enq_req_2_bits_exceptionVec_3,
  input             io_enq_req_2_bits_exceptionVec_4,
  input             io_enq_req_2_bits_exceptionVec_5,
  input             io_enq_req_2_bits_exceptionVec_6,
  input             io_enq_req_2_bits_exceptionVec_7,
  input             io_enq_req_2_bits_exceptionVec_8,
  input             io_enq_req_2_bits_exceptionVec_9,
  input             io_enq_req_2_bits_exceptionVec_10,
  input             io_enq_req_2_bits_exceptionVec_11,
  input             io_enq_req_2_bits_exceptionVec_12,
  input             io_enq_req_2_bits_exceptionVec_13,
  input             io_enq_req_2_bits_exceptionVec_14,
  input             io_enq_req_2_bits_exceptionVec_15,
  input             io_enq_req_2_bits_exceptionVec_16,
  input             io_enq_req_2_bits_exceptionVec_17,
  input             io_enq_req_2_bits_exceptionVec_18,
  input             io_enq_req_2_bits_exceptionVec_19,
  input             io_enq_req_2_bits_exceptionVec_20,
  input             io_enq_req_2_bits_exceptionVec_21,
  input             io_enq_req_2_bits_exceptionVec_22,
  input             io_enq_req_2_bits_exceptionVec_23,
  input  [3:0]      io_enq_req_2_bits_trigger,
  input  [34:0]     io_enq_req_2_bits_fuType,
  input  [8:0]      io_enq_req_2_bits_fuOpType,
  input             io_enq_req_2_bits_rfWen,
  input             io_enq_req_2_bits_flushPipe,
  input  [2:0]      io_enq_req_2_bits_vpu_nf,
  input  [1:0]      io_enq_req_2_bits_vpu_veew,
  input  [6:0]      io_enq_req_2_bits_uopIdx,
  input             io_enq_req_2_bits_lastUop,
  input  [7:0]      io_enq_req_2_bits_pdest,
  input             io_enq_req_2_bits_robIdx_flag,
  input  [7:0]      io_enq_req_2_bits_robIdx_value,
  input             io_enq_req_2_bits_debugInfo_eliminatedMove,
  input  [63:0]     io_enq_req_2_bits_debugInfo_renameTime,
  input  [63:0]     io_enq_req_2_bits_debugInfo_dispatchTime,
  input  [63:0]     io_enq_req_2_bits_debugInfo_enqRsTime,
  input  [63:0]     io_enq_req_2_bits_debugInfo_selectTime,
  input  [63:0]     io_enq_req_2_bits_debugInfo_issueTime,
  input  [63:0]     io_enq_req_2_bits_debugInfo_writebackTime,
  input  [63:0]     io_enq_req_2_bits_debugInfo_runahead_checkpoint_id,
  input  [63:0]     io_enq_req_2_bits_debugInfo_tlbFirstReqTime,
  input  [63:0]     io_enq_req_2_bits_debugInfo_tlbRespTime,
  input  [55:0]     io_enq_req_2_bits_debug_seqNum_seqNum,
  input  [7:0]      io_enq_req_2_bits_debug_seqNum_uopIdx,
  input             io_enq_req_2_bits_sqIdx_flag,
  input  [5:0]      io_enq_req_2_bits_sqIdx_value,
  input  [4:0]      io_enq_req_2_bits_numLsElem,
  input             io_enq_req_3_valid,
  input             io_enq_req_3_bits_exceptionVec_0,
  input             io_enq_req_3_bits_exceptionVec_1,
  input             io_enq_req_3_bits_exceptionVec_2,
  input             io_enq_req_3_bits_exceptionVec_3,
  input             io_enq_req_3_bits_exceptionVec_4,
  input             io_enq_req_3_bits_exceptionVec_5,
  input             io_enq_req_3_bits_exceptionVec_6,
  input             io_enq_req_3_bits_exceptionVec_7,
  input             io_enq_req_3_bits_exceptionVec_8,
  input             io_enq_req_3_bits_exceptionVec_9,
  input             io_enq_req_3_bits_exceptionVec_10,
  input             io_enq_req_3_bits_exceptionVec_11,
  input             io_enq_req_3_bits_exceptionVec_12,
  input             io_enq_req_3_bits_exceptionVec_13,
  input             io_enq_req_3_bits_exceptionVec_14,
  input             io_enq_req_3_bits_exceptionVec_15,
  input             io_enq_req_3_bits_exceptionVec_16,
  input             io_enq_req_3_bits_exceptionVec_17,
  input             io_enq_req_3_bits_exceptionVec_18,
  input             io_enq_req_3_bits_exceptionVec_19,
  input             io_enq_req_3_bits_exceptionVec_20,
  input             io_enq_req_3_bits_exceptionVec_21,
  input             io_enq_req_3_bits_exceptionVec_22,
  input             io_enq_req_3_bits_exceptionVec_23,
  input  [3:0]      io_enq_req_3_bits_trigger,
  input  [34:0]     io_enq_req_3_bits_fuType,
  input  [8:0]      io_enq_req_3_bits_fuOpType,
  input             io_enq_req_3_bits_rfWen,
  input             io_enq_req_3_bits_flushPipe,
  input  [2:0]      io_enq_req_3_bits_vpu_nf,
  input  [1:0]      io_enq_req_3_bits_vpu_veew,
  input  [6:0]      io_enq_req_3_bits_uopIdx,
  input             io_enq_req_3_bits_lastUop,
  input  [7:0]      io_enq_req_3_bits_pdest,
  input             io_enq_req_3_bits_robIdx_flag,
  input  [7:0]      io_enq_req_3_bits_robIdx_value,
  input             io_enq_req_3_bits_debugInfo_eliminatedMove,
  input  [63:0]     io_enq_req_3_bits_debugInfo_renameTime,
  input  [63:0]     io_enq_req_3_bits_debugInfo_dispatchTime,
  input  [63:0]     io_enq_req_3_bits_debugInfo_enqRsTime,
  input  [63:0]     io_enq_req_3_bits_debugInfo_selectTime,
  input  [63:0]     io_enq_req_3_bits_debugInfo_issueTime,
  input  [63:0]     io_enq_req_3_bits_debugInfo_writebackTime,
  input  [63:0]     io_enq_req_3_bits_debugInfo_runahead_checkpoint_id,
  input  [63:0]     io_enq_req_3_bits_debugInfo_tlbFirstReqTime,
  input  [63:0]     io_enq_req_3_bits_debugInfo_tlbRespTime,
  input  [55:0]     io_enq_req_3_bits_debug_seqNum_seqNum,
  input  [7:0]      io_enq_req_3_bits_debug_seqNum_uopIdx,
  input             io_enq_req_3_bits_sqIdx_flag,
  input  [5:0]      io_enq_req_3_bits_sqIdx_value,
  input  [4:0]      io_enq_req_3_bits_numLsElem,
  input             io_enq_req_4_valid,
  input             io_enq_req_4_bits_exceptionVec_0,
  input             io_enq_req_4_bits_exceptionVec_1,
  input             io_enq_req_4_bits_exceptionVec_2,
  input             io_enq_req_4_bits_exceptionVec_3,
  input             io_enq_req_4_bits_exceptionVec_4,
  input             io_enq_req_4_bits_exceptionVec_5,
  input             io_enq_req_4_bits_exceptionVec_6,
  input             io_enq_req_4_bits_exceptionVec_7,
  input             io_enq_req_4_bits_exceptionVec_8,
  input             io_enq_req_4_bits_exceptionVec_9,
  input             io_enq_req_4_bits_exceptionVec_10,
  input             io_enq_req_4_bits_exceptionVec_11,
  input             io_enq_req_4_bits_exceptionVec_12,
  input             io_enq_req_4_bits_exceptionVec_13,
  input             io_enq_req_4_bits_exceptionVec_14,
  input             io_enq_req_4_bits_exceptionVec_15,
  input             io_enq_req_4_bits_exceptionVec_16,
  input             io_enq_req_4_bits_exceptionVec_17,
  input             io_enq_req_4_bits_exceptionVec_18,
  input             io_enq_req_4_bits_exceptionVec_19,
  input             io_enq_req_4_bits_exceptionVec_20,
  input             io_enq_req_4_bits_exceptionVec_21,
  input             io_enq_req_4_bits_exceptionVec_22,
  input             io_enq_req_4_bits_exceptionVec_23,
  input  [3:0]      io_enq_req_4_bits_trigger,
  input  [34:0]     io_enq_req_4_bits_fuType,
  input  [8:0]      io_enq_req_4_bits_fuOpType,
  input             io_enq_req_4_bits_rfWen,
  input             io_enq_req_4_bits_flushPipe,
  input  [2:0]      io_enq_req_4_bits_vpu_nf,
  input  [1:0]      io_enq_req_4_bits_vpu_veew,
  input  [6:0]      io_enq_req_4_bits_uopIdx,
  input             io_enq_req_4_bits_lastUop,
  input  [7:0]      io_enq_req_4_bits_pdest,
  input             io_enq_req_4_bits_robIdx_flag,
  input  [7:0]      io_enq_req_4_bits_robIdx_value,
  input             io_enq_req_4_bits_debugInfo_eliminatedMove,
  input  [63:0]     io_enq_req_4_bits_debugInfo_renameTime,
  input  [63:0]     io_enq_req_4_bits_debugInfo_dispatchTime,
  input  [63:0]     io_enq_req_4_bits_debugInfo_enqRsTime,
  input  [63:0]     io_enq_req_4_bits_debugInfo_selectTime,
  input  [63:0]     io_enq_req_4_bits_debugInfo_issueTime,
  input  [63:0]     io_enq_req_4_bits_debugInfo_writebackTime,
  input  [63:0]     io_enq_req_4_bits_debugInfo_runahead_checkpoint_id,
  input  [63:0]     io_enq_req_4_bits_debugInfo_tlbFirstReqTime,
  input  [63:0]     io_enq_req_4_bits_debugInfo_tlbRespTime,
  input  [55:0]     io_enq_req_4_bits_debug_seqNum_seqNum,
  input  [7:0]      io_enq_req_4_bits_debug_seqNum_uopIdx,
  input             io_enq_req_4_bits_sqIdx_flag,
  input  [5:0]      io_enq_req_4_bits_sqIdx_value,
  input  [4:0]      io_enq_req_4_bits_numLsElem,
  input             io_enq_req_5_valid,
  input             io_enq_req_5_bits_exceptionVec_0,
  input             io_enq_req_5_bits_exceptionVec_1,
  input             io_enq_req_5_bits_exceptionVec_2,
  input             io_enq_req_5_bits_exceptionVec_3,
  input             io_enq_req_5_bits_exceptionVec_4,
  input             io_enq_req_5_bits_exceptionVec_5,
  input             io_enq_req_5_bits_exceptionVec_6,
  input             io_enq_req_5_bits_exceptionVec_7,
  input             io_enq_req_5_bits_exceptionVec_8,
  input             io_enq_req_5_bits_exceptionVec_9,
  input             io_enq_req_5_bits_exceptionVec_10,
  input             io_enq_req_5_bits_exceptionVec_11,
  input             io_enq_req_5_bits_exceptionVec_12,
  input             io_enq_req_5_bits_exceptionVec_13,
  input             io_enq_req_5_bits_exceptionVec_14,
  input             io_enq_req_5_bits_exceptionVec_15,
  input             io_enq_req_5_bits_exceptionVec_16,
  input             io_enq_req_5_bits_exceptionVec_17,
  input             io_enq_req_5_bits_exceptionVec_18,
  input             io_enq_req_5_bits_exceptionVec_19,
  input             io_enq_req_5_bits_exceptionVec_20,
  input             io_enq_req_5_bits_exceptionVec_21,
  input             io_enq_req_5_bits_exceptionVec_22,
  input             io_enq_req_5_bits_exceptionVec_23,
  input  [3:0]      io_enq_req_5_bits_trigger,
  input  [34:0]     io_enq_req_5_bits_fuType,
  input  [8:0]      io_enq_req_5_bits_fuOpType,
  input             io_enq_req_5_bits_rfWen,
  input             io_enq_req_5_bits_flushPipe,
  input  [2:0]      io_enq_req_5_bits_vpu_nf,
  input  [1:0]      io_enq_req_5_bits_vpu_veew,
  input  [6:0]      io_enq_req_5_bits_uopIdx,
  input             io_enq_req_5_bits_lastUop,
  input  [7:0]      io_enq_req_5_bits_pdest,
  input             io_enq_req_5_bits_robIdx_flag,
  input  [7:0]      io_enq_req_5_bits_robIdx_value,
  input             io_enq_req_5_bits_debugInfo_eliminatedMove,
  input  [63:0]     io_enq_req_5_bits_debugInfo_renameTime,
  input  [63:0]     io_enq_req_5_bits_debugInfo_dispatchTime,
  input  [63:0]     io_enq_req_5_bits_debugInfo_enqRsTime,
  input  [63:0]     io_enq_req_5_bits_debugInfo_selectTime,
  input  [63:0]     io_enq_req_5_bits_debugInfo_issueTime,
  input  [63:0]     io_enq_req_5_bits_debugInfo_writebackTime,
  input  [63:0]     io_enq_req_5_bits_debugInfo_runahead_checkpoint_id,
  input  [63:0]     io_enq_req_5_bits_debugInfo_tlbFirstReqTime,
  input  [63:0]     io_enq_req_5_bits_debugInfo_tlbRespTime,
  input  [55:0]     io_enq_req_5_bits_debug_seqNum_seqNum,
  input  [7:0]      io_enq_req_5_bits_debug_seqNum_uopIdx,
  input             io_enq_req_5_bits_sqIdx_flag,
  input  [5:0]      io_enq_req_5_bits_sqIdx_value,
  input  [4:0]      io_enq_req_5_bits_numLsElem,
  input             io_brqRedirect_valid,
  input             io_brqRedirect_bits_robIdx_flag,
  input  [7:0]      io_brqRedirect_bits_robIdx_value,
  input             io_brqRedirect_bits_level,
  input             io_vecFeedback_0_valid,
  input             io_vecFeedback_0_bits_robidx_flag,
  input  [7:0]      io_vecFeedback_0_bits_robidx_value,
  input  [6:0]      io_vecFeedback_0_bits_uopidx,
  input  [63:0]     io_vecFeedback_0_bits_vaddr,
  input             io_vecFeedback_0_bits_vaNeedExt,
  input  [63:0]     io_vecFeedback_0_bits_gpaddr,
  input             io_vecFeedback_0_bits_isForVSnonLeafPTE,
  input             io_vecFeedback_0_bits_feedback_0,
  input             io_vecFeedback_0_bits_feedback_1,
  input             io_vecFeedback_0_bits_exceptionVec_3,
  input             io_vecFeedback_0_bits_exceptionVec_6,
  input             io_vecFeedback_0_bits_exceptionVec_7,
  input             io_vecFeedback_0_bits_exceptionVec_15,
  input             io_vecFeedback_0_bits_exceptionVec_19,
  input             io_vecFeedback_0_bits_exceptionVec_23,
  input             io_vecFeedback_1_valid,
  input             io_vecFeedback_1_bits_robidx_flag,
  input  [7:0]      io_vecFeedback_1_bits_robidx_value,
  input  [6:0]      io_vecFeedback_1_bits_uopidx,
  input  [63:0]     io_vecFeedback_1_bits_vaddr,
  input             io_vecFeedback_1_bits_vaNeedExt,
  input  [63:0]     io_vecFeedback_1_bits_gpaddr,
  input             io_vecFeedback_1_bits_isForVSnonLeafPTE,
  input             io_vecFeedback_1_bits_feedback_0,
  input             io_vecFeedback_1_bits_feedback_1,
  input             io_vecFeedback_1_bits_exceptionVec_3,
  input             io_vecFeedback_1_bits_exceptionVec_6,
  input             io_vecFeedback_1_bits_exceptionVec_7,
  input             io_vecFeedback_1_bits_exceptionVec_15,
  input             io_vecFeedback_1_bits_exceptionVec_19,
  input             io_vecFeedback_1_bits_exceptionVec_23,
  input             io_storeAddrIn_0_valid,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_0,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_1,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_2,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_3,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_4,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_5,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_6,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_7,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_8,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_9,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_10,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_11,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_12,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_13,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_14,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_15,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_16,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_17,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_18,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_19,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_20,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_21,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_22,
  input             io_storeAddrIn_0_bits_uop_exceptionVec_23,
  input  [3:0]      io_storeAddrIn_0_bits_uop_trigger,
  input  [34:0]     io_storeAddrIn_0_bits_uop_fuType,
  input  [8:0]      io_storeAddrIn_0_bits_uop_fuOpType,
  input             io_storeAddrIn_0_bits_uop_rfWen,
  input  [2:0]      io_storeAddrIn_0_bits_uop_vpu_nf,
  input  [1:0]      io_storeAddrIn_0_bits_uop_vpu_veew,
  input  [6:0]      io_storeAddrIn_0_bits_uop_uopIdx,
  input  [7:0]      io_storeAddrIn_0_bits_uop_pdest,
  input             io_storeAddrIn_0_bits_uop_robIdx_flag,
  input  [7:0]      io_storeAddrIn_0_bits_uop_robIdx_value,
  input             io_storeAddrIn_0_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]     io_storeAddrIn_0_bits_uop_debugInfo_renameTime,
  input  [63:0]     io_storeAddrIn_0_bits_uop_debugInfo_dispatchTime,
  input  [63:0]     io_storeAddrIn_0_bits_uop_debugInfo_enqRsTime,
  input  [63:0]     io_storeAddrIn_0_bits_uop_debugInfo_selectTime,
  input  [63:0]     io_storeAddrIn_0_bits_uop_debugInfo_issueTime,
  input  [63:0]     io_storeAddrIn_0_bits_uop_debugInfo_writebackTime,
  input  [63:0]     io_storeAddrIn_0_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]     io_storeAddrIn_0_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]     io_storeAddrIn_0_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]     io_storeAddrIn_0_bits_uop_debug_seqNum_seqNum,
  input  [7:0]      io_storeAddrIn_0_bits_uop_debug_seqNum_uopIdx,
  input  [5:0]      io_storeAddrIn_0_bits_uop_sqIdx_value,
  input  [49:0]     io_storeAddrIn_0_bits_vaddr,
  input  [63:0]     io_storeAddrIn_0_bits_fullva,
  input             io_storeAddrIn_0_bits_vaNeedExt,
  input  [47:0]     io_storeAddrIn_0_bits_paddr,
  input  [63:0]     io_storeAddrIn_0_bits_gpaddr,
  input  [15:0]     io_storeAddrIn_0_bits_mask,
  input             io_storeAddrIn_0_bits_wlineflag,
  input             io_storeAddrIn_0_bits_miss,
  input             io_storeAddrIn_0_bits_nc,
  input             io_storeAddrIn_0_bits_isHyper,
  input             io_storeAddrIn_0_bits_isForVSnonLeafPTE,
  input             io_storeAddrIn_0_bits_isvec,
  input             io_storeAddrIn_0_bits_isFrmMisAlignBuf,
  input             io_storeAddrIn_0_bits_isMisalign,
  input             io_storeAddrIn_0_bits_misalignWith16Byte,
  input             io_storeAddrIn_0_bits_updateAddrValid,
  input             io_storeAddrIn_1_valid,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_0,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_1,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_2,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_3,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_4,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_5,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_6,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_7,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_8,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_9,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_10,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_11,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_12,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_13,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_14,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_15,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_16,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_17,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_18,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_19,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_20,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_21,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_22,
  input             io_storeAddrIn_1_bits_uop_exceptionVec_23,
  input  [3:0]      io_storeAddrIn_1_bits_uop_trigger,
  input  [34:0]     io_storeAddrIn_1_bits_uop_fuType,
  input  [8:0]      io_storeAddrIn_1_bits_uop_fuOpType,
  input             io_storeAddrIn_1_bits_uop_rfWen,
  input  [2:0]      io_storeAddrIn_1_bits_uop_vpu_nf,
  input  [1:0]      io_storeAddrIn_1_bits_uop_vpu_veew,
  input  [6:0]      io_storeAddrIn_1_bits_uop_uopIdx,
  input  [7:0]      io_storeAddrIn_1_bits_uop_pdest,
  input             io_storeAddrIn_1_bits_uop_robIdx_flag,
  input  [7:0]      io_storeAddrIn_1_bits_uop_robIdx_value,
  input             io_storeAddrIn_1_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]     io_storeAddrIn_1_bits_uop_debugInfo_renameTime,
  input  [63:0]     io_storeAddrIn_1_bits_uop_debugInfo_dispatchTime,
  input  [63:0]     io_storeAddrIn_1_bits_uop_debugInfo_enqRsTime,
  input  [63:0]     io_storeAddrIn_1_bits_uop_debugInfo_selectTime,
  input  [63:0]     io_storeAddrIn_1_bits_uop_debugInfo_issueTime,
  input  [63:0]     io_storeAddrIn_1_bits_uop_debugInfo_writebackTime,
  input  [63:0]     io_storeAddrIn_1_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]     io_storeAddrIn_1_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]     io_storeAddrIn_1_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]     io_storeAddrIn_1_bits_uop_debug_seqNum_seqNum,
  input  [7:0]      io_storeAddrIn_1_bits_uop_debug_seqNum_uopIdx,
  input  [5:0]      io_storeAddrIn_1_bits_uop_sqIdx_value,
  input  [49:0]     io_storeAddrIn_1_bits_vaddr,
  input  [63:0]     io_storeAddrIn_1_bits_fullva,
  input             io_storeAddrIn_1_bits_vaNeedExt,
  input  [47:0]     io_storeAddrIn_1_bits_paddr,
  input  [63:0]     io_storeAddrIn_1_bits_gpaddr,
  input  [15:0]     io_storeAddrIn_1_bits_mask,
  input             io_storeAddrIn_1_bits_wlineflag,
  input             io_storeAddrIn_1_bits_miss,
  input             io_storeAddrIn_1_bits_nc,
  input             io_storeAddrIn_1_bits_isHyper,
  input             io_storeAddrIn_1_bits_isForVSnonLeafPTE,
  input             io_storeAddrIn_1_bits_isvec,
  input             io_storeAddrIn_1_bits_isFrmMisAlignBuf,
  input             io_storeAddrIn_1_bits_isMisalign,
  input             io_storeAddrIn_1_bits_misalignWith16Byte,
  input             io_storeAddrIn_1_bits_updateAddrValid,
  input             io_storeAddrInRe_0_uop_exceptionVec_3,
  input             io_storeAddrInRe_0_uop_exceptionVec_6,
  input             io_storeAddrInRe_0_uop_exceptionVec_15,
  input             io_storeAddrInRe_0_uop_exceptionVec_19,
  input             io_storeAddrInRe_0_uop_exceptionVec_23,
  input  [6:0]      io_storeAddrInRe_0_uop_uopIdx,
  input             io_storeAddrInRe_0_uop_robIdx_flag,
  input  [7:0]      io_storeAddrInRe_0_uop_robIdx_value,
  input  [63:0]     io_storeAddrInRe_0_fullva,
  input             io_storeAddrInRe_0_vaNeedExt,
  input  [63:0]     io_storeAddrInRe_0_gpaddr,
  input             io_storeAddrInRe_0_af,
  input             io_storeAddrInRe_0_mmio,
  input             io_storeAddrInRe_0_memBackTypeMM,
  input             io_storeAddrInRe_0_hasException,
  input             io_storeAddrInRe_0_isHyper,
  input             io_storeAddrInRe_0_isForVSnonLeafPTE,
  input             io_storeAddrInRe_0_isvec,
  input             io_storeAddrInRe_0_updateAddrValid,
  input             io_storeAddrInRe_1_uop_exceptionVec_3,
  input             io_storeAddrInRe_1_uop_exceptionVec_6,
  input             io_storeAddrInRe_1_uop_exceptionVec_15,
  input             io_storeAddrInRe_1_uop_exceptionVec_19,
  input             io_storeAddrInRe_1_uop_exceptionVec_23,
  input  [6:0]      io_storeAddrInRe_1_uop_uopIdx,
  input             io_storeAddrInRe_1_uop_robIdx_flag,
  input  [7:0]      io_storeAddrInRe_1_uop_robIdx_value,
  input  [63:0]     io_storeAddrInRe_1_fullva,
  input             io_storeAddrInRe_1_vaNeedExt,
  input  [63:0]     io_storeAddrInRe_1_gpaddr,
  input             io_storeAddrInRe_1_af,
  input             io_storeAddrInRe_1_mmio,
  input             io_storeAddrInRe_1_memBackTypeMM,
  input             io_storeAddrInRe_1_hasException,
  input             io_storeAddrInRe_1_isHyper,
  input             io_storeAddrInRe_1_isForVSnonLeafPTE,
  input             io_storeAddrInRe_1_isvec,
  input             io_storeAddrInRe_1_updateAddrValid,
  input             io_storeDataIn_0_valid,
  input  [34:0]     io_storeDataIn_0_bits_uop_fuType,
  input  [8:0]      io_storeDataIn_0_bits_uop_fuOpType,
  input  [5:0]      io_storeDataIn_0_bits_uop_sqIdx_value,
  input  [127:0]    io_storeDataIn_0_bits_data,
  input  [5:0]      io_storeDataIn_0_bits_vecDebug_offset,
  input             io_storeDataIn_1_valid,
  input  [34:0]     io_storeDataIn_1_bits_uop_fuType,
  input  [8:0]      io_storeDataIn_1_bits_uop_fuOpType,
  input  [5:0]      io_storeDataIn_1_bits_uop_sqIdx_value,
  input  [127:0]    io_storeDataIn_1_bits_data,
  input  [5:0]      io_storeDataIn_1_bits_vecDebug_offset,
  input             io_storeMaskIn_0_valid,
  input  [5:0]      io_storeMaskIn_0_bits_sqIdx_value,
  input  [15:0]     io_storeMaskIn_0_bits_mask,
  input             io_storeMaskIn_1_valid,
  input  [5:0]      io_storeMaskIn_1_bits_sqIdx_value,
  input  [15:0]     io_storeMaskIn_1_bits_mask,
  input             io_sbuffer_0_ready,
  output            io_sbuffer_0_valid,
  output [49:0]     io_sbuffer_0_bits_vaddr,
  output [127:0]    io_sbuffer_0_bits_data,
  output [15:0]     io_sbuffer_0_bits_mask,
  output [47:0]     io_sbuffer_0_bits_addr,
  output            io_sbuffer_0_bits_wline,
  output            io_sbuffer_0_bits_vecValid,
  input             io_sbuffer_1_ready,
  output            io_sbuffer_1_valid,
  output [49:0]     io_sbuffer_1_bits_vaddr,
  output [127:0]    io_sbuffer_1_bits_data,
  output [15:0]     io_sbuffer_1_bits_mask,
  output [47:0]     io_sbuffer_1_bits_addr,
  output            io_sbuffer_1_bits_wline,
  output            io_sbuffer_1_bits_vecValid,
  input             io_uncacheOutstanding,
  input             io_cmoOpReq_ready,
  output            io_cmoOpReq_valid,
  output [2:0]      io_cmoOpReq_bits_opcode,
  output [63:0]     io_cmoOpReq_bits_address,
  output            io_cmoOpResp_ready,
  input             io_cmoOpResp_valid,
  input             io_cmoOpResp_bits_denied,
  input             io_cmoOpResp_bits_corrupt,
  input             io_cboZeroStout_ready,
  output            io_cboZeroStout_valid,
  output            io_cboZeroStout_bits_uop_exceptionVec_0,
  output            io_cboZeroStout_bits_uop_exceptionVec_1,
  output            io_cboZeroStout_bits_uop_exceptionVec_2,
  output            io_cboZeroStout_bits_uop_exceptionVec_3,
  output            io_cboZeroStout_bits_uop_exceptionVec_4,
  output            io_cboZeroStout_bits_uop_exceptionVec_5,
  output            io_cboZeroStout_bits_uop_exceptionVec_6,
  output            io_cboZeroStout_bits_uop_exceptionVec_7,
  output            io_cboZeroStout_bits_uop_exceptionVec_8,
  output            io_cboZeroStout_bits_uop_exceptionVec_9,
  output            io_cboZeroStout_bits_uop_exceptionVec_10,
  output            io_cboZeroStout_bits_uop_exceptionVec_11,
  output            io_cboZeroStout_bits_uop_exceptionVec_12,
  output            io_cboZeroStout_bits_uop_exceptionVec_13,
  output            io_cboZeroStout_bits_uop_exceptionVec_14,
  output            io_cboZeroStout_bits_uop_exceptionVec_15,
  output            io_cboZeroStout_bits_uop_exceptionVec_16,
  output            io_cboZeroStout_bits_uop_exceptionVec_17,
  output            io_cboZeroStout_bits_uop_exceptionVec_18,
  output            io_cboZeroStout_bits_uop_exceptionVec_19,
  output            io_cboZeroStout_bits_uop_exceptionVec_20,
  output            io_cboZeroStout_bits_uop_exceptionVec_21,
  output            io_cboZeroStout_bits_uop_exceptionVec_22,
  output            io_cboZeroStout_bits_uop_exceptionVec_23,
  output [3:0]      io_cboZeroStout_bits_uop_trigger,
  output            io_cboZeroStout_bits_uop_rfWen,
  output            io_cboZeroStout_bits_uop_flushPipe,
  output [7:0]      io_cboZeroStout_bits_uop_pdest,
  output            io_cboZeroStout_bits_uop_robIdx_flag,
  output [7:0]      io_cboZeroStout_bits_uop_robIdx_value,
  output            io_cboZeroStout_bits_uop_debugInfo_eliminatedMove,
  output [63:0]     io_cboZeroStout_bits_uop_debugInfo_renameTime,
  output [63:0]     io_cboZeroStout_bits_uop_debugInfo_dispatchTime,
  output [63:0]     io_cboZeroStout_bits_uop_debugInfo_enqRsTime,
  output [63:0]     io_cboZeroStout_bits_uop_debugInfo_selectTime,
  output [63:0]     io_cboZeroStout_bits_uop_debugInfo_issueTime,
  output [63:0]     io_cboZeroStout_bits_uop_debugInfo_writebackTime,
  output [63:0]     io_cboZeroStout_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]     io_cboZeroStout_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]     io_cboZeroStout_bits_uop_debugInfo_tlbRespTime,
  output [55:0]     io_cboZeroStout_bits_uop_debug_seqNum_seqNum,
  output [7:0]      io_cboZeroStout_bits_uop_debug_seqNum_uopIdx,
  output            io_cboZeroStout_bits_uop_sqIdx_flag,
  output [5:0]      io_cboZeroStout_bits_uop_sqIdx_value,
  input             io_mmioStout_ready,
  output            io_mmioStout_valid,
  output            io_mmioStout_bits_uop_exceptionVec_7,
  output            io_mmioStout_bits_uop_exceptionVec_19,
  output            io_mmioStout_bits_uop_rfWen,
  output            io_mmioStout_bits_uop_flushPipe,
  output [7:0]      io_mmioStout_bits_uop_pdest,
  output            io_mmioStout_bits_uop_robIdx_flag,
  output [7:0]      io_mmioStout_bits_uop_robIdx_value,
  output            io_mmioStout_bits_uop_debugInfo_eliminatedMove,
  output [63:0]     io_mmioStout_bits_uop_debugInfo_renameTime,
  output [63:0]     io_mmioStout_bits_uop_debugInfo_dispatchTime,
  output [63:0]     io_mmioStout_bits_uop_debugInfo_enqRsTime,
  output [63:0]     io_mmioStout_bits_uop_debugInfo_selectTime,
  output [63:0]     io_mmioStout_bits_uop_debugInfo_issueTime,
  output [63:0]     io_mmioStout_bits_uop_debugInfo_writebackTime,
  output [63:0]     io_mmioStout_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]     io_mmioStout_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]     io_mmioStout_bits_uop_debugInfo_tlbRespTime,
  output [55:0]     io_mmioStout_bits_uop_debug_seqNum_seqNum,
  output [7:0]      io_mmioStout_bits_uop_debug_seqNum_uopIdx,
  output            io_mmioStout_bits_uop_sqIdx_flag,
  output [5:0]      io_mmioStout_bits_uop_sqIdx_value,
  output [63:0]     io_mmioStout_bits_data,
  output            io_mmioStout_bits_debug_isMMIO,
  input  [49:0]     io_forward_0_vaddr,
  input  [47:0]     io_forward_0_paddr,
  input  [15:0]     io_forward_0_mask,
  input             io_forward_0_uop_waitForRobIdx_flag,
  input  [7:0]      io_forward_0_uop_waitForRobIdx_value,
  input             io_forward_0_uop_loadWaitBit,
  input             io_forward_0_uop_loadWaitStrict,
  input             io_forward_0_uop_sqIdx_flag,
  input  [5:0]      io_forward_0_uop_sqIdx_value,
  input             io_forward_0_valid,
  output            io_forward_0_forwardMask_0,
  output            io_forward_0_forwardMask_1,
  output            io_forward_0_forwardMask_2,
  output            io_forward_0_forwardMask_3,
  output            io_forward_0_forwardMask_4,
  output            io_forward_0_forwardMask_5,
  output            io_forward_0_forwardMask_6,
  output            io_forward_0_forwardMask_7,
  output            io_forward_0_forwardMask_8,
  output            io_forward_0_forwardMask_9,
  output            io_forward_0_forwardMask_10,
  output            io_forward_0_forwardMask_11,
  output            io_forward_0_forwardMask_12,
  output            io_forward_0_forwardMask_13,
  output            io_forward_0_forwardMask_14,
  output            io_forward_0_forwardMask_15,
  output [7:0]      io_forward_0_forwardData_0,
  output [7:0]      io_forward_0_forwardData_1,
  output [7:0]      io_forward_0_forwardData_2,
  output [7:0]      io_forward_0_forwardData_3,
  output [7:0]      io_forward_0_forwardData_4,
  output [7:0]      io_forward_0_forwardData_5,
  output [7:0]      io_forward_0_forwardData_6,
  output [7:0]      io_forward_0_forwardData_7,
  output [7:0]      io_forward_0_forwardData_8,
  output [7:0]      io_forward_0_forwardData_9,
  output [7:0]      io_forward_0_forwardData_10,
  output [7:0]      io_forward_0_forwardData_11,
  output [7:0]      io_forward_0_forwardData_12,
  output [7:0]      io_forward_0_forwardData_13,
  output [7:0]      io_forward_0_forwardData_14,
  output [7:0]      io_forward_0_forwardData_15,
  input             io_forward_0_sqIdx_flag,
  output            io_forward_0_dataInvalid,
  output            io_forward_0_matchInvalid,
  output            io_forward_0_addrInvalid,
  input  [55:0]     io_forward_0_sqIdxMask,
  output            io_forward_0_dataInvalidSqIdx_flag,
  output [5:0]      io_forward_0_dataInvalidSqIdx_value,
  output            io_forward_0_addrInvalidSqIdx_flag,
  output [5:0]      io_forward_0_addrInvalidSqIdx_value,
  input  [49:0]     io_forward_1_vaddr,
  input  [47:0]     io_forward_1_paddr,
  input  [15:0]     io_forward_1_mask,
  input             io_forward_1_uop_waitForRobIdx_flag,
  input  [7:0]      io_forward_1_uop_waitForRobIdx_value,
  input             io_forward_1_uop_loadWaitBit,
  input             io_forward_1_uop_loadWaitStrict,
  input             io_forward_1_uop_sqIdx_flag,
  input  [5:0]      io_forward_1_uop_sqIdx_value,
  input             io_forward_1_valid,
  output            io_forward_1_forwardMask_0,
  output            io_forward_1_forwardMask_1,
  output            io_forward_1_forwardMask_2,
  output            io_forward_1_forwardMask_3,
  output            io_forward_1_forwardMask_4,
  output            io_forward_1_forwardMask_5,
  output            io_forward_1_forwardMask_6,
  output            io_forward_1_forwardMask_7,
  output            io_forward_1_forwardMask_8,
  output            io_forward_1_forwardMask_9,
  output            io_forward_1_forwardMask_10,
  output            io_forward_1_forwardMask_11,
  output            io_forward_1_forwardMask_12,
  output            io_forward_1_forwardMask_13,
  output            io_forward_1_forwardMask_14,
  output            io_forward_1_forwardMask_15,
  output [7:0]      io_forward_1_forwardData_0,
  output [7:0]      io_forward_1_forwardData_1,
  output [7:0]      io_forward_1_forwardData_2,
  output [7:0]      io_forward_1_forwardData_3,
  output [7:0]      io_forward_1_forwardData_4,
  output [7:0]      io_forward_1_forwardData_5,
  output [7:0]      io_forward_1_forwardData_6,
  output [7:0]      io_forward_1_forwardData_7,
  output [7:0]      io_forward_1_forwardData_8,
  output [7:0]      io_forward_1_forwardData_9,
  output [7:0]      io_forward_1_forwardData_10,
  output [7:0]      io_forward_1_forwardData_11,
  output [7:0]      io_forward_1_forwardData_12,
  output [7:0]      io_forward_1_forwardData_13,
  output [7:0]      io_forward_1_forwardData_14,
  output [7:0]      io_forward_1_forwardData_15,
  input             io_forward_1_sqIdx_flag,
  output            io_forward_1_dataInvalid,
  output            io_forward_1_matchInvalid,
  output            io_forward_1_addrInvalid,
  input  [55:0]     io_forward_1_sqIdxMask,
  output            io_forward_1_dataInvalidSqIdx_flag,
  output [5:0]      io_forward_1_dataInvalidSqIdx_value,
  output            io_forward_1_addrInvalidSqIdx_flag,
  output [5:0]      io_forward_1_addrInvalidSqIdx_value,
  input  [49:0]     io_forward_2_vaddr,
  input  [47:0]     io_forward_2_paddr,
  input  [15:0]     io_forward_2_mask,
  input             io_forward_2_uop_waitForRobIdx_flag,
  input  [7:0]      io_forward_2_uop_waitForRobIdx_value,
  input             io_forward_2_uop_loadWaitBit,
  input             io_forward_2_uop_loadWaitStrict,
  input             io_forward_2_uop_sqIdx_flag,
  input  [5:0]      io_forward_2_uop_sqIdx_value,
  input             io_forward_2_valid,
  output            io_forward_2_forwardMask_0,
  output            io_forward_2_forwardMask_1,
  output            io_forward_2_forwardMask_2,
  output            io_forward_2_forwardMask_3,
  output            io_forward_2_forwardMask_4,
  output            io_forward_2_forwardMask_5,
  output            io_forward_2_forwardMask_6,
  output            io_forward_2_forwardMask_7,
  output            io_forward_2_forwardMask_8,
  output            io_forward_2_forwardMask_9,
  output            io_forward_2_forwardMask_10,
  output            io_forward_2_forwardMask_11,
  output            io_forward_2_forwardMask_12,
  output            io_forward_2_forwardMask_13,
  output            io_forward_2_forwardMask_14,
  output            io_forward_2_forwardMask_15,
  output [7:0]      io_forward_2_forwardData_0,
  output [7:0]      io_forward_2_forwardData_1,
  output [7:0]      io_forward_2_forwardData_2,
  output [7:0]      io_forward_2_forwardData_3,
  output [7:0]      io_forward_2_forwardData_4,
  output [7:0]      io_forward_2_forwardData_5,
  output [7:0]      io_forward_2_forwardData_6,
  output [7:0]      io_forward_2_forwardData_7,
  output [7:0]      io_forward_2_forwardData_8,
  output [7:0]      io_forward_2_forwardData_9,
  output [7:0]      io_forward_2_forwardData_10,
  output [7:0]      io_forward_2_forwardData_11,
  output [7:0]      io_forward_2_forwardData_12,
  output [7:0]      io_forward_2_forwardData_13,
  output [7:0]      io_forward_2_forwardData_14,
  output [7:0]      io_forward_2_forwardData_15,
  input             io_forward_2_sqIdx_flag,
  output            io_forward_2_dataInvalid,
  output            io_forward_2_matchInvalid,
  output            io_forward_2_addrInvalid,
  input  [55:0]     io_forward_2_sqIdxMask,
  output            io_forward_2_dataInvalidSqIdx_flag,
  output [5:0]      io_forward_2_dataInvalidSqIdx_value,
  output            io_forward_2_addrInvalidSqIdx_flag,
  output [5:0]      io_forward_2_addrInvalidSqIdx_value,
  input  [3:0]      io_rob_scommit,
  input             io_rob_pendingst,
  input             io_rob_pendingPtr_flag,
  input  [7:0]      io_rob_pendingPtr_value,
  output            io_rob_storeMmio,
  output [7:0]      io_rob_storeMmioUop_robIdx_value,
  input             io_uncache_req_ready,
  output            io_uncache_req_valid,
  output            io_uncache_req_bits_robIdx_flag,
  output [7:0]      io_uncache_req_bits_robIdx_value,
  output [47:0]     io_uncache_req_bits_addr,
  output [49:0]     io_uncache_req_bits_vaddr,
  output [63:0]     io_uncache_req_bits_data,
  output [7:0]      io_uncache_req_bits_mask,
  output [6:0]      io_uncache_req_bits_id,
  output            io_uncache_req_bits_nc,
  output            io_uncache_req_bits_memBackTypeMM,
  input             io_uncache_idResp_valid,
  input  [6:0]      io_uncache_idResp_bits_mid,
  input             io_uncache_idResp_bits_nc,
  input             io_uncache_resp_valid,
  input             io_uncache_resp_bits_nc,
  input             io_uncache_resp_bits_denied,
  input             io_uncache_resp_bits_corrupt,
  output [63:0]     io_exceptionAddr_vaddr,
  output            io_exceptionAddr_vaNeedExt,
  output            io_exceptionAddr_isHyper,
  output [63:0]     io_exceptionAddr_gpaddr,
  output            io_exceptionAddr_isForVSnonLeafPTE,
  output            io_flushSbuffer_valid,
  input             io_flushSbuffer_empty,
  output            io_sqEmpty,
  output            io_stAddrReadySqPtr_flag,
  output [5:0]      io_stAddrReadySqPtr_value,
  output            io_stAddrReadyVec_0,
  output            io_stAddrReadyVec_1,
  output            io_stAddrReadyVec_2,
  output            io_stAddrReadyVec_3,
  output            io_stAddrReadyVec_4,
  output            io_stAddrReadyVec_5,
  output            io_stAddrReadyVec_6,
  output            io_stAddrReadyVec_7,
  output            io_stAddrReadyVec_8,
  output            io_stAddrReadyVec_9,
  output            io_stAddrReadyVec_10,
  output            io_stAddrReadyVec_11,
  output            io_stAddrReadyVec_12,
  output            io_stAddrReadyVec_13,
  output            io_stAddrReadyVec_14,
  output            io_stAddrReadyVec_15,
  output            io_stAddrReadyVec_16,
  output            io_stAddrReadyVec_17,
  output            io_stAddrReadyVec_18,
  output            io_stAddrReadyVec_19,
  output            io_stAddrReadyVec_20,
  output            io_stAddrReadyVec_21,
  output            io_stAddrReadyVec_22,
  output            io_stAddrReadyVec_23,
  output            io_stAddrReadyVec_24,
  output            io_stAddrReadyVec_25,
  output            io_stAddrReadyVec_26,
  output            io_stAddrReadyVec_27,
  output            io_stAddrReadyVec_28,
  output            io_stAddrReadyVec_29,
  output            io_stAddrReadyVec_30,
  output            io_stAddrReadyVec_31,
  output            io_stAddrReadyVec_32,
  output            io_stAddrReadyVec_33,
  output            io_stAddrReadyVec_34,
  output            io_stAddrReadyVec_35,
  output            io_stAddrReadyVec_36,
  output            io_stAddrReadyVec_37,
  output            io_stAddrReadyVec_38,
  output            io_stAddrReadyVec_39,
  output            io_stAddrReadyVec_40,
  output            io_stAddrReadyVec_41,
  output            io_stAddrReadyVec_42,
  output            io_stAddrReadyVec_43,
  output            io_stAddrReadyVec_44,
  output            io_stAddrReadyVec_45,
  output            io_stAddrReadyVec_46,
  output            io_stAddrReadyVec_47,
  output            io_stAddrReadyVec_48,
  output            io_stAddrReadyVec_49,
  output            io_stAddrReadyVec_50,
  output            io_stAddrReadyVec_51,
  output            io_stAddrReadyVec_52,
  output            io_stAddrReadyVec_53,
  output            io_stAddrReadyVec_54,
  output            io_stAddrReadyVec_55,
  output            io_stDataReadySqPtr_flag,
  output [5:0]      io_stDataReadySqPtr_value,
  output            io_stDataReadyVec_0,
  output            io_stDataReadyVec_1,
  output            io_stDataReadyVec_2,
  output            io_stDataReadyVec_3,
  output            io_stDataReadyVec_4,
  output            io_stDataReadyVec_5,
  output            io_stDataReadyVec_6,
  output            io_stDataReadyVec_7,
  output            io_stDataReadyVec_8,
  output            io_stDataReadyVec_9,
  output            io_stDataReadyVec_10,
  output            io_stDataReadyVec_11,
  output            io_stDataReadyVec_12,
  output            io_stDataReadyVec_13,
  output            io_stDataReadyVec_14,
  output            io_stDataReadyVec_15,
  output            io_stDataReadyVec_16,
  output            io_stDataReadyVec_17,
  output            io_stDataReadyVec_18,
  output            io_stDataReadyVec_19,
  output            io_stDataReadyVec_20,
  output            io_stDataReadyVec_21,
  output            io_stDataReadyVec_22,
  output            io_stDataReadyVec_23,
  output            io_stDataReadyVec_24,
  output            io_stDataReadyVec_25,
  output            io_stDataReadyVec_26,
  output            io_stDataReadyVec_27,
  output            io_stDataReadyVec_28,
  output            io_stDataReadyVec_29,
  output            io_stDataReadyVec_30,
  output            io_stDataReadyVec_31,
  output            io_stDataReadyVec_32,
  output            io_stDataReadyVec_33,
  output            io_stDataReadyVec_34,
  output            io_stDataReadyVec_35,
  output            io_stDataReadyVec_36,
  output            io_stDataReadyVec_37,
  output            io_stDataReadyVec_38,
  output            io_stDataReadyVec_39,
  output            io_stDataReadyVec_40,
  output            io_stDataReadyVec_41,
  output            io_stDataReadyVec_42,
  output            io_stDataReadyVec_43,
  output            io_stDataReadyVec_44,
  output            io_stDataReadyVec_45,
  output            io_stDataReadyVec_46,
  output            io_stDataReadyVec_47,
  output            io_stDataReadyVec_48,
  output            io_stDataReadyVec_49,
  output            io_stDataReadyVec_50,
  output            io_stDataReadyVec_51,
  output            io_stDataReadyVec_52,
  output            io_stDataReadyVec_53,
  output            io_stDataReadyVec_54,
  output            io_stDataReadyVec_55,
  output            io_stIssuePtr_flag,
  output [5:0]      io_stIssuePtr_value,
  output            io_sqDeqPtr_flag,
  output [5:0]      io_sqDeqPtr_value,
  output            io_sqCommitPtr_flag,
  output [5:0]      io_sqCommitPtr_value,
  output [6:0]      io_sqCommitUopIdx,
  output            io_sqCommitRobIdx_flag,
  output [7:0]      io_sqCommitRobIdx_value,
  output            io_sqFull,
  output [5:0]      io_sqCancelCnt,
  output [1:0]      io_sqDeq,
  output            io_sqDeqIsVec,
  output            io_force_write,
  input             io_maControl_toStoreQueue_crossPageWithHit,
  input             io_maControl_toStoreQueue_crossPageCanDeq,
  input  [47:0]     io_maControl_toStoreQueue_paddr,
  input             io_maControl_toStoreQueue_withSamePtr,
  output            io_maControl_toStoreMisalignBuffer_sqPtr_flag,
  output [5:0]      io_maControl_toStoreMisalignBuffer_sqPtr_value,
  output            io_maControl_toStoreMisalignBuffer_doDeq,
  output [6:0]      io_maControl_toStoreMisalignBuffer_uop_uopIdx,
  output            io_maControl_toStoreMisalignBuffer_uop_robIdx_flag,
  output [7:0]      io_maControl_toStoreMisalignBuffer_uop_robIdx_value,
  input             io_wfi_wfiReq,
  output            io_wfi_wfiSafe,
  output [34:0]     io_diffStore_diffInfo_0_uop_fuType,
  output [8:0]      io_diffStore_diffInfo_0_uop_fuOpType,
  output [2:0]      io_diffStore_diffInfo_0_uop_vpu_nf,
  output [1:0]      io_diffStore_diffInfo_0_uop_vpu_veew,
  output [7:0]      io_diffStore_diffInfo_0_uop_robIdx_value,
  output [5:0]      io_diffStore_diffInfo_0_offset,
  output [34:0]     io_diffStore_diffInfo_1_uop_fuType,
  output [8:0]      io_diffStore_diffInfo_1_uop_fuOpType,
  output [2:0]      io_diffStore_diffInfo_1_uop_vpu_nf,
  output [1:0]      io_diffStore_diffInfo_1_uop_vpu_veew,
  output [7:0]      io_diffStore_diffInfo_1_uop_robIdx_value,
  output [5:0]      io_diffStore_diffInfo_1_offset,
  output            io_diffStore_pmaStore_0_valid,
  output [127:0]    io_diffStore_pmaStore_0_bits_data,
  output [15:0]     io_diffStore_pmaStore_0_bits_mask,
  output [47:0]     io_diffStore_pmaStore_0_bits_addr,
  output            io_diffStore_pmaStore_0_bits_wline,
  output            io_diffStore_pmaStore_0_bits_vecValid,
  output            io_diffStore_pmaStore_1_valid,
  output [127:0]    io_diffStore_pmaStore_1_bits_data,
  output [15:0]     io_diffStore_pmaStore_1_bits_mask,
  output [47:0]     io_diffStore_pmaStore_1_bits_addr,
  output            io_diffStore_pmaStore_1_bits_wline,
  output            io_diffStore_pmaStore_1_bits_vecValid,
  output            io_diffStore_ncStore_valid,
  output [47:0]     io_diffStore_ncStore_bits_addr,
  output [63:0]     io_diffStore_ncStore_bits_data,
  output [7:0]      io_diffStore_ncStore_bits_mask,
  output            io_diffStore_ncStore_bits_memBackTypeMM,
  output [5:0]      io_perf_0_value,
  output [5:0]      io_perf_1_value,
  output [5:0]      io_perf_2_value,
  output [5:0]      io_perf_3_value,
  output [5:0]      io_perf_4_value,
  output [5:0]      io_perf_5_value,
  output [5:0]      io_perf_6_value,
  output [5:0]      io_perf_7_value,
  output [72:0]     gatewayIn_packed_48_bore
);

  import storequeue_pkg::*;

  // 扁平 golden 端口 <-> 可读核结构体数组的接线。
  // ★本段全部由 gen_storequeue.py 机械生成★：字段顺序直接取自
  //   emit_pkg_structs 用的同一张 chans 表，所以 packed struct 的位序
  //   与这里的赋值**按构造**一致，不存在手写错位的可能。

  sq_enq_req_t_in enq_req_in [6];
  assign enq_req_in[0].valid = io_enq_req_0_valid;
  assign enq_req_in[0].bits_exceptionVec_0 = io_enq_req_0_bits_exceptionVec_0;
  assign enq_req_in[0].bits_exceptionVec_1 = io_enq_req_0_bits_exceptionVec_1;
  assign enq_req_in[0].bits_exceptionVec_2 = io_enq_req_0_bits_exceptionVec_2;
  assign enq_req_in[0].bits_exceptionVec_3 = io_enq_req_0_bits_exceptionVec_3;
  assign enq_req_in[0].bits_exceptionVec_4 = io_enq_req_0_bits_exceptionVec_4;
  assign enq_req_in[0].bits_exceptionVec_5 = io_enq_req_0_bits_exceptionVec_5;
  assign enq_req_in[0].bits_exceptionVec_6 = io_enq_req_0_bits_exceptionVec_6;
  assign enq_req_in[0].bits_exceptionVec_7 = io_enq_req_0_bits_exceptionVec_7;
  assign enq_req_in[0].bits_exceptionVec_8 = io_enq_req_0_bits_exceptionVec_8;
  assign enq_req_in[0].bits_exceptionVec_9 = io_enq_req_0_bits_exceptionVec_9;
  assign enq_req_in[0].bits_exceptionVec_10 = io_enq_req_0_bits_exceptionVec_10;
  assign enq_req_in[0].bits_exceptionVec_11 = io_enq_req_0_bits_exceptionVec_11;
  assign enq_req_in[0].bits_exceptionVec_12 = io_enq_req_0_bits_exceptionVec_12;
  assign enq_req_in[0].bits_exceptionVec_13 = io_enq_req_0_bits_exceptionVec_13;
  assign enq_req_in[0].bits_exceptionVec_14 = io_enq_req_0_bits_exceptionVec_14;
  assign enq_req_in[0].bits_exceptionVec_15 = io_enq_req_0_bits_exceptionVec_15;
  assign enq_req_in[0].bits_exceptionVec_16 = io_enq_req_0_bits_exceptionVec_16;
  assign enq_req_in[0].bits_exceptionVec_17 = io_enq_req_0_bits_exceptionVec_17;
  assign enq_req_in[0].bits_exceptionVec_18 = io_enq_req_0_bits_exceptionVec_18;
  assign enq_req_in[0].bits_exceptionVec_19 = io_enq_req_0_bits_exceptionVec_19;
  assign enq_req_in[0].bits_exceptionVec_20 = io_enq_req_0_bits_exceptionVec_20;
  assign enq_req_in[0].bits_exceptionVec_21 = io_enq_req_0_bits_exceptionVec_21;
  assign enq_req_in[0].bits_exceptionVec_22 = io_enq_req_0_bits_exceptionVec_22;
  assign enq_req_in[0].bits_exceptionVec_23 = io_enq_req_0_bits_exceptionVec_23;
  assign enq_req_in[0].bits_trigger = io_enq_req_0_bits_trigger;
  assign enq_req_in[0].bits_fuType = io_enq_req_0_bits_fuType;
  assign enq_req_in[0].bits_fuOpType = io_enq_req_0_bits_fuOpType;
  assign enq_req_in[0].bits_rfWen = io_enq_req_0_bits_rfWen;
  assign enq_req_in[0].bits_flushPipe = io_enq_req_0_bits_flushPipe;
  assign enq_req_in[0].bits_vpu_nf = io_enq_req_0_bits_vpu_nf;
  assign enq_req_in[0].bits_vpu_veew = io_enq_req_0_bits_vpu_veew;
  assign enq_req_in[0].bits_uopIdx = io_enq_req_0_bits_uopIdx;
  assign enq_req_in[0].bits_lastUop = io_enq_req_0_bits_lastUop;
  assign enq_req_in[0].bits_pdest = io_enq_req_0_bits_pdest;
  assign enq_req_in[0].bits_robIdx_flag = io_enq_req_0_bits_robIdx_flag;
  assign enq_req_in[0].bits_robIdx_value = io_enq_req_0_bits_robIdx_value;
  assign enq_req_in[0].bits_debugInfo_eliminatedMove = io_enq_req_0_bits_debugInfo_eliminatedMove;
  assign enq_req_in[0].bits_debugInfo_renameTime = io_enq_req_0_bits_debugInfo_renameTime;
  assign enq_req_in[0].bits_debugInfo_dispatchTime = io_enq_req_0_bits_debugInfo_dispatchTime;
  assign enq_req_in[0].bits_debugInfo_enqRsTime = io_enq_req_0_bits_debugInfo_enqRsTime;
  assign enq_req_in[0].bits_debugInfo_selectTime = io_enq_req_0_bits_debugInfo_selectTime;
  assign enq_req_in[0].bits_debugInfo_issueTime = io_enq_req_0_bits_debugInfo_issueTime;
  assign enq_req_in[0].bits_debugInfo_writebackTime = io_enq_req_0_bits_debugInfo_writebackTime;
  assign enq_req_in[0].bits_debugInfo_runahead_checkpoint_id = io_enq_req_0_bits_debugInfo_runahead_checkpoint_id;
  assign enq_req_in[0].bits_debugInfo_tlbFirstReqTime = io_enq_req_0_bits_debugInfo_tlbFirstReqTime;
  assign enq_req_in[0].bits_debugInfo_tlbRespTime = io_enq_req_0_bits_debugInfo_tlbRespTime;
  assign enq_req_in[0].bits_debug_seqNum_seqNum = io_enq_req_0_bits_debug_seqNum_seqNum;
  assign enq_req_in[0].bits_debug_seqNum_uopIdx = io_enq_req_0_bits_debug_seqNum_uopIdx;
  assign enq_req_in[0].bits_sqIdx_flag = io_enq_req_0_bits_sqIdx_flag;
  assign enq_req_in[0].bits_sqIdx_value = io_enq_req_0_bits_sqIdx_value;
  assign enq_req_in[0].bits_numLsElem = io_enq_req_0_bits_numLsElem;
  assign enq_req_in[1].valid = io_enq_req_1_valid;
  assign enq_req_in[1].bits_exceptionVec_0 = io_enq_req_1_bits_exceptionVec_0;
  assign enq_req_in[1].bits_exceptionVec_1 = io_enq_req_1_bits_exceptionVec_1;
  assign enq_req_in[1].bits_exceptionVec_2 = io_enq_req_1_bits_exceptionVec_2;
  assign enq_req_in[1].bits_exceptionVec_3 = io_enq_req_1_bits_exceptionVec_3;
  assign enq_req_in[1].bits_exceptionVec_4 = io_enq_req_1_bits_exceptionVec_4;
  assign enq_req_in[1].bits_exceptionVec_5 = io_enq_req_1_bits_exceptionVec_5;
  assign enq_req_in[1].bits_exceptionVec_6 = io_enq_req_1_bits_exceptionVec_6;
  assign enq_req_in[1].bits_exceptionVec_7 = io_enq_req_1_bits_exceptionVec_7;
  assign enq_req_in[1].bits_exceptionVec_8 = io_enq_req_1_bits_exceptionVec_8;
  assign enq_req_in[1].bits_exceptionVec_9 = io_enq_req_1_bits_exceptionVec_9;
  assign enq_req_in[1].bits_exceptionVec_10 = io_enq_req_1_bits_exceptionVec_10;
  assign enq_req_in[1].bits_exceptionVec_11 = io_enq_req_1_bits_exceptionVec_11;
  assign enq_req_in[1].bits_exceptionVec_12 = io_enq_req_1_bits_exceptionVec_12;
  assign enq_req_in[1].bits_exceptionVec_13 = io_enq_req_1_bits_exceptionVec_13;
  assign enq_req_in[1].bits_exceptionVec_14 = io_enq_req_1_bits_exceptionVec_14;
  assign enq_req_in[1].bits_exceptionVec_15 = io_enq_req_1_bits_exceptionVec_15;
  assign enq_req_in[1].bits_exceptionVec_16 = io_enq_req_1_bits_exceptionVec_16;
  assign enq_req_in[1].bits_exceptionVec_17 = io_enq_req_1_bits_exceptionVec_17;
  assign enq_req_in[1].bits_exceptionVec_18 = io_enq_req_1_bits_exceptionVec_18;
  assign enq_req_in[1].bits_exceptionVec_19 = io_enq_req_1_bits_exceptionVec_19;
  assign enq_req_in[1].bits_exceptionVec_20 = io_enq_req_1_bits_exceptionVec_20;
  assign enq_req_in[1].bits_exceptionVec_21 = io_enq_req_1_bits_exceptionVec_21;
  assign enq_req_in[1].bits_exceptionVec_22 = io_enq_req_1_bits_exceptionVec_22;
  assign enq_req_in[1].bits_exceptionVec_23 = io_enq_req_1_bits_exceptionVec_23;
  assign enq_req_in[1].bits_trigger = io_enq_req_1_bits_trigger;
  assign enq_req_in[1].bits_fuType = io_enq_req_1_bits_fuType;
  assign enq_req_in[1].bits_fuOpType = io_enq_req_1_bits_fuOpType;
  assign enq_req_in[1].bits_rfWen = io_enq_req_1_bits_rfWen;
  assign enq_req_in[1].bits_flushPipe = io_enq_req_1_bits_flushPipe;
  assign enq_req_in[1].bits_vpu_nf = io_enq_req_1_bits_vpu_nf;
  assign enq_req_in[1].bits_vpu_veew = io_enq_req_1_bits_vpu_veew;
  assign enq_req_in[1].bits_uopIdx = io_enq_req_1_bits_uopIdx;
  assign enq_req_in[1].bits_lastUop = io_enq_req_1_bits_lastUop;
  assign enq_req_in[1].bits_pdest = io_enq_req_1_bits_pdest;
  assign enq_req_in[1].bits_robIdx_flag = io_enq_req_1_bits_robIdx_flag;
  assign enq_req_in[1].bits_robIdx_value = io_enq_req_1_bits_robIdx_value;
  assign enq_req_in[1].bits_debugInfo_eliminatedMove = io_enq_req_1_bits_debugInfo_eliminatedMove;
  assign enq_req_in[1].bits_debugInfo_renameTime = io_enq_req_1_bits_debugInfo_renameTime;
  assign enq_req_in[1].bits_debugInfo_dispatchTime = io_enq_req_1_bits_debugInfo_dispatchTime;
  assign enq_req_in[1].bits_debugInfo_enqRsTime = io_enq_req_1_bits_debugInfo_enqRsTime;
  assign enq_req_in[1].bits_debugInfo_selectTime = io_enq_req_1_bits_debugInfo_selectTime;
  assign enq_req_in[1].bits_debugInfo_issueTime = io_enq_req_1_bits_debugInfo_issueTime;
  assign enq_req_in[1].bits_debugInfo_writebackTime = io_enq_req_1_bits_debugInfo_writebackTime;
  assign enq_req_in[1].bits_debugInfo_runahead_checkpoint_id = io_enq_req_1_bits_debugInfo_runahead_checkpoint_id;
  assign enq_req_in[1].bits_debugInfo_tlbFirstReqTime = io_enq_req_1_bits_debugInfo_tlbFirstReqTime;
  assign enq_req_in[1].bits_debugInfo_tlbRespTime = io_enq_req_1_bits_debugInfo_tlbRespTime;
  assign enq_req_in[1].bits_debug_seqNum_seqNum = io_enq_req_1_bits_debug_seqNum_seqNum;
  assign enq_req_in[1].bits_debug_seqNum_uopIdx = io_enq_req_1_bits_debug_seqNum_uopIdx;
  assign enq_req_in[1].bits_sqIdx_flag = io_enq_req_1_bits_sqIdx_flag;
  assign enq_req_in[1].bits_sqIdx_value = io_enq_req_1_bits_sqIdx_value;
  assign enq_req_in[1].bits_numLsElem = io_enq_req_1_bits_numLsElem;
  assign enq_req_in[2].valid = io_enq_req_2_valid;
  assign enq_req_in[2].bits_exceptionVec_0 = io_enq_req_2_bits_exceptionVec_0;
  assign enq_req_in[2].bits_exceptionVec_1 = io_enq_req_2_bits_exceptionVec_1;
  assign enq_req_in[2].bits_exceptionVec_2 = io_enq_req_2_bits_exceptionVec_2;
  assign enq_req_in[2].bits_exceptionVec_3 = io_enq_req_2_bits_exceptionVec_3;
  assign enq_req_in[2].bits_exceptionVec_4 = io_enq_req_2_bits_exceptionVec_4;
  assign enq_req_in[2].bits_exceptionVec_5 = io_enq_req_2_bits_exceptionVec_5;
  assign enq_req_in[2].bits_exceptionVec_6 = io_enq_req_2_bits_exceptionVec_6;
  assign enq_req_in[2].bits_exceptionVec_7 = io_enq_req_2_bits_exceptionVec_7;
  assign enq_req_in[2].bits_exceptionVec_8 = io_enq_req_2_bits_exceptionVec_8;
  assign enq_req_in[2].bits_exceptionVec_9 = io_enq_req_2_bits_exceptionVec_9;
  assign enq_req_in[2].bits_exceptionVec_10 = io_enq_req_2_bits_exceptionVec_10;
  assign enq_req_in[2].bits_exceptionVec_11 = io_enq_req_2_bits_exceptionVec_11;
  assign enq_req_in[2].bits_exceptionVec_12 = io_enq_req_2_bits_exceptionVec_12;
  assign enq_req_in[2].bits_exceptionVec_13 = io_enq_req_2_bits_exceptionVec_13;
  assign enq_req_in[2].bits_exceptionVec_14 = io_enq_req_2_bits_exceptionVec_14;
  assign enq_req_in[2].bits_exceptionVec_15 = io_enq_req_2_bits_exceptionVec_15;
  assign enq_req_in[2].bits_exceptionVec_16 = io_enq_req_2_bits_exceptionVec_16;
  assign enq_req_in[2].bits_exceptionVec_17 = io_enq_req_2_bits_exceptionVec_17;
  assign enq_req_in[2].bits_exceptionVec_18 = io_enq_req_2_bits_exceptionVec_18;
  assign enq_req_in[2].bits_exceptionVec_19 = io_enq_req_2_bits_exceptionVec_19;
  assign enq_req_in[2].bits_exceptionVec_20 = io_enq_req_2_bits_exceptionVec_20;
  assign enq_req_in[2].bits_exceptionVec_21 = io_enq_req_2_bits_exceptionVec_21;
  assign enq_req_in[2].bits_exceptionVec_22 = io_enq_req_2_bits_exceptionVec_22;
  assign enq_req_in[2].bits_exceptionVec_23 = io_enq_req_2_bits_exceptionVec_23;
  assign enq_req_in[2].bits_trigger = io_enq_req_2_bits_trigger;
  assign enq_req_in[2].bits_fuType = io_enq_req_2_bits_fuType;
  assign enq_req_in[2].bits_fuOpType = io_enq_req_2_bits_fuOpType;
  assign enq_req_in[2].bits_rfWen = io_enq_req_2_bits_rfWen;
  assign enq_req_in[2].bits_flushPipe = io_enq_req_2_bits_flushPipe;
  assign enq_req_in[2].bits_vpu_nf = io_enq_req_2_bits_vpu_nf;
  assign enq_req_in[2].bits_vpu_veew = io_enq_req_2_bits_vpu_veew;
  assign enq_req_in[2].bits_uopIdx = io_enq_req_2_bits_uopIdx;
  assign enq_req_in[2].bits_lastUop = io_enq_req_2_bits_lastUop;
  assign enq_req_in[2].bits_pdest = io_enq_req_2_bits_pdest;
  assign enq_req_in[2].bits_robIdx_flag = io_enq_req_2_bits_robIdx_flag;
  assign enq_req_in[2].bits_robIdx_value = io_enq_req_2_bits_robIdx_value;
  assign enq_req_in[2].bits_debugInfo_eliminatedMove = io_enq_req_2_bits_debugInfo_eliminatedMove;
  assign enq_req_in[2].bits_debugInfo_renameTime = io_enq_req_2_bits_debugInfo_renameTime;
  assign enq_req_in[2].bits_debugInfo_dispatchTime = io_enq_req_2_bits_debugInfo_dispatchTime;
  assign enq_req_in[2].bits_debugInfo_enqRsTime = io_enq_req_2_bits_debugInfo_enqRsTime;
  assign enq_req_in[2].bits_debugInfo_selectTime = io_enq_req_2_bits_debugInfo_selectTime;
  assign enq_req_in[2].bits_debugInfo_issueTime = io_enq_req_2_bits_debugInfo_issueTime;
  assign enq_req_in[2].bits_debugInfo_writebackTime = io_enq_req_2_bits_debugInfo_writebackTime;
  assign enq_req_in[2].bits_debugInfo_runahead_checkpoint_id = io_enq_req_2_bits_debugInfo_runahead_checkpoint_id;
  assign enq_req_in[2].bits_debugInfo_tlbFirstReqTime = io_enq_req_2_bits_debugInfo_tlbFirstReqTime;
  assign enq_req_in[2].bits_debugInfo_tlbRespTime = io_enq_req_2_bits_debugInfo_tlbRespTime;
  assign enq_req_in[2].bits_debug_seqNum_seqNum = io_enq_req_2_bits_debug_seqNum_seqNum;
  assign enq_req_in[2].bits_debug_seqNum_uopIdx = io_enq_req_2_bits_debug_seqNum_uopIdx;
  assign enq_req_in[2].bits_sqIdx_flag = io_enq_req_2_bits_sqIdx_flag;
  assign enq_req_in[2].bits_sqIdx_value = io_enq_req_2_bits_sqIdx_value;
  assign enq_req_in[2].bits_numLsElem = io_enq_req_2_bits_numLsElem;
  assign enq_req_in[3].valid = io_enq_req_3_valid;
  assign enq_req_in[3].bits_exceptionVec_0 = io_enq_req_3_bits_exceptionVec_0;
  assign enq_req_in[3].bits_exceptionVec_1 = io_enq_req_3_bits_exceptionVec_1;
  assign enq_req_in[3].bits_exceptionVec_2 = io_enq_req_3_bits_exceptionVec_2;
  assign enq_req_in[3].bits_exceptionVec_3 = io_enq_req_3_bits_exceptionVec_3;
  assign enq_req_in[3].bits_exceptionVec_4 = io_enq_req_3_bits_exceptionVec_4;
  assign enq_req_in[3].bits_exceptionVec_5 = io_enq_req_3_bits_exceptionVec_5;
  assign enq_req_in[3].bits_exceptionVec_6 = io_enq_req_3_bits_exceptionVec_6;
  assign enq_req_in[3].bits_exceptionVec_7 = io_enq_req_3_bits_exceptionVec_7;
  assign enq_req_in[3].bits_exceptionVec_8 = io_enq_req_3_bits_exceptionVec_8;
  assign enq_req_in[3].bits_exceptionVec_9 = io_enq_req_3_bits_exceptionVec_9;
  assign enq_req_in[3].bits_exceptionVec_10 = io_enq_req_3_bits_exceptionVec_10;
  assign enq_req_in[3].bits_exceptionVec_11 = io_enq_req_3_bits_exceptionVec_11;
  assign enq_req_in[3].bits_exceptionVec_12 = io_enq_req_3_bits_exceptionVec_12;
  assign enq_req_in[3].bits_exceptionVec_13 = io_enq_req_3_bits_exceptionVec_13;
  assign enq_req_in[3].bits_exceptionVec_14 = io_enq_req_3_bits_exceptionVec_14;
  assign enq_req_in[3].bits_exceptionVec_15 = io_enq_req_3_bits_exceptionVec_15;
  assign enq_req_in[3].bits_exceptionVec_16 = io_enq_req_3_bits_exceptionVec_16;
  assign enq_req_in[3].bits_exceptionVec_17 = io_enq_req_3_bits_exceptionVec_17;
  assign enq_req_in[3].bits_exceptionVec_18 = io_enq_req_3_bits_exceptionVec_18;
  assign enq_req_in[3].bits_exceptionVec_19 = io_enq_req_3_bits_exceptionVec_19;
  assign enq_req_in[3].bits_exceptionVec_20 = io_enq_req_3_bits_exceptionVec_20;
  assign enq_req_in[3].bits_exceptionVec_21 = io_enq_req_3_bits_exceptionVec_21;
  assign enq_req_in[3].bits_exceptionVec_22 = io_enq_req_3_bits_exceptionVec_22;
  assign enq_req_in[3].bits_exceptionVec_23 = io_enq_req_3_bits_exceptionVec_23;
  assign enq_req_in[3].bits_trigger = io_enq_req_3_bits_trigger;
  assign enq_req_in[3].bits_fuType = io_enq_req_3_bits_fuType;
  assign enq_req_in[3].bits_fuOpType = io_enq_req_3_bits_fuOpType;
  assign enq_req_in[3].bits_rfWen = io_enq_req_3_bits_rfWen;
  assign enq_req_in[3].bits_flushPipe = io_enq_req_3_bits_flushPipe;
  assign enq_req_in[3].bits_vpu_nf = io_enq_req_3_bits_vpu_nf;
  assign enq_req_in[3].bits_vpu_veew = io_enq_req_3_bits_vpu_veew;
  assign enq_req_in[3].bits_uopIdx = io_enq_req_3_bits_uopIdx;
  assign enq_req_in[3].bits_lastUop = io_enq_req_3_bits_lastUop;
  assign enq_req_in[3].bits_pdest = io_enq_req_3_bits_pdest;
  assign enq_req_in[3].bits_robIdx_flag = io_enq_req_3_bits_robIdx_flag;
  assign enq_req_in[3].bits_robIdx_value = io_enq_req_3_bits_robIdx_value;
  assign enq_req_in[3].bits_debugInfo_eliminatedMove = io_enq_req_3_bits_debugInfo_eliminatedMove;
  assign enq_req_in[3].bits_debugInfo_renameTime = io_enq_req_3_bits_debugInfo_renameTime;
  assign enq_req_in[3].bits_debugInfo_dispatchTime = io_enq_req_3_bits_debugInfo_dispatchTime;
  assign enq_req_in[3].bits_debugInfo_enqRsTime = io_enq_req_3_bits_debugInfo_enqRsTime;
  assign enq_req_in[3].bits_debugInfo_selectTime = io_enq_req_3_bits_debugInfo_selectTime;
  assign enq_req_in[3].bits_debugInfo_issueTime = io_enq_req_3_bits_debugInfo_issueTime;
  assign enq_req_in[3].bits_debugInfo_writebackTime = io_enq_req_3_bits_debugInfo_writebackTime;
  assign enq_req_in[3].bits_debugInfo_runahead_checkpoint_id = io_enq_req_3_bits_debugInfo_runahead_checkpoint_id;
  assign enq_req_in[3].bits_debugInfo_tlbFirstReqTime = io_enq_req_3_bits_debugInfo_tlbFirstReqTime;
  assign enq_req_in[3].bits_debugInfo_tlbRespTime = io_enq_req_3_bits_debugInfo_tlbRespTime;
  assign enq_req_in[3].bits_debug_seqNum_seqNum = io_enq_req_3_bits_debug_seqNum_seqNum;
  assign enq_req_in[3].bits_debug_seqNum_uopIdx = io_enq_req_3_bits_debug_seqNum_uopIdx;
  assign enq_req_in[3].bits_sqIdx_flag = io_enq_req_3_bits_sqIdx_flag;
  assign enq_req_in[3].bits_sqIdx_value = io_enq_req_3_bits_sqIdx_value;
  assign enq_req_in[3].bits_numLsElem = io_enq_req_3_bits_numLsElem;
  assign enq_req_in[4].valid = io_enq_req_4_valid;
  assign enq_req_in[4].bits_exceptionVec_0 = io_enq_req_4_bits_exceptionVec_0;
  assign enq_req_in[4].bits_exceptionVec_1 = io_enq_req_4_bits_exceptionVec_1;
  assign enq_req_in[4].bits_exceptionVec_2 = io_enq_req_4_bits_exceptionVec_2;
  assign enq_req_in[4].bits_exceptionVec_3 = io_enq_req_4_bits_exceptionVec_3;
  assign enq_req_in[4].bits_exceptionVec_4 = io_enq_req_4_bits_exceptionVec_4;
  assign enq_req_in[4].bits_exceptionVec_5 = io_enq_req_4_bits_exceptionVec_5;
  assign enq_req_in[4].bits_exceptionVec_6 = io_enq_req_4_bits_exceptionVec_6;
  assign enq_req_in[4].bits_exceptionVec_7 = io_enq_req_4_bits_exceptionVec_7;
  assign enq_req_in[4].bits_exceptionVec_8 = io_enq_req_4_bits_exceptionVec_8;
  assign enq_req_in[4].bits_exceptionVec_9 = io_enq_req_4_bits_exceptionVec_9;
  assign enq_req_in[4].bits_exceptionVec_10 = io_enq_req_4_bits_exceptionVec_10;
  assign enq_req_in[4].bits_exceptionVec_11 = io_enq_req_4_bits_exceptionVec_11;
  assign enq_req_in[4].bits_exceptionVec_12 = io_enq_req_4_bits_exceptionVec_12;
  assign enq_req_in[4].bits_exceptionVec_13 = io_enq_req_4_bits_exceptionVec_13;
  assign enq_req_in[4].bits_exceptionVec_14 = io_enq_req_4_bits_exceptionVec_14;
  assign enq_req_in[4].bits_exceptionVec_15 = io_enq_req_4_bits_exceptionVec_15;
  assign enq_req_in[4].bits_exceptionVec_16 = io_enq_req_4_bits_exceptionVec_16;
  assign enq_req_in[4].bits_exceptionVec_17 = io_enq_req_4_bits_exceptionVec_17;
  assign enq_req_in[4].bits_exceptionVec_18 = io_enq_req_4_bits_exceptionVec_18;
  assign enq_req_in[4].bits_exceptionVec_19 = io_enq_req_4_bits_exceptionVec_19;
  assign enq_req_in[4].bits_exceptionVec_20 = io_enq_req_4_bits_exceptionVec_20;
  assign enq_req_in[4].bits_exceptionVec_21 = io_enq_req_4_bits_exceptionVec_21;
  assign enq_req_in[4].bits_exceptionVec_22 = io_enq_req_4_bits_exceptionVec_22;
  assign enq_req_in[4].bits_exceptionVec_23 = io_enq_req_4_bits_exceptionVec_23;
  assign enq_req_in[4].bits_trigger = io_enq_req_4_bits_trigger;
  assign enq_req_in[4].bits_fuType = io_enq_req_4_bits_fuType;
  assign enq_req_in[4].bits_fuOpType = io_enq_req_4_bits_fuOpType;
  assign enq_req_in[4].bits_rfWen = io_enq_req_4_bits_rfWen;
  assign enq_req_in[4].bits_flushPipe = io_enq_req_4_bits_flushPipe;
  assign enq_req_in[4].bits_vpu_nf = io_enq_req_4_bits_vpu_nf;
  assign enq_req_in[4].bits_vpu_veew = io_enq_req_4_bits_vpu_veew;
  assign enq_req_in[4].bits_uopIdx = io_enq_req_4_bits_uopIdx;
  assign enq_req_in[4].bits_lastUop = io_enq_req_4_bits_lastUop;
  assign enq_req_in[4].bits_pdest = io_enq_req_4_bits_pdest;
  assign enq_req_in[4].bits_robIdx_flag = io_enq_req_4_bits_robIdx_flag;
  assign enq_req_in[4].bits_robIdx_value = io_enq_req_4_bits_robIdx_value;
  assign enq_req_in[4].bits_debugInfo_eliminatedMove = io_enq_req_4_bits_debugInfo_eliminatedMove;
  assign enq_req_in[4].bits_debugInfo_renameTime = io_enq_req_4_bits_debugInfo_renameTime;
  assign enq_req_in[4].bits_debugInfo_dispatchTime = io_enq_req_4_bits_debugInfo_dispatchTime;
  assign enq_req_in[4].bits_debugInfo_enqRsTime = io_enq_req_4_bits_debugInfo_enqRsTime;
  assign enq_req_in[4].bits_debugInfo_selectTime = io_enq_req_4_bits_debugInfo_selectTime;
  assign enq_req_in[4].bits_debugInfo_issueTime = io_enq_req_4_bits_debugInfo_issueTime;
  assign enq_req_in[4].bits_debugInfo_writebackTime = io_enq_req_4_bits_debugInfo_writebackTime;
  assign enq_req_in[4].bits_debugInfo_runahead_checkpoint_id = io_enq_req_4_bits_debugInfo_runahead_checkpoint_id;
  assign enq_req_in[4].bits_debugInfo_tlbFirstReqTime = io_enq_req_4_bits_debugInfo_tlbFirstReqTime;
  assign enq_req_in[4].bits_debugInfo_tlbRespTime = io_enq_req_4_bits_debugInfo_tlbRespTime;
  assign enq_req_in[4].bits_debug_seqNum_seqNum = io_enq_req_4_bits_debug_seqNum_seqNum;
  assign enq_req_in[4].bits_debug_seqNum_uopIdx = io_enq_req_4_bits_debug_seqNum_uopIdx;
  assign enq_req_in[4].bits_sqIdx_flag = io_enq_req_4_bits_sqIdx_flag;
  assign enq_req_in[4].bits_sqIdx_value = io_enq_req_4_bits_sqIdx_value;
  assign enq_req_in[4].bits_numLsElem = io_enq_req_4_bits_numLsElem;
  assign enq_req_in[5].valid = io_enq_req_5_valid;
  assign enq_req_in[5].bits_exceptionVec_0 = io_enq_req_5_bits_exceptionVec_0;
  assign enq_req_in[5].bits_exceptionVec_1 = io_enq_req_5_bits_exceptionVec_1;
  assign enq_req_in[5].bits_exceptionVec_2 = io_enq_req_5_bits_exceptionVec_2;
  assign enq_req_in[5].bits_exceptionVec_3 = io_enq_req_5_bits_exceptionVec_3;
  assign enq_req_in[5].bits_exceptionVec_4 = io_enq_req_5_bits_exceptionVec_4;
  assign enq_req_in[5].bits_exceptionVec_5 = io_enq_req_5_bits_exceptionVec_5;
  assign enq_req_in[5].bits_exceptionVec_6 = io_enq_req_5_bits_exceptionVec_6;
  assign enq_req_in[5].bits_exceptionVec_7 = io_enq_req_5_bits_exceptionVec_7;
  assign enq_req_in[5].bits_exceptionVec_8 = io_enq_req_5_bits_exceptionVec_8;
  assign enq_req_in[5].bits_exceptionVec_9 = io_enq_req_5_bits_exceptionVec_9;
  assign enq_req_in[5].bits_exceptionVec_10 = io_enq_req_5_bits_exceptionVec_10;
  assign enq_req_in[5].bits_exceptionVec_11 = io_enq_req_5_bits_exceptionVec_11;
  assign enq_req_in[5].bits_exceptionVec_12 = io_enq_req_5_bits_exceptionVec_12;
  assign enq_req_in[5].bits_exceptionVec_13 = io_enq_req_5_bits_exceptionVec_13;
  assign enq_req_in[5].bits_exceptionVec_14 = io_enq_req_5_bits_exceptionVec_14;
  assign enq_req_in[5].bits_exceptionVec_15 = io_enq_req_5_bits_exceptionVec_15;
  assign enq_req_in[5].bits_exceptionVec_16 = io_enq_req_5_bits_exceptionVec_16;
  assign enq_req_in[5].bits_exceptionVec_17 = io_enq_req_5_bits_exceptionVec_17;
  assign enq_req_in[5].bits_exceptionVec_18 = io_enq_req_5_bits_exceptionVec_18;
  assign enq_req_in[5].bits_exceptionVec_19 = io_enq_req_5_bits_exceptionVec_19;
  assign enq_req_in[5].bits_exceptionVec_20 = io_enq_req_5_bits_exceptionVec_20;
  assign enq_req_in[5].bits_exceptionVec_21 = io_enq_req_5_bits_exceptionVec_21;
  assign enq_req_in[5].bits_exceptionVec_22 = io_enq_req_5_bits_exceptionVec_22;
  assign enq_req_in[5].bits_exceptionVec_23 = io_enq_req_5_bits_exceptionVec_23;
  assign enq_req_in[5].bits_trigger = io_enq_req_5_bits_trigger;
  assign enq_req_in[5].bits_fuType = io_enq_req_5_bits_fuType;
  assign enq_req_in[5].bits_fuOpType = io_enq_req_5_bits_fuOpType;
  assign enq_req_in[5].bits_rfWen = io_enq_req_5_bits_rfWen;
  assign enq_req_in[5].bits_flushPipe = io_enq_req_5_bits_flushPipe;
  assign enq_req_in[5].bits_vpu_nf = io_enq_req_5_bits_vpu_nf;
  assign enq_req_in[5].bits_vpu_veew = io_enq_req_5_bits_vpu_veew;
  assign enq_req_in[5].bits_uopIdx = io_enq_req_5_bits_uopIdx;
  assign enq_req_in[5].bits_lastUop = io_enq_req_5_bits_lastUop;
  assign enq_req_in[5].bits_pdest = io_enq_req_5_bits_pdest;
  assign enq_req_in[5].bits_robIdx_flag = io_enq_req_5_bits_robIdx_flag;
  assign enq_req_in[5].bits_robIdx_value = io_enq_req_5_bits_robIdx_value;
  assign enq_req_in[5].bits_debugInfo_eliminatedMove = io_enq_req_5_bits_debugInfo_eliminatedMove;
  assign enq_req_in[5].bits_debugInfo_renameTime = io_enq_req_5_bits_debugInfo_renameTime;
  assign enq_req_in[5].bits_debugInfo_dispatchTime = io_enq_req_5_bits_debugInfo_dispatchTime;
  assign enq_req_in[5].bits_debugInfo_enqRsTime = io_enq_req_5_bits_debugInfo_enqRsTime;
  assign enq_req_in[5].bits_debugInfo_selectTime = io_enq_req_5_bits_debugInfo_selectTime;
  assign enq_req_in[5].bits_debugInfo_issueTime = io_enq_req_5_bits_debugInfo_issueTime;
  assign enq_req_in[5].bits_debugInfo_writebackTime = io_enq_req_5_bits_debugInfo_writebackTime;
  assign enq_req_in[5].bits_debugInfo_runahead_checkpoint_id = io_enq_req_5_bits_debugInfo_runahead_checkpoint_id;
  assign enq_req_in[5].bits_debugInfo_tlbFirstReqTime = io_enq_req_5_bits_debugInfo_tlbFirstReqTime;
  assign enq_req_in[5].bits_debugInfo_tlbRespTime = io_enq_req_5_bits_debugInfo_tlbRespTime;
  assign enq_req_in[5].bits_debug_seqNum_seqNum = io_enq_req_5_bits_debug_seqNum_seqNum;
  assign enq_req_in[5].bits_debug_seqNum_uopIdx = io_enq_req_5_bits_debug_seqNum_uopIdx;
  assign enq_req_in[5].bits_sqIdx_flag = io_enq_req_5_bits_sqIdx_flag;
  assign enq_req_in[5].bits_sqIdx_value = io_enq_req_5_bits_sqIdx_value;
  assign enq_req_in[5].bits_numLsElem = io_enq_req_5_bits_numLsElem;

  sq_storeAddrIn_t_in storeAddrIn_in [2];
  assign storeAddrIn_in[0].valid = io_storeAddrIn_0_valid;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_0 = io_storeAddrIn_0_bits_uop_exceptionVec_0;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_1 = io_storeAddrIn_0_bits_uop_exceptionVec_1;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_2 = io_storeAddrIn_0_bits_uop_exceptionVec_2;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_3 = io_storeAddrIn_0_bits_uop_exceptionVec_3;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_4 = io_storeAddrIn_0_bits_uop_exceptionVec_4;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_5 = io_storeAddrIn_0_bits_uop_exceptionVec_5;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_6 = io_storeAddrIn_0_bits_uop_exceptionVec_6;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_7 = io_storeAddrIn_0_bits_uop_exceptionVec_7;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_8 = io_storeAddrIn_0_bits_uop_exceptionVec_8;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_9 = io_storeAddrIn_0_bits_uop_exceptionVec_9;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_10 = io_storeAddrIn_0_bits_uop_exceptionVec_10;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_11 = io_storeAddrIn_0_bits_uop_exceptionVec_11;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_12 = io_storeAddrIn_0_bits_uop_exceptionVec_12;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_13 = io_storeAddrIn_0_bits_uop_exceptionVec_13;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_14 = io_storeAddrIn_0_bits_uop_exceptionVec_14;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_15 = io_storeAddrIn_0_bits_uop_exceptionVec_15;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_16 = io_storeAddrIn_0_bits_uop_exceptionVec_16;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_17 = io_storeAddrIn_0_bits_uop_exceptionVec_17;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_18 = io_storeAddrIn_0_bits_uop_exceptionVec_18;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_19 = io_storeAddrIn_0_bits_uop_exceptionVec_19;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_20 = io_storeAddrIn_0_bits_uop_exceptionVec_20;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_21 = io_storeAddrIn_0_bits_uop_exceptionVec_21;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_22 = io_storeAddrIn_0_bits_uop_exceptionVec_22;
  assign storeAddrIn_in[0].bits_uop_exceptionVec_23 = io_storeAddrIn_0_bits_uop_exceptionVec_23;
  assign storeAddrIn_in[0].bits_uop_trigger = io_storeAddrIn_0_bits_uop_trigger;
  assign storeAddrIn_in[0].bits_uop_fuType = io_storeAddrIn_0_bits_uop_fuType;
  assign storeAddrIn_in[0].bits_uop_fuOpType = io_storeAddrIn_0_bits_uop_fuOpType;
  assign storeAddrIn_in[0].bits_uop_rfWen = io_storeAddrIn_0_bits_uop_rfWen;
  assign storeAddrIn_in[0].bits_uop_vpu_nf = io_storeAddrIn_0_bits_uop_vpu_nf;
  assign storeAddrIn_in[0].bits_uop_vpu_veew = io_storeAddrIn_0_bits_uop_vpu_veew;
  assign storeAddrIn_in[0].bits_uop_uopIdx = io_storeAddrIn_0_bits_uop_uopIdx;
  assign storeAddrIn_in[0].bits_uop_pdest = io_storeAddrIn_0_bits_uop_pdest;
  assign storeAddrIn_in[0].bits_uop_robIdx_flag = io_storeAddrIn_0_bits_uop_robIdx_flag;
  assign storeAddrIn_in[0].bits_uop_robIdx_value = io_storeAddrIn_0_bits_uop_robIdx_value;
  assign storeAddrIn_in[0].bits_uop_debugInfo_eliminatedMove = io_storeAddrIn_0_bits_uop_debugInfo_eliminatedMove;
  assign storeAddrIn_in[0].bits_uop_debugInfo_renameTime = io_storeAddrIn_0_bits_uop_debugInfo_renameTime;
  assign storeAddrIn_in[0].bits_uop_debugInfo_dispatchTime = io_storeAddrIn_0_bits_uop_debugInfo_dispatchTime;
  assign storeAddrIn_in[0].bits_uop_debugInfo_enqRsTime = io_storeAddrIn_0_bits_uop_debugInfo_enqRsTime;
  assign storeAddrIn_in[0].bits_uop_debugInfo_selectTime = io_storeAddrIn_0_bits_uop_debugInfo_selectTime;
  assign storeAddrIn_in[0].bits_uop_debugInfo_issueTime = io_storeAddrIn_0_bits_uop_debugInfo_issueTime;
  assign storeAddrIn_in[0].bits_uop_debugInfo_writebackTime = io_storeAddrIn_0_bits_uop_debugInfo_writebackTime;
  assign storeAddrIn_in[0].bits_uop_debugInfo_runahead_checkpoint_id = io_storeAddrIn_0_bits_uop_debugInfo_runahead_checkpoint_id;
  assign storeAddrIn_in[0].bits_uop_debugInfo_tlbFirstReqTime = io_storeAddrIn_0_bits_uop_debugInfo_tlbFirstReqTime;
  assign storeAddrIn_in[0].bits_uop_debugInfo_tlbRespTime = io_storeAddrIn_0_bits_uop_debugInfo_tlbRespTime;
  assign storeAddrIn_in[0].bits_uop_debug_seqNum_seqNum = io_storeAddrIn_0_bits_uop_debug_seqNum_seqNum;
  assign storeAddrIn_in[0].bits_uop_debug_seqNum_uopIdx = io_storeAddrIn_0_bits_uop_debug_seqNum_uopIdx;
  assign storeAddrIn_in[0].bits_uop_sqIdx_value = io_storeAddrIn_0_bits_uop_sqIdx_value;
  assign storeAddrIn_in[0].bits_vaddr = io_storeAddrIn_0_bits_vaddr;
  assign storeAddrIn_in[0].bits_fullva = io_storeAddrIn_0_bits_fullva;
  assign storeAddrIn_in[0].bits_vaNeedExt = io_storeAddrIn_0_bits_vaNeedExt;
  assign storeAddrIn_in[0].bits_paddr = io_storeAddrIn_0_bits_paddr;
  assign storeAddrIn_in[0].bits_gpaddr = io_storeAddrIn_0_bits_gpaddr;
  assign storeAddrIn_in[0].bits_mask = io_storeAddrIn_0_bits_mask;
  assign storeAddrIn_in[0].bits_wlineflag = io_storeAddrIn_0_bits_wlineflag;
  assign storeAddrIn_in[0].bits_miss = io_storeAddrIn_0_bits_miss;
  assign storeAddrIn_in[0].bits_nc = io_storeAddrIn_0_bits_nc;
  assign storeAddrIn_in[0].bits_isHyper = io_storeAddrIn_0_bits_isHyper;
  assign storeAddrIn_in[0].bits_isForVSnonLeafPTE = io_storeAddrIn_0_bits_isForVSnonLeafPTE;
  assign storeAddrIn_in[0].bits_isvec = io_storeAddrIn_0_bits_isvec;
  assign storeAddrIn_in[0].bits_isFrmMisAlignBuf = io_storeAddrIn_0_bits_isFrmMisAlignBuf;
  assign storeAddrIn_in[0].bits_isMisalign = io_storeAddrIn_0_bits_isMisalign;
  assign storeAddrIn_in[0].bits_misalignWith16Byte = io_storeAddrIn_0_bits_misalignWith16Byte;
  assign storeAddrIn_in[0].bits_updateAddrValid = io_storeAddrIn_0_bits_updateAddrValid;
  assign storeAddrIn_in[1].valid = io_storeAddrIn_1_valid;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_0 = io_storeAddrIn_1_bits_uop_exceptionVec_0;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_1 = io_storeAddrIn_1_bits_uop_exceptionVec_1;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_2 = io_storeAddrIn_1_bits_uop_exceptionVec_2;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_3 = io_storeAddrIn_1_bits_uop_exceptionVec_3;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_4 = io_storeAddrIn_1_bits_uop_exceptionVec_4;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_5 = io_storeAddrIn_1_bits_uop_exceptionVec_5;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_6 = io_storeAddrIn_1_bits_uop_exceptionVec_6;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_7 = io_storeAddrIn_1_bits_uop_exceptionVec_7;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_8 = io_storeAddrIn_1_bits_uop_exceptionVec_8;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_9 = io_storeAddrIn_1_bits_uop_exceptionVec_9;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_10 = io_storeAddrIn_1_bits_uop_exceptionVec_10;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_11 = io_storeAddrIn_1_bits_uop_exceptionVec_11;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_12 = io_storeAddrIn_1_bits_uop_exceptionVec_12;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_13 = io_storeAddrIn_1_bits_uop_exceptionVec_13;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_14 = io_storeAddrIn_1_bits_uop_exceptionVec_14;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_15 = io_storeAddrIn_1_bits_uop_exceptionVec_15;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_16 = io_storeAddrIn_1_bits_uop_exceptionVec_16;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_17 = io_storeAddrIn_1_bits_uop_exceptionVec_17;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_18 = io_storeAddrIn_1_bits_uop_exceptionVec_18;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_19 = io_storeAddrIn_1_bits_uop_exceptionVec_19;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_20 = io_storeAddrIn_1_bits_uop_exceptionVec_20;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_21 = io_storeAddrIn_1_bits_uop_exceptionVec_21;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_22 = io_storeAddrIn_1_bits_uop_exceptionVec_22;
  assign storeAddrIn_in[1].bits_uop_exceptionVec_23 = io_storeAddrIn_1_bits_uop_exceptionVec_23;
  assign storeAddrIn_in[1].bits_uop_trigger = io_storeAddrIn_1_bits_uop_trigger;
  assign storeAddrIn_in[1].bits_uop_fuType = io_storeAddrIn_1_bits_uop_fuType;
  assign storeAddrIn_in[1].bits_uop_fuOpType = io_storeAddrIn_1_bits_uop_fuOpType;
  assign storeAddrIn_in[1].bits_uop_rfWen = io_storeAddrIn_1_bits_uop_rfWen;
  assign storeAddrIn_in[1].bits_uop_vpu_nf = io_storeAddrIn_1_bits_uop_vpu_nf;
  assign storeAddrIn_in[1].bits_uop_vpu_veew = io_storeAddrIn_1_bits_uop_vpu_veew;
  assign storeAddrIn_in[1].bits_uop_uopIdx = io_storeAddrIn_1_bits_uop_uopIdx;
  assign storeAddrIn_in[1].bits_uop_pdest = io_storeAddrIn_1_bits_uop_pdest;
  assign storeAddrIn_in[1].bits_uop_robIdx_flag = io_storeAddrIn_1_bits_uop_robIdx_flag;
  assign storeAddrIn_in[1].bits_uop_robIdx_value = io_storeAddrIn_1_bits_uop_robIdx_value;
  assign storeAddrIn_in[1].bits_uop_debugInfo_eliminatedMove = io_storeAddrIn_1_bits_uop_debugInfo_eliminatedMove;
  assign storeAddrIn_in[1].bits_uop_debugInfo_renameTime = io_storeAddrIn_1_bits_uop_debugInfo_renameTime;
  assign storeAddrIn_in[1].bits_uop_debugInfo_dispatchTime = io_storeAddrIn_1_bits_uop_debugInfo_dispatchTime;
  assign storeAddrIn_in[1].bits_uop_debugInfo_enqRsTime = io_storeAddrIn_1_bits_uop_debugInfo_enqRsTime;
  assign storeAddrIn_in[1].bits_uop_debugInfo_selectTime = io_storeAddrIn_1_bits_uop_debugInfo_selectTime;
  assign storeAddrIn_in[1].bits_uop_debugInfo_issueTime = io_storeAddrIn_1_bits_uop_debugInfo_issueTime;
  assign storeAddrIn_in[1].bits_uop_debugInfo_writebackTime = io_storeAddrIn_1_bits_uop_debugInfo_writebackTime;
  assign storeAddrIn_in[1].bits_uop_debugInfo_runahead_checkpoint_id = io_storeAddrIn_1_bits_uop_debugInfo_runahead_checkpoint_id;
  assign storeAddrIn_in[1].bits_uop_debugInfo_tlbFirstReqTime = io_storeAddrIn_1_bits_uop_debugInfo_tlbFirstReqTime;
  assign storeAddrIn_in[1].bits_uop_debugInfo_tlbRespTime = io_storeAddrIn_1_bits_uop_debugInfo_tlbRespTime;
  assign storeAddrIn_in[1].bits_uop_debug_seqNum_seqNum = io_storeAddrIn_1_bits_uop_debug_seqNum_seqNum;
  assign storeAddrIn_in[1].bits_uop_debug_seqNum_uopIdx = io_storeAddrIn_1_bits_uop_debug_seqNum_uopIdx;
  assign storeAddrIn_in[1].bits_uop_sqIdx_value = io_storeAddrIn_1_bits_uop_sqIdx_value;
  assign storeAddrIn_in[1].bits_vaddr = io_storeAddrIn_1_bits_vaddr;
  assign storeAddrIn_in[1].bits_fullva = io_storeAddrIn_1_bits_fullva;
  assign storeAddrIn_in[1].bits_vaNeedExt = io_storeAddrIn_1_bits_vaNeedExt;
  assign storeAddrIn_in[1].bits_paddr = io_storeAddrIn_1_bits_paddr;
  assign storeAddrIn_in[1].bits_gpaddr = io_storeAddrIn_1_bits_gpaddr;
  assign storeAddrIn_in[1].bits_mask = io_storeAddrIn_1_bits_mask;
  assign storeAddrIn_in[1].bits_wlineflag = io_storeAddrIn_1_bits_wlineflag;
  assign storeAddrIn_in[1].bits_miss = io_storeAddrIn_1_bits_miss;
  assign storeAddrIn_in[1].bits_nc = io_storeAddrIn_1_bits_nc;
  assign storeAddrIn_in[1].bits_isHyper = io_storeAddrIn_1_bits_isHyper;
  assign storeAddrIn_in[1].bits_isForVSnonLeafPTE = io_storeAddrIn_1_bits_isForVSnonLeafPTE;
  assign storeAddrIn_in[1].bits_isvec = io_storeAddrIn_1_bits_isvec;
  assign storeAddrIn_in[1].bits_isFrmMisAlignBuf = io_storeAddrIn_1_bits_isFrmMisAlignBuf;
  assign storeAddrIn_in[1].bits_isMisalign = io_storeAddrIn_1_bits_isMisalign;
  assign storeAddrIn_in[1].bits_misalignWith16Byte = io_storeAddrIn_1_bits_misalignWith16Byte;
  assign storeAddrIn_in[1].bits_updateAddrValid = io_storeAddrIn_1_bits_updateAddrValid;

  sq_storeAddrInRe_t_in storeAddrInRe_in [2];
  assign storeAddrInRe_in[0].uop_exceptionVec_3 = io_storeAddrInRe_0_uop_exceptionVec_3;
  assign storeAddrInRe_in[0].uop_exceptionVec_6 = io_storeAddrInRe_0_uop_exceptionVec_6;
  assign storeAddrInRe_in[0].uop_exceptionVec_15 = io_storeAddrInRe_0_uop_exceptionVec_15;
  assign storeAddrInRe_in[0].uop_exceptionVec_19 = io_storeAddrInRe_0_uop_exceptionVec_19;
  assign storeAddrInRe_in[0].uop_exceptionVec_23 = io_storeAddrInRe_0_uop_exceptionVec_23;
  assign storeAddrInRe_in[0].uop_uopIdx = io_storeAddrInRe_0_uop_uopIdx;
  assign storeAddrInRe_in[0].uop_robIdx_flag = io_storeAddrInRe_0_uop_robIdx_flag;
  assign storeAddrInRe_in[0].uop_robIdx_value = io_storeAddrInRe_0_uop_robIdx_value;
  assign storeAddrInRe_in[0].fullva = io_storeAddrInRe_0_fullva;
  assign storeAddrInRe_in[0].vaNeedExt = io_storeAddrInRe_0_vaNeedExt;
  assign storeAddrInRe_in[0].gpaddr = io_storeAddrInRe_0_gpaddr;
  assign storeAddrInRe_in[0].af = io_storeAddrInRe_0_af;
  assign storeAddrInRe_in[0].mmio = io_storeAddrInRe_0_mmio;
  assign storeAddrInRe_in[0].memBackTypeMM = io_storeAddrInRe_0_memBackTypeMM;
  assign storeAddrInRe_in[0].hasException = io_storeAddrInRe_0_hasException;
  assign storeAddrInRe_in[0].isHyper = io_storeAddrInRe_0_isHyper;
  assign storeAddrInRe_in[0].isForVSnonLeafPTE = io_storeAddrInRe_0_isForVSnonLeafPTE;
  assign storeAddrInRe_in[0].isvec = io_storeAddrInRe_0_isvec;
  assign storeAddrInRe_in[0].updateAddrValid = io_storeAddrInRe_0_updateAddrValid;
  assign storeAddrInRe_in[1].uop_exceptionVec_3 = io_storeAddrInRe_1_uop_exceptionVec_3;
  assign storeAddrInRe_in[1].uop_exceptionVec_6 = io_storeAddrInRe_1_uop_exceptionVec_6;
  assign storeAddrInRe_in[1].uop_exceptionVec_15 = io_storeAddrInRe_1_uop_exceptionVec_15;
  assign storeAddrInRe_in[1].uop_exceptionVec_19 = io_storeAddrInRe_1_uop_exceptionVec_19;
  assign storeAddrInRe_in[1].uop_exceptionVec_23 = io_storeAddrInRe_1_uop_exceptionVec_23;
  assign storeAddrInRe_in[1].uop_uopIdx = io_storeAddrInRe_1_uop_uopIdx;
  assign storeAddrInRe_in[1].uop_robIdx_flag = io_storeAddrInRe_1_uop_robIdx_flag;
  assign storeAddrInRe_in[1].uop_robIdx_value = io_storeAddrInRe_1_uop_robIdx_value;
  assign storeAddrInRe_in[1].fullva = io_storeAddrInRe_1_fullva;
  assign storeAddrInRe_in[1].vaNeedExt = io_storeAddrInRe_1_vaNeedExt;
  assign storeAddrInRe_in[1].gpaddr = io_storeAddrInRe_1_gpaddr;
  assign storeAddrInRe_in[1].af = io_storeAddrInRe_1_af;
  assign storeAddrInRe_in[1].mmio = io_storeAddrInRe_1_mmio;
  assign storeAddrInRe_in[1].memBackTypeMM = io_storeAddrInRe_1_memBackTypeMM;
  assign storeAddrInRe_in[1].hasException = io_storeAddrInRe_1_hasException;
  assign storeAddrInRe_in[1].isHyper = io_storeAddrInRe_1_isHyper;
  assign storeAddrInRe_in[1].isForVSnonLeafPTE = io_storeAddrInRe_1_isForVSnonLeafPTE;
  assign storeAddrInRe_in[1].isvec = io_storeAddrInRe_1_isvec;
  assign storeAddrInRe_in[1].updateAddrValid = io_storeAddrInRe_1_updateAddrValid;

  sq_storeDataIn_t_in storeDataIn_in [2];
  assign storeDataIn_in[0].valid = io_storeDataIn_0_valid;
  assign storeDataIn_in[0].bits_uop_fuType = io_storeDataIn_0_bits_uop_fuType;
  assign storeDataIn_in[0].bits_uop_fuOpType = io_storeDataIn_0_bits_uop_fuOpType;
  assign storeDataIn_in[0].bits_uop_sqIdx_value = io_storeDataIn_0_bits_uop_sqIdx_value;
  assign storeDataIn_in[0].bits_data = io_storeDataIn_0_bits_data;
  assign storeDataIn_in[0].bits_vecDebug_offset = io_storeDataIn_0_bits_vecDebug_offset;
  assign storeDataIn_in[1].valid = io_storeDataIn_1_valid;
  assign storeDataIn_in[1].bits_uop_fuType = io_storeDataIn_1_bits_uop_fuType;
  assign storeDataIn_in[1].bits_uop_fuOpType = io_storeDataIn_1_bits_uop_fuOpType;
  assign storeDataIn_in[1].bits_uop_sqIdx_value = io_storeDataIn_1_bits_uop_sqIdx_value;
  assign storeDataIn_in[1].bits_data = io_storeDataIn_1_bits_data;
  assign storeDataIn_in[1].bits_vecDebug_offset = io_storeDataIn_1_bits_vecDebug_offset;

  sq_storeMaskIn_t_in storeMaskIn_in [2];
  assign storeMaskIn_in[0].valid = io_storeMaskIn_0_valid;
  assign storeMaskIn_in[0].bits_sqIdx_value = io_storeMaskIn_0_bits_sqIdx_value;
  assign storeMaskIn_in[0].bits_mask = io_storeMaskIn_0_bits_mask;
  assign storeMaskIn_in[1].valid = io_storeMaskIn_1_valid;
  assign storeMaskIn_in[1].bits_sqIdx_value = io_storeMaskIn_1_bits_sqIdx_value;
  assign storeMaskIn_in[1].bits_mask = io_storeMaskIn_1_bits_mask;

  sq_forward_t_in forward_in [3];
  assign forward_in[0].vaddr = io_forward_0_vaddr;
  assign forward_in[0].paddr = io_forward_0_paddr;
  assign forward_in[0].mask = io_forward_0_mask;
  assign forward_in[0].uop_waitForRobIdx_flag = io_forward_0_uop_waitForRobIdx_flag;
  assign forward_in[0].uop_waitForRobIdx_value = io_forward_0_uop_waitForRobIdx_value;
  assign forward_in[0].uop_loadWaitBit = io_forward_0_uop_loadWaitBit;
  assign forward_in[0].uop_loadWaitStrict = io_forward_0_uop_loadWaitStrict;
  assign forward_in[0].uop_sqIdx_flag = io_forward_0_uop_sqIdx_flag;
  assign forward_in[0].uop_sqIdx_value = io_forward_0_uop_sqIdx_value;
  assign forward_in[0].valid = io_forward_0_valid;
  assign forward_in[0].sqIdx_flag = io_forward_0_sqIdx_flag;
  assign forward_in[0].sqIdxMask = io_forward_0_sqIdxMask;
  assign forward_in[1].vaddr = io_forward_1_vaddr;
  assign forward_in[1].paddr = io_forward_1_paddr;
  assign forward_in[1].mask = io_forward_1_mask;
  assign forward_in[1].uop_waitForRobIdx_flag = io_forward_1_uop_waitForRobIdx_flag;
  assign forward_in[1].uop_waitForRobIdx_value = io_forward_1_uop_waitForRobIdx_value;
  assign forward_in[1].uop_loadWaitBit = io_forward_1_uop_loadWaitBit;
  assign forward_in[1].uop_loadWaitStrict = io_forward_1_uop_loadWaitStrict;
  assign forward_in[1].uop_sqIdx_flag = io_forward_1_uop_sqIdx_flag;
  assign forward_in[1].uop_sqIdx_value = io_forward_1_uop_sqIdx_value;
  assign forward_in[1].valid = io_forward_1_valid;
  assign forward_in[1].sqIdx_flag = io_forward_1_sqIdx_flag;
  assign forward_in[1].sqIdxMask = io_forward_1_sqIdxMask;
  assign forward_in[2].vaddr = io_forward_2_vaddr;
  assign forward_in[2].paddr = io_forward_2_paddr;
  assign forward_in[2].mask = io_forward_2_mask;
  assign forward_in[2].uop_waitForRobIdx_flag = io_forward_2_uop_waitForRobIdx_flag;
  assign forward_in[2].uop_waitForRobIdx_value = io_forward_2_uop_waitForRobIdx_value;
  assign forward_in[2].uop_loadWaitBit = io_forward_2_uop_loadWaitBit;
  assign forward_in[2].uop_loadWaitStrict = io_forward_2_uop_loadWaitStrict;
  assign forward_in[2].uop_sqIdx_flag = io_forward_2_uop_sqIdx_flag;
  assign forward_in[2].uop_sqIdx_value = io_forward_2_uop_sqIdx_value;
  assign forward_in[2].valid = io_forward_2_valid;
  assign forward_in[2].sqIdx_flag = io_forward_2_sqIdx_flag;
  assign forward_in[2].sqIdxMask = io_forward_2_sqIdxMask;

  sq_forward_t_out forward_out [3];
  assign io_forward_0_forwardMask_0 = forward_out[0].forwardMask_0;
  assign io_forward_0_forwardMask_1 = forward_out[0].forwardMask_1;
  assign io_forward_0_forwardMask_2 = forward_out[0].forwardMask_2;
  assign io_forward_0_forwardMask_3 = forward_out[0].forwardMask_3;
  assign io_forward_0_forwardMask_4 = forward_out[0].forwardMask_4;
  assign io_forward_0_forwardMask_5 = forward_out[0].forwardMask_5;
  assign io_forward_0_forwardMask_6 = forward_out[0].forwardMask_6;
  assign io_forward_0_forwardMask_7 = forward_out[0].forwardMask_7;
  assign io_forward_0_forwardMask_8 = forward_out[0].forwardMask_8;
  assign io_forward_0_forwardMask_9 = forward_out[0].forwardMask_9;
  assign io_forward_0_forwardMask_10 = forward_out[0].forwardMask_10;
  assign io_forward_0_forwardMask_11 = forward_out[0].forwardMask_11;
  assign io_forward_0_forwardMask_12 = forward_out[0].forwardMask_12;
  assign io_forward_0_forwardMask_13 = forward_out[0].forwardMask_13;
  assign io_forward_0_forwardMask_14 = forward_out[0].forwardMask_14;
  assign io_forward_0_forwardMask_15 = forward_out[0].forwardMask_15;
  assign io_forward_0_forwardData_0 = forward_out[0].forwardData_0;
  assign io_forward_0_forwardData_1 = forward_out[0].forwardData_1;
  assign io_forward_0_forwardData_2 = forward_out[0].forwardData_2;
  assign io_forward_0_forwardData_3 = forward_out[0].forwardData_3;
  assign io_forward_0_forwardData_4 = forward_out[0].forwardData_4;
  assign io_forward_0_forwardData_5 = forward_out[0].forwardData_5;
  assign io_forward_0_forwardData_6 = forward_out[0].forwardData_6;
  assign io_forward_0_forwardData_7 = forward_out[0].forwardData_7;
  assign io_forward_0_forwardData_8 = forward_out[0].forwardData_8;
  assign io_forward_0_forwardData_9 = forward_out[0].forwardData_9;
  assign io_forward_0_forwardData_10 = forward_out[0].forwardData_10;
  assign io_forward_0_forwardData_11 = forward_out[0].forwardData_11;
  assign io_forward_0_forwardData_12 = forward_out[0].forwardData_12;
  assign io_forward_0_forwardData_13 = forward_out[0].forwardData_13;
  assign io_forward_0_forwardData_14 = forward_out[0].forwardData_14;
  assign io_forward_0_forwardData_15 = forward_out[0].forwardData_15;
  assign io_forward_0_dataInvalid = forward_out[0].dataInvalid;
  assign io_forward_0_matchInvalid = forward_out[0].matchInvalid;
  assign io_forward_0_addrInvalid = forward_out[0].addrInvalid;
  assign io_forward_0_dataInvalidSqIdx_flag = forward_out[0].dataInvalidSqIdx_flag;
  assign io_forward_0_dataInvalidSqIdx_value = forward_out[0].dataInvalidSqIdx_value;
  assign io_forward_0_addrInvalidSqIdx_flag = forward_out[0].addrInvalidSqIdx_flag;
  assign io_forward_0_addrInvalidSqIdx_value = forward_out[0].addrInvalidSqIdx_value;
  assign io_forward_1_forwardMask_0 = forward_out[1].forwardMask_0;
  assign io_forward_1_forwardMask_1 = forward_out[1].forwardMask_1;
  assign io_forward_1_forwardMask_2 = forward_out[1].forwardMask_2;
  assign io_forward_1_forwardMask_3 = forward_out[1].forwardMask_3;
  assign io_forward_1_forwardMask_4 = forward_out[1].forwardMask_4;
  assign io_forward_1_forwardMask_5 = forward_out[1].forwardMask_5;
  assign io_forward_1_forwardMask_6 = forward_out[1].forwardMask_6;
  assign io_forward_1_forwardMask_7 = forward_out[1].forwardMask_7;
  assign io_forward_1_forwardMask_8 = forward_out[1].forwardMask_8;
  assign io_forward_1_forwardMask_9 = forward_out[1].forwardMask_9;
  assign io_forward_1_forwardMask_10 = forward_out[1].forwardMask_10;
  assign io_forward_1_forwardMask_11 = forward_out[1].forwardMask_11;
  assign io_forward_1_forwardMask_12 = forward_out[1].forwardMask_12;
  assign io_forward_1_forwardMask_13 = forward_out[1].forwardMask_13;
  assign io_forward_1_forwardMask_14 = forward_out[1].forwardMask_14;
  assign io_forward_1_forwardMask_15 = forward_out[1].forwardMask_15;
  assign io_forward_1_forwardData_0 = forward_out[1].forwardData_0;
  assign io_forward_1_forwardData_1 = forward_out[1].forwardData_1;
  assign io_forward_1_forwardData_2 = forward_out[1].forwardData_2;
  assign io_forward_1_forwardData_3 = forward_out[1].forwardData_3;
  assign io_forward_1_forwardData_4 = forward_out[1].forwardData_4;
  assign io_forward_1_forwardData_5 = forward_out[1].forwardData_5;
  assign io_forward_1_forwardData_6 = forward_out[1].forwardData_6;
  assign io_forward_1_forwardData_7 = forward_out[1].forwardData_7;
  assign io_forward_1_forwardData_8 = forward_out[1].forwardData_8;
  assign io_forward_1_forwardData_9 = forward_out[1].forwardData_9;
  assign io_forward_1_forwardData_10 = forward_out[1].forwardData_10;
  assign io_forward_1_forwardData_11 = forward_out[1].forwardData_11;
  assign io_forward_1_forwardData_12 = forward_out[1].forwardData_12;
  assign io_forward_1_forwardData_13 = forward_out[1].forwardData_13;
  assign io_forward_1_forwardData_14 = forward_out[1].forwardData_14;
  assign io_forward_1_forwardData_15 = forward_out[1].forwardData_15;
  assign io_forward_1_dataInvalid = forward_out[1].dataInvalid;
  assign io_forward_1_matchInvalid = forward_out[1].matchInvalid;
  assign io_forward_1_addrInvalid = forward_out[1].addrInvalid;
  assign io_forward_1_dataInvalidSqIdx_flag = forward_out[1].dataInvalidSqIdx_flag;
  assign io_forward_1_dataInvalidSqIdx_value = forward_out[1].dataInvalidSqIdx_value;
  assign io_forward_1_addrInvalidSqIdx_flag = forward_out[1].addrInvalidSqIdx_flag;
  assign io_forward_1_addrInvalidSqIdx_value = forward_out[1].addrInvalidSqIdx_value;
  assign io_forward_2_forwardMask_0 = forward_out[2].forwardMask_0;
  assign io_forward_2_forwardMask_1 = forward_out[2].forwardMask_1;
  assign io_forward_2_forwardMask_2 = forward_out[2].forwardMask_2;
  assign io_forward_2_forwardMask_3 = forward_out[2].forwardMask_3;
  assign io_forward_2_forwardMask_4 = forward_out[2].forwardMask_4;
  assign io_forward_2_forwardMask_5 = forward_out[2].forwardMask_5;
  assign io_forward_2_forwardMask_6 = forward_out[2].forwardMask_6;
  assign io_forward_2_forwardMask_7 = forward_out[2].forwardMask_7;
  assign io_forward_2_forwardMask_8 = forward_out[2].forwardMask_8;
  assign io_forward_2_forwardMask_9 = forward_out[2].forwardMask_9;
  assign io_forward_2_forwardMask_10 = forward_out[2].forwardMask_10;
  assign io_forward_2_forwardMask_11 = forward_out[2].forwardMask_11;
  assign io_forward_2_forwardMask_12 = forward_out[2].forwardMask_12;
  assign io_forward_2_forwardMask_13 = forward_out[2].forwardMask_13;
  assign io_forward_2_forwardMask_14 = forward_out[2].forwardMask_14;
  assign io_forward_2_forwardMask_15 = forward_out[2].forwardMask_15;
  assign io_forward_2_forwardData_0 = forward_out[2].forwardData_0;
  assign io_forward_2_forwardData_1 = forward_out[2].forwardData_1;
  assign io_forward_2_forwardData_2 = forward_out[2].forwardData_2;
  assign io_forward_2_forwardData_3 = forward_out[2].forwardData_3;
  assign io_forward_2_forwardData_4 = forward_out[2].forwardData_4;
  assign io_forward_2_forwardData_5 = forward_out[2].forwardData_5;
  assign io_forward_2_forwardData_6 = forward_out[2].forwardData_6;
  assign io_forward_2_forwardData_7 = forward_out[2].forwardData_7;
  assign io_forward_2_forwardData_8 = forward_out[2].forwardData_8;
  assign io_forward_2_forwardData_9 = forward_out[2].forwardData_9;
  assign io_forward_2_forwardData_10 = forward_out[2].forwardData_10;
  assign io_forward_2_forwardData_11 = forward_out[2].forwardData_11;
  assign io_forward_2_forwardData_12 = forward_out[2].forwardData_12;
  assign io_forward_2_forwardData_13 = forward_out[2].forwardData_13;
  assign io_forward_2_forwardData_14 = forward_out[2].forwardData_14;
  assign io_forward_2_forwardData_15 = forward_out[2].forwardData_15;
  assign io_forward_2_dataInvalid = forward_out[2].dataInvalid;
  assign io_forward_2_matchInvalid = forward_out[2].matchInvalid;
  assign io_forward_2_addrInvalid = forward_out[2].addrInvalid;
  assign io_forward_2_dataInvalidSqIdx_flag = forward_out[2].dataInvalidSqIdx_flag;
  assign io_forward_2_dataInvalidSqIdx_value = forward_out[2].dataInvalidSqIdx_value;
  assign io_forward_2_addrInvalidSqIdx_flag = forward_out[2].addrInvalidSqIdx_flag;
  assign io_forward_2_addrInvalidSqIdx_value = forward_out[2].addrInvalidSqIdx_value;

  sq_sbuffer_t_in sbuffer_in [2];
  assign sbuffer_in[0].ready = io_sbuffer_0_ready;
  assign sbuffer_in[1].ready = io_sbuffer_1_ready;

  sq_sbuffer_t_out sbuffer_out [2];
  assign io_sbuffer_0_valid = sbuffer_out[0].valid;
  assign io_sbuffer_0_bits_vaddr = sbuffer_out[0].bits_vaddr;
  assign io_sbuffer_0_bits_data = sbuffer_out[0].bits_data;
  assign io_sbuffer_0_bits_mask = sbuffer_out[0].bits_mask;
  assign io_sbuffer_0_bits_addr = sbuffer_out[0].bits_addr;
  assign io_sbuffer_0_bits_wline = sbuffer_out[0].bits_wline;
  assign io_sbuffer_0_bits_vecValid = sbuffer_out[0].bits_vecValid;
  assign io_sbuffer_1_valid = sbuffer_out[1].valid;
  assign io_sbuffer_1_bits_vaddr = sbuffer_out[1].bits_vaddr;
  assign io_sbuffer_1_bits_data = sbuffer_out[1].bits_data;
  assign io_sbuffer_1_bits_mask = sbuffer_out[1].bits_mask;
  assign io_sbuffer_1_bits_addr = sbuffer_out[1].bits_addr;
  assign io_sbuffer_1_bits_wline = sbuffer_out[1].bits_wline;
  assign io_sbuffer_1_bits_vecValid = sbuffer_out[1].bits_vecValid;

  sq_vecFeedback_t_in vecFeedback_in [2];
  assign vecFeedback_in[0].valid = io_vecFeedback_0_valid;
  assign vecFeedback_in[0].bits_robidx_flag = io_vecFeedback_0_bits_robidx_flag;
  assign vecFeedback_in[0].bits_robidx_value = io_vecFeedback_0_bits_robidx_value;
  assign vecFeedback_in[0].bits_uopidx = io_vecFeedback_0_bits_uopidx;
  assign vecFeedback_in[0].bits_vaddr = io_vecFeedback_0_bits_vaddr;
  assign vecFeedback_in[0].bits_vaNeedExt = io_vecFeedback_0_bits_vaNeedExt;
  assign vecFeedback_in[0].bits_gpaddr = io_vecFeedback_0_bits_gpaddr;
  assign vecFeedback_in[0].bits_isForVSnonLeafPTE = io_vecFeedback_0_bits_isForVSnonLeafPTE;
  assign vecFeedback_in[0].bits_feedback_0 = io_vecFeedback_0_bits_feedback_0;
  assign vecFeedback_in[0].bits_feedback_1 = io_vecFeedback_0_bits_feedback_1;
  assign vecFeedback_in[0].bits_exceptionVec_3 = io_vecFeedback_0_bits_exceptionVec_3;
  assign vecFeedback_in[0].bits_exceptionVec_6 = io_vecFeedback_0_bits_exceptionVec_6;
  assign vecFeedback_in[0].bits_exceptionVec_7 = io_vecFeedback_0_bits_exceptionVec_7;
  assign vecFeedback_in[0].bits_exceptionVec_15 = io_vecFeedback_0_bits_exceptionVec_15;
  assign vecFeedback_in[0].bits_exceptionVec_19 = io_vecFeedback_0_bits_exceptionVec_19;
  assign vecFeedback_in[0].bits_exceptionVec_23 = io_vecFeedback_0_bits_exceptionVec_23;
  assign vecFeedback_in[1].valid = io_vecFeedback_1_valid;
  assign vecFeedback_in[1].bits_robidx_flag = io_vecFeedback_1_bits_robidx_flag;
  assign vecFeedback_in[1].bits_robidx_value = io_vecFeedback_1_bits_robidx_value;
  assign vecFeedback_in[1].bits_uopidx = io_vecFeedback_1_bits_uopidx;
  assign vecFeedback_in[1].bits_vaddr = io_vecFeedback_1_bits_vaddr;
  assign vecFeedback_in[1].bits_vaNeedExt = io_vecFeedback_1_bits_vaNeedExt;
  assign vecFeedback_in[1].bits_gpaddr = io_vecFeedback_1_bits_gpaddr;
  assign vecFeedback_in[1].bits_isForVSnonLeafPTE = io_vecFeedback_1_bits_isForVSnonLeafPTE;
  assign vecFeedback_in[1].bits_feedback_0 = io_vecFeedback_1_bits_feedback_0;
  assign vecFeedback_in[1].bits_feedback_1 = io_vecFeedback_1_bits_feedback_1;
  assign vecFeedback_in[1].bits_exceptionVec_3 = io_vecFeedback_1_bits_exceptionVec_3;
  assign vecFeedback_in[1].bits_exceptionVec_6 = io_vecFeedback_1_bits_exceptionVec_6;
  assign vecFeedback_in[1].bits_exceptionVec_7 = io_vecFeedback_1_bits_exceptionVec_7;
  assign vecFeedback_in[1].bits_exceptionVec_15 = io_vecFeedback_1_bits_exceptionVec_15;
  assign vecFeedback_in[1].bits_exceptionVec_19 = io_vecFeedback_1_bits_exceptionVec_19;
  assign vecFeedback_in[1].bits_exceptionVec_23 = io_vecFeedback_1_bits_exceptionVec_23;

  sq_perf_t_out perf_out [8];
  assign io_perf_0_value = perf_out[0].value;
  assign io_perf_1_value = perf_out[1].value;
  assign io_perf_2_value = perf_out[2].value;
  assign io_perf_3_value = perf_out[3].value;
  assign io_perf_4_value = perf_out[4].value;
  assign io_perf_5_value = perf_out[5].value;
  assign io_perf_6_value = perf_out[6].value;
  assign io_perf_7_value = perf_out[7].value;

  sq_diffStore_diffInfo_t_out diffStore_diffInfo_out [2];
  assign io_diffStore_diffInfo_0_uop_fuType = diffStore_diffInfo_out[0].uop_fuType;
  assign io_diffStore_diffInfo_0_uop_fuOpType = diffStore_diffInfo_out[0].uop_fuOpType;
  assign io_diffStore_diffInfo_0_uop_vpu_nf = diffStore_diffInfo_out[0].uop_vpu_nf;
  assign io_diffStore_diffInfo_0_uop_vpu_veew = diffStore_diffInfo_out[0].uop_vpu_veew;
  assign io_diffStore_diffInfo_0_uop_robIdx_value = diffStore_diffInfo_out[0].uop_robIdx_value;
  assign io_diffStore_diffInfo_0_offset = diffStore_diffInfo_out[0].offset;
  assign io_diffStore_diffInfo_1_uop_fuType = diffStore_diffInfo_out[1].uop_fuType;
  assign io_diffStore_diffInfo_1_uop_fuOpType = diffStore_diffInfo_out[1].uop_fuOpType;
  assign io_diffStore_diffInfo_1_uop_vpu_nf = diffStore_diffInfo_out[1].uop_vpu_nf;
  assign io_diffStore_diffInfo_1_uop_vpu_veew = diffStore_diffInfo_out[1].uop_vpu_veew;
  assign io_diffStore_diffInfo_1_uop_robIdx_value = diffStore_diffInfo_out[1].uop_robIdx_value;
  assign io_diffStore_diffInfo_1_offset = diffStore_diffInfo_out[1].offset;

  sq_diffStore_pmaStore_t_out diffStore_pmaStore_out [2];
  assign io_diffStore_pmaStore_0_valid = diffStore_pmaStore_out[0].valid;
  assign io_diffStore_pmaStore_0_bits_data = diffStore_pmaStore_out[0].bits_data;
  assign io_diffStore_pmaStore_0_bits_mask = diffStore_pmaStore_out[0].bits_mask;
  assign io_diffStore_pmaStore_0_bits_addr = diffStore_pmaStore_out[0].bits_addr;
  assign io_diffStore_pmaStore_0_bits_wline = diffStore_pmaStore_out[0].bits_wline;
  assign io_diffStore_pmaStore_0_bits_vecValid = diffStore_pmaStore_out[0].bits_vecValid;
  assign io_diffStore_pmaStore_1_valid = diffStore_pmaStore_out[1].valid;
  assign io_diffStore_pmaStore_1_bits_data = diffStore_pmaStore_out[1].bits_data;
  assign io_diffStore_pmaStore_1_bits_mask = diffStore_pmaStore_out[1].bits_mask;
  assign io_diffStore_pmaStore_1_bits_addr = diffStore_pmaStore_out[1].bits_addr;
  assign io_diffStore_pmaStore_1_bits_wline = diffStore_pmaStore_out[1].bits_wline;
  assign io_diffStore_pmaStore_1_bits_vecValid = diffStore_pmaStore_out[1].bits_vecValid;

  xs_StoreQueue_core u_core (
    .clock(clock),
    .reset(reset),
    .enq_req_in(enq_req_in),
    .storeAddrIn_in(storeAddrIn_in),
    .storeAddrInRe_in(storeAddrInRe_in),
    .storeDataIn_in(storeDataIn_in),
    .storeMaskIn_in(storeMaskIn_in),
    .forward_in(forward_in),
    .forward_out(forward_out),
    .sbuffer_in(sbuffer_in),
    .sbuffer_out(sbuffer_out),
    .vecFeedback_in(vecFeedback_in),
    .perf_out(perf_out),
    .diffStore_diffInfo_out(diffStore_diffInfo_out),
    .diffStore_pmaStore_out(diffStore_pmaStore_out),
    .io_hartId(io_hartId),
    .io_enq_canAccept(io_enq_canAccept),
    .io_enq_lqCanAccept(io_enq_lqCanAccept),
    .io_enq_needAlloc_0(io_enq_needAlloc_0),
    .io_enq_needAlloc_1(io_enq_needAlloc_1),
    .io_enq_needAlloc_2(io_enq_needAlloc_2),
    .io_enq_needAlloc_3(io_enq_needAlloc_3),
    .io_enq_needAlloc_4(io_enq_needAlloc_4),
    .io_brqRedirect_valid(io_brqRedirect_valid),
    .io_brqRedirect_bits_robIdx_flag(io_brqRedirect_bits_robIdx_flag),
    .io_brqRedirect_bits_robIdx_value(io_brqRedirect_bits_robIdx_value),
    .io_brqRedirect_bits_level(io_brqRedirect_bits_level),
    .io_uncacheOutstanding(io_uncacheOutstanding),
    .io_cmoOpReq_ready(io_cmoOpReq_ready),
    .io_cmoOpReq_valid(io_cmoOpReq_valid),
    .io_cmoOpReq_bits_opcode(io_cmoOpReq_bits_opcode),
    .io_cmoOpReq_bits_address(io_cmoOpReq_bits_address),
    .io_cmoOpResp_ready(io_cmoOpResp_ready),
    .io_cmoOpResp_valid(io_cmoOpResp_valid),
    .io_cmoOpResp_bits_denied(io_cmoOpResp_bits_denied),
    .io_cmoOpResp_bits_corrupt(io_cmoOpResp_bits_corrupt),
    .io_cboZeroStout_ready(io_cboZeroStout_ready),
    .io_cboZeroStout_valid(io_cboZeroStout_valid),
    .io_cboZeroStout_bits_uop_exceptionVec_0(io_cboZeroStout_bits_uop_exceptionVec_0),
    .io_cboZeroStout_bits_uop_exceptionVec_1(io_cboZeroStout_bits_uop_exceptionVec_1),
    .io_cboZeroStout_bits_uop_exceptionVec_2(io_cboZeroStout_bits_uop_exceptionVec_2),
    .io_cboZeroStout_bits_uop_exceptionVec_3(io_cboZeroStout_bits_uop_exceptionVec_3),
    .io_cboZeroStout_bits_uop_exceptionVec_4(io_cboZeroStout_bits_uop_exceptionVec_4),
    .io_cboZeroStout_bits_uop_exceptionVec_5(io_cboZeroStout_bits_uop_exceptionVec_5),
    .io_cboZeroStout_bits_uop_exceptionVec_6(io_cboZeroStout_bits_uop_exceptionVec_6),
    .io_cboZeroStout_bits_uop_exceptionVec_7(io_cboZeroStout_bits_uop_exceptionVec_7),
    .io_cboZeroStout_bits_uop_exceptionVec_8(io_cboZeroStout_bits_uop_exceptionVec_8),
    .io_cboZeroStout_bits_uop_exceptionVec_9(io_cboZeroStout_bits_uop_exceptionVec_9),
    .io_cboZeroStout_bits_uop_exceptionVec_10(io_cboZeroStout_bits_uop_exceptionVec_10),
    .io_cboZeroStout_bits_uop_exceptionVec_11(io_cboZeroStout_bits_uop_exceptionVec_11),
    .io_cboZeroStout_bits_uop_exceptionVec_12(io_cboZeroStout_bits_uop_exceptionVec_12),
    .io_cboZeroStout_bits_uop_exceptionVec_13(io_cboZeroStout_bits_uop_exceptionVec_13),
    .io_cboZeroStout_bits_uop_exceptionVec_14(io_cboZeroStout_bits_uop_exceptionVec_14),
    .io_cboZeroStout_bits_uop_exceptionVec_15(io_cboZeroStout_bits_uop_exceptionVec_15),
    .io_cboZeroStout_bits_uop_exceptionVec_16(io_cboZeroStout_bits_uop_exceptionVec_16),
    .io_cboZeroStout_bits_uop_exceptionVec_17(io_cboZeroStout_bits_uop_exceptionVec_17),
    .io_cboZeroStout_bits_uop_exceptionVec_18(io_cboZeroStout_bits_uop_exceptionVec_18),
    .io_cboZeroStout_bits_uop_exceptionVec_19(io_cboZeroStout_bits_uop_exceptionVec_19),
    .io_cboZeroStout_bits_uop_exceptionVec_20(io_cboZeroStout_bits_uop_exceptionVec_20),
    .io_cboZeroStout_bits_uop_exceptionVec_21(io_cboZeroStout_bits_uop_exceptionVec_21),
    .io_cboZeroStout_bits_uop_exceptionVec_22(io_cboZeroStout_bits_uop_exceptionVec_22),
    .io_cboZeroStout_bits_uop_exceptionVec_23(io_cboZeroStout_bits_uop_exceptionVec_23),
    .io_cboZeroStout_bits_uop_trigger(io_cboZeroStout_bits_uop_trigger),
    .io_cboZeroStout_bits_uop_rfWen(io_cboZeroStout_bits_uop_rfWen),
    .io_cboZeroStout_bits_uop_flushPipe(io_cboZeroStout_bits_uop_flushPipe),
    .io_cboZeroStout_bits_uop_pdest(io_cboZeroStout_bits_uop_pdest),
    .io_cboZeroStout_bits_uop_robIdx_flag(io_cboZeroStout_bits_uop_robIdx_flag),
    .io_cboZeroStout_bits_uop_robIdx_value(io_cboZeroStout_bits_uop_robIdx_value),
    .io_cboZeroStout_bits_uop_debugInfo_eliminatedMove(io_cboZeroStout_bits_uop_debugInfo_eliminatedMove),
    .io_cboZeroStout_bits_uop_debugInfo_renameTime(io_cboZeroStout_bits_uop_debugInfo_renameTime),
    .io_cboZeroStout_bits_uop_debugInfo_dispatchTime(io_cboZeroStout_bits_uop_debugInfo_dispatchTime),
    .io_cboZeroStout_bits_uop_debugInfo_enqRsTime(io_cboZeroStout_bits_uop_debugInfo_enqRsTime),
    .io_cboZeroStout_bits_uop_debugInfo_selectTime(io_cboZeroStout_bits_uop_debugInfo_selectTime),
    .io_cboZeroStout_bits_uop_debugInfo_issueTime(io_cboZeroStout_bits_uop_debugInfo_issueTime),
    .io_cboZeroStout_bits_uop_debugInfo_writebackTime(io_cboZeroStout_bits_uop_debugInfo_writebackTime),
    .io_cboZeroStout_bits_uop_debugInfo_runahead_checkpoint_id(io_cboZeroStout_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_cboZeroStout_bits_uop_debugInfo_tlbFirstReqTime(io_cboZeroStout_bits_uop_debugInfo_tlbFirstReqTime),
    .io_cboZeroStout_bits_uop_debugInfo_tlbRespTime(io_cboZeroStout_bits_uop_debugInfo_tlbRespTime),
    .io_cboZeroStout_bits_uop_debug_seqNum_seqNum(io_cboZeroStout_bits_uop_debug_seqNum_seqNum),
    .io_cboZeroStout_bits_uop_debug_seqNum_uopIdx(io_cboZeroStout_bits_uop_debug_seqNum_uopIdx),
    .io_cboZeroStout_bits_uop_sqIdx_flag(io_cboZeroStout_bits_uop_sqIdx_flag),
    .io_cboZeroStout_bits_uop_sqIdx_value(io_cboZeroStout_bits_uop_sqIdx_value),
    .io_mmioStout_ready(io_mmioStout_ready),
    .io_mmioStout_valid(io_mmioStout_valid),
    .io_mmioStout_bits_uop_exceptionVec_7(io_mmioStout_bits_uop_exceptionVec_7),
    .io_mmioStout_bits_uop_exceptionVec_19(io_mmioStout_bits_uop_exceptionVec_19),
    .io_mmioStout_bits_uop_rfWen(io_mmioStout_bits_uop_rfWen),
    .io_mmioStout_bits_uop_flushPipe(io_mmioStout_bits_uop_flushPipe),
    .io_mmioStout_bits_uop_pdest(io_mmioStout_bits_uop_pdest),
    .io_mmioStout_bits_uop_robIdx_flag(io_mmioStout_bits_uop_robIdx_flag),
    .io_mmioStout_bits_uop_robIdx_value(io_mmioStout_bits_uop_robIdx_value),
    .io_mmioStout_bits_uop_debugInfo_eliminatedMove(io_mmioStout_bits_uop_debugInfo_eliminatedMove),
    .io_mmioStout_bits_uop_debugInfo_renameTime(io_mmioStout_bits_uop_debugInfo_renameTime),
    .io_mmioStout_bits_uop_debugInfo_dispatchTime(io_mmioStout_bits_uop_debugInfo_dispatchTime),
    .io_mmioStout_bits_uop_debugInfo_enqRsTime(io_mmioStout_bits_uop_debugInfo_enqRsTime),
    .io_mmioStout_bits_uop_debugInfo_selectTime(io_mmioStout_bits_uop_debugInfo_selectTime),
    .io_mmioStout_bits_uop_debugInfo_issueTime(io_mmioStout_bits_uop_debugInfo_issueTime),
    .io_mmioStout_bits_uop_debugInfo_writebackTime(io_mmioStout_bits_uop_debugInfo_writebackTime),
    .io_mmioStout_bits_uop_debugInfo_runahead_checkpoint_id(io_mmioStout_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_mmioStout_bits_uop_debugInfo_tlbFirstReqTime(io_mmioStout_bits_uop_debugInfo_tlbFirstReqTime),
    .io_mmioStout_bits_uop_debugInfo_tlbRespTime(io_mmioStout_bits_uop_debugInfo_tlbRespTime),
    .io_mmioStout_bits_uop_debug_seqNum_seqNum(io_mmioStout_bits_uop_debug_seqNum_seqNum),
    .io_mmioStout_bits_uop_debug_seqNum_uopIdx(io_mmioStout_bits_uop_debug_seqNum_uopIdx),
    .io_mmioStout_bits_uop_sqIdx_flag(io_mmioStout_bits_uop_sqIdx_flag),
    .io_mmioStout_bits_uop_sqIdx_value(io_mmioStout_bits_uop_sqIdx_value),
    .io_mmioStout_bits_data(io_mmioStout_bits_data),
    .io_mmioStout_bits_debug_isMMIO(io_mmioStout_bits_debug_isMMIO),
    .io_rob_scommit(io_rob_scommit),
    .io_rob_pendingst(io_rob_pendingst),
    .io_rob_pendingPtr_flag(io_rob_pendingPtr_flag),
    .io_rob_pendingPtr_value(io_rob_pendingPtr_value),
    .io_rob_storeMmio(io_rob_storeMmio),
    .io_rob_storeMmioUop_robIdx_value(io_rob_storeMmioUop_robIdx_value),
    .io_uncache_req_ready(io_uncache_req_ready),
    .io_uncache_req_valid(io_uncache_req_valid),
    .io_uncache_req_bits_robIdx_flag(io_uncache_req_bits_robIdx_flag),
    .io_uncache_req_bits_robIdx_value(io_uncache_req_bits_robIdx_value),
    .io_uncache_req_bits_addr(io_uncache_req_bits_addr),
    .io_uncache_req_bits_vaddr(io_uncache_req_bits_vaddr),
    .io_uncache_req_bits_data(io_uncache_req_bits_data),
    .io_uncache_req_bits_mask(io_uncache_req_bits_mask),
    .io_uncache_req_bits_id(io_uncache_req_bits_id),
    .io_uncache_req_bits_nc(io_uncache_req_bits_nc),
    .io_uncache_req_bits_memBackTypeMM(io_uncache_req_bits_memBackTypeMM),
    .io_uncache_idResp_valid(io_uncache_idResp_valid),
    .io_uncache_idResp_bits_mid(io_uncache_idResp_bits_mid),
    .io_uncache_idResp_bits_nc(io_uncache_idResp_bits_nc),
    .io_uncache_resp_valid(io_uncache_resp_valid),
    .io_uncache_resp_bits_nc(io_uncache_resp_bits_nc),
    .io_uncache_resp_bits_denied(io_uncache_resp_bits_denied),
    .io_uncache_resp_bits_corrupt(io_uncache_resp_bits_corrupt),
    .io_exceptionAddr_vaddr(io_exceptionAddr_vaddr),
    .io_exceptionAddr_vaNeedExt(io_exceptionAddr_vaNeedExt),
    .io_exceptionAddr_isHyper(io_exceptionAddr_isHyper),
    .io_exceptionAddr_gpaddr(io_exceptionAddr_gpaddr),
    .io_exceptionAddr_isForVSnonLeafPTE(io_exceptionAddr_isForVSnonLeafPTE),
    .io_flushSbuffer_valid(io_flushSbuffer_valid),
    .io_flushSbuffer_empty(io_flushSbuffer_empty),
    .io_sqEmpty(io_sqEmpty),
    .io_stAddrReadySqPtr_flag(io_stAddrReadySqPtr_flag),
    .io_stAddrReadySqPtr_value(io_stAddrReadySqPtr_value),
    .io_stAddrReadyVec_0(io_stAddrReadyVec_0),
    .io_stAddrReadyVec_1(io_stAddrReadyVec_1),
    .io_stAddrReadyVec_2(io_stAddrReadyVec_2),
    .io_stAddrReadyVec_3(io_stAddrReadyVec_3),
    .io_stAddrReadyVec_4(io_stAddrReadyVec_4),
    .io_stAddrReadyVec_5(io_stAddrReadyVec_5),
    .io_stAddrReadyVec_6(io_stAddrReadyVec_6),
    .io_stAddrReadyVec_7(io_stAddrReadyVec_7),
    .io_stAddrReadyVec_8(io_stAddrReadyVec_8),
    .io_stAddrReadyVec_9(io_stAddrReadyVec_9),
    .io_stAddrReadyVec_10(io_stAddrReadyVec_10),
    .io_stAddrReadyVec_11(io_stAddrReadyVec_11),
    .io_stAddrReadyVec_12(io_stAddrReadyVec_12),
    .io_stAddrReadyVec_13(io_stAddrReadyVec_13),
    .io_stAddrReadyVec_14(io_stAddrReadyVec_14),
    .io_stAddrReadyVec_15(io_stAddrReadyVec_15),
    .io_stAddrReadyVec_16(io_stAddrReadyVec_16),
    .io_stAddrReadyVec_17(io_stAddrReadyVec_17),
    .io_stAddrReadyVec_18(io_stAddrReadyVec_18),
    .io_stAddrReadyVec_19(io_stAddrReadyVec_19),
    .io_stAddrReadyVec_20(io_stAddrReadyVec_20),
    .io_stAddrReadyVec_21(io_stAddrReadyVec_21),
    .io_stAddrReadyVec_22(io_stAddrReadyVec_22),
    .io_stAddrReadyVec_23(io_stAddrReadyVec_23),
    .io_stAddrReadyVec_24(io_stAddrReadyVec_24),
    .io_stAddrReadyVec_25(io_stAddrReadyVec_25),
    .io_stAddrReadyVec_26(io_stAddrReadyVec_26),
    .io_stAddrReadyVec_27(io_stAddrReadyVec_27),
    .io_stAddrReadyVec_28(io_stAddrReadyVec_28),
    .io_stAddrReadyVec_29(io_stAddrReadyVec_29),
    .io_stAddrReadyVec_30(io_stAddrReadyVec_30),
    .io_stAddrReadyVec_31(io_stAddrReadyVec_31),
    .io_stAddrReadyVec_32(io_stAddrReadyVec_32),
    .io_stAddrReadyVec_33(io_stAddrReadyVec_33),
    .io_stAddrReadyVec_34(io_stAddrReadyVec_34),
    .io_stAddrReadyVec_35(io_stAddrReadyVec_35),
    .io_stAddrReadyVec_36(io_stAddrReadyVec_36),
    .io_stAddrReadyVec_37(io_stAddrReadyVec_37),
    .io_stAddrReadyVec_38(io_stAddrReadyVec_38),
    .io_stAddrReadyVec_39(io_stAddrReadyVec_39),
    .io_stAddrReadyVec_40(io_stAddrReadyVec_40),
    .io_stAddrReadyVec_41(io_stAddrReadyVec_41),
    .io_stAddrReadyVec_42(io_stAddrReadyVec_42),
    .io_stAddrReadyVec_43(io_stAddrReadyVec_43),
    .io_stAddrReadyVec_44(io_stAddrReadyVec_44),
    .io_stAddrReadyVec_45(io_stAddrReadyVec_45),
    .io_stAddrReadyVec_46(io_stAddrReadyVec_46),
    .io_stAddrReadyVec_47(io_stAddrReadyVec_47),
    .io_stAddrReadyVec_48(io_stAddrReadyVec_48),
    .io_stAddrReadyVec_49(io_stAddrReadyVec_49),
    .io_stAddrReadyVec_50(io_stAddrReadyVec_50),
    .io_stAddrReadyVec_51(io_stAddrReadyVec_51),
    .io_stAddrReadyVec_52(io_stAddrReadyVec_52),
    .io_stAddrReadyVec_53(io_stAddrReadyVec_53),
    .io_stAddrReadyVec_54(io_stAddrReadyVec_54),
    .io_stAddrReadyVec_55(io_stAddrReadyVec_55),
    .io_stDataReadySqPtr_flag(io_stDataReadySqPtr_flag),
    .io_stDataReadySqPtr_value(io_stDataReadySqPtr_value),
    .io_stDataReadyVec_0(io_stDataReadyVec_0),
    .io_stDataReadyVec_1(io_stDataReadyVec_1),
    .io_stDataReadyVec_2(io_stDataReadyVec_2),
    .io_stDataReadyVec_3(io_stDataReadyVec_3),
    .io_stDataReadyVec_4(io_stDataReadyVec_4),
    .io_stDataReadyVec_5(io_stDataReadyVec_5),
    .io_stDataReadyVec_6(io_stDataReadyVec_6),
    .io_stDataReadyVec_7(io_stDataReadyVec_7),
    .io_stDataReadyVec_8(io_stDataReadyVec_8),
    .io_stDataReadyVec_9(io_stDataReadyVec_9),
    .io_stDataReadyVec_10(io_stDataReadyVec_10),
    .io_stDataReadyVec_11(io_stDataReadyVec_11),
    .io_stDataReadyVec_12(io_stDataReadyVec_12),
    .io_stDataReadyVec_13(io_stDataReadyVec_13),
    .io_stDataReadyVec_14(io_stDataReadyVec_14),
    .io_stDataReadyVec_15(io_stDataReadyVec_15),
    .io_stDataReadyVec_16(io_stDataReadyVec_16),
    .io_stDataReadyVec_17(io_stDataReadyVec_17),
    .io_stDataReadyVec_18(io_stDataReadyVec_18),
    .io_stDataReadyVec_19(io_stDataReadyVec_19),
    .io_stDataReadyVec_20(io_stDataReadyVec_20),
    .io_stDataReadyVec_21(io_stDataReadyVec_21),
    .io_stDataReadyVec_22(io_stDataReadyVec_22),
    .io_stDataReadyVec_23(io_stDataReadyVec_23),
    .io_stDataReadyVec_24(io_stDataReadyVec_24),
    .io_stDataReadyVec_25(io_stDataReadyVec_25),
    .io_stDataReadyVec_26(io_stDataReadyVec_26),
    .io_stDataReadyVec_27(io_stDataReadyVec_27),
    .io_stDataReadyVec_28(io_stDataReadyVec_28),
    .io_stDataReadyVec_29(io_stDataReadyVec_29),
    .io_stDataReadyVec_30(io_stDataReadyVec_30),
    .io_stDataReadyVec_31(io_stDataReadyVec_31),
    .io_stDataReadyVec_32(io_stDataReadyVec_32),
    .io_stDataReadyVec_33(io_stDataReadyVec_33),
    .io_stDataReadyVec_34(io_stDataReadyVec_34),
    .io_stDataReadyVec_35(io_stDataReadyVec_35),
    .io_stDataReadyVec_36(io_stDataReadyVec_36),
    .io_stDataReadyVec_37(io_stDataReadyVec_37),
    .io_stDataReadyVec_38(io_stDataReadyVec_38),
    .io_stDataReadyVec_39(io_stDataReadyVec_39),
    .io_stDataReadyVec_40(io_stDataReadyVec_40),
    .io_stDataReadyVec_41(io_stDataReadyVec_41),
    .io_stDataReadyVec_42(io_stDataReadyVec_42),
    .io_stDataReadyVec_43(io_stDataReadyVec_43),
    .io_stDataReadyVec_44(io_stDataReadyVec_44),
    .io_stDataReadyVec_45(io_stDataReadyVec_45),
    .io_stDataReadyVec_46(io_stDataReadyVec_46),
    .io_stDataReadyVec_47(io_stDataReadyVec_47),
    .io_stDataReadyVec_48(io_stDataReadyVec_48),
    .io_stDataReadyVec_49(io_stDataReadyVec_49),
    .io_stDataReadyVec_50(io_stDataReadyVec_50),
    .io_stDataReadyVec_51(io_stDataReadyVec_51),
    .io_stDataReadyVec_52(io_stDataReadyVec_52),
    .io_stDataReadyVec_53(io_stDataReadyVec_53),
    .io_stDataReadyVec_54(io_stDataReadyVec_54),
    .io_stDataReadyVec_55(io_stDataReadyVec_55),
    .io_stIssuePtr_flag(io_stIssuePtr_flag),
    .io_stIssuePtr_value(io_stIssuePtr_value),
    .io_sqDeqPtr_flag(io_sqDeqPtr_flag),
    .io_sqDeqPtr_value(io_sqDeqPtr_value),
    .io_sqCommitPtr_flag(io_sqCommitPtr_flag),
    .io_sqCommitPtr_value(io_sqCommitPtr_value),
    .io_sqCommitUopIdx(io_sqCommitUopIdx),
    .io_sqCommitRobIdx_flag(io_sqCommitRobIdx_flag),
    .io_sqCommitRobIdx_value(io_sqCommitRobIdx_value),
    .io_sqFull(io_sqFull),
    .io_sqCancelCnt(io_sqCancelCnt),
    .io_sqDeq(io_sqDeq),
    .io_sqDeqIsVec(io_sqDeqIsVec),
    .io_force_write(io_force_write),
    .io_maControl_toStoreQueue_crossPageWithHit(io_maControl_toStoreQueue_crossPageWithHit),
    .io_maControl_toStoreQueue_crossPageCanDeq(io_maControl_toStoreQueue_crossPageCanDeq),
    .io_maControl_toStoreQueue_paddr(io_maControl_toStoreQueue_paddr),
    .io_maControl_toStoreQueue_withSamePtr(io_maControl_toStoreQueue_withSamePtr),
    .io_maControl_toStoreMisalignBuffer_sqPtr_flag(io_maControl_toStoreMisalignBuffer_sqPtr_flag),
    .io_maControl_toStoreMisalignBuffer_sqPtr_value(io_maControl_toStoreMisalignBuffer_sqPtr_value),
    .io_maControl_toStoreMisalignBuffer_doDeq(io_maControl_toStoreMisalignBuffer_doDeq),
    .io_maControl_toStoreMisalignBuffer_uop_uopIdx(io_maControl_toStoreMisalignBuffer_uop_uopIdx),
    .io_maControl_toStoreMisalignBuffer_uop_robIdx_flag(io_maControl_toStoreMisalignBuffer_uop_robIdx_flag),
    .io_maControl_toStoreMisalignBuffer_uop_robIdx_value(io_maControl_toStoreMisalignBuffer_uop_robIdx_value),
    .io_wfi_wfiReq(io_wfi_wfiReq),
    .io_wfi_wfiSafe(io_wfi_wfiSafe),
    .io_diffStore_ncStore_valid(io_diffStore_ncStore_valid),
    .io_diffStore_ncStore_bits_addr(io_diffStore_ncStore_bits_addr),
    .io_diffStore_ncStore_bits_data(io_diffStore_ncStore_bits_data),
    .io_diffStore_ncStore_bits_mask(io_diffStore_ncStore_bits_mask),
    .io_diffStore_ncStore_bits_memBackTypeMM(io_diffStore_ncStore_bits_memBackTypeMM),
    .gatewayIn_packed_48_bore(gatewayIn_packed_48_bore)
  );

endmodule
