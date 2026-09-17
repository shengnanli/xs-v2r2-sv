// =============================================================================
// LsqEnqCtrl —— LoadQueue / StoreQueue 的入队控制（Dispatch 与 LSQ 之间的一级）
//
// 对应 Chisel: xiangshan.mem.LsqEnqCtrl
// 位置：Backend / NewDispatch 里。Dispatch 每拍最多送 6 条访存 uop，本模块负责
//   (1) 用两个自由计数器判断 LQ/SQ 还容不容得下这一拍（io_enq_canAccept）；
//   (2) 给每条 uop 算出它将占用的 lqIdx / sqIdx（CircularQueuePtr：flag + value）；
//   (3) 把 uop 连同算好的 idx **打一拍**转发给 LSQ（io_enqLsq_*）。
//
// 规模（★全部从 golden 常数读出，不是从 Chisel 默认推★）：
//   LQ 深度 72（golden 里的 9'h48）、value 7 位；SQ 深度 56（8'h38）、value 6 位。
//   入队宽度 6；每条 uop 的 exceptionVec 24 位。
//
// 时序骨架（三拍 redirect 握手 + 一拍载荷流水）：
//   t1_redirect/t2_redirect ：redirect 打两拍；
//   t2_update ：redirect 到了第二拍、且这一拍 Dispatch 没有任何 needAlloc —— 意思是
//               "冲刷已经走空，可以用 lqCancelCnt/sqCancelCnt 回卷指针了"；
//   t3_update ：t2_update 再打一拍，真正执行回卷（指针往回退 cancelCnt，计数器加回）。
//   canAccept 也是寄存器输出（比较是在上一拍做的），所以入队判据用的是上一拍的余量。
//
// ★复位域（照抄 golden，别整齐划一）★
//   异步复位(posedge reset)只有 8 个：lqPtr.flag/value、sqPtr.flag/value、
//   lqCounter(=72)、sqCounter(=56)、t3_lqCancelCnt_next_r、t3_sqCancelCnt_next_r。
//   其余 334 个寄存器**一个都不复位**：t1/t2/t3_update、canAccept_REG、needAlloc
//   的 6 个打拍寄存器，以及 6×54 个载荷寄存器。照抄成全复位是真 bug，
//   elaborate 与 lint 都不会报。
//
// ★一个"看着冗余、其实必须照抄"的结构★
//   每条 uop 的 8 个 debugInfo 时间戳（dispatchTime/enqRsTime/…）与 eliminatedMove
//   在 golden 里是**真寄存器**：入队拍写常数 0，其余拍保持。它们的输出恒等于 0 只
//   是"跑够久以后"的现象，不是组合常数 —— 直接把输出接 0 会让 golden 侧 54 个
//   compare point 无对象可配。这里原样保留为寄存器（见 lsq_enq_out_t 的注释）。
// =============================================================================
// 本文件导航（共 1513 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L211   CircularQueuePtr 前进：value + n，够到队列深度就绕一圈
//   L233   每条 uop 要占几个 LQ / SQ 表项
//   L281   每条 uop 的 lqIdx / sqIdx = 当前指针 + 它前面那些的占用数
//   L295   redirect 回卷握手
//   L325   指针 / 计数器：唯一带异步复位的一组
//   L366   无复位的一拍流水：控制骨架 + 载荷
//

package lsqenqctrl_pkg;

  localparam int unsigned N_ENQ   = 6;   // Dispatch 每拍最多送几条访存 uop
  localparam int unsigned N_EXC   = 24;  // exceptionVec 位宽
  localparam int unsigned LQ_SIZE = 72;  // VirtualLoadQueueSize（golden 9'h48）
  localparam int unsigned SQ_SIZE = 56;  // StoreQueueSize（golden 8'h38）
  localparam int unsigned LQ_VW   = 7;   // lqIdx.value 位宽
  localparam int unsigned SQ_VW   = 6;   // sqIdx.value 位宽

  // fuType 里标识"这条 uop 要占 LQ / 占 SQ"的位。golden 用的就是这四个位号：
  //   15 = ldu, 31 = vldu（向量 load）；16 = stu, 32 = vstu（向量 store）。
  localparam int unsigned FU_LOAD_BIT   = 15;
  localparam int unsigned FU_VLOAD_BIT  = 31;
  localparam int unsigned FU_STORE_BIT  = 16;
  localparam int unsigned FU_VSTORE_BIT = 32;

  // 入队水位余量：golden 的 canAccept 判据是 lqCounter >= alloc+6 且
  // sqCounter >= alloc+4（6/4 = 两个队列各自的保留余量）。
  localparam int unsigned LQ_RESERVE = 6;
  localparam int unsigned SQ_RESERVE = 4;

  typedef struct packed {
    logic               flag;               // 绕圈标志
    logic [LQ_VW-1:0]   value;
  } lq_ptr_t;

  typedef struct packed {
    logic               flag;
    logic [SQ_VW-1:0]   value;
  } sq_ptr_t;

  // 从 Dispatch 直通到 LSQ 的 uop 字段（本模块只搬运，不解释内容）
  typedef struct packed {
    logic [N_EXC-1:0] exceptionVec;
    logic [3:0]       trigger;
    logic [34:0]      fuType;
    logic [8:0]       fuOpType;
    logic             rfWen;
    logic             flushPipe;
    logic [2:0]       vpu_nf;
    logic [1:0]       vpu_veew;
    logic [6:0]       uopIdx;
    logic             lastUop;
    logic [7:0]       pdest;
    logic             robIdx_flag;
    logic [7:0]       robIdx_value;
    logic [63:0]      debugInfo_renameTime;
    logic [55:0]      debug_seqNum_seqNum;
    logic [7:0]       debug_seqNum_uopIdx;
    logic [4:0]       numLsElem;
  } lsq_uop_t;

  // 打一拍送给 LSQ 的整包。除直通字段外还带三组：
  //   - 本模块算出来的 lqIdx / sqIdx；
  //   - 入队拍写 0 的 8 个时间戳 + eliminatedMove（见文件头说明，必须是真寄存器）。
  typedef struct packed {
    lsq_uop_t    uop;
    logic        debugInfo_eliminatedMove;
    logic [63:0] debugInfo_dispatchTime;
    logic [63:0] debugInfo_enqRsTime;
    logic [63:0] debugInfo_selectTime;
    logic [63:0] debugInfo_issueTime;
    logic [63:0] debugInfo_writebackTime;
    logic [63:0] debugInfo_runahead_checkpoint_id;
    logic [63:0] debugInfo_tlbFirstReqTime;
    logic [63:0] debugInfo_tlbRespTime;
    lq_ptr_t     lqIdx;
    sq_ptr_t     sqIdx;
  } lsq_enq_out_t;

endpackage


module xs_LsqEnqCtrl_core
  import lsqenqctrl_pkg::*;
