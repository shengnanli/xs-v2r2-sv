// =============================================================================
// iq_ldu_pkg —— 香山 V2R2(昆明湖) 发射队列 Ldu(load 地址)变体 公共类型/参数
// -----------------------------------------------------------------------------
// 设计源: src/main/scala/xiangshan/backend/issue/{IssueQueue,Entries,EntryBundles,
//        EnqEntry,OthersEntry}.scala
//        其中 load 变体的派生类为 class IssueQueueMemAddrImp(IssueQueue.scala:1094),
//        其 isLdAddrIQ 分支(loadWakeUp / fromLoad 反馈)即本变体。
//
// Ldu = Load-Address 发射队列(LDU, FuType bit15)。它属于「访存类发射队列」, 与访存
// 样板 StaMou(store-address, 见 iq_stamou_pkg)同骨架(条目阵列 + 唤醒-选择 + 年龄
// 最老仲裁 + 一拍 deqDelay + 在队统计), 但 IO 最多(223 端口), 增量比 StaMou 大。
// 相对 StaMou 的访存增量(本文逐项, 代码里 [L1]..[L7] 标注):
//
//   [L1] load 唤醒输出(loadWakeUp → wakeupToIQ)(本变体最关键的 load 特征):
//        执行端 load 单元命中后, 通过 io_memIO_loadWakeUp 把「load 写回结果就绪」一拍
//        提前广播。IQ 把它寄存一拍后从 io_wakeupToIQ 引出, 供其它 IQ 提前唤醒等待
//        该 load 结果的 uop。pdest 扇出成 6 路 pdestCopy(物理上给 6 个读端口分别布线),
//        rfWen 扇出成 6 路 rfWenCopy, rcDest 直接取 io_replaceRCIdx(RegCache 回填索引)。
//        —— StaMou(store-addr)不写回寄存器, 故无此通路, 也无 MultiWakeupQueue。
//
//   [L2] FuBusyTable(功能单元忙表): load 要过忙表。canIssue 需先与忙表 mask 相与
//        再与 fuType[LDU=15] 相与才进年龄仲裁。忙表由 deq/og0/og1 响应写, 由各条目
//        fuType 读。—— StaMou 不过忙表(canIssue 直接进仲裁)。
//
//   [L3] fromLoad 反馈(按 lqIdx 匹配): load 发射后执行端给两路反馈
//        finalIssueResp(最终发射响应)/ memAddrIssueResp(访存地址发射响应), 各带
//        LqPtr(LoadQueue 指针)。条目阵列据 lqIdx 匹配把对应 issued 条目打回重发或确认。
//        —— StaMou 是单路 feedbackSlow 按 sqIdx 匹配, 且 IQ 核要把 hit 折算成 resp;
//           Ldu 这两路 IQ 核「直通」连进条目阵列(无 hit→resp 折算), 折算逻辑在条目内。
//
//   [L4] og0Resp/og1Resp 携带 fuType: 写忙表需要 fuType, 故 og0/og1 响应多带 35 位
//        fuType(StaMou 的 og 响应只有 valid / resp)。注意 fuType 只喂给忙表写, 条目
//        阵列仍只收 og 的 valid / resp。
//
//   [L5] load 专属 payload 透传: lqIdx(LqPtr)、preDecode.isRVC、ftqPtr.flag、fpWen,
//        以及条目内部从 imm 派生的 loadWaitBit/storeSetHit/waitForRobIdx/loadWaitStrict
//        (这 4 个不是 enq 输入, 由条目阵列内部算出, 仅 deqEntry 输出, IQ 核透传到 deqDelay)。
//        —— 无 sqIdx 折算外的额外处理; 无 isFirstIssue(StaMou 才有)。
//
//   [L6] imm 全宽 32 位透传(deqDelay.imm = {32'h0, imm}); 无 selImm/immType 输出
//        (StaMou 有 immType / selImm)。
//
//   [L7] fuType 仅用 LDU 位(bit15)。enq 只保留 fuType[15]; deqCanAccept = fuType[15];
//        deqDelay 输出的 35 位 fuType 由这一位拼回({19'h0, fuType15, 15'h0})。
//
//   关键维度参数(从 golden IssueQueueLdu.sv / EntriesLdu.sv 端口实测):
//     numEntries = 16, numEnq = 2, numSimp = 2, numComp = 12, numDeq = 1
//     numRegSrc  = 1, numWakeupFromIQ = 7, numWakeupFromWB = 4
//     LoadPipelineWidth = 3, LoadDependencyWidth = 2
//     imm 全宽 32 位, lqIdx 7 位, sqIdx 6 位, pdestCopy/rfWenCopy 各 6 路
//
// 本包定义条目/源状态 struct、离散量 enum、变体维度参数, 与 iq_stamou_pkg 同风格。
// =============================================================================
package iq_ldu_pkg;

  // ---------------------------------------------------------------------------
  // 1. 变体维度参数(全部来自 golden EntriesLdu.sv / IssueQueueLdu.sv 端口)
  // ---------------------------------------------------------------------------
  localparam int NUM_ENTRIES   = 16; // 条目总数(io_valid 宽度 16)
  localparam int NUM_ENQ       = 2;  // 入队端口数 / 入队条目数
  localparam int NUM_SIMP      = 2;  // 简单条目数(io_simpEntryOldestSel bits 宽 2)
  localparam int NUM_COMP      = 12; // 复杂条目数(io_compEntryOldestSel bits 宽 12)
  localparam int NUM_OTHERS    = NUM_ENTRIES - NUM_ENQ; // = 14 (simp 在前, comp 在后)
  localparam int NUM_DEQ       = 1;  // 发射端口数(单 LDU 流水)
  localparam int NUM_REGSRC    = 1;  // 每 uop 源寄存器数(load 地址仅基址 1 源)
  localparam int NUM_WK_IQ     = 7;  // IQ 唤醒源数
  localparam int NUM_WK_WB     = 4;  // WB 唤醒源数
  localparam int LDPW          = 3;  // LoadPipelineWidth
  localparam int LDW           = 2;  // LoadDependencyWidth
  localparam int ROB_PTR_W     = 8;  // RobPtr.value 宽度
  localparam int FTQ_PTR_W     = 6;  // FtqPtr.value 宽度
  localparam int LQ_PTR_W      = 7;  // LqPtr.value 宽度(LoadQueue 指针)
  localparam int SQ_PTR_W      = 6;  // SqPtr.value 宽度(StoreQueue 指针)
  localparam int PREG_W        = 8;  // 物理寄存器号宽度
  localparam int RC_IDX_W      = 5;  // RegCache 索引宽度
  localparam int IMM_W         = 32; // 立即数承载宽度(load imm 全宽 32 位)
  localparam int FU_NUM        = 35; // FuType 总位数(io_fuType 宽 35)
  localparam int FU_OP_W       = 9;  // fuOpType 宽度
  localparam int FTQ_OFF_W     = 4;  // ftqOffset 宽度
  localparam int NUM_PDEST_COPY = 6; // loadWakeUp pdest/rfWen 物理布线扇出份数

  // 本变体能承担的功能单元在 FuType one-hot 里的位号: LDU(load)= 15。
  //   golden enq 只保留 fuType_15; deqCanAccept = fuType[15]。
  localparam int FU_LDU = 15;

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

  // 发射响应类型 RespType(2 bit, 见 object RespType)。og1Resp 透传到忙表/条目。
  typedef enum logic [1:0] {
    RESP_BLOCK     = 2'b00,
    RESP_UNCERTAIN = 2'b01,
    RESP_SUCCESS   = 2'b11
  } resp_type_e;

  // ---------------------------------------------------------------------------
  // 3. 条目/源状态 struct(用于文档化条目布局, 黑盒内部为真实存储)
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
    logic [FU_NUM-1:0]            fu_type;    // FuType one-hot(仅 LDU bit15 有效)
    src_status_t [NUM_REGSRC-1:0] src;        // 各源状态(单源)
    logic                         issued;     // 已发射(等待 fromLoad 响应)
    logic [1:0]                   issue_timer;// 发射计时(选择 og/load 响应窗口)
    logic                         deq_port;   // 发射走哪个 deq 端口(本变体单端口)
  } status_t;

  // uop 负载 payload(见 class DynInst)。firtool 已把本变体不消费的字段裁掉。
  // load 特有: lqIdx(LqPtr)、preDecodeInfo.isRVC、ftqPtr.flag、fpWen。
  // 另: loadWaitBit/storeSetHit/waitForRobIdx/loadWaitStrict 由条目阵列内部从 imm
  //     派生(非 enq 输入), 仅 deqEntry 输出 → IQ 核透传到 deqDelay。
  typedef struct packed {
    logic                         pre_rvc;   // preDecodeInfo.isRVC
    logic                         ftq_flag;  // FtqPtr.flag
    logic [FTQ_PTR_W-1:0]         ftq_value;
    logic [FTQ_OFF_W-1:0]         ftq_offset;
    logic [FU_OP_W-1:0]           fu_op_type;
    logic                         rf_wen;
    logic                         fp_wen;
    logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] src_load_dep; // 入队原始 load 依赖
    logic [PREG_W-1:0]            pdest;
    logic                         lq_flag;   // LqPtr.flag
    logic [LQ_PTR_W-1:0]          lq_value;  // LqPtr.value
    logic                         sq_flag;   // SqPtr.flag
    logic [SQ_PTR_W-1:0]          sq_value;  // SqPtr.value
  } payload_t;

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

  // ---------------------------------------------------------------------------
  // 4. load 反馈 / load 唤醒 bundle —— 本变体关键差异
  // ---------------------------------------------------------------------------
  // [L3] fromLoad 反馈: 按 LqPtr 匹配。两路 finalIssueResp / memAddrIssueResp,
  //      条目阵列据此把对应 lqIdx 的 issued 条目打回重发(load replay)或确认。
  typedef struct packed {
    logic                valid;
    logic                lq_flag;   // LqPtr.flag
    logic [LQ_PTR_W-1:0] lq_value;  // LqPtr.value(在条目阵列里匹配回填)
  } from_load_resp_t;

  // [L1] load 唤醒 loadWakeUp(见 MemWakeUpBundle): load 命中提前广播写回就绪。
  typedef struct packed {
    logic                valid;
    logic                rf_wen;    // 写整数寄存器堆
    logic                fp_wen;    // 写浮点寄存器堆
    logic [PREG_W-1:0]   pdest;     // 写回目标物理寄存器(扇出成 pdestCopy)
  } load_wakeup_t;

endpackage : iq_ldu_pkg
