// SplittedSRAMTemplate_24 UT：golden vs _xs（均例化 golden 内层 SRAMTemplate_70）。
// 测 ITTAGE 条目 struct 打包/解包 + 逐位写掩码 bitmask 的按路铺开。
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
  logic [8:0]  wd0_tag, wd1_tag;
  logic [1:0]  wd0_ctr, wd1_ctr;
  logic [19:0] wd0_off, wd1_off;
  logic [3:0]  wd0_ptr, wd1_ptr;
  logic        wd0_upc, wd1_upc, wd0_uf, wd1_uf;
  logic [1:0]  waymask;
  logic [37:0] bitmask;
  logic [7:0]  b_addr, b_addr_rd;
  logic [75:0] b_wdata, b_wmask;
  logic        b_re, b_we, b_ack, b_sel;

  wire        g_ready, i_ready;
  wire        g_v0,g_v1, i_v0,i_v1;
  wire [8:0]  g_t0,g_t1, i_t0,i_t1;
  wire [1:0]  g_c0,g_c1, i_c0,i_c1;
  wire [19:0] g_o0,g_o1, i_o0,i_o1;
  wire [3:0]  g_p0,g_p1, i_p0,i_p1;
  wire        g_u0,g_u1, i_u0,i_u1;
  wire        g_f0,g_f1, i_f0,i_f1;
  wire [75:0] g_brd, i_brd;

  `define PORTS(RDY,V0,T0,C0,O0,P0,U0,F0,V1,T1,C1,O1,P1,U1,F1,BRD) \
    .clock(clk), .reset(rst), \
    .io_r_req_ready(RDY), .io_r_req_valid(r_valid), .io_r_req_bits_setIdx(r_setIdx), \
    .io_r_resp_data_0_valid(V0), .io_r_resp_data_0_tag(T0), .io_r_resp_data_0_ctr(C0), \
    .io_r_resp_data_0_target_offset_offset(O0), .io_r_resp_data_0_target_offset_pointer(P0), \
    .io_r_resp_data_0_target_offset_usePCRegion(U0), .io_r_resp_data_0_useful(F0), \
    .io_r_resp_data_1_valid(V1), .io_r_resp_data_1_tag(T1), .io_r_resp_data_1_ctr(C1), \
    .io_r_resp_data_1_target_offset_offset(O1), .io_r_resp_data_1_target_offset_pointer(P1), \
    .io_r_resp_data_1_target_offset_usePCRegion(U1), .io_r_resp_data_1_useful(F1), \
    .io_w_req_valid(w_valid), .io_w_req_bits_setIdx(w_setIdx), \
    .io_w_req_bits_data_0_tag(wd0_tag), .io_w_req_bits_data_0_ctr(wd0_ctr), \
    .io_w_req_bits_data_0_target_offset_offset(wd0_off), \
    .io_w_req_bits_data_0_target_offset_pointer(wd0_ptr), \
    .io_w_req_bits_data_0_target_offset_usePCRegion(wd0_upc), .io_w_req_bits_data_0_useful(wd0_uf), \
    .io_w_req_bits_data_1_tag(wd1_tag), .io_w_req_bits_data_1_ctr(wd1_ctr), \
    .io_w_req_bits_data_1_target_offset_offset(wd1_off), \
    .io_w_req_bits_data_1_target_offset_pointer(wd1_ptr), \
    .io_w_req_bits_data_1_target_offset_usePCRegion(wd1_upc), .io_w_req_bits_data_1_useful(wd1_uf), \
    .io_w_req_bits_waymask(waymask), .io_w_req_bits_bitmask(bitmask), \
    .boreChildrenBd_bore_addr(b_addr), .boreChildrenBd_bore_addr_rd(b_addr_rd), \
    .boreChildrenBd_bore_wdata(b_wdata), .boreChildrenBd_bore_wmask(b_wmask), \
    .boreChildrenBd_bore_re(b_re), .boreChildrenBd_bore_we(b_we), \
    .boreChildrenBd_bore_rdata(BRD), .boreChildrenBd_bore_ack(b_ack), \
    .boreChildrenBd_bore_selectedOH(b_sel), .boreChildrenBd_bore_array(7'h0), \
    .sigFromSrams_bore_ram_hold(1'b0), .sigFromSrams_bore_ram_bypass(1'b0), \
    .sigFromSrams_bore_ram_bp_clken(1'b0), .sigFromSrams_bore_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_ram_aux_ckbp(1'b0), .sigFromSrams_bore_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_cgen(1'b0)

  SplittedSRAMTemplate_24    u_g (`PORTS(g_ready,g_v0,g_t0,g_c0,g_o0,g_p0,g_u0,g_f0,g_v1,g_t1,g_c1,g_o1,g_p1,g_u1,g_f1,g_brd));
  SplittedSRAMTemplate_24_xs u_i (`PORTS(i_ready,i_v0,i_t0,i_c0,i_o0,i_p0,i_u0,i_f0,i_v1,i_t1,i_c1,i_o1,i_p1,i_u1,i_f1,i_brd));

  always @(negedge clk) begin
    if (rst) begin
      r_valid<=0; w_valid<=0; b_ack<=0; b_re<=0; b_we<=0;
    end else begin
      r_valid <= ($urandom_range(0,3)!=0);
      w_valid <= ($urandom_range(0,2)==0);
      r_setIdx<= 7'($urandom); w_setIdx<= 7'($urandom);
      wd0_tag<=9'($urandom); wd1_tag<=9'($urandom);
      wd0_ctr<=2'($urandom); wd1_ctr<=2'($urandom);
      wd0_off<=20'($urandom); wd1_off<=20'($urandom);
      wd0_ptr<=4'($urandom); wd1_ptr<=4'($urandom);
      wd0_upc<=$urandom; wd1_upc<=$urandom; wd0_uf<=$urandom; wd1_uf<=$urandom;
      waymask<=2'($urandom);
      bitmask<={6'($urandom),$urandom};  // 随机逐位掩码（含常见全 1 情况）
      if ($urandom_range(0,1)) bitmask<=38'h3fffffffff;
      b_ack<=($urandom_range(0,7)==0); b_re<=$urandom; b_we<=$urandom;
      b_addr<=8'($urandom); b_addr_rd<=8'($urandom);
      b_wdata<={$urandom,$urandom,12'($urandom)};
      b_wmask<={$urandom,$urandom,12'($urandom)}; b_sel<=$urandom;
    end
  end

  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    if (g_ready!==i_ready) begin errors++; $display("[%0t] ready mismatch",$time); end
    if ({g_v0,g_t0,g_c0,g_o0,g_p0,g_u0,g_f0,g_v1,g_t1,g_c1,g_o1,g_p1,g_u1,g_f1} !==
        {i_v0,i_t0,i_c0,i_o0,i_p0,i_u0,i_f0,i_v1,i_t1,i_c1,i_o1,i_p1,i_u1,i_f1})
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
