// =============================================================================
// FreeList —— 访存队列「空闲槽位表」（参数化核 + 基础变体 wrapper）
//
// 对应 Chisel: xiangshan.mem.FreeList(size, allocWidth, freeWidth, enablePreAlloc)
// （src/main/scala/xiangshan/mem/lsqueue/FreeList.scala）。
//
// 用途：给 Load/Store 队列（LoadQueueRAW / LoadQueueReplay 等）分配**条目槽位号**
// （不是物理寄存器，那是 backend 的 StdFreeList）。入队的访存指令向本表申请一个
// 空闲槽位号作为它在队列里的索引；条目完成/被冲刷时把槽位号释放回池。
//
// 结构 —— 一个循环队列，队列里存的是"当前空闲的槽位号"：
//   freeList[SIZE]  空闲槽位号池
//   headPtr         出队端（分配）   tailPtr 入队端（释放）
//   freeMask        尚未回收进 freeList 的释放请求位图
// 指针是 {flag, value} 的 CircularQueuePtr：flag 用来区分"绕了奇数圈还是偶数圈"，
// 因此 head==tail 且 flag 相同 = 空，flag 不同 = 满。
//
// 释放侧为什么要 bank + 打拍：释放接口是 SIZE 位的位图（任意多个条目可能同拍释放），
// 而 freeList 每拍只有 FREE_WIDTH 个写口。于是把位图按"下标 % FREE_WIDTH"分成
// FREE_WIDTH 个 bank，每 bank 用优先编码挑一个，打一拍后写回 freeList[tailPtr+offset]，
// 并把已选中的位从 freeMask 扣掉。这样多拍分批把释放请求吸收掉。
//
// ★ 同拍多 bank 写同一个 freeList 地址时的优先级：**bank 号大的赢**。
//   来源是 Chisel 的 last-connect（for 循环里后写的 i 覆盖先写的），golden 展开成
//   `if (freeReq_3 & idx==e) ... else if (freeReq_2 ...) ...`，即 3>2>1>0。
//   Chisel 源码里没有任何注释说明这一点，判据取自 golden。
//   —— 但这条优先级**按构造不可达**：bank b 的写地址是
//      (tailPtr + 「b 以下有几个 bank 也在回收」) mod SIZE，活跃 bank 的偏移量
//      互不相同且总和 < FREE_WIDTH ≤ SIZE，所以两个活跃 bank 永远不会撞同一个
//      地址。实测也印证：把优先级整个反过来做成变异体，UT 3 万拍 errors 仍为 0。
//      这里仍按 golden 的顺序写，是为了结构对齐（不合并、不改写死逻辑），
//      不是因为它有功能意义。
//
// ★ 分配侧两种形态（Chisel 的 enablePreAlloc）：
//   ENABLE_PRE_ALLOC=0：allocateSlot/canAllocate 组合给出，读指针 = headPtr + i。
//   ENABLE_PRE_ALLOC=1：两者**打一拍**给出（RegEnable(x, true.B) ⇒ 无使能、
//                       **无复位**的寄存器），且读指针 = headPtrNext + i
//                       （headPtrNext = headPtr + 本拍分配个数），即提前一拍把
//                       下一批槽位准备好。这 2×ALLOC_WIDTH 个寄存器不复位。
//
// ★ 冗余结构照抄：ENABLE_PRE_ALLOC 下 golden 对每个分配口都**重新算一遍**
//   headPtr+numAllocate（而不是算一次共用），并在其上再套一次回绕修正
//   （第二次修正恒不触发）。这里用 ptr_add(ptr_add(...)) 如实保留。
//
// 本文件 = 参数化可读核 xs_FreeList_core + golden 同名基础 wrapper FreeList
// （SIZE=16 / 2 分配口 / 2 释放 bank / 无 preAlloc，给 LoadQueueRAW 用）。
// 家族其余单态化变体各自一个薄 wrapper 文件：
//   FreeList_5 : 72 项, 3 分配口, 4 释放 bank, preAlloc（LoadQueueReplay）
// （golden 还有 FreeList_1/_3/_4/_6 尚未重写，届时同样只加薄文件。）
// =============================================================================

