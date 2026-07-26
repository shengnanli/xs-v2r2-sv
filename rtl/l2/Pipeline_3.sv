// Pipeline_3 —— 手写可读实现(TL2 shard 4, AUX signoff)。
//
// L2 预取响应的一级流水缓冲: 单纯例化一个深度 1 的 skid-buffer 队列
// (xs_Queue1_PrefetchResp_core), enq/deq 端口原样转发。golden 里 stages_0
// 例化 Queue1_PrefetchResp, 本实现例化可读同构核 xs_Queue1_PrefetchResp_core。
//
// 本文件定义可读核 xs_Pipeline_3_core + 深度1队列核 xs_Queue1_PrefetchResp_core。
// golden 同名扁平端口包装在 rtl/l2/Pipeline_3_wrapper.sv(仅 FM impl 侧例化本核)。
module xs_Pipeline_3_core(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [32:0] io_in_bits_tag,
  input  [8:0]  io_in_bits_set,
  input  [43:0] io_in_bits_vaddr,
  input  [4:0]  io_in_bits_pfSource,
  input         io_out_ready,
  output        io_out_valid,
  output [4:0]  io_out_bits_pfSource
);

  xs_Queue1_PrefetchResp_core stages_0 (
    .clock                (clock),
    .reset                (reset),
    .io_enq_ready         (io_in_ready),
    .io_enq_valid         (io_in_valid),
    .io_enq_bits_tag      (io_in_bits_tag),
    .io_enq_bits_set      (io_in_bits_set),
    .io_enq_bits_vaddr    (io_in_bits_vaddr),
    .io_enq_bits_pfSource (io_in_bits_pfSource),
    .io_deq_ready         (io_out_ready),
    .io_deq_valid         (io_out_valid),
    .io_deq_bits_pfSource (io_out_bits_pfSource)
  );

endmodule

// xs_Queue1_PrefetchResp_core —— 深度 1 skid-buffer 队列可读核(flow=false)。
//
// 语义(与 golden Queue1_PrefetchResp 逐位一致):
//   - full: 当前是否驻留一拍数据(异步 reset 清 0)。
//   - enq_ready = deq_ready | ~full。
//   - do_enq    = enq_ready & enq_valid。
//   - ram(91b): do_enq 时锁存整个入队载荷(同步写, 无 reset)。载荷打包顺序与 golden
//               完全一致: {pfSource[4:0], vaddr[43:0], set[8:0], tag[32:0]}。
//   - full 更新: 仅当 do_enq != (deq_ready & full) 时改变, 取值 do_enq。
//   - deq_valid = full; deq 仅读回 pfSource=ram[90:86]。
//
// 死位说明: ram 低 86 位(tag/set/vaddr)被写入但 deq 从不读出——这是 golden 本身的
// 行为(Chisel Queue 存整个 bundle, 但本模块 deq 端口只暴露 pfSource)。impl 逐位复刻
// golden 的 ram 打包与 deq 切片, 故两侧同一组 "写而不读" 位对称等价(golden-side
// cone-dead 双射), 非 impl 独有死寄存器。
module xs_Queue1_PrefetchResp_core(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input  [32:0] io_enq_bits_tag,
  input  [8:0]  io_enq_bits_set,
  input  [43:0] io_enq_bits_vaddr,
  input  [4:0]  io_enq_bits_pfSource,
  input         io_deq_ready,
  output        io_deq_valid,
  output [4:0]  io_deq_bits_pfSource
);

  reg  [90:0] ram;
  reg         full;

  wire io_enq_ready_0 = io_deq_ready | ~full;
  wire do_enq         = io_enq_ready_0 & io_enq_valid;

  always @(posedge clock) begin
    if (do_enq)
      ram <= {io_enq_bits_pfSource,
              io_enq_bits_vaddr,
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
  assign io_deq_bits_pfSource = ram[90:86];

endmodule
