// =====================================================================
// mefreelist_pkg —— 重命名「Move-Elimination 空闲列表」(MEFreeList) 的类型与参数
// ---------------------------------------------------------------------
// MEFreeList 管理【整数】物理寄存器的空闲池。它和 StdFreeList 一样是一个
// 支持「投机执行 + 回滚」的循环队列空闲表(Scala 里两者继承同一 BaseFreeList)，
// 但服务于支持 move-elimination 的整数寄存器：
//   - headPtr     指向下一个可【分配】的空闲物理寄存器(出队端，投机态)；
//   - archHeadPtr 是【体系结构态】的 head，仅在 commit 时推进；
//   - tailPtr     指向下一个【回收】物理寄存器的写入位置(入队端)；
//   - freeList[]  数组存放当前空闲的物理寄存器号。
//
// 与 StdFreeList 的关键差异(分配/回退主逻辑相同)：
//   1. freeList 初值：x0..x31 都映射到物理寄存器 0；因此初始时物理寄存器
//      {1,2,...,size-1} 都空闲，0 号被占用(给 x0)。golden 初值为
//      freeList[i] = i+1 (i < size-1)，freeList[size-1] = 0。
//   2. tailPtr 初值 = FreeListPtr(flag=0, value=size-1)：尾指针落在最后一格
//      (此处存的就是 0 号)，因此初始空闲数 = distance(tailPtr, headPtr) = size-1。
//   3. archHeadPtr 推进条件用 rfWen && !isMove(move-elimination：被消除的
//      move 指令不真正占用新物理寄存器，故不推进体系结构 head)。
//   4. 本核直接用 tailPtr(组合算 tailPtrNext)，回收写入用【当前】tailPtr，
//      空闲计数 freeRegCnt 用【下一拍】tailPtrNext —— 这点与 StdFreeList
//      的 lastTailPtr 写法不同(MEFreeList golden 即如此)。
//   5. canAllocate 是组合输出(freeRegCntReg >= RenameWidth)，StdFreeList 是寄存器输出。
//   6. 带 32 个 debug_rat 输入与两级打拍的 debugArchHeadPtr/debugArchRAT 影子寄存器
//      (只喂 XSError 断言，综合口径下是死寄存器，bug-for-bug 保留，见核第 9 节)。
//
// 整数池只有这一个例化(Rename 的 intFreeList，IntPhyRegs=224)，不需要参数化。
// =====================================================================
package mefreelist_pkg;

  // ---- MEFreeList 例化对应整数物理寄存器空闲池 ----
  // IntPhyRegs = 224 → size = 224(注意：整数池 size 直接给 224，不减逻辑寄存器；
  // 0 号被 x0 永久占用，靠 freeList 初值把 0 放到尾格表达"已用"语义)。
  localparam int SIZE          = 224;  // 空闲池容量(循环队列条目数, 非 2 的幂)
  localparam int PHYREG_W      = 8;    // 物理寄存器号位宽 PhyRegIdxWidth
  localparam int RENAME_WIDTH  = 6;    // 每拍重命名(分配)口数
  localparam int COMMIT_WIDTH  = 6;    // 每拍提交/回滚(回收)口数 RabCommitWidth
  localparam int SNAPSHOT_NUM  = 4;    // 快照个数 RenameSnapshotNum
  localparam int NUM_LOGIC_REGS= 32;   // 整数逻辑寄存器数(debug_rat 的项数)

  localparam int PTR_W   = $clog2(SIZE);      // 指针 value 位宽 = 8
  localparam int CNT_W   = $clog2(SIZE + 1);  // 空闲计数位宽 = 8

  // ---- 循环队列指针：flag 区分"绕过几圈"，value 是池内下标 ----
  // 由于 SIZE 非 2 的幂，加法需要手动检测越界回绕(见 ptr_add 函数)。
  typedef struct packed {
    logic               flag;
    logic [PTR_W-1:0]   value;
  } fl_ptr_t;

  // 指针 + 偏移(循环加)。对应 CircularQueuePtr.`+`(非 2 幂分支)：
  //   new_value = value + v；若 new_value >= SIZE 则回绕并翻转 flag。
  function automatic fl_ptr_t ptr_add(input fl_ptr_t p, input logic [PTR_W:0] v);
    logic [PTR_W:0]          new_value;  // value +& v，多 1 bit 防溢出
    logic signed [PTR_W+2:0] diff;
    fl_ptr_t                 r;
    begin
      new_value = {1'b0, p.value} + v;
      diff      = $signed({2'b0, new_value}) - $signed((PTR_W+3)'(SIZE));
      if (diff >= 0) begin           // 越过池尾 → 回绕，翻转 flag
        r.flag  = ~p.flag;
        r.value = diff[PTR_W-1:0];
      end else begin
        r.flag  = p.flag;
        r.value = new_value[PTR_W-1:0];
      end
      return r;
    end
  endfunction

  // 两指针距离：enq 与 deq 之间的有效条目数(circular)。
  function automatic logic [CNT_W-1:0] distance(input fl_ptr_t enq, input fl_ptr_t deq);
    begin
      if (enq.flag == deq.flag)
        return CNT_W'(enq.value - deq.value);
      else
        return CNT_W'((PTR_W+1)'(SIZE) + enq.value - deq.value);
    end
  endfunction

endpackage

// =====================================================================
// xs_MEFreeList_core —— 重命名「Move-Elimination 空闲列表」可读重写
// ---------------------------------------------------------------------
// 功能定位(后端 Rename 级)：
//   为【整数】物理寄存器维护空闲池。重命名时从池里【分配(alloc)】物理
//   寄存器给写整数寄存器的指令；指令在 ROB/RAB 提交或回滚时把旧物理寄存器
//   【回收(free)】回池。支持 move-elimination：被消除的 move 指令不占用
//   新物理寄存器，故提交时不推进体系结构 head。
//
// 三个指针(均为循环队列指针 fl_ptr_t)：
//   headPtr      投机态分配指针(出队端)。每拍按"实际分配个数"前移。
//   archHeadPtr  体系结构态分配指针。仅在 commit 拍按"提交且写整数寄存器
//                且非 move"的指令数前移。redirect 后 head 可回退到它。
//   tailPtr      回收指针(入队端)。按本拍 freeReq 个数前移。
//
// 重定向/回滚(redirect / walk)：
//   分支预测错误时，前两拍打拍的 redirect/snpt 选出回退目标：
//     - 若该错误点之前打了快照(useSnpt)，head 回退到 snapshot + 已 walk 数；
//     - 否则回退到 archHeadPtr + 已 walk 数。
//   随后若 io.walk，按 walkReq(而非 allocateReq)逐条重放分配。
//
// 子模块：快照存储用家族共核 xs_SnapshotGenerator_core(rtl/backend/SnapshotGenerator.sv)，
//   payload = fl_ptr_t 打平(9 位)；golden 对应 SnapshotGenerator(base 变体)。
// =====================================================================
module xs_MEFreeList_core
  import mefreelist_pkg::*;
(
  input  logic                          clock,
  input  logic                          reset,

  input  logic                          io_redirect,
  input  logic                          io_walk,

  // 重命名分配请求(本拍各口是否需要一个新物理寄存器)
  input  logic [RENAME_WIDTH-1:0]       io_allocateReq,
  // 回滚重放时的分配请求(walk 期间用它代替 allocateReq)
  input  logic [COMMIT_WIDTH-1:0]       io_walkReq,
  output logic [PHYREG_W-1:0]           io_allocatePhyReg [RENAME_WIDTH],
  output logic                          io_canAllocate,
  input  logic                          io_doAllocate,

  // 回收：把提交指令的旧物理寄存器写回空闲池
  input  logic [COMMIT_WIDTH-1:0]       io_freeReq,
  input  logic [PHYREG_W-1:0]           io_freePhyReg     [COMMIT_WIDTH],

  // 提交信息：commit 拍推进 archHeadPtr，仅统计"写整数寄存器且非 move"的指令
  input  logic                          io_commit_isCommit,
  input  logic [COMMIT_WIDTH-1:0]       io_commit_commitValid,
  input  logic [COMMIT_WIDTH-1:0]       io_commit_info_rfWen,
  input  logic [COMMIT_WIDTH-1:0]       io_commit_info_isMove,

  // 快照端口(转发给快照存储核)
  input  logic                          io_snpt_snptEnq,
  input  logic                          io_snpt_snptDeq,
  input  logic                          io_snpt_useSnpt,
  input  logic [$clog2(SNAPSHOT_NUM)-1:0] io_snpt_snptSelect,
  input  logic [SNAPSHOT_NUM-1:0]       io_snpt_flushVec,

  // 体系结构态整数 RAT(debug 断言用，见第 9 节)
  input  logic [PHYREG_W-1:0]           io_debug_rat [NUM_LOGIC_REGS],

  output logic [5:0]                    io_perf_value [4]
);

  // -------------------- 小工具函数 --------------------
  // 统计 [0:n) 个 1bit 请求中前 i 个的置位数(用作各口在本拍内的偏移)
  function automatic logic [PTR_W:0] popcnt_below
      (input logic [COMMIT_WIDTH-1:0] req, input int i);
    logic [PTR_W:0] s;
    begin
      s = '0;
      for (int k = 0; k < COMMIT_WIDTH; k++)
        if (k < i && req[k]) s += 1'b1;
      return s;
    end
  endfunction

  function automatic logic [PTR_W:0] popcnt_all_c(input logic [COMMIT_WIDTH-1:0] req);
    logic [PTR_W:0] s; begin s='0; for (int k=0;k<COMMIT_WIDTH;k++) if(req[k]) s+=1'b1; return s; end
  endfunction
  function automatic logic [PTR_W:0] popcnt_all_r(input logic [RENAME_WIDTH-1:0] req);
    logic [PTR_W:0] s; begin s='0; for (int k=0;k<RENAME_WIDTH;k++) if(req[k]) s+=1'b1; return s; end
  endfunction
  function automatic logic [PTR_W:0] popcnt_below_r
      (input logic [RENAME_WIDTH-1:0] req, input int i);
    logic [PTR_W:0] s;
    begin s='0; for (int k=0;k<RENAME_WIDTH;k++) if(k<i && req[k]) s+=1'b1; return s; end
  endfunction

  // =====================================================================
  // 1. 空闲池存储 + 三个指针寄存器
  // =====================================================================
  logic [PHYREG_W-1:0] freeList [SIZE];

  fl_ptr_t headPtr;            // 投机态分配指针
  logic [SIZE-1:0] headPtrOH;  // headPtr 的 one-hot 冗余表示
  fl_ptr_t archHeadPtr;        // 体系结构态分配指针
  fl_ptr_t tailPtr;            // 回收入队点(本核直接用，不打 lastTailPtr)

  // -------------------- 两拍打拍的 redirect / snpt --------------------
  // 与 Scala 的 lastCycleRedirect = RegNext(RegNext(io.redirect)) 一致：
  // redirect/snpt 的影响延迟两拍生效(_REG 为第一级，无后缀为第二级)。
  logic        lastCycleRedirect_REG,        lastCycleRedirect;
  logic        lastCycleSnpt_REG_useSnpt,    lastCycleSnpt_useSnpt;
  logic [$clog2(SNAPSHOT_NUM)-1:0] lastCycleSnpt_REG_snptSelect, lastCycleSnpt_snptSelect;

  // =====================================================================
  // 2. 分配候选：headPtrOH 循环左移 0..RenameWidth 步，每步 Mux1H 选一个
  //    空闲寄存器。第 i 个分配口取第 (前 i 口 allocateReq 个数) 个候选。
  // =====================================================================
  // 循环左移 s 步：位 j 来自 (j - s) mod SIZE
  function automatic logic [SIZE-1:0] rotl(input logic [SIZE-1:0] x, input int s);
    logic [SIZE-1:0] y;
    int src;
    begin
      y = '0;
      for (int j = 0; j < SIZE; j++) begin
        src = (j - s + SIZE) % SIZE;
        y[j] = x[src];
      end
      return y;
    end
  endfunction

  // 分配候选个数 = RenameWidth+1(移位 0..RenameWidth)。数组开到 2 的幂(NCAND_P2)
  // 并用 3bit 索引，使所有下标静态可证在界内(便于 FM 解释，避免越界告警)。
  localparam int NCAND   = RENAME_WIDTH + 1;   // 7
  localparam int NCAND_P2= 8;                  // 下一 2 的幂
  localparam int CAND_IW = 3;                  // 候选索引位宽

  // headPtrOHVec[s] = headPtrOH 循环左移 s 步
  logic [SIZE-1:0] headPtrOHVec [NCAND_P2];
  always_comb begin
    for (int s = 0; s < NCAND_P2; s++) headPtrOHVec[s] = '0;
    for (int s = 0; s < NCAND;    s++) headPtrOHVec[s] = rotl(headPtrOH, s);
  end

  // phyRegCandidates[s] = Mux1H(headPtrOHVec[s], freeList)
  logic [PHYREG_W-1:0] phyRegCandidates [NCAND_P2];
  always_comb begin
    for (int s = 0; s < NCAND_P2; s++) begin
      logic [PHYREG_W-1:0] sel;
      sel = '0;
      for (int j = 0; j < SIZE; j++)
        if (headPtrOHVec[s][j]) sel |= freeList[j];
      phyRegCandidates[s] = sel;
    end
  end

  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      io_allocatePhyReg[i] = phyRegCandidates[CAND_IW'(popcnt_below_r(io_allocateReq, i))];

  // =====================================================================
  // 3. 体系结构态 head：commit 拍按"提交且写整数寄存器且非 move"的指令数推进
  //    move-elimination：被消除的 move 不占用新物理寄存器，故不计入。
  // =====================================================================
  logic [COMMIT_WIDTH-1:0] archAlloc;
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++)
      archAlloc[i] = io_commit_commitValid[i] & io_commit_info_rfWen[i] & ~io_commit_info_isMove[i];

  wire fl_ptr_t archHeadPtrNew  = ptr_add(archHeadPtr, popcnt_all_c(archAlloc));
  wire fl_ptr_t archHeadPtrNext = io_commit_isCommit ? archHeadPtrNew : archHeadPtr;

  // =====================================================================
  // 4. 重定向回退目标：snapshot 或 archHeadPtr，再加上已 walk 的请求数
  // =====================================================================
  // 快照存储(家族共核)：存 headPtr 的快照，供 redirect 回退选择。
  // payload 就是 fl_ptr_t 打平({flag, value}，flag 在高位)。
  localparam int SNAP_W = $bits(fl_ptr_t);          // = 9
  logic [SNAP_W-1:0] snapshots [SNAPSHOT_NUM];

  xs_SnapshotGenerator_core #(.DATA_W(SNAP_W)) snapshots_snapshotGen (
    .clock     (clock),
    .reset     (reset),
    .enq       (io_snpt_snptEnq),
    .enq_data  (headPtr),
    .deq       (io_snpt_snptDeq),
    .redirect  (io_redirect),
    .flush_vec (io_snpt_flushVec),
    .snapshots (snapshots),
    .enq_ptr   (),   // golden 本变体没导出这三组端口(见 SnapshotGenerator.sv 文件头)
    .deq_ptr   (),
    .valids    ()
  );

  // 选中的快照(用两拍前打拍的 snptSelect)
  wire fl_ptr_t selSnap = snapshots[lastCycleSnpt_snptSelect];

  wire [PTR_W:0] numWalk = popcnt_all_c(io_walkReq);
  wire fl_ptr_t redirectBase   = lastCycleSnpt_useSnpt ? selSnap : archHeadPtr;
  wire fl_ptr_t redirectedHead = ptr_add(redirectBase, numWalk);

  // =====================================================================
  // 5. 回收(free)：把旧物理寄存器写回 freeList，并推进 tailPtr
  //    第 i 口写入位置 = tailPtr + (前 i 口的 freeReq 个数)
  //    (MEFreeList 用【当前】tailPtr 做写入地址，与 StdFreeList 的 lastTailPtr 不同)
  // =====================================================================
  fl_ptr_t tailPtrNext;
  always_comb tailPtrNext = ptr_add(tailPtr, popcnt_all_c(io_freeReq));

  // 每个回收口 i 的写入下标 = tailPtr + (前 i 口 freeReq 个数)，预先算好。
  // 写回时按"条目 E 是否等于某口的写入下标"做显式地址译码(常量比较，无变量
  // 下标)，从而不产生越界 X，且把回收的地址译码逻辑表达得很直白。
  logic [PTR_W-1:0] freeEnqIdx [COMMIT_WIDTH];
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      fl_ptr_t enq;
      enq = ptr_add(tailPtr, popcnt_below(io_freeReq, i));
      freeEnqIdx[i] = enq.value;
    end

  // =====================================================================
  // 6. 投机态 head 更新 + 空闲计数
  //    分配个数：walk 时用 walkReq，否则用 allocateReq。
  // =====================================================================
  wire isWalkAlloc   = io_walk && io_doAllocate && !io_redirect;        // doWalkRename
  wire isNormalAlloc = io_canAllocate && io_doAllocate && !io_redirect; // doNormalRename
  wire isAllocate    = isWalkAlloc || isNormalAlloc;                    // doRename

  wire [PTR_W:0] numAllocate = io_walk ? popcnt_all_c(io_walkReq)
                                       : popcnt_all_r(io_allocateReq);

  // 正常前移：head + numAllocate；其 OH 取 headPtrOHVec[numAllocate]
  wire fl_ptr_t headPtrFwd = ptr_add(headPtr, numAllocate);

  wire fl_ptr_t headPtrNew =
      lastCycleRedirect ? redirectedHead : headPtrFwd;

  // headPtrOH 的下一值：回退时用 redirectedHead 的 OH，否则用移位向量。
  // 用移位生成 one-hot(而非变量下标赋值)：下标越界时 1 被移出、不产生 X。
  logic [SIZE-1:0] redirectedHeadOH;
  always_comb redirectedHeadOH = (SIZE'(1) << redirectedHead.value);
  wire [SIZE-1:0] headPtrOHNew =
      lastCycleRedirect ? redirectedHeadOH : headPtrOHVec[CAND_IW'(numAllocate)];

  // 空闲寄存器数(组合)：tailPtrNext 与 head 的距离，减去本拍要分配的数
  // 注意 MEFreeList 用 tailPtrNext(下一拍尾)，而非当前 tailPtr。
  logic [CNT_W-1:0] freeRegCnt;
  always_comb begin
    if (isWalkAlloc && !lastCycleRedirect)
      freeRegCnt = distance(tailPtrNext, headPtr) - CNT_W'(popcnt_all_c(io_walkReq));
    else if (isNormalAlloc)
      freeRegCnt = distance(tailPtrNext, headPtr) - CNT_W'(popcnt_all_r(io_allocateReq));
    else
      freeRegCnt = distance(tailPtrNext, headPtr);
  end

  // freeRegCnt 打一拍 → canAllocate 组合判定(空闲数 >= RenameWidth)
  logic [CNT_W-1:0] freeRegCntReg;
  always_ff @(posedge clock) freeRegCntReg <= freeRegCnt;
  always_comb io_canAllocate = (freeRegCntReg >= CNT_W'(RENAME_WIDTH));

  // 优先级：异常/flush(redirect) 时不推进 head；否则确实分配时才推进。
  // (isWalkAlloc/isNormalAlloc 已含 !io_redirect，doRename 自然满足)
  wire realDoAllocate = isAllocate;

  // =====================================================================
  // 7. 寄存器更新
  // =====================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      headPtr      <= '{flag:1'b0, value:'0};
      headPtrOH    <= {{(SIZE-1){1'b0}}, 1'b1};
      archHeadPtr  <= '{flag:1'b0, value:'0};
      tailPtr      <= '{flag:1'b0, value:PTR_W'(SIZE-1)}; // 尾指针落在最后一格
      // 仅 snpt 第一级带复位初值 0(对应 Scala RegNext(io.snpt, 0))；
      // redirect 两级与 snpt 第二级无复位(RegNext 无初值)，见下方独立 always_ff。
      lastCycleSnpt_REG_useSnpt    <= 1'b0;
      lastCycleSnpt_REG_snptSelect <= '0;
      // freeList 初值：{1,2,...,size-1, 0}。物理寄存器 0 给 x0(放尾格)。
      for (int i = 0; i < SIZE-1; i++)
        freeList[i] <= PHYREG_W'(i + 1);
      freeList[SIZE-1] <= '0;
    end else begin
      if (realDoAllocate) begin
        headPtr   <= headPtrNew;
        headPtrOH <= headPtrOHNew;
      end
      archHeadPtr <= archHeadPtrNext;

      // 回收写回：对每个条目 E 做地址译码——若某口要写且其写入下标==E 则写入。
      // 多口命中同一 E 时高编号口优先(与 golden 一致；正常流控下不会冲突)。
      for (int e = 0; e < SIZE; e++)
        for (int i = 0; i < COMMIT_WIDTH; i++)
          if (io_freeReq[i] && freeEnqIdx[i] == PTR_W'(e))
            freeList[e] <= io_freePhyReg[i];
      tailPtr <= tailPtrNext;

      lastCycleSnpt_REG_useSnpt    <= io_snpt_useSnpt;
      lastCycleSnpt_REG_snptSelect <= io_snpt_snptSelect;
    end
  end

  // 无复位的打拍级(对应 golden 不带 reset 的 always 块；RegNext 无初值)：
  // redirect 两级 + snpt 第二级。复位时这些值无定义(综合按 RANDOM/X 处理)。
  always_ff @(posedge clock) begin
    lastCycleRedirect_REG    <= io_redirect;
    lastCycleRedirect        <= lastCycleRedirect_REG;
    lastCycleSnpt_useSnpt    <= lastCycleSnpt_REG_useSnpt;
    lastCycleSnpt_snptSelect <= lastCycleSnpt_REG_snptSelect;
  end

  // =====================================================================
  // 8. 性能事件(空闲度四分位)，两级打拍以匹配 golden
  //    边界与 golden 一致：size/4=56, size/2=112, 3size/4=168；
  //    ★注意 MEFreeList 的中间两档上界是 <=(Scala 写的 <=)，StdFreeList 是 <★
  // =====================================================================
  localparam int Q1 = SIZE/4;       // 56
  localparam int Q2 = SIZE/2;       // 112
  localparam int Q3 = SIZE*3/4;     // 168

  logic [3:0] perf_s1, perf_s2;
  always_ff @(posedge clock) begin
    perf_s1[0] <= (freeRegCntReg <  CNT_W'(Q1));
    perf_s1[1] <= (freeRegCntReg >= CNT_W'(Q1) && freeRegCntReg <= CNT_W'(Q2));
    perf_s1[2] <= (freeRegCntReg >= CNT_W'(Q2) && freeRegCntReg <= CNT_W'(Q3));
    perf_s1[3] <= (freeRegCntReg >= CNT_W'(Q3));
    perf_s2    <= perf_s1;
  end
  always_comb for (int i=0;i<4;i++) io_perf_value[i] = {5'h0, perf_s2[i]};

  // =====================================================================
  // 9. debug 影子寄存器(bug-for-bug 保留的死位)
  //    Scala(backendParams.debugEn=true)：
  //      debugArchHeadPtr = RegNext(RegNext(archHeadPtr, 0), 0)      —— 两级打拍，复位 0
  //      debugArchRAT     = RegNext(RegNext(io.debug_rat, 0), 0)     —— 32×8 两级打拍，复位 0
  //    它们唯一的读者是 XSError("Integer physical register should be in either arch
  //    RAT or arch free list")，综合口径(`define SYNTHESIS)下断言不存在 ⇒ 这 530 位
  //    寄存器没有任何可观测扇出。golden 原样保留它们(firtool 不删有复位的寄存器)，
  //    重写核按同名同宽同源复刻，使两侧成为对称死位(FM 里按名配对成 matched-unread，
  //    由 verif/fm_target_config/MEFreeList.tcl 的 vmucp 加强去证)。
  //    ★不能删★：删掉就成 golden-only 死位，signoff-strict 直接 PARTIAL。
  // =====================================================================
  //    ★命名对齐 golden★：这些死位没有可观测锥，FM 的签名分析配不上它们，只能靠
  //    scripts/fm_eq.tcl 的 auto_match_flattened_arrays 按名配对(<名>_<i>_reg ↔ <名>_reg[i])，
  //    所以指针不用 fl_ptr_t 结构体而拆成 _flag/_value 两个标量(与 golden 展平名同形)。
  logic                debugArchHeadPtr_REG_flag, debugArchHeadPtr_flag;
  logic [PTR_W-1:0]    debugArchHeadPtr_REG_value, debugArchHeadPtr_value;
  logic [PHYREG_W-1:0] debugArchRAT_REG [NUM_LOGIC_REGS];
  logic [PHYREG_W-1:0] debugArchRAT     [NUM_LOGIC_REGS];
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      debugArchHeadPtr_REG_flag  <= 1'b0;
      debugArchHeadPtr_REG_value <= '0;
      debugArchHeadPtr_flag      <= 1'b0;
      debugArchHeadPtr_value     <= '0;
      for (int i = 0; i < NUM_LOGIC_REGS; i++) begin
        debugArchRAT_REG[i] <= '0;
        debugArchRAT[i]     <= '0;
      end
    end else begin
      debugArchHeadPtr_REG_flag  <= archHeadPtr.flag;
      debugArchHeadPtr_REG_value <= archHeadPtr.value;
      debugArchHeadPtr_flag      <= debugArchHeadPtr_REG_flag;
      debugArchHeadPtr_value     <= debugArchHeadPtr_REG_value;
      for (int i = 0; i < NUM_LOGIC_REGS; i++) begin
        debugArchRAT_REG[i] <= io_debug_rat[i];
        debugArchRAT[i]     <= debugArchRAT_REG[i];
      end
    end
  end

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper —— golden 同名扁平端口 → 可读核 xs_MEFreeList_core 的机械适配层
// ---------------------------------------------------------------------------

module MEFreeList(
  input        clock,
  input        reset,
  input        io_redirect,
  input        io_walk,
  input        io_allocateReq_0,
  input        io_allocateReq_1,
  input        io_allocateReq_2,
  input        io_allocateReq_3,
  input        io_allocateReq_4,
  input        io_allocateReq_5,
  input        io_walkReq_0,
  input        io_walkReq_1,
  input        io_walkReq_2,
  input        io_walkReq_3,
  input        io_walkReq_4,
  input        io_walkReq_5,
  output [7:0] io_allocatePhyReg_0,
  output [7:0] io_allocatePhyReg_1,
  output [7:0] io_allocatePhyReg_2,
  output [7:0] io_allocatePhyReg_3,
  output [7:0] io_allocatePhyReg_4,
  output [7:0] io_allocatePhyReg_5,
  output       io_canAllocate,
  input        io_doAllocate,
  input        io_freeReq_0,
  input        io_freeReq_1,
  input        io_freeReq_2,
  input        io_freeReq_3,
  input        io_freeReq_4,
  input        io_freeReq_5,
  input  [7:0] io_freePhyReg_0,
  input  [7:0] io_freePhyReg_1,
  input  [7:0] io_freePhyReg_2,
  input  [7:0] io_freePhyReg_3,
  input  [7:0] io_freePhyReg_4,
  input  [7:0] io_freePhyReg_5,
  input        io_commit_isCommit,
  input        io_commit_commitValid_0,
  input        io_commit_commitValid_1,
  input        io_commit_commitValid_2,
  input        io_commit_commitValid_3,
  input        io_commit_commitValid_4,
  input        io_commit_commitValid_5,
  input        io_commit_info_0_rfWen,
  input        io_commit_info_0_isMove,
  input        io_commit_info_1_rfWen,
  input        io_commit_info_1_isMove,
  input        io_commit_info_2_rfWen,
  input        io_commit_info_2_isMove,
  input        io_commit_info_3_rfWen,
  input        io_commit_info_3_isMove,
  input        io_commit_info_4_rfWen,
  input        io_commit_info_4_isMove,
  input        io_commit_info_5_rfWen,
  input        io_commit_info_5_isMove,
  input        io_snpt_snptEnq,
  input        io_snpt_snptDeq,
  input        io_snpt_useSnpt,
  input  [1:0] io_snpt_snptSelect,
  input        io_snpt_flushVec_0,
  input        io_snpt_flushVec_1,
  input        io_snpt_flushVec_2,
  input        io_snpt_flushVec_3,
  input  [7:0] io_debug_rat_0,
  input  [7:0] io_debug_rat_1,
  input  [7:0] io_debug_rat_2,
  input  [7:0] io_debug_rat_3,
  input  [7:0] io_debug_rat_4,
  input  [7:0] io_debug_rat_5,
  input  [7:0] io_debug_rat_6,
  input  [7:0] io_debug_rat_7,
  input  [7:0] io_debug_rat_8,
  input  [7:0] io_debug_rat_9,
  input  [7:0] io_debug_rat_10,
  input  [7:0] io_debug_rat_11,
  input  [7:0] io_debug_rat_12,
  input  [7:0] io_debug_rat_13,
  input  [7:0] io_debug_rat_14,
  input  [7:0] io_debug_rat_15,
  input  [7:0] io_debug_rat_16,
  input  [7:0] io_debug_rat_17,
  input  [7:0] io_debug_rat_18,
  input  [7:0] io_debug_rat_19,
  input  [7:0] io_debug_rat_20,
  input  [7:0] io_debug_rat_21,
  input  [7:0] io_debug_rat_22,
  input  [7:0] io_debug_rat_23,
  input  [7:0] io_debug_rat_24,
  input  [7:0] io_debug_rat_25,
  input  [7:0] io_debug_rat_26,
  input  [7:0] io_debug_rat_27,
  input  [7:0] io_debug_rat_28,
  input  [7:0] io_debug_rat_29,
  input  [7:0] io_debug_rat_30,
  input  [7:0] io_debug_rat_31,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value
);
  logic [5:0] io_allocateReq;
  logic [5:0] io_walkReq;
  logic [7:0] allocatePhyReg [6];
  logic [5:0] io_freeReq;
  logic [7:0] freePhyReg [6];
  logic [5:0] io_commit_commitValid;
  logic [5:0] io_commit_info_rfWen;
  logic [5:0] io_commit_info_isMove;
  logic [3:0] io_snpt_flushVec;
  logic [7:0] debug_rat [32];
  logic [5:0] perf_value [4];

  assign io_allocateReq = {io_allocateReq_5, io_allocateReq_4, io_allocateReq_3,
                           io_allocateReq_2, io_allocateReq_1, io_allocateReq_0};
  assign io_walkReq     = {io_walkReq_5, io_walkReq_4, io_walkReq_3,
                           io_walkReq_2, io_walkReq_1, io_walkReq_0};
  assign io_freeReq     = {io_freeReq_5, io_freeReq_4, io_freeReq_3,
                           io_freeReq_2, io_freeReq_1, io_freeReq_0};
  assign freePhyReg     = '{io_freePhyReg_0, io_freePhyReg_1, io_freePhyReg_2,
                            io_freePhyReg_3, io_freePhyReg_4, io_freePhyReg_5};
  assign io_commit_commitValid = {io_commit_commitValid_5, io_commit_commitValid_4,
                                  io_commit_commitValid_3, io_commit_commitValid_2,
                                  io_commit_commitValid_1, io_commit_commitValid_0};
  assign io_commit_info_rfWen  = {io_commit_info_5_rfWen, io_commit_info_4_rfWen,
                                  io_commit_info_3_rfWen, io_commit_info_2_rfWen,
                                  io_commit_info_1_rfWen, io_commit_info_0_rfWen};
  assign io_commit_info_isMove = {io_commit_info_5_isMove, io_commit_info_4_isMove,
                                  io_commit_info_3_isMove, io_commit_info_2_isMove,
                                  io_commit_info_1_isMove, io_commit_info_0_isMove};
  assign io_snpt_flushVec = {io_snpt_flushVec_3, io_snpt_flushVec_2,
                             io_snpt_flushVec_1, io_snpt_flushVec_0};
  assign debug_rat = '{io_debug_rat_0,  io_debug_rat_1,  io_debug_rat_2,  io_debug_rat_3,
                       io_debug_rat_4,  io_debug_rat_5,  io_debug_rat_6,  io_debug_rat_7,
                       io_debug_rat_8,  io_debug_rat_9,  io_debug_rat_10, io_debug_rat_11,
                       io_debug_rat_12, io_debug_rat_13, io_debug_rat_14, io_debug_rat_15,
                       io_debug_rat_16, io_debug_rat_17, io_debug_rat_18, io_debug_rat_19,
                       io_debug_rat_20, io_debug_rat_21, io_debug_rat_22, io_debug_rat_23,
                       io_debug_rat_24, io_debug_rat_25, io_debug_rat_26, io_debug_rat_27,
                       io_debug_rat_28, io_debug_rat_29, io_debug_rat_30, io_debug_rat_31};

  assign io_allocatePhyReg_0 = allocatePhyReg[0];
  assign io_allocatePhyReg_1 = allocatePhyReg[1];
  assign io_allocatePhyReg_2 = allocatePhyReg[2];
  assign io_allocatePhyReg_3 = allocatePhyReg[3];
  assign io_allocatePhyReg_4 = allocatePhyReg[4];
  assign io_allocatePhyReg_5 = allocatePhyReg[5];
  assign io_perf_0_value = perf_value[0];
  assign io_perf_1_value = perf_value[1];
  assign io_perf_2_value = perf_value[2];
  assign io_perf_3_value = perf_value[3];

  xs_MEFreeList_core u_core (
    .clock(clock),
    .reset(reset),
    .io_redirect(io_redirect),
    .io_walk(io_walk),
    .io_allocateReq(io_allocateReq),
    .io_walkReq(io_walkReq),
    .io_allocatePhyReg(allocatePhyReg),
    .io_canAllocate(io_canAllocate),
    .io_doAllocate(io_doAllocate),
    .io_freeReq(io_freeReq),
    .io_freePhyReg(freePhyReg),
    .io_commit_isCommit(io_commit_isCommit),
    .io_commit_commitValid(io_commit_commitValid),
    .io_commit_info_rfWen(io_commit_info_rfWen),
    .io_commit_info_isMove(io_commit_info_isMove),
    .io_snpt_snptEnq(io_snpt_snptEnq),
    .io_snpt_snptDeq(io_snpt_snptDeq),
    .io_snpt_useSnpt(io_snpt_useSnpt),
    .io_snpt_snptSelect(io_snpt_snptSelect),
    .io_snpt_flushVec(io_snpt_flushVec),
    .io_debug_rat(debug_rat),
    .io_perf_value(perf_value)
  );
endmodule
