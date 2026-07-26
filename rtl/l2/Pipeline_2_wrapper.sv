// Pipeline_2 包装层(golden 同名扁平端口 ↔ xs_Pipeline_2_core)。
// 端口逐一直连(golden 端口已是扁平标量), 仅供 FM impl 侧与 ST 替换。
module Pipeline_2(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [32:0] io_in_bits_tag,
  input  [8:0]  io_in_bits_set,
  input         io_in_bits_needT,
  input  [6:0]  io_in_bits_source,
  input  [43:0] io_in_bits_vaddr,
  input         io_in_bits_hit,
  input         io_in_bits_prefetched,
  input  [2:0]  io_in_bits_pfsource,
  input  [4:0]  io_in_bits_reqsource,
  input         io_out_ready,
  output        io_out_valid,
  output [32:0] io_out_bits_tag,
  output [8:0]  io_out_bits_set,
  output        io_out_bits_needT,
  output [6:0]  io_out_bits_source,
  output [43:0] io_out_bits_vaddr,
  output [4:0]  io_out_bits_reqsource
);

  xs_Pipeline_2_core u_core (
    .clock                 (clock),
    .reset                 (reset),
    .io_in_ready           (io_in_ready),
    .io_in_valid           (io_in_valid),
    .io_in_bits_tag        (io_in_bits_tag),
    .io_in_bits_set        (io_in_bits_set),
    .io_in_bits_needT      (io_in_bits_needT),
    .io_in_bits_source     (io_in_bits_source),
    .io_in_bits_vaddr      (io_in_bits_vaddr),
    .io_in_bits_hit        (io_in_bits_hit),
    .io_in_bits_prefetched (io_in_bits_prefetched),
    .io_in_bits_pfsource   (io_in_bits_pfsource),
    .io_in_bits_reqsource  (io_in_bits_reqsource),
    .io_out_ready          (io_out_ready),
    .io_out_valid          (io_out_valid),
    .io_out_bits_tag       (io_out_bits_tag),
    .io_out_bits_set       (io_out_bits_set),
    .io_out_bits_needT     (io_out_bits_needT),
    .io_out_bits_source    (io_out_bits_source),
    .io_out_bits_vaddr     (io_out_bits_vaddr),
    .io_out_bits_reqsource (io_out_bits_reqsource)
  );

endmodule
