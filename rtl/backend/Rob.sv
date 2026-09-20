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
  logic [PTR_W-1:0] enqPtrValue [RENAME_W];
  logic             enqPtrFlag  [RENAME_W];
  always_comb begin
    enqPtrValue[0] = enqPtrVec_0_value; enqPtrFlag[0] = enqPtrVec_0_flag;
    enqPtrValue[1] = enqPtrVec_1_value;   enqPtrFlag[1] = enqPtrVec_1_flag;
    enqPtrValue[2] = enqPtrVec_2_value;   enqPtrFlag[2] = enqPtrVec_2_flag;
    enqPtrValue[3] = enqPtrVec_3_value;   enqPtrFlag[3] = enqPtrVec_3_flag;
    enqPtrValue[4] = enqPtrVec_4_value;   enqPtrFlag[4] = enqPtrVec_4_flag;
    enqPtrValue[5] = enqPtrVec_5_value;   enqPtrFlag[5] = enqPtrVec_5_flag;
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
  //   golden 把后者折成 `(enq - 8'h60) - deq`（160 mod 256 = -96），等价。
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
      : ((enqPtrVec_0_value - PTR_W'(ROB_SIZE)) - deqPtrVec_0_value);
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

  // hasBlockBackward：进队时置位，ROB 空了就清（Scala 里 isEmpty 分支在后，优先级更高）
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                                    hasBlockBackward <= 1'b0;
    else if (isEmpty)                             hasBlockBackward <= 1'b0;
    else if (anyBlockBackward & io_enq_canAccept) hasBlockBackward <= 1'b1;
  end
  assign hasBlockBackwardOut = hasBlockBackward;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)                       hasWaitForward <= 1'b0;
    else if (commitsHasWalkInstr | commitsHasCommitInstr) hasWaitForward <= 1'b0;
    else if (anyWaitForward)         hasWaitForward <= 1'b1;
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
  logic enqIsHls        [RENAME_W];   // DynInst.isHls：hlv(ldu) / hsv(stu)
  logic enqNeedWriteRf  [RENAME_W];   // rfWen|fpWen|vecWen|v0Wen|vlWen
  logic enqAllowIntr    [RENAME_W];   // 允许中断：非访存/非 fence/非 csr/非 vset/非 amo
  logic enqNeedFlush    [RENAME_W];   // hasException | flushPipe

  always_comb begin
    enqIsHls[0] = ((io_enq_req_0_bits_fuType == FUTYPE_W'(1) << FU_LDU)
                   | (io_enq_req_0_bits_fuType == FUTYPE_W'(1) << FU_STU))
                  & io_enq_req_0_bits_fuOpType[4]
                  & ~io_enq_req_0_bits_fuOpType[5]
                  & ~(|io_enq_req_0_bits_fuOpType[8:7]);
    enqIsHls[1] = ((io_enq_req_1_bits_fuType == FUTYPE_W'(1) << FU_LDU)
                   | (io_enq_req_1_bits_fuType == FUTYPE_W'(1) << FU_STU))
                  & io_enq_req_1_bits_fuOpType[4]
                  & ~io_enq_req_1_bits_fuOpType[5]
                  & ~(|io_enq_req_1_bits_fuOpType[8:7]);
    enqIsHls[2] = ((io_enq_req_2_bits_fuType == FUTYPE_W'(1) << FU_LDU)
                   | (io_enq_req_2_bits_fuType == FUTYPE_W'(1) << FU_STU))
                  & io_enq_req_2_bits_fuOpType[4]
                  & ~io_enq_req_2_bits_fuOpType[5]
                  & ~(|io_enq_req_2_bits_fuOpType[8:7]);
    enqIsHls[3] = ((io_enq_req_3_bits_fuType == FUTYPE_W'(1) << FU_LDU)
                   | (io_enq_req_3_bits_fuType == FUTYPE_W'(1) << FU_STU))
                  & io_enq_req_3_bits_fuOpType[4]
                  & ~io_enq_req_3_bits_fuOpType[5]
                  & ~(|io_enq_req_3_bits_fuOpType[8:7]);
    enqIsHls[4] = ((io_enq_req_4_bits_fuType == FUTYPE_W'(1) << FU_LDU)
                   | (io_enq_req_4_bits_fuType == FUTYPE_W'(1) << FU_STU))
                  & io_enq_req_4_bits_fuOpType[4]
                  & ~io_enq_req_4_bits_fuOpType[5]
                  & ~(|io_enq_req_4_bits_fuOpType[8:7]);
    enqIsHls[5] = ((io_enq_req_5_bits_fuType == FUTYPE_W'(1) << FU_LDU)
                   | (io_enq_req_5_bits_fuType == FUTYPE_W'(1) << FU_STU))
                  & io_enq_req_5_bits_fuOpType[4]
                  & ~io_enq_req_5_bits_fuOpType[5]
                  & ~(|io_enq_req_5_bits_fuOpType[8:7]);
  end

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
    logic                        isHls;
    logic                        needFlush;
    logic [LREG_W-1:0]           basicDebug_vd;   // instr[11:7]（XSInstBitFields.VD）
  } rob_enq_sel_t;

  rob_enq_sel_t enqBits [RENAME_W];
  rob_enq_sel_t enqSel  [ROB_SIZE];

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
    enqBits[0].isHls                      = enqIsHls[0];
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
    enqBits[1].isHls                      = enqIsHls[1];
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
    enqBits[2].isHls                      = enqIsHls[2];
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
    enqBits[3].isHls                      = enqIsHls[3];
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
    enqBits[4].isHls                      = enqIsHls[4];
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
    enqBits[5].isHls                      = enqIsHls[5];
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
        enqSel[i].isHls                      |= enqOH[i][j] & enqBits[j].isHls;
        enqSel[i].needFlush                  |= enqOH[i][j] & enqBits[j].needFlush;
        enqSel[i].basicDebug_vd              |= {LREG_W{enqOH[i][j]}} & enqBits[j].basicDebug_vd;
      end
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
        robEntries_isHls[i]                      <= enqSel[i].isHls;
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

  // 把一条条目装进组合用的结构体（存储本身仍是每字段一个数组）
  function automatic rob_entry_t packEntry(input int idx);
    rob_entry_t e;
    begin
      e.valid                      = robEntries_valid[idx];
      e.vls                        = robEntries_vls[idx];
      e.interrupt_safe             = robEntries_interrupt_safe[idx];
      e.fpWen                      = robEntries_fpWen[idx];
      e.rfWen                      = robEntries_rfWen[idx];
      e.wflags                     = robEntries_wflags[idx];
      e.dirtyVs                    = robEntries_dirtyVs[idx];
      e.commitType                 = robEntries_commitType[idx];
      e.ftqIdx_flag                = robEntries_ftqIdx_flag[idx];
      e.ftqIdx_value               = robEntries_ftqIdx_value[idx];
      e.ftqOffset                  = robEntries_ftqOffset[idx];
      e.isRVC                      = robEntries_isRVC[idx];
      e.isVset                     = robEntries_isVset[idx];
      e.isHls                      = robEntries_isHls[idx];
      e.instrSize                  = robEntries_instrSize[idx];
      e.traceBlockInPipe_itype     = robEntries_traceBlockInPipe_itype[idx];
      e.traceBlockInPipe_iretire   = robEntries_traceBlockInPipe_iretire[idx];
      e.traceBlockInPipe_ilastsize = robEntries_traceBlockInPipe_ilastsize[idx];
      e.fflags                     = robEntries_fflags[idx];
      e.mmio                       = robEntries_mmio[idx];
      e.stdWritebacked             = robEntries_stdWritebacked[idx];
      e.vxsat                      = robEntries_vxsat[idx];
      e.realDestSize               = robEntries_realDestSize[idx];
      e.uopNum                     = robEntries_uopNum[idx];
      e.needFlush                  = robEntries_needFlush[idx];
      e.debug_pc                   = robEntries_debug_pc[idx];
      e.debug_instr                = robEntries_debug_instr[idx];
      e.basicDebug_ldest           = robEntries_basicDebug_ldest[idx];
      e.basicDebug_pdest           = robEntries_basicDebug_pdest[idx];
      e.basicDebug_vd              = robEntries_basicDebug_vd[idx];
      e.basicDebug_fpWen           = robEntries_basicDebug_fpWen[idx];
      e.basicDebug_vecWen          = robEntries_basicDebug_vecWen[idx];
      e.basicDebug_v0Wen           = robEntries_basicDebug_v0Wen[idx];
      e.basicDebug_eliminatedMove  = robEntries_basicDebug_eliminatedMove[idx];
      e.basicDebug_isXSTrap        = robEntries_basicDebug_isXSTrap[idx];
      e.debug_fuType               = robEntries_debug_fuType[idx];
      packEntry = e;
    end
  endfunction

  always_comb begin
    for (int b = 0; b < BANK_N; b++) begin
      bankRdThisLine[b] = '0;
      bankRdNextLine[b] = '0;
      // ★Mux1H：按位或★（非 one-hot 时与优先级选择不等价，golden 是或）
      for (int r = 0; r < BANK_ROWS; r++) begin
        if (robBanksRaddrThisLine[r]) begin
          bankRdThisLine[b] = bankRdThisLine[b] | packEntry(r * BANK_N + b);
          bankRdNextLine[b] = bankRdNextLine[b]
                            | packEntry(((r + 1) % BANK_ROWS) * BANK_N + b);
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
  always_ff @(posedge clock) begin
    for (int i = 0; i < COMMIT_W; i++) begin
      // 默认取本行，allCommitted 时直接取下一行（提前一拍把下一行搬进来）
      automatic int s = allCommitted ? (BANK_N + i) : i;
      robDeqGroup_walk_v[i]                      <= needUpdate[s].valid;
      robDeqGroup_commit_v[i]                    <= needUpdate[s].valid;
      robDeqGroup_commit_w[i]                    <= (needUpdate[s].uopNum == {UOPNUM_W{1'b0}})
                                                  & needUpdate[s].stdWritebacked;
      robDeqGroup_realDestSize[i]                <= needUpdate[s].realDestSize;
      robDeqGroup_interrupt_safe[i]              <= needUpdate[s].interrupt_safe;
      robDeqGroup_rfWen[i]                       <= needUpdate[s].rfWen;
      robDeqGroup_fpWen[i]                       <= needUpdate[s].fpWen;
      robDeqGroup_fflags[i]                      <= needUpdate[s].fflags;
      robDeqGroup_wflags[i]                      <= needUpdate[s].wflags;
      robDeqGroup_vxsat[i]                       <= needUpdate[s].vxsat;
      robDeqGroup_isRVC[i]                       <= needUpdate[s].isRVC;
      robDeqGroup_isVset[i]                      <= needUpdate[s].isVset;
      robDeqGroup_isHls[i]                       <= needUpdate[s].isHls;
      robDeqGroup_isVls[i]                       <= needUpdate[s].vls;
      robDeqGroup_vls[i]                         <= needUpdate[s].vls;
      robDeqGroup_mmio[i]                        <= needUpdate[s].mmio;
      robDeqGroup_ftqIdx_flag[i]                 <= needUpdate[s].ftqIdx_flag;
      robDeqGroup_ftqIdx_value[i]                <= needUpdate[s].ftqIdx_value;
      robDeqGroup_ftqOffset[i]                   <= needUpdate[s].ftqOffset;
      robDeqGroup_commitType[i]                  <= needUpdate[s].commitType;
      robDeqGroup_instrSize[i]                   <= needUpdate[s].instrSize;
      robDeqGroup_dirtyFs[i]                     <= needUpdate[s].fpWen | needUpdate[s].wflags;
      robDeqGroup_dirtyVs[i]                     <= needUpdate[s].dirtyVs;
      robDeqGroup_needFlush[i]                   <= needUpdate[s].needFlush;
      robDeqGroup_traceBlockInPipe_itype[i]      <= needUpdate[s].traceBlockInPipe_itype;
      robDeqGroup_traceBlockInPipe_iretire[i]    <= needUpdate[s].traceBlockInPipe_iretire;
      robDeqGroup_traceBlockInPipe_ilastsize[i]  <= needUpdate[s].traceBlockInPipe_ilastsize;
      robDeqGroup_debug_pc[i]                    <= needUpdate[s].debug_pc;
      robDeqGroup_debug_instr[i]                 <= needUpdate[s].debug_instr;
      robDeqGroup_basicDebug_ldest[i]            <= needUpdate[s].basicDebug_ldest;
      robDeqGroup_basicDebug_pdest[i]            <= needUpdate[s].basicDebug_pdest;
      robDeqGroup_basicDebug_vd[i]               <= needUpdate[s].basicDebug_vd;
      robDeqGroup_basicDebug_fpWen[i]            <= needUpdate[s].basicDebug_fpWen;
      robDeqGroup_basicDebug_vecWen[i]           <= needUpdate[s].basicDebug_vecWen;
      robDeqGroup_basicDebug_v0Wen[i]            <= needUpdate[s].basicDebug_v0Wen;
      robDeqGroup_basicDebug_eliminatedMove[i]   <= needUpdate[s].basicDebug_eliminatedMove;
      robDeqGroup_basicDebug_isXSTrap[i]         <= needUpdate[s].basicDebug_isXSTrap;
      robDeqGroup_debug_fuType[i]                <= needUpdate[s].debug_fuType;
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

  function automatic rob_commit_t packDeqGroup(input int b);
    rob_commit_t c;
    begin
      c.walk_v                     = robDeqGroup_walk_v[b];
      c.commit_v                   = robDeqGroup_commit_v[b];
      c.commit_w                   = robDeqGroup_commit_w[b];
      c.realDestSize               = robDeqGroup_realDestSize[b];
      c.interrupt_safe             = robDeqGroup_interrupt_safe[b];
      c.wflags                     = robDeqGroup_wflags[b];
      c.fflags                     = robDeqGroup_fflags[b];
      c.vxsat                      = robDeqGroup_vxsat[b];
      c.isRVC                      = robDeqGroup_isRVC[b];
      c.isVset                     = robDeqGroup_isVset[b];
      c.isHls                      = robDeqGroup_isHls[b];
      c.isVls                      = robDeqGroup_isVls[b];
      c.vls                        = robDeqGroup_vls[b];
      c.mmio                       = robDeqGroup_mmio[b];
      c.commitType                 = robDeqGroup_commitType[b];
      c.ftqIdx_flag                = robDeqGroup_ftqIdx_flag[b];
      c.ftqIdx_value               = robDeqGroup_ftqIdx_value[b];
      c.ftqOffset                  = robDeqGroup_ftqOffset[b];
      c.instrSize                  = robDeqGroup_instrSize[b];
      c.fpWen                      = robDeqGroup_fpWen[b];
      c.rfWen                      = robDeqGroup_rfWen[b];
      c.needFlush                  = robDeqGroup_needFlush[b];
      c.traceBlockInPipe_itype     = robDeqGroup_traceBlockInPipe_itype[b];
      c.traceBlockInPipe_iretire   = robDeqGroup_traceBlockInPipe_iretire[b];
      c.traceBlockInPipe_ilastsize = robDeqGroup_traceBlockInPipe_ilastsize[b];
      c.debug_pc                   = robDeqGroup_debug_pc[b];
      c.debug_instr                = robDeqGroup_debug_instr[b];
      c.basicDebug_ldest           = robDeqGroup_basicDebug_ldest[b];
      c.basicDebug_pdest           = robDeqGroup_basicDebug_pdest[b];
      c.basicDebug_vd              = robDeqGroup_basicDebug_vd[b];
      c.basicDebug_fpWen           = robDeqGroup_basicDebug_fpWen[b];
      c.basicDebug_vecWen          = robDeqGroup_basicDebug_vecWen[b];
      c.basicDebug_v0Wen           = robDeqGroup_basicDebug_v0Wen[b];
      c.basicDebug_eliminatedMove  = robDeqGroup_basicDebug_eliminatedMove[b];
      c.basicDebug_isXSTrap        = robDeqGroup_basicDebug_isXSTrap[b];
      c.debug_fuType               = robDeqGroup_debug_fuType[b];
      c.dirtyFs                    = robDeqGroup_dirtyFs[b];
      c.dirtyVs                    = robDeqGroup_dirtyVs[b];
      // ★这 7 个是全核唯一不驱动的字段★（见文件头「已知残留」）：
      //   RobEntryBundle 没有这个成员，connectCommitEntry 没得可拷；
      //   golden 里这 56 个寄存器同样只在 RANDOMIZE_REG_INIT 里被写。
      //   ★仍然照 golden 的结构从寄存器上读出来送到端口★ —— 这样两侧形状一致，
      //   残留是"两侧各 56 个从不写的寄存器"，而不是"impl 少驱动 56 个输出"。
      c.debug_otherPdest_0         = robDeqGroup_debug_otherPdest_0[b];
      c.debug_otherPdest_1         = robDeqGroup_debug_otherPdest_1[b];
      c.debug_otherPdest_2         = robDeqGroup_debug_otherPdest_2[b];
      c.debug_otherPdest_3         = robDeqGroup_debug_otherPdest_3[b];
      c.debug_otherPdest_4         = robDeqGroup_debug_otherPdest_4[b];
      c.debug_otherPdest_5         = robDeqGroup_debug_otherPdest_5[b];
      c.debug_otherPdest_6         = robDeqGroup_debug_otherPdest_6[b];
      packDeqGroup = c;
    end
  endfunction

  always_comb begin
    for (int i = 0; i < COMMIT_W; i++) begin
      rawInfo[i]  = packDeqGroup(0);
      walkInfo[i] = packDeqGroup(0);
      // 下标只有 3 位、深度正好 8（2^3=8，不越界），但仍按本文件的通例
      // 用循环+比较，不用信号直接索引。
      for (int b = 0; b < BANK_N; b++) begin
        if (deqBankIdx[i]  == BANK_ADDR_W'(b)) rawInfo[i]  = packDeqGroup(b);
        if (walkBankIdx[i] == BANK_ADDR_W'(b)) walkInfo[i] = packDeqGroup(b);
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
    deqIsMmio = 1'b0;
    for (int i = 0; i < ROB_SIZE; i++)
      if (deqPtrValue[0] == PTR_W'(i))
        deqIsMmio = robEntries_valid[i] & robEntries_mmio[i];
  end
  assign commitStuckCounter_io_stuck =
      (~(commitValidOut[0] | commitValidOut[1] | commitValidOut[2] | commitValidOut[3]
       | commitValidOut[4] | commitValidOut[5] | commitValidOut[6] | commitValidOut[7])
       | ~io_commits_isCommit) & ~deqIsMmio;
  assign io_error_0 = commitStuckCounter_io_overflow;



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
  logic [FFLAGS_W-1:0] fflagsDataRead [COMMIT_W];
  logic                vxsatDataRead  [COMMIT_W];
  always_comb begin
    for (int i = 0; i < COMMIT_W; i++) begin
      fflagsDataRead[i] = {FFLAGS_W{1'b0}};
      vxsatDataRead[i]  = 1'b0;
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
      entryVls = 1'b0;
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
      // 写回：第 24 路优先（同样循环递增 => 后写的赢）
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
      // LSQ 入队回来的 lqIdx（比写回更靠后，优先级更高）
      for (int j = 0; j < RENAME_W; j++)
        if (dbgEnqLsqAlloc[j] & (dbgEnqLsqRobIdx[j] == PTR_W'(i)))
          debug_microOp_debugReg_lqIdx_value[i] <= dbgEnqLsqLqIdx[j];
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

  always_comb begin
    deqHeadInstr     = 32'h0;
    deqHeadDbgFuType = {FUTYPE_W{1'b0}};
    headLsIssued     = 1'b0;
    headS1Valid      = 1'b0;
    headS1Vaddr      = {VADDR_W{1'b0}};
    headS2Valid      = 1'b0;
    headS2Paddr      = {PADDR_W{1'b0}};
    storeDbgPc[0]    = {VADDR_W{1'b0}};
    storeDbgPc[1]    = {VADDR_W{1'b0}};
    for (int i = 0; i < ROB_SIZE; i++) begin
      if (deqPtrValue[0] == PTR_W'(i)) begin
        deqHeadInstr     = debug_microOp_debugReg_instr[i];
        deqHeadDbgFuType = debug_microOp_debugReg_debug_fuType[i];
        headS1Valid      = debug_lsTopdownInfo_s1_vaddr_valid[i];
        headS1Vaddr      = debug_lsTopdownInfo_s1_vaddr_bits[i];
        headS2Valid      = debug_lsTopdownInfo_s2_paddr_valid[i];
        headS2Paddr      = debug_lsTopdownInfo_s2_paddr_bits[i];
        // debug_lsIssue 是 WireDefault(debug_lsIssued) 再就地覆盖队头那一条
        headLsIssued     = debug_lsIssued[i] | io_debugHeadLsIssue;
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

endmodule
