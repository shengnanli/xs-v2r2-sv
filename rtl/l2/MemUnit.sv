// ============================================================================
// MemUnit —— OpenLLC memory-access (TXREQ/TXDAT) issue buffer (可读手写核 xs_MemUnit_core)
// ----------------------------------------------------------------------------
// 忠实重写 golden MemUnit.sv(firtool 展开的 16 条目 mem-buffer + FastArbiter_50/52)。
// 逻辑等价 bug-for-bug。架构与 SnoopUnit pilot 同型(16 条目 buffer + bufferTimer 泄漏计时),
// 但每条目携带完整 CHI task + 512b data + 5 态子状态机, 并有两个仲裁器(txreq/txdat)。
//
// 每条目状态机(state):
//   s_issueReq —— TXREQ 已发出(此后可等 dbid/comp/datRsp)
//   s_issueDat —— TXDAT 已发出
//   w_datRsp   —— 已收齐 rnRxdat 两拍数据(可发 TXDAT)
//   w_dbid     —— 已收到 snRxrsp(CompDBIDResp/DBIDResp) 的 dbid
//   w_comp     —— 已收到 comp
//
// 关键数据流:
//   * 入队: MainPipe 双通道(alloc_s4 立即 / alloc_s6 带数据), buffer 未满则占首个空槽;
//     若与在存条目地址冲突(chiOpcode==WriteBackFull 0x1D)则 bypass, 造 fakeRsp 直接回;
//   * txreqArb(FastArbiter_50): 挑 valid & w_datRsp & ~s_issueReq 的条目发 TXREQ;
//     被 respInfo(w_snpRsp 命中同 reqID)阻塞时 valid 撤销; urgentRead 可抢占透传;
//   * snRxrsp: 按 txnID 命中条目, opcode 0x4/0x5/0x6 分别置 w_comp/w_dbid, 更新 txnID←dbID;
//   * rnRxdat: 按 reqID 命中, resp[2]=DataResp 存 data + 置 beatValids/w_datRsp;
//     非 DataResp 也可 w_datRsp;
//   * rnRxrsp: 按 reqID 命中, 置 w_comp/w_dbid(依赖当前 opcode 上下文, _GEN_168);
//   * txdatArb(FastArbiter_52): 挑 valid & w_datRsp & WriteBackFull & s_issueReq & w_dbid
//     & ~s_issueDat 的条目发 TXDAT(携数据);
//   * 条目 free: valid & WBF & s_issueReq & s_issueDat & w_dbid & w_comp & w_datRsp 全满足;
//   * bufferTimer: valid 时自增, valid→invalid(REG_i & ~valid)清零(泄漏检测计时)。
// FastArbiter_50/52 在两侧 elaborate(确定性逻辑, 非厂商宏)。
// ============================================================================

package xs_memunit_pkg;
  localparam int unsigned N        = 16;   // buffer 条目数
  localparam int unsigned IDX_W    = 4;    // $clog2(16)
  localparam int unsigned SET_W    = 12;
  localparam int unsigned BANK_W   = 2;
  localparam int unsigned TAG_W    = 28;
  localparam int unsigned OFF_W    = 6;
  localparam int unsigned SIZE_W   = 3;
  localparam int unsigned BUFID_W  = 4;
  localparam int unsigned REQID_W  = 12;
  localparam int unsigned ID11_W   = 11;   // tgtID/srcID/homeNID/fwdNID
  localparam int unsigned TXNID_W  = 12;   // txnID/dbID/fwdTxnID
  localparam int unsigned OPCODE_W = 7;
  localparam int unsigned RESP_W   = 3;
  localparam int unsigned PCRD_W   = 4;
  localparam int unsigned ORDER_W  = 2;
  localparam int unsigned DATA_W   = 256;
  localparam int unsigned TIMER_W  = 16;
  localparam int unsigned KEY_W    = TAG_W + SET_W; // {tag,set} = 40 位

  // CHI opcode 常量(golden 字面量)
  localparam logic [OPCODE_W-1:0] OP_WRITEBACKFULL = 7'h1D; // conflict / will_free 判据
  localparam logic [OPCODE_W-1:0] OP_READNOSNP     = 7'h4;  // fakeRsp / s4-conflict opcode
  localparam logic [OPCODE_W-1:0] OP_SNP_A         = 7'h7;  // blockByResp opcode 集合
  localparam logic [OPCODE_W-1:0] OP_SNP_B         = 7'h26;
  localparam logic [OPCODE_W-1:0] OP_DBIDRESP      = 7'h5;  // snRxrsp: 置 w_dbid
  localparam logic [OPCODE_W-1:0] OP_COMPDBIDRESP  = 7'h6;  // snRxrsp: 置 w_dbid+w_comp
  localparam logic [TIMER_W-1:0]  TIMEOUT_THRESHOLD = 16'h4E1F;

  // buffer 保存的完整 CHI task
  typedef struct packed {
    logic [SET_W-1:0]    set;
    logic [BANK_W-1:0]   bank;
    logic [TAG_W-1:0]    tag;
    logic [OFF_W-1:0]    off;
    logic [SIZE_W-1:0]   size;
    logic                refillTask;
    logic [BUFID_W-1:0]  bufID;
    logic [REQID_W-1:0]  reqID;
    logic                replSnp;
    logic                snpVec_0;
    logic [ID11_W-1:0]   tgtID;
    logic [ID11_W-1:0]   srcID;
    logic [TXNID_W-1:0]  txnID;
    logic [ID11_W-1:0]   homeNID;
    logic [TXNID_W-1:0]  dbID;
    logic [ID11_W-1:0]   fwdNID;
    logic [TXNID_W-1:0]  fwdTxnID;
    logic [OPCODE_W-1:0] chiOpcode;
    logic [RESP_W-1:0]   resp;
    logic [RESP_W-1:0]   fwdState;
    logic [PCRD_W-1:0]   pCrdType;
    logic                retToSrc;
    logic                doNotGoToSD;
    logic                expCompAck;
    logic                allowRetry;
    logic [ORDER_W-1:0]  order;
    logic                memAttr_allocate;
    logic                memAttr_cacheable;
    logic                memAttr_device;
    logic                memAttr_ewa;
    logic                snpAttr;
  } mem_task_t;

  // MainPipe s4 入队通道(带 state 初值, 无 data)
  typedef struct packed {
    logic                state_s_issueDat;
    logic                state_w_datRsp;
    logic                state_w_dbid;
    logic                state_w_comp;
    mem_task_t           task_bits;
  } alloc_s4_t;

  // MainPipe s6 入队通道(全 task + 数据两拍)
  typedef struct packed {
    mem_task_t           task_bits;
    logic [DATA_W-1:0]   data0;
    logic [DATA_W-1:0]   data1;
  } alloc_s6_t;

  // respInfo(16 路, 用于 blockByResp)
  typedef struct packed {
    logic                valid;
    logic [OPCODE_W-1:0] opcode;
    logic [REQID_W-1:0]  reqID;
    logic                w_snpRsp;
    logic                w_compdata;
  } resp_info_t;
endpackage

// ----------------------------------------------------------------------------
// 可读核: struct 化端口 + generate 展开的 16 条目 mem-buffer
// ----------------------------------------------------------------------------
module xs_MemUnit_core
  import xs_memunit_pkg::*;
