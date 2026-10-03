// DelayQueue UT —— DelayQueue / DelayQueue_1 两对 golden vs 重写件双例化，逐拍比全部输出
//
// 定向打的点：
//  (1) 时延控制字大多取小值（1~12），否则默认 300 拍的倒计时会让队列长期塞满、几乎不出队；
//      仍留 0.5% 的 0（走默认 300）与 0.5% 的任意值。
//  (2) 入队密度分相位：稀疏相（队列常空）/ 密集相（队列常满 → 打"满则丢弃"）。
//  (3) out_ready 随机，偶尔长时间为 0。
//  (4) 运行中途再打几次异步复位（复位域自证：地址载荷也要清零）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic [9:0]  lat;
  logic        in_valid;
  logic [43:0] in_bits;
  logic        out_ready;

  wire        g0_v, i0_v, g1_v, i1_v;
  wire [47:0] g0_b, i0_b;
  wire [49:0] g1_b, i1_b;

  DelayQueue      g0 (.clock(clk), .reset(rst), .io_pfCtrlOfDelayLatency(lat), .io_in_valid(in_valid),
                      .io_in_bits(in_bits[41:0]), .io_out_ready(out_ready), .io_out_valid(g0_v), .io_out_bits(g0_b));
  DelayQueue_xs   i0 (.clock(clk), .reset(rst), .io_pfCtrlOfDelayLatency(lat), .io_in_valid(in_valid),
                      .io_in_bits(in_bits[41:0]), .io_out_ready(out_ready), .io_out_valid(i0_v), .io_out_bits(i0_b));
  DelayQueue_1    g1 (.clock(clk), .reset(rst), .io_pfCtrlOfDelayLatency(lat), .io_in_valid(in_valid),
                      .io_in_bits(in_bits), .io_out_ready(out_ready), .io_out_valid(g1_v), .io_out_bits(g1_b));
  DelayQueue_1_xs i1 (.clock(clk), .reset(rst), .io_pfCtrlOfDelayLatency(lat), .io_in_valid(in_valid),
                      .io_in_bits(in_bits), .io_out_ready(out_ready), .io_out_valid(i1_v), .io_out_bits(i1_b));

  int cyc;
  int phase;          // 0 稀疏 / 1 密集 / 2 堵出口
  int cov_enq, cov_drop_full, cov_deq, cov_default_lat, cov_stall, cov_midrst;

  // golden 内部的满标志（仅用于覆盖计数，不参与比对）
  wire g_full = g0.full_probe;

  always @(negedge clk) begin
    if (rst) begin
      cyc <= 0; lat <= '0; in_valid <= 1'b0; in_bits <= '0; out_ready <= 1'b0; phase <= 0;
    end else begin
      cyc <= cyc + 1;
      if ($urandom_range(0, 499) == 0) phase <= $urandom_range(0, 2);
      case ($urandom_range(0, 199))
        0:       lat <= 10'd0;
        1:       lat <= 10'($urandom);
        default: lat <= 10'($urandom_range(1, 12));
      endcase
      in_valid  <= (phase == 0) ? ($urandom_range(0, 7) == 0) : ($urandom_range(0, 3) != 0);
      in_bits   <= {$urandom, $urandom};
      out_ready <= (phase == 2) ? ($urandom_range(0, 15) == 0) : ($urandom_range(0, 3) != 0);
    end
  end

  `define CHK(nm, g, i) \
    if ((g) !== (i)) begin errors++; \
      if (errors <= 40) $display("[cyc %0d] %s g=%h i=%h", cyc, nm, g, i); end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("DelayQueue.out_valid",   g0_v, i0_v)
    `CHK("DelayQueue.out_bits",    g0_b, i0_b)
    `CHK("DelayQueue_1.out_valid", g1_v, i1_v)
    `CHK("DelayQueue_1.out_bits",  g1_b, i1_b)
    if (in_valid && !g_full) cov_enq++;
    if (in_valid &&  g_full) cov_drop_full++;
    if (g0_v && out_ready)   cov_deq++;
    if (g0_v && !out_ready)  cov_stall++;
    if (in_valid && !g_full && lat == 0) cov_default_lat++;
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    for (int k = 0; k < 4; k++) begin
      repeat (NCYCLES / 4) @(posedge clk);
      if (k < 3) begin
        // 异步复位：在时钟沿之间拉起
        #2 rst = 1; cov_midrst++;
        repeat (3) @(posedge clk);
        #2 rst = 0;
      end
    end
    $display("COV enq=%0d drop_full=%0d deq=%0d stall=%0d default_lat=%0d midrst=%0d",
             cov_enq, cov_drop_full, cov_deq, cov_stall, cov_default_lat, cov_midrst);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_enq > 1000 && cov_drop_full > 1000 && cov_deq > 1000
        && cov_stall > 100 && cov_default_lat > 10 && cov_midrst == 3)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
