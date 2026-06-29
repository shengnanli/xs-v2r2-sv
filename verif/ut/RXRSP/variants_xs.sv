// 自动生成 scripts/gen_chi_channel.py —— 勿手改
module RXRSP_xs(
  input io_out_valid,
  input [10:0] io_out_bits_srcID,
  input [11:0] io_out_bits_txnID,
  input [4:0] io_out_bits_opcode,
  input [1:0] io_out_bits_respErr,
  input [2:0] io_out_bits_resp,
  input [11:0] io_out_bits_dbID,
  input [3:0] io_out_bits_pCrdType,
  input io_out_bits_traceTag,
  output io_in_valid,
  output [7:0] io_in_mshrId,
  output [6:0] io_in_respInfo_chiOpcode,
  output [10:0] io_in_respInfo_srcID,
  output [11:0] io_in_respInfo_dbID,
  output [2:0] io_in_respInfo_resp,
  output [3:0] io_in_respInfo_pCrdType,
  output [1:0] io_in_respInfo_respErr,
  output io_in_respInfo_traceTag
);
  xs_RXRSP_core u_core (
    .io_out_valid(io_out_valid),
    .io_out_bits_srcID(io_out_bits_srcID),
    .io_out_bits_txnID(io_out_bits_txnID),
    .io_out_bits_opcode(io_out_bits_opcode),
    .io_out_bits_respErr(io_out_bits_respErr),
    .io_out_bits_resp(io_out_bits_resp),
    .io_out_bits_dbID(io_out_bits_dbID),
    .io_out_bits_pCrdType(io_out_bits_pCrdType),
    .io_out_bits_traceTag(io_out_bits_traceTag),
    .io_in_valid(io_in_valid),
    .io_in_mshrId(io_in_mshrId),
    .io_in_respInfo_chiOpcode(io_in_respInfo_chiOpcode),
    .io_in_respInfo_srcID(io_in_respInfo_srcID),
    .io_in_respInfo_dbID(io_in_respInfo_dbID),
    .io_in_respInfo_resp(io_in_respInfo_resp),
    .io_in_respInfo_pCrdType(io_in_respInfo_pCrdType),
    .io_in_respInfo_respErr(io_in_respInfo_respErr),
    .io_in_respInfo_traceTag(io_in_respInfo_traceTag)
  );
endmodule
