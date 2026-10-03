// tb —— MbistIntfL2：L2 MBIST 树根（MbistInterface，单子树退化为直通）双例化 UT。
// 本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= MbistIntfL2 =================
  int unsigned mi_mode = 0;
  wire  [5:0] mi_g_toPipeline_0_array, mi_i_toPipeline_0_array;
  logic [5:0] mi_s0_toPipeline_0_array = '0, mi_s1_toPipeline_0_array = '0;
  wire  mi_g_toPipeline_0_all, mi_i_toPipeline_0_all;
  logic mi_s0_toPipeline_0_all = '0, mi_s1_toPipeline_0_all = '0;
  wire  mi_g_toPipeline_0_req, mi_i_toPipeline_0_req;
  logic mi_s0_toPipeline_0_req = '0, mi_s1_toPipeline_0_req = '0;
  logic mi_toPipeline_0_ack;
  wire  mi_g_toPipeline_0_writeen, mi_i_toPipeline_0_writeen;
  logic mi_s0_toPipeline_0_writeen = '0, mi_s1_toPipeline_0_writeen = '0;
  wire  [7:0] mi_g_toPipeline_0_be, mi_i_toPipeline_0_be;
  logic [7:0] mi_s0_toPipeline_0_be = '0, mi_s1_toPipeline_0_be = '0;
  wire  [12:0] mi_g_toPipeline_0_addr, mi_i_toPipeline_0_addr;
  logic [12:0] mi_s0_toPipeline_0_addr = '0, mi_s1_toPipeline_0_addr = '0;
  wire  [136:0] mi_g_toPipeline_0_indata, mi_i_toPipeline_0_indata;
  logic [136:0] mi_s0_toPipeline_0_indata = '0, mi_s1_toPipeline_0_indata = '0;
  wire  mi_g_toPipeline_0_readen, mi_i_toPipeline_0_readen;
  logic mi_s0_toPipeline_0_readen = '0, mi_s1_toPipeline_0_readen = '0;
  wire  [12:0] mi_g_toPipeline_0_addr_rd, mi_i_toPipeline_0_addr_rd;
  logic [12:0] mi_s0_toPipeline_0_addr_rd = '0, mi_s1_toPipeline_0_addr_rd = '0;
  logic [136:0] mi_toPipeline_0_outdata;
  logic [5:0] mi_mbist_array;
  logic mi_mbist_all;
  logic mi_mbist_req;
  wire  mi_g_mbist_ack, mi_i_mbist_ack;
  logic mi_s0_mbist_ack = '0, mi_s1_mbist_ack = '0;
  logic mi_mbist_writeen;
  logic [7:0] mi_mbist_be;
  logic [12:0] mi_mbist_addr;
  logic [136:0] mi_mbist_indata;
  logic mi_mbist_readen;
  logic [12:0] mi_mbist_addr_rd;
  wire  [136:0] mi_g_mbist_outdata, mi_i_mbist_outdata;
  logic [136:0] mi_s0_mbist_outdata = '0, mi_s1_mbist_outdata = '0;
  int mi_cov_req = 0;
  int mi_cov_ack = 0;
  logic [0:0] mi_armed = '0;
  int mi_armed_at = -1;
  MbistIntfL2 mi_u_gold (
    .toPipeline_0_array(mi_g_toPipeline_0_array),
    .toPipeline_0_all(mi_g_toPipeline_0_all),
    .toPipeline_0_req(mi_g_toPipeline_0_req),
    .toPipeline_0_ack(mi_toPipeline_0_ack),
    .toPipeline_0_writeen(mi_g_toPipeline_0_writeen),
    .toPipeline_0_be(mi_g_toPipeline_0_be),
    .toPipeline_0_addr(mi_g_toPipeline_0_addr),
    .toPipeline_0_indata(mi_g_toPipeline_0_indata),
    .toPipeline_0_readen(mi_g_toPipeline_0_readen),
    .toPipeline_0_addr_rd(mi_g_toPipeline_0_addr_rd),
    .toPipeline_0_outdata(mi_toPipeline_0_outdata),
    .mbist_array(mi_mbist_array),
    .mbist_all(mi_mbist_all),
    .mbist_req(mi_mbist_req),
    .mbist_ack(mi_g_mbist_ack),
    .mbist_writeen(mi_mbist_writeen),
    .mbist_be(mi_mbist_be),
    .mbist_addr(mi_mbist_addr),
    .mbist_indata(mi_mbist_indata),
    .mbist_readen(mi_mbist_readen),
    .mbist_addr_rd(mi_mbist_addr_rd),
    .mbist_outdata(mi_g_mbist_outdata)
  );
  MbistIntfL2_xs mi_u_impl (
    .toPipeline_0_array(mi_i_toPipeline_0_array),
    .toPipeline_0_all(mi_i_toPipeline_0_all),
    .toPipeline_0_req(mi_i_toPipeline_0_req),
    .toPipeline_0_ack(mi_toPipeline_0_ack),
    .toPipeline_0_writeen(mi_i_toPipeline_0_writeen),
    .toPipeline_0_be(mi_i_toPipeline_0_be),
    .toPipeline_0_addr(mi_i_toPipeline_0_addr),
    .toPipeline_0_indata(mi_i_toPipeline_0_indata),
    .toPipeline_0_readen(mi_i_toPipeline_0_readen),
    .toPipeline_0_addr_rd(mi_i_toPipeline_0_addr_rd),
    .toPipeline_0_outdata(mi_toPipeline_0_outdata),
    .mbist_array(mi_mbist_array),
    .mbist_all(mi_mbist_all),
    .mbist_req(mi_mbist_req),
    .mbist_ack(mi_i_mbist_ack),
    .mbist_writeen(mi_mbist_writeen),
    .mbist_be(mi_mbist_be),
    .mbist_addr(mi_mbist_addr),
    .mbist_indata(mi_mbist_indata),
    .mbist_readen(mi_mbist_readen),
    .mbist_addr_rd(mi_mbist_addr_rd),
    .mbist_outdata(mi_i_mbist_outdata)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) mi_mode = $urandom_range(0, 15);
      mi_toPipeline_0_ack = 1'($urandom);
      mi_toPipeline_0_outdata = 137'({$urandom, $urandom, $urandom, $urandom, $urandom});
      mi_mbist_array = 6'($urandom);
      mi_mbist_all = 1'($urandom);
      mi_mbist_req = 1'($urandom);
      mi_mbist_writeen = 1'($urandom);
      mi_mbist_be = 8'($urandom);
      mi_mbist_addr = 13'($urandom);
      mi_mbist_indata = 137'({$urandom, $urandom, $urandom, $urandom, $urandom});
      mi_mbist_readen = 1'($urandom);
      mi_mbist_addr_rd = 13'($urandom);
      #4;
      mi_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&mi_armed)) begin
        checks++;
        if (mi_g_toPipeline_0_array !== mi_i_toPipeline_0_array) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistIntfL2.toPipeline_0_array g=%h i=%h", cyc, mi_g_toPipeline_0_array, mi_i_toPipeline_0_array);
        end
        mi_s1_toPipeline_0_array |= mi_g_toPipeline_0_array;
        mi_s0_toPipeline_0_array |= ~mi_g_toPipeline_0_array;
        checks++;
        if (mi_g_toPipeline_0_all !== mi_i_toPipeline_0_all) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistIntfL2.toPipeline_0_all g=%h i=%h", cyc, mi_g_toPipeline_0_all, mi_i_toPipeline_0_all);
        end
        mi_s1_toPipeline_0_all |= mi_g_toPipeline_0_all;
        mi_s0_toPipeline_0_all |= ~mi_g_toPipeline_0_all;
        checks++;
        if (mi_g_toPipeline_0_req !== mi_i_toPipeline_0_req) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistIntfL2.toPipeline_0_req g=%h i=%h", cyc, mi_g_toPipeline_0_req, mi_i_toPipeline_0_req);
        end
        mi_s1_toPipeline_0_req |= mi_g_toPipeline_0_req;
        mi_s0_toPipeline_0_req |= ~mi_g_toPipeline_0_req;
        checks++;
        if (mi_g_toPipeline_0_writeen !== mi_i_toPipeline_0_writeen) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistIntfL2.toPipeline_0_writeen g=%h i=%h", cyc, mi_g_toPipeline_0_writeen, mi_i_toPipeline_0_writeen);
        end
        mi_s1_toPipeline_0_writeen |= mi_g_toPipeline_0_writeen;
        mi_s0_toPipeline_0_writeen |= ~mi_g_toPipeline_0_writeen;
        checks++;
        if (mi_g_toPipeline_0_be !== mi_i_toPipeline_0_be) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistIntfL2.toPipeline_0_be g=%h i=%h", cyc, mi_g_toPipeline_0_be, mi_i_toPipeline_0_be);
        end
        mi_s1_toPipeline_0_be |= mi_g_toPipeline_0_be;
        mi_s0_toPipeline_0_be |= ~mi_g_toPipeline_0_be;
        checks++;
        if (mi_g_toPipeline_0_addr !== mi_i_toPipeline_0_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistIntfL2.toPipeline_0_addr g=%h i=%h", cyc, mi_g_toPipeline_0_addr, mi_i_toPipeline_0_addr);
        end
        mi_s1_toPipeline_0_addr |= mi_g_toPipeline_0_addr;
        mi_s0_toPipeline_0_addr |= ~mi_g_toPipeline_0_addr;
        checks++;
        if (mi_g_toPipeline_0_indata !== mi_i_toPipeline_0_indata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistIntfL2.toPipeline_0_indata g=%h i=%h", cyc, mi_g_toPipeline_0_indata, mi_i_toPipeline_0_indata);
        end
        mi_s1_toPipeline_0_indata |= mi_g_toPipeline_0_indata;
        mi_s0_toPipeline_0_indata |= ~mi_g_toPipeline_0_indata;
        checks++;
        if (mi_g_toPipeline_0_readen !== mi_i_toPipeline_0_readen) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistIntfL2.toPipeline_0_readen g=%h i=%h", cyc, mi_g_toPipeline_0_readen, mi_i_toPipeline_0_readen);
        end
        mi_s1_toPipeline_0_readen |= mi_g_toPipeline_0_readen;
        mi_s0_toPipeline_0_readen |= ~mi_g_toPipeline_0_readen;
        checks++;
        if (mi_g_toPipeline_0_addr_rd !== mi_i_toPipeline_0_addr_rd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistIntfL2.toPipeline_0_addr_rd g=%h i=%h", cyc, mi_g_toPipeline_0_addr_rd, mi_i_toPipeline_0_addr_rd);
        end
        mi_s1_toPipeline_0_addr_rd |= mi_g_toPipeline_0_addr_rd;
        mi_s0_toPipeline_0_addr_rd |= ~mi_g_toPipeline_0_addr_rd;
        checks++;
        if (mi_g_mbist_ack !== mi_i_mbist_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistIntfL2.mbist_ack g=%h i=%h", cyc, mi_g_mbist_ack, mi_i_mbist_ack);
        end
        mi_s1_mbist_ack |= mi_g_mbist_ack;
        mi_s0_mbist_ack |= ~mi_g_mbist_ack;
        checks++;
        if (mi_g_mbist_outdata !== mi_i_mbist_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistIntfL2.mbist_outdata g=%h i=%h", cyc, mi_g_mbist_outdata, mi_i_mbist_outdata);
        end
        mi_s1_mbist_outdata |= mi_g_mbist_outdata;
        mi_s0_mbist_outdata |= ~mi_g_mbist_outdata;
        if (mi_mbist_req) mi_cov_req++;
        if (mi_g_mbist_ack) mi_cov_ack++;
      end
      if (mi_armed_at < 0 && (&mi_armed)) mi_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(mi_s0_toPipeline_0_array[0] && mi_s1_toPipeline_0_array[0])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_array[0] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_array[1] && mi_s1_toPipeline_0_array[1])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_array[1] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_array[2] && mi_s1_toPipeline_0_array[2])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_array[2] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_array[3] && mi_s1_toPipeline_0_array[3])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_array[3] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_array[4] && mi_s1_toPipeline_0_array[4])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_array[4] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_array[5] && mi_s1_toPipeline_0_array[5])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_array[5] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_all && mi_s1_toPipeline_0_all)) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_all 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_req && mi_s1_toPipeline_0_req)) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_req 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_writeen && mi_s1_toPipeline_0_writeen)) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_writeen 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_be[0] && mi_s1_toPipeline_0_be[0])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_be[0] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_be[1] && mi_s1_toPipeline_0_be[1])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_be[1] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_be[2] && mi_s1_toPipeline_0_be[2])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_be[2] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_be[3] && mi_s1_toPipeline_0_be[3])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_be[3] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_be[4] && mi_s1_toPipeline_0_be[4])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_be[4] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_be[5] && mi_s1_toPipeline_0_be[5])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_be[5] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_be[6] && mi_s1_toPipeline_0_be[6])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_be[6] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_be[7] && mi_s1_toPipeline_0_be[7])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_be[7] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[0] && mi_s1_toPipeline_0_addr[0])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[0] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[1] && mi_s1_toPipeline_0_addr[1])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[1] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[2] && mi_s1_toPipeline_0_addr[2])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[2] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[3] && mi_s1_toPipeline_0_addr[3])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[3] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[4] && mi_s1_toPipeline_0_addr[4])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[4] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[5] && mi_s1_toPipeline_0_addr[5])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[5] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[6] && mi_s1_toPipeline_0_addr[6])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[6] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[7] && mi_s1_toPipeline_0_addr[7])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[7] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[8] && mi_s1_toPipeline_0_addr[8])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[8] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[9] && mi_s1_toPipeline_0_addr[9])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[9] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[10] && mi_s1_toPipeline_0_addr[10])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[10] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[11] && mi_s1_toPipeline_0_addr[11])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[11] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr[12] && mi_s1_toPipeline_0_addr[12])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr[12] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[0] && mi_s1_toPipeline_0_indata[0])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[0] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[1] && mi_s1_toPipeline_0_indata[1])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[1] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[2] && mi_s1_toPipeline_0_indata[2])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[2] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[3] && mi_s1_toPipeline_0_indata[3])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[3] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[4] && mi_s1_toPipeline_0_indata[4])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[4] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[5] && mi_s1_toPipeline_0_indata[5])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[5] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[6] && mi_s1_toPipeline_0_indata[6])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[6] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[7] && mi_s1_toPipeline_0_indata[7])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[7] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[8] && mi_s1_toPipeline_0_indata[8])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[8] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[9] && mi_s1_toPipeline_0_indata[9])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[9] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[10] && mi_s1_toPipeline_0_indata[10])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[10] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[11] && mi_s1_toPipeline_0_indata[11])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[11] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[12] && mi_s1_toPipeline_0_indata[12])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[12] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[13] && mi_s1_toPipeline_0_indata[13])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[13] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[14] && mi_s1_toPipeline_0_indata[14])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[14] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[15] && mi_s1_toPipeline_0_indata[15])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[15] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[16] && mi_s1_toPipeline_0_indata[16])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[16] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[17] && mi_s1_toPipeline_0_indata[17])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[17] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[18] && mi_s1_toPipeline_0_indata[18])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[18] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[19] && mi_s1_toPipeline_0_indata[19])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[19] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[20] && mi_s1_toPipeline_0_indata[20])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[20] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[21] && mi_s1_toPipeline_0_indata[21])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[21] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[22] && mi_s1_toPipeline_0_indata[22])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[22] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[23] && mi_s1_toPipeline_0_indata[23])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[23] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[24] && mi_s1_toPipeline_0_indata[24])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[24] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[25] && mi_s1_toPipeline_0_indata[25])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[25] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[26] && mi_s1_toPipeline_0_indata[26])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[26] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[27] && mi_s1_toPipeline_0_indata[27])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[27] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[28] && mi_s1_toPipeline_0_indata[28])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[28] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[29] && mi_s1_toPipeline_0_indata[29])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[29] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[30] && mi_s1_toPipeline_0_indata[30])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[30] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[31] && mi_s1_toPipeline_0_indata[31])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[31] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[32] && mi_s1_toPipeline_0_indata[32])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[32] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[33] && mi_s1_toPipeline_0_indata[33])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[33] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[34] && mi_s1_toPipeline_0_indata[34])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[34] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[35] && mi_s1_toPipeline_0_indata[35])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[35] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[36] && mi_s1_toPipeline_0_indata[36])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[36] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[37] && mi_s1_toPipeline_0_indata[37])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[37] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[38] && mi_s1_toPipeline_0_indata[38])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[38] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[39] && mi_s1_toPipeline_0_indata[39])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[39] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[40] && mi_s1_toPipeline_0_indata[40])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[40] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[41] && mi_s1_toPipeline_0_indata[41])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[41] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[42] && mi_s1_toPipeline_0_indata[42])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[42] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[43] && mi_s1_toPipeline_0_indata[43])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[43] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[44] && mi_s1_toPipeline_0_indata[44])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[44] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[45] && mi_s1_toPipeline_0_indata[45])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[45] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[46] && mi_s1_toPipeline_0_indata[46])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[46] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[47] && mi_s1_toPipeline_0_indata[47])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[47] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[48] && mi_s1_toPipeline_0_indata[48])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[48] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[49] && mi_s1_toPipeline_0_indata[49])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[49] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[50] && mi_s1_toPipeline_0_indata[50])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[50] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[51] && mi_s1_toPipeline_0_indata[51])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[51] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[52] && mi_s1_toPipeline_0_indata[52])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[52] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[53] && mi_s1_toPipeline_0_indata[53])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[53] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[54] && mi_s1_toPipeline_0_indata[54])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[54] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[55] && mi_s1_toPipeline_0_indata[55])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[55] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[56] && mi_s1_toPipeline_0_indata[56])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[56] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[57] && mi_s1_toPipeline_0_indata[57])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[57] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[58] && mi_s1_toPipeline_0_indata[58])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[58] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[59] && mi_s1_toPipeline_0_indata[59])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[59] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[60] && mi_s1_toPipeline_0_indata[60])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[60] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[61] && mi_s1_toPipeline_0_indata[61])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[61] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[62] && mi_s1_toPipeline_0_indata[62])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[62] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[63] && mi_s1_toPipeline_0_indata[63])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[63] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[64] && mi_s1_toPipeline_0_indata[64])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[64] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[65] && mi_s1_toPipeline_0_indata[65])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[65] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[66] && mi_s1_toPipeline_0_indata[66])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[66] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[67] && mi_s1_toPipeline_0_indata[67])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[67] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[68] && mi_s1_toPipeline_0_indata[68])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[68] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[69] && mi_s1_toPipeline_0_indata[69])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[69] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[70] && mi_s1_toPipeline_0_indata[70])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[70] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[71] && mi_s1_toPipeline_0_indata[71])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[71] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[72] && mi_s1_toPipeline_0_indata[72])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[72] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[73] && mi_s1_toPipeline_0_indata[73])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[73] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[74] && mi_s1_toPipeline_0_indata[74])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[74] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[75] && mi_s1_toPipeline_0_indata[75])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[75] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[76] && mi_s1_toPipeline_0_indata[76])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[76] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[77] && mi_s1_toPipeline_0_indata[77])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[77] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[78] && mi_s1_toPipeline_0_indata[78])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[78] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[79] && mi_s1_toPipeline_0_indata[79])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[79] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[80] && mi_s1_toPipeline_0_indata[80])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[80] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[81] && mi_s1_toPipeline_0_indata[81])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[81] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[82] && mi_s1_toPipeline_0_indata[82])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[82] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[83] && mi_s1_toPipeline_0_indata[83])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[83] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[84] && mi_s1_toPipeline_0_indata[84])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[84] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[85] && mi_s1_toPipeline_0_indata[85])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[85] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[86] && mi_s1_toPipeline_0_indata[86])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[86] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[87] && mi_s1_toPipeline_0_indata[87])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[87] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[88] && mi_s1_toPipeline_0_indata[88])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[88] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[89] && mi_s1_toPipeline_0_indata[89])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[89] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[90] && mi_s1_toPipeline_0_indata[90])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[90] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[91] && mi_s1_toPipeline_0_indata[91])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[91] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[92] && mi_s1_toPipeline_0_indata[92])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[92] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[93] && mi_s1_toPipeline_0_indata[93])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[93] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[94] && mi_s1_toPipeline_0_indata[94])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[94] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[95] && mi_s1_toPipeline_0_indata[95])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[95] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[96] && mi_s1_toPipeline_0_indata[96])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[96] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[97] && mi_s1_toPipeline_0_indata[97])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[97] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[98] && mi_s1_toPipeline_0_indata[98])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[98] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[99] && mi_s1_toPipeline_0_indata[99])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[99] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[100] && mi_s1_toPipeline_0_indata[100])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[100] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[101] && mi_s1_toPipeline_0_indata[101])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[101] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[102] && mi_s1_toPipeline_0_indata[102])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[102] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[103] && mi_s1_toPipeline_0_indata[103])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[103] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[104] && mi_s1_toPipeline_0_indata[104])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[104] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[105] && mi_s1_toPipeline_0_indata[105])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[105] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[106] && mi_s1_toPipeline_0_indata[106])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[106] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[107] && mi_s1_toPipeline_0_indata[107])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[107] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[108] && mi_s1_toPipeline_0_indata[108])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[108] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[109] && mi_s1_toPipeline_0_indata[109])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[109] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[110] && mi_s1_toPipeline_0_indata[110])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[110] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[111] && mi_s1_toPipeline_0_indata[111])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[111] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[112] && mi_s1_toPipeline_0_indata[112])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[112] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[113] && mi_s1_toPipeline_0_indata[113])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[113] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[114] && mi_s1_toPipeline_0_indata[114])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[114] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[115] && mi_s1_toPipeline_0_indata[115])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[115] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[116] && mi_s1_toPipeline_0_indata[116])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[116] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[117] && mi_s1_toPipeline_0_indata[117])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[117] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[118] && mi_s1_toPipeline_0_indata[118])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[118] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[119] && mi_s1_toPipeline_0_indata[119])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[119] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[120] && mi_s1_toPipeline_0_indata[120])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[120] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[121] && mi_s1_toPipeline_0_indata[121])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[121] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[122] && mi_s1_toPipeline_0_indata[122])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[122] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[123] && mi_s1_toPipeline_0_indata[123])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[123] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[124] && mi_s1_toPipeline_0_indata[124])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[124] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[125] && mi_s1_toPipeline_0_indata[125])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[125] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[126] && mi_s1_toPipeline_0_indata[126])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[126] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[127] && mi_s1_toPipeline_0_indata[127])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[127] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[128] && mi_s1_toPipeline_0_indata[128])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[128] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[129] && mi_s1_toPipeline_0_indata[129])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[129] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[130] && mi_s1_toPipeline_0_indata[130])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[130] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[131] && mi_s1_toPipeline_0_indata[131])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[131] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[132] && mi_s1_toPipeline_0_indata[132])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[132] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[133] && mi_s1_toPipeline_0_indata[133])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[133] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[134] && mi_s1_toPipeline_0_indata[134])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[134] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[135] && mi_s1_toPipeline_0_indata[135])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[135] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_indata[136] && mi_s1_toPipeline_0_indata[136])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_indata[136] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_readen && mi_s1_toPipeline_0_readen)) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_readen 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[0] && mi_s1_toPipeline_0_addr_rd[0])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[0] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[1] && mi_s1_toPipeline_0_addr_rd[1])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[1] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[2] && mi_s1_toPipeline_0_addr_rd[2])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[2] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[3] && mi_s1_toPipeline_0_addr_rd[3])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[3] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[4] && mi_s1_toPipeline_0_addr_rd[4])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[4] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[5] && mi_s1_toPipeline_0_addr_rd[5])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[5] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[6] && mi_s1_toPipeline_0_addr_rd[6])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[6] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[7] && mi_s1_toPipeline_0_addr_rd[7])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[7] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[8] && mi_s1_toPipeline_0_addr_rd[8])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[8] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[9] && mi_s1_toPipeline_0_addr_rd[9])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[9] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[10] && mi_s1_toPipeline_0_addr_rd[10])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[10] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[11] && mi_s1_toPipeline_0_addr_rd[11])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[11] 未见过 0 和 1"); end
    if (!(mi_s0_toPipeline_0_addr_rd[12] && mi_s1_toPipeline_0_addr_rd[12])) begin cov_fail++; $display("[COV] MbistIntfL2.toPipeline_0_addr_rd[12] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_ack && mi_s1_mbist_ack)) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_ack 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[0] && mi_s1_mbist_outdata[0])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[0] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[1] && mi_s1_mbist_outdata[1])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[1] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[2] && mi_s1_mbist_outdata[2])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[2] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[3] && mi_s1_mbist_outdata[3])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[3] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[4] && mi_s1_mbist_outdata[4])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[4] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[5] && mi_s1_mbist_outdata[5])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[5] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[6] && mi_s1_mbist_outdata[6])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[6] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[7] && mi_s1_mbist_outdata[7])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[7] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[8] && mi_s1_mbist_outdata[8])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[8] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[9] && mi_s1_mbist_outdata[9])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[9] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[10] && mi_s1_mbist_outdata[10])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[10] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[11] && mi_s1_mbist_outdata[11])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[11] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[12] && mi_s1_mbist_outdata[12])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[12] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[13] && mi_s1_mbist_outdata[13])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[13] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[14] && mi_s1_mbist_outdata[14])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[14] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[15] && mi_s1_mbist_outdata[15])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[15] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[16] && mi_s1_mbist_outdata[16])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[16] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[17] && mi_s1_mbist_outdata[17])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[17] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[18] && mi_s1_mbist_outdata[18])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[18] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[19] && mi_s1_mbist_outdata[19])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[19] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[20] && mi_s1_mbist_outdata[20])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[20] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[21] && mi_s1_mbist_outdata[21])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[21] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[22] && mi_s1_mbist_outdata[22])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[22] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[23] && mi_s1_mbist_outdata[23])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[23] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[24] && mi_s1_mbist_outdata[24])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[24] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[25] && mi_s1_mbist_outdata[25])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[25] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[26] && mi_s1_mbist_outdata[26])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[26] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[27] && mi_s1_mbist_outdata[27])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[27] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[28] && mi_s1_mbist_outdata[28])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[28] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[29] && mi_s1_mbist_outdata[29])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[29] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[30] && mi_s1_mbist_outdata[30])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[30] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[31] && mi_s1_mbist_outdata[31])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[31] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[32] && mi_s1_mbist_outdata[32])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[32] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[33] && mi_s1_mbist_outdata[33])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[33] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[34] && mi_s1_mbist_outdata[34])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[34] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[35] && mi_s1_mbist_outdata[35])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[35] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[36] && mi_s1_mbist_outdata[36])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[36] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[37] && mi_s1_mbist_outdata[37])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[37] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[38] && mi_s1_mbist_outdata[38])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[38] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[39] && mi_s1_mbist_outdata[39])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[39] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[40] && mi_s1_mbist_outdata[40])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[40] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[41] && mi_s1_mbist_outdata[41])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[41] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[42] && mi_s1_mbist_outdata[42])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[42] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[43] && mi_s1_mbist_outdata[43])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[43] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[44] && mi_s1_mbist_outdata[44])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[44] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[45] && mi_s1_mbist_outdata[45])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[45] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[46] && mi_s1_mbist_outdata[46])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[46] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[47] && mi_s1_mbist_outdata[47])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[47] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[48] && mi_s1_mbist_outdata[48])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[48] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[49] && mi_s1_mbist_outdata[49])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[49] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[50] && mi_s1_mbist_outdata[50])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[50] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[51] && mi_s1_mbist_outdata[51])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[51] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[52] && mi_s1_mbist_outdata[52])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[52] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[53] && mi_s1_mbist_outdata[53])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[53] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[54] && mi_s1_mbist_outdata[54])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[54] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[55] && mi_s1_mbist_outdata[55])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[55] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[56] && mi_s1_mbist_outdata[56])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[56] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[57] && mi_s1_mbist_outdata[57])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[57] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[58] && mi_s1_mbist_outdata[58])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[58] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[59] && mi_s1_mbist_outdata[59])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[59] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[60] && mi_s1_mbist_outdata[60])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[60] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[61] && mi_s1_mbist_outdata[61])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[61] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[62] && mi_s1_mbist_outdata[62])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[62] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[63] && mi_s1_mbist_outdata[63])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[63] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[64] && mi_s1_mbist_outdata[64])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[64] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[65] && mi_s1_mbist_outdata[65])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[65] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[66] && mi_s1_mbist_outdata[66])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[66] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[67] && mi_s1_mbist_outdata[67])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[67] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[68] && mi_s1_mbist_outdata[68])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[68] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[69] && mi_s1_mbist_outdata[69])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[69] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[70] && mi_s1_mbist_outdata[70])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[70] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[71] && mi_s1_mbist_outdata[71])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[71] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[72] && mi_s1_mbist_outdata[72])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[72] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[73] && mi_s1_mbist_outdata[73])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[73] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[74] && mi_s1_mbist_outdata[74])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[74] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[75] && mi_s1_mbist_outdata[75])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[75] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[76] && mi_s1_mbist_outdata[76])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[76] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[77] && mi_s1_mbist_outdata[77])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[77] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[78] && mi_s1_mbist_outdata[78])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[78] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[79] && mi_s1_mbist_outdata[79])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[79] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[80] && mi_s1_mbist_outdata[80])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[80] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[81] && mi_s1_mbist_outdata[81])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[81] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[82] && mi_s1_mbist_outdata[82])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[82] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[83] && mi_s1_mbist_outdata[83])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[83] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[84] && mi_s1_mbist_outdata[84])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[84] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[85] && mi_s1_mbist_outdata[85])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[85] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[86] && mi_s1_mbist_outdata[86])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[86] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[87] && mi_s1_mbist_outdata[87])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[87] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[88] && mi_s1_mbist_outdata[88])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[88] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[89] && mi_s1_mbist_outdata[89])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[89] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[90] && mi_s1_mbist_outdata[90])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[90] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[91] && mi_s1_mbist_outdata[91])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[91] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[92] && mi_s1_mbist_outdata[92])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[92] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[93] && mi_s1_mbist_outdata[93])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[93] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[94] && mi_s1_mbist_outdata[94])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[94] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[95] && mi_s1_mbist_outdata[95])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[95] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[96] && mi_s1_mbist_outdata[96])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[96] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[97] && mi_s1_mbist_outdata[97])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[97] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[98] && mi_s1_mbist_outdata[98])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[98] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[99] && mi_s1_mbist_outdata[99])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[99] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[100] && mi_s1_mbist_outdata[100])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[100] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[101] && mi_s1_mbist_outdata[101])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[101] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[102] && mi_s1_mbist_outdata[102])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[102] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[103] && mi_s1_mbist_outdata[103])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[103] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[104] && mi_s1_mbist_outdata[104])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[104] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[105] && mi_s1_mbist_outdata[105])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[105] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[106] && mi_s1_mbist_outdata[106])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[106] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[107] && mi_s1_mbist_outdata[107])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[107] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[108] && mi_s1_mbist_outdata[108])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[108] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[109] && mi_s1_mbist_outdata[109])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[109] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[110] && mi_s1_mbist_outdata[110])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[110] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[111] && mi_s1_mbist_outdata[111])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[111] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[112] && mi_s1_mbist_outdata[112])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[112] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[113] && mi_s1_mbist_outdata[113])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[113] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[114] && mi_s1_mbist_outdata[114])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[114] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[115] && mi_s1_mbist_outdata[115])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[115] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[116] && mi_s1_mbist_outdata[116])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[116] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[117] && mi_s1_mbist_outdata[117])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[117] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[118] && mi_s1_mbist_outdata[118])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[118] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[119] && mi_s1_mbist_outdata[119])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[119] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[120] && mi_s1_mbist_outdata[120])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[120] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[121] && mi_s1_mbist_outdata[121])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[121] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[122] && mi_s1_mbist_outdata[122])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[122] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[123] && mi_s1_mbist_outdata[123])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[123] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[124] && mi_s1_mbist_outdata[124])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[124] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[125] && mi_s1_mbist_outdata[125])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[125] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[126] && mi_s1_mbist_outdata[126])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[126] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[127] && mi_s1_mbist_outdata[127])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[127] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[128] && mi_s1_mbist_outdata[128])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[128] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[129] && mi_s1_mbist_outdata[129])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[129] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[130] && mi_s1_mbist_outdata[130])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[130] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[131] && mi_s1_mbist_outdata[131])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[131] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[132] && mi_s1_mbist_outdata[132])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[132] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[133] && mi_s1_mbist_outdata[133])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[133] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[134] && mi_s1_mbist_outdata[134])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[134] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[135] && mi_s1_mbist_outdata[135])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[135] 未见过 0 和 1"); end
    if (!(mi_s0_mbist_outdata[136] && mi_s1_mbist_outdata[136])) begin cov_fail++; $display("[COV] MbistIntfL2.mbist_outdata[136] 未见过 0 和 1"); end
    $display("[ARM] MbistIntfL2 armed_at=%0d", mi_armed_at);
    if (mi_armed_at < 0) begin cov_fail++; $display("[ARM] MbistIntfL2 从未 arm"); end
    $display("[COV] MbistIntfL2.req = %0d", mi_cov_req);
    if (mi_cov_req < 100) begin cov_fail++; $display("[COV] MbistIntfL2.req < 100"); end
    $display("[COV] MbistIntfL2.ack = %0d", mi_cov_ack);
    if (mi_cov_ack < 100) begin cov_fail++; $display("[COV] MbistIntfL2.ack < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
