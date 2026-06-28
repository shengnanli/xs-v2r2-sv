// 自动生成：scripts/gen_linkmonitor.py —— 勿手改
// LinkMonitor 双例化逐拍比对: golden LinkMonitor vs 可读 LinkMonitor_xs。
// 激励: 全输入随机 —— linkactiveack/linkactivereq 覆盖 LINKACTIVE 4 态转换,
//       syscoack 覆盖 txsactive, flit/flitv/lcrdv/valid 覆盖子模块与 L-Credit
//       reclaim (rx 去激活) 路径。两侧共用 golden 子模块, 比对聚焦本核逻辑。
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

  logic io_in_tx_req_valid;
  logic [3:0] io_in_tx_req_bits_qos;
  logic [10:0] io_in_tx_req_bits_tgtID;
  logic [11:0] io_in_tx_req_bits_txnID;
  logic [10:0] io_in_tx_req_bits_returnNID;
  logic io_in_tx_req_bits_stashNIDValid;
  logic [11:0] io_in_tx_req_bits_returnTxnID;
  logic [6:0] io_in_tx_req_bits_opcode;
  logic [2:0] io_in_tx_req_bits_size;
  logic [47:0] io_in_tx_req_bits_addr;
  logic io_in_tx_req_bits_ns;
  logic io_in_tx_req_bits_likelyshared;
  logic io_in_tx_req_bits_allowRetry;
  logic [1:0] io_in_tx_req_bits_order;
  logic [3:0] io_in_tx_req_bits_pCrdType;
  logic io_in_tx_req_bits_memAttr_allocate;
  logic io_in_tx_req_bits_memAttr_cacheable;
  logic io_in_tx_req_bits_memAttr_device;
  logic io_in_tx_req_bits_memAttr_ewa;
  logic io_in_tx_req_bits_snpAttr;
  logic [7:0] io_in_tx_req_bits_lpIDWithPadding;
  logic io_in_tx_req_bits_snoopMe;
  logic io_in_tx_req_bits_expCompAck;
  logic [1:0] io_in_tx_req_bits_tagOp;
  logic io_in_tx_req_bits_traceTag;
  logic io_in_tx_req_bits_mpam_perfMonGroup;
  logic [8:0] io_in_tx_req_bits_mpam_partID;
  logic io_in_tx_req_bits_mpam_mpamNS;
  logic [3:0] io_in_tx_req_bits_rsvdc;
  logic io_in_tx_rsp_valid;
  logic [3:0] io_in_tx_rsp_bits_qos;
  logic [10:0] io_in_tx_rsp_bits_tgtID;
  logic [11:0] io_in_tx_rsp_bits_txnID;
  logic [4:0] io_in_tx_rsp_bits_opcode;
  logic [1:0] io_in_tx_rsp_bits_respErr;
  logic [2:0] io_in_tx_rsp_bits_resp;
  logic [2:0] io_in_tx_rsp_bits_fwdState;
  logic [2:0] io_in_tx_rsp_bits_cBusy;
  logic [11:0] io_in_tx_rsp_bits_dbID;
  logic [3:0] io_in_tx_rsp_bits_pCrdType;
  logic [1:0] io_in_tx_rsp_bits_tagOp;
  logic io_in_tx_rsp_bits_traceTag;
  logic io_in_tx_dat_valid;
  logic [3:0] io_in_tx_dat_bits_qos;
  logic [10:0] io_in_tx_dat_bits_tgtID;
  logic [11:0] io_in_tx_dat_bits_txnID;
  logic [10:0] io_in_tx_dat_bits_homeNID;
  logic [3:0] io_in_tx_dat_bits_opcode;
  logic [1:0] io_in_tx_dat_bits_respErr;
  logic [2:0] io_in_tx_dat_bits_resp;
  logic [3:0] io_in_tx_dat_bits_dataSource;
  logic [2:0] io_in_tx_dat_bits_cBusy;
  logic [11:0] io_in_tx_dat_bits_dbID;
  logic [1:0] io_in_tx_dat_bits_ccID;
  logic [1:0] io_in_tx_dat_bits_dataID;
  logic [1:0] io_in_tx_dat_bits_tagOp;
  logic [7:0] io_in_tx_dat_bits_tag;
  logic [1:0] io_in_tx_dat_bits_tu;
  logic io_in_tx_dat_bits_traceTag;
  logic [3:0] io_in_tx_dat_bits_rsvdc;
  logic [31:0] io_in_tx_dat_bits_be;
  logic [255:0] io_in_tx_dat_bits_data;
  logic [31:0] io_in_tx_dat_bits_dataCheck;
  logic [3:0] io_in_tx_dat_bits_poison;
  logic io_in_rx_rsp_ready;
  logic io_in_rx_dat_ready;
  logic io_in_rx_snp_ready;
  logic io_out_rxsactive;
  logic io_out_syscoack;
  logic io_out_tx_linkactiveack;
  logic io_out_tx_req_lcrdv;
  logic io_out_tx_rsp_lcrdv;
  logic io_out_tx_dat_lcrdv;
  logic io_out_rx_linkactivereq;
  logic io_out_rx_rsp_flitpend;
  logic io_out_rx_rsp_flitv;
  logic [72:0] io_out_rx_rsp_flit;
  logic io_out_rx_dat_flitpend;
  logic io_out_rx_dat_flitv;
  logic [421:0] io_out_rx_dat_flit;
  logic io_out_rx_snp_flitpend;
  logic io_out_rx_snp_flitv;
  logic [114:0] io_out_rx_snp_flit;
  logic [10:0] io_nodeID;
  wire g_io_in_tx_req_ready;
  wire i_io_in_tx_req_ready;
  wire g_io_in_tx_rsp_ready;
  wire i_io_in_tx_rsp_ready;
  wire g_io_in_tx_dat_ready;
  wire i_io_in_tx_dat_ready;
  wire g_io_in_rx_rsp_valid;
  wire i_io_in_rx_rsp_valid;
  wire [3:0] g_io_in_rx_rsp_bits_qos;
  wire [3:0] i_io_in_rx_rsp_bits_qos;
  wire [10:0] g_io_in_rx_rsp_bits_tgtID;
  wire [10:0] i_io_in_rx_rsp_bits_tgtID;
  wire [10:0] g_io_in_rx_rsp_bits_srcID;
  wire [10:0] i_io_in_rx_rsp_bits_srcID;
  wire [11:0] g_io_in_rx_rsp_bits_txnID;
  wire [11:0] i_io_in_rx_rsp_bits_txnID;
  wire [4:0] g_io_in_rx_rsp_bits_opcode;
  wire [4:0] i_io_in_rx_rsp_bits_opcode;
  wire [1:0] g_io_in_rx_rsp_bits_respErr;
  wire [1:0] i_io_in_rx_rsp_bits_respErr;
  wire [2:0] g_io_in_rx_rsp_bits_resp;
  wire [2:0] i_io_in_rx_rsp_bits_resp;
  wire [2:0] g_io_in_rx_rsp_bits_fwdState;
  wire [2:0] i_io_in_rx_rsp_bits_fwdState;
  wire [2:0] g_io_in_rx_rsp_bits_cBusy;
  wire [2:0] i_io_in_rx_rsp_bits_cBusy;
  wire [11:0] g_io_in_rx_rsp_bits_dbID;
  wire [11:0] i_io_in_rx_rsp_bits_dbID;
  wire [3:0] g_io_in_rx_rsp_bits_pCrdType;
  wire [3:0] i_io_in_rx_rsp_bits_pCrdType;
  wire [1:0] g_io_in_rx_rsp_bits_tagOp;
  wire [1:0] i_io_in_rx_rsp_bits_tagOp;
  wire g_io_in_rx_rsp_bits_traceTag;
  wire i_io_in_rx_rsp_bits_traceTag;
  wire g_io_in_rx_dat_valid;
  wire i_io_in_rx_dat_valid;
  wire [3:0] g_io_in_rx_dat_bits_qos;
  wire [3:0] i_io_in_rx_dat_bits_qos;
  wire [10:0] g_io_in_rx_dat_bits_tgtID;
  wire [10:0] i_io_in_rx_dat_bits_tgtID;
  wire [10:0] g_io_in_rx_dat_bits_srcID;
  wire [10:0] i_io_in_rx_dat_bits_srcID;
  wire [11:0] g_io_in_rx_dat_bits_txnID;
  wire [11:0] i_io_in_rx_dat_bits_txnID;
  wire [10:0] g_io_in_rx_dat_bits_homeNID;
  wire [10:0] i_io_in_rx_dat_bits_homeNID;
  wire [3:0] g_io_in_rx_dat_bits_opcode;
  wire [3:0] i_io_in_rx_dat_bits_opcode;
  wire [1:0] g_io_in_rx_dat_bits_respErr;
  wire [1:0] i_io_in_rx_dat_bits_respErr;
  wire [2:0] g_io_in_rx_dat_bits_resp;
  wire [2:0] i_io_in_rx_dat_bits_resp;
  wire [3:0] g_io_in_rx_dat_bits_dataSource;
  wire [3:0] i_io_in_rx_dat_bits_dataSource;
  wire [2:0] g_io_in_rx_dat_bits_cBusy;
  wire [2:0] i_io_in_rx_dat_bits_cBusy;
  wire [11:0] g_io_in_rx_dat_bits_dbID;
  wire [11:0] i_io_in_rx_dat_bits_dbID;
  wire [1:0] g_io_in_rx_dat_bits_ccID;
  wire [1:0] i_io_in_rx_dat_bits_ccID;
  wire [1:0] g_io_in_rx_dat_bits_dataID;
  wire [1:0] i_io_in_rx_dat_bits_dataID;
  wire [1:0] g_io_in_rx_dat_bits_tagOp;
  wire [1:0] i_io_in_rx_dat_bits_tagOp;
  wire [7:0] g_io_in_rx_dat_bits_tag;
  wire [7:0] i_io_in_rx_dat_bits_tag;
  wire [1:0] g_io_in_rx_dat_bits_tu;
  wire [1:0] i_io_in_rx_dat_bits_tu;
  wire g_io_in_rx_dat_bits_traceTag;
  wire i_io_in_rx_dat_bits_traceTag;
  wire [3:0] g_io_in_rx_dat_bits_rsvdc;
  wire [3:0] i_io_in_rx_dat_bits_rsvdc;
  wire [31:0] g_io_in_rx_dat_bits_be;
  wire [31:0] i_io_in_rx_dat_bits_be;
  wire [255:0] g_io_in_rx_dat_bits_data;
  wire [255:0] i_io_in_rx_dat_bits_data;
  wire [31:0] g_io_in_rx_dat_bits_dataCheck;
  wire [31:0] i_io_in_rx_dat_bits_dataCheck;
  wire [3:0] g_io_in_rx_dat_bits_poison;
  wire [3:0] i_io_in_rx_dat_bits_poison;
  wire g_io_in_rx_snp_valid;
  wire i_io_in_rx_snp_valid;
  wire [3:0] g_io_in_rx_snp_bits_qos;
  wire [3:0] i_io_in_rx_snp_bits_qos;
  wire [10:0] g_io_in_rx_snp_bits_srcID;
  wire [10:0] i_io_in_rx_snp_bits_srcID;
  wire [11:0] g_io_in_rx_snp_bits_txnID;
  wire [11:0] i_io_in_rx_snp_bits_txnID;
  wire [10:0] g_io_in_rx_snp_bits_fwdNID;
  wire [10:0] i_io_in_rx_snp_bits_fwdNID;
  wire [11:0] g_io_in_rx_snp_bits_fwdTxnID;
  wire [11:0] i_io_in_rx_snp_bits_fwdTxnID;
  wire [4:0] g_io_in_rx_snp_bits_opcode;
  wire [4:0] i_io_in_rx_snp_bits_opcode;
  wire [44:0] g_io_in_rx_snp_bits_addr;
  wire [44:0] i_io_in_rx_snp_bits_addr;
  wire g_io_in_rx_snp_bits_ns;
  wire i_io_in_rx_snp_bits_ns;
  wire g_io_in_rx_snp_bits_doNotGoToSD;
  wire i_io_in_rx_snp_bits_doNotGoToSD;
  wire g_io_in_rx_snp_bits_retToSrc;
  wire i_io_in_rx_snp_bits_retToSrc;
  wire g_io_in_rx_snp_bits_traceTag;
  wire i_io_in_rx_snp_bits_traceTag;
  wire g_io_in_rx_snp_bits_mpam_perfMonGroup;
  wire i_io_in_rx_snp_bits_mpam_perfMonGroup;
  wire [8:0] g_io_in_rx_snp_bits_mpam_partID;
  wire [8:0] i_io_in_rx_snp_bits_mpam_partID;
  wire g_io_in_rx_snp_bits_mpam_mpamNS;
  wire i_io_in_rx_snp_bits_mpam_mpamNS;
  wire g_io_out_txsactive;
  wire i_io_out_txsactive;
  wire g_io_out_syscoreq;
  wire i_io_out_syscoreq;
  wire g_io_out_tx_linkactivereq;
  wire i_io_out_tx_linkactivereq;
  wire g_io_out_tx_req_flitpend;
  wire i_io_out_tx_req_flitpend;
  wire g_io_out_tx_req_flitv;
  wire i_io_out_tx_req_flitv;
  wire [161:0] g_io_out_tx_req_flit;
  wire [161:0] i_io_out_tx_req_flit;
  wire g_io_out_tx_rsp_flitpend;
  wire i_io_out_tx_rsp_flitpend;
  wire g_io_out_tx_rsp_flitv;
  wire i_io_out_tx_rsp_flitv;
  wire [72:0] g_io_out_tx_rsp_flit;
  wire [72:0] i_io_out_tx_rsp_flit;
  wire g_io_out_tx_dat_flitpend;
  wire i_io_out_tx_dat_flitpend;
  wire g_io_out_tx_dat_flitv;
  wire i_io_out_tx_dat_flitv;
  wire [421:0] g_io_out_tx_dat_flit;
  wire [421:0] i_io_out_tx_dat_flit;
  wire g_io_out_rx_linkactiveack;
  wire i_io_out_rx_linkactiveack;
  wire g_io_out_rx_rsp_lcrdv;
  wire i_io_out_rx_rsp_lcrdv;
  wire g_io_out_rx_dat_lcrdv;
  wire i_io_out_rx_dat_lcrdv;
  wire g_io_out_rx_snp_lcrdv;
  wire i_io_out_rx_snp_lcrdv;

  LinkMonitor u_g (
    .clock(clock),
    .reset(reset),
    .io_in_tx_req_ready(g_io_in_tx_req_ready),
    .io_in_tx_req_valid(io_in_tx_req_valid),
    .io_in_tx_req_bits_qos(io_in_tx_req_bits_qos),
    .io_in_tx_req_bits_tgtID(io_in_tx_req_bits_tgtID),
    .io_in_tx_req_bits_txnID(io_in_tx_req_bits_txnID),
    .io_in_tx_req_bits_returnNID(io_in_tx_req_bits_returnNID),
    .io_in_tx_req_bits_stashNIDValid(io_in_tx_req_bits_stashNIDValid),
    .io_in_tx_req_bits_returnTxnID(io_in_tx_req_bits_returnTxnID),
    .io_in_tx_req_bits_opcode(io_in_tx_req_bits_opcode),
    .io_in_tx_req_bits_size(io_in_tx_req_bits_size),
    .io_in_tx_req_bits_addr(io_in_tx_req_bits_addr),
    .io_in_tx_req_bits_ns(io_in_tx_req_bits_ns),
    .io_in_tx_req_bits_likelyshared(io_in_tx_req_bits_likelyshared),
    .io_in_tx_req_bits_allowRetry(io_in_tx_req_bits_allowRetry),
    .io_in_tx_req_bits_order(io_in_tx_req_bits_order),
    .io_in_tx_req_bits_pCrdType(io_in_tx_req_bits_pCrdType),
    .io_in_tx_req_bits_memAttr_allocate(io_in_tx_req_bits_memAttr_allocate),
    .io_in_tx_req_bits_memAttr_cacheable(io_in_tx_req_bits_memAttr_cacheable),
    .io_in_tx_req_bits_memAttr_device(io_in_tx_req_bits_memAttr_device),
    .io_in_tx_req_bits_memAttr_ewa(io_in_tx_req_bits_memAttr_ewa),
    .io_in_tx_req_bits_snpAttr(io_in_tx_req_bits_snpAttr),
    .io_in_tx_req_bits_lpIDWithPadding(io_in_tx_req_bits_lpIDWithPadding),
    .io_in_tx_req_bits_snoopMe(io_in_tx_req_bits_snoopMe),
    .io_in_tx_req_bits_expCompAck(io_in_tx_req_bits_expCompAck),
    .io_in_tx_req_bits_tagOp(io_in_tx_req_bits_tagOp),
    .io_in_tx_req_bits_traceTag(io_in_tx_req_bits_traceTag),
    .io_in_tx_req_bits_mpam_perfMonGroup(io_in_tx_req_bits_mpam_perfMonGroup),
    .io_in_tx_req_bits_mpam_partID(io_in_tx_req_bits_mpam_partID),
    .io_in_tx_req_bits_mpam_mpamNS(io_in_tx_req_bits_mpam_mpamNS),
    .io_in_tx_req_bits_rsvdc(io_in_tx_req_bits_rsvdc),
    .io_in_tx_rsp_ready(g_io_in_tx_rsp_ready),
    .io_in_tx_rsp_valid(io_in_tx_rsp_valid),
    .io_in_tx_rsp_bits_qos(io_in_tx_rsp_bits_qos),
    .io_in_tx_rsp_bits_tgtID(io_in_tx_rsp_bits_tgtID),
    .io_in_tx_rsp_bits_txnID(io_in_tx_rsp_bits_txnID),
    .io_in_tx_rsp_bits_opcode(io_in_tx_rsp_bits_opcode),
    .io_in_tx_rsp_bits_respErr(io_in_tx_rsp_bits_respErr),
    .io_in_tx_rsp_bits_resp(io_in_tx_rsp_bits_resp),
    .io_in_tx_rsp_bits_fwdState(io_in_tx_rsp_bits_fwdState),
    .io_in_tx_rsp_bits_cBusy(io_in_tx_rsp_bits_cBusy),
    .io_in_tx_rsp_bits_dbID(io_in_tx_rsp_bits_dbID),
    .io_in_tx_rsp_bits_pCrdType(io_in_tx_rsp_bits_pCrdType),
    .io_in_tx_rsp_bits_tagOp(io_in_tx_rsp_bits_tagOp),
    .io_in_tx_rsp_bits_traceTag(io_in_tx_rsp_bits_traceTag),
    .io_in_tx_dat_ready(g_io_in_tx_dat_ready),
    .io_in_tx_dat_valid(io_in_tx_dat_valid),
    .io_in_tx_dat_bits_qos(io_in_tx_dat_bits_qos),
    .io_in_tx_dat_bits_tgtID(io_in_tx_dat_bits_tgtID),
    .io_in_tx_dat_bits_txnID(io_in_tx_dat_bits_txnID),
    .io_in_tx_dat_bits_homeNID(io_in_tx_dat_bits_homeNID),
    .io_in_tx_dat_bits_opcode(io_in_tx_dat_bits_opcode),
    .io_in_tx_dat_bits_respErr(io_in_tx_dat_bits_respErr),
    .io_in_tx_dat_bits_resp(io_in_tx_dat_bits_resp),
    .io_in_tx_dat_bits_dataSource(io_in_tx_dat_bits_dataSource),
    .io_in_tx_dat_bits_cBusy(io_in_tx_dat_bits_cBusy),
    .io_in_tx_dat_bits_dbID(io_in_tx_dat_bits_dbID),
    .io_in_tx_dat_bits_ccID(io_in_tx_dat_bits_ccID),
    .io_in_tx_dat_bits_dataID(io_in_tx_dat_bits_dataID),
    .io_in_tx_dat_bits_tagOp(io_in_tx_dat_bits_tagOp),
    .io_in_tx_dat_bits_tag(io_in_tx_dat_bits_tag),
    .io_in_tx_dat_bits_tu(io_in_tx_dat_bits_tu),
    .io_in_tx_dat_bits_traceTag(io_in_tx_dat_bits_traceTag),
    .io_in_tx_dat_bits_rsvdc(io_in_tx_dat_bits_rsvdc),
    .io_in_tx_dat_bits_be(io_in_tx_dat_bits_be),
    .io_in_tx_dat_bits_data(io_in_tx_dat_bits_data),
    .io_in_tx_dat_bits_dataCheck(io_in_tx_dat_bits_dataCheck),
    .io_in_tx_dat_bits_poison(io_in_tx_dat_bits_poison),
    .io_in_rx_rsp_ready(io_in_rx_rsp_ready),
    .io_in_rx_rsp_valid(g_io_in_rx_rsp_valid),
    .io_in_rx_rsp_bits_qos(g_io_in_rx_rsp_bits_qos),
    .io_in_rx_rsp_bits_tgtID(g_io_in_rx_rsp_bits_tgtID),
    .io_in_rx_rsp_bits_srcID(g_io_in_rx_rsp_bits_srcID),
    .io_in_rx_rsp_bits_txnID(g_io_in_rx_rsp_bits_txnID),
    .io_in_rx_rsp_bits_opcode(g_io_in_rx_rsp_bits_opcode),
    .io_in_rx_rsp_bits_respErr(g_io_in_rx_rsp_bits_respErr),
    .io_in_rx_rsp_bits_resp(g_io_in_rx_rsp_bits_resp),
    .io_in_rx_rsp_bits_fwdState(g_io_in_rx_rsp_bits_fwdState),
    .io_in_rx_rsp_bits_cBusy(g_io_in_rx_rsp_bits_cBusy),
    .io_in_rx_rsp_bits_dbID(g_io_in_rx_rsp_bits_dbID),
    .io_in_rx_rsp_bits_pCrdType(g_io_in_rx_rsp_bits_pCrdType),
    .io_in_rx_rsp_bits_tagOp(g_io_in_rx_rsp_bits_tagOp),
    .io_in_rx_rsp_bits_traceTag(g_io_in_rx_rsp_bits_traceTag),
    .io_in_rx_dat_ready(io_in_rx_dat_ready),
    .io_in_rx_dat_valid(g_io_in_rx_dat_valid),
    .io_in_rx_dat_bits_qos(g_io_in_rx_dat_bits_qos),
    .io_in_rx_dat_bits_tgtID(g_io_in_rx_dat_bits_tgtID),
    .io_in_rx_dat_bits_srcID(g_io_in_rx_dat_bits_srcID),
    .io_in_rx_dat_bits_txnID(g_io_in_rx_dat_bits_txnID),
    .io_in_rx_dat_bits_homeNID(g_io_in_rx_dat_bits_homeNID),
    .io_in_rx_dat_bits_opcode(g_io_in_rx_dat_bits_opcode),
    .io_in_rx_dat_bits_respErr(g_io_in_rx_dat_bits_respErr),
    .io_in_rx_dat_bits_resp(g_io_in_rx_dat_bits_resp),
    .io_in_rx_dat_bits_dataSource(g_io_in_rx_dat_bits_dataSource),
    .io_in_rx_dat_bits_cBusy(g_io_in_rx_dat_bits_cBusy),
    .io_in_rx_dat_bits_dbID(g_io_in_rx_dat_bits_dbID),
    .io_in_rx_dat_bits_ccID(g_io_in_rx_dat_bits_ccID),
    .io_in_rx_dat_bits_dataID(g_io_in_rx_dat_bits_dataID),
    .io_in_rx_dat_bits_tagOp(g_io_in_rx_dat_bits_tagOp),
    .io_in_rx_dat_bits_tag(g_io_in_rx_dat_bits_tag),
    .io_in_rx_dat_bits_tu(g_io_in_rx_dat_bits_tu),
    .io_in_rx_dat_bits_traceTag(g_io_in_rx_dat_bits_traceTag),
    .io_in_rx_dat_bits_rsvdc(g_io_in_rx_dat_bits_rsvdc),
    .io_in_rx_dat_bits_be(g_io_in_rx_dat_bits_be),
    .io_in_rx_dat_bits_data(g_io_in_rx_dat_bits_data),
    .io_in_rx_dat_bits_dataCheck(g_io_in_rx_dat_bits_dataCheck),
    .io_in_rx_dat_bits_poison(g_io_in_rx_dat_bits_poison),
    .io_in_rx_snp_ready(io_in_rx_snp_ready),
    .io_in_rx_snp_valid(g_io_in_rx_snp_valid),
    .io_in_rx_snp_bits_qos(g_io_in_rx_snp_bits_qos),
    .io_in_rx_snp_bits_srcID(g_io_in_rx_snp_bits_srcID),
    .io_in_rx_snp_bits_txnID(g_io_in_rx_snp_bits_txnID),
    .io_in_rx_snp_bits_fwdNID(g_io_in_rx_snp_bits_fwdNID),
    .io_in_rx_snp_bits_fwdTxnID(g_io_in_rx_snp_bits_fwdTxnID),
    .io_in_rx_snp_bits_opcode(g_io_in_rx_snp_bits_opcode),
    .io_in_rx_snp_bits_addr(g_io_in_rx_snp_bits_addr),
    .io_in_rx_snp_bits_ns(g_io_in_rx_snp_bits_ns),
    .io_in_rx_snp_bits_doNotGoToSD(g_io_in_rx_snp_bits_doNotGoToSD),
    .io_in_rx_snp_bits_retToSrc(g_io_in_rx_snp_bits_retToSrc),
    .io_in_rx_snp_bits_traceTag(g_io_in_rx_snp_bits_traceTag),
    .io_in_rx_snp_bits_mpam_perfMonGroup(g_io_in_rx_snp_bits_mpam_perfMonGroup),
    .io_in_rx_snp_bits_mpam_partID(g_io_in_rx_snp_bits_mpam_partID),
    .io_in_rx_snp_bits_mpam_mpamNS(g_io_in_rx_snp_bits_mpam_mpamNS),
    .io_out_txsactive(g_io_out_txsactive),
    .io_out_rxsactive(io_out_rxsactive),
    .io_out_syscoreq(g_io_out_syscoreq),
    .io_out_syscoack(io_out_syscoack),
    .io_out_tx_linkactivereq(g_io_out_tx_linkactivereq),
    .io_out_tx_linkactiveack(io_out_tx_linkactiveack),
    .io_out_tx_req_flitpend(g_io_out_tx_req_flitpend),
    .io_out_tx_req_flitv(g_io_out_tx_req_flitv),
    .io_out_tx_req_flit(g_io_out_tx_req_flit),
    .io_out_tx_req_lcrdv(io_out_tx_req_lcrdv),
    .io_out_tx_rsp_flitpend(g_io_out_tx_rsp_flitpend),
    .io_out_tx_rsp_flitv(g_io_out_tx_rsp_flitv),
    .io_out_tx_rsp_flit(g_io_out_tx_rsp_flit),
    .io_out_tx_rsp_lcrdv(io_out_tx_rsp_lcrdv),
    .io_out_tx_dat_flitpend(g_io_out_tx_dat_flitpend),
    .io_out_tx_dat_flitv(g_io_out_tx_dat_flitv),
    .io_out_tx_dat_flit(g_io_out_tx_dat_flit),
    .io_out_tx_dat_lcrdv(io_out_tx_dat_lcrdv),
    .io_out_rx_linkactivereq(io_out_rx_linkactivereq),
    .io_out_rx_linkactiveack(g_io_out_rx_linkactiveack),
    .io_out_rx_rsp_flitpend(io_out_rx_rsp_flitpend),
    .io_out_rx_rsp_flitv(io_out_rx_rsp_flitv),
    .io_out_rx_rsp_flit(io_out_rx_rsp_flit),
    .io_out_rx_rsp_lcrdv(g_io_out_rx_rsp_lcrdv),
    .io_out_rx_dat_flitpend(io_out_rx_dat_flitpend),
    .io_out_rx_dat_flitv(io_out_rx_dat_flitv),
    .io_out_rx_dat_flit(io_out_rx_dat_flit),
    .io_out_rx_dat_lcrdv(g_io_out_rx_dat_lcrdv),
    .io_out_rx_snp_flitpend(io_out_rx_snp_flitpend),
    .io_out_rx_snp_flitv(io_out_rx_snp_flitv),
    .io_out_rx_snp_flit(io_out_rx_snp_flit),
    .io_out_rx_snp_lcrdv(g_io_out_rx_snp_lcrdv),
    .io_nodeID(io_nodeID)
  );

  LinkMonitor_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_tx_req_ready(i_io_in_tx_req_ready),
    .io_in_tx_req_valid(io_in_tx_req_valid),
    .io_in_tx_req_bits_qos(io_in_tx_req_bits_qos),
    .io_in_tx_req_bits_tgtID(io_in_tx_req_bits_tgtID),
    .io_in_tx_req_bits_txnID(io_in_tx_req_bits_txnID),
    .io_in_tx_req_bits_returnNID(io_in_tx_req_bits_returnNID),
    .io_in_tx_req_bits_stashNIDValid(io_in_tx_req_bits_stashNIDValid),
    .io_in_tx_req_bits_returnTxnID(io_in_tx_req_bits_returnTxnID),
    .io_in_tx_req_bits_opcode(io_in_tx_req_bits_opcode),
    .io_in_tx_req_bits_size(io_in_tx_req_bits_size),
    .io_in_tx_req_bits_addr(io_in_tx_req_bits_addr),
    .io_in_tx_req_bits_ns(io_in_tx_req_bits_ns),
    .io_in_tx_req_bits_likelyshared(io_in_tx_req_bits_likelyshared),
    .io_in_tx_req_bits_allowRetry(io_in_tx_req_bits_allowRetry),
    .io_in_tx_req_bits_order(io_in_tx_req_bits_order),
    .io_in_tx_req_bits_pCrdType(io_in_tx_req_bits_pCrdType),
    .io_in_tx_req_bits_memAttr_allocate(io_in_tx_req_bits_memAttr_allocate),
    .io_in_tx_req_bits_memAttr_cacheable(io_in_tx_req_bits_memAttr_cacheable),
    .io_in_tx_req_bits_memAttr_device(io_in_tx_req_bits_memAttr_device),
    .io_in_tx_req_bits_memAttr_ewa(io_in_tx_req_bits_memAttr_ewa),
    .io_in_tx_req_bits_snpAttr(io_in_tx_req_bits_snpAttr),
    .io_in_tx_req_bits_lpIDWithPadding(io_in_tx_req_bits_lpIDWithPadding),
    .io_in_tx_req_bits_snoopMe(io_in_tx_req_bits_snoopMe),
    .io_in_tx_req_bits_expCompAck(io_in_tx_req_bits_expCompAck),
    .io_in_tx_req_bits_tagOp(io_in_tx_req_bits_tagOp),
    .io_in_tx_req_bits_traceTag(io_in_tx_req_bits_traceTag),
    .io_in_tx_req_bits_mpam_perfMonGroup(io_in_tx_req_bits_mpam_perfMonGroup),
    .io_in_tx_req_bits_mpam_partID(io_in_tx_req_bits_mpam_partID),
    .io_in_tx_req_bits_mpam_mpamNS(io_in_tx_req_bits_mpam_mpamNS),
    .io_in_tx_req_bits_rsvdc(io_in_tx_req_bits_rsvdc),
    .io_in_tx_rsp_ready(i_io_in_tx_rsp_ready),
    .io_in_tx_rsp_valid(io_in_tx_rsp_valid),
    .io_in_tx_rsp_bits_qos(io_in_tx_rsp_bits_qos),
    .io_in_tx_rsp_bits_tgtID(io_in_tx_rsp_bits_tgtID),
    .io_in_tx_rsp_bits_txnID(io_in_tx_rsp_bits_txnID),
    .io_in_tx_rsp_bits_opcode(io_in_tx_rsp_bits_opcode),
    .io_in_tx_rsp_bits_respErr(io_in_tx_rsp_bits_respErr),
    .io_in_tx_rsp_bits_resp(io_in_tx_rsp_bits_resp),
    .io_in_tx_rsp_bits_fwdState(io_in_tx_rsp_bits_fwdState),
    .io_in_tx_rsp_bits_cBusy(io_in_tx_rsp_bits_cBusy),
    .io_in_tx_rsp_bits_dbID(io_in_tx_rsp_bits_dbID),
    .io_in_tx_rsp_bits_pCrdType(io_in_tx_rsp_bits_pCrdType),
    .io_in_tx_rsp_bits_tagOp(io_in_tx_rsp_bits_tagOp),
    .io_in_tx_rsp_bits_traceTag(io_in_tx_rsp_bits_traceTag),
    .io_in_tx_dat_ready(i_io_in_tx_dat_ready),
    .io_in_tx_dat_valid(io_in_tx_dat_valid),
    .io_in_tx_dat_bits_qos(io_in_tx_dat_bits_qos),
    .io_in_tx_dat_bits_tgtID(io_in_tx_dat_bits_tgtID),
    .io_in_tx_dat_bits_txnID(io_in_tx_dat_bits_txnID),
    .io_in_tx_dat_bits_homeNID(io_in_tx_dat_bits_homeNID),
    .io_in_tx_dat_bits_opcode(io_in_tx_dat_bits_opcode),
    .io_in_tx_dat_bits_respErr(io_in_tx_dat_bits_respErr),
    .io_in_tx_dat_bits_resp(io_in_tx_dat_bits_resp),
    .io_in_tx_dat_bits_dataSource(io_in_tx_dat_bits_dataSource),
    .io_in_tx_dat_bits_cBusy(io_in_tx_dat_bits_cBusy),
    .io_in_tx_dat_bits_dbID(io_in_tx_dat_bits_dbID),
    .io_in_tx_dat_bits_ccID(io_in_tx_dat_bits_ccID),
    .io_in_tx_dat_bits_dataID(io_in_tx_dat_bits_dataID),
    .io_in_tx_dat_bits_tagOp(io_in_tx_dat_bits_tagOp),
    .io_in_tx_dat_bits_tag(io_in_tx_dat_bits_tag),
    .io_in_tx_dat_bits_tu(io_in_tx_dat_bits_tu),
    .io_in_tx_dat_bits_traceTag(io_in_tx_dat_bits_traceTag),
    .io_in_tx_dat_bits_rsvdc(io_in_tx_dat_bits_rsvdc),
    .io_in_tx_dat_bits_be(io_in_tx_dat_bits_be),
    .io_in_tx_dat_bits_data(io_in_tx_dat_bits_data),
    .io_in_tx_dat_bits_dataCheck(io_in_tx_dat_bits_dataCheck),
    .io_in_tx_dat_bits_poison(io_in_tx_dat_bits_poison),
    .io_in_rx_rsp_ready(io_in_rx_rsp_ready),
    .io_in_rx_rsp_valid(i_io_in_rx_rsp_valid),
    .io_in_rx_rsp_bits_qos(i_io_in_rx_rsp_bits_qos),
    .io_in_rx_rsp_bits_tgtID(i_io_in_rx_rsp_bits_tgtID),
    .io_in_rx_rsp_bits_srcID(i_io_in_rx_rsp_bits_srcID),
    .io_in_rx_rsp_bits_txnID(i_io_in_rx_rsp_bits_txnID),
    .io_in_rx_rsp_bits_opcode(i_io_in_rx_rsp_bits_opcode),
    .io_in_rx_rsp_bits_respErr(i_io_in_rx_rsp_bits_respErr),
    .io_in_rx_rsp_bits_resp(i_io_in_rx_rsp_bits_resp),
    .io_in_rx_rsp_bits_fwdState(i_io_in_rx_rsp_bits_fwdState),
    .io_in_rx_rsp_bits_cBusy(i_io_in_rx_rsp_bits_cBusy),
    .io_in_rx_rsp_bits_dbID(i_io_in_rx_rsp_bits_dbID),
    .io_in_rx_rsp_bits_pCrdType(i_io_in_rx_rsp_bits_pCrdType),
    .io_in_rx_rsp_bits_tagOp(i_io_in_rx_rsp_bits_tagOp),
    .io_in_rx_rsp_bits_traceTag(i_io_in_rx_rsp_bits_traceTag),
    .io_in_rx_dat_ready(io_in_rx_dat_ready),
    .io_in_rx_dat_valid(i_io_in_rx_dat_valid),
    .io_in_rx_dat_bits_qos(i_io_in_rx_dat_bits_qos),
    .io_in_rx_dat_bits_tgtID(i_io_in_rx_dat_bits_tgtID),
    .io_in_rx_dat_bits_srcID(i_io_in_rx_dat_bits_srcID),
    .io_in_rx_dat_bits_txnID(i_io_in_rx_dat_bits_txnID),
    .io_in_rx_dat_bits_homeNID(i_io_in_rx_dat_bits_homeNID),
    .io_in_rx_dat_bits_opcode(i_io_in_rx_dat_bits_opcode),
    .io_in_rx_dat_bits_respErr(i_io_in_rx_dat_bits_respErr),
    .io_in_rx_dat_bits_resp(i_io_in_rx_dat_bits_resp),
    .io_in_rx_dat_bits_dataSource(i_io_in_rx_dat_bits_dataSource),
    .io_in_rx_dat_bits_cBusy(i_io_in_rx_dat_bits_cBusy),
    .io_in_rx_dat_bits_dbID(i_io_in_rx_dat_bits_dbID),
    .io_in_rx_dat_bits_ccID(i_io_in_rx_dat_bits_ccID),
    .io_in_rx_dat_bits_dataID(i_io_in_rx_dat_bits_dataID),
    .io_in_rx_dat_bits_tagOp(i_io_in_rx_dat_bits_tagOp),
    .io_in_rx_dat_bits_tag(i_io_in_rx_dat_bits_tag),
    .io_in_rx_dat_bits_tu(i_io_in_rx_dat_bits_tu),
    .io_in_rx_dat_bits_traceTag(i_io_in_rx_dat_bits_traceTag),
    .io_in_rx_dat_bits_rsvdc(i_io_in_rx_dat_bits_rsvdc),
    .io_in_rx_dat_bits_be(i_io_in_rx_dat_bits_be),
    .io_in_rx_dat_bits_data(i_io_in_rx_dat_bits_data),
    .io_in_rx_dat_bits_dataCheck(i_io_in_rx_dat_bits_dataCheck),
    .io_in_rx_dat_bits_poison(i_io_in_rx_dat_bits_poison),
    .io_in_rx_snp_ready(io_in_rx_snp_ready),
    .io_in_rx_snp_valid(i_io_in_rx_snp_valid),
    .io_in_rx_snp_bits_qos(i_io_in_rx_snp_bits_qos),
    .io_in_rx_snp_bits_srcID(i_io_in_rx_snp_bits_srcID),
    .io_in_rx_snp_bits_txnID(i_io_in_rx_snp_bits_txnID),
    .io_in_rx_snp_bits_fwdNID(i_io_in_rx_snp_bits_fwdNID),
    .io_in_rx_snp_bits_fwdTxnID(i_io_in_rx_snp_bits_fwdTxnID),
    .io_in_rx_snp_bits_opcode(i_io_in_rx_snp_bits_opcode),
    .io_in_rx_snp_bits_addr(i_io_in_rx_snp_bits_addr),
    .io_in_rx_snp_bits_ns(i_io_in_rx_snp_bits_ns),
    .io_in_rx_snp_bits_doNotGoToSD(i_io_in_rx_snp_bits_doNotGoToSD),
    .io_in_rx_snp_bits_retToSrc(i_io_in_rx_snp_bits_retToSrc),
    .io_in_rx_snp_bits_traceTag(i_io_in_rx_snp_bits_traceTag),
    .io_in_rx_snp_bits_mpam_perfMonGroup(i_io_in_rx_snp_bits_mpam_perfMonGroup),
    .io_in_rx_snp_bits_mpam_partID(i_io_in_rx_snp_bits_mpam_partID),
    .io_in_rx_snp_bits_mpam_mpamNS(i_io_in_rx_snp_bits_mpam_mpamNS),
    .io_out_txsactive(i_io_out_txsactive),
    .io_out_rxsactive(io_out_rxsactive),
    .io_out_syscoreq(i_io_out_syscoreq),
    .io_out_syscoack(io_out_syscoack),
    .io_out_tx_linkactivereq(i_io_out_tx_linkactivereq),
    .io_out_tx_linkactiveack(io_out_tx_linkactiveack),
    .io_out_tx_req_flitpend(i_io_out_tx_req_flitpend),
    .io_out_tx_req_flitv(i_io_out_tx_req_flitv),
    .io_out_tx_req_flit(i_io_out_tx_req_flit),
    .io_out_tx_req_lcrdv(io_out_tx_req_lcrdv),
    .io_out_tx_rsp_flitpend(i_io_out_tx_rsp_flitpend),
    .io_out_tx_rsp_flitv(i_io_out_tx_rsp_flitv),
    .io_out_tx_rsp_flit(i_io_out_tx_rsp_flit),
    .io_out_tx_rsp_lcrdv(io_out_tx_rsp_lcrdv),
    .io_out_tx_dat_flitpend(i_io_out_tx_dat_flitpend),
    .io_out_tx_dat_flitv(i_io_out_tx_dat_flitv),
    .io_out_tx_dat_flit(i_io_out_tx_dat_flit),
    .io_out_tx_dat_lcrdv(io_out_tx_dat_lcrdv),
    .io_out_rx_linkactivereq(io_out_rx_linkactivereq),
    .io_out_rx_linkactiveack(i_io_out_rx_linkactiveack),
    .io_out_rx_rsp_flitpend(io_out_rx_rsp_flitpend),
    .io_out_rx_rsp_flitv(io_out_rx_rsp_flitv),
    .io_out_rx_rsp_flit(io_out_rx_rsp_flit),
    .io_out_rx_rsp_lcrdv(i_io_out_rx_rsp_lcrdv),
    .io_out_rx_dat_flitpend(io_out_rx_dat_flitpend),
    .io_out_rx_dat_flitv(io_out_rx_dat_flitv),
    .io_out_rx_dat_flit(io_out_rx_dat_flit),
    .io_out_rx_dat_lcrdv(i_io_out_rx_dat_lcrdv),
    .io_out_rx_snp_flitpend(io_out_rx_snp_flitpend),
    .io_out_rx_snp_flitv(io_out_rx_snp_flitv),
    .io_out_rx_snp_flit(io_out_rx_snp_flit),
    .io_out_rx_snp_lcrdv(i_io_out_rx_snp_lcrdv),
    .io_nodeID(io_nodeID)
  );

  task automatic drive_random_inputs();
    io_in_tx_req_valid <= $urandom_range(0, 1);
    io_in_tx_req_bits_qos <= 4'({$urandom});
    io_in_tx_req_bits_tgtID <= 11'({$urandom});
    io_in_tx_req_bits_txnID <= 12'({$urandom});
    io_in_tx_req_bits_returnNID <= 11'({$urandom});
    io_in_tx_req_bits_stashNIDValid <= $urandom_range(0, 1);
    io_in_tx_req_bits_returnTxnID <= 12'({$urandom});
    io_in_tx_req_bits_opcode <= 7'({$urandom});
    io_in_tx_req_bits_size <= 3'({$urandom});
    io_in_tx_req_bits_addr <= 48'({$urandom, $urandom});
    io_in_tx_req_bits_ns <= $urandom_range(0, 1);
    io_in_tx_req_bits_likelyshared <= $urandom_range(0, 1);
    io_in_tx_req_bits_allowRetry <= $urandom_range(0, 1);
    io_in_tx_req_bits_order <= 2'({$urandom});
    io_in_tx_req_bits_pCrdType <= 4'({$urandom});
    io_in_tx_req_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_tx_req_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_tx_req_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_tx_req_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_tx_req_bits_snpAttr <= $urandom_range(0, 1);
    io_in_tx_req_bits_lpIDWithPadding <= 8'({$urandom});
    io_in_tx_req_bits_snoopMe <= $urandom_range(0, 1);
    io_in_tx_req_bits_expCompAck <= $urandom_range(0, 1);
    io_in_tx_req_bits_tagOp <= 2'({$urandom});
    io_in_tx_req_bits_traceTag <= $urandom_range(0, 1);
    io_in_tx_req_bits_mpam_perfMonGroup <= $urandom_range(0, 1);
    io_in_tx_req_bits_mpam_partID <= 9'({$urandom});
    io_in_tx_req_bits_mpam_mpamNS <= $urandom_range(0, 1);
    io_in_tx_req_bits_rsvdc <= 4'({$urandom});
    io_in_tx_rsp_valid <= $urandom_range(0, 1);
    io_in_tx_rsp_bits_qos <= 4'({$urandom});
    io_in_tx_rsp_bits_tgtID <= 11'({$urandom});
    io_in_tx_rsp_bits_txnID <= 12'({$urandom});
    io_in_tx_rsp_bits_opcode <= 5'({$urandom});
    io_in_tx_rsp_bits_respErr <= 2'({$urandom});
    io_in_tx_rsp_bits_resp <= 3'({$urandom});
    io_in_tx_rsp_bits_fwdState <= 3'({$urandom});
    io_in_tx_rsp_bits_cBusy <= 3'({$urandom});
    io_in_tx_rsp_bits_dbID <= 12'({$urandom});
    io_in_tx_rsp_bits_pCrdType <= 4'({$urandom});
    io_in_tx_rsp_bits_tagOp <= 2'({$urandom});
    io_in_tx_rsp_bits_traceTag <= $urandom_range(0, 1);
    io_in_tx_dat_valid <= $urandom_range(0, 1);
    io_in_tx_dat_bits_qos <= 4'({$urandom});
    io_in_tx_dat_bits_tgtID <= 11'({$urandom});
    io_in_tx_dat_bits_txnID <= 12'({$urandom});
    io_in_tx_dat_bits_homeNID <= 11'({$urandom});
    io_in_tx_dat_bits_opcode <= 4'({$urandom});
    io_in_tx_dat_bits_respErr <= 2'({$urandom});
    io_in_tx_dat_bits_resp <= 3'({$urandom});
    io_in_tx_dat_bits_dataSource <= 4'({$urandom});
    io_in_tx_dat_bits_cBusy <= 3'({$urandom});
    io_in_tx_dat_bits_dbID <= 12'({$urandom});
    io_in_tx_dat_bits_ccID <= 2'({$urandom});
    io_in_tx_dat_bits_dataID <= 2'({$urandom});
    io_in_tx_dat_bits_tagOp <= 2'({$urandom});
    io_in_tx_dat_bits_tag <= 8'({$urandom});
    io_in_tx_dat_bits_tu <= 2'({$urandom});
    io_in_tx_dat_bits_traceTag <= $urandom_range(0, 1);
    io_in_tx_dat_bits_rsvdc <= 4'({$urandom});
    io_in_tx_dat_bits_be <= 32'({$urandom});
    io_in_tx_dat_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_tx_dat_bits_dataCheck <= 32'({$urandom});
    io_in_tx_dat_bits_poison <= 4'({$urandom});
    io_in_rx_rsp_ready <= $urandom_range(0, 1);
    io_in_rx_dat_ready <= $urandom_range(0, 1);
    io_in_rx_snp_ready <= $urandom_range(0, 1);
    io_out_rxsactive <= $urandom_range(0, 1);
    io_out_syscoack <= $urandom_range(0, 1);
    io_out_tx_linkactiveack <= $urandom_range(0, 1);
    io_out_tx_req_lcrdv <= $urandom_range(0, 1);
    io_out_tx_rsp_lcrdv <= $urandom_range(0, 1);
    io_out_tx_dat_lcrdv <= $urandom_range(0, 1);
    io_out_rx_linkactivereq <= $urandom_range(0, 1);
    io_out_rx_rsp_flitpend <= $urandom_range(0, 1);
    io_out_rx_rsp_flitv <= $urandom_range(0, 1);
    io_out_rx_rsp_flit <= 73'({$urandom, $urandom, $urandom});
    io_out_rx_dat_flitpend <= $urandom_range(0, 1);
    io_out_rx_dat_flitv <= $urandom_range(0, 1);
    io_out_rx_dat_flit <= 422'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_out_rx_snp_flitpend <= $urandom_range(0, 1);
    io_out_rx_snp_flitv <= $urandom_range(0, 1);
    io_out_rx_snp_flit <= 115'({$urandom, $urandom, $urandom, $urandom});
    io_nodeID <= 11'({$urandom});
  endtask

  task automatic check_outputs();
    `CHECK(io_in_tx_req_ready)
    `CHECK(io_in_tx_rsp_ready)
    `CHECK(io_in_tx_dat_ready)
    `CHECK(io_in_rx_rsp_valid)
    `CHECK(io_in_rx_rsp_bits_qos)
    `CHECK(io_in_rx_rsp_bits_tgtID)
    `CHECK(io_in_rx_rsp_bits_srcID)
    `CHECK(io_in_rx_rsp_bits_txnID)
    `CHECK(io_in_rx_rsp_bits_opcode)
    `CHECK(io_in_rx_rsp_bits_respErr)
    `CHECK(io_in_rx_rsp_bits_resp)
    `CHECK(io_in_rx_rsp_bits_fwdState)
    `CHECK(io_in_rx_rsp_bits_cBusy)
    `CHECK(io_in_rx_rsp_bits_dbID)
    `CHECK(io_in_rx_rsp_bits_pCrdType)
    `CHECK(io_in_rx_rsp_bits_tagOp)
    `CHECK(io_in_rx_rsp_bits_traceTag)
    `CHECK(io_in_rx_dat_valid)
    `CHECK(io_in_rx_dat_bits_qos)
    `CHECK(io_in_rx_dat_bits_tgtID)
    `CHECK(io_in_rx_dat_bits_srcID)
    `CHECK(io_in_rx_dat_bits_txnID)
    `CHECK(io_in_rx_dat_bits_homeNID)
    `CHECK(io_in_rx_dat_bits_opcode)
    `CHECK(io_in_rx_dat_bits_respErr)
    `CHECK(io_in_rx_dat_bits_resp)
    `CHECK(io_in_rx_dat_bits_dataSource)
    `CHECK(io_in_rx_dat_bits_cBusy)
    `CHECK(io_in_rx_dat_bits_dbID)
    `CHECK(io_in_rx_dat_bits_ccID)
    `CHECK(io_in_rx_dat_bits_dataID)
    `CHECK(io_in_rx_dat_bits_tagOp)
    `CHECK(io_in_rx_dat_bits_tag)
    `CHECK(io_in_rx_dat_bits_tu)
    `CHECK(io_in_rx_dat_bits_traceTag)
    `CHECK(io_in_rx_dat_bits_rsvdc)
    `CHECK(io_in_rx_dat_bits_be)
    `CHECK(io_in_rx_dat_bits_data)
    `CHECK(io_in_rx_dat_bits_dataCheck)
    `CHECK(io_in_rx_dat_bits_poison)
    `CHECK(io_in_rx_snp_valid)
    `CHECK(io_in_rx_snp_bits_qos)
    `CHECK(io_in_rx_snp_bits_srcID)
    `CHECK(io_in_rx_snp_bits_txnID)
    `CHECK(io_in_rx_snp_bits_fwdNID)
    `CHECK(io_in_rx_snp_bits_fwdTxnID)
    `CHECK(io_in_rx_snp_bits_opcode)
    `CHECK(io_in_rx_snp_bits_addr)
    `CHECK(io_in_rx_snp_bits_ns)
    `CHECK(io_in_rx_snp_bits_doNotGoToSD)
    `CHECK(io_in_rx_snp_bits_retToSrc)
    `CHECK(io_in_rx_snp_bits_traceTag)
    `CHECK(io_in_rx_snp_bits_mpam_perfMonGroup)
    `CHECK(io_in_rx_snp_bits_mpam_partID)
    `CHECK(io_in_rx_snp_bits_mpam_mpamNS)
    `CHECK(io_out_txsactive)
    `CHECK(io_out_syscoreq)
    `CHECK(io_out_tx_linkactivereq)
    `CHECK(io_out_tx_req_flitpend)
    `CHECK(io_out_tx_req_flitv)
    `CHECK(io_out_tx_req_flit)
    `CHECK(io_out_tx_rsp_flitpend)
    `CHECK(io_out_tx_rsp_flitv)
    `CHECK(io_out_tx_rsp_flit)
    `CHECK(io_out_tx_dat_flitpend)
    `CHECK(io_out_tx_dat_flitv)
    `CHECK(io_out_tx_dat_flit)
    `CHECK(io_out_rx_linkactiveack)
    `CHECK(io_out_rx_rsp_lcrdv)
    `CHECK(io_out_rx_dat_lcrdv)
    `CHECK(io_out_rx_snp_lcrdv)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_tx_req_valid = '0;
    io_in_tx_req_bits_qos = '0;
    io_in_tx_req_bits_tgtID = '0;
    io_in_tx_req_bits_txnID = '0;
    io_in_tx_req_bits_returnNID = '0;
    io_in_tx_req_bits_stashNIDValid = '0;
    io_in_tx_req_bits_returnTxnID = '0;
    io_in_tx_req_bits_opcode = '0;
    io_in_tx_req_bits_size = '0;
    io_in_tx_req_bits_addr = '0;
    io_in_tx_req_bits_ns = '0;
    io_in_tx_req_bits_likelyshared = '0;
    io_in_tx_req_bits_allowRetry = '0;
    io_in_tx_req_bits_order = '0;
    io_in_tx_req_bits_pCrdType = '0;
    io_in_tx_req_bits_memAttr_allocate = '0;
    io_in_tx_req_bits_memAttr_cacheable = '0;
    io_in_tx_req_bits_memAttr_device = '0;
    io_in_tx_req_bits_memAttr_ewa = '0;
    io_in_tx_req_bits_snpAttr = '0;
    io_in_tx_req_bits_lpIDWithPadding = '0;
    io_in_tx_req_bits_snoopMe = '0;
    io_in_tx_req_bits_expCompAck = '0;
    io_in_tx_req_bits_tagOp = '0;
    io_in_tx_req_bits_traceTag = '0;
    io_in_tx_req_bits_mpam_perfMonGroup = '0;
    io_in_tx_req_bits_mpam_partID = '0;
    io_in_tx_req_bits_mpam_mpamNS = '0;
    io_in_tx_req_bits_rsvdc = '0;
    io_in_tx_rsp_valid = '0;
    io_in_tx_rsp_bits_qos = '0;
    io_in_tx_rsp_bits_tgtID = '0;
    io_in_tx_rsp_bits_txnID = '0;
    io_in_tx_rsp_bits_opcode = '0;
    io_in_tx_rsp_bits_respErr = '0;
    io_in_tx_rsp_bits_resp = '0;
    io_in_tx_rsp_bits_fwdState = '0;
    io_in_tx_rsp_bits_cBusy = '0;
    io_in_tx_rsp_bits_dbID = '0;
    io_in_tx_rsp_bits_pCrdType = '0;
    io_in_tx_rsp_bits_tagOp = '0;
    io_in_tx_rsp_bits_traceTag = '0;
    io_in_tx_dat_valid = '0;
    io_in_tx_dat_bits_qos = '0;
    io_in_tx_dat_bits_tgtID = '0;
    io_in_tx_dat_bits_txnID = '0;
    io_in_tx_dat_bits_homeNID = '0;
    io_in_tx_dat_bits_opcode = '0;
    io_in_tx_dat_bits_respErr = '0;
    io_in_tx_dat_bits_resp = '0;
    io_in_tx_dat_bits_dataSource = '0;
    io_in_tx_dat_bits_cBusy = '0;
    io_in_tx_dat_bits_dbID = '0;
    io_in_tx_dat_bits_ccID = '0;
    io_in_tx_dat_bits_dataID = '0;
    io_in_tx_dat_bits_tagOp = '0;
    io_in_tx_dat_bits_tag = '0;
    io_in_tx_dat_bits_tu = '0;
    io_in_tx_dat_bits_traceTag = '0;
    io_in_tx_dat_bits_rsvdc = '0;
    io_in_tx_dat_bits_be = '0;
    io_in_tx_dat_bits_data = '0;
    io_in_tx_dat_bits_dataCheck = '0;
    io_in_tx_dat_bits_poison = '0;
    io_in_rx_rsp_ready = '0;
    io_in_rx_dat_ready = '0;
    io_in_rx_snp_ready = '0;
    io_out_rxsactive = '0;
    io_out_syscoack = '0;
    io_out_tx_linkactiveack = '0;
    io_out_tx_req_lcrdv = '0;
    io_out_tx_rsp_lcrdv = '0;
    io_out_tx_dat_lcrdv = '0;
    io_out_rx_linkactivereq = '0;
    io_out_rx_rsp_flitpend = '0;
    io_out_rx_rsp_flitv = '0;
    io_out_rx_rsp_flit = '0;
    io_out_rx_dat_flitpend = '0;
    io_out_rx_dat_flitv = '0;
    io_out_rx_dat_flit = '0;
    io_out_rx_snp_flitpend = '0;
    io_out_rx_snp_flitv = '0;
    io_out_rx_snp_flit = '0;
    io_nodeID = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("LinkMonitor checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
