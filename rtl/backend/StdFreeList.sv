// =====================================================================
// stdfreelist_pkg —— 重命名「标准空闲列表」(StdFreeList 家族) 的家族常量
// ---------------------------------------------------------------------
// StdFreeList 管理一类物理寄存器(浮点/向量/v0/vl)的空闲池。它本质是一个
// 「循环队列」：
//   - headPtr 指向下一个可【分配】的空闲物理寄存器(出队端)；
//   - tailPtr 指向下一个【回收】物理寄存器的写入位置(入队端)；
//   - freeList[] 数组存放当前空闲的物理寄存器号。
// 与普通队列不同处在于它要支持「投机执行 + 回滚(walk/redirect)」：
//   - archHeadPtr 是【体系结构态】的 head，仅在 commit 时推进，
//     代表"真正用掉、不会再回退"的分配进度；
//   - 当分支预测错误(redirect)发生时，head 需要回退到某个快照(snapshot)
//     或回退到 archHeadPtr，再按 walk 重新分配。
//
// ★家族★ golden 里 Rename 例化了 4 个同构变体(Scala: 同一个 class StdFreeList
// 用不同参数例化)，控制逻辑逐字相同，只有池容量 / 初值基数 / commit 侧
// 看的 Wen 字段不同(端口名也随之不同)：
//   golden 顶层        Scala 例化(Rename.scala)                     SIZE  NUM_LOGIC  commit Wen  SnapshotGenerator 变体
//   StdFreeList      StdFreeList(FpPhyRegs-FpLogicRegs, FpLogicRegs, Reg_F)      158  34   fpWen   SnapshotGenerator    (value 8 位)
//   StdFreeList_1    StdFreeList(VfPhyRegs-VecLogicRegs, VecLogicRegs, Reg_V)    81   47   vecWen  SnapshotGenerator_11 (value 7 位)
//   StdFreeList_2    StdFreeList(V0PhyRegs-V0LogicRegs, V0LogicRegs, Reg_V0)     21   1    v0Wen   SnapshotGenerator_12 (value 5 位)
//   StdFreeList_3    StdFreeList(VlPhyRegs-VlLogicRegs, VlLogicRegs, Reg_Vl)     31   1    vlWen   SnapshotGenerator_12 (value 5 位)
// 数字逐个量自 G1 golden：SIZE = 回绕常量(`_tailPtr_diff_T_4 = ... - N'hSIZE`)，
// NUM_LOGIC = 复位臂里 `freeList_0 <= 8'hNUM_LOGIC`，指针宽 = `reg [W-1:0] archHeadPtr_value`。
// 核 xs_StdFreeList_core 以 SIZE / NUM_LOGIC_REGS 为参数；本文件末尾的 golden
// 同名 wrapper 是浮点变体，另外三个变体各自一个薄文件(rtl/backend/StdFreeList_{1,2,3}.sv，
// 由 verif/ut/StdFreeListVariants/gen_variants.py 从 golden 端口表生成)。
//
// 家族内不变的量放在本包；随变体变的量(SIZE / NUM_LOGIC_REGS 及由它们导出的
// 指针宽)是核参数——所以循环指针类型与指针算术定义在核里，而不是包里
// (SystemVerilog 的 package 不能参数化)。
// =====================================================================
package stdfreelist_pkg;

  localparam int PHYREG_W      = 8;    // 物理寄存器号位宽 PhyRegIdxWidth(四个变体都是 8)
  localparam int RENAME_WIDTH  = 6;    // 每拍重命名(分配)口数
  localparam int COMMIT_WIDTH  = 6;    // 每拍提交/回滚(回收)口数 RabCommitWidth
  localparam int SNAPSHOT_NUM  = 4;    // 快照个数 RenameSnapshotNum

  // ---- 四个变体的参数表(薄 wrapper 用；见文件头表格) ----
  localparam int FP_SIZE  = 158, FP_NUM_LOGIC  = 34;   // StdFreeList
  localparam int VEC_SIZE = 81,  VEC_NUM_LOGIC = 47;   // StdFreeList_1
  localparam int V0_SIZE  = 21,  V0_NUM_LOGIC  = 1;    // StdFreeList_2
  localparam int VL_SIZE  = 31,  VL_NUM_LOGIC  = 1;    // StdFreeList_3

