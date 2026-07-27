// 自动生成: gen_tb_shardD.py —— PrefetchReceiver_xs (UT 变体, 例化可读核 xs_PrefetchReceiver_core)
module PrefetchReceiver_xs(
  output io_req_valid,
  output [32:0] io_req_bits_tag,
  output [8:0] io_req_bits_set,
  output [4:0] io_req_bits_pfSource,
  input io_recv_addr_valid,
  input [63:0] io_recv_addr_bits_addr,
  input [4:0] io_recv_addr_bits_pfSource,
  input io_enable
);
  xs_PrefetchReceiver_core u_core (
    .io_req_valid(io_req_valid),
    .io_req_bits_tag(io_req_bits_tag),
    .io_req_bits_set(io_req_bits_set),
    .io_req_bits_pfSource(io_req_bits_pfSource),
    .io_recv_addr_valid(io_recv_addr_valid),
    .io_recv_addr_bits_addr(io_recv_addr_bits_addr),
    .io_recv_addr_bits_pfSource(io_recv_addr_bits_pfSource),
    .io_enable(io_enable)
  );
endmodule
