// =============================================================================
// FtqPcMemWrapper UT testbench
//
// 双例化逐拍比对：
//   golden = SyncDataModuleTemplate_FtqPC_64entry（FtqPcMemWrapper 内部唯一子模块，
//            wrapper 本身只是端口改名 + raddr 映射，无逻辑，故直接拿子模块当 golden
//            参考，避免与手写同名 FtqPcMemWrapper 的模块名冲突）
//   impl   = FtqPcMemWrapper（手写，golden 同名扁平端口包装可读核 xs_FtqPcMemWrapper）
//
// 激励：每拍随机 7 个读地址 + 随机写（使能/地址/数据），逐拍比对全部读出字段。
// 读延迟 1 拍 + 写旁路，golden/impl 同时序，直接同拍比对即可。
//
// 端口映射对应关系（impl 的 FTQ 指针名 -> golden 的 raddr 下标）：
//   ifuPtr->0  ifuPtrPlus1->1  ifuPtrPlus2->2  pfPtr->3  pfPtrPlus1->4
//   commPtr->6  commPtrPlus1->5   （注意 comm 两口的 5/6 次序）
// =============================================================================
`timescale 1ns/1ps
module tb;
  logic clk = 0;
  logic rst = 1;
  int   errors = 0, checks = 0;

  always #5 clk = ~clk;

  // ---- 共享激励 ----
  logic [5:0]  ifuPtr, ifuPtrPlus1, ifuPtrPlus2, pfPtr, pfPtrPlus1, commPtr, commPtrPlus1;
  logic        wen;
  logic [5:0]  waddr;
  logic [49:0] wdata_startAddr, wdata_nextLineAddr;
  logic        wdata_fallThruError;

  // ---- golden 读出（子模块端口：raddr_0..6 / rdata_*）----
  wire [49:0] g_r0_start, g_r0_next;  wire g_r0_fte;
  wire [49:0] g_r1_start, g_r1_next;  wire g_r1_fte;
  wire [49:0] g_r2_start;
  wire [49:0] g_r3_start, g_r3_next;
  wire [49:0] g_r4_start, g_r4_next;
  wire [49:0] g_r5_start;
  wire [49:0] g_r6_start;

  // ---- impl 读出（FtqPcMemWrapper 扁平端口）----
  wire [49:0] i_ifu_start, i_ifu_next;       wire i_ifu_fte;
  wire [49:0] i_ifup1_start, i_ifup1_next;   wire i_ifup1_fte;
  wire [49:0] i_ifup2_start;
  wire [49:0] i_pf_start, i_pf_next;
  wire [49:0] i_pfp1_start, i_pfp1_next;
  wire [49:0] i_commp1_start;
  wire [49:0] i_comm_start;

  // golden 参考：FtqPcMemWrapper 的内部子模块
  //   raddr_5 <- commPtrPlus1, raddr_6 <- commPtr  （见 golden wrapper 例化）
  SyncDataModuleTemplate_FtqPC_64entry u_golden (
    .clock(clk), .reset(rst),
    .io_raddr_0(ifuPtr), .io_raddr_1(ifuPtrPlus1), .io_raddr_2(ifuPtrPlus2),
    .io_raddr_3(pfPtr),  .io_raddr_4(pfPtrPlus1),
    .io_raddr_5(commPtrPlus1), .io_raddr_6(commPtr),
    .io_rdata_0_startAddr(g_r0_start), .io_rdata_0_nextLineAddr(g_r0_next), .io_rdata_0_fallThruError(g_r0_fte),
    .io_rdata_1_startAddr(g_r1_start), .io_rdata_1_nextLineAddr(g_r1_next), .io_rdata_1_fallThruError(g_r1_fte),
    .io_rdata_2_startAddr(g_r2_start),
    .io_rdata_3_startAddr(g_r3_start), .io_rdata_3_nextLineAddr(g_r3_next),
    .io_rdata_4_startAddr(g_r4_start), .io_rdata_4_nextLineAddr(g_r4_next),
    .io_rdata_5_startAddr(g_r5_start),
    .io_rdata_6_startAddr(g_r6_start),
    .io_wen_0(wen), .io_waddr_0(waddr),
    .io_wdata_0_startAddr(wdata_startAddr), .io_wdata_0_nextLineAddr(wdata_nextLineAddr),
    .io_wdata_0_fallThruError(wdata_fallThruError)
  );

  FtqPcMemWrapper u_impl (
    .clock(clk), .reset(rst),
    .io_ifuPtr_w_value(ifuPtr), .io_ifuPtrPlus1_w_value(ifuPtrPlus1), .io_ifuPtrPlus2_w_value(ifuPtrPlus2),
    .io_pfPtr_w_value(pfPtr),   .io_pfPtrPlus1_w_value(pfPtrPlus1),
    .io_commPtr_w_value(commPtr), .io_commPtrPlus1_w_value(commPtrPlus1),
    .io_ifuPtr_rdata_startAddr(i_ifu_start), .io_ifuPtr_rdata_nextLineAddr(i_ifu_next), .io_ifuPtr_rdata_fallThruError(i_ifu_fte),
    .io_ifuPtrPlus1_rdata_startAddr(i_ifup1_start), .io_ifuPtrPlus1_rdata_nextLineAddr(i_ifup1_next), .io_ifuPtrPlus1_rdata_fallThruError(i_ifup1_fte),
    .io_ifuPtrPlus2_rdata_startAddr(i_ifup2_start),
    .io_pfPtr_rdata_startAddr(i_pf_start), .io_pfPtr_rdata_nextLineAddr(i_pf_next),
    .io_pfPtrPlus1_rdata_startAddr(i_pfp1_start), .io_pfPtrPlus1_rdata_nextLineAddr(i_pfp1_next),
    .io_commPtr_rdata_startAddr(i_comm_start),
    .io_commPtrPlus1_rdata_startAddr(i_commp1_start),
    .io_wen(wen), .io_waddr(waddr),
    .io_wdata_startAddr(wdata_startAddr), .io_wdata_nextLineAddr(wdata_nextLineAddr),
    .io_wdata_fallThruError(wdata_fallThruError)
  );

  task automatic drive;
    ifuPtr              = 6'($urandom);
    ifuPtrPlus1         = 6'($urandom);
    ifuPtrPlus2         = 6'($urandom);
    pfPtr               = 6'($urandom);
    pfPtrPlus1          = 6'($urandom);
    commPtr             = 6'($urandom);
    commPtrPlus1        = 6'($urandom);
    wen                 = 1'($urandom);
    waddr               = 6'($urandom);
    wdata_startAddr     = {18'($urandom), 32'($urandom)};
    wdata_nextLineAddr  = {18'($urandom), 32'($urandom)};
    wdata_fallThruError = 1'($urandom);
  endtask

  task automatic check;
    // port0 ifuPtr：全字段
    if (i_ifu_start !== g_r0_start) begin errors++; $display("[%0t] ifuPtr.startAddr g=%h i=%h", $time, g_r0_start, i_ifu_start); end
    checks++;
    if (i_ifu_next !== g_r0_next) begin errors++; $display("[%0t] ifuPtr.nextLineAddr g=%h i=%h", $time, g_r0_next, i_ifu_next); end
    checks++;
    if (i_ifu_fte !== g_r0_fte) begin errors++; $display("[%0t] ifuPtr.fallThruError g=%b i=%b", $time, g_r0_fte, i_ifu_fte); end
    checks++;
    // port1 ifuPtrPlus1：全字段
    if (i_ifup1_start !== g_r1_start) begin errors++; $display("[%0t] ifuPtrPlus1.startAddr g=%h i=%h", $time, g_r1_start, i_ifup1_start); end
    checks++;
    if (i_ifup1_next !== g_r1_next) begin errors++; $display("[%0t] ifuPtrPlus1.nextLineAddr g=%h i=%h", $time, g_r1_next, i_ifup1_next); end
    checks++;
    if (i_ifup1_fte !== g_r1_fte) begin errors++; $display("[%0t] ifuPtrPlus1.fallThruError g=%b i=%b", $time, g_r1_fte, i_ifup1_fte); end
    checks++;
    // port2 ifuPtrPlus2
    if (i_ifup2_start !== g_r2_start) begin errors++; $display("[%0t] ifuPtrPlus2.startAddr g=%h i=%h", $time, g_r2_start, i_ifup2_start); end
    checks++;
    // port3 pfPtr
    if (i_pf_start !== g_r3_start) begin errors++; $display("[%0t] pfPtr.startAddr g=%h i=%h", $time, g_r3_start, i_pf_start); end
    checks++;
    if (i_pf_next !== g_r3_next) begin errors++; $display("[%0t] pfPtr.nextLineAddr g=%h i=%h", $time, g_r3_next, i_pf_next); end
    checks++;
    // port4 pfPtrPlus1
    if (i_pfp1_start !== g_r4_start) begin errors++; $display("[%0t] pfPtrPlus1.startAddr g=%h i=%h", $time, g_r4_start, i_pfp1_start); end
    checks++;
    if (i_pfp1_next !== g_r4_next) begin errors++; $display("[%0t] pfPtrPlus1.nextLineAddr g=%h i=%h", $time, g_r4_next, i_pfp1_next); end
    checks++;
    // port5 commPtrPlus1 (golden raddr_5)
    if (i_commp1_start !== g_r5_start) begin errors++; $display("[%0t] commPtrPlus1.startAddr g=%h i=%h", $time, g_r5_start, i_commp1_start); end
    checks++;
    // port6 commPtr (golden raddr_6)
    if (i_comm_start !== g_r6_start) begin errors++; $display("[%0t] commPtr.startAddr g=%h i=%h", $time, g_r6_start, i_comm_start); end
    checks++;
  endtask

  int unsigned N = 4000;
  initial begin
    drive(); wen = 0;
    repeat (3) @(posedge clk);
    rst = 0;
    @(posedge clk);
    for (int unsigned n = 0; n < N; n++) begin
      drive();
      @(posedge clk);   // 锁存激励，读地址打一拍
      #1 check();       // 在时钟沿后稍待，比较本拍读出
    end
    $display("==== FtqPcMemWrapper UT done: checks=%0d errors=%0d ====", checks, errors);
    if (errors == 0) $display("TEST PASSED");
    else             $display("TEST FAILED");
    $finish;
  end
endmodule
