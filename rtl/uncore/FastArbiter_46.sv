// =============================================================================
//  FastArbiter_46 —— CHI DAT 4 路 round-robin 仲裁器 (可读核 xs_FastArbiter_46_core)
// -----------------------------------------------------------------------------
//  RNXbar RXDAT / SNXbar TXDAT: 4 路 CHI 数据通道 flit 经本仲裁器轮转选一路输出。
//  payload = CHI DAT flit 子集 (tgtID/srcID/txnID/homeNID/opcode/resp/dataSource/
//  dbID/dataID/be/data[256]/dataCheck)。仲裁算法见 fastarbiter_pkg。
//  无 io_in_ready 端口; 下游背压只看 io_out_ready。
// =============================================================================
module xs_FastArbiter_46_core
  import fastarbiter_pkg::*;
(
  input          clock,
  input          reset,
  input          io_in_0_valid,
  input  [10:0]  io_in_0_bits_tgtID,
  input  [10:0]  io_in_0_bits_srcID,
  input  [11:0]  io_in_0_bits_txnID,
  input  [10:0]  io_in_0_bits_homeNID,
  input  [3:0]   io_in_0_bits_opcode,
  input  [2:0]   io_in_0_bits_resp,
  input  [3:0]   io_in_0_bits_dataSource,
  input  [11:0]  io_in_0_bits_dbID,
  input  [1:0]   io_in_0_bits_dataID,
  input  [31:0]  io_in_0_bits_be,
  input  [255:0] io_in_0_bits_data,
  input  [31:0]  io_in_0_bits_dataCheck,
  input          io_in_1_valid,
  input  [10:0]  io_in_1_bits_tgtID,
  input  [10:0]  io_in_1_bits_srcID,
  input  [11:0]  io_in_1_bits_txnID,
  input  [10:0]  io_in_1_bits_homeNID,
  input  [3:0]   io_in_1_bits_opcode,
  input  [2:0]   io_in_1_bits_resp,
  input  [3:0]   io_in_1_bits_dataSource,
  input  [11:0]  io_in_1_bits_dbID,
  input  [1:0]   io_in_1_bits_dataID,
  input  [31:0]  io_in_1_bits_be,
  input  [255:0] io_in_1_bits_data,
  input  [31:0]  io_in_1_bits_dataCheck,
  input          io_in_2_valid,
  input  [10:0]  io_in_2_bits_tgtID,
  input  [10:0]  io_in_2_bits_srcID,
  input  [11:0]  io_in_2_bits_txnID,
  input  [10:0]  io_in_2_bits_homeNID,
  input  [3:0]   io_in_2_bits_opcode,
  input  [2:0]   io_in_2_bits_resp,
  input  [3:0]   io_in_2_bits_dataSource,
  input  [11:0]  io_in_2_bits_dbID,
  input  [1:0]   io_in_2_bits_dataID,
  input  [31:0]  io_in_2_bits_be,
  input  [255:0] io_in_2_bits_data,
  input  [31:0]  io_in_2_bits_dataCheck,
  input          io_in_3_valid,
  input  [10:0]  io_in_3_bits_tgtID,
  input  [10:0]  io_in_3_bits_srcID,
  input  [11:0]  io_in_3_bits_txnID,
  input  [10:0]  io_in_3_bits_homeNID,
  input  [3:0]   io_in_3_bits_opcode,
  input  [2:0]   io_in_3_bits_resp,
  input  [3:0]   io_in_3_bits_dataSource,
  input  [11:0]  io_in_3_bits_dbID,
  input  [1:0]   io_in_3_bits_dataID,
  input  [31:0]  io_in_3_bits_be,
  input  [255:0] io_in_3_bits_data,
  input  [31:0]  io_in_3_bits_dataCheck,
  input          io_out_ready,
  output         io_out_valid,
  output [10:0]  io_out_bits_tgtID,
  output [10:0]  io_out_bits_srcID,
  output [11:0]  io_out_bits_txnID,
  output [10:0]  io_out_bits_homeNID,
  output [3:0]   io_out_bits_opcode,
  output [2:0]   io_out_bits_resp,
  output [3:0]   io_out_bits_dataSource,
  output [11:0]  io_out_bits_dbID,
  output [1:0]   io_out_bits_dataID,
  output [31:0]  io_out_bits_be,
  output [255:0] io_out_bits_data,
  output [31:0]  io_out_bits_dataCheck,
  output [IDXW-1:0] io_chosen
);

  // ---- CHI DAT flit payload ----
  typedef struct packed {
    logic [10:0]  tgtID;
    logic [10:0]  srcID;
    logic [11:0]  txnID;
    logic [10:0]  homeNID;
    logic [3:0]   opcode;
    logic [2:0]   resp;
    logic [3:0]   dataSource;
    logic [11:0]  dbID;
    logic [1:0]   dataID;
    logic [31:0]  be;
    logic [255:0] data;
    logic [31:0]  dataCheck;
  } dat_t;

  dat_t            pin [NUM];
  logic [NUM-1:0]  valids;

  assign valids = {io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};

  assign pin[0] = '{tgtID:io_in_0_bits_tgtID, srcID:io_in_0_bits_srcID, txnID:io_in_0_bits_txnID,
                    homeNID:io_in_0_bits_homeNID, opcode:io_in_0_bits_opcode, resp:io_in_0_bits_resp,
                    dataSource:io_in_0_bits_dataSource, dbID:io_in_0_bits_dbID,
                    dataID:io_in_0_bits_dataID, be:io_in_0_bits_be, data:io_in_0_bits_data,
                    dataCheck:io_in_0_bits_dataCheck};
  assign pin[1] = '{tgtID:io_in_1_bits_tgtID, srcID:io_in_1_bits_srcID, txnID:io_in_1_bits_txnID,
                    homeNID:io_in_1_bits_homeNID, opcode:io_in_1_bits_opcode, resp:io_in_1_bits_resp,
                    dataSource:io_in_1_bits_dataSource, dbID:io_in_1_bits_dbID,
                    dataID:io_in_1_bits_dataID, be:io_in_1_bits_be, data:io_in_1_bits_data,
                    dataCheck:io_in_1_bits_dataCheck};
  assign pin[2] = '{tgtID:io_in_2_bits_tgtID, srcID:io_in_2_bits_srcID, txnID:io_in_2_bits_txnID,
                    homeNID:io_in_2_bits_homeNID, opcode:io_in_2_bits_opcode, resp:io_in_2_bits_resp,
                    dataSource:io_in_2_bits_dataSource, dbID:io_in_2_bits_dbID,
                    dataID:io_in_2_bits_dataID, be:io_in_2_bits_be, data:io_in_2_bits_data,
                    dataCheck:io_in_2_bits_dataCheck};
  assign pin[3] = '{tgtID:io_in_3_bits_tgtID, srcID:io_in_3_bits_srcID, txnID:io_in_3_bits_txnID,
                    homeNID:io_in_3_bits_homeNID, opcode:io_in_3_bits_opcode, resp:io_in_3_bits_resp,
                    dataSource:io_in_3_bits_dataSource, dbID:io_in_3_bits_dbID,
                    dataID:io_in_3_bits_dataID, be:io_in_3_bits_be, data:io_in_3_bits_data,
                    dataCheck:io_in_3_bits_dataCheck};

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
  dat_t psel;
  always_comb begin
    psel = '0;
    for (int i = 0; i < NUM; i++)
      if (chosenOH[i]) psel |= pin[i];
  end

  assign io_out_valid           = |valids;
  assign io_out_bits_tgtID      = psel.tgtID;
  assign io_out_bits_srcID      = psel.srcID;
  assign io_out_bits_txnID      = psel.txnID;
  assign io_out_bits_homeNID    = psel.homeNID;
  assign io_out_bits_opcode     = psel.opcode;
  assign io_out_bits_resp       = psel.resp;
  assign io_out_bits_dataSource = psel.dataSource;
  assign io_out_bits_dbID       = psel.dbID;
  assign io_out_bits_dataID     = psel.dataID;
  assign io_out_bits_be         = psel.be;
  assign io_out_bits_data       = psel.data;
  assign io_out_bits_dataCheck  = psel.dataCheck;
  assign io_chosen              = encode_oh(chosenOH);

endmodule