endpackage

// =====================================================================
// xs_StdFreeList_core —— 重命名「标准空闲列表」可读重写(家族共用参数化核)
// ---------------------------------------------------------------------
// 功能定位(后端 Rename 级)：
//   为一类物理寄存器(浮点 Reg_F / 向量 Reg_V / v0 / vl)维护空闲池。
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
//     freeList，省去对 SIZE 路做译码比较，改善时序。
//   * canAllocate 打一拍：只有空闲数 >= RenameWidth 时才允许分配，从而
//     保证"本拍回收的寄存器下一拍才可能被分配"，free 路径可安全打拍。
//
// 参数：
//   SIZE            空闲池容量(循环队列条目数，非 2 的幂)
//   NUM_LOGIC_REGS  逻辑寄存器数：freeList 初值 = i + NUM_LOGIC_REGS
//                   (物理寄存器 0..NUM_LOGIC_REGS-1 复位时映射给逻辑寄存器，其余空闲)
//
// 子模块：快照存储用家族共核 xs_SnapshotGenerator_core(rtl/backend/SnapshotGenerator.sv)，
//   payload 宽 = 指针宽 PTR_W+1；golden 各变体对应 SnapshotGenerator / _11 / _12。
// =====================================================================

module xs_StdFreeList_core
  import stdfreelist_pkg::*;
