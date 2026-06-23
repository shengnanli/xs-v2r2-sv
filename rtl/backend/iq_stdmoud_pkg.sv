// =============================================================================
// iq_stdmoud_pkg —— 香山 V2R2(昆明湖) 发射队列 StdMoud(store-data)变体 公共类型/参数
// -----------------------------------------------------------------------------
// 设计源: src/main/scala/xiangshan/backend/issue/{IssueQueue,Entries,EntryBundles,
//        EnqEntry,OthersEntry}.scala
//        StdMoud 是「store-data / 杂项」发射队列, 派生自整数 IssueQueueImp(非访存子类),
//        负责把 store 的「数据源」操作数调度到 StdExeUnit。
//
// StdMoud 与整数样板 AluCsrFenceDiv / 访存样板 StaMou 同构(同样是 16 条目, 2 入队,
// 2 简单 +12 复杂, 单发射端口, 单源), 但它是「裁瘦的整数 IQ」, 关键差异:
//
//   1) 几乎无访存特征: 虽然条目携带 sqIdx(store 数据要写回 StoreQueue 的数据域),
//      但本变体 *没有* mem feedback(无 io_fromMem / io_memIO.feedbackSlow), 也 *没有*
//      isFirstIssue 输出。issued 条目仅靠 og0/og1Resp 普通响应推进, 与整数 IQ 一致。
//      —— 这是它与 StaMou(地址 IQ, 有 feedbackSlow 回灌)的根本区别。
//
//   2) deqDelay 输出极薄: 只有
//        rf_0_0_addr(源0物理寄存器号)/ srcType_0 / rcIdx_0 / immType? (无!) /
//        common.{fuType, fuOpType, robIdx, sqIdx, dataSources, exuSources, loadDependency}
//      —— *没有* imm / immType / pdest / rfWen / ftqIdx / ftqOffset / isFirstIssue。
//      因为 store-data 只把「数据」连同 robIdx/sqIdx 送出去, 不需要 PC/imm/写回目标。
//      注意它 *有* srcType_0 输出(StaMou 没有), 因为 StdExeUnit 要据此区分 int/fp 数据源。
//
//   3) 条目 payload 极薄: 只存 fuOpType / srcLoadDependency / sqIdx, 无 imm/ftq/pdest/
//      rfWen/selImm(对比 StaMou 还存这些)。enq 端这些字段直接不进条目。
//
//   4) FP 唤醒: 唤醒源里 WB_4..9 / IQDelayed_4..6 带 fpWen(StaMou 这些位置是 rfWen),
//      因为 store 的数据源可能来自浮点写回。共 10 路 WB + 7 路 IQ 唤醒(对比 StaMou 4+7)。
//      —— 唤醒匹配逻辑全在条目阵列(黑盒)内, IQ 核只透传, 故本核与 StaMou 核同形。
//
//   5) 无 validCntDeqVec 输出, 无 FuBusyTable, 无 wakeupToIQ(同 StaMou)。
//
//   6) 单源(numRegSrc = 1): store-data 只需 1 个数据源寄存器。
//   7) 单发射端口(numDeq = 1)。
//   8) 端口承担功能单元: 与 StaMou 一样 deqCanAccept = fuType[16] | fuType[17]
//      (StdMoud 在 backendParams 里复用 STA/MOU 的 FuType 槽位号编码 store-data uop)。
//
//   关键维度参数(从 golden IssueQueueStdMoud.sv / EntriesStdMoud.sv 端口实测):
//     numEntries = 16, numEnq = 2, numSimp = 2, numComp = 12, numDeq = 1
//     numRegSrc  = 1, numWakeupFromIQ = 7, numWakeupFromWB = 10
//     LoadPipelineWidth = 3, LoadDependencyWidth = 2
//
// 本包定义条目/源状态 struct、离散量 enum、变体维度参数, 与 iq_stamou_pkg 同风格。
// =============================================================================
package iq_stdmoud_pkg;

  // ---------------------------------------------------------------------------
  // 1. 变体维度参数(全部来自 golden EntriesStdMoud.sv / IssueQueueStdMoud.sv 端口)
  // ---------------------------------------------------------------------------
  localparam int NUM_ENTRIES   = 16; // 条目总数(io_valid 宽度 16)
  localparam int NUM_ENQ       = 2;  // 入队端口数 / 入队条目数
  localparam int NUM_SIMP      = 2;  // 简单条目数(io_simpEntryOldestSel bits 宽 2)
  localparam int NUM_COMP      = 12; // 复杂条目数(io_compEntryOldestSel bits 宽 12)
  localparam int NUM_OTHERS    = NUM_ENTRIES - NUM_ENQ; // = 14 (simp 在前, comp 在后)
  localparam int NUM_DEQ       = 1;  // 发射端口数(单 Std 流水)
  localparam int NUM_REGSRC    = 1;  // 每 uop 源寄存器数(store-data 仅数据 1 源)
  localparam int NUM_WK_IQ     = 7;  // IQ 唤醒源数
  localparam int NUM_WK_WB     = 10; // WB 唤醒源数(整数+浮点写回, 0..9)
  localparam int LDPW          = 3;  // LoadPipelineWidth
  localparam int LDW           = 2;  // LoadDependencyWidth
  localparam int ROB_PTR_W     = 8;  // RobPtr.value 宽度
  localparam int SQ_PTR_W      = 6;  // SqPtr.value 宽度(StoreQueue 指针)
  localparam int PREG_W        = 8;  // 物理寄存器号宽度
  localparam int RC_IDX_W      = 5;  // RegCache 索引宽度
  localparam int FU_NUM        = 35; // FuType 总位数(io_fuType 宽 35)
  localparam int FU_OP_W       = 9;  // fuOpType 宽度

  // 本变体能承担的功能单元在 FuType one-hot 里的位号。
  //   golden enq 只保留 fuType_{16,17}; deqCanAccept = fuType[16] | fuType[17]。
  //   (store-data uop 复用 STA/MOU 槽位号编码)。
  localparam int FU_BIT_LO = 16;
  localparam int FU_BIT_HI = 17;

  // og0Cancel 是按全局 EXU 号索引的取消向量。0 周期延迟源(is0Lat)在 og0Cancel 命中
  // 时取消。golden 只引用 og0Cancel{0,2,4,6}。
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
    DS_IMM      = 4'b0100, // 立即数 / 等 WB
    DS_V0       = 4'b0101, // 向量 v0
    DS_REGCACHE = 4'b0110, // 寄存器缓存
    DS_REG      = 4'b1000  // 物理寄存器堆
  } data_source_e;

  // 发射响应类型 RespType(2 bit, 见 object RespType)。本变体仅用普通 og 响应。
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

  // 条目状态 Status(见 class Status)。无 blocked/firstIssue 输出, 但内部仍有发射状态。
  typedef struct packed {
    logic                         rob_flag;   // RobPtr.flag(环形指针方向位)
    logic [ROB_PTR_W-1:0]         rob_value;  // RobPtr.value
    logic [FU_NUM-1:0]            fu_type;    // FuType one-hot(仅 16/17 位有效)
    src_status_t [NUM_REGSRC-1:0] src;        // 各源状态(单源)
    logic                         issued;     // 已发射(等待 og 响应)
    logic [1:0]                   issue_timer;// 发射计时(选择 og 响应窗口)
  } status_t;

  // uop 负载 payload(见 class DynInst)。store-data 极薄: 只留 fuOpType / load 依赖 / sqIdx。
  typedef struct packed {
    logic [FU_OP_W-1:0]           fu_op_type;
    logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] src_load_dep; // 入队原始 load 依赖
    logic                         sq_flag;   // SqPtr.flag(store-data 写回 StoreQueue 数据域)
    logic [SQ_PTR_W-1:0]          sq_value;  // SqPtr.value
  } payload_t;

  // 完整条目 EntryBundle(见 class EntryBundle)= 状态 + 负载(无 imm)。
  typedef struct packed {
    status_t   status;
    payload_t  payload;
  } entry_t;

  // 单个 IQ 唤醒源 bundle(rfWen/fpWen + pdest + loadDependency + is0Lat + rcDest)
  typedef struct packed {
    logic                     valid;
    logic                     wen;       // rfWen 或 fpWen(随源序号)
    logic [PREG_W-1:0]        pdest;
    logic [LDPW-1:0][LDW-1:0] ld_dep;
    logic                     is0lat;
    logic [RC_IDX_W-1:0]      rc_dest;
  } wk_iq_t;

  // 单个 WB 唤醒源 bundle(rfWen/fpWen + pdest)
  typedef struct packed {
    logic              valid;
    logic              wen;       // rfWen(0..3) 或 fpWen(4..9)
    logic [PREG_W-1:0] pdest;
  } wk_wb_t;

  // load 取消 bundle LoadCancelIO(每个 load 流水道两级取消)
  typedef struct packed {
    logic ld1_cancel;
    logic ld2_cancel;
  } ld_cancel_t;

endpackage : iq_stdmoud_pkg
