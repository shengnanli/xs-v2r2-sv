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
// 子模块：8 个全是**对称黑盒**（ref 与 impl 两侧都不给体），所以本目标是
// **条件绿** —— 依赖 rab / vtypeBuffer / exceptionGen / enqPtrGenModule /
// deqPtrGenModule / snapshots_snapshotGen / commitStuckCounter / dt_pcTransType_ext
// 各自独立签核。receipt 必须带这条依赖，Rob 不得报成无条件通过。
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

endmodule