(
  input  logic clock,
  input  logic reset,                                  // 异步复位（只作用于 8 个指针/计数器）

  input  logic                            io_redirect_valid,

  // ---- Dispatch 侧 ----
  output logic                            io_enq_canAccept,
  input  logic [N_ENQ-1:0][1:0]           io_enq_needAlloc,   // [0]=要 LQ, [1]=要 SQ
  input  logic [N_ENQ-1:0]                io_enq_iqAccept,    // 发射队列也收下了这条
  input  logic [N_ENQ-1:0]                io_enq_req_valid,
  input  logic [N_ENQ-1:0][N_EXC-1:0]     io_enq_req_exceptionVec,
  input  logic [N_ENQ-1:0][3:0]           io_enq_req_trigger,
  input  logic [N_ENQ-1:0][34:0]          io_enq_req_fuType,
  input  logic [N_ENQ-1:0][8:0]           io_enq_req_fuOpType,
  input  logic [N_ENQ-1:0]                io_enq_req_rfWen,
  input  logic [N_ENQ-1:0]                io_enq_req_flushPipe,
  input  logic [N_ENQ-1:0][2:0]           io_enq_req_vpu_nf,
  input  logic [N_ENQ-1:0][1:0]           io_enq_req_vpu_veew,
  input  logic [N_ENQ-1:0][6:0]           io_enq_req_uopIdx,
  input  logic [N_ENQ-1:0]                io_enq_req_lastUop,
  input  logic [N_ENQ-1:0][7:0]           io_enq_req_pdest,
  input  logic [N_ENQ-1:0]                io_enq_req_robIdx_flag,
  input  logic [N_ENQ-1:0][7:0]           io_enq_req_robIdx_value,
  input  logic [N_ENQ-1:0][63:0]          io_enq_req_debugInfo_renameTime,
  input  logic [N_ENQ-1:0][55:0]          io_enq_req_debug_seqNum_seqNum,
  input  logic [N_ENQ-1:0][7:0]           io_enq_req_debug_seqNum_uopIdx,
  input  logic [N_ENQ-1:0][4:0]           io_enq_req_numLsElem,
  output logic [N_ENQ-1:0]                io_enq_resp_lqIdx_flag,
  output logic [N_ENQ-1:0][LQ_VW-1:0]     io_enq_resp_lqIdx_value,
  output logic [N_ENQ-1:0]                io_enq_resp_sqIdx_flag,
  output logic [N_ENQ-1:0][SQ_VW-1:0]     io_enq_resp_sqIdx_value,

  // ---- LSQ 侧回报：提交了几条 / 冲刷掉了几条 ----
  input  logic [3:0]                      io_lcommit,
  input  logic [1:0]                      io_scommit,
  input  logic [LQ_VW-1:0]                io_lqCancelCnt,
  input  logic [SQ_VW-1:0]                io_sqCancelCnt,
  output logic [LQ_VW-1:0]                io_lqFreeCount,
  output logic [SQ_VW-1:0]                io_sqFreeCount,

  // ---- 转发给 LSQ（全部打一拍）----
  output logic [N_ENQ-1:0][1:0]           io_enqLsq_needAlloc,
  output logic [N_ENQ-1:0]                io_enqLsq_req_valid,
  output logic [N_ENQ-1:0][N_EXC-1:0]     io_enqLsq_req_exceptionVec,
  output logic [N_ENQ-1:0][3:0]           io_enqLsq_req_trigger,
  output logic [N_ENQ-1:0][34:0]          io_enqLsq_req_fuType,
  output logic [N_ENQ-1:0][8:0]           io_enqLsq_req_fuOpType,
  output logic [N_ENQ-1:0]                io_enqLsq_req_rfWen,
  output logic [N_ENQ-1:0]                io_enqLsq_req_flushPipe,
  output logic [N_ENQ-1:0][2:0]           io_enqLsq_req_vpu_nf,
  output logic [N_ENQ-1:0][1:0]           io_enqLsq_req_vpu_veew,
  output logic [N_ENQ-1:0][6:0]           io_enqLsq_req_uopIdx,
  output logic [N_ENQ-1:0]                io_enqLsq_req_lastUop,
  output logic [N_ENQ-1:0][7:0]           io_enqLsq_req_pdest,
  output logic [N_ENQ-1:0]                io_enqLsq_req_robIdx_flag,
  output logic [N_ENQ-1:0][7:0]           io_enqLsq_req_robIdx_value,
  output logic [N_ENQ-1:0][63:0]          io_enqLsq_req_debugInfo_renameTime,
  output logic [N_ENQ-1:0][55:0]          io_enqLsq_req_debug_seqNum_seqNum,
  output logic [N_ENQ-1:0][7:0]           io_enqLsq_req_debug_seqNum_uopIdx,
  output logic [N_ENQ-1:0][4:0]           io_enqLsq_req_numLsElem,
  output logic [N_ENQ-1:0]                io_enqLsq_req_debugInfo_eliminatedMove,
  output logic [N_ENQ-1:0][63:0]          io_enqLsq_req_debugInfo_dispatchTime,
  output logic [N_ENQ-1:0][63:0]          io_enqLsq_req_debugInfo_enqRsTime,
  output logic [N_ENQ-1:0][63:0]          io_enqLsq_req_debugInfo_selectTime,
  output logic [N_ENQ-1:0][63:0]          io_enqLsq_req_debugInfo_issueTime,
  output logic [N_ENQ-1:0][63:0]          io_enqLsq_req_debugInfo_writebackTime,
  output logic [N_ENQ-1:0][63:0]          io_enqLsq_req_debugInfo_runahead_checkpoint_id,
  output logic [N_ENQ-1:0][63:0]          io_enqLsq_req_debugInfo_tlbFirstReqTime,
  output logic [N_ENQ-1:0][63:0]          io_enqLsq_req_debugInfo_tlbRespTime,
  output logic [N_ENQ-1:0]                io_enqLsq_req_lqIdx_flag,
  output logic [N_ENQ-1:0][LQ_VW-1:0]     io_enqLsq_req_lqIdx_value,
  output logic [N_ENQ-1:0]                io_enqLsq_req_sqIdx_flag,
  output logic [N_ENQ-1:0][SQ_VW-1:0]     io_enqLsq_req_sqIdx_value
);

  // ---------------------------------------------------------------------------
  // 状态
  // ---------------------------------------------------------------------------
  lq_ptr_t              lqPtr;          // 下一条 load 将占的位置
  sq_ptr_t              sqPtr;
  logic [LQ_VW-1:0]     lqCounter;      // LQ 剩余空位（复位 = LQ_SIZE）
  logic [SQ_VW-1:0]     sqCounter;
  logic [LQ_VW-1:0]     lqCancelCntReg; // golden: t3_lqCancelCnt_next_r
  logic [SQ_VW-1:0]     sqCancelCntReg;

  logic                 t1_redirect, t2_redirect, t3_update;   // 无复位
  logic                 canAcceptReg;                          // 无复位
  logic [N_ENQ-1:0][1:0] needAllocReg;                         // 无复位
  lsq_enq_out_t         outReg [N_ENQ];                        // 无复位
  logic [N_ENQ-1:0]     outValidReg;                           // 无复位

  // ---------------------------------------------------------------------------
  // CircularQueuePtr 前进：value + n，够到队列深度就绕一圈（flag 翻转）。
  // 返回 {绕了吗, 新 value}。★golden 只做一次回绕，不是取模★——n 大到跨两圈时
  // golden 自己也会错；照抄，别"顺手修好"。
  // ---------------------------------------------------------------------------
  function automatic logic [LQ_VW:0] lqAdvance(input logic [LQ_VW-1:0] value,
                                               input logic [8:0]       addend);
    logic [8:0] sum;
    sum = {2'b0, value} + addend;              // 9 位够用：71 + 255 = 326 < 512
    // golden 写成 $signed(sum - LQ_SIZE) > -1，与 sum >= LQ_SIZE 同义
    return (sum >= 9'(LQ_SIZE)) ? {1'b1, LQ_VW'(sum - 9'(LQ_SIZE))}
                                : {1'b0, LQ_VW'(sum)};
  endfunction

  function automatic logic [SQ_VW:0] sqAdvance(input logic [SQ_VW-1:0] value,
                                               input logic [8:0]       addend);
    logic [8:0] sum;
    sum = {3'b0, value} + addend;
    return (sum >= 9'(SQ_SIZE)) ? {1'b1, SQ_VW'(sum - 9'(SQ_SIZE))}
                                : {1'b0, SQ_VW'(sum)};
  endfunction

  // ---------------------------------------------------------------------------
  // 每条 uop 要占几个 LQ / SQ 表项
  //   标量访存占 1，向量访存占 numLsElem（一条向量指令拆成若干个 flow）。
  //   golden 直接用 numLsElem —— 标量路径上层保证它是 1，这里不额外判。
  // ---------------------------------------------------------------------------
  logic [N_ENQ-1:0][4:0] loadElem, storeElem;

  always_comb
    for (int i = 0; i < int'(N_ENQ); i++) begin
      loadElem[i]  = (io_enq_req_valid[i] &
                      (io_enq_req_fuType[i][FU_LOAD_BIT] |
                       io_enq_req_fuType[i][FU_VLOAD_BIT]))  ? io_enq_req_numLsElem[i] : 5'h0;
      storeElem[i] = (io_enq_req_valid[i] &
                      (io_enq_req_fuType[i][FU_STORE_BIT] |
                       io_enq_req_fuType[i][FU_VSTORE_BIT])) ? io_enq_req_numLsElem[i] : 5'h0;
    end

  // 前缀和 prefix[k] = 前 k 条一共要几个表项。★位宽照 golden 截断★：
  // 送进 lqIdx 计算的那一路 golden 截到 7 位（LQ）/ 6 位（SQ），
  // 送进 allocNumber 的那一路保留 8 位。k<=3 时两者其实一样宽，只有 k=4/5 看得出。
  logic [N_ENQ:0][7:0] loadPrefix, storePrefix;

  always_comb begin
    loadPrefix[0]  = 8'h0;
    storePrefix[0] = 8'h0;
    for (int i = 0; i < int'(N_ENQ); i++) begin
      loadPrefix[i+1]  = loadPrefix[i]  + {3'h0, loadElem[i]};
      storePrefix[i+1] = storePrefix[i] + {3'h0, storeElem[i]};
    end
  end

  // 本拍真正要占用的总数：iqAccept 是**前缀式**的 —— 第一个没被发射队列收下的口
  // 之后全都不算（Dispatch 是顺序的，前面卡住后面就进不去）。
  logic [7:0] lqAllocNumber, sqAllocNumber;

  always_comb begin
    automatic logic allAccepted = 1'b1;   // 前 i 个口是否都被收下
    lqAllocNumber = 8'h0;
    sqAllocNumber = 8'h0;
    for (int i = 0; i < int'(N_ENQ); i++) begin
      allAccepted &= io_enq_iqAccept[i];
      if (allAccepted) begin
        lqAllocNumber = loadPrefix[i+1];
        sqAllocNumber = storePrefix[i+1];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 每条 uop 的 lqIdx / sqIdx = 当前指针 + 它前面那些的占用数
  // ---------------------------------------------------------------------------
  lq_ptr_t [N_ENQ-1:0] respLqIdx;
  sq_ptr_t [N_ENQ-1:0] respSqIdx;

  always_comb
    for (int i = 0; i < int'(N_ENQ); i++) begin
      automatic logic [LQ_VW:0] l = lqAdvance(lqPtr.value, {2'h0, loadPrefix[i][LQ_VW-1:0]});
      automatic logic [SQ_VW:0] s = sqAdvance(sqPtr.value, {3'h0, storePrefix[i][SQ_VW-1:0]});
      respLqIdx[i] = '{flag: l[LQ_VW] ^ lqPtr.flag, value: l[LQ_VW-1:0]};
      respSqIdx[i] = '{flag: s[SQ_VW] ^ sqPtr.flag, value: s[SQ_VW-1:0]};
    end

  // ---------------------------------------------------------------------------
  // redirect 回卷握手
  //   t2_update：redirect 已经打了两拍，且这一拍 Dispatch 一条 needAlloc 都没有 ——
  //   说明冲刷的那批已经走干净，可以按 lqCancelCnt/sqCancelCnt 把指针退回去。
  // ---------------------------------------------------------------------------
  logic anyNeedAlloc, t2_update;

  always_comb begin
    anyNeedAlloc = 1'b0;
    for (int i = 0; i < int'(N_ENQ); i++) anyNeedAlloc |= |io_enq_needAlloc[i];
  end
  assign t2_update = t2_redirect & ~anyNeedAlloc;

  // 指针后退 cancelCnt：用"加上 (SIZE - cancelCnt)"实现，于是必然多绕一圈，
  // 所以新 flag 要和**取反后的**旧 flag 再异或（golden: reverse ^ ~lqPtr_flag）。
  logic [LQ_VW:0] lqRewind;
  logic [SQ_VW:0] sqRewind;
  assign lqRewind = lqAdvance(lqPtr.value, {2'h0, LQ_VW'(LQ_VW'(LQ_SIZE) - lqCancelCntReg)});
  assign sqRewind = sqAdvance(sqPtr.value, {3'h0, SQ_VW'(SQ_VW'(SQ_SIZE) - sqCancelCntReg)});

  // 正常前进
  logic [LQ_VW:0] lqNext;
  logic [SQ_VW:0] sqNext;
  assign lqNext = lqAdvance(lqPtr.value, {1'b0, lqAllocNumber});
  assign sqNext = sqAdvance(sqPtr.value, {1'b0, sqAllocNumber});

  // 本拍真的接收入队（redirect 优先，且要上一拍算出的 canAccept）
  logic acceptThisCycle;
  assign acceptThisCycle = ~io_redirect_valid & canAcceptReg;

  // ---------------------------------------------------------------------------
  // 指针 / 计数器：唯一带异步复位的一组
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      lqPtr          <= '{flag: 1'b0, value: '0};
      sqPtr          <= '{flag: 1'b0, value: '0};
      lqCounter      <= LQ_VW'(LQ_SIZE);
      sqCounter      <= SQ_VW'(SQ_SIZE);
      lqCancelCntReg <= '0;
      sqCancelCntReg <= '0;
    end
    else begin
      if (t3_update) begin
        // 回卷：指针退回 cancelCnt，空位加回（cancelCnt + 本拍提交数）
        lqPtr     <= '{flag: lqRewind[LQ_VW] ^ ~lqPtr.flag, value: lqRewind[LQ_VW-1:0]};
        sqPtr     <= '{flag: sqRewind[SQ_VW] ^ ~sqPtr.flag, value: sqRewind[SQ_VW-1:0]};
        lqCounter <= lqCounter + {3'h0, io_lcommit} + lqCancelCntReg;
        sqCounter <= sqCounter + {4'h0, io_scommit} + sqCancelCntReg;
      end
      else begin
        // flag 每拍都写（没接收时异或 0 = 保持），value/占用只在接收拍动
        lqPtr.flag <= (acceptThisCycle & lqNext[LQ_VW]) ^ lqPtr.flag;
        sqPtr.flag <= (acceptThisCycle & sqNext[SQ_VW]) ^ sqPtr.flag;
        if (acceptThisCycle) begin
          lqPtr.value <= lqNext[LQ_VW-1:0];
          sqPtr.value <= sqNext[SQ_VW-1:0];
          lqCounter   <= lqCounter + {3'h0, io_lcommit} - lqAllocNumber[LQ_VW-1:0];
          sqCounter   <= sqCounter + {4'h0, io_scommit} - sqAllocNumber[SQ_VW-1:0];
        end
        else begin
          lqCounter <= lqCounter + {3'h0, io_lcommit};
          sqCounter <= sqCounter + {4'h0, io_scommit};
        end
      end
      // golden 写成 `if (in != reg) reg <= in`，与无条件打拍等价（使能就是 in!=reg）
      lqCancelCntReg <= io_lqCancelCnt;
      sqCancelCntReg <= io_sqCancelCnt;
    end
  end

  // ---------------------------------------------------------------------------
  // 无复位的一拍流水：控制骨架 + 载荷
  // ---------------------------------------------------------------------------
  logic [N_ENQ-1:0] doEnq;
  always_comb
    for (int i = 0; i < int'(N_ENQ); i++)
      doEnq[i] = io_enq_req_valid[i] & acceptThisCycle;

  always_ff @(posedge clock) begin
    t1_redirect  <= io_redirect_valid;
    t2_redirect  <= t1_redirect;
    t3_update    <= t2_update;
    // 下一拍能不能收：两个队列的余量都要盖过本拍的占用再加各自的保留量；
    // 正在回卷的那一拍一律不收。
    canAcceptReg <= ({2'h0, lqCounter} >= 9'(lqAllocNumber) + 9'(LQ_RESERVE))
                  & ({3'h0, sqCounter} >= 9'(sqAllocNumber) + 9'(SQ_RESERVE))
                  & ~t2_update;
    needAllocReg <= io_enq_needAlloc;

    for (int i = 0; i < int'(N_ENQ); i++) begin
      outValidReg[i] <= doEnq[i];
      if (doEnq[i])
        outReg[i] <= '{
          uop: '{exceptionVec:         io_enq_req_exceptionVec[i],
                 trigger:              io_enq_req_trigger[i],
                 fuType:               io_enq_req_fuType[i],
                 fuOpType:             io_enq_req_fuOpType[i],
                 rfWen:                io_enq_req_rfWen[i],
                 flushPipe:            io_enq_req_flushPipe[i],
                 vpu_nf:               io_enq_req_vpu_nf[i],
                 vpu_veew:             io_enq_req_vpu_veew[i],
                 uopIdx:               io_enq_req_uopIdx[i],
                 lastUop:              io_enq_req_lastUop[i],
                 pdest:                io_enq_req_pdest[i],
                 robIdx_flag:          io_enq_req_robIdx_flag[i],
                 robIdx_value:         io_enq_req_robIdx_value[i],
                 debugInfo_renameTime: io_enq_req_debugInfo_renameTime[i],
                 debug_seqNum_seqNum:  io_enq_req_debug_seqNum_seqNum[i],
                 debug_seqNum_uopIdx:  io_enq_req_debug_seqNum_uopIdx[i],
                 numLsElem:            io_enq_req_numLsElem[i]},
          // 下面 9 个字段入队拍写常数 0：LsqEnqCtrl 不产生这些时间戳，但 golden
          // 里它们确实是寄存器（见文件头），不能塌成组合常数。
          debugInfo_eliminatedMove:         1'b0,
          debugInfo_dispatchTime:           64'h0,
          debugInfo_enqRsTime:              64'h0,
          debugInfo_selectTime:             64'h0,
          debugInfo_issueTime:              64'h0,
          debugInfo_writebackTime:          64'h0,
          debugInfo_runahead_checkpoint_id: 64'h0,
          debugInfo_tlbFirstReqTime:        64'h0,
          debugInfo_tlbRespTime:            64'h0,
          lqIdx: respLqIdx[i],
          sqIdx: respSqIdx[i]
        };
    end
  end

  // ---------------------------------------------------------------------------
  // 输出
  // ---------------------------------------------------------------------------
  assign io_enq_canAccept = canAcceptReg;
  assign io_lqFreeCount   = lqCounter;
  assign io_sqFreeCount   = sqCounter;
  assign io_enqLsq_needAlloc = needAllocReg;
  assign io_enqLsq_req_valid = outValidReg;

  always_comb
    for (int i = 0; i < int'(N_ENQ); i++) begin
      io_enq_resp_lqIdx_flag[i]   = respLqIdx[i].flag;
      io_enq_resp_lqIdx_value[i]  = respLqIdx[i].value;
      io_enq_resp_sqIdx_flag[i]   = respSqIdx[i].flag;
      io_enq_resp_sqIdx_value[i]  = respSqIdx[i].value;

      io_enqLsq_req_exceptionVec[i]         = outReg[i].uop.exceptionVec;
      io_enqLsq_req_trigger[i]              = outReg[i].uop.trigger;
      io_enqLsq_req_fuType[i]               = outReg[i].uop.fuType;
      io_enqLsq_req_fuOpType[i]             = outReg[i].uop.fuOpType;
      io_enqLsq_req_rfWen[i]                = outReg[i].uop.rfWen;
      io_enqLsq_req_flushPipe[i]            = outReg[i].uop.flushPipe;
      io_enqLsq_req_vpu_nf[i]               = outReg[i].uop.vpu_nf;
      io_enqLsq_req_vpu_veew[i]             = outReg[i].uop.vpu_veew;
      io_enqLsq_req_uopIdx[i]               = outReg[i].uop.uopIdx;
      io_enqLsq_req_lastUop[i]              = outReg[i].uop.lastUop;
      io_enqLsq_req_pdest[i]                = outReg[i].uop.pdest;
      io_enqLsq_req_robIdx_flag[i]          = outReg[i].uop.robIdx_flag;
      io_enqLsq_req_robIdx_value[i]         = outReg[i].uop.robIdx_value;
      io_enqLsq_req_debugInfo_renameTime[i] = outReg[i].uop.debugInfo_renameTime;
      io_enqLsq_req_debug_seqNum_seqNum[i]  = outReg[i].uop.debug_seqNum_seqNum;
      io_enqLsq_req_debug_seqNum_uopIdx[i]  = outReg[i].uop.debug_seqNum_uopIdx;
      io_enqLsq_req_numLsElem[i]            = outReg[i].uop.numLsElem;

      io_enqLsq_req_debugInfo_eliminatedMove[i]         = outReg[i].debugInfo_eliminatedMove;
      io_enqLsq_req_debugInfo_dispatchTime[i]           = outReg[i].debugInfo_dispatchTime;
      io_enqLsq_req_debugInfo_enqRsTime[i]              = outReg[i].debugInfo_enqRsTime;
      io_enqLsq_req_debugInfo_selectTime[i]             = outReg[i].debugInfo_selectTime;
      io_enqLsq_req_debugInfo_issueTime[i]              = outReg[i].debugInfo_issueTime;
      io_enqLsq_req_debugInfo_writebackTime[i]          = outReg[i].debugInfo_writebackTime;
      io_enqLsq_req_debugInfo_runahead_checkpoint_id[i] = outReg[i].debugInfo_runahead_checkpoint_id;
      io_enqLsq_req_debugInfo_tlbFirstReqTime[i]        = outReg[i].debugInfo_tlbFirstReqTime;
      io_enqLsq_req_debugInfo_tlbRespTime[i]            = outReg[i].debugInfo_tlbRespTime;

      io_enqLsq_req_lqIdx_flag[i]  = outReg[i].lqIdx.flag;
      io_enqLsq_req_lqIdx_value[i] = outReg[i].lqIdx.value;
      io_enqLsq_req_sqIdx_flag[i]  = outReg[i].sqIdx.flag;
      io_enqLsq_req_sqIdx_value[i] = outReg[i].sqIdx.value;
    end

endmodule

// BEGIN GENERATED(wrapper)
module LsqEnqCtrl(
  input         clock,
  input         reset,
  input         io_redirect_valid,
  output        io_enq_canAccept,
  input  [1:0]  io_enq_needAlloc_0,
  input  [1:0]  io_enq_needAlloc_1,
  input  [1:0]  io_enq_needAlloc_2,
  input  [1:0]  io_enq_needAlloc_3,
  input  [1:0]  io_enq_needAlloc_4,
  input  [1:0]  io_enq_needAlloc_5,
  input         io_enq_req_0_valid,
  input         io_enq_req_0_bits_exceptionVec_0,
  input         io_enq_req_0_bits_exceptionVec_1,
  input         io_enq_req_0_bits_exceptionVec_2,
  input         io_enq_req_0_bits_exceptionVec_3,
  input         io_enq_req_0_bits_exceptionVec_4,
  input         io_enq_req_0_bits_exceptionVec_5,
  input         io_enq_req_0_bits_exceptionVec_6,
  input         io_enq_req_0_bits_exceptionVec_7,
  input         io_enq_req_0_bits_exceptionVec_8,
  input         io_enq_req_0_bits_exceptionVec_9,
  input         io_enq_req_0_bits_exceptionVec_10,
  input         io_enq_req_0_bits_exceptionVec_11,
  input         io_enq_req_0_bits_exceptionVec_12,
  input         io_enq_req_0_bits_exceptionVec_13,
  input         io_enq_req_0_bits_exceptionVec_14,
  input         io_enq_req_0_bits_exceptionVec_15,
  input         io_enq_req_0_bits_exceptionVec_16,
  input         io_enq_req_0_bits_exceptionVec_17,
  input         io_enq_req_0_bits_exceptionVec_18,
  input         io_enq_req_0_bits_exceptionVec_19,
  input         io_enq_req_0_bits_exceptionVec_20,
  input         io_enq_req_0_bits_exceptionVec_21,
  input         io_enq_req_0_bits_exceptionVec_22,
  input         io_enq_req_0_bits_exceptionVec_23,
  input  [3:0]  io_enq_req_0_bits_trigger,
  input  [34:0] io_enq_req_0_bits_fuType,
  input  [8:0]  io_enq_req_0_bits_fuOpType,
  input         io_enq_req_0_bits_rfWen,
  input         io_enq_req_0_bits_flushPipe,
  input  [2:0]  io_enq_req_0_bits_vpu_nf,
  input  [1:0]  io_enq_req_0_bits_vpu_veew,
  input  [6:0]  io_enq_req_0_bits_uopIdx,
  input         io_enq_req_0_bits_lastUop,
  input  [7:0]  io_enq_req_0_bits_pdest,
  input         io_enq_req_0_bits_robIdx_flag,
  input  [7:0]  io_enq_req_0_bits_robIdx_value,
  input  [63:0] io_enq_req_0_bits_debugInfo_renameTime,
  input  [55:0] io_enq_req_0_bits_debug_seqNum_seqNum,
  input  [7:0]  io_enq_req_0_bits_debug_seqNum_uopIdx,
  input  [4:0]  io_enq_req_0_bits_numLsElem,
  input         io_enq_req_1_valid,
  input         io_enq_req_1_bits_exceptionVec_0,
  input         io_enq_req_1_bits_exceptionVec_1,
  input         io_enq_req_1_bits_exceptionVec_2,
  input         io_enq_req_1_bits_exceptionVec_3,
  input         io_enq_req_1_bits_exceptionVec_4,
  input         io_enq_req_1_bits_exceptionVec_5,
  input         io_enq_req_1_bits_exceptionVec_6,
  input         io_enq_req_1_bits_exceptionVec_7,
  input         io_enq_req_1_bits_exceptionVec_8,
  input         io_enq_req_1_bits_exceptionVec_9,
  input         io_enq_req_1_bits_exceptionVec_10,
  input         io_enq_req_1_bits_exceptionVec_11,
  input         io_enq_req_1_bits_exceptionVec_12,
  input         io_enq_req_1_bits_exceptionVec_13,
  input         io_enq_req_1_bits_exceptionVec_14,
  input         io_enq_req_1_bits_exceptionVec_15,
  input         io_enq_req_1_bits_exceptionVec_16,
  input         io_enq_req_1_bits_exceptionVec_17,
  input         io_enq_req_1_bits_exceptionVec_18,
  input         io_enq_req_1_bits_exceptionVec_19,
  input         io_enq_req_1_bits_exceptionVec_20,
  input         io_enq_req_1_bits_exceptionVec_21,
  input         io_enq_req_1_bits_exceptionVec_22,
  input         io_enq_req_1_bits_exceptionVec_23,
  input  [3:0]  io_enq_req_1_bits_trigger,
  input  [34:0] io_enq_req_1_bits_fuType,
  input  [8:0]  io_enq_req_1_bits_fuOpType,
  input         io_enq_req_1_bits_rfWen,
  input         io_enq_req_1_bits_flushPipe,
  input  [2:0]  io_enq_req_1_bits_vpu_nf,
  input  [1:0]  io_enq_req_1_bits_vpu_veew,
  input  [6:0]  io_enq_req_1_bits_uopIdx,
  input         io_enq_req_1_bits_lastUop,
  input  [7:0]  io_enq_req_1_bits_pdest,
  input         io_enq_req_1_bits_robIdx_flag,
  input  [7:0]  io_enq_req_1_bits_robIdx_value,
  input  [63:0] io_enq_req_1_bits_debugInfo_renameTime,
  input  [55:0] io_enq_req_1_bits_debug_seqNum_seqNum,
  input  [7:0]  io_enq_req_1_bits_debug_seqNum_uopIdx,
  input  [4:0]  io_enq_req_1_bits_numLsElem,
  input         io_enq_req_2_valid,
  input         io_enq_req_2_bits_exceptionVec_0,
  input         io_enq_req_2_bits_exceptionVec_1,
  input         io_enq_req_2_bits_exceptionVec_2,
  input         io_enq_req_2_bits_exceptionVec_3,
  input         io_enq_req_2_bits_exceptionVec_4,
  input         io_enq_req_2_bits_exceptionVec_5,
  input         io_enq_req_2_bits_exceptionVec_6,
  input         io_enq_req_2_bits_exceptionVec_7,
  input         io_enq_req_2_bits_exceptionVec_8,
  input         io_enq_req_2_bits_exceptionVec_9,
  input         io_enq_req_2_bits_exceptionVec_10,
  input         io_enq_req_2_bits_exceptionVec_11,
  input         io_enq_req_2_bits_exceptionVec_12,
  input         io_enq_req_2_bits_exceptionVec_13,
  input         io_enq_req_2_bits_exceptionVec_14,
  input         io_enq_req_2_bits_exceptionVec_15,
  input         io_enq_req_2_bits_exceptionVec_16,
  input         io_enq_req_2_bits_exceptionVec_17,
  input         io_enq_req_2_bits_exceptionVec_18,
  input         io_enq_req_2_bits_exceptionVec_19,
  input         io_enq_req_2_bits_exceptionVec_20,
  input         io_enq_req_2_bits_exceptionVec_21,
  input         io_enq_req_2_bits_exceptionVec_22,
  input         io_enq_req_2_bits_exceptionVec_23,
  input  [3:0]  io_enq_req_2_bits_trigger,
  input  [34:0] io_enq_req_2_bits_fuType,
  input  [8:0]  io_enq_req_2_bits_fuOpType,
  input         io_enq_req_2_bits_rfWen,
  input         io_enq_req_2_bits_flushPipe,
  input  [2:0]  io_enq_req_2_bits_vpu_nf,
  input  [1:0]  io_enq_req_2_bits_vpu_veew,
  input  [6:0]  io_enq_req_2_bits_uopIdx,
  input         io_enq_req_2_bits_lastUop,
  input  [7:0]  io_enq_req_2_bits_pdest,
  input         io_enq_req_2_bits_robIdx_flag,
  input  [7:0]  io_enq_req_2_bits_robIdx_value,
  input  [63:0] io_enq_req_2_bits_debugInfo_renameTime,
  input  [55:0] io_enq_req_2_bits_debug_seqNum_seqNum,
  input  [7:0]  io_enq_req_2_bits_debug_seqNum_uopIdx,
  input  [4:0]  io_enq_req_2_bits_numLsElem,
  input         io_enq_req_3_valid,
  input         io_enq_req_3_bits_exceptionVec_0,
  input         io_enq_req_3_bits_exceptionVec_1,
  input         io_enq_req_3_bits_exceptionVec_2,
  input         io_enq_req_3_bits_exceptionVec_3,
  input         io_enq_req_3_bits_exceptionVec_4,
  input         io_enq_req_3_bits_exceptionVec_5,
  input         io_enq_req_3_bits_exceptionVec_6,
  input         io_enq_req_3_bits_exceptionVec_7,
  input         io_enq_req_3_bits_exceptionVec_8,
  input         io_enq_req_3_bits_exceptionVec_9,
  input         io_enq_req_3_bits_exceptionVec_10,
  input         io_enq_req_3_bits_exceptionVec_11,
  input         io_enq_req_3_bits_exceptionVec_12,
  input         io_enq_req_3_bits_exceptionVec_13,
  input         io_enq_req_3_bits_exceptionVec_14,
  input         io_enq_req_3_bits_exceptionVec_15,
  input         io_enq_req_3_bits_exceptionVec_16,
  input         io_enq_req_3_bits_exceptionVec_17,
  input         io_enq_req_3_bits_exceptionVec_18,
  input         io_enq_req_3_bits_exceptionVec_19,
  input         io_enq_req_3_bits_exceptionVec_20,
  input         io_enq_req_3_bits_exceptionVec_21,
  input         io_enq_req_3_bits_exceptionVec_22,
  input         io_enq_req_3_bits_exceptionVec_23,
  input  [3:0]  io_enq_req_3_bits_trigger,
  input  [34:0] io_enq_req_3_bits_fuType,
  input  [8:0]  io_enq_req_3_bits_fuOpType,
  input         io_enq_req_3_bits_rfWen,
  input         io_enq_req_3_bits_flushPipe,
  input  [2:0]  io_enq_req_3_bits_vpu_nf,
  input  [1:0]  io_enq_req_3_bits_vpu_veew,
  input  [6:0]  io_enq_req_3_bits_uopIdx,
  input         io_enq_req_3_bits_lastUop,
  input  [7:0]  io_enq_req_3_bits_pdest,
  input         io_enq_req_3_bits_robIdx_flag,
  input  [7:0]  io_enq_req_3_bits_robIdx_value,
  input  [63:0] io_enq_req_3_bits_debugInfo_renameTime,
  input  [55:0] io_enq_req_3_bits_debug_seqNum_seqNum,
  input  [7:0]  io_enq_req_3_bits_debug_seqNum_uopIdx,
  input  [4:0]  io_enq_req_3_bits_numLsElem,
  input         io_enq_req_4_valid,
  input         io_enq_req_4_bits_exceptionVec_0,
  input         io_enq_req_4_bits_exceptionVec_1,
  input         io_enq_req_4_bits_exceptionVec_2,
  input         io_enq_req_4_bits_exceptionVec_3,
  input         io_enq_req_4_bits_exceptionVec_4,
  input         io_enq_req_4_bits_exceptionVec_5,
  input         io_enq_req_4_bits_exceptionVec_6,
  input         io_enq_req_4_bits_exceptionVec_7,
  input         io_enq_req_4_bits_exceptionVec_8,
  input         io_enq_req_4_bits_exceptionVec_9,
  input         io_enq_req_4_bits_exceptionVec_10,
  input         io_enq_req_4_bits_exceptionVec_11,
  input         io_enq_req_4_bits_exceptionVec_12,
  input         io_enq_req_4_bits_exceptionVec_13,
  input         io_enq_req_4_bits_exceptionVec_14,
  input         io_enq_req_4_bits_exceptionVec_15,
  input         io_enq_req_4_bits_exceptionVec_16,
  input         io_enq_req_4_bits_exceptionVec_17,
  input         io_enq_req_4_bits_exceptionVec_18,
  input         io_enq_req_4_bits_exceptionVec_19,
  input         io_enq_req_4_bits_exceptionVec_20,
  input         io_enq_req_4_bits_exceptionVec_21,
  input         io_enq_req_4_bits_exceptionVec_22,
  input         io_enq_req_4_bits_exceptionVec_23,
  input  [3:0]  io_enq_req_4_bits_trigger,
  input  [34:0] io_enq_req_4_bits_fuType,
  input  [8:0]  io_enq_req_4_bits_fuOpType,
  input         io_enq_req_4_bits_rfWen,
  input         io_enq_req_4_bits_flushPipe,
  input  [2:0]  io_enq_req_4_bits_vpu_nf,
  input  [1:0]  io_enq_req_4_bits_vpu_veew,
  input  [6:0]  io_enq_req_4_bits_uopIdx,
  input         io_enq_req_4_bits_lastUop,
  input  [7:0]  io_enq_req_4_bits_pdest,
  input         io_enq_req_4_bits_robIdx_flag,
  input  [7:0]  io_enq_req_4_bits_robIdx_value,
  input  [63:0] io_enq_req_4_bits_debugInfo_renameTime,
  input  [55:0] io_enq_req_4_bits_debug_seqNum_seqNum,
  input  [7:0]  io_enq_req_4_bits_debug_seqNum_uopIdx,
  input  [4:0]  io_enq_req_4_bits_numLsElem,
  input         io_enq_req_5_valid,
  input         io_enq_req_5_bits_exceptionVec_0,
  input         io_enq_req_5_bits_exceptionVec_1,
  input         io_enq_req_5_bits_exceptionVec_2,
  input         io_enq_req_5_bits_exceptionVec_3,
  input         io_enq_req_5_bits_exceptionVec_4,
  input         io_enq_req_5_bits_exceptionVec_5,
  input         io_enq_req_5_bits_exceptionVec_6,
  input         io_enq_req_5_bits_exceptionVec_7,
  input         io_enq_req_5_bits_exceptionVec_8,
  input         io_enq_req_5_bits_exceptionVec_9,
  input         io_enq_req_5_bits_exceptionVec_10,
  input         io_enq_req_5_bits_exceptionVec_11,
  input         io_enq_req_5_bits_exceptionVec_12,
  input         io_enq_req_5_bits_exceptionVec_13,
  input         io_enq_req_5_bits_exceptionVec_14,
  input         io_enq_req_5_bits_exceptionVec_15,
  input         io_enq_req_5_bits_exceptionVec_16,
  input         io_enq_req_5_bits_exceptionVec_17,
  input         io_enq_req_5_bits_exceptionVec_18,
  input         io_enq_req_5_bits_exceptionVec_19,
  input         io_enq_req_5_bits_exceptionVec_20,
  input         io_enq_req_5_bits_exceptionVec_21,
  input         io_enq_req_5_bits_exceptionVec_22,
  input         io_enq_req_5_bits_exceptionVec_23,
  input  [3:0]  io_enq_req_5_bits_trigger,
  input  [34:0] io_enq_req_5_bits_fuType,
  input  [8:0]  io_enq_req_5_bits_fuOpType,
  input         io_enq_req_5_bits_rfWen,
  input         io_enq_req_5_bits_flushPipe,
  input  [2:0]  io_enq_req_5_bits_vpu_nf,
  input  [1:0]  io_enq_req_5_bits_vpu_veew,
  input  [6:0]  io_enq_req_5_bits_uopIdx,
  input         io_enq_req_5_bits_lastUop,
  input  [7:0]  io_enq_req_5_bits_pdest,
  input         io_enq_req_5_bits_robIdx_flag,
  input  [7:0]  io_enq_req_5_bits_robIdx_value,
  input  [63:0] io_enq_req_5_bits_debugInfo_renameTime,
  input  [55:0] io_enq_req_5_bits_debug_seqNum_seqNum,
  input  [7:0]  io_enq_req_5_bits_debug_seqNum_uopIdx,
  input  [4:0]  io_enq_req_5_bits_numLsElem,
  input         io_enq_iqAccept_0,
  input         io_enq_iqAccept_1,
  input         io_enq_iqAccept_2,
  input         io_enq_iqAccept_3,
  input         io_enq_iqAccept_4,
  input         io_enq_iqAccept_5,
  output        io_enq_resp_0_lqIdx_flag,
  output [6:0]  io_enq_resp_0_lqIdx_value,
  output        io_enq_resp_0_sqIdx_flag,
  output [5:0]  io_enq_resp_0_sqIdx_value,
  output        io_enq_resp_1_lqIdx_flag,
  output [6:0]  io_enq_resp_1_lqIdx_value,
  output        io_enq_resp_1_sqIdx_flag,
  output [5:0]  io_enq_resp_1_sqIdx_value,
  output        io_enq_resp_2_lqIdx_flag,
  output [6:0]  io_enq_resp_2_lqIdx_value,
  output        io_enq_resp_2_sqIdx_flag,
  output [5:0]  io_enq_resp_2_sqIdx_value,
  output        io_enq_resp_3_lqIdx_flag,
  output [6:0]  io_enq_resp_3_lqIdx_value,
  output        io_enq_resp_3_sqIdx_flag,
  output [5:0]  io_enq_resp_3_sqIdx_value,
  output        io_enq_resp_4_lqIdx_flag,
  output [6:0]  io_enq_resp_4_lqIdx_value,
  output        io_enq_resp_4_sqIdx_flag,
  output [5:0]  io_enq_resp_4_sqIdx_value,
  output        io_enq_resp_5_lqIdx_flag,
  output [6:0]  io_enq_resp_5_lqIdx_value,
  output        io_enq_resp_5_sqIdx_flag,
  output [5:0]  io_enq_resp_5_sqIdx_value,
  input  [3:0]  io_lcommit,
  input  [1:0]  io_scommit,
  input  [6:0]  io_lqCancelCnt,
  input  [5:0]  io_sqCancelCnt,
  output [6:0]  io_lqFreeCount,
  output [5:0]  io_sqFreeCount,
  output [1:0]  io_enqLsq_needAlloc_0,
  output [1:0]  io_enqLsq_needAlloc_1,
  output [1:0]  io_enqLsq_needAlloc_2,
  output [1:0]  io_enqLsq_needAlloc_3,
  output [1:0]  io_enqLsq_needAlloc_4,
  output [1:0]  io_enqLsq_needAlloc_5,
  output        io_enqLsq_req_0_valid,
  output        io_enqLsq_req_0_bits_exceptionVec_0,
  output        io_enqLsq_req_0_bits_exceptionVec_1,
  output        io_enqLsq_req_0_bits_exceptionVec_2,
  output        io_enqLsq_req_0_bits_exceptionVec_3,
  output        io_enqLsq_req_0_bits_exceptionVec_4,
  output        io_enqLsq_req_0_bits_exceptionVec_5,
  output        io_enqLsq_req_0_bits_exceptionVec_6,
  output        io_enqLsq_req_0_bits_exceptionVec_7,
  output        io_enqLsq_req_0_bits_exceptionVec_8,
  output        io_enqLsq_req_0_bits_exceptionVec_9,
  output        io_enqLsq_req_0_bits_exceptionVec_10,
  output        io_enqLsq_req_0_bits_exceptionVec_11,
  output        io_enqLsq_req_0_bits_exceptionVec_12,
  output        io_enqLsq_req_0_bits_exceptionVec_13,
  output        io_enqLsq_req_0_bits_exceptionVec_14,
  output        io_enqLsq_req_0_bits_exceptionVec_15,
  output        io_enqLsq_req_0_bits_exceptionVec_16,
  output        io_enqLsq_req_0_bits_exceptionVec_17,
  output        io_enqLsq_req_0_bits_exceptionVec_18,
  output        io_enqLsq_req_0_bits_exceptionVec_19,
  output        io_enqLsq_req_0_bits_exceptionVec_20,
  output        io_enqLsq_req_0_bits_exceptionVec_21,
  output        io_enqLsq_req_0_bits_exceptionVec_22,
  output        io_enqLsq_req_0_bits_exceptionVec_23,
  output [3:0]  io_enqLsq_req_0_bits_trigger,
  output [34:0] io_enqLsq_req_0_bits_fuType,
  output [8:0]  io_enqLsq_req_0_bits_fuOpType,
  output        io_enqLsq_req_0_bits_rfWen,
  output        io_enqLsq_req_0_bits_flushPipe,
  output [2:0]  io_enqLsq_req_0_bits_vpu_nf,
  output [1:0]  io_enqLsq_req_0_bits_vpu_veew,
  output [6:0]  io_enqLsq_req_0_bits_uopIdx,
  output        io_enqLsq_req_0_bits_lastUop,
  output [7:0]  io_enqLsq_req_0_bits_pdest,
  output        io_enqLsq_req_0_bits_robIdx_flag,
  output [7:0]  io_enqLsq_req_0_bits_robIdx_value,
  output        io_enqLsq_req_0_bits_debugInfo_eliminatedMove,
  output [63:0] io_enqLsq_req_0_bits_debugInfo_renameTime,
  output [63:0] io_enqLsq_req_0_bits_debugInfo_dispatchTime,
  output [63:0] io_enqLsq_req_0_bits_debugInfo_enqRsTime,
  output [63:0] io_enqLsq_req_0_bits_debugInfo_selectTime,
  output [63:0] io_enqLsq_req_0_bits_debugInfo_issueTime,
  output [63:0] io_enqLsq_req_0_bits_debugInfo_writebackTime,
  output [63:0] io_enqLsq_req_0_bits_debugInfo_runahead_checkpoint_id,
  output [63:0] io_enqLsq_req_0_bits_debugInfo_tlbFirstReqTime,
  output [63:0] io_enqLsq_req_0_bits_debugInfo_tlbRespTime,
  output [55:0] io_enqLsq_req_0_bits_debug_seqNum_seqNum,
  output [7:0]  io_enqLsq_req_0_bits_debug_seqNum_uopIdx,
  output        io_enqLsq_req_0_bits_lqIdx_flag,
  output [6:0]  io_enqLsq_req_0_bits_lqIdx_value,
  output        io_enqLsq_req_0_bits_sqIdx_flag,
  output [5:0]  io_enqLsq_req_0_bits_sqIdx_value,
  output [4:0]  io_enqLsq_req_0_bits_numLsElem,
  output        io_enqLsq_req_1_valid,
  output        io_enqLsq_req_1_bits_exceptionVec_0,
  output        io_enqLsq_req_1_bits_exceptionVec_1,
  output        io_enqLsq_req_1_bits_exceptionVec_2,
  output        io_enqLsq_req_1_bits_exceptionVec_3,
  output        io_enqLsq_req_1_bits_exceptionVec_4,
  output        io_enqLsq_req_1_bits_exceptionVec_5,
  output        io_enqLsq_req_1_bits_exceptionVec_6,
  output        io_enqLsq_req_1_bits_exceptionVec_7,
  output        io_enqLsq_req_1_bits_exceptionVec_8,
  output        io_enqLsq_req_1_bits_exceptionVec_9,
  output        io_enqLsq_req_1_bits_exceptionVec_10,
  output        io_enqLsq_req_1_bits_exceptionVec_11,
  output        io_enqLsq_req_1_bits_exceptionVec_12,
  output        io_enqLsq_req_1_bits_exceptionVec_13,
  output        io_enqLsq_req_1_bits_exceptionVec_14,
  output        io_enqLsq_req_1_bits_exceptionVec_15,
  output        io_enqLsq_req_1_bits_exceptionVec_16,
  output        io_enqLsq_req_1_bits_exceptionVec_17,
  output        io_enqLsq_req_1_bits_exceptionVec_18,
  output        io_enqLsq_req_1_bits_exceptionVec_19,
  output        io_enqLsq_req_1_bits_exceptionVec_20,
  output        io_enqLsq_req_1_bits_exceptionVec_21,
  output        io_enqLsq_req_1_bits_exceptionVec_22,
  output        io_enqLsq_req_1_bits_exceptionVec_23,
  output [3:0]  io_enqLsq_req_1_bits_trigger,
  output [34:0] io_enqLsq_req_1_bits_fuType,
  output [8:0]  io_enqLsq_req_1_bits_fuOpType,
  output        io_enqLsq_req_1_bits_rfWen,
  output        io_enqLsq_req_1_bits_flushPipe,
  output [2:0]  io_enqLsq_req_1_bits_vpu_nf,
  output [1:0]  io_enqLsq_req_1_bits_vpu_veew,
  output [6:0]  io_enqLsq_req_1_bits_uopIdx,
  output        io_enqLsq_req_1_bits_lastUop,
  output [7:0]  io_enqLsq_req_1_bits_pdest,
  output        io_enqLsq_req_1_bits_robIdx_flag,
  output [7:0]  io_enqLsq_req_1_bits_robIdx_value,
  output        io_enqLsq_req_1_bits_debugInfo_eliminatedMove,
  output [63:0] io_enqLsq_req_1_bits_debugInfo_renameTime,
  output [63:0] io_enqLsq_req_1_bits_debugInfo_dispatchTime,
  output [63:0] io_enqLsq_req_1_bits_debugInfo_enqRsTime,
  output [63:0] io_enqLsq_req_1_bits_debugInfo_selectTime,
  output [63:0] io_enqLsq_req_1_bits_debugInfo_issueTime,
  output [63:0] io_enqLsq_req_1_bits_debugInfo_writebackTime,
  output [63:0] io_enqLsq_req_1_bits_debugInfo_runahead_checkpoint_id,
  output [63:0] io_enqLsq_req_1_bits_debugInfo_tlbFirstReqTime,
  output [63:0] io_enqLsq_req_1_bits_debugInfo_tlbRespTime,
  output [55:0] io_enqLsq_req_1_bits_debug_seqNum_seqNum,
  output [7:0]  io_enqLsq_req_1_bits_debug_seqNum_uopIdx,
  output        io_enqLsq_req_1_bits_lqIdx_flag,
  output [6:0]  io_enqLsq_req_1_bits_lqIdx_value,
  output        io_enqLsq_req_1_bits_sqIdx_flag,
  output [5:0]  io_enqLsq_req_1_bits_sqIdx_value,
  output [4:0]  io_enqLsq_req_1_bits_numLsElem,
  output        io_enqLsq_req_2_valid,
  output        io_enqLsq_req_2_bits_exceptionVec_0,
  output        io_enqLsq_req_2_bits_exceptionVec_1,
  output        io_enqLsq_req_2_bits_exceptionVec_2,
  output        io_enqLsq_req_2_bits_exceptionVec_3,
  output        io_enqLsq_req_2_bits_exceptionVec_4,
  output        io_enqLsq_req_2_bits_exceptionVec_5,
  output        io_enqLsq_req_2_bits_exceptionVec_6,
  output        io_enqLsq_req_2_bits_exceptionVec_7,
  output        io_enqLsq_req_2_bits_exceptionVec_8,
  output        io_enqLsq_req_2_bits_exceptionVec_9,
  output        io_enqLsq_req_2_bits_exceptionVec_10,
  output        io_enqLsq_req_2_bits_exceptionVec_11,
  output        io_enqLsq_req_2_bits_exceptionVec_12,
  output        io_enqLsq_req_2_bits_exceptionVec_13,
  output        io_enqLsq_req_2_bits_exceptionVec_14,
  output        io_enqLsq_req_2_bits_exceptionVec_15,
  output        io_enqLsq_req_2_bits_exceptionVec_16,
  output        io_enqLsq_req_2_bits_exceptionVec_17,
  output        io_enqLsq_req_2_bits_exceptionVec_18,
  output        io_enqLsq_req_2_bits_exceptionVec_19,
  output        io_enqLsq_req_2_bits_exceptionVec_20,
  output        io_enqLsq_req_2_bits_exceptionVec_21,
  output        io_enqLsq_req_2_bits_exceptionVec_22,
  output        io_enqLsq_req_2_bits_exceptionVec_23,
  output [3:0]  io_enqLsq_req_2_bits_trigger,
  output [34:0] io_enqLsq_req_2_bits_fuType,
  output [8:0]  io_enqLsq_req_2_bits_fuOpType,
  output        io_enqLsq_req_2_bits_rfWen,
  output        io_enqLsq_req_2_bits_flushPipe,
  output [2:0]  io_enqLsq_req_2_bits_vpu_nf,
  output [1:0]  io_enqLsq_req_2_bits_vpu_veew,
  output [6:0]  io_enqLsq_req_2_bits_uopIdx,
  output        io_enqLsq_req_2_bits_lastUop,
  output [7:0]  io_enqLsq_req_2_bits_pdest,
  output        io_enqLsq_req_2_bits_robIdx_flag,
  output [7:0]  io_enqLsq_req_2_bits_robIdx_value,
  output        io_enqLsq_req_2_bits_debugInfo_eliminatedMove,
  output [63:0] io_enqLsq_req_2_bits_debugInfo_renameTime,
  output [63:0] io_enqLsq_req_2_bits_debugInfo_dispatchTime,
  output [63:0] io_enqLsq_req_2_bits_debugInfo_enqRsTime,
  output [63:0] io_enqLsq_req_2_bits_debugInfo_selectTime,
  output [63:0] io_enqLsq_req_2_bits_debugInfo_issueTime,
  output [63:0] io_enqLsq_req_2_bits_debugInfo_writebackTime,
  output [63:0] io_enqLsq_req_2_bits_debugInfo_runahead_checkpoint_id,
  output [63:0] io_enqLsq_req_2_bits_debugInfo_tlbFirstReqTime,
  output [63:0] io_enqLsq_req_2_bits_debugInfo_tlbRespTime,
  output [55:0] io_enqLsq_req_2_bits_debug_seqNum_seqNum,
  output [7:0]  io_enqLsq_req_2_bits_debug_seqNum_uopIdx,
  output        io_enqLsq_req_2_bits_lqIdx_flag,
  output [6:0]  io_enqLsq_req_2_bits_lqIdx_value,
  output        io_enqLsq_req_2_bits_sqIdx_flag,
  output [5:0]  io_enqLsq_req_2_bits_sqIdx_value,
  output [4:0]  io_enqLsq_req_2_bits_numLsElem,
  output        io_enqLsq_req_3_valid,
  output        io_enqLsq_req_3_bits_exceptionVec_0,
  output        io_enqLsq_req_3_bits_exceptionVec_1,
  output        io_enqLsq_req_3_bits_exceptionVec_2,
  output        io_enqLsq_req_3_bits_exceptionVec_3,
  output        io_enqLsq_req_3_bits_exceptionVec_4,
  output        io_enqLsq_req_3_bits_exceptionVec_5,
  output        io_enqLsq_req_3_bits_exceptionVec_6,
  output        io_enqLsq_req_3_bits_exceptionVec_7,
  output        io_enqLsq_req_3_bits_exceptionVec_8,
  output        io_enqLsq_req_3_bits_exceptionVec_9,
  output        io_enqLsq_req_3_bits_exceptionVec_10,
  output        io_enqLsq_req_3_bits_exceptionVec_11,
  output        io_enqLsq_req_3_bits_exceptionVec_12,
  output        io_enqLsq_req_3_bits_exceptionVec_13,
  output        io_enqLsq_req_3_bits_exceptionVec_14,
  output        io_enqLsq_req_3_bits_exceptionVec_15,
  output        io_enqLsq_req_3_bits_exceptionVec_16,
  output        io_enqLsq_req_3_bits_exceptionVec_17,
  output        io_enqLsq_req_3_bits_exceptionVec_18,
  output        io_enqLsq_req_3_bits_exceptionVec_19,
  output        io_enqLsq_req_3_bits_exceptionVec_20,
  output        io_enqLsq_req_3_bits_exceptionVec_21,
  output        io_enqLsq_req_3_bits_exceptionVec_22,
  output        io_enqLsq_req_3_bits_exceptionVec_23,
  output [3:0]  io_enqLsq_req_3_bits_trigger,
  output [34:0] io_enqLsq_req_3_bits_fuType,
  output [8:0]  io_enqLsq_req_3_bits_fuOpType,
  output        io_enqLsq_req_3_bits_rfWen,
  output        io_enqLsq_req_3_bits_flushPipe,
  output [2:0]  io_enqLsq_req_3_bits_vpu_nf,
  output [1:0]  io_enqLsq_req_3_bits_vpu_veew,
  output [6:0]  io_enqLsq_req_3_bits_uopIdx,
  output        io_enqLsq_req_3_bits_lastUop,
  output [7:0]  io_enqLsq_req_3_bits_pdest,
  output        io_enqLsq_req_3_bits_robIdx_flag,
  output [7:0]  io_enqLsq_req_3_bits_robIdx_value,
  output        io_enqLsq_req_3_bits_debugInfo_eliminatedMove,
  output [63:0] io_enqLsq_req_3_bits_debugInfo_renameTime,
  output [63:0] io_enqLsq_req_3_bits_debugInfo_dispatchTime,
  output [63:0] io_enqLsq_req_3_bits_debugInfo_enqRsTime,
  output [63:0] io_enqLsq_req_3_bits_debugInfo_selectTime,
  output [63:0] io_enqLsq_req_3_bits_debugInfo_issueTime,
  output [63:0] io_enqLsq_req_3_bits_debugInfo_writebackTime,
  output [63:0] io_enqLsq_req_3_bits_debugInfo_runahead_checkpoint_id,
  output [63:0] io_enqLsq_req_3_bits_debugInfo_tlbFirstReqTime,
  output [63:0] io_enqLsq_req_3_bits_debugInfo_tlbRespTime,
  output [55:0] io_enqLsq_req_3_bits_debug_seqNum_seqNum,
  output [7:0]  io_enqLsq_req_3_bits_debug_seqNum_uopIdx,
  output        io_enqLsq_req_3_bits_lqIdx_flag,
  output [6:0]  io_enqLsq_req_3_bits_lqIdx_value,
  output        io_enqLsq_req_3_bits_sqIdx_flag,
  output [5:0]  io_enqLsq_req_3_bits_sqIdx_value,
  output [4:0]  io_enqLsq_req_3_bits_numLsElem,
  output        io_enqLsq_req_4_valid,
  output        io_enqLsq_req_4_bits_exceptionVec_0,
  output        io_enqLsq_req_4_bits_exceptionVec_1,
  output        io_enqLsq_req_4_bits_exceptionVec_2,
  output        io_enqLsq_req_4_bits_exceptionVec_3,
  output        io_enqLsq_req_4_bits_exceptionVec_4,
  output        io_enqLsq_req_4_bits_exceptionVec_5,
  output        io_enqLsq_req_4_bits_exceptionVec_6,
  output        io_enqLsq_req_4_bits_exceptionVec_7,
  output        io_enqLsq_req_4_bits_exceptionVec_8,
  output        io_enqLsq_req_4_bits_exceptionVec_9,
  output        io_enqLsq_req_4_bits_exceptionVec_10,
  output        io_enqLsq_req_4_bits_exceptionVec_11,
  output        io_enqLsq_req_4_bits_exceptionVec_12,
  output        io_enqLsq_req_4_bits_exceptionVec_13,
  output        io_enqLsq_req_4_bits_exceptionVec_14,
  output        io_enqLsq_req_4_bits_exceptionVec_15,
  output        io_enqLsq_req_4_bits_exceptionVec_16,
  output        io_enqLsq_req_4_bits_exceptionVec_17,
  output        io_enqLsq_req_4_bits_exceptionVec_18,
  output        io_enqLsq_req_4_bits_exceptionVec_19,
  output        io_enqLsq_req_4_bits_exceptionVec_20,
  output        io_enqLsq_req_4_bits_exceptionVec_21,
  output        io_enqLsq_req_4_bits_exceptionVec_22,
  output        io_enqLsq_req_4_bits_exceptionVec_23,
  output [3:0]  io_enqLsq_req_4_bits_trigger,
  output [34:0] io_enqLsq_req_4_bits_fuType,
  output [8:0]  io_enqLsq_req_4_bits_fuOpType,
  output        io_enqLsq_req_4_bits_rfWen,
  output        io_enqLsq_req_4_bits_flushPipe,
  output [2:0]  io_enqLsq_req_4_bits_vpu_nf,
  output [1:0]  io_enqLsq_req_4_bits_vpu_veew,
  output [6:0]  io_enqLsq_req_4_bits_uopIdx,
  output        io_enqLsq_req_4_bits_lastUop,
  output [7:0]  io_enqLsq_req_4_bits_pdest,
  output        io_enqLsq_req_4_bits_robIdx_flag,
  output [7:0]  io_enqLsq_req_4_bits_robIdx_value,
  output        io_enqLsq_req_4_bits_debugInfo_eliminatedMove,
  output [63:0] io_enqLsq_req_4_bits_debugInfo_renameTime,
  output [63:0] io_enqLsq_req_4_bits_debugInfo_dispatchTime,
  output [63:0] io_enqLsq_req_4_bits_debugInfo_enqRsTime,
  output [63:0] io_enqLsq_req_4_bits_debugInfo_selectTime,
  output [63:0] io_enqLsq_req_4_bits_debugInfo_issueTime,
  output [63:0] io_enqLsq_req_4_bits_debugInfo_writebackTime,
  output [63:0] io_enqLsq_req_4_bits_debugInfo_runahead_checkpoint_id,
  output [63:0] io_enqLsq_req_4_bits_debugInfo_tlbFirstReqTime,
  output [63:0] io_enqLsq_req_4_bits_debugInfo_tlbRespTime,
  output [55:0] io_enqLsq_req_4_bits_debug_seqNum_seqNum,
  output [7:0]  io_enqLsq_req_4_bits_debug_seqNum_uopIdx,
  output        io_enqLsq_req_4_bits_lqIdx_flag,
  output [6:0]  io_enqLsq_req_4_bits_lqIdx_value,
  output        io_enqLsq_req_4_bits_sqIdx_flag,
  output [5:0]  io_enqLsq_req_4_bits_sqIdx_value,
  output [4:0]  io_enqLsq_req_4_bits_numLsElem,
  output        io_enqLsq_req_5_valid,
  output        io_enqLsq_req_5_bits_exceptionVec_0,
  output        io_enqLsq_req_5_bits_exceptionVec_1,
  output        io_enqLsq_req_5_bits_exceptionVec_2,
  output        io_enqLsq_req_5_bits_exceptionVec_3,
  output        io_enqLsq_req_5_bits_exceptionVec_4,
  output        io_enqLsq_req_5_bits_exceptionVec_5,
  output        io_enqLsq_req_5_bits_exceptionVec_6,
  output        io_enqLsq_req_5_bits_exceptionVec_7,
  output        io_enqLsq_req_5_bits_exceptionVec_8,
  output        io_enqLsq_req_5_bits_exceptionVec_9,
  output        io_enqLsq_req_5_bits_exceptionVec_10,
  output        io_enqLsq_req_5_bits_exceptionVec_11,
  output        io_enqLsq_req_5_bits_exceptionVec_12,
  output        io_enqLsq_req_5_bits_exceptionVec_13,
  output        io_enqLsq_req_5_bits_exceptionVec_14,
  output        io_enqLsq_req_5_bits_exceptionVec_15,
  output        io_enqLsq_req_5_bits_exceptionVec_16,
  output        io_enqLsq_req_5_bits_exceptionVec_17,
  output        io_enqLsq_req_5_bits_exceptionVec_18,
  output        io_enqLsq_req_5_bits_exceptionVec_19,
  output        io_enqLsq_req_5_bits_exceptionVec_20,
  output        io_enqLsq_req_5_bits_exceptionVec_21,
  output        io_enqLsq_req_5_bits_exceptionVec_22,
  output        io_enqLsq_req_5_bits_exceptionVec_23,
  output [3:0]  io_enqLsq_req_5_bits_trigger,
  output [34:0] io_enqLsq_req_5_bits_fuType,
  output [8:0]  io_enqLsq_req_5_bits_fuOpType,
  output        io_enqLsq_req_5_bits_rfWen,
  output        io_enqLsq_req_5_bits_flushPipe,
  output [2:0]  io_enqLsq_req_5_bits_vpu_nf,
  output [1:0]  io_enqLsq_req_5_bits_vpu_veew,
  output [6:0]  io_enqLsq_req_5_bits_uopIdx,
  output        io_enqLsq_req_5_bits_lastUop,
  output [7:0]  io_enqLsq_req_5_bits_pdest,
  output        io_enqLsq_req_5_bits_robIdx_flag,
  output [7:0]  io_enqLsq_req_5_bits_robIdx_value,
  output        io_enqLsq_req_5_bits_debugInfo_eliminatedMove,
  output [63:0] io_enqLsq_req_5_bits_debugInfo_renameTime,
  output [63:0] io_enqLsq_req_5_bits_debugInfo_dispatchTime,
  output [63:0] io_enqLsq_req_5_bits_debugInfo_enqRsTime,
  output [63:0] io_enqLsq_req_5_bits_debugInfo_selectTime,
  output [63:0] io_enqLsq_req_5_bits_debugInfo_issueTime,
  output [63:0] io_enqLsq_req_5_bits_debugInfo_writebackTime,
  output [63:0] io_enqLsq_req_5_bits_debugInfo_runahead_checkpoint_id,
  output [63:0] io_enqLsq_req_5_bits_debugInfo_tlbFirstReqTime,
  output [63:0] io_enqLsq_req_5_bits_debugInfo_tlbRespTime,
  output [55:0] io_enqLsq_req_5_bits_debug_seqNum_seqNum,
  output [7:0]  io_enqLsq_req_5_bits_debug_seqNum_uopIdx,
  output        io_enqLsq_req_5_bits_lqIdx_flag,
  output [6:0]  io_enqLsq_req_5_bits_lqIdx_value,
  output        io_enqLsq_req_5_bits_sqIdx_flag,
  output [5:0]  io_enqLsq_req_5_bits_sqIdx_value,
  output [4:0]  io_enqLsq_req_5_bits_numLsElem
);

  xs_LsqEnqCtrl_core u_core (
    .clock                  (clock),
    .reset                  (reset),
    .io_redirect_valid      (io_redirect_valid),
    .io_enq_canAccept       (io_enq_canAccept),
    .io_enq_needAlloc ({
      io_enq_needAlloc_5, io_enq_needAlloc_4, io_enq_needAlloc_3, io_enq_needAlloc_2,
      io_enq_needAlloc_1, io_enq_needAlloc_0
    }),
    .io_enq_iqAccept ({
      io_enq_iqAccept_5, io_enq_iqAccept_4, io_enq_iqAccept_3, io_enq_iqAccept_2,
      io_enq_iqAccept_1, io_enq_iqAccept_0
    }),
    .io_enq_req_valid ({
      io_enq_req_5_valid, io_enq_req_4_valid, io_enq_req_3_valid, io_enq_req_2_valid,
      io_enq_req_1_valid, io_enq_req_0_valid
    }),
    .io_enq_req_exceptionVec ({
      {io_enq_req_5_bits_exceptionVec_23, io_enq_req_5_bits_exceptionVec_22,
      io_enq_req_5_bits_exceptionVec_21, io_enq_req_5_bits_exceptionVec_20,
      io_enq_req_5_bits_exceptionVec_19, io_enq_req_5_bits_exceptionVec_18,
      io_enq_req_5_bits_exceptionVec_17, io_enq_req_5_bits_exceptionVec_16,
      io_enq_req_5_bits_exceptionVec_15, io_enq_req_5_bits_exceptionVec_14,
      io_enq_req_5_bits_exceptionVec_13, io_enq_req_5_bits_exceptionVec_12,
      io_enq_req_5_bits_exceptionVec_11, io_enq_req_5_bits_exceptionVec_10,
      io_enq_req_5_bits_exceptionVec_9, io_enq_req_5_bits_exceptionVec_8,
      io_enq_req_5_bits_exceptionVec_7, io_enq_req_5_bits_exceptionVec_6,
      io_enq_req_5_bits_exceptionVec_5, io_enq_req_5_bits_exceptionVec_4,
      io_enq_req_5_bits_exceptionVec_3, io_enq_req_5_bits_exceptionVec_2,
      io_enq_req_5_bits_exceptionVec_1, io_enq_req_5_bits_exceptionVec_0},
      {io_enq_req_4_bits_exceptionVec_23, io_enq_req_4_bits_exceptionVec_22,
      io_enq_req_4_bits_exceptionVec_21, io_enq_req_4_bits_exceptionVec_20,
      io_enq_req_4_bits_exceptionVec_19, io_enq_req_4_bits_exceptionVec_18,
      io_enq_req_4_bits_exceptionVec_17, io_enq_req_4_bits_exceptionVec_16,
      io_enq_req_4_bits_exceptionVec_15, io_enq_req_4_bits_exceptionVec_14,
      io_enq_req_4_bits_exceptionVec_13, io_enq_req_4_bits_exceptionVec_12,
      io_enq_req_4_bits_exceptionVec_11, io_enq_req_4_bits_exceptionVec_10,
      io_enq_req_4_bits_exceptionVec_9, io_enq_req_4_bits_exceptionVec_8,
      io_enq_req_4_bits_exceptionVec_7, io_enq_req_4_bits_exceptionVec_6,
      io_enq_req_4_bits_exceptionVec_5, io_enq_req_4_bits_exceptionVec_4,
      io_enq_req_4_bits_exceptionVec_3, io_enq_req_4_bits_exceptionVec_2,
      io_enq_req_4_bits_exceptionVec_1, io_enq_req_4_bits_exceptionVec_0},
      {io_enq_req_3_bits_exceptionVec_23, io_enq_req_3_bits_exceptionVec_22,
      io_enq_req_3_bits_exceptionVec_21, io_enq_req_3_bits_exceptionVec_20,
      io_enq_req_3_bits_exceptionVec_19, io_enq_req_3_bits_exceptionVec_18,
      io_enq_req_3_bits_exceptionVec_17, io_enq_req_3_bits_exceptionVec_16,
      io_enq_req_3_bits_exceptionVec_15, io_enq_req_3_bits_exceptionVec_14,
      io_enq_req_3_bits_exceptionVec_13, io_enq_req_3_bits_exceptionVec_12,
      io_enq_req_3_bits_exceptionVec_11, io_enq_req_3_bits_exceptionVec_10,
      io_enq_req_3_bits_exceptionVec_9, io_enq_req_3_bits_exceptionVec_8,
      io_enq_req_3_bits_exceptionVec_7, io_enq_req_3_bits_exceptionVec_6,
      io_enq_req_3_bits_exceptionVec_5, io_enq_req_3_bits_exceptionVec_4,
      io_enq_req_3_bits_exceptionVec_3, io_enq_req_3_bits_exceptionVec_2,
      io_enq_req_3_bits_exceptionVec_1, io_enq_req_3_bits_exceptionVec_0},
      {io_enq_req_2_bits_exceptionVec_23, io_enq_req_2_bits_exceptionVec_22,
      io_enq_req_2_bits_exceptionVec_21, io_enq_req_2_bits_exceptionVec_20,
      io_enq_req_2_bits_exceptionVec_19, io_enq_req_2_bits_exceptionVec_18,
      io_enq_req_2_bits_exceptionVec_17, io_enq_req_2_bits_exceptionVec_16,
      io_enq_req_2_bits_exceptionVec_15, io_enq_req_2_bits_exceptionVec_14,
      io_enq_req_2_bits_exceptionVec_13, io_enq_req_2_bits_exceptionVec_12,
      io_enq_req_2_bits_exceptionVec_11, io_enq_req_2_bits_exceptionVec_10,
      io_enq_req_2_bits_exceptionVec_9, io_enq_req_2_bits_exceptionVec_8,
      io_enq_req_2_bits_exceptionVec_7, io_enq_req_2_bits_exceptionVec_6,
      io_enq_req_2_bits_exceptionVec_5, io_enq_req_2_bits_exceptionVec_4,
      io_enq_req_2_bits_exceptionVec_3, io_enq_req_2_bits_exceptionVec_2,
      io_enq_req_2_bits_exceptionVec_1, io_enq_req_2_bits_exceptionVec_0},
      {io_enq_req_1_bits_exceptionVec_23, io_enq_req_1_bits_exceptionVec_22,
      io_enq_req_1_bits_exceptionVec_21, io_enq_req_1_bits_exceptionVec_20,
      io_enq_req_1_bits_exceptionVec_19, io_enq_req_1_bits_exceptionVec_18,
      io_enq_req_1_bits_exceptionVec_17, io_enq_req_1_bits_exceptionVec_16,
      io_enq_req_1_bits_exceptionVec_15, io_enq_req_1_bits_exceptionVec_14,
      io_enq_req_1_bits_exceptionVec_13, io_enq_req_1_bits_exceptionVec_12,
      io_enq_req_1_bits_exceptionVec_11, io_enq_req_1_bits_exceptionVec_10,
      io_enq_req_1_bits_exceptionVec_9, io_enq_req_1_bits_exceptionVec_8,
      io_enq_req_1_bits_exceptionVec_7, io_enq_req_1_bits_exceptionVec_6,
      io_enq_req_1_bits_exceptionVec_5, io_enq_req_1_bits_exceptionVec_4,
      io_enq_req_1_bits_exceptionVec_3, io_enq_req_1_bits_exceptionVec_2,
      io_enq_req_1_bits_exceptionVec_1, io_enq_req_1_bits_exceptionVec_0},
      {io_enq_req_0_bits_exceptionVec_23, io_enq_req_0_bits_exceptionVec_22,
      io_enq_req_0_bits_exceptionVec_21, io_enq_req_0_bits_exceptionVec_20,
      io_enq_req_0_bits_exceptionVec_19, io_enq_req_0_bits_exceptionVec_18,
      io_enq_req_0_bits_exceptionVec_17, io_enq_req_0_bits_exceptionVec_16,
      io_enq_req_0_bits_exceptionVec_15, io_enq_req_0_bits_exceptionVec_14,
      io_enq_req_0_bits_exceptionVec_13, io_enq_req_0_bits_exceptionVec_12,
      io_enq_req_0_bits_exceptionVec_11, io_enq_req_0_bits_exceptionVec_10,
      io_enq_req_0_bits_exceptionVec_9, io_enq_req_0_bits_exceptionVec_8,
      io_enq_req_0_bits_exceptionVec_7, io_enq_req_0_bits_exceptionVec_6,
      io_enq_req_0_bits_exceptionVec_5, io_enq_req_0_bits_exceptionVec_4,
      io_enq_req_0_bits_exceptionVec_3, io_enq_req_0_bits_exceptionVec_2,
      io_enq_req_0_bits_exceptionVec_1, io_enq_req_0_bits_exceptionVec_0}
    }),
    .io_enq_req_trigger ({
      io_enq_req_5_bits_trigger, io_enq_req_4_bits_trigger, io_enq_req_3_bits_trigger,
      io_enq_req_2_bits_trigger, io_enq_req_1_bits_trigger, io_enq_req_0_bits_trigger
    }),
    .io_enq_req_fuType ({
      io_enq_req_5_bits_fuType, io_enq_req_4_bits_fuType, io_enq_req_3_bits_fuType,
      io_enq_req_2_bits_fuType, io_enq_req_1_bits_fuType, io_enq_req_0_bits_fuType
    }),
    .io_enq_req_fuOpType ({
      io_enq_req_5_bits_fuOpType, io_enq_req_4_bits_fuOpType, io_enq_req_3_bits_fuOpType,
      io_enq_req_2_bits_fuOpType, io_enq_req_1_bits_fuOpType, io_enq_req_0_bits_fuOpType
    }),
    .io_enq_req_rfWen ({
      io_enq_req_5_bits_rfWen, io_enq_req_4_bits_rfWen, io_enq_req_3_bits_rfWen,
      io_enq_req_2_bits_rfWen, io_enq_req_1_bits_rfWen, io_enq_req_0_bits_rfWen
    }),
    .io_enq_req_flushPipe ({
      io_enq_req_5_bits_flushPipe, io_enq_req_4_bits_flushPipe, io_enq_req_3_bits_flushPipe,
      io_enq_req_2_bits_flushPipe, io_enq_req_1_bits_flushPipe, io_enq_req_0_bits_flushPipe
    }),
    .io_enq_req_vpu_nf ({
      io_enq_req_5_bits_vpu_nf, io_enq_req_4_bits_vpu_nf, io_enq_req_3_bits_vpu_nf,
      io_enq_req_2_bits_vpu_nf, io_enq_req_1_bits_vpu_nf, io_enq_req_0_bits_vpu_nf
    }),
    .io_enq_req_vpu_veew ({
      io_enq_req_5_bits_vpu_veew, io_enq_req_4_bits_vpu_veew, io_enq_req_3_bits_vpu_veew,
      io_enq_req_2_bits_vpu_veew, io_enq_req_1_bits_vpu_veew, io_enq_req_0_bits_vpu_veew
    }),
    .io_enq_req_uopIdx ({
      io_enq_req_5_bits_uopIdx, io_enq_req_4_bits_uopIdx, io_enq_req_3_bits_uopIdx,
      io_enq_req_2_bits_uopIdx, io_enq_req_1_bits_uopIdx, io_enq_req_0_bits_uopIdx
    }),
    .io_enq_req_lastUop ({
      io_enq_req_5_bits_lastUop, io_enq_req_4_bits_lastUop, io_enq_req_3_bits_lastUop,
      io_enq_req_2_bits_lastUop, io_enq_req_1_bits_lastUop, io_enq_req_0_bits_lastUop
    }),
    .io_enq_req_pdest ({
      io_enq_req_5_bits_pdest, io_enq_req_4_bits_pdest, io_enq_req_3_bits_pdest,
      io_enq_req_2_bits_pdest, io_enq_req_1_bits_pdest, io_enq_req_0_bits_pdest
    }),
    .io_enq_req_robIdx_flag ({
      io_enq_req_5_bits_robIdx_flag, io_enq_req_4_bits_robIdx_flag,
      io_enq_req_3_bits_robIdx_flag, io_enq_req_2_bits_robIdx_flag,
      io_enq_req_1_bits_robIdx_flag, io_enq_req_0_bits_robIdx_flag
    }),
    .io_enq_req_robIdx_value ({
      io_enq_req_5_bits_robIdx_value, io_enq_req_4_bits_robIdx_value,
      io_enq_req_3_bits_robIdx_value, io_enq_req_2_bits_robIdx_value,
      io_enq_req_1_bits_robIdx_value, io_enq_req_0_bits_robIdx_value
    }),
    .io_enq_req_debugInfo_renameTime ({
      io_enq_req_5_bits_debugInfo_renameTime, io_enq_req_4_bits_debugInfo_renameTime,
      io_enq_req_3_bits_debugInfo_renameTime, io_enq_req_2_bits_debugInfo_renameTime,
      io_enq_req_1_bits_debugInfo_renameTime, io_enq_req_0_bits_debugInfo_renameTime
    }),
    .io_enq_req_debug_seqNum_seqNum ({
      io_enq_req_5_bits_debug_seqNum_seqNum, io_enq_req_4_bits_debug_seqNum_seqNum,
      io_enq_req_3_bits_debug_seqNum_seqNum, io_enq_req_2_bits_debug_seqNum_seqNum,
      io_enq_req_1_bits_debug_seqNum_seqNum, io_enq_req_0_bits_debug_seqNum_seqNum
    }),
    .io_enq_req_debug_seqNum_uopIdx ({
      io_enq_req_5_bits_debug_seqNum_uopIdx, io_enq_req_4_bits_debug_seqNum_uopIdx,
      io_enq_req_3_bits_debug_seqNum_uopIdx, io_enq_req_2_bits_debug_seqNum_uopIdx,
      io_enq_req_1_bits_debug_seqNum_uopIdx, io_enq_req_0_bits_debug_seqNum_uopIdx
    }),
    .io_enq_req_numLsElem ({
      io_enq_req_5_bits_numLsElem, io_enq_req_4_bits_numLsElem, io_enq_req_3_bits_numLsElem,
      io_enq_req_2_bits_numLsElem, io_enq_req_1_bits_numLsElem, io_enq_req_0_bits_numLsElem
    }),
    .io_lcommit             (io_lcommit),
    .io_scommit             (io_scommit),
    .io_lqCancelCnt         (io_lqCancelCnt),
    .io_sqCancelCnt         (io_sqCancelCnt),
    .io_lqFreeCount         (io_lqFreeCount),
    .io_sqFreeCount         (io_sqFreeCount),
    .io_enq_resp_lqIdx_flag ({
      io_enq_resp_5_lqIdx_flag, io_enq_resp_4_lqIdx_flag, io_enq_resp_3_lqIdx_flag,
      io_enq_resp_2_lqIdx_flag, io_enq_resp_1_lqIdx_flag, io_enq_resp_0_lqIdx_flag
    }),
    .io_enq_resp_lqIdx_value ({
      io_enq_resp_5_lqIdx_value, io_enq_resp_4_lqIdx_value, io_enq_resp_3_lqIdx_value,
      io_enq_resp_2_lqIdx_value, io_enq_resp_1_lqIdx_value, io_enq_resp_0_lqIdx_value
    }),
    .io_enq_resp_sqIdx_flag ({
      io_enq_resp_5_sqIdx_flag, io_enq_resp_4_sqIdx_flag, io_enq_resp_3_sqIdx_flag,
      io_enq_resp_2_sqIdx_flag, io_enq_resp_1_sqIdx_flag, io_enq_resp_0_sqIdx_flag
    }),
    .io_enq_resp_sqIdx_value ({
      io_enq_resp_5_sqIdx_value, io_enq_resp_4_sqIdx_value, io_enq_resp_3_sqIdx_value,
      io_enq_resp_2_sqIdx_value, io_enq_resp_1_sqIdx_value, io_enq_resp_0_sqIdx_value
    }),
    .io_enqLsq_needAlloc ({
      io_enqLsq_needAlloc_5, io_enqLsq_needAlloc_4, io_enqLsq_needAlloc_3, io_enqLsq_needAlloc_2,
      io_enqLsq_needAlloc_1, io_enqLsq_needAlloc_0
    }),
    .io_enqLsq_req_valid ({
      io_enqLsq_req_5_valid, io_enqLsq_req_4_valid, io_enqLsq_req_3_valid, io_enqLsq_req_2_valid,
      io_enqLsq_req_1_valid, io_enqLsq_req_0_valid
    }),
    .io_enqLsq_req_exceptionVec ({
      {io_enqLsq_req_5_bits_exceptionVec_23, io_enqLsq_req_5_bits_exceptionVec_22,
      io_enqLsq_req_5_bits_exceptionVec_21, io_enqLsq_req_5_bits_exceptionVec_20,
      io_enqLsq_req_5_bits_exceptionVec_19, io_enqLsq_req_5_bits_exceptionVec_18,
      io_enqLsq_req_5_bits_exceptionVec_17, io_enqLsq_req_5_bits_exceptionVec_16,
      io_enqLsq_req_5_bits_exceptionVec_15, io_enqLsq_req_5_bits_exceptionVec_14,
      io_enqLsq_req_5_bits_exceptionVec_13, io_enqLsq_req_5_bits_exceptionVec_12,
      io_enqLsq_req_5_bits_exceptionVec_11, io_enqLsq_req_5_bits_exceptionVec_10,
      io_enqLsq_req_5_bits_exceptionVec_9, io_enqLsq_req_5_bits_exceptionVec_8,
      io_enqLsq_req_5_bits_exceptionVec_7, io_enqLsq_req_5_bits_exceptionVec_6,
      io_enqLsq_req_5_bits_exceptionVec_5, io_enqLsq_req_5_bits_exceptionVec_4,
      io_enqLsq_req_5_bits_exceptionVec_3, io_enqLsq_req_5_bits_exceptionVec_2,
      io_enqLsq_req_5_bits_exceptionVec_1, io_enqLsq_req_5_bits_exceptionVec_0},
      {io_enqLsq_req_4_bits_exceptionVec_23, io_enqLsq_req_4_bits_exceptionVec_22,
      io_enqLsq_req_4_bits_exceptionVec_21, io_enqLsq_req_4_bits_exceptionVec_20,
      io_enqLsq_req_4_bits_exceptionVec_19, io_enqLsq_req_4_bits_exceptionVec_18,
      io_enqLsq_req_4_bits_exceptionVec_17, io_enqLsq_req_4_bits_exceptionVec_16,
      io_enqLsq_req_4_bits_exceptionVec_15, io_enqLsq_req_4_bits_exceptionVec_14,
      io_enqLsq_req_4_bits_exceptionVec_13, io_enqLsq_req_4_bits_exceptionVec_12,
      io_enqLsq_req_4_bits_exceptionVec_11, io_enqLsq_req_4_bits_exceptionVec_10,
      io_enqLsq_req_4_bits_exceptionVec_9, io_enqLsq_req_4_bits_exceptionVec_8,
      io_enqLsq_req_4_bits_exceptionVec_7, io_enqLsq_req_4_bits_exceptionVec_6,
      io_enqLsq_req_4_bits_exceptionVec_5, io_enqLsq_req_4_bits_exceptionVec_4,
      io_enqLsq_req_4_bits_exceptionVec_3, io_enqLsq_req_4_bits_exceptionVec_2,
      io_enqLsq_req_4_bits_exceptionVec_1, io_enqLsq_req_4_bits_exceptionVec_0},
      {io_enqLsq_req_3_bits_exceptionVec_23, io_enqLsq_req_3_bits_exceptionVec_22,
      io_enqLsq_req_3_bits_exceptionVec_21, io_enqLsq_req_3_bits_exceptionVec_20,
      io_enqLsq_req_3_bits_exceptionVec_19, io_enqLsq_req_3_bits_exceptionVec_18,
      io_enqLsq_req_3_bits_exceptionVec_17, io_enqLsq_req_3_bits_exceptionVec_16,
      io_enqLsq_req_3_bits_exceptionVec_15, io_enqLsq_req_3_bits_exceptionVec_14,
      io_enqLsq_req_3_bits_exceptionVec_13, io_enqLsq_req_3_bits_exceptionVec_12,
      io_enqLsq_req_3_bits_exceptionVec_11, io_enqLsq_req_3_bits_exceptionVec_10,
      io_enqLsq_req_3_bits_exceptionVec_9, io_enqLsq_req_3_bits_exceptionVec_8,
      io_enqLsq_req_3_bits_exceptionVec_7, io_enqLsq_req_3_bits_exceptionVec_6,
      io_enqLsq_req_3_bits_exceptionVec_5, io_enqLsq_req_3_bits_exceptionVec_4,
      io_enqLsq_req_3_bits_exceptionVec_3, io_enqLsq_req_3_bits_exceptionVec_2,
      io_enqLsq_req_3_bits_exceptionVec_1, io_enqLsq_req_3_bits_exceptionVec_0},
      {io_enqLsq_req_2_bits_exceptionVec_23, io_enqLsq_req_2_bits_exceptionVec_22,
      io_enqLsq_req_2_bits_exceptionVec_21, io_enqLsq_req_2_bits_exceptionVec_20,
      io_enqLsq_req_2_bits_exceptionVec_19, io_enqLsq_req_2_bits_exceptionVec_18,
      io_enqLsq_req_2_bits_exceptionVec_17, io_enqLsq_req_2_bits_exceptionVec_16,
      io_enqLsq_req_2_bits_exceptionVec_15, io_enqLsq_req_2_bits_exceptionVec_14,
      io_enqLsq_req_2_bits_exceptionVec_13, io_enqLsq_req_2_bits_exceptionVec_12,
      io_enqLsq_req_2_bits_exceptionVec_11, io_enqLsq_req_2_bits_exceptionVec_10,
      io_enqLsq_req_2_bits_exceptionVec_9, io_enqLsq_req_2_bits_exceptionVec_8,
      io_enqLsq_req_2_bits_exceptionVec_7, io_enqLsq_req_2_bits_exceptionVec_6,
      io_enqLsq_req_2_bits_exceptionVec_5, io_enqLsq_req_2_bits_exceptionVec_4,
      io_enqLsq_req_2_bits_exceptionVec_3, io_enqLsq_req_2_bits_exceptionVec_2,
      io_enqLsq_req_2_bits_exceptionVec_1, io_enqLsq_req_2_bits_exceptionVec_0},
      {io_enqLsq_req_1_bits_exceptionVec_23, io_enqLsq_req_1_bits_exceptionVec_22,
      io_enqLsq_req_1_bits_exceptionVec_21, io_enqLsq_req_1_bits_exceptionVec_20,
      io_enqLsq_req_1_bits_exceptionVec_19, io_enqLsq_req_1_bits_exceptionVec_18,
      io_enqLsq_req_1_bits_exceptionVec_17, io_enqLsq_req_1_bits_exceptionVec_16,
      io_enqLsq_req_1_bits_exceptionVec_15, io_enqLsq_req_1_bits_exceptionVec_14,
      io_enqLsq_req_1_bits_exceptionVec_13, io_enqLsq_req_1_bits_exceptionVec_12,
      io_enqLsq_req_1_bits_exceptionVec_11, io_enqLsq_req_1_bits_exceptionVec_10,
      io_enqLsq_req_1_bits_exceptionVec_9, io_enqLsq_req_1_bits_exceptionVec_8,
      io_enqLsq_req_1_bits_exceptionVec_7, io_enqLsq_req_1_bits_exceptionVec_6,
      io_enqLsq_req_1_bits_exceptionVec_5, io_enqLsq_req_1_bits_exceptionVec_4,
      io_enqLsq_req_1_bits_exceptionVec_3, io_enqLsq_req_1_bits_exceptionVec_2,
      io_enqLsq_req_1_bits_exceptionVec_1, io_enqLsq_req_1_bits_exceptionVec_0},
      {io_enqLsq_req_0_bits_exceptionVec_23, io_enqLsq_req_0_bits_exceptionVec_22,
      io_enqLsq_req_0_bits_exceptionVec_21, io_enqLsq_req_0_bits_exceptionVec_20,
      io_enqLsq_req_0_bits_exceptionVec_19, io_enqLsq_req_0_bits_exceptionVec_18,
      io_enqLsq_req_0_bits_exceptionVec_17, io_enqLsq_req_0_bits_exceptionVec_16,
      io_enqLsq_req_0_bits_exceptionVec_15, io_enqLsq_req_0_bits_exceptionVec_14,
      io_enqLsq_req_0_bits_exceptionVec_13, io_enqLsq_req_0_bits_exceptionVec_12,
      io_enqLsq_req_0_bits_exceptionVec_11, io_enqLsq_req_0_bits_exceptionVec_10,
      io_enqLsq_req_0_bits_exceptionVec_9, io_enqLsq_req_0_bits_exceptionVec_8,
      io_enqLsq_req_0_bits_exceptionVec_7, io_enqLsq_req_0_bits_exceptionVec_6,
      io_enqLsq_req_0_bits_exceptionVec_5, io_enqLsq_req_0_bits_exceptionVec_4,
      io_enqLsq_req_0_bits_exceptionVec_3, io_enqLsq_req_0_bits_exceptionVec_2,
      io_enqLsq_req_0_bits_exceptionVec_1, io_enqLsq_req_0_bits_exceptionVec_0}
    }),
    .io_enqLsq_req_trigger ({
      io_enqLsq_req_5_bits_trigger, io_enqLsq_req_4_bits_trigger, io_enqLsq_req_3_bits_trigger,
      io_enqLsq_req_2_bits_trigger, io_enqLsq_req_1_bits_trigger, io_enqLsq_req_0_bits_trigger
    }),
    .io_enqLsq_req_fuType ({
      io_enqLsq_req_5_bits_fuType, io_enqLsq_req_4_bits_fuType, io_enqLsq_req_3_bits_fuType,
      io_enqLsq_req_2_bits_fuType, io_enqLsq_req_1_bits_fuType, io_enqLsq_req_0_bits_fuType
    }),
    .io_enqLsq_req_fuOpType ({
      io_enqLsq_req_5_bits_fuOpType, io_enqLsq_req_4_bits_fuOpType,
      io_enqLsq_req_3_bits_fuOpType, io_enqLsq_req_2_bits_fuOpType,
      io_enqLsq_req_1_bits_fuOpType, io_enqLsq_req_0_bits_fuOpType
    }),
    .io_enqLsq_req_rfWen ({
      io_enqLsq_req_5_bits_rfWen, io_enqLsq_req_4_bits_rfWen, io_enqLsq_req_3_bits_rfWen,
      io_enqLsq_req_2_bits_rfWen, io_enqLsq_req_1_bits_rfWen, io_enqLsq_req_0_bits_rfWen
    }),
    .io_enqLsq_req_flushPipe ({
      io_enqLsq_req_5_bits_flushPipe, io_enqLsq_req_4_bits_flushPipe,
      io_enqLsq_req_3_bits_flushPipe, io_enqLsq_req_2_bits_flushPipe,
      io_enqLsq_req_1_bits_flushPipe, io_enqLsq_req_0_bits_flushPipe
    }),
    .io_enqLsq_req_vpu_nf ({
      io_enqLsq_req_5_bits_vpu_nf, io_enqLsq_req_4_bits_vpu_nf, io_enqLsq_req_3_bits_vpu_nf,
      io_enqLsq_req_2_bits_vpu_nf, io_enqLsq_req_1_bits_vpu_nf, io_enqLsq_req_0_bits_vpu_nf
    }),
    .io_enqLsq_req_vpu_veew ({
      io_enqLsq_req_5_bits_vpu_veew, io_enqLsq_req_4_bits_vpu_veew,
      io_enqLsq_req_3_bits_vpu_veew, io_enqLsq_req_2_bits_vpu_veew,
      io_enqLsq_req_1_bits_vpu_veew, io_enqLsq_req_0_bits_vpu_veew
    }),
    .io_enqLsq_req_uopIdx ({
      io_enqLsq_req_5_bits_uopIdx, io_enqLsq_req_4_bits_uopIdx, io_enqLsq_req_3_bits_uopIdx,
      io_enqLsq_req_2_bits_uopIdx, io_enqLsq_req_1_bits_uopIdx, io_enqLsq_req_0_bits_uopIdx
    }),
    .io_enqLsq_req_lastUop ({
      io_enqLsq_req_5_bits_lastUop, io_enqLsq_req_4_bits_lastUop, io_enqLsq_req_3_bits_lastUop,
      io_enqLsq_req_2_bits_lastUop, io_enqLsq_req_1_bits_lastUop, io_enqLsq_req_0_bits_lastUop
    }),
    .io_enqLsq_req_pdest ({
      io_enqLsq_req_5_bits_pdest, io_enqLsq_req_4_bits_pdest, io_enqLsq_req_3_bits_pdest,
      io_enqLsq_req_2_bits_pdest, io_enqLsq_req_1_bits_pdest, io_enqLsq_req_0_bits_pdest
    }),
    .io_enqLsq_req_robIdx_flag ({
      io_enqLsq_req_5_bits_robIdx_flag, io_enqLsq_req_4_bits_robIdx_flag,
      io_enqLsq_req_3_bits_robIdx_flag, io_enqLsq_req_2_bits_robIdx_flag,
      io_enqLsq_req_1_bits_robIdx_flag, io_enqLsq_req_0_bits_robIdx_flag
    }),
    .io_enqLsq_req_robIdx_value ({
      io_enqLsq_req_5_bits_robIdx_value, io_enqLsq_req_4_bits_robIdx_value,
      io_enqLsq_req_3_bits_robIdx_value, io_enqLsq_req_2_bits_robIdx_value,
      io_enqLsq_req_1_bits_robIdx_value, io_enqLsq_req_0_bits_robIdx_value
    }),
    .io_enqLsq_req_debugInfo_renameTime ({
      io_enqLsq_req_5_bits_debugInfo_renameTime, io_enqLsq_req_4_bits_debugInfo_renameTime,
      io_enqLsq_req_3_bits_debugInfo_renameTime, io_enqLsq_req_2_bits_debugInfo_renameTime,
      io_enqLsq_req_1_bits_debugInfo_renameTime, io_enqLsq_req_0_bits_debugInfo_renameTime
    }),
    .io_enqLsq_req_debug_seqNum_seqNum ({
      io_enqLsq_req_5_bits_debug_seqNum_seqNum, io_enqLsq_req_4_bits_debug_seqNum_seqNum,
      io_enqLsq_req_3_bits_debug_seqNum_seqNum, io_enqLsq_req_2_bits_debug_seqNum_seqNum,
      io_enqLsq_req_1_bits_debug_seqNum_seqNum, io_enqLsq_req_0_bits_debug_seqNum_seqNum
    }),
    .io_enqLsq_req_debug_seqNum_uopIdx ({
      io_enqLsq_req_5_bits_debug_seqNum_uopIdx, io_enqLsq_req_4_bits_debug_seqNum_uopIdx,
      io_enqLsq_req_3_bits_debug_seqNum_uopIdx, io_enqLsq_req_2_bits_debug_seqNum_uopIdx,
      io_enqLsq_req_1_bits_debug_seqNum_uopIdx, io_enqLsq_req_0_bits_debug_seqNum_uopIdx
    }),
    .io_enqLsq_req_numLsElem ({
      io_enqLsq_req_5_bits_numLsElem, io_enqLsq_req_4_bits_numLsElem,
      io_enqLsq_req_3_bits_numLsElem, io_enqLsq_req_2_bits_numLsElem,
      io_enqLsq_req_1_bits_numLsElem, io_enqLsq_req_0_bits_numLsElem
    }),
    .io_enqLsq_req_debugInfo_eliminatedMove ({
      io_enqLsq_req_5_bits_debugInfo_eliminatedMove,
      io_enqLsq_req_4_bits_debugInfo_eliminatedMove,
      io_enqLsq_req_3_bits_debugInfo_eliminatedMove,
      io_enqLsq_req_2_bits_debugInfo_eliminatedMove,
      io_enqLsq_req_1_bits_debugInfo_eliminatedMove, io_enqLsq_req_0_bits_debugInfo_eliminatedMove
    }),
    .io_enqLsq_req_debugInfo_dispatchTime ({
      io_enqLsq_req_5_bits_debugInfo_dispatchTime, io_enqLsq_req_4_bits_debugInfo_dispatchTime,
      io_enqLsq_req_3_bits_debugInfo_dispatchTime, io_enqLsq_req_2_bits_debugInfo_dispatchTime,
      io_enqLsq_req_1_bits_debugInfo_dispatchTime, io_enqLsq_req_0_bits_debugInfo_dispatchTime
    }),
    .io_enqLsq_req_debugInfo_enqRsTime ({
      io_enqLsq_req_5_bits_debugInfo_enqRsTime, io_enqLsq_req_4_bits_debugInfo_enqRsTime,
      io_enqLsq_req_3_bits_debugInfo_enqRsTime, io_enqLsq_req_2_bits_debugInfo_enqRsTime,
      io_enqLsq_req_1_bits_debugInfo_enqRsTime, io_enqLsq_req_0_bits_debugInfo_enqRsTime
    }),
    .io_enqLsq_req_debugInfo_selectTime ({
      io_enqLsq_req_5_bits_debugInfo_selectTime, io_enqLsq_req_4_bits_debugInfo_selectTime,
      io_enqLsq_req_3_bits_debugInfo_selectTime, io_enqLsq_req_2_bits_debugInfo_selectTime,
      io_enqLsq_req_1_bits_debugInfo_selectTime, io_enqLsq_req_0_bits_debugInfo_selectTime
    }),
    .io_enqLsq_req_debugInfo_issueTime ({
      io_enqLsq_req_5_bits_debugInfo_issueTime, io_enqLsq_req_4_bits_debugInfo_issueTime,
      io_enqLsq_req_3_bits_debugInfo_issueTime, io_enqLsq_req_2_bits_debugInfo_issueTime,
      io_enqLsq_req_1_bits_debugInfo_issueTime, io_enqLsq_req_0_bits_debugInfo_issueTime
    }),
    .io_enqLsq_req_debugInfo_writebackTime ({
      io_enqLsq_req_5_bits_debugInfo_writebackTime, io_enqLsq_req_4_bits_debugInfo_writebackTime,
      io_enqLsq_req_3_bits_debugInfo_writebackTime, io_enqLsq_req_2_bits_debugInfo_writebackTime,
      io_enqLsq_req_1_bits_debugInfo_writebackTime, io_enqLsq_req_0_bits_debugInfo_writebackTime
    }),
    .io_enqLsq_req_debugInfo_runahead_checkpoint_id ({
      io_enqLsq_req_5_bits_debugInfo_runahead_checkpoint_id,
      io_enqLsq_req_4_bits_debugInfo_runahead_checkpoint_id,
      io_enqLsq_req_3_bits_debugInfo_runahead_checkpoint_id,
      io_enqLsq_req_2_bits_debugInfo_runahead_checkpoint_id,
      io_enqLsq_req_1_bits_debugInfo_runahead_checkpoint_id,
      io_enqLsq_req_0_bits_debugInfo_runahead_checkpoint_id
    }),
    .io_enqLsq_req_debugInfo_tlbFirstReqTime ({
      io_enqLsq_req_5_bits_debugInfo_tlbFirstReqTime,
      io_enqLsq_req_4_bits_debugInfo_tlbFirstReqTime,
      io_enqLsq_req_3_bits_debugInfo_tlbFirstReqTime,
      io_enqLsq_req_2_bits_debugInfo_tlbFirstReqTime,
      io_enqLsq_req_1_bits_debugInfo_tlbFirstReqTime,
      io_enqLsq_req_0_bits_debugInfo_tlbFirstReqTime
    }),
    .io_enqLsq_req_debugInfo_tlbRespTime ({
      io_enqLsq_req_5_bits_debugInfo_tlbRespTime, io_enqLsq_req_4_bits_debugInfo_tlbRespTime,
      io_enqLsq_req_3_bits_debugInfo_tlbRespTime, io_enqLsq_req_2_bits_debugInfo_tlbRespTime,
      io_enqLsq_req_1_bits_debugInfo_tlbRespTime, io_enqLsq_req_0_bits_debugInfo_tlbRespTime
    }),
    .io_enqLsq_req_lqIdx_flag ({
      io_enqLsq_req_5_bits_lqIdx_flag, io_enqLsq_req_4_bits_lqIdx_flag,
      io_enqLsq_req_3_bits_lqIdx_flag, io_enqLsq_req_2_bits_lqIdx_flag,
      io_enqLsq_req_1_bits_lqIdx_flag, io_enqLsq_req_0_bits_lqIdx_flag
    }),
    .io_enqLsq_req_lqIdx_value ({
      io_enqLsq_req_5_bits_lqIdx_value, io_enqLsq_req_4_bits_lqIdx_value,
      io_enqLsq_req_3_bits_lqIdx_value, io_enqLsq_req_2_bits_lqIdx_value,
      io_enqLsq_req_1_bits_lqIdx_value, io_enqLsq_req_0_bits_lqIdx_value
    }),
    .io_enqLsq_req_sqIdx_flag ({
      io_enqLsq_req_5_bits_sqIdx_flag, io_enqLsq_req_4_bits_sqIdx_flag,
      io_enqLsq_req_3_bits_sqIdx_flag, io_enqLsq_req_2_bits_sqIdx_flag,
      io_enqLsq_req_1_bits_sqIdx_flag, io_enqLsq_req_0_bits_sqIdx_flag
    }),
    .io_enqLsq_req_sqIdx_value ({
      io_enqLsq_req_5_bits_sqIdx_value, io_enqLsq_req_4_bits_sqIdx_value,
      io_enqLsq_req_3_bits_sqIdx_value, io_enqLsq_req_2_bits_sqIdx_value,
      io_enqLsq_req_1_bits_sqIdx_value, io_enqLsq_req_0_bits_sqIdx_value
    })
  );

endmodule
// END GENERATED
