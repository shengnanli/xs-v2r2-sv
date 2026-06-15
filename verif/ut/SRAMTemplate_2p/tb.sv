// 双端口 SRAM UT：golden SRAMTemplate_66 vs 手写 SRAMTemplate_66_xs 双例化逐拍比对。
// 读/写两口可同拍激励（覆盖读写冲突缓冲）；MBIST re/we 驱动为互斥，避免触发 golden
// 内部「读写同址」$fatal 断言（该断言仅针对物理宏不允许的同址 R+W）。
`timescale 1ns/1ps
module tb;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  int unsigned NCYCLES = 40000;
  localparam int unsigned WARMUP = 400;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  // ---- 激励信号 ----
  logic        r_valid, w_valid;
  logic [7:0]  r_setIdx, w_setIdx;
  logic [5:0]  w_d0, w_d1, w_d2, w_d3;
  logic [3:0]  w_waymask;
  logic        b_hold, b_bypass, b_bpclken, b_auxclk, b_auxckbp, b_mcphold, b_cgen;
  logic [63:0] b_ctl;
  logic [8:0]  bore_addr, bore_addr_rd;
  logic [23:0] bore_wdata;
  logic [3:0]  bore_wmask;
  logic        bore_re, bore_we, bore_ack, bore_selOH;
  logic [6:0]  bore_array;
  int unsigned mb;   // MBIST 操作选择（保证 re/we 互斥）

  // ---- 输出（g=golden, i=impl）----
  wire [5:0]  g_rd0, g_rd1, g_rd2, g_rd3;  wire [23:0] g_brdata;
  wire [5:0]  i_rd0, i_rd1, i_rd2, i_rd3;  wire [23:0] i_brdata;

  `define PORTS(P) \
    .clock(clk), .reset(rst), \
    .io_r_req_valid(r_valid), .io_r_req_bits_setIdx(r_setIdx), \
    .io_r_resp_data_0(P``rd0), .io_r_resp_data_1(P``rd1), \
    .io_r_resp_data_2(P``rd2), .io_r_resp_data_3(P``rd3), \
    .io_w_req_valid(w_valid), .io_w_req_bits_setIdx(w_setIdx), \
    .io_w_req_bits_data_0(w_d0), .io_w_req_bits_data_1(w_d1), \
    .io_w_req_bits_data_2(w_d2), .io_w_req_bits_data_3(w_d3), \
    .io_w_req_bits_waymask(w_waymask), \
    .io_broadcast_ram_hold(b_hold), .io_broadcast_ram_bypass(b_bypass), \
    .io_broadcast_ram_bp_clken(b_bpclken), .io_broadcast_ram_aux_clk(b_auxclk), \
    .io_broadcast_ram_aux_ckbp(b_auxckbp), .io_broadcast_ram_mcp_hold(b_mcphold), \
    .io_broadcast_ram_ctl(b_ctl), .io_broadcast_cgen(b_cgen), \
    .boreChildrenBd_bore_addr(bore_addr), .boreChildrenBd_bore_addr_rd(bore_addr_rd), \
    .boreChildrenBd_bore_wdata(bore_wdata), .boreChildrenBd_bore_wmask(bore_wmask), \
    .boreChildrenBd_bore_re(bore_re), .boreChildrenBd_bore_we(bore_we), \
    .boreChildrenBd_bore_rdata(P``brdata), .boreChildrenBd_bore_ack(bore_ack), \
    .boreChildrenBd_bore_selectedOH(bore_selOH), .boreChildrenBd_bore_array(bore_array)

  SRAMTemplate_66    u_g (`PORTS(g_));
  SRAMTemplate_66_xs u_i (`PORTS(i_));

  // ---- 随机激励 ----
  always @(negedge clk) begin
    if (rst) begin
      r_valid <= 1'b0; w_valid <= 1'b0; bore_re <= 1'b0; bore_we <= 1'b0;
      bore_ack <= 1'b0; b_hold <= 1'b0;
    end else begin
      r_valid   <= ($urandom_range(0,3) != 0);   // 读：3/4
      w_valid   <= ($urandom_range(0,2) == 0);   // 写：1/3
      r_setIdx  <= 8'($urandom);
      w_setIdx  <= 8'($urandom);
      w_d0 <= 6'($urandom); w_d1 <= 6'($urandom);
      w_d2 <= 6'($urandom); w_d3 <= 6'($urandom);
      w_waymask <= 4'($urandom_range(1,15));  // 写掩码恒非零（真实写请求语义；waymask=0 同址读写会触发 golden 断言）
      b_hold    <= ($urandom_range(0,15) == 0);
      b_bypass  <= 1'b0; b_bpclken <= 1'b0; b_auxclk <= 1'b0;
      b_auxckbp <= 1'b0; b_mcphold <= 1'b0; b_cgen <= 1'b0;
      b_ctl     <= 64'({$urandom, $urandom});
      bore_ack  <= ($urandom_range(0,7) == 0);
      // MBIST 读/写互斥（mb: 0→读, 1→写, 其余→无），避免 golden 读写同址 $fatal 断言
      mb        = $urandom_range(0,3);
      bore_re   <= (mb == 0);
      bore_we   <= (mb == 1);
      bore_addr    <= 9'($urandom);
      bore_addr_rd <= 9'($urandom);
      bore_wdata   <= 24'($urandom);
      bore_wmask   <= 4'($urandom);
      bore_selOH   <= $urandom;
      bore_array   <= 7'($urandom);
    end
  end

  // ---- 比对 ----
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (g_rd0    !== i_rd0)    begin errors++; $display("[%0t] rd0 g=%h i=%h", $time, g_rd0, i_rd0); end
    if (g_rd1    !== i_rd1)    begin errors++; $display("[%0t] rd1 g=%h i=%h", $time, g_rd1, i_rd1); end
    if (g_rd2    !== i_rd2)    begin errors++; $display("[%0t] rd2 g=%h i=%h", $time, g_rd2, i_rd2); end
    if (g_rd3    !== i_rd3)    begin errors++; $display("[%0t] rd3 g=%h i=%h", $time, g_rd3, i_rd3); end
    if (g_brdata !== i_brdata) begin errors++; $display("[%0t] brdata g=%h i=%h", $time, g_brdata, i_brdata); end
  end

  // =========================================================================
  //  SRAMTemplate_64 (bp_tage_bt 256set×8way×2bit)  —— 独立激励/比对
  // =========================================================================
  logic        r64_valid, w64_valid;
  logic [7:0]  r64_setIdx, w64_setIdx;
  logic [1:0]  w64_d [0:7];
  logic [7:0]  w64_waymask;
  logic [8:0]  b64_addr, b64_addr_rd;
  logic [15:0] b64_wdata;
  logic [7:0]  b64_wmask;
  logic        b64_re, b64_we, b64_ack, b64_selOH;
  logic [6:0]  b64_array;
  int unsigned mb64;
  wire [1:0]  g64_rd [0:7];  wire [15:0] g64_brdata;
  wire [1:0]  i64_rd [0:7];  wire [15:0] i64_brdata;

  `define PORTS64(P) \
    .clock(clk), .reset(rst), \
    .io_r_req_valid(r64_valid), .io_r_req_bits_setIdx(r64_setIdx), \
    .io_r_resp_data_0(P``rd[0]), .io_r_resp_data_1(P``rd[1]), \
    .io_r_resp_data_2(P``rd[2]), .io_r_resp_data_3(P``rd[3]), \
    .io_r_resp_data_4(P``rd[4]), .io_r_resp_data_5(P``rd[5]), \
    .io_r_resp_data_6(P``rd[6]), .io_r_resp_data_7(P``rd[7]), \
    .io_w_req_valid(w64_valid), .io_w_req_bits_setIdx(w64_setIdx), \
    .io_w_req_bits_data_0(w64_d[0]), .io_w_req_bits_data_1(w64_d[1]), \
    .io_w_req_bits_data_2(w64_d[2]), .io_w_req_bits_data_3(w64_d[3]), \
    .io_w_req_bits_data_4(w64_d[4]), .io_w_req_bits_data_5(w64_d[5]), \
    .io_w_req_bits_data_6(w64_d[6]), .io_w_req_bits_data_7(w64_d[7]), \
    .io_w_req_bits_waymask(w64_waymask), \
    .io_broadcast_ram_hold(b_hold), .io_broadcast_ram_bypass(b_bypass), \
    .io_broadcast_ram_bp_clken(b_bpclken), .io_broadcast_ram_aux_clk(b_auxclk), \
    .io_broadcast_ram_aux_ckbp(b_auxckbp), .io_broadcast_ram_mcp_hold(b_mcphold), \
    .io_broadcast_ram_ctl(b_ctl), .io_broadcast_cgen(b_cgen), \
    .boreChildrenBd_bore_addr(b64_addr), .boreChildrenBd_bore_addr_rd(b64_addr_rd), \
    .boreChildrenBd_bore_wdata(b64_wdata), .boreChildrenBd_bore_wmask(b64_wmask), \
    .boreChildrenBd_bore_re(b64_re), .boreChildrenBd_bore_we(b64_we), \
    .boreChildrenBd_bore_rdata(P``brdata), .boreChildrenBd_bore_ack(b64_ack), \
    .boreChildrenBd_bore_selectedOH(b64_selOH), .boreChildrenBd_bore_array(b64_array)

  SRAMTemplate_64    u_g64 (`PORTS64(g64_));
  SRAMTemplate_64_xs u_i64 (`PORTS64(i64_));

  always @(negedge clk) begin
    if (rst) begin
      r64_valid <= 1'b0; w64_valid <= 1'b0; b64_re <= 1'b0; b64_we <= 1'b0; b64_ack <= 1'b0;
    end else begin
      r64_valid <= ($urandom_range(0,3) != 0);
      w64_valid <= ($urandom_range(0,2) == 0);
      r64_setIdx <= 8'($urandom); w64_setIdx <= 8'($urandom);
      for (int k = 0; k < 8; k++) w64_d[k] <= 2'($urandom);
      w64_waymask <= 8'($urandom_range(1,255));   // 写掩码恒非零
      mb64 <= 0; mb64 = $urandom_range(0,3);
      b64_ack <= ($urandom_range(0,7) == 0);
      b64_re <= (mb64 == 0); b64_we <= (mb64 == 1);
      b64_addr <= 9'($urandom); b64_addr_rd <= 9'($urandom);
      b64_wdata <= 16'($urandom); b64_wmask <= 8'($urandom);
      b64_selOH <= $urandom; b64_array <= 7'($urandom);
    end
  end

  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    for (int k = 0; k < 8; k++)
      if (g64_rd[k] !== i64_rd[k]) begin errors++; $display("[%0t] _64.rd%0d g=%h i=%h", $time, k, g64_rd[k], i64_rd[k]); end
    if (g64_brdata !== i64_brdata) begin errors++; $display("[%0t] _64.brdata g=%h i=%h", $time, g64_brdata, i64_brdata); end
  end

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 40000;
    $fsdbDumpfile("novas.fsdb"); $fsdbDumpvars(0, tb);
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
