// 自动生成：scripts/gen_stdfreelist.py —— 勿手改

`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_redirect;
  logic io_walk;
  logic io_allocateReq_0;
  logic io_allocateReq_1;
  logic io_allocateReq_2;
  logic io_allocateReq_3;
  logic io_allocateReq_4;
  logic io_allocateReq_5;
  logic io_walkReq_0;
  logic io_walkReq_1;
  logic io_walkReq_2;
  logic io_walkReq_3;
  logic io_walkReq_4;
  logic io_walkReq_5;
  logic io_doAllocate;
  logic io_freeReq_0;
  logic io_freeReq_1;
  logic io_freeReq_2;
  logic io_freeReq_3;
  logic io_freeReq_4;
  logic io_freeReq_5;
  logic [7:0] io_freePhyReg_0;
  logic [7:0] io_freePhyReg_1;
  logic [7:0] io_freePhyReg_2;
  logic [7:0] io_freePhyReg_3;
  logic [7:0] io_freePhyReg_4;
  logic [7:0] io_freePhyReg_5;
  logic io_commit_isCommit;
  logic io_commit_commitValid_0;
  logic io_commit_commitValid_1;
  logic io_commit_commitValid_2;
  logic io_commit_commitValid_3;
  logic io_commit_commitValid_4;
  logic io_commit_commitValid_5;
  logic io_commit_info_0_fpWen;
  logic io_commit_info_1_fpWen;
  logic io_commit_info_2_fpWen;
  logic io_commit_info_3_fpWen;
  logic io_commit_info_4_fpWen;
  logic io_commit_info_5_fpWen;
  logic io_snpt_snptEnq;
  logic io_snpt_snptDeq;
  logic io_snpt_useSnpt;
  logic [1:0] io_snpt_snptSelect;
  logic io_snpt_flushVec_0;
  logic io_snpt_flushVec_1;
  logic io_snpt_flushVec_2;
  logic io_snpt_flushVec_3;
  logic [7:0] g_io_allocatePhyReg_0;
  logic [7:0] i_io_allocatePhyReg_0;
  logic [7:0] g_io_allocatePhyReg_1;
  logic [7:0] i_io_allocatePhyReg_1;
  logic [7:0] g_io_allocatePhyReg_2;
  logic [7:0] i_io_allocatePhyReg_2;
  logic [7:0] g_io_allocatePhyReg_3;
  logic [7:0] i_io_allocatePhyReg_3;
  logic [7:0] g_io_allocatePhyReg_4;
  logic [7:0] i_io_allocatePhyReg_4;
  logic [7:0] g_io_allocatePhyReg_5;
  logic [7:0] i_io_allocatePhyReg_5;
  logic g_io_canAllocate;
  logic i_io_canAllocate;
  logic [5:0] g_io_perf_0_value;
  logic [5:0] i_io_perf_0_value;
  logic [5:0] g_io_perf_1_value;
  logic [5:0] i_io_perf_1_value;
  logic [5:0] g_io_perf_2_value;
  logic [5:0] i_io_perf_2_value;
  logic [5:0] g_io_perf_3_value;
  logic [5:0] i_io_perf_3_value;

  StdFreeList g_u (.clock(clk), .reset(rst), .io_redirect(io_redirect), .io_walk(io_walk), .io_allocateReq_0(io_allocateReq_0), .io_allocateReq_1(io_allocateReq_1), .io_allocateReq_2(io_allocateReq_2), .io_allocateReq_3(io_allocateReq_3), .io_allocateReq_4(io_allocateReq_4), .io_allocateReq_5(io_allocateReq_5), .io_walkReq_0(io_walkReq_0), .io_walkReq_1(io_walkReq_1), .io_walkReq_2(io_walkReq_2), .io_walkReq_3(io_walkReq_3), .io_walkReq_4(io_walkReq_4), .io_walkReq_5(io_walkReq_5), .io_doAllocate(io_doAllocate), .io_freeReq_0(io_freeReq_0), .io_freeReq_1(io_freeReq_1), .io_freeReq_2(io_freeReq_2), .io_freeReq_3(io_freeReq_3), .io_freeReq_4(io_freeReq_4), .io_freeReq_5(io_freeReq_5), .io_freePhyReg_0(io_freePhyReg_0), .io_freePhyReg_1(io_freePhyReg_1), .io_freePhyReg_2(io_freePhyReg_2), .io_freePhyReg_3(io_freePhyReg_3), .io_freePhyReg_4(io_freePhyReg_4), .io_freePhyReg_5(io_freePhyReg_5), .io_commit_isCommit(io_commit_isCommit), .io_commit_commitValid_0(io_commit_commitValid_0), .io_commit_commitValid_1(io_commit_commitValid_1), .io_commit_commitValid_2(io_commit_commitValid_2), .io_commit_commitValid_3(io_commit_commitValid_3), .io_commit_commitValid_4(io_commit_commitValid_4), .io_commit_commitValid_5(io_commit_commitValid_5), .io_commit_info_0_fpWen(io_commit_info_0_fpWen), .io_commit_info_1_fpWen(io_commit_info_1_fpWen), .io_commit_info_2_fpWen(io_commit_info_2_fpWen), .io_commit_info_3_fpWen(io_commit_info_3_fpWen), .io_commit_info_4_fpWen(io_commit_info_4_fpWen), .io_commit_info_5_fpWen(io_commit_info_5_fpWen), .io_snpt_snptEnq(io_snpt_snptEnq), .io_snpt_snptDeq(io_snpt_snptDeq), .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect), .io_snpt_flushVec_0(io_snpt_flushVec_0), .io_snpt_flushVec_1(io_snpt_flushVec_1), .io_snpt_flushVec_2(io_snpt_flushVec_2), .io_snpt_flushVec_3(io_snpt_flushVec_3), .io_allocatePhyReg_0(g_io_allocatePhyReg_0), .io_allocatePhyReg_1(g_io_allocatePhyReg_1), .io_allocatePhyReg_2(g_io_allocatePhyReg_2), .io_allocatePhyReg_3(g_io_allocatePhyReg_3), .io_allocatePhyReg_4(g_io_allocatePhyReg_4), .io_allocatePhyReg_5(g_io_allocatePhyReg_5), .io_canAllocate(g_io_canAllocate), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value));
  StdFreeList_xs i_u (.clock(clk), .reset(rst), .io_redirect(io_redirect), .io_walk(io_walk), .io_allocateReq_0(io_allocateReq_0), .io_allocateReq_1(io_allocateReq_1), .io_allocateReq_2(io_allocateReq_2), .io_allocateReq_3(io_allocateReq_3), .io_allocateReq_4(io_allocateReq_4), .io_allocateReq_5(io_allocateReq_5), .io_walkReq_0(io_walkReq_0), .io_walkReq_1(io_walkReq_1), .io_walkReq_2(io_walkReq_2), .io_walkReq_3(io_walkReq_3), .io_walkReq_4(io_walkReq_4), .io_walkReq_5(io_walkReq_5), .io_doAllocate(io_doAllocate), .io_freeReq_0(io_freeReq_0), .io_freeReq_1(io_freeReq_1), .io_freeReq_2(io_freeReq_2), .io_freeReq_3(io_freeReq_3), .io_freeReq_4(io_freeReq_4), .io_freeReq_5(io_freeReq_5), .io_freePhyReg_0(io_freePhyReg_0), .io_freePhyReg_1(io_freePhyReg_1), .io_freePhyReg_2(io_freePhyReg_2), .io_freePhyReg_3(io_freePhyReg_3), .io_freePhyReg_4(io_freePhyReg_4), .io_freePhyReg_5(io_freePhyReg_5), .io_commit_isCommit(io_commit_isCommit), .io_commit_commitValid_0(io_commit_commitValid_0), .io_commit_commitValid_1(io_commit_commitValid_1), .io_commit_commitValid_2(io_commit_commitValid_2), .io_commit_commitValid_3(io_commit_commitValid_3), .io_commit_commitValid_4(io_commit_commitValid_4), .io_commit_commitValid_5(io_commit_commitValid_5), .io_commit_info_0_fpWen(io_commit_info_0_fpWen), .io_commit_info_1_fpWen(io_commit_info_1_fpWen), .io_commit_info_2_fpWen(io_commit_info_2_fpWen), .io_commit_info_3_fpWen(io_commit_info_3_fpWen), .io_commit_info_4_fpWen(io_commit_info_4_fpWen), .io_commit_info_5_fpWen(io_commit_info_5_fpWen), .io_snpt_snptEnq(io_snpt_snptEnq), .io_snpt_snptDeq(io_snpt_snptDeq), .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect), .io_snpt_flushVec_0(io_snpt_flushVec_0), .io_snpt_flushVec_1(io_snpt_flushVec_1), .io_snpt_flushVec_2(io_snpt_flushVec_2), .io_snpt_flushVec_3(io_snpt_flushVec_3), .io_allocatePhyReg_0(i_io_allocatePhyReg_0), .io_allocatePhyReg_1(i_io_allocatePhyReg_1), .io_allocatePhyReg_2(i_io_allocatePhyReg_2), .io_allocatePhyReg_3(i_io_allocatePhyReg_3), .io_allocatePhyReg_4(i_io_allocatePhyReg_4), .io_allocatePhyReg_5(i_io_allocatePhyReg_5), .io_canAllocate(i_io_canAllocate), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value));


  // free 用的物理寄存器号池(34..191)。回收时回灌已分配过的号，避免重复。
  function automatic logic [7:0] rnd_preg(); return 8'(34 + $urandom_range(0,157)); endfunction
  always @(negedge clk) begin
    if (rst) begin
      io_redirect<=0; io_walk<=0; io_doAllocate<=0;
      {io_allocateReq_5,io_allocateReq_4,io_allocateReq_3,io_allocateReq_2,io_allocateReq_1,io_allocateReq_0}<=0;
      {io_walkReq_5,io_walkReq_4,io_walkReq_3,io_walkReq_2,io_walkReq_1,io_walkReq_0}<=0;
      {io_freeReq_5,io_freeReq_4,io_freeReq_3,io_freeReq_2,io_freeReq_1,io_freeReq_0}<=0;
      io_commit_isCommit<=0;
      {io_commit_commitValid_5,io_commit_commitValid_4,io_commit_commitValid_3,io_commit_commitValid_2,io_commit_commitValid_1,io_commit_commitValid_0}<=0;
      {io_commit_info_5_fpWen,io_commit_info_4_fpWen,io_commit_info_3_fpWen,io_commit_info_2_fpWen,io_commit_info_1_fpWen,io_commit_info_0_fpWen}<=0;
      io_snpt_snptEnq<=0; io_snpt_snptDeq<=0; io_snpt_useSnpt<=0; io_snpt_snptSelect<=0;
      {io_snpt_flushVec_3,io_snpt_flushVec_2,io_snpt_flushVec_1,io_snpt_flushVec_0}<=0;
    end else begin
      // redirect 偶发(约 3%)，并伴随一段 walk
      io_redirect <= ($urandom_range(0,99) < 3);
      io_walk     <= ($urandom_range(0,99) < 25);
      io_doAllocate <= $urandom_range(0,1);
      io_allocateReq_0<=$urandom_range(0,1); io_allocateReq_1<=$urandom_range(0,1);
      io_allocateReq_2<=$urandom_range(0,1); io_allocateReq_3<=$urandom_range(0,1);
      io_allocateReq_4<=$urandom_range(0,1); io_allocateReq_5<=$urandom_range(0,1);
      io_walkReq_0<=$urandom_range(0,1); io_walkReq_1<=$urandom_range(0,1);
      io_walkReq_2<=$urandom_range(0,1); io_walkReq_3<=$urandom_range(0,1);
      io_walkReq_4<=$urandom_range(0,1); io_walkReq_5<=$urandom_range(0,1);
      // free 较稀疏(约 30% 每口)，回收随机物理号
      io_freeReq_0<=($urandom_range(0,99)<30); io_freeReq_1<=($urandom_range(0,99)<30);
      io_freeReq_2<=($urandom_range(0,99)<30); io_freeReq_3<=($urandom_range(0,99)<30);
      io_freeReq_4<=($urandom_range(0,99)<30); io_freeReq_5<=($urandom_range(0,99)<30);
      io_freePhyReg_0<=rnd_preg(); io_freePhyReg_1<=rnd_preg(); io_freePhyReg_2<=rnd_preg();
      io_freePhyReg_3<=rnd_preg(); io_freePhyReg_4<=rnd_preg(); io_freePhyReg_5<=rnd_preg();
      io_commit_isCommit<=$urandom_range(0,1);
      io_commit_commitValid_0<=$urandom_range(0,1); io_commit_commitValid_1<=$urandom_range(0,1);
      io_commit_commitValid_2<=$urandom_range(0,1); io_commit_commitValid_3<=$urandom_range(0,1);
      io_commit_commitValid_4<=$urandom_range(0,1); io_commit_commitValid_5<=$urandom_range(0,1);
      io_commit_info_0_fpWen<=$urandom_range(0,1); io_commit_info_1_fpWen<=$urandom_range(0,1);
      io_commit_info_2_fpWen<=$urandom_range(0,1); io_commit_info_3_fpWen<=$urandom_range(0,1);
      io_commit_info_4_fpWen<=$urandom_range(0,1); io_commit_info_5_fpWen<=$urandom_range(0,1);
      io_snpt_snptEnq<=($urandom_range(0,99)<15); io_snpt_snptDeq<=($urandom_range(0,99)<15);
      io_snpt_useSnpt<=$urandom_range(0,1); io_snpt_snptSelect<=$urandom_range(0,3);
      io_snpt_flushVec_0<=($urandom_range(0,99)<5); io_snpt_flushVec_1<=($urandom_range(0,99)<5);
      io_snpt_flushVec_2<=($urandom_range(0,99)<5); io_snpt_flushVec_3<=($urandom_range(0,99)<5);
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_allocatePhyReg_0) && g_io_allocatePhyReg_0 !== i_io_allocatePhyReg_0) begin errors++;
      if(errors<=80) $display("[%0t] io_allocatePhyReg_0 g=%h i=%h", $time, g_io_allocatePhyReg_0, i_io_allocatePhyReg_0); end
    if (!$isunknown(g_io_allocatePhyReg_1) && g_io_allocatePhyReg_1 !== i_io_allocatePhyReg_1) begin errors++;
      if(errors<=80) $display("[%0t] io_allocatePhyReg_1 g=%h i=%h", $time, g_io_allocatePhyReg_1, i_io_allocatePhyReg_1); end
    if (!$isunknown(g_io_allocatePhyReg_2) && g_io_allocatePhyReg_2 !== i_io_allocatePhyReg_2) begin errors++;
      if(errors<=80) $display("[%0t] io_allocatePhyReg_2 g=%h i=%h", $time, g_io_allocatePhyReg_2, i_io_allocatePhyReg_2); end
    if (!$isunknown(g_io_allocatePhyReg_3) && g_io_allocatePhyReg_3 !== i_io_allocatePhyReg_3) begin errors++;
      if(errors<=80) $display("[%0t] io_allocatePhyReg_3 g=%h i=%h", $time, g_io_allocatePhyReg_3, i_io_allocatePhyReg_3); end
    if (!$isunknown(g_io_allocatePhyReg_4) && g_io_allocatePhyReg_4 !== i_io_allocatePhyReg_4) begin errors++;
      if(errors<=80) $display("[%0t] io_allocatePhyReg_4 g=%h i=%h", $time, g_io_allocatePhyReg_4, i_io_allocatePhyReg_4); end
    if (!$isunknown(g_io_allocatePhyReg_5) && g_io_allocatePhyReg_5 !== i_io_allocatePhyReg_5) begin errors++;
      if(errors<=80) $display("[%0t] io_allocatePhyReg_5 g=%h i=%h", $time, g_io_allocatePhyReg_5, i_io_allocatePhyReg_5); end
    if (!$isunknown(g_io_canAllocate) && g_io_canAllocate !== i_io_canAllocate) begin errors++;
      if(errors<=80) $display("[%0t] io_canAllocate g=%h i=%h", $time, g_io_canAllocate, i_io_canAllocate); end
    if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
    if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
    if (!$isunknown(g_io_perf_2_value) && g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end
    if (!$isunknown(g_io_perf_3_value) && g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end

    if (!$isunknown(g_u.headPtr_flag)) begin
      if (g_u.headPtr_flag !== i_u.u_core.headPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] headPtr.flag g=%h i=%h", $time, g_u.headPtr_flag, i_u.u_core.headPtr.flag); end
      if (g_u.shiftAmount !== i_u.u_core.headPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] headPtr.value g=%h i=%h", $time, g_u.shiftAmount, i_u.u_core.headPtr.value); end
    end
    if (!$isunknown(g_u.archHeadPtr_flag)) begin
      if (g_u.archHeadPtr_flag !== i_u.u_core.archHeadPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] archHeadPtr.flag g=%h i=%h", $time, g_u.archHeadPtr_flag, i_u.u_core.archHeadPtr.flag); end
      if (g_u.archHeadPtr_value !== i_u.u_core.archHeadPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] archHeadPtr.value g=%h i=%h", $time, g_u.archHeadPtr_value, i_u.u_core.archHeadPtr.value); end
    end
    if (!$isunknown(g_u.lastTailPtr_flag)) begin
      if (g_u.lastTailPtr_flag !== i_u.u_core.lastTailPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] lastTailPtr.flag g=%h i=%h", $time, g_u.lastTailPtr_flag, i_u.u_core.lastTailPtr.flag); end
      if (g_u.lastTailPtr_value !== i_u.u_core.lastTailPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] lastTailPtr.value g=%h i=%h", $time, g_u.lastTailPtr_value, i_u.u_core.lastTailPtr.value); end
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