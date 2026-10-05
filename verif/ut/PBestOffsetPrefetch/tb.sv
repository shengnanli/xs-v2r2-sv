// 自动生成：verif/ut/PBestOffsetPrefetch/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// PBestOffsetPrefetch 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= PBestOffsetPrefetch =================
  int unsigned pb_mode = 0;
  logic [35:0] pb_page [8];            // 8 个物理页号（块地址 42 位 = {36 位页号, 6 位页内块号}）
  int unsigned pb_k = 0;
  int          pb_step = 1;
  initial for (int i = 0; i < 8; i++) pb_page[i] = 36'({$urandom, $urandom});
  function automatic logic [41:0] pb_blk();
    // 页内块号 = (k × step) mod 64 —— 同一步长的流；偶尔换步长、换页
    if ($urandom_range(0, 255) == 0) pb_step = $urandom_range(1, 9) * (($urandom_range(0, 1) != 0) ? 1 : -1);
    if ($urandom_range(0, 1023) == 0) pb_page[$urandom_range(0, 7)] = 36'({$urandom, $urandom});   // 偶尔换一页，高位也翻得到
    pb_k++;
    return {pb_page[$urandom_range(0, 7)], 6'(pb_k * pb_step)};
  endfunction
  logic pb_reset;
  logic pb_io_enable;
  logic [9:0] pb_io_pfCtrlOfDelayLatency;
  wire  pb_g_io_train_ready, pb_i_io_train_ready;
  logic pb_s0_io_train_ready = '0, pb_s1_io_train_ready = '0;
  logic pb_io_train_valid;
  logic [32:0] pb_io_train_bits_tag;
  logic [8:0] pb_io_train_bits_set;
  logic pb_io_train_bits_needT;
  logic [6:0] pb_io_train_bits_source;
  logic pb_io_req_ready;
  wire  pb_g_io_req_valid, pb_i_io_req_valid;
  logic pb_s0_io_req_valid = '0, pb_s1_io_req_valid = '0;
  wire  [32:0] pb_g_io_req_bits_tag, pb_i_io_req_bits_tag;
  logic [32:0] pb_s0_io_req_bits_tag = '0, pb_s1_io_req_bits_tag = '0;
  wire  [8:0] pb_g_io_req_bits_set, pb_i_io_req_bits_set;
  logic [8:0] pb_s0_io_req_bits_set = '0, pb_s1_io_req_bits_set = '0;
  wire  [43:0] pb_g_io_req_bits_vaddr, pb_i_io_req_bits_vaddr;
  logic [43:0] pb_s0_io_req_bits_vaddr = '0, pb_s1_io_req_bits_vaddr = '0;
  wire  pb_g_io_req_bits_needT, pb_i_io_req_bits_needT;
  logic pb_s0_io_req_bits_needT = '0, pb_s1_io_req_bits_needT = '0;
  wire  [6:0] pb_g_io_req_bits_source, pb_i_io_req_bits_source;
  logic [6:0] pb_s0_io_req_bits_source = '0, pb_s1_io_req_bits_source = '0;
  wire  pb_g_io_resp_ready, pb_i_io_resp_ready;
  logic pb_s0_io_resp_ready = '0, pb_s1_io_resp_ready = '0;
  logic pb_io_resp_valid;
  logic [8:0] pb_boreChildrenBd_bore_addr;
  logic [8:0] pb_boreChildrenBd_bore_addr_rd;
  logic [12:0] pb_boreChildrenBd_bore_wdata;
  logic pb_boreChildrenBd_bore_wmask;
  logic pb_boreChildrenBd_bore_re;
  logic pb_boreChildrenBd_bore_we;
  wire  [12:0] pb_g_boreChildrenBd_bore_rdata, pb_i_boreChildrenBd_bore_rdata;
  logic [12:0] pb_s0_boreChildrenBd_bore_rdata = '0, pb_s1_boreChildrenBd_bore_rdata = '0;
  logic pb_boreChildrenBd_bore_ack;
  logic pb_boreChildrenBd_bore_selectedOH;
  logic pb_boreChildrenBd_bore_array;
  logic pb_sigFromSrams_bore_ram_hold;
  logic pb_sigFromSrams_bore_ram_bypass;
  logic pb_sigFromSrams_bore_ram_bp_clken;
  logic pb_sigFromSrams_bore_ram_aux_clk;
  logic pb_sigFromSrams_bore_ram_aux_ckbp;
  logic pb_sigFromSrams_bore_ram_mcp_hold;
  logic pb_sigFromSrams_bore_cgen;
  int pb_cov_train_fire = 0;
  int pb_cov_req_fire = 0;
  int pb_cov_req_stall = 0;
  int pb_cov_train_blocked = 0;
  int pb_cov_resp_ready_low = 0;
  int pb_cov_bore_rdata_nz = 0;
  int pb_cov_reset_mid = 0;
  int pb_cov_cross_page_drop = 0;
  int pb_cov_disable_drop = 0;
  int pb_cov_enable_low_full = 0;
  logic [1:0] pb_armed = '0;
  int pb_armed_at = -1;
  PBestOffsetPrefetch pb_u_gold (
    .clock(clk),
    .reset(pb_reset),
    .io_enable(pb_io_enable),
    .io_pfCtrlOfDelayLatency(pb_io_pfCtrlOfDelayLatency),
    .io_train_ready(pb_g_io_train_ready),
    .io_train_valid(pb_io_train_valid),
    .io_train_bits_tag(pb_io_train_bits_tag),
    .io_train_bits_set(pb_io_train_bits_set),
    .io_train_bits_needT(pb_io_train_bits_needT),
    .io_train_bits_source(pb_io_train_bits_source),
    .io_req_ready(pb_io_req_ready),
    .io_req_valid(pb_g_io_req_valid),
    .io_req_bits_tag(pb_g_io_req_bits_tag),
    .io_req_bits_set(pb_g_io_req_bits_set),
    .io_req_bits_vaddr(pb_g_io_req_bits_vaddr),
    .io_req_bits_needT(pb_g_io_req_bits_needT),
    .io_req_bits_source(pb_g_io_req_bits_source),
    .io_resp_ready(pb_g_io_resp_ready),
    .io_resp_valid(pb_io_resp_valid),
    .boreChildrenBd_bore_addr(pb_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(pb_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(pb_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(pb_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(pb_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(pb_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(pb_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(pb_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(pb_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(pb_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(pb_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(pb_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(pb_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(pb_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(pb_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(pb_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(pb_sigFromSrams_bore_cgen)
  );
  PBestOffsetPrefetch_xs pb_u_impl (
    .clock(clk),
    .reset(pb_reset),
    .io_enable(pb_io_enable),
    .io_pfCtrlOfDelayLatency(pb_io_pfCtrlOfDelayLatency),
    .io_train_ready(pb_i_io_train_ready),
    .io_train_valid(pb_io_train_valid),
    .io_train_bits_tag(pb_io_train_bits_tag),
    .io_train_bits_set(pb_io_train_bits_set),
    .io_train_bits_needT(pb_io_train_bits_needT),
    .io_train_bits_source(pb_io_train_bits_source),
    .io_req_ready(pb_io_req_ready),
    .io_req_valid(pb_i_io_req_valid),
    .io_req_bits_tag(pb_i_io_req_bits_tag),
    .io_req_bits_set(pb_i_io_req_bits_set),
    .io_req_bits_vaddr(pb_i_io_req_bits_vaddr),
    .io_req_bits_needT(pb_i_io_req_bits_needT),
    .io_req_bits_source(pb_i_io_req_bits_source),
    .io_resp_ready(pb_i_io_resp_ready),
    .io_resp_valid(pb_io_resp_valid),
    .boreChildrenBd_bore_addr(pb_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(pb_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(pb_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(pb_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(pb_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(pb_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(pb_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(pb_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(pb_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(pb_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(pb_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(pb_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(pb_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(pb_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(pb_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(pb_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(pb_sigFromSrams_bore_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) pb_mode = $urandom_range(0, 15);
      pb_io_enable = 1'($urandom);
      pb_io_pfCtrlOfDelayLatency = 10'($urandom);
      pb_io_train_valid = 1'($urandom);
      pb_io_train_bits_tag = 33'({$urandom, $urandom});
      pb_io_train_bits_set = 9'($urandom);
      pb_io_train_bits_needT = 1'($urandom);
      pb_io_train_bits_source = 7'($urandom);
      pb_io_req_ready = 1'($urandom);
      pb_io_resp_valid = 1'($urandom);
      pb_boreChildrenBd_bore_addr = 9'($urandom);
      pb_boreChildrenBd_bore_addr_rd = 9'($urandom);
      pb_boreChildrenBd_bore_wdata = 13'($urandom);
      pb_boreChildrenBd_bore_wmask = 1'($urandom);
      pb_boreChildrenBd_bore_re = 1'($urandom);
      pb_boreChildrenBd_bore_we = 1'($urandom);
      pb_boreChildrenBd_bore_ack = 1'($urandom);
      pb_boreChildrenBd_bore_selectedOH = 1'($urandom);
      pb_boreChildrenBd_bore_array = 1'($urandom);
      pb_sigFromSrams_bore_ram_hold = 1'($urandom);
      pb_sigFromSrams_bore_ram_bypass = 1'($urandom);
      pb_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      pb_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      pb_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      pb_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      pb_sigFromSrams_bore_cgen = 1'($urandom);
      pb_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_pb
        pb_io_enable = ($urandom_range(0, 7) != 0);
        pb_io_pfCtrlOfDelayLatency = 10'($urandom_range(0, 15));
        pb_io_train_valid = ($urandom_range(0, 1) != 0);
        begin logic [41:0] a; a = pb_blk(); pb_io_train_bits_tag = a[41:9]; pb_io_train_bits_set = a[8:0]; end
        pb_io_req_ready = ($urandom_range(0, 3) != 0);
        if (pb_mode != 0) begin
          pb_boreChildrenBd_bore_re = '0;
          pb_boreChildrenBd_bore_we = '0;
          pb_boreChildrenBd_bore_ack = '0;
          pb_boreChildrenBd_bore_selectedOH = '0;
          pb_boreChildrenBd_bore_array = '0;
          pb_boreChildrenBd_bore_wmask = '0;
          pb_sigFromSrams_bore_ram_hold = '0;
          pb_sigFromSrams_bore_ram_bypass = '0;
          pb_sigFromSrams_bore_ram_bp_clken = '0;
          pb_sigFromSrams_bore_ram_aux_clk = '0;
          pb_sigFromSrams_bore_ram_aux_ckbp = '0;
          pb_sigFromSrams_bore_ram_mcp_hold = '0;
          pb_sigFromSrams_bore_cgen = '0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && pb_armed_at >= 0 && cyc >= pb_armed_at) begin
        checks++;
        if (pb_g_io_train_ready !== pb_i_io_train_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PBestOffsetPrefetch.io_train_ready g=%h i=%h", cyc, pb_g_io_train_ready, pb_i_io_train_ready);
        end
        pb_s1_io_train_ready |= pb_g_io_train_ready;
        pb_s0_io_train_ready |= ~pb_g_io_train_ready;
        checks++;
        if (pb_g_io_req_valid !== pb_i_io_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PBestOffsetPrefetch.io_req_valid g=%h i=%h", cyc, pb_g_io_req_valid, pb_i_io_req_valid);
        end
        pb_s1_io_req_valid |= pb_g_io_req_valid;
        pb_s0_io_req_valid |= ~pb_g_io_req_valid;
        checks++;
        if (pb_g_io_req_bits_tag !== pb_i_io_req_bits_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PBestOffsetPrefetch.io_req_bits_tag g=%h i=%h", cyc, pb_g_io_req_bits_tag, pb_i_io_req_bits_tag);
        end
        pb_s1_io_req_bits_tag |= pb_g_io_req_bits_tag;
        pb_s0_io_req_bits_tag |= ~pb_g_io_req_bits_tag;
        checks++;
        if (pb_g_io_req_bits_set !== pb_i_io_req_bits_set) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PBestOffsetPrefetch.io_req_bits_set g=%h i=%h", cyc, pb_g_io_req_bits_set, pb_i_io_req_bits_set);
        end
        pb_s1_io_req_bits_set |= pb_g_io_req_bits_set;
        pb_s0_io_req_bits_set |= ~pb_g_io_req_bits_set;
        checks++;
        if (pb_g_io_req_bits_vaddr !== pb_i_io_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PBestOffsetPrefetch.io_req_bits_vaddr g=%h i=%h", cyc, pb_g_io_req_bits_vaddr, pb_i_io_req_bits_vaddr);
        end
        pb_s1_io_req_bits_vaddr |= pb_g_io_req_bits_vaddr;
        pb_s0_io_req_bits_vaddr |= ~pb_g_io_req_bits_vaddr;
        checks++;
        if (pb_g_io_req_bits_needT !== pb_i_io_req_bits_needT) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PBestOffsetPrefetch.io_req_bits_needT g=%h i=%h", cyc, pb_g_io_req_bits_needT, pb_i_io_req_bits_needT);
        end
        pb_s1_io_req_bits_needT |= pb_g_io_req_bits_needT;
        pb_s0_io_req_bits_needT |= ~pb_g_io_req_bits_needT;
        checks++;
        if (pb_g_io_req_bits_source !== pb_i_io_req_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PBestOffsetPrefetch.io_req_bits_source g=%h i=%h", cyc, pb_g_io_req_bits_source, pb_i_io_req_bits_source);
        end
        pb_s1_io_req_bits_source |= pb_g_io_req_bits_source;
        pb_s0_io_req_bits_source |= ~pb_g_io_req_bits_source;
        checks++;
        if (pb_g_io_resp_ready !== pb_i_io_resp_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PBestOffsetPrefetch.io_resp_ready g=%h i=%h", cyc, pb_g_io_resp_ready, pb_i_io_resp_ready);
        end
        pb_s1_io_resp_ready |= pb_g_io_resp_ready;
        pb_s0_io_resp_ready |= ~pb_g_io_resp_ready;
        checks++;
        if (pb_g_boreChildrenBd_bore_rdata !== pb_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PBestOffsetPrefetch.boreChildrenBd_bore_rdata g=%h i=%h", cyc, pb_g_boreChildrenBd_bore_rdata, pb_i_boreChildrenBd_bore_rdata);
        end
        pb_s1_boreChildrenBd_bore_rdata |= pb_g_boreChildrenBd_bore_rdata;
        pb_s0_boreChildrenBd_bore_rdata |= ~pb_g_boreChildrenBd_bore_rdata;
        if (pb_io_train_valid && pb_g_io_train_ready) pb_cov_train_fire++;
        if (pb_g_io_req_valid && pb_io_req_ready) pb_cov_req_fire++;
        if (pb_g_io_req_valid && !pb_io_req_ready) pb_cov_req_stall++;
        if (pb_io_train_valid && !pb_g_io_train_ready) pb_cov_train_blocked++;
        if (!pb_g_io_resp_ready) pb_cov_resp_ready_low++;
        if (pb_g_boreChildrenBd_bore_rdata != 0) pb_cov_bore_rdata_nz++;
        if (pb_reset && cyc > 100) pb_cov_reset_mid++;
        if (pb_u_gold._GEN_0 && pb_u_gold.crossPage) pb_cov_cross_page_drop++;
        if (pb_u_gold._GEN_0 && pb_u_gold._scoreTable_io_prefetchDisable) pb_cov_disable_drop++;
        if (!pb_io_enable && pb_u_gold.req_valid) pb_cov_enable_low_full++;
      end
      if (pb_io_train_valid && pb_g_io_train_ready) pb_armed[0] = 1'b1;
      if (pb_u_gold.rrTable.rrTable.respReg) pb_armed[1] = 1'b1;
      if (pb_armed_at < 0 && (&pb_armed)) pb_armed_at = cyc + 1 + 1;
    end

    // ---- 覆盖闸 ----
    if (!(pb_s0_io_train_ready && pb_s1_io_train_ready)) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_train_ready 未见过 0 和 1"); end
    if (!(pb_s0_io_req_valid && pb_s1_io_req_valid)) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_valid 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[0] && pb_s1_io_req_bits_tag[0])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[0] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[1] && pb_s1_io_req_bits_tag[1])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[1] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[2] && pb_s1_io_req_bits_tag[2])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[2] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[3] && pb_s1_io_req_bits_tag[3])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[3] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[4] && pb_s1_io_req_bits_tag[4])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[4] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[5] && pb_s1_io_req_bits_tag[5])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[5] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[6] && pb_s1_io_req_bits_tag[6])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[6] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[7] && pb_s1_io_req_bits_tag[7])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[7] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[8] && pb_s1_io_req_bits_tag[8])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[8] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[9] && pb_s1_io_req_bits_tag[9])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[9] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[10] && pb_s1_io_req_bits_tag[10])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[10] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[11] && pb_s1_io_req_bits_tag[11])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[11] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[12] && pb_s1_io_req_bits_tag[12])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[12] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[13] && pb_s1_io_req_bits_tag[13])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[13] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[14] && pb_s1_io_req_bits_tag[14])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[14] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[15] && pb_s1_io_req_bits_tag[15])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[15] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[16] && pb_s1_io_req_bits_tag[16])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[16] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[17] && pb_s1_io_req_bits_tag[17])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[17] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[18] && pb_s1_io_req_bits_tag[18])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[18] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[19] && pb_s1_io_req_bits_tag[19])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[19] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[20] && pb_s1_io_req_bits_tag[20])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[20] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[21] && pb_s1_io_req_bits_tag[21])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[21] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[22] && pb_s1_io_req_bits_tag[22])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[22] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[23] && pb_s1_io_req_bits_tag[23])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[23] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[24] && pb_s1_io_req_bits_tag[24])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[24] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[25] && pb_s1_io_req_bits_tag[25])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[25] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[26] && pb_s1_io_req_bits_tag[26])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[26] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[27] && pb_s1_io_req_bits_tag[27])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[27] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[28] && pb_s1_io_req_bits_tag[28])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[28] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[29] && pb_s1_io_req_bits_tag[29])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[29] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[30] && pb_s1_io_req_bits_tag[30])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[30] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[31] && pb_s1_io_req_bits_tag[31])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[31] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_tag[32] && pb_s1_io_req_bits_tag[32])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_tag[32] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_set[0] && pb_s1_io_req_bits_set[0])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_set[0] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_set[1] && pb_s1_io_req_bits_set[1])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_set[1] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_set[2] && pb_s1_io_req_bits_set[2])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_set[2] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_set[3] && pb_s1_io_req_bits_set[3])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_set[3] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_set[4] && pb_s1_io_req_bits_set[4])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_set[4] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_set[5] && pb_s1_io_req_bits_set[5])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_set[5] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_set[6] && pb_s1_io_req_bits_set[6])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_set[6] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_set[7] && pb_s1_io_req_bits_set[7])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_set[7] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_set[8] && pb_s1_io_req_bits_set[8])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_set[8] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_needT && pb_s1_io_req_bits_needT)) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_needT 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_source[0] && pb_s1_io_req_bits_source[0])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_source[0] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_source[1] && pb_s1_io_req_bits_source[1])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_source[1] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_source[2] && pb_s1_io_req_bits_source[2])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_source[2] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_source[3] && pb_s1_io_req_bits_source[3])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_source[3] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_source[4] && pb_s1_io_req_bits_source[4])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_source[4] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_source[5] && pb_s1_io_req_bits_source[5])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_source[5] 未见过 0 和 1"); end
    if (!(pb_s0_io_req_bits_source[6] && pb_s1_io_req_bits_source[6])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_req_bits_source[6] 未见过 0 和 1"); end
    if (!(pb_s0_io_resp_ready && pb_s1_io_resp_ready)) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.io_resp_ready 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[0] && pb_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[1] && pb_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[2] && pb_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[3] && pb_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[4] && pb_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[5] && pb_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[6] && pb_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[7] && pb_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[8] && pb_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[9] && pb_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[10] && pb_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[11] && pb_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(pb_s0_boreChildrenBd_bore_rdata[12] && pb_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    $display("[ARM] PBestOffsetPrefetch armed_at=%0d", pb_armed_at);
    if (pb_armed_at < 0) begin cov_fail++; $display("[ARM] PBestOffsetPrefetch 从未 arm"); end
    $display("[COV] PBestOffsetPrefetch.train_fire = %0d", pb_cov_train_fire);
    if (pb_cov_train_fire < 5) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.train_fire < 5"); end
    $display("[COV] PBestOffsetPrefetch.req_fire = %0d", pb_cov_req_fire);
    if (pb_cov_req_fire < 5) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.req_fire < 5"); end
    $display("[COV] PBestOffsetPrefetch.req_stall = %0d", pb_cov_req_stall);
    if (pb_cov_req_stall < 5) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.req_stall < 5"); end
    $display("[COV] PBestOffsetPrefetch.train_blocked = %0d", pb_cov_train_blocked);
    if (pb_cov_train_blocked < 5) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.train_blocked < 5"); end
    $display("[COV] PBestOffsetPrefetch.resp_ready_low = %0d", pb_cov_resp_ready_low);
    if (pb_cov_resp_ready_low < 5) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.resp_ready_low < 5"); end
    $display("[COV] PBestOffsetPrefetch.bore_rdata_nz = %0d", pb_cov_bore_rdata_nz);
    if (pb_cov_bore_rdata_nz < 5) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.bore_rdata_nz < 5"); end
    $display("[COV] PBestOffsetPrefetch.reset_mid = %0d", pb_cov_reset_mid);
    if (pb_cov_reset_mid < 5) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.reset_mid < 5"); end
    $display("[COV] PBestOffsetPrefetch.cross_page_drop = %0d", pb_cov_cross_page_drop);
    if (pb_cov_cross_page_drop < 5) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.cross_page_drop < 5"); end
    $display("[COV] PBestOffsetPrefetch.disable_drop = %0d", pb_cov_disable_drop);
    if (pb_cov_disable_drop < 5) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.disable_drop < 5"); end
    $display("[COV] PBestOffsetPrefetch.enable_low_full = %0d", pb_cov_enable_low_full);
    if (pb_cov_enable_low_full < 5) begin cov_fail++; $display("[COV] PBestOffsetPrefetch.enable_low_full < 5"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
