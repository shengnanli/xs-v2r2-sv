// 自动生成：scripts/gen_l1prefetcher.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk=0, rst; int errors=0, checks=0;
  always #5 clk = ~clk;
  logic io_ld_in_0_valid;
  logic io_ld_in_0_bits_uop_robIdx_flag;
  logic [7:0] io_ld_in_0_bits_uop_robIdx_value;
  logic [49:0] io_ld_in_0_bits_vaddr;
  logic io_ld_in_0_bits_miss;
  logic [2:0] io_ld_in_0_bits_meta_prefetch;
  logic io_ld_in_1_valid;
  logic io_ld_in_1_bits_uop_robIdx_flag;
  logic [7:0] io_ld_in_1_bits_uop_robIdx_value;
  logic [49:0] io_ld_in_1_bits_vaddr;
  logic io_ld_in_1_bits_miss;
  logic [2:0] io_ld_in_1_bits_meta_prefetch;
  logic io_ld_in_2_valid;
  logic io_ld_in_2_bits_uop_robIdx_flag;
  logic [7:0] io_ld_in_2_bits_uop_robIdx_value;
  logic [49:0] io_ld_in_2_bits_vaddr;
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
  logic io_l1_req_ready;
  logic io_enable;
  logic pf_ctrl_enable;
  logic pf_ctrl_confidence;
  logic stride_train_0_valid;
  logic [49:0] stride_train_0_bits_uop_pc;
  logic stride_train_0_bits_uop_robIdx_flag;
  logic [7:0] stride_train_0_bits_uop_robIdx_value;
  logic [49:0] stride_train_0_bits_vaddr;
  logic stride_train_1_valid;
  logic [49:0] stride_train_1_bits_uop_pc;
  logic stride_train_1_bits_uop_robIdx_flag;
  logic [7:0] stride_train_1_bits_uop_robIdx_value;
  logic [49:0] stride_train_1_bits_vaddr;
  logic stride_train_2_valid;
  logic [49:0] stride_train_2_bits_uop_pc;
  logic stride_train_2_bits_uop_robIdx_flag;
  logic [7:0] stride_train_2_bits_uop_robIdx_value;
  logic [49:0] stride_train_2_bits_vaddr;
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
  wire g_io_l1_req_valid;
  wire i_io_l1_req_valid;
  wire [47:0] g_io_l1_req_bits_paddr;
  wire [47:0] i_io_l1_req_bits_paddr;
  wire [1:0] g_io_l1_req_bits_alias;
  wire [1:0] i_io_l1_req_bits_alias;
  wire g_io_l1_req_bits_confidence;
  wire i_io_l1_req_bits_confidence;
  wire g_io_l1_req_bits_is_store;
  wire i_io_l1_req_bits_is_store;
  wire [2:0] g_io_l1_req_bits_pf_source_value;
  wire [2:0] i_io_l1_req_bits_pf_source_value;
  wire g_io_l2_req_valid;
  wire i_io_l2_req_valid;
  wire [47:0] g_io_l2_req_bits_addr;
  wire [47:0] i_io_l2_req_bits_addr;
  wire [4:0] g_io_l2_req_bits_source;
  wire [4:0] i_io_l2_req_bits_source;
  L1Prefetcher    u_g (.clock(clk), .reset(rst), .io_ld_in_0_valid(io_ld_in_0_valid), .io_ld_in_0_bits_uop_robIdx_flag(io_ld_in_0_bits_uop_robIdx_flag), .io_ld_in_0_bits_uop_robIdx_value(io_ld_in_0_bits_uop_robIdx_value), .io_ld_in_0_bits_vaddr(io_ld_in_0_bits_vaddr), .io_ld_in_0_bits_miss(io_ld_in_0_bits_miss), .io_ld_in_0_bits_meta_prefetch(io_ld_in_0_bits_meta_prefetch), .io_ld_in_1_valid(io_ld_in_1_valid), .io_ld_in_1_bits_uop_robIdx_flag(io_ld_in_1_bits_uop_robIdx_flag), .io_ld_in_1_bits_uop_robIdx_value(io_ld_in_1_bits_uop_robIdx_value), .io_ld_in_1_bits_vaddr(io_ld_in_1_bits_vaddr), .io_ld_in_1_bits_miss(io_ld_in_1_bits_miss), .io_ld_in_1_bits_meta_prefetch(io_ld_in_1_bits_meta_prefetch), .io_ld_in_2_valid(io_ld_in_2_valid), .io_ld_in_2_bits_uop_robIdx_flag(io_ld_in_2_bits_uop_robIdx_flag), .io_ld_in_2_bits_uop_robIdx_value(io_ld_in_2_bits_uop_robIdx_value), .io_ld_in_2_bits_vaddr(io_ld_in_2_bits_vaddr), .io_ld_in_2_bits_miss(io_ld_in_2_bits_miss), .io_ld_in_2_bits_meta_prefetch(io_ld_in_2_bits_meta_prefetch), .io_tlb_req_resp_valid(io_tlb_req_resp_valid), .io_tlb_req_resp_bits_paddr_0(io_tlb_req_resp_bits_paddr_0), .io_tlb_req_resp_bits_pbmt_0(io_tlb_req_resp_bits_pbmt_0), .io_tlb_req_resp_bits_miss(io_tlb_req_resp_bits_miss), .io_tlb_req_resp_bits_excp_0_gpf_ld(io_tlb_req_resp_bits_excp_0_gpf_ld), .io_tlb_req_resp_bits_excp_0_pf_ld(io_tlb_req_resp_bits_excp_0_pf_ld), .io_tlb_req_resp_bits_excp_0_af_ld(io_tlb_req_resp_bits_excp_0_af_ld), .io_pmp_resp_ld(io_pmp_resp_ld), .io_pmp_resp_mmio(io_pmp_resp_mmio), .io_l1_req_ready(io_l1_req_ready), .io_enable(io_enable), .pf_ctrl_enable(pf_ctrl_enable), .pf_ctrl_confidence(pf_ctrl_confidence), .stride_train_0_valid(stride_train_0_valid), .stride_train_0_bits_uop_pc(stride_train_0_bits_uop_pc), .stride_train_0_bits_uop_robIdx_flag(stride_train_0_bits_uop_robIdx_flag), .stride_train_0_bits_uop_robIdx_value(stride_train_0_bits_uop_robIdx_value), .stride_train_0_bits_vaddr(stride_train_0_bits_vaddr), .stride_train_1_valid(stride_train_1_valid), .stride_train_1_bits_uop_pc(stride_train_1_bits_uop_pc), .stride_train_1_bits_uop_robIdx_flag(stride_train_1_bits_uop_robIdx_flag), .stride_train_1_bits_uop_robIdx_value(stride_train_1_bits_uop_robIdx_value), .stride_train_1_bits_vaddr(stride_train_1_bits_vaddr), .stride_train_2_valid(stride_train_2_valid), .stride_train_2_bits_uop_pc(stride_train_2_bits_uop_pc), .stride_train_2_bits_uop_robIdx_flag(stride_train_2_bits_uop_robIdx_flag), .stride_train_2_bits_uop_robIdx_value(stride_train_2_bits_uop_robIdx_value), .stride_train_2_bits_vaddr(stride_train_2_bits_vaddr), .io_tlb_req_req_valid(g_io_tlb_req_req_valid), .io_tlb_req_req_bits_vaddr(g_io_tlb_req_req_bits_vaddr), .io_tlb_req_req_bits_fullva(g_io_tlb_req_req_bits_fullva), .io_tlb_req_req_bits_checkfullva(g_io_tlb_req_req_bits_checkfullva), .io_tlb_req_req_bits_cmd(g_io_tlb_req_req_bits_cmd), .io_tlb_req_req_bits_hyperinst(g_io_tlb_req_req_bits_hyperinst), .io_tlb_req_req_bits_hlvx(g_io_tlb_req_req_bits_hlvx), .io_tlb_req_req_bits_kill(g_io_tlb_req_req_bits_kill), .io_tlb_req_req_bits_isPrefetch(g_io_tlb_req_req_bits_isPrefetch), .io_tlb_req_req_bits_no_translate(g_io_tlb_req_req_bits_no_translate), .io_tlb_req_req_bits_pmp_addr(g_io_tlb_req_req_bits_pmp_addr), .io_tlb_req_req_bits_debug_robIdx_flag(g_io_tlb_req_req_bits_debug_robIdx_flag), .io_tlb_req_req_bits_debug_robIdx_value(g_io_tlb_req_req_bits_debug_robIdx_value), .io_tlb_req_req_bits_debug_isFirstIssue(g_io_tlb_req_req_bits_debug_isFirstIssue), .io_l1_req_valid(g_io_l1_req_valid), .io_l1_req_bits_paddr(g_io_l1_req_bits_paddr), .io_l1_req_bits_alias(g_io_l1_req_bits_alias), .io_l1_req_bits_confidence(g_io_l1_req_bits_confidence), .io_l1_req_bits_is_store(g_io_l1_req_bits_is_store), .io_l1_req_bits_pf_source_value(g_io_l1_req_bits_pf_source_value), .io_l2_req_valid(g_io_l2_req_valid), .io_l2_req_bits_addr(g_io_l2_req_bits_addr), .io_l2_req_bits_source(g_io_l2_req_bits_source));
  L1Prefetcher_xs u_i (.clock(clk), .reset(rst), .io_ld_in_0_valid(io_ld_in_0_valid), .io_ld_in_0_bits_uop_robIdx_flag(io_ld_in_0_bits_uop_robIdx_flag), .io_ld_in_0_bits_uop_robIdx_value(io_ld_in_0_bits_uop_robIdx_value), .io_ld_in_0_bits_vaddr(io_ld_in_0_bits_vaddr), .io_ld_in_0_bits_miss(io_ld_in_0_bits_miss), .io_ld_in_0_bits_meta_prefetch(io_ld_in_0_bits_meta_prefetch), .io_ld_in_1_valid(io_ld_in_1_valid), .io_ld_in_1_bits_uop_robIdx_flag(io_ld_in_1_bits_uop_robIdx_flag), .io_ld_in_1_bits_uop_robIdx_value(io_ld_in_1_bits_uop_robIdx_value), .io_ld_in_1_bits_vaddr(io_ld_in_1_bits_vaddr), .io_ld_in_1_bits_miss(io_ld_in_1_bits_miss), .io_ld_in_1_bits_meta_prefetch(io_ld_in_1_bits_meta_prefetch), .io_ld_in_2_valid(io_ld_in_2_valid), .io_ld_in_2_bits_uop_robIdx_flag(io_ld_in_2_bits_uop_robIdx_flag), .io_ld_in_2_bits_uop_robIdx_value(io_ld_in_2_bits_uop_robIdx_value), .io_ld_in_2_bits_vaddr(io_ld_in_2_bits_vaddr), .io_ld_in_2_bits_miss(io_ld_in_2_bits_miss), .io_ld_in_2_bits_meta_prefetch(io_ld_in_2_bits_meta_prefetch), .io_tlb_req_resp_valid(io_tlb_req_resp_valid), .io_tlb_req_resp_bits_paddr_0(io_tlb_req_resp_bits_paddr_0), .io_tlb_req_resp_bits_pbmt_0(io_tlb_req_resp_bits_pbmt_0), .io_tlb_req_resp_bits_miss(io_tlb_req_resp_bits_miss), .io_tlb_req_resp_bits_excp_0_gpf_ld(io_tlb_req_resp_bits_excp_0_gpf_ld), .io_tlb_req_resp_bits_excp_0_pf_ld(io_tlb_req_resp_bits_excp_0_pf_ld), .io_tlb_req_resp_bits_excp_0_af_ld(io_tlb_req_resp_bits_excp_0_af_ld), .io_pmp_resp_ld(io_pmp_resp_ld), .io_pmp_resp_mmio(io_pmp_resp_mmio), .io_l1_req_ready(io_l1_req_ready), .io_enable(io_enable), .pf_ctrl_enable(pf_ctrl_enable), .pf_ctrl_confidence(pf_ctrl_confidence), .stride_train_0_valid(stride_train_0_valid), .stride_train_0_bits_uop_pc(stride_train_0_bits_uop_pc), .stride_train_0_bits_uop_robIdx_flag(stride_train_0_bits_uop_robIdx_flag), .stride_train_0_bits_uop_robIdx_value(stride_train_0_bits_uop_robIdx_value), .stride_train_0_bits_vaddr(stride_train_0_bits_vaddr), .stride_train_1_valid(stride_train_1_valid), .stride_train_1_bits_uop_pc(stride_train_1_bits_uop_pc), .stride_train_1_bits_uop_robIdx_flag(stride_train_1_bits_uop_robIdx_flag), .stride_train_1_bits_uop_robIdx_value(stride_train_1_bits_uop_robIdx_value), .stride_train_1_bits_vaddr(stride_train_1_bits_vaddr), .stride_train_2_valid(stride_train_2_valid), .stride_train_2_bits_uop_pc(stride_train_2_bits_uop_pc), .stride_train_2_bits_uop_robIdx_flag(stride_train_2_bits_uop_robIdx_flag), .stride_train_2_bits_uop_robIdx_value(stride_train_2_bits_uop_robIdx_value), .stride_train_2_bits_vaddr(stride_train_2_bits_vaddr), .io_tlb_req_req_valid(i_io_tlb_req_req_valid), .io_tlb_req_req_bits_vaddr(i_io_tlb_req_req_bits_vaddr), .io_tlb_req_req_bits_fullva(i_io_tlb_req_req_bits_fullva), .io_tlb_req_req_bits_checkfullva(i_io_tlb_req_req_bits_checkfullva), .io_tlb_req_req_bits_cmd(i_io_tlb_req_req_bits_cmd), .io_tlb_req_req_bits_hyperinst(i_io_tlb_req_req_bits_hyperinst), .io_tlb_req_req_bits_hlvx(i_io_tlb_req_req_bits_hlvx), .io_tlb_req_req_bits_kill(i_io_tlb_req_req_bits_kill), .io_tlb_req_req_bits_isPrefetch(i_io_tlb_req_req_bits_isPrefetch), .io_tlb_req_req_bits_no_translate(i_io_tlb_req_req_bits_no_translate), .io_tlb_req_req_bits_pmp_addr(i_io_tlb_req_req_bits_pmp_addr), .io_tlb_req_req_bits_debug_robIdx_flag(i_io_tlb_req_req_bits_debug_robIdx_flag), .io_tlb_req_req_bits_debug_robIdx_value(i_io_tlb_req_req_bits_debug_robIdx_value), .io_tlb_req_req_bits_debug_isFirstIssue(i_io_tlb_req_req_bits_debug_isFirstIssue), .io_l1_req_valid(i_io_l1_req_valid), .io_l1_req_bits_paddr(i_io_l1_req_bits_paddr), .io_l1_req_bits_alias(i_io_l1_req_bits_alias), .io_l1_req_bits_confidence(i_io_l1_req_bits_confidence), .io_l1_req_bits_is_store(i_io_l1_req_bits_is_store), .io_l1_req_bits_pf_source_value(i_io_l1_req_bits_pf_source_value), .io_l2_req_valid(i_io_l2_req_valid), .io_l2_req_bits_addr(i_io_l2_req_bits_addr), .io_l2_req_bits_source(i_io_l2_req_bits_source));
  always @(negedge clk) begin
    if (rst) begin
      io_enable <= 1'b0;
      pf_ctrl_enable <= 1'b0;
      io_l1_req_ready <= 1'b0;
      io_tlb_req_resp_valid <= 1'b0;
      io_ld_in_0_valid <= 1'b0;
      stride_train_0_valid <= 1'b0;
      io_ld_in_1_valid <= 1'b0;
      stride_train_1_valid <= 1'b0;
      io_ld_in_2_valid <= 1'b0;
      stride_train_2_valid <= 1'b0;
    end else begin
      io_ld_in_0_valid <= ($urandom_range(0,1));
      io_ld_in_0_bits_uop_robIdx_flag <= $urandom_range(0,1);
      io_ld_in_0_bits_uop_robIdx_value <= 8'($urandom);
      io_ld_in_0_bits_vaddr <= {38'($urandom_range(0,15)), 12'($urandom)};
      io_ld_in_0_bits_miss <= $urandom_range(0,1);
      io_ld_in_0_bits_meta_prefetch <= 3'($urandom);
      io_ld_in_1_valid <= ($urandom_range(0,1));
      io_ld_in_1_bits_uop_robIdx_flag <= $urandom_range(0,1);
      io_ld_in_1_bits_uop_robIdx_value <= 8'($urandom);
      io_ld_in_1_bits_vaddr <= {38'($urandom_range(0,15)), 12'($urandom)};
      io_ld_in_1_bits_miss <= $urandom_range(0,1);
      io_ld_in_1_bits_meta_prefetch <= 3'($urandom);
      io_ld_in_2_valid <= ($urandom_range(0,1));
      io_ld_in_2_bits_uop_robIdx_flag <= $urandom_range(0,1);
      io_ld_in_2_bits_uop_robIdx_value <= 8'($urandom);
      io_ld_in_2_bits_vaddr <= {38'($urandom_range(0,15)), 12'($urandom)};
      io_ld_in_2_bits_miss <= $urandom_range(0,1);
      io_ld_in_2_bits_meta_prefetch <= 3'($urandom);
      io_tlb_req_resp_valid <= ($urandom_range(0,2)==0);
      io_tlb_req_resp_bits_paddr_0 <= 48'({$urandom(), $urandom()});
      io_tlb_req_resp_bits_pbmt_0 <= 2'($urandom);
      io_tlb_req_resp_bits_miss <= $urandom_range(0,1);
      io_tlb_req_resp_bits_excp_0_gpf_ld <= $urandom_range(0,1);
      io_tlb_req_resp_bits_excp_0_pf_ld <= $urandom_range(0,1);
      io_tlb_req_resp_bits_excp_0_af_ld <= $urandom_range(0,1);
      io_pmp_resp_ld <= $urandom_range(0,1);
      io_pmp_resp_mmio <= $urandom_range(0,1);
      io_l1_req_ready <= ($urandom_range(0,1));
      io_enable <= ($urandom_range(0,3)!=0);
      pf_ctrl_enable <= ($urandom_range(0,3)!=0);
      pf_ctrl_confidence <= $urandom_range(0,1);
      stride_train_0_valid <= ($urandom_range(0,1));
      stride_train_0_bits_uop_pc <= {38'($urandom_range(0,15)), 12'($urandom)};
      stride_train_0_bits_uop_robIdx_flag <= $urandom_range(0,1);
      stride_train_0_bits_uop_robIdx_value <= 8'($urandom);
      stride_train_0_bits_vaddr <= {38'($urandom_range(0,15)), 12'($urandom)};
      stride_train_1_valid <= ($urandom_range(0,1));
      stride_train_1_bits_uop_pc <= {38'($urandom_range(0,15)), 12'($urandom)};
      stride_train_1_bits_uop_robIdx_flag <= $urandom_range(0,1);
      stride_train_1_bits_uop_robIdx_value <= 8'($urandom);
      stride_train_1_bits_vaddr <= {38'($urandom_range(0,15)), 12'($urandom)};
      stride_train_2_valid <= ($urandom_range(0,1));
      stride_train_2_bits_uop_pc <= {38'($urandom_range(0,15)), 12'($urandom)};
      stride_train_2_bits_uop_robIdx_flag <= $urandom_range(0,1);
      stride_train_2_bits_uop_robIdx_value <= 8'($urandom);
      stride_train_2_bits_vaddr <= {38'($urandom_range(0,15)), 12'($urandom)};
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
    if (!$isunknown(g_io_l1_req_valid) && g_io_l1_req_valid !== i_io_l1_req_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_l1_req_valid g=%h i=%h", $time, g_io_l1_req_valid, i_io_l1_req_valid); end
    if (!$isunknown(g_io_l1_req_bits_paddr) && g_io_l1_req_bits_paddr !== i_io_l1_req_bits_paddr) begin errors++;
      if(errors<=80) $display("[%0t] io_l1_req_bits_paddr g=%h i=%h", $time, g_io_l1_req_bits_paddr, i_io_l1_req_bits_paddr); end
    if (!$isunknown(g_io_l1_req_bits_alias) && g_io_l1_req_bits_alias !== i_io_l1_req_bits_alias) begin errors++;
      if(errors<=80) $display("[%0t] io_l1_req_bits_alias g=%h i=%h", $time, g_io_l1_req_bits_alias, i_io_l1_req_bits_alias); end
    if (!$isunknown(g_io_l1_req_bits_confidence) && g_io_l1_req_bits_confidence !== i_io_l1_req_bits_confidence) begin errors++;
      if(errors<=80) $display("[%0t] io_l1_req_bits_confidence g=%h i=%h", $time, g_io_l1_req_bits_confidence, i_io_l1_req_bits_confidence); end
    if (!$isunknown(g_io_l1_req_bits_is_store) && g_io_l1_req_bits_is_store !== i_io_l1_req_bits_is_store) begin errors++;
      if(errors<=80) $display("[%0t] io_l1_req_bits_is_store g=%h i=%h", $time, g_io_l1_req_bits_is_store, i_io_l1_req_bits_is_store); end
    if (!$isunknown(g_io_l1_req_bits_pf_source_value) && g_io_l1_req_bits_pf_source_value !== i_io_l1_req_bits_pf_source_value) begin errors++;
      if(errors<=80) $display("[%0t] io_l1_req_bits_pf_source_value g=%h i=%h", $time, g_io_l1_req_bits_pf_source_value, i_io_l1_req_bits_pf_source_value); end
    if (!$isunknown(g_io_l2_req_valid) && g_io_l2_req_valid !== i_io_l2_req_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_l2_req_valid g=%h i=%h", $time, g_io_l2_req_valid, i_io_l2_req_valid); end
    if (!$isunknown(g_io_l2_req_bits_addr) && g_io_l2_req_bits_addr !== i_io_l2_req_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] io_l2_req_bits_addr g=%h i=%h", $time, g_io_l2_req_bits_addr, i_io_l2_req_bits_addr); end
    if (!$isunknown(g_io_l2_req_bits_source) && g_io_l2_req_bits_source !== i_io_l2_req_bits_source) begin errors++;
      if(errors<=80) $display("[%0t] io_l2_req_bits_source g=%h i=%h", $time, g_io_l2_req_bits_source, i_io_l2_req_bits_source); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
