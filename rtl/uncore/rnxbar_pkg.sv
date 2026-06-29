// =============================================================================
//  rnxbar_pkg —— RNXbar (CHI 1 RN × 4 HN 交叉开关) 常量 / flit 类型 / 路由函数
// -----------------------------------------------------------------------------
//  对应 OpenLLC 的 RNXbar (CHI Request-Node 侧交叉开关)。它把 1 个上游
//  Request-Node (RN, 这里是 io_in_0, 携带完整 CHIBundleUpstream 全字段) 与 4 个
//  下游 Home-Node bank (HN, io_out_0..3, 携带精简的 CHIBundleDownstream 字段) 互连:
//
//    上行 (RN→HN, TX): RN 的 TXREQ / TXRSP / TXDAT 按「路由位」拆分到 4 个 HN bank;
//      每个 bank 各有一个单输入 FastArbiter (黑盒, 这里退化为带 valid 门控的透传),
//      胜者载荷写到对应 io_out_j。RN 侧 ready = 各 bank 输出 valid (TXREQ 还要 & 该
//      bank 的 out_ready) 的或归约。
//        · TXREQ 路由位 = addr[7:6]   (按物理地址的 bank 交织位选 HN)
//        · TXRSP 路由位 = txnID[10:9]  (响应/数据按事务 ID 高位回到发起该事务的 HN)
//        · TXDAT 路由位 = txnID[10:9]
//    下行 (HN→RN, RX): 4 个 HN bank 的 RXSNP / RXRSP / RXDAT 各经一个 4 输入
//      FastArbiter (黑盒) 仲裁汇聚到唯一 RN (io_in_0)。
//        · RXRSP / RXDAT 输入按 srcID==0 (目标 RN 编号) 门控, 仲裁器 io_chosen 决定
//          ready 回送哪个 bank;
//        · RXSNP 特殊: 先经「snoop 跟踪状态机」(snpReqs / snpMasks 快照寄存器) 缓存
//          一拍再喂仲裁器, 详见 RNXbar.sv。
//
//  注意: 6 通道共 15 个 FastArbiter 均按黑盒例化 (仲裁 + 胜者 payload 选择由其内部
//  完成); 本核重写的是「TX 路由拆分 / RX ready 解复用 / snoop 跟踪状态机」这些路由
//  与时序逻辑。
// =============================================================================
package rnxbar_pkg;

  // 下游 Home-Node bank 数量 (4); 上游 Request-Node 数量 (1, 单 RN)。
  localparam int NUM_HN = 4;
  localparam int NUM_RN = 1;

  // HN bank 编号 (语义命名, 取代 golden 的 out_0/out_1/out_2/out_3 展平名)。
  typedef enum int unsigned {
    HN_0 = 0,
    HN_1 = 1,
    HN_2 = 2,
    HN_3 = 3
  } hn_e;

  // ---------------------------------------------------------------------------
  //  TXREQ —— 请求通道 (RN→HN), 上游全字段 (CHIBundleUpstream REQ)。
  //  喂给 txreq 仲裁器的输入; 仲裁器输出只取其中部分字段 (见 hn 侧端口)。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [3:0]  qos;
    logic [10:0] tgtID;
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [10:0] returnNID;
    logic        stashNIDValid;
    logic [11:0] returnTxnID;
    logic [6:0]  opcode;
    logic [2:0]  size;
    logic [47:0] addr;
    logic        ns;
    logic        likelyshared;
    logic        allowRetry;
    logic [1:0]  order;
    logic [3:0]  pCrdType;
    logic        memAttr_allocate;
    logic        memAttr_cacheable;
    logic        memAttr_device;
    logic        memAttr_ewa;
    logic        snpAttr;
    logic [7:0]  lpIDWithPadding;
    logic        snoopMe;
    logic        expCompAck;
    logic [1:0]  tagOp;
    logic        traceTag;
    logic        mpam_perfMonGroup;
    logic [8:0]  mpam_partID;
    logic        mpam_mpamNS;
    logic [3:0]  rsvdc;
  } rn_req_t;

  // ---------------------------------------------------------------------------
  //  TXRSP —— 响应通道 (RN→HN)。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [4:0]  opcode;
    logic [11:0] dbID;
  } rn_rsp_t;

  // ---------------------------------------------------------------------------
  //  TXDAT —— 写数据通道 (RN→HN), 上游全字段。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [3:0]   qos;
    logic [10:0]  tgtID;
    logic [10:0]  srcID;
    logic [11:0]  txnID;
    logic [10:0]  homeNID;
    logic [3:0]   opcode;
    logic [1:0]   respErr;
    logic [2:0]   resp;
    logic [3:0]   dataSource;
    logic [2:0]   cBusy;
    logic [11:0]  dbID;
    logic [1:0]   ccID;
    logic [1:0]   dataID;
    logic [1:0]   tagOp;
    logic [7:0]   tag;
    logic [1:0]   tu;
    logic         traceTag;
    logic [3:0]   rsvdc;
    logic [31:0]  be;
    logic [255:0] data;
    logic [31:0]  dataCheck;
    logic [3:0]   poison;
  } rn_dat_t;

  // ---------------------------------------------------------------------------
  //  RXSNP —— snoop 通道 (HN→RN)。也是 snoop 跟踪状态机里 snpReqs 快照寄存器的字段。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [11:0] txnID;
    logic [10:0] fwdNID;
    logic [11:0] fwdTxnID;
    logic [4:0]  opcode;
    logic [44:0] addr;
    logic        doNotGoToSD;
    logic        retToSrc;
  } snp_t;

  // ---------------------------------------------------------------------------
  //  RXRSP —— 响应通道 (HN→RN) 喂给 rxrsp 仲裁器的载荷 (不含 srcID, srcID 仅用于
  //  输入 valid 门控)。仲裁器另对 qos/respErr/cBusy/tagOp/traceTag 注入常量 0。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [10:0] tgtID;
    logic [11:0] txnID;
    logic [4:0]  opcode;
    logic [2:0]  resp;
    logic [2:0]  fwdState;
    logic [11:0] dbID;
    logic [3:0]  pCrdType;
  } hn_rsp_t;

  // ---------------------------------------------------------------------------
  //  RXDAT —— 读数据通道 (HN→RN) 喂给 rxdat 仲裁器的载荷 (含 srcID, 仲裁器输出端
  //  丢弃 tgtID/srcID)。srcID 同时用于输入 valid 门控。
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
  } hn_dat_t;

  // ---------------------------------------------------------------------------
  //  路由位提取
  // ---------------------------------------------------------------------------
  //  TXREQ 按物理地址的 bank 交织位 addr[7:6] 选目标 HN (0..3)。
  function automatic logic [1:0] route_req(input logic [47:0] addr);
    return addr[7:6];
  endfunction
  //  TXRSP / TXDAT 按事务 ID 高 2 位 txnID[10:9] 回到发起该事务的 HN (0..3)。
  function automatic logic [1:0] route_txnid(input logic [11:0] txnID);
    return txnID[10:9];
  endfunction

endpackage
