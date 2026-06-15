// FoldedSRAMTemplate_21 UT：golden vs _xs（均例化 golden 内层 SplittedSRAMTemplate_24）。
// width=2，逻辑 256set×1way×38b ITTAGE。测折叠 + bitmask 透传 + holdRidx 二选一。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  int unsigned WARMUP  = 400;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  logic        r_valid, w_valid;
  logic [7:0]  r_setIdx, w_setIdx;
  logic [8:0]  wtag; logic [1:0] wctr; logic [19:0] woff; logic [3:0] wptr; logic wupc,wuf;
  logic [37:0] bitmask;
  logic [7:0]  b_addr, b_addr_rd;
  logic [75:0] b_wdata, b_wmask;
  logic        b_re, b_we, b_ack, b_sel;

  wire        g_ready, i_ready;
  wire        g_v,i_v; wire [8:0] g_t,i_t; wire [1:0] g_c,i_c; wire [19:0] g_o,i_o;
  wire [3:0]  g_p,i_p; wire g_u,i_u,g_f,i_f;
  wire [75:0] g_brd, i_brd;

  `define PORTS(RDY,V,T,C,O,P,U,F,BRD) \
    .clock(clk), .reset(rst), \
    .io_r_req_ready(RDY), .io_r_req_valid(r_valid), .io_r_req_bits_setIdx(r_setIdx), \
    .io_r_resp_data_0_valid(V), .io_r_resp_data_0_tag(T), .io_r_resp_data_0_ctr(C), \
    .io_r_resp_data_0_target_offset_offset(O), .io_r_resp_data_0_target_offset_pointer(P), \
    .io_r_resp_data_0_target_offset_usePCRegion(U), .io_r_resp_data_0_useful(F), \
    .io_w_req_valid(w_valid), .io_w_req_bits_setIdx(w_setIdx), \
    .io_w_req_bits_data_0_tag(wtag), .io_w_req_bits_data_0_ctr(wctr), \
    .io_w_req_bits_data_0_target_offset_offset(woff), \
    .io_w_req_bits_data_0_target_offset_pointer(wptr), \
    .io_w_req_bits_data_0_target_offset_usePCRegion(wupc), .io_w_req_bits_data_0_useful(wuf), \
    .io_w_req_bits_bitmask(bitmask), \
    .boreChildrenBd_bore_addr(b_addr), .boreChildrenBd_bore_addr_rd(b_addr_rd), \
    .boreChildrenBd_bore_wdata(b_wdata), .boreChildrenBd_bore_wmask(b_wmask), \
    .boreChildrenBd_bore_re(b_re), .boreChildrenBd_bore_we(b_we), \
    .boreChildrenBd_bore_rdata(BRD), .boreChildrenBd_bore_ack(b_ack), \
    .boreChildrenBd_bore_selectedOH(b_sel), .boreChildrenBd_bore_array(7'h0), \
    .sigFromSrams_bore_ram_hold(1'b0), .sigFromSrams_bore_ram_bypass(1'b0), \
    .sigFromSrams_bore_ram_bp_clken(1'b0), .sigFromSrams_bore_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_ram_aux_ckbp(1'b0), .sigFromSrams_bore_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_cgen(1'b0)

  FoldedSRAMTemplate_21    u_g (`PORTS(g_ready,g_v,g_t,g_c,g_o,g_p,g_u,g_f,g_brd));
  FoldedSRAMTemplate_21_xs u_i (`PORTS(i_ready,i_v,i_t,i_c,i_o,i_p,i_u,i_f,i_brd));

  always @(negedge clk) begin
    if (rst) begin
      r_valid<=0; w_valid<=0; b_ack<=0; b_re<=0; b_we<=0;
    end else begin
      r_valid <= ($urandom_range(0,3)!=0);
      w_valid <= ($urandom_range(0,2)==0);
      r_setIdx<= 8'($urandom); w_setIdx<= 8'($urandom);
      wtag<=9'($urandom); wctr<=2'($urandom); woff<=20'($urandom);
      wptr<=4'($urandom); wupc<=$urandom; wuf<=$urandom;
      bitmask<={6'($urandom),$urandom};
      if ($urandom_range(0,1)) bitmask<=38'h3fffffffff;
      b_ack<=($urandom_range(0,7)==0); b_re<=$urandom; b_we<=$urandom;
      b_addr<=8'($urandom); b_addr_rd<=8'($urandom);
      b_wdata<={$urandom,$urandom,12'($urandom)}; b_wmask<={$urandom,$urandom,12'($urandom)}; b_sel<=$urandom;
    end
  end

  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    if (g_ready!==i_ready) begin errors++; $display("[%0t] ready mismatch",$time); end
    if ({g_v,g_t,g_c,g_o,g_p,g_u,g_f} !== {i_v,i_t,i_c,i_o,i_p,i_u,i_f})
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
