// =============================================================================
//  StoreQueue_xs —— 访存子系统的存储队列（G1 golden: StoreQueue_xs.sv, 77145 行 / 1003 端口）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/mem/lsqueue/StoreQueue_xs.scala (1597 行)
//               同目录 StoreQueueData.scala / sbuffer/DatamoduleResultBuffer_xs.scala
//  golden 基线：G1-canonical (XiangShan kunminghu-v2 @ b36a1a2a5, KunminghuV2Config)
//
//  ★★★ 本文件是**考古阶段的骨架**，不是完成的重写 ★★★
//  只有「已在 golden 上实测核对过」的东西才写进来：
//    · 端口契约（1003 根，逐位从 golden 端口表推导，不是手抄）
//    · per-entry 状态清单与**复位域**（async / 不复位，实测分区见 §3）
//    · 多源写同一状态位的**优先级骨架**（条件线名已留，方程未追清的标 TODO）
//    · 5 个子模块的例化形状
//  功能方程绝大部分**尚未追清**，集中列在文件末尾 §9 待办清单。
//  任何人不得据本文件声称 StoreQueue_xs 已重写完成。
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
//   L887    §10 StoreQueue_xs —— golden 同名 wrapper（1003 根端口，逐位对齐）

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
  localparam int N_ISSUE_STRIDE= 4;  // IssuePtrMoveStride：两个 issue 指针每拍最多跳 4 条
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

  // ★照抄 utility.CircularQueuePtr 的 `+`★：先做不截位的加法，再与 56 比一次。
  // 只处理**一次**绕回 —— v > 56 时结果按 golden 的同一套截位走（不是"未定义"，
  // 是"与 golden 逐位一致地错"）。加数统一取 8 位：本模块最大的加数是
  // enqNumber（6 路 numLsElem 之和，8 位）。
  function automatic sqptr_t sqptr_add(sqptr_t p, logic [7:0] v);
    logic [8:0]        new_value;
    logic signed [9:0] diff;
    logic              reverse;
    new_value = {3'b0, p.value} + {1'b0, v};
    diff      = $signed({1'b0, new_value}) - $signed(10'(SQ_SIZE));
    reverse   = (diff >= 0);
    sqptr_add.flag  = reverse ? ~p.flag : p.flag;
    sqptr_add.value = reverse ? diff[SQ_IDX_W-1:0] : new_value[SQ_IDX_W-1:0];
  endfunction

  // ★照抄 `-`★：`p - v` == 「p + (56 - v) 之后把 flag 再翻一次」。
  // 不要图省事写成 value-v 再判负 —— flag 的翻法与那种写法差一次取反。
  function automatic sqptr_t sqptr_sub(sqptr_t p, logic [7:0] v);
    sqptr_t flipped;
    flipped = sqptr_add(p, 8'(SQ_SIZE) - v);
    sqptr_sub.flag  = ~flipped.flag;
    sqptr_sub.value =  flipped.value;
  endfunction

  // isAfter / distanceBetween 只在「相距不超过一圈」时有效（golden 同）。
  function automatic logic sqptr_after(sqptr_t a, sqptr_t b);
    sqptr_after = (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction

  // distanceBetween：同 flag 直接相减；异 flag 是 a + 56 - b。
  // golden 把「+56」写成 6 位域里的「-8」（56 ≡ -8 mod 64），两者等价，
  // 这里写成可读的形式，宽度仍然钉死 6 位以保持与 golden 逐位相同的截位。
  function automatic logic [SQ_IDX_W-1:0] sqptr_dist(sqptr_t a, sqptr_t b);
    sqptr_dist = (a.flag == b.flag) ? SQ_IDX_W'(a.value - b.value)
                                    : SQ_IDX_W'(a.value + SQ_IDX_W'(SQ_SIZE) - b.value);
  endfunction

  // UIntToMask(idx, 56) = 低 idx 位全 1。★先左移到 64 位再截 56 位，然后减 1★
  // （golden 的次序；先截后减与先减后截在 idx=56.. 时不同，别调换）。
  function automatic logic [SQ_SIZE-1:0] sq_idx_to_mask(logic [SQ_IDX_W-1:0] idx);
    logic [63:0] one_hot;
    one_hot        = 64'h1 << idx;
    sq_idx_to_mask = one_hot[SQ_SIZE-1:0] - 56'h1;
  endfunction

  // RobPtr 的 isAfter / needFlush（robIdx 是 {flag, value[7:0]}）。
  function automatic logic rob_after(logic af, logic [7:0] av, logic bf, logic [7:0] bv);
    rob_after = (af ^ bf) ^ (av > bv);
  endfunction

  // needFlush：level=1（flushItself）时连「正好等于重定向自身」也要冲。
  function automatic logic rob_need_flush(
      logic af, logic [7:0] av,
      logic rvalid, logic rflag, logic [7:0] rvalue, logic rlevel);
    rob_need_flush = rvalid & ((rlevel & ({af, av} == {rflag, rvalue}))
                               | rob_after(af, av, rflag, rvalue));
  endfunction

  // OHToUInt(Reverse(PriorityEncoderOH(Reverse(x)))) —— 即「x 里**最高**的置位下标」。
  // 全 0 时给 0（与 OHToUInt(0) 一致）。
  //
  // ★这里必须写成三目链，不能写成 `if (x[j]) r = j;`★
  //   x 里**真的会出现 X**：sta 从 misalign buffer 回灌时（isFrmMisAlignBuf=1）
  //   addrvalid 会置起来但地址阵列**没被写**，于是 vaddr CAM 的命中位是 X，
  //   一路进到 dataInvalidMask。golden 的优先级链是
  //       x[55] ? 55 : x[54] ? 54 : … : 0
  //   X 选择子会让整条结果变 X；`if (x[j])` 却把 X 当假，凭空给出一个确定值。
  //   实测：写成 if 的版本在 UT 上 3 个 forward 口的 dataInvalidSqIdx 共 191 拍
  //   失配（golden=X，重写=确定值），换成三目链后归零。
  //   而且要**照 golden 的两步走**：先用三目链选出 one-hot，再 OHToUInt 按位或
  //   下标。直接在三目链里选下标值（而不是 one-hot）会让 X 落在不同的位上 ——
  //   实测两种写法的 X 位模式确实不一样，只有两步版本与 golden 逐位相同。
  //   （下面的循环从低到高、后写者胜，展开后正好是 golden 那条从高到低的三目链。）
  function automatic logic [SQ_IDX_W-1:0] sq_highest_set(logic [SQ_SIZE-1:0] x);
    logic [SQ_SIZE-2:0] rev_oh;   // 55 位；bit k 表示「最高置位下标 = 55-k」
    logic               acc;
    // ★j 从 1 起★：golden 的链最内层是常数 0（下标 0 编码成全零，不需要 one-hot 位）
    rev_oh = '0;
    for (int j = 1; j < SQ_SIZE; j++)
      rev_oh = x[j] ? ((SQ_SIZE-1)'(1) << (SQ_SIZE - 1 - j)) : rev_oh;
    for (int b = 0; b < SQ_IDX_W; b++) begin
      acc = 1'b0;
      for (int k = 0; k < SQ_SIZE - 1; k++)
        if (((SQ_SIZE - 1 - k) >> b) & 1) acc = acc | rev_oh[k];
      sq_highest_set[b] = acc;
    end
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
  // 下面每一族状态都标了它属于哪个块；§18/§19 两个 always_ff 与此一一对应。

  // ---- 【异步复位块】per-entry 标志位（每条 56 位，位 j = 条目 j）----
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

  // ---- 【异步复位块】就绪向量输出寄存器（golden `r_*` / `r_1_*`）----
  // Chisel 是 GatedValidRegNext：使能 =「整条 56 位次态 != 现值」，异步复位 0。
  // 该使能与「无条件 RegNext」功能等价（次态等于现值时写不写都一样），
  // 但 golden 里确实是带使能的形式；这里照抄结构，别化简。
  logic [SQ_SIZE-1:0] stAddrReadyVec_q;    // golden `r_*`   -> io_stAddrReadyVec_*
  logic [SQ_SIZE-1:0] stDataReadyVec_q;    // golden `r_1_*` -> io_stDataReadyVec_*
  logic [SQ_SIZE-1:0] stAddrReadyVecReg;   // 组合次态
  logic [SQ_SIZE-1:0] stDataReadyVecReg;   // 组合次态

  // ---- 【异步复位块】指针 ----
  // ★DCE 形状必须照抄★（golden 实测，多写出来的就是 unread，FM 判 PARTIAL）：
  //   enqPtrExt   Chisel 6 份，golden **只剩第 0 份**（1..5 flag+value 全死）
  //   cmtPtrExt   Chisel 8 份，golden 保留 8 份 value，但 **只有第 0 份有 flag**
  //   deqPtrExt   2 份，两份的 flag 与 value **都活**
  //   rdataPtrExt 2 份全活（第 1 份 flag 经 dataBuffer 逃逸到 cboZeroStout.sqIdx）
  sqptr_t                     enqPtrExt;               // 仅第 0 份
  sqptr_t                     deqPtrExt   [N_ENSBUF];
  sqptr_t                     rdataPtrExt [N_ENSBUF];
  logic [SQ_IDX_W-1:0]        cmtPtrValue [N_COMMIT];  // 8 份 value
  logic                       cmtPtrFlag;              // ★只有第 0 份有 flag★
  sqptr_t                     addrReadyPtrExt, dataReadyPtrExt;

  // ---- 【异步复位块】uncache / CBO / 向量异常 的零散状态 ----
  // mmio 5 态 FSM 的编码照 golden：firtool 把 Enum(5) 压成 3 位。
  localparam logic [2:0] S_IDLE = 3'd0, S_REQ = 3'd1, S_RESP = 3'd2,
                         S_WB   = 3'd3, S_WAIT = 3'd4;
  // NC 4 态 FSM：2 位。
  localparam logic [1:0] NC_IDLE = 2'd0, NC_REQ = 2'd1,
                         NC_REQ_ACK = 2'd2, NC_RESP = 2'd3;

  logic [2:0]                 mmioState;
  logic [1:0]                 ncState;
  logic                       noPending;          // 复位值 1（★不是 0★）
  logic                       cboFlushedSb;
  logic [47:0]                cboMmioPAddr;
  logic [2:0]                 cboZeroOffset;      // CacheLineSize/XLEN = 8 -> 3 位
  logic                       cboZeroValid;
  logic                       cboZeroWaitFlushSb;
  logic [6:0]                 ncWaitRespPtrReg;   // uncacheIdxBits = 7
  logic                       vecExceptionFlag_valid;
  logic                       vecExceptionFlag_robIdx_flag;
  logic [7:0]                 vecExceptionFlag_robIdx_value;
  logic [31:0]                timeoutCounter;     // golden `counter`：只喂 TimeOutAssert
  logic [3:0]                 scommit;            // GatedRegNext(io_rob_scommit)
  logic [7:0]                 redirectCancelCount;  // 端口只取低 6 位
  logic                       lastCycleRedirect, lastlastCycleRedirect;
  logic [7:0]                 lastEnqCancel;
  logic                       forceWriteReg;      // io_force_write 的输出寄存器
  logic                       sqEmptyReg;         // io_sqEmpty 的输出寄存器（非复位，见下）
  logic                       wfiSafeReg;         // GatedValidRegNext(noPending & wfiReq)
  logic                       cboZeroFlushSb;     // GatedRegNext(cboZeroToSb)
  logic                       deqCanDoCboReg;     // GatedRegNext(...) 的寄存器部分

  // GatedRegNext(io_rob_pendingPtr) —— ★提交循环里 8 份各摇各的★（CommitWidth=8）。
  // 它们在 golden 里叫 next_r / next_r_1 … next_r_7，是 8 个独立寄存器而不是一份广播。
  logic                       pendingPtrReg_flag  [N_COMMIT];
  logic [7:0]                 pendingPtrReg_value [N_COMMIT];

  // GatedRegNext(rdataPtrExtNext(0)) —— mmioReq / ncReq 各自的 robIdx 与 memBackTypeMM
  // 取值指针。golden 是 4 份独立寄存器（两条通路 × 两个用途），不是一份共用。
  sqptr_t                     mmioReqRobIdxPtr, mmioReqMemBackPtr;
  sqptr_t                     ncReqRobIdxPtr,   ncReqMemBackPtr;

  // ---- 【不复位块】per-entry uop 载荷（47 个字段 × 56 条 = 2632 个寄存器）----
  // ★按「一个字段一个 56 项数组」声明★，不要打包成 struct 数组：上一轮
  //   用 struct 数组导致 FM 与 golden 的扁平标量 allocated_N 约 35K 个寄存器
  //   配对不收敛，大量 unverified（见 xs-v2r2-sv/docs/memblock/StoreQueue_xs.md §7.3）。
  // 字段集**就是 golden 保留下来的 47 个**（uop_0_* 一族逐条对过），
  // Chisel DynInst 里其余字段被 firtool DCE 掉了，补出来只会变成 unread。
  logic [23:0]  uop_exceptionVec                  [SQ_SIZE];
  logic [3:0]   uop_trigger                       [SQ_SIZE];
  logic [34:0]  uop_fuType                        [SQ_SIZE];
  logic [8:0]   uop_fuOpType                      [SQ_SIZE];
  logic         uop_rfWen                         [SQ_SIZE];
  logic         uop_flushPipe                     [SQ_SIZE];
  logic [2:0]   uop_vpu_nf                        [SQ_SIZE];
  logic [1:0]   uop_vpu_veew                      [SQ_SIZE];
  logic [6:0]   uop_uopIdx                        [SQ_SIZE];
  logic [7:0]   uop_pdest                         [SQ_SIZE];
  logic         uop_robIdx_flag                   [SQ_SIZE];
  logic [7:0]   uop_robIdx_value                  [SQ_SIZE];
  logic         uop_debugInfo_eliminatedMove      [SQ_SIZE];
  logic [63:0]  uop_debugInfo_renameTime          [SQ_SIZE];
  logic [63:0]  uop_debugInfo_dispatchTime        [SQ_SIZE];
  logic [63:0]  uop_debugInfo_enqRsTime           [SQ_SIZE];
  logic [63:0]  uop_debugInfo_selectTime          [SQ_SIZE];
  logic [63:0]  uop_debugInfo_issueTime           [SQ_SIZE];
  logic [63:0]  uop_debugInfo_writebackTime       [SQ_SIZE];
  logic [63:0]  uop_debugInfo_runahead_checkpoint_id [SQ_SIZE];
  logic [63:0]  uop_debugInfo_tlbFirstReqTime     [SQ_SIZE];
  logic [63:0]  uop_debugInfo_tlbRespTime         [SQ_SIZE];
  logic [55:0]  uop_debug_seqNum_seqNum           [SQ_SIZE];
  logic [7:0]   uop_debug_seqNum_uopIdx           [SQ_SIZE];

  // 只为 difftest 的 diffInfo.offset 活下来的那一份调试载荷（start 已被 DCE）。
  logic [5:0]   debug_vec_unaligned_offset        [SQ_SIZE];

  // ---- 【不复位块】uncacheUop —— ★读锁存值，不读 uop[deqPtr] 的 live 值★ ----
  // 见 §TRAP-G。整族在 mmioState 进 s_req 的那一拍一起锁存。
  // ★uncacheUop 的 exceptionVec 只剩两位★：ExceptionNO.selectByFu(·, StaCfg)
  // 之后只有 storeAccessFault(7) 与 hardwareError(19) 能活下来，golden 连寄存器
  // 都只留了这两个。补出另外 22 位只会变成 unread。
  logic         uncacheUop_excStoreAccessFault;  // golden uncacheUop_exceptionVec_7
  logic         uncacheUop_excHardwareError;     // golden uncacheUop_exceptionVec_19
  logic [8:0]   uncacheUop_fuOpType;
  logic         uncacheUop_rfWen;
  logic [6:0]   uncacheUop_uopIdx;
  logic [7:0]   uncacheUop_pdest;
  logic         uncacheUop_robIdx_flag;
  logic [7:0]   uncacheUop_robIdx_value;
  logic         uncacheUop_debugInfo_eliminatedMove;
  logic [63:0]  uncacheUop_debugInfo_renameTime;
  logic [63:0]  uncacheUop_debugInfo_dispatchTime;
  logic [63:0]  uncacheUop_debugInfo_enqRsTime;
  logic [63:0]  uncacheUop_debugInfo_selectTime;
  logic [63:0]  uncacheUop_debugInfo_issueTime;
  logic [63:0]  uncacheUop_debugInfo_writebackTime;
  logic [63:0]  uncacheUop_debugInfo_runahead_checkpoint_id;
  logic [63:0]  uncacheUop_debugInfo_tlbFirstReqTime;
  logic [63:0]  uncacheUop_debugInfo_tlbRespTime;
  logic [55:0]  uncacheUop_debug_seqNum_seqNum;
  logic [7:0]   uncacheUop_debug_seqNum_uopIdx;

  // ---- 【不复位块】cboZeroUop —— cbo.zero 回写 ROB 用的那份快照 ----
  logic [23:0]  cboZeroUop_exceptionVec;
  logic [3:0]   cboZeroUop_trigger;
  logic         cboZeroUop_rfWen;
  logic         cboZeroUop_flushPipe;
  logic [7:0]   cboZeroUop_pdest;
  logic         cboZeroUop_robIdx_flag;
  logic [7:0]   cboZeroUop_robIdx_value;
  logic         cboZeroUop_debugInfo_eliminatedMove;
  logic [63:0]  cboZeroUop_debugInfo_renameTime;
  logic [63:0]  cboZeroUop_debugInfo_dispatchTime;
  logic [63:0]  cboZeroUop_debugInfo_enqRsTime;
  logic [63:0]  cboZeroUop_debugInfo_selectTime;
  logic [63:0]  cboZeroUop_debugInfo_issueTime;
  logic [63:0]  cboZeroUop_debugInfo_writebackTime;
  logic [63:0]  cboZeroUop_debugInfo_runahead_checkpoint_id;
  logic [63:0]  cboZeroUop_debugInfo_tlbFirstReqTime;
  logic [63:0]  cboZeroUop_debugInfo_tlbRespTime;
  logic [55:0]  cboZeroUop_debug_seqNum_seqNum;
  logic [7:0]   cboZeroUop_debug_seqNum_uopIdx;
  logic         cboZeroSqIdx_flag;
  logic [5:0]   cboZeroSqIdx_value;

  // ---- 【不复位块】各条流水的一拍打拍寄存器 ----
  logic [5:0]   stWbIndexReg     [N_STA];   // RegEnable(stWbIndex, storeAddrIn.fire)
  logic         storeAddrInFireReg_q [N_STA];
  logic [5:0]   lastStWbIndex    [N_STD];   // RegEnable(stWbIndex, storeDataIn.fire)
  logic         storeDataInFireReg [N_STD];
  logic [SQ_SIZE-1:0] lastCycleCancelVec;   // RegEnable(needCancel, brqRedirect.valid)

  // 转发通路的一拍打拍（每口一份）
  logic [SQ_SIZE-1:0] fwdPaddrMmask_q   [N_FWD];  // golden vpmaskNotEqual_r{,_2,_4}
  logic [SQ_SIZE-1:0] fwdVaddrMmask_q   [N_FWD];  // golden vpmaskNotEqual_r_{1,3,5}
  logic [SQ_SIZE-1:0] needForward_q     [N_FWD];  // golden vpmaskNotEqual_REG*
  logic [SQ_SIZE-1:0] addrRealValid_q   [N_FWD];  // golden vpmaskNotEqual_next_r*（带使能）
  logic               fwdValid_q        [N_FWD];  // golden vaddrMatchFailed_REG*
  logic [SQ_SIZE-1:0] dataInvalidMask1Reg [N_FWD];
  logic [SQ_SIZE-1:0] dataInvalidMask2Reg [N_FWD];
  logic [SQ_SIZE-1:0] addrInvalidMask1Reg [N_FWD];
  logic [SQ_SIZE-1:0] addrInvalidMask2Reg [N_FWD];
  logic               fwdDataInvalid_q  [N_FWD];  // io_forward_*_dataInvalid_REG
  logic               fwdHasInvalidAddr_q [N_FWD];// io_forward_*_addrInvalid_REG
  // ★同一个 RegEnable(loadWaitStrict, valid) golden 摇了两份★（Chisel 里这个
  // 表达式出现两次，firtool 没做 CSE）。_sel 供 addrInvalidSqIdx 的三选一用，
  // _inv 供 addrInvalid 用。合并成一份会在 FM 里变成 unmatched。
  logic               fwdLoadWaitStrict_sel_q [N_FWD]; // golden r_5_0 / r_9_0 / r_13_0
  logic               fwdLoadWaitStrict_inv_q [N_FWD]; // golden io_forward_*_addrInvalid_r
  sqptr_t             fwdSqIdxMinus1_q  [N_FWD];  // RegEnable(uop.sqIdx - 1, valid)
  sqptr_t             fwdSqIdxA_q       [N_FWD];  // addrInvalid 用的 RegEnable(uop.sqIdx)
  sqptr_t             fwdSqIdxD_q       [N_FWD];  // dataInvalid 用的 RegEnable(uop.sqIdx)
  logic               s2_differentFlag  [N_FWD];
  logic               s2_enqPtrFlag     [N_FWD];
  sqptr_t             s2_deqPtr         [N_FWD];

  // ---- 【不复位块】输出打拍 ----
  logic [1:0]   sqDeqReg;                 // io_sqDeq = RegNext(sqDeqCnt)
  logic         perfValueReg   [N_PERF];  // 两级：REG -> REG_1
  logic         perfValueReg_1 [N_PERF];
  // ★golden 为 6 个 dispatch 口各摇了一份 RegNext(brqRedirect.valid)★（没做 CSE），
  // 少摇几份 FM 就多几个 unmatched，所以照抄 6 份。
  logic         validVStoreFlow_q [N_ENQ];
  logic         redirectValidReg;         // RegNext(io_brqRedirect_valid)
  logic         mmioStoutFireRegChain;    // golden REG/REG_1（断言用的两级打拍）
  logic         mmioStoutFireRegChain_1;

// -----------------------------------------------------------------------------
// §4 组合中间量的声明（按通路分组；方程在后面各节）
// -----------------------------------------------------------------------------
  // ---- 容量与掩码 ----
  logic [SQ_IDX_W-1:0]  validCount;      // = distanceBetween(enqPtr, deqPtr)
  logic                 allowEnqueue;
  logic [SQ_SIZE-1:0]   deqMask;         // 低 deqPtr 位为 1

  // ---- 入队 ----
  logic [N_ENQ-1:0]     canEnqueue;
  logic [N_ENQ-1:0]     enqCancel;
  logic [7:0]           vStoreFlow     [N_ENQ];
  sqptr_t               enqUpBound     [N_ENQ];
  logic [N_ENQ-1:0]     entryCanEnqSeq [SQ_SIZE];  // 每条目 × 每个 dispatch 口
  logic [SQ_SIZE-1:0]   entryCanEnq;
  logic [2:0]           enqSelPort     [SQ_SIZE];  // ParallelPriorityMux 选中的口号
  logic [7:0]           enqNumber;
  logic [7:0]           enqCancelNum;

  // ---- sta / std / mask 写入 ----
  logic [N_STA-1:0]     staFire;          // io_storeAddrIn_i_valid（ValidIO，无 ready）
  logic [SQ_IDX_W-1:0]  stWbIndex      [N_STA];
  logic [N_STA-1:0]     staWen;           // fire & !miss & !isFrmMisAlignBuf
  logic [N_STA-1:0]     storeAddrInFireReg;
  logic [N_STD-1:0]     stdFire;
  logic [SQ_IDX_W-1:0]  stdWbIndex     [N_STD];
  logic [127:0]         stdWdata       [N_STD];

  // ---- issue 指针 ----
  sqptr_t               nextAddrReadyPtr, nextDataReadyPtr;
  logic                 unalignedCanMove;
  logic [1:0]           unalignedMoveStep;
  sqptr_t               redirectIssuePtr; // 冲刷时两个 issue 指针的强制值

  // ---- 出队 / 读出 ----
  logic [N_ENSBUF-1:0]  readyReadGoVec;
  logic [1:0]           sqReadCnt;
  sqptr_t               rdataPtrExtNext [N_ENSBUF];
  logic [N_ENSBUF-1:0]  readyDeqVec;
  logic [1:0]           sqDeqCnt;
  sqptr_t               deqPtrExtNext   [N_ENSBUF];
  logic [SQ_SIZE-1:0]   deqClear;         // 本拍被退队清掉的条目

  // ---- 提交 ----
  logic [N_COMMIT-1:0]  commitVec;
  logic [N_COMMIT-1:0]  isCommit;
  logic [3:0]           commitCount;
  logic [SQ_SIZE-1:0]   commitSet;        // 本拍被置 committed 的条目
  logic [SQ_SIZE-1:0]   commitNcExcDone;  // isCommit & nc & hasException -> completed

  // ---- 冲刷 ----
  logic [SQ_SIZE-1:0]   needCancel;

  // ---- 转发（每口一组）----
  logic [SQ_SIZE-1:0]   addrValidVec;     // addrvalid & allocated
  logic [SQ_SIZE-1:0]   dataValidVec;     // datavalid
  logic [SQ_SIZE-1:0]   allValidVec;      // addrvalid & datavalid & allocated
  logic                 differentFlag  [N_FWD];
  logic [SQ_SIZE-1:0]   forwardMask1   [N_FWD];
  logic [SQ_SIZE-1:0]   forwardMask2   [N_FWD];
  logic [SQ_SIZE-1:0]   needForward    [N_FWD];
  logic [SQ_SIZE-1:0]   canForward1    [N_FWD];
  logic [SQ_SIZE-1:0]   canForward2    [N_FWD];
  logic [SQ_SIZE-1:0]   storeSetHitVec [N_FWD];
  logic [SQ_SIZE-1:0]   dataInvalidMask1 [N_FWD];
  logic [SQ_SIZE-1:0]   dataInvalidMask2 [N_FWD];
  logic [SQ_SIZE-1:0]   addrInvalidMask1 [N_FWD];
  logic [SQ_SIZE-1:0]   addrInvalidMask2 [N_FWD];
  logic                 hasInvalidAddr [N_FWD];
  // 「谁挡住了我」的下标与标志（提到模块级：既便于阅读，也便于 UT 打层次探针）
  logic                 addrInvalidFlag  [N_FWD];
  logic                 dataInvalidFlag  [N_FWD];
  logic [SQ_IDX_W-1:0]  addrInvalidSqIdx [N_FWD];
  logic [SQ_IDX_W-1:0]  dataInvalidSqIdx [N_FWD];

  // ---- 子模块的输出线（名字照 golden 的 `_<inst>_<port>` 去掉前导下划线）----
  logic [15:0]          dataModule_rdata_mask [N_ENSBUF];
  logic [127:0]         dataModule_rdata_data [N_ENSBUF];
  logic [15:0]          dataModule_forwardMask[N_FWD];
  logic [7:0]           dataModule_forwardData[N_FWD][16];
  logic [47:0]          paddrModule_rdata     [N_ENSBUF];
  logic [N_ENSBUF-1:0]  paddrModule_rlineflag;
  logic [SQ_SIZE-1:0]   paddrModule_forwardMmask [N_FWD];
  logic [49:0]          vaddrModule_rdata     [N_ENSBUF];
  logic [SQ_SIZE-1:0]   vaddrModule_forwardMmask [N_FWD];

  logic [N_ENSBUF-1:0]  dataBuffer_enq_ready;
  logic [N_ENSBUF-1:0]  dataBuffer_deq_valid;
  logic [47:0]          dataBuffer_deq_addr   [N_ENSBUF];
  logic [49:0]          dataBuffer_deq_vaddr  [N_ENSBUF];
  logic [127:0]         dataBuffer_deq_data   [N_ENSBUF];
  logic [15:0]          dataBuffer_deq_mask   [N_ENSBUF];
  logic [N_ENSBUF-1:0]  dataBuffer_deq_wline;
  sqptr_t               dataBuffer_deq_sqPtr  [N_ENSBUF];
  logic [N_ENSBUF-1:0]  dataBuffer_deq_vecValid;
  logic [N_ENSBUF-1:0]  dataBuffer_deq_sqNeedDeq;

  // dataBuffer 入口侧（本模块驱动）
  logic [N_ENSBUF-1:0]  dataBuffer_enq_valid;
  logic [47:0]          dataBuffer_enq_addr   [N_ENSBUF];
  logic [49:0]          dataBuffer_enq_vaddr  [N_ENSBUF];
  logic [127:0]         dataBuffer_enq_data   [N_ENSBUF];
  logic [15:0]          dataBuffer_enq_mask   [N_ENSBUF];
  logic [N_ENSBUF-1:0]  dataBuffer_enq_wline;
  sqptr_t               dataBuffer_enq_sqPtr  [N_ENSBUF];
  logic [N_ENSBUF-1:0]  dataBuffer_enq_vecValid;
  logic [N_ENSBUF-1:0]  dataBuffer_enq_sqNeedDeq;
  logic [N_ENSBUF-1:0]  dataBuffer_enq_fire;

  logic [63:0]          exceptionBuffer_vaddr;
  logic                 exceptionBuffer_vaNeedExt;
  logic                 exceptionBuffer_isHyper;
  logic [63:0]          exceptionBuffer_gpaddr;
  logic                 exceptionBuffer_isForVSnonLeafPTE;

  // ---- uncache / CBO ----
  logic                 mmioReq_valid, ncReq_valid;
  logic [47:0]          mmioReq_addr,  ncReq_addr;
  logic [49:0]          mmioReq_vaddr, ncReq_vaddr;
  logic [63:0]          mmioReq_data,  ncReq_data;
  logic [7:0]           mmioReq_mask,  ncReq_mask;
  logic [6:0]           mmioReq_id;
  logic                 mmioReq_memBackTypeMM, ncReq_memBackTypeMM;
  logic                 mmioReq_robIdx_flag,  ncReq_robIdx_flag;
  logic [7:0]           mmioReq_robIdx_value, ncReq_robIdx_value;
  logic                 mmioDoReq, ncDoReq, ncDoResp, ncSlaveAck, ncDeqTrigger;
  logic [6:0]           ncSlaveAckMid, ncPtr;
  logic                 ncRespFire;
  logic                 mmioIsCboZero, deqCanDoCbo;
  logic [SQ_IDX_W-1:0]  deqPtr, rdPtr, cmtPtr;
  logic [N_ENSBUF-1:0]  isCboZeroToSbVec;
  logic                 cboZeroToSb;
  logic [5:0]           valid_cnt;        // PopCount(allocated)

  // ---- 向量异常旗标 ----
  logic [N_ENSBUF-1:0]  vecCommitHasExceptionValid;
  logic [N_ENSBUF-1:0]  vecCommitHasExceptionLastFlow;
  logic                 vecCommitLastFlow;
  logic                 vecExceptionFlagCancel;
  logic [SQ_IDX_W-1:0]  vecCommitSelEntry;

  // ---- 输出中间量 ----
  logic [N_ENSBUF-1:0]  sbufferFire;
  logic [N_ENSBUF-1:0]  sbufferWline;     // = deq.wline & deq.vecValid（见 §13）
  logic                 mmioStoutValid, mmioStoutFire;
  logic                 cboZeroStoutValid, cboZeroStoutFire;

// -----------------------------------------------------------------------------
// §5 容量、掩码、若干「指针的当前值」
// -----------------------------------------------------------------------------
  assign deqPtr = deqPtrExt[0].value;
  assign rdPtr  = rdataPtrExt[0].value;
  assign cmtPtr = cmtPtrValue[0];

  assign validCount   = sqptr_dist(enqPtrExt, deqPtrExt[0]);
  // golden 写成 `validCount < 6'h35`（53）。Chisel 那边是
  //   validCount <= StoreQueueSize - LSQStEnqWidth = 56 - 4 = 52
  // 两者同义；这里照 golden 的字面形式记，别自己换算回去。
  assign allowEnqueue = validCount < SQ_IDX_W'(ALLOW_ENQ_LT);
  assign deqMask      = sq_idx_to_mask(deqPtr);

  assign valid_cnt    = 6'($countones(allocated));


// -----------------------------------------------------------------------------
// §6 dispatch 入队 —— 6 个口，每个口按 numLsElem 占**一段连续条目**
// -----------------------------------------------------------------------------
  // 向量 store 一条指令要占多条 SQ 条目（numLsElem 个 flow）。所以入队不是
  // 「一个口写一条」，而是「一个口盖住 [sqIdx, sqIdx+numLsElem) 这一段」。
  // 每条目自己判断「我落在哪些口的区间里」，多个口同时盖住时**下标小的口赢**
  // （Chisel 的 ParallelPriorityMux）。
  always_comb begin
    for (int k = 0; k < N_ENQ; k++) begin
      canEnqueue[k] = enq_req_in[k].valid;
      enqCancel[k]  = rob_need_flush(enq_req_in[k].bits_robIdx_flag,
                                     enq_req_in[k].bits_robIdx_value,
                                     io_brqRedirect_valid,
                                     io_brqRedirect_bits_robIdx_flag,
                                     io_brqRedirect_bits_robIdx_value,
                                     io_brqRedirect_bits_level);
      vStoreFlow[k] = {3'h0, enq_req_in[k].bits_numLsElem};
      enqUpBound[k] = sqptr_add('{flag:  enq_req_in[k].bits_sqIdx_flag,
                                  value: enq_req_in[k].bits_sqIdx_value},
                                vStoreFlow[k]);
    end
  end

  always_comb begin
    for (int j = 0; j < SQ_SIZE; j++) begin
      entryCanEnqSeq[j] = '0;
      for (int k = 0; k < N_ENQ; k++) begin
        automatic logic [5:0]  lowV  = enq_req_in[k].bits_sqIdx_value;
        automatic logic        crossLoop = (enq_req_in[k].bits_sqIdx_flag != enqUpBound[k].flag);
        automatic logic        hit   = crossLoop
                                     ? ((lowV <= SQ_IDX_W'(j)) || (SQ_IDX_W'(j) < enqUpBound[k].value))
                                     : ((lowV <= SQ_IDX_W'(j)) && (SQ_IDX_W'(j) < enqUpBound[k].value));
        entryCanEnqSeq[j][k] = canEnqueue[k] & ~enqCancel[k] & hit;
      end
      entryCanEnq[j] = |entryCanEnqSeq[j];
      // ParallelPriorityMux：下标最小的命中者胜。倒着扫一遍即得。
      enqSelPort[j] = 3'd0;
      for (int k = N_ENQ - 1; k >= 0; k--)
        if (entryCanEnqSeq[j][k]) enqSelPort[j] = 3'(k);
    end
  end

  // enqPtr 每拍前进的条目数 = 「没被冲掉的那些口」的 numLsElem 之和。
  // ★门控用的是 RegNext(brqRedirect.valid)，不是当拍的 valid★
  // （golden 把这个 RegNext 复制成 6 份 validVStoreFlow_REG_*，形状照抄）。
  always_comb begin
    enqNumber = 8'h0;
    for (int k = 0; k < N_ENQ; k++)
      if (~validVStoreFlow_q[k] & canEnqueue[k]) enqNumber = enqNumber + vStoreFlow[k];
  end

  // 冲刷时要从 enqPtr 扣掉的条目数（当拍算，下一拍锁进 lastEnqCancel）。
  always_comb begin
    enqCancelNum = 8'h0;
    for (int k = 0; k < N_ENQ; k++)
      if (canEnqueue[k] & enqCancel[k]) enqCancelNum = enqCancelNum + vStoreFlow[k];
  end

  assign io_enq_canAccept = allowEnqueue;

  // §1.2 的通道结构体按 golden 端口逐根展开（exceptionVec 是 24 根独立端口）。
  // 先把它们收成 24 位向量，后面所有地方就能按向量走，不用再摊开。
  logic [23:0] enqExceptionVec [N_ENQ];
  logic [23:0] staExceptionVec [N_STA];
  always_comb begin
    for (int k = 0; k < N_ENQ; k++)
      enqExceptionVec[k] = {
        enq_req_in[k].bits_exceptionVec_23, enq_req_in[k].bits_exceptionVec_22,
        enq_req_in[k].bits_exceptionVec_21, enq_req_in[k].bits_exceptionVec_20,
        enq_req_in[k].bits_exceptionVec_19, enq_req_in[k].bits_exceptionVec_18,
        enq_req_in[k].bits_exceptionVec_17, enq_req_in[k].bits_exceptionVec_16,
        enq_req_in[k].bits_exceptionVec_15, enq_req_in[k].bits_exceptionVec_14,
        enq_req_in[k].bits_exceptionVec_13, enq_req_in[k].bits_exceptionVec_12,
        enq_req_in[k].bits_exceptionVec_11, enq_req_in[k].bits_exceptionVec_10,
        enq_req_in[k].bits_exceptionVec_9,  enq_req_in[k].bits_exceptionVec_8,
        enq_req_in[k].bits_exceptionVec_7,  enq_req_in[k].bits_exceptionVec_6,
        enq_req_in[k].bits_exceptionVec_5,  enq_req_in[k].bits_exceptionVec_4,
        enq_req_in[k].bits_exceptionVec_3,  enq_req_in[k].bits_exceptionVec_2,
        enq_req_in[k].bits_exceptionVec_1,  enq_req_in[k].bits_exceptionVec_0};
    for (int i = 0; i < N_STA; i++)
      staExceptionVec[i] = {
        storeAddrIn_in[i].bits_uop_exceptionVec_23, storeAddrIn_in[i].bits_uop_exceptionVec_22,
        storeAddrIn_in[i].bits_uop_exceptionVec_21, storeAddrIn_in[i].bits_uop_exceptionVec_20,
        storeAddrIn_in[i].bits_uop_exceptionVec_19, storeAddrIn_in[i].bits_uop_exceptionVec_18,
        storeAddrIn_in[i].bits_uop_exceptionVec_17, storeAddrIn_in[i].bits_uop_exceptionVec_16,
        storeAddrIn_in[i].bits_uop_exceptionVec_15, storeAddrIn_in[i].bits_uop_exceptionVec_14,
        storeAddrIn_in[i].bits_uop_exceptionVec_13, storeAddrIn_in[i].bits_uop_exceptionVec_12,
        storeAddrIn_in[i].bits_uop_exceptionVec_11, storeAddrIn_in[i].bits_uop_exceptionVec_10,
        storeAddrIn_in[i].bits_uop_exceptionVec_9,  storeAddrIn_in[i].bits_uop_exceptionVec_8,
        storeAddrIn_in[i].bits_uop_exceptionVec_7,  storeAddrIn_in[i].bits_uop_exceptionVec_6,
        storeAddrIn_in[i].bits_uop_exceptionVec_5,  storeAddrIn_in[i].bits_uop_exceptionVec_4,
        storeAddrIn_in[i].bits_uop_exceptionVec_3,  storeAddrIn_in[i].bits_uop_exceptionVec_2,
        storeAddrIn_in[i].bits_uop_exceptionVec_1,  storeAddrIn_in[i].bits_uop_exceptionVec_0};
  end

  // uncache 的一些公共条件线（在 §20/§21 的时序块里反复用到）
  logic uncacheRespFireNonNc, respDenied, respCorrupt;
  logic mmioEnterReqReg;          // golden REG_4：s_idle -> s_req 的那个 RegNext 条件
  logic cmoOpReqFire, cmoOpRespFire;
  assign uncacheRespFireNonNc = io_uncache_resp_valid & ~io_uncache_resp_bits_nc;
  assign respDenied  = io_uncache_resp_bits_denied | io_cmoOpResp_bits_denied;
  assign respCorrupt = (io_uncache_resp_bits_corrupt  & ~io_uncache_resp_bits_denied)
                     | (io_cmoOpResp_bits_corrupt     & ~io_cmoOpResp_bits_denied);
  assign cmoOpReqFire  = io_cmoOpReq_valid  & io_cmoOpReq_ready;
  assign cmoOpRespFire = io_cmoOpResp_valid & io_cmoOpResp_ready;

// -----------------------------------------------------------------------------
// §7 sta / std / storeMask 三条写入通路
// -----------------------------------------------------------------------------
  // storeAddrIn 是 ValidIO（没有 ready），所以 fire == valid。
  always_comb begin
    for (int i = 0; i < N_STA; i++) begin
      staFire[i]   = storeAddrIn_in[i].valid;
      stWbIndex[i] = storeAddrIn_in[i].bits_uop_sqIdx_value;
      // 地址阵列的写使能：非「从 misalign buffer 回灌」且 dcache 没 miss。
      staWen[i]    = staFire[i] & ~storeAddrIn_in[i].bits_isFrmMisAlignBuf
                                & ~storeAddrIn_in[i].bits_miss;
      // s2（下一拍）：pma/pmp 要晚一拍才给出 mmio/异常裁决，所以有第二次写。
      storeAddrInFireReg[i] = storeAddrInFireReg_q[i] & storeAddrInRe_in[i].updateAddrValid;
    end
  end

  // ---- std：store 数据写入，golden 实际是两拍 ----
  // s0 写数据阵列；s1 才把 datavalid 置起来（且要求该条目当拍仍然 allocated）。
  // genVWdata：标量 store 按 fuOpType[2:0] 把有效字节**复制铺满** 128 位，
  // 向量 store 直接用原数据，cbo.zero（fuOpType == 9'h7）写全 0。
  always_comb begin
    for (int i = 0; i < N_STD; i++) begin
      automatic logic isVecStore;
      stdFire[i]    = storeDataIn_in[i].valid;
      stdWbIndex[i] = storeDataIn_in[i].bits_uop_sqIdx_value;
      isVecStore    = storeDataIn_in[i].bits_uop_fuType[32]
                    | storeDataIn_in[i].bits_uop_fuType[34];
      if (storeDataIn_in[i].bits_uop_fuOpType == 9'h7)
        stdWdata[i] = 128'h0;
      else if (isVecStore)
        stdWdata[i] = storeDataIn_in[i].bits_data;
      else begin
        unique case (storeDataIn_in[i].bits_uop_fuOpType[2:0])
          3'h0:    stdWdata[i] = {16{storeDataIn_in[i].bits_data[7:0]}};   // sb
          3'h1:    stdWdata[i] = { 8{storeDataIn_in[i].bits_data[15:0]}};  // sh
          3'h2:    stdWdata[i] = { 4{storeDataIn_in[i].bits_data[31:0]}};  // sw
          3'h3:    stdWdata[i] = { 2{storeDataIn_in[i].bits_data[63:0]}};  // sd
          3'h4:    stdWdata[i] = storeDataIn_in[i].bits_data;              // 128 位
          default: stdWdata[i] = 128'h0;
        endcase
      end
    end
  end


// -----------------------------------------------------------------------------
// §8 addrReady / dataReady 两个「发射就绪」指针
// -----------------------------------------------------------------------------
  // 这两个指针告诉后端「到哪一条为止的 store 地址/数据都已经就绪」。
  // 每拍最多前进 IssuePtrMoveStride(=4) 条：连着看 4 条，遇到第一条没就绪的就停。
  always_comb begin
    automatic logic [N_ISSUE_STRIDE-1:0] addrLookup;
    automatic logic [N_ISSUE_STRIDE-1:0] dataLookup;
    automatic logic [2:0]                addrStep, dataStep;
    for (int k = 0; k < N_ISSUE_STRIDE; k++) begin
      automatic sqptr_t pa = sqptr_add(addrReadyPtrExt, 8'(k));
      automatic sqptr_t pd = sqptr_add(dataReadyPtrExt, 8'(k));
      addrLookup[k] = allocated[pa.value]
                    & (mmio[pa.value] | addrvalid[pa.value] | vecMbCommit[pa.value])
                    & (pa != enqPtrExt);
      // ★dataReady 侧多两条：要求 addrvalid 已经有，且**非对齐的条目一律不算就绪**★
      dataLookup[k] = allocated[pd.value]
                    & ((addrvalid[pd.value] & (mmio[pd.value] | datavalid[pd.value]))
                       | vecMbCommit[pd.value])
                    & ~unaligned[pd.value]
                    & (pd != enqPtrExt);
    end
    addrStep = 3'(N_ISSUE_STRIDE);
    for (int k = N_ISSUE_STRIDE - 1; k >= 0; k--) if (~addrLookup[k]) addrStep = 3'(k);
    dataStep = 3'(N_ISSUE_STRIDE);
    for (int k = N_ISSUE_STRIDE - 1; k >= 0; k--) if (~dataLookup[k]) dataStep = 3'(k);
    nextAddrReadyPtr = sqptr_add(addrReadyPtrExt, {5'h0, addrStep});
    nextDataReadyPtr = sqptr_add(dataReadyPtrExt, {5'h0, dataStep});
  end

  // 非对齐条目永远进不了 dataLookup，所以它会把 dataReadyPtr 卡死在原地。
  // 补救：当它正随着出队组一起离开时，让 dataReadyPtr 跟着退队量一起跳过去。
  always_comb begin
    automatic logic [N_ENSBUF-1:0] inDeqGroup;
    automatic logic [1:0]          firstInGroup;
    for (int i = 0; i < N_ENSBUF; i++)
      inDeqGroup[i] = (dataReadyPtrExt == deqPtrExt[i]) & (sqDeqCnt > 2'(i));
    unalignedCanMove = (unaligned[deqPtrExt[0].value] | unaligned[deqPtrExt[1].value])
                     & (|inDeqGroup);
    firstInGroup = 2'(N_ENSBUF);
    for (int i = N_ENSBUF - 1; i >= 0; i--) if (inDeqGroup[i]) firstInGroup = 2'(i);
    unalignedMoveStep = sqDeqCnt - firstInGroup;
  end

  // 冲刷时两个 issue 指针一起被强制拉回：谁更靠后就用谁
  // （mmio 会让 deqPtr 跑到 cmtPtr 前面，所以不能无脑用 cmtPtr）。
  assign redirectIssuePtr = sqptr_after('{flag: cmtPtrFlag, value: cmtPtrValue[0]}, deqPtrExt[0])
                          ? '{flag: cmtPtrFlag, value: cmtPtrValue[0]}
                          : deqPtrExtNext[0];

  // 两条就绪向量的组合次态（输出寄存器在 §19 的复位块里）。
  always_comb begin
    for (int j = 0; j < SQ_SIZE; j++) begin
      stAddrReadyVecReg[j] = allocated[j] & (mmio[j] | addrvalid[j] | (isVec[j] & vecMbCommit[j]));
      stDataReadyVecReg[j] = allocated[j]
                           & ((addrvalid[j] & (mmio[j] | datavalid[j])) | (isVec[j] & vecMbCommit[j]))
                           & ~unaligned[j];
    end
  end

// -----------------------------------------------------------------------------
// §9 store-to-load 转发（3 个 load 口，队列里做地址 CAM）
// -----------------------------------------------------------------------------
  // load 要找「比自己老、地址有重叠」的 store 拿数据。队列是环形的，所以
  // 「比我老」这一段可能被队尾切成两截：
  //   同 flag：只有一段  deqMask ^ sqIdxMask
  //   异 flag：两段      段1 = ~deqMask（从 deq 到队尾），段2 = sqIdxMask（从 0 到 sqIdx）
  // 转发用的是 **vaddr** CAM（vaddrModule）；paddr CAM 只用来事后核对两者是否一致
  // （不一致 -> matchInvalid -> load 重放）。
  assign addrValidVec = addrvalid & allocated;
  assign dataValidVec = datavalid;
  assign allValidVec  = addrvalid & datavalid & allocated;

  always_comb begin
    for (int i = 0; i < N_FWD; i++) begin
      differentFlag[i] = deqPtrExt[0].flag != forward_in[i].sqIdx_flag;
      forwardMask1[i]  = differentFlag[i] ? ~deqMask : (deqMask ^ forward_in[i].sqIdxMask);
      forwardMask2[i]  = differentFlag[i] ? forward_in[i].sqIdxMask : '0;
      needForward[i]   = differentFlag[i] ? (~deqMask | forward_in[i].sqIdxMask)
                                          : (deqMask ^ forward_in[i].sqIdxMask);
      canForward1[i]   = forwardMask1[i] & allValidVec;
      canForward2[i]   = forwardMask2[i] & allValidVec;

      // store-set（LFST）：这条 load 被记录为「要等某条 store」。
      // ★KunminghuV2Config 下 LFSTEnable 是常真★，golden 只留了 loadWaitBit 这一支，
      // storeSetHit/ssid 那一支整块被 Constantin 折成常量消掉了。
      for (int j = 0; j < SQ_SIZE; j++)
        storeSetHitVec[i][j] = forward_in[i].uop_loadWaitBit
                             & ({uop_robIdx_flag[j], uop_robIdx_value[j]}
                                == {forward_in[i].uop_waitForRobIdx_flag,
                                    forward_in[i].uop_waitForRobIdx_value});

      // 地址命中但数据还没写进来 -> dataInvalid，load 要等。
      // ★第二项是 golden 的一条怪规则★：**任何**已分配的非对齐 store 都无条件
      //   算作 dataInvalid，不管地址是否重叠。Chisel 原注释承认这是"very unreasonable"
      //   的临时做法。照抄，不许"优化"成按地址判。
      dataInvalidMask1[i] = ((addrValidVec & ~dataValidVec & vaddrModule_forwardMmask[i])
                             | (unaligned & allocated)) & forwardMask1[i];
      dataInvalidMask2[i] = ((addrValidVec & ~dataValidVec & vaddrModule_forwardMmask[i])
                             | (unaligned & allocated)) & forwardMask2[i];

      // store-set 命中但地址还没写进来 -> addrInvalid。
      addrInvalidMask1[i] = ~addrValidVec & storeSetHitVec[i] & forwardMask1[i];
      addrInvalidMask2[i] = ~addrValidVec & storeSetHitVec[i] & forwardMask2[i];

      hasInvalidAddr[i]   = |(~addrValidVec & needForward[i]);
    end
  end

  // ---- ★perf 观测探针：必须按 golden 的名字导出★（见 §TRAP-D2）----
  // vpmaskNotEqual：vaddr CAM 与 paddr CAM 的命中掩码在「本次真要转发的位」上不同
  //   -> 说明虚实地址的低位别名判断出了岔子，load 拿到的转发数据不可信。
  // 三级打拍都要照抄：两个 mmask 是 RegEnable(·, forward.valid)，needForward 是
  // 无条件 RegNext，addrRealValidVec 是 GatedRegNext（带「变了才写」的使能）。
  logic [N_FWD-1:0] vpmaskNotEqualVec, vaddrMatchFailedVec;
  always_comb begin
    for (int i = 0; i < N_FWD; i++) begin
      vpmaskNotEqualVec[i]   = |((fwdPaddrMmask_q[i] ^ fwdVaddrMmask_q[i])
                                 & needForward_q[i] & addrRealValid_q[i]);
      vaddrMatchFailedVec[i] = vpmaskNotEqualVec[i] & fwdValid_q[i];
    end
  end
  // 单根导出，名字与 golden 的 perf 探针逐字相同 —— docs/perf_bore_map.tsv 按名字
  // 重绑到这里。★不许接零冒充已绑★。
  wire vpmaskNotEqual_probe     = vpmaskNotEqualVec[0];
  wire vpmaskNotEqual_1_probe   = vpmaskNotEqualVec[1];
  wire vpmaskNotEqual_2_probe   = vpmaskNotEqualVec[2];
  wire vaddrMatchFailed_probe   = vaddrMatchFailedVec[0];
  wire vaddrMatchFailed_1_probe = vaddrMatchFailedVec[1];
  wire vaddrMatchFailed_2_probe = vaddrMatchFailedVec[2];

  // ---- 转发结果与两个「谁挡住了我」的 sqIdx ----
  // 挑的是**最年轻**的那个挡路者（OHToUInt(Reverse(PriorityEncoderOH(Reverse(x))))
  // 就是最高置位下标）；段 2 比段 1 年轻，所以段 2 有人就用段 2。
  always_comb begin
    for (int i = 0; i < N_FWD; i++) begin
      automatic logic       aFlag, dFlag;
      automatic logic [5:0] aIdx,  dIdx;
      automatic logic       aInvalidFlag, dInvalidFlag;

      aInvalidFlag = |(addrInvalidMask1Reg[i] | addrInvalidMask2Reg[i]);
      dInvalidFlag = |(dataInvalidMask1Reg[i] | dataInvalidMask2Reg[i]);
      aIdx = (|addrInvalidMask2Reg[i]) ? sq_highest_set(addrInvalidMask2Reg[i])
                                       : sq_highest_set(addrInvalidMask1Reg[i]);
      dIdx = (|dataInvalidMask2Reg[i]) ? sq_highest_set(dataInvalidMask2Reg[i])
                                       : sq_highest_set(dataInvalidMask1Reg[i]);
      addrInvalidFlag[i]  = aInvalidFlag;
      dataInvalidFlag[i]  = dInvalidFlag;
      addrInvalidSqIdx[i] = aIdx;
      dataInvalidSqIdx[i] = dIdx;
      // 下标落在哪一圈：没跨圈、或者下标还在 deqPtr 之后 -> 用 deq 侧的 flag；
      // 否则说明它在绕回来的那一段 -> 用 enq 侧的 flag。
      aFlag = (~s2_differentFlag[i] | (aIdx >= s2_deqPtr[i].value)) ? s2_deqPtr[i].flag
                                                                   : s2_enqPtrFlag[i];
      dFlag = (~s2_differentFlag[i] | (dIdx >= s2_deqPtr[i].value)) ? s2_deqPtr[i].flag
                                                                   : s2_enqPtrFlag[i];

      // 16 个字节道的转发掩码/数据直接来自 dataModule（§1.2 的结构体按 golden
      // 端口逐根展开，packed struct 的字段不能下标访问，所以这 32 行只能摊开写；
      // 摊开的是**字段名**，不是逻辑 —— 三个口共用这一段循环体）。
      forward_out[i].forwardMask_0  = dataModule_forwardMask[i][0];
      forward_out[i].forwardMask_1  = dataModule_forwardMask[i][1];
      forward_out[i].forwardMask_2  = dataModule_forwardMask[i][2];
      forward_out[i].forwardMask_3  = dataModule_forwardMask[i][3];
      forward_out[i].forwardMask_4  = dataModule_forwardMask[i][4];
      forward_out[i].forwardMask_5  = dataModule_forwardMask[i][5];
      forward_out[i].forwardMask_6  = dataModule_forwardMask[i][6];
      forward_out[i].forwardMask_7  = dataModule_forwardMask[i][7];
      forward_out[i].forwardMask_8  = dataModule_forwardMask[i][8];
      forward_out[i].forwardMask_9  = dataModule_forwardMask[i][9];
      forward_out[i].forwardMask_10 = dataModule_forwardMask[i][10];
      forward_out[i].forwardMask_11 = dataModule_forwardMask[i][11];
      forward_out[i].forwardMask_12 = dataModule_forwardMask[i][12];
      forward_out[i].forwardMask_13 = dataModule_forwardMask[i][13];
      forward_out[i].forwardMask_14 = dataModule_forwardMask[i][14];
      forward_out[i].forwardMask_15 = dataModule_forwardMask[i][15];
      forward_out[i].forwardData_0  = dataModule_forwardData[i][0];
      forward_out[i].forwardData_1  = dataModule_forwardData[i][1];
      forward_out[i].forwardData_2  = dataModule_forwardData[i][2];
      forward_out[i].forwardData_3  = dataModule_forwardData[i][3];
      forward_out[i].forwardData_4  = dataModule_forwardData[i][4];
      forward_out[i].forwardData_5  = dataModule_forwardData[i][5];
      forward_out[i].forwardData_6  = dataModule_forwardData[i][6];
      forward_out[i].forwardData_7  = dataModule_forwardData[i][7];
      forward_out[i].forwardData_8  = dataModule_forwardData[i][8];
      forward_out[i].forwardData_9  = dataModule_forwardData[i][9];
      forward_out[i].forwardData_10 = dataModule_forwardData[i][10];
      forward_out[i].forwardData_11 = dataModule_forwardData[i][11];
      forward_out[i].forwardData_12 = dataModule_forwardData[i][12];
      forward_out[i].forwardData_13 = dataModule_forwardData[i][13];
      forward_out[i].forwardData_14 = dataModule_forwardData[i][14];
      forward_out[i].forwardData_15 = dataModule_forwardData[i][15];

      forward_out[i].dataInvalid  = fwdDataInvalid_q[i];
      forward_out[i].matchInvalid = vaddrMatchFailedVec[i];

      // loadWaitStrict：这条 load 要等**所有**更老的 store，不看具体是谁。
      forward_out[i].addrInvalid  = fwdLoadWaitStrict_inv_q[i] ? fwdHasInvalidAddr_q[i]
                                                               : aInvalidFlag;

      // ★这三个选择必须写成三目表达式，不能写成 if/else★
      //   aInvalidFlag / dInvalidFlag 是 `|mask` 的结果，mask 里**真的会有 X**
      //   （见 sq_highest_set 的注释）。`|X…` 是 X，三目会把 X 传下去，
      //   而 if/else 会把 X 当假、直接走 else 分支，凭空给出一个确定值。
      //   实测：写成 if 的版本在 3 个 forward 口上共 191 拍报失配。
      forward_out[i].addrInvalidSqIdx_flag  =
          fwdLoadWaitStrict_sel_q[i] ? fwdSqIdxMinus1_q[i].flag
        : aInvalidFlag               ? aFlag
                                     // 那条 store 可能早就写进 sbuffer 走了 ——
                                     // 回自己的 sqIdx，不阻塞。
                                     : fwdSqIdxA_q[i].flag;
      forward_out[i].addrInvalidSqIdx_value =
          fwdLoadWaitStrict_sel_q[i] ? fwdSqIdxMinus1_q[i].value
        : aInvalidFlag               ? aIdx
                                     : fwdSqIdxA_q[i].value;
      forward_out[i].dataInvalidSqIdx_flag  = dInvalidFlag ? dFlag : fwdSqIdxD_q[i].flag;
      forward_out[i].dataInvalidSqIdx_value = dInvalidFlag ? dIdx  : fwdSqIdxD_q[i].value;
    end
  end

// -----------------------------------------------------------------------------
// §10 mmio / NC / CBO —— 三条共用 uncache 通道的出队路径
// -----------------------------------------------------------------------------
  // 可缓存 store 走 dataBuffer -> Sbuffer（§12）。不可缓存的三类走这里：
  //   mmio ：等到它成为 ROB 头（pendingst）才发请求，回来后经 mmioStout 回写 ROB
  //   NC   ：提交后就能发，但因为还要给 load 做转发，必须等 resp 回来才退队
  //   CBO  ：cbo.clean/flush/inval 走 cmoOpReq 专用口，**越权覆盖** mmio FSM 的迁移
  // 三者共用一个 5 态 FSM（mmioState）+ 一个 4 态 FSM（ncState）。

  assign mmioIsCboZero = (uop_fuOpType[deqPtr][3:0] == 4'h7);           // LSUOpType.isCboZero
  assign deqCanDoCbo   = deqCanDoCboReg & memBackTypeMM[deqPtr];

  // uncache 请求的两个来源，mmio 优先。
  assign mmioReq_valid = (mmioState == S_REQ)
                       & ~(&uop_fuOpType[deqPtr][3:2] & ~(|uop_fuOpType[deqPtr][6:4])) // !isCbo
                       & ~io_wfi_wfiReq;
  assign ncReq_valid   = (ncState == NC_REQ) & ~io_wfi_wfiReq;

  // ★CBO 在发 cmoOpReq 时要把 uncache 通道整个关掉★（否则同一拍两条请求）。
  assign io_uncache_req_valid = ~deqCanDoCbo & (mmioReq_valid | ncReq_valid);

  assign mmioDoReq = io_uncache_req_ready & io_uncache_req_valid &  mmioReq_valid;
  assign ncDoReq   = io_uncache_req_ready & io_uncache_req_valid & ~mmioReq_valid;

  // uncache.resp.ready 恒 1（golden 已把它常量折掉，端口都没留），所以
  // resp.fire == resp.valid。
  assign ncRespFire     = io_uncache_resp_valid & io_uncache_resp_bits_nc;
  assign ncDoResp       = ncRespFire;
  assign ncSlaveAck     = io_uncache_idResp_valid & io_uncache_idResp_bits_nc;
  assign ncSlaveAckMid  = io_uncache_idResp_bits_mid;
  // outstanding 模式下 ubuffer 一收下就算完事，非 outstanding 要等真正的 resp。
  assign ncDeqTrigger   = io_uncacheOutstanding ? ncSlaveAck    : ncDoResp;
  assign ncPtr          = io_uncacheOutstanding ? ncSlaveAckMid : ncWaitRespPtrReg;

  // ---- 两条请求的载荷 ----
  // cbo.zero 要往整条 cache line 写 0，所以地址是 block 基址 + offset*8，一共 8 拍。
  always_comb begin
    mmioReq_addr  = mmioIsCboZero ? (cboMmioPAddr + {42'h0, cboZeroOffset, 3'h0})
                                  : paddrModule_rdata[0];
    mmioReq_vaddr = mmioIsCboZero ? ({vaddrModule_rdata[0][49:6], 6'h0} + {44'h0, cboZeroOffset, 3'h0})
                                  : vaddrModule_rdata[0];
    // shiftDataToLow / shiftMaskToLow：按 paddr 的第 3 位挑 128 位里的哪半边。
    mmioReq_data  = mmioIsCboZero ? 64'h0
                                  : (paddrModule_rdata[0][3] ? dataModule_rdata_data[0][127:64]
                                                             : dataModule_rdata_data[0][63:0]);
    mmioReq_mask  = mmioIsCboZero ? 8'hFF
                                  : (paddrModule_rdata[0][3] ? dataModule_rdata_mask[0][15:8]
                                                             : dataModule_rdata_mask[0][7:0]);
    mmioReq_id    = {1'h0, rdataPtrExt[0].value};

    ncReq_addr    = paddrModule_rdata[0];
    ncReq_vaddr   = vaddrModule_rdata[0];
    ncReq_data    = paddrModule_rdata[0][3] ? dataModule_rdata_data[0][127:64]
                                            : dataModule_rdata_data[0][63:0];
    ncReq_mask    = paddrModule_rdata[0][3] ? dataModule_rdata_mask[0][15:8]
                                            : dataModule_rdata_mask[0][7:0];
  end

  // robIdx / memBackTypeMM 取的是**提前一拍的读指针再打一拍**（GatedRegNext(rdataPtrExtNext(0))），
  // 不是 rdataPtrExt(0) 的当拍值。golden 为两条通路、两个用途各摇了一份寄存器，
  // 这里照抄成 4 份（§TRAP-F 的同一类坑）。
  assign mmioReq_robIdx_flag  = uop_robIdx_flag [mmioReqRobIdxPtr.value];
  assign mmioReq_robIdx_value = uop_robIdx_value[mmioReqRobIdxPtr.value];
  assign mmioReq_memBackTypeMM= memBackTypeMM   [mmioReqMemBackPtr.value];
  assign ncReq_robIdx_flag    = uop_robIdx_flag [ncReqRobIdxPtr.value];
  assign ncReq_robIdx_value   = uop_robIdx_value[ncReqRobIdxPtr.value];
  assign ncReq_memBackTypeMM  = memBackTypeMM   [ncReqMemBackPtr.value];

  // ---- CBO.zero 走的是 sbuffer 通路（wline 整行写），不是 uncache 通道 ----
  always_comb begin
    for (int i = 0; i < N_ENSBUF; i++)
      isCboZeroToSbVec[i] = sbufferFire[i]
                          & dataBuffer_deq_vecValid[i]
                          & sbufferWline[i]          // ★是 &vecValid 之后的那根★
                          & allocated    [dataBuffer_deq_sqPtr[i].value]
                          & memBackTypeMM[dataBuffer_deq_sqPtr[i].value];
    cboZeroToSb = |isCboZeroToSbVec;
  end

  // ---- 输出 ----
  assign io_cmoOpReq_valid       = deqCanDoCbo & cboFlushedSb & (mmioState == S_REQ)
                                 & ~io_wfi_wfiReq;
  assign io_cmoOpReq_bits_opcode = {1'h0, uncacheUop_fuOpType[1:0]};
  assign io_cmoOpReq_bits_address= {16'h0, cboMmioPAddr};
  assign io_cmoOpResp_ready      = deqCanDoCbo & (mmioState == S_RESP);
  // CBO 发请求前要先把 Sbuffer 冲干净（保证顺序）；cbo.zero 写完也要冲一次。
  assign io_flushSbuffer_valid   = (deqCanDoCbo & ~cboFlushedSb & (mmioState == S_REQ)
                                    & ~io_flushSbuffer_empty)
                                 | cboZeroFlushSb;

  assign mmioStoutValid   = (mmioState == S_WB) & ~isVec[deqPtr];
  assign mmioStoutFire    = mmioStoutValid & io_mmioStout_ready;
  assign cboZeroStoutValid= cboZeroValid & ~cboZeroWaitFlushSb;
  assign cboZeroStoutFire = cboZeroStoutValid & io_cboZeroStout_ready;

  assign io_rob_storeMmio             = mmioReq_valid;
  assign io_rob_storeMmioUop_robIdx_value = uncacheUop_robIdx_value;

// -----------------------------------------------------------------------------
// §11 ROB 提交 —— 把 cmtPtr 起的连续 8 条标成 committed
// -----------------------------------------------------------------------------
  // committed 之后这条 store 就不可撤销了（needCancel 不再碰它），可以往下走。
  // 8 个槽是**串行链**：第 i 槽只有在第 i-1 槽也提交了的情况下才算提交
  // （commitVec(i) := commitVec(i-1)），所以中间卡住一条后面全停。
  logic [SQ_SIZE-1:0] commitWrEn, commitWrVal;

  always_comb begin
    commitWrEn      = '0;
    commitWrVal     = '0;
    commitNcExcDone = '0;
    commitVec       = '0;
    isCommit        = '0;
    for (int i = 0; i < N_COMMIT; i++) begin
      automatic logic [5:0] ptr    = cmtPtrValue[i];
      automatic logic       notAfter =
        ~rob_after(uop_robIdx_flag[ptr], uop_robIdx_value[ptr],
                   pendingPtrReg_flag[i], pendingPtrReg_value[i]);
      // waitStoreS2：标量 store 必须等到 store_s2 把 mmio/异常裁决写回来才准提交；
      // 向量 store 不受这条限制。
      automatic logic       baseOk = allocated[ptr] & notAfter & ~needCancel[ptr]
                                   & (~waitStoreS2[ptr] | isVec[ptr]);
      automatic logic       vecOk  = (isVec[ptr] & vecMbCommit[ptr]) | ~isVec[ptr];
      if (i == 0) begin
        // 第 0 槽还要让开 mmio：mmio 没做完不许提交（否则 mmio 指令会被越过去）。
        if (baseOk & ((mmioState == S_IDLE) | ((mmioState == S_WAIT) & (|scommit))) & vecOk) begin
          isCommit[0]      = 1'b1;
          commitVec[0]     = 1'b1;
          commitWrEn[ptr]  = 1'b1;
          commitWrVal[ptr] = 1'b1;
        end
      end
      else begin
        if (baseOk & vecOk) begin
          isCommit[i]      = commitVec[i-1] | committed[ptr];
          commitVec[i]     = commitVec[i-1];
          commitWrEn[ptr]  = 1'b1;
          commitWrVal[ptr] = commitVec[i-1] | committed[ptr];
        end
      end
      // NC 且带异常的：不用真去发请求，提交的同时直接算「完成」。
      if (isCommit[i] & nc[ptr] & hasException[ptr]) commitNcExcDone[ptr] = 1'b1;
    end
  end

  assign commitCount = 4'($countones(commitVec));
  assign commitSet   = commitWrEn & commitWrVal;


// -----------------------------------------------------------------------------
// §12 出队：读 RAM -> dataBuffer -> Sbuffer
// -----------------------------------------------------------------------------
  // 三个指针各司其职（★最容易写错的一段★，见 §TRAP-F）：
  //   rdataPtrExt  读指针。RAM 的读地址用的是 **rdataPtrExtNext**（提前一拍），
  //                模块内部再寄存一次才拿到数据。
  //   deqPtrExt    退队指针。比 rdataPtr 晚：数据真正写进 Sbuffer 才推进。
  //   cmtPtrExt    提交指针。
  // readyReadGoVec：本拍读指针能前进几条。
  //   口 0：进了 dataBuffer（且该条需要退队）/ 是已完成的 NC / mmio 回写了
  //   口 1：同上，但 **NC 那一支**额外要求口 0 也走了（口 0 卡住时不许跳号）
  always_comb begin
    readyReadGoVec[0] = (dataBuffer_enq_fire[0] & dataBuffer_enq_sqNeedDeq[0])
                      | (allocated[rdataPtrExt[0].value] & completed[rdataPtrExt[0].value]
                         & nc[rdataPtrExt[0].value])
                      | mmioStoutFire;   // vecmmioStout 恒 0（golden 已折掉），不再列
    readyReadGoVec[1] = (dataBuffer_enq_fire[1] & dataBuffer_enq_sqNeedDeq[1])
                      | (allocated[rdataPtrExt[1].value] & completed[rdataPtrExt[1].value]
                         & nc[rdataPtrExt[1].value] & readyReadGoVec[0]);
    sqReadCnt = 2'($countones(readyReadGoVec));
    for (int i = 0; i < N_ENSBUF; i++)
      rdataPtrExtNext[i] = sqptr_add(rdataPtrExt[i], {6'h0, sqReadCnt});
  end

  // 退队：两条都「已分配且已完成」才退 2 条，否则看第 0 条。
  always_comb begin
    deqClear = '0;
    sqDeqCnt = 2'd0;
    for (int i = 0; i < N_ENSBUF; i++)
      readyDeqVec[i] = allocated[deqPtrExt[i].value] & completed[deqPtrExt[i].value];
    // ★循环内后写者胜★：两条都就绪时 sqDeqCnt = 2。
    for (int i = 0; i < N_ENSBUF; i++) begin
      automatic logic allReady = 1'b1;
      for (int k = 0; k <= i; k++) allReady = allReady & readyDeqVec[k];
      if (allReady) begin
        sqDeqCnt = 2'(i + 1);
        deqClear[deqPtrExt[i].value] = 1'b1;
      end
    end
    for (int i = 0; i < N_ENSBUF; i++)
      deqPtrExtNext[i] = sqptr_add(deqPtrExt[i], {6'h0, sqDeqCnt});
  end

// -----------------------------------------------------------------------------
// §13 dataBuffer 入口：三分支（跨 16B 拆分 / 非跨 16B 的非对齐 / 常规）
// -----------------------------------------------------------------------------
  // 非对齐 store 的三种处置：
  //  (1) 跨 16 字节：一条 store 拆成**两拍**送 dataBuffer（低半 + 高半），
  //      两拍都挂在 rdataPtrExt(0) 名下，只有第二拍带 sqNeedDeq。
  //      再跨 4K 页时高半的 paddr 要问 StoreMisalignBuffer 要（本模块算不出来）。
  //  (2) 不跨 16 字节的非对齐：把数据左移对齐到 16B 边界，一拍搞定。
  //  (3) 常规：直接原样送。
  logic               canDeqMisaligned, firstWithMisalign, firstWithCross16Byte;
  logic               isCross4KPage, isCross4KPageCanDeq;
  logic               misalignToDataBufferValid;
  logic [31:0]        cross16ByteMask;
  logic [255:0]       cross16ByteData;
  logic [47:0]        paddrLow, paddrHigh;
  logic [49:0]        vaddrLow, vaddrHigh;
  logic [N_ENSBUF-1:0] toSbufferVecValid;

  assign canDeqMisaligned     = dataBuffer_enq_ready[0] & dataBuffer_enq_ready[1];
  assign firstWithMisalign    = unaligned  [rdataPtrExt[0].value];
  assign firstWithCross16Byte = cross16Byte[rdataPtrExt[0].value];
  assign isCross4KPage        = io_maControl_toStoreQueue_crossPageWithHit;
  assign isCross4KPageCanDeq  = io_maControl_toStoreQueue_crossPageCanDeq;

  always_comb begin
    automatic logic [3:0] lowAddr4 = vaddrModule_rdata[0][3:0];
    cross16ByteMask = {16'h0, dataModule_rdata_mask[0]} << lowAddr4;
    cross16ByteData = {128'h0, dataModule_rdata_data[0]} << {lowAddr4, 3'h0};
    paddrLow  = {paddrModule_rdata[0][47:3], 3'h0};
    paddrHigh = {paddrModule_rdata[0][47:3], 3'h0} + 48'h8;
    vaddrLow  = {vaddrModule_rdata[0][49:3], 3'h0};
    vaddrHigh = {vaddrModule_rdata[0][49:3], 3'h0} + 50'h8;
  end

  assign misalignToDataBufferValid =
      allocated[rdataPtrExt[0].value] & committed[rdataPtrExt[0].value]
    & ((~isVec[rdataPtrExt[0].value] & allvalid[rdataPtrExt[0].value])
       | vecMbCommit[rdataPtrExt[0].value])
    & canDeqMisaligned
    & (~isCross4KPage | isCross4KPageCanDeq | hasException[rdataPtrExt[0].value]);

  always_comb begin
    for (int i = 0; i < N_ENSBUF; i++) begin
      automatic logic [5:0] ptr = rdataPtrExt[i].value;
      automatic logic mmioStall, ncStall, exceptionValid, vecFlagHit;

      // 口 1 要连口 0 一起看：mmio/NC 一旦出现在这一组里，整组都不许走 Sbuffer。
      mmioStall = (i == 0) ? mmio[rdataPtrExt[0].value]
                           : (mmio[rdataPtrExt[1].value] | mmio[rdataPtrExt[0].value]);
      ncStall   = (i == 0) ? nc[rdataPtrExt[0].value]
                           : (nc[rdataPtrExt[1].value] | nc[rdataPtrExt[0].value]);
      // 同一条向量指令的后续 flow 也要一起挡住（robIdx 相同才算同一条）。
      exceptionValid = (i == 0)
        ? hasException[rdataPtrExt[0].value]
        : (hasException[rdataPtrExt[1].value]
           | (hasException[rdataPtrExt[0].value]
              & ({uop_robIdx_flag[rdataPtrExt[1].value], uop_robIdx_value[rdataPtrExt[1].value]}
                 == {uop_robIdx_flag[rdataPtrExt[0].value], uop_robIdx_value[rdataPtrExt[0].value]})));
      vecFlagHit = vecExceptionFlag_valid & isVec[ptr]
                 & ({vecExceptionFlag_robIdx_flag, vecExceptionFlag_robIdx_value}
                    == {uop_robIdx_flag[ptr], uop_robIdx_value[ptr]});

      // 真正写进 Sbuffer 的位（vecValid=0 表示「走个过场，别写内存」）
      toSbufferVecValid[i] =
          (~isVec[ptr] | (vecMbCommit[ptr] & allvalid[ptr] & (|dataModule_rdata_mask[i])))
        & ~exceptionValid & ~vecFlagHit;

      // ---- valid ----
      if (firstWithMisalign & firstWithCross16Byte)
        dataBuffer_enq_valid[i] = misalignToDataBufferValid;
      else
        dataBuffer_enq_valid[i] =
            allocated[ptr] & committed[ptr]
          & ((~isVec[ptr] & (allvalid[ptr] | hasException[ptr])) | vecMbCommit[ptr])
          & ~mmioStall & ~ncStall
          & (~unaligned[ptr] | (~cross16Byte[ptr] & (allvalid[ptr] | hasException[ptr])));

      // ---- bits ----
      if (canDeqMisaligned & firstWithMisalign & firstWithCross16Byte) begin
        // 跨 16B：两拍拆分，都挂 rdataPtrExt(0)
        dataBuffer_enq_wline[i]     = 1'b0;
        dataBuffer_enq_sqPtr[i]     = rdataPtrExt[0];
        dataBuffer_enq_sqNeedDeq[i] = (i != 0);
        if (i == 0) begin
          dataBuffer_enq_addr[0]     = paddrLow;
          dataBuffer_enq_vaddr[0]    = vaddrLow;
          dataBuffer_enq_data[0]     = cross16ByteData[127:0];
          dataBuffer_enq_mask[0]     = cross16ByteMask[15:0];
          dataBuffer_enq_vecValid[0] = toSbufferVecValid[0];
        end
        else begin
          // 跨 4K 页时高半的物理地址只能由 StoreMisalignBuffer 给。
          dataBuffer_enq_addr[1]     = (isCross4KPage & isCross4KPageCanDeq)
                                     ? io_maControl_toStoreQueue_paddr : paddrHigh;
          dataBuffer_enq_vaddr[1]    = vaddrHigh;
          dataBuffer_enq_data[1]     = cross16ByteData[255:128];
          dataBuffer_enq_mask[1]     = cross16ByteMask[31:16];
          // ★高半跟着低半的 vecValid 走★（Chisel 直接引用 enq(0).bits.vecValid）
          dataBuffer_enq_vecValid[1] = toSbufferVecValid[0];
        end
      end
      else if (~cross16Byte[ptr] & unaligned[ptr]) begin
        // 不跨 16B 的非对齐：地址砍到 16B 边界，数据按低 4 位左移补齐
        dataBuffer_enq_addr[i]      = {paddrModule_rdata[i][47:4], 4'h0};
        dataBuffer_enq_vaddr[i]     = {vaddrModule_rdata[i][49:4], 4'h0};
        dataBuffer_enq_data[i]      = dataModule_rdata_data[i] << {vaddrModule_rdata[i][3:0], 3'h0};
        dataBuffer_enq_mask[i]      = dataModule_rdata_mask[i];
        dataBuffer_enq_wline[i]     = paddrModule_rlineflag[i];
        dataBuffer_enq_sqPtr[i]     = rdataPtrExt[i];
        dataBuffer_enq_sqNeedDeq[i] = 1'b1;
        dataBuffer_enq_vecValid[i]  = toSbufferVecValid[i];
      end
      else begin
        dataBuffer_enq_addr[i]      = paddrModule_rdata[i];
        dataBuffer_enq_vaddr[i]     = vaddrModule_rdata[i];
        dataBuffer_enq_data[i]      = dataModule_rdata_data[i];
        dataBuffer_enq_mask[i]      = dataModule_rdata_mask[i];
        dataBuffer_enq_wline[i]     = paddrModule_rlineflag[i];
        dataBuffer_enq_sqPtr[i]     = rdataPtrExt[i];
        dataBuffer_enq_sqNeedDeq[i] = 1'b1;
        dataBuffer_enq_vecValid[i]  = toSbufferVecValid[i];
      end

      dataBuffer_enq_fire[i] = dataBuffer_enq_valid[i] & dataBuffer_enq_ready[i];
    end
  end

  // ---- dataBuffer 出口 -> Sbuffer ----
  // ★DCacheWordReq.fromDataBufferEntry 里 wline := src.wline && src.vecValid★
  // —— 不是直通。少这个 & vecValid 会让「整行写」在向量无效流上误触发，
  // 进而经 isCboZeroToSbVec / completed 一路传到 deqPtr。
  always_comb begin
    for (int i = 0; i < N_ENSBUF; i++) begin
      sbufferWline[i]                = dataBuffer_deq_wline[i] & dataBuffer_deq_vecValid[i];
      sbufferFire[i]                 = dataBuffer_deq_valid[i] & sbuffer_in[i].ready;
      sbuffer_out[i].valid           = dataBuffer_deq_valid[i];
      sbuffer_out[i].bits_addr       = dataBuffer_deq_addr[i];
      sbuffer_out[i].bits_vaddr      = dataBuffer_deq_vaddr[i];
      sbuffer_out[i].bits_data       = dataBuffer_deq_data[i];
      sbuffer_out[i].bits_mask       = dataBuffer_deq_mask[i];
      sbuffer_out[i].bits_wline      = sbufferWline[i];
      sbuffer_out[i].bits_vecValid   = dataBuffer_deq_vecValid[i];
    end
  end

  // 跨 4K 页时要向 StoreMisalignBuffer 要高半页的 paddr。
  assign io_maControl_toStoreMisalignBuffer_sqPtr_flag  = rdataPtrExt[0].flag;
  assign io_maControl_toStoreMisalignBuffer_sqPtr_value = rdataPtrExt[0].value;
  assign io_maControl_toStoreMisalignBuffer_doDeq       =
      isCross4KPage & isCross4KPageCanDeq & dataBuffer_enq_fire[0];
  assign io_maControl_toStoreMisalignBuffer_uop_uopIdx      = uop_uopIdx     [rdataPtrExt[0].value];
  assign io_maControl_toStoreMisalignBuffer_uop_robIdx_flag = uop_robIdx_flag[rdataPtrExt[0].value];
  assign io_maControl_toStoreMisalignBuffer_uop_robIdx_value= uop_robIdx_value[rdataPtrExt[0].value];


// -----------------------------------------------------------------------------
// §14 difftest 观测口（difftest 关掉时整块是 DontCare，golden 里仍然留着端口）
// -----------------------------------------------------------------------------
  always_comb begin
    for (int i = 0; i < N_ENSBUF; i++) begin
      automatic logic [5:0] p = dataBuffer_enq_sqPtr[i].value;
      diffStore_diffInfo_out[i].uop_fuType       = uop_fuType[p];
      diffStore_diffInfo_out[i].uop_fuOpType     = uop_fuOpType[p];
      diffStore_diffInfo_out[i].uop_vpu_nf       = uop_vpu_nf[p];
      diffStore_diffInfo_out[i].uop_vpu_veew     = uop_vpu_veew[p];
      diffStore_diffInfo_out[i].uop_robIdx_value = uop_robIdx_value[p];
      diffStore_diffInfo_out[i].offset           = debug_vec_unaligned_offset[p];

      diffStore_pmaStore_out[i].valid          = dataBuffer_enq_fire[i];
      diffStore_pmaStore_out[i].bits_data      = dataBuffer_enq_data[i];
      diffStore_pmaStore_out[i].bits_mask      = dataBuffer_enq_mask[i];
      diffStore_pmaStore_out[i].bits_addr      = dataBuffer_enq_addr[i];
      // 同样是 fromDataBufferEntry：wline := wline && vecValid
      diffStore_pmaStore_out[i].bits_wline     = dataBuffer_enq_wline[i] & dataBuffer_enq_vecValid[i];
      diffStore_pmaStore_out[i].bits_vecValid  = dataBuffer_enq_vecValid[i];
    end
  end

  // NC / mmio 请求发出的那一拍，把它也报给 difftest（只报走真内存的那些）。
  logic ncReqFire, mmioReqFire;
  assign ncReqFire   = ncReq_valid   & io_uncache_req_ready & ~mmioReq_valid;
  assign mmioReqFire = mmioReq_valid & io_uncache_req_ready;
  assign io_diffStore_ncStore_valid = (ncReqFire   & ncReq_memBackTypeMM)
                                    | (mmioReqFire & mmioReq_memBackTypeMM);
  assign io_diffStore_ncStore_bits_addr = ncReqFire ? ncReq_addr : mmioReq_addr;
  assign io_diffStore_ncStore_bits_data = ncReqFire ? ncReq_data : mmioReq_data;
  assign io_diffStore_ncStore_bits_mask = ncReqFire ? ncReq_mask : mmioReq_mask;
  assign io_diffStore_ncStore_bits_memBackTypeMM =
      ncReqFire ? ncReq_memBackTypeMM : mmioReq_memBackTypeMM;

// -----------------------------------------------------------------------------
// §16 子模块例化 —— 5 个，实例名照 golden（dataModule / paddrModule /
//                  vaddrModule / dataBuffer / exceptionBuffer）
// -----------------------------------------------------------------------------
  // ★下面的端口连线块由 scratchpad/sqbuild/gen_inst.py 机械生成★：
  // golden 把 forwardMmask / forwardMask / forwardData 展平成 168+48 根扁平标量，
  // 一行一根不是啰嗦，是 FM 按名字配层次的硬约束（generate 循环会多出块名）。
  //
  //   dataModule      SQDataModule_xs   (56,rd2,wr2,fwd3)  内部 16×SQData8Module_xs 按字节分道
  //   paddrModule     SQAddrModule_xs   (dataWidth=48)     物理地址阵列 + 地址 CAM
  //   vaddrModule     SQAddrModule_1_xs (dataWidth=50)     虚地址阵列 + 地址 CAM（转发用它选）
  //   dataBuffer      DatamoduleResultBuffer_xs            SQ 读出级到 Sbuffer 的 2 项 skid
  //   exceptionBuffer StoreExceptionBuffer_xs              7 口单条目「最老者胜」异常地址锁存

  SQDataModule_xs dataModule (
    .clock            (clock),
    .reset            (reset),
    .io_raddr_0       (rdataPtrExtNext[0].value),
    .io_raddr_1       (rdataPtrExtNext[1].value),
    .io_rdata_0_mask  (dataModule_rdata_mask[0]),
    .io_rdata_0_data  (dataModule_rdata_data[0]),
    .io_rdata_1_mask  (dataModule_rdata_mask[1]),
    .io_rdata_1_data  (dataModule_rdata_data[1]),
    .io_data_wen_0     (stdFire[0]),
    .io_data_waddr_0   (stdWbIndex[0]),
    .io_data_wdata_0   (stdWdata[0]),
    .io_data_wen_1     (stdFire[1]),
    .io_data_waddr_1   (stdWbIndex[1]),
    .io_data_wdata_1   (stdWdata[1]),
    .io_mask_wen_0     (storeMaskIn_in[0].valid),
    .io_mask_waddr_0   (storeMaskIn_in[0].bits_sqIdx_value),
    .io_mask_wdata_0   (storeMaskIn_in[0].bits_mask),
    .io_mask_wen_1     (storeMaskIn_in[1].valid),
    .io_mask_waddr_1   (storeMaskIn_in[1].bits_sqIdx_value),
    .io_mask_wdata_1   (storeMaskIn_in[1].bits_mask),
    .io_needForward_0_0 (canForward1[0] & vaddrModule_forwardMmask[0]),
    .io_needForward_0_1 (canForward2[0] & vaddrModule_forwardMmask[0]),
    .io_needForward_1_0 (canForward1[1] & vaddrModule_forwardMmask[1]),
    .io_needForward_1_1 (canForward2[1] & vaddrModule_forwardMmask[1]),
    .io_needForward_2_0 (canForward1[2] & vaddrModule_forwardMmask[2]),
    .io_needForward_2_1 (canForward2[2] & vaddrModule_forwardMmask[2]),
    .io_forwardMask_0_0 (dataModule_forwardMask[0][0]),
    .io_forwardMask_0_1 (dataModule_forwardMask[0][1]),
    .io_forwardMask_0_2 (dataModule_forwardMask[0][2]),
    .io_forwardMask_0_3 (dataModule_forwardMask[0][3]),
    .io_forwardMask_0_4 (dataModule_forwardMask[0][4]),
    .io_forwardMask_0_5 (dataModule_forwardMask[0][5]),
    .io_forwardMask_0_6 (dataModule_forwardMask[0][6]),
    .io_forwardMask_0_7 (dataModule_forwardMask[0][7]),
    .io_forwardMask_0_8 (dataModule_forwardMask[0][8]),
    .io_forwardMask_0_9 (dataModule_forwardMask[0][9]),
    .io_forwardMask_0_10 (dataModule_forwardMask[0][10]),
    .io_forwardMask_0_11 (dataModule_forwardMask[0][11]),
    .io_forwardMask_0_12 (dataModule_forwardMask[0][12]),
    .io_forwardMask_0_13 (dataModule_forwardMask[0][13]),
    .io_forwardMask_0_14 (dataModule_forwardMask[0][14]),
    .io_forwardMask_0_15 (dataModule_forwardMask[0][15]),
    .io_forwardMask_1_0 (dataModule_forwardMask[1][0]),
    .io_forwardMask_1_1 (dataModule_forwardMask[1][1]),
    .io_forwardMask_1_2 (dataModule_forwardMask[1][2]),
    .io_forwardMask_1_3 (dataModule_forwardMask[1][3]),
    .io_forwardMask_1_4 (dataModule_forwardMask[1][4]),
    .io_forwardMask_1_5 (dataModule_forwardMask[1][5]),
    .io_forwardMask_1_6 (dataModule_forwardMask[1][6]),
    .io_forwardMask_1_7 (dataModule_forwardMask[1][7]),
    .io_forwardMask_1_8 (dataModule_forwardMask[1][8]),
    .io_forwardMask_1_9 (dataModule_forwardMask[1][9]),
    .io_forwardMask_1_10 (dataModule_forwardMask[1][10]),
    .io_forwardMask_1_11 (dataModule_forwardMask[1][11]),
    .io_forwardMask_1_12 (dataModule_forwardMask[1][12]),
    .io_forwardMask_1_13 (dataModule_forwardMask[1][13]),
    .io_forwardMask_1_14 (dataModule_forwardMask[1][14]),
    .io_forwardMask_1_15 (dataModule_forwardMask[1][15]),
    .io_forwardMask_2_0 (dataModule_forwardMask[2][0]),
    .io_forwardMask_2_1 (dataModule_forwardMask[2][1]),
    .io_forwardMask_2_2 (dataModule_forwardMask[2][2]),
    .io_forwardMask_2_3 (dataModule_forwardMask[2][3]),
    .io_forwardMask_2_4 (dataModule_forwardMask[2][4]),
    .io_forwardMask_2_5 (dataModule_forwardMask[2][5]),
    .io_forwardMask_2_6 (dataModule_forwardMask[2][6]),
    .io_forwardMask_2_7 (dataModule_forwardMask[2][7]),
    .io_forwardMask_2_8 (dataModule_forwardMask[2][8]),
    .io_forwardMask_2_9 (dataModule_forwardMask[2][9]),
    .io_forwardMask_2_10 (dataModule_forwardMask[2][10]),
    .io_forwardMask_2_11 (dataModule_forwardMask[2][11]),
    .io_forwardMask_2_12 (dataModule_forwardMask[2][12]),
    .io_forwardMask_2_13 (dataModule_forwardMask[2][13]),
    .io_forwardMask_2_14 (dataModule_forwardMask[2][14]),
    .io_forwardMask_2_15 (dataModule_forwardMask[2][15]),
    .io_forwardData_0_0 (dataModule_forwardData[0][0]),
    .io_forwardData_0_1 (dataModule_forwardData[0][1]),
    .io_forwardData_0_2 (dataModule_forwardData[0][2]),
    .io_forwardData_0_3 (dataModule_forwardData[0][3]),
    .io_forwardData_0_4 (dataModule_forwardData[0][4]),
    .io_forwardData_0_5 (dataModule_forwardData[0][5]),
    .io_forwardData_0_6 (dataModule_forwardData[0][6]),
    .io_forwardData_0_7 (dataModule_forwardData[0][7]),
    .io_forwardData_0_8 (dataModule_forwardData[0][8]),
    .io_forwardData_0_9 (dataModule_forwardData[0][9]),
    .io_forwardData_0_10 (dataModule_forwardData[0][10]),
    .io_forwardData_0_11 (dataModule_forwardData[0][11]),
    .io_forwardData_0_12 (dataModule_forwardData[0][12]),
    .io_forwardData_0_13 (dataModule_forwardData[0][13]),
    .io_forwardData_0_14 (dataModule_forwardData[0][14]),
    .io_forwardData_0_15 (dataModule_forwardData[0][15]),
    .io_forwardData_1_0 (dataModule_forwardData[1][0]),
    .io_forwardData_1_1 (dataModule_forwardData[1][1]),
    .io_forwardData_1_2 (dataModule_forwardData[1][2]),
    .io_forwardData_1_3 (dataModule_forwardData[1][3]),
    .io_forwardData_1_4 (dataModule_forwardData[1][4]),
    .io_forwardData_1_5 (dataModule_forwardData[1][5]),
    .io_forwardData_1_6 (dataModule_forwardData[1][6]),
    .io_forwardData_1_7 (dataModule_forwardData[1][7]),
    .io_forwardData_1_8 (dataModule_forwardData[1][8]),
    .io_forwardData_1_9 (dataModule_forwardData[1][9]),
    .io_forwardData_1_10 (dataModule_forwardData[1][10]),
    .io_forwardData_1_11 (dataModule_forwardData[1][11]),
    .io_forwardData_1_12 (dataModule_forwardData[1][12]),
    .io_forwardData_1_13 (dataModule_forwardData[1][13]),
    .io_forwardData_1_14 (dataModule_forwardData[1][14]),
    .io_forwardData_1_15 (dataModule_forwardData[1][15]),
    .io_forwardData_2_0 (dataModule_forwardData[2][0]),
    .io_forwardData_2_1 (dataModule_forwardData[2][1]),
    .io_forwardData_2_2 (dataModule_forwardData[2][2]),
    .io_forwardData_2_3 (dataModule_forwardData[2][3]),
    .io_forwardData_2_4 (dataModule_forwardData[2][4]),
    .io_forwardData_2_5 (dataModule_forwardData[2][5]),
    .io_forwardData_2_6 (dataModule_forwardData[2][6]),
    .io_forwardData_2_7 (dataModule_forwardData[2][7]),
    .io_forwardData_2_8 (dataModule_forwardData[2][8]),
    .io_forwardData_2_9 (dataModule_forwardData[2][9]),
    .io_forwardData_2_10 (dataModule_forwardData[2][10]),
    .io_forwardData_2_11 (dataModule_forwardData[2][11]),
    .io_forwardData_2_12 (dataModule_forwardData[2][12]),
    .io_forwardData_2_13 (dataModule_forwardData[2][13]),
    .io_forwardData_2_14 (dataModule_forwardData[2][14]),
    .io_forwardData_2_15 (dataModule_forwardData[2][15])
  );

  SQAddrModule_xs paddrModule (
    .clock                (clock),
    .reset                (reset),
    .io_raddr_0           (rdataPtrExtNext[0].value),
    .io_raddr_1           (rdataPtrExtNext[1].value),
    .io_rdata_0           (paddrModule_rdata[0]),
    .io_rdata_1           (paddrModule_rdata[1]),
    .io_rlineflag_0       (paddrModule_rlineflag[0]),
    .io_rlineflag_1       (paddrModule_rlineflag[1]),
    .io_wen_0             (staWen[0]),
    .io_wen_1             (staWen[1]),
    .io_waddr_0           (stWbIndex[0]),
    .io_waddr_1           (stWbIndex[1]),
    .io_wdata_0           (storeAddrIn_in[0].bits_paddr),
    .io_wdata_1           (storeAddrIn_in[1].bits_paddr),
    .io_wmask_0           (storeAddrIn_in[0].bits_mask),
    .io_wmask_1           (storeAddrIn_in[1].bits_mask),
    .io_wlineflag_0       (storeAddrIn_in[0].bits_wlineflag),
    .io_wlineflag_1       (storeAddrIn_in[1].bits_wlineflag),
    .io_forwardMdata_0    (forward_in[0].paddr),
    .io_forwardMdata_1    (forward_in[1].paddr),
    .io_forwardMdata_2    (forward_in[2].paddr),
    .io_forwardDataMask_0 (forward_in[0].mask),
    .io_forwardDataMask_1 (forward_in[1].mask),
    .io_forwardDataMask_2 (forward_in[2].mask),
    .io_forwardMmask_0_0 (paddrModule_forwardMmask[0][0]),
    .io_forwardMmask_0_1 (paddrModule_forwardMmask[0][1]),
    .io_forwardMmask_0_2 (paddrModule_forwardMmask[0][2]),
    .io_forwardMmask_0_3 (paddrModule_forwardMmask[0][3]),
    .io_forwardMmask_0_4 (paddrModule_forwardMmask[0][4]),
    .io_forwardMmask_0_5 (paddrModule_forwardMmask[0][5]),
    .io_forwardMmask_0_6 (paddrModule_forwardMmask[0][6]),
    .io_forwardMmask_0_7 (paddrModule_forwardMmask[0][7]),
    .io_forwardMmask_0_8 (paddrModule_forwardMmask[0][8]),
    .io_forwardMmask_0_9 (paddrModule_forwardMmask[0][9]),
    .io_forwardMmask_0_10 (paddrModule_forwardMmask[0][10]),
    .io_forwardMmask_0_11 (paddrModule_forwardMmask[0][11]),
    .io_forwardMmask_0_12 (paddrModule_forwardMmask[0][12]),
    .io_forwardMmask_0_13 (paddrModule_forwardMmask[0][13]),
    .io_forwardMmask_0_14 (paddrModule_forwardMmask[0][14]),
    .io_forwardMmask_0_15 (paddrModule_forwardMmask[0][15]),
    .io_forwardMmask_0_16 (paddrModule_forwardMmask[0][16]),
    .io_forwardMmask_0_17 (paddrModule_forwardMmask[0][17]),
    .io_forwardMmask_0_18 (paddrModule_forwardMmask[0][18]),
    .io_forwardMmask_0_19 (paddrModule_forwardMmask[0][19]),
    .io_forwardMmask_0_20 (paddrModule_forwardMmask[0][20]),
    .io_forwardMmask_0_21 (paddrModule_forwardMmask[0][21]),
    .io_forwardMmask_0_22 (paddrModule_forwardMmask[0][22]),
    .io_forwardMmask_0_23 (paddrModule_forwardMmask[0][23]),
    .io_forwardMmask_0_24 (paddrModule_forwardMmask[0][24]),
    .io_forwardMmask_0_25 (paddrModule_forwardMmask[0][25]),
    .io_forwardMmask_0_26 (paddrModule_forwardMmask[0][26]),
    .io_forwardMmask_0_27 (paddrModule_forwardMmask[0][27]),
    .io_forwardMmask_0_28 (paddrModule_forwardMmask[0][28]),
    .io_forwardMmask_0_29 (paddrModule_forwardMmask[0][29]),
    .io_forwardMmask_0_30 (paddrModule_forwardMmask[0][30]),
    .io_forwardMmask_0_31 (paddrModule_forwardMmask[0][31]),
    .io_forwardMmask_0_32 (paddrModule_forwardMmask[0][32]),
    .io_forwardMmask_0_33 (paddrModule_forwardMmask[0][33]),
    .io_forwardMmask_0_34 (paddrModule_forwardMmask[0][34]),
    .io_forwardMmask_0_35 (paddrModule_forwardMmask[0][35]),
    .io_forwardMmask_0_36 (paddrModule_forwardMmask[0][36]),
    .io_forwardMmask_0_37 (paddrModule_forwardMmask[0][37]),
    .io_forwardMmask_0_38 (paddrModule_forwardMmask[0][38]),
    .io_forwardMmask_0_39 (paddrModule_forwardMmask[0][39]),
    .io_forwardMmask_0_40 (paddrModule_forwardMmask[0][40]),
    .io_forwardMmask_0_41 (paddrModule_forwardMmask[0][41]),
    .io_forwardMmask_0_42 (paddrModule_forwardMmask[0][42]),
    .io_forwardMmask_0_43 (paddrModule_forwardMmask[0][43]),
    .io_forwardMmask_0_44 (paddrModule_forwardMmask[0][44]),
    .io_forwardMmask_0_45 (paddrModule_forwardMmask[0][45]),
    .io_forwardMmask_0_46 (paddrModule_forwardMmask[0][46]),
    .io_forwardMmask_0_47 (paddrModule_forwardMmask[0][47]),
    .io_forwardMmask_0_48 (paddrModule_forwardMmask[0][48]),
    .io_forwardMmask_0_49 (paddrModule_forwardMmask[0][49]),
    .io_forwardMmask_0_50 (paddrModule_forwardMmask[0][50]),
    .io_forwardMmask_0_51 (paddrModule_forwardMmask[0][51]),
    .io_forwardMmask_0_52 (paddrModule_forwardMmask[0][52]),
    .io_forwardMmask_0_53 (paddrModule_forwardMmask[0][53]),
    .io_forwardMmask_0_54 (paddrModule_forwardMmask[0][54]),
    .io_forwardMmask_0_55 (paddrModule_forwardMmask[0][55]),
    .io_forwardMmask_1_0 (paddrModule_forwardMmask[1][0]),
    .io_forwardMmask_1_1 (paddrModule_forwardMmask[1][1]),
    .io_forwardMmask_1_2 (paddrModule_forwardMmask[1][2]),
    .io_forwardMmask_1_3 (paddrModule_forwardMmask[1][3]),
    .io_forwardMmask_1_4 (paddrModule_forwardMmask[1][4]),
    .io_forwardMmask_1_5 (paddrModule_forwardMmask[1][5]),
    .io_forwardMmask_1_6 (paddrModule_forwardMmask[1][6]),
    .io_forwardMmask_1_7 (paddrModule_forwardMmask[1][7]),
    .io_forwardMmask_1_8 (paddrModule_forwardMmask[1][8]),
    .io_forwardMmask_1_9 (paddrModule_forwardMmask[1][9]),
    .io_forwardMmask_1_10 (paddrModule_forwardMmask[1][10]),
    .io_forwardMmask_1_11 (paddrModule_forwardMmask[1][11]),
    .io_forwardMmask_1_12 (paddrModule_forwardMmask[1][12]),
    .io_forwardMmask_1_13 (paddrModule_forwardMmask[1][13]),
    .io_forwardMmask_1_14 (paddrModule_forwardMmask[1][14]),
    .io_forwardMmask_1_15 (paddrModule_forwardMmask[1][15]),
    .io_forwardMmask_1_16 (paddrModule_forwardMmask[1][16]),
    .io_forwardMmask_1_17 (paddrModule_forwardMmask[1][17]),
    .io_forwardMmask_1_18 (paddrModule_forwardMmask[1][18]),
    .io_forwardMmask_1_19 (paddrModule_forwardMmask[1][19]),
    .io_forwardMmask_1_20 (paddrModule_forwardMmask[1][20]),
    .io_forwardMmask_1_21 (paddrModule_forwardMmask[1][21]),
    .io_forwardMmask_1_22 (paddrModule_forwardMmask[1][22]),
    .io_forwardMmask_1_23 (paddrModule_forwardMmask[1][23]),
    .io_forwardMmask_1_24 (paddrModule_forwardMmask[1][24]),
    .io_forwardMmask_1_25 (paddrModule_forwardMmask[1][25]),
    .io_forwardMmask_1_26 (paddrModule_forwardMmask[1][26]),
    .io_forwardMmask_1_27 (paddrModule_forwardMmask[1][27]),
    .io_forwardMmask_1_28 (paddrModule_forwardMmask[1][28]),
    .io_forwardMmask_1_29 (paddrModule_forwardMmask[1][29]),
    .io_forwardMmask_1_30 (paddrModule_forwardMmask[1][30]),
    .io_forwardMmask_1_31 (paddrModule_forwardMmask[1][31]),
    .io_forwardMmask_1_32 (paddrModule_forwardMmask[1][32]),
    .io_forwardMmask_1_33 (paddrModule_forwardMmask[1][33]),
    .io_forwardMmask_1_34 (paddrModule_forwardMmask[1][34]),
    .io_forwardMmask_1_35 (paddrModule_forwardMmask[1][35]),
    .io_forwardMmask_1_36 (paddrModule_forwardMmask[1][36]),
    .io_forwardMmask_1_37 (paddrModule_forwardMmask[1][37]),
    .io_forwardMmask_1_38 (paddrModule_forwardMmask[1][38]),
    .io_forwardMmask_1_39 (paddrModule_forwardMmask[1][39]),
    .io_forwardMmask_1_40 (paddrModule_forwardMmask[1][40]),
    .io_forwardMmask_1_41 (paddrModule_forwardMmask[1][41]),
    .io_forwardMmask_1_42 (paddrModule_forwardMmask[1][42]),
    .io_forwardMmask_1_43 (paddrModule_forwardMmask[1][43]),
    .io_forwardMmask_1_44 (paddrModule_forwardMmask[1][44]),
    .io_forwardMmask_1_45 (paddrModule_forwardMmask[1][45]),
    .io_forwardMmask_1_46 (paddrModule_forwardMmask[1][46]),
    .io_forwardMmask_1_47 (paddrModule_forwardMmask[1][47]),
    .io_forwardMmask_1_48 (paddrModule_forwardMmask[1][48]),
    .io_forwardMmask_1_49 (paddrModule_forwardMmask[1][49]),
    .io_forwardMmask_1_50 (paddrModule_forwardMmask[1][50]),
    .io_forwardMmask_1_51 (paddrModule_forwardMmask[1][51]),
    .io_forwardMmask_1_52 (paddrModule_forwardMmask[1][52]),
    .io_forwardMmask_1_53 (paddrModule_forwardMmask[1][53]),
    .io_forwardMmask_1_54 (paddrModule_forwardMmask[1][54]),
    .io_forwardMmask_1_55 (paddrModule_forwardMmask[1][55]),
    .io_forwardMmask_2_0 (paddrModule_forwardMmask[2][0]),
    .io_forwardMmask_2_1 (paddrModule_forwardMmask[2][1]),
    .io_forwardMmask_2_2 (paddrModule_forwardMmask[2][2]),
    .io_forwardMmask_2_3 (paddrModule_forwardMmask[2][3]),
    .io_forwardMmask_2_4 (paddrModule_forwardMmask[2][4]),
    .io_forwardMmask_2_5 (paddrModule_forwardMmask[2][5]),
    .io_forwardMmask_2_6 (paddrModule_forwardMmask[2][6]),
    .io_forwardMmask_2_7 (paddrModule_forwardMmask[2][7]),
    .io_forwardMmask_2_8 (paddrModule_forwardMmask[2][8]),
    .io_forwardMmask_2_9 (paddrModule_forwardMmask[2][9]),
    .io_forwardMmask_2_10 (paddrModule_forwardMmask[2][10]),
    .io_forwardMmask_2_11 (paddrModule_forwardMmask[2][11]),
    .io_forwardMmask_2_12 (paddrModule_forwardMmask[2][12]),
    .io_forwardMmask_2_13 (paddrModule_forwardMmask[2][13]),
    .io_forwardMmask_2_14 (paddrModule_forwardMmask[2][14]),
    .io_forwardMmask_2_15 (paddrModule_forwardMmask[2][15]),
    .io_forwardMmask_2_16 (paddrModule_forwardMmask[2][16]),
    .io_forwardMmask_2_17 (paddrModule_forwardMmask[2][17]),
    .io_forwardMmask_2_18 (paddrModule_forwardMmask[2][18]),
    .io_forwardMmask_2_19 (paddrModule_forwardMmask[2][19]),
    .io_forwardMmask_2_20 (paddrModule_forwardMmask[2][20]),
    .io_forwardMmask_2_21 (paddrModule_forwardMmask[2][21]),
    .io_forwardMmask_2_22 (paddrModule_forwardMmask[2][22]),
    .io_forwardMmask_2_23 (paddrModule_forwardMmask[2][23]),
    .io_forwardMmask_2_24 (paddrModule_forwardMmask[2][24]),
    .io_forwardMmask_2_25 (paddrModule_forwardMmask[2][25]),
    .io_forwardMmask_2_26 (paddrModule_forwardMmask[2][26]),
    .io_forwardMmask_2_27 (paddrModule_forwardMmask[2][27]),
    .io_forwardMmask_2_28 (paddrModule_forwardMmask[2][28]),
    .io_forwardMmask_2_29 (paddrModule_forwardMmask[2][29]),
    .io_forwardMmask_2_30 (paddrModule_forwardMmask[2][30]),
    .io_forwardMmask_2_31 (paddrModule_forwardMmask[2][31]),
    .io_forwardMmask_2_32 (paddrModule_forwardMmask[2][32]),
    .io_forwardMmask_2_33 (paddrModule_forwardMmask[2][33]),
    .io_forwardMmask_2_34 (paddrModule_forwardMmask[2][34]),
    .io_forwardMmask_2_35 (paddrModule_forwardMmask[2][35]),
    .io_forwardMmask_2_36 (paddrModule_forwardMmask[2][36]),
    .io_forwardMmask_2_37 (paddrModule_forwardMmask[2][37]),
    .io_forwardMmask_2_38 (paddrModule_forwardMmask[2][38]),
    .io_forwardMmask_2_39 (paddrModule_forwardMmask[2][39]),
    .io_forwardMmask_2_40 (paddrModule_forwardMmask[2][40]),
    .io_forwardMmask_2_41 (paddrModule_forwardMmask[2][41]),
    .io_forwardMmask_2_42 (paddrModule_forwardMmask[2][42]),
    .io_forwardMmask_2_43 (paddrModule_forwardMmask[2][43]),
    .io_forwardMmask_2_44 (paddrModule_forwardMmask[2][44]),
    .io_forwardMmask_2_45 (paddrModule_forwardMmask[2][45]),
    .io_forwardMmask_2_46 (paddrModule_forwardMmask[2][46]),
    .io_forwardMmask_2_47 (paddrModule_forwardMmask[2][47]),
    .io_forwardMmask_2_48 (paddrModule_forwardMmask[2][48]),
    .io_forwardMmask_2_49 (paddrModule_forwardMmask[2][49]),
    .io_forwardMmask_2_50 (paddrModule_forwardMmask[2][50]),
    .io_forwardMmask_2_51 (paddrModule_forwardMmask[2][51]),
    .io_forwardMmask_2_52 (paddrModule_forwardMmask[2][52]),
    .io_forwardMmask_2_53 (paddrModule_forwardMmask[2][53]),
    .io_forwardMmask_2_54 (paddrModule_forwardMmask[2][54]),
    .io_forwardMmask_2_55 (paddrModule_forwardMmask[2][55])
  );

  SQAddrModule_1_xs vaddrModule (
    .clock                (clock),
    .reset                (reset),
    .io_raddr_0           (rdataPtrExtNext[0].value),
    .io_raddr_1           (rdataPtrExtNext[1].value),
    .io_rdata_0           (vaddrModule_rdata[0]),
    .io_rdata_1           (vaddrModule_rdata[1]),
    // ★SQAddrModule_1_xs（虚地址那份）没有 rlineflag 输出★：wline 只由物理地址侧给，
    // golden 的 dataWidth=50 变体里这两根被 firtool 裁掉了。
    .io_wen_0             (staWen[0]),
    .io_wen_1             (staWen[1]),
    .io_waddr_0           (stWbIndex[0]),
    .io_waddr_1           (stWbIndex[1]),
    .io_wdata_0           (storeAddrIn_in[0].bits_vaddr),
    .io_wdata_1           (storeAddrIn_in[1].bits_vaddr),
    .io_wmask_0           (storeAddrIn_in[0].bits_mask),
    .io_wmask_1           (storeAddrIn_in[1].bits_mask),
    .io_wlineflag_0       (storeAddrIn_in[0].bits_wlineflag),
    .io_wlineflag_1       (storeAddrIn_in[1].bits_wlineflag),
    .io_forwardMdata_0    (forward_in[0].vaddr),
    .io_forwardMdata_1    (forward_in[1].vaddr),
    .io_forwardMdata_2    (forward_in[2].vaddr),
    .io_forwardDataMask_0 (forward_in[0].mask),
    .io_forwardDataMask_1 (forward_in[1].mask),
    .io_forwardDataMask_2 (forward_in[2].mask),
    .io_forwardMmask_0_0 (vaddrModule_forwardMmask[0][0]),
    .io_forwardMmask_0_1 (vaddrModule_forwardMmask[0][1]),
    .io_forwardMmask_0_2 (vaddrModule_forwardMmask[0][2]),
    .io_forwardMmask_0_3 (vaddrModule_forwardMmask[0][3]),
    .io_forwardMmask_0_4 (vaddrModule_forwardMmask[0][4]),
    .io_forwardMmask_0_5 (vaddrModule_forwardMmask[0][5]),
    .io_forwardMmask_0_6 (vaddrModule_forwardMmask[0][6]),
    .io_forwardMmask_0_7 (vaddrModule_forwardMmask[0][7]),
    .io_forwardMmask_0_8 (vaddrModule_forwardMmask[0][8]),
    .io_forwardMmask_0_9 (vaddrModule_forwardMmask[0][9]),
    .io_forwardMmask_0_10 (vaddrModule_forwardMmask[0][10]),
    .io_forwardMmask_0_11 (vaddrModule_forwardMmask[0][11]),
    .io_forwardMmask_0_12 (vaddrModule_forwardMmask[0][12]),
    .io_forwardMmask_0_13 (vaddrModule_forwardMmask[0][13]),
    .io_forwardMmask_0_14 (vaddrModule_forwardMmask[0][14]),
    .io_forwardMmask_0_15 (vaddrModule_forwardMmask[0][15]),
    .io_forwardMmask_0_16 (vaddrModule_forwardMmask[0][16]),
    .io_forwardMmask_0_17 (vaddrModule_forwardMmask[0][17]),
    .io_forwardMmask_0_18 (vaddrModule_forwardMmask[0][18]),
    .io_forwardMmask_0_19 (vaddrModule_forwardMmask[0][19]),
    .io_forwardMmask_0_20 (vaddrModule_forwardMmask[0][20]),
    .io_forwardMmask_0_21 (vaddrModule_forwardMmask[0][21]),
    .io_forwardMmask_0_22 (vaddrModule_forwardMmask[0][22]),
    .io_forwardMmask_0_23 (vaddrModule_forwardMmask[0][23]),
    .io_forwardMmask_0_24 (vaddrModule_forwardMmask[0][24]),
    .io_forwardMmask_0_25 (vaddrModule_forwardMmask[0][25]),
    .io_forwardMmask_0_26 (vaddrModule_forwardMmask[0][26]),
    .io_forwardMmask_0_27 (vaddrModule_forwardMmask[0][27]),
    .io_forwardMmask_0_28 (vaddrModule_forwardMmask[0][28]),
    .io_forwardMmask_0_29 (vaddrModule_forwardMmask[0][29]),
    .io_forwardMmask_0_30 (vaddrModule_forwardMmask[0][30]),
    .io_forwardMmask_0_31 (vaddrModule_forwardMmask[0][31]),
    .io_forwardMmask_0_32 (vaddrModule_forwardMmask[0][32]),
    .io_forwardMmask_0_33 (vaddrModule_forwardMmask[0][33]),
    .io_forwardMmask_0_34 (vaddrModule_forwardMmask[0][34]),
    .io_forwardMmask_0_35 (vaddrModule_forwardMmask[0][35]),
    .io_forwardMmask_0_36 (vaddrModule_forwardMmask[0][36]),
    .io_forwardMmask_0_37 (vaddrModule_forwardMmask[0][37]),
    .io_forwardMmask_0_38 (vaddrModule_forwardMmask[0][38]),
    .io_forwardMmask_0_39 (vaddrModule_forwardMmask[0][39]),
    .io_forwardMmask_0_40 (vaddrModule_forwardMmask[0][40]),
    .io_forwardMmask_0_41 (vaddrModule_forwardMmask[0][41]),
    .io_forwardMmask_0_42 (vaddrModule_forwardMmask[0][42]),
    .io_forwardMmask_0_43 (vaddrModule_forwardMmask[0][43]),
    .io_forwardMmask_0_44 (vaddrModule_forwardMmask[0][44]),
    .io_forwardMmask_0_45 (vaddrModule_forwardMmask[0][45]),
    .io_forwardMmask_0_46 (vaddrModule_forwardMmask[0][46]),
    .io_forwardMmask_0_47 (vaddrModule_forwardMmask[0][47]),
    .io_forwardMmask_0_48 (vaddrModule_forwardMmask[0][48]),
    .io_forwardMmask_0_49 (vaddrModule_forwardMmask[0][49]),
    .io_forwardMmask_0_50 (vaddrModule_forwardMmask[0][50]),
    .io_forwardMmask_0_51 (vaddrModule_forwardMmask[0][51]),
    .io_forwardMmask_0_52 (vaddrModule_forwardMmask[0][52]),
    .io_forwardMmask_0_53 (vaddrModule_forwardMmask[0][53]),
    .io_forwardMmask_0_54 (vaddrModule_forwardMmask[0][54]),
    .io_forwardMmask_0_55 (vaddrModule_forwardMmask[0][55]),
    .io_forwardMmask_1_0 (vaddrModule_forwardMmask[1][0]),
    .io_forwardMmask_1_1 (vaddrModule_forwardMmask[1][1]),
    .io_forwardMmask_1_2 (vaddrModule_forwardMmask[1][2]),
    .io_forwardMmask_1_3 (vaddrModule_forwardMmask[1][3]),
    .io_forwardMmask_1_4 (vaddrModule_forwardMmask[1][4]),
    .io_forwardMmask_1_5 (vaddrModule_forwardMmask[1][5]),
    .io_forwardMmask_1_6 (vaddrModule_forwardMmask[1][6]),
    .io_forwardMmask_1_7 (vaddrModule_forwardMmask[1][7]),
    .io_forwardMmask_1_8 (vaddrModule_forwardMmask[1][8]),
    .io_forwardMmask_1_9 (vaddrModule_forwardMmask[1][9]),
    .io_forwardMmask_1_10 (vaddrModule_forwardMmask[1][10]),
    .io_forwardMmask_1_11 (vaddrModule_forwardMmask[1][11]),
    .io_forwardMmask_1_12 (vaddrModule_forwardMmask[1][12]),
    .io_forwardMmask_1_13 (vaddrModule_forwardMmask[1][13]),
    .io_forwardMmask_1_14 (vaddrModule_forwardMmask[1][14]),
    .io_forwardMmask_1_15 (vaddrModule_forwardMmask[1][15]),
    .io_forwardMmask_1_16 (vaddrModule_forwardMmask[1][16]),
    .io_forwardMmask_1_17 (vaddrModule_forwardMmask[1][17]),
    .io_forwardMmask_1_18 (vaddrModule_forwardMmask[1][18]),
    .io_forwardMmask_1_19 (vaddrModule_forwardMmask[1][19]),
    .io_forwardMmask_1_20 (vaddrModule_forwardMmask[1][20]),
    .io_forwardMmask_1_21 (vaddrModule_forwardMmask[1][21]),
    .io_forwardMmask_1_22 (vaddrModule_forwardMmask[1][22]),
    .io_forwardMmask_1_23 (vaddrModule_forwardMmask[1][23]),
    .io_forwardMmask_1_24 (vaddrModule_forwardMmask[1][24]),
    .io_forwardMmask_1_25 (vaddrModule_forwardMmask[1][25]),
    .io_forwardMmask_1_26 (vaddrModule_forwardMmask[1][26]),
    .io_forwardMmask_1_27 (vaddrModule_forwardMmask[1][27]),
    .io_forwardMmask_1_28 (vaddrModule_forwardMmask[1][28]),
    .io_forwardMmask_1_29 (vaddrModule_forwardMmask[1][29]),
    .io_forwardMmask_1_30 (vaddrModule_forwardMmask[1][30]),
    .io_forwardMmask_1_31 (vaddrModule_forwardMmask[1][31]),
    .io_forwardMmask_1_32 (vaddrModule_forwardMmask[1][32]),
    .io_forwardMmask_1_33 (vaddrModule_forwardMmask[1][33]),
    .io_forwardMmask_1_34 (vaddrModule_forwardMmask[1][34]),
    .io_forwardMmask_1_35 (vaddrModule_forwardMmask[1][35]),
    .io_forwardMmask_1_36 (vaddrModule_forwardMmask[1][36]),
    .io_forwardMmask_1_37 (vaddrModule_forwardMmask[1][37]),
    .io_forwardMmask_1_38 (vaddrModule_forwardMmask[1][38]),
    .io_forwardMmask_1_39 (vaddrModule_forwardMmask[1][39]),
    .io_forwardMmask_1_40 (vaddrModule_forwardMmask[1][40]),
    .io_forwardMmask_1_41 (vaddrModule_forwardMmask[1][41]),
    .io_forwardMmask_1_42 (vaddrModule_forwardMmask[1][42]),
    .io_forwardMmask_1_43 (vaddrModule_forwardMmask[1][43]),
    .io_forwardMmask_1_44 (vaddrModule_forwardMmask[1][44]),
    .io_forwardMmask_1_45 (vaddrModule_forwardMmask[1][45]),
    .io_forwardMmask_1_46 (vaddrModule_forwardMmask[1][46]),
    .io_forwardMmask_1_47 (vaddrModule_forwardMmask[1][47]),
    .io_forwardMmask_1_48 (vaddrModule_forwardMmask[1][48]),
    .io_forwardMmask_1_49 (vaddrModule_forwardMmask[1][49]),
    .io_forwardMmask_1_50 (vaddrModule_forwardMmask[1][50]),
    .io_forwardMmask_1_51 (vaddrModule_forwardMmask[1][51]),
    .io_forwardMmask_1_52 (vaddrModule_forwardMmask[1][52]),
    .io_forwardMmask_1_53 (vaddrModule_forwardMmask[1][53]),
    .io_forwardMmask_1_54 (vaddrModule_forwardMmask[1][54]),
    .io_forwardMmask_1_55 (vaddrModule_forwardMmask[1][55]),
    .io_forwardMmask_2_0 (vaddrModule_forwardMmask[2][0]),
    .io_forwardMmask_2_1 (vaddrModule_forwardMmask[2][1]),
    .io_forwardMmask_2_2 (vaddrModule_forwardMmask[2][2]),
    .io_forwardMmask_2_3 (vaddrModule_forwardMmask[2][3]),
    .io_forwardMmask_2_4 (vaddrModule_forwardMmask[2][4]),
    .io_forwardMmask_2_5 (vaddrModule_forwardMmask[2][5]),
    .io_forwardMmask_2_6 (vaddrModule_forwardMmask[2][6]),
    .io_forwardMmask_2_7 (vaddrModule_forwardMmask[2][7]),
    .io_forwardMmask_2_8 (vaddrModule_forwardMmask[2][8]),
    .io_forwardMmask_2_9 (vaddrModule_forwardMmask[2][9]),
    .io_forwardMmask_2_10 (vaddrModule_forwardMmask[2][10]),
    .io_forwardMmask_2_11 (vaddrModule_forwardMmask[2][11]),
    .io_forwardMmask_2_12 (vaddrModule_forwardMmask[2][12]),
    .io_forwardMmask_2_13 (vaddrModule_forwardMmask[2][13]),
    .io_forwardMmask_2_14 (vaddrModule_forwardMmask[2][14]),
    .io_forwardMmask_2_15 (vaddrModule_forwardMmask[2][15]),
    .io_forwardMmask_2_16 (vaddrModule_forwardMmask[2][16]),
    .io_forwardMmask_2_17 (vaddrModule_forwardMmask[2][17]),
    .io_forwardMmask_2_18 (vaddrModule_forwardMmask[2][18]),
    .io_forwardMmask_2_19 (vaddrModule_forwardMmask[2][19]),
    .io_forwardMmask_2_20 (vaddrModule_forwardMmask[2][20]),
    .io_forwardMmask_2_21 (vaddrModule_forwardMmask[2][21]),
    .io_forwardMmask_2_22 (vaddrModule_forwardMmask[2][22]),
    .io_forwardMmask_2_23 (vaddrModule_forwardMmask[2][23]),
    .io_forwardMmask_2_24 (vaddrModule_forwardMmask[2][24]),
    .io_forwardMmask_2_25 (vaddrModule_forwardMmask[2][25]),
    .io_forwardMmask_2_26 (vaddrModule_forwardMmask[2][26]),
    .io_forwardMmask_2_27 (vaddrModule_forwardMmask[2][27]),
    .io_forwardMmask_2_28 (vaddrModule_forwardMmask[2][28]),
    .io_forwardMmask_2_29 (vaddrModule_forwardMmask[2][29]),
    .io_forwardMmask_2_30 (vaddrModule_forwardMmask[2][30]),
    .io_forwardMmask_2_31 (vaddrModule_forwardMmask[2][31]),
    .io_forwardMmask_2_32 (vaddrModule_forwardMmask[2][32]),
    .io_forwardMmask_2_33 (vaddrModule_forwardMmask[2][33]),
    .io_forwardMmask_2_34 (vaddrModule_forwardMmask[2][34]),
    .io_forwardMmask_2_35 (vaddrModule_forwardMmask[2][35]),
    .io_forwardMmask_2_36 (vaddrModule_forwardMmask[2][36]),
    .io_forwardMmask_2_37 (vaddrModule_forwardMmask[2][37]),
    .io_forwardMmask_2_38 (vaddrModule_forwardMmask[2][38]),
    .io_forwardMmask_2_39 (vaddrModule_forwardMmask[2][39]),
    .io_forwardMmask_2_40 (vaddrModule_forwardMmask[2][40]),
    .io_forwardMmask_2_41 (vaddrModule_forwardMmask[2][41]),
    .io_forwardMmask_2_42 (vaddrModule_forwardMmask[2][42]),
    .io_forwardMmask_2_43 (vaddrModule_forwardMmask[2][43]),
    .io_forwardMmask_2_44 (vaddrModule_forwardMmask[2][44]),
    .io_forwardMmask_2_45 (vaddrModule_forwardMmask[2][45]),
    .io_forwardMmask_2_46 (vaddrModule_forwardMmask[2][46]),
    .io_forwardMmask_2_47 (vaddrModule_forwardMmask[2][47]),
    .io_forwardMmask_2_48 (vaddrModule_forwardMmask[2][48]),
    .io_forwardMmask_2_49 (vaddrModule_forwardMmask[2][49]),
    .io_forwardMmask_2_50 (vaddrModule_forwardMmask[2][50]),
    .io_forwardMmask_2_51 (vaddrModule_forwardMmask[2][51]),
    .io_forwardMmask_2_52 (vaddrModule_forwardMmask[2][52]),
    .io_forwardMmask_2_53 (vaddrModule_forwardMmask[2][53]),
    .io_forwardMmask_2_54 (vaddrModule_forwardMmask[2][54]),
    .io_forwardMmask_2_55 (vaddrModule_forwardMmask[2][55])
  );

  DatamoduleResultBuffer_xs dataBuffer (
    .clock                     (clock),
    .reset                     (reset),
    .io_enq_0_ready            (dataBuffer_enq_ready[0]),
    .io_enq_0_valid            (dataBuffer_enq_valid[0]),
    .io_enq_0_bits_addr        (dataBuffer_enq_addr[0]),
    .io_enq_0_bits_vaddr       (dataBuffer_enq_vaddr[0]),
    .io_enq_0_bits_data        (dataBuffer_enq_data[0]),
    .io_enq_0_bits_mask        (dataBuffer_enq_mask[0]),
    .io_enq_0_bits_wline       (dataBuffer_enq_wline[0]),
    .io_enq_0_bits_sqPtr_flag  (dataBuffer_enq_sqPtr[0].flag),
    .io_enq_0_bits_sqPtr_value (dataBuffer_enq_sqPtr[0].value),
    .io_enq_0_bits_vecValid    (dataBuffer_enq_vecValid[0]),
    .io_enq_0_bits_sqNeedDeq   (dataBuffer_enq_sqNeedDeq[0]),
    .io_enq_1_ready            (dataBuffer_enq_ready[1]),
    .io_enq_1_valid            (dataBuffer_enq_valid[1]),
    .io_enq_1_bits_addr        (dataBuffer_enq_addr[1]),
    .io_enq_1_bits_vaddr       (dataBuffer_enq_vaddr[1]),
    .io_enq_1_bits_data        (dataBuffer_enq_data[1]),
    .io_enq_1_bits_mask        (dataBuffer_enq_mask[1]),
    .io_enq_1_bits_wline       (dataBuffer_enq_wline[1]),
    .io_enq_1_bits_sqPtr_flag  (dataBuffer_enq_sqPtr[1].flag),
    .io_enq_1_bits_sqPtr_value (dataBuffer_enq_sqPtr[1].value),
    .io_enq_1_bits_vecValid    (dataBuffer_enq_vecValid[1]),
    .io_deq_0_ready            (sbuffer_in[0].ready),
    .io_deq_0_valid            (dataBuffer_deq_valid[0]),
    .io_deq_0_bits_addr        (dataBuffer_deq_addr[0]),
    .io_deq_0_bits_vaddr       (dataBuffer_deq_vaddr[0]),
    .io_deq_0_bits_data        (dataBuffer_deq_data[0]),
    .io_deq_0_bits_mask        (dataBuffer_deq_mask[0]),
    .io_deq_0_bits_wline       (dataBuffer_deq_wline[0]),
    .io_deq_0_bits_sqPtr_flag  (dataBuffer_deq_sqPtr[0].flag),
    .io_deq_0_bits_sqPtr_value (dataBuffer_deq_sqPtr[0].value),
    .io_deq_0_bits_vecValid    (dataBuffer_deq_vecValid[0]),
    .io_deq_0_bits_sqNeedDeq   (dataBuffer_deq_sqNeedDeq[0]),
    .io_deq_1_ready            (sbuffer_in[1].ready),
    .io_deq_1_valid            (dataBuffer_deq_valid[1]),
    .io_deq_1_bits_addr        (dataBuffer_deq_addr[1]),
    .io_deq_1_bits_vaddr       (dataBuffer_deq_vaddr[1]),
    .io_deq_1_bits_data        (dataBuffer_deq_data[1]),
    .io_deq_1_bits_mask        (dataBuffer_deq_mask[1]),
    .io_deq_1_bits_wline       (dataBuffer_deq_wline[1]),
    .io_deq_1_bits_sqPtr_flag  (dataBuffer_deq_sqPtr[1].flag),
    .io_deq_1_bits_sqPtr_value (dataBuffer_deq_sqPtr[1].value),
    .io_deq_1_bits_vecValid    (dataBuffer_deq_vecValid[1]),
    .io_deq_1_bits_sqNeedDeq   (dataBuffer_deq_sqNeedDeq[1])
  );

  // exceptionBuffer 的 7 个入口（enqPortNum = StorePipelineWidth*2 + VecStorePipelineWidth + 1）：
  //   0,1  sta 的 s1 异常（af 除外，af 要等 pmp/pma，晚一拍）
  //   2,3  sta 的 s2 异常（★这两口的 exceptionVec_7 用的是 af，不是 uop 里的那一位★）
  //   4,5  向量通路的 FLUSH 反馈（feedback_0 = VecFeedbacks.FLUSH）
  //   6    mmio 回写时把 uncacheUop 的异常也送进来
  // 每口的端口集合不一样（firtool 按常量各自裁剪过），下面照 golden 的连线逐条对。
  StoreExceptionBuffer_xs exceptionBuffer (
    .clock                                     (clock),
    .reset                                     (reset),
    .io_redirect_valid                         (io_brqRedirect_valid),
    .io_redirect_bits_robIdx_flag              (io_brqRedirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value             (io_brqRedirect_bits_robIdx_value),
    .io_redirect_bits_level                    (io_brqRedirect_bits_level),

    .io_storeAddrIn_0_valid
      (staFire[0] & ~storeAddrIn_in[0].bits_miss & ~storeAddrIn_in[0].bits_isvec),
    .io_storeAddrIn_0_bits_uop_exceptionVec_3  (storeAddrIn_in[0].bits_uop_exceptionVec_3),
    .io_storeAddrIn_0_bits_uop_exceptionVec_6  (storeAddrIn_in[0].bits_uop_exceptionVec_6),
    .io_storeAddrIn_0_bits_uop_exceptionVec_7  (storeAddrIn_in[0].bits_uop_exceptionVec_7),
    .io_storeAddrIn_0_bits_uop_exceptionVec_15 (storeAddrIn_in[0].bits_uop_exceptionVec_15),
    .io_storeAddrIn_0_bits_uop_exceptionVec_19 (storeAddrIn_in[0].bits_uop_exceptionVec_19),
    .io_storeAddrIn_0_bits_uop_exceptionVec_23 (storeAddrIn_in[0].bits_uop_exceptionVec_23),
    .io_storeAddrIn_0_bits_uop_uopIdx          (storeAddrIn_in[0].bits_uop_uopIdx),
    .io_storeAddrIn_0_bits_uop_robIdx_flag     (storeAddrIn_in[0].bits_uop_robIdx_flag),
    .io_storeAddrIn_0_bits_uop_robIdx_value    (storeAddrIn_in[0].bits_uop_robIdx_value),
    .io_storeAddrIn_0_bits_fullva              (storeAddrIn_in[0].bits_fullva),
    .io_storeAddrIn_0_bits_vaNeedExt           (storeAddrIn_in[0].bits_vaNeedExt),
    .io_storeAddrIn_0_bits_gpaddr              (storeAddrIn_in[0].bits_gpaddr),
    .io_storeAddrIn_0_bits_isHyper             (storeAddrIn_in[0].bits_isHyper),
    .io_storeAddrIn_0_bits_isForVSnonLeafPTE   (storeAddrIn_in[0].bits_isForVSnonLeafPTE),

    .io_storeAddrIn_1_valid
      (staFire[1] & ~storeAddrIn_in[1].bits_miss & ~storeAddrIn_in[1].bits_isvec),
    .io_storeAddrIn_1_bits_uop_exceptionVec_3  (storeAddrIn_in[1].bits_uop_exceptionVec_3),
    .io_storeAddrIn_1_bits_uop_exceptionVec_6  (storeAddrIn_in[1].bits_uop_exceptionVec_6),
    .io_storeAddrIn_1_bits_uop_exceptionVec_7  (storeAddrIn_in[1].bits_uop_exceptionVec_7),
    .io_storeAddrIn_1_bits_uop_exceptionVec_15 (storeAddrIn_in[1].bits_uop_exceptionVec_15),
    .io_storeAddrIn_1_bits_uop_exceptionVec_19 (storeAddrIn_in[1].bits_uop_exceptionVec_19),
    .io_storeAddrIn_1_bits_uop_exceptionVec_23 (storeAddrIn_in[1].bits_uop_exceptionVec_23),
    .io_storeAddrIn_1_bits_uop_uopIdx          (storeAddrIn_in[1].bits_uop_uopIdx),
    .io_storeAddrIn_1_bits_uop_robIdx_flag     (storeAddrIn_in[1].bits_uop_robIdx_flag),
    .io_storeAddrIn_1_bits_uop_robIdx_value    (storeAddrIn_in[1].bits_uop_robIdx_value),
    .io_storeAddrIn_1_bits_fullva              (storeAddrIn_in[1].bits_fullva),
    .io_storeAddrIn_1_bits_vaNeedExt           (storeAddrIn_in[1].bits_vaNeedExt),
    .io_storeAddrIn_1_bits_gpaddr              (storeAddrIn_in[1].bits_gpaddr),
    .io_storeAddrIn_1_bits_isHyper             (storeAddrIn_in[1].bits_isHyper),
    .io_storeAddrIn_1_bits_isForVSnonLeafPTE   (storeAddrIn_in[1].bits_isForVSnonLeafPTE),

    // s2 两口：Chisel 先把整个 bundle 钉成 0，再在 storeAddrInFireReg 下覆盖，
    // 所以每根都带 storeAddrInFireReg 的门控（照抄，别提到 valid 上去）。
    .io_storeAddrIn_2_valid
      (storeAddrInFireReg[0] & storeAddrInRe_in[0].hasException & ~storeAddrInRe_in[0].isvec),
    .io_storeAddrIn_2_bits_uop_exceptionVec_3  (storeAddrInFireReg[0] & storeAddrInRe_in[0].uop_exceptionVec_3),
    .io_storeAddrIn_2_bits_uop_exceptionVec_6  (storeAddrInFireReg[0] & storeAddrInRe_in[0].uop_exceptionVec_6),
    .io_storeAddrIn_2_bits_uop_exceptionVec_7  (storeAddrInFireReg[0] & storeAddrInRe_in[0].af),
    .io_storeAddrIn_2_bits_uop_exceptionVec_15 (storeAddrInFireReg[0] & storeAddrInRe_in[0].uop_exceptionVec_15),
    .io_storeAddrIn_2_bits_uop_exceptionVec_19 (storeAddrInFireReg[0] & storeAddrInRe_in[0].uop_exceptionVec_19),
    .io_storeAddrIn_2_bits_uop_exceptionVec_23 (storeAddrInFireReg[0] & storeAddrInRe_in[0].uop_exceptionVec_23),
    .io_storeAddrIn_2_bits_uop_uopIdx          (storeAddrInFireReg[0] ? storeAddrInRe_in[0].uop_uopIdx : 7'h0),
    .io_storeAddrIn_2_bits_uop_robIdx_flag     (storeAddrInFireReg[0] & storeAddrInRe_in[0].uop_robIdx_flag),
    .io_storeAddrIn_2_bits_uop_robIdx_value    (storeAddrInFireReg[0] ? storeAddrInRe_in[0].uop_robIdx_value : 8'h0),
    .io_storeAddrIn_2_bits_fullva              (storeAddrInFireReg[0] ? storeAddrInRe_in[0].fullva : 64'h0),
    .io_storeAddrIn_2_bits_vaNeedExt           (storeAddrInFireReg[0] & storeAddrInRe_in[0].vaNeedExt),
    .io_storeAddrIn_2_bits_gpaddr              (storeAddrInFireReg[0] ? storeAddrInRe_in[0].gpaddr : 64'h0),
    .io_storeAddrIn_2_bits_isHyper             (storeAddrInFireReg[0] & storeAddrInRe_in[0].isHyper),
    .io_storeAddrIn_2_bits_isForVSnonLeafPTE   (storeAddrInFireReg[0] & storeAddrInRe_in[0].isForVSnonLeafPTE),

    .io_storeAddrIn_3_valid
      (storeAddrInFireReg[1] & storeAddrInRe_in[1].hasException & ~storeAddrInRe_in[1].isvec),
    .io_storeAddrIn_3_bits_uop_exceptionVec_3  (storeAddrInFireReg[1] & storeAddrInRe_in[1].uop_exceptionVec_3),
    .io_storeAddrIn_3_bits_uop_exceptionVec_6  (storeAddrInFireReg[1] & storeAddrInRe_in[1].uop_exceptionVec_6),
    .io_storeAddrIn_3_bits_uop_exceptionVec_7  (storeAddrInFireReg[1] & storeAddrInRe_in[1].af),
    .io_storeAddrIn_3_bits_uop_exceptionVec_15 (storeAddrInFireReg[1] & storeAddrInRe_in[1].uop_exceptionVec_15),
    .io_storeAddrIn_3_bits_uop_exceptionVec_19 (storeAddrInFireReg[1] & storeAddrInRe_in[1].uop_exceptionVec_19),
    .io_storeAddrIn_3_bits_uop_exceptionVec_23 (storeAddrInFireReg[1] & storeAddrInRe_in[1].uop_exceptionVec_23),
    .io_storeAddrIn_3_bits_uop_uopIdx          (storeAddrInFireReg[1] ? storeAddrInRe_in[1].uop_uopIdx : 7'h0),
    .io_storeAddrIn_3_bits_uop_robIdx_flag     (storeAddrInFireReg[1] & storeAddrInRe_in[1].uop_robIdx_flag),
    .io_storeAddrIn_3_bits_uop_robIdx_value    (storeAddrInFireReg[1] ? storeAddrInRe_in[1].uop_robIdx_value : 8'h0),
    .io_storeAddrIn_3_bits_fullva              (storeAddrInFireReg[1] ? storeAddrInRe_in[1].fullva : 64'h0),
    .io_storeAddrIn_3_bits_vaNeedExt           (storeAddrInFireReg[1] & storeAddrInRe_in[1].vaNeedExt),
    .io_storeAddrIn_3_bits_gpaddr              (storeAddrInFireReg[1] ? storeAddrInRe_in[1].gpaddr : 64'h0),
    .io_storeAddrIn_3_bits_isHyper             (storeAddrInFireReg[1] & storeAddrInRe_in[1].isHyper),
    .io_storeAddrIn_3_bits_isForVSnonLeafPTE   (storeAddrInFireReg[1] & storeAddrInRe_in[1].isForVSnonLeafPTE),

    // 向量两口：feedback_0 = VecFeedbacks.FLUSH。★这两口没有 isHyper 端口★
    // （firtool 判它恒 DontCare 直接裁了），golden 也不接，这里跟着不接。
    .io_storeAddrIn_4_valid                    (vecFeedback_in[0].valid & vecFeedback_in[0].bits_feedback_0),
    .io_storeAddrIn_4_bits_uop_exceptionVec_3  (vecFeedback_in[0].bits_exceptionVec_3),
    .io_storeAddrIn_4_bits_uop_exceptionVec_6  (vecFeedback_in[0].bits_exceptionVec_6),
    .io_storeAddrIn_4_bits_uop_exceptionVec_7  (vecFeedback_in[0].bits_exceptionVec_7),
    .io_storeAddrIn_4_bits_uop_exceptionVec_15 (vecFeedback_in[0].bits_exceptionVec_15),
    .io_storeAddrIn_4_bits_uop_exceptionVec_19 (vecFeedback_in[0].bits_exceptionVec_19),
    .io_storeAddrIn_4_bits_uop_exceptionVec_23 (vecFeedback_in[0].bits_exceptionVec_23),
    .io_storeAddrIn_4_bits_uop_uopIdx          (vecFeedback_in[0].bits_uopidx),
    .io_storeAddrIn_4_bits_uop_robIdx_flag     (vecFeedback_in[0].bits_robidx_flag),
    .io_storeAddrIn_4_bits_uop_robIdx_value    (vecFeedback_in[0].bits_robidx_value),
    .io_storeAddrIn_4_bits_fullva              (vecFeedback_in[0].bits_vaddr),
    .io_storeAddrIn_4_bits_vaNeedExt           (vecFeedback_in[0].bits_vaNeedExt),
    .io_storeAddrIn_4_bits_gpaddr              (vecFeedback_in[0].bits_gpaddr),
    .io_storeAddrIn_4_bits_isForVSnonLeafPTE   (vecFeedback_in[0].bits_isForVSnonLeafPTE),

    .io_storeAddrIn_5_valid                    (vecFeedback_in[1].valid & vecFeedback_in[1].bits_feedback_0),
    .io_storeAddrIn_5_bits_uop_exceptionVec_3  (vecFeedback_in[1].bits_exceptionVec_3),
    .io_storeAddrIn_5_bits_uop_exceptionVec_6  (vecFeedback_in[1].bits_exceptionVec_6),
    .io_storeAddrIn_5_bits_uop_exceptionVec_7  (vecFeedback_in[1].bits_exceptionVec_7),
    .io_storeAddrIn_5_bits_uop_exceptionVec_15 (vecFeedback_in[1].bits_exceptionVec_15),
    .io_storeAddrIn_5_bits_uop_exceptionVec_19 (vecFeedback_in[1].bits_exceptionVec_19),
    .io_storeAddrIn_5_bits_uop_exceptionVec_23 (vecFeedback_in[1].bits_exceptionVec_23),
    .io_storeAddrIn_5_bits_uop_uopIdx          (vecFeedback_in[1].bits_uopidx),
    .io_storeAddrIn_5_bits_uop_robIdx_flag     (vecFeedback_in[1].bits_robidx_flag),
    .io_storeAddrIn_5_bits_uop_robIdx_value    (vecFeedback_in[1].bits_robidx_value),
    .io_storeAddrIn_5_bits_fullva              (vecFeedback_in[1].bits_vaddr),
    .io_storeAddrIn_5_bits_vaNeedExt           (vecFeedback_in[1].bits_vaNeedExt),
    .io_storeAddrIn_5_bits_gpaddr              (vecFeedback_in[1].bits_gpaddr),
    .io_storeAddrIn_5_bits_isForVSnonLeafPTE   (vecFeedback_in[1].bits_isForVSnonLeafPTE),

    // mmio 回写口：★只剩 6 根端口★（其余字段 firtool 判恒定裁掉了）。
    .io_storeAddrIn_6_valid                    (mmioStoutFire),
    .io_storeAddrIn_6_bits_uop_exceptionVec_7  (uncacheUop_excStoreAccessFault),
    .io_storeAddrIn_6_bits_uop_exceptionVec_19 (uncacheUop_excHardwareError),
    .io_storeAddrIn_6_bits_uop_uopIdx          (uncacheUop_uopIdx),
    .io_storeAddrIn_6_bits_uop_robIdx_flag     (uncacheUop_robIdx_flag),
    .io_storeAddrIn_6_bits_uop_robIdx_value    (uncacheUop_robIdx_value),
    .io_storeAddrIn_6_bits_fullva              ({14'h0, vaddrModule_rdata[0]}),

    .io_exceptionAddr_vaddr                    (exceptionBuffer_vaddr),
    .io_exceptionAddr_vaNeedExt                (exceptionBuffer_vaNeedExt),
    .io_exceptionAddr_isHyper                  (exceptionBuffer_isHyper),
    .io_exceptionAddr_gpaddr                   (exceptionBuffer_gpaddr),
    .io_exceptionAddr_isForVSnonLeafPTE        (exceptionBuffer_isForVSnonLeafPTE)
  );

// -----------------------------------------------------------------------------
// §18 向量异常旗标 + 冲刷判定
// -----------------------------------------------------------------------------
  // 一条向量 store 会占多条条目。如果其中某条出了异常，**它后面的 flow 就不许再写
  // Sbuffer**。vecExceptionFlag 记住「这条指令已经出过异常」，直到它的 lastFlow
  // 也出队才清掉。
  logic [N_ENSBUF-1:0] vecFlagSetReq;

  always_comb begin
    automatic logic robidxEQ, robidxNE, onlyCommit0;
    for (int i = 0; i < N_ENSBUF; i++) begin
      automatic logic [5:0] p = dataBuffer_enq_sqPtr[i].value;
      vecCommitHasExceptionValid[i]    = isVec[p] & hasException[p]
                                       & dataBuffer_enq_fire[i] & dataBuffer_enq_sqNeedDeq[i];
      vecCommitHasExceptionLastFlow[i] = vecLastFlow[p];
    end
    // ParallelPosteriorityMux：**最后**一个命中的赢（要的是最靠后那条异常 uop）。
    vecCommitSelEntry = dataBuffer_enq_sqPtr[0].value;
    for (int i = 0; i < N_ENSBUF; i++)
      if (vecCommitHasExceptionValid[i]) vecCommitSelEntry = dataBuffer_enq_sqPtr[i].value;

    robidxEQ = dataBuffer_enq_fire[0] & dataBuffer_enq_fire[1]
             & ({uop_robIdx_flag[dataBuffer_enq_sqPtr[0].value],
                 uop_robIdx_value[dataBuffer_enq_sqPtr[0].value]}
                == {uop_robIdx_flag[dataBuffer_enq_sqPtr[1].value],
                    uop_robIdx_value[dataBuffer_enq_sqPtr[1].value]});
    robidxNE = dataBuffer_enq_fire[0] & dataBuffer_enq_fire[1]
             & ({uop_robIdx_flag[dataBuffer_enq_sqPtr[0].value],
                 uop_robIdx_value[dataBuffer_enq_sqPtr[0].value]}
                != {uop_robIdx_flag[dataBuffer_enq_sqPtr[1].value],
                    uop_robIdx_value[dataBuffer_enq_sqPtr[1].value]});
    onlyCommit0 = dataBuffer_enq_fire[0] & ~dataBuffer_enq_fire[1];

    // 「出异常的那条正好就是 lastFlow」-> 这条指令到此为止，旗标不用立。
    vecCommitLastFlow =
        (robidxEQ & vecCommitHasExceptionLastFlow[1])
      | (robidxNE & ((vecCommitHasExceptionValid[1] & vecCommitHasExceptionLastFlow[1])
                     | ~vecCommitHasExceptionValid[1]))
      | (onlyCommit0 & vecCommitHasExceptionLastFlow[0]);

    vecExceptionFlagCancel = 1'b0;
    for (int i = 0; i < N_ENSBUF; i++) begin
      automatic logic [5:0] p = dataBuffer_enq_sqPtr[i].value;
      if (vecLastFlow[p]
          & ({uop_robIdx_flag[p], uop_robIdx_value[p]}
             == {vecExceptionFlag_robIdx_flag, vecExceptionFlag_robIdx_value})
          & dataBuffer_enq_fire[i] & dataBuffer_enq_sqNeedDeq[i])
        vecExceptionFlagCancel = 1'b1;
    end
  end

  // ---- 冲刷：比重定向点更年轻的、还没提交的条目全部作废 ----
  // ★向量旗标立着的时候判据不一样★：只看 isAfter，不看 level（flushItself）。
  // 这不是化简，是 golden 的两支 Mux，两支的语义确实不同。
  always_comb begin
    for (int j = 0; j < SQ_SIZE; j++)
      needCancel[j] = allocated[j] & ~committed[j]
                    & (vecExceptionFlag_valid
                       ? (rob_after(uop_robIdx_flag[j], uop_robIdx_value[j],
                                    io_brqRedirect_bits_robIdx_flag,
                                    io_brqRedirect_bits_robIdx_value) & io_brqRedirect_valid)
                       : rob_need_flush(uop_robIdx_flag[j], uop_robIdx_value[j],
                                        io_brqRedirect_valid,
                                        io_brqRedirect_bits_robIdx_flag,
                                        io_brqRedirect_bits_robIdx_value,
                                        io_brqRedirect_bits_level));
  end

  // ---- 向量 merge buffer 的 commit/flush 反馈 ----
  logic [SQ_SIZE-1:0] vecCommit;
  always_comb begin
    for (int j = 0; j < SQ_SIZE; j++) begin
      vecCommit[j] = 1'b0;
      for (int k = 0; k < N_VECFB; k++)
        if (vecFeedback_in[k].valid
            & (vecFeedback_in[k].bits_feedback_1 | vecFeedback_in[k].bits_feedback_0) // COMMIT|FLUSH
            & ({uop_robIdx_flag[j], uop_robIdx_value[j]}
               == {vecFeedback_in[k].bits_robidx_flag, vecFeedback_in[k].bits_robidx_value})
            & (uop_uopIdx[j] == vecFeedback_in[k].bits_uopidx)
            & allocated[j])
          vecCommit[j] = 1'b1;
    end
  end

// -----------------------------------------------------------------------------
// §19 输出驱动
// -----------------------------------------------------------------------------
  // 本节里「一根一行」的几段（readyVec 各 56 根、cboZeroStout 的 24 根 exceptionVec、
  // 两份 uop 快照的 debugInfo）由 scratchpad/sqbuild/gen_out.py 机械生成：
  // golden 端口是 firtool 展平的标量，没有向量形态可用。

  // ---- 队列状态 ----
  assign io_sqFull          = ~allowEnqueue;
  assign io_sqEmpty         = sqEmptyReg;
  assign io_sqCancelCnt     = redirectCancelCount[5:0];
  assign io_sqDeq           = sqDeqReg;
  assign io_sqDeqIsVec      = isVec[deqPtr];
  assign io_force_write     = forceWriteReg;
  assign io_wfi_wfiSafe     = wfiSafeReg;

  // ---- 四个对外指针 ----
  assign io_stIssuePtr_flag       = enqPtrExt.flag;
  assign io_stIssuePtr_value      = enqPtrExt.value;
  assign io_sqDeqPtr_flag         = deqPtrExt[0].flag;
  assign io_sqDeqPtr_value        = deqPtrExt[0].value;
  assign io_sqCommitPtr_flag      = cmtPtrFlag;
  assign io_sqCommitPtr_value     = cmtPtrValue[0];
  assign io_sqCommitUopIdx        = uop_uopIdx[cmtPtr];
  assign io_sqCommitRobIdx_flag   = uop_robIdx_flag[cmtPtr];
  assign io_sqCommitRobIdx_value  = uop_robIdx_value[cmtPtr];
  assign io_stAddrReadySqPtr_flag  = addrReadyPtrExt.flag;
  assign io_stAddrReadySqPtr_value = addrReadyPtrExt.value;
  assign io_stDataReadySqPtr_flag  = dataReadyPtrExt.flag;
  assign io_stDataReadySqPtr_value = dataReadyPtrExt.value;

  // ---- 两条 56 位就绪向量 ----
  assign io_stAddrReadyVec_0 = stAddrReadyVec_q[0];
  assign io_stAddrReadyVec_1 = stAddrReadyVec_q[1];
  assign io_stAddrReadyVec_2 = stAddrReadyVec_q[2];
  assign io_stAddrReadyVec_3 = stAddrReadyVec_q[3];
  assign io_stAddrReadyVec_4 = stAddrReadyVec_q[4];
  assign io_stAddrReadyVec_5 = stAddrReadyVec_q[5];
  assign io_stAddrReadyVec_6 = stAddrReadyVec_q[6];
  assign io_stAddrReadyVec_7 = stAddrReadyVec_q[7];
  assign io_stAddrReadyVec_8 = stAddrReadyVec_q[8];
  assign io_stAddrReadyVec_9 = stAddrReadyVec_q[9];
  assign io_stAddrReadyVec_10 = stAddrReadyVec_q[10];
  assign io_stAddrReadyVec_11 = stAddrReadyVec_q[11];
  assign io_stAddrReadyVec_12 = stAddrReadyVec_q[12];
  assign io_stAddrReadyVec_13 = stAddrReadyVec_q[13];
  assign io_stAddrReadyVec_14 = stAddrReadyVec_q[14];
  assign io_stAddrReadyVec_15 = stAddrReadyVec_q[15];
  assign io_stAddrReadyVec_16 = stAddrReadyVec_q[16];
  assign io_stAddrReadyVec_17 = stAddrReadyVec_q[17];
  assign io_stAddrReadyVec_18 = stAddrReadyVec_q[18];
  assign io_stAddrReadyVec_19 = stAddrReadyVec_q[19];
  assign io_stAddrReadyVec_20 = stAddrReadyVec_q[20];
  assign io_stAddrReadyVec_21 = stAddrReadyVec_q[21];
  assign io_stAddrReadyVec_22 = stAddrReadyVec_q[22];
  assign io_stAddrReadyVec_23 = stAddrReadyVec_q[23];
  assign io_stAddrReadyVec_24 = stAddrReadyVec_q[24];
  assign io_stAddrReadyVec_25 = stAddrReadyVec_q[25];
  assign io_stAddrReadyVec_26 = stAddrReadyVec_q[26];
  assign io_stAddrReadyVec_27 = stAddrReadyVec_q[27];
  assign io_stAddrReadyVec_28 = stAddrReadyVec_q[28];
  assign io_stAddrReadyVec_29 = stAddrReadyVec_q[29];
  assign io_stAddrReadyVec_30 = stAddrReadyVec_q[30];
  assign io_stAddrReadyVec_31 = stAddrReadyVec_q[31];
  assign io_stAddrReadyVec_32 = stAddrReadyVec_q[32];
  assign io_stAddrReadyVec_33 = stAddrReadyVec_q[33];
  assign io_stAddrReadyVec_34 = stAddrReadyVec_q[34];
  assign io_stAddrReadyVec_35 = stAddrReadyVec_q[35];
  assign io_stAddrReadyVec_36 = stAddrReadyVec_q[36];
  assign io_stAddrReadyVec_37 = stAddrReadyVec_q[37];
  assign io_stAddrReadyVec_38 = stAddrReadyVec_q[38];
  assign io_stAddrReadyVec_39 = stAddrReadyVec_q[39];
  assign io_stAddrReadyVec_40 = stAddrReadyVec_q[40];
  assign io_stAddrReadyVec_41 = stAddrReadyVec_q[41];
  assign io_stAddrReadyVec_42 = stAddrReadyVec_q[42];
  assign io_stAddrReadyVec_43 = stAddrReadyVec_q[43];
  assign io_stAddrReadyVec_44 = stAddrReadyVec_q[44];
  assign io_stAddrReadyVec_45 = stAddrReadyVec_q[45];
  assign io_stAddrReadyVec_46 = stAddrReadyVec_q[46];
  assign io_stAddrReadyVec_47 = stAddrReadyVec_q[47];
  assign io_stAddrReadyVec_48 = stAddrReadyVec_q[48];
  assign io_stAddrReadyVec_49 = stAddrReadyVec_q[49];
  assign io_stAddrReadyVec_50 = stAddrReadyVec_q[50];
  assign io_stAddrReadyVec_51 = stAddrReadyVec_q[51];
  assign io_stAddrReadyVec_52 = stAddrReadyVec_q[52];
  assign io_stAddrReadyVec_53 = stAddrReadyVec_q[53];
  assign io_stAddrReadyVec_54 = stAddrReadyVec_q[54];
  assign io_stAddrReadyVec_55 = stAddrReadyVec_q[55];
  assign io_stDataReadyVec_0 = stDataReadyVec_q[0];
  assign io_stDataReadyVec_1 = stDataReadyVec_q[1];
  assign io_stDataReadyVec_2 = stDataReadyVec_q[2];
  assign io_stDataReadyVec_3 = stDataReadyVec_q[3];
  assign io_stDataReadyVec_4 = stDataReadyVec_q[4];
  assign io_stDataReadyVec_5 = stDataReadyVec_q[5];
  assign io_stDataReadyVec_6 = stDataReadyVec_q[6];
  assign io_stDataReadyVec_7 = stDataReadyVec_q[7];
  assign io_stDataReadyVec_8 = stDataReadyVec_q[8];
  assign io_stDataReadyVec_9 = stDataReadyVec_q[9];
  assign io_stDataReadyVec_10 = stDataReadyVec_q[10];
  assign io_stDataReadyVec_11 = stDataReadyVec_q[11];
  assign io_stDataReadyVec_12 = stDataReadyVec_q[12];
  assign io_stDataReadyVec_13 = stDataReadyVec_q[13];
  assign io_stDataReadyVec_14 = stDataReadyVec_q[14];
  assign io_stDataReadyVec_15 = stDataReadyVec_q[15];
  assign io_stDataReadyVec_16 = stDataReadyVec_q[16];
  assign io_stDataReadyVec_17 = stDataReadyVec_q[17];
  assign io_stDataReadyVec_18 = stDataReadyVec_q[18];
  assign io_stDataReadyVec_19 = stDataReadyVec_q[19];
  assign io_stDataReadyVec_20 = stDataReadyVec_q[20];
  assign io_stDataReadyVec_21 = stDataReadyVec_q[21];
  assign io_stDataReadyVec_22 = stDataReadyVec_q[22];
  assign io_stDataReadyVec_23 = stDataReadyVec_q[23];
  assign io_stDataReadyVec_24 = stDataReadyVec_q[24];
  assign io_stDataReadyVec_25 = stDataReadyVec_q[25];
  assign io_stDataReadyVec_26 = stDataReadyVec_q[26];
  assign io_stDataReadyVec_27 = stDataReadyVec_q[27];
  assign io_stDataReadyVec_28 = stDataReadyVec_q[28];
  assign io_stDataReadyVec_29 = stDataReadyVec_q[29];
  assign io_stDataReadyVec_30 = stDataReadyVec_q[30];
  assign io_stDataReadyVec_31 = stDataReadyVec_q[31];
  assign io_stDataReadyVec_32 = stDataReadyVec_q[32];
  assign io_stDataReadyVec_33 = stDataReadyVec_q[33];
  assign io_stDataReadyVec_34 = stDataReadyVec_q[34];
  assign io_stDataReadyVec_35 = stDataReadyVec_q[35];
  assign io_stDataReadyVec_36 = stDataReadyVec_q[36];
  assign io_stDataReadyVec_37 = stDataReadyVec_q[37];
  assign io_stDataReadyVec_38 = stDataReadyVec_q[38];
  assign io_stDataReadyVec_39 = stDataReadyVec_q[39];
  assign io_stDataReadyVec_40 = stDataReadyVec_q[40];
  assign io_stDataReadyVec_41 = stDataReadyVec_q[41];
  assign io_stDataReadyVec_42 = stDataReadyVec_q[42];
  assign io_stDataReadyVec_43 = stDataReadyVec_q[43];
  assign io_stDataReadyVec_44 = stDataReadyVec_q[44];
  assign io_stDataReadyVec_45 = stDataReadyVec_q[45];
  assign io_stDataReadyVec_46 = stDataReadyVec_q[46];
  assign io_stDataReadyVec_47 = stDataReadyVec_q[47];
  assign io_stDataReadyVec_48 = stDataReadyVec_q[48];
  assign io_stDataReadyVec_49 = stDataReadyVec_q[49];
  assign io_stDataReadyVec_50 = stDataReadyVec_q[50];
  assign io_stDataReadyVec_51 = stDataReadyVec_q[51];
  assign io_stDataReadyVec_52 = stDataReadyVec_q[52];
  assign io_stDataReadyVec_53 = stDataReadyVec_q[53];
  assign io_stDataReadyVec_54 = stDataReadyVec_q[54];
  assign io_stDataReadyVec_55 = stDataReadyVec_q[55];

  // ---- 异常地址（全部来自 exceptionBuffer）----
  assign io_exceptionAddr_vaddr             = exceptionBuffer_vaddr;
  assign io_exceptionAddr_vaNeedExt         = exceptionBuffer_vaNeedExt;
  assign io_exceptionAddr_isHyper           = exceptionBuffer_isHyper;
  assign io_exceptionAddr_gpaddr            = exceptionBuffer_gpaddr;
  assign io_exceptionAddr_isForVSnonLeafPTE = exceptionBuffer_isForVSnonLeafPTE;

  // ---- uncache 请求（mmio 优先，否则 NC）----
  assign io_uncache_req_bits_robIdx_flag  = mmioReq_valid ? mmioReq_robIdx_flag  : ncReq_robIdx_flag;
  assign io_uncache_req_bits_robIdx_value = mmioReq_valid ? mmioReq_robIdx_value : ncReq_robIdx_value;
  assign io_uncache_req_bits_addr         = mmioReq_valid ? mmioReq_addr  : ncReq_addr;
  assign io_uncache_req_bits_vaddr        = mmioReq_valid ? mmioReq_vaddr : ncReq_vaddr;
  assign io_uncache_req_bits_data         = mmioReq_valid ? mmioReq_data  : ncReq_data;
  assign io_uncache_req_bits_mask         = mmioReq_valid ? mmioReq_mask  : ncReq_mask;
  assign io_uncache_req_bits_id           = mmioReq_valid ? mmioReq_id    : ncWaitRespPtrReg;
  assign io_uncache_req_bits_nc           = ~mmioReq_valid;
  assign io_uncache_req_bits_memBackTypeMM= mmioReq_valid ? mmioReq_memBackTypeMM : ncReq_memBackTypeMM;

  // ---- mmio 回写 ROB（读的全是 uncacheUop 这组**锁存值**，见 §TRAP-G）----
  assign io_mmioStout_valid = mmioStoutValid;
  // ExceptionNO.selectByFu(·, StaCfg) 之后只剩这两位，golden 连寄存器都只留了两个。
  assign io_mmioStout_bits_uop_exceptionVec_7  = uncacheUop_excStoreAccessFault;
  assign io_mmioStout_bits_uop_exceptionVec_19 = uncacheUop_excHardwareError;
  assign io_mmioStout_bits_uop_rfWen     = uncacheUop_rfWen;
  // CMO 要靠 flushPipe 保住顺序。
  assign io_mmioStout_bits_uop_flushPipe = deqCanDoCbo;
  assign io_mmioStout_bits_uop_pdest     = uncacheUop_pdest;
  assign io_mmioStout_bits_uop_robIdx_flag  = uncacheUop_robIdx_flag;
  assign io_mmioStout_bits_uop_robIdx_value = uncacheUop_robIdx_value;
  assign io_mmioStout_bits_uop_debugInfo_eliminatedMove = uncacheUop_debugInfo_eliminatedMove;
  assign io_mmioStout_bits_uop_debugInfo_renameTime = uncacheUop_debugInfo_renameTime;
  assign io_mmioStout_bits_uop_debugInfo_dispatchTime = uncacheUop_debugInfo_dispatchTime;
  assign io_mmioStout_bits_uop_debugInfo_enqRsTime = uncacheUop_debugInfo_enqRsTime;
  assign io_mmioStout_bits_uop_debugInfo_selectTime = uncacheUop_debugInfo_selectTime;
  assign io_mmioStout_bits_uop_debugInfo_issueTime = uncacheUop_debugInfo_issueTime;
  assign io_mmioStout_bits_uop_debugInfo_writebackTime = uncacheUop_debugInfo_writebackTime;
  assign io_mmioStout_bits_uop_debugInfo_runahead_checkpoint_id = uncacheUop_debugInfo_runahead_checkpoint_id;
  assign io_mmioStout_bits_uop_debugInfo_tlbFirstReqTime = uncacheUop_debugInfo_tlbFirstReqTime;
  assign io_mmioStout_bits_uop_debugInfo_tlbRespTime = uncacheUop_debugInfo_tlbRespTime;
  assign io_mmioStout_bits_uop_debug_seqNum_seqNum = uncacheUop_debug_seqNum_seqNum;
  assign io_mmioStout_bits_uop_debug_seqNum_uopIdx = uncacheUop_debug_seqNum_uopIdx;
  assign io_mmioStout_bits_uop_sqIdx_flag  = deqPtrExt[0].flag;
  assign io_mmioStout_bits_uop_sqIdx_value = deqPtrExt[0].value;
  // shiftDataToLow：按 paddr 第 3 位挑 128 位里的哪半边。
  assign io_mmioStout_bits_data = paddrModule_rdata[0][3] ? dataModule_rdata_data[0][127:64]
                                                          : dataModule_rdata_data[0][63:0];
  assign io_mmioStout_bits_debug_isMMIO = ~memBackTypeMM[deqPtr];

  // ---- cbo.zero 回写 ROB ----
  assign io_cboZeroStout_valid = cboZeroStoutValid;
  assign io_cboZeroStout_bits_uop_exceptionVec_0 = cboZeroUop_exceptionVec[0];
  assign io_cboZeroStout_bits_uop_exceptionVec_1 = cboZeroUop_exceptionVec[1];
  assign io_cboZeroStout_bits_uop_exceptionVec_2 = cboZeroUop_exceptionVec[2];
  assign io_cboZeroStout_bits_uop_exceptionVec_3 = cboZeroUop_exceptionVec[3];
  assign io_cboZeroStout_bits_uop_exceptionVec_4 = cboZeroUop_exceptionVec[4];
  assign io_cboZeroStout_bits_uop_exceptionVec_5 = cboZeroUop_exceptionVec[5];
  assign io_cboZeroStout_bits_uop_exceptionVec_6 = cboZeroUop_exceptionVec[6];
  assign io_cboZeroStout_bits_uop_exceptionVec_7 = cboZeroUop_exceptionVec[7];
  assign io_cboZeroStout_bits_uop_exceptionVec_8 = cboZeroUop_exceptionVec[8];
  assign io_cboZeroStout_bits_uop_exceptionVec_9 = cboZeroUop_exceptionVec[9];
  assign io_cboZeroStout_bits_uop_exceptionVec_10 = cboZeroUop_exceptionVec[10];
  assign io_cboZeroStout_bits_uop_exceptionVec_11 = cboZeroUop_exceptionVec[11];
  assign io_cboZeroStout_bits_uop_exceptionVec_12 = cboZeroUop_exceptionVec[12];
  assign io_cboZeroStout_bits_uop_exceptionVec_13 = cboZeroUop_exceptionVec[13];
  assign io_cboZeroStout_bits_uop_exceptionVec_14 = cboZeroUop_exceptionVec[14];
  assign io_cboZeroStout_bits_uop_exceptionVec_15 = cboZeroUop_exceptionVec[15];
  assign io_cboZeroStout_bits_uop_exceptionVec_16 = cboZeroUop_exceptionVec[16];
  assign io_cboZeroStout_bits_uop_exceptionVec_17 = cboZeroUop_exceptionVec[17];
  assign io_cboZeroStout_bits_uop_exceptionVec_18 = cboZeroUop_exceptionVec[18];
  assign io_cboZeroStout_bits_uop_exceptionVec_19 = cboZeroUop_exceptionVec[19];
  assign io_cboZeroStout_bits_uop_exceptionVec_20 = cboZeroUop_exceptionVec[20];
  assign io_cboZeroStout_bits_uop_exceptionVec_21 = cboZeroUop_exceptionVec[21];
  assign io_cboZeroStout_bits_uop_exceptionVec_22 = cboZeroUop_exceptionVec[22];
  assign io_cboZeroStout_bits_uop_exceptionVec_23 = cboZeroUop_exceptionVec[23];
  assign io_cboZeroStout_bits_uop_trigger      = cboZeroUop_trigger;
  assign io_cboZeroStout_bits_uop_rfWen        = cboZeroUop_rfWen;
  assign io_cboZeroStout_bits_uop_flushPipe    = cboZeroUop_flushPipe;
  assign io_cboZeroStout_bits_uop_pdest        = cboZeroUop_pdest;
  assign io_cboZeroStout_bits_uop_robIdx_flag  = cboZeroUop_robIdx_flag;
  assign io_cboZeroStout_bits_uop_robIdx_value = cboZeroUop_robIdx_value;
  assign io_cboZeroStout_bits_uop_debugInfo_eliminatedMove = cboZeroUop_debugInfo_eliminatedMove;
  assign io_cboZeroStout_bits_uop_debugInfo_renameTime = cboZeroUop_debugInfo_renameTime;
  assign io_cboZeroStout_bits_uop_debugInfo_dispatchTime = cboZeroUop_debugInfo_dispatchTime;
  assign io_cboZeroStout_bits_uop_debugInfo_enqRsTime = cboZeroUop_debugInfo_enqRsTime;
  assign io_cboZeroStout_bits_uop_debugInfo_selectTime = cboZeroUop_debugInfo_selectTime;
  assign io_cboZeroStout_bits_uop_debugInfo_issueTime = cboZeroUop_debugInfo_issueTime;
  assign io_cboZeroStout_bits_uop_debugInfo_writebackTime = cboZeroUop_debugInfo_writebackTime;
  assign io_cboZeroStout_bits_uop_debugInfo_runahead_checkpoint_id = cboZeroUop_debugInfo_runahead_checkpoint_id;
  assign io_cboZeroStout_bits_uop_debugInfo_tlbFirstReqTime = cboZeroUop_debugInfo_tlbFirstReqTime;
  assign io_cboZeroStout_bits_uop_debugInfo_tlbRespTime = cboZeroUop_debugInfo_tlbRespTime;
  assign io_cboZeroStout_bits_uop_debug_seqNum_seqNum = cboZeroUop_debug_seqNum_seqNum;
  assign io_cboZeroStout_bits_uop_debug_seqNum_uopIdx = cboZeroUop_debug_seqNum_uopIdx;
  assign io_cboZeroStout_bits_uop_sqIdx_flag  = cboZeroSqIdx_flag;
  assign io_cboZeroStout_bits_uop_sqIdx_value = cboZeroSqIdx_value;

  // ---- 8 路 perf 事件（两级打拍后各占 1 位）----
  assign perf_out[0].value = {5'h0, perfValueReg_1[0]};
  assign perf_out[1].value = {5'h0, perfValueReg_1[1]};
  assign perf_out[2].value = {5'h0, perfValueReg_1[2]};
  assign perf_out[3].value = {5'h0, perfValueReg_1[3]};
  assign perf_out[4].value = {5'h0, perfValueReg_1[4]};
  assign perf_out[5].value = {5'h0, perfValueReg_1[5]};
  assign perf_out[6].value = {5'h0, perfValueReg_1[6]};
  assign perf_out[7].value = {5'h0, perfValueReg_1[7]};

  // ---- difftest 的 cbo.inval 事件（打包成一根 73 位 bore 送出去）----
  wire        cmoInvalEvent_valid  = mmioStoutFire & deqCanDoCbo
                                   & (&uop_fuOpType[deqPtr][3:2]) & ~(|uop_fuOpType[deqPtr][6:4])
                                   & (uop_fuOpType[deqPtr][3:0] == 4'hE);   // LSUOpType.isCboInval
  wire [63:0] cmoInvalEvent_addr   = {16'h0, cboMmioPAddr};
  wire [7:0]  cmoInvalEvent_coreid = {2'h0, io_hartId};
  assign gatewayIn_packed_48_bore = {cmoInvalEvent_valid, cmoInvalEvent_addr, cmoInvalEvent_coreid};

// -----------------------------------------------------------------------------
// §20 时序（一）：★不复位★块（对应 golden L20336-58753 的 2913 个寄存器）
// -----------------------------------------------------------------------------
  // 这里**故意没有 if (reset)**——golden 这一整块不复位。加上复位就是真 bug：
  // elaborate 与 lint 都不会报，UT 也很难打到，只有 FM 会把初值差异揪出来。
  always_ff @(posedge clock) begin
    // ---- 每条目的 uop 快照与调试载荷 ----
    for (int j = 0; j < SQ_SIZE; j++) begin
      // uop 载荷：sta 口1 > sta 口0 > 入队。（golden L20337 的三层 if/else）
      if (staFire[1] && stWbIndex[1] == 6'(j)) begin
        uop_exceptionVec[j] <= staExceptionVec[1];
        uop_trigger[j] <= storeAddrIn_in[1].bits_uop_trigger;
        uop_fuType[j] <= storeAddrIn_in[1].bits_uop_fuType;
        uop_fuOpType[j] <= storeAddrIn_in[1].bits_uop_fuOpType;
        uop_rfWen[j] <= storeAddrIn_in[1].bits_uop_rfWen;
        // ★golden 的 storeAddrIn 端口表里没有 flushPipe★（firtool 全局 DCE 判它恒 0）
        // —— sta 写入会把它**清成 0**，不是保持。抹平成保持是真 bug。
        uop_flushPipe[j] <= 1'b0;
        uop_vpu_nf[j] <= storeAddrIn_in[1].bits_uop_vpu_nf;
        uop_vpu_veew[j] <= storeAddrIn_in[1].bits_uop_vpu_veew;
        uop_uopIdx[j] <= storeAddrIn_in[1].bits_uop_uopIdx;
        uop_pdest[j] <= storeAddrIn_in[1].bits_uop_pdest;
        uop_robIdx_flag[j] <= storeAddrIn_in[1].bits_uop_robIdx_flag;
        uop_robIdx_value[j] <= storeAddrIn_in[1].bits_uop_robIdx_value;
        uop_debugInfo_eliminatedMove[j] <= storeAddrIn_in[1].bits_uop_debugInfo_eliminatedMove;
        uop_debugInfo_renameTime[j] <= storeAddrIn_in[1].bits_uop_debugInfo_renameTime;
        uop_debugInfo_dispatchTime[j] <= storeAddrIn_in[1].bits_uop_debugInfo_dispatchTime;
        uop_debugInfo_enqRsTime[j] <= storeAddrIn_in[1].bits_uop_debugInfo_enqRsTime;
        uop_debugInfo_selectTime[j] <= storeAddrIn_in[1].bits_uop_debugInfo_selectTime;
        uop_debugInfo_issueTime[j] <= storeAddrIn_in[1].bits_uop_debugInfo_issueTime;
        uop_debugInfo_writebackTime[j] <= storeAddrIn_in[1].bits_uop_debugInfo_writebackTime;
        uop_debugInfo_runahead_checkpoint_id[j] <= storeAddrIn_in[1].bits_uop_debugInfo_runahead_checkpoint_id;
        uop_debugInfo_tlbFirstReqTime[j] <= storeAddrIn_in[1].bits_uop_debugInfo_tlbFirstReqTime;
        uop_debugInfo_tlbRespTime[j] <= storeAddrIn_in[1].bits_uop_debugInfo_tlbRespTime;
        uop_debug_seqNum_seqNum[j] <= storeAddrIn_in[1].bits_uop_debug_seqNum_seqNum;
        uop_debug_seqNum_uopIdx[j] <= storeAddrIn_in[1].bits_uop_debug_seqNum_uopIdx;
      end
      else if (staFire[0] && stWbIndex[0] == 6'(j)) begin
        uop_exceptionVec[j] <= staExceptionVec[0];
        uop_trigger[j] <= storeAddrIn_in[0].bits_uop_trigger;
        uop_fuType[j] <= storeAddrIn_in[0].bits_uop_fuType;
        uop_fuOpType[j] <= storeAddrIn_in[0].bits_uop_fuOpType;
        uop_rfWen[j] <= storeAddrIn_in[0].bits_uop_rfWen;
        // ★golden 的 storeAddrIn 端口表里没有 flushPipe★（firtool 全局 DCE 判它恒 0）
        // —— sta 写入会把它**清成 0**，不是保持。抹平成保持是真 bug。
        uop_flushPipe[j] <= 1'b0;
        uop_vpu_nf[j] <= storeAddrIn_in[0].bits_uop_vpu_nf;
        uop_vpu_veew[j] <= storeAddrIn_in[0].bits_uop_vpu_veew;
        uop_uopIdx[j] <= storeAddrIn_in[0].bits_uop_uopIdx;
        uop_pdest[j] <= storeAddrIn_in[0].bits_uop_pdest;
        uop_robIdx_flag[j] <= storeAddrIn_in[0].bits_uop_robIdx_flag;
        uop_robIdx_value[j] <= storeAddrIn_in[0].bits_uop_robIdx_value;
        uop_debugInfo_eliminatedMove[j] <= storeAddrIn_in[0].bits_uop_debugInfo_eliminatedMove;
        uop_debugInfo_renameTime[j] <= storeAddrIn_in[0].bits_uop_debugInfo_renameTime;
        uop_debugInfo_dispatchTime[j] <= storeAddrIn_in[0].bits_uop_debugInfo_dispatchTime;
        uop_debugInfo_enqRsTime[j] <= storeAddrIn_in[0].bits_uop_debugInfo_enqRsTime;
        uop_debugInfo_selectTime[j] <= storeAddrIn_in[0].bits_uop_debugInfo_selectTime;
        uop_debugInfo_issueTime[j] <= storeAddrIn_in[0].bits_uop_debugInfo_issueTime;
        uop_debugInfo_writebackTime[j] <= storeAddrIn_in[0].bits_uop_debugInfo_writebackTime;
        uop_debugInfo_runahead_checkpoint_id[j] <= storeAddrIn_in[0].bits_uop_debugInfo_runahead_checkpoint_id;
        uop_debugInfo_tlbFirstReqTime[j] <= storeAddrIn_in[0].bits_uop_debugInfo_tlbFirstReqTime;
        uop_debugInfo_tlbRespTime[j] <= storeAddrIn_in[0].bits_uop_debugInfo_tlbRespTime;
        uop_debug_seqNum_seqNum[j] <= storeAddrIn_in[0].bits_uop_debug_seqNum_seqNum;
        uop_debug_seqNum_uopIdx[j] <= storeAddrIn_in[0].bits_uop_debug_seqNum_uopIdx;
      end
      else if (entryCanEnq[j]) begin
        uop_exceptionVec[j] <= enqExceptionVec[enqSelPort[j]];
        uop_trigger[j] <= enq_req_in[enqSelPort[j]].bits_trigger;
        uop_fuType[j] <= enq_req_in[enqSelPort[j]].bits_fuType;
        uop_fuOpType[j] <= enq_req_in[enqSelPort[j]].bits_fuOpType;
        uop_rfWen[j] <= enq_req_in[enqSelPort[j]].bits_rfWen;
        uop_flushPipe[j] <= enq_req_in[enqSelPort[j]].bits_flushPipe;
        uop_vpu_nf[j] <= enq_req_in[enqSelPort[j]].bits_vpu_nf;
        uop_vpu_veew[j] <= enq_req_in[enqSelPort[j]].bits_vpu_veew;
        uop_uopIdx[j] <= enq_req_in[enqSelPort[j]].bits_uopIdx;
        uop_pdest[j] <= enq_req_in[enqSelPort[j]].bits_pdest;
        uop_robIdx_flag[j] <= enq_req_in[enqSelPort[j]].bits_robIdx_flag;
        uop_robIdx_value[j] <= enq_req_in[enqSelPort[j]].bits_robIdx_value;
        uop_debugInfo_eliminatedMove[j] <= enq_req_in[enqSelPort[j]].bits_debugInfo_eliminatedMove;
        uop_debugInfo_renameTime[j] <= enq_req_in[enqSelPort[j]].bits_debugInfo_renameTime;
        uop_debugInfo_dispatchTime[j] <= enq_req_in[enqSelPort[j]].bits_debugInfo_dispatchTime;
        uop_debugInfo_enqRsTime[j] <= enq_req_in[enqSelPort[j]].bits_debugInfo_enqRsTime;
        uop_debugInfo_selectTime[j] <= enq_req_in[enqSelPort[j]].bits_debugInfo_selectTime;
        uop_debugInfo_issueTime[j] <= enq_req_in[enqSelPort[j]].bits_debugInfo_issueTime;
        uop_debugInfo_writebackTime[j] <= enq_req_in[enqSelPort[j]].bits_debugInfo_writebackTime;
        uop_debugInfo_runahead_checkpoint_id[j] <= enq_req_in[enqSelPort[j]].bits_debugInfo_runahead_checkpoint_id;
        uop_debugInfo_tlbFirstReqTime[j] <= enq_req_in[enqSelPort[j]].bits_debugInfo_tlbFirstReqTime;
        uop_debugInfo_tlbRespTime[j] <= enq_req_in[enqSelPort[j]].bits_debugInfo_tlbRespTime;
        uop_debug_seqNum_seqNum[j] <= enq_req_in[enqSelPort[j]].bits_debug_seqNum_seqNum;
        uop_debug_seqNum_uopIdx[j] <= enq_req_in[enqSelPort[j]].bits_debug_seqNum_uopIdx;
      end

      // difftest 用的非对齐向量 offset：std 口1 > std 口0
      if (stdFire[1] && stdWbIndex[1] == 6'(j))
        debug_vec_unaligned_offset[j] <= storeDataIn_in[1].bits_vecDebug_offset;
      else if (stdFire[0] && stdWbIndex[0] == 6'(j))
        debug_vec_unaligned_offset[j] <= storeDataIn_in[0].bits_vecDebug_offset;
    end

    // ---- 冲刷相关的一拍/两拍打拍 ----
    if (io_brqRedirect_valid) begin
      lastCycleCancelVec <= needCancel;     // 冲掉几条，下一拍才数得出来
      lastEnqCancel      <= enqCancelNum;   // 入队侧被冲掉的 flow 数
    end
    lastCycleRedirect     <= io_brqRedirect_valid;
    lastlastCycleRedirect <= lastCycleRedirect;
    for (int k = 0; k < N_ENQ; k++) validVStoreFlow_q[k] <= io_brqRedirect_valid;

    // ---- sta / std 的流水打拍 ----
    for (int i = 0; i < N_STA; i++) begin
      storeAddrInFireReg_q[i] <= staFire[i] & ~storeAddrIn_in[i].bits_miss;
      if (staFire[i]) stWbIndexReg[i] <= stWbIndex[i];
    end
    for (int i = 0; i < N_STD; i++) begin
      storeDataInFireReg[i] <= stdFire[i];
      if (stdFire[i]) lastStWbIndex[i] <= stdWbIndex[i];
    end

    // ---- uncacheUop：★mmio 进入 s_req 的那一拍锁一次，之后一直读锁存值★ ----
    // （见 §TRAP-G：读 uop[deqPtr] 的 live 值是真 bug）
    mmioEnterReqReg <=
        io_rob_pendingst
      & ({uop_robIdx_flag[deqPtr], uop_robIdx_value[deqPtr]}
         == {io_rob_pendingPtr_flag, io_rob_pendingPtr_value})
      & pending[deqPtr] & allocated[deqPtr] & datavalid[deqPtr] & addrvalid[deqPtr]
      & ~hasException[deqPtr];

    if (mmioState == S_IDLE) begin
      // 进 s_req 时把异常位清零（Chisel: uncacheUop.exceptionVec := 0）
      uncacheUop_excStoreAccessFault <= ~mmioEnterReqReg & uncacheUop_excStoreAccessFault;
      uncacheUop_excHardwareError    <= ~mmioEnterReqReg & uncacheUop_excHardwareError;
    end
    else begin
      // s_resp 收到 denied/corrupt 就把对应异常位**或**上去
      uncacheUop_excStoreAccessFault <=
        ((mmioState == S_RESP) & uncacheRespFireNonNc & respDenied)  | uncacheUop_excStoreAccessFault;
      uncacheUop_excHardwareError <=
        ((mmioState == S_RESP) & uncacheRespFireNonNc & respCorrupt) | uncacheUop_excHardwareError;
    end

    if ((mmioState == S_IDLE) && mmioEnterReqReg) begin
      uncacheUop_fuOpType     <= uop_fuOpType[deqPtr];
      uncacheUop_rfWen        <= uop_rfWen[deqPtr];
      uncacheUop_uopIdx       <= uop_uopIdx[deqPtr];
      uncacheUop_pdest        <= uop_pdest[deqPtr];
      uncacheUop_robIdx_flag  <= uop_robIdx_flag[deqPtr];
      uncacheUop_robIdx_value <= uop_robIdx_value[deqPtr];
      uncacheUop_debugInfo_eliminatedMove          <= uop_debugInfo_eliminatedMove[deqPtr];
      uncacheUop_debugInfo_renameTime              <= uop_debugInfo_renameTime[deqPtr];
      uncacheUop_debugInfo_dispatchTime            <= uop_debugInfo_dispatchTime[deqPtr];
      uncacheUop_debugInfo_enqRsTime               <= uop_debugInfo_enqRsTime[deqPtr];
      uncacheUop_debugInfo_selectTime              <= uop_debugInfo_selectTime[deqPtr];
      uncacheUop_debugInfo_issueTime               <= uop_debugInfo_issueTime[deqPtr];
      uncacheUop_debugInfo_writebackTime           <= uop_debugInfo_writebackTime[deqPtr];
      uncacheUop_debugInfo_runahead_checkpoint_id  <= uop_debugInfo_runahead_checkpoint_id[deqPtr];
      uncacheUop_debugInfo_tlbFirstReqTime         <= uop_debugInfo_tlbFirstReqTime[deqPtr];
      uncacheUop_debugInfo_tlbRespTime             <= uop_debugInfo_tlbRespTime[deqPtr];
      uncacheUop_debug_seqNum_seqNum               <= uop_debug_seqNum_seqNum[deqPtr];
      uncacheUop_debug_seqNum_uopIdx               <= uop_debug_seqNum_uopIdx[deqPtr];
      // get_block_addr：CBO 的目标是整条 cache line（64B）
      cboMmioPAddr <= {paddrModule_rdata[0][47:6], 6'h0};
    end

    // ---- cbo.zero 的 uop 快照（两个口里下标小的赢）----
    if (cboZeroToSb) begin
      automatic logic [5:0] p = isCboZeroToSbVec[0] ? dataBuffer_deq_sqPtr[0].value
                                                    : dataBuffer_deq_sqPtr[1].value;
      cboZeroUop_exceptionVec  <= uop_exceptionVec[p];
      cboZeroUop_trigger       <= uop_trigger[p];
      cboZeroUop_rfWen         <= uop_rfWen[p];
      cboZeroUop_flushPipe     <= uop_flushPipe[p];
      cboZeroUop_pdest         <= uop_pdest[p];
      cboZeroUop_robIdx_flag   <= uop_robIdx_flag[p];
      cboZeroUop_robIdx_value  <= uop_robIdx_value[p];
      cboZeroUop_debugInfo_eliminatedMove         <= uop_debugInfo_eliminatedMove[p];
      cboZeroUop_debugInfo_renameTime             <= uop_debugInfo_renameTime[p];
      cboZeroUop_debugInfo_dispatchTime           <= uop_debugInfo_dispatchTime[p];
      cboZeroUop_debugInfo_enqRsTime              <= uop_debugInfo_enqRsTime[p];
      cboZeroUop_debugInfo_selectTime             <= uop_debugInfo_selectTime[p];
      cboZeroUop_debugInfo_issueTime              <= uop_debugInfo_issueTime[p];
      cboZeroUop_debugInfo_writebackTime          <= uop_debugInfo_writebackTime[p];
      cboZeroUop_debugInfo_runahead_checkpoint_id <= uop_debugInfo_runahead_checkpoint_id[p];
      cboZeroUop_debugInfo_tlbFirstReqTime        <= uop_debugInfo_tlbFirstReqTime[p];
      cboZeroUop_debugInfo_tlbRespTime            <= uop_debugInfo_tlbRespTime[p];
      cboZeroUop_debug_seqNum_seqNum              <= uop_debug_seqNum_seqNum[p];
      cboZeroUop_debug_seqNum_uopIdx              <= uop_debug_seqNum_uopIdx[p];
      cboZeroSqIdx_flag  <= isCboZeroToSbVec[0] ? dataBuffer_deq_sqPtr[0].flag
                                                : dataBuffer_deq_sqPtr[1].flag;
      cboZeroSqIdx_value <= isCboZeroToSbVec[0] ? dataBuffer_deq_sqPtr[0].value
                                                : dataBuffer_deq_sqPtr[1].value;
    end

    // ---- 转发通路的打拍 ----
    for (int i = 0; i < N_FWD; i++) begin
      if (forward_in[i].valid) begin
        fwdPaddrMmask_q[i]         <= paddrModule_forwardMmask[i];
        fwdVaddrMmask_q[i]         <= vaddrModule_forwardMmask[i];
        // ★golden 为同一个 RegEnable(loadWaitStrict, valid) 摇了两份寄存器★
        //   （Chisel 里这个表达式出现了两次，firtool 没做 CSE）——照抄两份，
        //   少一份会在 FM 里变成 unmatched。
        fwdLoadWaitStrict_sel_q[i] <= forward_in[i].uop_loadWaitStrict;
        fwdLoadWaitStrict_inv_q[i] <= forward_in[i].uop_loadWaitStrict;
        fwdSqIdxMinus1_q[i] <= sqptr_sub('{flag:  forward_in[i].uop_sqIdx_flag,
                                           value: forward_in[i].uop_sqIdx_value}, 8'h1);
        fwdSqIdxA_q[i]      <= '{flag: forward_in[i].uop_sqIdx_flag,
                                 value: forward_in[i].uop_sqIdx_value};
        fwdSqIdxD_q[i]      <= '{flag: forward_in[i].uop_sqIdx_flag,
                                 value: forward_in[i].uop_sqIdx_value};
      end
      needForward_q[i]       <= needForward[i];
      fwdValid_q[i]          <= forward_in[i].valid;
      dataInvalidMask1Reg[i] <= dataInvalidMask1[i];
      dataInvalidMask2Reg[i] <= dataInvalidMask2[i];
      addrInvalidMask1Reg[i] <= addrInvalidMask1[i];
      addrInvalidMask2Reg[i] <= addrInvalidMask2[i];
      fwdDataInvalid_q[i]    <= |(dataInvalidMask1[i] | dataInvalidMask2[i]);
      fwdHasInvalidAddr_q[i] <= hasInvalidAddr[i];
      s2_differentFlag[i]    <= differentFlag[i];
      s2_enqPtrFlag[i]       <= enqPtrExt.flag;
      s2_deqPtr[i]           <= deqPtrExt[0];
    end

    // ---- 输出打拍 ----
    sqDeqReg   <= sqDeqCnt;
    sqEmptyReg <= (enqPtrExt.value == deqPtrExt[0].value)
                & (enqPtrExt.flag  == deqPtrExt[0].flag);
    // golden 的 REG / REG_1：只喂 `assert(!RegNext(RegNext(sbuffer(0).fire) && mmioStout.fire))`。
    // 本仓按 SYNTHESIS 编译，断言不生成 —— 但寄存器本身 golden 留着，
    // 少写一个 FM 就会多出一个 unmatched 点，所以照留。
    mmioStoutFireRegChain   <= sbufferFire[0];
    mmioStoutFireRegChain_1 <= mmioStoutFireRegChain & mmioStoutFire;

    // ---- 8 路 perf 事件，各走两级打拍 ----
    perfValueReg[0] <= (|mmioState);                                  // mmioCycle
    perfValueReg[1] <= mmioDoReq;                                     // mmioCnt
    perfValueReg[2] <= mmioStoutFire;                                 // mmio_wb_success
    perfValueReg[3] <= mmioStoutValid & ~io_mmioStout_ready;          // mmio_wb_blocked
    perfValueReg[4] <= validCount < 6'hE;                             // stq_1_4_valid
    perfValueReg[5] <= (validCount > 6'hE) & (validCount < 6'h1D);    // stq_2_4_valid
    // 3/4 与 4/4 两档的门限 42 放不进 6 位，golden 在 8 位里比，这里照抄宽度。
    perfValueReg[6] <= (validCount > 6'h1C) & ({2'h0, validCount} < 8'h2B);
    perfValueReg[7] <= {2'h0, validCount} > 8'h2A;                    // stq_4_4_valid
    for (int i = 0; i < N_PERF; i++) perfValueReg_1[i] <= perfValueReg[i];
  end

// -----------------------------------------------------------------------------
// §21 「completed」的 4 个置位源（出队的四条路各有一个）
// -----------------------------------------------------------------------------
  logic [SQ_SIZE-1:0] sbufferCompleteSet;  // 写进 Sbuffer 了
  logic [SQ_SIZE-1:0] mmioCompleteSet;     // mmio 回写 ROB 了
  logic [SQ_SIZE-1:0] cboZeroCompleteSet;  // cbo.zero 回写 ROB 了
  logic [SQ_SIZE-1:0] ncCompleteSet;       // NC 请求被 ubuffer 收下/回了

  always_comb begin
    sbufferCompleteSet = '0;
    mmioCompleteSet    = '0;
    cboZeroCompleteSet = '0;
    ncCompleteSet      = '0;
    for (int i = 0; i < N_ENSBUF; i++)
      // ★wline（cbo.zero 整行写）不走这条★：它由 cboZeroStout 那边收尾。
      if (sbufferFire[i] & dataBuffer_deq_sqNeedDeq[i] & ~sbufferWline[i])
        sbufferCompleteSet[dataBuffer_deq_sqPtr[i].value] = 1'b1;
    if (mmioStoutFire)    mmioCompleteSet[deqPtr]                = 1'b1;
    if (cboZeroStoutFire) cboZeroCompleteSet[cboZeroSqIdx_value] = 1'b1;
    // ★ncPtr 在这里是 6 位★：uncacheIdxBits 是 7 位，但 Chisel 用它去索引
    // Vec(56) 时 firtool 只保留 log2Up(56)=6 位（golden L58933 明写
    // `io_uncache_idResp_bits_mid[5:0]`）。用 7 位全宽比会让 mid[6]=1 的那一半
    // 请求一条都命中不到 —— 本轮实测就是靠这条把 completed 的首次失配
    // （cycle 10，golden 置了条目 22 而重写没置）定下来的。
    for (int j = 0; j < SQ_SIZE; j++)
      if (ncDeqTrigger && ncPtr[5:0] == 6'(j)) ncCompleteSet[j] = 1'b1;
  end


// -----------------------------------------------------------------------------
// §22 perf 观测探针（golden 同名导出；docs/perf_bore_map.tsv 按名字重绑）
// -----------------------------------------------------------------------------
  // ★这些不是"调试信号"，是 perf 台账的观测点★：名字必须与 golden 逐字相同，
  // 而且必须由真逻辑驱动 —— 接零会让台账把「测不出差异」误报成「一致」。
  logic [5:0] vecValidCount;
  always_comb begin
    automatic logic [SQ_SIZE-1:0] vecValidVec;
    for (int j = 0; j < SQ_SIZE; j++) vecValidVec[j] = allocated[j] & isVec[j];
    vecValidCount = 6'($countones(vecValidVec));
  end

  wire [5:0] validCount_probe      = validCount;
  wire       _io_sqFull_T_probe    = ~allowEnqueue;
  wire       _io_sqFull_T_probe_0  = ~allowEnqueue;
  wire       exHalf_probe          = validCount > 6'h1C;   // QueuePerf: 过半
  wire       empty_probe           = validCount == 6'h0;
  wire       exHalf_1_probe        = vecValidCount > 6'h1C; // 向量条目那一组
  wire       empty_1_probe         = vecValidCount == 6'h0;
  wire       mmioDoReq_probe       = mmioDoReq;
  wire       perfEvents_0_2_probe  = (|mmioState);
  wire       perfEvents_2_2_probe  = mmioStoutFire;


// -----------------------------------------------------------------------------
// §23 时序（二）：异步复位块（对应 golden L62202-69650 的 1076 个寄存器）
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
      // 指针的复位初值：第 i 份从条目 i 开始，flag=0。
      enqPtrExt        <= '{flag: 1'b0, value: 6'd0};
      for (int i = 0; i < N_ENSBUF; i++) begin
        deqPtrExt[i]   <= '{flag: 1'b0, value: 6'(i)};
        rdataPtrExt[i] <= '{flag: 1'b0, value: 6'(i)};
      end
      for (int i = 0; i < N_COMMIT; i++) cmtPtrValue[i] <= 6'(i);
      cmtPtrFlag       <= 1'b0;
      addrReadyPtrExt  <= '{flag: 1'b0, value: 6'd0};
      dataReadyPtrExt  <= '{flag: 1'b0, value: 6'd0};
      mmioState        <= S_IDLE;
      ncState          <= NC_IDLE;
      noPending        <= 1'b1;            // ★复位成 1，不是 0★
      cboFlushedSb     <= 1'b0;
      cboZeroOffset    <= 3'd0;
      cboZeroValid     <= 1'b0;
      cboZeroWaitFlushSb <= 1'b0;
      ncWaitRespPtrReg <= 7'd0;
      vecExceptionFlag_valid        <= 1'b0;
      vecExceptionFlag_robIdx_flag  <= 1'b0;
      vecExceptionFlag_robIdx_value <= 8'd0;
      timeoutCounter   <= 32'd0;
      scommit          <= 4'd0;
      redirectCancelCount <= 8'd0;
      forceWriteReg    <= 1'b0;
      wfiSafeReg       <= 1'b0;
      cboZeroFlushSb   <= 1'b0;
      deqCanDoCboReg   <= 1'b0;
      for (int i = 0; i < N_COMMIT; i++) begin
        pendingPtrReg_flag[i]  <= 1'b0;
        pendingPtrReg_value[i] <= 8'd0;
      end
      mmioReqRobIdxPtr  <= '{flag: 1'b0, value: 6'd0};
      mmioReqMemBackPtr <= '{flag: 1'b0, value: 6'd0};
      ncReqRobIdxPtr    <= '{flag: 1'b0, value: 6'd0};
      ncReqMemBackPtr   <= '{flag: 1'b0, value: 6'd0};
      for (int i = 0; i < N_FWD; i++) addrRealValid_q[i] <= '0;
    end
    else begin
      // ======================= per-entry 状态 =======================
      // 每一族的优先级都在注释里写明（★最高在前★）。这些优先级是 Chisel
      // 「后写者胜」的直接结果，不是可以随手调换的风格问题。
      for (int j = 0; j < SQ_SIZE; j++) begin
        // allocated：冲刷 > 入队 > 退队清零
        if      (needCancel[j])   allocated[j] <= 1'b0;
        else if (entryCanEnq[j])  allocated[j] <= 1'b1;
        else if (deqClear[j])     allocated[j] <= 1'b0;

        // completed：冲刷 > Sbuffer 回执 > 提交时 nc&异常 > cboZero > mmio > NC > 入队 > 退队
        if      (needCancel[j])         completed[j] <= 1'b0;
        else if (sbufferCompleteSet[j]) completed[j] <= 1'b1;
        else if (commitNcExcDone[j])    completed[j] <= 1'b1;
        else if (cboZeroCompleteSet[j]) completed[j] <= 1'b1;
        else if (mmioCompleteSet[j])    completed[j] <= 1'b1;
        else if (ncCompleteSet[j])      completed[j] <= 1'b1;
        else if (entryCanEnq[j])        completed[j] <= 1'b0;
        else if (deqClear[j])           completed[j] <= 1'b0;

        // addrvalid：口1-s2 > 口1-s1 > 口0-s2 > 口0-s1 > 入队
        // ★不是「s2 一律压 s1」★——两条流水是展开的，口1 的 s1 压过口0 的 s2。
        if (storeAddrInFireReg[1] && stWbIndexReg[1] == 6'(j))
          addrvalid[j] <= addrvalid[j] | storeAddrInRe_in[1].hasException;
        else if (staFire[1] && storeAddrIn_in[1].bits_updateAddrValid
                 && ~storeAddrIn_in[1].bits_miss && stWbIndex[1] == 6'(j))
          addrvalid[j] <= 1'b1;
        else if (storeAddrInFireReg[0] && stWbIndexReg[0] == 6'(j))
          addrvalid[j] <= addrvalid[j] | storeAddrInRe_in[0].hasException;
        else if (staFire[0] && storeAddrIn_in[0].bits_updateAddrValid
                 && ~storeAddrIn_in[0].bits_miss && stWbIndex[0] == 6'(j))
          addrvalid[j] <= 1'b1;
        else if (entryCanEnq[j])
          addrvalid[j] <= 1'b0;

        // datavalid：std 口1-s1 > 口0-s1 > 入队（s1 还要求该条目当拍仍然 allocated）
        if (storeDataInFireReg[1] && allocated[lastStWbIndex[1]] && lastStWbIndex[1] == 6'(j))
          datavalid[j] <= 1'b1;
        else if (storeDataInFireReg[0] && allocated[lastStWbIndex[0]] && lastStWbIndex[0] == 6'(j))
          datavalid[j] <= 1'b1;
        else if (entryCanEnq[j])
          datavalid[j] <= 1'b0;

        // committed：提交 > 入队。★冲刷不清 committed★（提交了就不可撤销）
        if      (commitWrEn[j])  committed[j] <= commitWrVal[j];
        else if (entryCanEnq[j]) committed[j] <= 1'b0;

        // unaligned / cross16Byte / nc：sta 口1 > 口0 > 入队
        // （unaligned/cross16Byte 的写条件不含 updateAddrValid，nc 的含 —— 别串了）
        if (staFire[1] && ~storeAddrIn_in[1].bits_isFrmMisAlignBuf && stWbIndex[1] == 6'(j)) begin
          unaligned[j]   <= storeAddrIn_in[1].bits_isMisalign;
          cross16Byte[j] <= storeAddrIn_in[1].bits_isMisalign
                          & ~storeAddrIn_in[1].bits_misalignWith16Byte;
        end
        else if (staFire[0] && ~storeAddrIn_in[0].bits_isFrmMisAlignBuf && stWbIndex[0] == 6'(j)) begin
          unaligned[j]   <= storeAddrIn_in[0].bits_isMisalign;
          cross16Byte[j] <= storeAddrIn_in[0].bits_isMisalign
                          & ~storeAddrIn_in[0].bits_misalignWith16Byte;
        end
        else if (entryCanEnq[j]) begin
          unaligned[j]   <= 1'b0;
          cross16Byte[j] <= 1'b0;
        end

        if (staFire[1] && storeAddrIn_in[1].bits_updateAddrValid
            && ~storeAddrIn_in[1].bits_miss && stWbIndex[1] == 6'(j))
          nc[j] <= storeAddrIn_in[1].bits_nc;
        else if (staFire[0] && storeAddrIn_in[0].bits_updateAddrValid
                 && ~storeAddrIn_in[0].bits_miss && stWbIndex[0] == 6'(j))
          nc[j] <= storeAddrIn_in[0].bits_nc;
        else if (entryCanEnq[j])
          nc[j] <= 1'b0;

        // mmio / hasException / waitStoreS2：sta-s2 口1 > 口0 > 入队
        if (storeAddrInFireReg[1] && stWbIndexReg[1] == 6'(j)) begin
          mmio[j]         <= storeAddrInRe_in[1].mmio;
          hasException[j] <= storeAddrInRe_in[1].hasException;
          waitStoreS2[j]  <= 1'b0;
        end
        else if (storeAddrInFireReg[0] && stWbIndexReg[0] == 6'(j)) begin
          mmio[j]         <= storeAddrInRe_in[0].mmio;
          hasException[j] <= storeAddrInRe_in[0].hasException;
          waitStoreS2[j]  <= 1'b0;
        end
        else if (entryCanEnq[j]) begin
          mmio[j]         <= 1'b0;
          hasException[j] <= 1'b0;
          waitStoreS2[j]  <= 1'b1;        // ★入队置 1，不是清 0★
        end

        // ===================== ★TRAP-2：memBackTypeMM 不清 ★ =====================
        // 只有两个 sta-s2 分支写它，**没有入队清零那一支**（同组的 mmio 与
        // hasException 都有）。也就是说它会保留上一个占用者的值，直到某次 sta-s2
        // 覆盖。顺手抹平成「入队一起清」是真 bug，UT 极难打到。
        // ========================================================================
        if (storeAddrInFireReg[1] && stWbIndexReg[1] == 6'(j))
          memBackTypeMM[j] <= storeAddrInRe_in[1].memBackTypeMM;
        else if (storeAddrInFireReg[0] && stWbIndexReg[0] == 6'(j))
          memBackTypeMM[j] <= storeAddrInRe_in[0].memBackTypeMM;

        // pending：mmio 发出请求时清 > sta-s2 口1 > 口0 > 入队
        if      (mmioDoReq && deqPtr == 6'(j))
          pending[j] <= 1'b0;
        else if (storeAddrInFireReg[1] && stWbIndexReg[1] == 6'(j))
          pending[j] <= storeAddrInRe_in[1].mmio;
        else if (storeAddrInFireReg[0] && stWbIndexReg[0] == 6'(j))
          pending[j] <= storeAddrInRe_in[0].mmio;
        else if (entryCanEnq[j])
          pending[j] <= 1'b0;

        // isVec / vecLastFlow：只在入队时写
        if (entryCanEnq[j]) begin
          // FuType.isVStore：fuType 的第 32/34 位
          isVec[j] <= enq_req_in[enqSelPort[j]].bits_fuType[32]
                    | enq_req_in[enqSelPort[j]].bits_fuType[34];
          // 「这条目正好是该向量 uop 区间的最后一条」才带 lastUop。
          // 区间上界绕回 0 时，最后一条是条目 55 —— 所以比的是 (j+1) mod 56。
          vecLastFlow[j] <= (enqUpBound[enqSelPort[j]].value == 6'((j + 1) % SQ_SIZE))
                          ? enq_req_in[enqSelPort[j]].bits_lastUop : 1'b0;
        end

        // vecMbCommit：跨页同指针 > 向量反馈 > 入队清零
        if      (io_maControl_toStoreQueue_withSamePtr && rdataPtrExt[0].value == 6'(j))
          vecMbCommit[j] <= 1'b1;
        else if (vecCommit[j])
          vecMbCommit[j] <= 1'b1;
        else if (entryCanEnq[j])
          vecMbCommit[j] <= 1'b0;
      end

      // ======================= 两条就绪向量（GatedValidRegNext）=======================
      // 使能 =「整条 56 位次态 != 现值」。与无条件 RegNext 功能等价，
      // 但 golden 是这个形状，照抄。
      if (stAddrReadyVec_q != stAddrReadyVecReg) stAddrReadyVec_q <= stAddrReadyVecReg;
      if (stDataReadyVec_q != stDataReadyVecReg) stDataReadyVec_q <= stDataReadyVecReg;

      // ======================= 指针 =======================
      // enqPtr：冲刷后**第 2 拍**才回退（为了时序），平时按本拍入队数前进。
      if (lastlastCycleRedirect) enqPtrExt <= sqptr_sub(enqPtrExt, redirectCancelCount);
      else                       enqPtrExt <= sqptr_add(enqPtrExt, enqNumber);

      for (int i = 0; i < N_ENSBUF; i++) begin
        deqPtrExt[i]   <= deqPtrExtNext[i];
        rdataPtrExt[i] <= rdataPtrExtNext[i];
      end

      // cmtPtr 的 8 份一起加 commitCount；★只有第 0 份有 flag★（其余被 DCE）。
      cmtPtrFlag <= sqptr_add('{flag: cmtPtrFlag, value: cmtPtrValue[0]},
                              {4'h0, commitCount}).flag;
      for (int i = 0; i < N_COMMIT; i++)
        cmtPtrValue[i] <= sqptr_add('{flag: 1'b0, value: cmtPtrValue[i]},
                                    {4'h0, commitCount}).value;

      // 两个 issue 指针：冲刷 > （dataReady 侧还有）非对齐随组跳过 > 正常推进
      if (io_brqRedirect_valid) addrReadyPtrExt <= redirectIssuePtr;
      else                      addrReadyPtrExt <= nextAddrReadyPtr;

      if (io_brqRedirect_valid)      dataReadyPtrExt <= redirectIssuePtr;
      else if (unalignedCanMove)     dataReadyPtrExt <= sqptr_add(dataReadyPtrExt,
                                                                  {6'h0, unalignedMoveStep});
      else                           dataReadyPtrExt <= nextDataReadyPtr;

      // 冲刷计数：T0 重定向 -> T1 数 needCancel -> T2 才减 enqPtr
      if (lastCycleRedirect)
        redirectCancelCount <= 8'($countones(lastCycleCancelVec)) + lastEnqCancel;

      // ======================= mmio 5 态 FSM =======================
      unique case (mmioState)
        S_IDLE: begin
          // 走到 ROB 头、数据地址都齐、没异常，才把它交给 uncache 通道。
          if (mmioEnterReqReg) begin
            mmioState    <= S_REQ;
            cboFlushedSb <= 1'b0;
            cboZeroOffset<= 3'd0;
          end
        end
        S_REQ: begin
          if (mmioDoReq) begin
            noPending <= 1'b0;
            mmioState <= S_RESP;
          end
        end
        S_RESP: begin
          if (uncacheRespFireNonNc) begin
            if (~mmioIsCboZero) begin
              noPending <= 1'b1;
              mmioState <= S_WB;
            end
            else begin
              // cbo.zero 要写满一整行：8 拍，每拍回来一次再发下一拍。
              cboZeroOffset <= cboZeroOffset + 3'd1;
              mmioState     <= (&cboZeroOffset) ? S_WB : S_REQ;
            end
            // denied / corrupt 直接结束，异常位在 §20 的不复位块里置起。
            if (respDenied)  mmioState <= S_WB;
            if (respCorrupt) mmioState <= S_WB;
          end
        end
        S_WB: begin
          if (mmioStoutFire)
            mmioState <= (uncacheUop_excStoreAccessFault | uncacheUop_excHardwareError)
                       ? S_IDLE : S_WAIT;
        end
        S_WAIT: begin
          // mmio store 必然在 ROB 头，scommit 一来就说明它提交了。
          if (|scommit) mmioState <= S_IDLE;
        end
        default: mmioState <= S_IDLE;
      endcase

      // ★CBO 越权覆盖上面的 FSM 迁移★：走的是 cmoOpReq/cmoOpResp 专用口，
      // 不经 uncache 通道，所以迁移条件整个换掉。
      if (deqCanDoCbo) begin
        if (cmoOpReqFire) begin
          noPending <= 1'b0;
          mmioState <= S_RESP;
        end
        if ((mmioState == S_RESP) && cmoOpRespFire) begin
          noPending <= 1'b1;
          mmioState <= S_WB;
        end
      end

      // CBO 发请求前先把 Sbuffer 冲干净（这一条压过 s_idle 里的清零）
      if (deqCanDoCbo && ~cboFlushedSb && (mmioState == S_REQ) && io_flushSbuffer_empty)
        cboFlushedSb <= 1'b1;

      // ======================= NC 4 态 FSM =======================
      unique case (ncState)
        NC_IDLE: begin
          // NC 要等提交；而且必须等 resp 回来才退队（SQ 还得给 load 做转发）。
          if (nc[rdPtr] & allocated[rdPtr] & ~completed[rdPtr] & committed[rdPtr]
              & allvalid[rdPtr] & ~isVec[rdPtr] & ~hasException[rdPtr] & ~mmio[rdPtr]
              // !isCboAll：CBO 全家（含 cbo.zero）不走 NC 通道
              & ~((&uop_fuOpType[rdPtr][3:2] & ~(|uop_fuOpType[rdPtr][6:4]))
                  | (uop_fuOpType[rdPtr][3:0] == 4'h7))) begin
            ncState          <= NC_REQ;
            ncWaitRespPtrReg <= {1'b0, rdPtr};
          end
        end
        NC_REQ:     if (ncDoReq)    ncState <= NC_REQ_ACK;
        NC_REQ_ACK: if (ncSlaveAck) ncState <= io_uncacheOutstanding ? NC_IDLE : NC_RESP;
        NC_RESP:    if (ncRespFire) ncState <= NC_IDLE;
        default:                    ncState <= NC_IDLE;
      endcase

      // ======================= cbo.zero 的回写握手 =======================
      if (cboZeroToSb) begin
        cboZeroValid       <= 1'b1;
        cboZeroWaitFlushSb <= 1'b1;
      end
      if (cboZeroWaitFlushSb && io_flushSbuffer_empty) cboZeroWaitFlushSb <= 1'b0;
      if (cboZeroStoutFire)                            cboZeroValid       <= 1'b0;

      // ======================= 向量异常旗标 =======================
      if (~vecExceptionFlag_valid && (|vecCommitHasExceptionValid) && ~vecCommitLastFlow) begin
        vecExceptionFlag_valid        <= 1'b1;
        vecExceptionFlag_robIdx_flag  <= uop_robIdx_flag [vecCommitSelEntry];
        vecExceptionFlag_robIdx_value <= uop_robIdx_value[vecCommitSelEntry];
      end
      else if (vecExceptionFlag_valid && vecExceptionFlagCancel) begin
        vecExceptionFlag_valid        <= 1'b0;
        vecExceptionFlag_robIdx_flag  <= 1'b0;
        vecExceptionFlag_robIdx_value <= 8'd0;
      end

      // TimeOutAssert 的计数器：旗标立着就数，倒了就清。本仓按 SYNTHESIS 编译，
      // 断言不生成 —— 但 golden 留着这个寄存器，少写一个 FM 就多一个 unmatched。
      if (vecExceptionFlag_valid) timeoutCounter <= timeoutCounter + 32'd1;
      else                        timeoutCounter <= 32'd0;

      // ======================= 其余 GatedRegNext / RegNext =======================
      if (scommit != io_rob_scommit) scommit <= io_rob_scommit;
      for (int i = 0; i < N_COMMIT; i++)
        if ({pendingPtrReg_flag[i], pendingPtrReg_value[i]}
            != {io_rob_pendingPtr_flag, io_rob_pendingPtr_value}) begin
          pendingPtrReg_flag[i]  <= io_rob_pendingPtr_flag;
          pendingPtrReg_value[i] <= io_rob_pendingPtr_value;
        end
      if (mmioReqRobIdxPtr  != rdataPtrExtNext[0]) mmioReqRobIdxPtr  <= rdataPtrExtNext[0];
      if (mmioReqMemBackPtr != rdataPtrExtNext[0]) mmioReqMemBackPtr <= rdataPtrExtNext[0];
      if (ncReqRobIdxPtr    != rdataPtrExtNext[0]) ncReqRobIdxPtr    <= rdataPtrExtNext[0];
      if (ncReqMemBackPtr   != rdataPtrExtNext[0]) ncReqMemBackPtr   <= rdataPtrExtNext[0];

      for (int i = 0; i < N_FWD; i++)
        if (addrRealValid_q[i] != addrValidVec) addrRealValid_q[i] <= addrValidVec;

      if (cboZeroFlushSb != cboZeroToSb) cboZeroFlushSb <= cboZeroToSb;

      // deqCanDoCbo 的寄存器部分（memBackTypeMM 那一项是**当拍**的，不打拍）
      begin
        automatic logic deqCanDoCboNext =
            (&uop_fuOpType[deqPtr][3:2]) & ~(|uop_fuOpType[deqPtr][6:4])   // isCbo
          & allocated[deqPtr] & addrvalid[deqPtr] & ~hasException[deqPtr];
        if (deqCanDoCboReg != deqCanDoCboNext) deqCanDoCboReg <= deqCanDoCboNext;
      end

      begin
        automatic logic wfiSafeNext = noPending & io_wfi_wfiReq;
        if (wfiSafeReg != wfiSafeNext) wfiSafeReg <= wfiSafeNext;
      end

      // force_write：超过上限就置起，掉到下限以下才落下（带迟滞）。
      forceWriteReg <= (valid_cnt > 6'(FORCE_WR_SET_GT))
                     | ((valid_cnt > 6'(FORCE_WR_HOLD_GT)) & forceWriteReg);
    end
  end


endmodule


// -----------------------------------------------------------------------------
// §10 StoreQueue_xs —— golden 同名 wrapper（1003 根端口，逐位对齐）
// -----------------------------------------------------------------------------
module StoreQueue_xs(
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
