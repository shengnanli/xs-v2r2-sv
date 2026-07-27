// PrefetchQueue_xs (UT 变体, 例化可读核 xs_PrefetchQueue_core)
module PrefetchQueue_xs(
  input         clock,
  input         reset,
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
  xs_PrefetchQueue_core u_core (
    .clock                (clock),
    .reset                (reset),
    .io_enq_valid         (io_enq_valid),
    .io_enq_bits_tag      (io_enq_bits_tag),
    .io_enq_bits_set      (io_enq_bits_set),
    .io_enq_bits_vaddr    (io_enq_bits_vaddr),
    .io_enq_bits_needT    (io_enq_bits_needT),
    .io_enq_bits_source   (io_enq_bits_source),
    .io_enq_bits_pfSource (io_enq_bits_pfSource),
    .io_deq_ready         (io_deq_ready),
    .io_deq_valid         (io_deq_valid),
    .io_deq_bits_tag      (io_deq_bits_tag),
    .io_deq_bits_set      (io_deq_bits_set),
    .io_deq_bits_vaddr    (io_deq_bits_vaddr),
    .io_deq_bits_needT    (io_deq_bits_needT),
    .io_deq_bits_source   (io_deq_bits_source),
    .io_deq_bits_pfSource  (io_deq_bits_pfSource)
  );
endmodule
