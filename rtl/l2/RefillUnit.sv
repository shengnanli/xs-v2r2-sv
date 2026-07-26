// ============================================================================
// RefillUnit —— OpenLLC refill 缓冲区(可读手写核 xs_RefillUnit_core)
// ----------------------------------------------------------------------------
// 忠实重写 golden RefillUnit.sv(firtool 展开的 16 条目 refill buffer + FastArbiter_50)。
// 逻辑等价 bug-for-bug(源自 openLLC/RefillUnit.scala):
//   * 16 条目 buffer, 每条目保存: 完整 task(33 字段) + state{s_refill,w_datRsp,w_snpRsp}
//     + data{data_0,data_1}(2 拍 × 256b) + beatValids[2] + dirResult{clients_hit,
//     clients_meta_0_valid} + isWrite;
//   * Alloc: buffer 未满 & io_alloc.valid → 首个空槽(priority insertIdx)写入, 置 bufID=insertIdx,
//     清 beatValids;
//   * rspData(RXDAT)更新: 命中 reqID==txnID & valid 的条目; cancel=isWrite & resp==I;
//     beatId=dataID[1], newBeatValids = 旧|OH(beatId), w_datRsp=newBeatValids.andR,
//     按 beatId 存 data_0/data_1, 写 task.resp; opcode==SnpRespData → 清 snpVec 位 & w_snpRsp;
//   * rsp(RXRSP)更新: 命中 reqID==txnID & valid & ~w_snpRsp & opcode==SnpResp → 清 snpVec & w_snpRsp;
//   * rspData&rsp 同时且都是 Snp*且 txnID 相等 → 同时清两源 srcID 位;
//   * Issue: arb.in.valid = valid & w_datRsp & ~s_refill & (~replSnp | replSnp & w_snpRsp);
//     task.fire(_GEN_96) → 置 chosen 条目 s_refill;
//   * Data read: ridReg = RegEnable(read.bits.id, read.valid); io.data = buffer(ridReg).data;
//   * Dealloc: valid & ~w_datRsp & ~isWrite & w_snpRsp & beatValids==0 → 清 valid;
//     io.read.valid → 清 read.bits.id 条目 valid & w_datRsp;
//   * refillInfo: 每条目 {valid, task.set, task.tag, task.reqID} 直连输出;
//   * bufferTimer: valid 时自增, valid→invalid(REG_i & ~valid)时清零(泄漏检测计时, 仅
//     `ifndef SYNTHESIS 断言读取 → 两侧对称 cone-dead)。
// numRNs=1 ⇒ src_idOH = (srcID==0), newSnpVec = snpVec & ~src_idOH = snpVec & (|srcID)。
// beatSize=2 ⇒ beatId=dataID[1], w_datRsp=beatValids[0]&beatValids[1]。
// FastArbiter_50 在两侧 elaborate(确定性逻辑, 非厂商宏)。
// ============================================================================

package xs_refillunit_pkg;
  localparam int unsigned N        = 16;   // buffer 条目数 (mshrs.refill)
  localparam int unsigned IDX_W    = 4;    // $clog2(16)
  localparam int unsigned TIMER_W  = 16;

  // 完整 CHI Task(与 golden Task bundle 逐字段位宽一致)
  typedef struct packed {
    logic [11:0] set;
    logic [1:0]  bank;
    logic [27:0] tag;
    logic [5:0]  off;
    logic [2:0]  size;
    logic        refillTask;
    logic [3:0]  bufID;
    logic [11:0] reqID;
    logic        replSnp;
    logic        snpVec_0;
    logic [10:0] tgtID;
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [11:0] dbID;
    logic [10:0] fwdNID;
    logic [11:0] fwdTxnID;
    logic [6:0]  chiOpcode;
    logic [2:0]  resp;
    logic [2:0]  fwdState;
    logic [3:0]  pCrdType;
    logic        retToSrc;
    logic        doNotGoToSD;
    logic        expCompAck;
    logic        allowRetry;
    logic [1:0]  order;
    logic        memAttr_allocate;
    logic        memAttr_cacheable;
    logic        memAttr_device;
    logic        memAttr_ewa;
    logic        snpAttr;
  } task_t;
endpackage

module xs_RefillUnit_core
  import xs_refillunit_pkg::*;
