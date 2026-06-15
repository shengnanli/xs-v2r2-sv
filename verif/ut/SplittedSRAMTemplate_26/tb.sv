// SplittedSRAMTemplate_26 UT：golden vs _xs（均例化 golden 内层 SRAMTemplate_72）。
// 测 ITTAGE 4way + dataSplit=2（高低半切片）+ 逐位 bitmask 按数据维/路铺开 + 双 bore。
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
  logic [8:0]  wtag  [4];
  logic [1:0]  wctr  [4];
  logic [19:0] woff  [4];
  logic [3:0]  wptr  [4];
  logic        wupc  [4], wuf [4];
  logic [3:0]  waymask;
  logic [37:0] bitmask;
  logic [7:0]  b0_addr,b0_addr_rd, b1_addr,b1_addr_rd;
  logic [75:0] b0_wdata,b0_wmask, b1_wdata,b1_wmask;
  logic        b0_re,b0_we,b0_ack,b0_sel, b1_re,b1_we,b1_ack,b1_sel;

  wire        g_ready, i_ready;
  wire        g_v[4], i_v[4];
  wire [8:0]  g_t[4], i_t[4];
  wire [1:0]  g_c[4], i_c[4];
  wire [19:0] g_o[4], i_o[4];
  wire [3:0]  g_p[4], i_p[4];
  wire        g_u[4], i_u[4];
  wire        g_f[4], i_f[4];
  wire [75:0] g_b0rd,g_b1rd, i_b0rd,i_b1rd;

  `define WAYW(N) \
    .io_w_req_bits_data_``N``_tag(wtag[N]), .io_w_req_bits_data_``N``_ctr(wctr[N]), \
    .io_w_req_bits_data_``N``_target_offset_offset(woff[N]), \
    .io_w_req_bits_data_``N``_target_offset_pointer(wptr[N]), \
    .io_w_req_bits_data_``N``_target_offset_usePCRegion(wupc[N]), \
    .io_w_req_bits_data_``N``_useful(wuf[N])
  `define WAYR(N,V,T,C,O,P,U,F) \
    .io_r_resp_data_``N``_valid(V[N]), .io_r_resp_data_``N``_tag(T[N]), \
    .io_r_resp_data_``N``_ctr(C[N]), .io_r_resp_data_``N``_target_offset_offset(O[N]), \
    .io_r_resp_data_``N``_target_offset_pointer(P[N]), \
    .io_r_resp_data_``N``_target_offset_usePCRegion(U[N]), .io_r_resp_data_``N``_useful(F[N])

  `define PORTS(RDY,V,T,C,O,P,U,F,B0,B1) \
    .clock(clk), .reset(rst), \
    .io_r_req_ready(RDY), .io_r_req_valid(r_valid), .io_r_req_bits_setIdx(r_setIdx), \
    `WAYR(0,V,T,C,O,P,U,F), `WAYR(1,V,T,C,O,P,U,F), \
    `WAYR(2,V,T,C,O,P,U,F), `WAYR(3,V,T,C,O,P,U,F), \
    .io_w_req_valid(w_valid), .io_w_req_bits_setIdx(w_setIdx), \
    `WAYW(0), `WAYW(1), `WAYW(2), `WAYW(3), \
    .io_w_req_bits_waymask(waymask), .io_w_req_bits_bitmask(bitmask), \
    .boreChildrenBd_bore_addr(b0_addr), .boreChildrenBd_bore_addr_rd(b0_addr_rd), \
    .boreChildrenBd_bore_wdata(b0_wdata), .boreChildrenBd_bore_wmask(b0_wmask), \
    .boreChildrenBd_bore_re(b0_re), .boreChildrenBd_bore_we(b0_we), \
    .boreChildrenBd_bore_rdata(B0), .boreChildrenBd_bore_ack(b0_ack), \
    .boreChildrenBd_bore_selectedOH(b0_sel), .boreChildrenBd_bore_array(7'h0), \
    .boreChildrenBd_bore_1_addr(b1_addr), .boreChildrenBd_bore_1_addr_rd(b1_addr_rd), \
    .boreChildrenBd_bore_1_wdata(b1_wdata), .boreChildrenBd_bore_1_wmask(b1_wmask), \
    .boreChildrenBd_bore_1_re(b1_re), .boreChildrenBd_bore_1_we(b1_we), \
    .boreChildrenBd_bore_1_rdata(B1), .boreChildrenBd_bore_1_ack(b1_ack), \
    .boreChildrenBd_bore_1_selectedOH(b1_sel), .boreChildrenBd_bore_1_array(7'h0), \
    .sigFromSrams_bore_ram_hold(1'b0), .sigFromSrams_bore_ram_bypass(1'b0), \
    .sigFromSrams_bore_ram_bp_clken(1'b0), .sigFromSrams_bore_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_ram_aux_ckbp(1'b0), .sigFromSrams_bore_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_cgen(1'b0), \
    .sigFromSrams_bore_1_ram_hold(1'b0), .sigFromSrams_bore_1_ram_bypass(1'b0), \
    .sigFromSrams_bore_1_ram_bp_clken(1'b0), .sigFromSrams_bore_1_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_1_ram_aux_ckbp(1'b0), .sigFromSrams_bore_1_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_1_cgen(1'b0)

  SplittedSRAMTemplate_26    u_g (`PORTS(g_ready,g_v,g_t,g_c,g_o,g_p,g_u,g_f,g_b0rd,g_b1rd));
  SplittedSRAMTemplate_26_xs u_i (`PORTS(i_ready,i_v,i_t,i_c,i_o,i_p,i_u,i_f,i_b0rd,i_b1rd));

  int k;
  always @(negedge clk) begin
    if (rst) begin
      r_valid<=0; w_valid<=0; b0_ack<=0; b1_ack<=0; b0_re<=0; b0_we<=0; b1_re<=0; b1_we<=0;
    end else begin
      r_valid <= ($urandom_range(0,3)!=0);
      w_valid <= ($urandom_range(0,2)==0);
      r_setIdx<= 7'($urandom); w_setIdx<= 7'($urandom);
      for (k=0;k<4;k++) begin
        wtag[k]<=9'($urandom); wctr[k]<=2'($urandom); woff[k]<=20'($urandom);
        wptr[k]<=4'($urandom); wupc[k]<=$urandom; wuf[k]<=$urandom;
      end
      waymask<=4'($urandom);
      bitmask<={6'($urandom),$urandom};
      if ($urandom_range(0,1)) bitmask<=38'h3fffffffff;
      b0_ack<=($urandom_range(0,7)==0); b1_ack<=($urandom_range(0,7)==0);
      b0_re<=$urandom; b0_we<=$urandom; b1_re<=$urandom; b1_we<=$urandom;
      b0_addr<=8'($urandom); b0_addr_rd<=8'($urandom); b1_addr<=8'($urandom); b1_addr_rd<=8'($urandom);
      b0_wdata<={$urandom,$urandom,12'($urandom)}; b0_wmask<={$urandom,$urandom,12'($urandom)};
      b1_wdata<={$urandom,$urandom,12'($urandom)}; b1_wmask<={$urandom,$urandom,12'($urandom)};
      b0_sel<=$urandom; b1_sel<=$urandom;
    end
  end

  int j;
  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    if (g_ready!==i_ready) begin errors++; $display("[%0t] ready mismatch",$time); end
    for (j=0;j<4;j++)
      if ({g_v[j],g_t[j],g_c[j],g_o[j],g_p[j],g_u[j],g_f[j]} !==
          {i_v[j],i_t[j],i_c[j],i_o[j],i_p[j],i_u[j],i_f[j]})
        begin errors++; if(errors<=20) $display("[%0t] rdata way%0d mismatch",$time,j); end
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
