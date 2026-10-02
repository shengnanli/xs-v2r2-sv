// =============================================================================
// PrefetchFilter UT —— golden PrefetchFilter 对重写 PrefetchFilter_xs 双例化，同激励逐拍比对全部 18 根输出。
//
// 激励要点（判别力来自哪里）：
//   · 区域请求从 24 个区域的池子取（命中 → update / 不中 → alloc / PLRU 替换），1/8 概率连发同一区域
//     （s0 去重路径）；tag 由区域地址哈希出来，另有 1/16 给一个随机 tag（tag 撞车）；
//     paddr_valid 约一半（已是物理地址的请求直接可发 L2），decr_mode 随机，region_bits 随机。
//   · TLB 模型：golden 发出 TLB 请求的下一拍给回应（与 s1→s2→s3 的时序一致），偶尔丢回应 / 凭空回应；
//     miss / 三种异常 / pbmt(NC/IO) / PMP(ld/mmio) 都有小概率，触发「作废」路径。
//   · 负载分相：每 2048 拍换一次请求概率（5/30/70/100%），让表有满有空。
//   · 偶发 3 拍复位脉冲（复位期间不比）。
// 比较窗口：+random 档两侧不复位寄存器初值各摇各的。TLB 请求 bits 是不复位寄存器直接驱动、
//   L2 仲裁器在没有候选时也把某一路（可能是没写过的表项）的地址摆在 io_l2_pf_addr_bits 上，
//   所以复位释放后先等：golden 发过一次 TLB 请求、16 项每一项都 alloc 过，再加 4 拍，之后逐拍全比。
//   两路 valid 从复位释放起就比（它们只依赖复位过的状态和写过的表项）。
// 覆盖判据：窗口内 alloc / update / 去重丢弃 / TLB 请求 / TLB 回填成功 / 作废 / 撤销 TLB 请求 /
//   L2 预取（递增与递减各自）每一类都必须发生过，否则本轮不作数（TEST FAILED）。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;

  // ---- 输入（两个 DUT 共用）----
  logic        reset;
  logic        io_gen_req_valid;
  logic [10:0] io_gen_req_bits_region_tag;
  logic [39:0] io_gen_req_bits_region_addr;
  logic [15:0] io_gen_req_bits_region_bits;
  logic        io_gen_req_bits_paddr_valid;
  logic        io_gen_req_bits_decr_mode;
  logic        io_tlb_req_resp_valid;
  logic [47:0] io_tlb_req_resp_bits_paddr_0;
  logic [1:0]  io_tlb_req_resp_bits_pbmt_0;
  logic        io_tlb_req_resp_bits_miss;
  logic        io_tlb_req_resp_bits_excp_0_gpf_ld;
  logic        io_tlb_req_resp_bits_excp_0_pf_ld;
  logic        io_tlb_req_resp_bits_excp_0_af_ld;
  logic        io_pmp_resp_ld;
  logic        io_pmp_resp_mmio;

  // ---- 输出：g_ = golden，x_ = 重写（打包成一个向量逐位比，名字表见 out_names）----
  logic        g_tlb_valid, x_tlb_valid;
  logic [49:0] g_vaddr, x_vaddr;
  logic [63:0] g_fullva, x_fullva;
  logic        g_checkfullva, x_checkfullva;
  logic [2:0]  g_cmd, x_cmd;
  logic        g_hyperinst, x_hyperinst;
  logic        g_hlvx, x_hlvx;
  logic        g_kill, x_kill;
  logic        g_isPrefetch, x_isPrefetch;
  logic        g_no_translate, x_no_translate;
  logic [47:0] g_pmp_addr, x_pmp_addr;
  logic        g_frm_mabuf, x_frm_mabuf;
  logic        g_rob_flag, x_rob_flag;
  logic [7:0]  g_rob_value, x_rob_value;
  logic        g_first_issue, x_first_issue;
  logic        g_l2_valid, x_l2_valid;
  logic [47:0] g_l2_addr, x_l2_addr;

