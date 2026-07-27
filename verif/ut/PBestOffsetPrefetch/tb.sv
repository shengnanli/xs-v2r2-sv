// 自动生成: gen_tb_shardD.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_enable;
  logic io_train_valid;
  logic [32:0] io_train_bits_tag;
  logic [8:0] io_train_bits_set;
  logic io_train_bits_needT;
  logic [6:0] io_train_bits_source;
  logic io_req_ready;
  logic io_resp_valid;
  logic [8:0] boreChildrenBd_bore_addr;
  logic [8:0] boreChildrenBd_bore_addr_rd;
  logic [12:0] boreChildrenBd_bore_wdata;
  logic boreChildrenBd_bore_wmask;
  logic boreChildrenBd_bore_re;
  logic boreChildrenBd_bore_we;
  logic boreChildrenBd_bore_ack;
  logic boreChildrenBd_bore_selectedOH;
  logic boreChildrenBd_bore_array;
  logic sigFromSrams_bore_ram_hold;
  logic sigFromSrams_bore_ram_bypass;
  logic sigFromSrams_bore_ram_bp_clken;
  logic sigFromSrams_bore_ram_aux_clk;
  logic sigFromSrams_bore_ram_aux_ckbp;
  logic sigFromSrams_bore_ram_mcp_hold;
  logic sigFromSrams_bore_cgen;
  logic g_io_train_ready;
  logic i_io_train_ready;
  logic g_io_req_valid;
  logic i_io_req_valid;
  logic [32:0] g_io_req_bits_tag;
  logic [32:0] i_io_req_bits_tag;
  logic [8:0] g_io_req_bits_set;
  logic [8:0] i_io_req_bits_set;
  logic [43:0] g_io_req_bits_vaddr;
  logic [43:0] i_io_req_bits_vaddr;
  logic g_io_req_bits_needT;
  logic i_io_req_bits_needT;
  logic [6:0] g_io_req_bits_source;
  logic [6:0] i_io_req_bits_source;
  logic g_io_resp_ready;
  logic i_io_resp_ready;
  logic [12:0] g_boreChildrenBd_bore_rdata;
  logic [12:0] i_boreChildrenBd_bore_rdata;

  PBestOffsetPrefetch dut_g (
    .clock(clk),
    .reset(rst),
    .io_enable(io_enable),
    .io_train_valid(io_train_valid),
    .io_train_bits_tag(io_train_bits_tag),
    .io_train_bits_set(io_train_bits_set),
    .io_train_bits_needT(io_train_bits_needT),
    .io_train_bits_source(io_train_bits_source),
    .io_req_ready(io_req_ready),
    .io_resp_valid(io_resp_valid),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(boreChildrenBd_bore_we),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .io_train_ready(g_io_train_ready),
    .io_req_valid(g_io_req_valid),
    .io_req_bits_tag(g_io_req_bits_tag),
    .io_req_bits_set(g_io_req_bits_set),
    .io_req_bits_vaddr(g_io_req_bits_vaddr),
    .io_req_bits_needT(g_io_req_bits_needT),
    .io_req_bits_source(g_io_req_bits_source),
    .io_resp_ready(g_io_resp_ready),
    .boreChildrenBd_bore_rdata(g_boreChildrenBd_bore_rdata)
  );

  PBestOffsetPrefetch_xs dut_i (
    .clock(clk),
    .reset(rst),
    .io_enable(io_enable),
    .io_train_valid(io_train_valid),
    .io_train_bits_tag(io_train_bits_tag),
    .io_train_bits_set(io_train_bits_set),
    .io_train_bits_needT(io_train_bits_needT),
    .io_train_bits_source(io_train_bits_source),
    .io_req_ready(io_req_ready),
    .io_resp_valid(io_resp_valid),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(boreChildrenBd_bore_we),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .io_train_ready(i_io_train_ready),
    .io_req_valid(i_io_req_valid),
    .io_req_bits_tag(i_io_req_bits_tag),
    .io_req_bits_set(i_io_req_bits_set),
    .io_req_bits_vaddr(i_io_req_bits_vaddr),
    .io_req_bits_needT(i_io_req_bits_needT),
    .io_req_bits_source(i_io_req_bits_source),
    .io_resp_ready(i_io_resp_ready),
    .boreChildrenBd_bore_rdata(i_boreChildrenBd_bore_rdata)
  );

  task automatic drive_random();
    io_enable = $random;
    io_train_valid = $random;
    io_train_bits_tag = $random;
    io_train_bits_set = $random;
    io_train_bits_needT = $random;
    io_train_bits_source = $random;
    io_req_ready = $random;
    io_resp_valid = $random;
    boreChildrenBd_bore_addr = $random;
    boreChildrenBd_bore_addr_rd = $random;
    boreChildrenBd_bore_wdata = $random;
    boreChildrenBd_bore_wmask = $random;
    boreChildrenBd_bore_re = $random;
    boreChildrenBd_bore_we = $random;
    boreChildrenBd_bore_ack = $random;
    boreChildrenBd_bore_selectedOH = $random;
    boreChildrenBd_bore_array = $random;
    sigFromSrams_bore_ram_hold = $random;
    sigFromSrams_bore_ram_bypass = $random;
    sigFromSrams_bore_ram_bp_clken = $random;
    sigFromSrams_bore_ram_aux_clk = $random;
    sigFromSrams_bore_ram_aux_ckbp = $random;
    sigFromSrams_bore_ram_mcp_hold = $random;
    sigFromSrams_bore_cgen = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_train_ready !== i_io_train_ready) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_train_ready: g=%h i=%h", cyc, g_io_train_ready, i_io_train_ready); end
    if (g_io_req_valid !== i_io_req_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_req_valid: g=%h i=%h", cyc, g_io_req_valid, i_io_req_valid); end
    if (g_io_req_bits_tag !== i_io_req_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_req_bits_tag: g=%h i=%h", cyc, g_io_req_bits_tag, i_io_req_bits_tag); end
    if (g_io_req_bits_set !== i_io_req_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_req_bits_set: g=%h i=%h", cyc, g_io_req_bits_set, i_io_req_bits_set); end
    if (g_io_req_bits_vaddr !== i_io_req_bits_vaddr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_req_bits_vaddr: g=%h i=%h", cyc, g_io_req_bits_vaddr, i_io_req_bits_vaddr); end
    if (g_io_req_bits_needT !== i_io_req_bits_needT) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_req_bits_needT: g=%h i=%h", cyc, g_io_req_bits_needT, i_io_req_bits_needT); end
    if (g_io_req_bits_source !== i_io_req_bits_source) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_req_bits_source: g=%h i=%h", cyc, g_io_req_bits_source, i_io_req_bits_source); end
    if (g_io_resp_ready !== i_io_resp_ready) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_resp_ready: g=%h i=%h", cyc, g_io_resp_ready, i_io_resp_ready); end
    if (g_boreChildrenBd_bore_rdata !== i_boreChildrenBd_bore_rdata) begin errors++; if (errors<=20) $display("[%0d] MISMATCH boreChildrenBd_bore_rdata: g=%h i=%h", cyc, g_boreChildrenBd_bore_rdata, i_boreChildrenBd_bore_rdata); end
  endtask

  initial begin
    rst = 1'b1;
    io_enable = '0;
    io_train_valid = '0;
    io_train_bits_tag = '0;
    io_train_bits_set = '0;
    io_train_bits_needT = '0;
    io_train_bits_source = '0;
    io_req_ready = '0;
    io_resp_valid = '0;
    boreChildrenBd_bore_addr = '0;
    boreChildrenBd_bore_addr_rd = '0;
    boreChildrenBd_bore_wdata = '0;
    boreChildrenBd_bore_wmask = '0;
    boreChildrenBd_bore_re = '0;
    boreChildrenBd_bore_we = '0;
    boreChildrenBd_bore_ack = '0;
    boreChildrenBd_bore_selectedOH = '0;
    boreChildrenBd_bore_array = '0;
    sigFromSrams_bore_ram_hold = '0;
    sigFromSrams_bore_ram_bypass = '0;
    sigFromSrams_bore_ram_bp_clken = '0;
    sigFromSrams_bore_ram_aux_clk = '0;
    sigFromSrams_bore_ram_aux_ckbp = '0;
    sigFromSrams_bore_ram_mcp_hold = '0;
    sigFromSrams_bore_cgen = '0;
    repeat (6) @(posedge clk);
    @(negedge clk); rst = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      drive_random();
      @(posedge clk);
      #1;
      if (cyc >= WARMUP) check_outputs();
    end
    if (errors == 0)
      $display("TEST PASSED: checks=%0d errors=0", checks);
    else
      $display("TEST FAILED: checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
