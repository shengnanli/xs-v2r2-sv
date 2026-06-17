// =====================================================================
// rob_pkg —— 重排序缓冲(Rob, ReOrder Buffer) 类型/参数定义
// ---------------------------------------------------------------------
// 香山 V2R2(昆明湖)后端按序提交核心。ROB 跟踪所有在飞指令的精确状态，
// 实现 James E. Smith & Pleszkun 1985 的「精确中断/异常」语义：
//   - dispatch 时按序 enqueue，分配连续 robIdx；
//   - 各 FU 执行完通过 writeback 把对应条目「写回计数 uopNum」递减直到 0；
//   - deqPtr 处条目「全部 uop 写回 + std 写回」后才允许 commit(按序退休)；
//   - 队头若带异常/flushPipe/replay/中断 → flushOut 触发精确重定向；
//   - 误预测/异常 redirect 时进入 s_walk，用 walkPtr 把投机条目逐拍回滚
//     (回收物理寄存器映射)，直到追上 redirect 边界。
//
// 关键参数(默认核配置)：
//   RobSize=160(8 bank × 20 entry/bank)；CommitWidth=8；RenameWidth=6；
//   RabCommitWidth=6；MaxUopSize=65；RobIdx value 宽 8 位。
//
// 本 pkg 仅定义 ROB「控制逻辑」用到的条目状态/提交条目/指针/枚举。
// 大量 difftest/debug/trace 字段不进可读核(由 golden 黑盒承担)。
// =====================================================================
package rob_pkg;

  // ---- 规模参数 ----
  localparam int ROB_SIZE        = 160;            // ROB 条目数
  localparam int BANK_NUM        = 8;              // bank 数(= CommitWidth)
  localparam int ENTRY_PER_BANK  = ROB_SIZE / BANK_NUM; // 每 bank 20 条
  localparam int COMMIT_WIDTH    = 8;              // 每拍最多提交/回滚条数
  localparam int RENAME_WIDTH    = 6;              // 每拍最多入队条数
  localparam int RAB_COMMIT_WIDTH= 6;              // 送 Rab 的提交宽度
  localparam int MAX_UOP_SIZE    = 65;             // 一条指令最多拆成的 uop 数

  localparam int PTR_W           = $clog2(ROB_SIZE);     // robIdx value 宽 = 8
  localparam int BANK_ADDR_W     = $clog2(COMMIT_WIDTH); // bank 内偏移 = 3
  localparam int BANK_SEL_W      = $clog2(BANK_NUM);     // bank 选择 = 3
  localparam int ENTRY_ADDR_W    = $clog2(ENTRY_PER_BANK);// bank 内 raddr = 5(one-hot 20)
  localparam int UOP_CNT_W       = $clog2(MAX_UOP_SIZE+1);// uopNum/realDestSize 宽 = 7
  localparam int INSTR_SIZE_W    = $clog2(RENAME_WIDTH+1);// instrSize 宽 = 3
  localparam int FTQ_PTR_W       = 6;              // ftqIdx.value 宽
  localparam int FTQ_OFFSET_W    = 4;              // ftqOffset 宽
  localparam int IRETIRE_W       = 4;              // trace iretire 宽
  localparam int ITYPE_W         = 4;              // trace itype 宽

  // ---- 写回端口数(由 BackendParams 决定的当前配置) ----
  localparam int NUM_EXU_WB      = 27;             // io.exuWriteback 端口数
  localparam int NUM_WB          = 25;             // io.writeback 端口数(含异常/重定向口)

  // ---- ROB 全局状态机(只有 idle / walk 两态) ----
  // s_idle : 正常按序提交；
  // s_walk : redirect 后回滚投机条目(walkPtr 逐拍前进，追上 redirect 边界即回 idle)。
  typedef enum logic { S_IDLE, S_WALK } rob_state_e;

  // ---- vsetvl flush 位置选择 FSM ----
  // 用于挑出需要 flushPipe 的 vset 指令位置(与提交解耦的小状态机)。
  typedef enum logic [1:0] { VS_IDLE, VS_WAIT_VINSTR, VS_WAIT_FLUSH } vset_state_e;

  // ---- CircularQueuePtr {flag,value}：环形队列指针 ----
  // value ∈ [0,RobSize)；flag 翻转用于区分「绕回一圈」的新旧。
  typedef struct packed {
    logic               flag;
    logic [PTR_W-1:0]   value;
  } rob_ptr_t;

  // ---- 一条 ROB 条目的「核心状态」(RobEntryBundle 的控制相关子集) ----
  // 只保留按序提交/walk/异常判定真正用到的字段；debug_* / 大量 trace 不入核。
  typedef struct packed {
    // —— 状态位 ——
    logic                    valid;          // 条目占用(enq 置 1，commit/flush 清 0)
    logic [UOP_CNT_W-1:0]    uop_num;        // 剩余未写回 uop 数(到 0 表示算完)
    logic                    std_writebacked;// store 的 std 已写回(store 需 sta&std 都回)
    logic [UOP_CNT_W-1:0]    real_dest_size; // 真正写寄存器堆的 uop 数(给 Rab 回收用)
    logic                    need_flush;     // 该指令带异常/flushPipe(commit 时要刷流水)
    logic                    interrupt_safe; // 允许在此指令处响应中断(非 ld/st/fence/csr/vset)
    logic                    mmio;           // 访存为 MMIO(不可投机/不可中断)
    logic                    vls;            // 向量 load/store 指令
    logic [4:0]              fflags;         // 浮点异常标志累计
    logic                    vxsat;          // 向量饱和标志累计
    // —— 静态信息(enq 时写入，commit/异常读) ——
    logic                    rf_wen;         // 写整型寄存器
    logic                    fp_wen;         // 写浮点(= dirtyFs)
    logic                    wflags;         // 写 fflags(浮点)
    logic                    dirty_vs;       // 弄脏向量状态
    logic [2:0]              commit_type;    // NORMAL/BRANCH/LOAD/STORE/...
    logic                    is_rvc;         // 压缩指令
    logic                    is_vset;        // vset 指令
    logic                    is_hls;         // 超级模式 load/store
    logic [INSTR_SIZE_W-1:0] instr_size;     // 压缩后这条占的原始指令数
    logic [FTQ_PTR_W-1:0]    ftq_idx_value;  // 取指队列指针(异常/重定向用)
    logic                    ftq_idx_flag;
    logic [FTQ_OFFSET_W-1:0] ftq_offset;
    // —— trace ——
    logic [ITYPE_W-1:0]      itype;          // 指令类型(branch/jump/...)
    logic [IRETIRE_W-1:0]    iretire;        // 本块退休指令数
    logic [1:0]              ilastsize;      // 末指令大小
  } rob_entry_t;

  // 派生：一条指令是否「完全写回」= 无剩余 uop 且 std 已回。
  function automatic logic entry_writebacked(input rob_entry_t e);
    return (e.uop_num == '0) & e.std_writebacked;
  endfunction
  // 派生：所有 uop 写回(不含 std 约束)。
  function automatic logic entry_uop_writebacked(input rob_entry_t e);
    return (e.uop_num == '0);
  endfunction

  // ---- 提交读出的「分 bank 条目」(RobCommitEntryBundle 的控制子集) ----
  // robDeqGroup：每拍读出 deqPtr 所在行的 8 个 bank，提供给提交/walk 判定。
  typedef struct packed {
    logic                    commit_v;       // = valid
    logic                    commit_w;       // = (uopNum==0)&&std_writebacked，可提交
    logic                    walk_v;         // = valid，可回滚
    logic [UOP_CNT_W-1:0]    real_dest_size; // 给 Rab 的回收映射数
    logic                    interrupt_safe;
    logic                    need_flush;
    logic                    is_vls;
    logic                    vls;
    logic                    mmio;
    logic [2:0]              commit_type;
    logic                    is_rvc;
    logic                    is_vset;
    logic                    is_hls;
    logic                    rf_wen;
    logic                    fp_wen;
    logic                    wflags;
    logic [4:0]              fflags;
    logic                    vxsat;
    logic                    dirty_fs;       // = fp_wen || wflags
    logic                    dirty_vs;
    logic [INSTR_SIZE_W-1:0] instr_size;
    logic [FTQ_PTR_W-1:0]    ftq_idx_value;
    logic                    ftq_idx_flag;
    logic [FTQ_OFFSET_W-1:0] ftq_offset;
    logic [ITYPE_W-1:0]      itype;
    logic [IRETIRE_W-1:0]    iretire;
    logic [1:0]              ilastsize;
  } rob_commit_entry_t;

  // RobEntryBundle → RobCommitEntryBundle(connectCommitEntry)。
  function automatic rob_commit_entry_t connect_commit_entry(input rob_entry_t e);
    rob_commit_entry_t c;
    c.commit_v        = e.valid;
    c.walk_v          = e.valid;
    c.commit_w        = (e.uop_num == '0) & e.std_writebacked;
    c.real_dest_size  = e.real_dest_size;
    c.interrupt_safe  = e.interrupt_safe;
    c.rf_wen          = e.rf_wen;
    c.fp_wen          = e.fp_wen;
    c.fflags          = e.fflags;
    c.wflags          = e.wflags;
    c.vxsat           = e.vxsat;
    c.is_rvc          = e.is_rvc;
    c.is_vset         = e.is_vset;
    c.is_hls          = e.is_hls;
    c.is_vls          = e.vls;
    c.vls             = e.vls;
    c.mmio            = e.mmio;
    c.ftq_idx_value   = e.ftq_idx_value;
    c.ftq_idx_flag    = e.ftq_idx_flag;
    c.ftq_offset      = e.ftq_offset;
    c.commit_type     = e.commit_type;
    c.instr_size      = e.instr_size;
    c.dirty_fs        = e.fp_wen | e.wflags;
    c.dirty_vs        = e.dirty_vs;
    c.need_flush      = e.need_flush;
    c.itype           = e.itype;
    c.iretire         = e.iretire;
    c.ilastsize       = e.ilastsize;
    return c;
  endfunction

endpackage
