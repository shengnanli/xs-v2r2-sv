// =============================================================================
// xs_DelayQueue_core —— BOP（Best-Offset 预取器）的"延迟队列"参数化核
//
// 位置：L2 的 BestOffsetPrefetch 里，训练地址写 Recent-Requests 表（RR table）之前
//   先在这里排队等一段时间。BOP 的想法是"如果 X-d 在不久前被访问过，那么当时
//   预取 X 就来得及"，所以 RR 表里记的应当是"已经过了一次预取时延"的地址 ——
//   本队列就是那段人为的时延（默认 300 拍，可由 CSR 的 pfCtrl 字段覆盖）。
//
// 输入输出：
//   in_valid/in_addr   入队请求，地址已去掉块内偏移（noOffsetAddr）；队列永远 ready，
//                      满了就把新请求丢掉（golden 没有 io_in_ready 端口）。
//   out_valid/out_addr 队头条目倒计时归零后有效；out_addr = {地址, OFFSET_BITS 个 0}。
//   latency_ctrl       非 0 时作为入队条目的倒计时初值，0 则用 DEFAULT_LATENCY。
//
// 核心机制：16 项环形 FIFO（head/tail 指针，不带回绕位），每项 {addr, cnt}。
//   每项的 cnt 每拍自减到 0 为止；队头 cnt==0 且有效时才允许出队。
//
// 怪癖（照 golden，bug-for-bug）：
//   1. 空/满只看**最后一项**的有效位：empty = head==tail && !valid[N-1]，
//      full = head==tail && valid[N-1]。指针相等时队列要么全空要么全满，
//      所以看哪一项都一样 —— Chisel 取了 valids.last。
//   2. cnt 的"自减"优先于"入队写初值"（Chisel 里自减的 when 写在后面，后连接者赢）。
//      只有 cnt 已经为 0 的槽被入队时才装入新的倒计时；正常情况下被入队的槽是空槽，
//      其 cnt 早已减到 0，两者不冲突。
//   3. 全部寄存器（含地址载荷）异步复位清零。
// =============================================================================

module xs_DelayQueue_core #(
  parameter int unsigned ADDR_W          = 42,   // 去掉块内偏移后的地址宽度
  parameter int unsigned OFFSET_BITS     = 6,    // 块内偏移位数（输出时补 0）
  parameter int unsigned ENTRIES         = 16,
  parameter int unsigned CNT_W           = 10,
  parameter int unsigned DEFAULT_LATENCY = 300
) (
  input  logic                          clock,
  input  logic                          reset,
  input  logic [CNT_W-1:0]              latency_ctrl,
  input  logic                          in_valid,
  input  logic [ADDR_W-1:0]             in_addr,
  input  logic                          out_ready,
  output logic                          out_valid,
  output logic [ADDR_W+OFFSET_BITS-1:0] out_addr
);

  localparam int unsigned IDX_W = $clog2(ENTRIES);

  // ---------------------------------------------------------------------------
  // 状态：条目按字段分开存（与 golden 的扁平寄存器一一对应）
  // ---------------------------------------------------------------------------
  logic [ADDR_W-1:0] queue_addr  [ENTRIES];
  logic [CNT_W-1:0]  queue_cnt   [ENTRIES];
  logic              queue_valid [ENTRIES];
  logic [IDX_W-1:0]  head;
  logic [IDX_W-1:0]  tail;

  // ---------------------------------------------------------------------------
  // 空满判断与出入队握手
  // ---------------------------------------------------------------------------
  logic ptr_equal;
  logic empty;
  logic full;
  logic enq_fire;
  logic deq_fire;
  logic [CNT_W-1:0] enq_latency;

  assign ptr_equal = (head == tail);
  assign empty     = ptr_equal & ~queue_valid[ENTRIES-1];
  assign full      = ptr_equal &  queue_valid[ENTRIES-1];

  assign out_valid = ~empty & (queue_cnt[head] == '0) & queue_valid[head];
  assign out_addr  = {queue_addr[head], {OFFSET_BITS{1'b0}}};

  assign enq_fire    = in_valid & ~full;
  assign deq_fire    = out_valid & out_ready;
  assign enq_latency = (latency_ctrl != '0) ? latency_ctrl : CNT_W'(DEFAULT_LATENCY);

  // ---------------------------------------------------------------------------
  // 条目更新
  // ---------------------------------------------------------------------------
  for (genvar i = 0; i < ENTRIES; i++) begin : g_entry
    logic enq_here;
    logic deq_here;
    assign enq_here = enq_fire & (tail == IDX_W'(i));
    assign deq_here = deq_fire & (head == IDX_W'(i));

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        queue_addr[i]  <= '0;
        queue_cnt[i]   <= '0;
        queue_valid[i] <= 1'b0;
      end else begin
        if (enq_here) queue_addr[i] <= in_addr;
        // 自减优先于装入（怪癖 2）
        if (queue_cnt[i] != '0) queue_cnt[i] <= queue_cnt[i] - 1'b1;
        else if (enq_here)      queue_cnt[i] <= enq_latency;
        // 出队清除优先于入队置位
        queue_valid[i] <= ~deq_here & (enq_here | queue_valid[i]);
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 指针
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      head <= '0;
      tail <= '0;
    end else begin
      if (deq_fire) head <= head + 1'b1;
      if (enq_fire) tail <= tail + 1'b1;
    end
  end

endmodule
