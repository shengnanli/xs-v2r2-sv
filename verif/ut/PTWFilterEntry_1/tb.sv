// =============================================================================
// PTWFilterEntry_1 UT —— golden PTWFilterEntry_1 对重写 PTWFilterEntry_1_xs 双例化，同激励逐拍比对全部 6 根输出。
//
// 激励要点（判别力来自哪里）：
//   · 2 条 lane 的 miss vpn 从 10 项小池子取，常常两条 lane 同页（"更低 lane 同页 → 借用 id"路径）、
//     与表内已有项同页（"已在表"路径）、与本拍回来的 PTW 响应同页；池里有同一 2MB 区域的几页，
//     PTW 回 level=1 的超页时一次销掉多项。每 lane 只有 4 项，分区满很常见。
//   · PTW 模型：golden 发出的请求被收下后 1~6 拍回应（命中键按那一页拼），偶尔凭空回应；
//     ptw_req.ready 随机（60%）；flush 1%；s2xlate 取 0~3。
//   · 偶发 3 拍复位脉冲（复位期间不比）。
// 比较窗口：表项载荷不复位，空表时 ptw_req.bits / getGpa 输出第 0 项的载荷，+random 档两侧不同。
//   所以先等 golden 8 项每一项都入过表，再加 4 拍，之后逐拍全比。
// 覆盖判据（在重写核的语义名上数；输出逐拍相等，所以与 golden 同值）：入表 / 已在表去重 /
//   同拍同页借 id / 响应同页不入 / 分区满 / PTW 发出 / refill / 一次销多项 / getGpa / rob_head_miss /
//   flush 时表非空 —— 每一类都必须发生过，否则本轮不作数（TEST FAILED）。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;

  // ---- 输入（两个 DUT 共用）/ 输出（g_ = golden，x_ = 重写）----
  logic reset;
  logic [15:0] io_csr_satp_asid;
  logic [15:0] io_csr_vsatp_asid;
  logic [15:0] io_csr_hgatp_vmid;
  logic io_tlb_req_0_valid;
  logic [37:0] io_tlb_req_0_bits_vpn;
  logic [1:0] io_tlb_req_0_bits_s2xlate;
  logic io_tlb_req_0_bits_getGpa;
  logic io_tlb_req_1_valid;
  logic [37:0] io_tlb_req_1_bits_vpn;
  logic [1:0] io_tlb_req_1_bits_s2xlate;
  logic io_tlb_req_1_bits_getGpa;
  logic io_ptw_req_0_ready;
  logic g_io_ptw_req_0_valid, x_io_ptw_req_0_valid;
  logic [37:0] g_io_ptw_req_0_bits_vpn, x_io_ptw_req_0_bits_vpn;
  logic [1:0] g_io_ptw_req_0_bits_s2xlate, x_io_ptw_req_0_bits_s2xlate;
  logic io_ptw_resp_valid;
  logic [1:0] io_ptw_resp_bits_s2xlate;
  logic [34:0] io_ptw_resp_bits_s1_entry_tag;
  logic [15:0] io_ptw_resp_bits_s1_entry_asid;
  logic [13:0] io_ptw_resp_bits_s1_entry_vmid;
  logic io_ptw_resp_bits_s1_entry_n;
  logic io_ptw_resp_bits_s1_entry_perm_g;
  logic [1:0] io_ptw_resp_bits_s1_entry_level;
  logic [2:0] io_ptw_resp_bits_s1_addr_low;
  logic [7:0] vidx;
  logic [37:0] io_ptw_resp_bits_s2_entry_tag;
  logic [13:0] io_ptw_resp_bits_s2_entry_vmid;
  logic io_ptw_resp_bits_s2_entry_n;
  logic [1:0] io_ptw_resp_bits_s2_entry_level;
  logic g_io_rob_head_miss_in_tlb, x_io_rob_head_miss_in_tlb;
  logic io_debugTopDown_robHeadVaddr_valid;
  logic [49:0] io_debugTopDown_robHeadVaddr_bits;
  logic io_flush;
  logic g_io_refill, x_io_refill;
  logic g_io_getGpa, x_io_getGpa;