// -----------------------------------------------------------------------------
// xs_FreeList_core —— 参数化可读核
// -----------------------------------------------------------------------------
module xs_FreeList_core #(
  parameter int SIZE             = 16,     // 槽位数（须被 FREE_WIDTH 整除）
  parameter int ALLOC_WIDTH      = 2,      // 每拍分配口数
  parameter int FREE_WIDTH       = 2,      // 每拍最多回收槽位数 = 释放 bank 数
  parameter bit ENABLE_PRE_ALLOC = 1'b0    // 分配输出是否提前一拍打拍给出
) (
  input  logic                   clock,
  input  logic                   reset,

  // 分配口
  output logic [$clog2(SIZE)-1:0] io_allocateSlot [ALLOC_WIDTH],
  output logic [ALLOC_WIDTH-1:0]  io_canAllocate,  // 该口是否真有空闲槽位可取
  input  logic [ALLOC_WIDTH-1:0]  io_doAllocate,   // 该口本拍确实取走一个

  // 释放位图：每位代表对应槽位本拍被释放回池
  input  logic [SIZE-1:0]         io_free,

  output logic [$clog2(SIZE+1)-1:0] io_validCount, // 已占用条目数 = SIZE - 空闲数
  output logic                      io_empty       // 空闲池是否为空
);

  // ---------------------------------------------------------------------------
  // 派生参数
  // ---------------------------------------------------------------------------
  localparam int  IDX_W    = $clog2(SIZE);       // 槽位号/指针 value 位宽
  localparam int  CNT_W    = $clog2(SIZE + 1);   // 空闲计数位宽
  localparam int  PER_BANK = SIZE / FREE_WIDTH;  // 每个释放 bank 覆盖的槽位数
  localparam bit  IS_POW2  = ((SIZE & (SIZE - 1)) == 0);
  localparam int  PC_W     = (ALLOC_WIDTH > FREE_WIDTH) ? ALLOC_WIDTH : FREE_WIDTH;

  // 循环队列指针。SIZE 为 2 的幂时 {flag,value} 拼起来自然回绕；否则要显式减 SIZE。
  typedef struct packed {
    logic             flag;
    logic [IDX_W-1:0] value;
  } fl_ptr_t;

  // ---------------------------------------------------------------------------
  // 指针 + 偏移（CircularQueuePtr.+）
  // ---------------------------------------------------------------------------
  // 两条分支与 utility.CircularQueuePtr 的 isPow2 分支一一对应：
  //   pow2   ：{flag,value} 当作 (IDX_W+1) 位无符号数直接加，溢出即翻 flag。
  //   非 pow2：new = value + v（扩位不截断）；diff = new - SIZE 按有符号判；
  //            diff >= 0 说明绕过一圈 → flag 翻转、value 取 diff，否则保持。
  function automatic fl_ptr_t ptr_add(input fl_ptr_t p, input logic [IDX_W:0] v);
    fl_ptr_t                 r;
    logic [IDX_W:0]          sum;      // 与 golden 同宽：IDX_W+1 位
    logic signed [IDX_W+1:0] diff;     // 与 golden 同宽：IDX_W+2 位有符号
    begin
      if (IS_POW2) begin
        sum     = {p.flag, p.value} + v;
        r.flag  = sum[IDX_W];
        r.value = sum[IDX_W-1:0];
      end else begin
        sum  = {1'b0, p.value} + v;
        diff = $signed({1'b0, sum}) - $signed((IDX_W+2)'(SIZE));
        if (diff >= 0) begin
          r.flag  = ~p.flag;
          r.value = diff[IDX_W-1:0];
        end else begin
          r.flag  = p.flag;
          r.value = sum[IDX_W-1:0];
        end
      end
      return r;
    end
  endfunction

  // 循环队列指针比较 isBefore(a, b)：flag 相同看 value 大小，flag 不同取反。
  function automatic logic ptr_before(input fl_ptr_t a, input fl_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value < b.value);
  endfunction

  // ---------------------------------------------------------------------------
  // 位图小工具
  // ---------------------------------------------------------------------------
  // 取 in 中"下标 % FREE_WIDTH == rem"的那些位，压成 PER_BANK 位向量
  function automatic logic [PER_BANK-1:0] get_rem_bits
      (input logic [SIZE-1:0] in, input int rem);
    logic [PER_BANK-1:0] y;
    begin
      y = '0;
      for (int i = 0; i < PER_BANK; i++) y[i] = in[FREE_WIDTH*i + rem];
      return y;
    end
  endfunction

  // PriorityEncoderOH：返回最低置位的 one-hot（全 0 输入返回全 0）
  function automatic logic [PER_BANK-1:0] prio_oh(input logic [PER_BANK-1:0] x);
    logic [PER_BANK-1:0] y;
    logic                found;
    begin
      y = '0; found = 1'b0;
      for (int i = 0; i < PER_BANK; i++)
        if (!found && x[i]) begin y[i] = 1'b1; found = 1'b1; end
      return y;
    end
  endfunction

  // OHToUInt：one-hot → 槽位号
  function automatic logic [IDX_W-1:0] oh_to_idx(input logic [SIZE-1:0] oh);
    logic [IDX_W-1:0] r;
    begin
      r = '0;
      for (int i = 0; i < SIZE; i++) if (oh[i]) r |= IDX_W'(i);
      return r;
    end
  endfunction

  // 数 v 的低 n 位里有几个 1（PopCount(x.take(n))）
  function automatic logic [IDX_W:0] popcnt(input logic [PC_W-1:0] v, input int n);
    logic [IDX_W:0] s;
    begin s = '0; for (int k = 0; k < n; k++) if (v[k]) s += 1'b1; return s; end
  endfunction

  // ===========================================================================
  // 1. 存储 + 指针 + 释放打拍寄存器
  // ===========================================================================
  logic [IDX_W-1:0] freeList [SIZE];
  fl_ptr_t          headPtr;      // 分配出队端
  fl_ptr_t          tailPtr;      // 释放入队端
  logic [SIZE-1:0]  freeMask;     // 待回收位图（尚未写回 freeList 的释放请求）
  logic [CNT_W-1:0] freeSlotCnt;  // 池内空闲槽位数

  // 上一拍选出的待回收（GatedRegNext 打拍）
  logic [FREE_WIDTH-1:0] freeReqReg;
  logic [SIZE-1:0]       freeSlotOHReg [FREE_WIDTH];

  // ===========================================================================
  // 2. 释放路径：bank 优先编码，从 freeMask 里选本拍要回收的槽位
  // ===========================================================================
  // 已被选中（打拍后）的位要从 freeMask 扣掉，避免重复回收
  logic [SIZE-1:0] freeSelMask;
  always_comb begin
    freeSelMask = '0;
    for (int b = 0; b < FREE_WIDTH; b++)
      if (freeReqReg[b]) freeSelMask |= freeSlotOHReg[b];
  end

  logic [PER_BANK-1:0]   remFreeSelMask    [FREE_WIDTH];
  logic [SIZE-1:0]       remFreeSelIndexOH [FREE_WIDTH];
  logic [FREE_WIDTH-1:0] freeReqNext;
  always_comb begin
    for (int b = 0; b < FREE_WIDTH; b++) begin
      logic [PER_BANK-1:0] hi;
      remFreeSelMask[b] = get_rem_bits(freeMask & ~freeSelMask, b);
      hi                = prio_oh(remFreeSelMask[b]);
      // bank 内 one-hot 散回 SIZE 位（位置 = i*FREE_WIDTH + b）
      remFreeSelIndexOH[b] = '0;
      for (int i = 0; i < PER_BANK; i++)
        remFreeSelIndexOH[b][i*FREE_WIDTH + b] = hi[i];
      freeReqNext[b] = |remFreeSelMask[b];
    end
  end

  // 释放写回地址：bank b 写 freeList[tailPtr + (b 之前有几个 bank 也在回收)]
  // 注意：FM 的 read_sverilog 不支持对函数返回值直接做域选（f(x).value），
  // 所以先落到局部变量再取字段。
  logic [IDX_W-1:0] freeEnqIdx [FREE_WIDTH];
  always_comb begin
    fl_ptr_t enqPtr;
    for (int b = 0; b < FREE_WIDTH; b++) begin
      enqPtr        = ptr_add(tailPtr, popcnt(PC_W'(freeReqReg), b));
      freeEnqIdx[b] = enqPtr.value;
    end
  end

  wire doFree = |freeReqReg;

  // ===========================================================================
  // 3. 分配路径
  // ===========================================================================
  wire            doAllocate   = |io_doAllocate;
  wire [IDX_W:0]  numAllocate  = popcnt(PC_W'(io_doAllocate), ALLOC_WIDTH);
  wire fl_ptr_t   headPtrNext  = ptr_add(headPtr, numAllocate);
  wire fl_ptr_t   tailPtrNext  = ptr_add(tailPtr, popcnt(PC_W'(freeReqReg), FREE_WIDTH));

  // 分配口 i 的读指针。
  //   preAlloc：从 headPtrNext 起算（提前一拍），且 golden 对每个口各算一次
  //             headPtr+numAllocate，外面再套一次回绕修正——如实保留这层嵌套。
  //   非 preAlloc：从当前 headPtr 起算。
  fl_ptr_t deqPtr [ALLOC_WIDTH];
  always_comb
    for (int i = 0; i < ALLOC_WIDTH; i++)
      deqPtr[i] = ENABLE_PRE_ALLOC ? ptr_add(ptr_add(headPtr, numAllocate), IDX_W'(i))
                                   : ptr_add(headPtr, IDX_W'(i));

  // ★ 越界读语义：指针 value 是 IDX_W 位，SIZE 不是 2 的幂时取值范围大于 SIZE。
  //   golden 把 freeList 读展开成 2^IDX_W 项查找表，SIZE..2^IDX_W-1 这些项
  //   **全部填 freeList[0]**（firtool 对 Vec 越界读的填充语义），不是 0。
  //   构造上 deqPtr.value < SIZE，但随机初值下会走到这条路径，必须照抄。
  //
  //   写法上这里**不用变量下标**，而是"默认取第 0 项 + 逐项常量比较覆盖"——
  //   它就是 golden 那张查找表的字面形状。用 freeList[deqPtr[i].value] 写会让
  //   Formality 报 FMR_ELAB-147（Index may take values outside array bound）：
  //   FM 不把外面那个 `< SIZE` 守卫传播进下标，于是 set_top 直接失败。
  //   判据是"改 RTL 让下标可证在界内"，不是拿 set_mismatch_message_filter 压消息。
  logic [IDX_W-1:0] deqSlot   [ALLOC_WIDTH];
  logic [ALLOC_WIDTH-1:0] deqCanAlloc;
  always_comb
    for (int i = 0; i < ALLOC_WIDTH; i++) begin
      deqSlot[i] = freeList[0];                       // 越界（含 SIZE..2^IDX_W-1）的填充项
      for (int e = 1; e < SIZE; e++)
        if (deqPtr[i].value == IDX_W'(e)) deqSlot[i] = freeList[e];
      deqCanAlloc[i] = ptr_before(deqPtr[i], tailPtr);
    end

  // ===========================================================================
  // 4. 分配输出：preAlloc 打一拍（无使能、无复位的寄存器），否则直通
  // ===========================================================================
  if (ENABLE_PRE_ALLOC) begin : g_pre_alloc_out
    // ★ 这 2×ALLOC_WIDTH 个寄存器在 golden 里不在 reset 分支内（RegEnable(x, true.B)
    //   展开成 always @(posedge clock) 无条件赋值），照抄成不复位。
    logic [IDX_W-1:0]       allocateSlotReg [ALLOC_WIDTH];
    logic [ALLOC_WIDTH-1:0] canAllocateReg;
    always_ff @(posedge clock)
      for (int i = 0; i < ALLOC_WIDTH; i++) begin
        allocateSlotReg[i] <= deqSlot[i];
        canAllocateReg[i]  <= deqCanAlloc[i];
      end
    for (genvar i = 0; i < ALLOC_WIDTH; i++)
      assign io_allocateSlot[i] = allocateSlotReg[i];
    assign io_canAllocate = canAllocateReg;
  end else begin : g_comb_out
    for (genvar i = 0; i < ALLOC_WIDTH; i++)
      assign io_allocateSlot[i] = deqSlot[i];
    assign io_canAllocate = deqCanAlloc;
  end

  // ===========================================================================
  // 5. 空闲计数下一值 = distanceBetween(tailPtrNext, headPtrNext)
  // ===========================================================================
  logic [CNT_W-1:0] freeSlotCntNext;
  always_comb begin
    if (tailPtrNext.flag == headPtrNext.flag)
      // flag 相同：在 IDX_W 位内相减（借位自然回绕），再零扩展到 CNT_W。
      // SIZE 为 2 的幂时 CNT_W = IDX_W+1，这一步就是 golden 的 {1'h0, 4'(...)};
      // SIZE 非 2 的幂时 CNT_W = IDX_W，退化成直接相减。
      freeSlotCntNext = CNT_W'(IDX_W'(tailPtrNext.value - headPtrNext.value));
    else
      // flag 不同：SIZE + tail.value - head.value（CNT_W 位内运算）
      freeSlotCntNext = CNT_W'(CNT_W'({1'b0, tailPtrNext.value}) + CNT_W'(SIZE)
                               - CNT_W'({1'b0, headPtrNext.value}));
  end

  // ===========================================================================
  // 6. 时序更新（异步复位，与 golden 一致）
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      // 上电时槽位 0..SIZE-1 全空闲，按顺序排在池里；tailPtr.flag=1 表示"满"。
      for (int i = 0; i < SIZE; i++) freeList[i] <= IDX_W'(i);
      headPtr     <= '{flag: 1'b0, value: '0};
      tailPtr     <= '{flag: 1'b1, value: '0};
      freeMask    <= '0;
      freeReqReg  <= '0;
      for (int b = 0; b < FREE_WIDTH; b++) freeSlotOHReg[b] <= '0;
      freeSlotCnt <= CNT_W'(SIZE);
    end else begin
      // 释放写回：对每个条目译码，命中则写其槽位号。
      // 这里是过程赋值，循环中**后写的 bank 覆盖先写的**，即高 bank 优先 —— 与
      // golden 的 `if (bank3) ... else if (bank2) ...` 优先级一致（见文件头）。
      for (int e = 0; e < SIZE; e++)
        for (int b = 0; b < FREE_WIDTH; b++)
          if (freeReqReg[b] && freeEnqIdx[b] == IDX_W'(e))
            freeList[e] <= oh_to_idx(freeSlotOHReg[b]);

      if (doAllocate) headPtr <= headPtrNext;
      if (doFree)     tailPtr <= tailPtrNext;

      // freeMask 累加本拍新释放、扣除已选中的
      freeMask <= (io_free | freeMask) & ~freeSelMask;

      // GatedRegNext：golden 展开成"值变了才写"（时钟门控的行为模型），照抄
      for (int b = 0; b < FREE_WIDTH; b++) begin
        if (freeReqNext[b] != freeReqReg[b])
          freeReqReg[b] <= freeReqNext[b];
        if (remFreeSelIndexOH[b] != freeSlotOHReg[b])
          freeSlotOHReg[b] <= remFreeSelIndexOH[b];
      end

      freeSlotCnt <= freeSlotCntNext;
    end
  end

  // ===========================================================================
  // 7. 输出
  // ===========================================================================
  assign io_validCount = CNT_W'(SIZE) - freeSlotCnt;
  assign io_empty      = (freeSlotCnt == '0);

endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper —— 基础变体：16 项 / 2 分配口 / 2 释放 bank / 无 preAlloc
// golden 未导出 canAllocate（该实例不用，被 firtool 裁掉），故核的该输出悬空。
// -----------------------------------------------------------------------------
module FreeList(
  input         clock,
  input         reset,
  output [3:0]  io_allocateSlot_0,
  output [3:0]  io_allocateSlot_1,
  input         io_doAllocate_0,
  input         io_doAllocate_1,
  input  [15:0] io_free,
  output [4:0]  io_validCount,
  output        io_empty
);
  logic [3:0] allocateSlot [2];
  logic [1:0] canAllocate;

  assign io_allocateSlot_0 = allocateSlot[0];
  assign io_allocateSlot_1 = allocateSlot[1];

  xs_FreeList_core #(
    .SIZE(16), .ALLOC_WIDTH(2), .FREE_WIDTH(2), .ENABLE_PRE_ALLOC(1'b0)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .io_allocateSlot (allocateSlot),
    .io_canAllocate  (canAllocate),
    .io_doAllocate   ({io_doAllocate_1, io_doAllocate_0}),
    .io_free         (io_free),
    .io_validCount   (io_validCount),
    .io_empty        (io_empty)
  );
endmodule
