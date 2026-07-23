// =============================================================================
//  StoreQueue —— store 顺序队列（可读重写核 xs_StoreQueue_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/mem/lsqueue/StoreQueue.scala
//  类型/常量/纯函数集中在 storequeue_pkg（见 storequeue_pkg.sv 文件头整体说明）。
//
//  本核维护 SQ_SIZE(=56) 个 store entry（环形队列），跟踪每条 store 从 dispatch
//  入队 → 地址/数据就绪 → ROB 提交 → 出队写回 Sbuffer 的全过程，并向 load 提供
//  store-to-load forward。数据存储用 5 个黑盒子模块（与 golden 共用），本核重写
//  **控制逻辑**：多根环形指针推进、每 entry 的状态位、enq/commit/deq 仲裁、
//  forward 命中掩码计算、mmio/nc/cmo 三套小状态机。
//
//  分节（对应 Scala 源的注释分节）：
//    §0  端口/参数/子模块例化
//    §1  指针与就绪计数（enq/rdata/deq/cmt + addr/dataReadyPtr）
//    §2  读数据指针 rdataPtr 推进 + 子模块读地址
//    §3  出队指针 deqPtr 推进
//    §4  dispatch 入队（按 numLsElem 给 entry 置位）
//    §5  addr/dataReadyPtr 扫描推进 + 就绪向量输出
//    §6  StoreUnit 写回地址（addrvalid/mmio/exception，写 paddr/vaddr 子模块）
//    §7  StoreData 写回数据（datavalid，写 data 子模块）+ 掩码写入
//    §8  load forward 查询（forwardMask/Data + addr/dataInvalid）
//    §9  mmio / CMO uncache store 状态机
//    §10 nc（non-cacheable）store 状态机
//    §11 uncache 请求仲裁 + mmioStout / cboZeroStout 写回 ROB
//    §12 ROB 提交（committed）+ cmtPtr 推进
//    §13 出队组 dataBuffer 入队 payload（含非对齐拆分）+ 写 Sbuffer
//    §14 向量异常标志 vecExceptionFlag + vecMbCommit
//    §15 redirect 取消 needCancel + enqPtr 回滚
//    §16 异常地址、force_write、sqEmpty、perf
//
//  ⚠ 端口集合/命名与 golden StoreQueue 完全一致（扁平 io_*，见 storequeue_ports.svh）。
//    本配置 golden 已裁剪 difftest / debug 寄存器 / 部分 enq.resp。可读性体现在
//    「内部」用 struct 数组 + genvar + enum + function 表达微架构。
// =============================================================================
module xs_StoreQueue_core
  import storequeue_pkg::*;
