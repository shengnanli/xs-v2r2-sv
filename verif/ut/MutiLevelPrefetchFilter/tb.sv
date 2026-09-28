// =============================================================================
// MutiLevelPrefetchFilter UT —— golden MutiLevelPrefetchFilter 对重写 MutiLevelPrefetchFilter_xs
// 双例化，同激励逐拍比对全部 24 根输出（293 位）。
// 本文件由 verif/ut/MutiLevelPrefetchFilter/gen.py 生成（幂等），不要手改。
//
// 激励要点（判别力来自哪里）：
//   · 区域地址从一个小池子里取（每 seed 32 个），让「命中已有项 → update」「不中 → alloc」都常见；
//     另有 1/8 的请求只改 region[39:25] —— 哈希不看这些位，专打「哈希相同、区域不同」的冲突路径；
//   · 负载分相：每 1024 拍换一次两路请求的发送概率（0/15/45/85%），让表有满有空、有替换有闲置；
//   · TLB 用一个 1 拍延迟的回应模型接住 golden 的 io_tlb_req_req（偶尔丢回应 / 凭空回应），
//     miss / 三种异常 / pbmt / PMP 都有小概率，物理地址 85% 落在 PmemRanges 里；
//   · l2 请求的 sink 取 L2/L3 为主，也给 L1 和非法值 3；io_l1_req_ready / io_enable 随机；
//   · 偶发 3 拍复位脉冲（复位期间两侧都不比）。
// 比较窗口：+vcs+initreg+random 下两侧的不复位寄存器初值各摇各的（双例化的已知性质），
//   其中 s1_pf_bits_* 与 s1_tlb_req_bits_* 直接连输出、要等第一次发出才被覆盖；
//   L2/L3 仲裁器在没有候选时照样把某一路（无效项）的地址摆在 io_l2_pf_addr_bits_* 上，
//   那是没写过的表项内容（seed 7 实测：第 32 拍起 10 拍 io_l2_pf_addr_bits_addr 两侧不同）。
//   所以复位释放后先等：golden 各发出过一次 TLB 请求与一次 L1 预取、且两张表的 32 项
//   每一项都被 alloc 过（valid 曾经为 1），再加 4 拍，之后逐拍全比，直到结束。
//   这段等待在 +0 档下同样生效，只影响开头几百～几千拍（checks 数照实打印）。
// 覆盖判据：比较窗口内 L1 预取 / L2 预取 / TLB 请求 / 表命中(update) / TLB 回填作废 等事件
//   每一类都必须发生过，否则本轮 errors=0 不作数（TEST FAILED）。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;

  // ---- 输入（两个 DUT 共用）----
  logic reset;
  logic io_enable;
  logic io_l1_prefetch_req_valid;
  logic [39:0] io_l1_prefetch_req_bits_region;
  logic [15:0] io_l1_prefetch_req_bits_bit_vec;
  logic [2:0] io_l1_prefetch_req_bits_source_value;
  logic io_l2_l3_prefetch_req_valid;
  logic [39:0] io_l2_l3_prefetch_req_bits_region;
  logic [15:0] io_l2_l3_prefetch_req_bits_bit_vec;
  logic [1:0] io_l2_l3_prefetch_req_bits_sink;
  logic [2:0] io_l2_l3_prefetch_req_bits_source_value;
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
  logic io_confidence;

  // ---- 输出：g_ = golden，x_ = 重写 ----
  logic g_io_tlb_req_req_valid, x_io_tlb_req_req_valid;
  logic [49:0] g_io_tlb_req_req_bits_vaddr, x_io_tlb_req_req_bits_vaddr;
  logic [63:0] g_io_tlb_req_req_bits_fullva, x_io_tlb_req_req_bits_fullva;
  logic g_io_tlb_req_req_bits_checkfullva, x_io_tlb_req_req_bits_checkfullva;
  logic [2:0] g_io_tlb_req_req_bits_cmd, x_io_tlb_req_req_bits_cmd;
  logic g_io_tlb_req_req_bits_hyperinst, x_io_tlb_req_req_bits_hyperinst;
  logic g_io_tlb_req_req_bits_hlvx, x_io_tlb_req_req_bits_hlvx;
  logic g_io_tlb_req_req_bits_kill, x_io_tlb_req_req_bits_kill;
  logic g_io_tlb_req_req_bits_isPrefetch, x_io_tlb_req_req_bits_isPrefetch;
  logic g_io_tlb_req_req_bits_no_translate, x_io_tlb_req_req_bits_no_translate;
  logic [47:0] g_io_tlb_req_req_bits_pmp_addr, x_io_tlb_req_req_bits_pmp_addr;
  logic g_io_tlb_req_req_bits_frm_mabuf, x_io_tlb_req_req_bits_frm_mabuf;
  logic g_io_tlb_req_req_bits_debug_robIdx_flag, x_io_tlb_req_req_bits_debug_robIdx_flag;
  logic [7:0] g_io_tlb_req_req_bits_debug_robIdx_value, x_io_tlb_req_req_bits_debug_robIdx_value;
  logic g_io_tlb_req_req_bits_debug_isFirstIssue, x_io_tlb_req_req_bits_debug_isFirstIssue;
  logic g_io_l1_req_valid, x_io_l1_req_valid;
  logic [47:0] g_io_l1_req_bits_paddr, x_io_l1_req_bits_paddr;
  logic [1:0] g_io_l1_req_bits_alias, x_io_l1_req_bits_alias;
  logic g_io_l1_req_bits_confidence, x_io_l1_req_bits_confidence;
  logic g_io_l1_req_bits_is_store, x_io_l1_req_bits_is_store;
  logic [2:0] g_io_l1_req_bits_pf_source_value, x_io_l1_req_bits_pf_source_value;
  logic g_io_l2_pf_addr_valid, x_io_l2_pf_addr_valid;
  logic [47:0] g_io_l2_pf_addr_bits_addr, x_io_l2_pf_addr_bits_addr;
  logic [4:0] g_io_l2_pf_addr_bits_source, x_io_l2_pf_addr_bits_source;

  MutiLevelPrefetchFilter g_dut (
    .clock(clk),
    .reset(reset),
    .io_enable(io_enable),
    .io_l1_prefetch_req_valid(io_l1_prefetch_req_valid),
    .io_l1_prefetch_req_bits_region(io_l1_prefetch_req_bits_region),
    .io_l1_prefetch_req_bits_bit_vec(io_l1_prefetch_req_bits_bit_vec),
    .io_l1_prefetch_req_bits_source_value(io_l1_prefetch_req_bits_source_value),
    .io_l2_l3_prefetch_req_valid(io_l2_l3_prefetch_req_valid),
    .io_l2_l3_prefetch_req_bits_region(io_l2_l3_prefetch_req_bits_region),
    .io_l2_l3_prefetch_req_bits_bit_vec(io_l2_l3_prefetch_req_bits_bit_vec),
    .io_l2_l3_prefetch_req_bits_sink(io_l2_l3_prefetch_req_bits_sink),
    .io_l2_l3_prefetch_req_bits_source_value(io_l2_l3_prefetch_req_bits_source_value),
    .io_tlb_req_resp_valid(io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt_0(io_tlb_req_resp_bits_pbmt_0),
    .io_tlb_req_resp_bits_miss(io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(io_tlb_req_resp_bits_excp_0_af_ld),
    .io_pmp_resp_ld(io_pmp_resp_ld),
    .io_pmp_resp_mmio(io_pmp_resp_mmio),
    .io_l1_req_ready(io_l1_req_ready),
    .io_confidence(io_confidence),
    .io_tlb_req_req_valid(g_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(g_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_fullva(g_io_tlb_req_req_bits_fullva),
    .io_tlb_req_req_bits_checkfullva(g_io_tlb_req_req_bits_checkfullva),
    .io_tlb_req_req_bits_cmd(g_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_hyperinst(g_io_tlb_req_req_bits_hyperinst),
    .io_tlb_req_req_bits_hlvx(g_io_tlb_req_req_bits_hlvx),
    .io_tlb_req_req_bits_kill(g_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_isPrefetch(g_io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_no_translate(g_io_tlb_req_req_bits_no_translate),
    .io_tlb_req_req_bits_pmp_addr(g_io_tlb_req_req_bits_pmp_addr),
    .io_tlb_req_req_bits_frm_mabuf(g_io_tlb_req_req_bits_frm_mabuf),
    .io_tlb_req_req_bits_debug_robIdx_flag(g_io_tlb_req_req_bits_debug_robIdx_flag),
    .io_tlb_req_req_bits_debug_robIdx_value(g_io_tlb_req_req_bits_debug_robIdx_value),
    .io_tlb_req_req_bits_debug_isFirstIssue(g_io_tlb_req_req_bits_debug_isFirstIssue),
    .io_l1_req_valid(g_io_l1_req_valid),
    .io_l1_req_bits_paddr(g_io_l1_req_bits_paddr),
    .io_l1_req_bits_alias(g_io_l1_req_bits_alias),
    .io_l1_req_bits_confidence(g_io_l1_req_bits_confidence),
    .io_l1_req_bits_is_store(g_io_l1_req_bits_is_store),
    .io_l1_req_bits_pf_source_value(g_io_l1_req_bits_pf_source_value),
    .io_l2_pf_addr_valid(g_io_l2_pf_addr_valid),
    .io_l2_pf_addr_bits_addr(g_io_l2_pf_addr_bits_addr),
    .io_l2_pf_addr_bits_source(g_io_l2_pf_addr_bits_source)
  );

  MutiLevelPrefetchFilter_xs x_dut (
    .clock(clk),
    .reset(reset),
    .io_enable(io_enable),
    .io_l1_prefetch_req_valid(io_l1_prefetch_req_valid),
    .io_l1_prefetch_req_bits_region(io_l1_prefetch_req_bits_region),
    .io_l1_prefetch_req_bits_bit_vec(io_l1_prefetch_req_bits_bit_vec),
    .io_l1_prefetch_req_bits_source_value(io_l1_prefetch_req_bits_source_value),
    .io_l2_l3_prefetch_req_valid(io_l2_l3_prefetch_req_valid),
    .io_l2_l3_prefetch_req_bits_region(io_l2_l3_prefetch_req_bits_region),
    .io_l2_l3_prefetch_req_bits_bit_vec(io_l2_l3_prefetch_req_bits_bit_vec),
    .io_l2_l3_prefetch_req_bits_sink(io_l2_l3_prefetch_req_bits_sink),
    .io_l2_l3_prefetch_req_bits_source_value(io_l2_l3_prefetch_req_bits_source_value),
    .io_tlb_req_resp_valid(io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt_0(io_tlb_req_resp_bits_pbmt_0),
    .io_tlb_req_resp_bits_miss(io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(io_tlb_req_resp_bits_excp_0_af_ld),
    .io_pmp_resp_ld(io_pmp_resp_ld),
    .io_pmp_resp_mmio(io_pmp_resp_mmio),
    .io_l1_req_ready(io_l1_req_ready),
    .io_confidence(io_confidence),
    .io_tlb_req_req_valid(x_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(x_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_fullva(x_io_tlb_req_req_bits_fullva),
    .io_tlb_req_req_bits_checkfullva(x_io_tlb_req_req_bits_checkfullva),
    .io_tlb_req_req_bits_cmd(x_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_hyperinst(x_io_tlb_req_req_bits_hyperinst),
    .io_tlb_req_req_bits_hlvx(x_io_tlb_req_req_bits_hlvx),
    .io_tlb_req_req_bits_kill(x_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_isPrefetch(x_io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_no_translate(x_io_tlb_req_req_bits_no_translate),
    .io_tlb_req_req_bits_pmp_addr(x_io_tlb_req_req_bits_pmp_addr),
    .io_tlb_req_req_bits_frm_mabuf(x_io_tlb_req_req_bits_frm_mabuf),
    .io_tlb_req_req_bits_debug_robIdx_flag(x_io_tlb_req_req_bits_debug_robIdx_flag),
    .io_tlb_req_req_bits_debug_robIdx_value(x_io_tlb_req_req_bits_debug_robIdx_value),
    .io_tlb_req_req_bits_debug_isFirstIssue(x_io_tlb_req_req_bits_debug_isFirstIssue),
    .io_l1_req_valid(x_io_l1_req_valid),
    .io_l1_req_bits_paddr(x_io_l1_req_bits_paddr),
    .io_l1_req_bits_alias(x_io_l1_req_bits_alias),
    .io_l1_req_bits_confidence(x_io_l1_req_bits_confidence),
    .io_l1_req_bits_is_store(x_io_l1_req_bits_is_store),
    .io_l1_req_bits_pf_source_value(x_io_l1_req_bits_pf_source_value),
    .io_l2_pf_addr_valid(x_io_l2_pf_addr_valid),
    .io_l2_pf_addr_bits_addr(x_io_l2_pf_addr_bits_addr),
    .io_l2_pf_addr_bits_source(x_io_l2_pf_addr_bits_source)
  );

  // ---- 逐拍比较全部输出 ----
  task automatic compare_outputs();
    checks++;
    if (g_io_tlb_req_req_valid !== x_io_tlb_req_req_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_valid g=%h x=%h", $time, g_io_tlb_req_req_valid, x_io_tlb_req_req_valid); end
    if (g_io_tlb_req_req_bits_vaddr !== x_io_tlb_req_req_bits_vaddr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_vaddr g=%h x=%h", $time, g_io_tlb_req_req_bits_vaddr, x_io_tlb_req_req_bits_vaddr); end
    if (g_io_tlb_req_req_bits_fullva !== x_io_tlb_req_req_bits_fullva) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_fullva g=%h x=%h", $time, g_io_tlb_req_req_bits_fullva, x_io_tlb_req_req_bits_fullva); end
    if (g_io_tlb_req_req_bits_checkfullva !== x_io_tlb_req_req_bits_checkfullva) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_checkfullva g=%h x=%h", $time, g_io_tlb_req_req_bits_checkfullva, x_io_tlb_req_req_bits_checkfullva); end
    if (g_io_tlb_req_req_bits_cmd !== x_io_tlb_req_req_bits_cmd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_cmd g=%h x=%h", $time, g_io_tlb_req_req_bits_cmd, x_io_tlb_req_req_bits_cmd); end
    if (g_io_tlb_req_req_bits_hyperinst !== x_io_tlb_req_req_bits_hyperinst) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_hyperinst g=%h x=%h", $time, g_io_tlb_req_req_bits_hyperinst, x_io_tlb_req_req_bits_hyperinst); end
    if (g_io_tlb_req_req_bits_hlvx !== x_io_tlb_req_req_bits_hlvx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_hlvx g=%h x=%h", $time, g_io_tlb_req_req_bits_hlvx, x_io_tlb_req_req_bits_hlvx); end
    if (g_io_tlb_req_req_bits_kill !== x_io_tlb_req_req_bits_kill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_kill g=%h x=%h", $time, g_io_tlb_req_req_bits_kill, x_io_tlb_req_req_bits_kill); end
    if (g_io_tlb_req_req_bits_isPrefetch !== x_io_tlb_req_req_bits_isPrefetch) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_isPrefetch g=%h x=%h", $time, g_io_tlb_req_req_bits_isPrefetch, x_io_tlb_req_req_bits_isPrefetch); end
    if (g_io_tlb_req_req_bits_no_translate !== x_io_tlb_req_req_bits_no_translate) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_no_translate g=%h x=%h", $time, g_io_tlb_req_req_bits_no_translate, x_io_tlb_req_req_bits_no_translate); end
    if (g_io_tlb_req_req_bits_pmp_addr !== x_io_tlb_req_req_bits_pmp_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_pmp_addr g=%h x=%h", $time, g_io_tlb_req_req_bits_pmp_addr, x_io_tlb_req_req_bits_pmp_addr); end
    if (g_io_tlb_req_req_bits_frm_mabuf !== x_io_tlb_req_req_bits_frm_mabuf) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_frm_mabuf g=%h x=%h", $time, g_io_tlb_req_req_bits_frm_mabuf, x_io_tlb_req_req_bits_frm_mabuf); end
    if (g_io_tlb_req_req_bits_debug_robIdx_flag !== x_io_tlb_req_req_bits_debug_robIdx_flag) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_debug_robIdx_flag g=%h x=%h", $time, g_io_tlb_req_req_bits_debug_robIdx_flag, x_io_tlb_req_req_bits_debug_robIdx_flag); end
    if (g_io_tlb_req_req_bits_debug_robIdx_value !== x_io_tlb_req_req_bits_debug_robIdx_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_debug_robIdx_value g=%h x=%h", $time, g_io_tlb_req_req_bits_debug_robIdx_value, x_io_tlb_req_req_bits_debug_robIdx_value); end
    if (g_io_tlb_req_req_bits_debug_isFirstIssue !== x_io_tlb_req_req_bits_debug_isFirstIssue) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_tlb_req_req_bits_debug_isFirstIssue g=%h x=%h", $time, g_io_tlb_req_req_bits_debug_isFirstIssue, x_io_tlb_req_req_bits_debug_isFirstIssue); end
    if (g_io_l1_req_valid !== x_io_l1_req_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_l1_req_valid g=%h x=%h", $time, g_io_l1_req_valid, x_io_l1_req_valid); end
    if (g_io_l1_req_bits_paddr !== x_io_l1_req_bits_paddr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_l1_req_bits_paddr g=%h x=%h", $time, g_io_l1_req_bits_paddr, x_io_l1_req_bits_paddr); end
    if (g_io_l1_req_bits_alias !== x_io_l1_req_bits_alias) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_l1_req_bits_alias g=%h x=%h", $time, g_io_l1_req_bits_alias, x_io_l1_req_bits_alias); end
    if (g_io_l1_req_bits_confidence !== x_io_l1_req_bits_confidence) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_l1_req_bits_confidence g=%h x=%h", $time, g_io_l1_req_bits_confidence, x_io_l1_req_bits_confidence); end
    if (g_io_l1_req_bits_is_store !== x_io_l1_req_bits_is_store) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_l1_req_bits_is_store g=%h x=%h", $time, g_io_l1_req_bits_is_store, x_io_l1_req_bits_is_store); end
    if (g_io_l1_req_bits_pf_source_value !== x_io_l1_req_bits_pf_source_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_l1_req_bits_pf_source_value g=%h x=%h", $time, g_io_l1_req_bits_pf_source_value, x_io_l1_req_bits_pf_source_value); end
    if (g_io_l2_pf_addr_valid !== x_io_l2_pf_addr_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_l2_pf_addr_valid g=%h x=%h", $time, g_io_l2_pf_addr_valid, x_io_l2_pf_addr_valid); end
    if (g_io_l2_pf_addr_bits_addr !== x_io_l2_pf_addr_bits_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_l2_pf_addr_bits_addr g=%h x=%h", $time, g_io_l2_pf_addr_bits_addr, x_io_l2_pf_addr_bits_addr); end
    if (g_io_l2_pf_addr_bits_source !== x_io_l2_pf_addr_bits_source) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_l2_pf_addr_bits_source g=%h x=%h", $time, g_io_l2_pf_addr_bits_source, x_io_l2_pf_addr_bits_source); end
  endtask


  // ---- 激励 ----
  logic [39:0] pool [32];
  int unsigned load_l1, load_l2;          // 当前相位的两路请求概率（%）
  bit          l1_req_is_alias;           // 本拍 L1 请求是不是「只改了高位」的那种

  function automatic logic [39:0] pick_region(output bit is_alias);
    int p = $urandom_range(0, 99);
    logic [39:0] r = pool[$urandom_range(0, 31)];
    is_alias = (p < 12);
    if (p < 12)      r[39:25] = 15'($urandom);                // 哈希相同、区域不同
    else if (p < 20) r = {8'($urandom), 32'($urandom)};       // 全随机
    return r;
  endfunction

  function automatic logic [15:0] pick_bitvec();
    int p = $urandom_range(0, 99);
    if (p < 3)  return 16'h0;
    if (p < 25) return 16'h1 << $urandom_range(0, 15);
    if (p < 35) return 16'hFFFF;
    return 16'($urandom);
  endfunction

  function automatic logic [2:0] pick_source();
    int p = $urandom_range(0, 99);
    if (p < 40) return 3'd3;       // stream
    if (p < 75) return 3'd2;       // stride
    return 3'($urandom);
  endfunction

  function automatic logic [1:0] pick_sink();
    int p = $urandom_range(0, 99);
    if (p < 45) return 2'd1;       // L2
    if (p < 90) return 2'd2;       // L3
    if (p < 97) return 2'd0;       // L1（上游不会给 L2 表发 L1，但端口是自由的）
    return 2'd3;                   // 非法编码
  endfunction

  // TLB 回应模型：golden 在第 t 拍发请求，第 t+1 拍回应（偶尔丢 / 凭空多一个）
  logic tlb_req_q = 1'b0;
  always @(posedge clk) tlb_req_q <= g_io_tlb_req_req_valid;

  task automatic drive_inputs(longint c);
    bit dummy_alias;
    if (c % 1024 == 0) begin
      int ph = $urandom_range(0, 3);
      load_l1 = (ph == 0) ? 0 : (ph == 1) ? 15 : (ph == 2) ? 45 : 85;
      ph = $urandom_range(0, 3);
      load_l2 = (ph == 0) ? 0 : (ph == 1) ? 15 : (ph == 2) ? 45 : 85;
    end
    io_enable                  = ($urandom_range(0, 99) < 92);
    io_confidence              = 1'($urandom);
    io_l1_prefetch_req_valid   = ($urandom_range(0, 99) < load_l1);
    io_l1_prefetch_req_bits_region       = pick_region(l1_req_is_alias);
    io_l1_prefetch_req_bits_bit_vec      = pick_bitvec();
    io_l1_prefetch_req_bits_source_value = pick_source();
    io_l2_l3_prefetch_req_valid = ($urandom_range(0, 99) < load_l2);
    io_l2_l3_prefetch_req_bits_region       = pick_region(dummy_alias);
    io_l2_l3_prefetch_req_bits_bit_vec      = pick_bitvec();
    io_l2_l3_prefetch_req_bits_sink         = pick_sink();
    io_l2_l3_prefetch_req_bits_source_value = pick_source();
    // TLB 回应
    io_tlb_req_resp_valid = tlb_req_q ? ($urandom_range(0, 99) < 95) : ($urandom_range(0, 99) < 2);
    if ($urandom_range(0, 99) < 85) begin            // 落在 PmemRanges [0x8000_0000, 0x800_0000_0000)
      io_tlb_req_resp_bits_paddr_0 = {5'h0, 11'($urandom), 32'($urandom)};
      if (io_tlb_req_resp_bits_paddr_0 < 48'h8000_0000) io_tlb_req_resp_bits_paddr_0[31] = 1'b1;
    end else begin
      io_tlb_req_resp_bits_paddr_0 = {16'($urandom), 32'($urandom)};
    end
    io_tlb_req_resp_bits_pbmt_0        = ($urandom_range(0, 99) < 85) ? 2'd0 : 2'($urandom);
    io_tlb_req_resp_bits_miss          = ($urandom_range(0, 99) < 15);
    io_tlb_req_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 99) < 3);
    io_tlb_req_resp_bits_excp_0_pf_ld  = ($urandom_range(0, 99) < 3);
    io_tlb_req_resp_bits_excp_0_af_ld  = ($urandom_range(0, 99) < 3);
    io_pmp_resp_ld   = ($urandom_range(0, 99) < 3);
    io_pmp_resp_mmio = ($urandom_range(0, 99) < 3);
    io_l1_req_ready  = ($urandom_range(0, 99) < 75);
  endtask

  // ---- 覆盖事件（golden 侧计数，比较窗口内）----
  longint n_l1_fire, n_l2_pf, n_tlb_req, n_update_l1, n_update_l2, n_drop, n_hash_alias;
  task automatic collect_cov();
    if (g_io_l1_req_valid && io_l1_req_ready) n_l1_fire++;
    if (g_io_l2_pf_addr_valid)                n_l2_pf++;
    if (g_io_tlb_req_req_valid)               n_tlb_req++;
    if (g_dut.s1_l1_valid && g_dut.s1_l1_hit) n_update_l1++;
    if (g_dut.s1_l2_valid && g_dut.s1_l2_hit) n_update_l2++;
    if (g_dut.s3_drop)                        n_drop++;
    if (io_l1_prefetch_req_valid && l1_req_is_alias && g_dut.s0_l1_can_accept) n_hash_alias++;
  endtask

  // 两张表每一项是否被 alloc 过（热身判据，见文件头）
  logic [31:0] ever_valid = '0;
  always @(posedge clk) ever_valid <= ever_valid | {g_dut.l2_valids_15, g_dut.l2_valids_14, g_dut.l2_valids_13, g_dut.l2_valids_12, g_dut.l2_valids_11, g_dut.l2_valids_10, g_dut.l2_valids_9, g_dut.l2_valids_8, g_dut.l2_valids_7, g_dut.l2_valids_6, g_dut.l2_valids_5, g_dut.l2_valids_4, g_dut.l2_valids_3, g_dut.l2_valids_2, g_dut.l2_valids_1, g_dut.l2_valids_0, g_dut.l1_valids_15, g_dut.l1_valids_14, g_dut.l1_valids_13, g_dut.l1_valids_12, g_dut.l1_valids_11, g_dut.l1_valids_10, g_dut.l1_valids_9, g_dut.l1_valids_8, g_dut.l1_valids_7, g_dut.l1_valids_6, g_dut.l1_valids_5, g_dut.l1_valids_4, g_dut.l1_valids_3, g_dut.l1_valids_2, g_dut.l1_valids_1, g_dut.l1_valids_0};

  initial begin
    bit warm_tlb, warm_l1;
    int warm_cnt;
    bit cmp_on;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < 32; i++) pool[i] = {8'($urandom), 32'($urandom)};
    load_l1 = 45; load_l2 = 45;
    warm_tlb = 0; warm_l1 = 0; warm_cnt = 0; cmp_on = 0;
    reset = 1;
    drive_inputs(1);
    repeat (10) @(negedge clk);
    reset = 0;
    for (longint c = 0; c < NCYCLES; c++) begin
      // 偶发复位脉冲：拉 3 拍，期间不比；不复位寄存器两侧保持相同，复位后不必重新热身
      if (c > 1000 && $urandom_range(0, 39999) == 0) begin
        reset = 1;
        repeat (3) begin drive_inputs(c); @(negedge clk); end
        reset = 0;
      end
      drive_inputs(c);
      #1;
      if (g_io_tlb_req_req_valid) warm_tlb = 1;
      if (g_io_l1_req_valid)      warm_l1  = 1;
      if (warm_tlb && warm_l1 && (&ever_valid) && !cmp_on) begin
        warm_cnt++;
        if (warm_cnt > 4) cmp_on = 1;
      end
      if (cmp_on) begin compare_outputs(); collect_cov(); end
      @(negedge clk);
    end
    $display("=== COVERAGE (MutiLevelPrefetchFilter) === checks=%0d l1_fire=%0d l2_pf=%0d tlb_req=%0d upd_l1=%0d upd_l2=%0d drop=%0d hash_alias=%0d",
             checks, n_l1_fire, n_l2_pf, n_tlb_req, n_update_l1, n_update_l2, n_drop, n_hash_alias);
    if (checks < NCYCLES - 2000 || n_l1_fire == 0 || n_l2_pf == 0 || n_tlb_req == 0 ||
        n_update_l1 == 0 || n_update_l2 == 0 || n_drop == 0 || n_hash_alias == 0) begin
      $display("COVERAGE INSUFFICIENT");
      errors++;
    end
    if (errors == 0) $display("TEST PASSED (checks=%0d errors=0)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
