// =============================================================================
// xs_SkidBuffer_core —— 单项 skid buffer（skidBufferConnect 的核）
//
// 位置：src/main/scala/xiangshan/mem/vector/VecCommon.scala 的 object skidBuffer /
//   class skidBufferConnect。向量访存的拆分单元 VLSplit / VSSplit 用它把发往后级流水
//   的 DecoupledIO 断开一拍 ready 的时序路径：下游 ready 不再直接穿回上游。
//
// 机制（两态：empty / skid）：
//   empty：直通。out.valid = in.valid，out.bits = in.bits，in.ready = 1。
//          若本拍上游有数据而下游不收（in.fire && !out.ready）且没有 flush，
//          把 in.bits 锁进 dataBuffer，转 skid。
//   skid ：缓冲里有一项。out.valid = 1，out.bits = dataBuffer，in.ready = 0。
//          下游收走（out.ready）或 flush ⇒ 回 empty。
//   因而 in.ready = !state，out.valid = in.valid | state，out.bits = state ? buf : in.bits。
//
// 怪癖：dataBuffer 不复位；flush 当拍若 in.fire && !out.ready，载荷仍会被锁进 dataBuffer
//   （RegEnable 的使能里没有 flush），只是 state 不转 skid。
//
// 载荷是 WIDTH 位打包向量，字段拆拼由薄文件做。
// =============================================================================
module xs_SkidBuffer_core #(
  parameter int unsigned WIDTH = 1
)(
  input  logic             clock,
  input  logic             reset,
  input  logic             flush,
  output logic             in_ready,
  input  logic             in_valid,
  input  logic [WIDTH-1:0] in_bits,
  input  logic             out_ready,
  output logic             out_valid,
  output logic [WIDTH-1:0] out_bits
);

  typedef enum logic {
    EMPTY = 1'b0,   // 直通
    SKID  = 1'b1    // 缓冲里有一项
  } state_e;

  state_e           state;
  logic [WIDTH-1:0] dataBuffer;       // 不复位

  wire in_fire = in_valid & in_ready;
  wire capture = in_fire & ~out_ready;      // 下游不收：接住这一项

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      state <= EMPTY;
    else if (state == EMPTY)
      state <= (capture & ~flush) ? SKID : EMPTY;
    else
      state <= (out_ready | flush) ? EMPTY : SKID;
  end

  always_ff @(posedge clock) begin
    if (capture) dataBuffer <= in_bits;
  end

  assign in_ready  = (state == EMPTY);
  assign out_valid = in_valid | (state == SKID);
  assign out_bits  = (state == SKID) ? dataBuffer : in_bits;

endmodule
