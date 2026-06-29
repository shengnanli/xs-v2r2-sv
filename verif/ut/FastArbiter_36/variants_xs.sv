// 自动生成：scripts/gen_fastarbiter.py —— 勿手改
module FastArbiter_36_xs(
  input io_in_0_valid,
  input [10:0] io_in_0_bits_srcID,
  input [11:0] io_in_0_bits_txnID,
  input [4:0] io_in_0_bits_opcode,
  input [11:0] io_in_0_bits_dbID,
  output io_out_valid,
  output [10:0] io_out_bits_srcID,
  output [11:0] io_out_bits_txnID,
  output [4:0] io_out_bits_opcode,
  output [11:0] io_out_bits_dbID
);
  xs_FastArbiter_36_core u_core (
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_dbID(io_in_0_bits_dbID),
    .io_out_valid(io_out_valid),
    .io_out_bits_srcID(io_out_bits_srcID),
    .io_out_bits_txnID(io_out_bits_txnID),
    .io_out_bits_opcode(io_out_bits_opcode),
    .io_out_bits_dbID(io_out_bits_dbID)
  );
endmodule
