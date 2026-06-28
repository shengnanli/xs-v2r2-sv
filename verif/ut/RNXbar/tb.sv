// 自动生成：scripts/gen_rnxbar.py —— 勿手改
// RNXbar 双例化逐拍比对: golden RNXbar vs 可读 RNXbar_xs。
// 激励: RN (io_in_0) 的 TXREQ/TXRSP/TXDAT valid+载荷全随机 (addr[7:6]/txnID[10:9]
//       全宽随机 ⇒ 均匀覆盖 4 路 TX 路由拆分); 4 个 HN bank 的 RXSNP/RXRSP/RXDAT
//       valid+载荷全随机 (覆盖 3 个 4 输入仲裁器的争用 + snoop 跟踪状态机的接收/
//       投递时序); io_snp_mask_set 及各侧 ready 随机背压。
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
// 内部探针: snoop 跟踪状态机寄存器 (golden 与可读核同名标量, 逐拍对拍)。
`define PCHECK(GPATH, IPATH) begin \
  if (!$isunknown(GPATH)) begin \
    pchecks++; \
    if (GPATH !== IPATH) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] PROBE MISMATCH %s g=%0h i=%0h", $time, `"GPATH`", GPATH, IPATH); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  int pchecks = 0;
  always #5 clock = ~clock;

  logic io_in_0_tx_req_valid;
  logic [3:0] io_in_0_tx_req_bits_qos;
  logic [10:0] io_in_0_tx_req_bits_tgtID;
  logic [10:0] io_in_0_tx_req_bits_srcID;
  logic [11:0] io_in_0_tx_req_bits_txnID;
  logic [10:0] io_in_0_tx_req_bits_returnNID;
  logic io_in_0_tx_req_bits_stashNIDValid;
  logic [11:0] io_in_0_tx_req_bits_returnTxnID;
  logic [6:0] io_in_0_tx_req_bits_opcode;
  logic [2:0] io_in_0_tx_req_bits_size;
  logic [47:0] io_in_0_tx_req_bits_addr;
  logic io_in_0_tx_req_bits_ns;
  logic io_in_0_tx_req_bits_likelyshared;
  logic io_in_0_tx_req_bits_allowRetry;
  logic [1:0] io_in_0_tx_req_bits_order;
  logic [3:0] io_in_0_tx_req_bits_pCrdType;
  logic io_in_0_tx_req_bits_memAttr_allocate;
  logic io_in_0_tx_req_bits_memAttr_cacheable;
  logic io_in_0_tx_req_bits_memAttr_device;
  logic io_in_0_tx_req_bits_memAttr_ewa;
  logic io_in_0_tx_req_bits_snpAttr;
  logic [7:0] io_in_0_tx_req_bits_lpIDWithPadding;
  logic io_in_0_tx_req_bits_snoopMe;
  logic io_in_0_tx_req_bits_expCompAck;
  logic [1:0] io_in_0_tx_req_bits_tagOp;
  logic io_in_0_tx_req_bits_traceTag;
  logic io_in_0_tx_req_bits_mpam_perfMonGroup;
  logic [8:0] io_in_0_tx_req_bits_mpam_partID;
  logic io_in_0_tx_req_bits_mpam_mpamNS;
  logic [3:0] io_in_0_tx_req_bits_rsvdc;
  logic io_in_0_tx_rsp_valid;
  logic [10:0] io_in_0_tx_rsp_bits_srcID;
  logic [11:0] io_in_0_tx_rsp_bits_txnID;
  logic [4:0] io_in_0_tx_rsp_bits_opcode;
  logic [11:0] io_in_0_tx_rsp_bits_dbID;
  logic io_in_0_tx_dat_valid;
  logic [3:0] io_in_0_tx_dat_bits_qos;
  logic [10:0] io_in_0_tx_dat_bits_tgtID;
  logic [10:0] io_in_0_tx_dat_bits_srcID;
  logic [11:0] io_in_0_tx_dat_bits_txnID;
  logic [10:0] io_in_0_tx_dat_bits_homeNID;
  logic [3:0] io_in_0_tx_dat_bits_opcode;
  logic [1:0] io_in_0_tx_dat_bits_respErr;
  logic [2:0] io_in_0_tx_dat_bits_resp;
  logic [3:0] io_in_0_tx_dat_bits_dataSource;
  logic [2:0] io_in_0_tx_dat_bits_cBusy;
  logic [11:0] io_in_0_tx_dat_bits_dbID;
  logic [1:0] io_in_0_tx_dat_bits_ccID;
  logic [1:0] io_in_0_tx_dat_bits_dataID;
  logic [1:0] io_in_0_tx_dat_bits_tagOp;
  logic [7:0] io_in_0_tx_dat_bits_tag;
  logic [1:0] io_in_0_tx_dat_bits_tu;
  logic io_in_0_tx_dat_bits_traceTag;
  logic [3:0] io_in_0_tx_dat_bits_rsvdc;
  logic [31:0] io_in_0_tx_dat_bits_be;
  logic [255:0] io_in_0_tx_dat_bits_data;
  logic [31:0] io_in_0_tx_dat_bits_dataCheck;
  logic [3:0] io_in_0_tx_dat_bits_poison;
  logic io_in_0_rx_rsp_ready;
  logic io_in_0_rx_dat_ready;
  logic io_in_0_rx_snp_ready;
  logic io_out_0_tx_req_ready;
  logic io_out_0_rx_rsp_valid;
  logic [10:0] io_out_0_rx_rsp_bits_tgtID;
  logic [10:0] io_out_0_rx_rsp_bits_srcID;
  logic [11:0] io_out_0_rx_rsp_bits_txnID;
  logic [4:0] io_out_0_rx_rsp_bits_opcode;
  logic [2:0] io_out_0_rx_rsp_bits_resp;
  logic [2:0] io_out_0_rx_rsp_bits_fwdState;
  logic [11:0] io_out_0_rx_rsp_bits_dbID;
  logic [3:0] io_out_0_rx_rsp_bits_pCrdType;
  logic io_out_0_rx_dat_valid;
  logic [10:0] io_out_0_rx_dat_bits_tgtID;
  logic [10:0] io_out_0_rx_dat_bits_srcID;
  logic [11:0] io_out_0_rx_dat_bits_txnID;
  logic [10:0] io_out_0_rx_dat_bits_homeNID;
  logic [3:0] io_out_0_rx_dat_bits_opcode;
  logic [2:0] io_out_0_rx_dat_bits_resp;
  logic [3:0] io_out_0_rx_dat_bits_dataSource;
  logic [11:0] io_out_0_rx_dat_bits_dbID;
  logic [1:0] io_out_0_rx_dat_bits_dataID;
  logic [31:0] io_out_0_rx_dat_bits_be;
  logic [255:0] io_out_0_rx_dat_bits_data;
  logic [31:0] io_out_0_rx_dat_bits_dataCheck;
  logic io_out_0_rx_snp_valid;
  logic [11:0] io_out_0_rx_snp_bits_txnID;
  logic [10:0] io_out_0_rx_snp_bits_fwdNID;
  logic [11:0] io_out_0_rx_snp_bits_fwdTxnID;
  logic [4:0] io_out_0_rx_snp_bits_opcode;
  logic [44:0] io_out_0_rx_snp_bits_addr;
  logic io_out_0_rx_snp_bits_doNotGoToSD;
  logic io_out_0_rx_snp_bits_retToSrc;
  logic io_out_1_tx_req_ready;
  logic io_out_1_rx_rsp_valid;
  logic [10:0] io_out_1_rx_rsp_bits_tgtID;
  logic [10:0] io_out_1_rx_rsp_bits_srcID;
  logic [11:0] io_out_1_rx_rsp_bits_txnID;
  logic [4:0] io_out_1_rx_rsp_bits_opcode;
  logic [2:0] io_out_1_rx_rsp_bits_resp;
  logic [2:0] io_out_1_rx_rsp_bits_fwdState;
  logic [11:0] io_out_1_rx_rsp_bits_dbID;
  logic [3:0] io_out_1_rx_rsp_bits_pCrdType;
  logic io_out_1_rx_dat_valid;
  logic [10:0] io_out_1_rx_dat_bits_tgtID;
  logic [10:0] io_out_1_rx_dat_bits_srcID;
  logic [11:0] io_out_1_rx_dat_bits_txnID;
  logic [10:0] io_out_1_rx_dat_bits_homeNID;
  logic [3:0] io_out_1_rx_dat_bits_opcode;
  logic [2:0] io_out_1_rx_dat_bits_resp;
  logic [3:0] io_out_1_rx_dat_bits_dataSource;
  logic [11:0] io_out_1_rx_dat_bits_dbID;
  logic [1:0] io_out_1_rx_dat_bits_dataID;
  logic [31:0] io_out_1_rx_dat_bits_be;
  logic [255:0] io_out_1_rx_dat_bits_data;
  logic [31:0] io_out_1_rx_dat_bits_dataCheck;
  logic io_out_1_rx_snp_valid;
  logic [11:0] io_out_1_rx_snp_bits_txnID;
  logic [10:0] io_out_1_rx_snp_bits_fwdNID;
  logic [11:0] io_out_1_rx_snp_bits_fwdTxnID;
  logic [4:0] io_out_1_rx_snp_bits_opcode;
  logic [44:0] io_out_1_rx_snp_bits_addr;
  logic io_out_1_rx_snp_bits_doNotGoToSD;
  logic io_out_1_rx_snp_bits_retToSrc;
  logic io_out_2_tx_req_ready;
  logic io_out_2_rx_rsp_valid;
  logic [10:0] io_out_2_rx_rsp_bits_tgtID;
  logic [10:0] io_out_2_rx_rsp_bits_srcID;
  logic [11:0] io_out_2_rx_rsp_bits_txnID;
  logic [4:0] io_out_2_rx_rsp_bits_opcode;
  logic [2:0] io_out_2_rx_rsp_bits_resp;
  logic [2:0] io_out_2_rx_rsp_bits_fwdState;
  logic [11:0] io_out_2_rx_rsp_bits_dbID;
  logic [3:0] io_out_2_rx_rsp_bits_pCrdType;
  logic io_out_2_rx_dat_valid;
  logic [10:0] io_out_2_rx_dat_bits_tgtID;
  logic [10:0] io_out_2_rx_dat_bits_srcID;
  logic [11:0] io_out_2_rx_dat_bits_txnID;
  logic [10:0] io_out_2_rx_dat_bits_homeNID;
  logic [3:0] io_out_2_rx_dat_bits_opcode;
  logic [2:0] io_out_2_rx_dat_bits_resp;
  logic [3:0] io_out_2_rx_dat_bits_dataSource;
  logic [11:0] io_out_2_rx_dat_bits_dbID;
  logic [1:0] io_out_2_rx_dat_bits_dataID;
  logic [31:0] io_out_2_rx_dat_bits_be;
  logic [255:0] io_out_2_rx_dat_bits_data;
  logic [31:0] io_out_2_rx_dat_bits_dataCheck;
  logic io_out_2_rx_snp_valid;
  logic [11:0] io_out_2_rx_snp_bits_txnID;
  logic [10:0] io_out_2_rx_snp_bits_fwdNID;
  logic [11:0] io_out_2_rx_snp_bits_fwdTxnID;
  logic [4:0] io_out_2_rx_snp_bits_opcode;
  logic [44:0] io_out_2_rx_snp_bits_addr;
  logic io_out_2_rx_snp_bits_doNotGoToSD;
  logic io_out_2_rx_snp_bits_retToSrc;
  logic io_out_3_tx_req_ready;
  logic io_out_3_rx_rsp_valid;
  logic [10:0] io_out_3_rx_rsp_bits_tgtID;
  logic [10:0] io_out_3_rx_rsp_bits_srcID;
  logic [11:0] io_out_3_rx_rsp_bits_txnID;
  logic [4:0] io_out_3_rx_rsp_bits_opcode;
  logic [2:0] io_out_3_rx_rsp_bits_resp;
  logic [2:0] io_out_3_rx_rsp_bits_fwdState;
  logic [11:0] io_out_3_rx_rsp_bits_dbID;
  logic [3:0] io_out_3_rx_rsp_bits_pCrdType;
  logic io_out_3_rx_dat_valid;
  logic [10:0] io_out_3_rx_dat_bits_tgtID;
  logic [10:0] io_out_3_rx_dat_bits_srcID;
  logic [11:0] io_out_3_rx_dat_bits_txnID;
  logic [10:0] io_out_3_rx_dat_bits_homeNID;
  logic [3:0] io_out_3_rx_dat_bits_opcode;
  logic [2:0] io_out_3_rx_dat_bits_resp;
  logic [3:0] io_out_3_rx_dat_bits_dataSource;
  logic [11:0] io_out_3_rx_dat_bits_dbID;
  logic [1:0] io_out_3_rx_dat_bits_dataID;
  logic [31:0] io_out_3_rx_dat_bits_be;
  logic [255:0] io_out_3_rx_dat_bits_data;
  logic [31:0] io_out_3_rx_dat_bits_dataCheck;
  logic io_out_3_rx_snp_valid;
  logic [11:0] io_out_3_rx_snp_bits_txnID;
  logic [10:0] io_out_3_rx_snp_bits_fwdNID;
  logic [11:0] io_out_3_rx_snp_bits_fwdTxnID;
  logic [4:0] io_out_3_rx_snp_bits_opcode;
  logic [44:0] io_out_3_rx_snp_bits_addr;
  logic io_out_3_rx_snp_bits_doNotGoToSD;
  logic io_out_3_rx_snp_bits_retToSrc;
  logic io_snpMasks_0_0;
  logic io_snpMasks_1_0;
  logic io_snpMasks_2_0;
  logic io_snpMasks_3_0;
  wire g_io_in_0_tx_req_ready;
  wire i_io_in_0_tx_req_ready;
  wire g_io_in_0_tx_rsp_ready;
  wire i_io_in_0_tx_rsp_ready;
  wire g_io_in_0_tx_dat_ready;
  wire i_io_in_0_tx_dat_ready;
  wire g_io_in_0_rx_rsp_valid;
  wire i_io_in_0_rx_rsp_valid;
  wire [3:0] g_io_in_0_rx_rsp_bits_qos;
  wire [3:0] i_io_in_0_rx_rsp_bits_qos;
  wire [11:0] g_io_in_0_rx_rsp_bits_txnID;
  wire [11:0] i_io_in_0_rx_rsp_bits_txnID;
  wire [4:0] g_io_in_0_rx_rsp_bits_opcode;
  wire [4:0] i_io_in_0_rx_rsp_bits_opcode;
  wire [1:0] g_io_in_0_rx_rsp_bits_respErr;
  wire [1:0] i_io_in_0_rx_rsp_bits_respErr;
  wire [2:0] g_io_in_0_rx_rsp_bits_resp;
  wire [2:0] i_io_in_0_rx_rsp_bits_resp;
  wire [2:0] g_io_in_0_rx_rsp_bits_fwdState;
  wire [2:0] i_io_in_0_rx_rsp_bits_fwdState;
  wire [2:0] g_io_in_0_rx_rsp_bits_cBusy;
  wire [2:0] i_io_in_0_rx_rsp_bits_cBusy;
  wire [11:0] g_io_in_0_rx_rsp_bits_dbID;
  wire [11:0] i_io_in_0_rx_rsp_bits_dbID;
  wire [3:0] g_io_in_0_rx_rsp_bits_pCrdType;
  wire [3:0] i_io_in_0_rx_rsp_bits_pCrdType;
  wire [1:0] g_io_in_0_rx_rsp_bits_tagOp;
  wire [1:0] i_io_in_0_rx_rsp_bits_tagOp;
  wire g_io_in_0_rx_rsp_bits_traceTag;
  wire i_io_in_0_rx_rsp_bits_traceTag;
  wire g_io_in_0_rx_dat_valid;
  wire i_io_in_0_rx_dat_valid;
  wire [11:0] g_io_in_0_rx_dat_bits_txnID;
  wire [11:0] i_io_in_0_rx_dat_bits_txnID;
  wire [10:0] g_io_in_0_rx_dat_bits_homeNID;
  wire [10:0] i_io_in_0_rx_dat_bits_homeNID;
  wire [3:0] g_io_in_0_rx_dat_bits_opcode;
  wire [3:0] i_io_in_0_rx_dat_bits_opcode;
  wire [2:0] g_io_in_0_rx_dat_bits_resp;
  wire [2:0] i_io_in_0_rx_dat_bits_resp;
  wire [3:0] g_io_in_0_rx_dat_bits_dataSource;
  wire [3:0] i_io_in_0_rx_dat_bits_dataSource;
  wire [11:0] g_io_in_0_rx_dat_bits_dbID;
  wire [11:0] i_io_in_0_rx_dat_bits_dbID;
  wire [1:0] g_io_in_0_rx_dat_bits_dataID;
  wire [1:0] i_io_in_0_rx_dat_bits_dataID;
  wire [31:0] g_io_in_0_rx_dat_bits_be;
  wire [31:0] i_io_in_0_rx_dat_bits_be;
  wire [255:0] g_io_in_0_rx_dat_bits_data;
  wire [255:0] i_io_in_0_rx_dat_bits_data;
  wire [31:0] g_io_in_0_rx_dat_bits_dataCheck;
  wire [31:0] i_io_in_0_rx_dat_bits_dataCheck;
  wire g_io_in_0_rx_snp_valid;
  wire i_io_in_0_rx_snp_valid;
  wire [11:0] g_io_in_0_rx_snp_bits_txnID;
  wire [11:0] i_io_in_0_rx_snp_bits_txnID;
  wire [10:0] g_io_in_0_rx_snp_bits_fwdNID;
  wire [10:0] i_io_in_0_rx_snp_bits_fwdNID;
  wire [11:0] g_io_in_0_rx_snp_bits_fwdTxnID;
  wire [11:0] i_io_in_0_rx_snp_bits_fwdTxnID;
  wire [4:0] g_io_in_0_rx_snp_bits_opcode;
  wire [4:0] i_io_in_0_rx_snp_bits_opcode;
  wire [44:0] g_io_in_0_rx_snp_bits_addr;
  wire [44:0] i_io_in_0_rx_snp_bits_addr;
  wire g_io_in_0_rx_snp_bits_doNotGoToSD;
  wire i_io_in_0_rx_snp_bits_doNotGoToSD;
  wire g_io_in_0_rx_snp_bits_retToSrc;
  wire i_io_in_0_rx_snp_bits_retToSrc;
  wire g_io_out_0_tx_req_valid;
  wire i_io_out_0_tx_req_valid;
  wire [10:0] g_io_out_0_tx_req_bits_tgtID;
  wire [10:0] i_io_out_0_tx_req_bits_tgtID;
  wire [10:0] g_io_out_0_tx_req_bits_srcID;
  wire [10:0] i_io_out_0_tx_req_bits_srcID;
  wire [11:0] g_io_out_0_tx_req_bits_txnID;
  wire [11:0] i_io_out_0_tx_req_bits_txnID;
  wire [6:0] g_io_out_0_tx_req_bits_opcode;
  wire [6:0] i_io_out_0_tx_req_bits_opcode;
  wire [2:0] g_io_out_0_tx_req_bits_size;
  wire [2:0] i_io_out_0_tx_req_bits_size;
  wire [47:0] g_io_out_0_tx_req_bits_addr;
  wire [47:0] i_io_out_0_tx_req_bits_addr;
  wire g_io_out_0_tx_req_bits_allowRetry;
  wire i_io_out_0_tx_req_bits_allowRetry;
  wire [1:0] g_io_out_0_tx_req_bits_order;
  wire [1:0] i_io_out_0_tx_req_bits_order;
  wire [3:0] g_io_out_0_tx_req_bits_pCrdType;
  wire [3:0] i_io_out_0_tx_req_bits_pCrdType;
  wire g_io_out_0_tx_req_bits_memAttr_allocate;
  wire i_io_out_0_tx_req_bits_memAttr_allocate;
  wire g_io_out_0_tx_req_bits_memAttr_cacheable;
  wire i_io_out_0_tx_req_bits_memAttr_cacheable;
  wire g_io_out_0_tx_req_bits_memAttr_device;
  wire i_io_out_0_tx_req_bits_memAttr_device;
  wire g_io_out_0_tx_req_bits_memAttr_ewa;
  wire i_io_out_0_tx_req_bits_memAttr_ewa;
  wire g_io_out_0_tx_req_bits_snpAttr;
  wire i_io_out_0_tx_req_bits_snpAttr;
  wire g_io_out_0_tx_req_bits_expCompAck;
  wire i_io_out_0_tx_req_bits_expCompAck;
  wire g_io_out_0_tx_rsp_valid;
  wire i_io_out_0_tx_rsp_valid;
  wire [10:0] g_io_out_0_tx_rsp_bits_srcID;
  wire [10:0] i_io_out_0_tx_rsp_bits_srcID;
  wire [11:0] g_io_out_0_tx_rsp_bits_txnID;
  wire [11:0] i_io_out_0_tx_rsp_bits_txnID;
  wire [4:0] g_io_out_0_tx_rsp_bits_opcode;
  wire [4:0] i_io_out_0_tx_rsp_bits_opcode;
  wire [11:0] g_io_out_0_tx_rsp_bits_dbID;
  wire [11:0] i_io_out_0_tx_rsp_bits_dbID;
  wire g_io_out_0_tx_dat_valid;
  wire i_io_out_0_tx_dat_valid;
  wire [10:0] g_io_out_0_tx_dat_bits_srcID;
  wire [10:0] i_io_out_0_tx_dat_bits_srcID;
  wire [11:0] g_io_out_0_tx_dat_bits_txnID;
  wire [11:0] i_io_out_0_tx_dat_bits_txnID;
  wire [3:0] g_io_out_0_tx_dat_bits_opcode;
  wire [3:0] i_io_out_0_tx_dat_bits_opcode;
  wire [2:0] g_io_out_0_tx_dat_bits_resp;
  wire [2:0] i_io_out_0_tx_dat_bits_resp;
  wire [1:0] g_io_out_0_tx_dat_bits_dataID;
  wire [1:0] i_io_out_0_tx_dat_bits_dataID;
  wire [255:0] g_io_out_0_tx_dat_bits_data;
  wire [255:0] i_io_out_0_tx_dat_bits_data;
  wire g_io_out_0_rx_rsp_ready;
  wire i_io_out_0_rx_rsp_ready;
  wire g_io_out_0_rx_dat_ready;
  wire i_io_out_0_rx_dat_ready;
  wire g_io_out_0_rx_snp_ready;
  wire i_io_out_0_rx_snp_ready;
  wire g_io_out_1_tx_req_valid;
  wire i_io_out_1_tx_req_valid;
  wire [10:0] g_io_out_1_tx_req_bits_tgtID;
  wire [10:0] i_io_out_1_tx_req_bits_tgtID;
  wire [10:0] g_io_out_1_tx_req_bits_srcID;
  wire [10:0] i_io_out_1_tx_req_bits_srcID;
  wire [11:0] g_io_out_1_tx_req_bits_txnID;
  wire [11:0] i_io_out_1_tx_req_bits_txnID;
  wire [6:0] g_io_out_1_tx_req_bits_opcode;
  wire [6:0] i_io_out_1_tx_req_bits_opcode;
  wire [2:0] g_io_out_1_tx_req_bits_size;
  wire [2:0] i_io_out_1_tx_req_bits_size;
  wire [47:0] g_io_out_1_tx_req_bits_addr;
  wire [47:0] i_io_out_1_tx_req_bits_addr;
  wire g_io_out_1_tx_req_bits_allowRetry;
  wire i_io_out_1_tx_req_bits_allowRetry;
  wire [1:0] g_io_out_1_tx_req_bits_order;
  wire [1:0] i_io_out_1_tx_req_bits_order;
  wire [3:0] g_io_out_1_tx_req_bits_pCrdType;
  wire [3:0] i_io_out_1_tx_req_bits_pCrdType;
  wire g_io_out_1_tx_req_bits_memAttr_allocate;
  wire i_io_out_1_tx_req_bits_memAttr_allocate;
  wire g_io_out_1_tx_req_bits_memAttr_cacheable;
  wire i_io_out_1_tx_req_bits_memAttr_cacheable;
  wire g_io_out_1_tx_req_bits_memAttr_device;
  wire i_io_out_1_tx_req_bits_memAttr_device;
  wire g_io_out_1_tx_req_bits_memAttr_ewa;
  wire i_io_out_1_tx_req_bits_memAttr_ewa;
  wire g_io_out_1_tx_req_bits_snpAttr;
  wire i_io_out_1_tx_req_bits_snpAttr;
  wire g_io_out_1_tx_req_bits_expCompAck;
  wire i_io_out_1_tx_req_bits_expCompAck;
  wire g_io_out_1_tx_rsp_valid;
  wire i_io_out_1_tx_rsp_valid;
  wire [10:0] g_io_out_1_tx_rsp_bits_srcID;
  wire [10:0] i_io_out_1_tx_rsp_bits_srcID;
  wire [11:0] g_io_out_1_tx_rsp_bits_txnID;
  wire [11:0] i_io_out_1_tx_rsp_bits_txnID;
  wire [4:0] g_io_out_1_tx_rsp_bits_opcode;
  wire [4:0] i_io_out_1_tx_rsp_bits_opcode;
  wire [11:0] g_io_out_1_tx_rsp_bits_dbID;
  wire [11:0] i_io_out_1_tx_rsp_bits_dbID;
  wire g_io_out_1_tx_dat_valid;
  wire i_io_out_1_tx_dat_valid;
  wire [10:0] g_io_out_1_tx_dat_bits_srcID;
  wire [10:0] i_io_out_1_tx_dat_bits_srcID;
  wire [11:0] g_io_out_1_tx_dat_bits_txnID;
  wire [11:0] i_io_out_1_tx_dat_bits_txnID;
  wire [3:0] g_io_out_1_tx_dat_bits_opcode;
  wire [3:0] i_io_out_1_tx_dat_bits_opcode;
  wire [2:0] g_io_out_1_tx_dat_bits_resp;
  wire [2:0] i_io_out_1_tx_dat_bits_resp;
  wire [1:0] g_io_out_1_tx_dat_bits_dataID;
  wire [1:0] i_io_out_1_tx_dat_bits_dataID;
  wire [255:0] g_io_out_1_tx_dat_bits_data;
  wire [255:0] i_io_out_1_tx_dat_bits_data;
  wire g_io_out_1_rx_rsp_ready;
  wire i_io_out_1_rx_rsp_ready;
  wire g_io_out_1_rx_dat_ready;
  wire i_io_out_1_rx_dat_ready;
  wire g_io_out_1_rx_snp_ready;
  wire i_io_out_1_rx_snp_ready;
  wire g_io_out_2_tx_req_valid;
  wire i_io_out_2_tx_req_valid;
  wire [10:0] g_io_out_2_tx_req_bits_tgtID;
  wire [10:0] i_io_out_2_tx_req_bits_tgtID;
  wire [10:0] g_io_out_2_tx_req_bits_srcID;
  wire [10:0] i_io_out_2_tx_req_bits_srcID;
  wire [11:0] g_io_out_2_tx_req_bits_txnID;
  wire [11:0] i_io_out_2_tx_req_bits_txnID;
  wire [6:0] g_io_out_2_tx_req_bits_opcode;
  wire [6:0] i_io_out_2_tx_req_bits_opcode;
  wire [2:0] g_io_out_2_tx_req_bits_size;
  wire [2:0] i_io_out_2_tx_req_bits_size;
  wire [47:0] g_io_out_2_tx_req_bits_addr;
  wire [47:0] i_io_out_2_tx_req_bits_addr;
  wire g_io_out_2_tx_req_bits_allowRetry;
  wire i_io_out_2_tx_req_bits_allowRetry;
  wire [1:0] g_io_out_2_tx_req_bits_order;
  wire [1:0] i_io_out_2_tx_req_bits_order;
  wire [3:0] g_io_out_2_tx_req_bits_pCrdType;
  wire [3:0] i_io_out_2_tx_req_bits_pCrdType;
  wire g_io_out_2_tx_req_bits_memAttr_allocate;
  wire i_io_out_2_tx_req_bits_memAttr_allocate;
  wire g_io_out_2_tx_req_bits_memAttr_cacheable;
  wire i_io_out_2_tx_req_bits_memAttr_cacheable;
  wire g_io_out_2_tx_req_bits_memAttr_device;
  wire i_io_out_2_tx_req_bits_memAttr_device;
  wire g_io_out_2_tx_req_bits_memAttr_ewa;
  wire i_io_out_2_tx_req_bits_memAttr_ewa;
  wire g_io_out_2_tx_req_bits_snpAttr;
  wire i_io_out_2_tx_req_bits_snpAttr;
  wire g_io_out_2_tx_req_bits_expCompAck;
  wire i_io_out_2_tx_req_bits_expCompAck;
  wire g_io_out_2_tx_rsp_valid;
  wire i_io_out_2_tx_rsp_valid;
  wire [10:0] g_io_out_2_tx_rsp_bits_srcID;
  wire [10:0] i_io_out_2_tx_rsp_bits_srcID;
  wire [11:0] g_io_out_2_tx_rsp_bits_txnID;
  wire [11:0] i_io_out_2_tx_rsp_bits_txnID;
  wire [4:0] g_io_out_2_tx_rsp_bits_opcode;
  wire [4:0] i_io_out_2_tx_rsp_bits_opcode;
  wire [11:0] g_io_out_2_tx_rsp_bits_dbID;
  wire [11:0] i_io_out_2_tx_rsp_bits_dbID;
  wire g_io_out_2_tx_dat_valid;
  wire i_io_out_2_tx_dat_valid;
  wire [10:0] g_io_out_2_tx_dat_bits_srcID;
  wire [10:0] i_io_out_2_tx_dat_bits_srcID;
  wire [11:0] g_io_out_2_tx_dat_bits_txnID;
  wire [11:0] i_io_out_2_tx_dat_bits_txnID;
  wire [3:0] g_io_out_2_tx_dat_bits_opcode;
  wire [3:0] i_io_out_2_tx_dat_bits_opcode;
  wire [2:0] g_io_out_2_tx_dat_bits_resp;
  wire [2:0] i_io_out_2_tx_dat_bits_resp;
  wire [1:0] g_io_out_2_tx_dat_bits_dataID;
  wire [1:0] i_io_out_2_tx_dat_bits_dataID;
  wire [255:0] g_io_out_2_tx_dat_bits_data;
  wire [255:0] i_io_out_2_tx_dat_bits_data;
  wire g_io_out_2_rx_rsp_ready;
  wire i_io_out_2_rx_rsp_ready;
  wire g_io_out_2_rx_dat_ready;
  wire i_io_out_2_rx_dat_ready;
  wire g_io_out_2_rx_snp_ready;
  wire i_io_out_2_rx_snp_ready;
  wire g_io_out_3_tx_req_valid;
  wire i_io_out_3_tx_req_valid;
  wire [10:0] g_io_out_3_tx_req_bits_tgtID;
  wire [10:0] i_io_out_3_tx_req_bits_tgtID;
  wire [10:0] g_io_out_3_tx_req_bits_srcID;
  wire [10:0] i_io_out_3_tx_req_bits_srcID;
  wire [11:0] g_io_out_3_tx_req_bits_txnID;
  wire [11:0] i_io_out_3_tx_req_bits_txnID;
  wire [6:0] g_io_out_3_tx_req_bits_opcode;
  wire [6:0] i_io_out_3_tx_req_bits_opcode;
  wire [2:0] g_io_out_3_tx_req_bits_size;
  wire [2:0] i_io_out_3_tx_req_bits_size;
  wire [47:0] g_io_out_3_tx_req_bits_addr;
  wire [47:0] i_io_out_3_tx_req_bits_addr;
  wire g_io_out_3_tx_req_bits_allowRetry;
  wire i_io_out_3_tx_req_bits_allowRetry;
  wire [1:0] g_io_out_3_tx_req_bits_order;
  wire [1:0] i_io_out_3_tx_req_bits_order;
  wire [3:0] g_io_out_3_tx_req_bits_pCrdType;
  wire [3:0] i_io_out_3_tx_req_bits_pCrdType;
  wire g_io_out_3_tx_req_bits_memAttr_allocate;
  wire i_io_out_3_tx_req_bits_memAttr_allocate;
  wire g_io_out_3_tx_req_bits_memAttr_cacheable;
  wire i_io_out_3_tx_req_bits_memAttr_cacheable;
  wire g_io_out_3_tx_req_bits_memAttr_device;
  wire i_io_out_3_tx_req_bits_memAttr_device;
  wire g_io_out_3_tx_req_bits_memAttr_ewa;
  wire i_io_out_3_tx_req_bits_memAttr_ewa;
  wire g_io_out_3_tx_req_bits_snpAttr;
  wire i_io_out_3_tx_req_bits_snpAttr;
  wire g_io_out_3_tx_req_bits_expCompAck;
  wire i_io_out_3_tx_req_bits_expCompAck;
  wire g_io_out_3_tx_rsp_valid;
  wire i_io_out_3_tx_rsp_valid;
  wire [10:0] g_io_out_3_tx_rsp_bits_srcID;
  wire [10:0] i_io_out_3_tx_rsp_bits_srcID;
  wire [11:0] g_io_out_3_tx_rsp_bits_txnID;
  wire [11:0] i_io_out_3_tx_rsp_bits_txnID;
  wire [4:0] g_io_out_3_tx_rsp_bits_opcode;
  wire [4:0] i_io_out_3_tx_rsp_bits_opcode;
  wire [11:0] g_io_out_3_tx_rsp_bits_dbID;
  wire [11:0] i_io_out_3_tx_rsp_bits_dbID;
  wire g_io_out_3_tx_dat_valid;
  wire i_io_out_3_tx_dat_valid;
  wire [10:0] g_io_out_3_tx_dat_bits_srcID;
  wire [10:0] i_io_out_3_tx_dat_bits_srcID;
  wire [11:0] g_io_out_3_tx_dat_bits_txnID;
  wire [11:0] i_io_out_3_tx_dat_bits_txnID;
  wire [3:0] g_io_out_3_tx_dat_bits_opcode;
  wire [3:0] i_io_out_3_tx_dat_bits_opcode;
  wire [2:0] g_io_out_3_tx_dat_bits_resp;
  wire [2:0] i_io_out_3_tx_dat_bits_resp;
  wire [1:0] g_io_out_3_tx_dat_bits_dataID;
  wire [1:0] i_io_out_3_tx_dat_bits_dataID;
  wire [255:0] g_io_out_3_tx_dat_bits_data;
  wire [255:0] i_io_out_3_tx_dat_bits_data;
  wire g_io_out_3_rx_rsp_ready;
  wire i_io_out_3_rx_rsp_ready;
  wire g_io_out_3_rx_dat_ready;
  wire i_io_out_3_rx_dat_ready;
  wire g_io_out_3_rx_snp_ready;
  wire i_io_out_3_rx_snp_ready;

  RNXbar u_g (
    .clock(clock),
    .reset(reset),
    .io_in_0_tx_req_ready(g_io_in_0_tx_req_ready),
    .io_in_0_tx_req_valid(io_in_0_tx_req_valid),
    .io_in_0_tx_req_bits_qos(io_in_0_tx_req_bits_qos),
    .io_in_0_tx_req_bits_tgtID(io_in_0_tx_req_bits_tgtID),
    .io_in_0_tx_req_bits_srcID(io_in_0_tx_req_bits_srcID),
    .io_in_0_tx_req_bits_txnID(io_in_0_tx_req_bits_txnID),
    .io_in_0_tx_req_bits_returnNID(io_in_0_tx_req_bits_returnNID),
    .io_in_0_tx_req_bits_stashNIDValid(io_in_0_tx_req_bits_stashNIDValid),
    .io_in_0_tx_req_bits_returnTxnID(io_in_0_tx_req_bits_returnTxnID),
    .io_in_0_tx_req_bits_opcode(io_in_0_tx_req_bits_opcode),
    .io_in_0_tx_req_bits_size(io_in_0_tx_req_bits_size),
    .io_in_0_tx_req_bits_addr(io_in_0_tx_req_bits_addr),
    .io_in_0_tx_req_bits_ns(io_in_0_tx_req_bits_ns),
    .io_in_0_tx_req_bits_likelyshared(io_in_0_tx_req_bits_likelyshared),
    .io_in_0_tx_req_bits_allowRetry(io_in_0_tx_req_bits_allowRetry),
    .io_in_0_tx_req_bits_order(io_in_0_tx_req_bits_order),
    .io_in_0_tx_req_bits_pCrdType(io_in_0_tx_req_bits_pCrdType),
    .io_in_0_tx_req_bits_memAttr_allocate(io_in_0_tx_req_bits_memAttr_allocate),
    .io_in_0_tx_req_bits_memAttr_cacheable(io_in_0_tx_req_bits_memAttr_cacheable),
    .io_in_0_tx_req_bits_memAttr_device(io_in_0_tx_req_bits_memAttr_device),
    .io_in_0_tx_req_bits_memAttr_ewa(io_in_0_tx_req_bits_memAttr_ewa),
    .io_in_0_tx_req_bits_snpAttr(io_in_0_tx_req_bits_snpAttr),
    .io_in_0_tx_req_bits_lpIDWithPadding(io_in_0_tx_req_bits_lpIDWithPadding),
    .io_in_0_tx_req_bits_snoopMe(io_in_0_tx_req_bits_snoopMe),
    .io_in_0_tx_req_bits_expCompAck(io_in_0_tx_req_bits_expCompAck),
    .io_in_0_tx_req_bits_tagOp(io_in_0_tx_req_bits_tagOp),
    .io_in_0_tx_req_bits_traceTag(io_in_0_tx_req_bits_traceTag),
    .io_in_0_tx_req_bits_mpam_perfMonGroup(io_in_0_tx_req_bits_mpam_perfMonGroup),
    .io_in_0_tx_req_bits_mpam_partID(io_in_0_tx_req_bits_mpam_partID),
    .io_in_0_tx_req_bits_mpam_mpamNS(io_in_0_tx_req_bits_mpam_mpamNS),
    .io_in_0_tx_req_bits_rsvdc(io_in_0_tx_req_bits_rsvdc),
    .io_in_0_tx_rsp_ready(g_io_in_0_tx_rsp_ready),
    .io_in_0_tx_rsp_valid(io_in_0_tx_rsp_valid),
    .io_in_0_tx_rsp_bits_srcID(io_in_0_tx_rsp_bits_srcID),
    .io_in_0_tx_rsp_bits_txnID(io_in_0_tx_rsp_bits_txnID),
    .io_in_0_tx_rsp_bits_opcode(io_in_0_tx_rsp_bits_opcode),
    .io_in_0_tx_rsp_bits_dbID(io_in_0_tx_rsp_bits_dbID),
    .io_in_0_tx_dat_ready(g_io_in_0_tx_dat_ready),
    .io_in_0_tx_dat_valid(io_in_0_tx_dat_valid),
    .io_in_0_tx_dat_bits_qos(io_in_0_tx_dat_bits_qos),
    .io_in_0_tx_dat_bits_tgtID(io_in_0_tx_dat_bits_tgtID),
    .io_in_0_tx_dat_bits_srcID(io_in_0_tx_dat_bits_srcID),
    .io_in_0_tx_dat_bits_txnID(io_in_0_tx_dat_bits_txnID),
    .io_in_0_tx_dat_bits_homeNID(io_in_0_tx_dat_bits_homeNID),
    .io_in_0_tx_dat_bits_opcode(io_in_0_tx_dat_bits_opcode),
    .io_in_0_tx_dat_bits_respErr(io_in_0_tx_dat_bits_respErr),
    .io_in_0_tx_dat_bits_resp(io_in_0_tx_dat_bits_resp),
    .io_in_0_tx_dat_bits_dataSource(io_in_0_tx_dat_bits_dataSource),
    .io_in_0_tx_dat_bits_cBusy(io_in_0_tx_dat_bits_cBusy),
    .io_in_0_tx_dat_bits_dbID(io_in_0_tx_dat_bits_dbID),
    .io_in_0_tx_dat_bits_ccID(io_in_0_tx_dat_bits_ccID),
    .io_in_0_tx_dat_bits_dataID(io_in_0_tx_dat_bits_dataID),
    .io_in_0_tx_dat_bits_tagOp(io_in_0_tx_dat_bits_tagOp),
    .io_in_0_tx_dat_bits_tag(io_in_0_tx_dat_bits_tag),
    .io_in_0_tx_dat_bits_tu(io_in_0_tx_dat_bits_tu),
    .io_in_0_tx_dat_bits_traceTag(io_in_0_tx_dat_bits_traceTag),
    .io_in_0_tx_dat_bits_rsvdc(io_in_0_tx_dat_bits_rsvdc),
    .io_in_0_tx_dat_bits_be(io_in_0_tx_dat_bits_be),
    .io_in_0_tx_dat_bits_data(io_in_0_tx_dat_bits_data),
    .io_in_0_tx_dat_bits_dataCheck(io_in_0_tx_dat_bits_dataCheck),
    .io_in_0_tx_dat_bits_poison(io_in_0_tx_dat_bits_poison),
    .io_in_0_rx_rsp_ready(io_in_0_rx_rsp_ready),
    .io_in_0_rx_rsp_valid(g_io_in_0_rx_rsp_valid),
    .io_in_0_rx_rsp_bits_qos(g_io_in_0_rx_rsp_bits_qos),
    .io_in_0_rx_rsp_bits_txnID(g_io_in_0_rx_rsp_bits_txnID),
    .io_in_0_rx_rsp_bits_opcode(g_io_in_0_rx_rsp_bits_opcode),
    .io_in_0_rx_rsp_bits_respErr(g_io_in_0_rx_rsp_bits_respErr),
    .io_in_0_rx_rsp_bits_resp(g_io_in_0_rx_rsp_bits_resp),
    .io_in_0_rx_rsp_bits_fwdState(g_io_in_0_rx_rsp_bits_fwdState),
    .io_in_0_rx_rsp_bits_cBusy(g_io_in_0_rx_rsp_bits_cBusy),
    .io_in_0_rx_rsp_bits_dbID(g_io_in_0_rx_rsp_bits_dbID),
    .io_in_0_rx_rsp_bits_pCrdType(g_io_in_0_rx_rsp_bits_pCrdType),
    .io_in_0_rx_rsp_bits_tagOp(g_io_in_0_rx_rsp_bits_tagOp),
    .io_in_0_rx_rsp_bits_traceTag(g_io_in_0_rx_rsp_bits_traceTag),
    .io_in_0_rx_dat_ready(io_in_0_rx_dat_ready),
    .io_in_0_rx_dat_valid(g_io_in_0_rx_dat_valid),
    .io_in_0_rx_dat_bits_txnID(g_io_in_0_rx_dat_bits_txnID),
    .io_in_0_rx_dat_bits_homeNID(g_io_in_0_rx_dat_bits_homeNID),
    .io_in_0_rx_dat_bits_opcode(g_io_in_0_rx_dat_bits_opcode),
    .io_in_0_rx_dat_bits_resp(g_io_in_0_rx_dat_bits_resp),
    .io_in_0_rx_dat_bits_dataSource(g_io_in_0_rx_dat_bits_dataSource),
    .io_in_0_rx_dat_bits_dbID(g_io_in_0_rx_dat_bits_dbID),
    .io_in_0_rx_dat_bits_dataID(g_io_in_0_rx_dat_bits_dataID),
    .io_in_0_rx_dat_bits_be(g_io_in_0_rx_dat_bits_be),
    .io_in_0_rx_dat_bits_data(g_io_in_0_rx_dat_bits_data),
    .io_in_0_rx_dat_bits_dataCheck(g_io_in_0_rx_dat_bits_dataCheck),
    .io_in_0_rx_snp_ready(io_in_0_rx_snp_ready),
    .io_in_0_rx_snp_valid(g_io_in_0_rx_snp_valid),
    .io_in_0_rx_snp_bits_txnID(g_io_in_0_rx_snp_bits_txnID),
    .io_in_0_rx_snp_bits_fwdNID(g_io_in_0_rx_snp_bits_fwdNID),
    .io_in_0_rx_snp_bits_fwdTxnID(g_io_in_0_rx_snp_bits_fwdTxnID),
    .io_in_0_rx_snp_bits_opcode(g_io_in_0_rx_snp_bits_opcode),
    .io_in_0_rx_snp_bits_addr(g_io_in_0_rx_snp_bits_addr),
    .io_in_0_rx_snp_bits_doNotGoToSD(g_io_in_0_rx_snp_bits_doNotGoToSD),
    .io_in_0_rx_snp_bits_retToSrc(g_io_in_0_rx_snp_bits_retToSrc),
    .io_out_0_tx_req_ready(io_out_0_tx_req_ready),
    .io_out_0_tx_req_valid(g_io_out_0_tx_req_valid),
    .io_out_0_tx_req_bits_tgtID(g_io_out_0_tx_req_bits_tgtID),
    .io_out_0_tx_req_bits_srcID(g_io_out_0_tx_req_bits_srcID),
    .io_out_0_tx_req_bits_txnID(g_io_out_0_tx_req_bits_txnID),
    .io_out_0_tx_req_bits_opcode(g_io_out_0_tx_req_bits_opcode),
    .io_out_0_tx_req_bits_size(g_io_out_0_tx_req_bits_size),
    .io_out_0_tx_req_bits_addr(g_io_out_0_tx_req_bits_addr),
    .io_out_0_tx_req_bits_allowRetry(g_io_out_0_tx_req_bits_allowRetry),
    .io_out_0_tx_req_bits_order(g_io_out_0_tx_req_bits_order),
    .io_out_0_tx_req_bits_pCrdType(g_io_out_0_tx_req_bits_pCrdType),
    .io_out_0_tx_req_bits_memAttr_allocate(g_io_out_0_tx_req_bits_memAttr_allocate),
    .io_out_0_tx_req_bits_memAttr_cacheable(g_io_out_0_tx_req_bits_memAttr_cacheable),
    .io_out_0_tx_req_bits_memAttr_device(g_io_out_0_tx_req_bits_memAttr_device),
    .io_out_0_tx_req_bits_memAttr_ewa(g_io_out_0_tx_req_bits_memAttr_ewa),
    .io_out_0_tx_req_bits_snpAttr(g_io_out_0_tx_req_bits_snpAttr),
    .io_out_0_tx_req_bits_expCompAck(g_io_out_0_tx_req_bits_expCompAck),
    .io_out_0_tx_rsp_valid(g_io_out_0_tx_rsp_valid),
    .io_out_0_tx_rsp_bits_srcID(g_io_out_0_tx_rsp_bits_srcID),
    .io_out_0_tx_rsp_bits_txnID(g_io_out_0_tx_rsp_bits_txnID),
    .io_out_0_tx_rsp_bits_opcode(g_io_out_0_tx_rsp_bits_opcode),
    .io_out_0_tx_rsp_bits_dbID(g_io_out_0_tx_rsp_bits_dbID),
    .io_out_0_tx_dat_valid(g_io_out_0_tx_dat_valid),
    .io_out_0_tx_dat_bits_srcID(g_io_out_0_tx_dat_bits_srcID),
    .io_out_0_tx_dat_bits_txnID(g_io_out_0_tx_dat_bits_txnID),
    .io_out_0_tx_dat_bits_opcode(g_io_out_0_tx_dat_bits_opcode),
    .io_out_0_tx_dat_bits_resp(g_io_out_0_tx_dat_bits_resp),
    .io_out_0_tx_dat_bits_dataID(g_io_out_0_tx_dat_bits_dataID),
    .io_out_0_tx_dat_bits_data(g_io_out_0_tx_dat_bits_data),
    .io_out_0_rx_rsp_ready(g_io_out_0_rx_rsp_ready),
    .io_out_0_rx_rsp_valid(io_out_0_rx_rsp_valid),
    .io_out_0_rx_rsp_bits_tgtID(io_out_0_rx_rsp_bits_tgtID),
    .io_out_0_rx_rsp_bits_srcID(io_out_0_rx_rsp_bits_srcID),
    .io_out_0_rx_rsp_bits_txnID(io_out_0_rx_rsp_bits_txnID),
    .io_out_0_rx_rsp_bits_opcode(io_out_0_rx_rsp_bits_opcode),
    .io_out_0_rx_rsp_bits_resp(io_out_0_rx_rsp_bits_resp),
    .io_out_0_rx_rsp_bits_fwdState(io_out_0_rx_rsp_bits_fwdState),
    .io_out_0_rx_rsp_bits_dbID(io_out_0_rx_rsp_bits_dbID),
    .io_out_0_rx_rsp_bits_pCrdType(io_out_0_rx_rsp_bits_pCrdType),
    .io_out_0_rx_dat_ready(g_io_out_0_rx_dat_ready),
    .io_out_0_rx_dat_valid(io_out_0_rx_dat_valid),
    .io_out_0_rx_dat_bits_tgtID(io_out_0_rx_dat_bits_tgtID),
    .io_out_0_rx_dat_bits_srcID(io_out_0_rx_dat_bits_srcID),
    .io_out_0_rx_dat_bits_txnID(io_out_0_rx_dat_bits_txnID),
    .io_out_0_rx_dat_bits_homeNID(io_out_0_rx_dat_bits_homeNID),
    .io_out_0_rx_dat_bits_opcode(io_out_0_rx_dat_bits_opcode),
    .io_out_0_rx_dat_bits_resp(io_out_0_rx_dat_bits_resp),
    .io_out_0_rx_dat_bits_dataSource(io_out_0_rx_dat_bits_dataSource),
    .io_out_0_rx_dat_bits_dbID(io_out_0_rx_dat_bits_dbID),
    .io_out_0_rx_dat_bits_dataID(io_out_0_rx_dat_bits_dataID),
    .io_out_0_rx_dat_bits_be(io_out_0_rx_dat_bits_be),
    .io_out_0_rx_dat_bits_data(io_out_0_rx_dat_bits_data),
    .io_out_0_rx_dat_bits_dataCheck(io_out_0_rx_dat_bits_dataCheck),
    .io_out_0_rx_snp_ready(g_io_out_0_rx_snp_ready),
    .io_out_0_rx_snp_valid(io_out_0_rx_snp_valid),
    .io_out_0_rx_snp_bits_txnID(io_out_0_rx_snp_bits_txnID),
    .io_out_0_rx_snp_bits_fwdNID(io_out_0_rx_snp_bits_fwdNID),
    .io_out_0_rx_snp_bits_fwdTxnID(io_out_0_rx_snp_bits_fwdTxnID),
    .io_out_0_rx_snp_bits_opcode(io_out_0_rx_snp_bits_opcode),
    .io_out_0_rx_snp_bits_addr(io_out_0_rx_snp_bits_addr),
    .io_out_0_rx_snp_bits_doNotGoToSD(io_out_0_rx_snp_bits_doNotGoToSD),
    .io_out_0_rx_snp_bits_retToSrc(io_out_0_rx_snp_bits_retToSrc),
    .io_out_1_tx_req_ready(io_out_1_tx_req_ready),
    .io_out_1_tx_req_valid(g_io_out_1_tx_req_valid),
    .io_out_1_tx_req_bits_tgtID(g_io_out_1_tx_req_bits_tgtID),
    .io_out_1_tx_req_bits_srcID(g_io_out_1_tx_req_bits_srcID),
    .io_out_1_tx_req_bits_txnID(g_io_out_1_tx_req_bits_txnID),
    .io_out_1_tx_req_bits_opcode(g_io_out_1_tx_req_bits_opcode),
    .io_out_1_tx_req_bits_size(g_io_out_1_tx_req_bits_size),
    .io_out_1_tx_req_bits_addr(g_io_out_1_tx_req_bits_addr),
    .io_out_1_tx_req_bits_allowRetry(g_io_out_1_tx_req_bits_allowRetry),
    .io_out_1_tx_req_bits_order(g_io_out_1_tx_req_bits_order),
    .io_out_1_tx_req_bits_pCrdType(g_io_out_1_tx_req_bits_pCrdType),
    .io_out_1_tx_req_bits_memAttr_allocate(g_io_out_1_tx_req_bits_memAttr_allocate),
    .io_out_1_tx_req_bits_memAttr_cacheable(g_io_out_1_tx_req_bits_memAttr_cacheable),
    .io_out_1_tx_req_bits_memAttr_device(g_io_out_1_tx_req_bits_memAttr_device),
    .io_out_1_tx_req_bits_memAttr_ewa(g_io_out_1_tx_req_bits_memAttr_ewa),
    .io_out_1_tx_req_bits_snpAttr(g_io_out_1_tx_req_bits_snpAttr),
    .io_out_1_tx_req_bits_expCompAck(g_io_out_1_tx_req_bits_expCompAck),
    .io_out_1_tx_rsp_valid(g_io_out_1_tx_rsp_valid),
    .io_out_1_tx_rsp_bits_srcID(g_io_out_1_tx_rsp_bits_srcID),
    .io_out_1_tx_rsp_bits_txnID(g_io_out_1_tx_rsp_bits_txnID),
    .io_out_1_tx_rsp_bits_opcode(g_io_out_1_tx_rsp_bits_opcode),
    .io_out_1_tx_rsp_bits_dbID(g_io_out_1_tx_rsp_bits_dbID),
    .io_out_1_tx_dat_valid(g_io_out_1_tx_dat_valid),
    .io_out_1_tx_dat_bits_srcID(g_io_out_1_tx_dat_bits_srcID),
    .io_out_1_tx_dat_bits_txnID(g_io_out_1_tx_dat_bits_txnID),
    .io_out_1_tx_dat_bits_opcode(g_io_out_1_tx_dat_bits_opcode),
    .io_out_1_tx_dat_bits_resp(g_io_out_1_tx_dat_bits_resp),
    .io_out_1_tx_dat_bits_dataID(g_io_out_1_tx_dat_bits_dataID),
    .io_out_1_tx_dat_bits_data(g_io_out_1_tx_dat_bits_data),
    .io_out_1_rx_rsp_ready(g_io_out_1_rx_rsp_ready),
    .io_out_1_rx_rsp_valid(io_out_1_rx_rsp_valid),
    .io_out_1_rx_rsp_bits_tgtID(io_out_1_rx_rsp_bits_tgtID),
    .io_out_1_rx_rsp_bits_srcID(io_out_1_rx_rsp_bits_srcID),
    .io_out_1_rx_rsp_bits_txnID(io_out_1_rx_rsp_bits_txnID),
    .io_out_1_rx_rsp_bits_opcode(io_out_1_rx_rsp_bits_opcode),
    .io_out_1_rx_rsp_bits_resp(io_out_1_rx_rsp_bits_resp),
    .io_out_1_rx_rsp_bits_fwdState(io_out_1_rx_rsp_bits_fwdState),
    .io_out_1_rx_rsp_bits_dbID(io_out_1_rx_rsp_bits_dbID),
    .io_out_1_rx_rsp_bits_pCrdType(io_out_1_rx_rsp_bits_pCrdType),
    .io_out_1_rx_dat_ready(g_io_out_1_rx_dat_ready),
    .io_out_1_rx_dat_valid(io_out_1_rx_dat_valid),
    .io_out_1_rx_dat_bits_tgtID(io_out_1_rx_dat_bits_tgtID),
    .io_out_1_rx_dat_bits_srcID(io_out_1_rx_dat_bits_srcID),
    .io_out_1_rx_dat_bits_txnID(io_out_1_rx_dat_bits_txnID),
    .io_out_1_rx_dat_bits_homeNID(io_out_1_rx_dat_bits_homeNID),
    .io_out_1_rx_dat_bits_opcode(io_out_1_rx_dat_bits_opcode),
    .io_out_1_rx_dat_bits_resp(io_out_1_rx_dat_bits_resp),
    .io_out_1_rx_dat_bits_dataSource(io_out_1_rx_dat_bits_dataSource),
    .io_out_1_rx_dat_bits_dbID(io_out_1_rx_dat_bits_dbID),
    .io_out_1_rx_dat_bits_dataID(io_out_1_rx_dat_bits_dataID),
    .io_out_1_rx_dat_bits_be(io_out_1_rx_dat_bits_be),
    .io_out_1_rx_dat_bits_data(io_out_1_rx_dat_bits_data),
    .io_out_1_rx_dat_bits_dataCheck(io_out_1_rx_dat_bits_dataCheck),
    .io_out_1_rx_snp_ready(g_io_out_1_rx_snp_ready),
    .io_out_1_rx_snp_valid(io_out_1_rx_snp_valid),
    .io_out_1_rx_snp_bits_txnID(io_out_1_rx_snp_bits_txnID),
    .io_out_1_rx_snp_bits_fwdNID(io_out_1_rx_snp_bits_fwdNID),
    .io_out_1_rx_snp_bits_fwdTxnID(io_out_1_rx_snp_bits_fwdTxnID),
    .io_out_1_rx_snp_bits_opcode(io_out_1_rx_snp_bits_opcode),
    .io_out_1_rx_snp_bits_addr(io_out_1_rx_snp_bits_addr),
    .io_out_1_rx_snp_bits_doNotGoToSD(io_out_1_rx_snp_bits_doNotGoToSD),
    .io_out_1_rx_snp_bits_retToSrc(io_out_1_rx_snp_bits_retToSrc),
    .io_out_2_tx_req_ready(io_out_2_tx_req_ready),
    .io_out_2_tx_req_valid(g_io_out_2_tx_req_valid),
    .io_out_2_tx_req_bits_tgtID(g_io_out_2_tx_req_bits_tgtID),
    .io_out_2_tx_req_bits_srcID(g_io_out_2_tx_req_bits_srcID),
    .io_out_2_tx_req_bits_txnID(g_io_out_2_tx_req_bits_txnID),
    .io_out_2_tx_req_bits_opcode(g_io_out_2_tx_req_bits_opcode),
    .io_out_2_tx_req_bits_size(g_io_out_2_tx_req_bits_size),
    .io_out_2_tx_req_bits_addr(g_io_out_2_tx_req_bits_addr),
    .io_out_2_tx_req_bits_allowRetry(g_io_out_2_tx_req_bits_allowRetry),
    .io_out_2_tx_req_bits_order(g_io_out_2_tx_req_bits_order),
    .io_out_2_tx_req_bits_pCrdType(g_io_out_2_tx_req_bits_pCrdType),
    .io_out_2_tx_req_bits_memAttr_allocate(g_io_out_2_tx_req_bits_memAttr_allocate),
    .io_out_2_tx_req_bits_memAttr_cacheable(g_io_out_2_tx_req_bits_memAttr_cacheable),
    .io_out_2_tx_req_bits_memAttr_device(g_io_out_2_tx_req_bits_memAttr_device),
    .io_out_2_tx_req_bits_memAttr_ewa(g_io_out_2_tx_req_bits_memAttr_ewa),
    .io_out_2_tx_req_bits_snpAttr(g_io_out_2_tx_req_bits_snpAttr),
    .io_out_2_tx_req_bits_expCompAck(g_io_out_2_tx_req_bits_expCompAck),
    .io_out_2_tx_rsp_valid(g_io_out_2_tx_rsp_valid),
    .io_out_2_tx_rsp_bits_srcID(g_io_out_2_tx_rsp_bits_srcID),
    .io_out_2_tx_rsp_bits_txnID(g_io_out_2_tx_rsp_bits_txnID),
    .io_out_2_tx_rsp_bits_opcode(g_io_out_2_tx_rsp_bits_opcode),
    .io_out_2_tx_rsp_bits_dbID(g_io_out_2_tx_rsp_bits_dbID),
    .io_out_2_tx_dat_valid(g_io_out_2_tx_dat_valid),
    .io_out_2_tx_dat_bits_srcID(g_io_out_2_tx_dat_bits_srcID),
    .io_out_2_tx_dat_bits_txnID(g_io_out_2_tx_dat_bits_txnID),
    .io_out_2_tx_dat_bits_opcode(g_io_out_2_tx_dat_bits_opcode),
    .io_out_2_tx_dat_bits_resp(g_io_out_2_tx_dat_bits_resp),
    .io_out_2_tx_dat_bits_dataID(g_io_out_2_tx_dat_bits_dataID),
    .io_out_2_tx_dat_bits_data(g_io_out_2_tx_dat_bits_data),
    .io_out_2_rx_rsp_ready(g_io_out_2_rx_rsp_ready),
    .io_out_2_rx_rsp_valid(io_out_2_rx_rsp_valid),
    .io_out_2_rx_rsp_bits_tgtID(io_out_2_rx_rsp_bits_tgtID),
    .io_out_2_rx_rsp_bits_srcID(io_out_2_rx_rsp_bits_srcID),
    .io_out_2_rx_rsp_bits_txnID(io_out_2_rx_rsp_bits_txnID),
    .io_out_2_rx_rsp_bits_opcode(io_out_2_rx_rsp_bits_opcode),
    .io_out_2_rx_rsp_bits_resp(io_out_2_rx_rsp_bits_resp),
    .io_out_2_rx_rsp_bits_fwdState(io_out_2_rx_rsp_bits_fwdState),
    .io_out_2_rx_rsp_bits_dbID(io_out_2_rx_rsp_bits_dbID),
    .io_out_2_rx_rsp_bits_pCrdType(io_out_2_rx_rsp_bits_pCrdType),
    .io_out_2_rx_dat_ready(g_io_out_2_rx_dat_ready),
    .io_out_2_rx_dat_valid(io_out_2_rx_dat_valid),
    .io_out_2_rx_dat_bits_tgtID(io_out_2_rx_dat_bits_tgtID),
    .io_out_2_rx_dat_bits_srcID(io_out_2_rx_dat_bits_srcID),
    .io_out_2_rx_dat_bits_txnID(io_out_2_rx_dat_bits_txnID),
    .io_out_2_rx_dat_bits_homeNID(io_out_2_rx_dat_bits_homeNID),
    .io_out_2_rx_dat_bits_opcode(io_out_2_rx_dat_bits_opcode),
    .io_out_2_rx_dat_bits_resp(io_out_2_rx_dat_bits_resp),
    .io_out_2_rx_dat_bits_dataSource(io_out_2_rx_dat_bits_dataSource),
    .io_out_2_rx_dat_bits_dbID(io_out_2_rx_dat_bits_dbID),
    .io_out_2_rx_dat_bits_dataID(io_out_2_rx_dat_bits_dataID),
    .io_out_2_rx_dat_bits_be(io_out_2_rx_dat_bits_be),
    .io_out_2_rx_dat_bits_data(io_out_2_rx_dat_bits_data),
    .io_out_2_rx_dat_bits_dataCheck(io_out_2_rx_dat_bits_dataCheck),
    .io_out_2_rx_snp_ready(g_io_out_2_rx_snp_ready),
    .io_out_2_rx_snp_valid(io_out_2_rx_snp_valid),
    .io_out_2_rx_snp_bits_txnID(io_out_2_rx_snp_bits_txnID),
    .io_out_2_rx_snp_bits_fwdNID(io_out_2_rx_snp_bits_fwdNID),
    .io_out_2_rx_snp_bits_fwdTxnID(io_out_2_rx_snp_bits_fwdTxnID),
    .io_out_2_rx_snp_bits_opcode(io_out_2_rx_snp_bits_opcode),
    .io_out_2_rx_snp_bits_addr(io_out_2_rx_snp_bits_addr),
    .io_out_2_rx_snp_bits_doNotGoToSD(io_out_2_rx_snp_bits_doNotGoToSD),
    .io_out_2_rx_snp_bits_retToSrc(io_out_2_rx_snp_bits_retToSrc),
    .io_out_3_tx_req_ready(io_out_3_tx_req_ready),
    .io_out_3_tx_req_valid(g_io_out_3_tx_req_valid),
    .io_out_3_tx_req_bits_tgtID(g_io_out_3_tx_req_bits_tgtID),
    .io_out_3_tx_req_bits_srcID(g_io_out_3_tx_req_bits_srcID),
    .io_out_3_tx_req_bits_txnID(g_io_out_3_tx_req_bits_txnID),
    .io_out_3_tx_req_bits_opcode(g_io_out_3_tx_req_bits_opcode),
    .io_out_3_tx_req_bits_size(g_io_out_3_tx_req_bits_size),
    .io_out_3_tx_req_bits_addr(g_io_out_3_tx_req_bits_addr),
    .io_out_3_tx_req_bits_allowRetry(g_io_out_3_tx_req_bits_allowRetry),
    .io_out_3_tx_req_bits_order(g_io_out_3_tx_req_bits_order),
    .io_out_3_tx_req_bits_pCrdType(g_io_out_3_tx_req_bits_pCrdType),
    .io_out_3_tx_req_bits_memAttr_allocate(g_io_out_3_tx_req_bits_memAttr_allocate),
    .io_out_3_tx_req_bits_memAttr_cacheable(g_io_out_3_tx_req_bits_memAttr_cacheable),
    .io_out_3_tx_req_bits_memAttr_device(g_io_out_3_tx_req_bits_memAttr_device),
    .io_out_3_tx_req_bits_memAttr_ewa(g_io_out_3_tx_req_bits_memAttr_ewa),
    .io_out_3_tx_req_bits_snpAttr(g_io_out_3_tx_req_bits_snpAttr),
    .io_out_3_tx_req_bits_expCompAck(g_io_out_3_tx_req_bits_expCompAck),
    .io_out_3_tx_rsp_valid(g_io_out_3_tx_rsp_valid),
    .io_out_3_tx_rsp_bits_srcID(g_io_out_3_tx_rsp_bits_srcID),
    .io_out_3_tx_rsp_bits_txnID(g_io_out_3_tx_rsp_bits_txnID),
    .io_out_3_tx_rsp_bits_opcode(g_io_out_3_tx_rsp_bits_opcode),
    .io_out_3_tx_rsp_bits_dbID(g_io_out_3_tx_rsp_bits_dbID),
    .io_out_3_tx_dat_valid(g_io_out_3_tx_dat_valid),
    .io_out_3_tx_dat_bits_srcID(g_io_out_3_tx_dat_bits_srcID),
    .io_out_3_tx_dat_bits_txnID(g_io_out_3_tx_dat_bits_txnID),
    .io_out_3_tx_dat_bits_opcode(g_io_out_3_tx_dat_bits_opcode),
    .io_out_3_tx_dat_bits_resp(g_io_out_3_tx_dat_bits_resp),
    .io_out_3_tx_dat_bits_dataID(g_io_out_3_tx_dat_bits_dataID),
    .io_out_3_tx_dat_bits_data(g_io_out_3_tx_dat_bits_data),
    .io_out_3_rx_rsp_ready(g_io_out_3_rx_rsp_ready),
    .io_out_3_rx_rsp_valid(io_out_3_rx_rsp_valid),
    .io_out_3_rx_rsp_bits_tgtID(io_out_3_rx_rsp_bits_tgtID),
    .io_out_3_rx_rsp_bits_srcID(io_out_3_rx_rsp_bits_srcID),
    .io_out_3_rx_rsp_bits_txnID(io_out_3_rx_rsp_bits_txnID),
    .io_out_3_rx_rsp_bits_opcode(io_out_3_rx_rsp_bits_opcode),
    .io_out_3_rx_rsp_bits_resp(io_out_3_rx_rsp_bits_resp),
    .io_out_3_rx_rsp_bits_fwdState(io_out_3_rx_rsp_bits_fwdState),
    .io_out_3_rx_rsp_bits_dbID(io_out_3_rx_rsp_bits_dbID),
    .io_out_3_rx_rsp_bits_pCrdType(io_out_3_rx_rsp_bits_pCrdType),
    .io_out_3_rx_dat_ready(g_io_out_3_rx_dat_ready),
    .io_out_3_rx_dat_valid(io_out_3_rx_dat_valid),
    .io_out_3_rx_dat_bits_tgtID(io_out_3_rx_dat_bits_tgtID),
    .io_out_3_rx_dat_bits_srcID(io_out_3_rx_dat_bits_srcID),
    .io_out_3_rx_dat_bits_txnID(io_out_3_rx_dat_bits_txnID),
    .io_out_3_rx_dat_bits_homeNID(io_out_3_rx_dat_bits_homeNID),
    .io_out_3_rx_dat_bits_opcode(io_out_3_rx_dat_bits_opcode),
    .io_out_3_rx_dat_bits_resp(io_out_3_rx_dat_bits_resp),
    .io_out_3_rx_dat_bits_dataSource(io_out_3_rx_dat_bits_dataSource),
    .io_out_3_rx_dat_bits_dbID(io_out_3_rx_dat_bits_dbID),
    .io_out_3_rx_dat_bits_dataID(io_out_3_rx_dat_bits_dataID),
    .io_out_3_rx_dat_bits_be(io_out_3_rx_dat_bits_be),
    .io_out_3_rx_dat_bits_data(io_out_3_rx_dat_bits_data),
    .io_out_3_rx_dat_bits_dataCheck(io_out_3_rx_dat_bits_dataCheck),
    .io_out_3_rx_snp_ready(g_io_out_3_rx_snp_ready),
    .io_out_3_rx_snp_valid(io_out_3_rx_snp_valid),
    .io_out_3_rx_snp_bits_txnID(io_out_3_rx_snp_bits_txnID),
    .io_out_3_rx_snp_bits_fwdNID(io_out_3_rx_snp_bits_fwdNID),
    .io_out_3_rx_snp_bits_fwdTxnID(io_out_3_rx_snp_bits_fwdTxnID),
    .io_out_3_rx_snp_bits_opcode(io_out_3_rx_snp_bits_opcode),
    .io_out_3_rx_snp_bits_addr(io_out_3_rx_snp_bits_addr),
    .io_out_3_rx_snp_bits_doNotGoToSD(io_out_3_rx_snp_bits_doNotGoToSD),
    .io_out_3_rx_snp_bits_retToSrc(io_out_3_rx_snp_bits_retToSrc),
    .io_snpMasks_0_0(io_snpMasks_0_0),
    .io_snpMasks_1_0(io_snpMasks_1_0),
    .io_snpMasks_2_0(io_snpMasks_2_0),
    .io_snpMasks_3_0(io_snpMasks_3_0)
  );

  RNXbar_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_0_tx_req_ready(i_io_in_0_tx_req_ready),
    .io_in_0_tx_req_valid(io_in_0_tx_req_valid),
    .io_in_0_tx_req_bits_qos(io_in_0_tx_req_bits_qos),
    .io_in_0_tx_req_bits_tgtID(io_in_0_tx_req_bits_tgtID),
    .io_in_0_tx_req_bits_srcID(io_in_0_tx_req_bits_srcID),
    .io_in_0_tx_req_bits_txnID(io_in_0_tx_req_bits_txnID),
    .io_in_0_tx_req_bits_returnNID(io_in_0_tx_req_bits_returnNID),
    .io_in_0_tx_req_bits_stashNIDValid(io_in_0_tx_req_bits_stashNIDValid),
    .io_in_0_tx_req_bits_returnTxnID(io_in_0_tx_req_bits_returnTxnID),
    .io_in_0_tx_req_bits_opcode(io_in_0_tx_req_bits_opcode),
    .io_in_0_tx_req_bits_size(io_in_0_tx_req_bits_size),
    .io_in_0_tx_req_bits_addr(io_in_0_tx_req_bits_addr),
    .io_in_0_tx_req_bits_ns(io_in_0_tx_req_bits_ns),
    .io_in_0_tx_req_bits_likelyshared(io_in_0_tx_req_bits_likelyshared),
    .io_in_0_tx_req_bits_allowRetry(io_in_0_tx_req_bits_allowRetry),
    .io_in_0_tx_req_bits_order(io_in_0_tx_req_bits_order),
    .io_in_0_tx_req_bits_pCrdType(io_in_0_tx_req_bits_pCrdType),
    .io_in_0_tx_req_bits_memAttr_allocate(io_in_0_tx_req_bits_memAttr_allocate),
    .io_in_0_tx_req_bits_memAttr_cacheable(io_in_0_tx_req_bits_memAttr_cacheable),
    .io_in_0_tx_req_bits_memAttr_device(io_in_0_tx_req_bits_memAttr_device),
    .io_in_0_tx_req_bits_memAttr_ewa(io_in_0_tx_req_bits_memAttr_ewa),
    .io_in_0_tx_req_bits_snpAttr(io_in_0_tx_req_bits_snpAttr),
    .io_in_0_tx_req_bits_lpIDWithPadding(io_in_0_tx_req_bits_lpIDWithPadding),
    .io_in_0_tx_req_bits_snoopMe(io_in_0_tx_req_bits_snoopMe),
    .io_in_0_tx_req_bits_expCompAck(io_in_0_tx_req_bits_expCompAck),
    .io_in_0_tx_req_bits_tagOp(io_in_0_tx_req_bits_tagOp),
    .io_in_0_tx_req_bits_traceTag(io_in_0_tx_req_bits_traceTag),
    .io_in_0_tx_req_bits_mpam_perfMonGroup(io_in_0_tx_req_bits_mpam_perfMonGroup),
    .io_in_0_tx_req_bits_mpam_partID(io_in_0_tx_req_bits_mpam_partID),
    .io_in_0_tx_req_bits_mpam_mpamNS(io_in_0_tx_req_bits_mpam_mpamNS),
    .io_in_0_tx_req_bits_rsvdc(io_in_0_tx_req_bits_rsvdc),
    .io_in_0_tx_rsp_ready(i_io_in_0_tx_rsp_ready),
    .io_in_0_tx_rsp_valid(io_in_0_tx_rsp_valid),
    .io_in_0_tx_rsp_bits_srcID(io_in_0_tx_rsp_bits_srcID),
    .io_in_0_tx_rsp_bits_txnID(io_in_0_tx_rsp_bits_txnID),
    .io_in_0_tx_rsp_bits_opcode(io_in_0_tx_rsp_bits_opcode),
    .io_in_0_tx_rsp_bits_dbID(io_in_0_tx_rsp_bits_dbID),
    .io_in_0_tx_dat_ready(i_io_in_0_tx_dat_ready),
    .io_in_0_tx_dat_valid(io_in_0_tx_dat_valid),
    .io_in_0_tx_dat_bits_qos(io_in_0_tx_dat_bits_qos),
    .io_in_0_tx_dat_bits_tgtID(io_in_0_tx_dat_bits_tgtID),
    .io_in_0_tx_dat_bits_srcID(io_in_0_tx_dat_bits_srcID),
    .io_in_0_tx_dat_bits_txnID(io_in_0_tx_dat_bits_txnID),
    .io_in_0_tx_dat_bits_homeNID(io_in_0_tx_dat_bits_homeNID),
    .io_in_0_tx_dat_bits_opcode(io_in_0_tx_dat_bits_opcode),
    .io_in_0_tx_dat_bits_respErr(io_in_0_tx_dat_bits_respErr),
    .io_in_0_tx_dat_bits_resp(io_in_0_tx_dat_bits_resp),
    .io_in_0_tx_dat_bits_dataSource(io_in_0_tx_dat_bits_dataSource),
    .io_in_0_tx_dat_bits_cBusy(io_in_0_tx_dat_bits_cBusy),
    .io_in_0_tx_dat_bits_dbID(io_in_0_tx_dat_bits_dbID),
    .io_in_0_tx_dat_bits_ccID(io_in_0_tx_dat_bits_ccID),
    .io_in_0_tx_dat_bits_dataID(io_in_0_tx_dat_bits_dataID),
    .io_in_0_tx_dat_bits_tagOp(io_in_0_tx_dat_bits_tagOp),
    .io_in_0_tx_dat_bits_tag(io_in_0_tx_dat_bits_tag),
    .io_in_0_tx_dat_bits_tu(io_in_0_tx_dat_bits_tu),
    .io_in_0_tx_dat_bits_traceTag(io_in_0_tx_dat_bits_traceTag),
    .io_in_0_tx_dat_bits_rsvdc(io_in_0_tx_dat_bits_rsvdc),
    .io_in_0_tx_dat_bits_be(io_in_0_tx_dat_bits_be),
    .io_in_0_tx_dat_bits_data(io_in_0_tx_dat_bits_data),
    .io_in_0_tx_dat_bits_dataCheck(io_in_0_tx_dat_bits_dataCheck),
    .io_in_0_tx_dat_bits_poison(io_in_0_tx_dat_bits_poison),
    .io_in_0_rx_rsp_ready(io_in_0_rx_rsp_ready),
    .io_in_0_rx_rsp_valid(i_io_in_0_rx_rsp_valid),
    .io_in_0_rx_rsp_bits_qos(i_io_in_0_rx_rsp_bits_qos),
    .io_in_0_rx_rsp_bits_txnID(i_io_in_0_rx_rsp_bits_txnID),
    .io_in_0_rx_rsp_bits_opcode(i_io_in_0_rx_rsp_bits_opcode),
    .io_in_0_rx_rsp_bits_respErr(i_io_in_0_rx_rsp_bits_respErr),
    .io_in_0_rx_rsp_bits_resp(i_io_in_0_rx_rsp_bits_resp),
    .io_in_0_rx_rsp_bits_fwdState(i_io_in_0_rx_rsp_bits_fwdState),
    .io_in_0_rx_rsp_bits_cBusy(i_io_in_0_rx_rsp_bits_cBusy),
    .io_in_0_rx_rsp_bits_dbID(i_io_in_0_rx_rsp_bits_dbID),
    .io_in_0_rx_rsp_bits_pCrdType(i_io_in_0_rx_rsp_bits_pCrdType),
    .io_in_0_rx_rsp_bits_tagOp(i_io_in_0_rx_rsp_bits_tagOp),
    .io_in_0_rx_rsp_bits_traceTag(i_io_in_0_rx_rsp_bits_traceTag),
    .io_in_0_rx_dat_ready(io_in_0_rx_dat_ready),
    .io_in_0_rx_dat_valid(i_io_in_0_rx_dat_valid),
    .io_in_0_rx_dat_bits_txnID(i_io_in_0_rx_dat_bits_txnID),
    .io_in_0_rx_dat_bits_homeNID(i_io_in_0_rx_dat_bits_homeNID),
    .io_in_0_rx_dat_bits_opcode(i_io_in_0_rx_dat_bits_opcode),
    .io_in_0_rx_dat_bits_resp(i_io_in_0_rx_dat_bits_resp),
    .io_in_0_rx_dat_bits_dataSource(i_io_in_0_rx_dat_bits_dataSource),
    .io_in_0_rx_dat_bits_dbID(i_io_in_0_rx_dat_bits_dbID),
    .io_in_0_rx_dat_bits_dataID(i_io_in_0_rx_dat_bits_dataID),
    .io_in_0_rx_dat_bits_be(i_io_in_0_rx_dat_bits_be),
    .io_in_0_rx_dat_bits_data(i_io_in_0_rx_dat_bits_data),
    .io_in_0_rx_dat_bits_dataCheck(i_io_in_0_rx_dat_bits_dataCheck),
    .io_in_0_rx_snp_ready(io_in_0_rx_snp_ready),
    .io_in_0_rx_snp_valid(i_io_in_0_rx_snp_valid),
    .io_in_0_rx_snp_bits_txnID(i_io_in_0_rx_snp_bits_txnID),
    .io_in_0_rx_snp_bits_fwdNID(i_io_in_0_rx_snp_bits_fwdNID),
    .io_in_0_rx_snp_bits_fwdTxnID(i_io_in_0_rx_snp_bits_fwdTxnID),
    .io_in_0_rx_snp_bits_opcode(i_io_in_0_rx_snp_bits_opcode),
    .io_in_0_rx_snp_bits_addr(i_io_in_0_rx_snp_bits_addr),
    .io_in_0_rx_snp_bits_doNotGoToSD(i_io_in_0_rx_snp_bits_doNotGoToSD),
    .io_in_0_rx_snp_bits_retToSrc(i_io_in_0_rx_snp_bits_retToSrc),
    .io_out_0_tx_req_ready(io_out_0_tx_req_ready),
    .io_out_0_tx_req_valid(i_io_out_0_tx_req_valid),
    .io_out_0_tx_req_bits_tgtID(i_io_out_0_tx_req_bits_tgtID),
    .io_out_0_tx_req_bits_srcID(i_io_out_0_tx_req_bits_srcID),
    .io_out_0_tx_req_bits_txnID(i_io_out_0_tx_req_bits_txnID),
    .io_out_0_tx_req_bits_opcode(i_io_out_0_tx_req_bits_opcode),
    .io_out_0_tx_req_bits_size(i_io_out_0_tx_req_bits_size),
    .io_out_0_tx_req_bits_addr(i_io_out_0_tx_req_bits_addr),
    .io_out_0_tx_req_bits_allowRetry(i_io_out_0_tx_req_bits_allowRetry),
    .io_out_0_tx_req_bits_order(i_io_out_0_tx_req_bits_order),
    .io_out_0_tx_req_bits_pCrdType(i_io_out_0_tx_req_bits_pCrdType),
    .io_out_0_tx_req_bits_memAttr_allocate(i_io_out_0_tx_req_bits_memAttr_allocate),
    .io_out_0_tx_req_bits_memAttr_cacheable(i_io_out_0_tx_req_bits_memAttr_cacheable),
    .io_out_0_tx_req_bits_memAttr_device(i_io_out_0_tx_req_bits_memAttr_device),
    .io_out_0_tx_req_bits_memAttr_ewa(i_io_out_0_tx_req_bits_memAttr_ewa),
    .io_out_0_tx_req_bits_snpAttr(i_io_out_0_tx_req_bits_snpAttr),
    .io_out_0_tx_req_bits_expCompAck(i_io_out_0_tx_req_bits_expCompAck),
    .io_out_0_tx_rsp_valid(i_io_out_0_tx_rsp_valid),
    .io_out_0_tx_rsp_bits_srcID(i_io_out_0_tx_rsp_bits_srcID),
    .io_out_0_tx_rsp_bits_txnID(i_io_out_0_tx_rsp_bits_txnID),
    .io_out_0_tx_rsp_bits_opcode(i_io_out_0_tx_rsp_bits_opcode),
    .io_out_0_tx_rsp_bits_dbID(i_io_out_0_tx_rsp_bits_dbID),
    .io_out_0_tx_dat_valid(i_io_out_0_tx_dat_valid),
    .io_out_0_tx_dat_bits_srcID(i_io_out_0_tx_dat_bits_srcID),
    .io_out_0_tx_dat_bits_txnID(i_io_out_0_tx_dat_bits_txnID),
    .io_out_0_tx_dat_bits_opcode(i_io_out_0_tx_dat_bits_opcode),
    .io_out_0_tx_dat_bits_resp(i_io_out_0_tx_dat_bits_resp),
    .io_out_0_tx_dat_bits_dataID(i_io_out_0_tx_dat_bits_dataID),
    .io_out_0_tx_dat_bits_data(i_io_out_0_tx_dat_bits_data),
    .io_out_0_rx_rsp_ready(i_io_out_0_rx_rsp_ready),
    .io_out_0_rx_rsp_valid(io_out_0_rx_rsp_valid),
    .io_out_0_rx_rsp_bits_tgtID(io_out_0_rx_rsp_bits_tgtID),
    .io_out_0_rx_rsp_bits_srcID(io_out_0_rx_rsp_bits_srcID),
    .io_out_0_rx_rsp_bits_txnID(io_out_0_rx_rsp_bits_txnID),
    .io_out_0_rx_rsp_bits_opcode(io_out_0_rx_rsp_bits_opcode),
    .io_out_0_rx_rsp_bits_resp(io_out_0_rx_rsp_bits_resp),
    .io_out_0_rx_rsp_bits_fwdState(io_out_0_rx_rsp_bits_fwdState),
    .io_out_0_rx_rsp_bits_dbID(io_out_0_rx_rsp_bits_dbID),
    .io_out_0_rx_rsp_bits_pCrdType(io_out_0_rx_rsp_bits_pCrdType),
    .io_out_0_rx_dat_ready(i_io_out_0_rx_dat_ready),
    .io_out_0_rx_dat_valid(io_out_0_rx_dat_valid),
    .io_out_0_rx_dat_bits_tgtID(io_out_0_rx_dat_bits_tgtID),
    .io_out_0_rx_dat_bits_srcID(io_out_0_rx_dat_bits_srcID),
    .io_out_0_rx_dat_bits_txnID(io_out_0_rx_dat_bits_txnID),
    .io_out_0_rx_dat_bits_homeNID(io_out_0_rx_dat_bits_homeNID),
    .io_out_0_rx_dat_bits_opcode(io_out_0_rx_dat_bits_opcode),
    .io_out_0_rx_dat_bits_resp(io_out_0_rx_dat_bits_resp),
    .io_out_0_rx_dat_bits_dataSource(io_out_0_rx_dat_bits_dataSource),
    .io_out_0_rx_dat_bits_dbID(io_out_0_rx_dat_bits_dbID),
    .io_out_0_rx_dat_bits_dataID(io_out_0_rx_dat_bits_dataID),
    .io_out_0_rx_dat_bits_be(io_out_0_rx_dat_bits_be),
    .io_out_0_rx_dat_bits_data(io_out_0_rx_dat_bits_data),
    .io_out_0_rx_dat_bits_dataCheck(io_out_0_rx_dat_bits_dataCheck),
    .io_out_0_rx_snp_ready(i_io_out_0_rx_snp_ready),
    .io_out_0_rx_snp_valid(io_out_0_rx_snp_valid),
    .io_out_0_rx_snp_bits_txnID(io_out_0_rx_snp_bits_txnID),
    .io_out_0_rx_snp_bits_fwdNID(io_out_0_rx_snp_bits_fwdNID),
    .io_out_0_rx_snp_bits_fwdTxnID(io_out_0_rx_snp_bits_fwdTxnID),
    .io_out_0_rx_snp_bits_opcode(io_out_0_rx_snp_bits_opcode),
    .io_out_0_rx_snp_bits_addr(io_out_0_rx_snp_bits_addr),
    .io_out_0_rx_snp_bits_doNotGoToSD(io_out_0_rx_snp_bits_doNotGoToSD),
    .io_out_0_rx_snp_bits_retToSrc(io_out_0_rx_snp_bits_retToSrc),
    .io_out_1_tx_req_ready(io_out_1_tx_req_ready),
    .io_out_1_tx_req_valid(i_io_out_1_tx_req_valid),
    .io_out_1_tx_req_bits_tgtID(i_io_out_1_tx_req_bits_tgtID),
    .io_out_1_tx_req_bits_srcID(i_io_out_1_tx_req_bits_srcID),
    .io_out_1_tx_req_bits_txnID(i_io_out_1_tx_req_bits_txnID),
    .io_out_1_tx_req_bits_opcode(i_io_out_1_tx_req_bits_opcode),
    .io_out_1_tx_req_bits_size(i_io_out_1_tx_req_bits_size),
    .io_out_1_tx_req_bits_addr(i_io_out_1_tx_req_bits_addr),
    .io_out_1_tx_req_bits_allowRetry(i_io_out_1_tx_req_bits_allowRetry),
    .io_out_1_tx_req_bits_order(i_io_out_1_tx_req_bits_order),
    .io_out_1_tx_req_bits_pCrdType(i_io_out_1_tx_req_bits_pCrdType),
    .io_out_1_tx_req_bits_memAttr_allocate(i_io_out_1_tx_req_bits_memAttr_allocate),
    .io_out_1_tx_req_bits_memAttr_cacheable(i_io_out_1_tx_req_bits_memAttr_cacheable),
    .io_out_1_tx_req_bits_memAttr_device(i_io_out_1_tx_req_bits_memAttr_device),
    .io_out_1_tx_req_bits_memAttr_ewa(i_io_out_1_tx_req_bits_memAttr_ewa),
    .io_out_1_tx_req_bits_snpAttr(i_io_out_1_tx_req_bits_snpAttr),
    .io_out_1_tx_req_bits_expCompAck(i_io_out_1_tx_req_bits_expCompAck),
    .io_out_1_tx_rsp_valid(i_io_out_1_tx_rsp_valid),
    .io_out_1_tx_rsp_bits_srcID(i_io_out_1_tx_rsp_bits_srcID),
    .io_out_1_tx_rsp_bits_txnID(i_io_out_1_tx_rsp_bits_txnID),
    .io_out_1_tx_rsp_bits_opcode(i_io_out_1_tx_rsp_bits_opcode),
    .io_out_1_tx_rsp_bits_dbID(i_io_out_1_tx_rsp_bits_dbID),
    .io_out_1_tx_dat_valid(i_io_out_1_tx_dat_valid),
    .io_out_1_tx_dat_bits_srcID(i_io_out_1_tx_dat_bits_srcID),
    .io_out_1_tx_dat_bits_txnID(i_io_out_1_tx_dat_bits_txnID),
    .io_out_1_tx_dat_bits_opcode(i_io_out_1_tx_dat_bits_opcode),
    .io_out_1_tx_dat_bits_resp(i_io_out_1_tx_dat_bits_resp),
    .io_out_1_tx_dat_bits_dataID(i_io_out_1_tx_dat_bits_dataID),
    .io_out_1_tx_dat_bits_data(i_io_out_1_tx_dat_bits_data),
    .io_out_1_rx_rsp_ready(i_io_out_1_rx_rsp_ready),
    .io_out_1_rx_rsp_valid(io_out_1_rx_rsp_valid),
    .io_out_1_rx_rsp_bits_tgtID(io_out_1_rx_rsp_bits_tgtID),
    .io_out_1_rx_rsp_bits_srcID(io_out_1_rx_rsp_bits_srcID),
    .io_out_1_rx_rsp_bits_txnID(io_out_1_rx_rsp_bits_txnID),
    .io_out_1_rx_rsp_bits_opcode(io_out_1_rx_rsp_bits_opcode),
    .io_out_1_rx_rsp_bits_resp(io_out_1_rx_rsp_bits_resp),
    .io_out_1_rx_rsp_bits_fwdState(io_out_1_rx_rsp_bits_fwdState),
    .io_out_1_rx_rsp_bits_dbID(io_out_1_rx_rsp_bits_dbID),
    .io_out_1_rx_rsp_bits_pCrdType(io_out_1_rx_rsp_bits_pCrdType),
    .io_out_1_rx_dat_ready(i_io_out_1_rx_dat_ready),
    .io_out_1_rx_dat_valid(io_out_1_rx_dat_valid),
    .io_out_1_rx_dat_bits_tgtID(io_out_1_rx_dat_bits_tgtID),
    .io_out_1_rx_dat_bits_srcID(io_out_1_rx_dat_bits_srcID),
    .io_out_1_rx_dat_bits_txnID(io_out_1_rx_dat_bits_txnID),
    .io_out_1_rx_dat_bits_homeNID(io_out_1_rx_dat_bits_homeNID),
    .io_out_1_rx_dat_bits_opcode(io_out_1_rx_dat_bits_opcode),
    .io_out_1_rx_dat_bits_resp(io_out_1_rx_dat_bits_resp),
    .io_out_1_rx_dat_bits_dataSource(io_out_1_rx_dat_bits_dataSource),
    .io_out_1_rx_dat_bits_dbID(io_out_1_rx_dat_bits_dbID),
    .io_out_1_rx_dat_bits_dataID(io_out_1_rx_dat_bits_dataID),
    .io_out_1_rx_dat_bits_be(io_out_1_rx_dat_bits_be),
    .io_out_1_rx_dat_bits_data(io_out_1_rx_dat_bits_data),
    .io_out_1_rx_dat_bits_dataCheck(io_out_1_rx_dat_bits_dataCheck),
    .io_out_1_rx_snp_ready(i_io_out_1_rx_snp_ready),
    .io_out_1_rx_snp_valid(io_out_1_rx_snp_valid),
    .io_out_1_rx_snp_bits_txnID(io_out_1_rx_snp_bits_txnID),
    .io_out_1_rx_snp_bits_fwdNID(io_out_1_rx_snp_bits_fwdNID),
    .io_out_1_rx_snp_bits_fwdTxnID(io_out_1_rx_snp_bits_fwdTxnID),
    .io_out_1_rx_snp_bits_opcode(io_out_1_rx_snp_bits_opcode),
    .io_out_1_rx_snp_bits_addr(io_out_1_rx_snp_bits_addr),
    .io_out_1_rx_snp_bits_doNotGoToSD(io_out_1_rx_snp_bits_doNotGoToSD),
    .io_out_1_rx_snp_bits_retToSrc(io_out_1_rx_snp_bits_retToSrc),
    .io_out_2_tx_req_ready(io_out_2_tx_req_ready),
    .io_out_2_tx_req_valid(i_io_out_2_tx_req_valid),
    .io_out_2_tx_req_bits_tgtID(i_io_out_2_tx_req_bits_tgtID),
    .io_out_2_tx_req_bits_srcID(i_io_out_2_tx_req_bits_srcID),
    .io_out_2_tx_req_bits_txnID(i_io_out_2_tx_req_bits_txnID),
    .io_out_2_tx_req_bits_opcode(i_io_out_2_tx_req_bits_opcode),
    .io_out_2_tx_req_bits_size(i_io_out_2_tx_req_bits_size),
    .io_out_2_tx_req_bits_addr(i_io_out_2_tx_req_bits_addr),
    .io_out_2_tx_req_bits_allowRetry(i_io_out_2_tx_req_bits_allowRetry),
    .io_out_2_tx_req_bits_order(i_io_out_2_tx_req_bits_order),
    .io_out_2_tx_req_bits_pCrdType(i_io_out_2_tx_req_bits_pCrdType),
    .io_out_2_tx_req_bits_memAttr_allocate(i_io_out_2_tx_req_bits_memAttr_allocate),
    .io_out_2_tx_req_bits_memAttr_cacheable(i_io_out_2_tx_req_bits_memAttr_cacheable),
    .io_out_2_tx_req_bits_memAttr_device(i_io_out_2_tx_req_bits_memAttr_device),
    .io_out_2_tx_req_bits_memAttr_ewa(i_io_out_2_tx_req_bits_memAttr_ewa),
    .io_out_2_tx_req_bits_snpAttr(i_io_out_2_tx_req_bits_snpAttr),
    .io_out_2_tx_req_bits_expCompAck(i_io_out_2_tx_req_bits_expCompAck),
    .io_out_2_tx_rsp_valid(i_io_out_2_tx_rsp_valid),
    .io_out_2_tx_rsp_bits_srcID(i_io_out_2_tx_rsp_bits_srcID),
    .io_out_2_tx_rsp_bits_txnID(i_io_out_2_tx_rsp_bits_txnID),
    .io_out_2_tx_rsp_bits_opcode(i_io_out_2_tx_rsp_bits_opcode),
    .io_out_2_tx_rsp_bits_dbID(i_io_out_2_tx_rsp_bits_dbID),
    .io_out_2_tx_dat_valid(i_io_out_2_tx_dat_valid),
    .io_out_2_tx_dat_bits_srcID(i_io_out_2_tx_dat_bits_srcID),
    .io_out_2_tx_dat_bits_txnID(i_io_out_2_tx_dat_bits_txnID),
    .io_out_2_tx_dat_bits_opcode(i_io_out_2_tx_dat_bits_opcode),
    .io_out_2_tx_dat_bits_resp(i_io_out_2_tx_dat_bits_resp),
    .io_out_2_tx_dat_bits_dataID(i_io_out_2_tx_dat_bits_dataID),
    .io_out_2_tx_dat_bits_data(i_io_out_2_tx_dat_bits_data),
    .io_out_2_rx_rsp_ready(i_io_out_2_rx_rsp_ready),
    .io_out_2_rx_rsp_valid(io_out_2_rx_rsp_valid),
    .io_out_2_rx_rsp_bits_tgtID(io_out_2_rx_rsp_bits_tgtID),
    .io_out_2_rx_rsp_bits_srcID(io_out_2_rx_rsp_bits_srcID),
    .io_out_2_rx_rsp_bits_txnID(io_out_2_rx_rsp_bits_txnID),
    .io_out_2_rx_rsp_bits_opcode(io_out_2_rx_rsp_bits_opcode),
    .io_out_2_rx_rsp_bits_resp(io_out_2_rx_rsp_bits_resp),
    .io_out_2_rx_rsp_bits_fwdState(io_out_2_rx_rsp_bits_fwdState),
    .io_out_2_rx_rsp_bits_dbID(io_out_2_rx_rsp_bits_dbID),
    .io_out_2_rx_rsp_bits_pCrdType(io_out_2_rx_rsp_bits_pCrdType),
    .io_out_2_rx_dat_ready(i_io_out_2_rx_dat_ready),
    .io_out_2_rx_dat_valid(io_out_2_rx_dat_valid),
    .io_out_2_rx_dat_bits_tgtID(io_out_2_rx_dat_bits_tgtID),
    .io_out_2_rx_dat_bits_srcID(io_out_2_rx_dat_bits_srcID),
    .io_out_2_rx_dat_bits_txnID(io_out_2_rx_dat_bits_txnID),
    .io_out_2_rx_dat_bits_homeNID(io_out_2_rx_dat_bits_homeNID),
    .io_out_2_rx_dat_bits_opcode(io_out_2_rx_dat_bits_opcode),
    .io_out_2_rx_dat_bits_resp(io_out_2_rx_dat_bits_resp),
    .io_out_2_rx_dat_bits_dataSource(io_out_2_rx_dat_bits_dataSource),
    .io_out_2_rx_dat_bits_dbID(io_out_2_rx_dat_bits_dbID),
    .io_out_2_rx_dat_bits_dataID(io_out_2_rx_dat_bits_dataID),
    .io_out_2_rx_dat_bits_be(io_out_2_rx_dat_bits_be),
    .io_out_2_rx_dat_bits_data(io_out_2_rx_dat_bits_data),
    .io_out_2_rx_dat_bits_dataCheck(io_out_2_rx_dat_bits_dataCheck),
    .io_out_2_rx_snp_ready(i_io_out_2_rx_snp_ready),
    .io_out_2_rx_snp_valid(io_out_2_rx_snp_valid),
    .io_out_2_rx_snp_bits_txnID(io_out_2_rx_snp_bits_txnID),
    .io_out_2_rx_snp_bits_fwdNID(io_out_2_rx_snp_bits_fwdNID),
    .io_out_2_rx_snp_bits_fwdTxnID(io_out_2_rx_snp_bits_fwdTxnID),
    .io_out_2_rx_snp_bits_opcode(io_out_2_rx_snp_bits_opcode),
    .io_out_2_rx_snp_bits_addr(io_out_2_rx_snp_bits_addr),
    .io_out_2_rx_snp_bits_doNotGoToSD(io_out_2_rx_snp_bits_doNotGoToSD),
    .io_out_2_rx_snp_bits_retToSrc(io_out_2_rx_snp_bits_retToSrc),
    .io_out_3_tx_req_ready(io_out_3_tx_req_ready),
    .io_out_3_tx_req_valid(i_io_out_3_tx_req_valid),
    .io_out_3_tx_req_bits_tgtID(i_io_out_3_tx_req_bits_tgtID),
    .io_out_3_tx_req_bits_srcID(i_io_out_3_tx_req_bits_srcID),
    .io_out_3_tx_req_bits_txnID(i_io_out_3_tx_req_bits_txnID),
    .io_out_3_tx_req_bits_opcode(i_io_out_3_tx_req_bits_opcode),
    .io_out_3_tx_req_bits_size(i_io_out_3_tx_req_bits_size),
    .io_out_3_tx_req_bits_addr(i_io_out_3_tx_req_bits_addr),
    .io_out_3_tx_req_bits_allowRetry(i_io_out_3_tx_req_bits_allowRetry),
    .io_out_3_tx_req_bits_order(i_io_out_3_tx_req_bits_order),
    .io_out_3_tx_req_bits_pCrdType(i_io_out_3_tx_req_bits_pCrdType),
    .io_out_3_tx_req_bits_memAttr_allocate(i_io_out_3_tx_req_bits_memAttr_allocate),
    .io_out_3_tx_req_bits_memAttr_cacheable(i_io_out_3_tx_req_bits_memAttr_cacheable),
    .io_out_3_tx_req_bits_memAttr_device(i_io_out_3_tx_req_bits_memAttr_device),
    .io_out_3_tx_req_bits_memAttr_ewa(i_io_out_3_tx_req_bits_memAttr_ewa),
    .io_out_3_tx_req_bits_snpAttr(i_io_out_3_tx_req_bits_snpAttr),
    .io_out_3_tx_req_bits_expCompAck(i_io_out_3_tx_req_bits_expCompAck),
    .io_out_3_tx_rsp_valid(i_io_out_3_tx_rsp_valid),
    .io_out_3_tx_rsp_bits_srcID(i_io_out_3_tx_rsp_bits_srcID),
    .io_out_3_tx_rsp_bits_txnID(i_io_out_3_tx_rsp_bits_txnID),
    .io_out_3_tx_rsp_bits_opcode(i_io_out_3_tx_rsp_bits_opcode),
    .io_out_3_tx_rsp_bits_dbID(i_io_out_3_tx_rsp_bits_dbID),
    .io_out_3_tx_dat_valid(i_io_out_3_tx_dat_valid),
    .io_out_3_tx_dat_bits_srcID(i_io_out_3_tx_dat_bits_srcID),
    .io_out_3_tx_dat_bits_txnID(i_io_out_3_tx_dat_bits_txnID),
    .io_out_3_tx_dat_bits_opcode(i_io_out_3_tx_dat_bits_opcode),
    .io_out_3_tx_dat_bits_resp(i_io_out_3_tx_dat_bits_resp),
    .io_out_3_tx_dat_bits_dataID(i_io_out_3_tx_dat_bits_dataID),
    .io_out_3_tx_dat_bits_data(i_io_out_3_tx_dat_bits_data),
    .io_out_3_rx_rsp_ready(i_io_out_3_rx_rsp_ready),
    .io_out_3_rx_rsp_valid(io_out_3_rx_rsp_valid),
    .io_out_3_rx_rsp_bits_tgtID(io_out_3_rx_rsp_bits_tgtID),
    .io_out_3_rx_rsp_bits_srcID(io_out_3_rx_rsp_bits_srcID),
    .io_out_3_rx_rsp_bits_txnID(io_out_3_rx_rsp_bits_txnID),
    .io_out_3_rx_rsp_bits_opcode(io_out_3_rx_rsp_bits_opcode),
    .io_out_3_rx_rsp_bits_resp(io_out_3_rx_rsp_bits_resp),
    .io_out_3_rx_rsp_bits_fwdState(io_out_3_rx_rsp_bits_fwdState),
    .io_out_3_rx_rsp_bits_dbID(io_out_3_rx_rsp_bits_dbID),
    .io_out_3_rx_rsp_bits_pCrdType(io_out_3_rx_rsp_bits_pCrdType),
    .io_out_3_rx_dat_ready(i_io_out_3_rx_dat_ready),
    .io_out_3_rx_dat_valid(io_out_3_rx_dat_valid),
    .io_out_3_rx_dat_bits_tgtID(io_out_3_rx_dat_bits_tgtID),
    .io_out_3_rx_dat_bits_srcID(io_out_3_rx_dat_bits_srcID),
    .io_out_3_rx_dat_bits_txnID(io_out_3_rx_dat_bits_txnID),
    .io_out_3_rx_dat_bits_homeNID(io_out_3_rx_dat_bits_homeNID),
    .io_out_3_rx_dat_bits_opcode(io_out_3_rx_dat_bits_opcode),
    .io_out_3_rx_dat_bits_resp(io_out_3_rx_dat_bits_resp),
    .io_out_3_rx_dat_bits_dataSource(io_out_3_rx_dat_bits_dataSource),
    .io_out_3_rx_dat_bits_dbID(io_out_3_rx_dat_bits_dbID),
    .io_out_3_rx_dat_bits_dataID(io_out_3_rx_dat_bits_dataID),
    .io_out_3_rx_dat_bits_be(io_out_3_rx_dat_bits_be),
    .io_out_3_rx_dat_bits_data(io_out_3_rx_dat_bits_data),
    .io_out_3_rx_dat_bits_dataCheck(io_out_3_rx_dat_bits_dataCheck),
    .io_out_3_rx_snp_ready(i_io_out_3_rx_snp_ready),
    .io_out_3_rx_snp_valid(io_out_3_rx_snp_valid),
    .io_out_3_rx_snp_bits_txnID(io_out_3_rx_snp_bits_txnID),
    .io_out_3_rx_snp_bits_fwdNID(io_out_3_rx_snp_bits_fwdNID),
    .io_out_3_rx_snp_bits_fwdTxnID(io_out_3_rx_snp_bits_fwdTxnID),
    .io_out_3_rx_snp_bits_opcode(io_out_3_rx_snp_bits_opcode),
    .io_out_3_rx_snp_bits_addr(io_out_3_rx_snp_bits_addr),
    .io_out_3_rx_snp_bits_doNotGoToSD(io_out_3_rx_snp_bits_doNotGoToSD),
    .io_out_3_rx_snp_bits_retToSrc(io_out_3_rx_snp_bits_retToSrc),
    .io_snpMasks_0_0(io_snpMasks_0_0),
    .io_snpMasks_1_0(io_snpMasks_1_0),
    .io_snpMasks_2_0(io_snpMasks_2_0),
    .io_snpMasks_3_0(io_snpMasks_3_0)
  );

  task automatic drive_random_inputs();
    io_in_0_tx_req_valid <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_qos <= 4'({$urandom});
    io_in_0_tx_req_bits_tgtID <= 11'({$urandom});
    io_in_0_tx_req_bits_srcID <= 11'({$urandom});
    io_in_0_tx_req_bits_txnID <= 12'({$urandom});
    io_in_0_tx_req_bits_returnNID <= 11'({$urandom});
    io_in_0_tx_req_bits_stashNIDValid <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_returnTxnID <= 12'({$urandom});
    io_in_0_tx_req_bits_opcode <= 7'({$urandom});
    io_in_0_tx_req_bits_size <= 3'({$urandom});
    io_in_0_tx_req_bits_addr <= 48'({$urandom, $urandom});
    io_in_0_tx_req_bits_ns <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_likelyshared <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_allowRetry <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_order <= 2'({$urandom});
    io_in_0_tx_req_bits_pCrdType <= 4'({$urandom});
    io_in_0_tx_req_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_snpAttr <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_lpIDWithPadding <= 8'({$urandom});
    io_in_0_tx_req_bits_snoopMe <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_expCompAck <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_tagOp <= 2'({$urandom});
    io_in_0_tx_req_bits_traceTag <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_mpam_perfMonGroup <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_mpam_partID <= 9'({$urandom});
    io_in_0_tx_req_bits_mpam_mpamNS <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_rsvdc <= 4'({$urandom});
    io_in_0_tx_rsp_valid <= $urandom_range(0, 1);
    io_in_0_tx_rsp_bits_srcID <= 11'({$urandom});
    io_in_0_tx_rsp_bits_txnID <= 12'({$urandom});
    io_in_0_tx_rsp_bits_opcode <= 5'({$urandom});
    io_in_0_tx_rsp_bits_dbID <= 12'({$urandom});
    io_in_0_tx_dat_valid <= $urandom_range(0, 1);
    io_in_0_tx_dat_bits_qos <= 4'({$urandom});
    io_in_0_tx_dat_bits_tgtID <= 11'({$urandom});
    io_in_0_tx_dat_bits_srcID <= 11'({$urandom});
    io_in_0_tx_dat_bits_txnID <= 12'({$urandom});
    io_in_0_tx_dat_bits_homeNID <= 11'({$urandom});
    io_in_0_tx_dat_bits_opcode <= 4'({$urandom});
    io_in_0_tx_dat_bits_respErr <= 2'({$urandom});
    io_in_0_tx_dat_bits_resp <= 3'({$urandom});
    io_in_0_tx_dat_bits_dataSource <= 4'({$urandom});
    io_in_0_tx_dat_bits_cBusy <= 3'({$urandom});
    io_in_0_tx_dat_bits_dbID <= 12'({$urandom});
    io_in_0_tx_dat_bits_ccID <= 2'({$urandom});
    io_in_0_tx_dat_bits_dataID <= 2'({$urandom});
    io_in_0_tx_dat_bits_tagOp <= 2'({$urandom});
    io_in_0_tx_dat_bits_tag <= 8'({$urandom});
    io_in_0_tx_dat_bits_tu <= 2'({$urandom});
    io_in_0_tx_dat_bits_traceTag <= $urandom_range(0, 1);
    io_in_0_tx_dat_bits_rsvdc <= 4'({$urandom});
    io_in_0_tx_dat_bits_be <= 32'({$urandom});
    io_in_0_tx_dat_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_0_tx_dat_bits_dataCheck <= 32'({$urandom});
    io_in_0_tx_dat_bits_poison <= 4'({$urandom});
    io_in_0_rx_rsp_ready <= $urandom_range(0, 1);
    io_in_0_rx_dat_ready <= $urandom_range(0, 1);
    io_in_0_rx_snp_ready <= $urandom_range(0, 1);
    io_out_0_tx_req_ready <= $urandom_range(0, 1);
    io_out_0_rx_rsp_valid <= $urandom_range(0, 1);
    io_out_0_rx_rsp_bits_tgtID <= 11'({$urandom});
    io_out_0_rx_rsp_bits_srcID <= 11'({$urandom});
    io_out_0_rx_rsp_bits_txnID <= 12'({$urandom});
    io_out_0_rx_rsp_bits_opcode <= 5'({$urandom});
    io_out_0_rx_rsp_bits_resp <= 3'({$urandom});
    io_out_0_rx_rsp_bits_fwdState <= 3'({$urandom});
    io_out_0_rx_rsp_bits_dbID <= 12'({$urandom});
    io_out_0_rx_rsp_bits_pCrdType <= 4'({$urandom});
    io_out_0_rx_dat_valid <= $urandom_range(0, 1);
    io_out_0_rx_dat_bits_tgtID <= 11'({$urandom});
    io_out_0_rx_dat_bits_srcID <= 11'({$urandom});
    io_out_0_rx_dat_bits_txnID <= 12'({$urandom});
    io_out_0_rx_dat_bits_homeNID <= 11'({$urandom});
    io_out_0_rx_dat_bits_opcode <= 4'({$urandom});
    io_out_0_rx_dat_bits_resp <= 3'({$urandom});
    io_out_0_rx_dat_bits_dataSource <= 4'({$urandom});
    io_out_0_rx_dat_bits_dbID <= 12'({$urandom});
    io_out_0_rx_dat_bits_dataID <= 2'({$urandom});
    io_out_0_rx_dat_bits_be <= 32'({$urandom});
    io_out_0_rx_dat_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_out_0_rx_dat_bits_dataCheck <= 32'({$urandom});
    io_out_0_rx_snp_valid <= $urandom_range(0, 1);
    io_out_0_rx_snp_bits_txnID <= 12'({$urandom});
    io_out_0_rx_snp_bits_fwdNID <= 11'({$urandom});
    io_out_0_rx_snp_bits_fwdTxnID <= 12'({$urandom});
    io_out_0_rx_snp_bits_opcode <= 5'({$urandom});
    io_out_0_rx_snp_bits_addr <= 45'({$urandom, $urandom});
    io_out_0_rx_snp_bits_doNotGoToSD <= $urandom_range(0, 1);
    io_out_0_rx_snp_bits_retToSrc <= $urandom_range(0, 1);
    io_out_1_tx_req_ready <= $urandom_range(0, 1);
    io_out_1_rx_rsp_valid <= $urandom_range(0, 1);
    io_out_1_rx_rsp_bits_tgtID <= 11'({$urandom});
    io_out_1_rx_rsp_bits_srcID <= 11'({$urandom});
    io_out_1_rx_rsp_bits_txnID <= 12'({$urandom});
    io_out_1_rx_rsp_bits_opcode <= 5'({$urandom});
    io_out_1_rx_rsp_bits_resp <= 3'({$urandom});
    io_out_1_rx_rsp_bits_fwdState <= 3'({$urandom});
    io_out_1_rx_rsp_bits_dbID <= 12'({$urandom});
    io_out_1_rx_rsp_bits_pCrdType <= 4'({$urandom});
    io_out_1_rx_dat_valid <= $urandom_range(0, 1);
    io_out_1_rx_dat_bits_tgtID <= 11'({$urandom});
    io_out_1_rx_dat_bits_srcID <= 11'({$urandom});
    io_out_1_rx_dat_bits_txnID <= 12'({$urandom});
    io_out_1_rx_dat_bits_homeNID <= 11'({$urandom});
    io_out_1_rx_dat_bits_opcode <= 4'({$urandom});
    io_out_1_rx_dat_bits_resp <= 3'({$urandom});
    io_out_1_rx_dat_bits_dataSource <= 4'({$urandom});
    io_out_1_rx_dat_bits_dbID <= 12'({$urandom});
    io_out_1_rx_dat_bits_dataID <= 2'({$urandom});
    io_out_1_rx_dat_bits_be <= 32'({$urandom});
    io_out_1_rx_dat_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_out_1_rx_dat_bits_dataCheck <= 32'({$urandom});
    io_out_1_rx_snp_valid <= $urandom_range(0, 1);
    io_out_1_rx_snp_bits_txnID <= 12'({$urandom});
    io_out_1_rx_snp_bits_fwdNID <= 11'({$urandom});
    io_out_1_rx_snp_bits_fwdTxnID <= 12'({$urandom});
    io_out_1_rx_snp_bits_opcode <= 5'({$urandom});
    io_out_1_rx_snp_bits_addr <= 45'({$urandom, $urandom});
    io_out_1_rx_snp_bits_doNotGoToSD <= $urandom_range(0, 1);
    io_out_1_rx_snp_bits_retToSrc <= $urandom_range(0, 1);
    io_out_2_tx_req_ready <= $urandom_range(0, 1);
    io_out_2_rx_rsp_valid <= $urandom_range(0, 1);
    io_out_2_rx_rsp_bits_tgtID <= 11'({$urandom});
    io_out_2_rx_rsp_bits_srcID <= 11'({$urandom});
    io_out_2_rx_rsp_bits_txnID <= 12'({$urandom});
    io_out_2_rx_rsp_bits_opcode <= 5'({$urandom});
    io_out_2_rx_rsp_bits_resp <= 3'({$urandom});
    io_out_2_rx_rsp_bits_fwdState <= 3'({$urandom});
    io_out_2_rx_rsp_bits_dbID <= 12'({$urandom});
    io_out_2_rx_rsp_bits_pCrdType <= 4'({$urandom});
    io_out_2_rx_dat_valid <= $urandom_range(0, 1);
    io_out_2_rx_dat_bits_tgtID <= 11'({$urandom});
    io_out_2_rx_dat_bits_srcID <= 11'({$urandom});
    io_out_2_rx_dat_bits_txnID <= 12'({$urandom});
    io_out_2_rx_dat_bits_homeNID <= 11'({$urandom});
    io_out_2_rx_dat_bits_opcode <= 4'({$urandom});
    io_out_2_rx_dat_bits_resp <= 3'({$urandom});
    io_out_2_rx_dat_bits_dataSource <= 4'({$urandom});
    io_out_2_rx_dat_bits_dbID <= 12'({$urandom});
    io_out_2_rx_dat_bits_dataID <= 2'({$urandom});
    io_out_2_rx_dat_bits_be <= 32'({$urandom});
    io_out_2_rx_dat_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_out_2_rx_dat_bits_dataCheck <= 32'({$urandom});
    io_out_2_rx_snp_valid <= $urandom_range(0, 1);
    io_out_2_rx_snp_bits_txnID <= 12'({$urandom});
    io_out_2_rx_snp_bits_fwdNID <= 11'({$urandom});
    io_out_2_rx_snp_bits_fwdTxnID <= 12'({$urandom});
    io_out_2_rx_snp_bits_opcode <= 5'({$urandom});
    io_out_2_rx_snp_bits_addr <= 45'({$urandom, $urandom});
    io_out_2_rx_snp_bits_doNotGoToSD <= $urandom_range(0, 1);
    io_out_2_rx_snp_bits_retToSrc <= $urandom_range(0, 1);
    io_out_3_tx_req_ready <= $urandom_range(0, 1);
    io_out_3_rx_rsp_valid <= $urandom_range(0, 1);
    io_out_3_rx_rsp_bits_tgtID <= 11'({$urandom});
    io_out_3_rx_rsp_bits_srcID <= 11'({$urandom});
    io_out_3_rx_rsp_bits_txnID <= 12'({$urandom});
    io_out_3_rx_rsp_bits_opcode <= 5'({$urandom});
    io_out_3_rx_rsp_bits_resp <= 3'({$urandom});
    io_out_3_rx_rsp_bits_fwdState <= 3'({$urandom});
    io_out_3_rx_rsp_bits_dbID <= 12'({$urandom});
    io_out_3_rx_rsp_bits_pCrdType <= 4'({$urandom});
    io_out_3_rx_dat_valid <= $urandom_range(0, 1);
    io_out_3_rx_dat_bits_tgtID <= 11'({$urandom});
    io_out_3_rx_dat_bits_srcID <= 11'({$urandom});
    io_out_3_rx_dat_bits_txnID <= 12'({$urandom});
    io_out_3_rx_dat_bits_homeNID <= 11'({$urandom});
    io_out_3_rx_dat_bits_opcode <= 4'({$urandom});
    io_out_3_rx_dat_bits_resp <= 3'({$urandom});
    io_out_3_rx_dat_bits_dataSource <= 4'({$urandom});
    io_out_3_rx_dat_bits_dbID <= 12'({$urandom});
    io_out_3_rx_dat_bits_dataID <= 2'({$urandom});
    io_out_3_rx_dat_bits_be <= 32'({$urandom});
    io_out_3_rx_dat_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_out_3_rx_dat_bits_dataCheck <= 32'({$urandom});
    io_out_3_rx_snp_valid <= $urandom_range(0, 1);
    io_out_3_rx_snp_bits_txnID <= 12'({$urandom});
    io_out_3_rx_snp_bits_fwdNID <= 11'({$urandom});
    io_out_3_rx_snp_bits_fwdTxnID <= 12'({$urandom});
    io_out_3_rx_snp_bits_opcode <= 5'({$urandom});
    io_out_3_rx_snp_bits_addr <= 45'({$urandom, $urandom});
    io_out_3_rx_snp_bits_doNotGoToSD <= $urandom_range(0, 1);
    io_out_3_rx_snp_bits_retToSrc <= $urandom_range(0, 1);
    io_snpMasks_0_0 <= $urandom_range(0, 1);
    io_snpMasks_1_0 <= $urandom_range(0, 1);
    io_snpMasks_2_0 <= $urandom_range(0, 1);
    io_snpMasks_3_0 <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(io_in_0_tx_req_ready)
    `CHECK(io_in_0_tx_rsp_ready)
    `CHECK(io_in_0_tx_dat_ready)
    `CHECK(io_in_0_rx_rsp_valid)
    `CHECK(io_in_0_rx_rsp_bits_qos)
    `CHECK(io_in_0_rx_rsp_bits_txnID)
    `CHECK(io_in_0_rx_rsp_bits_opcode)
    `CHECK(io_in_0_rx_rsp_bits_respErr)
    `CHECK(io_in_0_rx_rsp_bits_resp)
    `CHECK(io_in_0_rx_rsp_bits_fwdState)
    `CHECK(io_in_0_rx_rsp_bits_cBusy)
    `CHECK(io_in_0_rx_rsp_bits_dbID)
    `CHECK(io_in_0_rx_rsp_bits_pCrdType)
    `CHECK(io_in_0_rx_rsp_bits_tagOp)
    `CHECK(io_in_0_rx_rsp_bits_traceTag)
    `CHECK(io_in_0_rx_dat_valid)
    `CHECK(io_in_0_rx_dat_bits_txnID)
    `CHECK(io_in_0_rx_dat_bits_homeNID)
    `CHECK(io_in_0_rx_dat_bits_opcode)
    `CHECK(io_in_0_rx_dat_bits_resp)
    `CHECK(io_in_0_rx_dat_bits_dataSource)
    `CHECK(io_in_0_rx_dat_bits_dbID)
    `CHECK(io_in_0_rx_dat_bits_dataID)
    `CHECK(io_in_0_rx_dat_bits_be)
    `CHECK(io_in_0_rx_dat_bits_data)
    `CHECK(io_in_0_rx_dat_bits_dataCheck)
    `CHECK(io_in_0_rx_snp_valid)
    `CHECK(io_in_0_rx_snp_bits_txnID)
    `CHECK(io_in_0_rx_snp_bits_fwdNID)
    `CHECK(io_in_0_rx_snp_bits_fwdTxnID)
    `CHECK(io_in_0_rx_snp_bits_opcode)
    `CHECK(io_in_0_rx_snp_bits_addr)
    `CHECK(io_in_0_rx_snp_bits_doNotGoToSD)
    `CHECK(io_in_0_rx_snp_bits_retToSrc)
    `CHECK(io_out_0_tx_req_valid)
    `CHECK(io_out_0_tx_req_bits_tgtID)
    `CHECK(io_out_0_tx_req_bits_srcID)
    `CHECK(io_out_0_tx_req_bits_txnID)
    `CHECK(io_out_0_tx_req_bits_opcode)
    `CHECK(io_out_0_tx_req_bits_size)
    `CHECK(io_out_0_tx_req_bits_addr)
    `CHECK(io_out_0_tx_req_bits_allowRetry)
    `CHECK(io_out_0_tx_req_bits_order)
    `CHECK(io_out_0_tx_req_bits_pCrdType)
    `CHECK(io_out_0_tx_req_bits_memAttr_allocate)
    `CHECK(io_out_0_tx_req_bits_memAttr_cacheable)
    `CHECK(io_out_0_tx_req_bits_memAttr_device)
    `CHECK(io_out_0_tx_req_bits_memAttr_ewa)
    `CHECK(io_out_0_tx_req_bits_snpAttr)
    `CHECK(io_out_0_tx_req_bits_expCompAck)
    `CHECK(io_out_0_tx_rsp_valid)
    `CHECK(io_out_0_tx_rsp_bits_srcID)
    `CHECK(io_out_0_tx_rsp_bits_txnID)
    `CHECK(io_out_0_tx_rsp_bits_opcode)
    `CHECK(io_out_0_tx_rsp_bits_dbID)
    `CHECK(io_out_0_tx_dat_valid)
    `CHECK(io_out_0_tx_dat_bits_srcID)
    `CHECK(io_out_0_tx_dat_bits_txnID)
    `CHECK(io_out_0_tx_dat_bits_opcode)
    `CHECK(io_out_0_tx_dat_bits_resp)
    `CHECK(io_out_0_tx_dat_bits_dataID)
    `CHECK(io_out_0_tx_dat_bits_data)
    `CHECK(io_out_0_rx_rsp_ready)
    `CHECK(io_out_0_rx_dat_ready)
    `CHECK(io_out_0_rx_snp_ready)
    `CHECK(io_out_1_tx_req_valid)
    `CHECK(io_out_1_tx_req_bits_tgtID)
    `CHECK(io_out_1_tx_req_bits_srcID)
    `CHECK(io_out_1_tx_req_bits_txnID)
    `CHECK(io_out_1_tx_req_bits_opcode)
    `CHECK(io_out_1_tx_req_bits_size)
    `CHECK(io_out_1_tx_req_bits_addr)
    `CHECK(io_out_1_tx_req_bits_allowRetry)
    `CHECK(io_out_1_tx_req_bits_order)
    `CHECK(io_out_1_tx_req_bits_pCrdType)
    `CHECK(io_out_1_tx_req_bits_memAttr_allocate)
    `CHECK(io_out_1_tx_req_bits_memAttr_cacheable)
    `CHECK(io_out_1_tx_req_bits_memAttr_device)
    `CHECK(io_out_1_tx_req_bits_memAttr_ewa)
    `CHECK(io_out_1_tx_req_bits_snpAttr)
    `CHECK(io_out_1_tx_req_bits_expCompAck)
    `CHECK(io_out_1_tx_rsp_valid)
    `CHECK(io_out_1_tx_rsp_bits_srcID)
    `CHECK(io_out_1_tx_rsp_bits_txnID)
    `CHECK(io_out_1_tx_rsp_bits_opcode)
    `CHECK(io_out_1_tx_rsp_bits_dbID)
    `CHECK(io_out_1_tx_dat_valid)
    `CHECK(io_out_1_tx_dat_bits_srcID)
    `CHECK(io_out_1_tx_dat_bits_txnID)
    `CHECK(io_out_1_tx_dat_bits_opcode)
    `CHECK(io_out_1_tx_dat_bits_resp)
    `CHECK(io_out_1_tx_dat_bits_dataID)
    `CHECK(io_out_1_tx_dat_bits_data)
    `CHECK(io_out_1_rx_rsp_ready)
    `CHECK(io_out_1_rx_dat_ready)
    `CHECK(io_out_1_rx_snp_ready)
    `CHECK(io_out_2_tx_req_valid)
    `CHECK(io_out_2_tx_req_bits_tgtID)
    `CHECK(io_out_2_tx_req_bits_srcID)
    `CHECK(io_out_2_tx_req_bits_txnID)
    `CHECK(io_out_2_tx_req_bits_opcode)
    `CHECK(io_out_2_tx_req_bits_size)
    `CHECK(io_out_2_tx_req_bits_addr)
    `CHECK(io_out_2_tx_req_bits_allowRetry)
    `CHECK(io_out_2_tx_req_bits_order)
    `CHECK(io_out_2_tx_req_bits_pCrdType)
    `CHECK(io_out_2_tx_req_bits_memAttr_allocate)
    `CHECK(io_out_2_tx_req_bits_memAttr_cacheable)
    `CHECK(io_out_2_tx_req_bits_memAttr_device)
    `CHECK(io_out_2_tx_req_bits_memAttr_ewa)
    `CHECK(io_out_2_tx_req_bits_snpAttr)
    `CHECK(io_out_2_tx_req_bits_expCompAck)
    `CHECK(io_out_2_tx_rsp_valid)
    `CHECK(io_out_2_tx_rsp_bits_srcID)
    `CHECK(io_out_2_tx_rsp_bits_txnID)
    `CHECK(io_out_2_tx_rsp_bits_opcode)
    `CHECK(io_out_2_tx_rsp_bits_dbID)
    `CHECK(io_out_2_tx_dat_valid)
    `CHECK(io_out_2_tx_dat_bits_srcID)
    `CHECK(io_out_2_tx_dat_bits_txnID)
    `CHECK(io_out_2_tx_dat_bits_opcode)
    `CHECK(io_out_2_tx_dat_bits_resp)
    `CHECK(io_out_2_tx_dat_bits_dataID)
    `CHECK(io_out_2_tx_dat_bits_data)
    `CHECK(io_out_2_rx_rsp_ready)
    `CHECK(io_out_2_rx_dat_ready)
    `CHECK(io_out_2_rx_snp_ready)
    `CHECK(io_out_3_tx_req_valid)
    `CHECK(io_out_3_tx_req_bits_tgtID)
    `CHECK(io_out_3_tx_req_bits_srcID)
    `CHECK(io_out_3_tx_req_bits_txnID)
    `CHECK(io_out_3_tx_req_bits_opcode)
    `CHECK(io_out_3_tx_req_bits_size)
    `CHECK(io_out_3_tx_req_bits_addr)
    `CHECK(io_out_3_tx_req_bits_allowRetry)
    `CHECK(io_out_3_tx_req_bits_order)
    `CHECK(io_out_3_tx_req_bits_pCrdType)
    `CHECK(io_out_3_tx_req_bits_memAttr_allocate)
    `CHECK(io_out_3_tx_req_bits_memAttr_cacheable)
    `CHECK(io_out_3_tx_req_bits_memAttr_device)
    `CHECK(io_out_3_tx_req_bits_memAttr_ewa)
    `CHECK(io_out_3_tx_req_bits_snpAttr)
    `CHECK(io_out_3_tx_req_bits_expCompAck)
    `CHECK(io_out_3_tx_rsp_valid)
    `CHECK(io_out_3_tx_rsp_bits_srcID)
    `CHECK(io_out_3_tx_rsp_bits_txnID)
    `CHECK(io_out_3_tx_rsp_bits_opcode)
    `CHECK(io_out_3_tx_rsp_bits_dbID)
    `CHECK(io_out_3_tx_dat_valid)
    `CHECK(io_out_3_tx_dat_bits_srcID)
    `CHECK(io_out_3_tx_dat_bits_txnID)
    `CHECK(io_out_3_tx_dat_bits_opcode)
    `CHECK(io_out_3_tx_dat_bits_resp)
    `CHECK(io_out_3_tx_dat_bits_dataID)
    `CHECK(io_out_3_tx_dat_bits_data)
    `CHECK(io_out_3_rx_rsp_ready)
    `CHECK(io_out_3_rx_dat_ready)
    `CHECK(io_out_3_rx_snp_ready)
    `PCHECK(u_g.snpMasks_0_0, u_i.u_core.snpMasks_0_0)
    `PCHECK(u_g.snpReqs_0_valid, u_i.u_core.snpReqs_0_valid)
    `PCHECK(u_g.snpReqs_0_bits_txnID, u_i.u_core.snpReqs_0_bits_txnID)
    `PCHECK(u_g.snpReqs_0_bits_fwdNID, u_i.u_core.snpReqs_0_bits_fwdNID)
    `PCHECK(u_g.snpReqs_0_bits_fwdTxnID, u_i.u_core.snpReqs_0_bits_fwdTxnID)
    `PCHECK(u_g.snpReqs_0_bits_opcode, u_i.u_core.snpReqs_0_bits_opcode)
    `PCHECK(u_g.snpReqs_0_bits_addr, u_i.u_core.snpReqs_0_bits_addr)
    `PCHECK(u_g.snpReqs_0_bits_doNotGoToSD, u_i.u_core.snpReqs_0_bits_doNotGoToSD)
    `PCHECK(u_g.snpReqs_0_bits_retToSrc, u_i.u_core.snpReqs_0_bits_retToSrc)
    `PCHECK(u_g.snpMasks_1_0, u_i.u_core.snpMasks_1_0)
    `PCHECK(u_g.snpReqs_1_valid, u_i.u_core.snpReqs_1_valid)
    `PCHECK(u_g.snpReqs_1_bits_txnID, u_i.u_core.snpReqs_1_bits_txnID)
    `PCHECK(u_g.snpReqs_1_bits_fwdNID, u_i.u_core.snpReqs_1_bits_fwdNID)
    `PCHECK(u_g.snpReqs_1_bits_fwdTxnID, u_i.u_core.snpReqs_1_bits_fwdTxnID)
    `PCHECK(u_g.snpReqs_1_bits_opcode, u_i.u_core.snpReqs_1_bits_opcode)
    `PCHECK(u_g.snpReqs_1_bits_addr, u_i.u_core.snpReqs_1_bits_addr)
    `PCHECK(u_g.snpReqs_1_bits_doNotGoToSD, u_i.u_core.snpReqs_1_bits_doNotGoToSD)
    `PCHECK(u_g.snpReqs_1_bits_retToSrc, u_i.u_core.snpReqs_1_bits_retToSrc)
    `PCHECK(u_g.snpMasks_2_0, u_i.u_core.snpMasks_2_0)
    `PCHECK(u_g.snpReqs_2_valid, u_i.u_core.snpReqs_2_valid)
    `PCHECK(u_g.snpReqs_2_bits_txnID, u_i.u_core.snpReqs_2_bits_txnID)
    `PCHECK(u_g.snpReqs_2_bits_fwdNID, u_i.u_core.snpReqs_2_bits_fwdNID)
    `PCHECK(u_g.snpReqs_2_bits_fwdTxnID, u_i.u_core.snpReqs_2_bits_fwdTxnID)
    `PCHECK(u_g.snpReqs_2_bits_opcode, u_i.u_core.snpReqs_2_bits_opcode)
    `PCHECK(u_g.snpReqs_2_bits_addr, u_i.u_core.snpReqs_2_bits_addr)
    `PCHECK(u_g.snpReqs_2_bits_doNotGoToSD, u_i.u_core.snpReqs_2_bits_doNotGoToSD)
    `PCHECK(u_g.snpReqs_2_bits_retToSrc, u_i.u_core.snpReqs_2_bits_retToSrc)
    `PCHECK(u_g.snpMasks_3_0, u_i.u_core.snpMasks_3_0)
    `PCHECK(u_g.snpReqs_3_valid, u_i.u_core.snpReqs_3_valid)
    `PCHECK(u_g.snpReqs_3_bits_txnID, u_i.u_core.snpReqs_3_bits_txnID)
    `PCHECK(u_g.snpReqs_3_bits_fwdNID, u_i.u_core.snpReqs_3_bits_fwdNID)
    `PCHECK(u_g.snpReqs_3_bits_fwdTxnID, u_i.u_core.snpReqs_3_bits_fwdTxnID)
    `PCHECK(u_g.snpReqs_3_bits_opcode, u_i.u_core.snpReqs_3_bits_opcode)
    `PCHECK(u_g.snpReqs_3_bits_addr, u_i.u_core.snpReqs_3_bits_addr)
    `PCHECK(u_g.snpReqs_3_bits_doNotGoToSD, u_i.u_core.snpReqs_3_bits_doNotGoToSD)
    `PCHECK(u_g.snpReqs_3_bits_retToSrc, u_i.u_core.snpReqs_3_bits_retToSrc)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_tx_req_valid = '0;
    io_in_0_tx_req_bits_qos = '0;
    io_in_0_tx_req_bits_tgtID = '0;
    io_in_0_tx_req_bits_srcID = '0;
    io_in_0_tx_req_bits_txnID = '0;
    io_in_0_tx_req_bits_returnNID = '0;
    io_in_0_tx_req_bits_stashNIDValid = '0;
    io_in_0_tx_req_bits_returnTxnID = '0;
    io_in_0_tx_req_bits_opcode = '0;
    io_in_0_tx_req_bits_size = '0;
    io_in_0_tx_req_bits_addr = '0;
    io_in_0_tx_req_bits_ns = '0;
    io_in_0_tx_req_bits_likelyshared = '0;
    io_in_0_tx_req_bits_allowRetry = '0;
    io_in_0_tx_req_bits_order = '0;
    io_in_0_tx_req_bits_pCrdType = '0;
    io_in_0_tx_req_bits_memAttr_allocate = '0;
    io_in_0_tx_req_bits_memAttr_cacheable = '0;
    io_in_0_tx_req_bits_memAttr_device = '0;
    io_in_0_tx_req_bits_memAttr_ewa = '0;
    io_in_0_tx_req_bits_snpAttr = '0;
    io_in_0_tx_req_bits_lpIDWithPadding = '0;
    io_in_0_tx_req_bits_snoopMe = '0;
    io_in_0_tx_req_bits_expCompAck = '0;
    io_in_0_tx_req_bits_tagOp = '0;
    io_in_0_tx_req_bits_traceTag = '0;
    io_in_0_tx_req_bits_mpam_perfMonGroup = '0;
    io_in_0_tx_req_bits_mpam_partID = '0;
    io_in_0_tx_req_bits_mpam_mpamNS = '0;
    io_in_0_tx_req_bits_rsvdc = '0;
    io_in_0_tx_rsp_valid = '0;
    io_in_0_tx_rsp_bits_srcID = '0;
    io_in_0_tx_rsp_bits_txnID = '0;
    io_in_0_tx_rsp_bits_opcode = '0;
    io_in_0_tx_rsp_bits_dbID = '0;
    io_in_0_tx_dat_valid = '0;
    io_in_0_tx_dat_bits_qos = '0;
    io_in_0_tx_dat_bits_tgtID = '0;
    io_in_0_tx_dat_bits_srcID = '0;
    io_in_0_tx_dat_bits_txnID = '0;
    io_in_0_tx_dat_bits_homeNID = '0;
    io_in_0_tx_dat_bits_opcode = '0;
    io_in_0_tx_dat_bits_respErr = '0;
    io_in_0_tx_dat_bits_resp = '0;
    io_in_0_tx_dat_bits_dataSource = '0;
    io_in_0_tx_dat_bits_cBusy = '0;
    io_in_0_tx_dat_bits_dbID = '0;
    io_in_0_tx_dat_bits_ccID = '0;
    io_in_0_tx_dat_bits_dataID = '0;
    io_in_0_tx_dat_bits_tagOp = '0;
    io_in_0_tx_dat_bits_tag = '0;
    io_in_0_tx_dat_bits_tu = '0;
    io_in_0_tx_dat_bits_traceTag = '0;
    io_in_0_tx_dat_bits_rsvdc = '0;
    io_in_0_tx_dat_bits_be = '0;
    io_in_0_tx_dat_bits_data = '0;
    io_in_0_tx_dat_bits_dataCheck = '0;
    io_in_0_tx_dat_bits_poison = '0;
    io_in_0_rx_rsp_ready = '0;
    io_in_0_rx_dat_ready = '0;
    io_in_0_rx_snp_ready = '0;
    io_out_0_tx_req_ready = '0;
    io_out_0_rx_rsp_valid = '0;
    io_out_0_rx_rsp_bits_tgtID = '0;
    io_out_0_rx_rsp_bits_srcID = '0;
    io_out_0_rx_rsp_bits_txnID = '0;
    io_out_0_rx_rsp_bits_opcode = '0;
    io_out_0_rx_rsp_bits_resp = '0;
    io_out_0_rx_rsp_bits_fwdState = '0;
    io_out_0_rx_rsp_bits_dbID = '0;
    io_out_0_rx_rsp_bits_pCrdType = '0;
    io_out_0_rx_dat_valid = '0;
    io_out_0_rx_dat_bits_tgtID = '0;
    io_out_0_rx_dat_bits_srcID = '0;
    io_out_0_rx_dat_bits_txnID = '0;
    io_out_0_rx_dat_bits_homeNID = '0;
    io_out_0_rx_dat_bits_opcode = '0;
    io_out_0_rx_dat_bits_resp = '0;
    io_out_0_rx_dat_bits_dataSource = '0;
    io_out_0_rx_dat_bits_dbID = '0;
    io_out_0_rx_dat_bits_dataID = '0;
    io_out_0_rx_dat_bits_be = '0;
    io_out_0_rx_dat_bits_data = '0;
    io_out_0_rx_dat_bits_dataCheck = '0;
    io_out_0_rx_snp_valid = '0;
    io_out_0_rx_snp_bits_txnID = '0;
    io_out_0_rx_snp_bits_fwdNID = '0;
    io_out_0_rx_snp_bits_fwdTxnID = '0;
    io_out_0_rx_snp_bits_opcode = '0;
    io_out_0_rx_snp_bits_addr = '0;
    io_out_0_rx_snp_bits_doNotGoToSD = '0;
    io_out_0_rx_snp_bits_retToSrc = '0;
    io_out_1_tx_req_ready = '0;
    io_out_1_rx_rsp_valid = '0;
    io_out_1_rx_rsp_bits_tgtID = '0;
    io_out_1_rx_rsp_bits_srcID = '0;
    io_out_1_rx_rsp_bits_txnID = '0;
    io_out_1_rx_rsp_bits_opcode = '0;
    io_out_1_rx_rsp_bits_resp = '0;
    io_out_1_rx_rsp_bits_fwdState = '0;
    io_out_1_rx_rsp_bits_dbID = '0;
    io_out_1_rx_rsp_bits_pCrdType = '0;
    io_out_1_rx_dat_valid = '0;
    io_out_1_rx_dat_bits_tgtID = '0;
    io_out_1_rx_dat_bits_srcID = '0;
    io_out_1_rx_dat_bits_txnID = '0;
    io_out_1_rx_dat_bits_homeNID = '0;
    io_out_1_rx_dat_bits_opcode = '0;
    io_out_1_rx_dat_bits_resp = '0;
    io_out_1_rx_dat_bits_dataSource = '0;
    io_out_1_rx_dat_bits_dbID = '0;
    io_out_1_rx_dat_bits_dataID = '0;
    io_out_1_rx_dat_bits_be = '0;
    io_out_1_rx_dat_bits_data = '0;
    io_out_1_rx_dat_bits_dataCheck = '0;
    io_out_1_rx_snp_valid = '0;
    io_out_1_rx_snp_bits_txnID = '0;
    io_out_1_rx_snp_bits_fwdNID = '0;
    io_out_1_rx_snp_bits_fwdTxnID = '0;
    io_out_1_rx_snp_bits_opcode = '0;
    io_out_1_rx_snp_bits_addr = '0;
    io_out_1_rx_snp_bits_doNotGoToSD = '0;
    io_out_1_rx_snp_bits_retToSrc = '0;
    io_out_2_tx_req_ready = '0;
    io_out_2_rx_rsp_valid = '0;
    io_out_2_rx_rsp_bits_tgtID = '0;
    io_out_2_rx_rsp_bits_srcID = '0;
    io_out_2_rx_rsp_bits_txnID = '0;
    io_out_2_rx_rsp_bits_opcode = '0;
    io_out_2_rx_rsp_bits_resp = '0;
    io_out_2_rx_rsp_bits_fwdState = '0;
    io_out_2_rx_rsp_bits_dbID = '0;
    io_out_2_rx_rsp_bits_pCrdType = '0;
    io_out_2_rx_dat_valid = '0;
    io_out_2_rx_dat_bits_tgtID = '0;
    io_out_2_rx_dat_bits_srcID = '0;
    io_out_2_rx_dat_bits_txnID = '0;
    io_out_2_rx_dat_bits_homeNID = '0;
    io_out_2_rx_dat_bits_opcode = '0;
    io_out_2_rx_dat_bits_resp = '0;
    io_out_2_rx_dat_bits_dataSource = '0;
    io_out_2_rx_dat_bits_dbID = '0;
    io_out_2_rx_dat_bits_dataID = '0;
    io_out_2_rx_dat_bits_be = '0;
    io_out_2_rx_dat_bits_data = '0;
    io_out_2_rx_dat_bits_dataCheck = '0;
    io_out_2_rx_snp_valid = '0;
    io_out_2_rx_snp_bits_txnID = '0;
    io_out_2_rx_snp_bits_fwdNID = '0;
    io_out_2_rx_snp_bits_fwdTxnID = '0;
    io_out_2_rx_snp_bits_opcode = '0;
    io_out_2_rx_snp_bits_addr = '0;
    io_out_2_rx_snp_bits_doNotGoToSD = '0;
    io_out_2_rx_snp_bits_retToSrc = '0;
    io_out_3_tx_req_ready = '0;
    io_out_3_rx_rsp_valid = '0;
    io_out_3_rx_rsp_bits_tgtID = '0;
    io_out_3_rx_rsp_bits_srcID = '0;
    io_out_3_rx_rsp_bits_txnID = '0;
    io_out_3_rx_rsp_bits_opcode = '0;
    io_out_3_rx_rsp_bits_resp = '0;
    io_out_3_rx_rsp_bits_fwdState = '0;
    io_out_3_rx_rsp_bits_dbID = '0;
    io_out_3_rx_rsp_bits_pCrdType = '0;
    io_out_3_rx_dat_valid = '0;
    io_out_3_rx_dat_bits_tgtID = '0;
    io_out_3_rx_dat_bits_srcID = '0;
    io_out_3_rx_dat_bits_txnID = '0;
    io_out_3_rx_dat_bits_homeNID = '0;
    io_out_3_rx_dat_bits_opcode = '0;
    io_out_3_rx_dat_bits_resp = '0;
    io_out_3_rx_dat_bits_dataSource = '0;
    io_out_3_rx_dat_bits_dbID = '0;
    io_out_3_rx_dat_bits_dataID = '0;
    io_out_3_rx_dat_bits_be = '0;
    io_out_3_rx_dat_bits_data = '0;
    io_out_3_rx_dat_bits_dataCheck = '0;
    io_out_3_rx_snp_valid = '0;
    io_out_3_rx_snp_bits_txnID = '0;
    io_out_3_rx_snp_bits_fwdNID = '0;
    io_out_3_rx_snp_bits_fwdTxnID = '0;
    io_out_3_rx_snp_bits_opcode = '0;
    io_out_3_rx_snp_bits_addr = '0;
    io_out_3_rx_snp_bits_doNotGoToSD = '0;
    io_out_3_rx_snp_bits_retToSrc = '0;
    io_snpMasks_0_0 = '0;
    io_snpMasks_1_0 = '0;
    io_snpMasks_2_0 = '0;
    io_snpMasks_3_0 = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("RNXbar checks=%0d pchecks=%0d errors=%0d", checks, pchecks, errors);
    if (errors == 0 && checks > 1000 && pchecks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
`undef PCHECK
