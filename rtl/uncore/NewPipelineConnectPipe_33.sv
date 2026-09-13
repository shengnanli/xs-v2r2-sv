// NewPipelineConnectPipe_33 —— NewPipelineConnectPipe_25 单态化变体 wrapper（核体见 rtl/common/PipelineConnect.sv 的 xs_PipelineConnect）
// 位置：MemBlock 向量访存流水的一级 PipelineConnect；本文件只做端口适配与直通，不含逻辑。
// 本变体规模：17 端口（10 输入 / 7 输出），payload 243 位 =
//   vaddr(50) + data(128) + mask(16) + addr(48) + vecValid(1)；isFlush 恒 0。
// G1 重编号：G0 里这个变体叫 NewPipelineConnectPipe_31，G1 改叫 _33；golden 模块体
// 逐字节相同（仅自名不同），故本文件是上一轮 wrapper 的原样继承 + 改名。
// 注意 G0 的 NewPipelineConnectPipe_33 是另一个 96 端口的变体，与本文件无关。

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
