// xs_ChiselQueue_core.sv —— chisel3.util.Queue 的控制部分（指针 / 空满 / 握手 / 计数）
//
// 共享辅助件（不对应任何 golden 模块）：firtool 把每个 `Queue(gen, entries, flow)` 单态化成
// 一个 Queue<N>_<Bundle> 模块，里面一律是同一套控制逻辑 + 一块 ram_<D>x<W> 行为级存储。
// 各单态化只差三件事：深度、flow 开关、以及 Bundle 字段怎么拼进 ram 的一个字。
// 本核只管控制；ram 由各变体薄文件直接例化 golden 的 ram_<D>x<W>（firtool 行为级存储叶子，
// 两侧同源 inline elaborate，见 verif/vendor_boundary.tsv 的 codex 0151 D60 裁定），
// 字段拼接/拆分也在薄文件里（那是纯连线）。
//
// 语义（chisel3 Queue.scala，pipe=false、useSyncReadMem=false）：
//   * 环形缓冲：enq_ptr 指向下一个写入槽，deq_ptr 指向队头；两者相等时靠 maybe_full
//     区分空（maybe_full=0）与满（=1）。maybe_full 在"只进不出"那拍置 1、"只出不进"那拍清 0。
//   * 深度是 2 的幂时指针自然回绕；否则在 DEPTH-1 处显式回 0。
//   * enq_ready = !full，deq_valid = !empty，do_enq/do_deq 即两侧 fire。
//   * flow=1（直通）：队列空时入队数据当拍就能出队——deq_valid 也看 enq_valid，
//     薄文件在 empty 时把 enq 数据直接送到 deq；这时若出队方也接走了，就**不**写入
//     也**不**移动读指针（do_enq/do_deq 都被压掉），相当于数据从旁路穿过。
//   * count：2 的幂深度 = {maybe_full & ptr_match, enq_ptr - deq_ptr}；否则
//     ptr_match ? (maybe_full ? DEPTH : 0) : (deq_ptr > enq_ptr ? DEPTH + diff : diff)。

module xs_ChiselQueue_core #(
  parameter int unsigned DEPTH = 16,
  parameter bit          FLOW  = 1'b0,
  localparam int unsigned PTR_W = (DEPTH > 1) ? $clog2(DEPTH) : 1,
  localparam int unsigned CNT_W = $clog2(DEPTH + 1)
)(
  input  logic             clock,
  input  logic             reset,
  input  logic             enq_valid,
  output logic             enq_ready,
  output logic             deq_valid,
  input  logic             deq_ready,
  // 给薄文件用：ram 的读写地址 / 写使能，以及 flow 旁路选择
  output logic             do_enq,
  output logic [PTR_W-1:0] enq_ptr,
  output logic [PTR_W-1:0] deq_ptr,
  output logic             empty,
  output logic [CNT_W-1:0] count
);

  localparam bit POW2 = (DEPTH & (DEPTH - 1)) == 0;

  logic maybe_full;
  logic ptr_match, full, do_deq;

  assign ptr_match = (enq_ptr == deq_ptr);
  assign empty     = ptr_match & ~maybe_full;
  assign full      = ptr_match &  maybe_full;

  // ---- 握手 ----
  assign enq_ready = ~full;
  if (FLOW) begin : g_flow
    // 空队列时入队直通：出队侧看得到 enq_valid；直通那拍不写 ram、不动读指针
    assign deq_valid = enq_valid | ~empty;
    assign do_enq    = enq_valid & enq_ready & ~(empty & deq_ready);
    assign do_deq    = deq_ready & deq_valid & ~empty;
  end else begin : g_noflow
    assign deq_valid = ~empty;
    assign do_enq    = enq_valid & enq_ready;
    assign do_deq    = deq_ready & deq_valid;
  end

  // ---- 指针与空满标志（异步复位）----
  function automatic logic [PTR_W-1:0] next_ptr(input logic [PTR_W-1:0] p);
    if (!POW2 && p == PTR_W'(DEPTH - 1)) return '0;
    return PTR_W'(p + 1'b1);
  endfunction

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      enq_ptr    <= '0;
      deq_ptr    <= '0;
      maybe_full <= 1'b0;
    end else begin
      if (do_enq) enq_ptr <= next_ptr(enq_ptr);
      if (do_deq) deq_ptr <= next_ptr(deq_ptr);
      if (do_enq != do_deq) maybe_full <= do_enq;
    end
  end

  // ---- 元素个数 ----
  logic [PTR_W-1:0] ptr_diff;
  assign ptr_diff = PTR_W'(enq_ptr - deq_ptr);
  if (POW2) begin : g_cnt_pow2
    assign count = {maybe_full & ptr_match, ptr_diff};
  end else begin : g_cnt_npow2
    assign count = ptr_match ? (maybe_full ? CNT_W'(DEPTH) : '0)
                 : (deq_ptr > enq_ptr) ? CNT_W'(DEPTH + ptr_diff) : CNT_W'(ptr_diff);
  end

endmodule
