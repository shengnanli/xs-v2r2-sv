// =============================================================================
// iq_ffmac_pkg —— 香山 V2R2(昆明湖) 发射队列 FaluFmac 变体 公共类型/参数
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{Entries,EntryBundles,EnqEntry,
//        OthersEntry,IssueQueue}.scala
// golden 对照:IssueQueueFaluFmac.sv / EntriesFaluFmac.sv
//             叶子:EnqEntry_12.sv / OthersEntry_120.sv(simp) / OthersEntry_122.sv(comp)
//
// 发射队列(IssueQueue)是乱序后端的「调度心脏」。它在条目阵列里缓存等待发射的 uop,
// 监听写回(WB)与发射(IQ)两类唤醒总线:当某条 uop 的某个源操作数被唤醒(产出该
// 物理寄存器的执行单元广播了 pdest),就把该源置就绪;当一条 uop 的全部源都就绪、
// 且未发射未阻塞时,它「可发射(canIssue)」;再由年龄检测器(AgeDetector)在所有
// 可发射条目里选出**最老**的那条,经发射端口送往 DataPath/执行单元。
//
// 本变体 FaluFmac = 浮点 IQ,功能单元含 FALU(浮点加减/比较)+ FMAC(浮点乘加)。
// 关键参数(从 golden RTL 端口实测,见各 localparam 注释):
//   numEntries = 18, numEnq = 2, numSimp = 2, numComp = 14, numDeq = 1
//   numRegSrc  = 3 (浮点乘加最多三个源寄存器 rs1/rs2/rs3)
//   numWakeupFromIQ = 3, numWakeupFromWB = 6   (全部 fpWen-only,纯浮点唤醒)
//
// ★ 与 AluCsrFenceDiv 样板的关键差异(本变体大幅简化)★
//   * 唤醒看 **fpWen**(浮点写使能)+ srcType[1](isFp)+ pdest 匹配,而非整数的 rfWen/srcType[0]。
//   * **完全没有 loadDependency / load-to-cancel / srcLoadCancel 机制**——浮点 IQ 的唤醒
//     源不含推测 load,故 srcStatus 里无 ld_dep、条目逻辑里无 LoadShouldCancel。
//   * **没有 RegCache**(srcStatus 无 useRegCache / regCacheIdx)。
//   * **没有 imm 字段**(EntryBundle 不带 imm)。
//   * 单个 deq 端口(numDeq=1)→ 发射响应只有 og0Resp_0/og1Resp_0,无双端口 timer 选择。
//   * og0Cancel 仅作用于 **IQ 唤醒源 0**(唯一的 is0Lat 旁路源),命中位 og0Cancel[8]。
//   * EnqEntry 只有 **1 级 enqDelay**(enqDelayIn1),而非样板的 2 级(In1/In2)。
//
// 本包定义:条目/源状态的 struct、各离散量的 enum、以及变体维度参数。
// =============================================================================
package iq_ffmac_pkg;

  // ---------------------------------------------------------------------------
  // 1. 变体维度参数(全部来自 golden EntriesFaluFmac.sv / IssueQueueFaluFmac.sv 端口)
  // ---------------------------------------------------------------------------
  localparam int NUM_ENTRIES   = 18; // 条目总数(io_valid 宽度 18)
  localparam int NUM_ENQ       = 2;  // 入队端口数 / 入队条目数
  localparam int NUM_SIMP      = 2;  // 简单条目数(io_simpEntryEnqSelVec_0 宽 2)
  localparam int NUM_COMP      = 14; // 复杂条目数(io_compEntryEnqSelVec_0 宽 14)
  localparam int NUM_OTHERS    = NUM_ENTRIES - NUM_ENQ; // = 16 (simp 在前, comp 在后)
  localparam int NUM_DEQ       = 1;  // 发射端口数(单端口)
  localparam int NUM_REGSRC    = 3;  // 每 uop 源寄存器数(浮点乘加 rs1/rs2/rs3)
  localparam int NUM_WK_IQ     = 3;  // IQ 唤醒源数
  localparam int NUM_WK_WB     = 6;  // WB 唤醒源数
  localparam int ROB_PTR_W     = 8;  // RobPtr.value 宽度
  localparam int PREG_W        = 8;  // 物理寄存器号宽度
  localparam int FU_OP_W       = 9;  // fuOpType 宽度
  localparam int EXU_SRC_W     = 2;  // exuSources.value 宽度(本变体 3 个 IQ 源 → 2 位)

  // 浮点 fpu 控制 bundle 中本变体保留的字段(firtool 已裁掉其余)。
  localparam int FPU_FMT_W     = 2;  // fpu.fmt
  localparam int FPU_RM_W      = 3;  // fpu.rm

  // 本变体功能单元在 FuType one-hot 里的位号(IQFuType.readFuType:其余位清零)。
  // golden enq/输出仅保留 fuType_{11,12}。FuType 总位宽仍是 35(对外 io_fuType 宽 35)。
  localparam int FU_NUM   = 35; // FuType 总位数(deq 输出 io_..._fuType 宽 35)
  localparam int FU_FALU  = 11; // 浮点 ALU
  localparam int FU_FMAC  = 12; // 浮点乘加

  // FuType 紧凑存储:本变体只可能出现 {FU_FALU, FU_FMAC} 两位为 1,其余 33 位恒 0
  // (golden 已按变体剪枝)。因此条目里只存这些"保留位",对外仍复原成 35 位 one-hot。
  // FU_TYPE_KEEP_MASK 标出保留位;pack/unpack 在 35 位总线与紧凑存储间无损转换。
  localparam logic [FU_NUM-1:0] FU_TYPE_KEEP_MASK =
      (35'b1 << FU_FALU) | (35'b1 << FU_FMAC);
  localparam int FU_TYPE_KEEP_W = 2; // = $countones(FU_TYPE_KEEP_MASK)

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

  // og0Cancel / og1Cancel 是按全局 EXU 号(numExu)索引的取消向量。本变体仅 IQ 唤醒源 0
  // 是 0 周期延迟(is0Lat),其对应全局 EXU 号 = 8(命中位 og0Cancel[8])。
  localparam int NUM_EXU = 27; // backendParams.numExu

  // ---------------------------------------------------------------------------
  // 2. 离散量编码
  // ---------------------------------------------------------------------------
  // 源就绪状态 SrcState(1 bit, 见 object SrcState)
  typedef enum logic {
    SRC_BUSY = 1'b0, // 源未就绪,等待唤醒
    SRC_RDY  = 1'b1  // 源已就绪
  } src_state_e;

  // 数据来源 DataSource(4 bit, 见 object DataSource)。浮点 IQ 只用到其中几种,
  // 但保留完整编码以对齐 enq 透传值。
  typedef enum logic [3:0] {
    DS_ZERO     = 4'b0000, // 0 号物理寄存器,恒 0
    DS_FORWARD  = 4'b0001, // 旁路源本拍直出(commonOut 即时前递用)
    DS_BYPASS   = 4'b0010, // 旁路源寄存一拍(被 IQ 唤醒置位)
    DS_BYPASS2  = 4'b0011, // 二级旁路(本变体不用)
    DS_IMM      = 4'b0100, // 立即数(本变体不用)
    DS_V0       = 4'b0101, // 向量 v0(本变体不用)
    DS_REGCACHE = 4'b0110, // 寄存器缓存(本变体不用)
    DS_REG      = 4'b1000  // 物理寄存器堆
  } data_source_e;

  // 发射响应类型 RespType(2 bit, 见 object RespType)
  typedef enum logic [1:0] {
    RESP_BLOCK     = 2'b00,
    RESP_UNCERTAIN = 2'b01,
    RESP_SUCCESS   = 2'b11
  } resp_type_e;

  // ---------------------------------------------------------------------------
  // 3. 条目/源状态 struct
  // ---------------------------------------------------------------------------
  // 单个源操作数的状态 SrcStatus(浮点变体:无 loadDependency、无 RegCache)。
  typedef struct packed {
    logic [PREG_W-1:0]    psrc;     // 源物理寄存器号(用于 pdest 匹配唤醒)
    logic [3:0]           src_type; // SrcType(本变体看 bit1 = isFp)
    src_state_e           src_state;// 是否就绪
    data_source_e         data_src; // 数据来源
    logic [EXU_SRC_W-1:0] exu_src;  // 唤醒该源的旁路源在 IQ 唤醒源内的序号(ExuSource.value)
  } src_status_t;

  // 条目状态 Status(见 class Status)。浮点变体无 blocked(恒 0,vecMem 才用)的实际作用,
  // 但保留字段以对齐结构;无 first_issue 输出端口(golden 该变体未引,故省略)。
  typedef struct packed {
    logic                         rob_flag;   // RobPtr.flag(环形指针方向位)
    logic [ROB_PTR_W-1:0]         rob_value;  // RobPtr.value
    logic [FU_TYPE_KEEP_W-1:0]    fu_type;    // 紧凑存储保留位(见 FU_TYPE_KEEP_MASK / pack_fu_type)
    src_status_t [NUM_REGSRC-1:0] src;        // 各源状态
    logic                         issued;     // 已发射(等待响应)
    logic [1:0]                   issue_timer;// 发射计时(0→1→2→饱和3,/og 响应选择窗口)
  } status_t;

  // uop 负载 payload(见 class DynInst)。firtool 已把本变体不消费的字段裁掉,
  // 这里只保留 deqEntry 实际用到的字段(与 golden 端口逐一对应)。
  typedef struct packed {
    logic [FU_OP_W-1:0]   fu_op_type;
    logic                 rf_wen;
    logic                 fp_wen;
    logic                 fpu_wflags;
    logic [FPU_FMT_W-1:0] fpu_fmt;
    logic [FPU_RM_W-1:0]  fpu_rm;
    logic [PREG_W-1:0]    pdest;
  } payload_t;

  // 完整条目 EntryBundle(见 class EntryBundle)= 状态 + 负载(本变体无 imm)。
  typedef struct packed {
    status_t  status;
    payload_t payload;
  } entry_t;

  // 带 valid 的条目(ValidIO(EntryBundle))
  typedef struct packed {
    logic   valid;
    entry_t bits;
  } entry_valid_t;

  // 发射响应 EntryDeqRespBundle(本变体只用 robIdx/resp/fuType)。
  typedef struct packed {
    logic                 valid;
    logic                 rob_flag;
    logic [ROB_PTR_W-1:0] rob_value;
    resp_type_e           resp;
    logic [FU_NUM-1:0]    fu_type;
  } deq_resp_t;

  // 单个 IQ 唤醒源 bundle(浮点 IQ:仅 fpWen + pdest + is0Lat,无 loadDependency/rcDest)
  typedef struct packed {
    logic              fp_wen;
    logic [PREG_W-1:0] pdest;
    logic              is0lat;
  } wk_iq_t;

  // 单个 WB 唤醒源 bundle(仅 fpWen + pdest + valid)
  typedef struct packed {
    logic              valid;
    logic              fp_wen;
    logic [PREG_W-1:0] pdest;
  } wk_wb_t;

endpackage : iq_ffmac_pkg
