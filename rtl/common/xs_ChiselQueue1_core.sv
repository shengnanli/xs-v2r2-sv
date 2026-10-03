// xs_ChiselQueue1_core.sv —— 单项 chisel3.util.Queue（entries = 1）的控制 + 存储
//
// 共享辅助件（不对应任何 golden 模块）。深度为 1 时 firtool 不生成读写指针，也不例化 ram_* 存储叶子，
// 只剩一个 full 标志和一个装整条 Bundle 的寄存器 ram —— 所以它和 xs_ChiselQueue_core（多项、指针 + ram 叶子）
// 的寄存器集合根本不同，单独成核。字段怎么拼进 ram 由各变体薄文件决定（照 golden 的拼接）。
//
// 语义（chisel3 Queue，entries=1）：
//   * enq_ready = !full；PIPE=1 时队满也能收，只要本拍出队方接走（io_deq_ready）——"边出边进"。
//   * deq_valid = full（本核不支持 flow）。
//   * 入队时整字写入 ram；full 在"只进不出"时置 1、"只出不进"时清 0。
//   * ram 不复位（golden 就是 `always @(posedge clock) if (do_enq) ram <= ...`），full 异步复位。

module xs_ChiselQueue1_core #(
  parameter int unsigned W    = 1,
  parameter bit          PIPE = 1'b0
)(
  input  logic         clock,
  input  logic         reset,
  input  logic         enq_valid,
  output logic         enq_ready,
  input  logic [W-1:0] enq_word,
  output logic         deq_valid,
  input  logic         deq_ready,
  output logic [W-1:0] deq_word
);

  logic         full;
  logic [W-1:0] ram;
  logic         do_enq, do_deq;

  assign enq_ready = PIPE ? (deq_ready | ~full) : ~full;
  assign deq_valid = full;
  assign do_enq    = enq_ready & enq_valid;
  assign do_deq    = deq_ready & full;
  assign deq_word  = ram;

  always_ff @(posedge clock) begin
    if (do_enq) ram <= enq_word;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      full <= 1'b0;
    else if (do_enq != do_deq)
      full <= do_enq;
  end

endmodule
