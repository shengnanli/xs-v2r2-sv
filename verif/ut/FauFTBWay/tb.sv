// 自动生成：scripts/gen_fauftbway.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic [15:0] io_req_tag;
  logic [15:0] io_update_req_tag;
  logic io_write_valid;
  logic io_write_entry_isCall;
  logic io_write_entry_isRet;
  logic io_write_entry_isJalr;
  logic io_write_entry_valid;
  logic [3:0] io_write_entry_brSlots_0_offset;
  logic io_write_entry_brSlots_0_sharing;
  logic io_write_entry_brSlots_0_valid;
  logic [11:0] io_write_entry_brSlots_0_lower;
  logic [1:0] io_write_entry_brSlots_0_tarStat;
  logic [3:0] io_write_entry_tailSlot_offset;
  logic io_write_entry_tailSlot_sharing;
  logic io_write_entry_tailSlot_valid;
  logic [19:0] io_write_entry_tailSlot_lower;
  logic [1:0] io_write_entry_tailSlot_tarStat;
  logic [3:0] io_write_entry_pftAddr;
  logic io_write_entry_carry;
  logic io_write_entry_last_may_be_rvi_call;
  logic io_write_entry_strong_bias_0;
  logic io_write_entry_strong_bias_1;
  logic [15:0] io_write_tag;
  wire g_io_resp_isCall;
  wire i_io_resp_isCall;
  wire g_io_resp_isRet;
  wire i_io_resp_isRet;
  wire g_io_resp_isJalr;
  wire i_io_resp_isJalr;
  wire g_io_resp_valid;
  wire i_io_resp_valid;
  wire [3:0] g_io_resp_brSlots_0_offset;
  wire [3:0] i_io_resp_brSlots_0_offset;
  wire g_io_resp_brSlots_0_sharing;
  wire i_io_resp_brSlots_0_sharing;
  wire g_io_resp_brSlots_0_valid;
  wire i_io_resp_brSlots_0_valid;
  wire [11:0] g_io_resp_brSlots_0_lower;
  wire [11:0] i_io_resp_brSlots_0_lower;
  wire [1:0] g_io_resp_brSlots_0_tarStat;
  wire [1:0] i_io_resp_brSlots_0_tarStat;
  wire [3:0] g_io_resp_tailSlot_offset;
  wire [3:0] i_io_resp_tailSlot_offset;
  wire g_io_resp_tailSlot_sharing;
  wire i_io_resp_tailSlot_sharing;
  wire g_io_resp_tailSlot_valid;
  wire i_io_resp_tailSlot_valid;
  wire [19:0] g_io_resp_tailSlot_lower;
  wire [19:0] i_io_resp_tailSlot_lower;
  wire [1:0] g_io_resp_tailSlot_tarStat;
  wire [1:0] i_io_resp_tailSlot_tarStat;
  wire [3:0] g_io_resp_pftAddr;
  wire [3:0] i_io_resp_pftAddr;
  wire g_io_resp_carry;
  wire i_io_resp_carry;
  wire g_io_resp_last_may_be_rvi_call;
  wire i_io_resp_last_may_be_rvi_call;
  wire g_io_resp_strong_bias_0;
  wire i_io_resp_strong_bias_0;
  wire g_io_resp_strong_bias_1;
  wire i_io_resp_strong_bias_1;
  wire g_io_resp_hit;
  wire i_io_resp_hit;
  wire g_io_update_hit;
  wire i_io_update_hit;
  FauFTBWay    u_g (.clock(clk), .reset(rst), .io_req_tag(io_req_tag), .io_update_req_tag(io_update_req_tag), .io_write_valid(io_write_valid), .io_write_entry_isCall(io_write_entry_isCall), .io_write_entry_isRet(io_write_entry_isRet), .io_write_entry_isJalr(io_write_entry_isJalr), .io_write_entry_valid(io_write_entry_valid), .io_write_entry_brSlots_0_offset(io_write_entry_brSlots_0_offset), .io_write_entry_brSlots_0_sharing(io_write_entry_brSlots_0_sharing), .io_write_entry_brSlots_0_valid(io_write_entry_brSlots_0_valid), .io_write_entry_brSlots_0_lower(io_write_entry_brSlots_0_lower), .io_write_entry_brSlots_0_tarStat(io_write_entry_brSlots_0_tarStat), .io_write_entry_tailSlot_offset(io_write_entry_tailSlot_offset), .io_write_entry_tailSlot_sharing(io_write_entry_tailSlot_sharing), .io_write_entry_tailSlot_valid(io_write_entry_tailSlot_valid), .io_write_entry_tailSlot_lower(io_write_entry_tailSlot_lower), .io_write_entry_tailSlot_tarStat(io_write_entry_tailSlot_tarStat), .io_write_entry_pftAddr(io_write_entry_pftAddr), .io_write_entry_carry(io_write_entry_carry), .io_write_entry_last_may_be_rvi_call(io_write_entry_last_may_be_rvi_call), .io_write_entry_strong_bias_0(io_write_entry_strong_bias_0), .io_write_entry_strong_bias_1(io_write_entry_strong_bias_1), .io_write_tag(io_write_tag), .io_resp_isCall(g_io_resp_isCall), .io_resp_isRet(g_io_resp_isRet), .io_resp_isJalr(g_io_resp_isJalr), .io_resp_valid(g_io_resp_valid), .io_resp_brSlots_0_offset(g_io_resp_brSlots_0_offset), .io_resp_brSlots_0_sharing(g_io_resp_brSlots_0_sharing), .io_resp_brSlots_0_valid(g_io_resp_brSlots_0_valid), .io_resp_brSlots_0_lower(g_io_resp_brSlots_0_lower), .io_resp_brSlots_0_tarStat(g_io_resp_brSlots_0_tarStat), .io_resp_tailSlot_offset(g_io_resp_tailSlot_offset), .io_resp_tailSlot_sharing(g_io_resp_tailSlot_sharing), .io_resp_tailSlot_valid(g_io_resp_tailSlot_valid), .io_resp_tailSlot_lower(g_io_resp_tailSlot_lower), .io_resp_tailSlot_tarStat(g_io_resp_tailSlot_tarStat), .io_resp_pftAddr(g_io_resp_pftAddr), .io_resp_carry(g_io_resp_carry), .io_resp_last_may_be_rvi_call(g_io_resp_last_may_be_rvi_call), .io_resp_strong_bias_0(g_io_resp_strong_bias_0), .io_resp_strong_bias_1(g_io_resp_strong_bias_1), .io_resp_hit(g_io_resp_hit), .io_update_hit(g_io_update_hit));
  FauFTBWay_xs u_i (.clock(clk), .reset(rst), .io_req_tag(io_req_tag), .io_update_req_tag(io_update_req_tag), .io_write_valid(io_write_valid), .io_write_entry_isCall(io_write_entry_isCall), .io_write_entry_isRet(io_write_entry_isRet), .io_write_entry_isJalr(io_write_entry_isJalr), .io_write_entry_valid(io_write_entry_valid), .io_write_entry_brSlots_0_offset(io_write_entry_brSlots_0_offset), .io_write_entry_brSlots_0_sharing(io_write_entry_brSlots_0_sharing), .io_write_entry_brSlots_0_valid(io_write_entry_brSlots_0_valid), .io_write_entry_brSlots_0_lower(io_write_entry_brSlots_0_lower), .io_write_entry_brSlots_0_tarStat(io_write_entry_brSlots_0_tarStat), .io_write_entry_tailSlot_offset(io_write_entry_tailSlot_offset), .io_write_entry_tailSlot_sharing(io_write_entry_tailSlot_sharing), .io_write_entry_tailSlot_valid(io_write_entry_tailSlot_valid), .io_write_entry_tailSlot_lower(io_write_entry_tailSlot_lower), .io_write_entry_tailSlot_tarStat(io_write_entry_tailSlot_tarStat), .io_write_entry_pftAddr(io_write_entry_pftAddr), .io_write_entry_carry(io_write_entry_carry), .io_write_entry_last_may_be_rvi_call(io_write_entry_last_may_be_rvi_call), .io_write_entry_strong_bias_0(io_write_entry_strong_bias_0), .io_write_entry_strong_bias_1(io_write_entry_strong_bias_1), .io_write_tag(io_write_tag), .io_resp_isCall(i_io_resp_isCall), .io_resp_isRet(i_io_resp_isRet), .io_resp_isJalr(i_io_resp_isJalr), .io_resp_valid(i_io_resp_valid), .io_resp_brSlots_0_offset(i_io_resp_brSlots_0_offset), .io_resp_brSlots_0_sharing(i_io_resp_brSlots_0_sharing), .io_resp_brSlots_0_valid(i_io_resp_brSlots_0_valid), .io_resp_brSlots_0_lower(i_io_resp_brSlots_0_lower), .io_resp_brSlots_0_tarStat(i_io_resp_brSlots_0_tarStat), .io_resp_tailSlot_offset(i_io_resp_tailSlot_offset), .io_resp_tailSlot_sharing(i_io_resp_tailSlot_sharing), .io_resp_tailSlot_valid(i_io_resp_tailSlot_valid), .io_resp_tailSlot_lower(i_io_resp_tailSlot_lower), .io_resp_tailSlot_tarStat(i_io_resp_tailSlot_tarStat), .io_resp_pftAddr(i_io_resp_pftAddr), .io_resp_carry(i_io_resp_carry), .io_resp_last_may_be_rvi_call(i_io_resp_last_may_be_rvi_call), .io_resp_strong_bias_0(i_io_resp_strong_bias_0), .io_resp_strong_bias_1(i_io_resp_strong_bias_1), .io_resp_hit(i_io_resp_hit), .io_update_hit(i_io_update_hit));
  always @(negedge clk) begin
    if (rst) io_write_valid <= 1'b0;
    else begin
      io_req_tag <= 16'($urandom_range(0,15));
      io_update_req_tag <= 16'($urandom_range(0,15));
      io_write_valid <= ($urandom_range(0,3)==0);
      io_write_entry_isCall <= 1'($urandom);
      io_write_entry_isRet <= 1'($urandom);
      io_write_entry_isJalr <= 1'($urandom);
      io_write_entry_valid <= 1'($urandom);
      io_write_entry_brSlots_0_offset <= 4'($urandom);
      io_write_entry_brSlots_0_sharing <= 1'($urandom);
      io_write_entry_brSlots_0_valid <= 1'($urandom);
      io_write_entry_brSlots_0_lower <= 12'($urandom);
      io_write_entry_brSlots_0_tarStat <= 2'($urandom);
      io_write_entry_tailSlot_offset <= 4'($urandom);
      io_write_entry_tailSlot_sharing <= 1'($urandom);
      io_write_entry_tailSlot_valid <= 1'($urandom);
      io_write_entry_tailSlot_lower <= 20'($urandom);
      io_write_entry_tailSlot_tarStat <= 2'($urandom);
      io_write_entry_pftAddr <= 4'($urandom);
      io_write_entry_carry <= 1'($urandom);
      io_write_entry_last_may_be_rvi_call <= 1'($urandom);
      io_write_entry_strong_bias_0 <= 1'($urandom);
      io_write_entry_strong_bias_1 <= 1'($urandom);
      io_write_tag <= 16'($urandom_range(0,15));
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (g_io_resp_isCall !== i_io_resp_isCall) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_isCall g=%h i=%h", $time, g_io_resp_isCall, i_io_resp_isCall); end
    if (g_io_resp_isRet !== i_io_resp_isRet) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_isRet g=%h i=%h", $time, g_io_resp_isRet, i_io_resp_isRet); end
    if (g_io_resp_isJalr !== i_io_resp_isJalr) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_isJalr g=%h i=%h", $time, g_io_resp_isJalr, i_io_resp_isJalr); end
    if (g_io_resp_valid !== i_io_resp_valid) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_valid g=%h i=%h", $time, g_io_resp_valid, i_io_resp_valid); end
    if (g_io_resp_brSlots_0_offset !== i_io_resp_brSlots_0_offset) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_brSlots_0_offset g=%h i=%h", $time, g_io_resp_brSlots_0_offset, i_io_resp_brSlots_0_offset); end
    if (g_io_resp_brSlots_0_sharing !== i_io_resp_brSlots_0_sharing) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_brSlots_0_sharing g=%h i=%h", $time, g_io_resp_brSlots_0_sharing, i_io_resp_brSlots_0_sharing); end
    if (g_io_resp_brSlots_0_valid !== i_io_resp_brSlots_0_valid) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_brSlots_0_valid g=%h i=%h", $time, g_io_resp_brSlots_0_valid, i_io_resp_brSlots_0_valid); end
    if (g_io_resp_brSlots_0_lower !== i_io_resp_brSlots_0_lower) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_brSlots_0_lower g=%h i=%h", $time, g_io_resp_brSlots_0_lower, i_io_resp_brSlots_0_lower); end
    if (g_io_resp_brSlots_0_tarStat !== i_io_resp_brSlots_0_tarStat) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_brSlots_0_tarStat g=%h i=%h", $time, g_io_resp_brSlots_0_tarStat, i_io_resp_brSlots_0_tarStat); end
    if (g_io_resp_tailSlot_offset !== i_io_resp_tailSlot_offset) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_tailSlot_offset g=%h i=%h", $time, g_io_resp_tailSlot_offset, i_io_resp_tailSlot_offset); end
    if (g_io_resp_tailSlot_sharing !== i_io_resp_tailSlot_sharing) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_tailSlot_sharing g=%h i=%h", $time, g_io_resp_tailSlot_sharing, i_io_resp_tailSlot_sharing); end
    if (g_io_resp_tailSlot_valid !== i_io_resp_tailSlot_valid) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_tailSlot_valid g=%h i=%h", $time, g_io_resp_tailSlot_valid, i_io_resp_tailSlot_valid); end
    if (g_io_resp_tailSlot_lower !== i_io_resp_tailSlot_lower) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_tailSlot_lower g=%h i=%h", $time, g_io_resp_tailSlot_lower, i_io_resp_tailSlot_lower); end
    if (g_io_resp_tailSlot_tarStat !== i_io_resp_tailSlot_tarStat) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_tailSlot_tarStat g=%h i=%h", $time, g_io_resp_tailSlot_tarStat, i_io_resp_tailSlot_tarStat); end
    if (g_io_resp_pftAddr !== i_io_resp_pftAddr) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_pftAddr g=%h i=%h", $time, g_io_resp_pftAddr, i_io_resp_pftAddr); end
    if (g_io_resp_carry !== i_io_resp_carry) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_carry g=%h i=%h", $time, g_io_resp_carry, i_io_resp_carry); end
    if (g_io_resp_last_may_be_rvi_call !== i_io_resp_last_may_be_rvi_call) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_last_may_be_rvi_call g=%h i=%h", $time, g_io_resp_last_may_be_rvi_call, i_io_resp_last_may_be_rvi_call); end
    if (g_io_resp_strong_bias_0 !== i_io_resp_strong_bias_0) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_strong_bias_0 g=%h i=%h", $time, g_io_resp_strong_bias_0, i_io_resp_strong_bias_0); end
    if (g_io_resp_strong_bias_1 !== i_io_resp_strong_bias_1) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_strong_bias_1 g=%h i=%h", $time, g_io_resp_strong_bias_1, i_io_resp_strong_bias_1); end
    if (g_io_resp_hit !== i_io_resp_hit) begin errors++;
      if(errors<=20) $display("[%0t] io_resp_hit g=%h i=%h", $time, g_io_resp_hit, i_io_resp_hit); end
    if (g_io_update_hit !== i_io_update_hit) begin errors++;
      if(errors<=20) $display("[%0t] io_update_hit g=%h i=%h", $time, g_io_update_hit, i_io_update_hit); end
  end
  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
