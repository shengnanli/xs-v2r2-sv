// =====================================================================
// renamebuffer_pkg —— RenameBuffer(重命名缓冲 Rab)的类型与参数
// ---------------------------------------------------------------------
// 设计意图来自 src/main/scala/xiangshan/backend/rob/Rab.scala (class RenameBuffer)。
//
// RenameBuffer 是一个 RabSize=256 项的【环形队列】，记录每条「需要写寄存器」的指令
// 的「逻辑寄存器号 ldest → 新物理号 pdest + 各写使能」映射(RabCommitInfo)。它把
// 「重命名(rename) 入队」与「ROB 按序提交(commit) 出队」解耦：
//
//   入队(enq)  rename 级每拍最多 RenameWidth=6 条指令，只有 needWriteRf 的才真正占位
//              (realNeedAlloc)。入队指针 enqPtr 前进 enqCount。
//   出队(deq)  ROB 提交时按 commit 数把队头若干项弹出(deqPtr 前进)，这些项的
//              (ldest,pdest) 通过 io.commits 交给 RenameTable 的 archWrite，从而把
//              旧物理号交还 freelist 回收。
//   回滚(walk) 重定向(redirect)时分两种：
//              ① 用快照(useSnpt)：walkPtr 跳到快照点，从那里 s_walk 逐拍回放到 enqPtr，
//                 把投机映射写回 RAT 的 specTable(io.commits.walkValid)。
//              ② 不用快照(special_walk)：先把"已提交待回收"的 commitSize 转成
//                 specialWalkSize，用 deqPtr 走一遍 s_special_walk(同时是 commit 又是
//                 walk)，再转入普通 s_walk。
//   压缩(compress) commit/walk 每拍可处理最多 RabCommitWidth=6 项；commitSize/walkSize
//              是"待处理累计数"，commitNum/walkNum 是本拍实际处理数(由 commitValid 压缩)。
//
// 指针采用 CircularQueuePtr：{flag,value}，flag 是绕回标志位(用于区分空/满与先后)。
// 比对见 golden/chisel-rtl/RenameBuffer.sv。文档见 docs/backend/RenameBuffer.md。
// =====================================================================
package renamebuffer_pkg;

  // ---- 例化参数(KunmingHu 默认配置) ----
  localparam int RAB_SIZE      = 256;  // 环形队列深度 RabSize
  localparam int PTR_W         = 8;    // 队列指针 value 位宽 = log2(256)
  localparam int RENAME_WIDTH  = 6;    // 每拍入队口数 RenameWidth
  localparam int COMMIT_WIDTH  = 6;    // 每拍 commit/walk 口数 RabCommitWidth
  localparam int LDEST_W       = 6;    // 逻辑寄存器号位宽 LogicRegsWidth
  localparam int PDEST_W       = 8;    // 物理寄存器号位宽 PhyRegIdxWidth
  localparam int SNAP_SEL_W    = 2;    // 快照选择位宽 = log2(RenameSnapshotNum=4)
  localparam int SNAPSHOT_NUM  = 4;    // 快照个数 RenameSnapshotNum
  // diff 输出口数 = difftest 用，等于本 golden 例化暴露的索引数(0..254)。
  localparam int NUM_DIFF      = 255;

  // ---- 队列指针 {flag,value}(CircularQueuePtr) ----
  // value 在 [0,RAB_SIZE) 间环绕；flag 每绕回一圈翻转，用于区分"队列绕了几圈"。
  typedef struct packed {
    logic               flag;
    logic [PTR_W-1:0]   value;
  } rab_ptr_t;

  // ---- 一条入队请求(来自 rename 的 DynInst 中与 Rab 相关的字段) ----
  typedef struct packed {
    logic               valid;    // 该口有指令
    logic [LDEST_W-1:0] ldest;    // 目的逻辑寄存器号
    logic [PDEST_W-1:0] pdest;    // 新分配的物理寄存器号
    logic               rfWen;    // 写整数寄存器
    logic               fpWen;    // 写浮点寄存器
    logic               vecWen;   // 写向量寄存器
    logic               v0Wen;    // 写 v0
    logic               vlWen;    // 写 vl
    logic               isMove;   // move 消除标记(供 RAT/freelist 区分)
  } rab_req_t;

  // ---- 队列条目存储的映射信息(RabCommitInfo) ----
  // 这是真正存进 256 项环形队列里的内容；commit/walk 时原样读出送 io.commits.info。
  typedef struct packed {
    logic [LDEST_W-1:0] ldest;
    logic [PDEST_W-1:0] pdest;
    logic               rfWen;
    logic               fpWen;
    logic               vecWen;
    logic               v0Wen;
    logic               vlWen;
    logic               isMove;
  } rab_info_t;

  // ---- 状态机(对应 Scala 的 Enum(3))：s_idle / s_special_walk / s_walk ----
  // 注意编码必须与 golden 一致：idle=0, special_walk=1, walk=2(redirect/transition 都依赖)。
  typedef enum logic [1:0] {
    S_IDLE         = 2'd0,  // 正常：边入队边按 commit 出队
    S_SPECIAL_WALK = 2'd1,  // 无快照回滚的过渡态：用 deqPtr 把已提交项走完(既 commit 又 walk)
    S_WALK         = 2'd2   // 普通回滚：从快照/过渡点逐拍回放投机映射到 enqPtr
  } rab_state_e;

  // 把入队请求字段打包成条目信息(入队时写进队列)。
  function automatic rab_info_t req_to_info(input rab_req_t r);
    rab_info_t o;
    o.ldest  = r.ldest;
    o.pdest  = r.pdest;
    o.rfWen  = r.rfWen;
    o.fpWen  = r.fpWen;
    o.vecWen = r.vecWen;
    o.v0Wen  = r.v0Wen;
    o.vlWen  = r.vlWen;
    o.isMove = r.isMove;
    return o;
  endfunction

  // 该口指令是否"真正需要占用一个 Rab 表项"：valid 且写任一寄存器堆。
  function automatic logic real_need_alloc(input rab_req_t r);
    return r.valid & (r.rfWen | r.fpWen | r.vecWen | r.v0Wen | r.vlWen);
  endfunction

endpackage
