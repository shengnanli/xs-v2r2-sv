// =============================================================================
// xs_PipelineConnect —— 带握手的单级流水线寄存器（buffer stage）
//
// 对应 Chisel: xiangshan.backend.datapath.NewPipelineConnectPipe / NewPipelineConnect
// 语义（与 Scala 完全一致）：
//   in_ready = out_ready | ~valid           // 空或下游可收时可纳新数据
//   fire     = in_valid & in_ready          // 左侧握手成功
//   valid 寄存器：isFlush 清零（最高优先级）；否则 fire 置 1；否则 rightOutFire 清零；
//                 否则保持 → valid' = ~isFlush & (fire | ~rightOutFire & valid)
//   data = RegEnable(in_bits, fire)          // 数据在 fire 拍锁存
//   out_valid = valid，out_bits = data
// 注意：rightOutFire 是“下游本拍是否取走”的外部信号（通常 = out_valid & out_ready，
// 但由调用方提供，可能与 out_ready 不同步），用于决定何时清空本级。
//
// payload 用打包总线 io_in_bits/io_out_bits 表示，字段由外层包装层拼接/拆分。
// =============================================================================
module xs_PipelineConnect #(
  parameter int unsigned DATA_WIDTH = 1
)(
  input  logic                    clock,
  input  logic                    reset,          // 异步高有效，仅复位 valid
  output logic                    io_in_ready,
  input  logic                    io_in_valid,
  input  logic [DATA_WIDTH-1:0]   io_in_bits,
  input  logic                    io_out_ready,
  output logic                    io_out_valid,
  output logic [DATA_WIDTH-1:0]   io_out_bits,
  input  logic                    io_rightOutFire,
  input  logic                    io_isFlush
);

  logic                  valid;
  logic [DATA_WIDTH-1:0] data;
  logic                  fire;

  assign io_in_ready = io_out_ready | ~valid;
  assign fire        = io_in_valid & io_in_ready;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) valid <= 1'b0;
    else       valid <= ~io_isFlush & (fire | (~io_rightOutFire & valid));
  end

  always_ff @(posedge clock) begin
    if (fire) data <= io_in_bits;
  end

  assign io_out_valid = valid;
  assign io_out_bits  = data;

endmodule