(
`include "storequeue_ports.svh"
);

  // ===========================================================================
  //  §0  每 entry 的状态位（散列 Vec(SQ_SIZE,Bool)，对应 Scala 的多个 RegInit）
  //      用 struct 数组聚合：一条 entry 的全部控制标志放一起，可读性远好于几十个
  //      独立标量 reg 阵列。
  // ===========================================================================
  typedef struct packed {
    logic allocated;     // entry 已分配（活跃）
    logic completed;     // 已完成出队动作（写 Sbuffer / mmio / nc 完成）
    logic addrvalid;     // 地址就绪
    logic datavalid;     // 数据就绪
    logic committed;     // ROB 已提交
    logic unaligned;     // 非对齐 store
    logic cross16Byte;   // 非对齐且跨 16B 边界（拆两拍）
    logic pending;       // mmio：等 ROB 头才发 uncache
    logic nc;            // non-cacheable
    logic mmio;          // mmio
    logic memBackTypeMM; // 访存后端类型（difftest 用，决定是否记 ncStore）
    logic prefetch;      // 提交到 Sbuffer 时触发预取
    logic isVec;         // 向量 store
    logic vecLastFlow;   // 向量 store 的最后一条流
    logic vecMbCommit;   // 向量 store 已从 merge buffer 提交到 ROB
    logic hasException;  // 有异常：应出队但不写 Sbuffer
    logic waitStoreS2;   // 等 store_s2 的 mmio/exception 结果
  } sq_entry_t;

  // entry 数组按 2^SQ_IDX_W=64 声明（实际只用 0..SQ_SIZE-1=55）：使任意 6 位下标都在
  // 界内，避免 Formality 的「下标可能越界」(FMR_ELAB-147) 把可读核误判为不可解释。
  sq_entry_t ent [1<<SQ_IDX_W];       // 64 槽（有效 56）
  // allvalid = addrvalid & datavalid（组合派生）
  logic [SQ_SIZE-1:0] allocated_v, addrvalid_v, datavalid_v, committed_v,
                      allvalid_v, mmio_v, nc_v, unaligned_v, isvec_v,
                      vecmbcommit_v, hasexc_v, prefetch_v;
  // uop 元数据：每 entry 只保留控制需要的字段（robIdx/uopIdx/sqIdx/fuType/fuOpType
  // /storeSet 等），其余 difftest/debug 字段 golden 已裁剪。
  typedef struct packed {
    logic                robIdx_flag;
    logic [ROB_IDX_W-1:0]robIdx_value;
    logic [UOP_IDX_W-1:0]uopIdx;
    logic                lastUop;
    logic [34:0]         fuType;
    logic [8:0]          fuOpType;
    logic                sqIdx_flag;
    logic [SQ_IDX_W-1:0] sqIdx_value;
    logic                flushPipe;
    logic [3:0]          trigger;
    logic [23:0]         exceptionVec;   // 异常向量（enq/storeAddrIn 写入；cbo.zero 出队时随 uop 上报）
    logic [63:0]         dbg_enqRsTime;
    logic [63:0]         dbg_selectTime;
    logic [63:0]         dbg_issueTime;
  } sq_uop_t;
  sq_uop_t uop [1<<SQ_IDX_W];         // 同 ent：按 64 槽声明，下标恒在界内

  // ---- 越界折叠读视图（FM 配平）：golden 对 Vec(56) 以 6 位下标做**纯值读取**时，
  //      firtool 生成 64 项读表、高 8 项(56..63)复制条目 0（越界回绕 vec[0]）。
  //      运行期下标的"纯值读"（喂输出/其它状态，不带 idx==j 写译码卫）一律走
  //      uopR/entR 视图，与 golden 位级一致；idx≥56 实际不可达，不改真实行为。
  //      per-entry 写译码/RMW（形如 ent[idx].x <= f(ent[idx])）不折叠——golden 同为
  //      per-entry 译码，等价性由 idx==j 卫自然保证。条目 56..63 因此变为只写不读，
  //      FM 两侧同被剪除。
  sq_uop_t   uopR [1<<SQ_IDX_W];
  sq_entry_t entR [1<<SQ_IDX_W];
  always_comb
    for (int k = 0; k < (1<<SQ_IDX_W); k++) begin
      uopR[k] = (k >= SQ_SIZE) ? uop[0] : uop[k];
      entR[k] = (k >= SQ_SIZE) ? ent[0] : ent[k];
    end

  genvar gi;
  generate
    for (gi = 0; gi < SQ_SIZE; gi++) begin : g_entvec
      assign allocated_v[gi]   = ent[gi].allocated;
      assign addrvalid_v[gi]   = ent[gi].addrvalid;
      assign datavalid_v[gi]   = ent[gi].datavalid;
      assign committed_v[gi]   = ent[gi].committed;
      assign allvalid_v[gi]    = ent[gi].addrvalid & ent[gi].datavalid;
      assign mmio_v[gi]        = ent[gi].mmio;
      assign nc_v[gi]          = ent[gi].nc;
      assign unaligned_v[gi]   = ent[gi].unaligned;
      assign isvec_v[gi]       = ent[gi].isVec;
      assign vecmbcommit_v[gi] = ent[gi].vecMbCommit;
      assign hasexc_v[gi]      = ent[gi].hasException;
      assign prefetch_v[gi]    = ent[gi].prefetch;
    end
  endgenerate

  // ===========================================================================
  //  §0b  子模块 readable 互联网（被 storequeue_subinst.svh 例化引用）
  // ===========================================================================
  // 读地址（rdataPtrExtNext 的两路）
  logic [SQ_IDX_W-1:0] sq_rdata_raddr [ENSB_W];
  // data 子模块读出 / 写入 / forward
  logic [VLEN_BYTES-1:0] sd_rdata_mask [ENSB_W];
  logic [VLEN-1:0]       sd_rdata_data [ENSB_W];
  logic                  sd_data_wen   [ST_PIPE_W];
  logic [VLEN-1:0]       sd_data_wdata [ST_PIPE_W];
  logic [FWD_W-1:0]      sd_need_forward_0_0, sd_need_forward_0_1,
                         sd_need_forward_1_0, sd_need_forward_1_1,
                         sd_need_forward_2_0, sd_need_forward_2_1;
  logic                  sd_forwardMask     [LD_PIPE_W][VLEN_BYTES];
  logic [7:0]            sd_forwardData     [LD_PIPE_W][VLEN_BYTES];
  // paddr/vaddr 子模块
  logic                  pa_wen [ST_PIPE_W];
  logic [PADDR_BITS-1:0] pa_rdata [ENSB_W];
  logic                  pa_rlineflag [ENSB_W];
  logic                  pa_forwardMmask [LD_PIPE_W][FWD_W];
  logic                  va_wen [ST_PIPE_W];
  logic [VADDR_BITS-1:0] va_rdata [ENSB_W];
  logic                  va_forwardMmask [LD_PIPE_W][FWD_W];
  // dataBuffer 入队 / 出队
  logic                  db_enq_ready [ENSB_W];
  logic                  db_enq_0_valid, db_enq_1_valid, db_enq_1_bits_sqNeedDeq;
  logic [PADDR_BITS-1:0] db_enq_0_bits_addr, db_enq_1_bits_addr;
  logic [VADDR_BITS-1:0] db_enq_0_bits_vaddr, db_enq_1_bits_vaddr;
  logic [VLEN-1:0]       db_enq_0_bits_data, db_enq_1_bits_data;
  logic [VLEN_BYTES-1:0] db_enq_0_bits_mask, db_enq_1_bits_mask;
  logic                  db_enq_0_bits_wline, db_enq_1_bits_wline;
  logic [SQ_IDX_W-1:0]   db_enq_0_bits_sqPtr_value, db_enq_1_bits_sqPtr_value;
  logic                  db_enq_0_bits_vecValid, db_enq_1_bits_vecValid;
  logic                  db_deq_0_valid, db_deq_1_valid;
  logic [PADDR_BITS-1:0] db_deq_0_bits_addr, db_deq_1_bits_addr;
  logic [VADDR_BITS-1:0] db_deq_0_bits_vaddr, db_deq_1_bits_vaddr;
  logic [VLEN-1:0]       db_deq_0_bits_data, db_deq_1_bits_data;
  logic [VLEN_BYTES-1:0] db_deq_0_bits_mask, db_deq_1_bits_mask;
  logic                  db_deq_0_bits_wline, db_deq_1_bits_wline;
  logic [SQ_IDX_W-1:0]   db_deq_0_bits_sqPtr_value, db_deq_1_bits_sqPtr_value;
  logic                  db_deq_0_bits_vecValid, db_deq_1_bits_vecValid;
  logic                  db_deq_0_bits_sqNeedDeq, db_deq_1_bits_sqNeedDeq;
  // exceptionBuffer 输入（7 路）：核内 readable 网（逐字段，与 subinst 引用名一致）
`include "storequeue_ebdecl.svh"
  logic [63:0] eb_exc_vaddr, eb_exc_gpaddr;
  logic        eb_exc_vaNeedExt, eb_exc_isHyper, eb_exc_isForVSnonLeafPTE;

  // 向量异常标志（在 §14 vec 里更新；此处前向声明，供 §13 deq 引用）
  logic                 vecExceptionFlag_valid;
  logic                 vecExceptionFlag_robIdx_flag;
  logic [ROB_IDX_W-1:0] vecExceptionFlag_robIdx_value;

  // 子模块例化（黑盒；端口连接表自动生成）
`include "storequeue_subinst.svh"

  // ===========================================================================
  //  §1  环形队列指针（enq/rdata/deq/cmt + addr/dataReadyPtr）
  //      初值：enqPtr/cmtPtr 各 0..N（多根并行指针，下标 i 即第 i 路）；rdata/deq 0/1。
  // ===========================================================================
  sqptr_t enqPtrExt [ENQ_W];     // 入队（6 根，第 0 根是主指针）
  sqptr_t rdataPtrExt [ENSB_W];  // 读数据（2 根）
  sqptr_t deqPtrExt [ENSB_W];    // 出队（2 根）
  sqptr_t cmtPtrExt [COMMIT_W];  // 提交（8 根）
  sqptr_t addrReadyPtrExt, dataReadyPtrExt;

  // 主指针的物理下标别名（频繁用）
  wire [SQ_IDX_W-1:0] enqPtr = enqPtrExt[0].value;
  wire [SQ_IDX_W-1:0] deqPtr = deqPtrExt[0].value;
  wire [SQ_IDX_W-1:0] cmtPtr = cmtPtrExt[0].value;
  wire [SQ_IDX_W-1:0] rdPtr  = rdataPtrExt[0].value;

  // 已用表项数 + 是否可入队。golden：allowEnqueue = validCount < 0x35(53)。
  // validCount 用 6 位模算术（与 golden distanceBetween 截断一致）。
  wire [SQ_IDX_W-1:0] validCount = sq_distance(enqPtrExt[0], deqPtrExt[0]);
  wire allowEnqueue = validCount < 6'h35;

  wire [SQ_SIZE-1:0] deqMask = uint_to_mask(deqPtr);
  wire [SQ_SIZE-1:0] enqMask = uint_to_mask(enqPtr);

  // scommit 打一拍（ROB 标量提交数）。golden scommit_next_r 异步复位到 0（holdUnless≡直存）。
  logic [3:0] scommit;
  always_ff @(posedge clock or posedge reset)
    if (reset) scommit <= 4'h0;
    else       scommit <= io_rob_scommit;

  // ===========================================================================
  //  §2  读数据指针 rdataPtr 推进
  //      rdataPtrExtNext 与 +1 项被预读出 data/addr 子模块（提前一拍）。每路就绪
  //      （dataBuffer 入队 fire 且需出队 / nc 已完成 / mmio 写回）则该路推进。
  // ===========================================================================
  logic [1:0] sqReadCnt;        // 本拍 rdataPtr 前进步数（0/1/2）
  logic [ENSB_W-1:0] readyReadGoVec;
  // dataBuffer enq fire = valid & ready
  wire db_enq0_fire = db_enq_0_valid & db_enq_ready[0];
  wire db_enq1_fire = db_enq_1_valid & db_enq_ready[1];
  // 口 0 的 sqNeedDeq 在 DatamoduleResultBuffer 内部恒为 1（无该端口）；逻辑上恒 deq。
  wire db_enq_0_bits_sqNeedDeq = 1'b1;
  // mmio/vecmmio 写回 fire（见 §11）
  logic mmioStout_fire, vecmmioStout_fire;

  always_comb begin
    // 第 0 路：出队需 deq 的 dataBuffer 项 / nc 完成 / mmio 写回
    readyReadGoVec[0] = (db_enq0_fire & db_enq_0_bits_sqNeedDeq)
                      | (entR[rdataPtrExt[0].value].allocated & entR[rdataPtrExt[0].value].completed
                         & entR[rdataPtrExt[0].value].nc)
                      | mmioStout_fire | vecmmioStout_fire;
    // 第 1 路（无 mmio）
    readyReadGoVec[1] = (db_enq1_fire & db_enq_1_bits_sqNeedDeq)
                      | (entR[rdataPtrExt[1].value].allocated & entR[rdataPtrExt[1].value].completed
                         & entR[rdataPtrExt[1].value].nc);
  end
  always_comb begin
    sqReadCnt = '0;
    if (readyReadGoVec[0])                    sqReadCnt = 2'd1;
    if (readyReadGoVec[0] & readyReadGoVec[1])sqReadCnt = 2'd2;
  end
  sqptr_t rdataPtrExtNext [ENSB_W];
  generate
    for (gi = 0; gi < ENSB_W; gi++) begin : g_rdnext
      assign rdataPtrExtNext[gi] = sqptr_add(rdataPtrExt[gi], {4'b0, sqReadCnt});
      // 子模块读地址 = rdataPtrExtNext.value
      assign sq_rdata_raddr[gi]  = rdataPtrExtNext[gi].value;
    end
  endgenerate

  // ===========================================================================
  //  §3  出队指针 deqPtr 推进：deqPtrExt(i) 的 entry 已 allocated&completed 则推进，
  //      并清该 entry 的 allocated/completed（真正离队）。
  // ===========================================================================
  logic [1:0] sqDeqCnt;
  logic [ENSB_W-1:0] readyDeqVec;
  always_comb begin
    for (int i = 0; i < ENSB_W; i++)
      readyDeqVec[i] = entR[deqPtrExt[i].value].allocated & entR[deqPtrExt[i].value].completed;
    sqDeqCnt = '0;
    if (readyDeqVec[0])                  sqDeqCnt = 2'd1;
    if (readyDeqVec[0] & readyDeqVec[1]) sqDeqCnt = 2'd2;
  end
  sqptr_t deqPtrExtNext [ENSB_W];
  generate
    for (gi = 0; gi < ENSB_W; gi++) begin : g_deqnext
      assign deqPtrExtNext[gi] = sqptr_add(deqPtrExt[gi], {4'b0, sqDeqCnt});
    end
  endgenerate
  // io_sqDeq = RegNext(sqDeqCnt)
  logic [1:0] sqDeq_q;
  always_ff @(posedge clock) sqDeq_q <= sqDeqCnt;
  assign io_sqDeq = sqDeq_q;

  // ===========================================================================
  //  §4  dispatch 入队
  //      io.enq.req(j) 携带 sqIdx 与 numLsElem（向量展开流数）。每个物理 entry i
  //      检查是否落在某请求的 [sqIdx, sqIdx+numLsElem) 区间（环形），命中则按优先级
  //      选最低 j 的请求写入该 entry 并置位（allocated 等）。
  // ===========================================================================
  assign io_enq_canAccept = allowEnqueue;

  // 各 enq 请求的有效 / 取消（被 redirect flush）/ 展开流数
  logic [ENQ_W-1:0] canEnqueue, enqCancel;
  logic [4:0]       vStoreFlow [ENQ_W];   // numLsElem
  logic [ENQ_W-1:0] enqCrossLoop;
  // enqLowBound 仅按 j(0..ENQ_W-1) 索引；enqUpBound 还被 selj 索引 → 按 8 槽声明。
  sqptr_t enqLowBound [ENQ_W], enqUpBound [8];

  // 把扁平 io_enq_req_j_* 收进局部（用 generate 取每路）
  // robIdx.needFlush(redirect): 被刷 = redirect.valid & (后于 robIdx 或同 robIdx 且 level)
  //  robIdx.needFlush(redirect)（与 golden 逐位一致）：
  //    isAfter   = differentFlag ^ (value > redirect.value)
  //    flushItself = level & (robIdx == redirect.robIdx)   // 含 flag 与 value
  //    needFlush = redirect.valid & (flushItself | isAfter)
  //  注意 differentFlag^compare 在「异圈且 value 相等」时为 1（golden 判其为 after），
  //  与简单的 value< 比较不同——这是 redirect 取消计数对齐的关键。
  //  纯函数：把 redirect 的 valid/flag/value/level 作为入参传入（不引用模块信号，
  //  以便 Formality 接受为可综合纯函数）。
  function automatic logic rob_need_flush(input logic rf, input logic [ROB_IDX_W-1:0] rv,
                                          input logic redV, input logic redF,
                                          input logic [ROB_IDX_W-1:0] redIdx, input logic redLvl);
    logic differentFlag, compare, isAfter, sameidx;
    differentFlag = rf ^ redF;
    compare       = rv > redIdx;
    isAfter       = differentFlag ^ compare;
    sameidx       = (rf == redF) & (rv == redIdx);
    return redV & ((redLvl & sameidx) | isAfter);
  endfunction
  // 便捷宏：以当前 io_brqRedirect_* 调用
  `define ROB_NEED_FLUSH(RF, RV) rob_need_flush(RF, RV, io_brqRedirect_valid, \
      io_brqRedirect_bits_robIdx_flag, io_brqRedirect_bits_robIdx_value, io_brqRedirect_bits_level)

  // 收集每路 enq 的字段（generate 内 assign）
  // 被 selj(3 位优先编码结果) 选取的 enq 元数据数组按 8 槽声明（2^3，实际只用 0..ENQ_W-1）：
  //   令 3 位下标恒在界内，避免 FMR_ELAB-147。en_valid/en_nelem 不被 selj 索引，按 ENQ_W 即可。
  localparam int ENQ_SLOTS = 8;
  logic                en_valid [ENQ_W];
  logic                en_robF  [ENQ_SLOTS];
  logic [ROB_IDX_W-1:0]en_robV  [ENQ_SLOTS];
  logic                en_sqF   [ENQ_SLOTS];
  logic [SQ_IDX_W-1:0] en_sqV   [ENQ_SLOTS];
  logic [4:0]          en_nelem [ENQ_W];
  logic [34:0]         en_fuType[ENQ_SLOTS];
  logic                en_lastUop[ENQ_SLOTS];
  logic [8:0]          en_fuOp  [ENQ_SLOTS];
  logic [UOP_IDX_W-1:0]en_uopIdx[ENQ_SLOTS];
  logic                en_flushP[ENQ_SLOTS];
  logic [3:0]          en_trig  [ENQ_SLOTS];
  logic [23:0]         en_excVec[ENQ_SLOTS];
  logic [63:0]         en_dbgEnq[ENQ_SLOTS], en_dbgSel[ENQ_SLOTS], en_dbgIss[ENQ_SLOTS];

  // 扁平 → 数组（按 j 展开；这些 io_enq_req_j_* 是 golden 端口名）
  `define SQ_ENQ_BIND(J) \
    assign en_valid[J] = io_enq_req_``J``_valid; \
    assign en_robF[J]  = io_enq_req_``J``_bits_robIdx_flag; \
    assign en_robV[J]  = io_enq_req_``J``_bits_robIdx_value; \
    assign en_sqF[J]   = io_enq_req_``J``_bits_sqIdx_flag; \
    assign en_sqV[J]   = io_enq_req_``J``_bits_sqIdx_value; \
    assign en_nelem[J] = io_enq_req_``J``_bits_numLsElem; \
    assign en_fuType[J]= io_enq_req_``J``_bits_fuType; \
    assign en_lastUop[J]= io_enq_req_``J``_bits_lastUop; \
    assign en_fuOp[J]  = io_enq_req_``J``_bits_fuOpType; \
    assign en_uopIdx[J]= io_enq_req_``J``_bits_uopIdx; \
    assign en_flushP[J]= io_enq_req_``J``_bits_flushPipe; \
    assign en_trig[J]  = io_enq_req_``J``_bits_trigger; \
    assign en_excVec[J]= {io_enq_req_``J``_bits_exceptionVec_23, io_enq_req_``J``_bits_exceptionVec_22, \
                          io_enq_req_``J``_bits_exceptionVec_21, io_enq_req_``J``_bits_exceptionVec_20, \
                          io_enq_req_``J``_bits_exceptionVec_19, io_enq_req_``J``_bits_exceptionVec_18, \
                          io_enq_req_``J``_bits_exceptionVec_17, io_enq_req_``J``_bits_exceptionVec_16, \
                          io_enq_req_``J``_bits_exceptionVec_15, io_enq_req_``J``_bits_exceptionVec_14, \
                          io_enq_req_``J``_bits_exceptionVec_13, io_enq_req_``J``_bits_exceptionVec_12, \
                          io_enq_req_``J``_bits_exceptionVec_11, io_enq_req_``J``_bits_exceptionVec_10, \
                          io_enq_req_``J``_bits_exceptionVec_9,  io_enq_req_``J``_bits_exceptionVec_8, \
                          io_enq_req_``J``_bits_exceptionVec_7,  io_enq_req_``J``_bits_exceptionVec_6, \
                          io_enq_req_``J``_bits_exceptionVec_5,  io_enq_req_``J``_bits_exceptionVec_4, \
                          io_enq_req_``J``_bits_exceptionVec_3,  io_enq_req_``J``_bits_exceptionVec_2, \
                          io_enq_req_``J``_bits_exceptionVec_1,  io_enq_req_``J``_bits_exceptionVec_0}; \
    assign en_dbgEnq[J]= io_enq_req_``J``_bits_debugInfo_enqRsTime; \
    assign en_dbgSel[J]= io_enq_req_``J``_bits_debugInfo_selectTime; \
    assign en_dbgIss[J]= io_enq_req_``J``_bits_debugInfo_issueTime;
  `SQ_ENQ_BIND(0) `SQ_ENQ_BIND(1) `SQ_ENQ_BIND(2)
  `SQ_ENQ_BIND(3) `SQ_ENQ_BIND(4) `SQ_ENQ_BIND(5)
  `undef SQ_ENQ_BIND

  // 槽 6/7 不可达（selj 只会落在 0..5），显式驱 0：FM 把无驱动网当自由输入
  // 会污染整个 enq 选择锥（uop/ent 写入全部误判失配），UT 下也消除 X 源。
  generate
    for (gi = 6; gi < ENQ_SLOTS; gi++) begin : g_enqpad
      assign en_robF[gi] = '0;  assign en_robV[gi] = '0;
      assign en_sqF[gi]  = '0;  assign en_sqV[gi]  = '0;
      assign en_fuType[gi] = '0; assign en_lastUop[gi] = '0;
      assign en_fuOp[gi] = '0;  assign en_uopIdx[gi] = '0;
      assign en_flushP[gi] = '0; assign en_trig[gi] = '0;
      assign en_excVec[gi] = '0;
      assign en_dbgEnq[gi] = '0; assign en_dbgSel[gi] = '0; assign en_dbgIss[gi] = '0;
      assign enqUpBound[gi] = '0;
    end
  endgenerate

  generate
    for (gi = 0; gi < ENQ_W; gi++) begin : g_enqb
      assign canEnqueue[gi]   = en_valid[gi];
      assign enqCancel[gi]    = `ROB_NEED_FLUSH(en_robF[gi], en_robV[gi]);
      assign vStoreFlow[gi]   = en_nelem[gi];
      assign enqLowBound[gi]  = '{flag:en_sqF[gi], value:en_sqV[gi]};
      assign enqUpBound[gi]   = sqptr_add('{flag:en_sqF[gi], value:en_sqV[gi]}, {2'b0, en_nelem[gi]});
      assign enqCrossLoop[gi] = enqLowBound[gi].flag != enqUpBound[gi].flag;
    end
  endgenerate

  // isVStore(fuType)：fuType[32] | fuType[34]（与 golden 里 SQDataModule wdata 判定一致）
  function automatic logic is_vstore(input logic [34:0] ft); return ft[32] | ft[34]; endfunction

  // FuType.isVStore 也用于 vecLastFlow 选择。每个 entry 的入队**组合**决定：
  //   entryEnq[i] = 该 entry 本拍被分配；entrySelUop[i] = 选中的 enq 请求（最低 j）。
  //   真正的寄存器写入在 body 里的统一 always_ff（与写回/提交/取消按优先级合并）。
  logic               entryEnq    [SQ_SIZE];
  sq_uop_t            entryEnqUop [SQ_SIZE];
  logic               entryEnqIsVec [SQ_SIZE];
  logic               entryEnqLastFlow [SQ_SIZE];
  always_comb begin
    for (int i = 0; i < SQ_SIZE; i++) begin
      logic [ENQ_W-1:0] hit;
      logic [2:0] selj;
      for (int j = 0; j < ENQ_W; j++) begin
        logic inbound;
        inbound = enqCrossLoop[j]
                  ? (enqLowBound[j].value <= i[SQ_IDX_W-1:0] || i[SQ_IDX_W-1:0] < enqUpBound[j].value)
                  : (enqLowBound[j].value <= i[SQ_IDX_W-1:0] && i[SQ_IDX_W-1:0] < enqUpBound[j].value);
        hit[j] = canEnqueue[j] & ~enqCancel[j] & inbound;
      end
      entryEnq[i] = |hit;
      selj = 3'd0;
      for (int j = ENQ_W-1; j >= 0; j--) if (hit[j]) selj = j[2:0];
      entryEnqIsVec[i]    = is_vstore(en_fuType[selj]);
      // vecLastFlow：该 entry 是该请求区间末尾（upBound==(i+1)%SQ_SIZE）则取 lastUop
      entryEnqLastFlow[i] = (enqUpBound[selj].value == ((i+1) % SQ_SIZE)) ? en_lastUop[selj] : 1'b0;
      entryEnqUop[i] = '0;
      entryEnqUop[i].robIdx_flag   = en_robF[selj];
      entryEnqUop[i].robIdx_value  = en_robV[selj];
      entryEnqUop[i].sqIdx_flag    = en_sqF[selj];
      entryEnqUop[i].sqIdx_value   = en_sqV[selj];
      entryEnqUop[i].lastUop       = en_lastUop[selj];
      entryEnqUop[i].fuType        = en_fuType[selj];
      entryEnqUop[i].fuOpType      = en_fuOp[selj];
      entryEnqUop[i].uopIdx        = en_uopIdx[selj];
      entryEnqUop[i].flushPipe     = en_flushP[selj];
      entryEnqUop[i].trigger       = en_trig[selj];
      entryEnqUop[i].exceptionVec  = en_excVec[selj];
      entryEnqUop[i].dbg_enqRsTime = en_dbgEnq[selj];
      entryEnqUop[i].dbg_selectTime= en_dbgSel[selj];
      entryEnqUop[i].dbg_issueTime = en_dbgIss[selj];
    end
  end

  // ===========================================================================
  //  §5  addr/dataReadyPtr 扫描推进（给后端 issue 看哪些 store 地址/数据已就绪）
  //      从当前指针向后看 ISSUE_STRIDE 个 entry，连续就绪则一次前移多格；遇到第一个
  //      未就绪即停。redirect 时回退到 cmt/deq。
  // ===========================================================================
  // addr/data_ready_at(p)：环形位置 p 的 entry 地址/数据是否就绪（allocated 且
  //   mmio|addr/datavalid|vecMbCommit，且 p 未追上 enqPtr）。内联在 always_comb 里
  //   （引用 ent/enqPtrExt 等模块信号，避免在 function 里引用非局部变量）。
  logic [ISSUE_STRIDE:0] addrReadyLookup, dataReadyLookup;
  always_comb begin
    addrReadyLookup[ISSUE_STRIDE] = 1'b1;  // 末位恒 1 保证 PriorityEncoder 有解
    dataReadyLookup[ISSUE_STRIDE] = 1'b1;
    for (int k = 0; k < ISSUE_STRIDE; k++) begin
      sqptr_t pa_ptr, pd_ptr;
      logic   a_rdy, d_rdy;
      pa_ptr = sqptr_add(addrReadyPtrExt, k[SQ_IDX_W:0]);
      pd_ptr = sqptr_add(dataReadyPtrExt, k[SQ_IDX_W:0]);
      a_rdy = entR[pa_ptr.value].allocated
              & (entR[pa_ptr.value].mmio | entR[pa_ptr.value].addrvalid | entR[pa_ptr.value].vecMbCommit)
              & (pa_ptr.value != enqPtrExt[0].value | pa_ptr.flag != enqPtrExt[0].flag);
      d_rdy = entR[pd_ptr.value].allocated
              & (entR[pd_ptr.value].mmio | entR[pd_ptr.value].datavalid | entR[pd_ptr.value].vecMbCommit)
              & (pd_ptr.value != enqPtrExt[0].value | pd_ptr.flag != enqPtrExt[0].flag);
      addrReadyLookup[k] = ~a_rdy;
      dataReadyLookup[k] = ~d_rdy;
    end
  end

  // 就绪向量（打一拍输出）：每 entry 是否地址/数据就绪
  logic [SQ_SIZE-1:0] stAddrReadyVecReg, stDataReadyVecReg;
  always_comb begin
    for (int i = 0; i < SQ_SIZE; i++) begin
      stAddrReadyVecReg[i] = ent[i].allocated
        & (ent[i].mmio | ent[i].addrvalid | (ent[i].isVec & ent[i].vecMbCommit));
      stDataReadyVecReg[i] = ent[i].allocated
        & (ent[i].mmio | ent[i].datavalid | (ent[i].isVec & ent[i].vecMbCommit));
    end
  end
  // 输出 stAddrReadyVec_i / stDataReadyVec_i（打一拍）
  logic [SQ_SIZE-1:0] stAddrReadyVec_q, stDataReadyVec_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin stAddrReadyVec_q <= '0; stDataReadyVec_q <= '0; end
    else begin stAddrReadyVec_q <= stAddrReadyVecReg; stDataReadyVec_q <= stDataReadyVecReg; end
  end

  // 把就绪向量摊到扁平输出端口
  `define SQ_RDYVEC_BIND(I) \
    assign io_stAddrReadyVec_``I = stAddrReadyVec_q[I]; \
    assign io_stDataReadyVec_``I = stDataReadyVec_q[I];
  // 56 路展开
  generate
    for (gi = 0; gi < SQ_SIZE; gi++) begin : g_rdyout end
  endgenerate
  // （扁平绑定见文件末尾 include 的 svh，避免此处 56 行手工展开）
`include "storequeue_rdyvec.svh"

  // 就绪指针寄存器更新
  wire [SQ_IDX_W:0] addrStep = prio_first_one(addrReadyLookup);
  wire [SQ_IDX_W:0] dataStep = prio_first_one(dataReadyLookup);
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      addrReadyPtrExt <= '0; dataReadyPtrExt <= '0;
    end else if (io_brqRedirect_valid) begin
      // redirect：回退到 cmt（若 cmt 后于 deq）否则 deqNext
      addrReadyPtrExt <= ptr_is_after(cmtPtrExt[0], deqPtrExt[0]) ? cmtPtrExt[0] : deqPtrExtNext[0];
      dataReadyPtrExt <= ptr_is_after(cmtPtrExt[0], deqPtrExt[0]) ? cmtPtrExt[0] : deqPtrExtNext[0];
    end else begin
      addrReadyPtrExt <= sqptr_add(addrReadyPtrExt, addrStep);
      dataReadyPtrExt <= sqptr_add(dataReadyPtrExt, dataStep);
    end
  end
  assign io_stAddrReadySqPtr_flag  = addrReadyPtrExt.flag;
  assign io_stAddrReadySqPtr_value = addrReadyPtrExt.value;
  assign io_stDataReadySqPtr_flag  = dataReadyPtrExt.flag;
  assign io_stDataReadySqPtr_value = dataReadyPtrExt.value;
  assign io_stIssuePtr_flag  = enqPtrExt[0].flag;
  assign io_stIssuePtr_value = enqPtrExt[0].value;

`include "storequeue_body.svh"

endmodule