`define PTWFE1_PORTS(P) \
    .clock                                (clk), \
    .reset                                (reset), \
    .io_csr_satp_asid                     (io_csr_satp_asid), \
    .io_csr_vsatp_asid                    (io_csr_vsatp_asid), \
    .io_csr_hgatp_vmid                    (io_csr_hgatp_vmid), \
    .io_tlb_req_0_valid                   (io_tlb_req_0_valid), \
    .io_tlb_req_0_bits_vpn                (io_tlb_req_0_bits_vpn), \
    .io_tlb_req_0_bits_s2xlate            (io_tlb_req_0_bits_s2xlate), \
    .io_tlb_req_0_bits_getGpa             (io_tlb_req_0_bits_getGpa), \
    .io_tlb_req_1_valid                   (io_tlb_req_1_valid), \
    .io_tlb_req_1_bits_vpn                (io_tlb_req_1_bits_vpn), \
    .io_tlb_req_1_bits_s2xlate            (io_tlb_req_1_bits_s2xlate), \
    .io_tlb_req_1_bits_getGpa             (io_tlb_req_1_bits_getGpa), \
    .io_ptw_req_0_ready                   (io_ptw_req_0_ready), \
    .io_ptw_req_0_valid                   (P``_io_ptw_req_0_valid), \
    .io_ptw_req_0_bits_vpn                (P``_io_ptw_req_0_bits_vpn), \
    .io_ptw_req_0_bits_s2xlate            (P``_io_ptw_req_0_bits_s2xlate), \
    .io_ptw_resp_valid                    (io_ptw_resp_valid), \
    .io_ptw_resp_bits_s2xlate             (io_ptw_resp_bits_s2xlate), \
    .io_ptw_resp_bits_s1_entry_tag        (io_ptw_resp_bits_s1_entry_tag), \
    .io_ptw_resp_bits_s1_entry_asid       (io_ptw_resp_bits_s1_entry_asid), \
    .io_ptw_resp_bits_s1_entry_vmid       (io_ptw_resp_bits_s1_entry_vmid), \
    .io_ptw_resp_bits_s1_entry_n          (io_ptw_resp_bits_s1_entry_n), \
    .io_ptw_resp_bits_s1_entry_perm_g     (io_ptw_resp_bits_s1_entry_perm_g), \
    .io_ptw_resp_bits_s1_entry_level      (io_ptw_resp_bits_s1_entry_level), \
    .io_ptw_resp_bits_s1_addr_low         (io_ptw_resp_bits_s1_addr_low), \
    .io_ptw_resp_bits_s1_valididx_0       (vidx[0]), \
    .io_ptw_resp_bits_s1_valididx_1       (vidx[1]), \
    .io_ptw_resp_bits_s1_valididx_2       (vidx[2]), \
    .io_ptw_resp_bits_s1_valididx_3       (vidx[3]), \
    .io_ptw_resp_bits_s1_valididx_4       (vidx[4]), \
    .io_ptw_resp_bits_s1_valididx_5       (vidx[5]), \
    .io_ptw_resp_bits_s1_valididx_6       (vidx[6]), \
    .io_ptw_resp_bits_s1_valididx_7       (vidx[7]), \
    .io_ptw_resp_bits_s2_entry_tag        (io_ptw_resp_bits_s2_entry_tag), \
    .io_ptw_resp_bits_s2_entry_vmid       (io_ptw_resp_bits_s2_entry_vmid), \
    .io_ptw_resp_bits_s2_entry_n          (io_ptw_resp_bits_s2_entry_n), \
    .io_ptw_resp_bits_s2_entry_level      (io_ptw_resp_bits_s2_entry_level), \
    .io_rob_head_miss_in_tlb              (P``_io_rob_head_miss_in_tlb), \
    .io_debugTopDown_robHeadVaddr_valid   (io_debugTopDown_robHeadVaddr_valid), \
    .io_debugTopDown_robHeadVaddr_bits    (io_debugTopDown_robHeadVaddr_bits), \
    .io_flush                             (io_flush), \
    .io_refill                            (P``_io_refill), \
    .io_getGpa                            (P``_io_getGpa)

  PTWFilterEntry_1    g_dut (`PTWFE1_PORTS(g));
  PTWFilterEntry_1_xs x_dut (`PTWFE1_PORTS(x));

  // ---- 激励 ----
  localparam int POOL = 10;
  logic [37:0] pool [POOL];
  typedef struct { logic [37:0] vpn; logic [1:0] s2x; int delay; } job_t;
  job_t jobs[$];

  task automatic set_resp(input logic [37:0] vpn, input logic [1:0] s2x);
    io_ptw_resp_bits_s2xlate          = s2x;
    io_ptw_resp_bits_s1_entry_tag     = vpn[37:3];
    io_ptw_resp_bits_s1_entry_asid    = ($urandom_range(0, 9) == 0) ? 16'($urandom) : 16'h5;
    io_ptw_resp_bits_s1_entry_vmid    = ($urandom_range(0, 9) == 0) ? 14'($urandom) : 14'h3;
    io_ptw_resp_bits_s1_entry_n       = ($urandom_range(0, 9) == 0);
    io_ptw_resp_bits_s1_entry_perm_g  = ($urandom_range(0, 4) == 0);
    io_ptw_resp_bits_s1_entry_level   = ($urandom_range(0, 3) == 0) ? 2'($urandom_range(1, 3)) : 2'd0;
    io_ptw_resp_bits_s1_addr_low      = vpn[2:0];
    vidx = 8'($urandom) | (($urandom_range(0, 7) != 0) ? (8'd1 << vpn[2:0]) : 8'd0);
    io_ptw_resp_bits_s2_entry_tag     = vpn;
    io_ptw_resp_bits_s2_entry_vmid    = ($urandom_range(0, 9) == 0) ? 14'($urandom) : 14'h3;
    io_ptw_resp_bits_s2_entry_n       = ($urandom_range(0, 9) == 0);
    io_ptw_resp_bits_s2_entry_level   = ($urandom_range(0, 3) == 0) ? 2'($urandom_range(1, 3)) : 2'd0;
  endtask

  task automatic drive_inputs();
    io_csr_satp_asid  = 16'h5;
    io_csr_vsatp_asid = 16'h5;
    io_csr_hgatp_vmid = 16'h3;
    io_tlb_req_0_valid = ($urandom_range(0, 9) < 5);
    io_tlb_req_1_valid = ($urandom_range(0, 9) < 5);
    io_tlb_req_0_bits_vpn = pool[$urandom_range(0, POOL - 1)];
    io_tlb_req_1_bits_vpn = ($urandom_range(0, 3) == 0) ? io_tlb_req_0_bits_vpn : pool[$urandom_range(0, POOL - 1)];
    io_tlb_req_0_bits_s2xlate = ($urandom_range(0, 3) == 0) ? 2'($urandom) : 2'd0;
    io_tlb_req_1_bits_s2xlate = ($urandom_range(0, 3) == 0) ? 2'($urandom) : 2'd0;
    io_tlb_req_0_bits_getGpa = ($urandom_range(0, 4) == 0);
    io_tlb_req_1_bits_getGpa = ($urandom_range(0, 4) == 0);
    io_ptw_req_0_ready = ($urandom_range(0, 9) < 6);
    io_flush = ($urandom_range(0, 99) == 0);
    io_debugTopDown_robHeadVaddr_valid = $urandom_range(0, 1);
    io_debugTopDown_robHeadVaddr_bits  = {pool[$urandom_range(0, POOL - 1)], 12'($urandom)};
    io_ptw_resp_valid = 1'b0;
    set_resp(pool[$urandom_range(0, POOL - 1)], 2'($urandom));
    if (jobs.size() > 0 && jobs[0].delay <= 0) begin
      job_t j = jobs.pop_front();
      set_resp(j.vpn, ($urandom_range(0, 19) == 0) ? 2'($urandom) : j.s2x);
      io_ptw_resp_valid = 1'b1;
    end else if ($urandom_range(0, 29) == 0) begin
      io_ptw_resp_valid = 1'b1;
    end
    foreach (jobs[k]) jobs[k].delay--;
  endtask

  task automatic cmp1(input string name, input logic [63:0] g, input logic [63:0] x);
    checks++;
    if (g !== x) begin
      errors++;
      if (errors <= 20) $display("[%0t] MISMATCH %s golden=%h rewrite=%h", $time, name, g, x);
    end
  endtask

  task automatic compare_outputs();
    cmp1("io_ptw_req_0_valid",        g_io_ptw_req_0_valid,        x_io_ptw_req_0_valid);
    cmp1("io_ptw_req_0_bits_vpn",     g_io_ptw_req_0_bits_vpn,     x_io_ptw_req_0_bits_vpn);
    cmp1("io_ptw_req_0_bits_s2xlate", g_io_ptw_req_0_bits_s2xlate, x_io_ptw_req_0_bits_s2xlate);
    cmp1("io_rob_head_miss_in_tlb",   g_io_rob_head_miss_in_tlb,   x_io_rob_head_miss_in_tlb);
    cmp1("io_refill",                 g_io_refill,                 x_io_refill);
    cmp1("io_getGpa",                 g_io_getGpa,                 x_io_getGpa);
  endtask

  // ---- 覆盖事件 ----
  longint n_enq, n_inmatch, n_lane_dup, n_respmatch, n_full, n_issue, n_refill, n_multi, n_gpa, n_robhead, n_flush;
  task automatic collect_cov();
    if (|x_dut.u_core.enqvalid) n_enq++;
    if (io_tlb_req_0_valid && x_dut.u_core.entry_is_match[0]) n_inmatch++;
    if (io_tlb_req_1_valid && io_tlb_req_0_valid && io_tlb_req_1_bits_vpn == io_tlb_req_0_bits_vpn
        && io_tlb_req_1_bits_s2xlate == io_tlb_req_0_bits_s2xlate) n_lane_dup++;
    if (|x_dut.u_core.resp_req_match) n_respmatch++;
    if (~&x_dut.u_core.canenq) n_full++;
    if (g_io_ptw_req_0_valid && io_ptw_req_0_ready) n_issue++;
    if (g_io_refill) n_refill++;
    if (g_io_refill && $countones(x_dut.u_core.resp_entry_match) > 1) n_multi++;
    if (g_io_getGpa) n_gpa++;
    if (g_io_rob_head_miss_in_tlb) n_robhead++;
    if (io_flush && (|x_dut.u_core.v)) n_flush++;
  endtask

  initial begin
    logic [7:0] ever_v;
    bit cmp_on;
    int warm_cnt;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < POOL; i++) pool[i] = {6'($urandom), 32'($urandom)};
    pool[1] = {pool[0][37:9], 9'h0a7};     // 与 pool[0] 同一 2MB 区域
    pool[2] = {pool[0][37:9], 9'h1c2};
    pool[3] = {pool[0][37:3], 3'd6};       // 与 pool[0] 同一 sector
    ever_v = '0; cmp_on = 0; warm_cnt = 0;
    reset = 1;
    drive_inputs();
    repeat (10) @(negedge clk);
    reset = 0;
    for (longint c = 0; c < NCYCLES; c++) begin
      if (c > 1000 && $urandom_range(0, 39999) == 0) begin
        reset = 1;
        repeat (3) begin drive_inputs(); @(negedge clk); end
        reset = 0;
        jobs.delete();
      end
      drive_inputs();
      #1;
      ever_v |= {g_dut.v_7, g_dut.v_6, g_dut.v_5, g_dut.v_4, g_dut.v_3, g_dut.v_2, g_dut.v_1, g_dut.v_0};
      if ((&ever_v) && !cmp_on) begin
        warm_cnt++;
        if (warm_cnt > 4) cmp_on = 1;
      end
      if (cmp_on) begin compare_outputs(); collect_cov(); end
      if (g_io_ptw_req_0_valid && io_ptw_req_0_ready)
        jobs.push_back('{g_io_ptw_req_0_bits_vpn, g_io_ptw_req_0_bits_s2xlate, $urandom_range(1, 6)});
      while (jobs.size() > 8) void'(jobs.pop_front());
      @(negedge clk);
    end
    $display("=== COVERAGE (PTWFilterEntry_1) === checks=%0d enq=%0d in_table=%0d lane_dup=%0d resp_match=%0d full=%0d issue=%0d refill=%0d multi_refill=%0d getGpa=%0d robhead=%0d flush_nonempty=%0d",
             checks, n_enq, n_inmatch, n_lane_dup, n_respmatch, n_full, n_issue, n_refill, n_multi, n_gpa, n_robhead, n_flush);
    if (n_enq == 0 || n_inmatch == 0 || n_lane_dup == 0 || n_respmatch == 0 || n_full == 0 || n_issue == 0 ||
        n_refill == 0 || n_multi == 0 || n_gpa == 0 || n_robhead == 0 || n_flush == 0) begin
      $display("COVERAGE INSUFFICIENT");
      errors++;
    end
    if (errors == 0) $display("TEST PASSED (checks=%0d errors=0)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
