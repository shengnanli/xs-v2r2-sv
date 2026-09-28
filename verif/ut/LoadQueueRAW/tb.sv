// LoadQueueRAW UT —— golden 与重写件双例化，逐拍比全部 38 个输出口
//
// 激励设计（均匀随机几乎打不出 rollback，所以每一路都往"会撞上"的方向偏）：
//   · ROB 指针：所有 robIdx 都取自一个缓慢前移的窗口 base+[0,40)，使 isAfter 比较两边都常见，
//     且窗口会跨过 256 的回绕点（flag 翻转）；
//   · SQ 指针：stAddrReadySqPtr 慢慢前移，stIssuePtr 在它前面 0..4；load 的 sqIdx 取在
//     stAddrReadySqPtr 附近 [-2, +8)，于是"有未就绪的更老 store → 入队"与"出队"都常发生；
//     stIssuePtr==stAddrReadySqPtr（allAddrCheck）约 20% 的拍；
//   · 地址：paddr[27:4] 取自 4 个 cacheline × 4 个 16B 块的小池子，掩码稀疏 → CAM 常命中；
//   · redirect ~4%，level 随机；revoke ~15%；store miss ~10%，wlineflag ~15%。
//
// ★+vcs+initreg+random 下的比对口径★：本模块有不复位寄存器，两侧初值各摇各的。
//   依赖它们的输出只在"该寄存器至少被写过一次"之后才比：
//     · rollback 的 bits（第二级 RegEnable）：以 golden 的 selValidNext_last_REG(_1) 首次为 1
//       为准（它为 1 的那一拍，bits 刚被写过）；
//     · rollback 的 stFtqIdx / stFtqOffset（DelayNWithValid 3 拍）：该 store 流水首次 valid 后 3 拍；
//   rollback.valid / ready / lqFull / perf 从复位结束起每拍都比（它们的来源在复位期间已确定）。
//   +vcs+initreg+0 档两侧初态相同，上述门控不起过滤作用（输出同为 0）。
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
  logic        q_valid [3], q_isRVC [3], q_ftq_flag [3], q_rob_flag [3], q_sq_flag [3];
  logic [5:0]  q_ftq_value [3], q_sq_value [3];
  logic [3:0]  q_ftqOffset [3];
  logic [7:0]  q_rob_value [3];
  logic [63:0] q_runahead [3];
  logic [15:0] q_mask [3];
  logic [47:0] q_paddr [3];
  logic        q_dv [3], q_revoke [3];
  logic        s_valid [2], s_ftq_flag [2], s_rob_flag [2], s_wline [2], s_miss [2];
  logic [5:0]  s_ftq_value [2];
  logic [3:0]  s_ftqOffset [2];
  logic [7:0]  s_rob_value [2];
  logic [47:0] s_paddr [2];
  logic [15:0] s_mask [2];
  logic        ar_flag, is_flag;
  logic [5:0]  ar_value, is_value;

  // ---------------------------------------------------------------------------
  // 输出（g_ = golden，i_ = 重写件）
  // ---------------------------------------------------------------------------
  `define LQRAW_OUT_DECL(P) \
    wire        P``ready [3]; \
    wire        P``rb_valid [2], P``rb_isRVC [2], P``rb_rob_flag [2], P``rb_ftq_flag [2], P``rb_stftq_flag [2]; \
    wire [7:0]  P``rb_rob_value [2]; \
    wire [5:0]  P``rb_ftq_value [2], P``rb_stftq_value [2]; \
    wire [3:0]  P``rb_ftqOffset [2], P``rb_stftqOffset [2]; \
    wire [63:0] P``rb_runahead [2]; \
    wire        P``lqFull; \
    wire [5:0]  P``perf0, P``perf1;
  `LQRAW_OUT_DECL(g_)
  `LQRAW_OUT_DECL(i_)

  `define LQRAW_Q(N) \
    .io_query_``N``_req_valid(q_valid[N]), \
    .io_query_``N``_req_bits_uop_preDecodeInfo_isRVC(q_isRVC[N]), \
    .io_query_``N``_req_bits_uop_ftqPtr_flag(q_ftq_flag[N]), \
    .io_query_``N``_req_bits_uop_ftqPtr_value(q_ftq_value[N]), \
    .io_query_``N``_req_bits_uop_ftqOffset(q_ftqOffset[N]), \
    .io_query_``N``_req_bits_uop_robIdx_flag(q_rob_flag[N]), \
    .io_query_``N``_req_bits_uop_robIdx_value(q_rob_value[N]), \
    .io_query_``N``_req_bits_uop_debugInfo_runahead_checkpoint_id(q_runahead[N]), \
    .io_query_``N``_req_bits_uop_sqIdx_flag(q_sq_flag[N]), \
    .io_query_``N``_req_bits_uop_sqIdx_value(q_sq_value[N]), \
    .io_query_``N``_req_bits_mask(q_mask[N]), \
    .io_query_``N``_req_bits_paddr(q_paddr[N]), \
    .io_query_``N``_req_bits_data_valid(q_dv[N]), \
    .io_query_``N``_revoke(q_revoke[N])
  `define LQRAW_S(N) \
    .io_storeIn_``N``_valid(s_valid[N]), \
    .io_storeIn_``N``_bits_uop_ftqPtr_flag(s_ftq_flag[N]), \
    .io_storeIn_``N``_bits_uop_ftqPtr_value(s_ftq_value[N]), \
    .io_storeIn_``N``_bits_uop_ftqOffset(s_ftqOffset[N]), \
    .io_storeIn_``N``_bits_uop_robIdx_flag(s_rob_flag[N]), \
    .io_storeIn_``N``_bits_uop_robIdx_value(s_rob_value[N]), \
    .io_storeIn_``N``_bits_paddr(s_paddr[N]), \
    .io_storeIn_``N``_bits_mask(s_mask[N]), \
    .io_storeIn_``N``_bits_wlineflag(s_wline[N]), \
    .io_storeIn_``N``_bits_miss(s_miss[N])
  `define LQRAW_RB(P, N) \
    .io_rollback_``N``_valid(P``rb_valid[N]), \
    .io_rollback_``N``_bits_isRVC(P``rb_isRVC[N]), \
    .io_rollback_``N``_bits_robIdx_flag(P``rb_rob_flag[N]), \
    .io_rollback_``N``_bits_robIdx_value(P``rb_rob_value[N]), \
    .io_rollback_``N``_bits_ftqIdx_flag(P``rb_ftq_flag[N]), \
    .io_rollback_``N``_bits_ftqIdx_value(P``rb_ftq_value[N]), \
    .io_rollback_``N``_bits_ftqOffset(P``rb_ftqOffset[N]), \
    .io_rollback_``N``_bits_stFtqIdx_flag(P``rb_stftq_flag[N]), \
    .io_rollback_``N``_bits_stFtqIdx_value(P``rb_stftq_value[N]), \
    .io_rollback_``N``_bits_stFtqOffset(P``rb_stftqOffset[N]), \
    .io_rollback_``N``_bits_debug_runahead_checkpoint_id(P``rb_runahead[N])
  `define LQRAW_PORTS(P) \
    .clock(clk), .reset(rst), \
    .io_redirect_valid(rd_valid), .io_redirect_bits_robIdx_flag(rd_rob_flag), \
    .io_redirect_bits_robIdx_value(rd_rob_value), .io_redirect_bits_level(rd_level), \
    .io_query_0_req_ready(P``ready[0]), .io_query_1_req_ready(P``ready[1]), \
    .io_query_2_req_ready(P``ready[2]), \
    `LQRAW_Q(0), `LQRAW_Q(1), `LQRAW_Q(2), `LQRAW_S(0), `LQRAW_S(1), \
    `LQRAW_RB(P, 0), `LQRAW_RB(P, 1), \
    .io_stAddrReadySqPtr_flag(ar_flag), .io_stAddrReadySqPtr_value(ar_value), \
    .io_stIssuePtr_flag(is_flag), .io_stIssuePtr_value(is_value), \
    .io_lqFull(P``lqFull), .io_perf_0_value(P``perf0), .io_perf_1_value(P``perf1)

  LoadQueueRAW    g_u (`LQRAW_PORTS(g_));
  LoadQueueRAW_xs i_u (`LQRAW_PORTS(i_));

  // ---------------------------------------------------------------------------
  // 激励生成
  // ---------------------------------------------------------------------------
  int rob_base;          // 0..511：{flag, value}
  int sq_ready;          // 0..111：{flag = >=56, value = %56}
  int sq_issue_gap;
  logic [21:0] line_pool [4];

  function automatic void rob_of(input int x, output logic f, output logic [7:0] v);
    int y; y = x % 512; f = (y >= 256); v = 8'(y % 256);
  endfunction
  function automatic void sq_of(input int x, output logic f, output logic [5:0] v);
    int y; y = ((x % 112) + 112) % 112; f = (y >= 56); v = 6'(y % 56);
  endfunction
  function automatic logic [47:0] rnd_paddr();
    return {20'($urandom), line_pool[$urandom_range(0, 3)], 2'($urandom_range(0, 3)), 4'($urandom)};
  endfunction
  function automatic logic [15:0] rnd_mask();
    logic [15:0] m;
    if ($urandom_range(0, 9) == 0) return 16'hFFFF;
    m = '0;
    repeat ($urandom_range(1, 4)) m[$urandom_range(0, 15)] = 1'b1;
    return m;
  endfunction

  always @(negedge clk) begin
    if (rst) begin
      cyc <= 0;
      rd_valid <= 0; rd_rob_flag <= 0; rd_rob_value <= 0; rd_level <= 0;
      for (int w = 0; w < 3; w++) begin
        q_valid[w] <= 0; q_isRVC[w] <= 0; q_ftq_flag[w] <= 0; q_ftq_value[w] <= 0;
        q_ftqOffset[w] <= 0; q_rob_flag[w] <= 0; q_rob_value[w] <= 0; q_runahead[w] <= 0;
        q_sq_flag[w] <= 0; q_sq_value[w] <= 0; q_mask[w] <= 0; q_paddr[w] <= 0;
        q_dv[w] <= 0; q_revoke[w] <= 0;
      end
      for (int s = 0; s < 2; s++) begin
        s_valid[s] <= 0; s_ftq_flag[s] <= 0; s_ftq_value[s] <= 0; s_ftqOffset[s] <= 0;
        s_rob_flag[s] <= 0; s_rob_value[s] <= 0; s_paddr[s] <= 0; s_mask[s] <= 0;
        s_wline[s] <= 0; s_miss[s] <= 0;
      end
      ar_flag <= 0; ar_value <= 0; is_flag <= 0; is_value <= 0;
    end else begin
      logic f; logic [7:0] v8; logic [5:0] v6;
      cyc <= cyc + 1;
      // 指针漂移
      if ($urandom_range(0, 3) == 0) rob_base = (rob_base + $urandom_range(0, 3)) % 512;
      if ($urandom_range(0, 5) == 0) sq_ready = (sq_ready + $urandom_range(0, 2)) % 112;
      if ($urandom_range(0, 3) == 0) sq_issue_gap = ($urandom_range(0, 4) == 0) ? 0 : $urandom_range(1, 4);
      sq_of(sq_ready, f, v6);                ar_flag <= f; ar_value <= v6;
      sq_of(sq_ready + sq_issue_gap, f, v6); is_flag <= f; is_value <= v6;
      if ($urandom_range(0, 999) == 0) line_pool[$urandom_range(0, 3)] = 22'($urandom);

      // redirect
      rd_valid <= ($urandom_range(0, 99) < 4);
      rob_of(rob_base + $urandom_range(0, 39), f, v8);
      rd_rob_flag <= f; rd_rob_value <= v8; rd_level <= $urandom_range(0, 1);

      // load 查询
      for (int w = 0; w < 3; w++) begin
        q_valid[w]     <= ($urandom_range(0, 1) == 1);
        q_isRVC[w]     <= $urandom_range(0, 1);
        q_ftq_flag[w]  <= $urandom_range(0, 1);
        q_ftq_value[w] <= 6'($urandom);
        q_ftqOffset[w] <= 4'($urandom);
        rob_of(rob_base + $urandom_range(0, 39), f, v8);
        q_rob_flag[w]  <= f; q_rob_value[w] <= v8;
        q_runahead[w]  <= {$urandom, $urandom};
        sq_of(sq_ready + $urandom_range(0, 9) - 2, f, v6);
        q_sq_flag[w]   <= f; q_sq_value[w] <= v6;
        q_mask[w]      <= rnd_mask();
        q_paddr[w]     <= rnd_paddr();
        q_dv[w]        <= ($urandom_range(0, 9) != 0);
        q_revoke[w]    <= ($urandom_range(0, 99) < 15);
      end

      // store
      for (int s = 0; s < 2; s++) begin
        s_valid[s]     <= ($urandom_range(0, 9) < 4);
        s_ftq_flag[s]  <= $urandom_range(0, 1);
        s_ftq_value[s] <= 6'($urandom);
        s_ftqOffset[s] <= 4'($urandom);
        rob_of(rob_base + $urandom_range(0, 39), f, v8);
        s_rob_flag[s]  <= f; s_rob_value[s] <= v8;
        s_paddr[s]     <= rnd_paddr();
        s_mask[s]      <= rnd_mask();
        s_wline[s]     <= ($urandom_range(0, 99) < 15);
        s_miss[s]      <= ($urandom_range(0, 9) == 0);
      end
    end
  end

  // ---------------------------------------------------------------------------
  // "写过一次"门控（只对 +random 档有过滤作用，见文件头）
  // ---------------------------------------------------------------------------
  logic rbBitsLoaded [2];
  int   stSeen [2];      // 该 store 流水首次 valid 以来的拍数（饱和）
  always @(posedge clk) begin
    if (rst) begin
      rbBitsLoaded[0] <= 0; rbBitsLoaded[1] <= 0; stSeen[0] <= 0; stSeen[1] <= 0;
    end else begin
      if (g_u.detectedRollback_lqSelect_selValidNext_last_REG)   rbBitsLoaded[0] <= 1;
      if (g_u.detectedRollback_lqSelect_selValidNext_last_REG_1) rbBitsLoaded[1] <= 1;
      for (int s = 0; s < 2; s++)
        if (stSeen[s] > 0 || s_valid[s]) stSeen[s] <= (stSeen[s] < 10) ? stSeen[s] + 1 : stSeen[s];
    end
  end

  // ---------------------------------------------------------------------------
  // 比对与覆盖
  // ---------------------------------------------------------------------------
  `define CHK(nm, g, i) \
    if ((g) !== (i)) begin errors++; \
      if (errors <= 60) $display("[cyc %0d] %s g=%h i=%h", cyc, nm, g, i); end

  int cov_rollback [2], cov_enq, cov_full, cov_notready;
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    for (int w = 0; w < 3; w++) begin
      `CHK($sformatf("io_query_%0d_req_ready", w), g_ready[w], i_ready[w])
      if (g_ready[w] && q_valid[w]) cov_enq++;
      if (!g_ready[w]) cov_notready++;
    end
    `CHK("io_lqFull", g_lqFull, i_lqFull)
    `CHK("io_perf_0_value", g_perf0, i_perf0)
    `CHK("io_perf_1_value", g_perf1, i_perf1)
    if (g_lqFull) cov_full++;
    for (int s = 0; s < 2; s++) begin
      `CHK($sformatf("io_rollback_%0d_valid", s), g_rb_valid[s], i_rb_valid[s])
      if (g_rb_valid[s]) cov_rollback[s]++;
      if (rbBitsLoaded[s]) begin
        `CHK($sformatf("io_rollback_%0d_bits_isRVC", s), g_rb_isRVC[s], i_rb_isRVC[s])
        `CHK($sformatf("io_rollback_%0d_bits_robIdx", s), {g_rb_rob_flag[s], g_rb_rob_value[s]},
             {i_rb_rob_flag[s], i_rb_rob_value[s]})
        `CHK($sformatf("io_rollback_%0d_bits_ftqIdx", s), {g_rb_ftq_flag[s], g_rb_ftq_value[s]},
             {i_rb_ftq_flag[s], i_rb_ftq_value[s]})
        `CHK($sformatf("io_rollback_%0d_bits_ftqOffset", s), g_rb_ftqOffset[s], i_rb_ftqOffset[s])
        `CHK($sformatf("io_rollback_%0d_bits_runahead", s), g_rb_runahead[s], i_rb_runahead[s])
      end
      if (stSeen[s] >= 4) begin
        `CHK($sformatf("io_rollback_%0d_bits_stFtqIdx", s), {g_rb_stftq_flag[s], g_rb_stftq_value[s]},
             {i_rb_stftq_flag[s], i_rb_stftq_value[s]})
        `CHK($sformatf("io_rollback_%0d_bits_stFtqOffset", s), g_rb_stftqOffset[s], i_rb_stftqOffset[s])
      end
    end
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rob_base = 200; sq_ready = 50; sq_issue_gap = 2;   // 起点靠近回绕，尽早覆盖 flag 翻转
    for (int i = 0; i < 4; i++) line_pool[i] = 22'($urandom);
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("COV rollback0=%0d rollback1=%0d enq_fire=%0d not_ready=%0d lqFull=%0d",
             cov_rollback[0], cov_rollback[1], cov_enq, cov_notready, cov_full);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_rollback[0] > 100 && cov_rollback[1] > 100)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
