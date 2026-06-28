// =============================================================================
//  snxbar_pkg —— SNXbar (CHI 4 主 × 1 从 交叉开关) 常量与 flit 类型
// -----------------------------------------------------------------------------
//  对应 OpenLLC 的 SNXbar (CHI Subordinate-Node 侧交叉开关)。它把 4 个上游
//  Home-Node (HN-F, 这里作为本交叉开关的「主口 in_0..in_3」) 对 1 个下游
//  Subordinate-Node (SN, 主存控制器) 的访问做汇聚/分发:
//
//    上行 (主→从, TX): 4 个主口的 TXREQ / TXDAT 各经一个 FastArbiter 轮转仲裁,
//                       胜者载荷路由到唯一从口 out。
//    下行 (从→主, RX): 从口回送的 RXRSP / RXDAT 按 flit 的 txnID[10:9] (= 2 位
//                       源主口编号) 解复用回对应主口; 载荷广播, 仅 valid 门控。
//
//  CHI flit 通道 (OpenLLC 的 CHIBundleDownstream/Upstream 子集):
//    TXREQ : 请求通道 (读/写/CMO 等), 含 addr / size / memAttr / order 等;
//    TXDAT : 写数据通道, 含 256 位 data / 32 位 be / dataCheck;
//    RXRSP : 响应通道 (Comp/DBIDResp/RetryAck 等), 含 dbID;
//    RXDAT : 读数据通道, 含 256 位 data / resp / dataID。
//
//  注意: 仲裁器 FastArbiter_46 (TXDAT) / FastArbiter_47 (TXREQ) 在本核中按
//  黑盒例化 (仲裁 + 胜者 payload 多路选择由其内部完成); 本核只重写
//  「ready 解复用 (按 chosen)」与「RX 解复用 (按 txnID 路由)」这两段路由逻辑。
// =============================================================================
package snxbar_pkg;

  // 主口数量 (4 个上游 HN), 从口恒为 1。
  localparam int NUM_IN = 4;

  // 主口编号 (语义命名, 取代 golden 的 in_0/in_1/in_2/in_3 展平名)。
  typedef enum int unsigned {
    IN_0 = 0,
    IN_1 = 1,
    IN_2 = 2,
    IN_3 = 3
  } in_port_e;

  // ---------------------------------------------------------------------------
  //  TXREQ —— 请求通道 (主→从): 字段顺序同 CHI REQ flit。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [10:0] tgtID;
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [6:0]  opcode;
    logic [2:0]  size;
    logic [47:0] addr;
    logic        allowRetry;
    logic [1:0]  order;
    logic [3:0]  pCrdType;
    logic        memAttr_allocate;
    logic        memAttr_cacheable;
    logic        memAttr_device;
    logic        memAttr_ewa;
    logic        snpAttr;
    logic        expCompAck;
  } chi_req_t;

  // ---------------------------------------------------------------------------
  //  TXDAT —— 写数据通道 (主→从): 256 位数据 + byte-enable + dataCheck。
  // ---------------------------------------------------------------------------
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
  } chi_dat_tx_t;

  // ---------------------------------------------------------------------------
  //  RXRSP —— 响应通道 (从→主): 无 ready 背压, 由交叉开关广播 + valid 门控。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [4:0]  opcode;
    logic [11:0] dbID;
  } chi_rsp_t;

  // ---------------------------------------------------------------------------
  //  RXDAT —— 读数据通道 (从→主): 256 位数据 + resp / dataID。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [10:0]  srcID;
    logic [11:0]  txnID;
    logic [3:0]   opcode;
    logic [2:0]   resp;
    logic [1:0]   dataID;
    logic [255:0] data;
  } chi_dat_rx_t;

  // ---------------------------------------------------------------------------
  //  RX 解复用路由: 从口回送的 flit 由 txnID[10:9] 指出归属哪个主口 (0..3)。
  //  (OpenLLC 在下发请求时把源 HN 的 2 位编号塞进 txnID 的这两位, 回程据此还原。)
  // ---------------------------------------------------------------------------
  function automatic logic [1:0] rx_route(input logic [11:0] txnID);
    return txnID[10:9];
  endfunction

endpackage
