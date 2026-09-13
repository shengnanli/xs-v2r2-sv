// =============================================================================
// FIFOReg —— 寄存器堆实现的小容量循环 FIFO（ICacheMissUnit 的预取 MSHR 空闲队列）
//
// 位置：ICacheMissUnit 用它排队"哪几个预取 MSHR 现在空闲"。10 个预取 MSHR，
//       每个用 4 位编号表示，所以是一条 10 深 × 4 位的队列。深度小、要单拍出数，
//       所以用寄存器堆而不是 SRAM。
//
// 机制：读写指针各带一个 flag 位（"绕了奇数圈"标记），这是小 FIFO 的经典做法：
//   空 = {enq_flag, enq_ptr} == {deq_flag, deq_ptr}
//   满 = enq_ptr == deq_ptr 且 两个 flag 不同（指针追上了但圈数差一）
//   指针到 DEPTH 就回 0 并翻转 flag —— 注意 DEPTH=10 不是 2 的幂，所以是
//   "加一后减 DEPTH，非负就回绕"，不能靠位宽自然回绕。
//   io_flush 把两个指针与两个 flag 一起清零（队列瞬间变空），但**不清数据**。
//
// ★ 两处 golden 行为必须照抄，不能"顺手修好"：
//   1) 出队读口的越界行为：指针值域是 4 位（0..15）而队列只有 10 项，
//      firtool 把读多路展开成一张 16 项表，10..15 全部指向第 0 项。
//      所以 deq_ptr_value >= 10 时读出的是 regfile[0]，不是 X、也不是回绕到
//      idx-10。正常运行到不了这里（指针受回绕逻辑约束），但 FM 要逐位等价，
//      本核用显式的 (idx < DEPTH) ? regfile[idx] : regfile[0] 复现。
//   2) io_flush 与入队同拍时：enq_ptr_value 被清零（flush 优先），但
//      regfile 该写还是写（写使能不看 flush）—— 写进的是**被清零前**的
//      enq_ptr_value 指向的那一项。照抄。
//
// 本文件 = 参数化可读核 xs_FIFOReg_core + golden 同名 wrapper。
// =============================================================================