(
  input  logic                clock,
  input  logic                reset,

  // MainPipe 入队(alloc_s4 立即路径 / alloc_s6 带数据路径)
  input  logic                io_alloc_s4_valid,
  input  alloc_s4_t           io_alloc_s4,
  input  logic                io_alloc_s6_valid,
  input  alloc_s6_t           io_alloc_s6,

  // urgentRead(可抢占 TXREQ / bypass 造 fakeRsp)
  input  logic                io_urgentRead_valid,
  output logic                io_urgentRead_ready,
  input  logic [SET_W-1:0]    io_urgentRead_bits_set,
  input  logic [BANK_W-1:0]   io_urgentRead_bits_bank,
  input  logic [TAG_W-1:0]    io_urgentRead_bits_tag,
  input  logic [ID11_W-1:0]   io_urgentRead_bits_tgtID,
  input  logic [ID11_W-1:0]   io_urgentRead_bits_srcID,
  input  logic [TXNID_W-1:0]  io_urgentRead_bits_txnID,
  input  logic [PCRD_W-1:0]   io_urgentRead_bits_pCrdType,

  // 下行响应输入
  input  logic                io_snRxrsp_valid,
  input  logic [TXNID_W-1:0]  io_snRxrsp_bits_txnID,
  input  logic [TXNID_W-1:0]  io_snRxrsp_bits_dbID,
  input  logic [OPCODE_W-1:0] io_snRxrsp_bits_opcode,
  input  logic                io_rnRxdat_valid,
  input  logic [TXNID_W-1:0]  io_rnRxdat_bits_txnID,
  input  logic [RESP_W-1:0]   io_rnRxdat_bits_resp,
  input  logic [1:0]          io_rnRxdat_bits_dataID,
  input  logic [DATA_W-1:0]   io_rnRxdat_bits_data_data,
  input  logic                io_rnRxrsp_valid,
  input  logic [TXNID_W-1:0]  io_rnRxrsp_bits_txnID,

  // TXREQ 出口
  input  logic                io_txreq_ready,
  output logic                io_txreq_valid,
  output logic [SET_W-1:0]    io_txreq_bits_set,
  output logic [BANK_W-1:0]   io_txreq_bits_bank,
  output logic [TAG_W-1:0]    io_txreq_bits_tag,
  output logic [SIZE_W-1:0]   io_txreq_bits_size,
  output logic [ID11_W-1:0]   io_txreq_bits_tgtID,
  output logic [ID11_W-1:0]   io_txreq_bits_srcID,
  output logic [TXNID_W-1:0]  io_txreq_bits_txnID,
  output logic [OPCODE_W-1:0] io_txreq_bits_chiOpcode,
  output logic [PCRD_W-1:0]   io_txreq_bits_pCrdType,
  output logic                io_txreq_bits_expCompAck,
  output logic                io_txreq_bits_allowRetry,
  output logic [ORDER_W-1:0]  io_txreq_bits_order,
  output logic                io_txreq_bits_memAttr_allocate,
  output logic                io_txreq_bits_memAttr_cacheable,
  output logic                io_txreq_bits_memAttr_device,
  output logic                io_txreq_bits_memAttr_ewa,
  output logic                io_txreq_bits_snpAttr,

  // TXDAT 出口(数据由 txdatArb 直接给出)
  input  logic                io_txdat_ready,
  output logic                io_txdat_valid,
  output logic [ID11_W-1:0]   io_txdat_bits_task_tgtID,
  output logic [ID11_W-1:0]   io_txdat_bits_task_srcID,
  output logic [TXNID_W-1:0]  io_txdat_bits_task_txnID,
  output logic [ID11_W-1:0]   io_txdat_bits_task_homeNID,
  output logic [TXNID_W-1:0]  io_txdat_bits_task_dbID,
  output logic [RESP_W-1:0]   io_txdat_bits_task_resp,
  output logic [RESP_W-1:0]   io_txdat_bits_task_fwdState,
  output logic [DATA_W-1:0]   io_txdat_bits_data_data_0_data,
  output logic [DATA_W-1:0]   io_txdat_bits_data_data_1_data,

  // bypassData(fakeRsp 回程, 两拍)
  output logic                io_bypassData_0_valid,
  output logic [TXNID_W-1:0]  io_bypassData_0_bits_txnID,
  output logic [OPCODE_W-1:0] io_bypassData_0_bits_opcode,
  output logic [DATA_W-1:0]   io_bypassData_0_bits_data_data,
  output logic                io_bypassData_1_valid,
  output logic [TXNID_W-1:0]  io_bypassData_1_bits_txnID,
  output logic [OPCODE_W-1:0] io_bypassData_1_bits_opcode,
  output logic [1:0]          io_bypassData_1_bits_dataID,
  output logic [DATA_W-1:0]   io_bypassData_1_bits_data_data,

  // memInfo(16 路快照, 供 MainPipe 冲突检测)
  output logic [N-1:0]        io_memInfo_valid,
  output logic [SET_W-1:0]    io_memInfo_set    [N-1:0],
  output logic [TAG_W-1:0]    io_memInfo_tag    [N-1:0],
  output logic [OPCODE_W-1:0] io_memInfo_opcode [N-1:0],
  output logic [REQID_W-1:0]  io_memInfo_reqID  [N-1:0],
  output logic                io_memInfo_w_datRsp [N-1:0],

  // respInfo(16 路)
  input  resp_info_t [N-1:0]  io_respInfo
);

  // -------------------- buffer 状态寄存器 --------------------
  logic              buffer_valid  [N-1:0];
  mem_task_t         buffer_task   [N-1:0];
  logic              state_s_issueReq [N-1:0];
  logic              state_s_issueDat [N-1:0];
  logic              state_w_datRsp   [N-1:0];
  logic              state_w_dbid     [N-1:0];
  logic              state_w_comp     [N-1:0];
  logic [DATA_W-1:0] data0 [N-1:0];
  logic [DATA_W-1:0] data1 [N-1:0];
  logic              beatValids_0 [N-1:0];
  logic              beatValids_1 [N-1:0];
  logic [TIMER_W-1:0] bufferTimer [N-1:0];
  logic              REG_valid_d  [N-1:0]; // golden REG_i(上一拍 valid, 用于计时清零)

  // fakeRsp 两拍(bypass 回程)
  logic [TXNID_W-1:0] fakeRsp_0_txnID,   fakeRsp_1_txnID;
  logic [OPCODE_W-1:0] fakeRsp_0_opcode, fakeRsp_1_opcode;
  logic [DATA_W-1:0]  fakeRsp_0_data,    fakeRsp_1_data;
  logic [1:0]         fakeRsp_1_dataID;
  logic               bypassData_0_valid_d, bypassData_1_valid_d;

  // arbiter 输出线(txreq FastArbiter_50 / txdat FastArbiter_52)
  logic                txreqArb_out_valid;
  logic [SET_W-1:0]    txreqArb_out_set;
  logic [BANK_W-1:0]   txreqArb_out_bank;
  logic [TAG_W-1:0]    txreqArb_out_tag;
  logic [SIZE_W-1:0]   txreqArb_out_size;
  logic [REQID_W-1:0]  txreqArb_out_reqID;
  logic [ID11_W-1:0]   txreqArb_out_tgtID;
  logic [ID11_W-1:0]   txreqArb_out_srcID;
  logic [TXNID_W-1:0]  txreqArb_out_txnID;
  logic [OPCODE_W-1:0] txreqArb_out_chiOpcode;
  logic [PCRD_W-1:0]   txreqArb_out_pCrdType;
  logic                txreqArb_out_expCompAck;
  logic                txreqArb_out_allowRetry;
  logic [ORDER_W-1:0]  txreqArb_out_order;
  logic                txreqArb_out_memAttr_allocate;
  logic                txreqArb_out_memAttr_cacheable;
  logic                txreqArb_out_memAttr_device;
  logic                txreqArb_out_memAttr_ewa;
  logic                txreqArb_out_snpAttr;
  logic [IDX_W-1:0]    txreqArb_chosen;
  logic                txdatArb_out_valid;
  logic [IDX_W-1:0]    txdatArb_chosen;

  // -------------------- 每条目地址键 / will_free 判据 --------------------
  logic [KEY_W-1:0] bufKey [N-1:0];   // {tag,set}
  logic             bufWBF [N-1:0];   // chiOpcode == WriteBackFull
  for (genvar i = 0; i < N; i++) begin : g_key
    assign bufKey[i] = {buffer_task[i].tag, buffer_task[i].set};
    assign bufWBF[i] = (buffer_task[i].chiOpcode == OP_WRITEBACKFULL);
  end

  // -------------------- match 向量(三种响应通道) --------------------
  // match_vec  : rnRxdat 命中(valid & ~w_datRsp & WBF & reqID==rnRxdat.txnID)
  // match_vec_1: rnRxrsp 命中(同, 对 rnRxrsp.txnID)
  // match_vec_2: snRxrsp 命中(valid & s_issueReq & reqID==snRxrsp.txnID)
  logic [N-1:0] match_dat, match_rsp, match_sn;
  for (genvar i = 0; i < N; i++) begin : g_match
    assign match_dat[i] = buffer_valid[i] & ~state_w_datRsp[i] & bufWBF[i]
                        & (buffer_task[i].reqID == io_rnRxdat_bits_txnID);
    assign match_rsp[i] = buffer_valid[i] & ~state_w_datRsp[i] & bufWBF[i]
                        & (buffer_task[i].reqID == io_rnRxrsp_bits_txnID);
    assign match_sn[i]  = buffer_valid[i] & state_s_issueReq[i]
                        & (buffer_task[i].reqID == io_snRxrsp_bits_txnID);
  end

  // 首个命中条目号(golden bufID/bufID_1/bufID_2, priority: 0..14 优先, 末项 15 缺省)
  // golden 末项写作 {3'h7,~match_vec_14} => 命中14时=14, 否则=15(不区分15是否命中)。
  logic [IDX_W-1:0] bufID_dat, bufID_rsp, bufID_sn;
  always_comb begin
    bufID_dat = {3'h7, ~match_dat[14]};
    for (int k = 13; k >= 0; k--) if (match_dat[k]) bufID_dat = IDX_W'(k);
  end
  always_comb begin
    bufID_rsp = {3'h7, ~match_rsp[14]};
    for (int k = 13; k >= 0; k--) if (match_rsp[k]) bufID_rsp = IDX_W'(k);
  end
  always_comb begin
    bufID_sn = {3'h7, ~match_sn[14]};
    for (int k = 13; k >= 0; k--) if (match_sn[k]) bufID_sn = IDX_W'(k);
  end
  logic anyMatchDat, anyMatchRsp, anyMatchSn;
  assign anyMatchDat = (match_dat != '0);
  assign anyMatchRsp = (match_rsp != '0);
  assign anyMatchSn  = (match_sn  != '0);

  // -------------------- 冲突检测(urgentRead / alloc_s4 对在存 WBF 条目) --------------------
  logic [KEY_W-1:0] urKey, s4Key, s6Key;
  assign urKey = {io_urgentRead_bits_tag, io_urgentRead_bits_set};
  assign s4Key = {io_alloc_s4.task_bits.tag, io_alloc_s4.task_bits.set};
  assign s6Key = {io_alloc_s6.task_bits.tag, io_alloc_s6.task_bits.set};
  logic s4OpRN;   // alloc_s4 opcode == ReadNoSnp
  logic s6OpWBF;  // alloc_s6 opcode == WriteBackFull
  assign s4OpRN  = (io_alloc_s4.task_bits.chiOpcode == OP_READNOSNP);
  assign s6OpWBF = (io_alloc_s6.task_bits.chiOpcode == OP_WRITEBACKFULL);

  logic [N-1:0] conflictMask_ur, conflictMask_s4;
  for (genvar i = 0; i < N; i++) begin : g_conflict
    assign conflictMask_ur[i] = buffer_valid[i] & io_urgentRead_valid
                              & (urKey == bufKey[i]) & bufWBF[i];
    assign conflictMask_s4[i] = buffer_valid[i] & io_alloc_s4_valid
                              & (s4Key == bufKey[i]) & s4OpRN & bufWBF[i];
  end
  // 与 in-flight s6 的冲突(第 16 项)
  logic conflict_ur_s6, conflict_s4_s6;
  assign conflict_ur_s6 = io_alloc_s6_valid & io_urgentRead_valid & (urKey == s6Key) & s6OpWBF;
  assign conflict_s4_s6 = io_alloc_s6_valid & io_alloc_s4_valid & (s4Key == s6Key) & s4OpRN & s6OpWBF;

  logic bypass_ur, bypass_s4;
  assign bypass_ur = io_urgentRead_valid & (|{conflictMask_ur, conflict_ur_s6});
  assign bypass_s4 = io_alloc_s4_valid   & (|{conflictMask_s4, conflict_s4_s6});

  // 首个冲突槽号(golden conflictIdx_ur/s4, priority 0..15, 缺省 5'h10=none)
  logic [4:0] conflictIdx_ur, conflictIdx_s4;
  always_comb begin
    conflictIdx_ur = 5'h10;
    for (int k = N-1; k >= 0; k--) if (conflictMask_ur[k]) conflictIdx_ur = 5'(k);
  end
  always_comb begin
    conflictIdx_s4 = 5'h10;
    for (int k = N-1; k >= 0; k--) if (conflictMask_s4[k]) conflictIdx_s4 = 5'(k);
  end

  // -------------------- 空槽向量 / 插入索引 --------------------
  // idOH_s6_enc: alloc_s6 占用的首个空槽 one-hot(priority 0..15); 与 s4 空槽向量互斥,
  //   以便 s4/s6 同拍分配不同槽。
  logic [N-1:0] validVec, notValidVec;
  for (genvar i = 0; i < N; i++) begin : g_valid
    assign validVec[i]    = buffer_valid[i];
    assign notValidVec[i] = ~buffer_valid[i];
  end
  logic [N-1:0] idOH_s6;       // s6 首个空槽 one-hot
  always_comb begin
    idOH_s6 = '0;
    for (int k = N-1; k >= 0; k--) if (~buffer_valid[k]) idOH_s6 = (16'h1 << k);
  end
  // freeVec_s4: s4 可用空槽(排除 s6 已占的槽, 若 s6 valid)
  logic [N-1:0] freeVec_s4;
  for (genvar i = 0; i < N; i++) begin : g_free
    assign freeVec_s4[i] = io_alloc_s6_valid ? (~buffer_valid[i] & ~idOH_s6[i])
                                             : ~buffer_valid[i];
  end
  // s6 插入索引 = idOH_s6 的编码; s4 插入索引 = freeVec_s4 首个置位(priority 0..15)
  logic [IDX_W-1:0] insertIdx_s6, insertIdx_s4;
  always_comb begin
    insertIdx_s6 = '0;
    for (int k = N-1; k >= 0; k--) if (idOH_s6[k]) insertIdx_s6 = IDX_W'(k);
  end
  always_comb begin
    insertIdx_s4 = '0;
    for (int k = N-1; k >= 0; k--) if (freeVec_s4[k]) insertIdx_s4 = IDX_W'(k);
  end
  logic canAlloc_s6, canAlloc_s4;
  assign canAlloc_s6 = io_alloc_s6_valid & (|notValidVec);      // golden: |_full_s6_T
  assign canAlloc_s4 = io_alloc_s4_valid & (|freeVec_s4) & ~bypass_s4;

  // 每条目 s4/s6 分配命中
  logic [N-1:0] allocHere_s6, allocHere_s4;
  for (genvar i = 0; i < N; i++) begin : g_allochere
    assign allocHere_s6[i] = canAlloc_s6 & (insertIdx_s6 == IDX_W'(i));
    assign allocHere_s4[i] = canAlloc_s4 & (insertIdx_s4 == IDX_W'(i));
  end

  // -------------------- blockByResp(TXREQ valid 屏蔽) --------------------
  // 若某 respInfo 命中 txreqArb 选中条目的 reqID(w_snpRsp & ~w_compdata & opcode∈{7,26})
  // 且被选任务是 WBF, 则该 TXREQ 被 snoop-resp 阻塞, valid 撤销。
  logic txreqOutWBF;
  assign txreqOutWBF = (txreqArb_out_chiOpcode == OP_WRITEBACKFULL);
  logic [N-1:0] blockByResp;
  for (genvar i = 0; i < N; i++) begin : g_block
    assign blockByResp[i] =
        io_respInfo[i].valid & ~io_respInfo[i].w_compdata & io_respInfo[i].w_snpRsp
      & ((io_respInfo[i].opcode == OP_SNP_A) | (io_respInfo[i].opcode == OP_SNP_B))
      & (io_respInfo[i].reqID == txreqArb_out_reqID) & txreqOutWBF;
  end
  logic urgentTxreq;                 // urgentRead 抢占 TXREQ
  assign urgentTxreq = io_urgentRead_valid & ~bypass_ur;
  logic txreq_valid_int;             // golden io_txreq_valid_0
  assign txreq_valid_int = (txreqArb_out_valid & (blockByResp == 16'h0)) | urgentTxreq;

  // txreqArb 出队 fire(io_out_ready=1, 但仅当 ~urgent 或 bypass_ur 时真正出队)
  logic txreqFire;
  assign txreqFire = io_txreq_ready & txreq_valid_int & (~io_urgentRead_valid | bypass_ur);
  // txreqArb 选中条目当前是否 WBF(golden _GEN_86)
  logic txreqChosenWBF;
  assign txreqChosenWBF = bufWBF[txreqArb_chosen];
  // txdatArb 出队 fire
  logic txdatFire;
  assign txdatFire = io_txdat_ready & txdatArb_out_valid;

  // -------------------- 每条目下一拍 s_issueReq 置位(TXREQ 已发) --------------------
  // golden: state_s_issueReq[i]' = txreqFire & txreqChosenWBF & (chosen==i) | ...保持
  logic [N-1:0] setIssueReq;
  for (genvar i = 0; i < N; i++) begin : g_setreq
    assign setIssueReq[i] = txreqFire & txreqChosenWBF & (txreqArb_chosen == IDX_W'(i));
  end

  // -------------------- rnRxdat 数据/beatValids 更新辅助 --------------------
  // newBeatValids: 命中条目当前 beatValids | (1<<dataID[1])
  logic [1:0] curBeat, newBeatValids;
  assign curBeat = {beatValids_1[bufID_dat], beatValids_0[bufID_dat]};
  assign newBeatValids = curBeat | (2'h1 << io_rnRxdat_bits_dataID[1]);
  logic rnDatHit;                    // golden _GEN_151 = rnRxdat_valid & anyMatchDat
  assign rnDatHit = io_rnRxdat_valid & anyMatchDat;
  logic rnDatIsData;                 // resp[2] = DataResp(带数据)
  assign rnDatIsData = io_rnRxdat_bits_resp[2];

  // -------------------- snRxrsp opcode 解码 --------------------
  logic snIsDBID, snIsCompDBID, snIsRN, snRspHit;
  assign snIsDBID     = (io_snRxrsp_bits_opcode == OP_DBIDRESP);     // _GEN_169
  assign snIsCompDBID = (io_snRxrsp_bits_opcode == OP_COMPDBIDRESP); // _GEN_185
  assign snIsRN       = (io_snRxrsp_bits_opcode == OP_READNOSNP);    // _GEN_2 (comp on ReadNoSnp)
  assign snRspHit     = io_snRxrsp_valid & anyMatchSn;               // _GEN_186
  logic snDbidOrComp;
  assign snDbidOrComp = snIsDBID | snIsCompDBID;                     // _GEN_187
  logic rnRspHit;
  assign rnRspHit = io_rnRxrsp_valid & anyMatchRsp;                  // _GEN_168

  // ==========================================================================
  // 每条目跨条目更新辅助(golden _GEN_102.. / _GEN_119.. / _GEN_152.. 等)
  // ==========================================================================
  // rnDatClr[i]: rnRxdat 命中且非数据响应(resp[2]=0) 命中条目 i —— 该拍会“清 valid”那条路径
  //   (golden _GEN_119/121/.../148, 用 bufID_dat 选中)
  logic [N-1:0] rnDatClr;
  for (genvar i = 0; i < N; i++) begin : g_rndatclr
    assign rnDatClr[i] = rnDatHit & ~rnDatIsData & (bufID_dat == IDX_W'(i));
  end
  // rnDatWrData[i]: rnRxdat 命中且数据响应 命中条目 i(golden _GEN_152.._GEN_167)
  logic [N-1:0] rnDatWrData;
  for (genvar i = 0; i < N; i++) begin : g_rndatwr
    assign rnDatWrData[i] = rnDatHit & rnDatIsData & (bufID_dat == IDX_W'(i));
  end

  // keepValidCore[i] = golden _GEN_102.._GEN_117:
  //   (~txreqFire | txreqChosenWBF | ~(txreqArb_chosen==i))
  //   & (canAlloc_s4 ? (insertIdx_s4==i | allocHere_s6_i | valid_i) : (allocHere_s6_i | valid_i))
  logic [N-1:0] keepValidCore;
  for (genvar i = 0; i < N; i++) begin : g_keepvalid
    logic notReqClear;      // TXREQ 发出后 s_issueReq 置位, 不影响 valid(仅非WBF发req时清? 见下)
    logic allocOrValid;
    assign notReqClear = ~txreqFire | txreqChosenWBF | ~(txreqArb_chosen == IDX_W'(i));
    assign allocOrValid = canAlloc_s4
        ? ((insertIdx_s4 == IDX_W'(i)) | allocHere_s6[i] | buffer_valid[i])
        : (allocHere_s6[i] | buffer_valid[i]);
    assign keepValidCore[i] = notReqClear & allocOrValid;
  end
  // will_free[i]: 条目完成所有阶段, 本拍应释放
  logic [N-1:0] willFree;
  for (genvar i = 0; i < N; i++) begin : g_willfree
    assign willFree[i] = buffer_valid[i] & bufWBF[i] & state_s_issueReq[i]
                       & state_s_issueDat[i] & state_w_dbid[i] & state_w_comp[i]
                       & state_w_datRsp[i];
  end

  // ==========================================================================
  // 每条目寄存器更新(generate 展开; 逐条目等价 golden always 块)
  // ==========================================================================
  for (genvar i = 0; i < N; i++) begin : g_entry
    localparam logic [IDX_W-1:0] IDX = IDX_W'(i);

    // ---- valid ----
    logic next_valid;
    always_comb begin
      // golden: ~willFree & (rnRspHit ? ~(bufID_rsp==i | rnDatClr_i) & keepValidCore_i
      //                                : ~rnDatClr_i & keepValidCore_i)
      if (rnRspHit)
        next_valid = ~willFree[i] & ~((bufID_rsp == IDX) | rnDatClr[i]) & keepValidCore[i];
      else
        next_valid = ~willFree[i] & ~rnDatClr[i] & keepValidCore[i];
    end

    // ---- s_issueReq ----
    logic next_s_issueReq;
    assign next_s_issueReq = setIssueReq[i]
                           | (~(allocHere_s4[i] | allocHere_s6[i]) & state_s_issueReq[i]);

    // ---- s_issueDat ----
    logic next_s_issueDat;
    assign next_s_issueDat = (txdatFire & (txdatArb_chosen == IDX))
        | (allocHere_s4[i] ? io_alloc_s4.state_s_issueDat
                           : (~allocHere_s6[i] & state_s_issueDat[i]));

    // ---- w_datRsp ----
    logic next_w_datRsp;
    always_comb begin
      if (rnDatWrData[i])       next_w_datRsp = &newBeatValids;
      else if (allocHere_s4[i]) next_w_datRsp = io_alloc_s4.state_w_datRsp;
      else                      next_w_datRsp = allocHere_s6[i] | state_w_datRsp[i];
    end

    // ---- w_dbid / w_comp (含 snRxrsp 跨条目更新) ----
    // 基线保持值(golden _GEN_21/22..: ~allocHere_s6_i & state; alloc_s4 覆盖)
    logic keep_w_dbid, keep_w_comp;
    assign keep_w_dbid = ~allocHere_s6[i] & state_w_dbid[i];
    assign keep_w_comp = ~allocHere_s6[i] & state_w_comp[i];
    // alloc_s4 覆盖后的基线(golden _GEN_189/190..)
    logic base_w_dbid, base_w_comp;
    assign base_w_dbid = allocHere_s4[i] ? io_alloc_s4.state_w_dbid : keep_w_dbid;
    assign base_w_comp = allocHere_s4[i] ? io_alloc_s4.state_w_comp : keep_w_comp;
    // snRxrsp 命中该条目
    logic snHitHere;
    assign snHitHere = (bufID_sn == IDX);
    logic next_w_dbid, next_w_comp;
    always_comb begin
      if (snRspHit) begin
        if (snIsDBID) begin
          // DBIDResp: 命中条目置 w_dbid; w_comp 走 base
          next_w_dbid = snHitHere | base_w_dbid;
          next_w_comp = snHitHere | base_w_comp;
        end
        else begin
          // CompDBIDResp(_GEN_185): 置 w_dbid; ReadNoSnp(_GEN_2)时置 w_comp
          next_w_dbid = (snIsCompDBID & snHitHere) | base_w_dbid;
          next_w_comp = (~snIsCompDBID & snIsRN & snHitHere) | base_w_comp;
        end
      end
      else begin
        next_w_dbid = base_w_dbid;
        next_w_comp = base_w_comp;
      end
    end

    // ---- task payload 更新 ----
    mem_task_t next_task;
    always_comb begin
      next_task = buffer_task[i];
      // 大多数字段: alloc_s4 优先, 否则 alloc_s6, 否则保持
      if (allocHere_s4[i]) begin
        next_task.set        = io_alloc_s4.task_bits.set;
        next_task.bank       = io_alloc_s4.task_bits.bank;
        next_task.tag        = io_alloc_s4.task_bits.tag;
        next_task.off        = io_alloc_s4.task_bits.off;
        next_task.size       = 3'h6;   // golden: s4 固定 size=6
        next_task.refillTask = io_alloc_s4.task_bits.refillTask;
        next_task.bufID      = io_alloc_s4.task_bits.bufID;
        next_task.reqID      = io_alloc_s4.task_bits.reqID;
        next_task.replSnp    = io_alloc_s4.task_bits.replSnp;
        next_task.snpVec_0   = io_alloc_s4.task_bits.snpVec_0;
        next_task.tgtID      = io_alloc_s4.task_bits.tgtID;
        next_task.srcID      = io_alloc_s4.task_bits.srcID;
        next_task.homeNID    = io_alloc_s4.task_bits.homeNID;
        next_task.dbID       = io_alloc_s4.task_bits.dbID;
        next_task.fwdNID     = io_alloc_s4.task_bits.fwdNID;
        next_task.fwdTxnID   = io_alloc_s4.task_bits.fwdTxnID;
        next_task.chiOpcode  = io_alloc_s4.task_bits.chiOpcode;
        next_task.resp       = io_alloc_s4.task_bits.resp;
        next_task.fwdState   = io_alloc_s4.task_bits.fwdState;
        next_task.pCrdType   = io_alloc_s4.task_bits.pCrdType;
        next_task.retToSrc   = io_alloc_s4.task_bits.retToSrc;
        next_task.doNotGoToSD= io_alloc_s4.task_bits.doNotGoToSD;
        next_task.order      = 2'h0;   // golden: s4 固定 order=0
      end
      else if (allocHere_s6[i]) begin
        next_task.set        = io_alloc_s6.task_bits.set;
        next_task.bank       = io_alloc_s6.task_bits.bank;
        next_task.tag        = io_alloc_s6.task_bits.tag;
        next_task.off        = io_alloc_s6.task_bits.off;
        next_task.size       = io_alloc_s6.task_bits.size;
        next_task.refillTask = io_alloc_s6.task_bits.refillTask;
        next_task.bufID      = io_alloc_s6.task_bits.bufID;
        next_task.reqID      = io_alloc_s6.task_bits.reqID;
        next_task.replSnp    = io_alloc_s6.task_bits.replSnp;
        next_task.snpVec_0   = io_alloc_s6.task_bits.snpVec_0;
        next_task.tgtID      = io_alloc_s6.task_bits.tgtID;
        next_task.srcID      = io_alloc_s6.task_bits.srcID;
        next_task.homeNID    = io_alloc_s6.task_bits.homeNID;
        next_task.dbID       = io_alloc_s6.task_bits.dbID;
        next_task.fwdNID     = io_alloc_s6.task_bits.fwdNID;
        next_task.fwdTxnID   = io_alloc_s6.task_bits.fwdTxnID;
        next_task.chiOpcode  = io_alloc_s6.task_bits.chiOpcode;
        next_task.resp       = io_alloc_s6.task_bits.resp;
        next_task.fwdState   = io_alloc_s6.task_bits.fwdState;
        next_task.pCrdType   = io_alloc_s6.task_bits.pCrdType;
        next_task.retToSrc   = io_alloc_s6.task_bits.retToSrc;
        next_task.doNotGoToSD= io_alloc_s6.task_bits.doNotGoToSD;
        next_task.order      = io_alloc_s6.task_bits.order;
      end
      // txnID: snRxrsp(dbid/comp)命中优先写 snRxrsp.dbID, 否则 alloc_s4/s6
      if (snRspHit & snDbidOrComp & snHitHere)
        next_task.txnID = io_snRxrsp_bits_dbID;
      else if (allocHere_s4[i])
        next_task.txnID = io_alloc_s4.task_bits.txnID;
      else if (allocHere_s6[i])
        next_task.txnID = io_alloc_s6.task_bits.txnID;
      // expCompAck/allowRetry/memAttr/snpAttr: 仅 s6 写(golden ~allocHere_s4 & (s6?..:keep))
      next_task.expCompAck = ~allocHere_s4[i]
          & (allocHere_s6[i] ? io_alloc_s6.task_bits.expCompAck : buffer_task[i].expCompAck);
      next_task.allowRetry = allocHere_s4[i]
          | (allocHere_s6[i] ? io_alloc_s6.task_bits.allowRetry : buffer_task[i].allowRetry);
      next_task.memAttr_allocate = ~allocHere_s4[i]
          & (allocHere_s6[i] ? io_alloc_s6.task_bits.memAttr_allocate : buffer_task[i].memAttr_allocate);
      next_task.memAttr_cacheable = ~allocHere_s4[i]
          & (allocHere_s6[i] ? io_alloc_s6.task_bits.memAttr_cacheable : buffer_task[i].memAttr_cacheable);
      next_task.memAttr_device = ~allocHere_s4[i]
          & (allocHere_s6[i] ? io_alloc_s6.task_bits.memAttr_device : buffer_task[i].memAttr_device);
      next_task.memAttr_ewa = ~allocHere_s4[i]
          & (allocHere_s6[i] ? io_alloc_s6.task_bits.memAttr_ewa : buffer_task[i].memAttr_ewa);
      next_task.snpAttr = ~allocHere_s4[i]
          & (allocHere_s6[i] ? io_alloc_s6.task_bits.snpAttr : buffer_task[i].snpAttr);
    end

    // ---- data0 / data1 (rnRxdat 数据写 / s6 入队写) ----
    logic [DATA_W-1:0] next_data0, next_data1;
    always_comb begin
      if (rnDatWrData[i] & ~io_rnRxdat_bits_dataID[1]) next_data0 = io_rnRxdat_bits_data_data;
      else if (allocHere_s6[i])                        next_data0 = io_alloc_s6.data0;
      else                                             next_data0 = data0[i];
      if (rnDatWrData[i] & io_rnRxdat_bits_dataID[1])  next_data1 = io_rnRxdat_bits_data_data;
      else if (allocHere_s6[i])                        next_data1 = io_alloc_s6.data1;
      else                                             next_data1 = data1[i];
    end

    // ---- beatValids ----
    logic next_bv0, next_bv1;
    always_comb begin
      if (rnDatWrData[i]) begin
        next_bv0 = newBeatValids[0];
        next_bv1 = newBeatValids[1];
      end
      else begin
        next_bv0 = ~allocHere_s4[i] & (allocHere_s6[i] | beatValids_0[i]);
        next_bv1 = ~allocHere_s4[i] & (allocHere_s6[i] | beatValids_1[i]);
      end
    end

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        buffer_valid[i]     <= 1'b0;
        buffer_task[i]      <= '0;
        state_s_issueReq[i] <= 1'b0;
        state_s_issueDat[i] <= 1'b0;
        state_w_datRsp[i]   <= 1'b0;
        state_w_dbid[i]     <= 1'b0;
        state_w_comp[i]     <= 1'b0;
        data0[i]            <= '0;
        data1[i]            <= '0;
        beatValids_0[i]     <= 1'b0;
        beatValids_1[i]     <= 1'b0;
        bufferTimer[i]      <= '0;
        REG_valid_d[i]      <= 1'b0;
      end
      else begin
        buffer_valid[i]     <= next_valid;
        buffer_task[i]      <= next_task;
        state_s_issueReq[i] <= next_s_issueReq;
        state_s_issueDat[i] <= next_s_issueDat;
        state_w_datRsp[i]   <= next_w_datRsp;
        state_w_dbid[i]     <= next_w_dbid;
        state_w_comp[i]     <= next_w_comp;
        data0[i]            <= next_data0;
        data1[i]            <= next_data1;
        beatValids_0[i]     <= next_bv0;
        beatValids_1[i]     <= next_bv1;
        // bufferTimer: valid→invalid 清零, 否则 valid 时自增(泄漏检测)
        if (REG_valid_d[i] & ~buffer_valid[i]) bufferTimer[i] <= '0;
        else if (buffer_valid[i])              bufferTimer[i] <= TIMER_W'(bufferTimer[i] + 16'h1);
        REG_valid_d[i]      <= buffer_valid[i];
      end
    end
  end

  // ==========================================================================
  // fakeRsp / bypassData 共享寄存器(bypass 命中时造两拍伪响应回程)
  // ==========================================================================
  // 数据取被冲突条目的存储数据(golden _GEN_3/_GEN_4 按 conflictIdx 选; idx=16 时取 s6 in-flight)
  // conflictIdx 0..15 => buffer data; 5'h10(=16) => alloc_s6 数据
  logic [DATA_W-1:0] fakeData0_s4, fakeData0_ur, fakeData1_s4, fakeData1_ur;
  always_comb begin
    fakeData0_s4 = (conflictIdx_s4 == 5'h10) ? io_alloc_s6.data0 : data0[conflictIdx_s4[3:0]];
    fakeData0_ur = (conflictIdx_ur == 5'h10) ? io_alloc_s6.data0 : data0[conflictIdx_ur[3:0]];
    fakeData1_s4 = (conflictIdx_s4 == 5'h10) ? io_alloc_s6.data1 : data1[conflictIdx_s4[3:0]];
    fakeData1_ur = (conflictIdx_ur == 5'h10) ? io_alloc_s6.data1 : data1[conflictIdx_ur[3:0]];
  end
  logic anyBypass;
  assign anyBypass = bypass_ur | bypass_s4;   // golden _io_bypassData_1_valid_T
  logic [TXNID_W-1:0] fakeTxnID;
  assign fakeTxnID = bypass_s4 ? io_alloc_s4.task_bits.txnID : io_urgentRead_bits_txnID;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fakeRsp_0_txnID  <= '0;
      fakeRsp_0_opcode <= '0;
      fakeRsp_0_data   <= '0;
      fakeRsp_1_txnID  <= '0;
      fakeRsp_1_opcode <= '0;
      fakeRsp_1_dataID <= '0;
      fakeRsp_1_data   <= '0;
      bypassData_0_valid_d <= 1'b0;
      bypassData_1_valid_d <= 1'b0;
    end
    else begin
      if (anyBypass) begin
        fakeRsp_0_txnID  <= fakeTxnID;
        fakeRsp_0_opcode <= 7'h4;
        fakeRsp_0_data   <= bypass_s4 ? fakeData0_s4 : fakeData0_ur;
        fakeRsp_1_txnID  <= fakeTxnID;
        fakeRsp_1_opcode <= 7'h4;
        fakeRsp_1_dataID <= 2'h2;
        fakeRsp_1_data   <= bypass_s4 ? fakeData1_s4 : fakeData1_ur;
      end
      bypassData_0_valid_d <= anyBypass;
      bypassData_1_valid_d <= anyBypass;
    end
  end

  // ==========================================================================
  // 输出装配
  // ==========================================================================
  // urgentRead ready: TXREQ 就绪且非 bypass_ur, 或 bypass_ur 且非 bypass_s4
  assign io_urgentRead_ready = (io_txreq_ready & ~bypass_ur) | (bypass_ur & ~bypass_s4);

  // TXREQ(urgentTxreq 抢占透传, 否则仲裁器结果)
  assign io_txreq_valid            = txreq_valid_int;
  assign io_txreq_bits_set         = urgentTxreq ? io_urgentRead_bits_set   : txreqArb_out_set;
  assign io_txreq_bits_bank        = urgentTxreq ? io_urgentRead_bits_bank  : txreqArb_out_bank;
  assign io_txreq_bits_tag         = urgentTxreq ? io_urgentRead_bits_tag   : txreqArb_out_tag;
  assign io_txreq_bits_size        = urgentTxreq ? 3'h6                     : txreqArb_out_size;
  assign io_txreq_bits_tgtID       = urgentTxreq ? io_urgentRead_bits_tgtID : txreqArb_out_tgtID;
  assign io_txreq_bits_srcID       = urgentTxreq ? io_urgentRead_bits_srcID : txreqArb_out_srcID;
  assign io_txreq_bits_txnID       = urgentTxreq ? io_urgentRead_bits_txnID : txreqArb_out_txnID;
  assign io_txreq_bits_chiOpcode   = urgentTxreq ? 7'h4                     : txreqArb_out_chiOpcode;
  assign io_txreq_bits_pCrdType    = urgentTxreq ? io_urgentRead_bits_pCrdType : txreqArb_out_pCrdType;
  assign io_txreq_bits_expCompAck  = ~urgentTxreq & txreqArb_out_expCompAck;
  assign io_txreq_bits_allowRetry  = urgentTxreq | txreqArb_out_allowRetry;
  assign io_txreq_bits_order       = urgentTxreq ? 2'h0 : txreqArb_out_order;
  assign io_txreq_bits_memAttr_allocate  = ~urgentTxreq & txreqArb_out_memAttr_allocate;
  assign io_txreq_bits_memAttr_cacheable = ~urgentTxreq & txreqArb_out_memAttr_cacheable;
  assign io_txreq_bits_memAttr_device    = ~urgentTxreq & txreqArb_out_memAttr_device;
  assign io_txreq_bits_memAttr_ewa       = ~urgentTxreq & txreqArb_out_memAttr_ewa;
  assign io_txreq_bits_snpAttr           = ~urgentTxreq & txreqArb_out_snpAttr;

  // TXDAT valid(数据/task 端口由 txdatArb 直接驱动, 见实例化)
  assign io_txdat_valid = txdatArb_out_valid;

  // bypassData
  assign io_bypassData_0_valid       = bypassData_0_valid_d;
  assign io_bypassData_0_bits_txnID  = fakeRsp_0_txnID;
  assign io_bypassData_0_bits_opcode = fakeRsp_0_opcode;
  assign io_bypassData_0_bits_data_data = fakeRsp_0_data;
  assign io_bypassData_1_valid       = bypassData_1_valid_d;
  assign io_bypassData_1_bits_txnID  = fakeRsp_1_txnID;
  assign io_bypassData_1_bits_opcode = fakeRsp_1_opcode;
  assign io_bypassData_1_bits_dataID = fakeRsp_1_dataID;
  assign io_bypassData_1_bits_data_data = fakeRsp_1_data;

  // memInfo(16 路条目快照)
  for (genvar i = 0; i < N; i++) begin : g_meminfo
    assign io_memInfo_valid[i]    = buffer_valid[i];
    assign io_memInfo_set[i]      = buffer_task[i].set;
    assign io_memInfo_tag[i]      = buffer_task[i].tag;
    assign io_memInfo_opcode[i]   = buffer_task[i].chiOpcode;
    assign io_memInfo_reqID[i]    = buffer_task[i].reqID;
    assign io_memInfo_w_datRsp[i] = state_w_datRsp[i];
  end
  // -------------------- txreqArb(FastArbiter_50): 挑 w_datRsp & ~s_issueReq 条目发 TXREQ --------------------
  FastArbiter_50 txreqArb (
    .clock (clock),
    .reset (reset),
    .io_in_0_valid ((buffer_valid[0] & state_w_datRsp[0]) & ~state_s_issueReq[0]),
    .io_in_0_bits_set (buffer_task[0].set), .io_in_0_bits_bank (buffer_task[0].bank), .io_in_0_bits_tag (buffer_task[0].tag),
    .io_in_0_bits_off (buffer_task[0].off), .io_in_0_bits_size (buffer_task[0].size), .io_in_0_bits_refillTask (buffer_task[0].refillTask),
    .io_in_0_bits_bufID (buffer_task[0].bufID), .io_in_0_bits_reqID (buffer_task[0].reqID), .io_in_0_bits_replSnp (buffer_task[0].replSnp),
    .io_in_0_bits_snpVec_0 (buffer_task[0].snpVec_0), .io_in_0_bits_tgtID (buffer_task[0].tgtID), .io_in_0_bits_srcID (buffer_task[0].srcID),
    .io_in_0_bits_txnID (buffer_task[0].txnID), .io_in_0_bits_dbID (buffer_task[0].dbID), .io_in_0_bits_fwdNID (buffer_task[0].fwdNID),
    .io_in_0_bits_fwdTxnID (buffer_task[0].fwdTxnID), .io_in_0_bits_chiOpcode (buffer_task[0].chiOpcode), .io_in_0_bits_resp (buffer_task[0].resp),
    .io_in_0_bits_fwdState (buffer_task[0].fwdState), .io_in_0_bits_pCrdType (buffer_task[0].pCrdType), .io_in_0_bits_retToSrc (buffer_task[0].retToSrc),
    .io_in_0_bits_doNotGoToSD (buffer_task[0].doNotGoToSD), .io_in_0_bits_expCompAck (buffer_task[0].expCompAck), .io_in_0_bits_allowRetry (buffer_task[0].allowRetry),
    .io_in_0_bits_order (buffer_task[0].order), .io_in_0_bits_memAttr_allocate (buffer_task[0].memAttr_allocate), .io_in_0_bits_memAttr_cacheable (buffer_task[0].memAttr_cacheable),
    .io_in_0_bits_memAttr_device (buffer_task[0].memAttr_device), .io_in_0_bits_memAttr_ewa (buffer_task[0].memAttr_ewa), .io_in_0_bits_snpAttr (buffer_task[0].snpAttr),
    .io_in_1_valid ((buffer_valid[1] & state_w_datRsp[1]) & ~state_s_issueReq[1]),
    .io_in_1_bits_set (buffer_task[1].set), .io_in_1_bits_bank (buffer_task[1].bank), .io_in_1_bits_tag (buffer_task[1].tag),
    .io_in_1_bits_off (buffer_task[1].off), .io_in_1_bits_size (buffer_task[1].size), .io_in_1_bits_refillTask (buffer_task[1].refillTask),
    .io_in_1_bits_bufID (buffer_task[1].bufID), .io_in_1_bits_reqID (buffer_task[1].reqID), .io_in_1_bits_replSnp (buffer_task[1].replSnp),
    .io_in_1_bits_snpVec_0 (buffer_task[1].snpVec_0), .io_in_1_bits_tgtID (buffer_task[1].tgtID), .io_in_1_bits_srcID (buffer_task[1].srcID),
    .io_in_1_bits_txnID (buffer_task[1].txnID), .io_in_1_bits_dbID (buffer_task[1].dbID), .io_in_1_bits_fwdNID (buffer_task[1].fwdNID),
    .io_in_1_bits_fwdTxnID (buffer_task[1].fwdTxnID), .io_in_1_bits_chiOpcode (buffer_task[1].chiOpcode), .io_in_1_bits_resp (buffer_task[1].resp),
    .io_in_1_bits_fwdState (buffer_task[1].fwdState), .io_in_1_bits_pCrdType (buffer_task[1].pCrdType), .io_in_1_bits_retToSrc (buffer_task[1].retToSrc),
    .io_in_1_bits_doNotGoToSD (buffer_task[1].doNotGoToSD), .io_in_1_bits_expCompAck (buffer_task[1].expCompAck), .io_in_1_bits_allowRetry (buffer_task[1].allowRetry),
    .io_in_1_bits_order (buffer_task[1].order), .io_in_1_bits_memAttr_allocate (buffer_task[1].memAttr_allocate), .io_in_1_bits_memAttr_cacheable (buffer_task[1].memAttr_cacheable),
    .io_in_1_bits_memAttr_device (buffer_task[1].memAttr_device), .io_in_1_bits_memAttr_ewa (buffer_task[1].memAttr_ewa), .io_in_1_bits_snpAttr (buffer_task[1].snpAttr),
    .io_in_2_valid ((buffer_valid[2] & state_w_datRsp[2]) & ~state_s_issueReq[2]),
    .io_in_2_bits_set (buffer_task[2].set), .io_in_2_bits_bank (buffer_task[2].bank), .io_in_2_bits_tag (buffer_task[2].tag),
    .io_in_2_bits_off (buffer_task[2].off), .io_in_2_bits_size (buffer_task[2].size), .io_in_2_bits_refillTask (buffer_task[2].refillTask),
    .io_in_2_bits_bufID (buffer_task[2].bufID), .io_in_2_bits_reqID (buffer_task[2].reqID), .io_in_2_bits_replSnp (buffer_task[2].replSnp),
    .io_in_2_bits_snpVec_0 (buffer_task[2].snpVec_0), .io_in_2_bits_tgtID (buffer_task[2].tgtID), .io_in_2_bits_srcID (buffer_task[2].srcID),
    .io_in_2_bits_txnID (buffer_task[2].txnID), .io_in_2_bits_dbID (buffer_task[2].dbID), .io_in_2_bits_fwdNID (buffer_task[2].fwdNID),
    .io_in_2_bits_fwdTxnID (buffer_task[2].fwdTxnID), .io_in_2_bits_chiOpcode (buffer_task[2].chiOpcode), .io_in_2_bits_resp (buffer_task[2].resp),
    .io_in_2_bits_fwdState (buffer_task[2].fwdState), .io_in_2_bits_pCrdType (buffer_task[2].pCrdType), .io_in_2_bits_retToSrc (buffer_task[2].retToSrc),
    .io_in_2_bits_doNotGoToSD (buffer_task[2].doNotGoToSD), .io_in_2_bits_expCompAck (buffer_task[2].expCompAck), .io_in_2_bits_allowRetry (buffer_task[2].allowRetry),
    .io_in_2_bits_order (buffer_task[2].order), .io_in_2_bits_memAttr_allocate (buffer_task[2].memAttr_allocate), .io_in_2_bits_memAttr_cacheable (buffer_task[2].memAttr_cacheable),
    .io_in_2_bits_memAttr_device (buffer_task[2].memAttr_device), .io_in_2_bits_memAttr_ewa (buffer_task[2].memAttr_ewa), .io_in_2_bits_snpAttr (buffer_task[2].snpAttr),
    .io_in_3_valid ((buffer_valid[3] & state_w_datRsp[3]) & ~state_s_issueReq[3]),
    .io_in_3_bits_set (buffer_task[3].set), .io_in_3_bits_bank (buffer_task[3].bank), .io_in_3_bits_tag (buffer_task[3].tag),
    .io_in_3_bits_off (buffer_task[3].off), .io_in_3_bits_size (buffer_task[3].size), .io_in_3_bits_refillTask (buffer_task[3].refillTask),
    .io_in_3_bits_bufID (buffer_task[3].bufID), .io_in_3_bits_reqID (buffer_task[3].reqID), .io_in_3_bits_replSnp (buffer_task[3].replSnp),
    .io_in_3_bits_snpVec_0 (buffer_task[3].snpVec_0), .io_in_3_bits_tgtID (buffer_task[3].tgtID), .io_in_3_bits_srcID (buffer_task[3].srcID),
    .io_in_3_bits_txnID (buffer_task[3].txnID), .io_in_3_bits_dbID (buffer_task[3].dbID), .io_in_3_bits_fwdNID (buffer_task[3].fwdNID),
    .io_in_3_bits_fwdTxnID (buffer_task[3].fwdTxnID), .io_in_3_bits_chiOpcode (buffer_task[3].chiOpcode), .io_in_3_bits_resp (buffer_task[3].resp),
    .io_in_3_bits_fwdState (buffer_task[3].fwdState), .io_in_3_bits_pCrdType (buffer_task[3].pCrdType), .io_in_3_bits_retToSrc (buffer_task[3].retToSrc),
    .io_in_3_bits_doNotGoToSD (buffer_task[3].doNotGoToSD), .io_in_3_bits_expCompAck (buffer_task[3].expCompAck), .io_in_3_bits_allowRetry (buffer_task[3].allowRetry),
    .io_in_3_bits_order (buffer_task[3].order), .io_in_3_bits_memAttr_allocate (buffer_task[3].memAttr_allocate), .io_in_3_bits_memAttr_cacheable (buffer_task[3].memAttr_cacheable),
    .io_in_3_bits_memAttr_device (buffer_task[3].memAttr_device), .io_in_3_bits_memAttr_ewa (buffer_task[3].memAttr_ewa), .io_in_3_bits_snpAttr (buffer_task[3].snpAttr),
    .io_in_4_valid ((buffer_valid[4] & state_w_datRsp[4]) & ~state_s_issueReq[4]),
    .io_in_4_bits_set (buffer_task[4].set), .io_in_4_bits_bank (buffer_task[4].bank), .io_in_4_bits_tag (buffer_task[4].tag),
    .io_in_4_bits_off (buffer_task[4].off), .io_in_4_bits_size (buffer_task[4].size), .io_in_4_bits_refillTask (buffer_task[4].refillTask),
    .io_in_4_bits_bufID (buffer_task[4].bufID), .io_in_4_bits_reqID (buffer_task[4].reqID), .io_in_4_bits_replSnp (buffer_task[4].replSnp),
    .io_in_4_bits_snpVec_0 (buffer_task[4].snpVec_0), .io_in_4_bits_tgtID (buffer_task[4].tgtID), .io_in_4_bits_srcID (buffer_task[4].srcID),
    .io_in_4_bits_txnID (buffer_task[4].txnID), .io_in_4_bits_dbID (buffer_task[4].dbID), .io_in_4_bits_fwdNID (buffer_task[4].fwdNID),
    .io_in_4_bits_fwdTxnID (buffer_task[4].fwdTxnID), .io_in_4_bits_chiOpcode (buffer_task[4].chiOpcode), .io_in_4_bits_resp (buffer_task[4].resp),
    .io_in_4_bits_fwdState (buffer_task[4].fwdState), .io_in_4_bits_pCrdType (buffer_task[4].pCrdType), .io_in_4_bits_retToSrc (buffer_task[4].retToSrc),
    .io_in_4_bits_doNotGoToSD (buffer_task[4].doNotGoToSD), .io_in_4_bits_expCompAck (buffer_task[4].expCompAck), .io_in_4_bits_allowRetry (buffer_task[4].allowRetry),
    .io_in_4_bits_order (buffer_task[4].order), .io_in_4_bits_memAttr_allocate (buffer_task[4].memAttr_allocate), .io_in_4_bits_memAttr_cacheable (buffer_task[4].memAttr_cacheable),
    .io_in_4_bits_memAttr_device (buffer_task[4].memAttr_device), .io_in_4_bits_memAttr_ewa (buffer_task[4].memAttr_ewa), .io_in_4_bits_snpAttr (buffer_task[4].snpAttr),
    .io_in_5_valid ((buffer_valid[5] & state_w_datRsp[5]) & ~state_s_issueReq[5]),
    .io_in_5_bits_set (buffer_task[5].set), .io_in_5_bits_bank (buffer_task[5].bank), .io_in_5_bits_tag (buffer_task[5].tag),
    .io_in_5_bits_off (buffer_task[5].off), .io_in_5_bits_size (buffer_task[5].size), .io_in_5_bits_refillTask (buffer_task[5].refillTask),
    .io_in_5_bits_bufID (buffer_task[5].bufID), .io_in_5_bits_reqID (buffer_task[5].reqID), .io_in_5_bits_replSnp (buffer_task[5].replSnp),
    .io_in_5_bits_snpVec_0 (buffer_task[5].snpVec_0), .io_in_5_bits_tgtID (buffer_task[5].tgtID), .io_in_5_bits_srcID (buffer_task[5].srcID),
    .io_in_5_bits_txnID (buffer_task[5].txnID), .io_in_5_bits_dbID (buffer_task[5].dbID), .io_in_5_bits_fwdNID (buffer_task[5].fwdNID),
    .io_in_5_bits_fwdTxnID (buffer_task[5].fwdTxnID), .io_in_5_bits_chiOpcode (buffer_task[5].chiOpcode), .io_in_5_bits_resp (buffer_task[5].resp),
    .io_in_5_bits_fwdState (buffer_task[5].fwdState), .io_in_5_bits_pCrdType (buffer_task[5].pCrdType), .io_in_5_bits_retToSrc (buffer_task[5].retToSrc),
    .io_in_5_bits_doNotGoToSD (buffer_task[5].doNotGoToSD), .io_in_5_bits_expCompAck (buffer_task[5].expCompAck), .io_in_5_bits_allowRetry (buffer_task[5].allowRetry),
    .io_in_5_bits_order (buffer_task[5].order), .io_in_5_bits_memAttr_allocate (buffer_task[5].memAttr_allocate), .io_in_5_bits_memAttr_cacheable (buffer_task[5].memAttr_cacheable),
    .io_in_5_bits_memAttr_device (buffer_task[5].memAttr_device), .io_in_5_bits_memAttr_ewa (buffer_task[5].memAttr_ewa), .io_in_5_bits_snpAttr (buffer_task[5].snpAttr),
    .io_in_6_valid ((buffer_valid[6] & state_w_datRsp[6]) & ~state_s_issueReq[6]),
    .io_in_6_bits_set (buffer_task[6].set), .io_in_6_bits_bank (buffer_task[6].bank), .io_in_6_bits_tag (buffer_task[6].tag),
    .io_in_6_bits_off (buffer_task[6].off), .io_in_6_bits_size (buffer_task[6].size), .io_in_6_bits_refillTask (buffer_task[6].refillTask),
    .io_in_6_bits_bufID (buffer_task[6].bufID), .io_in_6_bits_reqID (buffer_task[6].reqID), .io_in_6_bits_replSnp (buffer_task[6].replSnp),
    .io_in_6_bits_snpVec_0 (buffer_task[6].snpVec_0), .io_in_6_bits_tgtID (buffer_task[6].tgtID), .io_in_6_bits_srcID (buffer_task[6].srcID),
    .io_in_6_bits_txnID (buffer_task[6].txnID), .io_in_6_bits_dbID (buffer_task[6].dbID), .io_in_6_bits_fwdNID (buffer_task[6].fwdNID),
    .io_in_6_bits_fwdTxnID (buffer_task[6].fwdTxnID), .io_in_6_bits_chiOpcode (buffer_task[6].chiOpcode), .io_in_6_bits_resp (buffer_task[6].resp),
    .io_in_6_bits_fwdState (buffer_task[6].fwdState), .io_in_6_bits_pCrdType (buffer_task[6].pCrdType), .io_in_6_bits_retToSrc (buffer_task[6].retToSrc),
    .io_in_6_bits_doNotGoToSD (buffer_task[6].doNotGoToSD), .io_in_6_bits_expCompAck (buffer_task[6].expCompAck), .io_in_6_bits_allowRetry (buffer_task[6].allowRetry),
    .io_in_6_bits_order (buffer_task[6].order), .io_in_6_bits_memAttr_allocate (buffer_task[6].memAttr_allocate), .io_in_6_bits_memAttr_cacheable (buffer_task[6].memAttr_cacheable),
    .io_in_6_bits_memAttr_device (buffer_task[6].memAttr_device), .io_in_6_bits_memAttr_ewa (buffer_task[6].memAttr_ewa), .io_in_6_bits_snpAttr (buffer_task[6].snpAttr),
    .io_in_7_valid ((buffer_valid[7] & state_w_datRsp[7]) & ~state_s_issueReq[7]),
    .io_in_7_bits_set (buffer_task[7].set), .io_in_7_bits_bank (buffer_task[7].bank), .io_in_7_bits_tag (buffer_task[7].tag),
    .io_in_7_bits_off (buffer_task[7].off), .io_in_7_bits_size (buffer_task[7].size), .io_in_7_bits_refillTask (buffer_task[7].refillTask),
    .io_in_7_bits_bufID (buffer_task[7].bufID), .io_in_7_bits_reqID (buffer_task[7].reqID), .io_in_7_bits_replSnp (buffer_task[7].replSnp),
    .io_in_7_bits_snpVec_0 (buffer_task[7].snpVec_0), .io_in_7_bits_tgtID (buffer_task[7].tgtID), .io_in_7_bits_srcID (buffer_task[7].srcID),
    .io_in_7_bits_txnID (buffer_task[7].txnID), .io_in_7_bits_dbID (buffer_task[7].dbID), .io_in_7_bits_fwdNID (buffer_task[7].fwdNID),
    .io_in_7_bits_fwdTxnID (buffer_task[7].fwdTxnID), .io_in_7_bits_chiOpcode (buffer_task[7].chiOpcode), .io_in_7_bits_resp (buffer_task[7].resp),
    .io_in_7_bits_fwdState (buffer_task[7].fwdState), .io_in_7_bits_pCrdType (buffer_task[7].pCrdType), .io_in_7_bits_retToSrc (buffer_task[7].retToSrc),
    .io_in_7_bits_doNotGoToSD (buffer_task[7].doNotGoToSD), .io_in_7_bits_expCompAck (buffer_task[7].expCompAck), .io_in_7_bits_allowRetry (buffer_task[7].allowRetry),
    .io_in_7_bits_order (buffer_task[7].order), .io_in_7_bits_memAttr_allocate (buffer_task[7].memAttr_allocate), .io_in_7_bits_memAttr_cacheable (buffer_task[7].memAttr_cacheable),
    .io_in_7_bits_memAttr_device (buffer_task[7].memAttr_device), .io_in_7_bits_memAttr_ewa (buffer_task[7].memAttr_ewa), .io_in_7_bits_snpAttr (buffer_task[7].snpAttr),
    .io_in_8_valid ((buffer_valid[8] & state_w_datRsp[8]) & ~state_s_issueReq[8]),
    .io_in_8_bits_set (buffer_task[8].set), .io_in_8_bits_bank (buffer_task[8].bank), .io_in_8_bits_tag (buffer_task[8].tag),
    .io_in_8_bits_off (buffer_task[8].off), .io_in_8_bits_size (buffer_task[8].size), .io_in_8_bits_refillTask (buffer_task[8].refillTask),
    .io_in_8_bits_bufID (buffer_task[8].bufID), .io_in_8_bits_reqID (buffer_task[8].reqID), .io_in_8_bits_replSnp (buffer_task[8].replSnp),
    .io_in_8_bits_snpVec_0 (buffer_task[8].snpVec_0), .io_in_8_bits_tgtID (buffer_task[8].tgtID), .io_in_8_bits_srcID (buffer_task[8].srcID),
    .io_in_8_bits_txnID (buffer_task[8].txnID), .io_in_8_bits_dbID (buffer_task[8].dbID), .io_in_8_bits_fwdNID (buffer_task[8].fwdNID),
    .io_in_8_bits_fwdTxnID (buffer_task[8].fwdTxnID), .io_in_8_bits_chiOpcode (buffer_task[8].chiOpcode), .io_in_8_bits_resp (buffer_task[8].resp),
    .io_in_8_bits_fwdState (buffer_task[8].fwdState), .io_in_8_bits_pCrdType (buffer_task[8].pCrdType), .io_in_8_bits_retToSrc (buffer_task[8].retToSrc),
    .io_in_8_bits_doNotGoToSD (buffer_task[8].doNotGoToSD), .io_in_8_bits_expCompAck (buffer_task[8].expCompAck), .io_in_8_bits_allowRetry (buffer_task[8].allowRetry),
    .io_in_8_bits_order (buffer_task[8].order), .io_in_8_bits_memAttr_allocate (buffer_task[8].memAttr_allocate), .io_in_8_bits_memAttr_cacheable (buffer_task[8].memAttr_cacheable),
    .io_in_8_bits_memAttr_device (buffer_task[8].memAttr_device), .io_in_8_bits_memAttr_ewa (buffer_task[8].memAttr_ewa), .io_in_8_bits_snpAttr (buffer_task[8].snpAttr),
    .io_in_9_valid ((buffer_valid[9] & state_w_datRsp[9]) & ~state_s_issueReq[9]),
    .io_in_9_bits_set (buffer_task[9].set), .io_in_9_bits_bank (buffer_task[9].bank), .io_in_9_bits_tag (buffer_task[9].tag),
    .io_in_9_bits_off (buffer_task[9].off), .io_in_9_bits_size (buffer_task[9].size), .io_in_9_bits_refillTask (buffer_task[9].refillTask),
    .io_in_9_bits_bufID (buffer_task[9].bufID), .io_in_9_bits_reqID (buffer_task[9].reqID), .io_in_9_bits_replSnp (buffer_task[9].replSnp),
    .io_in_9_bits_snpVec_0 (buffer_task[9].snpVec_0), .io_in_9_bits_tgtID (buffer_task[9].tgtID), .io_in_9_bits_srcID (buffer_task[9].srcID),
    .io_in_9_bits_txnID (buffer_task[9].txnID), .io_in_9_bits_dbID (buffer_task[9].dbID), .io_in_9_bits_fwdNID (buffer_task[9].fwdNID),
    .io_in_9_bits_fwdTxnID (buffer_task[9].fwdTxnID), .io_in_9_bits_chiOpcode (buffer_task[9].chiOpcode), .io_in_9_bits_resp (buffer_task[9].resp),
    .io_in_9_bits_fwdState (buffer_task[9].fwdState), .io_in_9_bits_pCrdType (buffer_task[9].pCrdType), .io_in_9_bits_retToSrc (buffer_task[9].retToSrc),
    .io_in_9_bits_doNotGoToSD (buffer_task[9].doNotGoToSD), .io_in_9_bits_expCompAck (buffer_task[9].expCompAck), .io_in_9_bits_allowRetry (buffer_task[9].allowRetry),
    .io_in_9_bits_order (buffer_task[9].order), .io_in_9_bits_memAttr_allocate (buffer_task[9].memAttr_allocate), .io_in_9_bits_memAttr_cacheable (buffer_task[9].memAttr_cacheable),
    .io_in_9_bits_memAttr_device (buffer_task[9].memAttr_device), .io_in_9_bits_memAttr_ewa (buffer_task[9].memAttr_ewa), .io_in_9_bits_snpAttr (buffer_task[9].snpAttr),
    .io_in_10_valid ((buffer_valid[10] & state_w_datRsp[10]) & ~state_s_issueReq[10]),
    .io_in_10_bits_set (buffer_task[10].set), .io_in_10_bits_bank (buffer_task[10].bank), .io_in_10_bits_tag (buffer_task[10].tag),
    .io_in_10_bits_off (buffer_task[10].off), .io_in_10_bits_size (buffer_task[10].size), .io_in_10_bits_refillTask (buffer_task[10].refillTask),
    .io_in_10_bits_bufID (buffer_task[10].bufID), .io_in_10_bits_reqID (buffer_task[10].reqID), .io_in_10_bits_replSnp (buffer_task[10].replSnp),
    .io_in_10_bits_snpVec_0 (buffer_task[10].snpVec_0), .io_in_10_bits_tgtID (buffer_task[10].tgtID), .io_in_10_bits_srcID (buffer_task[10].srcID),
    .io_in_10_bits_txnID (buffer_task[10].txnID), .io_in_10_bits_dbID (buffer_task[10].dbID), .io_in_10_bits_fwdNID (buffer_task[10].fwdNID),
    .io_in_10_bits_fwdTxnID (buffer_task[10].fwdTxnID), .io_in_10_bits_chiOpcode (buffer_task[10].chiOpcode), .io_in_10_bits_resp (buffer_task[10].resp),
    .io_in_10_bits_fwdState (buffer_task[10].fwdState), .io_in_10_bits_pCrdType (buffer_task[10].pCrdType), .io_in_10_bits_retToSrc (buffer_task[10].retToSrc),
    .io_in_10_bits_doNotGoToSD (buffer_task[10].doNotGoToSD), .io_in_10_bits_expCompAck (buffer_task[10].expCompAck), .io_in_10_bits_allowRetry (buffer_task[10].allowRetry),
    .io_in_10_bits_order (buffer_task[10].order), .io_in_10_bits_memAttr_allocate (buffer_task[10].memAttr_allocate), .io_in_10_bits_memAttr_cacheable (buffer_task[10].memAttr_cacheable),
    .io_in_10_bits_memAttr_device (buffer_task[10].memAttr_device), .io_in_10_bits_memAttr_ewa (buffer_task[10].memAttr_ewa), .io_in_10_bits_snpAttr (buffer_task[10].snpAttr),
    .io_in_11_valid ((buffer_valid[11] & state_w_datRsp[11]) & ~state_s_issueReq[11]),
    .io_in_11_bits_set (buffer_task[11].set), .io_in_11_bits_bank (buffer_task[11].bank), .io_in_11_bits_tag (buffer_task[11].tag),
    .io_in_11_bits_off (buffer_task[11].off), .io_in_11_bits_size (buffer_task[11].size), .io_in_11_bits_refillTask (buffer_task[11].refillTask),
    .io_in_11_bits_bufID (buffer_task[11].bufID), .io_in_11_bits_reqID (buffer_task[11].reqID), .io_in_11_bits_replSnp (buffer_task[11].replSnp),
    .io_in_11_bits_snpVec_0 (buffer_task[11].snpVec_0), .io_in_11_bits_tgtID (buffer_task[11].tgtID), .io_in_11_bits_srcID (buffer_task[11].srcID),
    .io_in_11_bits_txnID (buffer_task[11].txnID), .io_in_11_bits_dbID (buffer_task[11].dbID), .io_in_11_bits_fwdNID (buffer_task[11].fwdNID),
    .io_in_11_bits_fwdTxnID (buffer_task[11].fwdTxnID), .io_in_11_bits_chiOpcode (buffer_task[11].chiOpcode), .io_in_11_bits_resp (buffer_task[11].resp),
    .io_in_11_bits_fwdState (buffer_task[11].fwdState), .io_in_11_bits_pCrdType (buffer_task[11].pCrdType), .io_in_11_bits_retToSrc (buffer_task[11].retToSrc),
    .io_in_11_bits_doNotGoToSD (buffer_task[11].doNotGoToSD), .io_in_11_bits_expCompAck (buffer_task[11].expCompAck), .io_in_11_bits_allowRetry (buffer_task[11].allowRetry),
    .io_in_11_bits_order (buffer_task[11].order), .io_in_11_bits_memAttr_allocate (buffer_task[11].memAttr_allocate), .io_in_11_bits_memAttr_cacheable (buffer_task[11].memAttr_cacheable),
    .io_in_11_bits_memAttr_device (buffer_task[11].memAttr_device), .io_in_11_bits_memAttr_ewa (buffer_task[11].memAttr_ewa), .io_in_11_bits_snpAttr (buffer_task[11].snpAttr),
    .io_in_12_valid ((buffer_valid[12] & state_w_datRsp[12]) & ~state_s_issueReq[12]),
    .io_in_12_bits_set (buffer_task[12].set), .io_in_12_bits_bank (buffer_task[12].bank), .io_in_12_bits_tag (buffer_task[12].tag),
    .io_in_12_bits_off (buffer_task[12].off), .io_in_12_bits_size (buffer_task[12].size), .io_in_12_bits_refillTask (buffer_task[12].refillTask),
    .io_in_12_bits_bufID (buffer_task[12].bufID), .io_in_12_bits_reqID (buffer_task[12].reqID), .io_in_12_bits_replSnp (buffer_task[12].replSnp),
    .io_in_12_bits_snpVec_0 (buffer_task[12].snpVec_0), .io_in_12_bits_tgtID (buffer_task[12].tgtID), .io_in_12_bits_srcID (buffer_task[12].srcID),
    .io_in_12_bits_txnID (buffer_task[12].txnID), .io_in_12_bits_dbID (buffer_task[12].dbID), .io_in_12_bits_fwdNID (buffer_task[12].fwdNID),
    .io_in_12_bits_fwdTxnID (buffer_task[12].fwdTxnID), .io_in_12_bits_chiOpcode (buffer_task[12].chiOpcode), .io_in_12_bits_resp (buffer_task[12].resp),
    .io_in_12_bits_fwdState (buffer_task[12].fwdState), .io_in_12_bits_pCrdType (buffer_task[12].pCrdType), .io_in_12_bits_retToSrc (buffer_task[12].retToSrc),
    .io_in_12_bits_doNotGoToSD (buffer_task[12].doNotGoToSD), .io_in_12_bits_expCompAck (buffer_task[12].expCompAck), .io_in_12_bits_allowRetry (buffer_task[12].allowRetry),
    .io_in_12_bits_order (buffer_task[12].order), .io_in_12_bits_memAttr_allocate (buffer_task[12].memAttr_allocate), .io_in_12_bits_memAttr_cacheable (buffer_task[12].memAttr_cacheable),
    .io_in_12_bits_memAttr_device (buffer_task[12].memAttr_device), .io_in_12_bits_memAttr_ewa (buffer_task[12].memAttr_ewa), .io_in_12_bits_snpAttr (buffer_task[12].snpAttr),
    .io_in_13_valid ((buffer_valid[13] & state_w_datRsp[13]) & ~state_s_issueReq[13]),
    .io_in_13_bits_set (buffer_task[13].set), .io_in_13_bits_bank (buffer_task[13].bank), .io_in_13_bits_tag (buffer_task[13].tag),
    .io_in_13_bits_off (buffer_task[13].off), .io_in_13_bits_size (buffer_task[13].size), .io_in_13_bits_refillTask (buffer_task[13].refillTask),
    .io_in_13_bits_bufID (buffer_task[13].bufID), .io_in_13_bits_reqID (buffer_task[13].reqID), .io_in_13_bits_replSnp (buffer_task[13].replSnp),
    .io_in_13_bits_snpVec_0 (buffer_task[13].snpVec_0), .io_in_13_bits_tgtID (buffer_task[13].tgtID), .io_in_13_bits_srcID (buffer_task[13].srcID),
    .io_in_13_bits_txnID (buffer_task[13].txnID), .io_in_13_bits_dbID (buffer_task[13].dbID), .io_in_13_bits_fwdNID (buffer_task[13].fwdNID),
    .io_in_13_bits_fwdTxnID (buffer_task[13].fwdTxnID), .io_in_13_bits_chiOpcode (buffer_task[13].chiOpcode), .io_in_13_bits_resp (buffer_task[13].resp),
    .io_in_13_bits_fwdState (buffer_task[13].fwdState), .io_in_13_bits_pCrdType (buffer_task[13].pCrdType), .io_in_13_bits_retToSrc (buffer_task[13].retToSrc),
    .io_in_13_bits_doNotGoToSD (buffer_task[13].doNotGoToSD), .io_in_13_bits_expCompAck (buffer_task[13].expCompAck), .io_in_13_bits_allowRetry (buffer_task[13].allowRetry),
    .io_in_13_bits_order (buffer_task[13].order), .io_in_13_bits_memAttr_allocate (buffer_task[13].memAttr_allocate), .io_in_13_bits_memAttr_cacheable (buffer_task[13].memAttr_cacheable),
    .io_in_13_bits_memAttr_device (buffer_task[13].memAttr_device), .io_in_13_bits_memAttr_ewa (buffer_task[13].memAttr_ewa), .io_in_13_bits_snpAttr (buffer_task[13].snpAttr),
    .io_in_14_valid ((buffer_valid[14] & state_w_datRsp[14]) & ~state_s_issueReq[14]),
    .io_in_14_bits_set (buffer_task[14].set), .io_in_14_bits_bank (buffer_task[14].bank), .io_in_14_bits_tag (buffer_task[14].tag),
    .io_in_14_bits_off (buffer_task[14].off), .io_in_14_bits_size (buffer_task[14].size), .io_in_14_bits_refillTask (buffer_task[14].refillTask),
    .io_in_14_bits_bufID (buffer_task[14].bufID), .io_in_14_bits_reqID (buffer_task[14].reqID), .io_in_14_bits_replSnp (buffer_task[14].replSnp),
    .io_in_14_bits_snpVec_0 (buffer_task[14].snpVec_0), .io_in_14_bits_tgtID (buffer_task[14].tgtID), .io_in_14_bits_srcID (buffer_task[14].srcID),
    .io_in_14_bits_txnID (buffer_task[14].txnID), .io_in_14_bits_dbID (buffer_task[14].dbID), .io_in_14_bits_fwdNID (buffer_task[14].fwdNID),
    .io_in_14_bits_fwdTxnID (buffer_task[14].fwdTxnID), .io_in_14_bits_chiOpcode (buffer_task[14].chiOpcode), .io_in_14_bits_resp (buffer_task[14].resp),
    .io_in_14_bits_fwdState (buffer_task[14].fwdState), .io_in_14_bits_pCrdType (buffer_task[14].pCrdType), .io_in_14_bits_retToSrc (buffer_task[14].retToSrc),
    .io_in_14_bits_doNotGoToSD (buffer_task[14].doNotGoToSD), .io_in_14_bits_expCompAck (buffer_task[14].expCompAck), .io_in_14_bits_allowRetry (buffer_task[14].allowRetry),
    .io_in_14_bits_order (buffer_task[14].order), .io_in_14_bits_memAttr_allocate (buffer_task[14].memAttr_allocate), .io_in_14_bits_memAttr_cacheable (buffer_task[14].memAttr_cacheable),
    .io_in_14_bits_memAttr_device (buffer_task[14].memAttr_device), .io_in_14_bits_memAttr_ewa (buffer_task[14].memAttr_ewa), .io_in_14_bits_snpAttr (buffer_task[14].snpAttr),
    .io_in_15_valid ((buffer_valid[15] & state_w_datRsp[15]) & ~state_s_issueReq[15]),
    .io_in_15_bits_set (buffer_task[15].set), .io_in_15_bits_bank (buffer_task[15].bank), .io_in_15_bits_tag (buffer_task[15].tag),
    .io_in_15_bits_off (buffer_task[15].off), .io_in_15_bits_size (buffer_task[15].size), .io_in_15_bits_refillTask (buffer_task[15].refillTask),
    .io_in_15_bits_bufID (buffer_task[15].bufID), .io_in_15_bits_reqID (buffer_task[15].reqID), .io_in_15_bits_replSnp (buffer_task[15].replSnp),
    .io_in_15_bits_snpVec_0 (buffer_task[15].snpVec_0), .io_in_15_bits_tgtID (buffer_task[15].tgtID), .io_in_15_bits_srcID (buffer_task[15].srcID),
    .io_in_15_bits_txnID (buffer_task[15].txnID), .io_in_15_bits_dbID (buffer_task[15].dbID), .io_in_15_bits_fwdNID (buffer_task[15].fwdNID),
    .io_in_15_bits_fwdTxnID (buffer_task[15].fwdTxnID), .io_in_15_bits_chiOpcode (buffer_task[15].chiOpcode), .io_in_15_bits_resp (buffer_task[15].resp),
    .io_in_15_bits_fwdState (buffer_task[15].fwdState), .io_in_15_bits_pCrdType (buffer_task[15].pCrdType), .io_in_15_bits_retToSrc (buffer_task[15].retToSrc),
    .io_in_15_bits_doNotGoToSD (buffer_task[15].doNotGoToSD), .io_in_15_bits_expCompAck (buffer_task[15].expCompAck), .io_in_15_bits_allowRetry (buffer_task[15].allowRetry),
    .io_in_15_bits_order (buffer_task[15].order), .io_in_15_bits_memAttr_allocate (buffer_task[15].memAttr_allocate), .io_in_15_bits_memAttr_cacheable (buffer_task[15].memAttr_cacheable),
    .io_in_15_bits_memAttr_device (buffer_task[15].memAttr_device), .io_in_15_bits_memAttr_ewa (buffer_task[15].memAttr_ewa), .io_in_15_bits_snpAttr (buffer_task[15].snpAttr),
    .io_out_ready (1'h1),
    .io_out_valid (txreqArb_out_valid),
    .io_out_bits_set (txreqArb_out_set),
    .io_out_bits_bank (txreqArb_out_bank),
    .io_out_bits_tag (txreqArb_out_tag),
    .io_out_bits_off (/* unused */),
    .io_out_bits_size (txreqArb_out_size),
    .io_out_bits_refillTask (/* unused */),
    .io_out_bits_bufID (/* unused */),
    .io_out_bits_reqID (txreqArb_out_reqID),
    .io_out_bits_replSnp (/* unused */),
    .io_out_bits_snpVec_0 (/* unused */),
    .io_out_bits_tgtID (txreqArb_out_tgtID),
    .io_out_bits_srcID (txreqArb_out_srcID),
    .io_out_bits_txnID (txreqArb_out_txnID),
    .io_out_bits_dbID (/* unused */),
    .io_out_bits_fwdNID (/* unused */),
    .io_out_bits_fwdTxnID (/* unused */),
    .io_out_bits_chiOpcode (txreqArb_out_chiOpcode),
    .io_out_bits_resp (/* unused */),
    .io_out_bits_fwdState (/* unused */),
    .io_out_bits_pCrdType (txreqArb_out_pCrdType),
    .io_out_bits_retToSrc (/* unused */),
    .io_out_bits_doNotGoToSD (/* unused */),
    .io_out_bits_expCompAck (txreqArb_out_expCompAck),
    .io_out_bits_allowRetry (txreqArb_out_allowRetry),
    .io_out_bits_order (txreqArb_out_order),
    .io_out_bits_memAttr_allocate (txreqArb_out_memAttr_allocate),
    .io_out_bits_memAttr_cacheable (txreqArb_out_memAttr_cacheable),
    .io_out_bits_memAttr_device (txreqArb_out_memAttr_device),
    .io_out_bits_memAttr_ewa (txreqArb_out_memAttr_ewa),
    .io_out_bits_snpAttr (txreqArb_out_snpAttr),
    .io_chosen (txreqArb_chosen)
  );

  // -------------------- txdatArb(FastArbiter_52): 挑就绪 WBF 条目发 TXDAT(携数据) --------------------
  FastArbiter_52 txdatArb (
    .clock (clock),
    .reset (reset),
    .io_in_0_valid ((buffer_valid[0] & state_w_datRsp[0]) & bufWBF[0] & state_s_issueReq[0] & state_w_dbid[0] & ~state_s_issueDat[0]),
    .io_in_0_bits_task_tgtID (buffer_task[0].tgtID), .io_in_0_bits_task_srcID (buffer_task[0].srcID), .io_in_0_bits_task_txnID (buffer_task[0].txnID),
    .io_in_0_bits_task_homeNID (buffer_task[0].homeNID), .io_in_0_bits_task_dbID (buffer_task[0].dbID), .io_in_0_bits_task_resp (buffer_task[0].resp),
    .io_in_0_bits_task_fwdState (buffer_task[0].fwdState), .io_in_0_bits_data_data_0_data (data0[0]), .io_in_0_bits_data_data_1_data (data1[0]),
    .io_in_1_valid ((buffer_valid[1] & state_w_datRsp[1]) & bufWBF[1] & state_s_issueReq[1] & state_w_dbid[1] & ~state_s_issueDat[1]),
    .io_in_1_bits_task_tgtID (buffer_task[1].tgtID), .io_in_1_bits_task_srcID (buffer_task[1].srcID), .io_in_1_bits_task_txnID (buffer_task[1].txnID),
    .io_in_1_bits_task_homeNID (buffer_task[1].homeNID), .io_in_1_bits_task_dbID (buffer_task[1].dbID), .io_in_1_bits_task_resp (buffer_task[1].resp),
    .io_in_1_bits_task_fwdState (buffer_task[1].fwdState), .io_in_1_bits_data_data_0_data (data0[1]), .io_in_1_bits_data_data_1_data (data1[1]),
    .io_in_2_valid ((buffer_valid[2] & state_w_datRsp[2]) & bufWBF[2] & state_s_issueReq[2] & state_w_dbid[2] & ~state_s_issueDat[2]),
    .io_in_2_bits_task_tgtID (buffer_task[2].tgtID), .io_in_2_bits_task_srcID (buffer_task[2].srcID), .io_in_2_bits_task_txnID (buffer_task[2].txnID),
    .io_in_2_bits_task_homeNID (buffer_task[2].homeNID), .io_in_2_bits_task_dbID (buffer_task[2].dbID), .io_in_2_bits_task_resp (buffer_task[2].resp),
    .io_in_2_bits_task_fwdState (buffer_task[2].fwdState), .io_in_2_bits_data_data_0_data (data0[2]), .io_in_2_bits_data_data_1_data (data1[2]),
    .io_in_3_valid ((buffer_valid[3] & state_w_datRsp[3]) & bufWBF[3] & state_s_issueReq[3] & state_w_dbid[3] & ~state_s_issueDat[3]),
    .io_in_3_bits_task_tgtID (buffer_task[3].tgtID), .io_in_3_bits_task_srcID (buffer_task[3].srcID), .io_in_3_bits_task_txnID (buffer_task[3].txnID),
    .io_in_3_bits_task_homeNID (buffer_task[3].homeNID), .io_in_3_bits_task_dbID (buffer_task[3].dbID), .io_in_3_bits_task_resp (buffer_task[3].resp),
    .io_in_3_bits_task_fwdState (buffer_task[3].fwdState), .io_in_3_bits_data_data_0_data (data0[3]), .io_in_3_bits_data_data_1_data (data1[3]),
    .io_in_4_valid ((buffer_valid[4] & state_w_datRsp[4]) & bufWBF[4] & state_s_issueReq[4] & state_w_dbid[4] & ~state_s_issueDat[4]),
    .io_in_4_bits_task_tgtID (buffer_task[4].tgtID), .io_in_4_bits_task_srcID (buffer_task[4].srcID), .io_in_4_bits_task_txnID (buffer_task[4].txnID),
    .io_in_4_bits_task_homeNID (buffer_task[4].homeNID), .io_in_4_bits_task_dbID (buffer_task[4].dbID), .io_in_4_bits_task_resp (buffer_task[4].resp),
    .io_in_4_bits_task_fwdState (buffer_task[4].fwdState), .io_in_4_bits_data_data_0_data (data0[4]), .io_in_4_bits_data_data_1_data (data1[4]),
    .io_in_5_valid ((buffer_valid[5] & state_w_datRsp[5]) & bufWBF[5] & state_s_issueReq[5] & state_w_dbid[5] & ~state_s_issueDat[5]),
    .io_in_5_bits_task_tgtID (buffer_task[5].tgtID), .io_in_5_bits_task_srcID (buffer_task[5].srcID), .io_in_5_bits_task_txnID (buffer_task[5].txnID),
    .io_in_5_bits_task_homeNID (buffer_task[5].homeNID), .io_in_5_bits_task_dbID (buffer_task[5].dbID), .io_in_5_bits_task_resp (buffer_task[5].resp),
    .io_in_5_bits_task_fwdState (buffer_task[5].fwdState), .io_in_5_bits_data_data_0_data (data0[5]), .io_in_5_bits_data_data_1_data (data1[5]),
    .io_in_6_valid ((buffer_valid[6] & state_w_datRsp[6]) & bufWBF[6] & state_s_issueReq[6] & state_w_dbid[6] & ~state_s_issueDat[6]),
    .io_in_6_bits_task_tgtID (buffer_task[6].tgtID), .io_in_6_bits_task_srcID (buffer_task[6].srcID), .io_in_6_bits_task_txnID (buffer_task[6].txnID),
    .io_in_6_bits_task_homeNID (buffer_task[6].homeNID), .io_in_6_bits_task_dbID (buffer_task[6].dbID), .io_in_6_bits_task_resp (buffer_task[6].resp),
    .io_in_6_bits_task_fwdState (buffer_task[6].fwdState), .io_in_6_bits_data_data_0_data (data0[6]), .io_in_6_bits_data_data_1_data (data1[6]),
    .io_in_7_valid ((buffer_valid[7] & state_w_datRsp[7]) & bufWBF[7] & state_s_issueReq[7] & state_w_dbid[7] & ~state_s_issueDat[7]),
    .io_in_7_bits_task_tgtID (buffer_task[7].tgtID), .io_in_7_bits_task_srcID (buffer_task[7].srcID), .io_in_7_bits_task_txnID (buffer_task[7].txnID),
    .io_in_7_bits_task_homeNID (buffer_task[7].homeNID), .io_in_7_bits_task_dbID (buffer_task[7].dbID), .io_in_7_bits_task_resp (buffer_task[7].resp),
    .io_in_7_bits_task_fwdState (buffer_task[7].fwdState), .io_in_7_bits_data_data_0_data (data0[7]), .io_in_7_bits_data_data_1_data (data1[7]),
    .io_in_8_valid ((buffer_valid[8] & state_w_datRsp[8]) & bufWBF[8] & state_s_issueReq[8] & state_w_dbid[8] & ~state_s_issueDat[8]),
    .io_in_8_bits_task_tgtID (buffer_task[8].tgtID), .io_in_8_bits_task_srcID (buffer_task[8].srcID), .io_in_8_bits_task_txnID (buffer_task[8].txnID),
    .io_in_8_bits_task_homeNID (buffer_task[8].homeNID), .io_in_8_bits_task_dbID (buffer_task[8].dbID), .io_in_8_bits_task_resp (buffer_task[8].resp),
    .io_in_8_bits_task_fwdState (buffer_task[8].fwdState), .io_in_8_bits_data_data_0_data (data0[8]), .io_in_8_bits_data_data_1_data (data1[8]),
    .io_in_9_valid ((buffer_valid[9] & state_w_datRsp[9]) & bufWBF[9] & state_s_issueReq[9] & state_w_dbid[9] & ~state_s_issueDat[9]),
    .io_in_9_bits_task_tgtID (buffer_task[9].tgtID), .io_in_9_bits_task_srcID (buffer_task[9].srcID), .io_in_9_bits_task_txnID (buffer_task[9].txnID),
    .io_in_9_bits_task_homeNID (buffer_task[9].homeNID), .io_in_9_bits_task_dbID (buffer_task[9].dbID), .io_in_9_bits_task_resp (buffer_task[9].resp),
    .io_in_9_bits_task_fwdState (buffer_task[9].fwdState), .io_in_9_bits_data_data_0_data (data0[9]), .io_in_9_bits_data_data_1_data (data1[9]),
    .io_in_10_valid ((buffer_valid[10] & state_w_datRsp[10]) & bufWBF[10] & state_s_issueReq[10] & state_w_dbid[10] & ~state_s_issueDat[10]),
    .io_in_10_bits_task_tgtID (buffer_task[10].tgtID), .io_in_10_bits_task_srcID (buffer_task[10].srcID), .io_in_10_bits_task_txnID (buffer_task[10].txnID),
    .io_in_10_bits_task_homeNID (buffer_task[10].homeNID), .io_in_10_bits_task_dbID (buffer_task[10].dbID), .io_in_10_bits_task_resp (buffer_task[10].resp),
    .io_in_10_bits_task_fwdState (buffer_task[10].fwdState), .io_in_10_bits_data_data_0_data (data0[10]), .io_in_10_bits_data_data_1_data (data1[10]),
    .io_in_11_valid ((buffer_valid[11] & state_w_datRsp[11]) & bufWBF[11] & state_s_issueReq[11] & state_w_dbid[11] & ~state_s_issueDat[11]),
    .io_in_11_bits_task_tgtID (buffer_task[11].tgtID), .io_in_11_bits_task_srcID (buffer_task[11].srcID), .io_in_11_bits_task_txnID (buffer_task[11].txnID),
    .io_in_11_bits_task_homeNID (buffer_task[11].homeNID), .io_in_11_bits_task_dbID (buffer_task[11].dbID), .io_in_11_bits_task_resp (buffer_task[11].resp),
    .io_in_11_bits_task_fwdState (buffer_task[11].fwdState), .io_in_11_bits_data_data_0_data (data0[11]), .io_in_11_bits_data_data_1_data (data1[11]),
    .io_in_12_valid ((buffer_valid[12] & state_w_datRsp[12]) & bufWBF[12] & state_s_issueReq[12] & state_w_dbid[12] & ~state_s_issueDat[12]),
    .io_in_12_bits_task_tgtID (buffer_task[12].tgtID), .io_in_12_bits_task_srcID (buffer_task[12].srcID), .io_in_12_bits_task_txnID (buffer_task[12].txnID),
    .io_in_12_bits_task_homeNID (buffer_task[12].homeNID), .io_in_12_bits_task_dbID (buffer_task[12].dbID), .io_in_12_bits_task_resp (buffer_task[12].resp),
    .io_in_12_bits_task_fwdState (buffer_task[12].fwdState), .io_in_12_bits_data_data_0_data (data0[12]), .io_in_12_bits_data_data_1_data (data1[12]),
    .io_in_13_valid ((buffer_valid[13] & state_w_datRsp[13]) & bufWBF[13] & state_s_issueReq[13] & state_w_dbid[13] & ~state_s_issueDat[13]),
    .io_in_13_bits_task_tgtID (buffer_task[13].tgtID), .io_in_13_bits_task_srcID (buffer_task[13].srcID), .io_in_13_bits_task_txnID (buffer_task[13].txnID),
    .io_in_13_bits_task_homeNID (buffer_task[13].homeNID), .io_in_13_bits_task_dbID (buffer_task[13].dbID), .io_in_13_bits_task_resp (buffer_task[13].resp),
    .io_in_13_bits_task_fwdState (buffer_task[13].fwdState), .io_in_13_bits_data_data_0_data (data0[13]), .io_in_13_bits_data_data_1_data (data1[13]),
    .io_in_14_valid ((buffer_valid[14] & state_w_datRsp[14]) & bufWBF[14] & state_s_issueReq[14] & state_w_dbid[14] & ~state_s_issueDat[14]),
    .io_in_14_bits_task_tgtID (buffer_task[14].tgtID), .io_in_14_bits_task_srcID (buffer_task[14].srcID), .io_in_14_bits_task_txnID (buffer_task[14].txnID),
    .io_in_14_bits_task_homeNID (buffer_task[14].homeNID), .io_in_14_bits_task_dbID (buffer_task[14].dbID), .io_in_14_bits_task_resp (buffer_task[14].resp),
    .io_in_14_bits_task_fwdState (buffer_task[14].fwdState), .io_in_14_bits_data_data_0_data (data0[14]), .io_in_14_bits_data_data_1_data (data1[14]),
    .io_in_15_valid ((buffer_valid[15] & state_w_datRsp[15]) & bufWBF[15] & state_s_issueReq[15] & state_w_dbid[15] & ~state_s_issueDat[15]),
    .io_in_15_bits_task_tgtID (buffer_task[15].tgtID), .io_in_15_bits_task_srcID (buffer_task[15].srcID), .io_in_15_bits_task_txnID (buffer_task[15].txnID),
    .io_in_15_bits_task_homeNID (buffer_task[15].homeNID), .io_in_15_bits_task_dbID (buffer_task[15].dbID), .io_in_15_bits_task_resp (buffer_task[15].resp),
    .io_in_15_bits_task_fwdState (buffer_task[15].fwdState), .io_in_15_bits_data_data_0_data (data0[15]), .io_in_15_bits_data_data_1_data (data1[15]),
    .io_out_ready (io_txdat_ready),
    .io_out_valid (txdatArb_out_valid),
    .io_out_bits_task_tgtID (io_txdat_bits_task_tgtID),
    .io_out_bits_task_srcID (io_txdat_bits_task_srcID),
    .io_out_bits_task_txnID (io_txdat_bits_task_txnID),
    .io_out_bits_task_homeNID (io_txdat_bits_task_homeNID),
    .io_out_bits_task_dbID (io_txdat_bits_task_dbID),
    .io_out_bits_task_resp (io_txdat_bits_task_resp),
    .io_out_bits_task_fwdState (io_txdat_bits_task_fwdState),
    .io_out_bits_data_data_0_data (io_txdat_bits_data_data_0_data),
    .io_out_bits_data_data_1_data (io_txdat_bits_data_data_1_data),
    .io_chosen (txdatArb_chosen)
  );

endmodule
