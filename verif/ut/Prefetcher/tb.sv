// 自动生成：verif/ut/Prefetcher/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// Prefetcher 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= Prefetcher =================
  int unsigned pf_mode = 0;
  logic [37:0] pf_page [8];            // 8 个页号（块号 44 位 = {38 位页号, 6 位页内块号}）
  int unsigned pf_k = 0;
  int          pf_step = 1;
  logic        pf_tlb_q = 1'b0;        // 上一拍 golden 是否发了 tlb_req
  initial for (int i = 0; i < 8; i++) pf_page[i] = 38'({$urandom, $urandom});
  function automatic logic [43:0] pf_blk();
    if ($urandom_range(0, 255) == 0) pf_step = $urandom_range(1, 9) * (($urandom_range(0, 1) != 0) ? 1 : -1);
    if ($urandom_range(0, 1023) == 0) pf_page[$urandom_range(0, 7)] = 38'({$urandom, $urandom});
    pf_k++;
    return {pf_page[$urandom_range(0, 7)], 6'(pf_k * pf_step)};
  endfunction
  // vbop reqFilter 16 项条目数据不复位：每项至少被分配过一次后，出口 bits 两侧才同值
  logic [15:0] pf_alloc_seen = '0;
  always @(posedge clk) pf_alloc_seen <= pf_alloc_seen | {pf_u_gold.vbop.reqFilter.alloc_15, pf_u_gold.vbop.reqFilter.alloc_14, pf_u_gold.vbop.reqFilter.alloc_13, pf_u_gold.vbop.reqFilter.alloc_12, pf_u_gold.vbop.reqFilter.alloc_11, pf_u_gold.vbop.reqFilter.alloc_10, pf_u_gold.vbop.reqFilter.alloc_9, pf_u_gold.vbop.reqFilter.alloc_8, pf_u_gold.vbop.reqFilter.alloc_7, pf_u_gold.vbop.reqFilter.alloc_6, pf_u_gold.vbop.reqFilter.alloc_5, pf_u_gold.vbop.reqFilter.alloc_4, pf_u_gold.vbop.reqFilter.alloc_3, pf_u_gold.vbop.reqFilter.alloc_2, pf_u_gold.vbop.reqFilter.alloc_1, pf_u_gold.vbop.reqFilter.alloc_0};
  logic pf_reset;
  wire  pf_g_io_train_ready, pf_i_io_train_ready;
  logic pf_s0_io_train_ready = '0, pf_s1_io_train_ready = '0;
  logic pf_io_train_valid;
  logic [32:0] pf_io_train_bits_tag;
  logic [8:0] pf_io_train_bits_set;
  logic pf_io_train_bits_needT;
  logic [6:0] pf_io_train_bits_source;
  logic [43:0] pf_io_train_bits_vaddr;
  logic [4:0] pf_io_train_bits_reqsource;
  wire  pf_g_io_tlb_req_req_valid, pf_i_io_tlb_req_req_valid;
  logic pf_s0_io_tlb_req_req_valid = '0, pf_s1_io_tlb_req_req_valid = '0;
  wire  [49:0] pf_g_io_tlb_req_req_bits_vaddr, pf_i_io_tlb_req_req_bits_vaddr;
  logic [49:0] pf_s0_io_tlb_req_req_bits_vaddr = '0, pf_s1_io_tlb_req_req_bits_vaddr = '0;
  wire  [2:0] pf_g_io_tlb_req_req_bits_cmd, pf_i_io_tlb_req_req_bits_cmd;
  logic [2:0] pf_s0_io_tlb_req_req_bits_cmd = '0, pf_s1_io_tlb_req_req_bits_cmd = '0;
  wire  pf_g_io_tlb_req_req_bits_isPrefetch, pf_i_io_tlb_req_req_bits_isPrefetch;
  logic pf_s0_io_tlb_req_req_bits_isPrefetch = '0, pf_s1_io_tlb_req_req_bits_isPrefetch = '0;
  wire  pf_g_io_tlb_req_req_bits_kill, pf_i_io_tlb_req_req_bits_kill;
  logic pf_s0_io_tlb_req_req_bits_kill = '0, pf_s1_io_tlb_req_req_bits_kill = '0;
  wire  pf_g_io_tlb_req_req_bits_no_translate, pf_i_io_tlb_req_req_bits_no_translate;
  logic pf_s0_io_tlb_req_req_bits_no_translate = '0, pf_s1_io_tlb_req_req_bits_no_translate = '0;
  logic pf_io_tlb_req_resp_valid;
  logic [47:0] pf_io_tlb_req_resp_bits_paddr_0;
  logic [1:0] pf_io_tlb_req_resp_bits_pbmt;
  logic pf_io_tlb_req_resp_bits_miss;
  logic pf_io_tlb_req_resp_bits_excp_0_gpf_ld;
  logic pf_io_tlb_req_resp_bits_excp_0_pf_ld;
  logic pf_io_tlb_req_resp_bits_excp_0_af_ld;
  logic pf_io_tlb_req_pmp_resp_ld;
  logic pf_io_tlb_req_pmp_resp_mmio;
  logic pf_io_req_ready;
  wire  pf_g_io_req_valid, pf_i_io_req_valid;
  logic pf_s0_io_req_valid = '0, pf_s1_io_req_valid = '0;
  wire  [32:0] pf_g_io_req_bits_tag, pf_i_io_req_bits_tag;
  logic [32:0] pf_s0_io_req_bits_tag = '0, pf_s1_io_req_bits_tag = '0;
  wire  [8:0] pf_g_io_req_bits_set, pf_i_io_req_bits_set;
  logic [8:0] pf_s0_io_req_bits_set = '0, pf_s1_io_req_bits_set = '0;
  wire  [43:0] pf_g_io_req_bits_vaddr, pf_i_io_req_bits_vaddr;
  logic [43:0] pf_s0_io_req_bits_vaddr = '0, pf_s1_io_req_bits_vaddr = '0;
  wire  pf_g_io_req_bits_needT, pf_i_io_req_bits_needT;
  logic pf_s0_io_req_bits_needT = '0, pf_s1_io_req_bits_needT = '0;
  wire  [6:0] pf_g_io_req_bits_source, pf_i_io_req_bits_source;
  logic [6:0] pf_s0_io_req_bits_source = '0, pf_s1_io_req_bits_source = '0;
  wire  [4:0] pf_g_io_req_bits_pfSource, pf_i_io_req_bits_pfSource;
  logic [4:0] pf_s0_io_req_bits_pfSource = '0, pf_s1_io_req_bits_pfSource = '0;
  wire  pf_g_io_resp_ready, pf_i_io_resp_ready;
  logic pf_s0_io_resp_ready = '0, pf_s1_io_resp_ready = '0;
  logic pf_io_resp_valid;
  logic [4:0] pf_io_resp_bits_pfSource;
  logic pf_io_recv_addr_valid;
  logic [63:0] pf_io_recv_addr_bits_addr;
  logic [4:0] pf_io_recv_addr_bits_pfSource;
  logic pf_pfCtrlFromCore_l2_pf_master_en;
  logic pf_pfCtrlFromCore_l2_pf_recv_en;
  logic pf_pfCtrlFromCore_l2_pbop_en;
  logic pf_pfCtrlFromCore_l2_vbop_en;
  logic [9:0] pf_pfCtrlFromCore_l2_pf_delay_latency;
  logic pf_sigFromSrams_bore_ram_hold;
  logic pf_sigFromSrams_bore_ram_bypass;
  logic pf_sigFromSrams_bore_ram_bp_clken;
  logic pf_sigFromSrams_bore_ram_aux_clk;
  logic pf_sigFromSrams_bore_ram_aux_ckbp;
  logic pf_sigFromSrams_bore_ram_mcp_hold;
  logic pf_sigFromSrams_bore_cgen;
  logic pf_sigFromSrams_bore_1_ram_hold;
  logic pf_sigFromSrams_bore_1_ram_bypass;
  logic pf_sigFromSrams_bore_1_ram_bp_clken;
  logic pf_sigFromSrams_bore_1_ram_aux_clk;
  logic pf_sigFromSrams_bore_1_ram_aux_ckbp;
  logic pf_sigFromSrams_bore_1_ram_mcp_hold;
  logic pf_sigFromSrams_bore_1_cgen;
  logic pf_boreChildrenBd_bore_array;
  logic pf_boreChildrenBd_bore_all;
  logic pf_boreChildrenBd_bore_req;
  wire  pf_g_boreChildrenBd_bore_ack, pf_i_boreChildrenBd_bore_ack;
  logic pf_s0_boreChildrenBd_bore_ack = '0, pf_s1_boreChildrenBd_bore_ack = '0;
  logic pf_boreChildrenBd_bore_writeen;
  logic pf_boreChildrenBd_bore_be;
  logic [8:0] pf_boreChildrenBd_bore_addr;
  logic [12:0] pf_boreChildrenBd_bore_indata;
  logic pf_boreChildrenBd_bore_readen;
  logic [8:0] pf_boreChildrenBd_bore_addr_rd;
  wire  [12:0] pf_g_boreChildrenBd_bore_outdata, pf_i_boreChildrenBd_bore_outdata;
  logic [12:0] pf_s0_boreChildrenBd_bore_outdata = '0, pf_s1_boreChildrenBd_bore_outdata = '0;
  int pf_cov_train_filtered = 0;
  int pf_cov_pbop_req = 0;
  int pf_cov_vbop_req = 0;
  int pf_cov_rcv_req = 0;
  int pf_cov_vbop_yield_rcv = 0;
  int pf_cov_pbop_yield_vbop = 0;
  int pf_cov_resp_pbop = 0;
  int pf_cov_resp_vbop = 0;
  int pf_cov_rcv_disabled = 0;
  int pf_cov_tlb_req = 0;
  int pf_cov_req_fire = 0;
  int pf_cov_req_stall = 0;
  int pf_cov_bore_outdata_nz = 0;
  logic [6:0] pf_armed = '0;
  int pf_armed_at = -1;
  Prefetcher pf_u_gold (
    .clock(clk),
    .reset(pf_reset),
    .io_train_ready(pf_g_io_train_ready),
    .io_train_valid(pf_io_train_valid),
    .io_train_bits_tag(pf_io_train_bits_tag),
    .io_train_bits_set(pf_io_train_bits_set),
    .io_train_bits_needT(pf_io_train_bits_needT),
    .io_train_bits_source(pf_io_train_bits_source),
    .io_train_bits_vaddr(pf_io_train_bits_vaddr),
    .io_train_bits_reqsource(pf_io_train_bits_reqsource),
    .io_tlb_req_req_valid(pf_g_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(pf_g_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_cmd(pf_g_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_isPrefetch(pf_g_io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_kill(pf_g_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_no_translate(pf_g_io_tlb_req_req_bits_no_translate),
    .io_tlb_req_resp_valid(pf_io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(pf_io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt(pf_io_tlb_req_resp_bits_pbmt),
    .io_tlb_req_resp_bits_miss(pf_io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(pf_io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(pf_io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(pf_io_tlb_req_resp_bits_excp_0_af_ld),
    .io_tlb_req_pmp_resp_ld(pf_io_tlb_req_pmp_resp_ld),
    .io_tlb_req_pmp_resp_mmio(pf_io_tlb_req_pmp_resp_mmio),
    .io_req_ready(pf_io_req_ready),
    .io_req_valid(pf_g_io_req_valid),
    .io_req_bits_tag(pf_g_io_req_bits_tag),
    .io_req_bits_set(pf_g_io_req_bits_set),
    .io_req_bits_vaddr(pf_g_io_req_bits_vaddr),
    .io_req_bits_needT(pf_g_io_req_bits_needT),
    .io_req_bits_source(pf_g_io_req_bits_source),
    .io_req_bits_pfSource(pf_g_io_req_bits_pfSource),
    .io_resp_ready(pf_g_io_resp_ready),
    .io_resp_valid(pf_io_resp_valid),
    .io_resp_bits_pfSource(pf_io_resp_bits_pfSource),
    .io_recv_addr_valid(pf_io_recv_addr_valid),
    .io_recv_addr_bits_addr(pf_io_recv_addr_bits_addr),
    .io_recv_addr_bits_pfSource(pf_io_recv_addr_bits_pfSource),
    .pfCtrlFromCore_l2_pf_master_en(pf_pfCtrlFromCore_l2_pf_master_en),
    .pfCtrlFromCore_l2_pf_recv_en(pf_pfCtrlFromCore_l2_pf_recv_en),
    .pfCtrlFromCore_l2_pbop_en(pf_pfCtrlFromCore_l2_pbop_en),
    .pfCtrlFromCore_l2_vbop_en(pf_pfCtrlFromCore_l2_vbop_en),
    .pfCtrlFromCore_l2_pf_delay_latency(pf_pfCtrlFromCore_l2_pf_delay_latency),
    .sigFromSrams_bore_ram_hold(pf_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(pf_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(pf_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(pf_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(pf_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(pf_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(pf_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(pf_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(pf_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(pf_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(pf_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(pf_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(pf_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(pf_sigFromSrams_bore_1_cgen),
    .boreChildrenBd_bore_array(pf_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(pf_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(pf_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(pf_g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(pf_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(pf_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(pf_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(pf_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(pf_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(pf_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(pf_g_boreChildrenBd_bore_outdata)
  );
  Prefetcher_xs pf_u_impl (
    .clock(clk),
    .reset(pf_reset),
    .io_train_ready(pf_i_io_train_ready),
    .io_train_valid(pf_io_train_valid),
    .io_train_bits_tag(pf_io_train_bits_tag),
    .io_train_bits_set(pf_io_train_bits_set),
    .io_train_bits_needT(pf_io_train_bits_needT),
    .io_train_bits_source(pf_io_train_bits_source),
    .io_train_bits_vaddr(pf_io_train_bits_vaddr),
    .io_train_bits_reqsource(pf_io_train_bits_reqsource),
    .io_tlb_req_req_valid(pf_i_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(pf_i_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_cmd(pf_i_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_isPrefetch(pf_i_io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_kill(pf_i_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_no_translate(pf_i_io_tlb_req_req_bits_no_translate),
    .io_tlb_req_resp_valid(pf_io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(pf_io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt(pf_io_tlb_req_resp_bits_pbmt),
    .io_tlb_req_resp_bits_miss(pf_io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(pf_io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(pf_io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(pf_io_tlb_req_resp_bits_excp_0_af_ld),
    .io_tlb_req_pmp_resp_ld(pf_io_tlb_req_pmp_resp_ld),
    .io_tlb_req_pmp_resp_mmio(pf_io_tlb_req_pmp_resp_mmio),
    .io_req_ready(pf_io_req_ready),
    .io_req_valid(pf_i_io_req_valid),
    .io_req_bits_tag(pf_i_io_req_bits_tag),
    .io_req_bits_set(pf_i_io_req_bits_set),
    .io_req_bits_vaddr(pf_i_io_req_bits_vaddr),
    .io_req_bits_needT(pf_i_io_req_bits_needT),
    .io_req_bits_source(pf_i_io_req_bits_source),
    .io_req_bits_pfSource(pf_i_io_req_bits_pfSource),
    .io_resp_ready(pf_i_io_resp_ready),
    .io_resp_valid(pf_io_resp_valid),
    .io_resp_bits_pfSource(pf_io_resp_bits_pfSource),
    .io_recv_addr_valid(pf_io_recv_addr_valid),
    .io_recv_addr_bits_addr(pf_io_recv_addr_bits_addr),
    .io_recv_addr_bits_pfSource(pf_io_recv_addr_bits_pfSource),
    .pfCtrlFromCore_l2_pf_master_en(pf_pfCtrlFromCore_l2_pf_master_en),
    .pfCtrlFromCore_l2_pf_recv_en(pf_pfCtrlFromCore_l2_pf_recv_en),
    .pfCtrlFromCore_l2_pbop_en(pf_pfCtrlFromCore_l2_pbop_en),
    .pfCtrlFromCore_l2_vbop_en(pf_pfCtrlFromCore_l2_vbop_en),
    .pfCtrlFromCore_l2_pf_delay_latency(pf_pfCtrlFromCore_l2_pf_delay_latency),
    .sigFromSrams_bore_ram_hold(pf_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(pf_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(pf_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(pf_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(pf_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(pf_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(pf_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(pf_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(pf_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(pf_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(pf_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(pf_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(pf_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(pf_sigFromSrams_bore_1_cgen),
    .boreChildrenBd_bore_array(pf_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(pf_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(pf_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(pf_i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(pf_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(pf_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(pf_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(pf_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(pf_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(pf_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(pf_i_boreChildrenBd_bore_outdata)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) pf_mode = $urandom_range(0, 15);
      pf_io_train_valid = 1'($urandom);
      pf_io_train_bits_tag = 33'({$urandom, $urandom});
      pf_io_train_bits_set = 9'($urandom);
      pf_io_train_bits_needT = 1'($urandom);
      pf_io_train_bits_source = 7'($urandom);
      pf_io_train_bits_vaddr = 44'({$urandom, $urandom});
      pf_io_train_bits_reqsource = 5'($urandom);
      pf_io_tlb_req_resp_valid = 1'($urandom);
      pf_io_tlb_req_resp_bits_paddr_0 = 48'({$urandom, $urandom});
      pf_io_tlb_req_resp_bits_pbmt = 2'($urandom);
      pf_io_tlb_req_resp_bits_miss = 1'($urandom);
      pf_io_tlb_req_resp_bits_excp_0_gpf_ld = 1'($urandom);
      pf_io_tlb_req_resp_bits_excp_0_pf_ld = 1'($urandom);
      pf_io_tlb_req_resp_bits_excp_0_af_ld = 1'($urandom);
      pf_io_tlb_req_pmp_resp_ld = 1'($urandom);
      pf_io_tlb_req_pmp_resp_mmio = 1'($urandom);
      pf_io_req_ready = 1'($urandom);
      pf_io_resp_valid = 1'($urandom);
      pf_io_resp_bits_pfSource = 5'($urandom);
      pf_io_recv_addr_valid = 1'($urandom);
      pf_io_recv_addr_bits_addr = 64'({$urandom, $urandom});
      pf_io_recv_addr_bits_pfSource = 5'($urandom);
      pf_pfCtrlFromCore_l2_pf_master_en = 1'($urandom);
      pf_pfCtrlFromCore_l2_pf_recv_en = 1'($urandom);
      pf_pfCtrlFromCore_l2_pbop_en = 1'($urandom);
      pf_pfCtrlFromCore_l2_vbop_en = 1'($urandom);
      pf_pfCtrlFromCore_l2_pf_delay_latency = 10'($urandom);
      pf_sigFromSrams_bore_ram_hold = 1'($urandom);
      pf_sigFromSrams_bore_ram_bypass = 1'($urandom);
      pf_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      pf_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      pf_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      pf_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      pf_sigFromSrams_bore_cgen = 1'($urandom);
      pf_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      pf_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      pf_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      pf_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      pf_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      pf_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      pf_sigFromSrams_bore_1_cgen = 1'($urandom);
      pf_boreChildrenBd_bore_array = 1'($urandom);
      pf_boreChildrenBd_bore_all = 1'($urandom);
      pf_boreChildrenBd_bore_req = 1'($urandom);
      pf_boreChildrenBd_bore_writeen = 1'($urandom);
      pf_boreChildrenBd_bore_be = 1'($urandom);
      pf_boreChildrenBd_bore_addr = 9'($urandom);
      pf_boreChildrenBd_bore_indata = 13'($urandom);
      pf_boreChildrenBd_bore_readen = 1'($urandom);
      pf_boreChildrenBd_bore_addr_rd = 9'($urandom);
      pf_reset = (cyc < RESET_CYC) || ($urandom_range(0, 49999) == 0);
      begin : stim_pf
        pf_pfCtrlFromCore_l2_pf_master_en = ($urandom_range(0, 15) != 0);
        pf_pfCtrlFromCore_l2_pf_recv_en = ($urandom_range(0, 7) != 0);
        pf_pfCtrlFromCore_l2_pbop_en = ($urandom_range(0, 7) != 0);
        pf_pfCtrlFromCore_l2_vbop_en = ($urandom_range(0, 7) != 0);
        pf_pfCtrlFromCore_l2_pf_delay_latency = 10'($urandom_range(0, 15));
        pf_io_train_valid = ($urandom_range(0, 1) != 0);
        begin logic [43:0] b; b = pf_blk(); pf_io_train_bits_vaddr = b; pf_io_train_bits_tag = b[41:9]; pf_io_train_bits_set = b[8:0]; end
        pf_io_train_bits_reqsource = ($urandom_range(0, 3) == 0) ? 5'd6 : 5'($urandom_range(0, 15));
        pf_io_req_ready = (pf_mode == 1 || cyc < 6000) ? 1'b0 : ($urandom_range(0, 3) != 0);
        pf_io_tlb_req_resp_valid = pf_tlb_q;
        pf_tlb_q = pf_g_io_tlb_req_req_valid;
        pf_io_tlb_req_resp_bits_miss = ($urandom_range(0, 3) == 0);
        pf_io_tlb_req_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 19) == 0);
        pf_io_tlb_req_resp_bits_excp_0_pf_ld = ($urandom_range(0, 19) == 0);
        pf_io_tlb_req_resp_bits_excp_0_af_ld = ($urandom_range(0, 19) == 0);
        pf_io_tlb_req_pmp_resp_ld = ($urandom_range(0, 9) == 0);
        pf_io_tlb_req_pmp_resp_mmio = ($urandom_range(0, 9) == 0);
        case ($urandom_range(0, 7))
          0, 1, 2: pf_io_resp_bits_pfSource = 5'd8;
          3, 4, 5: pf_io_resp_bits_pfSource = 5'd9;
          default: ;
        endcase
        pf_io_recv_addr_valid = ($urandom_range(0, 3) == 0);
        case ($urandom_range(0, 7))
          0, 1: pf_io_recv_addr_bits_pfSource = 5'd10;
          2, 3: pf_io_recv_addr_bits_pfSource = 5'd11;
          4:    pf_io_recv_addr_bits_pfSource = 5'd12;
          5, 6: pf_io_recv_addr_bits_pfSource = 5'd14;
          default: ;   // 1/8 随机值：Scala 的 assert 只在仿真里报，硬件照样透传（让 pfSource 高位也翻到）
        endcase
        if (pf_mode == 1 || cyc < 6000) begin   // mode 1（与开头 6000 拍）：pfRcv 连续出请求，vbop/pbop 一直让路，把 vbop reqFilter 16 项塞满
          pf_io_recv_addr_valid = 1'b1;
          pf_pfCtrlFromCore_l2_pf_master_en = 1'b1;
          pf_pfCtrlFromCore_l2_pf_recv_en = 1'b1;
        end
        if (pf_mode != 0) begin
          pf_boreChildrenBd_bore_array = '0;
          pf_boreChildrenBd_bore_all = '0;
          pf_boreChildrenBd_bore_req = '0;
          pf_boreChildrenBd_bore_writeen = '0;
          pf_boreChildrenBd_bore_be = '0;
          pf_boreChildrenBd_bore_readen = '0;
          pf_sigFromSrams_bore_ram_hold = '0;
          pf_sigFromSrams_bore_ram_bypass = '0;
          pf_sigFromSrams_bore_ram_bp_clken = '0;
          pf_sigFromSrams_bore_ram_aux_clk = '0;
          pf_sigFromSrams_bore_ram_aux_ckbp = '0;
          pf_sigFromSrams_bore_ram_mcp_hold = '0;
          pf_sigFromSrams_bore_cgen = '0;
          pf_sigFromSrams_bore_1_ram_hold = '0;
          pf_sigFromSrams_bore_1_ram_bypass = '0;
          pf_sigFromSrams_bore_1_ram_bp_clken = '0;
          pf_sigFromSrams_bore_1_ram_aux_clk = '0;
          pf_sigFromSrams_bore_1_ram_aux_ckbp = '0;
          pf_sigFromSrams_bore_1_ram_mcp_hold = '0;
          pf_sigFromSrams_bore_1_cgen = '0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && pf_armed_at >= 0 && cyc >= pf_armed_at) begin
        checks++;
        if (pf_g_io_train_ready !== pf_i_io_train_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_train_ready g=%h i=%h", cyc, pf_g_io_train_ready, pf_i_io_train_ready);
        end
        pf_s1_io_train_ready |= pf_g_io_train_ready;
        pf_s0_io_train_ready |= ~pf_g_io_train_ready;
        checks++;
        if (pf_g_io_tlb_req_req_valid !== pf_i_io_tlb_req_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_tlb_req_req_valid g=%h i=%h", cyc, pf_g_io_tlb_req_req_valid, pf_i_io_tlb_req_req_valid);
        end
        pf_s1_io_tlb_req_req_valid |= pf_g_io_tlb_req_req_valid;
        pf_s0_io_tlb_req_req_valid |= ~pf_g_io_tlb_req_req_valid;
        checks++;
        if (pf_g_io_tlb_req_req_bits_vaddr !== pf_i_io_tlb_req_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_tlb_req_req_bits_vaddr g=%h i=%h", cyc, pf_g_io_tlb_req_req_bits_vaddr, pf_i_io_tlb_req_req_bits_vaddr);
        end
        pf_s1_io_tlb_req_req_bits_vaddr |= pf_g_io_tlb_req_req_bits_vaddr;
        pf_s0_io_tlb_req_req_bits_vaddr |= ~pf_g_io_tlb_req_req_bits_vaddr;
        checks++;
        if (pf_g_io_tlb_req_req_bits_cmd !== pf_i_io_tlb_req_req_bits_cmd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_tlb_req_req_bits_cmd g=%h i=%h", cyc, pf_g_io_tlb_req_req_bits_cmd, pf_i_io_tlb_req_req_bits_cmd);
        end
        pf_s1_io_tlb_req_req_bits_cmd |= pf_g_io_tlb_req_req_bits_cmd;
        pf_s0_io_tlb_req_req_bits_cmd |= ~pf_g_io_tlb_req_req_bits_cmd;
        checks++;
        if (pf_g_io_tlb_req_req_bits_isPrefetch !== pf_i_io_tlb_req_req_bits_isPrefetch) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_tlb_req_req_bits_isPrefetch g=%h i=%h", cyc, pf_g_io_tlb_req_req_bits_isPrefetch, pf_i_io_tlb_req_req_bits_isPrefetch);
        end
        pf_s1_io_tlb_req_req_bits_isPrefetch |= pf_g_io_tlb_req_req_bits_isPrefetch;
        pf_s0_io_tlb_req_req_bits_isPrefetch |= ~pf_g_io_tlb_req_req_bits_isPrefetch;
        checks++;
        if (pf_g_io_tlb_req_req_bits_kill !== pf_i_io_tlb_req_req_bits_kill) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_tlb_req_req_bits_kill g=%h i=%h", cyc, pf_g_io_tlb_req_req_bits_kill, pf_i_io_tlb_req_req_bits_kill);
        end
        pf_s1_io_tlb_req_req_bits_kill |= pf_g_io_tlb_req_req_bits_kill;
        pf_s0_io_tlb_req_req_bits_kill |= ~pf_g_io_tlb_req_req_bits_kill;
        checks++;
        if (pf_g_io_tlb_req_req_bits_no_translate !== pf_i_io_tlb_req_req_bits_no_translate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_tlb_req_req_bits_no_translate g=%h i=%h", cyc, pf_g_io_tlb_req_req_bits_no_translate, pf_i_io_tlb_req_req_bits_no_translate);
        end
        pf_s1_io_tlb_req_req_bits_no_translate |= pf_g_io_tlb_req_req_bits_no_translate;
        pf_s0_io_tlb_req_req_bits_no_translate |= ~pf_g_io_tlb_req_req_bits_no_translate;
        checks++;
        if (pf_g_io_req_valid !== pf_i_io_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_req_valid g=%h i=%h", cyc, pf_g_io_req_valid, pf_i_io_req_valid);
        end
        pf_s1_io_req_valid |= pf_g_io_req_valid;
        pf_s0_io_req_valid |= ~pf_g_io_req_valid;
        checks++;
        if (pf_g_io_req_bits_tag !== pf_i_io_req_bits_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_req_bits_tag g=%h i=%h", cyc, pf_g_io_req_bits_tag, pf_i_io_req_bits_tag);
        end
        pf_s1_io_req_bits_tag |= pf_g_io_req_bits_tag;
        pf_s0_io_req_bits_tag |= ~pf_g_io_req_bits_tag;
        checks++;
        if (pf_g_io_req_bits_set !== pf_i_io_req_bits_set) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_req_bits_set g=%h i=%h", cyc, pf_g_io_req_bits_set, pf_i_io_req_bits_set);
        end
        pf_s1_io_req_bits_set |= pf_g_io_req_bits_set;
        pf_s0_io_req_bits_set |= ~pf_g_io_req_bits_set;
        checks++;
        if (pf_g_io_req_bits_vaddr !== pf_i_io_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_req_bits_vaddr g=%h i=%h", cyc, pf_g_io_req_bits_vaddr, pf_i_io_req_bits_vaddr);
        end
        pf_s1_io_req_bits_vaddr |= pf_g_io_req_bits_vaddr;
        pf_s0_io_req_bits_vaddr |= ~pf_g_io_req_bits_vaddr;
        checks++;
        if (pf_g_io_req_bits_needT !== pf_i_io_req_bits_needT) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_req_bits_needT g=%h i=%h", cyc, pf_g_io_req_bits_needT, pf_i_io_req_bits_needT);
        end
        pf_s1_io_req_bits_needT |= pf_g_io_req_bits_needT;
        pf_s0_io_req_bits_needT |= ~pf_g_io_req_bits_needT;
        checks++;
        if (pf_g_io_req_bits_source !== pf_i_io_req_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_req_bits_source g=%h i=%h", cyc, pf_g_io_req_bits_source, pf_i_io_req_bits_source);
        end
        pf_s1_io_req_bits_source |= pf_g_io_req_bits_source;
        pf_s0_io_req_bits_source |= ~pf_g_io_req_bits_source;
        checks++;
        if (pf_g_io_req_bits_pfSource !== pf_i_io_req_bits_pfSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_req_bits_pfSource g=%h i=%h", cyc, pf_g_io_req_bits_pfSource, pf_i_io_req_bits_pfSource);
        end
        pf_s1_io_req_bits_pfSource |= pf_g_io_req_bits_pfSource;
        pf_s0_io_req_bits_pfSource |= ~pf_g_io_req_bits_pfSource;
        checks++;
        if (pf_g_io_resp_ready !== pf_i_io_resp_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.io_resp_ready g=%h i=%h", cyc, pf_g_io_resp_ready, pf_i_io_resp_ready);
        end
        pf_s1_io_resp_ready |= pf_g_io_resp_ready;
        pf_s0_io_resp_ready |= ~pf_g_io_resp_ready;
        checks++;
        if (pf_g_boreChildrenBd_bore_ack !== pf_i_boreChildrenBd_bore_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.boreChildrenBd_bore_ack g=%h i=%h", cyc, pf_g_boreChildrenBd_bore_ack, pf_i_boreChildrenBd_bore_ack);
        end
        pf_s1_boreChildrenBd_bore_ack |= pf_g_boreChildrenBd_bore_ack;
        pf_s0_boreChildrenBd_bore_ack |= ~pf_g_boreChildrenBd_bore_ack;
        checks++;
        if (pf_g_boreChildrenBd_bore_outdata !== pf_i_boreChildrenBd_bore_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Prefetcher.boreChildrenBd_bore_outdata g=%h i=%h", cyc, pf_g_boreChildrenBd_bore_outdata, pf_i_boreChildrenBd_bore_outdata);
        end
        pf_s1_boreChildrenBd_bore_outdata |= pf_g_boreChildrenBd_bore_outdata;
        pf_s0_boreChildrenBd_bore_outdata |= ~pf_g_boreChildrenBd_bore_outdata;
        if (pf_io_train_valid && pf_io_train_bits_reqsource == 5'd6) pf_cov_train_filtered++;
        if (pf_u_gold._pbop_io_req_valid) pf_cov_pbop_req++;
        if (pf_u_gold._vbop_io_req_valid) pf_cov_vbop_req++;
        if (pf_u_gold._pfRcv_io_req_valid) pf_cov_rcv_req++;
        if (pf_u_gold._vbop_io_req_valid && pf_u_gold._pfRcv_io_req_valid) pf_cov_vbop_yield_rcv++;
        if (pf_u_gold._pbop_io_req_valid && pf_u_gold._vbop_io_req_valid) pf_cov_pbop_yield_vbop++;
        if (pf_io_resp_valid && pf_io_resp_bits_pfSource == 5'd9) pf_cov_resp_pbop++;
        if (pf_io_resp_valid && pf_io_resp_bits_pfSource == 5'd8) pf_cov_resp_vbop++;
        if (!pf_u_gold.pfRcv_en && pf_u_gold.pfRcv_io_recv_addr_v_last_REG_1) pf_cov_rcv_disabled++;
        if (pf_g_io_tlb_req_req_valid) pf_cov_tlb_req++;
        if (pf_g_io_req_valid && pf_io_req_ready) pf_cov_req_fire++;
        if (pf_g_io_req_valid && !pf_io_req_ready) pf_cov_req_stall++;
        if (pf_g_boreChildrenBd_bore_outdata != 0) pf_cov_bore_outdata_nz++;
      end
      if (pf_io_train_valid && pf_g_io_train_ready) pf_armed[0] = 1'b1;
      if (pf_u_gold.pbop.rrTable.rrTable.respReg) pf_armed[1] = 1'b1;
      if (pf_u_gold.vbop._s0_fire_T) pf_armed[2] = 1'b1;
      if (pf_u_gold.vbop.rrTable.rrTable.respReg) pf_armed[3] = 1'b1;
      if (pf_g_io_tlb_req_req_valid) pf_armed[4] = 1'b1;
      if (&pf_alloc_seen) pf_armed[5] = 1'b1;
      if (pf_g_io_req_valid) pf_armed[6] = 1'b1;
      if (pf_armed_at < 0 && (&pf_armed)) pf_armed_at = cyc + 1 + 1;
    end

    // ---- 覆盖闸 ----
    if (!(pf_s0_io_train_ready && pf_s1_io_train_ready)) begin cov_fail++; $display("[COV] Prefetcher.io_train_ready 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_valid && pf_s1_io_tlb_req_req_valid)) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_valid 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[6] && pf_s1_io_tlb_req_req_bits_vaddr[6])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[7] && pf_s1_io_tlb_req_req_bits_vaddr[7])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[8] && pf_s1_io_tlb_req_req_bits_vaddr[8])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[9] && pf_s1_io_tlb_req_req_bits_vaddr[9])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[10] && pf_s1_io_tlb_req_req_bits_vaddr[10])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[11] && pf_s1_io_tlb_req_req_bits_vaddr[11])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[12] && pf_s1_io_tlb_req_req_bits_vaddr[12])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[13] && pf_s1_io_tlb_req_req_bits_vaddr[13])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[14] && pf_s1_io_tlb_req_req_bits_vaddr[14])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[15] && pf_s1_io_tlb_req_req_bits_vaddr[15])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[16] && pf_s1_io_tlb_req_req_bits_vaddr[16])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[17] && pf_s1_io_tlb_req_req_bits_vaddr[17])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[18] && pf_s1_io_tlb_req_req_bits_vaddr[18])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[19] && pf_s1_io_tlb_req_req_bits_vaddr[19])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[20] && pf_s1_io_tlb_req_req_bits_vaddr[20])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[21] && pf_s1_io_tlb_req_req_bits_vaddr[21])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[22] && pf_s1_io_tlb_req_req_bits_vaddr[22])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[23] && pf_s1_io_tlb_req_req_bits_vaddr[23])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[24] && pf_s1_io_tlb_req_req_bits_vaddr[24])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[25] && pf_s1_io_tlb_req_req_bits_vaddr[25])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[26] && pf_s1_io_tlb_req_req_bits_vaddr[26])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[27] && pf_s1_io_tlb_req_req_bits_vaddr[27])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[28] && pf_s1_io_tlb_req_req_bits_vaddr[28])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[29] && pf_s1_io_tlb_req_req_bits_vaddr[29])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[30] && pf_s1_io_tlb_req_req_bits_vaddr[30])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[31] && pf_s1_io_tlb_req_req_bits_vaddr[31])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[32] && pf_s1_io_tlb_req_req_bits_vaddr[32])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[33] && pf_s1_io_tlb_req_req_bits_vaddr[33])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[34] && pf_s1_io_tlb_req_req_bits_vaddr[34])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[35] && pf_s1_io_tlb_req_req_bits_vaddr[35])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[36] && pf_s1_io_tlb_req_req_bits_vaddr[36])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[37] && pf_s1_io_tlb_req_req_bits_vaddr[37])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[38] && pf_s1_io_tlb_req_req_bits_vaddr[38])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[39] && pf_s1_io_tlb_req_req_bits_vaddr[39])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[40] && pf_s1_io_tlb_req_req_bits_vaddr[40])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[41] && pf_s1_io_tlb_req_req_bits_vaddr[41])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[42] && pf_s1_io_tlb_req_req_bits_vaddr[42])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[43] && pf_s1_io_tlb_req_req_bits_vaddr[43])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[44] && pf_s1_io_tlb_req_req_bits_vaddr[44])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[44] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[45] && pf_s1_io_tlb_req_req_bits_vaddr[45])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[46] && pf_s1_io_tlb_req_req_bits_vaddr[46])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[47] && pf_s1_io_tlb_req_req_bits_vaddr[47])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[48] && pf_s1_io_tlb_req_req_bits_vaddr[48])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[48] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_req_bits_vaddr[49] && pf_s1_io_tlb_req_req_bits_vaddr[49])) begin cov_fail++; $display("[COV] Prefetcher.io_tlb_req_req_bits_vaddr[49] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_valid && pf_s1_io_req_valid)) begin cov_fail++; $display("[COV] Prefetcher.io_req_valid 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[0] && pf_s1_io_req_bits_tag[0])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[1] && pf_s1_io_req_bits_tag[1])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[2] && pf_s1_io_req_bits_tag[2])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[3] && pf_s1_io_req_bits_tag[3])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[4] && pf_s1_io_req_bits_tag[4])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[5] && pf_s1_io_req_bits_tag[5])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[6] && pf_s1_io_req_bits_tag[6])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[7] && pf_s1_io_req_bits_tag[7])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[8] && pf_s1_io_req_bits_tag[8])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[9] && pf_s1_io_req_bits_tag[9])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[10] && pf_s1_io_req_bits_tag[10])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[11] && pf_s1_io_req_bits_tag[11])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[12] && pf_s1_io_req_bits_tag[12])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[13] && pf_s1_io_req_bits_tag[13])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[14] && pf_s1_io_req_bits_tag[14])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[15] && pf_s1_io_req_bits_tag[15])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[16] && pf_s1_io_req_bits_tag[16])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[17] && pf_s1_io_req_bits_tag[17])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[18] && pf_s1_io_req_bits_tag[18])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[19] && pf_s1_io_req_bits_tag[19])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[20] && pf_s1_io_req_bits_tag[20])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[21] && pf_s1_io_req_bits_tag[21])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[22] && pf_s1_io_req_bits_tag[22])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[23] && pf_s1_io_req_bits_tag[23])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[24] && pf_s1_io_req_bits_tag[24])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[25] && pf_s1_io_req_bits_tag[25])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[26] && pf_s1_io_req_bits_tag[26])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[27] && pf_s1_io_req_bits_tag[27])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[28] && pf_s1_io_req_bits_tag[28])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[29] && pf_s1_io_req_bits_tag[29])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[30] && pf_s1_io_req_bits_tag[30])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[31] && pf_s1_io_req_bits_tag[31])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_tag[32] && pf_s1_io_req_bits_tag[32])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_tag[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_set[0] && pf_s1_io_req_bits_set[0])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_set[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_set[1] && pf_s1_io_req_bits_set[1])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_set[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_set[2] && pf_s1_io_req_bits_set[2])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_set[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_set[3] && pf_s1_io_req_bits_set[3])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_set[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_set[4] && pf_s1_io_req_bits_set[4])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_set[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_set[5] && pf_s1_io_req_bits_set[5])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_set[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_set[6] && pf_s1_io_req_bits_set[6])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_set[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_set[7] && pf_s1_io_req_bits_set[7])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_set[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_set[8] && pf_s1_io_req_bits_set[8])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_set[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[0] && pf_s1_io_req_bits_vaddr[0])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[1] && pf_s1_io_req_bits_vaddr[1])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[2] && pf_s1_io_req_bits_vaddr[2])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[3] && pf_s1_io_req_bits_vaddr[3])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[4] && pf_s1_io_req_bits_vaddr[4])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[5] && pf_s1_io_req_bits_vaddr[5])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[6] && pf_s1_io_req_bits_vaddr[6])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[7] && pf_s1_io_req_bits_vaddr[7])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[8] && pf_s1_io_req_bits_vaddr[8])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[9] && pf_s1_io_req_bits_vaddr[9])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[10] && pf_s1_io_req_bits_vaddr[10])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[11] && pf_s1_io_req_bits_vaddr[11])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[12] && pf_s1_io_req_bits_vaddr[12])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[13] && pf_s1_io_req_bits_vaddr[13])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[14] && pf_s1_io_req_bits_vaddr[14])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[15] && pf_s1_io_req_bits_vaddr[15])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[16] && pf_s1_io_req_bits_vaddr[16])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[17] && pf_s1_io_req_bits_vaddr[17])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[18] && pf_s1_io_req_bits_vaddr[18])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[19] && pf_s1_io_req_bits_vaddr[19])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[20] && pf_s1_io_req_bits_vaddr[20])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[21] && pf_s1_io_req_bits_vaddr[21])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[22] && pf_s1_io_req_bits_vaddr[22])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[23] && pf_s1_io_req_bits_vaddr[23])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[24] && pf_s1_io_req_bits_vaddr[24])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[25] && pf_s1_io_req_bits_vaddr[25])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[26] && pf_s1_io_req_bits_vaddr[26])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[27] && pf_s1_io_req_bits_vaddr[27])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[28] && pf_s1_io_req_bits_vaddr[28])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[29] && pf_s1_io_req_bits_vaddr[29])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[30] && pf_s1_io_req_bits_vaddr[30])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[31] && pf_s1_io_req_bits_vaddr[31])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[32] && pf_s1_io_req_bits_vaddr[32])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[33] && pf_s1_io_req_bits_vaddr[33])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[34] && pf_s1_io_req_bits_vaddr[34])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[35] && pf_s1_io_req_bits_vaddr[35])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[36] && pf_s1_io_req_bits_vaddr[36])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[37] && pf_s1_io_req_bits_vaddr[37])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[38] && pf_s1_io_req_bits_vaddr[38])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[39] && pf_s1_io_req_bits_vaddr[39])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[40] && pf_s1_io_req_bits_vaddr[40])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[41] && pf_s1_io_req_bits_vaddr[41])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[42] && pf_s1_io_req_bits_vaddr[42])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_vaddr[43] && pf_s1_io_req_bits_vaddr[43])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_needT && pf_s1_io_req_bits_needT)) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_needT 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_source[0] && pf_s1_io_req_bits_source[0])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_source[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_source[1] && pf_s1_io_req_bits_source[1])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_source[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_source[2] && pf_s1_io_req_bits_source[2])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_source[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_source[3] && pf_s1_io_req_bits_source[3])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_source[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_source[4] && pf_s1_io_req_bits_source[4])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_source[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_source[5] && pf_s1_io_req_bits_source[5])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_source[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_source[6] && pf_s1_io_req_bits_source[6])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_source[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_pfSource[0] && pf_s1_io_req_bits_pfSource[0])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_pfSource[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_pfSource[1] && pf_s1_io_req_bits_pfSource[1])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_pfSource[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_pfSource[2] && pf_s1_io_req_bits_pfSource[2])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_pfSource[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_pfSource[3] && pf_s1_io_req_bits_pfSource[3])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_pfSource[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_req_bits_pfSource[4] && pf_s1_io_req_bits_pfSource[4])) begin cov_fail++; $display("[COV] Prefetcher.io_req_bits_pfSource[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_resp_ready && pf_s1_io_resp_ready)) begin cov_fail++; $display("[COV] Prefetcher.io_resp_ready 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_ack && pf_s1_boreChildrenBd_bore_ack)) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_ack 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[0] && pf_s1_boreChildrenBd_bore_outdata[0])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[0] 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[1] && pf_s1_boreChildrenBd_bore_outdata[1])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[1] 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[2] && pf_s1_boreChildrenBd_bore_outdata[2])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[2] 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[3] && pf_s1_boreChildrenBd_bore_outdata[3])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[3] 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[4] && pf_s1_boreChildrenBd_bore_outdata[4])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[4] 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[5] && pf_s1_boreChildrenBd_bore_outdata[5])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[5] 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[6] && pf_s1_boreChildrenBd_bore_outdata[6])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[6] 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[7] && pf_s1_boreChildrenBd_bore_outdata[7])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[7] 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[8] && pf_s1_boreChildrenBd_bore_outdata[8])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[8] 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[9] && pf_s1_boreChildrenBd_bore_outdata[9])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[9] 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[10] && pf_s1_boreChildrenBd_bore_outdata[10])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[10] 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[11] && pf_s1_boreChildrenBd_bore_outdata[11])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[11] 未见过 0 和 1"); end
    if (!(pf_s0_boreChildrenBd_bore_outdata[12] && pf_s1_boreChildrenBd_bore_outdata[12])) begin cov_fail++; $display("[COV] Prefetcher.boreChildrenBd_bore_outdata[12] 未见过 0 和 1"); end
    $display("[ARM] Prefetcher armed_at=%0d", pf_armed_at);
    if (pf_armed_at < 0) begin cov_fail++; $display("[ARM] Prefetcher 从未 arm"); end
    $display("[COV] Prefetcher.train_filtered = %0d", pf_cov_train_filtered);
    if (pf_cov_train_filtered < 5) begin cov_fail++; $display("[COV] Prefetcher.train_filtered < 5"); end
    $display("[COV] Prefetcher.pbop_req = %0d", pf_cov_pbop_req);
    if (pf_cov_pbop_req < 5) begin cov_fail++; $display("[COV] Prefetcher.pbop_req < 5"); end
    $display("[COV] Prefetcher.vbop_req = %0d", pf_cov_vbop_req);
    if (pf_cov_vbop_req < 5) begin cov_fail++; $display("[COV] Prefetcher.vbop_req < 5"); end
    $display("[COV] Prefetcher.rcv_req = %0d", pf_cov_rcv_req);
    if (pf_cov_rcv_req < 5) begin cov_fail++; $display("[COV] Prefetcher.rcv_req < 5"); end
    $display("[COV] Prefetcher.vbop_yield_rcv = %0d", pf_cov_vbop_yield_rcv);
    if (pf_cov_vbop_yield_rcv < 5) begin cov_fail++; $display("[COV] Prefetcher.vbop_yield_rcv < 5"); end
    $display("[COV] Prefetcher.pbop_yield_vbop = %0d", pf_cov_pbop_yield_vbop);
    if (pf_cov_pbop_yield_vbop < 5) begin cov_fail++; $display("[COV] Prefetcher.pbop_yield_vbop < 5"); end
    $display("[COV] Prefetcher.resp_pbop = %0d", pf_cov_resp_pbop);
    if (pf_cov_resp_pbop < 5) begin cov_fail++; $display("[COV] Prefetcher.resp_pbop < 5"); end
    $display("[COV] Prefetcher.resp_vbop = %0d", pf_cov_resp_vbop);
    if (pf_cov_resp_vbop < 5) begin cov_fail++; $display("[COV] Prefetcher.resp_vbop < 5"); end
    $display("[COV] Prefetcher.rcv_disabled = %0d", pf_cov_rcv_disabled);
    if (pf_cov_rcv_disabled < 5) begin cov_fail++; $display("[COV] Prefetcher.rcv_disabled < 5"); end
    $display("[COV] Prefetcher.tlb_req = %0d", pf_cov_tlb_req);
    if (pf_cov_tlb_req < 5) begin cov_fail++; $display("[COV] Prefetcher.tlb_req < 5"); end
    $display("[COV] Prefetcher.req_fire = %0d", pf_cov_req_fire);
    if (pf_cov_req_fire < 5) begin cov_fail++; $display("[COV] Prefetcher.req_fire < 5"); end
    $display("[COV] Prefetcher.req_stall = %0d", pf_cov_req_stall);
    if (pf_cov_req_stall < 5) begin cov_fail++; $display("[COV] Prefetcher.req_stall < 5"); end
    $display("[COV] Prefetcher.bore_outdata_nz = %0d", pf_cov_bore_outdata_nz);
    if (pf_cov_bore_outdata_nz < 5) begin cov_fail++; $display("[COV] Prefetcher.bore_outdata_nz < 5"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
