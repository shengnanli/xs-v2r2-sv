// =============================================================================
// AgeDetector 家族 UT（发射队列版，9 个变体）：每个变体一对 DUT —— golden <M> 对
// 重写 <M>_xs，共享时钟/复位，各自独立随机激励，逐拍比对**全部** io_out 端口。
//
// ★ 激励为什么不能是「每个输入位独立均匀随机」★
// 本模块的判别力集中在三处，均匀随机都碰不到：
//   1. **两个入队口同拍进队**（矩阵次态的第 (1) 条规则）—— 决定"口号小的算更老"。
//      两口各自 one-hot、位宽最大 16，独立均匀随机时两口同拍都非零的概率极低。
//      这里直接按事件造：45% 的拍两口都进队。
//   2. **两口撞同一条目**（i0 == i1）—— isEnq(i) 为真但 beatenByEarlierPort 也为真。
//   3. **canIssue 只点亮两位**（成对探测）—— 这时 io_out 直接把 get_age(i,j) 这一位
//      读出来，N*(N-1)/2 个上三角元素因此能被逐个观测，而不是淹没在 N 选 1 的结果里。
//      游标 pairI/pairJ 逐拍推进，保证扫遍所有对（tb 尾部核对 pairs = N*(N-1)/2）。
// 另有 4% 的拍喂**非 one-hot** 的 enq：golden 的 PopCount 断言在 `ifndef SYNTHESIS
// 里，两侧都带 +define+SYNTHESIS 编译 ⇒ 断言不在场，非法编码上两边也必须逐位一致
// （CONVENTIONS：输入端口在 FM 里是自由变量，UT 这边也别把它当约束）。
//
// ★ 覆盖证据 ★
// 每个变体各自统计若干「没有它这一轮就等于没验」的事件，任何一项为 0、或成对探测
// 没扫满，tb 判 TEST FAILED —— 不让 errors=0 在空激励上成立。
//
// 自动生成：verif/ut/AgeDetector/gen.py —— 勿手改
// =============================================================================
`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// agedet_env —— 一个变体的激励 + 比对 + 覆盖统计（按条目数/发射口数参数化）
// -----------------------------------------------------------------------------
module agedet_env #(
  parameter string NAME = "?",
  parameter int    N    = 2,   // 条目数
  parameter int    NDEQ = 1    // 发射口数
) (
  input  logic         clk,
  input  logic         rst,
  output logic [N-1:0] enq0,
  output logic [N-1:0] enq1,
  output logic [N-1:0] canIssue [NDEQ],
  input  logic [N-1:0] g_out    [NDEQ],
  input  logic [N-1:0] i_out    [NDEQ]
);

  int     errors = 0;
  longint checks = 0;

  // 覆盖计数（每个都是"没有它这一轮就等于没验"的事件）
  longint cov_enq_both  = 0;   // 两口同拍进不同条目（端口优先级判别点）
  longint cov_enq_same  = 0;   // 两口同拍撞同一条目
  longint cov_enq_nonoh = 0;   // 某口喂了非 one-hot（非法编码）
  longint cov_enq_none  = 0;   // 本拍无人进队（矩阵保持，时钟使能关着）
  longint cov_out_hit   = 0;   // io_out 非 0（真的选出了一个）
  longint cov_ci_full   = 0;   // canIssue 全 1
  longint cov_ci_zero   = 0;   // canIssue 全 0（out 必须全 0）
  longint cov_multi_ci  = 0;   // canIssue 至少两个候选（选择逻辑真的在挑）
  bit     pair_seen [N][N];    // 成对探测覆盖到的 (i,j)

  int pairI = 0, pairJ = 1;    // 成对探测游标

  function automatic logic [N-1:0] one_hot(input int idx);
    logic [N-1:0] v;
    v = '0;
    v[idx] = 1'b1;
    return v;
  endfunction

  task automatic gen_stim();
    int r, i0, i1;
    enq0 = '0;
    enq1 = '0;
    r = $urandom_range(0, 99);
    if (r < 45) begin              // 两口同拍都进队（i0==i1 时即"撞同一条目"）
      i0 = $urandom_range(0, N-1);
      i1 = $urandom_range(0, N-1);
      enq0 = one_hot(i0);
      enq1 = one_hot(i1);
    end
    else if (r < 70) enq0 = one_hot($urandom_range(0, N-1));   // 只有 0 口
    else if (r < 90) enq1 = one_hot($urandom_range(0, N-1));   // 只有 1 口
    else if (r < 94) begin                                     // 非 one-hot
      enq0 = N'($urandom);
      enq1 = N'($urandom);
    end
    // 其余 6%: 本拍无人进队 —— 时钟使能全关，矩阵必须原样不动

    for (int d = 0; d < NDEQ; d++) begin
      r = $urandom_range(0, 99);
      if (r < 40) begin            // 成对探测：out 直接暴露 get_age(pairI,pairJ)
        canIssue[d] = '0;
        canIssue[d][pairI] = 1'b1;
        canIssue[d][pairJ] = 1'b1;
      end
      else if (r < 60) canIssue[d] = '1;
      else if (r < 90) canIssue[d] = N'($urandom);
      else             canIssue[d] = one_hot($urandom_range(0, N-1));
    end

    // 游标每拍推进一格，逐对扫过整个上三角
    pairJ = pairJ + 1;
    if (pairJ >= N) begin
      pairI = pairI + 1;
      pairJ = pairI + 1;
      if (pairJ >= N) begin
        pairI = 0;
        pairJ = 1;
      end
    end
  endtask

  always @(negedge clk) begin
    if (rst) begin
      enq0 = '0;
      enq1 = '0;
      for (int d = 0; d < NDEQ; d++) canIssue[d] = '0;
      pairI = 0;
      pairJ = 1;
    end
    else gen_stim();
  end

  // 覆盖采样（用本拍已生效的激励）
  always @(posedge clk) if (!rst) begin
    int a, b;
    if ((|enq0) && (|enq1)) begin
      if (enq0 == enq1) cov_enq_same++;
      else              cov_enq_both++;
    end
    if (!(|enq0) && !(|enq1)) cov_enq_none++;
    if ($countones(enq0) > 1 || $countones(enq1) > 1) cov_enq_nonoh++;
    for (int d = 0; d < NDEQ; d++) begin
      if (|g_out[d])                    cov_out_hit++;
      if (&canIssue[d])                 cov_ci_full++;
      if (!(|canIssue[d]))              cov_ci_zero++;
      if ($countones(canIssue[d]) >= 2) cov_multi_ci++;
    end
    if ($countones(canIssue[0]) == 2) begin
      a = -1;
      b = -1;
      for (int k = 0; k < N; k++) if (canIssue[0][k]) begin
        if (a < 0) a = k;
        else       b = k;
      end
      if (b >= 0) pair_seen[a][b] = 1'b1;
    end
  end

  // 比对：负沿施加激励后 4ns（下一个正沿之前）比全部 io_out
  always @(negedge clk) if (!rst) begin
    #4;
    for (int d = 0; d < NDEQ; d++) begin
      checks++;
      if (!$isunknown(g_out[d]) && g_out[d] !== i_out[d]) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] %s io_out_%0d g=%h i=%h (enq=%h/%h canIssue=%h)",
                   $time, NAME, d, g_out[d], i_out[d], enq0, enq1, canIssue[d]);
      end
    end
  end

  function automatic int pairs_seen();
    int n;
    n = 0;
    for (int a = 0; a < N; a++)
      for (int b = a + 1; b < N; b++) if (pair_seen[a][b]) n++;
    return n;
  endfunction

  // 返回 0 = 本变体合格；非 0 = 有错或覆盖不足（覆盖不足时 errors=0 不作数）
  function automatic int report();
    int want, got, bad;
    want = N * (N - 1) / 2;
    got  = pairs_seen();
    bad  = 0;
    if (errors != 0) bad = 1;
    if (checks < 100000) bad = 1;
    if (cov_enq_both == 0 || cov_enq_same == 0 || cov_enq_nonoh == 0 ||
        cov_enq_none == 0 || cov_out_hit == 0 || cov_ci_full == 0 ||
        cov_ci_zero == 0 || cov_multi_ci == 0) bad = 1;
    if (got != want) bad = 1;
    $display("COV %-16s checks=%0d errors=%0d enq_both=%0d enq_same=%0d enq_nonoh=%0d enq_none=%0d out_hit=%0d ci_full=%0d ci_zero=%0d multi_ci=%0d pairs=%0d/%0d %s",
             NAME, checks, errors, cov_enq_both, cov_enq_same, cov_enq_nonoh,
             cov_enq_none, cov_out_hit, cov_ci_full, cov_ci_zero, cov_multi_ci,
             got, want, (bad ? "BAD" : "ok"));
    return bad;
  endfunction

endmodule

// -----------------------------------------------------------------------------
// tb —— 9 个变体各一对 DUT + 一个 env
// -----------------------------------------------------------------------------
module tb;
  int unsigned NCYCLES = 200000;
  bit   clk = 0;
  logic rst;

  always #5 clk = ~clk;

  // --- AgeDetector: 6 条目 / 2 入队口 / 4 发射口 ---
  logic [5:0] AgeDetector_enq0, AgeDetector_enq1;
  logic [5:0] AgeDetector_ci [4];
  logic [5:0] AgeDetector_g_out [4];
  logic [5:0] AgeDetector_i_out [4];
  AgeDetector g_AgeDetector (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_enq0), .io_enq_1(AgeDetector_enq1), .io_canIssue_0(AgeDetector_ci[0]), .io_canIssue_1(AgeDetector_ci[1]), .io_canIssue_2(AgeDetector_ci[2]), .io_canIssue_3(AgeDetector_ci[3]), .io_out_0(AgeDetector_g_out[0]), .io_out_1(AgeDetector_g_out[1]), .io_out_2(AgeDetector_g_out[2]), .io_out_3(AgeDetector_g_out[3]));
  AgeDetector_xs i_AgeDetector (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_enq0), .io_enq_1(AgeDetector_enq1), .io_canIssue_0(AgeDetector_ci[0]), .io_canIssue_1(AgeDetector_ci[1]), .io_canIssue_2(AgeDetector_ci[2]), .io_canIssue_3(AgeDetector_ci[3]), .io_out_0(AgeDetector_i_out[0]), .io_out_1(AgeDetector_i_out[1]), .io_out_2(AgeDetector_i_out[2]), .io_out_3(AgeDetector_i_out[3]));
  agedet_env #(.NAME("AgeDetector"), .N(6), .NDEQ(4)) e_AgeDetector (
    .clk(clk), .rst(rst), .enq0(AgeDetector_enq0), .enq1(AgeDetector_enq1),
    .canIssue(AgeDetector_ci), .g_out(AgeDetector_g_out), .i_out(AgeDetector_i_out));

  // --- AgeDetector_1: 16 条目 / 2 入队口 / 2 发射口 ---
  logic [15:0] AgeDetector_1_enq0, AgeDetector_1_enq1;
  logic [15:0] AgeDetector_1_ci [2];
  logic [15:0] AgeDetector_1_g_out [2];
  logic [15:0] AgeDetector_1_i_out [2];
  AgeDetector_1 g_AgeDetector_1 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_1_enq0), .io_enq_1(AgeDetector_1_enq1), .io_canIssue_0(AgeDetector_1_ci[0]), .io_canIssue_1(AgeDetector_1_ci[1]), .io_out_0(AgeDetector_1_g_out[0]), .io_out_1(AgeDetector_1_g_out[1]));
  AgeDetector_1_xs i_AgeDetector_1 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_1_enq0), .io_enq_1(AgeDetector_1_enq1), .io_canIssue_0(AgeDetector_1_ci[0]), .io_canIssue_1(AgeDetector_1_ci[1]), .io_out_0(AgeDetector_1_i_out[0]), .io_out_1(AgeDetector_1_i_out[1]));
  agedet_env #(.NAME("AgeDetector_1"), .N(16), .NDEQ(2)) e_AgeDetector_1 (
    .clk(clk), .rst(rst), .enq0(AgeDetector_1_enq0), .enq1(AgeDetector_1_enq1),
    .canIssue(AgeDetector_1_ci), .g_out(AgeDetector_1_g_out), .i_out(AgeDetector_1_i_out));

  // --- AgeDetector_8: 2 条目 / 2 入队口 / 4 发射口 ---
  logic [1:0] AgeDetector_8_enq0, AgeDetector_8_enq1;
  logic [1:0] AgeDetector_8_ci [4];
  logic [1:0] AgeDetector_8_g_out [4];
  logic [1:0] AgeDetector_8_i_out [4];
  AgeDetector_8 g_AgeDetector_8 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_8_enq0), .io_enq_1(AgeDetector_8_enq1), .io_canIssue_0(AgeDetector_8_ci[0]), .io_canIssue_1(AgeDetector_8_ci[1]), .io_canIssue_2(AgeDetector_8_ci[2]), .io_canIssue_3(AgeDetector_8_ci[3]), .io_out_0(AgeDetector_8_g_out[0]), .io_out_1(AgeDetector_8_g_out[1]), .io_out_2(AgeDetector_8_g_out[2]), .io_out_3(AgeDetector_8_g_out[3]));
  AgeDetector_8_xs i_AgeDetector_8 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_8_enq0), .io_enq_1(AgeDetector_8_enq1), .io_canIssue_0(AgeDetector_8_ci[0]), .io_canIssue_1(AgeDetector_8_ci[1]), .io_canIssue_2(AgeDetector_8_ci[2]), .io_canIssue_3(AgeDetector_8_ci[3]), .io_out_0(AgeDetector_8_i_out[0]), .io_out_1(AgeDetector_8_i_out[1]), .io_out_2(AgeDetector_8_i_out[2]), .io_out_3(AgeDetector_8_i_out[3]));
  agedet_env #(.NAME("AgeDetector_8"), .N(2), .NDEQ(4)) e_AgeDetector_8 (
    .clk(clk), .rst(rst), .enq0(AgeDetector_8_enq0), .enq1(AgeDetector_8_enq1),
    .canIssue(AgeDetector_8_ci), .g_out(AgeDetector_8_g_out), .i_out(AgeDetector_8_i_out));

  // --- AgeDetector_9: 14 条目 / 2 入队口 / 2 发射口 ---
  logic [13:0] AgeDetector_9_enq0, AgeDetector_9_enq1;
  logic [13:0] AgeDetector_9_ci [2];
  logic [13:0] AgeDetector_9_g_out [2];
  logic [13:0] AgeDetector_9_i_out [2];
  AgeDetector_9 g_AgeDetector_9 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_9_enq0), .io_enq_1(AgeDetector_9_enq1), .io_canIssue_0(AgeDetector_9_ci[0]), .io_canIssue_1(AgeDetector_9_ci[1]), .io_out_0(AgeDetector_9_g_out[0]), .io_out_1(AgeDetector_9_g_out[1]));
  AgeDetector_9_xs i_AgeDetector_9 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_9_enq0), .io_enq_1(AgeDetector_9_enq1), .io_canIssue_0(AgeDetector_9_ci[0]), .io_canIssue_1(AgeDetector_9_ci[1]), .io_out_0(AgeDetector_9_i_out[0]), .io_out_1(AgeDetector_9_i_out[1]));
  agedet_env #(.NAME("AgeDetector_9"), .N(14), .NDEQ(2)) e_AgeDetector_9 (
    .clk(clk), .rst(rst), .enq0(AgeDetector_9_enq0), .enq1(AgeDetector_9_enq1),
    .canIssue(AgeDetector_9_ci), .g_out(AgeDetector_9_g_out), .i_out(AgeDetector_9_i_out));

  // --- AgeDetector_12: 2 条目 / 2 入队口 / 3 发射口 ---
  logic [1:0] AgeDetector_12_enq0, AgeDetector_12_enq1;
  logic [1:0] AgeDetector_12_ci [3];
  logic [1:0] AgeDetector_12_g_out [3];
  logic [1:0] AgeDetector_12_i_out [3];
  AgeDetector_12 g_AgeDetector_12 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_12_enq0), .io_enq_1(AgeDetector_12_enq1), .io_canIssue_0(AgeDetector_12_ci[0]), .io_canIssue_1(AgeDetector_12_ci[1]), .io_canIssue_2(AgeDetector_12_ci[2]), .io_out_0(AgeDetector_12_g_out[0]), .io_out_1(AgeDetector_12_g_out[1]), .io_out_2(AgeDetector_12_g_out[2]));
  AgeDetector_12_xs i_AgeDetector_12 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_12_enq0), .io_enq_1(AgeDetector_12_enq1), .io_canIssue_0(AgeDetector_12_ci[0]), .io_canIssue_1(AgeDetector_12_ci[1]), .io_canIssue_2(AgeDetector_12_ci[2]), .io_out_0(AgeDetector_12_i_out[0]), .io_out_1(AgeDetector_12_i_out[1]), .io_out_2(AgeDetector_12_i_out[2]));
  agedet_env #(.NAME("AgeDetector_12"), .N(2), .NDEQ(3)) e_AgeDetector_12 (
    .clk(clk), .rst(rst), .enq0(AgeDetector_12_enq0), .enq1(AgeDetector_12_enq1),
    .canIssue(AgeDetector_12_ci), .g_out(AgeDetector_12_g_out), .i_out(AgeDetector_12_i_out));

  // --- AgeDetector_13: 14 条目 / 2 入队口 / 1 发射口 ---
  logic [13:0] AgeDetector_13_enq0, AgeDetector_13_enq1;
  logic [13:0] AgeDetector_13_ci [1];
  logic [13:0] AgeDetector_13_g_out [1];
  logic [13:0] AgeDetector_13_i_out [1];
  AgeDetector_13 g_AgeDetector_13 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_13_enq0), .io_enq_1(AgeDetector_13_enq1), .io_canIssue_0(AgeDetector_13_ci[0]), .io_out_0(AgeDetector_13_g_out[0]));
  AgeDetector_13_xs i_AgeDetector_13 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_13_enq0), .io_enq_1(AgeDetector_13_enq1), .io_canIssue_0(AgeDetector_13_ci[0]), .io_out_0(AgeDetector_13_i_out[0]));
  agedet_env #(.NAME("AgeDetector_13"), .N(14), .NDEQ(1)) e_AgeDetector_13 (
    .clk(clk), .rst(rst), .enq0(AgeDetector_13_enq0), .enq1(AgeDetector_13_enq1),
    .canIssue(AgeDetector_13_ci), .g_out(AgeDetector_13_g_out), .i_out(AgeDetector_13_i_out));

  // --- AgeDetector_15: 12 条目 / 2 入队口 / 2 发射口 ---
  logic [11:0] AgeDetector_15_enq0, AgeDetector_15_enq1;
  logic [11:0] AgeDetector_15_ci [2];
  logic [11:0] AgeDetector_15_g_out [2];
  logic [11:0] AgeDetector_15_i_out [2];
  AgeDetector_15 g_AgeDetector_15 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_15_enq0), .io_enq_1(AgeDetector_15_enq1), .io_canIssue_0(AgeDetector_15_ci[0]), .io_canIssue_1(AgeDetector_15_ci[1]), .io_out_0(AgeDetector_15_g_out[0]), .io_out_1(AgeDetector_15_g_out[1]));
  AgeDetector_15_xs i_AgeDetector_15 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_15_enq0), .io_enq_1(AgeDetector_15_enq1), .io_canIssue_0(AgeDetector_15_ci[0]), .io_canIssue_1(AgeDetector_15_ci[1]), .io_out_0(AgeDetector_15_i_out[0]), .io_out_1(AgeDetector_15_i_out[1]));
  agedet_env #(.NAME("AgeDetector_15"), .N(12), .NDEQ(2)) e_AgeDetector_15 (
    .clk(clk), .rst(rst), .enq0(AgeDetector_15_enq0), .enq1(AgeDetector_15_enq1),
    .canIssue(AgeDetector_15_ci), .g_out(AgeDetector_15_g_out), .i_out(AgeDetector_15_i_out));

  // --- AgeDetector_19: 6 条目 / 2 入队口 / 1 发射口 ---
  logic [5:0] AgeDetector_19_enq0, AgeDetector_19_enq1;
  logic [5:0] AgeDetector_19_ci [1];
  logic [5:0] AgeDetector_19_g_out [1];
  logic [5:0] AgeDetector_19_i_out [1];
  AgeDetector_19 g_AgeDetector_19 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_19_enq0), .io_enq_1(AgeDetector_19_enq1), .io_canIssue_0(AgeDetector_19_ci[0]), .io_out_0(AgeDetector_19_g_out[0]));
  AgeDetector_19_xs i_AgeDetector_19 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_19_enq0), .io_enq_1(AgeDetector_19_enq1), .io_canIssue_0(AgeDetector_19_ci[0]), .io_out_0(AgeDetector_19_i_out[0]));
  agedet_env #(.NAME("AgeDetector_19"), .N(6), .NDEQ(1)) e_AgeDetector_19 (
    .clk(clk), .rst(rst), .enq0(AgeDetector_19_enq0), .enq1(AgeDetector_19_enq1),
    .canIssue(AgeDetector_19_ci), .g_out(AgeDetector_19_g_out), .i_out(AgeDetector_19_i_out));

  // --- AgeDetector_21: 12 条目 / 2 入队口 / 1 发射口 ---
  logic [11:0] AgeDetector_21_enq0, AgeDetector_21_enq1;
  logic [11:0] AgeDetector_21_ci [1];
  logic [11:0] AgeDetector_21_g_out [1];
  logic [11:0] AgeDetector_21_i_out [1];
  AgeDetector_21 g_AgeDetector_21 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_21_enq0), .io_enq_1(AgeDetector_21_enq1), .io_canIssue_0(AgeDetector_21_ci[0]), .io_out_0(AgeDetector_21_g_out[0]));
  AgeDetector_21_xs i_AgeDetector_21 (
    .clock(clk), .reset(rst), .io_enq_0(AgeDetector_21_enq0), .io_enq_1(AgeDetector_21_enq1), .io_canIssue_0(AgeDetector_21_ci[0]), .io_out_0(AgeDetector_21_i_out[0]));
  agedet_env #(.NAME("AgeDetector_21"), .N(12), .NDEQ(1)) e_AgeDetector_21 (
    .clk(clk), .rst(rst), .enq0(AgeDetector_21_enq0), .enq1(AgeDetector_21_enq1),
    .canIssue(AgeDetector_21_ci), .g_out(AgeDetector_21_g_out), .i_out(AgeDetector_21_i_out));

  initial begin
    int bad;
    longint tot_checks;
    int tot_errors;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    bad = 0;
    tot_checks = 0;
    tot_errors = 0;
    bad += e_AgeDetector.report();
    tot_checks += e_AgeDetector.checks;
    tot_errors += e_AgeDetector.errors;
    bad += e_AgeDetector_1.report();
    tot_checks += e_AgeDetector_1.checks;
    tot_errors += e_AgeDetector_1.errors;
    bad += e_AgeDetector_8.report();
    tot_checks += e_AgeDetector_8.checks;
    tot_errors += e_AgeDetector_8.errors;
    bad += e_AgeDetector_9.report();
    tot_checks += e_AgeDetector_9.checks;
    tot_errors += e_AgeDetector_9.errors;
    bad += e_AgeDetector_12.report();
    tot_checks += e_AgeDetector_12.checks;
    tot_errors += e_AgeDetector_12.errors;
    bad += e_AgeDetector_13.report();
    tot_checks += e_AgeDetector_13.checks;
    tot_errors += e_AgeDetector_13.errors;
    bad += e_AgeDetector_15.report();
    tot_checks += e_AgeDetector_15.checks;
    tot_errors += e_AgeDetector_15.errors;
    bad += e_AgeDetector_19.report();
    tot_checks += e_AgeDetector_19.checks;
    tot_errors += e_AgeDetector_19.errors;
    bad += e_AgeDetector_21.report();
    tot_checks += e_AgeDetector_21.checks;
    tot_errors += e_AgeDetector_21.errors;
    $display("VARIANTS=9 bad=%0d", bad);
    $display("checks=%0d errors=%0d", tot_checks, tot_errors);
    if (bad == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
