// 自动生成：scripts/gen_freelist.py —— 勿手改

`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_doAllocate_0;
  logic io_doAllocate_1;
  logic [15:0] io_free;
  logic [3:0] g_io_allocateSlot_0;
  logic [3:0] i_io_allocateSlot_0;
  logic [3:0] g_io_allocateSlot_1;
  logic [3:0] i_io_allocateSlot_1;
  logic [4:0] g_io_validCount;
  logic [4:0] i_io_validCount;
  logic g_io_empty;
  logic i_io_empty;

  FreeList g_u (.clock(clk), .reset(rst), .io_doAllocate_0(io_doAllocate_0), .io_doAllocate_1(io_doAllocate_1), .io_free(io_free), .io_allocateSlot_0(g_io_allocateSlot_0), .io_allocateSlot_1(g_io_allocateSlot_1), .io_validCount(g_io_validCount), .io_empty(g_io_empty));
  FreeList_xs i_u (.clock(clk), .reset(rst), .io_doAllocate_0(io_doAllocate_0), .io_doAllocate_1(io_doAllocate_1), .io_free(io_free), .io_allocateSlot_0(i_io_allocateSlot_0), .io_allocateSlot_1(i_io_allocateSlot_1), .io_validCount(i_io_validCount), .io_empty(i_io_empty));


  bit [15:0] outstanding;   // 槽位是否已分配未释放
  bit [15:0] freeing;       // 本拍正在释放的槽位(避免重复释放)
  int occ;                  // 已占用计数
  always @(negedge clk) begin
    if (rst) begin
      io_free <= 16'h0; io_doAllocate_0 <= 1'b0; io_doAllocate_1 <= 1'b0;
      outstanding <= 16'h0; occ <= 0;
    end else begin
      // --- 记账上一拍的分配/释放结果 ---
      // 上一拍 doAllocate 取走的槽位(用 golden 输出)标记为已占用
      if (io_doAllocate_0) begin outstanding[g_io_allocateSlot_0] <= 1'b1; end
      if (io_doAllocate_1) begin outstanding[g_io_allocateSlot_1] <= 1'b1; end
      // 上一拍发出的 io_free 标记为已释放
      for (int k = 0; k < 16; k++) if (io_free[k]) outstanding[k] <= 1'b0;

      // --- 生成本拍激励 ---
      // 分配流控：上游须保证不溢出。这里用 DUT 的 validCount(已占用数)留出余量，
      // 确保任何拍最多分配 2 个时占用不超过 SIZE(留 4 余量覆盖在途释放抖动)。
      io_doAllocate_0 <= (g_io_validCount < 16 - 4) && $urandom_range(0,1);
      io_doAllocate_1 <= (g_io_validCount < 16 - 4) && $urandom_range(0,1);
      // 释放：从已占用槽位里随机挑若干个释放(每个约 25%)，不碰未占用槽位
      freeing = 16'h0;
      for (int k = 0; k < 16; k++)
        if (outstanding[k] && ($urandom_range(0,99) < 25)) freeing[k] = 1'b1;
      io_free <= freeing;
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_allocateSlot_0) && g_io_allocateSlot_0 !== i_io_allocateSlot_0) begin errors++;
      if(errors<=80) $display("[%0t] io_allocateSlot_0 g=%h i=%h", $time, g_io_allocateSlot_0, i_io_allocateSlot_0); end
    if (!$isunknown(g_io_allocateSlot_1) && g_io_allocateSlot_1 !== i_io_allocateSlot_1) begin errors++;
      if(errors<=80) $display("[%0t] io_allocateSlot_1 g=%h i=%h", $time, g_io_allocateSlot_1, i_io_allocateSlot_1); end
    if (!$isunknown(g_io_validCount) && g_io_validCount !== i_io_validCount) begin errors++;
      if(errors<=80) $display("[%0t] io_validCount g=%h i=%h", $time, g_io_validCount, i_io_validCount); end
    if (!$isunknown(g_io_empty) && g_io_empty !== i_io_empty) begin errors++;
      if(errors<=80) $display("[%0t] io_empty g=%h i=%h", $time, g_io_empty, i_io_empty); end

    if (!$isunknown(g_u.headPtr_flag)) begin
      if (g_u.headPtr_flag !== i_u.u_core.headPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] headPtr.flag g=%h i=%h", $time, g_u.headPtr_flag, i_u.u_core.headPtr.flag); end
      if (g_u.headPtr_value !== i_u.u_core.headPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] headPtr.value g=%h i=%h", $time, g_u.headPtr_value, i_u.u_core.headPtr.value); end
      if (g_u.tailPtr_flag !== i_u.u_core.tailPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] tailPtr.flag g=%h i=%h", $time, g_u.tailPtr_flag, i_u.u_core.tailPtr.flag); end
      if (g_u.tailPtr_value !== i_u.u_core.tailPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] tailPtr.value g=%h i=%h", $time, g_u.tailPtr_value, i_u.u_core.tailPtr.value); end
      if (g_u.freeMask !== i_u.u_core.freeMask) begin errors++;
        if(errors<=80) $display("[%0t] freeMask g=%h i=%h", $time, g_u.freeMask, i_u.u_core.freeMask); end
      if (g_u.freeSlotCnt !== i_u.u_core.freeSlotCnt) begin errors++;
        if(errors<=80) $display("[%0t] freeSlotCnt g=%h i=%h", $time, g_u.freeSlotCnt, i_u.u_core.freeSlotCnt); end
    end

  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule