// =====================================================================
// xs_StdFreeList_core —— 重命名「标准空闲列表」可读重写
// ---------------------------------------------------------------------
// 功能定位(后端 Rename 级)：
//   为一类物理寄存器(浮点 Reg_F / 向量 Reg_V/V0/Vl)维护空闲池。
//   重命名时从池里【分配(alloc)】物理寄存器给写寄存器的指令；指令在
//   ROB/RAB 提交或回滚时把不再需要的旧物理寄存器【回收(free)】回池。
//
// 三个指针(均为循环队列指针 fl_ptr_t)：
//   headPtr      投机态分配指针(出队端)。每拍按"实际分配个数"前移。
//   archHeadPtr  体系结构态分配指针。仅在 commit 拍按"提交且写该类
//                寄存器的指令数"前移。redirect 后 head 可回退到它。
//   tailPtr      回收指针(入队端)。按本拍 freeReq 个数前移。
//                (代码里用 lastTailPtr 保存上拍 tail 以改善时序)
//
// 重定向/回滚(redirect / walk)：
//   分支预测错误时，前两拍打拍的 redirect/snpt 选出回退目标：
//     - 若该错误点之前打了快照(useSnpt)，head 回退到 snapshot + 已 walk 数；
//     - 否则回退到 archHeadPtr + 已 walk 数。
//   随后若 io.walk，按 walkReq(而非 allocateReq)逐条重放分配。
//
// 关键设计点：
//   * headPtrOH 与 headPtr 是同一指针的 one-hot 冗余表示，用 Mux1H 选
//     freeList，省去对 158 路做译码比较，改善时序。
//   * canAllocate 打一拍：只有空闲数 > RenameWidth 时才允许分配，从而
//     保证"本拍回收的寄存器下一拍才可能被分配"，free 路径可安全打拍。
//
// 注：本核把 SnapshotGenerator 当黑盒例化(golden 同名子模块)，只复用
//     其快照存储/选择，分配/回收/回滚主逻辑在本核内可读重写。
// =====================================================================
module xs_StdFreeList_core
  import stdfreelist_pkg::*;
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

  // 提交信息：commit 拍推进 archHeadPtr，仅统计写该类寄存器的指令
  input  logic                          io_commit_isCommit,
  input  logic [COMMIT_WIDTH-1:0]       io_commit_commitValid,
  input  logic [COMMIT_WIDTH-1:0]       io_commit_info_fpWen,

  // 快照端口(直接转发给 SnapshotGenerator 黑盒)
  input  logic                          io_snpt_snptEnq,
  input  logic                          io_snpt_snptDeq,
  input  logic                          io_snpt_useSnpt,
  input  logic [$clog2(SNAPSHOT_NUM)-1:0] io_snpt_snptSelect,
  input  logic [SNAPSHOT_NUM-1:0]       io_snpt_flushVec,

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
  fl_ptr_t lastTailPtr;        // 上拍 tail(回收入队点)，改善时序

  // -------------------- 两拍打拍的 redirect / snpt --------------------
  // 与 Scala 的 lastCycleRedirect = RegNext(RegNext(io.redirect)) 一致：
  // redirect/snpt 的影响延迟两拍生效(_REG 为第一级，无后缀为第二级)。
  logic        lastCycleRedirect_REG,        lastCycleRedirect;
  logic        lastCycleSnpt_REG_useSnpt,    lastCycleSnpt_useSnpt;
  logic [$clog2(SNAPSHOT_NUM)-1:0] lastCycleSnpt_REG_snptSelect, lastCycleSnpt_snptSelect;

  // =====================================================================
  // 2. 回收(free)：把旧物理寄存器写回 freeList，并推进 tailPtr
  //    第 i 口写入位置 = lastTailPtr + (前 i 口的 freeReq 个数)
  //    为何能直接用 io.freeReq(组合)而非寄存：canAllocate 保证本拍回收的
  //    寄存器至少下一拍才会被分配，故回收写入与读出不冲突。
  // =====================================================================
  fl_ptr_t tailPtr;
  always_comb tailPtr = ptr_add(lastTailPtr, popcnt_all_c(io_freeReq));

  // 每个回收口 i 的写入下标 = lastTailPtr + (前 i 口 freeReq 个数)，预先算好。
  // 写回时按"条目 E 是否等于某口的写入下标"做显式地址译码(常量比较，无变量
  // 下标)，从而不产生越界 X，且把回收的地址译码逻辑表达得很直白。
  logic [PTR_W-1:0] freeEnqIdx [COMMIT_WIDTH];
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      fl_ptr_t enq;
      enq = ptr_add(lastTailPtr, popcnt_below(io_freeReq, i));
      freeEnqIdx[i] = enq.value;
    end

  // 实际写回(freeList 数组 + lastTailPtr)在下方统一的 always_ff(第 7 节)进行，
  // 以避免对同一变量出现多个过程驱动。

  // =====================================================================
  // 3. 分配候选：headPtrOH 循环左移 0..RenameWidth 步，每步 Mux1H 选一个
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

  // 分配候选个数 = RenameWidth+1(移位 0..RenameWidth)。数组开到 2 的幂(NCAND)
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
  // 4. 体系结构态 head：commit 拍按"提交且写该类寄存器"的指令数推进
  // =====================================================================
  logic [COMMIT_WIDTH-1:0] archAlloc;
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++)
      archAlloc[i] = io_commit_commitValid[i] & io_commit_info_fpWen[i];

  wire fl_ptr_t archHeadPtrNew  = ptr_add(archHeadPtr, popcnt_all_c(archAlloc));
  wire fl_ptr_t archHeadPtrNext = io_commit_isCommit ? archHeadPtrNew : archHeadPtr;

  // =====================================================================
  // 5. 重定向回退目标：snapshot 或 archHeadPtr，再加上已 walk 的请求数
  // =====================================================================
  // SnapshotGenerator 黑盒：存储 head 的快照，供 redirect 回退选择
  logic                snap_flag  [SNAPSHOT_NUM];
  logic [PTR_W-1:0]    snap_value [SNAPSHOT_NUM];

  SnapshotGenerator snapshots_snapshotGen (
    .clock                (clock),
    .reset                (reset),
    .io_enq               (io_snpt_snptEnq),
    .io_enqData_flag      (headPtr.flag),
    .io_enqData_value     (headPtr.value),
    .io_deq               (io_snpt_snptDeq),
    .io_redirect          (io_redirect),
    .io_flushVec_0        (io_snpt_flushVec[0]),
    .io_flushVec_1        (io_snpt_flushVec[1]),
    .io_flushVec_2        (io_snpt_flushVec[2]),
    .io_flushVec_3        (io_snpt_flushVec[3]),
    .io_snapshots_0_flag  (snap_flag[0]),
    .io_snapshots_0_value (snap_value[0]),
    .io_snapshots_1_flag  (snap_flag[1]),
    .io_snapshots_1_value (snap_value[1]),
    .io_snapshots_2_flag  (snap_flag[2]),
    .io_snapshots_2_value (snap_value[2]),
    .io_snapshots_3_flag  (snap_flag[3]),
    .io_snapshots_3_value (snap_value[3])
  );

  // 选中的快照(用两拍前打拍的 snptSelect)
  fl_ptr_t selSnap;
  always_comb begin
    selSnap.flag  = snap_flag [lastCycleSnpt_snptSelect];
    selSnap.value = snap_value[lastCycleSnpt_snptSelect];
  end

  wire [PTR_W:0] numWalk = popcnt_all_c(io_walkReq);
  wire fl_ptr_t redirectBase   = lastCycleSnpt_useSnpt ? selSnap : archHeadPtr;
  wire fl_ptr_t redirectedHead = ptr_add(redirectBase, numWalk);

  // =====================================================================
  // 6. 投机态 head 更新 + 空闲计数
  //    分配个数：walk 时用 walkReq，否则用 allocateReq。
  // =====================================================================
  wire isWalkAlloc   = io_walk && io_doAllocate;
  wire isNormalAlloc = io_canAllocate && io_doAllocate;
  wire isAllocate    = isWalkAlloc || isNormalAlloc;

  wire [PTR_W:0] numAllocate = io_walk ? popcnt_all_c(io_walkReq)
                                       : popcnt_all_r(io_allocateReq);

  // 正常前移：head + numAllocate；其 OH 取 headPtrOHVec[numAllocate]
  wire fl_ptr_t headPtrFwd = ptr_add(headPtr, numAllocate);

  wire fl_ptr_t headPtrAllocate =
      lastCycleRedirect ? redirectedHead : headPtrFwd;

  // headPtrOH 的下一值：回退时用 redirectedHead 的 OH，否则用移位向量。
  // 用移位生成 one-hot(而非变量下标赋值)：下标越界时 1 被移出、不产生 X。
  logic [SIZE-1:0] redirectedHeadOH;
  always_comb redirectedHeadOH = (SIZE'(1) << redirectedHead.value);
  wire [SIZE-1:0] headPtrOHAllocate =
      lastCycleRedirect ? redirectedHeadOH : headPtrOHVec[CAND_IW'(numAllocate)];

  // 空闲寄存器数(组合)：tail 与 head 的距离，减去本拍要分配的数
  logic [CNT_W-1:0] freeRegCnt;
  always_comb begin
    if (isWalkAlloc && !lastCycleRedirect)
      freeRegCnt = distance(tailPtr, headPtr) - popcnt_all_c(io_walkReq);
    else if (isNormalAlloc)
      freeRegCnt = distance(tailPtr, headPtr) - popcnt_all_r(io_allocateReq);
    else
      freeRegCnt = distance(tailPtr, headPtr);
  end

  // canAllocate 打一拍：空闲数严格大于 RenameWidth 才允许分配
  // (异步复位，与 golden 同处主复位域，复位置 0)
  always_ff @(posedge clock or posedge reset) begin
    if (reset) io_canAllocate <= 1'b0;
    else       io_canAllocate <= (freeRegCnt >= RENAME_WIDTH);
  end

  // 优先级：异常/flush(redirect) > walk回退 > 误预测 > 正常出队
  // 只有非 redirect 且确实分配时才推进 head/headPtrOH。
  wire realDoAllocate = !io_redirect && isAllocate;

  // =====================================================================
  // 7. 寄存器更新
  // =====================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      headPtr      <= '{flag:1'b0, value:'0};
      headPtrOH    <= {{(SIZE-1){1'b0}}, 1'b1};
      archHeadPtr  <= '{flag:1'b0, value:'0};
      lastTailPtr  <= '{flag:1'b1, value:'0};   // tail 初值在"满圈"位置
      // 仅 snpt 第一级带复位初值 0(对应 Scala RegNext(io.snpt, 0))；
      // redirect 两级与 snpt 第二级无复位(RegNext 无初值)，见下方独立 always_ff。
      lastCycleSnpt_REG_useSnpt    <= 1'b0;
      lastCycleSnpt_REG_snptSelect <= '0;
      for (int i = 0; i < SIZE; i++)
        freeList[i] <= PHYREG_W'(i + NUM_LOGIC_REGS);
    end else begin
      if (realDoAllocate) begin
        headPtr   <= headPtrAllocate;
        headPtrOH <= headPtrOHAllocate;
      end
      archHeadPtr <= archHeadPtrNext;

      // 回收写回：对每个条目 E 做地址译码——若某口要写且其写入下标==E 则写入。
      // 多口命中同一 E 时高编号口优先(与 golden 一致；正常流控下不会冲突)。
      for (int e = 0; e < SIZE; e++)
        for (int i = 0; i < COMMIT_WIDTH; i++)
          if (io_freeReq[i] && freeEnqIdx[i] == PTR_W'(e))
            freeList[e] <= io_freePhyReg[i];
      lastTailPtr <= tailPtr;

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
  // 8. 性能事件(空闲度四分位)，打一拍以匹配 golden
  // =====================================================================
  logic [CNT_W-1:0] freeRegCntReg;
  always_ff @(posedge clock) freeRegCntReg <= freeRegCnt;

  // golden 对四分位事件做两级打拍(REG → REG_1)
  logic [3:0] perf_s1, perf_s2;
  always_ff @(posedge clock) begin
    perf_s1[0] <= (freeRegCntReg <  (SIZE/4));
    perf_s1[1] <= (freeRegCntReg >= (SIZE/4)   && freeRegCntReg < (SIZE/2));
    perf_s1[2] <= (freeRegCntReg >= (SIZE/2)   && freeRegCntReg < (SIZE*3/4));
    perf_s1[3] <= (freeRegCntReg >= (SIZE*3/4));
    perf_s2    <= perf_s1;
  end
  always_comb for (int i=0;i<4;i++) io_perf_value[i] = {5'h0, perf_s2[i]};

endmodule
