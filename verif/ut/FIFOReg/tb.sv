// FIFOReg 双例化逐拍比对：golden FIFOReg vs 可读重写 FIFOReg_xs。
// 被测：10 深 × 4 位寄存器堆循环 FIFO（flag 位判空满、非 2 的幂回绕、flush 只清指针）。
// 激励：enq_valid / deq_ready 各 ~60%，flush 低概率注入（含"flush 与入队同拍"），
//   reset 偶尔异步脉冲；enq_bits 用递增计数以便肉眼核对顺序，同时混入随机值。
// 覆盖闸（小 FIFO 最容易只在"半空"区间打转就报绿）：必须
//   (1) 有效比对 >= COV_MIN；(2) 入队 / 出队各 >= COV_MIN；
//   (3) **队满**（enq_ready=0）与**队空**（deq_valid=0）各 >= COV_MIN；
//   (4) 指针回绕（写指针走到 9 再回 0）>= COV_MIN；
//   (5) flush >= COV_MIN，且 flush 与入队同拍 >= 1（golden 在这一拍照写不误）；
//   (6) 10 个条目都被写过。任何一项不足即 TEST FAILED。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  logic reset;
  int errors = 0, checks = 0, cov_fail = 0;
  always #5 clock = ~clock;

  logic       enq_valid, deq_ready, flush;
  logic [3:0] enq_bits;
  wire        g_enq_ready, i_enq_ready, g_deq_valid, i_deq_valid;
  wire [3:0]  g_deq_bits, i_deq_bits;

  FIFOReg u_g (
    .clock(clock), .reset(reset),
    .io_enq_ready(g_enq_ready), .io_enq_valid(enq_valid), .io_enq_bits(enq_bits),
    .io_deq_ready(deq_ready), .io_deq_valid(g_deq_valid), .io_deq_bits(g_deq_bits),
    .io_flush(flush)
  );
  FIFOReg_xs u_i (
    .clock(clock), .reset(reset),
    .io_enq_ready(i_enq_ready), .io_enq_valid(enq_valid), .io_enq_bits(enq_bits),
    .io_deq_ready(deq_ready), .io_deq_valid(i_deq_valid), .io_deq_bits(i_deq_bits),
    .io_flush(flush)
  );

  int c_enq, c_deq, c_full, c_empty, c_wrap, c_flush, c_flush_enq;
  logic [9:0] written;
  int wr_idx;   // tb 侧影子写指针，只用于覆盖统计
  logic [3:0] seq;

  function automatic int cov_short(string what, int n, int need);
    if (n < need) begin
      $display("COVERAGE FAIL: %s 只发生 %0d 次 (需 >= %0d)", what, n, need);
      return 1;
    end
    return 0;
  endfunction

  task automatic drive_random_inputs();
    enq_valid = ($urandom_range(0, 9) < 6);
    deq_ready = ($urandom_range(0, 9) < 6);
    flush     = ($urandom_range(0, 79) == 0);
    if ($urandom_range(0, 1)) begin
      enq_bits = seq;              // 递增序列：出队顺序错了一眼看得出
      seq = 4'(seq + 1);
    end else begin
      enq_bits = 4'($urandom);     // 随机值
    end
  endtask

  task automatic check_outputs();
    checks++;
    if (g_enq_ready & enq_valid) begin
      c_enq++;
      written[wr_idx] = 1'b1;
      if (wr_idx == 9) begin c_wrap++; wr_idx = 0; end
      else wr_idx++;
    end
    if (deq_ready & g_deq_valid) c_deq++;
    if (!g_enq_ready)  c_full++;
    if (!g_deq_valid)  c_empty++;
    if (flush) begin
      c_flush++;
      if (g_enq_ready & enq_valid) c_flush_enq++;
      wr_idx = 0;
    end
    if ({g_enq_ready, g_deq_valid, g_deq_bits} !== {i_enq_ready, i_deq_valid, i_deq_bits}) begin
      errors++;
      if (errors <= 20)
        $display("[%0t] MISMATCH FIFOReg g={%0b,%0b,%0h} i={%0b,%0b,%0h}", $time,
                 g_enq_ready, g_deq_valid, g_deq_bits, i_enq_ready, i_deq_valid, i_deq_bits);
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    reset = 1'b1;
    enq_valid = 0; deq_ready = 0; flush = 0; enq_bits = '0; seq = '0;
    c_enq = 0; c_deq = 0; c_full = 0; c_empty = 0; c_wrap = 0;
    c_flush = 0; c_flush_enq = 0; written = '0; wr_idx = 0;
    repeat (4) @(negedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
      @(posedge clock);
      if ($urandom_range(0, 9999) == 0) begin   // 异步复位脉冲
        reset = 1'b1;
        #1 reset = 1'b0;
        wr_idx = 0;
      end
    end
    $display("FIFOReg checks=%0d errors=%0d", checks, errors);
    $display("  enq=%0d deq=%0d full=%0d empty=%0d wrap=%0d flush=%0d flush&enq=%0d written=%0h/3ff",
             c_enq, c_deq, c_full, c_empty, c_wrap, c_flush, c_flush_enq, written);
    cov_fail += cov_short("FIFOReg checks", checks, COV_MIN)
              + cov_short("FIFOReg enq",    c_enq,  COV_MIN)
              + cov_short("FIFOReg deq",    c_deq,  COV_MIN)
              + cov_short("FIFOReg 队满",   c_full, COV_MIN)
              + cov_short("FIFOReg 队空",   c_empty, COV_MIN)
              + cov_short("FIFOReg 写指针回绕", c_wrap, COV_MIN)
              + cov_short("FIFOReg flush",  c_flush, COV_MIN)
              + cov_short("FIFOReg flush 与入队同拍", c_flush_enq, 1);
    if (written !== 10'h3ff) begin
      $display("COVERAGE FAIL: FIFOReg 有条目从未被写过 (written=%0h)", written);
      cov_fail++;
    end
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
