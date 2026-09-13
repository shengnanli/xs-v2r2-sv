// 自动生成：scripts/gen_pc_wrappers.py —— 勿手改
// 本文件只做端口适配与直通，不含逻辑。
// 端口规模：13 输入 / 9 输出。

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module NewPipelineConnectPipe_25(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  io_in_bits_sqIdx_flag,
  input  [5:0] io_in_bits_sqIdx_value,
  input  io_out_ready,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output io_out_bits_sqIdx_flag,
  output [5:0] io_out_bits_sqIdx_value,
  input  io_rightOutFire,
  input  io_isFlush
);
  // G1 锚点：golden NewPipelineConnectPipe_25 的 io_in_bits_* 端口位数之和（机器可查，
  // 由 golden 端口表逐行累加得到），传给核做防呆；核里是 elaborate 期 $fatal。
  localparam int unsigned PAYLOAD_W_G1 = 124;
  // 入口打包位数从**端口本身**求得：哪个端口位数被抄错，这里就跟着变，和锚点一比就炸。
  localparam int unsigned PAYLOAD_W = $bits({
    io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_robIdx_flag,
    io_in_bits_robIdx_value, io_in_bits_sqIdx_flag, io_in_bits_sqIdx_value});

  wire [PAYLOAD_W-1:0] out_bus;
  assign io_out_bits_fuType = out_bus[123:89];
  assign io_out_bits_fuOpType = out_bus[88:80];
  assign io_out_bits_src_0 = out_bus[79:16];
  assign io_out_bits_robIdx_flag = out_bus[15:15];
  assign io_out_bits_robIdx_value = out_bus[14:7];
  assign io_out_bits_sqIdx_flag = out_bus[6:6];
  assign io_out_bits_sqIdx_value = out_bus[5:0];
  xs_PipelineConnect #(.DATA_WIDTH(PAYLOAD_W), .PAYLOAD_W_G1(PAYLOAD_W_G1)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_sqIdx_flag, io_in_bits_sqIdx_value}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule
