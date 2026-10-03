// vmergebuffer_pkg.sv — 向量访存合并缓冲（VMergeBuffer 家族）的共用包
//
// 本包被 VLMergeBufferImp.sv（参数化核 xs_VMergeBuffer_core + load 变体 wrapper）与
// VSMergeBufferImp.sv（store 变体薄 wrapper）共同 import。设计说明见 VLMergeBufferImp.sv 文件头。
//
// ★为什么单独成文件★：包若住在 VLMergeBufferImp.sv 里，编译 VSMergeBufferImp.sv 就隐含要求
// VLMergeBufferImp.sv 先编（文件顺序依赖，VCS 报 SV-LCM-PND；scripts/check_pkg_scope.py 判据 B）。
// 单独成文件后，filelist 只需把本文件放在最前。
//
// 端口 struct 区（GENERATED(structs)）由 scripts/gen_vmergebuf.py 从 G1 golden 端口表生成，勿手改。

package vmergebuffer_pkg;

  // ---- KunminghuV2Config 下的规模常量（由 golden 端口/寄存器宽度核实）----
  localparam int MB_SIZE  = 16;   // VlMergeBufferSize == VsMergeBufferSize
  localparam int MB_IDX_W = 4;    // log2(MB_SIZE)：mBIndex 宽度
  localparam int VLEN     = 128;
  localparam int VLENB    = 16;   // VLEN/8：每字节一位的 mask 宽度
  localparam int FLOW_W   = 5;    // flowIdxBits：flowNum / replayFlowNum 宽度
  localparam int ELEM_W   = 8;    // elemIdxBits：elemIdx / vstart / vl / vlmax 宽度
  localparam int ROB_W    = 8;    // robIdx.value 宽度

  // ---- ExceptionVec（24 位）与两类功能单元会产生的异常号（FuConfig.exceptionOut）----
  localparam int EXC_BREAKPOINT = 3;
  //   load : breakPoint(3) loadAddrMisaligned(4) loadAccessFault(5) loadPageFault(13)
  //          hardwareError(19) loadGuestPageFault(21)
  localparam logic [23:0] VLDU_EXC_SEL = 24'h28_2038;
  //   store: breakPoint(3) storeAddrMisaligned(6) storeAccessFault(7) storePageFault(15)
  //          hardwareError(19) storeGuestPageFault(23)
  localparam logic [23:0] VSTU_EXC_SEL = 24'h88_80C8;

  // ---- TriggerAction ----
  localparam logic [3:0] TRIGGER_BREAKPOINT_EXP = 4'd0;  // 触发断点异常
  localparam logic [3:0] TRIGGER_DEBUG_MODE     = 4'd1;  // 进入 debug mode（isDmode）

  // ---- 端口 struct：成员名 = golden 扁平端口名去掉 `io_<口>_<i>_bits_` 前缀 ----
  //  exceptionVec_<n> 收成 24 位向量 exceptionVec[n]；toLsq 的 feedback_<n> 收成 feedback[n]。
  //  各 struct 是两个变体端口的并集；某变体没有的成员由 wrapper 补常量（见文件头）。
  // BEGIN GENERATED(structs)
  // DynInst 在本单元进出的字段（入队请求 uop 与写回 uop 的并集）
  typedef struct packed {
    logic [23:0]         exceptionVec;
    logic [3:0]          trigger;
    logic [8:0]          fuOpType;
    logic                vecWen;
    logic                v0Wen;
    logic                vlWen;
    logic                flushPipe;
    logic                vpu_vill;
    logic                vpu_vma;
    logic                vpu_vta;
    logic [1:0]          vpu_vsew;
    logic [2:0]          vpu_vlmul;
    logic                vpu_specVill;
    logic                vpu_specVma;
    logic                vpu_specVta;
    logic [1:0]          vpu_specVsew;
    logic [2:0]          vpu_specVlmul;
    logic                vpu_vm;
    logic [7:0]          vpu_vstart;
    logic [2:0]          vpu_frm;
    logic                vpu_fpu_isFpToVecInst;
    logic                vpu_fpu_isFP32Instr;
    logic                vpu_fpu_isFP64Instr;
    logic                vpu_fpu_isReduction;
    logic                vpu_fpu_isFoldTo1_2;
    logic                vpu_fpu_isFoldTo1_4;
    logic                vpu_fpu_isFoldTo1_8;
    logic [1:0]          vpu_vxrm;
    logic [6:0]          vpu_vuopIdx;
    logic                vpu_lastUop;
    logic [127:0]        vpu_vmask;
    logic [7:0]          vpu_vl;
    logic [2:0]          vpu_nf;
    logic [1:0]          vpu_veew;
    logic                vpu_isReverse;
    logic                vpu_isExt;
    logic                vpu_isNarrow;
    logic                vpu_isDstMask;
    logic                vpu_isOpMask;
    logic                vpu_isMove;
    logic                vpu_isDependOldVd;
    logic                vpu_isWritePartVd;
    logic                vpu_isVleff;
    logic [7:0]          psrc_2;
    logic [7:0]          pdest;
    logic                robIdx_flag;
    logic [7:0]          robIdx_value;
    logic                debugInfo_eliminatedMove;
    logic [63:0]         debugInfo_renameTime;
    logic [63:0]         debugInfo_dispatchTime;
    logic [63:0]         debugInfo_enqRsTime;
    logic [63:0]         debugInfo_selectTime;
    logic [63:0]         debugInfo_issueTime;
    logic [63:0]         debugInfo_writebackTime;
    logic [63:0]         debugInfo_runahead_checkpoint_id;
    logic [63:0]         debugInfo_tlbFirstReqTime;
    logic [63:0]         debugInfo_tlbRespTime;
    logic [55:0]         debug_seqNum_seqNum;
    logic [7:0]          debug_seqNum_uopIdx;
    logic                replayInst;
    logic [6:0]          uopIdx;
    logic                lqIdx_flag;
    logic [6:0]          lqIdx_value;
    logic                sqIdx_flag;
    logic [5:0]          sqIdx_value;
  } mb_uop_t;

  // redirect：重定向点 robIdx 与 level
  typedef struct packed {
    logic                valid;
    logic                robIdx_flag;
    logic [7:0]          robIdx_value;
    logic                level;
  } mb_redirect_t;

  // fromSplit.req：VSplit 发来的一条 uop（MergeBufferReq）
  typedef struct packed {
    logic                valid;
    logic [15:0]         mask;
    logic [49:0]         vaddr;
    logic [4:0]          flowNum;
    logic [127:0]        data;
    logic [2:0]          vdIdx;
    logic                fof;
    logic [7:0]          vlmax;
    mb_uop_t             uop;
  } mb_enq_req_t;

  // fromPipeline：一个 flow 的写回（VecPipelineFeedbackIO）；sourceType/flushState 无端口，恒由 wrapper 补常量
  typedef struct packed {
    logic                valid;
    logic [3:0]          mBIndex;
    logic [3:0]          trigger;
    logic [23:0]         exceptionVec;
    logic                hasException;
    logic [63:0]         vaddr;
    logic                vaNeedExt;
    logic [63:0]         gpaddr;
    logic                isForVSnonLeafPTE;
    logic [7:0]          vstart;
    logic [15:0]         vecTriggerMask;
    logic [7:0]          elemIdx;
    logic [15:0]         mask;
    logic [2:0]          alignedType;
    logic [3:0]          reg_offset;
    logic [7:0]          elemIdxInsideVd;
    logic [127:0]        vecdata;
    logic                hit;
    logic [4:0]          splitIndex;
    logic [2:0]          sourceType;
    logic                flushState;
  } mb_pipe_t;

  // uopWriteback：写回后端的 MemExuOutput
  typedef struct packed {
    logic                valid;
    logic [127:0]        data;
    logic [2:0]          vdIdx;
    logic [2:0]          vdIdxInField;
    mb_uop_t             uop;
  } mb_wb_t;

  // toLsq：FeedbackToLsqIO
  typedef struct packed {
    logic                valid;
    logic                robidx_flag;
    logic [7:0]          robidx_value;
    logic [6:0]          uopidx;
    logic [63:0]         vaddr;
    logic                vaNeedExt;
    logic [63:0]         gpaddr;
    logic                isForVSnonLeafPTE;
    logic [1:0]          feedback;
    logic [7:0]          vl;
    logic [23:0]         exceptionVec;
  } mb_lsq_t;

  // feedback：给发射队列的 RSFeedback
  typedef struct packed {
    logic                valid;
    logic                robIdx_flag;
    logic [7:0]          robIdx_value;
    logic                hit;
    logic                flushState;
    logic [3:0]          sourceType;
    logic                sqIdx_flag;
    logic [5:0]          sqIdx_value;
    logic                lqIdx_flag;
    logic [6:0]          lqIdx_value;
    logic                isVecPartReplay;
    logic [15:0]         vecReplayMask;
    logic [3:0]          vecReplayMbIdx;
  } mb_fb_t;
  // END GENERATED

  // DynInst.fuOpType 的 LSUOpType.isAllUS：unit-stride / whole-register / masked 三类
  function automatic logic is_all_us(input logic [8:0] fuOpType);
    return fuOpType[6:5] == 2'b00 && (fuOpType[8] ^ fuOpType[7]);
  endfunction

  // RobPtr.needFlush(redirect)：重定向有效，且 robIdx 在重定向点之后
  // （level=1 表示"连重定向点这条自己也冲"）。isAfter 用 {flag,value} 环形比较。
  function automatic logic need_flush(input logic flag, input logic [ROB_W-1:0] value,
                                      input mb_redirect_t r);
    logic is_after;
    is_after = flag ^ r.robIdx_flag ^ (value > r.robIdx_value);
    return r.valid && ((r.level && flag == r.robIdx_flag && value == r.robIdx_value) || is_after);
  endfunction

endpackage
