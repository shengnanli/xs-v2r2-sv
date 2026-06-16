// StorePfWrapper_xs：UT 用实现侧变体，端口与 golden StorePfWrapper 完全一致。
module StorePfWrapper_xs
  import storepfwrapper_pkg::*;
(
  input         clock,
  input         reset,
  output [49:0] io_prefetch_req_0_bits_vaddr,
  output [49:0] io_prefetch_req_1_bits_vaddr
);

  logic [VADDR_BITS-1:0] spb_prefetch_vaddr [PREFETCH_REQ_LANES];
  logic [VADDR_BITS-1:0] core_prefetch_vaddr [PREFETCH_REQ_LANES];

  Serializer serializer (
    .clock(clock),
    .reset(reset)
  );

  StorePrefetchBursts spb (
    .io_prefetch_req_0_bits_vaddr(spb_prefetch_vaddr[0]),
    .io_prefetch_req_1_bits_vaddr(spb_prefetch_vaddr[1])
  );

  xs_StorePfWrapper_core u_core (
    .spb_prefetch_vaddr(spb_prefetch_vaddr),
    .io_prefetch_vaddr (core_prefetch_vaddr)
  );

  assign io_prefetch_req_0_bits_vaddr = core_prefetch_vaddr[0];
  assign io_prefetch_req_1_bits_vaddr = core_prefetch_vaddr[1];
endmodule
