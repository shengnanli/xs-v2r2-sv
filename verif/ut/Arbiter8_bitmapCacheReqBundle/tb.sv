// 自动生成：verif/ut/Arbiter8_bitmapCacheReqBundle/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// Arbiter8_bitmapCacheReqBundle 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= Arbiter8_bitmapCacheReqBundle =================
  int unsigned b_mode = 0;
  logic [7:0] b_vmap;
  logic b_io_in_0_valid;
  logic [35:0] b_io_in_0_bits_tag;
  logic b_io_in_1_valid;
  logic [35:0] b_io_in_1_bits_tag;
  logic b_io_in_2_valid;
  logic [35:0] b_io_in_2_bits_tag;
  logic b_io_in_3_valid;
  logic [35:0] b_io_in_3_bits_tag;
  logic b_io_in_4_valid;
  logic [35:0] b_io_in_4_bits_tag;
  logic b_io_in_5_valid;
  logic [35:0] b_io_in_5_bits_tag;
  logic b_io_in_6_valid;
  logic [35:0] b_io_in_6_bits_tag;
  logic b_io_in_7_valid;
  logic [35:0] b_io_in_7_bits_tag;
  wire  b_g_io_out_valid, b_i_io_out_valid;
  logic b_s0_io_out_valid = '0, b_s1_io_out_valid = '0;
  wire  [7:0] b_g_io_out_bits_order, b_i_io_out_bits_order;
  logic [7:0] b_s0_io_out_bits_order = '0, b_s1_io_out_bits_order = '0;
  wire  [35:0] b_g_io_out_bits_tag, b_i_io_out_bits_tag;
  logic [35:0] b_s0_io_out_bits_tag = '0, b_s1_io_out_bits_tag = '0;
  wire  [2:0] b_g_io_chosen, b_i_io_chosen;
  logic [2:0] b_s0_io_chosen = '0, b_s1_io_chosen = '0;
  int b_cov_none = 0;
  int b_cov_win0 = 0;
  int b_cov_win1 = 0;
  int b_cov_win2 = 0;
  int b_cov_win3 = 0;
  int b_cov_win4 = 0;
  int b_cov_win5 = 0;
  int b_cov_win6 = 0;
  int b_cov_win7 = 0;
  logic [0:0] b_armed = '0;
  int b_armed_at = -1;
  Arbiter8_bitmapCacheReqBundle b_u_gold (
    .io_in_0_valid(b_io_in_0_valid),
    .io_in_0_bits_tag(b_io_in_0_bits_tag),
    .io_in_1_valid(b_io_in_1_valid),
    .io_in_1_bits_tag(b_io_in_1_bits_tag),
    .io_in_2_valid(b_io_in_2_valid),
    .io_in_2_bits_tag(b_io_in_2_bits_tag),
    .io_in_3_valid(b_io_in_3_valid),
    .io_in_3_bits_tag(b_io_in_3_bits_tag),
    .io_in_4_valid(b_io_in_4_valid),
    .io_in_4_bits_tag(b_io_in_4_bits_tag),
    .io_in_5_valid(b_io_in_5_valid),
    .io_in_5_bits_tag(b_io_in_5_bits_tag),
    .io_in_6_valid(b_io_in_6_valid),
    .io_in_6_bits_tag(b_io_in_6_bits_tag),
    .io_in_7_valid(b_io_in_7_valid),
    .io_in_7_bits_tag(b_io_in_7_bits_tag),
    .io_out_valid(b_g_io_out_valid),
    .io_out_bits_order(b_g_io_out_bits_order),
    .io_out_bits_tag(b_g_io_out_bits_tag),
    .io_chosen(b_g_io_chosen)
  );
  Arbiter8_bitmapCacheReqBundle_xs b_u_impl (
    .io_in_0_valid(b_io_in_0_valid),
    .io_in_0_bits_tag(b_io_in_0_bits_tag),
    .io_in_1_valid(b_io_in_1_valid),
    .io_in_1_bits_tag(b_io_in_1_bits_tag),
    .io_in_2_valid(b_io_in_2_valid),
    .io_in_2_bits_tag(b_io_in_2_bits_tag),
    .io_in_3_valid(b_io_in_3_valid),
    .io_in_3_bits_tag(b_io_in_3_bits_tag),
    .io_in_4_valid(b_io_in_4_valid),
    .io_in_4_bits_tag(b_io_in_4_bits_tag),
    .io_in_5_valid(b_io_in_5_valid),
    .io_in_5_bits_tag(b_io_in_5_bits_tag),
    .io_in_6_valid(b_io_in_6_valid),
    .io_in_6_bits_tag(b_io_in_6_bits_tag),
    .io_in_7_valid(b_io_in_7_valid),
    .io_in_7_bits_tag(b_io_in_7_bits_tag),
    .io_out_valid(b_i_io_out_valid),
    .io_out_bits_order(b_i_io_out_bits_order),
    .io_out_bits_tag(b_i_io_out_bits_tag),
    .io_chosen(b_i_io_chosen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) b_mode = $urandom_range(0, 15);
      b_io_in_0_valid = 1'($urandom);
      b_io_in_0_bits_tag = 36'({$urandom, $urandom});
      b_io_in_1_valid = 1'($urandom);
      b_io_in_1_bits_tag = 36'({$urandom, $urandom});
      b_io_in_2_valid = 1'($urandom);
      b_io_in_2_bits_tag = 36'({$urandom, $urandom});
      b_io_in_3_valid = 1'($urandom);
      b_io_in_3_bits_tag = 36'({$urandom, $urandom});
      b_io_in_4_valid = 1'($urandom);
      b_io_in_4_bits_tag = 36'({$urandom, $urandom});
      b_io_in_5_valid = 1'($urandom);
      b_io_in_5_bits_tag = 36'({$urandom, $urandom});
      b_io_in_6_valid = 1'($urandom);
      b_io_in_6_bits_tag = 36'({$urandom, $urandom});
      b_io_in_7_valid = 1'($urandom);
      b_io_in_7_bits_tag = 36'({$urandom, $urandom});
      begin : stim_b
        case (cyc % 4)
          0: b_vmap = 8'h00;
          1: b_vmap = 8'h01 << $urandom_range(0, 7);
          2: b_vmap = 8'($urandom) & 8'($urandom) & 8'($urandom);
          default: b_vmap = 8'($urandom);
        endcase
        {b_io_in_7_valid, b_io_in_6_valid, b_io_in_5_valid, b_io_in_4_valid,
         b_io_in_3_valid, b_io_in_2_valid, b_io_in_1_valid, b_io_in_0_valid} = b_vmap;
      end
      #4;
      b_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&b_armed)) begin
        checks++;
        if (b_g_io_out_valid !== b_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_bitmapCacheReqBundle.io_out_valid g=%h i=%h", cyc, b_g_io_out_valid, b_i_io_out_valid);
        end
        b_s1_io_out_valid |= b_g_io_out_valid;
        b_s0_io_out_valid |= ~b_g_io_out_valid;
        checks++;
        if (b_g_io_out_bits_order !== b_i_io_out_bits_order) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_bitmapCacheReqBundle.io_out_bits_order g=%h i=%h", cyc, b_g_io_out_bits_order, b_i_io_out_bits_order);
        end
        b_s1_io_out_bits_order |= b_g_io_out_bits_order;
        b_s0_io_out_bits_order |= ~b_g_io_out_bits_order;
        checks++;
        if (b_g_io_out_bits_tag !== b_i_io_out_bits_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_bitmapCacheReqBundle.io_out_bits_tag g=%h i=%h", cyc, b_g_io_out_bits_tag, b_i_io_out_bits_tag);
        end
        b_s1_io_out_bits_tag |= b_g_io_out_bits_tag;
        b_s0_io_out_bits_tag |= ~b_g_io_out_bits_tag;
        checks++;
        if (b_g_io_chosen !== b_i_io_chosen) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_bitmapCacheReqBundle.io_chosen g=%h i=%h", cyc, b_g_io_chosen, b_i_io_chosen);
        end
        b_s1_io_chosen |= b_g_io_chosen;
        b_s0_io_chosen |= ~b_g_io_chosen;
        if (!b_g_io_out_valid) b_cov_none++;
        if (b_io_in_0_valid && 1) b_cov_win0++;
        if (b_io_in_1_valid && !b_io_in_0_valid) b_cov_win1++;
        if (b_io_in_2_valid && !b_io_in_0_valid && !b_io_in_1_valid) b_cov_win2++;
        if (b_io_in_3_valid && !b_io_in_0_valid && !b_io_in_1_valid && !b_io_in_2_valid) b_cov_win3++;
        if (b_io_in_4_valid && !b_io_in_0_valid && !b_io_in_1_valid && !b_io_in_2_valid && !b_io_in_3_valid) b_cov_win4++;
        if (b_io_in_5_valid && !b_io_in_0_valid && !b_io_in_1_valid && !b_io_in_2_valid && !b_io_in_3_valid && !b_io_in_4_valid) b_cov_win5++;
        if (b_io_in_6_valid && !b_io_in_0_valid && !b_io_in_1_valid && !b_io_in_2_valid && !b_io_in_3_valid && !b_io_in_4_valid && !b_io_in_5_valid) b_cov_win6++;
        if (b_io_in_7_valid && !b_io_in_0_valid && !b_io_in_1_valid && !b_io_in_2_valid && !b_io_in_3_valid && !b_io_in_4_valid && !b_io_in_5_valid && !b_io_in_6_valid) b_cov_win7++;
      end
      if (b_armed_at < 0 && (&b_armed)) b_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(b_s0_io_out_valid && b_s1_io_out_valid)) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_valid 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_order[0] && b_s1_io_out_bits_order[0])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_order[0] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_order[1] && b_s1_io_out_bits_order[1])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_order[1] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_order[2] && b_s1_io_out_bits_order[2])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_order[2] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[0] && b_s1_io_out_bits_tag[0])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[0] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[1] && b_s1_io_out_bits_tag[1])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[1] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[2] && b_s1_io_out_bits_tag[2])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[2] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[3] && b_s1_io_out_bits_tag[3])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[3] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[4] && b_s1_io_out_bits_tag[4])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[4] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[5] && b_s1_io_out_bits_tag[5])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[5] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[6] && b_s1_io_out_bits_tag[6])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[6] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[7] && b_s1_io_out_bits_tag[7])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[7] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[8] && b_s1_io_out_bits_tag[8])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[8] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[9] && b_s1_io_out_bits_tag[9])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[9] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[10] && b_s1_io_out_bits_tag[10])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[10] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[11] && b_s1_io_out_bits_tag[11])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[11] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[12] && b_s1_io_out_bits_tag[12])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[12] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[13] && b_s1_io_out_bits_tag[13])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[13] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[14] && b_s1_io_out_bits_tag[14])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[14] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[15] && b_s1_io_out_bits_tag[15])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[15] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[16] && b_s1_io_out_bits_tag[16])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[16] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[17] && b_s1_io_out_bits_tag[17])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[17] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[18] && b_s1_io_out_bits_tag[18])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[18] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[19] && b_s1_io_out_bits_tag[19])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[19] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[20] && b_s1_io_out_bits_tag[20])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[20] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[21] && b_s1_io_out_bits_tag[21])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[21] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[22] && b_s1_io_out_bits_tag[22])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[22] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[23] && b_s1_io_out_bits_tag[23])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[23] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[24] && b_s1_io_out_bits_tag[24])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[24] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[25] && b_s1_io_out_bits_tag[25])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[25] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[26] && b_s1_io_out_bits_tag[26])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[26] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[27] && b_s1_io_out_bits_tag[27])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[27] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[28] && b_s1_io_out_bits_tag[28])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[28] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[29] && b_s1_io_out_bits_tag[29])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[29] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[30] && b_s1_io_out_bits_tag[30])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[30] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[31] && b_s1_io_out_bits_tag[31])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[31] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[32] && b_s1_io_out_bits_tag[32])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[32] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[33] && b_s1_io_out_bits_tag[33])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[33] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[34] && b_s1_io_out_bits_tag[34])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[34] 未见过 0 和 1"); end
    if (!(b_s0_io_out_bits_tag[35] && b_s1_io_out_bits_tag[35])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_out_bits_tag[35] 未见过 0 和 1"); end
    if (!(b_s0_io_chosen[0] && b_s1_io_chosen[0])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_chosen[0] 未见过 0 和 1"); end
    if (!(b_s0_io_chosen[1] && b_s1_io_chosen[1])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_chosen[1] 未见过 0 和 1"); end
    if (!(b_s0_io_chosen[2] && b_s1_io_chosen[2])) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.io_chosen[2] 未见过 0 和 1"); end
    $display("[ARM] Arbiter8_bitmapCacheReqBundle armed_at=%0d", b_armed_at);
    if (b_armed_at < 0) begin cov_fail++; $display("[ARM] Arbiter8_bitmapCacheReqBundle 从未 arm"); end
    $display("[COV] Arbiter8_bitmapCacheReqBundle.none = %0d", b_cov_none);
    if (b_cov_none < 200) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.none < 200"); end
    $display("[COV] Arbiter8_bitmapCacheReqBundle.win0 = %0d", b_cov_win0);
    if (b_cov_win0 < 200) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.win0 < 200"); end
    $display("[COV] Arbiter8_bitmapCacheReqBundle.win1 = %0d", b_cov_win1);
    if (b_cov_win1 < 200) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.win1 < 200"); end
    $display("[COV] Arbiter8_bitmapCacheReqBundle.win2 = %0d", b_cov_win2);
    if (b_cov_win2 < 200) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.win2 < 200"); end
    $display("[COV] Arbiter8_bitmapCacheReqBundle.win3 = %0d", b_cov_win3);
    if (b_cov_win3 < 200) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.win3 < 200"); end
    $display("[COV] Arbiter8_bitmapCacheReqBundle.win4 = %0d", b_cov_win4);
    if (b_cov_win4 < 200) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.win4 < 200"); end
    $display("[COV] Arbiter8_bitmapCacheReqBundle.win5 = %0d", b_cov_win5);
    if (b_cov_win5 < 200) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.win5 < 200"); end
    $display("[COV] Arbiter8_bitmapCacheReqBundle.win6 = %0d", b_cov_win6);
    if (b_cov_win6 < 200) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.win6 < 200"); end
    $display("[COV] Arbiter8_bitmapCacheReqBundle.win7 = %0d", b_cov_win7);
    if (b_cov_win7 < 200) begin cov_fail++; $display("[COV] Arbiter8_bitmapCacheReqBundle.win7 < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
