// SplittedSRAMTemplate_3 UT：golden vs _xs（均例化 golden 内层 SRAMTemplate_44）。
// 纯透传层（16way×1b，带 extra_reset），测端口直连正确性。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  int unsigned WARMUP  = 400;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  logic        r_valid, w_valid, xrst;
  logic [7:0]  r_setIdx, w_setIdx;
  logic [15:0] wdata, waymask;
  logic [8:0]  b_addr, b_addr_rd;
  logic [15:0] b_wdata, b_wmask;
  logic        b_re, b_we, b_ack, b_sel;

  wire        g_ready, i_ready;
  wire [15:0] g_rd, i_rd;
  wire [15:0] g_brd, i_brd;

  `define PORTS(RDY,RD,BRD) \
    .clock(clk), .reset(rst), \
    .io_r_req_ready(RDY), .io_r_req_valid(r_valid), .io_r_req_bits_setIdx(r_setIdx), \
    .io_r_resp_data_0(RD[0]),  .io_r_resp_data_1(RD[1]), \
    .io_r_resp_data_2(RD[2]),  .io_r_resp_data_3(RD[3]), \
    .io_r_resp_data_4(RD[4]),  .io_r_resp_data_5(RD[5]), \
    .io_r_resp_data_6(RD[6]),  .io_r_resp_data_7(RD[7]), \
    .io_r_resp_data_8(RD[8]),  .io_r_resp_data_9(RD[9]), \
    .io_r_resp_data_10(RD[10]),.io_r_resp_data_11(RD[11]), \
    .io_r_resp_data_12(RD[12]),.io_r_resp_data_13(RD[13]), \
    .io_r_resp_data_14(RD[14]),.io_r_resp_data_15(RD[15]), \
    .io_w_req_valid(w_valid), .io_w_req_bits_setIdx(w_setIdx), \
    .io_w_req_bits_data_0(wdata[0]),  .io_w_req_bits_data_1(wdata[1]), \
    .io_w_req_bits_data_2(wdata[2]),  .io_w_req_bits_data_3(wdata[3]), \
    .io_w_req_bits_data_4(wdata[4]),  .io_w_req_bits_data_5(wdata[5]), \
    .io_w_req_bits_data_6(wdata[6]),  .io_w_req_bits_data_7(wdata[7]), \
    .io_w_req_bits_data_8(wdata[8]),  .io_w_req_bits_data_9(wdata[9]), \
    .io_w_req_bits_data_10(wdata[10]),.io_w_req_bits_data_11(wdata[11]), \
    .io_w_req_bits_data_12(wdata[12]),.io_w_req_bits_data_13(wdata[13]), \
    .io_w_req_bits_data_14(wdata[14]),.io_w_req_bits_data_15(wdata[15]), \
    .io_w_req_bits_waymask(waymask), .extra_reset(xrst), \
    .boreChildrenBd_bore_addr(b_addr), .boreChildrenBd_bore_addr_rd(b_addr_rd), \
    .boreChildrenBd_bore_wdata(b_wdata), .boreChildrenBd_bore_wmask(b_wmask), \
    .boreChildrenBd_bore_re(b_re), .boreChildrenBd_bore_we(b_we), \
    .boreChildrenBd_bore_rdata(BRD), .boreChildrenBd_bore_ack(b_ack), \
    .boreChildrenBd_bore_selectedOH(b_sel), .boreChildrenBd_bore_array(6'h0), \
    .sigFromSrams_bore_ram_hold(1'b0), .sigFromSrams_bore_ram_bypass(1'b0), \
    .sigFromSrams_bore_ram_bp_clken(1'b0), .sigFromSrams_bore_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_ram_aux_ckbp(1'b0), .sigFromSrams_bore_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_cgen(1'b0)

  SplittedSRAMTemplate_3    u_g (`PORTS(g_ready,g_rd,g_brd));
  SplittedSRAMTemplate_3_xs u_i (`PORTS(i_ready,i_rd,i_brd));

  always @(negedge clk) begin
    if (rst) begin
      r_valid<=0; w_valid<=0; b_ack<=0; b_re<=0; b_we<=0; xrst<=0;
    end else begin
      r_valid <= ($urandom_range(0,3)!=0);
      w_valid <= ($urandom_range(0,2)==0);
      xrst    <= ($urandom_range(0,63)==0);
      r_setIdx<= 8'($urandom); w_setIdx<= 8'($urandom);
      wdata<=16'($urandom); waymask<=16'($urandom);
      b_ack<=($urandom_range(0,7)==0); b_re<=$urandom; b_we<=$urandom;
      b_addr<=9'($urandom); b_addr_rd<=9'($urandom);
      b_wdata<=16'($urandom); b_wmask<=16'($urandom); b_sel<=$urandom;
    end
  end

  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    if (g_ready!==i_ready) begin errors++; $display("[%0t] ready mismatch",$time); end
    if (g_rd!==i_rd) begin errors++; if(errors<=20) $display("[%0t] rdata mismatch g=%h i=%h",$time,g_rd,i_rd); end
    if (g_brd!==i_brd) begin errors++; if(errors<=20) $display("[%0t] bore_rd mismatch",$time); end
  end

  initial begin
    rst=1; repeat(5) @(posedge clk); rst=0;
    repeat(NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
