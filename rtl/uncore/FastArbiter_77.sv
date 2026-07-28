// =============================================================================
//  FastArbiter_77 —— CHI RXSNP (snoop) 2 路 round-robin 仲裁器 (可读核 xs_FastArbiter_77_core)
// -----------------------------------------------------------------------------
//  XSTop 顶层 CHI 交叉开关: 2 个上行主口经本仲裁器轮转选一路发往下游。
//  与 SNXbar/RNXbar 的 4 输入 FastArbiter 同族, 但 N=2 且 golden 用特化的 2 位
//  rrSelOH/rrGrantMask 展开式 (非通用 pkg), 本核逐位忠实复刻。
//  payload = CHI RXSNP (snoop) flit 子集, 打包成 packed struct 后用胜者 one-hot OR
//  归约多路选择到 io_out。无 io_in_ready 端口 (上游用 io_chosen 自行回送),
//  下游背压只看 io_out_ready。
// =============================================================================
module xs_FastArbiter_77_core(
  input clock,
  input reset,
  input io_in_0_valid,
  input [3:0] io_in_0_bits_qos,
  input [10:0] io_in_0_bits_srcID,
  input [11:0] io_in_0_bits_txnID,
  input [10:0] io_in_0_bits_fwdNID,
  input [11:0] io_in_0_bits_fwdTxnID,
  input [4:0] io_in_0_bits_opcode,
  input [44:0] io_in_0_bits_addr,
  input io_in_0_bits_ns,
  input io_in_0_bits_doNotGoToSD,
  input io_in_0_bits_retToSrc,
  input io_in_0_bits_traceTag,
  input io_in_0_bits_mpam_perfMonGroup,
  input [8:0] io_in_0_bits_mpam_partID,
  input io_in_0_bits_mpam_mpamNS,
  input io_in_1_valid,
  input [3:0] io_in_1_bits_qos,
  input [10:0] io_in_1_bits_srcID,
  input [11:0] io_in_1_bits_txnID,
  input [10:0] io_in_1_bits_fwdNID,
  input [11:0] io_in_1_bits_fwdTxnID,
  input [4:0] io_in_1_bits_opcode,
  input [44:0] io_in_1_bits_addr,
  input io_in_1_bits_ns,
  input io_in_1_bits_doNotGoToSD,
  input io_in_1_bits_retToSrc,
  input io_in_1_bits_traceTag,
  input io_in_1_bits_mpam_perfMonGroup,
  input [8:0] io_in_1_bits_mpam_partID,
  input io_in_1_bits_mpam_mpamNS,
  input io_out_ready,
  output io_out_valid,
  output [3:0] io_out_bits_qos,
  output [10:0] io_out_bits_srcID,
  output [11:0] io_out_bits_txnID,
  output [10:0] io_out_bits_fwdNID,
  output [11:0] io_out_bits_fwdTxnID,
  output [4:0] io_out_bits_opcode,
  output [44:0] io_out_bits_addr,
  output io_out_bits_ns,
  output io_out_bits_doNotGoToSD,
  output io_out_bits_retToSrc,
  output io_out_bits_traceTag,
  output io_out_bits_mpam_perfMonGroup,
  output [8:0] io_out_bits_mpam_partID,
  output io_out_bits_mpam_mpamNS,
  output io_chosen
);

  // ---- CHI RXSNP (snoop) flit payload (打包成 packed struct, 便于 one-hot OR 多路选择) ----
  typedef struct packed {
    logic [3:0] qos;
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [10:0] fwdNID;
    logic [11:0] fwdTxnID;
    logic [4:0] opcode;
    logic [44:0] addr;
    logic ns;
    logic doNotGoToSD;
    logic retToSrc;
    logic traceTag;
    logic mpam_perfMonGroup;
    logic [8:0] mpam_partID;
    logic mpam_mpamNS;
  } flit_t;

  flit_t       pin [2];
  logic [1:0]  valids;

  assign valids = {io_in_1_valid, io_in_0_valid};
  assign pin[0] = '{qos:io_in_0_bits_qos, srcID:io_in_0_bits_srcID, txnID:io_in_0_bits_txnID, fwdNID:io_in_0_bits_fwdNID, fwdTxnID:io_in_0_bits_fwdTxnID, opcode:io_in_0_bits_opcode, addr:io_in_0_bits_addr, ns:io_in_0_bits_ns, doNotGoToSD:io_in_0_bits_doNotGoToSD, retToSrc:io_in_0_bits_retToSrc, traceTag:io_in_0_bits_traceTag, mpam_perfMonGroup:io_in_0_bits_mpam_perfMonGroup, mpam_partID:io_in_0_bits_mpam_partID, mpam_mpamNS:io_in_0_bits_mpam_mpamNS};
  assign pin[1] = '{qos:io_in_1_bits_qos, srcID:io_in_1_bits_srcID, txnID:io_in_1_bits_txnID, fwdNID:io_in_1_bits_fwdNID, fwdTxnID:io_in_1_bits_fwdTxnID, opcode:io_in_1_bits_opcode, addr:io_in_1_bits_addr, ns:io_in_1_bits_ns, doNotGoToSD:io_in_1_bits_doNotGoToSD, retToSrc:io_in_1_bits_retToSrc, traceTag:io_in_1_bits_traceTag, mpam_perfMonGroup:io_in_1_bits_mpam_perfMonGroup, mpam_partID:io_in_1_bits_mpam_partID, mpam_mpamNS:io_in_1_bits_mpam_mpamNS};

  // ---- 2 输入 round-robin 状态 + 组合选胜 (逐位复刻 golden 特化展开) ----
  reg   [1:0] pendingMask;
  reg   [1:0] rrGrantMask;
  logic [1:0] chosenOH;

  wire        rrSelOH_T3 = rrGrantMask[0] & pendingMask[0];
  wire [1:0]  rrSelOH    = {rrGrantMask[1] & pendingMask[1] & ~rrSelOH_T3, rrSelOH_T3};
  assign chosenOH =
    (|(rrSelOH & valids)) ? rrSelOH
                          : {io_in_1_valid & ~io_in_0_valid, io_in_0_valid};

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      pendingMask <= 2'h0;
      rrGrantMask <= 2'h0;
    end else if (io_out_ready & (|valids)) begin
      pendingMask <= valids & ~chosenOH;     // 没被选中的 valid 转入欠服务
      rrGrantMask <= {chosenOH[0], 1'h0};  // 优先区推进到本次胜者之后
    end
  end

  // ---- 胜者 payload 多路选择 (one-hot OR 归约, chosenOH 至多一位置位) ----
  flit_t psel;
  always_comb begin
    psel = '0;
    for (int i = 0; i < 2; i++)
      if (chosenOH[i]) psel |= pin[i];
  end

  assign io_out_valid = |valids;
  assign io_out_bits_qos                  = psel.qos;
  assign io_out_bits_srcID                = psel.srcID;
  assign io_out_bits_txnID                = psel.txnID;
  assign io_out_bits_fwdNID               = psel.fwdNID;
  assign io_out_bits_fwdTxnID             = psel.fwdTxnID;
  assign io_out_bits_opcode               = psel.opcode;
  assign io_out_bits_addr                 = psel.addr;
  assign io_out_bits_ns                   = psel.ns;
  assign io_out_bits_doNotGoToSD          = psel.doNotGoToSD;
  assign io_out_bits_retToSrc             = psel.retToSrc;
  assign io_out_bits_traceTag             = psel.traceTag;
  assign io_out_bits_mpam_perfMonGroup    = psel.mpam_perfMonGroup;
  assign io_out_bits_mpam_partID          = psel.mpam_partID;
  assign io_out_bits_mpam_mpamNS          = psel.mpam_mpamNS;
  assign io_chosen    = chosenOH[1];

endmodule
