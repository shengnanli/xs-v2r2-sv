// =============================================================================
// iq_ffcfmacfdiv_pkg —— 香山 V2R2(昆明湖) 发射队列 FaluFcvtF2vFmacFdiv 变体
//                       公共类型/参数
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{Entries,EntryBundles,EnqEntry,
//        OthersEntry,IssueQueue}.scala
// golden 对照:IssueQueueFaluFcvtF2vFmacFdiv.sv / EntriesFaluFcvtF2vFmacFdiv.sv
//             叶子:EnqEntry_8.sv / OthersEntry_88.sv(simp) / OthersEntry_90.sv(comp)
//
// 发射队列(IssueQueue)是乱序后端的「调度心脏」(总览见 iq_ffmac_pkg 头部)。
//
// 本变体 FaluFcvtF2vFmacFdiv = 浮点 IQ「全家桶」,功能单元含:
//   FALU(浮点加减/比较)+ FMAC(浮点乘加)+ FDIV/FSQRT(浮点除/开方)
//   + FCVT(浮点格式转换)+ F2V(浮点→向量,把浮点结果写进向量/v0 寄存器)。
// 它是 FaluFmacFdiv 变体的「近邻」:在其全栈基础上**多了 Fcvt 与 F2v 两类 FU**。
//
// 关键参数(从 golden RTL 端口实测,与 FaluFmacFdiv **完全相同**):
//   numEntries = 18, numEnq = 2, numSimp = 2, numComp = 14
//   numDeq     = 2   (Falu/Fmac/Fcvt/F2v 共用端口 0 + Fdiv 端口 1)
//   numRegSrc  = 3 (浮点乘加最多三个源寄存器 rs1/rs2/rs3)
//   numWakeupFromIQ = 3, numWakeupFromWB = 6   (全部 fpWen-only,纯浮点唤醒)
//
// ★ 与 FaluFmacFdiv 样板的关键差异(仅两处,全部是「数据携带」型,机制 100% 相同)★
//   1) **多保留 fuType 两位**:Fcvt(FU_FCVT=13)与 F2v(FU_F2V=4)。
//      FaluFmacFdiv 保留 {11,12,14};本变体保留 {4,11,12,13,14}。
//      (IQFuType.readFuType:这 5 位透传,其余位清零;FuType 总位宽仍 35。)
//   2) **payload 多两位写回使能**:vec_wen(写向量寄存器)+ v0_wen(写 v0 掩码寄存器)。
//      因为 F2v 会把浮点结果写进向量/v0 寄存器堆,下游需要这两个 wen。
//      它们在条目里纯透传(随 enq 寄存、随 transEntry 转移、由 deqEntry 输出),
//      **不参与唤醒匹配 / canIssue / 选择**(唤醒仍只看 fpWen + srcType[1]=isFp)。
//
// 其余(numDeq=2 的双端口 deqSelOH/og*Resp/oldestSel、status.deqPortIdx、
//   og1Resp_1_bits_resp 动态 resp、srcStatus 无 ld_dep/RegCache/imm、og0Cancel 仅 [8]、
//   is0Lat 仅 IQ 源 0、enqDelay 1 级、UIntCompressor bit{8,10,12} 拓扑、EnqPolicy_8
//   转移策略)与 FaluFmacFdiv 完全一致。
// =============================================================================
package iq_ffcfmacfdiv_pkg;

  // ---------------------------------------------------------------------------
  // 1. 变体维度参数(全部来自 golden EntriesFaluFcvtF2vFmacFdiv.sv 端口)
  // ---------------------------------------------------------------------------
  localparam int NUM_ENTRIES   = 18; // 条目总数(io_valid 宽度 18)
  localparam int NUM_ENQ       = 2;  // 入队端口数 / 入队条目数
  localparam int NUM_SIMP      = 2;  // 简单条目数(io_simpEntryEnqSelVec_0 宽 2)
  localparam int NUM_COMP      = 14; // 复杂条目数(io_compEntryEnqSelVec_0 宽 14)
  localparam int NUM_OTHERS    = NUM_ENTRIES - NUM_ENQ; // = 16 (simp 在前, comp 在后)
  localparam int NUM_DEQ       = 2;  // 发射端口数(双端口:Falu/Fmac/Fcvt/F2v + Fdiv)
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
  // ★ 与 FaluFmacFdiv 不同:多保留 FU_F2V(4)与 FU_FCVT(13)★
  //   位序见 src/main/scala/xiangshan/backend/fu/FuType.scala(addType 自增顺序):
  //   ... f2v=4 ... falu=11, fmac=12, fcvt=13, fDivSqrt=14 ...
  localparam int FU_NUM   = 35; // FuType 总位数(deq 输出 io_..._fuType 宽 35)
  localparam int FU_F2V   = 4;  // 浮点→向量(FaluFcvtF2vFmacFdiv 新增)
  localparam int FU_FALU  = 11; // 浮点 ALU
  localparam int FU_FMAC  = 12; // 浮点乘加
  localparam int FU_FCVT  = 13; // 浮点格式转换(FaluFcvtF2vFmacFdiv 新增)
  localparam int FU_FDIV  = 14; // 浮点除/开方

  // FuType 紧凑存储:本变体只保留 {FU_F2V, FU_FALU, FU_FMAC, FU_FCVT, FU_FDIV} 五位,其余
  // 30 位恒 0(golden 已按变体剪枝)。存储只留保留位,对外经 pack/unpack 复原 35 位 one-hot。
  localparam logic [FU_NUM-1:0] FU_TYPE_KEEP_MASK =
      (35'b1 << FU_F2V) | (35'b1 << FU_FALU) | (35'b1 << FU_FMAC)
    | (35'b1 << FU_FCVT) | (35'b1 << FU_FDIV);
  localparam int FU_TYPE_KEEP_W = 5; // = $countones(FU_TYPE_KEEP_MASK)

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
  // 2. 离散量编码(与 FaluFmacFdiv 完全一致)
  // ---------------------------------------------------------------------------
  // 源就绪状态 SrcState(1 bit, 见 object SrcState)
  typedef enum logic {
    SRC_BUSY = 1'b0, // 源未就绪,等待唤醒
    SRC_RDY  = 1'b1  // 源已就绪
  } src_state_e;

  // 数据来源 DataSource(4 bit, 见 object DataSource)。
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

  // 条目状态 Status(见 class Status)。
  //   deq_port_idx:该条目将在哪个发射端口出队(numDeq=2 才有意义,同 FaluFmacFdiv)。
  typedef struct packed {
    logic                         rob_flag;     // RobPtr.flag(环形指针方向位)
    logic [ROB_PTR_W-1:0]         rob_value;    // RobPtr.value
    logic [FU_TYPE_KEEP_W-1:0]    fu_type;      // 紧凑存储保留位(见 FU_TYPE_KEEP_MASK / pack_fu_type)
    src_status_t [NUM_REGSRC-1:0] src;          // 各源状态
    logic                         issued;       // 已发射(等待响应)
    logic [1:0]                   issue_timer;  // 发射计时(0→1→2→饱和3,/og 响应选择窗口)
    logic                         deq_port_idx; // 出队端口号(0=Falu/Fmac/Fcvt/F2v 口, 1=Fdiv 口)
  } status_t;

  // uop 负载 payload(见 class DynInst)。
  // ★ 本变体新增 vec_wen / v0_wen:F2v 把浮点结果写进向量/v0 寄存器堆所需的写使能 ★
  typedef struct packed {
    logic [FU_OP_W-1:0]   fu_op_type;
    logic                 rf_wen;     // 写整数寄存器堆使能
    logic                 fp_wen;     // 写浮点寄存器堆使能
    logic                 vec_wen;    // ★ 写向量寄存器堆使能(F2v)
    logic                 v0_wen;     // ★ 写 v0 掩码寄存器使能(F2v)
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

  // 单个 IQ 唤醒源 bundle(浮点 IQ:仅 fpWen + pdest + is0Lat)
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

endpackage : iq_ffcfmacfdiv_pkg
