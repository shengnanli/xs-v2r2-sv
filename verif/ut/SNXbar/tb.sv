// 自动生成：scripts/gen_snxbar.py —— 勿手改
// SNXbar 双例化逐拍比对: golden SNXbar vs 可读 SNXbar_xs。
// 激励: 4 主口 TXREQ/TXDAT valid+载荷全随机 (覆盖两个 FastArbiter 的 4 路争用);
//       out 的 RXRSP/RXDAT valid+txnID 全随机 (txnID 全宽随机 ⇒ [10:9] 均匀覆盖
//       0..3 四条回程解复用路由); out 的 tx_*_ready/rx_* 随机背压。
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

  logic io_in_0_tx_req_valid;
  logic [10:0] io_in_0_tx_req_bits_tgtID;
  logic [10:0] io_in_0_tx_req_bits_srcID;
  logic [11:0] io_in_0_tx_req_bits_txnID;
  logic [6:0] io_in_0_tx_req_bits_opcode;
  logic [2:0] io_in_0_tx_req_bits_size;
  logic [47:0] io_in_0_tx_req_bits_addr;
  logic io_in_0_tx_req_bits_allowRetry;
  logic [1:0] io_in_0_tx_req_bits_order;
  logic [3:0] io_in_0_tx_req_bits_pCrdType;
  logic io_in_0_tx_req_bits_memAttr_allocate;
  logic io_in_0_tx_req_bits_memAttr_cacheable;
  logic io_in_0_tx_req_bits_memAttr_device;
  logic io_in_0_tx_req_bits_memAttr_ewa;
  logic io_in_0_tx_req_bits_snpAttr;
  logic io_in_0_tx_req_bits_expCompAck;
  logic io_in_0_tx_dat_valid;
  logic [10:0] io_in_0_tx_dat_bits_tgtID;
  logic [10:0] io_in_0_tx_dat_bits_srcID;
  logic [11:0] io_in_0_tx_dat_bits_txnID;
  logic [10:0] io_in_0_tx_dat_bits_homeNID;
  logic [3:0] io_in_0_tx_dat_bits_opcode;
  logic [2:0] io_in_0_tx_dat_bits_resp;
  logic [3:0] io_in_0_tx_dat_bits_dataSource;
  logic [11:0] io_in_0_tx_dat_bits_dbID;
  logic [1:0] io_in_0_tx_dat_bits_dataID;
  logic [31:0] io_in_0_tx_dat_bits_be;
  logic [255:0] io_in_0_tx_dat_bits_data;
  logic [31:0] io_in_0_tx_dat_bits_dataCheck;
  logic io_in_1_tx_req_valid;
  logic [10:0] io_in_1_tx_req_bits_tgtID;
  logic [10:0] io_in_1_tx_req_bits_srcID;
  logic [11:0] io_in_1_tx_req_bits_txnID;
  logic [6:0] io_in_1_tx_req_bits_opcode;
  logic [2:0] io_in_1_tx_req_bits_size;
  logic [47:0] io_in_1_tx_req_bits_addr;
  logic io_in_1_tx_req_bits_allowRetry;
  logic [1:0] io_in_1_tx_req_bits_order;
  logic [3:0] io_in_1_tx_req_bits_pCrdType;
  logic io_in_1_tx_req_bits_memAttr_allocate;
  logic io_in_1_tx_req_bits_memAttr_cacheable;
  logic io_in_1_tx_req_bits_memAttr_device;
  logic io_in_1_tx_req_bits_memAttr_ewa;
  logic io_in_1_tx_req_bits_snpAttr;
  logic io_in_1_tx_req_bits_expCompAck;
  logic io_in_1_tx_dat_valid;
  logic [10:0] io_in_1_tx_dat_bits_tgtID;
  logic [10:0] io_in_1_tx_dat_bits_srcID;
  logic [11:0] io_in_1_tx_dat_bits_txnID;
  logic [10:0] io_in_1_tx_dat_bits_homeNID;
  logic [3:0] io_in_1_tx_dat_bits_opcode;
  logic [2:0] io_in_1_tx_dat_bits_resp;
  logic [3:0] io_in_1_tx_dat_bits_dataSource;
  logic [11:0] io_in_1_tx_dat_bits_dbID;
  logic [1:0] io_in_1_tx_dat_bits_dataID;
  logic [31:0] io_in_1_tx_dat_bits_be;
  logic [255:0] io_in_1_tx_dat_bits_data;
  logic [31:0] io_in_1_tx_dat_bits_dataCheck;
  logic io_in_2_tx_req_valid;
  logic [10:0] io_in_2_tx_req_bits_tgtID;
  logic [10:0] io_in_2_tx_req_bits_srcID;
  logic [11:0] io_in_2_tx_req_bits_txnID;
  logic [6:0] io_in_2_tx_req_bits_opcode;
  logic [2:0] io_in_2_tx_req_bits_size;
  logic [47:0] io_in_2_tx_req_bits_addr;
  logic io_in_2_tx_req_bits_allowRetry;
  logic [1:0] io_in_2_tx_req_bits_order;
  logic [3:0] io_in_2_tx_req_bits_pCrdType;
  logic io_in_2_tx_req_bits_memAttr_allocate;
  logic io_in_2_tx_req_bits_memAttr_cacheable;
  logic io_in_2_tx_req_bits_memAttr_device;
  logic io_in_2_tx_req_bits_memAttr_ewa;
  logic io_in_2_tx_req_bits_snpAttr;
  logic io_in_2_tx_req_bits_expCompAck;
  logic io_in_2_tx_dat_valid;
  logic [10:0] io_in_2_tx_dat_bits_tgtID;
  logic [10:0] io_in_2_tx_dat_bits_srcID;
  logic [11:0] io_in_2_tx_dat_bits_txnID;
  logic [10:0] io_in_2_tx_dat_bits_homeNID;
  logic [3:0] io_in_2_tx_dat_bits_opcode;
  logic [2:0] io_in_2_tx_dat_bits_resp;
  logic [3:0] io_in_2_tx_dat_bits_dataSource;
  logic [11:0] io_in_2_tx_dat_bits_dbID;
  logic [1:0] io_in_2_tx_dat_bits_dataID;
  logic [31:0] io_in_2_tx_dat_bits_be;
  logic [255:0] io_in_2_tx_dat_bits_data;
  logic [31:0] io_in_2_tx_dat_bits_dataCheck;
  logic io_in_3_tx_req_valid;
  logic [10:0] io_in_3_tx_req_bits_tgtID;
  logic [10:0] io_in_3_tx_req_bits_srcID;
  logic [11:0] io_in_3_tx_req_bits_txnID;
  logic [6:0] io_in_3_tx_req_bits_opcode;
  logic [2:0] io_in_3_tx_req_bits_size;
  logic [47:0] io_in_3_tx_req_bits_addr;
  logic io_in_3_tx_req_bits_allowRetry;
  logic [1:0] io_in_3_tx_req_bits_order;
  logic [3:0] io_in_3_tx_req_bits_pCrdType;
  logic io_in_3_tx_req_bits_memAttr_allocate;
  logic io_in_3_tx_req_bits_memAttr_cacheable;
  logic io_in_3_tx_req_bits_memAttr_device;
  logic io_in_3_tx_req_bits_memAttr_ewa;
  logic io_in_3_tx_req_bits_snpAttr;
  logic io_in_3_tx_req_bits_expCompAck;
  logic io_in_3_tx_dat_valid;
  logic [10:0] io_in_3_tx_dat_bits_tgtID;
  logic [10:0] io_in_3_tx_dat_bits_srcID;
  logic [11:0] io_in_3_tx_dat_bits_txnID;
  logic [10:0] io_in_3_tx_dat_bits_homeNID;
  logic [3:0] io_in_3_tx_dat_bits_opcode;
  logic [2:0] io_in_3_tx_dat_bits_resp;
  logic [3:0] io_in_3_tx_dat_bits_dataSource;
  logic [11:0] io_in_3_tx_dat_bits_dbID;
  logic [1:0] io_in_3_tx_dat_bits_dataID;
  logic [31:0] io_in_3_tx_dat_bits_be;
  logic [255:0] io_in_3_tx_dat_bits_data;
  logic [31:0] io_in_3_tx_dat_bits_dataCheck;
  logic io_out_tx_req_ready;
  logic io_out_tx_dat_ready;
  logic io_out_rx_rsp_valid;
  logic [10:0] io_out_rx_rsp_bits_srcID;
  logic [11:0] io_out_rx_rsp_bits_txnID;
  logic [4:0] io_out_rx_rsp_bits_opcode;
  logic [11:0] io_out_rx_rsp_bits_dbID;
  logic io_out_rx_dat_valid;
  logic [10:0] io_out_rx_dat_bits_srcID;
  logic [11:0] io_out_rx_dat_bits_txnID;
  logic [3:0] io_out_rx_dat_bits_opcode;
  logic [2:0] io_out_rx_dat_bits_resp;
  logic [1:0] io_out_rx_dat_bits_dataID;
  logic [255:0] io_out_rx_dat_bits_data;
  wire g_io_in_0_tx_req_ready;
  wire i_io_in_0_tx_req_ready;
  wire g_io_in_0_tx_dat_ready;
  wire i_io_in_0_tx_dat_ready;
  wire g_io_in_0_rx_rsp_valid;
  wire i_io_in_0_rx_rsp_valid;
  wire [10:0] g_io_in_0_rx_rsp_bits_srcID;
  wire [10:0] i_io_in_0_rx_rsp_bits_srcID;
  wire [11:0] g_io_in_0_rx_rsp_bits_txnID;
  wire [11:0] i_io_in_0_rx_rsp_bits_txnID;
  wire [4:0] g_io_in_0_rx_rsp_bits_opcode;
  wire [4:0] i_io_in_0_rx_rsp_bits_opcode;
  wire [11:0] g_io_in_0_rx_rsp_bits_dbID;
  wire [11:0] i_io_in_0_rx_rsp_bits_dbID;
  wire g_io_in_0_rx_dat_valid;
  wire i_io_in_0_rx_dat_valid;
  wire [10:0] g_io_in_0_rx_dat_bits_srcID;
  wire [10:0] i_io_in_0_rx_dat_bits_srcID;
  wire [11:0] g_io_in_0_rx_dat_bits_txnID;
  wire [11:0] i_io_in_0_rx_dat_bits_txnID;
  wire [3:0] g_io_in_0_rx_dat_bits_opcode;
  wire [3:0] i_io_in_0_rx_dat_bits_opcode;
  wire [2:0] g_io_in_0_rx_dat_bits_resp;
  wire [2:0] i_io_in_0_rx_dat_bits_resp;
  wire [1:0] g_io_in_0_rx_dat_bits_dataID;
  wire [1:0] i_io_in_0_rx_dat_bits_dataID;
  wire [255:0] g_io_in_0_rx_dat_bits_data;
  wire [255:0] i_io_in_0_rx_dat_bits_data;
  wire g_io_in_1_tx_req_ready;
  wire i_io_in_1_tx_req_ready;
  wire g_io_in_1_tx_dat_ready;
  wire i_io_in_1_tx_dat_ready;
  wire g_io_in_1_rx_rsp_valid;
  wire i_io_in_1_rx_rsp_valid;
  wire [10:0] g_io_in_1_rx_rsp_bits_srcID;
  wire [10:0] i_io_in_1_rx_rsp_bits_srcID;
  wire [11:0] g_io_in_1_rx_rsp_bits_txnID;
  wire [11:0] i_io_in_1_rx_rsp_bits_txnID;
  wire [4:0] g_io_in_1_rx_rsp_bits_opcode;
  wire [4:0] i_io_in_1_rx_rsp_bits_opcode;
  wire [11:0] g_io_in_1_rx_rsp_bits_dbID;
  wire [11:0] i_io_in_1_rx_rsp_bits_dbID;
  wire g_io_in_1_rx_dat_valid;
  wire i_io_in_1_rx_dat_valid;
  wire [10:0] g_io_in_1_rx_dat_bits_srcID;
  wire [10:0] i_io_in_1_rx_dat_bits_srcID;
  wire [11:0] g_io_in_1_rx_dat_bits_txnID;
  wire [11:0] i_io_in_1_rx_dat_bits_txnID;
  wire [3:0] g_io_in_1_rx_dat_bits_opcode;
  wire [3:0] i_io_in_1_rx_dat_bits_opcode;
  wire [2:0] g_io_in_1_rx_dat_bits_resp;
  wire [2:0] i_io_in_1_rx_dat_bits_resp;
  wire [1:0] g_io_in_1_rx_dat_bits_dataID;
  wire [1:0] i_io_in_1_rx_dat_bits_dataID;
  wire [255:0] g_io_in_1_rx_dat_bits_data;
  wire [255:0] i_io_in_1_rx_dat_bits_data;
  wire g_io_in_2_tx_req_ready;
  wire i_io_in_2_tx_req_ready;
  wire g_io_in_2_tx_dat_ready;
  wire i_io_in_2_tx_dat_ready;
  wire g_io_in_2_rx_rsp_valid;
  wire i_io_in_2_rx_rsp_valid;
  wire [10:0] g_io_in_2_rx_rsp_bits_srcID;
  wire [10:0] i_io_in_2_rx_rsp_bits_srcID;
  wire [11:0] g_io_in_2_rx_rsp_bits_txnID;
  wire [11:0] i_io_in_2_rx_rsp_bits_txnID;
  wire [4:0] g_io_in_2_rx_rsp_bits_opcode;
  wire [4:0] i_io_in_2_rx_rsp_bits_opcode;
  wire [11:0] g_io_in_2_rx_rsp_bits_dbID;
  wire [11:0] i_io_in_2_rx_rsp_bits_dbID;
  wire g_io_in_2_rx_dat_valid;
  wire i_io_in_2_rx_dat_valid;
  wire [10:0] g_io_in_2_rx_dat_bits_srcID;
  wire [10:0] i_io_in_2_rx_dat_bits_srcID;
  wire [11:0] g_io_in_2_rx_dat_bits_txnID;
  wire [11:0] i_io_in_2_rx_dat_bits_txnID;
  wire [3:0] g_io_in_2_rx_dat_bits_opcode;
  wire [3:0] i_io_in_2_rx_dat_bits_opcode;
  wire [2:0] g_io_in_2_rx_dat_bits_resp;
  wire [2:0] i_io_in_2_rx_dat_bits_resp;
  wire [1:0] g_io_in_2_rx_dat_bits_dataID;
  wire [1:0] i_io_in_2_rx_dat_bits_dataID;
  wire [255:0] g_io_in_2_rx_dat_bits_data;
  wire [255:0] i_io_in_2_rx_dat_bits_data;
  wire g_io_in_3_tx_req_ready;
  wire i_io_in_3_tx_req_ready;
  wire g_io_in_3_tx_dat_ready;
  wire i_io_in_3_tx_dat_ready;
  wire g_io_in_3_rx_rsp_valid;
  wire i_io_in_3_rx_rsp_valid;
  wire [10:0] g_io_in_3_rx_rsp_bits_srcID;
  wire [10:0] i_io_in_3_rx_rsp_bits_srcID;
  wire [11:0] g_io_in_3_rx_rsp_bits_txnID;
  wire [11:0] i_io_in_3_rx_rsp_bits_txnID;
  wire [4:0] g_io_in_3_rx_rsp_bits_opcode;
  wire [4:0] i_io_in_3_rx_rsp_bits_opcode;
  wire [11:0] g_io_in_3_rx_rsp_bits_dbID;
  wire [11:0] i_io_in_3_rx_rsp_bits_dbID;
  wire g_io_in_3_rx_dat_valid;
  wire i_io_in_3_rx_dat_valid;
  wire [10:0] g_io_in_3_rx_dat_bits_srcID;
  wire [10:0] i_io_in_3_rx_dat_bits_srcID;
  wire [11:0] g_io_in_3_rx_dat_bits_txnID;
  wire [11:0] i_io_in_3_rx_dat_bits_txnID;
  wire [3:0] g_io_in_3_rx_dat_bits_opcode;
  wire [3:0] i_io_in_3_rx_dat_bits_opcode;
  wire [2:0] g_io_in_3_rx_dat_bits_resp;
  wire [2:0] i_io_in_3_rx_dat_bits_resp;
  wire [1:0] g_io_in_3_rx_dat_bits_dataID;
  wire [1:0] i_io_in_3_rx_dat_bits_dataID;
  wire [255:0] g_io_in_3_rx_dat_bits_data;
  wire [255:0] i_io_in_3_rx_dat_bits_data;
  wire g_io_out_tx_req_valid;
  wire i_io_out_tx_req_valid;
  wire [10:0] g_io_out_tx_req_bits_tgtID;
  wire [10:0] i_io_out_tx_req_bits_tgtID;
  wire [10:0] g_io_out_tx_req_bits_srcID;
  wire [10:0] i_io_out_tx_req_bits_srcID;
  wire [11:0] g_io_out_tx_req_bits_txnID;
  wire [11:0] i_io_out_tx_req_bits_txnID;
  wire [6:0] g_io_out_tx_req_bits_opcode;
  wire [6:0] i_io_out_tx_req_bits_opcode;
  wire [2:0] g_io_out_tx_req_bits_size;
  wire [2:0] i_io_out_tx_req_bits_size;
  wire [47:0] g_io_out_tx_req_bits_addr;
  wire [47:0] i_io_out_tx_req_bits_addr;
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
  wire g_io_out_tx_req_bits_expCompAck;
  wire i_io_out_tx_req_bits_expCompAck;
  wire g_io_out_tx_dat_valid;
  wire i_io_out_tx_dat_valid;
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
  wire [2:0] g_io_out_tx_dat_bits_resp;
  wire [2:0] i_io_out_tx_dat_bits_resp;
  wire [3:0] g_io_out_tx_dat_bits_dataSource;
  wire [3:0] i_io_out_tx_dat_bits_dataSource;
  wire [11:0] g_io_out_tx_dat_bits_dbID;
  wire [11:0] i_io_out_tx_dat_bits_dbID;
  wire [1:0] g_io_out_tx_dat_bits_dataID;
  wire [1:0] i_io_out_tx_dat_bits_dataID;
  wire [31:0] g_io_out_tx_dat_bits_be;
  wire [31:0] i_io_out_tx_dat_bits_be;
  wire [255:0] g_io_out_tx_dat_bits_data;
  wire [255:0] i_io_out_tx_dat_bits_data;
  wire [31:0] g_io_out_tx_dat_bits_dataCheck;
  wire [31:0] i_io_out_tx_dat_bits_dataCheck;
  wire g_io_out_rx_rsp_ready;
  wire i_io_out_rx_rsp_ready;
  wire g_io_out_rx_dat_ready;
  wire i_io_out_rx_dat_ready;

  SNXbar u_g (
    .clock(clock),
    .reset(reset),
    .io_in_0_tx_req_ready(g_io_in_0_tx_req_ready),
    .io_in_0_tx_req_valid(io_in_0_tx_req_valid),
    .io_in_0_tx_req_bits_tgtID(io_in_0_tx_req_bits_tgtID),
    .io_in_0_tx_req_bits_srcID(io_in_0_tx_req_bits_srcID),
    .io_in_0_tx_req_bits_txnID(io_in_0_tx_req_bits_txnID),
    .io_in_0_tx_req_bits_opcode(io_in_0_tx_req_bits_opcode),
    .io_in_0_tx_req_bits_size(io_in_0_tx_req_bits_size),
    .io_in_0_tx_req_bits_addr(io_in_0_tx_req_bits_addr),
    .io_in_0_tx_req_bits_allowRetry(io_in_0_tx_req_bits_allowRetry),
    .io_in_0_tx_req_bits_order(io_in_0_tx_req_bits_order),
    .io_in_0_tx_req_bits_pCrdType(io_in_0_tx_req_bits_pCrdType),
    .io_in_0_tx_req_bits_memAttr_allocate(io_in_0_tx_req_bits_memAttr_allocate),
    .io_in_0_tx_req_bits_memAttr_cacheable(io_in_0_tx_req_bits_memAttr_cacheable),
    .io_in_0_tx_req_bits_memAttr_device(io_in_0_tx_req_bits_memAttr_device),
    .io_in_0_tx_req_bits_memAttr_ewa(io_in_0_tx_req_bits_memAttr_ewa),
    .io_in_0_tx_req_bits_snpAttr(io_in_0_tx_req_bits_snpAttr),
    .io_in_0_tx_req_bits_expCompAck(io_in_0_tx_req_bits_expCompAck),
    .io_in_0_tx_dat_ready(g_io_in_0_tx_dat_ready),
    .io_in_0_tx_dat_valid(io_in_0_tx_dat_valid),
    .io_in_0_tx_dat_bits_tgtID(io_in_0_tx_dat_bits_tgtID),
    .io_in_0_tx_dat_bits_srcID(io_in_0_tx_dat_bits_srcID),
    .io_in_0_tx_dat_bits_txnID(io_in_0_tx_dat_bits_txnID),
    .io_in_0_tx_dat_bits_homeNID(io_in_0_tx_dat_bits_homeNID),
    .io_in_0_tx_dat_bits_opcode(io_in_0_tx_dat_bits_opcode),
    .io_in_0_tx_dat_bits_resp(io_in_0_tx_dat_bits_resp),
    .io_in_0_tx_dat_bits_dataSource(io_in_0_tx_dat_bits_dataSource),
    .io_in_0_tx_dat_bits_dbID(io_in_0_tx_dat_bits_dbID),
    .io_in_0_tx_dat_bits_dataID(io_in_0_tx_dat_bits_dataID),
    .io_in_0_tx_dat_bits_be(io_in_0_tx_dat_bits_be),
    .io_in_0_tx_dat_bits_data(io_in_0_tx_dat_bits_data),
    .io_in_0_tx_dat_bits_dataCheck(io_in_0_tx_dat_bits_dataCheck),
    .io_in_0_rx_rsp_valid(g_io_in_0_rx_rsp_valid),
    .io_in_0_rx_rsp_bits_srcID(g_io_in_0_rx_rsp_bits_srcID),
    .io_in_0_rx_rsp_bits_txnID(g_io_in_0_rx_rsp_bits_txnID),
    .io_in_0_rx_rsp_bits_opcode(g_io_in_0_rx_rsp_bits_opcode),
    .io_in_0_rx_rsp_bits_dbID(g_io_in_0_rx_rsp_bits_dbID),
    .io_in_0_rx_dat_valid(g_io_in_0_rx_dat_valid),
    .io_in_0_rx_dat_bits_srcID(g_io_in_0_rx_dat_bits_srcID),
    .io_in_0_rx_dat_bits_txnID(g_io_in_0_rx_dat_bits_txnID),
    .io_in_0_rx_dat_bits_opcode(g_io_in_0_rx_dat_bits_opcode),
    .io_in_0_rx_dat_bits_resp(g_io_in_0_rx_dat_bits_resp),
    .io_in_0_rx_dat_bits_dataID(g_io_in_0_rx_dat_bits_dataID),
    .io_in_0_rx_dat_bits_data(g_io_in_0_rx_dat_bits_data),
    .io_in_1_tx_req_ready(g_io_in_1_tx_req_ready),
    .io_in_1_tx_req_valid(io_in_1_tx_req_valid),
    .io_in_1_tx_req_bits_tgtID(io_in_1_tx_req_bits_tgtID),
    .io_in_1_tx_req_bits_srcID(io_in_1_tx_req_bits_srcID),
    .io_in_1_tx_req_bits_txnID(io_in_1_tx_req_bits_txnID),
    .io_in_1_tx_req_bits_opcode(io_in_1_tx_req_bits_opcode),
    .io_in_1_tx_req_bits_size(io_in_1_tx_req_bits_size),
    .io_in_1_tx_req_bits_addr(io_in_1_tx_req_bits_addr),
    .io_in_1_tx_req_bits_allowRetry(io_in_1_tx_req_bits_allowRetry),
    .io_in_1_tx_req_bits_order(io_in_1_tx_req_bits_order),
    .io_in_1_tx_req_bits_pCrdType(io_in_1_tx_req_bits_pCrdType),
    .io_in_1_tx_req_bits_memAttr_allocate(io_in_1_tx_req_bits_memAttr_allocate),
    .io_in_1_tx_req_bits_memAttr_cacheable(io_in_1_tx_req_bits_memAttr_cacheable),
    .io_in_1_tx_req_bits_memAttr_device(io_in_1_tx_req_bits_memAttr_device),
    .io_in_1_tx_req_bits_memAttr_ewa(io_in_1_tx_req_bits_memAttr_ewa),
    .io_in_1_tx_req_bits_snpAttr(io_in_1_tx_req_bits_snpAttr),
    .io_in_1_tx_req_bits_expCompAck(io_in_1_tx_req_bits_expCompAck),
    .io_in_1_tx_dat_ready(g_io_in_1_tx_dat_ready),
    .io_in_1_tx_dat_valid(io_in_1_tx_dat_valid),
    .io_in_1_tx_dat_bits_tgtID(io_in_1_tx_dat_bits_tgtID),
    .io_in_1_tx_dat_bits_srcID(io_in_1_tx_dat_bits_srcID),
    .io_in_1_tx_dat_bits_txnID(io_in_1_tx_dat_bits_txnID),
    .io_in_1_tx_dat_bits_homeNID(io_in_1_tx_dat_bits_homeNID),
    .io_in_1_tx_dat_bits_opcode(io_in_1_tx_dat_bits_opcode),
    .io_in_1_tx_dat_bits_resp(io_in_1_tx_dat_bits_resp),
    .io_in_1_tx_dat_bits_dataSource(io_in_1_tx_dat_bits_dataSource),
    .io_in_1_tx_dat_bits_dbID(io_in_1_tx_dat_bits_dbID),
    .io_in_1_tx_dat_bits_dataID(io_in_1_tx_dat_bits_dataID),
    .io_in_1_tx_dat_bits_be(io_in_1_tx_dat_bits_be),
    .io_in_1_tx_dat_bits_data(io_in_1_tx_dat_bits_data),
    .io_in_1_tx_dat_bits_dataCheck(io_in_1_tx_dat_bits_dataCheck),
    .io_in_1_rx_rsp_valid(g_io_in_1_rx_rsp_valid),
    .io_in_1_rx_rsp_bits_srcID(g_io_in_1_rx_rsp_bits_srcID),
    .io_in_1_rx_rsp_bits_txnID(g_io_in_1_rx_rsp_bits_txnID),
    .io_in_1_rx_rsp_bits_opcode(g_io_in_1_rx_rsp_bits_opcode),
    .io_in_1_rx_rsp_bits_dbID(g_io_in_1_rx_rsp_bits_dbID),
    .io_in_1_rx_dat_valid(g_io_in_1_rx_dat_valid),
    .io_in_1_rx_dat_bits_srcID(g_io_in_1_rx_dat_bits_srcID),
    .io_in_1_rx_dat_bits_txnID(g_io_in_1_rx_dat_bits_txnID),
    .io_in_1_rx_dat_bits_opcode(g_io_in_1_rx_dat_bits_opcode),
    .io_in_1_rx_dat_bits_resp(g_io_in_1_rx_dat_bits_resp),
    .io_in_1_rx_dat_bits_dataID(g_io_in_1_rx_dat_bits_dataID),
    .io_in_1_rx_dat_bits_data(g_io_in_1_rx_dat_bits_data),
    .io_in_2_tx_req_ready(g_io_in_2_tx_req_ready),
    .io_in_2_tx_req_valid(io_in_2_tx_req_valid),
    .io_in_2_tx_req_bits_tgtID(io_in_2_tx_req_bits_tgtID),
    .io_in_2_tx_req_bits_srcID(io_in_2_tx_req_bits_srcID),
    .io_in_2_tx_req_bits_txnID(io_in_2_tx_req_bits_txnID),
    .io_in_2_tx_req_bits_opcode(io_in_2_tx_req_bits_opcode),
    .io_in_2_tx_req_bits_size(io_in_2_tx_req_bits_size),
    .io_in_2_tx_req_bits_addr(io_in_2_tx_req_bits_addr),
    .io_in_2_tx_req_bits_allowRetry(io_in_2_tx_req_bits_allowRetry),
    .io_in_2_tx_req_bits_order(io_in_2_tx_req_bits_order),
    .io_in_2_tx_req_bits_pCrdType(io_in_2_tx_req_bits_pCrdType),
    .io_in_2_tx_req_bits_memAttr_allocate(io_in_2_tx_req_bits_memAttr_allocate),
    .io_in_2_tx_req_bits_memAttr_cacheable(io_in_2_tx_req_bits_memAttr_cacheable),
    .io_in_2_tx_req_bits_memAttr_device(io_in_2_tx_req_bits_memAttr_device),
    .io_in_2_tx_req_bits_memAttr_ewa(io_in_2_tx_req_bits_memAttr_ewa),
    .io_in_2_tx_req_bits_snpAttr(io_in_2_tx_req_bits_snpAttr),
    .io_in_2_tx_req_bits_expCompAck(io_in_2_tx_req_bits_expCompAck),
    .io_in_2_tx_dat_ready(g_io_in_2_tx_dat_ready),
    .io_in_2_tx_dat_valid(io_in_2_tx_dat_valid),
    .io_in_2_tx_dat_bits_tgtID(io_in_2_tx_dat_bits_tgtID),
    .io_in_2_tx_dat_bits_srcID(io_in_2_tx_dat_bits_srcID),
    .io_in_2_tx_dat_bits_txnID(io_in_2_tx_dat_bits_txnID),
    .io_in_2_tx_dat_bits_homeNID(io_in_2_tx_dat_bits_homeNID),
    .io_in_2_tx_dat_bits_opcode(io_in_2_tx_dat_bits_opcode),
    .io_in_2_tx_dat_bits_resp(io_in_2_tx_dat_bits_resp),
    .io_in_2_tx_dat_bits_dataSource(io_in_2_tx_dat_bits_dataSource),
    .io_in_2_tx_dat_bits_dbID(io_in_2_tx_dat_bits_dbID),
    .io_in_2_tx_dat_bits_dataID(io_in_2_tx_dat_bits_dataID),
    .io_in_2_tx_dat_bits_be(io_in_2_tx_dat_bits_be),
    .io_in_2_tx_dat_bits_data(io_in_2_tx_dat_bits_data),
    .io_in_2_tx_dat_bits_dataCheck(io_in_2_tx_dat_bits_dataCheck),
    .io_in_2_rx_rsp_valid(g_io_in_2_rx_rsp_valid),
    .io_in_2_rx_rsp_bits_srcID(g_io_in_2_rx_rsp_bits_srcID),
    .io_in_2_rx_rsp_bits_txnID(g_io_in_2_rx_rsp_bits_txnID),
    .io_in_2_rx_rsp_bits_opcode(g_io_in_2_rx_rsp_bits_opcode),
    .io_in_2_rx_rsp_bits_dbID(g_io_in_2_rx_rsp_bits_dbID),
    .io_in_2_rx_dat_valid(g_io_in_2_rx_dat_valid),
    .io_in_2_rx_dat_bits_srcID(g_io_in_2_rx_dat_bits_srcID),
    .io_in_2_rx_dat_bits_txnID(g_io_in_2_rx_dat_bits_txnID),
    .io_in_2_rx_dat_bits_opcode(g_io_in_2_rx_dat_bits_opcode),
    .io_in_2_rx_dat_bits_resp(g_io_in_2_rx_dat_bits_resp),
    .io_in_2_rx_dat_bits_dataID(g_io_in_2_rx_dat_bits_dataID),
    .io_in_2_rx_dat_bits_data(g_io_in_2_rx_dat_bits_data),
    .io_in_3_tx_req_ready(g_io_in_3_tx_req_ready),
    .io_in_3_tx_req_valid(io_in_3_tx_req_valid),
    .io_in_3_tx_req_bits_tgtID(io_in_3_tx_req_bits_tgtID),
    .io_in_3_tx_req_bits_srcID(io_in_3_tx_req_bits_srcID),
    .io_in_3_tx_req_bits_txnID(io_in_3_tx_req_bits_txnID),
    .io_in_3_tx_req_bits_opcode(io_in_3_tx_req_bits_opcode),
    .io_in_3_tx_req_bits_size(io_in_3_tx_req_bits_size),
    .io_in_3_tx_req_bits_addr(io_in_3_tx_req_bits_addr),
    .io_in_3_tx_req_bits_allowRetry(io_in_3_tx_req_bits_allowRetry),
    .io_in_3_tx_req_bits_order(io_in_3_tx_req_bits_order),
    .io_in_3_tx_req_bits_pCrdType(io_in_3_tx_req_bits_pCrdType),
    .io_in_3_tx_req_bits_memAttr_allocate(io_in_3_tx_req_bits_memAttr_allocate),
    .io_in_3_tx_req_bits_memAttr_cacheable(io_in_3_tx_req_bits_memAttr_cacheable),
    .io_in_3_tx_req_bits_memAttr_device(io_in_3_tx_req_bits_memAttr_device),
    .io_in_3_tx_req_bits_memAttr_ewa(io_in_3_tx_req_bits_memAttr_ewa),
    .io_in_3_tx_req_bits_snpAttr(io_in_3_tx_req_bits_snpAttr),
    .io_in_3_tx_req_bits_expCompAck(io_in_3_tx_req_bits_expCompAck),
    .io_in_3_tx_dat_ready(g_io_in_3_tx_dat_ready),
    .io_in_3_tx_dat_valid(io_in_3_tx_dat_valid),
    .io_in_3_tx_dat_bits_tgtID(io_in_3_tx_dat_bits_tgtID),
    .io_in_3_tx_dat_bits_srcID(io_in_3_tx_dat_bits_srcID),
    .io_in_3_tx_dat_bits_txnID(io_in_3_tx_dat_bits_txnID),
    .io_in_3_tx_dat_bits_homeNID(io_in_3_tx_dat_bits_homeNID),
    .io_in_3_tx_dat_bits_opcode(io_in_3_tx_dat_bits_opcode),
    .io_in_3_tx_dat_bits_resp(io_in_3_tx_dat_bits_resp),
    .io_in_3_tx_dat_bits_dataSource(io_in_3_tx_dat_bits_dataSource),
    .io_in_3_tx_dat_bits_dbID(io_in_3_tx_dat_bits_dbID),
    .io_in_3_tx_dat_bits_dataID(io_in_3_tx_dat_bits_dataID),
    .io_in_3_tx_dat_bits_be(io_in_3_tx_dat_bits_be),
    .io_in_3_tx_dat_bits_data(io_in_3_tx_dat_bits_data),
    .io_in_3_tx_dat_bits_dataCheck(io_in_3_tx_dat_bits_dataCheck),
    .io_in_3_rx_rsp_valid(g_io_in_3_rx_rsp_valid),
    .io_in_3_rx_rsp_bits_srcID(g_io_in_3_rx_rsp_bits_srcID),
    .io_in_3_rx_rsp_bits_txnID(g_io_in_3_rx_rsp_bits_txnID),
    .io_in_3_rx_rsp_bits_opcode(g_io_in_3_rx_rsp_bits_opcode),
    .io_in_3_rx_rsp_bits_dbID(g_io_in_3_rx_rsp_bits_dbID),
    .io_in_3_rx_dat_valid(g_io_in_3_rx_dat_valid),
    .io_in_3_rx_dat_bits_srcID(g_io_in_3_rx_dat_bits_srcID),
    .io_in_3_rx_dat_bits_txnID(g_io_in_3_rx_dat_bits_txnID),
    .io_in_3_rx_dat_bits_opcode(g_io_in_3_rx_dat_bits_opcode),
    .io_in_3_rx_dat_bits_resp(g_io_in_3_rx_dat_bits_resp),
    .io_in_3_rx_dat_bits_dataID(g_io_in_3_rx_dat_bits_dataID),
    .io_in_3_rx_dat_bits_data(g_io_in_3_rx_dat_bits_data),
    .io_out_tx_req_ready(io_out_tx_req_ready),
    .io_out_tx_req_valid(g_io_out_tx_req_valid),
    .io_out_tx_req_bits_tgtID(g_io_out_tx_req_bits_tgtID),
    .io_out_tx_req_bits_srcID(g_io_out_tx_req_bits_srcID),
    .io_out_tx_req_bits_txnID(g_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_opcode(g_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_size(g_io_out_tx_req_bits_size),
    .io_out_tx_req_bits_addr(g_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_allowRetry(g_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order(g_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType(g_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate(g_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable(g_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device(g_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa(g_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr(g_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_expCompAck(g_io_out_tx_req_bits_expCompAck),
    .io_out_tx_dat_ready(io_out_tx_dat_ready),
    .io_out_tx_dat_valid(g_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID(g_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_srcID(g_io_out_tx_dat_bits_srcID),
    .io_out_tx_dat_bits_txnID(g_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID(g_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode(g_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_resp(g_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource(g_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID(g_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_dataID(g_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_be(g_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data(g_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck(g_io_out_tx_dat_bits_dataCheck),
    .io_out_rx_rsp_ready(g_io_out_rx_rsp_ready),
    .io_out_rx_rsp_valid(io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID(io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID(io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode(io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_dbID(io_out_rx_rsp_bits_dbID),
    .io_out_rx_dat_ready(g_io_out_rx_dat_ready),
    .io_out_rx_dat_valid(io_out_rx_dat_valid),
    .io_out_rx_dat_bits_srcID(io_out_rx_dat_bits_srcID),
    .io_out_rx_dat_bits_txnID(io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_opcode(io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_resp(io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dataID(io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_data(io_out_rx_dat_bits_data)
  );

  SNXbar_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_0_tx_req_ready(i_io_in_0_tx_req_ready),
    .io_in_0_tx_req_valid(io_in_0_tx_req_valid),
    .io_in_0_tx_req_bits_tgtID(io_in_0_tx_req_bits_tgtID),
    .io_in_0_tx_req_bits_srcID(io_in_0_tx_req_bits_srcID),
    .io_in_0_tx_req_bits_txnID(io_in_0_tx_req_bits_txnID),
    .io_in_0_tx_req_bits_opcode(io_in_0_tx_req_bits_opcode),
    .io_in_0_tx_req_bits_size(io_in_0_tx_req_bits_size),
    .io_in_0_tx_req_bits_addr(io_in_0_tx_req_bits_addr),
    .io_in_0_tx_req_bits_allowRetry(io_in_0_tx_req_bits_allowRetry),
    .io_in_0_tx_req_bits_order(io_in_0_tx_req_bits_order),
    .io_in_0_tx_req_bits_pCrdType(io_in_0_tx_req_bits_pCrdType),
    .io_in_0_tx_req_bits_memAttr_allocate(io_in_0_tx_req_bits_memAttr_allocate),
    .io_in_0_tx_req_bits_memAttr_cacheable(io_in_0_tx_req_bits_memAttr_cacheable),
    .io_in_0_tx_req_bits_memAttr_device(io_in_0_tx_req_bits_memAttr_device),
    .io_in_0_tx_req_bits_memAttr_ewa(io_in_0_tx_req_bits_memAttr_ewa),
    .io_in_0_tx_req_bits_snpAttr(io_in_0_tx_req_bits_snpAttr),
    .io_in_0_tx_req_bits_expCompAck(io_in_0_tx_req_bits_expCompAck),
    .io_in_0_tx_dat_ready(i_io_in_0_tx_dat_ready),
    .io_in_0_tx_dat_valid(io_in_0_tx_dat_valid),
    .io_in_0_tx_dat_bits_tgtID(io_in_0_tx_dat_bits_tgtID),
    .io_in_0_tx_dat_bits_srcID(io_in_0_tx_dat_bits_srcID),
    .io_in_0_tx_dat_bits_txnID(io_in_0_tx_dat_bits_txnID),
    .io_in_0_tx_dat_bits_homeNID(io_in_0_tx_dat_bits_homeNID),
    .io_in_0_tx_dat_bits_opcode(io_in_0_tx_dat_bits_opcode),
    .io_in_0_tx_dat_bits_resp(io_in_0_tx_dat_bits_resp),
    .io_in_0_tx_dat_bits_dataSource(io_in_0_tx_dat_bits_dataSource),
    .io_in_0_tx_dat_bits_dbID(io_in_0_tx_dat_bits_dbID),
    .io_in_0_tx_dat_bits_dataID(io_in_0_tx_dat_bits_dataID),
    .io_in_0_tx_dat_bits_be(io_in_0_tx_dat_bits_be),
    .io_in_0_tx_dat_bits_data(io_in_0_tx_dat_bits_data),
    .io_in_0_tx_dat_bits_dataCheck(io_in_0_tx_dat_bits_dataCheck),
    .io_in_0_rx_rsp_valid(i_io_in_0_rx_rsp_valid),
    .io_in_0_rx_rsp_bits_srcID(i_io_in_0_rx_rsp_bits_srcID),
    .io_in_0_rx_rsp_bits_txnID(i_io_in_0_rx_rsp_bits_txnID),
    .io_in_0_rx_rsp_bits_opcode(i_io_in_0_rx_rsp_bits_opcode),
    .io_in_0_rx_rsp_bits_dbID(i_io_in_0_rx_rsp_bits_dbID),
    .io_in_0_rx_dat_valid(i_io_in_0_rx_dat_valid),
    .io_in_0_rx_dat_bits_srcID(i_io_in_0_rx_dat_bits_srcID),
    .io_in_0_rx_dat_bits_txnID(i_io_in_0_rx_dat_bits_txnID),
    .io_in_0_rx_dat_bits_opcode(i_io_in_0_rx_dat_bits_opcode),
    .io_in_0_rx_dat_bits_resp(i_io_in_0_rx_dat_bits_resp),
    .io_in_0_rx_dat_bits_dataID(i_io_in_0_rx_dat_bits_dataID),
    .io_in_0_rx_dat_bits_data(i_io_in_0_rx_dat_bits_data),
    .io_in_1_tx_req_ready(i_io_in_1_tx_req_ready),
    .io_in_1_tx_req_valid(io_in_1_tx_req_valid),
    .io_in_1_tx_req_bits_tgtID(io_in_1_tx_req_bits_tgtID),
    .io_in_1_tx_req_bits_srcID(io_in_1_tx_req_bits_srcID),
    .io_in_1_tx_req_bits_txnID(io_in_1_tx_req_bits_txnID),
    .io_in_1_tx_req_bits_opcode(io_in_1_tx_req_bits_opcode),
    .io_in_1_tx_req_bits_size(io_in_1_tx_req_bits_size),
    .io_in_1_tx_req_bits_addr(io_in_1_tx_req_bits_addr),
    .io_in_1_tx_req_bits_allowRetry(io_in_1_tx_req_bits_allowRetry),
    .io_in_1_tx_req_bits_order(io_in_1_tx_req_bits_order),
    .io_in_1_tx_req_bits_pCrdType(io_in_1_tx_req_bits_pCrdType),
    .io_in_1_tx_req_bits_memAttr_allocate(io_in_1_tx_req_bits_memAttr_allocate),
    .io_in_1_tx_req_bits_memAttr_cacheable(io_in_1_tx_req_bits_memAttr_cacheable),
    .io_in_1_tx_req_bits_memAttr_device(io_in_1_tx_req_bits_memAttr_device),
    .io_in_1_tx_req_bits_memAttr_ewa(io_in_1_tx_req_bits_memAttr_ewa),
    .io_in_1_tx_req_bits_snpAttr(io_in_1_tx_req_bits_snpAttr),
    .io_in_1_tx_req_bits_expCompAck(io_in_1_tx_req_bits_expCompAck),
    .io_in_1_tx_dat_ready(i_io_in_1_tx_dat_ready),
    .io_in_1_tx_dat_valid(io_in_1_tx_dat_valid),
    .io_in_1_tx_dat_bits_tgtID(io_in_1_tx_dat_bits_tgtID),
    .io_in_1_tx_dat_bits_srcID(io_in_1_tx_dat_bits_srcID),
    .io_in_1_tx_dat_bits_txnID(io_in_1_tx_dat_bits_txnID),
    .io_in_1_tx_dat_bits_homeNID(io_in_1_tx_dat_bits_homeNID),
    .io_in_1_tx_dat_bits_opcode(io_in_1_tx_dat_bits_opcode),
    .io_in_1_tx_dat_bits_resp(io_in_1_tx_dat_bits_resp),
    .io_in_1_tx_dat_bits_dataSource(io_in_1_tx_dat_bits_dataSource),
    .io_in_1_tx_dat_bits_dbID(io_in_1_tx_dat_bits_dbID),
    .io_in_1_tx_dat_bits_dataID(io_in_1_tx_dat_bits_dataID),
    .io_in_1_tx_dat_bits_be(io_in_1_tx_dat_bits_be),
    .io_in_1_tx_dat_bits_data(io_in_1_tx_dat_bits_data),
    .io_in_1_tx_dat_bits_dataCheck(io_in_1_tx_dat_bits_dataCheck),
    .io_in_1_rx_rsp_valid(i_io_in_1_rx_rsp_valid),
    .io_in_1_rx_rsp_bits_srcID(i_io_in_1_rx_rsp_bits_srcID),
    .io_in_1_rx_rsp_bits_txnID(i_io_in_1_rx_rsp_bits_txnID),
    .io_in_1_rx_rsp_bits_opcode(i_io_in_1_rx_rsp_bits_opcode),
    .io_in_1_rx_rsp_bits_dbID(i_io_in_1_rx_rsp_bits_dbID),
    .io_in_1_rx_dat_valid(i_io_in_1_rx_dat_valid),
    .io_in_1_rx_dat_bits_srcID(i_io_in_1_rx_dat_bits_srcID),
    .io_in_1_rx_dat_bits_txnID(i_io_in_1_rx_dat_bits_txnID),
    .io_in_1_rx_dat_bits_opcode(i_io_in_1_rx_dat_bits_opcode),
    .io_in_1_rx_dat_bits_resp(i_io_in_1_rx_dat_bits_resp),
    .io_in_1_rx_dat_bits_dataID(i_io_in_1_rx_dat_bits_dataID),
    .io_in_1_rx_dat_bits_data(i_io_in_1_rx_dat_bits_data),
    .io_in_2_tx_req_ready(i_io_in_2_tx_req_ready),
    .io_in_2_tx_req_valid(io_in_2_tx_req_valid),
    .io_in_2_tx_req_bits_tgtID(io_in_2_tx_req_bits_tgtID),
    .io_in_2_tx_req_bits_srcID(io_in_2_tx_req_bits_srcID),
    .io_in_2_tx_req_bits_txnID(io_in_2_tx_req_bits_txnID),
    .io_in_2_tx_req_bits_opcode(io_in_2_tx_req_bits_opcode),
    .io_in_2_tx_req_bits_size(io_in_2_tx_req_bits_size),
    .io_in_2_tx_req_bits_addr(io_in_2_tx_req_bits_addr),
    .io_in_2_tx_req_bits_allowRetry(io_in_2_tx_req_bits_allowRetry),
    .io_in_2_tx_req_bits_order(io_in_2_tx_req_bits_order),
    .io_in_2_tx_req_bits_pCrdType(io_in_2_tx_req_bits_pCrdType),
    .io_in_2_tx_req_bits_memAttr_allocate(io_in_2_tx_req_bits_memAttr_allocate),
    .io_in_2_tx_req_bits_memAttr_cacheable(io_in_2_tx_req_bits_memAttr_cacheable),
    .io_in_2_tx_req_bits_memAttr_device(io_in_2_tx_req_bits_memAttr_device),
    .io_in_2_tx_req_bits_memAttr_ewa(io_in_2_tx_req_bits_memAttr_ewa),
    .io_in_2_tx_req_bits_snpAttr(io_in_2_tx_req_bits_snpAttr),
    .io_in_2_tx_req_bits_expCompAck(io_in_2_tx_req_bits_expCompAck),
    .io_in_2_tx_dat_ready(i_io_in_2_tx_dat_ready),
    .io_in_2_tx_dat_valid(io_in_2_tx_dat_valid),
    .io_in_2_tx_dat_bits_tgtID(io_in_2_tx_dat_bits_tgtID),
    .io_in_2_tx_dat_bits_srcID(io_in_2_tx_dat_bits_srcID),
    .io_in_2_tx_dat_bits_txnID(io_in_2_tx_dat_bits_txnID),
    .io_in_2_tx_dat_bits_homeNID(io_in_2_tx_dat_bits_homeNID),
    .io_in_2_tx_dat_bits_opcode(io_in_2_tx_dat_bits_opcode),
    .io_in_2_tx_dat_bits_resp(io_in_2_tx_dat_bits_resp),
    .io_in_2_tx_dat_bits_dataSource(io_in_2_tx_dat_bits_dataSource),
    .io_in_2_tx_dat_bits_dbID(io_in_2_tx_dat_bits_dbID),
    .io_in_2_tx_dat_bits_dataID(io_in_2_tx_dat_bits_dataID),
    .io_in_2_tx_dat_bits_be(io_in_2_tx_dat_bits_be),
    .io_in_2_tx_dat_bits_data(io_in_2_tx_dat_bits_data),
    .io_in_2_tx_dat_bits_dataCheck(io_in_2_tx_dat_bits_dataCheck),
    .io_in_2_rx_rsp_valid(i_io_in_2_rx_rsp_valid),
    .io_in_2_rx_rsp_bits_srcID(i_io_in_2_rx_rsp_bits_srcID),
    .io_in_2_rx_rsp_bits_txnID(i_io_in_2_rx_rsp_bits_txnID),
    .io_in_2_rx_rsp_bits_opcode(i_io_in_2_rx_rsp_bits_opcode),
    .io_in_2_rx_rsp_bits_dbID(i_io_in_2_rx_rsp_bits_dbID),
    .io_in_2_rx_dat_valid(i_io_in_2_rx_dat_valid),
    .io_in_2_rx_dat_bits_srcID(i_io_in_2_rx_dat_bits_srcID),
    .io_in_2_rx_dat_bits_txnID(i_io_in_2_rx_dat_bits_txnID),
    .io_in_2_rx_dat_bits_opcode(i_io_in_2_rx_dat_bits_opcode),
    .io_in_2_rx_dat_bits_resp(i_io_in_2_rx_dat_bits_resp),
    .io_in_2_rx_dat_bits_dataID(i_io_in_2_rx_dat_bits_dataID),
    .io_in_2_rx_dat_bits_data(i_io_in_2_rx_dat_bits_data),
    .io_in_3_tx_req_ready(i_io_in_3_tx_req_ready),
    .io_in_3_tx_req_valid(io_in_3_tx_req_valid),
    .io_in_3_tx_req_bits_tgtID(io_in_3_tx_req_bits_tgtID),
    .io_in_3_tx_req_bits_srcID(io_in_3_tx_req_bits_srcID),
    .io_in_3_tx_req_bits_txnID(io_in_3_tx_req_bits_txnID),
    .io_in_3_tx_req_bits_opcode(io_in_3_tx_req_bits_opcode),
    .io_in_3_tx_req_bits_size(io_in_3_tx_req_bits_size),
    .io_in_3_tx_req_bits_addr(io_in_3_tx_req_bits_addr),
    .io_in_3_tx_req_bits_allowRetry(io_in_3_tx_req_bits_allowRetry),
    .io_in_3_tx_req_bits_order(io_in_3_tx_req_bits_order),
    .io_in_3_tx_req_bits_pCrdType(io_in_3_tx_req_bits_pCrdType),
    .io_in_3_tx_req_bits_memAttr_allocate(io_in_3_tx_req_bits_memAttr_allocate),
    .io_in_3_tx_req_bits_memAttr_cacheable(io_in_3_tx_req_bits_memAttr_cacheable),
    .io_in_3_tx_req_bits_memAttr_device(io_in_3_tx_req_bits_memAttr_device),
    .io_in_3_tx_req_bits_memAttr_ewa(io_in_3_tx_req_bits_memAttr_ewa),
    .io_in_3_tx_req_bits_snpAttr(io_in_3_tx_req_bits_snpAttr),
    .io_in_3_tx_req_bits_expCompAck(io_in_3_tx_req_bits_expCompAck),
    .io_in_3_tx_dat_ready(i_io_in_3_tx_dat_ready),
    .io_in_3_tx_dat_valid(io_in_3_tx_dat_valid),
    .io_in_3_tx_dat_bits_tgtID(io_in_3_tx_dat_bits_tgtID),
    .io_in_3_tx_dat_bits_srcID(io_in_3_tx_dat_bits_srcID),
    .io_in_3_tx_dat_bits_txnID(io_in_3_tx_dat_bits_txnID),
    .io_in_3_tx_dat_bits_homeNID(io_in_3_tx_dat_bits_homeNID),
    .io_in_3_tx_dat_bits_opcode(io_in_3_tx_dat_bits_opcode),
    .io_in_3_tx_dat_bits_resp(io_in_3_tx_dat_bits_resp),
    .io_in_3_tx_dat_bits_dataSource(io_in_3_tx_dat_bits_dataSource),
    .io_in_3_tx_dat_bits_dbID(io_in_3_tx_dat_bits_dbID),
    .io_in_3_tx_dat_bits_dataID(io_in_3_tx_dat_bits_dataID),
    .io_in_3_tx_dat_bits_be(io_in_3_tx_dat_bits_be),
    .io_in_3_tx_dat_bits_data(io_in_3_tx_dat_bits_data),
    .io_in_3_tx_dat_bits_dataCheck(io_in_3_tx_dat_bits_dataCheck),
    .io_in_3_rx_rsp_valid(i_io_in_3_rx_rsp_valid),
    .io_in_3_rx_rsp_bits_srcID(i_io_in_3_rx_rsp_bits_srcID),
    .io_in_3_rx_rsp_bits_txnID(i_io_in_3_rx_rsp_bits_txnID),
    .io_in_3_rx_rsp_bits_opcode(i_io_in_3_rx_rsp_bits_opcode),
    .io_in_3_rx_rsp_bits_dbID(i_io_in_3_rx_rsp_bits_dbID),
    .io_in_3_rx_dat_valid(i_io_in_3_rx_dat_valid),
    .io_in_3_rx_dat_bits_srcID(i_io_in_3_rx_dat_bits_srcID),
    .io_in_3_rx_dat_bits_txnID(i_io_in_3_rx_dat_bits_txnID),
    .io_in_3_rx_dat_bits_opcode(i_io_in_3_rx_dat_bits_opcode),
    .io_in_3_rx_dat_bits_resp(i_io_in_3_rx_dat_bits_resp),
    .io_in_3_rx_dat_bits_dataID(i_io_in_3_rx_dat_bits_dataID),
    .io_in_3_rx_dat_bits_data(i_io_in_3_rx_dat_bits_data),
    .io_out_tx_req_ready(io_out_tx_req_ready),
    .io_out_tx_req_valid(i_io_out_tx_req_valid),
    .io_out_tx_req_bits_tgtID(i_io_out_tx_req_bits_tgtID),
    .io_out_tx_req_bits_srcID(i_io_out_tx_req_bits_srcID),
    .io_out_tx_req_bits_txnID(i_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_opcode(i_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_size(i_io_out_tx_req_bits_size),
    .io_out_tx_req_bits_addr(i_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_allowRetry(i_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order(i_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType(i_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate(i_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable(i_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device(i_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa(i_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr(i_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_expCompAck(i_io_out_tx_req_bits_expCompAck),
    .io_out_tx_dat_ready(io_out_tx_dat_ready),
    .io_out_tx_dat_valid(i_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID(i_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_srcID(i_io_out_tx_dat_bits_srcID),
    .io_out_tx_dat_bits_txnID(i_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID(i_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode(i_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_resp(i_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource(i_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID(i_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_dataID(i_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_be(i_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data(i_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck(i_io_out_tx_dat_bits_dataCheck),
    .io_out_rx_rsp_ready(i_io_out_rx_rsp_ready),
    .io_out_rx_rsp_valid(io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID(io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID(io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode(io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_dbID(io_out_rx_rsp_bits_dbID),
    .io_out_rx_dat_ready(i_io_out_rx_dat_ready),
    .io_out_rx_dat_valid(io_out_rx_dat_valid),
    .io_out_rx_dat_bits_srcID(io_out_rx_dat_bits_srcID),
    .io_out_rx_dat_bits_txnID(io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_opcode(io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_resp(io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dataID(io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_data(io_out_rx_dat_bits_data)
  );

  task automatic drive_random_inputs();
    io_in_0_tx_req_valid <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_tgtID <= 11'({$urandom});
    io_in_0_tx_req_bits_srcID <= 11'({$urandom});
    io_in_0_tx_req_bits_txnID <= 12'({$urandom});
    io_in_0_tx_req_bits_opcode <= 7'({$urandom});
    io_in_0_tx_req_bits_size <= 3'({$urandom});
    io_in_0_tx_req_bits_addr <= 48'({$urandom, $urandom});
    io_in_0_tx_req_bits_allowRetry <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_order <= 2'({$urandom});
    io_in_0_tx_req_bits_pCrdType <= 4'({$urandom});
    io_in_0_tx_req_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_snpAttr <= $urandom_range(0, 1);
    io_in_0_tx_req_bits_expCompAck <= $urandom_range(0, 1);
    io_in_0_tx_dat_valid <= $urandom_range(0, 1);
    io_in_0_tx_dat_bits_tgtID <= 11'({$urandom});
    io_in_0_tx_dat_bits_srcID <= 11'({$urandom});
    io_in_0_tx_dat_bits_txnID <= 12'({$urandom});
    io_in_0_tx_dat_bits_homeNID <= 11'({$urandom});
    io_in_0_tx_dat_bits_opcode <= 4'({$urandom});
    io_in_0_tx_dat_bits_resp <= 3'({$urandom});
    io_in_0_tx_dat_bits_dataSource <= 4'({$urandom});
    io_in_0_tx_dat_bits_dbID <= 12'({$urandom});
    io_in_0_tx_dat_bits_dataID <= 2'({$urandom});
    io_in_0_tx_dat_bits_be <= 32'({$urandom});
    io_in_0_tx_dat_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_0_tx_dat_bits_dataCheck <= 32'({$urandom});
    io_in_1_tx_req_valid <= $urandom_range(0, 1);
    io_in_1_tx_req_bits_tgtID <= 11'({$urandom});
    io_in_1_tx_req_bits_srcID <= 11'({$urandom});
    io_in_1_tx_req_bits_txnID <= 12'({$urandom});
    io_in_1_tx_req_bits_opcode <= 7'({$urandom});
    io_in_1_tx_req_bits_size <= 3'({$urandom});
    io_in_1_tx_req_bits_addr <= 48'({$urandom, $urandom});
    io_in_1_tx_req_bits_allowRetry <= $urandom_range(0, 1);
    io_in_1_tx_req_bits_order <= 2'({$urandom});
    io_in_1_tx_req_bits_pCrdType <= 4'({$urandom});
    io_in_1_tx_req_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_1_tx_req_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_1_tx_req_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_1_tx_req_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_1_tx_req_bits_snpAttr <= $urandom_range(0, 1);
    io_in_1_tx_req_bits_expCompAck <= $urandom_range(0, 1);
    io_in_1_tx_dat_valid <= $urandom_range(0, 1);
    io_in_1_tx_dat_bits_tgtID <= 11'({$urandom});
    io_in_1_tx_dat_bits_srcID <= 11'({$urandom});
    io_in_1_tx_dat_bits_txnID <= 12'({$urandom});
    io_in_1_tx_dat_bits_homeNID <= 11'({$urandom});
    io_in_1_tx_dat_bits_opcode <= 4'({$urandom});
    io_in_1_tx_dat_bits_resp <= 3'({$urandom});
    io_in_1_tx_dat_bits_dataSource <= 4'({$urandom});
    io_in_1_tx_dat_bits_dbID <= 12'({$urandom});
    io_in_1_tx_dat_bits_dataID <= 2'({$urandom});
    io_in_1_tx_dat_bits_be <= 32'({$urandom});
    io_in_1_tx_dat_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_1_tx_dat_bits_dataCheck <= 32'({$urandom});
    io_in_2_tx_req_valid <= $urandom_range(0, 1);
    io_in_2_tx_req_bits_tgtID <= 11'({$urandom});
    io_in_2_tx_req_bits_srcID <= 11'({$urandom});
    io_in_2_tx_req_bits_txnID <= 12'({$urandom});
    io_in_2_tx_req_bits_opcode <= 7'({$urandom});
    io_in_2_tx_req_bits_size <= 3'({$urandom});
    io_in_2_tx_req_bits_addr <= 48'({$urandom, $urandom});
    io_in_2_tx_req_bits_allowRetry <= $urandom_range(0, 1);
    io_in_2_tx_req_bits_order <= 2'({$urandom});
    io_in_2_tx_req_bits_pCrdType <= 4'({$urandom});
    io_in_2_tx_req_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_2_tx_req_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_2_tx_req_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_2_tx_req_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_2_tx_req_bits_snpAttr <= $urandom_range(0, 1);
    io_in_2_tx_req_bits_expCompAck <= $urandom_range(0, 1);
    io_in_2_tx_dat_valid <= $urandom_range(0, 1);
    io_in_2_tx_dat_bits_tgtID <= 11'({$urandom});
    io_in_2_tx_dat_bits_srcID <= 11'({$urandom});
    io_in_2_tx_dat_bits_txnID <= 12'({$urandom});
    io_in_2_tx_dat_bits_homeNID <= 11'({$urandom});
    io_in_2_tx_dat_bits_opcode <= 4'({$urandom});
    io_in_2_tx_dat_bits_resp <= 3'({$urandom});
    io_in_2_tx_dat_bits_dataSource <= 4'({$urandom});
    io_in_2_tx_dat_bits_dbID <= 12'({$urandom});
    io_in_2_tx_dat_bits_dataID <= 2'({$urandom});
    io_in_2_tx_dat_bits_be <= 32'({$urandom});
    io_in_2_tx_dat_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_2_tx_dat_bits_dataCheck <= 32'({$urandom});
    io_in_3_tx_req_valid <= $urandom_range(0, 1);
    io_in_3_tx_req_bits_tgtID <= 11'({$urandom});
    io_in_3_tx_req_bits_srcID <= 11'({$urandom});
    io_in_3_tx_req_bits_txnID <= 12'({$urandom});
    io_in_3_tx_req_bits_opcode <= 7'({$urandom});
    io_in_3_tx_req_bits_size <= 3'({$urandom});
    io_in_3_tx_req_bits_addr <= 48'({$urandom, $urandom});
    io_in_3_tx_req_bits_allowRetry <= $urandom_range(0, 1);
    io_in_3_tx_req_bits_order <= 2'({$urandom});
    io_in_3_tx_req_bits_pCrdType <= 4'({$urandom});
    io_in_3_tx_req_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_3_tx_req_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_3_tx_req_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_3_tx_req_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_3_tx_req_bits_snpAttr <= $urandom_range(0, 1);
    io_in_3_tx_req_bits_expCompAck <= $urandom_range(0, 1);
    io_in_3_tx_dat_valid <= $urandom_range(0, 1);
    io_in_3_tx_dat_bits_tgtID <= 11'({$urandom});
    io_in_3_tx_dat_bits_srcID <= 11'({$urandom});
    io_in_3_tx_dat_bits_txnID <= 12'({$urandom});
    io_in_3_tx_dat_bits_homeNID <= 11'({$urandom});
    io_in_3_tx_dat_bits_opcode <= 4'({$urandom});
    io_in_3_tx_dat_bits_resp <= 3'({$urandom});
    io_in_3_tx_dat_bits_dataSource <= 4'({$urandom});
    io_in_3_tx_dat_bits_dbID <= 12'({$urandom});
    io_in_3_tx_dat_bits_dataID <= 2'({$urandom});
    io_in_3_tx_dat_bits_be <= 32'({$urandom});
    io_in_3_tx_dat_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_3_tx_dat_bits_dataCheck <= 32'({$urandom});
    io_out_tx_req_ready <= $urandom_range(0, 1);
    io_out_tx_dat_ready <= $urandom_range(0, 1);
    io_out_rx_rsp_valid <= $urandom_range(0, 1);
    io_out_rx_rsp_bits_srcID <= 11'({$urandom});
    io_out_rx_rsp_bits_txnID <= 12'({$urandom});
    io_out_rx_rsp_bits_opcode <= 5'({$urandom});
    io_out_rx_rsp_bits_dbID <= 12'({$urandom});
    io_out_rx_dat_valid <= $urandom_range(0, 1);
    io_out_rx_dat_bits_srcID <= 11'({$urandom});
    io_out_rx_dat_bits_txnID <= 12'({$urandom});
    io_out_rx_dat_bits_opcode <= 4'({$urandom});
    io_out_rx_dat_bits_resp <= 3'({$urandom});
    io_out_rx_dat_bits_dataID <= 2'({$urandom});
    io_out_rx_dat_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
  endtask

  task automatic check_outputs();
    `CHECK(io_in_0_tx_req_ready)
    `CHECK(io_in_0_tx_dat_ready)
    `CHECK(io_in_0_rx_rsp_valid)
    `CHECK(io_in_0_rx_rsp_bits_srcID)
    `CHECK(io_in_0_rx_rsp_bits_txnID)
    `CHECK(io_in_0_rx_rsp_bits_opcode)
    `CHECK(io_in_0_rx_rsp_bits_dbID)
    `CHECK(io_in_0_rx_dat_valid)
    `CHECK(io_in_0_rx_dat_bits_srcID)
    `CHECK(io_in_0_rx_dat_bits_txnID)
    `CHECK(io_in_0_rx_dat_bits_opcode)
    `CHECK(io_in_0_rx_dat_bits_resp)
    `CHECK(io_in_0_rx_dat_bits_dataID)
    `CHECK(io_in_0_rx_dat_bits_data)
    `CHECK(io_in_1_tx_req_ready)
    `CHECK(io_in_1_tx_dat_ready)
    `CHECK(io_in_1_rx_rsp_valid)
    `CHECK(io_in_1_rx_rsp_bits_srcID)
    `CHECK(io_in_1_rx_rsp_bits_txnID)
    `CHECK(io_in_1_rx_rsp_bits_opcode)
    `CHECK(io_in_1_rx_rsp_bits_dbID)
    `CHECK(io_in_1_rx_dat_valid)
    `CHECK(io_in_1_rx_dat_bits_srcID)
    `CHECK(io_in_1_rx_dat_bits_txnID)
    `CHECK(io_in_1_rx_dat_bits_opcode)
    `CHECK(io_in_1_rx_dat_bits_resp)
    `CHECK(io_in_1_rx_dat_bits_dataID)
    `CHECK(io_in_1_rx_dat_bits_data)
    `CHECK(io_in_2_tx_req_ready)
    `CHECK(io_in_2_tx_dat_ready)
    `CHECK(io_in_2_rx_rsp_valid)
    `CHECK(io_in_2_rx_rsp_bits_srcID)
    `CHECK(io_in_2_rx_rsp_bits_txnID)
    `CHECK(io_in_2_rx_rsp_bits_opcode)
    `CHECK(io_in_2_rx_rsp_bits_dbID)
    `CHECK(io_in_2_rx_dat_valid)
    `CHECK(io_in_2_rx_dat_bits_srcID)
    `CHECK(io_in_2_rx_dat_bits_txnID)
    `CHECK(io_in_2_rx_dat_bits_opcode)
    `CHECK(io_in_2_rx_dat_bits_resp)
    `CHECK(io_in_2_rx_dat_bits_dataID)
    `CHECK(io_in_2_rx_dat_bits_data)
    `CHECK(io_in_3_tx_req_ready)
    `CHECK(io_in_3_tx_dat_ready)
    `CHECK(io_in_3_rx_rsp_valid)
    `CHECK(io_in_3_rx_rsp_bits_srcID)
    `CHECK(io_in_3_rx_rsp_bits_txnID)
    `CHECK(io_in_3_rx_rsp_bits_opcode)
    `CHECK(io_in_3_rx_rsp_bits_dbID)
    `CHECK(io_in_3_rx_dat_valid)
    `CHECK(io_in_3_rx_dat_bits_srcID)
    `CHECK(io_in_3_rx_dat_bits_txnID)
    `CHECK(io_in_3_rx_dat_bits_opcode)
    `CHECK(io_in_3_rx_dat_bits_resp)
    `CHECK(io_in_3_rx_dat_bits_dataID)
    `CHECK(io_in_3_rx_dat_bits_data)
    `CHECK(io_out_tx_req_valid)
    `CHECK(io_out_tx_req_bits_tgtID)
    `CHECK(io_out_tx_req_bits_srcID)
    `CHECK(io_out_tx_req_bits_txnID)
    `CHECK(io_out_tx_req_bits_opcode)
    `CHECK(io_out_tx_req_bits_size)
    `CHECK(io_out_tx_req_bits_addr)
    `CHECK(io_out_tx_req_bits_allowRetry)
    `CHECK(io_out_tx_req_bits_order)
    `CHECK(io_out_tx_req_bits_pCrdType)
    `CHECK(io_out_tx_req_bits_memAttr_allocate)
    `CHECK(io_out_tx_req_bits_memAttr_cacheable)
    `CHECK(io_out_tx_req_bits_memAttr_device)
    `CHECK(io_out_tx_req_bits_memAttr_ewa)
    `CHECK(io_out_tx_req_bits_snpAttr)
    `CHECK(io_out_tx_req_bits_expCompAck)
    `CHECK(io_out_tx_dat_valid)
    `CHECK(io_out_tx_dat_bits_tgtID)
    `CHECK(io_out_tx_dat_bits_srcID)
    `CHECK(io_out_tx_dat_bits_txnID)
    `CHECK(io_out_tx_dat_bits_homeNID)
    `CHECK(io_out_tx_dat_bits_opcode)
    `CHECK(io_out_tx_dat_bits_resp)
    `CHECK(io_out_tx_dat_bits_dataSource)
    `CHECK(io_out_tx_dat_bits_dbID)
    `CHECK(io_out_tx_dat_bits_dataID)
    `CHECK(io_out_tx_dat_bits_be)
    `CHECK(io_out_tx_dat_bits_data)
    `CHECK(io_out_tx_dat_bits_dataCheck)
    `CHECK(io_out_rx_rsp_ready)
    `CHECK(io_out_rx_dat_ready)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_tx_req_valid = '0;
    io_in_0_tx_req_bits_tgtID = '0;
    io_in_0_tx_req_bits_srcID = '0;
    io_in_0_tx_req_bits_txnID = '0;
    io_in_0_tx_req_bits_opcode = '0;
    io_in_0_tx_req_bits_size = '0;
    io_in_0_tx_req_bits_addr = '0;
    io_in_0_tx_req_bits_allowRetry = '0;
    io_in_0_tx_req_bits_order = '0;
    io_in_0_tx_req_bits_pCrdType = '0;
    io_in_0_tx_req_bits_memAttr_allocate = '0;
    io_in_0_tx_req_bits_memAttr_cacheable = '0;
    io_in_0_tx_req_bits_memAttr_device = '0;
    io_in_0_tx_req_bits_memAttr_ewa = '0;
    io_in_0_tx_req_bits_snpAttr = '0;
    io_in_0_tx_req_bits_expCompAck = '0;
    io_in_0_tx_dat_valid = '0;
    io_in_0_tx_dat_bits_tgtID = '0;
    io_in_0_tx_dat_bits_srcID = '0;
    io_in_0_tx_dat_bits_txnID = '0;
    io_in_0_tx_dat_bits_homeNID = '0;
    io_in_0_tx_dat_bits_opcode = '0;
    io_in_0_tx_dat_bits_resp = '0;
    io_in_0_tx_dat_bits_dataSource = '0;
    io_in_0_tx_dat_bits_dbID = '0;
    io_in_0_tx_dat_bits_dataID = '0;
    io_in_0_tx_dat_bits_be = '0;
    io_in_0_tx_dat_bits_data = '0;
    io_in_0_tx_dat_bits_dataCheck = '0;
    io_in_1_tx_req_valid = '0;
    io_in_1_tx_req_bits_tgtID = '0;
    io_in_1_tx_req_bits_srcID = '0;
    io_in_1_tx_req_bits_txnID = '0;
    io_in_1_tx_req_bits_opcode = '0;
    io_in_1_tx_req_bits_size = '0;
    io_in_1_tx_req_bits_addr = '0;
    io_in_1_tx_req_bits_allowRetry = '0;
    io_in_1_tx_req_bits_order = '0;
    io_in_1_tx_req_bits_pCrdType = '0;
    io_in_1_tx_req_bits_memAttr_allocate = '0;
    io_in_1_tx_req_bits_memAttr_cacheable = '0;
    io_in_1_tx_req_bits_memAttr_device = '0;
    io_in_1_tx_req_bits_memAttr_ewa = '0;
    io_in_1_tx_req_bits_snpAttr = '0;
    io_in_1_tx_req_bits_expCompAck = '0;
    io_in_1_tx_dat_valid = '0;
    io_in_1_tx_dat_bits_tgtID = '0;
    io_in_1_tx_dat_bits_srcID = '0;
    io_in_1_tx_dat_bits_txnID = '0;
    io_in_1_tx_dat_bits_homeNID = '0;
    io_in_1_tx_dat_bits_opcode = '0;
    io_in_1_tx_dat_bits_resp = '0;
    io_in_1_tx_dat_bits_dataSource = '0;
    io_in_1_tx_dat_bits_dbID = '0;
    io_in_1_tx_dat_bits_dataID = '0;
    io_in_1_tx_dat_bits_be = '0;
    io_in_1_tx_dat_bits_data = '0;
    io_in_1_tx_dat_bits_dataCheck = '0;
    io_in_2_tx_req_valid = '0;
    io_in_2_tx_req_bits_tgtID = '0;
    io_in_2_tx_req_bits_srcID = '0;
    io_in_2_tx_req_bits_txnID = '0;
    io_in_2_tx_req_bits_opcode = '0;
    io_in_2_tx_req_bits_size = '0;
    io_in_2_tx_req_bits_addr = '0;
    io_in_2_tx_req_bits_allowRetry = '0;
    io_in_2_tx_req_bits_order = '0;
    io_in_2_tx_req_bits_pCrdType = '0;
    io_in_2_tx_req_bits_memAttr_allocate = '0;
    io_in_2_tx_req_bits_memAttr_cacheable = '0;
    io_in_2_tx_req_bits_memAttr_device = '0;
    io_in_2_tx_req_bits_memAttr_ewa = '0;
    io_in_2_tx_req_bits_snpAttr = '0;
    io_in_2_tx_req_bits_expCompAck = '0;
    io_in_2_tx_dat_valid = '0;
    io_in_2_tx_dat_bits_tgtID = '0;
    io_in_2_tx_dat_bits_srcID = '0;
    io_in_2_tx_dat_bits_txnID = '0;
    io_in_2_tx_dat_bits_homeNID = '0;
    io_in_2_tx_dat_bits_opcode = '0;
    io_in_2_tx_dat_bits_resp = '0;
    io_in_2_tx_dat_bits_dataSource = '0;
    io_in_2_tx_dat_bits_dbID = '0;
    io_in_2_tx_dat_bits_dataID = '0;
    io_in_2_tx_dat_bits_be = '0;
    io_in_2_tx_dat_bits_data = '0;
    io_in_2_tx_dat_bits_dataCheck = '0;
    io_in_3_tx_req_valid = '0;
    io_in_3_tx_req_bits_tgtID = '0;
    io_in_3_tx_req_bits_srcID = '0;
    io_in_3_tx_req_bits_txnID = '0;
    io_in_3_tx_req_bits_opcode = '0;
    io_in_3_tx_req_bits_size = '0;
    io_in_3_tx_req_bits_addr = '0;
    io_in_3_tx_req_bits_allowRetry = '0;
    io_in_3_tx_req_bits_order = '0;
    io_in_3_tx_req_bits_pCrdType = '0;
    io_in_3_tx_req_bits_memAttr_allocate = '0;
    io_in_3_tx_req_bits_memAttr_cacheable = '0;
    io_in_3_tx_req_bits_memAttr_device = '0;
    io_in_3_tx_req_bits_memAttr_ewa = '0;
    io_in_3_tx_req_bits_snpAttr = '0;
    io_in_3_tx_req_bits_expCompAck = '0;
    io_in_3_tx_dat_valid = '0;
    io_in_3_tx_dat_bits_tgtID = '0;
    io_in_3_tx_dat_bits_srcID = '0;
    io_in_3_tx_dat_bits_txnID = '0;
    io_in_3_tx_dat_bits_homeNID = '0;
    io_in_3_tx_dat_bits_opcode = '0;
    io_in_3_tx_dat_bits_resp = '0;
    io_in_3_tx_dat_bits_dataSource = '0;
    io_in_3_tx_dat_bits_dbID = '0;
    io_in_3_tx_dat_bits_dataID = '0;
    io_in_3_tx_dat_bits_be = '0;
    io_in_3_tx_dat_bits_data = '0;
    io_in_3_tx_dat_bits_dataCheck = '0;
    io_out_tx_req_ready = '0;
    io_out_tx_dat_ready = '0;
    io_out_rx_rsp_valid = '0;
    io_out_rx_rsp_bits_srcID = '0;
    io_out_rx_rsp_bits_txnID = '0;
    io_out_rx_rsp_bits_opcode = '0;
    io_out_rx_rsp_bits_dbID = '0;
    io_out_rx_dat_valid = '0;
    io_out_rx_dat_bits_srcID = '0;
    io_out_rx_dat_bits_txnID = '0;
    io_out_rx_dat_bits_opcode = '0;
    io_out_rx_dat_bits_resp = '0;
    io_out_rx_dat_bits_dataID = '0;
    io_out_rx_dat_bits_data = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("SNXbar checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
