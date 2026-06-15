// FoldedSRAMTemplate UT：golden vs _xs（均例化 golden 内层 SplittedSRAMTemplate_3）。
// 测折叠层：raddr/ridx 拆分、ridx 寄存 + holdRidx 保持、waymask 按组展开、读 mux 选组。
// width=8，逻辑 2048set×2way×1b。
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
  logic [10:0] r_setIdx, w_setIdx;
  logic        wd0, wd1;
  logic [1:0]  waymask;
  logic [8:0]  b_addr, b_addr_rd;
  logic [15:0] b_wdata, b_wmask;
  logic        b_re, b_we, b_ack, b_sel;

  wire        g_ready, i_ready;
  wire        g_d0,g_d1, i_d0,i_d1;
  wire [15:0] g_brd, i_brd;

  `define PORTS(RDY,D0,D1,BRD) \
    .clock(clk), .reset(rst), \
    .io_r_req_ready(RDY), .io_r_req_valid(r_valid), .io_r_req_bits_setIdx(r_setIdx), \
    .io_r_resp_data_0(D0), .io_r_resp_data_1(D1), \
    .io_w_req_valid(w_valid), .io_w_req_bits_setIdx(w_setIdx), \
    .io_w_req_bits_data_0(wd0), .io_w_req_bits_data_1(wd1), \
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

  FoldedSRAMTemplate    u_g (`PORTS(g_ready,g_d0,g_d1,g_brd));
  FoldedSRAMTemplate_xs u_i (`PORTS(i_ready,i_d0,i_d1,i_brd));

  always @(negedge clk) begin
    if (rst) begin
      r_valid<=0; w_valid<=0; b_ack<=0; b_re<=0; b_we<=0; xrst<=0;
    end else begin
      r_valid <= ($urandom_range(0,3)!=0);
      w_valid <= ($urandom_range(0,2)==0);
      xrst    <= ($urandom_range(0,127)==0);
      r_setIdx<= 11'($urandom); w_setIdx<= 11'($urandom);
      wd0<=$urandom; wd1<=$urandom; waymask<=2'($urandom);
      b_ack<=($urandom_range(0,7)==0); b_re<=$urandom; b_we<=$urandom;
      b_addr<=9'($urandom); b_addr_rd<=9'($urandom);
      b_wdata<=16'($urandom); b_wmask<=16'($urandom); b_sel<=$urandom;
    end
  end

  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    if (g_ready!==i_ready) begin errors++; $display("[%0t] ready mismatch",$time); end
    if ({g_d0,g_d1} !== {i_d0,i_d1}) begin errors++; if(errors<=20) $display("[%0t] rdata mismatch g=%b%b i=%b%b",$time,g_d0,g_d1,i_d0,i_d1); end
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
