// =============================================================================
// SRAMTemplate UT：手写 xs (SRAMTemplate_xs) 与 golden (SRAMTemplate) 双例化随机比对
//
// 两侧各含独立的 SRAM 宏实例（行为级 array_ext），上电 reset FSM 把所有 set 清零，
// 故 reset 完成后存储内容确定、两侧同步。激励覆盖：随机读/写（单端口，写优先）、
// 偶发 MBIST bore 读写、broadcast hold。比对 io_r_req_ready / io_r_resp_data /
// boreChildrenBd_bore_rdata。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 300;   // 等 reset FSM(128拍)清零完成
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  // 驱动信号
  logic        r_valid, w_valid;
  logic [6:0]  r_setIdx, w_setIdx;
  logic [36:0] w_data_0, w_data_1;
  logic [1:0]  w_waymask;
  logic        bc_hold, bc_bypass, bc_bp_clken, bc_cgen;
  logic [7:0]  bore_addr, bore_addr_rd;
  logic [73:0] bore_wdata;
  logic [1:0]  bore_wmask;
  logic        bore_re, bore_we, bore_ack, bore_selOH;

  // 输出
  wire        g_rready, i_rready;
  wire [36:0] g_rd0, g_rd1, i_rd0, i_rd1;
  wire [73:0] g_bore_rd, i_bore_rd;

  `define PORTS(RR, RD0, RD1, BRD) \
    .clock(clk), .reset(rst), \
    .io_r_req_ready(RR), .io_r_req_valid(r_valid), .io_r_req_bits_setIdx(r_setIdx), \
    .io_r_resp_data_0(RD0), .io_r_resp_data_1(RD1), \
    .io_w_req_valid(w_valid), .io_w_req_bits_setIdx(w_setIdx), \
    .io_w_req_bits_data_0(w_data_0), .io_w_req_bits_data_1(w_data_1), \
    .io_w_req_bits_waymask(w_waymask), \
    .io_broadcast_ram_hold(bc_hold), .io_broadcast_ram_bypass(bc_bypass), \
    .io_broadcast_ram_bp_clken(bc_bp_clken), .io_broadcast_ram_aux_clk(1'b0), \
    .io_broadcast_ram_aux_ckbp(1'b0), .io_broadcast_ram_mcp_hold(1'b0), \
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(bc_cgen), \
    .boreChildrenBd_bore_addr(bore_addr), .boreChildrenBd_bore_addr_rd(bore_addr_rd), \
    .boreChildrenBd_bore_wdata(bore_wdata), .boreChildrenBd_bore_wmask(bore_wmask), \
    .boreChildrenBd_bore_re(bore_re), .boreChildrenBd_bore_we(bore_we), \
    .boreChildrenBd_bore_rdata(BRD), .boreChildrenBd_bore_ack(bore_ack), \
    .boreChildrenBd_bore_selectedOH(bore_selOH), .boreChildrenBd_bore_array(1'b0)

  SRAMTemplate    u_g (`PORTS(g_rready, g_rd0, g_rd1, g_bore_rd));
  SRAMTemplate_xs u_i (`PORTS(i_rready, i_rd0, i_rd1, i_bore_rd));

  // 激励
  always @(negedge clk) begin
    if (rst) begin
      r_valid <= 0; w_valid <= 0; bore_ack <= 0; bore_re <= 0; bore_we <= 0;
      bc_hold <= 0; bc_bypass <= 0; bc_bp_clken <= 0; bc_cgen <= 0;
    end else begin
      r_valid   <= ($urandom_range(0,3) != 0);
      w_valid   <= ($urandom_range(0,2) == 0);
      r_setIdx  <= 7'($urandom);
      w_setIdx  <= 7'($urandom);
      w_data_0  <= 37'($urandom);
      w_data_1  <= 37'($urandom);
      w_waymask <= 2'($urandom);
      bc_hold   <= ($urandom_range(0,15) == 0);
      bc_bypass <= 1'b0;  // bypass 关联宏内部行为，保持 0
      bc_bp_clken <= 1'b0;
      bc_cgen   <= ($urandom_range(0,1));
      // MBIST：偶发一次 bore 访问
      bore_ack    <= ($urandom_range(0,7) == 0);
      bore_re     <= ($urandom_range(0,1));
      bore_we     <= ($urandom_range(0,1));
      bore_addr   <= 8'($urandom);
      bore_addr_rd<= 8'($urandom);
      bore_wdata  <= {$urandom, $urandom, 10'($urandom)};
      bore_wmask  <= 2'($urandom);
      bore_selOH  <= ($urandom_range(0,1));
    end
  end

  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (g_rready !== i_rready) begin errors++; $display("[%0t] rready g=%b i=%b", $time, g_rready, i_rready); end
    if (g_rd0 !== i_rd0) begin errors++; $display("[%0t] rd0 g=%h i=%h", $time, g_rd0, i_rd0); end
    if (g_rd1 !== i_rd1) begin errors++; $display("[%0t] rd1 g=%h i=%h", $time, g_rd1, i_rd1); end
    if (g_bore_rd !== i_bore_rd) begin errors++; $display("[%0t] bore_rd g=%h i=%h", $time, g_bore_rd, i_bore_rd); end
  end

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 60000;
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
