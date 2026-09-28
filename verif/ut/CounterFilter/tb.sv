// 自动生成：verif/ut/CounterFilter/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// CounterFilter 双例化逐拍比对：golden CounterFilter vs 重写 CounterFilter_xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= CounterFilter =================
  int unsigned cf_mode = 0;
  logic cf_reset;
  logic cf_io_ld_in_0_valid;
  logic [7:0] cf_io_ld_in_0_bits_idx;
  logic [1:0] cf_io_ld_in_0_bits_way;
  logic cf_io_ld_in_1_valid;
  logic [7:0] cf_io_ld_in_1_bits_idx;
  logic [1:0] cf_io_ld_in_1_bits_way;
  logic cf_io_ld_in_2_valid;
  logic [7:0] cf_io_ld_in_2_bits_idx;
  logic [1:0] cf_io_ld_in_2_bits_way;
  logic cf_io_query_0_req_valid;
  logic [7:0] cf_io_query_0_req_bits_idx;
  logic [1:0] cf_io_query_0_req_bits_way;
  wire  cf_g_io_query_0_resp, cf_i_io_query_0_resp;
  logic cf_s0_io_query_0_resp = '0, cf_s1_io_query_0_resp = '0;
  logic cf_io_query_1_req_valid;
  logic [7:0] cf_io_query_1_req_bits_idx;
  logic [1:0] cf_io_query_1_req_bits_way;
  wire  cf_g_io_query_1_resp, cf_i_io_query_1_resp;
  logic cf_s0_io_query_1_resp = '0, cf_s1_io_query_1_resp = '0;
  logic cf_io_query_2_req_valid;
  logic [7:0] cf_io_query_2_req_bits_idx;
  logic [1:0] cf_io_query_2_req_bits_way;
  wire  cf_g_io_query_2_resp, cf_i_io_query_2_resp;
  logic cf_s0_io_query_2_resp = '0, cf_s1_io_query_2_resp = '0;
  int cf_cov_alloc0 = 0;
  int cf_cov_alloc1 = 0;
  int cf_cov_alloc2 = 0;
  int cf_cov_reject = 0;
  int cf_cov_deq1 = 0;
  int cf_cov_deq2 = 0;
  int cf_cov_deq3 = 0;
  int cf_cov_enq_wrap = 0;
  int cf_cov_deq_wrap = 0;
  int cf_cov_hit0 = 0;
  int cf_cov_hit2 = 0;
  int cf_cov_miss0 = 0;
  logic [0:0] cf_armed = '0;
  int cf_armed_at = -1;
  CounterFilter cf_u_gold (
    .clock(clk),
    .reset(cf_reset),
    .io_ld_in_0_valid(cf_io_ld_in_0_valid),
    .io_ld_in_0_bits_idx(cf_io_ld_in_0_bits_idx),
    .io_ld_in_0_bits_way(cf_io_ld_in_0_bits_way),
    .io_ld_in_1_valid(cf_io_ld_in_1_valid),
    .io_ld_in_1_bits_idx(cf_io_ld_in_1_bits_idx),
    .io_ld_in_1_bits_way(cf_io_ld_in_1_bits_way),
    .io_ld_in_2_valid(cf_io_ld_in_2_valid),
    .io_ld_in_2_bits_idx(cf_io_ld_in_2_bits_idx),
    .io_ld_in_2_bits_way(cf_io_ld_in_2_bits_way),
    .io_query_0_req_valid(cf_io_query_0_req_valid),
    .io_query_0_req_bits_idx(cf_io_query_0_req_bits_idx),
    .io_query_0_req_bits_way(cf_io_query_0_req_bits_way),
    .io_query_0_resp(cf_g_io_query_0_resp),
    .io_query_1_req_valid(cf_io_query_1_req_valid),
    .io_query_1_req_bits_idx(cf_io_query_1_req_bits_idx),
    .io_query_1_req_bits_way(cf_io_query_1_req_bits_way),
    .io_query_1_resp(cf_g_io_query_1_resp),
    .io_query_2_req_valid(cf_io_query_2_req_valid),
    .io_query_2_req_bits_idx(cf_io_query_2_req_bits_idx),
    .io_query_2_req_bits_way(cf_io_query_2_req_bits_way),
    .io_query_2_resp(cf_g_io_query_2_resp)
  );
  CounterFilter_xs cf_u_impl (
    .clock(clk),
    .reset(cf_reset),
    .io_ld_in_0_valid(cf_io_ld_in_0_valid),
    .io_ld_in_0_bits_idx(cf_io_ld_in_0_bits_idx),
    .io_ld_in_0_bits_way(cf_io_ld_in_0_bits_way),
    .io_ld_in_1_valid(cf_io_ld_in_1_valid),
    .io_ld_in_1_bits_idx(cf_io_ld_in_1_bits_idx),
    .io_ld_in_1_bits_way(cf_io_ld_in_1_bits_way),
    .io_ld_in_2_valid(cf_io_ld_in_2_valid),
    .io_ld_in_2_bits_idx(cf_io_ld_in_2_bits_idx),
    .io_ld_in_2_bits_way(cf_io_ld_in_2_bits_way),
    .io_query_0_req_valid(cf_io_query_0_req_valid),
    .io_query_0_req_bits_idx(cf_io_query_0_req_bits_idx),
    .io_query_0_req_bits_way(cf_io_query_0_req_bits_way),
    .io_query_0_resp(cf_i_io_query_0_resp),
    .io_query_1_req_valid(cf_io_query_1_req_valid),
    .io_query_1_req_bits_idx(cf_io_query_1_req_bits_idx),
    .io_query_1_req_bits_way(cf_io_query_1_req_bits_way),
    .io_query_1_resp(cf_i_io_query_1_resp),
    .io_query_2_req_valid(cf_io_query_2_req_valid),
    .io_query_2_req_bits_idx(cf_io_query_2_req_bits_idx),
    .io_query_2_req_bits_way(cf_io_query_2_req_bits_way),
    .io_query_2_resp(cf_i_io_query_2_resp)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 500 == 0) cf_mode = $urandom_range(0, 15);
      cf_io_ld_in_0_valid = 1'($urandom);
      cf_io_ld_in_0_bits_idx = 8'($urandom);
      cf_io_ld_in_0_bits_way = 2'($urandom);
      cf_io_ld_in_1_valid = 1'($urandom);
      cf_io_ld_in_1_bits_idx = 8'($urandom);
      cf_io_ld_in_1_bits_way = 2'($urandom);
      cf_io_ld_in_2_valid = 1'($urandom);
      cf_io_ld_in_2_bits_idx = 8'($urandom);
      cf_io_ld_in_2_bits_way = 2'($urandom);
      cf_io_query_0_req_valid = 1'($urandom);
      cf_io_query_0_req_bits_idx = 8'($urandom);
      cf_io_query_0_req_bits_way = 2'($urandom);
      cf_io_query_1_req_valid = 1'($urandom);
      cf_io_query_1_req_bits_idx = 8'($urandom);
      cf_io_query_1_req_bits_way = 2'($urandom);
      cf_io_query_2_req_valid = 1'($urandom);
      cf_io_query_2_req_bits_idx = 8'($urandom);
      cf_io_query_2_req_bits_way = 2'($urandom);
      cf_reset = (cyc < RESET_CYC) || ($urandom_range(0, 29999) == 0);
      begin : stim_cf
        cf_io_ld_in_0_bits_idx = 8'($urandom_range(0, 3));
        cf_io_ld_in_1_bits_idx = 8'($urandom_range(0, 3));
        cf_io_ld_in_2_bits_idx = 8'($urandom_range(0, 3));
        cf_io_query_0_req_bits_idx = 8'($urandom_range(0, 3));
        cf_io_query_1_req_bits_idx = 8'($urandom_range(0, 3));
        cf_io_query_2_req_bits_idx = 8'($urandom_range(0, 3));
        case (cf_mode % 3)
          0: begin  // 稀疏
            cf_io_ld_in_0_valid = ($urandom_range(0, 7) == 0);
            cf_io_ld_in_1_valid = ($urandom_range(0, 7) == 0);
            cf_io_ld_in_2_valid = ($urandom_range(0, 7) == 0);
          end
          1: ;      // 半数
          2: begin  // 全满
            cf_io_ld_in_0_valid = 1'b1; cf_io_ld_in_1_valid = 1'b1; cf_io_ld_in_2_valid = 1'b1;
          end
        endcase
      end
      #4;
      cf_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&cf_armed)) begin
        checks++;
        if (cf_g_io_query_0_resp !== cf_i_io_query_0_resp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CounterFilter.io_query_0_resp g=%h i=%h", cyc, cf_g_io_query_0_resp, cf_i_io_query_0_resp);
        end
        cf_s1_io_query_0_resp |= cf_g_io_query_0_resp;
        cf_s0_io_query_0_resp |= ~cf_g_io_query_0_resp;
        checks++;
        if (cf_g_io_query_1_resp !== cf_i_io_query_1_resp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CounterFilter.io_query_1_resp g=%h i=%h", cyc, cf_g_io_query_1_resp, cf_i_io_query_1_resp);
        end
        cf_s1_io_query_1_resp |= cf_g_io_query_1_resp;
        cf_s0_io_query_1_resp |= ~cf_g_io_query_1_resp;
        checks++;
        if (cf_g_io_query_2_resp !== cf_i_io_query_2_resp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CounterFilter.io_query_2_resp g=%h i=%h", cyc, cf_g_io_query_2_resp, cf_i_io_query_2_resp);
        end
        cf_s1_io_query_2_resp |= cf_g_io_query_2_resp;
        cf_s0_io_query_2_resp |= ~cf_g_io_query_2_resp;
        if (cf_u_gold.canAlloc_0) cf_cov_alloc0++;
        if (cf_u_gold.canAlloc_1) cf_cov_alloc1++;
        if (cf_u_gold.canAlloc_2) cf_cov_alloc2++;
        if ((cf_io_ld_in_0_valid && !cf_u_gold.canAlloc_0) || (cf_io_ld_in_2_valid && !cf_u_gold.canAlloc_2)) cf_cov_reject++;
        if (cf_u_gold.last3CycleAlloc == 2'd1) cf_cov_deq1++;
        if (cf_u_gold.last3CycleAlloc == 2'd2) cf_cov_deq2++;
        if (cf_u_gold.last3CycleAlloc == 2'd3) cf_cov_deq3++;
        if ((|cf_u_gold._GEN_64) && cf_u_gold.enqPtrExt_0_reverse_flag) cf_cov_enq_wrap++;
        if (cf_u_gold.deqPtrExt_0_reverse_flag && (|cf_u_gold.last3CycleAlloc)) cf_cov_deq_wrap++;
        if (cf_g_io_query_0_resp) cf_cov_hit0++;
        if (cf_g_io_query_2_resp) cf_cov_hit2++;
        if (cf_io_query_0_req_valid && !cf_g_io_query_0_resp) cf_cov_miss0++;
      end
      if (cf_armed_at < 0 && (&cf_armed)) cf_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(cf_s0_io_query_0_resp && cf_s1_io_query_0_resp)) begin cov_fail++; $display("[COV] CounterFilter.io_query_0_resp 未见过 0 和 1"); end
    if (!(cf_s0_io_query_1_resp && cf_s1_io_query_1_resp)) begin cov_fail++; $display("[COV] CounterFilter.io_query_1_resp 未见过 0 和 1"); end
    if (!(cf_s0_io_query_2_resp && cf_s1_io_query_2_resp)) begin cov_fail++; $display("[COV] CounterFilter.io_query_2_resp 未见过 0 和 1"); end
    $display("[ARM] CounterFilter armed_at=%0d", cf_armed_at);
    if (cf_armed_at < 0) begin cov_fail++; $display("[ARM] CounterFilter 从未 arm"); end
    $display("[COV] CounterFilter.alloc0 = %0d", cf_cov_alloc0);
    if (cf_cov_alloc0 < 500) begin cov_fail++; $display("[COV] CounterFilter.alloc0 < 500"); end
    $display("[COV] CounterFilter.alloc1 = %0d", cf_cov_alloc1);
    if (cf_cov_alloc1 < 500) begin cov_fail++; $display("[COV] CounterFilter.alloc1 < 500"); end
    $display("[COV] CounterFilter.alloc2 = %0d", cf_cov_alloc2);
    if (cf_cov_alloc2 < 500) begin cov_fail++; $display("[COV] CounterFilter.alloc2 < 500"); end
    $display("[COV] CounterFilter.reject = %0d", cf_cov_reject);
    if (cf_cov_reject < 500) begin cov_fail++; $display("[COV] CounterFilter.reject < 500"); end
    $display("[COV] CounterFilter.deq1 = %0d", cf_cov_deq1);
    if (cf_cov_deq1 < 500) begin cov_fail++; $display("[COV] CounterFilter.deq1 < 500"); end
    $display("[COV] CounterFilter.deq2 = %0d", cf_cov_deq2);
    if (cf_cov_deq2 < 500) begin cov_fail++; $display("[COV] CounterFilter.deq2 < 500"); end
    $display("[COV] CounterFilter.deq3 = %0d", cf_cov_deq3);
    if (cf_cov_deq3 < 500) begin cov_fail++; $display("[COV] CounterFilter.deq3 < 500"); end
    $display("[COV] CounterFilter.enq_wrap = %0d", cf_cov_enq_wrap);
    if (cf_cov_enq_wrap < 500) begin cov_fail++; $display("[COV] CounterFilter.enq_wrap < 500"); end
    $display("[COV] CounterFilter.deq_wrap = %0d", cf_cov_deq_wrap);
    if (cf_cov_deq_wrap < 500) begin cov_fail++; $display("[COV] CounterFilter.deq_wrap < 500"); end
    $display("[COV] CounterFilter.hit0 = %0d", cf_cov_hit0);
    if (cf_cov_hit0 < 500) begin cov_fail++; $display("[COV] CounterFilter.hit0 < 500"); end
    $display("[COV] CounterFilter.hit2 = %0d", cf_cov_hit2);
    if (cf_cov_hit2 < 500) begin cov_fail++; $display("[COV] CounterFilter.hit2 < 500"); end
    $display("[COV] CounterFilter.miss0 = %0d", cf_cov_miss0);
    if (cf_cov_miss0 < 500) begin cov_fail++; $display("[COV] CounterFilter.miss0 < 500"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
