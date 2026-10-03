// =============================================================================
// xs_MMIOBridgeEntry_core —— TL→CHI MMIO 桥的一个事务槽（MMIOBridgeEntry 家族的核）
//
// 位置：coupledL2/tl2chi/MMIOBridge.scala 的 class MMIOBridgeEntry。MMIOBridge 里有
//   若干个这样的槽，每个槽一次只处理一笔不可缓存（MMIO / NC）访问：上游是 TileLink-UL
//   的 A 通道请求（Get / PutFullData / PutPartialData，一个 64 位字），下游是 CHI 的
//   四条通道（TXREQ / TXDAT 发、RXRSP / RXDAT 收）。四个变体只差 io_id 的位宽：
//   MMIOBridge 里 16 个槽写的是 `entry.io.id := i.U`，字面量 i.U 的位宽随 i 变
//   （槽 0~1 是 1 位、2~3 是 2 位、4~7 是 3 位、8~15 是 4 位），于是同一个 Scala 类
//   被 firtool 单态化成 MMIOBridgeEntry / _2 / _4 / _8 四个模块，其余逐位相同。
//
// 机制：八个"待办"标志，0 表示这件事还欠着，全 1 表示槽空闲。
//   s_*（schedule，欠着要发的）       w_*（wait，欠着要等的）
//     s_txreq      发 CHI 请求          w_comp        等 Comp（写完成）
//     s_ncbwrdata  发写数据             w_dbidresp    等 DBIDResp（写数据许可）
//     s_resp       回 TileLink D        w_compdata    等 CompData（读数据）
//                                       w_pcrdgrant   等 P-Credit（RetryAck 之后）
//                                       w_readreceipt 等 ReadReceipt（读保序回执）
//   读：  收请求 → TXREQ(ReadNoSnp) → [ReadReceipt] + CompData → 回 AccessAckData
//   写：  收请求 → TXREQ(WriteNoSnpPtl) → DBIDResp/CompDBIDResp → TXDAT(NCBWrData)
//         → Comp → 回 AccessAck
//   重试：RXRSP 来 RetryAck ⇒ 重新欠下 s_txreq 与 w_pcrdgrant、allowRetry 清 0、记下
//         pCrdType/srcID；等上层（MMIOBridge 的 P-Credit 仲裁）给 io_pCrd_grant 后重发。
//
// 怪癖（都照 golden，不"修"）：
//   · 同一拍多个事件写同一个标志时按 Chisel 的"后写覆盖"定优先级，下面的 always_ff
//     就按 Scala 里 when 块的先后顺序写，后面的赋值覆盖前面的。
//   · io_req_bits_opcode 既不是 Get 也不是 Put 时（如 Hint），槽只欠 s_txreq / s_resp，
//     TXREQ 的 opcode 发出去是 0 —— 上游不会发这种请求，但电路如此。
//   · denied / corrupt / traceTag / rdata / srcID / dbID / pCrdType 与锁存的请求都不复位。
//   · 数据校验（DataCheck）是逐字节奇校验：check[i] = ~^data[8i+7:8i]。
//   · golden 里的 assert（UC should not have DataCheck error）在 SYNTHESIS 下不存在，不抄。
//
// 端口与 golden 逐名相同（io_id 的位宽由 ID_W 给），变体薄文件只设 ID_W。
// =============================================================================
module xs_MMIOBridgeEntry_core #(
  parameter int unsigned ID_W = 1          // io_id 位宽 = 槽号字面量的位宽（1..4）
)(
  input  logic         clock,
  input  logic         reset,
  // ---- 上游 TileLink A（请求）/ D（应答）----
  output logic         io_req_ready,
  input  logic         io_req_valid,
  input  logic [3:0]   io_req_bits_opcode,
  input  logic [1:0]   io_req_bits_size,
  input  logic [4:0]   io_req_bits_source,
  input  logic [47:0]  io_req_bits_address,
  input  logic         io_req_bits_user_memBackType_MM,
  input  logic         io_req_bits_user_memPageType_NC,
  input  logic [7:0]   io_req_bits_mask,
  input  logic [63:0]  io_req_bits_data,
  input  logic         io_req_bits_corrupt,
  input  logic         io_resp_ready,
  output logic         io_resp_valid,
  output logic [3:0]   io_resp_bits_opcode,
  output logic [1:0]   io_resp_bits_size,
  output logic [4:0]   io_resp_bits_source,
  output logic         io_resp_bits_denied,
  output logic [63:0]  io_resp_bits_data,
  output logic         io_resp_bits_corrupt,
  // ---- 下游 CHI TXREQ ----
  input  logic         io_chi_tx_req_ready,
  output logic         io_chi_tx_req_valid,
  output logic [11:0]  io_chi_tx_req_bits_txnID,
  output logic [6:0]   io_chi_tx_req_bits_opcode,
  output logic [2:0]   io_chi_tx_req_bits_size,
  output logic [47:0]  io_chi_tx_req_bits_addr,
  output logic         io_chi_tx_req_bits_allowRetry,
  output logic [1:0]   io_chi_tx_req_bits_order,
  output logic [3:0]   io_chi_tx_req_bits_pCrdType,
  output logic         io_chi_tx_req_bits_memAttr_device,
  output logic         io_chi_tx_req_bits_memAttr_ewa,
  // ---- 下游 CHI TXDAT（写数据）----
  input  logic         io_chi_tx_dat_ready,
  output logic         io_chi_tx_dat_valid,
  output logic [10:0]  io_chi_tx_dat_bits_tgtID,
  output logic [11:0]  io_chi_tx_dat_bits_txnID,
  output logic [1:0]   io_chi_tx_dat_bits_respErr,
  output logic [1:0]   io_chi_tx_dat_bits_ccID,
  output logic [1:0]   io_chi_tx_dat_bits_dataID,
  output logic         io_chi_tx_dat_bits_traceTag,
  output logic [31:0]  io_chi_tx_dat_bits_be,
  output logic [255:0] io_chi_tx_dat_bits_data,
  output logic [31:0]  io_chi_tx_dat_bits_dataCheck,
  output logic [3:0]   io_chi_tx_dat_bits_poison,
  // ---- 下游 CHI RXRSP / RXDAT ----
  output logic         io_chi_rx_rsp_ready,
  input  logic         io_chi_rx_rsp_valid,
  input  logic [10:0]  io_chi_rx_rsp_bits_srcID,
  input  logic [4:0]   io_chi_rx_rsp_bits_opcode,
  input  logic [1:0]   io_chi_rx_rsp_bits_respErr,
  input  logic [11:0]  io_chi_rx_rsp_bits_dbID,
  input  logic [3:0]   io_chi_rx_rsp_bits_pCrdType,
  input  logic         io_chi_rx_rsp_bits_traceTag,
  output logic         io_chi_rx_dat_ready,
  input  logic         io_chi_rx_dat_valid,
  input  logic [1:0]   io_chi_rx_dat_bits_respErr,
  input  logic [255:0] io_chi_rx_dat_bits_data,
  input  logic [31:0]  io_chi_rx_dat_bits_dataCheck,
  input  logic [3:0]   io_chi_rx_dat_bits_poison,
  // ---- 槽号、P-Credit 查询、读回执等待指示 ----
  input  logic [ID_W-1:0] io_id,
  output logic         io_pCrd_query_valid,
  output logic [3:0]   io_pCrd_query_bits_pCrdType,
  output logic [10:0]  io_pCrd_query_bits_srcID,
  input  logic         io_pCrd_grant,
  output logic         io_waitOnReadReceipt
);

  // ---- 编码常量（TileLink A opcode / CHI RSP opcode / CHI REQ opcode / RespErr）----
  localparam logic [3:0] TL_PUT_FULL    = 4'h0;
  localparam logic [3:0] TL_PUT_PARTIAL = 4'h1;
  localparam logic [3:0] TL_GET         = 4'h4;
  localparam logic [4:0] RSP_RETRY_ACK     = 5'h03;
  localparam logic [4:0] RSP_COMP          = 5'h04;
  localparam logic [4:0] RSP_COMP_DBIDRESP = 5'h05;
  localparam logic [4:0] RSP_DBIDRESP      = 5'h06;
  localparam logic [4:0] RSP_READ_RECEIPT  = 5'h08;
  localparam logic [4:0] RSP_DBIDRESP_ORD  = 5'h0E;
  localparam logic [6:0] REQ_READ_NO_SNP       = 7'h04;
  localparam logic [6:0] REQ_WRITE_NO_SNP_PTL  = 7'h1C;
  localparam logic [1:0] RESPERR_DERR  = 2'h2;
  localparam logic [1:0] RESPERR_NDERR = 2'h3;

  localparam int unsigned WORD_BITS  = 64;                 // TileLink 一个字
  localparam int unsigned WORDS      = 256 / WORD_BITS;    // CHI 一拍 256 位 = 4 个字
  localparam int unsigned CHECK_W    = 32;                 // 每字节一位校验

  initial begin
    if (ID_W < 1 || ID_W > 12)
      $fatal(1, "xs_MMIOBridgeEntry_core: ID_W=%0d 不合法（txnID 只有 12 位）", ID_W);
  end

  // ===========================================================================
  // 一、状态
  // ===========================================================================
  // 待办标志（异步复位为 1 = 空闲）
  logic s_txreq, s_ncbwrdata, s_resp;
  logic w_comp, w_dbidresp, w_compdata, w_pcrdgrant, w_readreceipt;
  logic allowRetry;              // 本次 TXREQ 是否允许被 RetryAck（重发时为 0）

  // 锁存的 TileLink 请求（不复位）
  logic [3:0]  req_opcode;
  logic [1:0]  req_size;
  logic [4:0]  req_source;
  logic [47:0] req_address;
  logic        req_user_memBackType_MM;
  logic        req_user_memPageType_NC;
  logic [7:0]  req_mask;
  logic [63:0] req_data;
  logic        req_corrupt;

  // 从 CHI 收回来的东西（不复位）
  logic [255:0] rdata;           // CompData 的整拍数据
  logic [10:0]  srcID;           // 应答方节点号：TXDAT 的 tgtID / P-Credit 查询键
  logic [11:0]  dbID;            // DBIDResp 给的数据缓冲号：TXDAT 的 txnID
  logic [3:0]   pCrdType;        // RetryAck 指定的信用类型
  logic         denied;          // 回 TileLink 的 denied
  logic         corrupt;         // 回 TileLink 的 corrupt（只对读有效）
  logic         traceTag;

  // ===========================================================================
  // 二、事件
  // ===========================================================================
  wire no_schedule = s_txreq & s_ncbwrdata & s_resp;
  wire no_wait     = w_comp & w_dbidresp & w_compdata & w_pcrdgrant & w_readreceipt;

  wire is_read = (req_opcode == TL_GET);       // 槽里这笔是读

  wire req_fire   = io_req_ready & io_req_valid;
  wire in_is_get  = (io_req_bits_opcode == TL_GET);
  wire in_is_put  = (io_req_bits_opcode == TL_PUT_FULL) | (io_req_bits_opcode == TL_PUT_PARTIAL);
  wire alloc_read  = req_fire & in_is_get;
  wire alloc_write = req_fire & ~in_is_get & in_is_put;

  wire txreq_fire = io_chi_tx_req_ready & io_chi_tx_req_valid;
  wire txdat_fire = io_chi_tx_dat_ready & io_chi_tx_dat_valid;
  wire resp_fire  = io_resp_ready & io_resp_valid;
  wire rxdat_fire = io_chi_rx_dat_ready & io_chi_rx_dat_valid;
  wire rxrsp_fire = io_chi_rx_rsp_ready & io_chi_rx_rsp_valid;

  // RXRSP 按 opcode 分类
  wire rsp_comp    = rxrsp_fire & ((io_chi_rx_rsp_bits_opcode == RSP_COMP_DBIDRESP) |
                                   (io_chi_rx_rsp_bits_opcode == RSP_COMP));
  wire rsp_dbid    = rxrsp_fire & ((io_chi_rx_rsp_bits_opcode == RSP_COMP_DBIDRESP) |
                                   (io_chi_rx_rsp_bits_opcode == RSP_DBIDRESP) |
                                   (io_chi_rx_rsp_bits_opcode == RSP_DBIDRESP_ORD));
  wire rsp_retry   = rxrsp_fire & (io_chi_rx_rsp_bits_opcode == RSP_RETRY_ACK);
  wire rsp_receipt = rxrsp_fire & (io_chi_rx_rsp_bits_opcode == RSP_READ_RECEIPT);

  // RXDAT 的错误汇总
  wire rxdat_nderr = (io_chi_rx_dat_bits_respErr == RESPERR_NDERR);
  wire rxdat_derr  = (io_chi_rx_dat_bits_respErr == RESPERR_DERR);
  logic [CHECK_W-1:0] rxdat_check_bad;         // 第 i 字节奇校验不对
  always_comb begin
    for (int i = 0; i < CHECK_W; i++)
      rxdat_check_bad[i] = io_chi_rx_dat_bits_dataCheck[i] ^ ~(^io_chi_rx_dat_bits_data[8*i +: 8]);
  end
  wire rxdat_check_err = |rxdat_check_bad;
  wire rxdat_poison    = |io_chi_rx_dat_bits_poison;

  // RXRSP 的错误：Comp 带 NDERR 或 DERR 都算 denied
  wire rsp_err = (io_chi_rx_rsp_bits_respErr == RESPERR_NDERR) |
                 (io_chi_rx_rsp_bits_respErr == RESPERR_DERR);

  // ===========================================================================
  // 三、状态更新（同一拍多个事件按书写顺序后写覆盖，与 Scala 的 when 顺序一致）
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s_txreq       <= 1'b1;
      s_ncbwrdata   <= 1'b1;
      s_resp        <= 1'b1;
      w_comp        <= 1'b1;
      w_dbidresp    <= 1'b1;
      w_compdata    <= 1'b1;
      w_pcrdgrant   <= 1'b1;
      w_readreceipt <= 1'b1;
      allowRetry    <= 1'b1;
    end else begin
      // 1) 收下一笔请求：欠下要做的事
      if (req_fire) begin
        s_txreq    <= 1'b0;
        s_resp     <= 1'b0;
        allowRetry <= 1'b1;
      end
      if (alloc_read) begin
        w_compdata    <= 1'b0;
        w_readreceipt <= 1'b0;
      end
      if (alloc_write) begin
        w_comp      <= 1'b0;
        w_dbidresp  <= 1'b0;
        s_ncbwrdata <= 1'b0;
      end
      // 2) 各件事办完：把标志还回 1
      if (txreq_fire)  s_txreq       <= 1'b1;
      if (rxdat_fire)  w_compdata    <= 1'b1;
      if (resp_fire)   s_resp        <= 1'b1;
      if (rsp_comp)    w_comp        <= 1'b1;
      if (rsp_dbid)    w_dbidresp    <= 1'b1;
      if (rsp_retry) begin                        // 被拒：重新欠下 TXREQ，并且要先拿到信用
        s_txreq     <= 1'b0;
        w_pcrdgrant <= 1'b0;
        allowRetry  <= 1'b0;
      end
      if (rsp_receipt) w_readreceipt <= 1'b1;
      if (txdat_fire)  s_ncbwrdata   <= 1'b1;
      if (io_pCrd_grant) w_pcrdgrant <= 1'b1;
    end
  end

  always_ff @(posedge clock) begin
    if (req_fire) begin
      req_opcode              <= io_req_bits_opcode;
      req_size                <= io_req_bits_size;
      req_source              <= io_req_bits_source;
      req_address             <= io_req_bits_address;
      req_user_memBackType_MM <= io_req_bits_user_memBackType_MM;
      req_user_memPageType_NC <= io_req_bits_user_memPageType_NC;
      req_mask                <= io_req_bits_mask;
      req_data                <= io_req_bits_data;
      req_corrupt             <= io_req_bits_corrupt;
      // 新事务把上一笔留下的错误/跟踪位清掉
      denied   <= 1'b0;
      corrupt  <= 1'b0;
      traceTag <= 1'b0;
    end
    if (rxdat_fire) begin
      rdata   <= io_chi_rx_dat_bits_data;
      denied  <= denied | rxdat_nderr;
      corrupt <= corrupt | rxdat_derr | rxdat_nderr | rxdat_check_err | rxdat_poison;
    end
    if (rsp_dbid) begin
      srcID    <= io_chi_rx_rsp_bits_srcID;
      dbID     <= io_chi_rx_rsp_bits_dbID;
      traceTag <= io_chi_rx_rsp_bits_traceTag;
    end
    if (rsp_comp)
      denied <= denied | rsp_err;
    if (rsp_retry) begin
      pCrdType <= io_chi_rx_rsp_bits_pCrdType;
      srcID    <= io_chi_rx_rsp_bits_srcID;
    end
  end

  // ===========================================================================
  // 四、输出
  // ===========================================================================
  // ---- 上游 ----
  assign io_req_ready = no_schedule & no_wait;

  // 请求地址落在 256 位 CHI 数据拍里的第几个 64 位字
  wire [1:0] req_word_idx = req_address[4:3];

  assign io_resp_valid        = ~s_resp & (is_read ? w_compdata : (w_comp & w_dbidresp & s_ncbwrdata));
  assign io_resp_bits_opcode  = {3'h0, is_read};          // AccessAckData(1) / AccessAck(0)
  assign io_resp_bits_size    = req_size;
  assign io_resp_bits_source  = req_source;
  assign io_resp_bits_denied  = denied;
  assign io_resp_bits_data    = rdata[req_word_idx * WORD_BITS +: WORD_BITS];
  assign io_resp_bits_corrupt = is_read & corrupt;

  // ---- TXREQ ----
  wire req_is_put = (req_opcode == TL_PUT_FULL) | (req_opcode == TL_PUT_PARTIAL);

  assign io_chi_tx_req_valid           = ~s_txreq & w_pcrdgrant;
  assign io_chi_tx_req_bits_txnID      = 12'(io_id);
  assign io_chi_tx_req_bits_opcode     = (is_read    ? REQ_READ_NO_SNP      : 7'h0) |
                                         (req_is_put ? REQ_WRITE_NO_SNP_PTL : 7'h0);
  assign io_chi_tx_req_bits_size       = {1'b0, req_size};
  assign io_chi_tx_req_bits_addr       = req_address;
  assign io_chi_tx_req_bits_allowRetry = allowRetry;
  // 保序：设备空间用 EndpointOrder(3)，内存空间用 RequestOrder(2)
  assign io_chi_tx_req_bits_order      = {1'b1, ~req_user_memBackType_MM};
  assign io_chi_tx_req_bits_pCrdType   = allowRetry ? 4'h0 : pCrdType;
  assign io_chi_tx_req_bits_memAttr_device = ~req_user_memBackType_MM;
  assign io_chi_tx_req_bits_memAttr_ewa    = req_user_memPageType_NC | req_user_memBackType_MM;

  // ---- TXDAT：把 64 位写数据放到 256 位数据拍里对应的字上 ----
  logic [31:0]  txdat_be;                      // 字节使能：8 位 mask 移到所在的字
  logic [255:0] txdat_data;                    // 数据在四个字上都复制，再按 be 逐字节屏蔽
  logic [CHECK_W-1:0] txdat_check;
  always_comb begin
    txdat_be = 32'(req_mask) << (8 * req_word_idx);
    for (int i = 0; i < 32; i++)
      txdat_data[8*i +: 8] = req_data[8*(i % 8) +: 8] & {8{txdat_be[i]}};
    for (int i = 0; i < CHECK_W; i++)
      txdat_check[i] = ~(^txdat_data[8*i +: 8]);
  end

  assign io_chi_tx_dat_valid          = ~s_ncbwrdata & w_dbidresp;
  assign io_chi_tx_dat_bits_tgtID     = srcID;
  assign io_chi_tx_dat_bits_txnID     = dbID;
  assign io_chi_tx_dat_bits_respErr   = {req_corrupt, 1'b0};        // DERR(2) / OK(0)
  assign io_chi_tx_dat_bits_ccID      = req_address[5:4];
  assign io_chi_tx_dat_bits_dataID    = {req_address[5], 1'b0};
  assign io_chi_tx_dat_bits_traceTag  = traceTag;
  assign io_chi_tx_dat_bits_be        = txdat_be;
  assign io_chi_tx_dat_bits_data      = txdat_data;
  assign io_chi_tx_dat_bits_dataCheck = txdat_check;
  assign io_chi_tx_dat_bits_poison    = {4{req_corrupt}};

  // ---- RXRSP / RXDAT：请求发出去之后、还有东西没等到时才收 ----
  assign io_chi_rx_rsp_ready = (~w_comp | ~w_dbidresp | ~w_readreceipt) & s_txreq;
  assign io_chi_rx_dat_ready = ~w_compdata & s_txreq;

  // ---- P-Credit 查询与读回执等待 ----
  assign io_pCrd_query_valid         = ~w_pcrdgrant;
  assign io_pCrd_query_bits_pCrdType = pCrdType;
  assign io_pCrd_query_bits_srcID    = srcID;
  assign io_waitOnReadReceipt        = ~w_readreceipt & s_txreq;

endmodule
