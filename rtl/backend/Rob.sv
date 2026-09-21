// Rob.sv —— 重排序缓冲（ReOrder Buffer），后端提交级的心脏。
//
// 在哪一层：CtrlBlock 里唯一的按序提交点。Rename/Dispatch 把 uop 入队到这里，
// 各执行单元把写回打回这里，提交宽度 8 的那条"行"从这里流向 RAT/LSQ/CSR/difftest。
//
// 核心机制（三件，读这个文件按这个顺序看）：
//   1. **条目存储是 160 项 x 每字段一个非打包数组**，不是打包结构体数组。
//      这不是风格选择：深度 160、下标 8 位时，Formality 对"信号下标"判
//      FMR_ELAB-147，`set_top` 直接失败；只有**循环变量下标**能过
//      （scripts/rob_array_idiom_canary.py 五种写法实测，四种撞 147）。
//      所以本文件里所有条目访问都走 `for` + 下标比较，没有一处用信号直接索引。
//   2. **提交读口是 8 bank x 20 行的 one-hot 读**。robBanks(i) 装 robidx%8==i 的
//      20 个条目，所有 bank 共用一个 one-hot 行地址 robBanksRaddrThisLine；
//      "下一行"用同一个 one-hot 读移位后的 bank，省掉第二套地址。
//   3. **robDeqGroup 是提交读口的寄存器级**：commitInfo / rawInfo / deqPtrEntry
//      全从它出来，io_commits_info_* 的 360 个输出直接由它驱动。
//
// 子模块：8 个的 FM 处置都是**对称黑盒**（ref 与 impl 两侧都不给体，
// CONVENTIONS §3）。★但「条件绿」的那个条件，8 个分成三类，不是一回事★
// —— 本轮逐个核实过，见 docs/rob_child_ledger.tsv（判据命令写在表头，可复算）：
//   · 2 个 **DEP_DISCHARGEABLE**：RenameBuffer(rab) / SnapshotGenerator_3
//     (snapshots_snapshotGen) 有自己的 FM target 也有重写实现，它们自己签核
//     就能解掉这条依赖。但本仓 verif/proof_certificates/ 当前**一张证书都没有**，
//     所以现在只能记 HAS_TARGET_UNVERIFIED，不是「已绿」。
//   · 5 个 **DEP_UNCLOSED**：VTypeBuffer / ExceptionGen / NewRobDeqPtrWrapper /
//     RobEnqPtrWrapper / CommitStuckCounter —— **都不是 FM target**
//     （scripts/fm_target_universe.py --check，engine=both）。条件挂在一个
//     不存在的目标上，按 codex 0153 D70 是**结构性不闭合**，
//     出路只有两条：两侧 inline elaborate 白盒化，或新建 AUX leaf target。
//   · 1 个 **DEP_UNCLOSED_MEM**：dt_pcTransType_160x2 是 firtool 行为级存储叶子
//     （reg [1:0] Memory[0:159]，8 读口/6 写口）。深度 160 / addr 8 位，
//     2^8>160 ⇒ 两侧 inline 必触发 FMR_ELAB-147，与 ram_40x47 同形；
//     要走 codex 0158 §1 的 APPROVED_MEMORY_MACRO_MODEL 逐条入表。
// ⇒ **Rob 不得记 PROVEN_DIRECT**（codex 0168 §1）。最好的可得终态是
//   条件性证明 + 6 条 UNCHANGED_GOLDEN_DEP + 2 条 HAS_TARGET_UNVERIFIED。
//   receipt 必须逐条带上，不得报成无条件通过。
// 另外三条反面结论也已钉住（见台账表头）：8 个**无一是厂商硬宏**（不得免检）；
// 8 个**只有 Rob 一个父**（别处不会替我们证掉）；ExceptionGen 在 G0/xs-signoff
// 那条 AUX 签核**不适用于本仓**（G0 2366 行 vs G1 2636 行 446 端口，不是同一设计）。
//
// 三张契约表是本文件"一位不少"的定义，改这个文件前先读：
//   docs/rob_core_contract.tsv   寄存器：13 族 161 字段 + 452 散寄存器
//   docs/rob_iface_contract.tsv  接口：647 个 output 是核的义务、20 个由子模块直接驱动
//   docs/rob_pin_failclosed.tsv  钉点判据的地基
//
// 已知残留（集成者 0920 裁定，如实记账，不得用 dont_verify/黑盒/白名单吞掉）：
//   robDeqGroup_*_debug_otherPdest_0..6 共 56 个寄存器 / 448 bit **不驱动**，
//   与 golden 一致（golden 里它们只在 RANDOMIZE_REG_INIT 里被写）。
//   射程已量：父层 CtrlBlock 把对应的 56 个输出**全部**接成 `/* unused */`，
//   整棵 Scala 树里该字段只出现 1 次（Bundle 声明，无写者无读者）——
//   见 scripts/rob_otherpdest_scope.py 的 F1..F4。
//   影响只在本层 FM：两侧各 56 个悬空比较点。
//
// 生成区：`// BEGIN GENERATED(<tag>)` .. `// END GENERATED` 由
// scripts/gen_rob.py --write 填写，手写内容一律在标记之外。
// 本文件导航（共 11795 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L2031  §1 条目存储
//   L2033  每字段一个非打包数组，名字必须是 `<prefix>_<field>`：pin 契约按
//   L2372  §2 RobPtr 算术
//   L2374  RobSize=160 不是 2 的幂，所以 CircularQueuePtr 的 `+` 走"回绕"那条路：
//   L2417  §3 入队请求的整理
//   L2419  六路 enq 请求打成数组，后面所有"逐路"逻辑都从这里取，避免六份复制粘贴
//   L2507  §4 入队许可
//   L2551  §5 状态机与走回
//   L2739  §6 入队计数与 allowEnqueue
//   L2741  ★这里的加法全是 8 位回绕★
//   L2782  §7 阻塞类状态位
//   L2837  §8 写回口的整理
//   L2839  ★写回口的下标是稀疏的，而且每个子集的下标集合只有 golden 能告诉你★
//   L3068  §9 入队：条目存储的写入
//   L3070  这里有**两种完全不同的选择结构**，弄混就是真 bug：
//   L3582  §10 条目存储的时序写入
//   L3682  §11 提交读口：8 bank x 20 行的 one-hot 读
//   L3684  robBanks(b) 装 robidx%8==b 的 20 个条目；八个 bank **共用**一个 one-hot 行地址
//   L3913  §12 robDeqGroup：提交读口的寄存器级
//   L3915  connectCommitEntry 的逐字段拷贝
//   L3977  §13 队头读口
//   L3979  三个名字在 Scala 里是**同一个表达式**
//   L4095  §14 队头的异常/中断/冲刷判定
//   L4265  §15 提交 / 走回的对外输出
//   L4267  ★commit_vDeqGroup / commit_wDeqGroup 是**按 bank 直接取**的★
//   L4813  §16 RAB
//   L4815  io.rabCommits := RegNext(rab.io.commits) —— 整条打一拍，纯粹为了时序/面积
//   L5046  §17 送给 exceptionGen 的三类折算量
//   L5048  ★io_writeback_<i> 各自只有一部分 exceptionVec 位★
//   L5085  §18 WFI
//   L5087  遇到 wfi 指令就挂起提交，等 CSR 说可以恢复、或者被冲刷、或者 2^20 拍超时
//   L5188  §19 CSR / LSQ / 队头杂项
//   L5355  §20 trace
//   L5357  八路提交槽各出一个 trace block，内容直接取 rawInfo
//   L5421  §21 异常出口
//   L5423  整条是 RegEnable(..., exceptionHappen)：异常发生那一拍把现场锁下来，
//   L5577  §22 debug / difftest 规则阵列
//   L5579  这一段不参与功能，但**一位都不能省**：省掉之后 FM 的 match 会退化成签名
//   L6099  §23 性能事件
//   L6101  generatePerfEvent() 出来的 19 个事件，每个都**打两拍**再送出去
//   L6252  §24 difftest 打包口
//   L6254  difftest 的三种事件被打包成宽总线从 Rob 直接钻出去
//   L6640  Rob —— 顶层壳
//   L6642  这一层不含任何设计逻辑：端口表、局部网、核实例、8 个子模块实例**全部**由
//

package rob_pkg;

  // ---- 规模（KunminghuV2Config；只有 golden 的端口/寄存器表能确认这些）----
  localparam int ROB_SIZE     = 160;  // 条目数
  localparam int COMMIT_W     = 8;    // 提交宽度 = 一"行"
  localparam int RENAME_W     = 6;    // 入队宽度
  localparam int BANK_N       = 8;    // bank 数 = COMMIT_W
  localparam int BANK_DEPTH   = ROB_SIZE / BANK_N;   // 20
  localparam int BANK_ADDR_W  = 3;    // log2Up(COMMIT_W)

  // ---- 指针与字段位宽（逐个对过 golden 的端口表/寄存器表）----
  localparam int PTR_W        = 8;    // RobPtr.value（log2(160) 向上取 8）
  localparam int LQ_PTR_W     = 7;
  localparam int SQ_PTR_W     = 6;
  localparam int FTQ_PTR_W    = 6;
  localparam int FTQ_OFF_W    = 4;
  localparam int VADDR_W      = 50;
  localparam int PADDR_W      = 48;
  localparam int XLEN         = 64;
  localparam int PREG_W       = 8;    // PhyRegIdxWidth
  localparam int LREG_W       = 6;    // LogicRegsWidth
  localparam int FUTYPE_W     = 35;   // FuType 是 one-hot，35 位
  localparam int FUOPTYPE_W   = 9;
  localparam int UOPNUM_W     = 7;    // log2Up(MaxUopSize+1)
  localparam int INSTRSIZE_W  = 3;    // log2Ceil(RenameWidth+1)
  localparam int FFLAGS_W     = 5;
  localparam int COMMITTYPE_W = 3;
  localparam int TRIGGER_W    = 4;
  localparam int ITYPE_W      = 4;
  localparam int IRETIRE_W    = 4;
  localparam int EXCP_N       = 24;   // ExceptionVec 长度

  // ---- 写回口的子集下标 ----
  // ★这些下标 Scala 源里看不出来★：它们由 KunminghuV2Config 决定，
  // 只有 golden 的端口表能告诉你。逐条见 docs/rob_iface_contract.tsv 的 WBSUBSET 段。
  localparam int EXU_WB_N     = 27;   // io_exuWriteback_0..26（稠密）
  localparam int EXU_N        = 25;   // exuWBs = 0..24（非 std）
  localparam int STD_N        = 2;    // stdWBs = {25, 26}
  localparam int FFLAGS_WB_N  = 11;   // {5,8,9,10,11,12,13,14,15,16,17}
  localparam int VXSAT_WB_N   = 2;    // {13,15}
  localparam int VLD_WB_N     = 2;    // {23,24}
  localparam int BRH_WB_N     = 3;    // {1,3,5}
  localparam int EXCP_WB_N    = 10;   // io_writeback {7,13,14,18..24}
  localparam int REDIR_WB_N   = 4;    // io_writeback {1,3,5,7}

  // ---- 编码（取自 xiangshan 的 Scala 定义，改动前回对源）----
  // CommitType（src/main/scala/xiangshan/package.scala:165）
  localparam logic [COMMITTYPE_W-1:0] CT_NORMAL = 3'b000;
  localparam logic [COMMITTYPE_W-1:0] CT_BRANCH = 3'b001;
  localparam logic [COMMITTYPE_W-1:0] CT_LOAD   = 3'b010;
  localparam logic [COMMITTYPE_W-1:0] CT_STORE  = 3'b011;

  // RedirectLevel（同文件 179 行）
  localparam logic RL_FLUSH_AFTER = 1'b0;
  localparam logic RL_FLUSH       = 1'b1;

  // TriggerAction（backend/fu/util/..., object TriggerAction）
  localparam logic [TRIGGER_W-1:0] TA_DMODE = 4'd1;
  localparam logic [TRIGGER_W-1:0] TA_NONE  = 4'd15;

  // Itype（backend/trace/Interface.scala:62）；Branch 就是 NonTaken
  localparam logic [ITYPE_W-1:0] IT_BRANCH = 4'd4;
  localparam logic [ITYPE_W-1:0] IT_TAKEN  = 4'd5;
  localparam logic [ITYPE_W-1:0] IT_EXCP   = 4'd1;
  localparam logic [ITYPE_W-1:0] IT_INTR   = 4'd2;

  // FuType 是 one-hot（backend/fu/FuType.scala，addType 的顺序就是位号）
  localparam int FU_JMP = 0,  FU_BRH = 1,  FU_I2F = 2,  FU_I2V = 3,  FU_F2V = 4;
  localparam int FU_CSR = 5,  FU_ALU = 6,  FU_MUL = 7,  FU_DIV = 8,  FU_FENCE = 9;
  localparam int FU_BKU = 10, FU_FALU = 11, FU_FMAC = 12, FU_FCVT = 13, FU_FDIVSQRT = 14;
  localparam int FU_LDU = 15, FU_STU = 16, FU_MOU = 17;
  localparam int FU_VIPU = 18, FU_VIALUF = 19, FU_VPPU = 20, FU_VIMAC = 21, FU_VIDIV = 22;
  localparam int FU_VFPU = 23, FU_VFALU = 24, FU_VFMA = 25, FU_VFDIV = 26, FU_VFCVT = 27;
  localparam int FU_VSETIWI = 28, FU_VSETIWF = 29, FU_VSETFWF = 30;
  localparam int FU_VLDU = 31, FU_VSTU = 32, FU_VSEGLDU = 33, FU_VSEGSTU = 34;

  // ---- 状态机 ----
  localparam logic S_IDLE = 1'b0;
  localparam logic S_WALK = 1'b1;

  // ---- 条目字段（组合路径用打包结构体，**存储不用**）----
  // ★为什么只在组合路径用★：存储必须是"每字段一个非打包数组"，pin 契约按
  // `<prefix>_<field>_reg[<i>][<b>]` 配对（scripts/gen_rob_pins.py 就是那份契约），
  // 打包成结构体后 Formality 只能看到一根位串，set_user_match 无从下手
  // （上一轮 FM-036 命中 9263/9440 就是这么来的）。
  // 但**读出来之后**的那一路是纯组合，打包成结构体能把 36 个字段的重复代码
  // 收成一行，不影响存储形态。
  typedef struct packed {
    logic                      valid;
    logic                      vls;
    logic                      interrupt_safe;
    logic                      fpWen;
    logic                      rfWen;
    logic                      wflags;
    logic                      dirtyVs;
    logic [COMMITTYPE_W-1:0]   commitType;
    logic                      ftqIdx_flag;
    logic [FTQ_PTR_W-1:0]      ftqIdx_value;
    logic [FTQ_OFF_W-1:0]      ftqOffset;
    logic                      isRVC;
    logic                      isVset;
    logic                      isHls;
    logic [INSTRSIZE_W-1:0]    instrSize;
    logic [ITYPE_W-1:0]        traceBlockInPipe_itype;
    logic [IRETIRE_W-1:0]      traceBlockInPipe_iretire;
    logic                      traceBlockInPipe_ilastsize;
    logic [FFLAGS_W-1:0]       fflags;
    logic                      mmio;
    logic                      stdWritebacked;
    logic                      vxsat;
    logic [UOPNUM_W-1:0]       realDestSize;
    logic [UOPNUM_W-1:0]       uopNum;
    logic                      needFlush;
    logic [VADDR_W-1:0]        debug_pc;
    logic [31:0]               debug_instr;
    logic [LREG_W-1:0]         basicDebug_ldest;
    logic [PREG_W-1:0]         basicDebug_pdest;
    logic [LREG_W-1:0]         basicDebug_vd;
    logic                      basicDebug_fpWen;
    logic                      basicDebug_vecWen;
    logic                      basicDebug_v0Wen;
    logic                      basicDebug_eliminatedMove;
    logic                      basicDebug_isXSTrap;
    logic [FUTYPE_W-1:0]       debug_fuType;
  } rob_entry_t;

  // 提交读口那一级（robDeqGroup）的组合视图。字段表 = RobCommitEntryBundle，
  // 比 rob_entry_t 多出 walk_v/commit_v/commit_w/isVls/dirtyFs 和
  // debug_otherPdest_0..6（见文件头「已知残留」）。同样**只用于组合路径**。
  typedef struct packed {
    logic                      walk_v;
    logic                      commit_v;
    logic                      commit_w;
    logic [UOPNUM_W-1:0]       realDestSize;
    logic                      interrupt_safe;
    logic                      wflags;
    logic [FFLAGS_W-1:0]       fflags;
    logic                      vxsat;
    logic                      isRVC;
    logic                      isVset;
    logic                      isHls;
    logic                      isVls;
    logic                      vls;
    logic                      mmio;
    logic [COMMITTYPE_W-1:0]   commitType;
    logic                      ftqIdx_flag;
    logic [FTQ_PTR_W-1:0]      ftqIdx_value;
    logic [FTQ_OFF_W-1:0]      ftqOffset;
    logic [INSTRSIZE_W-1:0]    instrSize;
    logic                      fpWen;
    logic                      rfWen;
    logic                      needFlush;
    logic [ITYPE_W-1:0]        traceBlockInPipe_itype;
    logic [IRETIRE_W-1:0]      traceBlockInPipe_iretire;
    logic                      traceBlockInPipe_ilastsize;
    logic [VADDR_W-1:0]        debug_pc;
    logic [31:0]               debug_instr;
    logic [LREG_W-1:0]         basicDebug_ldest;
    logic [PREG_W-1:0]         basicDebug_pdest;
    logic [LREG_W-1:0]         basicDebug_vd;
    logic                      basicDebug_fpWen;
    logic                      basicDebug_vecWen;
    logic                      basicDebug_v0Wen;
    logic                      basicDebug_eliminatedMove;
    logic                      basicDebug_isXSTrap;
    logic [FUTYPE_W-1:0]       debug_fuType;
    logic                      dirtyFs;
    logic                      dirtyVs;
    logic [PREG_W-1:0]         debug_otherPdest_0;
    logic [PREG_W-1:0]         debug_otherPdest_1;
    logic [PREG_W-1:0]         debug_otherPdest_2;
    logic [PREG_W-1:0]         debug_otherPdest_3;
    logic [PREG_W-1:0]         debug_otherPdest_4;
    logic [PREG_W-1:0]         debug_otherPdest_5;
    logic [PREG_W-1:0]         debug_otherPdest_6;
  } rob_commit_t;

endpackage

module xs_Rob_core
  import rob_pkg::*;
(
  // BEGIN GENERATED(core_ports)
  input  logic         clock,
  input  logic         reset,
  input  logic [5:0]   io_hartId,
  input  logic         io_redirect_valid,
  input  logic         io_redirect_bits_robIdx_flag,
  input  logic [7:0]   io_redirect_bits_robIdx_value,
  input  logic         io_redirect_bits_level,
  input  logic         io_redirect_bits_cfiUpdate_isMisPred,
  output logic         io_enq_canAccept,
  output logic         io_enq_canAcceptForDispatch,
  output logic         io_enq_isEmpty,
  input  logic         io_enq_req_0_valid,
  input  logic [31:0]  io_enq_req_0_bits_instr,
  input  logic [49:0]  io_enq_req_0_bits_pc,
  input  logic         io_enq_req_0_bits_exceptionVec_0,
  input  logic         io_enq_req_0_bits_exceptionVec_1,
  input  logic         io_enq_req_0_bits_exceptionVec_2,
  input  logic         io_enq_req_0_bits_exceptionVec_3,
  input  logic         io_enq_req_0_bits_exceptionVec_12,
  input  logic         io_enq_req_0_bits_exceptionVec_20,
  input  logic         io_enq_req_0_bits_exceptionVec_22,
  input  logic         io_enq_req_0_bits_hasException,
  input  logic [3:0]   io_enq_req_0_bits_trigger,
  input  logic         io_enq_req_0_bits_preDecodeInfo_isRVC,
  input  logic         io_enq_req_0_bits_ftqPtr_flag,
  input  logic [5:0]   io_enq_req_0_bits_ftqPtr_value,
  input  logic [3:0]   io_enq_req_0_bits_ftqOffset,
  input  logic [5:0]   io_enq_req_0_bits_ldest,
  input  logic [34:0]  io_enq_req_0_bits_fuType,
  input  logic [8:0]   io_enq_req_0_bits_fuOpType,
  input  logic         io_enq_req_0_bits_rfWen,
  input  logic         io_enq_req_0_bits_fpWen,
  input  logic         io_enq_req_0_bits_vecWen,
  input  logic         io_enq_req_0_bits_v0Wen,
  input  logic         io_enq_req_0_bits_vlWen,
  input  logic         io_enq_req_0_bits_isXSTrap,
  input  logic         io_enq_req_0_bits_waitForward,
  input  logic         io_enq_req_0_bits_blockBackward,
  input  logic         io_enq_req_0_bits_flushPipe,
  input  logic         io_enq_req_0_bits_vlsInstr,
  input  logic         io_enq_req_0_bits_wfflags,
  input  logic         io_enq_req_0_bits_isVset,
  input  logic         io_enq_req_0_bits_firstUop,
  input  logic [6:0]   io_enq_req_0_bits_numWB,
  input  logic [2:0]   io_enq_req_0_bits_commitType,
  input  logic [7:0]   io_enq_req_0_bits_pdest,
  input  logic         io_enq_req_0_bits_robIdx_flag,
  input  logic [7:0]   io_enq_req_0_bits_robIdx_value,
  input  logic [2:0]   io_enq_req_0_bits_instrSize,
  input  logic         io_enq_req_0_bits_dirtyFs,
  input  logic         io_enq_req_0_bits_dirtyVs,
  input  logic [3:0]   io_enq_req_0_bits_traceBlockInPipe_itype,
  input  logic [3:0]   io_enq_req_0_bits_traceBlockInPipe_iretire,
  input  logic         io_enq_req_0_bits_traceBlockInPipe_ilastsize,
  input  logic         io_enq_req_0_bits_eliminatedMove,
  input  logic         io_enq_req_0_bits_snapshot,
  input  logic [63:0]  io_enq_req_0_bits_debugInfo_renameTime,
  input  logic [6:0]   io_enq_req_0_bits_lqIdx_value,
  input  logic [5:0]   io_enq_req_0_bits_sqIdx_value,
  input  logic [34:0]  io_enq_req_0_bits_debug_fuType,
  input  logic         io_enq_req_0_bits_debug_sim_trig,
  input  logic         io_enq_req_1_valid,
  input  logic [31:0]  io_enq_req_1_bits_instr,
  input  logic [49:0]  io_enq_req_1_bits_pc,
  input  logic         io_enq_req_1_bits_exceptionVec_0,
  input  logic         io_enq_req_1_bits_exceptionVec_1,
  input  logic         io_enq_req_1_bits_exceptionVec_2,
  input  logic         io_enq_req_1_bits_exceptionVec_3,
  input  logic         io_enq_req_1_bits_exceptionVec_12,
  input  logic         io_enq_req_1_bits_exceptionVec_20,
  input  logic         io_enq_req_1_bits_exceptionVec_22,
  input  logic         io_enq_req_1_bits_hasException,
  input  logic [3:0]   io_enq_req_1_bits_trigger,
  input  logic         io_enq_req_1_bits_preDecodeInfo_isRVC,
  input  logic         io_enq_req_1_bits_ftqPtr_flag,
  input  logic [5:0]   io_enq_req_1_bits_ftqPtr_value,
  input  logic [3:0]   io_enq_req_1_bits_ftqOffset,
  input  logic [5:0]   io_enq_req_1_bits_ldest,
  input  logic [34:0]  io_enq_req_1_bits_fuType,
  input  logic [8:0]   io_enq_req_1_bits_fuOpType,
  input  logic         io_enq_req_1_bits_rfWen,
  input  logic         io_enq_req_1_bits_fpWen,
  input  logic         io_enq_req_1_bits_vecWen,
  input  logic         io_enq_req_1_bits_v0Wen,
  input  logic         io_enq_req_1_bits_vlWen,
  input  logic         io_enq_req_1_bits_isXSTrap,
  input  logic         io_enq_req_1_bits_waitForward,
  input  logic         io_enq_req_1_bits_blockBackward,
  input  logic         io_enq_req_1_bits_flushPipe,
  input  logic         io_enq_req_1_bits_vlsInstr,
  input  logic         io_enq_req_1_bits_wfflags,
  input  logic         io_enq_req_1_bits_isVset,
  input  logic         io_enq_req_1_bits_firstUop,
  input  logic [6:0]   io_enq_req_1_bits_numWB,
  input  logic [2:0]   io_enq_req_1_bits_commitType,
  input  logic [7:0]   io_enq_req_1_bits_pdest,
  input  logic         io_enq_req_1_bits_robIdx_flag,
  input  logic [7:0]   io_enq_req_1_bits_robIdx_value,
  input  logic [2:0]   io_enq_req_1_bits_instrSize,
  input  logic         io_enq_req_1_bits_dirtyFs,
  input  logic         io_enq_req_1_bits_dirtyVs,
  input  logic [3:0]   io_enq_req_1_bits_traceBlockInPipe_itype,
  input  logic [3:0]   io_enq_req_1_bits_traceBlockInPipe_iretire,
  input  logic         io_enq_req_1_bits_traceBlockInPipe_ilastsize,
  input  logic         io_enq_req_1_bits_eliminatedMove,
  input  logic         io_enq_req_1_bits_snapshot,
  input  logic [63:0]  io_enq_req_1_bits_debugInfo_renameTime,
  input  logic [6:0]   io_enq_req_1_bits_lqIdx_value,
  input  logic [5:0]   io_enq_req_1_bits_sqIdx_value,
  input  logic [34:0]  io_enq_req_1_bits_debug_fuType,
  input  logic         io_enq_req_1_bits_debug_sim_trig,
  input  logic         io_enq_req_2_valid,
  input  logic [31:0]  io_enq_req_2_bits_instr,
  input  logic [49:0]  io_enq_req_2_bits_pc,
  input  logic         io_enq_req_2_bits_exceptionVec_0,
  input  logic         io_enq_req_2_bits_exceptionVec_1,
  input  logic         io_enq_req_2_bits_exceptionVec_2,
  input  logic         io_enq_req_2_bits_exceptionVec_3,
  input  logic         io_enq_req_2_bits_exceptionVec_12,
  input  logic         io_enq_req_2_bits_exceptionVec_20,
  input  logic         io_enq_req_2_bits_exceptionVec_22,
  input  logic         io_enq_req_2_bits_hasException,
  input  logic [3:0]   io_enq_req_2_bits_trigger,
  input  logic         io_enq_req_2_bits_preDecodeInfo_isRVC,
  input  logic         io_enq_req_2_bits_ftqPtr_flag,
  input  logic [5:0]   io_enq_req_2_bits_ftqPtr_value,
  input  logic [3:0]   io_enq_req_2_bits_ftqOffset,
  input  logic [5:0]   io_enq_req_2_bits_ldest,
  input  logic [34:0]  io_enq_req_2_bits_fuType,
  input  logic [8:0]   io_enq_req_2_bits_fuOpType,
  input  logic         io_enq_req_2_bits_rfWen,
  input  logic         io_enq_req_2_bits_fpWen,
  input  logic         io_enq_req_2_bits_vecWen,
  input  logic         io_enq_req_2_bits_v0Wen,
  input  logic         io_enq_req_2_bits_vlWen,
  input  logic         io_enq_req_2_bits_isXSTrap,
  input  logic         io_enq_req_2_bits_waitForward,
  input  logic         io_enq_req_2_bits_blockBackward,
  input  logic         io_enq_req_2_bits_flushPipe,
  input  logic         io_enq_req_2_bits_vlsInstr,
  input  logic         io_enq_req_2_bits_wfflags,
  input  logic         io_enq_req_2_bits_isVset,
  input  logic         io_enq_req_2_bits_firstUop,
  input  logic [6:0]   io_enq_req_2_bits_numWB,
  input  logic [2:0]   io_enq_req_2_bits_commitType,
  input  logic [7:0]   io_enq_req_2_bits_pdest,
  input  logic         io_enq_req_2_bits_robIdx_flag,
  input  logic [7:0]   io_enq_req_2_bits_robIdx_value,
  input  logic [2:0]   io_enq_req_2_bits_instrSize,
  input  logic         io_enq_req_2_bits_dirtyFs,
  input  logic         io_enq_req_2_bits_dirtyVs,
  input  logic [3:0]   io_enq_req_2_bits_traceBlockInPipe_itype,
  input  logic [3:0]   io_enq_req_2_bits_traceBlockInPipe_iretire,
  input  logic         io_enq_req_2_bits_traceBlockInPipe_ilastsize,
  input  logic         io_enq_req_2_bits_eliminatedMove,
  input  logic         io_enq_req_2_bits_snapshot,
  input  logic [63:0]  io_enq_req_2_bits_debugInfo_renameTime,
  input  logic [6:0]   io_enq_req_2_bits_lqIdx_value,
  input  logic [5:0]   io_enq_req_2_bits_sqIdx_value,
  input  logic [34:0]  io_enq_req_2_bits_debug_fuType,
  input  logic         io_enq_req_2_bits_debug_sim_trig,
  input  logic         io_enq_req_3_valid,
  input  logic [31:0]  io_enq_req_3_bits_instr,
  input  logic [49:0]  io_enq_req_3_bits_pc,
  input  logic         io_enq_req_3_bits_exceptionVec_0,
  input  logic         io_enq_req_3_bits_exceptionVec_1,
  input  logic         io_enq_req_3_bits_exceptionVec_2,
  input  logic         io_enq_req_3_bits_exceptionVec_3,
  input  logic         io_enq_req_3_bits_exceptionVec_12,
  input  logic         io_enq_req_3_bits_exceptionVec_20,
  input  logic         io_enq_req_3_bits_exceptionVec_22,
  input  logic         io_enq_req_3_bits_hasException,
  input  logic [3:0]   io_enq_req_3_bits_trigger,
  input  logic         io_enq_req_3_bits_preDecodeInfo_isRVC,
  input  logic         io_enq_req_3_bits_ftqPtr_flag,
  input  logic [5:0]   io_enq_req_3_bits_ftqPtr_value,
  input  logic [3:0]   io_enq_req_3_bits_ftqOffset,
  input  logic [5:0]   io_enq_req_3_bits_ldest,
  input  logic [34:0]  io_enq_req_3_bits_fuType,
  input  logic [8:0]   io_enq_req_3_bits_fuOpType,
  input  logic         io_enq_req_3_bits_rfWen,
  input  logic         io_enq_req_3_bits_fpWen,
  input  logic         io_enq_req_3_bits_vecWen,
  input  logic         io_enq_req_3_bits_v0Wen,
  input  logic         io_enq_req_3_bits_vlWen,
  input  logic         io_enq_req_3_bits_isXSTrap,
  input  logic         io_enq_req_3_bits_waitForward,
  input  logic         io_enq_req_3_bits_blockBackward,
  input  logic         io_enq_req_3_bits_flushPipe,
  input  logic         io_enq_req_3_bits_vlsInstr,
  input  logic         io_enq_req_3_bits_wfflags,
  input  logic         io_enq_req_3_bits_isVset,
  input  logic         io_enq_req_3_bits_firstUop,
  input  logic [6:0]   io_enq_req_3_bits_numWB,
  input  logic [2:0]   io_enq_req_3_bits_commitType,
  input  logic [7:0]   io_enq_req_3_bits_pdest,
  input  logic         io_enq_req_3_bits_robIdx_flag,
  input  logic [7:0]   io_enq_req_3_bits_robIdx_value,
  input  logic [2:0]   io_enq_req_3_bits_instrSize,
  input  logic         io_enq_req_3_bits_dirtyFs,
  input  logic         io_enq_req_3_bits_dirtyVs,
  input  logic [3:0]   io_enq_req_3_bits_traceBlockInPipe_itype,
  input  logic [3:0]   io_enq_req_3_bits_traceBlockInPipe_iretire,
  input  logic         io_enq_req_3_bits_traceBlockInPipe_ilastsize,
  input  logic         io_enq_req_3_bits_eliminatedMove,
  input  logic         io_enq_req_3_bits_snapshot,
  input  logic [63:0]  io_enq_req_3_bits_debugInfo_renameTime,
  input  logic [6:0]   io_enq_req_3_bits_lqIdx_value,
  input  logic [5:0]   io_enq_req_3_bits_sqIdx_value,
  input  logic [34:0]  io_enq_req_3_bits_debug_fuType,
  input  logic         io_enq_req_3_bits_debug_sim_trig,
  input  logic         io_enq_req_4_valid,
  input  logic [31:0]  io_enq_req_4_bits_instr,
  input  logic [49:0]  io_enq_req_4_bits_pc,
  input  logic         io_enq_req_4_bits_exceptionVec_0,
  input  logic         io_enq_req_4_bits_exceptionVec_1,
  input  logic         io_enq_req_4_bits_exceptionVec_2,
  input  logic         io_enq_req_4_bits_exceptionVec_3,
  input  logic         io_enq_req_4_bits_exceptionVec_12,
  input  logic         io_enq_req_4_bits_exceptionVec_20,
  input  logic         io_enq_req_4_bits_exceptionVec_22,
  input  logic         io_enq_req_4_bits_hasException,
  input  logic [3:0]   io_enq_req_4_bits_trigger,
  input  logic         io_enq_req_4_bits_preDecodeInfo_isRVC,
  input  logic         io_enq_req_4_bits_ftqPtr_flag,
  input  logic [5:0]   io_enq_req_4_bits_ftqPtr_value,
  input  logic [3:0]   io_enq_req_4_bits_ftqOffset,
  input  logic [5:0]   io_enq_req_4_bits_ldest,
  input  logic [34:0]  io_enq_req_4_bits_fuType,
  input  logic [8:0]   io_enq_req_4_bits_fuOpType,
  input  logic         io_enq_req_4_bits_rfWen,
  input  logic         io_enq_req_4_bits_fpWen,
  input  logic         io_enq_req_4_bits_vecWen,
  input  logic         io_enq_req_4_bits_v0Wen,
  input  logic         io_enq_req_4_bits_vlWen,
  input  logic         io_enq_req_4_bits_isXSTrap,
  input  logic         io_enq_req_4_bits_waitForward,
  input  logic         io_enq_req_4_bits_blockBackward,
  input  logic         io_enq_req_4_bits_flushPipe,
  input  logic         io_enq_req_4_bits_vlsInstr,
  input  logic         io_enq_req_4_bits_wfflags,
  input  logic         io_enq_req_4_bits_isVset,
  input  logic         io_enq_req_4_bits_firstUop,
  input  logic [6:0]   io_enq_req_4_bits_numWB,
  input  logic [2:0]   io_enq_req_4_bits_commitType,
  input  logic [7:0]   io_enq_req_4_bits_pdest,
  input  logic         io_enq_req_4_bits_robIdx_flag,
  input  logic [7:0]   io_enq_req_4_bits_robIdx_value,
  input  logic [2:0]   io_enq_req_4_bits_instrSize,
  input  logic         io_enq_req_4_bits_dirtyFs,
  input  logic         io_enq_req_4_bits_dirtyVs,
  input  logic [3:0]   io_enq_req_4_bits_traceBlockInPipe_itype,
  input  logic [3:0]   io_enq_req_4_bits_traceBlockInPipe_iretire,
  input  logic         io_enq_req_4_bits_traceBlockInPipe_ilastsize,
  input  logic         io_enq_req_4_bits_eliminatedMove,
  input  logic         io_enq_req_4_bits_snapshot,
  input  logic [63:0]  io_enq_req_4_bits_debugInfo_renameTime,
  input  logic [6:0]   io_enq_req_4_bits_lqIdx_value,
  input  logic [5:0]   io_enq_req_4_bits_sqIdx_value,
  input  logic [34:0]  io_enq_req_4_bits_debug_fuType,
  input  logic         io_enq_req_4_bits_debug_sim_trig,
  input  logic         io_enq_req_5_valid,
  input  logic [31:0]  io_enq_req_5_bits_instr,
  input  logic [49:0]  io_enq_req_5_bits_pc,
  input  logic         io_enq_req_5_bits_exceptionVec_0,
  input  logic         io_enq_req_5_bits_exceptionVec_1,
  input  logic         io_enq_req_5_bits_exceptionVec_2,
  input  logic         io_enq_req_5_bits_exceptionVec_3,
  input  logic         io_enq_req_5_bits_exceptionVec_12,
  input  logic         io_enq_req_5_bits_exceptionVec_20,
  input  logic         io_enq_req_5_bits_exceptionVec_22,
  input  logic         io_enq_req_5_bits_hasException,
  input  logic [3:0]   io_enq_req_5_bits_trigger,
  input  logic         io_enq_req_5_bits_preDecodeInfo_isRVC,
  input  logic         io_enq_req_5_bits_ftqPtr_flag,
  input  logic [5:0]   io_enq_req_5_bits_ftqPtr_value,
  input  logic [3:0]   io_enq_req_5_bits_ftqOffset,
  input  logic [5:0]   io_enq_req_5_bits_ldest,
  input  logic [34:0]  io_enq_req_5_bits_fuType,
  input  logic [8:0]   io_enq_req_5_bits_fuOpType,
  input  logic         io_enq_req_5_bits_rfWen,
  input  logic         io_enq_req_5_bits_fpWen,
  input  logic         io_enq_req_5_bits_vecWen,
  input  logic         io_enq_req_5_bits_v0Wen,
  input  logic         io_enq_req_5_bits_vlWen,
  input  logic         io_enq_req_5_bits_isXSTrap,
  input  logic         io_enq_req_5_bits_waitForward,
  input  logic         io_enq_req_5_bits_blockBackward,
  input  logic         io_enq_req_5_bits_flushPipe,
  input  logic         io_enq_req_5_bits_vlsInstr,
  input  logic         io_enq_req_5_bits_wfflags,
  input  logic         io_enq_req_5_bits_isVset,
  input  logic         io_enq_req_5_bits_firstUop,
  input  logic [6:0]   io_enq_req_5_bits_numWB,
  input  logic [2:0]   io_enq_req_5_bits_commitType,
  input  logic [7:0]   io_enq_req_5_bits_pdest,
  input  logic         io_enq_req_5_bits_robIdx_flag,
  input  logic [7:0]   io_enq_req_5_bits_robIdx_value,
  input  logic [2:0]   io_enq_req_5_bits_instrSize,
  input  logic         io_enq_req_5_bits_dirtyFs,
  input  logic         io_enq_req_5_bits_dirtyVs,
  input  logic [3:0]   io_enq_req_5_bits_traceBlockInPipe_itype,
  input  logic [3:0]   io_enq_req_5_bits_traceBlockInPipe_iretire,
  input  logic         io_enq_req_5_bits_traceBlockInPipe_ilastsize,
  input  logic         io_enq_req_5_bits_eliminatedMove,
  input  logic         io_enq_req_5_bits_snapshot,
  input  logic [63:0]  io_enq_req_5_bits_debugInfo_renameTime,
  input  logic [6:0]   io_enq_req_5_bits_lqIdx_value,
  input  logic [5:0]   io_enq_req_5_bits_sqIdx_value,
  input  logic [34:0]  io_enq_req_5_bits_debug_fuType,
  input  logic         io_enq_req_5_bits_debug_sim_trig,
  output logic         io_flushOut_valid,
  output logic         io_flushOut_bits_isRVC,
  output logic         io_flushOut_bits_robIdx_flag,
  output logic [7:0]   io_flushOut_bits_robIdx_value,
  output logic         io_flushOut_bits_ftqIdx_flag,
  output logic [5:0]   io_flushOut_bits_ftqIdx_value,
  output logic [3:0]   io_flushOut_bits_ftqOffset,
  output logic         io_flushOut_bits_level,
  output logic         io_flushOut_bits_satpFlush,
  output logic         io_flushOut_bits_isVlsException,
  output logic         io_exception_valid,
  output logic [31:0]  io_exception_bits_instr,
  output logic [2:0]   io_exception_bits_commitType,
  output logic         io_exception_bits_exceptionVec_0,
  output logic         io_exception_bits_exceptionVec_1,
  output logic         io_exception_bits_exceptionVec_2,
  output logic         io_exception_bits_exceptionVec_3,
  output logic         io_exception_bits_exceptionVec_4,
  output logic         io_exception_bits_exceptionVec_5,
  output logic         io_exception_bits_exceptionVec_6,
  output logic         io_exception_bits_exceptionVec_7,
  output logic         io_exception_bits_exceptionVec_8,
  output logic         io_exception_bits_exceptionVec_9,
  output logic         io_exception_bits_exceptionVec_10,
  output logic         io_exception_bits_exceptionVec_11,
  output logic         io_exception_bits_exceptionVec_12,
  output logic         io_exception_bits_exceptionVec_13,
  output logic         io_exception_bits_exceptionVec_14,
  output logic         io_exception_bits_exceptionVec_15,
  output logic         io_exception_bits_exceptionVec_16,
  output logic         io_exception_bits_exceptionVec_17,
  output logic         io_exception_bits_exceptionVec_18,
  output logic         io_exception_bits_exceptionVec_19,
  output logic         io_exception_bits_exceptionVec_20,
  output logic         io_exception_bits_exceptionVec_21,
  output logic         io_exception_bits_exceptionVec_22,
  output logic         io_exception_bits_exceptionVec_23,
  output logic         io_exception_bits_isPcBkpt,
  output logic         io_exception_bits_isFetchMalAddr,
  output logic         io_exception_bits_satpFlushFirstFetchFault,
  output logic [63:0]  io_exception_bits_gpaddr,
  output logic         io_exception_bits_singleStep,
  output logic         io_exception_bits_crossPageIPFFix,
  output logic         io_exception_bits_isInterrupt,
  output logic         io_exception_bits_isHls,
  output logic [3:0]   io_exception_bits_trigger,
  output logic         io_exception_bits_isForVSnonLeafPTE,
  input  logic         io_writeback_24_valid,
  input  logic [7:0]   io_writeback_24_bits_robIdx_value,
  input  logic         io_writeback_24_bits_exceptionVec_0,
  input  logic         io_writeback_24_bits_exceptionVec_1,
  input  logic         io_writeback_24_bits_exceptionVec_2,
  input  logic         io_writeback_24_bits_exceptionVec_3,
  input  logic         io_writeback_24_bits_exceptionVec_4,
  input  logic         io_writeback_24_bits_exceptionVec_5,
  input  logic         io_writeback_24_bits_exceptionVec_6,
  input  logic         io_writeback_24_bits_exceptionVec_7,
  input  logic         io_writeback_24_bits_exceptionVec_8,
  input  logic         io_writeback_24_bits_exceptionVec_9,
  input  logic         io_writeback_24_bits_exceptionVec_10,
  input  logic         io_writeback_24_bits_exceptionVec_11,
  input  logic         io_writeback_24_bits_exceptionVec_12,
  input  logic         io_writeback_24_bits_exceptionVec_13,
  input  logic         io_writeback_24_bits_exceptionVec_14,
  input  logic         io_writeback_24_bits_exceptionVec_15,
  input  logic         io_writeback_24_bits_exceptionVec_16,
  input  logic         io_writeback_24_bits_exceptionVec_17,
  input  logic         io_writeback_24_bits_exceptionVec_18,
  input  logic         io_writeback_24_bits_exceptionVec_19,
  input  logic         io_writeback_24_bits_exceptionVec_20,
  input  logic         io_writeback_24_bits_exceptionVec_21,
  input  logic         io_writeback_24_bits_exceptionVec_22,
  input  logic         io_writeback_24_bits_exceptionVec_23,
  input  logic [3:0]   io_writeback_24_bits_trigger,
  input  logic [7:0]   io_writeback_24_bits_vls_vpu_vstart,
  input  logic         io_writeback_23_valid,
  input  logic [7:0]   io_writeback_23_bits_robIdx_value,
  input  logic         io_writeback_23_bits_exceptionVec_0,
  input  logic         io_writeback_23_bits_exceptionVec_1,
  input  logic         io_writeback_23_bits_exceptionVec_2,
  input  logic         io_writeback_23_bits_exceptionVec_3,
  input  logic         io_writeback_23_bits_exceptionVec_4,
  input  logic         io_writeback_23_bits_exceptionVec_5,
  input  logic         io_writeback_23_bits_exceptionVec_6,
  input  logic         io_writeback_23_bits_exceptionVec_7,
  input  logic         io_writeback_23_bits_exceptionVec_8,
  input  logic         io_writeback_23_bits_exceptionVec_9,
  input  logic         io_writeback_23_bits_exceptionVec_10,
  input  logic         io_writeback_23_bits_exceptionVec_11,
  input  logic         io_writeback_23_bits_exceptionVec_12,
  input  logic         io_writeback_23_bits_exceptionVec_13,
  input  logic         io_writeback_23_bits_exceptionVec_14,
  input  logic         io_writeback_23_bits_exceptionVec_15,
  input  logic         io_writeback_23_bits_exceptionVec_16,
  input  logic         io_writeback_23_bits_exceptionVec_17,
  input  logic         io_writeback_23_bits_exceptionVec_18,
  input  logic         io_writeback_23_bits_exceptionVec_19,
  input  logic         io_writeback_23_bits_exceptionVec_20,
  input  logic         io_writeback_23_bits_exceptionVec_21,
  input  logic         io_writeback_23_bits_exceptionVec_22,
  input  logic         io_writeback_23_bits_exceptionVec_23,
  input  logic [3:0]   io_writeback_23_bits_trigger,
  input  logic [7:0]   io_writeback_23_bits_vls_vpu_vstart,
  input  logic         io_writeback_22_valid,
  input  logic [7:0]   io_writeback_22_bits_robIdx_value,
  input  logic         io_writeback_22_bits_exceptionVec_0,
  input  logic         io_writeback_22_bits_exceptionVec_1,
  input  logic         io_writeback_22_bits_exceptionVec_2,
  input  logic         io_writeback_22_bits_exceptionVec_3,
  input  logic         io_writeback_22_bits_exceptionVec_4,
  input  logic         io_writeback_22_bits_exceptionVec_5,
  input  logic         io_writeback_22_bits_exceptionVec_6,
  input  logic         io_writeback_22_bits_exceptionVec_7,
  input  logic         io_writeback_22_bits_exceptionVec_8,
  input  logic         io_writeback_22_bits_exceptionVec_9,
  input  logic         io_writeback_22_bits_exceptionVec_10,
  input  logic         io_writeback_22_bits_exceptionVec_11,
  input  logic         io_writeback_22_bits_exceptionVec_12,
  input  logic         io_writeback_22_bits_exceptionVec_13,
  input  logic         io_writeback_22_bits_exceptionVec_14,
  input  logic         io_writeback_22_bits_exceptionVec_15,
  input  logic         io_writeback_22_bits_exceptionVec_16,
  input  logic         io_writeback_22_bits_exceptionVec_17,
  input  logic         io_writeback_22_bits_exceptionVec_18,
  input  logic         io_writeback_22_bits_exceptionVec_19,
  input  logic         io_writeback_22_bits_exceptionVec_20,
  input  logic         io_writeback_22_bits_exceptionVec_21,
  input  logic         io_writeback_22_bits_exceptionVec_22,
  input  logic         io_writeback_22_bits_exceptionVec_23,
  input  logic         io_writeback_21_valid,
  input  logic [7:0]   io_writeback_21_bits_robIdx_value,
  input  logic         io_writeback_21_bits_exceptionVec_0,
  input  logic         io_writeback_21_bits_exceptionVec_1,
  input  logic         io_writeback_21_bits_exceptionVec_2,
  input  logic         io_writeback_21_bits_exceptionVec_3,
  input  logic         io_writeback_21_bits_exceptionVec_4,
  input  logic         io_writeback_21_bits_exceptionVec_5,
  input  logic         io_writeback_21_bits_exceptionVec_6,
  input  logic         io_writeback_21_bits_exceptionVec_7,
  input  logic         io_writeback_21_bits_exceptionVec_8,
  input  logic         io_writeback_21_bits_exceptionVec_9,
  input  logic         io_writeback_21_bits_exceptionVec_10,
  input  logic         io_writeback_21_bits_exceptionVec_11,
  input  logic         io_writeback_21_bits_exceptionVec_12,
  input  logic         io_writeback_21_bits_exceptionVec_13,
  input  logic         io_writeback_21_bits_exceptionVec_14,
  input  logic         io_writeback_21_bits_exceptionVec_15,
  input  logic         io_writeback_21_bits_exceptionVec_16,
  input  logic         io_writeback_21_bits_exceptionVec_17,
  input  logic         io_writeback_21_bits_exceptionVec_18,
  input  logic         io_writeback_21_bits_exceptionVec_19,
  input  logic         io_writeback_21_bits_exceptionVec_20,
  input  logic         io_writeback_21_bits_exceptionVec_21,
  input  logic         io_writeback_21_bits_exceptionVec_22,
  input  logic         io_writeback_21_bits_exceptionVec_23,
  input  logic         io_writeback_20_valid,
  input  logic [7:0]   io_writeback_20_bits_robIdx_value,
  input  logic         io_writeback_20_bits_exceptionVec_0,
  input  logic         io_writeback_20_bits_exceptionVec_1,
  input  logic         io_writeback_20_bits_exceptionVec_2,
  input  logic         io_writeback_20_bits_exceptionVec_3,
  input  logic         io_writeback_20_bits_exceptionVec_4,
  input  logic         io_writeback_20_bits_exceptionVec_5,
  input  logic         io_writeback_20_bits_exceptionVec_6,
  input  logic         io_writeback_20_bits_exceptionVec_7,
  input  logic         io_writeback_20_bits_exceptionVec_8,
  input  logic         io_writeback_20_bits_exceptionVec_9,
  input  logic         io_writeback_20_bits_exceptionVec_10,
  input  logic         io_writeback_20_bits_exceptionVec_11,
  input  logic         io_writeback_20_bits_exceptionVec_12,
  input  logic         io_writeback_20_bits_exceptionVec_13,
  input  logic         io_writeback_20_bits_exceptionVec_14,
  input  logic         io_writeback_20_bits_exceptionVec_15,
  input  logic         io_writeback_20_bits_exceptionVec_16,
  input  logic         io_writeback_20_bits_exceptionVec_17,
  input  logic         io_writeback_20_bits_exceptionVec_18,
  input  logic         io_writeback_20_bits_exceptionVec_19,
  input  logic         io_writeback_20_bits_exceptionVec_20,
  input  logic         io_writeback_20_bits_exceptionVec_21,
  input  logic         io_writeback_20_bits_exceptionVec_22,
  input  logic         io_writeback_20_bits_exceptionVec_23,
  input  logic         io_writeback_19_valid,
  input  logic [7:0]   io_writeback_19_bits_robIdx_value,
  input  logic         io_writeback_19_bits_exceptionVec_0,
  input  logic         io_writeback_19_bits_exceptionVec_1,
  input  logic         io_writeback_19_bits_exceptionVec_2,
  input  logic         io_writeback_19_bits_exceptionVec_3,
  input  logic         io_writeback_19_bits_exceptionVec_4,
  input  logic         io_writeback_19_bits_exceptionVec_5,
  input  logic         io_writeback_19_bits_exceptionVec_6,
  input  logic         io_writeback_19_bits_exceptionVec_7,
  input  logic         io_writeback_19_bits_exceptionVec_8,
  input  logic         io_writeback_19_bits_exceptionVec_9,
  input  logic         io_writeback_19_bits_exceptionVec_10,
  input  logic         io_writeback_19_bits_exceptionVec_11,
  input  logic         io_writeback_19_bits_exceptionVec_12,
  input  logic         io_writeback_19_bits_exceptionVec_13,
  input  logic         io_writeback_19_bits_exceptionVec_14,
  input  logic         io_writeback_19_bits_exceptionVec_15,
  input  logic         io_writeback_19_bits_exceptionVec_16,
  input  logic         io_writeback_19_bits_exceptionVec_17,
  input  logic         io_writeback_19_bits_exceptionVec_18,
  input  logic         io_writeback_19_bits_exceptionVec_19,
  input  logic         io_writeback_19_bits_exceptionVec_20,
  input  logic         io_writeback_19_bits_exceptionVec_21,
  input  logic         io_writeback_19_bits_exceptionVec_22,
  input  logic         io_writeback_19_bits_exceptionVec_23,
  input  logic         io_writeback_18_valid,
  input  logic [7:0]   io_writeback_18_bits_robIdx_value,
  input  logic         io_writeback_18_bits_exceptionVec_0,
  input  logic         io_writeback_18_bits_exceptionVec_1,
  input  logic         io_writeback_18_bits_exceptionVec_2,
  input  logic         io_writeback_18_bits_exceptionVec_3,
  input  logic         io_writeback_18_bits_exceptionVec_4,
  input  logic         io_writeback_18_bits_exceptionVec_5,
  input  logic         io_writeback_18_bits_exceptionVec_6,
  input  logic         io_writeback_18_bits_exceptionVec_7,
  input  logic         io_writeback_18_bits_exceptionVec_8,
  input  logic         io_writeback_18_bits_exceptionVec_9,
  input  logic         io_writeback_18_bits_exceptionVec_10,
  input  logic         io_writeback_18_bits_exceptionVec_11,
  input  logic         io_writeback_18_bits_exceptionVec_12,
  input  logic         io_writeback_18_bits_exceptionVec_13,
  input  logic         io_writeback_18_bits_exceptionVec_14,
  input  logic         io_writeback_18_bits_exceptionVec_15,
  input  logic         io_writeback_18_bits_exceptionVec_16,
  input  logic         io_writeback_18_bits_exceptionVec_17,
  input  logic         io_writeback_18_bits_exceptionVec_18,
  input  logic         io_writeback_18_bits_exceptionVec_19,
  input  logic         io_writeback_18_bits_exceptionVec_20,
  input  logic         io_writeback_18_bits_exceptionVec_21,
  input  logic         io_writeback_18_bits_exceptionVec_22,
  input  logic         io_writeback_18_bits_exceptionVec_23,
  input  logic         io_writeback_14_valid,
  input  logic [7:0]   io_writeback_14_bits_robIdx_value,
  input  logic         io_writeback_13_valid,
  input  logic [7:0]   io_writeback_13_bits_robIdx_value,
  input  logic         io_writeback_7_valid,
  input  logic [7:0]   io_writeback_7_bits_robIdx_value,
  input  logic         io_writeback_7_bits_redirect_valid,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_isMisPred,
  input  logic         io_writeback_7_bits_exceptionVec_2,
  input  logic         io_writeback_7_bits_exceptionVec_3,
  input  logic         io_writeback_7_bits_exceptionVec_8,
  input  logic         io_writeback_7_bits_exceptionVec_9,
  input  logic         io_writeback_7_bits_exceptionVec_10,
  input  logic         io_writeback_7_bits_exceptionVec_11,
  input  logic         io_writeback_7_bits_exceptionVec_22,
  input  logic         io_writeback_5_valid,
  input  logic         io_writeback_5_bits_redirect_valid,
  input  logic         io_writeback_5_bits_redirect_bits_cfiUpdate_isMisPred,
  input  logic         io_writeback_3_valid,
  input  logic         io_writeback_3_bits_redirect_valid,
  input  logic         io_writeback_3_bits_redirect_bits_cfiUpdate_isMisPred,
  input  logic         io_writeback_1_valid,
  input  logic         io_writeback_1_bits_redirect_valid,
  input  logic         io_writeback_1_bits_redirect_bits_cfiUpdate_isMisPred,
  input  logic         io_exuWriteback_26_valid,
  input  logic [7:0]   io_exuWriteback_26_bits_robIdx_value,
  input  logic         io_exuWriteback_25_valid,
  input  logic [7:0]   io_exuWriteback_25_bits_robIdx_value,
  input  logic         io_exuWriteback_24_valid,
  input  logic [127:0] io_exuWriteback_24_bits_data_0,
  input  logic [6:0]   io_exuWriteback_24_bits_pdest,
  input  logic [7:0]   io_exuWriteback_24_bits_robIdx_value,
  input  logic         io_exuWriteback_24_bits_vecWen,
  input  logic         io_exuWriteback_24_bits_v0Wen,
  input  logic [2:0]   io_exuWriteback_24_bits_vls_vdIdx,
  input  logic         io_exuWriteback_24_bits_debug_isMMIO,
  input  logic         io_exuWriteback_24_bits_debug_isNCIO,
  input  logic         io_exuWriteback_24_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_24_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_24_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_24_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_24_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_24_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_23_valid,
  input  logic [127:0] io_exuWriteback_23_bits_data_0,
  input  logic [6:0]   io_exuWriteback_23_bits_pdest,
  input  logic [7:0]   io_exuWriteback_23_bits_robIdx_value,
  input  logic         io_exuWriteback_23_bits_vecWen,
  input  logic         io_exuWriteback_23_bits_v0Wen,
  input  logic [2:0]   io_exuWriteback_23_bits_vls_vdIdx,
  input  logic         io_exuWriteback_23_bits_debug_isMMIO,
  input  logic         io_exuWriteback_23_bits_debug_isNCIO,
  input  logic         io_exuWriteback_23_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_23_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_23_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_23_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_23_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_23_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_22_valid,
  input  logic [63:0]  io_exuWriteback_22_bits_data_0,
  input  logic [7:0]   io_exuWriteback_22_bits_robIdx_value,
  input  logic [6:0]   io_exuWriteback_22_bits_lqIdx_value,
  input  logic         io_exuWriteback_22_bits_debug_isMMIO,
  input  logic         io_exuWriteback_22_bits_debug_isNCIO,
  input  logic         io_exuWriteback_22_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_22_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_22_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_22_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_22_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_22_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_21_valid,
  input  logic [63:0]  io_exuWriteback_21_bits_data_0,
  input  logic [7:0]   io_exuWriteback_21_bits_robIdx_value,
  input  logic [6:0]   io_exuWriteback_21_bits_lqIdx_value,
  input  logic         io_exuWriteback_21_bits_debug_isMMIO,
  input  logic         io_exuWriteback_21_bits_debug_isNCIO,
  input  logic         io_exuWriteback_21_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_21_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_21_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_21_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_21_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_21_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_20_valid,
  input  logic [63:0]  io_exuWriteback_20_bits_data_0,
  input  logic [7:0]   io_exuWriteback_20_bits_robIdx_value,
  input  logic [6:0]   io_exuWriteback_20_bits_lqIdx_value,
  input  logic         io_exuWriteback_20_bits_debug_isMMIO,
  input  logic         io_exuWriteback_20_bits_debug_isNCIO,
  input  logic         io_exuWriteback_20_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_20_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_20_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_20_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_20_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_20_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_19_valid,
  input  logic [63:0]  io_exuWriteback_19_bits_data_0,
  input  logic [7:0]   io_exuWriteback_19_bits_robIdx_value,
  input  logic [5:0]   io_exuWriteback_19_bits_sqIdx_value,
  input  logic         io_exuWriteback_19_bits_debug_isMMIO,
  input  logic         io_exuWriteback_19_bits_debug_isNCIO,
  input  logic         io_exuWriteback_19_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_19_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_19_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_19_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_19_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_19_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_18_valid,
  input  logic [63:0]  io_exuWriteback_18_bits_data_0,
  input  logic [7:0]   io_exuWriteback_18_bits_robIdx_value,
  input  logic [5:0]   io_exuWriteback_18_bits_sqIdx_value,
  input  logic         io_exuWriteback_18_bits_debug_isMMIO,
  input  logic         io_exuWriteback_18_bits_debug_isNCIO,
  input  logic         io_exuWriteback_18_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_18_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_18_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_18_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_18_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_18_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_17_valid,
  input  logic [127:0] io_exuWriteback_17_bits_data_0,
  input  logic [7:0]   io_exuWriteback_17_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_17_bits_fflags,
  input  logic         io_exuWriteback_17_bits_wflags,
  input  logic [63:0]  io_exuWriteback_17_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_17_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_17_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_17_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_16_valid,
  input  logic [127:0] io_exuWriteback_16_bits_data_0,
  input  logic [7:0]   io_exuWriteback_16_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_16_bits_fflags,
  input  logic         io_exuWriteback_16_bits_wflags,
  input  logic [63:0]  io_exuWriteback_16_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_16_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_16_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_16_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_15_valid,
  input  logic [127:0] io_exuWriteback_15_bits_data_0,
  input  logic [7:0]   io_exuWriteback_15_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_15_bits_fflags,
  input  logic         io_exuWriteback_15_bits_wflags,
  input  logic         io_exuWriteback_15_bits_vxsat,
  input  logic [63:0]  io_exuWriteback_15_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_15_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_15_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_15_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_14_valid,
  input  logic [127:0] io_exuWriteback_14_bits_data_0,
  input  logic [7:0]   io_exuWriteback_14_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_14_bits_fflags,
  input  logic         io_exuWriteback_14_bits_wflags,
  input  logic [63:0]  io_exuWriteback_14_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_14_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_14_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_14_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_13_valid,
  input  logic [127:0] io_exuWriteback_13_bits_data_0,
  input  logic [7:0]   io_exuWriteback_13_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_13_bits_fflags,
  input  logic         io_exuWriteback_13_bits_wflags,
  input  logic         io_exuWriteback_13_bits_vxsat,
  input  logic [63:0]  io_exuWriteback_13_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_13_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_13_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_13_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_12_valid,
  input  logic [63:0]  io_exuWriteback_12_bits_data_0,
  input  logic [7:0]   io_exuWriteback_12_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_12_bits_fflags,
  input  logic         io_exuWriteback_12_bits_wflags,
  input  logic [63:0]  io_exuWriteback_12_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_12_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_12_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_12_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_11_valid,
  input  logic [63:0]  io_exuWriteback_11_bits_data_0,
  input  logic [7:0]   io_exuWriteback_11_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_11_bits_fflags,
  input  logic         io_exuWriteback_11_bits_wflags,
  input  logic [63:0]  io_exuWriteback_11_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_11_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_11_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_11_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_10_valid,
  input  logic [63:0]  io_exuWriteback_10_bits_data_0,
  input  logic [7:0]   io_exuWriteback_10_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_10_bits_fflags,
  input  logic         io_exuWriteback_10_bits_wflags,
  input  logic [63:0]  io_exuWriteback_10_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_10_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_10_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_10_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_9_valid,
  input  logic [63:0]  io_exuWriteback_9_bits_data_0,
  input  logic [7:0]   io_exuWriteback_9_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_9_bits_fflags,
  input  logic         io_exuWriteback_9_bits_wflags,
  input  logic [63:0]  io_exuWriteback_9_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_9_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_9_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_9_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_8_valid,
  input  logic [127:0] io_exuWriteback_8_bits_data_0,
  input  logic [7:0]   io_exuWriteback_8_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_8_bits_fflags,
  input  logic         io_exuWriteback_8_bits_wflags,
  input  logic [63:0]  io_exuWriteback_8_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_8_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_8_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_8_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_7_valid,
  input  logic [63:0]  io_exuWriteback_7_bits_data_0,
  input  logic [7:0]   io_exuWriteback_7_bits_robIdx_value,
  input  logic         io_exuWriteback_7_bits_debug_isPerfCnt,
  input  logic [63:0]  io_exuWriteback_7_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_7_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_7_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_7_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_6_valid,
  input  logic [63:0]  io_exuWriteback_6_bits_data_0,
  input  logic [7:0]   io_exuWriteback_6_bits_robIdx_value,
  input  logic [63:0]  io_exuWriteback_6_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_6_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_6_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_6_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_5_valid,
  input  logic [127:0] io_exuWriteback_5_bits_data_0,
  input  logic [7:0]   io_exuWriteback_5_bits_robIdx_value,
  input  logic         io_exuWriteback_5_bits_redirect_bits_cfiUpdate_taken,
  input  logic [4:0]   io_exuWriteback_5_bits_fflags,
  input  logic         io_exuWriteback_5_bits_wflags,
  input  logic [63:0]  io_exuWriteback_5_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_5_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_5_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_5_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_4_valid,
  input  logic [63:0]  io_exuWriteback_4_bits_data_0,
  input  logic [7:0]   io_exuWriteback_4_bits_robIdx_value,
  input  logic [63:0]  io_exuWriteback_4_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_4_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_4_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_4_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_3_valid,
  input  logic [63:0]  io_exuWriteback_3_bits_data_0,
  input  logic [7:0]   io_exuWriteback_3_bits_robIdx_value,
  input  logic         io_exuWriteback_3_bits_redirect_bits_cfiUpdate_taken,
  input  logic [63:0]  io_exuWriteback_3_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_3_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_3_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_3_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_2_valid,
  input  logic [63:0]  io_exuWriteback_2_bits_data_0,
  input  logic [7:0]   io_exuWriteback_2_bits_robIdx_value,
  input  logic [63:0]  io_exuWriteback_2_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_2_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_2_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_2_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_1_valid,
  input  logic [63:0]  io_exuWriteback_1_bits_data_0,
  input  logic [7:0]   io_exuWriteback_1_bits_robIdx_value,
  input  logic         io_exuWriteback_1_bits_redirect_bits_cfiUpdate_taken,
  input  logic [63:0]  io_exuWriteback_1_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_1_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_1_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_1_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_0_valid,
  input  logic [63:0]  io_exuWriteback_0_bits_data_0,
  input  logic [7:0]   io_exuWriteback_0_bits_robIdx_value,
  input  logic [63:0]  io_exuWriteback_0_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_0_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_0_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_0_bits_debugInfo_writebackTime,
  input  logic [4:0]   io_writebackNums_0_bits,
  input  logic [4:0]   io_writebackNums_1_bits,
  input  logic [4:0]   io_writebackNums_2_bits,
  input  logic [4:0]   io_writebackNums_3_bits,
  input  logic [4:0]   io_writebackNums_4_bits,
  input  logic [4:0]   io_writebackNums_5_bits,
  input  logic [4:0]   io_writebackNums_6_bits,
  input  logic [4:0]   io_writebackNums_7_bits,
  input  logic [4:0]   io_writebackNums_8_bits,
  input  logic [4:0]   io_writebackNums_9_bits,
  input  logic [4:0]   io_writebackNums_10_bits,
  input  logic [4:0]   io_writebackNums_11_bits,
  input  logic [4:0]   io_writebackNums_12_bits,
  input  logic [4:0]   io_writebackNums_13_bits,
  input  logic [4:0]   io_writebackNums_14_bits,
  input  logic [4:0]   io_writebackNums_15_bits,
  input  logic [4:0]   io_writebackNums_16_bits,
  input  logic [4:0]   io_writebackNums_17_bits,
  input  logic [4:0]   io_writebackNums_18_bits,
  input  logic [4:0]   io_writebackNums_19_bits,
  input  logic [4:0]   io_writebackNums_20_bits,
  input  logic [4:0]   io_writebackNums_21_bits,
  input  logic [4:0]   io_writebackNums_22_bits,
  input  logic [4:0]   io_writebackNums_23_bits,
  input  logic [4:0]   io_writebackNums_24_bits,
  input  logic         io_writebackNeedFlush_0,
  input  logic         io_writebackNeedFlush_1,
  input  logic         io_writebackNeedFlush_2,
  input  logic         io_writebackNeedFlush_6,
  input  logic         io_writebackNeedFlush_7,
  input  logic         io_writebackNeedFlush_8,
  input  logic         io_writebackNeedFlush_9,
  input  logic         io_writebackNeedFlush_10,
  input  logic         io_writebackNeedFlush_11,
  input  logic         io_writebackNeedFlush_12,
  output logic         io_commits_isCommit,
  output logic         io_commits_commitValid_0,
  output logic         io_commits_commitValid_1,
  output logic         io_commits_commitValid_2,
  output logic         io_commits_commitValid_3,
  output logic         io_commits_commitValid_4,
  output logic         io_commits_commitValid_5,
  output logic         io_commits_commitValid_6,
  output logic         io_commits_commitValid_7,
  output logic         io_commits_isWalk,
  output logic         io_commits_walkValid_0,
  output logic         io_commits_walkValid_1,
  output logic         io_commits_walkValid_2,
  output logic         io_commits_walkValid_3,
  output logic         io_commits_walkValid_4,
  output logic         io_commits_walkValid_5,
  output logic         io_commits_walkValid_6,
  output logic         io_commits_walkValid_7,
  output logic         io_commits_info_0_walk_v,
  output logic         io_commits_info_0_commit_v,
  output logic         io_commits_info_0_commit_w,
  output logic [6:0]   io_commits_info_0_realDestSize,
  output logic         io_commits_info_0_interrupt_safe,
  output logic         io_commits_info_0_wflags,
  output logic [4:0]   io_commits_info_0_fflags,
  output logic         io_commits_info_0_vxsat,
  output logic         io_commits_info_0_isRVC,
  output logic         io_commits_info_0_isVset,
  output logic         io_commits_info_0_isHls,
  output logic         io_commits_info_0_isVls,
  output logic         io_commits_info_0_vls,
  output logic         io_commits_info_0_mmio,
  output logic [2:0]   io_commits_info_0_commitType,
  output logic         io_commits_info_0_ftqIdx_flag,
  output logic [5:0]   io_commits_info_0_ftqIdx_value,
  output logic [3:0]   io_commits_info_0_ftqOffset,
  output logic [2:0]   io_commits_info_0_instrSize,
  output logic         io_commits_info_0_fpWen,
  output logic         io_commits_info_0_rfWen,
  output logic         io_commits_info_0_needFlush,
  output logic [3:0]   io_commits_info_0_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_0_traceBlockInPipe_iretire,
  output logic         io_commits_info_0_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_0_debug_pc,
  output logic [31:0]  io_commits_info_0_debug_instr,
  output logic [5:0]   io_commits_info_0_basicDebug_ldest,
  output logic [7:0]   io_commits_info_0_basicDebug_pdest,
  output logic [5:0]   io_commits_info_0_basicDebug_vd,
  output logic         io_commits_info_0_basicDebug_fpWen,
  output logic         io_commits_info_0_basicDebug_vecWen,
  output logic         io_commits_info_0_basicDebug_v0Wen,
  output logic         io_commits_info_0_basicDebug_eliminatedMove,
  output logic         io_commits_info_0_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_0_debug_fuType,
  output logic         io_commits_info_0_dirtyFs,
  output logic         io_commits_info_0_dirtyVs,
  output logic         io_commits_info_1_walk_v,
  output logic         io_commits_info_1_commit_v,
  output logic         io_commits_info_1_commit_w,
  output logic [6:0]   io_commits_info_1_realDestSize,
  output logic         io_commits_info_1_interrupt_safe,
  output logic         io_commits_info_1_wflags,
  output logic [4:0]   io_commits_info_1_fflags,
  output logic         io_commits_info_1_vxsat,
  output logic         io_commits_info_1_isRVC,
  output logic         io_commits_info_1_isVset,
  output logic         io_commits_info_1_isHls,
  output logic         io_commits_info_1_isVls,
  output logic         io_commits_info_1_vls,
  output logic         io_commits_info_1_mmio,
  output logic [2:0]   io_commits_info_1_commitType,
  output logic         io_commits_info_1_ftqIdx_flag,
  output logic [5:0]   io_commits_info_1_ftqIdx_value,
  output logic [3:0]   io_commits_info_1_ftqOffset,
  output logic [2:0]   io_commits_info_1_instrSize,
  output logic         io_commits_info_1_fpWen,
  output logic         io_commits_info_1_rfWen,
  output logic         io_commits_info_1_needFlush,
  output logic [3:0]   io_commits_info_1_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_1_traceBlockInPipe_iretire,
  output logic         io_commits_info_1_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_1_debug_pc,
  output logic [31:0]  io_commits_info_1_debug_instr,
  output logic [5:0]   io_commits_info_1_basicDebug_ldest,
  output logic [7:0]   io_commits_info_1_basicDebug_pdest,
  output logic [5:0]   io_commits_info_1_basicDebug_vd,
  output logic         io_commits_info_1_basicDebug_fpWen,
  output logic         io_commits_info_1_basicDebug_vecWen,
  output logic         io_commits_info_1_basicDebug_v0Wen,
  output logic         io_commits_info_1_basicDebug_eliminatedMove,
  output logic         io_commits_info_1_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_1_debug_fuType,
  output logic         io_commits_info_1_dirtyFs,
  output logic         io_commits_info_1_dirtyVs,
  output logic         io_commits_info_2_walk_v,
  output logic         io_commits_info_2_commit_v,
  output logic         io_commits_info_2_commit_w,
  output logic [6:0]   io_commits_info_2_realDestSize,
  output logic         io_commits_info_2_interrupt_safe,
  output logic         io_commits_info_2_wflags,
  output logic [4:0]   io_commits_info_2_fflags,
  output logic         io_commits_info_2_vxsat,
  output logic         io_commits_info_2_isRVC,
  output logic         io_commits_info_2_isVset,
  output logic         io_commits_info_2_isHls,
  output logic         io_commits_info_2_isVls,
  output logic         io_commits_info_2_vls,
  output logic         io_commits_info_2_mmio,
  output logic [2:0]   io_commits_info_2_commitType,
  output logic         io_commits_info_2_ftqIdx_flag,
  output logic [5:0]   io_commits_info_2_ftqIdx_value,
  output logic [3:0]   io_commits_info_2_ftqOffset,
  output logic [2:0]   io_commits_info_2_instrSize,
  output logic         io_commits_info_2_fpWen,
  output logic         io_commits_info_2_rfWen,
  output logic         io_commits_info_2_needFlush,
  output logic [3:0]   io_commits_info_2_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_2_traceBlockInPipe_iretire,
  output logic         io_commits_info_2_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_2_debug_pc,
  output logic [31:0]  io_commits_info_2_debug_instr,
  output logic [5:0]   io_commits_info_2_basicDebug_ldest,
  output logic [7:0]   io_commits_info_2_basicDebug_pdest,
  output logic [5:0]   io_commits_info_2_basicDebug_vd,
  output logic         io_commits_info_2_basicDebug_fpWen,
  output logic         io_commits_info_2_basicDebug_vecWen,
  output logic         io_commits_info_2_basicDebug_v0Wen,
  output logic         io_commits_info_2_basicDebug_eliminatedMove,
  output logic         io_commits_info_2_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_2_debug_fuType,
  output logic         io_commits_info_2_dirtyFs,
  output logic         io_commits_info_2_dirtyVs,
  output logic         io_commits_info_3_walk_v,
  output logic         io_commits_info_3_commit_v,
  output logic         io_commits_info_3_commit_w,
  output logic [6:0]   io_commits_info_3_realDestSize,
  output logic         io_commits_info_3_interrupt_safe,
  output logic         io_commits_info_3_wflags,
  output logic [4:0]   io_commits_info_3_fflags,
  output logic         io_commits_info_3_vxsat,
  output logic         io_commits_info_3_isRVC,
  output logic         io_commits_info_3_isVset,
  output logic         io_commits_info_3_isHls,
  output logic         io_commits_info_3_isVls,
  output logic         io_commits_info_3_vls,
  output logic         io_commits_info_3_mmio,
  output logic [2:0]   io_commits_info_3_commitType,
  output logic         io_commits_info_3_ftqIdx_flag,
  output logic [5:0]   io_commits_info_3_ftqIdx_value,
  output logic [3:0]   io_commits_info_3_ftqOffset,
  output logic [2:0]   io_commits_info_3_instrSize,
  output logic         io_commits_info_3_fpWen,
  output logic         io_commits_info_3_rfWen,
  output logic         io_commits_info_3_needFlush,
  output logic [3:0]   io_commits_info_3_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_3_traceBlockInPipe_iretire,
  output logic         io_commits_info_3_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_3_debug_pc,
  output logic [31:0]  io_commits_info_3_debug_instr,
  output logic [5:0]   io_commits_info_3_basicDebug_ldest,
  output logic [7:0]   io_commits_info_3_basicDebug_pdest,
  output logic [5:0]   io_commits_info_3_basicDebug_vd,
  output logic         io_commits_info_3_basicDebug_fpWen,
  output logic         io_commits_info_3_basicDebug_vecWen,
  output logic         io_commits_info_3_basicDebug_v0Wen,
  output logic         io_commits_info_3_basicDebug_eliminatedMove,
  output logic         io_commits_info_3_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_3_debug_fuType,
  output logic         io_commits_info_3_dirtyFs,
  output logic         io_commits_info_3_dirtyVs,
  output logic         io_commits_info_4_walk_v,
  output logic         io_commits_info_4_commit_v,
  output logic         io_commits_info_4_commit_w,
  output logic [6:0]   io_commits_info_4_realDestSize,
  output logic         io_commits_info_4_interrupt_safe,
  output logic         io_commits_info_4_wflags,
  output logic [4:0]   io_commits_info_4_fflags,
  output logic         io_commits_info_4_vxsat,
  output logic         io_commits_info_4_isRVC,
  output logic         io_commits_info_4_isVset,
  output logic         io_commits_info_4_isHls,
  output logic         io_commits_info_4_isVls,
  output logic         io_commits_info_4_vls,
  output logic         io_commits_info_4_mmio,
  output logic [2:0]   io_commits_info_4_commitType,
  output logic         io_commits_info_4_ftqIdx_flag,
  output logic [5:0]   io_commits_info_4_ftqIdx_value,
  output logic [3:0]   io_commits_info_4_ftqOffset,
  output logic [2:0]   io_commits_info_4_instrSize,
  output logic         io_commits_info_4_fpWen,
  output logic         io_commits_info_4_rfWen,
  output logic         io_commits_info_4_needFlush,
  output logic [3:0]   io_commits_info_4_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_4_traceBlockInPipe_iretire,
  output logic         io_commits_info_4_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_4_debug_pc,
  output logic [31:0]  io_commits_info_4_debug_instr,
  output logic [5:0]   io_commits_info_4_basicDebug_ldest,
  output logic [7:0]   io_commits_info_4_basicDebug_pdest,
  output logic [5:0]   io_commits_info_4_basicDebug_vd,
  output logic         io_commits_info_4_basicDebug_fpWen,
  output logic         io_commits_info_4_basicDebug_vecWen,
  output logic         io_commits_info_4_basicDebug_v0Wen,
  output logic         io_commits_info_4_basicDebug_eliminatedMove,
  output logic         io_commits_info_4_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_4_debug_fuType,
  output logic         io_commits_info_4_dirtyFs,
  output logic         io_commits_info_4_dirtyVs,
  output logic         io_commits_info_5_walk_v,
  output logic         io_commits_info_5_commit_v,
  output logic         io_commits_info_5_commit_w,
  output logic [6:0]   io_commits_info_5_realDestSize,
  output logic         io_commits_info_5_interrupt_safe,
  output logic         io_commits_info_5_wflags,
  output logic [4:0]   io_commits_info_5_fflags,
  output logic         io_commits_info_5_vxsat,
  output logic         io_commits_info_5_isRVC,
  output logic         io_commits_info_5_isVset,
  output logic         io_commits_info_5_isHls,
  output logic         io_commits_info_5_isVls,
  output logic         io_commits_info_5_vls,
  output logic         io_commits_info_5_mmio,
  output logic [2:0]   io_commits_info_5_commitType,
  output logic         io_commits_info_5_ftqIdx_flag,
  output logic [5:0]   io_commits_info_5_ftqIdx_value,
  output logic [3:0]   io_commits_info_5_ftqOffset,
  output logic [2:0]   io_commits_info_5_instrSize,
  output logic         io_commits_info_5_fpWen,
  output logic         io_commits_info_5_rfWen,
  output logic         io_commits_info_5_needFlush,
  output logic [3:0]   io_commits_info_5_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_5_traceBlockInPipe_iretire,
  output logic         io_commits_info_5_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_5_debug_pc,
  output logic [31:0]  io_commits_info_5_debug_instr,
  output logic [5:0]   io_commits_info_5_basicDebug_ldest,
  output logic [7:0]   io_commits_info_5_basicDebug_pdest,
  output logic [5:0]   io_commits_info_5_basicDebug_vd,
  output logic         io_commits_info_5_basicDebug_fpWen,
  output logic         io_commits_info_5_basicDebug_vecWen,
  output logic         io_commits_info_5_basicDebug_v0Wen,
  output logic         io_commits_info_5_basicDebug_eliminatedMove,
  output logic         io_commits_info_5_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_5_debug_fuType,
  output logic         io_commits_info_5_dirtyFs,
  output logic         io_commits_info_5_dirtyVs,
  output logic         io_commits_info_6_walk_v,
  output logic         io_commits_info_6_commit_v,
  output logic         io_commits_info_6_commit_w,
  output logic [6:0]   io_commits_info_6_realDestSize,
  output logic         io_commits_info_6_interrupt_safe,
  output logic         io_commits_info_6_wflags,
  output logic [4:0]   io_commits_info_6_fflags,
  output logic         io_commits_info_6_vxsat,
  output logic         io_commits_info_6_isRVC,
  output logic         io_commits_info_6_isVset,
  output logic         io_commits_info_6_isHls,
  output logic         io_commits_info_6_isVls,
  output logic         io_commits_info_6_vls,
  output logic         io_commits_info_6_mmio,
  output logic [2:0]   io_commits_info_6_commitType,
  output logic         io_commits_info_6_ftqIdx_flag,
  output logic [5:0]   io_commits_info_6_ftqIdx_value,
  output logic [3:0]   io_commits_info_6_ftqOffset,
  output logic [2:0]   io_commits_info_6_instrSize,
  output logic         io_commits_info_6_fpWen,
  output logic         io_commits_info_6_rfWen,
  output logic         io_commits_info_6_needFlush,
  output logic [3:0]   io_commits_info_6_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_6_traceBlockInPipe_iretire,
  output logic         io_commits_info_6_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_6_debug_pc,
  output logic [31:0]  io_commits_info_6_debug_instr,
  output logic [5:0]   io_commits_info_6_basicDebug_ldest,
  output logic [7:0]   io_commits_info_6_basicDebug_pdest,
  output logic [5:0]   io_commits_info_6_basicDebug_vd,
  output logic         io_commits_info_6_basicDebug_fpWen,
  output logic         io_commits_info_6_basicDebug_vecWen,
  output logic         io_commits_info_6_basicDebug_v0Wen,
  output logic         io_commits_info_6_basicDebug_eliminatedMove,
  output logic         io_commits_info_6_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_6_debug_fuType,
  output logic         io_commits_info_6_dirtyFs,
  output logic         io_commits_info_6_dirtyVs,
  output logic         io_commits_info_7_walk_v,
  output logic         io_commits_info_7_commit_v,
  output logic         io_commits_info_7_commit_w,
  output logic [6:0]   io_commits_info_7_realDestSize,
  output logic         io_commits_info_7_interrupt_safe,
  output logic         io_commits_info_7_wflags,
  output logic [4:0]   io_commits_info_7_fflags,
  output logic         io_commits_info_7_vxsat,
  output logic         io_commits_info_7_isRVC,
  output logic         io_commits_info_7_isVset,
  output logic         io_commits_info_7_isHls,
  output logic         io_commits_info_7_isVls,
  output logic         io_commits_info_7_vls,
  output logic         io_commits_info_7_mmio,
  output logic [2:0]   io_commits_info_7_commitType,
  output logic         io_commits_info_7_ftqIdx_flag,
  output logic [5:0]   io_commits_info_7_ftqIdx_value,
  output logic [3:0]   io_commits_info_7_ftqOffset,
  output logic [2:0]   io_commits_info_7_instrSize,
  output logic         io_commits_info_7_fpWen,
  output logic         io_commits_info_7_rfWen,
  output logic         io_commits_info_7_needFlush,
  output logic [3:0]   io_commits_info_7_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_7_traceBlockInPipe_iretire,
  output logic         io_commits_info_7_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_7_debug_pc,
  output logic [31:0]  io_commits_info_7_debug_instr,
  output logic [5:0]   io_commits_info_7_basicDebug_ldest,
  output logic [7:0]   io_commits_info_7_basicDebug_pdest,
  output logic [5:0]   io_commits_info_7_basicDebug_vd,
  output logic         io_commits_info_7_basicDebug_fpWen,
  output logic         io_commits_info_7_basicDebug_vecWen,
  output logic         io_commits_info_7_basicDebug_v0Wen,
  output logic         io_commits_info_7_basicDebug_eliminatedMove,
  output logic         io_commits_info_7_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_7_debug_fuType,
  output logic         io_commits_info_7_dirtyFs,
  output logic         io_commits_info_7_dirtyVs,
  output logic         io_commits_robIdx_0_flag,
  output logic [7:0]   io_commits_robIdx_0_value,
  output logic         io_commits_robIdx_1_flag,
  output logic [7:0]   io_commits_robIdx_1_value,
  output logic         io_commits_robIdx_2_flag,
  output logic [7:0]   io_commits_robIdx_2_value,
  output logic         io_commits_robIdx_3_flag,
  output logic [7:0]   io_commits_robIdx_3_value,
  output logic         io_commits_robIdx_4_flag,
  output logic [7:0]   io_commits_robIdx_4_value,
  output logic         io_commits_robIdx_5_flag,
  output logic [7:0]   io_commits_robIdx_5_value,
  output logic         io_commits_robIdx_6_flag,
  output logic [7:0]   io_commits_robIdx_6_value,
  output logic         io_commits_robIdx_7_flag,
  output logic [7:0]   io_commits_robIdx_7_value,
  input  logic         io_trace_blockCommit,
  output logic         io_trace_traceCommitInfo_blocks_0_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_0_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_0_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_0_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_0_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_0_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_1_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_1_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_1_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_1_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_1_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_1_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_2_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_2_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_2_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_2_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_2_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_2_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_3_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_3_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_3_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_3_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_3_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_3_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_4_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_4_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_4_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_4_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_4_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_4_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_5_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_5_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_5_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_5_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_5_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_5_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_6_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_6_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_6_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_6_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_6_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_6_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_7_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_7_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_7_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_7_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_7_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_7_bits_tracePipe_ilastsize,
  output logic         io_rabCommits_isCommit,
  output logic         io_rabCommits_commitValid_0,
  output logic         io_rabCommits_commitValid_1,
  output logic         io_rabCommits_commitValid_2,
  output logic         io_rabCommits_commitValid_3,
  output logic         io_rabCommits_commitValid_4,
  output logic         io_rabCommits_commitValid_5,
  output logic         io_rabCommits_isWalk,
  output logic         io_rabCommits_walkValid_0,
  output logic         io_rabCommits_walkValid_1,
  output logic         io_rabCommits_walkValid_2,
  output logic         io_rabCommits_walkValid_3,
  output logic         io_rabCommits_walkValid_4,
  output logic         io_rabCommits_walkValid_5,
  output logic [5:0]   io_rabCommits_info_0_ldest,
  output logic [7:0]   io_rabCommits_info_0_pdest,
  output logic         io_rabCommits_info_0_rfWen,
  output logic         io_rabCommits_info_0_fpWen,
  output logic         io_rabCommits_info_0_vecWen,
  output logic         io_rabCommits_info_0_v0Wen,
  output logic         io_rabCommits_info_0_vlWen,
  output logic         io_rabCommits_info_0_isMove,
  output logic [5:0]   io_rabCommits_info_1_ldest,
  output logic [7:0]   io_rabCommits_info_1_pdest,
  output logic         io_rabCommits_info_1_rfWen,
  output logic         io_rabCommits_info_1_fpWen,
  output logic         io_rabCommits_info_1_vecWen,
  output logic         io_rabCommits_info_1_v0Wen,
  output logic         io_rabCommits_info_1_vlWen,
  output logic         io_rabCommits_info_1_isMove,
  output logic [5:0]   io_rabCommits_info_2_ldest,
  output logic [7:0]   io_rabCommits_info_2_pdest,
  output logic         io_rabCommits_info_2_rfWen,
  output logic         io_rabCommits_info_2_fpWen,
  output logic         io_rabCommits_info_2_vecWen,
  output logic         io_rabCommits_info_2_v0Wen,
  output logic         io_rabCommits_info_2_vlWen,
  output logic         io_rabCommits_info_2_isMove,
  output logic [5:0]   io_rabCommits_info_3_ldest,
  output logic [7:0]   io_rabCommits_info_3_pdest,
  output logic         io_rabCommits_info_3_rfWen,
  output logic         io_rabCommits_info_3_fpWen,
  output logic         io_rabCommits_info_3_vecWen,
  output logic         io_rabCommits_info_3_v0Wen,
  output logic         io_rabCommits_info_3_vlWen,
  output logic         io_rabCommits_info_3_isMove,
  output logic [5:0]   io_rabCommits_info_4_ldest,
  output logic [7:0]   io_rabCommits_info_4_pdest,
  output logic         io_rabCommits_info_4_rfWen,
  output logic         io_rabCommits_info_4_fpWen,
  output logic         io_rabCommits_info_4_vecWen,
  output logic         io_rabCommits_info_4_v0Wen,
  output logic         io_rabCommits_info_4_vlWen,
  output logic         io_rabCommits_info_4_isMove,
  output logic [5:0]   io_rabCommits_info_5_ldest,
  output logic [7:0]   io_rabCommits_info_5_pdest,
  output logic         io_rabCommits_info_5_rfWen,
  output logic         io_rabCommits_info_5_fpWen,
  output logic         io_rabCommits_info_5_vecWen,
  output logic         io_rabCommits_info_5_v0Wen,
  output logic         io_rabCommits_info_5_vlWen,
  output logic         io_rabCommits_info_5_isMove,
  output logic         io_diffRatCommitRobIdx_valid,
  output logic         io_diffRatCommitRobIdx_bits_flag,
  output logic [7:0]   io_diffRatCommitRobIdx_bits_value,
  output logic [3:0]   io_lsq_scommit,
  output logic         io_lsq_pendingMMIOld,
  output logic         io_lsq_pendingst,
  output logic         io_lsq_pendingPtr_flag,
  output logic [7:0]   io_lsq_pendingPtr_value,
  input  logic         io_lsq_loadMmio_0,
  input  logic         io_lsq_loadMmio_1,
  input  logic         io_lsq_loadMmio_2,
  input  logic [7:0]   io_lsq_loadMmioUop_0_robIdx_value,
  input  logic [7:0]   io_lsq_loadMmioUop_1_robIdx_value,
  input  logic [7:0]   io_lsq_loadMmioUop_2_robIdx_value,
  input  logic         io_lsq_storeMmio,
  input  logic [7:0]   io_lsq_storeMmioUop_robIdx_value,
  output logic         io_robDeqPtr_flag,
  output logic [7:0]   io_robDeqPtr_value,
  input  logic         io_csr_intrBitSet,
  input  logic         io_csr_wfiEvent,
  input  logic         io_csr_criticalErrorState,
  output logic         io_csr_fflags_valid,
  output logic [4:0]   io_csr_fflags_bits,
  output logic         io_csr_vxsat_valid,
  output logic         io_csr_vxsat_bits,
  output logic         io_csr_vstart_valid,
  output logic [63:0]  io_csr_vstart_bits,
  output logic         io_csr_dirty_fs,
  output logic         io_csr_dirty_vs,
  output logic [6:0]   io_csr_perfinfo_retiredInstr,
  input  logic         io_snpt_useSnpt,
  input  logic [1:0]   io_snpt_snptSelect,
  output logic         io_headNotReady,
  output logic         io_cpu_halt,
  output logic         io_wfi_wfiReq,
  input  logic         io_wfi_safeFromMem,
  input  logic         io_wfi_safeFromFrontend,
  input  logic         io_wfi_enable,
  output logic         io_toDecode_isResumeVType,
  input  logic         io_fromVecExcpMod_busy,
  output logic         io_readGPAMemAddr_valid,
  input  logic [55:0]  io_readGPAMemData_gpaddr,
  input  logic         io_readGPAMemData_isForVSnonLeafPTE,
  input  logic         io_vstartIsZero,
  output logic         io_toVecExcpMod_excpInfo_valid,
  output logic [6:0]   io_toVecExcpMod_excpInfo_bits_vstart,
  output logic [1:0]   io_toVecExcpMod_excpInfo_bits_vsew,
  output logic [1:0]   io_toVecExcpMod_excpInfo_bits_veew,
  output logic [2:0]   io_toVecExcpMod_excpInfo_bits_vlmul,
  output logic [2:0]   io_toVecExcpMod_excpInfo_bits_nf,
  output logic         io_toVecExcpMod_excpInfo_bits_isStride,
  output logic         io_toVecExcpMod_excpInfo_bits_isIndexed,
  output logic         io_toVecExcpMod_excpInfo_bits_isWhole,
  output logic         io_toVecExcpMod_excpInfo_bits_isVlm,
  output logic [34:0]  io_debugRobHead_debug_fuType,
  input  logic         io_debugEnqLsq_canAccept,
  input  logic [1:0]   io_debugEnqLsq_needAlloc_0,
  input  logic [1:0]   io_debugEnqLsq_needAlloc_1,
  input  logic [1:0]   io_debugEnqLsq_needAlloc_2,
  input  logic [1:0]   io_debugEnqLsq_needAlloc_3,
  input  logic [1:0]   io_debugEnqLsq_needAlloc_4,
  input  logic [1:0]   io_debugEnqLsq_needAlloc_5,
  input  logic         io_debugEnqLsq_req_0_valid,
  input  logic [7:0]   io_debugEnqLsq_req_0_bits_robIdx_value,
  input  logic [6:0]   io_debugEnqLsq_req_0_bits_lqIdx_value,
  input  logic         io_debugEnqLsq_req_1_valid,
  input  logic [7:0]   io_debugEnqLsq_req_1_bits_robIdx_value,
  input  logic [6:0]   io_debugEnqLsq_req_1_bits_lqIdx_value,
  input  logic         io_debugEnqLsq_req_2_valid,
  input  logic [7:0]   io_debugEnqLsq_req_2_bits_robIdx_value,
  input  logic [6:0]   io_debugEnqLsq_req_2_bits_lqIdx_value,
  input  logic         io_debugEnqLsq_req_3_valid,
  input  logic [7:0]   io_debugEnqLsq_req_3_bits_robIdx_value,
  input  logic [6:0]   io_debugEnqLsq_req_3_bits_lqIdx_value,
  input  logic         io_debugEnqLsq_req_4_valid,
  input  logic [7:0]   io_debugEnqLsq_req_4_bits_robIdx_value,
  input  logic [6:0]   io_debugEnqLsq_req_4_bits_lqIdx_value,
  input  logic         io_debugEnqLsq_req_5_valid,
  input  logic [7:0]   io_debugEnqLsq_req_5_bits_robIdx_value,
  input  logic [6:0]   io_debugEnqLsq_req_5_bits_lqIdx_value,
  input  logic         io_debugHeadLsIssue,
  input  logic [7:0]   io_lsTopdownInfo_0_s1_robIdx,
  input  logic         io_lsTopdownInfo_0_s1_vaddr_valid,
  input  logic [49:0]  io_lsTopdownInfo_0_s1_vaddr_bits,
  input  logic [7:0]   io_lsTopdownInfo_0_s2_robIdx,
  input  logic         io_lsTopdownInfo_0_s2_paddr_valid,
  input  logic [47:0]  io_lsTopdownInfo_0_s2_paddr_bits,
  input  logic [7:0]   io_lsTopdownInfo_1_s1_robIdx,
  input  logic         io_lsTopdownInfo_1_s1_vaddr_valid,
  input  logic [49:0]  io_lsTopdownInfo_1_s1_vaddr_bits,
  input  logic [7:0]   io_lsTopdownInfo_1_s2_robIdx,
  input  logic         io_lsTopdownInfo_1_s2_paddr_valid,
  input  logic [47:0]  io_lsTopdownInfo_1_s2_paddr_bits,
  input  logic [7:0]   io_lsTopdownInfo_2_s1_robIdx,
  input  logic         io_lsTopdownInfo_2_s1_vaddr_valid,
  input  logic [49:0]  io_lsTopdownInfo_2_s1_vaddr_bits,
  input  logic [7:0]   io_lsTopdownInfo_2_s2_robIdx,
  input  logic         io_lsTopdownInfo_2_s2_paddr_valid,
  input  logic [47:0]  io_lsTopdownInfo_2_s2_paddr_bits,
  output logic         io_debugTopDown_toCore_robHeadVaddr_valid,
  output logic [49:0]  io_debugTopDown_toCore_robHeadVaddr_bits,
  output logic         io_debugTopDown_toCore_robHeadPaddr_valid,
  output logic [47:0]  io_debugTopDown_toCore_robHeadPaddr_bits,
  output logic         io_debugTopDown_toDispatch_robHeadLsIssue,
  input  logic         io_debugInstrAddrTransType_sv39,
  input  logic         io_debugInstrAddrTransType_sv48,
  input  logic [7:0]   io_storeDebugInfo_0_robidx_value,
  output logic [49:0]  io_storeDebugInfo_0_pc,
  input  logic [7:0]   io_storeDebugInfo_1_robidx_value,
  output logic [49:0]  io_storeDebugInfo_1_pc,
  output logic [5:0]   io_perf_0_value,
  output logic [5:0]   io_perf_1_value,
  output logic [5:0]   io_perf_2_value,
  output logic [5:0]   io_perf_3_value,
  output logic [5:0]   io_perf_4_value,
  output logic [5:0]   io_perf_5_value,
  output logic [5:0]   io_perf_6_value,
  output logic [5:0]   io_perf_7_value,
  output logic [5:0]   io_perf_8_value,
  output logic [5:0]   io_perf_9_value,
  output logic [5:0]   io_perf_10_value,
  output logic [5:0]   io_perf_11_value,
  output logic [5:0]   io_perf_12_value,
  output logic [5:0]   io_perf_13_value,
  output logic [5:0]   io_perf_14_value,
  output logic [5:0]   io_perf_15_value,
  output logic [5:0]   io_perf_16_value,
  output logic [5:0]   io_perf_17_value,
  output logic [5:0]   io_perf_18_value,
  output logic         io_error_0,
  output logic [321:0] gatewayIn_packed_6_bore,
  output logic [91:0]  gatewayIn_packed_7_bore,
  output logic [321:0] gatewayIn_packed_8_bore,
  output logic [91:0]  gatewayIn_packed_9_bore,
  output logic [321:0] gatewayIn_packed_10_bore,
  output logic [91:0]  gatewayIn_packed_11_bore,
  output logic [321:0] gatewayIn_packed_12_bore,
  output logic [91:0]  gatewayIn_packed_13_bore,
  output logic [321:0] gatewayIn_packed_14_bore,
  output logic [91:0]  gatewayIn_packed_15_bore,
  output logic [321:0] gatewayIn_packed_16_bore,
  output logic [91:0]  gatewayIn_packed_17_bore,
  output logic [321:0] gatewayIn_packed_18_bore,
  output logic [91:0]  gatewayIn_packed_19_bore,
  output logic [321:0] gatewayIn_packed_20_bore,
  output logic [91:0]  gatewayIn_packed_21_bore,
  output logic [265:0] gatewayIn_packed_22_bore,
  output logic [7:0]   allocatePtrVec_1_value,
  output logic [7:0]   allocatePtrVec_2_value,
  output logic [7:0]   allocatePtrVec_3_value,
  output logic [7:0]   allocatePtrVec_4_value,
  output logic [7:0]   allocatePtrVec_5_value,
  output logic         allowOnlyOneCommit,
  output logic         blockCommit,
  output logic         canEnqueueEG_0,
  output logic         canEnqueueEG_1,
  output logic         canEnqueueEG_2,
  output logic         canEnqueueEG_3,
  output logic         canEnqueueEG_4,
  output logic         canEnqueueEG_5,
  output logic         canEnqueue_0,
  output logic         canEnqueue_1,
  output logic         canEnqueue_2,
  output logic         canEnqueue_3,
  output logic         canEnqueue_4,
  output logic         canEnqueue_5,
  output logic         commitStuckCounter_io_stuck,
  output logic         commit_vDeqGroup_0,
  output logic         commit_vDeqGroup_1,
  output logic         commit_vDeqGroup_2,
  output logic         commit_vDeqGroup_3,
  output logic         commit_vDeqGroup_4,
  output logic         commit_vDeqGroup_5,
  output logic         commit_vDeqGroup_6,
  output logic         commit_vDeqGroup_7,
  output logic         commit_wDeqGroup_0,
  output logic         commit_wDeqGroup_1,
  output logic         commit_wDeqGroup_2,
  output logic         commit_wDeqGroup_3,
  output logic         commit_wDeqGroup_4,
  output logic         commit_wDeqGroup_5,
  output logic         commit_wDeqGroup_6,
  output logic         commit_wDeqGroup_7,
  output logic [1:0]   deqPtrGenModule_io_state,
  output logic [1:0]   dtPcTransTypeWdata,
  output logic         enqFirstUopValid_0,
  output logic         enqFirstUopValid_1,
  output logic         enqFirstUopValid_2,
  output logic         enqFirstUopValid_3,
  output logic         enqFirstUopValid_4,
  output logic         enqFirstUopValid_5,
  output logic         enqPtrGenModule_io_allowEnqueue,
  output logic         exceptionGen_io_wb_0_bits_hasException,
  output logic         exceptionGen_io_wb_10_bits_hasException,
  output logic         exceptionGen_io_wb_11_bits_hasException,
  output logic [63:0]  exceptionGen_io_wb_11_bits_vstart,
  output logic         exceptionGen_io_wb_11_bits_vstartEn,
  output logic         exceptionGen_io_wb_12_bits_hasException,
  output logic [63:0]  exceptionGen_io_wb_12_bits_vstart,
  output logic         exceptionGen_io_wb_12_bits_vstartEn,
  output logic         exceptionGen_io_wb_6_bits_hasException,
  output logic         exceptionGen_io_wb_7_bits_hasException,
  output logic         exceptionGen_io_wb_8_bits_hasException,
  output logic         exceptionGen_io_wb_9_bits_hasException,
  output logic         hasBlockBackwardOut,
  output logic         hasCommittedOut_0,
  output logic         hasCommittedOut_1,
  output logic         hasCommittedOut_2,
  output logic         hasCommittedOut_3,
  output logic         hasCommittedOut_4,
  output logic         hasCommittedOut_5,
  output logic         hasCommittedOut_6,
  output logic         hasCommittedOut_7,
  output logic         hasWaitForwardOut,
  output logic         intrBitSetRegOut,
  output logic         io_flushOut_valid_0,
  output logic [7:0]   rab_io_fromRob_commitSize,
  output logic         rab_io_fromRob_vecLoadExcp_valid_REGOut,
  output logic         rab_io_fromRob_walkEnd,
  output logic [7:0]   rab_io_fromRob_walkSize,
  output logic         rawInfo_0_interrupt_safe,
  output logic         snptEnq,
  output logic [5:0]   vtypeBuffer_io_fromRob_commitSize,
  output logic         vtypeBuffer_io_fromRob_walkEnd,
  output logic [5:0]   vtypeBuffer_io_fromRob_walkSize,
  input  logic         commitStuckCounter_io_overflow,
  input  logic         deqPtrVec_0_flag,
  input  logic [7:0]   deqPtrVec_0_value,
  input  logic         deqPtrVec_1_flag,
  input  logic [7:0]   deqPtrVec_1_value,
  input  logic         deqPtrVec_2_flag,
  input  logic [7:0]   deqPtrVec_2_value,
  input  logic         deqPtrVec_3_flag,
  input  logic [7:0]   deqPtrVec_3_value,
  input  logic         deqPtrVec_4_flag,
  input  logic [7:0]   deqPtrVec_4_value,
  input  logic         deqPtrVec_5_flag,
  input  logic [7:0]   deqPtrVec_5_value,
  input  logic         deqPtrVec_6_flag,
  input  logic [7:0]   deqPtrVec_6_value,
  input  logic         deqPtrVec_7_flag,
  input  logic [7:0]   deqPtrVec_7_value,
  input  logic         deqPtrVec_next_0_flag,
  input  logic [7:0]   deqPtrVec_next_0_value,
  input  logic [1:0]   dt_pcTransType_ext_R0_data,
  input  logic [1:0]   dt_pcTransType_ext_R1_data,
  input  logic [1:0]   dt_pcTransType_ext_R2_data,
  input  logic [1:0]   dt_pcTransType_ext_R3_data,
  input  logic [1:0]   dt_pcTransType_ext_R4_data,
  input  logic [1:0]   dt_pcTransType_ext_R5_data,
  input  logic [1:0]   dt_pcTransType_ext_R6_data,
  input  logic [1:0]   dt_pcTransType_ext_R7_data,
  input  logic         enqPtrVec_0_flag,
  input  logic [7:0]   enqPtrVec_0_value,
  input  logic [7:0]   enqPtrVec_1_value,
  input  logic [7:0]   enqPtrVec_2_value,
  input  logic [7:0]   enqPtrVec_3_value,
  input  logic [7:0]   enqPtrVec_4_value,
  input  logic [7:0]   enqPtrVec_5_value,
  input  logic         exceptionGen_io_state_bits_crossPageIPFFix,
  input  logic         exceptionGen_io_state_bits_exceptionVec_0,
  input  logic         exceptionGen_io_state_bits_exceptionVec_1,
  input  logic         exceptionGen_io_state_bits_exceptionVec_10,
  input  logic         exceptionGen_io_state_bits_exceptionVec_11,
  input  logic         exceptionGen_io_state_bits_exceptionVec_12,
  input  logic         exceptionGen_io_state_bits_exceptionVec_13,
  input  logic         exceptionGen_io_state_bits_exceptionVec_14,
  input  logic         exceptionGen_io_state_bits_exceptionVec_15,
  input  logic         exceptionGen_io_state_bits_exceptionVec_16,
  input  logic         exceptionGen_io_state_bits_exceptionVec_17,
  input  logic         exceptionGen_io_state_bits_exceptionVec_18,
  input  logic         exceptionGen_io_state_bits_exceptionVec_19,
  input  logic         exceptionGen_io_state_bits_exceptionVec_2,
  input  logic         exceptionGen_io_state_bits_exceptionVec_20,
  input  logic         exceptionGen_io_state_bits_exceptionVec_21,
  input  logic         exceptionGen_io_state_bits_exceptionVec_22,
  input  logic         exceptionGen_io_state_bits_exceptionVec_23,
  input  logic         exceptionGen_io_state_bits_exceptionVec_3,
  input  logic         exceptionGen_io_state_bits_exceptionVec_4,
  input  logic         exceptionGen_io_state_bits_exceptionVec_5,
  input  logic         exceptionGen_io_state_bits_exceptionVec_6,
  input  logic         exceptionGen_io_state_bits_exceptionVec_7,
  input  logic         exceptionGen_io_state_bits_exceptionVec_8,
  input  logic         exceptionGen_io_state_bits_exceptionVec_9,
  input  logic         exceptionGen_io_state_bits_flushPipe,
  input  logic         exceptionGen_io_state_bits_isEnqExcp,
  input  logic         exceptionGen_io_state_bits_isFetchMalAddr,
  input  logic         exceptionGen_io_state_bits_isIndexed,
  input  logic         exceptionGen_io_state_bits_isStrided,
  input  logic         exceptionGen_io_state_bits_isVecLoad,
  input  logic         exceptionGen_io_state_bits_isVlm,
  input  logic         exceptionGen_io_state_bits_isVset,
  input  logic         exceptionGen_io_state_bits_isWhole,
  input  logic [2:0]   exceptionGen_io_state_bits_nf,
  input  logic         exceptionGen_io_state_bits_replayInst,
  input  logic         exceptionGen_io_state_bits_robIdx_flag,
  input  logic [7:0]   exceptionGen_io_state_bits_robIdx_value,
  input  logic         exceptionGen_io_state_bits_satpFlushFirstFetchFault,
  input  logic         exceptionGen_io_state_bits_satpFlushPipe,
  input  logic         exceptionGen_io_state_bits_singleStep,
  input  logic [3:0]   exceptionGen_io_state_bits_trigger,
  input  logic [1:0]   exceptionGen_io_state_bits_veew,
  input  logic [2:0]   exceptionGen_io_state_bits_vlmul,
  input  logic [1:0]   exceptionGen_io_state_bits_vsew,
  input  logic [63:0]  exceptionGen_io_state_bits_vstart,
  input  logic         exceptionGen_io_state_bits_vstartEn,
  input  logic         exceptionGen_io_state_valid,
  input  logic         rab_io_canEnq,
  input  logic         rab_io_canEnqForDispatch,
  input  logic         rab_io_commits_commitValid_0,
  input  logic         rab_io_commits_commitValid_1,
  input  logic         rab_io_commits_commitValid_2,
  input  logic         rab_io_commits_commitValid_3,
  input  logic         rab_io_commits_commitValid_4,
  input  logic         rab_io_commits_commitValid_5,
  input  logic         rab_io_commits_info_0_fpWen,
  input  logic         rab_io_commits_info_0_isMove,
  input  logic [5:0]   rab_io_commits_info_0_ldest,
  input  logic [7:0]   rab_io_commits_info_0_pdest,
  input  logic         rab_io_commits_info_0_rfWen,
  input  logic         rab_io_commits_info_0_v0Wen,
  input  logic         rab_io_commits_info_0_vecWen,
  input  logic         rab_io_commits_info_0_vlWen,
  input  logic         rab_io_commits_info_1_fpWen,
  input  logic         rab_io_commits_info_1_isMove,
  input  logic [5:0]   rab_io_commits_info_1_ldest,
  input  logic [7:0]   rab_io_commits_info_1_pdest,
  input  logic         rab_io_commits_info_1_rfWen,
  input  logic         rab_io_commits_info_1_v0Wen,
  input  logic         rab_io_commits_info_1_vecWen,
  input  logic         rab_io_commits_info_1_vlWen,
  input  logic         rab_io_commits_info_2_fpWen,
  input  logic         rab_io_commits_info_2_isMove,
  input  logic [5:0]   rab_io_commits_info_2_ldest,
  input  logic [7:0]   rab_io_commits_info_2_pdest,
  input  logic         rab_io_commits_info_2_rfWen,
  input  logic         rab_io_commits_info_2_v0Wen,
  input  logic         rab_io_commits_info_2_vecWen,
  input  logic         rab_io_commits_info_2_vlWen,
  input  logic         rab_io_commits_info_3_fpWen,
  input  logic         rab_io_commits_info_3_isMove,
  input  logic [5:0]   rab_io_commits_info_3_ldest,
  input  logic [7:0]   rab_io_commits_info_3_pdest,
  input  logic         rab_io_commits_info_3_rfWen,
  input  logic         rab_io_commits_info_3_v0Wen,
  input  logic         rab_io_commits_info_3_vecWen,
  input  logic         rab_io_commits_info_3_vlWen,
  input  logic         rab_io_commits_info_4_fpWen,
  input  logic         rab_io_commits_info_4_isMove,
  input  logic [5:0]   rab_io_commits_info_4_ldest,
  input  logic [7:0]   rab_io_commits_info_4_pdest,
  input  logic         rab_io_commits_info_4_rfWen,
  input  logic         rab_io_commits_info_4_v0Wen,
  input  logic         rab_io_commits_info_4_vecWen,
  input  logic         rab_io_commits_info_4_vlWen,
  input  logic         rab_io_commits_info_5_fpWen,
  input  logic         rab_io_commits_info_5_isMove,
  input  logic [5:0]   rab_io_commits_info_5_ldest,
  input  logic [7:0]   rab_io_commits_info_5_pdest,
  input  logic         rab_io_commits_info_5_rfWen,
  input  logic         rab_io_commits_info_5_v0Wen,
  input  logic         rab_io_commits_info_5_vecWen,
  input  logic         rab_io_commits_info_5_vlWen,
  input  logic         rab_io_commits_isCommit,
  input  logic         rab_io_commits_isWalk,
  input  logic         rab_io_commits_walkValid_0,
  input  logic         rab_io_commits_walkValid_1,
  input  logic         rab_io_commits_walkValid_2,
  input  logic         rab_io_commits_walkValid_3,
  input  logic         rab_io_commits_walkValid_4,
  input  logic         rab_io_commits_walkValid_5,
  input  logic         rab_io_status_commitEnd,
  input  logic         rab_io_status_walkEnd,
  input  logic         snapshots_snapshotGen_io_snapshots_0_0_flag,
  input  logic [7:0]   snapshots_snapshotGen_io_snapshots_0_0_value,
  input  logic         snapshots_snapshotGen_io_snapshots_1_0_flag,
  input  logic [7:0]   snapshots_snapshotGen_io_snapshots_1_0_value,
  input  logic         snapshots_snapshotGen_io_snapshots_2_0_flag,
  input  logic [7:0]   snapshots_snapshotGen_io_snapshots_2_0_value,
  input  logic         snapshots_snapshotGen_io_snapshots_3_0_flag,
  input  logic [7:0]   snapshots_snapshotGen_io_snapshots_3_0_value,
  input  logic         vtypeBuffer_io_canEnq,
  input  logic         vtypeBuffer_io_canEnqForDispatch,
  input  logic         vtypeBuffer_io_status_walkEnd,
  input  logic         vtypeBuffer_io_toDecode_isResumeVType
  // END GENERATED
);

  // ==========================================================================
  // §1 条目存储
  // ==========================================================================
  // 每字段一个非打包数组，名字必须是 `<prefix>_<field>`：pin 契约按
  // `i:/WORK/Rob/u_core/<prefix>_<field>_reg[<i>][<b>]` 配对（gen_rob_pins.py）。
  // 改名 = 169,168 个 pin 全部配不上。核对用：
  //     python3 scripts/gen_rob_pins.py --check-core
  // 位宽/深度/复位域逐条来自 docs/rob_core_contract.tsv，不靠记忆。

  // ---- robEntries：36 字段 x 160 条目 ----
  logic                      robEntries_valid                      [ROB_SIZE]; // 唯一异步复位的字段
  logic                      robEntries_vls                        [ROB_SIZE];
  logic                      robEntries_interrupt_safe             [ROB_SIZE];
  logic                      robEntries_fpWen                      [ROB_SIZE];
  logic                      robEntries_rfWen                      [ROB_SIZE];
  logic                      robEntries_wflags                     [ROB_SIZE];
  logic                      robEntries_dirtyVs                    [ROB_SIZE];
  logic [COMMITTYPE_W-1:0]   robEntries_commitType                 [ROB_SIZE];
  logic                      robEntries_ftqIdx_flag                [ROB_SIZE];
  logic [FTQ_PTR_W-1:0]      robEntries_ftqIdx_value               [ROB_SIZE];
  logic [FTQ_OFF_W-1:0]      robEntries_ftqOffset                  [ROB_SIZE];
  logic                      robEntries_isRVC                      [ROB_SIZE];
  logic                      robEntries_isVset                     [ROB_SIZE];
  logic                      robEntries_isHls                      [ROB_SIZE];
  logic [INSTRSIZE_W-1:0]    robEntries_instrSize                  [ROB_SIZE];
  logic [ITYPE_W-1:0]        robEntries_traceBlockInPipe_itype     [ROB_SIZE];
  logic [IRETIRE_W-1:0]      robEntries_traceBlockInPipe_iretire   [ROB_SIZE];
  logic                      robEntries_traceBlockInPipe_ilastsize [ROB_SIZE];
  logic [FFLAGS_W-1:0]       robEntries_fflags                     [ROB_SIZE];
  logic                      robEntries_mmio                       [ROB_SIZE];
  logic                      robEntries_stdWritebacked             [ROB_SIZE];
  logic                      robEntries_vxsat                      [ROB_SIZE];
  logic [UOPNUM_W-1:0]       robEntries_realDestSize               [ROB_SIZE];
  logic [UOPNUM_W-1:0]       robEntries_uopNum                     [ROB_SIZE];
  logic                      robEntries_needFlush                  [ROB_SIZE];
  logic [VADDR_W-1:0]        robEntries_debug_pc                   [ROB_SIZE];
  logic [31:0]               robEntries_debug_instr                [ROB_SIZE];
  logic [LREG_W-1:0]         robEntries_basicDebug_ldest           [ROB_SIZE];
  logic [PREG_W-1:0]         robEntries_basicDebug_pdest           [ROB_SIZE];
  logic [LREG_W-1:0]         robEntries_basicDebug_vd              [ROB_SIZE];
  logic                      robEntries_basicDebug_fpWen           [ROB_SIZE];
  logic                      robEntries_basicDebug_vecWen          [ROB_SIZE];
  logic                      robEntries_basicDebug_v0Wen           [ROB_SIZE];
  logic                      robEntries_basicDebug_eliminatedMove  [ROB_SIZE];
  logic                      robEntries_basicDebug_isXSTrap        [ROB_SIZE];
  logic [FUTYPE_W-1:0]       robEntries_debug_fuType               [ROB_SIZE];

  // ---- robDeqGroup：45 字段 x 8（提交读口的寄存器级）----
  logic                      robDeqGroup_walk_v                      [BANK_N];
  logic                      robDeqGroup_commit_v                    [BANK_N];
  logic                      robDeqGroup_commit_w                    [BANK_N];
  logic [UOPNUM_W-1:0]       robDeqGroup_realDestSize                [BANK_N];
  logic                      robDeqGroup_interrupt_safe              [BANK_N];
  logic                      robDeqGroup_wflags                      [BANK_N];
  logic [FFLAGS_W-1:0]       robDeqGroup_fflags                      [BANK_N];
  logic                      robDeqGroup_vxsat                       [BANK_N];
  logic                      robDeqGroup_isRVC                       [BANK_N];
  logic                      robDeqGroup_isVset                      [BANK_N];
  logic                      robDeqGroup_isHls                       [BANK_N];
  logic                      robDeqGroup_isVls                       [BANK_N];
  logic                      robDeqGroup_vls                         [BANK_N];
  logic                      robDeqGroup_mmio                        [BANK_N];
  logic [COMMITTYPE_W-1:0]   robDeqGroup_commitType                  [BANK_N];
  logic                      robDeqGroup_ftqIdx_flag                 [BANK_N];
  logic [FTQ_PTR_W-1:0]      robDeqGroup_ftqIdx_value                [BANK_N];
  logic [FTQ_OFF_W-1:0]      robDeqGroup_ftqOffset                   [BANK_N];
  logic [INSTRSIZE_W-1:0]    robDeqGroup_instrSize                   [BANK_N];
  logic                      robDeqGroup_fpWen                       [BANK_N];
  logic                      robDeqGroup_rfWen                       [BANK_N];
  logic                      robDeqGroup_needFlush                   [BANK_N];
  logic [ITYPE_W-1:0]        robDeqGroup_traceBlockInPipe_itype      [BANK_N];
  logic [IRETIRE_W-1:0]      robDeqGroup_traceBlockInPipe_iretire    [BANK_N];
  logic                      robDeqGroup_traceBlockInPipe_ilastsize  [BANK_N];
  logic [VADDR_W-1:0]        robDeqGroup_debug_pc                    [BANK_N];
  logic [31:0]               robDeqGroup_debug_instr                 [BANK_N];
  logic [LREG_W-1:0]         robDeqGroup_basicDebug_ldest            [BANK_N];
  logic [PREG_W-1:0]         robDeqGroup_basicDebug_pdest            [BANK_N];
  logic [LREG_W-1:0]         robDeqGroup_basicDebug_vd               [BANK_N];
  logic                      robDeqGroup_basicDebug_fpWen            [BANK_N];
  logic                      robDeqGroup_basicDebug_vecWen           [BANK_N];
  logic                      robDeqGroup_basicDebug_v0Wen            [BANK_N];
  logic                      robDeqGroup_basicDebug_eliminatedMove   [BANK_N];
  logic                      robDeqGroup_basicDebug_isXSTrap         [BANK_N];
  logic [FUTYPE_W-1:0]       robDeqGroup_debug_fuType                [BANK_N];
  logic                      robDeqGroup_dirtyFs                     [BANK_N];
  logic                      robDeqGroup_dirtyVs                     [BANK_N];
  // ★这 7 个刻意不驱动★（见文件头「已知残留」）：与 golden 一致，
  // golden 里它们只在 RANDOMIZE_REG_INIT 里被写，connectCommitEntry 逐字段
  // 拷贝时唯独不提它（RobEntryBundle 根本没有这个成员，没得可拷）。
  logic [PREG_W-1:0]         robDeqGroup_debug_otherPdest_0          [BANK_N];
  logic [PREG_W-1:0]         robDeqGroup_debug_otherPdest_1          [BANK_N];
  logic [PREG_W-1:0]         robDeqGroup_debug_otherPdest_2          [BANK_N];
  logic [PREG_W-1:0]         robDeqGroup_debug_otherPdest_3          [BANK_N];
  logic [PREG_W-1:0]         robDeqGroup_debug_otherPdest_4          [BANK_N];
  logic [PREG_W-1:0]         robDeqGroup_debug_otherPdest_5          [BANK_N];
  logic [PREG_W-1:0]         robDeqGroup_debug_otherPdest_6          [BANK_N];

  // ---- debug/difftest 规则阵列（169,763 bit 里 79% 在这里）----
  // 它们不参与功能，但**一位都不能省**：省掉之后 FM 的 match 会退化成签名匹配，
  // 在 11,639 个结构相同的寄存器上是 O(N^2)（canary 实测 2560 个要 554 秒）。
  logic [COMMITTYPE_W-1:0]   debug_microOp_debugReg_commitType                [ROB_SIZE];
  logic [XLEN-1:0]           debug_microOp_debugReg_debugInfo_dispatchTime    [ROB_SIZE];
  logic [XLEN-1:0]           debug_microOp_debugReg_debugInfo_enqRsTime       [ROB_SIZE];
  logic [XLEN-1:0]           debug_microOp_debugReg_debugInfo_issueTime       [ROB_SIZE];
  logic [XLEN-1:0]           debug_microOp_debugReg_debugInfo_renameTime      [ROB_SIZE];
  logic [XLEN-1:0]           debug_microOp_debugReg_debugInfo_selectTime      [ROB_SIZE];
  logic [XLEN-1:0]           debug_microOp_debugReg_debugInfo_writebackTime   [ROB_SIZE];
  logic [FUTYPE_W-1:0]       debug_microOp_debugReg_debug_fuType              [ROB_SIZE];
  logic                      debug_microOp_debugReg_debug_sim_trig            [ROB_SIZE];
  logic [FUOPTYPE_W-1:0]     debug_microOp_debugReg_fuOpType                  [ROB_SIZE];
  logic [FUTYPE_W-1:0]       debug_microOp_debugReg_fuType                    [ROB_SIZE];
  logic [31:0]               debug_microOp_debugReg_instr                     [ROB_SIZE];
  logic [LQ_PTR_W-1:0]       debug_microOp_debugReg_lqIdx_value               [ROB_SIZE];
  logic [VADDR_W-1:0]        debug_microOp_debugReg_pc                        [ROB_SIZE];
  logic [SQ_PTR_W-1:0]       debug_microOp_debugReg_sqIdx_value               [ROB_SIZE];

  logic [VADDR_W-1:0]        debug_lsTopdownInfo_s1_vaddr_bits   [ROB_SIZE];
  logic                      debug_lsTopdownInfo_s1_vaddr_valid  [ROB_SIZE];
  logic [PADDR_W-1:0]        debug_lsTopdownInfo_s2_paddr_bits   [ROB_SIZE];
  logic                      debug_lsTopdownInfo_s2_paddr_valid  [ROB_SIZE];

  logic [PREG_W-1:0]         debug_VecOtherPdest_0 [ROB_SIZE];
  logic [PREG_W-1:0]         debug_VecOtherPdest_1 [ROB_SIZE];
  logic [PREG_W-1:0]         debug_VecOtherPdest_2 [ROB_SIZE];
  logic [PREG_W-1:0]         debug_VecOtherPdest_3 [ROB_SIZE];
  logic [PREG_W-1:0]         debug_VecOtherPdest_4 [ROB_SIZE];
  logic [PREG_W-1:0]         debug_VecOtherPdest_5 [ROB_SIZE];
  logic [PREG_W-1:0]         debug_VecOtherPdest_6 [ROB_SIZE];
  logic [PREG_W-1:0]         debug_VecOtherPdest_7 [ROB_SIZE];

  logic                      dt_exuDebug_isMMIO    [ROB_SIZE];
  logic                      dt_exuDebug_isNCIO    [ROB_SIZE];
  logic                      dt_exuDebug_isPerfCnt [ROB_SIZE];
  logic [PADDR_W-1:0]        dt_exuDebug_paddr     [ROB_SIZE];

  logic [XLEN-1:0]           debug_exuData  [ROB_SIZE];   // 一维族
  logic                      debug_lsIssued [ROB_SIZE];   // 一维族，异步复位 0

  // ---- io_rabCommits 的流水级（RegNext(rab.io.commits)）----
  logic                      io_rabCommits_REG_info_fpWen  [RENAME_W];
  logic                      io_rabCommits_REG_info_isMove [RENAME_W];
  logic [LREG_W-1:0]         io_rabCommits_REG_info_ldest  [RENAME_W];
  logic [PREG_W-1:0]         io_rabCommits_REG_info_pdest  [RENAME_W];
  logic                      io_rabCommits_REG_info_rfWen  [RENAME_W];
  logic                      io_rabCommits_REG_info_v0Wen  [RENAME_W];
  logic                      io_rabCommits_REG_info_vecWen [RENAME_W];
  logic                      io_rabCommits_REG_info_vlWen  [RENAME_W];

  // ---- 走回指针 ----
  logic                      walkPtrVec_flag     [COMMIT_W];
  logic [PTR_W-1:0]          walkPtrVec_value    [COMMIT_W];
  logic                      walkingPtrVec_flag  [COMMIT_W];
  logic [PTR_W-1:0]          walkingPtrVec_value [COMMIT_W];


  // ---- 跨段前置声明 ----
  // 本文件按"机制"分段（入队 / 读口 / 提交 / 异常），但 SystemVerilog 要求
  // 变量先声明后使用，而这几根信号被更靠前的段引用。集中放在这里，
  // 免得为了迁就语法把机制顺序打乱。
  logic [PTR_W-1:0]       deqPtrValue [COMMIT_W];
  logic                   deqPtrFlag  [COMMIT_W];
  logic                   commitValidOut [COMMIT_W];
  logic                   commitsHasWalkInstr;
  logic                   commitsHasCommitInstr;

  logic [31:0]        deqHeadInstr;   // debug_microOp(deqPtr).instr，异常出口要用
  // ---- §22 debug 段的输入整理数组（声明提前，使用点在后）----
  logic                dbgEnqLsqAlloc  [RENAME_W];
  logic [PTR_W-1:0]    dbgEnqLsqRobIdx [RENAME_W];
  logic [LQ_PTR_W-1:0] dbgEnqLsqLqIdx  [RENAME_W];
  logic                lsTdS1Valid [3];
  logic [PTR_W-1:0]    lsTdS1RobIdx[3];
  logic [VADDR_W-1:0]  lsTdS1Vaddr [3];
  logic                lsTdS2Valid [3];
  logic [PTR_W-1:0]    lsTdS2RobIdx[3];
  logic [PADDR_W-1:0]  lsTdS2Paddr [3];
  logic             vldWbValid  [VLD_WB_N];
  logic [PTR_W-1:0] vldWbRobIdx [VLD_WB_N];
  logic [2:0]       vldWbVdIdx  [VLD_WB_N];
  logic [PREG_W-1:0] vldWbPdest [VLD_WB_N];
  logic             vldWbVecWen [VLD_WB_N];
  logic             vldWbV0Wen  [VLD_WB_N];

  logic io_error_0_REG, io_error_0_REG_1;   // commitStuckCounter 溢出也打两拍

  // perfEvents 的 RegEnable 桶：三组提交向量各 8 位
  logic perfEvents_r_1_0, perfEvents_r_1_1, perfEvents_r_1_2, perfEvents_r_1_3;
  logic perfEvents_r_1_4, perfEvents_r_1_5, perfEvents_r_1_6, perfEvents_r_1_7;
  logic perfEvents_r_2_0, perfEvents_r_2_1, perfEvents_r_2_2, perfEvents_r_2_3;
  logic perfEvents_r_2_4, perfEvents_r_2_5, perfEvents_r_2_6, perfEvents_r_2_7;

  // ---- RegEnable 桶（契约表的 BUCKET 段）----
  // r_4_0..r_4_23 = RegEnable(exceptionDataRead.bits.exceptionVec, exceptionHappen)
  // 名字照 golden（name_lock=free，只能靠 FM 按名字配）。
  logic r_4_0;  logic r_4_1;  logic r_4_2;  logic r_4_3;
  logic r_4_4;  logic r_4_5;  logic r_4_6;  logic r_4_7;
  logic r_4_8;  logic r_4_9;  logic r_4_10; logic r_4_11;
  logic r_4_12; logic r_4_13; logic r_4_14; logic r_4_15;
  logic r_4_16; logic r_4_17; logic r_4_18; logic r_4_19;
  logic r_4_20; logic r_4_21; logic r_4_22; logic r_4_23;

  // ---- 散寄存器（docs/rob_core_contract.tsv 的 SCALAR 段，132 条）----
  // ★名字照 golden 起★：这些在契约表里是 name_lock=free —— fm_pins.tcl **不钉**
  // 它们，也就是说它们只能靠 FM 自己按名字/结构配对。改名等于把唯一的线索扔掉。
  // 语义在各自使用处的注释里；`REG*` / `r_*` 这类 firtool 起的名字，
  // 用到的地方都写明了它是谁的 RegNext/RegEnable。
  // 复位域按表分两类：async 的进 `always_ff @(posedge clock or posedge reset)`，
  // none 的进 `always_ff @(posedge clock)`（表里两块不相交）。
  logic          REG;
  logic          REG_1;
  logic          REG_2;
  logic          REG_3;
  logic          REG_4;
  logic          REG_5;
  logic          REG_6;
  logic          REG_7;
  logic          REG_8;
  logic          allowEnqueue;   // async reset 1'h1
  logic          allowEnqueueForDispatch;   // async reset 1'h1
  logic          commit_w_delay;
  logic [2:0]    deqFlushBlockCounter;
  logic          deqHasFlushed;   // async reset 1'h0
  logic          deqHitRedirectReg_REG;
  logic          deqHitRedirectReg_REG_1;
  logic          deqHitRedirectReg_REG_2;
  logic          deqVlsCanCommit;   // async reset 1'h0
  logic          deqVlsCanCommit_REG;
  logic          deqVlsCanCommit_REG_1;
  logic [6:0]    deqVlsExceptionCommitSize;   // async reset 7'h0
  logic          deqVlsExceptionNeedCommit;   // async reset 1'h0
  logic          deqVlsExcpLock;   // async reset 1'h0
  logic          donotNeedWalk_0;   // async reset 1'h0
  logic          donotNeedWalk_1;   // async reset 1'h0
  logic          donotNeedWalk_2;   // async reset 1'h0
  logic          donotNeedWalk_3;   // async reset 1'h0
  logic          donotNeedWalk_4;   // async reset 1'h0
  logic          donotNeedWalk_5;   // async reset 1'h0
  logic          donotNeedWalk_6;   // async reset 1'h0
  logic          donotNeedWalk_7;   // async reset 1'h0
  logic          fuseCommitCnt_r;
  logic          fuseCommitCnt_r_1;
  logic          fuseCommitCnt_r_2;
  logic          fuseCommitCnt_r_3;
  logic          fuseCommitCnt_r_4;
  logic          fuseCommitCnt_r_5;
  logic          fuseCommitCnt_r_6;
  logic          fuseCommitCnt_r_7;
  logic          hasBlockBackward;   // async reset 1'h0
  logic          hasCommitted_0;   // async reset 1'h0
  logic          hasCommitted_1;   // async reset 1'h0
  logic          hasCommitted_2;   // async reset 1'h0
  logic          hasCommitted_3;   // async reset 1'h0
  logic          hasCommitted_4;   // async reset 1'h0
  logic          hasCommitted_5;   // async reset 1'h0
  logic          hasCommitted_6;   // async reset 1'h0
  logic          hasCommitted_7;   // async reset 1'h0
  logic          hasWFI;   // async reset 1'h0
  logic          hasWaitForward;   // async reset 1'h0
  logic [63:0]   instrCntReg;   // async reset 64'h0
  logic          intrBitSetReg;
  logic          io_csr_dirty_fs_last_REG;   // async reset 1'h0
  logic          io_csr_dirty_vs_last_REG;   // async reset 1'h0
  logic [4:0]    io_csr_fflags_next_bits_r;
  logic          io_csr_fflags_next_valid_last_REG;   // async reset 1'h0
  logic [63:0]   io_csr_vstart_bits_REG;
  logic          io_csr_vstart_valid_REG;
  logic          io_csr_vxsat_next_bits_r;
  logic          io_csr_vxsat_next_valid_last_REG;   // async reset 1'h0
  logic          io_enq_isEmpty_REG;
  logic [2:0]    io_exception_bits_commitType_r;
  logic          io_exception_bits_crossPageIPFFix_r;
  logic [31:0]   io_exception_bits_instr_r;
  logic          io_exception_bits_isFetchMalAddr_r;
  logic          io_exception_bits_isHls_r;
  logic          io_exception_bits_isInterrupt_r;
  logic          io_exception_bits_isPcBkpt_r;
  logic          io_exception_bits_satpFlushFirstFetchFault_r;
  logic          io_exception_bits_singleStep_r;
  logic [3:0]    io_exception_bits_trigger_r;
  logic          io_exception_valid_REG;
  logic          io_lsq_pendingMMIOld_REG;
  logic          io_lsq_pendingPtr_REG_flag;
  logic [7:0]    io_lsq_pendingPtr_REG_value;
  logic          io_lsq_pendingst_REG;
  logic [3:0]    io_lsq_scommit_REG;
  logic          io_rabCommits_REG_commitValid_0;
  logic          io_rabCommits_REG_commitValid_1;
  logic          io_rabCommits_REG_commitValid_2;
  logic          io_rabCommits_REG_commitValid_3;
  logic          io_rabCommits_REG_commitValid_4;
  logic          io_rabCommits_REG_commitValid_5;
  logic          io_rabCommits_REG_isCommit;
  logic          io_rabCommits_REG_isWalk;
  logic          io_rabCommits_REG_walkValid_0;
  logic          io_rabCommits_REG_walkValid_1;
  logic          io_rabCommits_REG_walkValid_2;
  logic          io_rabCommits_REG_walkValid_3;
  logic          io_rabCommits_REG_walkValid_4;
  logic          io_rabCommits_REG_walkValid_5;
  logic          isCommitReg_last_REG;   // async reset 1'h0
  logic          isVsetFlushPipeReg;
  logic          lastCycleFlush;
  logic          lastWalkPtr_flag;
  logic [7:0]    lastWalkPtr_value;
  logic [2:0]    misPredBlockCounter;
  logic          perfEvents_r_0;
  logic          perfEvents_r_1;
  logic          perfEvents_r_2;
  logic          perfEvents_r_3;
  logic          perfEvents_r_4;
  logic          perfEvents_r_5;
  logic          perfEvents_r_6;
  logic          perfEvents_r_7;
  logic [7:0]    r_value;
  logic          rab_io_fromRob_vecLoadExcp_valid_REG;
  logic          redirectAll;   // async reset 1'h0
  logic [7:0]    redirectBegin;
  logic [7:0]    redirectEnd;
  logic          redirectValidReg;
  logic [19:0]   robBanksRaddrThisLine;   // async reset 20'h1
  logic          state;   // async reset 1'h0
  logic          state_next_REG;
  logic [63:0]   timer;   // async reset 64'h0
  logic [9:0]    trueCommitCnt_r;
  logic          vecExcpInfo_bits_isIndexed;
  logic          vecExcpInfo_bits_isStride;
  logic          vecExcpInfo_bits_isVlm;
  logic          vecExcpInfo_bits_isWhole;
  logic [2:0]    vecExcpInfo_bits_nf;
  logic [1:0]    vecExcpInfo_bits_veew;
  logic [2:0]    vecExcpInfo_bits_vlmul;
  logic [1:0]    vecExcpInfo_bits_vsew;
  logic [6:0]    vecExcpInfo_bits_vstart;
  logic          vecExcpInfo_valid;   // async reset 1'h0
  logic [7:0]    waitRabWalkCycle;   // async reset 8'h0
  logic [7:0]    walkCycle;   // async reset 8'h0
  logic [2:0]    walkPtrLowBits;
  logic          walkPtrTrue_flag;
  logic [7:0]    walkPtrTrue_value;
  logic [19:0]   wfi_cycles;   // async reset 20'h0

  // ==========================================================================
  // §2 RobPtr 算术（循环队列指针）
  // ==========================================================================
  // RobSize=160 不是 2 的幂，所以 CircularQueuePtr 的 `+` 走"回绕"那条路：
  //   new_value = value +& v; 若 new_value >= 160 则 flag 取反、值减 160。
  // ★为什么拆成两个函数而不是返回一个 {flag,value}★：
  //   FM 的 read_sverilog 不支持对函数返回值做域选（`f(x).value`），
  //   本仓已有踩坑记录；拆开是唯一稳的写法。
  // 比较用 CircularQueuePtr 的定义：a>b 等价于 (a.flag^b.flag) ^ (a.value>b.value)。

  function automatic logic [PTR_W-1:0] ptrAddValue
      (input logic [PTR_W-1:0] value, input logic [PTR_W:0] v);
    logic [PTR_W:0] nv;
    begin
      nv = {1'b0, value} + v;
      ptrAddValue = (nv >= (PTR_W+1)'(ROB_SIZE))
                      ? (PTR_W)'(nv - (PTR_W+1)'(ROB_SIZE)) : nv[PTR_W-1:0];
    end
  endfunction

  function automatic logic ptrAddFlag
      (input logic flag, input logic [PTR_W-1:0] value, input logic [PTR_W:0] v);
    logic [PTR_W:0] nv;
    begin
      nv = {1'b0, value} + v;
      ptrAddFlag = (nv >= (PTR_W+1)'(ROB_SIZE)) ? ~flag : flag;
    end
  endfunction

  // a > b / a <= b，两侧都是 {flag,value}
  function automatic logic ptrGt(input logic af, input logic [PTR_W-1:0] av,
                                 input logic bf, input logic [PTR_W-1:0] bv);
    ptrGt = (af ^ bf) ^ (av > bv);
  endfunction

  function automatic logic ptrLe(input logic af, input logic [PTR_W-1:0] av,
                                 input logic bf, input logic [PTR_W-1:0] bv);
    ptrLe = (af ^ bf) ^ (av <= bv);
  endfunction

  // 一"行"的行首指针：低 log2(COMMIT_W)=3 位清零（RobPtr.lineHeadPtr）
  function automatic logic [PTR_W-1:0] lineHeadValue(input logic [PTR_W-1:0] v);
    lineHeadValue = {v[PTR_W-1:BANK_ADDR_W], {BANK_ADDR_W{1'b0}}};
  endfunction

  // ==========================================================================
  // §3 入队请求的整理
  // ==========================================================================
  // 六路 enq 请求打成数组，后面所有"逐路"逻辑都从这里取，避免六份复制粘贴。
  // ★io_enq_req_<i>_bits_exceptionVec 只有 {0,1,2,3,12,20,22} 七个下标★：
  //   Rob 只吃 ExceptionNO.selectFrontend 选出来的那几个，其余被 firtool 消掉了
  //   （docs/rob_iface_contract.tsv 的 PORT 段可核对）。照 24 位写会全部悬空。

  logic                   enqValid   [RENAME_W];
  logic                   enqFirstUop[RENAME_W];
  logic [PTR_W-1:0]       enqRobIdx  [RENAME_W];
  logic                   enqRobIdxFlag [RENAME_W];

  always_comb begin
    enqValid[0]    = io_enq_req_0_valid;
    enqValid[1]    = io_enq_req_1_valid;
    enqValid[2]    = io_enq_req_2_valid;
    enqValid[3]    = io_enq_req_3_valid;
    enqValid[4]    = io_enq_req_4_valid;
    enqValid[5]    = io_enq_req_5_valid;
    enqFirstUop[0] = io_enq_req_0_bits_firstUop;
    enqFirstUop[1] = io_enq_req_1_bits_firstUop;
    enqFirstUop[2] = io_enq_req_2_bits_firstUop;
    enqFirstUop[3] = io_enq_req_3_bits_firstUop;
    enqFirstUop[4] = io_enq_req_4_bits_firstUop;
    enqFirstUop[5] = io_enq_req_5_bits_firstUop;
    enqRobIdx[0]   = io_enq_req_0_bits_robIdx_value;
    enqRobIdx[1]   = io_enq_req_1_bits_robIdx_value;
    enqRobIdx[2]   = io_enq_req_2_bits_robIdx_value;
    enqRobIdx[3]   = io_enq_req_3_bits_robIdx_value;
    enqRobIdx[4]   = io_enq_req_4_bits_robIdx_value;
    enqRobIdx[5]   = io_enq_req_5_bits_robIdx_value;
    enqRobIdxFlag[0] = io_enq_req_0_bits_robIdx_flag;
    enqRobIdxFlag[1] = io_enq_req_1_bits_robIdx_flag;
    enqRobIdxFlag[2] = io_enq_req_2_bits_robIdx_flag;
    enqRobIdxFlag[3] = io_enq_req_3_bits_robIdx_flag;
    enqRobIdxFlag[4] = io_enq_req_4_bits_robIdx_flag;
    enqRobIdxFlag[5] = io_enq_req_5_bits_robIdx_flag;
  end

  // "第 i 路是一条指令的首个 uop 且有效" —— 这就是送给 enqPtrGenModule 的那根网
  // （golden 里叫 _dispatchNum_T*，本核按语义改名，见 gen_rob.py 的 RENAME 表）。
  logic enqFirstUopValidVec [RENAME_W];
  always_comb begin
    for (int i = 0; i < RENAME_W; i++)
      enqFirstUopValidVec[i] = enqValid[i] & enqFirstUop[i];
  end
  assign enqFirstUopValid_0 = enqFirstUopValidVec[0];
  assign enqFirstUopValid_1 = enqFirstUopValidVec[1];
  assign enqFirstUopValid_2 = enqFirstUopValidVec[2];
  assign enqFirstUopValid_3 = enqFirstUopValidVec[3];
  assign enqFirstUopValid_4 = enqFirstUopValidVec[4];
  assign enqFirstUopValid_5 = enqFirstUopValidVec[5];

  // allocatePtrVec(i) = enqPtrVec(该路之前有几个 firstUop 有效)
  // enqPtrVec 由 enqPtrGenModule 给出（本核只读）。
  // ★enqPtrVec_1..5 的 flag 位 golden 根本不读★：firtool 把 enqPtrVec_<1..5>_flag
  //   声明出来接到 RobEnqPtrWrapper 的 io_out_<n>_flag 上，然后**一处也不用**
  //   （只有 enqPtrVec_0_flag 真在用：isEmpty / numValidEntries / redirect 比较）。
  //   本核原先把这 5 根也接进来存进 enqPtrFlag[]，而 enqPtrFlag[] 自己又没人读——
  //   于是 FM 两侧对这 5 个黑盒 pin 推出的方向不一致，报 5 个 unmatched failing
  //   （failing.rpt: `Ref BBPin enqPtrGenModule/io_out_<1..5>_flag / Impl None`）。
  //   修法就是照 golden 把它们悬空：wrapper 里那 5 根 n_enqPtrVec_<n>_flag 仍然
  //   声明并接在黑盒输出上，但不再进本核。
  logic [PTR_W-1:0] enqPtrValue [RENAME_W];
  always_comb begin
    enqPtrValue[0] = enqPtrVec_0_value;
    enqPtrValue[1] = enqPtrVec_1_value;
    enqPtrValue[2] = enqPtrVec_2_value;
    enqPtrValue[3] = enqPtrVec_3_value;
    enqPtrValue[4] = enqPtrVec_4_value;
    enqPtrValue[5] = enqPtrVec_5_value;
  end

  logic [2:0]       allocSel      [RENAME_W];   // PopCount(前 i 路的 firstUop&valid)
  logic [PTR_W-1:0] allocatePtrValue [RENAME_W];
  always_comb begin
    for (int i = 0; i < RENAME_W; i++) begin
      allocSel[i] = 3'd0;
      for (int j = 0; j < RENAME_W; j++)
        if (j < i) allocSel[i] = allocSel[i] + 3'(enqFirstUopValidVec[j]);
    end
    // ★下标一律靠循环+比较★（FMR_ELAB-147：深度 160/下标 8 位时信号下标直接判 147）
    for (int i = 0; i < RENAME_W; i++) begin
      allocatePtrValue[i] = enqPtrValue[0];
      for (int k = 0; k < RENAME_W; k++)
        if (allocSel[i] == 3'(k)) allocatePtrValue[i] = enqPtrValue[k];
    end
  end

  // ==========================================================================
  // §4 入队许可（canAccept / canAcceptForDispatch / canEnqueue）
  // ==========================================================================
  assign io_enq_canAccept =
      allowEnqueue & ~hasBlockBackward & rab_io_canEnq & vtypeBuffer_io_canEnq
      & ~io_fromVecExcpMod_busy;
  assign io_enq_canAcceptForDispatch =
      allowEnqueueForDispatch & ~hasBlockBackward & rab_io_canEnqForDispatch
      & vtypeBuffer_io_canEnqForDispatch & ~io_fromVecExcpMod_busy;

  logic canEnqueue [RENAME_W];      // 首 uop 且被接纳：条目的"分配"事件
  logic canEnqueueEG [RENAME_W];    // 任一 uop 且被接纳：喂 rab / exceptionGen 的事件
  always_comb begin
    for (int i = 0; i < RENAME_W; i++) begin
      canEnqueue[i]   = enqFirstUopValidVec[i] & io_enq_canAccept;
      canEnqueueEG[i] = enqValid[i]            & io_enq_canAccept;
    end
  end
  assign canEnqueueEG_0 = canEnqueueEG[0];
  assign canEnqueueEG_1 = canEnqueueEG[1];
  assign canEnqueueEG_2 = canEnqueueEG[2];
  assign canEnqueueEG_3 = canEnqueueEG[3];
  assign canEnqueueEG_4 = canEnqueueEG[4];
  assign canEnqueueEG_5 = canEnqueueEG[5];

  // dt_pcTransType 的写口：6 路 enq 各一个写口，**写口编号与 enq 路号是反的**
  // （W5<-enq0 ... W0<-enq5，见 docs/rob_iface_contract.tsv 的 PIN 段），
  // 地址取 allocatePtrVec(i).value。W0 的地址直接接顶层 enqPtrVec_0_value，
  // 所以这里只出 W1..W5 五根（allocatePtrVec_1..5）。
  assign allocatePtrVec_1_value = allocatePtrValue[1];
  assign allocatePtrVec_2_value = allocatePtrValue[2];
  assign allocatePtrVec_3_value = allocatePtrValue[3];
  assign allocatePtrVec_4_value = allocatePtrValue[4];
  assign allocatePtrVec_5_value = allocatePtrValue[5];
  assign canEnqueue_0 = canEnqueue[0];
  assign canEnqueue_1 = canEnqueue[1];
  assign canEnqueue_2 = canEnqueue[2];
  assign canEnqueue_3 = canEnqueue[3];
  assign canEnqueue_4 = canEnqueue[4];
  assign canEnqueue_5 = canEnqueue[5];
  // 六个写口写的是同一份数据（AddrTransType 的两位），所以只有 W0_data 一根网。
  assign dtPcTransTypeWdata =
      {io_debugInstrAddrTransType_sv48, io_debugInstrAddrTransType_sv39};

  // ==========================================================================
  // §5 状态机与走回（walk）指针
  // ==========================================================================
  logic       state_next;
  logic       walkFinished;
  logic       isEmpty;

  assign isEmpty = (enqPtrVec_0_flag == deqPtrVec_0_flag)
                 & (enqPtrVec_0_value == deqPtrVec_0_value);

  // walkFinished = walkPtrTrue > lastWalkPtr
  assign walkFinished = ptrGt(walkPtrTrue_flag, walkPtrTrue_value,
                              lastWalkPtr_flag, lastWalkPtr_value);

  assign rab_io_fromRob_walkEnd        = state & walkFinished;
  assign vtypeBuffer_io_fromRob_walkEnd = state & walkFinished;

  // NewRobDeqPtrWrapper 的 io_state 是 2 位（{1'h0, state}），见 PIN 段的 expr 引脚。
  assign deqPtrGenModule_io_state = {1'b0, state};

  assign state_next =
      (io_redirect_valid | state_next_REG) ? S_WALK
    : ((state == S_WALK) & walkFinished & rab_io_status_walkEnd
       & vtypeBuffer_io_status_walkEnd) ? S_IDLE : state;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) state <= S_IDLE;
    else       state <= state_next;
  end
  // ★io.redirect.valid 打一拍在 golden 里是**四个独立寄存器**★
  //   （state_next_REG / redirectValidReg / REG_7 / REG_8），不是一个扇出四处。
  //   FM 跑的是 merge_duplicated_registers=false —— 那是**加强**（比较点只增不减），
  //   所以这四个必须一一对上；合并成一个会让 golden 侧多出三个配不上的比较点。
  //   各自的去处：state_next_REG -> 状态机；redirectValidReg -> 条目冲刷窗口；
  //                REG_7 -> shouldWalkVec；REG_8 -> donotNeedWalk。
  always_ff @(posedge clock) begin
    state_next_REG <= io_redirect_valid;
    REG_7          <= io_redirect_valid;
    REG_8          <= io_redirect_valid;
  end

  // ---- 走回指针的下一拍值 ----
  // (1) redirect：按 snapshot 或 deqPtr_next 的**行首**重装
  // (2) walk 中：整体 +CommitWidth
  logic [PTR_W-1:0] deqPtrReadBankValue;
  logic             deqPtrReadBankFlag;
  logic [PTR_W-1:0] snapPtrReadBankValue;
  logic             snapPtrReadBankFlag;
  logic [PTR_W-1:0] snapSelValue;
  logic             snapSelFlag;

  // snapshots(io.snpt.snptSelect)(0)：4 组快照里选一组的第 0 项
  always_comb begin
    snapSelValue = snapshots_snapshotGen_io_snapshots_0_0_value;
    snapSelFlag  = snapshots_snapshotGen_io_snapshots_0_0_flag;
    case (io_snpt_snptSelect)
      2'd1: begin snapSelValue = snapshots_snapshotGen_io_snapshots_1_0_value;
                  snapSelFlag  = snapshots_snapshotGen_io_snapshots_1_0_flag;  end
      2'd2: begin snapSelValue = snapshots_snapshotGen_io_snapshots_2_0_value;
                  snapSelFlag  = snapshots_snapshotGen_io_snapshots_2_0_flag;  end
      2'd3: begin snapSelValue = snapshots_snapshotGen_io_snapshots_3_0_value;
                  snapSelFlag  = snapshots_snapshotGen_io_snapshots_3_0_flag;  end
      default: ;
    endcase
  end

  assign deqPtrReadBankValue  = lineHeadValue(deqPtrVec_next_0_value);
  assign deqPtrReadBankFlag   = deqPtrVec_next_0_flag;
  assign snapPtrReadBankValue = lineHeadValue(snapSelValue);
  assign snapPtrReadBankFlag  = snapSelFlag;

  logic [PTR_W-1:0] walkPtrVec_next_value [COMMIT_W];
  logic             walkPtrVec_next_flag  [COMMIT_W];
  logic [PTR_W-1:0] walkPtrTrue_next_value;
  logic             walkPtrTrue_next_flag;

  always_comb begin
    for (int i = 0; i < COMMIT_W; i++) begin
      if (io_redirect_valid) begin
        if (io_snpt_useSnpt) begin
          walkPtrVec_next_value[i] =
              ptrAddValue(snapPtrReadBankValue, (PTR_W+1)'(i));
          walkPtrVec_next_flag[i]  =
              ptrAddFlag(snapPtrReadBankFlag, snapPtrReadBankValue, (PTR_W+1)'(i));
        end else begin
          walkPtrVec_next_value[i] =
              ptrAddValue(deqPtrReadBankValue, (PTR_W+1)'(i));
          walkPtrVec_next_flag[i]  =
              ptrAddFlag(deqPtrReadBankFlag, deqPtrReadBankValue, (PTR_W+1)'(i));
        end
      end else if ((state == S_WALK) & ~walkFinished) begin
        walkPtrVec_next_value[i] =
            ptrAddValue(walkPtrVec_value[i], (PTR_W+1)'(COMMIT_W));
        walkPtrVec_next_flag[i]  =
            ptrAddFlag(walkPtrVec_flag[i], walkPtrVec_value[i], (PTR_W+1)'(COMMIT_W));
      end else begin
        walkPtrVec_next_value[i] = walkPtrVec_value[i];
        walkPtrVec_next_flag[i]  = walkPtrVec_flag[i];
      end
    end
  end

  always_comb begin
    if (io_redirect_valid) begin
      walkPtrTrue_next_value = io_snpt_useSnpt ? snapSelValue : deqPtrVec_next_0_value;
      walkPtrTrue_next_flag  = io_snpt_useSnpt ? snapSelFlag  : deqPtrVec_next_0_flag;
    end else if ((state == S_WALK) & ~walkFinished) begin
      walkPtrTrue_next_value = walkPtrVec_next_value[0];
      walkPtrTrue_next_flag  = walkPtrVec_next_flag[0];
    end else begin
      walkPtrTrue_next_value = walkPtrTrue_value;
      walkPtrTrue_next_flag  = walkPtrTrue_flag;
    end
  end

  always_ff @(posedge clock) begin
    for (int i = 0; i < COMMIT_W; i++) begin
      walkPtrVec_value[i]    <= walkPtrVec_next_value[i];
      walkPtrVec_flag[i]     <= walkPtrVec_next_flag[i];
      walkingPtrVec_value[i] <= walkPtrVec_value[i];
      walkingPtrVec_flag[i]  <= walkPtrVec_flag[i];
    end
    walkPtrTrue_value <= walkPtrTrue_next_value;
    walkPtrTrue_flag  <= walkPtrTrue_next_flag;
  end

  // lastWalkPtr：redirect 那一拍锁下"最后一个要走回的条目"
  always_ff @(posedge clock) begin
    if (io_redirect_valid) begin
      if (io_redirect_bits_level) begin   // flushItself
        // robIdx - 1 == robIdx + (160-1)，再把 flag 取反（CircularQueuePtr 的 `-`）
        lastWalkPtr_value <= ptrAddValue(io_redirect_bits_robIdx_value,
                                         (PTR_W+1)'(ROB_SIZE - 1));
        lastWalkPtr_flag  <= ~ptrAddFlag(io_redirect_bits_robIdx_flag,
                                         io_redirect_bits_robIdx_value,
                                         (PTR_W+1)'(ROB_SIZE - 1));
      end else begin
        lastWalkPtr_value <= io_redirect_bits_robIdx_value;
        lastWalkPtr_flag  <= io_redirect_bits_robIdx_flag;
      end
    end
  end

  // T redirect.valid, T+1 walkPtrLowBits 更新, T+2 donotNeedWalk 更新
  always_ff @(posedge clock) begin
    if (io_redirect_valid)
      walkPtrLowBits <= io_snpt_useSnpt ? snapSelValue[BANK_ADDR_W-1:0]
                                        : deqPtrVec_next_0_value[BANK_ADDR_W-1:0];
  end

  // ★这八个写成八个独立寄存器、名字照 golden★（donotNeedWalk_0..7）：
  //   契约表里它们是 name_lock=free —— fm_pins.tcl 不钉它们，只能靠 FM 按名字配。
  //   写成 `logic donotNeedWalk[8]` 会让 impl 侧的比较点叫 `donotNeedWalk_reg[3]`，
  //   与 golden 的 `donotNeedWalk_3_reg` 配不上。八行的代价换一个确定的配对。
  logic [COMMIT_W-1:0] donotNeedWalkNext;
  logic                donotNeedWalkVec [COMMIT_W];
  always_comb begin
    donotNeedWalkVec[0] = donotNeedWalk_0;  donotNeedWalkVec[1] = donotNeedWalk_1;
    donotNeedWalkVec[2] = donotNeedWalk_2;  donotNeedWalkVec[3] = donotNeedWalk_3;
    donotNeedWalkVec[4] = donotNeedWalk_4;  donotNeedWalkVec[5] = donotNeedWalk_5;
    donotNeedWalkVec[6] = donotNeedWalk_6;  donotNeedWalkVec[7] = donotNeedWalk_7;
  end
  always_comb begin
    if (io_redirect_valid)    donotNeedWalkNext = {COMMIT_W{1'b1}};
    else if (REG_8)
      for (int i = 0; i < COMMIT_W; i++)
        donotNeedWalkNext[i] = (BANK_ADDR_W'(i) < walkPtrLowBits);
    else                      donotNeedWalkNext = {COMMIT_W{1'b0}};
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      donotNeedWalk_0 <= 1'b0;  donotNeedWalk_1 <= 1'b0;
      donotNeedWalk_2 <= 1'b0;  donotNeedWalk_3 <= 1'b0;
      donotNeedWalk_4 <= 1'b0;  donotNeedWalk_5 <= 1'b0;
      donotNeedWalk_6 <= 1'b0;  donotNeedWalk_7 <= 1'b0;
    end else begin
      donotNeedWalk_0 <= donotNeedWalkNext[0];
      donotNeedWalk_1 <= donotNeedWalkNext[1];
      donotNeedWalk_2 <= donotNeedWalkNext[2];
      donotNeedWalk_3 <= donotNeedWalkNext[3];
      donotNeedWalk_4 <= donotNeedWalkNext[4];
      donotNeedWalk_5 <= donotNeedWalkNext[5];
      donotNeedWalk_6 <= donotNeedWalkNext[6];
      donotNeedWalk_7 <= donotNeedWalkNext[7];
    end
  end

  // ==========================================================================
  // §6 入队计数与 allowEnqueue
  // ==========================================================================
  // ★这里的加法全是 8 位回绕★（Chisel 的 `+` 同宽截断）：
  //   numValidEntries = flag 相同 ? enq-deq : 160+enq-deq，两者都在 8 位里算。
  //   golden 把后者折成 `(enq - 8'h60) - deq`：**-96 ≡ +160 (mod 256)**，
  //   所以 `enq - 96` 就是 `enq + 160`。
  // ★真 bug（UT 首跑抓到，2026-09-20）★：这里原先照着注释写成 `enq - 160`。
  //   注释把 "160 mod 256 = -96" 这句话读反了 —— 该减的是 **96**，不是 160。
  //   反例（enq=0x20, deq=0xF0）：golden 208 / 原写法 144。
  //   征状是 io_enq_canAccept / canAcceptForDispatch / io_perf_12..15 齐错。
  //   写成 `+ ROB_SIZE` 而不是 `- 8'h60`，是因为前者一眼可读且在 8 位里完全等价。
  logic [PTR_W-1:0] numValidEntries;
  logic [2:0]       dispatchNum;
  logic [PTR_W-1:0] enqCountSum;

  always_comb begin
    dispatchNum = 3'd0;
    if (io_enq_canAccept)
      for (int i = 0; i < RENAME_W; i++)
        dispatchNum = dispatchNum + 3'(enqFirstUopValidVec[i]);
  end

  assign numValidEntries = (enqPtrVec_0_flag == deqPtrVec_0_flag)
      ? (enqPtrVec_0_value - deqPtrVec_0_value)
      : ((enqPtrVec_0_value + PTR_W'(ROB_SIZE)) - deqPtrVec_0_value);
  assign enqCountSum = numValidEntries + {5'h0, dispatchNum};

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      allowEnqueue            <= 1'b1;
      allowEnqueueForDispatch <= 1'b1;
    end else begin
      allowEnqueue            <= enqCountSum <= PTR_W'(ROB_SIZE - RENAME_W);
      allowEnqueueForDispatch <= enqCountSum <= PTR_W'(ROB_SIZE - 2*RENAME_W);
    end
  end

  always_ff @(posedge clock) io_enq_isEmpty_REG <= isEmpty & ~(
      enqValid[0] | enqValid[1] | enqValid[2] |
      enqValid[3] | enqValid[4] | enqValid[5]);
  assign io_enq_isEmpty = io_enq_isEmpty_REG;

  // ==========================================================================
  // §7 阻塞类状态位（hasBlockBackward / hasWaitForward / hasWFI）
  // ==========================================================================
  logic anyBlockBackward;
  logic anyWaitForward;
  always_comb begin
    anyBlockBackward =
        (enqValid[0] & io_enq_req_0_bits_blockBackward) |
        (enqValid[1] & io_enq_req_1_bits_blockBackward) |
        (enqValid[2] & io_enq_req_2_bits_blockBackward) |
        (enqValid[3] & io_enq_req_3_bits_blockBackward) |
        (enqValid[4] & io_enq_req_4_bits_blockBackward) |
        (enqValid[5] & io_enq_req_5_bits_blockBackward);
    anyWaitForward =
        (canEnqueue[0] & io_enq_req_0_bits_waitForward) |
        (canEnqueue[1] & io_enq_req_1_bits_waitForward) |
        (canEnqueue[2] & io_enq_req_2_bits_waitForward) |
        (canEnqueue[3] & io_enq_req_3_bits_waitForward) |
        (canEnqueue[4] & io_enq_req_4_bits_waitForward) |
        (canEnqueue[5] & io_enq_req_5_bits_waitForward);
  end

  // ★★ 这两位的形状是 `置位 | (~清除 & 保持)` —— **置位压过清除**，不是
  //    「先清后置」的优先级链。★★
  // 真 bug（UT 探针 2026-09-20 抓到，首处内部分歧就是 hasBlockBackward，cyc=10362 g=1 x=0）：
  //   原先写成 `if (isEmpty) <= 0; else if (置位条件) <= 1;`，让**清除压过置位**。
  //   于是「ROB 空着、同一拍进来一条 blockBackward 指令」时 golden 置 1、本核清 0。
  //   它是全局第一处分歧：hasBlockBackward 一错，io_enq_canAccept 跟着错，
  //   入队被错误放行，指针/条目/几乎所有输出随后全线崩开
  //   （20k 拍那轮 errors=898651 —— 一个根因，不是九十万个）。
  // golden 原文：
  //   hasBlockBackward <= |(enq_req_i_valid & blockBackward & canAccept)
  //                       | ~isEmpty & hasBlockBackward;
  //   hasWaitForward   <= |(canEnqueue_i & waitForward)
  //                       | ~((state & |shouldWalkVec) | (isCommit & |commitValid))
  //                         & hasWaitForward;      （golden 的 _GEN_13485）
  // 同族的 hasWFI 本来就写对了（`io_wfi_enable & (setWFI | (~clearWFI & hasWFI))`），
  // 这两位没跟上——所以这三位现在统一成同一个形状，别再分叉。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) hasBlockBackward <= 1'b0;
    else       hasBlockBackward <= (anyBlockBackward & io_enq_canAccept)
                                 | (~isEmpty & hasBlockBackward);
  end
  assign hasBlockBackwardOut = hasBlockBackward;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) hasWaitForward <= 1'b0;
    else       hasWaitForward <= anyWaitForward
                               | (~(commitsHasWalkInstr | commitsHasCommitInstr)
                                  & hasWaitForward);
  end
  assign hasWaitForwardOut = hasWaitForward;



  // ==========================================================================
  // §8 写回口的整理
  // ==========================================================================
  // ★写回口的下标是稀疏的，而且每个子集的下标集合只有 golden 能告诉你★
  //   （KunminghuV2Config 决定的，Scala 源里看不出来；见 rob_pkg 里的
  //    EXU_WB_N/FFLAGS_WB_N/... 和 docs/rob_iface_contract.tsv 的 WBSUBSET 段）。
  //   照下标当稠密数组写会**整体错位**，而且错得很安静。
  // 这里先把每个子集摊成紧凑数组，后面 160 个条目的逻辑就只对数组循环。

  // ---- exuWBs：io_exuWriteback 去掉 std 两路，0..24 ----
  logic             exuWbValid  [EXU_N];
  logic [PTR_W-1:0] exuWbRobIdx [EXU_N];
  logic [4:0]       exuWbNum    [EXU_N];   // io_writebackNums_<i>_bits
  always_comb begin
    exuWbValid[0] = io_exuWriteback_0_valid;
    exuWbValid[1] = io_exuWriteback_1_valid;
    exuWbValid[2] = io_exuWriteback_2_valid;
    exuWbValid[3] = io_exuWriteback_3_valid;
    exuWbValid[4] = io_exuWriteback_4_valid;
    exuWbValid[5] = io_exuWriteback_5_valid;
    exuWbValid[6] = io_exuWriteback_6_valid;
    exuWbValid[7] = io_exuWriteback_7_valid;
    exuWbValid[8] = io_exuWriteback_8_valid;
    exuWbValid[9] = io_exuWriteback_9_valid;
    exuWbValid[10] = io_exuWriteback_10_valid;
    exuWbValid[11] = io_exuWriteback_11_valid;
    exuWbValid[12] = io_exuWriteback_12_valid;
    exuWbValid[13] = io_exuWriteback_13_valid;
    exuWbValid[14] = io_exuWriteback_14_valid;
    exuWbValid[15] = io_exuWriteback_15_valid;
    exuWbValid[16] = io_exuWriteback_16_valid;
    exuWbValid[17] = io_exuWriteback_17_valid;
    exuWbValid[18] = io_exuWriteback_18_valid;
    exuWbValid[19] = io_exuWriteback_19_valid;
    exuWbValid[20] = io_exuWriteback_20_valid;
    exuWbValid[21] = io_exuWriteback_21_valid;
    exuWbValid[22] = io_exuWriteback_22_valid;
    exuWbValid[23] = io_exuWriteback_23_valid;
    exuWbValid[24] = io_exuWriteback_24_valid;
    exuWbRobIdx[0] = io_exuWriteback_0_bits_robIdx_value;
    exuWbRobIdx[1] = io_exuWriteback_1_bits_robIdx_value;
    exuWbRobIdx[2] = io_exuWriteback_2_bits_robIdx_value;
    exuWbRobIdx[3] = io_exuWriteback_3_bits_robIdx_value;
    exuWbRobIdx[4] = io_exuWriteback_4_bits_robIdx_value;
    exuWbRobIdx[5] = io_exuWriteback_5_bits_robIdx_value;
    exuWbRobIdx[6] = io_exuWriteback_6_bits_robIdx_value;
    exuWbRobIdx[7] = io_exuWriteback_7_bits_robIdx_value;
    exuWbRobIdx[8] = io_exuWriteback_8_bits_robIdx_value;
    exuWbRobIdx[9] = io_exuWriteback_9_bits_robIdx_value;
    exuWbRobIdx[10] = io_exuWriteback_10_bits_robIdx_value;
    exuWbRobIdx[11] = io_exuWriteback_11_bits_robIdx_value;
    exuWbRobIdx[12] = io_exuWriteback_12_bits_robIdx_value;
    exuWbRobIdx[13] = io_exuWriteback_13_bits_robIdx_value;
    exuWbRobIdx[14] = io_exuWriteback_14_bits_robIdx_value;
    exuWbRobIdx[15] = io_exuWriteback_15_bits_robIdx_value;
    exuWbRobIdx[16] = io_exuWriteback_16_bits_robIdx_value;
    exuWbRobIdx[17] = io_exuWriteback_17_bits_robIdx_value;
    exuWbRobIdx[18] = io_exuWriteback_18_bits_robIdx_value;
    exuWbRobIdx[19] = io_exuWriteback_19_bits_robIdx_value;
    exuWbRobIdx[20] = io_exuWriteback_20_bits_robIdx_value;
    exuWbRobIdx[21] = io_exuWriteback_21_bits_robIdx_value;
    exuWbRobIdx[22] = io_exuWriteback_22_bits_robIdx_value;
    exuWbRobIdx[23] = io_exuWriteback_23_bits_robIdx_value;
    exuWbRobIdx[24] = io_exuWriteback_24_bits_robIdx_value;
    exuWbNum[0] = io_writebackNums_0_bits;
    exuWbNum[1] = io_writebackNums_1_bits;
    exuWbNum[2] = io_writebackNums_2_bits;
    exuWbNum[3] = io_writebackNums_3_bits;
    exuWbNum[4] = io_writebackNums_4_bits;
    exuWbNum[5] = io_writebackNums_5_bits;
    exuWbNum[6] = io_writebackNums_6_bits;
    exuWbNum[7] = io_writebackNums_7_bits;
    exuWbNum[8] = io_writebackNums_8_bits;
    exuWbNum[9] = io_writebackNums_9_bits;
    exuWbNum[10] = io_writebackNums_10_bits;
    exuWbNum[11] = io_writebackNums_11_bits;
    exuWbNum[12] = io_writebackNums_12_bits;
    exuWbNum[13] = io_writebackNums_13_bits;
    exuWbNum[14] = io_writebackNums_14_bits;
    exuWbNum[15] = io_writebackNums_15_bits;
    exuWbNum[16] = io_writebackNums_16_bits;
    exuWbNum[17] = io_writebackNums_17_bits;
    exuWbNum[18] = io_writebackNums_18_bits;
    exuWbNum[19] = io_writebackNums_19_bits;
    exuWbNum[20] = io_writebackNums_20_bits;
    exuWbNum[21] = io_writebackNums_21_bits;
    exuWbNum[22] = io_writebackNums_22_bits;
    exuWbNum[23] = io_writebackNums_23_bits;
    exuWbNum[24] = io_writebackNums_24_bits;
  end

  // ---- stdWBs：{25,26}，只用来放 stdWritebacked ----
  logic             stdWbValid  [STD_N];
  logic [PTR_W-1:0] stdWbRobIdx [STD_N];
  always_comb begin
    stdWbValid[0]  = io_exuWriteback_25_valid;
    stdWbRobIdx[0] = io_exuWriteback_25_bits_robIdx_value;
    stdWbValid[1]  = io_exuWriteback_26_valid;
    stdWbRobIdx[1] = io_exuWriteback_26_bits_robIdx_value;
  end

  // ---- fflagsWBs：{5,8,9,10,11,12,13,14,15,16,17} ----
  logic             fflagsWbValid  [FFLAGS_WB_N];
  logic [PTR_W-1:0] fflagsWbRobIdx [FFLAGS_WB_N];
  logic             fflagsWbWflags [FFLAGS_WB_N];
  logic [FFLAGS_W-1:0] fflagsWbData [FFLAGS_WB_N];
  always_comb begin
    fflagsWbValid[0]  = io_exuWriteback_5_valid;
    fflagsWbRobIdx[0] = io_exuWriteback_5_bits_robIdx_value;
    fflagsWbWflags[0] = io_exuWriteback_5_bits_wflags;
    fflagsWbData[0]   = io_exuWriteback_5_bits_fflags;
    fflagsWbValid[1]  = io_exuWriteback_8_valid;
    fflagsWbRobIdx[1] = io_exuWriteback_8_bits_robIdx_value;
    fflagsWbWflags[1] = io_exuWriteback_8_bits_wflags;
    fflagsWbData[1]   = io_exuWriteback_8_bits_fflags;
    fflagsWbValid[2]  = io_exuWriteback_9_valid;
    fflagsWbRobIdx[2] = io_exuWriteback_9_bits_robIdx_value;
    fflagsWbWflags[2] = io_exuWriteback_9_bits_wflags;
    fflagsWbData[2]   = io_exuWriteback_9_bits_fflags;
    fflagsWbValid[3]  = io_exuWriteback_10_valid;
    fflagsWbRobIdx[3] = io_exuWriteback_10_bits_robIdx_value;
    fflagsWbWflags[3] = io_exuWriteback_10_bits_wflags;
    fflagsWbData[3]   = io_exuWriteback_10_bits_fflags;
    fflagsWbValid[4]  = io_exuWriteback_11_valid;
    fflagsWbRobIdx[4] = io_exuWriteback_11_bits_robIdx_value;
    fflagsWbWflags[4] = io_exuWriteback_11_bits_wflags;
    fflagsWbData[4]   = io_exuWriteback_11_bits_fflags;
    fflagsWbValid[5]  = io_exuWriteback_12_valid;
    fflagsWbRobIdx[5] = io_exuWriteback_12_bits_robIdx_value;
    fflagsWbWflags[5] = io_exuWriteback_12_bits_wflags;
    fflagsWbData[5]   = io_exuWriteback_12_bits_fflags;
    fflagsWbValid[6]  = io_exuWriteback_13_valid;
    fflagsWbRobIdx[6] = io_exuWriteback_13_bits_robIdx_value;
    fflagsWbWflags[6] = io_exuWriteback_13_bits_wflags;
    fflagsWbData[6]   = io_exuWriteback_13_bits_fflags;
    fflagsWbValid[7]  = io_exuWriteback_14_valid;
    fflagsWbRobIdx[7] = io_exuWriteback_14_bits_robIdx_value;
    fflagsWbWflags[7] = io_exuWriteback_14_bits_wflags;
    fflagsWbData[7]   = io_exuWriteback_14_bits_fflags;
    fflagsWbValid[8]  = io_exuWriteback_15_valid;
    fflagsWbRobIdx[8] = io_exuWriteback_15_bits_robIdx_value;
    fflagsWbWflags[8] = io_exuWriteback_15_bits_wflags;
    fflagsWbData[8]   = io_exuWriteback_15_bits_fflags;
    fflagsWbValid[9]  = io_exuWriteback_16_valid;
    fflagsWbRobIdx[9] = io_exuWriteback_16_bits_robIdx_value;
    fflagsWbWflags[9] = io_exuWriteback_16_bits_wflags;
    fflagsWbData[9]   = io_exuWriteback_16_bits_fflags;
    fflagsWbValid[10]  = io_exuWriteback_17_valid;
    fflagsWbRobIdx[10] = io_exuWriteback_17_bits_robIdx_value;
    fflagsWbWflags[10] = io_exuWriteback_17_bits_wflags;
    fflagsWbData[10]   = io_exuWriteback_17_bits_fflags;
  end

  // ---- vxsatWBs：{13,15} ----
  logic             vxsatWbValid  [VXSAT_WB_N];
  logic [PTR_W-1:0] vxsatWbRobIdx [VXSAT_WB_N];
  logic             vxsatWbData   [VXSAT_WB_N];
  always_comb begin
    vxsatWbValid[0]  = io_exuWriteback_13_valid;
    vxsatWbRobIdx[0] = io_exuWriteback_13_bits_robIdx_value;
    vxsatWbData[0]   = io_exuWriteback_13_bits_vxsat;
    vxsatWbValid[1]  = io_exuWriteback_15_valid;
    vxsatWbRobIdx[1] = io_exuWriteback_15_bits_robIdx_value;
    vxsatWbData[1]   = io_exuWriteback_15_bits_vxsat;
  end

  // ---- branchWBs：{1,3,5}，只取 taken（trace 的 itype 要改写成 Taken）----
  logic             brhWbValid  [BRH_WB_N];
  logic [PTR_W-1:0] brhWbRobIdx [BRH_WB_N];
  logic             brhWbTaken  [BRH_WB_N];
  always_comb begin
    brhWbValid[0]  = io_exuWriteback_1_valid;
    brhWbRobIdx[0] = io_exuWriteback_1_bits_robIdx_value;
    brhWbTaken[0]  = io_exuWriteback_1_bits_redirect_bits_cfiUpdate_taken;
    brhWbValid[1]  = io_exuWriteback_3_valid;
    brhWbRobIdx[1] = io_exuWriteback_3_bits_robIdx_value;
    brhWbTaken[1]  = io_exuWriteback_3_bits_redirect_bits_cfiUpdate_taken;
    brhWbValid[2]  = io_exuWriteback_5_valid;
    brhWbRobIdx[2] = io_exuWriteback_5_bits_robIdx_value;
    brhWbTaken[2]  = io_exuWriteback_5_bits_redirect_bits_cfiUpdate_taken;
  end

  // ---- exceptionWBs：io_writeback 的 {7,13,14,18..24}，与
  //      io_writebackNeedFlush 的 {0,1,2,6,7,8,9,10,11,12} **靠位置对齐**
  //      （不是靠名字/下标！见 docs/rob_iface_contract.tsv 的 EXCPWB 段）。
  logic             excpWbValid     [EXCP_WB_N];
  logic [PTR_W-1:0] excpWbRobIdx    [EXCP_WB_N];
  logic             excpWbNeedFlush [EXCP_WB_N];
  always_comb begin
    excpWbValid[0]     = io_writeback_7_valid;
    excpWbRobIdx[0]    = io_writeback_7_bits_robIdx_value;
    excpWbNeedFlush[0] = io_writebackNeedFlush_0;
    excpWbValid[1]     = io_writeback_13_valid;
    excpWbRobIdx[1]    = io_writeback_13_bits_robIdx_value;
    excpWbNeedFlush[1] = io_writebackNeedFlush_1;
    excpWbValid[2]     = io_writeback_14_valid;
    excpWbRobIdx[2]    = io_writeback_14_bits_robIdx_value;
    excpWbNeedFlush[2] = io_writebackNeedFlush_2;
    excpWbValid[3]     = io_writeback_18_valid;
    excpWbRobIdx[3]    = io_writeback_18_bits_robIdx_value;
    excpWbNeedFlush[3] = io_writebackNeedFlush_6;
    excpWbValid[4]     = io_writeback_19_valid;
    excpWbRobIdx[4]    = io_writeback_19_bits_robIdx_value;
    excpWbNeedFlush[4] = io_writebackNeedFlush_7;
    excpWbValid[5]     = io_writeback_20_valid;
    excpWbRobIdx[5]    = io_writeback_20_bits_robIdx_value;
    excpWbNeedFlush[5] = io_writebackNeedFlush_8;
    excpWbValid[6]     = io_writeback_21_valid;
    excpWbRobIdx[6]    = io_writeback_21_bits_robIdx_value;
    excpWbNeedFlush[6] = io_writebackNeedFlush_9;
    excpWbValid[7]     = io_writeback_22_valid;
    excpWbRobIdx[7]    = io_writeback_22_bits_robIdx_value;
    excpWbNeedFlush[7] = io_writebackNeedFlush_10;
    excpWbValid[8]     = io_writeback_23_valid;
    excpWbRobIdx[8]    = io_writeback_23_bits_robIdx_value;
    excpWbNeedFlush[8] = io_writebackNeedFlush_11;
    excpWbValid[9]     = io_writeback_24_valid;
    excpWbRobIdx[9]    = io_writeback_24_bits_robIdx_value;
    excpWbNeedFlush[9] = io_writebackNeedFlush_12;
  end

  // ---- redirectWBs：io_writeback 的 {1,3,5,7}，用于 misPredBlock ----
  logic misPredWb;
  assign misPredWb =
      (io_writeback_1_valid & io_writeback_1_bits_redirect_valid & io_writeback_1_bits_redirect_bits_cfiUpdate_isMisPred) |
      (io_writeback_3_valid & io_writeback_3_bits_redirect_valid & io_writeback_3_bits_redirect_bits_cfiUpdate_isMisPred) |
      (io_writeback_5_valid & io_writeback_5_bits_redirect_valid & io_writeback_5_bits_redirect_bits_cfiUpdate_isMisPred) |
      (io_writeback_7_valid & io_writeback_7_bits_redirect_valid & io_writeback_7_bits_redirect_bits_cfiUpdate_isMisPred);



  // ==========================================================================
  // §9 入队：条目存储的写入
  // ==========================================================================
  // 这里有**两种完全不同的选择结构**，弄混就是真 bug：
  //
  //   (A) `connectEnq` 那一族字段：Scala 是 `for (i <- 0 until RobSize)` +
  //       `Mux1H(enqOH, ...)` —— ★Mux1H 在 golden 里展开成"按位或"，不是优先级选择★。
  //       非 one-hot 时两者**不等价**（或 vs 取最后一个命中），FM 一定会抓到。
  //       所以下面一律写成 `|= 掩码 & 值` 的或形式。
  //   (B) `vls` / `mmio` / `interrupt_safe` / `debug_microOp` 那一族：Scala 是
  //       `for (i <- 0 until RenameWidth)` + `when(canEnqueue(i))` 写
  //       `allocatePtrVec(i).value` 那一条 —— 后写的赢，也就是
  //       ★第 5 路优先级最高★的优先链（golden 里就是 `if (canEnq_5) ... else if (canEnq_4)`）。
  //
  // 条目下标一律 `for` + 比较，没有一处信号直接索引（FMR_ELAB-147）。

  // ---- 六路 enq 的派生量 ----
  logic enqNeedWriteRf  [RENAME_W];   // rfWen|fpWen|vecWen|v0Wen|vlWen
  logic enqAllowIntr    [RENAME_W];   // 允许中断：非访存/非 fence/非 csr/非 vset/非 amo
  logic enqNeedFlush    [RENAME_W];   // hasException | flushPipe

  always_comb begin
    enqNeedWriteRf[0] = io_enq_req_0_bits_rfWen | io_enq_req_0_bits_fpWen
                       | io_enq_req_0_bits_vecWen | io_enq_req_0_bits_v0Wen
                       | io_enq_req_0_bits_vlWen;
    enqNeedWriteRf[1] = io_enq_req_1_bits_rfWen | io_enq_req_1_bits_fpWen
                       | io_enq_req_1_bits_vecWen | io_enq_req_1_bits_v0Wen
                       | io_enq_req_1_bits_vlWen;
    enqNeedWriteRf[2] = io_enq_req_2_bits_rfWen | io_enq_req_2_bits_fpWen
                       | io_enq_req_2_bits_vecWen | io_enq_req_2_bits_v0Wen
                       | io_enq_req_2_bits_vlWen;
    enqNeedWriteRf[3] = io_enq_req_3_bits_rfWen | io_enq_req_3_bits_fpWen
                       | io_enq_req_3_bits_vecWen | io_enq_req_3_bits_v0Wen
                       | io_enq_req_3_bits_vlWen;
    enqNeedWriteRf[4] = io_enq_req_4_bits_rfWen | io_enq_req_4_bits_fpWen
                       | io_enq_req_4_bits_vecWen | io_enq_req_4_bits_v0Wen
                       | io_enq_req_4_bits_vlWen;
    enqNeedWriteRf[5] = io_enq_req_5_bits_rfWen | io_enq_req_5_bits_fpWen
                       | io_enq_req_5_bits_vecWen | io_enq_req_5_bits_v0Wen
                       | io_enq_req_5_bits_vlWen;
  end

  always_comb begin
    enqAllowIntr[0] = ~(~io_enq_req_0_bits_commitType[2] & io_enq_req_0_bits_commitType[1])
                     & ~io_enq_req_0_bits_fuType[FU_FENCE]
                     & ~io_enq_req_0_bits_fuType[FU_CSR]
                     & ~io_enq_req_0_bits_isVset
                     & ~io_enq_req_0_bits_fuType[FU_MOU];
    enqAllowIntr[1] = ~(~io_enq_req_1_bits_commitType[2] & io_enq_req_1_bits_commitType[1])
                     & ~io_enq_req_1_bits_fuType[FU_FENCE]
                     & ~io_enq_req_1_bits_fuType[FU_CSR]
                     & ~io_enq_req_1_bits_isVset
                     & ~io_enq_req_1_bits_fuType[FU_MOU];
    enqAllowIntr[2] = ~(~io_enq_req_2_bits_commitType[2] & io_enq_req_2_bits_commitType[1])
                     & ~io_enq_req_2_bits_fuType[FU_FENCE]
                     & ~io_enq_req_2_bits_fuType[FU_CSR]
                     & ~io_enq_req_2_bits_isVset
                     & ~io_enq_req_2_bits_fuType[FU_MOU];
    enqAllowIntr[3] = ~(~io_enq_req_3_bits_commitType[2] & io_enq_req_3_bits_commitType[1])
                     & ~io_enq_req_3_bits_fuType[FU_FENCE]
                     & ~io_enq_req_3_bits_fuType[FU_CSR]
                     & ~io_enq_req_3_bits_isVset
                     & ~io_enq_req_3_bits_fuType[FU_MOU];
    enqAllowIntr[4] = ~(~io_enq_req_4_bits_commitType[2] & io_enq_req_4_bits_commitType[1])
                     & ~io_enq_req_4_bits_fuType[FU_FENCE]
                     & ~io_enq_req_4_bits_fuType[FU_CSR]
                     & ~io_enq_req_4_bits_isVset
                     & ~io_enq_req_4_bits_fuType[FU_MOU];
    enqAllowIntr[5] = ~(~io_enq_req_5_bits_commitType[2] & io_enq_req_5_bits_commitType[1])
                     & ~io_enq_req_5_bits_fuType[FU_FENCE]
                     & ~io_enq_req_5_bits_fuType[FU_CSR]
                     & ~io_enq_req_5_bits_isVset
                     & ~io_enq_req_5_bits_fuType[FU_MOU];
  end

  always_comb begin
    enqNeedFlush[0] = io_enq_req_0_bits_hasException | io_enq_req_0_bits_flushPipe;
    enqNeedFlush[1] = io_enq_req_1_bits_hasException | io_enq_req_1_bits_flushPipe;
    enqNeedFlush[2] = io_enq_req_2_bits_hasException | io_enq_req_2_bits_flushPipe;
    enqNeedFlush[3] = io_enq_req_3_bits_hasException | io_enq_req_3_bits_flushPipe;
    enqNeedFlush[4] = io_enq_req_4_bits_hasException | io_enq_req_4_bits_flushPipe;
    enqNeedFlush[5] = io_enq_req_5_bits_hasException | io_enq_req_5_bits_flushPipe;
  end

  // ---- enqOH[i][j]：第 j 路分配到第 i 条 ----
  // ★Scala 断言 PopCount(enqOH) < 2★，但**下面的或形式不依赖这条断言**
  //   —— golden 就是或，照 one-hot 优化成优先级选择会在非 one-hot 时不等价。
  logic enqOH        [ROB_SIZE][RENAME_W];
  logic enqOHAny     [ROB_SIZE];
  logic uopCanEnq    [ROB_SIZE][RENAME_W];   // 按 req 自带的 robIdx 匹配（不是 allocatePtr）
  logic instCanEnq   [ROB_SIZE][RENAME_W];
  logic instCanEnqAny[ROB_SIZE];

  always_comb begin
    for (int i = 0; i < ROB_SIZE; i++) begin
      enqOHAny[i]      = 1'b0;
      instCanEnqAny[i] = 1'b0;
      for (int j = 0; j < RENAME_W; j++) begin
        enqOH[i][j]      = canEnqueue[j]   & (allocatePtrValue[j] == PTR_W'(i));
        uopCanEnq[i][j]  = canEnqueueEG[j] & (enqRobIdx[j]        == PTR_W'(i));
        instCanEnq[i][j] = canEnqueue[j]   & (enqRobIdx[j]        == PTR_W'(i));
        enqOHAny[i]      = enqOHAny[i]      | enqOH[i][j];
        instCanEnqAny[i] = instCanEnqAny[i] | instCanEnq[i][j];
      end
    end
  end

  // ---- (A) connectEnq 的 payload：先把六路摊成同构的结构体，再按位或 ----
  // ★结构体只用在组合路径上★：存储仍是"每字段一个非打包数组"（见 §1 的说明），
  //   打包成结构体存储会让 FM 只看到一根位串，169,168 个 pin 全部配不上。
  typedef struct packed {
    logic                        wflags;
    logic [COMMITTYPE_W-1:0]     commitType;
    logic                        ftqIdx_flag;
    logic [FTQ_PTR_W-1:0]        ftqIdx_value;
    logic [FTQ_OFF_W-1:0]        ftqOffset;
    logic                        isRVC;
    logic                        isVset;
    logic [INSTRSIZE_W-1:0]      instrSize;
    logic                        rfWen;
    logic                        fpWen;
    logic                        dirtyVs;
    logic [ITYPE_W-1:0]          traceBlockInPipe_itype;
    logic [IRETIRE_W-1:0]        traceBlockInPipe_iretire;
    logic                        traceBlockInPipe_ilastsize;
    logic [VADDR_W-1:0]          debug_pc;
    logic [31:0]                 debug_instr;
    logic [LREG_W-1:0]           basicDebug_ldest;
    logic [PREG_W-1:0]           basicDebug_pdest;
    logic                        basicDebug_fpWen;
    logic                        basicDebug_vecWen;
    logic                        basicDebug_v0Wen;
    logic                        basicDebug_eliminatedMove;
    logic                        basicDebug_isXSTrap;
    logic [FUTYPE_W-1:0]         debug_fuType;
    // ★不是 isHls，是 fuOpType[8:4]★：golden 的 isHls **不是** Mux1H 选出来的
    //   per-port isHls，而是拿 Mux1H **之后**的 fuType / fuOpType 再算一次
    //   （golden: `_GEN_3881 == 35'h8000 & _GEN_11894[0] & ...`，_GEN_3881 /
    //   _GEN_11894 都是按位或的 Mux1H 结果）。isHls 是 fuType/fuOpType 的
    //   **非线性**函数，所以 Mux1H 与它不可交换：enqOH 非 one-hot 时
    //   `Mux1H(f(x))` ≠ `f(Mux1H(x))`，FM 一定抓得到。见下面的 enqSelIsHls。
    logic [4:0]                  fuOpHi;          // fuOpType[8:4]
    logic                        needFlush;
    logic [LREG_W-1:0]           basicDebug_vd;   // instr[11:7]（XSInstBitFields.VD）
  } rob_enq_sel_t;

  rob_enq_sel_t enqBits [RENAME_W];
  rob_enq_sel_t enqSel  [ROB_SIZE];
  logic         enqSelIsHls [ROB_SIZE];   // Mux1H 之后再算的 isHls（见上面 fuOpHi）

  always_comb begin
    enqBits[0].wflags                     = io_enq_req_0_bits_wfflags;
    enqBits[0].commitType                 = io_enq_req_0_bits_commitType;
    enqBits[0].ftqIdx_flag                = io_enq_req_0_bits_ftqPtr_flag;
    enqBits[0].ftqIdx_value               = io_enq_req_0_bits_ftqPtr_value;
    enqBits[0].ftqOffset                  = io_enq_req_0_bits_ftqOffset;
    enqBits[0].isRVC                      = io_enq_req_0_bits_preDecodeInfo_isRVC;
    enqBits[0].isVset                     = io_enq_req_0_bits_isVset;
    enqBits[0].instrSize                  = io_enq_req_0_bits_instrSize;
    enqBits[0].rfWen                      = io_enq_req_0_bits_rfWen;
    enqBits[0].fpWen                      = io_enq_req_0_bits_dirtyFs;
    enqBits[0].dirtyVs                    = io_enq_req_0_bits_dirtyVs;
    enqBits[0].traceBlockInPipe_itype     = io_enq_req_0_bits_traceBlockInPipe_itype;
    enqBits[0].traceBlockInPipe_iretire   = io_enq_req_0_bits_traceBlockInPipe_iretire;
    enqBits[0].traceBlockInPipe_ilastsize = io_enq_req_0_bits_traceBlockInPipe_ilastsize;
    enqBits[0].debug_pc                   = io_enq_req_0_bits_pc;
    enqBits[0].debug_instr                = io_enq_req_0_bits_instr;
    enqBits[0].basicDebug_ldest           = io_enq_req_0_bits_ldest;
    enqBits[0].basicDebug_pdest           = io_enq_req_0_bits_pdest;
    enqBits[0].basicDebug_fpWen           = io_enq_req_0_bits_fpWen;
    enqBits[0].basicDebug_vecWen          = io_enq_req_0_bits_vecWen;
    enqBits[0].basicDebug_v0Wen           = io_enq_req_0_bits_v0Wen;
    enqBits[0].basicDebug_eliminatedMove  = io_enq_req_0_bits_eliminatedMove;
    enqBits[0].basicDebug_isXSTrap        = io_enq_req_0_bits_isXSTrap;
    enqBits[0].debug_fuType               = io_enq_req_0_bits_fuType;
    enqBits[0].fuOpHi                     = io_enq_req_0_bits_fuOpType[8:4];
    enqBits[0].needFlush                  = enqNeedFlush[0];
    enqBits[0].basicDebug_vd              = io_enq_req_0_bits_instr[11:7];

    enqBits[1].wflags                     = io_enq_req_1_bits_wfflags;
    enqBits[1].commitType                 = io_enq_req_1_bits_commitType;
    enqBits[1].ftqIdx_flag                = io_enq_req_1_bits_ftqPtr_flag;
    enqBits[1].ftqIdx_value               = io_enq_req_1_bits_ftqPtr_value;
    enqBits[1].ftqOffset                  = io_enq_req_1_bits_ftqOffset;
    enqBits[1].isRVC                      = io_enq_req_1_bits_preDecodeInfo_isRVC;
    enqBits[1].isVset                     = io_enq_req_1_bits_isVset;
    enqBits[1].instrSize                  = io_enq_req_1_bits_instrSize;
    enqBits[1].rfWen                      = io_enq_req_1_bits_rfWen;
    enqBits[1].fpWen                      = io_enq_req_1_bits_dirtyFs;
    enqBits[1].dirtyVs                    = io_enq_req_1_bits_dirtyVs;
    enqBits[1].traceBlockInPipe_itype     = io_enq_req_1_bits_traceBlockInPipe_itype;
    enqBits[1].traceBlockInPipe_iretire   = io_enq_req_1_bits_traceBlockInPipe_iretire;
    enqBits[1].traceBlockInPipe_ilastsize = io_enq_req_1_bits_traceBlockInPipe_ilastsize;
    enqBits[1].debug_pc                   = io_enq_req_1_bits_pc;
    enqBits[1].debug_instr                = io_enq_req_1_bits_instr;
    enqBits[1].basicDebug_ldest           = io_enq_req_1_bits_ldest;
    enqBits[1].basicDebug_pdest           = io_enq_req_1_bits_pdest;
    enqBits[1].basicDebug_fpWen           = io_enq_req_1_bits_fpWen;
    enqBits[1].basicDebug_vecWen          = io_enq_req_1_bits_vecWen;
    enqBits[1].basicDebug_v0Wen           = io_enq_req_1_bits_v0Wen;
    enqBits[1].basicDebug_eliminatedMove  = io_enq_req_1_bits_eliminatedMove;
    enqBits[1].basicDebug_isXSTrap        = io_enq_req_1_bits_isXSTrap;
    enqBits[1].debug_fuType               = io_enq_req_1_bits_fuType;
    enqBits[1].fuOpHi                     = io_enq_req_1_bits_fuOpType[8:4];
    enqBits[1].needFlush                  = enqNeedFlush[1];
    enqBits[1].basicDebug_vd              = io_enq_req_1_bits_instr[11:7];

    enqBits[2].wflags                     = io_enq_req_2_bits_wfflags;
    enqBits[2].commitType                 = io_enq_req_2_bits_commitType;
    enqBits[2].ftqIdx_flag                = io_enq_req_2_bits_ftqPtr_flag;
    enqBits[2].ftqIdx_value               = io_enq_req_2_bits_ftqPtr_value;
    enqBits[2].ftqOffset                  = io_enq_req_2_bits_ftqOffset;
    enqBits[2].isRVC                      = io_enq_req_2_bits_preDecodeInfo_isRVC;
    enqBits[2].isVset                     = io_enq_req_2_bits_isVset;
    enqBits[2].instrSize                  = io_enq_req_2_bits_instrSize;
    enqBits[2].rfWen                      = io_enq_req_2_bits_rfWen;
    enqBits[2].fpWen                      = io_enq_req_2_bits_dirtyFs;
    enqBits[2].dirtyVs                    = io_enq_req_2_bits_dirtyVs;
    enqBits[2].traceBlockInPipe_itype     = io_enq_req_2_bits_traceBlockInPipe_itype;
    enqBits[2].traceBlockInPipe_iretire   = io_enq_req_2_bits_traceBlockInPipe_iretire;
    enqBits[2].traceBlockInPipe_ilastsize = io_enq_req_2_bits_traceBlockInPipe_ilastsize;
    enqBits[2].debug_pc                   = io_enq_req_2_bits_pc;
    enqBits[2].debug_instr                = io_enq_req_2_bits_instr;
    enqBits[2].basicDebug_ldest           = io_enq_req_2_bits_ldest;
    enqBits[2].basicDebug_pdest           = io_enq_req_2_bits_pdest;
    enqBits[2].basicDebug_fpWen           = io_enq_req_2_bits_fpWen;
    enqBits[2].basicDebug_vecWen          = io_enq_req_2_bits_vecWen;
    enqBits[2].basicDebug_v0Wen           = io_enq_req_2_bits_v0Wen;
    enqBits[2].basicDebug_eliminatedMove  = io_enq_req_2_bits_eliminatedMove;
    enqBits[2].basicDebug_isXSTrap        = io_enq_req_2_bits_isXSTrap;
    enqBits[2].debug_fuType               = io_enq_req_2_bits_fuType;
    enqBits[2].fuOpHi                     = io_enq_req_2_bits_fuOpType[8:4];
    enqBits[2].needFlush                  = enqNeedFlush[2];
    enqBits[2].basicDebug_vd              = io_enq_req_2_bits_instr[11:7];

    enqBits[3].wflags                     = io_enq_req_3_bits_wfflags;
    enqBits[3].commitType                 = io_enq_req_3_bits_commitType;
    enqBits[3].ftqIdx_flag                = io_enq_req_3_bits_ftqPtr_flag;
    enqBits[3].ftqIdx_value               = io_enq_req_3_bits_ftqPtr_value;
    enqBits[3].ftqOffset                  = io_enq_req_3_bits_ftqOffset;
    enqBits[3].isRVC                      = io_enq_req_3_bits_preDecodeInfo_isRVC;
    enqBits[3].isVset                     = io_enq_req_3_bits_isVset;
    enqBits[3].instrSize                  = io_enq_req_3_bits_instrSize;
    enqBits[3].rfWen                      = io_enq_req_3_bits_rfWen;
    enqBits[3].fpWen                      = io_enq_req_3_bits_dirtyFs;
    enqBits[3].dirtyVs                    = io_enq_req_3_bits_dirtyVs;
    enqBits[3].traceBlockInPipe_itype     = io_enq_req_3_bits_traceBlockInPipe_itype;
    enqBits[3].traceBlockInPipe_iretire   = io_enq_req_3_bits_traceBlockInPipe_iretire;
    enqBits[3].traceBlockInPipe_ilastsize = io_enq_req_3_bits_traceBlockInPipe_ilastsize;
    enqBits[3].debug_pc                   = io_enq_req_3_bits_pc;
    enqBits[3].debug_instr                = io_enq_req_3_bits_instr;
    enqBits[3].basicDebug_ldest           = io_enq_req_3_bits_ldest;
    enqBits[3].basicDebug_pdest           = io_enq_req_3_bits_pdest;
    enqBits[3].basicDebug_fpWen           = io_enq_req_3_bits_fpWen;
    enqBits[3].basicDebug_vecWen          = io_enq_req_3_bits_vecWen;
    enqBits[3].basicDebug_v0Wen           = io_enq_req_3_bits_v0Wen;
    enqBits[3].basicDebug_eliminatedMove  = io_enq_req_3_bits_eliminatedMove;
    enqBits[3].basicDebug_isXSTrap        = io_enq_req_3_bits_isXSTrap;
    enqBits[3].debug_fuType               = io_enq_req_3_bits_fuType;
    enqBits[3].fuOpHi                     = io_enq_req_3_bits_fuOpType[8:4];
    enqBits[3].needFlush                  = enqNeedFlush[3];
    enqBits[3].basicDebug_vd              = io_enq_req_3_bits_instr[11:7];

    enqBits[4].wflags                     = io_enq_req_4_bits_wfflags;
    enqBits[4].commitType                 = io_enq_req_4_bits_commitType;
    enqBits[4].ftqIdx_flag                = io_enq_req_4_bits_ftqPtr_flag;
    enqBits[4].ftqIdx_value               = io_enq_req_4_bits_ftqPtr_value;
    enqBits[4].ftqOffset                  = io_enq_req_4_bits_ftqOffset;
    enqBits[4].isRVC                      = io_enq_req_4_bits_preDecodeInfo_isRVC;
    enqBits[4].isVset                     = io_enq_req_4_bits_isVset;
    enqBits[4].instrSize                  = io_enq_req_4_bits_instrSize;
    enqBits[4].rfWen                      = io_enq_req_4_bits_rfWen;
    enqBits[4].fpWen                      = io_enq_req_4_bits_dirtyFs;
    enqBits[4].dirtyVs                    = io_enq_req_4_bits_dirtyVs;
    enqBits[4].traceBlockInPipe_itype     = io_enq_req_4_bits_traceBlockInPipe_itype;
    enqBits[4].traceBlockInPipe_iretire   = io_enq_req_4_bits_traceBlockInPipe_iretire;
    enqBits[4].traceBlockInPipe_ilastsize = io_enq_req_4_bits_traceBlockInPipe_ilastsize;
    enqBits[4].debug_pc                   = io_enq_req_4_bits_pc;
    enqBits[4].debug_instr                = io_enq_req_4_bits_instr;
    enqBits[4].basicDebug_ldest           = io_enq_req_4_bits_ldest;
    enqBits[4].basicDebug_pdest           = io_enq_req_4_bits_pdest;
    enqBits[4].basicDebug_fpWen           = io_enq_req_4_bits_fpWen;
    enqBits[4].basicDebug_vecWen          = io_enq_req_4_bits_vecWen;
    enqBits[4].basicDebug_v0Wen           = io_enq_req_4_bits_v0Wen;
    enqBits[4].basicDebug_eliminatedMove  = io_enq_req_4_bits_eliminatedMove;
    enqBits[4].basicDebug_isXSTrap        = io_enq_req_4_bits_isXSTrap;
    enqBits[4].debug_fuType               = io_enq_req_4_bits_fuType;
    enqBits[4].fuOpHi                     = io_enq_req_4_bits_fuOpType[8:4];
    enqBits[4].needFlush                  = enqNeedFlush[4];
    enqBits[4].basicDebug_vd              = io_enq_req_4_bits_instr[11:7];

    enqBits[5].wflags                     = io_enq_req_5_bits_wfflags;
    enqBits[5].commitType                 = io_enq_req_5_bits_commitType;
    enqBits[5].ftqIdx_flag                = io_enq_req_5_bits_ftqPtr_flag;
    enqBits[5].ftqIdx_value               = io_enq_req_5_bits_ftqPtr_value;
    enqBits[5].ftqOffset                  = io_enq_req_5_bits_ftqOffset;
    enqBits[5].isRVC                      = io_enq_req_5_bits_preDecodeInfo_isRVC;
    enqBits[5].isVset                     = io_enq_req_5_bits_isVset;
    enqBits[5].instrSize                  = io_enq_req_5_bits_instrSize;
    enqBits[5].rfWen                      = io_enq_req_5_bits_rfWen;
    enqBits[5].fpWen                      = io_enq_req_5_bits_dirtyFs;
    enqBits[5].dirtyVs                    = io_enq_req_5_bits_dirtyVs;
    enqBits[5].traceBlockInPipe_itype     = io_enq_req_5_bits_traceBlockInPipe_itype;
    enqBits[5].traceBlockInPipe_iretire   = io_enq_req_5_bits_traceBlockInPipe_iretire;
    enqBits[5].traceBlockInPipe_ilastsize = io_enq_req_5_bits_traceBlockInPipe_ilastsize;
    enqBits[5].debug_pc                   = io_enq_req_5_bits_pc;
    enqBits[5].debug_instr                = io_enq_req_5_bits_instr;
    enqBits[5].basicDebug_ldest           = io_enq_req_5_bits_ldest;
    enqBits[5].basicDebug_pdest           = io_enq_req_5_bits_pdest;
    enqBits[5].basicDebug_fpWen           = io_enq_req_5_bits_fpWen;
    enqBits[5].basicDebug_vecWen          = io_enq_req_5_bits_vecWen;
    enqBits[5].basicDebug_v0Wen           = io_enq_req_5_bits_v0Wen;
    enqBits[5].basicDebug_eliminatedMove  = io_enq_req_5_bits_eliminatedMove;
    enqBits[5].basicDebug_isXSTrap        = io_enq_req_5_bits_isXSTrap;
    enqBits[5].debug_fuType               = io_enq_req_5_bits_fuType;
    enqBits[5].fuOpHi                     = io_enq_req_5_bits_fuOpType[8:4];
    enqBits[5].needFlush                  = enqNeedFlush[5];
    enqBits[5].basicDebug_vd              = io_enq_req_5_bits_instr[11:7];

  end

  always_comb begin
    for (int i = 0; i < ROB_SIZE; i++) begin
      enqSel[i] = '0;
      for (int j = 0; j < RENAME_W; j++) begin
        enqSel[i].wflags                     |= enqOH[i][j] & enqBits[j].wflags;
        enqSel[i].commitType                 |= {COMMITTYPE_W{enqOH[i][j]}} & enqBits[j].commitType;
        enqSel[i].ftqIdx_flag                |= enqOH[i][j] & enqBits[j].ftqIdx_flag;
        enqSel[i].ftqIdx_value               |= {FTQ_PTR_W{enqOH[i][j]}} & enqBits[j].ftqIdx_value;
        enqSel[i].ftqOffset                  |= {FTQ_OFF_W{enqOH[i][j]}} & enqBits[j].ftqOffset;
        enqSel[i].isRVC                      |= enqOH[i][j] & enqBits[j].isRVC;
        enqSel[i].isVset                     |= enqOH[i][j] & enqBits[j].isVset;
        enqSel[i].instrSize                  |= {INSTRSIZE_W{enqOH[i][j]}} & enqBits[j].instrSize;
        enqSel[i].rfWen                      |= enqOH[i][j] & enqBits[j].rfWen;
        enqSel[i].fpWen                      |= enqOH[i][j] & enqBits[j].fpWen;
        enqSel[i].dirtyVs                    |= enqOH[i][j] & enqBits[j].dirtyVs;
        enqSel[i].traceBlockInPipe_itype     |= {ITYPE_W{enqOH[i][j]}} & enqBits[j].traceBlockInPipe_itype;
        enqSel[i].traceBlockInPipe_iretire   |= {IRETIRE_W{enqOH[i][j]}} & enqBits[j].traceBlockInPipe_iretire;
        enqSel[i].traceBlockInPipe_ilastsize |= enqOH[i][j] & enqBits[j].traceBlockInPipe_ilastsize;
        enqSel[i].debug_pc                   |= {VADDR_W{enqOH[i][j]}} & enqBits[j].debug_pc;
        enqSel[i].debug_instr                |= {32{enqOH[i][j]}} & enqBits[j].debug_instr;
        enqSel[i].basicDebug_ldest           |= {LREG_W{enqOH[i][j]}} & enqBits[j].basicDebug_ldest;
        enqSel[i].basicDebug_pdest           |= {PREG_W{enqOH[i][j]}} & enqBits[j].basicDebug_pdest;
        enqSel[i].basicDebug_fpWen           |= enqOH[i][j] & enqBits[j].basicDebug_fpWen;
        enqSel[i].basicDebug_vecWen          |= enqOH[i][j] & enqBits[j].basicDebug_vecWen;
        enqSel[i].basicDebug_v0Wen           |= enqOH[i][j] & enqBits[j].basicDebug_v0Wen;
        enqSel[i].basicDebug_eliminatedMove  |= enqOH[i][j] & enqBits[j].basicDebug_eliminatedMove;
        enqSel[i].basicDebug_isXSTrap        |= enqOH[i][j] & enqBits[j].basicDebug_isXSTrap;
        enqSel[i].debug_fuType               |= {FUTYPE_W{enqOH[i][j]}} & enqBits[j].debug_fuType;
        enqSel[i].fuOpHi                     |= {5{enqOH[i][j]}} & enqBits[j].fuOpHi;
        enqSel[i].needFlush                  |= enqOH[i][j] & enqBits[j].needFlush;
        enqSel[i].basicDebug_vd              |= {LREG_W{enqOH[i][j]}} & enqBits[j].basicDebug_vd;
      end
      // ★isHls 在 Mux1H **之后**算★（golden 的形状，见 rob_enq_sel_t.fuOpHi 的注释）：
      //   golden 是 `f(Mux1H(fuType), Mux1H(fuOpType[8:4]))`，不是 `Mux1H(f(...))`。
      //   f 非线性（有相等比较和取反），两者只在 enqOH 恰好 one-hot 时才相等；
      //   而 enqOH 非 one-hot 是**可达**的：allocatePtrVec(j) 数的是前面几路的
      //   firstUop，某一路不是 firstUop 时它与下一路共用同一个分配指针。
      //   FM 首跑 robEntries_isHls 整族失配就是这么来的。
      enqSelIsHls[i] = ((enqSel[i].debug_fuType == FUTYPE_W'(1) << FU_LDU)
                        | (enqSel[i].debug_fuType == FUTYPE_W'(1) << FU_STU))
                       & enqSel[i].fuOpHi[0]
                       & ~enqSel[i].fuOpHi[1]
                       & ~(|enqSel[i].fuOpHi[4:3]);
    end
  end
  // ---- (B) 优先链那一族的 payload（vls / interrupt_safe / debug_microOp）----
  logic enqVlsInstr [RENAME_W];
  always_comb begin
    enqVlsInstr[0] = io_enq_req_0_bits_vlsInstr;
    enqVlsInstr[1] = io_enq_req_1_bits_vlsInstr;
    enqVlsInstr[2] = io_enq_req_2_bits_vlsInstr;
    enqVlsInstr[3] = io_enq_req_3_bits_vlsInstr;
    enqVlsInstr[4] = io_enq_req_4_bits_vlsInstr;
    enqVlsInstr[5] = io_enq_req_5_bits_vlsInstr;
  end

  // ---- 每条目的写回聚合 ----
  // 全部按 Mux1H=**按位或**写（golden 的形状），不按 one-hot 优化成优先级。
  logic [UOPNUM_W-1:0] enqWBNumVec    [RENAME_W];
  logic                enqWriteStdVec [RENAME_W];
  logic [4:0]          wbCnt        [ROB_SIZE];   // 本拍这条被写回了几个 uop
  logic                needFlushWb  [ROB_SIZE];
  logic                anyStdWb     [ROB_SIZE];
  logic                anyUopEnq    [ROB_SIZE];
  logic [FFLAGS_W-1:0] fflagsRes    [ROB_SIZE];
  logic                vxsatRes     [ROB_SIZE];
  logic                takenWb      [ROB_SIZE];
  logic [UOPNUM_W-1:0] realDestEnqNum [ROB_SIZE];
  logic [UOPNUM_W-1:0] enqWBNum     [ROB_SIZE];
  logic                enqWriteStd  [ROB_SIZE];
  logic                isFirstEnq   [ROB_SIZE];

  always_comb begin
    for (int i = 0; i < ROB_SIZE; i++) begin
      wbCnt[i]       = 5'h0;
      needFlushWb[i] = 1'b0;
      anyStdWb[i]    = 1'b0;
      anyUopEnq[i]   = 1'b0;
      fflagsRes[i]   = {FFLAGS_W{1'b0}};
      vxsatRes[i]    = 1'b0;
      takenWb[i]     = 1'b0;
      realDestEnqNum[i] = {UOPNUM_W{1'b0}};

      for (int k = 0; k < EXU_N; k++)
        wbCnt[i] |= {5{exuWbValid[k] & (exuWbRobIdx[k] == PTR_W'(i))}} & exuWbNum[k];
      for (int k = 0; k < EXCP_WB_N; k++)
        needFlushWb[i] |= excpWbValid[k] & (excpWbRobIdx[k] == PTR_W'(i))
                          & excpWbNeedFlush[k];
      for (int k = 0; k < STD_N; k++)
        anyStdWb[i] |= stdWbValid[k] & (stdWbRobIdx[k] == PTR_W'(i));
      for (int k = 0; k < FFLAGS_WB_N; k++)
        fflagsRes[i] |= {FFLAGS_W{fflagsWbValid[k] & (fflagsWbRobIdx[k] == PTR_W'(i))
                                  & fflagsWbWflags[k]}} & fflagsWbData[k];
      for (int k = 0; k < VXSAT_WB_N; k++)
        vxsatRes[i] |= vxsatWbValid[k] & (vxsatWbRobIdx[k] == PTR_W'(i)) & vxsatWbData[k];
      for (int k = 0; k < BRH_WB_N; k++)
        takenWb[i] |= brhWbValid[k] & (brhWbRobIdx[k] == PTR_W'(i)) & brhWbTaken[k];

      for (int j = 0; j < RENAME_W; j++) begin
        anyUopEnq[i] = anyUopEnq[i] | uopCanEnq[i][j];
        realDestEnqNum[i] = realDestEnqNum[i]
                          + UOPNUM_W'(enqNeedWriteRf[j] & uopCanEnq[i][j]);
      end

      // ★PriorityMux：第 0 路优先级最高★（与 (B) 的优先链方向相反，别弄反）
      enqWBNum[i]    = {UOPNUM_W{1'b0}};
      enqWriteStd[i] = 1'b0;
      for (int j = RENAME_W - 1; j >= 0; j--)
        if (instCanEnq[i][j]) begin
          enqWBNum[i]    = enqWBNumVec[j];
          enqWriteStd[i] = enqWriteStdVec[j];
        end

      isFirstEnq[i] = ~robEntries_valid[i] & instCanEnqAny[i];
    end
  end

  always_comb begin
    enqWBNumVec[0] = io_enq_req_0_bits_numWB;
    enqWBNumVec[1] = io_enq_req_1_bits_numWB;
    enqWBNumVec[2] = io_enq_req_2_bits_numWB;
    enqWBNumVec[3] = io_enq_req_3_bits_numWB;
    enqWBNumVec[4] = io_enq_req_4_bits_numWB;
    enqWBNumVec[5] = io_enq_req_5_bits_numWB;
    // FuType.isStore(fuType) = fuType[stu]
    enqWriteStdVec[0] = io_enq_req_0_bits_fuType[FU_STU];
    enqWriteStdVec[1] = io_enq_req_1_bits_fuType[FU_STU];
    enqWriteStdVec[2] = io_enq_req_2_bits_fuType[FU_STU];
    enqWriteStdVec[3] = io_enq_req_3_bits_fuType[FU_STU];
    enqWriteStdVec[4] = io_enq_req_4_bits_fuType[FU_STU];
    enqWriteStdVec[5] = io_enq_req_5_bits_fuType[FU_STU];
  end

  // ---- lsq 回来的 mmio 标记：打一拍再写 ----
  // 名字照 golden（REG_3..REG_6 / r_value / r_1..3_value）：这些是 name_lock=free
  // 的散寄存器，只能靠 FM 按名字配 —— 起个好听的名字换不来任何东西，只会丢配对。
  //   REG_3/4/5 = RegNext(io_lsq_loadMmio_0/1/2)   REG_6 = RegNext(io_lsq_storeMmio)
  //   r_value / r_1_value / r_2_value = RegEnable(loadMmioUop_i.robIdx, loadMmio_i)
  //   r_3_value                        = RegEnable(storeMmioUop.robIdx, storeMmio)
  logic [PTR_W-1:0] r_1_value;
  logic [PTR_W-1:0] r_2_value;
  logic [PTR_W-1:0] r_3_value;
  always_ff @(posedge clock) begin
    REG_3 <= io_lsq_loadMmio_0;
    if (io_lsq_loadMmio_0) r_value   <= io_lsq_loadMmioUop_0_robIdx_value;
    REG_4 <= io_lsq_loadMmio_1;
    if (io_lsq_loadMmio_1) r_1_value <= io_lsq_loadMmioUop_1_robIdx_value;
    REG_5 <= io_lsq_loadMmio_2;
    if (io_lsq_loadMmio_2) r_2_value <= io_lsq_loadMmioUop_2_robIdx_value;
    REG_6 <= io_lsq_storeMmio;
    if (io_lsq_storeMmio)  r_3_value <= io_lsq_storeMmioUop_robIdx_value;
  end

  // ---- redirect 的冲刷窗口 ----
  logic entryNeedFlush [ROB_SIZE];
  always_comb begin
    for (int i = 0; i < ROB_SIZE; i++)
      entryNeedFlush[i] = redirectValidReg
        & (((redirectEnd > redirectBegin)
              ? ((PTR_W'(i) > redirectBegin) & (PTR_W'(i) < redirectEnd))
              : ((PTR_W'(i) > redirectBegin) | (PTR_W'(i) < redirectEnd)))
           | redirectAll);
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) redirectAll <= 1'b0;
    else if (io_redirect_valid)
      redirectAll <= io_redirect_bits_level
                   & (io_redirect_bits_robIdx_value == enqPtrVec_0_value)
                   & (io_redirect_bits_robIdx_flag ^ enqPtrVec_0_flag);
  end
  always_ff @(posedge clock) begin
    redirectValidReg <= io_redirect_valid;
    if (io_redirect_valid) begin
      redirectBegin <= io_redirect_bits_level
                     ? PTR_W'(io_redirect_bits_robIdx_value - PTR_W'(1))
                     : io_redirect_bits_robIdx_value;
      redirectEnd   <= enqPtrVec_0_value;
    end
  end

  // ---- 提交清 valid 的条件 ----
  logic commitCond [ROB_SIZE];
  always_comb begin
    for (int i = 0; i < ROB_SIZE; i++) begin
      commitCond[i] = 1'b0;
      for (int k = 0; k < COMMIT_W; k++)
        commitCond[i] = commitCond[i]
          | (commitValidOut[k] & (deqPtrValue[k] == PTR_W'(i)));
      commitCond[i] = commitCond[i] & io_commits_isCommit;
    end
  end

  // ==========================================================================
  // §10 条目存储的时序写入
  // ==========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < ROB_SIZE; i++) robEntries_valid[i] <= 1'b0;
    end else begin
      for (int i = 0; i < ROB_SIZE; i++) begin
        if (commitCond[i])                          robEntries_valid[i] <= 1'b0;
        else if (enqOHAny[i] & ~io_redirect_valid)  robEntries_valid[i] <= 1'b1;
        else if (entryNeedFlush[i])                 robEntries_valid[i] <= 1'b0;
      end
    end
  end

  always_ff @(posedge clock) begin
    for (int i = 0; i < ROB_SIZE; i++) begin
      // (A) connectEnq：Mux1H 选出来的 payload，redirect 那一拍不写
      if (enqOHAny[i] & ~io_redirect_valid) begin
        robEntries_wflags[i]                     <= enqSel[i].wflags;
        robEntries_commitType[i]                 <= enqSel[i].commitType;
        robEntries_ftqIdx_flag[i]                <= enqSel[i].ftqIdx_flag;
        robEntries_ftqIdx_value[i]               <= enqSel[i].ftqIdx_value;
        robEntries_ftqOffset[i]                  <= enqSel[i].ftqOffset;
        robEntries_isRVC[i]                      <= enqSel[i].isRVC;
        robEntries_isVset[i]                     <= enqSel[i].isVset;
        robEntries_isHls[i]                      <= enqSelIsHls[i];
        robEntries_instrSize[i]                  <= enqSel[i].instrSize;
        robEntries_rfWen[i]                      <= enqSel[i].rfWen;
        robEntries_fpWen[i]                      <= enqSel[i].fpWen;
        robEntries_dirtyVs[i]                    <= enqSel[i].dirtyVs;
        robEntries_traceBlockInPipe_iretire[i]   <= enqSel[i].traceBlockInPipe_iretire;
        robEntries_traceBlockInPipe_ilastsize[i] <= enqSel[i].traceBlockInPipe_ilastsize;
        robEntries_debug_pc[i]                   <= enqSel[i].debug_pc;
        robEntries_debug_instr[i]                <= enqSel[i].debug_instr;
        robEntries_basicDebug_ldest[i]           <= enqSel[i].basicDebug_ldest;
        robEntries_basicDebug_pdest[i]           <= enqSel[i].basicDebug_pdest;
        robEntries_basicDebug_vd[i]              <= enqSel[i].basicDebug_vd;
        robEntries_basicDebug_fpWen[i]           <= enqSel[i].basicDebug_fpWen;
        robEntries_basicDebug_vecWen[i]          <= enqSel[i].basicDebug_vecWen;
        robEntries_basicDebug_v0Wen[i]           <= enqSel[i].basicDebug_v0Wen;
        robEntries_basicDebug_eliminatedMove[i]  <= enqSel[i].basicDebug_eliminatedMove;
        robEntries_basicDebug_isXSTrap[i]        <= enqSel[i].basicDebug_isXSTrap;
        robEntries_debug_fuType[i]               <= enqSel[i].debug_fuType;
      end

      // trace 的 itype：入队先写 Branch(=NonTaken)，写回发现 taken 再改写成 Taken。
      // ★改写那一条在 Scala 里更靠后，优先级更高★。
      if (robEntries_valid[i]
          & (robEntries_traceBlockInPipe_itype[i] == IT_BRANCH) & takenWb[i])
        robEntries_traceBlockInPipe_itype[i] <= IT_TAKEN;
      else if (enqOHAny[i] & ~io_redirect_valid)
        robEntries_traceBlockInPipe_itype[i] <= enqSel[i].traceBlockInPipe_itype;

      // needFlush：同理，写回聚合那一条优先级更高
      if (robEntries_valid[i])
        robEntries_needFlush[i] <= robEntries_needFlush[i] | needFlushWb[i];
      else if (enqOHAny[i] & ~io_redirect_valid)
        robEntries_needFlush[i] <= enqSel[i].needFlush;

      // (B) 优先链：第 5 路最后写 => 第 5 路优先级最高
      for (int j = 0; j < RENAME_W; j++)
        if (enqOH[i][j]) begin
          robEntries_vls[i]            <= enqVlsInstr[j];
          robEntries_mmio[i]           <= 1'b0;
          robEntries_interrupt_safe[i] <= enqAllowIntr[j];
        end
      // lsq 回来的 mmio 比入队清零更靠后，优先级更高
      if (REG_3 & (r_value   == PTR_W'(i))) robEntries_mmio[i] <= 1'b1;
      if (REG_4 & (r_1_value == PTR_W'(i))) robEntries_mmio[i] <= 1'b1;
      if (REG_5 & (r_2_value == PTR_W'(i))) robEntries_mmio[i] <= 1'b1;
      if (REG_6 & (r_3_value == PTR_W'(i))) robEntries_mmio[i] <= 1'b1;

      // realDestSize：首次入队置数，之后同一条指令的后续 uop 累加
      if (isFirstEnq[i])
        robEntries_realDestSize[i] <= realDestEnqNum[i];
      else if (robEntries_valid[i] & anyUopEnq[i])
        robEntries_realDestSize[i] <= robEntries_realDestSize[i] + realDestEnqNum[i];

      // uopNum / stdWritebacked
      if (robEntries_valid[i] & (robEntries_needFlush[i] | needFlushWb[i])) begin
        robEntries_uopNum[i]         <= robEntries_uopNum[i] - UOPNUM_W'(wbCnt[i]);
        robEntries_stdWritebacked[i] <= 1'b1;
      end else if (~robEntries_valid[i] & instCanEnqAny[i]) begin
        robEntries_uopNum[i]         <= enqWBNum[i];
        robEntries_stdWritebacked[i] <= ~enqWriteStd[i];
      end else if (robEntries_valid[i]) begin
        robEntries_uopNum[i] <= robEntries_uopNum[i] - UOPNUM_W'(wbCnt[i]);
        if (anyStdWb[i]) robEntries_stdWritebacked[i] <= 1'b1;
      end

      // fflags / vxsat：入队清零，之后按位或累积
      if (isFirstEnq[i])           robEntries_fflags[i] <= {FFLAGS_W{1'b0}};
      else if (|fflagsRes[i])      robEntries_fflags[i] <= robEntries_fflags[i] | fflagsRes[i];
      if (isFirstEnq[i])           robEntries_vxsat[i]  <= 1'b0;
      else if (vxsatRes[i])        robEntries_vxsat[i]  <= robEntries_vxsat[i] | vxsatRes[i];
    end
  end


  // ==========================================================================
  // §11 提交读口：8 bank x 20 行的 one-hot 读
  // ==========================================================================
  // robBanks(b) 装 robidx%8==b 的 20 个条目；八个 bank **共用**一个 one-hot 行地址
  // robBanksRaddrThisLine。"下一行"不另设地址，而是把同一个 one-hot 读到
  // **移位过的 bank**（第 r 行取第 (r+1)%20 个条目）——省掉第二套地址。

  localparam int BANK_ROWS = BANK_DEPTH;   // 20

  rob_entry_t bankRdThisLine [BANK_N];
  rob_entry_t bankRdNextLine [BANK_N];

  // 把一条条目装进组合用的结构体（存储本身仍是每字段一个数组）。
  // ★原先这里是 `function automatic rob_entry_t packEntry(input int idx)`，
  //   已改成预打包数组 + always_comb。不是风格问题，是**Formality 直接拒绝 elaborate**★：
  //   函数体读的全是模块级变量（非 local），FM 对每一处报 FMR_VLOG-091
  //   "Using non-local variable ... in task/function ... may cause a simulation and
  //   synthesis mismatch"，本模块两个函数合计 81 条；link 阶段汇总成
  //     Error: Unsuppressed RTL interpretation message(s): FMR_VLOG-091 FMR_ELAB-117 (FM-262)
  //     Error: Failed to set top design to 'i:/WORK/Rob' (FM-156)
  //   —— set_top impl 失败，**整个证明一个比较点都跑不到**。
  //   ★VCS 全程零 error 零 warning 也照样过不了 FM★：这两个工具的可接受集合不一样，
  //   "VCS elaborate 干净" 不蕴含 "FM elaborate 干净"。
  //   （压制消息不是选项：那几条消息说的正是"结果可能与仿真不一致"。）
  rob_entry_t robEntryPacked [ROB_SIZE];
  always_comb begin
    for (int idx = 0; idx < ROB_SIZE; idx++) begin
        robEntryPacked[idx].valid                      = robEntries_valid[idx];
        robEntryPacked[idx].vls                        = robEntries_vls[idx];
        robEntryPacked[idx].interrupt_safe             = robEntries_interrupt_safe[idx];
        robEntryPacked[idx].fpWen                      = robEntries_fpWen[idx];
        robEntryPacked[idx].rfWen                      = robEntries_rfWen[idx];
        robEntryPacked[idx].wflags                     = robEntries_wflags[idx];
        robEntryPacked[idx].dirtyVs                    = robEntries_dirtyVs[idx];
        robEntryPacked[idx].commitType                 = robEntries_commitType[idx];
        robEntryPacked[idx].ftqIdx_flag                = robEntries_ftqIdx_flag[idx];
        robEntryPacked[idx].ftqIdx_value               = robEntries_ftqIdx_value[idx];
        robEntryPacked[idx].ftqOffset                  = robEntries_ftqOffset[idx];
        robEntryPacked[idx].isRVC                      = robEntries_isRVC[idx];
        robEntryPacked[idx].isVset                     = robEntries_isVset[idx];
        robEntryPacked[idx].isHls                      = robEntries_isHls[idx];
        robEntryPacked[idx].instrSize                  = robEntries_instrSize[idx];
        robEntryPacked[idx].traceBlockInPipe_itype     = robEntries_traceBlockInPipe_itype[idx];
        robEntryPacked[idx].traceBlockInPipe_iretire   = robEntries_traceBlockInPipe_iretire[idx];
        robEntryPacked[idx].traceBlockInPipe_ilastsize = robEntries_traceBlockInPipe_ilastsize[idx];
        robEntryPacked[idx].fflags                     = robEntries_fflags[idx];
        robEntryPacked[idx].mmio                       = robEntries_mmio[idx];
        robEntryPacked[idx].stdWritebacked             = robEntries_stdWritebacked[idx];
        robEntryPacked[idx].vxsat                      = robEntries_vxsat[idx];
        robEntryPacked[idx].realDestSize               = robEntries_realDestSize[idx];
        robEntryPacked[idx].uopNum                     = robEntries_uopNum[idx];
        robEntryPacked[idx].needFlush                  = robEntries_needFlush[idx];
        robEntryPacked[idx].debug_pc                   = robEntries_debug_pc[idx];
        robEntryPacked[idx].debug_instr                = robEntries_debug_instr[idx];
        robEntryPacked[idx].basicDebug_ldest           = robEntries_basicDebug_ldest[idx];
        robEntryPacked[idx].basicDebug_pdest           = robEntries_basicDebug_pdest[idx];
        robEntryPacked[idx].basicDebug_vd              = robEntries_basicDebug_vd[idx];
        robEntryPacked[idx].basicDebug_fpWen           = robEntries_basicDebug_fpWen[idx];
        robEntryPacked[idx].basicDebug_vecWen          = robEntries_basicDebug_vecWen[idx];
        robEntryPacked[idx].basicDebug_v0Wen           = robEntries_basicDebug_v0Wen[idx];
        robEntryPacked[idx].basicDebug_eliminatedMove  = robEntries_basicDebug_eliminatedMove[idx];
        robEntryPacked[idx].basicDebug_isXSTrap        = robEntries_basicDebug_isXSTrap[idx];
        robEntryPacked[idx].debug_fuType               = robEntries_debug_fuType[idx];
    end
  end

  always_comb begin
    for (int b = 0; b < BANK_N; b++) begin
      bankRdThisLine[b] = '0;
      bankRdNextLine[b] = '0;
      // ★Mux1H：按位或★（非 one-hot 时与优先级选择不等价，golden 是或）
      for (int r = 0; r < BANK_ROWS; r++) begin
        if (robBanksRaddrThisLine[r]) begin
          bankRdThisLine[b] = bankRdThisLine[b] | robEntryPacked[r * BANK_N + b];
          bankRdNextLine[b] = bankRdNextLine[b]
                            | robEntryPacked[((r + 1) % BANK_ROWS) * BANK_N + b];
        end
      end
    end
  end

  // ---- 读地址的下一拍 ----
  logic [BANK_ROWS-1:0] robBanksRaddrNextLine;
  logic [PTR_W-1:BANK_ADDR_W] highDeqPtrThisLine;
  logic [PTR_W-1:BANK_ADDR_W] highDeqPtrNextLine;
  logic                 changeBankAddrToDeqPtr;
  logic                 allCommitted;
  logic [PTR_W-1:0]     walkPtrHeadValue;

  assign highDeqPtrThisLine = deqPtrVec_0_value[PTR_W-1:BANK_ADDR_W];
  assign highDeqPtrNextLine =
      (highDeqPtrThisLine == (PTR_W-BANK_ADDR_W)'(BANK_ROWS - 1))
        ? (PTR_W-BANK_ADDR_W)'(0)
        : (PTR_W-BANK_ADDR_W)'(highDeqPtrThisLine + 1'b1);

  assign walkPtrHeadValue = walkPtrVec_next_value[0];
  // (walkPtrVec.head + CommitWidth) > lastWalkPtr
  assign changeBankAddrToDeqPtr =
      ptrGt(ptrAddFlag(walkPtrVec_flag[0], walkPtrVec_value[0], (PTR_W+1)'(COMMIT_W)),
            ptrAddValue(walkPtrVec_value[0], (PTR_W+1)'(COMMIT_W)),
            lastWalkPtr_flag, lastWalkPtr_value);

  always_comb begin
    if (io_redirect_valid)
      robBanksRaddrNextLine = BANK_ROWS'(1) << walkPtrHeadValue[PTR_W-1:BANK_ADDR_W];
    else if (allCommitted | (io_commits_isWalk & ~changeBankAddrToDeqPtr))
      robBanksRaddrNextLine = robBanksRaddrThisLine[BANK_ROWS-1]
                            ? BANK_ROWS'(1) : (robBanksRaddrThisLine << 1);
    else if (io_commits_isWalk & changeBankAddrToDeqPtr)
      robBanksRaddrNextLine = BANK_ROWS'(1) << highDeqPtrThisLine;
    else
      robBanksRaddrNextLine = robBanksRaddrThisLine;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) robBanksRaddrThisLine <= BANK_ROWS'(1);
    else       robBanksRaddrThisLine <= robBanksRaddrNextLine;
  end

  // ---- 读出来的 16 个槽（本行 8 + 下一行 8）要就地打补丁 ----
  // 条目存储是时序的，而本拍的入队/写回还没写进去；提交要看的是"打完补丁的值"。
  // 所以这 16 个槽各自重做一遍 §9/§10 里那套聚合，只是匹配的下标换成槽自己的 robidx。
  localparam int SLOT_N = 2 * COMMIT_W;    // 16

  logic [PTR_W-1:0] slotRobIdx [SLOT_N];
  rob_entry_t       slotRd     [SLOT_N];
  rob_entry_t       needUpdate [SLOT_N];

  always_comb begin
    for (int b = 0; b < BANK_N; b++) begin
      slotRobIdx[b]           = {highDeqPtrThisLine, BANK_ADDR_W'(b)};
      slotRobIdx[BANK_N + b]  = {highDeqPtrNextLine, BANK_ADDR_W'(b)};
      slotRd[b]               = bankRdThisLine[b];
      slotRd[BANK_N + b]      = bankRdNextLine[b];
    end
  end

  logic [4:0]          slotWbCnt       [SLOT_N];
  logic                slotNeedFlushWb [SLOT_N];
  logic                slotAnyStdWb    [SLOT_N];
  logic [FFLAGS_W-1:0] slotFflagsRes   [SLOT_N];
  logic                slotVxsatRes    [SLOT_N];
  logic                slotTakenWb     [SLOT_N];
  logic [UOPNUM_W-1:0] slotRealDestEnq [SLOT_N];
  logic [UOPNUM_W-1:0] slotEnqWBNum    [SLOT_N];
  logic                slotEnqWriteStd [SLOT_N];
  logic                slotInstCanEnq  [SLOT_N];

  always_comb begin
    for (int s = 0; s < SLOT_N; s++) begin
      slotWbCnt[s]       = 5'h0;
      slotNeedFlushWb[s] = 1'b0;
      slotAnyStdWb[s]    = 1'b0;
      slotFflagsRes[s]   = {FFLAGS_W{1'b0}};
      slotVxsatRes[s]    = 1'b0;
      slotTakenWb[s]     = 1'b0;
      slotRealDestEnq[s] = {UOPNUM_W{1'b0}};
      slotInstCanEnq[s]  = 1'b0;

      for (int k = 0; k < EXU_N; k++)
        slotWbCnt[s] |= {5{exuWbValid[k] & (exuWbRobIdx[k] == slotRobIdx[s])}}
                        & exuWbNum[k];
      for (int k = 0; k < EXCP_WB_N; k++)
        slotNeedFlushWb[s] |= excpWbValid[k] & (excpWbRobIdx[k] == slotRobIdx[s])
                              & excpWbNeedFlush[k];
      for (int k = 0; k < STD_N; k++)
        slotAnyStdWb[s] |= stdWbValid[k] & (stdWbRobIdx[k] == slotRobIdx[s]);
      for (int k = 0; k < FFLAGS_WB_N; k++)
        slotFflagsRes[s] |= {FFLAGS_W{fflagsWbValid[k]
                                      & (fflagsWbRobIdx[k] == slotRobIdx[s])
                                      & fflagsWbWflags[k]}} & fflagsWbData[k];
      for (int k = 0; k < VXSAT_WB_N; k++)
        slotVxsatRes[s] |= vxsatWbValid[k] & (vxsatWbRobIdx[k] == slotRobIdx[s])
                           & vxsatWbData[k];
      for (int k = 0; k < BRH_WB_N; k++)
        slotTakenWb[s] |= brhWbValid[k] & (brhWbRobIdx[k] == slotRobIdx[s])
                          & brhWbTaken[k];

      for (int j = 0; j < RENAME_W; j++) begin
        slotRealDestEnq[s] = slotRealDestEnq[s]
          + UOPNUM_W'(enqNeedWriteRf[j] & canEnqueueEG[j]
                      & (enqRobIdx[j] == slotRobIdx[s]));
        slotInstCanEnq[s] = slotInstCanEnq[s]
          | (canEnqueue[j] & (enqRobIdx[j] == slotRobIdx[s]));
      end

      // PriorityMux：第 0 路优先
      slotEnqWBNum[s]    = {UOPNUM_W{1'b0}};
      slotEnqWriteStd[s] = 1'b0;
      for (int j = RENAME_W - 1; j >= 0; j--)
        if (canEnqueue[j] & (enqRobIdx[j] == slotRobIdx[s])) begin
          slotEnqWBNum[s]    = enqWBNumVec[j];
          slotEnqWriteStd[s] = enqWriteStdVec[j];
        end
    end
  end

  always_comb begin
    for (int s = 0; s < SLOT_N; s++) begin
      needUpdate[s] = slotRd[s];      // 默认就是读出来的原值

      if (~slotRd[s].valid & slotInstCanEnq[s])
        needUpdate[s].realDestSize = slotRealDestEnq[s];
      else if (slotRd[s].valid & slotInstCanEnq[s])
        needUpdate[s].realDestSize = slotRd[s].realDestSize + slotRealDestEnq[s];

      if (slotRd[s].valid)
        needUpdate[s].needFlush = slotRd[s].needFlush | slotNeedFlushWb[s];

      if (slotRd[s].valid & (slotRd[s].needFlush | slotNeedFlushWb[s])) begin
        needUpdate[s].uopNum         = slotRd[s].uopNum - UOPNUM_W'(slotWbCnt[s]);
        needUpdate[s].stdWritebacked = 1'b1;
      end else if (~slotRd[s].valid & slotInstCanEnq[s]) begin
        needUpdate[s].uopNum         = slotEnqWBNum[s];
        needUpdate[s].stdWritebacked = ~slotEnqWriteStd[s];
      end else if (slotRd[s].valid) begin
        needUpdate[s].uopNum = slotRd[s].uopNum - UOPNUM_W'(slotWbCnt[s]);
        if (slotAnyStdWb[s]) needUpdate[s].stdWritebacked = 1'b1;
      end

      needUpdate[s].fflags = (~slotRd[s].valid & slotInstCanEnq[s])
          ? {FFLAGS_W{1'b0}} : (slotRd[s].fflags | slotFflagsRes[s]);
      needUpdate[s].vxsat  = (~slotRd[s].valid & slotInstCanEnq[s])
          ? 1'b0 : (slotRd[s].vxsat | slotVxsatRes[s]);

      if (slotRd[s].valid & (slotRd[s].traceBlockInPipe_itype == IT_BRANCH)
          & slotTakenWb[s])
        needUpdate[s].traceBlockInPipe_itype = IT_TAKEN;
    end
  end

  // ==========================================================================
  // §12 robDeqGroup：提交读口的寄存器级
  // ==========================================================================
  // connectCommitEntry 的逐字段拷贝。★debug_otherPdest 不在这份拷贝里★——
  // RobEntryBundle 根本没有这个成员，没得可拷；见文件头「已知残留」。
  // ★源选择必须在 always_ff **外面**算★：原先这里写的是
  //     `automatic int s = allCommitted ? (BANK_N + i) : i;`
  //   —— 一个声明在 always_ff 里的 32 位 automatic int。FM 把它按循环展开
  //   推成了 8 个 32 位**寄存器**（i:/WORK/Rob/u_core/s_reg3..s_reg10，共 256 位），
  //   写了却没人读 ⇒ 256 个 impl 侧 unread 比较点，strict 口径直接判 PARTIAL。
  //   golden 里没有这种东西（Chisel 的 Mux 是纯组合）。挪到 always_comb 即消失。
  //   两个下标 (BANK_N+i) 和 i 展开后都是常量，不构成信号下标（FMR_ELAB-147）。
  rob_entry_t deqGroupSrc [COMMIT_W];
  always_comb begin
    for (int i = 0; i < COMMIT_W; i++)
      // 默认取本行，allCommitted 时直接取下一行（提前一拍把下一行搬进来）
      deqGroupSrc[i] = allCommitted ? needUpdate[BANK_N + i] : needUpdate[i];
  end

  always_ff @(posedge clock) begin
    for (int i = 0; i < COMMIT_W; i++) begin
      robDeqGroup_walk_v[i]                      <= deqGroupSrc[i].valid;
      robDeqGroup_commit_v[i]                    <= deqGroupSrc[i].valid;
      robDeqGroup_commit_w[i]                    <= (deqGroupSrc[i].uopNum == {UOPNUM_W{1'b0}})
                                                  & deqGroupSrc[i].stdWritebacked;
      robDeqGroup_realDestSize[i]                <= deqGroupSrc[i].realDestSize;
      robDeqGroup_interrupt_safe[i]              <= deqGroupSrc[i].interrupt_safe;
      robDeqGroup_rfWen[i]                       <= deqGroupSrc[i].rfWen;
      robDeqGroup_fpWen[i]                       <= deqGroupSrc[i].fpWen;
      robDeqGroup_fflags[i]                      <= deqGroupSrc[i].fflags;
      robDeqGroup_wflags[i]                      <= deqGroupSrc[i].wflags;
      robDeqGroup_vxsat[i]                       <= deqGroupSrc[i].vxsat;
      robDeqGroup_isRVC[i]                       <= deqGroupSrc[i].isRVC;
      robDeqGroup_isVset[i]                      <= deqGroupSrc[i].isVset;
      robDeqGroup_isHls[i]                       <= deqGroupSrc[i].isHls;
      robDeqGroup_isVls[i]                       <= deqGroupSrc[i].vls;
      robDeqGroup_vls[i]                         <= deqGroupSrc[i].vls;
      robDeqGroup_mmio[i]                        <= deqGroupSrc[i].mmio;
      robDeqGroup_ftqIdx_flag[i]                 <= deqGroupSrc[i].ftqIdx_flag;
      robDeqGroup_ftqIdx_value[i]                <= deqGroupSrc[i].ftqIdx_value;
      robDeqGroup_ftqOffset[i]                   <= deqGroupSrc[i].ftqOffset;
      robDeqGroup_commitType[i]                  <= deqGroupSrc[i].commitType;
      robDeqGroup_instrSize[i]                   <= deqGroupSrc[i].instrSize;
      robDeqGroup_dirtyFs[i]                     <= deqGroupSrc[i].fpWen | deqGroupSrc[i].wflags;
      robDeqGroup_dirtyVs[i]                     <= deqGroupSrc[i].dirtyVs;
      robDeqGroup_needFlush[i]                   <= deqGroupSrc[i].needFlush;
      robDeqGroup_traceBlockInPipe_itype[i]      <= deqGroupSrc[i].traceBlockInPipe_itype;
      robDeqGroup_traceBlockInPipe_iretire[i]    <= deqGroupSrc[i].traceBlockInPipe_iretire;
      robDeqGroup_traceBlockInPipe_ilastsize[i]  <= deqGroupSrc[i].traceBlockInPipe_ilastsize;
      robDeqGroup_debug_pc[i]                    <= deqGroupSrc[i].debug_pc;
      robDeqGroup_debug_instr[i]                 <= deqGroupSrc[i].debug_instr;
      robDeqGroup_basicDebug_ldest[i]            <= deqGroupSrc[i].basicDebug_ldest;
      robDeqGroup_basicDebug_pdest[i]            <= deqGroupSrc[i].basicDebug_pdest;
      robDeqGroup_basicDebug_vd[i]               <= deqGroupSrc[i].basicDebug_vd;
      robDeqGroup_basicDebug_fpWen[i]            <= deqGroupSrc[i].basicDebug_fpWen;
      robDeqGroup_basicDebug_vecWen[i]           <= deqGroupSrc[i].basicDebug_vecWen;
      robDeqGroup_basicDebug_v0Wen[i]            <= deqGroupSrc[i].basicDebug_v0Wen;
      robDeqGroup_basicDebug_eliminatedMove[i]   <= deqGroupSrc[i].basicDebug_eliminatedMove;
      robDeqGroup_basicDebug_isXSTrap[i]         <= deqGroupSrc[i].basicDebug_isXSTrap;
      robDeqGroup_debug_fuType[i]                <= deqGroupSrc[i].debug_fuType;
    end
  end


  // ==========================================================================
  // §13 队头读口（rawInfo / commitInfo / walkInfo）
  // ==========================================================================
  // 三个名字在 Scala 里是**同一个表达式**（robDeqGroup 按 bank 低位选），
  // golden 也生成三套同值的线。这里保留三个名字，因为读代码时它们的角色不同：
  //   rawInfo   —— 未修正的原值（ftqOffset 的修正就是拿它算的）
  //   commitInfo—— 送给 io_commits_info 的值（只有 ftqOffset 与 rawInfo 不同）
  //   walkInfo  —— 走回时按 walkPtr 选的那一份
  logic [BANK_ADDR_W-1:0] deqBankIdx [COMMIT_W];
  logic [BANK_ADDR_W-1:0] walkBankIdx[COMMIT_W];

  always_comb begin
    deqPtrValue[0] = deqPtrVec_0_value; deqPtrFlag[0] = deqPtrVec_0_flag;
    deqPtrValue[1] = deqPtrVec_1_value; deqPtrFlag[1] = deqPtrVec_1_flag;
    deqPtrValue[2] = deqPtrVec_2_value; deqPtrFlag[2] = deqPtrVec_2_flag;
    deqPtrValue[3] = deqPtrVec_3_value; deqPtrFlag[3] = deqPtrVec_3_flag;
    deqPtrValue[4] = deqPtrVec_4_value; deqPtrFlag[4] = deqPtrVec_4_flag;
    deqPtrValue[5] = deqPtrVec_5_value; deqPtrFlag[5] = deqPtrVec_5_flag;
    deqPtrValue[6] = deqPtrVec_6_value; deqPtrFlag[6] = deqPtrVec_6_flag;
    deqPtrValue[7] = deqPtrVec_7_value; deqPtrFlag[7] = deqPtrVec_7_flag;
    for (int i = 0; i < COMMIT_W; i++) begin
      deqBankIdx[i]  = deqPtrValue[i][BANK_ADDR_W-1:0];
      walkBankIdx[i] = walkPtrVec_value[i][BANK_ADDR_W-1:0];
    end
  end

  rob_commit_t rawInfo   [COMMIT_W];
  rob_commit_t commitInfo[COMMIT_W];
  rob_commit_t walkInfo  [COMMIT_W];

  // 与 packEntry 同一处理：原先是 `function automatic rob_commit_t packDeqGroup(input int b)`，
  // 改成预打包数组 + always_comb。除了 FMR_VLOG-091（非 local 变量）之外，
  // 这个函数还额外触发 7 条 **FMR_ELAB-117**
  //   "variable 'robDeqGroup_debug_otherPdest_N' read before write"
  // —— 正是那 56 个按裁定留空、两侧都不驱动的寄存器：在函数里读一个从不被写的
  // 模块级变量，FM 视为 read-before-write。这 7 条与 91 那批一起进了 FM-262 的
  // 汇总错误，是 set_top impl 失败的另一半原因。
  // ★留空的裁定不变★（不驱动、不 dont_verify、不黑盒），改的只是"从哪里读它"。
  rob_commit_t deqGroupPacked [BANK_N];
  always_comb begin
    for (int b = 0; b < BANK_N; b++) begin
        deqGroupPacked[b].walk_v                     = robDeqGroup_walk_v[b];
        deqGroupPacked[b].commit_v                   = robDeqGroup_commit_v[b];
        deqGroupPacked[b].commit_w                   = robDeqGroup_commit_w[b];
        deqGroupPacked[b].realDestSize               = robDeqGroup_realDestSize[b];
        deqGroupPacked[b].interrupt_safe             = robDeqGroup_interrupt_safe[b];
        deqGroupPacked[b].wflags                     = robDeqGroup_wflags[b];
        deqGroupPacked[b].fflags                     = robDeqGroup_fflags[b];
        deqGroupPacked[b].vxsat                      = robDeqGroup_vxsat[b];
        deqGroupPacked[b].isRVC                      = robDeqGroup_isRVC[b];
        deqGroupPacked[b].isVset                     = robDeqGroup_isVset[b];
        deqGroupPacked[b].isHls                      = robDeqGroup_isHls[b];
        deqGroupPacked[b].isVls                      = robDeqGroup_isVls[b];
        deqGroupPacked[b].vls                        = robDeqGroup_vls[b];
        deqGroupPacked[b].mmio                       = robDeqGroup_mmio[b];
        deqGroupPacked[b].commitType                 = robDeqGroup_commitType[b];
        deqGroupPacked[b].ftqIdx_flag                = robDeqGroup_ftqIdx_flag[b];
        deqGroupPacked[b].ftqIdx_value               = robDeqGroup_ftqIdx_value[b];
        deqGroupPacked[b].ftqOffset                  = robDeqGroup_ftqOffset[b];
        deqGroupPacked[b].instrSize                  = robDeqGroup_instrSize[b];
        deqGroupPacked[b].fpWen                      = robDeqGroup_fpWen[b];
        deqGroupPacked[b].rfWen                      = robDeqGroup_rfWen[b];
        deqGroupPacked[b].needFlush                  = robDeqGroup_needFlush[b];
        deqGroupPacked[b].traceBlockInPipe_itype     = robDeqGroup_traceBlockInPipe_itype[b];
        deqGroupPacked[b].traceBlockInPipe_iretire   = robDeqGroup_traceBlockInPipe_iretire[b];
        deqGroupPacked[b].traceBlockInPipe_ilastsize = robDeqGroup_traceBlockInPipe_ilastsize[b];
        deqGroupPacked[b].debug_pc                   = robDeqGroup_debug_pc[b];
        deqGroupPacked[b].debug_instr                = robDeqGroup_debug_instr[b];
        deqGroupPacked[b].basicDebug_ldest           = robDeqGroup_basicDebug_ldest[b];
        deqGroupPacked[b].basicDebug_pdest           = robDeqGroup_basicDebug_pdest[b];
        deqGroupPacked[b].basicDebug_vd              = robDeqGroup_basicDebug_vd[b];
        deqGroupPacked[b].basicDebug_fpWen           = robDeqGroup_basicDebug_fpWen[b];
        deqGroupPacked[b].basicDebug_vecWen          = robDeqGroup_basicDebug_vecWen[b];
        deqGroupPacked[b].basicDebug_v0Wen           = robDeqGroup_basicDebug_v0Wen[b];
        deqGroupPacked[b].basicDebug_eliminatedMove  = robDeqGroup_basicDebug_eliminatedMove[b];
        deqGroupPacked[b].basicDebug_isXSTrap        = robDeqGroup_basicDebug_isXSTrap[b];
        deqGroupPacked[b].debug_fuType               = robDeqGroup_debug_fuType[b];
        deqGroupPacked[b].dirtyFs                    = robDeqGroup_dirtyFs[b];
        deqGroupPacked[b].dirtyVs                    = robDeqGroup_dirtyVs[b];
        // ★这 7 个是全核唯一不驱动的字段★（见文件头「已知残留」）：
        //   RobEntryBundle 没有这个成员，connectCommitEntry 没得可拷；
        //   golden 里这 56 个寄存器同样只在 RANDOMIZE_REG_INIT 里被写。
        //   ★仍然照 golden 的结构从寄存器上读出来送到端口★ —— 这样两侧形状一致，
        //   残留是"两侧各 56 个从不写的寄存器"，而不是"impl 少驱动 56 个输出"。
        deqGroupPacked[b].debug_otherPdest_0         = robDeqGroup_debug_otherPdest_0[b];
        deqGroupPacked[b].debug_otherPdest_1         = robDeqGroup_debug_otherPdest_1[b];
        deqGroupPacked[b].debug_otherPdest_2         = robDeqGroup_debug_otherPdest_2[b];
        deqGroupPacked[b].debug_otherPdest_3         = robDeqGroup_debug_otherPdest_3[b];
        deqGroupPacked[b].debug_otherPdest_4         = robDeqGroup_debug_otherPdest_4[b];
        deqGroupPacked[b].debug_otherPdest_5         = robDeqGroup_debug_otherPdest_5[b];
        deqGroupPacked[b].debug_otherPdest_6         = robDeqGroup_debug_otherPdest_6[b];
    end
  end

  always_comb begin
    for (int i = 0; i < COMMIT_W; i++) begin
      rawInfo[i]  = deqGroupPacked[0];
      walkInfo[i] = deqGroupPacked[0];
      // 下标只有 3 位、深度正好 8（2^3=8，不越界），但仍按本文件的通例
      // 用循环+比较，不用信号直接索引。
      for (int b = 0; b < BANK_N; b++) begin
        if (deqBankIdx[i]  == BANK_ADDR_W'(b)) rawInfo[i]  = deqGroupPacked[b];
        if (walkBankIdx[i] == BANK_ADDR_W'(b)) walkInfo[i] = deqGroupPacked[b];
      end
      // commitInfo 与 rawInfo 只差一个 ftqOffset：
      // 多条指令被压缩进同一条 RobEntry 时，条目里存的 ftqIdx/ftqOffset 属于
      // **被压缩的第一条**；提交要告诉前端的是**最后一条**的 offset。
      commitInfo[i] = rawInfo[i];
      commitInfo[i].ftqOffset = rawInfo[i].commitType[2]   // CommitType.isFused
          ? rawInfo[i].ftqOffset
          : FTQ_OFF_W'(FTQ_OFF_W'(rawInfo[i].traceBlockInPipe_iretire
                                  - {2'h0, 2'h1 << rawInfo[i].traceBlockInPipe_ilastsize})
                       + rawInfo[i].ftqOffset);
    end
  end

  assign rawInfo_0_interrupt_safe = rawInfo[0].interrupt_safe;

  // ==========================================================================
  // §14 队头的异常/中断/冲刷判定
  // ==========================================================================
  logic deqPtrEntryValid, deqNeedFlush, deqHitExceptionGenState;
  logic deqNeedFlushAndHitExceptionGenState, exceptionGenStateIsException;
  logic deqHasException, deqHasFlushPipe, deqHasReplayInst;
  logic deqIsVlsException, deqIsVlsFlushPipe, deqCanException, deqCanFlushPipe;
  logic intrEnable, isFlushPipe, isVsetFlushPipe, exceptionHappen;
  logic handleVlsExcp, blockCommitInt, misPredBlock, deqFlushBlock;
  logic deqHitRedirectReg, deqHasCommitted, criticalErrorState;
  logic [EXCP_N-1:0] excpVec;

  always_comb begin
    excpVec = {exceptionGen_io_state_bits_exceptionVec_23,
               exceptionGen_io_state_bits_exceptionVec_22,
               exceptionGen_io_state_bits_exceptionVec_21,
               exceptionGen_io_state_bits_exceptionVec_20,
               exceptionGen_io_state_bits_exceptionVec_19,
               exceptionGen_io_state_bits_exceptionVec_18,
               exceptionGen_io_state_bits_exceptionVec_17,
               exceptionGen_io_state_bits_exceptionVec_16,
               exceptionGen_io_state_bits_exceptionVec_15,
               exceptionGen_io_state_bits_exceptionVec_14,
               exceptionGen_io_state_bits_exceptionVec_13,
               exceptionGen_io_state_bits_exceptionVec_12,
               exceptionGen_io_state_bits_exceptionVec_11,
               exceptionGen_io_state_bits_exceptionVec_10,
               exceptionGen_io_state_bits_exceptionVec_9,
               exceptionGen_io_state_bits_exceptionVec_8,
               exceptionGen_io_state_bits_exceptionVec_7,
               exceptionGen_io_state_bits_exceptionVec_6,
               exceptionGen_io_state_bits_exceptionVec_5,
               exceptionGen_io_state_bits_exceptionVec_4,
               exceptionGen_io_state_bits_exceptionVec_3,
               exceptionGen_io_state_bits_exceptionVec_2,
               exceptionGen_io_state_bits_exceptionVec_1,
               exceptionGen_io_state_bits_exceptionVec_0};
  end

  always_ff @(posedge clock) intrBitSetReg <= io_csr_intrBitSet;
  assign intrBitSetRegOut = intrBitSetReg;
  assign criticalErrorState = io_csr_criticalErrorState;

  assign deqPtrEntryValid = rawInfo[0].commit_v;
  assign intrEnable = intrBitSetReg & ~hasWaitForward & rawInfo[0].interrupt_safe
                    & ~deqHasFlushed;
  assign deqNeedFlush = rawInfo[0].needFlush & rawInfo[0].commit_v & rawInfo[0].commit_w;
  assign deqHitExceptionGenState = exceptionGen_io_state_valid
      & (exceptionGen_io_state_bits_robIdx_value == deqPtrValue[0])
      & (exceptionGen_io_state_bits_robIdx_flag  == deqPtrFlag[0]);
  assign deqNeedFlushAndHitExceptionGenState = deqNeedFlush & deqHitExceptionGenState;
  assign exceptionGenStateIsException = (|excpVec)
      | exceptionGen_io_state_bits_singleStep
      | (exceptionGen_io_state_bits_trigger == TA_DMODE);

  always_ff @(posedge clock) commit_w_delay <= rawInfo[0].commit_w;

  assign deqHasException   = deqNeedFlushAndHitExceptionGenState
                           & exceptionGenStateIsException & commit_w_delay;
  assign deqHasFlushPipe   = deqNeedFlushAndHitExceptionGenState
                           & exceptionGen_io_state_bits_flushPipe
                           & ~deqHasException & commit_w_delay;
  assign deqHasReplayInst  = deqNeedFlushAndHitExceptionGenState
                           & exceptionGen_io_state_bits_replayInst;
  assign deqIsVlsException = deqHasException & rawInfo[0].isVls
                           & ~exceptionGen_io_state_bits_isEnqExcp;
  assign deqIsVlsFlushPipe = deqHasFlushPipe & rawInfo[0].isVls;
  assign deqCanException   = deqHasException & (~deqIsVlsException | deqVlsCanCommit);
  assign deqCanFlushPipe   = deqHasFlushPipe & (~deqIsVlsFlushPipe | deqVlsCanCommit);

  // 向量访存的异常只有等 RAB 把它那几对寄存器全提交完才算数，所以要等两拍 + commitEnd
  always_ff @(posedge clock) begin
    deqVlsCanCommit_REG   <= (deqIsVlsException | deqIsVlsFlushPipe) & rawInfo[0].commit_w;
    deqVlsCanCommit_REG_1 <= deqVlsCanCommit_REG;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) deqVlsCanCommit <= 1'b0;
    else       deqVlsCanCommit <= deqVlsCanCommit_REG_1 & rab_io_status_commitEnd;
  end

  assign handleVlsExcp = deqIsVlsException & deqVlsCanCommit & ~deqVlsExcpLock
                       & (state == S_IDLE);
  always_ff @(posedge clock or posedge reset) begin
    if (reset) deqVlsExcpLock <= 1'b0;
    else if (handleVlsExcp) deqVlsExcpLock <= 1'b1;
    else if ((deqPtrValue[0] != deqPtrVec_next_0_value)
             | (deqPtrFlag[0] != deqPtrVec_next_0_flag)) deqVlsExcpLock <= 1'b0;
  end

  // 只在 deqVlsExcp 发生时向 RAB 发一次，免得重复报
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      deqVlsExceptionNeedCommit <= 1'b0;
      deqVlsExceptionCommitSize <= {UOPNUM_W{1'b0}};
    end else if (deqVlsExceptionNeedCommit) begin
      deqVlsExceptionNeedCommit <= 1'b0;
    end else if (handleVlsExcp) begin
      deqVlsExceptionCommitSize <= rawInfo[0].realDestSize;
      deqVlsExceptionNeedCommit <= 1'b1;
    end
  end

  assign isFlushPipe = rawInfo[0].commit_w & (deqHasFlushPipe | deqHasReplayInst);
  assign isVsetFlushPipe = rawInfo[0].commit_w & deqHasFlushed
                         & exceptionGen_io_state_bits_isVset;
  always_ff @(posedge clock) isVsetFlushPipeReg <= isVsetFlushPipe;
  // ★io.isVsetFlushPipe 在 golden 里没有端口★（下游没人用，firtool 把整条输出消了）。
  //   照 Scala 写 `io_isVsetFlushPipe` 会变成一根**隐式 wire**（VCS 默认 nettype
  //   是 wire，不报错），安静地悬空。isVsetFlushPipe 本身仍然要算 —— 它喂
  //   isVsetFlushPipeReg，再进 io_toDecode_isResumeVType。
  assign io_toDecode_isResumeVType = vtypeBuffer_io_toDecode_isResumeVType
                                   | isVsetFlushPipeReg;

  always_ff @(posedge clock) lastCycleFlush <= io_flushOut_valid;

  assign io_flushOut_valid = (state == S_IDLE) & deqPtrEntryValid
      & (intrEnable | deqCanException | deqCanFlushPipe) & ~lastCycleFlush;
  assign io_flushOut_valid_0 = io_flushOut_valid;   // 同一根，送 exceptionGen.io_flush

  // io.flushOut.bits := DontCare 之后逐字段赋值；needModifyFtqIdxOffset 恒假
  // （Scala 里写死 `val needModifyFtqIdxOffset = false.B`），所以 Mux 全被折掉。
  assign io_flushOut_bits_isRVC        = rawInfo[0].isRVC;
  assign io_flushOut_bits_robIdx_flag  = deqPtrFlag[0];
  assign io_flushOut_bits_robIdx_value = deqPtrValue[0];
  assign io_flushOut_bits_ftqIdx_flag  = rawInfo[0].ftqIdx_flag;
  assign io_flushOut_bits_ftqIdx_value = rawInfo[0].ftqIdx_value;
  assign io_flushOut_bits_ftqOffset    = rawInfo[0].ftqOffset;
  assign io_flushOut_bits_level        = (deqHasReplayInst | intrEnable | deqHasException)
                                       ? RL_FLUSH : RL_FLUSH_AFTER;
  assign io_flushOut_bits_satpFlush    = isFlushPipe
                                       & exceptionGen_io_state_bits_satpFlushPipe;
  assign io_flushOut_bits_isVlsException = deqHasException & deqIsVlsException;

  assign exceptionHappen = (state == S_IDLE) & deqPtrEntryValid
      & (intrEnable | deqCanException) & ~lastCycleFlush;

  // ---- 提交阻塞 ----
  always_ff @(posedge clock) begin
    misPredBlockCounter <= misPredWb ? 3'b111 : (misPredBlockCounter >> 1);
    deqHitRedirectReg_REG <= io_redirect_valid
                           & (io_redirect_bits_robIdx_value == deqPtrValue[0])
                           & (io_redirect_bits_robIdx_flag  == deqPtrFlag[0]);
    deqHitRedirectReg_REG_1 <= io_redirect_valid
                             & (io_redirect_bits_robIdx_value == deqPtrValue[0])
                             & (io_redirect_bits_robIdx_flag  == deqPtrFlag[0]);
    deqHitRedirectReg_REG_2 <= deqHitRedirectReg_REG_1;
    deqFlushBlockCounter <= (deqNeedFlush & deqHitRedirectReg)
                          ? 3'b111 : (deqFlushBlockCounter >> 1);
  end
  assign deqHitRedirectReg = deqHitRedirectReg_REG | deqHitRedirectReg_REG_2;
  assign misPredBlock  = misPredBlockCounter[0];
  assign deqFlushBlock = deqFlushBlockCounter[0];
  assign deqHasCommitted = io_commits_isCommit & io_commits_commitValid_0;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) deqHasFlushed <= 1'b0;
    else if (deqHasCommitted) deqHasFlushed <= 1'b0;
    else if (deqNeedFlush & io_flushOut_valid & ~io_flushOut_bits_level)
      deqHasFlushed <= 1'b1;
  end

  assign blockCommitInt = misPredBlock | lastCycleFlush | hasWFI | io_redirect_valid
      | (deqNeedFlush & ~deqHasFlushed) | deqFlushBlock | criticalErrorState
      | io_trace_blockCommit;
  assign blockCommit = blockCommitInt;

  assign io_commits_isWalk   = (state == S_WALK);
  assign io_commits_isCommit = (state == S_IDLE) & ~blockCommitInt;


  // ==========================================================================
  // §15 提交 / 走回的对外输出
  // ==========================================================================
  // ★commit_vDeqGroup / commit_wDeqGroup 是**按 bank 直接取**的★（robDeqGroup(b)），
  //   不是按 deqPtrVec 选出来的那一份 —— 送给 deqPtrGenModule 的就是这八个原值。
  logic commit_block       [COMMIT_W];
  logic commitValidThisLine[COMMIT_W];
  logic shouldWalkVec      [COMMIT_W];
  logic hasCommittedVec    [COMMIT_W];
  logic isBlocked, allowOnlyOneCommitInt;

  assign commit_vDeqGroup_0 = robDeqGroup_commit_v[0];
  assign commit_vDeqGroup_1 = robDeqGroup_commit_v[1];
  assign commit_vDeqGroup_2 = robDeqGroup_commit_v[2];
  assign commit_vDeqGroup_3 = robDeqGroup_commit_v[3];
  assign commit_vDeqGroup_4 = robDeqGroup_commit_v[4];
  assign commit_vDeqGroup_5 = robDeqGroup_commit_v[5];
  assign commit_vDeqGroup_6 = robDeqGroup_commit_v[6];
  assign commit_vDeqGroup_7 = robDeqGroup_commit_v[7];
  assign commit_wDeqGroup_0 = robDeqGroup_commit_w[0];
  assign commit_wDeqGroup_1 = robDeqGroup_commit_w[1];
  assign commit_wDeqGroup_2 = robDeqGroup_commit_w[2];
  assign commit_wDeqGroup_3 = robDeqGroup_commit_w[3];
  assign commit_wDeqGroup_4 = robDeqGroup_commit_w[4];
  assign commit_wDeqGroup_5 = robDeqGroup_commit_w[5];
  assign commit_wDeqGroup_6 = robDeqGroup_commit_w[6];
  assign commit_wDeqGroup_7 = robDeqGroup_commit_w[7];

  // hasCommitted_0..7 同样按 golden 起名（见 donotNeedWalk 那段的理由）
  always_comb begin
    hasCommittedVec[0] = hasCommitted_0;  hasCommittedVec[1] = hasCommitted_1;
    hasCommittedVec[2] = hasCommitted_2;  hasCommittedVec[3] = hasCommitted_3;
    hasCommittedVec[4] = hasCommitted_4;  hasCommittedVec[5] = hasCommitted_5;
    hasCommittedVec[6] = hasCommitted_6;  hasCommittedVec[7] = hasCommitted_7;
  end
  assign hasCommittedOut_0 = hasCommitted_0;
  assign hasCommittedOut_1 = hasCommitted_1;
  assign hasCommittedOut_2 = hasCommitted_2;
  assign hasCommittedOut_3 = hasCommitted_3;
  assign hasCommittedOut_4 = hasCommitted_4;
  assign hasCommittedOut_5 = hasCommitted_5;
  assign hasCommittedOut_6 = hasCommitted_6;
  assign hasCommittedOut_7 = hasCommitted_7;

  // 队头有"要冲刷"的条目、或者中断挂着时，一拍只准提交一条
  always_comb begin
    allowOnlyOneCommitInt = intrBitSetReg;
    for (int b = 0; b < BANK_N; b++)
      allowOnlyOneCommitInt = allowOnlyOneCommitInt
                            | (robDeqGroup_commit_v[b] & robDeqGroup_needFlush[b]);
  end
  assign allowOnlyOneCommit = allowOnlyOneCommitInt;

  assign isBlocked = intrEnable | (deqNeedFlush & ~deqHasFlushed);

  always_comb begin
    for (int i = 0; i < COMMIT_W; i++)
      commit_block[i] = ~robDeqGroup_commit_w[i] & ~hasCommittedVec[i];
  end

  always_comb begin
    for (int i = 0; i < COMMIT_W; i++) begin
      automatic logic blockedByOlder;
      automatic logic allOlderCommitted;
      blockedByOlder    = 1'b0;
      allOlderCommitted = 1'b1;
      for (int k = 0; k < COMMIT_W; k++) begin
        if (k <= i)     blockedByOlder    = blockedByOlder    | commit_block[k];
        if (k <  i)     allOlderCommitted = allOlderCommitted & hasCommittedVec[k];
      end
      if (i == 0) begin
        blockedByOlder    = 1'b0;         // 第 0 条没有更老的
        allOlderCommitted = 1'b1;
      end else begin
        blockedByOlder = blockedByOlder
                       | (allowOnlyOneCommitInt & ~allOlderCommitted);
      end
      commitValidThisLine[i] = robDeqGroup_commit_v[i] & robDeqGroup_commit_w[i]
                             & ~isBlocked & ~blockedByOlder & ~hasCommittedVec[i];
    end
  end

  assign allCommitted = io_commits_isCommit & commitValidThisLine[COMMIT_W-1];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      hasCommitted_0 <= 1'b0;  hasCommitted_1 <= 1'b0;
      hasCommitted_2 <= 1'b0;  hasCommitted_3 <= 1'b0;
      hasCommitted_4 <= 1'b0;  hasCommitted_5 <= 1'b0;
      hasCommitted_6 <= 1'b0;  hasCommitted_7 <= 1'b0;
    end else if (allCommitted) begin
      hasCommitted_0 <= 1'b0;  hasCommitted_1 <= 1'b0;
      hasCommitted_2 <= 1'b0;  hasCommitted_3 <= 1'b0;
      hasCommitted_4 <= 1'b0;  hasCommitted_5 <= 1'b0;
      hasCommitted_6 <= 1'b0;  hasCommitted_7 <= 1'b0;
    end else if (io_commits_isCommit) begin
      hasCommitted_0 <= commitValidThisLine[0] | hasCommitted_0;
      hasCommitted_1 <= commitValidThisLine[1] | hasCommitted_1;
      hasCommitted_2 <= commitValidThisLine[2] | hasCommitted_2;
      hasCommitted_3 <= commitValidThisLine[3] | hasCommitted_3;
      hasCommitted_4 <= commitValidThisLine[4] | hasCommitted_4;
      hasCommitted_5 <= commitValidThisLine[5] | hasCommitted_5;
      hasCommitted_6 <= commitValidThisLine[6] | hasCommitted_6;
      hasCommitted_7 <= commitValidThisLine[7] | hasCommitted_7;
    end
  end

  // ★io.commits.commitValid 不是 commitValidThisLine 本身★：
  //   Scala 是 PriorityMux(commitValidThisLine, 各种右移过的它自己) ——
  //   找到第一个为真的位 i，输出整条右移 i 位。没有任何一位为真时，
  //   PriorityMux 落到最后一项，也就是右移 7 位。
  always_comb begin
    automatic logic [COMMIT_W-1:0] cvtl;
    for (int i = 0; i < COMMIT_W; i++) cvtl[i] = commitValidThisLine[i];
    for (int i = 0; i < COMMIT_W; i++) commitValidOut[i] = cvtl[COMMIT_W-1];
    for (int s = COMMIT_W - 1; s >= 0; s--)
      if (cvtl[s] | (s == COMMIT_W - 1))
        for (int i = 0; i < COMMIT_W; i++)
          commitValidOut[i] = ((s + i) < COMMIT_W) ? cvtl[s + i] : 1'b0;
  end

  // 走回：T redirect.valid，T+1 用 walkPtrVec 读条目，T+2 才真正走
  always_comb begin
    for (int i = 0; i < COMMIT_W; i++) begin
      if (io_redirect_valid | REG_7)               shouldWalkVec[i] = 1'b0;
      else if (state == S_WALK)
        shouldWalkVec[i] = ptrLe(walkingPtrVec_flag[i], walkingPtrVec_value[i],
                                 lastWalkPtr_flag, lastWalkPtr_value)
                         & ~donotNeedWalkVec[i];
      else                                         shouldWalkVec[i] = 1'b0;
    end
  end

  assign io_commits_commitValid_0 = commitValidOut[0];
  assign io_commits_commitValid_1 = commitValidOut[1];
  assign io_commits_commitValid_2 = commitValidOut[2];
  assign io_commits_commitValid_3 = commitValidOut[3];
  assign io_commits_commitValid_4 = commitValidOut[4];
  assign io_commits_commitValid_5 = commitValidOut[5];
  assign io_commits_commitValid_6 = commitValidOut[6];
  assign io_commits_commitValid_7 = commitValidOut[7];
  assign io_commits_walkValid_0   = shouldWalkVec[0];
  assign io_commits_walkValid_1   = shouldWalkVec[1];
  assign io_commits_walkValid_2   = shouldWalkVec[2];
  assign io_commits_walkValid_3   = shouldWalkVec[3];
  assign io_commits_walkValid_4   = shouldWalkVec[4];
  assign io_commits_walkValid_5   = shouldWalkVec[5];
  assign io_commits_walkValid_6   = shouldWalkVec[6];
  assign io_commits_walkValid_7   = shouldWalkVec[7];
  assign io_commits_robIdx_0_flag  = deqPtrFlag[0];
  assign io_commits_robIdx_0_value = deqPtrValue[0];
  assign io_commits_robIdx_1_flag  = deqPtrFlag[1];
  assign io_commits_robIdx_1_value = deqPtrValue[1];
  assign io_commits_robIdx_2_flag  = deqPtrFlag[2];
  assign io_commits_robIdx_2_value = deqPtrValue[2];
  assign io_commits_robIdx_3_flag  = deqPtrFlag[3];
  assign io_commits_robIdx_3_value = deqPtrValue[3];
  assign io_commits_robIdx_4_flag  = deqPtrFlag[4];
  assign io_commits_robIdx_4_value = deqPtrValue[4];
  assign io_commits_robIdx_5_flag  = deqPtrFlag[5];
  assign io_commits_robIdx_5_value = deqPtrValue[5];
  assign io_commits_robIdx_6_flag  = deqPtrFlag[6];
  assign io_commits_robIdx_6_value = deqPtrValue[6];
  assign io_commits_robIdx_7_flag  = deqPtrFlag[7];
  assign io_commits_robIdx_7_value = deqPtrValue[7];

  always_comb begin
    commitsHasWalkInstr   = 1'b0;
    commitsHasCommitInstr = 1'b0;
    for (int i = 0; i < COMMIT_W; i++) begin
      commitsHasWalkInstr   = commitsHasWalkInstr   | shouldWalkVec[i];
      commitsHasCommitInstr = commitsHasCommitInstr | commitValidOut[i];
    end
    commitsHasWalkInstr   = commitsHasWalkInstr   & io_commits_isWalk;
    commitsHasCommitInstr = commitsHasCommitInstr & io_commits_isCommit;
  end

  // ---- io_commits_info_<i>_<field>：360 根，全部来自 commitInfo ----
  assign io_commits_info_0_walk_v                       = commitInfo[0].walk_v;
  assign io_commits_info_0_commit_v                     = commitInfo[0].commit_v;
  assign io_commits_info_0_commit_w                     = commitInfo[0].commit_w;
  assign io_commits_info_0_realDestSize                 = commitInfo[0].realDestSize;
  assign io_commits_info_0_interrupt_safe               = commitInfo[0].interrupt_safe;
  assign io_commits_info_0_wflags                       = commitInfo[0].wflags;
  assign io_commits_info_0_fflags                       = commitInfo[0].fflags;
  assign io_commits_info_0_vxsat                        = commitInfo[0].vxsat;
  assign io_commits_info_0_isRVC                        = commitInfo[0].isRVC;
  assign io_commits_info_0_isVset                       = commitInfo[0].isVset;
  assign io_commits_info_0_isHls                        = commitInfo[0].isHls;
  assign io_commits_info_0_isVls                        = commitInfo[0].isVls;
  assign io_commits_info_0_vls                          = commitInfo[0].vls;
  assign io_commits_info_0_mmio                         = commitInfo[0].mmio;
  assign io_commits_info_0_commitType                   = commitInfo[0].commitType;
  assign io_commits_info_0_ftqIdx_flag                  = commitInfo[0].ftqIdx_flag;
  assign io_commits_info_0_ftqIdx_value                 = commitInfo[0].ftqIdx_value;
  assign io_commits_info_0_ftqOffset                    = commitInfo[0].ftqOffset;
  assign io_commits_info_0_instrSize                    = commitInfo[0].instrSize;
  assign io_commits_info_0_fpWen                        = commitInfo[0].fpWen;
  assign io_commits_info_0_rfWen                        = commitInfo[0].rfWen;
  assign io_commits_info_0_needFlush                    = commitInfo[0].needFlush;
  assign io_commits_info_0_traceBlockInPipe_itype       = commitInfo[0].traceBlockInPipe_itype;
  assign io_commits_info_0_traceBlockInPipe_iretire     = commitInfo[0].traceBlockInPipe_iretire;
  assign io_commits_info_0_traceBlockInPipe_ilastsize   = commitInfo[0].traceBlockInPipe_ilastsize;
  assign io_commits_info_0_debug_pc                     = commitInfo[0].debug_pc;
  assign io_commits_info_0_debug_instr                  = commitInfo[0].debug_instr;
  assign io_commits_info_0_basicDebug_ldest             = commitInfo[0].basicDebug_ldest;
  assign io_commits_info_0_basicDebug_pdest             = commitInfo[0].basicDebug_pdest;
  assign io_commits_info_0_basicDebug_vd                = commitInfo[0].basicDebug_vd;
  assign io_commits_info_0_basicDebug_fpWen             = commitInfo[0].basicDebug_fpWen;
  assign io_commits_info_0_basicDebug_vecWen            = commitInfo[0].basicDebug_vecWen;
  assign io_commits_info_0_basicDebug_v0Wen             = commitInfo[0].basicDebug_v0Wen;
  assign io_commits_info_0_basicDebug_eliminatedMove    = commitInfo[0].basicDebug_eliminatedMove;
  assign io_commits_info_0_basicDebug_isXSTrap          = commitInfo[0].basicDebug_isXSTrap;
  assign io_commits_info_0_debug_fuType                 = commitInfo[0].debug_fuType;
  assign io_commits_info_0_dirtyFs                      = commitInfo[0].dirtyFs;
  assign io_commits_info_0_dirtyVs                      = commitInfo[0].dirtyVs;
  assign io_commits_info_0_debug_otherPdest_0           = commitInfo[0].debug_otherPdest_0;
  assign io_commits_info_0_debug_otherPdest_1           = commitInfo[0].debug_otherPdest_1;
  assign io_commits_info_0_debug_otherPdest_2           = commitInfo[0].debug_otherPdest_2;
  assign io_commits_info_0_debug_otherPdest_3           = commitInfo[0].debug_otherPdest_3;
  assign io_commits_info_0_debug_otherPdest_4           = commitInfo[0].debug_otherPdest_4;
  assign io_commits_info_0_debug_otherPdest_5           = commitInfo[0].debug_otherPdest_5;
  assign io_commits_info_0_debug_otherPdest_6           = commitInfo[0].debug_otherPdest_6;

  assign io_commits_info_1_walk_v                       = commitInfo[1].walk_v;
  assign io_commits_info_1_commit_v                     = commitInfo[1].commit_v;
  assign io_commits_info_1_commit_w                     = commitInfo[1].commit_w;
  assign io_commits_info_1_realDestSize                 = commitInfo[1].realDestSize;
  assign io_commits_info_1_interrupt_safe               = commitInfo[1].interrupt_safe;
  assign io_commits_info_1_wflags                       = commitInfo[1].wflags;
  assign io_commits_info_1_fflags                       = commitInfo[1].fflags;
  assign io_commits_info_1_vxsat                        = commitInfo[1].vxsat;
  assign io_commits_info_1_isRVC                        = commitInfo[1].isRVC;
  assign io_commits_info_1_isVset                       = commitInfo[1].isVset;
  assign io_commits_info_1_isHls                        = commitInfo[1].isHls;
  assign io_commits_info_1_isVls                        = commitInfo[1].isVls;
  assign io_commits_info_1_vls                          = commitInfo[1].vls;
  assign io_commits_info_1_mmio                         = commitInfo[1].mmio;
  assign io_commits_info_1_commitType                   = commitInfo[1].commitType;
  assign io_commits_info_1_ftqIdx_flag                  = commitInfo[1].ftqIdx_flag;
  assign io_commits_info_1_ftqIdx_value                 = commitInfo[1].ftqIdx_value;
  assign io_commits_info_1_ftqOffset                    = commitInfo[1].ftqOffset;
  assign io_commits_info_1_instrSize                    = commitInfo[1].instrSize;
  assign io_commits_info_1_fpWen                        = commitInfo[1].fpWen;
  assign io_commits_info_1_rfWen                        = commitInfo[1].rfWen;
  assign io_commits_info_1_needFlush                    = commitInfo[1].needFlush;
  assign io_commits_info_1_traceBlockInPipe_itype       = commitInfo[1].traceBlockInPipe_itype;
  assign io_commits_info_1_traceBlockInPipe_iretire     = commitInfo[1].traceBlockInPipe_iretire;
  assign io_commits_info_1_traceBlockInPipe_ilastsize   = commitInfo[1].traceBlockInPipe_ilastsize;
  assign io_commits_info_1_debug_pc                     = commitInfo[1].debug_pc;
  assign io_commits_info_1_debug_instr                  = commitInfo[1].debug_instr;
  assign io_commits_info_1_basicDebug_ldest             = commitInfo[1].basicDebug_ldest;
  assign io_commits_info_1_basicDebug_pdest             = commitInfo[1].basicDebug_pdest;
  assign io_commits_info_1_basicDebug_vd                = commitInfo[1].basicDebug_vd;
  assign io_commits_info_1_basicDebug_fpWen             = commitInfo[1].basicDebug_fpWen;
  assign io_commits_info_1_basicDebug_vecWen            = commitInfo[1].basicDebug_vecWen;
  assign io_commits_info_1_basicDebug_v0Wen             = commitInfo[1].basicDebug_v0Wen;
  assign io_commits_info_1_basicDebug_eliminatedMove    = commitInfo[1].basicDebug_eliminatedMove;
  assign io_commits_info_1_basicDebug_isXSTrap          = commitInfo[1].basicDebug_isXSTrap;
  assign io_commits_info_1_debug_fuType                 = commitInfo[1].debug_fuType;
  assign io_commits_info_1_dirtyFs                      = commitInfo[1].dirtyFs;
  assign io_commits_info_1_dirtyVs                      = commitInfo[1].dirtyVs;
  assign io_commits_info_1_debug_otherPdest_0           = commitInfo[1].debug_otherPdest_0;
  assign io_commits_info_1_debug_otherPdest_1           = commitInfo[1].debug_otherPdest_1;
  assign io_commits_info_1_debug_otherPdest_2           = commitInfo[1].debug_otherPdest_2;
  assign io_commits_info_1_debug_otherPdest_3           = commitInfo[1].debug_otherPdest_3;
  assign io_commits_info_1_debug_otherPdest_4           = commitInfo[1].debug_otherPdest_4;
  assign io_commits_info_1_debug_otherPdest_5           = commitInfo[1].debug_otherPdest_5;
  assign io_commits_info_1_debug_otherPdest_6           = commitInfo[1].debug_otherPdest_6;

  assign io_commits_info_2_walk_v                       = commitInfo[2].walk_v;
  assign io_commits_info_2_commit_v                     = commitInfo[2].commit_v;
  assign io_commits_info_2_commit_w                     = commitInfo[2].commit_w;
  assign io_commits_info_2_realDestSize                 = commitInfo[2].realDestSize;
  assign io_commits_info_2_interrupt_safe               = commitInfo[2].interrupt_safe;
  assign io_commits_info_2_wflags                       = commitInfo[2].wflags;
  assign io_commits_info_2_fflags                       = commitInfo[2].fflags;
  assign io_commits_info_2_vxsat                        = commitInfo[2].vxsat;
  assign io_commits_info_2_isRVC                        = commitInfo[2].isRVC;
  assign io_commits_info_2_isVset                       = commitInfo[2].isVset;
  assign io_commits_info_2_isHls                        = commitInfo[2].isHls;
  assign io_commits_info_2_isVls                        = commitInfo[2].isVls;
  assign io_commits_info_2_vls                          = commitInfo[2].vls;
  assign io_commits_info_2_mmio                         = commitInfo[2].mmio;
  assign io_commits_info_2_commitType                   = commitInfo[2].commitType;
  assign io_commits_info_2_ftqIdx_flag                  = commitInfo[2].ftqIdx_flag;
  assign io_commits_info_2_ftqIdx_value                 = commitInfo[2].ftqIdx_value;
  assign io_commits_info_2_ftqOffset                    = commitInfo[2].ftqOffset;
  assign io_commits_info_2_instrSize                    = commitInfo[2].instrSize;
  assign io_commits_info_2_fpWen                        = commitInfo[2].fpWen;
  assign io_commits_info_2_rfWen                        = commitInfo[2].rfWen;
  assign io_commits_info_2_needFlush                    = commitInfo[2].needFlush;
  assign io_commits_info_2_traceBlockInPipe_itype       = commitInfo[2].traceBlockInPipe_itype;
  assign io_commits_info_2_traceBlockInPipe_iretire     = commitInfo[2].traceBlockInPipe_iretire;
  assign io_commits_info_2_traceBlockInPipe_ilastsize   = commitInfo[2].traceBlockInPipe_ilastsize;
  assign io_commits_info_2_debug_pc                     = commitInfo[2].debug_pc;
  assign io_commits_info_2_debug_instr                  = commitInfo[2].debug_instr;
  assign io_commits_info_2_basicDebug_ldest             = commitInfo[2].basicDebug_ldest;
  assign io_commits_info_2_basicDebug_pdest             = commitInfo[2].basicDebug_pdest;
  assign io_commits_info_2_basicDebug_vd                = commitInfo[2].basicDebug_vd;
  assign io_commits_info_2_basicDebug_fpWen             = commitInfo[2].basicDebug_fpWen;
  assign io_commits_info_2_basicDebug_vecWen            = commitInfo[2].basicDebug_vecWen;
  assign io_commits_info_2_basicDebug_v0Wen             = commitInfo[2].basicDebug_v0Wen;
  assign io_commits_info_2_basicDebug_eliminatedMove    = commitInfo[2].basicDebug_eliminatedMove;
  assign io_commits_info_2_basicDebug_isXSTrap          = commitInfo[2].basicDebug_isXSTrap;
  assign io_commits_info_2_debug_fuType                 = commitInfo[2].debug_fuType;
  assign io_commits_info_2_dirtyFs                      = commitInfo[2].dirtyFs;
  assign io_commits_info_2_dirtyVs                      = commitInfo[2].dirtyVs;
  assign io_commits_info_2_debug_otherPdest_0           = commitInfo[2].debug_otherPdest_0;
  assign io_commits_info_2_debug_otherPdest_1           = commitInfo[2].debug_otherPdest_1;
  assign io_commits_info_2_debug_otherPdest_2           = commitInfo[2].debug_otherPdest_2;
  assign io_commits_info_2_debug_otherPdest_3           = commitInfo[2].debug_otherPdest_3;
  assign io_commits_info_2_debug_otherPdest_4           = commitInfo[2].debug_otherPdest_4;
  assign io_commits_info_2_debug_otherPdest_5           = commitInfo[2].debug_otherPdest_5;
  assign io_commits_info_2_debug_otherPdest_6           = commitInfo[2].debug_otherPdest_6;

  assign io_commits_info_3_walk_v                       = commitInfo[3].walk_v;
  assign io_commits_info_3_commit_v                     = commitInfo[3].commit_v;
  assign io_commits_info_3_commit_w                     = commitInfo[3].commit_w;
  assign io_commits_info_3_realDestSize                 = commitInfo[3].realDestSize;
  assign io_commits_info_3_interrupt_safe               = commitInfo[3].interrupt_safe;
  assign io_commits_info_3_wflags                       = commitInfo[3].wflags;
  assign io_commits_info_3_fflags                       = commitInfo[3].fflags;
  assign io_commits_info_3_vxsat                        = commitInfo[3].vxsat;
  assign io_commits_info_3_isRVC                        = commitInfo[3].isRVC;
  assign io_commits_info_3_isVset                       = commitInfo[3].isVset;
  assign io_commits_info_3_isHls                        = commitInfo[3].isHls;
  assign io_commits_info_3_isVls                        = commitInfo[3].isVls;
  assign io_commits_info_3_vls                          = commitInfo[3].vls;
  assign io_commits_info_3_mmio                         = commitInfo[3].mmio;
  assign io_commits_info_3_commitType                   = commitInfo[3].commitType;
  assign io_commits_info_3_ftqIdx_flag                  = commitInfo[3].ftqIdx_flag;
  assign io_commits_info_3_ftqIdx_value                 = commitInfo[3].ftqIdx_value;
  assign io_commits_info_3_ftqOffset                    = commitInfo[3].ftqOffset;
  assign io_commits_info_3_instrSize                    = commitInfo[3].instrSize;
  assign io_commits_info_3_fpWen                        = commitInfo[3].fpWen;
  assign io_commits_info_3_rfWen                        = commitInfo[3].rfWen;
  assign io_commits_info_3_needFlush                    = commitInfo[3].needFlush;
  assign io_commits_info_3_traceBlockInPipe_itype       = commitInfo[3].traceBlockInPipe_itype;
  assign io_commits_info_3_traceBlockInPipe_iretire     = commitInfo[3].traceBlockInPipe_iretire;
  assign io_commits_info_3_traceBlockInPipe_ilastsize   = commitInfo[3].traceBlockInPipe_ilastsize;
  assign io_commits_info_3_debug_pc                     = commitInfo[3].debug_pc;
  assign io_commits_info_3_debug_instr                  = commitInfo[3].debug_instr;
  assign io_commits_info_3_basicDebug_ldest             = commitInfo[3].basicDebug_ldest;
  assign io_commits_info_3_basicDebug_pdest             = commitInfo[3].basicDebug_pdest;
  assign io_commits_info_3_basicDebug_vd                = commitInfo[3].basicDebug_vd;
  assign io_commits_info_3_basicDebug_fpWen             = commitInfo[3].basicDebug_fpWen;
  assign io_commits_info_3_basicDebug_vecWen            = commitInfo[3].basicDebug_vecWen;
  assign io_commits_info_3_basicDebug_v0Wen             = commitInfo[3].basicDebug_v0Wen;
  assign io_commits_info_3_basicDebug_eliminatedMove    = commitInfo[3].basicDebug_eliminatedMove;
  assign io_commits_info_3_basicDebug_isXSTrap          = commitInfo[3].basicDebug_isXSTrap;
  assign io_commits_info_3_debug_fuType                 = commitInfo[3].debug_fuType;
  assign io_commits_info_3_dirtyFs                      = commitInfo[3].dirtyFs;
  assign io_commits_info_3_dirtyVs                      = commitInfo[3].dirtyVs;
  assign io_commits_info_3_debug_otherPdest_0           = commitInfo[3].debug_otherPdest_0;
  assign io_commits_info_3_debug_otherPdest_1           = commitInfo[3].debug_otherPdest_1;
  assign io_commits_info_3_debug_otherPdest_2           = commitInfo[3].debug_otherPdest_2;
  assign io_commits_info_3_debug_otherPdest_3           = commitInfo[3].debug_otherPdest_3;
  assign io_commits_info_3_debug_otherPdest_4           = commitInfo[3].debug_otherPdest_4;
  assign io_commits_info_3_debug_otherPdest_5           = commitInfo[3].debug_otherPdest_5;
  assign io_commits_info_3_debug_otherPdest_6           = commitInfo[3].debug_otherPdest_6;

  assign io_commits_info_4_walk_v                       = commitInfo[4].walk_v;
  assign io_commits_info_4_commit_v                     = commitInfo[4].commit_v;
  assign io_commits_info_4_commit_w                     = commitInfo[4].commit_w;
  assign io_commits_info_4_realDestSize                 = commitInfo[4].realDestSize;
  assign io_commits_info_4_interrupt_safe               = commitInfo[4].interrupt_safe;
  assign io_commits_info_4_wflags                       = commitInfo[4].wflags;
  assign io_commits_info_4_fflags                       = commitInfo[4].fflags;
  assign io_commits_info_4_vxsat                        = commitInfo[4].vxsat;
  assign io_commits_info_4_isRVC                        = commitInfo[4].isRVC;
  assign io_commits_info_4_isVset                       = commitInfo[4].isVset;
  assign io_commits_info_4_isHls                        = commitInfo[4].isHls;
  assign io_commits_info_4_isVls                        = commitInfo[4].isVls;
  assign io_commits_info_4_vls                          = commitInfo[4].vls;
  assign io_commits_info_4_mmio                         = commitInfo[4].mmio;
  assign io_commits_info_4_commitType                   = commitInfo[4].commitType;
  assign io_commits_info_4_ftqIdx_flag                  = commitInfo[4].ftqIdx_flag;
  assign io_commits_info_4_ftqIdx_value                 = commitInfo[4].ftqIdx_value;
  assign io_commits_info_4_ftqOffset                    = commitInfo[4].ftqOffset;
  assign io_commits_info_4_instrSize                    = commitInfo[4].instrSize;
  assign io_commits_info_4_fpWen                        = commitInfo[4].fpWen;
  assign io_commits_info_4_rfWen                        = commitInfo[4].rfWen;
  assign io_commits_info_4_needFlush                    = commitInfo[4].needFlush;
  assign io_commits_info_4_traceBlockInPipe_itype       = commitInfo[4].traceBlockInPipe_itype;
  assign io_commits_info_4_traceBlockInPipe_iretire     = commitInfo[4].traceBlockInPipe_iretire;
  assign io_commits_info_4_traceBlockInPipe_ilastsize   = commitInfo[4].traceBlockInPipe_ilastsize;
  assign io_commits_info_4_debug_pc                     = commitInfo[4].debug_pc;
  assign io_commits_info_4_debug_instr                  = commitInfo[4].debug_instr;
  assign io_commits_info_4_basicDebug_ldest             = commitInfo[4].basicDebug_ldest;
  assign io_commits_info_4_basicDebug_pdest             = commitInfo[4].basicDebug_pdest;
  assign io_commits_info_4_basicDebug_vd                = commitInfo[4].basicDebug_vd;
  assign io_commits_info_4_basicDebug_fpWen             = commitInfo[4].basicDebug_fpWen;
  assign io_commits_info_4_basicDebug_vecWen            = commitInfo[4].basicDebug_vecWen;
  assign io_commits_info_4_basicDebug_v0Wen             = commitInfo[4].basicDebug_v0Wen;
  assign io_commits_info_4_basicDebug_eliminatedMove    = commitInfo[4].basicDebug_eliminatedMove;
  assign io_commits_info_4_basicDebug_isXSTrap          = commitInfo[4].basicDebug_isXSTrap;
  assign io_commits_info_4_debug_fuType                 = commitInfo[4].debug_fuType;
  assign io_commits_info_4_dirtyFs                      = commitInfo[4].dirtyFs;
  assign io_commits_info_4_dirtyVs                      = commitInfo[4].dirtyVs;
  assign io_commits_info_4_debug_otherPdest_0           = commitInfo[4].debug_otherPdest_0;
  assign io_commits_info_4_debug_otherPdest_1           = commitInfo[4].debug_otherPdest_1;
  assign io_commits_info_4_debug_otherPdest_2           = commitInfo[4].debug_otherPdest_2;
  assign io_commits_info_4_debug_otherPdest_3           = commitInfo[4].debug_otherPdest_3;
  assign io_commits_info_4_debug_otherPdest_4           = commitInfo[4].debug_otherPdest_4;
  assign io_commits_info_4_debug_otherPdest_5           = commitInfo[4].debug_otherPdest_5;
  assign io_commits_info_4_debug_otherPdest_6           = commitInfo[4].debug_otherPdest_6;

  assign io_commits_info_5_walk_v                       = commitInfo[5].walk_v;
  assign io_commits_info_5_commit_v                     = commitInfo[5].commit_v;
  assign io_commits_info_5_commit_w                     = commitInfo[5].commit_w;
  assign io_commits_info_5_realDestSize                 = commitInfo[5].realDestSize;
  assign io_commits_info_5_interrupt_safe               = commitInfo[5].interrupt_safe;
  assign io_commits_info_5_wflags                       = commitInfo[5].wflags;
  assign io_commits_info_5_fflags                       = commitInfo[5].fflags;
  assign io_commits_info_5_vxsat                        = commitInfo[5].vxsat;
  assign io_commits_info_5_isRVC                        = commitInfo[5].isRVC;
  assign io_commits_info_5_isVset                       = commitInfo[5].isVset;
  assign io_commits_info_5_isHls                        = commitInfo[5].isHls;
  assign io_commits_info_5_isVls                        = commitInfo[5].isVls;
  assign io_commits_info_5_vls                          = commitInfo[5].vls;
  assign io_commits_info_5_mmio                         = commitInfo[5].mmio;
  assign io_commits_info_5_commitType                   = commitInfo[5].commitType;
  assign io_commits_info_5_ftqIdx_flag                  = commitInfo[5].ftqIdx_flag;
  assign io_commits_info_5_ftqIdx_value                 = commitInfo[5].ftqIdx_value;
  assign io_commits_info_5_ftqOffset                    = commitInfo[5].ftqOffset;
  assign io_commits_info_5_instrSize                    = commitInfo[5].instrSize;
  assign io_commits_info_5_fpWen                        = commitInfo[5].fpWen;
  assign io_commits_info_5_rfWen                        = commitInfo[5].rfWen;
  assign io_commits_info_5_needFlush                    = commitInfo[5].needFlush;
  assign io_commits_info_5_traceBlockInPipe_itype       = commitInfo[5].traceBlockInPipe_itype;
  assign io_commits_info_5_traceBlockInPipe_iretire     = commitInfo[5].traceBlockInPipe_iretire;
  assign io_commits_info_5_traceBlockInPipe_ilastsize   = commitInfo[5].traceBlockInPipe_ilastsize;
  assign io_commits_info_5_debug_pc                     = commitInfo[5].debug_pc;
  assign io_commits_info_5_debug_instr                  = commitInfo[5].debug_instr;
  assign io_commits_info_5_basicDebug_ldest             = commitInfo[5].basicDebug_ldest;
  assign io_commits_info_5_basicDebug_pdest             = commitInfo[5].basicDebug_pdest;
  assign io_commits_info_5_basicDebug_vd                = commitInfo[5].basicDebug_vd;
  assign io_commits_info_5_basicDebug_fpWen             = commitInfo[5].basicDebug_fpWen;
  assign io_commits_info_5_basicDebug_vecWen            = commitInfo[5].basicDebug_vecWen;
  assign io_commits_info_5_basicDebug_v0Wen             = commitInfo[5].basicDebug_v0Wen;
  assign io_commits_info_5_basicDebug_eliminatedMove    = commitInfo[5].basicDebug_eliminatedMove;
  assign io_commits_info_5_basicDebug_isXSTrap          = commitInfo[5].basicDebug_isXSTrap;
  assign io_commits_info_5_debug_fuType                 = commitInfo[5].debug_fuType;
  assign io_commits_info_5_dirtyFs                      = commitInfo[5].dirtyFs;
  assign io_commits_info_5_dirtyVs                      = commitInfo[5].dirtyVs;
  assign io_commits_info_5_debug_otherPdest_0           = commitInfo[5].debug_otherPdest_0;
  assign io_commits_info_5_debug_otherPdest_1           = commitInfo[5].debug_otherPdest_1;
  assign io_commits_info_5_debug_otherPdest_2           = commitInfo[5].debug_otherPdest_2;
  assign io_commits_info_5_debug_otherPdest_3           = commitInfo[5].debug_otherPdest_3;
  assign io_commits_info_5_debug_otherPdest_4           = commitInfo[5].debug_otherPdest_4;
  assign io_commits_info_5_debug_otherPdest_5           = commitInfo[5].debug_otherPdest_5;
  assign io_commits_info_5_debug_otherPdest_6           = commitInfo[5].debug_otherPdest_6;

  assign io_commits_info_6_walk_v                       = commitInfo[6].walk_v;
  assign io_commits_info_6_commit_v                     = commitInfo[6].commit_v;
  assign io_commits_info_6_commit_w                     = commitInfo[6].commit_w;
  assign io_commits_info_6_realDestSize                 = commitInfo[6].realDestSize;
  assign io_commits_info_6_interrupt_safe               = commitInfo[6].interrupt_safe;
  assign io_commits_info_6_wflags                       = commitInfo[6].wflags;
  assign io_commits_info_6_fflags                       = commitInfo[6].fflags;
  assign io_commits_info_6_vxsat                        = commitInfo[6].vxsat;
  assign io_commits_info_6_isRVC                        = commitInfo[6].isRVC;
  assign io_commits_info_6_isVset                       = commitInfo[6].isVset;
  assign io_commits_info_6_isHls                        = commitInfo[6].isHls;
  assign io_commits_info_6_isVls                        = commitInfo[6].isVls;
  assign io_commits_info_6_vls                          = commitInfo[6].vls;
  assign io_commits_info_6_mmio                         = commitInfo[6].mmio;
  assign io_commits_info_6_commitType                   = commitInfo[6].commitType;
  assign io_commits_info_6_ftqIdx_flag                  = commitInfo[6].ftqIdx_flag;
  assign io_commits_info_6_ftqIdx_value                 = commitInfo[6].ftqIdx_value;
  assign io_commits_info_6_ftqOffset                    = commitInfo[6].ftqOffset;
  assign io_commits_info_6_instrSize                    = commitInfo[6].instrSize;
  assign io_commits_info_6_fpWen                        = commitInfo[6].fpWen;
  assign io_commits_info_6_rfWen                        = commitInfo[6].rfWen;
  assign io_commits_info_6_needFlush                    = commitInfo[6].needFlush;
  assign io_commits_info_6_traceBlockInPipe_itype       = commitInfo[6].traceBlockInPipe_itype;
  assign io_commits_info_6_traceBlockInPipe_iretire     = commitInfo[6].traceBlockInPipe_iretire;
  assign io_commits_info_6_traceBlockInPipe_ilastsize   = commitInfo[6].traceBlockInPipe_ilastsize;
  assign io_commits_info_6_debug_pc                     = commitInfo[6].debug_pc;
  assign io_commits_info_6_debug_instr                  = commitInfo[6].debug_instr;
  assign io_commits_info_6_basicDebug_ldest             = commitInfo[6].basicDebug_ldest;
  assign io_commits_info_6_basicDebug_pdest             = commitInfo[6].basicDebug_pdest;
  assign io_commits_info_6_basicDebug_vd                = commitInfo[6].basicDebug_vd;
  assign io_commits_info_6_basicDebug_fpWen             = commitInfo[6].basicDebug_fpWen;
  assign io_commits_info_6_basicDebug_vecWen            = commitInfo[6].basicDebug_vecWen;
  assign io_commits_info_6_basicDebug_v0Wen             = commitInfo[6].basicDebug_v0Wen;
  assign io_commits_info_6_basicDebug_eliminatedMove    = commitInfo[6].basicDebug_eliminatedMove;
  assign io_commits_info_6_basicDebug_isXSTrap          = commitInfo[6].basicDebug_isXSTrap;
  assign io_commits_info_6_debug_fuType                 = commitInfo[6].debug_fuType;
  assign io_commits_info_6_dirtyFs                      = commitInfo[6].dirtyFs;
  assign io_commits_info_6_dirtyVs                      = commitInfo[6].dirtyVs;
  assign io_commits_info_6_debug_otherPdest_0           = commitInfo[6].debug_otherPdest_0;
  assign io_commits_info_6_debug_otherPdest_1           = commitInfo[6].debug_otherPdest_1;
  assign io_commits_info_6_debug_otherPdest_2           = commitInfo[6].debug_otherPdest_2;
  assign io_commits_info_6_debug_otherPdest_3           = commitInfo[6].debug_otherPdest_3;
  assign io_commits_info_6_debug_otherPdest_4           = commitInfo[6].debug_otherPdest_4;
  assign io_commits_info_6_debug_otherPdest_5           = commitInfo[6].debug_otherPdest_5;
  assign io_commits_info_6_debug_otherPdest_6           = commitInfo[6].debug_otherPdest_6;

  assign io_commits_info_7_walk_v                       = commitInfo[7].walk_v;
  assign io_commits_info_7_commit_v                     = commitInfo[7].commit_v;
  assign io_commits_info_7_commit_w                     = commitInfo[7].commit_w;
  assign io_commits_info_7_realDestSize                 = commitInfo[7].realDestSize;
  assign io_commits_info_7_interrupt_safe               = commitInfo[7].interrupt_safe;
  assign io_commits_info_7_wflags                       = commitInfo[7].wflags;
  assign io_commits_info_7_fflags                       = commitInfo[7].fflags;
  assign io_commits_info_7_vxsat                        = commitInfo[7].vxsat;
  assign io_commits_info_7_isRVC                        = commitInfo[7].isRVC;
  assign io_commits_info_7_isVset                       = commitInfo[7].isVset;
  assign io_commits_info_7_isHls                        = commitInfo[7].isHls;
  assign io_commits_info_7_isVls                        = commitInfo[7].isVls;
  assign io_commits_info_7_vls                          = commitInfo[7].vls;
  assign io_commits_info_7_mmio                         = commitInfo[7].mmio;
  assign io_commits_info_7_commitType                   = commitInfo[7].commitType;
  assign io_commits_info_7_ftqIdx_flag                  = commitInfo[7].ftqIdx_flag;
  assign io_commits_info_7_ftqIdx_value                 = commitInfo[7].ftqIdx_value;
  assign io_commits_info_7_ftqOffset                    = commitInfo[7].ftqOffset;
  assign io_commits_info_7_instrSize                    = commitInfo[7].instrSize;
  assign io_commits_info_7_fpWen                        = commitInfo[7].fpWen;
  assign io_commits_info_7_rfWen                        = commitInfo[7].rfWen;
  assign io_commits_info_7_needFlush                    = commitInfo[7].needFlush;
  assign io_commits_info_7_traceBlockInPipe_itype       = commitInfo[7].traceBlockInPipe_itype;
  assign io_commits_info_7_traceBlockInPipe_iretire     = commitInfo[7].traceBlockInPipe_iretire;
  assign io_commits_info_7_traceBlockInPipe_ilastsize   = commitInfo[7].traceBlockInPipe_ilastsize;
  assign io_commits_info_7_debug_pc                     = commitInfo[7].debug_pc;
  assign io_commits_info_7_debug_instr                  = commitInfo[7].debug_instr;
  assign io_commits_info_7_basicDebug_ldest             = commitInfo[7].basicDebug_ldest;
  assign io_commits_info_7_basicDebug_pdest             = commitInfo[7].basicDebug_pdest;
  assign io_commits_info_7_basicDebug_vd                = commitInfo[7].basicDebug_vd;
  assign io_commits_info_7_basicDebug_fpWen             = commitInfo[7].basicDebug_fpWen;
  assign io_commits_info_7_basicDebug_vecWen            = commitInfo[7].basicDebug_vecWen;
  assign io_commits_info_7_basicDebug_v0Wen             = commitInfo[7].basicDebug_v0Wen;
  assign io_commits_info_7_basicDebug_eliminatedMove    = commitInfo[7].basicDebug_eliminatedMove;
  assign io_commits_info_7_basicDebug_isXSTrap          = commitInfo[7].basicDebug_isXSTrap;
  assign io_commits_info_7_debug_fuType                 = commitInfo[7].debug_fuType;
  assign io_commits_info_7_dirtyFs                      = commitInfo[7].dirtyFs;
  assign io_commits_info_7_dirtyVs                      = commitInfo[7].dirtyVs;
  assign io_commits_info_7_debug_otherPdest_0           = commitInfo[7].debug_otherPdest_0;
  assign io_commits_info_7_debug_otherPdest_1           = commitInfo[7].debug_otherPdest_1;
  assign io_commits_info_7_debug_otherPdest_2           = commitInfo[7].debug_otherPdest_2;
  assign io_commits_info_7_debug_otherPdest_3           = commitInfo[7].debug_otherPdest_3;
  assign io_commits_info_7_debug_otherPdest_4           = commitInfo[7].debug_otherPdest_4;
  assign io_commits_info_7_debug_otherPdest_5           = commitInfo[7].debug_otherPdest_5;
  assign io_commits_info_7_debug_otherPdest_6           = commitInfo[7].debug_otherPdest_6;



  // ==========================================================================
  // §16 RAB（重命名缓冲）接口
  // ==========================================================================
  // io.rabCommits := RegNext(rab.io.commits) —— 整条打一拍，纯粹为了时序/面积。
  always_ff @(posedge clock) begin
    io_rabCommits_REG_isCommit <= rab_io_commits_isCommit;
    io_rabCommits_REG_isWalk   <= rab_io_commits_isWalk;
    io_rabCommits_REG_commitValid_0 <= rab_io_commits_commitValid_0;
    io_rabCommits_REG_commitValid_1 <= rab_io_commits_commitValid_1;
    io_rabCommits_REG_commitValid_2 <= rab_io_commits_commitValid_2;
    io_rabCommits_REG_commitValid_3 <= rab_io_commits_commitValid_3;
    io_rabCommits_REG_commitValid_4 <= rab_io_commits_commitValid_4;
    io_rabCommits_REG_commitValid_5 <= rab_io_commits_commitValid_5;
    io_rabCommits_REG_walkValid_0   <= rab_io_commits_walkValid_0;
    io_rabCommits_REG_walkValid_1   <= rab_io_commits_walkValid_1;
    io_rabCommits_REG_walkValid_2   <= rab_io_commits_walkValid_2;
    io_rabCommits_REG_walkValid_3   <= rab_io_commits_walkValid_3;
    io_rabCommits_REG_walkValid_4   <= rab_io_commits_walkValid_4;
    io_rabCommits_REG_walkValid_5   <= rab_io_commits_walkValid_5;
    for (int i = 0; i < RENAME_W; i++) begin
      // 名字被 fm_pins.tcl 钉死（io_rabCommits_REG_info_<field>_reg[<i>]），不能改
    end
    io_rabCommits_REG_info_fpWen [0] <= rab_io_commits_info_0_fpWen;
    io_rabCommits_REG_info_isMove[0] <= rab_io_commits_info_0_isMove;
    io_rabCommits_REG_info_ldest [0] <= rab_io_commits_info_0_ldest;
    io_rabCommits_REG_info_pdest [0] <= rab_io_commits_info_0_pdest;
    io_rabCommits_REG_info_rfWen [0] <= rab_io_commits_info_0_rfWen;
    io_rabCommits_REG_info_v0Wen [0] <= rab_io_commits_info_0_v0Wen;
    io_rabCommits_REG_info_vecWen[0] <= rab_io_commits_info_0_vecWen;
    io_rabCommits_REG_info_vlWen [0] <= rab_io_commits_info_0_vlWen;
    io_rabCommits_REG_info_fpWen [1] <= rab_io_commits_info_1_fpWen;
    io_rabCommits_REG_info_isMove[1] <= rab_io_commits_info_1_isMove;
    io_rabCommits_REG_info_ldest [1] <= rab_io_commits_info_1_ldest;
    io_rabCommits_REG_info_pdest [1] <= rab_io_commits_info_1_pdest;
    io_rabCommits_REG_info_rfWen [1] <= rab_io_commits_info_1_rfWen;
    io_rabCommits_REG_info_v0Wen [1] <= rab_io_commits_info_1_v0Wen;
    io_rabCommits_REG_info_vecWen[1] <= rab_io_commits_info_1_vecWen;
    io_rabCommits_REG_info_vlWen [1] <= rab_io_commits_info_1_vlWen;
    io_rabCommits_REG_info_fpWen [2] <= rab_io_commits_info_2_fpWen;
    io_rabCommits_REG_info_isMove[2] <= rab_io_commits_info_2_isMove;
    io_rabCommits_REG_info_ldest [2] <= rab_io_commits_info_2_ldest;
    io_rabCommits_REG_info_pdest [2] <= rab_io_commits_info_2_pdest;
    io_rabCommits_REG_info_rfWen [2] <= rab_io_commits_info_2_rfWen;
    io_rabCommits_REG_info_v0Wen [2] <= rab_io_commits_info_2_v0Wen;
    io_rabCommits_REG_info_vecWen[2] <= rab_io_commits_info_2_vecWen;
    io_rabCommits_REG_info_vlWen [2] <= rab_io_commits_info_2_vlWen;
    io_rabCommits_REG_info_fpWen [3] <= rab_io_commits_info_3_fpWen;
    io_rabCommits_REG_info_isMove[3] <= rab_io_commits_info_3_isMove;
    io_rabCommits_REG_info_ldest [3] <= rab_io_commits_info_3_ldest;
    io_rabCommits_REG_info_pdest [3] <= rab_io_commits_info_3_pdest;
    io_rabCommits_REG_info_rfWen [3] <= rab_io_commits_info_3_rfWen;
    io_rabCommits_REG_info_v0Wen [3] <= rab_io_commits_info_3_v0Wen;
    io_rabCommits_REG_info_vecWen[3] <= rab_io_commits_info_3_vecWen;
    io_rabCommits_REG_info_vlWen [3] <= rab_io_commits_info_3_vlWen;
    io_rabCommits_REG_info_fpWen [4] <= rab_io_commits_info_4_fpWen;
    io_rabCommits_REG_info_isMove[4] <= rab_io_commits_info_4_isMove;
    io_rabCommits_REG_info_ldest [4] <= rab_io_commits_info_4_ldest;
    io_rabCommits_REG_info_pdest [4] <= rab_io_commits_info_4_pdest;
    io_rabCommits_REG_info_rfWen [4] <= rab_io_commits_info_4_rfWen;
    io_rabCommits_REG_info_v0Wen [4] <= rab_io_commits_info_4_v0Wen;
    io_rabCommits_REG_info_vecWen[4] <= rab_io_commits_info_4_vecWen;
    io_rabCommits_REG_info_vlWen [4] <= rab_io_commits_info_4_vlWen;
    io_rabCommits_REG_info_fpWen [5] <= rab_io_commits_info_5_fpWen;
    io_rabCommits_REG_info_isMove[5] <= rab_io_commits_info_5_isMove;
    io_rabCommits_REG_info_ldest [5] <= rab_io_commits_info_5_ldest;
    io_rabCommits_REG_info_pdest [5] <= rab_io_commits_info_5_pdest;
    io_rabCommits_REG_info_rfWen [5] <= rab_io_commits_info_5_rfWen;
    io_rabCommits_REG_info_v0Wen [5] <= rab_io_commits_info_5_v0Wen;
    io_rabCommits_REG_info_vecWen[5] <= rab_io_commits_info_5_vecWen;
    io_rabCommits_REG_info_vlWen [5] <= rab_io_commits_info_5_vlWen;
  end

  assign io_rabCommits_isCommit = io_rabCommits_REG_isCommit;
  assign io_rabCommits_isWalk   = io_rabCommits_REG_isWalk;
  assign io_rabCommits_commitValid_0 = io_rabCommits_REG_commitValid_0;
  assign io_rabCommits_commitValid_1 = io_rabCommits_REG_commitValid_1;
  assign io_rabCommits_commitValid_2 = io_rabCommits_REG_commitValid_2;
  assign io_rabCommits_commitValid_3 = io_rabCommits_REG_commitValid_3;
  assign io_rabCommits_commitValid_4 = io_rabCommits_REG_commitValid_4;
  assign io_rabCommits_commitValid_5 = io_rabCommits_REG_commitValid_5;
  assign io_rabCommits_walkValid_0   = io_rabCommits_REG_walkValid_0;
  assign io_rabCommits_walkValid_1   = io_rabCommits_REG_walkValid_1;
  assign io_rabCommits_walkValid_2   = io_rabCommits_REG_walkValid_2;
  assign io_rabCommits_walkValid_3   = io_rabCommits_REG_walkValid_3;
  assign io_rabCommits_walkValid_4   = io_rabCommits_REG_walkValid_4;
  assign io_rabCommits_walkValid_5   = io_rabCommits_REG_walkValid_5;
  assign io_rabCommits_info_0_fpWen  = io_rabCommits_REG_info_fpWen[0];
  assign io_rabCommits_info_0_isMove = io_rabCommits_REG_info_isMove[0];
  assign io_rabCommits_info_0_ldest  = io_rabCommits_REG_info_ldest[0];
  assign io_rabCommits_info_0_pdest  = io_rabCommits_REG_info_pdest[0];
  assign io_rabCommits_info_0_rfWen  = io_rabCommits_REG_info_rfWen[0];
  assign io_rabCommits_info_0_v0Wen  = io_rabCommits_REG_info_v0Wen[0];
  assign io_rabCommits_info_0_vecWen = io_rabCommits_REG_info_vecWen[0];
  assign io_rabCommits_info_0_vlWen  = io_rabCommits_REG_info_vlWen[0];
  assign io_rabCommits_info_1_fpWen  = io_rabCommits_REG_info_fpWen[1];
  assign io_rabCommits_info_1_isMove = io_rabCommits_REG_info_isMove[1];
  assign io_rabCommits_info_1_ldest  = io_rabCommits_REG_info_ldest[1];
  assign io_rabCommits_info_1_pdest  = io_rabCommits_REG_info_pdest[1];
  assign io_rabCommits_info_1_rfWen  = io_rabCommits_REG_info_rfWen[1];
  assign io_rabCommits_info_1_v0Wen  = io_rabCommits_REG_info_v0Wen[1];
  assign io_rabCommits_info_1_vecWen = io_rabCommits_REG_info_vecWen[1];
  assign io_rabCommits_info_1_vlWen  = io_rabCommits_REG_info_vlWen[1];
  assign io_rabCommits_info_2_fpWen  = io_rabCommits_REG_info_fpWen[2];
  assign io_rabCommits_info_2_isMove = io_rabCommits_REG_info_isMove[2];
  assign io_rabCommits_info_2_ldest  = io_rabCommits_REG_info_ldest[2];
  assign io_rabCommits_info_2_pdest  = io_rabCommits_REG_info_pdest[2];
  assign io_rabCommits_info_2_rfWen  = io_rabCommits_REG_info_rfWen[2];
  assign io_rabCommits_info_2_v0Wen  = io_rabCommits_REG_info_v0Wen[2];
  assign io_rabCommits_info_2_vecWen = io_rabCommits_REG_info_vecWen[2];
  assign io_rabCommits_info_2_vlWen  = io_rabCommits_REG_info_vlWen[2];
  assign io_rabCommits_info_3_fpWen  = io_rabCommits_REG_info_fpWen[3];
  assign io_rabCommits_info_3_isMove = io_rabCommits_REG_info_isMove[3];
  assign io_rabCommits_info_3_ldest  = io_rabCommits_REG_info_ldest[3];
  assign io_rabCommits_info_3_pdest  = io_rabCommits_REG_info_pdest[3];
  assign io_rabCommits_info_3_rfWen  = io_rabCommits_REG_info_rfWen[3];
  assign io_rabCommits_info_3_v0Wen  = io_rabCommits_REG_info_v0Wen[3];
  assign io_rabCommits_info_3_vecWen = io_rabCommits_REG_info_vecWen[3];
  assign io_rabCommits_info_3_vlWen  = io_rabCommits_REG_info_vlWen[3];
  assign io_rabCommits_info_4_fpWen  = io_rabCommits_REG_info_fpWen[4];
  assign io_rabCommits_info_4_isMove = io_rabCommits_REG_info_isMove[4];
  assign io_rabCommits_info_4_ldest  = io_rabCommits_REG_info_ldest[4];
  assign io_rabCommits_info_4_pdest  = io_rabCommits_REG_info_pdest[4];
  assign io_rabCommits_info_4_rfWen  = io_rabCommits_REG_info_rfWen[4];
  assign io_rabCommits_info_4_v0Wen  = io_rabCommits_REG_info_v0Wen[4];
  assign io_rabCommits_info_4_vecWen = io_rabCommits_REG_info_vecWen[4];
  assign io_rabCommits_info_4_vlWen  = io_rabCommits_REG_info_vlWen[4];
  assign io_rabCommits_info_5_fpWen  = io_rabCommits_REG_info_fpWen[5];
  assign io_rabCommits_info_5_isMove = io_rabCommits_REG_info_isMove[5];
  assign io_rabCommits_info_5_ldest  = io_rabCommits_REG_info_ldest[5];
  assign io_rabCommits_info_5_pdest  = io_rabCommits_REG_info_pdest[5];
  assign io_rabCommits_info_5_rfWen  = io_rabCommits_REG_info_rfWen[5];
  assign io_rabCommits_info_5_v0Wen  = io_rabCommits_REG_info_v0Wen[5];
  assign io_rabCommits_info_5_vecWen = io_rabCommits_REG_info_vecWen[5];
  assign io_rabCommits_info_5_vlWen  = io_rabCommits_REG_info_vlWen[5];

  // ---- 送给 rab / vtypeBuffer 的提交/走回规模 ----
  // realDestSize 是"这条 RobEntry 里有几个要写寄存器的 uop"；RAB 要按这个数出队。
  // ★PriorityMuxDefault(cond.reverse, seq.reverse, 0)★ —— 从**高位往低位**找第一个
  // 满足的，也就是取"最后一个提交/走回有效"的那个前缀和；一个都不满足取 0。
  logic [UOPNUM_W-1:0] realDestSizeSeq [COMMIT_W];
  logic [UOPNUM_W-1:0] walkDestSizeSeq [COMMIT_W];
  logic [9:0]          commitSizeSumSeq[COMMIT_W];
  logic [9:0]          walkSizeSumSeq  [COMMIT_W];
  logic                commitSizeSumCond[COMMIT_W];
  logic                walkSizeSumCond  [COMMIT_W];
  logic [9:0]          commitSizeSum, walkSizeSum;

  always_comb begin
    for (int b = 0; b < COMMIT_W; b++) begin
      realDestSizeSeq[b] = hasCommittedVec[b]   ? {UOPNUM_W{1'b0}}
                                                : robDeqGroup_realDestSize[b];
      walkDestSizeSeq[b] = donotNeedWalkVec[b]  ? {UOPNUM_W{1'b0}}
                                                : robDeqGroup_realDestSize[b];
    end
    for (int i = 0; i < COMMIT_W; i++) begin
      commitSizeSumSeq[i] = 10'h0;
      walkSizeSumSeq[i]   = 10'h0;
      for (int b = 0; b <= i; b++) begin
        commitSizeSumSeq[i] = commitSizeSumSeq[i] + 10'(realDestSizeSeq[b]);
        walkSizeSumSeq[i]   = walkSizeSumSeq[i]   + 10'(walkDestSizeSeq[b]);
      end
      commitSizeSumCond[i] = (commitValidThisLine[i] | hasCommittedVec[i])
                           & io_commits_isCommit;
      walkSizeSumCond[i]   = (shouldWalkVec[i] | donotNeedWalkVec[i])
                           & io_commits_isWalk;
    end
    commitSizeSum = 10'h0;
    walkSizeSum   = 10'h0;
    for (int i = 0; i < COMMIT_W; i++) begin
      if (commitSizeSumCond[i]) commitSizeSum = commitSizeSumSeq[i];
      if (walkSizeSumCond[i])   walkSizeSum   = walkSizeSumSeq[i];
    end
  end

  assign rab_io_fromRob_commitSize = deqVlsExceptionNeedCommit
      ? {1'b0, deqVlsExceptionCommitSize} : commitSizeSum[PTR_W-1:0];
  assign rab_io_fromRob_walkSize   = walkSizeSum[PTR_W-1:0];

  // vtypeBuffer 只数 vset 的条数
  logic [3:0] commitVTypeCnt, walkVTypeCnt;
  always_comb begin
    commitVTypeCnt = 4'h0;
    walkVTypeCnt   = 4'h0;
    for (int i = 0; i < COMMIT_W; i++) begin
      commitVTypeCnt = commitVTypeCnt
        + 4'(io_commits_isCommit & commitValidOut[i] & commitInfo[i].isVset);
      walkVTypeCnt = walkVTypeCnt
        + 4'(io_commits_isWalk & shouldWalkVec[i] & walkInfo[i].isVset);
    end
  end
  assign vtypeBuffer_io_fromRob_commitSize = {2'h0, commitVTypeCnt};
  assign vtypeBuffer_io_fromRob_walkSize   = {2'h0, walkVTypeCnt};

  // 快照入队：有一路带 snapshot 且本拍能进队
  assign snptEnq = io_enq_canAccept & (
        (enqValid[0] & io_enq_req_0_bits_snapshot)
      | (enqValid[1] & io_enq_req_1_bits_snapshot)
      | (enqValid[2] & io_enq_req_2_bits_snapshot)
      | (enqValid[3] & io_enq_req_3_bits_snapshot)
      | (enqValid[4] & io_enq_req_4_bits_snapshot)
      | (enqValid[5] & io_enq_req_5_bits_snapshot));

  // RAB 要知道"向量 load 出异常了"，好把那几对寄存器一起提交掉
  always_ff @(posedge clock)
    rab_io_fromRob_vecLoadExcp_valid_REG <= exceptionGen_io_state_valid
                                          & exceptionGen_io_state_bits_isVecLoad;
  assign rab_io_fromRob_vecLoadExcp_valid_REGOut = rab_io_fromRob_vecLoadExcp_valid_REG;

  assign enqPtrGenModule_io_allowEnqueue =
      allowEnqueue & rab_io_canEnq & ~io_fromVecExcpMod_busy;

  // 提交卡住计数器的输入：这一拍一条都没提交，且队头不是 mmio
  // （mmio 本来就慢，不算卡住）。wfiResume 在本配置下为真，`wfiResume || !hasWFI`
  // 被常数折掉了 —— golden 里这一项整个不见了，不是漏写。
  logic deqIsMmio;
  always_comb begin
    // ★越界回绕到条目 0★（见 §9 头上的「越界读」总说明）：
    // golden 是 `_GEN_2631[deqPtr] & _GEN_2641[deqPtr]`，两张表的 160..255 格
    // 填的都是条目 0。
    deqIsMmio = robEntries_valid[0] & robEntries_mmio[0];
    for (int i = 0; i < ROB_SIZE; i++)
      if (deqPtrValue[0] == PTR_W'(i))
        deqIsMmio = robEntries_valid[i] & robEntries_mmio[i];
  end
  assign commitStuckCounter_io_stuck =
      (~(commitValidOut[0] | commitValidOut[1] | commitValidOut[2] | commitValidOut[3]
       | commitValidOut[4] | commitValidOut[5] | commitValidOut[6] | commitValidOut[7])
       | ~io_commits_isCommit) & ~deqIsMmio;
  // io_error_0 也和 perf 一样打两拍（见 §23 的 io_error_0_REG/_REG_1）
  assign io_error_0 = io_error_0_REG_1;



  // ==========================================================================
  // §17 送给 exceptionGen 的三类折算量
  // ==========================================================================
  // ★io_writeback_<i> 各自只有一部分 exceptionVec 位★（7 号只有 7 位、
  //   13/14 号只有 1 位、15/16/17 号一位没有、18..24 号才是全 24 位）。
  //   照 24 位写会引用到不存在的端口。索引集见 PORT 段。
  // ★exceptionGen 的 io_wb 下标 != io_writeback 下标★：
  //   io_wb_k 对应 io_writeback_{7,13,14,15,16,17,18,19,20,21,22,23,24}[k]，
  //   一共 13 路。其中 io_wb_1/2 的 hasException 只有一位，golden 直接把那根
  //   端口连过去（不经过核）；io_wb_3/4/5 那三路一位异常都没有，也不经过核。
  //   所以核只需要产生下面这 8 根 —— 写成 0..9 会凭空造出
  //   exceptionGen_io_wb_1..5 这种**隐式线**（VCS 默认 wire，不报错），
  //   同时漏掉 io_wb_10/11/12。
  assign exceptionGen_io_wb_0_bits_hasException =   // io_writeback_7
      |{io_writeback_7_bits_exceptionVec_22, io_writeback_7_bits_exceptionVec_11, io_writeback_7_bits_exceptionVec_10, io_writeback_7_bits_exceptionVec_9, io_writeback_7_bits_exceptionVec_8, io_writeback_7_bits_exceptionVec_3, io_writeback_7_bits_exceptionVec_2};
  assign exceptionGen_io_wb_6_bits_hasException =   // io_writeback_18
      |{io_writeback_18_bits_exceptionVec_23, io_writeback_18_bits_exceptionVec_22, io_writeback_18_bits_exceptionVec_21, io_writeback_18_bits_exceptionVec_20, io_writeback_18_bits_exceptionVec_19, io_writeback_18_bits_exceptionVec_18, io_writeback_18_bits_exceptionVec_17, io_writeback_18_bits_exceptionVec_16, io_writeback_18_bits_exceptionVec_15, io_writeback_18_bits_exceptionVec_14, io_writeback_18_bits_exceptionVec_13, io_writeback_18_bits_exceptionVec_12, io_writeback_18_bits_exceptionVec_11, io_writeback_18_bits_exceptionVec_10, io_writeback_18_bits_exceptionVec_9, io_writeback_18_bits_exceptionVec_8, io_writeback_18_bits_exceptionVec_7, io_writeback_18_bits_exceptionVec_6, io_writeback_18_bits_exceptionVec_5, io_writeback_18_bits_exceptionVec_4, io_writeback_18_bits_exceptionVec_3, io_writeback_18_bits_exceptionVec_2, io_writeback_18_bits_exceptionVec_1, io_writeback_18_bits_exceptionVec_0};
  assign exceptionGen_io_wb_7_bits_hasException =   // io_writeback_19
      |{io_writeback_19_bits_exceptionVec_23, io_writeback_19_bits_exceptionVec_22, io_writeback_19_bits_exceptionVec_21, io_writeback_19_bits_exceptionVec_20, io_writeback_19_bits_exceptionVec_19, io_writeback_19_bits_exceptionVec_18, io_writeback_19_bits_exceptionVec_17, io_writeback_19_bits_exceptionVec_16, io_writeback_19_bits_exceptionVec_15, io_writeback_19_bits_exceptionVec_14, io_writeback_19_bits_exceptionVec_13, io_writeback_19_bits_exceptionVec_12, io_writeback_19_bits_exceptionVec_11, io_writeback_19_bits_exceptionVec_10, io_writeback_19_bits_exceptionVec_9, io_writeback_19_bits_exceptionVec_8, io_writeback_19_bits_exceptionVec_7, io_writeback_19_bits_exceptionVec_6, io_writeback_19_bits_exceptionVec_5, io_writeback_19_bits_exceptionVec_4, io_writeback_19_bits_exceptionVec_3, io_writeback_19_bits_exceptionVec_2, io_writeback_19_bits_exceptionVec_1, io_writeback_19_bits_exceptionVec_0};
  assign exceptionGen_io_wb_8_bits_hasException =   // io_writeback_20
      |{io_writeback_20_bits_exceptionVec_23, io_writeback_20_bits_exceptionVec_22, io_writeback_20_bits_exceptionVec_21, io_writeback_20_bits_exceptionVec_20, io_writeback_20_bits_exceptionVec_19, io_writeback_20_bits_exceptionVec_18, io_writeback_20_bits_exceptionVec_17, io_writeback_20_bits_exceptionVec_16, io_writeback_20_bits_exceptionVec_15, io_writeback_20_bits_exceptionVec_14, io_writeback_20_bits_exceptionVec_13, io_writeback_20_bits_exceptionVec_12, io_writeback_20_bits_exceptionVec_11, io_writeback_20_bits_exceptionVec_10, io_writeback_20_bits_exceptionVec_9, io_writeback_20_bits_exceptionVec_8, io_writeback_20_bits_exceptionVec_7, io_writeback_20_bits_exceptionVec_6, io_writeback_20_bits_exceptionVec_5, io_writeback_20_bits_exceptionVec_4, io_writeback_20_bits_exceptionVec_3, io_writeback_20_bits_exceptionVec_2, io_writeback_20_bits_exceptionVec_1, io_writeback_20_bits_exceptionVec_0};
  assign exceptionGen_io_wb_9_bits_hasException =   // io_writeback_21
      |{io_writeback_21_bits_exceptionVec_23, io_writeback_21_bits_exceptionVec_22, io_writeback_21_bits_exceptionVec_21, io_writeback_21_bits_exceptionVec_20, io_writeback_21_bits_exceptionVec_19, io_writeback_21_bits_exceptionVec_18, io_writeback_21_bits_exceptionVec_17, io_writeback_21_bits_exceptionVec_16, io_writeback_21_bits_exceptionVec_15, io_writeback_21_bits_exceptionVec_14, io_writeback_21_bits_exceptionVec_13, io_writeback_21_bits_exceptionVec_12, io_writeback_21_bits_exceptionVec_11, io_writeback_21_bits_exceptionVec_10, io_writeback_21_bits_exceptionVec_9, io_writeback_21_bits_exceptionVec_8, io_writeback_21_bits_exceptionVec_7, io_writeback_21_bits_exceptionVec_6, io_writeback_21_bits_exceptionVec_5, io_writeback_21_bits_exceptionVec_4, io_writeback_21_bits_exceptionVec_3, io_writeback_21_bits_exceptionVec_2, io_writeback_21_bits_exceptionVec_1, io_writeback_21_bits_exceptionVec_0};
  assign exceptionGen_io_wb_10_bits_hasException =   // io_writeback_22
      |{io_writeback_22_bits_exceptionVec_23, io_writeback_22_bits_exceptionVec_22, io_writeback_22_bits_exceptionVec_21, io_writeback_22_bits_exceptionVec_20, io_writeback_22_bits_exceptionVec_19, io_writeback_22_bits_exceptionVec_18, io_writeback_22_bits_exceptionVec_17, io_writeback_22_bits_exceptionVec_16, io_writeback_22_bits_exceptionVec_15, io_writeback_22_bits_exceptionVec_14, io_writeback_22_bits_exceptionVec_13, io_writeback_22_bits_exceptionVec_12, io_writeback_22_bits_exceptionVec_11, io_writeback_22_bits_exceptionVec_10, io_writeback_22_bits_exceptionVec_9, io_writeback_22_bits_exceptionVec_8, io_writeback_22_bits_exceptionVec_7, io_writeback_22_bits_exceptionVec_6, io_writeback_22_bits_exceptionVec_5, io_writeback_22_bits_exceptionVec_4, io_writeback_22_bits_exceptionVec_3, io_writeback_22_bits_exceptionVec_2, io_writeback_22_bits_exceptionVec_1, io_writeback_22_bits_exceptionVec_0};
  assign exceptionGen_io_wb_11_bits_hasException =   // io_writeback_23
      |{io_writeback_23_bits_exceptionVec_23, io_writeback_23_bits_exceptionVec_22, io_writeback_23_bits_exceptionVec_21, io_writeback_23_bits_exceptionVec_20, io_writeback_23_bits_exceptionVec_19, io_writeback_23_bits_exceptionVec_18, io_writeback_23_bits_exceptionVec_17, io_writeback_23_bits_exceptionVec_16, io_writeback_23_bits_exceptionVec_15, io_writeback_23_bits_exceptionVec_14, io_writeback_23_bits_exceptionVec_13, io_writeback_23_bits_exceptionVec_12, io_writeback_23_bits_exceptionVec_11, io_writeback_23_bits_exceptionVec_10, io_writeback_23_bits_exceptionVec_9, io_writeback_23_bits_exceptionVec_8, io_writeback_23_bits_exceptionVec_7, io_writeback_23_bits_exceptionVec_6, io_writeback_23_bits_exceptionVec_5, io_writeback_23_bits_exceptionVec_4, io_writeback_23_bits_exceptionVec_3, io_writeback_23_bits_exceptionVec_2, io_writeback_23_bits_exceptionVec_1, io_writeback_23_bits_exceptionVec_0};
  assign exceptionGen_io_wb_12_bits_hasException =   // io_writeback_24
      |{io_writeback_24_bits_exceptionVec_23, io_writeback_24_bits_exceptionVec_22, io_writeback_24_bits_exceptionVec_21, io_writeback_24_bits_exceptionVec_20, io_writeback_24_bits_exceptionVec_19, io_writeback_24_bits_exceptionVec_18, io_writeback_24_bits_exceptionVec_17, io_writeback_24_bits_exceptionVec_16, io_writeback_24_bits_exceptionVec_15, io_writeback_24_bits_exceptionVec_14, io_writeback_24_bits_exceptionVec_13, io_writeback_24_bits_exceptionVec_12, io_writeback_24_bits_exceptionVec_11, io_writeback_24_bits_exceptionVec_10, io_writeback_24_bits_exceptionVec_9, io_writeback_24_bits_exceptionVec_8, io_writeback_24_bits_exceptionVec_7, io_writeback_24_bits_exceptionVec_6, io_writeback_24_bits_exceptionVec_5, io_writeback_24_bits_exceptionVec_4, io_writeback_24_bits_exceptionVec_3, io_writeback_24_bits_exceptionVec_2, io_writeback_24_bits_exceptionVec_1, io_writeback_24_bits_exceptionVec_0};

  // 11/12 号（= io_writeback_23/24，向量访存）还要给 vstart：
  // vstartEn = 有异常 或 触发器进 debug mode
  assign exceptionGen_io_wb_11_bits_vstartEn =
      exceptionGen_io_wb_11_bits_hasException | (io_writeback_23_bits_trigger == TA_DMODE);
  assign exceptionGen_io_wb_12_bits_vstartEn =
      exceptionGen_io_wb_12_bits_hasException | (io_writeback_24_bits_trigger == TA_DMODE);
  assign exceptionGen_io_wb_11_bits_vstart = {57'h0, io_writeback_23_bits_vls_vpu_vstart};
  assign exceptionGen_io_wb_12_bits_vstart = {57'h0, io_writeback_24_bits_vls_vpu_vstart};

  // ==========================================================================
  // §18 WFI
  // ==========================================================================
  // 遇到 wfi 指令就挂起提交，等 CSR 说可以恢复、或者被冲刷、或者 2^20 拍超时。
  logic enqIsWFI [RENAME_W];
  logic wfi_timeout, wfiSafe, setWFI, clearWFI;

  always_comb begin
    // isWFI = fuType==csr && fuOpType==CSROpType.wfi；再排除本身带前端异常
    // 和触发器要求进 debug mode 的情况（那两种要走异常，不是挂起）。
    enqIsWFI[0] = (io_enq_req_0_bits_fuType == (FUTYPE_W'(1) << FU_CSR))
                & (io_enq_req_0_bits_fuOpType == 9'h20)
                & ~(|{io_enq_req_0_bits_exceptionVec_22, io_enq_req_0_bits_exceptionVec_20,
                      io_enq_req_0_bits_exceptionVec_12, io_enq_req_0_bits_exceptionVec_3,
                      io_enq_req_0_bits_exceptionVec_2,  io_enq_req_0_bits_exceptionVec_1,
                      io_enq_req_0_bits_exceptionVec_0})
                & (io_enq_req_0_bits_trigger != TA_DMODE);
    enqIsWFI[1] = (io_enq_req_1_bits_fuType == (FUTYPE_W'(1) << FU_CSR))
                & (io_enq_req_1_bits_fuOpType == 9'h20)
                & ~(|{io_enq_req_1_bits_exceptionVec_22, io_enq_req_1_bits_exceptionVec_20,
                      io_enq_req_1_bits_exceptionVec_12, io_enq_req_1_bits_exceptionVec_3,
                      io_enq_req_1_bits_exceptionVec_2,  io_enq_req_1_bits_exceptionVec_1,
                      io_enq_req_1_bits_exceptionVec_0})
                & (io_enq_req_1_bits_trigger != TA_DMODE);
    enqIsWFI[2] = (io_enq_req_2_bits_fuType == (FUTYPE_W'(1) << FU_CSR))
                & (io_enq_req_2_bits_fuOpType == 9'h20)
                & ~(|{io_enq_req_2_bits_exceptionVec_22, io_enq_req_2_bits_exceptionVec_20,
                      io_enq_req_2_bits_exceptionVec_12, io_enq_req_2_bits_exceptionVec_3,
                      io_enq_req_2_bits_exceptionVec_2,  io_enq_req_2_bits_exceptionVec_1,
                      io_enq_req_2_bits_exceptionVec_0})
                & (io_enq_req_2_bits_trigger != TA_DMODE);
    enqIsWFI[3] = (io_enq_req_3_bits_fuType == (FUTYPE_W'(1) << FU_CSR))
                & (io_enq_req_3_bits_fuOpType == 9'h20)
                & ~(|{io_enq_req_3_bits_exceptionVec_22, io_enq_req_3_bits_exceptionVec_20,
                      io_enq_req_3_bits_exceptionVec_12, io_enq_req_3_bits_exceptionVec_3,
                      io_enq_req_3_bits_exceptionVec_2,  io_enq_req_3_bits_exceptionVec_1,
                      io_enq_req_3_bits_exceptionVec_0})
                & (io_enq_req_3_bits_trigger != TA_DMODE);
    enqIsWFI[4] = (io_enq_req_4_bits_fuType == (FUTYPE_W'(1) << FU_CSR))
                & (io_enq_req_4_bits_fuOpType == 9'h20)
                & ~(|{io_enq_req_4_bits_exceptionVec_22, io_enq_req_4_bits_exceptionVec_20,
                      io_enq_req_4_bits_exceptionVec_12, io_enq_req_4_bits_exceptionVec_3,
                      io_enq_req_4_bits_exceptionVec_2,  io_enq_req_4_bits_exceptionVec_1,
                      io_enq_req_4_bits_exceptionVec_0})
                & (io_enq_req_4_bits_trigger != TA_DMODE);
    enqIsWFI[5] = (io_enq_req_5_bits_fuType == (FUTYPE_W'(1) << FU_CSR))
                & (io_enq_req_5_bits_fuOpType == 9'h20)
                & ~(|{io_enq_req_5_bits_exceptionVec_22, io_enq_req_5_bits_exceptionVec_20,
                      io_enq_req_5_bits_exceptionVec_12, io_enq_req_5_bits_exceptionVec_3,
                      io_enq_req_5_bits_exceptionVec_2,  io_enq_req_5_bits_exceptionVec_1,
                      io_enq_req_5_bits_exceptionVec_0})
                & (io_enq_req_5_bits_trigger != TA_DMODE);
    setWFI = 1'b0;
    for (int j = 0; j < RENAME_W; j++) setWFI = setWFI | (canEnqueue[j] & enqIsWFI[j]);
  end

  assign wfi_timeout = &wfi_cycles;
  assign wfiSafe     = io_wfi_safeFromMem & io_wfi_safeFromFrontend;
  // REG_1/REG_2 = io_csr_wfiEvent 打两拍
  assign clearWFI   = REG_2 | io_flushOut_valid | wfi_timeout;

  // 优先级（Scala 里后写的赢）：!wfi_enable > 入队置位 > 恢复/超时清零 > 保持
  always_ff @(posedge clock or posedge reset) begin
    if (reset) hasWFI <= 1'b0;
    else       hasWFI <= io_wfi_enable & (setWFI | (~clearWFI & hasWFI));
  end
  always_ff @(posedge clock) begin
    REG   <= hasWFI;            // RegNext(hasWFI)，只用来判"刚离开 WFI"
    REG_1 <= io_csr_wfiEvent;
    REG_2 <= REG_1;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset)              wfi_cycles <= 20'h0;
    else if (hasWFI)        wfi_cycles <= 20'(wfi_cycles + 20'h1);
    else if (~hasWFI & REG) wfi_cycles <= 20'h0;
  end

  assign io_wfi_wfiReq = hasWFI;
  assign io_cpu_halt   = hasWFI & wfiSafe;


  // ---- fflags / vxsat 的读口 ----
  // ★这两个读的是**条目存储**（robEntries）按 deqPtr 直接读，不是 robDeqGroup★：
  //   robDeqGroup 是打过一拍的，而 CSR 要的是这一拍提交那条的值。
  //   下标是 8 位 / 深度 160 —— 正是 FMR_ELAB-147 的形状，所以走循环+比较。
  // ★越界回绕到条目 0★（见 §21 头上的「越界读」总说明）：deqPtr 是 8 位、深度
  //   只有 160，golden 的查找表 _GEN_2640（fflags）/ _GEN_2643（vxsat）
  //   160..255 这 96 格填的都是**条目 0**，所以「没命中」时的默认值不是 0，
  //   是条目 0 的值。原先这两行写的是 0。
  logic [FFLAGS_W-1:0] fflagsDataRead [COMMIT_W];
  logic                vxsatDataRead  [COMMIT_W];
  always_comb begin
    for (int i = 0; i < COMMIT_W; i++) begin
      fflagsDataRead[i] = robEntries_fflags[0];
      vxsatDataRead[i]  = robEntries_vxsat[0];
      for (int k = 0; k < ROB_SIZE; k++)
        if (deqPtrValue[i] == PTR_W'(k)) begin
          fflagsDataRead[i] = robEntries_fflags[k];
          vxsatDataRead[i]  = robEntries_vxsat[k];
        end
    end
  end

  // ==========================================================================
  // §19 CSR / LSQ / 队头杂项
  // ==========================================================================
  logic                fflagsValid, vxsatValid, dirty_fs, dirty_vs, resetVstart;
  logic [FFLAGS_W-1:0] fflagsBits;
  logic                vxsatBits;

  always_comb begin
    fflagsValid = 1'b0;
    fflagsBits  = {FFLAGS_W{1'b0}};
    vxsatBits   = 1'b0;
    dirty_fs    = 1'b0;
    dirty_vs    = 1'b0;
    for (int i = 0; i < COMMIT_W; i++) begin
      fflagsValid = fflagsValid | (commitValidOut[i] & commitInfo[i].wflags);
      // fflagsDataRead(i) 取的是**条目存储**里那一条的 fflags（按 deqPtr 直接读），
      // 不是 robDeqGroup 里那一份 —— 两者差一拍。
      fflagsBits  = fflagsBits
                  | ({FFLAGS_W{commitValidOut[i] & commitInfo[i].wflags}}
                     & fflagsDataRead[i]);
      vxsatBits   = vxsatBits | (commitValidOut[i] & vxsatDataRead[i]);
      dirty_fs    = dirty_fs  | (commitValidOut[i] & commitInfo[i].dirtyFs);
      dirty_vs    = dirty_vs  | (commitValidOut[i] & commitInfo[i].dirtyVs);
    end
    fflagsValid = fflagsValid & io_commits_isCommit;
    dirty_fs    = dirty_fs    & io_commits_isCommit;
    dirty_vs    = dirty_vs    & io_commits_isCommit;
    vxsatValid  = vxsatBits   & io_commits_isCommit;
  end

  assign resetVstart = dirty_vs & ~io_vstartIsZero;

  // fflags / vxsat 用的是 RegNextWithEnable：valid 打一拍，bits 只在 valid 时更新
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      io_csr_fflags_next_valid_last_REG <= 1'b0;
      io_csr_vxsat_next_valid_last_REG  <= 1'b0;
      io_csr_dirty_fs_last_REG          <= 1'b0;
      io_csr_dirty_vs_last_REG          <= 1'b0;
    end else begin
      io_csr_fflags_next_valid_last_REG <= fflagsValid;
      io_csr_vxsat_next_valid_last_REG  <= vxsatValid;
      io_csr_dirty_fs_last_REG          <= dirty_fs;
      io_csr_dirty_vs_last_REG          <= dirty_vs;
    end
  end
  always_ff @(posedge clock) begin
    if (fflagsValid) io_csr_fflags_next_bits_r <= fflagsBits;
    if (vxsatValid)  io_csr_vxsat_next_bits_r  <= vxsatBits;
    io_csr_vstart_valid_REG <= (exceptionHappen & deqHasException)
                             ? exceptionGen_io_state_bits_vstartEn : resetVstart;
    io_csr_vstart_bits_REG  <= (exceptionHappen & deqHasException)
                             ? exceptionGen_io_state_bits_vstart : 64'h0;
  end

  assign io_csr_fflags_valid = io_csr_fflags_next_valid_last_REG;
  assign io_csr_fflags_bits  = io_csr_fflags_next_bits_r;
  assign io_csr_vxsat_valid  = io_csr_vxsat_next_valid_last_REG;
  assign io_csr_vxsat_bits   = io_csr_vxsat_next_bits_r;
  assign io_csr_dirty_fs     = io_csr_dirty_fs_last_REG;
  assign io_csr_dirty_vs     = io_csr_dirty_vs_last_REG;
  assign io_csr_vstart_valid = io_csr_vstart_valid_REG;
  assign io_csr_vstart_bits  = io_csr_vstart_bits_REG;

  // ---- LSQ ----
  // ★lcommit / pendingld / pendingVst / commit / pendingPtrNext 在 golden 里没有端口★
  //   （下游没人用，firtool 把整条输出消了）。只剩下面这五根。
  logic [3:0] stCommitCnt;
  always_comb begin
    stCommitCnt = 4'h0;
    for (int i = 0; i < COMMIT_W; i++) begin
      automatic logic isStore;
      automatic logic entryVls;
      // ★越界回绕到条目 0★（见 §21 头上的「越界读」总说明）：golden 的查找表
      //   _GEN_11733（vls）160..255 格填的是**条目 0**，不是 0。原先这里写 0。
      entryVls = robEntries_vls[0];
      for (int k = 0; k < ROB_SIZE; k++)
        if (deqPtrValue[i] == PTR_W'(k)) entryVls = robEntries_vls[k];
      isStore = commitValidOut[i] & (commitInfo[i].commitType == CT_STORE) & ~entryVls;
      stCommitCnt = stCommitCnt + 4'(isStore);
    end
  end

  always_ff @(posedge clock) begin
    io_lsq_scommit_REG      <= io_commits_isCommit ? stCommitCnt : 4'h0;
    io_lsq_pendingMMIOld_REG <= io_commits_isCommit
                              & (commitInfo[0].commitType == CT_LOAD)
                              & deqPtrEntryValid & rawInfo[0].mmio;
    io_lsq_pendingst_REG    <= io_commits_isCommit
                             & (commitInfo[0].commitType == CT_STORE) & deqPtrEntryValid;
    io_lsq_pendingPtr_REG_flag  <= deqPtrFlag[0];
    io_lsq_pendingPtr_REG_value <= deqPtrValue[0];
  end
  assign io_lsq_scommit        = io_lsq_scommit_REG;
  assign io_lsq_pendingMMIOld  = io_lsq_pendingMMIOld_REG;
  assign io_lsq_pendingst      = io_lsq_pendingst_REG;
  assign io_lsq_pendingPtr_flag  = io_lsq_pendingPtr_REG_flag;
  assign io_lsq_pendingPtr_value = io_lsq_pendingPtr_REG_value;

  // ---- 队头指针与"队头没就绪" ----
  assign io_robDeqPtr_flag  = deqPtrFlag[0];
  assign io_robDeqPtr_value = deqPtrValue[0];
  // ★按 bank 低位直接选 robDeqGroup★，不是取 rawInfo[0]（两者同值，但 golden
  //   在这里生成的是独立的一份选择逻辑）。
  logic headCommitV, headCommitW;
  always_comb begin
    headCommitV = 1'b0;
    headCommitW = 1'b0;
    for (int b = 0; b < BANK_N; b++)
      if (deqBankIdx[0] == BANK_ADDR_W'(b)) begin
        headCommitV = robDeqGroup_commit_v[b];
        headCommitW = robDeqGroup_commit_w[b];
      end
  end
  assign io_headNotReady = headCommitV & ~headCommitW;

  // ---- 提交出来的指令条数（送 CSR 的 perfinfo）----
  logic [9:0] trueCommitCnt;
  logic [3:0] fuseCommitCnt;
  logic       isCommitReg;
  always_comb begin
    trueCommitCnt = 10'h0;
    for (int i = 0; i < COMMIT_W; i++)
      trueCommitCnt = trueCommitCnt
        + (commitValidOut[i] ? 10'(commitInfo[i].instrSize) : 10'h0);
    fuseCommitCnt = 4'h0;
    fuseCommitCnt = fuseCommitCnt + 4'(fuseCommitCnt_r) + 4'(fuseCommitCnt_r_1)
                  + 4'(fuseCommitCnt_r_2) + 4'(fuseCommitCnt_r_3)
                  + 4'(fuseCommitCnt_r_4) + 4'(fuseCommitCnt_r_5)
                  + 4'(fuseCommitCnt_r_6) + 4'(fuseCommitCnt_r_7);
  end
  always_ff @(posedge clock) begin
    if (io_commits_isCommit) begin
      trueCommitCnt_r  <= trueCommitCnt;
      fuseCommitCnt_r <= commitValidOut[0] & commitInfo[0].commitType[2];
      fuseCommitCnt_r_1 <= commitValidOut[1] & commitInfo[1].commitType[2];
      fuseCommitCnt_r_2 <= commitValidOut[2] & commitInfo[2].commitType[2];
      fuseCommitCnt_r_3 <= commitValidOut[3] & commitInfo[3].commitType[2];
      fuseCommitCnt_r_4 <= commitValidOut[4] & commitInfo[4].commitType[2];
      fuseCommitCnt_r_5 <= commitValidOut[5] & commitInfo[5].commitType[2];
      fuseCommitCnt_r_6 <= commitValidOut[6] & commitInfo[6].commitType[2];
      fuseCommitCnt_r_7 <= commitValidOut[7] & commitInfo[7].commitType[2];
    end
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) isCommitReg_last_REG <= 1'b0;
    else       isCommitReg_last_REG <= io_commits_isCommit;
  end
  assign isCommitReg = isCommitReg_last_REG;

  logic [10:0] retireCounter;
  assign retireCounter = isCommitReg
      ? (11'(trueCommitCnt_r) + 11'(fuseCommitCnt)) : 11'h0;
  assign io_csr_perfinfo_retiredInstr = retireCounter[6:0];

  always_ff @(posedge clock or posedge reset) begin
    if (reset)            instrCntReg <= 64'h0;
    else if (isCommitReg) instrCntReg <= instrCntReg + {53'h0, retireCounter};
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) timer <= 64'h0;
    else       timer <= timer + 64'h1;
  end



  // ==========================================================================
  // §20 trace（指令追踪）
  // ==========================================================================
  // 八路提交槽各出一个 trace block，内容直接取 rawInfo（★不是 commitInfo★：
  // commitInfo 只把 ftqOffset 改成了"最后一条"，trace 要的是条目里存的原值）。
  // 第 0 路是唯一会被异常改写的：出异常/中断时它变成 Exception/Interrupt，
  // iretire 清零，并且**无条件 valid**（即便这一拍没有提交）。
  assign io_trace_traceCommitInfo_blocks_0_bits_ftqIdx_value = rawInfo[0].ftqIdx_value;
  assign io_trace_traceCommitInfo_blocks_0_bits_ftqOffset    = rawInfo[0].ftqOffset;
  assign io_trace_traceCommitInfo_blocks_0_bits_tracePipe_ilastsize = rawInfo[0].traceBlockInPipe_ilastsize;
  assign io_trace_traceCommitInfo_blocks_0_valid = (io_commits_isCommit & commitValidOut[0]) | io_exception_valid;
  assign io_trace_traceCommitInfo_blocks_0_bits_tracePipe_itype = io_exception_valid
      ? (io_exception_bits_isInterrupt ? IT_INTR : IT_EXCP)
      : rawInfo[0].traceBlockInPipe_itype;
  assign io_trace_traceCommitInfo_blocks_0_bits_tracePipe_iretire = io_exception_valid
      ? IRETIRE_W'(0) : rawInfo[0].traceBlockInPipe_iretire;

  assign io_trace_traceCommitInfo_blocks_1_bits_ftqIdx_value = rawInfo[1].ftqIdx_value;
  assign io_trace_traceCommitInfo_blocks_1_bits_ftqOffset    = rawInfo[1].ftqOffset;
  assign io_trace_traceCommitInfo_blocks_1_bits_tracePipe_ilastsize = rawInfo[1].traceBlockInPipe_ilastsize;
  assign io_trace_traceCommitInfo_blocks_1_valid = io_commits_isCommit & commitValidOut[1];
  assign io_trace_traceCommitInfo_blocks_1_bits_tracePipe_itype = rawInfo[1].traceBlockInPipe_itype;
  assign io_trace_traceCommitInfo_blocks_1_bits_tracePipe_iretire = rawInfo[1].traceBlockInPipe_iretire;

  assign io_trace_traceCommitInfo_blocks_2_bits_ftqIdx_value = rawInfo[2].ftqIdx_value;
  assign io_trace_traceCommitInfo_blocks_2_bits_ftqOffset    = rawInfo[2].ftqOffset;
  assign io_trace_traceCommitInfo_blocks_2_bits_tracePipe_ilastsize = rawInfo[2].traceBlockInPipe_ilastsize;
  assign io_trace_traceCommitInfo_blocks_2_valid = io_commits_isCommit & commitValidOut[2];
  assign io_trace_traceCommitInfo_blocks_2_bits_tracePipe_itype = rawInfo[2].traceBlockInPipe_itype;
  assign io_trace_traceCommitInfo_blocks_2_bits_tracePipe_iretire = rawInfo[2].traceBlockInPipe_iretire;

  assign io_trace_traceCommitInfo_blocks_3_bits_ftqIdx_value = rawInfo[3].ftqIdx_value;
  assign io_trace_traceCommitInfo_blocks_3_bits_ftqOffset    = rawInfo[3].ftqOffset;
  assign io_trace_traceCommitInfo_blocks_3_bits_tracePipe_ilastsize = rawInfo[3].traceBlockInPipe_ilastsize;
  assign io_trace_traceCommitInfo_blocks_3_valid = io_commits_isCommit & commitValidOut[3];
  assign io_trace_traceCommitInfo_blocks_3_bits_tracePipe_itype = rawInfo[3].traceBlockInPipe_itype;
  assign io_trace_traceCommitInfo_blocks_3_bits_tracePipe_iretire = rawInfo[3].traceBlockInPipe_iretire;

  assign io_trace_traceCommitInfo_blocks_4_bits_ftqIdx_value = rawInfo[4].ftqIdx_value;
  assign io_trace_traceCommitInfo_blocks_4_bits_ftqOffset    = rawInfo[4].ftqOffset;
  assign io_trace_traceCommitInfo_blocks_4_bits_tracePipe_ilastsize = rawInfo[4].traceBlockInPipe_ilastsize;
  assign io_trace_traceCommitInfo_blocks_4_valid = io_commits_isCommit & commitValidOut[4];
  assign io_trace_traceCommitInfo_blocks_4_bits_tracePipe_itype = rawInfo[4].traceBlockInPipe_itype;
  assign io_trace_traceCommitInfo_blocks_4_bits_tracePipe_iretire = rawInfo[4].traceBlockInPipe_iretire;

  assign io_trace_traceCommitInfo_blocks_5_bits_ftqIdx_value = rawInfo[5].ftqIdx_value;
  assign io_trace_traceCommitInfo_blocks_5_bits_ftqOffset    = rawInfo[5].ftqOffset;
  assign io_trace_traceCommitInfo_blocks_5_bits_tracePipe_ilastsize = rawInfo[5].traceBlockInPipe_ilastsize;
  assign io_trace_traceCommitInfo_blocks_5_valid = io_commits_isCommit & commitValidOut[5];
  assign io_trace_traceCommitInfo_blocks_5_bits_tracePipe_itype = rawInfo[5].traceBlockInPipe_itype;
  assign io_trace_traceCommitInfo_blocks_5_bits_tracePipe_iretire = rawInfo[5].traceBlockInPipe_iretire;

  assign io_trace_traceCommitInfo_blocks_6_bits_ftqIdx_value = rawInfo[6].ftqIdx_value;
  assign io_trace_traceCommitInfo_blocks_6_bits_ftqOffset    = rawInfo[6].ftqOffset;
  assign io_trace_traceCommitInfo_blocks_6_bits_tracePipe_ilastsize = rawInfo[6].traceBlockInPipe_ilastsize;
  assign io_trace_traceCommitInfo_blocks_6_valid = io_commits_isCommit & commitValidOut[6];
  assign io_trace_traceCommitInfo_blocks_6_bits_tracePipe_itype = rawInfo[6].traceBlockInPipe_itype;
  assign io_trace_traceCommitInfo_blocks_6_bits_tracePipe_iretire = rawInfo[6].traceBlockInPipe_iretire;

  assign io_trace_traceCommitInfo_blocks_7_bits_ftqIdx_value = rawInfo[7].ftqIdx_value;
  assign io_trace_traceCommitInfo_blocks_7_bits_ftqOffset    = rawInfo[7].ftqOffset;
  assign io_trace_traceCommitInfo_blocks_7_bits_tracePipe_ilastsize = rawInfo[7].traceBlockInPipe_ilastsize;
  assign io_trace_traceCommitInfo_blocks_7_valid = io_commits_isCommit & commitValidOut[7];
  assign io_trace_traceCommitInfo_blocks_7_bits_tracePipe_itype = rawInfo[7].traceBlockInPipe_itype;
  assign io_trace_traceCommitInfo_blocks_7_bits_tracePipe_iretire = rawInfo[7].traceBlockInPipe_iretire;

  // ==========================================================================
  // §21 异常出口（io_exception）
  // ==========================================================================
  // 整条是 RegEnable(..., exceptionHappen)：异常发生那一拍把现场锁下来，
  // 下一拍送出去。★gpaddr 不锁★ —— 它是上一拍 readGPAMemAddr 请求回来的数据，
  // 组合直通（56 位零扩到 64）。
  assign io_readGPAMemAddr_valid = exceptionHappen;

  always_ff @(posedge clock) io_exception_valid_REG <= exceptionHappen;
  assign io_exception_valid = io_exception_valid_REG;

  always_ff @(posedge clock) begin
    if (exceptionHappen) begin
      io_exception_bits_instr_r      <= deqHeadInstr;
      io_exception_bits_commitType_r <= rawInfo[0].commitType;
      r_4_0  <= exceptionGen_io_state_bits_exceptionVec_0;
      r_4_1  <= exceptionGen_io_state_bits_exceptionVec_1;
      r_4_2  <= exceptionGen_io_state_bits_exceptionVec_2;
      r_4_3  <= exceptionGen_io_state_bits_exceptionVec_3;
      r_4_4  <= exceptionGen_io_state_bits_exceptionVec_4;
      r_4_5  <= exceptionGen_io_state_bits_exceptionVec_5;
      r_4_6  <= exceptionGen_io_state_bits_exceptionVec_6;
      r_4_7  <= exceptionGen_io_state_bits_exceptionVec_7;
      r_4_8  <= exceptionGen_io_state_bits_exceptionVec_8;
      r_4_9  <= exceptionGen_io_state_bits_exceptionVec_9;
      r_4_10 <= exceptionGen_io_state_bits_exceptionVec_10;
      r_4_11 <= exceptionGen_io_state_bits_exceptionVec_11;
      r_4_12 <= exceptionGen_io_state_bits_exceptionVec_12;
      r_4_13 <= exceptionGen_io_state_bits_exceptionVec_13;
      r_4_14 <= exceptionGen_io_state_bits_exceptionVec_14;
      r_4_15 <= exceptionGen_io_state_bits_exceptionVec_15;
      r_4_16 <= exceptionGen_io_state_bits_exceptionVec_16;
      r_4_17 <= exceptionGen_io_state_bits_exceptionVec_17;
      r_4_18 <= exceptionGen_io_state_bits_exceptionVec_18;
      r_4_19 <= exceptionGen_io_state_bits_exceptionVec_19;
      r_4_20 <= exceptionGen_io_state_bits_exceptionVec_20;
      r_4_21 <= exceptionGen_io_state_bits_exceptionVec_21;
      r_4_22 <= exceptionGen_io_state_bits_exceptionVec_22;
      r_4_23 <= exceptionGen_io_state_bits_exceptionVec_23;
      // EX_BP(=3) 的断点：取指触发或执行 ebreak 才算 pcBkpt
      io_exception_bits_isPcBkpt_r <= exceptionGen_io_state_bits_exceptionVec_3
          & (exceptionGen_io_state_bits_isEnqExcp
             | (exceptionGen_io_state_bits_trigger == TA_NONE));
      io_exception_bits_isFetchMalAddr_r <=
          exceptionGen_io_state_bits_isFetchMalAddr & deqHasException;
      io_exception_bits_satpFlushFirstFetchFault_r <=
          exceptionGen_io_state_bits_satpFlushFirstFetchFault & deqHasException;
      io_exception_bits_singleStep_r      <= exceptionGen_io_state_bits_singleStep;
      io_exception_bits_crossPageIPFFix_r <= exceptionGen_io_state_bits_crossPageIPFFix;
      io_exception_bits_isInterrupt_r     <= intrEnable;
      io_exception_bits_isHls_r           <= rawInfo[0].isHls;
      io_exception_bits_trigger_r         <= exceptionGen_io_state_bits_trigger;
    end
  end

  assign io_exception_bits_instr      = io_exception_bits_instr_r;
  assign io_exception_bits_commitType = io_exception_bits_commitType_r;
  assign io_exception_bits_exceptionVec_0  = r_4_0;
  assign io_exception_bits_exceptionVec_1  = r_4_1;
  assign io_exception_bits_exceptionVec_2  = r_4_2;
  assign io_exception_bits_exceptionVec_3  = r_4_3;
  assign io_exception_bits_exceptionVec_4  = r_4_4;
  assign io_exception_bits_exceptionVec_5  = r_4_5;
  assign io_exception_bits_exceptionVec_6  = r_4_6;
  assign io_exception_bits_exceptionVec_7  = r_4_7;
  assign io_exception_bits_exceptionVec_8  = r_4_8;
  assign io_exception_bits_exceptionVec_9  = r_4_9;
  assign io_exception_bits_exceptionVec_10 = r_4_10;
  assign io_exception_bits_exceptionVec_11 = r_4_11;
  assign io_exception_bits_exceptionVec_12 = r_4_12;
  assign io_exception_bits_exceptionVec_13 = r_4_13;
  assign io_exception_bits_exceptionVec_14 = r_4_14;
  assign io_exception_bits_exceptionVec_15 = r_4_15;
  assign io_exception_bits_exceptionVec_16 = r_4_16;
  assign io_exception_bits_exceptionVec_17 = r_4_17;
  assign io_exception_bits_exceptionVec_18 = r_4_18;
  assign io_exception_bits_exceptionVec_19 = r_4_19;
  assign io_exception_bits_exceptionVec_20 = r_4_20;
  assign io_exception_bits_exceptionVec_21 = r_4_21;
  assign io_exception_bits_exceptionVec_22 = r_4_22;
  assign io_exception_bits_exceptionVec_23 = r_4_23;
  assign io_exception_bits_isPcBkpt                 = io_exception_bits_isPcBkpt_r;
  assign io_exception_bits_isFetchMalAddr           = io_exception_bits_isFetchMalAddr_r;
  assign io_exception_bits_satpFlushFirstFetchFault =
      io_exception_bits_satpFlushFirstFetchFault_r;
  assign io_exception_bits_singleStep      = io_exception_bits_singleStep_r;
  assign io_exception_bits_crossPageIPFFix = io_exception_bits_crossPageIPFFix_r;
  assign io_exception_bits_isInterrupt     = io_exception_bits_isInterrupt_r;
  assign io_exception_bits_isHls           = io_exception_bits_isHls_r;
  assign io_exception_bits_trigger         = io_exception_bits_trigger_r;
  // GPAMem 读回来的是 56 位物理地址，端口是 64 位
  assign io_exception_bits_gpaddr             = {8'h0, io_readGPAMemData_gpaddr};
  assign io_exception_bits_isForVSnonLeafPTE  = io_readGPAMemData_isForVSnonLeafPTE;

  // ---- 向量异常信息（送 VecExcpMod）----
  // vecExcpInfo 的 valid 每拍都算，bits 只在 exceptionHappen 那拍更新。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) vecExcpInfo_valid <= 1'b0;
    else vecExcpInfo_valid <= exceptionHappen & ~intrEnable
                            & exceptionGen_io_state_bits_vstartEn
                            & exceptionGen_io_state_bits_isVecLoad
                            & ~exceptionGen_io_state_bits_isEnqExcp;
  end
  always_ff @(posedge clock) begin
    if (exceptionHappen) begin
      vecExcpInfo_bits_nf        <= exceptionGen_io_state_bits_nf;
      vecExcpInfo_bits_vsew      <= exceptionGen_io_state_bits_vsew;
      vecExcpInfo_bits_veew      <= exceptionGen_io_state_bits_veew;
      vecExcpInfo_bits_vlmul     <= exceptionGen_io_state_bits_vlmul;
      vecExcpInfo_bits_isStride  <= exceptionGen_io_state_bits_isStrided;
      vecExcpInfo_bits_isIndexed <= exceptionGen_io_state_bits_isIndexed;
      vecExcpInfo_bits_isWhole   <= exceptionGen_io_state_bits_isWhole;
      vecExcpInfo_bits_isVlm     <= exceptionGen_io_state_bits_isVlm;
      // vstart 端口只有 7 位（VLEN 决定），exceptionGen 那边是 64 位
      vecExcpInfo_bits_vstart    <= exceptionGen_io_state_bits_vstart[6:0];
    end
  end
  assign io_toVecExcpMod_excpInfo_valid          = vecExcpInfo_valid;
  assign io_toVecExcpMod_excpInfo_bits_nf        = vecExcpInfo_bits_nf;
  assign io_toVecExcpMod_excpInfo_bits_vsew      = vecExcpInfo_bits_vsew;
  assign io_toVecExcpMod_excpInfo_bits_veew      = vecExcpInfo_bits_veew;
  assign io_toVecExcpMod_excpInfo_bits_vlmul     = vecExcpInfo_bits_vlmul;
  assign io_toVecExcpMod_excpInfo_bits_isStride  = vecExcpInfo_bits_isStride;
  assign io_toVecExcpMod_excpInfo_bits_isIndexed = vecExcpInfo_bits_isIndexed;
  assign io_toVecExcpMod_excpInfo_bits_isWhole   = vecExcpInfo_bits_isWhole;
  assign io_toVecExcpMod_excpInfo_bits_isVlm     = vecExcpInfo_bits_isVlm;
  assign io_toVecExcpMod_excpInfo_bits_vstart    = vecExcpInfo_bits_vstart;

  // ---- difftest 用的"最新提交 robIdx" ----
  // PriorityMuxDefault(commitValid.reverse zip robIdx.reverse, deqPtr)：
  // 从最后一路往前找第一个提交有效的，一个都没有就用 deqPtr。
  logic             newestCommitFlag;
  logic [PTR_W-1:0] newestCommitValue;
  always_comb begin
    newestCommitFlag  = deqPtrFlag[0];
    newestCommitValue = deqPtrValue[0];
    for (int i = 0; i < COMMIT_W; i++)
      if (commitValidOut[i]) begin
        newestCommitFlag  = deqPtrFlag[i];
        newestCommitValue = deqPtrValue[i];
      end
  end
  logic hasCommitNow;
  always_comb begin
    hasCommitNow = 1'b0;
    for (int i = 0; i < COMMIT_W; i++) hasCommitNow = hasCommitNow | commitValidOut[i];
    hasCommitNow = hasCommitNow & io_commits_isCommit;
  end
  assign io_diffRatCommitRobIdx_valid      = hasCommitNow | deqVlsExceptionNeedCommit;
  assign io_diffRatCommitRobIdx_bits_flag  = deqVlsExceptionNeedCommit
                                           ? deqPtrFlag[0]  : newestCommitFlag;
  assign io_diffRatCommitRobIdx_bits_value = deqVlsExceptionNeedCommit
                                           ? deqPtrValue[0] : newestCommitValue;



  // ==========================================================================
  // §22 debug / difftest 规则阵列
  // ==========================================================================
  // 这一段不参与功能，但**一位都不能省**：省掉之后 FM 的 match 会退化成签名
  // 匹配，在上万个结构相同的寄存器上是 O(N^2)（见文件头 §1 的说明）。
  //
  // ★两个方向相反的优先链，别弄反★
  //   入队侧：Scala `for (i <- 0 until RenameWidth) when(canEnqueue(i))` ——
  //           后写的赢 ⇒ **第 5 路优先级最高**。
  //   写回侧：Scala `for (wb <- exuWBs)`（0..24）—— 同样后写的赢 ⇒
  //           **第 24 路优先级最高**（golden 里就是
  //           `if (wb24) ... else if (wb23) ...` 这条链）。
  //   SV 里两者都靠"循环里后一次非阻塞赋值覆盖前一次"实现，所以两个循环的
  //   方向都是 j 递增；差别在于哪一端是 0。

  logic [XLEN-1:0]  enqRenameTime [RENAME_W];
  logic [31:0]      enqInstrVec   [RENAME_W];
  logic [VADDR_W-1:0] enqPcVec    [RENAME_W];
  logic [FUTYPE_W-1:0] enqFuType  [RENAME_W];
  logic [FUTYPE_W-1:0] enqDbgFuType[RENAME_W];
  logic [FUOPTYPE_W-1:0] enqFuOpType[RENAME_W];
  logic [COMMITTYPE_W-1:0] enqCommitType [RENAME_W];
  logic             enqSimTrig    [RENAME_W];
  logic [LQ_PTR_W-1:0] enqLqIdx   [RENAME_W];
  logic [SQ_PTR_W-1:0] enqSqIdx   [RENAME_W];

  always_comb begin
    enqRenameTime[0] = io_enq_req_0_bits_debugInfo_renameTime;
    enqInstrVec[0]   = io_enq_req_0_bits_instr;
    enqPcVec[0]      = io_enq_req_0_bits_pc;
    enqFuType[0]     = io_enq_req_0_bits_fuType;
    enqDbgFuType[0]  = io_enq_req_0_bits_debug_fuType;
    enqFuOpType[0]   = io_enq_req_0_bits_fuOpType;
    enqCommitType[0] = io_enq_req_0_bits_commitType;
    enqSimTrig[0]    = io_enq_req_0_bits_debug_sim_trig;
    enqLqIdx[0]      = io_enq_req_0_bits_lqIdx_value;
    enqSqIdx[0]      = io_enq_req_0_bits_sqIdx_value;
    enqRenameTime[1] = io_enq_req_1_bits_debugInfo_renameTime;
    enqInstrVec[1]   = io_enq_req_1_bits_instr;
    enqPcVec[1]      = io_enq_req_1_bits_pc;
    enqFuType[1]     = io_enq_req_1_bits_fuType;
    enqDbgFuType[1]  = io_enq_req_1_bits_debug_fuType;
    enqFuOpType[1]   = io_enq_req_1_bits_fuOpType;
    enqCommitType[1] = io_enq_req_1_bits_commitType;
    enqSimTrig[1]    = io_enq_req_1_bits_debug_sim_trig;
    enqLqIdx[1]      = io_enq_req_1_bits_lqIdx_value;
    enqSqIdx[1]      = io_enq_req_1_bits_sqIdx_value;
    enqRenameTime[2] = io_enq_req_2_bits_debugInfo_renameTime;
    enqInstrVec[2]   = io_enq_req_2_bits_instr;
    enqPcVec[2]      = io_enq_req_2_bits_pc;
    enqFuType[2]     = io_enq_req_2_bits_fuType;
    enqDbgFuType[2]  = io_enq_req_2_bits_debug_fuType;
    enqFuOpType[2]   = io_enq_req_2_bits_fuOpType;
    enqCommitType[2] = io_enq_req_2_bits_commitType;
    enqSimTrig[2]    = io_enq_req_2_bits_debug_sim_trig;
    enqLqIdx[2]      = io_enq_req_2_bits_lqIdx_value;
    enqSqIdx[2]      = io_enq_req_2_bits_sqIdx_value;
    enqRenameTime[3] = io_enq_req_3_bits_debugInfo_renameTime;
    enqInstrVec[3]   = io_enq_req_3_bits_instr;
    enqPcVec[3]      = io_enq_req_3_bits_pc;
    enqFuType[3]     = io_enq_req_3_bits_fuType;
    enqDbgFuType[3]  = io_enq_req_3_bits_debug_fuType;
    enqFuOpType[3]   = io_enq_req_3_bits_fuOpType;
    enqCommitType[3] = io_enq_req_3_bits_commitType;
    enqSimTrig[3]    = io_enq_req_3_bits_debug_sim_trig;
    enqLqIdx[3]      = io_enq_req_3_bits_lqIdx_value;
    enqSqIdx[3]      = io_enq_req_3_bits_sqIdx_value;
    enqRenameTime[4] = io_enq_req_4_bits_debugInfo_renameTime;
    enqInstrVec[4]   = io_enq_req_4_bits_instr;
    enqPcVec[4]      = io_enq_req_4_bits_pc;
    enqFuType[4]     = io_enq_req_4_bits_fuType;
    enqDbgFuType[4]  = io_enq_req_4_bits_debug_fuType;
    enqFuOpType[4]   = io_enq_req_4_bits_fuOpType;
    enqCommitType[4] = io_enq_req_4_bits_commitType;
    enqSimTrig[4]    = io_enq_req_4_bits_debug_sim_trig;
    enqLqIdx[4]      = io_enq_req_4_bits_lqIdx_value;
    enqSqIdx[4]      = io_enq_req_4_bits_sqIdx_value;
    enqRenameTime[5] = io_enq_req_5_bits_debugInfo_renameTime;
    enqInstrVec[5]   = io_enq_req_5_bits_instr;
    enqPcVec[5]      = io_enq_req_5_bits_pc;
    enqFuType[5]     = io_enq_req_5_bits_fuType;
    enqDbgFuType[5]  = io_enq_req_5_bits_debug_fuType;
    enqFuOpType[5]   = io_enq_req_5_bits_fuOpType;
    enqCommitType[5] = io_enq_req_5_bits_commitType;
    enqSimTrig[5]    = io_enq_req_5_bits_debug_sim_trig;
    enqLqIdx[5]      = io_enq_req_5_bits_lqIdx_value;
    enqSqIdx[5]      = io_enq_req_5_bits_sqIdx_value;
  end

  // 写回侧的调试负载（下标集合各不相同：只有访存那几路有 lqIdx/sqIdx/paddr）
  logic [XLEN-1:0]  wbEnqRsTime   [EXU_N];
  logic [XLEN-1:0]  wbSelectTime  [EXU_N];
  logic [XLEN-1:0]  wbIssueTime   [EXU_N];
  logic [XLEN-1:0]  wbWbTime      [EXU_N];
  logic [XLEN-1:0]  wbData0       [EXU_N];
  logic [LQ_PTR_W-1:0] wbLqIdx    [EXU_N];
  logic [SQ_PTR_W-1:0] wbSqIdx    [EXU_N];
  logic             wbIsMMIO      [EXU_N];
  logic             wbIsNCIO      [EXU_N];
  logic             wbIsPerfCnt   [EXU_N];
  logic [PADDR_W-1:0] wbPaddr     [EXU_N];

  always_comb begin
    for (int k = 0; k < EXU_N; k++) begin
      // 没有这个字段的写回口写 0 —— 与 Scala 的 `.getOrElse(0.U)` 一致
      wbLqIdx[k]    = {LQ_PTR_W{1'b0}};
      wbSqIdx[k]    = {SQ_PTR_W{1'b0}};
      wbIsMMIO[k]   = 1'b0;
      wbIsNCIO[k]   = 1'b0;
      wbIsPerfCnt[k]= 1'b0;
      wbPaddr[k]    = {PADDR_W{1'b0}};
    end
    wbEnqRsTime[0]  = io_exuWriteback_0_bits_debugInfo_enqRsTime;
    wbSelectTime[0] = io_exuWriteback_0_bits_debugInfo_selectTime;
    wbIssueTime[0]  = io_exuWriteback_0_bits_debugInfo_issueTime;
    wbWbTime[0]     = io_exuWriteback_0_bits_debugInfo_writebackTime;
    wbData0[0]      = io_exuWriteback_0_bits_data_0;
    wbEnqRsTime[1]  = io_exuWriteback_1_bits_debugInfo_enqRsTime;
    wbSelectTime[1] = io_exuWriteback_1_bits_debugInfo_selectTime;
    wbIssueTime[1]  = io_exuWriteback_1_bits_debugInfo_issueTime;
    wbWbTime[1]     = io_exuWriteback_1_bits_debugInfo_writebackTime;
    wbData0[1]      = io_exuWriteback_1_bits_data_0;
    wbEnqRsTime[2]  = io_exuWriteback_2_bits_debugInfo_enqRsTime;
    wbSelectTime[2] = io_exuWriteback_2_bits_debugInfo_selectTime;
    wbIssueTime[2]  = io_exuWriteback_2_bits_debugInfo_issueTime;
    wbWbTime[2]     = io_exuWriteback_2_bits_debugInfo_writebackTime;
    wbData0[2]      = io_exuWriteback_2_bits_data_0;
    wbEnqRsTime[3]  = io_exuWriteback_3_bits_debugInfo_enqRsTime;
    wbSelectTime[3] = io_exuWriteback_3_bits_debugInfo_selectTime;
    wbIssueTime[3]  = io_exuWriteback_3_bits_debugInfo_issueTime;
    wbWbTime[3]     = io_exuWriteback_3_bits_debugInfo_writebackTime;
    wbData0[3]      = io_exuWriteback_3_bits_data_0;
    wbEnqRsTime[4]  = io_exuWriteback_4_bits_debugInfo_enqRsTime;
    wbSelectTime[4] = io_exuWriteback_4_bits_debugInfo_selectTime;
    wbIssueTime[4]  = io_exuWriteback_4_bits_debugInfo_issueTime;
    wbWbTime[4]     = io_exuWriteback_4_bits_debugInfo_writebackTime;
    wbData0[4]      = io_exuWriteback_4_bits_data_0;
    wbEnqRsTime[5]  = io_exuWriteback_5_bits_debugInfo_enqRsTime;
    wbSelectTime[5] = io_exuWriteback_5_bits_debugInfo_selectTime;
    wbIssueTime[5]  = io_exuWriteback_5_bits_debugInfo_issueTime;
    wbWbTime[5]     = io_exuWriteback_5_bits_debugInfo_writebackTime;
    wbData0[5]      = io_exuWriteback_5_bits_data_0;
    wbEnqRsTime[6]  = io_exuWriteback_6_bits_debugInfo_enqRsTime;
    wbSelectTime[6] = io_exuWriteback_6_bits_debugInfo_selectTime;
    wbIssueTime[6]  = io_exuWriteback_6_bits_debugInfo_issueTime;
    wbWbTime[6]     = io_exuWriteback_6_bits_debugInfo_writebackTime;
    wbData0[6]      = io_exuWriteback_6_bits_data_0;
    wbEnqRsTime[7]  = io_exuWriteback_7_bits_debugInfo_enqRsTime;
    wbSelectTime[7] = io_exuWriteback_7_bits_debugInfo_selectTime;
    wbIssueTime[7]  = io_exuWriteback_7_bits_debugInfo_issueTime;
    wbWbTime[7]     = io_exuWriteback_7_bits_debugInfo_writebackTime;
    wbData0[7]      = io_exuWriteback_7_bits_data_0;
    wbEnqRsTime[8]  = io_exuWriteback_8_bits_debugInfo_enqRsTime;
    wbSelectTime[8] = io_exuWriteback_8_bits_debugInfo_selectTime;
    wbIssueTime[8]  = io_exuWriteback_8_bits_debugInfo_issueTime;
    wbWbTime[8]     = io_exuWriteback_8_bits_debugInfo_writebackTime;
    wbData0[8]      = io_exuWriteback_8_bits_data_0;
    wbEnqRsTime[9]  = io_exuWriteback_9_bits_debugInfo_enqRsTime;
    wbSelectTime[9] = io_exuWriteback_9_bits_debugInfo_selectTime;
    wbIssueTime[9]  = io_exuWriteback_9_bits_debugInfo_issueTime;
    wbWbTime[9]     = io_exuWriteback_9_bits_debugInfo_writebackTime;
    wbData0[9]      = io_exuWriteback_9_bits_data_0;
    wbEnqRsTime[10]  = io_exuWriteback_10_bits_debugInfo_enqRsTime;
    wbSelectTime[10] = io_exuWriteback_10_bits_debugInfo_selectTime;
    wbIssueTime[10]  = io_exuWriteback_10_bits_debugInfo_issueTime;
    wbWbTime[10]     = io_exuWriteback_10_bits_debugInfo_writebackTime;
    wbData0[10]      = io_exuWriteback_10_bits_data_0;
    wbEnqRsTime[11]  = io_exuWriteback_11_bits_debugInfo_enqRsTime;
    wbSelectTime[11] = io_exuWriteback_11_bits_debugInfo_selectTime;
    wbIssueTime[11]  = io_exuWriteback_11_bits_debugInfo_issueTime;
    wbWbTime[11]     = io_exuWriteback_11_bits_debugInfo_writebackTime;
    wbData0[11]      = io_exuWriteback_11_bits_data_0;
    wbEnqRsTime[12]  = io_exuWriteback_12_bits_debugInfo_enqRsTime;
    wbSelectTime[12] = io_exuWriteback_12_bits_debugInfo_selectTime;
    wbIssueTime[12]  = io_exuWriteback_12_bits_debugInfo_issueTime;
    wbWbTime[12]     = io_exuWriteback_12_bits_debugInfo_writebackTime;
    wbData0[12]      = io_exuWriteback_12_bits_data_0;
    wbEnqRsTime[13]  = io_exuWriteback_13_bits_debugInfo_enqRsTime;
    wbSelectTime[13] = io_exuWriteback_13_bits_debugInfo_selectTime;
    wbIssueTime[13]  = io_exuWriteback_13_bits_debugInfo_issueTime;
    wbWbTime[13]     = io_exuWriteback_13_bits_debugInfo_writebackTime;
    wbData0[13]      = io_exuWriteback_13_bits_data_0;
    wbEnqRsTime[14]  = io_exuWriteback_14_bits_debugInfo_enqRsTime;
    wbSelectTime[14] = io_exuWriteback_14_bits_debugInfo_selectTime;
    wbIssueTime[14]  = io_exuWriteback_14_bits_debugInfo_issueTime;
    wbWbTime[14]     = io_exuWriteback_14_bits_debugInfo_writebackTime;
    wbData0[14]      = io_exuWriteback_14_bits_data_0;
    wbEnqRsTime[15]  = io_exuWriteback_15_bits_debugInfo_enqRsTime;
    wbSelectTime[15] = io_exuWriteback_15_bits_debugInfo_selectTime;
    wbIssueTime[15]  = io_exuWriteback_15_bits_debugInfo_issueTime;
    wbWbTime[15]     = io_exuWriteback_15_bits_debugInfo_writebackTime;
    wbData0[15]      = io_exuWriteback_15_bits_data_0;
    wbEnqRsTime[16]  = io_exuWriteback_16_bits_debugInfo_enqRsTime;
    wbSelectTime[16] = io_exuWriteback_16_bits_debugInfo_selectTime;
    wbIssueTime[16]  = io_exuWriteback_16_bits_debugInfo_issueTime;
    wbWbTime[16]     = io_exuWriteback_16_bits_debugInfo_writebackTime;
    wbData0[16]      = io_exuWriteback_16_bits_data_0;
    wbEnqRsTime[17]  = io_exuWriteback_17_bits_debugInfo_enqRsTime;
    wbSelectTime[17] = io_exuWriteback_17_bits_debugInfo_selectTime;
    wbIssueTime[17]  = io_exuWriteback_17_bits_debugInfo_issueTime;
    wbWbTime[17]     = io_exuWriteback_17_bits_debugInfo_writebackTime;
    wbData0[17]      = io_exuWriteback_17_bits_data_0;
    wbEnqRsTime[18]  = io_exuWriteback_18_bits_debugInfo_enqRsTime;
    wbSelectTime[18] = io_exuWriteback_18_bits_debugInfo_selectTime;
    wbIssueTime[18]  = io_exuWriteback_18_bits_debugInfo_issueTime;
    wbWbTime[18]     = io_exuWriteback_18_bits_debugInfo_writebackTime;
    wbData0[18]      = io_exuWriteback_18_bits_data_0;
    wbEnqRsTime[19]  = io_exuWriteback_19_bits_debugInfo_enqRsTime;
    wbSelectTime[19] = io_exuWriteback_19_bits_debugInfo_selectTime;
    wbIssueTime[19]  = io_exuWriteback_19_bits_debugInfo_issueTime;
    wbWbTime[19]     = io_exuWriteback_19_bits_debugInfo_writebackTime;
    wbData0[19]      = io_exuWriteback_19_bits_data_0;
    wbEnqRsTime[20]  = io_exuWriteback_20_bits_debugInfo_enqRsTime;
    wbSelectTime[20] = io_exuWriteback_20_bits_debugInfo_selectTime;
    wbIssueTime[20]  = io_exuWriteback_20_bits_debugInfo_issueTime;
    wbWbTime[20]     = io_exuWriteback_20_bits_debugInfo_writebackTime;
    wbData0[20]      = io_exuWriteback_20_bits_data_0;
    wbEnqRsTime[21]  = io_exuWriteback_21_bits_debugInfo_enqRsTime;
    wbSelectTime[21] = io_exuWriteback_21_bits_debugInfo_selectTime;
    wbIssueTime[21]  = io_exuWriteback_21_bits_debugInfo_issueTime;
    wbWbTime[21]     = io_exuWriteback_21_bits_debugInfo_writebackTime;
    wbData0[21]      = io_exuWriteback_21_bits_data_0;
    wbEnqRsTime[22]  = io_exuWriteback_22_bits_debugInfo_enqRsTime;
    wbSelectTime[22] = io_exuWriteback_22_bits_debugInfo_selectTime;
    wbIssueTime[22]  = io_exuWriteback_22_bits_debugInfo_issueTime;
    wbWbTime[22]     = io_exuWriteback_22_bits_debugInfo_writebackTime;
    wbData0[22]      = io_exuWriteback_22_bits_data_0;
    wbEnqRsTime[23]  = io_exuWriteback_23_bits_debugInfo_enqRsTime;
    wbSelectTime[23] = io_exuWriteback_23_bits_debugInfo_selectTime;
    wbIssueTime[23]  = io_exuWriteback_23_bits_debugInfo_issueTime;
    wbWbTime[23]     = io_exuWriteback_23_bits_debugInfo_writebackTime;
    wbData0[23]      = io_exuWriteback_23_bits_data_0;
    wbEnqRsTime[24]  = io_exuWriteback_24_bits_debugInfo_enqRsTime;
    wbSelectTime[24] = io_exuWriteback_24_bits_debugInfo_selectTime;
    wbIssueTime[24]  = io_exuWriteback_24_bits_debugInfo_issueTime;
    wbWbTime[24]     = io_exuWriteback_24_bits_debugInfo_writebackTime;
    wbData0[24]      = io_exuWriteback_24_bits_data_0;
    wbLqIdx[20]     = io_exuWriteback_20_bits_lqIdx_value;
    wbLqIdx[21]     = io_exuWriteback_21_bits_lqIdx_value;
    wbLqIdx[22]     = io_exuWriteback_22_bits_lqIdx_value;
    wbSqIdx[18]     = io_exuWriteback_18_bits_sqIdx_value;
    wbSqIdx[19]     = io_exuWriteback_19_bits_sqIdx_value;
    wbIsMMIO[18]    = io_exuWriteback_18_bits_debug_isMMIO;
    wbIsNCIO[18]    = io_exuWriteback_18_bits_debug_isNCIO;
    wbPaddr[18]     = io_exuWriteback_18_bits_debug_paddr;
    wbIsMMIO[19]    = io_exuWriteback_19_bits_debug_isMMIO;
    wbIsNCIO[19]    = io_exuWriteback_19_bits_debug_isNCIO;
    wbPaddr[19]     = io_exuWriteback_19_bits_debug_paddr;
    wbIsMMIO[20]    = io_exuWriteback_20_bits_debug_isMMIO;
    wbIsNCIO[20]    = io_exuWriteback_20_bits_debug_isNCIO;
    wbPaddr[20]     = io_exuWriteback_20_bits_debug_paddr;
    wbIsMMIO[21]    = io_exuWriteback_21_bits_debug_isMMIO;
    wbIsNCIO[21]    = io_exuWriteback_21_bits_debug_isNCIO;
    wbPaddr[21]     = io_exuWriteback_21_bits_debug_paddr;
    wbIsMMIO[22]    = io_exuWriteback_22_bits_debug_isMMIO;
    wbIsNCIO[22]    = io_exuWriteback_22_bits_debug_isNCIO;
    wbPaddr[22]     = io_exuWriteback_22_bits_debug_paddr;
    wbIsMMIO[23]    = io_exuWriteback_23_bits_debug_isMMIO;
    wbIsNCIO[23]    = io_exuWriteback_23_bits_debug_isNCIO;
    wbPaddr[23]     = io_exuWriteback_23_bits_debug_paddr;
    wbIsMMIO[24]    = io_exuWriteback_24_bits_debug_isMMIO;
    wbIsNCIO[24]    = io_exuWriteback_24_bits_debug_isNCIO;
    wbPaddr[24]     = io_exuWriteback_24_bits_debug_paddr;
    wbIsPerfCnt[7] = io_exuWriteback_7_bits_debug_isPerfCnt;
    wbIsPerfCnt[18] = io_exuWriteback_18_bits_debug_isPerfCnt;
    wbIsPerfCnt[19] = io_exuWriteback_19_bits_debug_isPerfCnt;
    wbIsPerfCnt[20] = io_exuWriteback_20_bits_debug_isPerfCnt;
    wbIsPerfCnt[21] = io_exuWriteback_21_bits_debug_isPerfCnt;
    wbIsPerfCnt[22] = io_exuWriteback_22_bits_debug_isPerfCnt;
    wbIsPerfCnt[23] = io_exuWriteback_23_bits_debug_isPerfCnt;
    wbIsPerfCnt[24] = io_exuWriteback_24_bits_debug_isPerfCnt;
  end

  // ---- debug_microOp / debug_exuData / dt_exuDebug 的写入 ----
  always_ff @(posedge clock) begin
    for (int i = 0; i < ROB_SIZE; i++) begin
      // 入队：第 5 路优先（循环递增 => 后写的赢）
      for (int j = 0; j < RENAME_W; j++)
        if (enqOH[i][j]) begin
          debug_microOp_debugReg_instr[i]      <= enqInstrVec[j];
          debug_microOp_debugReg_pc[i]         <= enqPcVec[j];
          debug_microOp_debugReg_fuType[i]     <= enqFuType[j];
          debug_microOp_debugReg_fuOpType[i]   <= enqFuOpType[j];
          debug_microOp_debugReg_commitType[i] <= enqCommitType[j];
          debug_microOp_debugReg_debug_fuType[i]   <= enqDbgFuType[j];
          debug_microOp_debugReg_debug_sim_trig[i] <= enqSimTrig[j];
          debug_microOp_debugReg_lqIdx_value[i]    <= enqLqIdx[j];
          debug_microOp_debugReg_sqIdx_value[i]    <= enqSqIdx[j];
          debug_microOp_debugReg_debugInfo_renameTime[i]    <= enqRenameTime[j];
          // 五个时间戳入队时统一打上当前 timer
          debug_microOp_debugReg_debugInfo_dispatchTime[i]  <= timer;
          debug_microOp_debugReg_debugInfo_enqRsTime[i]     <= timer;
          debug_microOp_debugReg_debugInfo_selectTime[i]    <= timer;
          debug_microOp_debugReg_debugInfo_issueTime[i]     <= timer;
          debug_microOp_debugReg_debugInfo_writebackTime[i] <= timer;
        end
      // ★LSQ 入队回来的 lqIdx 必须写在写回**前面**★（UT 首轮修完后剩下的唯一一条，
      //   征状：gatewayIn_packed_8_bore 的 lqIdx 字段 g=0x34 x=0x56，其余 322 位全同）
      //   golden 的优先级链（if / else if，先者胜）是
      //     exuWriteback(24..19) > debugEnqLsq(req_5..req_0) > enq(req_5..req_0)
      //   —— 即**写回压过 LSQ 入队**。本文件用「后写的赢」表达优先级，所以
      //   debugEnqLsq 这一圈要放在 exuWriteback 那一圈**之前**。
      //   原先它排在最后（注释还写着"优先级更高"），把这两级整个倒过来了。
      for (int j = 0; j < RENAME_W; j++)
        if (dbgEnqLsqAlloc[j] & (dbgEnqLsqRobIdx[j] == PTR_W'(i)))
          debug_microOp_debugReg_lqIdx_value[i] <= dbgEnqLsqLqIdx[j];
      // 写回：第 24 路优先（同样循环递增 => 后写的赢）
      // lqIdx 只有第 20/21/22 路带真值，其余各路都写 0 —— 这不是漏写：
      // golden 把「都写 0」的相邻分支合并成了两条（24|23 一条、19..0 一条），
      // 合并前后优先级不变，展开就是「除 20/21/22 外一律写 0」。
      for (int k = 0; k < EXU_N; k++)
        if (exuWbValid[k] & (exuWbRobIdx[k] == PTR_W'(i))) begin
          debug_microOp_debugReg_debugInfo_enqRsTime[i]     <= wbEnqRsTime[k];
          debug_microOp_debugReg_debugInfo_selectTime[i]    <= wbSelectTime[k];
          debug_microOp_debugReg_debugInfo_issueTime[i]     <= wbIssueTime[k];
          debug_microOp_debugReg_debugInfo_writebackTime[i] <= wbWbTime[k];
          debug_microOp_debugReg_lqIdx_value[i]             <= wbLqIdx[k];
          debug_microOp_debugReg_sqIdx_value[i]             <= wbSqIdx[k];
          debug_exuData[i]        <= wbData0[k];
          dt_exuDebug_isMMIO[i]   <= wbIsMMIO[k];
          dt_exuDebug_isNCIO[i]   <= wbIsNCIO[k];
          dt_exuDebug_isPerfCnt[i]<= wbIsPerfCnt[k];
          dt_exuDebug_paddr[i]    <= wbPaddr[k];
        end
    end
  end

  always_comb begin
    dbgEnqLsqAlloc[0]  = io_debugEnqLsq_canAccept & io_debugEnqLsq_needAlloc_0[0] & io_debugEnqLsq_req_0_valid;
    dbgEnqLsqRobIdx[0] = io_debugEnqLsq_req_0_bits_robIdx_value;
    dbgEnqLsqLqIdx[0]  = io_debugEnqLsq_req_0_bits_lqIdx_value;
    dbgEnqLsqAlloc[1]  = io_debugEnqLsq_canAccept & io_debugEnqLsq_needAlloc_1[0] & io_debugEnqLsq_req_1_valid;
    dbgEnqLsqRobIdx[1] = io_debugEnqLsq_req_1_bits_robIdx_value;
    dbgEnqLsqLqIdx[1]  = io_debugEnqLsq_req_1_bits_lqIdx_value;
    dbgEnqLsqAlloc[2]  = io_debugEnqLsq_canAccept & io_debugEnqLsq_needAlloc_2[0] & io_debugEnqLsq_req_2_valid;
    dbgEnqLsqRobIdx[2] = io_debugEnqLsq_req_2_bits_robIdx_value;
    dbgEnqLsqLqIdx[2]  = io_debugEnqLsq_req_2_bits_lqIdx_value;
    dbgEnqLsqAlloc[3]  = io_debugEnqLsq_canAccept & io_debugEnqLsq_needAlloc_3[0] & io_debugEnqLsq_req_3_valid;
    dbgEnqLsqRobIdx[3] = io_debugEnqLsq_req_3_bits_robIdx_value;
    dbgEnqLsqLqIdx[3]  = io_debugEnqLsq_req_3_bits_lqIdx_value;
    dbgEnqLsqAlloc[4]  = io_debugEnqLsq_canAccept & io_debugEnqLsq_needAlloc_4[0] & io_debugEnqLsq_req_4_valid;
    dbgEnqLsqRobIdx[4] = io_debugEnqLsq_req_4_bits_robIdx_value;
    dbgEnqLsqLqIdx[4]  = io_debugEnqLsq_req_4_bits_lqIdx_value;
    dbgEnqLsqAlloc[5]  = io_debugEnqLsq_canAccept & io_debugEnqLsq_needAlloc_5[0] & io_debugEnqLsq_req_5_valid;
    dbgEnqLsqRobIdx[5] = io_debugEnqLsq_req_5_bits_robIdx_value;
    dbgEnqLsqLqIdx[5]  = io_debugEnqLsq_req_5_bits_lqIdx_value;
  end

  // ---- debug_lsIssued / debug_lsTopdownInfo ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < ROB_SIZE; i++) debug_lsIssued[i] <= 1'b0;
    end else begin
      for (int i = 0; i < ROB_SIZE; i++) begin
        for (int j = 0; j < RENAME_W; j++)
          if (enqOH[i][j]) debug_lsIssued[i] <= 1'b0;
        if (io_debugHeadLsIssue & (deqPtrValue[0] == PTR_W'(i)))
          debug_lsIssued[i] <= 1'b1;
      end
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < ROB_SIZE; i++) begin
        debug_lsTopdownInfo_s1_vaddr_valid[i] <= 1'b0;
        debug_lsTopdownInfo_s1_vaddr_bits[i]  <= {VADDR_W{1'b0}};
        debug_lsTopdownInfo_s2_paddr_valid[i] <= 1'b0;
        debug_lsTopdownInfo_s2_paddr_bits[i]  <= {PADDR_W{1'b0}};
      end
    end else begin
      for (int i = 0; i < ROB_SIZE; i++) begin
        // 入队清零（LsTopdownInfo.init），三路 ldu 的 s1/s2 再按 robIdx 置位
        for (int j = 0; j < RENAME_W; j++)
          if (enqOH[i][j]) begin
            debug_lsTopdownInfo_s1_vaddr_valid[i] <= 1'b0;
            debug_lsTopdownInfo_s1_vaddr_bits[i]  <= {VADDR_W{1'b0}};
            debug_lsTopdownInfo_s2_paddr_valid[i] <= 1'b0;
            debug_lsTopdownInfo_s2_paddr_bits[i]  <= {PADDR_W{1'b0}};
          end
        for (int k = 0; k < 3; k++) begin
          if (lsTdS1Valid[k] & (lsTdS1RobIdx[k] == PTR_W'(i))) begin
            debug_lsTopdownInfo_s1_vaddr_valid[i] <= 1'b1;
            debug_lsTopdownInfo_s1_vaddr_bits[i]  <= lsTdS1Vaddr[k];
          end
          if (lsTdS2Valid[k] & (lsTdS2RobIdx[k] == PTR_W'(i))) begin
            debug_lsTopdownInfo_s2_paddr_valid[i] <= 1'b1;
            debug_lsTopdownInfo_s2_paddr_bits[i]  <= lsTdS2Paddr[k];
          end
        end
      end
    end
  end

  always_comb begin
    lsTdS1Valid[0]  = io_lsTopdownInfo_0_s1_vaddr_valid;
    lsTdS1RobIdx[0] = io_lsTopdownInfo_0_s1_robIdx;
    lsTdS1Vaddr[0]  = io_lsTopdownInfo_0_s1_vaddr_bits;
    lsTdS2Valid[0]  = io_lsTopdownInfo_0_s2_paddr_valid;
    lsTdS2RobIdx[0] = io_lsTopdownInfo_0_s2_robIdx;
    lsTdS2Paddr[0]  = io_lsTopdownInfo_0_s2_paddr_bits;
    lsTdS1Valid[1]  = io_lsTopdownInfo_1_s1_vaddr_valid;
    lsTdS1RobIdx[1] = io_lsTopdownInfo_1_s1_robIdx;
    lsTdS1Vaddr[1]  = io_lsTopdownInfo_1_s1_vaddr_bits;
    lsTdS2Valid[1]  = io_lsTopdownInfo_1_s2_paddr_valid;
    lsTdS2RobIdx[1] = io_lsTopdownInfo_1_s2_robIdx;
    lsTdS2Paddr[1]  = io_lsTopdownInfo_1_s2_paddr_bits;
    lsTdS1Valid[2]  = io_lsTopdownInfo_2_s1_vaddr_valid;
    lsTdS1RobIdx[2] = io_lsTopdownInfo_2_s1_robIdx;
    lsTdS1Vaddr[2]  = io_lsTopdownInfo_2_s1_vaddr_bits;
    lsTdS2Valid[2]  = io_lsTopdownInfo_2_s2_paddr_valid;
    lsTdS2RobIdx[2] = io_lsTopdownInfo_2_s2_robIdx;
    lsTdS2Paddr[2]  = io_lsTopdownInfo_2_s2_paddr_bits;
  end

  // ---- 队头的调试读口 ----
  // 下标 8 位、深度 160 —— FMR_ELAB-147 的形状，一律循环+比较。
  logic [FUTYPE_W-1:0] deqHeadDbgFuType;
  logic               headLsIssued;
  logic               headS1Valid, headS2Valid;
  logic [VADDR_W-1:0] headS1Vaddr;
  logic [PADDR_W-1:0] headS2Paddr;
  logic [VADDR_W-1:0] storeDbgPc [2];

  // ★★ 越界读：Chisel 的 Vec(160) 用 8 位下标读，firtool 展成 **256 格**的查找表，
  //    160..255 这 96 格全部填**条目 0** —— 本模块 40 张这样的表**无一例外**
  //    （scripts/ 里那段一次性普查：total 256-wide _GEN decls: 40 / pad==elem0: 40）。
  //    所以「没命中」时的默认值不是 0，是**条目 0 的值**。★★
  //    UT 首跑就是靠 io_storeDebugInfo_0_pc（robidx 是 tb 直驱的输入，必然会 >=160）
  //    抓到的：golden 给 pc[0]，原写法给 0。
  always_comb begin
    deqHeadInstr     = debug_microOp_debugReg_instr[0];              // _GEN_211
    deqHeadDbgFuType = debug_microOp_debugReg_debug_fuType[0];       // _GEN_224
    headS1Valid      = debug_lsTopdownInfo_s1_vaddr_valid[0];        // _GEN_3534
    headS1Vaddr      = debug_lsTopdownInfo_s1_vaddr_bits[0];         // _GEN_3535
    headS2Valid      = debug_lsTopdownInfo_s2_paddr_valid[0];        // _GEN_3536
    headS2Paddr      = debug_lsTopdownInfo_s2_paddr_bits[0];         // _GEN_3537
    storeDbgPc[0]    = debug_microOp_debugReg_pc[0];                 // _GEN_212
    storeDbgPc[1]    = debug_microOp_debugReg_pc[0];                 // _GEN_212
    // ★headLsIssued 的越界值不是 debug_lsIssued[0] 那么直白★：golden 是
    //   debug_lsIssue_0 = (|deqPtr) ? debug_lsIssued_0 : io_debugHeadLsIssue
    // 而 _GEN_51 的 160..255 格填的正是 debug_lsIssue_0。下标 >=160 时 |deqPtr 恒真
    // ⇒ 越界值 = debug_lsIssued[0]。
    headLsIssued     = debug_lsIssued[0];
    for (int i = 0; i < ROB_SIZE; i++) begin
      if (deqPtrValue[0] == PTR_W'(i)) begin
        deqHeadInstr     = debug_microOp_debugReg_instr[i];
        deqHeadDbgFuType = debug_microOp_debugReg_debug_fuType[i];
        headS1Valid      = debug_lsTopdownInfo_s1_vaddr_valid[i];
        headS1Vaddr      = debug_lsTopdownInfo_s1_vaddr_bits[i];
        headS2Valid      = debug_lsTopdownInfo_s2_paddr_valid[i];
        headS2Paddr      = debug_lsTopdownInfo_s2_paddr_bits[i];
        // ★真 bug（UT 首跑抓到）★：debug_lsIssue 是 WireDefault(debug_lsIssued)
        // 之后把队头那一条**整个覆盖**成 io_debugHeadLsIssue，**不是或上去**。
        // golden：debug_lsIssue_k = (deqPtr==k) ? io_debugHeadLsIssue : debug_lsIssued_k，
        // 而输出就在 deqPtr 处取值 ⇒ 命中时结果**只**取决于 io_debugHeadLsIssue。
        // 原写法 `debug_lsIssued[i] | io_debugHeadLsIssue` 在
        // lsIssued=1 / head=0 时给 1，golden 给 0（首跑征状正是 g=0 x=1）。
        headLsIssued     = io_debugHeadLsIssue;
      end
      if (io_storeDebugInfo_0_robidx_value == PTR_W'(i))
        storeDbgPc[0] = debug_microOp_debugReg_pc[i];
      if (io_storeDebugInfo_1_robidx_value == PTR_W'(i))
        storeDbgPc[1] = debug_microOp_debugReg_pc[i];
    end
  end

  assign io_debugRobHead_debug_fuType = deqHeadDbgFuType;
  assign io_storeDebugInfo_0_pc       = storeDbgPc[0];
  assign io_storeDebugInfo_1_pc       = storeDbgPc[1];
  assign io_debugTopDown_toCore_robHeadVaddr_valid = headS1Valid;
  assign io_debugTopDown_toCore_robHeadVaddr_bits  = headS1Vaddr;
  assign io_debugTopDown_toCore_robHeadPaddr_valid = headS2Valid;
  assign io_debugTopDown_toCore_robHeadPaddr_bits  = headS2Paddr;
  assign io_debugTopDown_toDispatch_robHeadLsIssue = headLsIssued;

  // ---- debug_VecOtherPdest：向量 load 写回时按 vdIdx 记下另一个 pdest ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < ROB_SIZE; i++) begin
        debug_VecOtherPdest_0[i] <= {PREG_W{1'b0}};
        debug_VecOtherPdest_1[i] <= {PREG_W{1'b0}};
        debug_VecOtherPdest_2[i] <= {PREG_W{1'b0}};
        debug_VecOtherPdest_3[i] <= {PREG_W{1'b0}};
        debug_VecOtherPdest_4[i] <= {PREG_W{1'b0}};
        debug_VecOtherPdest_5[i] <= {PREG_W{1'b0}};
        debug_VecOtherPdest_6[i] <= {PREG_W{1'b0}};
        debug_VecOtherPdest_7[i] <= {PREG_W{1'b0}};
      end
    end else begin
      for (int i = 0; i < ROB_SIZE; i++)
        for (int k = 0; k < VLD_WB_N; k++)
          if (vldWbValid[k] & (vldWbRobIdx[k] == PTR_W'(i)) & robEntries_valid[i]
              & (vldWbVecWen[k] | vldWbV0Wen[k])) begin
            if (vldWbVdIdx[k] == 3'd0) debug_VecOtherPdest_0[i] <= vldWbPdest[k];
            if (vldWbVdIdx[k] == 3'd1) debug_VecOtherPdest_1[i] <= vldWbPdest[k];
            if (vldWbVdIdx[k] == 3'd2) debug_VecOtherPdest_2[i] <= vldWbPdest[k];
            if (vldWbVdIdx[k] == 3'd3) debug_VecOtherPdest_3[i] <= vldWbPdest[k];
            if (vldWbVdIdx[k] == 3'd4) debug_VecOtherPdest_4[i] <= vldWbPdest[k];
            if (vldWbVdIdx[k] == 3'd5) debug_VecOtherPdest_5[i] <= vldWbPdest[k];
            if (vldWbVdIdx[k] == 3'd6) debug_VecOtherPdest_6[i] <= vldWbPdest[k];
            if (vldWbVdIdx[k] == 3'd7) debug_VecOtherPdest_7[i] <= vldWbPdest[k];
          end
    end
  end

  always_comb begin
    vldWbValid[0]  = io_exuWriteback_23_valid;
    vldWbRobIdx[0] = io_exuWriteback_23_bits_robIdx_value;
    vldWbVdIdx[0]  = io_exuWriteback_23_bits_vls_vdIdx;
    vldWbPdest[0]  = io_exuWriteback_23_bits_pdest;
    vldWbVecWen[0] = io_exuWriteback_23_bits_vecWen;
    vldWbV0Wen[0]  = io_exuWriteback_23_bits_v0Wen;
    vldWbValid[1]  = io_exuWriteback_24_valid;
    vldWbRobIdx[1] = io_exuWriteback_24_bits_robIdx_value;
    vldWbVdIdx[1]  = io_exuWriteback_24_bits_vls_vdIdx;
    vldWbPdest[1]  = io_exuWriteback_24_bits_pdest;
    vldWbVecWen[1] = io_exuWriteback_24_bits_vecWen;
    vldWbV0Wen[1]  = io_exuWriteback_24_bits_v0Wen;
  end


  // ==========================================================================
  // §23 性能事件（io_perf_0..18）
  // ==========================================================================
  // generatePerfEvent() 出来的 19 个事件，每个都**打两拍**再送出去
  // （io_perf_<i>_value_REG -> _REG_1 -> 零扩到 6 位的端口）。
  // 宽度按事件不同：1 位的布尔、4 位的条数、11 位的 retireCounter 各不相同，
  // 所以端口上的零扩位数也不同（golden 逐条可核对）。
  logic       io_perf_0_value_REG,  io_perf_0_value_REG_1;
  logic       io_perf_1_value_REG,  io_perf_1_value_REG_1;
  logic       io_perf_2_value_REG,  io_perf_2_value_REG_1;
  logic       io_perf_3_value_REG,  io_perf_3_value_REG_1;
  logic [3:0] io_perf_4_value_REG,  io_perf_4_value_REG_1;
  logic [10:0] io_perf_5_value_REG, io_perf_5_value_REG_1;
  logic [3:0] io_perf_6_value_REG,  io_perf_6_value_REG_1;
  logic [3:0] io_perf_7_value_REG,  io_perf_7_value_REG_1;
  logic [3:0] io_perf_8_value_REG,  io_perf_8_value_REG_1;
  logic [3:0] io_perf_9_value_REG,  io_perf_9_value_REG_1;
  logic [3:0] io_perf_10_value_REG, io_perf_10_value_REG_1;
  logic       io_perf_11_value_REG, io_perf_11_value_REG_1;
  logic       io_perf_12_value_REG, io_perf_12_value_REG_1;
  logic       io_perf_13_value_REG, io_perf_13_value_REG_1;
  logic       io_perf_14_value_REG, io_perf_14_value_REG_1;
  logic       io_perf_15_value_REG, io_perf_15_value_REG_1;
  logic [2:0] io_perf_16_value_REG, io_perf_16_value_REG_1;
  logic       io_perf_17_value_REG, io_perf_17_value_REG_1;
  logic       io_perf_18_value_REG, io_perf_18_value_REG_1;

  // 提交出来的三类指令（load / branch / store），打一拍再数
  logic commitLoadVec   [COMMIT_W];
  logic commitBranchVec [COMMIT_W];
  logic commitStoreVec  [COMMIT_W];
  always_comb begin
    for (int i = 0; i < COMMIT_W; i++) begin
      commitLoadVec[i]   = commitValidOut[i] & (commitInfo[i].commitType == CT_LOAD);
      commitBranchVec[i] = commitValidOut[i] & (commitInfo[i].commitType == CT_BRANCH);
      commitStoreVec[i]  = commitValidOut[i] & (commitInfo[i].commitType == CT_STORE);
    end
  end

  always_ff @(posedge clock) begin
    if (io_commits_isCommit) begin
      perfEvents_r_0   <= commitLoadVec[0];   perfEvents_r_1   <= commitLoadVec[1];
      perfEvents_r_2   <= commitLoadVec[2];   perfEvents_r_3   <= commitLoadVec[3];
      perfEvents_r_4   <= commitLoadVec[4];   perfEvents_r_5   <= commitLoadVec[5];
      perfEvents_r_6   <= commitLoadVec[6];   perfEvents_r_7   <= commitLoadVec[7];
      perfEvents_r_1_0 <= commitBranchVec[0]; perfEvents_r_1_1 <= commitBranchVec[1];
      perfEvents_r_1_2 <= commitBranchVec[2]; perfEvents_r_1_3 <= commitBranchVec[3];
      perfEvents_r_1_4 <= commitBranchVec[4]; perfEvents_r_1_5 <= commitBranchVec[5];
      perfEvents_r_1_6 <= commitBranchVec[6]; perfEvents_r_1_7 <= commitBranchVec[7];
      perfEvents_r_2_0 <= commitStoreVec[0];  perfEvents_r_2_1 <= commitStoreVec[1];
      perfEvents_r_2_2 <= commitStoreVec[2];  perfEvents_r_2_3 <= commitStoreVec[3];
      perfEvents_r_2_4 <= commitStoreVec[4];  perfEvents_r_2_5 <= commitStoreVec[5];
      perfEvents_r_2_6 <= commitStoreVec[6];  perfEvents_r_2_7 <= commitStoreVec[7];
    end
  end

  // 本拍提交/走回了几条
  logic [3:0] commitCnt, walkCnt, loadCnt, branchCnt, storeCnt;
  logic [2:0] brhJump;
  always_comb begin
    commitCnt = 4'h0; walkCnt = 4'h0;
    loadCnt   = 4'h0; branchCnt = 4'h0; storeCnt = 4'h0;
    for (int i = 0; i < COMMIT_W; i++) begin
      commitCnt = commitCnt + 4'(commitValidOut[i]);
      walkCnt   = walkCnt   + 4'(shouldWalkVec[i]);
    end
    loadCnt   = 4'(perfEvents_r_0)   + 4'(perfEvents_r_1)
              + 4'(perfEvents_r_2)   + 4'(perfEvents_r_3)
              + 4'(perfEvents_r_4)   + 4'(perfEvents_r_5)
              + 4'(perfEvents_r_6)   + 4'(perfEvents_r_7);
    branchCnt = 4'(perfEvents_r_1_0) + 4'(perfEvents_r_1_1)
              + 4'(perfEvents_r_1_2) + 4'(perfEvents_r_1_3)
              + 4'(perfEvents_r_1_4) + 4'(perfEvents_r_1_5)
              + 4'(perfEvents_r_1_6) + 4'(perfEvents_r_1_7);
    storeCnt  = 4'(perfEvents_r_2_0) + 4'(perfEvents_r_2_1)
              + 4'(perfEvents_r_2_2) + 4'(perfEvents_r_2_3)
              + 4'(perfEvents_r_2_4) + 4'(perfEvents_r_2_5)
              + 4'(perfEvents_r_2_6) + 4'(perfEvents_r_2_7);
    // ★branchWBs 与 jmpWBs 在本配置下是同一组端口★（{1,3,5} 同时带 brh 和 jmp），
    //   所以 PopCount(branchWBs ++ jmpWBs) 就是那三个 valid 的和**乘二**。
    //   golden 里同一个子表达式原样出现两遍，就是这个意思。
    brhJump = 3'({1'b0, 2'(2'(io_exuWriteback_1_valid) + 2'(io_exuWriteback_3_valid)
                           + 2'(io_exuWriteback_5_valid))})
            + 3'({1'b0, 2'(2'(io_exuWriteback_1_valid) + 2'(io_exuWriteback_3_valid)
                           + 2'(io_exuWriteback_5_valid))});
  end

  always_ff @(posedge clock) begin
    io_perf_0_value_REG  <= io_flushOut_valid & intrEnable;
    io_perf_1_value_REG  <= io_flushOut_valid & deqHasException;
    io_perf_2_value_REG  <= io_flushOut_valid & isFlushPipe;
    io_perf_3_value_REG  <= io_flushOut_valid & isFlushPipe & deqHasReplayInst;
    io_perf_4_value_REG  <= io_commits_isCommit ? commitCnt : 4'h0;
    io_perf_5_value_REG  <= retireCounter;
    io_perf_6_value_REG  <= isCommitReg_last_REG ? fuseCommitCnt : 4'h0;
    io_perf_7_value_REG  <= isCommitReg_last_REG ? loadCnt   : 4'h0;
    io_perf_8_value_REG  <= isCommitReg_last_REG ? branchCnt : 4'h0;
    io_perf_9_value_REG  <= isCommitReg_last_REG ? storeCnt  : 4'h0;
    io_perf_10_value_REG <= state ? walkCnt : 4'h0;
    io_perf_11_value_REG <= state;
    // 队列占用的四分位（RobSize=160 => 40 / 80 / 120）
    io_perf_12_value_REG <= numValidEntries < PTR_W'(41);
    io_perf_13_value_REG <= (numValidEntries > PTR_W'(40)) & (numValidEntries < PTR_W'(81));
    io_perf_14_value_REG <= (numValidEntries > PTR_W'(80)) & (numValidEntries < PTR_W'(121));
    io_perf_15_value_REG <= numValidEntries > PTR_W'(120);
    io_perf_16_value_REG <= brhJump;
    io_perf_17_value_REG <= io_redirect_valid & io_redirect_bits_cfiUpdate_isMisPred;
    io_perf_18_value_REG <= io_redirect_valid;
    io_error_0_REG       <= commitStuckCounter_io_overflow;

    io_perf_0_value_REG_1  <= io_perf_0_value_REG;
    io_perf_1_value_REG_1  <= io_perf_1_value_REG;
    io_perf_2_value_REG_1  <= io_perf_2_value_REG;
    io_perf_3_value_REG_1  <= io_perf_3_value_REG;
    io_perf_4_value_REG_1  <= io_perf_4_value_REG;
    io_perf_5_value_REG_1  <= io_perf_5_value_REG;
    io_perf_6_value_REG_1  <= io_perf_6_value_REG;
    io_perf_7_value_REG_1  <= io_perf_7_value_REG;
    io_perf_8_value_REG_1  <= io_perf_8_value_REG;
    io_perf_9_value_REG_1  <= io_perf_9_value_REG;
    io_perf_10_value_REG_1 <= io_perf_10_value_REG;
    io_perf_11_value_REG_1 <= io_perf_11_value_REG;
    io_perf_12_value_REG_1 <= io_perf_12_value_REG;
    io_perf_13_value_REG_1 <= io_perf_13_value_REG;
    io_perf_14_value_REG_1 <= io_perf_14_value_REG;
    io_perf_15_value_REG_1 <= io_perf_15_value_REG;
    io_perf_16_value_REG_1 <= io_perf_16_value_REG;
    io_perf_17_value_REG_1 <= io_perf_17_value_REG;
    io_perf_18_value_REG_1 <= io_perf_18_value_REG;
    io_error_0_REG_1       <= io_error_0_REG;
  end

  assign io_perf_0_value  = {5'h0, io_perf_0_value_REG_1};
  assign io_perf_1_value  = {5'h0, io_perf_1_value_REG_1};
  assign io_perf_2_value  = {5'h0, io_perf_2_value_REG_1};
  assign io_perf_3_value  = {5'h0, io_perf_3_value_REG_1};
  assign io_perf_4_value  = {2'h0, io_perf_4_value_REG_1};
  assign io_perf_5_value  = io_perf_5_value_REG_1[5:0];
  assign io_perf_6_value  = {2'h0, io_perf_6_value_REG_1};
  assign io_perf_7_value  = {2'h0, io_perf_7_value_REG_1};
  assign io_perf_8_value  = {2'h0, io_perf_8_value_REG_1};
  assign io_perf_9_value  = {2'h0, io_perf_9_value_REG_1};
  assign io_perf_10_value = {2'h0, io_perf_10_value_REG_1};
  assign io_perf_11_value = {5'h0, io_perf_11_value_REG_1};
  assign io_perf_12_value = {5'h0, io_perf_12_value_REG_1};
  assign io_perf_13_value = {5'h0, io_perf_13_value_REG_1};
  assign io_perf_14_value = {5'h0, io_perf_14_value_REG_1};
  assign io_perf_15_value = {5'h0, io_perf_15_value_REG_1};
  assign io_perf_16_value = {3'h0, io_perf_16_value_REG_1};
  assign io_perf_17_value = {5'h0, io_perf_17_value_REG_1};
  assign io_perf_18_value = {5'h0, io_perf_18_value_REG_1};


  // ==========================================================================
  // §24 difftest 打包口（gatewayIn_packed_*_bore）
  // ==========================================================================
  // difftest 的三种事件被打包成宽总线从 Rob 直接钻出去（DifftestModule 的 bore）：
  //   packed_(6+2i) = DiffInstrCommit 第 i 槽（322 位）
  //   packed_(7+2i) = DiffLoadEvent   第 i 槽（92 位）
  //   packed_22     = DiffTrapEvent（266 位，整个 Rob 只有一份）
  // ★字段顺序就是 golden 里那个拼接的顺序★，不是 Bundle 的声明顺序；
  //   错一位，difftest 那边整条记录都读错。
  //
  // ★dt_pcTransType 的读口编号与槽号是反的★（槽 0 走 R7、槽 7 走 R0），
  //   和写口 W5<-enq0 那个反法是一回事。照槽号取会整体错位。

  localparam int V0_PHY_REGS = 22;   // golden: `+ 8'h16`

  logic [31:0]         dbgInstr   [COMMIT_W];
  logic [VADDR_W-1:0]  dbgPc      [COMMIT_W];
  logic [FUTYPE_W-1:0] dbgFuType  [COMMIT_W];
  logic [FUOPTYPE_W-1:0] dbgFuOpType [COMMIT_W];
  logic [LQ_PTR_W-1:0] dbgLqIdx   [COMMIT_W];
  logic [SQ_PTR_W-1:0] dbgSqIdx   [COMMIT_W];
  logic [XLEN-1:0]     dbgExuData [COMMIT_W];
  logic                dbgSkipDiff[COMMIT_W];
  logic [PADDR_W-1:0]  dbgPaddr   [COMMIT_W];
  logic [PREG_W-1:0]   dbgOtherPdest [COMMIT_W][8];

  always_comb begin
    for (int s = 0; s < COMMIT_W; s++) begin
      // ★越界回绕到条目 0★（见 §21 头上的「越界读」总说明）：这一组的 golden
      // 查找表分别是 _GEN_211/212/213/214/222/223/3538/3540|3541|3542/3543/3544..3551，
      // 每一张的 160..255 格填的都是条目 0。
      dbgInstr[s]    = debug_microOp_debugReg_instr[0];
      dbgPc[s]       = debug_microOp_debugReg_pc[0];
      dbgFuType[s]   = debug_microOp_debugReg_fuType[0];
      dbgFuOpType[s] = debug_microOp_debugReg_fuOpType[0];
      dbgLqIdx[s]    = debug_microOp_debugReg_lqIdx_value[0];
      dbgSqIdx[s]    = debug_microOp_debugReg_sqIdx_value[0];
      dbgExuData[s]  = debug_exuData[0];
      dbgSkipDiff[s] = dt_exuDebug_isMMIO[0] | dt_exuDebug_isNCIO[0]
                     | dt_exuDebug_isPerfCnt[0];
      dbgPaddr[s]    = dt_exuDebug_paddr[0];
      dbgOtherPdest[s][0] = debug_VecOtherPdest_0[0];
      dbgOtherPdest[s][1] = debug_VecOtherPdest_1[0];
      dbgOtherPdest[s][2] = debug_VecOtherPdest_2[0];
      dbgOtherPdest[s][3] = debug_VecOtherPdest_3[0];
      dbgOtherPdest[s][4] = debug_VecOtherPdest_4[0];
      dbgOtherPdest[s][5] = debug_VecOtherPdest_5[0];
      dbgOtherPdest[s][6] = debug_VecOtherPdest_6[0];
      dbgOtherPdest[s][7] = debug_VecOtherPdest_7[0];
      for (int i = 0; i < ROB_SIZE; i++)
        if (deqPtrValue[s] == PTR_W'(i)) begin
          dbgInstr[s]    = debug_microOp_debugReg_instr[i];
          dbgPc[s]       = debug_microOp_debugReg_pc[i];
          dbgFuType[s]   = debug_microOp_debugReg_fuType[i];
          dbgFuOpType[s] = debug_microOp_debugReg_fuOpType[i];
          dbgLqIdx[s]    = debug_microOp_debugReg_lqIdx_value[i];
          dbgSqIdx[s]    = debug_microOp_debugReg_sqIdx_value[i];
          dbgExuData[s]  = debug_exuData[i];
          // DebugBundle.isSkipDiff = isMMIO | isNCIO | isPerfCnt
          dbgSkipDiff[s] = dt_exuDebug_isMMIO[i] | dt_exuDebug_isNCIO[i]
                         | dt_exuDebug_isPerfCnt[i];
          dbgPaddr[s]    = dt_exuDebug_paddr[i];
          dbgOtherPdest[s][0] = debug_VecOtherPdest_0[i];
          dbgOtherPdest[s][1] = debug_VecOtherPdest_1[i];
          dbgOtherPdest[s][2] = debug_VecOtherPdest_2[i];
          dbgOtherPdest[s][3] = debug_VecOtherPdest_3[i];
          dbgOtherPdest[s][4] = debug_VecOtherPdest_4[i];
          dbgOtherPdest[s][5] = debug_VecOtherPdest_5[i];
          dbgOtherPdest[s][6] = debug_VecOtherPdest_6[i];
          dbgOtherPdest[s][7] = debug_VecOtherPdest_7[i];
        end
    end
  end

  logic [7:0]  dtCoreid;
  assign dtCoreid = {2'h0, io_hartId};

  logic                dtIsVLoad  [COMMIT_W];
  logic                dtSkip     [COMMIT_W];
  logic                dtValid    [COMMIT_W];
  logic                dtV0wen    [COMMIT_W];
  logic [8:0]          dtWpdest   [COMMIT_W];
  logic [7:0]          dtWdest    [COMMIT_W];
  logic [7:0]          dtNFused   [COMMIT_W];
  logic [XLEN-1:0]     dtPc       [COMMIT_W];
  logic [8:0]          dtOtherW   [COMMIT_W][16];
  logic                dtPcSext   [COMMIT_W];
  logic                dtIsAtomic [COMMIT_W];
  logic                dtIsLoadFu [COMMIT_W];
  logic                dtLoadValid[COMMIT_W];
  logic                trapVec    [COMMIT_W];

  always_comb begin
    for (int s = 0; s < COMMIT_W; s++) begin
      automatic logic [PREG_W-1:0] vd0;
      dtIsVLoad[s] = commitInfo[s].isVls & (commitInfo[s].commitType == CT_LOAD);
      dtSkip[s]    = ~commitInfo[s].basicDebug_eliminatedMove & dbgSkipDiff[s];
      dtValid[s]   = commitValidOut[s] & io_commits_isCommit;
      dtV0wen[s]   = commitValidOut[s]
                   & (commitInfo[s].basicDebug_v0Wen
                      | (dtIsVLoad[s] & (commitInfo[s].basicDebug_vd == LREG_W'(0))));
      dtWpdest[s]  = {1'b0, commitInfo[s].basicDebug_pdest};
      dtWdest[s]   = {2'h0, (dtIsVLoad[s] ? commitInfo[s].basicDebug_vd
                                          : commitInfo[s].basicDebug_ldest)};
      dtNFused[s]  = {5'h0, 3'(3'(commitInfo[s].commitType[2])
                               + 3'(commitInfo[s].instrSize - INSTRSIZE_W'(1)))};
      // 第 0 个 vec 目的寄存器：v0wen 时不加 V0PhyRegs 偏移，其余都加
      vd0 = dtV0wen[s] ? dbgOtherPdest[s][0]
                       : PREG_W'(dbgOtherPdest[s][0] + PREG_W'(V0_PHY_REGS));
      dtOtherW[s][0] = {vd0, 1'b0};
      dtOtherW[s][1] = 9'({vd0, 1'b0} + 9'h1);
      for (int k = 1; k < 8; k++) begin
        automatic logic [PREG_W-1:0] vdk;
        vdk = PREG_W'(dbgOtherPdest[s][k] + PREG_W'(V0_PHY_REGS));
        dtOtherW[s][2*k]     = {vdk, 1'b0};
        dtOtherW[s][2*k + 1] = 9'({vdk, 1'b0} + 9'h1);
      end
      dtPc[s] = {dtPcSext[s] ? {14{dbgPc[s][VADDR_W-1]}} : 14'h0, dbgPc[s]};
      dtIsAtomic[s] = dbgFuType[s][FU_MOU];
      dtIsLoadFu[s] = dbgFuType[s][FU_LDU];
      dtLoadValid[s] = dtValid[s]
                     & (dtIsAtomic[s] | dtIsLoadFu[s] | dtIsVLoad[s]) & ~dtSkip[s];
      trapVec[s] = io_commits_isCommit & commitValidOut[s]
                 & commitInfo[s].basicDebug_isXSTrap;
    end
  end

  // ★读口编号与槽号相反★：槽 s 用 R(7-s)

  assign dtPcSext[0] = |dt_pcTransType_ext_R7_data;
  assign dtPcSext[1] = |dt_pcTransType_ext_R6_data;
  assign dtPcSext[2] = |dt_pcTransType_ext_R5_data;
  assign dtPcSext[3] = |dt_pcTransType_ext_R4_data;
  assign dtPcSext[4] = |dt_pcTransType_ext_R3_data;
  assign dtPcSext[5] = |dt_pcTransType_ext_R2_data;
  assign dtPcSext[6] = |dt_pcTransType_ext_R1_data;
  assign dtPcSext[7] = |dt_pcTransType_ext_R0_data;

  // ---- 打包 ----
  assign gatewayIn_packed_6_bore =
      {dtValid[0], dtSkip[0], commitInfo[0].isRVC,
       commitValidOut[0] & commitInfo[0].rfWen & (|commitInfo[0].basicDebug_ldest),
       commitValidOut[0] & commitInfo[0].basicDebug_fpWen,
       commitValidOut[0] & commitInfo[0].basicDebug_vecWen,
       dtV0wen[0], dtWpdest[0], dtWdest[0],
       dtOtherW[0][15],
       dtOtherW[0][14],
       dtOtherW[0][13],
       dtOtherW[0][12],
       dtOtherW[0][11],
       dtOtherW[0][10],
       dtOtherW[0][9],
       dtOtherW[0][8],
       dtOtherW[0][7],
       dtOtherW[0][6],
       dtOtherW[0][5],
       dtOtherW[0][4],
       dtOtherW[0][3],
       dtOtherW[0][2],
       dtOtherW[0][1],
       dtOtherW[0][0],
       dtPc[0], dbgInstr[0], {2'h0, deqPtrValue[0]}, dbgLqIdx[0], {1'b0, dbgSqIdx[0]},
       commitInfo[0].commitType == CT_LOAD, commitInfo[0].commitType == CT_STORE,
       dtNFused[0], 8'h0 /* special */, dtCoreid, 8'd0 /* index */};
  assign gatewayIn_packed_7_bore =
      {dtLoadValid[0], {16'h0, dbgPaddr[0]}, dbgFuOpType[0][7:0],
       dtIsAtomic[0], dtIsLoadFu[0], dtIsVLoad[0], dtCoreid, 8'd0};
  assign gatewayIn_packed_8_bore =
      {dtValid[1], dtSkip[1], commitInfo[1].isRVC,
       commitValidOut[1] & commitInfo[1].rfWen & (|commitInfo[1].basicDebug_ldest),
       commitValidOut[1] & commitInfo[1].basicDebug_fpWen,
       commitValidOut[1] & commitInfo[1].basicDebug_vecWen,
       dtV0wen[1], dtWpdest[1], dtWdest[1],
       dtOtherW[1][15],
       dtOtherW[1][14],
       dtOtherW[1][13],
       dtOtherW[1][12],
       dtOtherW[1][11],
       dtOtherW[1][10],
       dtOtherW[1][9],
       dtOtherW[1][8],
       dtOtherW[1][7],
       dtOtherW[1][6],
       dtOtherW[1][5],
       dtOtherW[1][4],
       dtOtherW[1][3],
       dtOtherW[1][2],
       dtOtherW[1][1],
       dtOtherW[1][0],
       dtPc[1], dbgInstr[1], {2'h0, deqPtrValue[1]}, dbgLqIdx[1], {1'b0, dbgSqIdx[1]},
       commitInfo[1].commitType == CT_LOAD, commitInfo[1].commitType == CT_STORE,
       dtNFused[1], 8'h0 /* special */, dtCoreid, 8'd1 /* index */};
  assign gatewayIn_packed_9_bore =
      {dtLoadValid[1], {16'h0, dbgPaddr[1]}, dbgFuOpType[1][7:0],
       dtIsAtomic[1], dtIsLoadFu[1], dtIsVLoad[1], dtCoreid, 8'd1};
  assign gatewayIn_packed_10_bore =
      {dtValid[2], dtSkip[2], commitInfo[2].isRVC,
       commitValidOut[2] & commitInfo[2].rfWen & (|commitInfo[2].basicDebug_ldest),
       commitValidOut[2] & commitInfo[2].basicDebug_fpWen,
       commitValidOut[2] & commitInfo[2].basicDebug_vecWen,
       dtV0wen[2], dtWpdest[2], dtWdest[2],
       dtOtherW[2][15],
       dtOtherW[2][14],
       dtOtherW[2][13],
       dtOtherW[2][12],
       dtOtherW[2][11],
       dtOtherW[2][10],
       dtOtherW[2][9],
       dtOtherW[2][8],
       dtOtherW[2][7],
       dtOtherW[2][6],
       dtOtherW[2][5],
       dtOtherW[2][4],
       dtOtherW[2][3],
       dtOtherW[2][2],
       dtOtherW[2][1],
       dtOtherW[2][0],
       dtPc[2], dbgInstr[2], {2'h0, deqPtrValue[2]}, dbgLqIdx[2], {1'b0, dbgSqIdx[2]},
       commitInfo[2].commitType == CT_LOAD, commitInfo[2].commitType == CT_STORE,
       dtNFused[2], 8'h0 /* special */, dtCoreid, 8'd2 /* index */};
  assign gatewayIn_packed_11_bore =
      {dtLoadValid[2], {16'h0, dbgPaddr[2]}, dbgFuOpType[2][7:0],
       dtIsAtomic[2], dtIsLoadFu[2], dtIsVLoad[2], dtCoreid, 8'd2};
  assign gatewayIn_packed_12_bore =
      {dtValid[3], dtSkip[3], commitInfo[3].isRVC,
       commitValidOut[3] & commitInfo[3].rfWen & (|commitInfo[3].basicDebug_ldest),
       commitValidOut[3] & commitInfo[3].basicDebug_fpWen,
       commitValidOut[3] & commitInfo[3].basicDebug_vecWen,
       dtV0wen[3], dtWpdest[3], dtWdest[3],
       dtOtherW[3][15],
       dtOtherW[3][14],
       dtOtherW[3][13],
       dtOtherW[3][12],
       dtOtherW[3][11],
       dtOtherW[3][10],
       dtOtherW[3][9],
       dtOtherW[3][8],
       dtOtherW[3][7],
       dtOtherW[3][6],
       dtOtherW[3][5],
       dtOtherW[3][4],
       dtOtherW[3][3],
       dtOtherW[3][2],
       dtOtherW[3][1],
       dtOtherW[3][0],
       dtPc[3], dbgInstr[3], {2'h0, deqPtrValue[3]}, dbgLqIdx[3], {1'b0, dbgSqIdx[3]},
       commitInfo[3].commitType == CT_LOAD, commitInfo[3].commitType == CT_STORE,
       dtNFused[3], 8'h0 /* special */, dtCoreid, 8'd3 /* index */};
  assign gatewayIn_packed_13_bore =
      {dtLoadValid[3], {16'h0, dbgPaddr[3]}, dbgFuOpType[3][7:0],
       dtIsAtomic[3], dtIsLoadFu[3], dtIsVLoad[3], dtCoreid, 8'd3};
  assign gatewayIn_packed_14_bore =
      {dtValid[4], dtSkip[4], commitInfo[4].isRVC,
       commitValidOut[4] & commitInfo[4].rfWen & (|commitInfo[4].basicDebug_ldest),
       commitValidOut[4] & commitInfo[4].basicDebug_fpWen,
       commitValidOut[4] & commitInfo[4].basicDebug_vecWen,
       dtV0wen[4], dtWpdest[4], dtWdest[4],
       dtOtherW[4][15],
       dtOtherW[4][14],
       dtOtherW[4][13],
       dtOtherW[4][12],
       dtOtherW[4][11],
       dtOtherW[4][10],
       dtOtherW[4][9],
       dtOtherW[4][8],
       dtOtherW[4][7],
       dtOtherW[4][6],
       dtOtherW[4][5],
       dtOtherW[4][4],
       dtOtherW[4][3],
       dtOtherW[4][2],
       dtOtherW[4][1],
       dtOtherW[4][0],
       dtPc[4], dbgInstr[4], {2'h0, deqPtrValue[4]}, dbgLqIdx[4], {1'b0, dbgSqIdx[4]},
       commitInfo[4].commitType == CT_LOAD, commitInfo[4].commitType == CT_STORE,
       dtNFused[4], 8'h0 /* special */, dtCoreid, 8'd4 /* index */};
  assign gatewayIn_packed_15_bore =
      {dtLoadValid[4], {16'h0, dbgPaddr[4]}, dbgFuOpType[4][7:0],
       dtIsAtomic[4], dtIsLoadFu[4], dtIsVLoad[4], dtCoreid, 8'd4};
  assign gatewayIn_packed_16_bore =
      {dtValid[5], dtSkip[5], commitInfo[5].isRVC,
       commitValidOut[5] & commitInfo[5].rfWen & (|commitInfo[5].basicDebug_ldest),
       commitValidOut[5] & commitInfo[5].basicDebug_fpWen,
       commitValidOut[5] & commitInfo[5].basicDebug_vecWen,
       dtV0wen[5], dtWpdest[5], dtWdest[5],
       dtOtherW[5][15],
       dtOtherW[5][14],
       dtOtherW[5][13],
       dtOtherW[5][12],
       dtOtherW[5][11],
       dtOtherW[5][10],
       dtOtherW[5][9],
       dtOtherW[5][8],
       dtOtherW[5][7],
       dtOtherW[5][6],
       dtOtherW[5][5],
       dtOtherW[5][4],
       dtOtherW[5][3],
       dtOtherW[5][2],
       dtOtherW[5][1],
       dtOtherW[5][0],
       dtPc[5], dbgInstr[5], {2'h0, deqPtrValue[5]}, dbgLqIdx[5], {1'b0, dbgSqIdx[5]},
       commitInfo[5].commitType == CT_LOAD, commitInfo[5].commitType == CT_STORE,
       dtNFused[5], 8'h0 /* special */, dtCoreid, 8'd5 /* index */};
  assign gatewayIn_packed_17_bore =
      {dtLoadValid[5], {16'h0, dbgPaddr[5]}, dbgFuOpType[5][7:0],
       dtIsAtomic[5], dtIsLoadFu[5], dtIsVLoad[5], dtCoreid, 8'd5};
  assign gatewayIn_packed_18_bore =
      {dtValid[6], dtSkip[6], commitInfo[6].isRVC,
       commitValidOut[6] & commitInfo[6].rfWen & (|commitInfo[6].basicDebug_ldest),
       commitValidOut[6] & commitInfo[6].basicDebug_fpWen,
       commitValidOut[6] & commitInfo[6].basicDebug_vecWen,
       dtV0wen[6], dtWpdest[6], dtWdest[6],
       dtOtherW[6][15],
       dtOtherW[6][14],
       dtOtherW[6][13],
       dtOtherW[6][12],
       dtOtherW[6][11],
       dtOtherW[6][10],
       dtOtherW[6][9],
       dtOtherW[6][8],
       dtOtherW[6][7],
       dtOtherW[6][6],
       dtOtherW[6][5],
       dtOtherW[6][4],
       dtOtherW[6][3],
       dtOtherW[6][2],
       dtOtherW[6][1],
       dtOtherW[6][0],
       dtPc[6], dbgInstr[6], {2'h0, deqPtrValue[6]}, dbgLqIdx[6], {1'b0, dbgSqIdx[6]},
       commitInfo[6].commitType == CT_LOAD, commitInfo[6].commitType == CT_STORE,
       dtNFused[6], 8'h0 /* special */, dtCoreid, 8'd6 /* index */};
  assign gatewayIn_packed_19_bore =
      {dtLoadValid[6], {16'h0, dbgPaddr[6]}, dbgFuOpType[6][7:0],
       dtIsAtomic[6], dtIsLoadFu[6], dtIsVLoad[6], dtCoreid, 8'd6};
  assign gatewayIn_packed_20_bore =
      {dtValid[7], dtSkip[7], commitInfo[7].isRVC,
       commitValidOut[7] & commitInfo[7].rfWen & (|commitInfo[7].basicDebug_ldest),
       commitValidOut[7] & commitInfo[7].basicDebug_fpWen,
       commitValidOut[7] & commitInfo[7].basicDebug_vecWen,
       dtV0wen[7], dtWpdest[7], dtWdest[7],
       dtOtherW[7][15],
       dtOtherW[7][14],
       dtOtherW[7][13],
       dtOtherW[7][12],
       dtOtherW[7][11],
       dtOtherW[7][10],
       dtOtherW[7][9],
       dtOtherW[7][8],
       dtOtherW[7][7],
       dtOtherW[7][6],
       dtOtherW[7][5],
       dtOtherW[7][4],
       dtOtherW[7][3],
       dtOtherW[7][2],
       dtOtherW[7][1],
       dtOtherW[7][0],
       dtPc[7], dbgInstr[7], {2'h0, deqPtrValue[7]}, dbgLqIdx[7], {1'b0, dbgSqIdx[7]},
       commitInfo[7].commitType == CT_LOAD, commitInfo[7].commitType == CT_STORE,
       dtNFused[7], 8'h0 /* special */, dtCoreid, 8'd7 /* index */};
  assign gatewayIn_packed_21_bore =
      {dtLoadValid[7], {16'h0, dbgPaddr[7]}, dbgFuOpType[7][7:0],
       dtIsAtomic[7], dtIsLoadFu[7], dtIsVLoad[7], dtCoreid, 8'd7};

  // ---- DiffTrapEvent（整个 Rob 一份）----
  // trapCode / trapPC 是 PriorityMux（★第 0 槽优先★，与 walk/提交那几处的
  // 反向优先链不同），一个都没命中时取最后一项。
  logic [XLEN-1:0] trapCode, trapPc;
  logic            hasTrap;
  always_comb begin
    hasTrap  = 1'b0;
    trapCode = dbgExuData[COMMIT_W-1];
    trapPc   = {{14{dbgPc[COMMIT_W-1][VADDR_W-1]}}, dbgPc[COMMIT_W-1]};
    for (int s = COMMIT_W - 1; s >= 0; s--)
      if (trapVec[s]) begin
        trapCode = dbgExuData[s];
        trapPc   = {{14{dbgPc[s][VADDR_W-1]}}, dbgPc[s]};
      end
    for (int s = 0; s < COMMIT_W; s++) hasTrap = hasTrap | trapVec[s];
  end

  assign gatewayIn_packed_22_bore =
      {hasTrap, timer, instrCntReg + {53'h0, retireCounter}, hasWFI,
       trapCode, trapPc, dtCoreid};


endmodule

// ============================================================================
// Rob —— 顶层壳（wrapper）
// ============================================================================
// 这一层不含任何设计逻辑：端口表、局部网、核实例、8 个子模块实例**全部**由
// scripts/gen_rob.py --write 从 golden 机械生成（五个生成区）。
// 手写内容一律在标记之外 —— 这个文件里，标记之外只有这段注释。
//
// 子模块的性质（哪些有自己的 FM target、哪些结构性不闭合）见文件头与
// docs/rob_child_ledger.tsv；Rob 因此只能记**条件性证明**，不得记 PROVEN_DIRECT。
module Rob(
  // BEGIN GENERATED(ports)
  input  logic         clock,
  input  logic         reset,
  input  logic [5:0]   io_hartId,
  input  logic         io_redirect_valid,
  input  logic         io_redirect_bits_robIdx_flag,
  input  logic [7:0]   io_redirect_bits_robIdx_value,
  input  logic         io_redirect_bits_level,
  input  logic         io_redirect_bits_cfiUpdate_isMisPred,
  output logic         io_enq_canAccept,
  output logic         io_enq_canAcceptForDispatch,
  output logic         io_enq_isEmpty,
  input  logic         io_enq_req_0_valid,
  input  logic [31:0]  io_enq_req_0_bits_instr,
  input  logic [49:0]  io_enq_req_0_bits_pc,
  input  logic         io_enq_req_0_bits_exceptionVec_0,
  input  logic         io_enq_req_0_bits_exceptionVec_1,
  input  logic         io_enq_req_0_bits_exceptionVec_2,
  input  logic         io_enq_req_0_bits_exceptionVec_3,
  input  logic         io_enq_req_0_bits_exceptionVec_12,
  input  logic         io_enq_req_0_bits_exceptionVec_20,
  input  logic         io_enq_req_0_bits_exceptionVec_22,
  input  logic         io_enq_req_0_bits_isFetchMalAddr,
  input  logic         io_enq_req_0_bits_hasException,
  input  logic [3:0]   io_enq_req_0_bits_trigger,
  input  logic         io_enq_req_0_bits_preDecodeInfo_isRVC,
  input  logic         io_enq_req_0_bits_crossPageIPFFix,
  input  logic         io_enq_req_0_bits_ftqPtr_flag,
  input  logic [5:0]   io_enq_req_0_bits_ftqPtr_value,
  input  logic [3:0]   io_enq_req_0_bits_ftqOffset,
  input  logic         io_enq_req_0_bits_satpFlushFirstFetchFault,
  input  logic [5:0]   io_enq_req_0_bits_ldest,
  input  logic [34:0]  io_enq_req_0_bits_fuType,
  input  logic [8:0]   io_enq_req_0_bits_fuOpType,
  input  logic         io_enq_req_0_bits_rfWen,
  input  logic         io_enq_req_0_bits_fpWen,
  input  logic         io_enq_req_0_bits_vecWen,
  input  logic         io_enq_req_0_bits_v0Wen,
  input  logic         io_enq_req_0_bits_vlWen,
  input  logic         io_enq_req_0_bits_isXSTrap,
  input  logic         io_enq_req_0_bits_waitForward,
  input  logic         io_enq_req_0_bits_blockBackward,
  input  logic         io_enq_req_0_bits_flushPipe,
  input  logic         io_enq_req_0_bits_vpu_vill,
  input  logic         io_enq_req_0_bits_vpu_vma,
  input  logic         io_enq_req_0_bits_vpu_vta,
  input  logic [1:0]   io_enq_req_0_bits_vpu_vsew,
  input  logic [2:0]   io_enq_req_0_bits_vpu_vlmul,
  input  logic         io_enq_req_0_bits_vpu_specVill,
  input  logic         io_enq_req_0_bits_vpu_specVma,
  input  logic         io_enq_req_0_bits_vpu_specVta,
  input  logic [1:0]   io_enq_req_0_bits_vpu_specVsew,
  input  logic [2:0]   io_enq_req_0_bits_vpu_specVlmul,
  input  logic         io_enq_req_0_bits_vlsInstr,
  input  logic         io_enq_req_0_bits_wfflags,
  input  logic         io_enq_req_0_bits_isMove,
  input  logic         io_enq_req_0_bits_isVset,
  input  logic         io_enq_req_0_bits_firstUop,
  input  logic         io_enq_req_0_bits_lastUop,
  input  logic [6:0]   io_enq_req_0_bits_numWB,
  input  logic [2:0]   io_enq_req_0_bits_commitType,
  input  logic [7:0]   io_enq_req_0_bits_pdest,
  input  logic         io_enq_req_0_bits_robIdx_flag,
  input  logic [7:0]   io_enq_req_0_bits_robIdx_value,
  input  logic [2:0]   io_enq_req_0_bits_instrSize,
  input  logic         io_enq_req_0_bits_dirtyFs,
  input  logic         io_enq_req_0_bits_dirtyVs,
  input  logic [3:0]   io_enq_req_0_bits_traceBlockInPipe_itype,
  input  logic [3:0]   io_enq_req_0_bits_traceBlockInPipe_iretire,
  input  logic         io_enq_req_0_bits_traceBlockInPipe_ilastsize,
  input  logic         io_enq_req_0_bits_eliminatedMove,
  input  logic         io_enq_req_0_bits_snapshot,
  input  logic [63:0]  io_enq_req_0_bits_debugInfo_renameTime,
  input  logic [63:0]  io_enq_req_0_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_enq_req_0_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_enq_req_0_bits_debugInfo_selectTime,
  input  logic [63:0]  io_enq_req_0_bits_debugInfo_issueTime,
  input  logic [63:0]  io_enq_req_0_bits_debugInfo_writebackTime,
  input  logic [6:0]   io_enq_req_0_bits_lqIdx_value,
  input  logic [5:0]   io_enq_req_0_bits_sqIdx_value,
  input  logic         io_enq_req_0_bits_singleStep,
  input  logic         io_enq_req_0_bits_replayInst,
  input  logic [34:0]  io_enq_req_0_bits_debug_fuType,
  input  logic         io_enq_req_0_bits_debug_sim_trig,
  input  logic         io_enq_req_1_valid,
  input  logic [31:0]  io_enq_req_1_bits_instr,
  input  logic [49:0]  io_enq_req_1_bits_pc,
  input  logic         io_enq_req_1_bits_exceptionVec_0,
  input  logic         io_enq_req_1_bits_exceptionVec_1,
  input  logic         io_enq_req_1_bits_exceptionVec_2,
  input  logic         io_enq_req_1_bits_exceptionVec_3,
  input  logic         io_enq_req_1_bits_exceptionVec_12,
  input  logic         io_enq_req_1_bits_exceptionVec_20,
  input  logic         io_enq_req_1_bits_exceptionVec_22,
  input  logic         io_enq_req_1_bits_isFetchMalAddr,
  input  logic         io_enq_req_1_bits_hasException,
  input  logic [3:0]   io_enq_req_1_bits_trigger,
  input  logic         io_enq_req_1_bits_preDecodeInfo_isRVC,
  input  logic         io_enq_req_1_bits_crossPageIPFFix,
  input  logic         io_enq_req_1_bits_ftqPtr_flag,
  input  logic [5:0]   io_enq_req_1_bits_ftqPtr_value,
  input  logic [3:0]   io_enq_req_1_bits_ftqOffset,
  input  logic         io_enq_req_1_bits_satpFlushFirstFetchFault,
  input  logic [5:0]   io_enq_req_1_bits_ldest,
  input  logic [34:0]  io_enq_req_1_bits_fuType,
  input  logic [8:0]   io_enq_req_1_bits_fuOpType,
  input  logic         io_enq_req_1_bits_rfWen,
  input  logic         io_enq_req_1_bits_fpWen,
  input  logic         io_enq_req_1_bits_vecWen,
  input  logic         io_enq_req_1_bits_v0Wen,
  input  logic         io_enq_req_1_bits_vlWen,
  input  logic         io_enq_req_1_bits_isXSTrap,
  input  logic         io_enq_req_1_bits_waitForward,
  input  logic         io_enq_req_1_bits_blockBackward,
  input  logic         io_enq_req_1_bits_flushPipe,
  input  logic         io_enq_req_1_bits_vpu_vill,
  input  logic         io_enq_req_1_bits_vpu_vma,
  input  logic         io_enq_req_1_bits_vpu_vta,
  input  logic [1:0]   io_enq_req_1_bits_vpu_vsew,
  input  logic [2:0]   io_enq_req_1_bits_vpu_vlmul,
  input  logic         io_enq_req_1_bits_vpu_specVill,
  input  logic         io_enq_req_1_bits_vpu_specVma,
  input  logic         io_enq_req_1_bits_vpu_specVta,
  input  logic [1:0]   io_enq_req_1_bits_vpu_specVsew,
  input  logic [2:0]   io_enq_req_1_bits_vpu_specVlmul,
  input  logic         io_enq_req_1_bits_vlsInstr,
  input  logic         io_enq_req_1_bits_wfflags,
  input  logic         io_enq_req_1_bits_isMove,
  input  logic         io_enq_req_1_bits_isVset,
  input  logic         io_enq_req_1_bits_firstUop,
  input  logic         io_enq_req_1_bits_lastUop,
  input  logic [6:0]   io_enq_req_1_bits_numWB,
  input  logic [2:0]   io_enq_req_1_bits_commitType,
  input  logic [7:0]   io_enq_req_1_bits_pdest,
  input  logic         io_enq_req_1_bits_robIdx_flag,
  input  logic [7:0]   io_enq_req_1_bits_robIdx_value,
  input  logic [2:0]   io_enq_req_1_bits_instrSize,
  input  logic         io_enq_req_1_bits_dirtyFs,
  input  logic         io_enq_req_1_bits_dirtyVs,
  input  logic [3:0]   io_enq_req_1_bits_traceBlockInPipe_itype,
  input  logic [3:0]   io_enq_req_1_bits_traceBlockInPipe_iretire,
  input  logic         io_enq_req_1_bits_traceBlockInPipe_ilastsize,
  input  logic         io_enq_req_1_bits_eliminatedMove,
  input  logic         io_enq_req_1_bits_snapshot,
  input  logic [63:0]  io_enq_req_1_bits_debugInfo_renameTime,
  input  logic [63:0]  io_enq_req_1_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_enq_req_1_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_enq_req_1_bits_debugInfo_selectTime,
  input  logic [63:0]  io_enq_req_1_bits_debugInfo_issueTime,
  input  logic [63:0]  io_enq_req_1_bits_debugInfo_writebackTime,
  input  logic [6:0]   io_enq_req_1_bits_lqIdx_value,
  input  logic [5:0]   io_enq_req_1_bits_sqIdx_value,
  input  logic         io_enq_req_1_bits_singleStep,
  input  logic         io_enq_req_1_bits_replayInst,
  input  logic [34:0]  io_enq_req_1_bits_debug_fuType,
  input  logic         io_enq_req_1_bits_debug_sim_trig,
  input  logic         io_enq_req_2_valid,
  input  logic [31:0]  io_enq_req_2_bits_instr,
  input  logic [49:0]  io_enq_req_2_bits_pc,
  input  logic         io_enq_req_2_bits_exceptionVec_0,
  input  logic         io_enq_req_2_bits_exceptionVec_1,
  input  logic         io_enq_req_2_bits_exceptionVec_2,
  input  logic         io_enq_req_2_bits_exceptionVec_3,
  input  logic         io_enq_req_2_bits_exceptionVec_12,
  input  logic         io_enq_req_2_bits_exceptionVec_20,
  input  logic         io_enq_req_2_bits_exceptionVec_22,
  input  logic         io_enq_req_2_bits_isFetchMalAddr,
  input  logic         io_enq_req_2_bits_hasException,
  input  logic [3:0]   io_enq_req_2_bits_trigger,
  input  logic         io_enq_req_2_bits_preDecodeInfo_isRVC,
  input  logic         io_enq_req_2_bits_crossPageIPFFix,
  input  logic         io_enq_req_2_bits_ftqPtr_flag,
  input  logic [5:0]   io_enq_req_2_bits_ftqPtr_value,
  input  logic [3:0]   io_enq_req_2_bits_ftqOffset,
  input  logic         io_enq_req_2_bits_satpFlushFirstFetchFault,
  input  logic [5:0]   io_enq_req_2_bits_ldest,
  input  logic [34:0]  io_enq_req_2_bits_fuType,
  input  logic [8:0]   io_enq_req_2_bits_fuOpType,
  input  logic         io_enq_req_2_bits_rfWen,
  input  logic         io_enq_req_2_bits_fpWen,
  input  logic         io_enq_req_2_bits_vecWen,
  input  logic         io_enq_req_2_bits_v0Wen,
  input  logic         io_enq_req_2_bits_vlWen,
  input  logic         io_enq_req_2_bits_isXSTrap,
  input  logic         io_enq_req_2_bits_waitForward,
  input  logic         io_enq_req_2_bits_blockBackward,
  input  logic         io_enq_req_2_bits_flushPipe,
  input  logic         io_enq_req_2_bits_vpu_vill,
  input  logic         io_enq_req_2_bits_vpu_vma,
  input  logic         io_enq_req_2_bits_vpu_vta,
  input  logic [1:0]   io_enq_req_2_bits_vpu_vsew,
  input  logic [2:0]   io_enq_req_2_bits_vpu_vlmul,
  input  logic         io_enq_req_2_bits_vpu_specVill,
  input  logic         io_enq_req_2_bits_vpu_specVma,
  input  logic         io_enq_req_2_bits_vpu_specVta,
  input  logic [1:0]   io_enq_req_2_bits_vpu_specVsew,
  input  logic [2:0]   io_enq_req_2_bits_vpu_specVlmul,
  input  logic         io_enq_req_2_bits_vlsInstr,
  input  logic         io_enq_req_2_bits_wfflags,
  input  logic         io_enq_req_2_bits_isMove,
  input  logic         io_enq_req_2_bits_isVset,
  input  logic         io_enq_req_2_bits_firstUop,
  input  logic         io_enq_req_2_bits_lastUop,
  input  logic [6:0]   io_enq_req_2_bits_numWB,
  input  logic [2:0]   io_enq_req_2_bits_commitType,
  input  logic [7:0]   io_enq_req_2_bits_pdest,
  input  logic         io_enq_req_2_bits_robIdx_flag,
  input  logic [7:0]   io_enq_req_2_bits_robIdx_value,
  input  logic [2:0]   io_enq_req_2_bits_instrSize,
  input  logic         io_enq_req_2_bits_dirtyFs,
  input  logic         io_enq_req_2_bits_dirtyVs,
  input  logic [3:0]   io_enq_req_2_bits_traceBlockInPipe_itype,
  input  logic [3:0]   io_enq_req_2_bits_traceBlockInPipe_iretire,
  input  logic         io_enq_req_2_bits_traceBlockInPipe_ilastsize,
  input  logic         io_enq_req_2_bits_eliminatedMove,
  input  logic         io_enq_req_2_bits_snapshot,
  input  logic [63:0]  io_enq_req_2_bits_debugInfo_renameTime,
  input  logic [63:0]  io_enq_req_2_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_enq_req_2_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_enq_req_2_bits_debugInfo_selectTime,
  input  logic [63:0]  io_enq_req_2_bits_debugInfo_issueTime,
  input  logic [63:0]  io_enq_req_2_bits_debugInfo_writebackTime,
  input  logic [6:0]   io_enq_req_2_bits_lqIdx_value,
  input  logic [5:0]   io_enq_req_2_bits_sqIdx_value,
  input  logic         io_enq_req_2_bits_singleStep,
  input  logic         io_enq_req_2_bits_replayInst,
  input  logic [34:0]  io_enq_req_2_bits_debug_fuType,
  input  logic         io_enq_req_2_bits_debug_sim_trig,
  input  logic         io_enq_req_3_valid,
  input  logic [31:0]  io_enq_req_3_bits_instr,
  input  logic [49:0]  io_enq_req_3_bits_pc,
  input  logic         io_enq_req_3_bits_exceptionVec_0,
  input  logic         io_enq_req_3_bits_exceptionVec_1,
  input  logic         io_enq_req_3_bits_exceptionVec_2,
  input  logic         io_enq_req_3_bits_exceptionVec_3,
  input  logic         io_enq_req_3_bits_exceptionVec_12,
  input  logic         io_enq_req_3_bits_exceptionVec_20,
  input  logic         io_enq_req_3_bits_exceptionVec_22,
  input  logic         io_enq_req_3_bits_isFetchMalAddr,
  input  logic         io_enq_req_3_bits_hasException,
  input  logic [3:0]   io_enq_req_3_bits_trigger,
  input  logic         io_enq_req_3_bits_preDecodeInfo_isRVC,
  input  logic         io_enq_req_3_bits_crossPageIPFFix,
  input  logic         io_enq_req_3_bits_ftqPtr_flag,
  input  logic [5:0]   io_enq_req_3_bits_ftqPtr_value,
  input  logic [3:0]   io_enq_req_3_bits_ftqOffset,
  input  logic         io_enq_req_3_bits_satpFlushFirstFetchFault,
  input  logic [5:0]   io_enq_req_3_bits_ldest,
  input  logic [34:0]  io_enq_req_3_bits_fuType,
  input  logic [8:0]   io_enq_req_3_bits_fuOpType,
  input  logic         io_enq_req_3_bits_rfWen,
  input  logic         io_enq_req_3_bits_fpWen,
  input  logic         io_enq_req_3_bits_vecWen,
  input  logic         io_enq_req_3_bits_v0Wen,
  input  logic         io_enq_req_3_bits_vlWen,
  input  logic         io_enq_req_3_bits_isXSTrap,
  input  logic         io_enq_req_3_bits_waitForward,
  input  logic         io_enq_req_3_bits_blockBackward,
  input  logic         io_enq_req_3_bits_flushPipe,
  input  logic         io_enq_req_3_bits_vpu_vill,
  input  logic         io_enq_req_3_bits_vpu_vma,
  input  logic         io_enq_req_3_bits_vpu_vta,
  input  logic [1:0]   io_enq_req_3_bits_vpu_vsew,
  input  logic [2:0]   io_enq_req_3_bits_vpu_vlmul,
  input  logic         io_enq_req_3_bits_vpu_specVill,
  input  logic         io_enq_req_3_bits_vpu_specVma,
  input  logic         io_enq_req_3_bits_vpu_specVta,
  input  logic [1:0]   io_enq_req_3_bits_vpu_specVsew,
  input  logic [2:0]   io_enq_req_3_bits_vpu_specVlmul,
  input  logic         io_enq_req_3_bits_vlsInstr,
  input  logic         io_enq_req_3_bits_wfflags,
  input  logic         io_enq_req_3_bits_isMove,
  input  logic         io_enq_req_3_bits_isVset,
  input  logic         io_enq_req_3_bits_firstUop,
  input  logic         io_enq_req_3_bits_lastUop,
  input  logic [6:0]   io_enq_req_3_bits_numWB,
  input  logic [2:0]   io_enq_req_3_bits_commitType,
  input  logic [7:0]   io_enq_req_3_bits_pdest,
  input  logic         io_enq_req_3_bits_robIdx_flag,
  input  logic [7:0]   io_enq_req_3_bits_robIdx_value,
  input  logic [2:0]   io_enq_req_3_bits_instrSize,
  input  logic         io_enq_req_3_bits_dirtyFs,
  input  logic         io_enq_req_3_bits_dirtyVs,
  input  logic [3:0]   io_enq_req_3_bits_traceBlockInPipe_itype,
  input  logic [3:0]   io_enq_req_3_bits_traceBlockInPipe_iretire,
  input  logic         io_enq_req_3_bits_traceBlockInPipe_ilastsize,
  input  logic         io_enq_req_3_bits_eliminatedMove,
  input  logic         io_enq_req_3_bits_snapshot,
  input  logic [63:0]  io_enq_req_3_bits_debugInfo_renameTime,
  input  logic [63:0]  io_enq_req_3_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_enq_req_3_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_enq_req_3_bits_debugInfo_selectTime,
  input  logic [63:0]  io_enq_req_3_bits_debugInfo_issueTime,
  input  logic [63:0]  io_enq_req_3_bits_debugInfo_writebackTime,
  input  logic [6:0]   io_enq_req_3_bits_lqIdx_value,
  input  logic [5:0]   io_enq_req_3_bits_sqIdx_value,
  input  logic         io_enq_req_3_bits_singleStep,
  input  logic         io_enq_req_3_bits_replayInst,
  input  logic [34:0]  io_enq_req_3_bits_debug_fuType,
  input  logic         io_enq_req_3_bits_debug_sim_trig,
  input  logic         io_enq_req_4_valid,
  input  logic [31:0]  io_enq_req_4_bits_instr,
  input  logic [49:0]  io_enq_req_4_bits_pc,
  input  logic         io_enq_req_4_bits_exceptionVec_0,
  input  logic         io_enq_req_4_bits_exceptionVec_1,
  input  logic         io_enq_req_4_bits_exceptionVec_2,
  input  logic         io_enq_req_4_bits_exceptionVec_3,
  input  logic         io_enq_req_4_bits_exceptionVec_12,
  input  logic         io_enq_req_4_bits_exceptionVec_20,
  input  logic         io_enq_req_4_bits_exceptionVec_22,
  input  logic         io_enq_req_4_bits_isFetchMalAddr,
  input  logic         io_enq_req_4_bits_hasException,
  input  logic [3:0]   io_enq_req_4_bits_trigger,
  input  logic         io_enq_req_4_bits_preDecodeInfo_isRVC,
  input  logic         io_enq_req_4_bits_crossPageIPFFix,
  input  logic         io_enq_req_4_bits_ftqPtr_flag,
  input  logic [5:0]   io_enq_req_4_bits_ftqPtr_value,
  input  logic [3:0]   io_enq_req_4_bits_ftqOffset,
  input  logic         io_enq_req_4_bits_satpFlushFirstFetchFault,
  input  logic [5:0]   io_enq_req_4_bits_ldest,
  input  logic [34:0]  io_enq_req_4_bits_fuType,
  input  logic [8:0]   io_enq_req_4_bits_fuOpType,
  input  logic         io_enq_req_4_bits_rfWen,
  input  logic         io_enq_req_4_bits_fpWen,
  input  logic         io_enq_req_4_bits_vecWen,
  input  logic         io_enq_req_4_bits_v0Wen,
  input  logic         io_enq_req_4_bits_vlWen,
  input  logic         io_enq_req_4_bits_isXSTrap,
  input  logic         io_enq_req_4_bits_waitForward,
  input  logic         io_enq_req_4_bits_blockBackward,
  input  logic         io_enq_req_4_bits_flushPipe,
  input  logic         io_enq_req_4_bits_vpu_vill,
  input  logic         io_enq_req_4_bits_vpu_vma,
  input  logic         io_enq_req_4_bits_vpu_vta,
  input  logic [1:0]   io_enq_req_4_bits_vpu_vsew,
  input  logic [2:0]   io_enq_req_4_bits_vpu_vlmul,
  input  logic         io_enq_req_4_bits_vpu_specVill,
  input  logic         io_enq_req_4_bits_vpu_specVma,
  input  logic         io_enq_req_4_bits_vpu_specVta,
  input  logic [1:0]   io_enq_req_4_bits_vpu_specVsew,
  input  logic [2:0]   io_enq_req_4_bits_vpu_specVlmul,
  input  logic         io_enq_req_4_bits_vlsInstr,
  input  logic         io_enq_req_4_bits_wfflags,
  input  logic         io_enq_req_4_bits_isMove,
  input  logic         io_enq_req_4_bits_isVset,
  input  logic         io_enq_req_4_bits_firstUop,
  input  logic         io_enq_req_4_bits_lastUop,
  input  logic [6:0]   io_enq_req_4_bits_numWB,
  input  logic [2:0]   io_enq_req_4_bits_commitType,
  input  logic [7:0]   io_enq_req_4_bits_pdest,
  input  logic         io_enq_req_4_bits_robIdx_flag,
  input  logic [7:0]   io_enq_req_4_bits_robIdx_value,
  input  logic [2:0]   io_enq_req_4_bits_instrSize,
  input  logic         io_enq_req_4_bits_dirtyFs,
  input  logic         io_enq_req_4_bits_dirtyVs,
  input  logic [3:0]   io_enq_req_4_bits_traceBlockInPipe_itype,
  input  logic [3:0]   io_enq_req_4_bits_traceBlockInPipe_iretire,
  input  logic         io_enq_req_4_bits_traceBlockInPipe_ilastsize,
  input  logic         io_enq_req_4_bits_eliminatedMove,
  input  logic         io_enq_req_4_bits_snapshot,
  input  logic [63:0]  io_enq_req_4_bits_debugInfo_renameTime,
  input  logic [63:0]  io_enq_req_4_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_enq_req_4_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_enq_req_4_bits_debugInfo_selectTime,
  input  logic [63:0]  io_enq_req_4_bits_debugInfo_issueTime,
  input  logic [63:0]  io_enq_req_4_bits_debugInfo_writebackTime,
  input  logic [6:0]   io_enq_req_4_bits_lqIdx_value,
  input  logic [5:0]   io_enq_req_4_bits_sqIdx_value,
  input  logic         io_enq_req_4_bits_singleStep,
  input  logic         io_enq_req_4_bits_replayInst,
  input  logic [34:0]  io_enq_req_4_bits_debug_fuType,
  input  logic         io_enq_req_4_bits_debug_sim_trig,
  input  logic         io_enq_req_5_valid,
  input  logic [31:0]  io_enq_req_5_bits_instr,
  input  logic [49:0]  io_enq_req_5_bits_pc,
  input  logic         io_enq_req_5_bits_exceptionVec_0,
  input  logic         io_enq_req_5_bits_exceptionVec_1,
  input  logic         io_enq_req_5_bits_exceptionVec_2,
  input  logic         io_enq_req_5_bits_exceptionVec_3,
  input  logic         io_enq_req_5_bits_exceptionVec_12,
  input  logic         io_enq_req_5_bits_exceptionVec_20,
  input  logic         io_enq_req_5_bits_exceptionVec_22,
  input  logic         io_enq_req_5_bits_isFetchMalAddr,
  input  logic         io_enq_req_5_bits_hasException,
  input  logic [3:0]   io_enq_req_5_bits_trigger,
  input  logic         io_enq_req_5_bits_preDecodeInfo_isRVC,
  input  logic         io_enq_req_5_bits_crossPageIPFFix,
  input  logic         io_enq_req_5_bits_ftqPtr_flag,
  input  logic [5:0]   io_enq_req_5_bits_ftqPtr_value,
  input  logic [3:0]   io_enq_req_5_bits_ftqOffset,
  input  logic         io_enq_req_5_bits_satpFlushFirstFetchFault,
  input  logic [5:0]   io_enq_req_5_bits_ldest,
  input  logic [34:0]  io_enq_req_5_bits_fuType,
  input  logic [8:0]   io_enq_req_5_bits_fuOpType,
  input  logic         io_enq_req_5_bits_rfWen,
  input  logic         io_enq_req_5_bits_fpWen,
  input  logic         io_enq_req_5_bits_vecWen,
  input  logic         io_enq_req_5_bits_v0Wen,
  input  logic         io_enq_req_5_bits_vlWen,
  input  logic         io_enq_req_5_bits_isXSTrap,
  input  logic         io_enq_req_5_bits_waitForward,
  input  logic         io_enq_req_5_bits_blockBackward,
  input  logic         io_enq_req_5_bits_flushPipe,
  input  logic         io_enq_req_5_bits_vpu_vill,
  input  logic         io_enq_req_5_bits_vpu_vma,
  input  logic         io_enq_req_5_bits_vpu_vta,
  input  logic [1:0]   io_enq_req_5_bits_vpu_vsew,
  input  logic [2:0]   io_enq_req_5_bits_vpu_vlmul,
  input  logic         io_enq_req_5_bits_vpu_specVill,
  input  logic         io_enq_req_5_bits_vpu_specVma,
  input  logic         io_enq_req_5_bits_vpu_specVta,
  input  logic [1:0]   io_enq_req_5_bits_vpu_specVsew,
  input  logic [2:0]   io_enq_req_5_bits_vpu_specVlmul,
  input  logic         io_enq_req_5_bits_vlsInstr,
  input  logic         io_enq_req_5_bits_wfflags,
  input  logic         io_enq_req_5_bits_isMove,
  input  logic         io_enq_req_5_bits_isVset,
  input  logic         io_enq_req_5_bits_firstUop,
  input  logic         io_enq_req_5_bits_lastUop,
  input  logic [6:0]   io_enq_req_5_bits_numWB,
  input  logic [2:0]   io_enq_req_5_bits_commitType,
  input  logic [7:0]   io_enq_req_5_bits_pdest,
  input  logic         io_enq_req_5_bits_robIdx_flag,
  input  logic [7:0]   io_enq_req_5_bits_robIdx_value,
  input  logic [2:0]   io_enq_req_5_bits_instrSize,
  input  logic         io_enq_req_5_bits_dirtyFs,
  input  logic         io_enq_req_5_bits_dirtyVs,
  input  logic [3:0]   io_enq_req_5_bits_traceBlockInPipe_itype,
  input  logic [3:0]   io_enq_req_5_bits_traceBlockInPipe_iretire,
  input  logic         io_enq_req_5_bits_traceBlockInPipe_ilastsize,
  input  logic         io_enq_req_5_bits_eliminatedMove,
  input  logic         io_enq_req_5_bits_snapshot,
  input  logic [63:0]  io_enq_req_5_bits_debugInfo_renameTime,
  input  logic [63:0]  io_enq_req_5_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_enq_req_5_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_enq_req_5_bits_debugInfo_selectTime,
  input  logic [63:0]  io_enq_req_5_bits_debugInfo_issueTime,
  input  logic [63:0]  io_enq_req_5_bits_debugInfo_writebackTime,
  input  logic [6:0]   io_enq_req_5_bits_lqIdx_value,
  input  logic [5:0]   io_enq_req_5_bits_sqIdx_value,
  input  logic         io_enq_req_5_bits_singleStep,
  input  logic         io_enq_req_5_bits_replayInst,
  input  logic [34:0]  io_enq_req_5_bits_debug_fuType,
  input  logic         io_enq_req_5_bits_debug_sim_trig,
  output logic         io_flushOut_valid,
  output logic         io_flushOut_bits_isRVC,
  output logic         io_flushOut_bits_robIdx_flag,
  output logic [7:0]   io_flushOut_bits_robIdx_value,
  output logic         io_flushOut_bits_ftqIdx_flag,
  output logic [5:0]   io_flushOut_bits_ftqIdx_value,
  output logic [3:0]   io_flushOut_bits_ftqOffset,
  output logic         io_flushOut_bits_level,
  output logic         io_flushOut_bits_satpFlush,
  output logic         io_flushOut_bits_isVlsException,
  output logic         io_exception_valid,
  output logic [31:0]  io_exception_bits_instr,
  output logic [2:0]   io_exception_bits_commitType,
  output logic         io_exception_bits_exceptionVec_0,
  output logic         io_exception_bits_exceptionVec_1,
  output logic         io_exception_bits_exceptionVec_2,
  output logic         io_exception_bits_exceptionVec_3,
  output logic         io_exception_bits_exceptionVec_4,
  output logic         io_exception_bits_exceptionVec_5,
  output logic         io_exception_bits_exceptionVec_6,
  output logic         io_exception_bits_exceptionVec_7,
  output logic         io_exception_bits_exceptionVec_8,
  output logic         io_exception_bits_exceptionVec_9,
  output logic         io_exception_bits_exceptionVec_10,
  output logic         io_exception_bits_exceptionVec_11,
  output logic         io_exception_bits_exceptionVec_12,
  output logic         io_exception_bits_exceptionVec_13,
  output logic         io_exception_bits_exceptionVec_14,
  output logic         io_exception_bits_exceptionVec_15,
  output logic         io_exception_bits_exceptionVec_16,
  output logic         io_exception_bits_exceptionVec_17,
  output logic         io_exception_bits_exceptionVec_18,
  output logic         io_exception_bits_exceptionVec_19,
  output logic         io_exception_bits_exceptionVec_20,
  output logic         io_exception_bits_exceptionVec_21,
  output logic         io_exception_bits_exceptionVec_22,
  output logic         io_exception_bits_exceptionVec_23,
  output logic         io_exception_bits_isPcBkpt,
  output logic         io_exception_bits_isFetchMalAddr,
  output logic         io_exception_bits_satpFlushFirstFetchFault,
  output logic [63:0]  io_exception_bits_gpaddr,
  output logic         io_exception_bits_singleStep,
  output logic         io_exception_bits_crossPageIPFFix,
  output logic         io_exception_bits_isInterrupt,
  output logic         io_exception_bits_isHls,
  output logic [3:0]   io_exception_bits_trigger,
  output logic         io_exception_bits_isForVSnonLeafPTE,
  input  logic         io_writeback_24_valid,
  input  logic [127:0] io_writeback_24_bits_data_0,
  input  logic [6:0]   io_writeback_24_bits_pdest,
  input  logic         io_writeback_24_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_24_bits_robIdx_value,
  input  logic         io_writeback_24_bits_vecWen,
  input  logic         io_writeback_24_bits_v0Wen,
  input  logic         io_writeback_24_bits_vlWen,
  input  logic         io_writeback_24_bits_exceptionVec_0,
  input  logic         io_writeback_24_bits_exceptionVec_1,
  input  logic         io_writeback_24_bits_exceptionVec_2,
  input  logic         io_writeback_24_bits_exceptionVec_3,
  input  logic         io_writeback_24_bits_exceptionVec_4,
  input  logic         io_writeback_24_bits_exceptionVec_5,
  input  logic         io_writeback_24_bits_exceptionVec_6,
  input  logic         io_writeback_24_bits_exceptionVec_7,
  input  logic         io_writeback_24_bits_exceptionVec_8,
  input  logic         io_writeback_24_bits_exceptionVec_9,
  input  logic         io_writeback_24_bits_exceptionVec_10,
  input  logic         io_writeback_24_bits_exceptionVec_11,
  input  logic         io_writeback_24_bits_exceptionVec_12,
  input  logic         io_writeback_24_bits_exceptionVec_13,
  input  logic         io_writeback_24_bits_exceptionVec_14,
  input  logic         io_writeback_24_bits_exceptionVec_15,
  input  logic         io_writeback_24_bits_exceptionVec_16,
  input  logic         io_writeback_24_bits_exceptionVec_17,
  input  logic         io_writeback_24_bits_exceptionVec_18,
  input  logic         io_writeback_24_bits_exceptionVec_19,
  input  logic         io_writeback_24_bits_exceptionVec_20,
  input  logic         io_writeback_24_bits_exceptionVec_21,
  input  logic         io_writeback_24_bits_exceptionVec_22,
  input  logic         io_writeback_24_bits_exceptionVec_23,
  input  logic         io_writeback_24_bits_flushPipe,
  input  logic         io_writeback_24_bits_replay,
  input  logic [3:0]   io_writeback_24_bits_trigger,
  input  logic         io_writeback_24_bits_vls_vpu_vill,
  input  logic         io_writeback_24_bits_vls_vpu_vma,
  input  logic         io_writeback_24_bits_vls_vpu_vta,
  input  logic [1:0]   io_writeback_24_bits_vls_vpu_vsew,
  input  logic [2:0]   io_writeback_24_bits_vls_vpu_vlmul,
  input  logic         io_writeback_24_bits_vls_vpu_specVill,
  input  logic         io_writeback_24_bits_vls_vpu_specVma,
  input  logic         io_writeback_24_bits_vls_vpu_specVta,
  input  logic [1:0]   io_writeback_24_bits_vls_vpu_specVsew,
  input  logic [2:0]   io_writeback_24_bits_vls_vpu_specVlmul,
  input  logic         io_writeback_24_bits_vls_vpu_vm,
  input  logic [7:0]   io_writeback_24_bits_vls_vpu_vstart,
  input  logic [2:0]   io_writeback_24_bits_vls_vpu_frm,
  input  logic         io_writeback_24_bits_vls_vpu_fpu_isFpToVecInst,
  input  logic         io_writeback_24_bits_vls_vpu_fpu_isFP32Instr,
  input  logic         io_writeback_24_bits_vls_vpu_fpu_isFP64Instr,
  input  logic         io_writeback_24_bits_vls_vpu_fpu_isReduction,
  input  logic         io_writeback_24_bits_vls_vpu_fpu_isFoldTo1_2,
  input  logic         io_writeback_24_bits_vls_vpu_fpu_isFoldTo1_4,
  input  logic         io_writeback_24_bits_vls_vpu_fpu_isFoldTo1_8,
  input  logic [1:0]   io_writeback_24_bits_vls_vpu_vxrm,
  input  logic [6:0]   io_writeback_24_bits_vls_vpu_vuopIdx,
  input  logic         io_writeback_24_bits_vls_vpu_lastUop,
  input  logic [127:0] io_writeback_24_bits_vls_vpu_vmask,
  input  logic [7:0]   io_writeback_24_bits_vls_vpu_vl,
  input  logic [2:0]   io_writeback_24_bits_vls_vpu_nf,
  input  logic [1:0]   io_writeback_24_bits_vls_vpu_veew,
  input  logic         io_writeback_24_bits_vls_vpu_isReverse,
  input  logic         io_writeback_24_bits_vls_vpu_isExt,
  input  logic         io_writeback_24_bits_vls_vpu_isNarrow,
  input  logic         io_writeback_24_bits_vls_vpu_isDstMask,
  input  logic         io_writeback_24_bits_vls_vpu_isOpMask,
  input  logic         io_writeback_24_bits_vls_vpu_isMove,
  input  logic         io_writeback_24_bits_vls_vpu_isDependOldVd,
  input  logic         io_writeback_24_bits_vls_vpu_isWritePartVd,
  input  logic         io_writeback_24_bits_vls_vpu_isVleff,
  input  logic [7:0]   io_writeback_24_bits_vls_oldVdPsrc,
  input  logic [2:0]   io_writeback_24_bits_vls_vdIdx,
  input  logic [2:0]   io_writeback_24_bits_vls_vdIdxInField,
  input  logic         io_writeback_24_bits_vls_isIndexed,
  input  logic         io_writeback_24_bits_vls_isMasked,
  input  logic         io_writeback_24_bits_vls_isStrided,
  input  logic         io_writeback_24_bits_vls_isWhole,
  input  logic         io_writeback_24_bits_vls_isVecLoad,
  input  logic         io_writeback_24_bits_vls_isVlm,
  input  logic         io_writeback_24_bits_debug_isMMIO,
  input  logic         io_writeback_24_bits_debug_isNCIO,
  input  logic         io_writeback_24_bits_debug_isPerfCnt,
  input  logic [47:0]  io_writeback_24_bits_debug_paddr,
  input  logic [49:0]  io_writeback_24_bits_debug_vaddr,
  input  logic         io_writeback_24_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_24_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_24_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_24_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_24_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_24_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_24_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_24_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_24_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_24_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_24_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_24_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_23_valid,
  input  logic [127:0] io_writeback_23_bits_data_0,
  input  logic [6:0]   io_writeback_23_bits_pdest,
  input  logic         io_writeback_23_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_23_bits_robIdx_value,
  input  logic         io_writeback_23_bits_vecWen,
  input  logic         io_writeback_23_bits_v0Wen,
  input  logic         io_writeback_23_bits_vlWen,
  input  logic         io_writeback_23_bits_exceptionVec_0,
  input  logic         io_writeback_23_bits_exceptionVec_1,
  input  logic         io_writeback_23_bits_exceptionVec_2,
  input  logic         io_writeback_23_bits_exceptionVec_3,
  input  logic         io_writeback_23_bits_exceptionVec_4,
  input  logic         io_writeback_23_bits_exceptionVec_5,
  input  logic         io_writeback_23_bits_exceptionVec_6,
  input  logic         io_writeback_23_bits_exceptionVec_7,
  input  logic         io_writeback_23_bits_exceptionVec_8,
  input  logic         io_writeback_23_bits_exceptionVec_9,
  input  logic         io_writeback_23_bits_exceptionVec_10,
  input  logic         io_writeback_23_bits_exceptionVec_11,
  input  logic         io_writeback_23_bits_exceptionVec_12,
  input  logic         io_writeback_23_bits_exceptionVec_13,
  input  logic         io_writeback_23_bits_exceptionVec_14,
  input  logic         io_writeback_23_bits_exceptionVec_15,
  input  logic         io_writeback_23_bits_exceptionVec_16,
  input  logic         io_writeback_23_bits_exceptionVec_17,
  input  logic         io_writeback_23_bits_exceptionVec_18,
  input  logic         io_writeback_23_bits_exceptionVec_19,
  input  logic         io_writeback_23_bits_exceptionVec_20,
  input  logic         io_writeback_23_bits_exceptionVec_21,
  input  logic         io_writeback_23_bits_exceptionVec_22,
  input  logic         io_writeback_23_bits_exceptionVec_23,
  input  logic         io_writeback_23_bits_flushPipe,
  input  logic         io_writeback_23_bits_replay,
  input  logic [3:0]   io_writeback_23_bits_trigger,
  input  logic         io_writeback_23_bits_vls_vpu_vill,
  input  logic         io_writeback_23_bits_vls_vpu_vma,
  input  logic         io_writeback_23_bits_vls_vpu_vta,
  input  logic [1:0]   io_writeback_23_bits_vls_vpu_vsew,
  input  logic [2:0]   io_writeback_23_bits_vls_vpu_vlmul,
  input  logic         io_writeback_23_bits_vls_vpu_specVill,
  input  logic         io_writeback_23_bits_vls_vpu_specVma,
  input  logic         io_writeback_23_bits_vls_vpu_specVta,
  input  logic [1:0]   io_writeback_23_bits_vls_vpu_specVsew,
  input  logic [2:0]   io_writeback_23_bits_vls_vpu_specVlmul,
  input  logic         io_writeback_23_bits_vls_vpu_vm,
  input  logic [7:0]   io_writeback_23_bits_vls_vpu_vstart,
  input  logic [2:0]   io_writeback_23_bits_vls_vpu_frm,
  input  logic         io_writeback_23_bits_vls_vpu_fpu_isFpToVecInst,
  input  logic         io_writeback_23_bits_vls_vpu_fpu_isFP32Instr,
  input  logic         io_writeback_23_bits_vls_vpu_fpu_isFP64Instr,
  input  logic         io_writeback_23_bits_vls_vpu_fpu_isReduction,
  input  logic         io_writeback_23_bits_vls_vpu_fpu_isFoldTo1_2,
  input  logic         io_writeback_23_bits_vls_vpu_fpu_isFoldTo1_4,
  input  logic         io_writeback_23_bits_vls_vpu_fpu_isFoldTo1_8,
  input  logic [1:0]   io_writeback_23_bits_vls_vpu_vxrm,
  input  logic [6:0]   io_writeback_23_bits_vls_vpu_vuopIdx,
  input  logic         io_writeback_23_bits_vls_vpu_lastUop,
  input  logic [127:0] io_writeback_23_bits_vls_vpu_vmask,
  input  logic [7:0]   io_writeback_23_bits_vls_vpu_vl,
  input  logic [2:0]   io_writeback_23_bits_vls_vpu_nf,
  input  logic [1:0]   io_writeback_23_bits_vls_vpu_veew,
  input  logic         io_writeback_23_bits_vls_vpu_isReverse,
  input  logic         io_writeback_23_bits_vls_vpu_isExt,
  input  logic         io_writeback_23_bits_vls_vpu_isNarrow,
  input  logic         io_writeback_23_bits_vls_vpu_isDstMask,
  input  logic         io_writeback_23_bits_vls_vpu_isOpMask,
  input  logic         io_writeback_23_bits_vls_vpu_isMove,
  input  logic         io_writeback_23_bits_vls_vpu_isDependOldVd,
  input  logic         io_writeback_23_bits_vls_vpu_isWritePartVd,
  input  logic         io_writeback_23_bits_vls_vpu_isVleff,
  input  logic [7:0]   io_writeback_23_bits_vls_oldVdPsrc,
  input  logic [2:0]   io_writeback_23_bits_vls_vdIdx,
  input  logic [2:0]   io_writeback_23_bits_vls_vdIdxInField,
  input  logic         io_writeback_23_bits_vls_isIndexed,
  input  logic         io_writeback_23_bits_vls_isMasked,
  input  logic         io_writeback_23_bits_vls_isStrided,
  input  logic         io_writeback_23_bits_vls_isWhole,
  input  logic         io_writeback_23_bits_vls_isVecLoad,
  input  logic         io_writeback_23_bits_vls_isVlm,
  input  logic         io_writeback_23_bits_debug_isMMIO,
  input  logic         io_writeback_23_bits_debug_isNCIO,
  input  logic         io_writeback_23_bits_debug_isPerfCnt,
  input  logic [47:0]  io_writeback_23_bits_debug_paddr,
  input  logic [49:0]  io_writeback_23_bits_debug_vaddr,
  input  logic         io_writeback_23_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_23_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_23_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_23_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_23_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_23_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_23_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_23_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_23_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_23_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_23_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_23_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_22_valid,
  input  logic [63:0]  io_writeback_22_bits_data_0,
  input  logic [7:0]   io_writeback_22_bits_pdest,
  input  logic         io_writeback_22_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_22_bits_robIdx_value,
  input  logic         io_writeback_22_bits_intWen,
  input  logic         io_writeback_22_bits_fpWen,
  input  logic         io_writeback_22_bits_exceptionVec_0,
  input  logic         io_writeback_22_bits_exceptionVec_1,
  input  logic         io_writeback_22_bits_exceptionVec_2,
  input  logic         io_writeback_22_bits_exceptionVec_3,
  input  logic         io_writeback_22_bits_exceptionVec_4,
  input  logic         io_writeback_22_bits_exceptionVec_5,
  input  logic         io_writeback_22_bits_exceptionVec_6,
  input  logic         io_writeback_22_bits_exceptionVec_7,
  input  logic         io_writeback_22_bits_exceptionVec_8,
  input  logic         io_writeback_22_bits_exceptionVec_9,
  input  logic         io_writeback_22_bits_exceptionVec_10,
  input  logic         io_writeback_22_bits_exceptionVec_11,
  input  logic         io_writeback_22_bits_exceptionVec_12,
  input  logic         io_writeback_22_bits_exceptionVec_13,
  input  logic         io_writeback_22_bits_exceptionVec_14,
  input  logic         io_writeback_22_bits_exceptionVec_15,
  input  logic         io_writeback_22_bits_exceptionVec_16,
  input  logic         io_writeback_22_bits_exceptionVec_17,
  input  logic         io_writeback_22_bits_exceptionVec_18,
  input  logic         io_writeback_22_bits_exceptionVec_19,
  input  logic         io_writeback_22_bits_exceptionVec_20,
  input  logic         io_writeback_22_bits_exceptionVec_21,
  input  logic         io_writeback_22_bits_exceptionVec_22,
  input  logic         io_writeback_22_bits_exceptionVec_23,
  input  logic         io_writeback_22_bits_flushPipe,
  input  logic         io_writeback_22_bits_replay,
  input  logic         io_writeback_22_bits_lqIdx_flag,
  input  logic [6:0]   io_writeback_22_bits_lqIdx_value,
  input  logic [3:0]   io_writeback_22_bits_trigger,
  input  logic         io_writeback_22_bits_predecodeInfo_valid,
  input  logic         io_writeback_22_bits_predecodeInfo_isRVC,
  input  logic [1:0]   io_writeback_22_bits_predecodeInfo_brType,
  input  logic         io_writeback_22_bits_predecodeInfo_isCall,
  input  logic         io_writeback_22_bits_predecodeInfo_isRet,
  input  logic         io_writeback_22_bits_debug_isMMIO,
  input  logic         io_writeback_22_bits_debug_isNCIO,
  input  logic         io_writeback_22_bits_debug_isPerfCnt,
  input  logic [47:0]  io_writeback_22_bits_debug_paddr,
  input  logic [49:0]  io_writeback_22_bits_debug_vaddr,
  input  logic         io_writeback_22_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_22_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_22_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_22_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_22_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_22_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_22_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_22_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_22_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_22_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_22_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_22_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_21_valid,
  input  logic [63:0]  io_writeback_21_bits_data_0,
  input  logic [7:0]   io_writeback_21_bits_pdest,
  input  logic         io_writeback_21_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_21_bits_robIdx_value,
  input  logic         io_writeback_21_bits_intWen,
  input  logic         io_writeback_21_bits_fpWen,
  input  logic         io_writeback_21_bits_exceptionVec_0,
  input  logic         io_writeback_21_bits_exceptionVec_1,
  input  logic         io_writeback_21_bits_exceptionVec_2,
  input  logic         io_writeback_21_bits_exceptionVec_3,
  input  logic         io_writeback_21_bits_exceptionVec_4,
  input  logic         io_writeback_21_bits_exceptionVec_5,
  input  logic         io_writeback_21_bits_exceptionVec_6,
  input  logic         io_writeback_21_bits_exceptionVec_7,
  input  logic         io_writeback_21_bits_exceptionVec_8,
  input  logic         io_writeback_21_bits_exceptionVec_9,
  input  logic         io_writeback_21_bits_exceptionVec_10,
  input  logic         io_writeback_21_bits_exceptionVec_11,
  input  logic         io_writeback_21_bits_exceptionVec_12,
  input  logic         io_writeback_21_bits_exceptionVec_13,
  input  logic         io_writeback_21_bits_exceptionVec_14,
  input  logic         io_writeback_21_bits_exceptionVec_15,
  input  logic         io_writeback_21_bits_exceptionVec_16,
  input  logic         io_writeback_21_bits_exceptionVec_17,
  input  logic         io_writeback_21_bits_exceptionVec_18,
  input  logic         io_writeback_21_bits_exceptionVec_19,
  input  logic         io_writeback_21_bits_exceptionVec_20,
  input  logic         io_writeback_21_bits_exceptionVec_21,
  input  logic         io_writeback_21_bits_exceptionVec_22,
  input  logic         io_writeback_21_bits_exceptionVec_23,
  input  logic         io_writeback_21_bits_flushPipe,
  input  logic         io_writeback_21_bits_replay,
  input  logic         io_writeback_21_bits_lqIdx_flag,
  input  logic [6:0]   io_writeback_21_bits_lqIdx_value,
  input  logic [3:0]   io_writeback_21_bits_trigger,
  input  logic         io_writeback_21_bits_predecodeInfo_valid,
  input  logic         io_writeback_21_bits_predecodeInfo_isRVC,
  input  logic [1:0]   io_writeback_21_bits_predecodeInfo_brType,
  input  logic         io_writeback_21_bits_predecodeInfo_isCall,
  input  logic         io_writeback_21_bits_predecodeInfo_isRet,
  input  logic         io_writeback_21_bits_debug_isMMIO,
  input  logic         io_writeback_21_bits_debug_isNCIO,
  input  logic         io_writeback_21_bits_debug_isPerfCnt,
  input  logic [47:0]  io_writeback_21_bits_debug_paddr,
  input  logic [49:0]  io_writeback_21_bits_debug_vaddr,
  input  logic         io_writeback_21_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_21_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_21_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_21_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_21_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_21_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_21_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_21_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_21_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_21_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_21_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_21_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_20_valid,
  input  logic [63:0]  io_writeback_20_bits_data_0,
  input  logic [7:0]   io_writeback_20_bits_pdest,
  input  logic         io_writeback_20_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_20_bits_robIdx_value,
  input  logic         io_writeback_20_bits_intWen,
  input  logic         io_writeback_20_bits_fpWen,
  input  logic         io_writeback_20_bits_exceptionVec_0,
  input  logic         io_writeback_20_bits_exceptionVec_1,
  input  logic         io_writeback_20_bits_exceptionVec_2,
  input  logic         io_writeback_20_bits_exceptionVec_3,
  input  logic         io_writeback_20_bits_exceptionVec_4,
  input  logic         io_writeback_20_bits_exceptionVec_5,
  input  logic         io_writeback_20_bits_exceptionVec_6,
  input  logic         io_writeback_20_bits_exceptionVec_7,
  input  logic         io_writeback_20_bits_exceptionVec_8,
  input  logic         io_writeback_20_bits_exceptionVec_9,
  input  logic         io_writeback_20_bits_exceptionVec_10,
  input  logic         io_writeback_20_bits_exceptionVec_11,
  input  logic         io_writeback_20_bits_exceptionVec_12,
  input  logic         io_writeback_20_bits_exceptionVec_13,
  input  logic         io_writeback_20_bits_exceptionVec_14,
  input  logic         io_writeback_20_bits_exceptionVec_15,
  input  logic         io_writeback_20_bits_exceptionVec_16,
  input  logic         io_writeback_20_bits_exceptionVec_17,
  input  logic         io_writeback_20_bits_exceptionVec_18,
  input  logic         io_writeback_20_bits_exceptionVec_19,
  input  logic         io_writeback_20_bits_exceptionVec_20,
  input  logic         io_writeback_20_bits_exceptionVec_21,
  input  logic         io_writeback_20_bits_exceptionVec_22,
  input  logic         io_writeback_20_bits_exceptionVec_23,
  input  logic         io_writeback_20_bits_flushPipe,
  input  logic         io_writeback_20_bits_replay,
  input  logic         io_writeback_20_bits_lqIdx_flag,
  input  logic [6:0]   io_writeback_20_bits_lqIdx_value,
  input  logic [3:0]   io_writeback_20_bits_trigger,
  input  logic         io_writeback_20_bits_predecodeInfo_valid,
  input  logic         io_writeback_20_bits_predecodeInfo_isRVC,
  input  logic [1:0]   io_writeback_20_bits_predecodeInfo_brType,
  input  logic         io_writeback_20_bits_predecodeInfo_isCall,
  input  logic         io_writeback_20_bits_predecodeInfo_isRet,
  input  logic         io_writeback_20_bits_debug_isMMIO,
  input  logic         io_writeback_20_bits_debug_isNCIO,
  input  logic         io_writeback_20_bits_debug_isPerfCnt,
  input  logic [47:0]  io_writeback_20_bits_debug_paddr,
  input  logic [49:0]  io_writeback_20_bits_debug_vaddr,
  input  logic         io_writeback_20_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_20_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_20_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_20_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_20_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_20_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_20_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_20_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_20_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_20_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_20_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_20_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_19_valid,
  input  logic [63:0]  io_writeback_19_bits_data_0,
  input  logic [7:0]   io_writeback_19_bits_pdest,
  input  logic         io_writeback_19_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_19_bits_robIdx_value,
  input  logic         io_writeback_19_bits_intWen,
  input  logic         io_writeback_19_bits_exceptionVec_0,
  input  logic         io_writeback_19_bits_exceptionVec_1,
  input  logic         io_writeback_19_bits_exceptionVec_2,
  input  logic         io_writeback_19_bits_exceptionVec_3,
  input  logic         io_writeback_19_bits_exceptionVec_4,
  input  logic         io_writeback_19_bits_exceptionVec_5,
  input  logic         io_writeback_19_bits_exceptionVec_6,
  input  logic         io_writeback_19_bits_exceptionVec_7,
  input  logic         io_writeback_19_bits_exceptionVec_8,
  input  logic         io_writeback_19_bits_exceptionVec_9,
  input  logic         io_writeback_19_bits_exceptionVec_10,
  input  logic         io_writeback_19_bits_exceptionVec_11,
  input  logic         io_writeback_19_bits_exceptionVec_12,
  input  logic         io_writeback_19_bits_exceptionVec_13,
  input  logic         io_writeback_19_bits_exceptionVec_14,
  input  logic         io_writeback_19_bits_exceptionVec_15,
  input  logic         io_writeback_19_bits_exceptionVec_16,
  input  logic         io_writeback_19_bits_exceptionVec_17,
  input  logic         io_writeback_19_bits_exceptionVec_18,
  input  logic         io_writeback_19_bits_exceptionVec_19,
  input  logic         io_writeback_19_bits_exceptionVec_20,
  input  logic         io_writeback_19_bits_exceptionVec_21,
  input  logic         io_writeback_19_bits_exceptionVec_22,
  input  logic         io_writeback_19_bits_exceptionVec_23,
  input  logic         io_writeback_19_bits_flushPipe,
  input  logic         io_writeback_19_bits_sqIdx_flag,
  input  logic [5:0]   io_writeback_19_bits_sqIdx_value,
  input  logic [3:0]   io_writeback_19_bits_trigger,
  input  logic         io_writeback_19_bits_debug_isMMIO,
  input  logic         io_writeback_19_bits_debug_isNCIO,
  input  logic         io_writeback_19_bits_debug_isPerfCnt,
  input  logic [47:0]  io_writeback_19_bits_debug_paddr,
  input  logic [49:0]  io_writeback_19_bits_debug_vaddr,
  input  logic         io_writeback_19_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_19_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_19_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_19_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_19_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_19_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_19_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_19_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_19_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_19_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_19_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_19_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_18_valid,
  input  logic [63:0]  io_writeback_18_bits_data_0,
  input  logic [7:0]   io_writeback_18_bits_pdest,
  input  logic         io_writeback_18_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_18_bits_robIdx_value,
  input  logic         io_writeback_18_bits_intWen,
  input  logic         io_writeback_18_bits_exceptionVec_0,
  input  logic         io_writeback_18_bits_exceptionVec_1,
  input  logic         io_writeback_18_bits_exceptionVec_2,
  input  logic         io_writeback_18_bits_exceptionVec_3,
  input  logic         io_writeback_18_bits_exceptionVec_4,
  input  logic         io_writeback_18_bits_exceptionVec_5,
  input  logic         io_writeback_18_bits_exceptionVec_6,
  input  logic         io_writeback_18_bits_exceptionVec_7,
  input  logic         io_writeback_18_bits_exceptionVec_8,
  input  logic         io_writeback_18_bits_exceptionVec_9,
  input  logic         io_writeback_18_bits_exceptionVec_10,
  input  logic         io_writeback_18_bits_exceptionVec_11,
  input  logic         io_writeback_18_bits_exceptionVec_12,
  input  logic         io_writeback_18_bits_exceptionVec_13,
  input  logic         io_writeback_18_bits_exceptionVec_14,
  input  logic         io_writeback_18_bits_exceptionVec_15,
  input  logic         io_writeback_18_bits_exceptionVec_16,
  input  logic         io_writeback_18_bits_exceptionVec_17,
  input  logic         io_writeback_18_bits_exceptionVec_18,
  input  logic         io_writeback_18_bits_exceptionVec_19,
  input  logic         io_writeback_18_bits_exceptionVec_20,
  input  logic         io_writeback_18_bits_exceptionVec_21,
  input  logic         io_writeback_18_bits_exceptionVec_22,
  input  logic         io_writeback_18_bits_exceptionVec_23,
  input  logic         io_writeback_18_bits_flushPipe,
  input  logic         io_writeback_18_bits_sqIdx_flag,
  input  logic [5:0]   io_writeback_18_bits_sqIdx_value,
  input  logic [3:0]   io_writeback_18_bits_trigger,
  input  logic         io_writeback_18_bits_debug_isMMIO,
  input  logic         io_writeback_18_bits_debug_isNCIO,
  input  logic         io_writeback_18_bits_debug_isPerfCnt,
  input  logic [47:0]  io_writeback_18_bits_debug_paddr,
  input  logic [49:0]  io_writeback_18_bits_debug_vaddr,
  input  logic         io_writeback_18_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_18_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_18_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_18_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_18_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_18_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_18_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_18_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_18_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_18_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_18_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_18_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_17_valid,
  input  logic [127:0] io_writeback_17_bits_data_0,
  input  logic [127:0] io_writeback_17_bits_data_1,
  input  logic [127:0] io_writeback_17_bits_data_2,
  input  logic [6:0]   io_writeback_17_bits_pdest,
  input  logic         io_writeback_17_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_17_bits_robIdx_value,
  input  logic         io_writeback_17_bits_vecWen,
  input  logic         io_writeback_17_bits_v0Wen,
  input  logic [4:0]   io_writeback_17_bits_fflags,
  input  logic         io_writeback_17_bits_wflags,
  input  logic         io_writeback_17_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_17_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_17_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_17_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_17_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_17_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_17_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_17_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_17_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_17_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_17_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_17_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_16_valid,
  input  logic [127:0] io_writeback_16_bits_data_0,
  input  logic [127:0] io_writeback_16_bits_data_1,
  input  logic [127:0] io_writeback_16_bits_data_2,
  input  logic [127:0] io_writeback_16_bits_data_3,
  input  logic [7:0]   io_writeback_16_bits_pdest,
  input  logic         io_writeback_16_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_16_bits_robIdx_value,
  input  logic         io_writeback_16_bits_fpWen,
  input  logic         io_writeback_16_bits_vecWen,
  input  logic         io_writeback_16_bits_v0Wen,
  input  logic [4:0]   io_writeback_16_bits_fflags,
  input  logic         io_writeback_16_bits_wflags,
  input  logic         io_writeback_16_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_16_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_16_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_16_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_16_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_16_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_16_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_16_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_16_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_16_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_16_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_16_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_15_valid,
  input  logic [127:0] io_writeback_15_bits_data_0,
  input  logic [127:0] io_writeback_15_bits_data_1,
  input  logic [127:0] io_writeback_15_bits_data_2,
  input  logic [6:0]   io_writeback_15_bits_pdest,
  input  logic         io_writeback_15_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_15_bits_robIdx_value,
  input  logic         io_writeback_15_bits_vecWen,
  input  logic         io_writeback_15_bits_v0Wen,
  input  logic [4:0]   io_writeback_15_bits_fflags,
  input  logic         io_writeback_15_bits_wflags,
  input  logic         io_writeback_15_bits_vxsat,
  input  logic         io_writeback_15_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_15_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_15_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_15_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_15_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_15_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_15_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_15_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_15_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_15_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_15_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_15_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_14_valid,
  input  logic [127:0] io_writeback_14_bits_data_0,
  input  logic [127:0] io_writeback_14_bits_data_1,
  input  logic [127:0] io_writeback_14_bits_data_2,
  input  logic [127:0] io_writeback_14_bits_data_3,
  input  logic [127:0] io_writeback_14_bits_data_4,
  input  logic [127:0] io_writeback_14_bits_data_5,
  input  logic [7:0]   io_writeback_14_bits_pdest,
  input  logic         io_writeback_14_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_14_bits_robIdx_value,
  input  logic         io_writeback_14_bits_intWen,
  input  logic         io_writeback_14_bits_fpWen,
  input  logic         io_writeback_14_bits_vecWen,
  input  logic         io_writeback_14_bits_v0Wen,
  input  logic         io_writeback_14_bits_vlWen,
  input  logic [4:0]   io_writeback_14_bits_fflags,
  input  logic         io_writeback_14_bits_wflags,
  input  logic         io_writeback_14_bits_exceptionVec_2,
  input  logic         io_writeback_14_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_14_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_14_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_14_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_14_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_14_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_14_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_14_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_14_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_14_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_14_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_14_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_13_valid,
  input  logic [127:0] io_writeback_13_bits_data_0,
  input  logic [127:0] io_writeback_13_bits_data_1,
  input  logic [127:0] io_writeback_13_bits_data_2,
  input  logic [6:0]   io_writeback_13_bits_pdest,
  input  logic         io_writeback_13_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_13_bits_robIdx_value,
  input  logic         io_writeback_13_bits_vecWen,
  input  logic         io_writeback_13_bits_v0Wen,
  input  logic [4:0]   io_writeback_13_bits_fflags,
  input  logic         io_writeback_13_bits_wflags,
  input  logic         io_writeback_13_bits_vxsat,
  input  logic         io_writeback_13_bits_exceptionVec_2,
  input  logic         io_writeback_13_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_13_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_13_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_13_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_13_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_13_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_13_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_13_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_13_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_13_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_13_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_13_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_7_valid,
  input  logic [63:0]  io_writeback_7_bits_data_0,
  input  logic [63:0]  io_writeback_7_bits_data_1,
  input  logic [7:0]   io_writeback_7_bits_pdest,
  input  logic         io_writeback_7_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_7_bits_robIdx_value,
  input  logic         io_writeback_7_bits_intWen,
  input  logic         io_writeback_7_bits_redirect_valid,
  input  logic         io_writeback_7_bits_redirect_bits_isRVC,
  input  logic         io_writeback_7_bits_redirect_bits_robIdx_flag,
  input  logic [7:0]   io_writeback_7_bits_redirect_bits_robIdx_value,
  input  logic         io_writeback_7_bits_redirect_bits_ftqIdx_flag,
  input  logic [5:0]   io_writeback_7_bits_redirect_bits_ftqIdx_value,
  input  logic [3:0]   io_writeback_7_bits_redirect_bits_ftqOffset,
  input  logic         io_writeback_7_bits_redirect_bits_level,
  input  logic         io_writeback_7_bits_redirect_bits_interrupt,
  input  logic [49:0]  io_writeback_7_bits_redirect_bits_cfiUpdate_pc,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_pd_valid,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_pd_isRVC,
  input  logic [1:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_pd_brType,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_pd_isCall,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_pd_isRet,
  input  logic [3:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_ssp,
  input  logic [2:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_sctr,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_TOSW_flag,
  input  logic [4:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_TOSW_value,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_TOSR_flag,
  input  logic [4:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_TOSR_value,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_NOS_flag,
  input  logic [4:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_NOS_value,
  input  logic [49:0]  io_writeback_7_bits_redirect_bits_cfiUpdate_topAddr,
  input  logic [10:0]  io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist,
  input  logic [10:0]  io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist,
  input  logic [6:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist,
  input  logic [7:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist,
  input  logic [8:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist,
  input  logic [3:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist,
  input  logic [7:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist,
  input  logic [8:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist,
  input  logic [6:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist,
  input  logic [7:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist,
  input  logic [6:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist,
  input  logic [8:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist,
  input  logic [6:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist,
  input  logic [7:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist,
  input  logic [7:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist,
  input  logic [7:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist,
  input  logic [10:0]  io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist,
  input  logic [7:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3,
  input  logic [2:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_lastBrNumOH,
  input  logic [3:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_ghr,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_histPtr_flag,
  input  logic [7:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_histPtr_value,
  input  logic [9:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_specCnt_0,
  input  logic [9:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_specCnt_1,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_br_hit,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_jr_hit,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_sc_hit,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_predTaken,
  input  logic [49:0]  io_writeback_7_bits_redirect_bits_cfiUpdate_target,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_taken,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_isMisPred,
  input  logic [1:0]   io_writeback_7_bits_redirect_bits_cfiUpdate_shift,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_addIntoHist,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_backendIGPF,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_backendIPF,
  input  logic         io_writeback_7_bits_redirect_bits_cfiUpdate_backendIAF,
  input  logic [63:0]  io_writeback_7_bits_redirect_bits_fullTarget,
  input  logic         io_writeback_7_bits_redirect_bits_satpFlush,
  input  logic         io_writeback_7_bits_redirect_bits_isVlsException,
  input  logic         io_writeback_7_bits_redirect_bits_stFtqIdx_flag,
  input  logic [5:0]   io_writeback_7_bits_redirect_bits_stFtqIdx_value,
  input  logic [3:0]   io_writeback_7_bits_redirect_bits_stFtqOffset,
  input  logic [63:0]  io_writeback_7_bits_redirect_bits_debug_runahead_checkpoint_id,
  input  logic         io_writeback_7_bits_redirect_bits_debugIsCtrl,
  input  logic         io_writeback_7_bits_redirect_bits_debugIsMemVio,
  input  logic         io_writeback_7_bits_exceptionVec_2,
  input  logic         io_writeback_7_bits_exceptionVec_3,
  input  logic         io_writeback_7_bits_exceptionVec_8,
  input  logic         io_writeback_7_bits_exceptionVec_9,
  input  logic         io_writeback_7_bits_exceptionVec_10,
  input  logic         io_writeback_7_bits_exceptionVec_11,
  input  logic         io_writeback_7_bits_exceptionVec_22,
  input  logic         io_writeback_7_bits_flushPipe,
  input  logic         io_writeback_7_bits_satpFlushPipe,
  input  logic         io_writeback_7_bits_predecodeInfo_valid,
  input  logic         io_writeback_7_bits_predecodeInfo_isRVC,
  input  logic [1:0]   io_writeback_7_bits_predecodeInfo_brType,
  input  logic         io_writeback_7_bits_predecodeInfo_isCall,
  input  logic         io_writeback_7_bits_predecodeInfo_isRet,
  input  logic         io_writeback_7_bits_debug_isPerfCnt,
  input  logic         io_writeback_7_bits_debugInfo_eliminatedMove,
  input  logic [63:0]  io_writeback_7_bits_debugInfo_renameTime,
  input  logic [63:0]  io_writeback_7_bits_debugInfo_dispatchTime,
  input  logic [63:0]  io_writeback_7_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_writeback_7_bits_debugInfo_selectTime,
  input  logic [63:0]  io_writeback_7_bits_debugInfo_issueTime,
  input  logic [63:0]  io_writeback_7_bits_debugInfo_writebackTime,
  input  logic [63:0]  io_writeback_7_bits_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_writeback_7_bits_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_writeback_7_bits_debugInfo_tlbRespTime,
  input  logic [55:0]  io_writeback_7_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_writeback_7_bits_debug_seqNum_uopIdx,
  input  logic         io_writeback_5_valid,
  input  logic         io_writeback_5_bits_redirect_valid,
  input  logic         io_writeback_5_bits_redirect_bits_cfiUpdate_isMisPred,
  input  logic         io_writeback_3_valid,
  input  logic         io_writeback_3_bits_redirect_valid,
  input  logic         io_writeback_3_bits_redirect_bits_cfiUpdate_isMisPred,
  input  logic         io_writeback_1_valid,
  input  logic         io_writeback_1_bits_redirect_valid,
  input  logic         io_writeback_1_bits_redirect_bits_cfiUpdate_isMisPred,
  input  logic         io_exuWriteback_26_valid,
  input  logic [7:0]   io_exuWriteback_26_bits_robIdx_value,
  input  logic         io_exuWriteback_25_valid,
  input  logic [7:0]   io_exuWriteback_25_bits_robIdx_value,
  input  logic         io_exuWriteback_24_valid,
  input  logic [127:0] io_exuWriteback_24_bits_data_0,
  input  logic [6:0]   io_exuWriteback_24_bits_pdest,
  input  logic [7:0]   io_exuWriteback_24_bits_robIdx_value,
  input  logic         io_exuWriteback_24_bits_vecWen,
  input  logic         io_exuWriteback_24_bits_v0Wen,
  input  logic [2:0]   io_exuWriteback_24_bits_vls_vdIdx,
  input  logic         io_exuWriteback_24_bits_debug_isMMIO,
  input  logic         io_exuWriteback_24_bits_debug_isNCIO,
  input  logic         io_exuWriteback_24_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_24_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_24_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_24_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_24_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_24_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_23_valid,
  input  logic [127:0] io_exuWriteback_23_bits_data_0,
  input  logic [6:0]   io_exuWriteback_23_bits_pdest,
  input  logic [7:0]   io_exuWriteback_23_bits_robIdx_value,
  input  logic         io_exuWriteback_23_bits_vecWen,
  input  logic         io_exuWriteback_23_bits_v0Wen,
  input  logic [2:0]   io_exuWriteback_23_bits_vls_vdIdx,
  input  logic         io_exuWriteback_23_bits_debug_isMMIO,
  input  logic         io_exuWriteback_23_bits_debug_isNCIO,
  input  logic         io_exuWriteback_23_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_23_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_23_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_23_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_23_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_23_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_22_valid,
  input  logic [63:0]  io_exuWriteback_22_bits_data_0,
  input  logic [7:0]   io_exuWriteback_22_bits_robIdx_value,
  input  logic [6:0]   io_exuWriteback_22_bits_lqIdx_value,
  input  logic         io_exuWriteback_22_bits_debug_isMMIO,
  input  logic         io_exuWriteback_22_bits_debug_isNCIO,
  input  logic         io_exuWriteback_22_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_22_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_22_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_22_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_22_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_22_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_21_valid,
  input  logic [63:0]  io_exuWriteback_21_bits_data_0,
  input  logic [7:0]   io_exuWriteback_21_bits_robIdx_value,
  input  logic [6:0]   io_exuWriteback_21_bits_lqIdx_value,
  input  logic         io_exuWriteback_21_bits_debug_isMMIO,
  input  logic         io_exuWriteback_21_bits_debug_isNCIO,
  input  logic         io_exuWriteback_21_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_21_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_21_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_21_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_21_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_21_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_20_valid,
  input  logic [63:0]  io_exuWriteback_20_bits_data_0,
  input  logic [7:0]   io_exuWriteback_20_bits_robIdx_value,
  input  logic [6:0]   io_exuWriteback_20_bits_lqIdx_value,
  input  logic         io_exuWriteback_20_bits_debug_isMMIO,
  input  logic         io_exuWriteback_20_bits_debug_isNCIO,
  input  logic         io_exuWriteback_20_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_20_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_20_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_20_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_20_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_20_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_19_valid,
  input  logic [63:0]  io_exuWriteback_19_bits_data_0,
  input  logic [7:0]   io_exuWriteback_19_bits_robIdx_value,
  input  logic [5:0]   io_exuWriteback_19_bits_sqIdx_value,
  input  logic         io_exuWriteback_19_bits_debug_isMMIO,
  input  logic         io_exuWriteback_19_bits_debug_isNCIO,
  input  logic         io_exuWriteback_19_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_19_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_19_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_19_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_19_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_19_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_18_valid,
  input  logic [63:0]  io_exuWriteback_18_bits_data_0,
  input  logic [7:0]   io_exuWriteback_18_bits_robIdx_value,
  input  logic [5:0]   io_exuWriteback_18_bits_sqIdx_value,
  input  logic         io_exuWriteback_18_bits_debug_isMMIO,
  input  logic         io_exuWriteback_18_bits_debug_isNCIO,
  input  logic         io_exuWriteback_18_bits_debug_isPerfCnt,
  input  logic [47:0]  io_exuWriteback_18_bits_debug_paddr,
  input  logic [63:0]  io_exuWriteback_18_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_18_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_18_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_18_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_17_valid,
  input  logic [127:0] io_exuWriteback_17_bits_data_0,
  input  logic [7:0]   io_exuWriteback_17_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_17_bits_fflags,
  input  logic         io_exuWriteback_17_bits_wflags,
  input  logic [63:0]  io_exuWriteback_17_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_17_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_17_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_17_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_16_valid,
  input  logic [127:0] io_exuWriteback_16_bits_data_0,
  input  logic [7:0]   io_exuWriteback_16_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_16_bits_fflags,
  input  logic         io_exuWriteback_16_bits_wflags,
  input  logic [63:0]  io_exuWriteback_16_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_16_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_16_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_16_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_15_valid,
  input  logic [127:0] io_exuWriteback_15_bits_data_0,
  input  logic [7:0]   io_exuWriteback_15_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_15_bits_fflags,
  input  logic         io_exuWriteback_15_bits_wflags,
  input  logic         io_exuWriteback_15_bits_vxsat,
  input  logic [63:0]  io_exuWriteback_15_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_15_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_15_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_15_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_14_valid,
  input  logic [127:0] io_exuWriteback_14_bits_data_0,
  input  logic [7:0]   io_exuWriteback_14_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_14_bits_fflags,
  input  logic         io_exuWriteback_14_bits_wflags,
  input  logic [63:0]  io_exuWriteback_14_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_14_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_14_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_14_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_13_valid,
  input  logic [127:0] io_exuWriteback_13_bits_data_0,
  input  logic [7:0]   io_exuWriteback_13_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_13_bits_fflags,
  input  logic         io_exuWriteback_13_bits_wflags,
  input  logic         io_exuWriteback_13_bits_vxsat,
  input  logic [63:0]  io_exuWriteback_13_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_13_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_13_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_13_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_12_valid,
  input  logic [63:0]  io_exuWriteback_12_bits_data_0,
  input  logic [7:0]   io_exuWriteback_12_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_12_bits_fflags,
  input  logic         io_exuWriteback_12_bits_wflags,
  input  logic [63:0]  io_exuWriteback_12_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_12_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_12_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_12_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_11_valid,
  input  logic [63:0]  io_exuWriteback_11_bits_data_0,
  input  logic [7:0]   io_exuWriteback_11_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_11_bits_fflags,
  input  logic         io_exuWriteback_11_bits_wflags,
  input  logic [63:0]  io_exuWriteback_11_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_11_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_11_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_11_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_10_valid,
  input  logic [63:0]  io_exuWriteback_10_bits_data_0,
  input  logic [7:0]   io_exuWriteback_10_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_10_bits_fflags,
  input  logic         io_exuWriteback_10_bits_wflags,
  input  logic [63:0]  io_exuWriteback_10_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_10_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_10_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_10_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_9_valid,
  input  logic [63:0]  io_exuWriteback_9_bits_data_0,
  input  logic [7:0]   io_exuWriteback_9_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_9_bits_fflags,
  input  logic         io_exuWriteback_9_bits_wflags,
  input  logic [63:0]  io_exuWriteback_9_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_9_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_9_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_9_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_8_valid,
  input  logic [127:0] io_exuWriteback_8_bits_data_0,
  input  logic [7:0]   io_exuWriteback_8_bits_robIdx_value,
  input  logic [4:0]   io_exuWriteback_8_bits_fflags,
  input  logic         io_exuWriteback_8_bits_wflags,
  input  logic [63:0]  io_exuWriteback_8_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_8_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_8_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_8_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_7_valid,
  input  logic [63:0]  io_exuWriteback_7_bits_data_0,
  input  logic [7:0]   io_exuWriteback_7_bits_robIdx_value,
  input  logic         io_exuWriteback_7_bits_debug_isPerfCnt,
  input  logic [63:0]  io_exuWriteback_7_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_7_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_7_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_7_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_6_valid,
  input  logic [63:0]  io_exuWriteback_6_bits_data_0,
  input  logic [7:0]   io_exuWriteback_6_bits_robIdx_value,
  input  logic [63:0]  io_exuWriteback_6_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_6_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_6_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_6_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_5_valid,
  input  logic [127:0] io_exuWriteback_5_bits_data_0,
  input  logic [7:0]   io_exuWriteback_5_bits_robIdx_value,
  input  logic         io_exuWriteback_5_bits_redirect_bits_cfiUpdate_taken,
  input  logic [4:0]   io_exuWriteback_5_bits_fflags,
  input  logic         io_exuWriteback_5_bits_wflags,
  input  logic [63:0]  io_exuWriteback_5_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_5_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_5_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_5_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_4_valid,
  input  logic [63:0]  io_exuWriteback_4_bits_data_0,
  input  logic [7:0]   io_exuWriteback_4_bits_robIdx_value,
  input  logic [63:0]  io_exuWriteback_4_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_4_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_4_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_4_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_3_valid,
  input  logic [63:0]  io_exuWriteback_3_bits_data_0,
  input  logic [7:0]   io_exuWriteback_3_bits_robIdx_value,
  input  logic         io_exuWriteback_3_bits_redirect_bits_cfiUpdate_taken,
  input  logic [63:0]  io_exuWriteback_3_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_3_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_3_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_3_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_2_valid,
  input  logic [63:0]  io_exuWriteback_2_bits_data_0,
  input  logic [7:0]   io_exuWriteback_2_bits_robIdx_value,
  input  logic [63:0]  io_exuWriteback_2_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_2_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_2_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_2_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_1_valid,
  input  logic [63:0]  io_exuWriteback_1_bits_data_0,
  input  logic [7:0]   io_exuWriteback_1_bits_robIdx_value,
  input  logic         io_exuWriteback_1_bits_redirect_bits_cfiUpdate_taken,
  input  logic [63:0]  io_exuWriteback_1_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_1_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_1_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_1_bits_debugInfo_writebackTime,
  input  logic         io_exuWriteback_0_valid,
  input  logic [63:0]  io_exuWriteback_0_bits_data_0,
  input  logic [7:0]   io_exuWriteback_0_bits_robIdx_value,
  input  logic [63:0]  io_exuWriteback_0_bits_debugInfo_enqRsTime,
  input  logic [63:0]  io_exuWriteback_0_bits_debugInfo_selectTime,
  input  logic [63:0]  io_exuWriteback_0_bits_debugInfo_issueTime,
  input  logic [63:0]  io_exuWriteback_0_bits_debugInfo_writebackTime,
  input  logic [4:0]   io_writebackNums_0_bits,
  input  logic [4:0]   io_writebackNums_1_bits,
  input  logic [4:0]   io_writebackNums_2_bits,
  input  logic [4:0]   io_writebackNums_3_bits,
  input  logic [4:0]   io_writebackNums_4_bits,
  input  logic [4:0]   io_writebackNums_5_bits,
  input  logic [4:0]   io_writebackNums_6_bits,
  input  logic [4:0]   io_writebackNums_7_bits,
  input  logic [4:0]   io_writebackNums_8_bits,
  input  logic [4:0]   io_writebackNums_9_bits,
  input  logic [4:0]   io_writebackNums_10_bits,
  input  logic [4:0]   io_writebackNums_11_bits,
  input  logic [4:0]   io_writebackNums_12_bits,
  input  logic [4:0]   io_writebackNums_13_bits,
  input  logic [4:0]   io_writebackNums_14_bits,
  input  logic [4:0]   io_writebackNums_15_bits,
  input  logic [4:0]   io_writebackNums_16_bits,
  input  logic [4:0]   io_writebackNums_17_bits,
  input  logic [4:0]   io_writebackNums_18_bits,
  input  logic [4:0]   io_writebackNums_19_bits,
  input  logic [4:0]   io_writebackNums_20_bits,
  input  logic [4:0]   io_writebackNums_21_bits,
  input  logic [4:0]   io_writebackNums_22_bits,
  input  logic [4:0]   io_writebackNums_23_bits,
  input  logic [4:0]   io_writebackNums_24_bits,
  input  logic         io_writebackNeedFlush_0,
  input  logic         io_writebackNeedFlush_1,
  input  logic         io_writebackNeedFlush_2,
  input  logic         io_writebackNeedFlush_6,
  input  logic         io_writebackNeedFlush_7,
  input  logic         io_writebackNeedFlush_8,
  input  logic         io_writebackNeedFlush_9,
  input  logic         io_writebackNeedFlush_10,
  input  logic         io_writebackNeedFlush_11,
  input  logic         io_writebackNeedFlush_12,
  output logic         io_commits_isCommit,
  output logic         io_commits_commitValid_0,
  output logic         io_commits_commitValid_1,
  output logic         io_commits_commitValid_2,
  output logic         io_commits_commitValid_3,
  output logic         io_commits_commitValid_4,
  output logic         io_commits_commitValid_5,
  output logic         io_commits_commitValid_6,
  output logic         io_commits_commitValid_7,
  output logic         io_commits_isWalk,
  output logic         io_commits_walkValid_0,
  output logic         io_commits_walkValid_1,
  output logic         io_commits_walkValid_2,
  output logic         io_commits_walkValid_3,
  output logic         io_commits_walkValid_4,
  output logic         io_commits_walkValid_5,
  output logic         io_commits_walkValid_6,
  output logic         io_commits_walkValid_7,
  output logic         io_commits_info_0_walk_v,
  output logic         io_commits_info_0_commit_v,
  output logic         io_commits_info_0_commit_w,
  output logic [6:0]   io_commits_info_0_realDestSize,
  output logic         io_commits_info_0_interrupt_safe,
  output logic         io_commits_info_0_wflags,
  output logic [4:0]   io_commits_info_0_fflags,
  output logic         io_commits_info_0_vxsat,
  output logic         io_commits_info_0_isRVC,
  output logic         io_commits_info_0_isVset,
  output logic         io_commits_info_0_isHls,
  output logic         io_commits_info_0_isVls,
  output logic         io_commits_info_0_vls,
  output logic         io_commits_info_0_mmio,
  output logic [2:0]   io_commits_info_0_commitType,
  output logic         io_commits_info_0_ftqIdx_flag,
  output logic [5:0]   io_commits_info_0_ftqIdx_value,
  output logic [3:0]   io_commits_info_0_ftqOffset,
  output logic [2:0]   io_commits_info_0_instrSize,
  output logic         io_commits_info_0_fpWen,
  output logic         io_commits_info_0_rfWen,
  output logic         io_commits_info_0_needFlush,
  output logic [3:0]   io_commits_info_0_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_0_traceBlockInPipe_iretire,
  output logic         io_commits_info_0_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_0_debug_pc,
  output logic [31:0]  io_commits_info_0_debug_instr,
  output logic [5:0]   io_commits_info_0_basicDebug_ldest,
  output logic [7:0]   io_commits_info_0_basicDebug_pdest,
  output logic [5:0]   io_commits_info_0_basicDebug_vd,
  output logic         io_commits_info_0_basicDebug_fpWen,
  output logic         io_commits_info_0_basicDebug_vecWen,
  output logic         io_commits_info_0_basicDebug_v0Wen,
  output logic         io_commits_info_0_basicDebug_eliminatedMove,
  output logic         io_commits_info_0_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_0_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_0_debug_fuType,
  output logic         io_commits_info_0_dirtyFs,
  output logic         io_commits_info_0_dirtyVs,
  output logic         io_commits_info_1_walk_v,
  output logic         io_commits_info_1_commit_v,
  output logic         io_commits_info_1_commit_w,
  output logic [6:0]   io_commits_info_1_realDestSize,
  output logic         io_commits_info_1_interrupt_safe,
  output logic         io_commits_info_1_wflags,
  output logic [4:0]   io_commits_info_1_fflags,
  output logic         io_commits_info_1_vxsat,
  output logic         io_commits_info_1_isRVC,
  output logic         io_commits_info_1_isVset,
  output logic         io_commits_info_1_isHls,
  output logic         io_commits_info_1_isVls,
  output logic         io_commits_info_1_vls,
  output logic         io_commits_info_1_mmio,
  output logic [2:0]   io_commits_info_1_commitType,
  output logic         io_commits_info_1_ftqIdx_flag,
  output logic [5:0]   io_commits_info_1_ftqIdx_value,
  output logic [3:0]   io_commits_info_1_ftqOffset,
  output logic [2:0]   io_commits_info_1_instrSize,
  output logic         io_commits_info_1_fpWen,
  output logic         io_commits_info_1_rfWen,
  output logic         io_commits_info_1_needFlush,
  output logic [3:0]   io_commits_info_1_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_1_traceBlockInPipe_iretire,
  output logic         io_commits_info_1_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_1_debug_pc,
  output logic [31:0]  io_commits_info_1_debug_instr,
  output logic [5:0]   io_commits_info_1_basicDebug_ldest,
  output logic [7:0]   io_commits_info_1_basicDebug_pdest,
  output logic [5:0]   io_commits_info_1_basicDebug_vd,
  output logic         io_commits_info_1_basicDebug_fpWen,
  output logic         io_commits_info_1_basicDebug_vecWen,
  output logic         io_commits_info_1_basicDebug_v0Wen,
  output logic         io_commits_info_1_basicDebug_eliminatedMove,
  output logic         io_commits_info_1_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_1_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_1_debug_fuType,
  output logic         io_commits_info_1_dirtyFs,
  output logic         io_commits_info_1_dirtyVs,
  output logic         io_commits_info_2_walk_v,
  output logic         io_commits_info_2_commit_v,
  output logic         io_commits_info_2_commit_w,
  output logic [6:0]   io_commits_info_2_realDestSize,
  output logic         io_commits_info_2_interrupt_safe,
  output logic         io_commits_info_2_wflags,
  output logic [4:0]   io_commits_info_2_fflags,
  output logic         io_commits_info_2_vxsat,
  output logic         io_commits_info_2_isRVC,
  output logic         io_commits_info_2_isVset,
  output logic         io_commits_info_2_isHls,
  output logic         io_commits_info_2_isVls,
  output logic         io_commits_info_2_vls,
  output logic         io_commits_info_2_mmio,
  output logic [2:0]   io_commits_info_2_commitType,
  output logic         io_commits_info_2_ftqIdx_flag,
  output logic [5:0]   io_commits_info_2_ftqIdx_value,
  output logic [3:0]   io_commits_info_2_ftqOffset,
  output logic [2:0]   io_commits_info_2_instrSize,
  output logic         io_commits_info_2_fpWen,
  output logic         io_commits_info_2_rfWen,
  output logic         io_commits_info_2_needFlush,
  output logic [3:0]   io_commits_info_2_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_2_traceBlockInPipe_iretire,
  output logic         io_commits_info_2_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_2_debug_pc,
  output logic [31:0]  io_commits_info_2_debug_instr,
  output logic [5:0]   io_commits_info_2_basicDebug_ldest,
  output logic [7:0]   io_commits_info_2_basicDebug_pdest,
  output logic [5:0]   io_commits_info_2_basicDebug_vd,
  output logic         io_commits_info_2_basicDebug_fpWen,
  output logic         io_commits_info_2_basicDebug_vecWen,
  output logic         io_commits_info_2_basicDebug_v0Wen,
  output logic         io_commits_info_2_basicDebug_eliminatedMove,
  output logic         io_commits_info_2_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_2_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_2_debug_fuType,
  output logic         io_commits_info_2_dirtyFs,
  output logic         io_commits_info_2_dirtyVs,
  output logic         io_commits_info_3_walk_v,
  output logic         io_commits_info_3_commit_v,
  output logic         io_commits_info_3_commit_w,
  output logic [6:0]   io_commits_info_3_realDestSize,
  output logic         io_commits_info_3_interrupt_safe,
  output logic         io_commits_info_3_wflags,
  output logic [4:0]   io_commits_info_3_fflags,
  output logic         io_commits_info_3_vxsat,
  output logic         io_commits_info_3_isRVC,
  output logic         io_commits_info_3_isVset,
  output logic         io_commits_info_3_isHls,
  output logic         io_commits_info_3_isVls,
  output logic         io_commits_info_3_vls,
  output logic         io_commits_info_3_mmio,
  output logic [2:0]   io_commits_info_3_commitType,
  output logic         io_commits_info_3_ftqIdx_flag,
  output logic [5:0]   io_commits_info_3_ftqIdx_value,
  output logic [3:0]   io_commits_info_3_ftqOffset,
  output logic [2:0]   io_commits_info_3_instrSize,
  output logic         io_commits_info_3_fpWen,
  output logic         io_commits_info_3_rfWen,
  output logic         io_commits_info_3_needFlush,
  output logic [3:0]   io_commits_info_3_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_3_traceBlockInPipe_iretire,
  output logic         io_commits_info_3_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_3_debug_pc,
  output logic [31:0]  io_commits_info_3_debug_instr,
  output logic [5:0]   io_commits_info_3_basicDebug_ldest,
  output logic [7:0]   io_commits_info_3_basicDebug_pdest,
  output logic [5:0]   io_commits_info_3_basicDebug_vd,
  output logic         io_commits_info_3_basicDebug_fpWen,
  output logic         io_commits_info_3_basicDebug_vecWen,
  output logic         io_commits_info_3_basicDebug_v0Wen,
  output logic         io_commits_info_3_basicDebug_eliminatedMove,
  output logic         io_commits_info_3_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_3_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_3_debug_fuType,
  output logic         io_commits_info_3_dirtyFs,
  output logic         io_commits_info_3_dirtyVs,
  output logic         io_commits_info_4_walk_v,
  output logic         io_commits_info_4_commit_v,
  output logic         io_commits_info_4_commit_w,
  output logic [6:0]   io_commits_info_4_realDestSize,
  output logic         io_commits_info_4_interrupt_safe,
  output logic         io_commits_info_4_wflags,
  output logic [4:0]   io_commits_info_4_fflags,
  output logic         io_commits_info_4_vxsat,
  output logic         io_commits_info_4_isRVC,
  output logic         io_commits_info_4_isVset,
  output logic         io_commits_info_4_isHls,
  output logic         io_commits_info_4_isVls,
  output logic         io_commits_info_4_vls,
  output logic         io_commits_info_4_mmio,
  output logic [2:0]   io_commits_info_4_commitType,
  output logic         io_commits_info_4_ftqIdx_flag,
  output logic [5:0]   io_commits_info_4_ftqIdx_value,
  output logic [3:0]   io_commits_info_4_ftqOffset,
  output logic [2:0]   io_commits_info_4_instrSize,
  output logic         io_commits_info_4_fpWen,
  output logic         io_commits_info_4_rfWen,
  output logic         io_commits_info_4_needFlush,
  output logic [3:0]   io_commits_info_4_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_4_traceBlockInPipe_iretire,
  output logic         io_commits_info_4_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_4_debug_pc,
  output logic [31:0]  io_commits_info_4_debug_instr,
  output logic [5:0]   io_commits_info_4_basicDebug_ldest,
  output logic [7:0]   io_commits_info_4_basicDebug_pdest,
  output logic [5:0]   io_commits_info_4_basicDebug_vd,
  output logic         io_commits_info_4_basicDebug_fpWen,
  output logic         io_commits_info_4_basicDebug_vecWen,
  output logic         io_commits_info_4_basicDebug_v0Wen,
  output logic         io_commits_info_4_basicDebug_eliminatedMove,
  output logic         io_commits_info_4_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_4_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_4_debug_fuType,
  output logic         io_commits_info_4_dirtyFs,
  output logic         io_commits_info_4_dirtyVs,
  output logic         io_commits_info_5_walk_v,
  output logic         io_commits_info_5_commit_v,
  output logic         io_commits_info_5_commit_w,
  output logic [6:0]   io_commits_info_5_realDestSize,
  output logic         io_commits_info_5_interrupt_safe,
  output logic         io_commits_info_5_wflags,
  output logic [4:0]   io_commits_info_5_fflags,
  output logic         io_commits_info_5_vxsat,
  output logic         io_commits_info_5_isRVC,
  output logic         io_commits_info_5_isVset,
  output logic         io_commits_info_5_isHls,
  output logic         io_commits_info_5_isVls,
  output logic         io_commits_info_5_vls,
  output logic         io_commits_info_5_mmio,
  output logic [2:0]   io_commits_info_5_commitType,
  output logic         io_commits_info_5_ftqIdx_flag,
  output logic [5:0]   io_commits_info_5_ftqIdx_value,
  output logic [3:0]   io_commits_info_5_ftqOffset,
  output logic [2:0]   io_commits_info_5_instrSize,
  output logic         io_commits_info_5_fpWen,
  output logic         io_commits_info_5_rfWen,
  output logic         io_commits_info_5_needFlush,
  output logic [3:0]   io_commits_info_5_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_5_traceBlockInPipe_iretire,
  output logic         io_commits_info_5_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_5_debug_pc,
  output logic [31:0]  io_commits_info_5_debug_instr,
  output logic [5:0]   io_commits_info_5_basicDebug_ldest,
  output logic [7:0]   io_commits_info_5_basicDebug_pdest,
  output logic [5:0]   io_commits_info_5_basicDebug_vd,
  output logic         io_commits_info_5_basicDebug_fpWen,
  output logic         io_commits_info_5_basicDebug_vecWen,
  output logic         io_commits_info_5_basicDebug_v0Wen,
  output logic         io_commits_info_5_basicDebug_eliminatedMove,
  output logic         io_commits_info_5_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_5_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_5_debug_fuType,
  output logic         io_commits_info_5_dirtyFs,
  output logic         io_commits_info_5_dirtyVs,
  output logic         io_commits_info_6_walk_v,
  output logic         io_commits_info_6_commit_v,
  output logic         io_commits_info_6_commit_w,
  output logic [6:0]   io_commits_info_6_realDestSize,
  output logic         io_commits_info_6_interrupt_safe,
  output logic         io_commits_info_6_wflags,
  output logic [4:0]   io_commits_info_6_fflags,
  output logic         io_commits_info_6_vxsat,
  output logic         io_commits_info_6_isRVC,
  output logic         io_commits_info_6_isVset,
  output logic         io_commits_info_6_isHls,
  output logic         io_commits_info_6_isVls,
  output logic         io_commits_info_6_vls,
  output logic         io_commits_info_6_mmio,
  output logic [2:0]   io_commits_info_6_commitType,
  output logic         io_commits_info_6_ftqIdx_flag,
  output logic [5:0]   io_commits_info_6_ftqIdx_value,
  output logic [3:0]   io_commits_info_6_ftqOffset,
  output logic [2:0]   io_commits_info_6_instrSize,
  output logic         io_commits_info_6_fpWen,
  output logic         io_commits_info_6_rfWen,
  output logic         io_commits_info_6_needFlush,
  output logic [3:0]   io_commits_info_6_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_6_traceBlockInPipe_iretire,
  output logic         io_commits_info_6_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_6_debug_pc,
  output logic [31:0]  io_commits_info_6_debug_instr,
  output logic [5:0]   io_commits_info_6_basicDebug_ldest,
  output logic [7:0]   io_commits_info_6_basicDebug_pdest,
  output logic [5:0]   io_commits_info_6_basicDebug_vd,
  output logic         io_commits_info_6_basicDebug_fpWen,
  output logic         io_commits_info_6_basicDebug_vecWen,
  output logic         io_commits_info_6_basicDebug_v0Wen,
  output logic         io_commits_info_6_basicDebug_eliminatedMove,
  output logic         io_commits_info_6_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_6_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_6_debug_fuType,
  output logic         io_commits_info_6_dirtyFs,
  output logic         io_commits_info_6_dirtyVs,
  output logic         io_commits_info_7_walk_v,
  output logic         io_commits_info_7_commit_v,
  output logic         io_commits_info_7_commit_w,
  output logic [6:0]   io_commits_info_7_realDestSize,
  output logic         io_commits_info_7_interrupt_safe,
  output logic         io_commits_info_7_wflags,
  output logic [4:0]   io_commits_info_7_fflags,
  output logic         io_commits_info_7_vxsat,
  output logic         io_commits_info_7_isRVC,
  output logic         io_commits_info_7_isVset,
  output logic         io_commits_info_7_isHls,
  output logic         io_commits_info_7_isVls,
  output logic         io_commits_info_7_vls,
  output logic         io_commits_info_7_mmio,
  output logic [2:0]   io_commits_info_7_commitType,
  output logic         io_commits_info_7_ftqIdx_flag,
  output logic [5:0]   io_commits_info_7_ftqIdx_value,
  output logic [3:0]   io_commits_info_7_ftqOffset,
  output logic [2:0]   io_commits_info_7_instrSize,
  output logic         io_commits_info_7_fpWen,
  output logic         io_commits_info_7_rfWen,
  output logic         io_commits_info_7_needFlush,
  output logic [3:0]   io_commits_info_7_traceBlockInPipe_itype,
  output logic [3:0]   io_commits_info_7_traceBlockInPipe_iretire,
  output logic         io_commits_info_7_traceBlockInPipe_ilastsize,
  output logic [49:0]  io_commits_info_7_debug_pc,
  output logic [31:0]  io_commits_info_7_debug_instr,
  output logic [5:0]   io_commits_info_7_basicDebug_ldest,
  output logic [7:0]   io_commits_info_7_basicDebug_pdest,
  output logic [5:0]   io_commits_info_7_basicDebug_vd,
  output logic         io_commits_info_7_basicDebug_fpWen,
  output logic         io_commits_info_7_basicDebug_vecWen,
  output logic         io_commits_info_7_basicDebug_v0Wen,
  output logic         io_commits_info_7_basicDebug_eliminatedMove,
  output logic         io_commits_info_7_basicDebug_isXSTrap,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_0,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_1,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_2,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_3,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_4,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_5,
  output logic [7:0]   io_commits_info_7_debug_otherPdest_6,
  output logic [34:0]  io_commits_info_7_debug_fuType,
  output logic         io_commits_info_7_dirtyFs,
  output logic         io_commits_info_7_dirtyVs,
  output logic         io_commits_robIdx_0_flag,
  output logic [7:0]   io_commits_robIdx_0_value,
  output logic         io_commits_robIdx_1_flag,
  output logic [7:0]   io_commits_robIdx_1_value,
  output logic         io_commits_robIdx_2_flag,
  output logic [7:0]   io_commits_robIdx_2_value,
  output logic         io_commits_robIdx_3_flag,
  output logic [7:0]   io_commits_robIdx_3_value,
  output logic         io_commits_robIdx_4_flag,
  output logic [7:0]   io_commits_robIdx_4_value,
  output logic         io_commits_robIdx_5_flag,
  output logic [7:0]   io_commits_robIdx_5_value,
  output logic         io_commits_robIdx_6_flag,
  output logic [7:0]   io_commits_robIdx_6_value,
  output logic         io_commits_robIdx_7_flag,
  output logic [7:0]   io_commits_robIdx_7_value,
  input  logic         io_trace_blockCommit,
  output logic         io_trace_traceCommitInfo_blocks_0_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_0_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_0_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_0_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_0_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_0_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_1_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_1_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_1_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_1_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_1_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_1_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_2_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_2_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_2_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_2_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_2_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_2_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_3_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_3_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_3_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_3_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_3_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_3_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_4_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_4_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_4_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_4_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_4_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_4_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_5_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_5_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_5_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_5_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_5_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_5_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_6_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_6_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_6_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_6_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_6_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_6_bits_tracePipe_ilastsize,
  output logic         io_trace_traceCommitInfo_blocks_7_valid,
  output logic [5:0]   io_trace_traceCommitInfo_blocks_7_bits_ftqIdx_value,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_7_bits_ftqOffset,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_7_bits_tracePipe_itype,
  output logic [3:0]   io_trace_traceCommitInfo_blocks_7_bits_tracePipe_iretire,
  output logic         io_trace_traceCommitInfo_blocks_7_bits_tracePipe_ilastsize,
  output logic         io_rabCommits_isCommit,
  output logic         io_rabCommits_commitValid_0,
  output logic         io_rabCommits_commitValid_1,
  output logic         io_rabCommits_commitValid_2,
  output logic         io_rabCommits_commitValid_3,
  output logic         io_rabCommits_commitValid_4,
  output logic         io_rabCommits_commitValid_5,
  output logic         io_rabCommits_isWalk,
  output logic         io_rabCommits_walkValid_0,
  output logic         io_rabCommits_walkValid_1,
  output logic         io_rabCommits_walkValid_2,
  output logic         io_rabCommits_walkValid_3,
  output logic         io_rabCommits_walkValid_4,
  output logic         io_rabCommits_walkValid_5,
  output logic [5:0]   io_rabCommits_info_0_ldest,
  output logic [7:0]   io_rabCommits_info_0_pdest,
  output logic         io_rabCommits_info_0_rfWen,
  output logic         io_rabCommits_info_0_fpWen,
  output logic         io_rabCommits_info_0_vecWen,
  output logic         io_rabCommits_info_0_v0Wen,
  output logic         io_rabCommits_info_0_vlWen,
  output logic         io_rabCommits_info_0_isMove,
  output logic [5:0]   io_rabCommits_info_1_ldest,
  output logic [7:0]   io_rabCommits_info_1_pdest,
  output logic         io_rabCommits_info_1_rfWen,
  output logic         io_rabCommits_info_1_fpWen,
  output logic         io_rabCommits_info_1_vecWen,
  output logic         io_rabCommits_info_1_v0Wen,
  output logic         io_rabCommits_info_1_vlWen,
  output logic         io_rabCommits_info_1_isMove,
  output logic [5:0]   io_rabCommits_info_2_ldest,
  output logic [7:0]   io_rabCommits_info_2_pdest,
  output logic         io_rabCommits_info_2_rfWen,
  output logic         io_rabCommits_info_2_fpWen,
  output logic         io_rabCommits_info_2_vecWen,
  output logic         io_rabCommits_info_2_v0Wen,
  output logic         io_rabCommits_info_2_vlWen,
  output logic         io_rabCommits_info_2_isMove,
  output logic [5:0]   io_rabCommits_info_3_ldest,
  output logic [7:0]   io_rabCommits_info_3_pdest,
  output logic         io_rabCommits_info_3_rfWen,
  output logic         io_rabCommits_info_3_fpWen,
  output logic         io_rabCommits_info_3_vecWen,
  output logic         io_rabCommits_info_3_v0Wen,
  output logic         io_rabCommits_info_3_vlWen,
  output logic         io_rabCommits_info_3_isMove,
  output logic [5:0]   io_rabCommits_info_4_ldest,
  output logic [7:0]   io_rabCommits_info_4_pdest,
  output logic         io_rabCommits_info_4_rfWen,
  output logic         io_rabCommits_info_4_fpWen,
  output logic         io_rabCommits_info_4_vecWen,
  output logic         io_rabCommits_info_4_v0Wen,
  output logic         io_rabCommits_info_4_vlWen,
  output logic         io_rabCommits_info_4_isMove,
  output logic [5:0]   io_rabCommits_info_5_ldest,
  output logic [7:0]   io_rabCommits_info_5_pdest,
  output logic         io_rabCommits_info_5_rfWen,
  output logic         io_rabCommits_info_5_fpWen,
  output logic         io_rabCommits_info_5_vecWen,
  output logic         io_rabCommits_info_5_v0Wen,
  output logic         io_rabCommits_info_5_vlWen,
  output logic         io_rabCommits_info_5_isMove,
  output logic         io_diffRatCommitRobIdx_valid,
  output logic         io_diffRatCommitRobIdx_bits_flag,
  output logic [7:0]   io_diffRatCommitRobIdx_bits_value,
  output logic [3:0]   io_lsq_scommit,
  output logic         io_lsq_pendingMMIOld,
  output logic         io_lsq_pendingst,
  output logic         io_lsq_pendingPtr_flag,
  output logic [7:0]   io_lsq_pendingPtr_value,
  input  logic         io_lsq_loadMmio_0,
  input  logic         io_lsq_loadMmio_1,
  input  logic         io_lsq_loadMmio_2,
  input  logic [7:0]   io_lsq_loadMmioUop_0_robIdx_value,
  input  logic [7:0]   io_lsq_loadMmioUop_1_robIdx_value,
  input  logic [7:0]   io_lsq_loadMmioUop_2_robIdx_value,
  input  logic         io_lsq_storeMmio,
  input  logic [7:0]   io_lsq_storeMmioUop_robIdx_value,
  output logic         io_robDeqPtr_flag,
  output logic [7:0]   io_robDeqPtr_value,
  input  logic         io_csr_intrBitSet,
  input  logic         io_csr_wfiEvent,
  input  logic         io_csr_criticalErrorState,
  output logic         io_csr_fflags_valid,
  output logic [4:0]   io_csr_fflags_bits,
  output logic         io_csr_vxsat_valid,
  output logic         io_csr_vxsat_bits,
  output logic         io_csr_vstart_valid,
  output logic [63:0]  io_csr_vstart_bits,
  output logic         io_csr_dirty_fs,
  output logic         io_csr_dirty_vs,
  output logic [6:0]   io_csr_perfinfo_retiredInstr,
  input  logic         io_snpt_snptDeq,
  input  logic         io_snpt_useSnpt,
  input  logic [1:0]   io_snpt_snptSelect,
  input  logic         io_snpt_flushVec_0,
  input  logic         io_snpt_flushVec_1,
  input  logic         io_snpt_flushVec_2,
  input  logic         io_snpt_flushVec_3,
  output logic         io_headNotReady,
  output logic         io_cpu_halt,
  output logic         io_wfi_wfiReq,
  input  logic         io_wfi_safeFromMem,
  input  logic         io_wfi_safeFromFrontend,
  input  logic         io_wfi_enable,
  output logic         io_toDecode_isResumeVType,
  output logic         io_toDecode_walkToArchVType,
  output logic         io_toDecode_walkVType_valid,
  output logic         io_toDecode_walkVType_bits_illegal,
  output logic         io_toDecode_walkVType_bits_vma,
  output logic         io_toDecode_walkVType_bits_vta,
  output logic [1:0]   io_toDecode_walkVType_bits_vsew,
  output logic [2:0]   io_toDecode_walkVType_bits_vlmul,
  output logic         io_toDecode_commitVType_vtype_valid,
  output logic         io_toDecode_commitVType_vtype_bits_illegal,
  output logic         io_toDecode_commitVType_vtype_bits_vma,
  output logic         io_toDecode_commitVType_vtype_bits_vta,
  output logic [1:0]   io_toDecode_commitVType_vtype_bits_vsew,
  output logic [2:0]   io_toDecode_commitVType_vtype_bits_vlmul,
  output logic         io_toDecode_commitVType_hasVsetvl,
  input  logic         io_fromVecExcpMod_busy,
  output logic         io_readGPAMemAddr_valid,
  output logic [5:0]   io_readGPAMemAddr_bits_ftqPtr_value,
  output logic [3:0]   io_readGPAMemAddr_bits_ftqOffset,
  input  logic [55:0]  io_readGPAMemData_gpaddr,
  input  logic         io_readGPAMemData_isForVSnonLeafPTE,
  input  logic         io_vstartIsZero,
  output logic         io_toVecExcpMod_logicPhyRegMap_0_valid,
  output logic [5:0]   io_toVecExcpMod_logicPhyRegMap_0_bits_lreg,
  output logic [6:0]   io_toVecExcpMod_logicPhyRegMap_0_bits_preg,
  output logic         io_toVecExcpMod_logicPhyRegMap_1_valid,
  output logic [5:0]   io_toVecExcpMod_logicPhyRegMap_1_bits_lreg,
  output logic [6:0]   io_toVecExcpMod_logicPhyRegMap_1_bits_preg,
  output logic         io_toVecExcpMod_logicPhyRegMap_2_valid,
  output logic [5:0]   io_toVecExcpMod_logicPhyRegMap_2_bits_lreg,
  output logic [6:0]   io_toVecExcpMod_logicPhyRegMap_2_bits_preg,
  output logic         io_toVecExcpMod_logicPhyRegMap_3_valid,
  output logic [5:0]   io_toVecExcpMod_logicPhyRegMap_3_bits_lreg,
  output logic [6:0]   io_toVecExcpMod_logicPhyRegMap_3_bits_preg,
  output logic         io_toVecExcpMod_logicPhyRegMap_4_valid,
  output logic [5:0]   io_toVecExcpMod_logicPhyRegMap_4_bits_lreg,
  output logic [6:0]   io_toVecExcpMod_logicPhyRegMap_4_bits_preg,
  output logic         io_toVecExcpMod_logicPhyRegMap_5_valid,
  output logic [5:0]   io_toVecExcpMod_logicPhyRegMap_5_bits_lreg,
  output logic [6:0]   io_toVecExcpMod_logicPhyRegMap_5_bits_preg,
  output logic         io_toVecExcpMod_excpInfo_valid,
  output logic [6:0]   io_toVecExcpMod_excpInfo_bits_vstart,
  output logic [1:0]   io_toVecExcpMod_excpInfo_bits_vsew,
  output logic [1:0]   io_toVecExcpMod_excpInfo_bits_veew,
  output logic [2:0]   io_toVecExcpMod_excpInfo_bits_vlmul,
  output logic [2:0]   io_toVecExcpMod_excpInfo_bits_nf,
  output logic         io_toVecExcpMod_excpInfo_bits_isStride,
  output logic         io_toVecExcpMod_excpInfo_bits_isIndexed,
  output logic         io_toVecExcpMod_excpInfo_bits_isWhole,
  output logic         io_toVecExcpMod_excpInfo_bits_isVlm,
  output logic [34:0]  io_debugRobHead_debug_fuType,
  input  logic         io_debugEnqLsq_canAccept,
  input  logic [1:0]   io_debugEnqLsq_needAlloc_0,
  input  logic [1:0]   io_debugEnqLsq_needAlloc_1,
  input  logic [1:0]   io_debugEnqLsq_needAlloc_2,
  input  logic [1:0]   io_debugEnqLsq_needAlloc_3,
  input  logic [1:0]   io_debugEnqLsq_needAlloc_4,
  input  logic [1:0]   io_debugEnqLsq_needAlloc_5,
  input  logic         io_debugEnqLsq_req_0_valid,
  input  logic [7:0]   io_debugEnqLsq_req_0_bits_robIdx_value,
  input  logic [6:0]   io_debugEnqLsq_req_0_bits_lqIdx_value,
  input  logic         io_debugEnqLsq_req_1_valid,
  input  logic [7:0]   io_debugEnqLsq_req_1_bits_robIdx_value,
  input  logic [6:0]   io_debugEnqLsq_req_1_bits_lqIdx_value,
  input  logic         io_debugEnqLsq_req_2_valid,
  input  logic [7:0]   io_debugEnqLsq_req_2_bits_robIdx_value,
  input  logic [6:0]   io_debugEnqLsq_req_2_bits_lqIdx_value,
  input  logic         io_debugEnqLsq_req_3_valid,
  input  logic [7:0]   io_debugEnqLsq_req_3_bits_robIdx_value,
  input  logic [6:0]   io_debugEnqLsq_req_3_bits_lqIdx_value,
  input  logic         io_debugEnqLsq_req_4_valid,
  input  logic [7:0]   io_debugEnqLsq_req_4_bits_robIdx_value,
  input  logic [6:0]   io_debugEnqLsq_req_4_bits_lqIdx_value,
  input  logic         io_debugEnqLsq_req_5_valid,
  input  logic [7:0]   io_debugEnqLsq_req_5_bits_robIdx_value,
  input  logic [6:0]   io_debugEnqLsq_req_5_bits_lqIdx_value,
  input  logic         io_debugHeadLsIssue,
  input  logic [7:0]   io_lsTopdownInfo_0_s1_robIdx,
  input  logic         io_lsTopdownInfo_0_s1_vaddr_valid,
  input  logic [49:0]  io_lsTopdownInfo_0_s1_vaddr_bits,
  input  logic [7:0]   io_lsTopdownInfo_0_s2_robIdx,
  input  logic         io_lsTopdownInfo_0_s2_paddr_valid,
  input  logic [47:0]  io_lsTopdownInfo_0_s2_paddr_bits,
  input  logic [7:0]   io_lsTopdownInfo_1_s1_robIdx,
  input  logic         io_lsTopdownInfo_1_s1_vaddr_valid,
  input  logic [49:0]  io_lsTopdownInfo_1_s1_vaddr_bits,
  input  logic [7:0]   io_lsTopdownInfo_1_s2_robIdx,
  input  logic         io_lsTopdownInfo_1_s2_paddr_valid,
  input  logic [47:0]  io_lsTopdownInfo_1_s2_paddr_bits,
  input  logic [7:0]   io_lsTopdownInfo_2_s1_robIdx,
  input  logic         io_lsTopdownInfo_2_s1_vaddr_valid,
  input  logic [49:0]  io_lsTopdownInfo_2_s1_vaddr_bits,
  input  logic [7:0]   io_lsTopdownInfo_2_s2_robIdx,
  input  logic         io_lsTopdownInfo_2_s2_paddr_valid,
  input  logic [47:0]  io_lsTopdownInfo_2_s2_paddr_bits,
  output logic         io_debugTopDown_toCore_robHeadVaddr_valid,
  output logic [49:0]  io_debugTopDown_toCore_robHeadVaddr_bits,
  output logic         io_debugTopDown_toCore_robHeadPaddr_valid,
  output logic [47:0]  io_debugTopDown_toCore_robHeadPaddr_bits,
  output logic         io_debugTopDown_toDispatch_robHeadLsIssue,
  input  logic         io_debugInstrAddrTransType_bare,
  input  logic         io_debugInstrAddrTransType_sv39,
  input  logic         io_debugInstrAddrTransType_sv39x4,
  input  logic         io_debugInstrAddrTransType_sv48,
  input  logic         io_debugInstrAddrTransType_sv48x4,
  input  logic [7:0]   io_storeDebugInfo_0_robidx_value,
  output logic [49:0]  io_storeDebugInfo_0_pc,
  input  logic [7:0]   io_storeDebugInfo_1_robidx_value,
  output logic [49:0]  io_storeDebugInfo_1_pc,
  output logic [5:0]   io_perf_0_value,
  output logic [5:0]   io_perf_1_value,
  output logic [5:0]   io_perf_2_value,
  output logic [5:0]   io_perf_3_value,
  output logic [5:0]   io_perf_4_value,
  output logic [5:0]   io_perf_5_value,
  output logic [5:0]   io_perf_6_value,
  output logic [5:0]   io_perf_7_value,
  output logic [5:0]   io_perf_8_value,
  output logic [5:0]   io_perf_9_value,
  output logic [5:0]   io_perf_10_value,
  output logic [5:0]   io_perf_11_value,
  output logic [5:0]   io_perf_12_value,
  output logic [5:0]   io_perf_13_value,
  output logic [5:0]   io_perf_14_value,
  output logic [5:0]   io_perf_15_value,
  output logic [5:0]   io_perf_16_value,
  output logic [5:0]   io_perf_17_value,
  output logic [5:0]   io_perf_18_value,
  output logic         io_error_0,
  output logic [321:0] gatewayIn_packed_6_bore,
  output logic [91:0]  gatewayIn_packed_7_bore,
  output logic [321:0] gatewayIn_packed_8_bore,
  output logic [91:0]  gatewayIn_packed_9_bore,
  output logic [321:0] gatewayIn_packed_10_bore,
  output logic [91:0]  gatewayIn_packed_11_bore,
  output logic [321:0] gatewayIn_packed_12_bore,
  output logic [91:0]  gatewayIn_packed_13_bore,
  output logic [321:0] gatewayIn_packed_14_bore,
  output logic [91:0]  gatewayIn_packed_15_bore,
  output logic [321:0] gatewayIn_packed_16_bore,
  output logic [91:0]  gatewayIn_packed_17_bore,
  output logic [321:0] gatewayIn_packed_18_bore,
  output logic [91:0]  gatewayIn_packed_19_bore,
  output logic [321:0] gatewayIn_packed_20_bore,
  output logic [91:0]  gatewayIn_packed_21_bore,
  output logic [265:0] gatewayIn_packed_22_bore
  // END GENERATED
);

  // BEGIN GENERATED(wrapper_nets)
  logic [7:0] n_allocatePtrVec_1_value;
  logic [7:0] n_allocatePtrVec_2_value;
  logic [7:0] n_allocatePtrVec_3_value;
  logic [7:0] n_allocatePtrVec_4_value;
  logic [7:0] n_allocatePtrVec_5_value;
  logic n_allowOnlyOneCommit;
  logic n_blockCommit;
  logic n_canEnqueueEG_0;
  logic n_canEnqueueEG_1;
  logic n_canEnqueueEG_2;
  logic n_canEnqueueEG_3;
  logic n_canEnqueueEG_4;
  logic n_canEnqueueEG_5;
  logic n_canEnqueue_0;
  logic n_canEnqueue_1;
  logic n_canEnqueue_2;
  logic n_canEnqueue_3;
  logic n_canEnqueue_4;
  logic n_canEnqueue_5;
  logic n_commitStuckCounter_io_overflow;
  logic n_commit_vDeqGroup_0;
  logic n_commit_vDeqGroup_1;
  logic n_commit_vDeqGroup_2;
  logic n_commit_vDeqGroup_3;
  logic n_commit_vDeqGroup_4;
  logic n_commit_vDeqGroup_5;
  logic n_commit_vDeqGroup_6;
  logic n_commit_vDeqGroup_7;
  logic n_commit_wDeqGroup_0;
  logic n_commit_wDeqGroup_1;
  logic n_commit_wDeqGroup_2;
  logic n_commit_wDeqGroup_3;
  logic n_commit_wDeqGroup_4;
  logic n_commit_wDeqGroup_5;
  logic n_commit_wDeqGroup_6;
  logic n_commit_wDeqGroup_7;
  logic n_deqPtrVec_0_flag;
  logic [7:0] n_deqPtrVec_0_value;
  logic n_deqPtrVec_1_flag;
  logic [7:0] n_deqPtrVec_1_value;
  logic n_deqPtrVec_2_flag;
  logic [7:0] n_deqPtrVec_2_value;
  logic n_deqPtrVec_3_flag;
  logic [7:0] n_deqPtrVec_3_value;
  logic n_deqPtrVec_4_flag;
  logic [7:0] n_deqPtrVec_4_value;
  logic n_deqPtrVec_5_flag;
  logic [7:0] n_deqPtrVec_5_value;
  logic n_deqPtrVec_6_flag;
  logic [7:0] n_deqPtrVec_6_value;
  logic n_deqPtrVec_7_flag;
  logic [7:0] n_deqPtrVec_7_value;
  logic n_deqPtrVec_next_0_flag;
  logic [7:0] n_deqPtrVec_next_0_value;
  logic n_deqPtrVec_next_1_flag;
  logic [7:0] n_deqPtrVec_next_1_value;
  logic n_deqPtrVec_next_2_flag;
  logic [7:0] n_deqPtrVec_next_2_value;
  logic n_deqPtrVec_next_3_flag;
  logic [7:0] n_deqPtrVec_next_3_value;
  logic n_deqPtrVec_next_4_flag;
  logic [7:0] n_deqPtrVec_next_4_value;
  logic n_deqPtrVec_next_5_flag;
  logic [7:0] n_deqPtrVec_next_5_value;
  logic n_deqPtrVec_next_6_flag;
  logic [7:0] n_deqPtrVec_next_6_value;
  logic n_deqPtrVec_next_7_flag;
  logic [7:0] n_deqPtrVec_next_7_value;
  logic [1:0] n_dtPcTransTypeWdata;   // golden: _GEN_3539
  logic [1:0] n_dt_pcTransType_ext_R0_data;
  logic [1:0] n_dt_pcTransType_ext_R1_data;
  logic [1:0] n_dt_pcTransType_ext_R2_data;
  logic [1:0] n_dt_pcTransType_ext_R3_data;
  logic [1:0] n_dt_pcTransType_ext_R4_data;
  logic [1:0] n_dt_pcTransType_ext_R5_data;
  logic [1:0] n_dt_pcTransType_ext_R6_data;
  logic [1:0] n_dt_pcTransType_ext_R7_data;
  logic n_enqFirstUopValid_0;   // golden: _dispatchNum_T
  logic n_enqFirstUopValid_1;   // golden: _dispatchNum_T_1
  logic n_enqFirstUopValid_2;   // golden: _dispatchNum_T_2
  logic n_enqFirstUopValid_3;   // golden: _dispatchNum_T_3
  logic n_enqFirstUopValid_4;   // golden: _dispatchNum_T_4
  logic n_enqFirstUopValid_5;   // golden: _dispatchNum_T_5
  logic n_enqPtrVec_0_flag;
  logic [7:0] n_enqPtrVec_0_value;
  logic n_enqPtrVec_1_flag;
  logic [7:0] n_enqPtrVec_1_value;
  logic n_enqPtrVec_2_flag;
  logic [7:0] n_enqPtrVec_2_value;
  logic n_enqPtrVec_3_flag;
  logic [7:0] n_enqPtrVec_3_value;
  logic n_enqPtrVec_4_flag;
  logic [7:0] n_enqPtrVec_4_value;
  logic n_enqPtrVec_5_flag;
  logic [7:0] n_enqPtrVec_5_value;
  logic n_exceptionGen_io_state_bits_crossPageIPFFix;
  logic n_exceptionGen_io_state_bits_exceptionVec_0;
  logic n_exceptionGen_io_state_bits_exceptionVec_1;
  logic n_exceptionGen_io_state_bits_exceptionVec_10;
  logic n_exceptionGen_io_state_bits_exceptionVec_11;
  logic n_exceptionGen_io_state_bits_exceptionVec_12;
  logic n_exceptionGen_io_state_bits_exceptionVec_13;
  logic n_exceptionGen_io_state_bits_exceptionVec_14;
  logic n_exceptionGen_io_state_bits_exceptionVec_15;
  logic n_exceptionGen_io_state_bits_exceptionVec_16;
  logic n_exceptionGen_io_state_bits_exceptionVec_17;
  logic n_exceptionGen_io_state_bits_exceptionVec_18;
  logic n_exceptionGen_io_state_bits_exceptionVec_19;
  logic n_exceptionGen_io_state_bits_exceptionVec_2;
  logic n_exceptionGen_io_state_bits_exceptionVec_20;
  logic n_exceptionGen_io_state_bits_exceptionVec_21;
  logic n_exceptionGen_io_state_bits_exceptionVec_22;
  logic n_exceptionGen_io_state_bits_exceptionVec_23;
  logic n_exceptionGen_io_state_bits_exceptionVec_3;
  logic n_exceptionGen_io_state_bits_exceptionVec_4;
  logic n_exceptionGen_io_state_bits_exceptionVec_5;
  logic n_exceptionGen_io_state_bits_exceptionVec_6;
  logic n_exceptionGen_io_state_bits_exceptionVec_7;
  logic n_exceptionGen_io_state_bits_exceptionVec_8;
  logic n_exceptionGen_io_state_bits_exceptionVec_9;
  logic n_exceptionGen_io_state_bits_flushPipe;
  logic n_exceptionGen_io_state_bits_hasException;
  logic n_exceptionGen_io_state_bits_isEnqExcp;
  logic n_exceptionGen_io_state_bits_isFetchMalAddr;
  logic n_exceptionGen_io_state_bits_isIndexed;
  logic n_exceptionGen_io_state_bits_isStrided;
  logic n_exceptionGen_io_state_bits_isVecLoad;
  logic n_exceptionGen_io_state_bits_isVlm;
  logic n_exceptionGen_io_state_bits_isVset;
  logic n_exceptionGen_io_state_bits_isWhole;
  logic [2:0] n_exceptionGen_io_state_bits_nf;
  logic n_exceptionGen_io_state_bits_replayInst;
  logic n_exceptionGen_io_state_bits_robIdx_flag;
  logic [7:0] n_exceptionGen_io_state_bits_robIdx_value;
  logic n_exceptionGen_io_state_bits_satpFlushFirstFetchFault;
  logic n_exceptionGen_io_state_bits_satpFlushPipe;
  logic n_exceptionGen_io_state_bits_singleStep;
  logic [3:0] n_exceptionGen_io_state_bits_trigger;
  logic [1:0] n_exceptionGen_io_state_bits_veew;
  logic [2:0] n_exceptionGen_io_state_bits_vlmul;
  logic [1:0] n_exceptionGen_io_state_bits_vsew;
  logic [63:0] n_exceptionGen_io_state_bits_vstart;
  logic n_exceptionGen_io_state_bits_vstartEn;
  logic n_exceptionGen_io_state_valid;
  logic n_hasBlockBackwardOut;   // golden: hasBlockBackward
  logic n_hasCommittedOut_0;   // golden: hasCommitted_0
  logic n_hasCommittedOut_1;   // golden: hasCommitted_1
  logic n_hasCommittedOut_2;   // golden: hasCommitted_2
  logic n_hasCommittedOut_3;   // golden: hasCommitted_3
  logic n_hasCommittedOut_4;   // golden: hasCommitted_4
  logic n_hasCommittedOut_5;   // golden: hasCommitted_5
  logic n_hasCommittedOut_6;   // golden: hasCommitted_6
  logic n_hasCommittedOut_7;   // golden: hasCommitted_7
  logic n_hasWaitForwardOut;   // golden: hasWaitForward
  logic n_intrBitSetRegOut;   // golden: intrBitSetReg
  logic n_io_flushOut_valid_0;
  logic n_rab_io_canEnq;
  logic n_rab_io_canEnqForDispatch;
  logic n_rab_io_commits_commitValid_0;
  logic n_rab_io_commits_commitValid_1;
  logic n_rab_io_commits_commitValid_2;
  logic n_rab_io_commits_commitValid_3;
  logic n_rab_io_commits_commitValid_4;
  logic n_rab_io_commits_commitValid_5;
  logic n_rab_io_commits_info_0_fpWen;
  logic n_rab_io_commits_info_0_isMove;
  logic [5:0] n_rab_io_commits_info_0_ldest;
  logic [7:0] n_rab_io_commits_info_0_pdest;
  logic n_rab_io_commits_info_0_rfWen;
  logic n_rab_io_commits_info_0_v0Wen;
  logic n_rab_io_commits_info_0_vecWen;
  logic n_rab_io_commits_info_0_vlWen;
  logic n_rab_io_commits_info_1_fpWen;
  logic n_rab_io_commits_info_1_isMove;
  logic [5:0] n_rab_io_commits_info_1_ldest;
  logic [7:0] n_rab_io_commits_info_1_pdest;
  logic n_rab_io_commits_info_1_rfWen;
  logic n_rab_io_commits_info_1_v0Wen;
  logic n_rab_io_commits_info_1_vecWen;
  logic n_rab_io_commits_info_1_vlWen;
  logic n_rab_io_commits_info_2_fpWen;
  logic n_rab_io_commits_info_2_isMove;
  logic [5:0] n_rab_io_commits_info_2_ldest;
  logic [7:0] n_rab_io_commits_info_2_pdest;
  logic n_rab_io_commits_info_2_rfWen;
  logic n_rab_io_commits_info_2_v0Wen;
  logic n_rab_io_commits_info_2_vecWen;
  logic n_rab_io_commits_info_2_vlWen;
  logic n_rab_io_commits_info_3_fpWen;
  logic n_rab_io_commits_info_3_isMove;
  logic [5:0] n_rab_io_commits_info_3_ldest;
  logic [7:0] n_rab_io_commits_info_3_pdest;
  logic n_rab_io_commits_info_3_rfWen;
  logic n_rab_io_commits_info_3_v0Wen;
  logic n_rab_io_commits_info_3_vecWen;
  logic n_rab_io_commits_info_3_vlWen;
  logic n_rab_io_commits_info_4_fpWen;
  logic n_rab_io_commits_info_4_isMove;
  logic [5:0] n_rab_io_commits_info_4_ldest;
  logic [7:0] n_rab_io_commits_info_4_pdest;
  logic n_rab_io_commits_info_4_rfWen;
  logic n_rab_io_commits_info_4_v0Wen;
  logic n_rab_io_commits_info_4_vecWen;
  logic n_rab_io_commits_info_4_vlWen;
  logic n_rab_io_commits_info_5_fpWen;
  logic n_rab_io_commits_info_5_isMove;
  logic [5:0] n_rab_io_commits_info_5_ldest;
  logic [7:0] n_rab_io_commits_info_5_pdest;
  logic n_rab_io_commits_info_5_rfWen;
  logic n_rab_io_commits_info_5_v0Wen;
  logic n_rab_io_commits_info_5_vecWen;
  logic n_rab_io_commits_info_5_vlWen;
  logic n_rab_io_commits_isCommit;
  logic n_rab_io_commits_isWalk;
  logic n_rab_io_commits_walkValid_0;
  logic n_rab_io_commits_walkValid_1;
  logic n_rab_io_commits_walkValid_2;
  logic n_rab_io_commits_walkValid_3;
  logic n_rab_io_commits_walkValid_4;
  logic n_rab_io_commits_walkValid_5;
  logic n_rab_io_fromRob_vecLoadExcp_valid_REGOut;   // golden: rab_io_fromRob_vecLoadExcp_valid_REG
  logic n_rab_io_status_commitEnd;
  logic n_rab_io_status_walkEnd;
  logic n_rawInfo_0_interrupt_safe;
  logic n_snapshots_snapshotGen_io_snapshots_0_0_flag;
  logic [7:0] n_snapshots_snapshotGen_io_snapshots_0_0_value;
  logic n_snapshots_snapshotGen_io_snapshots_1_0_flag;
  logic [7:0] n_snapshots_snapshotGen_io_snapshots_1_0_value;
  logic n_snapshots_snapshotGen_io_snapshots_2_0_flag;
  logic [7:0] n_snapshots_snapshotGen_io_snapshots_2_0_value;
  logic n_snapshots_snapshotGen_io_snapshots_3_0_flag;
  logic [7:0] n_snapshots_snapshotGen_io_snapshots_3_0_value;
  logic n_snptEnq;
  logic n_vtypeBuffer_io_canEnq;
  logic n_vtypeBuffer_io_canEnqForDispatch;
  logic n_vtypeBuffer_io_status_walkEnd;
  logic n_vtypeBuffer_io_toDecode_isResumeVType;
  logic n_commitStuckCounter_io_stuck;   // golden: commitStuckCounter.io_stuck ((~(io_commits_commitValid_0_0 | io_commits_commitValid_1_0 | io_commits_commitValid_2_0 | io_commits_commitValid_3_0 | io_commits_commitValid_4_0 | io_commits_commitValid_5_0 | io_commits_commitValid_6_0 | io_commits_commitValid_7_0) | ~io_commits_isCommit_0) & ~(_GEN_2631[deqPtrVec_0_value] & _GEN_2641[deqPtrVec_0_value]))
  logic [1:0] n_deqPtrGenModule_io_state;   // golden: deqPtrGenModule.io_state ({1'h0, state})
  logic n_enqPtrGenModule_io_allowEnqueue;   // golden: enqPtrGenModule.io_allowEnqueue (allowEnqueue & _rab_io_canEnq & ~io_fromVecExcpMod_busy)
  logic n_exceptionGen_io_wb_0_bits_hasException;   // golden: exceptionGen.io_wb_0_bits_hasException (|{io_writeback_7_bits_exceptionVec_22, io_writeback_7_bits_exceptionVec_11, io_writeback_7_bits_exceptionVec_10, io_writeback_7_bits_exceptionVec_9, io_writeback_7_bits_exceptionVec_8, io_writeback_7_bits_exceptionVec_3, io_writeback_7_bits_exceptionVec_2})
  logic n_exceptionGen_io_wb_10_bits_hasException;   // golden: exceptionGen.io_wb_10_bits_hasException (|{io_writeback_22_bits_exceptionVec_23, io_writeback_22_bits_exceptionVec_22, io_writeback_22_bits_exceptionVec_21, io_writeback_22_bits_exceptionVec_20, io_writeback_22_bits_exceptionVec_19, io_writeback_22_bits_exceptionVec_18, io_writeback_22_bits_exceptionVec_17, io_writeback_22_bits_exceptionVec_16, io_writeback_22_bits_exceptionVec_15, io_writeback_22_bits_exceptionVec_14, io_writeback_22_bits_exceptionVec_13, io_writeback_22_bits_exceptionVec_12, io_writeback_22_bits_exceptionVec_11, io_writeback_22_bits_exceptionVec_10, io_writeback_22_bits_exceptionVec_9, io_writeback_22_bits_exceptionVec_8, io_writeback_22_bits_exceptionVec_7, io_writeback_22_bits_exceptionVec_6, io_writeback_22_bits_exceptionVec_5, io_writeback_22_bits_exceptionVec_4, io_writeback_22_bits_exceptionVec_3, io_writeback_22_bits_exceptionVec_2, io_writeback_22_bits_exceptionVec_1, io_writeback_22_bits_exceptionVec_0})
  logic n_exceptionGen_io_wb_11_bits_hasException;   // golden: exceptionGen.io_wb_11_bits_hasException (|{io_writeback_23_bits_exceptionVec_23, io_writeback_23_bits_exceptionVec_22, io_writeback_23_bits_exceptionVec_21, io_writeback_23_bits_exceptionVec_20, io_writeback_23_bits_exceptionVec_19, io_writeback_23_bits_exceptionVec_18, io_writeback_23_bits_exceptionVec_17, io_writeback_23_bits_exceptionVec_16, io_writeback_23_bits_exceptionVec_15, io_writeback_23_bits_exceptionVec_14, io_writeback_23_bits_exceptionVec_13, io_writeback_23_bits_exceptionVec_12, io_writeback_23_bits_exceptionVec_11, io_writeback_23_bits_exceptionVec_10, io_writeback_23_bits_exceptionVec_9, io_writeback_23_bits_exceptionVec_8, io_writeback_23_bits_exceptionVec_7, io_writeback_23_bits_exceptionVec_6, io_writeback_23_bits_exceptionVec_5, io_writeback_23_bits_exceptionVec_4, io_writeback_23_bits_exceptionVec_3, io_writeback_23_bits_exceptionVec_2, io_writeback_23_bits_exceptionVec_1, io_writeback_23_bits_exceptionVec_0})
  logic [63:0] n_exceptionGen_io_wb_11_bits_vstart;   // golden: exceptionGen.io_wb_11_bits_vstart ({56'h0, io_writeback_23_bits_vls_vpu_vstart})
  logic n_exceptionGen_io_wb_11_bits_vstartEn;   // golden: exceptionGen.io_wb_11_bits_vstartEn ((|{io_writeback_23_bits_exceptionVec_23, io_writeback_23_bits_exceptionVec_22, io_writeback_23_bits_exceptionVec_21, io_writeback_23_bits_exceptionVec_20, io_writeback_23_bits_exceptionVec_19, io_writeback_23_bits_exceptionVec_18, io_writeback_23_bits_exceptionVec_17, io_writeback_23_bits_exceptionVec_16, io_writeback_23_bits_exceptionVec_15, io_writeback_23_bits_exceptionVec_14, io_writeback_23_bits_exceptionVec_13, io_writeback_23_bits_exceptionVec_12, io_writeback_23_bits_exceptionVec_11, io_writeback_23_bits_exceptionVec_10, io_writeback_23_bits_exceptionVec_9, io_writeback_23_bits_exceptionVec_8, io_writeback_23_bits_exceptionVec_7, io_writeback_23_bits_exceptionVec_6, io_writeback_23_bits_exceptionVec_5, io_writeback_23_bits_exceptionVec_4, io_writeback_23_bits_exceptionVec_3, io_writeback_23_bits_exceptionVec_2, io_writeback_23_bits_exceptionVec_1, io_writeback_23_bits_exceptionVec_0}) | io_writeback_23_bits_trigger == 4'h1)
  logic n_exceptionGen_io_wb_12_bits_hasException;   // golden: exceptionGen.io_wb_12_bits_hasException (|{io_writeback_24_bits_exceptionVec_23, io_writeback_24_bits_exceptionVec_22, io_writeback_24_bits_exceptionVec_21, io_writeback_24_bits_exceptionVec_20, io_writeback_24_bits_exceptionVec_19, io_writeback_24_bits_exceptionVec_18, io_writeback_24_bits_exceptionVec_17, io_writeback_24_bits_exceptionVec_16, io_writeback_24_bits_exceptionVec_15, io_writeback_24_bits_exceptionVec_14, io_writeback_24_bits_exceptionVec_13, io_writeback_24_bits_exceptionVec_12, io_writeback_24_bits_exceptionVec_11, io_writeback_24_bits_exceptionVec_10, io_writeback_24_bits_exceptionVec_9, io_writeback_24_bits_exceptionVec_8, io_writeback_24_bits_exceptionVec_7, io_writeback_24_bits_exceptionVec_6, io_writeback_24_bits_exceptionVec_5, io_writeback_24_bits_exceptionVec_4, io_writeback_24_bits_exceptionVec_3, io_writeback_24_bits_exceptionVec_2, io_writeback_24_bits_exceptionVec_1, io_writeback_24_bits_exceptionVec_0})
  logic [63:0] n_exceptionGen_io_wb_12_bits_vstart;   // golden: exceptionGen.io_wb_12_bits_vstart ({56'h0, io_writeback_24_bits_vls_vpu_vstart})
  logic n_exceptionGen_io_wb_12_bits_vstartEn;   // golden: exceptionGen.io_wb_12_bits_vstartEn ((|{io_writeback_24_bits_exceptionVec_23, io_writeback_24_bits_exceptionVec_22, io_writeback_24_bits_exceptionVec_21, io_writeback_24_bits_exceptionVec_20, io_writeback_24_bits_exceptionVec_19, io_writeback_24_bits_exceptionVec_18, io_writeback_24_bits_exceptionVec_17, io_writeback_24_bits_exceptionVec_16, io_writeback_24_bits_exceptionVec_15, io_writeback_24_bits_exceptionVec_14, io_writeback_24_bits_exceptionVec_13, io_writeback_24_bits_exceptionVec_12, io_writeback_24_bits_exceptionVec_11, io_writeback_24_bits_exceptionVec_10, io_writeback_24_bits_exceptionVec_9, io_writeback_24_bits_exceptionVec_8, io_writeback_24_bits_exceptionVec_7, io_writeback_24_bits_exceptionVec_6, io_writeback_24_bits_exceptionVec_5, io_writeback_24_bits_exceptionVec_4, io_writeback_24_bits_exceptionVec_3, io_writeback_24_bits_exceptionVec_2, io_writeback_24_bits_exceptionVec_1, io_writeback_24_bits_exceptionVec_0}) | io_writeback_24_bits_trigger == 4'h1)
  logic n_exceptionGen_io_wb_6_bits_hasException;   // golden: exceptionGen.io_wb_6_bits_hasException (|{io_writeback_18_bits_exceptionVec_23, io_writeback_18_bits_exceptionVec_22, io_writeback_18_bits_exceptionVec_21, io_writeback_18_bits_exceptionVec_20, io_writeback_18_bits_exceptionVec_19, io_writeback_18_bits_exceptionVec_18, io_writeback_18_bits_exceptionVec_17, io_writeback_18_bits_exceptionVec_16, io_writeback_18_bits_exceptionVec_15, io_writeback_18_bits_exceptionVec_14, io_writeback_18_bits_exceptionVec_13, io_writeback_18_bits_exceptionVec_12, io_writeback_18_bits_exceptionVec_11, io_writeback_18_bits_exceptionVec_10, io_writeback_18_bits_exceptionVec_9, io_writeback_18_bits_exceptionVec_8, io_writeback_18_bits_exceptionVec_7, io_writeback_18_bits_exceptionVec_6, io_writeback_18_bits_exceptionVec_5, io_writeback_18_bits_exceptionVec_4, io_writeback_18_bits_exceptionVec_3, io_writeback_18_bits_exceptionVec_2, io_writeback_18_bits_exceptionVec_1, io_writeback_18_bits_exceptionVec_0})
  logic n_exceptionGen_io_wb_7_bits_hasException;   // golden: exceptionGen.io_wb_7_bits_hasException (|{io_writeback_19_bits_exceptionVec_23, io_writeback_19_bits_exceptionVec_22, io_writeback_19_bits_exceptionVec_21, io_writeback_19_bits_exceptionVec_20, io_writeback_19_bits_exceptionVec_19, io_writeback_19_bits_exceptionVec_18, io_writeback_19_bits_exceptionVec_17, io_writeback_19_bits_exceptionVec_16, io_writeback_19_bits_exceptionVec_15, io_writeback_19_bits_exceptionVec_14, io_writeback_19_bits_exceptionVec_13, io_writeback_19_bits_exceptionVec_12, io_writeback_19_bits_exceptionVec_11, io_writeback_19_bits_exceptionVec_10, io_writeback_19_bits_exceptionVec_9, io_writeback_19_bits_exceptionVec_8, io_writeback_19_bits_exceptionVec_7, io_writeback_19_bits_exceptionVec_6, io_writeback_19_bits_exceptionVec_5, io_writeback_19_bits_exceptionVec_4, io_writeback_19_bits_exceptionVec_3, io_writeback_19_bits_exceptionVec_2, io_writeback_19_bits_exceptionVec_1, io_writeback_19_bits_exceptionVec_0})
  logic n_exceptionGen_io_wb_8_bits_hasException;   // golden: exceptionGen.io_wb_8_bits_hasException (|{io_writeback_20_bits_exceptionVec_23, io_writeback_20_bits_exceptionVec_22, io_writeback_20_bits_exceptionVec_21, io_writeback_20_bits_exceptionVec_20, io_writeback_20_bits_exceptionVec_19, io_writeback_20_bits_exceptionVec_18, io_writeback_20_bits_exceptionVec_17, io_writeback_20_bits_exceptionVec_16, io_writeback_20_bits_exceptionVec_15, io_writeback_20_bits_exceptionVec_14, io_writeback_20_bits_exceptionVec_13, io_writeback_20_bits_exceptionVec_12, io_writeback_20_bits_exceptionVec_11, io_writeback_20_bits_exceptionVec_10, io_writeback_20_bits_exceptionVec_9, io_writeback_20_bits_exceptionVec_8, io_writeback_20_bits_exceptionVec_7, io_writeback_20_bits_exceptionVec_6, io_writeback_20_bits_exceptionVec_5, io_writeback_20_bits_exceptionVec_4, io_writeback_20_bits_exceptionVec_3, io_writeback_20_bits_exceptionVec_2, io_writeback_20_bits_exceptionVec_1, io_writeback_20_bits_exceptionVec_0})
  logic n_exceptionGen_io_wb_9_bits_hasException;   // golden: exceptionGen.io_wb_9_bits_hasException (|{io_writeback_21_bits_exceptionVec_23, io_writeback_21_bits_exceptionVec_22, io_writeback_21_bits_exceptionVec_21, io_writeback_21_bits_exceptionVec_20, io_writeback_21_bits_exceptionVec_19, io_writeback_21_bits_exceptionVec_18, io_writeback_21_bits_exceptionVec_17, io_writeback_21_bits_exceptionVec_16, io_writeback_21_bits_exceptionVec_15, io_writeback_21_bits_exceptionVec_14, io_writeback_21_bits_exceptionVec_13, io_writeback_21_bits_exceptionVec_12, io_writeback_21_bits_exceptionVec_11, io_writeback_21_bits_exceptionVec_10, io_writeback_21_bits_exceptionVec_9, io_writeback_21_bits_exceptionVec_8, io_writeback_21_bits_exceptionVec_7, io_writeback_21_bits_exceptionVec_6, io_writeback_21_bits_exceptionVec_5, io_writeback_21_bits_exceptionVec_4, io_writeback_21_bits_exceptionVec_3, io_writeback_21_bits_exceptionVec_2, io_writeback_21_bits_exceptionVec_1, io_writeback_21_bits_exceptionVec_0})
  logic [7:0] n_rab_io_fromRob_commitSize;   // golden: rab.io_fromRob_commitSize (deqVlsExceptionNeedCommit ? {1'h0, deqVlsExceptionCommitSize} : commitSizeSum[7:0])
  logic n_rab_io_fromRob_walkEnd;   // golden: rab.io_fromRob_walkEnd (state & walkFinished)
  logic [7:0] n_rab_io_fromRob_walkSize;   // golden: rab.io_fromRob_walkSize (walkSizeSum[7:0])
  logic [5:0] n_vtypeBuffer_io_fromRob_commitSize;   // golden: vtypeBuffer.io_fromRob_commitSize ({2'h0, 4'({1'h0, 3'({1'h0, 2'({1'h0, commitIsVTypeVec_0} + {1'h0, commitIsVTypeVec_1})} + {1'h0, 2'({1'h0, commitIsVTypeVec_2} + {1'h0, commitIsVTypeVec_3})})} + {1'h0, 3'({1'h0, 2'({1'h0, commitIsVTypeVec_4} + {1'h0, commitIsVTypeVec_5})} + {1'h0, 2'({1'h0, commitIsVTypeVec_6} + {1'h0, commitIsVTypeVec_7})})})})
  logic n_vtypeBuffer_io_fromRob_walkEnd;   // golden: vtypeBuffer.io_fromRob_walkEnd (state & walkFinished)
  logic [5:0] n_vtypeBuffer_io_fromRob_walkSize;   // golden: vtypeBuffer.io_fromRob_walkSize ({2'h0, 4'({1'h0, 3'({1'h0, 2'({1'h0, walkIsVTypeVec_0} + {1'h0, walkIsVTypeVec_1})} + {1'h0, 2'({1'h0, walkIsVTypeVec_2} + {1'h0, walkIsVTypeVec_3})})} + {1'h0, 3'({1'h0, 2'({1'h0, walkIsVTypeVec_4} + {1'h0, walkIsVTypeVec_5})} + {1'h0, 2'({1'h0, walkIsVTypeVec_6} + {1'h0, walkIsVTypeVec_7})})})})
  // END GENERATED

  // BEGIN GENERATED(core_inst)
  xs_Rob_core u_core (
    .clock                                                      (clock),
    .reset                                                      (reset),
    .io_hartId                                                  (io_hartId),
    .io_redirect_valid                                          (io_redirect_valid),
    .io_redirect_bits_robIdx_flag                               (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value                              (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level                                     (io_redirect_bits_level),
    .io_redirect_bits_cfiUpdate_isMisPred                       (io_redirect_bits_cfiUpdate_isMisPred),
    .io_enq_canAccept                                           (io_enq_canAccept),
    .io_enq_canAcceptForDispatch                                (io_enq_canAcceptForDispatch),
    .io_enq_isEmpty                                             (io_enq_isEmpty),
    .io_enq_req_0_valid                                         (io_enq_req_0_valid),
    .io_enq_req_0_bits_instr                                    (io_enq_req_0_bits_instr),
    .io_enq_req_0_bits_pc                                       (io_enq_req_0_bits_pc),
    .io_enq_req_0_bits_exceptionVec_0                           (io_enq_req_0_bits_exceptionVec_0),
    .io_enq_req_0_bits_exceptionVec_1                           (io_enq_req_0_bits_exceptionVec_1),
    .io_enq_req_0_bits_exceptionVec_2                           (io_enq_req_0_bits_exceptionVec_2),
    .io_enq_req_0_bits_exceptionVec_3                           (io_enq_req_0_bits_exceptionVec_3),
    .io_enq_req_0_bits_exceptionVec_12                          (io_enq_req_0_bits_exceptionVec_12),
    .io_enq_req_0_bits_exceptionVec_20                          (io_enq_req_0_bits_exceptionVec_20),
    .io_enq_req_0_bits_exceptionVec_22                          (io_enq_req_0_bits_exceptionVec_22),
    .io_enq_req_0_bits_hasException                             (io_enq_req_0_bits_hasException),
    .io_enq_req_0_bits_trigger                                  (io_enq_req_0_bits_trigger),
    .io_enq_req_0_bits_preDecodeInfo_isRVC                      (io_enq_req_0_bits_preDecodeInfo_isRVC),
    .io_enq_req_0_bits_ftqPtr_flag                              (io_enq_req_0_bits_ftqPtr_flag),
    .io_enq_req_0_bits_ftqPtr_value                             (io_enq_req_0_bits_ftqPtr_value),
    .io_enq_req_0_bits_ftqOffset                                (io_enq_req_0_bits_ftqOffset),
    .io_enq_req_0_bits_ldest                                    (io_enq_req_0_bits_ldest),
    .io_enq_req_0_bits_fuType                                   (io_enq_req_0_bits_fuType),
    .io_enq_req_0_bits_fuOpType                                 (io_enq_req_0_bits_fuOpType),
    .io_enq_req_0_bits_rfWen                                    (io_enq_req_0_bits_rfWen),
    .io_enq_req_0_bits_fpWen                                    (io_enq_req_0_bits_fpWen),
    .io_enq_req_0_bits_vecWen                                   (io_enq_req_0_bits_vecWen),
    .io_enq_req_0_bits_v0Wen                                    (io_enq_req_0_bits_v0Wen),
    .io_enq_req_0_bits_vlWen                                    (io_enq_req_0_bits_vlWen),
    .io_enq_req_0_bits_isXSTrap                                 (io_enq_req_0_bits_isXSTrap),
    .io_enq_req_0_bits_waitForward                              (io_enq_req_0_bits_waitForward),
    .io_enq_req_0_bits_blockBackward                            (io_enq_req_0_bits_blockBackward),
    .io_enq_req_0_bits_flushPipe                                (io_enq_req_0_bits_flushPipe),
    .io_enq_req_0_bits_vlsInstr                                 (io_enq_req_0_bits_vlsInstr),
    .io_enq_req_0_bits_wfflags                                  (io_enq_req_0_bits_wfflags),
    .io_enq_req_0_bits_isVset                                   (io_enq_req_0_bits_isVset),
    .io_enq_req_0_bits_firstUop                                 (io_enq_req_0_bits_firstUop),
    .io_enq_req_0_bits_numWB                                    (io_enq_req_0_bits_numWB),
    .io_enq_req_0_bits_commitType                               (io_enq_req_0_bits_commitType),
    .io_enq_req_0_bits_pdest                                    (io_enq_req_0_bits_pdest),
    .io_enq_req_0_bits_robIdx_flag                              (io_enq_req_0_bits_robIdx_flag),
    .io_enq_req_0_bits_robIdx_value                             (io_enq_req_0_bits_robIdx_value),
    .io_enq_req_0_bits_instrSize                                (io_enq_req_0_bits_instrSize),
    .io_enq_req_0_bits_dirtyFs                                  (io_enq_req_0_bits_dirtyFs),
    .io_enq_req_0_bits_dirtyVs                                  (io_enq_req_0_bits_dirtyVs),
    .io_enq_req_0_bits_traceBlockInPipe_itype                   (io_enq_req_0_bits_traceBlockInPipe_itype),
    .io_enq_req_0_bits_traceBlockInPipe_iretire                 (io_enq_req_0_bits_traceBlockInPipe_iretire),
    .io_enq_req_0_bits_traceBlockInPipe_ilastsize               (io_enq_req_0_bits_traceBlockInPipe_ilastsize),
    .io_enq_req_0_bits_eliminatedMove                           (io_enq_req_0_bits_eliminatedMove),
    .io_enq_req_0_bits_snapshot                                 (io_enq_req_0_bits_snapshot),
    .io_enq_req_0_bits_debugInfo_renameTime                     (io_enq_req_0_bits_debugInfo_renameTime),
    .io_enq_req_0_bits_lqIdx_value                              (io_enq_req_0_bits_lqIdx_value),
    .io_enq_req_0_bits_sqIdx_value                              (io_enq_req_0_bits_sqIdx_value),
    .io_enq_req_0_bits_debug_fuType                             (io_enq_req_0_bits_debug_fuType),
    .io_enq_req_0_bits_debug_sim_trig                           (io_enq_req_0_bits_debug_sim_trig),
    .io_enq_req_1_valid                                         (io_enq_req_1_valid),
    .io_enq_req_1_bits_instr                                    (io_enq_req_1_bits_instr),
    .io_enq_req_1_bits_pc                                       (io_enq_req_1_bits_pc),
    .io_enq_req_1_bits_exceptionVec_0                           (io_enq_req_1_bits_exceptionVec_0),
    .io_enq_req_1_bits_exceptionVec_1                           (io_enq_req_1_bits_exceptionVec_1),
    .io_enq_req_1_bits_exceptionVec_2                           (io_enq_req_1_bits_exceptionVec_2),
    .io_enq_req_1_bits_exceptionVec_3                           (io_enq_req_1_bits_exceptionVec_3),
    .io_enq_req_1_bits_exceptionVec_12                          (io_enq_req_1_bits_exceptionVec_12),
    .io_enq_req_1_bits_exceptionVec_20                          (io_enq_req_1_bits_exceptionVec_20),
    .io_enq_req_1_bits_exceptionVec_22                          (io_enq_req_1_bits_exceptionVec_22),
    .io_enq_req_1_bits_hasException                             (io_enq_req_1_bits_hasException),
    .io_enq_req_1_bits_trigger                                  (io_enq_req_1_bits_trigger),
    .io_enq_req_1_bits_preDecodeInfo_isRVC                      (io_enq_req_1_bits_preDecodeInfo_isRVC),
    .io_enq_req_1_bits_ftqPtr_flag                              (io_enq_req_1_bits_ftqPtr_flag),
    .io_enq_req_1_bits_ftqPtr_value                             (io_enq_req_1_bits_ftqPtr_value),
    .io_enq_req_1_bits_ftqOffset                                (io_enq_req_1_bits_ftqOffset),
    .io_enq_req_1_bits_ldest                                    (io_enq_req_1_bits_ldest),
    .io_enq_req_1_bits_fuType                                   (io_enq_req_1_bits_fuType),
    .io_enq_req_1_bits_fuOpType                                 (io_enq_req_1_bits_fuOpType),
    .io_enq_req_1_bits_rfWen                                    (io_enq_req_1_bits_rfWen),
    .io_enq_req_1_bits_fpWen                                    (io_enq_req_1_bits_fpWen),
    .io_enq_req_1_bits_vecWen                                   (io_enq_req_1_bits_vecWen),
    .io_enq_req_1_bits_v0Wen                                    (io_enq_req_1_bits_v0Wen),
    .io_enq_req_1_bits_vlWen                                    (io_enq_req_1_bits_vlWen),
    .io_enq_req_1_bits_isXSTrap                                 (io_enq_req_1_bits_isXSTrap),
    .io_enq_req_1_bits_waitForward                              (io_enq_req_1_bits_waitForward),
    .io_enq_req_1_bits_blockBackward                            (io_enq_req_1_bits_blockBackward),
    .io_enq_req_1_bits_flushPipe                                (io_enq_req_1_bits_flushPipe),
    .io_enq_req_1_bits_vlsInstr                                 (io_enq_req_1_bits_vlsInstr),
    .io_enq_req_1_bits_wfflags                                  (io_enq_req_1_bits_wfflags),
    .io_enq_req_1_bits_isVset                                   (io_enq_req_1_bits_isVset),
    .io_enq_req_1_bits_firstUop                                 (io_enq_req_1_bits_firstUop),
    .io_enq_req_1_bits_numWB                                    (io_enq_req_1_bits_numWB),
    .io_enq_req_1_bits_commitType                               (io_enq_req_1_bits_commitType),
    .io_enq_req_1_bits_pdest                                    (io_enq_req_1_bits_pdest),
    .io_enq_req_1_bits_robIdx_flag                              (io_enq_req_1_bits_robIdx_flag),
    .io_enq_req_1_bits_robIdx_value                             (io_enq_req_1_bits_robIdx_value),
    .io_enq_req_1_bits_instrSize                                (io_enq_req_1_bits_instrSize),
    .io_enq_req_1_bits_dirtyFs                                  (io_enq_req_1_bits_dirtyFs),
    .io_enq_req_1_bits_dirtyVs                                  (io_enq_req_1_bits_dirtyVs),
    .io_enq_req_1_bits_traceBlockInPipe_itype                   (io_enq_req_1_bits_traceBlockInPipe_itype),
    .io_enq_req_1_bits_traceBlockInPipe_iretire                 (io_enq_req_1_bits_traceBlockInPipe_iretire),
    .io_enq_req_1_bits_traceBlockInPipe_ilastsize               (io_enq_req_1_bits_traceBlockInPipe_ilastsize),
    .io_enq_req_1_bits_eliminatedMove                           (io_enq_req_1_bits_eliminatedMove),
    .io_enq_req_1_bits_snapshot                                 (io_enq_req_1_bits_snapshot),
    .io_enq_req_1_bits_debugInfo_renameTime                     (io_enq_req_1_bits_debugInfo_renameTime),
    .io_enq_req_1_bits_lqIdx_value                              (io_enq_req_1_bits_lqIdx_value),
    .io_enq_req_1_bits_sqIdx_value                              (io_enq_req_1_bits_sqIdx_value),
    .io_enq_req_1_bits_debug_fuType                             (io_enq_req_1_bits_debug_fuType),
    .io_enq_req_1_bits_debug_sim_trig                           (io_enq_req_1_bits_debug_sim_trig),
    .io_enq_req_2_valid                                         (io_enq_req_2_valid),
    .io_enq_req_2_bits_instr                                    (io_enq_req_2_bits_instr),
    .io_enq_req_2_bits_pc                                       (io_enq_req_2_bits_pc),
    .io_enq_req_2_bits_exceptionVec_0                           (io_enq_req_2_bits_exceptionVec_0),
    .io_enq_req_2_bits_exceptionVec_1                           (io_enq_req_2_bits_exceptionVec_1),
    .io_enq_req_2_bits_exceptionVec_2                           (io_enq_req_2_bits_exceptionVec_2),
    .io_enq_req_2_bits_exceptionVec_3                           (io_enq_req_2_bits_exceptionVec_3),
    .io_enq_req_2_bits_exceptionVec_12                          (io_enq_req_2_bits_exceptionVec_12),
    .io_enq_req_2_bits_exceptionVec_20                          (io_enq_req_2_bits_exceptionVec_20),
    .io_enq_req_2_bits_exceptionVec_22                          (io_enq_req_2_bits_exceptionVec_22),
    .io_enq_req_2_bits_hasException                             (io_enq_req_2_bits_hasException),
    .io_enq_req_2_bits_trigger                                  (io_enq_req_2_bits_trigger),
    .io_enq_req_2_bits_preDecodeInfo_isRVC                      (io_enq_req_2_bits_preDecodeInfo_isRVC),
    .io_enq_req_2_bits_ftqPtr_flag                              (io_enq_req_2_bits_ftqPtr_flag),
    .io_enq_req_2_bits_ftqPtr_value                             (io_enq_req_2_bits_ftqPtr_value),
    .io_enq_req_2_bits_ftqOffset                                (io_enq_req_2_bits_ftqOffset),
    .io_enq_req_2_bits_ldest                                    (io_enq_req_2_bits_ldest),
    .io_enq_req_2_bits_fuType                                   (io_enq_req_2_bits_fuType),
    .io_enq_req_2_bits_fuOpType                                 (io_enq_req_2_bits_fuOpType),
    .io_enq_req_2_bits_rfWen                                    (io_enq_req_2_bits_rfWen),
    .io_enq_req_2_bits_fpWen                                    (io_enq_req_2_bits_fpWen),
    .io_enq_req_2_bits_vecWen                                   (io_enq_req_2_bits_vecWen),
    .io_enq_req_2_bits_v0Wen                                    (io_enq_req_2_bits_v0Wen),
    .io_enq_req_2_bits_vlWen                                    (io_enq_req_2_bits_vlWen),
    .io_enq_req_2_bits_isXSTrap                                 (io_enq_req_2_bits_isXSTrap),
    .io_enq_req_2_bits_waitForward                              (io_enq_req_2_bits_waitForward),
    .io_enq_req_2_bits_blockBackward                            (io_enq_req_2_bits_blockBackward),
    .io_enq_req_2_bits_flushPipe                                (io_enq_req_2_bits_flushPipe),
    .io_enq_req_2_bits_vlsInstr                                 (io_enq_req_2_bits_vlsInstr),
    .io_enq_req_2_bits_wfflags                                  (io_enq_req_2_bits_wfflags),
    .io_enq_req_2_bits_isVset                                   (io_enq_req_2_bits_isVset),
    .io_enq_req_2_bits_firstUop                                 (io_enq_req_2_bits_firstUop),
    .io_enq_req_2_bits_numWB                                    (io_enq_req_2_bits_numWB),
    .io_enq_req_2_bits_commitType                               (io_enq_req_2_bits_commitType),
    .io_enq_req_2_bits_pdest                                    (io_enq_req_2_bits_pdest),
    .io_enq_req_2_bits_robIdx_flag                              (io_enq_req_2_bits_robIdx_flag),
    .io_enq_req_2_bits_robIdx_value                             (io_enq_req_2_bits_robIdx_value),
    .io_enq_req_2_bits_instrSize                                (io_enq_req_2_bits_instrSize),
    .io_enq_req_2_bits_dirtyFs                                  (io_enq_req_2_bits_dirtyFs),
    .io_enq_req_2_bits_dirtyVs                                  (io_enq_req_2_bits_dirtyVs),
    .io_enq_req_2_bits_traceBlockInPipe_itype                   (io_enq_req_2_bits_traceBlockInPipe_itype),
    .io_enq_req_2_bits_traceBlockInPipe_iretire                 (io_enq_req_2_bits_traceBlockInPipe_iretire),
    .io_enq_req_2_bits_traceBlockInPipe_ilastsize               (io_enq_req_2_bits_traceBlockInPipe_ilastsize),
    .io_enq_req_2_bits_eliminatedMove                           (io_enq_req_2_bits_eliminatedMove),
    .io_enq_req_2_bits_snapshot                                 (io_enq_req_2_bits_snapshot),
    .io_enq_req_2_bits_debugInfo_renameTime                     (io_enq_req_2_bits_debugInfo_renameTime),
    .io_enq_req_2_bits_lqIdx_value                              (io_enq_req_2_bits_lqIdx_value),
    .io_enq_req_2_bits_sqIdx_value                              (io_enq_req_2_bits_sqIdx_value),
    .io_enq_req_2_bits_debug_fuType                             (io_enq_req_2_bits_debug_fuType),
    .io_enq_req_2_bits_debug_sim_trig                           (io_enq_req_2_bits_debug_sim_trig),
    .io_enq_req_3_valid                                         (io_enq_req_3_valid),
    .io_enq_req_3_bits_instr                                    (io_enq_req_3_bits_instr),
    .io_enq_req_3_bits_pc                                       (io_enq_req_3_bits_pc),
    .io_enq_req_3_bits_exceptionVec_0                           (io_enq_req_3_bits_exceptionVec_0),
    .io_enq_req_3_bits_exceptionVec_1                           (io_enq_req_3_bits_exceptionVec_1),
    .io_enq_req_3_bits_exceptionVec_2                           (io_enq_req_3_bits_exceptionVec_2),
    .io_enq_req_3_bits_exceptionVec_3                           (io_enq_req_3_bits_exceptionVec_3),
    .io_enq_req_3_bits_exceptionVec_12                          (io_enq_req_3_bits_exceptionVec_12),
    .io_enq_req_3_bits_exceptionVec_20                          (io_enq_req_3_bits_exceptionVec_20),
    .io_enq_req_3_bits_exceptionVec_22                          (io_enq_req_3_bits_exceptionVec_22),
    .io_enq_req_3_bits_hasException                             (io_enq_req_3_bits_hasException),
    .io_enq_req_3_bits_trigger                                  (io_enq_req_3_bits_trigger),
    .io_enq_req_3_bits_preDecodeInfo_isRVC                      (io_enq_req_3_bits_preDecodeInfo_isRVC),
    .io_enq_req_3_bits_ftqPtr_flag                              (io_enq_req_3_bits_ftqPtr_flag),
    .io_enq_req_3_bits_ftqPtr_value                             (io_enq_req_3_bits_ftqPtr_value),
    .io_enq_req_3_bits_ftqOffset                                (io_enq_req_3_bits_ftqOffset),
    .io_enq_req_3_bits_ldest                                    (io_enq_req_3_bits_ldest),
    .io_enq_req_3_bits_fuType                                   (io_enq_req_3_bits_fuType),
    .io_enq_req_3_bits_fuOpType                                 (io_enq_req_3_bits_fuOpType),
    .io_enq_req_3_bits_rfWen                                    (io_enq_req_3_bits_rfWen),
    .io_enq_req_3_bits_fpWen                                    (io_enq_req_3_bits_fpWen),
    .io_enq_req_3_bits_vecWen                                   (io_enq_req_3_bits_vecWen),
    .io_enq_req_3_bits_v0Wen                                    (io_enq_req_3_bits_v0Wen),
    .io_enq_req_3_bits_vlWen                                    (io_enq_req_3_bits_vlWen),
    .io_enq_req_3_bits_isXSTrap                                 (io_enq_req_3_bits_isXSTrap),
    .io_enq_req_3_bits_waitForward                              (io_enq_req_3_bits_waitForward),
    .io_enq_req_3_bits_blockBackward                            (io_enq_req_3_bits_blockBackward),
    .io_enq_req_3_bits_flushPipe                                (io_enq_req_3_bits_flushPipe),
    .io_enq_req_3_bits_vlsInstr                                 (io_enq_req_3_bits_vlsInstr),
    .io_enq_req_3_bits_wfflags                                  (io_enq_req_3_bits_wfflags),
    .io_enq_req_3_bits_isVset                                   (io_enq_req_3_bits_isVset),
    .io_enq_req_3_bits_firstUop                                 (io_enq_req_3_bits_firstUop),
    .io_enq_req_3_bits_numWB                                    (io_enq_req_3_bits_numWB),
    .io_enq_req_3_bits_commitType                               (io_enq_req_3_bits_commitType),
    .io_enq_req_3_bits_pdest                                    (io_enq_req_3_bits_pdest),
    .io_enq_req_3_bits_robIdx_flag                              (io_enq_req_3_bits_robIdx_flag),
    .io_enq_req_3_bits_robIdx_value                             (io_enq_req_3_bits_robIdx_value),
    .io_enq_req_3_bits_instrSize                                (io_enq_req_3_bits_instrSize),
    .io_enq_req_3_bits_dirtyFs                                  (io_enq_req_3_bits_dirtyFs),
    .io_enq_req_3_bits_dirtyVs                                  (io_enq_req_3_bits_dirtyVs),
    .io_enq_req_3_bits_traceBlockInPipe_itype                   (io_enq_req_3_bits_traceBlockInPipe_itype),
    .io_enq_req_3_bits_traceBlockInPipe_iretire                 (io_enq_req_3_bits_traceBlockInPipe_iretire),
    .io_enq_req_3_bits_traceBlockInPipe_ilastsize               (io_enq_req_3_bits_traceBlockInPipe_ilastsize),
    .io_enq_req_3_bits_eliminatedMove                           (io_enq_req_3_bits_eliminatedMove),
    .io_enq_req_3_bits_snapshot                                 (io_enq_req_3_bits_snapshot),
    .io_enq_req_3_bits_debugInfo_renameTime                     (io_enq_req_3_bits_debugInfo_renameTime),
    .io_enq_req_3_bits_lqIdx_value                              (io_enq_req_3_bits_lqIdx_value),
    .io_enq_req_3_bits_sqIdx_value                              (io_enq_req_3_bits_sqIdx_value),
    .io_enq_req_3_bits_debug_fuType                             (io_enq_req_3_bits_debug_fuType),
    .io_enq_req_3_bits_debug_sim_trig                           (io_enq_req_3_bits_debug_sim_trig),
    .io_enq_req_4_valid                                         (io_enq_req_4_valid),
    .io_enq_req_4_bits_instr                                    (io_enq_req_4_bits_instr),
    .io_enq_req_4_bits_pc                                       (io_enq_req_4_bits_pc),
    .io_enq_req_4_bits_exceptionVec_0                           (io_enq_req_4_bits_exceptionVec_0),
    .io_enq_req_4_bits_exceptionVec_1                           (io_enq_req_4_bits_exceptionVec_1),
    .io_enq_req_4_bits_exceptionVec_2                           (io_enq_req_4_bits_exceptionVec_2),
    .io_enq_req_4_bits_exceptionVec_3                           (io_enq_req_4_bits_exceptionVec_3),
    .io_enq_req_4_bits_exceptionVec_12                          (io_enq_req_4_bits_exceptionVec_12),
    .io_enq_req_4_bits_exceptionVec_20                          (io_enq_req_4_bits_exceptionVec_20),
    .io_enq_req_4_bits_exceptionVec_22                          (io_enq_req_4_bits_exceptionVec_22),
    .io_enq_req_4_bits_hasException                             (io_enq_req_4_bits_hasException),
    .io_enq_req_4_bits_trigger                                  (io_enq_req_4_bits_trigger),
    .io_enq_req_4_bits_preDecodeInfo_isRVC                      (io_enq_req_4_bits_preDecodeInfo_isRVC),
    .io_enq_req_4_bits_ftqPtr_flag                              (io_enq_req_4_bits_ftqPtr_flag),
    .io_enq_req_4_bits_ftqPtr_value                             (io_enq_req_4_bits_ftqPtr_value),
    .io_enq_req_4_bits_ftqOffset                                (io_enq_req_4_bits_ftqOffset),
    .io_enq_req_4_bits_ldest                                    (io_enq_req_4_bits_ldest),
    .io_enq_req_4_bits_fuType                                   (io_enq_req_4_bits_fuType),
    .io_enq_req_4_bits_fuOpType                                 (io_enq_req_4_bits_fuOpType),
    .io_enq_req_4_bits_rfWen                                    (io_enq_req_4_bits_rfWen),
    .io_enq_req_4_bits_fpWen                                    (io_enq_req_4_bits_fpWen),
    .io_enq_req_4_bits_vecWen                                   (io_enq_req_4_bits_vecWen),
    .io_enq_req_4_bits_v0Wen                                    (io_enq_req_4_bits_v0Wen),
    .io_enq_req_4_bits_vlWen                                    (io_enq_req_4_bits_vlWen),
    .io_enq_req_4_bits_isXSTrap                                 (io_enq_req_4_bits_isXSTrap),
    .io_enq_req_4_bits_waitForward                              (io_enq_req_4_bits_waitForward),
    .io_enq_req_4_bits_blockBackward                            (io_enq_req_4_bits_blockBackward),
    .io_enq_req_4_bits_flushPipe                                (io_enq_req_4_bits_flushPipe),
    .io_enq_req_4_bits_vlsInstr                                 (io_enq_req_4_bits_vlsInstr),
    .io_enq_req_4_bits_wfflags                                  (io_enq_req_4_bits_wfflags),
    .io_enq_req_4_bits_isVset                                   (io_enq_req_4_bits_isVset),
    .io_enq_req_4_bits_firstUop                                 (io_enq_req_4_bits_firstUop),
    .io_enq_req_4_bits_numWB                                    (io_enq_req_4_bits_numWB),
    .io_enq_req_4_bits_commitType                               (io_enq_req_4_bits_commitType),
    .io_enq_req_4_bits_pdest                                    (io_enq_req_4_bits_pdest),
    .io_enq_req_4_bits_robIdx_flag                              (io_enq_req_4_bits_robIdx_flag),
    .io_enq_req_4_bits_robIdx_value                             (io_enq_req_4_bits_robIdx_value),
    .io_enq_req_4_bits_instrSize                                (io_enq_req_4_bits_instrSize),
    .io_enq_req_4_bits_dirtyFs                                  (io_enq_req_4_bits_dirtyFs),
    .io_enq_req_4_bits_dirtyVs                                  (io_enq_req_4_bits_dirtyVs),
    .io_enq_req_4_bits_traceBlockInPipe_itype                   (io_enq_req_4_bits_traceBlockInPipe_itype),
    .io_enq_req_4_bits_traceBlockInPipe_iretire                 (io_enq_req_4_bits_traceBlockInPipe_iretire),
    .io_enq_req_4_bits_traceBlockInPipe_ilastsize               (io_enq_req_4_bits_traceBlockInPipe_ilastsize),
    .io_enq_req_4_bits_eliminatedMove                           (io_enq_req_4_bits_eliminatedMove),
    .io_enq_req_4_bits_snapshot                                 (io_enq_req_4_bits_snapshot),
    .io_enq_req_4_bits_debugInfo_renameTime                     (io_enq_req_4_bits_debugInfo_renameTime),
    .io_enq_req_4_bits_lqIdx_value                              (io_enq_req_4_bits_lqIdx_value),
    .io_enq_req_4_bits_sqIdx_value                              (io_enq_req_4_bits_sqIdx_value),
    .io_enq_req_4_bits_debug_fuType                             (io_enq_req_4_bits_debug_fuType),
    .io_enq_req_4_bits_debug_sim_trig                           (io_enq_req_4_bits_debug_sim_trig),
    .io_enq_req_5_valid                                         (io_enq_req_5_valid),
    .io_enq_req_5_bits_instr                                    (io_enq_req_5_bits_instr),
    .io_enq_req_5_bits_pc                                       (io_enq_req_5_bits_pc),
    .io_enq_req_5_bits_exceptionVec_0                           (io_enq_req_5_bits_exceptionVec_0),
    .io_enq_req_5_bits_exceptionVec_1                           (io_enq_req_5_bits_exceptionVec_1),
    .io_enq_req_5_bits_exceptionVec_2                           (io_enq_req_5_bits_exceptionVec_2),
    .io_enq_req_5_bits_exceptionVec_3                           (io_enq_req_5_bits_exceptionVec_3),
    .io_enq_req_5_bits_exceptionVec_12                          (io_enq_req_5_bits_exceptionVec_12),
    .io_enq_req_5_bits_exceptionVec_20                          (io_enq_req_5_bits_exceptionVec_20),
    .io_enq_req_5_bits_exceptionVec_22                          (io_enq_req_5_bits_exceptionVec_22),
    .io_enq_req_5_bits_hasException                             (io_enq_req_5_bits_hasException),
    .io_enq_req_5_bits_trigger                                  (io_enq_req_5_bits_trigger),
    .io_enq_req_5_bits_preDecodeInfo_isRVC                      (io_enq_req_5_bits_preDecodeInfo_isRVC),
    .io_enq_req_5_bits_ftqPtr_flag                              (io_enq_req_5_bits_ftqPtr_flag),
    .io_enq_req_5_bits_ftqPtr_value                             (io_enq_req_5_bits_ftqPtr_value),
    .io_enq_req_5_bits_ftqOffset                                (io_enq_req_5_bits_ftqOffset),
    .io_enq_req_5_bits_ldest                                    (io_enq_req_5_bits_ldest),
    .io_enq_req_5_bits_fuType                                   (io_enq_req_5_bits_fuType),
    .io_enq_req_5_bits_fuOpType                                 (io_enq_req_5_bits_fuOpType),
    .io_enq_req_5_bits_rfWen                                    (io_enq_req_5_bits_rfWen),
    .io_enq_req_5_bits_fpWen                                    (io_enq_req_5_bits_fpWen),
    .io_enq_req_5_bits_vecWen                                   (io_enq_req_5_bits_vecWen),
    .io_enq_req_5_bits_v0Wen                                    (io_enq_req_5_bits_v0Wen),
    .io_enq_req_5_bits_vlWen                                    (io_enq_req_5_bits_vlWen),
    .io_enq_req_5_bits_isXSTrap                                 (io_enq_req_5_bits_isXSTrap),
    .io_enq_req_5_bits_waitForward                              (io_enq_req_5_bits_waitForward),
    .io_enq_req_5_bits_blockBackward                            (io_enq_req_5_bits_blockBackward),
    .io_enq_req_5_bits_flushPipe                                (io_enq_req_5_bits_flushPipe),
    .io_enq_req_5_bits_vlsInstr                                 (io_enq_req_5_bits_vlsInstr),
    .io_enq_req_5_bits_wfflags                                  (io_enq_req_5_bits_wfflags),
    .io_enq_req_5_bits_isVset                                   (io_enq_req_5_bits_isVset),
    .io_enq_req_5_bits_firstUop                                 (io_enq_req_5_bits_firstUop),
    .io_enq_req_5_bits_numWB                                    (io_enq_req_5_bits_numWB),
    .io_enq_req_5_bits_commitType                               (io_enq_req_5_bits_commitType),
    .io_enq_req_5_bits_pdest                                    (io_enq_req_5_bits_pdest),
    .io_enq_req_5_bits_robIdx_flag                              (io_enq_req_5_bits_robIdx_flag),
    .io_enq_req_5_bits_robIdx_value                             (io_enq_req_5_bits_robIdx_value),
    .io_enq_req_5_bits_instrSize                                (io_enq_req_5_bits_instrSize),
    .io_enq_req_5_bits_dirtyFs                                  (io_enq_req_5_bits_dirtyFs),
    .io_enq_req_5_bits_dirtyVs                                  (io_enq_req_5_bits_dirtyVs),
    .io_enq_req_5_bits_traceBlockInPipe_itype                   (io_enq_req_5_bits_traceBlockInPipe_itype),
    .io_enq_req_5_bits_traceBlockInPipe_iretire                 (io_enq_req_5_bits_traceBlockInPipe_iretire),
    .io_enq_req_5_bits_traceBlockInPipe_ilastsize               (io_enq_req_5_bits_traceBlockInPipe_ilastsize),
    .io_enq_req_5_bits_eliminatedMove                           (io_enq_req_5_bits_eliminatedMove),
    .io_enq_req_5_bits_snapshot                                 (io_enq_req_5_bits_snapshot),
    .io_enq_req_5_bits_debugInfo_renameTime                     (io_enq_req_5_bits_debugInfo_renameTime),
    .io_enq_req_5_bits_lqIdx_value                              (io_enq_req_5_bits_lqIdx_value),
    .io_enq_req_5_bits_sqIdx_value                              (io_enq_req_5_bits_sqIdx_value),
    .io_enq_req_5_bits_debug_fuType                             (io_enq_req_5_bits_debug_fuType),
    .io_enq_req_5_bits_debug_sim_trig                           (io_enq_req_5_bits_debug_sim_trig),
    .io_flushOut_valid                                          (io_flushOut_valid),
    .io_flushOut_bits_isRVC                                     (io_flushOut_bits_isRVC),
    .io_flushOut_bits_robIdx_flag                               (io_flushOut_bits_robIdx_flag),
    .io_flushOut_bits_robIdx_value                              (io_flushOut_bits_robIdx_value),
    .io_flushOut_bits_ftqIdx_flag                               (io_flushOut_bits_ftqIdx_flag),
    .io_flushOut_bits_ftqIdx_value                              (io_flushOut_bits_ftqIdx_value),
    .io_flushOut_bits_ftqOffset                                 (io_flushOut_bits_ftqOffset),
    .io_flushOut_bits_level                                     (io_flushOut_bits_level),
    .io_flushOut_bits_satpFlush                                 (io_flushOut_bits_satpFlush),
    .io_flushOut_bits_isVlsException                            (io_flushOut_bits_isVlsException),
    .io_exception_valid                                         (io_exception_valid),
    .io_exception_bits_instr                                    (io_exception_bits_instr),
    .io_exception_bits_commitType                               (io_exception_bits_commitType),
    .io_exception_bits_exceptionVec_0                           (io_exception_bits_exceptionVec_0),
    .io_exception_bits_exceptionVec_1                           (io_exception_bits_exceptionVec_1),
    .io_exception_bits_exceptionVec_2                           (io_exception_bits_exceptionVec_2),
    .io_exception_bits_exceptionVec_3                           (io_exception_bits_exceptionVec_3),
    .io_exception_bits_exceptionVec_4                           (io_exception_bits_exceptionVec_4),
    .io_exception_bits_exceptionVec_5                           (io_exception_bits_exceptionVec_5),
    .io_exception_bits_exceptionVec_6                           (io_exception_bits_exceptionVec_6),
    .io_exception_bits_exceptionVec_7                           (io_exception_bits_exceptionVec_7),
    .io_exception_bits_exceptionVec_8                           (io_exception_bits_exceptionVec_8),
    .io_exception_bits_exceptionVec_9                           (io_exception_bits_exceptionVec_9),
    .io_exception_bits_exceptionVec_10                          (io_exception_bits_exceptionVec_10),
    .io_exception_bits_exceptionVec_11                          (io_exception_bits_exceptionVec_11),
    .io_exception_bits_exceptionVec_12                          (io_exception_bits_exceptionVec_12),
    .io_exception_bits_exceptionVec_13                          (io_exception_bits_exceptionVec_13),
    .io_exception_bits_exceptionVec_14                          (io_exception_bits_exceptionVec_14),
    .io_exception_bits_exceptionVec_15                          (io_exception_bits_exceptionVec_15),
    .io_exception_bits_exceptionVec_16                          (io_exception_bits_exceptionVec_16),
    .io_exception_bits_exceptionVec_17                          (io_exception_bits_exceptionVec_17),
    .io_exception_bits_exceptionVec_18                          (io_exception_bits_exceptionVec_18),
    .io_exception_bits_exceptionVec_19                          (io_exception_bits_exceptionVec_19),
    .io_exception_bits_exceptionVec_20                          (io_exception_bits_exceptionVec_20),
    .io_exception_bits_exceptionVec_21                          (io_exception_bits_exceptionVec_21),
    .io_exception_bits_exceptionVec_22                          (io_exception_bits_exceptionVec_22),
    .io_exception_bits_exceptionVec_23                          (io_exception_bits_exceptionVec_23),
    .io_exception_bits_isPcBkpt                                 (io_exception_bits_isPcBkpt),
    .io_exception_bits_isFetchMalAddr                           (io_exception_bits_isFetchMalAddr),
    .io_exception_bits_satpFlushFirstFetchFault                 (io_exception_bits_satpFlushFirstFetchFault),
    .io_exception_bits_gpaddr                                   (io_exception_bits_gpaddr),
    .io_exception_bits_singleStep                               (io_exception_bits_singleStep),
    .io_exception_bits_crossPageIPFFix                          (io_exception_bits_crossPageIPFFix),
    .io_exception_bits_isInterrupt                              (io_exception_bits_isInterrupt),
    .io_exception_bits_isHls                                    (io_exception_bits_isHls),
    .io_exception_bits_trigger                                  (io_exception_bits_trigger),
    .io_exception_bits_isForVSnonLeafPTE                        (io_exception_bits_isForVSnonLeafPTE),
    .io_writeback_24_valid                                      (io_writeback_24_valid),
    .io_writeback_24_bits_robIdx_value                          (io_writeback_24_bits_robIdx_value),
    .io_writeback_24_bits_exceptionVec_0                        (io_writeback_24_bits_exceptionVec_0),
    .io_writeback_24_bits_exceptionVec_1                        (io_writeback_24_bits_exceptionVec_1),
    .io_writeback_24_bits_exceptionVec_2                        (io_writeback_24_bits_exceptionVec_2),
    .io_writeback_24_bits_exceptionVec_3                        (io_writeback_24_bits_exceptionVec_3),
    .io_writeback_24_bits_exceptionVec_4                        (io_writeback_24_bits_exceptionVec_4),
    .io_writeback_24_bits_exceptionVec_5                        (io_writeback_24_bits_exceptionVec_5),
    .io_writeback_24_bits_exceptionVec_6                        (io_writeback_24_bits_exceptionVec_6),
    .io_writeback_24_bits_exceptionVec_7                        (io_writeback_24_bits_exceptionVec_7),
    .io_writeback_24_bits_exceptionVec_8                        (io_writeback_24_bits_exceptionVec_8),
    .io_writeback_24_bits_exceptionVec_9                        (io_writeback_24_bits_exceptionVec_9),
    .io_writeback_24_bits_exceptionVec_10                       (io_writeback_24_bits_exceptionVec_10),
    .io_writeback_24_bits_exceptionVec_11                       (io_writeback_24_bits_exceptionVec_11),
    .io_writeback_24_bits_exceptionVec_12                       (io_writeback_24_bits_exceptionVec_12),
    .io_writeback_24_bits_exceptionVec_13                       (io_writeback_24_bits_exceptionVec_13),
    .io_writeback_24_bits_exceptionVec_14                       (io_writeback_24_bits_exceptionVec_14),
    .io_writeback_24_bits_exceptionVec_15                       (io_writeback_24_bits_exceptionVec_15),
    .io_writeback_24_bits_exceptionVec_16                       (io_writeback_24_bits_exceptionVec_16),
    .io_writeback_24_bits_exceptionVec_17                       (io_writeback_24_bits_exceptionVec_17),
    .io_writeback_24_bits_exceptionVec_18                       (io_writeback_24_bits_exceptionVec_18),
    .io_writeback_24_bits_exceptionVec_19                       (io_writeback_24_bits_exceptionVec_19),
    .io_writeback_24_bits_exceptionVec_20                       (io_writeback_24_bits_exceptionVec_20),
    .io_writeback_24_bits_exceptionVec_21                       (io_writeback_24_bits_exceptionVec_21),
    .io_writeback_24_bits_exceptionVec_22                       (io_writeback_24_bits_exceptionVec_22),
    .io_writeback_24_bits_exceptionVec_23                       (io_writeback_24_bits_exceptionVec_23),
    .io_writeback_24_bits_trigger                               (io_writeback_24_bits_trigger),
    .io_writeback_24_bits_vls_vpu_vstart                        (io_writeback_24_bits_vls_vpu_vstart),
    .io_writeback_23_valid                                      (io_writeback_23_valid),
    .io_writeback_23_bits_robIdx_value                          (io_writeback_23_bits_robIdx_value),
    .io_writeback_23_bits_exceptionVec_0                        (io_writeback_23_bits_exceptionVec_0),
    .io_writeback_23_bits_exceptionVec_1                        (io_writeback_23_bits_exceptionVec_1),
    .io_writeback_23_bits_exceptionVec_2                        (io_writeback_23_bits_exceptionVec_2),
    .io_writeback_23_bits_exceptionVec_3                        (io_writeback_23_bits_exceptionVec_3),
    .io_writeback_23_bits_exceptionVec_4                        (io_writeback_23_bits_exceptionVec_4),
    .io_writeback_23_bits_exceptionVec_5                        (io_writeback_23_bits_exceptionVec_5),
    .io_writeback_23_bits_exceptionVec_6                        (io_writeback_23_bits_exceptionVec_6),
    .io_writeback_23_bits_exceptionVec_7                        (io_writeback_23_bits_exceptionVec_7),
    .io_writeback_23_bits_exceptionVec_8                        (io_writeback_23_bits_exceptionVec_8),
    .io_writeback_23_bits_exceptionVec_9                        (io_writeback_23_bits_exceptionVec_9),
    .io_writeback_23_bits_exceptionVec_10                       (io_writeback_23_bits_exceptionVec_10),
    .io_writeback_23_bits_exceptionVec_11                       (io_writeback_23_bits_exceptionVec_11),
    .io_writeback_23_bits_exceptionVec_12                       (io_writeback_23_bits_exceptionVec_12),
    .io_writeback_23_bits_exceptionVec_13                       (io_writeback_23_bits_exceptionVec_13),
    .io_writeback_23_bits_exceptionVec_14                       (io_writeback_23_bits_exceptionVec_14),
    .io_writeback_23_bits_exceptionVec_15                       (io_writeback_23_bits_exceptionVec_15),
    .io_writeback_23_bits_exceptionVec_16                       (io_writeback_23_bits_exceptionVec_16),
    .io_writeback_23_bits_exceptionVec_17                       (io_writeback_23_bits_exceptionVec_17),
    .io_writeback_23_bits_exceptionVec_18                       (io_writeback_23_bits_exceptionVec_18),
    .io_writeback_23_bits_exceptionVec_19                       (io_writeback_23_bits_exceptionVec_19),
    .io_writeback_23_bits_exceptionVec_20                       (io_writeback_23_bits_exceptionVec_20),
    .io_writeback_23_bits_exceptionVec_21                       (io_writeback_23_bits_exceptionVec_21),
    .io_writeback_23_bits_exceptionVec_22                       (io_writeback_23_bits_exceptionVec_22),
    .io_writeback_23_bits_exceptionVec_23                       (io_writeback_23_bits_exceptionVec_23),
    .io_writeback_23_bits_trigger                               (io_writeback_23_bits_trigger),
    .io_writeback_23_bits_vls_vpu_vstart                        (io_writeback_23_bits_vls_vpu_vstart),
    .io_writeback_22_valid                                      (io_writeback_22_valid),
    .io_writeback_22_bits_robIdx_value                          (io_writeback_22_bits_robIdx_value),
    .io_writeback_22_bits_exceptionVec_0                        (io_writeback_22_bits_exceptionVec_0),
    .io_writeback_22_bits_exceptionVec_1                        (io_writeback_22_bits_exceptionVec_1),
    .io_writeback_22_bits_exceptionVec_2                        (io_writeback_22_bits_exceptionVec_2),
    .io_writeback_22_bits_exceptionVec_3                        (io_writeback_22_bits_exceptionVec_3),
    .io_writeback_22_bits_exceptionVec_4                        (io_writeback_22_bits_exceptionVec_4),
    .io_writeback_22_bits_exceptionVec_5                        (io_writeback_22_bits_exceptionVec_5),
    .io_writeback_22_bits_exceptionVec_6                        (io_writeback_22_bits_exceptionVec_6),
    .io_writeback_22_bits_exceptionVec_7                        (io_writeback_22_bits_exceptionVec_7),
    .io_writeback_22_bits_exceptionVec_8                        (io_writeback_22_bits_exceptionVec_8),
    .io_writeback_22_bits_exceptionVec_9                        (io_writeback_22_bits_exceptionVec_9),
    .io_writeback_22_bits_exceptionVec_10                       (io_writeback_22_bits_exceptionVec_10),
    .io_writeback_22_bits_exceptionVec_11                       (io_writeback_22_bits_exceptionVec_11),
    .io_writeback_22_bits_exceptionVec_12                       (io_writeback_22_bits_exceptionVec_12),
    .io_writeback_22_bits_exceptionVec_13                       (io_writeback_22_bits_exceptionVec_13),
    .io_writeback_22_bits_exceptionVec_14                       (io_writeback_22_bits_exceptionVec_14),
    .io_writeback_22_bits_exceptionVec_15                       (io_writeback_22_bits_exceptionVec_15),
    .io_writeback_22_bits_exceptionVec_16                       (io_writeback_22_bits_exceptionVec_16),
    .io_writeback_22_bits_exceptionVec_17                       (io_writeback_22_bits_exceptionVec_17),
    .io_writeback_22_bits_exceptionVec_18                       (io_writeback_22_bits_exceptionVec_18),
    .io_writeback_22_bits_exceptionVec_19                       (io_writeback_22_bits_exceptionVec_19),
    .io_writeback_22_bits_exceptionVec_20                       (io_writeback_22_bits_exceptionVec_20),
    .io_writeback_22_bits_exceptionVec_21                       (io_writeback_22_bits_exceptionVec_21),
    .io_writeback_22_bits_exceptionVec_22                       (io_writeback_22_bits_exceptionVec_22),
    .io_writeback_22_bits_exceptionVec_23                       (io_writeback_22_bits_exceptionVec_23),
    .io_writeback_21_valid                                      (io_writeback_21_valid),
    .io_writeback_21_bits_robIdx_value                          (io_writeback_21_bits_robIdx_value),
    .io_writeback_21_bits_exceptionVec_0                        (io_writeback_21_bits_exceptionVec_0),
    .io_writeback_21_bits_exceptionVec_1                        (io_writeback_21_bits_exceptionVec_1),
    .io_writeback_21_bits_exceptionVec_2                        (io_writeback_21_bits_exceptionVec_2),
    .io_writeback_21_bits_exceptionVec_3                        (io_writeback_21_bits_exceptionVec_3),
    .io_writeback_21_bits_exceptionVec_4                        (io_writeback_21_bits_exceptionVec_4),
    .io_writeback_21_bits_exceptionVec_5                        (io_writeback_21_bits_exceptionVec_5),
    .io_writeback_21_bits_exceptionVec_6                        (io_writeback_21_bits_exceptionVec_6),
    .io_writeback_21_bits_exceptionVec_7                        (io_writeback_21_bits_exceptionVec_7),
    .io_writeback_21_bits_exceptionVec_8                        (io_writeback_21_bits_exceptionVec_8),
    .io_writeback_21_bits_exceptionVec_9                        (io_writeback_21_bits_exceptionVec_9),
    .io_writeback_21_bits_exceptionVec_10                       (io_writeback_21_bits_exceptionVec_10),
    .io_writeback_21_bits_exceptionVec_11                       (io_writeback_21_bits_exceptionVec_11),
    .io_writeback_21_bits_exceptionVec_12                       (io_writeback_21_bits_exceptionVec_12),
    .io_writeback_21_bits_exceptionVec_13                       (io_writeback_21_bits_exceptionVec_13),
    .io_writeback_21_bits_exceptionVec_14                       (io_writeback_21_bits_exceptionVec_14),
    .io_writeback_21_bits_exceptionVec_15                       (io_writeback_21_bits_exceptionVec_15),
    .io_writeback_21_bits_exceptionVec_16                       (io_writeback_21_bits_exceptionVec_16),
    .io_writeback_21_bits_exceptionVec_17                       (io_writeback_21_bits_exceptionVec_17),
    .io_writeback_21_bits_exceptionVec_18                       (io_writeback_21_bits_exceptionVec_18),
    .io_writeback_21_bits_exceptionVec_19                       (io_writeback_21_bits_exceptionVec_19),
    .io_writeback_21_bits_exceptionVec_20                       (io_writeback_21_bits_exceptionVec_20),
    .io_writeback_21_bits_exceptionVec_21                       (io_writeback_21_bits_exceptionVec_21),
    .io_writeback_21_bits_exceptionVec_22                       (io_writeback_21_bits_exceptionVec_22),
    .io_writeback_21_bits_exceptionVec_23                       (io_writeback_21_bits_exceptionVec_23),
    .io_writeback_20_valid                                      (io_writeback_20_valid),
    .io_writeback_20_bits_robIdx_value                          (io_writeback_20_bits_robIdx_value),
    .io_writeback_20_bits_exceptionVec_0                        (io_writeback_20_bits_exceptionVec_0),
    .io_writeback_20_bits_exceptionVec_1                        (io_writeback_20_bits_exceptionVec_1),
    .io_writeback_20_bits_exceptionVec_2                        (io_writeback_20_bits_exceptionVec_2),
    .io_writeback_20_bits_exceptionVec_3                        (io_writeback_20_bits_exceptionVec_3),
    .io_writeback_20_bits_exceptionVec_4                        (io_writeback_20_bits_exceptionVec_4),
    .io_writeback_20_bits_exceptionVec_5                        (io_writeback_20_bits_exceptionVec_5),
    .io_writeback_20_bits_exceptionVec_6                        (io_writeback_20_bits_exceptionVec_6),
    .io_writeback_20_bits_exceptionVec_7                        (io_writeback_20_bits_exceptionVec_7),
    .io_writeback_20_bits_exceptionVec_8                        (io_writeback_20_bits_exceptionVec_8),
    .io_writeback_20_bits_exceptionVec_9                        (io_writeback_20_bits_exceptionVec_9),
    .io_writeback_20_bits_exceptionVec_10                       (io_writeback_20_bits_exceptionVec_10),
    .io_writeback_20_bits_exceptionVec_11                       (io_writeback_20_bits_exceptionVec_11),
    .io_writeback_20_bits_exceptionVec_12                       (io_writeback_20_bits_exceptionVec_12),
    .io_writeback_20_bits_exceptionVec_13                       (io_writeback_20_bits_exceptionVec_13),
    .io_writeback_20_bits_exceptionVec_14                       (io_writeback_20_bits_exceptionVec_14),
    .io_writeback_20_bits_exceptionVec_15                       (io_writeback_20_bits_exceptionVec_15),
    .io_writeback_20_bits_exceptionVec_16                       (io_writeback_20_bits_exceptionVec_16),
    .io_writeback_20_bits_exceptionVec_17                       (io_writeback_20_bits_exceptionVec_17),
    .io_writeback_20_bits_exceptionVec_18                       (io_writeback_20_bits_exceptionVec_18),
    .io_writeback_20_bits_exceptionVec_19                       (io_writeback_20_bits_exceptionVec_19),
    .io_writeback_20_bits_exceptionVec_20                       (io_writeback_20_bits_exceptionVec_20),
    .io_writeback_20_bits_exceptionVec_21                       (io_writeback_20_bits_exceptionVec_21),
    .io_writeback_20_bits_exceptionVec_22                       (io_writeback_20_bits_exceptionVec_22),
    .io_writeback_20_bits_exceptionVec_23                       (io_writeback_20_bits_exceptionVec_23),
    .io_writeback_19_valid                                      (io_writeback_19_valid),
    .io_writeback_19_bits_robIdx_value                          (io_writeback_19_bits_robIdx_value),
    .io_writeback_19_bits_exceptionVec_0                        (io_writeback_19_bits_exceptionVec_0),
    .io_writeback_19_bits_exceptionVec_1                        (io_writeback_19_bits_exceptionVec_1),
    .io_writeback_19_bits_exceptionVec_2                        (io_writeback_19_bits_exceptionVec_2),
    .io_writeback_19_bits_exceptionVec_3                        (io_writeback_19_bits_exceptionVec_3),
    .io_writeback_19_bits_exceptionVec_4                        (io_writeback_19_bits_exceptionVec_4),
    .io_writeback_19_bits_exceptionVec_5                        (io_writeback_19_bits_exceptionVec_5),
    .io_writeback_19_bits_exceptionVec_6                        (io_writeback_19_bits_exceptionVec_6),
    .io_writeback_19_bits_exceptionVec_7                        (io_writeback_19_bits_exceptionVec_7),
    .io_writeback_19_bits_exceptionVec_8                        (io_writeback_19_bits_exceptionVec_8),
    .io_writeback_19_bits_exceptionVec_9                        (io_writeback_19_bits_exceptionVec_9),
    .io_writeback_19_bits_exceptionVec_10                       (io_writeback_19_bits_exceptionVec_10),
    .io_writeback_19_bits_exceptionVec_11                       (io_writeback_19_bits_exceptionVec_11),
    .io_writeback_19_bits_exceptionVec_12                       (io_writeback_19_bits_exceptionVec_12),
    .io_writeback_19_bits_exceptionVec_13                       (io_writeback_19_bits_exceptionVec_13),
    .io_writeback_19_bits_exceptionVec_14                       (io_writeback_19_bits_exceptionVec_14),
    .io_writeback_19_bits_exceptionVec_15                       (io_writeback_19_bits_exceptionVec_15),
    .io_writeback_19_bits_exceptionVec_16                       (io_writeback_19_bits_exceptionVec_16),
    .io_writeback_19_bits_exceptionVec_17                       (io_writeback_19_bits_exceptionVec_17),
    .io_writeback_19_bits_exceptionVec_18                       (io_writeback_19_bits_exceptionVec_18),
    .io_writeback_19_bits_exceptionVec_19                       (io_writeback_19_bits_exceptionVec_19),
    .io_writeback_19_bits_exceptionVec_20                       (io_writeback_19_bits_exceptionVec_20),
    .io_writeback_19_bits_exceptionVec_21                       (io_writeback_19_bits_exceptionVec_21),
    .io_writeback_19_bits_exceptionVec_22                       (io_writeback_19_bits_exceptionVec_22),
    .io_writeback_19_bits_exceptionVec_23                       (io_writeback_19_bits_exceptionVec_23),
    .io_writeback_18_valid                                      (io_writeback_18_valid),
    .io_writeback_18_bits_robIdx_value                          (io_writeback_18_bits_robIdx_value),
    .io_writeback_18_bits_exceptionVec_0                        (io_writeback_18_bits_exceptionVec_0),
    .io_writeback_18_bits_exceptionVec_1                        (io_writeback_18_bits_exceptionVec_1),
    .io_writeback_18_bits_exceptionVec_2                        (io_writeback_18_bits_exceptionVec_2),
    .io_writeback_18_bits_exceptionVec_3                        (io_writeback_18_bits_exceptionVec_3),
    .io_writeback_18_bits_exceptionVec_4                        (io_writeback_18_bits_exceptionVec_4),
    .io_writeback_18_bits_exceptionVec_5                        (io_writeback_18_bits_exceptionVec_5),
    .io_writeback_18_bits_exceptionVec_6                        (io_writeback_18_bits_exceptionVec_6),
    .io_writeback_18_bits_exceptionVec_7                        (io_writeback_18_bits_exceptionVec_7),
    .io_writeback_18_bits_exceptionVec_8                        (io_writeback_18_bits_exceptionVec_8),
    .io_writeback_18_bits_exceptionVec_9                        (io_writeback_18_bits_exceptionVec_9),
    .io_writeback_18_bits_exceptionVec_10                       (io_writeback_18_bits_exceptionVec_10),
    .io_writeback_18_bits_exceptionVec_11                       (io_writeback_18_bits_exceptionVec_11),
    .io_writeback_18_bits_exceptionVec_12                       (io_writeback_18_bits_exceptionVec_12),
    .io_writeback_18_bits_exceptionVec_13                       (io_writeback_18_bits_exceptionVec_13),
    .io_writeback_18_bits_exceptionVec_14                       (io_writeback_18_bits_exceptionVec_14),
    .io_writeback_18_bits_exceptionVec_15                       (io_writeback_18_bits_exceptionVec_15),
    .io_writeback_18_bits_exceptionVec_16                       (io_writeback_18_bits_exceptionVec_16),
    .io_writeback_18_bits_exceptionVec_17                       (io_writeback_18_bits_exceptionVec_17),
    .io_writeback_18_bits_exceptionVec_18                       (io_writeback_18_bits_exceptionVec_18),
    .io_writeback_18_bits_exceptionVec_19                       (io_writeback_18_bits_exceptionVec_19),
    .io_writeback_18_bits_exceptionVec_20                       (io_writeback_18_bits_exceptionVec_20),
    .io_writeback_18_bits_exceptionVec_21                       (io_writeback_18_bits_exceptionVec_21),
    .io_writeback_18_bits_exceptionVec_22                       (io_writeback_18_bits_exceptionVec_22),
    .io_writeback_18_bits_exceptionVec_23                       (io_writeback_18_bits_exceptionVec_23),
    .io_writeback_14_valid                                      (io_writeback_14_valid),
    .io_writeback_14_bits_robIdx_value                          (io_writeback_14_bits_robIdx_value),
    .io_writeback_13_valid                                      (io_writeback_13_valid),
    .io_writeback_13_bits_robIdx_value                          (io_writeback_13_bits_robIdx_value),
    .io_writeback_7_valid                                       (io_writeback_7_valid),
    .io_writeback_7_bits_robIdx_value                           (io_writeback_7_bits_robIdx_value),
    .io_writeback_7_bits_redirect_valid                         (io_writeback_7_bits_redirect_valid),
    .io_writeback_7_bits_redirect_bits_cfiUpdate_isMisPred      (io_writeback_7_bits_redirect_bits_cfiUpdate_isMisPred),
    .io_writeback_7_bits_exceptionVec_2                         (io_writeback_7_bits_exceptionVec_2),
    .io_writeback_7_bits_exceptionVec_3                         (io_writeback_7_bits_exceptionVec_3),
    .io_writeback_7_bits_exceptionVec_8                         (io_writeback_7_bits_exceptionVec_8),
    .io_writeback_7_bits_exceptionVec_9                         (io_writeback_7_bits_exceptionVec_9),
    .io_writeback_7_bits_exceptionVec_10                        (io_writeback_7_bits_exceptionVec_10),
    .io_writeback_7_bits_exceptionVec_11                        (io_writeback_7_bits_exceptionVec_11),
    .io_writeback_7_bits_exceptionVec_22                        (io_writeback_7_bits_exceptionVec_22),
    .io_writeback_5_valid                                       (io_writeback_5_valid),
    .io_writeback_5_bits_redirect_valid                         (io_writeback_5_bits_redirect_valid),
    .io_writeback_5_bits_redirect_bits_cfiUpdate_isMisPred      (io_writeback_5_bits_redirect_bits_cfiUpdate_isMisPred),
    .io_writeback_3_valid                                       (io_writeback_3_valid),
    .io_writeback_3_bits_redirect_valid                         (io_writeback_3_bits_redirect_valid),
    .io_writeback_3_bits_redirect_bits_cfiUpdate_isMisPred      (io_writeback_3_bits_redirect_bits_cfiUpdate_isMisPred),
    .io_writeback_1_valid                                       (io_writeback_1_valid),
    .io_writeback_1_bits_redirect_valid                         (io_writeback_1_bits_redirect_valid),
    .io_writeback_1_bits_redirect_bits_cfiUpdate_isMisPred      (io_writeback_1_bits_redirect_bits_cfiUpdate_isMisPred),
    .io_exuWriteback_26_valid                                   (io_exuWriteback_26_valid),
    .io_exuWriteback_26_bits_robIdx_value                       (io_exuWriteback_26_bits_robIdx_value),
    .io_exuWriteback_25_valid                                   (io_exuWriteback_25_valid),
    .io_exuWriteback_25_bits_robIdx_value                       (io_exuWriteback_25_bits_robIdx_value),
    .io_exuWriteback_24_valid                                   (io_exuWriteback_24_valid),
    .io_exuWriteback_24_bits_data_0                             (io_exuWriteback_24_bits_data_0),
    .io_exuWriteback_24_bits_pdest                              (io_exuWriteback_24_bits_pdest),
    .io_exuWriteback_24_bits_robIdx_value                       (io_exuWriteback_24_bits_robIdx_value),
    .io_exuWriteback_24_bits_vecWen                             (io_exuWriteback_24_bits_vecWen),
    .io_exuWriteback_24_bits_v0Wen                              (io_exuWriteback_24_bits_v0Wen),
    .io_exuWriteback_24_bits_vls_vdIdx                          (io_exuWriteback_24_bits_vls_vdIdx),
    .io_exuWriteback_24_bits_debug_isMMIO                       (io_exuWriteback_24_bits_debug_isMMIO),
    .io_exuWriteback_24_bits_debug_isNCIO                       (io_exuWriteback_24_bits_debug_isNCIO),
    .io_exuWriteback_24_bits_debug_isPerfCnt                    (io_exuWriteback_24_bits_debug_isPerfCnt),
    .io_exuWriteback_24_bits_debug_paddr                        (io_exuWriteback_24_bits_debug_paddr),
    .io_exuWriteback_24_bits_debugInfo_enqRsTime                (io_exuWriteback_24_bits_debugInfo_enqRsTime),
    .io_exuWriteback_24_bits_debugInfo_selectTime               (io_exuWriteback_24_bits_debugInfo_selectTime),
    .io_exuWriteback_24_bits_debugInfo_issueTime                (io_exuWriteback_24_bits_debugInfo_issueTime),
    .io_exuWriteback_24_bits_debugInfo_writebackTime            (io_exuWriteback_24_bits_debugInfo_writebackTime),
    .io_exuWriteback_23_valid                                   (io_exuWriteback_23_valid),
    .io_exuWriteback_23_bits_data_0                             (io_exuWriteback_23_bits_data_0),
    .io_exuWriteback_23_bits_pdest                              (io_exuWriteback_23_bits_pdest),
    .io_exuWriteback_23_bits_robIdx_value                       (io_exuWriteback_23_bits_robIdx_value),
    .io_exuWriteback_23_bits_vecWen                             (io_exuWriteback_23_bits_vecWen),
    .io_exuWriteback_23_bits_v0Wen                              (io_exuWriteback_23_bits_v0Wen),
    .io_exuWriteback_23_bits_vls_vdIdx                          (io_exuWriteback_23_bits_vls_vdIdx),
    .io_exuWriteback_23_bits_debug_isMMIO                       (io_exuWriteback_23_bits_debug_isMMIO),
    .io_exuWriteback_23_bits_debug_isNCIO                       (io_exuWriteback_23_bits_debug_isNCIO),
    .io_exuWriteback_23_bits_debug_isPerfCnt                    (io_exuWriteback_23_bits_debug_isPerfCnt),
    .io_exuWriteback_23_bits_debug_paddr                        (io_exuWriteback_23_bits_debug_paddr),
    .io_exuWriteback_23_bits_debugInfo_enqRsTime                (io_exuWriteback_23_bits_debugInfo_enqRsTime),
    .io_exuWriteback_23_bits_debugInfo_selectTime               (io_exuWriteback_23_bits_debugInfo_selectTime),
    .io_exuWriteback_23_bits_debugInfo_issueTime                (io_exuWriteback_23_bits_debugInfo_issueTime),
    .io_exuWriteback_23_bits_debugInfo_writebackTime            (io_exuWriteback_23_bits_debugInfo_writebackTime),
    .io_exuWriteback_22_valid                                   (io_exuWriteback_22_valid),
    .io_exuWriteback_22_bits_data_0                             (io_exuWriteback_22_bits_data_0),
    .io_exuWriteback_22_bits_robIdx_value                       (io_exuWriteback_22_bits_robIdx_value),
    .io_exuWriteback_22_bits_lqIdx_value                        (io_exuWriteback_22_bits_lqIdx_value),
    .io_exuWriteback_22_bits_debug_isMMIO                       (io_exuWriteback_22_bits_debug_isMMIO),
    .io_exuWriteback_22_bits_debug_isNCIO                       (io_exuWriteback_22_bits_debug_isNCIO),
    .io_exuWriteback_22_bits_debug_isPerfCnt                    (io_exuWriteback_22_bits_debug_isPerfCnt),
    .io_exuWriteback_22_bits_debug_paddr                        (io_exuWriteback_22_bits_debug_paddr),
    .io_exuWriteback_22_bits_debugInfo_enqRsTime                (io_exuWriteback_22_bits_debugInfo_enqRsTime),
    .io_exuWriteback_22_bits_debugInfo_selectTime               (io_exuWriteback_22_bits_debugInfo_selectTime),
    .io_exuWriteback_22_bits_debugInfo_issueTime                (io_exuWriteback_22_bits_debugInfo_issueTime),
    .io_exuWriteback_22_bits_debugInfo_writebackTime            (io_exuWriteback_22_bits_debugInfo_writebackTime),
    .io_exuWriteback_21_valid                                   (io_exuWriteback_21_valid),
    .io_exuWriteback_21_bits_data_0                             (io_exuWriteback_21_bits_data_0),
    .io_exuWriteback_21_bits_robIdx_value                       (io_exuWriteback_21_bits_robIdx_value),
    .io_exuWriteback_21_bits_lqIdx_value                        (io_exuWriteback_21_bits_lqIdx_value),
    .io_exuWriteback_21_bits_debug_isMMIO                       (io_exuWriteback_21_bits_debug_isMMIO),
    .io_exuWriteback_21_bits_debug_isNCIO                       (io_exuWriteback_21_bits_debug_isNCIO),
    .io_exuWriteback_21_bits_debug_isPerfCnt                    (io_exuWriteback_21_bits_debug_isPerfCnt),
    .io_exuWriteback_21_bits_debug_paddr                        (io_exuWriteback_21_bits_debug_paddr),
    .io_exuWriteback_21_bits_debugInfo_enqRsTime                (io_exuWriteback_21_bits_debugInfo_enqRsTime),
    .io_exuWriteback_21_bits_debugInfo_selectTime               (io_exuWriteback_21_bits_debugInfo_selectTime),
    .io_exuWriteback_21_bits_debugInfo_issueTime                (io_exuWriteback_21_bits_debugInfo_issueTime),
    .io_exuWriteback_21_bits_debugInfo_writebackTime            (io_exuWriteback_21_bits_debugInfo_writebackTime),
    .io_exuWriteback_20_valid                                   (io_exuWriteback_20_valid),
    .io_exuWriteback_20_bits_data_0                             (io_exuWriteback_20_bits_data_0),
    .io_exuWriteback_20_bits_robIdx_value                       (io_exuWriteback_20_bits_robIdx_value),
    .io_exuWriteback_20_bits_lqIdx_value                        (io_exuWriteback_20_bits_lqIdx_value),
    .io_exuWriteback_20_bits_debug_isMMIO                       (io_exuWriteback_20_bits_debug_isMMIO),
    .io_exuWriteback_20_bits_debug_isNCIO                       (io_exuWriteback_20_bits_debug_isNCIO),
    .io_exuWriteback_20_bits_debug_isPerfCnt                    (io_exuWriteback_20_bits_debug_isPerfCnt),
    .io_exuWriteback_20_bits_debug_paddr                        (io_exuWriteback_20_bits_debug_paddr),
    .io_exuWriteback_20_bits_debugInfo_enqRsTime                (io_exuWriteback_20_bits_debugInfo_enqRsTime),
    .io_exuWriteback_20_bits_debugInfo_selectTime               (io_exuWriteback_20_bits_debugInfo_selectTime),
    .io_exuWriteback_20_bits_debugInfo_issueTime                (io_exuWriteback_20_bits_debugInfo_issueTime),
    .io_exuWriteback_20_bits_debugInfo_writebackTime            (io_exuWriteback_20_bits_debugInfo_writebackTime),
    .io_exuWriteback_19_valid                                   (io_exuWriteback_19_valid),
    .io_exuWriteback_19_bits_data_0                             (io_exuWriteback_19_bits_data_0),
    .io_exuWriteback_19_bits_robIdx_value                       (io_exuWriteback_19_bits_robIdx_value),
    .io_exuWriteback_19_bits_sqIdx_value                        (io_exuWriteback_19_bits_sqIdx_value),
    .io_exuWriteback_19_bits_debug_isMMIO                       (io_exuWriteback_19_bits_debug_isMMIO),
    .io_exuWriteback_19_bits_debug_isNCIO                       (io_exuWriteback_19_bits_debug_isNCIO),
    .io_exuWriteback_19_bits_debug_isPerfCnt                    (io_exuWriteback_19_bits_debug_isPerfCnt),
    .io_exuWriteback_19_bits_debug_paddr                        (io_exuWriteback_19_bits_debug_paddr),
    .io_exuWriteback_19_bits_debugInfo_enqRsTime                (io_exuWriteback_19_bits_debugInfo_enqRsTime),
    .io_exuWriteback_19_bits_debugInfo_selectTime               (io_exuWriteback_19_bits_debugInfo_selectTime),
    .io_exuWriteback_19_bits_debugInfo_issueTime                (io_exuWriteback_19_bits_debugInfo_issueTime),
    .io_exuWriteback_19_bits_debugInfo_writebackTime            (io_exuWriteback_19_bits_debugInfo_writebackTime),
    .io_exuWriteback_18_valid                                   (io_exuWriteback_18_valid),
    .io_exuWriteback_18_bits_data_0                             (io_exuWriteback_18_bits_data_0),
    .io_exuWriteback_18_bits_robIdx_value                       (io_exuWriteback_18_bits_robIdx_value),
    .io_exuWriteback_18_bits_sqIdx_value                        (io_exuWriteback_18_bits_sqIdx_value),
    .io_exuWriteback_18_bits_debug_isMMIO                       (io_exuWriteback_18_bits_debug_isMMIO),
    .io_exuWriteback_18_bits_debug_isNCIO                       (io_exuWriteback_18_bits_debug_isNCIO),
    .io_exuWriteback_18_bits_debug_isPerfCnt                    (io_exuWriteback_18_bits_debug_isPerfCnt),
    .io_exuWriteback_18_bits_debug_paddr                        (io_exuWriteback_18_bits_debug_paddr),
    .io_exuWriteback_18_bits_debugInfo_enqRsTime                (io_exuWriteback_18_bits_debugInfo_enqRsTime),
    .io_exuWriteback_18_bits_debugInfo_selectTime               (io_exuWriteback_18_bits_debugInfo_selectTime),
    .io_exuWriteback_18_bits_debugInfo_issueTime                (io_exuWriteback_18_bits_debugInfo_issueTime),
    .io_exuWriteback_18_bits_debugInfo_writebackTime            (io_exuWriteback_18_bits_debugInfo_writebackTime),
    .io_exuWriteback_17_valid                                   (io_exuWriteback_17_valid),
    .io_exuWriteback_17_bits_data_0                             (io_exuWriteback_17_bits_data_0),
    .io_exuWriteback_17_bits_robIdx_value                       (io_exuWriteback_17_bits_robIdx_value),
    .io_exuWriteback_17_bits_fflags                             (io_exuWriteback_17_bits_fflags),
    .io_exuWriteback_17_bits_wflags                             (io_exuWriteback_17_bits_wflags),
    .io_exuWriteback_17_bits_debugInfo_enqRsTime                (io_exuWriteback_17_bits_debugInfo_enqRsTime),
    .io_exuWriteback_17_bits_debugInfo_selectTime               (io_exuWriteback_17_bits_debugInfo_selectTime),
    .io_exuWriteback_17_bits_debugInfo_issueTime                (io_exuWriteback_17_bits_debugInfo_issueTime),
    .io_exuWriteback_17_bits_debugInfo_writebackTime            (io_exuWriteback_17_bits_debugInfo_writebackTime),
    .io_exuWriteback_16_valid                                   (io_exuWriteback_16_valid),
    .io_exuWriteback_16_bits_data_0                             (io_exuWriteback_16_bits_data_0),
    .io_exuWriteback_16_bits_robIdx_value                       (io_exuWriteback_16_bits_robIdx_value),
    .io_exuWriteback_16_bits_fflags                             (io_exuWriteback_16_bits_fflags),
    .io_exuWriteback_16_bits_wflags                             (io_exuWriteback_16_bits_wflags),
    .io_exuWriteback_16_bits_debugInfo_enqRsTime                (io_exuWriteback_16_bits_debugInfo_enqRsTime),
    .io_exuWriteback_16_bits_debugInfo_selectTime               (io_exuWriteback_16_bits_debugInfo_selectTime),
    .io_exuWriteback_16_bits_debugInfo_issueTime                (io_exuWriteback_16_bits_debugInfo_issueTime),
    .io_exuWriteback_16_bits_debugInfo_writebackTime            (io_exuWriteback_16_bits_debugInfo_writebackTime),
    .io_exuWriteback_15_valid                                   (io_exuWriteback_15_valid),
    .io_exuWriteback_15_bits_data_0                             (io_exuWriteback_15_bits_data_0),
    .io_exuWriteback_15_bits_robIdx_value                       (io_exuWriteback_15_bits_robIdx_value),
    .io_exuWriteback_15_bits_fflags                             (io_exuWriteback_15_bits_fflags),
    .io_exuWriteback_15_bits_wflags                             (io_exuWriteback_15_bits_wflags),
    .io_exuWriteback_15_bits_vxsat                              (io_exuWriteback_15_bits_vxsat),
    .io_exuWriteback_15_bits_debugInfo_enqRsTime                (io_exuWriteback_15_bits_debugInfo_enqRsTime),
    .io_exuWriteback_15_bits_debugInfo_selectTime               (io_exuWriteback_15_bits_debugInfo_selectTime),
    .io_exuWriteback_15_bits_debugInfo_issueTime                (io_exuWriteback_15_bits_debugInfo_issueTime),
    .io_exuWriteback_15_bits_debugInfo_writebackTime            (io_exuWriteback_15_bits_debugInfo_writebackTime),
    .io_exuWriteback_14_valid                                   (io_exuWriteback_14_valid),
    .io_exuWriteback_14_bits_data_0                             (io_exuWriteback_14_bits_data_0),
    .io_exuWriteback_14_bits_robIdx_value                       (io_exuWriteback_14_bits_robIdx_value),
    .io_exuWriteback_14_bits_fflags                             (io_exuWriteback_14_bits_fflags),
    .io_exuWriteback_14_bits_wflags                             (io_exuWriteback_14_bits_wflags),
    .io_exuWriteback_14_bits_debugInfo_enqRsTime                (io_exuWriteback_14_bits_debugInfo_enqRsTime),
    .io_exuWriteback_14_bits_debugInfo_selectTime               (io_exuWriteback_14_bits_debugInfo_selectTime),
    .io_exuWriteback_14_bits_debugInfo_issueTime                (io_exuWriteback_14_bits_debugInfo_issueTime),
    .io_exuWriteback_14_bits_debugInfo_writebackTime            (io_exuWriteback_14_bits_debugInfo_writebackTime),
    .io_exuWriteback_13_valid                                   (io_exuWriteback_13_valid),
    .io_exuWriteback_13_bits_data_0                             (io_exuWriteback_13_bits_data_0),
    .io_exuWriteback_13_bits_robIdx_value                       (io_exuWriteback_13_bits_robIdx_value),
    .io_exuWriteback_13_bits_fflags                             (io_exuWriteback_13_bits_fflags),
    .io_exuWriteback_13_bits_wflags                             (io_exuWriteback_13_bits_wflags),
    .io_exuWriteback_13_bits_vxsat                              (io_exuWriteback_13_bits_vxsat),
    .io_exuWriteback_13_bits_debugInfo_enqRsTime                (io_exuWriteback_13_bits_debugInfo_enqRsTime),
    .io_exuWriteback_13_bits_debugInfo_selectTime               (io_exuWriteback_13_bits_debugInfo_selectTime),
    .io_exuWriteback_13_bits_debugInfo_issueTime                (io_exuWriteback_13_bits_debugInfo_issueTime),
    .io_exuWriteback_13_bits_debugInfo_writebackTime            (io_exuWriteback_13_bits_debugInfo_writebackTime),
    .io_exuWriteback_12_valid                                   (io_exuWriteback_12_valid),
    .io_exuWriteback_12_bits_data_0                             (io_exuWriteback_12_bits_data_0),
    .io_exuWriteback_12_bits_robIdx_value                       (io_exuWriteback_12_bits_robIdx_value),
    .io_exuWriteback_12_bits_fflags                             (io_exuWriteback_12_bits_fflags),
    .io_exuWriteback_12_bits_wflags                             (io_exuWriteback_12_bits_wflags),
    .io_exuWriteback_12_bits_debugInfo_enqRsTime                (io_exuWriteback_12_bits_debugInfo_enqRsTime),
    .io_exuWriteback_12_bits_debugInfo_selectTime               (io_exuWriteback_12_bits_debugInfo_selectTime),
    .io_exuWriteback_12_bits_debugInfo_issueTime                (io_exuWriteback_12_bits_debugInfo_issueTime),
    .io_exuWriteback_12_bits_debugInfo_writebackTime            (io_exuWriteback_12_bits_debugInfo_writebackTime),
    .io_exuWriteback_11_valid                                   (io_exuWriteback_11_valid),
    .io_exuWriteback_11_bits_data_0                             (io_exuWriteback_11_bits_data_0),
    .io_exuWriteback_11_bits_robIdx_value                       (io_exuWriteback_11_bits_robIdx_value),
    .io_exuWriteback_11_bits_fflags                             (io_exuWriteback_11_bits_fflags),
    .io_exuWriteback_11_bits_wflags                             (io_exuWriteback_11_bits_wflags),
    .io_exuWriteback_11_bits_debugInfo_enqRsTime                (io_exuWriteback_11_bits_debugInfo_enqRsTime),
    .io_exuWriteback_11_bits_debugInfo_selectTime               (io_exuWriteback_11_bits_debugInfo_selectTime),
    .io_exuWriteback_11_bits_debugInfo_issueTime                (io_exuWriteback_11_bits_debugInfo_issueTime),
    .io_exuWriteback_11_bits_debugInfo_writebackTime            (io_exuWriteback_11_bits_debugInfo_writebackTime),
    .io_exuWriteback_10_valid                                   (io_exuWriteback_10_valid),
    .io_exuWriteback_10_bits_data_0                             (io_exuWriteback_10_bits_data_0),
    .io_exuWriteback_10_bits_robIdx_value                       (io_exuWriteback_10_bits_robIdx_value),
    .io_exuWriteback_10_bits_fflags                             (io_exuWriteback_10_bits_fflags),
    .io_exuWriteback_10_bits_wflags                             (io_exuWriteback_10_bits_wflags),
    .io_exuWriteback_10_bits_debugInfo_enqRsTime                (io_exuWriteback_10_bits_debugInfo_enqRsTime),
    .io_exuWriteback_10_bits_debugInfo_selectTime               (io_exuWriteback_10_bits_debugInfo_selectTime),
    .io_exuWriteback_10_bits_debugInfo_issueTime                (io_exuWriteback_10_bits_debugInfo_issueTime),
    .io_exuWriteback_10_bits_debugInfo_writebackTime            (io_exuWriteback_10_bits_debugInfo_writebackTime),
    .io_exuWriteback_9_valid                                    (io_exuWriteback_9_valid),
    .io_exuWriteback_9_bits_data_0                              (io_exuWriteback_9_bits_data_0),
    .io_exuWriteback_9_bits_robIdx_value                        (io_exuWriteback_9_bits_robIdx_value),
    .io_exuWriteback_9_bits_fflags                              (io_exuWriteback_9_bits_fflags),
    .io_exuWriteback_9_bits_wflags                              (io_exuWriteback_9_bits_wflags),
    .io_exuWriteback_9_bits_debugInfo_enqRsTime                 (io_exuWriteback_9_bits_debugInfo_enqRsTime),
    .io_exuWriteback_9_bits_debugInfo_selectTime                (io_exuWriteback_9_bits_debugInfo_selectTime),
    .io_exuWriteback_9_bits_debugInfo_issueTime                 (io_exuWriteback_9_bits_debugInfo_issueTime),
    .io_exuWriteback_9_bits_debugInfo_writebackTime             (io_exuWriteback_9_bits_debugInfo_writebackTime),
    .io_exuWriteback_8_valid                                    (io_exuWriteback_8_valid),
    .io_exuWriteback_8_bits_data_0                              (io_exuWriteback_8_bits_data_0),
    .io_exuWriteback_8_bits_robIdx_value                        (io_exuWriteback_8_bits_robIdx_value),
    .io_exuWriteback_8_bits_fflags                              (io_exuWriteback_8_bits_fflags),
    .io_exuWriteback_8_bits_wflags                              (io_exuWriteback_8_bits_wflags),
    .io_exuWriteback_8_bits_debugInfo_enqRsTime                 (io_exuWriteback_8_bits_debugInfo_enqRsTime),
    .io_exuWriteback_8_bits_debugInfo_selectTime                (io_exuWriteback_8_bits_debugInfo_selectTime),
    .io_exuWriteback_8_bits_debugInfo_issueTime                 (io_exuWriteback_8_bits_debugInfo_issueTime),
    .io_exuWriteback_8_bits_debugInfo_writebackTime             (io_exuWriteback_8_bits_debugInfo_writebackTime),
    .io_exuWriteback_7_valid                                    (io_exuWriteback_7_valid),
    .io_exuWriteback_7_bits_data_0                              (io_exuWriteback_7_bits_data_0),
    .io_exuWriteback_7_bits_robIdx_value                        (io_exuWriteback_7_bits_robIdx_value),
    .io_exuWriteback_7_bits_debug_isPerfCnt                     (io_exuWriteback_7_bits_debug_isPerfCnt),
    .io_exuWriteback_7_bits_debugInfo_enqRsTime                 (io_exuWriteback_7_bits_debugInfo_enqRsTime),
    .io_exuWriteback_7_bits_debugInfo_selectTime                (io_exuWriteback_7_bits_debugInfo_selectTime),
    .io_exuWriteback_7_bits_debugInfo_issueTime                 (io_exuWriteback_7_bits_debugInfo_issueTime),
    .io_exuWriteback_7_bits_debugInfo_writebackTime             (io_exuWriteback_7_bits_debugInfo_writebackTime),
    .io_exuWriteback_6_valid                                    (io_exuWriteback_6_valid),
    .io_exuWriteback_6_bits_data_0                              (io_exuWriteback_6_bits_data_0),
    .io_exuWriteback_6_bits_robIdx_value                        (io_exuWriteback_6_bits_robIdx_value),
    .io_exuWriteback_6_bits_debugInfo_enqRsTime                 (io_exuWriteback_6_bits_debugInfo_enqRsTime),
    .io_exuWriteback_6_bits_debugInfo_selectTime                (io_exuWriteback_6_bits_debugInfo_selectTime),
    .io_exuWriteback_6_bits_debugInfo_issueTime                 (io_exuWriteback_6_bits_debugInfo_issueTime),
    .io_exuWriteback_6_bits_debugInfo_writebackTime             (io_exuWriteback_6_bits_debugInfo_writebackTime),
    .io_exuWriteback_5_valid                                    (io_exuWriteback_5_valid),
    .io_exuWriteback_5_bits_data_0                              (io_exuWriteback_5_bits_data_0),
    .io_exuWriteback_5_bits_robIdx_value                        (io_exuWriteback_5_bits_robIdx_value),
    .io_exuWriteback_5_bits_redirect_bits_cfiUpdate_taken       (io_exuWriteback_5_bits_redirect_bits_cfiUpdate_taken),
    .io_exuWriteback_5_bits_fflags                              (io_exuWriteback_5_bits_fflags),
    .io_exuWriteback_5_bits_wflags                              (io_exuWriteback_5_bits_wflags),
    .io_exuWriteback_5_bits_debugInfo_enqRsTime                 (io_exuWriteback_5_bits_debugInfo_enqRsTime),
    .io_exuWriteback_5_bits_debugInfo_selectTime                (io_exuWriteback_5_bits_debugInfo_selectTime),
    .io_exuWriteback_5_bits_debugInfo_issueTime                 (io_exuWriteback_5_bits_debugInfo_issueTime),
    .io_exuWriteback_5_bits_debugInfo_writebackTime             (io_exuWriteback_5_bits_debugInfo_writebackTime),
    .io_exuWriteback_4_valid                                    (io_exuWriteback_4_valid),
    .io_exuWriteback_4_bits_data_0                              (io_exuWriteback_4_bits_data_0),
    .io_exuWriteback_4_bits_robIdx_value                        (io_exuWriteback_4_bits_robIdx_value),
    .io_exuWriteback_4_bits_debugInfo_enqRsTime                 (io_exuWriteback_4_bits_debugInfo_enqRsTime),
    .io_exuWriteback_4_bits_debugInfo_selectTime                (io_exuWriteback_4_bits_debugInfo_selectTime),
    .io_exuWriteback_4_bits_debugInfo_issueTime                 (io_exuWriteback_4_bits_debugInfo_issueTime),
    .io_exuWriteback_4_bits_debugInfo_writebackTime             (io_exuWriteback_4_bits_debugInfo_writebackTime),
    .io_exuWriteback_3_valid                                    (io_exuWriteback_3_valid),
    .io_exuWriteback_3_bits_data_0                              (io_exuWriteback_3_bits_data_0),
    .io_exuWriteback_3_bits_robIdx_value                        (io_exuWriteback_3_bits_robIdx_value),
    .io_exuWriteback_3_bits_redirect_bits_cfiUpdate_taken       (io_exuWriteback_3_bits_redirect_bits_cfiUpdate_taken),
    .io_exuWriteback_3_bits_debugInfo_enqRsTime                 (io_exuWriteback_3_bits_debugInfo_enqRsTime),
    .io_exuWriteback_3_bits_debugInfo_selectTime                (io_exuWriteback_3_bits_debugInfo_selectTime),
    .io_exuWriteback_3_bits_debugInfo_issueTime                 (io_exuWriteback_3_bits_debugInfo_issueTime),
    .io_exuWriteback_3_bits_debugInfo_writebackTime             (io_exuWriteback_3_bits_debugInfo_writebackTime),
    .io_exuWriteback_2_valid                                    (io_exuWriteback_2_valid),
    .io_exuWriteback_2_bits_data_0                              (io_exuWriteback_2_bits_data_0),
    .io_exuWriteback_2_bits_robIdx_value                        (io_exuWriteback_2_bits_robIdx_value),
    .io_exuWriteback_2_bits_debugInfo_enqRsTime                 (io_exuWriteback_2_bits_debugInfo_enqRsTime),
    .io_exuWriteback_2_bits_debugInfo_selectTime                (io_exuWriteback_2_bits_debugInfo_selectTime),
    .io_exuWriteback_2_bits_debugInfo_issueTime                 (io_exuWriteback_2_bits_debugInfo_issueTime),
    .io_exuWriteback_2_bits_debugInfo_writebackTime             (io_exuWriteback_2_bits_debugInfo_writebackTime),
    .io_exuWriteback_1_valid                                    (io_exuWriteback_1_valid),
    .io_exuWriteback_1_bits_data_0                              (io_exuWriteback_1_bits_data_0),
    .io_exuWriteback_1_bits_robIdx_value                        (io_exuWriteback_1_bits_robIdx_value),
    .io_exuWriteback_1_bits_redirect_bits_cfiUpdate_taken       (io_exuWriteback_1_bits_redirect_bits_cfiUpdate_taken),
    .io_exuWriteback_1_bits_debugInfo_enqRsTime                 (io_exuWriteback_1_bits_debugInfo_enqRsTime),
    .io_exuWriteback_1_bits_debugInfo_selectTime                (io_exuWriteback_1_bits_debugInfo_selectTime),
    .io_exuWriteback_1_bits_debugInfo_issueTime                 (io_exuWriteback_1_bits_debugInfo_issueTime),
    .io_exuWriteback_1_bits_debugInfo_writebackTime             (io_exuWriteback_1_bits_debugInfo_writebackTime),
    .io_exuWriteback_0_valid                                    (io_exuWriteback_0_valid),
    .io_exuWriteback_0_bits_data_0                              (io_exuWriteback_0_bits_data_0),
    .io_exuWriteback_0_bits_robIdx_value                        (io_exuWriteback_0_bits_robIdx_value),
    .io_exuWriteback_0_bits_debugInfo_enqRsTime                 (io_exuWriteback_0_bits_debugInfo_enqRsTime),
    .io_exuWriteback_0_bits_debugInfo_selectTime                (io_exuWriteback_0_bits_debugInfo_selectTime),
    .io_exuWriteback_0_bits_debugInfo_issueTime                 (io_exuWriteback_0_bits_debugInfo_issueTime),
    .io_exuWriteback_0_bits_debugInfo_writebackTime             (io_exuWriteback_0_bits_debugInfo_writebackTime),
    .io_writebackNums_0_bits                                    (io_writebackNums_0_bits),
    .io_writebackNums_1_bits                                    (io_writebackNums_1_bits),
    .io_writebackNums_2_bits                                    (io_writebackNums_2_bits),
    .io_writebackNums_3_bits                                    (io_writebackNums_3_bits),
    .io_writebackNums_4_bits                                    (io_writebackNums_4_bits),
    .io_writebackNums_5_bits                                    (io_writebackNums_5_bits),
    .io_writebackNums_6_bits                                    (io_writebackNums_6_bits),
    .io_writebackNums_7_bits                                    (io_writebackNums_7_bits),
    .io_writebackNums_8_bits                                    (io_writebackNums_8_bits),
    .io_writebackNums_9_bits                                    (io_writebackNums_9_bits),
    .io_writebackNums_10_bits                                   (io_writebackNums_10_bits),
    .io_writebackNums_11_bits                                   (io_writebackNums_11_bits),
    .io_writebackNums_12_bits                                   (io_writebackNums_12_bits),
    .io_writebackNums_13_bits                                   (io_writebackNums_13_bits),
    .io_writebackNums_14_bits                                   (io_writebackNums_14_bits),
    .io_writebackNums_15_bits                                   (io_writebackNums_15_bits),
    .io_writebackNums_16_bits                                   (io_writebackNums_16_bits),
    .io_writebackNums_17_bits                                   (io_writebackNums_17_bits),
    .io_writebackNums_18_bits                                   (io_writebackNums_18_bits),
    .io_writebackNums_19_bits                                   (io_writebackNums_19_bits),
    .io_writebackNums_20_bits                                   (io_writebackNums_20_bits),
    .io_writebackNums_21_bits                                   (io_writebackNums_21_bits),
    .io_writebackNums_22_bits                                   (io_writebackNums_22_bits),
    .io_writebackNums_23_bits                                   (io_writebackNums_23_bits),
    .io_writebackNums_24_bits                                   (io_writebackNums_24_bits),
    .io_writebackNeedFlush_0                                    (io_writebackNeedFlush_0),
    .io_writebackNeedFlush_1                                    (io_writebackNeedFlush_1),
    .io_writebackNeedFlush_2                                    (io_writebackNeedFlush_2),
    .io_writebackNeedFlush_6                                    (io_writebackNeedFlush_6),
    .io_writebackNeedFlush_7                                    (io_writebackNeedFlush_7),
    .io_writebackNeedFlush_8                                    (io_writebackNeedFlush_8),
    .io_writebackNeedFlush_9                                    (io_writebackNeedFlush_9),
    .io_writebackNeedFlush_10                                   (io_writebackNeedFlush_10),
    .io_writebackNeedFlush_11                                   (io_writebackNeedFlush_11),
    .io_writebackNeedFlush_12                                   (io_writebackNeedFlush_12),
    .io_commits_isCommit                                        (io_commits_isCommit),
    .io_commits_commitValid_0                                   (io_commits_commitValid_0),
    .io_commits_commitValid_1                                   (io_commits_commitValid_1),
    .io_commits_commitValid_2                                   (io_commits_commitValid_2),
    .io_commits_commitValid_3                                   (io_commits_commitValid_3),
    .io_commits_commitValid_4                                   (io_commits_commitValid_4),
    .io_commits_commitValid_5                                   (io_commits_commitValid_5),
    .io_commits_commitValid_6                                   (io_commits_commitValid_6),
    .io_commits_commitValid_7                                   (io_commits_commitValid_7),
    .io_commits_isWalk                                          (io_commits_isWalk),
    .io_commits_walkValid_0                                     (io_commits_walkValid_0),
    .io_commits_walkValid_1                                     (io_commits_walkValid_1),
    .io_commits_walkValid_2                                     (io_commits_walkValid_2),
    .io_commits_walkValid_3                                     (io_commits_walkValid_3),
    .io_commits_walkValid_4                                     (io_commits_walkValid_4),
    .io_commits_walkValid_5                                     (io_commits_walkValid_5),
    .io_commits_walkValid_6                                     (io_commits_walkValid_6),
    .io_commits_walkValid_7                                     (io_commits_walkValid_7),
    .io_commits_info_0_walk_v                                   (io_commits_info_0_walk_v),
    .io_commits_info_0_commit_v                                 (io_commits_info_0_commit_v),
    .io_commits_info_0_commit_w                                 (io_commits_info_0_commit_w),
    .io_commits_info_0_realDestSize                             (io_commits_info_0_realDestSize),
    .io_commits_info_0_interrupt_safe                           (io_commits_info_0_interrupt_safe),
    .io_commits_info_0_wflags                                   (io_commits_info_0_wflags),
    .io_commits_info_0_fflags                                   (io_commits_info_0_fflags),
    .io_commits_info_0_vxsat                                    (io_commits_info_0_vxsat),
    .io_commits_info_0_isRVC                                    (io_commits_info_0_isRVC),
    .io_commits_info_0_isVset                                   (io_commits_info_0_isVset),
    .io_commits_info_0_isHls                                    (io_commits_info_0_isHls),
    .io_commits_info_0_isVls                                    (io_commits_info_0_isVls),
    .io_commits_info_0_vls                                      (io_commits_info_0_vls),
    .io_commits_info_0_mmio                                     (io_commits_info_0_mmio),
    .io_commits_info_0_commitType                               (io_commits_info_0_commitType),
    .io_commits_info_0_ftqIdx_flag                              (io_commits_info_0_ftqIdx_flag),
    .io_commits_info_0_ftqIdx_value                             (io_commits_info_0_ftqIdx_value),
    .io_commits_info_0_ftqOffset                                (io_commits_info_0_ftqOffset),
    .io_commits_info_0_instrSize                                (io_commits_info_0_instrSize),
    .io_commits_info_0_fpWen                                    (io_commits_info_0_fpWen),
    .io_commits_info_0_rfWen                                    (io_commits_info_0_rfWen),
    .io_commits_info_0_needFlush                                (io_commits_info_0_needFlush),
    .io_commits_info_0_traceBlockInPipe_itype                   (io_commits_info_0_traceBlockInPipe_itype),
    .io_commits_info_0_traceBlockInPipe_iretire                 (io_commits_info_0_traceBlockInPipe_iretire),
    .io_commits_info_0_traceBlockInPipe_ilastsize               (io_commits_info_0_traceBlockInPipe_ilastsize),
    .io_commits_info_0_debug_pc                                 (io_commits_info_0_debug_pc),
    .io_commits_info_0_debug_instr                              (io_commits_info_0_debug_instr),
    .io_commits_info_0_basicDebug_ldest                         (io_commits_info_0_basicDebug_ldest),
    .io_commits_info_0_basicDebug_pdest                         (io_commits_info_0_basicDebug_pdest),
    .io_commits_info_0_basicDebug_vd                            (io_commits_info_0_basicDebug_vd),
    .io_commits_info_0_basicDebug_fpWen                         (io_commits_info_0_basicDebug_fpWen),
    .io_commits_info_0_basicDebug_vecWen                        (io_commits_info_0_basicDebug_vecWen),
    .io_commits_info_0_basicDebug_v0Wen                         (io_commits_info_0_basicDebug_v0Wen),
    .io_commits_info_0_basicDebug_eliminatedMove                (io_commits_info_0_basicDebug_eliminatedMove),
    .io_commits_info_0_basicDebug_isXSTrap                      (io_commits_info_0_basicDebug_isXSTrap),
    .io_commits_info_0_debug_otherPdest_0                       (io_commits_info_0_debug_otherPdest_0),
    .io_commits_info_0_debug_otherPdest_1                       (io_commits_info_0_debug_otherPdest_1),
    .io_commits_info_0_debug_otherPdest_2                       (io_commits_info_0_debug_otherPdest_2),
    .io_commits_info_0_debug_otherPdest_3                       (io_commits_info_0_debug_otherPdest_3),
    .io_commits_info_0_debug_otherPdest_4                       (io_commits_info_0_debug_otherPdest_4),
    .io_commits_info_0_debug_otherPdest_5                       (io_commits_info_0_debug_otherPdest_5),
    .io_commits_info_0_debug_otherPdest_6                       (io_commits_info_0_debug_otherPdest_6),
    .io_commits_info_0_debug_fuType                             (io_commits_info_0_debug_fuType),
    .io_commits_info_0_dirtyFs                                  (io_commits_info_0_dirtyFs),
    .io_commits_info_0_dirtyVs                                  (io_commits_info_0_dirtyVs),
    .io_commits_info_1_walk_v                                   (io_commits_info_1_walk_v),
    .io_commits_info_1_commit_v                                 (io_commits_info_1_commit_v),
    .io_commits_info_1_commit_w                                 (io_commits_info_1_commit_w),
    .io_commits_info_1_realDestSize                             (io_commits_info_1_realDestSize),
    .io_commits_info_1_interrupt_safe                           (io_commits_info_1_interrupt_safe),
    .io_commits_info_1_wflags                                   (io_commits_info_1_wflags),
    .io_commits_info_1_fflags                                   (io_commits_info_1_fflags),
    .io_commits_info_1_vxsat                                    (io_commits_info_1_vxsat),
    .io_commits_info_1_isRVC                                    (io_commits_info_1_isRVC),
    .io_commits_info_1_isVset                                   (io_commits_info_1_isVset),
    .io_commits_info_1_isHls                                    (io_commits_info_1_isHls),
    .io_commits_info_1_isVls                                    (io_commits_info_1_isVls),
    .io_commits_info_1_vls                                      (io_commits_info_1_vls),
    .io_commits_info_1_mmio                                     (io_commits_info_1_mmio),
    .io_commits_info_1_commitType                               (io_commits_info_1_commitType),
    .io_commits_info_1_ftqIdx_flag                              (io_commits_info_1_ftqIdx_flag),
    .io_commits_info_1_ftqIdx_value                             (io_commits_info_1_ftqIdx_value),
    .io_commits_info_1_ftqOffset                                (io_commits_info_1_ftqOffset),
    .io_commits_info_1_instrSize                                (io_commits_info_1_instrSize),
    .io_commits_info_1_fpWen                                    (io_commits_info_1_fpWen),
    .io_commits_info_1_rfWen                                    (io_commits_info_1_rfWen),
    .io_commits_info_1_needFlush                                (io_commits_info_1_needFlush),
    .io_commits_info_1_traceBlockInPipe_itype                   (io_commits_info_1_traceBlockInPipe_itype),
    .io_commits_info_1_traceBlockInPipe_iretire                 (io_commits_info_1_traceBlockInPipe_iretire),
    .io_commits_info_1_traceBlockInPipe_ilastsize               (io_commits_info_1_traceBlockInPipe_ilastsize),
    .io_commits_info_1_debug_pc                                 (io_commits_info_1_debug_pc),
    .io_commits_info_1_debug_instr                              (io_commits_info_1_debug_instr),
    .io_commits_info_1_basicDebug_ldest                         (io_commits_info_1_basicDebug_ldest),
    .io_commits_info_1_basicDebug_pdest                         (io_commits_info_1_basicDebug_pdest),
    .io_commits_info_1_basicDebug_vd                            (io_commits_info_1_basicDebug_vd),
    .io_commits_info_1_basicDebug_fpWen                         (io_commits_info_1_basicDebug_fpWen),
    .io_commits_info_1_basicDebug_vecWen                        (io_commits_info_1_basicDebug_vecWen),
    .io_commits_info_1_basicDebug_v0Wen                         (io_commits_info_1_basicDebug_v0Wen),
    .io_commits_info_1_basicDebug_eliminatedMove                (io_commits_info_1_basicDebug_eliminatedMove),
    .io_commits_info_1_basicDebug_isXSTrap                      (io_commits_info_1_basicDebug_isXSTrap),
    .io_commits_info_1_debug_otherPdest_0                       (io_commits_info_1_debug_otherPdest_0),
    .io_commits_info_1_debug_otherPdest_1                       (io_commits_info_1_debug_otherPdest_1),
    .io_commits_info_1_debug_otherPdest_2                       (io_commits_info_1_debug_otherPdest_2),
    .io_commits_info_1_debug_otherPdest_3                       (io_commits_info_1_debug_otherPdest_3),
    .io_commits_info_1_debug_otherPdest_4                       (io_commits_info_1_debug_otherPdest_4),
    .io_commits_info_1_debug_otherPdest_5                       (io_commits_info_1_debug_otherPdest_5),
    .io_commits_info_1_debug_otherPdest_6                       (io_commits_info_1_debug_otherPdest_6),
    .io_commits_info_1_debug_fuType                             (io_commits_info_1_debug_fuType),
    .io_commits_info_1_dirtyFs                                  (io_commits_info_1_dirtyFs),
    .io_commits_info_1_dirtyVs                                  (io_commits_info_1_dirtyVs),
    .io_commits_info_2_walk_v                                   (io_commits_info_2_walk_v),
    .io_commits_info_2_commit_v                                 (io_commits_info_2_commit_v),
    .io_commits_info_2_commit_w                                 (io_commits_info_2_commit_w),
    .io_commits_info_2_realDestSize                             (io_commits_info_2_realDestSize),
    .io_commits_info_2_interrupt_safe                           (io_commits_info_2_interrupt_safe),
    .io_commits_info_2_wflags                                   (io_commits_info_2_wflags),
    .io_commits_info_2_fflags                                   (io_commits_info_2_fflags),
    .io_commits_info_2_vxsat                                    (io_commits_info_2_vxsat),
    .io_commits_info_2_isRVC                                    (io_commits_info_2_isRVC),
    .io_commits_info_2_isVset                                   (io_commits_info_2_isVset),
    .io_commits_info_2_isHls                                    (io_commits_info_2_isHls),
    .io_commits_info_2_isVls                                    (io_commits_info_2_isVls),
    .io_commits_info_2_vls                                      (io_commits_info_2_vls),
    .io_commits_info_2_mmio                                     (io_commits_info_2_mmio),
    .io_commits_info_2_commitType                               (io_commits_info_2_commitType),
    .io_commits_info_2_ftqIdx_flag                              (io_commits_info_2_ftqIdx_flag),
    .io_commits_info_2_ftqIdx_value                             (io_commits_info_2_ftqIdx_value),
    .io_commits_info_2_ftqOffset                                (io_commits_info_2_ftqOffset),
    .io_commits_info_2_instrSize                                (io_commits_info_2_instrSize),
    .io_commits_info_2_fpWen                                    (io_commits_info_2_fpWen),
    .io_commits_info_2_rfWen                                    (io_commits_info_2_rfWen),
    .io_commits_info_2_needFlush                                (io_commits_info_2_needFlush),
    .io_commits_info_2_traceBlockInPipe_itype                   (io_commits_info_2_traceBlockInPipe_itype),
    .io_commits_info_2_traceBlockInPipe_iretire                 (io_commits_info_2_traceBlockInPipe_iretire),
    .io_commits_info_2_traceBlockInPipe_ilastsize               (io_commits_info_2_traceBlockInPipe_ilastsize),
    .io_commits_info_2_debug_pc                                 (io_commits_info_2_debug_pc),
    .io_commits_info_2_debug_instr                              (io_commits_info_2_debug_instr),
    .io_commits_info_2_basicDebug_ldest                         (io_commits_info_2_basicDebug_ldest),
    .io_commits_info_2_basicDebug_pdest                         (io_commits_info_2_basicDebug_pdest),
    .io_commits_info_2_basicDebug_vd                            (io_commits_info_2_basicDebug_vd),
    .io_commits_info_2_basicDebug_fpWen                         (io_commits_info_2_basicDebug_fpWen),
    .io_commits_info_2_basicDebug_vecWen                        (io_commits_info_2_basicDebug_vecWen),
    .io_commits_info_2_basicDebug_v0Wen                         (io_commits_info_2_basicDebug_v0Wen),
    .io_commits_info_2_basicDebug_eliminatedMove                (io_commits_info_2_basicDebug_eliminatedMove),
    .io_commits_info_2_basicDebug_isXSTrap                      (io_commits_info_2_basicDebug_isXSTrap),
    .io_commits_info_2_debug_otherPdest_0                       (io_commits_info_2_debug_otherPdest_0),
    .io_commits_info_2_debug_otherPdest_1                       (io_commits_info_2_debug_otherPdest_1),
    .io_commits_info_2_debug_otherPdest_2                       (io_commits_info_2_debug_otherPdest_2),
    .io_commits_info_2_debug_otherPdest_3                       (io_commits_info_2_debug_otherPdest_3),
    .io_commits_info_2_debug_otherPdest_4                       (io_commits_info_2_debug_otherPdest_4),
    .io_commits_info_2_debug_otherPdest_5                       (io_commits_info_2_debug_otherPdest_5),
    .io_commits_info_2_debug_otherPdest_6                       (io_commits_info_2_debug_otherPdest_6),
    .io_commits_info_2_debug_fuType                             (io_commits_info_2_debug_fuType),
    .io_commits_info_2_dirtyFs                                  (io_commits_info_2_dirtyFs),
    .io_commits_info_2_dirtyVs                                  (io_commits_info_2_dirtyVs),
    .io_commits_info_3_walk_v                                   (io_commits_info_3_walk_v),
    .io_commits_info_3_commit_v                                 (io_commits_info_3_commit_v),
    .io_commits_info_3_commit_w                                 (io_commits_info_3_commit_w),
    .io_commits_info_3_realDestSize                             (io_commits_info_3_realDestSize),
    .io_commits_info_3_interrupt_safe                           (io_commits_info_3_interrupt_safe),
    .io_commits_info_3_wflags                                   (io_commits_info_3_wflags),
    .io_commits_info_3_fflags                                   (io_commits_info_3_fflags),
    .io_commits_info_3_vxsat                                    (io_commits_info_3_vxsat),
    .io_commits_info_3_isRVC                                    (io_commits_info_3_isRVC),
    .io_commits_info_3_isVset                                   (io_commits_info_3_isVset),
    .io_commits_info_3_isHls                                    (io_commits_info_3_isHls),
    .io_commits_info_3_isVls                                    (io_commits_info_3_isVls),
    .io_commits_info_3_vls                                      (io_commits_info_3_vls),
    .io_commits_info_3_mmio                                     (io_commits_info_3_mmio),
    .io_commits_info_3_commitType                               (io_commits_info_3_commitType),
    .io_commits_info_3_ftqIdx_flag                              (io_commits_info_3_ftqIdx_flag),
    .io_commits_info_3_ftqIdx_value                             (io_commits_info_3_ftqIdx_value),
    .io_commits_info_3_ftqOffset                                (io_commits_info_3_ftqOffset),
    .io_commits_info_3_instrSize                                (io_commits_info_3_instrSize),
    .io_commits_info_3_fpWen                                    (io_commits_info_3_fpWen),
    .io_commits_info_3_rfWen                                    (io_commits_info_3_rfWen),
    .io_commits_info_3_needFlush                                (io_commits_info_3_needFlush),
    .io_commits_info_3_traceBlockInPipe_itype                   (io_commits_info_3_traceBlockInPipe_itype),
    .io_commits_info_3_traceBlockInPipe_iretire                 (io_commits_info_3_traceBlockInPipe_iretire),
    .io_commits_info_3_traceBlockInPipe_ilastsize               (io_commits_info_3_traceBlockInPipe_ilastsize),
    .io_commits_info_3_debug_pc                                 (io_commits_info_3_debug_pc),
    .io_commits_info_3_debug_instr                              (io_commits_info_3_debug_instr),
    .io_commits_info_3_basicDebug_ldest                         (io_commits_info_3_basicDebug_ldest),
    .io_commits_info_3_basicDebug_pdest                         (io_commits_info_3_basicDebug_pdest),
    .io_commits_info_3_basicDebug_vd                            (io_commits_info_3_basicDebug_vd),
    .io_commits_info_3_basicDebug_fpWen                         (io_commits_info_3_basicDebug_fpWen),
    .io_commits_info_3_basicDebug_vecWen                        (io_commits_info_3_basicDebug_vecWen),
    .io_commits_info_3_basicDebug_v0Wen                         (io_commits_info_3_basicDebug_v0Wen),
    .io_commits_info_3_basicDebug_eliminatedMove                (io_commits_info_3_basicDebug_eliminatedMove),
    .io_commits_info_3_basicDebug_isXSTrap                      (io_commits_info_3_basicDebug_isXSTrap),
    .io_commits_info_3_debug_otherPdest_0                       (io_commits_info_3_debug_otherPdest_0),
    .io_commits_info_3_debug_otherPdest_1                       (io_commits_info_3_debug_otherPdest_1),
    .io_commits_info_3_debug_otherPdest_2                       (io_commits_info_3_debug_otherPdest_2),
    .io_commits_info_3_debug_otherPdest_3                       (io_commits_info_3_debug_otherPdest_3),
    .io_commits_info_3_debug_otherPdest_4                       (io_commits_info_3_debug_otherPdest_4),
    .io_commits_info_3_debug_otherPdest_5                       (io_commits_info_3_debug_otherPdest_5),
    .io_commits_info_3_debug_otherPdest_6                       (io_commits_info_3_debug_otherPdest_6),
    .io_commits_info_3_debug_fuType                             (io_commits_info_3_debug_fuType),
    .io_commits_info_3_dirtyFs                                  (io_commits_info_3_dirtyFs),
    .io_commits_info_3_dirtyVs                                  (io_commits_info_3_dirtyVs),
    .io_commits_info_4_walk_v                                   (io_commits_info_4_walk_v),
    .io_commits_info_4_commit_v                                 (io_commits_info_4_commit_v),
    .io_commits_info_4_commit_w                                 (io_commits_info_4_commit_w),
    .io_commits_info_4_realDestSize                             (io_commits_info_4_realDestSize),
    .io_commits_info_4_interrupt_safe                           (io_commits_info_4_interrupt_safe),
    .io_commits_info_4_wflags                                   (io_commits_info_4_wflags),
    .io_commits_info_4_fflags                                   (io_commits_info_4_fflags),
    .io_commits_info_4_vxsat                                    (io_commits_info_4_vxsat),
    .io_commits_info_4_isRVC                                    (io_commits_info_4_isRVC),
    .io_commits_info_4_isVset                                   (io_commits_info_4_isVset),
    .io_commits_info_4_isHls                                    (io_commits_info_4_isHls),
    .io_commits_info_4_isVls                                    (io_commits_info_4_isVls),
    .io_commits_info_4_vls                                      (io_commits_info_4_vls),
    .io_commits_info_4_mmio                                     (io_commits_info_4_mmio),
    .io_commits_info_4_commitType                               (io_commits_info_4_commitType),
    .io_commits_info_4_ftqIdx_flag                              (io_commits_info_4_ftqIdx_flag),
    .io_commits_info_4_ftqIdx_value                             (io_commits_info_4_ftqIdx_value),
    .io_commits_info_4_ftqOffset                                (io_commits_info_4_ftqOffset),
    .io_commits_info_4_instrSize                                (io_commits_info_4_instrSize),
    .io_commits_info_4_fpWen                                    (io_commits_info_4_fpWen),
    .io_commits_info_4_rfWen                                    (io_commits_info_4_rfWen),
    .io_commits_info_4_needFlush                                (io_commits_info_4_needFlush),
    .io_commits_info_4_traceBlockInPipe_itype                   (io_commits_info_4_traceBlockInPipe_itype),
    .io_commits_info_4_traceBlockInPipe_iretire                 (io_commits_info_4_traceBlockInPipe_iretire),
    .io_commits_info_4_traceBlockInPipe_ilastsize               (io_commits_info_4_traceBlockInPipe_ilastsize),
    .io_commits_info_4_debug_pc                                 (io_commits_info_4_debug_pc),
    .io_commits_info_4_debug_instr                              (io_commits_info_4_debug_instr),
    .io_commits_info_4_basicDebug_ldest                         (io_commits_info_4_basicDebug_ldest),
    .io_commits_info_4_basicDebug_pdest                         (io_commits_info_4_basicDebug_pdest),
    .io_commits_info_4_basicDebug_vd                            (io_commits_info_4_basicDebug_vd),
    .io_commits_info_4_basicDebug_fpWen                         (io_commits_info_4_basicDebug_fpWen),
    .io_commits_info_4_basicDebug_vecWen                        (io_commits_info_4_basicDebug_vecWen),
    .io_commits_info_4_basicDebug_v0Wen                         (io_commits_info_4_basicDebug_v0Wen),
    .io_commits_info_4_basicDebug_eliminatedMove                (io_commits_info_4_basicDebug_eliminatedMove),
    .io_commits_info_4_basicDebug_isXSTrap                      (io_commits_info_4_basicDebug_isXSTrap),
    .io_commits_info_4_debug_otherPdest_0                       (io_commits_info_4_debug_otherPdest_0),
    .io_commits_info_4_debug_otherPdest_1                       (io_commits_info_4_debug_otherPdest_1),
    .io_commits_info_4_debug_otherPdest_2                       (io_commits_info_4_debug_otherPdest_2),
    .io_commits_info_4_debug_otherPdest_3                       (io_commits_info_4_debug_otherPdest_3),
    .io_commits_info_4_debug_otherPdest_4                       (io_commits_info_4_debug_otherPdest_4),
    .io_commits_info_4_debug_otherPdest_5                       (io_commits_info_4_debug_otherPdest_5),
    .io_commits_info_4_debug_otherPdest_6                       (io_commits_info_4_debug_otherPdest_6),
    .io_commits_info_4_debug_fuType                             (io_commits_info_4_debug_fuType),
    .io_commits_info_4_dirtyFs                                  (io_commits_info_4_dirtyFs),
    .io_commits_info_4_dirtyVs                                  (io_commits_info_4_dirtyVs),
    .io_commits_info_5_walk_v                                   (io_commits_info_5_walk_v),
    .io_commits_info_5_commit_v                                 (io_commits_info_5_commit_v),
    .io_commits_info_5_commit_w                                 (io_commits_info_5_commit_w),
    .io_commits_info_5_realDestSize                             (io_commits_info_5_realDestSize),
    .io_commits_info_5_interrupt_safe                           (io_commits_info_5_interrupt_safe),
    .io_commits_info_5_wflags                                   (io_commits_info_5_wflags),
    .io_commits_info_5_fflags                                   (io_commits_info_5_fflags),
    .io_commits_info_5_vxsat                                    (io_commits_info_5_vxsat),
    .io_commits_info_5_isRVC                                    (io_commits_info_5_isRVC),
    .io_commits_info_5_isVset                                   (io_commits_info_5_isVset),
    .io_commits_info_5_isHls                                    (io_commits_info_5_isHls),
    .io_commits_info_5_isVls                                    (io_commits_info_5_isVls),
    .io_commits_info_5_vls                                      (io_commits_info_5_vls),
    .io_commits_info_5_mmio                                     (io_commits_info_5_mmio),
    .io_commits_info_5_commitType                               (io_commits_info_5_commitType),
    .io_commits_info_5_ftqIdx_flag                              (io_commits_info_5_ftqIdx_flag),
    .io_commits_info_5_ftqIdx_value                             (io_commits_info_5_ftqIdx_value),
    .io_commits_info_5_ftqOffset                                (io_commits_info_5_ftqOffset),
    .io_commits_info_5_instrSize                                (io_commits_info_5_instrSize),
    .io_commits_info_5_fpWen                                    (io_commits_info_5_fpWen),
    .io_commits_info_5_rfWen                                    (io_commits_info_5_rfWen),
    .io_commits_info_5_needFlush                                (io_commits_info_5_needFlush),
    .io_commits_info_5_traceBlockInPipe_itype                   (io_commits_info_5_traceBlockInPipe_itype),
    .io_commits_info_5_traceBlockInPipe_iretire                 (io_commits_info_5_traceBlockInPipe_iretire),
    .io_commits_info_5_traceBlockInPipe_ilastsize               (io_commits_info_5_traceBlockInPipe_ilastsize),
    .io_commits_info_5_debug_pc                                 (io_commits_info_5_debug_pc),
    .io_commits_info_5_debug_instr                              (io_commits_info_5_debug_instr),
    .io_commits_info_5_basicDebug_ldest                         (io_commits_info_5_basicDebug_ldest),
    .io_commits_info_5_basicDebug_pdest                         (io_commits_info_5_basicDebug_pdest),
    .io_commits_info_5_basicDebug_vd                            (io_commits_info_5_basicDebug_vd),
    .io_commits_info_5_basicDebug_fpWen                         (io_commits_info_5_basicDebug_fpWen),
    .io_commits_info_5_basicDebug_vecWen                        (io_commits_info_5_basicDebug_vecWen),
    .io_commits_info_5_basicDebug_v0Wen                         (io_commits_info_5_basicDebug_v0Wen),
    .io_commits_info_5_basicDebug_eliminatedMove                (io_commits_info_5_basicDebug_eliminatedMove),
    .io_commits_info_5_basicDebug_isXSTrap                      (io_commits_info_5_basicDebug_isXSTrap),
    .io_commits_info_5_debug_otherPdest_0                       (io_commits_info_5_debug_otherPdest_0),
    .io_commits_info_5_debug_otherPdest_1                       (io_commits_info_5_debug_otherPdest_1),
    .io_commits_info_5_debug_otherPdest_2                       (io_commits_info_5_debug_otherPdest_2),
    .io_commits_info_5_debug_otherPdest_3                       (io_commits_info_5_debug_otherPdest_3),
    .io_commits_info_5_debug_otherPdest_4                       (io_commits_info_5_debug_otherPdest_4),
    .io_commits_info_5_debug_otherPdest_5                       (io_commits_info_5_debug_otherPdest_5),
    .io_commits_info_5_debug_otherPdest_6                       (io_commits_info_5_debug_otherPdest_6),
    .io_commits_info_5_debug_fuType                             (io_commits_info_5_debug_fuType),
    .io_commits_info_5_dirtyFs                                  (io_commits_info_5_dirtyFs),
    .io_commits_info_5_dirtyVs                                  (io_commits_info_5_dirtyVs),
    .io_commits_info_6_walk_v                                   (io_commits_info_6_walk_v),
    .io_commits_info_6_commit_v                                 (io_commits_info_6_commit_v),
    .io_commits_info_6_commit_w                                 (io_commits_info_6_commit_w),
    .io_commits_info_6_realDestSize                             (io_commits_info_6_realDestSize),
    .io_commits_info_6_interrupt_safe                           (io_commits_info_6_interrupt_safe),
    .io_commits_info_6_wflags                                   (io_commits_info_6_wflags),
    .io_commits_info_6_fflags                                   (io_commits_info_6_fflags),
    .io_commits_info_6_vxsat                                    (io_commits_info_6_vxsat),
    .io_commits_info_6_isRVC                                    (io_commits_info_6_isRVC),
    .io_commits_info_6_isVset                                   (io_commits_info_6_isVset),
    .io_commits_info_6_isHls                                    (io_commits_info_6_isHls),
    .io_commits_info_6_isVls                                    (io_commits_info_6_isVls),
    .io_commits_info_6_vls                                      (io_commits_info_6_vls),
    .io_commits_info_6_mmio                                     (io_commits_info_6_mmio),
    .io_commits_info_6_commitType                               (io_commits_info_6_commitType),
    .io_commits_info_6_ftqIdx_flag                              (io_commits_info_6_ftqIdx_flag),
    .io_commits_info_6_ftqIdx_value                             (io_commits_info_6_ftqIdx_value),
    .io_commits_info_6_ftqOffset                                (io_commits_info_6_ftqOffset),
    .io_commits_info_6_instrSize                                (io_commits_info_6_instrSize),
    .io_commits_info_6_fpWen                                    (io_commits_info_6_fpWen),
    .io_commits_info_6_rfWen                                    (io_commits_info_6_rfWen),
    .io_commits_info_6_needFlush                                (io_commits_info_6_needFlush),
    .io_commits_info_6_traceBlockInPipe_itype                   (io_commits_info_6_traceBlockInPipe_itype),
    .io_commits_info_6_traceBlockInPipe_iretire                 (io_commits_info_6_traceBlockInPipe_iretire),
    .io_commits_info_6_traceBlockInPipe_ilastsize               (io_commits_info_6_traceBlockInPipe_ilastsize),
    .io_commits_info_6_debug_pc                                 (io_commits_info_6_debug_pc),
    .io_commits_info_6_debug_instr                              (io_commits_info_6_debug_instr),
    .io_commits_info_6_basicDebug_ldest                         (io_commits_info_6_basicDebug_ldest),
    .io_commits_info_6_basicDebug_pdest                         (io_commits_info_6_basicDebug_pdest),
    .io_commits_info_6_basicDebug_vd                            (io_commits_info_6_basicDebug_vd),
    .io_commits_info_6_basicDebug_fpWen                         (io_commits_info_6_basicDebug_fpWen),
    .io_commits_info_6_basicDebug_vecWen                        (io_commits_info_6_basicDebug_vecWen),
    .io_commits_info_6_basicDebug_v0Wen                         (io_commits_info_6_basicDebug_v0Wen),
    .io_commits_info_6_basicDebug_eliminatedMove                (io_commits_info_6_basicDebug_eliminatedMove),
    .io_commits_info_6_basicDebug_isXSTrap                      (io_commits_info_6_basicDebug_isXSTrap),
    .io_commits_info_6_debug_otherPdest_0                       (io_commits_info_6_debug_otherPdest_0),
    .io_commits_info_6_debug_otherPdest_1                       (io_commits_info_6_debug_otherPdest_1),
    .io_commits_info_6_debug_otherPdest_2                       (io_commits_info_6_debug_otherPdest_2),
    .io_commits_info_6_debug_otherPdest_3                       (io_commits_info_6_debug_otherPdest_3),
    .io_commits_info_6_debug_otherPdest_4                       (io_commits_info_6_debug_otherPdest_4),
    .io_commits_info_6_debug_otherPdest_5                       (io_commits_info_6_debug_otherPdest_5),
    .io_commits_info_6_debug_otherPdest_6                       (io_commits_info_6_debug_otherPdest_6),
    .io_commits_info_6_debug_fuType                             (io_commits_info_6_debug_fuType),
    .io_commits_info_6_dirtyFs                                  (io_commits_info_6_dirtyFs),
    .io_commits_info_6_dirtyVs                                  (io_commits_info_6_dirtyVs),
    .io_commits_info_7_walk_v                                   (io_commits_info_7_walk_v),
    .io_commits_info_7_commit_v                                 (io_commits_info_7_commit_v),
    .io_commits_info_7_commit_w                                 (io_commits_info_7_commit_w),
    .io_commits_info_7_realDestSize                             (io_commits_info_7_realDestSize),
    .io_commits_info_7_interrupt_safe                           (io_commits_info_7_interrupt_safe),
    .io_commits_info_7_wflags                                   (io_commits_info_7_wflags),
    .io_commits_info_7_fflags                                   (io_commits_info_7_fflags),
    .io_commits_info_7_vxsat                                    (io_commits_info_7_vxsat),
    .io_commits_info_7_isRVC                                    (io_commits_info_7_isRVC),
    .io_commits_info_7_isVset                                   (io_commits_info_7_isVset),
    .io_commits_info_7_isHls                                    (io_commits_info_7_isHls),
    .io_commits_info_7_isVls                                    (io_commits_info_7_isVls),
    .io_commits_info_7_vls                                      (io_commits_info_7_vls),
    .io_commits_info_7_mmio                                     (io_commits_info_7_mmio),
    .io_commits_info_7_commitType                               (io_commits_info_7_commitType),
    .io_commits_info_7_ftqIdx_flag                              (io_commits_info_7_ftqIdx_flag),
    .io_commits_info_7_ftqIdx_value                             (io_commits_info_7_ftqIdx_value),
    .io_commits_info_7_ftqOffset                                (io_commits_info_7_ftqOffset),
    .io_commits_info_7_instrSize                                (io_commits_info_7_instrSize),
    .io_commits_info_7_fpWen                                    (io_commits_info_7_fpWen),
    .io_commits_info_7_rfWen                                    (io_commits_info_7_rfWen),
    .io_commits_info_7_needFlush                                (io_commits_info_7_needFlush),
    .io_commits_info_7_traceBlockInPipe_itype                   (io_commits_info_7_traceBlockInPipe_itype),
    .io_commits_info_7_traceBlockInPipe_iretire                 (io_commits_info_7_traceBlockInPipe_iretire),
    .io_commits_info_7_traceBlockInPipe_ilastsize               (io_commits_info_7_traceBlockInPipe_ilastsize),
    .io_commits_info_7_debug_pc                                 (io_commits_info_7_debug_pc),
    .io_commits_info_7_debug_instr                              (io_commits_info_7_debug_instr),
    .io_commits_info_7_basicDebug_ldest                         (io_commits_info_7_basicDebug_ldest),
    .io_commits_info_7_basicDebug_pdest                         (io_commits_info_7_basicDebug_pdest),
    .io_commits_info_7_basicDebug_vd                            (io_commits_info_7_basicDebug_vd),
    .io_commits_info_7_basicDebug_fpWen                         (io_commits_info_7_basicDebug_fpWen),
    .io_commits_info_7_basicDebug_vecWen                        (io_commits_info_7_basicDebug_vecWen),
    .io_commits_info_7_basicDebug_v0Wen                         (io_commits_info_7_basicDebug_v0Wen),
    .io_commits_info_7_basicDebug_eliminatedMove                (io_commits_info_7_basicDebug_eliminatedMove),
    .io_commits_info_7_basicDebug_isXSTrap                      (io_commits_info_7_basicDebug_isXSTrap),
    .io_commits_info_7_debug_otherPdest_0                       (io_commits_info_7_debug_otherPdest_0),
    .io_commits_info_7_debug_otherPdest_1                       (io_commits_info_7_debug_otherPdest_1),
    .io_commits_info_7_debug_otherPdest_2                       (io_commits_info_7_debug_otherPdest_2),
    .io_commits_info_7_debug_otherPdest_3                       (io_commits_info_7_debug_otherPdest_3),
    .io_commits_info_7_debug_otherPdest_4                       (io_commits_info_7_debug_otherPdest_4),
    .io_commits_info_7_debug_otherPdest_5                       (io_commits_info_7_debug_otherPdest_5),
    .io_commits_info_7_debug_otherPdest_6                       (io_commits_info_7_debug_otherPdest_6),
    .io_commits_info_7_debug_fuType                             (io_commits_info_7_debug_fuType),
    .io_commits_info_7_dirtyFs                                  (io_commits_info_7_dirtyFs),
    .io_commits_info_7_dirtyVs                                  (io_commits_info_7_dirtyVs),
    .io_commits_robIdx_0_flag                                   (io_commits_robIdx_0_flag),
    .io_commits_robIdx_0_value                                  (io_commits_robIdx_0_value),
    .io_commits_robIdx_1_flag                                   (io_commits_robIdx_1_flag),
    .io_commits_robIdx_1_value                                  (io_commits_robIdx_1_value),
    .io_commits_robIdx_2_flag                                   (io_commits_robIdx_2_flag),
    .io_commits_robIdx_2_value                                  (io_commits_robIdx_2_value),
    .io_commits_robIdx_3_flag                                   (io_commits_robIdx_3_flag),
    .io_commits_robIdx_3_value                                  (io_commits_robIdx_3_value),
    .io_commits_robIdx_4_flag                                   (io_commits_robIdx_4_flag),
    .io_commits_robIdx_4_value                                  (io_commits_robIdx_4_value),
    .io_commits_robIdx_5_flag                                   (io_commits_robIdx_5_flag),
    .io_commits_robIdx_5_value                                  (io_commits_robIdx_5_value),
    .io_commits_robIdx_6_flag                                   (io_commits_robIdx_6_flag),
    .io_commits_robIdx_6_value                                  (io_commits_robIdx_6_value),
    .io_commits_robIdx_7_flag                                   (io_commits_robIdx_7_flag),
    .io_commits_robIdx_7_value                                  (io_commits_robIdx_7_value),
    .io_trace_blockCommit                                       (io_trace_blockCommit),
    .io_trace_traceCommitInfo_blocks_0_valid                    (io_trace_traceCommitInfo_blocks_0_valid),
    .io_trace_traceCommitInfo_blocks_0_bits_ftqIdx_value        (io_trace_traceCommitInfo_blocks_0_bits_ftqIdx_value),
    .io_trace_traceCommitInfo_blocks_0_bits_ftqOffset           (io_trace_traceCommitInfo_blocks_0_bits_ftqOffset),
    .io_trace_traceCommitInfo_blocks_0_bits_tracePipe_itype     (io_trace_traceCommitInfo_blocks_0_bits_tracePipe_itype),
    .io_trace_traceCommitInfo_blocks_0_bits_tracePipe_iretire   (io_trace_traceCommitInfo_blocks_0_bits_tracePipe_iretire),
    .io_trace_traceCommitInfo_blocks_0_bits_tracePipe_ilastsize (io_trace_traceCommitInfo_blocks_0_bits_tracePipe_ilastsize),
    .io_trace_traceCommitInfo_blocks_1_valid                    (io_trace_traceCommitInfo_blocks_1_valid),
    .io_trace_traceCommitInfo_blocks_1_bits_ftqIdx_value        (io_trace_traceCommitInfo_blocks_1_bits_ftqIdx_value),
    .io_trace_traceCommitInfo_blocks_1_bits_ftqOffset           (io_trace_traceCommitInfo_blocks_1_bits_ftqOffset),
    .io_trace_traceCommitInfo_blocks_1_bits_tracePipe_itype     (io_trace_traceCommitInfo_blocks_1_bits_tracePipe_itype),
    .io_trace_traceCommitInfo_blocks_1_bits_tracePipe_iretire   (io_trace_traceCommitInfo_blocks_1_bits_tracePipe_iretire),
    .io_trace_traceCommitInfo_blocks_1_bits_tracePipe_ilastsize (io_trace_traceCommitInfo_blocks_1_bits_tracePipe_ilastsize),
    .io_trace_traceCommitInfo_blocks_2_valid                    (io_trace_traceCommitInfo_blocks_2_valid),
    .io_trace_traceCommitInfo_blocks_2_bits_ftqIdx_value        (io_trace_traceCommitInfo_blocks_2_bits_ftqIdx_value),
    .io_trace_traceCommitInfo_blocks_2_bits_ftqOffset           (io_trace_traceCommitInfo_blocks_2_bits_ftqOffset),
    .io_trace_traceCommitInfo_blocks_2_bits_tracePipe_itype     (io_trace_traceCommitInfo_blocks_2_bits_tracePipe_itype),
    .io_trace_traceCommitInfo_blocks_2_bits_tracePipe_iretire   (io_trace_traceCommitInfo_blocks_2_bits_tracePipe_iretire),
    .io_trace_traceCommitInfo_blocks_2_bits_tracePipe_ilastsize (io_trace_traceCommitInfo_blocks_2_bits_tracePipe_ilastsize),
    .io_trace_traceCommitInfo_blocks_3_valid                    (io_trace_traceCommitInfo_blocks_3_valid),
    .io_trace_traceCommitInfo_blocks_3_bits_ftqIdx_value        (io_trace_traceCommitInfo_blocks_3_bits_ftqIdx_value),
    .io_trace_traceCommitInfo_blocks_3_bits_ftqOffset           (io_trace_traceCommitInfo_blocks_3_bits_ftqOffset),
    .io_trace_traceCommitInfo_blocks_3_bits_tracePipe_itype     (io_trace_traceCommitInfo_blocks_3_bits_tracePipe_itype),
    .io_trace_traceCommitInfo_blocks_3_bits_tracePipe_iretire   (io_trace_traceCommitInfo_blocks_3_bits_tracePipe_iretire),
    .io_trace_traceCommitInfo_blocks_3_bits_tracePipe_ilastsize (io_trace_traceCommitInfo_blocks_3_bits_tracePipe_ilastsize),
    .io_trace_traceCommitInfo_blocks_4_valid                    (io_trace_traceCommitInfo_blocks_4_valid),
    .io_trace_traceCommitInfo_blocks_4_bits_ftqIdx_value        (io_trace_traceCommitInfo_blocks_4_bits_ftqIdx_value),
    .io_trace_traceCommitInfo_blocks_4_bits_ftqOffset           (io_trace_traceCommitInfo_blocks_4_bits_ftqOffset),
    .io_trace_traceCommitInfo_blocks_4_bits_tracePipe_itype     (io_trace_traceCommitInfo_blocks_4_bits_tracePipe_itype),
    .io_trace_traceCommitInfo_blocks_4_bits_tracePipe_iretire   (io_trace_traceCommitInfo_blocks_4_bits_tracePipe_iretire),
    .io_trace_traceCommitInfo_blocks_4_bits_tracePipe_ilastsize (io_trace_traceCommitInfo_blocks_4_bits_tracePipe_ilastsize),
    .io_trace_traceCommitInfo_blocks_5_valid                    (io_trace_traceCommitInfo_blocks_5_valid),
    .io_trace_traceCommitInfo_blocks_5_bits_ftqIdx_value        (io_trace_traceCommitInfo_blocks_5_bits_ftqIdx_value),
    .io_trace_traceCommitInfo_blocks_5_bits_ftqOffset           (io_trace_traceCommitInfo_blocks_5_bits_ftqOffset),
    .io_trace_traceCommitInfo_blocks_5_bits_tracePipe_itype     (io_trace_traceCommitInfo_blocks_5_bits_tracePipe_itype),
    .io_trace_traceCommitInfo_blocks_5_bits_tracePipe_iretire   (io_trace_traceCommitInfo_blocks_5_bits_tracePipe_iretire),
    .io_trace_traceCommitInfo_blocks_5_bits_tracePipe_ilastsize (io_trace_traceCommitInfo_blocks_5_bits_tracePipe_ilastsize),
    .io_trace_traceCommitInfo_blocks_6_valid                    (io_trace_traceCommitInfo_blocks_6_valid),
    .io_trace_traceCommitInfo_blocks_6_bits_ftqIdx_value        (io_trace_traceCommitInfo_blocks_6_bits_ftqIdx_value),
    .io_trace_traceCommitInfo_blocks_6_bits_ftqOffset           (io_trace_traceCommitInfo_blocks_6_bits_ftqOffset),
    .io_trace_traceCommitInfo_blocks_6_bits_tracePipe_itype     (io_trace_traceCommitInfo_blocks_6_bits_tracePipe_itype),
    .io_trace_traceCommitInfo_blocks_6_bits_tracePipe_iretire   (io_trace_traceCommitInfo_blocks_6_bits_tracePipe_iretire),
    .io_trace_traceCommitInfo_blocks_6_bits_tracePipe_ilastsize (io_trace_traceCommitInfo_blocks_6_bits_tracePipe_ilastsize),
    .io_trace_traceCommitInfo_blocks_7_valid                    (io_trace_traceCommitInfo_blocks_7_valid),
    .io_trace_traceCommitInfo_blocks_7_bits_ftqIdx_value        (io_trace_traceCommitInfo_blocks_7_bits_ftqIdx_value),
    .io_trace_traceCommitInfo_blocks_7_bits_ftqOffset           (io_trace_traceCommitInfo_blocks_7_bits_ftqOffset),
    .io_trace_traceCommitInfo_blocks_7_bits_tracePipe_itype     (io_trace_traceCommitInfo_blocks_7_bits_tracePipe_itype),
    .io_trace_traceCommitInfo_blocks_7_bits_tracePipe_iretire   (io_trace_traceCommitInfo_blocks_7_bits_tracePipe_iretire),
    .io_trace_traceCommitInfo_blocks_7_bits_tracePipe_ilastsize (io_trace_traceCommitInfo_blocks_7_bits_tracePipe_ilastsize),
    .io_rabCommits_isCommit                                     (io_rabCommits_isCommit),
    .io_rabCommits_commitValid_0                                (io_rabCommits_commitValid_0),
    .io_rabCommits_commitValid_1                                (io_rabCommits_commitValid_1),
    .io_rabCommits_commitValid_2                                (io_rabCommits_commitValid_2),
    .io_rabCommits_commitValid_3                                (io_rabCommits_commitValid_3),
    .io_rabCommits_commitValid_4                                (io_rabCommits_commitValid_4),
    .io_rabCommits_commitValid_5                                (io_rabCommits_commitValid_5),
    .io_rabCommits_isWalk                                       (io_rabCommits_isWalk),
    .io_rabCommits_walkValid_0                                  (io_rabCommits_walkValid_0),
    .io_rabCommits_walkValid_1                                  (io_rabCommits_walkValid_1),
    .io_rabCommits_walkValid_2                                  (io_rabCommits_walkValid_2),
    .io_rabCommits_walkValid_3                                  (io_rabCommits_walkValid_3),
    .io_rabCommits_walkValid_4                                  (io_rabCommits_walkValid_4),
    .io_rabCommits_walkValid_5                                  (io_rabCommits_walkValid_5),
    .io_rabCommits_info_0_ldest                                 (io_rabCommits_info_0_ldest),
    .io_rabCommits_info_0_pdest                                 (io_rabCommits_info_0_pdest),
    .io_rabCommits_info_0_rfWen                                 (io_rabCommits_info_0_rfWen),
    .io_rabCommits_info_0_fpWen                                 (io_rabCommits_info_0_fpWen),
    .io_rabCommits_info_0_vecWen                                (io_rabCommits_info_0_vecWen),
    .io_rabCommits_info_0_v0Wen                                 (io_rabCommits_info_0_v0Wen),
    .io_rabCommits_info_0_vlWen                                 (io_rabCommits_info_0_vlWen),
    .io_rabCommits_info_0_isMove                                (io_rabCommits_info_0_isMove),
    .io_rabCommits_info_1_ldest                                 (io_rabCommits_info_1_ldest),
    .io_rabCommits_info_1_pdest                                 (io_rabCommits_info_1_pdest),
    .io_rabCommits_info_1_rfWen                                 (io_rabCommits_info_1_rfWen),
    .io_rabCommits_info_1_fpWen                                 (io_rabCommits_info_1_fpWen),
    .io_rabCommits_info_1_vecWen                                (io_rabCommits_info_1_vecWen),
    .io_rabCommits_info_1_v0Wen                                 (io_rabCommits_info_1_v0Wen),
    .io_rabCommits_info_1_vlWen                                 (io_rabCommits_info_1_vlWen),
    .io_rabCommits_info_1_isMove                                (io_rabCommits_info_1_isMove),
    .io_rabCommits_info_2_ldest                                 (io_rabCommits_info_2_ldest),
    .io_rabCommits_info_2_pdest                                 (io_rabCommits_info_2_pdest),
    .io_rabCommits_info_2_rfWen                                 (io_rabCommits_info_2_rfWen),
    .io_rabCommits_info_2_fpWen                                 (io_rabCommits_info_2_fpWen),
    .io_rabCommits_info_2_vecWen                                (io_rabCommits_info_2_vecWen),
    .io_rabCommits_info_2_v0Wen                                 (io_rabCommits_info_2_v0Wen),
    .io_rabCommits_info_2_vlWen                                 (io_rabCommits_info_2_vlWen),
    .io_rabCommits_info_2_isMove                                (io_rabCommits_info_2_isMove),
    .io_rabCommits_info_3_ldest                                 (io_rabCommits_info_3_ldest),
    .io_rabCommits_info_3_pdest                                 (io_rabCommits_info_3_pdest),
    .io_rabCommits_info_3_rfWen                                 (io_rabCommits_info_3_rfWen),
    .io_rabCommits_info_3_fpWen                                 (io_rabCommits_info_3_fpWen),
    .io_rabCommits_info_3_vecWen                                (io_rabCommits_info_3_vecWen),
    .io_rabCommits_info_3_v0Wen                                 (io_rabCommits_info_3_v0Wen),
    .io_rabCommits_info_3_vlWen                                 (io_rabCommits_info_3_vlWen),
    .io_rabCommits_info_3_isMove                                (io_rabCommits_info_3_isMove),
    .io_rabCommits_info_4_ldest                                 (io_rabCommits_info_4_ldest),
    .io_rabCommits_info_4_pdest                                 (io_rabCommits_info_4_pdest),
    .io_rabCommits_info_4_rfWen                                 (io_rabCommits_info_4_rfWen),
    .io_rabCommits_info_4_fpWen                                 (io_rabCommits_info_4_fpWen),
    .io_rabCommits_info_4_vecWen                                (io_rabCommits_info_4_vecWen),
    .io_rabCommits_info_4_v0Wen                                 (io_rabCommits_info_4_v0Wen),
    .io_rabCommits_info_4_vlWen                                 (io_rabCommits_info_4_vlWen),
    .io_rabCommits_info_4_isMove                                (io_rabCommits_info_4_isMove),
    .io_rabCommits_info_5_ldest                                 (io_rabCommits_info_5_ldest),
    .io_rabCommits_info_5_pdest                                 (io_rabCommits_info_5_pdest),
    .io_rabCommits_info_5_rfWen                                 (io_rabCommits_info_5_rfWen),
    .io_rabCommits_info_5_fpWen                                 (io_rabCommits_info_5_fpWen),
    .io_rabCommits_info_5_vecWen                                (io_rabCommits_info_5_vecWen),
    .io_rabCommits_info_5_v0Wen                                 (io_rabCommits_info_5_v0Wen),
    .io_rabCommits_info_5_vlWen                                 (io_rabCommits_info_5_vlWen),
    .io_rabCommits_info_5_isMove                                (io_rabCommits_info_5_isMove),
    .io_diffRatCommitRobIdx_valid                               (io_diffRatCommitRobIdx_valid),
    .io_diffRatCommitRobIdx_bits_flag                           (io_diffRatCommitRobIdx_bits_flag),
    .io_diffRatCommitRobIdx_bits_value                          (io_diffRatCommitRobIdx_bits_value),
    .io_lsq_scommit                                             (io_lsq_scommit),
    .io_lsq_pendingMMIOld                                       (io_lsq_pendingMMIOld),
    .io_lsq_pendingst                                           (io_lsq_pendingst),
    .io_lsq_pendingPtr_flag                                     (io_lsq_pendingPtr_flag),
    .io_lsq_pendingPtr_value                                    (io_lsq_pendingPtr_value),
    .io_lsq_loadMmio_0                                          (io_lsq_loadMmio_0),
    .io_lsq_loadMmio_1                                          (io_lsq_loadMmio_1),
    .io_lsq_loadMmio_2                                          (io_lsq_loadMmio_2),
    .io_lsq_loadMmioUop_0_robIdx_value                          (io_lsq_loadMmioUop_0_robIdx_value),
    .io_lsq_loadMmioUop_1_robIdx_value                          (io_lsq_loadMmioUop_1_robIdx_value),
    .io_lsq_loadMmioUop_2_robIdx_value                          (io_lsq_loadMmioUop_2_robIdx_value),
    .io_lsq_storeMmio                                           (io_lsq_storeMmio),
    .io_lsq_storeMmioUop_robIdx_value                           (io_lsq_storeMmioUop_robIdx_value),
    .io_robDeqPtr_flag                                          (io_robDeqPtr_flag),
    .io_robDeqPtr_value                                         (io_robDeqPtr_value),
    .io_csr_intrBitSet                                          (io_csr_intrBitSet),
    .io_csr_wfiEvent                                            (io_csr_wfiEvent),
    .io_csr_criticalErrorState                                  (io_csr_criticalErrorState),
    .io_csr_fflags_valid                                        (io_csr_fflags_valid),
    .io_csr_fflags_bits                                         (io_csr_fflags_bits),
    .io_csr_vxsat_valid                                         (io_csr_vxsat_valid),
    .io_csr_vxsat_bits                                          (io_csr_vxsat_bits),
    .io_csr_vstart_valid                                        (io_csr_vstart_valid),
    .io_csr_vstart_bits                                         (io_csr_vstart_bits),
    .io_csr_dirty_fs                                            (io_csr_dirty_fs),
    .io_csr_dirty_vs                                            (io_csr_dirty_vs),
    .io_csr_perfinfo_retiredInstr                               (io_csr_perfinfo_retiredInstr),
    .io_snpt_useSnpt                                            (io_snpt_useSnpt),
    .io_snpt_snptSelect                                         (io_snpt_snptSelect),
    .io_headNotReady                                            (io_headNotReady),
    .io_cpu_halt                                                (io_cpu_halt),
    .io_wfi_wfiReq                                              (io_wfi_wfiReq),
    .io_wfi_safeFromMem                                         (io_wfi_safeFromMem),
    .io_wfi_safeFromFrontend                                    (io_wfi_safeFromFrontend),
    .io_wfi_enable                                              (io_wfi_enable),
    .io_toDecode_isResumeVType                                  (io_toDecode_isResumeVType),
    .io_fromVecExcpMod_busy                                     (io_fromVecExcpMod_busy),
    .io_readGPAMemAddr_valid                                    (io_readGPAMemAddr_valid),
    .io_readGPAMemData_gpaddr                                   (io_readGPAMemData_gpaddr),
    .io_readGPAMemData_isForVSnonLeafPTE                        (io_readGPAMemData_isForVSnonLeafPTE),
    .io_vstartIsZero                                            (io_vstartIsZero),
    .io_toVecExcpMod_excpInfo_valid                             (io_toVecExcpMod_excpInfo_valid),
    .io_toVecExcpMod_excpInfo_bits_vstart                       (io_toVecExcpMod_excpInfo_bits_vstart),
    .io_toVecExcpMod_excpInfo_bits_vsew                         (io_toVecExcpMod_excpInfo_bits_vsew),
    .io_toVecExcpMod_excpInfo_bits_veew                         (io_toVecExcpMod_excpInfo_bits_veew),
    .io_toVecExcpMod_excpInfo_bits_vlmul                        (io_toVecExcpMod_excpInfo_bits_vlmul),
    .io_toVecExcpMod_excpInfo_bits_nf                           (io_toVecExcpMod_excpInfo_bits_nf),
    .io_toVecExcpMod_excpInfo_bits_isStride                     (io_toVecExcpMod_excpInfo_bits_isStride),
    .io_toVecExcpMod_excpInfo_bits_isIndexed                    (io_toVecExcpMod_excpInfo_bits_isIndexed),
    .io_toVecExcpMod_excpInfo_bits_isWhole                      (io_toVecExcpMod_excpInfo_bits_isWhole),
    .io_toVecExcpMod_excpInfo_bits_isVlm                        (io_toVecExcpMod_excpInfo_bits_isVlm),
    .io_debugRobHead_debug_fuType                               (io_debugRobHead_debug_fuType),
    .io_debugEnqLsq_canAccept                                   (io_debugEnqLsq_canAccept),
    .io_debugEnqLsq_needAlloc_0                                 (io_debugEnqLsq_needAlloc_0),
    .io_debugEnqLsq_needAlloc_1                                 (io_debugEnqLsq_needAlloc_1),
    .io_debugEnqLsq_needAlloc_2                                 (io_debugEnqLsq_needAlloc_2),
    .io_debugEnqLsq_needAlloc_3                                 (io_debugEnqLsq_needAlloc_3),
    .io_debugEnqLsq_needAlloc_4                                 (io_debugEnqLsq_needAlloc_4),
    .io_debugEnqLsq_needAlloc_5                                 (io_debugEnqLsq_needAlloc_5),
    .io_debugEnqLsq_req_0_valid                                 (io_debugEnqLsq_req_0_valid),
    .io_debugEnqLsq_req_0_bits_robIdx_value                     (io_debugEnqLsq_req_0_bits_robIdx_value),
    .io_debugEnqLsq_req_0_bits_lqIdx_value                      (io_debugEnqLsq_req_0_bits_lqIdx_value),
    .io_debugEnqLsq_req_1_valid                                 (io_debugEnqLsq_req_1_valid),
    .io_debugEnqLsq_req_1_bits_robIdx_value                     (io_debugEnqLsq_req_1_bits_robIdx_value),
    .io_debugEnqLsq_req_1_bits_lqIdx_value                      (io_debugEnqLsq_req_1_bits_lqIdx_value),
    .io_debugEnqLsq_req_2_valid                                 (io_debugEnqLsq_req_2_valid),
    .io_debugEnqLsq_req_2_bits_robIdx_value                     (io_debugEnqLsq_req_2_bits_robIdx_value),
    .io_debugEnqLsq_req_2_bits_lqIdx_value                      (io_debugEnqLsq_req_2_bits_lqIdx_value),
    .io_debugEnqLsq_req_3_valid                                 (io_debugEnqLsq_req_3_valid),
    .io_debugEnqLsq_req_3_bits_robIdx_value                     (io_debugEnqLsq_req_3_bits_robIdx_value),
    .io_debugEnqLsq_req_3_bits_lqIdx_value                      (io_debugEnqLsq_req_3_bits_lqIdx_value),
    .io_debugEnqLsq_req_4_valid                                 (io_debugEnqLsq_req_4_valid),
    .io_debugEnqLsq_req_4_bits_robIdx_value                     (io_debugEnqLsq_req_4_bits_robIdx_value),
    .io_debugEnqLsq_req_4_bits_lqIdx_value                      (io_debugEnqLsq_req_4_bits_lqIdx_value),
    .io_debugEnqLsq_req_5_valid                                 (io_debugEnqLsq_req_5_valid),
    .io_debugEnqLsq_req_5_bits_robIdx_value                     (io_debugEnqLsq_req_5_bits_robIdx_value),
    .io_debugEnqLsq_req_5_bits_lqIdx_value                      (io_debugEnqLsq_req_5_bits_lqIdx_value),
    .io_debugHeadLsIssue                                        (io_debugHeadLsIssue),
    .io_lsTopdownInfo_0_s1_robIdx                               (io_lsTopdownInfo_0_s1_robIdx),
    .io_lsTopdownInfo_0_s1_vaddr_valid                          (io_lsTopdownInfo_0_s1_vaddr_valid),
    .io_lsTopdownInfo_0_s1_vaddr_bits                           (io_lsTopdownInfo_0_s1_vaddr_bits),
    .io_lsTopdownInfo_0_s2_robIdx                               (io_lsTopdownInfo_0_s2_robIdx),
    .io_lsTopdownInfo_0_s2_paddr_valid                          (io_lsTopdownInfo_0_s2_paddr_valid),
    .io_lsTopdownInfo_0_s2_paddr_bits                           (io_lsTopdownInfo_0_s2_paddr_bits),
    .io_lsTopdownInfo_1_s1_robIdx                               (io_lsTopdownInfo_1_s1_robIdx),
    .io_lsTopdownInfo_1_s1_vaddr_valid                          (io_lsTopdownInfo_1_s1_vaddr_valid),
    .io_lsTopdownInfo_1_s1_vaddr_bits                           (io_lsTopdownInfo_1_s1_vaddr_bits),
    .io_lsTopdownInfo_1_s2_robIdx                               (io_lsTopdownInfo_1_s2_robIdx),
    .io_lsTopdownInfo_1_s2_paddr_valid                          (io_lsTopdownInfo_1_s2_paddr_valid),
    .io_lsTopdownInfo_1_s2_paddr_bits                           (io_lsTopdownInfo_1_s2_paddr_bits),
    .io_lsTopdownInfo_2_s1_robIdx                               (io_lsTopdownInfo_2_s1_robIdx),
    .io_lsTopdownInfo_2_s1_vaddr_valid                          (io_lsTopdownInfo_2_s1_vaddr_valid),
    .io_lsTopdownInfo_2_s1_vaddr_bits                           (io_lsTopdownInfo_2_s1_vaddr_bits),
    .io_lsTopdownInfo_2_s2_robIdx                               (io_lsTopdownInfo_2_s2_robIdx),
    .io_lsTopdownInfo_2_s2_paddr_valid                          (io_lsTopdownInfo_2_s2_paddr_valid),
    .io_lsTopdownInfo_2_s2_paddr_bits                           (io_lsTopdownInfo_2_s2_paddr_bits),
    .io_debugTopDown_toCore_robHeadVaddr_valid                  (io_debugTopDown_toCore_robHeadVaddr_valid),
    .io_debugTopDown_toCore_robHeadVaddr_bits                   (io_debugTopDown_toCore_robHeadVaddr_bits),
    .io_debugTopDown_toCore_robHeadPaddr_valid                  (io_debugTopDown_toCore_robHeadPaddr_valid),
    .io_debugTopDown_toCore_robHeadPaddr_bits                   (io_debugTopDown_toCore_robHeadPaddr_bits),
    .io_debugTopDown_toDispatch_robHeadLsIssue                  (io_debugTopDown_toDispatch_robHeadLsIssue),
    .io_debugInstrAddrTransType_sv39                            (io_debugInstrAddrTransType_sv39),
    .io_debugInstrAddrTransType_sv48                            (io_debugInstrAddrTransType_sv48),
    .io_storeDebugInfo_0_robidx_value                           (io_storeDebugInfo_0_robidx_value),
    .io_storeDebugInfo_0_pc                                     (io_storeDebugInfo_0_pc),
    .io_storeDebugInfo_1_robidx_value                           (io_storeDebugInfo_1_robidx_value),
    .io_storeDebugInfo_1_pc                                     (io_storeDebugInfo_1_pc),
    .io_perf_0_value                                            (io_perf_0_value),
    .io_perf_1_value                                            (io_perf_1_value),
    .io_perf_2_value                                            (io_perf_2_value),
    .io_perf_3_value                                            (io_perf_3_value),
    .io_perf_4_value                                            (io_perf_4_value),
    .io_perf_5_value                                            (io_perf_5_value),
    .io_perf_6_value                                            (io_perf_6_value),
    .io_perf_7_value                                            (io_perf_7_value),
    .io_perf_8_value                                            (io_perf_8_value),
    .io_perf_9_value                                            (io_perf_9_value),
    .io_perf_10_value                                           (io_perf_10_value),
    .io_perf_11_value                                           (io_perf_11_value),
    .io_perf_12_value                                           (io_perf_12_value),
    .io_perf_13_value                                           (io_perf_13_value),
    .io_perf_14_value                                           (io_perf_14_value),
    .io_perf_15_value                                           (io_perf_15_value),
    .io_perf_16_value                                           (io_perf_16_value),
    .io_perf_17_value                                           (io_perf_17_value),
    .io_perf_18_value                                           (io_perf_18_value),
    .io_error_0                                                 (io_error_0),
    .gatewayIn_packed_6_bore                                    (gatewayIn_packed_6_bore),
    .gatewayIn_packed_7_bore                                    (gatewayIn_packed_7_bore),
    .gatewayIn_packed_8_bore                                    (gatewayIn_packed_8_bore),
    .gatewayIn_packed_9_bore                                    (gatewayIn_packed_9_bore),
    .gatewayIn_packed_10_bore                                   (gatewayIn_packed_10_bore),
    .gatewayIn_packed_11_bore                                   (gatewayIn_packed_11_bore),
    .gatewayIn_packed_12_bore                                   (gatewayIn_packed_12_bore),
    .gatewayIn_packed_13_bore                                   (gatewayIn_packed_13_bore),
    .gatewayIn_packed_14_bore                                   (gatewayIn_packed_14_bore),
    .gatewayIn_packed_15_bore                                   (gatewayIn_packed_15_bore),
    .gatewayIn_packed_16_bore                                   (gatewayIn_packed_16_bore),
    .gatewayIn_packed_17_bore                                   (gatewayIn_packed_17_bore),
    .gatewayIn_packed_18_bore                                   (gatewayIn_packed_18_bore),
    .gatewayIn_packed_19_bore                                   (gatewayIn_packed_19_bore),
    .gatewayIn_packed_20_bore                                   (gatewayIn_packed_20_bore),
    .gatewayIn_packed_21_bore                                   (gatewayIn_packed_21_bore),
    .gatewayIn_packed_22_bore                                   (gatewayIn_packed_22_bore),
    .allocatePtrVec_1_value                                     (n_allocatePtrVec_1_value),
    .allocatePtrVec_2_value                                     (n_allocatePtrVec_2_value),
    .allocatePtrVec_3_value                                     (n_allocatePtrVec_3_value),
    .allocatePtrVec_4_value                                     (n_allocatePtrVec_4_value),
    .allocatePtrVec_5_value                                     (n_allocatePtrVec_5_value),
    .allowOnlyOneCommit                                         (n_allowOnlyOneCommit),
    .blockCommit                                                (n_blockCommit),
    .canEnqueueEG_0                                             (n_canEnqueueEG_0),
    .canEnqueueEG_1                                             (n_canEnqueueEG_1),
    .canEnqueueEG_2                                             (n_canEnqueueEG_2),
    .canEnqueueEG_3                                             (n_canEnqueueEG_3),
    .canEnqueueEG_4                                             (n_canEnqueueEG_4),
    .canEnqueueEG_5                                             (n_canEnqueueEG_5),
    .canEnqueue_0                                               (n_canEnqueue_0),
    .canEnqueue_1                                               (n_canEnqueue_1),
    .canEnqueue_2                                               (n_canEnqueue_2),
    .canEnqueue_3                                               (n_canEnqueue_3),
    .canEnqueue_4                                               (n_canEnqueue_4),
    .canEnqueue_5                                               (n_canEnqueue_5),
    .commitStuckCounter_io_stuck                                (n_commitStuckCounter_io_stuck),
    .commit_vDeqGroup_0                                         (n_commit_vDeqGroup_0),
    .commit_vDeqGroup_1                                         (n_commit_vDeqGroup_1),
    .commit_vDeqGroup_2                                         (n_commit_vDeqGroup_2),
    .commit_vDeqGroup_3                                         (n_commit_vDeqGroup_3),
    .commit_vDeqGroup_4                                         (n_commit_vDeqGroup_4),
    .commit_vDeqGroup_5                                         (n_commit_vDeqGroup_5),
    .commit_vDeqGroup_6                                         (n_commit_vDeqGroup_6),
    .commit_vDeqGroup_7                                         (n_commit_vDeqGroup_7),
    .commit_wDeqGroup_0                                         (n_commit_wDeqGroup_0),
    .commit_wDeqGroup_1                                         (n_commit_wDeqGroup_1),
    .commit_wDeqGroup_2                                         (n_commit_wDeqGroup_2),
    .commit_wDeqGroup_3                                         (n_commit_wDeqGroup_3),
    .commit_wDeqGroup_4                                         (n_commit_wDeqGroup_4),
    .commit_wDeqGroup_5                                         (n_commit_wDeqGroup_5),
    .commit_wDeqGroup_6                                         (n_commit_wDeqGroup_6),
    .commit_wDeqGroup_7                                         (n_commit_wDeqGroup_7),
    .deqPtrGenModule_io_state                                   (n_deqPtrGenModule_io_state),
    .dtPcTransTypeWdata                                         (n_dtPcTransTypeWdata),
    .enqFirstUopValid_0                                         (n_enqFirstUopValid_0),
    .enqFirstUopValid_1                                         (n_enqFirstUopValid_1),
    .enqFirstUopValid_2                                         (n_enqFirstUopValid_2),
    .enqFirstUopValid_3                                         (n_enqFirstUopValid_3),
    .enqFirstUopValid_4                                         (n_enqFirstUopValid_4),
    .enqFirstUopValid_5                                         (n_enqFirstUopValid_5),
    .enqPtrGenModule_io_allowEnqueue                            (n_enqPtrGenModule_io_allowEnqueue),
    .exceptionGen_io_wb_0_bits_hasException                     (n_exceptionGen_io_wb_0_bits_hasException),
    .exceptionGen_io_wb_10_bits_hasException                    (n_exceptionGen_io_wb_10_bits_hasException),
    .exceptionGen_io_wb_11_bits_hasException                    (n_exceptionGen_io_wb_11_bits_hasException),
    .exceptionGen_io_wb_11_bits_vstart                          (n_exceptionGen_io_wb_11_bits_vstart),
    .exceptionGen_io_wb_11_bits_vstartEn                        (n_exceptionGen_io_wb_11_bits_vstartEn),
    .exceptionGen_io_wb_12_bits_hasException                    (n_exceptionGen_io_wb_12_bits_hasException),
    .exceptionGen_io_wb_12_bits_vstart                          (n_exceptionGen_io_wb_12_bits_vstart),
    .exceptionGen_io_wb_12_bits_vstartEn                        (n_exceptionGen_io_wb_12_bits_vstartEn),
    .exceptionGen_io_wb_6_bits_hasException                     (n_exceptionGen_io_wb_6_bits_hasException),
    .exceptionGen_io_wb_7_bits_hasException                     (n_exceptionGen_io_wb_7_bits_hasException),
    .exceptionGen_io_wb_8_bits_hasException                     (n_exceptionGen_io_wb_8_bits_hasException),
    .exceptionGen_io_wb_9_bits_hasException                     (n_exceptionGen_io_wb_9_bits_hasException),
    .hasBlockBackwardOut                                        (n_hasBlockBackwardOut),
    .hasCommittedOut_0                                          (n_hasCommittedOut_0),
    .hasCommittedOut_1                                          (n_hasCommittedOut_1),
    .hasCommittedOut_2                                          (n_hasCommittedOut_2),
    .hasCommittedOut_3                                          (n_hasCommittedOut_3),
    .hasCommittedOut_4                                          (n_hasCommittedOut_4),
    .hasCommittedOut_5                                          (n_hasCommittedOut_5),
    .hasCommittedOut_6                                          (n_hasCommittedOut_6),
    .hasCommittedOut_7                                          (n_hasCommittedOut_7),
    .hasWaitForwardOut                                          (n_hasWaitForwardOut),
    .intrBitSetRegOut                                           (n_intrBitSetRegOut),
    .io_flushOut_valid_0                                        (n_io_flushOut_valid_0),
    .rab_io_fromRob_commitSize                                  (n_rab_io_fromRob_commitSize),
    .rab_io_fromRob_vecLoadExcp_valid_REGOut                    (n_rab_io_fromRob_vecLoadExcp_valid_REGOut),
    .rab_io_fromRob_walkEnd                                     (n_rab_io_fromRob_walkEnd),
    .rab_io_fromRob_walkSize                                    (n_rab_io_fromRob_walkSize),
    .rawInfo_0_interrupt_safe                                   (n_rawInfo_0_interrupt_safe),
    .snptEnq                                                    (n_snptEnq),
    .vtypeBuffer_io_fromRob_commitSize                          (n_vtypeBuffer_io_fromRob_commitSize),
    .vtypeBuffer_io_fromRob_walkEnd                             (n_vtypeBuffer_io_fromRob_walkEnd),
    .vtypeBuffer_io_fromRob_walkSize                            (n_vtypeBuffer_io_fromRob_walkSize),
    .commitStuckCounter_io_overflow                             (n_commitStuckCounter_io_overflow),
    .deqPtrVec_0_flag                                           (n_deqPtrVec_0_flag),
    .deqPtrVec_0_value                                          (n_deqPtrVec_0_value),
    .deqPtrVec_1_flag                                           (n_deqPtrVec_1_flag),
    .deqPtrVec_1_value                                          (n_deqPtrVec_1_value),
    .deqPtrVec_2_flag                                           (n_deqPtrVec_2_flag),
    .deqPtrVec_2_value                                          (n_deqPtrVec_2_value),
    .deqPtrVec_3_flag                                           (n_deqPtrVec_3_flag),
    .deqPtrVec_3_value                                          (n_deqPtrVec_3_value),
    .deqPtrVec_4_flag                                           (n_deqPtrVec_4_flag),
    .deqPtrVec_4_value                                          (n_deqPtrVec_4_value),
    .deqPtrVec_5_flag                                           (n_deqPtrVec_5_flag),
    .deqPtrVec_5_value                                          (n_deqPtrVec_5_value),
    .deqPtrVec_6_flag                                           (n_deqPtrVec_6_flag),
    .deqPtrVec_6_value                                          (n_deqPtrVec_6_value),
    .deqPtrVec_7_flag                                           (n_deqPtrVec_7_flag),
    .deqPtrVec_7_value                                          (n_deqPtrVec_7_value),
    .deqPtrVec_next_0_flag                                      (n_deqPtrVec_next_0_flag),
    .deqPtrVec_next_0_value                                     (n_deqPtrVec_next_0_value),
    .dt_pcTransType_ext_R0_data                                 (n_dt_pcTransType_ext_R0_data),
    .dt_pcTransType_ext_R1_data                                 (n_dt_pcTransType_ext_R1_data),
    .dt_pcTransType_ext_R2_data                                 (n_dt_pcTransType_ext_R2_data),
    .dt_pcTransType_ext_R3_data                                 (n_dt_pcTransType_ext_R3_data),
    .dt_pcTransType_ext_R4_data                                 (n_dt_pcTransType_ext_R4_data),
    .dt_pcTransType_ext_R5_data                                 (n_dt_pcTransType_ext_R5_data),
    .dt_pcTransType_ext_R6_data                                 (n_dt_pcTransType_ext_R6_data),
    .dt_pcTransType_ext_R7_data                                 (n_dt_pcTransType_ext_R7_data),
    .enqPtrVec_0_flag                                           (n_enqPtrVec_0_flag),
    .enqPtrVec_0_value                                          (n_enqPtrVec_0_value),
    .enqPtrVec_1_value                                          (n_enqPtrVec_1_value),
    .enqPtrVec_2_value                                          (n_enqPtrVec_2_value),
    .enqPtrVec_3_value                                          (n_enqPtrVec_3_value),
    .enqPtrVec_4_value                                          (n_enqPtrVec_4_value),
    .enqPtrVec_5_value                                          (n_enqPtrVec_5_value),
    .exceptionGen_io_state_bits_crossPageIPFFix                 (n_exceptionGen_io_state_bits_crossPageIPFFix),
    .exceptionGen_io_state_bits_exceptionVec_0                  (n_exceptionGen_io_state_bits_exceptionVec_0),
    .exceptionGen_io_state_bits_exceptionVec_1                  (n_exceptionGen_io_state_bits_exceptionVec_1),
    .exceptionGen_io_state_bits_exceptionVec_10                 (n_exceptionGen_io_state_bits_exceptionVec_10),
    .exceptionGen_io_state_bits_exceptionVec_11                 (n_exceptionGen_io_state_bits_exceptionVec_11),
    .exceptionGen_io_state_bits_exceptionVec_12                 (n_exceptionGen_io_state_bits_exceptionVec_12),
    .exceptionGen_io_state_bits_exceptionVec_13                 (n_exceptionGen_io_state_bits_exceptionVec_13),
    .exceptionGen_io_state_bits_exceptionVec_14                 (n_exceptionGen_io_state_bits_exceptionVec_14),
    .exceptionGen_io_state_bits_exceptionVec_15                 (n_exceptionGen_io_state_bits_exceptionVec_15),
    .exceptionGen_io_state_bits_exceptionVec_16                 (n_exceptionGen_io_state_bits_exceptionVec_16),
    .exceptionGen_io_state_bits_exceptionVec_17                 (n_exceptionGen_io_state_bits_exceptionVec_17),
    .exceptionGen_io_state_bits_exceptionVec_18                 (n_exceptionGen_io_state_bits_exceptionVec_18),
    .exceptionGen_io_state_bits_exceptionVec_19                 (n_exceptionGen_io_state_bits_exceptionVec_19),
    .exceptionGen_io_state_bits_exceptionVec_2                  (n_exceptionGen_io_state_bits_exceptionVec_2),
    .exceptionGen_io_state_bits_exceptionVec_20                 (n_exceptionGen_io_state_bits_exceptionVec_20),
    .exceptionGen_io_state_bits_exceptionVec_21                 (n_exceptionGen_io_state_bits_exceptionVec_21),
    .exceptionGen_io_state_bits_exceptionVec_22                 (n_exceptionGen_io_state_bits_exceptionVec_22),
    .exceptionGen_io_state_bits_exceptionVec_23                 (n_exceptionGen_io_state_bits_exceptionVec_23),
    .exceptionGen_io_state_bits_exceptionVec_3                  (n_exceptionGen_io_state_bits_exceptionVec_3),
    .exceptionGen_io_state_bits_exceptionVec_4                  (n_exceptionGen_io_state_bits_exceptionVec_4),
    .exceptionGen_io_state_bits_exceptionVec_5                  (n_exceptionGen_io_state_bits_exceptionVec_5),
    .exceptionGen_io_state_bits_exceptionVec_6                  (n_exceptionGen_io_state_bits_exceptionVec_6),
    .exceptionGen_io_state_bits_exceptionVec_7                  (n_exceptionGen_io_state_bits_exceptionVec_7),
    .exceptionGen_io_state_bits_exceptionVec_8                  (n_exceptionGen_io_state_bits_exceptionVec_8),
    .exceptionGen_io_state_bits_exceptionVec_9                  (n_exceptionGen_io_state_bits_exceptionVec_9),
    .exceptionGen_io_state_bits_flushPipe                       (n_exceptionGen_io_state_bits_flushPipe),
    .exceptionGen_io_state_bits_isEnqExcp                       (n_exceptionGen_io_state_bits_isEnqExcp),
    .exceptionGen_io_state_bits_isFetchMalAddr                  (n_exceptionGen_io_state_bits_isFetchMalAddr),
    .exceptionGen_io_state_bits_isIndexed                       (n_exceptionGen_io_state_bits_isIndexed),
    .exceptionGen_io_state_bits_isStrided                       (n_exceptionGen_io_state_bits_isStrided),
    .exceptionGen_io_state_bits_isVecLoad                       (n_exceptionGen_io_state_bits_isVecLoad),
    .exceptionGen_io_state_bits_isVlm                           (n_exceptionGen_io_state_bits_isVlm),
    .exceptionGen_io_state_bits_isVset                          (n_exceptionGen_io_state_bits_isVset),
    .exceptionGen_io_state_bits_isWhole                         (n_exceptionGen_io_state_bits_isWhole),
    .exceptionGen_io_state_bits_nf                              (n_exceptionGen_io_state_bits_nf),
    .exceptionGen_io_state_bits_replayInst                      (n_exceptionGen_io_state_bits_replayInst),
    .exceptionGen_io_state_bits_robIdx_flag                     (n_exceptionGen_io_state_bits_robIdx_flag),
    .exceptionGen_io_state_bits_robIdx_value                    (n_exceptionGen_io_state_bits_robIdx_value),
    .exceptionGen_io_state_bits_satpFlushFirstFetchFault        (n_exceptionGen_io_state_bits_satpFlushFirstFetchFault),
    .exceptionGen_io_state_bits_satpFlushPipe                   (n_exceptionGen_io_state_bits_satpFlushPipe),
    .exceptionGen_io_state_bits_singleStep                      (n_exceptionGen_io_state_bits_singleStep),
    .exceptionGen_io_state_bits_trigger                         (n_exceptionGen_io_state_bits_trigger),
    .exceptionGen_io_state_bits_veew                            (n_exceptionGen_io_state_bits_veew),
    .exceptionGen_io_state_bits_vlmul                           (n_exceptionGen_io_state_bits_vlmul),
    .exceptionGen_io_state_bits_vsew                            (n_exceptionGen_io_state_bits_vsew),
    .exceptionGen_io_state_bits_vstart                          (n_exceptionGen_io_state_bits_vstart),
    .exceptionGen_io_state_bits_vstartEn                        (n_exceptionGen_io_state_bits_vstartEn),
    .exceptionGen_io_state_valid                                (n_exceptionGen_io_state_valid),
    .rab_io_canEnq                                              (n_rab_io_canEnq),
    .rab_io_canEnqForDispatch                                   (n_rab_io_canEnqForDispatch),
    .rab_io_commits_commitValid_0                               (n_rab_io_commits_commitValid_0),
    .rab_io_commits_commitValid_1                               (n_rab_io_commits_commitValid_1),
    .rab_io_commits_commitValid_2                               (n_rab_io_commits_commitValid_2),
    .rab_io_commits_commitValid_3                               (n_rab_io_commits_commitValid_3),
    .rab_io_commits_commitValid_4                               (n_rab_io_commits_commitValid_4),
    .rab_io_commits_commitValid_5                               (n_rab_io_commits_commitValid_5),
    .rab_io_commits_info_0_fpWen                                (n_rab_io_commits_info_0_fpWen),
    .rab_io_commits_info_0_isMove                               (n_rab_io_commits_info_0_isMove),
    .rab_io_commits_info_0_ldest                                (n_rab_io_commits_info_0_ldest),
    .rab_io_commits_info_0_pdest                                (n_rab_io_commits_info_0_pdest),
    .rab_io_commits_info_0_rfWen                                (n_rab_io_commits_info_0_rfWen),
    .rab_io_commits_info_0_v0Wen                                (n_rab_io_commits_info_0_v0Wen),
    .rab_io_commits_info_0_vecWen                               (n_rab_io_commits_info_0_vecWen),
    .rab_io_commits_info_0_vlWen                                (n_rab_io_commits_info_0_vlWen),
    .rab_io_commits_info_1_fpWen                                (n_rab_io_commits_info_1_fpWen),
    .rab_io_commits_info_1_isMove                               (n_rab_io_commits_info_1_isMove),
    .rab_io_commits_info_1_ldest                                (n_rab_io_commits_info_1_ldest),
    .rab_io_commits_info_1_pdest                                (n_rab_io_commits_info_1_pdest),
    .rab_io_commits_info_1_rfWen                                (n_rab_io_commits_info_1_rfWen),
    .rab_io_commits_info_1_v0Wen                                (n_rab_io_commits_info_1_v0Wen),
    .rab_io_commits_info_1_vecWen                               (n_rab_io_commits_info_1_vecWen),
    .rab_io_commits_info_1_vlWen                                (n_rab_io_commits_info_1_vlWen),
    .rab_io_commits_info_2_fpWen                                (n_rab_io_commits_info_2_fpWen),
    .rab_io_commits_info_2_isMove                               (n_rab_io_commits_info_2_isMove),
    .rab_io_commits_info_2_ldest                                (n_rab_io_commits_info_2_ldest),
    .rab_io_commits_info_2_pdest                                (n_rab_io_commits_info_2_pdest),
    .rab_io_commits_info_2_rfWen                                (n_rab_io_commits_info_2_rfWen),
    .rab_io_commits_info_2_v0Wen                                (n_rab_io_commits_info_2_v0Wen),
    .rab_io_commits_info_2_vecWen                               (n_rab_io_commits_info_2_vecWen),
    .rab_io_commits_info_2_vlWen                                (n_rab_io_commits_info_2_vlWen),
    .rab_io_commits_info_3_fpWen                                (n_rab_io_commits_info_3_fpWen),
    .rab_io_commits_info_3_isMove                               (n_rab_io_commits_info_3_isMove),
    .rab_io_commits_info_3_ldest                                (n_rab_io_commits_info_3_ldest),
    .rab_io_commits_info_3_pdest                                (n_rab_io_commits_info_3_pdest),
    .rab_io_commits_info_3_rfWen                                (n_rab_io_commits_info_3_rfWen),
    .rab_io_commits_info_3_v0Wen                                (n_rab_io_commits_info_3_v0Wen),
    .rab_io_commits_info_3_vecWen                               (n_rab_io_commits_info_3_vecWen),
    .rab_io_commits_info_3_vlWen                                (n_rab_io_commits_info_3_vlWen),
    .rab_io_commits_info_4_fpWen                                (n_rab_io_commits_info_4_fpWen),
    .rab_io_commits_info_4_isMove                               (n_rab_io_commits_info_4_isMove),
    .rab_io_commits_info_4_ldest                                (n_rab_io_commits_info_4_ldest),
    .rab_io_commits_info_4_pdest                                (n_rab_io_commits_info_4_pdest),
    .rab_io_commits_info_4_rfWen                                (n_rab_io_commits_info_4_rfWen),
    .rab_io_commits_info_4_v0Wen                                (n_rab_io_commits_info_4_v0Wen),
    .rab_io_commits_info_4_vecWen                               (n_rab_io_commits_info_4_vecWen),
    .rab_io_commits_info_4_vlWen                                (n_rab_io_commits_info_4_vlWen),
    .rab_io_commits_info_5_fpWen                                (n_rab_io_commits_info_5_fpWen),
    .rab_io_commits_info_5_isMove                               (n_rab_io_commits_info_5_isMove),
    .rab_io_commits_info_5_ldest                                (n_rab_io_commits_info_5_ldest),
    .rab_io_commits_info_5_pdest                                (n_rab_io_commits_info_5_pdest),
    .rab_io_commits_info_5_rfWen                                (n_rab_io_commits_info_5_rfWen),
    .rab_io_commits_info_5_v0Wen                                (n_rab_io_commits_info_5_v0Wen),
    .rab_io_commits_info_5_vecWen                               (n_rab_io_commits_info_5_vecWen),
    .rab_io_commits_info_5_vlWen                                (n_rab_io_commits_info_5_vlWen),
    .rab_io_commits_isCommit                                    (n_rab_io_commits_isCommit),
    .rab_io_commits_isWalk                                      (n_rab_io_commits_isWalk),
    .rab_io_commits_walkValid_0                                 (n_rab_io_commits_walkValid_0),
    .rab_io_commits_walkValid_1                                 (n_rab_io_commits_walkValid_1),
    .rab_io_commits_walkValid_2                                 (n_rab_io_commits_walkValid_2),
    .rab_io_commits_walkValid_3                                 (n_rab_io_commits_walkValid_3),
    .rab_io_commits_walkValid_4                                 (n_rab_io_commits_walkValid_4),
    .rab_io_commits_walkValid_5                                 (n_rab_io_commits_walkValid_5),
    .rab_io_status_commitEnd                                    (n_rab_io_status_commitEnd),
    .rab_io_status_walkEnd                                      (n_rab_io_status_walkEnd),
    .snapshots_snapshotGen_io_snapshots_0_0_flag                (n_snapshots_snapshotGen_io_snapshots_0_0_flag),
    .snapshots_snapshotGen_io_snapshots_0_0_value               (n_snapshots_snapshotGen_io_snapshots_0_0_value),
    .snapshots_snapshotGen_io_snapshots_1_0_flag                (n_snapshots_snapshotGen_io_snapshots_1_0_flag),
    .snapshots_snapshotGen_io_snapshots_1_0_value               (n_snapshots_snapshotGen_io_snapshots_1_0_value),
    .snapshots_snapshotGen_io_snapshots_2_0_flag                (n_snapshots_snapshotGen_io_snapshots_2_0_flag),
    .snapshots_snapshotGen_io_snapshots_2_0_value               (n_snapshots_snapshotGen_io_snapshots_2_0_value),
    .snapshots_snapshotGen_io_snapshots_3_0_flag                (n_snapshots_snapshotGen_io_snapshots_3_0_flag),
    .snapshots_snapshotGen_io_snapshots_3_0_value               (n_snapshots_snapshotGen_io_snapshots_3_0_value),
    .vtypeBuffer_io_canEnq                                      (n_vtypeBuffer_io_canEnq),
    .vtypeBuffer_io_canEnqForDispatch                           (n_vtypeBuffer_io_canEnqForDispatch),
    .vtypeBuffer_io_status_walkEnd                              (n_vtypeBuffer_io_status_walkEnd),
    .vtypeBuffer_io_toDecode_isResumeVType                      (n_vtypeBuffer_io_toDecode_isResumeVType)
  );
  // END GENERATED

  // BEGIN GENERATED(children)
  // RenameBuffer -- symmetric blackbox (neither side gets a body); Rob is conditional on its own signoff.
  RenameBuffer rab (
    .clock                                      (clock),
    .reset                                      (reset),
    .io_redirect_valid                          (io_redirect_valid),
    .io_req_0_valid                             (n_canEnqueueEG_0),   // <- core
    .io_req_0_bits_ldest                        (io_enq_req_0_bits_ldest),
    .io_req_0_bits_rfWen                        (io_enq_req_0_bits_rfWen),
    .io_req_0_bits_fpWen                        (io_enq_req_0_bits_fpWen),
    .io_req_0_bits_vecWen                       (io_enq_req_0_bits_vecWen),
    .io_req_0_bits_v0Wen                        (io_enq_req_0_bits_v0Wen),
    .io_req_0_bits_vlWen                        (io_enq_req_0_bits_vlWen),
    .io_req_0_bits_isMove                       (io_enq_req_0_bits_isMove),
    .io_req_0_bits_pdest                        (io_enq_req_0_bits_pdest),
    .io_req_1_valid                             (n_canEnqueueEG_1),   // <- core
    .io_req_1_bits_ldest                        (io_enq_req_1_bits_ldest),
    .io_req_1_bits_rfWen                        (io_enq_req_1_bits_rfWen),
    .io_req_1_bits_fpWen                        (io_enq_req_1_bits_fpWen),
    .io_req_1_bits_vecWen                       (io_enq_req_1_bits_vecWen),
    .io_req_1_bits_v0Wen                        (io_enq_req_1_bits_v0Wen),
    .io_req_1_bits_vlWen                        (io_enq_req_1_bits_vlWen),
    .io_req_1_bits_isMove                       (io_enq_req_1_bits_isMove),
    .io_req_1_bits_pdest                        (io_enq_req_1_bits_pdest),
    .io_req_2_valid                             (n_canEnqueueEG_2),   // <- core
    .io_req_2_bits_ldest                        (io_enq_req_2_bits_ldest),
    .io_req_2_bits_rfWen                        (io_enq_req_2_bits_rfWen),
    .io_req_2_bits_fpWen                        (io_enq_req_2_bits_fpWen),
    .io_req_2_bits_vecWen                       (io_enq_req_2_bits_vecWen),
    .io_req_2_bits_v0Wen                        (io_enq_req_2_bits_v0Wen),
    .io_req_2_bits_vlWen                        (io_enq_req_2_bits_vlWen),
    .io_req_2_bits_isMove                       (io_enq_req_2_bits_isMove),
    .io_req_2_bits_pdest                        (io_enq_req_2_bits_pdest),
    .io_req_3_valid                             (n_canEnqueueEG_3),   // <- core
    .io_req_3_bits_ldest                        (io_enq_req_3_bits_ldest),
    .io_req_3_bits_rfWen                        (io_enq_req_3_bits_rfWen),
    .io_req_3_bits_fpWen                        (io_enq_req_3_bits_fpWen),
    .io_req_3_bits_vecWen                       (io_enq_req_3_bits_vecWen),
    .io_req_3_bits_v0Wen                        (io_enq_req_3_bits_v0Wen),
    .io_req_3_bits_vlWen                        (io_enq_req_3_bits_vlWen),
    .io_req_3_bits_isMove                       (io_enq_req_3_bits_isMove),
    .io_req_3_bits_pdest                        (io_enq_req_3_bits_pdest),
    .io_req_4_valid                             (n_canEnqueueEG_4),   // <- core
    .io_req_4_bits_ldest                        (io_enq_req_4_bits_ldest),
    .io_req_4_bits_rfWen                        (io_enq_req_4_bits_rfWen),
    .io_req_4_bits_fpWen                        (io_enq_req_4_bits_fpWen),
    .io_req_4_bits_vecWen                       (io_enq_req_4_bits_vecWen),
    .io_req_4_bits_v0Wen                        (io_enq_req_4_bits_v0Wen),
    .io_req_4_bits_vlWen                        (io_enq_req_4_bits_vlWen),
    .io_req_4_bits_isMove                       (io_enq_req_4_bits_isMove),
    .io_req_4_bits_pdest                        (io_enq_req_4_bits_pdest),
    .io_req_5_valid                             (n_canEnqueueEG_5),   // <- core
    .io_req_5_bits_ldest                        (io_enq_req_5_bits_ldest),
    .io_req_5_bits_rfWen                        (io_enq_req_5_bits_rfWen),
    .io_req_5_bits_fpWen                        (io_enq_req_5_bits_fpWen),
    .io_req_5_bits_vecWen                       (io_enq_req_5_bits_vecWen),
    .io_req_5_bits_v0Wen                        (io_enq_req_5_bits_v0Wen),
    .io_req_5_bits_vlWen                        (io_enq_req_5_bits_vlWen),
    .io_req_5_bits_isMove                       (io_enq_req_5_bits_isMove),
    .io_req_5_bits_pdest                        (io_enq_req_5_bits_pdest),
    .io_fromRob_walkSize                        (n_rab_io_fromRob_walkSize),
    .io_fromRob_walkEnd                         (n_rab_io_fromRob_walkEnd),
    .io_fromRob_commitSize                      (n_rab_io_fromRob_commitSize),
    .io_fromRob_vecLoadExcp_valid               (n_rab_io_fromRob_vecLoadExcp_valid_REGOut),   // <- core
    .io_snpt_snptEnq                            (n_snptEnq),   // <- core
    .io_snpt_snptDeq                            (io_snpt_snptDeq),
    .io_snpt_useSnpt                            (io_snpt_useSnpt),
    .io_snpt_snptSelect                         (io_snpt_snptSelect),
    .io_snpt_flushVec_0                         (io_snpt_flushVec_0),
    .io_snpt_flushVec_1                         (io_snpt_flushVec_1),
    .io_snpt_flushVec_2                         (io_snpt_flushVec_2),
    .io_snpt_flushVec_3                         (io_snpt_flushVec_3),
    .io_canEnq                                  (n_rab_io_canEnq),   // -> core
    .io_canEnqForDispatch                       (n_rab_io_canEnqForDispatch),   // -> core
    .io_commits_isCommit                        (n_rab_io_commits_isCommit),   // -> core
    .io_commits_commitValid_0                   (n_rab_io_commits_commitValid_0),   // -> core
    .io_commits_commitValid_1                   (n_rab_io_commits_commitValid_1),   // -> core
    .io_commits_commitValid_2                   (n_rab_io_commits_commitValid_2),   // -> core
    .io_commits_commitValid_3                   (n_rab_io_commits_commitValid_3),   // -> core
    .io_commits_commitValid_4                   (n_rab_io_commits_commitValid_4),   // -> core
    .io_commits_commitValid_5                   (n_rab_io_commits_commitValid_5),   // -> core
    .io_commits_isWalk                          (n_rab_io_commits_isWalk),   // -> core
    .io_commits_walkValid_0                     (n_rab_io_commits_walkValid_0),   // -> core
    .io_commits_walkValid_1                     (n_rab_io_commits_walkValid_1),   // -> core
    .io_commits_walkValid_2                     (n_rab_io_commits_walkValid_2),   // -> core
    .io_commits_walkValid_3                     (n_rab_io_commits_walkValid_3),   // -> core
    .io_commits_walkValid_4                     (n_rab_io_commits_walkValid_4),   // -> core
    .io_commits_walkValid_5                     (n_rab_io_commits_walkValid_5),   // -> core
    .io_commits_info_0_ldest                    (n_rab_io_commits_info_0_ldest),   // -> core
    .io_commits_info_0_pdest                    (n_rab_io_commits_info_0_pdest),   // -> core
    .io_commits_info_0_rfWen                    (n_rab_io_commits_info_0_rfWen),   // -> core
    .io_commits_info_0_fpWen                    (n_rab_io_commits_info_0_fpWen),   // -> core
    .io_commits_info_0_vecWen                   (n_rab_io_commits_info_0_vecWen),   // -> core
    .io_commits_info_0_v0Wen                    (n_rab_io_commits_info_0_v0Wen),   // -> core
    .io_commits_info_0_vlWen                    (n_rab_io_commits_info_0_vlWen),   // -> core
    .io_commits_info_0_isMove                   (n_rab_io_commits_info_0_isMove),   // -> core
    .io_commits_info_1_ldest                    (n_rab_io_commits_info_1_ldest),   // -> core
    .io_commits_info_1_pdest                    (n_rab_io_commits_info_1_pdest),   // -> core
    .io_commits_info_1_rfWen                    (n_rab_io_commits_info_1_rfWen),   // -> core
    .io_commits_info_1_fpWen                    (n_rab_io_commits_info_1_fpWen),   // -> core
    .io_commits_info_1_vecWen                   (n_rab_io_commits_info_1_vecWen),   // -> core
    .io_commits_info_1_v0Wen                    (n_rab_io_commits_info_1_v0Wen),   // -> core
    .io_commits_info_1_vlWen                    (n_rab_io_commits_info_1_vlWen),   // -> core
    .io_commits_info_1_isMove                   (n_rab_io_commits_info_1_isMove),   // -> core
    .io_commits_info_2_ldest                    (n_rab_io_commits_info_2_ldest),   // -> core
    .io_commits_info_2_pdest                    (n_rab_io_commits_info_2_pdest),   // -> core
    .io_commits_info_2_rfWen                    (n_rab_io_commits_info_2_rfWen),   // -> core
    .io_commits_info_2_fpWen                    (n_rab_io_commits_info_2_fpWen),   // -> core
    .io_commits_info_2_vecWen                   (n_rab_io_commits_info_2_vecWen),   // -> core
    .io_commits_info_2_v0Wen                    (n_rab_io_commits_info_2_v0Wen),   // -> core
    .io_commits_info_2_vlWen                    (n_rab_io_commits_info_2_vlWen),   // -> core
    .io_commits_info_2_isMove                   (n_rab_io_commits_info_2_isMove),   // -> core
    .io_commits_info_3_ldest                    (n_rab_io_commits_info_3_ldest),   // -> core
    .io_commits_info_3_pdest                    (n_rab_io_commits_info_3_pdest),   // -> core
    .io_commits_info_3_rfWen                    (n_rab_io_commits_info_3_rfWen),   // -> core
    .io_commits_info_3_fpWen                    (n_rab_io_commits_info_3_fpWen),   // -> core
    .io_commits_info_3_vecWen                   (n_rab_io_commits_info_3_vecWen),   // -> core
    .io_commits_info_3_v0Wen                    (n_rab_io_commits_info_3_v0Wen),   // -> core
    .io_commits_info_3_vlWen                    (n_rab_io_commits_info_3_vlWen),   // -> core
    .io_commits_info_3_isMove                   (n_rab_io_commits_info_3_isMove),   // -> core
    .io_commits_info_4_ldest                    (n_rab_io_commits_info_4_ldest),   // -> core
    .io_commits_info_4_pdest                    (n_rab_io_commits_info_4_pdest),   // -> core
    .io_commits_info_4_rfWen                    (n_rab_io_commits_info_4_rfWen),   // -> core
    .io_commits_info_4_fpWen                    (n_rab_io_commits_info_4_fpWen),   // -> core
    .io_commits_info_4_vecWen                   (n_rab_io_commits_info_4_vecWen),   // -> core
    .io_commits_info_4_v0Wen                    (n_rab_io_commits_info_4_v0Wen),   // -> core
    .io_commits_info_4_vlWen                    (n_rab_io_commits_info_4_vlWen),   // -> core
    .io_commits_info_4_isMove                   (n_rab_io_commits_info_4_isMove),   // -> core
    .io_commits_info_5_ldest                    (n_rab_io_commits_info_5_ldest),   // -> core
    .io_commits_info_5_pdest                    (n_rab_io_commits_info_5_pdest),   // -> core
    .io_commits_info_5_rfWen                    (n_rab_io_commits_info_5_rfWen),   // -> core
    .io_commits_info_5_fpWen                    (n_rab_io_commits_info_5_fpWen),   // -> core
    .io_commits_info_5_vecWen                   (n_rab_io_commits_info_5_vecWen),   // -> core
    .io_commits_info_5_v0Wen                    (n_rab_io_commits_info_5_v0Wen),   // -> core
    .io_commits_info_5_vlWen                    (n_rab_io_commits_info_5_vlWen),   // -> core
    .io_commits_info_5_isMove                   (n_rab_io_commits_info_5_isMove),   // -> core
    .io_status_walkEnd                          (n_rab_io_status_walkEnd),   // -> core
    .io_status_commitEnd                        (n_rab_io_status_commitEnd),   // -> core
    .io_toVecExcpMod_logicPhyRegMap_0_valid     (io_toVecExcpMod_logicPhyRegMap_0_valid),
    .io_toVecExcpMod_logicPhyRegMap_0_bits_lreg (io_toVecExcpMod_logicPhyRegMap_0_bits_lreg),
    .io_toVecExcpMod_logicPhyRegMap_0_bits_preg (io_toVecExcpMod_logicPhyRegMap_0_bits_preg),
    .io_toVecExcpMod_logicPhyRegMap_1_valid     (io_toVecExcpMod_logicPhyRegMap_1_valid),
    .io_toVecExcpMod_logicPhyRegMap_1_bits_lreg (io_toVecExcpMod_logicPhyRegMap_1_bits_lreg),
    .io_toVecExcpMod_logicPhyRegMap_1_bits_preg (io_toVecExcpMod_logicPhyRegMap_1_bits_preg),
    .io_toVecExcpMod_logicPhyRegMap_2_valid     (io_toVecExcpMod_logicPhyRegMap_2_valid),
    .io_toVecExcpMod_logicPhyRegMap_2_bits_lreg (io_toVecExcpMod_logicPhyRegMap_2_bits_lreg),
    .io_toVecExcpMod_logicPhyRegMap_2_bits_preg (io_toVecExcpMod_logicPhyRegMap_2_bits_preg),
    .io_toVecExcpMod_logicPhyRegMap_3_valid     (io_toVecExcpMod_logicPhyRegMap_3_valid),
    .io_toVecExcpMod_logicPhyRegMap_3_bits_lreg (io_toVecExcpMod_logicPhyRegMap_3_bits_lreg),
    .io_toVecExcpMod_logicPhyRegMap_3_bits_preg (io_toVecExcpMod_logicPhyRegMap_3_bits_preg),
    .io_toVecExcpMod_logicPhyRegMap_4_valid     (io_toVecExcpMod_logicPhyRegMap_4_valid),
    .io_toVecExcpMod_logicPhyRegMap_4_bits_lreg (io_toVecExcpMod_logicPhyRegMap_4_bits_lreg),
    .io_toVecExcpMod_logicPhyRegMap_4_bits_preg (io_toVecExcpMod_logicPhyRegMap_4_bits_preg),
    .io_toVecExcpMod_logicPhyRegMap_5_valid     (io_toVecExcpMod_logicPhyRegMap_5_valid),
    .io_toVecExcpMod_logicPhyRegMap_5_bits_lreg (io_toVecExcpMod_logicPhyRegMap_5_bits_lreg),
    .io_toVecExcpMod_logicPhyRegMap_5_bits_preg (io_toVecExcpMod_logicPhyRegMap_5_bits_preg)
  );

  // VTypeBuffer -- symmetric blackbox (neither side gets a body); Rob is conditional on its own signoff.
  VTypeBuffer vtypeBuffer (
    .clock                                      (clock),
    .reset                                      (reset),
    .io_redirect_valid                          (io_redirect_valid),
    .io_req_0_valid                             (n_canEnqueueEG_0),   // <- core
    .io_req_0_bits_fuOpType                     (io_enq_req_0_bits_fuOpType),
    .io_req_0_bits_vpu_vill                     (io_enq_req_0_bits_vpu_vill),
    .io_req_0_bits_vpu_vma                      (io_enq_req_0_bits_vpu_vma),
    .io_req_0_bits_vpu_vta                      (io_enq_req_0_bits_vpu_vta),
    .io_req_0_bits_vpu_vsew                     (io_enq_req_0_bits_vpu_vsew),
    .io_req_0_bits_vpu_vlmul                    (io_enq_req_0_bits_vpu_vlmul),
    .io_req_0_bits_vpu_specVill                 (io_enq_req_0_bits_vpu_specVill),
    .io_req_0_bits_vpu_specVma                  (io_enq_req_0_bits_vpu_specVma),
    .io_req_0_bits_vpu_specVta                  (io_enq_req_0_bits_vpu_specVta),
    .io_req_0_bits_vpu_specVsew                 (io_enq_req_0_bits_vpu_specVsew),
    .io_req_0_bits_vpu_specVlmul                (io_enq_req_0_bits_vpu_specVlmul),
    .io_req_0_bits_isVset                       (io_enq_req_0_bits_isVset),
    .io_req_0_bits_lastUop                      (io_enq_req_0_bits_lastUop),
    .io_req_1_valid                             (n_canEnqueueEG_1),   // <- core
    .io_req_1_bits_fuOpType                     (io_enq_req_1_bits_fuOpType),
    .io_req_1_bits_vpu_vill                     (io_enq_req_1_bits_vpu_vill),
    .io_req_1_bits_vpu_vma                      (io_enq_req_1_bits_vpu_vma),
    .io_req_1_bits_vpu_vta                      (io_enq_req_1_bits_vpu_vta),
    .io_req_1_bits_vpu_vsew                     (io_enq_req_1_bits_vpu_vsew),
    .io_req_1_bits_vpu_vlmul                    (io_enq_req_1_bits_vpu_vlmul),
    .io_req_1_bits_vpu_specVill                 (io_enq_req_1_bits_vpu_specVill),
    .io_req_1_bits_vpu_specVma                  (io_enq_req_1_bits_vpu_specVma),
    .io_req_1_bits_vpu_specVta                  (io_enq_req_1_bits_vpu_specVta),
    .io_req_1_bits_vpu_specVsew                 (io_enq_req_1_bits_vpu_specVsew),
    .io_req_1_bits_vpu_specVlmul                (io_enq_req_1_bits_vpu_specVlmul),
    .io_req_1_bits_isVset                       (io_enq_req_1_bits_isVset),
    .io_req_1_bits_lastUop                      (io_enq_req_1_bits_lastUop),
    .io_req_2_valid                             (n_canEnqueueEG_2),   // <- core
    .io_req_2_bits_fuOpType                     (io_enq_req_2_bits_fuOpType),
    .io_req_2_bits_vpu_vill                     (io_enq_req_2_bits_vpu_vill),
    .io_req_2_bits_vpu_vma                      (io_enq_req_2_bits_vpu_vma),
    .io_req_2_bits_vpu_vta                      (io_enq_req_2_bits_vpu_vta),
    .io_req_2_bits_vpu_vsew                     (io_enq_req_2_bits_vpu_vsew),
    .io_req_2_bits_vpu_vlmul                    (io_enq_req_2_bits_vpu_vlmul),
    .io_req_2_bits_vpu_specVill                 (io_enq_req_2_bits_vpu_specVill),
    .io_req_2_bits_vpu_specVma                  (io_enq_req_2_bits_vpu_specVma),
    .io_req_2_bits_vpu_specVta                  (io_enq_req_2_bits_vpu_specVta),
    .io_req_2_bits_vpu_specVsew                 (io_enq_req_2_bits_vpu_specVsew),
    .io_req_2_bits_vpu_specVlmul                (io_enq_req_2_bits_vpu_specVlmul),
    .io_req_2_bits_isVset                       (io_enq_req_2_bits_isVset),
    .io_req_2_bits_lastUop                      (io_enq_req_2_bits_lastUop),
    .io_req_3_valid                             (n_canEnqueueEG_3),   // <- core
    .io_req_3_bits_fuOpType                     (io_enq_req_3_bits_fuOpType),
    .io_req_3_bits_vpu_vill                     (io_enq_req_3_bits_vpu_vill),
    .io_req_3_bits_vpu_vma                      (io_enq_req_3_bits_vpu_vma),
    .io_req_3_bits_vpu_vta                      (io_enq_req_3_bits_vpu_vta),
    .io_req_3_bits_vpu_vsew                     (io_enq_req_3_bits_vpu_vsew),
    .io_req_3_bits_vpu_vlmul                    (io_enq_req_3_bits_vpu_vlmul),
    .io_req_3_bits_vpu_specVill                 (io_enq_req_3_bits_vpu_specVill),
    .io_req_3_bits_vpu_specVma                  (io_enq_req_3_bits_vpu_specVma),
    .io_req_3_bits_vpu_specVta                  (io_enq_req_3_bits_vpu_specVta),
    .io_req_3_bits_vpu_specVsew                 (io_enq_req_3_bits_vpu_specVsew),
    .io_req_3_bits_vpu_specVlmul                (io_enq_req_3_bits_vpu_specVlmul),
    .io_req_3_bits_isVset                       (io_enq_req_3_bits_isVset),
    .io_req_3_bits_lastUop                      (io_enq_req_3_bits_lastUop),
    .io_req_4_valid                             (n_canEnqueueEG_4),   // <- core
    .io_req_4_bits_fuOpType                     (io_enq_req_4_bits_fuOpType),
    .io_req_4_bits_vpu_vill                     (io_enq_req_4_bits_vpu_vill),
    .io_req_4_bits_vpu_vma                      (io_enq_req_4_bits_vpu_vma),
    .io_req_4_bits_vpu_vta                      (io_enq_req_4_bits_vpu_vta),
    .io_req_4_bits_vpu_vsew                     (io_enq_req_4_bits_vpu_vsew),
    .io_req_4_bits_vpu_vlmul                    (io_enq_req_4_bits_vpu_vlmul),
    .io_req_4_bits_vpu_specVill                 (io_enq_req_4_bits_vpu_specVill),
    .io_req_4_bits_vpu_specVma                  (io_enq_req_4_bits_vpu_specVma),
    .io_req_4_bits_vpu_specVta                  (io_enq_req_4_bits_vpu_specVta),
    .io_req_4_bits_vpu_specVsew                 (io_enq_req_4_bits_vpu_specVsew),
    .io_req_4_bits_vpu_specVlmul                (io_enq_req_4_bits_vpu_specVlmul),
    .io_req_4_bits_isVset                       (io_enq_req_4_bits_isVset),
    .io_req_4_bits_lastUop                      (io_enq_req_4_bits_lastUop),
    .io_req_5_valid                             (n_canEnqueueEG_5),   // <- core
    .io_req_5_bits_fuOpType                     (io_enq_req_5_bits_fuOpType),
    .io_req_5_bits_vpu_vill                     (io_enq_req_5_bits_vpu_vill),
    .io_req_5_bits_vpu_vma                      (io_enq_req_5_bits_vpu_vma),
    .io_req_5_bits_vpu_vta                      (io_enq_req_5_bits_vpu_vta),
    .io_req_5_bits_vpu_vsew                     (io_enq_req_5_bits_vpu_vsew),
    .io_req_5_bits_vpu_vlmul                    (io_enq_req_5_bits_vpu_vlmul),
    .io_req_5_bits_vpu_specVill                 (io_enq_req_5_bits_vpu_specVill),
    .io_req_5_bits_vpu_specVma                  (io_enq_req_5_bits_vpu_specVma),
    .io_req_5_bits_vpu_specVta                  (io_enq_req_5_bits_vpu_specVta),
    .io_req_5_bits_vpu_specVsew                 (io_enq_req_5_bits_vpu_specVsew),
    .io_req_5_bits_vpu_specVlmul                (io_enq_req_5_bits_vpu_specVlmul),
    .io_req_5_bits_isVset                       (io_enq_req_5_bits_isVset),
    .io_req_5_bits_lastUop                      (io_enq_req_5_bits_lastUop),
    .io_fromRob_walkSize                        (n_vtypeBuffer_io_fromRob_walkSize),
    .io_fromRob_walkEnd                         (n_vtypeBuffer_io_fromRob_walkEnd),
    .io_fromRob_commitSize                      (n_vtypeBuffer_io_fromRob_commitSize),
    .io_snpt_snptEnq                            (n_snptEnq),   // <- core
    .io_snpt_snptDeq                            (io_snpt_snptDeq),
    .io_snpt_useSnpt                            (io_snpt_useSnpt),
    .io_snpt_snptSelect                         (io_snpt_snptSelect),
    .io_snpt_flushVec_0                         (io_snpt_flushVec_0),
    .io_snpt_flushVec_1                         (io_snpt_flushVec_1),
    .io_snpt_flushVec_2                         (io_snpt_flushVec_2),
    .io_snpt_flushVec_3                         (io_snpt_flushVec_3),
    .io_canEnq                                  (n_vtypeBuffer_io_canEnq),   // -> core
    .io_canEnqForDispatch                       (n_vtypeBuffer_io_canEnqForDispatch),   // -> core
    .io_toDecode_isResumeVType                  (n_vtypeBuffer_io_toDecode_isResumeVType),   // -> core
    .io_toDecode_walkToArchVType                (io_toDecode_walkToArchVType),
    .io_toDecode_walkVType_valid                (io_toDecode_walkVType_valid),
    .io_toDecode_walkVType_bits_illegal         (io_toDecode_walkVType_bits_illegal),
    .io_toDecode_walkVType_bits_vma             (io_toDecode_walkVType_bits_vma),
    .io_toDecode_walkVType_bits_vta             (io_toDecode_walkVType_bits_vta),
    .io_toDecode_walkVType_bits_vsew            (io_toDecode_walkVType_bits_vsew),
    .io_toDecode_walkVType_bits_vlmul           (io_toDecode_walkVType_bits_vlmul),
    .io_toDecode_commitVType_vtype_valid        (io_toDecode_commitVType_vtype_valid),
    .io_toDecode_commitVType_vtype_bits_illegal (io_toDecode_commitVType_vtype_bits_illegal),
    .io_toDecode_commitVType_vtype_bits_vma     (io_toDecode_commitVType_vtype_bits_vma),
    .io_toDecode_commitVType_vtype_bits_vta     (io_toDecode_commitVType_vtype_bits_vta),
    .io_toDecode_commitVType_vtype_bits_vsew    (io_toDecode_commitVType_vtype_bits_vsew),
    .io_toDecode_commitVType_vtype_bits_vlmul   (io_toDecode_commitVType_vtype_bits_vlmul),
    .io_toDecode_commitVType_hasVsetvl          (io_toDecode_commitVType_hasVsetvl),
    .io_status_walkEnd                          (n_vtypeBuffer_io_status_walkEnd)   // -> core
  );

  // SnapshotGenerator_3 -- symmetric blackbox (neither side gets a body); Rob is conditional on its own signoff.
  SnapshotGenerator_3 snapshots_snapshotGen (
    .clock                  (clock),
    .reset                  (reset),
    .io_enq                 (n_snptEnq),   // <- core
    .io_enqData_0_flag      (io_enq_req_0_bits_robIdx_flag),
    .io_enqData_0_value     (io_enq_req_0_bits_robIdx_value),
    .io_deq                 (io_snpt_snptDeq),
    .io_redirect            (io_redirect_valid),
    .io_flushVec_0          (io_snpt_flushVec_0),
    .io_flushVec_1          (io_snpt_flushVec_1),
    .io_flushVec_2          (io_snpt_flushVec_2),
    .io_flushVec_3          (io_snpt_flushVec_3),
    .io_snapshots_0_0_flag  (n_snapshots_snapshotGen_io_snapshots_0_0_flag),   // -> core
    .io_snapshots_0_0_value (n_snapshots_snapshotGen_io_snapshots_0_0_value),   // -> core
    .io_snapshots_1_0_flag  (n_snapshots_snapshotGen_io_snapshots_1_0_flag),   // -> core
    .io_snapshots_1_0_value (n_snapshots_snapshotGen_io_snapshots_1_0_value),   // -> core
    .io_snapshots_2_0_flag  (n_snapshots_snapshotGen_io_snapshots_2_0_flag),   // -> core
    .io_snapshots_2_0_value (n_snapshots_snapshotGen_io_snapshots_2_0_value),   // -> core
    .io_snapshots_3_0_flag  (n_snapshots_snapshotGen_io_snapshots_3_0_flag),   // -> core
    .io_snapshots_3_0_value (n_snapshots_snapshotGen_io_snapshots_3_0_value)   // -> core
  );

  // ExceptionGen -- symmetric blackbox (neither side gets a body); Rob is conditional on its own signoff.
  ExceptionGen exceptionGen (
    .clock                                  (clock),
    .reset                                  (reset),
    .io_redirect_valid                      (io_redirect_valid),
    .io_redirect_bits_robIdx_flag           (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value          (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level                 (io_redirect_bits_level),
    .io_flush                               (n_io_flushOut_valid_0),   // <- core
    .io_enq_0_valid                         (n_canEnqueueEG_0),   // <- core
    .io_enq_0_bits_robIdx_flag              (io_enq_req_0_bits_robIdx_flag),
    .io_enq_0_bits_robIdx_value             (io_enq_req_0_bits_robIdx_value),
    .io_enq_0_bits_ftqPtr_value             (io_enq_req_0_bits_ftqPtr_value),
    .io_enq_0_bits_ftqOffset                (io_enq_req_0_bits_ftqOffset),
    .io_enq_0_bits_hasException             (io_enq_req_0_bits_hasException),
    .io_enq_0_bits_exceptionVec_0           (io_enq_req_0_bits_exceptionVec_0),
    .io_enq_0_bits_exceptionVec_1           (io_enq_req_0_bits_exceptionVec_1),
    .io_enq_0_bits_exceptionVec_2           (io_enq_req_0_bits_exceptionVec_2),
    .io_enq_0_bits_exceptionVec_3           (io_enq_req_0_bits_exceptionVec_3),
    .io_enq_0_bits_exceptionVec_12          (io_enq_req_0_bits_exceptionVec_12),
    .io_enq_0_bits_exceptionVec_20          (io_enq_req_0_bits_exceptionVec_20),
    .io_enq_0_bits_exceptionVec_22          (io_enq_req_0_bits_exceptionVec_22),
    .io_enq_0_bits_isFetchMalAddr           (io_enq_req_0_bits_isFetchMalAddr),
    .io_enq_0_bits_satpFlushFirstFetchFault (io_enq_req_0_bits_satpFlushFirstFetchFault),
    .io_enq_0_bits_flushPipe                (io_enq_req_0_bits_flushPipe),
    .io_enq_0_bits_isVset                   (io_enq_req_0_bits_isVset),
    .io_enq_0_bits_singleStep               (io_enq_req_0_bits_singleStep),
    .io_enq_0_bits_crossPageIPFFix          (io_enq_req_0_bits_crossPageIPFFix),
    .io_enq_0_bits_trigger                  (io_enq_req_0_bits_trigger),
    .io_enq_1_valid                         (n_canEnqueueEG_1),   // <- core
    .io_enq_1_bits_robIdx_flag              (io_enq_req_1_bits_robIdx_flag),
    .io_enq_1_bits_robIdx_value             (io_enq_req_1_bits_robIdx_value),
    .io_enq_1_bits_ftqPtr_value             (io_enq_req_1_bits_ftqPtr_value),
    .io_enq_1_bits_ftqOffset                (io_enq_req_1_bits_ftqOffset),
    .io_enq_1_bits_hasException             (io_enq_req_1_bits_hasException),
    .io_enq_1_bits_exceptionVec_0           (io_enq_req_1_bits_exceptionVec_0),
    .io_enq_1_bits_exceptionVec_1           (io_enq_req_1_bits_exceptionVec_1),
    .io_enq_1_bits_exceptionVec_2           (io_enq_req_1_bits_exceptionVec_2),
    .io_enq_1_bits_exceptionVec_3           (io_enq_req_1_bits_exceptionVec_3),
    .io_enq_1_bits_exceptionVec_12          (io_enq_req_1_bits_exceptionVec_12),
    .io_enq_1_bits_exceptionVec_20          (io_enq_req_1_bits_exceptionVec_20),
    .io_enq_1_bits_exceptionVec_22          (io_enq_req_1_bits_exceptionVec_22),
    .io_enq_1_bits_isFetchMalAddr           (io_enq_req_1_bits_isFetchMalAddr),
    .io_enq_1_bits_satpFlushFirstFetchFault (io_enq_req_1_bits_satpFlushFirstFetchFault),
    .io_enq_1_bits_flushPipe                (io_enq_req_1_bits_flushPipe),
    .io_enq_1_bits_isVset                   (io_enq_req_1_bits_isVset),
    .io_enq_1_bits_singleStep               (io_enq_req_1_bits_singleStep),
    .io_enq_1_bits_crossPageIPFFix          (io_enq_req_1_bits_crossPageIPFFix),
    .io_enq_1_bits_trigger                  (io_enq_req_1_bits_trigger),
    .io_enq_2_valid                         (n_canEnqueueEG_2),   // <- core
    .io_enq_2_bits_robIdx_flag              (io_enq_req_2_bits_robIdx_flag),
    .io_enq_2_bits_robIdx_value             (io_enq_req_2_bits_robIdx_value),
    .io_enq_2_bits_ftqPtr_value             (io_enq_req_2_bits_ftqPtr_value),
    .io_enq_2_bits_ftqOffset                (io_enq_req_2_bits_ftqOffset),
    .io_enq_2_bits_hasException             (io_enq_req_2_bits_hasException),
    .io_enq_2_bits_exceptionVec_0           (io_enq_req_2_bits_exceptionVec_0),
    .io_enq_2_bits_exceptionVec_1           (io_enq_req_2_bits_exceptionVec_1),
    .io_enq_2_bits_exceptionVec_2           (io_enq_req_2_bits_exceptionVec_2),
    .io_enq_2_bits_exceptionVec_3           (io_enq_req_2_bits_exceptionVec_3),
    .io_enq_2_bits_exceptionVec_12          (io_enq_req_2_bits_exceptionVec_12),
    .io_enq_2_bits_exceptionVec_20          (io_enq_req_2_bits_exceptionVec_20),
    .io_enq_2_bits_exceptionVec_22          (io_enq_req_2_bits_exceptionVec_22),
    .io_enq_2_bits_isFetchMalAddr           (io_enq_req_2_bits_isFetchMalAddr),
    .io_enq_2_bits_satpFlushFirstFetchFault (io_enq_req_2_bits_satpFlushFirstFetchFault),
    .io_enq_2_bits_flushPipe                (io_enq_req_2_bits_flushPipe),
    .io_enq_2_bits_isVset                   (io_enq_req_2_bits_isVset),
    .io_enq_2_bits_singleStep               (io_enq_req_2_bits_singleStep),
    .io_enq_2_bits_crossPageIPFFix          (io_enq_req_2_bits_crossPageIPFFix),
    .io_enq_2_bits_trigger                  (io_enq_req_2_bits_trigger),
    .io_enq_3_valid                         (n_canEnqueueEG_3),   // <- core
    .io_enq_3_bits_robIdx_flag              (io_enq_req_3_bits_robIdx_flag),
    .io_enq_3_bits_robIdx_value             (io_enq_req_3_bits_robIdx_value),
    .io_enq_3_bits_ftqPtr_value             (io_enq_req_3_bits_ftqPtr_value),
    .io_enq_3_bits_ftqOffset                (io_enq_req_3_bits_ftqOffset),
    .io_enq_3_bits_hasException             (io_enq_req_3_bits_hasException),
    .io_enq_3_bits_exceptionVec_0           (io_enq_req_3_bits_exceptionVec_0),
    .io_enq_3_bits_exceptionVec_1           (io_enq_req_3_bits_exceptionVec_1),
    .io_enq_3_bits_exceptionVec_2           (io_enq_req_3_bits_exceptionVec_2),
    .io_enq_3_bits_exceptionVec_3           (io_enq_req_3_bits_exceptionVec_3),
    .io_enq_3_bits_exceptionVec_12          (io_enq_req_3_bits_exceptionVec_12),
    .io_enq_3_bits_exceptionVec_20          (io_enq_req_3_bits_exceptionVec_20),
    .io_enq_3_bits_exceptionVec_22          (io_enq_req_3_bits_exceptionVec_22),
    .io_enq_3_bits_isFetchMalAddr           (io_enq_req_3_bits_isFetchMalAddr),
    .io_enq_3_bits_satpFlushFirstFetchFault (io_enq_req_3_bits_satpFlushFirstFetchFault),
    .io_enq_3_bits_flushPipe                (io_enq_req_3_bits_flushPipe),
    .io_enq_3_bits_isVset                   (io_enq_req_3_bits_isVset),
    .io_enq_3_bits_singleStep               (io_enq_req_3_bits_singleStep),
    .io_enq_3_bits_crossPageIPFFix          (io_enq_req_3_bits_crossPageIPFFix),
    .io_enq_3_bits_trigger                  (io_enq_req_3_bits_trigger),
    .io_enq_4_valid                         (n_canEnqueueEG_4),   // <- core
    .io_enq_4_bits_robIdx_flag              (io_enq_req_4_bits_robIdx_flag),
    .io_enq_4_bits_robIdx_value             (io_enq_req_4_bits_robIdx_value),
    .io_enq_4_bits_ftqPtr_value             (io_enq_req_4_bits_ftqPtr_value),
    .io_enq_4_bits_ftqOffset                (io_enq_req_4_bits_ftqOffset),
    .io_enq_4_bits_hasException             (io_enq_req_4_bits_hasException),
    .io_enq_4_bits_exceptionVec_0           (io_enq_req_4_bits_exceptionVec_0),
    .io_enq_4_bits_exceptionVec_1           (io_enq_req_4_bits_exceptionVec_1),
    .io_enq_4_bits_exceptionVec_2           (io_enq_req_4_bits_exceptionVec_2),
    .io_enq_4_bits_exceptionVec_3           (io_enq_req_4_bits_exceptionVec_3),
    .io_enq_4_bits_exceptionVec_12          (io_enq_req_4_bits_exceptionVec_12),
    .io_enq_4_bits_exceptionVec_20          (io_enq_req_4_bits_exceptionVec_20),
    .io_enq_4_bits_exceptionVec_22          (io_enq_req_4_bits_exceptionVec_22),
    .io_enq_4_bits_isFetchMalAddr           (io_enq_req_4_bits_isFetchMalAddr),
    .io_enq_4_bits_satpFlushFirstFetchFault (io_enq_req_4_bits_satpFlushFirstFetchFault),
    .io_enq_4_bits_flushPipe                (io_enq_req_4_bits_flushPipe),
    .io_enq_4_bits_isVset                   (io_enq_req_4_bits_isVset),
    .io_enq_4_bits_singleStep               (io_enq_req_4_bits_singleStep),
    .io_enq_4_bits_crossPageIPFFix          (io_enq_req_4_bits_crossPageIPFFix),
    .io_enq_4_bits_trigger                  (io_enq_req_4_bits_trigger),
    .io_enq_5_valid                         (n_canEnqueueEG_5),   // <- core
    .io_enq_5_bits_robIdx_flag              (io_enq_req_5_bits_robIdx_flag),
    .io_enq_5_bits_robIdx_value             (io_enq_req_5_bits_robIdx_value),
    .io_enq_5_bits_ftqPtr_value             (io_enq_req_5_bits_ftqPtr_value),
    .io_enq_5_bits_ftqOffset                (io_enq_req_5_bits_ftqOffset),
    .io_enq_5_bits_hasException             (io_enq_req_5_bits_hasException),
    .io_enq_5_bits_exceptionVec_0           (io_enq_req_5_bits_exceptionVec_0),
    .io_enq_5_bits_exceptionVec_1           (io_enq_req_5_bits_exceptionVec_1),
    .io_enq_5_bits_exceptionVec_2           (io_enq_req_5_bits_exceptionVec_2),
    .io_enq_5_bits_exceptionVec_3           (io_enq_req_5_bits_exceptionVec_3),
    .io_enq_5_bits_exceptionVec_12          (io_enq_req_5_bits_exceptionVec_12),
    .io_enq_5_bits_exceptionVec_20          (io_enq_req_5_bits_exceptionVec_20),
    .io_enq_5_bits_exceptionVec_22          (io_enq_req_5_bits_exceptionVec_22),
    .io_enq_5_bits_isFetchMalAddr           (io_enq_req_5_bits_isFetchMalAddr),
    .io_enq_5_bits_satpFlushFirstFetchFault (io_enq_req_5_bits_satpFlushFirstFetchFault),
    .io_enq_5_bits_flushPipe                (io_enq_req_5_bits_flushPipe),
    .io_enq_5_bits_isVset                   (io_enq_req_5_bits_isVset),
    .io_enq_5_bits_singleStep               (io_enq_req_5_bits_singleStep),
    .io_enq_5_bits_crossPageIPFFix          (io_enq_req_5_bits_crossPageIPFFix),
    .io_enq_5_bits_trigger                  (io_enq_req_5_bits_trigger),
    .io_wb_0_valid                          (io_writeback_7_valid),
    .io_wb_0_bits_robIdx_flag               (io_writeback_7_bits_robIdx_flag),
    .io_wb_0_bits_robIdx_value              (io_writeback_7_bits_robIdx_value),
    .io_wb_0_bits_hasException              (n_exceptionGen_io_wb_0_bits_hasException),
    .io_wb_0_bits_exceptionVec_2            (io_writeback_7_bits_exceptionVec_2),
    .io_wb_0_bits_exceptionVec_3            (io_writeback_7_bits_exceptionVec_3),
    .io_wb_0_bits_exceptionVec_8            (io_writeback_7_bits_exceptionVec_8),
    .io_wb_0_bits_exceptionVec_9            (io_writeback_7_bits_exceptionVec_9),
    .io_wb_0_bits_exceptionVec_10           (io_writeback_7_bits_exceptionVec_10),
    .io_wb_0_bits_exceptionVec_11           (io_writeback_7_bits_exceptionVec_11),
    .io_wb_0_bits_exceptionVec_22           (io_writeback_7_bits_exceptionVec_22),
    .io_wb_0_bits_flushPipe                 (io_writeback_7_bits_flushPipe),
    .io_wb_0_bits_satpFlushPipe             (io_writeback_7_bits_satpFlushPipe),
    .io_wb_1_valid                          (io_writeback_13_valid),
    .io_wb_1_bits_robIdx_flag               (io_writeback_13_bits_robIdx_flag),
    .io_wb_1_bits_robIdx_value              (io_writeback_13_bits_robIdx_value),
    .io_wb_1_bits_hasException              (io_writeback_13_bits_exceptionVec_2),
    .io_wb_1_bits_exceptionVec_2            (io_writeback_13_bits_exceptionVec_2),
    .io_wb_2_valid                          (io_writeback_14_valid),
    .io_wb_2_bits_robIdx_flag               (io_writeback_14_bits_robIdx_flag),
    .io_wb_2_bits_robIdx_value              (io_writeback_14_bits_robIdx_value),
    .io_wb_2_bits_hasException              (io_writeback_14_bits_exceptionVec_2),
    .io_wb_2_bits_exceptionVec_2            (io_writeback_14_bits_exceptionVec_2),
    .io_wb_3_bits_robIdx_flag               (io_writeback_15_bits_robIdx_flag),
    .io_wb_3_bits_robIdx_value              (io_writeback_15_bits_robIdx_value),
    .io_wb_4_bits_robIdx_flag               (io_writeback_16_bits_robIdx_flag),
    .io_wb_4_bits_robIdx_value              (io_writeback_16_bits_robIdx_value),
    .io_wb_5_bits_robIdx_flag               (io_writeback_17_bits_robIdx_flag),
    .io_wb_5_bits_robIdx_value              (io_writeback_17_bits_robIdx_value),
    .io_wb_6_valid                          (io_writeback_18_valid),
    .io_wb_6_bits_robIdx_flag               (io_writeback_18_bits_robIdx_flag),
    .io_wb_6_bits_robIdx_value              (io_writeback_18_bits_robIdx_value),
    .io_wb_6_bits_hasException              (n_exceptionGen_io_wb_6_bits_hasException),
    .io_wb_6_bits_exceptionVec_0            (io_writeback_18_bits_exceptionVec_0),
    .io_wb_6_bits_exceptionVec_1            (io_writeback_18_bits_exceptionVec_1),
    .io_wb_6_bits_exceptionVec_2            (io_writeback_18_bits_exceptionVec_2),
    .io_wb_6_bits_exceptionVec_3            (io_writeback_18_bits_exceptionVec_3),
    .io_wb_6_bits_exceptionVec_4            (io_writeback_18_bits_exceptionVec_4),
    .io_wb_6_bits_exceptionVec_5            (io_writeback_18_bits_exceptionVec_5),
    .io_wb_6_bits_exceptionVec_6            (io_writeback_18_bits_exceptionVec_6),
    .io_wb_6_bits_exceptionVec_7            (io_writeback_18_bits_exceptionVec_7),
    .io_wb_6_bits_exceptionVec_8            (io_writeback_18_bits_exceptionVec_8),
    .io_wb_6_bits_exceptionVec_9            (io_writeback_18_bits_exceptionVec_9),
    .io_wb_6_bits_exceptionVec_10           (io_writeback_18_bits_exceptionVec_10),
    .io_wb_6_bits_exceptionVec_11           (io_writeback_18_bits_exceptionVec_11),
    .io_wb_6_bits_exceptionVec_12           (io_writeback_18_bits_exceptionVec_12),
    .io_wb_6_bits_exceptionVec_13           (io_writeback_18_bits_exceptionVec_13),
    .io_wb_6_bits_exceptionVec_14           (io_writeback_18_bits_exceptionVec_14),
    .io_wb_6_bits_exceptionVec_15           (io_writeback_18_bits_exceptionVec_15),
    .io_wb_6_bits_exceptionVec_16           (io_writeback_18_bits_exceptionVec_16),
    .io_wb_6_bits_exceptionVec_17           (io_writeback_18_bits_exceptionVec_17),
    .io_wb_6_bits_exceptionVec_18           (io_writeback_18_bits_exceptionVec_18),
    .io_wb_6_bits_exceptionVec_19           (io_writeback_18_bits_exceptionVec_19),
    .io_wb_6_bits_exceptionVec_20           (io_writeback_18_bits_exceptionVec_20),
    .io_wb_6_bits_exceptionVec_21           (io_writeback_18_bits_exceptionVec_21),
    .io_wb_6_bits_exceptionVec_22           (io_writeback_18_bits_exceptionVec_22),
    .io_wb_6_bits_exceptionVec_23           (io_writeback_18_bits_exceptionVec_23),
    .io_wb_6_bits_flushPipe                 (io_writeback_18_bits_flushPipe),
    .io_wb_6_bits_trigger                   (io_writeback_18_bits_trigger),
    .io_wb_7_valid                          (io_writeback_19_valid),
    .io_wb_7_bits_robIdx_flag               (io_writeback_19_bits_robIdx_flag),
    .io_wb_7_bits_robIdx_value              (io_writeback_19_bits_robIdx_value),
    .io_wb_7_bits_hasException              (n_exceptionGen_io_wb_7_bits_hasException),
    .io_wb_7_bits_exceptionVec_0            (io_writeback_19_bits_exceptionVec_0),
    .io_wb_7_bits_exceptionVec_1            (io_writeback_19_bits_exceptionVec_1),
    .io_wb_7_bits_exceptionVec_2            (io_writeback_19_bits_exceptionVec_2),
    .io_wb_7_bits_exceptionVec_3            (io_writeback_19_bits_exceptionVec_3),
    .io_wb_7_bits_exceptionVec_4            (io_writeback_19_bits_exceptionVec_4),
    .io_wb_7_bits_exceptionVec_5            (io_writeback_19_bits_exceptionVec_5),
    .io_wb_7_bits_exceptionVec_6            (io_writeback_19_bits_exceptionVec_6),
    .io_wb_7_bits_exceptionVec_7            (io_writeback_19_bits_exceptionVec_7),
    .io_wb_7_bits_exceptionVec_8            (io_writeback_19_bits_exceptionVec_8),
    .io_wb_7_bits_exceptionVec_9            (io_writeback_19_bits_exceptionVec_9),
    .io_wb_7_bits_exceptionVec_10           (io_writeback_19_bits_exceptionVec_10),
    .io_wb_7_bits_exceptionVec_11           (io_writeback_19_bits_exceptionVec_11),
    .io_wb_7_bits_exceptionVec_12           (io_writeback_19_bits_exceptionVec_12),
    .io_wb_7_bits_exceptionVec_13           (io_writeback_19_bits_exceptionVec_13),
    .io_wb_7_bits_exceptionVec_14           (io_writeback_19_bits_exceptionVec_14),
    .io_wb_7_bits_exceptionVec_15           (io_writeback_19_bits_exceptionVec_15),
    .io_wb_7_bits_exceptionVec_16           (io_writeback_19_bits_exceptionVec_16),
    .io_wb_7_bits_exceptionVec_17           (io_writeback_19_bits_exceptionVec_17),
    .io_wb_7_bits_exceptionVec_18           (io_writeback_19_bits_exceptionVec_18),
    .io_wb_7_bits_exceptionVec_19           (io_writeback_19_bits_exceptionVec_19),
    .io_wb_7_bits_exceptionVec_20           (io_writeback_19_bits_exceptionVec_20),
    .io_wb_7_bits_exceptionVec_21           (io_writeback_19_bits_exceptionVec_21),
    .io_wb_7_bits_exceptionVec_22           (io_writeback_19_bits_exceptionVec_22),
    .io_wb_7_bits_exceptionVec_23           (io_writeback_19_bits_exceptionVec_23),
    .io_wb_7_bits_flushPipe                 (io_writeback_19_bits_flushPipe),
    .io_wb_7_bits_trigger                   (io_writeback_19_bits_trigger),
    .io_wb_8_valid                          (io_writeback_20_valid),
    .io_wb_8_bits_robIdx_flag               (io_writeback_20_bits_robIdx_flag),
    .io_wb_8_bits_robIdx_value              (io_writeback_20_bits_robIdx_value),
    .io_wb_8_bits_hasException              (n_exceptionGen_io_wb_8_bits_hasException),
    .io_wb_8_bits_exceptionVec_0            (io_writeback_20_bits_exceptionVec_0),
    .io_wb_8_bits_exceptionVec_1            (io_writeback_20_bits_exceptionVec_1),
    .io_wb_8_bits_exceptionVec_2            (io_writeback_20_bits_exceptionVec_2),
    .io_wb_8_bits_exceptionVec_3            (io_writeback_20_bits_exceptionVec_3),
    .io_wb_8_bits_exceptionVec_4            (io_writeback_20_bits_exceptionVec_4),
    .io_wb_8_bits_exceptionVec_5            (io_writeback_20_bits_exceptionVec_5),
    .io_wb_8_bits_exceptionVec_6            (io_writeback_20_bits_exceptionVec_6),
    .io_wb_8_bits_exceptionVec_7            (io_writeback_20_bits_exceptionVec_7),
    .io_wb_8_bits_exceptionVec_8            (io_writeback_20_bits_exceptionVec_8),
    .io_wb_8_bits_exceptionVec_9            (io_writeback_20_bits_exceptionVec_9),
    .io_wb_8_bits_exceptionVec_10           (io_writeback_20_bits_exceptionVec_10),
    .io_wb_8_bits_exceptionVec_11           (io_writeback_20_bits_exceptionVec_11),
    .io_wb_8_bits_exceptionVec_12           (io_writeback_20_bits_exceptionVec_12),
    .io_wb_8_bits_exceptionVec_13           (io_writeback_20_bits_exceptionVec_13),
    .io_wb_8_bits_exceptionVec_14           (io_writeback_20_bits_exceptionVec_14),
    .io_wb_8_bits_exceptionVec_15           (io_writeback_20_bits_exceptionVec_15),
    .io_wb_8_bits_exceptionVec_16           (io_writeback_20_bits_exceptionVec_16),
    .io_wb_8_bits_exceptionVec_17           (io_writeback_20_bits_exceptionVec_17),
    .io_wb_8_bits_exceptionVec_18           (io_writeback_20_bits_exceptionVec_18),
    .io_wb_8_bits_exceptionVec_19           (io_writeback_20_bits_exceptionVec_19),
    .io_wb_8_bits_exceptionVec_20           (io_writeback_20_bits_exceptionVec_20),
    .io_wb_8_bits_exceptionVec_21           (io_writeback_20_bits_exceptionVec_21),
    .io_wb_8_bits_exceptionVec_22           (io_writeback_20_bits_exceptionVec_22),
    .io_wb_8_bits_exceptionVec_23           (io_writeback_20_bits_exceptionVec_23),
    .io_wb_8_bits_flushPipe                 (io_writeback_20_bits_flushPipe),
    .io_wb_8_bits_replayInst                (io_writeback_20_bits_replay),
    .io_wb_8_bits_trigger                   (io_writeback_20_bits_trigger),
    .io_wb_9_valid                          (io_writeback_21_valid),
    .io_wb_9_bits_robIdx_flag               (io_writeback_21_bits_robIdx_flag),
    .io_wb_9_bits_robIdx_value              (io_writeback_21_bits_robIdx_value),
    .io_wb_9_bits_hasException              (n_exceptionGen_io_wb_9_bits_hasException),
    .io_wb_9_bits_exceptionVec_0            (io_writeback_21_bits_exceptionVec_0),
    .io_wb_9_bits_exceptionVec_1            (io_writeback_21_bits_exceptionVec_1),
    .io_wb_9_bits_exceptionVec_2            (io_writeback_21_bits_exceptionVec_2),
    .io_wb_9_bits_exceptionVec_3            (io_writeback_21_bits_exceptionVec_3),
    .io_wb_9_bits_exceptionVec_4            (io_writeback_21_bits_exceptionVec_4),
    .io_wb_9_bits_exceptionVec_5            (io_writeback_21_bits_exceptionVec_5),
    .io_wb_9_bits_exceptionVec_6            (io_writeback_21_bits_exceptionVec_6),
    .io_wb_9_bits_exceptionVec_7            (io_writeback_21_bits_exceptionVec_7),
    .io_wb_9_bits_exceptionVec_8            (io_writeback_21_bits_exceptionVec_8),
    .io_wb_9_bits_exceptionVec_9            (io_writeback_21_bits_exceptionVec_9),
    .io_wb_9_bits_exceptionVec_10           (io_writeback_21_bits_exceptionVec_10),
    .io_wb_9_bits_exceptionVec_11           (io_writeback_21_bits_exceptionVec_11),
    .io_wb_9_bits_exceptionVec_12           (io_writeback_21_bits_exceptionVec_12),
    .io_wb_9_bits_exceptionVec_13           (io_writeback_21_bits_exceptionVec_13),
    .io_wb_9_bits_exceptionVec_14           (io_writeback_21_bits_exceptionVec_14),
    .io_wb_9_bits_exceptionVec_15           (io_writeback_21_bits_exceptionVec_15),
    .io_wb_9_bits_exceptionVec_16           (io_writeback_21_bits_exceptionVec_16),
    .io_wb_9_bits_exceptionVec_17           (io_writeback_21_bits_exceptionVec_17),
    .io_wb_9_bits_exceptionVec_18           (io_writeback_21_bits_exceptionVec_18),
    .io_wb_9_bits_exceptionVec_19           (io_writeback_21_bits_exceptionVec_19),
    .io_wb_9_bits_exceptionVec_20           (io_writeback_21_bits_exceptionVec_20),
    .io_wb_9_bits_exceptionVec_21           (io_writeback_21_bits_exceptionVec_21),
    .io_wb_9_bits_exceptionVec_22           (io_writeback_21_bits_exceptionVec_22),
    .io_wb_9_bits_exceptionVec_23           (io_writeback_21_bits_exceptionVec_23),
    .io_wb_9_bits_flushPipe                 (io_writeback_21_bits_flushPipe),
    .io_wb_9_bits_replayInst                (io_writeback_21_bits_replay),
    .io_wb_9_bits_trigger                   (io_writeback_21_bits_trigger),
    .io_wb_10_valid                         (io_writeback_22_valid),
    .io_wb_10_bits_robIdx_flag              (io_writeback_22_bits_robIdx_flag),
    .io_wb_10_bits_robIdx_value             (io_writeback_22_bits_robIdx_value),
    .io_wb_10_bits_hasException             (n_exceptionGen_io_wb_10_bits_hasException),
    .io_wb_10_bits_exceptionVec_0           (io_writeback_22_bits_exceptionVec_0),
    .io_wb_10_bits_exceptionVec_1           (io_writeback_22_bits_exceptionVec_1),
    .io_wb_10_bits_exceptionVec_2           (io_writeback_22_bits_exceptionVec_2),
    .io_wb_10_bits_exceptionVec_3           (io_writeback_22_bits_exceptionVec_3),
    .io_wb_10_bits_exceptionVec_4           (io_writeback_22_bits_exceptionVec_4),
    .io_wb_10_bits_exceptionVec_5           (io_writeback_22_bits_exceptionVec_5),
    .io_wb_10_bits_exceptionVec_6           (io_writeback_22_bits_exceptionVec_6),
    .io_wb_10_bits_exceptionVec_7           (io_writeback_22_bits_exceptionVec_7),
    .io_wb_10_bits_exceptionVec_8           (io_writeback_22_bits_exceptionVec_8),
    .io_wb_10_bits_exceptionVec_9           (io_writeback_22_bits_exceptionVec_9),
    .io_wb_10_bits_exceptionVec_10          (io_writeback_22_bits_exceptionVec_10),
    .io_wb_10_bits_exceptionVec_11          (io_writeback_22_bits_exceptionVec_11),
    .io_wb_10_bits_exceptionVec_12          (io_writeback_22_bits_exceptionVec_12),
    .io_wb_10_bits_exceptionVec_13          (io_writeback_22_bits_exceptionVec_13),
    .io_wb_10_bits_exceptionVec_14          (io_writeback_22_bits_exceptionVec_14),
    .io_wb_10_bits_exceptionVec_15          (io_writeback_22_bits_exceptionVec_15),
    .io_wb_10_bits_exceptionVec_16          (io_writeback_22_bits_exceptionVec_16),
    .io_wb_10_bits_exceptionVec_17          (io_writeback_22_bits_exceptionVec_17),
    .io_wb_10_bits_exceptionVec_18          (io_writeback_22_bits_exceptionVec_18),
    .io_wb_10_bits_exceptionVec_19          (io_writeback_22_bits_exceptionVec_19),
    .io_wb_10_bits_exceptionVec_20          (io_writeback_22_bits_exceptionVec_20),
    .io_wb_10_bits_exceptionVec_21          (io_writeback_22_bits_exceptionVec_21),
    .io_wb_10_bits_exceptionVec_22          (io_writeback_22_bits_exceptionVec_22),
    .io_wb_10_bits_exceptionVec_23          (io_writeback_22_bits_exceptionVec_23),
    .io_wb_10_bits_flushPipe                (io_writeback_22_bits_flushPipe),
    .io_wb_10_bits_replayInst               (io_writeback_22_bits_replay),
    .io_wb_10_bits_trigger                  (io_writeback_22_bits_trigger),
    .io_wb_11_valid                         (io_writeback_23_valid),
    .io_wb_11_bits_robIdx_flag              (io_writeback_23_bits_robIdx_flag),
    .io_wb_11_bits_robIdx_value             (io_writeback_23_bits_robIdx_value),
    .io_wb_11_bits_hasException             (n_exceptionGen_io_wb_11_bits_hasException),
    .io_wb_11_bits_exceptionVec_0           (io_writeback_23_bits_exceptionVec_0),
    .io_wb_11_bits_exceptionVec_1           (io_writeback_23_bits_exceptionVec_1),
    .io_wb_11_bits_exceptionVec_2           (io_writeback_23_bits_exceptionVec_2),
    .io_wb_11_bits_exceptionVec_3           (io_writeback_23_bits_exceptionVec_3),
    .io_wb_11_bits_exceptionVec_4           (io_writeback_23_bits_exceptionVec_4),
    .io_wb_11_bits_exceptionVec_5           (io_writeback_23_bits_exceptionVec_5),
    .io_wb_11_bits_exceptionVec_6           (io_writeback_23_bits_exceptionVec_6),
    .io_wb_11_bits_exceptionVec_7           (io_writeback_23_bits_exceptionVec_7),
    .io_wb_11_bits_exceptionVec_8           (io_writeback_23_bits_exceptionVec_8),
    .io_wb_11_bits_exceptionVec_9           (io_writeback_23_bits_exceptionVec_9),
    .io_wb_11_bits_exceptionVec_10          (io_writeback_23_bits_exceptionVec_10),
    .io_wb_11_bits_exceptionVec_11          (io_writeback_23_bits_exceptionVec_11),
    .io_wb_11_bits_exceptionVec_12          (io_writeback_23_bits_exceptionVec_12),
    .io_wb_11_bits_exceptionVec_13          (io_writeback_23_bits_exceptionVec_13),
    .io_wb_11_bits_exceptionVec_14          (io_writeback_23_bits_exceptionVec_14),
    .io_wb_11_bits_exceptionVec_15          (io_writeback_23_bits_exceptionVec_15),
    .io_wb_11_bits_exceptionVec_16          (io_writeback_23_bits_exceptionVec_16),
    .io_wb_11_bits_exceptionVec_17          (io_writeback_23_bits_exceptionVec_17),
    .io_wb_11_bits_exceptionVec_18          (io_writeback_23_bits_exceptionVec_18),
    .io_wb_11_bits_exceptionVec_19          (io_writeback_23_bits_exceptionVec_19),
    .io_wb_11_bits_exceptionVec_20          (io_writeback_23_bits_exceptionVec_20),
    .io_wb_11_bits_exceptionVec_21          (io_writeback_23_bits_exceptionVec_21),
    .io_wb_11_bits_exceptionVec_22          (io_writeback_23_bits_exceptionVec_22),
    .io_wb_11_bits_exceptionVec_23          (io_writeback_23_bits_exceptionVec_23),
    .io_wb_11_bits_flushPipe                (io_writeback_23_bits_flushPipe),
    .io_wb_11_bits_replayInst               (io_writeback_23_bits_replay),
    .io_wb_11_bits_trigger                  (io_writeback_23_bits_trigger),
    .io_wb_11_bits_vstartEn                 (n_exceptionGen_io_wb_11_bits_vstartEn),
    .io_wb_11_bits_vstart                   (n_exceptionGen_io_wb_11_bits_vstart),
    .io_wb_11_bits_vuopIdx                  (io_writeback_23_bits_vls_vpu_vuopIdx),
    .io_wb_11_bits_isVecLoad                (io_writeback_23_bits_vls_isVecLoad),
    .io_wb_11_bits_isVlm                    (io_writeback_23_bits_vls_isVlm),
    .io_wb_11_bits_isStrided                (io_writeback_23_bits_vls_isStrided),
    .io_wb_11_bits_isIndexed                (io_writeback_23_bits_vls_isIndexed),
    .io_wb_11_bits_isWhole                  (io_writeback_23_bits_vls_isWhole),
    .io_wb_11_bits_nf                       (io_writeback_23_bits_vls_vpu_nf),
    .io_wb_11_bits_vsew                     (io_writeback_23_bits_vls_vpu_vsew),
    .io_wb_11_bits_veew                     (io_writeback_23_bits_vls_vpu_veew),
    .io_wb_11_bits_vlmul                    (io_writeback_23_bits_vls_vpu_vlmul),
    .io_wb_12_valid                         (io_writeback_24_valid),
    .io_wb_12_bits_robIdx_flag              (io_writeback_24_bits_robIdx_flag),
    .io_wb_12_bits_robIdx_value             (io_writeback_24_bits_robIdx_value),
    .io_wb_12_bits_hasException             (n_exceptionGen_io_wb_12_bits_hasException),
    .io_wb_12_bits_exceptionVec_0           (io_writeback_24_bits_exceptionVec_0),
    .io_wb_12_bits_exceptionVec_1           (io_writeback_24_bits_exceptionVec_1),
    .io_wb_12_bits_exceptionVec_2           (io_writeback_24_bits_exceptionVec_2),
    .io_wb_12_bits_exceptionVec_3           (io_writeback_24_bits_exceptionVec_3),
    .io_wb_12_bits_exceptionVec_4           (io_writeback_24_bits_exceptionVec_4),
    .io_wb_12_bits_exceptionVec_5           (io_writeback_24_bits_exceptionVec_5),
    .io_wb_12_bits_exceptionVec_6           (io_writeback_24_bits_exceptionVec_6),
    .io_wb_12_bits_exceptionVec_7           (io_writeback_24_bits_exceptionVec_7),
    .io_wb_12_bits_exceptionVec_8           (io_writeback_24_bits_exceptionVec_8),
    .io_wb_12_bits_exceptionVec_9           (io_writeback_24_bits_exceptionVec_9),
    .io_wb_12_bits_exceptionVec_10          (io_writeback_24_bits_exceptionVec_10),
    .io_wb_12_bits_exceptionVec_11          (io_writeback_24_bits_exceptionVec_11),
    .io_wb_12_bits_exceptionVec_12          (io_writeback_24_bits_exceptionVec_12),
    .io_wb_12_bits_exceptionVec_13          (io_writeback_24_bits_exceptionVec_13),
    .io_wb_12_bits_exceptionVec_14          (io_writeback_24_bits_exceptionVec_14),
    .io_wb_12_bits_exceptionVec_15          (io_writeback_24_bits_exceptionVec_15),
    .io_wb_12_bits_exceptionVec_16          (io_writeback_24_bits_exceptionVec_16),
    .io_wb_12_bits_exceptionVec_17          (io_writeback_24_bits_exceptionVec_17),
    .io_wb_12_bits_exceptionVec_18          (io_writeback_24_bits_exceptionVec_18),
    .io_wb_12_bits_exceptionVec_19          (io_writeback_24_bits_exceptionVec_19),
    .io_wb_12_bits_exceptionVec_20          (io_writeback_24_bits_exceptionVec_20),
    .io_wb_12_bits_exceptionVec_21          (io_writeback_24_bits_exceptionVec_21),
    .io_wb_12_bits_exceptionVec_22          (io_writeback_24_bits_exceptionVec_22),
    .io_wb_12_bits_exceptionVec_23          (io_writeback_24_bits_exceptionVec_23),
    .io_wb_12_bits_flushPipe                (io_writeback_24_bits_flushPipe),
    .io_wb_12_bits_replayInst               (io_writeback_24_bits_replay),
    .io_wb_12_bits_trigger                  (io_writeback_24_bits_trigger),
    .io_wb_12_bits_vstartEn                 (n_exceptionGen_io_wb_12_bits_vstartEn),
    .io_wb_12_bits_vstart                   (n_exceptionGen_io_wb_12_bits_vstart),
    .io_wb_12_bits_vuopIdx                  (io_writeback_24_bits_vls_vpu_vuopIdx),
    .io_wb_12_bits_isVecLoad                (io_writeback_24_bits_vls_isVecLoad),
    .io_wb_12_bits_isVlm                    (io_writeback_24_bits_vls_isVlm),
    .io_wb_12_bits_isStrided                (io_writeback_24_bits_vls_isStrided),
    .io_wb_12_bits_isIndexed                (io_writeback_24_bits_vls_isIndexed),
    .io_wb_12_bits_isWhole                  (io_writeback_24_bits_vls_isWhole),
    .io_wb_12_bits_nf                       (io_writeback_24_bits_vls_vpu_nf),
    .io_wb_12_bits_vsew                     (io_writeback_24_bits_vls_vpu_vsew),
    .io_wb_12_bits_veew                     (io_writeback_24_bits_vls_vpu_veew),
    .io_wb_12_bits_vlmul                    (io_writeback_24_bits_vls_vpu_vlmul),
    .io_state_valid                         (n_exceptionGen_io_state_valid),   // -> core
    .io_state_bits_robIdx_flag              (n_exceptionGen_io_state_bits_robIdx_flag),   // -> core
    .io_state_bits_robIdx_value             (n_exceptionGen_io_state_bits_robIdx_value),   // -> core
    .io_state_bits_ftqPtr_value             (io_readGPAMemAddr_bits_ftqPtr_value),
    .io_state_bits_ftqOffset                (io_readGPAMemAddr_bits_ftqOffset),
    .io_state_bits_hasException             (n_exceptionGen_io_state_bits_hasException),   // -> core
    .io_state_bits_isEnqExcp                (n_exceptionGen_io_state_bits_isEnqExcp),   // -> core
    .io_state_bits_exceptionVec_0           (n_exceptionGen_io_state_bits_exceptionVec_0),   // -> core
    .io_state_bits_exceptionVec_1           (n_exceptionGen_io_state_bits_exceptionVec_1),   // -> core
    .io_state_bits_exceptionVec_2           (n_exceptionGen_io_state_bits_exceptionVec_2),   // -> core
    .io_state_bits_exceptionVec_3           (n_exceptionGen_io_state_bits_exceptionVec_3),   // -> core
    .io_state_bits_exceptionVec_4           (n_exceptionGen_io_state_bits_exceptionVec_4),   // -> core
    .io_state_bits_exceptionVec_5           (n_exceptionGen_io_state_bits_exceptionVec_5),   // -> core
    .io_state_bits_exceptionVec_6           (n_exceptionGen_io_state_bits_exceptionVec_6),   // -> core
    .io_state_bits_exceptionVec_7           (n_exceptionGen_io_state_bits_exceptionVec_7),   // -> core
    .io_state_bits_exceptionVec_8           (n_exceptionGen_io_state_bits_exceptionVec_8),   // -> core
    .io_state_bits_exceptionVec_9           (n_exceptionGen_io_state_bits_exceptionVec_9),   // -> core
    .io_state_bits_exceptionVec_10          (n_exceptionGen_io_state_bits_exceptionVec_10),   // -> core
    .io_state_bits_exceptionVec_11          (n_exceptionGen_io_state_bits_exceptionVec_11),   // -> core
    .io_state_bits_exceptionVec_12          (n_exceptionGen_io_state_bits_exceptionVec_12),   // -> core
    .io_state_bits_exceptionVec_13          (n_exceptionGen_io_state_bits_exceptionVec_13),   // -> core
    .io_state_bits_exceptionVec_14          (n_exceptionGen_io_state_bits_exceptionVec_14),   // -> core
    .io_state_bits_exceptionVec_15          (n_exceptionGen_io_state_bits_exceptionVec_15),   // -> core
    .io_state_bits_exceptionVec_16          (n_exceptionGen_io_state_bits_exceptionVec_16),   // -> core
    .io_state_bits_exceptionVec_17          (n_exceptionGen_io_state_bits_exceptionVec_17),   // -> core
    .io_state_bits_exceptionVec_18          (n_exceptionGen_io_state_bits_exceptionVec_18),   // -> core
    .io_state_bits_exceptionVec_19          (n_exceptionGen_io_state_bits_exceptionVec_19),   // -> core
    .io_state_bits_exceptionVec_20          (n_exceptionGen_io_state_bits_exceptionVec_20),   // -> core
    .io_state_bits_exceptionVec_21          (n_exceptionGen_io_state_bits_exceptionVec_21),   // -> core
    .io_state_bits_exceptionVec_22          (n_exceptionGen_io_state_bits_exceptionVec_22),   // -> core
    .io_state_bits_exceptionVec_23          (n_exceptionGen_io_state_bits_exceptionVec_23),   // -> core
    .io_state_bits_isFetchMalAddr           (n_exceptionGen_io_state_bits_isFetchMalAddr),   // -> core
    .io_state_bits_satpFlushFirstFetchFault (n_exceptionGen_io_state_bits_satpFlushFirstFetchFault),   // -> core
    .io_state_bits_flushPipe                (n_exceptionGen_io_state_bits_flushPipe),   // -> core
    .io_state_bits_satpFlushPipe            (n_exceptionGen_io_state_bits_satpFlushPipe),   // -> core
    .io_state_bits_isVset                   (n_exceptionGen_io_state_bits_isVset),   // -> core
    .io_state_bits_replayInst               (n_exceptionGen_io_state_bits_replayInst),   // -> core
    .io_state_bits_singleStep               (n_exceptionGen_io_state_bits_singleStep),   // -> core
    .io_state_bits_crossPageIPFFix          (n_exceptionGen_io_state_bits_crossPageIPFFix),   // -> core
    .io_state_bits_trigger                  (n_exceptionGen_io_state_bits_trigger),   // -> core
    .io_state_bits_vstartEn                 (n_exceptionGen_io_state_bits_vstartEn),   // -> core
    .io_state_bits_vstart                   (n_exceptionGen_io_state_bits_vstart),   // -> core
    .io_state_bits_isVecLoad                (n_exceptionGen_io_state_bits_isVecLoad),   // -> core
    .io_state_bits_isVlm                    (n_exceptionGen_io_state_bits_isVlm),   // -> core
    .io_state_bits_isStrided                (n_exceptionGen_io_state_bits_isStrided),   // -> core
    .io_state_bits_isIndexed                (n_exceptionGen_io_state_bits_isIndexed),   // -> core
    .io_state_bits_isWhole                  (n_exceptionGen_io_state_bits_isWhole),   // -> core
    .io_state_bits_nf                       (n_exceptionGen_io_state_bits_nf),   // -> core
    .io_state_bits_vsew                     (n_exceptionGen_io_state_bits_vsew),   // -> core
    .io_state_bits_veew                     (n_exceptionGen_io_state_bits_veew),   // -> core
    .io_state_bits_vlmul                    (n_exceptionGen_io_state_bits_vlmul)   // -> core
  );

  // NewRobDeqPtrWrapper -- symmetric blackbox (neither side gets a body); Rob is conditional on its own signoff.
  NewRobDeqPtrWrapper deqPtrGenModule (
    .clock                                (clock),
    .reset                                (reset),
    .io_state                             (n_deqPtrGenModule_io_state),
    .io_deq_v_0                           (n_commit_vDeqGroup_0),   // <- core
    .io_deq_v_1                           (n_commit_vDeqGroup_1),   // <- core
    .io_deq_v_2                           (n_commit_vDeqGroup_2),   // <- core
    .io_deq_v_3                           (n_commit_vDeqGroup_3),   // <- core
    .io_deq_v_4                           (n_commit_vDeqGroup_4),   // <- core
    .io_deq_v_5                           (n_commit_vDeqGroup_5),   // <- core
    .io_deq_v_6                           (n_commit_vDeqGroup_6),   // <- core
    .io_deq_v_7                           (n_commit_vDeqGroup_7),   // <- core
    .io_deq_w_0                           (n_commit_wDeqGroup_0),   // <- core
    .io_deq_w_1                           (n_commit_wDeqGroup_1),   // <- core
    .io_deq_w_2                           (n_commit_wDeqGroup_2),   // <- core
    .io_deq_w_3                           (n_commit_wDeqGroup_3),   // <- core
    .io_deq_w_4                           (n_commit_wDeqGroup_4),   // <- core
    .io_deq_w_5                           (n_commit_wDeqGroup_5),   // <- core
    .io_deq_w_6                           (n_commit_wDeqGroup_6),   // <- core
    .io_deq_w_7                           (n_commit_wDeqGroup_7),   // <- core
    .io_hasCommitted_0                    (n_hasCommittedOut_0),   // <- core
    .io_hasCommitted_1                    (n_hasCommittedOut_1),   // <- core
    .io_hasCommitted_2                    (n_hasCommittedOut_2),   // <- core
    .io_hasCommitted_3                    (n_hasCommittedOut_3),   // <- core
    .io_hasCommitted_4                    (n_hasCommittedOut_4),   // <- core
    .io_hasCommitted_5                    (n_hasCommittedOut_5),   // <- core
    .io_hasCommitted_6                    (n_hasCommittedOut_6),   // <- core
    .io_hasCommitted_7                    (n_hasCommittedOut_7),   // <- core
    .io_exception_state_valid             (n_exceptionGen_io_state_valid),   // <- core
    .io_exception_state_bits_robIdx_flag  (n_exceptionGen_io_state_bits_robIdx_flag),   // <- core
    .io_exception_state_bits_robIdx_value (n_exceptionGen_io_state_bits_robIdx_value),   // <- core
    .io_exception_state_bits_hasException (n_exceptionGen_io_state_bits_hasException),   // <- core
    .io_exception_state_bits_replayInst   (n_exceptionGen_io_state_bits_replayInst),   // <- core
    .io_exception_state_bits_singleStep   (n_exceptionGen_io_state_bits_singleStep),   // <- core
    .io_exception_state_bits_trigger      (n_exceptionGen_io_state_bits_trigger),   // <- core
    .io_intrBitSetReg                     (n_intrBitSetRegOut),   // <- core
    .io_allowOnlyOneCommit                (n_allowOnlyOneCommit),   // <- core
    .io_hasNoSpecExec                     (n_hasWaitForwardOut),   // <- core
    .io_interrupt_safe                    (n_rawInfo_0_interrupt_safe),   // <- core
    .io_blockCommit                       (n_blockCommit),   // <- core
    .io_out_0_flag                        (n_deqPtrVec_0_flag),   // -> core
    .io_out_0_value                       (n_deqPtrVec_0_value),   // -> core
    .io_out_1_flag                        (n_deqPtrVec_1_flag),   // -> core
    .io_out_1_value                       (n_deqPtrVec_1_value),   // -> core
    .io_out_2_flag                        (n_deqPtrVec_2_flag),   // -> core
    .io_out_2_value                       (n_deqPtrVec_2_value),   // -> core
    .io_out_3_flag                        (n_deqPtrVec_3_flag),   // -> core
    .io_out_3_value                       (n_deqPtrVec_3_value),   // -> core
    .io_out_4_flag                        (n_deqPtrVec_4_flag),   // -> core
    .io_out_4_value                       (n_deqPtrVec_4_value),   // -> core
    .io_out_5_flag                        (n_deqPtrVec_5_flag),   // -> core
    .io_out_5_value                       (n_deqPtrVec_5_value),   // -> core
    .io_out_6_flag                        (n_deqPtrVec_6_flag),   // -> core
    .io_out_6_value                       (n_deqPtrVec_6_value),   // -> core
    .io_out_7_flag                        (n_deqPtrVec_7_flag),   // -> core
    .io_out_7_value                       (n_deqPtrVec_7_value),   // -> core
    .io_next_out_0_flag                   (n_deqPtrVec_next_0_flag),   // -> core
    .io_next_out_0_value                  (n_deqPtrVec_next_0_value),   // -> core
    .io_next_out_1_flag                   (n_deqPtrVec_next_1_flag),   // -> core
    .io_next_out_1_value                  (n_deqPtrVec_next_1_value),   // -> core
    .io_next_out_2_flag                   (n_deqPtrVec_next_2_flag),   // -> core
    .io_next_out_2_value                  (n_deqPtrVec_next_2_value),   // -> core
    .io_next_out_3_flag                   (n_deqPtrVec_next_3_flag),   // -> core
    .io_next_out_3_value                  (n_deqPtrVec_next_3_value),   // -> core
    .io_next_out_4_flag                   (n_deqPtrVec_next_4_flag),   // -> core
    .io_next_out_4_value                  (n_deqPtrVec_next_4_value),   // -> core
    .io_next_out_5_flag                   (n_deqPtrVec_next_5_flag),   // -> core
    .io_next_out_5_value                  (n_deqPtrVec_next_5_value),   // -> core
    .io_next_out_6_flag                   (n_deqPtrVec_next_6_flag),   // -> core
    .io_next_out_6_value                  (n_deqPtrVec_next_6_value),   // -> core
    .io_next_out_7_flag                   (n_deqPtrVec_next_7_flag),   // -> core
    .io_next_out_7_value                  (n_deqPtrVec_next_7_value),   // -> core
    .io_canCommitPriorityCond_0           (),
    .io_canCommitPriorityCond_1           (),
    .io_canCommitPriorityCond_2           (),
    .io_canCommitPriorityCond_3           (),
    .io_canCommitPriorityCond_4           (),
    .io_canCommitPriorityCond_5           (),
    .io_canCommitPriorityCond_6           (),
    .io_canCommitPriorityCond_7           (),
    .io_canCommitPriorityCond_8           ()
  );

  // RobEnqPtrWrapper -- symmetric blackbox (neither side gets a body); Rob is conditional on its own signoff.
  RobEnqPtrWrapper enqPtrGenModule (
    .clock                         (clock),
    .reset                         (reset),
    .io_redirect_valid             (io_redirect_valid),
    .io_redirect_bits_robIdx_flag  (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level        (io_redirect_bits_level),
    .io_allowEnqueue               (n_enqPtrGenModule_io_allowEnqueue),
    .io_hasBlockBackward           (n_hasBlockBackwardOut),   // <- core
    .io_enq_0                      (n_enqFirstUopValid_0),   // <- core
    .io_enq_1                      (n_enqFirstUopValid_1),   // <- core
    .io_enq_2                      (n_enqFirstUopValid_2),   // <- core
    .io_enq_3                      (n_enqFirstUopValid_3),   // <- core
    .io_enq_4                      (n_enqFirstUopValid_4),   // <- core
    .io_enq_5                      (n_enqFirstUopValid_5),   // <- core
    .io_out_0_flag                 (n_enqPtrVec_0_flag),   // -> core
    .io_out_0_value                (n_enqPtrVec_0_value),   // -> core
    .io_out_1_flag                 (n_enqPtrVec_1_flag),   // -> core
    .io_out_1_value                (n_enqPtrVec_1_value),   // -> core
    .io_out_2_flag                 (n_enqPtrVec_2_flag),   // -> core
    .io_out_2_value                (n_enqPtrVec_2_value),   // -> core
    .io_out_3_flag                 (n_enqPtrVec_3_flag),   // -> core
    .io_out_3_value                (n_enqPtrVec_3_value),   // -> core
    .io_out_4_flag                 (n_enqPtrVec_4_flag),   // -> core
    .io_out_4_value                (n_enqPtrVec_4_value),   // -> core
    .io_out_5_flag                 (n_enqPtrVec_5_flag),   // -> core
    .io_out_5_value                (n_enqPtrVec_5_value)   // -> core
  );

  // dt_pcTransType_160x2 -- symmetric blackbox (neither side gets a body); Rob is conditional on its own signoff.
  dt_pcTransType_160x2 dt_pcTransType_ext (
    .R0_addr (n_deqPtrVec_7_value),   // <- core
    .R0_en   (1'h1),
    .R0_clk  (clock),
    .R0_data (n_dt_pcTransType_ext_R0_data),   // -> core
    .R1_addr (n_deqPtrVec_6_value),   // <- core
    .R1_en   (1'h1),
    .R1_clk  (clock),
    .R1_data (n_dt_pcTransType_ext_R1_data),   // -> core
    .R2_addr (n_deqPtrVec_5_value),   // <- core
    .R2_en   (1'h1),
    .R2_clk  (clock),
    .R2_data (n_dt_pcTransType_ext_R2_data),   // -> core
    .R3_addr (n_deqPtrVec_4_value),   // <- core
    .R3_en   (1'h1),
    .R3_clk  (clock),
    .R3_data (n_dt_pcTransType_ext_R3_data),   // -> core
    .R4_addr (n_deqPtrVec_3_value),   // <- core
    .R4_en   (1'h1),
    .R4_clk  (clock),
    .R4_data (n_dt_pcTransType_ext_R4_data),   // -> core
    .R5_addr (n_deqPtrVec_2_value),   // <- core
    .R5_en   (1'h1),
    .R5_clk  (clock),
    .R5_data (n_dt_pcTransType_ext_R5_data),   // -> core
    .R6_addr (n_deqPtrVec_1_value),   // <- core
    .R6_en   (1'h1),
    .R6_clk  (clock),
    .R6_data (n_dt_pcTransType_ext_R6_data),   // -> core
    .R7_addr (n_deqPtrVec_0_value),   // <- core
    .R7_en   (1'h1),
    .R7_clk  (clock),
    .R7_data (n_dt_pcTransType_ext_R7_data),   // -> core
    .W0_addr (n_allocatePtrVec_5_value),   // <- core
    .W0_en   (n_canEnqueue_5),   // <- core
    .W0_clk  (clock),
    .W0_data (n_dtPcTransTypeWdata),   // <- core
    .W1_addr (n_allocatePtrVec_4_value),   // <- core
    .W1_en   (n_canEnqueue_4),   // <- core
    .W1_clk  (clock),
    .W1_data (n_dtPcTransTypeWdata),   // <- core
    .W2_addr (n_allocatePtrVec_3_value),   // <- core
    .W2_en   (n_canEnqueue_3),   // <- core
    .W2_clk  (clock),
    .W2_data (n_dtPcTransTypeWdata),   // <- core
    .W3_addr (n_allocatePtrVec_2_value),   // <- core
    .W3_en   (n_canEnqueue_2),   // <- core
    .W3_clk  (clock),
    .W3_data (n_dtPcTransTypeWdata),   // <- core
    .W4_addr (n_allocatePtrVec_1_value),   // <- core
    .W4_en   (n_canEnqueue_1),   // <- core
    .W4_clk  (clock),
    .W4_data (n_dtPcTransTypeWdata),   // <- core
    .W5_addr (n_enqPtrVec_0_value),   // <- core
    .W5_en   (n_canEnqueue_0),   // <- core
    .W5_clk  (clock),
    .W5_data (n_dtPcTransTypeWdata)   // <- core
  );

  // CommitStuckCounter -- symmetric blackbox (neither side gets a body); Rob is conditional on its own signoff.
  CommitStuckCounter commitStuckCounter (
    .clock       (clock),
    .reset       (reset),
    .io_stuck    (n_commitStuckCounter_io_stuck),
    .io_overflow (n_commitStuckCounter_io_overflow)   // -> core
  );

  // END GENERATED

endmodule
