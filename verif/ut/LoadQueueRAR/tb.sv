// 自动生成：scripts/gen_loadqueuerar.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_redirect_valid;
  logic io_redirect_bits_robIdx_flag;
  logic [7:0] io_redirect_bits_robIdx_value;
  logic io_redirect_bits_level;
  logic io_query_0_req_valid;
  logic io_query_0_req_bits_uop_robIdx_flag;
  logic [7:0] io_query_0_req_bits_uop_robIdx_value;
  logic io_query_0_req_bits_uop_lqIdx_flag;
  logic [6:0] io_query_0_req_bits_uop_lqIdx_value;
  logic [47:0] io_query_0_req_bits_paddr;
  logic io_query_0_req_bits_data_valid;
  logic io_query_0_req_bits_is_nc;
  logic io_query_0_revoke;
  logic io_query_1_req_valid;
  logic io_query_1_req_bits_uop_robIdx_flag;
  logic [7:0] io_query_1_req_bits_uop_robIdx_value;
  logic io_query_1_req_bits_uop_lqIdx_flag;
  logic [6:0] io_query_1_req_bits_uop_lqIdx_value;
  logic [47:0] io_query_1_req_bits_paddr;
  logic io_query_1_req_bits_data_valid;
  logic io_query_1_req_bits_is_nc;
  logic io_query_1_revoke;
  logic io_query_2_req_valid;
  logic io_query_2_req_bits_uop_robIdx_flag;
  logic [7:0] io_query_2_req_bits_uop_robIdx_value;
  logic io_query_2_req_bits_uop_lqIdx_flag;
  logic [6:0] io_query_2_req_bits_uop_lqIdx_value;
  logic [47:0] io_query_2_req_bits_paddr;
  logic io_query_2_req_bits_data_valid;
  logic io_query_2_req_bits_is_nc;
  logic io_query_2_revoke;
  logic io_release_valid;
  logic [47:0] io_release_bits_paddr;
  logic io_ldWbPtr_flag;
  logic [6:0] io_ldWbPtr_value;
  wire g_io_query_0_req_ready;
  wire i_io_query_0_req_ready;
  wire g_io_query_0_resp_valid;
  wire i_io_query_0_resp_valid;
  wire g_io_query_0_resp_bits_rep_frm_fetch;
  wire i_io_query_0_resp_bits_rep_frm_fetch;
  wire g_io_query_1_req_ready;
  wire i_io_query_1_req_ready;
  wire g_io_query_1_resp_valid;
  wire i_io_query_1_resp_valid;
  wire g_io_query_1_resp_bits_rep_frm_fetch;
  wire i_io_query_1_resp_bits_rep_frm_fetch;
  wire g_io_query_2_req_ready;
  wire i_io_query_2_req_ready;
  wire g_io_query_2_resp_valid;
  wire i_io_query_2_resp_valid;
  wire g_io_query_2_resp_bits_rep_frm_fetch;
  wire i_io_query_2_resp_bits_rep_frm_fetch;
  wire g_io_lqFull;
  wire i_io_lqFull;
  wire [6:0] g_io_validCount;
  wire [6:0] i_io_validCount;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;

  LoadQueueRAR u_g (
    .clock(clk), .reset(rst),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_query_0_req_ready(g_io_query_0_req_ready),
    .io_query_0_req_valid(io_query_0_req_valid),
    .io_query_0_req_bits_uop_robIdx_flag(io_query_0_req_bits_uop_robIdx_flag),
    .io_query_0_req_bits_uop_robIdx_value(io_query_0_req_bits_uop_robIdx_value),
    .io_query_0_req_bits_uop_lqIdx_flag(io_query_0_req_bits_uop_lqIdx_flag),
    .io_query_0_req_bits_uop_lqIdx_value(io_query_0_req_bits_uop_lqIdx_value),
    .io_query_0_req_bits_paddr(io_query_0_req_bits_paddr),
    .io_query_0_req_bits_data_valid(io_query_0_req_bits_data_valid),
    .io_query_0_req_bits_is_nc(io_query_0_req_bits_is_nc),
    .io_query_0_resp_valid(g_io_query_0_resp_valid),
    .io_query_0_resp_bits_rep_frm_fetch(g_io_query_0_resp_bits_rep_frm_fetch),
    .io_query_0_revoke(io_query_0_revoke),
    .io_query_1_req_ready(g_io_query_1_req_ready),
    .io_query_1_req_valid(io_query_1_req_valid),
    .io_query_1_req_bits_uop_robIdx_flag(io_query_1_req_bits_uop_robIdx_flag),
    .io_query_1_req_bits_uop_robIdx_value(io_query_1_req_bits_uop_robIdx_value),
    .io_query_1_req_bits_uop_lqIdx_flag(io_query_1_req_bits_uop_lqIdx_flag),
    .io_query_1_req_bits_uop_lqIdx_value(io_query_1_req_bits_uop_lqIdx_value),
    .io_query_1_req_bits_paddr(io_query_1_req_bits_paddr),
    .io_query_1_req_bits_data_valid(io_query_1_req_bits_data_valid),
    .io_query_1_req_bits_is_nc(io_query_1_req_bits_is_nc),
    .io_query_1_resp_valid(g_io_query_1_resp_valid),
    .io_query_1_resp_bits_rep_frm_fetch(g_io_query_1_resp_bits_rep_frm_fetch),
    .io_query_1_revoke(io_query_1_revoke),
    .io_query_2_req_ready(g_io_query_2_req_ready),
    .io_query_2_req_valid(io_query_2_req_valid),
    .io_query_2_req_bits_uop_robIdx_flag(io_query_2_req_bits_uop_robIdx_flag),
    .io_query_2_req_bits_uop_robIdx_value(io_query_2_req_bits_uop_robIdx_value),
    .io_query_2_req_bits_uop_lqIdx_flag(io_query_2_req_bits_uop_lqIdx_flag),
    .io_query_2_req_bits_uop_lqIdx_value(io_query_2_req_bits_uop_lqIdx_value),
    .io_query_2_req_bits_paddr(io_query_2_req_bits_paddr),
    .io_query_2_req_bits_data_valid(io_query_2_req_bits_data_valid),
    .io_query_2_req_bits_is_nc(io_query_2_req_bits_is_nc),
    .io_query_2_resp_valid(g_io_query_2_resp_valid),
    .io_query_2_resp_bits_rep_frm_fetch(g_io_query_2_resp_bits_rep_frm_fetch),
    .io_query_2_revoke(io_query_2_revoke),
    .io_release_valid(io_release_valid),
    .io_release_bits_paddr(io_release_bits_paddr),
    .io_ldWbPtr_flag(io_ldWbPtr_flag),
    .io_ldWbPtr_value(io_ldWbPtr_value),
    .io_lqFull(g_io_lqFull),
    .io_validCount(g_io_validCount),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value)
  );
  LoadQueueRAR_xs u_i (
    .clock(clk), .reset(rst),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_query_0_req_ready(i_io_query_0_req_ready),
    .io_query_0_req_valid(io_query_0_req_valid),
    .io_query_0_req_bits_uop_robIdx_flag(io_query_0_req_bits_uop_robIdx_flag),
    .io_query_0_req_bits_uop_robIdx_value(io_query_0_req_bits_uop_robIdx_value),
    .io_query_0_req_bits_uop_lqIdx_flag(io_query_0_req_bits_uop_lqIdx_flag),
    .io_query_0_req_bits_uop_lqIdx_value(io_query_0_req_bits_uop_lqIdx_value),
    .io_query_0_req_bits_paddr(io_query_0_req_bits_paddr),
    .io_query_0_req_bits_data_valid(io_query_0_req_bits_data_valid),
    .io_query_0_req_bits_is_nc(io_query_0_req_bits_is_nc),
    .io_query_0_resp_valid(i_io_query_0_resp_valid),
    .io_query_0_resp_bits_rep_frm_fetch(i_io_query_0_resp_bits_rep_frm_fetch),
    .io_query_0_revoke(io_query_0_revoke),
    .io_query_1_req_ready(i_io_query_1_req_ready),
    .io_query_1_req_valid(io_query_1_req_valid),
    .io_query_1_req_bits_uop_robIdx_flag(io_query_1_req_bits_uop_robIdx_flag),
    .io_query_1_req_bits_uop_robIdx_value(io_query_1_req_bits_uop_robIdx_value),
    .io_query_1_req_bits_uop_lqIdx_flag(io_query_1_req_bits_uop_lqIdx_flag),
    .io_query_1_req_bits_uop_lqIdx_value(io_query_1_req_bits_uop_lqIdx_value),
    .io_query_1_req_bits_paddr(io_query_1_req_bits_paddr),
    .io_query_1_req_bits_data_valid(io_query_1_req_bits_data_valid),
    .io_query_1_req_bits_is_nc(io_query_1_req_bits_is_nc),
    .io_query_1_resp_valid(i_io_query_1_resp_valid),
    .io_query_1_resp_bits_rep_frm_fetch(i_io_query_1_resp_bits_rep_frm_fetch),
    .io_query_1_revoke(io_query_1_revoke),
    .io_query_2_req_ready(i_io_query_2_req_ready),
    .io_query_2_req_valid(io_query_2_req_valid),
    .io_query_2_req_bits_uop_robIdx_flag(io_query_2_req_bits_uop_robIdx_flag),
    .io_query_2_req_bits_uop_robIdx_value(io_query_2_req_bits_uop_robIdx_value),
    .io_query_2_req_bits_uop_lqIdx_flag(io_query_2_req_bits_uop_lqIdx_flag),
    .io_query_2_req_bits_uop_lqIdx_value(io_query_2_req_bits_uop_lqIdx_value),
    .io_query_2_req_bits_paddr(io_query_2_req_bits_paddr),
    .io_query_2_req_bits_data_valid(io_query_2_req_bits_data_valid),
    .io_query_2_req_bits_is_nc(io_query_2_req_bits_is_nc),
    .io_query_2_resp_valid(i_io_query_2_resp_valid),
    .io_query_2_resp_bits_rep_frm_fetch(i_io_query_2_resp_bits_rep_frm_fetch),
    .io_query_2_revoke(io_query_2_revoke),
    .io_release_valid(io_release_valid),
    .io_release_bits_paddr(io_release_bits_paddr),
    .io_ldWbPtr_flag(io_ldWbPtr_flag),
    .io_ldWbPtr_value(io_ldWbPtr_value),
    .io_lqFull(i_io_lqFull),
    .io_validCount(i_io_validCount),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value)
  );

  // 随机激励：以 freelist 自然推进为前提随机驱动 query/release/redirect/ldWbPtr。
  // robIdx/lqIdx 用受限随机（小范围）以让违例/出队条件较易命中，提升覆盖。
  task automatic drive();
    io_redirect_valid = ($urandom_range(0,15)==0);
    io_redirect_bits_robIdx_flag = $urandom;
    io_redirect_bits_robIdx_value = $urandom_range(0,40);
    io_redirect_bits_level = $urandom;
    for (int w=0; w<3; w++) begin
    end
    io_query_0_req_valid = $urandom_range(0,1);
    io_query_1_req_valid = $urandom_range(0,1);
    io_query_2_req_valid = $urandom_range(0,1);
    io_query_0_req_bits_uop_robIdx_flag = $urandom;
    io_query_1_req_bits_uop_robIdx_flag = $urandom;
    io_query_2_req_bits_uop_robIdx_flag = $urandom;
    io_query_0_req_bits_uop_robIdx_value = $urandom_range(0,40);
    io_query_1_req_bits_uop_robIdx_value = $urandom_range(0,40);
    io_query_2_req_bits_uop_robIdx_value = $urandom_range(0,40);
    io_query_0_req_bits_uop_lqIdx_flag = $urandom;
    io_query_1_req_bits_uop_lqIdx_flag = $urandom;
    io_query_2_req_bits_uop_lqIdx_flag = $urandom;
    io_query_0_req_bits_uop_lqIdx_value = $urandom_range(0,80);
    io_query_1_req_bits_uop_lqIdx_value = $urandom_range(0,80);
    io_query_2_req_bits_uop_lqIdx_value = $urandom_range(0,80);
    // paddr：限制在少数 cacheline 上，提高地址匹配/违例命中率
    io_query_0_req_bits_paddr = {$urandom_range(0,7), 6'($urandom)} << 0 | ($urandom_range(0,3)<<6);
    io_query_1_req_bits_paddr = ($urandom_range(0,7)<<6) | $urandom_range(0,63);
    io_query_2_req_bits_paddr = ($urandom_range(0,7)<<6) | $urandom_range(0,63);
    io_query_0_req_bits_data_valid = $urandom;
    io_query_1_req_bits_data_valid = $urandom;
    io_query_2_req_bits_data_valid = $urandom;
    io_query_0_req_bits_is_nc = ($urandom_range(0,7)==0);
    io_query_1_req_bits_is_nc = ($urandom_range(0,7)==0);
    io_query_2_req_bits_is_nc = ($urandom_range(0,7)==0);
    io_query_0_revoke = ($urandom_range(0,7)==0);
    io_query_1_revoke = ($urandom_range(0,7)==0);
    io_query_2_revoke = ($urandom_range(0,7)==0);
    io_release_valid = $urandom_range(0,1);
    io_release_bits_paddr = ($urandom_range(0,7)<<6) | $urandom_range(0,63);
    io_ldWbPtr_flag = $urandom;
    io_ldWbPtr_value = $urandom_range(0,80);
  endtask

  int warmup = 4;
  always @(posedge clk) if (!rst) begin
    if (warmup > 0) warmup--; else begin
    checks++;
    if (!$isunknown(g_io_query_0_req_ready) && g_io_query_0_req_ready !== i_io_query_0_req_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_query_0_req_ready g=%h i=%h", $time, g_io_query_0_req_ready, i_io_query_0_req_ready); end
    if (!$isunknown(g_io_query_0_resp_valid) && g_io_query_0_resp_valid !== i_io_query_0_resp_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_query_0_resp_valid g=%h i=%h", $time, g_io_query_0_resp_valid, i_io_query_0_resp_valid); end
    if (!$isunknown(g_io_query_0_resp_bits_rep_frm_fetch) && g_io_query_0_resp_bits_rep_frm_fetch !== i_io_query_0_resp_bits_rep_frm_fetch) begin errors++;
      if(errors<=60) $display("[%0t] io_query_0_resp_bits_rep_frm_fetch g=%h i=%h", $time, g_io_query_0_resp_bits_rep_frm_fetch, i_io_query_0_resp_bits_rep_frm_fetch); end
    if (!$isunknown(g_io_query_1_req_ready) && g_io_query_1_req_ready !== i_io_query_1_req_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_query_1_req_ready g=%h i=%h", $time, g_io_query_1_req_ready, i_io_query_1_req_ready); end
    if (!$isunknown(g_io_query_1_resp_valid) && g_io_query_1_resp_valid !== i_io_query_1_resp_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_query_1_resp_valid g=%h i=%h", $time, g_io_query_1_resp_valid, i_io_query_1_resp_valid); end
    if (!$isunknown(g_io_query_1_resp_bits_rep_frm_fetch) && g_io_query_1_resp_bits_rep_frm_fetch !== i_io_query_1_resp_bits_rep_frm_fetch) begin errors++;
      if(errors<=60) $display("[%0t] io_query_1_resp_bits_rep_frm_fetch g=%h i=%h", $time, g_io_query_1_resp_bits_rep_frm_fetch, i_io_query_1_resp_bits_rep_frm_fetch); end
    if (!$isunknown(g_io_query_2_req_ready) && g_io_query_2_req_ready !== i_io_query_2_req_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_query_2_req_ready g=%h i=%h", $time, g_io_query_2_req_ready, i_io_query_2_req_ready); end
    if (!$isunknown(g_io_query_2_resp_valid) && g_io_query_2_resp_valid !== i_io_query_2_resp_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_query_2_resp_valid g=%h i=%h", $time, g_io_query_2_resp_valid, i_io_query_2_resp_valid); end
    if (!$isunknown(g_io_query_2_resp_bits_rep_frm_fetch) && g_io_query_2_resp_bits_rep_frm_fetch !== i_io_query_2_resp_bits_rep_frm_fetch) begin errors++;
      if(errors<=60) $display("[%0t] io_query_2_resp_bits_rep_frm_fetch g=%h i=%h", $time, g_io_query_2_resp_bits_rep_frm_fetch, i_io_query_2_resp_bits_rep_frm_fetch); end
    if (!$isunknown(g_io_lqFull) && g_io_lqFull !== i_io_lqFull) begin errors++;
      if(errors<=60) $display("[%0t] io_lqFull g=%h i=%h", $time, g_io_lqFull, i_io_lqFull); end
    if (!$isunknown(g_io_validCount) && g_io_validCount !== i_io_validCount) begin errors++;
      if(errors<=60) $display("[%0t] io_validCount g=%h i=%h", $time, g_io_validCount, i_io_validCount); end
    if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if(errors<=60) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
    if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if(errors<=60) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
    end
  end

  initial begin
    rst = 1; drive();
    repeat (8) @(posedge clk);
    rst = 0;
    repeat (NCYCLES) begin @(negedge clk); drive(); end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
