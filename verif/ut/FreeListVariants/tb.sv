// FreeListVariants UT —— FreeList 家族剩余 4 个变体的 golden/重写件双例化逐拍比对
//
// 本目录证的是 FreeList_1 / FreeList_3 / FreeList_4 / FreeList_6 四个单态化变体。
// 基础 FreeList 与 FreeList_5 已各自有 UT 目录（verif/ut/FreeList、verif/ut/FreeList_5）
// 并已出过 receipt —— 一个 golden 顶层只由一个 UT 出 receipt，故此处不重复覆盖它们。
//
// 四个变体共用 rtl/memblock/FreeList.sv 里的同一个参数化核 xs_FreeList_core，
// 差异维度只有 (SIZE, ALLOC_WIDTH, FREE_WIDTH, ENABLE_PRE_ALLOC) 四个参数
// 加两个"golden 裁没裁端口"的事实。tb 由 gen_tb.py 按同一模板生成，
// **改请改生成器**（手改会被下一次跑生成器静默覆盖）。
//
// 激励设计（沿用 verif/ut/FreeList_5/tb.sv 的相位轮转，理由同）：
//   均匀随机会把占用率钉在中段，打不到"满/空"边界，也打不满释放 bank。
//   所以按相位轮转：抽干 -> 一次性全释放 -> 贴边界来回 -> 随机混合。
//   ★doAllocate 必须是前缀掩码★，否则池里会出现重复槽位号、边界覆盖从此丢失。
//   tb 自带 dup_alloc 计数器把这件事变成可观测量：它非 0 就说明激励破了不变式。
//
// ★本文件由 gen_tb.py 生成，勿手改★
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  `define CHK(nm, g, i) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors <= 80) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end

  // ===========================================================================
  // FreeList_1: SIZE=16 ALLOC=1 FREE=1 preAlloc=0  canAllocate=无（golden 裁掉）  validCount=有
  // ===========================================================================
  localparam int FREELIST_1_SIZE = 16;
  logic [0:0]  freelist_1_do;
  logic [15:0] freelist_1_free;
  logic [3:0] freelist_1_g_slot [1];
  logic [4:0] freelist_1_g_vc;
  logic        freelist_1_g_empty;
  logic [3:0] freelist_1_i_slot [1];
  logic [4:0] freelist_1_i_vc;
  logic        freelist_1_i_empty;
  FreeList_1 freelist_1_g_u (
    .clock(clk), .reset(rst),
    .io_allocateSlot_0(freelist_1_g_slot[0]),
    .io_doAllocate_0(freelist_1_do[0]),
    .io_free(freelist_1_free),
    .io_validCount(freelist_1_g_vc),
    .io_empty(freelist_1_g_empty));
  FreeList_1_xs freelist_1_i_u (
    .clock(clk), .reset(rst),
    .io_allocateSlot_0(freelist_1_i_slot[0]),
    .io_doAllocate_0(freelist_1_do[0]),
    .io_free(freelist_1_free),
    .io_validCount(freelist_1_i_vc),
    .io_empty(freelist_1_i_empty));
  bit [15:0] freelist_1_outstanding;
  bit [15:0] freelist_1_freeing;
  int freelist_1_phase, freelist_1_phaseCnt, freelist_1_nAlloc;
  int freelist_1_cov_empty, freelist_1_cov_full, freelist_1_cov_hwrap, freelist_1_cov_twrap, freelist_1_cov_allbank, freelist_1_cov_maxfree, freelist_1_cov_dupalloc;
  bit freelist_1_prev_hflag, freelist_1_prev_tflag;

  always @(posedge clk) begin
    if (rst) freelist_1_outstanding <= '0;
    else begin
      if (freelist_1_do[0]) begin
        if (freelist_1_outstanding[freelist_1_g_slot[0]]) freelist_1_cov_dupalloc <= freelist_1_cov_dupalloc + 1;
        freelist_1_outstanding[freelist_1_g_slot[0]] <= 1'b1;
      end
      for (int k = 0; k < 16; k++)
        if (freelist_1_free[k]) freelist_1_outstanding[k] <= 1'b0;
    end
  end

  always @(negedge clk) begin
    if (rst) begin
      freelist_1_free = '0; freelist_1_do = '0;
      freelist_1_phase <= 0; freelist_1_phaseCnt <= 0;
    end else begin
      freelist_1_phaseCnt <= freelist_1_phaseCnt + 1;
      if (freelist_1_phaseCnt >= 60) begin
        freelist_1_phaseCnt <= 0; freelist_1_phase <= (freelist_1_phase + 1) % 4;
      end
      freelist_1_nAlloc = 0;
      while (freelist_1_nAlloc < 1 && (freelist_1_g_u.freeSlotCnt > 5'(freelist_1_nAlloc))) freelist_1_nAlloc = freelist_1_nAlloc + 1;
      freelist_1_freeing = '0;
      case (freelist_1_phase)
        // 相位 0：只分配不释放 —— 抽到空，逼 headPtr 绕圈
        0: ;
        // 相位 1：一次性全释放 —— io_free 打满，1 个 bank 满负荷
        1: begin freelist_1_nAlloc = 0; freelist_1_freeing = freelist_1_outstanding; end
        // 相位 2：贴边界来回 —— 分配到满，一满就整批放掉一半
        2: begin
          freelist_1_nAlloc = (freelist_1_nAlloc > 0) ? $urandom_range(0, freelist_1_nAlloc) : 0;
          if (freelist_1_g_u.freeSlotCnt < 5'd2)
            for (int k = 0; k < 16; k += 2)
              if (freelist_1_outstanding[k]) freelist_1_freeing[k] = 1'b1;
        end
        // 相位 3：常规随机混合
        default: begin
          freelist_1_nAlloc = (freelist_1_nAlloc > 0) ? $urandom_range(0, freelist_1_nAlloc) : 0;
          for (int k = 0; k < 16; k++)
            if (freelist_1_outstanding[k] && ($urandom_range(0,99) < 20)) freelist_1_freeing[k] = 1'b1;
        end
      endcase
      // doAllocate 必须是**前缀掩码**：硬件契约是 headPtr 前进 PopCount(doAllocate)
      // 而第 i 口拿的是 freeList[headPtr+i]，跳着占口会让槽位被重复发出。
      freelist_1_do[0] = (freelist_1_nAlloc > 0);
      freelist_1_free = freelist_1_freeing;
    end
  end

  always @(posedge clk) if (!rst) begin
    int nf, nb;
    if (freelist_1_g_empty) freelist_1_cov_empty++;
    if (freelist_1_g_u.freeSlotCnt == 5'd16) freelist_1_cov_full++;
    if (freelist_1_g_u.headPtr_flag !== freelist_1_prev_hflag) freelist_1_cov_hwrap++;
    if (freelist_1_g_u.tailPtr_flag !== freelist_1_prev_tflag) freelist_1_cov_twrap++;
    freelist_1_prev_hflag <= freelist_1_g_u.headPtr_flag;
    freelist_1_prev_tflag <= freelist_1_g_u.tailPtr_flag;
    nb = freelist_1_g_u.freeReq_next_nextVec_0_r;
    if (nb == 1) freelist_1_cov_allbank++;
    nf = $countones(freelist_1_free);
    if (nf > freelist_1_cov_maxfree) freelist_1_cov_maxfree <= nf;
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("FreeList_1.allocateSlot_0", freelist_1_g_slot[0], freelist_1_i_slot[0])
    `CHK("FreeList_1.validCount", freelist_1_g_vc, freelist_1_i_vc)
    `CHK("FreeList_1.empty", freelist_1_g_empty, freelist_1_i_empty)
    if (!$isunknown(freelist_1_g_u.headPtr_flag)) begin
      `CHK("FreeList_1.headPtr.flag",  freelist_1_g_u.headPtr_flag,  freelist_1_i_u.u_core.headPtr.flag)
      `CHK("FreeList_1.headPtr.value", freelist_1_g_u.headPtr_value, freelist_1_i_u.u_core.headPtr.value)
      `CHK("FreeList_1.tailPtr.flag",  freelist_1_g_u.tailPtr_flag,  freelist_1_i_u.u_core.tailPtr.flag)
      `CHK("FreeList_1.tailPtr.value", freelist_1_g_u.tailPtr_value, freelist_1_i_u.u_core.tailPtr.value)
      `CHK("FreeList_1.freeMask",      freelist_1_g_u.freeMask,      freelist_1_i_u.u_core.freeMask)
      `CHK("FreeList_1.freeSlotCnt",   freelist_1_g_u.freeSlotCnt,   freelist_1_i_u.u_core.freeSlotCnt)
      `CHK("FreeList_1.freeReq_0", freelist_1_g_u.freeReq_next_nextVec_0_r, freelist_1_i_u.u_core.freeReqReg[0])
      `CHK("FreeList_1.freeSlotOH_0", freelist_1_g_u.freeSlotOH_next_nextVec_0_r, freelist_1_i_u.u_core.freeSlotOHReg[0])
      `CHK("FreeList_1.freeList[0]", freelist_1_g_u.freeList_0, freelist_1_i_u.u_core.freeList[0])
      `CHK("FreeList_1.freeList[8]", freelist_1_g_u.freeList_8, freelist_1_i_u.u_core.freeList[8])
      `CHK("FreeList_1.freeList[15]", freelist_1_g_u.freeList_15, freelist_1_i_u.u_core.freeList[15])
    end
  end

  // ===========================================================================
  // FreeList_3: SIZE=72 ALLOC=3 FREE=4 preAlloc=0  canAllocate=有  validCount=有
  // ===========================================================================
  localparam int FREELIST_3_SIZE = 72;
  logic [2:0]  freelist_3_do;
  logic [71:0] freelist_3_free;
  logic [6:0] freelist_3_g_slot [3];
  logic [2:0] freelist_3_g_can;
  logic [6:0] freelist_3_g_vc;
  logic        freelist_3_g_empty;
  logic [6:0] freelist_3_i_slot [3];
  logic [2:0] freelist_3_i_can;
  logic [6:0] freelist_3_i_vc;
  logic        freelist_3_i_empty;
  FreeList_3 freelist_3_g_u (
    .clock(clk), .reset(rst),
    .io_allocateSlot_0(freelist_3_g_slot[0]),
    .io_allocateSlot_1(freelist_3_g_slot[1]),
    .io_allocateSlot_2(freelist_3_g_slot[2]),
    .io_canAllocate_0(freelist_3_g_can[0]),
    .io_canAllocate_1(freelist_3_g_can[1]),
    .io_canAllocate_2(freelist_3_g_can[2]),
    .io_doAllocate_0(freelist_3_do[0]),
    .io_doAllocate_1(freelist_3_do[1]),
    .io_doAllocate_2(freelist_3_do[2]),
    .io_free(freelist_3_free),
    .io_validCount(freelist_3_g_vc),
    .io_empty(freelist_3_g_empty));
  FreeList_3_xs freelist_3_i_u (
    .clock(clk), .reset(rst),
    .io_allocateSlot_0(freelist_3_i_slot[0]),
    .io_allocateSlot_1(freelist_3_i_slot[1]),
    .io_allocateSlot_2(freelist_3_i_slot[2]),
    .io_canAllocate_0(freelist_3_i_can[0]),
    .io_canAllocate_1(freelist_3_i_can[1]),
    .io_canAllocate_2(freelist_3_i_can[2]),
    .io_doAllocate_0(freelist_3_do[0]),
    .io_doAllocate_1(freelist_3_do[1]),
    .io_doAllocate_2(freelist_3_do[2]),
    .io_free(freelist_3_free),
    .io_validCount(freelist_3_i_vc),
    .io_empty(freelist_3_i_empty));
  bit [71:0] freelist_3_outstanding;
  bit [71:0] freelist_3_freeing;
  int freelist_3_phase, freelist_3_phaseCnt, freelist_3_nAlloc;
  int freelist_3_cov_empty, freelist_3_cov_full, freelist_3_cov_hwrap, freelist_3_cov_twrap, freelist_3_cov_allbank, freelist_3_cov_maxfree, freelist_3_cov_dupalloc;
  bit freelist_3_prev_hflag, freelist_3_prev_tflag;

  always @(posedge clk) begin
    if (rst) freelist_3_outstanding <= '0;
    else begin
      if (freelist_3_do[0]) begin
        if (freelist_3_outstanding[freelist_3_g_slot[0]]) freelist_3_cov_dupalloc <= freelist_3_cov_dupalloc + 1;
        freelist_3_outstanding[freelist_3_g_slot[0]] <= 1'b1;
      end
      if (freelist_3_do[1]) begin
        if (freelist_3_outstanding[freelist_3_g_slot[1]]) freelist_3_cov_dupalloc <= freelist_3_cov_dupalloc + 1;
        freelist_3_outstanding[freelist_3_g_slot[1]] <= 1'b1;
      end
      if (freelist_3_do[2]) begin
        if (freelist_3_outstanding[freelist_3_g_slot[2]]) freelist_3_cov_dupalloc <= freelist_3_cov_dupalloc + 1;
        freelist_3_outstanding[freelist_3_g_slot[2]] <= 1'b1;
      end
      for (int k = 0; k < 72; k++)
        if (freelist_3_free[k]) freelist_3_outstanding[k] <= 1'b0;
    end
  end

  always @(negedge clk) begin
    if (rst) begin
      freelist_3_free = '0; freelist_3_do = '0;
      freelist_3_phase <= 0; freelist_3_phaseCnt <= 0;
    end else begin
      freelist_3_phaseCnt <= freelist_3_phaseCnt + 1;
      if (freelist_3_phaseCnt >= 144) begin
        freelist_3_phaseCnt <= 0; freelist_3_phase <= (freelist_3_phase + 1) % 4;
      end
      freelist_3_nAlloc = 0;
      while (freelist_3_nAlloc < 3 && ((freelist_3_nAlloc == 0 && freelist_3_g_can[0]) || (freelist_3_nAlloc == 1 && freelist_3_g_can[1]) || (freelist_3_nAlloc == 2 && freelist_3_g_can[2]))) freelist_3_nAlloc = freelist_3_nAlloc + 1;
      freelist_3_freeing = '0;
      case (freelist_3_phase)
        // 相位 0：只分配不释放 —— 抽到空，逼 headPtr 绕圈
        0: ;
        // 相位 1：一次性全释放 —— io_free 打满，4 个 bank 满负荷
        1: begin freelist_3_nAlloc = 0; freelist_3_freeing = freelist_3_outstanding; end
        // 相位 2：贴边界来回 —— 分配到满，一满就整批放掉一半
        2: begin
          freelist_3_nAlloc = (freelist_3_nAlloc > 0) ? $urandom_range(0, freelist_3_nAlloc) : 0;
          if (freelist_3_g_u.freeSlotCnt < 7'd2)
            for (int k = 0; k < 72; k += 2)
              if (freelist_3_outstanding[k]) freelist_3_freeing[k] = 1'b1;
        end
        // 相位 3：常规随机混合
        default: begin
          freelist_3_nAlloc = (freelist_3_nAlloc > 0) ? $urandom_range(0, freelist_3_nAlloc) : 0;
          for (int k = 0; k < 72; k++)
            if (freelist_3_outstanding[k] && ($urandom_range(0,99) < 20)) freelist_3_freeing[k] = 1'b1;
        end
      endcase
      // doAllocate 必须是**前缀掩码**：硬件契约是 headPtr 前进 PopCount(doAllocate)
      // 而第 i 口拿的是 freeList[headPtr+i]，跳着占口会让槽位被重复发出。
      freelist_3_do[0] = (freelist_3_nAlloc > 0);
      freelist_3_do[1] = (freelist_3_nAlloc > 1);
      freelist_3_do[2] = (freelist_3_nAlloc > 2);
      freelist_3_free = freelist_3_freeing;
    end
  end

  always @(posedge clk) if (!rst) begin
    int nf, nb;
    if (freelist_3_g_empty) freelist_3_cov_empty++;
    if (freelist_3_g_u.freeSlotCnt == 7'd72) freelist_3_cov_full++;
    if (freelist_3_g_u.headPtr_flag !== freelist_3_prev_hflag) freelist_3_cov_hwrap++;
    if (freelist_3_g_u.tailPtr_flag !== freelist_3_prev_tflag) freelist_3_cov_twrap++;
    freelist_3_prev_hflag <= freelist_3_g_u.headPtr_flag;
    freelist_3_prev_tflag <= freelist_3_g_u.tailPtr_flag;
    nb = freelist_3_g_u.freeReq_next_nextVec_0_r + freelist_3_g_u.freeReq_next_nextVec_1_r + freelist_3_g_u.freeReq_next_nextVec_2_r + freelist_3_g_u.freeReq_next_nextVec_3_r;
    if (nb == 4) freelist_3_cov_allbank++;
    nf = $countones(freelist_3_free);
    if (nf > freelist_3_cov_maxfree) freelist_3_cov_maxfree <= nf;
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("FreeList_3.allocateSlot_0", freelist_3_g_slot[0], freelist_3_i_slot[0])
    `CHK("FreeList_3.allocateSlot_1", freelist_3_g_slot[1], freelist_3_i_slot[1])
    `CHK("FreeList_3.allocateSlot_2", freelist_3_g_slot[2], freelist_3_i_slot[2])
    `CHK("FreeList_3.canAllocate_0", freelist_3_g_can[0], freelist_3_i_can[0])
    `CHK("FreeList_3.canAllocate_1", freelist_3_g_can[1], freelist_3_i_can[1])
    `CHK("FreeList_3.canAllocate_2", freelist_3_g_can[2], freelist_3_i_can[2])
    `CHK("FreeList_3.validCount", freelist_3_g_vc, freelist_3_i_vc)
    `CHK("FreeList_3.empty", freelist_3_g_empty, freelist_3_i_empty)
    if (!$isunknown(freelist_3_g_u.headPtr_flag)) begin
      `CHK("FreeList_3.headPtr.flag",  freelist_3_g_u.headPtr_flag,  freelist_3_i_u.u_core.headPtr.flag)
      `CHK("FreeList_3.headPtr.value", freelist_3_g_u.headPtr_value, freelist_3_i_u.u_core.headPtr.value)
      `CHK("FreeList_3.tailPtr.flag",  freelist_3_g_u.tailPtr_flag,  freelist_3_i_u.u_core.tailPtr.flag)
      `CHK("FreeList_3.tailPtr.value", freelist_3_g_u.tailPtr_value, freelist_3_i_u.u_core.tailPtr.value)
      `CHK("FreeList_3.freeMask",      freelist_3_g_u.freeMask,      freelist_3_i_u.u_core.freeMask)
      `CHK("FreeList_3.freeSlotCnt",   freelist_3_g_u.freeSlotCnt,   freelist_3_i_u.u_core.freeSlotCnt)
      `CHK("FreeList_3.freeReq_0", freelist_3_g_u.freeReq_next_nextVec_0_r, freelist_3_i_u.u_core.freeReqReg[0])
      `CHK("FreeList_3.freeSlotOH_0", freelist_3_g_u.freeSlotOH_next_nextVec_0_r, freelist_3_i_u.u_core.freeSlotOHReg[0])
      `CHK("FreeList_3.freeReq_1", freelist_3_g_u.freeReq_next_nextVec_1_r, freelist_3_i_u.u_core.freeReqReg[1])
      `CHK("FreeList_3.freeSlotOH_1", freelist_3_g_u.freeSlotOH_next_nextVec_1_r, freelist_3_i_u.u_core.freeSlotOHReg[1])
      `CHK("FreeList_3.freeReq_2", freelist_3_g_u.freeReq_next_nextVec_2_r, freelist_3_i_u.u_core.freeReqReg[2])
      `CHK("FreeList_3.freeSlotOH_2", freelist_3_g_u.freeSlotOH_next_nextVec_2_r, freelist_3_i_u.u_core.freeSlotOHReg[2])
      `CHK("FreeList_3.freeReq_3", freelist_3_g_u.freeReq_next_nextVec_3_r, freelist_3_i_u.u_core.freeReqReg[3])
      `CHK("FreeList_3.freeSlotOH_3", freelist_3_g_u.freeSlotOH_next_nextVec_3_r, freelist_3_i_u.u_core.freeSlotOHReg[3])
      `CHK("FreeList_3.freeList[0]", freelist_3_g_u.freeList_0, freelist_3_i_u.u_core.freeList[0])
      `CHK("FreeList_3.freeList[36]", freelist_3_g_u.freeList_36, freelist_3_i_u.u_core.freeList[36])
      `CHK("FreeList_3.freeList[71]", freelist_3_g_u.freeList_71, freelist_3_i_u.u_core.freeList[71])
    end
  end

  // ===========================================================================
  // FreeList_4: SIZE=32 ALLOC=3 FREE=4 preAlloc=1  canAllocate=有  validCount=有
  // ===========================================================================
  localparam int FREELIST_4_SIZE = 32;
  logic [2:0]  freelist_4_do;
  logic [31:0] freelist_4_free;
  logic [4:0] freelist_4_g_slot [3];
  logic [2:0] freelist_4_g_can;
  logic [5:0] freelist_4_g_vc;
  logic        freelist_4_g_empty;
  logic [4:0] freelist_4_i_slot [3];
  logic [2:0] freelist_4_i_can;
  logic [5:0] freelist_4_i_vc;
  logic        freelist_4_i_empty;
  FreeList_4 freelist_4_g_u (
    .clock(clk), .reset(rst),
    .io_allocateSlot_0(freelist_4_g_slot[0]),
    .io_allocateSlot_1(freelist_4_g_slot[1]),
    .io_allocateSlot_2(freelist_4_g_slot[2]),
    .io_canAllocate_0(freelist_4_g_can[0]),
    .io_canAllocate_1(freelist_4_g_can[1]),
    .io_canAllocate_2(freelist_4_g_can[2]),
    .io_doAllocate_0(freelist_4_do[0]),
    .io_doAllocate_1(freelist_4_do[1]),
    .io_doAllocate_2(freelist_4_do[2]),
    .io_free(freelist_4_free),
    .io_validCount(freelist_4_g_vc),
    .io_empty(freelist_4_g_empty));
  FreeList_4_xs freelist_4_i_u (
    .clock(clk), .reset(rst),
    .io_allocateSlot_0(freelist_4_i_slot[0]),
    .io_allocateSlot_1(freelist_4_i_slot[1]),
    .io_allocateSlot_2(freelist_4_i_slot[2]),
    .io_canAllocate_0(freelist_4_i_can[0]),
    .io_canAllocate_1(freelist_4_i_can[1]),
    .io_canAllocate_2(freelist_4_i_can[2]),
    .io_doAllocate_0(freelist_4_do[0]),
    .io_doAllocate_1(freelist_4_do[1]),
    .io_doAllocate_2(freelist_4_do[2]),
    .io_free(freelist_4_free),
    .io_validCount(freelist_4_i_vc),
    .io_empty(freelist_4_i_empty));
  bit [31:0] freelist_4_outstanding;
  bit [31:0] freelist_4_freeing;
  int freelist_4_phase, freelist_4_phaseCnt, freelist_4_nAlloc;
  int freelist_4_cov_empty, freelist_4_cov_full, freelist_4_cov_hwrap, freelist_4_cov_twrap, freelist_4_cov_allbank, freelist_4_cov_maxfree, freelist_4_cov_dupalloc;
  bit freelist_4_prev_hflag, freelist_4_prev_tflag;

  always @(posedge clk) begin
    if (rst) freelist_4_outstanding <= '0;
    else begin
      if (freelist_4_do[0]) begin
        if (freelist_4_outstanding[freelist_4_g_slot[0]]) freelist_4_cov_dupalloc <= freelist_4_cov_dupalloc + 1;
        freelist_4_outstanding[freelist_4_g_slot[0]] <= 1'b1;
      end
      if (freelist_4_do[1]) begin
        if (freelist_4_outstanding[freelist_4_g_slot[1]]) freelist_4_cov_dupalloc <= freelist_4_cov_dupalloc + 1;
        freelist_4_outstanding[freelist_4_g_slot[1]] <= 1'b1;
      end
      if (freelist_4_do[2]) begin
        if (freelist_4_outstanding[freelist_4_g_slot[2]]) freelist_4_cov_dupalloc <= freelist_4_cov_dupalloc + 1;
        freelist_4_outstanding[freelist_4_g_slot[2]] <= 1'b1;
      end
      for (int k = 0; k < 32; k++)
        if (freelist_4_free[k]) freelist_4_outstanding[k] <= 1'b0;
    end
  end

  always @(negedge clk) begin
    if (rst) begin
      freelist_4_free = '0; freelist_4_do = '0;
      freelist_4_phase <= 0; freelist_4_phaseCnt <= 0;
    end else begin
      freelist_4_phaseCnt <= freelist_4_phaseCnt + 1;
      if (freelist_4_phaseCnt >= 64) begin
        freelist_4_phaseCnt <= 0; freelist_4_phase <= (freelist_4_phase + 1) % 4;
      end
      freelist_4_nAlloc = 0;
      while (freelist_4_nAlloc < 3 && ((freelist_4_nAlloc == 0 && freelist_4_g_can[0]) || (freelist_4_nAlloc == 1 && freelist_4_g_can[1]) || (freelist_4_nAlloc == 2 && freelist_4_g_can[2]))) freelist_4_nAlloc = freelist_4_nAlloc + 1;
      freelist_4_freeing = '0;
      case (freelist_4_phase)
        // 相位 0：只分配不释放 —— 抽到空，逼 headPtr 绕圈
        0: ;
        // 相位 1：一次性全释放 —— io_free 打满，4 个 bank 满负荷
        1: begin freelist_4_nAlloc = 0; freelist_4_freeing = freelist_4_outstanding; end
        // 相位 2：贴边界来回 —— 分配到满，一满就整批放掉一半
        2: begin
          freelist_4_nAlloc = (freelist_4_nAlloc > 0) ? $urandom_range(0, freelist_4_nAlloc) : 0;
          if (freelist_4_g_u.freeSlotCnt < 6'd2)
            for (int k = 0; k < 32; k += 2)
              if (freelist_4_outstanding[k]) freelist_4_freeing[k] = 1'b1;
        end
        // 相位 3：常规随机混合
        default: begin
          freelist_4_nAlloc = (freelist_4_nAlloc > 0) ? $urandom_range(0, freelist_4_nAlloc) : 0;
          for (int k = 0; k < 32; k++)
            if (freelist_4_outstanding[k] && ($urandom_range(0,99) < 20)) freelist_4_freeing[k] = 1'b1;
        end
      endcase
      // doAllocate 必须是**前缀掩码**：硬件契约是 headPtr 前进 PopCount(doAllocate)
      // 而第 i 口拿的是 freeList[headPtr+i]，跳着占口会让槽位被重复发出。
      freelist_4_do[0] = (freelist_4_nAlloc > 0);
      freelist_4_do[1] = (freelist_4_nAlloc > 1);
      freelist_4_do[2] = (freelist_4_nAlloc > 2);
      freelist_4_free = freelist_4_freeing;
    end
  end

  always @(posedge clk) if (!rst) begin
    int nf, nb;
    if (freelist_4_g_empty) freelist_4_cov_empty++;
    if (freelist_4_g_u.freeSlotCnt == 6'd32) freelist_4_cov_full++;
    if (freelist_4_g_u.headPtr_flag !== freelist_4_prev_hflag) freelist_4_cov_hwrap++;
    if (freelist_4_g_u.tailPtr_flag !== freelist_4_prev_tflag) freelist_4_cov_twrap++;
    freelist_4_prev_hflag <= freelist_4_g_u.headPtr_flag;
    freelist_4_prev_tflag <= freelist_4_g_u.tailPtr_flag;
    nb = freelist_4_g_u.freeReq_next_nextVec_0_r + freelist_4_g_u.freeReq_next_nextVec_1_r + freelist_4_g_u.freeReq_next_nextVec_2_r + freelist_4_g_u.freeReq_next_nextVec_3_r;
    if (nb == 4) freelist_4_cov_allbank++;
    nf = $countones(freelist_4_free);
    if (nf > freelist_4_cov_maxfree) freelist_4_cov_maxfree <= nf;
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("FreeList_4.allocateSlot_0", freelist_4_g_slot[0], freelist_4_i_slot[0])
    `CHK("FreeList_4.allocateSlot_1", freelist_4_g_slot[1], freelist_4_i_slot[1])
    `CHK("FreeList_4.allocateSlot_2", freelist_4_g_slot[2], freelist_4_i_slot[2])
    `CHK("FreeList_4.canAllocate_0", freelist_4_g_can[0], freelist_4_i_can[0])
    `CHK("FreeList_4.canAllocate_1", freelist_4_g_can[1], freelist_4_i_can[1])
    `CHK("FreeList_4.canAllocate_2", freelist_4_g_can[2], freelist_4_i_can[2])
    `CHK("FreeList_4.validCount", freelist_4_g_vc, freelist_4_i_vc)
    `CHK("FreeList_4.empty", freelist_4_g_empty, freelist_4_i_empty)
    if (!$isunknown(freelist_4_g_u.headPtr_flag)) begin
      `CHK("FreeList_4.headPtr.flag",  freelist_4_g_u.headPtr_flag,  freelist_4_i_u.u_core.headPtr.flag)
      `CHK("FreeList_4.headPtr.value", freelist_4_g_u.headPtr_value, freelist_4_i_u.u_core.headPtr.value)
      `CHK("FreeList_4.tailPtr.flag",  freelist_4_g_u.tailPtr_flag,  freelist_4_i_u.u_core.tailPtr.flag)
      `CHK("FreeList_4.tailPtr.value", freelist_4_g_u.tailPtr_value, freelist_4_i_u.u_core.tailPtr.value)
      `CHK("FreeList_4.freeMask",      freelist_4_g_u.freeMask,      freelist_4_i_u.u_core.freeMask)
      `CHK("FreeList_4.freeSlotCnt",   freelist_4_g_u.freeSlotCnt,   freelist_4_i_u.u_core.freeSlotCnt)
      `CHK("FreeList_4.freeReq_0", freelist_4_g_u.freeReq_next_nextVec_0_r, freelist_4_i_u.u_core.freeReqReg[0])
      `CHK("FreeList_4.freeSlotOH_0", freelist_4_g_u.freeSlotOH_next_nextVec_0_r, freelist_4_i_u.u_core.freeSlotOHReg[0])
      `CHK("FreeList_4.freeReq_1", freelist_4_g_u.freeReq_next_nextVec_1_r, freelist_4_i_u.u_core.freeReqReg[1])
      `CHK("FreeList_4.freeSlotOH_1", freelist_4_g_u.freeSlotOH_next_nextVec_1_r, freelist_4_i_u.u_core.freeSlotOHReg[1])
      `CHK("FreeList_4.freeReq_2", freelist_4_g_u.freeReq_next_nextVec_2_r, freelist_4_i_u.u_core.freeReqReg[2])
      `CHK("FreeList_4.freeSlotOH_2", freelist_4_g_u.freeSlotOH_next_nextVec_2_r, freelist_4_i_u.u_core.freeSlotOHReg[2])
      `CHK("FreeList_4.freeReq_3", freelist_4_g_u.freeReq_next_nextVec_3_r, freelist_4_i_u.u_core.freeReqReg[3])
      `CHK("FreeList_4.freeSlotOH_3", freelist_4_g_u.freeSlotOH_next_nextVec_3_r, freelist_4_i_u.u_core.freeSlotOHReg[3])
      `CHK("FreeList_4.freeList[0]", freelist_4_g_u.freeList_0, freelist_4_i_u.u_core.freeList[0])
      `CHK("FreeList_4.freeList[16]", freelist_4_g_u.freeList_16, freelist_4_i_u.u_core.freeList[16])
      `CHK("FreeList_4.freeList[31]", freelist_4_g_u.freeList_31, freelist_4_i_u.u_core.freeList[31])
    end
  end

  // ===========================================================================
  // FreeList_6: SIZE=16 ALLOC=3 FREE=4 preAlloc=1  canAllocate=有  validCount=有
  // ===========================================================================
  localparam int FREELIST_6_SIZE = 16;
  logic [2:0]  freelist_6_do;
  logic [15:0] freelist_6_free;
  logic [3:0] freelist_6_g_slot [3];
  logic [2:0] freelist_6_g_can;
  logic [4:0] freelist_6_g_vc;
  logic        freelist_6_g_empty;
  logic [3:0] freelist_6_i_slot [3];
  logic [2:0] freelist_6_i_can;
  logic [4:0] freelist_6_i_vc;
  logic        freelist_6_i_empty;
  FreeList_6 freelist_6_g_u (
    .clock(clk), .reset(rst),
    .io_allocateSlot_0(freelist_6_g_slot[0]),
    .io_allocateSlot_1(freelist_6_g_slot[1]),
    .io_allocateSlot_2(freelist_6_g_slot[2]),
    .io_canAllocate_0(freelist_6_g_can[0]),
    .io_canAllocate_1(freelist_6_g_can[1]),
    .io_canAllocate_2(freelist_6_g_can[2]),
    .io_doAllocate_0(freelist_6_do[0]),
    .io_doAllocate_1(freelist_6_do[1]),
    .io_doAllocate_2(freelist_6_do[2]),
    .io_free(freelist_6_free),
    .io_validCount(freelist_6_g_vc),
    .io_empty(freelist_6_g_empty));
  FreeList_6_xs freelist_6_i_u (
    .clock(clk), .reset(rst),
    .io_allocateSlot_0(freelist_6_i_slot[0]),
    .io_allocateSlot_1(freelist_6_i_slot[1]),
    .io_allocateSlot_2(freelist_6_i_slot[2]),
    .io_canAllocate_0(freelist_6_i_can[0]),
    .io_canAllocate_1(freelist_6_i_can[1]),
    .io_canAllocate_2(freelist_6_i_can[2]),
    .io_doAllocate_0(freelist_6_do[0]),
    .io_doAllocate_1(freelist_6_do[1]),
    .io_doAllocate_2(freelist_6_do[2]),
    .io_free(freelist_6_free),
    .io_validCount(freelist_6_i_vc),
    .io_empty(freelist_6_i_empty));
  bit [15:0] freelist_6_outstanding;
  bit [15:0] freelist_6_freeing;
  int freelist_6_phase, freelist_6_phaseCnt, freelist_6_nAlloc;
  int freelist_6_cov_empty, freelist_6_cov_full, freelist_6_cov_hwrap, freelist_6_cov_twrap, freelist_6_cov_allbank, freelist_6_cov_maxfree, freelist_6_cov_dupalloc;
  bit freelist_6_prev_hflag, freelist_6_prev_tflag;

  always @(posedge clk) begin
    if (rst) freelist_6_outstanding <= '0;
    else begin
      if (freelist_6_do[0]) begin
        if (freelist_6_outstanding[freelist_6_g_slot[0]]) freelist_6_cov_dupalloc <= freelist_6_cov_dupalloc + 1;
        freelist_6_outstanding[freelist_6_g_slot[0]] <= 1'b1;
      end
      if (freelist_6_do[1]) begin
        if (freelist_6_outstanding[freelist_6_g_slot[1]]) freelist_6_cov_dupalloc <= freelist_6_cov_dupalloc + 1;
        freelist_6_outstanding[freelist_6_g_slot[1]] <= 1'b1;
      end
      if (freelist_6_do[2]) begin
        if (freelist_6_outstanding[freelist_6_g_slot[2]]) freelist_6_cov_dupalloc <= freelist_6_cov_dupalloc + 1;
        freelist_6_outstanding[freelist_6_g_slot[2]] <= 1'b1;
      end
      for (int k = 0; k < 16; k++)
        if (freelist_6_free[k]) freelist_6_outstanding[k] <= 1'b0;
    end
  end

  always @(negedge clk) begin
    if (rst) begin
      freelist_6_free = '0; freelist_6_do = '0;
      freelist_6_phase <= 0; freelist_6_phaseCnt <= 0;
    end else begin
      freelist_6_phaseCnt <= freelist_6_phaseCnt + 1;
      if (freelist_6_phaseCnt >= 60) begin
        freelist_6_phaseCnt <= 0; freelist_6_phase <= (freelist_6_phase + 1) % 4;
      end
      freelist_6_nAlloc = 0;
      while (freelist_6_nAlloc < 3 && ((freelist_6_nAlloc == 0 && freelist_6_g_can[0]) || (freelist_6_nAlloc == 1 && freelist_6_g_can[1]) || (freelist_6_nAlloc == 2 && freelist_6_g_can[2]))) freelist_6_nAlloc = freelist_6_nAlloc + 1;
      freelist_6_freeing = '0;
      case (freelist_6_phase)
        // 相位 0：只分配不释放 —— 抽到空，逼 headPtr 绕圈
        0: ;
        // 相位 1：一次性全释放 —— io_free 打满，4 个 bank 满负荷
        1: begin freelist_6_nAlloc = 0; freelist_6_freeing = freelist_6_outstanding; end
        // 相位 2：贴边界来回 —— 分配到满，一满就整批放掉一半
        2: begin
          freelist_6_nAlloc = (freelist_6_nAlloc > 0) ? $urandom_range(0, freelist_6_nAlloc) : 0;
          if (freelist_6_g_u.freeSlotCnt < 5'd2)
            for (int k = 0; k < 16; k += 2)
              if (freelist_6_outstanding[k]) freelist_6_freeing[k] = 1'b1;
        end
        // 相位 3：常规随机混合
        default: begin
          freelist_6_nAlloc = (freelist_6_nAlloc > 0) ? $urandom_range(0, freelist_6_nAlloc) : 0;
          for (int k = 0; k < 16; k++)
            if (freelist_6_outstanding[k] && ($urandom_range(0,99) < 20)) freelist_6_freeing[k] = 1'b1;
        end
      endcase
      // doAllocate 必须是**前缀掩码**：硬件契约是 headPtr 前进 PopCount(doAllocate)
      // 而第 i 口拿的是 freeList[headPtr+i]，跳着占口会让槽位被重复发出。
      freelist_6_do[0] = (freelist_6_nAlloc > 0);
      freelist_6_do[1] = (freelist_6_nAlloc > 1);
      freelist_6_do[2] = (freelist_6_nAlloc > 2);
      freelist_6_free = freelist_6_freeing;
    end
  end

  always @(posedge clk) if (!rst) begin
    int nf, nb;
    if (freelist_6_g_empty) freelist_6_cov_empty++;
    if (freelist_6_g_u.freeSlotCnt == 5'd16) freelist_6_cov_full++;
    if (freelist_6_g_u.headPtr_flag !== freelist_6_prev_hflag) freelist_6_cov_hwrap++;
    if (freelist_6_g_u.tailPtr_flag !== freelist_6_prev_tflag) freelist_6_cov_twrap++;
    freelist_6_prev_hflag <= freelist_6_g_u.headPtr_flag;
    freelist_6_prev_tflag <= freelist_6_g_u.tailPtr_flag;
    nb = freelist_6_g_u.freeReq_next_nextVec_0_r + freelist_6_g_u.freeReq_next_nextVec_1_r + freelist_6_g_u.freeReq_next_nextVec_2_r + freelist_6_g_u.freeReq_next_nextVec_3_r;
    if (nb == 4) freelist_6_cov_allbank++;
    nf = $countones(freelist_6_free);
    if (nf > freelist_6_cov_maxfree) freelist_6_cov_maxfree <= nf;
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("FreeList_6.allocateSlot_0", freelist_6_g_slot[0], freelist_6_i_slot[0])
    `CHK("FreeList_6.allocateSlot_1", freelist_6_g_slot[1], freelist_6_i_slot[1])
    `CHK("FreeList_6.allocateSlot_2", freelist_6_g_slot[2], freelist_6_i_slot[2])
    `CHK("FreeList_6.canAllocate_0", freelist_6_g_can[0], freelist_6_i_can[0])
    `CHK("FreeList_6.canAllocate_1", freelist_6_g_can[1], freelist_6_i_can[1])
    `CHK("FreeList_6.canAllocate_2", freelist_6_g_can[2], freelist_6_i_can[2])
    `CHK("FreeList_6.validCount", freelist_6_g_vc, freelist_6_i_vc)
    `CHK("FreeList_6.empty", freelist_6_g_empty, freelist_6_i_empty)
    if (!$isunknown(freelist_6_g_u.headPtr_flag)) begin
      `CHK("FreeList_6.headPtr.flag",  freelist_6_g_u.headPtr_flag,  freelist_6_i_u.u_core.headPtr.flag)
      `CHK("FreeList_6.headPtr.value", freelist_6_g_u.headPtr_value, freelist_6_i_u.u_core.headPtr.value)
      `CHK("FreeList_6.tailPtr.flag",  freelist_6_g_u.tailPtr_flag,  freelist_6_i_u.u_core.tailPtr.flag)
      `CHK("FreeList_6.tailPtr.value", freelist_6_g_u.tailPtr_value, freelist_6_i_u.u_core.tailPtr.value)
      `CHK("FreeList_6.freeMask",      freelist_6_g_u.freeMask,      freelist_6_i_u.u_core.freeMask)
      `CHK("FreeList_6.freeSlotCnt",   freelist_6_g_u.freeSlotCnt,   freelist_6_i_u.u_core.freeSlotCnt)
      `CHK("FreeList_6.freeReq_0", freelist_6_g_u.freeReq_next_nextVec_0_r, freelist_6_i_u.u_core.freeReqReg[0])
      `CHK("FreeList_6.freeSlotOH_0", freelist_6_g_u.freeSlotOH_next_nextVec_0_r, freelist_6_i_u.u_core.freeSlotOHReg[0])
      `CHK("FreeList_6.freeReq_1", freelist_6_g_u.freeReq_next_nextVec_1_r, freelist_6_i_u.u_core.freeReqReg[1])
      `CHK("FreeList_6.freeSlotOH_1", freelist_6_g_u.freeSlotOH_next_nextVec_1_r, freelist_6_i_u.u_core.freeSlotOHReg[1])
      `CHK("FreeList_6.freeReq_2", freelist_6_g_u.freeReq_next_nextVec_2_r, freelist_6_i_u.u_core.freeReqReg[2])
      `CHK("FreeList_6.freeSlotOH_2", freelist_6_g_u.freeSlotOH_next_nextVec_2_r, freelist_6_i_u.u_core.freeSlotOHReg[2])
      `CHK("FreeList_6.freeReq_3", freelist_6_g_u.freeReq_next_nextVec_3_r, freelist_6_i_u.u_core.freeReqReg[3])
      `CHK("FreeList_6.freeSlotOH_3", freelist_6_g_u.freeSlotOH_next_nextVec_3_r, freelist_6_i_u.u_core.freeSlotOHReg[3])
      `CHK("FreeList_6.freeList[0]", freelist_6_g_u.freeList_0, freelist_6_i_u.u_core.freeList[0])
      `CHK("FreeList_6.freeList[8]", freelist_6_g_u.freeList_8, freelist_6_i_u.u_core.freeList[8])
      `CHK("FreeList_6.freeList[15]", freelist_6_g_u.freeList_15, freelist_6_i_u.u_core.freeList[15])
    end
  end
  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("COV FreeList_1: empty=%0d full=%0d head_wrap=%0d tail_wrap=%0d all1banks=%0d max_free_bits=%0d dup_alloc=%0d",
             freelist_1_cov_empty, freelist_1_cov_full, freelist_1_cov_hwrap, freelist_1_cov_twrap,
             freelist_1_cov_allbank, freelist_1_cov_maxfree, freelist_1_cov_dupalloc);
    $display("COV FreeList_3: empty=%0d full=%0d head_wrap=%0d tail_wrap=%0d all4banks=%0d max_free_bits=%0d dup_alloc=%0d",
             freelist_3_cov_empty, freelist_3_cov_full, freelist_3_cov_hwrap, freelist_3_cov_twrap,
             freelist_3_cov_allbank, freelist_3_cov_maxfree, freelist_3_cov_dupalloc);
    $display("COV FreeList_4: empty=%0d full=%0d head_wrap=%0d tail_wrap=%0d all4banks=%0d max_free_bits=%0d dup_alloc=%0d",
             freelist_4_cov_empty, freelist_4_cov_full, freelist_4_cov_hwrap, freelist_4_cov_twrap,
             freelist_4_cov_allbank, freelist_4_cov_maxfree, freelist_4_cov_dupalloc);
    $display("COV FreeList_6: empty=%0d full=%0d head_wrap=%0d tail_wrap=%0d all4banks=%0d max_free_bits=%0d dup_alloc=%0d",
             freelist_6_cov_empty, freelist_6_cov_full, freelist_6_cov_hwrap, freelist_6_cov_twrap,
             freelist_6_cov_allbank, freelist_6_cov_maxfree, freelist_6_cov_dupalloc);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
