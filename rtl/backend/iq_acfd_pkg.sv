// =============================================================================
// iq_acfd_pkg —— 香山 V2R2(昆明湖) 发射队列 AluCsrFenceDiv 变体 公共类型/参数
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{Entries,EntryBundles,EnqEntry,
//        OthersEntry,IssueQueue}.scala
//
// 发射队列(IssueQueue)是乱序后端的「调度心脏」。它在条目阵列里缓存等待发射的 uop,
// 监听写回(WB)与发射(IQ)两类唤醒总线:当某条 uop 的某个源操作数被唤醒(产出该
// 物理寄存器的执行单元广播了 pdest),就把该源置就绪;当一条 uop 的全部源都就绪、
// 且未发射未阻塞时,它「可发射(canIssue)」;再由年龄检测器(AgeDetector)在所有
// 可发射条目里选出**最老**的那条,经发射端口送往 DataPath/执行单元。
//
// 本变体 AluCsrFenceDiv = 整数定点 IQ,后端 4 个整数执行单元中的一组,功能单元含
// ALU / CSR / Fence / Div。其关键参数(从 golden RTL 端口实测,见各 localparam 注释):
//   numEntries = 24, numEnq = 2, numSimp = 6, numComp = 16, numDeq = 2
//   numRegSrc  = 2 (整数指令最多两个源寄存器,无向量/浮点源)
//   numWakeupFromIQ = 7, numWakeupFromWB = 4   (全部 rfWen-only,纯整数唤醒)
//   LoadPipelineWidth = 3, LoadDependencyWidth = 2
//
// 「整数 IQ」这一事实大幅简化了逻辑(相对 26417 行 golden 的通用展开):
//   * 唤醒只看 rfWen(整数写使能)+ pdest 匹配,无 fp/vec/v0/vl 唤醒;
//   * 无 numRegSrc==5 的 vl/v0 旁路、无 ignoreOldVd 向量尾处理(恒 false);
//   * inVfSchd / inMemSchd 均为否 → dataSources 用最简 MuxCase 分支;
//   * 7 个 IQ 唤醒源里只有源 0/1 是 0 周期延迟(is0Lat),需配合 og0Cancel 取消。
//
// 本包定义:条目/源状态的 struct、各离散量的 enum、以及变体维度参数。
// =============================================================================
package iq_acfd_pkg;

  // ---------------------------------------------------------------------------
  // 1. 变体维度参数(全部来自 golden EntriesAluCsrFenceDiv.sv / IssueQueueAluCsrFenceDiv.sv 端口)
  // ---------------------------------------------------------------------------
  localparam int NUM_ENTRIES   = 24; // 条目总数(io_valid 宽度 24)
  localparam int NUM_ENQ       = 2;  // 入队端口数 / 入队条目数
  localparam int NUM_SIMP      = 6;  // 简单条目数(io_simpEntryOldestSel bits 宽 6)
  localparam int NUM_COMP      = 16; // 复杂条目数(io_compEntryOldestSel bits 宽 16)
  localparam int NUM_OTHERS    = NUM_ENTRIES - NUM_ENQ; // = 22 (simp 在前, comp 在后)
  localparam int NUM_DEQ       = 2;  // 发射端口数
  localparam int NUM_REGSRC    = 2;  // 每 uop 源寄存器数
  localparam int NUM_WK_IQ     = 7;  // IQ 唤醒源数
  localparam int NUM_WK_WB     = 4;  // WB 唤醒源数
  localparam int LDPW          = 3;  // LoadPipelineWidth
  localparam int LDW           = 2;  // LoadDependencyWidth
  localparam int ROB_PTR_W     = 8;  // RobPtr.value 宽度
  localparam int FTQ_PTR_W     = 6;  // FtqPtr.value 宽度
  localparam int PREG_W        = 8;  // 物理寄存器号宽度
  localparam int RC_IDX_W      = 5;  // RegCache 索引宽度
  localparam int IMM_W         = 32; // 立即数承载宽度(deqImmTypesMaxLen)
  localparam int FU_NUM        = 35; // FuType 总位数(io_fuType 宽 35)
  localparam int FU_OP_W       = 9;  // fuOpType 宽度
  localparam int SEL_IMM_W     = 4;  // selImm 宽度
  localparam int FTQ_OFF_W     = 4;  // ftqOffset 宽度

  // 本变体能承担的功能单元在 FuType one-hot 里的位号(读 fuType 时只保留这几位,
  // 见 IQFuType.readFuType:其余位清零)。golden enq 仅保留 fuType_{5,6,8,9}。
  localparam int FU_ALU   = 5;
  localparam int FU_CSR   = 6;
  localparam int FU_FENCE = 8;
  localparam int FU_DIV   = 9;

  // ---------------------------------------------------------------------------
  // FuType 紧凑存储(可复用 Entries 家族方法学,见 iq_ffmac_pkg 同型)
  //   本变体只可能出现 {FU_ALU, FU_CSR, FU_FENCE, FU_DIV} 四位为 1,其余 31 位恒 0
  //   (golden firtool 已按变体剪枝)。若条目寄存器存全 35 位则多出 31 位死位/条目,
  //   × 24 条目 = 744 个 impl-only 死位(FM 判 unread_impl → strict PARTIAL)。
  //   故条目里只存这些"保留位"(FU_TYPE_KEEP_W 宽),对外仍复原成 35 位 one-hot。
  //   pack/unpack 在 35 位总线与紧凑存储间无损转换,外部接口不变。
  // ---------------------------------------------------------------------------
  localparam logic [FU_NUM-1:0] FU_TYPE_KEEP_MASK =
      (35'b1 << FU_ALU) | (35'b1 << FU_CSR) | (35'b1 << FU_FENCE) | (35'b1 << FU_DIV);
  localparam int FU_TYPE_KEEP_W = 4; // = $countones(FU_TYPE_KEEP_MASK)

  // 35 位 one-hot → 紧凑保留位(按 mask 位号升序装填到槽 0,1,…)
  function automatic logic [FU_TYPE_KEEP_W-1:0] pack_fu_type(input logic [FU_NUM-1:0] full);
    int unsigned slot;
    pack_fu_type = '0;
    slot = 0;
    for (int b = 0; b < FU_NUM; b++)
      if (FU_TYPE_KEEP_MASK[b]) begin
        pack_fu_type[slot] = full[b];
        slot++;
      end
  endfunction

  // 紧凑保留位 → 35 位 one-hot(未保留位复原为 0),pack 的逆运算
  function automatic logic [FU_NUM-1:0] unpack_fu_type(input logic [FU_TYPE_KEEP_W-1:0] kept);
    int unsigned slot;
    unpack_fu_type = '0;
    slot = 0;
    for (int b = 0; b < FU_NUM; b++)
      if (FU_TYPE_KEEP_MASK[b]) begin
        unpack_fu_type[b] = kept[slot];
        slot++;
      end
  endfunction

  // og0Cancel / og1Cancel 是按全局 EXU 号(numExu)索引的取消向量。本变体唤醒源
  // 0..6 的全局 EXU 号见下;只有 0 周期延迟的源(is0Lat)在 og0Cancel 命中时取消。
  // golden 只保留了 og0Cancel 的第 {0,2,4,6} 位被引用 → 这 4 个是可被 og0 取消的源。
  localparam int NUM_EXU = 27; // backendParams.numExu

  // ---------------------------------------------------------------------------
  // 2. 离散量编码
  // ---------------------------------------------------------------------------
  // 源就绪状态 SrcState(1 bit, 见 object SrcState)
  typedef enum logic {
    SRC_BUSY = 1'b0, // 源未就绪,等待唤醒
    SRC_RDY  = 1'b1  // 源已就绪
  } src_state_e;

  // 数据来源 DataSource(4 bit, 见 object DataSource)。整数 IQ 只用到其中几种,
  // 但保留完整编码以对齐 enq 透传值。
  typedef enum logic [3:0] {
    DS_ZERO     = 4'b0000, // 整数 0 号物理寄存器,恒 0
    DS_FORWARD  = 4'b0001, // 旁路源本拍直出
    DS_BYPASS   = 4'b0010, // 旁路源寄存一拍
    DS_BYPASS2  = 4'b0011, // 二级旁路(本变体不用)
    DS_IMM      = 4'b0100, // 立即数
    DS_V0       = 4'b0101, // 向量 v0(本变体不用)
    DS_REGCACHE = 4'b0110, // 寄存器缓存
    DS_REG      = 4'b1000  // 物理寄存器堆
  } data_source_e;

  // 发射响应类型 RespType(2 bit, 见 object RespType)
  //   BLOCK     : 发射被阻塞(需重发,issued 置回 0)
  //   UNCERTAIN : 结果未定
  //   SUCCESS   : 发射成功(条目可清空)
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
    logic [3:0]                   src_type; // SrcType(xp/fp/vp/v0/imm 的 one-hot 风格编码)
    src_state_e                   src_state;// 是否就绪
    data_source_e                 data_src; // 数据来源
    logic [LDPW-1:0][LDW-1:0]     ld_dep;   // 各 load 流水道的依赖移位寄存器
    logic [2:0]                   exu_src;  // 唤醒该源的旁路源 EXU 在唤醒源组内的序号(ExuSource.value, log2(7+1)=3b)
    logic                         use_rc;   // 该源是否取自 RegCache
    logic [RC_IDX_W-1:0]          rc_idx;   // RegCache 索引
  } src_status_t;

  // 条目状态 Status(见 class Status),含基本/源/发射三类状态。
  typedef struct packed {
    logic                         rob_flag;   // RobPtr.flag(环形指针方向位)
    logic [ROB_PTR_W-1:0]         rob_value;  // RobPtr.value
    logic [FU_TYPE_KEEP_W-1:0]    fu_type;    // 紧凑存储保留位(见 FU_TYPE_KEEP_MASK / pack_fu_type)
    src_status_t [NUM_REGSRC-1:0] src;        // 各源状态
    logic                         issued;     // 已发射(等待响应)
    logic [1:0]                   issue_timer;// 发射计时(0→1→2→饱和3,/og 响应选择窗口)
    logic                         deq_port;   // 发射走哪个 deq 端口(回填响应用)
  } status_t;
  // 注:blocked(本变体恒 0,vecMem 才用)与 first_issue(仅驱动 golden 未在本 wrapper
  //   暴露的 isFirstIssue 输出,自反馈死环)在本变体是 impl-only 死寄存器,golden firtool
  //   在扁平 Entries 顶层已消除;为对齐 golden(bug-for-bug 无多存)不进 status_t。

  // uop 负载 payload(见 class DynInst)。firtool 已把本变体不消费的字段裁掉,
  // 这里只保留 deqEntry/统计实际用到的字段(与 golden 端口逐一对应)。
  typedef struct packed {
    logic                         ftq_flag;
    logic [FTQ_PTR_W-1:0]         ftq_value;
    logic [FTQ_OFF_W-1:0]         ftq_offset;
    logic [FU_OP_W-1:0]           fu_op_type;
    logic                         rf_wen;
    logic                         flush_pipe;
    logic [SEL_IMM_W-1:0]         sel_imm;
    logic [PREG_W-1:0]            pdest;
  } payload_t;
  // 注:payload.srcLoadDependency(入队原始 load 依赖)只在入队拍喂 enqDelayIn1 流水,
  //   不是持久条目状态;golden 把 entryReg.payload.srcLoadDependency 链在扁平 Entries
  //   顶层整条消除(转移链无终端消费者)。故不入 payload_t,改由 Entries 顶层单独的
  //   enq_src_load_dep 输入直接喂 enqDelayIn1(见 EntriesAluCsrFenceDiv.sv 顶层)。

  // 入队原始 load 依赖(仅喂 enqDelayIn1 流水,非条目状态,单独走线不进 entry_t)
  typedef logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] enq_src_ld_t;

  // 完整条目 EntryBundle(见 class EntryBundle)= 状态 + 立即数 + 负载。
  typedef struct packed {
    status_t              status;
    logic [IMM_W-1:0]     imm;
    payload_t             payload;
  } entry_t;

  // 带 valid 的条目(ValidIO(EntryBundle))
  typedef struct packed {
    logic   valid;
    entry_t bits;
  } entry_valid_t;

  // 发射响应 EntryDeqRespBundle(见 class EntryDeqRespBundle):本变体只用 robIdx/resp/fuType。
  typedef struct packed {
    logic                 valid;
    logic                 rob_flag;
    logic [ROB_PTR_W-1:0] rob_value;
    resp_type_e           resp;
    logic [FU_NUM-1:0]    fu_type;
  } deq_resp_t;

  // 单个 IQ 唤醒源 bundle(整数 IQ:仅 rfWen + pdest + loadDependency + is0Lat + rcDest)
  typedef struct packed {
    logic                     valid;
    logic                     rf_wen;
    logic [PREG_W-1:0]        pdest;
    logic [LDPW-1:0][LDW-1:0] ld_dep;
    logic                     is0lat;
    logic [RC_IDX_W-1:0]      rc_dest;
  } wk_iq_t;

  // 单个 WB 唤醒源 bundle(仅 rfWen + pdest)
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

endpackage : iq_acfd_pkg
