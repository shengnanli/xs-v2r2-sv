// 自动生成：verif/ut/VBestOffsetPrefetch/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// VBestOffsetPrefetch 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= VBestOffsetPrefetch =================
  int unsigned vb_mode = 0;
  logic [37:0] vb_page [8];            // 8 个虚拟页号（块号 44 位 = {38 位页号, 6 位页内块号}）
  int unsigned vb_k = 0;
  int          vb_step = 1;
  logic        vb_tlb_q = 1'b0;        // 上一拍 golden 是否发了 tlb_req
  initial for (int i = 0; i < 8; i++) vb_page[i] = 38'({$urandom, $urandom});
  function automatic logic [43:0] vb_blk();
    if ($urandom_range(0, 255) == 0) vb_step = $urandom_range(1, 9) * (($urandom_range(0, 1) != 0) ? 1 : -1);
    if ($urandom_range(0, 1023) == 0) vb_page[$urandom_range(0, 7)] = 38'({$urandom, $urandom});   // 偶尔换一页，高位也翻得到
    vb_k++;
    return {vb_page[$urandom_range(0, 7)], 6'(vb_k * vb_step)};
  endfunction
  // reqFilter 16 项条目数据不复位：每项至少被分配（alloc）过一次后，出口 bits 两侧才有确定的同值
  logic [15:0] vb_alloc_seen = '0;
  always @(posedge clk) vb_alloc_seen <= vb_alloc_seen | {vb_u_gold.reqFilter.alloc_15, vb_u_gold.reqFilter.alloc_14, vb_u_gold.reqFilter.alloc_13, vb_u_gold.reqFilter.alloc_12, vb_u_gold.reqFilter.alloc_11, vb_u_gold.reqFilter.alloc_10, vb_u_gold.reqFilter.alloc_9, vb_u_gold.reqFilter.alloc_8, vb_u_gold.reqFilter.alloc_7, vb_u_gold.reqFilter.alloc_6, vb_u_gold.reqFilter.alloc_5, vb_u_gold.reqFilter.alloc_4, vb_u_gold.reqFilter.alloc_3, vb_u_gold.reqFilter.alloc_2, vb_u_gold.reqFilter.alloc_1, vb_u_gold.reqFilter.alloc_0};
  logic vb_reset;
  logic vb_io_enable;
  logic [9:0] vb_io_pfCtrlOfDelayLatency;
  logic vb_io_train_valid;
  logic vb_io_train_bits_needT;
  logic [6:0] vb_io_train_bits_source;
  logic [43:0] vb_io_train_bits_vaddr;
  wire  vb_g_io_tlb_req_req_valid, vb_i_io_tlb_req_req_valid;
  logic vb_s0_io_tlb_req_req_valid = '0, vb_s1_io_tlb_req_req_valid = '0;
  wire  [49:0] vb_g_io_tlb_req_req_bits_vaddr, vb_i_io_tlb_req_req_bits_vaddr;
  logic [49:0] vb_s0_io_tlb_req_req_bits_vaddr = '0, vb_s1_io_tlb_req_req_bits_vaddr = '0;
  wire  [2:0] vb_g_io_tlb_req_req_bits_cmd, vb_i_io_tlb_req_req_bits_cmd;
  logic [2:0] vb_s0_io_tlb_req_req_bits_cmd = '0, vb_s1_io_tlb_req_req_bits_cmd = '0;
  wire  vb_g_io_tlb_req_req_bits_isPrefetch, vb_i_io_tlb_req_req_bits_isPrefetch;
  logic vb_s0_io_tlb_req_req_bits_isPrefetch = '0, vb_s1_io_tlb_req_req_bits_isPrefetch = '0;
  wire  vb_g_io_tlb_req_req_bits_kill, vb_i_io_tlb_req_req_bits_kill;
  logic vb_s0_io_tlb_req_req_bits_kill = '0, vb_s1_io_tlb_req_req_bits_kill = '0;
  wire  vb_g_io_tlb_req_req_bits_no_translate, vb_i_io_tlb_req_req_bits_no_translate;
  logic vb_s0_io_tlb_req_req_bits_no_translate = '0, vb_s1_io_tlb_req_req_bits_no_translate = '0;
  logic vb_io_tlb_req_resp_valid;
  logic [47:0] vb_io_tlb_req_resp_bits_paddr_0;
  logic [1:0] vb_io_tlb_req_resp_bits_pbmt;
  logic vb_io_tlb_req_resp_bits_miss;
  logic vb_io_tlb_req_resp_bits_excp_0_gpf_ld;
  logic vb_io_tlb_req_resp_bits_excp_0_pf_ld;
  logic vb_io_tlb_req_resp_bits_excp_0_af_ld;
  logic vb_io_tlb_req_pmp_resp_ld;
  logic vb_io_tlb_req_pmp_resp_mmio;
  logic vb_io_req_ready;
  wire  vb_g_io_req_valid, vb_i_io_req_valid;
  logic vb_s0_io_req_valid = '0, vb_s1_io_req_valid = '0;
  wire  [32:0] vb_g_io_req_bits_tag, vb_i_io_req_bits_tag;
  logic [32:0] vb_s0_io_req_bits_tag = '0, vb_s1_io_req_bits_tag = '0;
  wire  [8:0] vb_g_io_req_bits_set, vb_i_io_req_bits_set;
  logic [8:0] vb_s0_io_req_bits_set = '0, vb_s1_io_req_bits_set = '0;
  wire  [43:0] vb_g_io_req_bits_vaddr, vb_i_io_req_bits_vaddr;
  logic [43:0] vb_s0_io_req_bits_vaddr = '0, vb_s1_io_req_bits_vaddr = '0;
  wire  vb_g_io_req_bits_needT, vb_i_io_req_bits_needT;
  logic vb_s0_io_req_bits_needT = '0, vb_s1_io_req_bits_needT = '0;
  wire  [6:0] vb_g_io_req_bits_source, vb_i_io_req_bits_source;
  logic [6:0] vb_s0_io_req_bits_source = '0, vb_s1_io_req_bits_source = '0;
  logic vb_io_resp_valid;
  logic [8:0] vb_boreChildrenBd_bore_addr;
  logic [8:0] vb_boreChildrenBd_bore_addr_rd;
  logic [12:0] vb_boreChildrenBd_bore_wdata;
  logic vb_boreChildrenBd_bore_wmask;
  logic vb_boreChildrenBd_bore_re;
  logic vb_boreChildrenBd_bore_we;
  wire  [12:0] vb_g_boreChildrenBd_bore_rdata, vb_i_boreChildrenBd_bore_rdata;
  logic [12:0] vb_s0_boreChildrenBd_bore_rdata = '0, vb_s1_boreChildrenBd_bore_rdata = '0;
  logic vb_boreChildrenBd_bore_ack;
  logic vb_boreChildrenBd_bore_selectedOH;
  logic vb_boreChildrenBd_bore_array;
  logic vb_sigFromSrams_bore_ram_hold;
  logic vb_sigFromSrams_bore_ram_bypass;
  logic vb_sigFromSrams_bore_ram_bp_clken;
  logic vb_sigFromSrams_bore_ram_aux_clk;
  logic vb_sigFromSrams_bore_ram_aux_ckbp;
  logic vb_sigFromSrams_bore_ram_mcp_hold;
  logic vb_sigFromSrams_bore_cgen;
  int vb_cov_s0_fire = 0;
  int vb_cov_s1_hold = 0;
  int vb_cov_disable_drop = 0;
  int vb_cov_tlb_req = 0;
  int vb_cov_req_fire = 0;
  int vb_cov_req_stall = 0;
  int vb_cov_enable_low = 0;
  int vb_cov_bore_rdata_nz = 0;
  int vb_cov_reset_mid = 0;
  logic [3:0] vb_armed = '0;
  int vb_armed_at = -1;
  VBestOffsetPrefetch vb_u_gold (
    .clock(clk),
    .reset(vb_reset),
    .io_enable(vb_io_enable),
    .io_pfCtrlOfDelayLatency(vb_io_pfCtrlOfDelayLatency),
    .io_train_valid(vb_io_train_valid),
    .io_train_bits_needT(vb_io_train_bits_needT),
    .io_train_bits_source(vb_io_train_bits_source),
    .io_train_bits_vaddr(vb_io_train_bits_vaddr),
    .io_tlb_req_req_valid(vb_g_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(vb_g_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_cmd(vb_g_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_isPrefetch(vb_g_io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_kill(vb_g_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_no_translate(vb_g_io_tlb_req_req_bits_no_translate),
    .io_tlb_req_resp_valid(vb_io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(vb_io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt(vb_io_tlb_req_resp_bits_pbmt),
    .io_tlb_req_resp_bits_miss(vb_io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(vb_io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(vb_io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(vb_io_tlb_req_resp_bits_excp_0_af_ld),
    .io_tlb_req_pmp_resp_ld(vb_io_tlb_req_pmp_resp_ld),
    .io_tlb_req_pmp_resp_mmio(vb_io_tlb_req_pmp_resp_mmio),
    .io_req_ready(vb_io_req_ready),
    .io_req_valid(vb_g_io_req_valid),
    .io_req_bits_tag(vb_g_io_req_bits_tag),
    .io_req_bits_set(vb_g_io_req_bits_set),
    .io_req_bits_vaddr(vb_g_io_req_bits_vaddr),
    .io_req_bits_needT(vb_g_io_req_bits_needT),
    .io_req_bits_source(vb_g_io_req_bits_source),
    .io_resp_valid(vb_io_resp_valid),
    .boreChildrenBd_bore_addr(vb_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(vb_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(vb_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(vb_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(vb_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(vb_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(vb_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(vb_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(vb_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(vb_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(vb_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(vb_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(vb_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(vb_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(vb_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(vb_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(vb_sigFromSrams_bore_cgen)
  );
  VBestOffsetPrefetch_xs vb_u_impl (
    .clock(clk),
    .reset(vb_reset),
    .io_enable(vb_io_enable),
    .io_pfCtrlOfDelayLatency(vb_io_pfCtrlOfDelayLatency),
    .io_train_valid(vb_io_train_valid),
    .io_train_bits_needT(vb_io_train_bits_needT),
    .io_train_bits_source(vb_io_train_bits_source),
    .io_train_bits_vaddr(vb_io_train_bits_vaddr),
    .io_tlb_req_req_valid(vb_i_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(vb_i_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_cmd(vb_i_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_isPrefetch(vb_i_io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_kill(vb_i_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_no_translate(vb_i_io_tlb_req_req_bits_no_translate),
    .io_tlb_req_resp_valid(vb_io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(vb_io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt(vb_io_tlb_req_resp_bits_pbmt),
    .io_tlb_req_resp_bits_miss(vb_io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(vb_io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(vb_io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(vb_io_tlb_req_resp_bits_excp_0_af_ld),
    .io_tlb_req_pmp_resp_ld(vb_io_tlb_req_pmp_resp_ld),
    .io_tlb_req_pmp_resp_mmio(vb_io_tlb_req_pmp_resp_mmio),
    .io_req_ready(vb_io_req_ready),
    .io_req_valid(vb_i_io_req_valid),
    .io_req_bits_tag(vb_i_io_req_bits_tag),
    .io_req_bits_set(vb_i_io_req_bits_set),
    .io_req_bits_vaddr(vb_i_io_req_bits_vaddr),
    .io_req_bits_needT(vb_i_io_req_bits_needT),
    .io_req_bits_source(vb_i_io_req_bits_source),
    .io_resp_valid(vb_io_resp_valid),
    .boreChildrenBd_bore_addr(vb_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(vb_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(vb_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(vb_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(vb_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(vb_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(vb_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(vb_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(vb_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(vb_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(vb_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(vb_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(vb_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(vb_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(vb_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(vb_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(vb_sigFromSrams_bore_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) vb_mode = $urandom_range(0, 15);
      vb_io_enable = 1'($urandom);
      vb_io_pfCtrlOfDelayLatency = 10'($urandom);
      vb_io_train_valid = 1'($urandom);
      vb_io_train_bits_needT = 1'($urandom);
      vb_io_train_bits_source = 7'($urandom);
      vb_io_train_bits_vaddr = 44'({$urandom, $urandom});
      vb_io_tlb_req_resp_valid = 1'($urandom);
      vb_io_tlb_req_resp_bits_paddr_0 = 48'({$urandom, $urandom});
      vb_io_tlb_req_resp_bits_pbmt = 2'($urandom);
      vb_io_tlb_req_resp_bits_miss = 1'($urandom);
      vb_io_tlb_req_resp_bits_excp_0_gpf_ld = 1'($urandom);
      vb_io_tlb_req_resp_bits_excp_0_pf_ld = 1'($urandom);
      vb_io_tlb_req_resp_bits_excp_0_af_ld = 1'($urandom);
      vb_io_tlb_req_pmp_resp_ld = 1'($urandom);
      vb_io_tlb_req_pmp_resp_mmio = 1'($urandom);
      vb_io_req_ready = 1'($urandom);
      vb_io_resp_valid = 1'($urandom);
      vb_boreChildrenBd_bore_addr = 9'($urandom);
      vb_boreChildrenBd_bore_addr_rd = 9'($urandom);
      vb_boreChildrenBd_bore_wdata = 13'($urandom);
      vb_boreChildrenBd_bore_wmask = 1'($urandom);
      vb_boreChildrenBd_bore_re = 1'($urandom);
      vb_boreChildrenBd_bore_we = 1'($urandom);
      vb_boreChildrenBd_bore_ack = 1'($urandom);
      vb_boreChildrenBd_bore_selectedOH = 1'($urandom);
      vb_boreChildrenBd_bore_array = 1'($urandom);
      vb_sigFromSrams_bore_ram_hold = 1'($urandom);
      vb_sigFromSrams_bore_ram_bypass = 1'($urandom);
      vb_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      vb_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      vb_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      vb_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      vb_sigFromSrams_bore_cgen = 1'($urandom);
      vb_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_vb
        vb_io_enable = ($urandom_range(0, 7) != 0);
        vb_io_pfCtrlOfDelayLatency = 10'($urandom_range(0, 15));
        vb_io_train_valid = ($urandom_range(0, 1) != 0);
        vb_io_train_bits_vaddr = vb_blk();
        vb_io_req_ready = (vb_mode == 1) ? 1'b0 : ($urandom_range(0, 3) != 0);   // mode 1：下游长时间不收，把 16 项填满
        vb_io_tlb_req_resp_valid = vb_tlb_q;
        vb_tlb_q = vb_g_io_tlb_req_req_valid;
        vb_io_tlb_req_resp_bits_miss = ($urandom_range(0, 3) == 0);
        vb_io_tlb_req_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 19) == 0);
        vb_io_tlb_req_resp_bits_excp_0_pf_ld = ($urandom_range(0, 19) == 0);
        vb_io_tlb_req_resp_bits_excp_0_af_ld = ($urandom_range(0, 19) == 0);
        vb_io_tlb_req_pmp_resp_ld = ($urandom_range(0, 9) == 0);
        vb_io_tlb_req_pmp_resp_mmio = ($urandom_range(0, 9) == 0);
        if (vb_mode != 0) begin
          vb_boreChildrenBd_bore_re = '0;
          vb_boreChildrenBd_bore_we = '0;
          vb_boreChildrenBd_bore_ack = '0;
          vb_boreChildrenBd_bore_selectedOH = '0;
          vb_boreChildrenBd_bore_array = '0;
          vb_boreChildrenBd_bore_wmask = '0;
          vb_sigFromSrams_bore_ram_hold = '0;
          vb_sigFromSrams_bore_ram_bypass = '0;
          vb_sigFromSrams_bore_ram_bp_clken = '0;
          vb_sigFromSrams_bore_ram_aux_clk = '0;
          vb_sigFromSrams_bore_ram_aux_ckbp = '0;
          vb_sigFromSrams_bore_ram_mcp_hold = '0;
          vb_sigFromSrams_bore_cgen = '0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && vb_armed_at >= 0 && cyc >= vb_armed_at) begin
        checks++;
        if (vb_g_io_tlb_req_req_valid !== vb_i_io_tlb_req_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.io_tlb_req_req_valid g=%h i=%h", cyc, vb_g_io_tlb_req_req_valid, vb_i_io_tlb_req_req_valid);
        end
        vb_s1_io_tlb_req_req_valid |= vb_g_io_tlb_req_req_valid;
        vb_s0_io_tlb_req_req_valid |= ~vb_g_io_tlb_req_req_valid;
        checks++;
        if (vb_g_io_tlb_req_req_bits_vaddr !== vb_i_io_tlb_req_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr g=%h i=%h", cyc, vb_g_io_tlb_req_req_bits_vaddr, vb_i_io_tlb_req_req_bits_vaddr);
        end
        vb_s1_io_tlb_req_req_bits_vaddr |= vb_g_io_tlb_req_req_bits_vaddr;
        vb_s0_io_tlb_req_req_bits_vaddr |= ~vb_g_io_tlb_req_req_bits_vaddr;
        checks++;
        if (vb_g_io_tlb_req_req_bits_cmd !== vb_i_io_tlb_req_req_bits_cmd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.io_tlb_req_req_bits_cmd g=%h i=%h", cyc, vb_g_io_tlb_req_req_bits_cmd, vb_i_io_tlb_req_req_bits_cmd);
        end
        vb_s1_io_tlb_req_req_bits_cmd |= vb_g_io_tlb_req_req_bits_cmd;
        vb_s0_io_tlb_req_req_bits_cmd |= ~vb_g_io_tlb_req_req_bits_cmd;
        checks++;
        if (vb_g_io_tlb_req_req_bits_isPrefetch !== vb_i_io_tlb_req_req_bits_isPrefetch) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.io_tlb_req_req_bits_isPrefetch g=%h i=%h", cyc, vb_g_io_tlb_req_req_bits_isPrefetch, vb_i_io_tlb_req_req_bits_isPrefetch);
        end
        vb_s1_io_tlb_req_req_bits_isPrefetch |= vb_g_io_tlb_req_req_bits_isPrefetch;
        vb_s0_io_tlb_req_req_bits_isPrefetch |= ~vb_g_io_tlb_req_req_bits_isPrefetch;
        checks++;
        if (vb_g_io_tlb_req_req_bits_kill !== vb_i_io_tlb_req_req_bits_kill) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.io_tlb_req_req_bits_kill g=%h i=%h", cyc, vb_g_io_tlb_req_req_bits_kill, vb_i_io_tlb_req_req_bits_kill);
        end
        vb_s1_io_tlb_req_req_bits_kill |= vb_g_io_tlb_req_req_bits_kill;
        vb_s0_io_tlb_req_req_bits_kill |= ~vb_g_io_tlb_req_req_bits_kill;
        checks++;
        if (vb_g_io_tlb_req_req_bits_no_translate !== vb_i_io_tlb_req_req_bits_no_translate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.io_tlb_req_req_bits_no_translate g=%h i=%h", cyc, vb_g_io_tlb_req_req_bits_no_translate, vb_i_io_tlb_req_req_bits_no_translate);
        end
        vb_s1_io_tlb_req_req_bits_no_translate |= vb_g_io_tlb_req_req_bits_no_translate;
        vb_s0_io_tlb_req_req_bits_no_translate |= ~vb_g_io_tlb_req_req_bits_no_translate;
        checks++;
        if (vb_g_io_req_valid !== vb_i_io_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.io_req_valid g=%h i=%h", cyc, vb_g_io_req_valid, vb_i_io_req_valid);
        end
        vb_s1_io_req_valid |= vb_g_io_req_valid;
        vb_s0_io_req_valid |= ~vb_g_io_req_valid;
        checks++;
        if (vb_g_io_req_bits_tag !== vb_i_io_req_bits_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.io_req_bits_tag g=%h i=%h", cyc, vb_g_io_req_bits_tag, vb_i_io_req_bits_tag);
        end
        vb_s1_io_req_bits_tag |= vb_g_io_req_bits_tag;
        vb_s0_io_req_bits_tag |= ~vb_g_io_req_bits_tag;
        checks++;
        if (vb_g_io_req_bits_set !== vb_i_io_req_bits_set) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.io_req_bits_set g=%h i=%h", cyc, vb_g_io_req_bits_set, vb_i_io_req_bits_set);
        end
        vb_s1_io_req_bits_set |= vb_g_io_req_bits_set;
        vb_s0_io_req_bits_set |= ~vb_g_io_req_bits_set;
        checks++;
        if (vb_g_io_req_bits_vaddr !== vb_i_io_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.io_req_bits_vaddr g=%h i=%h", cyc, vb_g_io_req_bits_vaddr, vb_i_io_req_bits_vaddr);
        end
        vb_s1_io_req_bits_vaddr |= vb_g_io_req_bits_vaddr;
        vb_s0_io_req_bits_vaddr |= ~vb_g_io_req_bits_vaddr;
        checks++;
        if (vb_g_io_req_bits_needT !== vb_i_io_req_bits_needT) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.io_req_bits_needT g=%h i=%h", cyc, vb_g_io_req_bits_needT, vb_i_io_req_bits_needT);
        end
        vb_s1_io_req_bits_needT |= vb_g_io_req_bits_needT;
        vb_s0_io_req_bits_needT |= ~vb_g_io_req_bits_needT;
        checks++;
        if (vb_g_io_req_bits_source !== vb_i_io_req_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.io_req_bits_source g=%h i=%h", cyc, vb_g_io_req_bits_source, vb_i_io_req_bits_source);
        end
        vb_s1_io_req_bits_source |= vb_g_io_req_bits_source;
        vb_s0_io_req_bits_source |= ~vb_g_io_req_bits_source;
        checks++;
        if (vb_g_boreChildrenBd_bore_rdata !== vb_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VBestOffsetPrefetch.boreChildrenBd_bore_rdata g=%h i=%h", cyc, vb_g_boreChildrenBd_bore_rdata, vb_i_boreChildrenBd_bore_rdata);
        end
        vb_s1_boreChildrenBd_bore_rdata |= vb_g_boreChildrenBd_bore_rdata;
        vb_s0_boreChildrenBd_bore_rdata |= ~vb_g_boreChildrenBd_bore_rdata;
        if (vb_u_gold._s0_fire_T) vb_cov_s0_fire++;
        if (vb_u_gold.s1_req_valid && !vb_u_gold.s1_ready) vb_cov_s1_hold++;
        if (vb_u_gold.s1_req_valid && vb_u_gold._scoreTable_io_prefetchDisable) vb_cov_disable_drop++;
        if (vb_g_io_tlb_req_req_valid) vb_cov_tlb_req++;
        if (vb_g_io_req_valid && vb_io_req_ready) vb_cov_req_fire++;
        if (vb_g_io_req_valid && !vb_io_req_ready) vb_cov_req_stall++;
        if (!vb_io_enable && vb_u_gold._reqFilter_io_out_req_valid) vb_cov_enable_low++;
        if (vb_g_boreChildrenBd_bore_rdata != 0) vb_cov_bore_rdata_nz++;
        if (vb_reset && cyc > 100) vb_cov_reset_mid++;
      end
      if (vb_u_gold._s0_fire_T) vb_armed[0] = 1'b1;
      if (vb_u_gold.rrTable.rrTable.respReg) vb_armed[1] = 1'b1;
      if (vb_g_io_tlb_req_req_valid) vb_armed[2] = 1'b1;
      if (&vb_alloc_seen) vb_armed[3] = 1'b1;
      if (vb_armed_at < 0 && (&vb_armed)) vb_armed_at = cyc + 1 + 1;
    end

    // ---- 覆盖闸 ----
    if (!(vb_s0_io_tlb_req_req_valid && vb_s1_io_tlb_req_req_valid)) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_valid 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[6] && vb_s1_io_tlb_req_req_bits_vaddr[6])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[7] && vb_s1_io_tlb_req_req_bits_vaddr[7])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[8] && vb_s1_io_tlb_req_req_bits_vaddr[8])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[9] && vb_s1_io_tlb_req_req_bits_vaddr[9])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[10] && vb_s1_io_tlb_req_req_bits_vaddr[10])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[11] && vb_s1_io_tlb_req_req_bits_vaddr[11])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[12] && vb_s1_io_tlb_req_req_bits_vaddr[12])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[13] && vb_s1_io_tlb_req_req_bits_vaddr[13])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[14] && vb_s1_io_tlb_req_req_bits_vaddr[14])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[15] && vb_s1_io_tlb_req_req_bits_vaddr[15])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[16] && vb_s1_io_tlb_req_req_bits_vaddr[16])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[17] && vb_s1_io_tlb_req_req_bits_vaddr[17])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[18] && vb_s1_io_tlb_req_req_bits_vaddr[18])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[19] && vb_s1_io_tlb_req_req_bits_vaddr[19])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[20] && vb_s1_io_tlb_req_req_bits_vaddr[20])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[21] && vb_s1_io_tlb_req_req_bits_vaddr[21])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[22] && vb_s1_io_tlb_req_req_bits_vaddr[22])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[23] && vb_s1_io_tlb_req_req_bits_vaddr[23])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[24] && vb_s1_io_tlb_req_req_bits_vaddr[24])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[25] && vb_s1_io_tlb_req_req_bits_vaddr[25])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[26] && vb_s1_io_tlb_req_req_bits_vaddr[26])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[27] && vb_s1_io_tlb_req_req_bits_vaddr[27])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[28] && vb_s1_io_tlb_req_req_bits_vaddr[28])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[29] && vb_s1_io_tlb_req_req_bits_vaddr[29])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[30] && vb_s1_io_tlb_req_req_bits_vaddr[30])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[31] && vb_s1_io_tlb_req_req_bits_vaddr[31])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[32] && vb_s1_io_tlb_req_req_bits_vaddr[32])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[33] && vb_s1_io_tlb_req_req_bits_vaddr[33])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[34] && vb_s1_io_tlb_req_req_bits_vaddr[34])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[35] && vb_s1_io_tlb_req_req_bits_vaddr[35])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[36] && vb_s1_io_tlb_req_req_bits_vaddr[36])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[37] && vb_s1_io_tlb_req_req_bits_vaddr[37])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[38] && vb_s1_io_tlb_req_req_bits_vaddr[38])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[39] && vb_s1_io_tlb_req_req_bits_vaddr[39])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[40] && vb_s1_io_tlb_req_req_bits_vaddr[40])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[41] && vb_s1_io_tlb_req_req_bits_vaddr[41])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[42] && vb_s1_io_tlb_req_req_bits_vaddr[42])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[43] && vb_s1_io_tlb_req_req_bits_vaddr[43])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[44] && vb_s1_io_tlb_req_req_bits_vaddr[44])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[44] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[45] && vb_s1_io_tlb_req_req_bits_vaddr[45])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[45] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[46] && vb_s1_io_tlb_req_req_bits_vaddr[46])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[46] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[47] && vb_s1_io_tlb_req_req_bits_vaddr[47])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[47] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[48] && vb_s1_io_tlb_req_req_bits_vaddr[48])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[48] 未见过 0 和 1"); end
    if (!(vb_s0_io_tlb_req_req_bits_vaddr[49] && vb_s1_io_tlb_req_req_bits_vaddr[49])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_tlb_req_req_bits_vaddr[49] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_valid && vb_s1_io_req_valid)) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_valid 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[0] && vb_s1_io_req_bits_tag[0])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[0] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[1] && vb_s1_io_req_bits_tag[1])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[1] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[2] && vb_s1_io_req_bits_tag[2])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[2] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[3] && vb_s1_io_req_bits_tag[3])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[3] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[4] && vb_s1_io_req_bits_tag[4])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[4] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[5] && vb_s1_io_req_bits_tag[5])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[5] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[6] && vb_s1_io_req_bits_tag[6])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[6] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[7] && vb_s1_io_req_bits_tag[7])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[7] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[8] && vb_s1_io_req_bits_tag[8])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[8] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[9] && vb_s1_io_req_bits_tag[9])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[9] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[10] && vb_s1_io_req_bits_tag[10])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[10] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[11] && vb_s1_io_req_bits_tag[11])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[11] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[12] && vb_s1_io_req_bits_tag[12])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[12] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[13] && vb_s1_io_req_bits_tag[13])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[13] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[14] && vb_s1_io_req_bits_tag[14])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[14] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[15] && vb_s1_io_req_bits_tag[15])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[15] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[16] && vb_s1_io_req_bits_tag[16])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[16] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[17] && vb_s1_io_req_bits_tag[17])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[17] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[18] && vb_s1_io_req_bits_tag[18])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[18] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[19] && vb_s1_io_req_bits_tag[19])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[19] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[20] && vb_s1_io_req_bits_tag[20])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[20] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[21] && vb_s1_io_req_bits_tag[21])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[21] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[22] && vb_s1_io_req_bits_tag[22])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[22] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[23] && vb_s1_io_req_bits_tag[23])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[23] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[24] && vb_s1_io_req_bits_tag[24])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[24] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[25] && vb_s1_io_req_bits_tag[25])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[25] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[26] && vb_s1_io_req_bits_tag[26])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[26] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[27] && vb_s1_io_req_bits_tag[27])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[27] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[28] && vb_s1_io_req_bits_tag[28])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[28] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[29] && vb_s1_io_req_bits_tag[29])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[29] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[30] && vb_s1_io_req_bits_tag[30])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[30] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[31] && vb_s1_io_req_bits_tag[31])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[31] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_tag[32] && vb_s1_io_req_bits_tag[32])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_tag[32] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_set[0] && vb_s1_io_req_bits_set[0])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_set[0] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_set[1] && vb_s1_io_req_bits_set[1])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_set[1] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_set[2] && vb_s1_io_req_bits_set[2])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_set[2] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_set[3] && vb_s1_io_req_bits_set[3])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_set[3] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_set[4] && vb_s1_io_req_bits_set[4])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_set[4] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_set[5] && vb_s1_io_req_bits_set[5])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_set[5] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_set[6] && vb_s1_io_req_bits_set[6])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_set[6] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_set[7] && vb_s1_io_req_bits_set[7])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_set[7] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_set[8] && vb_s1_io_req_bits_set[8])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_set[8] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[0] && vb_s1_io_req_bits_vaddr[0])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[1] && vb_s1_io_req_bits_vaddr[1])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[2] && vb_s1_io_req_bits_vaddr[2])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[3] && vb_s1_io_req_bits_vaddr[3])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[4] && vb_s1_io_req_bits_vaddr[4])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[5] && vb_s1_io_req_bits_vaddr[5])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[6] && vb_s1_io_req_bits_vaddr[6])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[7] && vb_s1_io_req_bits_vaddr[7])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[8] && vb_s1_io_req_bits_vaddr[8])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[9] && vb_s1_io_req_bits_vaddr[9])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[10] && vb_s1_io_req_bits_vaddr[10])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[11] && vb_s1_io_req_bits_vaddr[11])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[12] && vb_s1_io_req_bits_vaddr[12])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[13] && vb_s1_io_req_bits_vaddr[13])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[14] && vb_s1_io_req_bits_vaddr[14])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[15] && vb_s1_io_req_bits_vaddr[15])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[16] && vb_s1_io_req_bits_vaddr[16])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[17] && vb_s1_io_req_bits_vaddr[17])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[18] && vb_s1_io_req_bits_vaddr[18])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[19] && vb_s1_io_req_bits_vaddr[19])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[20] && vb_s1_io_req_bits_vaddr[20])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[21] && vb_s1_io_req_bits_vaddr[21])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[22] && vb_s1_io_req_bits_vaddr[22])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[23] && vb_s1_io_req_bits_vaddr[23])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[24] && vb_s1_io_req_bits_vaddr[24])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[25] && vb_s1_io_req_bits_vaddr[25])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[26] && vb_s1_io_req_bits_vaddr[26])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[27] && vb_s1_io_req_bits_vaddr[27])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[28] && vb_s1_io_req_bits_vaddr[28])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[29] && vb_s1_io_req_bits_vaddr[29])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[30] && vb_s1_io_req_bits_vaddr[30])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[31] && vb_s1_io_req_bits_vaddr[31])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[32] && vb_s1_io_req_bits_vaddr[32])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[33] && vb_s1_io_req_bits_vaddr[33])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[34] && vb_s1_io_req_bits_vaddr[34])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[35] && vb_s1_io_req_bits_vaddr[35])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[36] && vb_s1_io_req_bits_vaddr[36])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[37] && vb_s1_io_req_bits_vaddr[37])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[38] && vb_s1_io_req_bits_vaddr[38])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[39] && vb_s1_io_req_bits_vaddr[39])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[40] && vb_s1_io_req_bits_vaddr[40])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[41] && vb_s1_io_req_bits_vaddr[41])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[42] && vb_s1_io_req_bits_vaddr[42])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_vaddr[43] && vb_s1_io_req_bits_vaddr[43])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_needT && vb_s1_io_req_bits_needT)) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_needT 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_source[0] && vb_s1_io_req_bits_source[0])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_source[0] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_source[1] && vb_s1_io_req_bits_source[1])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_source[1] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_source[2] && vb_s1_io_req_bits_source[2])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_source[2] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_source[3] && vb_s1_io_req_bits_source[3])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_source[3] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_source[4] && vb_s1_io_req_bits_source[4])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_source[4] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_source[5] && vb_s1_io_req_bits_source[5])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_source[5] 未见过 0 和 1"); end
    if (!(vb_s0_io_req_bits_source[6] && vb_s1_io_req_bits_source[6])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.io_req_bits_source[6] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[0] && vb_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[1] && vb_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[2] && vb_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[3] && vb_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[4] && vb_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[5] && vb_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[6] && vb_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[7] && vb_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[8] && vb_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[9] && vb_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[10] && vb_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[11] && vb_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(vb_s0_boreChildrenBd_bore_rdata[12] && vb_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    $display("[ARM] VBestOffsetPrefetch armed_at=%0d", vb_armed_at);
    if (vb_armed_at < 0) begin cov_fail++; $display("[ARM] VBestOffsetPrefetch 从未 arm"); end
    $display("[COV] VBestOffsetPrefetch.s0_fire = %0d", vb_cov_s0_fire);
    if (vb_cov_s0_fire < 5) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.s0_fire < 5"); end
    $display("[COV] VBestOffsetPrefetch.s1_hold = %0d", vb_cov_s1_hold);
    if (vb_cov_s1_hold < 5) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.s1_hold < 5"); end
    $display("[COV] VBestOffsetPrefetch.disable_drop = %0d", vb_cov_disable_drop);
    if (vb_cov_disable_drop < 5) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.disable_drop < 5"); end
    $display("[COV] VBestOffsetPrefetch.tlb_req = %0d", vb_cov_tlb_req);
    if (vb_cov_tlb_req < 5) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.tlb_req < 5"); end
    $display("[COV] VBestOffsetPrefetch.req_fire = %0d", vb_cov_req_fire);
    if (vb_cov_req_fire < 5) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.req_fire < 5"); end
    $display("[COV] VBestOffsetPrefetch.req_stall = %0d", vb_cov_req_stall);
    if (vb_cov_req_stall < 5) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.req_stall < 5"); end
    $display("[COV] VBestOffsetPrefetch.enable_low = %0d", vb_cov_enable_low);
    if (vb_cov_enable_low < 5) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.enable_low < 5"); end
    $display("[COV] VBestOffsetPrefetch.bore_rdata_nz = %0d", vb_cov_bore_rdata_nz);
    if (vb_cov_bore_rdata_nz < 5) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.bore_rdata_nz < 5"); end
    $display("[COV] VBestOffsetPrefetch.reset_mid = %0d", vb_cov_reset_mid);
    if (vb_cov_reset_mid < 5) begin cov_fail++; $display("[COV] VBestOffsetPrefetch.reset_mid < 5"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
