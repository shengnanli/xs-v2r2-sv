// 自动生成：scripts/gen_rxtxlinkmon.py —— 勿手改
// ReceiverLinkMonitor 双例化逐拍比对: golden ReceiverLinkMonitor vs 可读 ReceiverLinkMonitor_xs(经 wrapper)。
// 6 个 flit 转换子模块两侧共用同一份 golden RTL(白盒)。全随机激励。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic io_in_txsactive;
  logic io_in_syscoreq;
  logic io_in_tx_linkactivereq;
  logic io_in_tx_req_flitpend;
  logic io_in_tx_req_flitv;
  logic [161:0] io_in_tx_req_flit;
  logic io_in_tx_rsp_flitpend;
  logic io_in_tx_rsp_flitv;
  logic [72:0] io_in_tx_rsp_flit;
  logic io_in_tx_dat_flitpend;
  logic io_in_tx_dat_flitv;
  logic [421:0] io_in_tx_dat_flit;
  logic io_in_rx_linkactiveack;
  logic io_in_rx_rsp_lcrdv;
  logic io_in_rx_dat_lcrdv;
  logic io_in_rx_snp_lcrdv;
  logic io_out_tx_req_ready;
  logic io_out_tx_rsp_ready;
  logic io_out_tx_dat_ready;
  logic io_out_rx_rsp_valid;
  logic [3:0] io_out_rx_rsp_bits_qos;
  logic [10:0] io_out_rx_rsp_bits_tgtID;
  logic [10:0] io_out_rx_rsp_bits_srcID;
  logic [11:0] io_out_rx_rsp_bits_txnID;
  logic [4:0] io_out_rx_rsp_bits_opcode;
  logic [1:0] io_out_rx_rsp_bits_respErr;
  logic [2:0] io_out_rx_rsp_bits_resp;
  logic [2:0] io_out_rx_rsp_bits_fwdState;
  logic [2:0] io_out_rx_rsp_bits_cBusy;
  logic [11:0] io_out_rx_rsp_bits_dbID;
  logic [3:0] io_out_rx_rsp_bits_pCrdType;
  logic [1:0] io_out_rx_rsp_bits_tagOp;
  logic io_out_rx_rsp_bits_traceTag;
  logic io_out_rx_dat_valid;
  logic [3:0] io_out_rx_dat_bits_qos;
  logic [10:0] io_out_rx_dat_bits_tgtID;
  logic [10:0] io_out_rx_dat_bits_srcID;
  logic [11:0] io_out_rx_dat_bits_txnID;
  logic [10:0] io_out_rx_dat_bits_homeNID;
  logic [3:0] io_out_rx_dat_bits_opcode;
  logic [1:0] io_out_rx_dat_bits_respErr;
  logic [2:0] io_out_rx_dat_bits_resp;
  logic [3:0] io_out_rx_dat_bits_dataSource;
  logic [2:0] io_out_rx_dat_bits_cBusy;
  logic [11:0] io_out_rx_dat_bits_dbID;
  logic [1:0] io_out_rx_dat_bits_ccID;
  logic [1:0] io_out_rx_dat_bits_dataID;
  logic [1:0] io_out_rx_dat_bits_tagOp;
  logic [7:0] io_out_rx_dat_bits_tag;
  logic [1:0] io_out_rx_dat_bits_tu;
  logic io_out_rx_dat_bits_traceTag;
  logic [3:0] io_out_rx_dat_bits_rsvdc;
  logic [31:0] io_out_rx_dat_bits_be;
  logic [255:0] io_out_rx_dat_bits_data;
  logic [31:0] io_out_rx_dat_bits_dataCheck;
  logic [3:0] io_out_rx_dat_bits_poison;
  logic io_out_rx_snp_valid;
  logic [3:0] io_out_rx_snp_bits_qos;
  logic [10:0] io_out_rx_snp_bits_srcID;
  logic [11:0] io_out_rx_snp_bits_txnID;
  logic [10:0] io_out_rx_snp_bits_fwdNID;
  logic [11:0] io_out_rx_snp_bits_fwdTxnID;
  logic [4:0] io_out_rx_snp_bits_opcode;
  logic [44:0] io_out_rx_snp_bits_addr;
  logic io_out_rx_snp_bits_ns;
  logic io_out_rx_snp_bits_doNotGoToSD;
  logic io_out_rx_snp_bits_retToSrc;
  logic io_out_rx_snp_bits_traceTag;
  logic io_out_rx_snp_bits_mpam_perfMonGroup;
  logic [8:0] io_out_rx_snp_bits_mpam_partID;
  logic io_out_rx_snp_bits_mpam_mpamNS;
  wire g_io_in_rxsactive;
  wire i_io_in_rxsactive;
  wire g_io_in_syscoack;
  wire i_io_in_syscoack;
  wire g_io_in_tx_linkactiveack;
  wire i_io_in_tx_linkactiveack;
  wire g_io_in_tx_req_lcrdv;
  wire i_io_in_tx_req_lcrdv;
  wire g_io_in_tx_rsp_lcrdv;
  wire i_io_in_tx_rsp_lcrdv;
  wire g_io_in_tx_dat_lcrdv;
  wire i_io_in_tx_dat_lcrdv;
  wire g_io_in_rx_linkactivereq;
  wire i_io_in_rx_linkactivereq;
  wire g_io_in_rx_rsp_flitpend;
  wire i_io_in_rx_rsp_flitpend;
  wire g_io_in_rx_rsp_flitv;
  wire i_io_in_rx_rsp_flitv;
  wire [72:0] g_io_in_rx_rsp_flit;
  wire [72:0] i_io_in_rx_rsp_flit;
  wire g_io_in_rx_dat_flitpend;
  wire i_io_in_rx_dat_flitpend;
  wire g_io_in_rx_dat_flitv;
  wire i_io_in_rx_dat_flitv;
  wire [421:0] g_io_in_rx_dat_flit;
  wire [421:0] i_io_in_rx_dat_flit;
  wire g_io_in_rx_snp_flitpend;
  wire i_io_in_rx_snp_flitpend;
  wire g_io_in_rx_snp_flitv;
  wire i_io_in_rx_snp_flitv;
  wire [114:0] g_io_in_rx_snp_flit;
  wire [114:0] i_io_in_rx_snp_flit;
  wire g_io_out_tx_req_valid;
  wire i_io_out_tx_req_valid;
  wire [3:0] g_io_out_tx_req_bits_qos;
  wire [3:0] i_io_out_tx_req_bits_qos;
  wire [10:0] g_io_out_tx_req_bits_srcID;
  wire [10:0] i_io_out_tx_req_bits_srcID;
  wire [11:0] g_io_out_tx_req_bits_txnID;
  wire [11:0] i_io_out_tx_req_bits_txnID;
  wire [10:0] g_io_out_tx_req_bits_returnNID;
  wire [10:0] i_io_out_tx_req_bits_returnNID;
  wire g_io_out_tx_req_bits_stashNIDValid;
  wire i_io_out_tx_req_bits_stashNIDValid;
  wire [11:0] g_io_out_tx_req_bits_returnTxnID;
  wire [11:0] i_io_out_tx_req_bits_returnTxnID;
  wire [6:0] g_io_out_tx_req_bits_opcode;
  wire [6:0] i_io_out_tx_req_bits_opcode;
  wire [2:0] g_io_out_tx_req_bits_size;
  wire [2:0] i_io_out_tx_req_bits_size;
  wire [47:0] g_io_out_tx_req_bits_addr;
  wire [47:0] i_io_out_tx_req_bits_addr;
  wire g_io_out_tx_req_bits_ns;
  wire i_io_out_tx_req_bits_ns;
  wire g_io_out_tx_req_bits_likelyshared;
  wire i_io_out_tx_req_bits_likelyshared;
  wire g_io_out_tx_req_bits_allowRetry;
  wire i_io_out_tx_req_bits_allowRetry;
  wire [1:0] g_io_out_tx_req_bits_order;
  wire [1:0] i_io_out_tx_req_bits_order;
  wire [3:0] g_io_out_tx_req_bits_pCrdType;
  wire [3:0] i_io_out_tx_req_bits_pCrdType;
  wire g_io_out_tx_req_bits_memAttr_allocate;
  wire i_io_out_tx_req_bits_memAttr_allocate;
  wire g_io_out_tx_req_bits_memAttr_cacheable;
  wire i_io_out_tx_req_bits_memAttr_cacheable;
  wire g_io_out_tx_req_bits_memAttr_device;
  wire i_io_out_tx_req_bits_memAttr_device;
  wire g_io_out_tx_req_bits_memAttr_ewa;
  wire i_io_out_tx_req_bits_memAttr_ewa;
  wire g_io_out_tx_req_bits_snpAttr;
  wire i_io_out_tx_req_bits_snpAttr;
  wire [7:0] g_io_out_tx_req_bits_lpIDWithPadding;
  wire [7:0] i_io_out_tx_req_bits_lpIDWithPadding;
  wire g_io_out_tx_req_bits_snoopMe;
  wire i_io_out_tx_req_bits_snoopMe;
  wire g_io_out_tx_req_bits_expCompAck;
  wire i_io_out_tx_req_bits_expCompAck;
  wire [1:0] g_io_out_tx_req_bits_tagOp;
  wire [1:0] i_io_out_tx_req_bits_tagOp;
  wire g_io_out_tx_req_bits_traceTag;
  wire i_io_out_tx_req_bits_traceTag;
  wire g_io_out_tx_req_bits_mpam_perfMonGroup;
  wire i_io_out_tx_req_bits_mpam_perfMonGroup;
  wire [8:0] g_io_out_tx_req_bits_mpam_partID;
  wire [8:0] i_io_out_tx_req_bits_mpam_partID;
  wire g_io_out_tx_req_bits_mpam_mpamNS;
  wire i_io_out_tx_req_bits_mpam_mpamNS;
  wire [3:0] g_io_out_tx_req_bits_rsvdc;
  wire [3:0] i_io_out_tx_req_bits_rsvdc;
  wire g_io_out_tx_rsp_valid;
  wire i_io_out_tx_rsp_valid;
  wire [3:0] g_io_out_tx_rsp_bits_qos;
  wire [3:0] i_io_out_tx_rsp_bits_qos;
  wire [10:0] g_io_out_tx_rsp_bits_tgtID;
  wire [10:0] i_io_out_tx_rsp_bits_tgtID;
  wire [10:0] g_io_out_tx_rsp_bits_srcID;
  wire [10:0] i_io_out_tx_rsp_bits_srcID;
  wire [11:0] g_io_out_tx_rsp_bits_txnID;
  wire [11:0] i_io_out_tx_rsp_bits_txnID;
  wire [4:0] g_io_out_tx_rsp_bits_opcode;
  wire [4:0] i_io_out_tx_rsp_bits_opcode;
  wire [1:0] g_io_out_tx_rsp_bits_respErr;
  wire [1:0] i_io_out_tx_rsp_bits_respErr;
  wire [2:0] g_io_out_tx_rsp_bits_resp;
  wire [2:0] i_io_out_tx_rsp_bits_resp;
  wire [2:0] g_io_out_tx_rsp_bits_fwdState;
  wire [2:0] i_io_out_tx_rsp_bits_fwdState;
  wire [2:0] g_io_out_tx_rsp_bits_cBusy;
  wire [2:0] i_io_out_tx_rsp_bits_cBusy;
  wire [11:0] g_io_out_tx_rsp_bits_dbID;
  wire [11:0] i_io_out_tx_rsp_bits_dbID;
  wire [3:0] g_io_out_tx_rsp_bits_pCrdType;
  wire [3:0] i_io_out_tx_rsp_bits_pCrdType;
  wire [1:0] g_io_out_tx_rsp_bits_tagOp;
  wire [1:0] i_io_out_tx_rsp_bits_tagOp;
  wire g_io_out_tx_rsp_bits_traceTag;
  wire i_io_out_tx_rsp_bits_traceTag;
  wire g_io_out_tx_dat_valid;
  wire i_io_out_tx_dat_valid;
  wire [3:0] g_io_out_tx_dat_bits_qos;
  wire [3:0] i_io_out_tx_dat_bits_qos;
  wire [10:0] g_io_out_tx_dat_bits_tgtID;
  wire [10:0] i_io_out_tx_dat_bits_tgtID;
  wire [10:0] g_io_out_tx_dat_bits_srcID;
  wire [10:0] i_io_out_tx_dat_bits_srcID;
  wire [11:0] g_io_out_tx_dat_bits_txnID;
  wire [11:0] i_io_out_tx_dat_bits_txnID;
  wire [10:0] g_io_out_tx_dat_bits_homeNID;
  wire [10:0] i_io_out_tx_dat_bits_homeNID;
  wire [3:0] g_io_out_tx_dat_bits_opcode;
  wire [3:0] i_io_out_tx_dat_bits_opcode;
  wire [1:0] g_io_out_tx_dat_bits_respErr;
  wire [1:0] i_io_out_tx_dat_bits_respErr;
  wire [2:0] g_io_out_tx_dat_bits_resp;
  wire [2:0] i_io_out_tx_dat_bits_resp;
  wire [3:0] g_io_out_tx_dat_bits_dataSource;
  wire [3:0] i_io_out_tx_dat_bits_dataSource;
  wire [2:0] g_io_out_tx_dat_bits_cBusy;
  wire [2:0] i_io_out_tx_dat_bits_cBusy;
  wire [11:0] g_io_out_tx_dat_bits_dbID;
  wire [11:0] i_io_out_tx_dat_bits_dbID;
  wire [1:0] g_io_out_tx_dat_bits_ccID;
  wire [1:0] i_io_out_tx_dat_bits_ccID;
  wire [1:0] g_io_out_tx_dat_bits_dataID;
  wire [1:0] i_io_out_tx_dat_bits_dataID;
  wire [1:0] g_io_out_tx_dat_bits_tagOp;
  wire [1:0] i_io_out_tx_dat_bits_tagOp;
  wire [7:0] g_io_out_tx_dat_bits_tag;
  wire [7:0] i_io_out_tx_dat_bits_tag;
  wire [1:0] g_io_out_tx_dat_bits_tu;
  wire [1:0] i_io_out_tx_dat_bits_tu;
  wire g_io_out_tx_dat_bits_traceTag;
  wire i_io_out_tx_dat_bits_traceTag;
  wire [3:0] g_io_out_tx_dat_bits_rsvdc;
  wire [3:0] i_io_out_tx_dat_bits_rsvdc;
  wire [31:0] g_io_out_tx_dat_bits_be;
  wire [31:0] i_io_out_tx_dat_bits_be;
  wire [255:0] g_io_out_tx_dat_bits_data;
  wire [255:0] i_io_out_tx_dat_bits_data;
  wire [31:0] g_io_out_tx_dat_bits_dataCheck;
  wire [31:0] i_io_out_tx_dat_bits_dataCheck;
  wire [3:0] g_io_out_tx_dat_bits_poison;
  wire [3:0] i_io_out_tx_dat_bits_poison;
  wire g_io_out_rx_rsp_ready;
  wire i_io_out_rx_rsp_ready;
  wire g_io_out_rx_dat_ready;
  wire i_io_out_rx_dat_ready;
  wire g_io_out_rx_snp_ready;
  wire i_io_out_rx_snp_ready;

  ReceiverLinkMonitor u_g (
    .clock(clock),
    .reset(reset),
    .io_in_txsactive(io_in_txsactive),
    .io_in_rxsactive(g_io_in_rxsactive),
    .io_in_syscoreq(io_in_syscoreq),
    .io_in_syscoack(g_io_in_syscoack),
    .io_in_tx_linkactivereq(io_in_tx_linkactivereq),
    .io_in_tx_linkactiveack(g_io_in_tx_linkactiveack),
    .io_in_tx_req_flitpend(io_in_tx_req_flitpend),
    .io_in_tx_req_flitv(io_in_tx_req_flitv),
    .io_in_tx_req_flit(io_in_tx_req_flit),
    .io_in_tx_req_lcrdv(g_io_in_tx_req_lcrdv),
    .io_in_tx_rsp_flitpend(io_in_tx_rsp_flitpend),
    .io_in_tx_rsp_flitv(io_in_tx_rsp_flitv),
    .io_in_tx_rsp_flit(io_in_tx_rsp_flit),
    .io_in_tx_rsp_lcrdv(g_io_in_tx_rsp_lcrdv),
    .io_in_tx_dat_flitpend(io_in_tx_dat_flitpend),
    .io_in_tx_dat_flitv(io_in_tx_dat_flitv),
    .io_in_tx_dat_flit(io_in_tx_dat_flit),
    .io_in_tx_dat_lcrdv(g_io_in_tx_dat_lcrdv),
    .io_in_rx_linkactivereq(g_io_in_rx_linkactivereq),
    .io_in_rx_linkactiveack(io_in_rx_linkactiveack),
    .io_in_rx_rsp_flitpend(g_io_in_rx_rsp_flitpend),
    .io_in_rx_rsp_flitv(g_io_in_rx_rsp_flitv),
    .io_in_rx_rsp_flit(g_io_in_rx_rsp_flit),
    .io_in_rx_rsp_lcrdv(io_in_rx_rsp_lcrdv),
    .io_in_rx_dat_flitpend(g_io_in_rx_dat_flitpend),
    .io_in_rx_dat_flitv(g_io_in_rx_dat_flitv),
    .io_in_rx_dat_flit(g_io_in_rx_dat_flit),
    .io_in_rx_dat_lcrdv(io_in_rx_dat_lcrdv),
    .io_in_rx_snp_flitpend(g_io_in_rx_snp_flitpend),
    .io_in_rx_snp_flitv(g_io_in_rx_snp_flitv),
    .io_in_rx_snp_flit(g_io_in_rx_snp_flit),
    .io_in_rx_snp_lcrdv(io_in_rx_snp_lcrdv),
    .io_out_tx_req_ready(io_out_tx_req_ready),
    .io_out_tx_req_valid(g_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos(g_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_srcID(g_io_out_tx_req_bits_srcID),
    .io_out_tx_req_bits_txnID(g_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID(g_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid(g_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID(g_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode(g_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_size(g_io_out_tx_req_bits_size),
    .io_out_tx_req_bits_addr(g_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns(g_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared(g_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry(g_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order(g_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType(g_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate(g_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable(g_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device(g_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa(g_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr(g_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding(g_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe(g_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck(g_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp(g_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag(g_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup(g_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID(g_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS(g_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc(g_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready(io_out_tx_rsp_ready),
    .io_out_tx_rsp_valid(g_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos(g_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID(g_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_srcID(g_io_out_tx_rsp_bits_srcID),
    .io_out_tx_rsp_bits_txnID(g_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode(g_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr(g_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp(g_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState(g_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy(g_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID(g_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType(g_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp(g_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag(g_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready(io_out_tx_dat_ready),
    .io_out_tx_dat_valid(g_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_qos(g_io_out_tx_dat_bits_qos),
    .io_out_tx_dat_bits_tgtID(g_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_srcID(g_io_out_tx_dat_bits_srcID),
    .io_out_tx_dat_bits_txnID(g_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID(g_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode(g_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr(g_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp(g_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource(g_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_cBusy(g_io_out_tx_dat_bits_cBusy),
    .io_out_tx_dat_bits_dbID(g_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID(g_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID(g_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_tagOp(g_io_out_tx_dat_bits_tagOp),
    .io_out_tx_dat_bits_tag(g_io_out_tx_dat_bits_tag),
    .io_out_tx_dat_bits_tu(g_io_out_tx_dat_bits_tu),
    .io_out_tx_dat_bits_traceTag(g_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_rsvdc(g_io_out_tx_dat_bits_rsvdc),
    .io_out_tx_dat_bits_be(g_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data(g_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck(g_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison(g_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_ready(g_io_out_rx_rsp_ready),
    .io_out_rx_rsp_valid(io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_qos(io_out_rx_rsp_bits_qos),
    .io_out_rx_rsp_bits_tgtID(io_out_rx_rsp_bits_tgtID),
    .io_out_rx_rsp_bits_srcID(io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID(io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode(io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_respErr(io_out_rx_rsp_bits_respErr),
    .io_out_rx_rsp_bits_resp(io_out_rx_rsp_bits_resp),
    .io_out_rx_rsp_bits_fwdState(io_out_rx_rsp_bits_fwdState),
    .io_out_rx_rsp_bits_cBusy(io_out_rx_rsp_bits_cBusy),
    .io_out_rx_rsp_bits_dbID(io_out_rx_rsp_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType(io_out_rx_rsp_bits_pCrdType),
    .io_out_rx_rsp_bits_tagOp(io_out_rx_rsp_bits_tagOp),
    .io_out_rx_rsp_bits_traceTag(io_out_rx_rsp_bits_traceTag),
    .io_out_rx_dat_ready(g_io_out_rx_dat_ready),
    .io_out_rx_dat_valid(io_out_rx_dat_valid),
    .io_out_rx_dat_bits_qos(io_out_rx_dat_bits_qos),
    .io_out_rx_dat_bits_tgtID(io_out_rx_dat_bits_tgtID),
    .io_out_rx_dat_bits_srcID(io_out_rx_dat_bits_srcID),
    .io_out_rx_dat_bits_txnID(io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_homeNID(io_out_rx_dat_bits_homeNID),
    .io_out_rx_dat_bits_opcode(io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_respErr(io_out_rx_dat_bits_respErr),
    .io_out_rx_dat_bits_resp(io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dataSource(io_out_rx_dat_bits_dataSource),
    .io_out_rx_dat_bits_cBusy(io_out_rx_dat_bits_cBusy),
    .io_out_rx_dat_bits_dbID(io_out_rx_dat_bits_dbID),
    .io_out_rx_dat_bits_ccID(io_out_rx_dat_bits_ccID),
    .io_out_rx_dat_bits_dataID(io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_tagOp(io_out_rx_dat_bits_tagOp),
    .io_out_rx_dat_bits_tag(io_out_rx_dat_bits_tag),
    .io_out_rx_dat_bits_tu(io_out_rx_dat_bits_tu),
    .io_out_rx_dat_bits_traceTag(io_out_rx_dat_bits_traceTag),
    .io_out_rx_dat_bits_rsvdc(io_out_rx_dat_bits_rsvdc),
    .io_out_rx_dat_bits_be(io_out_rx_dat_bits_be),
    .io_out_rx_dat_bits_data(io_out_rx_dat_bits_data),
    .io_out_rx_dat_bits_dataCheck(io_out_rx_dat_bits_dataCheck),
    .io_out_rx_dat_bits_poison(io_out_rx_dat_bits_poison),
    .io_out_rx_snp_ready(g_io_out_rx_snp_ready),
    .io_out_rx_snp_valid(io_out_rx_snp_valid),
    .io_out_rx_snp_bits_qos(io_out_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID(io_out_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID(io_out_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID(io_out_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID(io_out_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode(io_out_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr(io_out_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns(io_out_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD(io_out_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc(io_out_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag(io_out_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup(io_out_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID(io_out_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS(io_out_rx_snp_bits_mpam_mpamNS)
  );

  ReceiverLinkMonitor_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_txsactive(io_in_txsactive),
    .io_in_rxsactive(i_io_in_rxsactive),
    .io_in_syscoreq(io_in_syscoreq),
    .io_in_syscoack(i_io_in_syscoack),
    .io_in_tx_linkactivereq(io_in_tx_linkactivereq),
    .io_in_tx_linkactiveack(i_io_in_tx_linkactiveack),
    .io_in_tx_req_flitpend(io_in_tx_req_flitpend),
    .io_in_tx_req_flitv(io_in_tx_req_flitv),
    .io_in_tx_req_flit(io_in_tx_req_flit),
    .io_in_tx_req_lcrdv(i_io_in_tx_req_lcrdv),
    .io_in_tx_rsp_flitpend(io_in_tx_rsp_flitpend),
    .io_in_tx_rsp_flitv(io_in_tx_rsp_flitv),
    .io_in_tx_rsp_flit(io_in_tx_rsp_flit),
    .io_in_tx_rsp_lcrdv(i_io_in_tx_rsp_lcrdv),
    .io_in_tx_dat_flitpend(io_in_tx_dat_flitpend),
    .io_in_tx_dat_flitv(io_in_tx_dat_flitv),
    .io_in_tx_dat_flit(io_in_tx_dat_flit),
    .io_in_tx_dat_lcrdv(i_io_in_tx_dat_lcrdv),
    .io_in_rx_linkactivereq(i_io_in_rx_linkactivereq),
    .io_in_rx_linkactiveack(io_in_rx_linkactiveack),
    .io_in_rx_rsp_flitpend(i_io_in_rx_rsp_flitpend),
    .io_in_rx_rsp_flitv(i_io_in_rx_rsp_flitv),
    .io_in_rx_rsp_flit(i_io_in_rx_rsp_flit),
    .io_in_rx_rsp_lcrdv(io_in_rx_rsp_lcrdv),
    .io_in_rx_dat_flitpend(i_io_in_rx_dat_flitpend),
    .io_in_rx_dat_flitv(i_io_in_rx_dat_flitv),
    .io_in_rx_dat_flit(i_io_in_rx_dat_flit),
    .io_in_rx_dat_lcrdv(io_in_rx_dat_lcrdv),
    .io_in_rx_snp_flitpend(i_io_in_rx_snp_flitpend),
    .io_in_rx_snp_flitv(i_io_in_rx_snp_flitv),
    .io_in_rx_snp_flit(i_io_in_rx_snp_flit),
    .io_in_rx_snp_lcrdv(io_in_rx_snp_lcrdv),
    .io_out_tx_req_ready(io_out_tx_req_ready),
    .io_out_tx_req_valid(i_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos(i_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_srcID(i_io_out_tx_req_bits_srcID),
    .io_out_tx_req_bits_txnID(i_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID(i_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid(i_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID(i_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode(i_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_size(i_io_out_tx_req_bits_size),
    .io_out_tx_req_bits_addr(i_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns(i_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared(i_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry(i_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order(i_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType(i_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate(i_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable(i_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device(i_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa(i_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr(i_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding(i_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe(i_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck(i_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp(i_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag(i_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup(i_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID(i_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS(i_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc(i_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready(io_out_tx_rsp_ready),
    .io_out_tx_rsp_valid(i_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos(i_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID(i_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_srcID(i_io_out_tx_rsp_bits_srcID),
    .io_out_tx_rsp_bits_txnID(i_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode(i_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr(i_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp(i_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState(i_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy(i_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID(i_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType(i_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp(i_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag(i_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready(io_out_tx_dat_ready),
    .io_out_tx_dat_valid(i_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_qos(i_io_out_tx_dat_bits_qos),
    .io_out_tx_dat_bits_tgtID(i_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_srcID(i_io_out_tx_dat_bits_srcID),
    .io_out_tx_dat_bits_txnID(i_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID(i_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode(i_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr(i_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp(i_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource(i_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_cBusy(i_io_out_tx_dat_bits_cBusy),
    .io_out_tx_dat_bits_dbID(i_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID(i_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID(i_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_tagOp(i_io_out_tx_dat_bits_tagOp),
    .io_out_tx_dat_bits_tag(i_io_out_tx_dat_bits_tag),
    .io_out_tx_dat_bits_tu(i_io_out_tx_dat_bits_tu),
    .io_out_tx_dat_bits_traceTag(i_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_rsvdc(i_io_out_tx_dat_bits_rsvdc),
    .io_out_tx_dat_bits_be(i_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data(i_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck(i_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison(i_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_ready(i_io_out_rx_rsp_ready),
    .io_out_rx_rsp_valid(io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_qos(io_out_rx_rsp_bits_qos),
    .io_out_rx_rsp_bits_tgtID(io_out_rx_rsp_bits_tgtID),
    .io_out_rx_rsp_bits_srcID(io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID(io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode(io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_respErr(io_out_rx_rsp_bits_respErr),
    .io_out_rx_rsp_bits_resp(io_out_rx_rsp_bits_resp),
    .io_out_rx_rsp_bits_fwdState(io_out_rx_rsp_bits_fwdState),
    .io_out_rx_rsp_bits_cBusy(io_out_rx_rsp_bits_cBusy),
    .io_out_rx_rsp_bits_dbID(io_out_rx_rsp_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType(io_out_rx_rsp_bits_pCrdType),
    .io_out_rx_rsp_bits_tagOp(io_out_rx_rsp_bits_tagOp),
    .io_out_rx_rsp_bits_traceTag(io_out_rx_rsp_bits_traceTag),
    .io_out_rx_dat_ready(i_io_out_rx_dat_ready),
    .io_out_rx_dat_valid(io_out_rx_dat_valid),
    .io_out_rx_dat_bits_qos(io_out_rx_dat_bits_qos),
    .io_out_rx_dat_bits_tgtID(io_out_rx_dat_bits_tgtID),
    .io_out_rx_dat_bits_srcID(io_out_rx_dat_bits_srcID),
    .io_out_rx_dat_bits_txnID(io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_homeNID(io_out_rx_dat_bits_homeNID),
    .io_out_rx_dat_bits_opcode(io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_respErr(io_out_rx_dat_bits_respErr),
    .io_out_rx_dat_bits_resp(io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dataSource(io_out_rx_dat_bits_dataSource),
    .io_out_rx_dat_bits_cBusy(io_out_rx_dat_bits_cBusy),
    .io_out_rx_dat_bits_dbID(io_out_rx_dat_bits_dbID),
    .io_out_rx_dat_bits_ccID(io_out_rx_dat_bits_ccID),
    .io_out_rx_dat_bits_dataID(io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_tagOp(io_out_rx_dat_bits_tagOp),
    .io_out_rx_dat_bits_tag(io_out_rx_dat_bits_tag),
    .io_out_rx_dat_bits_tu(io_out_rx_dat_bits_tu),
    .io_out_rx_dat_bits_traceTag(io_out_rx_dat_bits_traceTag),
    .io_out_rx_dat_bits_rsvdc(io_out_rx_dat_bits_rsvdc),
    .io_out_rx_dat_bits_be(io_out_rx_dat_bits_be),
    .io_out_rx_dat_bits_data(io_out_rx_dat_bits_data),
    .io_out_rx_dat_bits_dataCheck(io_out_rx_dat_bits_dataCheck),
    .io_out_rx_dat_bits_poison(io_out_rx_dat_bits_poison),
    .io_out_rx_snp_ready(i_io_out_rx_snp_ready),
    .io_out_rx_snp_valid(io_out_rx_snp_valid),
    .io_out_rx_snp_bits_qos(io_out_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID(io_out_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID(io_out_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID(io_out_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID(io_out_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode(io_out_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr(io_out_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns(io_out_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD(io_out_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc(io_out_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag(io_out_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup(io_out_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID(io_out_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS(io_out_rx_snp_bits_mpam_mpamNS)
  );

  task automatic drive_random_inputs();
    io_in_txsactive <= $urandom_range(0, 1);
    io_in_syscoreq <= $urandom_range(0, 1);
    io_in_tx_linkactivereq <= $urandom_range(0, 1);
    io_in_tx_req_flitpend <= $urandom_range(0, 1);
    io_in_tx_req_flitv <= $urandom_range(0, 1);
    io_in_tx_req_flit <= 162'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_tx_rsp_flitpend <= $urandom_range(0, 1);
    io_in_tx_rsp_flitv <= $urandom_range(0, 1);
    io_in_tx_rsp_flit <= 73'({$urandom, $urandom, $urandom});
    io_in_tx_dat_flitpend <= $urandom_range(0, 1);
    io_in_tx_dat_flitv <= $urandom_range(0, 1);
    io_in_tx_dat_flit <= 422'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_rx_linkactiveack <= $urandom_range(0, 1);
    io_in_rx_rsp_lcrdv <= $urandom_range(0, 1);
    io_in_rx_dat_lcrdv <= $urandom_range(0, 1);
    io_in_rx_snp_lcrdv <= $urandom_range(0, 1);
    io_out_tx_req_ready <= $urandom_range(0, 1);
    io_out_tx_rsp_ready <= $urandom_range(0, 1);
    io_out_tx_dat_ready <= $urandom_range(0, 1);
    io_out_rx_rsp_valid <= $urandom_range(0, 1);
    io_out_rx_rsp_bits_qos <= 4'({$urandom});
    io_out_rx_rsp_bits_tgtID <= 11'({$urandom});
    io_out_rx_rsp_bits_srcID <= 11'({$urandom});
    io_out_rx_rsp_bits_txnID <= 12'({$urandom});
    io_out_rx_rsp_bits_opcode <= 5'({$urandom});
    io_out_rx_rsp_bits_respErr <= 2'({$urandom});
    io_out_rx_rsp_bits_resp <= 3'({$urandom});
    io_out_rx_rsp_bits_fwdState <= 3'({$urandom});
    io_out_rx_rsp_bits_cBusy <= 3'({$urandom});
    io_out_rx_rsp_bits_dbID <= 12'({$urandom});
    io_out_rx_rsp_bits_pCrdType <= 4'({$urandom});
    io_out_rx_rsp_bits_tagOp <= 2'({$urandom});
    io_out_rx_rsp_bits_traceTag <= $urandom_range(0, 1);
    io_out_rx_dat_valid <= $urandom_range(0, 1);
    io_out_rx_dat_bits_qos <= 4'({$urandom});
    io_out_rx_dat_bits_tgtID <= 11'({$urandom});
    io_out_rx_dat_bits_srcID <= 11'({$urandom});
    io_out_rx_dat_bits_txnID <= 12'({$urandom});
    io_out_rx_dat_bits_homeNID <= 11'({$urandom});
    io_out_rx_dat_bits_opcode <= 4'({$urandom});
    io_out_rx_dat_bits_respErr <= 2'({$urandom});
    io_out_rx_dat_bits_resp <= 3'({$urandom});
    io_out_rx_dat_bits_dataSource <= 4'({$urandom});
    io_out_rx_dat_bits_cBusy <= 3'({$urandom});
    io_out_rx_dat_bits_dbID <= 12'({$urandom});
    io_out_rx_dat_bits_ccID <= 2'({$urandom});
    io_out_rx_dat_bits_dataID <= 2'({$urandom});
    io_out_rx_dat_bits_tagOp <= 2'({$urandom});
    io_out_rx_dat_bits_tag <= 8'({$urandom});
    io_out_rx_dat_bits_tu <= 2'({$urandom});
    io_out_rx_dat_bits_traceTag <= $urandom_range(0, 1);
    io_out_rx_dat_bits_rsvdc <= 4'({$urandom});
    io_out_rx_dat_bits_be <= 32'({$urandom});
    io_out_rx_dat_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_out_rx_dat_bits_dataCheck <= 32'({$urandom});
    io_out_rx_dat_bits_poison <= 4'({$urandom});
    io_out_rx_snp_valid <= $urandom_range(0, 1);
    io_out_rx_snp_bits_qos <= 4'({$urandom});
    io_out_rx_snp_bits_srcID <= 11'({$urandom});
    io_out_rx_snp_bits_txnID <= 12'({$urandom});
    io_out_rx_snp_bits_fwdNID <= 11'({$urandom});
    io_out_rx_snp_bits_fwdTxnID <= 12'({$urandom});
    io_out_rx_snp_bits_opcode <= 5'({$urandom});
    io_out_rx_snp_bits_addr <= 45'({$urandom, $urandom});
    io_out_rx_snp_bits_ns <= $urandom_range(0, 1);
    io_out_rx_snp_bits_doNotGoToSD <= $urandom_range(0, 1);
    io_out_rx_snp_bits_retToSrc <= $urandom_range(0, 1);
    io_out_rx_snp_bits_traceTag <= $urandom_range(0, 1);
    io_out_rx_snp_bits_mpam_perfMonGroup <= $urandom_range(0, 1);
    io_out_rx_snp_bits_mpam_partID <= 9'({$urandom});
    io_out_rx_snp_bits_mpam_mpamNS <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(io_in_rxsactive)
    `CHECK(io_in_syscoack)
    `CHECK(io_in_tx_linkactiveack)
    `CHECK(io_in_tx_req_lcrdv)
    `CHECK(io_in_tx_rsp_lcrdv)
    `CHECK(io_in_tx_dat_lcrdv)
    `CHECK(io_in_rx_linkactivereq)
    `CHECK(io_in_rx_rsp_flitpend)
    `CHECK(io_in_rx_rsp_flitv)
    `CHECK(io_in_rx_rsp_flit)
    `CHECK(io_in_rx_dat_flitpend)
    `CHECK(io_in_rx_dat_flitv)
    `CHECK(io_in_rx_dat_flit)
    `CHECK(io_in_rx_snp_flitpend)
    `CHECK(io_in_rx_snp_flitv)
    `CHECK(io_in_rx_snp_flit)
    `CHECK(io_out_tx_req_valid)
    `CHECK(io_out_tx_req_bits_qos)
    `CHECK(io_out_tx_req_bits_srcID)
    `CHECK(io_out_tx_req_bits_txnID)
    `CHECK(io_out_tx_req_bits_returnNID)
    `CHECK(io_out_tx_req_bits_stashNIDValid)
    `CHECK(io_out_tx_req_bits_returnTxnID)
    `CHECK(io_out_tx_req_bits_opcode)
    `CHECK(io_out_tx_req_bits_size)
    `CHECK(io_out_tx_req_bits_addr)
    `CHECK(io_out_tx_req_bits_ns)
    `CHECK(io_out_tx_req_bits_likelyshared)
    `CHECK(io_out_tx_req_bits_allowRetry)
    `CHECK(io_out_tx_req_bits_order)
    `CHECK(io_out_tx_req_bits_pCrdType)
    `CHECK(io_out_tx_req_bits_memAttr_allocate)
    `CHECK(io_out_tx_req_bits_memAttr_cacheable)
    `CHECK(io_out_tx_req_bits_memAttr_device)
    `CHECK(io_out_tx_req_bits_memAttr_ewa)
    `CHECK(io_out_tx_req_bits_snpAttr)
    `CHECK(io_out_tx_req_bits_lpIDWithPadding)
    `CHECK(io_out_tx_req_bits_snoopMe)
    `CHECK(io_out_tx_req_bits_expCompAck)
    `CHECK(io_out_tx_req_bits_tagOp)
    `CHECK(io_out_tx_req_bits_traceTag)
    `CHECK(io_out_tx_req_bits_mpam_perfMonGroup)
    `CHECK(io_out_tx_req_bits_mpam_partID)
    `CHECK(io_out_tx_req_bits_mpam_mpamNS)
    `CHECK(io_out_tx_req_bits_rsvdc)
    `CHECK(io_out_tx_rsp_valid)
    `CHECK(io_out_tx_rsp_bits_qos)
    `CHECK(io_out_tx_rsp_bits_tgtID)
    `CHECK(io_out_tx_rsp_bits_srcID)
    `CHECK(io_out_tx_rsp_bits_txnID)
    `CHECK(io_out_tx_rsp_bits_opcode)
    `CHECK(io_out_tx_rsp_bits_respErr)
    `CHECK(io_out_tx_rsp_bits_resp)
    `CHECK(io_out_tx_rsp_bits_fwdState)
    `CHECK(io_out_tx_rsp_bits_cBusy)
    `CHECK(io_out_tx_rsp_bits_dbID)
    `CHECK(io_out_tx_rsp_bits_pCrdType)
    `CHECK(io_out_tx_rsp_bits_tagOp)
    `CHECK(io_out_tx_rsp_bits_traceTag)
    `CHECK(io_out_tx_dat_valid)
    `CHECK(io_out_tx_dat_bits_qos)
    `CHECK(io_out_tx_dat_bits_tgtID)
    `CHECK(io_out_tx_dat_bits_srcID)
    `CHECK(io_out_tx_dat_bits_txnID)
    `CHECK(io_out_tx_dat_bits_homeNID)
    `CHECK(io_out_tx_dat_bits_opcode)
    `CHECK(io_out_tx_dat_bits_respErr)
    `CHECK(io_out_tx_dat_bits_resp)
    `CHECK(io_out_tx_dat_bits_dataSource)
    `CHECK(io_out_tx_dat_bits_cBusy)
    `CHECK(io_out_tx_dat_bits_dbID)
    `CHECK(io_out_tx_dat_bits_ccID)
    `CHECK(io_out_tx_dat_bits_dataID)
    `CHECK(io_out_tx_dat_bits_tagOp)
    `CHECK(io_out_tx_dat_bits_tag)
    `CHECK(io_out_tx_dat_bits_tu)
    `CHECK(io_out_tx_dat_bits_traceTag)
    `CHECK(io_out_tx_dat_bits_rsvdc)
    `CHECK(io_out_tx_dat_bits_be)
    `CHECK(io_out_tx_dat_bits_data)
    `CHECK(io_out_tx_dat_bits_dataCheck)
    `CHECK(io_out_tx_dat_bits_poison)
    `CHECK(io_out_rx_rsp_ready)
    `CHECK(io_out_rx_dat_ready)
    `CHECK(io_out_rx_snp_ready)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_txsactive = '0;
    io_in_syscoreq = '0;
    io_in_tx_linkactivereq = '0;
    io_in_tx_req_flitpend = '0;
    io_in_tx_req_flitv = '0;
    io_in_tx_req_flit = '0;
    io_in_tx_rsp_flitpend = '0;
    io_in_tx_rsp_flitv = '0;
    io_in_tx_rsp_flit = '0;
    io_in_tx_dat_flitpend = '0;
    io_in_tx_dat_flitv = '0;
    io_in_tx_dat_flit = '0;
    io_in_rx_linkactiveack = '0;
    io_in_rx_rsp_lcrdv = '0;
    io_in_rx_dat_lcrdv = '0;
    io_in_rx_snp_lcrdv = '0;
    io_out_tx_req_ready = '0;
    io_out_tx_rsp_ready = '0;
    io_out_tx_dat_ready = '0;
    io_out_rx_rsp_valid = '0;
    io_out_rx_rsp_bits_qos = '0;
    io_out_rx_rsp_bits_tgtID = '0;
    io_out_rx_rsp_bits_srcID = '0;
    io_out_rx_rsp_bits_txnID = '0;
    io_out_rx_rsp_bits_opcode = '0;
    io_out_rx_rsp_bits_respErr = '0;
    io_out_rx_rsp_bits_resp = '0;
    io_out_rx_rsp_bits_fwdState = '0;
    io_out_rx_rsp_bits_cBusy = '0;
    io_out_rx_rsp_bits_dbID = '0;
    io_out_rx_rsp_bits_pCrdType = '0;
    io_out_rx_rsp_bits_tagOp = '0;
    io_out_rx_rsp_bits_traceTag = '0;
    io_out_rx_dat_valid = '0;
    io_out_rx_dat_bits_qos = '0;
    io_out_rx_dat_bits_tgtID = '0;
    io_out_rx_dat_bits_srcID = '0;
    io_out_rx_dat_bits_txnID = '0;
    io_out_rx_dat_bits_homeNID = '0;
    io_out_rx_dat_bits_opcode = '0;
    io_out_rx_dat_bits_respErr = '0;
    io_out_rx_dat_bits_resp = '0;
    io_out_rx_dat_bits_dataSource = '0;
    io_out_rx_dat_bits_cBusy = '0;
    io_out_rx_dat_bits_dbID = '0;
    io_out_rx_dat_bits_ccID = '0;
    io_out_rx_dat_bits_dataID = '0;
    io_out_rx_dat_bits_tagOp = '0;
    io_out_rx_dat_bits_tag = '0;
    io_out_rx_dat_bits_tu = '0;
    io_out_rx_dat_bits_traceTag = '0;
    io_out_rx_dat_bits_rsvdc = '0;
    io_out_rx_dat_bits_be = '0;
    io_out_rx_dat_bits_data = '0;
    io_out_rx_dat_bits_dataCheck = '0;
    io_out_rx_dat_bits_poison = '0;
    io_out_rx_snp_valid = '0;
    io_out_rx_snp_bits_qos = '0;
    io_out_rx_snp_bits_srcID = '0;
    io_out_rx_snp_bits_txnID = '0;
    io_out_rx_snp_bits_fwdNID = '0;
    io_out_rx_snp_bits_fwdTxnID = '0;
    io_out_rx_snp_bits_opcode = '0;
    io_out_rx_snp_bits_addr = '0;
    io_out_rx_snp_bits_ns = '0;
    io_out_rx_snp_bits_doNotGoToSD = '0;
    io_out_rx_snp_bits_retToSrc = '0;
    io_out_rx_snp_bits_traceTag = '0;
    io_out_rx_snp_bits_mpam_perfMonGroup = '0;
    io_out_rx_snp_bits_mpam_partID = '0;
    io_out_rx_snp_bits_mpam_mpamNS = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("ReceiverLinkMonitor checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
