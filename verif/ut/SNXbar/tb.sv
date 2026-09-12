// 自动生成：scripts/gen_zj_ut.py SNXbar —— 勿手改
// SNXbar 双例化逐拍比对：golden SNXbar vs 重写 SNXbar_xs（derive_ut_impl.py 派生）。
// 激励 = G1 golden 端口表全随机（ready 偏置 75% 高以制造反压）；
// 收尾判 errors / checks / toggled / fires 四项，后三项是覆盖闸（防假绿）。
`timescale 1ns/1ps
module tb;
  localparam int unsigned NCYCLES     = 120000;
  localparam int unsigned MIN_TOGGLED = 87;
  localparam int unsigned MIN_FIRES   = 50000;
  localparam int unsigned N_OUT       = 87;

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0, fires = 0;
  int      toggled = 0;

  // 宽随机：$urandom 一次 32 位，拼够位宽。
  function automatic logic [2047:0] rnd(input int w);
    logic [2047:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

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

  logic p_io_in_0_tx_req_ready;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_tx_req_ready;
  logic p_io_in_0_tx_dat_ready;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_tx_dat_ready;
  logic p_io_in_0_rx_rsp_valid;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_rx_rsp_valid;
  logic [10:0] p_io_in_0_rx_rsp_bits_srcID;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_rx_rsp_bits_srcID;
  logic [11:0] p_io_in_0_rx_rsp_bits_txnID;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_rx_rsp_bits_txnID;
  logic [4:0] p_io_in_0_rx_rsp_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_rx_rsp_bits_opcode;
  logic [11:0] p_io_in_0_rx_rsp_bits_dbID;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_rx_rsp_bits_dbID;
  logic p_io_in_0_rx_dat_valid;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_rx_dat_valid;
  logic [10:0] p_io_in_0_rx_dat_bits_srcID;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_rx_dat_bits_srcID;
  logic [11:0] p_io_in_0_rx_dat_bits_txnID;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_rx_dat_bits_txnID;
  logic [3:0] p_io_in_0_rx_dat_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_rx_dat_bits_opcode;
  logic [2:0] p_io_in_0_rx_dat_bits_resp;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_rx_dat_bits_resp;
  logic [1:0] p_io_in_0_rx_dat_bits_dataID;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_rx_dat_bits_dataID;
  logic [255:0] p_io_in_0_rx_dat_bits_data;   // 上一拍值（toggle 统计）
  bit tog_io_in_0_rx_dat_bits_data;
  logic p_io_in_1_tx_req_ready;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_tx_req_ready;
  logic p_io_in_1_tx_dat_ready;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_tx_dat_ready;
  logic p_io_in_1_rx_rsp_valid;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_rx_rsp_valid;
  logic [10:0] p_io_in_1_rx_rsp_bits_srcID;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_rx_rsp_bits_srcID;
  logic [11:0] p_io_in_1_rx_rsp_bits_txnID;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_rx_rsp_bits_txnID;
  logic [4:0] p_io_in_1_rx_rsp_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_rx_rsp_bits_opcode;
  logic [11:0] p_io_in_1_rx_rsp_bits_dbID;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_rx_rsp_bits_dbID;
  logic p_io_in_1_rx_dat_valid;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_rx_dat_valid;
  logic [10:0] p_io_in_1_rx_dat_bits_srcID;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_rx_dat_bits_srcID;
  logic [11:0] p_io_in_1_rx_dat_bits_txnID;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_rx_dat_bits_txnID;
  logic [3:0] p_io_in_1_rx_dat_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_rx_dat_bits_opcode;
  logic [2:0] p_io_in_1_rx_dat_bits_resp;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_rx_dat_bits_resp;
  logic [1:0] p_io_in_1_rx_dat_bits_dataID;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_rx_dat_bits_dataID;
  logic [255:0] p_io_in_1_rx_dat_bits_data;   // 上一拍值（toggle 统计）
  bit tog_io_in_1_rx_dat_bits_data;
  logic p_io_in_2_tx_req_ready;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_tx_req_ready;
  logic p_io_in_2_tx_dat_ready;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_tx_dat_ready;
  logic p_io_in_2_rx_rsp_valid;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_rx_rsp_valid;
  logic [10:0] p_io_in_2_rx_rsp_bits_srcID;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_rx_rsp_bits_srcID;
  logic [11:0] p_io_in_2_rx_rsp_bits_txnID;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_rx_rsp_bits_txnID;
  logic [4:0] p_io_in_2_rx_rsp_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_rx_rsp_bits_opcode;
  logic [11:0] p_io_in_2_rx_rsp_bits_dbID;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_rx_rsp_bits_dbID;
  logic p_io_in_2_rx_dat_valid;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_rx_dat_valid;
  logic [10:0] p_io_in_2_rx_dat_bits_srcID;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_rx_dat_bits_srcID;
  logic [11:0] p_io_in_2_rx_dat_bits_txnID;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_rx_dat_bits_txnID;
  logic [3:0] p_io_in_2_rx_dat_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_rx_dat_bits_opcode;
  logic [2:0] p_io_in_2_rx_dat_bits_resp;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_rx_dat_bits_resp;
  logic [1:0] p_io_in_2_rx_dat_bits_dataID;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_rx_dat_bits_dataID;
  logic [255:0] p_io_in_2_rx_dat_bits_data;   // 上一拍值（toggle 统计）
  bit tog_io_in_2_rx_dat_bits_data;
  logic p_io_in_3_tx_req_ready;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_tx_req_ready;
  logic p_io_in_3_tx_dat_ready;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_tx_dat_ready;
  logic p_io_in_3_rx_rsp_valid;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_rx_rsp_valid;
  logic [10:0] p_io_in_3_rx_rsp_bits_srcID;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_rx_rsp_bits_srcID;
  logic [11:0] p_io_in_3_rx_rsp_bits_txnID;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_rx_rsp_bits_txnID;
  logic [4:0] p_io_in_3_rx_rsp_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_rx_rsp_bits_opcode;
  logic [11:0] p_io_in_3_rx_rsp_bits_dbID;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_rx_rsp_bits_dbID;
  logic p_io_in_3_rx_dat_valid;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_rx_dat_valid;
  logic [10:0] p_io_in_3_rx_dat_bits_srcID;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_rx_dat_bits_srcID;
  logic [11:0] p_io_in_3_rx_dat_bits_txnID;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_rx_dat_bits_txnID;
  logic [3:0] p_io_in_3_rx_dat_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_rx_dat_bits_opcode;
  logic [2:0] p_io_in_3_rx_dat_bits_resp;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_rx_dat_bits_resp;
  logic [1:0] p_io_in_3_rx_dat_bits_dataID;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_rx_dat_bits_dataID;
  logic [255:0] p_io_in_3_rx_dat_bits_data;   // 上一拍值（toggle 统计）
  bit tog_io_in_3_rx_dat_bits_data;
  logic p_io_out_tx_req_valid;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_valid;
  logic [10:0] p_io_out_tx_req_bits_tgtID;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_tgtID;
  logic [10:0] p_io_out_tx_req_bits_srcID;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_srcID;
  logic [11:0] p_io_out_tx_req_bits_txnID;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_txnID;
  logic [6:0] p_io_out_tx_req_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_opcode;
  logic [2:0] p_io_out_tx_req_bits_size;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_size;
  logic [47:0] p_io_out_tx_req_bits_addr;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_addr;
  logic p_io_out_tx_req_bits_allowRetry;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_allowRetry;
  logic [1:0] p_io_out_tx_req_bits_order;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_order;
  logic [3:0] p_io_out_tx_req_bits_pCrdType;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_pCrdType;
  logic p_io_out_tx_req_bits_memAttr_allocate;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_memAttr_allocate;
  logic p_io_out_tx_req_bits_memAttr_cacheable;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_memAttr_cacheable;
  logic p_io_out_tx_req_bits_memAttr_device;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_memAttr_device;
  logic p_io_out_tx_req_bits_memAttr_ewa;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_memAttr_ewa;
  logic p_io_out_tx_req_bits_snpAttr;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_snpAttr;
  logic p_io_out_tx_req_bits_expCompAck;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_req_bits_expCompAck;
  logic p_io_out_tx_dat_valid;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_valid;
  logic [10:0] p_io_out_tx_dat_bits_tgtID;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_bits_tgtID;
  logic [10:0] p_io_out_tx_dat_bits_srcID;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_bits_srcID;
  logic [11:0] p_io_out_tx_dat_bits_txnID;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_bits_txnID;
  logic [10:0] p_io_out_tx_dat_bits_homeNID;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_bits_homeNID;
  logic [3:0] p_io_out_tx_dat_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_bits_opcode;
  logic [2:0] p_io_out_tx_dat_bits_resp;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_bits_resp;
  logic [3:0] p_io_out_tx_dat_bits_dataSource;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_bits_dataSource;
  logic [11:0] p_io_out_tx_dat_bits_dbID;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_bits_dbID;
  logic [1:0] p_io_out_tx_dat_bits_dataID;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_bits_dataID;
  logic [31:0] p_io_out_tx_dat_bits_be;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_bits_be;
  logic [255:0] p_io_out_tx_dat_bits_data;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_bits_data;
  logic [31:0] p_io_out_tx_dat_bits_dataCheck;   // 上一拍值（toggle 统计）
  bit tog_io_out_tx_dat_bits_dataCheck;
  logic p_io_out_rx_rsp_ready;   // 上一拍值（toggle 统计）
  bit tog_io_out_rx_rsp_ready;
  logic p_io_out_rx_dat_ready;   // 上一拍值（toggle 统计）
  bit tog_io_out_rx_dat_ready;

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

  task automatic drive_random();
    io_in_0_tx_req_valid = $urandom % 2;
    io_in_0_tx_req_bits_tgtID = rnd(11);
    io_in_0_tx_req_bits_srcID = rnd(11);
    io_in_0_tx_req_bits_txnID = rnd(12);
    io_in_0_tx_req_bits_opcode = rnd(7);
    io_in_0_tx_req_bits_size = rnd(3);
    io_in_0_tx_req_bits_addr = rnd(48);
    io_in_0_tx_req_bits_allowRetry = $urandom % 2;
    io_in_0_tx_req_bits_order = rnd(2);
    io_in_0_tx_req_bits_pCrdType = rnd(4);
    io_in_0_tx_req_bits_memAttr_allocate = $urandom % 2;
    io_in_0_tx_req_bits_memAttr_cacheable = $urandom % 2;
    io_in_0_tx_req_bits_memAttr_device = $urandom % 2;
    io_in_0_tx_req_bits_memAttr_ewa = $urandom % 2;
    io_in_0_tx_req_bits_snpAttr = $urandom % 2;
    io_in_0_tx_req_bits_expCompAck = $urandom % 2;
    io_in_0_tx_dat_valid = $urandom % 2;
    io_in_0_tx_dat_bits_tgtID = rnd(11);
    io_in_0_tx_dat_bits_srcID = rnd(11);
    io_in_0_tx_dat_bits_txnID = rnd(12);
    io_in_0_tx_dat_bits_homeNID = rnd(11);
    io_in_0_tx_dat_bits_opcode = rnd(4);
    io_in_0_tx_dat_bits_resp = rnd(3);
    io_in_0_tx_dat_bits_dataSource = rnd(4);
    io_in_0_tx_dat_bits_dbID = rnd(12);
    io_in_0_tx_dat_bits_dataID = rnd(2);
    io_in_0_tx_dat_bits_be = rnd(32);
    io_in_0_tx_dat_bits_data = rnd(256);
    io_in_0_tx_dat_bits_dataCheck = rnd(32);
    io_in_1_tx_req_valid = $urandom % 2;
    io_in_1_tx_req_bits_tgtID = rnd(11);
    io_in_1_tx_req_bits_srcID = rnd(11);
    io_in_1_tx_req_bits_txnID = rnd(12);
    io_in_1_tx_req_bits_opcode = rnd(7);
    io_in_1_tx_req_bits_size = rnd(3);
    io_in_1_tx_req_bits_addr = rnd(48);
    io_in_1_tx_req_bits_allowRetry = $urandom % 2;
    io_in_1_tx_req_bits_order = rnd(2);
    io_in_1_tx_req_bits_pCrdType = rnd(4);
    io_in_1_tx_req_bits_memAttr_allocate = $urandom % 2;
    io_in_1_tx_req_bits_memAttr_cacheable = $urandom % 2;
    io_in_1_tx_req_bits_memAttr_device = $urandom % 2;
    io_in_1_tx_req_bits_memAttr_ewa = $urandom % 2;
    io_in_1_tx_req_bits_snpAttr = $urandom % 2;
    io_in_1_tx_req_bits_expCompAck = $urandom % 2;
    io_in_1_tx_dat_valid = $urandom % 2;
    io_in_1_tx_dat_bits_tgtID = rnd(11);
    io_in_1_tx_dat_bits_srcID = rnd(11);
    io_in_1_tx_dat_bits_txnID = rnd(12);
    io_in_1_tx_dat_bits_homeNID = rnd(11);
    io_in_1_tx_dat_bits_opcode = rnd(4);
    io_in_1_tx_dat_bits_resp = rnd(3);
    io_in_1_tx_dat_bits_dataSource = rnd(4);
    io_in_1_tx_dat_bits_dbID = rnd(12);
    io_in_1_tx_dat_bits_dataID = rnd(2);
    io_in_1_tx_dat_bits_be = rnd(32);
    io_in_1_tx_dat_bits_data = rnd(256);
    io_in_1_tx_dat_bits_dataCheck = rnd(32);
    io_in_2_tx_req_valid = $urandom % 2;
    io_in_2_tx_req_bits_tgtID = rnd(11);
    io_in_2_tx_req_bits_srcID = rnd(11);
    io_in_2_tx_req_bits_txnID = rnd(12);
    io_in_2_tx_req_bits_opcode = rnd(7);
    io_in_2_tx_req_bits_size = rnd(3);
    io_in_2_tx_req_bits_addr = rnd(48);
    io_in_2_tx_req_bits_allowRetry = $urandom % 2;
    io_in_2_tx_req_bits_order = rnd(2);
    io_in_2_tx_req_bits_pCrdType = rnd(4);
    io_in_2_tx_req_bits_memAttr_allocate = $urandom % 2;
    io_in_2_tx_req_bits_memAttr_cacheable = $urandom % 2;
    io_in_2_tx_req_bits_memAttr_device = $urandom % 2;
    io_in_2_tx_req_bits_memAttr_ewa = $urandom % 2;
    io_in_2_tx_req_bits_snpAttr = $urandom % 2;
    io_in_2_tx_req_bits_expCompAck = $urandom % 2;
    io_in_2_tx_dat_valid = $urandom % 2;
    io_in_2_tx_dat_bits_tgtID = rnd(11);
    io_in_2_tx_dat_bits_srcID = rnd(11);
    io_in_2_tx_dat_bits_txnID = rnd(12);
    io_in_2_tx_dat_bits_homeNID = rnd(11);
    io_in_2_tx_dat_bits_opcode = rnd(4);
    io_in_2_tx_dat_bits_resp = rnd(3);
    io_in_2_tx_dat_bits_dataSource = rnd(4);
    io_in_2_tx_dat_bits_dbID = rnd(12);
    io_in_2_tx_dat_bits_dataID = rnd(2);
    io_in_2_tx_dat_bits_be = rnd(32);
    io_in_2_tx_dat_bits_data = rnd(256);
    io_in_2_tx_dat_bits_dataCheck = rnd(32);
    io_in_3_tx_req_valid = $urandom % 2;
    io_in_3_tx_req_bits_tgtID = rnd(11);
    io_in_3_tx_req_bits_srcID = rnd(11);
    io_in_3_tx_req_bits_txnID = rnd(12);
    io_in_3_tx_req_bits_opcode = rnd(7);
    io_in_3_tx_req_bits_size = rnd(3);
    io_in_3_tx_req_bits_addr = rnd(48);
    io_in_3_tx_req_bits_allowRetry = $urandom % 2;
    io_in_3_tx_req_bits_order = rnd(2);
    io_in_3_tx_req_bits_pCrdType = rnd(4);
    io_in_3_tx_req_bits_memAttr_allocate = $urandom % 2;
    io_in_3_tx_req_bits_memAttr_cacheable = $urandom % 2;
    io_in_3_tx_req_bits_memAttr_device = $urandom % 2;
    io_in_3_tx_req_bits_memAttr_ewa = $urandom % 2;
    io_in_3_tx_req_bits_snpAttr = $urandom % 2;
    io_in_3_tx_req_bits_expCompAck = $urandom % 2;
    io_in_3_tx_dat_valid = $urandom % 2;
    io_in_3_tx_dat_bits_tgtID = rnd(11);
    io_in_3_tx_dat_bits_srcID = rnd(11);
    io_in_3_tx_dat_bits_txnID = rnd(12);
    io_in_3_tx_dat_bits_homeNID = rnd(11);
    io_in_3_tx_dat_bits_opcode = rnd(4);
    io_in_3_tx_dat_bits_resp = rnd(3);
    io_in_3_tx_dat_bits_dataSource = rnd(4);
    io_in_3_tx_dat_bits_dbID = rnd(12);
    io_in_3_tx_dat_bits_dataID = rnd(2);
    io_in_3_tx_dat_bits_be = rnd(32);
    io_in_3_tx_dat_bits_data = rnd(256);
    io_in_3_tx_dat_bits_dataCheck = rnd(32);
    io_out_tx_req_ready = (($urandom % 4) != 0);            // 75% 高：制造反压
    io_out_tx_dat_ready = (($urandom % 4) != 0);            // 75% 高：制造反压
    io_out_rx_rsp_valid = $urandom % 2;
    io_out_rx_rsp_bits_srcID = rnd(11);
    io_out_rx_rsp_bits_txnID = rnd(12);
    io_out_rx_rsp_bits_opcode = rnd(5);
    io_out_rx_rsp_bits_dbID = rnd(12);
    io_out_rx_dat_valid = $urandom % 2;
    io_out_rx_dat_bits_srcID = rnd(11);
    io_out_rx_dat_bits_txnID = rnd(12);
    io_out_rx_dat_bits_opcode = rnd(4);
    io_out_rx_dat_bits_resp = rnd(3);
    io_out_rx_dat_bits_dataID = rnd(2);
    io_out_rx_dat_bits_data = rnd(256);
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_io_in_0_tx_req_ready)) begin
      checks++;
      if (g_io_in_0_tx_req_ready !== i_io_in_0_tx_req_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_tx_req_ready g=%0h i=%0h", $time, g_io_in_0_tx_req_ready, i_io_in_0_tx_req_ready);
      end
    end
    if (!$isunknown(g_io_in_0_tx_dat_ready)) begin
      checks++;
      if (g_io_in_0_tx_dat_ready !== i_io_in_0_tx_dat_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_tx_dat_ready g=%0h i=%0h", $time, g_io_in_0_tx_dat_ready, i_io_in_0_tx_dat_ready);
      end
    end
    if (!$isunknown(g_io_in_0_rx_rsp_valid)) begin
      checks++;
      if (g_io_in_0_rx_rsp_valid !== i_io_in_0_rx_rsp_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_rx_rsp_valid g=%0h i=%0h", $time, g_io_in_0_rx_rsp_valid, i_io_in_0_rx_rsp_valid);
      end
    end
    if (!$isunknown(g_io_in_0_rx_rsp_bits_srcID)) begin
      checks++;
      if (g_io_in_0_rx_rsp_bits_srcID !== i_io_in_0_rx_rsp_bits_srcID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_rx_rsp_bits_srcID g=%0h i=%0h", $time, g_io_in_0_rx_rsp_bits_srcID, i_io_in_0_rx_rsp_bits_srcID);
      end
    end
    if (!$isunknown(g_io_in_0_rx_rsp_bits_txnID)) begin
      checks++;
      if (g_io_in_0_rx_rsp_bits_txnID !== i_io_in_0_rx_rsp_bits_txnID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_rx_rsp_bits_txnID g=%0h i=%0h", $time, g_io_in_0_rx_rsp_bits_txnID, i_io_in_0_rx_rsp_bits_txnID);
      end
    end
    if (!$isunknown(g_io_in_0_rx_rsp_bits_opcode)) begin
      checks++;
      if (g_io_in_0_rx_rsp_bits_opcode !== i_io_in_0_rx_rsp_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_rx_rsp_bits_opcode g=%0h i=%0h", $time, g_io_in_0_rx_rsp_bits_opcode, i_io_in_0_rx_rsp_bits_opcode);
      end
    end
    if (!$isunknown(g_io_in_0_rx_rsp_bits_dbID)) begin
      checks++;
      if (g_io_in_0_rx_rsp_bits_dbID !== i_io_in_0_rx_rsp_bits_dbID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_rx_rsp_bits_dbID g=%0h i=%0h", $time, g_io_in_0_rx_rsp_bits_dbID, i_io_in_0_rx_rsp_bits_dbID);
      end
    end
    if (!$isunknown(g_io_in_0_rx_dat_valid)) begin
      checks++;
      if (g_io_in_0_rx_dat_valid !== i_io_in_0_rx_dat_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_rx_dat_valid g=%0h i=%0h", $time, g_io_in_0_rx_dat_valid, i_io_in_0_rx_dat_valid);
      end
    end
    if (!$isunknown(g_io_in_0_rx_dat_bits_srcID)) begin
      checks++;
      if (g_io_in_0_rx_dat_bits_srcID !== i_io_in_0_rx_dat_bits_srcID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_rx_dat_bits_srcID g=%0h i=%0h", $time, g_io_in_0_rx_dat_bits_srcID, i_io_in_0_rx_dat_bits_srcID);
      end
    end
    if (!$isunknown(g_io_in_0_rx_dat_bits_txnID)) begin
      checks++;
      if (g_io_in_0_rx_dat_bits_txnID !== i_io_in_0_rx_dat_bits_txnID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_rx_dat_bits_txnID g=%0h i=%0h", $time, g_io_in_0_rx_dat_bits_txnID, i_io_in_0_rx_dat_bits_txnID);
      end
    end
    if (!$isunknown(g_io_in_0_rx_dat_bits_opcode)) begin
      checks++;
      if (g_io_in_0_rx_dat_bits_opcode !== i_io_in_0_rx_dat_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_rx_dat_bits_opcode g=%0h i=%0h", $time, g_io_in_0_rx_dat_bits_opcode, i_io_in_0_rx_dat_bits_opcode);
      end
    end
    if (!$isunknown(g_io_in_0_rx_dat_bits_resp)) begin
      checks++;
      if (g_io_in_0_rx_dat_bits_resp !== i_io_in_0_rx_dat_bits_resp) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_rx_dat_bits_resp g=%0h i=%0h", $time, g_io_in_0_rx_dat_bits_resp, i_io_in_0_rx_dat_bits_resp);
      end
    end
    if (!$isunknown(g_io_in_0_rx_dat_bits_dataID)) begin
      checks++;
      if (g_io_in_0_rx_dat_bits_dataID !== i_io_in_0_rx_dat_bits_dataID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_rx_dat_bits_dataID g=%0h i=%0h", $time, g_io_in_0_rx_dat_bits_dataID, i_io_in_0_rx_dat_bits_dataID);
      end
    end
    if (!$isunknown(g_io_in_0_rx_dat_bits_data)) begin
      checks++;
      if (g_io_in_0_rx_dat_bits_data !== i_io_in_0_rx_dat_bits_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_0_rx_dat_bits_data g=%0h i=%0h", $time, g_io_in_0_rx_dat_bits_data, i_io_in_0_rx_dat_bits_data);
      end
    end
    if (!$isunknown(g_io_in_1_tx_req_ready)) begin
      checks++;
      if (g_io_in_1_tx_req_ready !== i_io_in_1_tx_req_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_tx_req_ready g=%0h i=%0h", $time, g_io_in_1_tx_req_ready, i_io_in_1_tx_req_ready);
      end
    end
    if (!$isunknown(g_io_in_1_tx_dat_ready)) begin
      checks++;
      if (g_io_in_1_tx_dat_ready !== i_io_in_1_tx_dat_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_tx_dat_ready g=%0h i=%0h", $time, g_io_in_1_tx_dat_ready, i_io_in_1_tx_dat_ready);
      end
    end
    if (!$isunknown(g_io_in_1_rx_rsp_valid)) begin
      checks++;
      if (g_io_in_1_rx_rsp_valid !== i_io_in_1_rx_rsp_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_rx_rsp_valid g=%0h i=%0h", $time, g_io_in_1_rx_rsp_valid, i_io_in_1_rx_rsp_valid);
      end
    end
    if (!$isunknown(g_io_in_1_rx_rsp_bits_srcID)) begin
      checks++;
      if (g_io_in_1_rx_rsp_bits_srcID !== i_io_in_1_rx_rsp_bits_srcID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_rx_rsp_bits_srcID g=%0h i=%0h", $time, g_io_in_1_rx_rsp_bits_srcID, i_io_in_1_rx_rsp_bits_srcID);
      end
    end
    if (!$isunknown(g_io_in_1_rx_rsp_bits_txnID)) begin
      checks++;
      if (g_io_in_1_rx_rsp_bits_txnID !== i_io_in_1_rx_rsp_bits_txnID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_rx_rsp_bits_txnID g=%0h i=%0h", $time, g_io_in_1_rx_rsp_bits_txnID, i_io_in_1_rx_rsp_bits_txnID);
      end
    end
    if (!$isunknown(g_io_in_1_rx_rsp_bits_opcode)) begin
      checks++;
      if (g_io_in_1_rx_rsp_bits_opcode !== i_io_in_1_rx_rsp_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_rx_rsp_bits_opcode g=%0h i=%0h", $time, g_io_in_1_rx_rsp_bits_opcode, i_io_in_1_rx_rsp_bits_opcode);
      end
    end
    if (!$isunknown(g_io_in_1_rx_rsp_bits_dbID)) begin
      checks++;
      if (g_io_in_1_rx_rsp_bits_dbID !== i_io_in_1_rx_rsp_bits_dbID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_rx_rsp_bits_dbID g=%0h i=%0h", $time, g_io_in_1_rx_rsp_bits_dbID, i_io_in_1_rx_rsp_bits_dbID);
      end
    end
    if (!$isunknown(g_io_in_1_rx_dat_valid)) begin
      checks++;
      if (g_io_in_1_rx_dat_valid !== i_io_in_1_rx_dat_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_rx_dat_valid g=%0h i=%0h", $time, g_io_in_1_rx_dat_valid, i_io_in_1_rx_dat_valid);
      end
    end
    if (!$isunknown(g_io_in_1_rx_dat_bits_srcID)) begin
      checks++;
      if (g_io_in_1_rx_dat_bits_srcID !== i_io_in_1_rx_dat_bits_srcID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_rx_dat_bits_srcID g=%0h i=%0h", $time, g_io_in_1_rx_dat_bits_srcID, i_io_in_1_rx_dat_bits_srcID);
      end
    end
    if (!$isunknown(g_io_in_1_rx_dat_bits_txnID)) begin
      checks++;
      if (g_io_in_1_rx_dat_bits_txnID !== i_io_in_1_rx_dat_bits_txnID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_rx_dat_bits_txnID g=%0h i=%0h", $time, g_io_in_1_rx_dat_bits_txnID, i_io_in_1_rx_dat_bits_txnID);
      end
    end
    if (!$isunknown(g_io_in_1_rx_dat_bits_opcode)) begin
      checks++;
      if (g_io_in_1_rx_dat_bits_opcode !== i_io_in_1_rx_dat_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_rx_dat_bits_opcode g=%0h i=%0h", $time, g_io_in_1_rx_dat_bits_opcode, i_io_in_1_rx_dat_bits_opcode);
      end
    end
    if (!$isunknown(g_io_in_1_rx_dat_bits_resp)) begin
      checks++;
      if (g_io_in_1_rx_dat_bits_resp !== i_io_in_1_rx_dat_bits_resp) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_rx_dat_bits_resp g=%0h i=%0h", $time, g_io_in_1_rx_dat_bits_resp, i_io_in_1_rx_dat_bits_resp);
      end
    end
    if (!$isunknown(g_io_in_1_rx_dat_bits_dataID)) begin
      checks++;
      if (g_io_in_1_rx_dat_bits_dataID !== i_io_in_1_rx_dat_bits_dataID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_rx_dat_bits_dataID g=%0h i=%0h", $time, g_io_in_1_rx_dat_bits_dataID, i_io_in_1_rx_dat_bits_dataID);
      end
    end
    if (!$isunknown(g_io_in_1_rx_dat_bits_data)) begin
      checks++;
      if (g_io_in_1_rx_dat_bits_data !== i_io_in_1_rx_dat_bits_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_1_rx_dat_bits_data g=%0h i=%0h", $time, g_io_in_1_rx_dat_bits_data, i_io_in_1_rx_dat_bits_data);
      end
    end
    if (!$isunknown(g_io_in_2_tx_req_ready)) begin
      checks++;
      if (g_io_in_2_tx_req_ready !== i_io_in_2_tx_req_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_tx_req_ready g=%0h i=%0h", $time, g_io_in_2_tx_req_ready, i_io_in_2_tx_req_ready);
      end
    end
    if (!$isunknown(g_io_in_2_tx_dat_ready)) begin
      checks++;
      if (g_io_in_2_tx_dat_ready !== i_io_in_2_tx_dat_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_tx_dat_ready g=%0h i=%0h", $time, g_io_in_2_tx_dat_ready, i_io_in_2_tx_dat_ready);
      end
    end
    if (!$isunknown(g_io_in_2_rx_rsp_valid)) begin
      checks++;
      if (g_io_in_2_rx_rsp_valid !== i_io_in_2_rx_rsp_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_rx_rsp_valid g=%0h i=%0h", $time, g_io_in_2_rx_rsp_valid, i_io_in_2_rx_rsp_valid);
      end
    end
    if (!$isunknown(g_io_in_2_rx_rsp_bits_srcID)) begin
      checks++;
      if (g_io_in_2_rx_rsp_bits_srcID !== i_io_in_2_rx_rsp_bits_srcID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_rx_rsp_bits_srcID g=%0h i=%0h", $time, g_io_in_2_rx_rsp_bits_srcID, i_io_in_2_rx_rsp_bits_srcID);
      end
    end
    if (!$isunknown(g_io_in_2_rx_rsp_bits_txnID)) begin
      checks++;
      if (g_io_in_2_rx_rsp_bits_txnID !== i_io_in_2_rx_rsp_bits_txnID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_rx_rsp_bits_txnID g=%0h i=%0h", $time, g_io_in_2_rx_rsp_bits_txnID, i_io_in_2_rx_rsp_bits_txnID);
      end
    end
    if (!$isunknown(g_io_in_2_rx_rsp_bits_opcode)) begin
      checks++;
      if (g_io_in_2_rx_rsp_bits_opcode !== i_io_in_2_rx_rsp_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_rx_rsp_bits_opcode g=%0h i=%0h", $time, g_io_in_2_rx_rsp_bits_opcode, i_io_in_2_rx_rsp_bits_opcode);
      end
    end
    if (!$isunknown(g_io_in_2_rx_rsp_bits_dbID)) begin
      checks++;
      if (g_io_in_2_rx_rsp_bits_dbID !== i_io_in_2_rx_rsp_bits_dbID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_rx_rsp_bits_dbID g=%0h i=%0h", $time, g_io_in_2_rx_rsp_bits_dbID, i_io_in_2_rx_rsp_bits_dbID);
      end
    end
    if (!$isunknown(g_io_in_2_rx_dat_valid)) begin
      checks++;
      if (g_io_in_2_rx_dat_valid !== i_io_in_2_rx_dat_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_rx_dat_valid g=%0h i=%0h", $time, g_io_in_2_rx_dat_valid, i_io_in_2_rx_dat_valid);
      end
    end
    if (!$isunknown(g_io_in_2_rx_dat_bits_srcID)) begin
      checks++;
      if (g_io_in_2_rx_dat_bits_srcID !== i_io_in_2_rx_dat_bits_srcID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_rx_dat_bits_srcID g=%0h i=%0h", $time, g_io_in_2_rx_dat_bits_srcID, i_io_in_2_rx_dat_bits_srcID);
      end
    end
    if (!$isunknown(g_io_in_2_rx_dat_bits_txnID)) begin
      checks++;
      if (g_io_in_2_rx_dat_bits_txnID !== i_io_in_2_rx_dat_bits_txnID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_rx_dat_bits_txnID g=%0h i=%0h", $time, g_io_in_2_rx_dat_bits_txnID, i_io_in_2_rx_dat_bits_txnID);
      end
    end
    if (!$isunknown(g_io_in_2_rx_dat_bits_opcode)) begin
      checks++;
      if (g_io_in_2_rx_dat_bits_opcode !== i_io_in_2_rx_dat_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_rx_dat_bits_opcode g=%0h i=%0h", $time, g_io_in_2_rx_dat_bits_opcode, i_io_in_2_rx_dat_bits_opcode);
      end
    end
    if (!$isunknown(g_io_in_2_rx_dat_bits_resp)) begin
      checks++;
      if (g_io_in_2_rx_dat_bits_resp !== i_io_in_2_rx_dat_bits_resp) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_rx_dat_bits_resp g=%0h i=%0h", $time, g_io_in_2_rx_dat_bits_resp, i_io_in_2_rx_dat_bits_resp);
      end
    end
    if (!$isunknown(g_io_in_2_rx_dat_bits_dataID)) begin
      checks++;
      if (g_io_in_2_rx_dat_bits_dataID !== i_io_in_2_rx_dat_bits_dataID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_rx_dat_bits_dataID g=%0h i=%0h", $time, g_io_in_2_rx_dat_bits_dataID, i_io_in_2_rx_dat_bits_dataID);
      end
    end
    if (!$isunknown(g_io_in_2_rx_dat_bits_data)) begin
      checks++;
      if (g_io_in_2_rx_dat_bits_data !== i_io_in_2_rx_dat_bits_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_2_rx_dat_bits_data g=%0h i=%0h", $time, g_io_in_2_rx_dat_bits_data, i_io_in_2_rx_dat_bits_data);
      end
    end
    if (!$isunknown(g_io_in_3_tx_req_ready)) begin
      checks++;
      if (g_io_in_3_tx_req_ready !== i_io_in_3_tx_req_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_tx_req_ready g=%0h i=%0h", $time, g_io_in_3_tx_req_ready, i_io_in_3_tx_req_ready);
      end
    end
    if (!$isunknown(g_io_in_3_tx_dat_ready)) begin
      checks++;
      if (g_io_in_3_tx_dat_ready !== i_io_in_3_tx_dat_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_tx_dat_ready g=%0h i=%0h", $time, g_io_in_3_tx_dat_ready, i_io_in_3_tx_dat_ready);
      end
    end
    if (!$isunknown(g_io_in_3_rx_rsp_valid)) begin
      checks++;
      if (g_io_in_3_rx_rsp_valid !== i_io_in_3_rx_rsp_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_rx_rsp_valid g=%0h i=%0h", $time, g_io_in_3_rx_rsp_valid, i_io_in_3_rx_rsp_valid);
      end
    end
    if (!$isunknown(g_io_in_3_rx_rsp_bits_srcID)) begin
      checks++;
      if (g_io_in_3_rx_rsp_bits_srcID !== i_io_in_3_rx_rsp_bits_srcID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_rx_rsp_bits_srcID g=%0h i=%0h", $time, g_io_in_3_rx_rsp_bits_srcID, i_io_in_3_rx_rsp_bits_srcID);
      end
    end
    if (!$isunknown(g_io_in_3_rx_rsp_bits_txnID)) begin
      checks++;
      if (g_io_in_3_rx_rsp_bits_txnID !== i_io_in_3_rx_rsp_bits_txnID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_rx_rsp_bits_txnID g=%0h i=%0h", $time, g_io_in_3_rx_rsp_bits_txnID, i_io_in_3_rx_rsp_bits_txnID);
      end
    end
    if (!$isunknown(g_io_in_3_rx_rsp_bits_opcode)) begin
      checks++;
      if (g_io_in_3_rx_rsp_bits_opcode !== i_io_in_3_rx_rsp_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_rx_rsp_bits_opcode g=%0h i=%0h", $time, g_io_in_3_rx_rsp_bits_opcode, i_io_in_3_rx_rsp_bits_opcode);
      end
    end
    if (!$isunknown(g_io_in_3_rx_rsp_bits_dbID)) begin
      checks++;
      if (g_io_in_3_rx_rsp_bits_dbID !== i_io_in_3_rx_rsp_bits_dbID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_rx_rsp_bits_dbID g=%0h i=%0h", $time, g_io_in_3_rx_rsp_bits_dbID, i_io_in_3_rx_rsp_bits_dbID);
      end
    end
    if (!$isunknown(g_io_in_3_rx_dat_valid)) begin
      checks++;
      if (g_io_in_3_rx_dat_valid !== i_io_in_3_rx_dat_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_rx_dat_valid g=%0h i=%0h", $time, g_io_in_3_rx_dat_valid, i_io_in_3_rx_dat_valid);
      end
    end
    if (!$isunknown(g_io_in_3_rx_dat_bits_srcID)) begin
      checks++;
      if (g_io_in_3_rx_dat_bits_srcID !== i_io_in_3_rx_dat_bits_srcID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_rx_dat_bits_srcID g=%0h i=%0h", $time, g_io_in_3_rx_dat_bits_srcID, i_io_in_3_rx_dat_bits_srcID);
      end
    end
    if (!$isunknown(g_io_in_3_rx_dat_bits_txnID)) begin
      checks++;
      if (g_io_in_3_rx_dat_bits_txnID !== i_io_in_3_rx_dat_bits_txnID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_rx_dat_bits_txnID g=%0h i=%0h", $time, g_io_in_3_rx_dat_bits_txnID, i_io_in_3_rx_dat_bits_txnID);
      end
    end
    if (!$isunknown(g_io_in_3_rx_dat_bits_opcode)) begin
      checks++;
      if (g_io_in_3_rx_dat_bits_opcode !== i_io_in_3_rx_dat_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_rx_dat_bits_opcode g=%0h i=%0h", $time, g_io_in_3_rx_dat_bits_opcode, i_io_in_3_rx_dat_bits_opcode);
      end
    end
    if (!$isunknown(g_io_in_3_rx_dat_bits_resp)) begin
      checks++;
      if (g_io_in_3_rx_dat_bits_resp !== i_io_in_3_rx_dat_bits_resp) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_rx_dat_bits_resp g=%0h i=%0h", $time, g_io_in_3_rx_dat_bits_resp, i_io_in_3_rx_dat_bits_resp);
      end
    end
    if (!$isunknown(g_io_in_3_rx_dat_bits_dataID)) begin
      checks++;
      if (g_io_in_3_rx_dat_bits_dataID !== i_io_in_3_rx_dat_bits_dataID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_rx_dat_bits_dataID g=%0h i=%0h", $time, g_io_in_3_rx_dat_bits_dataID, i_io_in_3_rx_dat_bits_dataID);
      end
    end
    if (!$isunknown(g_io_in_3_rx_dat_bits_data)) begin
      checks++;
      if (g_io_in_3_rx_dat_bits_data !== i_io_in_3_rx_dat_bits_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_3_rx_dat_bits_data g=%0h i=%0h", $time, g_io_in_3_rx_dat_bits_data, i_io_in_3_rx_dat_bits_data);
      end
    end
    if (!$isunknown(g_io_out_tx_req_valid)) begin
      checks++;
      if (g_io_out_tx_req_valid !== i_io_out_tx_req_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_valid g=%0h i=%0h", $time, g_io_out_tx_req_valid, i_io_out_tx_req_valid);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_tgtID)) begin
      checks++;
      if (g_io_out_tx_req_bits_tgtID !== i_io_out_tx_req_bits_tgtID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_tgtID g=%0h i=%0h", $time, g_io_out_tx_req_bits_tgtID, i_io_out_tx_req_bits_tgtID);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_srcID)) begin
      checks++;
      if (g_io_out_tx_req_bits_srcID !== i_io_out_tx_req_bits_srcID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_srcID g=%0h i=%0h", $time, g_io_out_tx_req_bits_srcID, i_io_out_tx_req_bits_srcID);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_txnID)) begin
      checks++;
      if (g_io_out_tx_req_bits_txnID !== i_io_out_tx_req_bits_txnID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_txnID g=%0h i=%0h", $time, g_io_out_tx_req_bits_txnID, i_io_out_tx_req_bits_txnID);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_opcode)) begin
      checks++;
      if (g_io_out_tx_req_bits_opcode !== i_io_out_tx_req_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_opcode g=%0h i=%0h", $time, g_io_out_tx_req_bits_opcode, i_io_out_tx_req_bits_opcode);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_size)) begin
      checks++;
      if (g_io_out_tx_req_bits_size !== i_io_out_tx_req_bits_size) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_size g=%0h i=%0h", $time, g_io_out_tx_req_bits_size, i_io_out_tx_req_bits_size);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_addr)) begin
      checks++;
      if (g_io_out_tx_req_bits_addr !== i_io_out_tx_req_bits_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_addr g=%0h i=%0h", $time, g_io_out_tx_req_bits_addr, i_io_out_tx_req_bits_addr);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_allowRetry)) begin
      checks++;
      if (g_io_out_tx_req_bits_allowRetry !== i_io_out_tx_req_bits_allowRetry) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_allowRetry g=%0h i=%0h", $time, g_io_out_tx_req_bits_allowRetry, i_io_out_tx_req_bits_allowRetry);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_order)) begin
      checks++;
      if (g_io_out_tx_req_bits_order !== i_io_out_tx_req_bits_order) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_order g=%0h i=%0h", $time, g_io_out_tx_req_bits_order, i_io_out_tx_req_bits_order);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_pCrdType)) begin
      checks++;
      if (g_io_out_tx_req_bits_pCrdType !== i_io_out_tx_req_bits_pCrdType) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_pCrdType g=%0h i=%0h", $time, g_io_out_tx_req_bits_pCrdType, i_io_out_tx_req_bits_pCrdType);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_memAttr_allocate)) begin
      checks++;
      if (g_io_out_tx_req_bits_memAttr_allocate !== i_io_out_tx_req_bits_memAttr_allocate) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_memAttr_allocate g=%0h i=%0h", $time, g_io_out_tx_req_bits_memAttr_allocate, i_io_out_tx_req_bits_memAttr_allocate);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_memAttr_cacheable)) begin
      checks++;
      if (g_io_out_tx_req_bits_memAttr_cacheable !== i_io_out_tx_req_bits_memAttr_cacheable) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_memAttr_cacheable g=%0h i=%0h", $time, g_io_out_tx_req_bits_memAttr_cacheable, i_io_out_tx_req_bits_memAttr_cacheable);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_memAttr_device)) begin
      checks++;
      if (g_io_out_tx_req_bits_memAttr_device !== i_io_out_tx_req_bits_memAttr_device) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_memAttr_device g=%0h i=%0h", $time, g_io_out_tx_req_bits_memAttr_device, i_io_out_tx_req_bits_memAttr_device);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_memAttr_ewa)) begin
      checks++;
      if (g_io_out_tx_req_bits_memAttr_ewa !== i_io_out_tx_req_bits_memAttr_ewa) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_memAttr_ewa g=%0h i=%0h", $time, g_io_out_tx_req_bits_memAttr_ewa, i_io_out_tx_req_bits_memAttr_ewa);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_snpAttr)) begin
      checks++;
      if (g_io_out_tx_req_bits_snpAttr !== i_io_out_tx_req_bits_snpAttr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_snpAttr g=%0h i=%0h", $time, g_io_out_tx_req_bits_snpAttr, i_io_out_tx_req_bits_snpAttr);
      end
    end
    if (!$isunknown(g_io_out_tx_req_bits_expCompAck)) begin
      checks++;
      if (g_io_out_tx_req_bits_expCompAck !== i_io_out_tx_req_bits_expCompAck) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_req_bits_expCompAck g=%0h i=%0h", $time, g_io_out_tx_req_bits_expCompAck, i_io_out_tx_req_bits_expCompAck);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_valid)) begin
      checks++;
      if (g_io_out_tx_dat_valid !== i_io_out_tx_dat_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_valid g=%0h i=%0h", $time, g_io_out_tx_dat_valid, i_io_out_tx_dat_valid);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_bits_tgtID)) begin
      checks++;
      if (g_io_out_tx_dat_bits_tgtID !== i_io_out_tx_dat_bits_tgtID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_bits_tgtID g=%0h i=%0h", $time, g_io_out_tx_dat_bits_tgtID, i_io_out_tx_dat_bits_tgtID);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_bits_srcID)) begin
      checks++;
      if (g_io_out_tx_dat_bits_srcID !== i_io_out_tx_dat_bits_srcID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_bits_srcID g=%0h i=%0h", $time, g_io_out_tx_dat_bits_srcID, i_io_out_tx_dat_bits_srcID);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_bits_txnID)) begin
      checks++;
      if (g_io_out_tx_dat_bits_txnID !== i_io_out_tx_dat_bits_txnID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_bits_txnID g=%0h i=%0h", $time, g_io_out_tx_dat_bits_txnID, i_io_out_tx_dat_bits_txnID);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_bits_homeNID)) begin
      checks++;
      if (g_io_out_tx_dat_bits_homeNID !== i_io_out_tx_dat_bits_homeNID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_bits_homeNID g=%0h i=%0h", $time, g_io_out_tx_dat_bits_homeNID, i_io_out_tx_dat_bits_homeNID);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_bits_opcode)) begin
      checks++;
      if (g_io_out_tx_dat_bits_opcode !== i_io_out_tx_dat_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_bits_opcode g=%0h i=%0h", $time, g_io_out_tx_dat_bits_opcode, i_io_out_tx_dat_bits_opcode);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_bits_resp)) begin
      checks++;
      if (g_io_out_tx_dat_bits_resp !== i_io_out_tx_dat_bits_resp) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_bits_resp g=%0h i=%0h", $time, g_io_out_tx_dat_bits_resp, i_io_out_tx_dat_bits_resp);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_bits_dataSource)) begin
      checks++;
      if (g_io_out_tx_dat_bits_dataSource !== i_io_out_tx_dat_bits_dataSource) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_bits_dataSource g=%0h i=%0h", $time, g_io_out_tx_dat_bits_dataSource, i_io_out_tx_dat_bits_dataSource);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_bits_dbID)) begin
      checks++;
      if (g_io_out_tx_dat_bits_dbID !== i_io_out_tx_dat_bits_dbID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_bits_dbID g=%0h i=%0h", $time, g_io_out_tx_dat_bits_dbID, i_io_out_tx_dat_bits_dbID);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_bits_dataID)) begin
      checks++;
      if (g_io_out_tx_dat_bits_dataID !== i_io_out_tx_dat_bits_dataID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_bits_dataID g=%0h i=%0h", $time, g_io_out_tx_dat_bits_dataID, i_io_out_tx_dat_bits_dataID);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_bits_be)) begin
      checks++;
      if (g_io_out_tx_dat_bits_be !== i_io_out_tx_dat_bits_be) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_bits_be g=%0h i=%0h", $time, g_io_out_tx_dat_bits_be, i_io_out_tx_dat_bits_be);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_bits_data)) begin
      checks++;
      if (g_io_out_tx_dat_bits_data !== i_io_out_tx_dat_bits_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_bits_data g=%0h i=%0h", $time, g_io_out_tx_dat_bits_data, i_io_out_tx_dat_bits_data);
      end
    end
    if (!$isunknown(g_io_out_tx_dat_bits_dataCheck)) begin
      checks++;
      if (g_io_out_tx_dat_bits_dataCheck !== i_io_out_tx_dat_bits_dataCheck) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_tx_dat_bits_dataCheck g=%0h i=%0h", $time, g_io_out_tx_dat_bits_dataCheck, i_io_out_tx_dat_bits_dataCheck);
      end
    end
    if (!$isunknown(g_io_out_rx_rsp_ready)) begin
      checks++;
      if (g_io_out_rx_rsp_ready !== i_io_out_rx_rsp_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_rx_rsp_ready g=%0h i=%0h", $time, g_io_out_rx_rsp_ready, i_io_out_rx_rsp_ready);
      end
    end
    if (!$isunknown(g_io_out_rx_dat_ready)) begin
      checks++;
      if (g_io_out_rx_dat_ready !== i_io_out_rx_dat_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_rx_dat_ready g=%0h i=%0h", $time, g_io_out_rx_dat_ready, i_io_out_rx_dat_ready);
      end
    end
  endtask

  task automatic sample_coverage();
    if (g_io_in_0_tx_req_ready !== p_io_in_0_tx_req_ready) tog_io_in_0_tx_req_ready = 1'b1;
    p_io_in_0_tx_req_ready = g_io_in_0_tx_req_ready;
    if (g_io_in_0_tx_dat_ready !== p_io_in_0_tx_dat_ready) tog_io_in_0_tx_dat_ready = 1'b1;
    p_io_in_0_tx_dat_ready = g_io_in_0_tx_dat_ready;
    if (g_io_in_0_rx_rsp_valid !== p_io_in_0_rx_rsp_valid) tog_io_in_0_rx_rsp_valid = 1'b1;
    p_io_in_0_rx_rsp_valid = g_io_in_0_rx_rsp_valid;
    if (g_io_in_0_rx_rsp_bits_srcID !== p_io_in_0_rx_rsp_bits_srcID) tog_io_in_0_rx_rsp_bits_srcID = 1'b1;
    p_io_in_0_rx_rsp_bits_srcID = g_io_in_0_rx_rsp_bits_srcID;
    if (g_io_in_0_rx_rsp_bits_txnID !== p_io_in_0_rx_rsp_bits_txnID) tog_io_in_0_rx_rsp_bits_txnID = 1'b1;
    p_io_in_0_rx_rsp_bits_txnID = g_io_in_0_rx_rsp_bits_txnID;
    if (g_io_in_0_rx_rsp_bits_opcode !== p_io_in_0_rx_rsp_bits_opcode) tog_io_in_0_rx_rsp_bits_opcode = 1'b1;
    p_io_in_0_rx_rsp_bits_opcode = g_io_in_0_rx_rsp_bits_opcode;
    if (g_io_in_0_rx_rsp_bits_dbID !== p_io_in_0_rx_rsp_bits_dbID) tog_io_in_0_rx_rsp_bits_dbID = 1'b1;
    p_io_in_0_rx_rsp_bits_dbID = g_io_in_0_rx_rsp_bits_dbID;
    if (g_io_in_0_rx_dat_valid !== p_io_in_0_rx_dat_valid) tog_io_in_0_rx_dat_valid = 1'b1;
    p_io_in_0_rx_dat_valid = g_io_in_0_rx_dat_valid;
    if (g_io_in_0_rx_dat_bits_srcID !== p_io_in_0_rx_dat_bits_srcID) tog_io_in_0_rx_dat_bits_srcID = 1'b1;
    p_io_in_0_rx_dat_bits_srcID = g_io_in_0_rx_dat_bits_srcID;
    if (g_io_in_0_rx_dat_bits_txnID !== p_io_in_0_rx_dat_bits_txnID) tog_io_in_0_rx_dat_bits_txnID = 1'b1;
    p_io_in_0_rx_dat_bits_txnID = g_io_in_0_rx_dat_bits_txnID;
    if (g_io_in_0_rx_dat_bits_opcode !== p_io_in_0_rx_dat_bits_opcode) tog_io_in_0_rx_dat_bits_opcode = 1'b1;
    p_io_in_0_rx_dat_bits_opcode = g_io_in_0_rx_dat_bits_opcode;
    if (g_io_in_0_rx_dat_bits_resp !== p_io_in_0_rx_dat_bits_resp) tog_io_in_0_rx_dat_bits_resp = 1'b1;
    p_io_in_0_rx_dat_bits_resp = g_io_in_0_rx_dat_bits_resp;
    if (g_io_in_0_rx_dat_bits_dataID !== p_io_in_0_rx_dat_bits_dataID) tog_io_in_0_rx_dat_bits_dataID = 1'b1;
    p_io_in_0_rx_dat_bits_dataID = g_io_in_0_rx_dat_bits_dataID;
    if (g_io_in_0_rx_dat_bits_data !== p_io_in_0_rx_dat_bits_data) tog_io_in_0_rx_dat_bits_data = 1'b1;
    p_io_in_0_rx_dat_bits_data = g_io_in_0_rx_dat_bits_data;
    if (g_io_in_1_tx_req_ready !== p_io_in_1_tx_req_ready) tog_io_in_1_tx_req_ready = 1'b1;
    p_io_in_1_tx_req_ready = g_io_in_1_tx_req_ready;
    if (g_io_in_1_tx_dat_ready !== p_io_in_1_tx_dat_ready) tog_io_in_1_tx_dat_ready = 1'b1;
    p_io_in_1_tx_dat_ready = g_io_in_1_tx_dat_ready;
    if (g_io_in_1_rx_rsp_valid !== p_io_in_1_rx_rsp_valid) tog_io_in_1_rx_rsp_valid = 1'b1;
    p_io_in_1_rx_rsp_valid = g_io_in_1_rx_rsp_valid;
    if (g_io_in_1_rx_rsp_bits_srcID !== p_io_in_1_rx_rsp_bits_srcID) tog_io_in_1_rx_rsp_bits_srcID = 1'b1;
    p_io_in_1_rx_rsp_bits_srcID = g_io_in_1_rx_rsp_bits_srcID;
    if (g_io_in_1_rx_rsp_bits_txnID !== p_io_in_1_rx_rsp_bits_txnID) tog_io_in_1_rx_rsp_bits_txnID = 1'b1;
    p_io_in_1_rx_rsp_bits_txnID = g_io_in_1_rx_rsp_bits_txnID;
    if (g_io_in_1_rx_rsp_bits_opcode !== p_io_in_1_rx_rsp_bits_opcode) tog_io_in_1_rx_rsp_bits_opcode = 1'b1;
    p_io_in_1_rx_rsp_bits_opcode = g_io_in_1_rx_rsp_bits_opcode;
    if (g_io_in_1_rx_rsp_bits_dbID !== p_io_in_1_rx_rsp_bits_dbID) tog_io_in_1_rx_rsp_bits_dbID = 1'b1;
    p_io_in_1_rx_rsp_bits_dbID = g_io_in_1_rx_rsp_bits_dbID;
    if (g_io_in_1_rx_dat_valid !== p_io_in_1_rx_dat_valid) tog_io_in_1_rx_dat_valid = 1'b1;
    p_io_in_1_rx_dat_valid = g_io_in_1_rx_dat_valid;
    if (g_io_in_1_rx_dat_bits_srcID !== p_io_in_1_rx_dat_bits_srcID) tog_io_in_1_rx_dat_bits_srcID = 1'b1;
    p_io_in_1_rx_dat_bits_srcID = g_io_in_1_rx_dat_bits_srcID;
    if (g_io_in_1_rx_dat_bits_txnID !== p_io_in_1_rx_dat_bits_txnID) tog_io_in_1_rx_dat_bits_txnID = 1'b1;
    p_io_in_1_rx_dat_bits_txnID = g_io_in_1_rx_dat_bits_txnID;
    if (g_io_in_1_rx_dat_bits_opcode !== p_io_in_1_rx_dat_bits_opcode) tog_io_in_1_rx_dat_bits_opcode = 1'b1;
    p_io_in_1_rx_dat_bits_opcode = g_io_in_1_rx_dat_bits_opcode;
    if (g_io_in_1_rx_dat_bits_resp !== p_io_in_1_rx_dat_bits_resp) tog_io_in_1_rx_dat_bits_resp = 1'b1;
    p_io_in_1_rx_dat_bits_resp = g_io_in_1_rx_dat_bits_resp;
    if (g_io_in_1_rx_dat_bits_dataID !== p_io_in_1_rx_dat_bits_dataID) tog_io_in_1_rx_dat_bits_dataID = 1'b1;
    p_io_in_1_rx_dat_bits_dataID = g_io_in_1_rx_dat_bits_dataID;
    if (g_io_in_1_rx_dat_bits_data !== p_io_in_1_rx_dat_bits_data) tog_io_in_1_rx_dat_bits_data = 1'b1;
    p_io_in_1_rx_dat_bits_data = g_io_in_1_rx_dat_bits_data;
    if (g_io_in_2_tx_req_ready !== p_io_in_2_tx_req_ready) tog_io_in_2_tx_req_ready = 1'b1;
    p_io_in_2_tx_req_ready = g_io_in_2_tx_req_ready;
    if (g_io_in_2_tx_dat_ready !== p_io_in_2_tx_dat_ready) tog_io_in_2_tx_dat_ready = 1'b1;
    p_io_in_2_tx_dat_ready = g_io_in_2_tx_dat_ready;
    if (g_io_in_2_rx_rsp_valid !== p_io_in_2_rx_rsp_valid) tog_io_in_2_rx_rsp_valid = 1'b1;
    p_io_in_2_rx_rsp_valid = g_io_in_2_rx_rsp_valid;
    if (g_io_in_2_rx_rsp_bits_srcID !== p_io_in_2_rx_rsp_bits_srcID) tog_io_in_2_rx_rsp_bits_srcID = 1'b1;
    p_io_in_2_rx_rsp_bits_srcID = g_io_in_2_rx_rsp_bits_srcID;
    if (g_io_in_2_rx_rsp_bits_txnID !== p_io_in_2_rx_rsp_bits_txnID) tog_io_in_2_rx_rsp_bits_txnID = 1'b1;
    p_io_in_2_rx_rsp_bits_txnID = g_io_in_2_rx_rsp_bits_txnID;
    if (g_io_in_2_rx_rsp_bits_opcode !== p_io_in_2_rx_rsp_bits_opcode) tog_io_in_2_rx_rsp_bits_opcode = 1'b1;
    p_io_in_2_rx_rsp_bits_opcode = g_io_in_2_rx_rsp_bits_opcode;
    if (g_io_in_2_rx_rsp_bits_dbID !== p_io_in_2_rx_rsp_bits_dbID) tog_io_in_2_rx_rsp_bits_dbID = 1'b1;
    p_io_in_2_rx_rsp_bits_dbID = g_io_in_2_rx_rsp_bits_dbID;
    if (g_io_in_2_rx_dat_valid !== p_io_in_2_rx_dat_valid) tog_io_in_2_rx_dat_valid = 1'b1;
    p_io_in_2_rx_dat_valid = g_io_in_2_rx_dat_valid;
    if (g_io_in_2_rx_dat_bits_srcID !== p_io_in_2_rx_dat_bits_srcID) tog_io_in_2_rx_dat_bits_srcID = 1'b1;
    p_io_in_2_rx_dat_bits_srcID = g_io_in_2_rx_dat_bits_srcID;
    if (g_io_in_2_rx_dat_bits_txnID !== p_io_in_2_rx_dat_bits_txnID) tog_io_in_2_rx_dat_bits_txnID = 1'b1;
    p_io_in_2_rx_dat_bits_txnID = g_io_in_2_rx_dat_bits_txnID;
    if (g_io_in_2_rx_dat_bits_opcode !== p_io_in_2_rx_dat_bits_opcode) tog_io_in_2_rx_dat_bits_opcode = 1'b1;
    p_io_in_2_rx_dat_bits_opcode = g_io_in_2_rx_dat_bits_opcode;
    if (g_io_in_2_rx_dat_bits_resp !== p_io_in_2_rx_dat_bits_resp) tog_io_in_2_rx_dat_bits_resp = 1'b1;
    p_io_in_2_rx_dat_bits_resp = g_io_in_2_rx_dat_bits_resp;
    if (g_io_in_2_rx_dat_bits_dataID !== p_io_in_2_rx_dat_bits_dataID) tog_io_in_2_rx_dat_bits_dataID = 1'b1;
    p_io_in_2_rx_dat_bits_dataID = g_io_in_2_rx_dat_bits_dataID;
    if (g_io_in_2_rx_dat_bits_data !== p_io_in_2_rx_dat_bits_data) tog_io_in_2_rx_dat_bits_data = 1'b1;
    p_io_in_2_rx_dat_bits_data = g_io_in_2_rx_dat_bits_data;
    if (g_io_in_3_tx_req_ready !== p_io_in_3_tx_req_ready) tog_io_in_3_tx_req_ready = 1'b1;
    p_io_in_3_tx_req_ready = g_io_in_3_tx_req_ready;
    if (g_io_in_3_tx_dat_ready !== p_io_in_3_tx_dat_ready) tog_io_in_3_tx_dat_ready = 1'b1;
    p_io_in_3_tx_dat_ready = g_io_in_3_tx_dat_ready;
    if (g_io_in_3_rx_rsp_valid !== p_io_in_3_rx_rsp_valid) tog_io_in_3_rx_rsp_valid = 1'b1;
    p_io_in_3_rx_rsp_valid = g_io_in_3_rx_rsp_valid;
    if (g_io_in_3_rx_rsp_bits_srcID !== p_io_in_3_rx_rsp_bits_srcID) tog_io_in_3_rx_rsp_bits_srcID = 1'b1;
    p_io_in_3_rx_rsp_bits_srcID = g_io_in_3_rx_rsp_bits_srcID;
    if (g_io_in_3_rx_rsp_bits_txnID !== p_io_in_3_rx_rsp_bits_txnID) tog_io_in_3_rx_rsp_bits_txnID = 1'b1;
    p_io_in_3_rx_rsp_bits_txnID = g_io_in_3_rx_rsp_bits_txnID;
    if (g_io_in_3_rx_rsp_bits_opcode !== p_io_in_3_rx_rsp_bits_opcode) tog_io_in_3_rx_rsp_bits_opcode = 1'b1;
    p_io_in_3_rx_rsp_bits_opcode = g_io_in_3_rx_rsp_bits_opcode;
    if (g_io_in_3_rx_rsp_bits_dbID !== p_io_in_3_rx_rsp_bits_dbID) tog_io_in_3_rx_rsp_bits_dbID = 1'b1;
    p_io_in_3_rx_rsp_bits_dbID = g_io_in_3_rx_rsp_bits_dbID;
    if (g_io_in_3_rx_dat_valid !== p_io_in_3_rx_dat_valid) tog_io_in_3_rx_dat_valid = 1'b1;
    p_io_in_3_rx_dat_valid = g_io_in_3_rx_dat_valid;
    if (g_io_in_3_rx_dat_bits_srcID !== p_io_in_3_rx_dat_bits_srcID) tog_io_in_3_rx_dat_bits_srcID = 1'b1;
    p_io_in_3_rx_dat_bits_srcID = g_io_in_3_rx_dat_bits_srcID;
    if (g_io_in_3_rx_dat_bits_txnID !== p_io_in_3_rx_dat_bits_txnID) tog_io_in_3_rx_dat_bits_txnID = 1'b1;
    p_io_in_3_rx_dat_bits_txnID = g_io_in_3_rx_dat_bits_txnID;
    if (g_io_in_3_rx_dat_bits_opcode !== p_io_in_3_rx_dat_bits_opcode) tog_io_in_3_rx_dat_bits_opcode = 1'b1;
    p_io_in_3_rx_dat_bits_opcode = g_io_in_3_rx_dat_bits_opcode;
    if (g_io_in_3_rx_dat_bits_resp !== p_io_in_3_rx_dat_bits_resp) tog_io_in_3_rx_dat_bits_resp = 1'b1;
    p_io_in_3_rx_dat_bits_resp = g_io_in_3_rx_dat_bits_resp;
    if (g_io_in_3_rx_dat_bits_dataID !== p_io_in_3_rx_dat_bits_dataID) tog_io_in_3_rx_dat_bits_dataID = 1'b1;
    p_io_in_3_rx_dat_bits_dataID = g_io_in_3_rx_dat_bits_dataID;
    if (g_io_in_3_rx_dat_bits_data !== p_io_in_3_rx_dat_bits_data) tog_io_in_3_rx_dat_bits_data = 1'b1;
    p_io_in_3_rx_dat_bits_data = g_io_in_3_rx_dat_bits_data;
    if (g_io_out_tx_req_valid !== p_io_out_tx_req_valid) tog_io_out_tx_req_valid = 1'b1;
    p_io_out_tx_req_valid = g_io_out_tx_req_valid;
    if (g_io_out_tx_req_bits_tgtID !== p_io_out_tx_req_bits_tgtID) tog_io_out_tx_req_bits_tgtID = 1'b1;
    p_io_out_tx_req_bits_tgtID = g_io_out_tx_req_bits_tgtID;
    if (g_io_out_tx_req_bits_srcID !== p_io_out_tx_req_bits_srcID) tog_io_out_tx_req_bits_srcID = 1'b1;
    p_io_out_tx_req_bits_srcID = g_io_out_tx_req_bits_srcID;
    if (g_io_out_tx_req_bits_txnID !== p_io_out_tx_req_bits_txnID) tog_io_out_tx_req_bits_txnID = 1'b1;
    p_io_out_tx_req_bits_txnID = g_io_out_tx_req_bits_txnID;
    if (g_io_out_tx_req_bits_opcode !== p_io_out_tx_req_bits_opcode) tog_io_out_tx_req_bits_opcode = 1'b1;
    p_io_out_tx_req_bits_opcode = g_io_out_tx_req_bits_opcode;
    if (g_io_out_tx_req_bits_size !== p_io_out_tx_req_bits_size) tog_io_out_tx_req_bits_size = 1'b1;
    p_io_out_tx_req_bits_size = g_io_out_tx_req_bits_size;
    if (g_io_out_tx_req_bits_addr !== p_io_out_tx_req_bits_addr) tog_io_out_tx_req_bits_addr = 1'b1;
    p_io_out_tx_req_bits_addr = g_io_out_tx_req_bits_addr;
    if (g_io_out_tx_req_bits_allowRetry !== p_io_out_tx_req_bits_allowRetry) tog_io_out_tx_req_bits_allowRetry = 1'b1;
    p_io_out_tx_req_bits_allowRetry = g_io_out_tx_req_bits_allowRetry;
    if (g_io_out_tx_req_bits_order !== p_io_out_tx_req_bits_order) tog_io_out_tx_req_bits_order = 1'b1;
    p_io_out_tx_req_bits_order = g_io_out_tx_req_bits_order;
    if (g_io_out_tx_req_bits_pCrdType !== p_io_out_tx_req_bits_pCrdType) tog_io_out_tx_req_bits_pCrdType = 1'b1;
    p_io_out_tx_req_bits_pCrdType = g_io_out_tx_req_bits_pCrdType;
    if (g_io_out_tx_req_bits_memAttr_allocate !== p_io_out_tx_req_bits_memAttr_allocate) tog_io_out_tx_req_bits_memAttr_allocate = 1'b1;
    p_io_out_tx_req_bits_memAttr_allocate = g_io_out_tx_req_bits_memAttr_allocate;
    if (g_io_out_tx_req_bits_memAttr_cacheable !== p_io_out_tx_req_bits_memAttr_cacheable) tog_io_out_tx_req_bits_memAttr_cacheable = 1'b1;
    p_io_out_tx_req_bits_memAttr_cacheable = g_io_out_tx_req_bits_memAttr_cacheable;
    if (g_io_out_tx_req_bits_memAttr_device !== p_io_out_tx_req_bits_memAttr_device) tog_io_out_tx_req_bits_memAttr_device = 1'b1;
    p_io_out_tx_req_bits_memAttr_device = g_io_out_tx_req_bits_memAttr_device;
    if (g_io_out_tx_req_bits_memAttr_ewa !== p_io_out_tx_req_bits_memAttr_ewa) tog_io_out_tx_req_bits_memAttr_ewa = 1'b1;
    p_io_out_tx_req_bits_memAttr_ewa = g_io_out_tx_req_bits_memAttr_ewa;
    if (g_io_out_tx_req_bits_snpAttr !== p_io_out_tx_req_bits_snpAttr) tog_io_out_tx_req_bits_snpAttr = 1'b1;
    p_io_out_tx_req_bits_snpAttr = g_io_out_tx_req_bits_snpAttr;
    if (g_io_out_tx_req_bits_expCompAck !== p_io_out_tx_req_bits_expCompAck) tog_io_out_tx_req_bits_expCompAck = 1'b1;
    p_io_out_tx_req_bits_expCompAck = g_io_out_tx_req_bits_expCompAck;
    if (g_io_out_tx_dat_valid !== p_io_out_tx_dat_valid) tog_io_out_tx_dat_valid = 1'b1;
    p_io_out_tx_dat_valid = g_io_out_tx_dat_valid;
    if (g_io_out_tx_dat_bits_tgtID !== p_io_out_tx_dat_bits_tgtID) tog_io_out_tx_dat_bits_tgtID = 1'b1;
    p_io_out_tx_dat_bits_tgtID = g_io_out_tx_dat_bits_tgtID;
    if (g_io_out_tx_dat_bits_srcID !== p_io_out_tx_dat_bits_srcID) tog_io_out_tx_dat_bits_srcID = 1'b1;
    p_io_out_tx_dat_bits_srcID = g_io_out_tx_dat_bits_srcID;
    if (g_io_out_tx_dat_bits_txnID !== p_io_out_tx_dat_bits_txnID) tog_io_out_tx_dat_bits_txnID = 1'b1;
    p_io_out_tx_dat_bits_txnID = g_io_out_tx_dat_bits_txnID;
    if (g_io_out_tx_dat_bits_homeNID !== p_io_out_tx_dat_bits_homeNID) tog_io_out_tx_dat_bits_homeNID = 1'b1;
    p_io_out_tx_dat_bits_homeNID = g_io_out_tx_dat_bits_homeNID;
    if (g_io_out_tx_dat_bits_opcode !== p_io_out_tx_dat_bits_opcode) tog_io_out_tx_dat_bits_opcode = 1'b1;
    p_io_out_tx_dat_bits_opcode = g_io_out_tx_dat_bits_opcode;
    if (g_io_out_tx_dat_bits_resp !== p_io_out_tx_dat_bits_resp) tog_io_out_tx_dat_bits_resp = 1'b1;
    p_io_out_tx_dat_bits_resp = g_io_out_tx_dat_bits_resp;
    if (g_io_out_tx_dat_bits_dataSource !== p_io_out_tx_dat_bits_dataSource) tog_io_out_tx_dat_bits_dataSource = 1'b1;
    p_io_out_tx_dat_bits_dataSource = g_io_out_tx_dat_bits_dataSource;
    if (g_io_out_tx_dat_bits_dbID !== p_io_out_tx_dat_bits_dbID) tog_io_out_tx_dat_bits_dbID = 1'b1;
    p_io_out_tx_dat_bits_dbID = g_io_out_tx_dat_bits_dbID;
    if (g_io_out_tx_dat_bits_dataID !== p_io_out_tx_dat_bits_dataID) tog_io_out_tx_dat_bits_dataID = 1'b1;
    p_io_out_tx_dat_bits_dataID = g_io_out_tx_dat_bits_dataID;
    if (g_io_out_tx_dat_bits_be !== p_io_out_tx_dat_bits_be) tog_io_out_tx_dat_bits_be = 1'b1;
    p_io_out_tx_dat_bits_be = g_io_out_tx_dat_bits_be;
    if (g_io_out_tx_dat_bits_data !== p_io_out_tx_dat_bits_data) tog_io_out_tx_dat_bits_data = 1'b1;
    p_io_out_tx_dat_bits_data = g_io_out_tx_dat_bits_data;
    if (g_io_out_tx_dat_bits_dataCheck !== p_io_out_tx_dat_bits_dataCheck) tog_io_out_tx_dat_bits_dataCheck = 1'b1;
    p_io_out_tx_dat_bits_dataCheck = g_io_out_tx_dat_bits_dataCheck;
    if (g_io_out_rx_rsp_ready !== p_io_out_rx_rsp_ready) tog_io_out_rx_rsp_ready = 1'b1;
    p_io_out_rx_rsp_ready = g_io_out_rx_rsp_ready;
    if (g_io_out_rx_dat_ready !== p_io_out_rx_dat_ready) tog_io_out_rx_dat_ready = 1'b1;
    p_io_out_rx_dat_ready = g_io_out_rx_dat_ready;
    if ((g_io_in_0_tx_req_ready && io_in_0_tx_req_valid) ||
        (g_io_in_0_tx_dat_ready && io_in_0_tx_dat_valid) ||
        (g_io_in_1_tx_req_ready && io_in_1_tx_req_valid) ||
        (g_io_in_1_tx_dat_ready && io_in_1_tx_dat_valid) ||
        (g_io_in_2_tx_req_ready && io_in_2_tx_req_valid) ||
        (g_io_in_2_tx_dat_ready && io_in_2_tx_dat_valid) ||
        (g_io_in_3_tx_req_ready && io_in_3_tx_req_valid) ||
        (g_io_in_3_tx_dat_ready && io_in_3_tx_dat_valid) ||
        (g_io_out_rx_rsp_ready && io_out_rx_rsp_valid) ||
        (g_io_out_rx_dat_ready && io_out_rx_dat_valid) ||
        (g_io_out_tx_req_valid && io_out_tx_req_ready) ||
        (g_io_out_tx_dat_valid && io_out_tx_dat_ready)) fires++;
  endtask

  initial begin
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
    p_io_in_0_tx_req_ready = '0; tog_io_in_0_tx_req_ready = 1'b0;
    p_io_in_0_tx_dat_ready = '0; tog_io_in_0_tx_dat_ready = 1'b0;
    p_io_in_0_rx_rsp_valid = '0; tog_io_in_0_rx_rsp_valid = 1'b0;
    p_io_in_0_rx_rsp_bits_srcID = '0; tog_io_in_0_rx_rsp_bits_srcID = 1'b0;
    p_io_in_0_rx_rsp_bits_txnID = '0; tog_io_in_0_rx_rsp_bits_txnID = 1'b0;
    p_io_in_0_rx_rsp_bits_opcode = '0; tog_io_in_0_rx_rsp_bits_opcode = 1'b0;
    p_io_in_0_rx_rsp_bits_dbID = '0; tog_io_in_0_rx_rsp_bits_dbID = 1'b0;
    p_io_in_0_rx_dat_valid = '0; tog_io_in_0_rx_dat_valid = 1'b0;
    p_io_in_0_rx_dat_bits_srcID = '0; tog_io_in_0_rx_dat_bits_srcID = 1'b0;
    p_io_in_0_rx_dat_bits_txnID = '0; tog_io_in_0_rx_dat_bits_txnID = 1'b0;
    p_io_in_0_rx_dat_bits_opcode = '0; tog_io_in_0_rx_dat_bits_opcode = 1'b0;
    p_io_in_0_rx_dat_bits_resp = '0; tog_io_in_0_rx_dat_bits_resp = 1'b0;
    p_io_in_0_rx_dat_bits_dataID = '0; tog_io_in_0_rx_dat_bits_dataID = 1'b0;
    p_io_in_0_rx_dat_bits_data = '0; tog_io_in_0_rx_dat_bits_data = 1'b0;
    p_io_in_1_tx_req_ready = '0; tog_io_in_1_tx_req_ready = 1'b0;
    p_io_in_1_tx_dat_ready = '0; tog_io_in_1_tx_dat_ready = 1'b0;
    p_io_in_1_rx_rsp_valid = '0; tog_io_in_1_rx_rsp_valid = 1'b0;
    p_io_in_1_rx_rsp_bits_srcID = '0; tog_io_in_1_rx_rsp_bits_srcID = 1'b0;
    p_io_in_1_rx_rsp_bits_txnID = '0; tog_io_in_1_rx_rsp_bits_txnID = 1'b0;
    p_io_in_1_rx_rsp_bits_opcode = '0; tog_io_in_1_rx_rsp_bits_opcode = 1'b0;
    p_io_in_1_rx_rsp_bits_dbID = '0; tog_io_in_1_rx_rsp_bits_dbID = 1'b0;
    p_io_in_1_rx_dat_valid = '0; tog_io_in_1_rx_dat_valid = 1'b0;
    p_io_in_1_rx_dat_bits_srcID = '0; tog_io_in_1_rx_dat_bits_srcID = 1'b0;
    p_io_in_1_rx_dat_bits_txnID = '0; tog_io_in_1_rx_dat_bits_txnID = 1'b0;
    p_io_in_1_rx_dat_bits_opcode = '0; tog_io_in_1_rx_dat_bits_opcode = 1'b0;
    p_io_in_1_rx_dat_bits_resp = '0; tog_io_in_1_rx_dat_bits_resp = 1'b0;
    p_io_in_1_rx_dat_bits_dataID = '0; tog_io_in_1_rx_dat_bits_dataID = 1'b0;
    p_io_in_1_rx_dat_bits_data = '0; tog_io_in_1_rx_dat_bits_data = 1'b0;
    p_io_in_2_tx_req_ready = '0; tog_io_in_2_tx_req_ready = 1'b0;
    p_io_in_2_tx_dat_ready = '0; tog_io_in_2_tx_dat_ready = 1'b0;
    p_io_in_2_rx_rsp_valid = '0; tog_io_in_2_rx_rsp_valid = 1'b0;
    p_io_in_2_rx_rsp_bits_srcID = '0; tog_io_in_2_rx_rsp_bits_srcID = 1'b0;
    p_io_in_2_rx_rsp_bits_txnID = '0; tog_io_in_2_rx_rsp_bits_txnID = 1'b0;
    p_io_in_2_rx_rsp_bits_opcode = '0; tog_io_in_2_rx_rsp_bits_opcode = 1'b0;
    p_io_in_2_rx_rsp_bits_dbID = '0; tog_io_in_2_rx_rsp_bits_dbID = 1'b0;
    p_io_in_2_rx_dat_valid = '0; tog_io_in_2_rx_dat_valid = 1'b0;
    p_io_in_2_rx_dat_bits_srcID = '0; tog_io_in_2_rx_dat_bits_srcID = 1'b0;
    p_io_in_2_rx_dat_bits_txnID = '0; tog_io_in_2_rx_dat_bits_txnID = 1'b0;
    p_io_in_2_rx_dat_bits_opcode = '0; tog_io_in_2_rx_dat_bits_opcode = 1'b0;
    p_io_in_2_rx_dat_bits_resp = '0; tog_io_in_2_rx_dat_bits_resp = 1'b0;
    p_io_in_2_rx_dat_bits_dataID = '0; tog_io_in_2_rx_dat_bits_dataID = 1'b0;
    p_io_in_2_rx_dat_bits_data = '0; tog_io_in_2_rx_dat_bits_data = 1'b0;
    p_io_in_3_tx_req_ready = '0; tog_io_in_3_tx_req_ready = 1'b0;
    p_io_in_3_tx_dat_ready = '0; tog_io_in_3_tx_dat_ready = 1'b0;
    p_io_in_3_rx_rsp_valid = '0; tog_io_in_3_rx_rsp_valid = 1'b0;
    p_io_in_3_rx_rsp_bits_srcID = '0; tog_io_in_3_rx_rsp_bits_srcID = 1'b0;
    p_io_in_3_rx_rsp_bits_txnID = '0; tog_io_in_3_rx_rsp_bits_txnID = 1'b0;
    p_io_in_3_rx_rsp_bits_opcode = '0; tog_io_in_3_rx_rsp_bits_opcode = 1'b0;
    p_io_in_3_rx_rsp_bits_dbID = '0; tog_io_in_3_rx_rsp_bits_dbID = 1'b0;
    p_io_in_3_rx_dat_valid = '0; tog_io_in_3_rx_dat_valid = 1'b0;
    p_io_in_3_rx_dat_bits_srcID = '0; tog_io_in_3_rx_dat_bits_srcID = 1'b0;
    p_io_in_3_rx_dat_bits_txnID = '0; tog_io_in_3_rx_dat_bits_txnID = 1'b0;
    p_io_in_3_rx_dat_bits_opcode = '0; tog_io_in_3_rx_dat_bits_opcode = 1'b0;
    p_io_in_3_rx_dat_bits_resp = '0; tog_io_in_3_rx_dat_bits_resp = 1'b0;
    p_io_in_3_rx_dat_bits_dataID = '0; tog_io_in_3_rx_dat_bits_dataID = 1'b0;
    p_io_in_3_rx_dat_bits_data = '0; tog_io_in_3_rx_dat_bits_data = 1'b0;
    p_io_out_tx_req_valid = '0; tog_io_out_tx_req_valid = 1'b0;
    p_io_out_tx_req_bits_tgtID = '0; tog_io_out_tx_req_bits_tgtID = 1'b0;
    p_io_out_tx_req_bits_srcID = '0; tog_io_out_tx_req_bits_srcID = 1'b0;
    p_io_out_tx_req_bits_txnID = '0; tog_io_out_tx_req_bits_txnID = 1'b0;
    p_io_out_tx_req_bits_opcode = '0; tog_io_out_tx_req_bits_opcode = 1'b0;
    p_io_out_tx_req_bits_size = '0; tog_io_out_tx_req_bits_size = 1'b0;
    p_io_out_tx_req_bits_addr = '0; tog_io_out_tx_req_bits_addr = 1'b0;
    p_io_out_tx_req_bits_allowRetry = '0; tog_io_out_tx_req_bits_allowRetry = 1'b0;
    p_io_out_tx_req_bits_order = '0; tog_io_out_tx_req_bits_order = 1'b0;
    p_io_out_tx_req_bits_pCrdType = '0; tog_io_out_tx_req_bits_pCrdType = 1'b0;
    p_io_out_tx_req_bits_memAttr_allocate = '0; tog_io_out_tx_req_bits_memAttr_allocate = 1'b0;
    p_io_out_tx_req_bits_memAttr_cacheable = '0; tog_io_out_tx_req_bits_memAttr_cacheable = 1'b0;
    p_io_out_tx_req_bits_memAttr_device = '0; tog_io_out_tx_req_bits_memAttr_device = 1'b0;
    p_io_out_tx_req_bits_memAttr_ewa = '0; tog_io_out_tx_req_bits_memAttr_ewa = 1'b0;
    p_io_out_tx_req_bits_snpAttr = '0; tog_io_out_tx_req_bits_snpAttr = 1'b0;
    p_io_out_tx_req_bits_expCompAck = '0; tog_io_out_tx_req_bits_expCompAck = 1'b0;
    p_io_out_tx_dat_valid = '0; tog_io_out_tx_dat_valid = 1'b0;
    p_io_out_tx_dat_bits_tgtID = '0; tog_io_out_tx_dat_bits_tgtID = 1'b0;
    p_io_out_tx_dat_bits_srcID = '0; tog_io_out_tx_dat_bits_srcID = 1'b0;
    p_io_out_tx_dat_bits_txnID = '0; tog_io_out_tx_dat_bits_txnID = 1'b0;
    p_io_out_tx_dat_bits_homeNID = '0; tog_io_out_tx_dat_bits_homeNID = 1'b0;
    p_io_out_tx_dat_bits_opcode = '0; tog_io_out_tx_dat_bits_opcode = 1'b0;
    p_io_out_tx_dat_bits_resp = '0; tog_io_out_tx_dat_bits_resp = 1'b0;
    p_io_out_tx_dat_bits_dataSource = '0; tog_io_out_tx_dat_bits_dataSource = 1'b0;
    p_io_out_tx_dat_bits_dbID = '0; tog_io_out_tx_dat_bits_dbID = 1'b0;
    p_io_out_tx_dat_bits_dataID = '0; tog_io_out_tx_dat_bits_dataID = 1'b0;
    p_io_out_tx_dat_bits_be = '0; tog_io_out_tx_dat_bits_be = 1'b0;
    p_io_out_tx_dat_bits_data = '0; tog_io_out_tx_dat_bits_data = 1'b0;
    p_io_out_tx_dat_bits_dataCheck = '0; tog_io_out_tx_dat_bits_dataCheck = 1'b0;
    p_io_out_rx_rsp_ready = '0; tog_io_out_rx_rsp_ready = 1'b0;
    p_io_out_rx_dat_ready = '0; tog_io_out_rx_dat_ready = 1'b0;
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      // 中途再来一次复位脉冲，覆盖复位路径（两侧同拍同源）。
      if (c == NCYCLES/2) begin
        @(negedge clock); reset = 1'b1;
        repeat (3) @(posedge clock);
        @(negedge clock); reset = 1'b0;
      end
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      sample_coverage();
      @(posedge clock);
    end

    if (tog_io_in_0_tx_req_ready) toggled++; else $display("COV: output io_in_0_tx_req_ready never toggled");
    if (tog_io_in_0_tx_dat_ready) toggled++; else $display("COV: output io_in_0_tx_dat_ready never toggled");
    if (tog_io_in_0_rx_rsp_valid) toggled++; else $display("COV: output io_in_0_rx_rsp_valid never toggled");
    if (tog_io_in_0_rx_rsp_bits_srcID) toggled++; else $display("COV: output io_in_0_rx_rsp_bits_srcID never toggled");
    if (tog_io_in_0_rx_rsp_bits_txnID) toggled++; else $display("COV: output io_in_0_rx_rsp_bits_txnID never toggled");
    if (tog_io_in_0_rx_rsp_bits_opcode) toggled++; else $display("COV: output io_in_0_rx_rsp_bits_opcode never toggled");
    if (tog_io_in_0_rx_rsp_bits_dbID) toggled++; else $display("COV: output io_in_0_rx_rsp_bits_dbID never toggled");
    if (tog_io_in_0_rx_dat_valid) toggled++; else $display("COV: output io_in_0_rx_dat_valid never toggled");
    if (tog_io_in_0_rx_dat_bits_srcID) toggled++; else $display("COV: output io_in_0_rx_dat_bits_srcID never toggled");
    if (tog_io_in_0_rx_dat_bits_txnID) toggled++; else $display("COV: output io_in_0_rx_dat_bits_txnID never toggled");
    if (tog_io_in_0_rx_dat_bits_opcode) toggled++; else $display("COV: output io_in_0_rx_dat_bits_opcode never toggled");
    if (tog_io_in_0_rx_dat_bits_resp) toggled++; else $display("COV: output io_in_0_rx_dat_bits_resp never toggled");
    if (tog_io_in_0_rx_dat_bits_dataID) toggled++; else $display("COV: output io_in_0_rx_dat_bits_dataID never toggled");
    if (tog_io_in_0_rx_dat_bits_data) toggled++; else $display("COV: output io_in_0_rx_dat_bits_data never toggled");
    if (tog_io_in_1_tx_req_ready) toggled++; else $display("COV: output io_in_1_tx_req_ready never toggled");
    if (tog_io_in_1_tx_dat_ready) toggled++; else $display("COV: output io_in_1_tx_dat_ready never toggled");
    if (tog_io_in_1_rx_rsp_valid) toggled++; else $display("COV: output io_in_1_rx_rsp_valid never toggled");
    if (tog_io_in_1_rx_rsp_bits_srcID) toggled++; else $display("COV: output io_in_1_rx_rsp_bits_srcID never toggled");
    if (tog_io_in_1_rx_rsp_bits_txnID) toggled++; else $display("COV: output io_in_1_rx_rsp_bits_txnID never toggled");
    if (tog_io_in_1_rx_rsp_bits_opcode) toggled++; else $display("COV: output io_in_1_rx_rsp_bits_opcode never toggled");
    if (tog_io_in_1_rx_rsp_bits_dbID) toggled++; else $display("COV: output io_in_1_rx_rsp_bits_dbID never toggled");
    if (tog_io_in_1_rx_dat_valid) toggled++; else $display("COV: output io_in_1_rx_dat_valid never toggled");
    if (tog_io_in_1_rx_dat_bits_srcID) toggled++; else $display("COV: output io_in_1_rx_dat_bits_srcID never toggled");
    if (tog_io_in_1_rx_dat_bits_txnID) toggled++; else $display("COV: output io_in_1_rx_dat_bits_txnID never toggled");
    if (tog_io_in_1_rx_dat_bits_opcode) toggled++; else $display("COV: output io_in_1_rx_dat_bits_opcode never toggled");
    if (tog_io_in_1_rx_dat_bits_resp) toggled++; else $display("COV: output io_in_1_rx_dat_bits_resp never toggled");
    if (tog_io_in_1_rx_dat_bits_dataID) toggled++; else $display("COV: output io_in_1_rx_dat_bits_dataID never toggled");
    if (tog_io_in_1_rx_dat_bits_data) toggled++; else $display("COV: output io_in_1_rx_dat_bits_data never toggled");
    if (tog_io_in_2_tx_req_ready) toggled++; else $display("COV: output io_in_2_tx_req_ready never toggled");
    if (tog_io_in_2_tx_dat_ready) toggled++; else $display("COV: output io_in_2_tx_dat_ready never toggled");
    if (tog_io_in_2_rx_rsp_valid) toggled++; else $display("COV: output io_in_2_rx_rsp_valid never toggled");
    if (tog_io_in_2_rx_rsp_bits_srcID) toggled++; else $display("COV: output io_in_2_rx_rsp_bits_srcID never toggled");
    if (tog_io_in_2_rx_rsp_bits_txnID) toggled++; else $display("COV: output io_in_2_rx_rsp_bits_txnID never toggled");
    if (tog_io_in_2_rx_rsp_bits_opcode) toggled++; else $display("COV: output io_in_2_rx_rsp_bits_opcode never toggled");
    if (tog_io_in_2_rx_rsp_bits_dbID) toggled++; else $display("COV: output io_in_2_rx_rsp_bits_dbID never toggled");
    if (tog_io_in_2_rx_dat_valid) toggled++; else $display("COV: output io_in_2_rx_dat_valid never toggled");
    if (tog_io_in_2_rx_dat_bits_srcID) toggled++; else $display("COV: output io_in_2_rx_dat_bits_srcID never toggled");
    if (tog_io_in_2_rx_dat_bits_txnID) toggled++; else $display("COV: output io_in_2_rx_dat_bits_txnID never toggled");
    if (tog_io_in_2_rx_dat_bits_opcode) toggled++; else $display("COV: output io_in_2_rx_dat_bits_opcode never toggled");
    if (tog_io_in_2_rx_dat_bits_resp) toggled++; else $display("COV: output io_in_2_rx_dat_bits_resp never toggled");
    if (tog_io_in_2_rx_dat_bits_dataID) toggled++; else $display("COV: output io_in_2_rx_dat_bits_dataID never toggled");
    if (tog_io_in_2_rx_dat_bits_data) toggled++; else $display("COV: output io_in_2_rx_dat_bits_data never toggled");
    if (tog_io_in_3_tx_req_ready) toggled++; else $display("COV: output io_in_3_tx_req_ready never toggled");
    if (tog_io_in_3_tx_dat_ready) toggled++; else $display("COV: output io_in_3_tx_dat_ready never toggled");
    if (tog_io_in_3_rx_rsp_valid) toggled++; else $display("COV: output io_in_3_rx_rsp_valid never toggled");
    if (tog_io_in_3_rx_rsp_bits_srcID) toggled++; else $display("COV: output io_in_3_rx_rsp_bits_srcID never toggled");
    if (tog_io_in_3_rx_rsp_bits_txnID) toggled++; else $display("COV: output io_in_3_rx_rsp_bits_txnID never toggled");
    if (tog_io_in_3_rx_rsp_bits_opcode) toggled++; else $display("COV: output io_in_3_rx_rsp_bits_opcode never toggled");
    if (tog_io_in_3_rx_rsp_bits_dbID) toggled++; else $display("COV: output io_in_3_rx_rsp_bits_dbID never toggled");
    if (tog_io_in_3_rx_dat_valid) toggled++; else $display("COV: output io_in_3_rx_dat_valid never toggled");
    if (tog_io_in_3_rx_dat_bits_srcID) toggled++; else $display("COV: output io_in_3_rx_dat_bits_srcID never toggled");
    if (tog_io_in_3_rx_dat_bits_txnID) toggled++; else $display("COV: output io_in_3_rx_dat_bits_txnID never toggled");
    if (tog_io_in_3_rx_dat_bits_opcode) toggled++; else $display("COV: output io_in_3_rx_dat_bits_opcode never toggled");
    if (tog_io_in_3_rx_dat_bits_resp) toggled++; else $display("COV: output io_in_3_rx_dat_bits_resp never toggled");
    if (tog_io_in_3_rx_dat_bits_dataID) toggled++; else $display("COV: output io_in_3_rx_dat_bits_dataID never toggled");
    if (tog_io_in_3_rx_dat_bits_data) toggled++; else $display("COV: output io_in_3_rx_dat_bits_data never toggled");
    if (tog_io_out_tx_req_valid) toggled++; else $display("COV: output io_out_tx_req_valid never toggled");
    if (tog_io_out_tx_req_bits_tgtID) toggled++; else $display("COV: output io_out_tx_req_bits_tgtID never toggled");
    if (tog_io_out_tx_req_bits_srcID) toggled++; else $display("COV: output io_out_tx_req_bits_srcID never toggled");
    if (tog_io_out_tx_req_bits_txnID) toggled++; else $display("COV: output io_out_tx_req_bits_txnID never toggled");
    if (tog_io_out_tx_req_bits_opcode) toggled++; else $display("COV: output io_out_tx_req_bits_opcode never toggled");
    if (tog_io_out_tx_req_bits_size) toggled++; else $display("COV: output io_out_tx_req_bits_size never toggled");
    if (tog_io_out_tx_req_bits_addr) toggled++; else $display("COV: output io_out_tx_req_bits_addr never toggled");
    if (tog_io_out_tx_req_bits_allowRetry) toggled++; else $display("COV: output io_out_tx_req_bits_allowRetry never toggled");
    if (tog_io_out_tx_req_bits_order) toggled++; else $display("COV: output io_out_tx_req_bits_order never toggled");
    if (tog_io_out_tx_req_bits_pCrdType) toggled++; else $display("COV: output io_out_tx_req_bits_pCrdType never toggled");
    if (tog_io_out_tx_req_bits_memAttr_allocate) toggled++; else $display("COV: output io_out_tx_req_bits_memAttr_allocate never toggled");
    if (tog_io_out_tx_req_bits_memAttr_cacheable) toggled++; else $display("COV: output io_out_tx_req_bits_memAttr_cacheable never toggled");
    if (tog_io_out_tx_req_bits_memAttr_device) toggled++; else $display("COV: output io_out_tx_req_bits_memAttr_device never toggled");
    if (tog_io_out_tx_req_bits_memAttr_ewa) toggled++; else $display("COV: output io_out_tx_req_bits_memAttr_ewa never toggled");
    if (tog_io_out_tx_req_bits_snpAttr) toggled++; else $display("COV: output io_out_tx_req_bits_snpAttr never toggled");
    if (tog_io_out_tx_req_bits_expCompAck) toggled++; else $display("COV: output io_out_tx_req_bits_expCompAck never toggled");
    if (tog_io_out_tx_dat_valid) toggled++; else $display("COV: output io_out_tx_dat_valid never toggled");
    if (tog_io_out_tx_dat_bits_tgtID) toggled++; else $display("COV: output io_out_tx_dat_bits_tgtID never toggled");
    if (tog_io_out_tx_dat_bits_srcID) toggled++; else $display("COV: output io_out_tx_dat_bits_srcID never toggled");
    if (tog_io_out_tx_dat_bits_txnID) toggled++; else $display("COV: output io_out_tx_dat_bits_txnID never toggled");
    if (tog_io_out_tx_dat_bits_homeNID) toggled++; else $display("COV: output io_out_tx_dat_bits_homeNID never toggled");
    if (tog_io_out_tx_dat_bits_opcode) toggled++; else $display("COV: output io_out_tx_dat_bits_opcode never toggled");
    if (tog_io_out_tx_dat_bits_resp) toggled++; else $display("COV: output io_out_tx_dat_bits_resp never toggled");
    if (tog_io_out_tx_dat_bits_dataSource) toggled++; else $display("COV: output io_out_tx_dat_bits_dataSource never toggled");
    if (tog_io_out_tx_dat_bits_dbID) toggled++; else $display("COV: output io_out_tx_dat_bits_dbID never toggled");
    if (tog_io_out_tx_dat_bits_dataID) toggled++; else $display("COV: output io_out_tx_dat_bits_dataID never toggled");
    if (tog_io_out_tx_dat_bits_be) toggled++; else $display("COV: output io_out_tx_dat_bits_be never toggled");
    if (tog_io_out_tx_dat_bits_data) toggled++; else $display("COV: output io_out_tx_dat_bits_data never toggled");
    if (tog_io_out_tx_dat_bits_dataCheck) toggled++; else $display("COV: output io_out_tx_dat_bits_dataCheck never toggled");
    if (tog_io_out_rx_rsp_ready) toggled++; else $display("COV: output io_out_rx_rsp_ready never toggled");
    if (tog_io_out_rx_dat_ready) toggled++; else $display("COV: output io_out_rx_dat_ready never toggled");
    $display("SNXbar checks=%0d errors=%0d toggled=%0d/%0d fires=%0d", checks, errors, toggled, N_OUT, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < MIN_TOGGLED) begin $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)", toggled, MIN_TOGGLED); $fatal(1); end
    if (fires < MIN_FIRES) begin $display("TEST FAILED (coverage: only %0d handshake fires, need >= %0d)", fires, MIN_FIRES); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
