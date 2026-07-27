// =============================================================================
//  MMIOBridgeEntry —— MMIO 桥单条目事务 FSM 可读核 (xs_MMIOBridgeEntry_core)
// -----------------------------------------------------------------------------
//  MMIOBridge(MMIO 请求桥)的子模块: 单条 MMIO 事务的状态机, 把 TileLink req/resp
//  桥接到 CHI tx_req/tx_dat/rx_rsp/rx_dat。scoreboard 式状态位:
//    s_*  = 已发送标志(sent):  s_txreq/s_ncbwrdata/s_resp
//    w_*  = 等待标志(waiting): w_comp/w_dbidresp/w_compdata/w_pcrdgrant/w_readreceipt
//  捕获 req/resp payload 到 req_*/rdata/srcID/dbID/... 寄存器。
//
//  参数化家族: golden MMIOBridgeEntry(io_id 1 位)/_2(2 位)/_4(3 位) 仅 io_id 端口
//  位宽 + txnID 零填充常量不同, 逻辑逐位一致 → 单参数化核 #(.ID_W(N))。
//    tx_req.txnID = {(12-ID_W){1'b0}, io_id}
//
//  与 golden MMIOBridgeEntry{,_2,_4} 逐位等价(bug-for-bug)。
// =============================================================================
module xs_MMIOBridgeEntry_core #(
  parameter int ID_W = 1
) (
  input          clock,
  input          reset,
  output         io_req_ready,
  input          io_req_valid,
  input  [3:0]   io_req_bits_opcode,
  input  [1:0]   io_req_bits_size,
  input  [2:0]   io_req_bits_source,
  input  [47:0]  io_req_bits_address,
  input          io_req_bits_user_memBackType_MM,
  input          io_req_bits_user_memPageType_NC,
  input  [7:0]   io_req_bits_mask,
  input  [63:0]  io_req_bits_data,
  input          io_req_bits_corrupt,
  input          io_resp_ready,
  output         io_resp_valid,
  output [3:0]   io_resp_bits_opcode,
  output [1:0]   io_resp_bits_size,
  output [2:0]   io_resp_bits_source,
  output         io_resp_bits_denied,
  output [63:0]  io_resp_bits_data,
  output         io_resp_bits_corrupt,
  input          io_chi_tx_req_ready,
  output         io_chi_tx_req_valid,
  output [11:0]  io_chi_tx_req_bits_txnID,
  output [6:0]   io_chi_tx_req_bits_opcode,
  output [2:0]   io_chi_tx_req_bits_size,
  output [47:0]  io_chi_tx_req_bits_addr,
  output         io_chi_tx_req_bits_allowRetry,
  output [1:0]   io_chi_tx_req_bits_order,
  output [3:0]   io_chi_tx_req_bits_pCrdType,
  output         io_chi_tx_req_bits_memAttr_device,
  output         io_chi_tx_req_bits_memAttr_ewa,
  input          io_chi_tx_dat_ready,
  output         io_chi_tx_dat_valid,
  output [10:0]  io_chi_tx_dat_bits_tgtID,
  output [11:0]  io_chi_tx_dat_bits_txnID,
  output [1:0]   io_chi_tx_dat_bits_respErr,
  output [1:0]   io_chi_tx_dat_bits_ccID,
  output [1:0]   io_chi_tx_dat_bits_dataID,
  output         io_chi_tx_dat_bits_traceTag,
  output [31:0]  io_chi_tx_dat_bits_be,
  output [255:0] io_chi_tx_dat_bits_data,
  output [31:0]  io_chi_tx_dat_bits_dataCheck,
  output [3:0]   io_chi_tx_dat_bits_poison,
  output         io_chi_rx_rsp_ready,
  input          io_chi_rx_rsp_valid,
  input  [10:0]  io_chi_rx_rsp_bits_srcID,
  input  [4:0]   io_chi_rx_rsp_bits_opcode,
  input  [1:0]   io_chi_rx_rsp_bits_respErr,
  input  [11:0]  io_chi_rx_rsp_bits_dbID,
  input  [3:0]   io_chi_rx_rsp_bits_pCrdType,
  input          io_chi_rx_rsp_bits_traceTag,
  output         io_chi_rx_dat_ready,
  input          io_chi_rx_dat_valid,
  input  [1:0]   io_chi_rx_dat_bits_respErr,
  input  [255:0] io_chi_rx_dat_bits_data,
  input  [31:0]  io_chi_rx_dat_bits_dataCheck,
  input  [3:0]   io_chi_rx_dat_bits_poison,
  input  [ID_W-1:0] io_id,
  output         io_pCrd_query_valid,
  output [3:0]   io_pCrd_query_bits_pCrdType,
  output [10:0]  io_pCrd_query_bits_srcID,
  input          io_pCrd_grant,
  output         io_waitOnReadReceipt
);

  // ---- scoreboard 状态位(reset=1: 空闲态"全已完成") ----
  reg          s_txreq;
  reg          s_ncbwrdata;
  reg          s_resp;
  reg          w_comp;
  reg          w_dbidresp;
  reg          w_compdata;
  reg          w_pcrdgrant;
  reg          w_readreceipt;
  reg          allowRetry;

  // ---- 捕获的 req / resp payload ----
  reg  [3:0]   req_opcode;
  reg  [1:0]   req_size;
  reg  [2:0]   req_source;
  reg  [47:0]  req_address;
  reg          req_user_memBackType_MM;
  reg          req_user_memPageType_NC;
  reg  [7:0]   req_mask;
  reg  [63:0]  req_data;
  reg          req_corrupt;
  reg  [255:0] rdata;
  reg  [10:0]  srcID;
  reg  [11:0]  dbID;
  reg  [3:0]   pCrdType;
  reg          denied;
  reg          corrupt;
  reg          traceTag;

  // ---- 组合中间量 ----
  wire         _io_resp_valid_T_1 = w_comp & w_dbidresp;
  wire         io_chi_rx_dat_ready_0 = ~w_compdata & s_txreq;
  wire         io_chi_rx_rsp_ready_0 = (~w_comp | ~w_dbidresp | ~w_readreceipt) & s_txreq;
  wire         io_req_ready_0 =
    s_txreq & s_ncbwrdata & s_resp & _io_resp_valid_T_1 & w_compdata & w_pcrdgrant
    & w_readreceipt;

  wire         _req_T   = io_req_ready_0 & io_req_valid;    // req 握手成功(接受新事务)
  wire         isRead   = req_opcode == 4'h4;
  wire         _GEN     = io_req_bits_opcode == 4'h4;
  wire         _GEN_0   = _req_T & _GEN;
  wire         _GEN_1   = io_req_bits_opcode == 4'h0 | io_req_bits_opcode == 4'h1;
  wire         _GEN_2   = io_chi_rx_dat_ready_0 & io_chi_rx_dat_valid;   // rx_dat 握手
  wire         _GEN_16  = ~_req_T | _GEN | ~_GEN_1;

  wire         dataCheck =
    io_chi_rx_dat_bits_dataCheck[0]  ^ ~(^(io_chi_rx_dat_bits_data[7:0]))
    | io_chi_rx_dat_bits_dataCheck[1]  ^ ~(^(io_chi_rx_dat_bits_data[15:8]))
    | io_chi_rx_dat_bits_dataCheck[2]  ^ ~(^(io_chi_rx_dat_bits_data[23:16]))
    | io_chi_rx_dat_bits_dataCheck[3]  ^ ~(^(io_chi_rx_dat_bits_data[31:24]))
    | io_chi_rx_dat_bits_dataCheck[4]  ^ ~(^(io_chi_rx_dat_bits_data[39:32]))
    | io_chi_rx_dat_bits_dataCheck[5]  ^ ~(^(io_chi_rx_dat_bits_data[47:40]))
    | io_chi_rx_dat_bits_dataCheck[6]  ^ ~(^(io_chi_rx_dat_bits_data[55:48]))
    | io_chi_rx_dat_bits_dataCheck[7]  ^ ~(^(io_chi_rx_dat_bits_data[63:56]))
    | io_chi_rx_dat_bits_dataCheck[8]  ^ ~(^(io_chi_rx_dat_bits_data[71:64]))
    | io_chi_rx_dat_bits_dataCheck[9]  ^ ~(^(io_chi_rx_dat_bits_data[79:72]))
    | io_chi_rx_dat_bits_dataCheck[10] ^ ~(^(io_chi_rx_dat_bits_data[87:80]))
    | io_chi_rx_dat_bits_dataCheck[11] ^ ~(^(io_chi_rx_dat_bits_data[95:88]))
    | io_chi_rx_dat_bits_dataCheck[12] ^ ~(^(io_chi_rx_dat_bits_data[103:96]))
    | io_chi_rx_dat_bits_dataCheck[13] ^ ~(^(io_chi_rx_dat_bits_data[111:104]))
    | io_chi_rx_dat_bits_dataCheck[14] ^ ~(^(io_chi_rx_dat_bits_data[119:112]))
    | io_chi_rx_dat_bits_dataCheck[15] ^ ~(^(io_chi_rx_dat_bits_data[127:120]))
    | io_chi_rx_dat_bits_dataCheck[16] ^ ~(^(io_chi_rx_dat_bits_data[135:128]))
    | io_chi_rx_dat_bits_dataCheck[17] ^ ~(^(io_chi_rx_dat_bits_data[143:136]))
    | io_chi_rx_dat_bits_dataCheck[18] ^ ~(^(io_chi_rx_dat_bits_data[151:144]))
    | io_chi_rx_dat_bits_dataCheck[19] ^ ~(^(io_chi_rx_dat_bits_data[159:152]))
    | io_chi_rx_dat_bits_dataCheck[20] ^ ~(^(io_chi_rx_dat_bits_data[167:160]))
    | io_chi_rx_dat_bits_dataCheck[21] ^ ~(^(io_chi_rx_dat_bits_data[175:168]))
    | io_chi_rx_dat_bits_dataCheck[22] ^ ~(^(io_chi_rx_dat_bits_data[183:176]))
    | io_chi_rx_dat_bits_dataCheck[23] ^ ~(^(io_chi_rx_dat_bits_data[191:184]))
    | io_chi_rx_dat_bits_dataCheck[24] ^ ~(^(io_chi_rx_dat_bits_data[199:192]))
    | io_chi_rx_dat_bits_dataCheck[25] ^ ~(^(io_chi_rx_dat_bits_data[207:200]))
    | io_chi_rx_dat_bits_dataCheck[26] ^ ~(^(io_chi_rx_dat_bits_data[215:208]))
    | io_chi_rx_dat_bits_dataCheck[27] ^ ~(^(io_chi_rx_dat_bits_data[223:216]))
    | io_chi_rx_dat_bits_dataCheck[28] ^ ~(^(io_chi_rx_dat_bits_data[231:224]))
    | io_chi_rx_dat_bits_dataCheck[29] ^ ~(^(io_chi_rx_dat_bits_data[239:232]))
    | io_chi_rx_dat_bits_dataCheck[30] ^ ~(^(io_chi_rx_dat_bits_data[247:240]))
    | io_chi_rx_dat_bits_dataCheck[31] ^ ~(^(io_chi_rx_dat_bits_data[255:248]));

  wire         _GEN_3 = io_chi_rx_rsp_ready_0 & io_chi_rx_rsp_valid;    // rx_rsp 握手
  wire         _GEN_4 = io_chi_rx_rsp_bits_opcode == 5'h5;             // Comp
  wire         _GEN_5 = _GEN_3 & (_GEN_4 | io_chi_rx_rsp_bits_opcode == 5'h4);
  wire         _GEN_6 =
    _GEN_4 | io_chi_rx_rsp_bits_opcode == 5'h6 | io_chi_rx_rsp_bits_opcode == 5'hE;
  wire         _GEN_7 = _GEN_3 & _GEN_6;                               // DBIDResp
  wire         _GEN_8 = io_chi_rx_rsp_bits_opcode == 5'h3;
  wire         _GEN_9 = _GEN_3 & _GEN_8;                               // PCrdGrant

  wire         io_chi_tx_req_valid_0 = ~s_txreq & w_pcrdgrant;
  wire         io_resp_valid_0 =
    ~s_resp & (isRead ? w_compdata : _io_resp_valid_T_1 & s_ncbwrdata);

  // ---- byte-enable: 按 req_address[4:3] 选 64 位 lane 到 256 位 CHI DAT ----
  wire         _io_chi_tx_dat_bits_be_T_8  = req_address[4:3] == 2'h0;
  wire         _io_chi_tx_dat_bits_be_T_9  = req_address[4:3] == 2'h1;
  wire         _io_chi_tx_dat_bits_be_T_10 = req_address[4:3] == 2'h2;
  wire         io_chi_tx_dat_valid_0 = ~s_ncbwrdata & w_dbidresp;
  wire [31:0]  _io_chi_tx_dat_bits_be_T_14 =
    (_io_chi_tx_dat_bits_be_T_8  ? {24'h0, req_mask}        : 32'h0)
    | (_io_chi_tx_dat_bits_be_T_9  ? {16'h0, req_mask, 8'h0}  : 32'h0)
    | (_io_chi_tx_dat_bits_be_T_10 ? {8'h0,  req_mask, 16'h0} : 32'h0)
    | ((&(req_address[4:3]))        ? {req_mask, 24'h0}       : 32'h0);
  // data replicated to all 4 lanes, masked by per-byte be
  wire [255:0] io_chi_tx_dat_bits_data_0 =
    {2{{2{req_data}}}}
    & {{8{_io_chi_tx_dat_bits_be_T_14[31]}}, {8{_io_chi_tx_dat_bits_be_T_14[30]}},
       {8{_io_chi_tx_dat_bits_be_T_14[29]}}, {8{_io_chi_tx_dat_bits_be_T_14[28]}},
       {8{_io_chi_tx_dat_bits_be_T_14[27]}}, {8{_io_chi_tx_dat_bits_be_T_14[26]}},
       {8{_io_chi_tx_dat_bits_be_T_14[25]}}, {8{_io_chi_tx_dat_bits_be_T_14[24]}},
       {8{_io_chi_tx_dat_bits_be_T_14[23]}}, {8{_io_chi_tx_dat_bits_be_T_14[22]}},
       {8{_io_chi_tx_dat_bits_be_T_14[21]}}, {8{_io_chi_tx_dat_bits_be_T_14[20]}},
       {8{_io_chi_tx_dat_bits_be_T_14[19]}}, {8{_io_chi_tx_dat_bits_be_T_14[18]}},
       {8{_io_chi_tx_dat_bits_be_T_14[17]}}, {8{_io_chi_tx_dat_bits_be_T_14[16]}},
       {8{_io_chi_tx_dat_bits_be_T_14[15]}}, {8{_io_chi_tx_dat_bits_be_T_14[14]}},
       {8{_io_chi_tx_dat_bits_be_T_14[13]}}, {8{_io_chi_tx_dat_bits_be_T_14[12]}},
       {8{_io_chi_tx_dat_bits_be_T_14[11]}}, {8{_io_chi_tx_dat_bits_be_T_14[10]}},
       {8{_io_chi_tx_dat_bits_be_T_14[9]}},  {8{_io_chi_tx_dat_bits_be_T_14[8]}},
       {8{_io_chi_tx_dat_bits_be_T_14[7]}},  {8{_io_chi_tx_dat_bits_be_T_14[6]}},
       {8{_io_chi_tx_dat_bits_be_T_14[5]}},  {8{_io_chi_tx_dat_bits_be_T_14[4]}},
       {8{_io_chi_tx_dat_bits_be_T_14[3]}},  {8{_io_chi_tx_dat_bits_be_T_14[2]}},
       {8{_io_chi_tx_dat_bits_be_T_14[1]}},  {8{_io_chi_tx_dat_bits_be_T_14[0]}}};

  // ---- scoreboard 状态更新(异步 reset=1) ----
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      s_txreq       <= 1'h1;
      s_ncbwrdata   <= 1'h1;
      s_resp        <= 1'h1;
      w_comp        <= 1'h1;
      w_dbidresp    <= 1'h1;
      w_compdata    <= 1'h1;
      w_pcrdgrant   <= 1'h1;
      w_readreceipt <= 1'h1;
      allowRetry    <= 1'h1;
    end
    else begin
      s_txreq <=
        ~_GEN_9 & (io_chi_tx_req_ready & io_chi_tx_req_valid_0 | ~_req_T & s_txreq);
      s_ncbwrdata <= io_chi_tx_dat_ready & io_chi_tx_dat_valid_0 | _GEN_16 & s_ncbwrdata;
      s_resp <= io_resp_ready & io_resp_valid_0 | ~_req_T & s_resp;
      w_comp <= _GEN_5 | _GEN_16 & w_comp;
      w_dbidresp <= _GEN_7 | _GEN_16 & w_dbidresp;
      w_compdata <= _GEN_2 | ~_GEN_0 & w_compdata;
      w_pcrdgrant <= io_pCrd_grant | ~_GEN_9 & w_pcrdgrant;
      w_readreceipt <=
        _GEN_3 & io_chi_rx_rsp_bits_opcode == 5'h8 | ~_GEN_0 & w_readreceipt;
      allowRetry <= ~_GEN_9 & (_req_T | allowRetry);
    end
  end

  // ---- payload 捕获(同步, 无 reset: 上电随机, 首次写入后确定) ----
  always @(posedge clock) begin
    if (_req_T) begin
      req_opcode              <= io_req_bits_opcode;
      req_size                <= io_req_bits_size;
      req_source              <= io_req_bits_source;
      req_address             <= io_req_bits_address;
      req_user_memBackType_MM <= io_req_bits_user_memBackType_MM;
      req_user_memPageType_NC <= io_req_bits_user_memPageType_NC;
      req_mask                <= io_req_bits_mask;
      req_data                <= io_req_bits_data;
      req_corrupt             <= io_req_bits_corrupt;
    end
    if (_GEN_2) begin
      rdata <= io_chi_rx_dat_bits_data;
      corrupt <=
        corrupt | io_chi_rx_dat_bits_respErr == 2'h2 | (&io_chi_rx_dat_bits_respErr)
        | dataCheck | (|io_chi_rx_dat_bits_poison);
    end
    else
      corrupt <= ~_req_T & corrupt;
    if (_GEN_3 & (_GEN_8 | _GEN_6))
      srcID <= io_chi_rx_rsp_bits_srcID;
    if (_GEN_7) begin
      dbID     <= io_chi_rx_rsp_bits_dbID;
      traceTag <= io_chi_rx_rsp_bits_traceTag;
    end
    else
      traceTag <= ~_req_T & traceTag;
    if (_GEN_9)
      pCrdType <= io_chi_rx_rsp_bits_pCrdType;
    if (_GEN_5)
      denied <=
        denied | (&io_chi_rx_rsp_bits_respErr) | io_chi_rx_rsp_bits_respErr == 2'h2;
    else if (_GEN_2)
      denied <= denied | (&io_chi_rx_dat_bits_respErr);
    else
      denied <= ~_req_T & denied;
  end

  // ---- 输出 ----
  assign io_req_ready       = io_req_ready_0;
  assign io_resp_valid      = io_resp_valid_0;
  assign io_resp_bits_opcode = {3'h0, isRead};
  assign io_resp_bits_size  = req_size;
  assign io_resp_bits_source = req_source;
  assign io_resp_bits_denied = denied;
  assign io_resp_bits_data =
    (_io_chi_tx_dat_bits_be_T_8  ? rdata[63:0]    : 64'h0)
    | (_io_chi_tx_dat_bits_be_T_9  ? rdata[127:64]  : 64'h0)
    | (_io_chi_tx_dat_bits_be_T_10 ? rdata[191:128] : 64'h0)
    | ((&(req_address[4:3]))        ? rdata[255:192] : 64'h0);
  assign io_resp_bits_corrupt = isRead & corrupt;

  assign io_chi_tx_req_valid = io_chi_tx_req_valid_0;
  // 参数化 txnID 零填充: {(12-ID_W){0}, io_id}
  assign io_chi_tx_req_bits_txnID = {{(12-ID_W){1'b0}}, io_id};
  assign io_chi_tx_req_bits_opcode =
    {4'h0, req_opcode == 4'h4, 2'h0}
    | (req_opcode == 4'h0 | req_opcode == 4'h1 ? 7'h1C : 7'h0);
  assign io_chi_tx_req_bits_size  = {1'h0, req_size};
  assign io_chi_tx_req_bits_addr  = req_address;
  assign io_chi_tx_req_bits_allowRetry = allowRetry;
  assign io_chi_tx_req_bits_order = {1'h1, ~req_user_memBackType_MM};
  assign io_chi_tx_req_bits_pCrdType = allowRetry ? 4'h0 : pCrdType;
  assign io_chi_tx_req_bits_memAttr_device = ~req_user_memBackType_MM;
  assign io_chi_tx_req_bits_memAttr_ewa =
    req_user_memPageType_NC | req_user_memBackType_MM;

  assign io_chi_tx_dat_valid       = io_chi_tx_dat_valid_0;
  assign io_chi_tx_dat_bits_tgtID  = srcID;
  assign io_chi_tx_dat_bits_txnID  = dbID;
  assign io_chi_tx_dat_bits_respErr = {req_corrupt, 1'h0};
  assign io_chi_tx_dat_bits_ccID   = req_address[5:4];
  assign io_chi_tx_dat_bits_dataID = {req_address[5], 1'h0};
  assign io_chi_tx_dat_bits_traceTag = traceTag;
  assign io_chi_tx_dat_bits_be     = _io_chi_tx_dat_bits_be_T_14;
  assign io_chi_tx_dat_bits_data   = io_chi_tx_dat_bits_data_0;
  assign io_chi_tx_dat_bits_dataCheck =
    {~(^(io_chi_tx_dat_bits_data_0[255:248])), ~(^(io_chi_tx_dat_bits_data_0[247:240])),
     ~(^(io_chi_tx_dat_bits_data_0[239:232])), ~(^(io_chi_tx_dat_bits_data_0[231:224])),
     ~(^(io_chi_tx_dat_bits_data_0[223:216])), ~(^(io_chi_tx_dat_bits_data_0[215:208])),
     ~(^(io_chi_tx_dat_bits_data_0[207:200])), ~(^(io_chi_tx_dat_bits_data_0[199:192])),
     ~(^(io_chi_tx_dat_bits_data_0[191:184])), ~(^(io_chi_tx_dat_bits_data_0[183:176])),
     ~(^(io_chi_tx_dat_bits_data_0[175:168])), ~(^(io_chi_tx_dat_bits_data_0[167:160])),
     ~(^(io_chi_tx_dat_bits_data_0[159:152])), ~(^(io_chi_tx_dat_bits_data_0[151:144])),
     ~(^(io_chi_tx_dat_bits_data_0[143:136])), ~(^(io_chi_tx_dat_bits_data_0[135:128])),
     ~(^(io_chi_tx_dat_bits_data_0[127:120])), ~(^(io_chi_tx_dat_bits_data_0[119:112])),
     ~(^(io_chi_tx_dat_bits_data_0[111:104])), ~(^(io_chi_tx_dat_bits_data_0[103:96])),
     ~(^(io_chi_tx_dat_bits_data_0[95:88])),   ~(^(io_chi_tx_dat_bits_data_0[87:80])),
     ~(^(io_chi_tx_dat_bits_data_0[79:72])),   ~(^(io_chi_tx_dat_bits_data_0[71:64])),
     ~(^(io_chi_tx_dat_bits_data_0[63:56])),   ~(^(io_chi_tx_dat_bits_data_0[55:48])),
     ~(^(io_chi_tx_dat_bits_data_0[47:40])),   ~(^(io_chi_tx_dat_bits_data_0[39:32])),
     ~(^(io_chi_tx_dat_bits_data_0[31:24])),   ~(^(io_chi_tx_dat_bits_data_0[23:16])),
     ~(^(io_chi_tx_dat_bits_data_0[15:8])),    ~(^(io_chi_tx_dat_bits_data_0[7:0]))};
  assign io_chi_tx_dat_bits_poison = {4{req_corrupt}};

  assign io_chi_rx_rsp_ready = io_chi_rx_rsp_ready_0;
  assign io_chi_rx_dat_ready = io_chi_rx_dat_ready_0;
  assign io_pCrd_query_valid = ~w_pcrdgrant;
  assign io_pCrd_query_bits_pCrdType = pCrdType;
  assign io_pCrd_query_bits_srcID = srcID;
  assign io_waitOnReadReceipt = ~w_readreceipt & s_txreq;

endmodule
