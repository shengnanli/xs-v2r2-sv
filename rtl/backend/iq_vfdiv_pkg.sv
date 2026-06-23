// =============================================================================
// iq_vfdiv_pkg —— 香山 V2R2(昆明湖) 发射队列 VfdivVidiv 变体 公共类型/参数
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{Entries,EntryBundles,EnqEntry,
//        OthersEntry,IssueQueue}.scala
// golden 对照:IssueQueueVfdivVidiv.sv / EntriesVfdivVidiv.sv
//             叶子:EnqEntry_18.sv / OthersEntry_164.sv(simp) / OthersEntry_166.sv(comp)
//
// ★★ 这是「向量类」发射队列的开荒变体 ★★
// 发射队列(IssueQueue)是乱序后端的调度心脏:它把每条等待发射的 uop 存成一个「条目」,
// 每拍监听唤醒总线把就绪的源置位,在所有「全源就绪 && 未发射」的条目里按年龄选最老的
// 发射。VfdivVidiv = 向量除法 IQ(VFDIV 浮点向量除/开方 + VIDIV 整数向量除)。它是
// 向量 IQ 里最小的变体,用来给后续所有向量变体(VfaluVfmac/Vppu/VlVs…)打样。
//
// ─────────────────────────────────────────────────────────────────────────────
// ★ 向量专属机制(开荒重点,与浮点样板 iq_ffmac/iq_ffmacfdiv 的关键差异)★
// ─────────────────────────────────────────────────────────────────────────────
// (1) numRegSrc = 5(浮点只有 3)。向量 uop 的 5 个源各有专属语义:
//        src0/1/2 = 向量数据源 vs1/vs2/vd(旧目的寄存器,可读改写)
//        src3     = v0 掩码寄存器(mask)
//        src4     = vl(向量长度,作为一个「源」参与就绪判定)
//
// (2) 唤醒源:本变体**只有 WB 唤醒,没有 IQ 唤醒**(向量除法多周期,不做 0 周期前递),
//     因此**没有 exuSources / UIntCompressor / og0Cancel / dataSources=forward**。
//     这是向量除法相对浮点(FaluFmac)在结构上「更简单」的地方。
//     16 路 WB 唤醒按目的类型分三组,每组只看对应的写使能位 + 对应 srcType 位:
//        WB[0..5]   → vecWen 写回,匹配 srcType[2](isVec) 的 src0/1/2(向量数据)
//        WB[6..11]  → v0Wen  写回,匹配 srcType[3](isV0)  的 src3   (掩码)
//        WB[12..15] → vlWen  写回,匹配 srcType[2]        的 src4   (vl)
//     注意 vl 源(src4)用的也是 srcType[2],但写使能看的是 vlWen(不是 vecWen)。
//
// (3) srcType 位语义(SrcType, 见 object SrcType / EntryBundles):
//        srcType[2] = isVecVf(向量/浮点数据类)—— src0/1/2/4 用它做唤醒门控
//        srcType[3] = isV0  (v0 掩码类)        —— src3 用它做唤醒门控
//
// (4) ★ ignoreOldVd(向量专属!仅作用于 src2=vd 旧目的源)★
//     向量指令的 vd(目的寄存器)有时被当作「源」读旧值(read-modify-write),但在某些
//     vl/vstart/mask 配置下,旧 vd 的内容其实不会被用到(全被新结果覆盖,或被 tail/mask
//     agnostic 策略丢弃)。这时即使 vd 对应的物理寄存器尚未就绪,也可以「忽略旧 vd 依赖」,
//     把 src2 直接置就绪、srcType 清 0(不再当向量源)、dataSources 改成 IMM(立即/无源)。
//     触发条件(见 §EnqEntry/OthersEntry 的 ignoreOldVd_2):
//        - src2.srcType[2](是向量数据源)
//        - 本拍 src4(vl)被某条 vlWen 唤醒命中(wakeUpFromVl),且 vl 来源(Int/Vf)非零
//        - !isDependOldVd(指令本身不强依赖旧 vd)
//        - 且 (vl==vlmax 时, (vm|vma) && !isWritePartVd) 或 ((vm|vma) && vta)
//          —— 即 tail/mask agnostic 使旧 vd 无意义。
//     这是向量调度区别于标量/浮点的最核心机制,后续向量变体复用。
//     vl 的零/最大信息由顶层四个输入提供:vlFromInt{IsZero,IsVlmax}/vlFromVf{IsZero,IsVlmax}。
//
// (5) fuType:本变体只保留 one-hot 的 bit22(VFDIV)与 bit26(VIDIV);总位宽仍 35。
//
// (6) payload:向量负载字段众多(vpu_* 一族 + uopIdx),无 fpu_fmt/fpu_rm/rfWen/fpWen,
//     新增 vecWen/v0Wen(向量/掩码写使能,随条目透传)。
//
// 关键维度(全部来自 golden EntriesVfdivVidiv.sv 端口实测):
//   numEntries = 10, numEnq = 2, numSimp = 2, numComp = 6, numDeq = 1
//   numRegSrc  = 5, numWakeupFromWB = 16(无 IQ 唤醒)
//
// 转移策略与浮点同构:simp 是「转移源」(simp→comp 提级),comp 为终端条目。
// =============================================================================
package iq_vfdiv_pkg;

  // ---------------------------------------------------------------------------
  // 1. 变体维度参数
  // ---------------------------------------------------------------------------
  localparam int NUM_ENTRIES   = 10; // 条目总数(io_valid 宽度 10)
  localparam int NUM_ENQ       = 2;  // 入队端口数 / 入队条目数
  localparam int NUM_SIMP      = 2;  // 简单条目数(io_simpEntryEnqSelVec_0 宽 2)
  localparam int NUM_COMP      = 6;  // 复杂条目数(io_compEntryEnqSelVec_0 宽 6)
  localparam int NUM_OTHERS    = NUM_ENTRIES - NUM_ENQ; // = 8 (simp 在前, comp 在后)
  localparam int NUM_DEQ       = 1;  // 发射端口数(向量除法单端口)
  localparam int NUM_REGSRC    = 5;  // ★ 每 uop 源寄存器数(vs1/vs2/vd/v0/vl)★
  localparam int NUM_WK_WB     = 16; // ★ WB 唤醒源数(本变体无 IQ 唤醒)★
  localparam int ROB_PTR_W     = 8;  // RobPtr.value 宽度
  localparam int PREG_W        = 7;  // 源物理寄存器号宽度(srcStatus.psrc 宽 7)
  localparam int PDEST_W       = 8;  // 目的/唤醒 pdest 宽度(payload.pdest 与 WB.pdest 宽 8)
  localparam int FU_OP_W       = 9;  // fuOpType 宽度
  localparam int UOP_IDX_W     = 7;  // vpu uopIdx 宽度
  localparam int VSTART_W      = 8;  // vpu vstart 宽度

  // 本变体功能单元在 FuType one-hot 里的位号(IQFuType.readFuType:其余位清零)。
  localparam int FU_NUM   = 35; // FuType 总位数(io_fuType_* 宽 35)
  localparam int FU_VFDIV = 22; // 向量浮点除/开方
  localparam int FU_VIDIV = 26; // 向量整数除

  // WB 唤醒分组边界(按目的写使能类型)。
  localparam int WB_VEC_LO = 0;  localparam int WB_VEC_HI = 5;  // vecWen 组(向量数据)
  localparam int WB_V0_LO  = 6;  localparam int WB_V0_HI  = 11; // v0Wen 组(掩码)
  localparam int WB_VL_LO  = 12; localparam int WB_VL_HI  = 15; // vlWen 组(向量长度)

  // ---------------------------------------------------------------------------
  // 2. 离散量编码
  // ---------------------------------------------------------------------------
  // 源就绪状态 SrcState(1 bit)
  typedef enum logic {
    SRC_BUSY = 1'b0, // 源未就绪,等待唤醒
    SRC_RDY  = 1'b1  // 源已就绪
  } src_state_e;

  // 数据来源 DataSource(4 bit, 见 object DataSource)。本变体实际只用到:
  //   IMM(ignoreOldVd 后的 src2)、BYPASS(=2,入队时可能带)、REG(=8)。
  typedef enum logic [3:0] {
    DS_ZERO     = 4'b0000,
    DS_FORWARD  = 4'b0001, // 本变体不用(无 IQ 唤醒前递)
    DS_BYPASS   = 4'b0010, // 旁路源寄存一拍(入队携带,本变体内部只会从 2→8 转)
    DS_BYPASS2  = 4'b0011,
    DS_IMM      = 4'b0100, // ★ ignoreOldVd 把 src2 改成「无源/立即」(旧 vd 被忽略)★
    DS_V0       = 4'b0101,
    DS_REGCACHE = 4'b0110,
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
  // 单个源操作数的状态 SrcStatus(向量变体:无 loadDependency / 无 exuSources / 无 RegCache)。
  typedef struct packed {
    logic [PREG_W-1:0] psrc;      // 源物理寄存器号(用于 pdest 匹配唤醒)
    logic [3:0]        src_type;  // SrcType(本变体看 bit2=isVec / bit3=isV0)
    src_state_e        src_state; // 是否就绪
    data_source_e      data_src;  // 数据来源(本变体只在 2→8 与 ignoreOldVd→IMM 间变)
  } src_status_t;

  // 条目状态 Status(见 class Status)。本变体 numDeq=1,无 deqPortIdx。
  typedef struct packed {
    logic                         rob_flag;     // RobPtr.flag(环形指针方向位)
    logic [ROB_PTR_W-1:0]         rob_value;    // RobPtr.value
    logic                         fu_type_vfdiv;// FuType[22]
    logic                         fu_type_vidiv;// FuType[26]
    src_status_t [NUM_REGSRC-1:0] src;          // 5 个源的状态
    logic                         issued;       // 已发射(等待响应)
    logic [1:0]                   issue_timer;  // 发射计时(0→1→2→饱和3,选 og0/1/2 响应窗口)
  } status_t;

  // 向量处理单元控制 vpu(随条目透传 + ignoreOldVd 判定要用)。
  typedef struct packed {
    logic              vma;          // mask agnostic
    logic              vta;          // tail agnostic
    logic [1:0]        vsew;         // 元素宽度
    logic [2:0]        vlmul;        // 寄存器组倍率
    logic              vm;           // 是否用掩码(vm=1 表示无掩码)
    logic [VSTART_W-1:0] vstart;     // 起始元素
    logic              is_ext;
    logic              is_narrow;
    logic              is_dst_mask;
    logic              is_op_mask;
    logic              is_depend_old_vd; // ★ 指令强依赖旧 vd(则不能 ignoreOldVd)★
    logic              is_write_part_vd; // ★ 只写部分 vd(影响 ignoreOldVd 判定)★
  } vpu_t;

  // uop 负载 payload(见 class DynInst,向量子集)。
  typedef struct packed {
    logic [FU_OP_W-1:0]   fu_op_type;
    logic                 vec_wen;    // 向量写使能(随条目透传)
    logic                 v0_wen;     // v0 掩码写使能
    logic                 fpu_wflags; // 浮点标志写使能(透传)
    vpu_t                 vpu;
    logic [UOP_IDX_W-1:0] uop_idx;
    logic [PDEST_W-1:0]   pdest;
  } payload_t;

  // 完整条目 EntryBundle = 状态 + 负载。
  typedef struct packed {
    status_t  status;
    payload_t payload;
  } entry_t;

  // 发射响应 EntryDeqRespBundle(本变体只用 valid/resp)。
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

endpackage : iq_vfdiv_pkg