module xs_FIFOReg_core #(
  parameter int unsigned WIDTH = 4,    // 单项位宽
  parameter int unsigned DEPTH = 10,   // 队列深度（不必是 2 的幂）
  parameter int unsigned PTR_W = 4,    // golden 指针位宽 = $bits(enq_ptr_value)
  // ---- 由 wrapper 从 golden 端口表算出来，只用于自检 ----
  parameter int unsigned PORT_BITS_ENQ = WIDTH,   // = $bits(io_enq_bits)
  parameter int unsigned PORT_BITS_DEQ = WIDTH,   // = $bits(io_deq_bits)
  parameter int unsigned GOLDEN_PORTS  = 9        // golden 端口总数
)(
  input  logic             clock,
  input  logic             reset,      // 异步高有效，照搬 golden
  input  logic             flush,      // 清空（只清指针，不清数据）
  output logic             enq_ready,
  input  logic             enq_valid,
  input  logic [WIDTH-1:0] enq_bits,
  input  logic             deq_ready,
  output logic             deq_valid,
  output logic [WIDTH-1:0] deq_bits
);

  initial begin
    if (DEPTH < 2 || WIDTH == 0)
      $fatal(1, "xs_FIFOReg_core: DEPTH=%0d WIDTH=%0d 不合法", DEPTH, WIDTH);
    // 指针位宽必须刚好装得下 0..DEPTH-1：抄宽了会多出永远走不到的编码，
    // 抄窄了回绕算术直接错。golden 的 PTR_W 就是 clog2(DEPTH)。
    if (PTR_W != $clog2(DEPTH))
      $fatal(1, "xs_FIFOReg_core: PTR_W=%0d != clog2(DEPTH=%0d)=%0d（深度或指针位宽抄错）",
             PTR_W, DEPTH, $clog2(DEPTH));
    if (PORT_BITS_ENQ != WIDTH || PORT_BITS_DEQ != WIDTH)
      $fatal(1, "xs_FIFOReg_core: golden 数据端口 enq=%0d deq=%0d != WIDTH=%0d（位宽抄错）",
             PORT_BITS_ENQ, PORT_BITS_DEQ, WIDTH);
    // golden 端口数恒等式：clock/reset/flush + enq 三根 + deq 三根
    if (GOLDEN_PORTS != 9)
      $fatal(1, "xs_FIFOReg_core: golden 端口数 %0d != 9（端口表变了，核要跟着改）",
             GOLDEN_PORTS);
  end

  logic [WIDTH-1:0] regfile [DEPTH];
  logic             enq_flag_q, deq_flag_q;
  logic [PTR_W-1:0] enq_ptr_q,  deq_ptr_q;

  logic full, do_enq, do_deq;
  assign full      = (enq_ptr_q == deq_ptr_q) & (enq_flag_q ^ deq_flag_q);
  assign enq_ready = ~full;
  assign deq_valid = {enq_flag_q, enq_ptr_q} != {deq_flag_q, deq_ptr_q};
  assign do_enq    = enq_ready & enq_valid;
  assign do_deq    = deq_ready & deq_valid;

  // 指针加一并回绕：DEPTH 不是 2 的幂，所以是"加一后减 DEPTH，够减就用差值"。
  // ★ 这里刻意用"加一后与 DEPTH 比"而不是"等于 DEPTH-1"：指针位宽 PTR_W 能表示
  //   0..2^PTR_W-1，比 DEPTH 大，越界值（10..15）在正常运行到不了，但 FM 要比
  //   全状态空间。golden 在越界值上给的是 (v+1-DEPTH)，"等于 DEPTH-1"的写法在
  //   那些状态上会给出不同的次态，FM 立刻不等价。
  logic [PTR_W:0]   enq_ptr_inc, deq_ptr_inc;   // 多一位，加一不会溢出
  logic             enq_wrap, deq_wrap;
  logic [PTR_W-1:0] enq_ptr_next, deq_ptr_next;
  always_comb begin
    enq_ptr_inc  = (PTR_W+1)'(enq_ptr_q) + (PTR_W+1)'(1);
    deq_ptr_inc  = (PTR_W+1)'(deq_ptr_q) + (PTR_W+1)'(1);
    enq_wrap     = (enq_ptr_inc >= (PTR_W+1)'(DEPTH));
    deq_wrap     = (deq_ptr_inc >= (PTR_W+1)'(DEPTH));
    enq_ptr_next = enq_wrap ? PTR_W'(enq_ptr_inc - (PTR_W+1)'(DEPTH)) : PTR_W'(enq_ptr_inc);
    deq_ptr_next = deq_wrap ? PTR_W'(deq_ptr_inc - (PTR_W+1)'(DEPTH)) : PTR_W'(deq_ptr_inc);
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int unsigned i = 0; i < DEPTH; i++)
        regfile[i] <= '0;
      enq_flag_q <= 1'b0;
      enq_ptr_q  <= '0;
      deq_flag_q <= 1'b0;
      deq_ptr_q  <= '0;
    end
    else begin
      // 写译码：写使能**不看 flush**（照抄 golden，见文件头 ★2）；
      // 显式逐项译码而不是 regfile[enq_ptr_q] <= …，这样 enq_ptr_q 越界时
      // "谁都不写"是写在明面上的，而不是靠语言的越界规则。
      for (int unsigned i = 0; i < DEPTH; i++)
        if (do_enq && enq_ptr_q == PTR_W'(i))
          regfile[i] <= enq_bits;

      // flag：flush 清零；否则每绕一圈翻一次
      enq_flag_q <= ~flush & ((do_enq & enq_wrap) ^ enq_flag_q);
      deq_flag_q <= ~flush & ((do_deq & deq_wrap) ^ deq_flag_q);

      if (flush) begin
        enq_ptr_q <= '0;
        deq_ptr_q <= '0;
      end
      else begin
        if (do_enq) enq_ptr_q <= enq_ptr_next;
        if (do_deq) deq_ptr_q <= deq_ptr_next;
      end
    end
  end

  // 出队读口：指针值域 0..2^PTR_W-1 比 DEPTH 大，越界一律读第 0 项 —— 见文件头 ★1
  assign deq_bits = (deq_ptr_q < PTR_W'(DEPTH)) ? regfile[deq_ptr_q] : regfile[0];

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：ICacheMissUnit 的预取 MSHR 空闲队列（10 深 × 4 位）
// ---------------------------------------------------------------------------
module FIFOReg(
  input        clock,
  input        reset,
  output       io_enq_ready,
  input        io_enq_valid,
  input  [3:0] io_enq_bits,
  input        io_deq_ready,
  output       io_deq_valid,
  output [3:0] io_deq_bits,
  input        io_flush
);

  xs_FIFOReg_core #(
    .WIDTH        (4),
    .DEPTH        (10),
    .PTR_W        (4),
    // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
    .PORT_BITS_ENQ($bits(io_enq_bits)),
    .PORT_BITS_DEQ($bits(io_deq_bits)),
    .GOLDEN_PORTS (9)
  ) u_core (
    .clock    (clock),
    .reset    (reset),
    .flush    (io_flush),
    .enq_ready(io_enq_ready),
    .enq_valid(io_enq_valid),
    .enq_bits (io_enq_bits),
    .deq_ready(io_deq_ready),
    .deq_valid(io_deq_valid),
    .deq_bits (io_deq_bits)
  );

endmodule
