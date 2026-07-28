// 自动生成：scripts/gen_smsprefetcher.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk=0, rst; int errors=0, checks=0;
  always #5 clk = ~clk;
  logic io_ld_in_0_valid;
  logic [49:0] io_ld_in_0_bits_uop_pc;
  logic io_ld_in_0_bits_uop_robIdx_flag;
  logic [7:0] io_ld_in_0_bits_uop_robIdx_value;
  logic [49:0] io_ld_in_0_bits_vaddr;
  logic [47:0] io_ld_in_0_bits_paddr;
  logic io_ld_in_0_bits_miss;
  logic [2:0] io_ld_in_0_bits_meta_prefetch;
  logic io_ld_in_1_valid;
  logic [49:0] io_ld_in_1_bits_uop_pc;
  logic io_ld_in_1_bits_uop_robIdx_flag;
  logic [7:0] io_ld_in_1_bits_uop_robIdx_value;
  logic [49:0] io_ld_in_1_bits_vaddr;
  logic [47:0] io_ld_in_1_bits_paddr;
  logic io_ld_in_1_bits_miss;
  logic [2:0] io_ld_in_1_bits_meta_prefetch;
  logic io_ld_in_2_valid;
  logic [49:0] io_ld_in_2_bits_uop_pc;
  logic io_ld_in_2_bits_uop_robIdx_flag;
  logic [7:0] io_ld_in_2_bits_uop_robIdx_value;
  logic [49:0] io_ld_in_2_bits_vaddr;
  logic [47:0] io_ld_in_2_bits_paddr;
  logic io_ld_in_2_bits_miss;
  logic [2:0] io_ld_in_2_bits_meta_prefetch;
  logic io_tlb_req_resp_valid;
  logic [47:0] io_tlb_req_resp_bits_paddr_0;
  logic [1:0] io_tlb_req_resp_bits_pbmt_0;
  logic io_tlb_req_resp_bits_miss;
  logic io_tlb_req_resp_bits_excp_0_gpf_ld;
  logic io_tlb_req_resp_bits_excp_0_pf_ld;
  logic io_tlb_req_resp_bits_excp_0_af_ld;
  logic io_pmp_resp_ld;
  logic io_pmp_resp_mmio;
  logic io_enable;
  logic io_agt_en;
  logic io_pht_en;
  logic [3:0] io_act_threshold;
  logic [5:0] io_act_stride;
  logic io_dcache_evict_valid;
  logic [49:0] io_dcache_evict_bits_vaddr;
  logic [5:0] boreChildrenBd_bore_addr;
  logic [5:0] boreChildrenBd_bore_addr_rd;
  logic [147:0] boreChildrenBd_bore_wdata;
  logic [1:0] boreChildrenBd_bore_wmask;
  logic boreChildrenBd_bore_re;
  logic boreChildrenBd_bore_we;
  logic boreChildrenBd_bore_ack;
  logic boreChildrenBd_bore_selectedOH;
  logic [5:0] boreChildrenBd_bore_array;
  logic sigFromSrams_bore_ram_hold;
  logic sigFromSrams_bore_ram_bypass;
  logic sigFromSrams_bore_ram_bp_clken;
  logic sigFromSrams_bore_ram_aux_clk;
  logic sigFromSrams_bore_ram_aux_ckbp;
  logic sigFromSrams_bore_ram_mcp_hold;
  logic sigFromSrams_bore_cgen;
  wire g_io_tlb_req_req_valid;
  wire i_io_tlb_req_req_valid;
  wire [49:0] g_io_tlb_req_req_bits_vaddr;
  wire [49:0] i_io_tlb_req_req_bits_vaddr;
  wire [63:0] g_io_tlb_req_req_bits_fullva;
  wire [63:0] i_io_tlb_req_req_bits_fullva;
  wire g_io_tlb_req_req_bits_checkfullva;
  wire i_io_tlb_req_req_bits_checkfullva;
  wire [2:0] g_io_tlb_req_req_bits_cmd;
  wire [2:0] i_io_tlb_req_req_bits_cmd;
  wire g_io_tlb_req_req_bits_hyperinst;
  wire i_io_tlb_req_req_bits_hyperinst;
  wire g_io_tlb_req_req_bits_hlvx;
  wire i_io_tlb_req_req_bits_hlvx;
  wire g_io_tlb_req_req_bits_kill;
  wire i_io_tlb_req_req_bits_kill;
  wire g_io_tlb_req_req_bits_isPrefetch;
  wire i_io_tlb_req_req_bits_isPrefetch;
  wire g_io_tlb_req_req_bits_no_translate;
  wire i_io_tlb_req_req_bits_no_translate;
  wire [47:0] g_io_tlb_req_req_bits_pmp_addr;
  wire [47:0] i_io_tlb_req_req_bits_pmp_addr;
  wire g_io_tlb_req_req_bits_debug_robIdx_flag;
  wire i_io_tlb_req_req_bits_debug_robIdx_flag;
  wire [7:0] g_io_tlb_req_req_bits_debug_robIdx_value;
  wire [7:0] i_io_tlb_req_req_bits_debug_robIdx_value;
  wire g_io_tlb_req_req_bits_debug_isFirstIssue;
  wire i_io_tlb_req_req_bits_debug_isFirstIssue;
  wire g_io_l2_req_valid;
  wire i_io_l2_req_valid;
  wire [47:0] g_io_l2_req_bits_addr;
  wire [47:0] i_io_l2_req_bits_addr;
  wire [147:0] g_boreChildrenBd_bore_rdata;
  wire [147:0] i_boreChildrenBd_bore_rdata;
  SMSPrefetcher    u_g (.clock(clk), .reset(rst), .io_ld_in_0_valid(io_ld_in_0_valid), .io_ld_in_0_bits_uop_pc(io_ld_in_0_bits_uop_pc), .io_ld_in_0_bits_uop_robIdx_flag(io_ld_in_0_bits_uop_robIdx_flag), .io_ld_in_0_bits_uop_robIdx_value(io_ld_in_0_bits_uop_robIdx_value), .io_ld_in_0_bits_vaddr(io_ld_in_0_bits_vaddr), .io_ld_in_0_bits_paddr(io_ld_in_0_bits_paddr), .io_ld_in_0_bits_miss(io_ld_in_0_bits_miss), .io_ld_in_0_bits_meta_prefetch(io_ld_in_0_bits_meta_prefetch), .io_ld_in_1_valid(io_ld_in_1_valid), .io_ld_in_1_bits_uop_pc(io_ld_in_1_bits_uop_pc), .io_ld_in_1_bits_uop_robIdx_flag(io_ld_in_1_bits_uop_robIdx_flag), .io_ld_in_1_bits_uop_robIdx_value(io_ld_in_1_bits_uop_robIdx_value), .io_ld_in_1_bits_vaddr(io_ld_in_1_bits_vaddr), .io_ld_in_1_bits_paddr(io_ld_in_1_bits_paddr), .io_ld_in_1_bits_miss(io_ld_in_1_bits_miss), .io_ld_in_1_bits_meta_prefetch(io_ld_in_1_bits_meta_prefetch), .io_ld_in_2_valid(io_ld_in_2_valid), .io_ld_in_2_bits_uop_pc(io_ld_in_2_bits_uop_pc), .io_ld_in_2_bits_uop_robIdx_flag(io_ld_in_2_bits_uop_robIdx_flag), .io_ld_in_2_bits_uop_robIdx_value(io_ld_in_2_bits_uop_robIdx_value), .io_ld_in_2_bits_vaddr(io_ld_in_2_bits_vaddr), .io_ld_in_2_bits_paddr(io_ld_in_2_bits_paddr), .io_ld_in_2_bits_miss(io_ld_in_2_bits_miss), .io_ld_in_2_bits_meta_prefetch(io_ld_in_2_bits_meta_prefetch), .io_tlb_req_resp_valid(io_tlb_req_resp_valid), .io_tlb_req_resp_bits_paddr_0(io_tlb_req_resp_bits_paddr_0), .io_tlb_req_resp_bits_pbmt_0(io_tlb_req_resp_bits_pbmt_0), .io_tlb_req_resp_bits_miss(io_tlb_req_resp_bits_miss), .io_tlb_req_resp_bits_excp_0_gpf_ld(io_tlb_req_resp_bits_excp_0_gpf_ld), .io_tlb_req_resp_bits_excp_0_pf_ld(io_tlb_req_resp_bits_excp_0_pf_ld), .io_tlb_req_resp_bits_excp_0_af_ld(io_tlb_req_resp_bits_excp_0_af_ld), .io_pmp_resp_ld(io_pmp_resp_ld), .io_pmp_resp_mmio(io_pmp_resp_mmio), .io_enable(io_enable), .io_agt_en(io_agt_en), .io_pht_en(io_pht_en), .io_act_threshold(io_act_threshold), .io_act_stride(io_act_stride), .io_dcache_evict_valid(io_dcache_evict_valid), .io_dcache_evict_bits_vaddr(io_dcache_evict_bits_vaddr), .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(boreChildrenBd_bore_re), .boreChildrenBd_bore_we(boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(boreChildrenBd_bore_array), .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen), .io_tlb_req_req_valid(g_io_tlb_req_req_valid), .io_tlb_req_req_bits_vaddr(g_io_tlb_req_req_bits_vaddr), .io_tlb_req_req_bits_fullva(g_io_tlb_req_req_bits_fullva), .io_tlb_req_req_bits_checkfullva(g_io_tlb_req_req_bits_checkfullva), .io_tlb_req_req_bits_cmd(g_io_tlb_req_req_bits_cmd), .io_tlb_req_req_bits_hyperinst(g_io_tlb_req_req_bits_hyperinst), .io_tlb_req_req_bits_hlvx(g_io_tlb_req_req_bits_hlvx), .io_tlb_req_req_bits_kill(g_io_tlb_req_req_bits_kill), .io_tlb_req_req_bits_isPrefetch(g_io_tlb_req_req_bits_isPrefetch), .io_tlb_req_req_bits_no_translate(g_io_tlb_req_req_bits_no_translate), .io_tlb_req_req_bits_pmp_addr(g_io_tlb_req_req_bits_pmp_addr), .io_tlb_req_req_bits_debug_robIdx_flag(g_io_tlb_req_req_bits_debug_robIdx_flag), .io_tlb_req_req_bits_debug_robIdx_value(g_io_tlb_req_req_bits_debug_robIdx_value), .io_tlb_req_req_bits_debug_isFirstIssue(g_io_tlb_req_req_bits_debug_isFirstIssue), .io_l2_req_valid(g_io_l2_req_valid), .io_l2_req_bits_addr(g_io_l2_req_bits_addr), .boreChildrenBd_bore_rdata(g_boreChildrenBd_bore_rdata));
  SMSPrefetcher_xs u_i (.clock(clk), .reset(rst), .io_ld_in_0_valid(io_ld_in_0_valid), .io_ld_in_0_bits_uop_pc(io_ld_in_0_bits_uop_pc), .io_ld_in_0_bits_uop_robIdx_flag(io_ld_in_0_bits_uop_robIdx_flag), .io_ld_in_0_bits_uop_robIdx_value(io_ld_in_0_bits_uop_robIdx_value), .io_ld_in_0_bits_vaddr(io_ld_in_0_bits_vaddr), .io_ld_in_0_bits_paddr(io_ld_in_0_bits_paddr), .io_ld_in_0_bits_miss(io_ld_in_0_bits_miss), .io_ld_in_0_bits_meta_prefetch(io_ld_in_0_bits_meta_prefetch), .io_ld_in_1_valid(io_ld_in_1_valid), .io_ld_in_1_bits_uop_pc(io_ld_in_1_bits_uop_pc), .io_ld_in_1_bits_uop_robIdx_flag(io_ld_in_1_bits_uop_robIdx_flag), .io_ld_in_1_bits_uop_robIdx_value(io_ld_in_1_bits_uop_robIdx_value), .io_ld_in_1_bits_vaddr(io_ld_in_1_bits_vaddr), .io_ld_in_1_bits_paddr(io_ld_in_1_bits_paddr), .io_ld_in_1_bits_miss(io_ld_in_1_bits_miss), .io_ld_in_1_bits_meta_prefetch(io_ld_in_1_bits_meta_prefetch), .io_ld_in_2_valid(io_ld_in_2_valid), .io_ld_in_2_bits_uop_pc(io_ld_in_2_bits_uop_pc), .io_ld_in_2_bits_uop_robIdx_flag(io_ld_in_2_bits_uop_robIdx_flag), .io_ld_in_2_bits_uop_robIdx_value(io_ld_in_2_bits_uop_robIdx_value), .io_ld_in_2_bits_vaddr(io_ld_in_2_bits_vaddr), .io_ld_in_2_bits_paddr(io_ld_in_2_bits_paddr), .io_ld_in_2_bits_miss(io_ld_in_2_bits_miss), .io_ld_in_2_bits_meta_prefetch(io_ld_in_2_bits_meta_prefetch), .io_tlb_req_resp_valid(io_tlb_req_resp_valid), .io_tlb_req_resp_bits_paddr_0(io_tlb_req_resp_bits_paddr_0), .io_tlb_req_resp_bits_pbmt_0(io_tlb_req_resp_bits_pbmt_0), .io_tlb_req_resp_bits_miss(io_tlb_req_resp_bits_miss), .io_tlb_req_resp_bits_excp_0_gpf_ld(io_tlb_req_resp_bits_excp_0_gpf_ld), .io_tlb_req_resp_bits_excp_0_pf_ld(io_tlb_req_resp_bits_excp_0_pf_ld), .io_tlb_req_resp_bits_excp_0_af_ld(io_tlb_req_resp_bits_excp_0_af_ld), .io_pmp_resp_ld(io_pmp_resp_ld), .io_pmp_resp_mmio(io_pmp_resp_mmio), .io_enable(io_enable), .io_agt_en(io_agt_en), .io_pht_en(io_pht_en), .io_act_threshold(io_act_threshold), .io_act_stride(io_act_stride), .io_dcache_evict_valid(io_dcache_evict_valid), .io_dcache_evict_bits_vaddr(io_dcache_evict_bits_vaddr), .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(boreChildrenBd_bore_re), .boreChildrenBd_bore_we(boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(boreChildrenBd_bore_array), .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen), .io_tlb_req_req_valid(i_io_tlb_req_req_valid), .io_tlb_req_req_bits_vaddr(i_io_tlb_req_req_bits_vaddr), .io_tlb_req_req_bits_fullva(i_io_tlb_req_req_bits_fullva), .io_tlb_req_req_bits_checkfullva(i_io_tlb_req_req_bits_checkfullva), .io_tlb_req_req_bits_cmd(i_io_tlb_req_req_bits_cmd), .io_tlb_req_req_bits_hyperinst(i_io_tlb_req_req_bits_hyperinst), .io_tlb_req_req_bits_hlvx(i_io_tlb_req_req_bits_hlvx), .io_tlb_req_req_bits_kill(i_io_tlb_req_req_bits_kill), .io_tlb_req_req_bits_isPrefetch(i_io_tlb_req_req_bits_isPrefetch), .io_tlb_req_req_bits_no_translate(i_io_tlb_req_req_bits_no_translate), .io_tlb_req_req_bits_pmp_addr(i_io_tlb_req_req_bits_pmp_addr), .io_tlb_req_req_bits_debug_robIdx_flag(i_io_tlb_req_req_bits_debug_robIdx_flag), .io_tlb_req_req_bits_debug_robIdx_value(i_io_tlb_req_req_bits_debug_robIdx_value), .io_tlb_req_req_bits_debug_isFirstIssue(i_io_tlb_req_req_bits_debug_isFirstIssue), .io_l2_req_valid(i_io_l2_req_valid), .io_l2_req_bits_addr(i_io_l2_req_bits_addr), .boreChildrenBd_bore_rdata(i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      io_enable <= 1'b0;
      io_agt_en <= 1'b0;
      io_pht_en <= 1'b0;
      io_tlb_req_resp_valid <= 1'b0;
      io_dcache_evict_valid <= 1'b0;
      boreChildrenBd_bore_re <= 1'b0;
      boreChildrenBd_bore_we <= 1'b0;
      io_ld_in_0_valid <= 1'b0;
      io_ld_in_1_valid <= 1'b0;
      io_ld_in_2_valid <= 1'b0;
    end else begin
      io_ld_in_0_valid <= ($urandom_range(0,1));
      io_ld_in_0_bits_uop_pc <= {38'($urandom_range(0,15)), 12'($urandom)};
      io_ld_in_0_bits_uop_robIdx_flag <= $urandom_range(0,1);
      io_ld_in_0_bits_uop_robIdx_value <= 8'($urandom);
      io_ld_in_0_bits_vaddr <= {38'($urandom_range(0,15)), 12'($urandom)};
      io_ld_in_0_bits_paddr <= {36'($urandom_range(0,15)), 12'($urandom)};
      io_ld_in_0_bits_miss <= $urandom_range(0,1);
      io_ld_in_0_bits_meta_prefetch <= 3'($urandom);
      io_ld_in_1_valid <= ($urandom_range(0,1));
      io_ld_in_1_bits_uop_pc <= {38'($urandom_range(0,15)), 12'($urandom)};
      io_ld_in_1_bits_uop_robIdx_flag <= $urandom_range(0,1);
      io_ld_in_1_bits_uop_robIdx_value <= 8'($urandom);
      io_ld_in_1_bits_vaddr <= {38'($urandom_range(0,15)), 12'($urandom)};
      io_ld_in_1_bits_paddr <= {36'($urandom_range(0,15)), 12'($urandom)};
      io_ld_in_1_bits_miss <= $urandom_range(0,1);
      io_ld_in_1_bits_meta_prefetch <= 3'($urandom);
      io_ld_in_2_valid <= ($urandom_range(0,1));
      io_ld_in_2_bits_uop_pc <= {38'($urandom_range(0,15)), 12'($urandom)};
      io_ld_in_2_bits_uop_robIdx_flag <= $urandom_range(0,1);
      io_ld_in_2_bits_uop_robIdx_value <= 8'($urandom);
      io_ld_in_2_bits_vaddr <= {38'($urandom_range(0,15)), 12'($urandom)};
      io_ld_in_2_bits_paddr <= {36'($urandom_range(0,15)), 12'($urandom)};
      io_ld_in_2_bits_miss <= $urandom_range(0,1);
      io_ld_in_2_bits_meta_prefetch <= 3'($urandom);
      io_tlb_req_resp_valid <= ($urandom_range(0,2)==0);
      io_tlb_req_resp_bits_paddr_0 <= {36'($urandom_range(0,15)), 12'($urandom)};
      io_tlb_req_resp_bits_pbmt_0 <= 2'($urandom);
      io_tlb_req_resp_bits_miss <= $urandom_range(0,1);
      io_tlb_req_resp_bits_excp_0_gpf_ld <= $urandom_range(0,1);
      io_tlb_req_resp_bits_excp_0_pf_ld <= $urandom_range(0,1);
      io_tlb_req_resp_bits_excp_0_af_ld <= $urandom_range(0,1);
      io_pmp_resp_ld <= $urandom_range(0,1);
      io_pmp_resp_mmio <= $urandom_range(0,1);
      io_enable <= ($urandom_range(0,3)!=0);
      io_agt_en <= ($urandom_range(0,3)!=0);
      io_pht_en <= ($urandom_range(0,3)!=0);
      io_act_threshold <= 4'($urandom);
      io_act_stride <= 6'($urandom);
      io_dcache_evict_valid <= ($urandom_range(0,3)==0);
      io_dcache_evict_bits_vaddr <= {38'($urandom_range(0,15)), 12'($urandom)};
      boreChildrenBd_bore_addr <= 6'($urandom);
      boreChildrenBd_bore_addr_rd <= 6'($urandom);
      boreChildrenBd_bore_wdata <= 148'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      boreChildrenBd_bore_wmask <= 2'($urandom);
      boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      boreChildrenBd_bore_ack <= $urandom_range(0,1);
      boreChildrenBd_bore_selectedOH <= $urandom_range(0,1);
      boreChildrenBd_bore_array <= 6'($urandom);
      sigFromSrams_bore_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_cgen <= $urandom_range(0,1);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_tlb_req_req_valid) && g_io_tlb_req_req_valid !== i_io_tlb_req_req_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_valid g=%h i=%h", $time, g_io_tlb_req_req_valid, i_io_tlb_req_req_valid); end
    if (!$isunknown(g_io_tlb_req_req_bits_vaddr) && g_io_tlb_req_req_bits_vaddr !== i_io_tlb_req_req_bits_vaddr) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_vaddr g=%h i=%h", $time, g_io_tlb_req_req_bits_vaddr, i_io_tlb_req_req_bits_vaddr); end
    if (!$isunknown(g_io_tlb_req_req_bits_fullva) && g_io_tlb_req_req_bits_fullva !== i_io_tlb_req_req_bits_fullva) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_fullva g=%h i=%h", $time, g_io_tlb_req_req_bits_fullva, i_io_tlb_req_req_bits_fullva); end
    if (!$isunknown(g_io_tlb_req_req_bits_checkfullva) && g_io_tlb_req_req_bits_checkfullva !== i_io_tlb_req_req_bits_checkfullva) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_checkfullva g=%h i=%h", $time, g_io_tlb_req_req_bits_checkfullva, i_io_tlb_req_req_bits_checkfullva); end
    if (!$isunknown(g_io_tlb_req_req_bits_cmd) && g_io_tlb_req_req_bits_cmd !== i_io_tlb_req_req_bits_cmd) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_cmd g=%h i=%h", $time, g_io_tlb_req_req_bits_cmd, i_io_tlb_req_req_bits_cmd); end
    if (!$isunknown(g_io_tlb_req_req_bits_hyperinst) && g_io_tlb_req_req_bits_hyperinst !== i_io_tlb_req_req_bits_hyperinst) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_hyperinst g=%h i=%h", $time, g_io_tlb_req_req_bits_hyperinst, i_io_tlb_req_req_bits_hyperinst); end
    if (!$isunknown(g_io_tlb_req_req_bits_hlvx) && g_io_tlb_req_req_bits_hlvx !== i_io_tlb_req_req_bits_hlvx) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_hlvx g=%h i=%h", $time, g_io_tlb_req_req_bits_hlvx, i_io_tlb_req_req_bits_hlvx); end
    if (!$isunknown(g_io_tlb_req_req_bits_kill) && g_io_tlb_req_req_bits_kill !== i_io_tlb_req_req_bits_kill) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_kill g=%h i=%h", $time, g_io_tlb_req_req_bits_kill, i_io_tlb_req_req_bits_kill); end
    if (!$isunknown(g_io_tlb_req_req_bits_isPrefetch) && g_io_tlb_req_req_bits_isPrefetch !== i_io_tlb_req_req_bits_isPrefetch) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_isPrefetch g=%h i=%h", $time, g_io_tlb_req_req_bits_isPrefetch, i_io_tlb_req_req_bits_isPrefetch); end
    if (!$isunknown(g_io_tlb_req_req_bits_no_translate) && g_io_tlb_req_req_bits_no_translate !== i_io_tlb_req_req_bits_no_translate) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_no_translate g=%h i=%h", $time, g_io_tlb_req_req_bits_no_translate, i_io_tlb_req_req_bits_no_translate); end
    if (!$isunknown(g_io_tlb_req_req_bits_pmp_addr) && g_io_tlb_req_req_bits_pmp_addr !== i_io_tlb_req_req_bits_pmp_addr) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_pmp_addr g=%h i=%h", $time, g_io_tlb_req_req_bits_pmp_addr, i_io_tlb_req_req_bits_pmp_addr); end
    if (!$isunknown(g_io_tlb_req_req_bits_debug_robIdx_flag) && g_io_tlb_req_req_bits_debug_robIdx_flag !== i_io_tlb_req_req_bits_debug_robIdx_flag) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_debug_robIdx_flag g=%h i=%h", $time, g_io_tlb_req_req_bits_debug_robIdx_flag, i_io_tlb_req_req_bits_debug_robIdx_flag); end
    if (!$isunknown(g_io_tlb_req_req_bits_debug_robIdx_value) && g_io_tlb_req_req_bits_debug_robIdx_value !== i_io_tlb_req_req_bits_debug_robIdx_value) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_debug_robIdx_value g=%h i=%h", $time, g_io_tlb_req_req_bits_debug_robIdx_value, i_io_tlb_req_req_bits_debug_robIdx_value); end
    if (!$isunknown(g_io_tlb_req_req_bits_debug_isFirstIssue) && g_io_tlb_req_req_bits_debug_isFirstIssue !== i_io_tlb_req_req_bits_debug_isFirstIssue) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_req_bits_debug_isFirstIssue g=%h i=%h", $time, g_io_tlb_req_req_bits_debug_isFirstIssue, i_io_tlb_req_req_bits_debug_isFirstIssue); end
    if (!$isunknown(g_io_l2_req_valid) && g_io_l2_req_valid !== i_io_l2_req_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_l2_req_valid g=%h i=%h", $time, g_io_l2_req_valid, i_io_l2_req_valid); end
    if (!$isunknown(g_io_l2_req_bits_addr) && g_io_l2_req_bits_addr !== i_io_l2_req_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] io_l2_req_bits_addr g=%h i=%h", $time, g_io_l2_req_bits_addr, i_io_l2_req_bits_addr); end
    if (!$isunknown(g_boreChildrenBd_bore_rdata) && g_boreChildrenBd_bore_rdata !== i_boreChildrenBd_bore_rdata) begin errors++;
      if(errors<=80) $display("[%0t] boreChildrenBd_bore_rdata g=%h i=%h", $time, g_boreChildrenBd_bore_rdata, i_boreChildrenBd_bore_rdata); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