`define PFF_PORTS(P) \
    .clock                                   (clk), \
    .reset                                   (reset), \
    .io_gen_req_valid                        (io_gen_req_valid), \
    .io_gen_req_bits_region_tag              (io_gen_req_bits_region_tag), \
    .io_gen_req_bits_region_addr             (io_gen_req_bits_region_addr), \
    .io_gen_req_bits_region_bits             (io_gen_req_bits_region_bits), \
    .io_gen_req_bits_paddr_valid             (io_gen_req_bits_paddr_valid), \
    .io_gen_req_bits_decr_mode               (io_gen_req_bits_decr_mode), \
    .io_tlb_req_req_valid                    (P``_tlb_valid), \
    .io_tlb_req_req_bits_vaddr               (P``_vaddr), \
    .io_tlb_req_req_bits_fullva              (P``_fullva), \
    .io_tlb_req_req_bits_checkfullva         (P``_checkfullva), \
    .io_tlb_req_req_bits_cmd                 (P``_cmd), \
    .io_tlb_req_req_bits_hyperinst           (P``_hyperinst), \
    .io_tlb_req_req_bits_hlvx                (P``_hlvx), \
    .io_tlb_req_req_bits_kill                (P``_kill), \
    .io_tlb_req_req_bits_isPrefetch          (P``_isPrefetch), \
    .io_tlb_req_req_bits_no_translate        (P``_no_translate), \
    .io_tlb_req_req_bits_pmp_addr            (P``_pmp_addr), \
    .io_tlb_req_req_bits_frm_mabuf           (P``_frm_mabuf), \
    .io_tlb_req_req_bits_debug_robIdx_flag   (P``_rob_flag), \
    .io_tlb_req_req_bits_debug_robIdx_value  (P``_rob_value), \
    .io_tlb_req_req_bits_debug_isFirstIssue  (P``_first_issue), \
    .io_tlb_req_resp_valid                   (io_tlb_req_resp_valid), \
    .io_tlb_req_resp_bits_paddr_0            (io_tlb_req_resp_bits_paddr_0), \
    .io_tlb_req_resp_bits_pbmt_0             (io_tlb_req_resp_bits_pbmt_0), \
    .io_tlb_req_resp_bits_miss               (io_tlb_req_resp_bits_miss), \
    .io_tlb_req_resp_bits_excp_0_gpf_ld      (io_tlb_req_resp_bits_excp_0_gpf_ld), \
    .io_tlb_req_resp_bits_excp_0_pf_ld       (io_tlb_req_resp_bits_excp_0_pf_ld), \
    .io_tlb_req_resp_bits_excp_0_af_ld       (io_tlb_req_resp_bits_excp_0_af_ld), \
    .io_pmp_resp_ld                          (io_pmp_resp_ld), \
    .io_pmp_resp_mmio                        (io_pmp_resp_mmio), \
    .io_l2_pf_addr_valid                     (P``_l2_valid), \
    .io_l2_pf_addr_bits                      (P``_l2_addr)

  PrefetchFilter    g_dut (`PFF_PORTS(g));
  PrefetchFilter_xs x_dut (`PFF_PORTS(x));

  // ---- 激励 ----
  logic [39:0] pool [24];
  int          load_pct;
  logic [39:0] last_addr;
  logic [10:0] last_tag;
  bit          tlb_req_d1;          // golden 上一拍发了 TLB 请求

  function automatic logic [10:0] tag_of(input logic [39:0] r);
    return {r[10:6] ^ r[15:11] ^ r[20:16], r[5:0]};
  endfunction

  task automatic drive_inputs(input longint c);
    logic [39:0] r;
    if (c % 2048 == 0) begin
      case ($urandom_range(0, 3))
        0: load_pct = 5;
        1: load_pct = 30;
        2: load_pct = 70;
        default: load_pct = 100;
      endcase
    end
    io_gen_req_valid = ($urandom_range(1, 100) <= load_pct);
    if ($urandom_range(0, 7) == 0) r = last_addr;
    else                           r = pool[$urandom_range(0, 23)];
    io_gen_req_bits_region_addr = r;
    io_gen_req_bits_region_tag  = ($urandom_range(0, 15) == 0) ? 11'($urandom) : tag_of(r);
    io_gen_req_bits_region_bits = 16'($urandom) & 16'($urandom);
    io_gen_req_bits_paddr_valid = $urandom_range(0, 1);
    io_gen_req_bits_decr_mode   = $urandom_range(0, 1);
    if (io_gen_req_valid) begin last_addr = r; last_tag = io_gen_req_bits_region_tag; end
    // TLB 回应：上一拍 golden 发了请求就回（偶尔丢），另有极小概率凭空回
    io_tlb_req_resp_valid              = tlb_req_d1 ? ($urandom_range(0, 15) != 0) : ($urandom_range(0, 199) == 0);
    io_tlb_req_resp_bits_paddr_0       = {16'($urandom), 32'($urandom)};
    io_tlb_req_resp_bits_pbmt_0        = ($urandom_range(0, 15) == 0) ? 2'($urandom) : 2'd0;
    io_tlb_req_resp_bits_miss          = ($urandom_range(0, 7) == 0);
    io_tlb_req_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 31) == 0);
    io_tlb_req_resp_bits_excp_0_pf_ld  = ($urandom_range(0, 31) == 0);
    io_tlb_req_resp_bits_excp_0_af_ld  = ($urandom_range(0, 31) == 0);
    io_pmp_resp_ld                     = ($urandom_range(0, 31) == 0);
    io_pmp_resp_mmio                   = ($urandom_range(0, 31) == 0);
  endtask

  // ---- 比较 ----
  task automatic cmp1(input string name, input logic [63:0] g, input logic [63:0] x);
    checks++;
    if (g !== x) begin
      errors++;
      if (errors <= 20) $display("[%0t] MISMATCH %s golden=%h rewrite=%h", $time, name, g, x);
    end
  endtask

  task automatic compare_valids();
    cmp1("io_tlb_req_req_valid", g_tlb_valid, x_tlb_valid);
    cmp1("io_l2_pf_addr_valid",  g_l2_valid,  x_l2_valid);
  endtask

  task automatic compare_bits();
    cmp1("io_tlb_req_req_bits_vaddr",              g_vaddr,       x_vaddr);
    cmp1("io_tlb_req_req_bits_fullva",             g_fullva,      x_fullva);
    cmp1("io_tlb_req_req_bits_checkfullva",        g_checkfullva, x_checkfullva);
    cmp1("io_tlb_req_req_bits_cmd",                g_cmd,         x_cmd);
    cmp1("io_tlb_req_req_bits_hyperinst",          g_hyperinst,   x_hyperinst);
    cmp1("io_tlb_req_req_bits_hlvx",               g_hlvx,        x_hlvx);
    cmp1("io_tlb_req_req_bits_kill",               g_kill,        x_kill);
    cmp1("io_tlb_req_req_bits_isPrefetch",         g_isPrefetch,  x_isPrefetch);
    cmp1("io_tlb_req_req_bits_no_translate",       g_no_translate, x_no_translate);
    cmp1("io_tlb_req_req_bits_pmp_addr",           g_pmp_addr,    x_pmp_addr);
    cmp1("io_tlb_req_req_bits_frm_mabuf",          g_frm_mabuf,   x_frm_mabuf);
    cmp1("io_tlb_req_req_bits_debug_robIdx_flag",  g_rob_flag,    x_rob_flag);
    cmp1("io_tlb_req_req_bits_debug_robIdx_value", g_rob_value,   x_rob_value);
    cmp1("io_tlb_req_req_bits_debug_isFirstIssue", g_first_issue, x_first_issue);
    cmp1("io_l2_pf_addr_bits",                     g_l2_addr,     x_l2_addr);
  endtask

  // ---- 覆盖事件（golden 侧计数）----
  longint n_alloc, n_update, n_dedup, n_tlb, n_fill, n_drop, n_cancel, n_pf_incr, n_pf_decr;
  logic [15:0] ever_valid = '0;
  always @(posedge clk)
    ever_valid <= ever_valid | {g_dut.valids_15, g_dut.valids_14, g_dut.valids_13, g_dut.valids_12,
                                g_dut.valids_11, g_dut.valids_10, g_dut.valids_9,  g_dut.valids_8,
                                g_dut.valids_7,  g_dut.valids_6,  g_dut.valids_5,  g_dut.valids_4,
                                g_dut.valids_3,  g_dut.valids_2,  g_dut.valids_1,  g_dut.valids_0};

  task automatic collect_cov();
    if (g_dut.s1_valid_r_last_REG && !g_dut.s1_hit_r)              n_alloc++;
    if (g_dut._update_T_30_probe)                                   n_update++;
    if (io_gen_req_valid && !g_dut.s0_gen_req_valid)                n_dedup++;
    if (g_tlb_valid)                                                n_tlb++;
    if (g_dut.s3_update_valid && !g_dut.s3_drop_probe)              n_fill++;
    if (g_dut.s3_drop_probe)                                        n_drop++;
    if (g_dut.s1_tlb_req_valid_last_REG && !g_tlb_valid)            n_cancel++;
    if (g_l2_valid && !g_l2_addr[6])                                n_pf_incr++;   // 粗分：行号奇偶两类都要有
    if (g_l2_valid &&  g_l2_addr[6])                                n_pf_decr++;
  endtask

  initial begin
    bit warm_tlb, cmp_on;
    int warm_cnt;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < 24; i++) pool[i] = {8'($urandom), 32'($urandom)};
    load_pct = 30; last_addr = pool[0]; tlb_req_d1 = 0;
    warm_tlb = 0; cmp_on = 0; warm_cnt = 0;
    reset = 1;
    drive_inputs(1);
    repeat (10) @(negedge clk);
    reset = 0;
    for (longint c = 0; c < NCYCLES; c++) begin
      if (c > 1000 && $urandom_range(0, 39999) == 0) begin
        reset = 1;
        repeat (3) begin drive_inputs(c); @(negedge clk); end
        reset = 0;
        tlb_req_d1 = 0;
      end
      drive_inputs(c);
      #1;
      if (g_tlb_valid) warm_tlb = 1;
      if (warm_tlb && (&ever_valid) && !cmp_on) begin
        warm_cnt++;
        if (warm_cnt > 4) cmp_on = 1;
      end
      compare_valids();
      if (cmp_on) begin compare_bits(); collect_cov(); end
      else if (g_l2_valid) cmp1("io_l2_pf_addr_bits", g_l2_addr, x_l2_addr);
      tlb_req_d1 = g_tlb_valid;
      @(negedge clk);
    end
    $display("=== COVERAGE (PrefetchFilter) === checks=%0d alloc=%0d update=%0d dedup=%0d tlb_req=%0d fill=%0d drop=%0d cancel=%0d pf_even=%0d pf_odd=%0d",
             checks, n_alloc, n_update, n_dedup, n_tlb, n_fill, n_drop, n_cancel, n_pf_incr, n_pf_decr);
    if (n_alloc == 0 || n_update == 0 || n_dedup == 0 || n_tlb == 0 || n_fill == 0 || n_drop == 0 ||
        n_cancel == 0 || n_pf_incr == 0 || n_pf_decr == 0) begin
      $display("COVERAGE INSUFFICIENT");
      errors++;
    end
    if (errors == 0) $display("TEST PASSED (checks=%0d errors=0)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
