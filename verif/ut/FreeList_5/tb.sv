// FreeList_5 UT —— golden 与重写件双例化逐拍比对（72 项 / 3 分配口 / 4 释放 bank / preAlloc）
//
// 为什么不能只用均匀随机：本模块出错的地方集中在
//   (a) 队列满/空边界（指针 flag 翻转、freeSlotCnt 的 distanceBetween 两条分支）；
//   (b) 4 个释放 bank 同拍全在回收（各写 tailPtr+0..+3，写满 4 个口）——
//       注意它们的写地址按构造互不相同，golden 那条"高 bank 优先"的 else-if 链
//       是不可达的死优先级（详见 rtl/memblock/FreeList.sv 头注释）；
//   (c) 72 不是 2 的幂，指针每绕一圈都要显式减 72 —— 只有真的绕圈才会走到。
// 均匀随机的占用率会稳定在中段，几乎打不到 (a)(c)，释放位图也稀疏，(b) 打不满。
// 因此激励按相位轮转：抽干 → 猛灌 → 一次性大批释放 → 随机混合。
//
// ★ doAllocate 必须是**前缀掩码**（1/3/7，不能是 0b010 这种）：硬件契约是
//   headPtr 前进 PopCount(doAllocate)，而第 i 口拿的是 freeList[headPtr+i]。
//   只让 1 号口分配时，指针只走 1 格，于是 freeList[headPtr+1] 这个槽位下一拍
//   会被**再发一次**。这不是 RTL 的 bug（使用者按序占口），但激励若不守这条，
//   池里就会出现重复槽位号，"满/空"这两个边界从此再也回不去 —— 实测就是
//   full 计数只在第一轮出现过一次。两边 DUT 仍然逐拍一致，但边界覆盖丢了。
`timescale 1ns/1ps
module tb;
  localparam int SIZE = 72;

  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic         io_doAllocate_0, io_doAllocate_1, io_doAllocate_2;
  logic [71:0]  io_free;
  logic [6:0]   g_slot_0, g_slot_1, g_slot_2, i_slot_0, i_slot_1, i_slot_2;
  logic         g_can_0, g_can_1, g_can_2, i_can_0, i_can_1, i_can_2;
  logic         g_empty, i_empty;

  FreeList_5 g_u (
    .clock(clk), .reset(rst),
    .io_allocateSlot_0(g_slot_0), .io_allocateSlot_1(g_slot_1), .io_allocateSlot_2(g_slot_2),
    .io_canAllocate_0(g_can_0), .io_canAllocate_1(g_can_1), .io_canAllocate_2(g_can_2),
    .io_doAllocate_0(io_doAllocate_0), .io_doAllocate_1(io_doAllocate_1),
    .io_doAllocate_2(io_doAllocate_2),
    .io_free(io_free), .io_empty(g_empty));

  FreeList_5_xs i_u (
    .clock(clk), .reset(rst),
    .io_allocateSlot_0(i_slot_0), .io_allocateSlot_1(i_slot_1), .io_allocateSlot_2(i_slot_2),
    .io_canAllocate_0(i_can_0), .io_canAllocate_1(i_can_1), .io_canAllocate_2(i_can_2),
    .io_doAllocate_0(io_doAllocate_0), .io_doAllocate_1(io_doAllocate_1),
    .io_doAllocate_2(io_doAllocate_2),
    .io_free(io_free), .io_empty(i_empty));

  // ---------------------------------------------------------------------------
  // 激励模型：只释放"已分配未释放"的槽位，保证池里槽位号不重复（否则两边一起
  // 错，等于没测）。分配按 canAllocate 门控 —— 它是 preAlloc 打拍后的值，
  // 正是使用者（LoadQueueReplay）的用法。
  // ---------------------------------------------------------------------------
  bit [71:0] outstanding;    // 已取走、尚未释放的槽位
  bit [71:0] freeing;
  int        phase, phaseCnt, nAlloc;

  // 覆盖统计：证明上面那几个"只有定向才打得到"的状态真的被打到了
  int cov_empty;        // 池空（canAllocate 全 0）
  int cov_full;         // 池满（freeSlotCnt == 72）
  int cov_head_wrap;    // headPtr 绕圈（flag 翻转）次数
  int cov_tail_wrap;    // tailPtr 绕圈次数
  int cov_4bank;        // 同拍 4 个释放 bank 全在回收
  int cov_max_free;     // 单拍 io_free 里最多有几位
  bit prev_head_flag, prev_tail_flag;

  // 记账放在 posedge：此刻 io_doAllocate / g_slot_* / io_free 正是本拍真正生效的
  // 那一组值。（激励改用阻塞赋值在 negedge 给出，见下：这样 doAllocate 与
  // 它所依据的 canAllocate 处在**同一拍**，不会因为差一拍而超发。）
  always @(posedge clk) begin
    if (rst) begin
      outstanding <= '0;
    end else begin
      if (io_doAllocate_0) outstanding[g_slot_0] <= 1'b1;
      if (io_doAllocate_1) outstanding[g_slot_1] <= 1'b1;
      if (io_doAllocate_2) outstanding[g_slot_2] <= 1'b1;
      for (int k = 0; k < SIZE; k++) if (io_free[k]) outstanding[k] <= 1'b0;
    end
  end

  always @(negedge clk) begin
    if (rst) begin
      io_free = '0;
      io_doAllocate_0 = 1'b0; io_doAllocate_1 = 1'b0; io_doAllocate_2 = 1'b0;
      phase <= 0; phaseCnt <= 0;
    end else begin
      // --- 相位推进（每 60 拍换一档：足够抽干/灌满一轮，又能多轮往返）---
      phaseCnt <= phaseCnt + 1;
      if (phaseCnt >= 60) begin
        phaseCnt <= 0;
        phase    <= (phase + 1) % 4;
      end

      // 前缀掩码：nAlloc = 本拍占用的口数（0..3），逐口用 canAllocate 卡住
      nAlloc = 0;
      while (nAlloc < 3 &&
             ((nAlloc == 0) ? g_can_0 : (nAlloc == 1) ? g_can_1 : g_can_2))
        nAlloc = nAlloc + 1;

      freeing = '0;
      case (phase)
        // 相位 0：只分配不释放 —— 一路抽到空（canAllocate 全 0、io_empty=1），
        //         并让 headPtr 绕圈，踩非 2 幂回绕与 flag 翻转。
        0: begin
          io_doAllocate_0 = (nAlloc > 0);
          io_doAllocate_1 = (nAlloc > 1);
          io_doAllocate_2 = (nAlloc > 2);
        end

        // 相位 1：一次性把所有在外槽位全释放 —— io_free 同拍置到 70+ 位，
        //         4 个 bank 全程满负荷，连续多拍在 tailPtr 附近抢写地址。
        1: begin
          io_doAllocate_0 = 1'b0; io_doAllocate_1 = 1'b0; io_doAllocate_2 = 1'b0;
          freeing = outstanding;
        end

        // 相位 2：贴着边界来回 —— 分配到满，一满就整批放掉一半。
        2: begin
          nAlloc = (nAlloc > 0) ? $urandom_range(0, nAlloc) : 0;
          io_doAllocate_0 = (nAlloc > 0);
          io_doAllocate_1 = (nAlloc > 1);
          io_doAllocate_2 = (nAlloc > 2);
          if (!g_can_2)
            for (int k = 0; k < SIZE; k += 2) if (outstanding[k]) freeing[k] = 1'b1;
        end

        // 相位 3：常规随机混合
        default: begin
          nAlloc = (nAlloc > 0) ? $urandom_range(0, nAlloc) : 0;
          io_doAllocate_0 = (nAlloc > 0);
          io_doAllocate_1 = (nAlloc > 1);
          io_doAllocate_2 = (nAlloc > 2);
          for (int k = 0; k < SIZE; k++)
            if (outstanding[k] && ($urandom_range(0,99) < 20)) freeing[k] = 1'b1;
        end
      endcase
      io_free = freeing;
    end
  end

  `define CHK(nm, g, i) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors <= 80) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end

  // 覆盖采样（只看 golden 侧，采样点与比对点同拍）
  always @(posedge clk) if (!rst) begin
    int nf, nb;
    if (g_empty) cov_empty++;
    if (g_u.freeSlotCnt == 7'd72) cov_full++;
    if (g_u.headPtr_flag !== prev_head_flag) cov_head_wrap++;
    if (g_u.tailPtr_flag !== prev_tail_flag) cov_tail_wrap++;
    prev_head_flag <= g_u.headPtr_flag;
    prev_tail_flag <= g_u.tailPtr_flag;
    nb = g_u.freeReq_next_nextVec_0_r + g_u.freeReq_next_nextVec_1_r
       + g_u.freeReq_next_nextVec_2_r + g_u.freeReq_next_nextVec_3_r;
    if (nb == 4) cov_4bank++;
    nf = $countones(io_free);
    if (nf > cov_max_free) cov_max_free <= nf;
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("io_allocateSlot_0", g_slot_0, i_slot_0)
    `CHK("io_allocateSlot_1", g_slot_1, i_slot_1)
    `CHK("io_allocateSlot_2", g_slot_2, i_slot_2)
    `CHK("io_canAllocate_0",  g_can_0,  i_can_0)
    `CHK("io_canAllocate_1",  g_can_1,  i_can_1)
    `CHK("io_canAllocate_2",  g_can_2,  i_can_2)
    `CHK("io_empty",          g_empty,  i_empty)

    // 内部状态也比 —— 输出被 ready/指针遮蔽时内部先错，早一步抓到
    if (!$isunknown(g_u.headPtr_flag)) begin
      `CHK("headPtr.flag",  g_u.headPtr_flag,  i_u.u_core.headPtr.flag)
      `CHK("headPtr.value", g_u.headPtr_value, i_u.u_core.headPtr.value)
      `CHK("tailPtr.flag",  g_u.tailPtr_flag,  i_u.u_core.tailPtr.flag)
      `CHK("tailPtr.value", g_u.tailPtr_value, i_u.u_core.tailPtr.value)
      `CHK("freeMask",      g_u.freeMask,      i_u.u_core.freeMask)
      `CHK("freeSlotCnt",   g_u.freeSlotCnt,   i_u.u_core.freeSlotCnt)
      `CHK("freeList_0",    g_u.freeList_0,    i_u.u_core.freeList[0])
      `CHK("freeList_71",   g_u.freeList_71,   i_u.u_core.freeList[71])
    end
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("COV empty=%0d full=%0d head_wrap=%0d tail_wrap=%0d all4banks=%0d max_free_bits=%0d",
             cov_empty, cov_full, cov_head_wrap, cov_tail_wrap, cov_4bank, cov_max_free);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
