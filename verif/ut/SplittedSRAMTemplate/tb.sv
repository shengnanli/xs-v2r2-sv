// SplittedSRAMTemplate UT：golden vs _xs 双例化随机比对（两者均例化 golden 内层
// SRAMTemplate，故测的是 Splitted 层的 way 分配/拆拼/bore 路由）。内层有 reset 清零
// FSM，等清零后比对。
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
  logic [6:0]  r_setIdx, w_setIdx;
  logic [35:0] wd0_tag, wd1_tag, wd2_tag, wd3_tag;
  logic        wd0_c, wd1_c, wd2_c, wd3_c;
  logic [3:0]  waymask;
  // 两套 bore（多数时间 ack=0）
  logic [7:0]  b0_addr, b0_addr_rd, b1_addr, b1_addr_rd;
  logic [73:0] b0_wdata, b1_wdata;
  logic [1:0]  b0_wmask, b1_wmask;
  logic        b0_re, b0_we, b0_ack, b0_sel, b1_re, b1_we, b1_ack, b1_sel;

  wire        g_ready, i_ready;
  wire [35:0] g_d0t,g_d1t,g_d2t,g_d3t, i_d0t,i_d1t,i_d2t,i_d3t;
  wire        g_d0c,g_d1c,g_d2c,g_d3c, i_d0c,i_d1c,i_d2c,i_d3c;
  wire [73:0] g_b0rd,g_b1rd, i_b0rd,i_b1rd;

  `define PORTS(RDY,D0T,D0C,D1T,D1C,D2T,D2C,D3T,D3C,B0RD,B1RD) \
    .clock(clk), .reset(rst), \
    .io_r_req_ready(RDY), .io_r_req_valid(r_valid), .io_r_req_bits_setIdx(r_setIdx), \
    .io_r_resp_data_0_meta_tag(D0T), .io_r_resp_data_0_code(D0C), \
    .io_r_resp_data_1_meta_tag(D1T), .io_r_resp_data_1_code(D1C), \
    .io_r_resp_data_2_meta_tag(D2T), .io_r_resp_data_2_code(D2C), \
    .io_r_resp_data_3_meta_tag(D3T), .io_r_resp_data_3_code(D3C), \
    .io_w_req_valid(w_valid), .io_w_req_bits_setIdx(w_setIdx), \
    .io_w_req_bits_data_0_meta_tag(wd0_tag), .io_w_req_bits_data_0_code(wd0_c), \
    .io_w_req_bits_data_1_meta_tag(wd1_tag), .io_w_req_bits_data_1_code(wd1_c), \
    .io_w_req_bits_data_2_meta_tag(wd2_tag), .io_w_req_bits_data_2_code(wd2_c), \
    .io_w_req_bits_data_3_meta_tag(wd3_tag), .io_w_req_bits_data_3_code(wd3_c), \
    .io_w_req_bits_waymask(waymask), \
    .boreChildrenBd_bore_addr(b0_addr), .boreChildrenBd_bore_addr_rd(b0_addr_rd), \
    .boreChildrenBd_bore_wdata(b0_wdata), .boreChildrenBd_bore_wmask(b0_wmask), \
    .boreChildrenBd_bore_re(b0_re), .boreChildrenBd_bore_we(b0_we), \
    .boreChildrenBd_bore_rdata(B0RD), .boreChildrenBd_bore_ack(b0_ack), \
    .boreChildrenBd_bore_selectedOH(b0_sel), .boreChildrenBd_bore_array(1'b0), \
    .boreChildrenBd_bore_1_addr(b1_addr), .boreChildrenBd_bore_1_addr_rd(b1_addr_rd), \
    .boreChildrenBd_bore_1_wdata(b1_wdata), .boreChildrenBd_bore_1_wmask(b1_wmask), \
    .boreChildrenBd_bore_1_re(b1_re), .boreChildrenBd_bore_1_we(b1_we), \
    .boreChildrenBd_bore_1_rdata(B1RD), .boreChildrenBd_bore_1_ack(b1_ack), \
    .boreChildrenBd_bore_1_selectedOH(b1_sel), .boreChildrenBd_bore_1_array(1'b0), \
    .sigFromSrams_bore_ram_hold(1'b0), .sigFromSrams_bore_ram_bypass(1'b0), \
    .sigFromSrams_bore_ram_bp_clken(1'b0), .sigFromSrams_bore_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_ram_aux_ckbp(1'b0), .sigFromSrams_bore_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_cgen(1'b0), \
    .sigFromSrams_bore_1_ram_hold(1'b0), .sigFromSrams_bore_1_ram_bypass(1'b0), \
    .sigFromSrams_bore_1_ram_bp_clken(1'b0), .sigFromSrams_bore_1_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_1_ram_aux_ckbp(1'b0), .sigFromSrams_bore_1_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_1_cgen(1'b0)

  SplittedSRAMTemplate    u_g (`PORTS(g_ready,g_d0t,g_d0c,g_d1t,g_d1c,g_d2t,g_d2c,g_d3t,g_d3c,g_b0rd,g_b1rd));
  SplittedSRAMTemplate_xs u_i (`PORTS(i_ready,i_d0t,i_d0c,i_d1t,i_d1c,i_d2t,i_d2c,i_d3t,i_d3c,i_b0rd,i_b1rd));

  always @(negedge clk) begin
    if (rst) begin
      r_valid<=0; w_valid<=0; b0_ack<=0; b1_ack<=0; b0_re<=0; b0_we<=0; b1_re<=0; b1_we<=0;
    end else begin
      r_valid <= ($urandom_range(0,3)!=0);
      w_valid <= ($urandom_range(0,2)==0);
      r_setIdx<= 7'($urandom); w_setIdx<= 7'($urandom);
      wd0_tag<=36'($urandom); wd1_tag<=36'($urandom); wd2_tag<=36'($urandom); wd3_tag<=36'($urandom);
      wd0_c<=$urandom; wd1_c<=$urandom; wd2_c<=$urandom; wd3_c<=$urandom;
      waymask<=4'($urandom);
      b0_ack<=($urandom_range(0,7)==0); b1_ack<=($urandom_range(0,7)==0);
      b0_re<=$urandom; b0_we<=$urandom; b1_re<=$urandom; b1_we<=$urandom;
      b0_addr<=8'($urandom); b0_addr_rd<=8'($urandom); b1_addr<=8'($urandom); b1_addr_rd<=8'($urandom);
      b0_wdata<={$urandom,$urandom,10'($urandom)}; b1_wdata<={$urandom,$urandom,10'($urandom)};
      b0_wmask<=2'($urandom); b1_wmask<=2'($urandom); b0_sel<=$urandom; b1_sel<=$urandom;
    end
  end

  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    if (g_ready!==i_ready) begin errors++; $display("[%0t] ready g=%b i=%b",$time,g_ready,i_ready); end
    if ({g_d0t,g_d0c,g_d1t,g_d1c,g_d2t,g_d2c,g_d3t,g_d3c} !== {i_d0t,i_d0c,i_d1t,i_d1c,i_d2t,i_d2c,i_d3t,i_d3c})
      begin errors++; if(errors<=20) $display("[%0t] rdata mismatch",$time); end
    if (g_b0rd!==i_b0rd || g_b1rd!==i_b1rd) begin errors++; if(errors<=20) $display("[%0t] bore_rd mismatch",$time); end
  end

  initial begin
    rst=1; repeat(5) @(posedge clk); rst=0;
    repeat(NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
