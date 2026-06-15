// SplittedSRAMTemplate_23 UT：golden vs _xs 双例化随机比对（两者均例化 golden 内层
// SRAMTemplate_64，故测的是 Splitted_23 层的 setSplit=2 bank 路由 / ren_vec / Mux1H）。
// 内层 bp_tage_bt 无 reset 清零（读出 X 直到被写），两侧同源 → X===X 不算错。
// 编译带 +define+SYNTHESIS，关掉内层 ifndef SYNTHESIS 的读写同址断言与随机初始化。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  int unsigned WARMUP  = 200;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  logic        r_valid, w_valid;
  logic [8:0]  r_setIdx, w_setIdx;
  logic [1:0]  wd [8];
  logic [7:0]  waymask;
  logic [8:0]  b0_addr, b0_addr_rd, b1_addr, b1_addr_rd;
  logic [15:0] b0_wdata, b1_wdata;
  logic [7:0]  b0_wmask, b1_wmask;
  logic [6:0]  b0_array, b1_array;
  logic        b0_re, b0_we, b0_ack, b0_sel, b1_re, b1_we, b1_ack, b1_sel;
  int unsigned mb0, mb1;

  wire [1:0]  g_rd [8], i_rd [8];
  wire [15:0] g_b0rd, g_b1rd, i_b0rd, i_b1rd;

  `define PORTS(P,B0RD,B1RD) \
    .clock(clk), .reset(rst), \
    .io_r_req_valid(r_valid), .io_r_req_bits_setIdx(r_setIdx), \
    .io_r_resp_data_0(P``rd[0]), .io_r_resp_data_1(P``rd[1]), .io_r_resp_data_2(P``rd[2]), \
    .io_r_resp_data_3(P``rd[3]), .io_r_resp_data_4(P``rd[4]), .io_r_resp_data_5(P``rd[5]), \
    .io_r_resp_data_6(P``rd[6]), .io_r_resp_data_7(P``rd[7]), \
    .io_w_req_valid(w_valid), .io_w_req_bits_setIdx(w_setIdx), \
    .io_w_req_bits_data_0(wd[0]), .io_w_req_bits_data_1(wd[1]), .io_w_req_bits_data_2(wd[2]), \
    .io_w_req_bits_data_3(wd[3]), .io_w_req_bits_data_4(wd[4]), .io_w_req_bits_data_5(wd[5]), \
    .io_w_req_bits_data_6(wd[6]), .io_w_req_bits_data_7(wd[7]), \
    .io_w_req_bits_waymask(waymask), \
    .boreChildrenBd_bore_addr(b0_addr), .boreChildrenBd_bore_addr_rd(b0_addr_rd), \
    .boreChildrenBd_bore_wdata(b0_wdata), .boreChildrenBd_bore_wmask(b0_wmask), \
    .boreChildrenBd_bore_re(b0_re), .boreChildrenBd_bore_we(b0_we), \
    .boreChildrenBd_bore_rdata(B0RD), .boreChildrenBd_bore_ack(b0_ack), \
    .boreChildrenBd_bore_selectedOH(b0_sel), .boreChildrenBd_bore_array(b0_array), \
    .boreChildrenBd_bore_1_addr(b1_addr), .boreChildrenBd_bore_1_addr_rd(b1_addr_rd), \
    .boreChildrenBd_bore_1_wdata(b1_wdata), .boreChildrenBd_bore_1_wmask(b1_wmask), \
    .boreChildrenBd_bore_1_re(b1_re), .boreChildrenBd_bore_1_we(b1_we), \
    .boreChildrenBd_bore_1_rdata(B1RD), .boreChildrenBd_bore_1_ack(b1_ack), \
    .boreChildrenBd_bore_1_selectedOH(b1_sel), .boreChildrenBd_bore_1_array(b1_array), \
    .sigFromSrams_bore_ram_hold(1'b0), .sigFromSrams_bore_ram_bypass(1'b0), \
    .sigFromSrams_bore_ram_bp_clken(1'b0), .sigFromSrams_bore_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_ram_aux_ckbp(1'b0), .sigFromSrams_bore_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_cgen(1'b0), \
    .sigFromSrams_bore_1_ram_hold(1'b0), .sigFromSrams_bore_1_ram_bypass(1'b0), \
    .sigFromSrams_bore_1_ram_bp_clken(1'b0), .sigFromSrams_bore_1_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_1_ram_aux_ckbp(1'b0), .sigFromSrams_bore_1_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_1_cgen(1'b0)

  SplittedSRAMTemplate_23    u_g (`PORTS(g_, g_b0rd, g_b1rd));
  SplittedSRAMTemplate_23_xs u_i (`PORTS(i_, i_b0rd, i_b1rd));

  always @(negedge clk) begin
    if (rst) begin
      r_valid<=0; w_valid<=0; b0_ack<=0; b1_ack<=0; b0_re<=0; b0_we<=0; b1_re<=0; b1_we<=0;
    end else begin
      r_valid <= ($urandom_range(0,3)!=0);
      w_valid <= ($urandom_range(0,2)==0);
      r_setIdx<= 9'($urandom); w_setIdx<= 9'($urandom);
      for (int k=0;k<8;k++) wd[k] <= 2'($urandom);
      waymask <= 8'($urandom_range(1,255));
      // MBIST：每 bore re/we 互斥（即便 SYNTHESIS 关了断言也保持真实语义）
      b0_ack<=($urandom_range(0,7)==0); b1_ack<=($urandom_range(0,7)==0);
      mb0=$urandom_range(0,3); b0_re<=(mb0==0); b0_we<=(mb0==1);
      mb1=$urandom_range(0,3); b1_re<=(mb1==0); b1_we<=(mb1==1);
      b0_addr<=9'($urandom); b0_addr_rd<=9'($urandom); b1_addr<=9'($urandom); b1_addr_rd<=9'($urandom);
      b0_wdata<=16'($urandom); b1_wdata<=16'($urandom);
      b0_wmask<=8'($urandom); b1_wmask<=8'($urandom);
      b0_array<=7'($urandom); b1_array<=7'($urandom);
      b0_sel<=$urandom; b1_sel<=$urandom;
    end
  end

  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    for (int k=0;k<8;k++)
      if (g_rd[k]!==i_rd[k]) begin errors++; if(errors<=20) $display("[%0t] rd%0d g=%h i=%h",$time,k,g_rd[k],i_rd[k]); end
    if (g_b0rd!==i_b0rd) begin errors++; if(errors<=20) $display("[%0t] b0rd g=%h i=%h",$time,g_b0rd,i_b0rd); end
    if (g_b1rd!==i_b1rd) begin errors++; if(errors<=20) $display("[%0t] b1rd g=%h i=%h",$time,g_b1rd,i_b1rd); end
  end

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 40000;
    rst=1; repeat(5) @(posedge clk); rst=0;
    repeat(NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
