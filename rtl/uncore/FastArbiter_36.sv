// =============================================================================
//  FastArbiter_36 —— 单输入退化 FastArbiter (可读核 xs_FastArbiter_36_core)
// -----------------------------------------------------------------------------
//  RNXbar TXRSP: 每个 bank 只有 1 路输入, FastArbiter 退化为纯透传 (恒授权 input 0,
//  无状态、无 clock/reset、无握手)。本核把 CHI RSP-lite payload 打包成 struct 后原样
//  输出, 仅用于文档化通道字段布局 (srcID/txnID/opcode/dbID)。组合等价于逐字段直连。
// =============================================================================
module xs_FastArbiter_36_core(
  input         io_in_0_valid,
  input  [10:0] io_in_0_bits_srcID,
  input  [11:0] io_in_0_bits_txnID,
  input  [4:0]  io_in_0_bits_opcode,
  input  [11:0] io_in_0_bits_dbID,
  output        io_out_valid,
  output [10:0] io_out_bits_srcID,
  output [11:0] io_out_bits_txnID,
  output [4:0]  io_out_bits_opcode,
  output [11:0] io_out_bits_dbID
);

  typedef struct packed {
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [4:0]  opcode;
    logic [11:0] dbID;
  } rsp_t;

  rsp_t flit;
  assign flit = '{srcID:io_in_0_bits_srcID, txnID:io_in_0_bits_txnID,
                  opcode:io_in_0_bits_opcode, dbID:io_in_0_bits_dbID};

  assign io_out_valid      = io_in_0_valid;   // 单输入: 恒透传
  assign io_out_bits_srcID = flit.srcID;
  assign io_out_bits_txnID = flit.txnID;
  assign io_out_bits_opcode= flit.opcode;
  assign io_out_bits_dbID  = flit.dbID;

endmodule