#(
  parameter int SIZE           = FP_SIZE,
  parameter int NUM_LOGIC_REGS = FP_NUM_LOGIC
) (
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
  // (regWen 在各变体 wrapper 里分别接 fpWen / vecWen / v0Wen / vlWen)
  input  logic                          io_commit_isCommit,
  input  logic [COMMIT_WIDTH-1:0]       io_commit_commitValid,
  input  logic [COMMIT_WIDTH-1:0]       io_commit_info_regWen,

  // 快照端口(转发给快照存储核)
  input  logic                          io_snpt_snptEnq,
  input  logic                          io_snpt_snptDeq,
  input  logic                          io_snpt_useSnpt,
  input  logic [$clog2(SNAPSHOT_NUM)-1:0] io_snpt_snptSelect,
  input  logic [SNAPSHOT_NUM-1:0]       io_snpt_flushVec,

  output logic [5:0]                    io_perf_value [4]
);

  // -------------------- 由参数导出的宽度 --------------------
  localparam int PTR_W = $clog2(SIZE);      // 指针 value 位宽(158→8, 81→7, 21/31→5)
  localparam int CNT_W = $clog2(SIZE + 1);  // 空闲计数位宽

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
  // 4. 体系结构态 head：commit 拍按"提交且写该类寄存器"的指令数推进
  // =====================================================================
  logic [COMMIT_WIDTH-1:0] archAlloc;
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++)
      archAlloc[i] = io_commit_commitValid[i] & io_commit_info_regWen[i];

  wire fl_ptr_t archHeadPtrNew  = ptr_add(archHeadPtr, popcnt_all_c(archAlloc));
  wire fl_ptr_t archHeadPtrNext = io_commit_isCommit ? archHeadPtrNew : archHeadPtr;

  // =====================================================================
  // 5. 重定向回退目标：snapshot 或 archHeadPtr，再加上已 walk 的请求数
  // =====================================================================
  // 快照存储(家族共核)：存 headPtr 的快照，供 redirect 回退选择。
  // payload 就是 fl_ptr_t 打平({flag, value}，flag 在高位)。
  localparam int SNAP_W = $bits(fl_ptr_t);          // = PTR_W + 1
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
    .enq_ptr   (),   // golden 各变体都没导出这三组端口(见 SnapshotGenerator.sv 文件头)
    .deq_ptr   (),
    .valids    ()
  );

  // 选中的快照(用两拍前打拍的 snptSelect)
  wire fl_ptr_t selSnap = snapshots[lastCycleSnpt_snptSelect];

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
      freeRegCnt = distance(tailPtr, headPtr) - CNT_W'(popcnt_all_c(io_walkReq));
    else if (isNormalAlloc)
      freeRegCnt = distance(tailPtr, headPtr) - CNT_W'(popcnt_all_r(io_allocateReq));
    else
      freeRegCnt = distance(tailPtr, headPtr);
  end

  // canAllocate 打一拍：空闲数 >= RenameWidth 才允许分配
  // (异步复位，与 golden 同处主复位域，复位置 0)
  always_ff @(posedge clock or posedge reset) begin
    if (reset) io_canAllocate <= 1'b0;
    else       io_canAllocate <= (freeRegCnt >= CNT_W'(RENAME_WIDTH));
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
  //    四分位边界 = SIZE/4, SIZE/2, SIZE*3/4(整数除法，与 Scala 的 Int 除法一致)
  // =====================================================================
  logic [CNT_W-1:0] freeRegCntReg;
  always_ff @(posedge clock) freeRegCntReg <= freeRegCnt;

  // golden 对四分位事件做两级打拍(REG → REG_1)
  logic [3:0] perf_s1, perf_s2;
  always_ff @(posedge clock) begin
    perf_s1[0] <= (freeRegCntReg <  CNT_W'(SIZE/4));
    perf_s1[1] <= (freeRegCntReg >= CNT_W'(SIZE/4)   && freeRegCntReg < CNT_W'(SIZE/2));
    perf_s1[2] <= (freeRegCntReg >= CNT_W'(SIZE/2)   && freeRegCntReg < CNT_W'(SIZE*3/4));
    perf_s1[3] <= (freeRegCntReg >= CNT_W'(SIZE*3/4));
    perf_s2    <= perf_s1;
  end
  always_comb for (int i=0;i<4;i++) io_perf_value[i] = {5'h0, perf_s2[i]};

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper —— 浮点变体 StdFreeList(SIZE=158, NUM_LOGIC_REGS=34, commit 看 fpWen)
// golden 同名扁平端口 → 可读核 xs_StdFreeList_core 的机械适配层。
// 另外三个变体(StdFreeList_1/_2/_3)与本 wrapper 只差参数与 Wen 端口名，各自一个薄文件，
// 由 verif/ut/StdFreeListVariants/gen_variants.py 生成；本 wrapper 手工维护。
// ---------------------------------------------------------------------------

module StdFreeList(
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
  input        io_commit_info_0_fpWen,
  input        io_commit_info_1_fpWen,
  input        io_commit_info_2_fpWen,
  input        io_commit_info_3_fpWen,
  input        io_commit_info_4_fpWen,
  input        io_commit_info_5_fpWen,
  input        io_snpt_snptEnq,
  input        io_snpt_snptDeq,
  input        io_snpt_useSnpt,
  input  [1:0] io_snpt_snptSelect,
  input        io_snpt_flushVec_0,
  input        io_snpt_flushVec_1,
  input        io_snpt_flushVec_2,
  input        io_snpt_flushVec_3,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value
);
  import stdfreelist_pkg::*;

  logic [5:0] io_allocateReq;
  logic [5:0] io_walkReq;
  logic [7:0] allocatePhyReg [6];
  logic [5:0] io_freeReq;
  logic [7:0] freePhyReg [6];
  logic [5:0] io_commit_commitValid;
  logic [5:0] io_commit_info_regWen;
  logic [3:0] io_snpt_flushVec;
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
  assign io_commit_info_regWen = {io_commit_info_5_fpWen, io_commit_info_4_fpWen,
                                  io_commit_info_3_fpWen, io_commit_info_2_fpWen,
                                  io_commit_info_1_fpWen, io_commit_info_0_fpWen};
  assign io_snpt_flushVec = {io_snpt_flushVec_3, io_snpt_flushVec_2,
                             io_snpt_flushVec_1, io_snpt_flushVec_0};

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

  xs_StdFreeList_core #(.SIZE(FP_SIZE), .NUM_LOGIC_REGS(FP_NUM_LOGIC)) u_core (
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
    .io_commit_info_regWen(io_commit_info_regWen),
    .io_snpt_snptEnq(io_snpt_snptEnq),
    .io_snpt_snptDeq(io_snpt_snptDeq),
    .io_snpt_useSnpt(io_snpt_useSnpt),
    .io_snpt_snptSelect(io_snpt_snptSelect),
    .io_snpt_flushVec(io_snpt_flushVec),
    .io_perf_value(perf_value)
  );
endmodule