(
  input  logic         clock,
  input  logic         reset,

  // ---------------- alloc(来自 MainPipe 的 refill 请求) ----------------
  input  logic         io_alloc_valid,
  input  logic         io_alloc_bits_state_w_snpRsp,
  input  task_t        io_alloc_task,
  input  logic         io_alloc_bits_dirResult_clients_hit,
  input  logic         io_alloc_bits_dirResult_clients_meta_0_valid,
  input  logic         io_alloc_bits_isWrite,

  // ---------------- task(送 request arbiter) ----------------
  input  logic         io_task_ready,
  output logic         io_task_valid,
  output task_t        io_task_bits,

  // ---------------- respData(RXDAT) ----------------
  input  logic         io_respData_valid,
  input  logic [11:0]  io_respData_bits_txnID,
  input  logic [6:0]   io_respData_bits_opcode,
  input  logic [2:0]   io_respData_bits_resp,
  input  logic [10:0]  io_respData_bits_srcID,
  input  logic [1:0]   io_respData_bits_dataID,
  input  logic [255:0] io_respData_bits_data_data,

  // ---------------- resp(RXRSP) ----------------
  input  logic         io_resp_valid,
  input  logic [11:0]  io_resp_bits_txnID,
  input  logic [6:0]   io_resp_bits_opcode,
  input  logic [10:0]  io_resp_bits_srcID,

  // ---------------- refill data read ----------------
  input  logic         io_read_valid,
  input  logic [3:0]   io_read_bits_id,
  output logic [255:0] io_data_data_0_data,
  output logic [255:0] io_data_data_1_data,

  // ---------------- refill buffers info(16 路) ----------------
  output logic [N-1:0]        io_refillInfo_valid,
  output logic [N-1:0][11:0]  io_refillInfo_set,
  output logic [N-1:0][27:0]  io_refillInfo_tag,
  output logic [N-1:0][11:0]  io_refillInfo_reqID
);

  // CHI 常量: SnpRespData=0x1(respData opcode), SnpResp=0x1(resp opcode), I=0(resp)
  localparam logic [6:0] SnpRespData = 7'h1;
  localparam logic [6:0] SnpResp     = 7'h1;

  // -------------------- buffer 状态寄存器 --------------------
  task_t               buffer_task     [N-1:0];
  logic                buffer_valid    [N-1:0];
  logic                buffer_s_refill [N-1:0];
  logic                buffer_w_datRsp [N-1:0];
  logic                buffer_w_snpRsp [N-1:0];
  logic [255:0]        buffer_data_0   [N-1:0];
  logic [255:0]        buffer_data_1   [N-1:0];
  logic                buffer_bv_0     [N-1:0];   // beatValids[0]
  logic                buffer_bv_1     [N-1:0];   // beatValids[1]
  logic                buffer_dir_hit  [N-1:0];
  logic                buffer_dir_meta [N-1:0];   // dirResult_clients_meta_0_valid
  logic                buffer_isWrite  [N-1:0];
  logic [TIMER_W-1:0]  bufferTimer     [N-1:0];
  logic                REG_valid_d     [N-1:0];   // 上一拍 valid(golden REG_i)
  logic [IDX_W-1:0]    ridReg;

  // -------------------- full / insertIdx / canAlloc --------------------
  logic [N-1:0] validVec;
  for (genvar i = 0; i < N; i++) begin : g_validvec
    assign validVec[i] = buffer_valid[i];
  end
  logic full;
  assign full = (validVec == {N{1'b1}});     // Cat(valid).andR
  logic canAlloc;
  assign canAlloc = ~full & io_alloc_valid;

  // 首个空槽索引(PriorityEncoder(!valid), 缺省 N-1=15 与 golden 末项一致)
  logic [IDX_W-1:0] insertIdx;
  always_comb begin
    insertIdx = {IDX_W{1'b1}};
    for (int k = N-1; k >= 0; k--) begin
      if (!buffer_valid[k]) insertIdx = IDX_W'(k);
    end
  end

  // -------------------- rspData 匹配向量 (update_vec) --------------------
  logic [N-1:0] uvD;   // update_vec:  reqID==respData.txnID & valid
  for (genvar i = 0; i < N; i++) begin : g_uvD
    assign uvD[i] = (buffer_task[i].reqID == io_respData_bits_txnID) & buffer_valid[i];
  end
  logic canUpdateD;
  assign canUpdateD = (uvD != '0);
  logic [IDX_W-1:0] update_id;
  always_comb begin
    update_id = {IDX_W{1'b1}};
    for (int k = N-1; k >= 0; k--) if (uvD[k]) update_id = IDX_W'(k);
  end

  // -------------------- rsp 匹配向量 (update_vec_1) --------------------
  // reqID==resp.txnID & valid & ~w_snpRsp & resp.opcode==SnpResp
  logic snpResp_op;
  assign snpResp_op = (io_resp_bits_opcode == SnpResp);
  logic [N-1:0] uvR;
  for (genvar i = 0; i < N; i++) begin : g_uvR
    assign uvR[i] = (buffer_task[i].reqID == io_resp_bits_txnID) & buffer_valid[i]
                  & ~buffer_w_snpRsp[i] & snpResp_op;
  end
  logic canUpdateR;
  assign canUpdateR = (uvR != '0);
  logic [IDX_W-1:0] update_id_1;
  always_comb begin
    update_id_1 = {IDX_W{1'b1}};
    for (int k = N-1; k >= 0; k--) if (uvR[k]) update_id_1 = IDX_W'(k);
  end

  // -------------------- 合并 rspData&rsp 匹配向量 (update_vec_2) --------------------
  // reqID==resp.txnID & valid & ~w_snpRsp  (opcode/txnID 相等条件在门控 _GEN_1/_2/_3 里)
  logic [N-1:0] uvC;
  for (genvar i = 0; i < N; i++) begin : g_uvC
    assign uvC[i] = (buffer_task[i].reqID == io_resp_bits_txnID) & buffer_valid[i]
                  & ~buffer_w_snpRsp[i];
  end
  logic canUpdateC;
  assign canUpdateC = (uvC != '0);
  logic [IDX_W-1:0] update_id_2;
  always_comb begin
    update_id_2 = {IDX_W{1'b1}};
    for (int k = N-1; k >= 0; k--) if (uvC[k]) update_id_2 = IDX_W'(k);
  end

  // -------------------- rspData 更新派生量 --------------------
  logic inv_CBWrData;                     // resp === I(0)
  assign inv_CBWrData = (io_respData_bits_resp == 3'h0);
  logic cancel;                           // isWrite[update_id] & inv_CBWrData
  assign cancel = buffer_isWrite[update_id] & inv_CBWrData;
  // newBeatValids = {bv_1[uid], bv_0[uid]} | (2'h1 << dataID[1])
  logic [1:0] newBeatValids;
  assign newBeatValids = ({buffer_bv_1[update_id], buffer_bv_0[update_id]})
                       | (2'h1 << io_respData_bits_dataID[1]);
  // newSnpVec(numRNs=1): snpVec[uid] & (|srcID)
  logic newSnpVec_0;
  assign newSnpVec_0   = buffer_task[update_id].snpVec_0   & (|io_respData_bits_srcID);
  logic newSnpVec_1_0;
  assign newSnpVec_1_0 = buffer_task[update_id_1].snpVec_0 & (|io_resp_bits_srcID);
  logic newSnpVec_2_0;
  assign newSnpVec_2_0 = buffer_task[update_id_2].snpVec_0
                       & (|io_respData_bits_srcID) & (|io_resp_bits_srcID);

  // rspData opcode == SnpRespData
  logic respData_snp;
  assign respData_snp = (io_respData_bits_opcode == SnpRespData);
  // 合并-when 门控: rspData.valid & rsp.valid & rspData.opcode==SnpRespData &
  //                 rsp.opcode==SnpResp & rspData.txnID==rsp.txnID
  logic bothValid, bothSnp, sameTxn, combUpd;
  assign bothValid = io_respData_valid & io_resp_valid;
  assign bothSnp   = respData_snp & snpResp_op;
  assign sameTxn   = (io_respData_bits_txnID == io_resp_bits_txnID);
  assign combUpd   = bothValid & bothSnp & sameTxn & canUpdateC;

  // -------------------- task.fire / issue --------------------
  logic arb_out_valid;
  logic [IDX_W-1:0] arb_chosen;
  logic taskFire;                         // _GEN_96 = io_task_ready & arb_out_valid
  assign taskFire = io_task_ready & arb_out_valid;

  // -------------------- 每条目状态机 --------------------
  for (genvar i = 0; i < N; i++) begin : g_entry
    localparam logic [IDX_W-1:0] IDX = IDX_W'(i);

    logic allocHere;                      // _GEN_16.. = canAlloc & insertIdx==i
    assign allocHere = canAlloc & (insertIdx == IDX);

    // dealloc cancel(_cancel_1..): valid & ~w_datRsp & ~isWrite & w_snpRsp & beatValids==0
    logic deallocCancel;
    assign deallocCancel = buffer_valid[i] & ~buffer_w_datRsp[i] & ~buffer_isWrite[i]
                         & buffer_w_snpRsp[i] & ~(buffer_bv_1[i] | buffer_bv_0[i]);

    // rspData 命中本条目
    logic rspDataHit;                     // _GEN_50 = respData.valid & canUpdateD & update_id==i
    assign rspDataHit = io_respData_valid & canUpdateD & (update_id == IDX);

    // valid 的入队/保持项(_GEN_51..): rspDataHit ? ~cancel : (allocHere | valid)
    logic validKeep;
    assign validKeep = rspDataHit ? ~cancel : (allocHere | buffer_valid[i]);

    // read 命中本条目(清 valid & w_datRsp)
    logic readHit;
    assign readHit = io_read_valid & (io_read_bits_id == IDX);

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        buffer_valid[i]    <= 1'b0;
        buffer_task[i]     <= '0;
        buffer_s_refill[i] <= 1'b0;
        buffer_w_datRsp[i] <= 1'b0;
        buffer_w_snpRsp[i] <= 1'b0;
        buffer_data_0[i]   <= '0;
        buffer_data_1[i]   <= '0;
        buffer_bv_0[i]     <= 1'b0;
        buffer_bv_1[i]     <= 1'b0;
        buffer_dir_hit[i]  <= 1'b0;
        buffer_dir_meta[i] <= 1'b0;
        buffer_isWrite[i]  <= 1'b0;
        bufferTimer[i]     <= '0;
        REG_valid_d[i]     <= 1'b0;
      end
      else begin
        // ---- valid: read 命中或 dealloc-cancel 清 0, 否则 validKeep ----
        buffer_valid[i] <= ~(readHit | deallocCancel) & validKeep;

        // ---- task payload(除 snpVec/resp/refillTask/bufID): 仅 alloc 写 ----
        if (allocHere) begin
          buffer_task[i].set               <= io_alloc_task.set;
          buffer_task[i].bank              <= io_alloc_task.bank;
          buffer_task[i].tag               <= io_alloc_task.tag;
          buffer_task[i].off               <= io_alloc_task.off;
          buffer_task[i].size              <= io_alloc_task.size;
          buffer_task[i].reqID             <= io_alloc_task.reqID;
          buffer_task[i].replSnp           <= io_alloc_task.replSnp;
          buffer_task[i].tgtID             <= io_alloc_task.tgtID;
          buffer_task[i].srcID             <= io_alloc_task.srcID;
          buffer_task[i].txnID             <= io_alloc_task.txnID;
          buffer_task[i].dbID              <= io_alloc_task.dbID;
          buffer_task[i].fwdNID            <= io_alloc_task.fwdNID;
          buffer_task[i].fwdTxnID          <= io_alloc_task.fwdTxnID;
          buffer_task[i].chiOpcode         <= io_alloc_task.chiOpcode;
          buffer_task[i].fwdState          <= io_alloc_task.fwdState;
          buffer_task[i].pCrdType          <= io_alloc_task.pCrdType;
          buffer_task[i].retToSrc          <= io_alloc_task.retToSrc;
          buffer_task[i].doNotGoToSD       <= io_alloc_task.doNotGoToSD;
          buffer_task[i].expCompAck        <= io_alloc_task.expCompAck;
          buffer_task[i].allowRetry        <= io_alloc_task.allowRetry;
          buffer_task[i].order             <= io_alloc_task.order;
          buffer_task[i].memAttr_allocate  <= io_alloc_task.memAttr_allocate;
          buffer_task[i].memAttr_cacheable <= io_alloc_task.memAttr_cacheable;
          buffer_task[i].memAttr_device    <= io_alloc_task.memAttr_device;
          buffer_task[i].memAttr_ewa       <= io_alloc_task.memAttr_ewa;
          buffer_task[i].snpAttr           <= io_alloc_task.snpAttr;
          buffer_dir_hit[i]                <= io_alloc_bits_dirResult_clients_hit;
          buffer_dir_meta[i]               <= io_alloc_bits_dirResult_clients_meta_0_valid;
          buffer_isWrite[i]                <= io_alloc_bits_isWrite;
        end

        // ---- refillTask: alloc 置 0 保持?(golden: allocHere | refillTask 粘住)----
        buffer_task[i].refillTask <= allocHere | buffer_task[i].refillTask;
        // ---- bufID: alloc 时写 insertIdx ----
        if (allocHere)
          buffer_task[i].bufID <= insertIdx;

        // ---- snpVec_0 / w_snpRsp: 4 路优先 ----
        if (combUpd & (update_id_2 == IDX)) begin
          buffer_task[i].snpVec_0 <= newSnpVec_2_0;
          buffer_w_snpRsp[i]      <= ~newSnpVec_2_0;
        end
        else if (io_resp_valid & canUpdateR & (update_id_1 == IDX)) begin
          buffer_task[i].snpVec_0 <= newSnpVec_1_0;
          buffer_w_snpRsp[i]      <= ~newSnpVec_1_0;
        end
        else if (io_respData_valid & canUpdateD & respData_snp & (update_id == IDX)) begin
          buffer_task[i].snpVec_0 <= newSnpVec_0;
          buffer_w_snpRsp[i]      <= ~newSnpVec_0;
        end
        else if (allocHere) begin
          buffer_task[i].snpVec_0 <= io_alloc_task.snpVec_0;
          buffer_w_snpRsp[i]      <= io_alloc_bits_state_w_snpRsp;
        end

        // ---- task.resp / beatValids ----
        if (rspDataHit) begin
          buffer_task[i].resp <= io_respData_bits_resp;
          buffer_bv_0[i]      <= newBeatValids[0];
          buffer_bv_1[i]      <= newBeatValids[1];
        end
        else begin
          if (allocHere)
            buffer_task[i].resp <= io_alloc_task.resp;
          buffer_bv_0[i] <= ~allocHere & buffer_bv_0[i];
          buffer_bv_1[i] <= ~allocHere & buffer_bv_1[i];
        end

        // ---- s_refill: fire 置位 chosen 条目; alloc 清; 否则保持 ----
        buffer_s_refill[i] <=
          (taskFire & (arb_chosen == IDX)) | (~allocHere & buffer_s_refill[i]);

        // ---- w_datRsp: read 命中清; rspDataHit → andR; alloc 清; 否则保持 ----
        buffer_w_datRsp[i] <=
          ~readHit & (rspDataHit ? (&newBeatValids) : (~allocHere & buffer_w_datRsp[i]));

        // ---- data_0 / data_1: rspData 命中且 beatId 选择 ----
        if (io_respData_valid & canUpdateD & (update_id == IDX) & ~io_respData_bits_dataID[1])
          buffer_data_0[i] <= io_respData_bits_data_data;
        if (io_respData_valid & canUpdateD & (update_id == IDX) & io_respData_bits_dataID[1])
          buffer_data_1[i] <= io_respData_bits_data_data;

        // ---- bufferTimer(泄漏检测计时): valid→invalid 清 0, valid 时自增 ----
        if (REG_valid_d[i] & ~buffer_valid[i])
          bufferTimer[i] <= '0;
        else if (buffer_valid[i])
          bufferTimer[i] <= TIMER_W'(bufferTimer[i] + 16'h1);
        REG_valid_d[i] <= buffer_valid[i];
      end
    end
  end

  // -------------------- ridReg(RegEnable) --------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) ridReg <= 4'h0;
    else if (io_read_valid) ridReg <= io_read_bits_id;
  end

  // -------------------- 仲裁器输入 --------------------
  logic [N-1:0] arb_in_valid;
  task_t [N-1:0] arb_in_task;
  for (genvar i = 0; i < N; i++) begin : g_arbin
    assign arb_in_valid[i] = buffer_valid[i] & buffer_w_datRsp[i] & ~buffer_s_refill[i]
                           & (~buffer_task[i].replSnp
                              | (buffer_task[i].replSnp & buffer_w_snpRsp[i]));
    assign arb_in_task[i]  = buffer_task[i];
  end

  task_t arb_out_bits;

  FastArbiter_50 issueArb (
    .clock (clock),
    .reset (reset),
    .io_in_0_valid (arb_in_valid[0]), .io_in_0_bits_set (arb_in_task[0].set), .io_in_0_bits_bank (arb_in_task[0].bank), .io_in_0_bits_tag (arb_in_task[0].tag), .io_in_0_bits_off (arb_in_task[0].off), .io_in_0_bits_size (arb_in_task[0].size), .io_in_0_bits_refillTask (arb_in_task[0].refillTask), .io_in_0_bits_bufID (arb_in_task[0].bufID), .io_in_0_bits_reqID (arb_in_task[0].reqID), .io_in_0_bits_replSnp (arb_in_task[0].replSnp), .io_in_0_bits_snpVec_0 (arb_in_task[0].snpVec_0), .io_in_0_bits_tgtID (arb_in_task[0].tgtID), .io_in_0_bits_srcID (arb_in_task[0].srcID), .io_in_0_bits_txnID (arb_in_task[0].txnID), .io_in_0_bits_dbID (arb_in_task[0].dbID), .io_in_0_bits_fwdNID (arb_in_task[0].fwdNID), .io_in_0_bits_fwdTxnID (arb_in_task[0].fwdTxnID), .io_in_0_bits_chiOpcode (arb_in_task[0].chiOpcode), .io_in_0_bits_resp (arb_in_task[0].resp), .io_in_0_bits_fwdState (arb_in_task[0].fwdState), .io_in_0_bits_pCrdType (arb_in_task[0].pCrdType), .io_in_0_bits_retToSrc (arb_in_task[0].retToSrc), .io_in_0_bits_doNotGoToSD (arb_in_task[0].doNotGoToSD), .io_in_0_bits_expCompAck (arb_in_task[0].expCompAck), .io_in_0_bits_allowRetry (arb_in_task[0].allowRetry), .io_in_0_bits_order (arb_in_task[0].order), .io_in_0_bits_memAttr_allocate (arb_in_task[0].memAttr_allocate), .io_in_0_bits_memAttr_cacheable (arb_in_task[0].memAttr_cacheable), .io_in_0_bits_memAttr_device (arb_in_task[0].memAttr_device), .io_in_0_bits_memAttr_ewa (arb_in_task[0].memAttr_ewa), .io_in_0_bits_snpAttr (arb_in_task[0].snpAttr),
    .io_in_1_valid (arb_in_valid[1]), .io_in_1_bits_set (arb_in_task[1].set), .io_in_1_bits_bank (arb_in_task[1].bank), .io_in_1_bits_tag (arb_in_task[1].tag), .io_in_1_bits_off (arb_in_task[1].off), .io_in_1_bits_size (arb_in_task[1].size), .io_in_1_bits_refillTask (arb_in_task[1].refillTask), .io_in_1_bits_bufID (arb_in_task[1].bufID), .io_in_1_bits_reqID (arb_in_task[1].reqID), .io_in_1_bits_replSnp (arb_in_task[1].replSnp), .io_in_1_bits_snpVec_0 (arb_in_task[1].snpVec_0), .io_in_1_bits_tgtID (arb_in_task[1].tgtID), .io_in_1_bits_srcID (arb_in_task[1].srcID), .io_in_1_bits_txnID (arb_in_task[1].txnID), .io_in_1_bits_dbID (arb_in_task[1].dbID), .io_in_1_bits_fwdNID (arb_in_task[1].fwdNID), .io_in_1_bits_fwdTxnID (arb_in_task[1].fwdTxnID), .io_in_1_bits_chiOpcode (arb_in_task[1].chiOpcode), .io_in_1_bits_resp (arb_in_task[1].resp), .io_in_1_bits_fwdState (arb_in_task[1].fwdState), .io_in_1_bits_pCrdType (arb_in_task[1].pCrdType), .io_in_1_bits_retToSrc (arb_in_task[1].retToSrc), .io_in_1_bits_doNotGoToSD (arb_in_task[1].doNotGoToSD), .io_in_1_bits_expCompAck (arb_in_task[1].expCompAck), .io_in_1_bits_allowRetry (arb_in_task[1].allowRetry), .io_in_1_bits_order (arb_in_task[1].order), .io_in_1_bits_memAttr_allocate (arb_in_task[1].memAttr_allocate), .io_in_1_bits_memAttr_cacheable (arb_in_task[1].memAttr_cacheable), .io_in_1_bits_memAttr_device (arb_in_task[1].memAttr_device), .io_in_1_bits_memAttr_ewa (arb_in_task[1].memAttr_ewa), .io_in_1_bits_snpAttr (arb_in_task[1].snpAttr),
    .io_in_2_valid (arb_in_valid[2]), .io_in_2_bits_set (arb_in_task[2].set), .io_in_2_bits_bank (arb_in_task[2].bank), .io_in_2_bits_tag (arb_in_task[2].tag), .io_in_2_bits_off (arb_in_task[2].off), .io_in_2_bits_size (arb_in_task[2].size), .io_in_2_bits_refillTask (arb_in_task[2].refillTask), .io_in_2_bits_bufID (arb_in_task[2].bufID), .io_in_2_bits_reqID (arb_in_task[2].reqID), .io_in_2_bits_replSnp (arb_in_task[2].replSnp), .io_in_2_bits_snpVec_0 (arb_in_task[2].snpVec_0), .io_in_2_bits_tgtID (arb_in_task[2].tgtID), .io_in_2_bits_srcID (arb_in_task[2].srcID), .io_in_2_bits_txnID (arb_in_task[2].txnID), .io_in_2_bits_dbID (arb_in_task[2].dbID), .io_in_2_bits_fwdNID (arb_in_task[2].fwdNID), .io_in_2_bits_fwdTxnID (arb_in_task[2].fwdTxnID), .io_in_2_bits_chiOpcode (arb_in_task[2].chiOpcode), .io_in_2_bits_resp (arb_in_task[2].resp), .io_in_2_bits_fwdState (arb_in_task[2].fwdState), .io_in_2_bits_pCrdType (arb_in_task[2].pCrdType), .io_in_2_bits_retToSrc (arb_in_task[2].retToSrc), .io_in_2_bits_doNotGoToSD (arb_in_task[2].doNotGoToSD), .io_in_2_bits_expCompAck (arb_in_task[2].expCompAck), .io_in_2_bits_allowRetry (arb_in_task[2].allowRetry), .io_in_2_bits_order (arb_in_task[2].order), .io_in_2_bits_memAttr_allocate (arb_in_task[2].memAttr_allocate), .io_in_2_bits_memAttr_cacheable (arb_in_task[2].memAttr_cacheable), .io_in_2_bits_memAttr_device (arb_in_task[2].memAttr_device), .io_in_2_bits_memAttr_ewa (arb_in_task[2].memAttr_ewa), .io_in_2_bits_snpAttr (arb_in_task[2].snpAttr),
    .io_in_3_valid (arb_in_valid[3]), .io_in_3_bits_set (arb_in_task[3].set), .io_in_3_bits_bank (arb_in_task[3].bank), .io_in_3_bits_tag (arb_in_task[3].tag), .io_in_3_bits_off (arb_in_task[3].off), .io_in_3_bits_size (arb_in_task[3].size), .io_in_3_bits_refillTask (arb_in_task[3].refillTask), .io_in_3_bits_bufID (arb_in_task[3].bufID), .io_in_3_bits_reqID (arb_in_task[3].reqID), .io_in_3_bits_replSnp (arb_in_task[3].replSnp), .io_in_3_bits_snpVec_0 (arb_in_task[3].snpVec_0), .io_in_3_bits_tgtID (arb_in_task[3].tgtID), .io_in_3_bits_srcID (arb_in_task[3].srcID), .io_in_3_bits_txnID (arb_in_task[3].txnID), .io_in_3_bits_dbID (arb_in_task[3].dbID), .io_in_3_bits_fwdNID (arb_in_task[3].fwdNID), .io_in_3_bits_fwdTxnID (arb_in_task[3].fwdTxnID), .io_in_3_bits_chiOpcode (arb_in_task[3].chiOpcode), .io_in_3_bits_resp (arb_in_task[3].resp), .io_in_3_bits_fwdState (arb_in_task[3].fwdState), .io_in_3_bits_pCrdType (arb_in_task[3].pCrdType), .io_in_3_bits_retToSrc (arb_in_task[3].retToSrc), .io_in_3_bits_doNotGoToSD (arb_in_task[3].doNotGoToSD), .io_in_3_bits_expCompAck (arb_in_task[3].expCompAck), .io_in_3_bits_allowRetry (arb_in_task[3].allowRetry), .io_in_3_bits_order (arb_in_task[3].order), .io_in_3_bits_memAttr_allocate (arb_in_task[3].memAttr_allocate), .io_in_3_bits_memAttr_cacheable (arb_in_task[3].memAttr_cacheable), .io_in_3_bits_memAttr_device (arb_in_task[3].memAttr_device), .io_in_3_bits_memAttr_ewa (arb_in_task[3].memAttr_ewa), .io_in_3_bits_snpAttr (arb_in_task[3].snpAttr),
    .io_in_4_valid (arb_in_valid[4]), .io_in_4_bits_set (arb_in_task[4].set), .io_in_4_bits_bank (arb_in_task[4].bank), .io_in_4_bits_tag (arb_in_task[4].tag), .io_in_4_bits_off (arb_in_task[4].off), .io_in_4_bits_size (arb_in_task[4].size), .io_in_4_bits_refillTask (arb_in_task[4].refillTask), .io_in_4_bits_bufID (arb_in_task[4].bufID), .io_in_4_bits_reqID (arb_in_task[4].reqID), .io_in_4_bits_replSnp (arb_in_task[4].replSnp), .io_in_4_bits_snpVec_0 (arb_in_task[4].snpVec_0), .io_in_4_bits_tgtID (arb_in_task[4].tgtID), .io_in_4_bits_srcID (arb_in_task[4].srcID), .io_in_4_bits_txnID (arb_in_task[4].txnID), .io_in_4_bits_dbID (arb_in_task[4].dbID), .io_in_4_bits_fwdNID (arb_in_task[4].fwdNID), .io_in_4_bits_fwdTxnID (arb_in_task[4].fwdTxnID), .io_in_4_bits_chiOpcode (arb_in_task[4].chiOpcode), .io_in_4_bits_resp (arb_in_task[4].resp), .io_in_4_bits_fwdState (arb_in_task[4].fwdState), .io_in_4_bits_pCrdType (arb_in_task[4].pCrdType), .io_in_4_bits_retToSrc (arb_in_task[4].retToSrc), .io_in_4_bits_doNotGoToSD (arb_in_task[4].doNotGoToSD), .io_in_4_bits_expCompAck (arb_in_task[4].expCompAck), .io_in_4_bits_allowRetry (arb_in_task[4].allowRetry), .io_in_4_bits_order (arb_in_task[4].order), .io_in_4_bits_memAttr_allocate (arb_in_task[4].memAttr_allocate), .io_in_4_bits_memAttr_cacheable (arb_in_task[4].memAttr_cacheable), .io_in_4_bits_memAttr_device (arb_in_task[4].memAttr_device), .io_in_4_bits_memAttr_ewa (arb_in_task[4].memAttr_ewa), .io_in_4_bits_snpAttr (arb_in_task[4].snpAttr),
    .io_in_5_valid (arb_in_valid[5]), .io_in_5_bits_set (arb_in_task[5].set), .io_in_5_bits_bank (arb_in_task[5].bank), .io_in_5_bits_tag (arb_in_task[5].tag), .io_in_5_bits_off (arb_in_task[5].off), .io_in_5_bits_size (arb_in_task[5].size), .io_in_5_bits_refillTask (arb_in_task[5].refillTask), .io_in_5_bits_bufID (arb_in_task[5].bufID), .io_in_5_bits_reqID (arb_in_task[5].reqID), .io_in_5_bits_replSnp (arb_in_task[5].replSnp), .io_in_5_bits_snpVec_0 (arb_in_task[5].snpVec_0), .io_in_5_bits_tgtID (arb_in_task[5].tgtID), .io_in_5_bits_srcID (arb_in_task[5].srcID), .io_in_5_bits_txnID (arb_in_task[5].txnID), .io_in_5_bits_dbID (arb_in_task[5].dbID), .io_in_5_bits_fwdNID (arb_in_task[5].fwdNID), .io_in_5_bits_fwdTxnID (arb_in_task[5].fwdTxnID), .io_in_5_bits_chiOpcode (arb_in_task[5].chiOpcode), .io_in_5_bits_resp (arb_in_task[5].resp), .io_in_5_bits_fwdState (arb_in_task[5].fwdState), .io_in_5_bits_pCrdType (arb_in_task[5].pCrdType), .io_in_5_bits_retToSrc (arb_in_task[5].retToSrc), .io_in_5_bits_doNotGoToSD (arb_in_task[5].doNotGoToSD), .io_in_5_bits_expCompAck (arb_in_task[5].expCompAck), .io_in_5_bits_allowRetry (arb_in_task[5].allowRetry), .io_in_5_bits_order (arb_in_task[5].order), .io_in_5_bits_memAttr_allocate (arb_in_task[5].memAttr_allocate), .io_in_5_bits_memAttr_cacheable (arb_in_task[5].memAttr_cacheable), .io_in_5_bits_memAttr_device (arb_in_task[5].memAttr_device), .io_in_5_bits_memAttr_ewa (arb_in_task[5].memAttr_ewa), .io_in_5_bits_snpAttr (arb_in_task[5].snpAttr),
    .io_in_6_valid (arb_in_valid[6]), .io_in_6_bits_set (arb_in_task[6].set), .io_in_6_bits_bank (arb_in_task[6].bank), .io_in_6_bits_tag (arb_in_task[6].tag), .io_in_6_bits_off (arb_in_task[6].off), .io_in_6_bits_size (arb_in_task[6].size), .io_in_6_bits_refillTask (arb_in_task[6].refillTask), .io_in_6_bits_bufID (arb_in_task[6].bufID), .io_in_6_bits_reqID (arb_in_task[6].reqID), .io_in_6_bits_replSnp (arb_in_task[6].replSnp), .io_in_6_bits_snpVec_0 (arb_in_task[6].snpVec_0), .io_in_6_bits_tgtID (arb_in_task[6].tgtID), .io_in_6_bits_srcID (arb_in_task[6].srcID), .io_in_6_bits_txnID (arb_in_task[6].txnID), .io_in_6_bits_dbID (arb_in_task[6].dbID), .io_in_6_bits_fwdNID (arb_in_task[6].fwdNID), .io_in_6_bits_fwdTxnID (arb_in_task[6].fwdTxnID), .io_in_6_bits_chiOpcode (arb_in_task[6].chiOpcode), .io_in_6_bits_resp (arb_in_task[6].resp), .io_in_6_bits_fwdState (arb_in_task[6].fwdState), .io_in_6_bits_pCrdType (arb_in_task[6].pCrdType), .io_in_6_bits_retToSrc (arb_in_task[6].retToSrc), .io_in_6_bits_doNotGoToSD (arb_in_task[6].doNotGoToSD), .io_in_6_bits_expCompAck (arb_in_task[6].expCompAck), .io_in_6_bits_allowRetry (arb_in_task[6].allowRetry), .io_in_6_bits_order (arb_in_task[6].order), .io_in_6_bits_memAttr_allocate (arb_in_task[6].memAttr_allocate), .io_in_6_bits_memAttr_cacheable (arb_in_task[6].memAttr_cacheable), .io_in_6_bits_memAttr_device (arb_in_task[6].memAttr_device), .io_in_6_bits_memAttr_ewa (arb_in_task[6].memAttr_ewa), .io_in_6_bits_snpAttr (arb_in_task[6].snpAttr),
    .io_in_7_valid (arb_in_valid[7]), .io_in_7_bits_set (arb_in_task[7].set), .io_in_7_bits_bank (arb_in_task[7].bank), .io_in_7_bits_tag (arb_in_task[7].tag), .io_in_7_bits_off (arb_in_task[7].off), .io_in_7_bits_size (arb_in_task[7].size), .io_in_7_bits_refillTask (arb_in_task[7].refillTask), .io_in_7_bits_bufID (arb_in_task[7].bufID), .io_in_7_bits_reqID (arb_in_task[7].reqID), .io_in_7_bits_replSnp (arb_in_task[7].replSnp), .io_in_7_bits_snpVec_0 (arb_in_task[7].snpVec_0), .io_in_7_bits_tgtID (arb_in_task[7].tgtID), .io_in_7_bits_srcID (arb_in_task[7].srcID), .io_in_7_bits_txnID (arb_in_task[7].txnID), .io_in_7_bits_dbID (arb_in_task[7].dbID), .io_in_7_bits_fwdNID (arb_in_task[7].fwdNID), .io_in_7_bits_fwdTxnID (arb_in_task[7].fwdTxnID), .io_in_7_bits_chiOpcode (arb_in_task[7].chiOpcode), .io_in_7_bits_resp (arb_in_task[7].resp), .io_in_7_bits_fwdState (arb_in_task[7].fwdState), .io_in_7_bits_pCrdType (arb_in_task[7].pCrdType), .io_in_7_bits_retToSrc (arb_in_task[7].retToSrc), .io_in_7_bits_doNotGoToSD (arb_in_task[7].doNotGoToSD), .io_in_7_bits_expCompAck (arb_in_task[7].expCompAck), .io_in_7_bits_allowRetry (arb_in_task[7].allowRetry), .io_in_7_bits_order (arb_in_task[7].order), .io_in_7_bits_memAttr_allocate (arb_in_task[7].memAttr_allocate), .io_in_7_bits_memAttr_cacheable (arb_in_task[7].memAttr_cacheable), .io_in_7_bits_memAttr_device (arb_in_task[7].memAttr_device), .io_in_7_bits_memAttr_ewa (arb_in_task[7].memAttr_ewa), .io_in_7_bits_snpAttr (arb_in_task[7].snpAttr),
    .io_in_8_valid (arb_in_valid[8]), .io_in_8_bits_set (arb_in_task[8].set), .io_in_8_bits_bank (arb_in_task[8].bank), .io_in_8_bits_tag (arb_in_task[8].tag), .io_in_8_bits_off (arb_in_task[8].off), .io_in_8_bits_size (arb_in_task[8].size), .io_in_8_bits_refillTask (arb_in_task[8].refillTask), .io_in_8_bits_bufID (arb_in_task[8].bufID), .io_in_8_bits_reqID (arb_in_task[8].reqID), .io_in_8_bits_replSnp (arb_in_task[8].replSnp), .io_in_8_bits_snpVec_0 (arb_in_task[8].snpVec_0), .io_in_8_bits_tgtID (arb_in_task[8].tgtID), .io_in_8_bits_srcID (arb_in_task[8].srcID), .io_in_8_bits_txnID (arb_in_task[8].txnID), .io_in_8_bits_dbID (arb_in_task[8].dbID), .io_in_8_bits_fwdNID (arb_in_task[8].fwdNID), .io_in_8_bits_fwdTxnID (arb_in_task[8].fwdTxnID), .io_in_8_bits_chiOpcode (arb_in_task[8].chiOpcode), .io_in_8_bits_resp (arb_in_task[8].resp), .io_in_8_bits_fwdState (arb_in_task[8].fwdState), .io_in_8_bits_pCrdType (arb_in_task[8].pCrdType), .io_in_8_bits_retToSrc (arb_in_task[8].retToSrc), .io_in_8_bits_doNotGoToSD (arb_in_task[8].doNotGoToSD), .io_in_8_bits_expCompAck (arb_in_task[8].expCompAck), .io_in_8_bits_allowRetry (arb_in_task[8].allowRetry), .io_in_8_bits_order (arb_in_task[8].order), .io_in_8_bits_memAttr_allocate (arb_in_task[8].memAttr_allocate), .io_in_8_bits_memAttr_cacheable (arb_in_task[8].memAttr_cacheable), .io_in_8_bits_memAttr_device (arb_in_task[8].memAttr_device), .io_in_8_bits_memAttr_ewa (arb_in_task[8].memAttr_ewa), .io_in_8_bits_snpAttr (arb_in_task[8].snpAttr),
    .io_in_9_valid (arb_in_valid[9]), .io_in_9_bits_set (arb_in_task[9].set), .io_in_9_bits_bank (arb_in_task[9].bank), .io_in_9_bits_tag (arb_in_task[9].tag), .io_in_9_bits_off (arb_in_task[9].off), .io_in_9_bits_size (arb_in_task[9].size), .io_in_9_bits_refillTask (arb_in_task[9].refillTask), .io_in_9_bits_bufID (arb_in_task[9].bufID), .io_in_9_bits_reqID (arb_in_task[9].reqID), .io_in_9_bits_replSnp (arb_in_task[9].replSnp), .io_in_9_bits_snpVec_0 (arb_in_task[9].snpVec_0), .io_in_9_bits_tgtID (arb_in_task[9].tgtID), .io_in_9_bits_srcID (arb_in_task[9].srcID), .io_in_9_bits_txnID (arb_in_task[9].txnID), .io_in_9_bits_dbID (arb_in_task[9].dbID), .io_in_9_bits_fwdNID (arb_in_task[9].fwdNID), .io_in_9_bits_fwdTxnID (arb_in_task[9].fwdTxnID), .io_in_9_bits_chiOpcode (arb_in_task[9].chiOpcode), .io_in_9_bits_resp (arb_in_task[9].resp), .io_in_9_bits_fwdState (arb_in_task[9].fwdState), .io_in_9_bits_pCrdType (arb_in_task[9].pCrdType), .io_in_9_bits_retToSrc (arb_in_task[9].retToSrc), .io_in_9_bits_doNotGoToSD (arb_in_task[9].doNotGoToSD), .io_in_9_bits_expCompAck (arb_in_task[9].expCompAck), .io_in_9_bits_allowRetry (arb_in_task[9].allowRetry), .io_in_9_bits_order (arb_in_task[9].order), .io_in_9_bits_memAttr_allocate (arb_in_task[9].memAttr_allocate), .io_in_9_bits_memAttr_cacheable (arb_in_task[9].memAttr_cacheable), .io_in_9_bits_memAttr_device (arb_in_task[9].memAttr_device), .io_in_9_bits_memAttr_ewa (arb_in_task[9].memAttr_ewa), .io_in_9_bits_snpAttr (arb_in_task[9].snpAttr),
    .io_in_10_valid (arb_in_valid[10]), .io_in_10_bits_set (arb_in_task[10].set), .io_in_10_bits_bank (arb_in_task[10].bank), .io_in_10_bits_tag (arb_in_task[10].tag), .io_in_10_bits_off (arb_in_task[10].off), .io_in_10_bits_size (arb_in_task[10].size), .io_in_10_bits_refillTask (arb_in_task[10].refillTask), .io_in_10_bits_bufID (arb_in_task[10].bufID), .io_in_10_bits_reqID (arb_in_task[10].reqID), .io_in_10_bits_replSnp (arb_in_task[10].replSnp), .io_in_10_bits_snpVec_0 (arb_in_task[10].snpVec_0), .io_in_10_bits_tgtID (arb_in_task[10].tgtID), .io_in_10_bits_srcID (arb_in_task[10].srcID), .io_in_10_bits_txnID (arb_in_task[10].txnID), .io_in_10_bits_dbID (arb_in_task[10].dbID), .io_in_10_bits_fwdNID (arb_in_task[10].fwdNID), .io_in_10_bits_fwdTxnID (arb_in_task[10].fwdTxnID), .io_in_10_bits_chiOpcode (arb_in_task[10].chiOpcode), .io_in_10_bits_resp (arb_in_task[10].resp), .io_in_10_bits_fwdState (arb_in_task[10].fwdState), .io_in_10_bits_pCrdType (arb_in_task[10].pCrdType), .io_in_10_bits_retToSrc (arb_in_task[10].retToSrc), .io_in_10_bits_doNotGoToSD (arb_in_task[10].doNotGoToSD), .io_in_10_bits_expCompAck (arb_in_task[10].expCompAck), .io_in_10_bits_allowRetry (arb_in_task[10].allowRetry), .io_in_10_bits_order (arb_in_task[10].order), .io_in_10_bits_memAttr_allocate (arb_in_task[10].memAttr_allocate), .io_in_10_bits_memAttr_cacheable (arb_in_task[10].memAttr_cacheable), .io_in_10_bits_memAttr_device (arb_in_task[10].memAttr_device), .io_in_10_bits_memAttr_ewa (arb_in_task[10].memAttr_ewa), .io_in_10_bits_snpAttr (arb_in_task[10].snpAttr),
    .io_in_11_valid (arb_in_valid[11]), .io_in_11_bits_set (arb_in_task[11].set), .io_in_11_bits_bank (arb_in_task[11].bank), .io_in_11_bits_tag (arb_in_task[11].tag), .io_in_11_bits_off (arb_in_task[11].off), .io_in_11_bits_size (arb_in_task[11].size), .io_in_11_bits_refillTask (arb_in_task[11].refillTask), .io_in_11_bits_bufID (arb_in_task[11].bufID), .io_in_11_bits_reqID (arb_in_task[11].reqID), .io_in_11_bits_replSnp (arb_in_task[11].replSnp), .io_in_11_bits_snpVec_0 (arb_in_task[11].snpVec_0), .io_in_11_bits_tgtID (arb_in_task[11].tgtID), .io_in_11_bits_srcID (arb_in_task[11].srcID), .io_in_11_bits_txnID (arb_in_task[11].txnID), .io_in_11_bits_dbID (arb_in_task[11].dbID), .io_in_11_bits_fwdNID (arb_in_task[11].fwdNID), .io_in_11_bits_fwdTxnID (arb_in_task[11].fwdTxnID), .io_in_11_bits_chiOpcode (arb_in_task[11].chiOpcode), .io_in_11_bits_resp (arb_in_task[11].resp), .io_in_11_bits_fwdState (arb_in_task[11].fwdState), .io_in_11_bits_pCrdType (arb_in_task[11].pCrdType), .io_in_11_bits_retToSrc (arb_in_task[11].retToSrc), .io_in_11_bits_doNotGoToSD (arb_in_task[11].doNotGoToSD), .io_in_11_bits_expCompAck (arb_in_task[11].expCompAck), .io_in_11_bits_allowRetry (arb_in_task[11].allowRetry), .io_in_11_bits_order (arb_in_task[11].order), .io_in_11_bits_memAttr_allocate (arb_in_task[11].memAttr_allocate), .io_in_11_bits_memAttr_cacheable (arb_in_task[11].memAttr_cacheable), .io_in_11_bits_memAttr_device (arb_in_task[11].memAttr_device), .io_in_11_bits_memAttr_ewa (arb_in_task[11].memAttr_ewa), .io_in_11_bits_snpAttr (arb_in_task[11].snpAttr),
    .io_in_12_valid (arb_in_valid[12]), .io_in_12_bits_set (arb_in_task[12].set), .io_in_12_bits_bank (arb_in_task[12].bank), .io_in_12_bits_tag (arb_in_task[12].tag), .io_in_12_bits_off (arb_in_task[12].off), .io_in_12_bits_size (arb_in_task[12].size), .io_in_12_bits_refillTask (arb_in_task[12].refillTask), .io_in_12_bits_bufID (arb_in_task[12].bufID), .io_in_12_bits_reqID (arb_in_task[12].reqID), .io_in_12_bits_replSnp (arb_in_task[12].replSnp), .io_in_12_bits_snpVec_0 (arb_in_task[12].snpVec_0), .io_in_12_bits_tgtID (arb_in_task[12].tgtID), .io_in_12_bits_srcID (arb_in_task[12].srcID), .io_in_12_bits_txnID (arb_in_task[12].txnID), .io_in_12_bits_dbID (arb_in_task[12].dbID), .io_in_12_bits_fwdNID (arb_in_task[12].fwdNID), .io_in_12_bits_fwdTxnID (arb_in_task[12].fwdTxnID), .io_in_12_bits_chiOpcode (arb_in_task[12].chiOpcode), .io_in_12_bits_resp (arb_in_task[12].resp), .io_in_12_bits_fwdState (arb_in_task[12].fwdState), .io_in_12_bits_pCrdType (arb_in_task[12].pCrdType), .io_in_12_bits_retToSrc (arb_in_task[12].retToSrc), .io_in_12_bits_doNotGoToSD (arb_in_task[12].doNotGoToSD), .io_in_12_bits_expCompAck (arb_in_task[12].expCompAck), .io_in_12_bits_allowRetry (arb_in_task[12].allowRetry), .io_in_12_bits_order (arb_in_task[12].order), .io_in_12_bits_memAttr_allocate (arb_in_task[12].memAttr_allocate), .io_in_12_bits_memAttr_cacheable (arb_in_task[12].memAttr_cacheable), .io_in_12_bits_memAttr_device (arb_in_task[12].memAttr_device), .io_in_12_bits_memAttr_ewa (arb_in_task[12].memAttr_ewa), .io_in_12_bits_snpAttr (arb_in_task[12].snpAttr),
    .io_in_13_valid (arb_in_valid[13]), .io_in_13_bits_set (arb_in_task[13].set), .io_in_13_bits_bank (arb_in_task[13].bank), .io_in_13_bits_tag (arb_in_task[13].tag), .io_in_13_bits_off (arb_in_task[13].off), .io_in_13_bits_size (arb_in_task[13].size), .io_in_13_bits_refillTask (arb_in_task[13].refillTask), .io_in_13_bits_bufID (arb_in_task[13].bufID), .io_in_13_bits_reqID (arb_in_task[13].reqID), .io_in_13_bits_replSnp (arb_in_task[13].replSnp), .io_in_13_bits_snpVec_0 (arb_in_task[13].snpVec_0), .io_in_13_bits_tgtID (arb_in_task[13].tgtID), .io_in_13_bits_srcID (arb_in_task[13].srcID), .io_in_13_bits_txnID (arb_in_task[13].txnID), .io_in_13_bits_dbID (arb_in_task[13].dbID), .io_in_13_bits_fwdNID (arb_in_task[13].fwdNID), .io_in_13_bits_fwdTxnID (arb_in_task[13].fwdTxnID), .io_in_13_bits_chiOpcode (arb_in_task[13].chiOpcode), .io_in_13_bits_resp (arb_in_task[13].resp), .io_in_13_bits_fwdState (arb_in_task[13].fwdState), .io_in_13_bits_pCrdType (arb_in_task[13].pCrdType), .io_in_13_bits_retToSrc (arb_in_task[13].retToSrc), .io_in_13_bits_doNotGoToSD (arb_in_task[13].doNotGoToSD), .io_in_13_bits_expCompAck (arb_in_task[13].expCompAck), .io_in_13_bits_allowRetry (arb_in_task[13].allowRetry), .io_in_13_bits_order (arb_in_task[13].order), .io_in_13_bits_memAttr_allocate (arb_in_task[13].memAttr_allocate), .io_in_13_bits_memAttr_cacheable (arb_in_task[13].memAttr_cacheable), .io_in_13_bits_memAttr_device (arb_in_task[13].memAttr_device), .io_in_13_bits_memAttr_ewa (arb_in_task[13].memAttr_ewa), .io_in_13_bits_snpAttr (arb_in_task[13].snpAttr),
    .io_in_14_valid (arb_in_valid[14]), .io_in_14_bits_set (arb_in_task[14].set), .io_in_14_bits_bank (arb_in_task[14].bank), .io_in_14_bits_tag (arb_in_task[14].tag), .io_in_14_bits_off (arb_in_task[14].off), .io_in_14_bits_size (arb_in_task[14].size), .io_in_14_bits_refillTask (arb_in_task[14].refillTask), .io_in_14_bits_bufID (arb_in_task[14].bufID), .io_in_14_bits_reqID (arb_in_task[14].reqID), .io_in_14_bits_replSnp (arb_in_task[14].replSnp), .io_in_14_bits_snpVec_0 (arb_in_task[14].snpVec_0), .io_in_14_bits_tgtID (arb_in_task[14].tgtID), .io_in_14_bits_srcID (arb_in_task[14].srcID), .io_in_14_bits_txnID (arb_in_task[14].txnID), .io_in_14_bits_dbID (arb_in_task[14].dbID), .io_in_14_bits_fwdNID (arb_in_task[14].fwdNID), .io_in_14_bits_fwdTxnID (arb_in_task[14].fwdTxnID), .io_in_14_bits_chiOpcode (arb_in_task[14].chiOpcode), .io_in_14_bits_resp (arb_in_task[14].resp), .io_in_14_bits_fwdState (arb_in_task[14].fwdState), .io_in_14_bits_pCrdType (arb_in_task[14].pCrdType), .io_in_14_bits_retToSrc (arb_in_task[14].retToSrc), .io_in_14_bits_doNotGoToSD (arb_in_task[14].doNotGoToSD), .io_in_14_bits_expCompAck (arb_in_task[14].expCompAck), .io_in_14_bits_allowRetry (arb_in_task[14].allowRetry), .io_in_14_bits_order (arb_in_task[14].order), .io_in_14_bits_memAttr_allocate (arb_in_task[14].memAttr_allocate), .io_in_14_bits_memAttr_cacheable (arb_in_task[14].memAttr_cacheable), .io_in_14_bits_memAttr_device (arb_in_task[14].memAttr_device), .io_in_14_bits_memAttr_ewa (arb_in_task[14].memAttr_ewa), .io_in_14_bits_snpAttr (arb_in_task[14].snpAttr),
    .io_in_15_valid (arb_in_valid[15]), .io_in_15_bits_set (arb_in_task[15].set), .io_in_15_bits_bank (arb_in_task[15].bank), .io_in_15_bits_tag (arb_in_task[15].tag), .io_in_15_bits_off (arb_in_task[15].off), .io_in_15_bits_size (arb_in_task[15].size), .io_in_15_bits_refillTask (arb_in_task[15].refillTask), .io_in_15_bits_bufID (arb_in_task[15].bufID), .io_in_15_bits_reqID (arb_in_task[15].reqID), .io_in_15_bits_replSnp (arb_in_task[15].replSnp), .io_in_15_bits_snpVec_0 (arb_in_task[15].snpVec_0), .io_in_15_bits_tgtID (arb_in_task[15].tgtID), .io_in_15_bits_srcID (arb_in_task[15].srcID), .io_in_15_bits_txnID (arb_in_task[15].txnID), .io_in_15_bits_dbID (arb_in_task[15].dbID), .io_in_15_bits_fwdNID (arb_in_task[15].fwdNID), .io_in_15_bits_fwdTxnID (arb_in_task[15].fwdTxnID), .io_in_15_bits_chiOpcode (arb_in_task[15].chiOpcode), .io_in_15_bits_resp (arb_in_task[15].resp), .io_in_15_bits_fwdState (arb_in_task[15].fwdState), .io_in_15_bits_pCrdType (arb_in_task[15].pCrdType), .io_in_15_bits_retToSrc (arb_in_task[15].retToSrc), .io_in_15_bits_doNotGoToSD (arb_in_task[15].doNotGoToSD), .io_in_15_bits_expCompAck (arb_in_task[15].expCompAck), .io_in_15_bits_allowRetry (arb_in_task[15].allowRetry), .io_in_15_bits_order (arb_in_task[15].order), .io_in_15_bits_memAttr_allocate (arb_in_task[15].memAttr_allocate), .io_in_15_bits_memAttr_cacheable (arb_in_task[15].memAttr_cacheable), .io_in_15_bits_memAttr_device (arb_in_task[15].memAttr_device), .io_in_15_bits_memAttr_ewa (arb_in_task[15].memAttr_ewa), .io_in_15_bits_snpAttr (arb_in_task[15].snpAttr),
    .io_out_ready                    (1'h1),
    .io_out_valid                    (arb_out_valid),
    .io_out_bits_set                 (arb_out_bits.set),
    .io_out_bits_bank                (arb_out_bits.bank),
    .io_out_bits_tag                 (arb_out_bits.tag),
    .io_out_bits_off                 (arb_out_bits.off),
    .io_out_bits_size                (arb_out_bits.size),
    .io_out_bits_refillTask          (arb_out_bits.refillTask),
    .io_out_bits_bufID               (arb_out_bits.bufID),
    .io_out_bits_reqID               (arb_out_bits.reqID),
    .io_out_bits_replSnp             (arb_out_bits.replSnp),
    .io_out_bits_snpVec_0            (arb_out_bits.snpVec_0),
    .io_out_bits_tgtID               (arb_out_bits.tgtID),
    .io_out_bits_srcID               (arb_out_bits.srcID),
    .io_out_bits_txnID               (arb_out_bits.txnID),
    .io_out_bits_dbID                (arb_out_bits.dbID),
    .io_out_bits_fwdNID              (arb_out_bits.fwdNID),
    .io_out_bits_fwdTxnID            (arb_out_bits.fwdTxnID),
    .io_out_bits_chiOpcode           (arb_out_bits.chiOpcode),
    .io_out_bits_resp                (arb_out_bits.resp),
    .io_out_bits_fwdState            (arb_out_bits.fwdState),
    .io_out_bits_pCrdType            (arb_out_bits.pCrdType),
    .io_out_bits_retToSrc            (arb_out_bits.retToSrc),
    .io_out_bits_doNotGoToSD         (arb_out_bits.doNotGoToSD),
    .io_out_bits_expCompAck          (arb_out_bits.expCompAck),
    .io_out_bits_allowRetry          (arb_out_bits.allowRetry),
    .io_out_bits_order               (arb_out_bits.order),
    .io_out_bits_memAttr_allocate    (arb_out_bits.memAttr_allocate),
    .io_out_bits_memAttr_cacheable   (arb_out_bits.memAttr_cacheable),
    .io_out_bits_memAttr_device      (arb_out_bits.memAttr_device),
    .io_out_bits_memAttr_ewa         (arb_out_bits.memAttr_ewa),
    .io_out_bits_snpAttr             (arb_out_bits.snpAttr),
    .io_chosen                       (arb_chosen)
  );

  // -------------------- 输出装配 --------------------
  assign io_task_valid = arb_out_valid;
  assign io_task_bits  = arb_out_bits;

  assign io_data_data_0_data = buffer_data_0[ridReg];
  assign io_data_data_1_data = buffer_data_1[ridReg];

  for (genvar i = 0; i < N; i++) begin : g_refillinfo
    assign io_refillInfo_valid[i] = buffer_valid[i];
    assign io_refillInfo_set[i]   = buffer_task[i].set;
    assign io_refillInfo_tag[i]   = buffer_task[i].tag;
    assign io_refillInfo_reqID[i] = buffer_task[i].reqID;
  end

endmodule
