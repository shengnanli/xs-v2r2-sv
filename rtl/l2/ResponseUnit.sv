package xs_responseunit_pkg;
  localparam int unsigned N   = 16;
  localparam int unsigned IDX = 4;
  // buffer 条目 task 结构(与 golden buffer_N_task_* 字段/位宽逐位一致)
  typedef struct packed {
    logic snpAttr;
    logic memAttr_ewa;
    logic memAttr_device;
    logic memAttr_cacheable;
    logic memAttr_allocate;
    logic [1:0] order;
    logic allowRetry;
    logic expCompAck;
    logic doNotGoToSD;
    logic retToSrc;
    logic [3:0] pCrdType;
    logic [2:0] fwdState;
    logic [2:0] resp;
    logic [6:0] chiOpcode;
    logic [11:0] fwdTxnID;
    logic [10:0] fwdNID;
    logic [11:0] dbID;
    logic [10:0] homeNID;
    logic [11:0] txnID;
    logic [10:0] srcID;
    logic [10:0] tgtID;
    logic snpVec_0;
    logic replSnp;
    logic [11:0] reqID;
    logic [3:0] bufID;
    logic refillTask;
    logic [2:0] size;
    logic [5:0] off;
    logic [27:0] tag;
    logic [1:0] bank;
    logic [11:0] set;
  } ru_task_t;
endpackage

module xs_ResponseUnit_core
  import xs_responseunit_pkg::*;
