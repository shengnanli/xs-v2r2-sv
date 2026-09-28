// GPAMem UT —— golden GPAMem 与重写 GPAMem_xs 双例化同激励逐拍比对
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cyc = 0;
  always #5 clk = ~clk;
  always @(negedge clk) if (!rst) cyc <= cyc + 1;

  // ★暖机窗口★：表里 64 项与 ftqOffset/地址复制寄存器全部无复位，两侧独立例化在
  // +vcs+initreg+random 下各抽各的上电值。前 64 拍顺序把 64 项全部写一遍，同时每拍
  // 都发读（把 raddr_dup/ftqOffset 写定），之后才开比对窗口。这是契约（只读写过的
  // 项），不是 RTL 差异。
  localparam int WARM = 80;

  logic        wen;
  logic [5:0]  waddr;
  logic [55:0] wgpaddr;
  logic        wnonleaf;
  logic        rvalid;
  logic [5:0]  rptr;
  logic [3:0]  roff;
  logic [55:0] g_gpaddr, i_gpaddr;
  logic        g_nonleaf, i_nonleaf;

  GPAMem g_u (.clock(clk), .reset(rst),
    .io_fromIFU_gpaddrMem_wen(wen), .io_fromIFU_gpaddrMem_waddr(waddr),
    .io_fromIFU_gpaddrMem_wdata_gpaddr(wgpaddr), .io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE(wnonleaf),
    .io_exceptionReadAddr_valid(rvalid), .io_exceptionReadAddr_bits_ftqPtr_value(rptr),
    .io_exceptionReadAddr_bits_ftqOffset(roff),
    .io_exceptionReadData_gpaddr(g_gpaddr), .io_exceptionReadData_isForVSnonLeafPTE(g_nonleaf));
  GPAMem_xs i_u (.clock(clk), .reset(rst),
    .io_fromIFU_gpaddrMem_wen(wen), .io_fromIFU_gpaddrMem_waddr(waddr),
    .io_fromIFU_gpaddrMem_wdata_gpaddr(wgpaddr), .io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE(wnonleaf),
    .io_exceptionReadAddr_valid(rvalid), .io_exceptionReadAddr_bits_ftqPtr_value(rptr),
    .io_exceptionReadAddr_bits_ftqOffset(roff),
    .io_exceptionReadData_gpaddr(i_gpaddr), .io_exceptionReadData_isForVSnonLeafPTE(i_nonleaf));

  always @(negedge clk) begin
    if (rst) begin
      wen <= 0; waddr <= 0; wgpaddr <= 0; wnonleaf <= 0; rvalid <= 0; rptr <= 0; roff <= 0;
    end else if (cyc < 64) begin
      wen <= 1'b1; waddr <= 6'(cyc); wgpaddr <= {$urandom(), $urandom()}; wnonleaf <= $urandom_range(0,1);
      rvalid <= 1'b1; rptr <= 6'(cyc); roff <= 4'($urandom);
    end else begin
      wen <= ($urandom_range(0,99) < 60); waddr <= 6'($urandom);
      wgpaddr <= {$urandom(), $urandom()}; wnonleaf <= $urandom_range(0,1);
      rvalid <= ($urandom_range(0,99) < 50); rptr <= 6'($urandom); roff <= 4'($urandom);
    end
  end

  always @(negedge clk) if (!rst && cyc > WARM) begin
    #4; checks++;
    if (g_gpaddr !== i_gpaddr) begin errors++;
      if (errors <= 40) $display("[%0t] gpaddr g=%h i=%h", $time, g_gpaddr, i_gpaddr); end
    if (g_nonleaf !== i_nonleaf) begin errors++;
      if (errors <= 40) $display("[%0t] isForVSnonLeafPTE g=%h i=%h", $time, g_nonleaf, i_nonleaf); end
  end

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
