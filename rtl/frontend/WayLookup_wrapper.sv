// WayLookup 包装层（golden 同名扁平端口 ↔ xs_WayLookup 的 struct 端口）
// 仅做机械的端口打包/拆包，供 FM 对比与 ST 替换。
module WayLookup
  import xs_waylookup_pkg::*;
(
  input         clock,
  input         reset,
  input         io_flush,
  input         io_read_ready,
  output        io_read_valid,
  output [7:0]  io_read_bits_entry_vSetIdx_0,
  output [7:0]  io_read_bits_entry_vSetIdx_1,
  output [3:0]  io_read_bits_entry_waymask_0,
  output [3:0]  io_read_bits_entry_waymask_1,
  output [35:0] io_read_bits_entry_ptag_0,
  output [35:0] io_read_bits_entry_ptag_1,
  output [1:0]  io_read_bits_entry_itlb_exception_0,
  output [1:0]  io_read_bits_entry_itlb_exception_1,
  output [1:0]  io_read_bits_entry_itlb_pbmt_0,
  output [1:0]  io_read_bits_entry_itlb_pbmt_1,
  output        io_read_bits_entry_meta_codes_0,
  output        io_read_bits_entry_meta_codes_1,
  output [55:0] io_read_bits_gpf_gpaddr,
  output        io_read_bits_gpf_isForVSnonLeafPTE,
  output        io_write_ready,
  input         io_write_valid,
  input  [7:0]  io_write_bits_entry_vSetIdx_0,
  input  [7:0]  io_write_bits_entry_vSetIdx_1,
  input  [3:0]  io_write_bits_entry_waymask_0,
  input  [3:0]  io_write_bits_entry_waymask_1,
  input  [35:0] io_write_bits_entry_ptag_0,
  input  [35:0] io_write_bits_entry_ptag_1,
  input  [1:0]  io_write_bits_entry_itlb_exception_0,
  input  [1:0]  io_write_bits_entry_itlb_exception_1,
  input  [1:0]  io_write_bits_entry_itlb_pbmt_0,
  input  [1:0]  io_write_bits_entry_itlb_pbmt_1,
  input         io_write_bits_entry_meta_codes_0,
  input         io_write_bits_entry_meta_codes_1,
  input  [55:0] io_write_bits_gpf_gpaddr,
  input         io_write_bits_gpf_isForVSnonLeafPTE,
  input         io_update_valid,
  input  [41:0] io_update_bits_blkPaddr,
  input  [7:0]  io_update_bits_vSetIdx,
  input  [3:0]  io_update_bits_waymask,
  input         io_update_bits_corrupt
);
  // flat → struct（write）
  way_lookup_entry_t write_entry;
  way_lookup_gpf_t   write_gpf;
  assign write_entry.port[0].vSetIdx        = io_write_bits_entry_vSetIdx_0;
  assign write_entry.port[0].waymask        = io_write_bits_entry_waymask_0;
  assign write_entry.port[0].ptag           = io_write_bits_entry_ptag_0;
  assign write_entry.port[0].itlb_exception = io_write_bits_entry_itlb_exception_0;
  assign write_entry.port[0].itlb_pbmt      = io_write_bits_entry_itlb_pbmt_0;
  assign write_entry.port[0].meta_codes     = io_write_bits_entry_meta_codes_0;
  assign write_entry.port[1].vSetIdx        = io_write_bits_entry_vSetIdx_1;
  assign write_entry.port[1].waymask        = io_write_bits_entry_waymask_1;
  assign write_entry.port[1].ptag           = io_write_bits_entry_ptag_1;
  assign write_entry.port[1].itlb_exception = io_write_bits_entry_itlb_exception_1;
  assign write_entry.port[1].itlb_pbmt      = io_write_bits_entry_itlb_pbmt_1;
  assign write_entry.port[1].meta_codes     = io_write_bits_entry_meta_codes_1;
  assign write_gpf.gpaddr                   = io_write_bits_gpf_gpaddr;
  assign write_gpf.isForVSnonLeafPTE        = io_write_bits_gpf_isForVSnonLeafPTE;

  way_lookup_entry_t read_entry;
  way_lookup_gpf_t   read_gpf;

  xs_WayLookup u_core (
    .clock(clock), .reset(reset), .io_flush(io_flush),
    .io_read_ready(io_read_ready), .io_read_valid(io_read_valid),
    .io_read_bits_entry(read_entry), .io_read_bits_gpf(read_gpf),
    .io_write_ready(io_write_ready), .io_write_valid(io_write_valid),
    .io_write_bits_entry(write_entry), .io_write_bits_gpf(write_gpf),
    .io_update_valid(io_update_valid), .io_update_bits_blkPaddr(io_update_bits_blkPaddr),
    .io_update_bits_vSetIdx(io_update_bits_vSetIdx), .io_update_bits_waymask(io_update_bits_waymask),
    .io_update_bits_corrupt(io_update_bits_corrupt)
  );

  // struct → flat（read）
  assign io_read_bits_entry_vSetIdx_0        = read_entry.port[0].vSetIdx;
  assign io_read_bits_entry_waymask_0        = read_entry.port[0].waymask;
  assign io_read_bits_entry_ptag_0           = read_entry.port[0].ptag;
  assign io_read_bits_entry_itlb_exception_0 = read_entry.port[0].itlb_exception;
  assign io_read_bits_entry_itlb_pbmt_0      = read_entry.port[0].itlb_pbmt;
  assign io_read_bits_entry_meta_codes_0     = read_entry.port[0].meta_codes;
  assign io_read_bits_entry_vSetIdx_1        = read_entry.port[1].vSetIdx;
  assign io_read_bits_entry_waymask_1        = read_entry.port[1].waymask;
  assign io_read_bits_entry_ptag_1           = read_entry.port[1].ptag;
  assign io_read_bits_entry_itlb_exception_1 = read_entry.port[1].itlb_exception;
  assign io_read_bits_entry_itlb_pbmt_1      = read_entry.port[1].itlb_pbmt;
  assign io_read_bits_entry_meta_codes_1     = read_entry.port[1].meta_codes;
  assign io_read_bits_gpf_gpaddr             = read_gpf.gpaddr;
  assign io_read_bits_gpf_isForVSnonLeafPTE  = read_gpf.isForVSnonLeafPTE;
endmodule
