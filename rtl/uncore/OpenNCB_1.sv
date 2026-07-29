// OpenNCB_1 —— 手写可读实现(codex_0088 §6.2, OpenNCB_1 parent, AUX assembly signoff)。
//
// CHI<->AXI Non-Coherent Bridge 顶层(32 条目变体)。纯组合装配壳:
//   例化唯一 child NCB200_1(已 AUX 签核 PASS), 做 CHI packed-flit <-> NCB200_1 field
//   端口位切片映射 + 2 条输出 flit 打包 assign(io_chi_rx_rsp_flit / io_chi_rx_dat_flit)。
//
// ★顶层 = 纯结构 netlist(0 register / 0 always / 0 function): 声明 25 互连 wire +
//   例化 NCB200_1 uNCB200(494 端口连线, 400 debug /* unused */)+ 2 flit 打包 assign。
//   全部功能逻辑在 NCB200_1 内(CAM/FreeList/AgeMatrix/Queue/Payload/上下游通道 FSM)。
//
// ★ FM assembly: NCB200_1 对称黑盒 depends_on(已 clean AUX); ref==impl 同源装配壳,
//   互连逐位一致 → 结构无死位, allow 全空。
module xs_OpenNCB_1_core(
  input clock,
  input reset,
  input auto_axi4_out_aw_ready,
  output auto_axi4_out_aw_valid,
  output [4:0] auto_axi4_out_aw_bits_id,
  output [48:0] auto_axi4_out_aw_bits_addr,
  output [7:0] auto_axi4_out_aw_bits_len,
  output [2:0] auto_axi4_out_aw_bits_size,
  output [1:0] auto_axi4_out_aw_bits_burst,
  output [3:0] auto_axi4_out_aw_bits_cache,
  output [3:0] auto_axi4_out_aw_bits_qos,
  input auto_axi4_out_w_ready,
  output auto_axi4_out_w_valid,
  output [255:0] auto_axi4_out_w_bits_data,
  output [31:0] auto_axi4_out_w_bits_strb,
  output auto_axi4_out_w_bits_last,
  input auto_axi4_out_b_valid,
  input [4:0] auto_axi4_out_b_bits_id,
  input auto_axi4_out_ar_ready,
  output auto_axi4_out_ar_valid,
  output [4:0] auto_axi4_out_ar_bits_id,
  output [48:0] auto_axi4_out_ar_bits_addr,
  output [7:0] auto_axi4_out_ar_bits_len,
  output [2:0] auto_axi4_out_ar_bits_size,
  output [1:0] auto_axi4_out_ar_bits_burst,
  output [3:0] auto_axi4_out_ar_bits_cache,
  output [3:0] auto_axi4_out_ar_bits_qos,
  input auto_axi4_out_r_valid,
  input [4:0] auto_axi4_out_r_bits_id,
  input [255:0] auto_axi4_out_r_bits_data,
  input auto_axi4_out_r_bits_last,
  input io_chi_txsactive,
  output io_chi_rxsactive,
  input io_chi_tx_linkactivereq,
  output io_chi_tx_linkactiveack,
  input io_chi_tx_req_flitpend,
  input io_chi_tx_req_flitv,
  input [161:0] io_chi_tx_req_flit,
  output io_chi_tx_req_lcrdv,
  input io_chi_tx_dat_flitpend,
  input io_chi_tx_dat_flitv,
  input [421:0] io_chi_tx_dat_flit,
  output io_chi_tx_dat_lcrdv,
  output io_chi_rx_linkactivereq,
  input io_chi_rx_linkactiveack,
  output io_chi_rx_rsp_flitpend,
  output io_chi_rx_rsp_flitv,
  output [72:0] io_chi_rx_rsp_flit,
  input io_chi_rx_rsp_lcrdv,
  output io_chi_rx_dat_flitpend,
  output io_chi_rx_dat_flitv,
  output [421:0] io_chi_rx_dat_flit,
  input io_chi_rx_dat_lcrdv
);

  wire [3:0]   _uNCB200_io_chi_txrsp_flit_QoS;
  wire [10:0]  _uNCB200_io_chi_txrsp_flit_TgtID;
  wire [10:0]  _uNCB200_io_chi_txrsp_flit_SrcID;
  wire [11:0]  _uNCB200_io_chi_txrsp_flit_TxnID;
  wire [4:0]   _uNCB200_io_chi_txrsp_flit_Opcode;
  wire [1:0]   _uNCB200_io_chi_txrsp_flit_RespErr;
  wire [2:0]   _uNCB200_io_chi_txrsp_flit_CBusy;
  wire [11:0]  _uNCB200_io_chi_txrsp_flit_DBID_PGroupID_StashGroupID_TagGroupID;
  wire [1:0]   _uNCB200_io_chi_txrsp_flit_TagOp;
  wire [3:0]   _uNCB200_io_chi_txdat_flit_QoS;
  wire [10:0]  _uNCB200_io_chi_txdat_flit_TgtID;
  wire [10:0]  _uNCB200_io_chi_txdat_flit_SrcID;
  wire [11:0]  _uNCB200_io_chi_txdat_flit_TxnID;
  wire [10:0]  _uNCB200_io_chi_txdat_flit_HomeNID;
  wire [3:0]   _uNCB200_io_chi_txdat_flit_Opcode;
  wire [1:0]   _uNCB200_io_chi_txdat_flit_RespErr;
  wire [2:0]   _uNCB200_io_chi_txdat_flit_CBusy;
  wire [1:0]   _uNCB200_io_chi_txdat_flit_CCID;
  wire [1:0]   _uNCB200_io_chi_txdat_flit_DataID;
  wire [1:0]   _uNCB200_io_chi_txdat_flit_TagOp;
  wire [7:0]   _uNCB200_io_chi_txdat_flit_Tag;
  wire [1:0]   _uNCB200_io_chi_txdat_flit_TU;
  wire [3:0]   _uNCB200_io_chi_txdat_flit_RSVDC;
  wire [255:0] _uNCB200_io_chi_txdat_flit_Data;
  wire [31:0]  _uNCB200_io_chi_txdat_flit_DataCheck;
  NCB200_1 uNCB200 (
    .clock                                                                  (clock),
    .reset                                                                  (reset),
    .io_chi_rxreq_flitv
      (io_chi_tx_req_flitv),
    .io_chi_rxreq_flit_QoS
      (io_chi_tx_req_flit[3:0]),
    .io_chi_rxreq_flit_TgtID
      (io_chi_tx_req_flit[14:4]),
    .io_chi_rxreq_flit_SrcID
      (io_chi_tx_req_flit[25:15]),
    .io_chi_rxreq_flit_TxnID
      (io_chi_tx_req_flit[37:26]),
    .io_chi_rxreq_flit_ReturnNID_StashNID_SLCRepHint
      (io_chi_tx_req_flit[48:38]),
    .io_chi_rxreq_flit_ReturnTxnID_StashLPIDValid_StashLPID
      (io_chi_tx_req_flit[61:50]),
    .io_chi_rxreq_flit_Opcode
      (io_chi_tx_req_flit[68:62]),
    .io_chi_rxreq_flit_Size
      (io_chi_tx_req_flit[71:69]),
    .io_chi_rxreq_flit_Addr
      (io_chi_tx_req_flit[119:72]),
    .io_chi_rxreq_flit_LikelyShared
      (io_chi_tx_req_flit[121]),
    .io_chi_rxreq_flit_AllowRetry
      (io_chi_tx_req_flit[122]),
    .io_chi_rxreq_flit_Order
      (io_chi_tx_req_flit[124:123]),
    .io_chi_rxreq_flit_PCrdType
      (io_chi_tx_req_flit[128:125]),
    .io_chi_rxreq_flit_MemAttr
      (io_chi_tx_req_flit[132:129]),
    .io_chi_rxreq_flit_SnpAttr_DoDWT
      (io_chi_tx_req_flit[133]),
    .io_chi_rxreq_flit_Excl_SnoopMe
      (io_chi_tx_req_flit[142]),
    .io_chi_rxreq_flit_ExpCompAck
      (io_chi_tx_req_flit[143]),
    .io_chi_rxreq_lcrdv
      (io_chi_tx_req_lcrdv),
    .io_chi_txrsp_flitpend
      (io_chi_rx_rsp_flitpend),
    .io_chi_txrsp_flitv
      (io_chi_rx_rsp_flitv),
    .io_chi_txrsp_flit_QoS
      (_uNCB200_io_chi_txrsp_flit_QoS),
    .io_chi_txrsp_flit_TgtID
      (_uNCB200_io_chi_txrsp_flit_TgtID),
    .io_chi_txrsp_flit_SrcID
      (_uNCB200_io_chi_txrsp_flit_SrcID),
    .io_chi_txrsp_flit_TxnID
      (_uNCB200_io_chi_txrsp_flit_TxnID),
    .io_chi_txrsp_flit_Opcode
      (_uNCB200_io_chi_txrsp_flit_Opcode),
    .io_chi_txrsp_flit_RespErr
      (_uNCB200_io_chi_txrsp_flit_RespErr),
    .io_chi_txrsp_flit_CBusy
      (_uNCB200_io_chi_txrsp_flit_CBusy),
    .io_chi_txrsp_flit_DBID_PGroupID_StashGroupID_TagGroupID
      (_uNCB200_io_chi_txrsp_flit_DBID_PGroupID_StashGroupID_TagGroupID),
    .io_chi_txrsp_flit_TagOp
      (_uNCB200_io_chi_txrsp_flit_TagOp),
    .io_chi_txrsp_lcrdv
      (io_chi_rx_rsp_lcrdv),
    .io_chi_txdat_flitpend
      (io_chi_rx_dat_flitpend),
    .io_chi_txdat_flitv
      (io_chi_rx_dat_flitv),
    .io_chi_txdat_flit_QoS
      (_uNCB200_io_chi_txdat_flit_QoS),
    .io_chi_txdat_flit_TgtID
      (_uNCB200_io_chi_txdat_flit_TgtID),
    .io_chi_txdat_flit_SrcID
      (_uNCB200_io_chi_txdat_flit_SrcID),
    .io_chi_txdat_flit_TxnID
      (_uNCB200_io_chi_txdat_flit_TxnID),
    .io_chi_txdat_flit_HomeNID
      (_uNCB200_io_chi_txdat_flit_HomeNID),
    .io_chi_txdat_flit_Opcode
      (_uNCB200_io_chi_txdat_flit_Opcode),
    .io_chi_txdat_flit_RespErr
      (_uNCB200_io_chi_txdat_flit_RespErr),
    .io_chi_txdat_flit_CBusy
      (_uNCB200_io_chi_txdat_flit_CBusy),
    .io_chi_txdat_flit_CCID
      (_uNCB200_io_chi_txdat_flit_CCID),
    .io_chi_txdat_flit_DataID
      (_uNCB200_io_chi_txdat_flit_DataID),
    .io_chi_txdat_flit_TagOp
      (_uNCB200_io_chi_txdat_flit_TagOp),
    .io_chi_txdat_flit_Tag
      (_uNCB200_io_chi_txdat_flit_Tag),
    .io_chi_txdat_flit_TU
      (_uNCB200_io_chi_txdat_flit_TU),
    .io_chi_txdat_flit_RSVDC
      (_uNCB200_io_chi_txdat_flit_RSVDC),
    .io_chi_txdat_flit_Data
      (_uNCB200_io_chi_txdat_flit_Data),
    .io_chi_txdat_flit_DataCheck
      (_uNCB200_io_chi_txdat_flit_DataCheck),
    .io_chi_txdat_lcrdv
      (io_chi_rx_dat_lcrdv),
    .io_chi_rxdat_flitv
      (io_chi_tx_dat_flitv),
    .io_chi_rxdat_flit_TxnID
      (io_chi_tx_dat_flit[37:26]),
    .io_chi_rxdat_flit_Opcode
      (io_chi_tx_dat_flit[52:49]),
    .io_chi_rxdat_flit_DataID
      (io_chi_tx_dat_flit[80:79]),
    .io_chi_rxdat_flit_BE
      (io_chi_tx_dat_flit[129:98]),
    .io_chi_rxdat_flit_Data
      (io_chi_tx_dat_flit[385:130]),
    .io_chi_rxdat_lcrdv
      (io_chi_tx_dat_lcrdv),
    .io_chi_rxlinkactivereq
      (io_chi_tx_linkactivereq),
    .io_chi_rxlinkactiveack
      (io_chi_tx_linkactiveack),
    .io_chi_txlinkactivereq
      (io_chi_rx_linkactivereq),
    .io_chi_txlinkactiveack
      (io_chi_rx_linkactiveack),
    .io_chi_txsactive
      (io_chi_rxsactive),
    .io_axi_aw_ready
      (auto_axi4_out_aw_ready),
    .io_axi_aw_valid
      (auto_axi4_out_aw_valid),
    .io_axi_aw_bits_id
      (auto_axi4_out_aw_bits_id),
    .io_axi_aw_bits_addr
      (auto_axi4_out_aw_bits_addr),
    .io_axi_aw_bits_len
      (auto_axi4_out_aw_bits_len),
    .io_axi_aw_bits_size
      (auto_axi4_out_aw_bits_size),
    .io_axi_aw_bits_burst
      (auto_axi4_out_aw_bits_burst),
    .io_axi_aw_bits_cache
      (auto_axi4_out_aw_bits_cache),
    .io_axi_aw_bits_qos
      (auto_axi4_out_aw_bits_qos),
    .io_axi_w_ready
      (auto_axi4_out_w_ready),
    .io_axi_w_valid
      (auto_axi4_out_w_valid),
    .io_axi_w_bits_data
      (auto_axi4_out_w_bits_data),
    .io_axi_w_bits_strb
      (auto_axi4_out_w_bits_strb),
    .io_axi_w_bits_last
      (auto_axi4_out_w_bits_last),
    .io_axi_b_valid
      (auto_axi4_out_b_valid),
    .io_axi_b_bits_id
      (auto_axi4_out_b_bits_id),
    .io_axi_ar_ready
      (auto_axi4_out_ar_ready),
    .io_axi_ar_valid
      (auto_axi4_out_ar_valid),
    .io_axi_ar_bits_id
      (auto_axi4_out_ar_bits_id),
    .io_axi_ar_bits_addr
      (auto_axi4_out_ar_bits_addr),
    .io_axi_ar_bits_len
      (auto_axi4_out_ar_bits_len),
    .io_axi_ar_bits_size
      (auto_axi4_out_ar_bits_size),
    .io_axi_ar_bits_burst
      (auto_axi4_out_ar_bits_burst),
    .io_axi_ar_bits_cache
      (auto_axi4_out_ar_bits_cache),
    .io_axi_ar_bits_qos
      (auto_axi4_out_ar_bits_qos),
    .io_axi_r_valid
      (auto_axi4_out_r_valid),
    .io_axi_r_bits_id
      (auto_axi4_out_r_bits_id),
    .io_axi_r_bits_data
      (auto_axi4_out_r_bits_data),
    .io_axi_r_bits_last
      (auto_axi4_out_r_bits_last),
    .debug_valid
      (/* unused */),
    .debug_reason_orderAddressCAM_AllocateNotOneHot
      (/* unused */),
    .debug_reason_orderAddressCAM_QueryResultMultipleHit
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_0
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_1
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_2
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_3
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_4
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_5
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_6
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_7
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_8
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_9
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_10
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_11
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_12
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_13
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_14
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_15
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_16
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_17
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_18
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_19
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_20
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_21
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_22
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_23
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_24
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_25
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_26
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_27
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_28
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_29
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_30
      (/* unused */),
    .debug_reason_orderAddressCAM_DoubleAllocation_31
      (/* unused */),
    .debug_reason_orderRequestCAM_AllocateNotOneHot
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_0
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_1
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_2
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_3
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_4
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_5
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_6
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_7
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_8
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_9
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_10
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_11
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_12
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_13
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_14
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_15
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_16
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_17
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_18
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_19
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_20
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_21
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_22
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_23
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_24
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_25
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_26
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_27
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_28
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_29
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_30
      (/* unused */),
    .debug_reason_orderRequestCAM_DoubleAllocation_31
      (/* unused */),
    .debug_reason_transactionFreeList_FreeListUnderflow
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_0
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_1
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_2
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_3
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_4
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_5
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_6
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_7
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_8
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_9
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_10
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_11
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_12
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_13
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_14
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_15
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_16
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_17
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_18
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_19
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_20
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_21
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_22
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_23
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_24
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_25
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_26
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_27
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_28
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_29
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_30
      (/* unused */),
    .debug_reason_transactionFreeList_DoubleFreeOrCorruption_31
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_0
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_1
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_2
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_3
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_4
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_5
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_6
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_7
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_8
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_9
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_10
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_11
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_12
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_13
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_14
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_15
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_16
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_17
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_18
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_19
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_20
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_21
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_22
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_23
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_24
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_25
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_26
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_27
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_28
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_29
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_30
      (/* unused */),
    .debug_reason_transactionQueue_DoubleAllocation_31
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_0
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_1
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_2
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_3
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_4
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_5
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_6
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_7
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_8
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_9
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_10
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_11
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_12
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_13
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_14
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_15
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_16
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_17
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_18
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_19
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_20
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_21
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_22
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_23
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_24
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_25
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_26
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_27
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_28
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_29
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_30
      (/* unused */),
    .debug_reason_transactionQueue_DanglingAXIWriteResponse_31
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_0
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_1
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_2
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_3
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_4
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_5
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_6
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_7
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_8
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_9
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_10
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_11
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_12
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_13
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_14
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_15
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_16
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_17
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_18
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_19
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_20
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_21
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_22
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_23
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_24
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_25
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_26
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_27
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_28
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_29
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_30
      (/* unused */),
    .debug_reason_transactionPayload_DoubleAllocationException_31
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_0
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_1
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_2
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_3
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_4
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_5
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_6
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_7
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_8
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_9
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_10
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_11
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_12
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_13
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_14
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_15
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_16
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_17
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_18
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_19
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_20
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_21
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_22
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_23
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_24
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_25
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_26
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_27
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_28
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_29
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_30
      (/* unused */),
    .debug_reason_transactionPayload_DoubleFreeOrCorruptionException_31
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_0
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_1
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_2
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_3
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_4
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_5
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_6
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_7
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_8
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_9
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_10
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_11
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_12
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_13
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_14
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_15
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_16
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_17
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_18
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_19
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_20
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_21
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_22
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_23
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_24
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_25
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_26
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_27
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_28
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_29
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_30
      (/* unused */),
    .debug_reason_transactionPayload_DualWriteConfliction_31
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_0
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_1
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_2
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_3
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_4
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_5
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_6
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_7
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_8
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_9
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_10
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_11
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_12
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_13
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_14
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_15
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_16
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_17
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_18
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_19
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_20
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_21
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_22
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_23
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_24
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_25
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_26
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_27
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_28
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_29
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_30
      (/* unused */),
    .debug_reason_transactionPayload_DualReadConfliction_31
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_0
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_1
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_2
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_3
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_4
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_5
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_6
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_7
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_8
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_9
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_10
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_11
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_12
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_13
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_14
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_15
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_16
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_17
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_18
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_19
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_20
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_21
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_22
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_23
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_24
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_25
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_26
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_27
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_28
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_29
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_30
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteOutOfBound_31
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_0
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_1
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_2
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_3
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_4
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_5
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_6
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_7
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_8
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_9
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_10
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_11
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_12
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_13
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_14
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_15
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_16
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_17
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_18
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_19
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_20
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_21
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_22
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_23
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_24
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_25
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_26
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_27
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_28
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_29
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_30
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadOutOfBound_31
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_0
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_1
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_2
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_3
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_4
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_5
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_6
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_7
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_8
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_9
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_10
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_11
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_12
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_13
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_14
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_15
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_16
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_17
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_18
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_19
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_20
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_21
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_22
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_23
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_24
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_25
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_26
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_27
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_28
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_29
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_30
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteOutOfBound_31
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_0
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_1
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_2
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_3
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_4
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_5
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_6
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_7
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_8
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_9
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_10
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_11
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_12
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_13
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_14
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_15
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_16
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_17
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_18
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_19
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_20
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_21
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_22
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_23
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_24
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_25
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_26
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_27
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_28
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_29
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_30
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadOutOfBound_31
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_0
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_1
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_2
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_3
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_4
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_5
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_6
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_7
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_8
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_9
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_10
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_11
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_12
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_13
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_14
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_15
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_16
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_17
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_18
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_19
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_20
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_21
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_22
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_23
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_24
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_25
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_26
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_27
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_28
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_29
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_30
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamWriteDirectionConfliction_31
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_0
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_1
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_2
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_3
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_4
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_5
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_6
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_7
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_8
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_9
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_10
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_11
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_12
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_13
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_14
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_15
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_16
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_17
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_18
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_19
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_20
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_21
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_22
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_23
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_24
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_25
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_26
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_27
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_28
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_29
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_30
      (/* unused */),
    .debug_reason_transactionPayload_UpstreamReadDirectionConfliction_31
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_0
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_1
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_2
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_3
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_4
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_5
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_6
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_7
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_8
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_9
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_10
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_11
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_12
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_13
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_14
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_15
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_16
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_17
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_18
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_19
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_20
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_21
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_22
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_23
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_24
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_25
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_26
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_27
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_28
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_29
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_30
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamWriteDirectionConfliction_31
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_0
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_1
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_2
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_3
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_4
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_5
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_6
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_7
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_8
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_9
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_10
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_11
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_12
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_13
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_14
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_15
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_16
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_17
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_18
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_19
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_20
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_21
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_22
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_23
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_24
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_25
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_26
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_27
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_28
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_29
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_30
      (/* unused */),
    .debug_reason_transactionPayload_DownstreamReadDirectionConfliction_31
      (/* unused */),
    .debug_reason_chiRXREQ_WriteFullWithNarrowSize
      (/* unused */),
    .debug_reason_chiRXREQ_NonZeroLikelyShared
      (/* unused */),
    .debug_reason_chiRXREQ_PrefetchTgtWithNonZeroAllowRetry
      (/* unused */),
    .debug_reason_chiRXREQ_ZeroFirstAllowRetry
      (/* unused */),
    .debug_reason_chiRXREQ_WriteWithIllegalOrder
      (/* unused */),
    .debug_reason_chiRXREQ_ReadWithIllegalOrder
      (/* unused */),
    .debug_reason_chiRXREQ_DatalessWithIllegalOrder
      (/* unused */),
    .debug_reason_chiRXREQ_AllowRetryWithNonZeroPCrdType
      (/* unused */),
    .debug_reason_chiRXREQ_IllegalMemAttr
      (/* unused */),
    .debug_reason_chiRXREQ_NonZeroSnpAttr
      (/* unused */),
    .debug_reason_chiRXREQ_NonZeroExcl
      (/* unused */),
    .debug_reason_chiRXREQ_NonZeroExpCompAck
      (/* unused */),
    .debug_reason_chiRXREQ_IllegalSize
      (/* unused */),
    .debug_reason_chiRXREQ_MisalignedAroundDevice
      (/* unused */),
    .debug_reason_chiRXREQ_linkCredit_LinkActiveStateNotOneHot
      (/* unused */),
    .debug_reason_chiRXREQ_linkCredit_LinkCreditConsumeOutOfRun
      (/* unused */),
    .debug_reason_chiRXREQ_linkCredit_LinkCreditReturnOutOfDeactivate
      (/* unused */),
    .debug_reason_chiRXREQ_linkCredit_LinkCreditOverflow
      (/* unused */),
    .debug_reason_chiRXREQ_linkCredit_LinkCreditUnderflow
      (/* unused */),
    .debug_reason_chiRXREQ_decoder_OpcodeUnsupported
      (/* unused */),
    .debug_reason_chiRXREQ_decoder_OpcodeUnknown
      (/* unused */),
    .debug_reason_chiRXDAT_TxnIDNonExist
      (/* unused */),
    .debug_reason_chiRXDAT_TxnIDOutOfRange
      (/* unused */),
    .debug_reason_chiRXDAT_WriteCancelOnNonPtl
      (/* unused */),
    .debug_reason_chiRXDAT_WriteCancelNotSupported
      (/* unused */),
    .debug_reason_chiRXDAT_WriteFullWithParitalBE
      (/* unused */),
    .debug_reason_chiRXDAT_linkCredit_LinkActiveStateNotOneHot
      (/* unused */),
    .debug_reason_chiRXDAT_linkCredit_LinkCreditConsumeOutOfRun
      (/* unused */),
    .debug_reason_chiRXDAT_linkCredit_LinkCreditReturnOutOfDeactivate
      (/* unused */),
    .debug_reason_chiRXDAT_linkCredit_LinkCreditOverflow
      (/* unused */),
    .debug_reason_chiRXDAT_linkCredit_LinkCreditUnderflow
      (/* unused */),
    .debug_reason_chiRXDAT_linkCreditProvide_LinkCreditBufferOverflow
      (/* unused */),
    .debug_reason_chiRXDAT_decoder_OpcodeUnsupported
      (/* unused */),
    .debug_reason_chiRXDAT_decoder_OpcodeUnknown
      (/* unused */),
    .debug_reason_chiTXRSP_linkCredit_LinkActiveStateNotOneHot
      (/* unused */),
    .debug_reason_chiTXRSP_linkCredit_LinkCreditConsumeOutOfRun
      (/* unused */),
    .debug_reason_chiTXRSP_linkCredit_LinkCreditReturnOutOfDeactivate
      (/* unused */),
    .debug_reason_chiTXRSP_linkCredit_LinkCreditValidWhenLinkStop
      (/* unused */),
    .debug_reason_chiTXRSP_linkCredit_LinkCreditOverflow
      (/* unused */),
    .debug_reason_chiTXRSP_linkCredit_LinkCreditUnderflow
      (/* unused */),
    .debug_reason_chiTXDAT_linkCredit_LinkActiveStateNotOneHot
      (/* unused */),
    .debug_reason_chiTXDAT_linkCredit_LinkCreditConsumeOutOfRun
      (/* unused */),
    .debug_reason_chiTXDAT_linkCredit_LinkCreditReturnOutOfDeactivate
      (/* unused */),
    .debug_reason_chiTXDAT_linkCredit_LinkCreditValidWhenLinkStop
      (/* unused */),
    .debug_reason_chiTXDAT_linkCredit_LinkCreditOverflow
      (/* unused */),
    .debug_reason_chiTXDAT_linkCredit_LinkCreditUnderflow
      (/* unused */),
    .debug_reason_axiB_DanglingAXIWriteResponse
      (/* unused */),
    .debug_reason_axiR_DanglingAXIReadData
      (/* unused */),
    .debug_reason_axiR_NotEnoughAXIReadDataBeat
      (/* unused */),
    .debug_reason_axiR_TooMuchAXIReadDataBeat                               (/* unused */)
  );
  assign io_chi_rx_rsp_flit =
    {1'h0,
     _uNCB200_io_chi_txrsp_flit_TagOp,
     4'h0,
     _uNCB200_io_chi_txrsp_flit_DBID_PGroupID_StashGroupID_TagGroupID,
     _uNCB200_io_chi_txrsp_flit_CBusy,
     6'h0,
     _uNCB200_io_chi_txrsp_flit_RespErr,
     _uNCB200_io_chi_txrsp_flit_Opcode,
     _uNCB200_io_chi_txrsp_flit_TxnID,
     _uNCB200_io_chi_txrsp_flit_SrcID,
     _uNCB200_io_chi_txrsp_flit_TgtID,
     _uNCB200_io_chi_txrsp_flit_QoS};
  assign io_chi_rx_dat_flit =
    {4'h0,
     _uNCB200_io_chi_txdat_flit_DataCheck,
     _uNCB200_io_chi_txdat_flit_Data,
     32'h0,
     _uNCB200_io_chi_txdat_flit_RSVDC,
     1'h0,
     _uNCB200_io_chi_txdat_flit_TU,
     _uNCB200_io_chi_txdat_flit_Tag,
     _uNCB200_io_chi_txdat_flit_TagOp,
     _uNCB200_io_chi_txdat_flit_DataID,
     _uNCB200_io_chi_txdat_flit_CCID,
     12'h0,
     _uNCB200_io_chi_txdat_flit_CBusy,
     7'h0,
     _uNCB200_io_chi_txdat_flit_RespErr,
     _uNCB200_io_chi_txdat_flit_Opcode,
     _uNCB200_io_chi_txdat_flit_HomeNID,
     _uNCB200_io_chi_txdat_flit_TxnID,
     _uNCB200_io_chi_txdat_flit_SrcID,
     _uNCB200_io_chi_txdat_flit_TgtID,
     _uNCB200_io_chi_txdat_flit_QoS};
endmodule
