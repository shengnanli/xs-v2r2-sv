// Pipeline_1 —— 手写可读实现(TL2 shard D, AUX signoff)。
//
// L2 预取请求的一级流水缓冲: 单纯例化一个深度 1 的 skid-buffer 队列
// (xs_Queue1_PrefetchReq_core), enq/deq 端口原样转发。golden 里 stages_0
// 例化 Queue1_PrefetchReq, 本实现例化可读同构核 xs_Queue1_PrefetchReq_core。
//
// 载荷(99 位): {pfSource[4:0], source[6:0], needT, vaddr[43:0], set[8:0], tag[32:0]}。
//
// 本文件定义可读核 xs_Pipeline_1_core + 深度1队列核 xs_Queue1_PrefetchReq_core。
// golden 同名扁平端口包装在 rtl/l2/Pipeline_1_wrapper.sv(仅 FM impl 侧例化本核)。
module xs_Pipeline_1_core(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [32:0] io_in_bits_tag,
  input  [8:0]  io_in_bits_set,
  input  [43:0] io_in_bits_vaddr,
  input         io_in_bits_needT,
  input  [6:0]  io_in_bits_source,
  input  [4:0]  io_in_bits_pfSource,
  input         io_out_ready,
  output        io_out_valid,
  output [32:0] io_out_bits_tag,
  output [8:0]  io_out_bits_set,
  output [43:0] io_out_bits_vaddr,
  output        io_out_bits_needT,
  output [6:0]  io_out_bits_source,
  output [4:0]  io_out_bits_pfSource
);

  xs_Queue1_PrefetchReq_core stages_0 (
    .clock                (clock),
    .reset                (reset),
    .io_enq_ready         (io_in_ready),
    .io_enq_valid         (io_in_valid),
    .io_enq_bits_tag      (io_in_bits_tag),
    .io_enq_bits_set      (io_in_bits_set),
    .io_enq_bits_vaddr    (io_in_bits_vaddr),
    .io_enq_bits_needT    (io_in_bits_needT),
    .io_enq_bits_source   (io_in_bits_source),
    .io_enq_bits_pfSource (io_in_bits_pfSource),
    .io_deq_ready         (io_out_ready),
    .io_deq_valid         (io_out_valid),
    .io_deq_bits_tag      (io_out_bits_tag),
    .io_deq_bits_set      (io_out_bits_set),
    .io_deq_bits_vaddr    (io_out_bits_vaddr),
    .io_deq_bits_needT    (io_out_bits_needT),
    .io_deq_bits_source   (io_out_bits_source),
    .io_deq_bits_pfSource (io_out_bits_pfSource)
  );

endmodule

// xs_Queue1_PrefetchReq_core —— 深度 1 skid-buffer 队列可读核。
//
// 语义(与 golden Queue1_PrefetchReq 逐位一致):
//   - full: 当前是否驻留一拍数据(异步 reset 清 0)。
//   - enq_ready = deq_ready | ~full  (下游要走 或 尚空 时可入)。
//   - do_enq    = enq_ready & enq_valid。
//   - ram(99b): do_enq 时锁存入队载荷(同步写, 无 reset)。
//   - full 更新: 仅当 do_enq != (deq_ready & full) 时改变, 取值 do_enq。
//     即: 入而不出 -> 置满; 出而不入 -> 清空; 同时或都不 -> 保持。
//   - deq_valid = full, deq_bits = ram 各字段切片。
module xs_Queue1_PrefetchReq_core(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input  [32:0] io_enq_bits_tag,
  input  [8:0]  io_enq_bits_set,
  input  [43:0] io_enq_bits_vaddr,
  input         io_enq_bits_needT,
  input  [6:0]  io_enq_bits_source,
  input  [4:0]  io_enq_bits_pfSource,
  input         io_deq_ready,
  output        io_deq_valid,
  output [32:0] io_deq_bits_tag,
  output [8:0]  io_deq_bits_set,
  output [43:0] io_deq_bits_vaddr,
  output        io_deq_bits_needT,
  output [6:0]  io_deq_bits_source,
  output [4:0]  io_deq_bits_pfSource
);

  reg  [98:0] ram;
  reg         full;

  wire enq_ready_int = io_deq_ready | ~full;
  wire do_enq        = enq_ready_int & io_enq_valid;

  always @(posedge clock) begin
    if (do_enq)
      ram <= {io_enq_bits_pfSource,
              io_enq_bits_source,
              io_enq_bits_needT,
              io_enq_bits_vaddr,
              io_enq_bits_set,
              io_enq_bits_tag};
  end

  always @(posedge clock or posedge reset) begin
    if (reset)
      full <= 1'h0;
    else if (do_enq != (io_deq_ready & full))
      full <= do_enq;
  end

  assign io_enq_ready        = enq_ready_int;
  assign io_deq_valid        = full;
  assign io_deq_bits_tag      = ram[32:0];
  assign io_deq_bits_set      = ram[41:33];
  assign io_deq_bits_vaddr    = ram[85:42];
  assign io_deq_bits_needT    = ram[86];
  assign io_deq_bits_source   = ram[93:87];
  assign io_deq_bits_pfSource = ram[98:94];

endmodule
