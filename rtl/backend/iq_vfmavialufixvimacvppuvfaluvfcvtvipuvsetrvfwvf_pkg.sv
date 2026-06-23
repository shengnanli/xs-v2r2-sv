// =============================================================================
// iq_vfmavialufixvimacvppuvfaluvfcvtvipuvsetrvfwvf_pkg
//   —— 香山 V2R2(昆明湖) 发射队列 VfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf 变体
//      公共类型/参数
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{Entries,EntryBundles,EnqEntry,
//        OthersEntry,IssueQueue}.scala
// golden 对照:IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv
//             EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv
//             叶子:EnqEntry_14.sv / OthersEntry_136.sv(simp) / OthersEntry_138.sv(comp)
//             转移策略:EnqPolicy_14.sv
//
// ★★ 这是「向量执行类」发射队列里挂 FU 最多的双发射变体 ★★
// 一条发射队列上挂八种功能单元(FuType one-hot 位号,见 FuType.scala addType 次序,jmp=0 起):
//   bit18 = vipu  (向量整数置换/规约)
//   bit19 = vialuF(向量整数定点 ALU)
//   bit20 = vppu  (向量置换)
//   bit21 = vimac (向量整数乘累加)
//   bit24 = vfalu (向量浮点 ALU)
//   bit25 = vfma  (向量浮点 FMA)
//   bit27 = vfcvt (向量浮点转换)
//   bit30 = vsetfwf(vset 读旧 vl 写 vconfig,即名字里的 Vsetrvfwvf)
//
// ─────────────────────────────────────────────────────────────────────────────
// ★ 本变体相对样板 VfmaVialuFixVfalu 的「全部增量」(逐项对照 golden 实测)★
// ─────────────────────────────────────────────────────────────────────────────
//   增量 A:fuType 由 3 位(19/24/25)扩为 8 位(18/19/20/21/24/25/27/30)。
//           其余结构(numEntries/numEnq/numSimp/numComp/numDeq/numRegSrc/numWakeupFromWB、
//           WB 分组、ignoreOldVd、issueTimer→og2Resp、转移策略、入队延迟唤醒)逐字相同。
//   增量 B:payload 多带三个「随条目透传」字段:rf_wen(整数寄存器写使能)、
//           vl_wen(vl 写使能)、sel_imm(立即数选择,4 bit)。
//   增量 C:EntryBundle 顶层多带 imm(15 bit),与 status/payload 平级,随条目寄存透传
//           (转移 transEntry 也携带)。样板的 entry_t 无此字段。
//   * 这些增量字段都「只透传、不参与唤醒/选择/ignoreOldVd 判定」。
//     deqEntry(发射出口)的子集由 firtool 按下游消费裁剪:端口0 裁得多(无 imm/fpWen/
//     lastUop/rfWen/vlWen/selImm/fold/isDependOldVd/isWritePartVd),端口1 几乎全引出。
//     wrapper 只引出 golden 存在的端口,裁剪由 wrapper 自动完成。
//
// ─────────────────────────────────────────────────────────────────────────────
// ★ 与样板 VfmaVialuFixVfalu 完全相同(直接沿用)的机制 ★
// ─────────────────────────────────────────────────────────────────────────────
//   numEnq=2、numRegSrc=5(vs1/vs2/vd/v0/vl)、numWakeupFromWB=16(分 vec/v0/vl 三组)、
//   numDeq=2(deqPortIdx 机制:每条目记录被哪个 deq 端口选中,issueResp 按端口路由;
//     ★ og2Resp_1 只有 valid,端口1 的 timer2 resp 用常量 SUCCESS(2'h3)填——拓扑常量 ★)、
//   ignoreOldVd(仅 src2=旧 vd)、issueTimer→og2Resp 响应窗口、转移策略 simp→comp、
//   入队延迟唤醒(enqDelayIn1)。无 IQ 唤醒 / 无 exuSources / 无 og0Cancel。
//
// 关键维度(全部来自 golden 端口实测):
//   numEntries = 16, numEnq = 2, numSimp = 2, numComp = 12, numDeq = 2
//   numRegSrc  = 5, numWakeupFromWB = 16
// =============================================================================
package iq_vfmavialufixvimacvppuvfaluvfcvtvipuvsetrvfwvf_pkg;

  // ---------------------------------------------------------------------------
  // 1. 变体维度参数
  // ---------------------------------------------------------------------------
  localparam int NUM_ENTRIES   = 16; // 条目总数(io_valid 宽度 16)
  localparam int NUM_ENQ       = 2;  // 入队端口数 / 入队条目数
  localparam int NUM_SIMP      = 2;  // 简单条目数
  localparam int NUM_COMP      = 12; // 复杂条目数
  localparam int NUM_OTHERS    = NUM_ENTRIES - NUM_ENQ; // = 14 (simp 在前, comp 在后)
  localparam int NUM_DEQ       = 2;  // ★ 发射端口数(双发射)★
  localparam int NUM_REGSRC    = 5;  // 每 uop 源寄存器数(vs1/vs2/vd/v0/vl)
  localparam int NUM_WK_WB     = 16; // WB 唤醒源数(无 IQ 唤醒)
  localparam int ROB_PTR_W     = 8;  // RobPtr.value 宽度
  localparam int PREG_W        = 7;  // 源物理寄存器号宽度(srcStatus.psrc 宽 7)
  localparam int PDEST_W       = 8;  // 目的/唤醒 pdest 宽度
  localparam int FU_OP_W       = 9;  // fuOpType 宽度
  localparam int UOP_IDX_W     = 7;  // vpu uopIdx 宽度
  localparam int VSTART_W      = 8;  // vpu vstart 宽度
  localparam int IMM_W         = 15; // ★ 增量 C:EntryBundle 顶层 imm 宽度 ★
  localparam int SEL_IMM_W     = 4;  // ★ 增量 B:payload selImm 宽度 ★

  // ★ 增量 A:本变体功能单元在 FuType one-hot 里的位号(IQFuType.readFuType:其余位清零)★
  localparam int FU_NUM     = 35; // FuType 总位数(io_fuType_* 宽 35)
  localparam int FU_VIPU    = 18; // 向量整数置换/规约
  localparam int FU_VIALUF  = 19; // 向量整数定点 ALU
  localparam int FU_VPPU    = 20; // 向量置换
  localparam int FU_VIMAC   = 21; // 向量整数乘累加
  localparam int FU_VFALU   = 24; // 向量浮点 ALU
  localparam int FU_VFMA    = 25; // 向量浮点 FMA
  localparam int FU_VFCVT   = 27; // 向量浮点转换
  localparam int FU_VSETFWF = 30; // vset 读旧 vl 写 vconfig

  // WB 唤醒分组边界(按目的写使能类型),与样板同。
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
    DS_BYPASS   = 4'b0010, // 旁路源寄存一拍(入队携带,内部只会从 2→8 转)
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

  // 条目状态 Status(见 class Status)。numDeq=2 → 带 deq_port_idx。
  // ★ 增量 A:fuType 由 3 位扩为 8 位 ★
  typedef struct packed {
    logic                         rob_flag;       // RobPtr.flag(环形指针方向位)
    logic [ROB_PTR_W-1:0]         rob_value;      // RobPtr.value
    logic                         fu_type_vipu;   // FuType[18]
    logic                         fu_type_vialuf; // FuType[19]
    logic                         fu_type_vppu;   // FuType[20]
    logic                         fu_type_vimac;  // FuType[21]
    logic                         fu_type_vfalu;  // FuType[24]
    logic                         fu_type_vfma;   // FuType[25]
    logic                         fu_type_vfcvt;  // FuType[27]
    logic                         fu_type_vsetfwf;// FuType[30]
    src_status_t [NUM_REGSRC-1:0] src;            // 5 个源的状态
    logic                         issued;         // 已发射(等待响应)
    logic [1:0]                   issue_timer;    // 发射计时(0→1→2→饱和3,选 og0/1/2 响应窗口)
    logic                         deq_port_idx;   // 被哪个 deq 端口选中(0/1)
  } status_t;

  // 向量处理单元控制 vpu(随条目透传 + ignoreOldVd 判定要用)。
  typedef struct packed {
    logic              vma;          // mask agnostic
    logic              vta;          // tail agnostic
    logic [1:0]        vsew;         // 元素宽度
    logic [2:0]        vlmul;        // 寄存器组倍率
    logic              vm;           // 是否用掩码(vm=1 表示无掩码)
    logic [VSTART_W-1:0] vstart;     // 起始元素
    logic              fpu_is_fold_to_1_2; // FMA 折叠(1/2)
    logic              fpu_is_fold_to_1_4; // FMA 折叠(1/4)
    logic              fpu_is_fold_to_1_8; // FMA 折叠(1/8)
    logic              is_ext;
    logic              is_narrow;
    logic              is_dst_mask;
    logic              is_op_mask;
    logic              is_depend_old_vd; // ★ 指令强依赖旧 vd(则不能 ignoreOldVd)★
    logic              is_write_part_vd; // ★ 只写部分 vd(影响 ignoreOldVd 判定)★
  } vpu_t;

  // uop 负载 payload(见 class DynInst,向量子集)。
  // ★ 增量 B:多带 rf_wen / vl_wen / sel_imm(透传)★
  typedef struct packed {
    logic [FU_OP_W-1:0]   fu_op_type;
    logic                 rf_wen;     // ★ 整数寄存器写使能(透传)★
    logic                 fp_wen;     // 浮点写使能(透传)
    logic                 vec_wen;    // 向量写使能(随条目透传)
    logic                 v0_wen;     // v0 掩码写使能
    logic                 vl_wen;     // ★ vl 写使能(透传)★
    logic                 fpu_wflags; // 浮点标志写使能(透传)
    vpu_t                 vpu;
    logic [UOP_IDX_W-1:0] uop_idx;
    logic                 last_uop;   // 末尾 uop 标志
    logic [SEL_IMM_W-1:0] sel_imm;    // ★ 立即数选择(透传)★
    logic [PDEST_W-1:0]   pdest;
  } payload_t;

  // 完整条目 EntryBundle = imm + 状态 + 负载。
  // ★ 增量 C:imm 与 status/payload 平级,随条目透传 ★
  typedef struct packed {
    logic [IMM_W-1:0] imm;     // ★ 立即数(顶层透传字段)★
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

  // 单个 deq 端口的发射响应输入(og0/1/2)。
  //   og2 端口0 带真 resp;端口1 的 resp 由阵列内部用常量 SUCCESS 填。
  typedef struct packed {
    logic       og0_valid;
    logic       og1_valid;
    logic       og2_valid;
    logic [1:0] og2_resp;   // 仅端口0 有意义;端口1 由阵列忽略(用常量)
  } og_resp_t;

endpackage : iq_vfmavialufixvimacvppuvfaluvfcvtvipuvsetrvfwvf_pkg
