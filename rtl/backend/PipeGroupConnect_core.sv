// =============================================================================
// xs_PipeGroupConnect_core —— 6 路组流水连接(CtrlBlock 内 PipeGroupConnect)。
//
// 对应 golden PipeGroupConnect。6 条 lane 共享一个 canAcc(整组一起接收):
//   canAcc = io_outAllFire | (所有 validVec == 0)         // 下游全 fire 或本组空
//   in_ready[i] = canAcc                                   // 各 lane ready 同 canAcc
//   validVec[i]' = ~flush & (in_valid[i] & canAcc | ~out_ready[i] & validVec[i])
//   dataVec[i] = RegEnable(in_bits[i], in_valid[i] & canAcc)
//   out_valid[i] = validVec[i], out_bits[i] = dataVec[i]
//
// 注意各 lane payload 位宽不同(lane0 多一个 snapshot 字段=534, lane1..5=533)。
// 故 6 lane 各用独立位宽的 data 总线端口(W0..W5), 单独例化各 lane 逻辑, 共享 canAcc。
// =============================================================================

// 单条 lane 的流水寄存器(valid + data)。valid 逻辑用外部算好的 canAcc。
module xs_pgc_lane #(
  parameter int unsigned W = 1
)(
  input  logic         clock,
  input  logic         reset,
  input  logic         io_flush,
  input  logic         canAcc,
  input  logic         in_valid,
  input  logic         out_ready,
  input  logic [W-1:0] in_bits,
  output logic         valid,
  output logic [W-1:0] out_bits
);
  logic         v;
  logic [W-1:0] d;
  assign valid    = v;
  assign out_bits = d;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) v <= 1'b0;
    else       v <= ~io_flush & ((in_valid & canAcc) | (~out_ready & v));
  end
  always_ff @(posedge clock) begin
    if (in_valid & canAcc) d <= in_bits;
  end
endmodule

module xs_PipeGroupConnect_core #(
  parameter int unsigned W0 = 1,
  parameter int unsigned W1 = 1,
  parameter int unsigned W2 = 1,
  parameter int unsigned W3 = 1,
  parameter int unsigned W4 = 1,
  parameter int unsigned W5 = 1
)(
  input  logic         clock,
  input  logic         reset,
  input  logic         io_flush,
  input  logic         io_outAllFire,
  input  logic [5:0]   in_valid,
  input  logic [5:0]   out_ready,
  input  logic [W0-1:0] in_bits_0,
  input  logic [W1-1:0] in_bits_1,
  input  logic [W2-1:0] in_bits_2,
  input  logic [W3-1:0] in_bits_3,
  input  logic [W4-1:0] in_bits_4,
  input  logic [W5-1:0] in_bits_5,
  output logic [5:0]   in_ready,
  output logic [5:0]   out_valid,
  output logic [W0-1:0] out_bits_0,
  output logic [W1-1:0] out_bits_1,
  output logic [W2-1:0] out_bits_2,
  output logic [W3-1:0] out_bits_3,
  output logic [W4-1:0] out_bits_4,
  output logic [W5-1:0] out_bits_5
);

  logic [5:0] validVec;
  wire  canAcc = io_outAllFire | (validVec == 6'h0);
  assign in_ready = {6{canAcc}};

  xs_pgc_lane #(.W(W0)) lane0 (.clock(clock), .reset(reset), .io_flush(io_flush),
      .canAcc(canAcc), .in_valid(in_valid[0]), .out_ready(out_ready[0]),
      .in_bits(in_bits_0), .valid(validVec[0]), .out_bits(out_bits_0));
  xs_pgc_lane #(.W(W1)) lane1 (.clock(clock), .reset(reset), .io_flush(io_flush),
      .canAcc(canAcc), .in_valid(in_valid[1]), .out_ready(out_ready[1]),
      .in_bits(in_bits_1), .valid(validVec[1]), .out_bits(out_bits_1));
  xs_pgc_lane #(.W(W2)) lane2 (.clock(clock), .reset(reset), .io_flush(io_flush),
      .canAcc(canAcc), .in_valid(in_valid[2]), .out_ready(out_ready[2]),
      .in_bits(in_bits_2), .valid(validVec[2]), .out_bits(out_bits_2));
  xs_pgc_lane #(.W(W3)) lane3 (.clock(clock), .reset(reset), .io_flush(io_flush),
      .canAcc(canAcc), .in_valid(in_valid[3]), .out_ready(out_ready[3]),
      .in_bits(in_bits_3), .valid(validVec[3]), .out_bits(out_bits_3));
  xs_pgc_lane #(.W(W4)) lane4 (.clock(clock), .reset(reset), .io_flush(io_flush),
      .canAcc(canAcc), .in_valid(in_valid[4]), .out_ready(out_ready[4]),
      .in_bits(in_bits_4), .valid(validVec[4]), .out_bits(out_bits_4));
  xs_pgc_lane #(.W(W5)) lane5 (.clock(clock), .reset(reset), .io_flush(io_flush),
      .canAcc(canAcc), .in_valid(in_valid[5]), .out_ready(out_ready[5]),
      .in_bits(in_bits_5), .valid(validVec[5]), .out_bits(out_bits_5));

  assign out_valid = validVec;

endmodule
