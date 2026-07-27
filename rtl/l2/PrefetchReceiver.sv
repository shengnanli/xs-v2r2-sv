// PrefetchReceiver —— 手写可读实现(TL2 shard D, AUX signoff)。
//
// 功能: 把外部 receiver 接口(io_recv_addr)的物理地址翻译成 L2 预取请求
// (io_req)的 {tag,set} 划分, 并用 io_enable 做门控。纯组合逻辑, 无状态。
//
// 地址位划分(64b 物理地址):
//   [47:15] -> tag  (33 位)
//   [14:6]  -> set  (9 位, cacheline set index)
//   [5:0]   -> block offset(丢弃)
// pfSource 原样透传。req.valid = enable 与 recv.valid 相与。
//
// 本文件定义可读核 xs_PrefetchReceiver_core。golden 同名扁平端口包装在
// rtl/l2/PrefetchReceiver_wrapper.sv(仅 FM impl 侧例化本核)。
module xs_PrefetchReceiver_core(
  output        io_req_valid,
  output [32:0] io_req_bits_tag,
  output [8:0]  io_req_bits_set,
  output [4:0]  io_req_bits_pfSource,
  input         io_recv_addr_valid,
  input  [63:0] io_recv_addr_bits_addr,
  input  [4:0]  io_recv_addr_bits_pfSource,
  input         io_enable
);

  assign io_req_valid        = io_enable & io_recv_addr_valid;
  assign io_req_bits_tag      = io_recv_addr_bits_addr[47:15];
  assign io_req_bits_set      = io_recv_addr_bits_addr[14:6];
  assign io_req_bits_pfSource = io_recv_addr_bits_pfSource;

endmodule
