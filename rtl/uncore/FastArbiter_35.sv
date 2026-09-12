// =============================================================================
//  FastArbiter_35 —— RNXbar TXRSP 的单输入退化仲裁器（G1 名；G0 里叫 FastArbiter_36）
// -----------------------------------------------------------------------------
//  位置：OpenLLC / RNXbar 的上行 TXRSP 通道。RNXbar 把 1 个 RN 的 TXRSP 按
//  txnID[10:9] 解复用到 4 个 HN bank，每个 bank 侧只有 1 路输入 ——
//  FastArbiter 退化成恒授权 input 0 的纯组合透传：无 clock/reset、无状态、无握手。
//  核心机制：把 CHI RSP-lite payload（srcID/txnID/opcode/dbID）打包成 struct
//  再原样输出，组合上等价于逐字段直连，struct 只为讲清通道字段布局。
//  G1 重编号：golden 模块体与 G0 的 FastArbiter_36 逐字节相同（仅自名不同），
//  故本文件是上一轮可读核的原样继承 + 改名，逻辑一行未动。
// =============================================================================

module xs_FastArbiter_35_core(
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

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden FastArbiter_35.sv 逐位同名同宽
// ---------------------------------------------------------------------------
module FastArbiter_35(
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
  xs_FastArbiter_35_core u_core (
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
