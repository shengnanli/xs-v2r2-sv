// 生成 RegionWays 的双例化 UT testbench（tb.sv）。
//
// golden RegionWays vs 重写 RegionWays_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），逐拍比全部输出。
// 激励要点：write_region / update_region 从 24 项小池子取（比表容量 16 大一些：表会被填满、PLRU 替换会发生，
//   已有项又常被再次写中）；write_valid 按阶段 1/8 ~ 7/8；update_region 有 1/4 概率直接取本拍的
//   write_region（旁路路径）；读指针全随机。复位每 ~2000 拍一次（表从空开始重新填）。
// 覆盖（golden 内部语义信号）：写命中 / 写未满取空项 / 写满走 PLRU 替换 / 更新口旁路 / 更新口表内命中。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= RegionWays =================
  int unsigned r_mode = 0;
  logic [29:0] r_pool [24];
  initial for (int k = 0; k < 24; k++) r_pool[k] = 30'($urandom);
  logic r_reset;
  logic [3:0] r_io_req_pointer_0;
  logic [3:0] r_io_req_pointer_1;
  logic [3:0] r_io_req_pointer_2;
  logic [3:0] r_io_req_pointer_3;
  logic [3:0] r_io_req_pointer_4;
  wire  r_g_io_resp_hit_0, r_i_io_resp_hit_0;
  logic r_s0_io_resp_hit_0 = '0, r_s1_io_resp_hit_0 = '0;
  wire  r_g_io_resp_hit_1, r_i_io_resp_hit_1;
  logic r_s0_io_resp_hit_1 = '0, r_s1_io_resp_hit_1 = '0;
  wire  r_g_io_resp_hit_2, r_i_io_resp_hit_2;
  logic r_s0_io_resp_hit_2 = '0, r_s1_io_resp_hit_2 = '0;
  wire  r_g_io_resp_hit_3, r_i_io_resp_hit_3;
  logic r_s0_io_resp_hit_3 = '0, r_s1_io_resp_hit_3 = '0;
  wire  r_g_io_resp_hit_4, r_i_io_resp_hit_4;
  logic r_s0_io_resp_hit_4 = '0, r_s1_io_resp_hit_4 = '0;
  wire  [29:0] r_g_io_resp_region_0, r_i_io_resp_region_0;
  logic [29:0] r_s0_io_resp_region_0 = '0, r_s1_io_resp_region_0 = '0;
  wire  [29:0] r_g_io_resp_region_1, r_i_io_resp_region_1;
  logic [29:0] r_s0_io_resp_region_1 = '0, r_s1_io_resp_region_1 = '0;
  wire  [29:0] r_g_io_resp_region_2, r_i_io_resp_region_2;
  logic [29:0] r_s0_io_resp_region_2 = '0, r_s1_io_resp_region_2 = '0;
  wire  [29:0] r_g_io_resp_region_3, r_i_io_resp_region_3;
  logic [29:0] r_s0_io_resp_region_3 = '0, r_s1_io_resp_region_3 = '0;
  wire  [29:0] r_g_io_resp_region_4, r_i_io_resp_region_4;
  logic [29:0] r_s0_io_resp_region_4 = '0, r_s1_io_resp_region_4 = '0;
  logic [29:0] r_io_update_region_0;
  logic [29:0] r_io_update_region_1;
  wire  r_g_io_update_hit_0, r_i_io_update_hit_0;
  logic r_s0_io_update_hit_0 = '0, r_s1_io_update_hit_0 = '0;
  wire  r_g_io_update_hit_1, r_i_io_update_hit_1;
  logic r_s0_io_update_hit_1 = '0, r_s1_io_update_hit_1 = '0;
  wire  [3:0] r_g_io_update_pointer_0, r_i_io_update_pointer_0;
  logic [3:0] r_s0_io_update_pointer_0 = '0, r_s1_io_update_pointer_0 = '0;
  wire  [3:0] r_g_io_update_pointer_1, r_i_io_update_pointer_1;
  logic [3:0] r_s0_io_update_pointer_1 = '0, r_s1_io_update_pointer_1 = '0;
  logic r_io_write_valid;
  logic [29:0] r_io_write_region;
  wire  [3:0] r_g_io_write_pointer, r_i_io_write_pointer;
  logic [3:0] r_s0_io_write_pointer = '0, r_s1_io_write_pointer = '0;
  int r_cov_write_hit = 0;
  int r_cov_write_fill_free = 0;
  int r_cov_write_plru_replace = 0;
  int r_cov_update_bypass = 0;
  int r_cov_update_table_hit = 0;
  logic [0:0] r_armed = '0;
  int r_armed_at = -1;
  RegionWays r_u_gold (
    .clock(clk),
    .reset(r_reset),
    .io_req_pointer_0(r_io_req_pointer_0),
    .io_req_pointer_1(r_io_req_pointer_1),
    .io_req_pointer_2(r_io_req_pointer_2),
    .io_req_pointer_3(r_io_req_pointer_3),
    .io_req_pointer_4(r_io_req_pointer_4),
    .io_resp_hit_0(r_g_io_resp_hit_0),
    .io_resp_hit_1(r_g_io_resp_hit_1),
    .io_resp_hit_2(r_g_io_resp_hit_2),
    .io_resp_hit_3(r_g_io_resp_hit_3),
    .io_resp_hit_4(r_g_io_resp_hit_4),
    .io_resp_region_0(r_g_io_resp_region_0),
    .io_resp_region_1(r_g_io_resp_region_1),
    .io_resp_region_2(r_g_io_resp_region_2),
    .io_resp_region_3(r_g_io_resp_region_3),
    .io_resp_region_4(r_g_io_resp_region_4),
    .io_update_region_0(r_io_update_region_0),
    .io_update_region_1(r_io_update_region_1),
    .io_update_hit_0(r_g_io_update_hit_0),
    .io_update_hit_1(r_g_io_update_hit_1),
    .io_update_pointer_0(r_g_io_update_pointer_0),
    .io_update_pointer_1(r_g_io_update_pointer_1),
    .io_write_valid(r_io_write_valid),
    .io_write_region(r_io_write_region),
    .io_write_pointer(r_g_io_write_pointer)
  );
  RegionWays_xs r_u_impl (
    .clock(clk),
    .reset(r_reset),
    .io_req_pointer_0(r_io_req_pointer_0),
    .io_req_pointer_1(r_io_req_pointer_1),
    .io_req_pointer_2(r_io_req_pointer_2),
    .io_req_pointer_3(r_io_req_pointer_3),
    .io_req_pointer_4(r_io_req_pointer_4),
    .io_resp_hit_0(r_i_io_resp_hit_0),
    .io_resp_hit_1(r_i_io_resp_hit_1),
    .io_resp_hit_2(r_i_io_resp_hit_2),
    .io_resp_hit_3(r_i_io_resp_hit_3),
    .io_resp_hit_4(r_i_io_resp_hit_4),
    .io_resp_region_0(r_i_io_resp_region_0),
    .io_resp_region_1(r_i_io_resp_region_1),
    .io_resp_region_2(r_i_io_resp_region_2),
    .io_resp_region_3(r_i_io_resp_region_3),
    .io_resp_region_4(r_i_io_resp_region_4),
    .io_update_region_0(r_io_update_region_0),
    .io_update_region_1(r_io_update_region_1),
    .io_update_hit_0(r_i_io_update_hit_0),
    .io_update_hit_1(r_i_io_update_hit_1),
    .io_update_pointer_0(r_i_io_update_pointer_0),
    .io_update_pointer_1(r_i_io_update_pointer_1),
    .io_write_valid(r_io_write_valid),
    .io_write_region(r_io_write_region),
    .io_write_pointer(r_i_io_write_pointer)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 1000 == 0) r_mode = $urandom_range(0, 15);
      r_io_req_pointer_0 = 4'($urandom);
      r_io_req_pointer_1 = 4'($urandom);
      r_io_req_pointer_2 = 4'($urandom);
      r_io_req_pointer_3 = 4'($urandom);
      r_io_req_pointer_4 = 4'($urandom);
      r_io_update_region_0 = 30'($urandom);
      r_io_update_region_1 = 30'($urandom);
      r_io_write_valid = 1'($urandom);
      r_io_write_region = 30'($urandom);
      r_reset = (cyc < RESET_CYC) || ($urandom_range(0, 1999) == 0);
      begin : stim_r
        r_io_write_valid = ($urandom_range(0, 7) < (r_mode % 7) + 1);
        r_io_write_region = r_pool[$urandom_range(0, 23)];
        r_io_update_region_0 = ($urandom_range(0, 3) == 0) ? r_io_write_region : r_pool[$urandom_range(0, 23)];
        r_io_update_region_1 = ($urandom_range(0, 3) == 0) ? r_io_write_region : r_pool[$urandom_range(0, 23)];
      end
      #4;
      r_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&r_armed)) begin
        checks++;
        if (r_g_io_resp_hit_0 !== r_i_io_resp_hit_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_resp_hit_0 g=%h i=%h", cyc, r_g_io_resp_hit_0, r_i_io_resp_hit_0);
        end
        r_s1_io_resp_hit_0 |= r_g_io_resp_hit_0;
        r_s0_io_resp_hit_0 |= ~r_g_io_resp_hit_0;
        checks++;
        if (r_g_io_resp_hit_1 !== r_i_io_resp_hit_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_resp_hit_1 g=%h i=%h", cyc, r_g_io_resp_hit_1, r_i_io_resp_hit_1);
        end
        r_s1_io_resp_hit_1 |= r_g_io_resp_hit_1;
        r_s0_io_resp_hit_1 |= ~r_g_io_resp_hit_1;
        checks++;
        if (r_g_io_resp_hit_2 !== r_i_io_resp_hit_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_resp_hit_2 g=%h i=%h", cyc, r_g_io_resp_hit_2, r_i_io_resp_hit_2);
        end
        r_s1_io_resp_hit_2 |= r_g_io_resp_hit_2;
        r_s0_io_resp_hit_2 |= ~r_g_io_resp_hit_2;
        checks++;
        if (r_g_io_resp_hit_3 !== r_i_io_resp_hit_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_resp_hit_3 g=%h i=%h", cyc, r_g_io_resp_hit_3, r_i_io_resp_hit_3);
        end
        r_s1_io_resp_hit_3 |= r_g_io_resp_hit_3;
        r_s0_io_resp_hit_3 |= ~r_g_io_resp_hit_3;
        checks++;
        if (r_g_io_resp_hit_4 !== r_i_io_resp_hit_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_resp_hit_4 g=%h i=%h", cyc, r_g_io_resp_hit_4, r_i_io_resp_hit_4);
        end
        r_s1_io_resp_hit_4 |= r_g_io_resp_hit_4;
        r_s0_io_resp_hit_4 |= ~r_g_io_resp_hit_4;
        checks++;
        if (r_g_io_resp_region_0 !== r_i_io_resp_region_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_resp_region_0 g=%h i=%h", cyc, r_g_io_resp_region_0, r_i_io_resp_region_0);
        end
        r_s1_io_resp_region_0 |= r_g_io_resp_region_0;
        r_s0_io_resp_region_0 |= ~r_g_io_resp_region_0;
        checks++;
        if (r_g_io_resp_region_1 !== r_i_io_resp_region_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_resp_region_1 g=%h i=%h", cyc, r_g_io_resp_region_1, r_i_io_resp_region_1);
        end
        r_s1_io_resp_region_1 |= r_g_io_resp_region_1;
        r_s0_io_resp_region_1 |= ~r_g_io_resp_region_1;
        checks++;
        if (r_g_io_resp_region_2 !== r_i_io_resp_region_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_resp_region_2 g=%h i=%h", cyc, r_g_io_resp_region_2, r_i_io_resp_region_2);
        end
        r_s1_io_resp_region_2 |= r_g_io_resp_region_2;
        r_s0_io_resp_region_2 |= ~r_g_io_resp_region_2;
        checks++;
        if (r_g_io_resp_region_3 !== r_i_io_resp_region_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_resp_region_3 g=%h i=%h", cyc, r_g_io_resp_region_3, r_i_io_resp_region_3);
        end
        r_s1_io_resp_region_3 |= r_g_io_resp_region_3;
        r_s0_io_resp_region_3 |= ~r_g_io_resp_region_3;
        checks++;
        if (r_g_io_resp_region_4 !== r_i_io_resp_region_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_resp_region_4 g=%h i=%h", cyc, r_g_io_resp_region_4, r_i_io_resp_region_4);
        end
        r_s1_io_resp_region_4 |= r_g_io_resp_region_4;
        r_s0_io_resp_region_4 |= ~r_g_io_resp_region_4;
        checks++;
        if (r_g_io_update_hit_0 !== r_i_io_update_hit_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_update_hit_0 g=%h i=%h", cyc, r_g_io_update_hit_0, r_i_io_update_hit_0);
        end
        r_s1_io_update_hit_0 |= r_g_io_update_hit_0;
        r_s0_io_update_hit_0 |= ~r_g_io_update_hit_0;
        checks++;
        if (r_g_io_update_hit_1 !== r_i_io_update_hit_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_update_hit_1 g=%h i=%h", cyc, r_g_io_update_hit_1, r_i_io_update_hit_1);
        end
        r_s1_io_update_hit_1 |= r_g_io_update_hit_1;
        r_s0_io_update_hit_1 |= ~r_g_io_update_hit_1;
        checks++;
        if (r_g_io_update_pointer_0 !== r_i_io_update_pointer_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_update_pointer_0 g=%h i=%h", cyc, r_g_io_update_pointer_0, r_i_io_update_pointer_0);
        end
        r_s1_io_update_pointer_0 |= r_g_io_update_pointer_0;
        r_s0_io_update_pointer_0 |= ~r_g_io_update_pointer_0;
        checks++;
        if (r_g_io_update_pointer_1 !== r_i_io_update_pointer_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_update_pointer_1 g=%h i=%h", cyc, r_g_io_update_pointer_1, r_i_io_update_pointer_1);
        end
        r_s1_io_update_pointer_1 |= r_g_io_update_pointer_1;
        r_s0_io_update_pointer_1 |= ~r_g_io_update_pointer_1;
        checks++;
        if (r_g_io_write_pointer !== r_i_io_write_pointer) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegionWays.io_write_pointer g=%h i=%h", cyc, r_g_io_write_pointer, r_i_io_write_pointer);
        end
        r_s1_io_write_pointer |= r_g_io_write_pointer;
        r_s0_io_write_pointer |= ~r_g_io_write_pointer;
        if (r_io_write_valid && r_u_gold.w_hit) r_cov_write_hit++;
        if (r_io_write_valid && !r_u_gold.w_hit && !r_u_gold.valid) r_cov_write_fill_free++;
        if (r_io_write_valid && !r_u_gold.w_hit && r_u_gold.valid) r_cov_write_plru_replace++;
        if (r_u_gold.u_bypass || r_u_gold.u_bypass_1) r_cov_update_bypass++;
        if ((r_g_io_update_hit_0 && !r_u_gold.u_bypass) || (r_g_io_update_hit_1 && !r_u_gold.u_bypass_1)) r_cov_update_table_hit++;
      end
      if (r_armed_at < 0 && (&r_armed)) r_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(r_s0_io_resp_hit_0 && r_s1_io_resp_hit_0)) begin cov_fail++; $display("[COV] RegionWays.io_resp_hit_0 未见过 0 和 1"); end
    if (!(r_s0_io_resp_hit_1 && r_s1_io_resp_hit_1)) begin cov_fail++; $display("[COV] RegionWays.io_resp_hit_1 未见过 0 和 1"); end
    if (!(r_s0_io_resp_hit_2 && r_s1_io_resp_hit_2)) begin cov_fail++; $display("[COV] RegionWays.io_resp_hit_2 未见过 0 和 1"); end
    if (!(r_s0_io_resp_hit_3 && r_s1_io_resp_hit_3)) begin cov_fail++; $display("[COV] RegionWays.io_resp_hit_3 未见过 0 和 1"); end
    if (!(r_s0_io_resp_hit_4 && r_s1_io_resp_hit_4)) begin cov_fail++; $display("[COV] RegionWays.io_resp_hit_4 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[0] && r_s1_io_resp_region_0[0])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[1] && r_s1_io_resp_region_0[1])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[2] && r_s1_io_resp_region_0[2])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[3] && r_s1_io_resp_region_0[3])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[4] && r_s1_io_resp_region_0[4])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[4] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[5] && r_s1_io_resp_region_0[5])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[5] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[6] && r_s1_io_resp_region_0[6])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[6] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[7] && r_s1_io_resp_region_0[7])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[7] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[8] && r_s1_io_resp_region_0[8])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[8] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[9] && r_s1_io_resp_region_0[9])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[9] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[10] && r_s1_io_resp_region_0[10])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[10] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[11] && r_s1_io_resp_region_0[11])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[11] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[12] && r_s1_io_resp_region_0[12])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[12] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[13] && r_s1_io_resp_region_0[13])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[13] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[14] && r_s1_io_resp_region_0[14])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[14] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[15] && r_s1_io_resp_region_0[15])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[15] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[16] && r_s1_io_resp_region_0[16])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[16] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[17] && r_s1_io_resp_region_0[17])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[17] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[18] && r_s1_io_resp_region_0[18])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[18] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[19] && r_s1_io_resp_region_0[19])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[19] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[20] && r_s1_io_resp_region_0[20])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[20] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[21] && r_s1_io_resp_region_0[21])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[21] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[22] && r_s1_io_resp_region_0[22])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[22] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[23] && r_s1_io_resp_region_0[23])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[23] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[24] && r_s1_io_resp_region_0[24])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[24] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[25] && r_s1_io_resp_region_0[25])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[25] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[26] && r_s1_io_resp_region_0[26])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[26] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[27] && r_s1_io_resp_region_0[27])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[27] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[28] && r_s1_io_resp_region_0[28])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[28] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_0[29] && r_s1_io_resp_region_0[29])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_0[29] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[0] && r_s1_io_resp_region_1[0])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[1] && r_s1_io_resp_region_1[1])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[2] && r_s1_io_resp_region_1[2])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[3] && r_s1_io_resp_region_1[3])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[4] && r_s1_io_resp_region_1[4])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[4] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[5] && r_s1_io_resp_region_1[5])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[5] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[6] && r_s1_io_resp_region_1[6])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[6] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[7] && r_s1_io_resp_region_1[7])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[7] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[8] && r_s1_io_resp_region_1[8])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[8] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[9] && r_s1_io_resp_region_1[9])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[9] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[10] && r_s1_io_resp_region_1[10])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[10] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[11] && r_s1_io_resp_region_1[11])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[11] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[12] && r_s1_io_resp_region_1[12])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[12] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[13] && r_s1_io_resp_region_1[13])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[13] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[14] && r_s1_io_resp_region_1[14])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[14] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[15] && r_s1_io_resp_region_1[15])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[15] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[16] && r_s1_io_resp_region_1[16])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[16] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[17] && r_s1_io_resp_region_1[17])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[17] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[18] && r_s1_io_resp_region_1[18])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[18] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[19] && r_s1_io_resp_region_1[19])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[19] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[20] && r_s1_io_resp_region_1[20])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[20] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[21] && r_s1_io_resp_region_1[21])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[21] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[22] && r_s1_io_resp_region_1[22])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[22] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[23] && r_s1_io_resp_region_1[23])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[23] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[24] && r_s1_io_resp_region_1[24])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[24] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[25] && r_s1_io_resp_region_1[25])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[25] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[26] && r_s1_io_resp_region_1[26])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[26] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[27] && r_s1_io_resp_region_1[27])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[27] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[28] && r_s1_io_resp_region_1[28])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[28] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_1[29] && r_s1_io_resp_region_1[29])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_1[29] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[0] && r_s1_io_resp_region_2[0])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[0] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[1] && r_s1_io_resp_region_2[1])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[1] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[2] && r_s1_io_resp_region_2[2])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[2] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[3] && r_s1_io_resp_region_2[3])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[3] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[4] && r_s1_io_resp_region_2[4])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[4] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[5] && r_s1_io_resp_region_2[5])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[5] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[6] && r_s1_io_resp_region_2[6])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[6] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[7] && r_s1_io_resp_region_2[7])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[7] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[8] && r_s1_io_resp_region_2[8])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[8] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[9] && r_s1_io_resp_region_2[9])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[9] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[10] && r_s1_io_resp_region_2[10])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[10] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[11] && r_s1_io_resp_region_2[11])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[11] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[12] && r_s1_io_resp_region_2[12])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[12] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[13] && r_s1_io_resp_region_2[13])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[13] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[14] && r_s1_io_resp_region_2[14])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[14] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[15] && r_s1_io_resp_region_2[15])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[15] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[16] && r_s1_io_resp_region_2[16])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[16] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[17] && r_s1_io_resp_region_2[17])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[17] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[18] && r_s1_io_resp_region_2[18])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[18] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[19] && r_s1_io_resp_region_2[19])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[19] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[20] && r_s1_io_resp_region_2[20])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[20] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[21] && r_s1_io_resp_region_2[21])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[21] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[22] && r_s1_io_resp_region_2[22])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[22] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[23] && r_s1_io_resp_region_2[23])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[23] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[24] && r_s1_io_resp_region_2[24])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[24] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[25] && r_s1_io_resp_region_2[25])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[25] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[26] && r_s1_io_resp_region_2[26])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[26] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[27] && r_s1_io_resp_region_2[27])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[27] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[28] && r_s1_io_resp_region_2[28])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[28] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_2[29] && r_s1_io_resp_region_2[29])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_2[29] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[0] && r_s1_io_resp_region_3[0])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[0] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[1] && r_s1_io_resp_region_3[1])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[1] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[2] && r_s1_io_resp_region_3[2])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[2] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[3] && r_s1_io_resp_region_3[3])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[3] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[4] && r_s1_io_resp_region_3[4])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[4] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[5] && r_s1_io_resp_region_3[5])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[5] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[6] && r_s1_io_resp_region_3[6])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[6] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[7] && r_s1_io_resp_region_3[7])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[7] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[8] && r_s1_io_resp_region_3[8])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[8] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[9] && r_s1_io_resp_region_3[9])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[9] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[10] && r_s1_io_resp_region_3[10])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[10] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[11] && r_s1_io_resp_region_3[11])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[11] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[12] && r_s1_io_resp_region_3[12])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[12] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[13] && r_s1_io_resp_region_3[13])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[13] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[14] && r_s1_io_resp_region_3[14])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[14] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[15] && r_s1_io_resp_region_3[15])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[15] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[16] && r_s1_io_resp_region_3[16])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[16] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[17] && r_s1_io_resp_region_3[17])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[17] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[18] && r_s1_io_resp_region_3[18])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[18] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[19] && r_s1_io_resp_region_3[19])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[19] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[20] && r_s1_io_resp_region_3[20])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[20] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[21] && r_s1_io_resp_region_3[21])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[21] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[22] && r_s1_io_resp_region_3[22])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[22] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[23] && r_s1_io_resp_region_3[23])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[23] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[24] && r_s1_io_resp_region_3[24])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[24] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[25] && r_s1_io_resp_region_3[25])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[25] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[26] && r_s1_io_resp_region_3[26])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[26] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[27] && r_s1_io_resp_region_3[27])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[27] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[28] && r_s1_io_resp_region_3[28])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[28] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_3[29] && r_s1_io_resp_region_3[29])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_3[29] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[0] && r_s1_io_resp_region_4[0])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[0] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[1] && r_s1_io_resp_region_4[1])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[1] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[2] && r_s1_io_resp_region_4[2])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[2] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[3] && r_s1_io_resp_region_4[3])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[3] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[4] && r_s1_io_resp_region_4[4])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[4] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[5] && r_s1_io_resp_region_4[5])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[5] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[6] && r_s1_io_resp_region_4[6])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[6] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[7] && r_s1_io_resp_region_4[7])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[7] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[8] && r_s1_io_resp_region_4[8])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[8] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[9] && r_s1_io_resp_region_4[9])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[9] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[10] && r_s1_io_resp_region_4[10])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[10] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[11] && r_s1_io_resp_region_4[11])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[11] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[12] && r_s1_io_resp_region_4[12])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[12] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[13] && r_s1_io_resp_region_4[13])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[13] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[14] && r_s1_io_resp_region_4[14])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[14] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[15] && r_s1_io_resp_region_4[15])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[15] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[16] && r_s1_io_resp_region_4[16])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[16] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[17] && r_s1_io_resp_region_4[17])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[17] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[18] && r_s1_io_resp_region_4[18])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[18] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[19] && r_s1_io_resp_region_4[19])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[19] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[20] && r_s1_io_resp_region_4[20])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[20] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[21] && r_s1_io_resp_region_4[21])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[21] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[22] && r_s1_io_resp_region_4[22])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[22] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[23] && r_s1_io_resp_region_4[23])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[23] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[24] && r_s1_io_resp_region_4[24])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[24] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[25] && r_s1_io_resp_region_4[25])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[25] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[26] && r_s1_io_resp_region_4[26])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[26] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[27] && r_s1_io_resp_region_4[27])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[27] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[28] && r_s1_io_resp_region_4[28])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[28] 未见过 0 和 1"); end
    if (!(r_s0_io_resp_region_4[29] && r_s1_io_resp_region_4[29])) begin cov_fail++; $display("[COV] RegionWays.io_resp_region_4[29] 未见过 0 和 1"); end
    if (!(r_s0_io_update_hit_0 && r_s1_io_update_hit_0)) begin cov_fail++; $display("[COV] RegionWays.io_update_hit_0 未见过 0 和 1"); end
    if (!(r_s0_io_update_hit_1 && r_s1_io_update_hit_1)) begin cov_fail++; $display("[COV] RegionWays.io_update_hit_1 未见过 0 和 1"); end
    if (!(r_s0_io_update_pointer_0[0] && r_s1_io_update_pointer_0[0])) begin cov_fail++; $display("[COV] RegionWays.io_update_pointer_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_update_pointer_0[1] && r_s1_io_update_pointer_0[1])) begin cov_fail++; $display("[COV] RegionWays.io_update_pointer_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_update_pointer_0[2] && r_s1_io_update_pointer_0[2])) begin cov_fail++; $display("[COV] RegionWays.io_update_pointer_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_update_pointer_0[3] && r_s1_io_update_pointer_0[3])) begin cov_fail++; $display("[COV] RegionWays.io_update_pointer_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_update_pointer_1[0] && r_s1_io_update_pointer_1[0])) begin cov_fail++; $display("[COV] RegionWays.io_update_pointer_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_update_pointer_1[1] && r_s1_io_update_pointer_1[1])) begin cov_fail++; $display("[COV] RegionWays.io_update_pointer_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_update_pointer_1[2] && r_s1_io_update_pointer_1[2])) begin cov_fail++; $display("[COV] RegionWays.io_update_pointer_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_update_pointer_1[3] && r_s1_io_update_pointer_1[3])) begin cov_fail++; $display("[COV] RegionWays.io_update_pointer_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_write_pointer[0] && r_s1_io_write_pointer[0])) begin cov_fail++; $display("[COV] RegionWays.io_write_pointer[0] 未见过 0 和 1"); end
    if (!(r_s0_io_write_pointer[1] && r_s1_io_write_pointer[1])) begin cov_fail++; $display("[COV] RegionWays.io_write_pointer[1] 未见过 0 和 1"); end
    if (!(r_s0_io_write_pointer[2] && r_s1_io_write_pointer[2])) begin cov_fail++; $display("[COV] RegionWays.io_write_pointer[2] 未见过 0 和 1"); end
    if (!(r_s0_io_write_pointer[3] && r_s1_io_write_pointer[3])) begin cov_fail++; $display("[COV] RegionWays.io_write_pointer[3] 未见过 0 和 1"); end
    $display("[ARM] RegionWays armed_at=%0d", r_armed_at);
    if (r_armed_at < 0) begin cov_fail++; $display("[ARM] RegionWays 从未 arm"); end
    $display("[COV] RegionWays.write_hit = %0d", r_cov_write_hit);
    if (r_cov_write_hit < 100) begin cov_fail++; $display("[COV] RegionWays.write_hit < 100"); end
    $display("[COV] RegionWays.write_fill_free = %0d", r_cov_write_fill_free);
    if (r_cov_write_fill_free < 100) begin cov_fail++; $display("[COV] RegionWays.write_fill_free < 100"); end
    $display("[COV] RegionWays.write_plru_replace = %0d", r_cov_write_plru_replace);
    if (r_cov_write_plru_replace < 100) begin cov_fail++; $display("[COV] RegionWays.write_plru_replace < 100"); end
    $display("[COV] RegionWays.update_bypass = %0d", r_cov_update_bypass);
    if (r_cov_update_bypass < 100) begin cov_fail++; $display("[COV] RegionWays.update_bypass < 100"); end
    $display("[COV] RegionWays.update_table_hit = %0d", r_cov_update_table_hit);
    if (r_cov_update_table_hit < 100) begin cov_fail++; $display("[COV] RegionWays.update_table_hit < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
