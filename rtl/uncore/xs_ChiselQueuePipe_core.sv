// xs_ChiselQueuePipe_core.sv —— chisel3.util.Queue(pipe = true, flow = false) 的控制部分
//
// 与 rtl/common/xs_ChiselQueue_core.sv 是同一个 chisel Queue，只差一个开关 pipe：
//   pipe=true 时，**队列满但出口这拍正在被接走**的话，入口照样 ready —— 出一个、进一个，
//   满队列也能每拍吞吐一项（chisel：`when (io.deq.ready) { io.enq.ready := true.B }`）。
// 为什么另起一个文件而不是给那个核加 PIPE 参数：那个核已被 16+ 个已签目标共用，改它的字节会让
// 它们全部 STALE 重证（同 rtl/memblock/L2TlbMissQueue.sv 头注的理由）。本核端口与那个核逐名一致，
// 将来若集成者决定合并，薄文件只需换模块名。
// 当前使用者：Queue4_CHISNP（coupledL2 LinkLayer.scala:182 LCredit2Decoupled 的接收缓冲，
//   `Queue(gen, entries = lcreditNum, pipe = true, flow = false)`，lcreditNum = 4）。
//   G1 golden 里同族还有 Queue4_CHIDAT/REQ/RSP、Queue15_CHI*（均未重写）。
//
// 语义（chisel3 Queue.scala，pipe=true、flow=false、useSyncReadMem=false）：
//   * 环形缓冲：enq_ptr 指向下一个写入槽，deq_ptr 指向队头；两者相等时 maybe_full 区分空/满。
//   * enq_ready = !full | deq_ready；deq_valid = !empty；do_enq/do_deq 即两侧 fire。
//     满队列同拍进出时 enq_ptr == deq_ptr：组合读口先读出旧队头，时钟沿再写入新项，互不踩。
//   * maybe_full 在"只进不出"那拍置 1、"只出不进"那拍清 0（同拍进出不变）。
//   * 深度须为 2 的幂（指针自然回绕）；count = {maybe_full & ptr_match, enq_ptr - deq_ptr}。

module xs_ChiselQueuePipe_core #(
  parameter int unsigned DEPTH = 4,
  localparam int unsigned PTR_W = (DEPTH > 1) ? $clog2(DEPTH) : 1,
  localparam int unsigned CNT_W = $clog2(DEPTH + 1)
)(
  input  logic             clock,
  input  logic             reset,
  input  logic             enq_valid,
  output logic             enq_ready,
  output logic             deq_valid,
  input  logic             deq_ready,
  // 给薄文件用：ram 的读写地址 / 写使能
  output logic             do_enq,
  output logic [PTR_W-1:0] enq_ptr,
  output logic [PTR_W-1:0] deq_ptr,
  output logic             empty,
  output logic [CNT_W-1:0] count
);

  // 只支持 2 的幂深度（目前唯一使用者深度 4）；非 2 的幂要显式回绕，届时再加
  if ((DEPTH & (DEPTH - 1)) != 0)
    $fatal(1, "xs_ChiselQueuePipe_core: DEPTH=%0d must be a power of 2", DEPTH);

  logic maybe_full;
  logic ptr_match, full, do_deq;

  assign ptr_match = (enq_ptr == deq_ptr);
  assign empty     = ptr_match & ~maybe_full;
  assign full      = ptr_match &  maybe_full;

  // ---- 握手：pipe —— 满时只要出口在接，入口也放行 ----
  assign enq_ready = deq_ready | ~full;
  assign deq_valid = ~empty;
  assign do_enq    = enq_valid & enq_ready;
  assign do_deq    = deq_ready & deq_valid;

  // ---- 指针与空满标志（异步复位）----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      enq_ptr    <= '0;
      deq_ptr    <= '0;
      maybe_full <= 1'b0;
    end else begin
      if (do_enq) enq_ptr <= PTR_W'(enq_ptr + 1'b1);
      if (do_deq) deq_ptr <= PTR_W'(deq_ptr + 1'b1);
      if (do_enq != do_deq) maybe_full <= do_enq;
    end
  end

  // ---- 元素个数 ----
  assign count = {maybe_full & ptr_match, PTR_W'(enq_ptr - deq_ptr)};

endmodule
