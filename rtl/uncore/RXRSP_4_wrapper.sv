// 自动生成 scripts/gen_chi_channel.py —— 勿手改
module RXRSP_4(
  input io_in_valid,
  input [10:0] io_in_bits_srcID,
  input [11:0] io_in_bits_txnID,
  input [4:0] io_in_bits_opcode,
  input [11:0] io_in_bits_dbID,
  output io_out_valid,
  output [11:0] io_out_bits_txnID,
  output [11:0] io_out_bits_dbID,
  output [6:0] io_out_bits_opcode,
  output [10:0] io_out_bits_srcID
);
  xs_RXRSP_4_core u_core (
    .io_in_valid(io_in_valid),
    .io_in_bits_srcID(io_in_bits_srcID),
    .io_in_bits_txnID(io_in_bits_txnID),
    .io_in_bits_opcode(io_in_bits_opcode),
    .io_in_bits_dbID(io_in_bits_dbID),
    .io_out_valid(io_out_valid),
    .io_out_bits_txnID(io_out_bits_txnID),
    .io_out_bits_dbID(io_out_bits_dbID),
    .io_out_bits_opcode(io_out_bits_opcode),
    .io_out_bits_srcID(io_out_bits_srcID)
  );
endmodule
