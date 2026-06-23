// =============================================================================
// iq_vlduvstuseg_pkg —— 香山 V2R2(昆明湖) 发射队列 VlduVstuVseglduVsegstu 变体
//                       公共类型/参数(向量 load/store + 段 load/store)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{Entries,EntryBundles,EnqEntry,
//        OthersEntry,IssueQueue}.scala
//        其中向量访存变体 = class IssueQueueVecMemImp(IssueQueue.scala),向量调度
//        机制继承 VfDiv 一族,mem feedback 机制继承 MemAddr 一族。
// golden 对照:IssueQueueVlduVstuVseglduVsegstu.sv / EntriesVlduVstuVseglduVsegstu.sv
//             叶子:EnqEntryVecMem(入队) / OthersEntryVecMem(simp, 转移源)
//                  / OthersEntryVecMem(comp, 终端) / EnqPolicy_14(14位转移策略)
//
// ─────────────────────────────────────────────────────────────────────────────
// ★ 与「向量访存样板 VlduVstu」的差异(本变体唯一差异)★
// ─────────────────────────────────────────────────────────────────────────────
// (S1) ★ fuType one-hot 多 2 位:VSEGLDU=33(段 load)/ VSEGSTU=34(段 store)★。
//      —— 这是 VlduVstu(只有 VLDU=31 / VSTU=32)与本变体的全部差异。
//      源 FuType.scala 里 vldu=31, vstu=32, vsegldu=33, vsegstu=34 顺序 addType。
//      段访存(unit-stride/strided/indexed segment)与普通向量访存共用同一条发射
//      流水、同一套 vecMem 反馈机制(sqIdx/lqIdx/numLsElem 均已在 VlduVstu 里);
//      段数 nf 早已在 vpu_t.nf。因此在 IQ 调度层面,段访存与普通向量访存的唯一可见
//      差异,就是这两位额外的 FU one-hot 标识 —— 它们在条目里随 status 透传
//      (入队→转移→deqEntry 输出),行为与 VLDU/VSTU 位逐字一致。
//      —— golden 实测:fuType_33/34 在 Entries 的 oldest-select mux 与 31/32 完全平行。
//
// 以下为继承自 VlduVstu 样板的机制说明(本变体保留不变):
// ★★ 这是「向量/段 load/store」发射队列 —— 向量调度 + 访存反馈的融合变体 ★★
// 它把两套样板的机制揉到一起:
//   · 向量侧(参 VfdivVidiv):numRegSrc=5、ignoreOldVd、唤醒 WB 分 vec/v0/vl 三组、
//     srcType bit2=isVecVf / bit3=isV0、payload 为 vpu_* 一族。
//   · 访存侧(参 StaMou/Ldu):条目带 vecMem(sqIdx/lqIdx/numLsElem)、blocked、
//     mem 反馈按 {sqIdx,lqIdx} 匹配把已发射条目打回重发或确认成功。
//
// ─────────────────────────────────────────────────────────────────────────────
// ★ 与「向量样板 VfdivVidiv」的差异(融合访存而新增)★
// ─────────────────────────────────────────────────────────────────────────────
// (V1) numEntries 10→16(2 enq + 2 simp + 12 comp);numDeq 仍 1。
// (V2) 条目状态 status 新增 blocked(向量访存阻塞位)与 vecMem(sqIdx/lqIdx/numLsElem)。
//      blocked 入队时由顶层算出(EnqEntry)或随条目透传(Others);条目内每拍按
//      lqDeqPtr 重算:blocked = ({lqIdx} != {lqDeqPtr}) & isVleff。
//      ★ canIssue 多一个 & ~blocked 门控(VfDiv 无)★。
// (V3) payload 由「向量除法子集」扩成「向量访存全集」:vpu 新增 vmask[127]/nf/veew/isVleff,
//      payload 新增 lastUop / lqIdx / sqIdx;无 fpu_wflags。
// (V4) fuType one-hot 位:VLDU=31 / VSTU=32 / VSEGLDU=33 / VSEGSTU=34(VfDiv 是 22/26)。
// (V5) ★ mem feedback(本变体核心,来自访存样板)★:条目阵列额外收三路按索引匹配的响应——
//        vecLdIn.resp(向量 load 发射响应)、fromMem.slowResp(慢响应)、
//        vecLdIn.finalIssueResp(最终发射响应),均按 {sqIdx,lqIdx} 与条目匹配。
//      当条目 issueTimer 走到饱和(b11=空闲窗口)时,issueResp = 这三路的命中合并;
//      否则仍按 og0/og1/og2Resp 的 timer 窗口给响应(与 VfDiv 同)。
//      —— 这是 VfDiv「timer2 出 og2 响应」与访存「按索引回灌」的融合点。
//
// ★ 与「访存样板 StaMou/Ldu」的差异 ★
//   · 向量调度:5 源 + ignoreOldVd + WB 三组唤醒(无 IQ 唤醒 / 无 exuSources /
//     无 loadDependency / 无 RegCache / 无 og0Cancel / 无 ldCancel —— 这些是标量访存才有的)。
//   · 响应是「按索引匹配回灌」(三路 robIdx/uopIdx/sqIdx/lqIdx 携带,本变体匹配只用
//     {sqIdx,lqIdx}),而非 StaMou 单路 feedbackSlow 折算。
//
// 关键维度(全部来自 golden EntriesVlduVstu.sv / IssueQueueVlduVstu.sv 端口实测):
//   numEntries = 16, numEnq = 2, numSimp = 2, numComp = 12, numDeq = 1
//   numRegSrc  = 5, numWakeupFromWB = 16(无 IQ 唤醒)
// =============================================================================
package iq_vlduvstuseg_pkg;

  // ---------------------------------------------------------------------------
  // 1. 变体维度参数
  // ---------------------------------------------------------------------------
  localparam int NUM_ENTRIES   = 16; // 条目总数(io_valid 宽度 16)
  localparam int NUM_ENQ       = 2;  // 入队端口数 / 入队条目数
  localparam int NUM_SIMP      = 2;  // 简单条目数(io_simpEntryOldestSel bits 宽 2)
  localparam int NUM_COMP      = 12; // 复杂条目数(io_compEntryOldestSel bits 宽 12)
  localparam int NUM_OTHERS    = NUM_ENTRIES - NUM_ENQ; // = 14 (simp 在前, comp 在后)
  localparam int NUM_DEQ       = 1;  // 发射端口数(单向量访存流水)
  localparam int NUM_REGSRC    = 5;  // ★ 每 uop 源寄存器数(vs1/vs2/vd/v0/vl)★
  localparam int NUM_WK_WB     = 16; // ★ WB 唤醒源数(本变体无 IQ 唤醒)★
  localparam int ROB_PTR_W     = 8;  // RobPtr.value 宽度
  localparam int PREG_W        = 7;  // 源物理寄存器号宽度(srcStatus.psrc 宽 7)
  localparam int PDEST_W       = 8;  // 目的/唤醒 pdest 宽度(payload.pdest 与 WB.pdest 宽 8)
  localparam int FU_OP_W       = 9;  // fuOpType 宽度
  localparam int UOP_IDX_W     = 7;  // vpu uopIdx 宽度
  localparam int VSTART_W      = 8;  // vpu vstart 宽度
  localparam int VMASK_W       = 128;// vpu vmask 宽度
  localparam int FTQ_PTR_W     = 6;  // FtqPtr.value 宽度
  localparam int FTQ_OFF_W     = 4;  // ftqOffset 宽度
  localparam int SQ_PTR_W      = 6;  // SqPtr.value 宽度(StoreQueue 指针)
  localparam int LQ_PTR_W      = 7;  // LqPtr.value 宽度(LoadQueue 指针)
  localparam int NUM_LS_ELEM_W = 5;  // numLsElem 宽度

  // 本变体功能单元在 FuType one-hot 里的位号(IQFuType.readFuType:其余位清零)。
  localparam int FU_NUM     = 35; // FuType 总位数(io_fuType_* 宽 35)
  localparam int FU_VLDU    = 31; // 向量 load
  localparam int FU_VSTU    = 32; // 向量 store
  localparam int FU_VSEGLDU = 33; // ★ 段 load(本变体新增)★
  localparam int FU_VSEGSTU = 34; // ★ 段 store(本变体新增)★

  // WB 唤醒分组边界(按目的写使能类型,与 VfDiv 同构)。
  localparam int WB_VEC_LO = 0;  localparam int WB_VEC_HI = 5;  // vecWen 组(向量数据)
  localparam int WB_V0_LO  = 6;  localparam int WB_V0_HI  = 11; // v0Wen 组(掩码)
  localparam int WB_VL_LO  = 12; localparam int WB_VL_HI  = 15; // vlWen 组(向量长度)

  // ---------------------------------------------------------------------------
  // 2. 离散量编码(与 VfDiv 同)
  // ---------------------------------------------------------------------------
  // 源就绪状态 SrcState(1 bit)
  typedef enum logic {
    SRC_BUSY = 1'b0, // 源未就绪,等待唤醒
    SRC_RDY  = 1'b1  // 源已就绪
  } src_state_e;

  // 数据来源 DataSource(4 bit, 见 object DataSource)。
  typedef enum logic [3:0] {
    DS_ZERO     = 4'b0000, // 0 号物理寄存器,恒 0
    DS_FORWARD  = 4'b0001, // 本变体不用(无 IQ 唤醒前递)
    DS_BYPASS   = 4'b0010, // 旁路源寄存一拍(入队携带,本变体内部只会从 2→8 转)
    DS_BYPASS2  = 4'b0011,
    DS_IMM      = 4'b0100, // ★ ignoreOldVd 把 src2 改成「无源/立即」(旧 vd 被忽略)★
    DS_V0       = 4'b0101,
    DS_REGCACHE = 4'b0110,
    DS_REG      = 4'b1000  // 物理寄存器堆
  } data_source_e;

  // 发射响应类型 RespType(2 bit, 见 object RespType)。
  //   访存反馈把 hit 复制成 2 bit:hit=1→2'b11(SUCCESS),hit=0→2'b00(BLOCK)。
  typedef enum logic [1:0] {
    RESP_BLOCK     = 2'b00,
    RESP_UNCERTAIN = 2'b01,
    RESP_SUCCESS   = 2'b11
  } resp_type_e;

  // ---------------------------------------------------------------------------
  // 3. 条目/源状态 struct
  // ---------------------------------------------------------------------------
  // 单个源操作数的状态 SrcStatus(向量变体:无 loadDependency / 无 exuSources / 无 RegCache)。
  typedef struct packed {
    logic [PREG_W-1:0] psrc;      // 源物理寄存器号(用于 pdest 匹配唤醒)
    logic [3:0]        src_type;  // SrcType(本变体看 bit2=isVec / bit3=isV0)
    src_state_e        src_state; // 是否就绪
    data_source_e      data_src;  // 数据来源(2→8 与 ignoreOldVd→IMM 间变)
  } src_status_t;

  // 向量访存专属:条目内的存/取队列指针 + 元素数(vecMem 子束)。
  typedef struct packed {
    logic                    sq_flag;     // SqPtr.flag
    logic [SQ_PTR_W-1:0]     sq_value;    // SqPtr.value
    logic                    lq_flag;     // LqPtr.flag
    logic [LQ_PTR_W-1:0]     lq_value;    // LqPtr.value
    logic [NUM_LS_ELEM_W-1:0] num_ls_elem;// 本 uop 访存元素数
  } vec_mem_t;

  // 条目状态 Status(见 class Status)。本变体 numDeq=1,无 deqPortIdx。
  typedef struct packed {
    logic                         rob_flag;     // RobPtr.flag(环形指针方向位)
    logic [ROB_PTR_W-1:0]         rob_value;    // RobPtr.value
    logic                         fu_type_vldu;    // FuType[31]
    logic                         fu_type_vstu;    // FuType[32]
    logic                         fu_type_vsegldu; // FuType[33](★段 load,本变体新增★)
    logic                         fu_type_vsegstu; // FuType[34](★段 store,本变体新增★)
    src_status_t [NUM_REGSRC-1:0] src;          // 5 个源的状态
    logic                         blocked;      // ★ 向量访存阻塞(vleff 跨 lqDeqPtr 时阻塞)★
    logic                         issued;       // 已发射(等待响应)
    logic [1:0]                   issue_timer;  // 发射计时(0→1→2→饱和3,选响应窗口)
    vec_mem_t                     vec_mem;      // ★ 向量访存指针/元素数 ★
  } status_t;

  // 向量处理单元控制 vpu(随条目透传 + ignoreOldVd 判定要用)。
  typedef struct packed {
    logic                vma;          // mask agnostic
    logic                vta;          // tail agnostic
    logic [1:0]          vsew;         // 元素宽度
    logic [2:0]          vlmul;        // 寄存器组倍率
    logic                vm;           // 是否用掩码(vm=1 表示无掩码)
    logic [VSTART_W-1:0] vstart;       // 起始元素
    logic [VMASK_W-1:0]  vmask;        // ★ 掩码(向量访存透传)★
    logic [2:0]          nf;           // ★ 段数(nf, 向量分段访存)★
    logic [1:0]          veew;         // ★ 元素有效位宽 ★
    logic                is_depend_old_vd; // ★ 指令强依赖旧 vd(则不能 ignoreOldVd)★
    logic                is_write_part_vd; // ★ 只写部分 vd(影响 ignoreOldVd 判定)★
    logic                is_vleff;     // ★ vle-fault-first(影响 blocked 判定)★
  } vpu_t;

  // uop 负载 payload(见 class DynInst,向量访存子集)。
  typedef struct packed {
    logic                    ftq_flag;   // FtqPtr.flag
    logic [FTQ_PTR_W-1:0]    ftq_value;  // FtqPtr.value
    logic [FTQ_OFF_W-1:0]    ftq_offset;
    logic [FU_OP_W-1:0]      fu_op_type;
    logic                    vec_wen;    // 向量写使能(随条目透传)
    logic                    v0_wen;     // v0 掩码写使能
    logic                    vl_wen;     // vl 写使能
    vpu_t                    vpu;
    logic [UOP_IDX_W-1:0]    uop_idx;
    logic                    last_uop;   // 是否本指令最后一个 uop
    logic [PDEST_W-1:0]      pdest;
    logic                    lq_flag;    // LqPtr.flag(payload 侧副本)
    logic [LQ_PTR_W-1:0]     lq_value;   // LqPtr.value
    logic                    sq_flag;    // SqPtr.flag(payload 侧副本)
    logic [SQ_PTR_W-1:0]     sq_value;   // SqPtr.value
  } payload_t;

  // 完整条目 EntryBundle = 状态 + 负载。
  typedef struct packed {
    status_t  status;
    payload_t payload;
  } entry_t;

  // 发射响应 EntryDeqRespBundle(条目阵列折算后喂给单条目)。
  typedef struct packed {
    logic       valid;
    resp_type_e resp;
  } deq_resp_t;

  // 单个 WB 唤醒源 bundle。三组共用此结构;wen 字段语义按组解释:
  //   vec 组 → vecWen, v0 组 → v0Wen, vl 组 → vlWen。
  typedef struct packed {
    logic              valid;
    logic              wen;   // 对应组的写使能(vecWen/v0Wen/vlWen)
    logic [PDEST_W-1:0] pdest;
  } wk_wb_t;

  // 顶层提供的 vl 零/最大信息(用于 ignoreOldVd 判定)。
  typedef struct packed {
    logic int_is_zero;
    logic int_is_vlmax;
    logic vf_is_zero;
    logic vf_is_vlmax;
  } vl_info_t;

  // ---------------------------------------------------------------------------
  // 4. mem feedback bundle —— 三路按索引匹配的发射响应(本变体核心)
  // ---------------------------------------------------------------------------
  // 三路响应(vecLdIn.resp / fromMem.slowResp / vecLdIn.finalIssueResp)统一成此结构,
  // 条目阵列据 {sqIdx,lqIdx} 与条目匹配,命中则在 issueTimer 饱和窗口给出 issueResp。
  typedef struct packed {
    logic                valid;
    logic [1:0]          resp;
    logic                sq_flag;
    logic [SQ_PTR_W-1:0] sq_value;
    logic                lq_flag;
    logic [LQ_PTR_W-1:0] lq_value;
  } mem_resp_t;

endpackage : iq_vlduvstuseg_pkg