(
  input  logic clock,
  input  logic reset,
  // fromMainPipe.alloc.s4
  input  logic        io_fromMainPipe_alloc_s4_valid,
  input  logic        io_fromMainPipe_alloc_s4_bits_state_w_datRsp,
  input  logic        io_fromMainPipe_alloc_s4_bits_state_w_snpRsp,
  input  logic        io_fromMainPipe_alloc_s4_bits_state_w_compack,
  input  logic        io_fromMainPipe_alloc_s4_bits_state_w_comp,
  input  ru_task_t     io_fromMainPipe_alloc_s4_bits_task,
  input  logic        io_fromMainPipe_alloc_s4_bits_is_miss,
  // fromMainPipe.alloc.s6
  input  logic        io_fromMainPipe_alloc_s6_valid,
  input  logic        io_fromMainPipe_alloc_s6_bits_state_w_snpRsp,
  input  ru_task_t     io_fromMainPipe_alloc_s6_bits_task,
  input  logic [255:0] io_fromMainPipe_alloc_s6_bits_data_data_0_data,
  input  logic [255:0] io_fromMainPipe_alloc_s6_bits_data_data_1_data,
  // snRxdat / snRxrsp
  input  logic        io_snRxdat_valid,
  input  logic [11:0] io_snRxdat_bits_txnID,
  input  logic [6:0]  io_snRxdat_bits_opcode,
  input  logic [1:0]  io_snRxdat_bits_dataID,
  input  logic [255:0] io_snRxdat_bits_data_data,
  input  logic        io_snRxrsp_valid,
  input  logic [11:0] io_snRxrsp_bits_txnID,
  input  logic [6:0]  io_snRxrsp_bits_opcode,
  // bypassData_0 / bypassData_1
  input  logic        io_bypassData_0_valid,
  input  logic [11:0] io_bypassData_0_bits_txnID,
  input  logic [6:0]  io_bypassData_0_bits_opcode,
  input  logic [255:0] io_bypassData_0_bits_data_data,
  input  logic        io_bypassData_1_valid,
  input  logic [11:0] io_bypassData_1_bits_txnID,
  input  logic [6:0]  io_bypassData_1_bits_opcode,
  input  logic [1:0]  io_bypassData_1_bits_dataID,
  input  logic [255:0] io_bypassData_1_bits_data_data,
  // rnRxdat / rnRxrsp
  input  logic        io_rnRxdat_valid,
  input  logic [11:0] io_rnRxdat_bits_txnID,
  input  logic [6:0]  io_rnRxdat_bits_opcode,
  input  logic [2:0]  io_rnRxdat_bits_resp,
  input  logic [10:0] io_rnRxdat_bits_srcID,
  input  logic [1:0]  io_rnRxdat_bits_dataID,
  input  logic [255:0] io_rnRxdat_bits_data_data,
  input  logic        io_rnRxrsp_valid,
  input  logic [11:0] io_rnRxrsp_bits_txnID,
  input  logic [6:0]  io_rnRxrsp_bits_opcode,
  input  logic [10:0] io_rnRxrsp_bits_srcID,
  // out ready
  input  logic        io_txrsp_ready,
  input  logic        io_txdat_ready,
  input  logic        io_urgentRead_ready,
  // txrsp
  output logic        io_txrsp_valid,
  output logic [10:0] io_txrsp_bits_tgtID,
  output logic [10:0] io_txrsp_bits_srcID,
  output logic [11:0] io_txrsp_bits_txnID,
  output logic [11:0] io_txrsp_bits_dbID,
  output logic [6:0]  io_txrsp_bits_chiOpcode,
  output logic [2:0]  io_txrsp_bits_resp,
  output logic [2:0]  io_txrsp_bits_fwdState,
  output logic [3:0]  io_txrsp_bits_pCrdType,
  // txdat
  output logic        io_txdat_valid,
  output logic [10:0] io_txdat_bits_task_tgtID,
  output logic [10:0] io_txdat_bits_task_srcID,
  output logic [11:0] io_txdat_bits_task_txnID,
  output logic [10:0] io_txdat_bits_task_homeNID,
  output logic [11:0] io_txdat_bits_task_dbID,
  output logic [2:0]  io_txdat_bits_task_resp,
  output logic [2:0]  io_txdat_bits_task_fwdState,
  output logic [255:0] io_txdat_bits_data_data_0_data,
  output logic [255:0] io_txdat_bits_data_data_1_data,
  // respInfo[16]
  output logic [N-1:0]        io_respInfo_valid,
  output logic [N-1:0][11:0]  io_respInfo_set,
  output logic [N-1:0][27:0]  io_respInfo_tag,
  output logic [N-1:0][6:0]   io_respInfo_opcode,
  output logic [N-1:0][11:0]  io_respInfo_reqID,
  output logic [N-1:0]        io_respInfo_w_snpRsp,
  output logic [N-1:0]        io_respInfo_w_compdata,
  output logic [N-1:0]        io_respInfo_w_compack,
  output logic [N-1:0]        io_respInfo_is_miss,
  // urgentRead
  output logic        io_urgentRead_valid,
  output logic [11:0] io_urgentRead_bits_set,
  output logic [1:0]  io_urgentRead_bits_bank,
  output logic [27:0] io_urgentRead_bits_tag,
  output logic [10:0] io_urgentRead_bits_tgtID,
  output logic [10:0] io_urgentRead_bits_srcID,
  output logic [11:0] io_urgentRead_bits_txnID,
  output logic [3:0]  io_urgentRead_bits_pCrdType
);

  // ============ buffer 状态寄存器(16 条目数组) ============
  ru_task_t             buffer_task   [N-1:0];
  logic                 buffer_valid  [N-1:0];
  logic                 buffer_s_comp[N-1:0];
  logic                 buffer_s_urgentRead[N-1:0];
  logic                 buffer_w_datRsp[N-1:0];
  logic                 buffer_w_snpRsp[N-1:0];
  logic                 buffer_w_compack[N-1:0];
  logic                 buffer_w_comp[N-1:0];
  logic [255:0]         buffer_data0  [N-1:0];
  logic [255:0]         buffer_data1  [N-1:0];
  logic                 buffer_beat0  [N-1:0];
  logic                 buffer_beat1  [N-1:0];
  logic                 buffer_is_miss[N-1:0];
  logic [15:0]          bufferTimer   [N-1:0]; // 泄漏计时器(死寄存器, 对称)
  logic                 REG_valid_d   [N-1:0]; // 上一拍 valid 快照(golden REG_N)

  // ---- 从数组打平的位向量(便于优先编码/或归约) ----
  logic [N-1:0] validVec;
  logic [N-1:0] beat0Vec;
  logic [N-1:0] beat1Vec;
  logic [N-1:0] isMissVec;
  logic [N-1:0] wDatRspVec;
  logic [N-1:0] wSnpRspVec;
  logic [N-1:0] snpVec0Vec;
  logic [N-1:0][6:0]  chiOpcodeVec;
  logic [N-1:0][2:0]  respVec;
  for (genvar i = 0; i < N; i++) begin : g_vecs
    assign validVec[i]     = buffer_valid[i];
    assign beat0Vec[i]     = buffer_beat0[i];
    assign beat1Vec[i]     = buffer_beat1[i];
    assign isMissVec[i]    = buffer_is_miss[i];
    assign wDatRspVec[i]   = buffer_w_datRsp[i];
    assign wSnpRspVec[i]   = buffer_w_snpRsp[i];
    assign snpVec0Vec[i]   = buffer_task[i].snpVec_0;
    assign chiOpcodeVec[i] = buffer_task[i].chiOpcode;
    assign respVec[i]      = buffer_task[i].resp;
  end

  // ============ 分配: s6 独立占位编码 + s4 空槽 ============
  // idOH_s6_enc: golden 的 s6 占位 one-hot(优先取首个空槽; 全满时占 [15] 的 ~valid)
  logic [N-1:0] idOH_s6_enc;
  always_comb begin
    idOH_s6_enc = 16'h1;
    for (int k = 0; k < N-1; k++) begin
      if (!buffer_valid[k]) begin idOH_s6_enc = (16'h1 << k); break; end
      if (k == N-2) idOH_s6_enc = {~buffer_valid[N-1], 15'h0};
    end
  end
  // freeVec_s4: s6 有效时排除 s6 占位槽, 否则全 ~valid
  logic [N-1:0] freeVec_s4;
  for (genvar i = 0; i < N; i++) begin : g_freevec
    assign freeVec_s4[i] = io_fromMainPipe_alloc_s6_valid
      ? (~buffer_valid[i] & ~idOH_s6_enc[i]) : ~buffer_valid[i];
  end
  logic [N-1:0] fullS6Vec; // golden _full_s6_T = ~valid(位序反转仅影响 |, 语义同)
  for (genvar i = 0; i < N; i++) begin : g_fulls6
    assign fullS6Vec[i] = ~buffer_valid[i];
  end

  // insertIdx_s4 = freeVec_s4 首个置位下标; insertIdx_s6 = idOH_s6_enc 首个置位下标
  logic [IDX-1:0] insertIdx_s4, insertIdx_s6;
  always_comb begin
    insertIdx_s4 = {IDX{1'b1}};
    for (int k = N-1; k >= 0; k--) if (freeVec_s4[k]) insertIdx_s4 = IDX'(k);
  end
  always_comb begin
    insertIdx_s6 = {IDX{1'b1}};
    for (int k = N-1; k >= 0; k--) if (idOH_s6_enc[k]) insertIdx_s6 = IDX'(k);
  end
  logic canAlloc_s6, canAlloc_s4;
  assign canAlloc_s6 = io_fromMainPipe_alloc_s6_valid & (|fullS6Vec);
  assign canAlloc_s4 = io_fromMainPipe_alloc_s4_valid & (|freeVec_s4);
  logic [N-1:0] allocS4OH, allocS6OH; // 每条目分配 one-hot
  for (genvar i = 0; i < N; i++) begin : g_allocoh
    assign allocS6OH[i] = canAlloc_s6 & (insertIdx_s6 == IDX'(i));
    assign allocS4OH[i] = canAlloc_s4 & (insertIdx_s4 == IDX'(i));
  end

  // ============ 8 个响应更新通道的 match 向量 + 优先命中下标 ============
  logic snRxdatOp, snRxrspOp5, snRxrspOp4, rnRxdatOp, rnRxrspOp, rnRxrspOp2;
  logic byp0Op, byp1Op;
  assign snRxdatOp  = io_snRxdat_bits_opcode == 7'h4;
  assign snRxrspOp5 = io_snRxrsp_bits_opcode == 7'h5;
  assign snRxrspOp4 = io_snRxrsp_bits_opcode == 7'h4;
  assign rnRxdatOp  = io_rnRxdat_bits_opcode == 7'h1;
  assign rnRxrspOp  = io_rnRxrsp_bits_opcode == 7'h1;
  assign rnRxrspOp2 = io_rnRxrsp_bits_opcode == 7'h2;
  assign byp0Op     = io_bypassData_0_bits_opcode == 7'h4;
  assign byp1Op     = io_bypassData_1_bits_opcode == 7'h4;

  logic [N-1:0] uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7;
  for (genvar i = 0; i < N; i++) begin : g_uv
    assign uv0[i] = (buffer_task[i].reqID == io_snRxdat_bits_txnID) & buffer_valid[i] & snRxdatOp;
    assign uv1[i] = (buffer_task[i].reqID == io_snRxrsp_bits_txnID) & buffer_valid[i] & (snRxrspOp5 | snRxrspOp4);
    assign uv2[i] = (buffer_task[i].reqID == io_rnRxdat_bits_txnID) & buffer_valid[i] & ~buffer_task[i].replSnp & rnRxdatOp;
    assign uv3[i] = (buffer_task[i].reqID == io_rnRxrsp_bits_txnID) & buffer_valid[i] & ~buffer_w_snpRsp[i] & rnRxrspOp;
    assign uv4[i] = (buffer_task[i].reqID == io_rnRxrsp_bits_txnID) & buffer_valid[i] & ~buffer_w_snpRsp[i];
    assign uv5[i] = (buffer_task[i].reqID == io_rnRxrsp_bits_txnID) & buffer_valid[i]
                  & buffer_w_datRsp[i] & buffer_s_comp[i] & ~buffer_w_compack[i] & rnRxrspOp2;
    assign uv6[i] = (buffer_task[i].reqID == io_bypassData_0_bits_txnID) & buffer_valid[i] & byp0Op;
    assign uv7[i] = (buffer_task[i].reqID == io_bypassData_1_bits_txnID) & buffer_valid[i] & byp1Op;
  end

  // update_id_k = uvk 首个命中下标(优先, 缺省末项 15 —— 与 golden 同)
  logic [IDX-1:0] uid0, uid1, uid2, uid3, uid4, uid5, uid6, uid7;
  always_comb begin uid0 = {IDX{1'b1}};
    for (int p = N-1; p >= 0; p--) if (uv0[p]) uid0 = IDX'(p); end
  always_comb begin uid1 = {IDX{1'b1}};
    for (int p = N-1; p >= 0; p--) if (uv1[p]) uid1 = IDX'(p); end
  always_comb begin uid2 = {IDX{1'b1}};
    for (int p = N-1; p >= 0; p--) if (uv2[p]) uid2 = IDX'(p); end
  always_comb begin uid3 = {IDX{1'b1}};
    for (int p = N-1; p >= 0; p--) if (uv3[p]) uid3 = IDX'(p); end
  always_comb begin uid4 = {IDX{1'b1}};
    for (int p = N-1; p >= 0; p--) if (uv4[p]) uid4 = IDX'(p); end
  always_comb begin uid5 = {IDX{1'b1}};
    for (int p = N-1; p >= 0; p--) if (uv5[p]) uid5 = IDX'(p); end
  always_comb begin uid6 = {IDX{1'b1}};
    for (int p = N-1; p >= 0; p--) if (uv6[p]) uid6 = IDX'(p); end
  always_comb begin uid7 = {IDX{1'b1}};
    for (int p = N-1; p >= 0; p--) if (uv7[p]) uid7 = IDX'(p); end

  // ---- rnRxdat 更新(ch2): 新 beatValids/snpVec/resp ----
  logic [1:0] newBeatValids;
  logic       newSnpVec_0, isReadUnique;
  assign newBeatValids = {beat1Vec[uid2], beat0Vec[uid2]} | (2'h1 << io_rnRxdat_bits_dataID[1]);
  assign newSnpVec_0   = snpVec0Vec[uid2] & (|io_rnRxdat_bits_srcID);
  assign isReadUnique  = chiOpcodeVec[uid2] == 7'h7;
  logic [2:0] newResp; // _buffer_task_resp_T_1 = resp | 4
  assign newResp = respVec[uid2] | 3'h4;
  logic isReadOnce; // _GEN_213 = chiOpcode==9 | chiOpcode==8
  assign isReadOnce = (chiOpcodeVec[uid2] == 7'h9) | (chiOpcodeVec[uid2] == 7'h8);
  logic rnRxdatRespHi; // _GEN_214
  assign rnRxdatRespHi = io_rnRxdat_valid & (|uv2) & io_rnRxdat_bits_resp[2];
  // ch0 snRxdat: 双 beat 到齐则 w_datRsp(_buffer_state_w_datRsp_T_2)
  logic snRxdatBothBeats;
  assign snRxdatBothBeats = (2'({1'h0, beat0Vec[uid0]} + {1'h0, beat1Vec[uid0]}) == 2'h1);
  // ch3/ch4 rnRxrsp snpRsp 合并(newSnpVec_1_0 / newSnpVec_2_0)
  logic newSnpVec_1_0, newSnpVec_2_0;
  assign newSnpVec_1_0 = snpVec0Vec[uid3] & (|io_rnRxrsp_bits_srcID);
  assign newSnpVec_2_0 = snpVec0Vec[uid4] & (|io_rnRxdat_bits_srcID) & (|io_rnRxrsp_bits_srcID);
  logic sUrgSetByRnRxrsp; // _buffer_state_s_urgentRead_T_4
  assign sUrgSetByRnRxrsp = newSnpVec_1_0 | (|{beat1Vec[uid3], beat0Vec[uid3]}) | wDatRspVec[uid3];
  // ch3/ch4 同拍 rnRxdat&rnRxrsp 同 txnID 且都 opcode==1 的合并条件
  logic bothRxValid, bothRxOp1, bothRxSameTxn;
  assign bothRxValid    = io_rnRxdat_valid & io_rnRxrsp_valid;
  assign bothRxOp1      = (io_rnRxdat_bits_opcode == 7'h1) & (io_rnRxrsp_bits_opcode == 7'h1);
  assign bothRxSameTxn  = io_rnRxdat_bits_txnID == io_rnRxrsp_bits_txnID;
  logic mergeSnp; // 触发 ch4(newSnpVec_2_0)分支
  assign mergeSnp = bothRxValid & bothRxOp1 & bothRxSameTxn & (|uv4);

  // ============ 出队仲裁(txrsp: 非读完成; txdat: 读完成) ============
  logic        txrspArb_out_valid;
  logic [6:0]  txrspArb_out_chiOpcode;
  logic [IDX-1:0] txrspArb_chosen;
  logic        txdatArb_out_valid;
  logic [IDX-1:0] txdatArb_chosen;
  logic [N-1:0] isRead;
  for (genvar i = 0; i < N; i++) begin : g_isread
    assign isRead[i] = (buffer_task[i].chiOpcode == 7'h7) | (buffer_task[i].chiOpcode == 7'h26);
  end
  logic txrspFire, txdatFire; // io_*_ready & arb_out_valid
  assign txrspFire = io_txrsp_ready & txrspArb_out_valid;
  assign txdatFire = io_txdat_ready & txdatArb_out_valid;
  logic [N-1:0] txrspDeqOH, txdatDeqOH;
  for (genvar i = 0; i < N; i++) begin : g_deqoh
    assign txrspDeqOH[i] = txrspFire & (txrspArb_chosen == IDX'(i));
    assign txdatDeqOH[i] = txdatFire & (txdatArb_chosen == IDX'(i));
  end

  // ============ will_free(条目全部完成可释放) + urgent(待发 urgentRead) ============
  logic [N-1:0] will_free;
  for (genvar i = 0; i < N; i++) begin : g_willfree
    assign will_free[i] = buffer_valid[i] & buffer_w_datRsp[i] & buffer_s_comp[i]
      & buffer_w_compack[i] & buffer_w_snpRsp[i] & buffer_w_comp[i] & buffer_s_urgentRead[i];
  end
  logic [N-1:0] urgent_vec;
  for (genvar i = 0; i < N; i++) begin : g_urgentvec
    assign urgent_vec[i] = buffer_valid[i] & ~buffer_s_urgentRead[i];
  end
  logic [IDX-1:0] urgentIdx;
  always_comb begin urgentIdx = {IDX{1'b1}};
    for (int p = N-1; p >= 0; p--) if (urgent_vec[p]) urgentIdx = IDX'(p); end
  logic urgentFire; // _GEN_297
  assign urgentFire = io_urgentRead_ready & (|urgent_vec);

  // ============ 每条目状态更新(generate-for + 同步 reset) ============
  for (genvar i = 0; i < N; i++) begin : g_entry
    // 该条目参与各更新通道的命中(优先命中 & 是本条目)
    logic hitS4, hitS6;        // 本拍是否分配到本条目
    logic snRxdatHit0, snRxdatHit1; // ch0(按 dataID[1])
    logic rnRxdatHit;          // ch2
    logic byp0Hit;             // ch6
    logic byp1Hit;             // ch7
    assign hitS4       = allocS4OH[i];
    assign hitS6       = allocS6OH[i];
    assign snRxdatHit0 = io_snRxdat_valid & (|uv0) & (uid0 == IDX'(i)) & ~io_snRxdat_bits_dataID[1];
    assign snRxdatHit1 = io_snRxdat_valid & (|uv0) & (uid0 == IDX'(i)) &  io_snRxdat_bits_dataID[1];
    assign rnRxdatHit  = io_rnRxdat_valid & (|uv2) & (uid2 == IDX'(i));
    assign byp0Hit     = io_bypassData_0_valid & (|uv6) & (uid6 == IDX'(i));
    assign byp1Hit     = io_bypassData_1_valid & (|uv7) & (uid7 == IDX'(i));
    // s_comp: 出队(txrsp/txdat 命中本条目)置位, 否则保持(除本拍分配清 0)
    logic sCompHold;
    assign sCompHold = ~(hitS4 | hitS6) & buffer_s_comp[i];
    // beatValids0 下一态(_GEN_151 家族)
    logic nextBeat0;
    assign nextBeat0 = rnRxdatHit ? newBeatValids[0]
      : (snRxdatHit0 | (~hitS4 & (hitS6 | buffer_beat0[i])));
    // w_datRsp 下一态(_GEN_196 家族)
    logic nextWDatRsp;
    assign nextWDatRsp = rnRxdatHit ? (&newBeatValids)
      : ((io_snRxdat_valid & (|uv0) & (uid0 == IDX'(i))) ? snRxdatBothBeats
        : (hitS4 ? io_fromMainPipe_alloc_s4_bits_state_w_datRsp : (hitS6 | buffer_w_datRsp[i])));

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        buffer_valid[i]   <= 1'b0;
        buffer_task[i]    <= '0;
        buffer_s_comp[i]      <= 1'b0;
        buffer_s_urgentRead[i]<= 1'b0;
        buffer_w_datRsp[i]    <= 1'b0;
        buffer_w_snpRsp[i]    <= 1'b0;
        buffer_w_compack[i]   <= 1'b0;
        buffer_w_comp[i]      <= 1'b0;
        buffer_data0[i]   <= 256'h0;
        buffer_data1[i]   <= 256'h0;
        buffer_beat0[i]   <= 1'b0;
        buffer_beat1[i]   <= 1'b0;
        buffer_is_miss[i] <= 1'b0;
        bufferTimer[i]    <= 16'h0;
        REG_valid_d[i]    <= 1'b0;
      end else begin
        // ---- valid: will_free 清 0; 否则分配置位或保持 ----
        buffer_valid[i] <= ~will_free[i]
          & (canAlloc_s4 ? (hitS4 | hitS6 | buffer_valid[i]) : (hitS6 | buffer_valid[i]));
        // ---- task payload: s4 优先, 否则 s6(除 snpVec_0/resp 单独选择) ----
        if (hitS4) begin
          buffer_task[i].set               <= io_fromMainPipe_alloc_s4_bits_task.set;
          buffer_task[i].bank              <= io_fromMainPipe_alloc_s4_bits_task.bank;
          buffer_task[i].tag               <= io_fromMainPipe_alloc_s4_bits_task.tag;
          buffer_task[i].off               <= io_fromMainPipe_alloc_s4_bits_task.off;
          buffer_task[i].size              <= io_fromMainPipe_alloc_s4_bits_task.size;
          buffer_task[i].refillTask        <= io_fromMainPipe_alloc_s4_bits_task.refillTask;
          buffer_task[i].bufID             <= io_fromMainPipe_alloc_s4_bits_task.bufID;
          buffer_task[i].reqID             <= io_fromMainPipe_alloc_s4_bits_task.reqID;
          buffer_task[i].replSnp           <= io_fromMainPipe_alloc_s4_bits_task.replSnp;
          buffer_task[i].tgtID             <= io_fromMainPipe_alloc_s4_bits_task.tgtID;
          buffer_task[i].srcID             <= io_fromMainPipe_alloc_s4_bits_task.srcID;
          buffer_task[i].txnID             <= io_fromMainPipe_alloc_s4_bits_task.txnID;
          buffer_task[i].homeNID           <= io_fromMainPipe_alloc_s4_bits_task.homeNID;
          buffer_task[i].dbID              <= io_fromMainPipe_alloc_s4_bits_task.dbID;
          buffer_task[i].fwdNID            <= io_fromMainPipe_alloc_s4_bits_task.fwdNID;
          buffer_task[i].fwdTxnID          <= io_fromMainPipe_alloc_s4_bits_task.fwdTxnID;
          buffer_task[i].chiOpcode         <= io_fromMainPipe_alloc_s4_bits_task.chiOpcode;
          buffer_task[i].fwdState          <= io_fromMainPipe_alloc_s4_bits_task.fwdState;
          buffer_task[i].pCrdType          <= io_fromMainPipe_alloc_s4_bits_task.pCrdType;
          buffer_task[i].retToSrc          <= io_fromMainPipe_alloc_s4_bits_task.retToSrc;
          buffer_task[i].doNotGoToSD       <= io_fromMainPipe_alloc_s4_bits_task.doNotGoToSD;
          buffer_task[i].expCompAck        <= io_fromMainPipe_alloc_s4_bits_task.expCompAck;
          buffer_task[i].allowRetry        <= io_fromMainPipe_alloc_s4_bits_task.allowRetry;
          buffer_task[i].order             <= io_fromMainPipe_alloc_s4_bits_task.order;
          buffer_task[i].memAttr_allocate  <= io_fromMainPipe_alloc_s4_bits_task.memAttr_allocate;
          buffer_task[i].memAttr_cacheable <= io_fromMainPipe_alloc_s4_bits_task.memAttr_cacheable;
          buffer_task[i].memAttr_device    <= io_fromMainPipe_alloc_s4_bits_task.memAttr_device;
          buffer_task[i].memAttr_ewa       <= io_fromMainPipe_alloc_s4_bits_task.memAttr_ewa;
          buffer_task[i].snpAttr           <= io_fromMainPipe_alloc_s4_bits_task.snpAttr;
          buffer_is_miss[i] <= io_fromMainPipe_alloc_s4_bits_is_miss;
        end else begin
          if (hitS6) begin
            buffer_task[i].set               <= io_fromMainPipe_alloc_s6_bits_task.set;
            buffer_task[i].bank              <= io_fromMainPipe_alloc_s6_bits_task.bank;
            buffer_task[i].tag               <= io_fromMainPipe_alloc_s6_bits_task.tag;
            buffer_task[i].off               <= io_fromMainPipe_alloc_s6_bits_task.off;
            buffer_task[i].size              <= io_fromMainPipe_alloc_s6_bits_task.size;
            buffer_task[i].refillTask        <= io_fromMainPipe_alloc_s6_bits_task.refillTask;
            buffer_task[i].bufID             <= io_fromMainPipe_alloc_s6_bits_task.bufID;
            buffer_task[i].reqID             <= io_fromMainPipe_alloc_s6_bits_task.reqID;
            buffer_task[i].replSnp           <= io_fromMainPipe_alloc_s6_bits_task.replSnp;
            buffer_task[i].tgtID             <= io_fromMainPipe_alloc_s6_bits_task.tgtID;
            buffer_task[i].srcID             <= io_fromMainPipe_alloc_s6_bits_task.srcID;
            buffer_task[i].txnID             <= io_fromMainPipe_alloc_s6_bits_task.txnID;
            buffer_task[i].homeNID           <= io_fromMainPipe_alloc_s6_bits_task.homeNID;
            buffer_task[i].dbID              <= io_fromMainPipe_alloc_s6_bits_task.dbID;
            buffer_task[i].fwdNID            <= io_fromMainPipe_alloc_s6_bits_task.fwdNID;
            buffer_task[i].fwdTxnID          <= io_fromMainPipe_alloc_s6_bits_task.fwdTxnID;
            buffer_task[i].chiOpcode         <= io_fromMainPipe_alloc_s6_bits_task.chiOpcode;
            buffer_task[i].fwdState          <= io_fromMainPipe_alloc_s6_bits_task.fwdState;
            buffer_task[i].pCrdType          <= io_fromMainPipe_alloc_s6_bits_task.pCrdType;
            buffer_task[i].retToSrc          <= io_fromMainPipe_alloc_s6_bits_task.retToSrc;
            buffer_task[i].doNotGoToSD       <= io_fromMainPipe_alloc_s6_bits_task.doNotGoToSD;
            buffer_task[i].expCompAck        <= io_fromMainPipe_alloc_s6_bits_task.expCompAck;
            buffer_task[i].allowRetry        <= io_fromMainPipe_alloc_s6_bits_task.allowRetry;
            buffer_task[i].order             <= io_fromMainPipe_alloc_s6_bits_task.order;
            buffer_task[i].memAttr_allocate  <= io_fromMainPipe_alloc_s6_bits_task.memAttr_allocate;
            buffer_task[i].memAttr_cacheable <= io_fromMainPipe_alloc_s6_bits_task.memAttr_cacheable;
            buffer_task[i].memAttr_device    <= io_fromMainPipe_alloc_s6_bits_task.memAttr_device;
            buffer_task[i].memAttr_ewa       <= io_fromMainPipe_alloc_s6_bits_task.memAttr_ewa;
            buffer_task[i].snpAttr           <= io_fromMainPipe_alloc_s6_bits_task.snpAttr;
          end
          buffer_is_miss[i] <= ~hitS6 & buffer_is_miss[i];
        end
        // ---- snpVec_0 & w_snpRsp: 合并 snoop 响应优先级链 ----
        if (mergeSnp & (uid4 == IDX'(i))) begin
          buffer_task[i].snpVec_0 <= newSnpVec_2_0;
          buffer_w_snpRsp[i]      <= ~newSnpVec_2_0;
        end else if (io_rnRxrsp_valid & (|uv3) & (uid3 == IDX'(i))) begin
          buffer_task[i].snpVec_0 <= newSnpVec_1_0;
          buffer_w_snpRsp[i]      <= ~newSnpVec_1_0;
        end else if (rnRxdatHit) begin
          buffer_task[i].snpVec_0 <= newSnpVec_0;
          buffer_w_snpRsp[i]      <= ~newSnpVec_0;
        end else if (hitS4) begin
          buffer_task[i].snpVec_0 <= io_fromMainPipe_alloc_s4_bits_task.snpVec_0;
          buffer_w_snpRsp[i]      <= io_fromMainPipe_alloc_s4_bits_state_w_snpRsp;
        end else if (hitS6) begin
          buffer_task[i].snpVec_0 <= io_fromMainPipe_alloc_s6_bits_task.snpVec_0;
          buffer_w_snpRsp[i]      <= io_fromMainPipe_alloc_s6_bits_state_w_snpRsp;
        end
        // ---- task.resp: rnRxdat readUnique 升级 | s4 | s6 ----
        if (rnRxdatRespHi & isReadUnique & (uid2 == IDX'(i)))
          buffer_task[i].resp <= newResp;
        else if (hitS4) buffer_task[i].resp <= io_fromMainPipe_alloc_s4_bits_task.resp;
        else if (hitS6) buffer_task[i].resp <= io_fromMainPipe_alloc_s6_bits_task.resp;
        // ---- s_comp: 出队(txrsp/txdat 命中)置位, 否则保持 ----
        buffer_s_comp[i] <= txrspFire ? (txrspDeqOH[i] | txdatDeqOH[i] | sCompHold)
                                      : (txdatDeqOH[i] | sCompHold);
        // ---- s_urgentRead: urgentRead 发出置位 | ch3 合并 | 分配/保持 ----
        buffer_s_urgentRead[i] <= (urgentFire & (urgentIdx == IDX'(i)))
          | ((io_rnRxrsp_valid & (|uv3) & (uid3 == IDX'(i))) ? sUrgSetByRnRxrsp
             : ((hitS4 | hitS6) | buffer_s_urgentRead[i]));
        // ---- w_datRsp: will_free 清 0; 否则 bypass1/bypass0/其它通道 ----
        buffer_w_datRsp[i] <= ~will_free[i]
          & ((io_bypassData_1_valid & (|uv7)) ? ((uid7 == IDX'(i)) | byp0Hit | nextWDatRsp)
             : (byp0Hit | nextWDatRsp));
        // ---- w_compack: ch5(rnRxrsp op2) 置位 | s4 | 保持 ----
        buffer_w_compack[i] <= (io_rnRxrsp_valid & (|uv5) & (uid5 == IDX'(i)))
          | (hitS4 ? io_fromMainPipe_alloc_s4_bits_state_w_compack
                   : (~hitS6 & buffer_w_compack[i]));
        // ---- w_comp: ch1(snRxrsp) 置位 & readUnique/非readOnce 门控 | s4 | s6/保持 ----
        buffer_w_comp[i] <= (~rnRxdatRespHi | isReadUnique | ~(isReadOnce & (uid2 == IDX'(i))))
          & ((io_snRxrsp_valid & (|uv1) & (uid1 == IDX'(i)))
             | (hitS4 ? io_fromMainPipe_alloc_s4_bits_state_w_comp
                      : (hitS6 | buffer_w_comp[i])));
        // ---- data beat0: bypass1/bypass0/rnRxdat/snRxdat/s6 优先链 ----
        if (byp1Hit & ~io_bypassData_1_bits_dataID[1])
          buffer_data0[i] <= io_bypassData_1_bits_data_data;
        else if (byp0Hit) buffer_data0[i] <= io_bypassData_0_bits_data_data;
        else if (rnRxdatHit & ~io_rnRxdat_bits_dataID[1]) buffer_data0[i] <= io_rnRxdat_bits_data_data;
        else if (snRxdatHit0) buffer_data0[i] <= io_snRxdat_bits_data_data;
        else if (hitS6) buffer_data0[i] <= io_fromMainPipe_alloc_s6_bits_data_data_0_data;
        // ---- data beat1 ----
        if (byp1Hit & io_bypassData_1_bits_dataID[1])
          buffer_data1[i] <= io_bypassData_1_bits_data_data;
        else if (rnRxdatHit & io_rnRxdat_bits_dataID[1]) buffer_data1[i] <= io_rnRxdat_bits_data_data;
        else if (snRxdatHit1) buffer_data1[i] <= io_snRxdat_bits_data_data;
        else if (hitS6) buffer_data1[i] <= io_fromMainPipe_alloc_s6_bits_data_data_1_data;
        // ---- beatValids ----
        if (byp1Hit) buffer_beat0[i] <= ~io_bypassData_1_bits_dataID[1] | byp0Hit | nextBeat0;
        else buffer_beat0[i] <= byp0Hit | nextBeat0;
        buffer_beat1[i] <= (byp1Hit & io_bypassData_1_bits_dataID[1])
          | (rnRxdatHit ? newBeatValids[1]
             : (snRxdatHit1 | (~hitS4 & (hitS6 | buffer_beat1[i]))));
        // ---- bufferTimer(死): valid→invalid 清 0, 否则 valid 自增 ----
        if (REG_valid_d[i] & ~buffer_valid[i]) bufferTimer[i] <= 16'h0;
        else if (buffer_valid[i]) bufferTimer[i] <= 16'(bufferTimer[i] + 16'h1);
        REG_valid_d[i] <= buffer_valid[i];
      end
    end
  end

  // ============ FastArbiter_50 (txrsp) / FastArbiter_52 (txdat) 两侧 elaborate ============
  FastArbiter_50 txrspArb (
    .clock (clock), .reset (reset),
    .io_in_0_valid (buffer_valid[0] & buffer_w_datRsp[0] & buffer_w_snpRsp[0] & buffer_w_comp[0] & buffer_s_urgentRead[0] & ~buffer_s_comp[0] & ~isRead[0]),
    .io_in_0_bits_set (buffer_task[0].set),
    .io_in_0_bits_bank (buffer_task[0].bank),
    .io_in_0_bits_tag (buffer_task[0].tag),
    .io_in_0_bits_off (buffer_task[0].off),
    .io_in_0_bits_size (buffer_task[0].size),
    .io_in_0_bits_refillTask (buffer_task[0].refillTask),
    .io_in_0_bits_bufID (buffer_task[0].bufID),
    .io_in_0_bits_reqID (buffer_task[0].reqID),
    .io_in_0_bits_replSnp (buffer_task[0].replSnp),
    .io_in_0_bits_snpVec_0 (buffer_task[0].snpVec_0),
    .io_in_0_bits_tgtID (buffer_task[0].tgtID),
    .io_in_0_bits_srcID (buffer_task[0].srcID),
    .io_in_0_bits_txnID (buffer_task[0].txnID),
    .io_in_0_bits_dbID (buffer_task[0].dbID),
    .io_in_0_bits_fwdNID (buffer_task[0].fwdNID),
    .io_in_0_bits_fwdTxnID (buffer_task[0].fwdTxnID),
    .io_in_0_bits_chiOpcode (buffer_task[0].chiOpcode),
    .io_in_0_bits_resp (buffer_task[0].resp),
    .io_in_0_bits_fwdState (buffer_task[0].fwdState),
    .io_in_0_bits_pCrdType (buffer_task[0].pCrdType),
    .io_in_0_bits_retToSrc (buffer_task[0].retToSrc),
    .io_in_0_bits_doNotGoToSD (buffer_task[0].doNotGoToSD),
    .io_in_0_bits_expCompAck (buffer_task[0].expCompAck),
    .io_in_0_bits_allowRetry (buffer_task[0].allowRetry),
    .io_in_0_bits_order (buffer_task[0].order),
    .io_in_0_bits_memAttr_allocate (buffer_task[0].memAttr_allocate),
    .io_in_0_bits_memAttr_cacheable (buffer_task[0].memAttr_cacheable),
    .io_in_0_bits_memAttr_device (buffer_task[0].memAttr_device),
    .io_in_0_bits_memAttr_ewa (buffer_task[0].memAttr_ewa),
    .io_in_0_bits_snpAttr (buffer_task[0].snpAttr),
    .io_in_1_valid (buffer_valid[1] & buffer_w_datRsp[1] & buffer_w_snpRsp[1] & buffer_w_comp[1] & buffer_s_urgentRead[1] & ~buffer_s_comp[1] & ~isRead[1]),
    .io_in_1_bits_set (buffer_task[1].set),
    .io_in_1_bits_bank (buffer_task[1].bank),
    .io_in_1_bits_tag (buffer_task[1].tag),
    .io_in_1_bits_off (buffer_task[1].off),
    .io_in_1_bits_size (buffer_task[1].size),
    .io_in_1_bits_refillTask (buffer_task[1].refillTask),
    .io_in_1_bits_bufID (buffer_task[1].bufID),
    .io_in_1_bits_reqID (buffer_task[1].reqID),
    .io_in_1_bits_replSnp (buffer_task[1].replSnp),
    .io_in_1_bits_snpVec_0 (buffer_task[1].snpVec_0),
    .io_in_1_bits_tgtID (buffer_task[1].tgtID),
    .io_in_1_bits_srcID (buffer_task[1].srcID),
    .io_in_1_bits_txnID (buffer_task[1].txnID),
    .io_in_1_bits_dbID (buffer_task[1].dbID),
    .io_in_1_bits_fwdNID (buffer_task[1].fwdNID),
    .io_in_1_bits_fwdTxnID (buffer_task[1].fwdTxnID),
    .io_in_1_bits_chiOpcode (buffer_task[1].chiOpcode),
    .io_in_1_bits_resp (buffer_task[1].resp),
    .io_in_1_bits_fwdState (buffer_task[1].fwdState),
    .io_in_1_bits_pCrdType (buffer_task[1].pCrdType),
    .io_in_1_bits_retToSrc (buffer_task[1].retToSrc),
    .io_in_1_bits_doNotGoToSD (buffer_task[1].doNotGoToSD),
    .io_in_1_bits_expCompAck (buffer_task[1].expCompAck),
    .io_in_1_bits_allowRetry (buffer_task[1].allowRetry),
    .io_in_1_bits_order (buffer_task[1].order),
    .io_in_1_bits_memAttr_allocate (buffer_task[1].memAttr_allocate),
    .io_in_1_bits_memAttr_cacheable (buffer_task[1].memAttr_cacheable),
    .io_in_1_bits_memAttr_device (buffer_task[1].memAttr_device),
    .io_in_1_bits_memAttr_ewa (buffer_task[1].memAttr_ewa),
    .io_in_1_bits_snpAttr (buffer_task[1].snpAttr),
    .io_in_2_valid (buffer_valid[2] & buffer_w_datRsp[2] & buffer_w_snpRsp[2] & buffer_w_comp[2] & buffer_s_urgentRead[2] & ~buffer_s_comp[2] & ~isRead[2]),
    .io_in_2_bits_set (buffer_task[2].set),
    .io_in_2_bits_bank (buffer_task[2].bank),
    .io_in_2_bits_tag (buffer_task[2].tag),
    .io_in_2_bits_off (buffer_task[2].off),
    .io_in_2_bits_size (buffer_task[2].size),
    .io_in_2_bits_refillTask (buffer_task[2].refillTask),
    .io_in_2_bits_bufID (buffer_task[2].bufID),
    .io_in_2_bits_reqID (buffer_task[2].reqID),
    .io_in_2_bits_replSnp (buffer_task[2].replSnp),
    .io_in_2_bits_snpVec_0 (buffer_task[2].snpVec_0),
    .io_in_2_bits_tgtID (buffer_task[2].tgtID),
    .io_in_2_bits_srcID (buffer_task[2].srcID),
    .io_in_2_bits_txnID (buffer_task[2].txnID),
    .io_in_2_bits_dbID (buffer_task[2].dbID),
    .io_in_2_bits_fwdNID (buffer_task[2].fwdNID),
    .io_in_2_bits_fwdTxnID (buffer_task[2].fwdTxnID),
    .io_in_2_bits_chiOpcode (buffer_task[2].chiOpcode),
    .io_in_2_bits_resp (buffer_task[2].resp),
    .io_in_2_bits_fwdState (buffer_task[2].fwdState),
    .io_in_2_bits_pCrdType (buffer_task[2].pCrdType),
    .io_in_2_bits_retToSrc (buffer_task[2].retToSrc),
    .io_in_2_bits_doNotGoToSD (buffer_task[2].doNotGoToSD),
    .io_in_2_bits_expCompAck (buffer_task[2].expCompAck),
    .io_in_2_bits_allowRetry (buffer_task[2].allowRetry),
    .io_in_2_bits_order (buffer_task[2].order),
    .io_in_2_bits_memAttr_allocate (buffer_task[2].memAttr_allocate),
    .io_in_2_bits_memAttr_cacheable (buffer_task[2].memAttr_cacheable),
    .io_in_2_bits_memAttr_device (buffer_task[2].memAttr_device),
    .io_in_2_bits_memAttr_ewa (buffer_task[2].memAttr_ewa),
    .io_in_2_bits_snpAttr (buffer_task[2].snpAttr),
    .io_in_3_valid (buffer_valid[3] & buffer_w_datRsp[3] & buffer_w_snpRsp[3] & buffer_w_comp[3] & buffer_s_urgentRead[3] & ~buffer_s_comp[3] & ~isRead[3]),
    .io_in_3_bits_set (buffer_task[3].set),
    .io_in_3_bits_bank (buffer_task[3].bank),
    .io_in_3_bits_tag (buffer_task[3].tag),
    .io_in_3_bits_off (buffer_task[3].off),
    .io_in_3_bits_size (buffer_task[3].size),
    .io_in_3_bits_refillTask (buffer_task[3].refillTask),
    .io_in_3_bits_bufID (buffer_task[3].bufID),
    .io_in_3_bits_reqID (buffer_task[3].reqID),
    .io_in_3_bits_replSnp (buffer_task[3].replSnp),
    .io_in_3_bits_snpVec_0 (buffer_task[3].snpVec_0),
    .io_in_3_bits_tgtID (buffer_task[3].tgtID),
    .io_in_3_bits_srcID (buffer_task[3].srcID),
    .io_in_3_bits_txnID (buffer_task[3].txnID),
    .io_in_3_bits_dbID (buffer_task[3].dbID),
    .io_in_3_bits_fwdNID (buffer_task[3].fwdNID),
    .io_in_3_bits_fwdTxnID (buffer_task[3].fwdTxnID),
    .io_in_3_bits_chiOpcode (buffer_task[3].chiOpcode),
    .io_in_3_bits_resp (buffer_task[3].resp),
    .io_in_3_bits_fwdState (buffer_task[3].fwdState),
    .io_in_3_bits_pCrdType (buffer_task[3].pCrdType),
    .io_in_3_bits_retToSrc (buffer_task[3].retToSrc),
    .io_in_3_bits_doNotGoToSD (buffer_task[3].doNotGoToSD),
    .io_in_3_bits_expCompAck (buffer_task[3].expCompAck),
    .io_in_3_bits_allowRetry (buffer_task[3].allowRetry),
    .io_in_3_bits_order (buffer_task[3].order),
    .io_in_3_bits_memAttr_allocate (buffer_task[3].memAttr_allocate),
    .io_in_3_bits_memAttr_cacheable (buffer_task[3].memAttr_cacheable),
    .io_in_3_bits_memAttr_device (buffer_task[3].memAttr_device),
    .io_in_3_bits_memAttr_ewa (buffer_task[3].memAttr_ewa),
    .io_in_3_bits_snpAttr (buffer_task[3].snpAttr),
    .io_in_4_valid (buffer_valid[4] & buffer_w_datRsp[4] & buffer_w_snpRsp[4] & buffer_w_comp[4] & buffer_s_urgentRead[4] & ~buffer_s_comp[4] & ~isRead[4]),
    .io_in_4_bits_set (buffer_task[4].set),
    .io_in_4_bits_bank (buffer_task[4].bank),
    .io_in_4_bits_tag (buffer_task[4].tag),
    .io_in_4_bits_off (buffer_task[4].off),
    .io_in_4_bits_size (buffer_task[4].size),
    .io_in_4_bits_refillTask (buffer_task[4].refillTask),
    .io_in_4_bits_bufID (buffer_task[4].bufID),
    .io_in_4_bits_reqID (buffer_task[4].reqID),
    .io_in_4_bits_replSnp (buffer_task[4].replSnp),
    .io_in_4_bits_snpVec_0 (buffer_task[4].snpVec_0),
    .io_in_4_bits_tgtID (buffer_task[4].tgtID),
    .io_in_4_bits_srcID (buffer_task[4].srcID),
    .io_in_4_bits_txnID (buffer_task[4].txnID),
    .io_in_4_bits_dbID (buffer_task[4].dbID),
    .io_in_4_bits_fwdNID (buffer_task[4].fwdNID),
    .io_in_4_bits_fwdTxnID (buffer_task[4].fwdTxnID),
    .io_in_4_bits_chiOpcode (buffer_task[4].chiOpcode),
    .io_in_4_bits_resp (buffer_task[4].resp),
    .io_in_4_bits_fwdState (buffer_task[4].fwdState),
    .io_in_4_bits_pCrdType (buffer_task[4].pCrdType),
    .io_in_4_bits_retToSrc (buffer_task[4].retToSrc),
    .io_in_4_bits_doNotGoToSD (buffer_task[4].doNotGoToSD),
    .io_in_4_bits_expCompAck (buffer_task[4].expCompAck),
    .io_in_4_bits_allowRetry (buffer_task[4].allowRetry),
    .io_in_4_bits_order (buffer_task[4].order),
    .io_in_4_bits_memAttr_allocate (buffer_task[4].memAttr_allocate),
    .io_in_4_bits_memAttr_cacheable (buffer_task[4].memAttr_cacheable),
    .io_in_4_bits_memAttr_device (buffer_task[4].memAttr_device),
    .io_in_4_bits_memAttr_ewa (buffer_task[4].memAttr_ewa),
    .io_in_4_bits_snpAttr (buffer_task[4].snpAttr),
    .io_in_5_valid (buffer_valid[5] & buffer_w_datRsp[5] & buffer_w_snpRsp[5] & buffer_w_comp[5] & buffer_s_urgentRead[5] & ~buffer_s_comp[5] & ~isRead[5]),
    .io_in_5_bits_set (buffer_task[5].set),
    .io_in_5_bits_bank (buffer_task[5].bank),
    .io_in_5_bits_tag (buffer_task[5].tag),
    .io_in_5_bits_off (buffer_task[5].off),
    .io_in_5_bits_size (buffer_task[5].size),
    .io_in_5_bits_refillTask (buffer_task[5].refillTask),
    .io_in_5_bits_bufID (buffer_task[5].bufID),
    .io_in_5_bits_reqID (buffer_task[5].reqID),
    .io_in_5_bits_replSnp (buffer_task[5].replSnp),
    .io_in_5_bits_snpVec_0 (buffer_task[5].snpVec_0),
    .io_in_5_bits_tgtID (buffer_task[5].tgtID),
    .io_in_5_bits_srcID (buffer_task[5].srcID),
    .io_in_5_bits_txnID (buffer_task[5].txnID),
    .io_in_5_bits_dbID (buffer_task[5].dbID),
    .io_in_5_bits_fwdNID (buffer_task[5].fwdNID),
    .io_in_5_bits_fwdTxnID (buffer_task[5].fwdTxnID),
    .io_in_5_bits_chiOpcode (buffer_task[5].chiOpcode),
    .io_in_5_bits_resp (buffer_task[5].resp),
    .io_in_5_bits_fwdState (buffer_task[5].fwdState),
    .io_in_5_bits_pCrdType (buffer_task[5].pCrdType),
    .io_in_5_bits_retToSrc (buffer_task[5].retToSrc),
    .io_in_5_bits_doNotGoToSD (buffer_task[5].doNotGoToSD),
    .io_in_5_bits_expCompAck (buffer_task[5].expCompAck),
    .io_in_5_bits_allowRetry (buffer_task[5].allowRetry),
    .io_in_5_bits_order (buffer_task[5].order),
    .io_in_5_bits_memAttr_allocate (buffer_task[5].memAttr_allocate),
    .io_in_5_bits_memAttr_cacheable (buffer_task[5].memAttr_cacheable),
    .io_in_5_bits_memAttr_device (buffer_task[5].memAttr_device),
    .io_in_5_bits_memAttr_ewa (buffer_task[5].memAttr_ewa),
    .io_in_5_bits_snpAttr (buffer_task[5].snpAttr),
    .io_in_6_valid (buffer_valid[6] & buffer_w_datRsp[6] & buffer_w_snpRsp[6] & buffer_w_comp[6] & buffer_s_urgentRead[6] & ~buffer_s_comp[6] & ~isRead[6]),
    .io_in_6_bits_set (buffer_task[6].set),
    .io_in_6_bits_bank (buffer_task[6].bank),
    .io_in_6_bits_tag (buffer_task[6].tag),
    .io_in_6_bits_off (buffer_task[6].off),
    .io_in_6_bits_size (buffer_task[6].size),
    .io_in_6_bits_refillTask (buffer_task[6].refillTask),
    .io_in_6_bits_bufID (buffer_task[6].bufID),
    .io_in_6_bits_reqID (buffer_task[6].reqID),
    .io_in_6_bits_replSnp (buffer_task[6].replSnp),
    .io_in_6_bits_snpVec_0 (buffer_task[6].snpVec_0),
    .io_in_6_bits_tgtID (buffer_task[6].tgtID),
    .io_in_6_bits_srcID (buffer_task[6].srcID),
    .io_in_6_bits_txnID (buffer_task[6].txnID),
    .io_in_6_bits_dbID (buffer_task[6].dbID),
    .io_in_6_bits_fwdNID (buffer_task[6].fwdNID),
    .io_in_6_bits_fwdTxnID (buffer_task[6].fwdTxnID),
    .io_in_6_bits_chiOpcode (buffer_task[6].chiOpcode),
    .io_in_6_bits_resp (buffer_task[6].resp),
    .io_in_6_bits_fwdState (buffer_task[6].fwdState),
    .io_in_6_bits_pCrdType (buffer_task[6].pCrdType),
    .io_in_6_bits_retToSrc (buffer_task[6].retToSrc),
    .io_in_6_bits_doNotGoToSD (buffer_task[6].doNotGoToSD),
    .io_in_6_bits_expCompAck (buffer_task[6].expCompAck),
    .io_in_6_bits_allowRetry (buffer_task[6].allowRetry),
    .io_in_6_bits_order (buffer_task[6].order),
    .io_in_6_bits_memAttr_allocate (buffer_task[6].memAttr_allocate),
    .io_in_6_bits_memAttr_cacheable (buffer_task[6].memAttr_cacheable),
    .io_in_6_bits_memAttr_device (buffer_task[6].memAttr_device),
    .io_in_6_bits_memAttr_ewa (buffer_task[6].memAttr_ewa),
    .io_in_6_bits_snpAttr (buffer_task[6].snpAttr),
    .io_in_7_valid (buffer_valid[7] & buffer_w_datRsp[7] & buffer_w_snpRsp[7] & buffer_w_comp[7] & buffer_s_urgentRead[7] & ~buffer_s_comp[7] & ~isRead[7]),
    .io_in_7_bits_set (buffer_task[7].set),
    .io_in_7_bits_bank (buffer_task[7].bank),
    .io_in_7_bits_tag (buffer_task[7].tag),
    .io_in_7_bits_off (buffer_task[7].off),
    .io_in_7_bits_size (buffer_task[7].size),
    .io_in_7_bits_refillTask (buffer_task[7].refillTask),
    .io_in_7_bits_bufID (buffer_task[7].bufID),
    .io_in_7_bits_reqID (buffer_task[7].reqID),
    .io_in_7_bits_replSnp (buffer_task[7].replSnp),
    .io_in_7_bits_snpVec_0 (buffer_task[7].snpVec_0),
    .io_in_7_bits_tgtID (buffer_task[7].tgtID),
    .io_in_7_bits_srcID (buffer_task[7].srcID),
    .io_in_7_bits_txnID (buffer_task[7].txnID),
    .io_in_7_bits_dbID (buffer_task[7].dbID),
    .io_in_7_bits_fwdNID (buffer_task[7].fwdNID),
    .io_in_7_bits_fwdTxnID (buffer_task[7].fwdTxnID),
    .io_in_7_bits_chiOpcode (buffer_task[7].chiOpcode),
    .io_in_7_bits_resp (buffer_task[7].resp),
    .io_in_7_bits_fwdState (buffer_task[7].fwdState),
    .io_in_7_bits_pCrdType (buffer_task[7].pCrdType),
    .io_in_7_bits_retToSrc (buffer_task[7].retToSrc),
    .io_in_7_bits_doNotGoToSD (buffer_task[7].doNotGoToSD),
    .io_in_7_bits_expCompAck (buffer_task[7].expCompAck),
    .io_in_7_bits_allowRetry (buffer_task[7].allowRetry),
    .io_in_7_bits_order (buffer_task[7].order),
    .io_in_7_bits_memAttr_allocate (buffer_task[7].memAttr_allocate),
    .io_in_7_bits_memAttr_cacheable (buffer_task[7].memAttr_cacheable),
    .io_in_7_bits_memAttr_device (buffer_task[7].memAttr_device),
    .io_in_7_bits_memAttr_ewa (buffer_task[7].memAttr_ewa),
    .io_in_7_bits_snpAttr (buffer_task[7].snpAttr),
    .io_in_8_valid (buffer_valid[8] & buffer_w_datRsp[8] & buffer_w_snpRsp[8] & buffer_w_comp[8] & buffer_s_urgentRead[8] & ~buffer_s_comp[8] & ~isRead[8]),
    .io_in_8_bits_set (buffer_task[8].set),
    .io_in_8_bits_bank (buffer_task[8].bank),
    .io_in_8_bits_tag (buffer_task[8].tag),
    .io_in_8_bits_off (buffer_task[8].off),
    .io_in_8_bits_size (buffer_task[8].size),
    .io_in_8_bits_refillTask (buffer_task[8].refillTask),
    .io_in_8_bits_bufID (buffer_task[8].bufID),
    .io_in_8_bits_reqID (buffer_task[8].reqID),
    .io_in_8_bits_replSnp (buffer_task[8].replSnp),
    .io_in_8_bits_snpVec_0 (buffer_task[8].snpVec_0),
    .io_in_8_bits_tgtID (buffer_task[8].tgtID),
    .io_in_8_bits_srcID (buffer_task[8].srcID),
    .io_in_8_bits_txnID (buffer_task[8].txnID),
    .io_in_8_bits_dbID (buffer_task[8].dbID),
    .io_in_8_bits_fwdNID (buffer_task[8].fwdNID),
    .io_in_8_bits_fwdTxnID (buffer_task[8].fwdTxnID),
    .io_in_8_bits_chiOpcode (buffer_task[8].chiOpcode),
    .io_in_8_bits_resp (buffer_task[8].resp),
    .io_in_8_bits_fwdState (buffer_task[8].fwdState),
    .io_in_8_bits_pCrdType (buffer_task[8].pCrdType),
    .io_in_8_bits_retToSrc (buffer_task[8].retToSrc),
    .io_in_8_bits_doNotGoToSD (buffer_task[8].doNotGoToSD),
    .io_in_8_bits_expCompAck (buffer_task[8].expCompAck),
    .io_in_8_bits_allowRetry (buffer_task[8].allowRetry),
    .io_in_8_bits_order (buffer_task[8].order),
    .io_in_8_bits_memAttr_allocate (buffer_task[8].memAttr_allocate),
    .io_in_8_bits_memAttr_cacheable (buffer_task[8].memAttr_cacheable),
    .io_in_8_bits_memAttr_device (buffer_task[8].memAttr_device),
    .io_in_8_bits_memAttr_ewa (buffer_task[8].memAttr_ewa),
    .io_in_8_bits_snpAttr (buffer_task[8].snpAttr),
    .io_in_9_valid (buffer_valid[9] & buffer_w_datRsp[9] & buffer_w_snpRsp[9] & buffer_w_comp[9] & buffer_s_urgentRead[9] & ~buffer_s_comp[9] & ~isRead[9]),
    .io_in_9_bits_set (buffer_task[9].set),
    .io_in_9_bits_bank (buffer_task[9].bank),
    .io_in_9_bits_tag (buffer_task[9].tag),
    .io_in_9_bits_off (buffer_task[9].off),
    .io_in_9_bits_size (buffer_task[9].size),
    .io_in_9_bits_refillTask (buffer_task[9].refillTask),
    .io_in_9_bits_bufID (buffer_task[9].bufID),
    .io_in_9_bits_reqID (buffer_task[9].reqID),
    .io_in_9_bits_replSnp (buffer_task[9].replSnp),
    .io_in_9_bits_snpVec_0 (buffer_task[9].snpVec_0),
    .io_in_9_bits_tgtID (buffer_task[9].tgtID),
    .io_in_9_bits_srcID (buffer_task[9].srcID),
    .io_in_9_bits_txnID (buffer_task[9].txnID),
    .io_in_9_bits_dbID (buffer_task[9].dbID),
    .io_in_9_bits_fwdNID (buffer_task[9].fwdNID),
    .io_in_9_bits_fwdTxnID (buffer_task[9].fwdTxnID),
    .io_in_9_bits_chiOpcode (buffer_task[9].chiOpcode),
    .io_in_9_bits_resp (buffer_task[9].resp),
    .io_in_9_bits_fwdState (buffer_task[9].fwdState),
    .io_in_9_bits_pCrdType (buffer_task[9].pCrdType),
    .io_in_9_bits_retToSrc (buffer_task[9].retToSrc),
    .io_in_9_bits_doNotGoToSD (buffer_task[9].doNotGoToSD),
    .io_in_9_bits_expCompAck (buffer_task[9].expCompAck),
    .io_in_9_bits_allowRetry (buffer_task[9].allowRetry),
    .io_in_9_bits_order (buffer_task[9].order),
    .io_in_9_bits_memAttr_allocate (buffer_task[9].memAttr_allocate),
    .io_in_9_bits_memAttr_cacheable (buffer_task[9].memAttr_cacheable),
    .io_in_9_bits_memAttr_device (buffer_task[9].memAttr_device),
    .io_in_9_bits_memAttr_ewa (buffer_task[9].memAttr_ewa),
    .io_in_9_bits_snpAttr (buffer_task[9].snpAttr),
    .io_in_10_valid (buffer_valid[10] & buffer_w_datRsp[10] & buffer_w_snpRsp[10] & buffer_w_comp[10] & buffer_s_urgentRead[10] & ~buffer_s_comp[10] & ~isRead[10]),
    .io_in_10_bits_set (buffer_task[10].set),
    .io_in_10_bits_bank (buffer_task[10].bank),
    .io_in_10_bits_tag (buffer_task[10].tag),
    .io_in_10_bits_off (buffer_task[10].off),
    .io_in_10_bits_size (buffer_task[10].size),
    .io_in_10_bits_refillTask (buffer_task[10].refillTask),
    .io_in_10_bits_bufID (buffer_task[10].bufID),
    .io_in_10_bits_reqID (buffer_task[10].reqID),
    .io_in_10_bits_replSnp (buffer_task[10].replSnp),
    .io_in_10_bits_snpVec_0 (buffer_task[10].snpVec_0),
    .io_in_10_bits_tgtID (buffer_task[10].tgtID),
    .io_in_10_bits_srcID (buffer_task[10].srcID),
    .io_in_10_bits_txnID (buffer_task[10].txnID),
    .io_in_10_bits_dbID (buffer_task[10].dbID),
    .io_in_10_bits_fwdNID (buffer_task[10].fwdNID),
    .io_in_10_bits_fwdTxnID (buffer_task[10].fwdTxnID),
    .io_in_10_bits_chiOpcode (buffer_task[10].chiOpcode),
    .io_in_10_bits_resp (buffer_task[10].resp),
    .io_in_10_bits_fwdState (buffer_task[10].fwdState),
    .io_in_10_bits_pCrdType (buffer_task[10].pCrdType),
    .io_in_10_bits_retToSrc (buffer_task[10].retToSrc),
    .io_in_10_bits_doNotGoToSD (buffer_task[10].doNotGoToSD),
    .io_in_10_bits_expCompAck (buffer_task[10].expCompAck),
    .io_in_10_bits_allowRetry (buffer_task[10].allowRetry),
    .io_in_10_bits_order (buffer_task[10].order),
    .io_in_10_bits_memAttr_allocate (buffer_task[10].memAttr_allocate),
    .io_in_10_bits_memAttr_cacheable (buffer_task[10].memAttr_cacheable),
    .io_in_10_bits_memAttr_device (buffer_task[10].memAttr_device),
    .io_in_10_bits_memAttr_ewa (buffer_task[10].memAttr_ewa),
    .io_in_10_bits_snpAttr (buffer_task[10].snpAttr),
    .io_in_11_valid (buffer_valid[11] & buffer_w_datRsp[11] & buffer_w_snpRsp[11] & buffer_w_comp[11] & buffer_s_urgentRead[11] & ~buffer_s_comp[11] & ~isRead[11]),
    .io_in_11_bits_set (buffer_task[11].set),
    .io_in_11_bits_bank (buffer_task[11].bank),
    .io_in_11_bits_tag (buffer_task[11].tag),
    .io_in_11_bits_off (buffer_task[11].off),
    .io_in_11_bits_size (buffer_task[11].size),
    .io_in_11_bits_refillTask (buffer_task[11].refillTask),
    .io_in_11_bits_bufID (buffer_task[11].bufID),
    .io_in_11_bits_reqID (buffer_task[11].reqID),
    .io_in_11_bits_replSnp (buffer_task[11].replSnp),
    .io_in_11_bits_snpVec_0 (buffer_task[11].snpVec_0),
    .io_in_11_bits_tgtID (buffer_task[11].tgtID),
    .io_in_11_bits_srcID (buffer_task[11].srcID),
    .io_in_11_bits_txnID (buffer_task[11].txnID),
    .io_in_11_bits_dbID (buffer_task[11].dbID),
    .io_in_11_bits_fwdNID (buffer_task[11].fwdNID),
    .io_in_11_bits_fwdTxnID (buffer_task[11].fwdTxnID),
    .io_in_11_bits_chiOpcode (buffer_task[11].chiOpcode),
    .io_in_11_bits_resp (buffer_task[11].resp),
    .io_in_11_bits_fwdState (buffer_task[11].fwdState),
    .io_in_11_bits_pCrdType (buffer_task[11].pCrdType),
    .io_in_11_bits_retToSrc (buffer_task[11].retToSrc),
    .io_in_11_bits_doNotGoToSD (buffer_task[11].doNotGoToSD),
    .io_in_11_bits_expCompAck (buffer_task[11].expCompAck),
    .io_in_11_bits_allowRetry (buffer_task[11].allowRetry),
    .io_in_11_bits_order (buffer_task[11].order),
    .io_in_11_bits_memAttr_allocate (buffer_task[11].memAttr_allocate),
    .io_in_11_bits_memAttr_cacheable (buffer_task[11].memAttr_cacheable),
    .io_in_11_bits_memAttr_device (buffer_task[11].memAttr_device),
    .io_in_11_bits_memAttr_ewa (buffer_task[11].memAttr_ewa),
    .io_in_11_bits_snpAttr (buffer_task[11].snpAttr),
    .io_in_12_valid (buffer_valid[12] & buffer_w_datRsp[12] & buffer_w_snpRsp[12] & buffer_w_comp[12] & buffer_s_urgentRead[12] & ~buffer_s_comp[12] & ~isRead[12]),
    .io_in_12_bits_set (buffer_task[12].set),
    .io_in_12_bits_bank (buffer_task[12].bank),
    .io_in_12_bits_tag (buffer_task[12].tag),
    .io_in_12_bits_off (buffer_task[12].off),
    .io_in_12_bits_size (buffer_task[12].size),
    .io_in_12_bits_refillTask (buffer_task[12].refillTask),
    .io_in_12_bits_bufID (buffer_task[12].bufID),
    .io_in_12_bits_reqID (buffer_task[12].reqID),
    .io_in_12_bits_replSnp (buffer_task[12].replSnp),
    .io_in_12_bits_snpVec_0 (buffer_task[12].snpVec_0),
    .io_in_12_bits_tgtID (buffer_task[12].tgtID),
    .io_in_12_bits_srcID (buffer_task[12].srcID),
    .io_in_12_bits_txnID (buffer_task[12].txnID),
    .io_in_12_bits_dbID (buffer_task[12].dbID),
    .io_in_12_bits_fwdNID (buffer_task[12].fwdNID),
    .io_in_12_bits_fwdTxnID (buffer_task[12].fwdTxnID),
    .io_in_12_bits_chiOpcode (buffer_task[12].chiOpcode),
    .io_in_12_bits_resp (buffer_task[12].resp),
    .io_in_12_bits_fwdState (buffer_task[12].fwdState),
    .io_in_12_bits_pCrdType (buffer_task[12].pCrdType),
    .io_in_12_bits_retToSrc (buffer_task[12].retToSrc),
    .io_in_12_bits_doNotGoToSD (buffer_task[12].doNotGoToSD),
    .io_in_12_bits_expCompAck (buffer_task[12].expCompAck),
    .io_in_12_bits_allowRetry (buffer_task[12].allowRetry),
    .io_in_12_bits_order (buffer_task[12].order),
    .io_in_12_bits_memAttr_allocate (buffer_task[12].memAttr_allocate),
    .io_in_12_bits_memAttr_cacheable (buffer_task[12].memAttr_cacheable),
    .io_in_12_bits_memAttr_device (buffer_task[12].memAttr_device),
    .io_in_12_bits_memAttr_ewa (buffer_task[12].memAttr_ewa),
    .io_in_12_bits_snpAttr (buffer_task[12].snpAttr),
    .io_in_13_valid (buffer_valid[13] & buffer_w_datRsp[13] & buffer_w_snpRsp[13] & buffer_w_comp[13] & buffer_s_urgentRead[13] & ~buffer_s_comp[13] & ~isRead[13]),
    .io_in_13_bits_set (buffer_task[13].set),
    .io_in_13_bits_bank (buffer_task[13].bank),
    .io_in_13_bits_tag (buffer_task[13].tag),
    .io_in_13_bits_off (buffer_task[13].off),
    .io_in_13_bits_size (buffer_task[13].size),
    .io_in_13_bits_refillTask (buffer_task[13].refillTask),
    .io_in_13_bits_bufID (buffer_task[13].bufID),
    .io_in_13_bits_reqID (buffer_task[13].reqID),
    .io_in_13_bits_replSnp (buffer_task[13].replSnp),
    .io_in_13_bits_snpVec_0 (buffer_task[13].snpVec_0),
    .io_in_13_bits_tgtID (buffer_task[13].tgtID),
    .io_in_13_bits_srcID (buffer_task[13].srcID),
    .io_in_13_bits_txnID (buffer_task[13].txnID),
    .io_in_13_bits_dbID (buffer_task[13].dbID),
    .io_in_13_bits_fwdNID (buffer_task[13].fwdNID),
    .io_in_13_bits_fwdTxnID (buffer_task[13].fwdTxnID),
    .io_in_13_bits_chiOpcode (buffer_task[13].chiOpcode),
    .io_in_13_bits_resp (buffer_task[13].resp),
    .io_in_13_bits_fwdState (buffer_task[13].fwdState),
    .io_in_13_bits_pCrdType (buffer_task[13].pCrdType),
    .io_in_13_bits_retToSrc (buffer_task[13].retToSrc),
    .io_in_13_bits_doNotGoToSD (buffer_task[13].doNotGoToSD),
    .io_in_13_bits_expCompAck (buffer_task[13].expCompAck),
    .io_in_13_bits_allowRetry (buffer_task[13].allowRetry),
    .io_in_13_bits_order (buffer_task[13].order),
    .io_in_13_bits_memAttr_allocate (buffer_task[13].memAttr_allocate),
    .io_in_13_bits_memAttr_cacheable (buffer_task[13].memAttr_cacheable),
    .io_in_13_bits_memAttr_device (buffer_task[13].memAttr_device),
    .io_in_13_bits_memAttr_ewa (buffer_task[13].memAttr_ewa),
    .io_in_13_bits_snpAttr (buffer_task[13].snpAttr),
    .io_in_14_valid (buffer_valid[14] & buffer_w_datRsp[14] & buffer_w_snpRsp[14] & buffer_w_comp[14] & buffer_s_urgentRead[14] & ~buffer_s_comp[14] & ~isRead[14]),
    .io_in_14_bits_set (buffer_task[14].set),
    .io_in_14_bits_bank (buffer_task[14].bank),
    .io_in_14_bits_tag (buffer_task[14].tag),
    .io_in_14_bits_off (buffer_task[14].off),
    .io_in_14_bits_size (buffer_task[14].size),
    .io_in_14_bits_refillTask (buffer_task[14].refillTask),
    .io_in_14_bits_bufID (buffer_task[14].bufID),
    .io_in_14_bits_reqID (buffer_task[14].reqID),
    .io_in_14_bits_replSnp (buffer_task[14].replSnp),
    .io_in_14_bits_snpVec_0 (buffer_task[14].snpVec_0),
    .io_in_14_bits_tgtID (buffer_task[14].tgtID),
    .io_in_14_bits_srcID (buffer_task[14].srcID),
    .io_in_14_bits_txnID (buffer_task[14].txnID),
    .io_in_14_bits_dbID (buffer_task[14].dbID),
    .io_in_14_bits_fwdNID (buffer_task[14].fwdNID),
    .io_in_14_bits_fwdTxnID (buffer_task[14].fwdTxnID),
    .io_in_14_bits_chiOpcode (buffer_task[14].chiOpcode),
    .io_in_14_bits_resp (buffer_task[14].resp),
    .io_in_14_bits_fwdState (buffer_task[14].fwdState),
    .io_in_14_bits_pCrdType (buffer_task[14].pCrdType),
    .io_in_14_bits_retToSrc (buffer_task[14].retToSrc),
    .io_in_14_bits_doNotGoToSD (buffer_task[14].doNotGoToSD),
    .io_in_14_bits_expCompAck (buffer_task[14].expCompAck),
    .io_in_14_bits_allowRetry (buffer_task[14].allowRetry),
    .io_in_14_bits_order (buffer_task[14].order),
    .io_in_14_bits_memAttr_allocate (buffer_task[14].memAttr_allocate),
    .io_in_14_bits_memAttr_cacheable (buffer_task[14].memAttr_cacheable),
    .io_in_14_bits_memAttr_device (buffer_task[14].memAttr_device),
    .io_in_14_bits_memAttr_ewa (buffer_task[14].memAttr_ewa),
    .io_in_14_bits_snpAttr (buffer_task[14].snpAttr),
    .io_in_15_valid (buffer_valid[15] & buffer_w_datRsp[15] & buffer_w_snpRsp[15] & buffer_w_comp[15] & buffer_s_urgentRead[15] & ~buffer_s_comp[15] & ~isRead[15]),
    .io_in_15_bits_set (buffer_task[15].set),
    .io_in_15_bits_bank (buffer_task[15].bank),
    .io_in_15_bits_tag (buffer_task[15].tag),
    .io_in_15_bits_off (buffer_task[15].off),
    .io_in_15_bits_size (buffer_task[15].size),
    .io_in_15_bits_refillTask (buffer_task[15].refillTask),
    .io_in_15_bits_bufID (buffer_task[15].bufID),
    .io_in_15_bits_reqID (buffer_task[15].reqID),
    .io_in_15_bits_replSnp (buffer_task[15].replSnp),
    .io_in_15_bits_snpVec_0 (buffer_task[15].snpVec_0),
    .io_in_15_bits_tgtID (buffer_task[15].tgtID),
    .io_in_15_bits_srcID (buffer_task[15].srcID),
    .io_in_15_bits_txnID (buffer_task[15].txnID),
    .io_in_15_bits_dbID (buffer_task[15].dbID),
    .io_in_15_bits_fwdNID (buffer_task[15].fwdNID),
    .io_in_15_bits_fwdTxnID (buffer_task[15].fwdTxnID),
    .io_in_15_bits_chiOpcode (buffer_task[15].chiOpcode),
    .io_in_15_bits_resp (buffer_task[15].resp),
    .io_in_15_bits_fwdState (buffer_task[15].fwdState),
    .io_in_15_bits_pCrdType (buffer_task[15].pCrdType),
    .io_in_15_bits_retToSrc (buffer_task[15].retToSrc),
    .io_in_15_bits_doNotGoToSD (buffer_task[15].doNotGoToSD),
    .io_in_15_bits_expCompAck (buffer_task[15].expCompAck),
    .io_in_15_bits_allowRetry (buffer_task[15].allowRetry),
    .io_in_15_bits_order (buffer_task[15].order),
    .io_in_15_bits_memAttr_allocate (buffer_task[15].memAttr_allocate),
    .io_in_15_bits_memAttr_cacheable (buffer_task[15].memAttr_cacheable),
    .io_in_15_bits_memAttr_device (buffer_task[15].memAttr_device),
    .io_in_15_bits_memAttr_ewa (buffer_task[15].memAttr_ewa),
    .io_in_15_bits_snpAttr (buffer_task[15].snpAttr),
    .io_out_ready (io_txrsp_ready),
    .io_out_valid (txrspArb_out_valid),
    .io_out_bits_set (), .io_out_bits_bank (), .io_out_bits_tag (),
    .io_out_bits_off (), .io_out_bits_size (), .io_out_bits_refillTask (),
    .io_out_bits_bufID (), .io_out_bits_reqID (), .io_out_bits_replSnp (),
    .io_out_bits_snpVec_0 (),
    .io_out_bits_tgtID (io_txrsp_bits_tgtID),
    .io_out_bits_srcID (io_txrsp_bits_srcID),
    .io_out_bits_txnID (io_txrsp_bits_txnID),
    .io_out_bits_dbID (io_txrsp_bits_dbID),
    .io_out_bits_fwdNID (), .io_out_bits_fwdTxnID (),
    .io_out_bits_chiOpcode (txrspArb_out_chiOpcode),
    .io_out_bits_resp (io_txrsp_bits_resp),
    .io_out_bits_fwdState (io_txrsp_bits_fwdState),
    .io_out_bits_pCrdType (io_txrsp_bits_pCrdType),
    .io_out_bits_retToSrc (), .io_out_bits_doNotGoToSD (),
    .io_out_bits_expCompAck (), .io_out_bits_allowRetry (), .io_out_bits_order (),
    .io_out_bits_memAttr_allocate (), .io_out_bits_memAttr_cacheable (),
    .io_out_bits_memAttr_device (), .io_out_bits_memAttr_ewa (), .io_out_bits_snpAttr (),
    .io_chosen (txrspArb_chosen)
  );
  FastArbiter_52 txdatArb (
    .clock (clock), .reset (reset),
    .io_in_0_valid (buffer_valid[0] & buffer_w_datRsp[0] & buffer_w_snpRsp[0] & buffer_s_urgentRead[0] & ~buffer_s_comp[0] & isRead[0]),
    .io_in_0_bits_task_tgtID (buffer_task[0].tgtID),
    .io_in_0_bits_task_srcID (buffer_task[0].srcID),
    .io_in_0_bits_task_txnID (buffer_task[0].txnID),
    .io_in_0_bits_task_homeNID (buffer_task[0].homeNID),
    .io_in_0_bits_task_dbID (buffer_task[0].dbID),
    .io_in_0_bits_task_resp (buffer_task[0].resp),
    .io_in_0_bits_task_fwdState (buffer_task[0].fwdState),
    .io_in_0_bits_data_data_0_data (buffer_data0[0]),
    .io_in_0_bits_data_data_1_data (buffer_data1[0]),
    .io_in_1_valid (buffer_valid[1] & buffer_w_datRsp[1] & buffer_w_snpRsp[1] & buffer_s_urgentRead[1] & ~buffer_s_comp[1] & isRead[1]),
    .io_in_1_bits_task_tgtID (buffer_task[1].tgtID),
    .io_in_1_bits_task_srcID (buffer_task[1].srcID),
    .io_in_1_bits_task_txnID (buffer_task[1].txnID),
    .io_in_1_bits_task_homeNID (buffer_task[1].homeNID),
    .io_in_1_bits_task_dbID (buffer_task[1].dbID),
    .io_in_1_bits_task_resp (buffer_task[1].resp),
    .io_in_1_bits_task_fwdState (buffer_task[1].fwdState),
    .io_in_1_bits_data_data_0_data (buffer_data0[1]),
    .io_in_1_bits_data_data_1_data (buffer_data1[1]),
    .io_in_2_valid (buffer_valid[2] & buffer_w_datRsp[2] & buffer_w_snpRsp[2] & buffer_s_urgentRead[2] & ~buffer_s_comp[2] & isRead[2]),
    .io_in_2_bits_task_tgtID (buffer_task[2].tgtID),
    .io_in_2_bits_task_srcID (buffer_task[2].srcID),
    .io_in_2_bits_task_txnID (buffer_task[2].txnID),
    .io_in_2_bits_task_homeNID (buffer_task[2].homeNID),
    .io_in_2_bits_task_dbID (buffer_task[2].dbID),
    .io_in_2_bits_task_resp (buffer_task[2].resp),
    .io_in_2_bits_task_fwdState (buffer_task[2].fwdState),
    .io_in_2_bits_data_data_0_data (buffer_data0[2]),
    .io_in_2_bits_data_data_1_data (buffer_data1[2]),
    .io_in_3_valid (buffer_valid[3] & buffer_w_datRsp[3] & buffer_w_snpRsp[3] & buffer_s_urgentRead[3] & ~buffer_s_comp[3] & isRead[3]),
    .io_in_3_bits_task_tgtID (buffer_task[3].tgtID),
    .io_in_3_bits_task_srcID (buffer_task[3].srcID),
    .io_in_3_bits_task_txnID (buffer_task[3].txnID),
    .io_in_3_bits_task_homeNID (buffer_task[3].homeNID),
    .io_in_3_bits_task_dbID (buffer_task[3].dbID),
    .io_in_3_bits_task_resp (buffer_task[3].resp),
    .io_in_3_bits_task_fwdState (buffer_task[3].fwdState),
    .io_in_3_bits_data_data_0_data (buffer_data0[3]),
    .io_in_3_bits_data_data_1_data (buffer_data1[3]),
    .io_in_4_valid (buffer_valid[4] & buffer_w_datRsp[4] & buffer_w_snpRsp[4] & buffer_s_urgentRead[4] & ~buffer_s_comp[4] & isRead[4]),
    .io_in_4_bits_task_tgtID (buffer_task[4].tgtID),
    .io_in_4_bits_task_srcID (buffer_task[4].srcID),
    .io_in_4_bits_task_txnID (buffer_task[4].txnID),
    .io_in_4_bits_task_homeNID (buffer_task[4].homeNID),
    .io_in_4_bits_task_dbID (buffer_task[4].dbID),
    .io_in_4_bits_task_resp (buffer_task[4].resp),
    .io_in_4_bits_task_fwdState (buffer_task[4].fwdState),
    .io_in_4_bits_data_data_0_data (buffer_data0[4]),
    .io_in_4_bits_data_data_1_data (buffer_data1[4]),
    .io_in_5_valid (buffer_valid[5] & buffer_w_datRsp[5] & buffer_w_snpRsp[5] & buffer_s_urgentRead[5] & ~buffer_s_comp[5] & isRead[5]),
    .io_in_5_bits_task_tgtID (buffer_task[5].tgtID),
    .io_in_5_bits_task_srcID (buffer_task[5].srcID),
    .io_in_5_bits_task_txnID (buffer_task[5].txnID),
    .io_in_5_bits_task_homeNID (buffer_task[5].homeNID),
    .io_in_5_bits_task_dbID (buffer_task[5].dbID),
    .io_in_5_bits_task_resp (buffer_task[5].resp),
    .io_in_5_bits_task_fwdState (buffer_task[5].fwdState),
    .io_in_5_bits_data_data_0_data (buffer_data0[5]),
    .io_in_5_bits_data_data_1_data (buffer_data1[5]),
    .io_in_6_valid (buffer_valid[6] & buffer_w_datRsp[6] & buffer_w_snpRsp[6] & buffer_s_urgentRead[6] & ~buffer_s_comp[6] & isRead[6]),
    .io_in_6_bits_task_tgtID (buffer_task[6].tgtID),
    .io_in_6_bits_task_srcID (buffer_task[6].srcID),
    .io_in_6_bits_task_txnID (buffer_task[6].txnID),
    .io_in_6_bits_task_homeNID (buffer_task[6].homeNID),
    .io_in_6_bits_task_dbID (buffer_task[6].dbID),
    .io_in_6_bits_task_resp (buffer_task[6].resp),
    .io_in_6_bits_task_fwdState (buffer_task[6].fwdState),
    .io_in_6_bits_data_data_0_data (buffer_data0[6]),
    .io_in_6_bits_data_data_1_data (buffer_data1[6]),
    .io_in_7_valid (buffer_valid[7] & buffer_w_datRsp[7] & buffer_w_snpRsp[7] & buffer_s_urgentRead[7] & ~buffer_s_comp[7] & isRead[7]),
    .io_in_7_bits_task_tgtID (buffer_task[7].tgtID),
    .io_in_7_bits_task_srcID (buffer_task[7].srcID),
    .io_in_7_bits_task_txnID (buffer_task[7].txnID),
    .io_in_7_bits_task_homeNID (buffer_task[7].homeNID),
    .io_in_7_bits_task_dbID (buffer_task[7].dbID),
    .io_in_7_bits_task_resp (buffer_task[7].resp),
    .io_in_7_bits_task_fwdState (buffer_task[7].fwdState),
    .io_in_7_bits_data_data_0_data (buffer_data0[7]),
    .io_in_7_bits_data_data_1_data (buffer_data1[7]),
    .io_in_8_valid (buffer_valid[8] & buffer_w_datRsp[8] & buffer_w_snpRsp[8] & buffer_s_urgentRead[8] & ~buffer_s_comp[8] & isRead[8]),
    .io_in_8_bits_task_tgtID (buffer_task[8].tgtID),
    .io_in_8_bits_task_srcID (buffer_task[8].srcID),
    .io_in_8_bits_task_txnID (buffer_task[8].txnID),
    .io_in_8_bits_task_homeNID (buffer_task[8].homeNID),
    .io_in_8_bits_task_dbID (buffer_task[8].dbID),
    .io_in_8_bits_task_resp (buffer_task[8].resp),
    .io_in_8_bits_task_fwdState (buffer_task[8].fwdState),
    .io_in_8_bits_data_data_0_data (buffer_data0[8]),
    .io_in_8_bits_data_data_1_data (buffer_data1[8]),
    .io_in_9_valid (buffer_valid[9] & buffer_w_datRsp[9] & buffer_w_snpRsp[9] & buffer_s_urgentRead[9] & ~buffer_s_comp[9] & isRead[9]),
    .io_in_9_bits_task_tgtID (buffer_task[9].tgtID),
    .io_in_9_bits_task_srcID (buffer_task[9].srcID),
    .io_in_9_bits_task_txnID (buffer_task[9].txnID),
    .io_in_9_bits_task_homeNID (buffer_task[9].homeNID),
    .io_in_9_bits_task_dbID (buffer_task[9].dbID),
    .io_in_9_bits_task_resp (buffer_task[9].resp),
    .io_in_9_bits_task_fwdState (buffer_task[9].fwdState),
    .io_in_9_bits_data_data_0_data (buffer_data0[9]),
    .io_in_9_bits_data_data_1_data (buffer_data1[9]),
    .io_in_10_valid (buffer_valid[10] & buffer_w_datRsp[10] & buffer_w_snpRsp[10] & buffer_s_urgentRead[10] & ~buffer_s_comp[10] & isRead[10]),
    .io_in_10_bits_task_tgtID (buffer_task[10].tgtID),
    .io_in_10_bits_task_srcID (buffer_task[10].srcID),
    .io_in_10_bits_task_txnID (buffer_task[10].txnID),
    .io_in_10_bits_task_homeNID (buffer_task[10].homeNID),
    .io_in_10_bits_task_dbID (buffer_task[10].dbID),
    .io_in_10_bits_task_resp (buffer_task[10].resp),
    .io_in_10_bits_task_fwdState (buffer_task[10].fwdState),
    .io_in_10_bits_data_data_0_data (buffer_data0[10]),
    .io_in_10_bits_data_data_1_data (buffer_data1[10]),
    .io_in_11_valid (buffer_valid[11] & buffer_w_datRsp[11] & buffer_w_snpRsp[11] & buffer_s_urgentRead[11] & ~buffer_s_comp[11] & isRead[11]),
    .io_in_11_bits_task_tgtID (buffer_task[11].tgtID),
    .io_in_11_bits_task_srcID (buffer_task[11].srcID),
    .io_in_11_bits_task_txnID (buffer_task[11].txnID),
    .io_in_11_bits_task_homeNID (buffer_task[11].homeNID),
    .io_in_11_bits_task_dbID (buffer_task[11].dbID),
    .io_in_11_bits_task_resp (buffer_task[11].resp),
    .io_in_11_bits_task_fwdState (buffer_task[11].fwdState),
    .io_in_11_bits_data_data_0_data (buffer_data0[11]),
    .io_in_11_bits_data_data_1_data (buffer_data1[11]),
    .io_in_12_valid (buffer_valid[12] & buffer_w_datRsp[12] & buffer_w_snpRsp[12] & buffer_s_urgentRead[12] & ~buffer_s_comp[12] & isRead[12]),
    .io_in_12_bits_task_tgtID (buffer_task[12].tgtID),
    .io_in_12_bits_task_srcID (buffer_task[12].srcID),
    .io_in_12_bits_task_txnID (buffer_task[12].txnID),
    .io_in_12_bits_task_homeNID (buffer_task[12].homeNID),
    .io_in_12_bits_task_dbID (buffer_task[12].dbID),
    .io_in_12_bits_task_resp (buffer_task[12].resp),
    .io_in_12_bits_task_fwdState (buffer_task[12].fwdState),
    .io_in_12_bits_data_data_0_data (buffer_data0[12]),
    .io_in_12_bits_data_data_1_data (buffer_data1[12]),
    .io_in_13_valid (buffer_valid[13] & buffer_w_datRsp[13] & buffer_w_snpRsp[13] & buffer_s_urgentRead[13] & ~buffer_s_comp[13] & isRead[13]),
    .io_in_13_bits_task_tgtID (buffer_task[13].tgtID),
    .io_in_13_bits_task_srcID (buffer_task[13].srcID),
    .io_in_13_bits_task_txnID (buffer_task[13].txnID),
    .io_in_13_bits_task_homeNID (buffer_task[13].homeNID),
    .io_in_13_bits_task_dbID (buffer_task[13].dbID),
    .io_in_13_bits_task_resp (buffer_task[13].resp),
    .io_in_13_bits_task_fwdState (buffer_task[13].fwdState),
    .io_in_13_bits_data_data_0_data (buffer_data0[13]),
    .io_in_13_bits_data_data_1_data (buffer_data1[13]),
    .io_in_14_valid (buffer_valid[14] & buffer_w_datRsp[14] & buffer_w_snpRsp[14] & buffer_s_urgentRead[14] & ~buffer_s_comp[14] & isRead[14]),
    .io_in_14_bits_task_tgtID (buffer_task[14].tgtID),
    .io_in_14_bits_task_srcID (buffer_task[14].srcID),
    .io_in_14_bits_task_txnID (buffer_task[14].txnID),
    .io_in_14_bits_task_homeNID (buffer_task[14].homeNID),
    .io_in_14_bits_task_dbID (buffer_task[14].dbID),
    .io_in_14_bits_task_resp (buffer_task[14].resp),
    .io_in_14_bits_task_fwdState (buffer_task[14].fwdState),
    .io_in_14_bits_data_data_0_data (buffer_data0[14]),
    .io_in_14_bits_data_data_1_data (buffer_data1[14]),
    .io_in_15_valid (buffer_valid[15] & buffer_w_datRsp[15] & buffer_w_snpRsp[15] & buffer_s_urgentRead[15] & ~buffer_s_comp[15] & isRead[15]),
    .io_in_15_bits_task_tgtID (buffer_task[15].tgtID),
    .io_in_15_bits_task_srcID (buffer_task[15].srcID),
    .io_in_15_bits_task_txnID (buffer_task[15].txnID),
    .io_in_15_bits_task_homeNID (buffer_task[15].homeNID),
    .io_in_15_bits_task_dbID (buffer_task[15].dbID),
    .io_in_15_bits_task_resp (buffer_task[15].resp),
    .io_in_15_bits_task_fwdState (buffer_task[15].fwdState),
    .io_in_15_bits_data_data_0_data (buffer_data0[15]),
    .io_in_15_bits_data_data_1_data (buffer_data1[15]),
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

  // ============ 输出装配 ============
  assign io_txrsp_valid = txrspArb_out_valid;
  // txrsp.chiOpcode: 高 6 位 2, 低位由仲裁出的 opcode 判定(golden 编码)
  assign io_txrsp_bits_chiOpcode =
    {6'h2, (txrspArb_out_chiOpcode == 7'h1B) | (txrspArb_out_chiOpcode == 7'h17)
         | ((txrspArb_out_chiOpcode == 7'h42) & isMissVec[txrspArb_chosen])};
  assign io_txdat_valid = txdatArb_out_valid;
  // respInfo[16]
  for (genvar i = 0; i < N; i++) begin : g_respinfo
    assign io_respInfo_valid[i]     = buffer_valid[i] & ~will_free[i];
    assign io_respInfo_set[i]       = buffer_task[i].set;
    assign io_respInfo_tag[i]       = buffer_task[i].tag;
    assign io_respInfo_opcode[i]    = buffer_task[i].chiOpcode;
    assign io_respInfo_reqID[i]     = buffer_task[i].reqID;
    assign io_respInfo_w_snpRsp[i]  = buffer_w_snpRsp[i];
    assign io_respInfo_w_compdata[i]= buffer_w_datRsp[i];
    assign io_respInfo_w_compack[i] = buffer_w_compack[i]
      | (io_rnRxrsp_valid & rnRxrspOp2 & (io_rnRxrsp_bits_txnID == buffer_task[i].reqID));
    assign io_respInfo_is_miss[i]   = buffer_is_miss[i];
  end
  // urgentRead
  assign io_urgentRead_valid       = |urgent_vec;
  assign io_urgentRead_bits_set    = buffer_task[urgentIdx].set;
  assign io_urgentRead_bits_bank   = buffer_task[urgentIdx].bank;
  assign io_urgentRead_bits_tag    = buffer_task[urgentIdx].tag;
  assign io_urgentRead_bits_tgtID  = buffer_task[urgentIdx].tgtID;
  assign io_urgentRead_bits_srcID  = buffer_task[urgentIdx].srcID;
  assign io_urgentRead_bits_txnID  = buffer_task[urgentIdx].reqID;
  assign io_urgentRead_bits_pCrdType = buffer_task[urgentIdx].pCrdType;

endmodule
