// StorePfWrapper FM 包装：端口与 golden StorePfWrapper 完全一致。
// 可读核只承担 wrapper 连接语义；Serializer / StorePrefetchBursts 复用 golden 子模块，
// 作为 UT 与 FM 两侧共享黑盒。
module StorePfWrapper
  import storepfwrapper_pkg::*;
(
  input         clock,
  input         reset,
  output [49:0] io_prefetch_req_0_bits_vaddr,
  output [49:0] io_prefetch_req_1_bits_vaddr
);

  logic [VADDR_BITS-1:0] spb_prefetch_vaddr [PREFETCH_REQ_LANES];
  logic [VADDR_BITS-1:0] core_prefetch_vaddr [PREFETCH_REQ_LANES];

  // 当前配置下 Serializer 已被常量传播到只有内部指针寄存器，仍保留例化以对应 Scala
  // “多路 store 先串行化”的结构边界。
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
