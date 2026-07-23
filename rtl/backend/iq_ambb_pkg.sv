// =============================================================================
// iq_ambb_pkg —— 香山 V2R2(昆明湖) 发射队列 AluMulBkuBrhJmp 变体 公共类型/参数
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{Entries,EntryBundles,EnqEntry,
//        OthersEntry,IssueQueue}.scala
//
// 本变体 = 整数定点 IQ,后端 4 个整数执行单元中的另一组,功能单元含
// ALU / Mul / Bku / Brh / Jmp(分支跳转 + 乘法 + 位操作)。它与样板 AluCsrFenceDiv
// 同属「整数类、hasCompAndSimp、numEntries=24/numEnq=2/numDeq=2/numRegSrc=2」骨架,
// 仅在以下维度上有增量(本包 + 上层据此重写,严禁套壳):
//
//   1) 功能单元集合不同 → FuType 保留位不同:
//        ACFD 保留 {5(alu),6(csr),8(fence),9(div)};
//        AMBB 保留 {0(brh),1(jmp),6(alu),7(mul),10(bku)}。
//      端口分工也随之变化(见 IssueQueue 核):
//        端口0 = {alu,mul,bku} = fuType{6,7,10};
//        端口1 = {brh,jmp}     = fuType{0,1}。
//   2) payload 字段不同:AMBB 携带分支预测信息 preDecodeInfo.isRVC / pred_taken
//      (送端口1 的 BrhJmp),不再携带 flushPipe(那是 Fence 专属,本变体无 Fence)。
//   3) 唤醒/取消机制与 ACFD **完全一致**:同一颗 UIntCompressor_27_...(exuSources 编码)、
//      同一组 og0Cancel 命中位 {0,2,4,6}、同样 7 路 IQ 唤醒 + 4 路 WB 唤醒(纯 rfWen)、
//      同样 is0Lat 仅源 0/1。故条目级唤醒-选择逻辑直接 fork 样板,改的只是 FU 位 / payload。
//   4) 0 周期唤醒(is0Lat):本变体 ALU/Bku/Brh/Jmp 为 0 延迟、Mul 为多周期。唤醒广播口
//      io_wakeupToIQ_0.bits.is0Lat = ~(deq.fuType[7] | deq.fuType[10])(即非 Mul/Bku 才 0 延迟)。
//      这是 IQ 顶层据唤醒队列出队 fuType 算的,条目级不涉及。
//   5) WbBusyTable(写回忙表):本变体两个发射端口都过整数写回忙表(intWbBusyTable),
//      端口0 还额外过功能单元忙表(fuBusyTable,Mul 多周期独占)。这是 IQ 顶层新增的
//      旁路/独占冲突筛选,作 golden 黑盒(FuBusyTableRead/Write)例化,核连线。
//
// 本包定义:条目/源状态的 struct、各离散量的 enum、以及变体维度参数。
// =============================================================================
package iq_ambb_pkg;

  // ---------------------------------------------------------------------------
  // 1. 变体维度参数(全部来自 golden EntriesAluMulBkuBrhJmp.sv / IssueQueueAluMulBkuBrhJmp.sv 端口)
  // ---------------------------------------------------------------------------
  localparam int NUM_ENTRIES   = 24; // 条目总数(io_valid 宽度 24)
  localparam int NUM_ENQ       = 2;  // 入队端口数 / 入队条目数
  localparam int NUM_SIMP      = 6;  // 简单条目数
  localparam int NUM_COMP      = 16; // 复杂条目数
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
  localparam int IMM_W         = 32; // 立即数承载宽度
  localparam int FU_NUM        = 35; // FuType 总位数(io_fuType 宽 35)
  localparam int FU_OP_W       = 9;  // fuOpType 宽度
  localparam int SEL_IMM_W     = 4;  // selImm 宽度
  localparam int FTQ_OFF_W     = 4;  // ftqOffset 宽度

  // 本变体能承担的功能单元在 FuType one-hot 里的位号(读 fuType 时只保留这几位,
  // 见 IQFuType.readFuType:其余位清零)。golden enq 仅保留 fuType_{0,1,6,7,10}。
  localparam int FU_BRH = 0;  // 分支(端口1)
  localparam int FU_JMP = 1;  // 跳转(端口1)
  localparam int FU_ALU = 6;  // 算术逻辑(端口0)
  localparam int FU_MUL = 7;  // 乘法(端口0,多周期,需 fuBusyTable)
  localparam int FU_BKU = 10; // 位操作(端口0)

  // ---------------------------------------------------------------------------
  // FuType 紧凑存储(与 iq_acfd_pkg 同型方法学,见其 pack/unpack 注释)
  //   本变体只可能出现 {FU_BRH, FU_JMP, FU_ALU, FU_MUL, FU_BKU} 五位为 1,其余 30 位恒 0
  //   (golden firtool 已按变体剪枝)。若条目寄存器存全 35 位则多出 30 位死位/条目,
  //   × 24 条目 = 720 个 impl-only 死位(FM 判 unread_impl → strict PARTIAL)。
  //   故条目里只存这些"保留位"(FU_TYPE_KEEP_W 宽),对外仍复原成 35 位 one-hot。
  //   pack/unpack 在 35 位总线与紧凑存储间无损转换,外部接口不变。
  // ---------------------------------------------------------------------------
  localparam logic [FU_NUM-1:0] FU_TYPE_KEEP_MASK =
      (35'b1 << FU_BRH) | (35'b1 << FU_JMP) | (35'b1 << FU_ALU)
    | (35'b1 << FU_MUL) | (35'b1 << FU_BKU);
  localparam int FU_TYPE_KEEP_W = 5; // = $countones(FU_TYPE_KEEP_MASK) = {0,1,6,7,10}

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

  // og0Cancel / og1Cancel 按全局 EXU 号索引。本变体唤醒源 0..6 的取消拓扑与 ACFD 一致:
  // golden 只引用 og0Cancel 的 {0,2,4,6} 位 → 这 4 个是可被 og0 取消的源。
  localparam int NUM_EXU = 27; // backendParams.numExu

  // ---------------------------------------------------------------------------
  // 2. 离散量编码(与 ACFD 完全一致)
  // ---------------------------------------------------------------------------
  // 源就绪状态 SrcState(1 bit)
  typedef enum logic {
    SRC_BUSY = 1'b0, // 源未就绪,等待唤醒
    SRC_RDY  = 1'b1  // 源已就绪
  } src_state_e;

  // 数据来源 DataSource(4 bit)
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

  // 发射响应类型 RespType(2 bit)。本变体 Entries 无 og1Resp.bits.resp 端口,
  // resp 完全由 issueTimer 决定:timer0→block, timer1→success, 其余→block。
  typedef enum logic [1:0] {
    RESP_BLOCK     = 2'b00,
    RESP_UNCERTAIN = 2'b01,
    RESP_SUCCESS   = 2'b11
  } resp_type_e;

  // ---------------------------------------------------------------------------
  // 3. 条目/源状态 struct(与 ACFD 同构)
  // ---------------------------------------------------------------------------
  // 单个源操作数的状态 SrcStatus
  typedef struct packed {
    logic [PREG_W-1:0]            psrc;     // 源物理寄存器号
    logic [3:0]                   src_type; // SrcType
    src_state_e                   src_state;// 是否就绪
    data_source_e                 data_src; // 数据来源
    logic [LDPW-1:0][LDW-1:0]     ld_dep;   // 各 load 流水道的依赖移位寄存器
    logic [2:0]                   exu_src;  // ExuSource.value
    logic                         use_rc;   // 该源是否取自 RegCache
    logic [RC_IDX_W-1:0]          rc_idx;   // RegCache 索引
  } src_status_t;

  // 条目状态 Status
  typedef struct packed {
    logic                         rob_flag;
    logic [ROB_PTR_W-1:0]         rob_value;
    logic [FU_TYPE_KEEP_W-1:0]    fu_type;    // 紧凑存储保留位(见 FU_TYPE_KEEP_MASK / pack_fu_type)
    src_status_t [NUM_REGSRC-1:0] src;
    logic                         issued;
    logic [1:0]                   issue_timer;
    logic                         deq_port;
  } status_t;
  // 注:blocked(本变体恒 0,vecMem 才用)与 first_issue(仅驱动 golden 未在本 wrapper
  //   暴露的 isFirstIssue 输出,自反馈死环)在本变体是 impl-only 死寄存器,golden firtool
  //   在扁平 Entries 顶层已消除;为对齐 golden(bug-for-bug 无多存)不进 status_t。

  // uop 负载 payload。本变体携带分支预测字段(preDecodeInfo.isRVC / pred_taken),
  // 不携带 flushPipe(无 Fence)。其余与 ACFD 一致。
  typedef struct packed {
    logic                         ftq_flag;
    logic [FTQ_PTR_W-1:0]         ftq_value;
    logic [FTQ_OFF_W-1:0]         ftq_offset;
    logic [FU_OP_W-1:0]           fu_op_type;
    logic                         rf_wen;
    logic                         pre_decode_isrvc; // preDecodeInfo.isRVC(端口1 BrhJmp)
    logic                         pred_taken;       // pred.predTaken(端口1)
    logic [SEL_IMM_W-1:0]         sel_imm;
    logic [PREG_W-1:0]            pdest;
  } payload_t;
  // 注:payload.srcLoadDependency(入队原始 load 依赖)只在入队拍喂 enqDelayIn1 流水,
  //   不是持久条目状态;golden 把 entryReg.payload.srcLoadDependency 链在扁平 Entries
  //   顶层整条消除(转移链无终端消费者)。故不入 payload_t,改由 Entries 顶层单独的
  //   enq_src_load_dep 输入直接喂 enqDelayIn1(见 EntriesAluMulBkuBrhJmp.sv 顶层)。

  // 入队原始 load 依赖(仅喂 enqDelayIn1 流水,非条目状态,单独走线不进 entry_t)
  typedef logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] enq_src_ld_t;

  // 完整条目 EntryBundle = 状态 + 立即数 + 负载
  typedef struct packed {
    status_t              status;
    logic [IMM_W-1:0]     imm;
    payload_t             payload;
  } entry_t;

  // 带 valid 的条目
  typedef struct packed {
    logic   valid;
    entry_t bits;
  } entry_valid_t;

  // 发射响应 EntryDeqRespBundle:本变体只用 valid/resp(robIdx/fuType 条目侧不消费)。
  typedef struct packed {
    logic                 valid;
    logic                 rob_flag;
    logic [ROB_PTR_W-1:0] rob_value;
    resp_type_e           resp;
    logic [FU_NUM-1:0]    fu_type;
  } deq_resp_t;

  // 单个 IQ 唤醒源 bundle(rfWen + pdest + loadDependency + is0Lat + rcDest)
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

  // load 取消 bundle(每个 load 流水道两级取消)
  typedef struct packed {
    logic ld1_cancel;
    logic ld2_cancel;
  } ld_cancel_t;

endpackage : iq_ambb_pkg
