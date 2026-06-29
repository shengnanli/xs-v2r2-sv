// 自动生成 scripts/gen_chi_channel.py —— 勿手改
module RXDAT_4(
  input io_in_valid,
  input [10:0] io_in_bits_srcID,
  input [11:0] io_in_bits_txnID,
  input [3:0] io_in_bits_opcode,
  input [2:0] io_in_bits_resp,
  input [1:0] io_in_bits_dataID,
  input [255:0] io_in_bits_data,
  output io_out_valid,
  output [11:0] io_out_bits_txnID,
  output [6:0] io_out_bits_opcode,
  output [2:0] io_out_bits_resp,
  output [10:0] io_out_bits_srcID,
  output [1:0] io_out_bits_dataID,
  output [255:0] io_out_bits_data_data
);
  xs_RXDAT_4_core u_core (
    .io_in_valid(io_in_valid),
    .io_in_bits_srcID(io_in_bits_srcID),
    .io_in_bits_txnID(io_in_bits_txnID),
    .io_in_bits_opcode(io_in_bits_opcode),
    .io_in_bits_resp(io_in_bits_resp),
    .io_in_bits_dataID(io_in_bits_dataID),
    .io_in_bits_data(io_in_bits_data),
    .io_out_valid(io_out_valid),
    .io_out_bits_txnID(io_out_bits_txnID),
    .io_out_bits_opcode(io_out_bits_opcode),
    .io_out_bits_resp(io_out_bits_resp),
    .io_out_bits_srcID(io_out_bits_srcID),
    .io_out_bits_dataID(io_out_bits_dataID),
    .io_out_bits_data_data(io_out_bits_data_data)
  );
endmodule
