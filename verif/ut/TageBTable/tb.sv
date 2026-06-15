// TageBTable UT：golden vs _xs 双例化随机比对（两者共用 golden 子模块
// FoldedSRAMTemplate_20 / WrBypass_32，故测的是 TageBTable 层：索引、slot↔way 交织、
// 2bit 饱和计数更新、写旁路接线、上电清零）。WARMUP > 2048 等 doing_reset 清零完成。
// +define+SYNTHESIS 关内层断言/随机初始化。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  int unsigned WARMUP  = 2200;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  logic        req_valid, um0, um1, ut0, ut1;
  logic [49:0] req_pc, upd_pc;
  logic [1:0]  uc0, uc1;
  // 2 套 bore（多数时间 ack=0）
  logic [8:0]  b0_addr,b0_ard,b1_addr,b1_ard;
  logic [15:0] b0_wd,b1_wd;
  logic [7:0]  b0_wm,b1_wm;
  logic [6:0]  b0_ar,b1_ar;
  logic        b0_re,b0_we,b0_ack,b0_sel,b1_re,b1_we,b1_ack,b1_sel;
  int unsigned mb0,mb1;

  wire        g_rdy,i_rdy;
  wire [1:0]  g_c0,g_c1,i_c0,i_c1;
  wire [15:0] g_b0rd,g_b1rd,i_b0rd,i_b1rd;

  `define PORTS(RDY,C0,C1,B0RD,B1RD) \
    .clock(clk), .reset(rst), .io_req_ready(RDY), \
    .io_req_valid(req_valid), .io_req_bits(req_pc), \
    .io_s1_cnt_0(C0), .io_s1_cnt_1(C1), \
    .io_update_mask_0(um0), .io_update_mask_1(um1), .io_update_pc(upd_pc), \
    .io_update_cnt_0(uc0), .io_update_cnt_1(uc1), \
    .io_update_takens_0(ut0), .io_update_takens_1(ut1), \
    .boreChildrenBd_bore_addr(b0_addr), .boreChildrenBd_bore_addr_rd(b0_ard), \
    .boreChildrenBd_bore_wdata(b0_wd), .boreChildrenBd_bore_wmask(b0_wm), \
    .boreChildrenBd_bore_re(b0_re), .boreChildrenBd_bore_we(b0_we), \
    .boreChildrenBd_bore_rdata(B0RD), .boreChildrenBd_bore_ack(b0_ack), \
    .boreChildrenBd_bore_selectedOH(b0_sel), .boreChildrenBd_bore_array(b0_ar), \
    .boreChildrenBd_bore_1_addr(b1_addr), .boreChildrenBd_bore_1_addr_rd(b1_ard), \
    .boreChildrenBd_bore_1_wdata(b1_wd), .boreChildrenBd_bore_1_wmask(b1_wm), \
    .boreChildrenBd_bore_1_re(b1_re), .boreChildrenBd_bore_1_we(b1_we), \
    .boreChildrenBd_bore_1_rdata(B1RD), .boreChildrenBd_bore_1_ack(b1_ack), \
    .boreChildrenBd_bore_1_selectedOH(b1_sel), .boreChildrenBd_bore_1_array(b1_ar), \
    .sigFromSrams_bore_ram_hold(1'b0), .sigFromSrams_bore_ram_bypass(1'b0), \
    .sigFromSrams_bore_ram_bp_clken(1'b0), .sigFromSrams_bore_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_ram_aux_ckbp(1'b0), .sigFromSrams_bore_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_cgen(1'b0), \
    .sigFromSrams_bore_1_ram_hold(1'b0), .sigFromSrams_bore_1_ram_bypass(1'b0), \
    .sigFromSrams_bore_1_ram_bp_clken(1'b0), .sigFromSrams_bore_1_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_1_ram_aux_ckbp(1'b0), .sigFromSrams_bore_1_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_1_cgen(1'b0)

  TageBTable    u_g (`PORTS(g_rdy,g_c0,g_c1,g_b0rd,g_b1rd));
  TageBTable_xs u_i (`PORTS(i_rdy,i_c0,i_c1,i_b0rd,i_b1rd));

  always @(negedge clk) begin
    if (rst) begin
      req_valid<=0; um0<=0; um1<=0; b0_ack<=0; b1_ack<=0; b0_re<=0;b0_we<=0;b1_re<=0;b1_we<=0;
    end else begin
      req_valid <= ($urandom_range(0,3)!=0);
      req_pc    <= 50'($urandom);
      um0<=($urandom_range(0,2)==0); um1<=($urandom_range(0,2)==0);
      upd_pc<=50'($urandom); uc0<=2'($urandom); uc1<=2'($urandom);
      ut0<=$urandom; ut1<=$urandom;
      b0_ack<=($urandom_range(0,7)==0); b1_ack<=($urandom_range(0,7)==0);
      mb0=$urandom_range(0,3); b0_re<=(mb0==0); b0_we<=(mb0==1);
      mb1=$urandom_range(0,3); b1_re<=(mb1==0); b1_we<=(mb1==1);
      b0_addr<=9'($urandom);b0_ard<=9'($urandom);b1_addr<=9'($urandom);b1_ard<=9'($urandom);
      b0_wd<=16'($urandom);b1_wd<=16'($urandom);b0_wm<=8'($urandom);b1_wm<=8'($urandom);
      b0_ar<=7'($urandom);b1_ar<=7'($urandom);b0_sel<=$urandom;b1_sel<=$urandom;
    end
  end

  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    if (g_rdy!==i_rdy) begin errors++; if(errors<=20) $display("[%0t] rdy g=%b i=%b",$time,g_rdy,i_rdy); end
    if (g_c0!==i_c0) begin errors++; if(errors<=20) $display("[%0t] c0 g=%h i=%h",$time,g_c0,i_c0); end
    if (g_c1!==i_c1) begin errors++; if(errors<=20) $display("[%0t] c1 g=%h i=%h",$time,g_c1,i_c1); end
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
