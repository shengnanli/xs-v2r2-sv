// 自动生成: gen_prefetcher_files.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP = 16;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_train_valid;
  logic [32:0] io_train_bits_tag;
  logic [8:0] io_train_bits_set;
  logic io_train_bits_needT;
  logic [6:0] io_train_bits_source;
  logic [43:0] io_train_bits_vaddr;
  logic [4:0] io_train_bits_reqsource;
  logic io_tlb_req_resp_valid;
  logic [47:0] io_tlb_req_resp_bits_paddr_0;
  logic [1:0] io_tlb_req_resp_bits_pbmt;
  logic io_tlb_req_resp_bits_miss;
  logic io_tlb_req_resp_bits_excp_0_gpf_ld;
  logic io_tlb_req_resp_bits_excp_0_pf_ld;
  logic io_tlb_req_resp_bits_excp_0_af_ld;
  logic io_tlb_req_pmp_resp_ld;
  logic io_tlb_req_pmp_resp_mmio;
  logic io_req_ready;
  logic io_resp_valid;
  logic [4:0] io_resp_bits_pfSource;
  logic io_recv_addr_valid;
  logic [63:0] io_recv_addr_bits_addr;
  logic [4:0] io_recv_addr_bits_pfSource;
  logic pfCtrlFromCore_l2_pf_master_en;
  logic pfCtrlFromCore_l2_pf_recv_en;
  logic pfCtrlFromCore_l2_pbop_en;
  logic pfCtrlFromCore_l2_vbop_en;
  logic sigFromSrams_bore_ram_hold;
  logic sigFromSrams_bore_ram_bypass;
  logic sigFromSrams_bore_ram_bp_clken;
  logic sigFromSrams_bore_ram_aux_clk;
  logic sigFromSrams_bore_ram_aux_ckbp;
  logic sigFromSrams_bore_ram_mcp_hold;
  logic sigFromSrams_bore_cgen;
  logic sigFromSrams_bore_1_ram_hold;
  logic sigFromSrams_bore_1_ram_bypass;
  logic sigFromSrams_bore_1_ram_bp_clken;
  logic sigFromSrams_bore_1_ram_aux_clk;
  logic sigFromSrams_bore_1_ram_aux_ckbp;
  logic sigFromSrams_bore_1_ram_mcp_hold;
  logic sigFromSrams_bore_1_cgen;
  logic boreChildrenBd_bore_array;
  logic boreChildrenBd_bore_all;
  logic boreChildrenBd_bore_req;
  logic boreChildrenBd_bore_writeen;
  logic boreChildrenBd_bore_be;
  logic [8:0] boreChildrenBd_bore_addr;
  logic [12:0] boreChildrenBd_bore_indata;
  logic boreChildrenBd_bore_readen;
  logic [8:0] boreChildrenBd_bore_addr_rd;
  logic g_io_train_ready;
  logic i_io_train_ready;
  logic g_io_tlb_req_req_valid;
  logic i_io_tlb_req_req_valid;
  logic [49:0] g_io_tlb_req_req_bits_vaddr;
  logic [49:0] i_io_tlb_req_req_bits_vaddr;
  logic [2:0] g_io_tlb_req_req_bits_cmd;
  logic [2:0] i_io_tlb_req_req_bits_cmd;
  logic g_io_tlb_req_req_bits_kill;
  logic i_io_tlb_req_req_bits_kill;
  logic g_io_tlb_req_req_bits_no_translate;
  logic i_io_tlb_req_req_bits_no_translate;
  logic g_io_req_valid;
  logic i_io_req_valid;
  logic [32:0] g_io_req_bits_tag;
  logic [32:0] i_io_req_bits_tag;
  logic [8:0] g_io_req_bits_set;
  logic [8:0] i_io_req_bits_set;
  logic [43:0] g_io_req_bits_vaddr;
  logic [43:0] i_io_req_bits_vaddr;
  logic g_io_req_bits_needT;
  logic i_io_req_bits_needT;
  logic [6:0] g_io_req_bits_source;
  logic [6:0] i_io_req_bits_source;
  logic [4:0] g_io_req_bits_pfSource;
  logic [4:0] i_io_req_bits_pfSource;
  logic g_io_resp_ready;
  logic i_io_resp_ready;
  logic g_boreChildrenBd_bore_ack;
  logic i_boreChildrenBd_bore_ack;
  logic [12:0] g_boreChildrenBd_bore_outdata;
  logic [12:0] i_boreChildrenBd_bore_outdata;

  Prefetcher dut_g (
    .clock(clk),
    .reset(rst),
    .io_train_valid(io_train_valid),
    .io_train_bits_tag(io_train_bits_tag),
    .io_train_bits_set(io_train_bits_set),
    .io_train_bits_needT(io_train_bits_needT),
    .io_train_bits_source(io_train_bits_source),
    .io_train_bits_vaddr(io_train_bits_vaddr),
    .io_train_bits_reqsource(io_train_bits_reqsource),
    .io_tlb_req_resp_valid(io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt(io_tlb_req_resp_bits_pbmt),
    .io_tlb_req_resp_bits_miss(io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(io_tlb_req_resp_bits_excp_0_af_ld),
    .io_tlb_req_pmp_resp_ld(io_tlb_req_pmp_resp_ld),
    .io_tlb_req_pmp_resp_mmio(io_tlb_req_pmp_resp_mmio),
    .io_req_ready(io_req_ready),
    .io_resp_valid(io_resp_valid),
    .io_resp_bits_pfSource(io_resp_bits_pfSource),
    .io_recv_addr_valid(io_recv_addr_valid),
    .io_recv_addr_bits_addr(io_recv_addr_bits_addr),
    .io_recv_addr_bits_pfSource(io_recv_addr_bits_pfSource),
    .pfCtrlFromCore_l2_pf_master_en(pfCtrlFromCore_l2_pf_master_en),
    .pfCtrlFromCore_l2_pf_recv_en(pfCtrlFromCore_l2_pf_recv_en),
    .pfCtrlFromCore_l2_pbop_en(pfCtrlFromCore_l2_pbop_en),
    .pfCtrlFromCore_l2_vbop_en(pfCtrlFromCore_l2_vbop_en),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .io_train_ready(g_io_train_ready),
    .io_tlb_req_req_valid(g_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(g_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_cmd(g_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_kill(g_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_no_translate(g_io_tlb_req_req_bits_no_translate),
    .io_req_valid(g_io_req_valid),
    .io_req_bits_tag(g_io_req_bits_tag),
    .io_req_bits_set(g_io_req_bits_set),
    .io_req_bits_vaddr(g_io_req_bits_vaddr),
    .io_req_bits_needT(g_io_req_bits_needT),
    .io_req_bits_source(g_io_req_bits_source),
    .io_req_bits_pfSource(g_io_req_bits_pfSource),
    .io_resp_ready(g_io_resp_ready),
    .boreChildrenBd_bore_ack(g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_outdata(g_boreChildrenBd_bore_outdata)
  );

  Prefetcher_xs dut_i (
    .clock(clk),
    .reset(rst),
    .io_train_valid(io_train_valid),
    .io_train_bits_tag(io_train_bits_tag),
    .io_train_bits_set(io_train_bits_set),
    .io_train_bits_needT(io_train_bits_needT),
    .io_train_bits_source(io_train_bits_source),
    .io_train_bits_vaddr(io_train_bits_vaddr),
    .io_train_bits_reqsource(io_train_bits_reqsource),
    .io_tlb_req_resp_valid(io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt(io_tlb_req_resp_bits_pbmt),
    .io_tlb_req_resp_bits_miss(io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(io_tlb_req_resp_bits_excp_0_af_ld),
    .io_tlb_req_pmp_resp_ld(io_tlb_req_pmp_resp_ld),
    .io_tlb_req_pmp_resp_mmio(io_tlb_req_pmp_resp_mmio),
    .io_req_ready(io_req_ready),
    .io_resp_valid(io_resp_valid),
    .io_resp_bits_pfSource(io_resp_bits_pfSource),
    .io_recv_addr_valid(io_recv_addr_valid),
    .io_recv_addr_bits_addr(io_recv_addr_bits_addr),
    .io_recv_addr_bits_pfSource(io_recv_addr_bits_pfSource),
    .pfCtrlFromCore_l2_pf_master_en(pfCtrlFromCore_l2_pf_master_en),
    .pfCtrlFromCore_l2_pf_recv_en(pfCtrlFromCore_l2_pf_recv_en),
    .pfCtrlFromCore_l2_pbop_en(pfCtrlFromCore_l2_pbop_en),
    .pfCtrlFromCore_l2_vbop_en(pfCtrlFromCore_l2_vbop_en),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .io_train_ready(i_io_train_ready),
    .io_tlb_req_req_valid(i_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(i_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_cmd(i_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_kill(i_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_no_translate(i_io_tlb_req_req_bits_no_translate),
    .io_req_valid(i_io_req_valid),
    .io_req_bits_tag(i_io_req_bits_tag),
    .io_req_bits_set(i_io_req_bits_set),
    .io_req_bits_vaddr(i_io_req_bits_vaddr),
    .io_req_bits_needT(i_io_req_bits_needT),
    .io_req_bits_source(i_io_req_bits_source),
    .io_req_bits_pfSource(i_io_req_bits_pfSource),
    .io_resp_ready(i_io_resp_ready),
    .boreChildrenBd_bore_ack(i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_outdata(i_boreChildrenBd_bore_outdata)
  );

  task automatic drive_random();
    io_train_valid = $random;
    io_train_bits_tag = $random;
    io_train_bits_set = $random;
    io_train_bits_needT = $random;
    io_train_bits_source = $random;
    io_train_bits_vaddr = $random;
    io_train_bits_reqsource = $random;
    io_tlb_req_resp_valid = $random;
    io_tlb_req_resp_bits_paddr_0 = $random;
    io_tlb_req_resp_bits_pbmt = $random;
    io_tlb_req_resp_bits_miss = $random;
    io_tlb_req_resp_bits_excp_0_gpf_ld = $random;
    io_tlb_req_resp_bits_excp_0_pf_ld = $random;
    io_tlb_req_resp_bits_excp_0_af_ld = $random;
    io_tlb_req_pmp_resp_ld = $random;
    io_tlb_req_pmp_resp_mmio = $random;
    io_req_ready = $random;
    io_resp_valid = $random;
    io_resp_bits_pfSource = $random;
    io_recv_addr_valid = $random;
    io_recv_addr_bits_addr = $random;
    io_recv_addr_bits_pfSource = $random;
    pfCtrlFromCore_l2_pf_master_en = $random;
    pfCtrlFromCore_l2_pf_recv_en = $random;
    pfCtrlFromCore_l2_pbop_en = $random;
    pfCtrlFromCore_l2_vbop_en = $random;
    sigFromSrams_bore_ram_hold = $random;
    sigFromSrams_bore_ram_bypass = $random;
    sigFromSrams_bore_ram_bp_clken = $random;
    sigFromSrams_bore_ram_aux_clk = $random;
    sigFromSrams_bore_ram_aux_ckbp = $random;
    sigFromSrams_bore_ram_mcp_hold = $random;
    sigFromSrams_bore_cgen = $random;
    sigFromSrams_bore_1_ram_hold = $random;
    sigFromSrams_bore_1_ram_bypass = $random;
    sigFromSrams_bore_1_ram_bp_clken = $random;
    sigFromSrams_bore_1_ram_aux_clk = $random;
    sigFromSrams_bore_1_ram_aux_ckbp = $random;
    sigFromSrams_bore_1_ram_mcp_hold = $random;
    sigFromSrams_bore_1_cgen = $random;
    boreChildrenBd_bore_array = $random;
    boreChildrenBd_bore_all = $random;
    boreChildrenBd_bore_req = $random;
    boreChildrenBd_bore_writeen = $random;
    boreChildrenBd_bore_be = $random;
    boreChildrenBd_bore_addr = $random;
    boreChildrenBd_bore_indata = $random;
    boreChildrenBd_bore_readen = $random;
    boreChildrenBd_bore_addr_rd = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_train_ready !== i_io_train_ready) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_train_ready: g=%h i=%h", cyc, g_io_train_ready, i_io_train_ready); end
    if (g_io_tlb_req_req_valid !== i_io_tlb_req_req_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_tlb_req_req_valid: g=%h i=%h", cyc, g_io_tlb_req_req_valid, i_io_tlb_req_req_valid); end
    if (g_io_tlb_req_req_bits_vaddr !== i_io_tlb_req_req_bits_vaddr) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_tlb_req_req_bits_vaddr: g=%h i=%h", cyc, g_io_tlb_req_req_bits_vaddr, i_io_tlb_req_req_bits_vaddr); end
    if (g_io_tlb_req_req_bits_cmd !== i_io_tlb_req_req_bits_cmd) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_tlb_req_req_bits_cmd: g=%h i=%h", cyc, g_io_tlb_req_req_bits_cmd, i_io_tlb_req_req_bits_cmd); end
    if (g_io_tlb_req_req_bits_kill !== i_io_tlb_req_req_bits_kill) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_tlb_req_req_bits_kill: g=%h i=%h", cyc, g_io_tlb_req_req_bits_kill, i_io_tlb_req_req_bits_kill); end
    if (g_io_tlb_req_req_bits_no_translate !== i_io_tlb_req_req_bits_no_translate) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_tlb_req_req_bits_no_translate: g=%h i=%h", cyc, g_io_tlb_req_req_bits_no_translate, i_io_tlb_req_req_bits_no_translate); end
    if (g_io_req_valid !== i_io_req_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_req_valid: g=%h i=%h", cyc, g_io_req_valid, i_io_req_valid); end
    if (g_io_req_bits_tag !== i_io_req_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_req_bits_tag: g=%h i=%h", cyc, g_io_req_bits_tag, i_io_req_bits_tag); end
    if (g_io_req_bits_set !== i_io_req_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_req_bits_set: g=%h i=%h", cyc, g_io_req_bits_set, i_io_req_bits_set); end
    if (g_io_req_bits_vaddr !== i_io_req_bits_vaddr) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_req_bits_vaddr: g=%h i=%h", cyc, g_io_req_bits_vaddr, i_io_req_bits_vaddr); end
    if (g_io_req_bits_needT !== i_io_req_bits_needT) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_req_bits_needT: g=%h i=%h", cyc, g_io_req_bits_needT, i_io_req_bits_needT); end
    if (g_io_req_bits_source !== i_io_req_bits_source) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_req_bits_source: g=%h i=%h", cyc, g_io_req_bits_source, i_io_req_bits_source); end
    if (g_io_req_bits_pfSource !== i_io_req_bits_pfSource) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_req_bits_pfSource: g=%h i=%h", cyc, g_io_req_bits_pfSource, i_io_req_bits_pfSource); end
    if (g_io_resp_ready !== i_io_resp_ready) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_resp_ready: g=%h i=%h", cyc, g_io_resp_ready, i_io_resp_ready); end
    if (g_boreChildrenBd_bore_ack !== i_boreChildrenBd_bore_ack) begin errors++; if (errors<=30) $display("[%0d] MISMATCH boreChildrenBd_bore_ack: g=%h i=%h", cyc, g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack); end
    if (g_boreChildrenBd_bore_outdata !== i_boreChildrenBd_bore_outdata) begin errors++; if (errors<=30) $display("[%0d] MISMATCH boreChildrenBd_bore_outdata: g=%h i=%h", cyc, g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata); end
  endtask

  initial begin
    rst = 1'b1;
    io_train_valid = '0;
    io_train_bits_tag = '0;
    io_train_bits_set = '0;
    io_train_bits_needT = '0;
    io_train_bits_source = '0;
    io_train_bits_vaddr = '0;
    io_train_bits_reqsource = '0;
    io_tlb_req_resp_valid = '0;
    io_tlb_req_resp_bits_paddr_0 = '0;
    io_tlb_req_resp_bits_pbmt = '0;
    io_tlb_req_resp_bits_miss = '0;
    io_tlb_req_resp_bits_excp_0_gpf_ld = '0;
    io_tlb_req_resp_bits_excp_0_pf_ld = '0;
    io_tlb_req_resp_bits_excp_0_af_ld = '0;
    io_tlb_req_pmp_resp_ld = '0;
    io_tlb_req_pmp_resp_mmio = '0;
    io_req_ready = '0;
    io_resp_valid = '0;
    io_resp_bits_pfSource = '0;
    io_recv_addr_valid = '0;
    io_recv_addr_bits_addr = '0;
    io_recv_addr_bits_pfSource = '0;
    pfCtrlFromCore_l2_pf_master_en = '0;
    pfCtrlFromCore_l2_pf_recv_en = '0;
    pfCtrlFromCore_l2_pbop_en = '0;
    pfCtrlFromCore_l2_vbop_en = '0;
    sigFromSrams_bore_ram_hold = '0;
    sigFromSrams_bore_ram_bypass = '0;
    sigFromSrams_bore_ram_bp_clken = '0;
    sigFromSrams_bore_ram_aux_clk = '0;
    sigFromSrams_bore_ram_aux_ckbp = '0;
    sigFromSrams_bore_ram_mcp_hold = '0;
    sigFromSrams_bore_cgen = '0;
    sigFromSrams_bore_1_ram_hold = '0;
    sigFromSrams_bore_1_ram_bypass = '0;
    sigFromSrams_bore_1_ram_bp_clken = '0;
    sigFromSrams_bore_1_ram_aux_clk = '0;
    sigFromSrams_bore_1_ram_aux_ckbp = '0;
    sigFromSrams_bore_1_ram_mcp_hold = '0;
    sigFromSrams_bore_1_cgen = '0;
    boreChildrenBd_bore_array = '0;
    boreChildrenBd_bore_all = '0;
    boreChildrenBd_bore_req = '0;
    boreChildrenBd_bore_writeen = '0;
    boreChildrenBd_bore_be = '0;
    boreChildrenBd_bore_addr = '0;
    boreChildrenBd_bore_indata = '0;
    boreChildrenBd_bore_readen = '0;
    boreChildrenBd_bore_addr_rd = '0;
    repeat (6) @(posedge clk);
    @(negedge clk); rst = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      drive_random();
      @(posedge clk);
      #1;
      if (cyc >= WARMUP) check_outputs();
    end
    if (errors == 0)
      $display("TEST PASSED: checks=%0d errors=0", checks);
    else
      $display("TEST FAILED: checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
