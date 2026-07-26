// =============================================================================
//  Queue1_PrefetchTrain —— 深度 1 队列 (flow=false, L2 预取训练信息)  可读实现
// -----------------------------------------------------------------------------
//  对应 Chisel `Queue(entries=1, flow=false)`。io_deq_valid = full (无空直通)。
//  enq 打包 9 个字段进 104 位 ram; deq 只读回 tag/set/needT/source/vaddr/reqsource 6
//  个字段, 其余 (hit/prefetched/pfsource) 写入 ram 但不被 deq 读出 —— 与 golden 完全
//  一致 (golden 的 ram 亦为单个 104 位寄存器, 同样存写这些位而 deq 不读)。故本核逐位
//  复刻 golden ram 打包顺序与 deq 切片, 两侧 ram 的 "写但不读" 位对称等价。
// =============================================================================
module xs_Queue1_PrefetchTrain_core (
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input  [32:0] io_enq_bits_tag,
  input  [8:0]  io_enq_bits_set,
  input         io_enq_bits_needT,
  input  [6:0]  io_enq_bits_source,
  input  [43:0] io_enq_bits_vaddr,
  input         io_enq_bits_hit,
  input         io_enq_bits_prefetched,
  input  [2:0]  io_enq_bits_pfsource,
  input  [4:0]  io_enq_bits_reqsource,
  input         io_deq_ready,
  output        io_deq_valid,
  output [32:0] io_deq_bits_tag,
  output [8:0]  io_deq_bits_set,
  output        io_deq_bits_needT,
  output [6:0]  io_deq_bits_source,
  output [43:0] io_deq_bits_vaddr,
  output [4:0]  io_deq_bits_reqsource
);

  reg  [103:0] ram;
  reg          full;

  wire io_enq_ready_0 = io_deq_ready | ~full;
  wire do_enq = io_enq_ready_0 & io_enq_valid;

  always @(posedge clock) begin
    if (do_enq)
      ram <= {io_enq_bits_reqsource,
              io_enq_bits_pfsource,
              io_enq_bits_prefetched,
              io_enq_bits_hit,
              io_enq_bits_vaddr,
              io_enq_bits_source,
              io_enq_bits_needT,
              io_enq_bits_set,
              io_enq_bits_tag};
  end
  always @(posedge clock or posedge reset) begin
    if (reset)
      full <= 1'h0;
    else if (~(do_enq == (io_deq_ready & full)))
      full <= do_enq;
  end

  assign io_enq_ready         = io_enq_ready_0;
  assign io_deq_valid         = full;
  assign io_deq_bits_tag       = ram[32:0];
  assign io_deq_bits_set       = ram[41:33];
  assign io_deq_bits_needT     = ram[42];
  assign io_deq_bits_source    = ram[49:43];
  assign io_deq_bits_vaddr     = ram[93:50];
  assign io_deq_bits_reqsource = ram[103:99];
endmodule
