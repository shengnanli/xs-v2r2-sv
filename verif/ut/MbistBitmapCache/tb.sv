// 自动生成：verif/ut/MbistBitmapCache/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// MbistBitmapCache 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= MbistBitmapCache =================
  int unsigned m_mode = 0;
  logic m_reset;
  logic [5:0] m_mbist_array;
  logic m_mbist_all;
  logic m_mbist_req;
  wire  m_g_mbist_ack, m_i_mbist_ack;
  logic m_s0_mbist_ack = '0, m_s1_mbist_ack = '0;
  logic m_mbist_writeen;
  logic [1:0] m_mbist_be;
  logic [5:0] m_mbist_addr;
  logic [89:0] m_mbist_indata;
  logic m_mbist_readen;
  logic [5:0] m_mbist_addr_rd;
  wire  [89:0] m_g_mbist_outdata, m_i_mbist_outdata;
  logic [89:0] m_s0_mbist_outdata = '0, m_s1_mbist_outdata = '0;
  wire  [5:0] m_g_toSRAM_0_addr, m_i_toSRAM_0_addr;
  logic [5:0] m_s0_toSRAM_0_addr = '0, m_s1_toSRAM_0_addr = '0;
  wire  [5:0] m_g_toSRAM_0_addr_rd, m_i_toSRAM_0_addr_rd;
  logic [5:0] m_s0_toSRAM_0_addr_rd = '0, m_s1_toSRAM_0_addr_rd = '0;
  wire  [89:0] m_g_toSRAM_0_wdata, m_i_toSRAM_0_wdata;
  logic [89:0] m_s0_toSRAM_0_wdata = '0, m_s1_toSRAM_0_wdata = '0;
  wire  [1:0] m_g_toSRAM_0_wmask, m_i_toSRAM_0_wmask;
  logic [1:0] m_s0_toSRAM_0_wmask = '0, m_s1_toSRAM_0_wmask = '0;
  wire  m_g_toSRAM_0_re, m_i_toSRAM_0_re;
  logic m_s0_toSRAM_0_re = '0, m_s1_toSRAM_0_re = '0;
  wire  m_g_toSRAM_0_we, m_i_toSRAM_0_we;
  logic m_s0_toSRAM_0_we = '0, m_s1_toSRAM_0_we = '0;
  logic [89:0] m_toSRAM_0_rdata;
  wire  m_g_toSRAM_0_ack, m_i_toSRAM_0_ack;
  logic m_s0_toSRAM_0_ack = '0, m_s1_toSRAM_0_ack = '0;
  wire  m_g_toSRAM_0_selectedOH, m_i_toSRAM_0_selectedOH;
  logic m_s0_toSRAM_0_selectedOH = '0, m_s1_toSRAM_0_selectedOH = '0;
  wire  [5:0] m_g_toSRAM_0_array, m_i_toSRAM_0_array;
  logic [5:0] m_s0_toSRAM_0_array = '0, m_s1_toSRAM_0_array = '0;
  wire  [5:0] m_g_toSRAM_1_addr, m_i_toSRAM_1_addr;
  logic [5:0] m_s0_toSRAM_1_addr = '0, m_s1_toSRAM_1_addr = '0;
  wire  [5:0] m_g_toSRAM_1_addr_rd, m_i_toSRAM_1_addr_rd;
  logic [5:0] m_s0_toSRAM_1_addr_rd = '0, m_s1_toSRAM_1_addr_rd = '0;
  wire  [89:0] m_g_toSRAM_1_wdata, m_i_toSRAM_1_wdata;
  logic [89:0] m_s0_toSRAM_1_wdata = '0, m_s1_toSRAM_1_wdata = '0;
  wire  [1:0] m_g_toSRAM_1_wmask, m_i_toSRAM_1_wmask;
  logic [1:0] m_s0_toSRAM_1_wmask = '0, m_s1_toSRAM_1_wmask = '0;
  wire  m_g_toSRAM_1_re, m_i_toSRAM_1_re;
  logic m_s0_toSRAM_1_re = '0, m_s1_toSRAM_1_re = '0;
  wire  m_g_toSRAM_1_we, m_i_toSRAM_1_we;
  logic m_s0_toSRAM_1_we = '0, m_s1_toSRAM_1_we = '0;
  logic [89:0] m_toSRAM_1_rdata;
  wire  m_g_toSRAM_1_ack, m_i_toSRAM_1_ack;
  logic m_s0_toSRAM_1_ack = '0, m_s1_toSRAM_1_ack = '0;
  wire  m_g_toSRAM_1_selectedOH, m_i_toSRAM_1_selectedOH;
  logic m_s0_toSRAM_1_selectedOH = '0, m_s1_toSRAM_1_selectedOH = '0;
  wire  [5:0] m_g_toSRAM_1_array, m_i_toSRAM_1_array;
  logic [5:0] m_s0_toSRAM_1_array = '0, m_s1_toSRAM_1_array = '0;
  wire  [5:0] m_g_toSRAM_2_addr, m_i_toSRAM_2_addr;
  logic [5:0] m_s0_toSRAM_2_addr = '0, m_s1_toSRAM_2_addr = '0;
  wire  [5:0] m_g_toSRAM_2_addr_rd, m_i_toSRAM_2_addr_rd;
  logic [5:0] m_s0_toSRAM_2_addr_rd = '0, m_s1_toSRAM_2_addr_rd = '0;
  wire  [89:0] m_g_toSRAM_2_wdata, m_i_toSRAM_2_wdata;
  logic [89:0] m_s0_toSRAM_2_wdata = '0, m_s1_toSRAM_2_wdata = '0;
  wire  [1:0] m_g_toSRAM_2_wmask, m_i_toSRAM_2_wmask;
  logic [1:0] m_s0_toSRAM_2_wmask = '0, m_s1_toSRAM_2_wmask = '0;
  wire  m_g_toSRAM_2_re, m_i_toSRAM_2_re;
  logic m_s0_toSRAM_2_re = '0, m_s1_toSRAM_2_re = '0;
  wire  m_g_toSRAM_2_we, m_i_toSRAM_2_we;
  logic m_s0_toSRAM_2_we = '0, m_s1_toSRAM_2_we = '0;
  logic [89:0] m_toSRAM_2_rdata;
  wire  m_g_toSRAM_2_ack, m_i_toSRAM_2_ack;
  logic m_s0_toSRAM_2_ack = '0, m_s1_toSRAM_2_ack = '0;
  wire  m_g_toSRAM_2_selectedOH, m_i_toSRAM_2_selectedOH;
  logic m_s0_toSRAM_2_selectedOH = '0, m_s1_toSRAM_2_selectedOH = '0;
  wire  [5:0] m_g_toSRAM_2_array, m_i_toSRAM_2_array;
  logic [5:0] m_s0_toSRAM_2_array = '0, m_s1_toSRAM_2_array = '0;
  wire  [5:0] m_g_toSRAM_3_addr, m_i_toSRAM_3_addr;
  logic [5:0] m_s0_toSRAM_3_addr = '0, m_s1_toSRAM_3_addr = '0;
  wire  [5:0] m_g_toSRAM_3_addr_rd, m_i_toSRAM_3_addr_rd;
  logic [5:0] m_s0_toSRAM_3_addr_rd = '0, m_s1_toSRAM_3_addr_rd = '0;
  wire  [89:0] m_g_toSRAM_3_wdata, m_i_toSRAM_3_wdata;
  logic [89:0] m_s0_toSRAM_3_wdata = '0, m_s1_toSRAM_3_wdata = '0;
  wire  [1:0] m_g_toSRAM_3_wmask, m_i_toSRAM_3_wmask;
  logic [1:0] m_s0_toSRAM_3_wmask = '0, m_s1_toSRAM_3_wmask = '0;
  wire  m_g_toSRAM_3_re, m_i_toSRAM_3_re;
  logic m_s0_toSRAM_3_re = '0, m_s1_toSRAM_3_re = '0;
  wire  m_g_toSRAM_3_we, m_i_toSRAM_3_we;
  logic m_s0_toSRAM_3_we = '0, m_s1_toSRAM_3_we = '0;
  logic [89:0] m_toSRAM_3_rdata;
  wire  m_g_toSRAM_3_ack, m_i_toSRAM_3_ack;
  logic m_s0_toSRAM_3_ack = '0, m_s1_toSRAM_3_ack = '0;
  wire  m_g_toSRAM_3_selectedOH, m_i_toSRAM_3_selectedOH;
  logic m_s0_toSRAM_3_selectedOH = '0, m_s1_toSRAM_3_selectedOH = '0;
  wire  [5:0] m_g_toSRAM_3_array, m_i_toSRAM_3_array;
  logic [5:0] m_s0_toSRAM_3_array = '0, m_s1_toSRAM_3_array = '0;
  int m_cov_all = 0;
  int m_cov_reset_mid = 0;
  int m_cov_sel0 = 0;
  int m_cov_sel1 = 0;
  int m_cov_sel2 = 0;
  int m_cov_sel3 = 0;
  int m_cov_miss = 0;
  logic [0:0] m_armed = '0;
  int m_armed_at = -1;
  MbistBitmapCache m_u_gold (
    .clock(clk),
    .reset(m_reset),
    .mbist_array(m_mbist_array),
    .mbist_all(m_mbist_all),
    .mbist_req(m_mbist_req),
    .mbist_ack(m_g_mbist_ack),
    .mbist_writeen(m_mbist_writeen),
    .mbist_be(m_mbist_be),
    .mbist_addr(m_mbist_addr),
    .mbist_indata(m_mbist_indata),
    .mbist_readen(m_mbist_readen),
    .mbist_addr_rd(m_mbist_addr_rd),
    .mbist_outdata(m_g_mbist_outdata),
    .toSRAM_0_addr(m_g_toSRAM_0_addr),
    .toSRAM_0_addr_rd(m_g_toSRAM_0_addr_rd),
    .toSRAM_0_wdata(m_g_toSRAM_0_wdata),
    .toSRAM_0_wmask(m_g_toSRAM_0_wmask),
    .toSRAM_0_re(m_g_toSRAM_0_re),
    .toSRAM_0_we(m_g_toSRAM_0_we),
    .toSRAM_0_rdata(m_toSRAM_0_rdata),
    .toSRAM_0_ack(m_g_toSRAM_0_ack),
    .toSRAM_0_selectedOH(m_g_toSRAM_0_selectedOH),
    .toSRAM_0_array(m_g_toSRAM_0_array),
    .toSRAM_1_addr(m_g_toSRAM_1_addr),
    .toSRAM_1_addr_rd(m_g_toSRAM_1_addr_rd),
    .toSRAM_1_wdata(m_g_toSRAM_1_wdata),
    .toSRAM_1_wmask(m_g_toSRAM_1_wmask),
    .toSRAM_1_re(m_g_toSRAM_1_re),
    .toSRAM_1_we(m_g_toSRAM_1_we),
    .toSRAM_1_rdata(m_toSRAM_1_rdata),
    .toSRAM_1_ack(m_g_toSRAM_1_ack),
    .toSRAM_1_selectedOH(m_g_toSRAM_1_selectedOH),
    .toSRAM_1_array(m_g_toSRAM_1_array),
    .toSRAM_2_addr(m_g_toSRAM_2_addr),
    .toSRAM_2_addr_rd(m_g_toSRAM_2_addr_rd),
    .toSRAM_2_wdata(m_g_toSRAM_2_wdata),
    .toSRAM_2_wmask(m_g_toSRAM_2_wmask),
    .toSRAM_2_re(m_g_toSRAM_2_re),
    .toSRAM_2_we(m_g_toSRAM_2_we),
    .toSRAM_2_rdata(m_toSRAM_2_rdata),
    .toSRAM_2_ack(m_g_toSRAM_2_ack),
    .toSRAM_2_selectedOH(m_g_toSRAM_2_selectedOH),
    .toSRAM_2_array(m_g_toSRAM_2_array),
    .toSRAM_3_addr(m_g_toSRAM_3_addr),
    .toSRAM_3_addr_rd(m_g_toSRAM_3_addr_rd),
    .toSRAM_3_wdata(m_g_toSRAM_3_wdata),
    .toSRAM_3_wmask(m_g_toSRAM_3_wmask),
    .toSRAM_3_re(m_g_toSRAM_3_re),
    .toSRAM_3_we(m_g_toSRAM_3_we),
    .toSRAM_3_rdata(m_toSRAM_3_rdata),
    .toSRAM_3_ack(m_g_toSRAM_3_ack),
    .toSRAM_3_selectedOH(m_g_toSRAM_3_selectedOH),
    .toSRAM_3_array(m_g_toSRAM_3_array)
  );
  MbistBitmapCache_xs m_u_impl (
    .clock(clk),
    .reset(m_reset),
    .mbist_array(m_mbist_array),
    .mbist_all(m_mbist_all),
    .mbist_req(m_mbist_req),
    .mbist_ack(m_i_mbist_ack),
    .mbist_writeen(m_mbist_writeen),
    .mbist_be(m_mbist_be),
    .mbist_addr(m_mbist_addr),
    .mbist_indata(m_mbist_indata),
    .mbist_readen(m_mbist_readen),
    .mbist_addr_rd(m_mbist_addr_rd),
    .mbist_outdata(m_i_mbist_outdata),
    .toSRAM_0_addr(m_i_toSRAM_0_addr),
    .toSRAM_0_addr_rd(m_i_toSRAM_0_addr_rd),
    .toSRAM_0_wdata(m_i_toSRAM_0_wdata),
    .toSRAM_0_wmask(m_i_toSRAM_0_wmask),
    .toSRAM_0_re(m_i_toSRAM_0_re),
    .toSRAM_0_we(m_i_toSRAM_0_we),
    .toSRAM_0_rdata(m_toSRAM_0_rdata),
    .toSRAM_0_ack(m_i_toSRAM_0_ack),
    .toSRAM_0_selectedOH(m_i_toSRAM_0_selectedOH),
    .toSRAM_0_array(m_i_toSRAM_0_array),
    .toSRAM_1_addr(m_i_toSRAM_1_addr),
    .toSRAM_1_addr_rd(m_i_toSRAM_1_addr_rd),
    .toSRAM_1_wdata(m_i_toSRAM_1_wdata),
    .toSRAM_1_wmask(m_i_toSRAM_1_wmask),
    .toSRAM_1_re(m_i_toSRAM_1_re),
    .toSRAM_1_we(m_i_toSRAM_1_we),
    .toSRAM_1_rdata(m_toSRAM_1_rdata),
    .toSRAM_1_ack(m_i_toSRAM_1_ack),
    .toSRAM_1_selectedOH(m_i_toSRAM_1_selectedOH),
    .toSRAM_1_array(m_i_toSRAM_1_array),
    .toSRAM_2_addr(m_i_toSRAM_2_addr),
    .toSRAM_2_addr_rd(m_i_toSRAM_2_addr_rd),
    .toSRAM_2_wdata(m_i_toSRAM_2_wdata),
    .toSRAM_2_wmask(m_i_toSRAM_2_wmask),
    .toSRAM_2_re(m_i_toSRAM_2_re),
    .toSRAM_2_we(m_i_toSRAM_2_we),
    .toSRAM_2_rdata(m_toSRAM_2_rdata),
    .toSRAM_2_ack(m_i_toSRAM_2_ack),
    .toSRAM_2_selectedOH(m_i_toSRAM_2_selectedOH),
    .toSRAM_2_array(m_i_toSRAM_2_array),
    .toSRAM_3_addr(m_i_toSRAM_3_addr),
    .toSRAM_3_addr_rd(m_i_toSRAM_3_addr_rd),
    .toSRAM_3_wdata(m_i_toSRAM_3_wdata),
    .toSRAM_3_wmask(m_i_toSRAM_3_wmask),
    .toSRAM_3_re(m_i_toSRAM_3_re),
    .toSRAM_3_we(m_i_toSRAM_3_we),
    .toSRAM_3_rdata(m_toSRAM_3_rdata),
    .toSRAM_3_ack(m_i_toSRAM_3_ack),
    .toSRAM_3_selectedOH(m_i_toSRAM_3_selectedOH),
    .toSRAM_3_array(m_i_toSRAM_3_array)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) m_mode = $urandom_range(0, 15);
      m_mbist_array = 6'($urandom);
      m_mbist_all = 1'($urandom);
      m_mbist_req = 1'($urandom);
      m_mbist_writeen = 1'($urandom);
      m_mbist_be = 2'($urandom);
      m_mbist_addr = 6'($urandom);
      m_mbist_indata = 90'({$urandom, $urandom, $urandom});
      m_mbist_readen = 1'($urandom);
      m_mbist_addr_rd = 6'($urandom);
      m_toSRAM_0_rdata = 90'({$urandom, $urandom, $urandom});
      m_toSRAM_1_rdata = 90'({$urandom, $urandom, $urandom});
      m_toSRAM_2_rdata = 90'({$urandom, $urandom, $urandom});
      m_toSRAM_3_rdata = 90'({$urandom, $urandom, $urandom});
      m_reset = (cyc < RESET_CYC) || ($urandom_range(0, 1999) == 0);
      begin : stim_m
        if ($urandom_range(0, 3) != 0) m_mbist_array = 6'h28 + 6'($urandom_range(0, 3));
        m_mbist_all = ($urandom_range(0, 7) == 0);
      end
      #4;
      m_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&m_armed)) begin
        checks++;
        if (m_g_mbist_ack !== m_i_mbist_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.mbist_ack g=%h i=%h", cyc, m_g_mbist_ack, m_i_mbist_ack);
        end
        m_s1_mbist_ack |= m_g_mbist_ack;
        m_s0_mbist_ack |= ~m_g_mbist_ack;
        checks++;
        if (m_g_mbist_outdata !== m_i_mbist_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.mbist_outdata g=%h i=%h", cyc, m_g_mbist_outdata, m_i_mbist_outdata);
        end
        m_s1_mbist_outdata |= m_g_mbist_outdata;
        m_s0_mbist_outdata |= ~m_g_mbist_outdata;
        checks++;
        if (m_g_toSRAM_0_addr !== m_i_toSRAM_0_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_0_addr g=%h i=%h", cyc, m_g_toSRAM_0_addr, m_i_toSRAM_0_addr);
        end
        m_s1_toSRAM_0_addr |= m_g_toSRAM_0_addr;
        m_s0_toSRAM_0_addr |= ~m_g_toSRAM_0_addr;
        checks++;
        if (m_g_toSRAM_0_addr_rd !== m_i_toSRAM_0_addr_rd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_0_addr_rd g=%h i=%h", cyc, m_g_toSRAM_0_addr_rd, m_i_toSRAM_0_addr_rd);
        end
        m_s1_toSRAM_0_addr_rd |= m_g_toSRAM_0_addr_rd;
        m_s0_toSRAM_0_addr_rd |= ~m_g_toSRAM_0_addr_rd;
        checks++;
        if (m_g_toSRAM_0_wdata !== m_i_toSRAM_0_wdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_0_wdata g=%h i=%h", cyc, m_g_toSRAM_0_wdata, m_i_toSRAM_0_wdata);
        end
        m_s1_toSRAM_0_wdata |= m_g_toSRAM_0_wdata;
        m_s0_toSRAM_0_wdata |= ~m_g_toSRAM_0_wdata;
        checks++;
        if (m_g_toSRAM_0_wmask !== m_i_toSRAM_0_wmask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_0_wmask g=%h i=%h", cyc, m_g_toSRAM_0_wmask, m_i_toSRAM_0_wmask);
        end
        m_s1_toSRAM_0_wmask |= m_g_toSRAM_0_wmask;
        m_s0_toSRAM_0_wmask |= ~m_g_toSRAM_0_wmask;
        checks++;
        if (m_g_toSRAM_0_re !== m_i_toSRAM_0_re) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_0_re g=%h i=%h", cyc, m_g_toSRAM_0_re, m_i_toSRAM_0_re);
        end
        m_s1_toSRAM_0_re |= m_g_toSRAM_0_re;
        m_s0_toSRAM_0_re |= ~m_g_toSRAM_0_re;
        checks++;
        if (m_g_toSRAM_0_we !== m_i_toSRAM_0_we) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_0_we g=%h i=%h", cyc, m_g_toSRAM_0_we, m_i_toSRAM_0_we);
        end
        m_s1_toSRAM_0_we |= m_g_toSRAM_0_we;
        m_s0_toSRAM_0_we |= ~m_g_toSRAM_0_we;
        checks++;
        if (m_g_toSRAM_0_ack !== m_i_toSRAM_0_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_0_ack g=%h i=%h", cyc, m_g_toSRAM_0_ack, m_i_toSRAM_0_ack);
        end
        m_s1_toSRAM_0_ack |= m_g_toSRAM_0_ack;
        m_s0_toSRAM_0_ack |= ~m_g_toSRAM_0_ack;
        checks++;
        if (m_g_toSRAM_0_selectedOH !== m_i_toSRAM_0_selectedOH) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_0_selectedOH g=%h i=%h", cyc, m_g_toSRAM_0_selectedOH, m_i_toSRAM_0_selectedOH);
        end
        m_s1_toSRAM_0_selectedOH |= m_g_toSRAM_0_selectedOH;
        m_s0_toSRAM_0_selectedOH |= ~m_g_toSRAM_0_selectedOH;
        checks++;
        if (m_g_toSRAM_0_array !== m_i_toSRAM_0_array) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_0_array g=%h i=%h", cyc, m_g_toSRAM_0_array, m_i_toSRAM_0_array);
        end
        m_s1_toSRAM_0_array |= m_g_toSRAM_0_array;
        m_s0_toSRAM_0_array |= ~m_g_toSRAM_0_array;
        checks++;
        if (m_g_toSRAM_1_addr !== m_i_toSRAM_1_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_1_addr g=%h i=%h", cyc, m_g_toSRAM_1_addr, m_i_toSRAM_1_addr);
        end
        m_s1_toSRAM_1_addr |= m_g_toSRAM_1_addr;
        m_s0_toSRAM_1_addr |= ~m_g_toSRAM_1_addr;
        checks++;
        if (m_g_toSRAM_1_addr_rd !== m_i_toSRAM_1_addr_rd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_1_addr_rd g=%h i=%h", cyc, m_g_toSRAM_1_addr_rd, m_i_toSRAM_1_addr_rd);
        end
        m_s1_toSRAM_1_addr_rd |= m_g_toSRAM_1_addr_rd;
        m_s0_toSRAM_1_addr_rd |= ~m_g_toSRAM_1_addr_rd;
        checks++;
        if (m_g_toSRAM_1_wdata !== m_i_toSRAM_1_wdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_1_wdata g=%h i=%h", cyc, m_g_toSRAM_1_wdata, m_i_toSRAM_1_wdata);
        end
        m_s1_toSRAM_1_wdata |= m_g_toSRAM_1_wdata;
        m_s0_toSRAM_1_wdata |= ~m_g_toSRAM_1_wdata;
        checks++;
        if (m_g_toSRAM_1_wmask !== m_i_toSRAM_1_wmask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_1_wmask g=%h i=%h", cyc, m_g_toSRAM_1_wmask, m_i_toSRAM_1_wmask);
        end
        m_s1_toSRAM_1_wmask |= m_g_toSRAM_1_wmask;
        m_s0_toSRAM_1_wmask |= ~m_g_toSRAM_1_wmask;
        checks++;
        if (m_g_toSRAM_1_re !== m_i_toSRAM_1_re) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_1_re g=%h i=%h", cyc, m_g_toSRAM_1_re, m_i_toSRAM_1_re);
        end
        m_s1_toSRAM_1_re |= m_g_toSRAM_1_re;
        m_s0_toSRAM_1_re |= ~m_g_toSRAM_1_re;
        checks++;
        if (m_g_toSRAM_1_we !== m_i_toSRAM_1_we) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_1_we g=%h i=%h", cyc, m_g_toSRAM_1_we, m_i_toSRAM_1_we);
        end
        m_s1_toSRAM_1_we |= m_g_toSRAM_1_we;
        m_s0_toSRAM_1_we |= ~m_g_toSRAM_1_we;
        checks++;
        if (m_g_toSRAM_1_ack !== m_i_toSRAM_1_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_1_ack g=%h i=%h", cyc, m_g_toSRAM_1_ack, m_i_toSRAM_1_ack);
        end
        m_s1_toSRAM_1_ack |= m_g_toSRAM_1_ack;
        m_s0_toSRAM_1_ack |= ~m_g_toSRAM_1_ack;
        checks++;
        if (m_g_toSRAM_1_selectedOH !== m_i_toSRAM_1_selectedOH) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_1_selectedOH g=%h i=%h", cyc, m_g_toSRAM_1_selectedOH, m_i_toSRAM_1_selectedOH);
        end
        m_s1_toSRAM_1_selectedOH |= m_g_toSRAM_1_selectedOH;
        m_s0_toSRAM_1_selectedOH |= ~m_g_toSRAM_1_selectedOH;
        checks++;
        if (m_g_toSRAM_1_array !== m_i_toSRAM_1_array) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_1_array g=%h i=%h", cyc, m_g_toSRAM_1_array, m_i_toSRAM_1_array);
        end
        m_s1_toSRAM_1_array |= m_g_toSRAM_1_array;
        m_s0_toSRAM_1_array |= ~m_g_toSRAM_1_array;
        checks++;
        if (m_g_toSRAM_2_addr !== m_i_toSRAM_2_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_2_addr g=%h i=%h", cyc, m_g_toSRAM_2_addr, m_i_toSRAM_2_addr);
        end
        m_s1_toSRAM_2_addr |= m_g_toSRAM_2_addr;
        m_s0_toSRAM_2_addr |= ~m_g_toSRAM_2_addr;
        checks++;
        if (m_g_toSRAM_2_addr_rd !== m_i_toSRAM_2_addr_rd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_2_addr_rd g=%h i=%h", cyc, m_g_toSRAM_2_addr_rd, m_i_toSRAM_2_addr_rd);
        end
        m_s1_toSRAM_2_addr_rd |= m_g_toSRAM_2_addr_rd;
        m_s0_toSRAM_2_addr_rd |= ~m_g_toSRAM_2_addr_rd;
        checks++;
        if (m_g_toSRAM_2_wdata !== m_i_toSRAM_2_wdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_2_wdata g=%h i=%h", cyc, m_g_toSRAM_2_wdata, m_i_toSRAM_2_wdata);
        end
        m_s1_toSRAM_2_wdata |= m_g_toSRAM_2_wdata;
        m_s0_toSRAM_2_wdata |= ~m_g_toSRAM_2_wdata;
        checks++;
        if (m_g_toSRAM_2_wmask !== m_i_toSRAM_2_wmask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_2_wmask g=%h i=%h", cyc, m_g_toSRAM_2_wmask, m_i_toSRAM_2_wmask);
        end
        m_s1_toSRAM_2_wmask |= m_g_toSRAM_2_wmask;
        m_s0_toSRAM_2_wmask |= ~m_g_toSRAM_2_wmask;
        checks++;
        if (m_g_toSRAM_2_re !== m_i_toSRAM_2_re) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_2_re g=%h i=%h", cyc, m_g_toSRAM_2_re, m_i_toSRAM_2_re);
        end
        m_s1_toSRAM_2_re |= m_g_toSRAM_2_re;
        m_s0_toSRAM_2_re |= ~m_g_toSRAM_2_re;
        checks++;
        if (m_g_toSRAM_2_we !== m_i_toSRAM_2_we) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_2_we g=%h i=%h", cyc, m_g_toSRAM_2_we, m_i_toSRAM_2_we);
        end
        m_s1_toSRAM_2_we |= m_g_toSRAM_2_we;
        m_s0_toSRAM_2_we |= ~m_g_toSRAM_2_we;
        checks++;
        if (m_g_toSRAM_2_ack !== m_i_toSRAM_2_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_2_ack g=%h i=%h", cyc, m_g_toSRAM_2_ack, m_i_toSRAM_2_ack);
        end
        m_s1_toSRAM_2_ack |= m_g_toSRAM_2_ack;
        m_s0_toSRAM_2_ack |= ~m_g_toSRAM_2_ack;
        checks++;
        if (m_g_toSRAM_2_selectedOH !== m_i_toSRAM_2_selectedOH) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_2_selectedOH g=%h i=%h", cyc, m_g_toSRAM_2_selectedOH, m_i_toSRAM_2_selectedOH);
        end
        m_s1_toSRAM_2_selectedOH |= m_g_toSRAM_2_selectedOH;
        m_s0_toSRAM_2_selectedOH |= ~m_g_toSRAM_2_selectedOH;
        checks++;
        if (m_g_toSRAM_2_array !== m_i_toSRAM_2_array) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_2_array g=%h i=%h", cyc, m_g_toSRAM_2_array, m_i_toSRAM_2_array);
        end
        m_s1_toSRAM_2_array |= m_g_toSRAM_2_array;
        m_s0_toSRAM_2_array |= ~m_g_toSRAM_2_array;
        checks++;
        if (m_g_toSRAM_3_addr !== m_i_toSRAM_3_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_3_addr g=%h i=%h", cyc, m_g_toSRAM_3_addr, m_i_toSRAM_3_addr);
        end
        m_s1_toSRAM_3_addr |= m_g_toSRAM_3_addr;
        m_s0_toSRAM_3_addr |= ~m_g_toSRAM_3_addr;
        checks++;
        if (m_g_toSRAM_3_addr_rd !== m_i_toSRAM_3_addr_rd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_3_addr_rd g=%h i=%h", cyc, m_g_toSRAM_3_addr_rd, m_i_toSRAM_3_addr_rd);
        end
        m_s1_toSRAM_3_addr_rd |= m_g_toSRAM_3_addr_rd;
        m_s0_toSRAM_3_addr_rd |= ~m_g_toSRAM_3_addr_rd;
        checks++;
        if (m_g_toSRAM_3_wdata !== m_i_toSRAM_3_wdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_3_wdata g=%h i=%h", cyc, m_g_toSRAM_3_wdata, m_i_toSRAM_3_wdata);
        end
        m_s1_toSRAM_3_wdata |= m_g_toSRAM_3_wdata;
        m_s0_toSRAM_3_wdata |= ~m_g_toSRAM_3_wdata;
        checks++;
        if (m_g_toSRAM_3_wmask !== m_i_toSRAM_3_wmask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_3_wmask g=%h i=%h", cyc, m_g_toSRAM_3_wmask, m_i_toSRAM_3_wmask);
        end
        m_s1_toSRAM_3_wmask |= m_g_toSRAM_3_wmask;
        m_s0_toSRAM_3_wmask |= ~m_g_toSRAM_3_wmask;
        checks++;
        if (m_g_toSRAM_3_re !== m_i_toSRAM_3_re) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_3_re g=%h i=%h", cyc, m_g_toSRAM_3_re, m_i_toSRAM_3_re);
        end
        m_s1_toSRAM_3_re |= m_g_toSRAM_3_re;
        m_s0_toSRAM_3_re |= ~m_g_toSRAM_3_re;
        checks++;
        if (m_g_toSRAM_3_we !== m_i_toSRAM_3_we) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_3_we g=%h i=%h", cyc, m_g_toSRAM_3_we, m_i_toSRAM_3_we);
        end
        m_s1_toSRAM_3_we |= m_g_toSRAM_3_we;
        m_s0_toSRAM_3_we |= ~m_g_toSRAM_3_we;
        checks++;
        if (m_g_toSRAM_3_ack !== m_i_toSRAM_3_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_3_ack g=%h i=%h", cyc, m_g_toSRAM_3_ack, m_i_toSRAM_3_ack);
        end
        m_s1_toSRAM_3_ack |= m_g_toSRAM_3_ack;
        m_s0_toSRAM_3_ack |= ~m_g_toSRAM_3_ack;
        checks++;
        if (m_g_toSRAM_3_selectedOH !== m_i_toSRAM_3_selectedOH) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_3_selectedOH g=%h i=%h", cyc, m_g_toSRAM_3_selectedOH, m_i_toSRAM_3_selectedOH);
        end
        m_s1_toSRAM_3_selectedOH |= m_g_toSRAM_3_selectedOH;
        m_s0_toSRAM_3_selectedOH |= ~m_g_toSRAM_3_selectedOH;
        checks++;
        if (m_g_toSRAM_3_array !== m_i_toSRAM_3_array) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MbistBitmapCache.toSRAM_3_array g=%h i=%h", cyc, m_g_toSRAM_3_array, m_i_toSRAM_3_array);
        end
        m_s1_toSRAM_3_array |= m_g_toSRAM_3_array;
        m_s0_toSRAM_3_array |= ~m_g_toSRAM_3_array;
        if (m_mbist_all && m_mbist_req) m_cov_all++;
        if (m_reset && cyc > 100) m_cov_reset_mid++;
        if (m_mbist_req && !m_mbist_all && m_mbist_array == 6'h28 && m_mbist_writeen) m_cov_sel0++;
        if (m_mbist_req && !m_mbist_all && m_mbist_array == 6'h29 && m_mbist_writeen) m_cov_sel1++;
        if (m_mbist_req && !m_mbist_all && m_mbist_array == 6'h2A && m_mbist_writeen) m_cov_sel2++;
        if (m_mbist_req && !m_mbist_all && m_mbist_array == 6'h2B && m_mbist_writeen) m_cov_sel3++;
        if (m_mbist_req && !m_mbist_all && (m_mbist_array < 6'h28 || m_mbist_array > 6'h2B)) m_cov_miss++;
      end
      if (m_armed_at < 0 && (&m_armed)) m_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(m_s0_mbist_ack && m_s1_mbist_ack)) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_ack 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[0] && m_s1_mbist_outdata[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[0] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[1] && m_s1_mbist_outdata[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[1] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[2] && m_s1_mbist_outdata[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[2] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[3] && m_s1_mbist_outdata[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[3] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[4] && m_s1_mbist_outdata[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[4] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[5] && m_s1_mbist_outdata[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[5] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[6] && m_s1_mbist_outdata[6])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[6] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[7] && m_s1_mbist_outdata[7])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[7] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[8] && m_s1_mbist_outdata[8])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[8] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[9] && m_s1_mbist_outdata[9])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[9] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[10] && m_s1_mbist_outdata[10])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[10] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[11] && m_s1_mbist_outdata[11])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[11] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[12] && m_s1_mbist_outdata[12])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[12] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[13] && m_s1_mbist_outdata[13])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[13] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[14] && m_s1_mbist_outdata[14])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[14] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[15] && m_s1_mbist_outdata[15])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[15] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[16] && m_s1_mbist_outdata[16])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[16] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[17] && m_s1_mbist_outdata[17])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[17] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[18] && m_s1_mbist_outdata[18])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[18] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[19] && m_s1_mbist_outdata[19])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[19] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[20] && m_s1_mbist_outdata[20])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[20] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[21] && m_s1_mbist_outdata[21])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[21] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[22] && m_s1_mbist_outdata[22])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[22] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[23] && m_s1_mbist_outdata[23])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[23] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[24] && m_s1_mbist_outdata[24])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[24] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[25] && m_s1_mbist_outdata[25])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[25] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[26] && m_s1_mbist_outdata[26])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[26] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[27] && m_s1_mbist_outdata[27])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[27] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[28] && m_s1_mbist_outdata[28])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[28] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[29] && m_s1_mbist_outdata[29])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[29] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[30] && m_s1_mbist_outdata[30])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[30] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[31] && m_s1_mbist_outdata[31])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[31] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[32] && m_s1_mbist_outdata[32])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[32] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[33] && m_s1_mbist_outdata[33])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[33] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[34] && m_s1_mbist_outdata[34])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[34] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[35] && m_s1_mbist_outdata[35])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[35] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[36] && m_s1_mbist_outdata[36])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[36] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[37] && m_s1_mbist_outdata[37])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[37] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[38] && m_s1_mbist_outdata[38])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[38] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[39] && m_s1_mbist_outdata[39])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[39] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[40] && m_s1_mbist_outdata[40])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[40] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[41] && m_s1_mbist_outdata[41])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[41] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[42] && m_s1_mbist_outdata[42])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[42] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[43] && m_s1_mbist_outdata[43])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[43] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[44] && m_s1_mbist_outdata[44])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[44] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[45] && m_s1_mbist_outdata[45])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[45] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[46] && m_s1_mbist_outdata[46])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[46] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[47] && m_s1_mbist_outdata[47])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[47] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[48] && m_s1_mbist_outdata[48])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[48] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[49] && m_s1_mbist_outdata[49])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[49] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[50] && m_s1_mbist_outdata[50])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[50] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[51] && m_s1_mbist_outdata[51])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[51] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[52] && m_s1_mbist_outdata[52])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[52] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[53] && m_s1_mbist_outdata[53])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[53] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[54] && m_s1_mbist_outdata[54])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[54] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[55] && m_s1_mbist_outdata[55])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[55] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[56] && m_s1_mbist_outdata[56])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[56] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[57] && m_s1_mbist_outdata[57])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[57] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[58] && m_s1_mbist_outdata[58])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[58] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[59] && m_s1_mbist_outdata[59])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[59] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[60] && m_s1_mbist_outdata[60])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[60] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[61] && m_s1_mbist_outdata[61])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[61] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[62] && m_s1_mbist_outdata[62])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[62] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[63] && m_s1_mbist_outdata[63])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[63] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[64] && m_s1_mbist_outdata[64])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[64] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[65] && m_s1_mbist_outdata[65])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[65] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[66] && m_s1_mbist_outdata[66])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[66] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[67] && m_s1_mbist_outdata[67])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[67] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[68] && m_s1_mbist_outdata[68])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[68] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[69] && m_s1_mbist_outdata[69])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[69] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[70] && m_s1_mbist_outdata[70])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[70] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[71] && m_s1_mbist_outdata[71])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[71] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[72] && m_s1_mbist_outdata[72])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[72] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[73] && m_s1_mbist_outdata[73])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[73] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[74] && m_s1_mbist_outdata[74])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[74] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[75] && m_s1_mbist_outdata[75])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[75] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[76] && m_s1_mbist_outdata[76])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[76] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[77] && m_s1_mbist_outdata[77])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[77] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[78] && m_s1_mbist_outdata[78])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[78] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[79] && m_s1_mbist_outdata[79])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[79] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[80] && m_s1_mbist_outdata[80])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[80] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[81] && m_s1_mbist_outdata[81])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[81] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[82] && m_s1_mbist_outdata[82])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[82] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[83] && m_s1_mbist_outdata[83])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[83] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[84] && m_s1_mbist_outdata[84])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[84] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[85] && m_s1_mbist_outdata[85])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[85] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[86] && m_s1_mbist_outdata[86])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[86] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[87] && m_s1_mbist_outdata[87])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[87] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[88] && m_s1_mbist_outdata[88])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[88] 未见过 0 和 1"); end
    if (!(m_s0_mbist_outdata[89] && m_s1_mbist_outdata[89])) begin cov_fail++; $display("[COV] MbistBitmapCache.mbist_outdata[89] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_addr[0] && m_s1_toSRAM_0_addr[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_addr[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_addr[1] && m_s1_toSRAM_0_addr[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_addr[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_addr[2] && m_s1_toSRAM_0_addr[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_addr[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_addr[3] && m_s1_toSRAM_0_addr[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_addr[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_addr[4] && m_s1_toSRAM_0_addr[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_addr[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_addr[5] && m_s1_toSRAM_0_addr[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_addr[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_addr_rd[0] && m_s1_toSRAM_0_addr_rd[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_addr_rd[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_addr_rd[1] && m_s1_toSRAM_0_addr_rd[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_addr_rd[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_addr_rd[2] && m_s1_toSRAM_0_addr_rd[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_addr_rd[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_addr_rd[3] && m_s1_toSRAM_0_addr_rd[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_addr_rd[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_addr_rd[4] && m_s1_toSRAM_0_addr_rd[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_addr_rd[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_addr_rd[5] && m_s1_toSRAM_0_addr_rd[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_addr_rd[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[0] && m_s1_toSRAM_0_wdata[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[1] && m_s1_toSRAM_0_wdata[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[2] && m_s1_toSRAM_0_wdata[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[3] && m_s1_toSRAM_0_wdata[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[4] && m_s1_toSRAM_0_wdata[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[5] && m_s1_toSRAM_0_wdata[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[6] && m_s1_toSRAM_0_wdata[6])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[6] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[7] && m_s1_toSRAM_0_wdata[7])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[7] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[8] && m_s1_toSRAM_0_wdata[8])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[8] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[9] && m_s1_toSRAM_0_wdata[9])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[9] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[10] && m_s1_toSRAM_0_wdata[10])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[10] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[11] && m_s1_toSRAM_0_wdata[11])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[11] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[12] && m_s1_toSRAM_0_wdata[12])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[12] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[13] && m_s1_toSRAM_0_wdata[13])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[13] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[14] && m_s1_toSRAM_0_wdata[14])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[14] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[15] && m_s1_toSRAM_0_wdata[15])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[15] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[16] && m_s1_toSRAM_0_wdata[16])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[16] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[17] && m_s1_toSRAM_0_wdata[17])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[17] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[18] && m_s1_toSRAM_0_wdata[18])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[18] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[19] && m_s1_toSRAM_0_wdata[19])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[19] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[20] && m_s1_toSRAM_0_wdata[20])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[20] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[21] && m_s1_toSRAM_0_wdata[21])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[21] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[22] && m_s1_toSRAM_0_wdata[22])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[22] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[23] && m_s1_toSRAM_0_wdata[23])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[23] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[24] && m_s1_toSRAM_0_wdata[24])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[24] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[25] && m_s1_toSRAM_0_wdata[25])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[25] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[26] && m_s1_toSRAM_0_wdata[26])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[26] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[27] && m_s1_toSRAM_0_wdata[27])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[27] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[28] && m_s1_toSRAM_0_wdata[28])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[28] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[29] && m_s1_toSRAM_0_wdata[29])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[29] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[30] && m_s1_toSRAM_0_wdata[30])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[30] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[31] && m_s1_toSRAM_0_wdata[31])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[31] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[32] && m_s1_toSRAM_0_wdata[32])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[32] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[33] && m_s1_toSRAM_0_wdata[33])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[33] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[34] && m_s1_toSRAM_0_wdata[34])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[34] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[35] && m_s1_toSRAM_0_wdata[35])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[35] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[36] && m_s1_toSRAM_0_wdata[36])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[36] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[37] && m_s1_toSRAM_0_wdata[37])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[37] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[38] && m_s1_toSRAM_0_wdata[38])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[38] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[39] && m_s1_toSRAM_0_wdata[39])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[39] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[40] && m_s1_toSRAM_0_wdata[40])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[40] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[41] && m_s1_toSRAM_0_wdata[41])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[41] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[42] && m_s1_toSRAM_0_wdata[42])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[42] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[43] && m_s1_toSRAM_0_wdata[43])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[43] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[44] && m_s1_toSRAM_0_wdata[44])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[44] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[45] && m_s1_toSRAM_0_wdata[45])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[45] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[46] && m_s1_toSRAM_0_wdata[46])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[46] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[47] && m_s1_toSRAM_0_wdata[47])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[47] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[48] && m_s1_toSRAM_0_wdata[48])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[48] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[49] && m_s1_toSRAM_0_wdata[49])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[49] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[50] && m_s1_toSRAM_0_wdata[50])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[50] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[51] && m_s1_toSRAM_0_wdata[51])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[51] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[52] && m_s1_toSRAM_0_wdata[52])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[52] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[53] && m_s1_toSRAM_0_wdata[53])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[53] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[54] && m_s1_toSRAM_0_wdata[54])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[54] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[55] && m_s1_toSRAM_0_wdata[55])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[55] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[56] && m_s1_toSRAM_0_wdata[56])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[56] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[57] && m_s1_toSRAM_0_wdata[57])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[57] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[58] && m_s1_toSRAM_0_wdata[58])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[58] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[59] && m_s1_toSRAM_0_wdata[59])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[59] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[60] && m_s1_toSRAM_0_wdata[60])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[60] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[61] && m_s1_toSRAM_0_wdata[61])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[61] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[62] && m_s1_toSRAM_0_wdata[62])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[62] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[63] && m_s1_toSRAM_0_wdata[63])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[63] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[64] && m_s1_toSRAM_0_wdata[64])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[64] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[65] && m_s1_toSRAM_0_wdata[65])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[65] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[66] && m_s1_toSRAM_0_wdata[66])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[66] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[67] && m_s1_toSRAM_0_wdata[67])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[67] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[68] && m_s1_toSRAM_0_wdata[68])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[68] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[69] && m_s1_toSRAM_0_wdata[69])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[69] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[70] && m_s1_toSRAM_0_wdata[70])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[70] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[71] && m_s1_toSRAM_0_wdata[71])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[71] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[72] && m_s1_toSRAM_0_wdata[72])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[72] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[73] && m_s1_toSRAM_0_wdata[73])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[73] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[74] && m_s1_toSRAM_0_wdata[74])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[74] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[75] && m_s1_toSRAM_0_wdata[75])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[75] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[76] && m_s1_toSRAM_0_wdata[76])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[76] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[77] && m_s1_toSRAM_0_wdata[77])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[77] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[78] && m_s1_toSRAM_0_wdata[78])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[78] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[79] && m_s1_toSRAM_0_wdata[79])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[79] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[80] && m_s1_toSRAM_0_wdata[80])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[80] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[81] && m_s1_toSRAM_0_wdata[81])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[81] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[82] && m_s1_toSRAM_0_wdata[82])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[82] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[83] && m_s1_toSRAM_0_wdata[83])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[83] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[84] && m_s1_toSRAM_0_wdata[84])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[84] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[85] && m_s1_toSRAM_0_wdata[85])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[85] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[86] && m_s1_toSRAM_0_wdata[86])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[86] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[87] && m_s1_toSRAM_0_wdata[87])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[87] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[88] && m_s1_toSRAM_0_wdata[88])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[88] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wdata[89] && m_s1_toSRAM_0_wdata[89])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wdata[89] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wmask[0] && m_s1_toSRAM_0_wmask[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wmask[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_wmask[1] && m_s1_toSRAM_0_wmask[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_wmask[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_re && m_s1_toSRAM_0_re)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_re 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_we && m_s1_toSRAM_0_we)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_we 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_ack && m_s1_toSRAM_0_ack)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_ack 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_selectedOH && m_s1_toSRAM_0_selectedOH)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_selectedOH 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_array[0] && m_s1_toSRAM_0_array[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_array[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_array[1] && m_s1_toSRAM_0_array[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_array[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_array[2] && m_s1_toSRAM_0_array[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_array[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_array[3] && m_s1_toSRAM_0_array[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_array[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_array[4] && m_s1_toSRAM_0_array[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_array[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_0_array[5] && m_s1_toSRAM_0_array[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_0_array[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_addr[0] && m_s1_toSRAM_1_addr[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_addr[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_addr[1] && m_s1_toSRAM_1_addr[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_addr[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_addr[2] && m_s1_toSRAM_1_addr[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_addr[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_addr[3] && m_s1_toSRAM_1_addr[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_addr[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_addr[4] && m_s1_toSRAM_1_addr[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_addr[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_addr[5] && m_s1_toSRAM_1_addr[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_addr[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_addr_rd[0] && m_s1_toSRAM_1_addr_rd[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_addr_rd[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_addr_rd[1] && m_s1_toSRAM_1_addr_rd[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_addr_rd[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_addr_rd[2] && m_s1_toSRAM_1_addr_rd[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_addr_rd[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_addr_rd[3] && m_s1_toSRAM_1_addr_rd[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_addr_rd[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_addr_rd[4] && m_s1_toSRAM_1_addr_rd[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_addr_rd[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_addr_rd[5] && m_s1_toSRAM_1_addr_rd[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_addr_rd[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[0] && m_s1_toSRAM_1_wdata[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[1] && m_s1_toSRAM_1_wdata[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[2] && m_s1_toSRAM_1_wdata[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[3] && m_s1_toSRAM_1_wdata[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[4] && m_s1_toSRAM_1_wdata[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[5] && m_s1_toSRAM_1_wdata[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[6] && m_s1_toSRAM_1_wdata[6])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[6] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[7] && m_s1_toSRAM_1_wdata[7])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[7] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[8] && m_s1_toSRAM_1_wdata[8])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[8] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[9] && m_s1_toSRAM_1_wdata[9])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[9] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[10] && m_s1_toSRAM_1_wdata[10])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[10] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[11] && m_s1_toSRAM_1_wdata[11])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[11] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[12] && m_s1_toSRAM_1_wdata[12])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[12] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[13] && m_s1_toSRAM_1_wdata[13])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[13] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[14] && m_s1_toSRAM_1_wdata[14])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[14] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[15] && m_s1_toSRAM_1_wdata[15])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[15] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[16] && m_s1_toSRAM_1_wdata[16])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[16] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[17] && m_s1_toSRAM_1_wdata[17])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[17] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[18] && m_s1_toSRAM_1_wdata[18])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[18] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[19] && m_s1_toSRAM_1_wdata[19])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[19] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[20] && m_s1_toSRAM_1_wdata[20])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[20] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[21] && m_s1_toSRAM_1_wdata[21])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[21] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[22] && m_s1_toSRAM_1_wdata[22])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[22] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[23] && m_s1_toSRAM_1_wdata[23])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[23] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[24] && m_s1_toSRAM_1_wdata[24])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[24] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[25] && m_s1_toSRAM_1_wdata[25])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[25] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[26] && m_s1_toSRAM_1_wdata[26])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[26] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[27] && m_s1_toSRAM_1_wdata[27])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[27] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[28] && m_s1_toSRAM_1_wdata[28])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[28] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[29] && m_s1_toSRAM_1_wdata[29])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[29] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[30] && m_s1_toSRAM_1_wdata[30])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[30] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[31] && m_s1_toSRAM_1_wdata[31])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[31] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[32] && m_s1_toSRAM_1_wdata[32])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[32] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[33] && m_s1_toSRAM_1_wdata[33])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[33] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[34] && m_s1_toSRAM_1_wdata[34])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[34] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[35] && m_s1_toSRAM_1_wdata[35])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[35] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[36] && m_s1_toSRAM_1_wdata[36])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[36] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[37] && m_s1_toSRAM_1_wdata[37])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[37] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[38] && m_s1_toSRAM_1_wdata[38])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[38] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[39] && m_s1_toSRAM_1_wdata[39])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[39] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[40] && m_s1_toSRAM_1_wdata[40])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[40] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[41] && m_s1_toSRAM_1_wdata[41])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[41] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[42] && m_s1_toSRAM_1_wdata[42])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[42] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[43] && m_s1_toSRAM_1_wdata[43])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[43] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[44] && m_s1_toSRAM_1_wdata[44])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[44] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[45] && m_s1_toSRAM_1_wdata[45])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[45] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[46] && m_s1_toSRAM_1_wdata[46])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[46] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[47] && m_s1_toSRAM_1_wdata[47])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[47] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[48] && m_s1_toSRAM_1_wdata[48])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[48] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[49] && m_s1_toSRAM_1_wdata[49])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[49] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[50] && m_s1_toSRAM_1_wdata[50])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[50] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[51] && m_s1_toSRAM_1_wdata[51])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[51] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[52] && m_s1_toSRAM_1_wdata[52])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[52] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[53] && m_s1_toSRAM_1_wdata[53])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[53] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[54] && m_s1_toSRAM_1_wdata[54])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[54] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[55] && m_s1_toSRAM_1_wdata[55])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[55] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[56] && m_s1_toSRAM_1_wdata[56])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[56] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[57] && m_s1_toSRAM_1_wdata[57])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[57] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[58] && m_s1_toSRAM_1_wdata[58])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[58] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[59] && m_s1_toSRAM_1_wdata[59])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[59] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[60] && m_s1_toSRAM_1_wdata[60])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[60] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[61] && m_s1_toSRAM_1_wdata[61])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[61] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[62] && m_s1_toSRAM_1_wdata[62])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[62] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[63] && m_s1_toSRAM_1_wdata[63])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[63] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[64] && m_s1_toSRAM_1_wdata[64])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[64] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[65] && m_s1_toSRAM_1_wdata[65])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[65] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[66] && m_s1_toSRAM_1_wdata[66])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[66] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[67] && m_s1_toSRAM_1_wdata[67])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[67] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[68] && m_s1_toSRAM_1_wdata[68])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[68] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[69] && m_s1_toSRAM_1_wdata[69])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[69] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[70] && m_s1_toSRAM_1_wdata[70])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[70] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[71] && m_s1_toSRAM_1_wdata[71])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[71] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[72] && m_s1_toSRAM_1_wdata[72])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[72] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[73] && m_s1_toSRAM_1_wdata[73])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[73] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[74] && m_s1_toSRAM_1_wdata[74])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[74] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[75] && m_s1_toSRAM_1_wdata[75])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[75] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[76] && m_s1_toSRAM_1_wdata[76])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[76] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[77] && m_s1_toSRAM_1_wdata[77])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[77] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[78] && m_s1_toSRAM_1_wdata[78])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[78] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[79] && m_s1_toSRAM_1_wdata[79])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[79] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[80] && m_s1_toSRAM_1_wdata[80])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[80] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[81] && m_s1_toSRAM_1_wdata[81])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[81] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[82] && m_s1_toSRAM_1_wdata[82])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[82] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[83] && m_s1_toSRAM_1_wdata[83])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[83] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[84] && m_s1_toSRAM_1_wdata[84])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[84] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[85] && m_s1_toSRAM_1_wdata[85])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[85] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[86] && m_s1_toSRAM_1_wdata[86])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[86] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[87] && m_s1_toSRAM_1_wdata[87])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[87] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[88] && m_s1_toSRAM_1_wdata[88])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[88] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wdata[89] && m_s1_toSRAM_1_wdata[89])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wdata[89] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wmask[0] && m_s1_toSRAM_1_wmask[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wmask[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_wmask[1] && m_s1_toSRAM_1_wmask[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_wmask[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_re && m_s1_toSRAM_1_re)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_re 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_we && m_s1_toSRAM_1_we)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_we 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_ack && m_s1_toSRAM_1_ack)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_ack 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_selectedOH && m_s1_toSRAM_1_selectedOH)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_selectedOH 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_array[0] && m_s1_toSRAM_1_array[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_array[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_array[1] && m_s1_toSRAM_1_array[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_array[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_array[2] && m_s1_toSRAM_1_array[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_array[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_array[3] && m_s1_toSRAM_1_array[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_array[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_array[4] && m_s1_toSRAM_1_array[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_array[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_1_array[5] && m_s1_toSRAM_1_array[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_1_array[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_addr[0] && m_s1_toSRAM_2_addr[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_addr[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_addr[1] && m_s1_toSRAM_2_addr[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_addr[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_addr[2] && m_s1_toSRAM_2_addr[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_addr[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_addr[3] && m_s1_toSRAM_2_addr[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_addr[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_addr[4] && m_s1_toSRAM_2_addr[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_addr[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_addr[5] && m_s1_toSRAM_2_addr[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_addr[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_addr_rd[0] && m_s1_toSRAM_2_addr_rd[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_addr_rd[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_addr_rd[1] && m_s1_toSRAM_2_addr_rd[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_addr_rd[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_addr_rd[2] && m_s1_toSRAM_2_addr_rd[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_addr_rd[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_addr_rd[3] && m_s1_toSRAM_2_addr_rd[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_addr_rd[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_addr_rd[4] && m_s1_toSRAM_2_addr_rd[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_addr_rd[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_addr_rd[5] && m_s1_toSRAM_2_addr_rd[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_addr_rd[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[0] && m_s1_toSRAM_2_wdata[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[1] && m_s1_toSRAM_2_wdata[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[2] && m_s1_toSRAM_2_wdata[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[3] && m_s1_toSRAM_2_wdata[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[4] && m_s1_toSRAM_2_wdata[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[5] && m_s1_toSRAM_2_wdata[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[6] && m_s1_toSRAM_2_wdata[6])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[6] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[7] && m_s1_toSRAM_2_wdata[7])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[7] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[8] && m_s1_toSRAM_2_wdata[8])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[8] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[9] && m_s1_toSRAM_2_wdata[9])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[9] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[10] && m_s1_toSRAM_2_wdata[10])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[10] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[11] && m_s1_toSRAM_2_wdata[11])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[11] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[12] && m_s1_toSRAM_2_wdata[12])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[12] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[13] && m_s1_toSRAM_2_wdata[13])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[13] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[14] && m_s1_toSRAM_2_wdata[14])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[14] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[15] && m_s1_toSRAM_2_wdata[15])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[15] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[16] && m_s1_toSRAM_2_wdata[16])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[16] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[17] && m_s1_toSRAM_2_wdata[17])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[17] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[18] && m_s1_toSRAM_2_wdata[18])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[18] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[19] && m_s1_toSRAM_2_wdata[19])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[19] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[20] && m_s1_toSRAM_2_wdata[20])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[20] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[21] && m_s1_toSRAM_2_wdata[21])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[21] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[22] && m_s1_toSRAM_2_wdata[22])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[22] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[23] && m_s1_toSRAM_2_wdata[23])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[23] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[24] && m_s1_toSRAM_2_wdata[24])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[24] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[25] && m_s1_toSRAM_2_wdata[25])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[25] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[26] && m_s1_toSRAM_2_wdata[26])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[26] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[27] && m_s1_toSRAM_2_wdata[27])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[27] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[28] && m_s1_toSRAM_2_wdata[28])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[28] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[29] && m_s1_toSRAM_2_wdata[29])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[29] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[30] && m_s1_toSRAM_2_wdata[30])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[30] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[31] && m_s1_toSRAM_2_wdata[31])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[31] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[32] && m_s1_toSRAM_2_wdata[32])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[32] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[33] && m_s1_toSRAM_2_wdata[33])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[33] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[34] && m_s1_toSRAM_2_wdata[34])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[34] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[35] && m_s1_toSRAM_2_wdata[35])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[35] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[36] && m_s1_toSRAM_2_wdata[36])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[36] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[37] && m_s1_toSRAM_2_wdata[37])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[37] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[38] && m_s1_toSRAM_2_wdata[38])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[38] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[39] && m_s1_toSRAM_2_wdata[39])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[39] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[40] && m_s1_toSRAM_2_wdata[40])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[40] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[41] && m_s1_toSRAM_2_wdata[41])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[41] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[42] && m_s1_toSRAM_2_wdata[42])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[42] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[43] && m_s1_toSRAM_2_wdata[43])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[43] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[44] && m_s1_toSRAM_2_wdata[44])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[44] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[45] && m_s1_toSRAM_2_wdata[45])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[45] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[46] && m_s1_toSRAM_2_wdata[46])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[46] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[47] && m_s1_toSRAM_2_wdata[47])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[47] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[48] && m_s1_toSRAM_2_wdata[48])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[48] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[49] && m_s1_toSRAM_2_wdata[49])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[49] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[50] && m_s1_toSRAM_2_wdata[50])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[50] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[51] && m_s1_toSRAM_2_wdata[51])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[51] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[52] && m_s1_toSRAM_2_wdata[52])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[52] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[53] && m_s1_toSRAM_2_wdata[53])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[53] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[54] && m_s1_toSRAM_2_wdata[54])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[54] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[55] && m_s1_toSRAM_2_wdata[55])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[55] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[56] && m_s1_toSRAM_2_wdata[56])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[56] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[57] && m_s1_toSRAM_2_wdata[57])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[57] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[58] && m_s1_toSRAM_2_wdata[58])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[58] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[59] && m_s1_toSRAM_2_wdata[59])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[59] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[60] && m_s1_toSRAM_2_wdata[60])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[60] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[61] && m_s1_toSRAM_2_wdata[61])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[61] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[62] && m_s1_toSRAM_2_wdata[62])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[62] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[63] && m_s1_toSRAM_2_wdata[63])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[63] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[64] && m_s1_toSRAM_2_wdata[64])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[64] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[65] && m_s1_toSRAM_2_wdata[65])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[65] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[66] && m_s1_toSRAM_2_wdata[66])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[66] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[67] && m_s1_toSRAM_2_wdata[67])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[67] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[68] && m_s1_toSRAM_2_wdata[68])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[68] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[69] && m_s1_toSRAM_2_wdata[69])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[69] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[70] && m_s1_toSRAM_2_wdata[70])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[70] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[71] && m_s1_toSRAM_2_wdata[71])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[71] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[72] && m_s1_toSRAM_2_wdata[72])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[72] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[73] && m_s1_toSRAM_2_wdata[73])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[73] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[74] && m_s1_toSRAM_2_wdata[74])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[74] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[75] && m_s1_toSRAM_2_wdata[75])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[75] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[76] && m_s1_toSRAM_2_wdata[76])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[76] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[77] && m_s1_toSRAM_2_wdata[77])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[77] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[78] && m_s1_toSRAM_2_wdata[78])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[78] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[79] && m_s1_toSRAM_2_wdata[79])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[79] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[80] && m_s1_toSRAM_2_wdata[80])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[80] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[81] && m_s1_toSRAM_2_wdata[81])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[81] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[82] && m_s1_toSRAM_2_wdata[82])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[82] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[83] && m_s1_toSRAM_2_wdata[83])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[83] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[84] && m_s1_toSRAM_2_wdata[84])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[84] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[85] && m_s1_toSRAM_2_wdata[85])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[85] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[86] && m_s1_toSRAM_2_wdata[86])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[86] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[87] && m_s1_toSRAM_2_wdata[87])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[87] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[88] && m_s1_toSRAM_2_wdata[88])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[88] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wdata[89] && m_s1_toSRAM_2_wdata[89])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wdata[89] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wmask[0] && m_s1_toSRAM_2_wmask[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wmask[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_wmask[1] && m_s1_toSRAM_2_wmask[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_wmask[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_re && m_s1_toSRAM_2_re)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_re 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_we && m_s1_toSRAM_2_we)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_we 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_ack && m_s1_toSRAM_2_ack)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_ack 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_selectedOH && m_s1_toSRAM_2_selectedOH)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_selectedOH 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_array[0] && m_s1_toSRAM_2_array[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_array[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_array[1] && m_s1_toSRAM_2_array[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_array[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_array[2] && m_s1_toSRAM_2_array[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_array[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_array[3] && m_s1_toSRAM_2_array[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_array[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_array[4] && m_s1_toSRAM_2_array[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_array[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_2_array[5] && m_s1_toSRAM_2_array[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_2_array[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_addr[0] && m_s1_toSRAM_3_addr[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_addr[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_addr[1] && m_s1_toSRAM_3_addr[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_addr[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_addr[2] && m_s1_toSRAM_3_addr[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_addr[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_addr[3] && m_s1_toSRAM_3_addr[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_addr[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_addr[4] && m_s1_toSRAM_3_addr[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_addr[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_addr[5] && m_s1_toSRAM_3_addr[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_addr[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_addr_rd[0] && m_s1_toSRAM_3_addr_rd[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_addr_rd[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_addr_rd[1] && m_s1_toSRAM_3_addr_rd[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_addr_rd[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_addr_rd[2] && m_s1_toSRAM_3_addr_rd[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_addr_rd[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_addr_rd[3] && m_s1_toSRAM_3_addr_rd[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_addr_rd[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_addr_rd[4] && m_s1_toSRAM_3_addr_rd[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_addr_rd[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_addr_rd[5] && m_s1_toSRAM_3_addr_rd[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_addr_rd[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[0] && m_s1_toSRAM_3_wdata[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[1] && m_s1_toSRAM_3_wdata[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[2] && m_s1_toSRAM_3_wdata[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[3] && m_s1_toSRAM_3_wdata[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[4] && m_s1_toSRAM_3_wdata[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[5] && m_s1_toSRAM_3_wdata[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[5] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[6] && m_s1_toSRAM_3_wdata[6])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[6] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[7] && m_s1_toSRAM_3_wdata[7])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[7] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[8] && m_s1_toSRAM_3_wdata[8])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[8] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[9] && m_s1_toSRAM_3_wdata[9])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[9] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[10] && m_s1_toSRAM_3_wdata[10])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[10] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[11] && m_s1_toSRAM_3_wdata[11])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[11] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[12] && m_s1_toSRAM_3_wdata[12])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[12] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[13] && m_s1_toSRAM_3_wdata[13])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[13] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[14] && m_s1_toSRAM_3_wdata[14])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[14] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[15] && m_s1_toSRAM_3_wdata[15])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[15] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[16] && m_s1_toSRAM_3_wdata[16])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[16] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[17] && m_s1_toSRAM_3_wdata[17])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[17] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[18] && m_s1_toSRAM_3_wdata[18])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[18] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[19] && m_s1_toSRAM_3_wdata[19])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[19] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[20] && m_s1_toSRAM_3_wdata[20])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[20] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[21] && m_s1_toSRAM_3_wdata[21])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[21] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[22] && m_s1_toSRAM_3_wdata[22])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[22] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[23] && m_s1_toSRAM_3_wdata[23])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[23] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[24] && m_s1_toSRAM_3_wdata[24])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[24] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[25] && m_s1_toSRAM_3_wdata[25])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[25] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[26] && m_s1_toSRAM_3_wdata[26])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[26] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[27] && m_s1_toSRAM_3_wdata[27])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[27] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[28] && m_s1_toSRAM_3_wdata[28])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[28] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[29] && m_s1_toSRAM_3_wdata[29])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[29] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[30] && m_s1_toSRAM_3_wdata[30])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[30] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[31] && m_s1_toSRAM_3_wdata[31])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[31] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[32] && m_s1_toSRAM_3_wdata[32])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[32] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[33] && m_s1_toSRAM_3_wdata[33])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[33] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[34] && m_s1_toSRAM_3_wdata[34])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[34] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[35] && m_s1_toSRAM_3_wdata[35])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[35] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[36] && m_s1_toSRAM_3_wdata[36])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[36] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[37] && m_s1_toSRAM_3_wdata[37])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[37] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[38] && m_s1_toSRAM_3_wdata[38])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[38] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[39] && m_s1_toSRAM_3_wdata[39])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[39] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[40] && m_s1_toSRAM_3_wdata[40])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[40] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[41] && m_s1_toSRAM_3_wdata[41])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[41] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[42] && m_s1_toSRAM_3_wdata[42])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[42] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[43] && m_s1_toSRAM_3_wdata[43])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[43] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[44] && m_s1_toSRAM_3_wdata[44])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[44] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[45] && m_s1_toSRAM_3_wdata[45])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[45] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[46] && m_s1_toSRAM_3_wdata[46])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[46] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[47] && m_s1_toSRAM_3_wdata[47])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[47] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[48] && m_s1_toSRAM_3_wdata[48])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[48] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[49] && m_s1_toSRAM_3_wdata[49])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[49] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[50] && m_s1_toSRAM_3_wdata[50])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[50] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[51] && m_s1_toSRAM_3_wdata[51])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[51] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[52] && m_s1_toSRAM_3_wdata[52])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[52] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[53] && m_s1_toSRAM_3_wdata[53])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[53] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[54] && m_s1_toSRAM_3_wdata[54])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[54] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[55] && m_s1_toSRAM_3_wdata[55])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[55] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[56] && m_s1_toSRAM_3_wdata[56])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[56] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[57] && m_s1_toSRAM_3_wdata[57])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[57] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[58] && m_s1_toSRAM_3_wdata[58])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[58] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[59] && m_s1_toSRAM_3_wdata[59])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[59] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[60] && m_s1_toSRAM_3_wdata[60])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[60] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[61] && m_s1_toSRAM_3_wdata[61])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[61] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[62] && m_s1_toSRAM_3_wdata[62])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[62] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[63] && m_s1_toSRAM_3_wdata[63])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[63] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[64] && m_s1_toSRAM_3_wdata[64])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[64] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[65] && m_s1_toSRAM_3_wdata[65])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[65] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[66] && m_s1_toSRAM_3_wdata[66])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[66] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[67] && m_s1_toSRAM_3_wdata[67])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[67] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[68] && m_s1_toSRAM_3_wdata[68])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[68] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[69] && m_s1_toSRAM_3_wdata[69])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[69] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[70] && m_s1_toSRAM_3_wdata[70])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[70] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[71] && m_s1_toSRAM_3_wdata[71])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[71] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[72] && m_s1_toSRAM_3_wdata[72])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[72] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[73] && m_s1_toSRAM_3_wdata[73])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[73] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[74] && m_s1_toSRAM_3_wdata[74])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[74] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[75] && m_s1_toSRAM_3_wdata[75])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[75] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[76] && m_s1_toSRAM_3_wdata[76])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[76] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[77] && m_s1_toSRAM_3_wdata[77])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[77] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[78] && m_s1_toSRAM_3_wdata[78])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[78] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[79] && m_s1_toSRAM_3_wdata[79])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[79] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[80] && m_s1_toSRAM_3_wdata[80])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[80] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[81] && m_s1_toSRAM_3_wdata[81])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[81] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[82] && m_s1_toSRAM_3_wdata[82])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[82] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[83] && m_s1_toSRAM_3_wdata[83])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[83] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[84] && m_s1_toSRAM_3_wdata[84])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[84] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[85] && m_s1_toSRAM_3_wdata[85])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[85] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[86] && m_s1_toSRAM_3_wdata[86])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[86] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[87] && m_s1_toSRAM_3_wdata[87])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[87] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[88] && m_s1_toSRAM_3_wdata[88])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[88] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wdata[89] && m_s1_toSRAM_3_wdata[89])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wdata[89] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wmask[0] && m_s1_toSRAM_3_wmask[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wmask[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_wmask[1] && m_s1_toSRAM_3_wmask[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_wmask[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_re && m_s1_toSRAM_3_re)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_re 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_we && m_s1_toSRAM_3_we)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_we 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_ack && m_s1_toSRAM_3_ack)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_ack 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_selectedOH && m_s1_toSRAM_3_selectedOH)) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_selectedOH 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_array[0] && m_s1_toSRAM_3_array[0])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_array[0] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_array[1] && m_s1_toSRAM_3_array[1])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_array[1] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_array[2] && m_s1_toSRAM_3_array[2])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_array[2] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_array[3] && m_s1_toSRAM_3_array[3])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_array[3] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_array[4] && m_s1_toSRAM_3_array[4])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_array[4] 未见过 0 和 1"); end
    if (!(m_s0_toSRAM_3_array[5] && m_s1_toSRAM_3_array[5])) begin cov_fail++; $display("[COV] MbistBitmapCache.toSRAM_3_array[5] 未见过 0 和 1"); end
    $display("[ARM] MbistBitmapCache armed_at=%0d", m_armed_at);
    if (m_armed_at < 0) begin cov_fail++; $display("[ARM] MbistBitmapCache 从未 arm"); end
    $display("[COV] MbistBitmapCache.all = %0d", m_cov_all);
    if (m_cov_all < 50) begin cov_fail++; $display("[COV] MbistBitmapCache.all < 50"); end
    $display("[COV] MbistBitmapCache.reset_mid = %0d", m_cov_reset_mid);
    if (m_cov_reset_mid < 50) begin cov_fail++; $display("[COV] MbistBitmapCache.reset_mid < 50"); end
    $display("[COV] MbistBitmapCache.sel0 = %0d", m_cov_sel0);
    if (m_cov_sel0 < 50) begin cov_fail++; $display("[COV] MbistBitmapCache.sel0 < 50"); end
    $display("[COV] MbistBitmapCache.sel1 = %0d", m_cov_sel1);
    if (m_cov_sel1 < 50) begin cov_fail++; $display("[COV] MbistBitmapCache.sel1 < 50"); end
    $display("[COV] MbistBitmapCache.sel2 = %0d", m_cov_sel2);
    if (m_cov_sel2 < 50) begin cov_fail++; $display("[COV] MbistBitmapCache.sel2 < 50"); end
    $display("[COV] MbistBitmapCache.sel3 = %0d", m_cov_sel3);
    if (m_cov_sel3 < 50) begin cov_fail++; $display("[COV] MbistBitmapCache.sel3 < 50"); end
    $display("[COV] MbistBitmapCache.miss = %0d", m_cov_miss);
    if (m_cov_miss < 50) begin cov_fail++; $display("[COV] MbistBitmapCache.miss < 50"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
