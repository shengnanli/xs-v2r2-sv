// =============================================================================
// iq_abjivvi_pkg —— 香山 V2R2(昆明湖) 发射队列 AluBrhJmpI2fVsetriwiVsetriwvfI2v 变体
//                   公共类型/参数(IQ 变体收官,golden Entries 35141 行,体量最大)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{Entries,EntryBundles,EnqEntry,
//        OthersEntry,IssueQueue}.scala
//
// 本变体 = 整数 + I2F(int→float)+ I2V(int→vec)+ Vset 混合 IQ。功能单元含
//   Alu / Brh / Jmp / I2F / Vsetriwi(vsetiwi)/ Vsetriwvf(vsetiwf)/ I2V(i2v)。
// 它与样板 AluMulBkuBrhJmp 同属「整数类、hasCompAndSimp、numEntries=24/numEnq=2/
// numDeq=2/numRegSrc=2、7 路 IQ 唤醒 + 4 路 WB 唤醒」骨架,差异(本包据此重写,严禁套壳):
//
//   1) 功能单元集合 / FuType 保留位不同(读 fuType 时只保留这几位):
//        AMBB 保留 {brh(1),jmp(0),alu(6),mul(7),bku(10)};
//        本变体保留 {jmp(0),brh(1),i2f(2),i2v(3),alu(6),vsetiwi(28),vsetiwf(29)}。
//      ★ FuType 位号取自 FuType.scala 的 addType 顺序:
//          jmp=0 brh=1 i2f=2 i2v=3 f2v=4 csr=5 alu=6 mul=7 ... vsetiwi=28 vsetiwf=29。
//   2) 发射端口分工(与 AMBB 完全不同,见 IQ 核 deqCanAcceptVec):
//        端口0 = {alu} = fuType{6}                       —— 纯 Alu,0 延迟,无 FU 忙表;
//        端口1 = {brh,jmp,i2f,i2v,vsetiwi,vsetiwf}       —— 其余全部,带 FU 忙表 + fp/vf/v0 写回忙表。
//   3) payload 字段:本变体在 AMBB 的「分支预测 preDecodeInfo.isRVC / pred_taken」之外,
//      还携带 fp/vec 写使能 fpWen/vecWen/v0Wen/vlWen 与浮点控制 fpu.{typeTagOut,wflags,typ,rm}
//      (送端口1 的 I2F/I2V/Vset)。这些都是纯透传(随条目寄存/转移搬运),不参与唤醒选择。
//      无 flushPipe(无 Fence)。
//   4) 唤醒/取消机制与 AMBB **完全一致**:同一颗 UIntCompressor_27_…(exuSources 编码)、
//      同一组 og0Cancel 命中位 {0,2,4,6}、同样 is0Lat 仅源 0/1、7 路 IQ + 4 路 WB 唤醒。
//      故条目级唤醒-选择逻辑直接 fork 样板,改的只是 FU 位 / payload。
//   5) 0 周期唤醒广播:本变体唤醒队列从端口0(Alu,恒 0 延迟)取数,且 golden
//      MultiWakeupQueue_2 不带 lat / og0Fail / is0Lat(Alu 无多周期),故唤醒广播口
//      io_wakeupToIQ_0 **无 is0Lat 输出**(与 AMBB 不同,AMBB 有 Mul/Bku 故带 is0Lat)。
//
// 本包定义:条目/源状态的 struct、各离散量的 enum、以及变体维度参数。
// =============================================================================
package iq_abjivvi_pkg;

  // ---------------------------------------------------------------------------
  // 1. 变体维度参数(全部来自 golden Entries/IssueQueue 端口)
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

  // 本变体能承担的功能单元在 FuType one-hot 里的位号(IQFuType.readFuType:其余位清零)。
  // golden enq/deqEntry 仅保留 fuType_{0,1,2,3,6,28,29}。
  localparam int FU_JMP   = 0;  // 跳转       (端口1)
  localparam int FU_BRH   = 1;  // 分支       (端口1)
  localparam int FU_I2F   = 2;  // int→float (端口1)
  localparam int FU_I2V   = 3;  // int→vec   (端口1)
  localparam int FU_ALU   = 6;  // 算术逻辑   (端口0)
  localparam int FU_VSETI = 28; // vsetiwi    (端口1)
  localparam int FU_VSETF = 29; // vsetiwf    (端口1)

  // 本变体相关 FuType 位的集合(用于按位保留 / 透传),长度 7。
  localparam int NUM_FU_BITS = 7;

  // og0Cancel / og1Cancel 按全局 EXU 号索引。本变体唤醒源 0..6 的取消拓扑与 AMBB 一致:
  // golden 只引用 og0Cancel 的 {0,2,4,6} 位 → 这 4 个是可被 og0 取消的源。
  localparam int NUM_EXU = 27; // backendParams.numExu

  // ---------------------------------------------------------------------------
  // 2. 离散量编码(与 AMBB 完全一致)
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
  // 3. 条目/源状态 struct(与 AMBB 同构)
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
    logic [FU_NUM-1:0]            fu_type;    // FuType one-hot(仅本变体相关位有效)
    src_status_t [NUM_REGSRC-1:0] src;
    logic                         blocked;    // 阻塞(本变体恒 0)
    logic                         issued;
    logic                         first_issue;
    logic [1:0]                   issue_timer;
    logic                         deq_port;
  } status_t;

  // uop 负载 payload。本变体在 AMBB(分支预测 isRVC / pred_taken)之外,额外携带
  // fp/vec 写使能 fpWen/vecWen/v0Wen/vlWen 与浮点控制 fpu.{typeTagOut,wflags,typ,rm}
  // (送端口1 的 I2F/I2V/Vset)。这些字段是纯透传(随条目寄存/转移搬运),不参与唤醒选择。
  // 无 flushPipe(无 Fence)。
  typedef struct packed {
    logic                         ftq_flag;
    logic [FTQ_PTR_W-1:0]         ftq_value;
    logic [FTQ_OFF_W-1:0]         ftq_offset;
    logic [FU_OP_W-1:0]           fu_op_type;
    logic                         rf_wen;
    logic                         fp_wen;           // fpWen(端口1 I2F/Vset)
    logic                         vec_wen;          // vecWen(端口1 I2V)
    logic                         v0_wen;           // v0Wen(端口1 Vset/I2V)
    logic                         vl_wen;           // vlWen(端口1 Vset)
    logic [1:0]                   fpu_type_tag_out; // fpu.typeTagOut
    logic                         fpu_wflags;       // fpu.wflags
    logic [1:0]                   fpu_typ;          // fpu.typ
    logic [2:0]                   fpu_rm;           // fpu.rm
    logic                         pre_decode_isrvc; // preDecodeInfo.isRVC(端口1 BrhJmp)
    logic                         pred_taken;       // pred.predTaken(端口1)
    logic [SEL_IMM_W-1:0]         sel_imm;
    logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] src_load_dep;
    logic [PREG_W-1:0]            pdest;
  } payload_t;

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

endpackage : iq_abjivvi_pkg
