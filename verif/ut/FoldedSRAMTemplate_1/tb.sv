// FoldedSRAMTemplate_1 UT：golden vs _xs 双例化随机比对（width=1 直通）。
// 两侧共用 golden 内层 SplittedSRAMTemplate_4 → SRAMTemplate_45(bp_tage)。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  int unsigned WARMUP  = 600;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  logic        r_valid, w_valid;
  logic [8:0]  r_setIdx, w_setIdx;
  logic [7:0]  wd0_tag, wd1_tag;
  logic [2:0]  wd0_ctr, wd1_ctr;
  logic [1:0]  waymask;
  logic [9:0]  b_addr, b_addr_rd;
  logic [23:0] b_wdata;
  logic [1:0]  b_wmask;
  logic        b_re, b_we, b_ack, b_sel;
  logic [5:0]  b_array;

  wire        g_ready, i_ready;
  wire        g_d0v,g_d1v, i_d0v,i_d1v;
  wire [7:0]  g_d0t,g_d1t, i_d0t,i_d1t;
  wire [2:0]  g_d0c,g_d1c, i_d0c,i_d1c;
  wire [23:0] g_brd, i_brd;

  `define PORTS(RDY,D0V,D0T,D0C,D1V,D1T,D1C,BRD) \
    .clock(clk), .reset(rst), \
    .io_r_req_ready(RDY), .io_r_req_valid(r_valid), .io_r_req_bits_setIdx(r_setIdx), \
    .io_r_resp_data_0_valid(D0V), .io_r_resp_data_0_tag(D0T), .io_r_resp_data_0_ctr(D0C), \
    .io_r_resp_data_1_valid(D1V), .io_r_resp_data_1_tag(D1T), .io_r_resp_data_1_ctr(D1C), \
    .io_w_req_valid(w_valid), .io_w_req_bits_setIdx(w_setIdx), \
    .io_w_req_bits_data_0_tag(wd0_tag), .io_w_req_bits_data_0_ctr(wd0_ctr), \
    .io_w_req_bits_data_1_tag(wd1_tag), .io_w_req_bits_data_1_ctr(wd1_ctr), \
    .io_w_req_bits_waymask(waymask), \
    .boreChildrenBd_bore_addr(b_addr), .boreChildrenBd_bore_addr_rd(b_addr_rd), \
    .boreChildrenBd_bore_wdata(b_wdata), .boreChildrenBd_bore_wmask(b_wmask), \
    .boreChildrenBd_bore_re(b_re), .boreChildrenBd_bore_we(b_we), \
    .boreChildrenBd_bore_rdata(BRD), .boreChildrenBd_bore_ack(b_ack), \
    .boreChildrenBd_bore_selectedOH(b_sel), .boreChildrenBd_bore_array(b_array), \
    .sigFromSrams_bore_ram_hold(1'b0), .sigFromSrams_bore_ram_bypass(1'b0), \
    .sigFromSrams_bore_ram_bp_clken(1'b0), .sigFromSrams_bore_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_ram_aux_ckbp(1'b0), .sigFromSrams_bore_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_cgen(1'b0)

  FoldedSRAMTemplate_1    u_g (`PORTS(g_ready,g_d0v,g_d0t,g_d0c,g_d1v,g_d1t,g_d1c,g_brd));
  FoldedSRAMTemplate_1_xs u_i (`PORTS(i_ready,i_d0v,i_d0t,i_d0c,i_d1v,i_d1t,i_d1c,i_brd));

  always @(negedge clk) begin
    if (rst) begin
      r_valid<=0; w_valid<=0; b_ack<=0; b_re<=0; b_we<=0;
    end else begin
      r_valid <= ($urandom_range(0,3)!=0);
      w_valid <= ($urandom_range(0,2)==0);
      r_setIdx<= 9'($urandom); w_setIdx<= 9'($urandom);
      wd0_tag<=8'($urandom); wd1_tag<=8'($urandom);
      wd0_ctr<=3'($urandom); wd1_ctr<=3'($urandom);
      waymask<=2'($urandom);
      b_ack<=($urandom_range(0,7)==0);
      b_re<=$urandom; b_we<=$urandom;
      b_addr<=10'($urandom); b_addr_rd<=10'($urandom);
      b_wdata<={$urandom,$urandom}; b_wmask<=2'($urandom); b_array<=6'($urandom); b_sel<=$urandom;
    end
  end

  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    if (g_ready!==i_ready) begin errors++; if(errors<=20) $display("[%0t] ready g=%b i=%b",$time,g_ready,i_ready); end
    if ({g_d0v,g_d0t,g_d0c,g_d1v,g_d1t,g_d1c} !== {i_d0v,i_d0t,i_d0c,i_d1v,i_d1t,i_d1c})
      begin errors++; if(errors<=20) $display("[%0t] rdata mismatch",$time); end
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
