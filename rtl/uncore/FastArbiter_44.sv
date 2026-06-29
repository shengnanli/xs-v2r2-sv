// =============================================================================
//  FastArbiter_44 —— CHI SNP 4 路 round-robin 仲裁器 (可读核 xs_FastArbiter_44_core)
// -----------------------------------------------------------------------------
//  RNXbar RXSNP: 4 路 CHI 侦听 (snoop) flit 经本仲裁器轮转选一路下发。
//  payload = CHI SNP flit 子集 (txnID/fwdNID/fwdTxnID/opcode/addr[45]/doNotGoToSD/
//  retToSrc)。仲裁算法见 fastarbiter_pkg。无 io_in_ready 端口。
// =============================================================================
module xs_FastArbiter_44_core
  import fastarbiter_pkg::*;
(
  input         clock,
  input         reset,
  input         io_in_0_valid,
  input  [11:0] io_in_0_bits_txnID,
  input  [10:0] io_in_0_bits_fwdNID,
  input  [11:0] io_in_0_bits_fwdTxnID,
  input  [4:0]  io_in_0_bits_opcode,
  input  [44:0] io_in_0_bits_addr,
  input         io_in_0_bits_doNotGoToSD,
  input         io_in_0_bits_retToSrc,
  input         io_in_1_valid,
  input  [11:0] io_in_1_bits_txnID,
  input  [10:0] io_in_1_bits_fwdNID,
  input  [11:0] io_in_1_bits_fwdTxnID,
  input  [4:0]  io_in_1_bits_opcode,
  input  [44:0] io_in_1_bits_addr,
  input         io_in_1_bits_doNotGoToSD,
  input         io_in_1_bits_retToSrc,
  input         io_in_2_valid,
  input  [11:0] io_in_2_bits_txnID,
  input  [10:0] io_in_2_bits_fwdNID,
  input  [11:0] io_in_2_bits_fwdTxnID,
  input  [4:0]  io_in_2_bits_opcode,
  input  [44:0] io_in_2_bits_addr,
  input         io_in_2_bits_doNotGoToSD,
  input         io_in_2_bits_retToSrc,
  input         io_in_3_valid,
  input  [11:0] io_in_3_bits_txnID,
  input  [10:0] io_in_3_bits_fwdNID,
  input  [11:0] io_in_3_bits_fwdTxnID,
  input  [4:0]  io_in_3_bits_opcode,
  input  [44:0] io_in_3_bits_addr,
  input         io_in_3_bits_doNotGoToSD,
  input         io_in_3_bits_retToSrc,
  input         io_out_ready,
  output        io_out_valid,
  output [11:0] io_out_bits_txnID,
  output [10:0] io_out_bits_fwdNID,
  output [11:0] io_out_bits_fwdTxnID,
  output [4:0]  io_out_bits_opcode,
  output [44:0] io_out_bits_addr,
  output        io_out_bits_doNotGoToSD,
  output        io_out_bits_retToSrc,
  output [IDXW-1:0] io_chosen
);

  // ---- CHI SNP flit payload ----
  typedef struct packed {
    logic [11:0] txnID;
    logic [10:0] fwdNID;
    logic [11:0] fwdTxnID;
    logic [4:0]  opcode;
    logic [44:0] addr;
    logic        doNotGoToSD;
    logic        retToSrc;
  } snp_t;

  snp_t            pin [NUM];
  logic [NUM-1:0]  valids;

  assign valids = {io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};

  assign pin[0] = '{txnID:io_in_0_bits_txnID, fwdNID:io_in_0_bits_fwdNID,
                    fwdTxnID:io_in_0_bits_fwdTxnID, opcode:io_in_0_bits_opcode,
                    addr:io_in_0_bits_addr, doNotGoToSD:io_in_0_bits_doNotGoToSD,
                    retToSrc:io_in_0_bits_retToSrc};
  assign pin[1] = '{txnID:io_in_1_bits_txnID, fwdNID:io_in_1_bits_fwdNID,
                    fwdTxnID:io_in_1_bits_fwdTxnID, opcode:io_in_1_bits_opcode,
                    addr:io_in_1_bits_addr, doNotGoToSD:io_in_1_bits_doNotGoToSD,
                    retToSrc:io_in_1_bits_retToSrc};
  assign pin[2] = '{txnID:io_in_2_bits_txnID, fwdNID:io_in_2_bits_fwdNID,
                    fwdTxnID:io_in_2_bits_fwdTxnID, opcode:io_in_2_bits_opcode,
                    addr:io_in_2_bits_addr, doNotGoToSD:io_in_2_bits_doNotGoToSD,
                    retToSrc:io_in_2_bits_retToSrc};
  assign pin[3] = '{txnID:io_in_3_bits_txnID, fwdNID:io_in_3_bits_fwdNID,
                    fwdTxnID:io_in_3_bits_fwdTxnID, opcode:io_in_3_bits_opcode,
                    addr:io_in_3_bits_addr, doNotGoToSD:io_in_3_bits_doNotGoToSD,
                    retToSrc:io_in_3_bits_retToSrc};

  // ---- round-robin 状态 + 组合选胜 ----
  reg   [NUM-1:0] pendingMask;
  reg   [NUM-1:0] rrGrantMask;
  logic [NUM-1:0] chosenOH;

  assign chosenOH = rr_choose(valids, pendingMask, rrGrantMask);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      pendingMask <= '0;
      rrGrantMask <= '0;
    end else if (io_out_ready & (|valids)) begin
      pendingMask <= valids & ~chosenOH;
      rrGrantMask <= gt_mask(chosenOH);
    end
  end

  // ---- 胜者 payload 多路选择 ----
  snp_t psel;
  always_comb begin
    psel = '0;
    for (int i = 0; i < NUM; i++)
      if (chosenOH[i]) psel |= pin[i];
  end

  assign io_out_valid            = |valids;
  assign io_out_bits_txnID       = psel.txnID;
  assign io_out_bits_fwdNID      = psel.fwdNID;
  assign io_out_bits_fwdTxnID    = psel.fwdTxnID;
  assign io_out_bits_opcode      = psel.opcode;
  assign io_out_bits_addr        = psel.addr;
  assign io_out_bits_doNotGoToSD = psel.doNotGoToSD;
  assign io_out_bits_retToSrc    = psel.retToSrc;
  assign io_chosen               = encode_oh(chosenOH);

endmodule
