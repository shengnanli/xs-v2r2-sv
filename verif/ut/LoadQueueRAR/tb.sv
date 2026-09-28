// LoadQueueRAR UT —— golden 与重写件双例化，逐拍比全部 10 个输出口（3×ready / 3×resp.valid /
// 3×resp.rep_frm_fetch / lqFull / 2×perf，共 15 个信号）
//
// 激励设计（均匀随机几乎打不出 RAR 违例，所以每一路都往"会撞上"的方向偏）：
//   · ROB 指针：所有 robIdx 取自缓慢前移的窗口 base+[0,40)，使 isAfter 两边都常见，
//     且窗口会跨过 256 的回绕点（flag 翻转）；
//   · LQ 指针：ldWbPtr 大部分时间慢走、偶尔停一阵再跳一大步（让队列能攒满 → lqFull /
//     ready=0 都能打到）；load 的 lqIdx 取在 ldWbPtr 附近 [-3, +24)，入队与出队都常发生；
//   · 地址：paddr[47:6] 取自 4 条 cacheline 的小池子（池子慢漂），低 6 位随机
//     → 折叠键常撞、release 常命中在队的槽；5% 的地址完全随机；
//   · release ~12%（地址同样取自池子），is_nc ~10%，data_valid ~80%；
//   · redirect ~3%（level 随机），revoke ~15%。
//
// ★+vcs+initreg+random 下的比对口径★：ldLdViolationMask 是 RegEnable(query.req.valid)、不复位，
//   第 w 条流水第一次 req.valid 之前它是随机初值，rep_frm_fetch_w 两侧会不同 —— 那是不复位状态
//   本身没有定义。所以 rep_frm_fetch_w 从"第 w 条流水首次 req.valid 的下一拍"起才比。
//   其余输出（ready / resp.valid / lqFull / perf）的来源在复位期间已确定，从复位结束起每拍都比。
//   +vcs+initreg+0 档两侧初态相同，门控不起过滤作用。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int cyc;
  always #5 clk = ~clk;

  // ---------------------------------------------------------------------------
  // 激励信号
  // ---------------------------------------------------------------------------
  logic        rd_valid, rd_rob_flag, rd_level;
  logic [7:0]  rd_rob_value;
  logic        q_valid [3], q_rob_flag [3], q_lq_flag [3], q_dv [3], q_nc [3], q_revoke [3];
  logic [7:0]  q_rob_value [3];
  logic [6:0]  q_lq_value [3];
  logic [47:0] q_paddr [3];
  logic        rel_valid;
  logic [47:0] rel_paddr;
  logic        wb_flag;
  logic [6:0]  wb_value;

  // ---------------------------------------------------------------------------
  // 输出（g_ = golden，i_ = 重写件）
  // ---------------------------------------------------------------------------
  `define LQRAR_OUT_DECL(P) \
    wire       P``ready [3], P``resp_valid [3], P``rep [3]; \
    wire       P``lqFull; \
    wire [5:0] P``perf0, P``perf1;
  `LQRAR_OUT_DECL(g_)
  `LQRAR_OUT_DECL(i_)

  `define LQRAR_Q(P, N) \
    .io_query_``N``_req_ready(P``ready[N]), \
    .io_query_``N``_req_valid(q_valid[N]), \
    .io_query_``N``_req_bits_uop_robIdx_flag(q_rob_flag[N]), \
    .io_query_``N``_req_bits_uop_robIdx_value(q_rob_value[N]), \
    .io_query_``N``_req_bits_uop_lqIdx_flag(q_lq_flag[N]), \
    .io_query_``N``_req_bits_uop_lqIdx_value(q_lq_value[N]), \
    .io_query_``N``_req_bits_paddr(q_paddr[N]), \
    .io_query_``N``_req_bits_data_valid(q_dv[N]), \
    .io_query_``N``_req_bits_is_nc(q_nc[N]), \
    .io_query_``N``_resp_valid(P``resp_valid[N]), \
    .io_query_``N``_resp_bits_rep_frm_fetch(P``rep[N]), \
    .io_query_``N``_revoke(q_revoke[N])
  `define LQRAR_PORTS(P) \
    .clock(clk), .reset(rst), \
    .io_redirect_valid(rd_valid), .io_redirect_bits_robIdx_flag(rd_rob_flag), \
    .io_redirect_bits_robIdx_value(rd_rob_value), .io_redirect_bits_level(rd_level), \
    `LQRAR_Q(P, 0), `LQRAR_Q(P, 1), `LQRAR_Q(P, 2), \
    .io_release_valid(rel_valid), .io_release_bits_paddr(rel_paddr), \
    .io_ldWbPtr_flag(wb_flag), .io_ldWbPtr_value(wb_value), \
    .io_lqFull(P``lqFull), .io_perf_0_value(P``perf0), .io_perf_1_value(P``perf1)

  LoadQueueRAR    g_u (`LQRAR_PORTS(g_));
  LoadQueueRAR_xs i_u (`LQRAR_PORTS(i_));

  // ---------------------------------------------------------------------------
  // 激励生成
  // ---------------------------------------------------------------------------
  int rob_base;          // 0..511：{flag, value}
  int lq_wb;             // 0..143：{flag = >=72, value = %72}
  int wb_stall;          // >0：ldWbPtr 停住的剩余拍数
  logic [41:0] line_pool [4];

  function automatic void rob_of(input int x, output logic f, output logic [7:0] v);
    int y; y = x % 512; f = (y >= 256); v = 8'(y % 256);
  endfunction
  function automatic void lq_of(input int x, output logic f, output logic [6:0] v);
    int y; y = ((x % 144) + 144) % 144; f = (y >= 72); v = 7'(y % 72);
  endfunction
  function automatic logic [47:0] rnd_paddr();
    if ($urandom_range(0, 19) == 0) return {$urandom, 16'($urandom)};
    return {line_pool[$urandom_range(0, 3)], 6'($urandom)};
  endfunction

  always @(negedge clk) begin
    if (rst) begin
      cyc <= 0;
      rd_valid <= 0; rd_rob_flag <= 0; rd_rob_value <= 0; rd_level <= 0;
      for (int w = 0; w < 3; w++) begin
        q_valid[w] <= 0; q_rob_flag[w] <= 0; q_rob_value[w] <= 0; q_lq_flag[w] <= 0;
        q_lq_value[w] <= 0; q_paddr[w] <= 0; q_dv[w] <= 0; q_nc[w] <= 0; q_revoke[w] <= 0;
      end
      rel_valid <= 0; rel_paddr <= 0; wb_flag <= 0; wb_value <= 0;
    end else begin
      logic f; logic [7:0] v8; logic [6:0] v7;
      cyc <= cyc + 1;
      // 指针漂移
      if ($urandom_range(0, 3) == 0) rob_base = (rob_base + $urandom_range(0, 3)) % 512;
      if (wb_stall > 0) wb_stall = wb_stall - 1;
      else if ($urandom_range(0, 199) == 0) wb_stall = $urandom_range(20, 120);
      else if ($urandom_range(0, 99) == 0) lq_wb = (lq_wb + $urandom_range(10, 30)) % 144;
      else if ($urandom_range(0, 2) == 0) lq_wb = (lq_wb + 1) % 144;
      lq_of(lq_wb, f, v7); wb_flag <= f; wb_value <= v7;
      if ($urandom_range(0, 499) == 0) line_pool[$urandom_range(0, 3)] = 42'({$urandom, $urandom});

      // redirect
      rd_valid <= ($urandom_range(0, 99) < 3);
      rob_of(rob_base + $urandom_range(0, 39), f, v8);
      rd_rob_flag <= f; rd_rob_value <= v8; rd_level <= $urandom_range(0, 1);

      // load 查询
      for (int w = 0; w < 3; w++) begin
        q_valid[w]     <= ($urandom_range(0, 9) < 6);
        rob_of(rob_base + $urandom_range(0, 39), f, v8);
        q_rob_flag[w]  <= f; q_rob_value[w] <= v8;
        lq_of(lq_wb + $urandom_range(0, 26) - 3, f, v7);
        q_lq_flag[w]   <= f; q_lq_value[w] <= v7;
        q_paddr[w]     <= rnd_paddr();
        q_dv[w]        <= ($urandom_range(0, 9) < 8);
        q_nc[w]        <= ($urandom_range(0, 9) == 0);
        q_revoke[w]    <= ($urandom_range(0, 99) < 15);
      end

      // release
      rel_valid <= ($urandom_range(0, 99) < 12);
      rel_paddr <= rnd_paddr();
    end
  end

  // ---------------------------------------------------------------------------
  // "写过一次"门控（只对 +random 档有过滤作用，见文件头）
  // ---------------------------------------------------------------------------
  logic maskLoaded [3];
  always @(posedge clk) begin
    if (rst) for (int w = 0; w < 3; w++) maskLoaded[w] <= 0;
    else     for (int w = 0; w < 3; w++) if (q_valid[w]) maskLoaded[w] <= 1;
  end

  // ---------------------------------------------------------------------------
  // 比对与覆盖
  // ---------------------------------------------------------------------------
  `define CHK(nm, g, i) \
    if ((g) !== (i)) begin errors++; \
      if (errors <= 60) $display("[cyc %0d] %s g=%h i=%h", cyc, nm, g, i); end

  int cov_vio [3], cov_enq, cov_full, cov_notready, cov_relhit, cov_revoke;
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    for (int w = 0; w < 3; w++) begin
      `CHK($sformatf("io_query_%0d_req_ready", w), g_ready[w], i_ready[w])
      `CHK($sformatf("io_query_%0d_resp_valid", w), g_resp_valid[w], i_resp_valid[w])
      if (maskLoaded[w]) begin
        `CHK($sformatf("io_query_%0d_resp_bits_rep_frm_fetch", w), g_rep[w], i_rep[w])
      end
      if (g_ready[w] && q_valid[w]) cov_enq++;
      if (!g_ready[w]) cov_notready++;
      if (g_resp_valid[w] && g_rep[w]) cov_vio[w]++;
    end
    `CHK("io_lqFull", g_lqFull, i_lqFull)
    `CHK("io_perf_0_value", g_perf0, i_perf0)
    `CHK("io_perf_1_value", g_perf1, i_perf1)
    if (g_lqFull) cov_full++;
    // 白盒覆盖探针（只读 golden 内部，不参与比对）
    if (g_u.REG_5 | g_u.REG_40 | g_u.REG_71) cov_relhit++;
    if (q_revoke[0] && g_u.lastCanAccept_next_nextVec_0_r) cov_revoke++;
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rob_base = 200; lq_wb = 60; wb_stall = 0;   // 起点靠近回绕，尽早覆盖 flag 翻转
    for (int i = 0; i < 4; i++) line_pool[i] = 42'({$urandom, $urandom});
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("COV violation=%0d/%0d/%0d enq_fire=%0d not_ready=%0d lqFull=%0d release_hit(3 probes)=%0d revoke0=%0d",
             cov_vio[0], cov_vio[1], cov_vio[2], cov_enq, cov_notready, cov_full, cov_relhit, cov_revoke);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_vio[0] > 100 && cov_vio[1] > 100 && cov_vio[2] > 100
        && cov_full > 100 && cov_relhit > 100)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
