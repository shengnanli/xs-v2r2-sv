// =============================================================================
// iq_stamou_pkg —— 香山 V2R2(昆明湖) 发射队列 StaMou(访存地址)变体 公共类型/参数
// -----------------------------------------------------------------------------
// 设计源: src/main/scala/xiangshan/backend/issue/{IssueQueue,Entries,EntryBundles,
//        EnqEntry,OthersEntry}.scala
//        其中访存变体的派生类为 class IssueQueueMemAddrImp(IssueQueue.scala:1094)。
//
// StaMou = Store-Address + Memory-Ordering(原子/fence)地址生成 IQ。它属于「访存类
// 发射队列」, 与整数 AluCsrFenceDiv(样板)同构, 但有访存特有差异:
//
//   1) mem feedback(本变体的关键访存特征):
//      执行端的「慢响应」memIO.feedbackIO(0).feedbackSlow 回灌进发射队列。STA 发射出去
//      做地址翻译/store-set 检查后, 若 hit=1 表示放行(成功), hit=0 表示该 store 需被
//      阻塞重发。IQ 核把 feedbackSlow 折算成条目阵列认识的 fromMem.slowResp:
//          slowResp.valid = feedbackSlow.valid
//          slowResp.resp  = feedbackSlow.hit ? success : block   (golden 写作 {2{hit}})
//          slowResp.sqIdx = feedbackSlow.sqIdx
//      条目阵列据此把对应(sqIdx 匹配)的 issued 条目「打回未发射」或「确认成功」。
//      —— 这是 IQ 核里真正从 Scala 意图重写的访存逻辑(见 IssueQueue.scala:1107)。
//
//   2) sqIdx: 访存指令携带 StoreQueue 指针(enq 输入 / deq 输出都带 sqIdx)。
//   3) isFirstIssue: deq 输出条目是否「首次发射」(取条目 firstIssue 状态), 供执行端
//      区分首发与重发(影响 store-set 训练)。
//   4) 单源(numRegSrc = 1): store 地址只需 1 个基址源寄存器(对比整数 IQ 的 2 源)。
//   5) 单发射端口(numDeq = 1): 一个 STA/MOU 流水。
//   6) 无 FuBusyTable: 访存地址 IQ 不过功能单元忙表, canIssue 直接进年龄仲裁。
//   7) 无 wakeupToIQ 输出: STA 不产生寄存器写回唤醒(loadWakeUp 仅 load 单元有),
//      故本变体不例化 MultiWakeupQueue。
//
//   关键维度参数(从 golden IssueQueueStaMou.sv / EntriesStaMou.sv 端口实测):
//     numEntries = 16, numEnq = 2, numSimp = 2, numComp = 12, numDeq = 1
//     numRegSrc  = 1, numWakeupFromIQ = 7, numWakeupFromWB = 4
//     LoadPipelineWidth = 3, LoadDependencyWidth = 2, imm 承载 12 bit
//
// 本包定义条目/源状态 struct、离散量 enum、变体维度参数, 与 iq_acfd_pkg 同风格。
// =============================================================================
package iq_stamou_pkg;

  // ---------------------------------------------------------------------------
  // 1. 变体维度参数(全部来自 golden EntriesStaMou.sv / IssueQueueStaMou.sv 端口)
  // ---------------------------------------------------------------------------
  localparam int NUM_ENTRIES   = 16; // 条目总数(io_valid 宽度 16)
  localparam int NUM_ENQ       = 2;  // 入队端口数 / 入队条目数
  localparam int NUM_SIMP      = 2;  // 简单条目数(io_simpEntryOldestSel bits 宽 2)
  localparam int NUM_COMP      = 12; // 复杂条目数(io_compEntryOldestSel bits 宽 12)
  localparam int NUM_OTHERS    = NUM_ENTRIES - NUM_ENQ; // = 14 (simp 在前, comp 在后)
  localparam int NUM_DEQ       = 1;  // 发射端口数(单 STA/MOU 流水)
  localparam int NUM_REGSRC    = 1;  // 每 uop 源寄存器数(store 地址仅基址 1 源)
  localparam int NUM_WK_IQ     = 7;  // IQ 唤醒源数
  localparam int NUM_WK_WB     = 4;  // WB 唤醒源数
  localparam int LDPW          = 3;  // LoadPipelineWidth
  localparam int LDW           = 2;  // LoadDependencyWidth
  localparam int ROB_PTR_W     = 8;  // RobPtr.value 宽度
  localparam int FTQ_PTR_W     = 6;  // FtqPtr.value 宽度
  localparam int SQ_PTR_W      = 6;  // SqPtr.value 宽度(StoreQueue 指针)
  localparam int PREG_W        = 8;  // 物理寄存器号宽度
  localparam int RC_IDX_W      = 5;  // RegCache 索引宽度
  localparam int IMM_W         = 12; // 立即数承载宽度(访存 imm 截到 12 bit)
  localparam int FU_NUM        = 35; // FuType 总位数(io_fuType 宽 35)
  localparam int FU_OP_W       = 9;  // fuOpType 宽度
  localparam int SEL_IMM_W     = 4;  // selImm 宽度
  localparam int FTQ_OFF_W     = 4;  // ftqOffset 宽度

  // 本变体能承担的功能单元在 FuType one-hot 里的位号。
  //   STA(store-address)= 16, MOU(memory-ordering, 原子/fence)= 17。
  // golden enq 只保留 fuType_{16,17}; deqCanAccept = fuType[16] | fuType[17]。
  localparam int FU_STA = 16;
  localparam int FU_MOU = 17;

  // og0Cancel / og1Cancel 是按全局 EXU 号索引的取消向量。访存地址 IQ 唤醒源 0..6 里
  // 0 周期延迟源(is0Lat)在 og0Cancel 命中时取消。golden 只引用 og0Cancel{0,2,4,6}。
  localparam int NUM_EXU = 27; // backendParams.numExu

  // ---------------------------------------------------------------------------
  // 2. 离散量编码
  // ---------------------------------------------------------------------------
  // 源就绪状态 SrcState(1 bit, 见 object SrcState)
  typedef enum logic {
    SRC_BUSY = 1'b0, // 源未就绪, 等待唤醒
    SRC_RDY  = 1'b1  // 源已就绪
  } src_state_e;

  // 数据来源 DataSource(4 bit, 见 object DataSource)。
  typedef enum logic [3:0] {
    DS_ZERO     = 4'b0000, // 整数 0 号物理寄存器, 恒 0
    DS_FORWARD  = 4'b0001, // 旁路源本拍直出
    DS_BYPASS   = 4'b0010, // 旁路源寄存一拍
    DS_BYPASS2  = 4'b0011, // 二级旁路(本变体不用)
    DS_IMM      = 4'b0100, // 立即数
    DS_V0       = 4'b0101, // 向量 v0(本变体不用)
    DS_REGCACHE = 4'b0110, // 寄存器缓存
    DS_REG      = 4'b1000  // 物理寄存器堆
  } data_source_e;

  // 发射响应类型 RespType(2 bit, 见 object RespType)。
  //   BLOCK   : 发射被阻塞(访存 feedbackSlow.hit=0 → 该 store 需重发, issued 打回 0)
  //   SUCCESS : 发射成功(访存 feedbackSlow.hit=1 → 条目可清空)
  // 注: golden 访存 fromMem.slowResp 把 hit 复制成 2 bit({2{hit}}): hit=1→2'b11(SUCCESS),
  //     hit=0→2'b00(BLOCK), 恰好对齐这里 SUCCESS/BLOCK 的编码。
  typedef enum logic [1:0] {
    RESP_BLOCK     = 2'b00,
    RESP_UNCERTAIN = 2'b01,
    RESP_SUCCESS   = 2'b11
  } resp_type_e;

  // ---------------------------------------------------------------------------
  // 3. 条目/源状态 struct
  // ---------------------------------------------------------------------------
  // 单个源操作数的状态 SrcStatus(见 class SrcStatus)。
  typedef struct packed {
    logic [PREG_W-1:0]            psrc;     // 源物理寄存器号(用于 pdest 匹配唤醒)
    logic [3:0]                   src_type; // SrcType(xp/fp/imm 的 one-hot 风格编码)
    src_state_e                   src_state;// 是否就绪
    data_source_e                 data_src; // 数据来源
    logic [LDPW-1:0][LDW-1:0]     ld_dep;   // 各 load 流水道的依赖移位寄存器
    logic [2:0]                   exu_src;  // 唤醒该源的旁路源 EXU 序号(ExuSource.value)
    logic                         use_rc;   // 该源是否取自 RegCache
    logic [RC_IDX_W-1:0]          rc_idx;   // RegCache 索引
  } src_status_t;

  // 条目状态 Status(见 class Status), 含基本/源/发射三类状态。
  typedef struct packed {
    logic                         rob_flag;   // RobPtr.flag(环形指针方向位)
    logic [ROB_PTR_W-1:0]         rob_value;  // RobPtr.value
    logic [FU_NUM-1:0]            fu_type;    // FuType one-hot(仅 STA/MOU 位有效)
    src_status_t [NUM_REGSRC-1:0] src;        // 各源状态(单源)
    logic                         blocked;    // 阻塞(本变体恒 0, vecMem 才用)
    logic                         issued;     // 已发射(等待 mem feedback 响应)
    logic                         first_issue;// 是否曾发射过(取反作 isFirstIssue 输出)
    logic [1:0]                   issue_timer;// 发射计时(选择 og/mem 响应窗口)
    logic                         deq_port;   // 发射走哪个 deq 端口(本变体单端口)
  } status_t;

  // uop 负载 payload(见 class DynInst)。firtool 已把本变体不消费的字段裁掉。
  // 访存特有: sqIdx(StoreQueue 指针)。无 flush_pipe(访存指令不走 flushPipe)。
  typedef struct packed {
    logic [FTQ_PTR_W-1:0]         ftq_value;
    logic [FTQ_OFF_W-1:0]         ftq_offset;
    logic [FU_OP_W-1:0]           fu_op_type;
    logic                         rf_wen;
    logic [SEL_IMM_W-1:0]         sel_imm;
    logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] src_load_dep; // 入队原始 load 依赖
    logic [PREG_W-1:0]            pdest;
    logic                         sq_flag;   // SqPtr.flag
    logic [SQ_PTR_W-1:0]          sq_value;  // SqPtr.value
  } payload_t;

  // 完整条目 EntryBundle(见 class EntryBundle)= 状态 + 立即数 + 负载。
  typedef struct packed {
    status_t              status;
    logic [IMM_W-1:0]     imm;
    payload_t             payload;
  } entry_t;

  // 单个 IQ 唤醒源 bundle(rfWen + pdest + loadDependency + is0Lat + rcDest)
  typedef struct packed {
    logic                     valid;
    logic                     rf_wen;
    logic [PREG_W-1:0]        pdest;
    logic [LDPW-1:0][LDW-1:0] ld_dep;
    logic                     is0lat;
    logic [RC_IDX_W-1:0]      rc_dest;
  } wk_iq_t;

  // 单个 WB 唤醒源 bundle(rfWen + pdest)
  typedef struct packed {
    logic              valid;
    logic              rf_wen;
    logic [PREG_W-1:0] pdest;
  } wk_wb_t;

  // load 取消 bundle LoadCancelIO(每个 load 流水道两级取消)
  typedef struct packed {
    logic ld1_cancel;
    logic ld2_cancel;
  } ld_cancel_t;

  // ---------------------------------------------------------------------------
  // 4. mem feedback bundle —— 访存慢响应(本变体关键差异)
  // ---------------------------------------------------------------------------
  // MemRSFeedbackIO.feedbackSlow(见 IssueQueue.scala:1073 / MemRSFeedbackIO)。
  // STA 发射后执行端把地址翻译/冲突检查结果慢回灌: hit 决定放行(成功)还是阻塞。
  typedef struct packed {
    logic                valid;
    logic                hit;       // 1=放行(成功), 0=阻塞(需重发)
    logic                sq_flag;   // SqPtr.flag
    logic [SQ_PTR_W-1:0] sq_value;  // SqPtr.value(用于在条目阵列里匹配回填)
  } mem_feedback_slow_t;

endpackage : iq_stamou_pkg
