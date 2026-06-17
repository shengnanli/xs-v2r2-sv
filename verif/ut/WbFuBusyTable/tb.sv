// 自动生成：scripts/gen_wbfubusytable.py —— 勿手改
// WbFuBusyTable UT: golden(u_g) vs 可读核 wrapper WbFuBusyTable_xs(u_i)。
// 模块纯组合, 每拍随机驱动全部输入(各源忙表位图), 组合稳定后比对全部输出。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic [2:0] io_in_intSchdBusyTable_2_1_fpWbBusyTable;
  logic [2:0] io_in_intSchdBusyTable_1_0_intWbBusyTable;
  logic [2:0] io_in_intSchdBusyTable_0_0_intWbBusyTable;
  logic [1:0] io_in_fpSchdBusyTable_2_0_intWbBusyTable;
  logic [3:0] io_in_fpSchdBusyTable_2_0_fpWbBusyTable;
  logic [1:0] io_in_fpSchdBusyTable_1_0_intWbBusyTable;
  logic [3:0] io_in_fpSchdBusyTable_1_0_fpWbBusyTable;
  logic [2:0] io_in_fpSchdBusyTable_0_0_intWbBusyTable;
  logic [3:0] io_in_fpSchdBusyTable_0_0_fpWbBusyTable;
  logic [2:0] io_in_vfSchdBusyTable_1_1_fpWbBusyTable;
  logic [2:0] io_in_vfSchdBusyTable_1_1_vfWbBusyTable;
  logic [2:0] io_in_vfSchdBusyTable_1_1_v0WbBusyTable;
  logic [4:0] io_in_vfSchdBusyTable_1_0_vfWbBusyTable;
  logic [4:0] io_in_vfSchdBusyTable_1_0_v0WbBusyTable;
  logic [4:0] io_in_vfSchdBusyTable_0_1_intWbBusyTable;
  logic [2:0] io_in_vfSchdBusyTable_0_1_fpWbBusyTable;
  logic [3:0] io_in_vfSchdBusyTable_0_1_vfWbBusyTable;
  logic [3:0] io_in_vfSchdBusyTable_0_1_v0WbBusyTable;
  logic [1:0] io_in_vfSchdBusyTable_0_1_vlWbBusyTable;
  logic [4:0] io_in_vfSchdBusyTable_0_0_vfWbBusyTable;
  logic [4:0] io_in_vfSchdBusyTable_0_0_v0WbBusyTable;
  wire [2:0] g_io_out_intRespRead_2_1_fpWbBusyTable;
  wire [2:0] i_io_out_intRespRead_2_1_fpWbBusyTable;
  wire g_io_out_intRespRead_2_1_vfWbBusyTable;
  wire i_io_out_intRespRead_2_1_vfWbBusyTable;
  wire g_io_out_intRespRead_2_1_v0WbBusyTable;
  wire i_io_out_intRespRead_2_1_v0WbBusyTable;
  wire g_io_out_intRespRead_2_0_intWbBusyTable;
  wire i_io_out_intRespRead_2_0_intWbBusyTable;
  wire g_io_out_intRespRead_1_1_intWbBusyTable;
  wire i_io_out_intRespRead_1_1_intWbBusyTable;
  wire [2:0] g_io_out_intRespRead_1_0_intWbBusyTable;
  wire [2:0] i_io_out_intRespRead_1_0_intWbBusyTable;
  wire g_io_out_intRespRead_0_1_intWbBusyTable;
  wire i_io_out_intRespRead_0_1_intWbBusyTable;
  wire [2:0] g_io_out_intRespRead_0_0_intWbBusyTable;
  wire [2:0] i_io_out_intRespRead_0_0_intWbBusyTable;
  wire [1:0] g_io_out_fpRespRead_2_0_intWbBusyTable;
  wire [1:0] i_io_out_fpRespRead_2_0_intWbBusyTable;
  wire [3:0] g_io_out_fpRespRead_2_0_fpWbBusyTable;
  wire [3:0] i_io_out_fpRespRead_2_0_fpWbBusyTable;
  wire [1:0] g_io_out_fpRespRead_1_0_intWbBusyTable;
  wire [1:0] i_io_out_fpRespRead_1_0_intWbBusyTable;
  wire [3:0] g_io_out_fpRespRead_1_0_fpWbBusyTable;
  wire [3:0] i_io_out_fpRespRead_1_0_fpWbBusyTable;
  wire [2:0] g_io_out_fpRespRead_0_0_intWbBusyTable;
  wire [2:0] i_io_out_fpRespRead_0_0_intWbBusyTable;
  wire [3:0] g_io_out_fpRespRead_0_0_fpWbBusyTable;
  wire [3:0] i_io_out_fpRespRead_0_0_fpWbBusyTable;
  wire [2:0] g_io_out_vfRespRead_1_1_fpWbBusyTable;
  wire [2:0] i_io_out_vfRespRead_1_1_fpWbBusyTable;
  wire [2:0] g_io_out_vfRespRead_1_1_vfWbBusyTable;
  wire [2:0] i_io_out_vfRespRead_1_1_vfWbBusyTable;
  wire [2:0] g_io_out_vfRespRead_1_1_v0WbBusyTable;
  wire [2:0] i_io_out_vfRespRead_1_1_v0WbBusyTable;
  wire [4:0] g_io_out_vfRespRead_1_0_vfWbBusyTable;
  wire [4:0] i_io_out_vfRespRead_1_0_vfWbBusyTable;
  wire [4:0] g_io_out_vfRespRead_1_0_v0WbBusyTable;
  wire [4:0] i_io_out_vfRespRead_1_0_v0WbBusyTable;
  wire [4:0] g_io_out_vfRespRead_0_1_intWbBusyTable;
  wire [4:0] i_io_out_vfRespRead_0_1_intWbBusyTable;
  wire [2:0] g_io_out_vfRespRead_0_1_fpWbBusyTable;
  wire [2:0] i_io_out_vfRespRead_0_1_fpWbBusyTable;
  wire [3:0] g_io_out_vfRespRead_0_1_vfWbBusyTable;
  wire [3:0] i_io_out_vfRespRead_0_1_vfWbBusyTable;
  wire [3:0] g_io_out_vfRespRead_0_1_v0WbBusyTable;
  wire [3:0] i_io_out_vfRespRead_0_1_v0WbBusyTable;
  wire [1:0] g_io_out_vfRespRead_0_1_vlWbBusyTable;
  wire [1:0] i_io_out_vfRespRead_0_1_vlWbBusyTable;
  wire [4:0] g_io_out_vfRespRead_0_0_vfWbBusyTable;
  wire [4:0] i_io_out_vfRespRead_0_0_vfWbBusyTable;
  wire [4:0] g_io_out_vfRespRead_0_0_v0WbBusyTable;
  wire [4:0] i_io_out_vfRespRead_0_0_v0WbBusyTable;
  WbFuBusyTable    u_g (.io_in_intSchdBusyTable_2_1_fpWbBusyTable(io_in_intSchdBusyTable_2_1_fpWbBusyTable), .io_in_intSchdBusyTable_1_0_intWbBusyTable(io_in_intSchdBusyTable_1_0_intWbBusyTable), .io_in_intSchdBusyTable_0_0_intWbBusyTable(io_in_intSchdBusyTable_0_0_intWbBusyTable), .io_in_fpSchdBusyTable_2_0_intWbBusyTable(io_in_fpSchdBusyTable_2_0_intWbBusyTable), .io_in_fpSchdBusyTable_2_0_fpWbBusyTable(io_in_fpSchdBusyTable_2_0_fpWbBusyTable), .io_in_fpSchdBusyTable_1_0_intWbBusyTable(io_in_fpSchdBusyTable_1_0_intWbBusyTable), .io_in_fpSchdBusyTable_1_0_fpWbBusyTable(io_in_fpSchdBusyTable_1_0_fpWbBusyTable), .io_in_fpSchdBusyTable_0_0_intWbBusyTable(io_in_fpSchdBusyTable_0_0_intWbBusyTable), .io_in_fpSchdBusyTable_0_0_fpWbBusyTable(io_in_fpSchdBusyTable_0_0_fpWbBusyTable), .io_in_vfSchdBusyTable_1_1_fpWbBusyTable(io_in_vfSchdBusyTable_1_1_fpWbBusyTable), .io_in_vfSchdBusyTable_1_1_vfWbBusyTable(io_in_vfSchdBusyTable_1_1_vfWbBusyTable), .io_in_vfSchdBusyTable_1_1_v0WbBusyTable(io_in_vfSchdBusyTable_1_1_v0WbBusyTable), .io_in_vfSchdBusyTable_1_0_vfWbBusyTable(io_in_vfSchdBusyTable_1_0_vfWbBusyTable), .io_in_vfSchdBusyTable_1_0_v0WbBusyTable(io_in_vfSchdBusyTable_1_0_v0WbBusyTable), .io_in_vfSchdBusyTable_0_1_intWbBusyTable(io_in_vfSchdBusyTable_0_1_intWbBusyTable), .io_in_vfSchdBusyTable_0_1_fpWbBusyTable(io_in_vfSchdBusyTable_0_1_fpWbBusyTable), .io_in_vfSchdBusyTable_0_1_vfWbBusyTable(io_in_vfSchdBusyTable_0_1_vfWbBusyTable), .io_in_vfSchdBusyTable_0_1_v0WbBusyTable(io_in_vfSchdBusyTable_0_1_v0WbBusyTable), .io_in_vfSchdBusyTable_0_1_vlWbBusyTable(io_in_vfSchdBusyTable_0_1_vlWbBusyTable), .io_in_vfSchdBusyTable_0_0_vfWbBusyTable(io_in_vfSchdBusyTable_0_0_vfWbBusyTable), .io_in_vfSchdBusyTable_0_0_v0WbBusyTable(io_in_vfSchdBusyTable_0_0_v0WbBusyTable), .io_out_intRespRead_2_1_fpWbBusyTable(g_io_out_intRespRead_2_1_fpWbBusyTable), .io_out_intRespRead_2_1_vfWbBusyTable(g_io_out_intRespRead_2_1_vfWbBusyTable), .io_out_intRespRead_2_1_v0WbBusyTable(g_io_out_intRespRead_2_1_v0WbBusyTable), .io_out_intRespRead_2_0_intWbBusyTable(g_io_out_intRespRead_2_0_intWbBusyTable), .io_out_intRespRead_1_1_intWbBusyTable(g_io_out_intRespRead_1_1_intWbBusyTable), .io_out_intRespRead_1_0_intWbBusyTable(g_io_out_intRespRead_1_0_intWbBusyTable), .io_out_intRespRead_0_1_intWbBusyTable(g_io_out_intRespRead_0_1_intWbBusyTable), .io_out_intRespRead_0_0_intWbBusyTable(g_io_out_intRespRead_0_0_intWbBusyTable), .io_out_fpRespRead_2_0_intWbBusyTable(g_io_out_fpRespRead_2_0_intWbBusyTable), .io_out_fpRespRead_2_0_fpWbBusyTable(g_io_out_fpRespRead_2_0_fpWbBusyTable), .io_out_fpRespRead_1_0_intWbBusyTable(g_io_out_fpRespRead_1_0_intWbBusyTable), .io_out_fpRespRead_1_0_fpWbBusyTable(g_io_out_fpRespRead_1_0_fpWbBusyTable), .io_out_fpRespRead_0_0_intWbBusyTable(g_io_out_fpRespRead_0_0_intWbBusyTable), .io_out_fpRespRead_0_0_fpWbBusyTable(g_io_out_fpRespRead_0_0_fpWbBusyTable), .io_out_vfRespRead_1_1_fpWbBusyTable(g_io_out_vfRespRead_1_1_fpWbBusyTable), .io_out_vfRespRead_1_1_vfWbBusyTable(g_io_out_vfRespRead_1_1_vfWbBusyTable), .io_out_vfRespRead_1_1_v0WbBusyTable(g_io_out_vfRespRead_1_1_v0WbBusyTable), .io_out_vfRespRead_1_0_vfWbBusyTable(g_io_out_vfRespRead_1_0_vfWbBusyTable), .io_out_vfRespRead_1_0_v0WbBusyTable(g_io_out_vfRespRead_1_0_v0WbBusyTable), .io_out_vfRespRead_0_1_intWbBusyTable(g_io_out_vfRespRead_0_1_intWbBusyTable), .io_out_vfRespRead_0_1_fpWbBusyTable(g_io_out_vfRespRead_0_1_fpWbBusyTable), .io_out_vfRespRead_0_1_vfWbBusyTable(g_io_out_vfRespRead_0_1_vfWbBusyTable), .io_out_vfRespRead_0_1_v0WbBusyTable(g_io_out_vfRespRead_0_1_v0WbBusyTable), .io_out_vfRespRead_0_1_vlWbBusyTable(g_io_out_vfRespRead_0_1_vlWbBusyTable), .io_out_vfRespRead_0_0_vfWbBusyTable(g_io_out_vfRespRead_0_0_vfWbBusyTable), .io_out_vfRespRead_0_0_v0WbBusyTable(g_io_out_vfRespRead_0_0_v0WbBusyTable));
  WbFuBusyTable_xs u_i (.io_in_intSchdBusyTable_2_1_fpWbBusyTable(io_in_intSchdBusyTable_2_1_fpWbBusyTable), .io_in_intSchdBusyTable_1_0_intWbBusyTable(io_in_intSchdBusyTable_1_0_intWbBusyTable), .io_in_intSchdBusyTable_0_0_intWbBusyTable(io_in_intSchdBusyTable_0_0_intWbBusyTable), .io_in_fpSchdBusyTable_2_0_intWbBusyTable(io_in_fpSchdBusyTable_2_0_intWbBusyTable), .io_in_fpSchdBusyTable_2_0_fpWbBusyTable(io_in_fpSchdBusyTable_2_0_fpWbBusyTable), .io_in_fpSchdBusyTable_1_0_intWbBusyTable(io_in_fpSchdBusyTable_1_0_intWbBusyTable), .io_in_fpSchdBusyTable_1_0_fpWbBusyTable(io_in_fpSchdBusyTable_1_0_fpWbBusyTable), .io_in_fpSchdBusyTable_0_0_intWbBusyTable(io_in_fpSchdBusyTable_0_0_intWbBusyTable), .io_in_fpSchdBusyTable_0_0_fpWbBusyTable(io_in_fpSchdBusyTable_0_0_fpWbBusyTable), .io_in_vfSchdBusyTable_1_1_fpWbBusyTable(io_in_vfSchdBusyTable_1_1_fpWbBusyTable), .io_in_vfSchdBusyTable_1_1_vfWbBusyTable(io_in_vfSchdBusyTable_1_1_vfWbBusyTable), .io_in_vfSchdBusyTable_1_1_v0WbBusyTable(io_in_vfSchdBusyTable_1_1_v0WbBusyTable), .io_in_vfSchdBusyTable_1_0_vfWbBusyTable(io_in_vfSchdBusyTable_1_0_vfWbBusyTable), .io_in_vfSchdBusyTable_1_0_v0WbBusyTable(io_in_vfSchdBusyTable_1_0_v0WbBusyTable), .io_in_vfSchdBusyTable_0_1_intWbBusyTable(io_in_vfSchdBusyTable_0_1_intWbBusyTable), .io_in_vfSchdBusyTable_0_1_fpWbBusyTable(io_in_vfSchdBusyTable_0_1_fpWbBusyTable), .io_in_vfSchdBusyTable_0_1_vfWbBusyTable(io_in_vfSchdBusyTable_0_1_vfWbBusyTable), .io_in_vfSchdBusyTable_0_1_v0WbBusyTable(io_in_vfSchdBusyTable_0_1_v0WbBusyTable), .io_in_vfSchdBusyTable_0_1_vlWbBusyTable(io_in_vfSchdBusyTable_0_1_vlWbBusyTable), .io_in_vfSchdBusyTable_0_0_vfWbBusyTable(io_in_vfSchdBusyTable_0_0_vfWbBusyTable), .io_in_vfSchdBusyTable_0_0_v0WbBusyTable(io_in_vfSchdBusyTable_0_0_v0WbBusyTable), .io_out_intRespRead_2_1_fpWbBusyTable(i_io_out_intRespRead_2_1_fpWbBusyTable), .io_out_intRespRead_2_1_vfWbBusyTable(i_io_out_intRespRead_2_1_vfWbBusyTable), .io_out_intRespRead_2_1_v0WbBusyTable(i_io_out_intRespRead_2_1_v0WbBusyTable), .io_out_intRespRead_2_0_intWbBusyTable(i_io_out_intRespRead_2_0_intWbBusyTable), .io_out_intRespRead_1_1_intWbBusyTable(i_io_out_intRespRead_1_1_intWbBusyTable), .io_out_intRespRead_1_0_intWbBusyTable(i_io_out_intRespRead_1_0_intWbBusyTable), .io_out_intRespRead_0_1_intWbBusyTable(i_io_out_intRespRead_0_1_intWbBusyTable), .io_out_intRespRead_0_0_intWbBusyTable(i_io_out_intRespRead_0_0_intWbBusyTable), .io_out_fpRespRead_2_0_intWbBusyTable(i_io_out_fpRespRead_2_0_intWbBusyTable), .io_out_fpRespRead_2_0_fpWbBusyTable(i_io_out_fpRespRead_2_0_fpWbBusyTable), .io_out_fpRespRead_1_0_intWbBusyTable(i_io_out_fpRespRead_1_0_intWbBusyTable), .io_out_fpRespRead_1_0_fpWbBusyTable(i_io_out_fpRespRead_1_0_fpWbBusyTable), .io_out_fpRespRead_0_0_intWbBusyTable(i_io_out_fpRespRead_0_0_intWbBusyTable), .io_out_fpRespRead_0_0_fpWbBusyTable(i_io_out_fpRespRead_0_0_fpWbBusyTable), .io_out_vfRespRead_1_1_fpWbBusyTable(i_io_out_vfRespRead_1_1_fpWbBusyTable), .io_out_vfRespRead_1_1_vfWbBusyTable(i_io_out_vfRespRead_1_1_vfWbBusyTable), .io_out_vfRespRead_1_1_v0WbBusyTable(i_io_out_vfRespRead_1_1_v0WbBusyTable), .io_out_vfRespRead_1_0_vfWbBusyTable(i_io_out_vfRespRead_1_0_vfWbBusyTable), .io_out_vfRespRead_1_0_v0WbBusyTable(i_io_out_vfRespRead_1_0_v0WbBusyTable), .io_out_vfRespRead_0_1_intWbBusyTable(i_io_out_vfRespRead_0_1_intWbBusyTable), .io_out_vfRespRead_0_1_fpWbBusyTable(i_io_out_vfRespRead_0_1_fpWbBusyTable), .io_out_vfRespRead_0_1_vfWbBusyTable(i_io_out_vfRespRead_0_1_vfWbBusyTable), .io_out_vfRespRead_0_1_v0WbBusyTable(i_io_out_vfRespRead_0_1_v0WbBusyTable), .io_out_vfRespRead_0_1_vlWbBusyTable(i_io_out_vfRespRead_0_1_vlWbBusyTable), .io_out_vfRespRead_0_0_vfWbBusyTable(i_io_out_vfRespRead_0_0_vfWbBusyTable), .io_out_vfRespRead_0_0_v0WbBusyTable(i_io_out_vfRespRead_0_0_v0WbBusyTable));
  task automatic drive();
    io_in_intSchdBusyTable_2_1_fpWbBusyTable = 3'($urandom);
    io_in_intSchdBusyTable_1_0_intWbBusyTable = 3'($urandom);
    io_in_intSchdBusyTable_0_0_intWbBusyTable = 3'($urandom);
    io_in_fpSchdBusyTable_2_0_intWbBusyTable = 2'($urandom);
    io_in_fpSchdBusyTable_2_0_fpWbBusyTable = 4'($urandom);
    io_in_fpSchdBusyTable_1_0_intWbBusyTable = 2'($urandom);
    io_in_fpSchdBusyTable_1_0_fpWbBusyTable = 4'($urandom);
    io_in_fpSchdBusyTable_0_0_intWbBusyTable = 3'($urandom);
    io_in_fpSchdBusyTable_0_0_fpWbBusyTable = 4'($urandom);
    io_in_vfSchdBusyTable_1_1_fpWbBusyTable = 3'($urandom);
    io_in_vfSchdBusyTable_1_1_vfWbBusyTable = 3'($urandom);
    io_in_vfSchdBusyTable_1_1_v0WbBusyTable = 3'($urandom);
    io_in_vfSchdBusyTable_1_0_vfWbBusyTable = 5'($urandom);
    io_in_vfSchdBusyTable_1_0_v0WbBusyTable = 5'($urandom);
    io_in_vfSchdBusyTable_0_1_intWbBusyTable = 5'($urandom);
    io_in_vfSchdBusyTable_0_1_fpWbBusyTable = 3'($urandom);
    io_in_vfSchdBusyTable_0_1_vfWbBusyTable = 4'($urandom);
    io_in_vfSchdBusyTable_0_1_v0WbBusyTable = 4'($urandom);
    io_in_vfSchdBusyTable_0_1_vlWbBusyTable = 2'($urandom);
    io_in_vfSchdBusyTable_0_0_vfWbBusyTable = 5'($urandom);
    io_in_vfSchdBusyTable_0_0_v0WbBusyTable = 5'($urandom);
  endtask
  `define CK(g,i,nm) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors<=60) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end \
    checks++;
  task automatic check();
    `CK(g_io_out_intRespRead_2_1_fpWbBusyTable, i_io_out_intRespRead_2_1_fpWbBusyTable, "io_out_intRespRead_2_1_fpWbBusyTable")
    `CK(g_io_out_intRespRead_2_1_vfWbBusyTable, i_io_out_intRespRead_2_1_vfWbBusyTable, "io_out_intRespRead_2_1_vfWbBusyTable")
    `CK(g_io_out_intRespRead_2_1_v0WbBusyTable, i_io_out_intRespRead_2_1_v0WbBusyTable, "io_out_intRespRead_2_1_v0WbBusyTable")
    `CK(g_io_out_intRespRead_2_0_intWbBusyTable, i_io_out_intRespRead_2_0_intWbBusyTable, "io_out_intRespRead_2_0_intWbBusyTable")
    `CK(g_io_out_intRespRead_1_1_intWbBusyTable, i_io_out_intRespRead_1_1_intWbBusyTable, "io_out_intRespRead_1_1_intWbBusyTable")
    `CK(g_io_out_intRespRead_1_0_intWbBusyTable, i_io_out_intRespRead_1_0_intWbBusyTable, "io_out_intRespRead_1_0_intWbBusyTable")
    `CK(g_io_out_intRespRead_0_1_intWbBusyTable, i_io_out_intRespRead_0_1_intWbBusyTable, "io_out_intRespRead_0_1_intWbBusyTable")
    `CK(g_io_out_intRespRead_0_0_intWbBusyTable, i_io_out_intRespRead_0_0_intWbBusyTable, "io_out_intRespRead_0_0_intWbBusyTable")
    `CK(g_io_out_fpRespRead_2_0_intWbBusyTable, i_io_out_fpRespRead_2_0_intWbBusyTable, "io_out_fpRespRead_2_0_intWbBusyTable")
    `CK(g_io_out_fpRespRead_2_0_fpWbBusyTable, i_io_out_fpRespRead_2_0_fpWbBusyTable, "io_out_fpRespRead_2_0_fpWbBusyTable")
    `CK(g_io_out_fpRespRead_1_0_intWbBusyTable, i_io_out_fpRespRead_1_0_intWbBusyTable, "io_out_fpRespRead_1_0_intWbBusyTable")
    `CK(g_io_out_fpRespRead_1_0_fpWbBusyTable, i_io_out_fpRespRead_1_0_fpWbBusyTable, "io_out_fpRespRead_1_0_fpWbBusyTable")
    `CK(g_io_out_fpRespRead_0_0_intWbBusyTable, i_io_out_fpRespRead_0_0_intWbBusyTable, "io_out_fpRespRead_0_0_intWbBusyTable")
    `CK(g_io_out_fpRespRead_0_0_fpWbBusyTable, i_io_out_fpRespRead_0_0_fpWbBusyTable, "io_out_fpRespRead_0_0_fpWbBusyTable")
    `CK(g_io_out_vfRespRead_1_1_fpWbBusyTable, i_io_out_vfRespRead_1_1_fpWbBusyTable, "io_out_vfRespRead_1_1_fpWbBusyTable")
    `CK(g_io_out_vfRespRead_1_1_vfWbBusyTable, i_io_out_vfRespRead_1_1_vfWbBusyTable, "io_out_vfRespRead_1_1_vfWbBusyTable")
    `CK(g_io_out_vfRespRead_1_1_v0WbBusyTable, i_io_out_vfRespRead_1_1_v0WbBusyTable, "io_out_vfRespRead_1_1_v0WbBusyTable")
    `CK(g_io_out_vfRespRead_1_0_vfWbBusyTable, i_io_out_vfRespRead_1_0_vfWbBusyTable, "io_out_vfRespRead_1_0_vfWbBusyTable")
    `CK(g_io_out_vfRespRead_1_0_v0WbBusyTable, i_io_out_vfRespRead_1_0_v0WbBusyTable, "io_out_vfRespRead_1_0_v0WbBusyTable")
    `CK(g_io_out_vfRespRead_0_1_intWbBusyTable, i_io_out_vfRespRead_0_1_intWbBusyTable, "io_out_vfRespRead_0_1_intWbBusyTable")
    `CK(g_io_out_vfRespRead_0_1_fpWbBusyTable, i_io_out_vfRespRead_0_1_fpWbBusyTable, "io_out_vfRespRead_0_1_fpWbBusyTable")
    `CK(g_io_out_vfRespRead_0_1_vfWbBusyTable, i_io_out_vfRespRead_0_1_vfWbBusyTable, "io_out_vfRespRead_0_1_vfWbBusyTable")
    `CK(g_io_out_vfRespRead_0_1_v0WbBusyTable, i_io_out_vfRespRead_0_1_v0WbBusyTable, "io_out_vfRespRead_0_1_v0WbBusyTable")
    `CK(g_io_out_vfRespRead_0_1_vlWbBusyTable, i_io_out_vfRespRead_0_1_vlWbBusyTable, "io_out_vfRespRead_0_1_vlWbBusyTable")
    `CK(g_io_out_vfRespRead_0_0_vfWbBusyTable, i_io_out_vfRespRead_0_0_vfWbBusyTable, "io_out_vfRespRead_0_0_vfWbBusyTable")
    `CK(g_io_out_vfRespRead_0_0_v0WbBusyTable, i_io_out_vfRespRead_0_0_v0WbBusyTable, "io_out_vfRespRead_0_0_v0WbBusyTable")
  endtask
  initial begin
    drive();
    repeat (NCYCLES) begin
      @(posedge clk);
      #1 check();
      drive();
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
