// NewPipelineConnectPipe_33 —— VSegmentUnit 的段访存请求缓冲级（本家族的一个单态化变体）
// 例化点（G1 golden）：VSegmentUnit.VSegmentUnitPipelineConnect，全设计仅此一处。
// 本变体参数：DATA_WIDTH=243，payload = {vaddr[49:0], data[127:0], mask[15:0],
//   addr[47:0], vecValid}；**无 io_isFlush 端口**（Chisel 侧该处没接 flush，
//   firtool 把常量 0 折进去了），故核体的 io_isFlush 在这里恒接 1'b0。
// 端口规模：10 输入 / 7 输出，共 17 端口。握手/寄存语义见核体 rtl/common/PipelineConnect.sv。
//
// ★名字警告★：G0(v2r2) 里叫 NewPipelineConnectPipe_33 的是另一个模块（96 端口，
// MemBlock 的 4 个向量拆分连接），那个在 G1 里叫 NewPipelineConnectPipe_35。
// 本文件的内容在 G0 里的名字是 NewPipelineConnectPipe_31。
// 判据：例化点 + 模块体归一化后逐字相等，见 scripts/check_name_collisions.py。

module NewPipelineConnectPipe_33(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [49:0] io_in_bits_vaddr,
  input  [127:0] io_in_bits_data,
  input  [15:0] io_in_bits_mask,
  input  [47:0] io_in_bits_addr,
  input  io_in_bits_vecValid,
  input  io_out_ready,
  output io_out_valid,
  output [49:0] io_out_bits_vaddr,
  output [127:0] io_out_bits_data,
  output [15:0] io_out_bits_mask,
  output [47:0] io_out_bits_addr,
  output io_out_bits_vecValid,
  input  io_rightOutFire
);
  wire [242:0] out_bus;
  assign io_out_bits_vaddr = out_bus[242:193];
  assign io_out_bits_data = out_bus[192:65];
  assign io_out_bits_mask = out_bus[64:49];
  assign io_out_bits_addr = out_bus[48:1];
  assign io_out_bits_vecValid = out_bus[0:0];
  xs_PipelineConnect #(.DATA_WIDTH(243)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_vaddr, io_in_bits_data, io_in_bits_mask, io_in_bits_addr, io_in_bits_vecValid}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(1'b0)
  );
endmodule
