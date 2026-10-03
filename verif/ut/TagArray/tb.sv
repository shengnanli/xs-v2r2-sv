// 自动生成：verif/ut/TagArray/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// TagSRAMBank / TagArray 双例化逐拍比对：golden <Top> vs 重写 <Top>_xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= TagSRAMBank =================
  int unsigned tsb_mode = 0;
  logic tsb_reset;
  wire  tsb_g_io_read_ready, tsb_i_io_read_ready;
  logic tsb_s0_io_read_ready = '0, tsb_s1_io_read_ready = '0;
  logic tsb_io_read_valid;
  logic [7:0] tsb_io_read_bits_idx;
  wire  [42:0] tsb_g_io_resp_0, tsb_i_io_resp_0;
  logic [42:0] tsb_s0_io_resp_0 = '0, tsb_s1_io_resp_0 = '0;
  wire  [42:0] tsb_g_io_resp_1, tsb_i_io_resp_1;
  logic [42:0] tsb_s0_io_resp_1 = '0, tsb_s1_io_resp_1 = '0;
  logic tsb_io_write_valid;
  logic [7:0] tsb_io_write_bits_idx;
  logic [35:0] tsb_io_write_bits_tag;
  logic [6:0] tsb_io_write_bits_ecc;
  logic [1:0] tsb_io_write_bits_way_en;
  logic [8:0] tsb_boreChildrenBd_bore_addr;
  logic [8:0] tsb_boreChildrenBd_bore_addr_rd;
  logic [85:0] tsb_boreChildrenBd_bore_wdata;
  logic [1:0] tsb_boreChildrenBd_bore_wmask;
  logic tsb_boreChildrenBd_bore_re;
  logic tsb_boreChildrenBd_bore_we;
  wire  [85:0] tsb_g_boreChildrenBd_bore_rdata, tsb_i_boreChildrenBd_bore_rdata;
  logic [85:0] tsb_s0_boreChildrenBd_bore_rdata = '0, tsb_s1_boreChildrenBd_bore_rdata = '0;
  logic tsb_boreChildrenBd_bore_ack;
  logic tsb_boreChildrenBd_bore_selectedOH;
  logic [5:0] tsb_boreChildrenBd_bore_array;
  logic tsb_sigFromSrams_bore_ram_hold;
  logic tsb_sigFromSrams_bore_ram_bypass;
  logic tsb_sigFromSrams_bore_ram_bp_clken;
  logic tsb_sigFromSrams_bore_ram_aux_clk;
  logic tsb_sigFromSrams_bore_ram_aux_ckbp;
  logic tsb_sigFromSrams_bore_ram_mcp_hold;
  logic tsb_sigFromSrams_bore_cgen;
  int tsb_cov_sweep = 0;
  int tsb_cov_read_fire = 0;
  int tsb_cov_read_blocked = 0;
  int tsb_cov_write_way0 = 0;
  logic [1:0] tsb_armed = '0;
  int tsb_armed_at = -1;
  TagSRAMBank tsb_u_gold (
    .clock(clk),
    .reset(tsb_reset),
    .io_read_ready(tsb_g_io_read_ready),
    .io_read_valid(tsb_io_read_valid),
    .io_read_bits_idx(tsb_io_read_bits_idx),
    .io_resp_0(tsb_g_io_resp_0),
    .io_resp_1(tsb_g_io_resp_1),
    .io_write_valid(tsb_io_write_valid),
    .io_write_bits_idx(tsb_io_write_bits_idx),
    .io_write_bits_tag(tsb_io_write_bits_tag),
    .io_write_bits_ecc(tsb_io_write_bits_ecc),
    .io_write_bits_way_en(tsb_io_write_bits_way_en),
    .boreChildrenBd_bore_addr(tsb_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(tsb_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(tsb_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(tsb_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(tsb_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(tsb_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(tsb_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(tsb_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(tsb_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(tsb_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(tsb_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(tsb_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(tsb_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(tsb_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(tsb_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(tsb_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(tsb_sigFromSrams_bore_cgen)
  );
  TagSRAMBank_xs tsb_u_impl (
    .clock(clk),
    .reset(tsb_reset),
    .io_read_ready(tsb_i_io_read_ready),
    .io_read_valid(tsb_io_read_valid),
    .io_read_bits_idx(tsb_io_read_bits_idx),
    .io_resp_0(tsb_i_io_resp_0),
    .io_resp_1(tsb_i_io_resp_1),
    .io_write_valid(tsb_io_write_valid),
    .io_write_bits_idx(tsb_io_write_bits_idx),
    .io_write_bits_tag(tsb_io_write_bits_tag),
    .io_write_bits_ecc(tsb_io_write_bits_ecc),
    .io_write_bits_way_en(tsb_io_write_bits_way_en),
    .boreChildrenBd_bore_addr(tsb_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(tsb_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(tsb_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(tsb_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(tsb_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(tsb_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(tsb_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(tsb_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(tsb_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(tsb_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(tsb_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(tsb_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(tsb_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(tsb_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(tsb_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(tsb_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(tsb_sigFromSrams_bore_cgen)
  );

  // ================= TagArray =================
  int unsigned ta_mode = 0;
  logic ta_reset;
  wire  ta_g_io_read_ready, ta_i_io_read_ready;
  logic ta_s0_io_read_ready = '0, ta_s1_io_read_ready = '0;
  logic ta_io_read_valid;
  logic [7:0] ta_io_read_bits_idx;
  wire  [42:0] ta_g_io_resp_0, ta_i_io_resp_0;
  logic [42:0] ta_s0_io_resp_0 = '0, ta_s1_io_resp_0 = '0;
  wire  [42:0] ta_g_io_resp_1, ta_i_io_resp_1;
  logic [42:0] ta_s0_io_resp_1 = '0, ta_s1_io_resp_1 = '0;
  wire  [42:0] ta_g_io_resp_2, ta_i_io_resp_2;
  logic [42:0] ta_s0_io_resp_2 = '0, ta_s1_io_resp_2 = '0;
  wire  [42:0] ta_g_io_resp_3, ta_i_io_resp_3;
  logic [42:0] ta_s0_io_resp_3 = '0, ta_s1_io_resp_3 = '0;
  logic ta_io_write_valid;
  logic [7:0] ta_io_write_bits_idx;
  logic [3:0] ta_io_write_bits_way_en;
  logic [35:0] ta_io_write_bits_tag;
  logic [6:0] ta_io_write_bits_ecc;
  logic [8:0] ta_boreChildrenBd_bore_addr;
  logic [8:0] ta_boreChildrenBd_bore_addr_rd;
  logic [85:0] ta_boreChildrenBd_bore_wdata;
  logic [1:0] ta_boreChildrenBd_bore_wmask;
  logic ta_boreChildrenBd_bore_re;
  logic ta_boreChildrenBd_bore_we;
  wire  [85:0] ta_g_boreChildrenBd_bore_rdata, ta_i_boreChildrenBd_bore_rdata;
  logic [85:0] ta_s0_boreChildrenBd_bore_rdata = '0, ta_s1_boreChildrenBd_bore_rdata = '0;
  logic ta_boreChildrenBd_bore_ack;
  logic ta_boreChildrenBd_bore_selectedOH;
  logic [5:0] ta_boreChildrenBd_bore_array;
  logic [8:0] ta_boreChildrenBd_bore_1_addr;
  logic [8:0] ta_boreChildrenBd_bore_1_addr_rd;
  logic [85:0] ta_boreChildrenBd_bore_1_wdata;
  logic [1:0] ta_boreChildrenBd_bore_1_wmask;
  logic ta_boreChildrenBd_bore_1_re;
  logic ta_boreChildrenBd_bore_1_we;
  wire  [85:0] ta_g_boreChildrenBd_bore_1_rdata, ta_i_boreChildrenBd_bore_1_rdata;
  logic [85:0] ta_s0_boreChildrenBd_bore_1_rdata = '0, ta_s1_boreChildrenBd_bore_1_rdata = '0;
  logic ta_boreChildrenBd_bore_1_ack;
  logic ta_boreChildrenBd_bore_1_selectedOH;
  logic [5:0] ta_boreChildrenBd_bore_1_array;
  logic ta_sigFromSrams_bore_ram_hold;
  logic ta_sigFromSrams_bore_ram_bypass;
  logic ta_sigFromSrams_bore_ram_bp_clken;
  logic ta_sigFromSrams_bore_ram_aux_clk;
  logic ta_sigFromSrams_bore_ram_aux_ckbp;
  logic ta_sigFromSrams_bore_ram_mcp_hold;
  logic ta_sigFromSrams_bore_cgen;
  logic ta_sigFromSrams_bore_1_ram_hold;
  logic ta_sigFromSrams_bore_1_ram_bypass;
  logic ta_sigFromSrams_bore_1_ram_bp_clken;
  logic ta_sigFromSrams_bore_1_ram_aux_clk;
  logic ta_sigFromSrams_bore_1_ram_aux_ckbp;
  logic ta_sigFromSrams_bore_1_ram_mcp_hold;
  logic ta_sigFromSrams_bore_1_cgen;
  int ta_cov_read_fire = 0;
  int ta_cov_write_hi = 0;
  logic [1:0] ta_armed = '0;
  int ta_armed_at = -1;
  TagArray ta_u_gold (
    .clock(clk),
    .reset(ta_reset),
    .io_read_ready(ta_g_io_read_ready),
    .io_read_valid(ta_io_read_valid),
    .io_read_bits_idx(ta_io_read_bits_idx),
    .io_resp_0(ta_g_io_resp_0),
    .io_resp_1(ta_g_io_resp_1),
    .io_resp_2(ta_g_io_resp_2),
    .io_resp_3(ta_g_io_resp_3),
    .io_write_valid(ta_io_write_valid),
    .io_write_bits_idx(ta_io_write_bits_idx),
    .io_write_bits_way_en(ta_io_write_bits_way_en),
    .io_write_bits_tag(ta_io_write_bits_tag),
    .io_write_bits_ecc(ta_io_write_bits_ecc),
    .boreChildrenBd_bore_addr(ta_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(ta_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(ta_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(ta_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(ta_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(ta_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(ta_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(ta_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(ta_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(ta_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(ta_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(ta_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(ta_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(ta_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(ta_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(ta_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(ta_g_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(ta_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(ta_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(ta_boreChildrenBd_bore_1_array),
    .sigFromSrams_bore_ram_hold(ta_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(ta_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(ta_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(ta_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(ta_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(ta_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(ta_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(ta_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(ta_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(ta_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(ta_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(ta_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(ta_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(ta_sigFromSrams_bore_1_cgen)
  );
  TagArray_xs ta_u_impl (
    .clock(clk),
    .reset(ta_reset),
    .io_read_ready(ta_i_io_read_ready),
    .io_read_valid(ta_io_read_valid),
    .io_read_bits_idx(ta_io_read_bits_idx),
    .io_resp_0(ta_i_io_resp_0),
    .io_resp_1(ta_i_io_resp_1),
    .io_resp_2(ta_i_io_resp_2),
    .io_resp_3(ta_i_io_resp_3),
    .io_write_valid(ta_io_write_valid),
    .io_write_bits_idx(ta_io_write_bits_idx),
    .io_write_bits_way_en(ta_io_write_bits_way_en),
    .io_write_bits_tag(ta_io_write_bits_tag),
    .io_write_bits_ecc(ta_io_write_bits_ecc),
    .boreChildrenBd_bore_addr(ta_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(ta_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(ta_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(ta_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(ta_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(ta_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(ta_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(ta_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(ta_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(ta_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(ta_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(ta_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(ta_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(ta_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(ta_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(ta_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(ta_i_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(ta_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(ta_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(ta_boreChildrenBd_bore_1_array),
    .sigFromSrams_bore_ram_hold(ta_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(ta_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(ta_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(ta_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(ta_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(ta_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(ta_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(ta_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(ta_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(ta_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(ta_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(ta_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(ta_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(ta_sigFromSrams_bore_1_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 3000 == 0) tsb_mode = $urandom_range(0, 15);
      tsb_io_read_valid = 1'($urandom);
      tsb_io_read_bits_idx = 8'($urandom);
      tsb_io_write_valid = 1'($urandom);
      tsb_io_write_bits_idx = 8'($urandom);
      tsb_io_write_bits_tag = 36'({$urandom, $urandom});
      tsb_io_write_bits_ecc = 7'($urandom);
      tsb_io_write_bits_way_en = 2'($urandom);
      tsb_boreChildrenBd_bore_addr = 9'($urandom);
      tsb_boreChildrenBd_bore_addr_rd = 9'($urandom);
      tsb_boreChildrenBd_bore_wdata = 86'({$urandom, $urandom, $urandom});
      tsb_boreChildrenBd_bore_wmask = 2'($urandom);
      tsb_boreChildrenBd_bore_re = 1'($urandom);
      tsb_boreChildrenBd_bore_we = 1'($urandom);
      tsb_boreChildrenBd_bore_ack = 1'($urandom);
      tsb_boreChildrenBd_bore_selectedOH = 1'($urandom);
      tsb_boreChildrenBd_bore_array = 6'($urandom);
      tsb_sigFromSrams_bore_ram_hold = 1'($urandom);
      tsb_sigFromSrams_bore_ram_bypass = 1'($urandom);
      tsb_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      tsb_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      tsb_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      tsb_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      tsb_sigFromSrams_bore_cgen = 1'($urandom);
      tsb_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_tsb
        tsb_io_read_bits_idx = 8'($urandom_range(0, 15));
        tsb_io_write_bits_idx = 8'($urandom_range(0, 15));
        tsb_io_write_valid = ($urandom_range(0, 2) == 0);
        if (tsb_mode < 12) begin
          tsb_boreChildrenBd_bore_addr = '0;
          tsb_boreChildrenBd_bore_addr_rd = '0;
          tsb_boreChildrenBd_bore_wdata = '0;
          tsb_boreChildrenBd_bore_wmask = '0;
          tsb_boreChildrenBd_bore_re = '0;
          tsb_boreChildrenBd_bore_we = '0;
          tsb_boreChildrenBd_bore_ack = '0;
          tsb_boreChildrenBd_bore_selectedOH = '0;
          tsb_boreChildrenBd_bore_array = '0;
          tsb_sigFromSrams_bore_ram_hold = '0;
          tsb_sigFromSrams_bore_ram_bypass = '0;
          tsb_sigFromSrams_bore_ram_bp_clken = '0;
          tsb_sigFromSrams_bore_ram_aux_clk = '0;
          tsb_sigFromSrams_bore_ram_aux_ckbp = '0;
          tsb_sigFromSrams_bore_ram_mcp_hold = '0;
          tsb_sigFromSrams_bore_cgen = '0;
        end
      end
      if (cyc % 3000 == 0) ta_mode = $urandom_range(0, 15);
      ta_io_read_valid = 1'($urandom);
      ta_io_read_bits_idx = 8'($urandom);
      ta_io_write_valid = 1'($urandom);
      ta_io_write_bits_idx = 8'($urandom);
      ta_io_write_bits_way_en = 4'($urandom);
      ta_io_write_bits_tag = 36'({$urandom, $urandom});
      ta_io_write_bits_ecc = 7'($urandom);
      ta_boreChildrenBd_bore_addr = 9'($urandom);
      ta_boreChildrenBd_bore_addr_rd = 9'($urandom);
      ta_boreChildrenBd_bore_wdata = 86'({$urandom, $urandom, $urandom});
      ta_boreChildrenBd_bore_wmask = 2'($urandom);
      ta_boreChildrenBd_bore_re = 1'($urandom);
      ta_boreChildrenBd_bore_we = 1'($urandom);
      ta_boreChildrenBd_bore_ack = 1'($urandom);
      ta_boreChildrenBd_bore_selectedOH = 1'($urandom);
      ta_boreChildrenBd_bore_array = 6'($urandom);
      ta_boreChildrenBd_bore_1_addr = 9'($urandom);
      ta_boreChildrenBd_bore_1_addr_rd = 9'($urandom);
      ta_boreChildrenBd_bore_1_wdata = 86'({$urandom, $urandom, $urandom});
      ta_boreChildrenBd_bore_1_wmask = 2'($urandom);
      ta_boreChildrenBd_bore_1_re = 1'($urandom);
      ta_boreChildrenBd_bore_1_we = 1'($urandom);
      ta_boreChildrenBd_bore_1_ack = 1'($urandom);
      ta_boreChildrenBd_bore_1_selectedOH = 1'($urandom);
      ta_boreChildrenBd_bore_1_array = 6'($urandom);
      ta_sigFromSrams_bore_ram_hold = 1'($urandom);
      ta_sigFromSrams_bore_ram_bypass = 1'($urandom);
      ta_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      ta_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      ta_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      ta_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      ta_sigFromSrams_bore_cgen = 1'($urandom);
      ta_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      ta_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      ta_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      ta_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      ta_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      ta_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      ta_sigFromSrams_bore_1_cgen = 1'($urandom);
      ta_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_ta
        ta_io_read_bits_idx = 8'($urandom_range(0, 15));
        ta_io_write_bits_idx = 8'($urandom_range(0, 15));
        ta_io_write_valid = ($urandom_range(0, 2) == 0);
        if (ta_mode < 12) begin
          ta_boreChildrenBd_bore_addr = '0;
          ta_boreChildrenBd_bore_addr_rd = '0;
          ta_boreChildrenBd_bore_wdata = '0;
          ta_boreChildrenBd_bore_wmask = '0;
          ta_boreChildrenBd_bore_re = '0;
          ta_boreChildrenBd_bore_we = '0;
          ta_boreChildrenBd_bore_ack = '0;
          ta_boreChildrenBd_bore_selectedOH = '0;
          ta_boreChildrenBd_bore_array = '0;
          ta_boreChildrenBd_bore_1_addr = '0;
          ta_boreChildrenBd_bore_1_addr_rd = '0;
          ta_boreChildrenBd_bore_1_wdata = '0;
          ta_boreChildrenBd_bore_1_wmask = '0;
          ta_boreChildrenBd_bore_1_re = '0;
          ta_boreChildrenBd_bore_1_we = '0;
          ta_boreChildrenBd_bore_1_ack = '0;
          ta_boreChildrenBd_bore_1_selectedOH = '0;
          ta_boreChildrenBd_bore_1_array = '0;
          ta_sigFromSrams_bore_ram_hold = '0;
          ta_sigFromSrams_bore_ram_bypass = '0;
          ta_sigFromSrams_bore_ram_bp_clken = '0;
          ta_sigFromSrams_bore_ram_aux_clk = '0;
          ta_sigFromSrams_bore_ram_aux_ckbp = '0;
          ta_sigFromSrams_bore_ram_mcp_hold = '0;
          ta_sigFromSrams_bore_cgen = '0;
          ta_sigFromSrams_bore_1_ram_hold = '0;
          ta_sigFromSrams_bore_1_ram_bypass = '0;
          ta_sigFromSrams_bore_1_ram_bp_clken = '0;
          ta_sigFromSrams_bore_1_ram_aux_clk = '0;
          ta_sigFromSrams_bore_1_ram_aux_ckbp = '0;
          ta_sigFromSrams_bore_1_ram_mcp_hold = '0;
          ta_sigFromSrams_bore_1_cgen = '0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && tsb_armed_at >= 0 && cyc >= tsb_armed_at) begin
        checks++;
        if (tsb_g_io_read_ready !== tsb_i_io_read_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TagSRAMBank.io_read_ready g=%h i=%h", cyc, tsb_g_io_read_ready, tsb_i_io_read_ready);
        end
        tsb_s1_io_read_ready |= tsb_g_io_read_ready;
        tsb_s0_io_read_ready |= ~tsb_g_io_read_ready;
        checks++;
        if (tsb_g_io_resp_0 !== tsb_i_io_resp_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TagSRAMBank.io_resp_0 g=%h i=%h", cyc, tsb_g_io_resp_0, tsb_i_io_resp_0);
        end
        tsb_s1_io_resp_0 |= tsb_g_io_resp_0;
        tsb_s0_io_resp_0 |= ~tsb_g_io_resp_0;
        checks++;
        if (tsb_g_io_resp_1 !== tsb_i_io_resp_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TagSRAMBank.io_resp_1 g=%h i=%h", cyc, tsb_g_io_resp_1, tsb_i_io_resp_1);
        end
        tsb_s1_io_resp_1 |= tsb_g_io_resp_1;
        tsb_s0_io_resp_1 |= ~tsb_g_io_resp_1;
        checks++;
        if (tsb_g_boreChildrenBd_bore_rdata !== tsb_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TagSRAMBank.boreChildrenBd_bore_rdata g=%h i=%h", cyc, tsb_g_boreChildrenBd_bore_rdata, tsb_i_boreChildrenBd_bore_rdata);
        end
        tsb_s1_boreChildrenBd_bore_rdata |= tsb_g_boreChildrenBd_bore_rdata;
        tsb_s0_boreChildrenBd_bore_rdata |= ~tsb_g_boreChildrenBd_bore_rdata;
        if (!tsb_u_gold.rst_cnt[8]) tsb_cov_sweep++;
        if (tsb_io_read_valid && tsb_g_io_read_ready) tsb_cov_read_fire++;
        if (tsb_io_read_valid && !tsb_g_io_read_ready) tsb_cov_read_blocked++;
        if (tsb_io_write_valid && tsb_io_write_bits_way_en == 2'b01) tsb_cov_write_way0++;
      end
      if (tsb_u_gold.rst_cnt[8]) tsb_armed[0] = 1'b1;
      if (tsb_io_read_valid && tsb_g_io_read_ready) tsb_armed[1] = 1'b1;
      if (tsb_armed_at < 0 && (&tsb_armed)) tsb_armed_at = cyc + 1 + 2;
      if (cyc >= RESET_CYC + 0 && ta_armed_at >= 0 && cyc >= ta_armed_at) begin
        checks++;
        if (ta_g_io_read_ready !== ta_i_io_read_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TagArray.io_read_ready g=%h i=%h", cyc, ta_g_io_read_ready, ta_i_io_read_ready);
        end
        ta_s1_io_read_ready |= ta_g_io_read_ready;
        ta_s0_io_read_ready |= ~ta_g_io_read_ready;
        checks++;
        if (ta_g_io_resp_0 !== ta_i_io_resp_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TagArray.io_resp_0 g=%h i=%h", cyc, ta_g_io_resp_0, ta_i_io_resp_0);
        end
        ta_s1_io_resp_0 |= ta_g_io_resp_0;
        ta_s0_io_resp_0 |= ~ta_g_io_resp_0;
        checks++;
        if (ta_g_io_resp_1 !== ta_i_io_resp_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TagArray.io_resp_1 g=%h i=%h", cyc, ta_g_io_resp_1, ta_i_io_resp_1);
        end
        ta_s1_io_resp_1 |= ta_g_io_resp_1;
        ta_s0_io_resp_1 |= ~ta_g_io_resp_1;
        checks++;
        if (ta_g_io_resp_2 !== ta_i_io_resp_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TagArray.io_resp_2 g=%h i=%h", cyc, ta_g_io_resp_2, ta_i_io_resp_2);
        end
        ta_s1_io_resp_2 |= ta_g_io_resp_2;
        ta_s0_io_resp_2 |= ~ta_g_io_resp_2;
        checks++;
        if (ta_g_io_resp_3 !== ta_i_io_resp_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TagArray.io_resp_3 g=%h i=%h", cyc, ta_g_io_resp_3, ta_i_io_resp_3);
        end
        ta_s1_io_resp_3 |= ta_g_io_resp_3;
        ta_s0_io_resp_3 |= ~ta_g_io_resp_3;
        checks++;
        if (ta_g_boreChildrenBd_bore_rdata !== ta_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TagArray.boreChildrenBd_bore_rdata g=%h i=%h", cyc, ta_g_boreChildrenBd_bore_rdata, ta_i_boreChildrenBd_bore_rdata);
        end
        ta_s1_boreChildrenBd_bore_rdata |= ta_g_boreChildrenBd_bore_rdata;
        ta_s0_boreChildrenBd_bore_rdata |= ~ta_g_boreChildrenBd_bore_rdata;
        checks++;
        if (ta_g_boreChildrenBd_bore_1_rdata !== ta_i_boreChildrenBd_bore_1_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TagArray.boreChildrenBd_bore_1_rdata g=%h i=%h", cyc, ta_g_boreChildrenBd_bore_1_rdata, ta_i_boreChildrenBd_bore_1_rdata);
        end
        ta_s1_boreChildrenBd_bore_1_rdata |= ta_g_boreChildrenBd_bore_1_rdata;
        ta_s0_boreChildrenBd_bore_1_rdata |= ~ta_g_boreChildrenBd_bore_1_rdata;
        if (ta_io_read_valid && ta_g_io_read_ready) ta_cov_read_fire++;
        if (ta_io_write_valid && ta_io_write_bits_way_en[3]) ta_cov_write_hi++;
      end
      if (ta_u_gold.tag_arrays_0.rst_cnt[8]) ta_armed[0] = 1'b1;
      if (ta_io_read_valid && ta_g_io_read_ready) ta_armed[1] = 1'b1;
      if (ta_armed_at < 0 && (&ta_armed)) ta_armed_at = cyc + 1 + 2;
    end

    // ---- 覆盖闸 ----
    if (!(tsb_s0_io_read_ready && tsb_s1_io_read_ready)) begin cov_fail++; $display("[COV] TagSRAMBank.io_read_ready 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[0] && tsb_s1_io_resp_0[0])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[0] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[1] && tsb_s1_io_resp_0[1])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[1] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[2] && tsb_s1_io_resp_0[2])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[2] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[3] && tsb_s1_io_resp_0[3])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[3] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[4] && tsb_s1_io_resp_0[4])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[4] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[5] && tsb_s1_io_resp_0[5])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[5] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[6] && tsb_s1_io_resp_0[6])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[6] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[7] && tsb_s1_io_resp_0[7])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[7] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[8] && tsb_s1_io_resp_0[8])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[8] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[9] && tsb_s1_io_resp_0[9])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[9] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[10] && tsb_s1_io_resp_0[10])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[10] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[11] && tsb_s1_io_resp_0[11])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[11] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[12] && tsb_s1_io_resp_0[12])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[12] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[13] && tsb_s1_io_resp_0[13])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[13] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[14] && tsb_s1_io_resp_0[14])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[14] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[15] && tsb_s1_io_resp_0[15])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[15] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[16] && tsb_s1_io_resp_0[16])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[16] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[17] && tsb_s1_io_resp_0[17])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[17] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[18] && tsb_s1_io_resp_0[18])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[18] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[19] && tsb_s1_io_resp_0[19])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[19] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[20] && tsb_s1_io_resp_0[20])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[20] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[21] && tsb_s1_io_resp_0[21])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[21] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[22] && tsb_s1_io_resp_0[22])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[22] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[23] && tsb_s1_io_resp_0[23])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[23] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[24] && tsb_s1_io_resp_0[24])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[24] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[25] && tsb_s1_io_resp_0[25])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[25] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[26] && tsb_s1_io_resp_0[26])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[26] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[27] && tsb_s1_io_resp_0[27])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[27] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[28] && tsb_s1_io_resp_0[28])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[28] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[29] && tsb_s1_io_resp_0[29])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[29] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[30] && tsb_s1_io_resp_0[30])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[30] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[31] && tsb_s1_io_resp_0[31])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[31] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[32] && tsb_s1_io_resp_0[32])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[32] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[33] && tsb_s1_io_resp_0[33])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[33] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[34] && tsb_s1_io_resp_0[34])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[34] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[35] && tsb_s1_io_resp_0[35])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[35] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[36] && tsb_s1_io_resp_0[36])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[36] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[37] && tsb_s1_io_resp_0[37])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[37] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[38] && tsb_s1_io_resp_0[38])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[38] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[39] && tsb_s1_io_resp_0[39])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[39] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[40] && tsb_s1_io_resp_0[40])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[40] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[41] && tsb_s1_io_resp_0[41])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[41] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_0[42] && tsb_s1_io_resp_0[42])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_0[42] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[0] && tsb_s1_io_resp_1[0])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[0] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[1] && tsb_s1_io_resp_1[1])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[1] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[2] && tsb_s1_io_resp_1[2])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[2] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[3] && tsb_s1_io_resp_1[3])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[3] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[4] && tsb_s1_io_resp_1[4])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[4] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[5] && tsb_s1_io_resp_1[5])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[5] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[6] && tsb_s1_io_resp_1[6])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[6] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[7] && tsb_s1_io_resp_1[7])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[7] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[8] && tsb_s1_io_resp_1[8])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[8] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[9] && tsb_s1_io_resp_1[9])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[9] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[10] && tsb_s1_io_resp_1[10])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[10] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[11] && tsb_s1_io_resp_1[11])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[11] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[12] && tsb_s1_io_resp_1[12])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[12] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[13] && tsb_s1_io_resp_1[13])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[13] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[14] && tsb_s1_io_resp_1[14])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[14] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[15] && tsb_s1_io_resp_1[15])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[15] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[16] && tsb_s1_io_resp_1[16])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[16] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[17] && tsb_s1_io_resp_1[17])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[17] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[18] && tsb_s1_io_resp_1[18])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[18] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[19] && tsb_s1_io_resp_1[19])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[19] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[20] && tsb_s1_io_resp_1[20])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[20] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[21] && tsb_s1_io_resp_1[21])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[21] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[22] && tsb_s1_io_resp_1[22])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[22] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[23] && tsb_s1_io_resp_1[23])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[23] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[24] && tsb_s1_io_resp_1[24])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[24] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[25] && tsb_s1_io_resp_1[25])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[25] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[26] && tsb_s1_io_resp_1[26])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[26] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[27] && tsb_s1_io_resp_1[27])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[27] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[28] && tsb_s1_io_resp_1[28])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[28] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[29] && tsb_s1_io_resp_1[29])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[29] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[30] && tsb_s1_io_resp_1[30])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[30] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[31] && tsb_s1_io_resp_1[31])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[31] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[32] && tsb_s1_io_resp_1[32])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[32] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[33] && tsb_s1_io_resp_1[33])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[33] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[34] && tsb_s1_io_resp_1[34])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[34] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[35] && tsb_s1_io_resp_1[35])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[35] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[36] && tsb_s1_io_resp_1[36])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[36] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[37] && tsb_s1_io_resp_1[37])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[37] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[38] && tsb_s1_io_resp_1[38])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[38] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[39] && tsb_s1_io_resp_1[39])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[39] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[40] && tsb_s1_io_resp_1[40])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[40] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[41] && tsb_s1_io_resp_1[41])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[41] 未见过 0 和 1"); end
    if (!(tsb_s0_io_resp_1[42] && tsb_s1_io_resp_1[42])) begin cov_fail++; $display("[COV] TagSRAMBank.io_resp_1[42] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[0] && tsb_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[1] && tsb_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[2] && tsb_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[3] && tsb_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[4] && tsb_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[5] && tsb_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[6] && tsb_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[7] && tsb_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[8] && tsb_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[9] && tsb_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[10] && tsb_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[11] && tsb_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[12] && tsb_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[13] && tsb_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[14] && tsb_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[15] && tsb_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[16] && tsb_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[17] && tsb_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[18] && tsb_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[19] && tsb_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[20] && tsb_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[21] && tsb_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[22] && tsb_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[23] && tsb_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[24] && tsb_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[25] && tsb_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[26] && tsb_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[27] && tsb_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[28] && tsb_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[29] && tsb_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[30] && tsb_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[31] && tsb_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[32] && tsb_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[33] && tsb_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[34] && tsb_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[35] && tsb_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[36] && tsb_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[37] && tsb_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[38] && tsb_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[39] && tsb_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[40] && tsb_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[41] && tsb_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[42] && tsb_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[43] && tsb_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[44] && tsb_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[45] && tsb_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[46] && tsb_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[47] && tsb_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[48] && tsb_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[49] && tsb_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[50] && tsb_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[51] && tsb_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[52] && tsb_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[53] && tsb_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[54] && tsb_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[55] && tsb_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[56] && tsb_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[57] && tsb_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[58] && tsb_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[59] && tsb_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[60] && tsb_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[61] && tsb_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[62] && tsb_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[63] && tsb_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[64] && tsb_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[65] && tsb_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[66] && tsb_s1_boreChildrenBd_bore_rdata[66])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[66] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[67] && tsb_s1_boreChildrenBd_bore_rdata[67])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[67] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[68] && tsb_s1_boreChildrenBd_bore_rdata[68])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[68] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[69] && tsb_s1_boreChildrenBd_bore_rdata[69])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[69] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[70] && tsb_s1_boreChildrenBd_bore_rdata[70])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[70] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[71] && tsb_s1_boreChildrenBd_bore_rdata[71])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[71] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[72] && tsb_s1_boreChildrenBd_bore_rdata[72])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[72] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[73] && tsb_s1_boreChildrenBd_bore_rdata[73])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[73] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[74] && tsb_s1_boreChildrenBd_bore_rdata[74])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[74] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[75] && tsb_s1_boreChildrenBd_bore_rdata[75])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[75] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[76] && tsb_s1_boreChildrenBd_bore_rdata[76])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[76] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[77] && tsb_s1_boreChildrenBd_bore_rdata[77])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[77] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[78] && tsb_s1_boreChildrenBd_bore_rdata[78])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[78] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[79] && tsb_s1_boreChildrenBd_bore_rdata[79])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[79] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[80] && tsb_s1_boreChildrenBd_bore_rdata[80])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[80] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[81] && tsb_s1_boreChildrenBd_bore_rdata[81])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[81] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[82] && tsb_s1_boreChildrenBd_bore_rdata[82])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[82] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[83] && tsb_s1_boreChildrenBd_bore_rdata[83])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[83] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[84] && tsb_s1_boreChildrenBd_bore_rdata[84])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[84] 未见过 0 和 1"); end
    if (!(tsb_s0_boreChildrenBd_bore_rdata[85] && tsb_s1_boreChildrenBd_bore_rdata[85])) begin cov_fail++; $display("[COV] TagSRAMBank.boreChildrenBd_bore_rdata[85] 未见过 0 和 1"); end
    $display("[ARM] TagSRAMBank armed_at=%0d", tsb_armed_at);
    if (tsb_armed_at < 0) begin cov_fail++; $display("[ARM] TagSRAMBank 从未 arm"); end
    $display("[COV] TagSRAMBank.sweep = %0d", tsb_cov_sweep);
    if (tsb_cov_sweep < 200) begin cov_fail++; $display("[COV] TagSRAMBank.sweep < 200"); end
    $display("[COV] TagSRAMBank.read_fire = %0d", tsb_cov_read_fire);
    if (tsb_cov_read_fire < 200) begin cov_fail++; $display("[COV] TagSRAMBank.read_fire < 200"); end
    $display("[COV] TagSRAMBank.read_blocked = %0d", tsb_cov_read_blocked);
    if (tsb_cov_read_blocked < 200) begin cov_fail++; $display("[COV] TagSRAMBank.read_blocked < 200"); end
    $display("[COV] TagSRAMBank.write_way0 = %0d", tsb_cov_write_way0);
    if (tsb_cov_write_way0 < 200) begin cov_fail++; $display("[COV] TagSRAMBank.write_way0 < 200"); end
    if (!(ta_s0_io_read_ready && ta_s1_io_read_ready)) begin cov_fail++; $display("[COV] TagArray.io_read_ready 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[0] && ta_s1_io_resp_0[0])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[0] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[1] && ta_s1_io_resp_0[1])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[1] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[2] && ta_s1_io_resp_0[2])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[2] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[3] && ta_s1_io_resp_0[3])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[3] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[4] && ta_s1_io_resp_0[4])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[4] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[5] && ta_s1_io_resp_0[5])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[5] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[6] && ta_s1_io_resp_0[6])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[6] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[7] && ta_s1_io_resp_0[7])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[7] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[8] && ta_s1_io_resp_0[8])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[8] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[9] && ta_s1_io_resp_0[9])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[9] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[10] && ta_s1_io_resp_0[10])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[10] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[11] && ta_s1_io_resp_0[11])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[11] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[12] && ta_s1_io_resp_0[12])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[12] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[13] && ta_s1_io_resp_0[13])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[13] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[14] && ta_s1_io_resp_0[14])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[14] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[15] && ta_s1_io_resp_0[15])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[15] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[16] && ta_s1_io_resp_0[16])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[16] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[17] && ta_s1_io_resp_0[17])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[17] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[18] && ta_s1_io_resp_0[18])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[18] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[19] && ta_s1_io_resp_0[19])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[19] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[20] && ta_s1_io_resp_0[20])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[20] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[21] && ta_s1_io_resp_0[21])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[21] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[22] && ta_s1_io_resp_0[22])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[22] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[23] && ta_s1_io_resp_0[23])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[23] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[24] && ta_s1_io_resp_0[24])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[24] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[25] && ta_s1_io_resp_0[25])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[25] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[26] && ta_s1_io_resp_0[26])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[26] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[27] && ta_s1_io_resp_0[27])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[27] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[28] && ta_s1_io_resp_0[28])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[28] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[29] && ta_s1_io_resp_0[29])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[29] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[30] && ta_s1_io_resp_0[30])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[30] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[31] && ta_s1_io_resp_0[31])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[31] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[32] && ta_s1_io_resp_0[32])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[32] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[33] && ta_s1_io_resp_0[33])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[33] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[34] && ta_s1_io_resp_0[34])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[34] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[35] && ta_s1_io_resp_0[35])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[35] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[36] && ta_s1_io_resp_0[36])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[36] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[37] && ta_s1_io_resp_0[37])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[37] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[38] && ta_s1_io_resp_0[38])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[38] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[39] && ta_s1_io_resp_0[39])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[39] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[40] && ta_s1_io_resp_0[40])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[40] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[41] && ta_s1_io_resp_0[41])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[41] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_0[42] && ta_s1_io_resp_0[42])) begin cov_fail++; $display("[COV] TagArray.io_resp_0[42] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[0] && ta_s1_io_resp_1[0])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[0] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[1] && ta_s1_io_resp_1[1])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[1] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[2] && ta_s1_io_resp_1[2])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[2] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[3] && ta_s1_io_resp_1[3])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[3] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[4] && ta_s1_io_resp_1[4])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[4] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[5] && ta_s1_io_resp_1[5])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[5] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[6] && ta_s1_io_resp_1[6])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[6] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[7] && ta_s1_io_resp_1[7])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[7] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[8] && ta_s1_io_resp_1[8])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[8] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[9] && ta_s1_io_resp_1[9])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[9] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[10] && ta_s1_io_resp_1[10])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[10] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[11] && ta_s1_io_resp_1[11])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[11] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[12] && ta_s1_io_resp_1[12])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[12] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[13] && ta_s1_io_resp_1[13])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[13] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[14] && ta_s1_io_resp_1[14])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[14] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[15] && ta_s1_io_resp_1[15])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[15] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[16] && ta_s1_io_resp_1[16])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[16] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[17] && ta_s1_io_resp_1[17])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[17] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[18] && ta_s1_io_resp_1[18])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[18] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[19] && ta_s1_io_resp_1[19])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[19] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[20] && ta_s1_io_resp_1[20])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[20] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[21] && ta_s1_io_resp_1[21])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[21] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[22] && ta_s1_io_resp_1[22])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[22] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[23] && ta_s1_io_resp_1[23])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[23] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[24] && ta_s1_io_resp_1[24])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[24] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[25] && ta_s1_io_resp_1[25])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[25] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[26] && ta_s1_io_resp_1[26])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[26] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[27] && ta_s1_io_resp_1[27])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[27] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[28] && ta_s1_io_resp_1[28])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[28] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[29] && ta_s1_io_resp_1[29])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[29] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[30] && ta_s1_io_resp_1[30])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[30] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[31] && ta_s1_io_resp_1[31])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[31] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[32] && ta_s1_io_resp_1[32])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[32] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[33] && ta_s1_io_resp_1[33])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[33] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[34] && ta_s1_io_resp_1[34])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[34] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[35] && ta_s1_io_resp_1[35])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[35] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[36] && ta_s1_io_resp_1[36])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[36] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[37] && ta_s1_io_resp_1[37])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[37] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[38] && ta_s1_io_resp_1[38])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[38] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[39] && ta_s1_io_resp_1[39])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[39] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[40] && ta_s1_io_resp_1[40])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[40] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[41] && ta_s1_io_resp_1[41])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[41] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_1[42] && ta_s1_io_resp_1[42])) begin cov_fail++; $display("[COV] TagArray.io_resp_1[42] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[0] && ta_s1_io_resp_2[0])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[0] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[1] && ta_s1_io_resp_2[1])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[1] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[2] && ta_s1_io_resp_2[2])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[2] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[3] && ta_s1_io_resp_2[3])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[3] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[4] && ta_s1_io_resp_2[4])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[4] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[5] && ta_s1_io_resp_2[5])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[5] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[6] && ta_s1_io_resp_2[6])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[6] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[7] && ta_s1_io_resp_2[7])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[7] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[8] && ta_s1_io_resp_2[8])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[8] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[9] && ta_s1_io_resp_2[9])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[9] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[10] && ta_s1_io_resp_2[10])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[10] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[11] && ta_s1_io_resp_2[11])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[11] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[12] && ta_s1_io_resp_2[12])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[12] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[13] && ta_s1_io_resp_2[13])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[13] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[14] && ta_s1_io_resp_2[14])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[14] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[15] && ta_s1_io_resp_2[15])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[15] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[16] && ta_s1_io_resp_2[16])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[16] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[17] && ta_s1_io_resp_2[17])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[17] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[18] && ta_s1_io_resp_2[18])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[18] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[19] && ta_s1_io_resp_2[19])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[19] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[20] && ta_s1_io_resp_2[20])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[20] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[21] && ta_s1_io_resp_2[21])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[21] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[22] && ta_s1_io_resp_2[22])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[22] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[23] && ta_s1_io_resp_2[23])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[23] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[24] && ta_s1_io_resp_2[24])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[24] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[25] && ta_s1_io_resp_2[25])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[25] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[26] && ta_s1_io_resp_2[26])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[26] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[27] && ta_s1_io_resp_2[27])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[27] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[28] && ta_s1_io_resp_2[28])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[28] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[29] && ta_s1_io_resp_2[29])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[29] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[30] && ta_s1_io_resp_2[30])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[30] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[31] && ta_s1_io_resp_2[31])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[31] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[32] && ta_s1_io_resp_2[32])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[32] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[33] && ta_s1_io_resp_2[33])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[33] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[34] && ta_s1_io_resp_2[34])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[34] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[35] && ta_s1_io_resp_2[35])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[35] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[36] && ta_s1_io_resp_2[36])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[36] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[37] && ta_s1_io_resp_2[37])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[37] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[38] && ta_s1_io_resp_2[38])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[38] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[39] && ta_s1_io_resp_2[39])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[39] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[40] && ta_s1_io_resp_2[40])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[40] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[41] && ta_s1_io_resp_2[41])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[41] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_2[42] && ta_s1_io_resp_2[42])) begin cov_fail++; $display("[COV] TagArray.io_resp_2[42] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[0] && ta_s1_io_resp_3[0])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[0] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[1] && ta_s1_io_resp_3[1])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[1] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[2] && ta_s1_io_resp_3[2])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[2] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[3] && ta_s1_io_resp_3[3])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[3] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[4] && ta_s1_io_resp_3[4])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[4] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[5] && ta_s1_io_resp_3[5])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[5] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[6] && ta_s1_io_resp_3[6])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[6] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[7] && ta_s1_io_resp_3[7])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[7] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[8] && ta_s1_io_resp_3[8])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[8] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[9] && ta_s1_io_resp_3[9])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[9] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[10] && ta_s1_io_resp_3[10])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[10] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[11] && ta_s1_io_resp_3[11])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[11] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[12] && ta_s1_io_resp_3[12])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[12] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[13] && ta_s1_io_resp_3[13])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[13] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[14] && ta_s1_io_resp_3[14])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[14] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[15] && ta_s1_io_resp_3[15])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[15] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[16] && ta_s1_io_resp_3[16])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[16] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[17] && ta_s1_io_resp_3[17])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[17] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[18] && ta_s1_io_resp_3[18])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[18] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[19] && ta_s1_io_resp_3[19])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[19] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[20] && ta_s1_io_resp_3[20])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[20] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[21] && ta_s1_io_resp_3[21])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[21] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[22] && ta_s1_io_resp_3[22])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[22] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[23] && ta_s1_io_resp_3[23])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[23] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[24] && ta_s1_io_resp_3[24])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[24] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[25] && ta_s1_io_resp_3[25])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[25] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[26] && ta_s1_io_resp_3[26])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[26] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[27] && ta_s1_io_resp_3[27])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[27] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[28] && ta_s1_io_resp_3[28])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[28] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[29] && ta_s1_io_resp_3[29])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[29] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[30] && ta_s1_io_resp_3[30])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[30] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[31] && ta_s1_io_resp_3[31])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[31] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[32] && ta_s1_io_resp_3[32])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[32] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[33] && ta_s1_io_resp_3[33])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[33] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[34] && ta_s1_io_resp_3[34])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[34] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[35] && ta_s1_io_resp_3[35])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[35] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[36] && ta_s1_io_resp_3[36])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[36] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[37] && ta_s1_io_resp_3[37])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[37] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[38] && ta_s1_io_resp_3[38])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[38] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[39] && ta_s1_io_resp_3[39])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[39] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[40] && ta_s1_io_resp_3[40])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[40] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[41] && ta_s1_io_resp_3[41])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[41] 未见过 0 和 1"); end
    if (!(ta_s0_io_resp_3[42] && ta_s1_io_resp_3[42])) begin cov_fail++; $display("[COV] TagArray.io_resp_3[42] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[0] && ta_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[1] && ta_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[2] && ta_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[3] && ta_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[4] && ta_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[5] && ta_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[6] && ta_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[7] && ta_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[8] && ta_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[9] && ta_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[10] && ta_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[11] && ta_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[12] && ta_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[13] && ta_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[14] && ta_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[15] && ta_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[16] && ta_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[17] && ta_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[18] && ta_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[19] && ta_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[20] && ta_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[21] && ta_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[22] && ta_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[23] && ta_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[24] && ta_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[25] && ta_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[26] && ta_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[27] && ta_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[28] && ta_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[29] && ta_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[30] && ta_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[31] && ta_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[32] && ta_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[33] && ta_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[34] && ta_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[35] && ta_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[36] && ta_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[37] && ta_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[38] && ta_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[39] && ta_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[40] && ta_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[41] && ta_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[42] && ta_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[43] && ta_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[44] && ta_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[45] && ta_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[46] && ta_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[47] && ta_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[48] && ta_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[49] && ta_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[50] && ta_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[51] && ta_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[52] && ta_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[53] && ta_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[54] && ta_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[55] && ta_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[56] && ta_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[57] && ta_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[58] && ta_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[59] && ta_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[60] && ta_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[61] && ta_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[62] && ta_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[63] && ta_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[64] && ta_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[65] && ta_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[66] && ta_s1_boreChildrenBd_bore_rdata[66])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[66] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[67] && ta_s1_boreChildrenBd_bore_rdata[67])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[67] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[68] && ta_s1_boreChildrenBd_bore_rdata[68])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[68] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[69] && ta_s1_boreChildrenBd_bore_rdata[69])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[69] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[70] && ta_s1_boreChildrenBd_bore_rdata[70])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[70] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[71] && ta_s1_boreChildrenBd_bore_rdata[71])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[71] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[72] && ta_s1_boreChildrenBd_bore_rdata[72])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[72] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[73] && ta_s1_boreChildrenBd_bore_rdata[73])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[73] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[74] && ta_s1_boreChildrenBd_bore_rdata[74])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[74] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[75] && ta_s1_boreChildrenBd_bore_rdata[75])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[75] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[76] && ta_s1_boreChildrenBd_bore_rdata[76])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[76] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[77] && ta_s1_boreChildrenBd_bore_rdata[77])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[77] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[78] && ta_s1_boreChildrenBd_bore_rdata[78])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[78] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[79] && ta_s1_boreChildrenBd_bore_rdata[79])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[79] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[80] && ta_s1_boreChildrenBd_bore_rdata[80])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[80] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[81] && ta_s1_boreChildrenBd_bore_rdata[81])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[81] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[82] && ta_s1_boreChildrenBd_bore_rdata[82])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[82] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[83] && ta_s1_boreChildrenBd_bore_rdata[83])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[83] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[84] && ta_s1_boreChildrenBd_bore_rdata[84])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[84] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_rdata[85] && ta_s1_boreChildrenBd_bore_rdata[85])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_rdata[85] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[0] && ta_s1_boreChildrenBd_bore_1_rdata[0])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[0] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[1] && ta_s1_boreChildrenBd_bore_1_rdata[1])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[1] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[2] && ta_s1_boreChildrenBd_bore_1_rdata[2])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[2] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[3] && ta_s1_boreChildrenBd_bore_1_rdata[3])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[3] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[4] && ta_s1_boreChildrenBd_bore_1_rdata[4])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[4] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[5] && ta_s1_boreChildrenBd_bore_1_rdata[5])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[5] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[6] && ta_s1_boreChildrenBd_bore_1_rdata[6])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[6] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[7] && ta_s1_boreChildrenBd_bore_1_rdata[7])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[7] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[8] && ta_s1_boreChildrenBd_bore_1_rdata[8])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[8] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[9] && ta_s1_boreChildrenBd_bore_1_rdata[9])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[9] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[10] && ta_s1_boreChildrenBd_bore_1_rdata[10])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[10] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[11] && ta_s1_boreChildrenBd_bore_1_rdata[11])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[11] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[12] && ta_s1_boreChildrenBd_bore_1_rdata[12])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[12] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[13] && ta_s1_boreChildrenBd_bore_1_rdata[13])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[13] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[14] && ta_s1_boreChildrenBd_bore_1_rdata[14])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[14] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[15] && ta_s1_boreChildrenBd_bore_1_rdata[15])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[15] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[16] && ta_s1_boreChildrenBd_bore_1_rdata[16])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[16] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[17] && ta_s1_boreChildrenBd_bore_1_rdata[17])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[17] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[18] && ta_s1_boreChildrenBd_bore_1_rdata[18])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[18] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[19] && ta_s1_boreChildrenBd_bore_1_rdata[19])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[19] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[20] && ta_s1_boreChildrenBd_bore_1_rdata[20])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[20] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[21] && ta_s1_boreChildrenBd_bore_1_rdata[21])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[21] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[22] && ta_s1_boreChildrenBd_bore_1_rdata[22])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[22] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[23] && ta_s1_boreChildrenBd_bore_1_rdata[23])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[23] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[24] && ta_s1_boreChildrenBd_bore_1_rdata[24])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[24] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[25] && ta_s1_boreChildrenBd_bore_1_rdata[25])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[25] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[26] && ta_s1_boreChildrenBd_bore_1_rdata[26])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[26] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[27] && ta_s1_boreChildrenBd_bore_1_rdata[27])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[27] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[28] && ta_s1_boreChildrenBd_bore_1_rdata[28])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[28] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[29] && ta_s1_boreChildrenBd_bore_1_rdata[29])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[29] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[30] && ta_s1_boreChildrenBd_bore_1_rdata[30])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[30] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[31] && ta_s1_boreChildrenBd_bore_1_rdata[31])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[31] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[32] && ta_s1_boreChildrenBd_bore_1_rdata[32])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[32] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[33] && ta_s1_boreChildrenBd_bore_1_rdata[33])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[33] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[34] && ta_s1_boreChildrenBd_bore_1_rdata[34])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[34] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[35] && ta_s1_boreChildrenBd_bore_1_rdata[35])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[35] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[36] && ta_s1_boreChildrenBd_bore_1_rdata[36])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[36] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[37] && ta_s1_boreChildrenBd_bore_1_rdata[37])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[37] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[38] && ta_s1_boreChildrenBd_bore_1_rdata[38])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[38] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[39] && ta_s1_boreChildrenBd_bore_1_rdata[39])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[39] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[40] && ta_s1_boreChildrenBd_bore_1_rdata[40])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[40] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[41] && ta_s1_boreChildrenBd_bore_1_rdata[41])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[41] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[42] && ta_s1_boreChildrenBd_bore_1_rdata[42])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[42] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[43] && ta_s1_boreChildrenBd_bore_1_rdata[43])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[43] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[44] && ta_s1_boreChildrenBd_bore_1_rdata[44])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[44] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[45] && ta_s1_boreChildrenBd_bore_1_rdata[45])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[45] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[46] && ta_s1_boreChildrenBd_bore_1_rdata[46])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[46] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[47] && ta_s1_boreChildrenBd_bore_1_rdata[47])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[47] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[48] && ta_s1_boreChildrenBd_bore_1_rdata[48])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[48] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[49] && ta_s1_boreChildrenBd_bore_1_rdata[49])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[49] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[50] && ta_s1_boreChildrenBd_bore_1_rdata[50])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[50] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[51] && ta_s1_boreChildrenBd_bore_1_rdata[51])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[51] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[52] && ta_s1_boreChildrenBd_bore_1_rdata[52])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[52] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[53] && ta_s1_boreChildrenBd_bore_1_rdata[53])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[53] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[54] && ta_s1_boreChildrenBd_bore_1_rdata[54])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[54] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[55] && ta_s1_boreChildrenBd_bore_1_rdata[55])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[55] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[56] && ta_s1_boreChildrenBd_bore_1_rdata[56])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[56] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[57] && ta_s1_boreChildrenBd_bore_1_rdata[57])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[57] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[58] && ta_s1_boreChildrenBd_bore_1_rdata[58])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[58] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[59] && ta_s1_boreChildrenBd_bore_1_rdata[59])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[59] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[60] && ta_s1_boreChildrenBd_bore_1_rdata[60])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[60] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[61] && ta_s1_boreChildrenBd_bore_1_rdata[61])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[61] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[62] && ta_s1_boreChildrenBd_bore_1_rdata[62])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[62] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[63] && ta_s1_boreChildrenBd_bore_1_rdata[63])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[63] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[64] && ta_s1_boreChildrenBd_bore_1_rdata[64])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[64] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[65] && ta_s1_boreChildrenBd_bore_1_rdata[65])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[65] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[66] && ta_s1_boreChildrenBd_bore_1_rdata[66])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[66] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[67] && ta_s1_boreChildrenBd_bore_1_rdata[67])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[67] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[68] && ta_s1_boreChildrenBd_bore_1_rdata[68])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[68] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[69] && ta_s1_boreChildrenBd_bore_1_rdata[69])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[69] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[70] && ta_s1_boreChildrenBd_bore_1_rdata[70])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[70] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[71] && ta_s1_boreChildrenBd_bore_1_rdata[71])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[71] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[72] && ta_s1_boreChildrenBd_bore_1_rdata[72])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[72] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[73] && ta_s1_boreChildrenBd_bore_1_rdata[73])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[73] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[74] && ta_s1_boreChildrenBd_bore_1_rdata[74])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[74] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[75] && ta_s1_boreChildrenBd_bore_1_rdata[75])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[75] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[76] && ta_s1_boreChildrenBd_bore_1_rdata[76])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[76] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[77] && ta_s1_boreChildrenBd_bore_1_rdata[77])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[77] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[78] && ta_s1_boreChildrenBd_bore_1_rdata[78])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[78] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[79] && ta_s1_boreChildrenBd_bore_1_rdata[79])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[79] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[80] && ta_s1_boreChildrenBd_bore_1_rdata[80])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[80] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[81] && ta_s1_boreChildrenBd_bore_1_rdata[81])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[81] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[82] && ta_s1_boreChildrenBd_bore_1_rdata[82])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[82] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[83] && ta_s1_boreChildrenBd_bore_1_rdata[83])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[83] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[84] && ta_s1_boreChildrenBd_bore_1_rdata[84])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[84] 未见过 0 和 1"); end
    if (!(ta_s0_boreChildrenBd_bore_1_rdata[85] && ta_s1_boreChildrenBd_bore_1_rdata[85])) begin cov_fail++; $display("[COV] TagArray.boreChildrenBd_bore_1_rdata[85] 未见过 0 和 1"); end
    $display("[ARM] TagArray armed_at=%0d", ta_armed_at);
    if (ta_armed_at < 0) begin cov_fail++; $display("[ARM] TagArray 从未 arm"); end
    $display("[COV] TagArray.read_fire = %0d", ta_cov_read_fire);
    if (ta_cov_read_fire < 200) begin cov_fail++; $display("[COV] TagArray.read_fire < 200"); end
    $display("[COV] TagArray.write_hi = %0d", ta_cov_write_hi);
    if (ta_cov_write_hi < 200) begin cov_fail++; $display("[COV] TagArray.write_hi < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
