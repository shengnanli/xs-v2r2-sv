// WritebackEntry_15.sv —— WritebackQueue 第 15 号写回表项（WritebackEntry 家族变体）
//
// 本变体参数：io_id 6 位（ID_W=6），C 通道 source = io_id 原样（6 位，不再零扩展）。
// 为什么分成两个模块：WritebackQueue 有 18 个表项，表项 i 的 id = i + releaseIdBase(=nMissEntries+1=17)，
//   即 0x11..0x22。Scala 写的是 `entry.io.id := (i + releaseIdBase).U`，而 io.id 声明为不定宽 UInt()，
//   于是每个表项的端口宽度由这个常数的最小位宽决定：0x11..0x1F 是 5 位（表项 0..14 → WritebackEntry），
//   0x20..0x22 是 6 位（表项 15..17 → 本变体，名字取第一个用到它的表项号）。逻辑完全相同。
// 核 xs_WritebackEntry_core 在 rtl/memblock/WritebackEntry.sv（状态机、拍记账、写入时序讲在那里）。
// golden 275 行 / 25 端口；本文件只是 golden 同名 wrapper。

module WritebackEntry_15 (
  input  logic         clock,
  input  logic         reset,
  input  logic [5:0]   io_id,
  input  logic         io_req_valid,
  input  logic [2:0]   io_req_bits_param,
  input  logic         io_req_bits_voluntary,
  input  logic         io_req_bits_hasData,
  input  logic         io_req_bits_corrupt,
  input  logic         io_req_bits_dirty,
  input  logic [47:0]  io_req_bits_addr,
  input  logic [511:0] io_req_data_data,
  input  logic         io_mem_release_ready,
  output logic         io_mem_release_valid,
  output logic [2:0]   io_mem_release_bits_opcode,
  output logic [2:0]   io_mem_release_bits_param,
  output logic [5:0]   io_mem_release_bits_source,
  output logic [47:0]  io_mem_release_bits_address,
  output logic [255:0] io_mem_release_bits_data,
  output logic         io_mem_release_bits_corrupt,
  input  logic         io_mem_grant_valid,
  input  logic         io_primary_valid,
  output logic         io_primary_ready,
  output logic         io_block_addr_valid,
  output logic [47:0]  io_block_addr_bits
);

  xs_WritebackEntry_core #(.ID_W(6)) u_core (
    .clock            (clock),
    .reset            (reset),
    .entry_id         (io_id),
    .req_valid        (io_req_valid),
    .req_param_in     (io_req_bits_param),
    .req_voluntary_in (io_req_bits_voluntary),
    .req_has_data_in  (io_req_bits_hasData),
    .req_corrupt_in   (io_req_bits_corrupt),
    .req_dirty_in     (io_req_bits_dirty),
    .req_addr_in      (io_req_bits_addr),
    .req_line_data    (io_req_data_data),
    .release_ready    (io_mem_release_ready),
    .release_valid    (io_mem_release_valid),
    .release_opcode   (io_mem_release_bits_opcode),
    .release_param    (io_mem_release_bits_param),
    .release_source   (io_mem_release_bits_source),
    .release_address  (io_mem_release_bits_address),
    .release_data     (io_mem_release_bits_data),
    .release_corrupt  (io_mem_release_bits_corrupt),
    .grant_valid      (io_mem_grant_valid),
    .primary_valid    (io_primary_valid),
    .primary_ready    (io_primary_ready),
    .block_addr_valid (io_block_addr_valid),
    .block_addr       (io_block_addr_bits)
  );

endmodule
