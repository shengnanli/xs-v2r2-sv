// 自动生成：scripts/gen_waylookup.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_flush;
  logic io_read_ready;
  logic io_write_valid;
  logic [7:0] io_write_bits_entry_vSetIdx_0;
  logic [7:0] io_write_bits_entry_vSetIdx_1;
  logic [3:0] io_write_bits_entry_waymask_0;
  logic [3:0] io_write_bits_entry_waymask_1;
  logic [35:0] io_write_bits_entry_ptag_0;
  logic [35:0] io_write_bits_entry_ptag_1;
  logic [1:0] io_write_bits_entry_itlb_exception_0;
  logic [1:0] io_write_bits_entry_itlb_exception_1;
  logic [1:0] io_write_bits_entry_itlb_pbmt_0;
  logic [1:0] io_write_bits_entry_itlb_pbmt_1;
  logic io_write_bits_entry_meta_codes_0;
  logic io_write_bits_entry_meta_codes_1;
  logic [55:0] io_write_bits_gpf_gpaddr;
  logic io_write_bits_gpf_isForVSnonLeafPTE;
  logic io_update_valid;
  logic [41:0] io_update_bits_blkPaddr;
  logic [7:0] io_update_bits_vSetIdx;
  logic [3:0] io_update_bits_waymask;
  logic io_update_bits_corrupt;
  wire g_io_read_valid;
  wire i_io_read_valid;
  wire [7:0] g_io_read_bits_entry_vSetIdx_0;
  wire [7:0] i_io_read_bits_entry_vSetIdx_0;
  wire [7:0] g_io_read_bits_entry_vSetIdx_1;
  wire [7:0] i_io_read_bits_entry_vSetIdx_1;
  wire [3:0] g_io_read_bits_entry_waymask_0;
  wire [3:0] i_io_read_bits_entry_waymask_0;
  wire [3:0] g_io_read_bits_entry_waymask_1;
  wire [3:0] i_io_read_bits_entry_waymask_1;
  wire [35:0] g_io_read_bits_entry_ptag_0;
  wire [35:0] i_io_read_bits_entry_ptag_0;
  wire [35:0] g_io_read_bits_entry_ptag_1;
  wire [35:0] i_io_read_bits_entry_ptag_1;
  wire [1:0] g_io_read_bits_entry_itlb_exception_0;
  wire [1:0] i_io_read_bits_entry_itlb_exception_0;
  wire [1:0] g_io_read_bits_entry_itlb_exception_1;
  wire [1:0] i_io_read_bits_entry_itlb_exception_1;
  wire [1:0] g_io_read_bits_entry_itlb_pbmt_0;
  wire [1:0] i_io_read_bits_entry_itlb_pbmt_0;
  wire [1:0] g_io_read_bits_entry_itlb_pbmt_1;
  wire [1:0] i_io_read_bits_entry_itlb_pbmt_1;
  wire g_io_read_bits_entry_meta_codes_0;
  wire i_io_read_bits_entry_meta_codes_0;
  wire g_io_read_bits_entry_meta_codes_1;
  wire i_io_read_bits_entry_meta_codes_1;
  wire [55:0] g_io_read_bits_gpf_gpaddr;
  wire [55:0] i_io_read_bits_gpf_gpaddr;
  wire g_io_read_bits_gpf_isForVSnonLeafPTE;
  wire i_io_read_bits_gpf_isForVSnonLeafPTE;
  wire g_io_write_ready;
  wire i_io_write_ready;
  WayLookup    u_g (.clock(clk), .reset(rst), .io_flush(io_flush), .io_read_ready(io_read_ready), .io_write_valid(io_write_valid), .io_write_bits_entry_vSetIdx_0(io_write_bits_entry_vSetIdx_0), .io_write_bits_entry_vSetIdx_1(io_write_bits_entry_vSetIdx_1), .io_write_bits_entry_waymask_0(io_write_bits_entry_waymask_0), .io_write_bits_entry_waymask_1(io_write_bits_entry_waymask_1), .io_write_bits_entry_ptag_0(io_write_bits_entry_ptag_0), .io_write_bits_entry_ptag_1(io_write_bits_entry_ptag_1), .io_write_bits_entry_itlb_exception_0(io_write_bits_entry_itlb_exception_0), .io_write_bits_entry_itlb_exception_1(io_write_bits_entry_itlb_exception_1), .io_write_bits_entry_itlb_pbmt_0(io_write_bits_entry_itlb_pbmt_0), .io_write_bits_entry_itlb_pbmt_1(io_write_bits_entry_itlb_pbmt_1), .io_write_bits_entry_meta_codes_0(io_write_bits_entry_meta_codes_0), .io_write_bits_entry_meta_codes_1(io_write_bits_entry_meta_codes_1), .io_write_bits_gpf_gpaddr(io_write_bits_gpf_gpaddr), .io_write_bits_gpf_isForVSnonLeafPTE(io_write_bits_gpf_isForVSnonLeafPTE), .io_update_valid(io_update_valid), .io_update_bits_blkPaddr(io_update_bits_blkPaddr), .io_update_bits_vSetIdx(io_update_bits_vSetIdx), .io_update_bits_waymask(io_update_bits_waymask), .io_update_bits_corrupt(io_update_bits_corrupt), .io_read_valid(g_io_read_valid), .io_read_bits_entry_vSetIdx_0(g_io_read_bits_entry_vSetIdx_0), .io_read_bits_entry_vSetIdx_1(g_io_read_bits_entry_vSetIdx_1), .io_read_bits_entry_waymask_0(g_io_read_bits_entry_waymask_0), .io_read_bits_entry_waymask_1(g_io_read_bits_entry_waymask_1), .io_read_bits_entry_ptag_0(g_io_read_bits_entry_ptag_0), .io_read_bits_entry_ptag_1(g_io_read_bits_entry_ptag_1), .io_read_bits_entry_itlb_exception_0(g_io_read_bits_entry_itlb_exception_0), .io_read_bits_entry_itlb_exception_1(g_io_read_bits_entry_itlb_exception_1), .io_read_bits_entry_itlb_pbmt_0(g_io_read_bits_entry_itlb_pbmt_0), .io_read_bits_entry_itlb_pbmt_1(g_io_read_bits_entry_itlb_pbmt_1), .io_read_bits_entry_meta_codes_0(g_io_read_bits_entry_meta_codes_0), .io_read_bits_entry_meta_codes_1(g_io_read_bits_entry_meta_codes_1), .io_read_bits_gpf_gpaddr(g_io_read_bits_gpf_gpaddr), .io_read_bits_gpf_isForVSnonLeafPTE(g_io_read_bits_gpf_isForVSnonLeafPTE), .io_write_ready(g_io_write_ready));
  WayLookup_xs u_i (.clock(clk), .reset(rst), .io_flush(io_flush), .io_read_ready(io_read_ready), .io_write_valid(io_write_valid), .io_write_bits_entry_vSetIdx_0(io_write_bits_entry_vSetIdx_0), .io_write_bits_entry_vSetIdx_1(io_write_bits_entry_vSetIdx_1), .io_write_bits_entry_waymask_0(io_write_bits_entry_waymask_0), .io_write_bits_entry_waymask_1(io_write_bits_entry_waymask_1), .io_write_bits_entry_ptag_0(io_write_bits_entry_ptag_0), .io_write_bits_entry_ptag_1(io_write_bits_entry_ptag_1), .io_write_bits_entry_itlb_exception_0(io_write_bits_entry_itlb_exception_0), .io_write_bits_entry_itlb_exception_1(io_write_bits_entry_itlb_exception_1), .io_write_bits_entry_itlb_pbmt_0(io_write_bits_entry_itlb_pbmt_0), .io_write_bits_entry_itlb_pbmt_1(io_write_bits_entry_itlb_pbmt_1), .io_write_bits_entry_meta_codes_0(io_write_bits_entry_meta_codes_0), .io_write_bits_entry_meta_codes_1(io_write_bits_entry_meta_codes_1), .io_write_bits_gpf_gpaddr(io_write_bits_gpf_gpaddr), .io_write_bits_gpf_isForVSnonLeafPTE(io_write_bits_gpf_isForVSnonLeafPTE), .io_update_valid(io_update_valid), .io_update_bits_blkPaddr(io_update_bits_blkPaddr), .io_update_bits_vSetIdx(io_update_bits_vSetIdx), .io_update_bits_waymask(io_update_bits_waymask), .io_update_bits_corrupt(io_update_bits_corrupt), .io_read_valid(i_io_read_valid), .io_read_bits_entry_vSetIdx_0(i_io_read_bits_entry_vSetIdx_0), .io_read_bits_entry_vSetIdx_1(i_io_read_bits_entry_vSetIdx_1), .io_read_bits_entry_waymask_0(i_io_read_bits_entry_waymask_0), .io_read_bits_entry_waymask_1(i_io_read_bits_entry_waymask_1), .io_read_bits_entry_ptag_0(i_io_read_bits_entry_ptag_0), .io_read_bits_entry_ptag_1(i_io_read_bits_entry_ptag_1), .io_read_bits_entry_itlb_exception_0(i_io_read_bits_entry_itlb_exception_0), .io_read_bits_entry_itlb_exception_1(i_io_read_bits_entry_itlb_exception_1), .io_read_bits_entry_itlb_pbmt_0(i_io_read_bits_entry_itlb_pbmt_0), .io_read_bits_entry_itlb_pbmt_1(i_io_read_bits_entry_itlb_pbmt_1), .io_read_bits_entry_meta_codes_0(i_io_read_bits_entry_meta_codes_0), .io_read_bits_entry_meta_codes_1(i_io_read_bits_entry_meta_codes_1), .io_read_bits_gpf_gpaddr(i_io_read_bits_gpf_gpaddr), .io_read_bits_gpf_isForVSnonLeafPTE(i_io_read_bits_gpf_isForVSnonLeafPTE), .io_write_ready(i_io_write_ready));
  always @(negedge clk) begin
    if (rst) begin
      io_flush <= 1'b0;
      io_write_valid <= 1'b0;
      io_read_ready <= 1'b0;
      io_update_valid <= 1'b0;
    end else begin
      io_flush <= ($urandom_range(0,63)==0);
      io_read_ready <= ($urandom_range(0,2)!=0);
      io_write_valid <= ($urandom_range(0,3)!=0);
      io_write_bits_entry_vSetIdx_0 <= 8'($urandom_range(0,7));
      io_write_bits_entry_vSetIdx_1 <= 8'($urandom_range(0,7));
      io_write_bits_entry_waymask_0 <= 4'($urandom_range(0,15));
      io_write_bits_entry_waymask_1 <= 4'($urandom_range(0,15));
      io_write_bits_entry_ptag_0 <= 36'($urandom_range(0,15));
      io_write_bits_entry_ptag_1 <= 36'($urandom_range(0,15));
      io_write_bits_entry_itlb_exception_0 <= 2'($urandom_range(0,3));
      io_write_bits_entry_itlb_exception_1 <= 2'($urandom_range(0,3));
      io_write_bits_entry_itlb_pbmt_0 <= 2'($urandom);
      io_write_bits_entry_itlb_pbmt_1 <= 2'($urandom);
      io_write_bits_entry_meta_codes_0 <= 1'($urandom);
      io_write_bits_entry_meta_codes_1 <= 1'($urandom);
      io_write_bits_gpf_gpaddr <= 56'({$urandom(), $urandom()});
      io_write_bits_gpf_isForVSnonLeafPTE <= 1'($urandom);
      io_update_valid <= ($urandom_range(0,1)==0);
      io_update_bits_blkPaddr <= {36'($urandom_range(0,15)), 6'($urandom)};
      io_update_bits_vSetIdx <= 8'($urandom_range(0,7));
      io_update_bits_waymask <= 4'($urandom_range(0,15));
      io_update_bits_corrupt <= 1'($urandom);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (g_io_read_valid !== i_io_read_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_read_valid g=%h i=%h", $time, g_io_read_valid, i_io_read_valid); end
    if (g_io_read_bits_entry_vSetIdx_0 !== i_io_read_bits_entry_vSetIdx_0) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_entry_vSetIdx_0 g=%h i=%h", $time, g_io_read_bits_entry_vSetIdx_0, i_io_read_bits_entry_vSetIdx_0); end
    if (g_io_read_bits_entry_vSetIdx_1 !== i_io_read_bits_entry_vSetIdx_1) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_entry_vSetIdx_1 g=%h i=%h", $time, g_io_read_bits_entry_vSetIdx_1, i_io_read_bits_entry_vSetIdx_1); end
    if (g_io_read_bits_entry_waymask_0 !== i_io_read_bits_entry_waymask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_entry_waymask_0 g=%h i=%h", $time, g_io_read_bits_entry_waymask_0, i_io_read_bits_entry_waymask_0); end
    if (g_io_read_bits_entry_waymask_1 !== i_io_read_bits_entry_waymask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_entry_waymask_1 g=%h i=%h", $time, g_io_read_bits_entry_waymask_1, i_io_read_bits_entry_waymask_1); end
    if (g_io_read_bits_entry_ptag_0 !== i_io_read_bits_entry_ptag_0) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_entry_ptag_0 g=%h i=%h", $time, g_io_read_bits_entry_ptag_0, i_io_read_bits_entry_ptag_0); end
    if (g_io_read_bits_entry_ptag_1 !== i_io_read_bits_entry_ptag_1) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_entry_ptag_1 g=%h i=%h", $time, g_io_read_bits_entry_ptag_1, i_io_read_bits_entry_ptag_1); end
    if (g_io_read_bits_entry_itlb_exception_0 !== i_io_read_bits_entry_itlb_exception_0) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_entry_itlb_exception_0 g=%h i=%h", $time, g_io_read_bits_entry_itlb_exception_0, i_io_read_bits_entry_itlb_exception_0); end
    if (g_io_read_bits_entry_itlb_exception_1 !== i_io_read_bits_entry_itlb_exception_1) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_entry_itlb_exception_1 g=%h i=%h", $time, g_io_read_bits_entry_itlb_exception_1, i_io_read_bits_entry_itlb_exception_1); end
    if (g_io_read_bits_entry_itlb_pbmt_0 !== i_io_read_bits_entry_itlb_pbmt_0) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_entry_itlb_pbmt_0 g=%h i=%h", $time, g_io_read_bits_entry_itlb_pbmt_0, i_io_read_bits_entry_itlb_pbmt_0); end
    if (g_io_read_bits_entry_itlb_pbmt_1 !== i_io_read_bits_entry_itlb_pbmt_1) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_entry_itlb_pbmt_1 g=%h i=%h", $time, g_io_read_bits_entry_itlb_pbmt_1, i_io_read_bits_entry_itlb_pbmt_1); end
    if (g_io_read_bits_entry_meta_codes_0 !== i_io_read_bits_entry_meta_codes_0) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_entry_meta_codes_0 g=%h i=%h", $time, g_io_read_bits_entry_meta_codes_0, i_io_read_bits_entry_meta_codes_0); end
    if (g_io_read_bits_entry_meta_codes_1 !== i_io_read_bits_entry_meta_codes_1) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_entry_meta_codes_1 g=%h i=%h", $time, g_io_read_bits_entry_meta_codes_1, i_io_read_bits_entry_meta_codes_1); end
    if (g_io_read_bits_gpf_gpaddr !== i_io_read_bits_gpf_gpaddr) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_gpf_gpaddr g=%h i=%h", $time, g_io_read_bits_gpf_gpaddr, i_io_read_bits_gpf_gpaddr); end
    if (g_io_read_bits_gpf_isForVSnonLeafPTE !== i_io_read_bits_gpf_isForVSnonLeafPTE) begin errors++;
      if(errors<=30) $display("[%0t] io_read_bits_gpf_isForVSnonLeafPTE g=%h i=%h", $time, g_io_read_bits_gpf_isForVSnonLeafPTE, i_io_read_bits_gpf_isForVSnonLeafPTE); end
    if (g_io_write_ready !== i_io_write_ready) begin errors++;
      if(errors<=30) $display("[%0t] io_write_ready g=%h i=%h", $time, g_io_write_ready, i_io_write_ready); end
  end
  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
