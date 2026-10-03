// =============================================================================
// xs_OffsetScoreTable_core —— BOP（Best-Offset 预取器）的"偏移评分表"参数化核
//
// 位置：L2 的 BestOffsetPrefetch 里，决定"当前用哪个偏移 D 做预取（X -> X+D）"。
//
// 算法（Michaud, HPCA'16）：候选偏移表 OFFSET_LIST 里每个偏移 d 配一个得分。
//   学习阶段内，每来一次训练访问 X（req），就轮流拿下一个候选 d 去问 RR 表
//   "X-d 最近是否被访问过"（test_req，一拍后 test_resp 回 hit）。命中说明
//   "当初若用 d 预取，现在这次访问就被覆盖了"，于是 d 的得分 +1。
//   全部候选各测一次算一"轮"。学习阶段在下面两种情况之一结束：
//     (1) 某个得分加到了 SCORE_MAX（全 1）；
//     (2) 轮数达到 ROUND_MAX。
//   结束后花一拍（s_idle）：把学习期间见到的最高分偏移 bestOffset 发布为
//   prefetchOffset，最高分低于 BAD_SCORE 则发布 prefetchDisable=1（关预取），
//   同时清空所有得分、指针、轮数，下一拍重新开始学习。
//
// 输入输出：
//   req_valid/req_addr   训练访问；仅学习态 ready。
//   test_req_*           发给 RR 表的查询：地址原样带出，testOffset=当前候选，ptr=候选下标。
//                        （golden 没有 test_req_ready 端口，查询必被接收，fire == valid）
//   test_resp_*          RR 表的回答：ptr 指明是哪个候选，hit 表示命中。
//   prefetch_offset/disable  当前发布的预取偏移 / 关断标志。
//
// 怪癖（照 golden，bug-for-bug）：
//   1. test_resp_ptr / ptr 的位宽能表示到 2^PTR_W-1，超出候选数 N 的下标读到的是
//      **第 0 项**（得分与偏移都是），而写得分时没有任何条目被写。
//      bestOffset/bestScore 仍会按"第 0 项得分 +1"参与比较与更新。
//   2. 学习态下 resp 命中与"轮数到顶"同拍出现时都回 idle；state 的次态里
//      "轮数到顶"与"得分到顶"是或关系。
//   3. 轮数到顶的比较是 round >= ROUND_MAX（golden 写成 round > ROUND_MAX-1）。
//   4. idle 那一拍无条件清分，即使同拍来了 resp 命中（idle 时不记分）。
//   5. 全部寄存器异步复位；prefetchOffset / bestOffset 复位值为 2。
// =============================================================================

module xs_OffsetScoreTable_core #(
  parameter int unsigned ADDR_W    = 48,
  parameter int unsigned OFFSET_W  = 7,
  parameter int unsigned N         = 37,   // 候选偏移个数
  parameter int unsigned PTR_W     = 6,    // = log2Up(N)
  parameter int unsigned SCORE_W   = 5,
  parameter int unsigned ROUND_W   = 6,
  parameter int unsigned ROUND_MAX = 50,
  parameter int unsigned BAD_SCORE = 1,
  // 候选偏移表，下标 0 在最左（OFFSET_W 位补码）
  parameter logic [0:N-1][OFFSET_W-1:0] OFFSET_LIST = '0
) (
  input  logic                clock,
  input  logic                reset,
  // 训练访问
  output logic                req_ready,
  input  logic                req_valid,
  input  logic [ADDR_W-1:0]   req_addr,
  // 发布的预取偏移
  output logic [OFFSET_W-1:0] prefetch_offset,
  output logic                prefetch_disable,
  // 向 RR 表查询 X-d
  output logic                test_req_valid,
  output logic [ADDR_W-1:0]   test_req_addr,
  output logic [OFFSET_W-1:0] test_req_offset,
  output logic [PTR_W-1:0]    test_req_ptr,
  input  logic                test_resp_valid,
  input  logic [PTR_W-1:0]    test_resp_ptr,
  input  logic                test_resp_hit
);

  typedef enum logic { S_IDLE = 1'b0, S_LEARN = 1'b1 } state_e;

  // ---------------------------------------------------------------------------
  // 状态
  // ---------------------------------------------------------------------------
  state_e              state;
  logic [SCORE_W-1:0]  score [N];        // 每个候选偏移的得分
  logic [PTR_W-1:0]    ptr;              // 本轮下一个要测的候选下标
  logic [ROUND_W-1:0]  round;            // 已完成的轮数
  logic [OFFSET_W-1:0] best_offset;      // 本学习阶段至今得分最高的偏移
  logic [SCORE_W-1:0]  best_score;
  logic [OFFSET_W-1:0] prefetch_offset_q;
  logic                prefetch_disable_q;

  logic learning;
  assign learning = (state == S_LEARN);

  // ---------------------------------------------------------------------------
  // 查表：下标越界读第 0 项（怪癖 1）。用循环形式的选择器而不是直接下标 ——
  // N 不是 2 的幂，直接 score[ptr] 会让 Formality 报下标越界（FMR_ELAB-147）。
  // ---------------------------------------------------------------------------
  logic [OFFSET_W-1:0] test_offset;      // offList(ptr)
  logic [OFFSET_W-1:0] resp_offset;      // offList(resp.ptr)
  logic [SCORE_W-1:0]  resp_old_score;   // st(resp.ptr).score

  always_comb begin
    test_offset    = OFFSET_LIST[0];
    resp_offset    = OFFSET_LIST[0];
    resp_old_score = score[0];
    for (int unsigned i = 1; i < N; i++) begin
      if (ptr == PTR_W'(i)) test_offset = OFFSET_LIST[i];
      if (test_resp_ptr == PTR_W'(i)) begin
        resp_offset    = OFFSET_LIST[i];
        resp_old_score = score[i];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 学习阶段的事件
  // ---------------------------------------------------------------------------
  logic               test_fire;     // 本拍发出一次查询
  logic               resp_hit;      // 本拍收到一次命中回答
  logic [SCORE_W-1:0] new_score;
  logic               renew_best;
  logic               round_finish;  // 本轮最后一个候选
  logic               rounds_done;   // 结束条件 (2)
  logic               score_full;    // 结束条件 (1)
  logic               is_bad;

  assign test_fire    = learning & req_valid;
  assign resp_hit     = test_resp_valid & test_resp_hit;
  assign new_score    = resp_old_score + 1'b1;
  assign renew_best   = (new_score > best_score);
  assign round_finish = (ptr == PTR_W'(N - 1));
  assign rounds_done  = (round >= ROUND_W'(ROUND_MAX));
  assign score_full   = (&new_score);
  assign is_bad       = (best_score < SCORE_W'(BAD_SCORE));

  // ---------------------------------------------------------------------------
  // 得分表：idle 清零；学习态下命中的那一项 +1
  // ---------------------------------------------------------------------------
  for (genvar i = 0; i < N; i++) begin : g_score
    always_ff @(posedge clock or posedge reset) begin
      if (reset)                                          score[i] <= '0;
      else if (!learning)                                 score[i] <= '0;
      else if (resp_hit && test_resp_ptr == PTR_W'(i))    score[i] <= new_score;
    end
  end

  // ---------------------------------------------------------------------------
  // 状态机与其余寄存器
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      state              <= S_IDLE;
      ptr                <= '0;
      round              <= '0;
      best_offset        <= OFFSET_W'(2);
      best_score         <= '0;
      prefetch_offset_q  <= OFFSET_W'(2);
      prefetch_disable_q <= 1'b0;
    end else if (!learning) begin
      // ---- idle 一拍：发布上一阶段的结果，清场，开始新的学习阶段 ----
      state              <= S_LEARN;
      ptr                <= '0;
      round              <= '0;
      best_score         <= '0;
      prefetch_offset_q  <= best_offset;
      prefetch_disable_q <= is_bad;
    end else begin
      // ---- 学习态 ----
      if (test_fire) begin
        if (round_finish) begin
          ptr   <= '0;
          round <= round + 1'b1;
        end else begin
          ptr   <= ptr + 1'b1;
        end
      end
      if (resp_hit && renew_best) begin
        best_offset <= resp_offset;
        best_score  <= new_score;
      end
      if (rounds_done || (resp_hit && score_full)) state <= S_IDLE;
    end
  end

  // ---------------------------------------------------------------------------
  // 输出
  // ---------------------------------------------------------------------------
  assign req_ready        = learning;
  assign prefetch_offset  = prefetch_offset_q;
  assign prefetch_disable = prefetch_disable_q;
  assign test_req_valid   = test_fire;
  assign test_req_addr    = req_addr;
  assign test_req_offset  = test_offset;
  assign test_req_ptr     = ptr;

endmodule
