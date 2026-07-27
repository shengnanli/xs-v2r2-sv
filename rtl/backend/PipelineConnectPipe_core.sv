// =============================================================================
// xs_PipelineConnectPipe —— 「阻塞式」单级流水缓冲(plain PipelineConnect)。
//
// 对应 golden PipelineConnectPipe(CtrlBlock 内 decode->rename 之间的一级流水)。
// 与 NewPipelineConnect 不同, 本变体上游 ready 直接透传下游 ready, 锁存条件也用
// 下游 ready(而非本级 in_ready):
//   io_in_ready = io_out_ready                     // 直通(无本级容量反压)
//   leftFire    = io_in_valid & io_out_ready       // 左侧本拍握手成功
//   valid 寄存器(异步复位): valid' = ~isFlush & (leftFire | ~rightOutFire & valid)
//   data = RegEnable(io_in_bits, leftFire)         // payload 在 leftFire 拍锁存
//   io_out_valid = valid, io_out_bits = data
//
// payload 打包成一条 DATA_WIDTH 位总线, 字段拼接/拆分由外层 wrapper 负责。
// golden 里 lsrc_3/lsrc_4/vpu_vmask 是常量 0 输出(无对应输入), wrapper 在输入侧
// 直接喂 0 进 data 总线对应位, 令两侧同为「常量 0 驱动的寄存器」FM 精确匹配。
// =============================================================================
module xs_PipelineConnectPipe #(
  parameter int unsigned DATA_WIDTH = 1
)(
  input  logic                    clock,
  input  logic                    reset,          // 异步高有效, 仅复位 valid
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
  logic                  leftFire;

  assign io_in_ready = io_out_ready;
  assign leftFire    = io_in_valid & io_out_ready;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) valid <= 1'b0;
    else       valid <= ~io_isFlush & (leftFire | (~io_rightOutFire & valid));
  end

  always_ff @(posedge clock) begin
    if (leftFire) data <= io_in_bits;
  end

  assign io_out_valid = valid;
  assign io_out_bits  = data;

endmodule
