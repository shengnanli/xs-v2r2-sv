// NewPipelineConnectPipe_27 —— CtrlUnit 伪错误(pseudo error)注入请求的缓冲级
// （本家族的一个单态化变体）。
// 例化点（G1 golden）：CtrlUnit.CtrlUnitPseudoErrorPipelineConnect0 / …Connect1。
// 本变体参数：DATA_WIDTH=520，payload = 8 条通道 × {valid, mask[63:0]}，
//   通道 0 在高位、通道 7 在低位；**无 io_isFlush 端口**，核体的 io_isFlush 恒接 1'b0。
// 端口规模：21 输入 / 18 输出，共 39 端口。握手/寄存语义见核体 rtl/common/PipelineConnect.sv。
//
// ★名字警告★：G0(v2r2) 里叫 NewPipelineConnectPipe_27 的是另一个模块（82 端口，
// VLMergeBufferImp/VSMergeBufferImp 的 VMergebufferPipelineConnect），那个在 G1 里
// 叫 NewPipelineConnectPipe_29；本文件这个变体是 G1 新增的，G0 里没有对应物。
// 判据：例化点比对，见 scripts/check_name_collisions.py。

module NewPipelineConnectPipe_27(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  io_in_bits_0_valid,
  input  [63:0] io_in_bits_0_mask,
  input  io_in_bits_1_valid,
  input  [63:0] io_in_bits_1_mask,
  input  io_in_bits_2_valid,
  input  [63:0] io_in_bits_2_mask,
  input  io_in_bits_3_valid,
  input  [63:0] io_in_bits_3_mask,
  input  io_in_bits_4_valid,
  input  [63:0] io_in_bits_4_mask,
  input  io_in_bits_5_valid,
  input  [63:0] io_in_bits_5_mask,
  input  io_in_bits_6_valid,
  input  [63:0] io_in_bits_6_mask,
  input  io_in_bits_7_valid,
  input  [63:0] io_in_bits_7_mask,
  input  io_out_ready,
  output io_out_valid,
  output io_out_bits_0_valid,
  output [63:0] io_out_bits_0_mask,
  output io_out_bits_1_valid,
  output [63:0] io_out_bits_1_mask,
  output io_out_bits_2_valid,
  output [63:0] io_out_bits_2_mask,
  output io_out_bits_3_valid,
  output [63:0] io_out_bits_3_mask,
  output io_out_bits_4_valid,
  output [63:0] io_out_bits_4_mask,
  output io_out_bits_5_valid,
  output [63:0] io_out_bits_5_mask,
  output io_out_bits_6_valid,
  output [63:0] io_out_bits_6_mask,
  output io_out_bits_7_valid,
  output [63:0] io_out_bits_7_mask,
  input  io_rightOutFire
);
  // 8 条通道等宽（65 位/条 = 1 位 valid + 64 位 mask），按通道号从高位到低位排列。
  localparam int unsigned LANES  = 8;
  localparam int unsigned MASK_W = 64;
  localparam int unsigned LANE_W = 1 + MASK_W;

  wire [LANES*LANE_W-1:0] in_bus = {
    io_in_bits_0_valid, io_in_bits_0_mask,
    io_in_bits_1_valid, io_in_bits_1_mask,
    io_in_bits_2_valid, io_in_bits_2_mask,
    io_in_bits_3_valid, io_in_bits_3_mask,
    io_in_bits_4_valid, io_in_bits_4_mask,
    io_in_bits_5_valid, io_in_bits_5_mask,
    io_in_bits_6_valid, io_in_bits_6_mask,
    io_in_bits_7_valid, io_in_bits_7_mask
  };
  wire [LANES*LANE_W-1:0] out_bus;

  // 位宽自检（elaborate/time 0）：mask 宽度必须与布局一致。
  // 这一轮反复出事的形态是「逻辑全对、只有某个字段位宽停在旧值」——随机激励未必
  // 打得到高位，UT 照样 errors=0，要等 FM 才炸。这里让它在 time 0 就炸。
  initial begin
    if ($bits(io_in_bits_0_mask) != MASK_W)
      $fatal(1, "NewPipelineConnectPipe_27: mask %0d 位 != 布局的 %0d",
             $bits(io_in_bits_0_mask), MASK_W);
    if ($bits(in_bus) != LANES * LANE_W)
      $fatal(1, "NewPipelineConnectPipe_27: 入口打包 %0d 位 != %0d 条 x %0d 位",
             $bits(in_bus), LANES, LANE_W);
  end


  assign io_out_bits_0_valid = out_bus[7*LANE_W + MASK_W];
  assign io_out_bits_0_mask  = out_bus[7*LANE_W +: MASK_W];
  assign io_out_bits_1_valid = out_bus[6*LANE_W + MASK_W];
  assign io_out_bits_1_mask  = out_bus[6*LANE_W +: MASK_W];
  assign io_out_bits_2_valid = out_bus[5*LANE_W + MASK_W];
  assign io_out_bits_2_mask  = out_bus[5*LANE_W +: MASK_W];
  assign io_out_bits_3_valid = out_bus[4*LANE_W + MASK_W];
  assign io_out_bits_3_mask  = out_bus[4*LANE_W +: MASK_W];
  assign io_out_bits_4_valid = out_bus[3*LANE_W + MASK_W];
  assign io_out_bits_4_mask  = out_bus[3*LANE_W +: MASK_W];
  assign io_out_bits_5_valid = out_bus[2*LANE_W + MASK_W];
  assign io_out_bits_5_mask  = out_bus[2*LANE_W +: MASK_W];
  assign io_out_bits_6_valid = out_bus[1*LANE_W + MASK_W];
  assign io_out_bits_6_mask  = out_bus[1*LANE_W +: MASK_W];
  assign io_out_bits_7_valid = out_bus[0*LANE_W + MASK_W];
  assign io_out_bits_7_mask  = out_bus[0*LANE_W +: MASK_W];

  xs_PipelineConnect #(.DATA_WIDTH(LANES*LANE_W)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits(in_bus),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(1'b0)
  );
endmodule
