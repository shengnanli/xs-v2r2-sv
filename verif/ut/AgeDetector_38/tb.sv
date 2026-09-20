// AgeDetector_38 UT —— golden 与重写件双例化逐拍比对
//
// 为什么不能只用均匀随机：本模块的年龄矩阵只在"同拍多口进队""进队与出队撞同一
// 条目""多个 ready 候选争最老"这几种情形下才分出对错，纯随机很难稳定制造。
// 所以激励分 5 个相位轮转（见 phase），并且 io_ready 有一个**成对探测**相位：
// 只把两个条目置 ready，io_out 就直接把 get_age(i,j) 这一位读出来 —— 276 个
// 上三角非对角元素因此都能被单独观测到，而不是淹没在 24 选 1 的结果里。
`timescale 1ns/1ps
module tb;
  localparam int N = 24;

  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;

  always #5 clk = ~clk;

  logic [N-1:0] io_enq_0, io_enq_1, io_enq_2, io_deq, io_ready;
  logic [N-1:0] g_io_out, i_io_out;

  AgeDetector_38 g_u (
    .clock(clk), .reset(rst),
    .io_enq_0(io_enq_0), .io_enq_1(io_enq_1), .io_enq_2(io_enq_2),
    .io_deq(io_deq), .io_ready(io_ready), .io_out(g_io_out));
  AgeDetector_38_xs i_u (
    .clock(clk), .reset(rst),
    .io_enq_0(io_enq_0), .io_enq_1(io_enq_1), .io_enq_2(io_enq_2),
    .io_deq(io_deq), .io_ready(io_ready), .io_out(i_io_out));

  // ---------------------------------------------------------------------------
  // 激励模型：维护"哪些条目当前有效"，保证 enq 只进空条目、deq 只清有效条目，
  // 这样年龄矩阵的语义才有意义（非法激励下两边一样错，等于没测）。
  // ---------------------------------------------------------------------------
  bit [N-1:0] valid;
  int         phase;
  int         pairI, pairJ;   // 成对探测相位用的两个条目号

  // 覆盖统计
  int cov_full;         // 24 项全有效
  int cov_empty;        // 全无效
  int cov_enq3;         // 同拍 3 个口都进队
  int cov_enq_deq;      // 同拍某条目既 enq 又 deq
  int cov_out_hit;      // io_out 非 0（真的选出了一个）
  int cov_multi_ready;  // ready 里有 >= 2 个候选
  bit cov_pair_seen [N][N];  // 成对探测覆盖到的 (i,j)

  function automatic int pick_free(input bit [N-1:0] used);
    int cand [$];
    for (int k = 0; k < N; k++) if (!used[k]) cand.push_back(k);
    if (cand.size() == 0) return -1;
    return cand[$urandom_range(0, cand.size()-1)];
  endfunction

  function automatic int pick_valid(input bit [N-1:0] v);
    int cand [$];
    for (int k = 0; k < N; k++) if (v[k]) cand.push_back(k);
    if (cand.size() == 0) return -1;
    return cand[$urandom_range(0, cand.size()-1)];
  endfunction

  task automatic gen_stimulus();
    bit [N-1:0] used;
    int         slot, nDeq;
    begin
      io_enq_0 = '0; io_enq_1 = '0; io_enq_2 = '0; io_deq = '0; io_ready = '0;
      used = valid;

      case (phase)
        // 相位 0：猛灌 —— 三口每拍都进队，直到填满。制造"同拍三口进队"的
        //         端口优先级场景（规则 (3) 的 beatenByEarlierPort）。
        0: begin
          for (int k = 0; k < 3; k++) begin
            slot = pick_free(used);
            if (slot >= 0) begin
              used[slot] = 1'b1;
              case (k)
                0: io_enq_0[slot] = 1'b1;
                1: io_enq_1[slot] = 1'b1;
                default: io_enq_2[slot] = 1'b1;
              endcase
            end
          end
        end

        // 相位 1：进队与出队撞同一条目 —— isEnqueued 被 !deq 门掉的那条路径。
        1: begin
          slot = pick_free(used);
          if (slot >= 0) begin
            io_enq_0[slot] = 1'b1;
            io_enq_1[slot] = 1'b1;   // 两口同时指向同一条目（非 one-hot 也要能对上）
            io_deq[slot]   = 1'b1;   // 同拍又被释放
            used[slot]     = 1'b1;
          end
          slot = pick_valid(valid);
          if (slot >= 0) io_deq[slot] = 1'b1;
        end

        // 相位 2：随机混合（进队 0~3 个、出队 0~3 个）
        2: begin
          for (int k = 0; k < 3; k++) if ($urandom_range(0,2) != 0) begin
            slot = pick_free(used);
            if (slot >= 0) begin
              used[slot] = 1'b1;
              case (k)
                0: io_enq_0[slot] = 1'b1;
                1: io_enq_1[slot] = 1'b1;
                default: io_enq_2[slot] = 1'b1;
              endcase
            end
          end
          nDeq = $urandom_range(0,3);
          for (int k = 0; k < nDeq; k++) begin
            slot = pick_valid(valid & ~io_deq);
            if (slot >= 0) io_deq[slot] = 1'b1;
          end
        end

        // 相位 3：只出队，把队列抽空（回到全无效的边界）
        3: begin
          nDeq = $urandom_range(1,3);
          for (int k = 0; k < nDeq; k++) begin
            slot = pick_valid(valid & ~io_deq);
            if (slot >= 0) io_deq[slot] = 1'b1;
          end
        end

        // 相位 4：静止 —— 不动矩阵，只扫 ready（给成对探测留出稳定窗口）
        default: ;
      endcase

      // ready 的三种口径轮转：
      //   成对探测：只点亮 pairI/pairJ 两位 → io_out 直接暴露 get_age(pairI,pairJ)
      //   全 ready ：暴露全局最老
      //   随机子集：常规覆盖
      case ($urandom_range(0,2))
        0: begin
          io_ready = '0;
          io_ready[pairI] = 1'b1;
          io_ready[pairJ] = 1'b1;
          pairJ = pairJ + 1;
          if (pairJ >= N) begin
            pairI = (pairI + 1) % N;
            pairJ = 0;
          end
        end
        1: io_ready = {$urandom, $urandom};
        default: io_ready = '1;
      endcase
    end
  endtask

  always @(negedge clk) begin
    if (rst) begin
      io_enq_0 <= '0; io_enq_1 <= '0; io_enq_2 <= '0; io_deq <= '0; io_ready <= '0;
      valid <= '0; phase <= 0; pairI <= 0; pairJ <= 1;
    end else begin
      // 记账：上一拍生效的 enq/deq 更新有效位（deq 优先，与 isEnqueued 的
      // `& ~io_deq` 一致）
      for (int k = 0; k < N; k++) begin
        if (io_deq[k])                                   valid[k] <= 1'b0;
        else if (io_enq_0[k] | io_enq_1[k] | io_enq_2[k]) valid[k] <= 1'b1;
      end
      phase <= ($urandom_range(0,63) == 0) ? $urandom_range(0,4) : phase;
      gen_stimulus();
    end
  end

  always @(posedge clk) if (!rst) begin
    int nv, nr;
    nv = $countones(valid);
    if (nv == N) cov_full++;
    if (nv == 0)  cov_empty++;
    if ((|io_enq_0) && (|io_enq_1) && (|io_enq_2)) cov_enq3++;
    if (|((io_enq_0 | io_enq_1 | io_enq_2) & io_deq)) cov_enq_deq++;
    if (|g_io_out) cov_out_hit++;
    nr = $countones(io_ready);
    if (nr >= 2) cov_multi_ready++;
    if (nr == 2) begin
      int a, b;
      a = -1; b = -1;
      for (int k = 0; k < N; k++) if (io_ready[k]) begin
        if (a < 0) a = k; else b = k;
      end
      if (a >= 0 && b >= 0) cov_pair_seen[a][b] = 1'b1;
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_out) && g_io_out !== i_io_out) begin
      errors++;
      if (errors <= 80)
        $display("[%0t] io_out g=%h i=%h (enq=%h/%h/%h deq=%h ready=%h)",
                 $time, g_io_out, i_io_out, io_enq_0, io_enq_1, io_enq_2,
                 io_deq, io_ready);
    end
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    begin
      int npair;
      npair = 0;
      for (int a = 0; a < N; a++)
        for (int b = a+1; b < N; b++) if (cov_pair_seen[a][b]) npair++;
      $display("COV full=%0d empty=%0d enq3=%0d enq_deq_same=%0d out_hit=%0d multi_ready=%0d pairs=%0d/%0d",
               cov_full, cov_empty, cov_enq3, cov_enq_deq, cov_out_hit,
               cov_multi_ready, npair, N*(N-1)/2);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
