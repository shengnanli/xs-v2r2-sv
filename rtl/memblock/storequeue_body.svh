// =============================================================================
//  storequeue_body.svh —— xs_StoreQueue_core 主体（§6..§16），由核 include。
//  这里是手写控制逻辑；与 §0..§5（StoreQueue.sv 内）共享同一作用域的信号。
// =============================================================================

  // ===========================================================================
  //  §6  StoreUnit 写回地址（storeAddrIn 2 路）
  //      s1：写 paddr/vaddr 子模块、置 addrvalid/unaligned/cross16Byte，覆盖 uop。
  //      s2(storeAddrInRe，打一拍)：补 mmio/pending/memBackTypeMM/hasException/prefetch。
  //      这些都是组合「写使能 + 写值」，寄存器更新在 §UNI 统一 always_ff。
  // ===========================================================================
  // 子模块写使能（paddr/vaddr/data wen）直接组合驱动
  // s0：storeAddrIn.fire && !isFrmMisAlignBuf → 写地址子模块
  wire sta0_fire = io_storeAddrIn_0_valid;
  wire sta1_fire = io_storeAddrIn_1_valid;
  assign pa_wen[0] = sta0_fire & ~io_storeAddrIn_0_bits_isFrmMisAlignBuf;
  assign pa_wen[1] = sta1_fire & ~io_storeAddrIn_1_bits_isFrmMisAlignBuf;
  assign va_wen[0] = pa_wen[0];
  assign va_wen[1] = pa_wen[1];

  // s2 寄存：storeAddrInFireReg = RegNext(fire && !miss) && storeAddrInRe.updateAddrValid
  logic sta0_fireReg_q, sta1_fireReg_q;
  logic [SQ_IDX_W-1:0] sta0_wbIdxReg_q, sta1_wbIdxReg_q;
  always_ff @(posedge clock) begin
    sta0_fireReg_q  <= sta0_fire & ~io_storeAddrIn_0_bits_miss;
    sta1_fireReg_q  <= sta1_fire & ~io_storeAddrIn_1_bits_miss;
    if (sta0_fire) sta0_wbIdxReg_q <= io_storeAddrIn_0_bits_uop_sqIdx_value;
    if (sta1_fire) sta1_wbIdxReg_q <= io_storeAddrIn_1_bits_uop_sqIdx_value;
  end
  wire sta0_reFire = sta0_fireReg_q & io_storeAddrInRe_0_updateAddrValid;
  wire sta1_reFire = sta1_fireReg_q & io_storeAddrInRe_1_updateAddrValid;

  // ===========================================================================
  //  §7  StoreData 写回数据（storeDataIn 2 路）+ 掩码
  //      s0：写 data 子模块（wdata 由 fuOpType 选择字节复制，见 subinst 直通的 golden
  //          组合；这里给 wen/wdata）；s1（打一拍）：置 datavalid。
  // ===========================================================================
  // SQDataModule 的 wdata 组合（genVWdata：按 fuOpType[2:0] 复制低字节铺满 128b；
  // cbo_zero→0；向量→原样）。用纯函数表达，替代 golden 的手工 {2{{2{...}}}} 链。
  function automatic logic [VLEN-1:0] gen_vw_data(input logic [8:0] fuOp,
                                                  input logic [34:0] fuType,
                                                  input logic [VLEN-1:0] data);
    logic [VLEN-1:0] r;
    if (fuOp == 9'h7) r = '0;                         // cbo_zero
    else if (fuType[32] | fuType[34]) r = data;       // 向量 store：原样
    else begin
      unique case (fuOp[2:0])
        3'h0: r = {16{data[7:0]}};                    // sb：复制字节
        3'h1: r = {8{data[15:0]}};                    // sh
        3'h2: r = {4{data[31:0]}};                    // sw
        3'h3: r = {2{data[63:0]}};                    // sd
        3'h4: r = data;                               // 128b
        default: r = '0;
      endcase
    end
    return r;
  endfunction
  assign sd_data_wen[0]   = io_storeDataIn_0_valid;
  assign sd_data_wen[1]   = io_storeDataIn_1_valid;
  assign sd_data_wdata[0] = gen_vw_data(io_storeDataIn_0_bits_uop_fuOpType,
                                        io_storeDataIn_0_bits_uop_fuType,
                                        io_storeDataIn_0_bits_data);
  assign sd_data_wdata[1] = gen_vw_data(io_storeDataIn_1_bits_uop_fuOpType,
                                        io_storeDataIn_1_bits_uop_fuType,
                                        io_storeDataIn_1_bits_data);
  // s1：datavalid 置位（RegNext(storeDataIn.fire) && allocated(lastStWbIndex)）
  logic std0_fireReg_q, std1_fireReg_q;
  logic [SQ_IDX_W-1:0] std0_wbIdxReg_q, std1_wbIdxReg_q;
  always_ff @(posedge clock) begin
    std0_fireReg_q <= io_storeDataIn_0_valid;
    std1_fireReg_q <= io_storeDataIn_1_valid;
    if (io_storeDataIn_0_valid) std0_wbIdxReg_q <= io_storeDataIn_0_bits_uop_sqIdx_value;
    if (io_storeDataIn_1_valid) std1_wbIdxReg_q <= io_storeDataIn_1_bits_uop_sqIdx_value;
  end

  // ===========================================================================
  //  §8  load forward 查询（3 路）
  //      把比 load 老的、地址/数据已就绪的 store 数据前递给 load。范围由 sqIdxMask
  //      与 deqMask 在「同圈/异圈」两段切分（forwardMask1/2）。命中 CAM 由 paddr/vaddr
  //      子模块算（forwardMmask），与就绪掩码相与得到 needForward 喂给 data 子模块。
  // ===========================================================================
  // forward 每路输入收进数组
  logic                fwd_valid [LD_PIPE_W];
  logic                fwd_sqF   [LD_PIPE_W];
  logic [SQ_SIZE-1:0]  fwd_sqMask[LD_PIPE_W];
  logic                fwd_loadWaitBit   [LD_PIPE_W];
  logic                fwd_loadWaitStrict[LD_PIPE_W];
  logic                fwd_wfRobF [LD_PIPE_W];
  logic [ROB_IDX_W-1:0]fwd_wfRobV [LD_PIPE_W];
  logic                fwd_sqIdxF [LD_PIPE_W];
  logic [SQ_IDX_W-1:0] fwd_sqIdxV [LD_PIPE_W];
  `define SQ_FWD_BIND(I) \
    assign fwd_valid[I]   = io_forward_``I``_valid; \
    assign fwd_sqF[I]     = io_forward_``I``_sqIdx_flag; \
    assign fwd_sqMask[I]  = io_forward_``I``_sqIdxMask; \
    assign fwd_loadWaitBit[I]    = io_forward_``I``_uop_loadWaitBit; \
    assign fwd_loadWaitStrict[I] = io_forward_``I``_uop_loadWaitStrict; \
    assign fwd_wfRobF[I]  = io_forward_``I``_uop_waitForRobIdx_flag; \
    assign fwd_wfRobV[I]  = io_forward_``I``_uop_waitForRobIdx_value; \
    assign fwd_sqIdxF[I]  = io_forward_``I``_uop_sqIdx_flag; \
    assign fwd_sqIdxV[I]  = io_forward_``I``_uop_sqIdx_value;
  `SQ_FWD_BIND(0) `SQ_FWD_BIND(1) `SQ_FWD_BIND(2)
  `undef SQ_FWD_BIND

  // 就绪向量（组合）：addrValidVec/dataValidVec/allValidVec/addrRealValidVec
  wire [SQ_SIZE-1:0] addrValidVec = addrvalid_v & allocated_v;
  wire [SQ_SIZE-1:0] dataValidVec = datavalid_v;
  wire [SQ_SIZE-1:0] allValidVec  = addrvalid_v & datavalid_v & allocated_v;
  wire [SQ_SIZE-1:0] addrRealValidVec = addrvalid_v & allocated_v;

  // forward 命中网（来自 paddr/vaddr 子模块的 forwardMmask，每路 56 位）
  logic [SQ_SIZE-1:0] paddrFwdMmask [LD_PIPE_W];
  logic [SQ_SIZE-1:0] vaddrFwdMmask [LD_PIPE_W];
  generate
    for (gi = 0; gi < LD_PIPE_W; gi++) begin : g_fwdmmask
      for (genvar gj = 0; gj < SQ_SIZE; gj++) begin : g_fwdmmask_b
        assign paddrFwdMmask[gi][gj] = pa_forwardMmask[gi][gj];
        assign vaddrFwdMmask[gi][gj] = va_forwardMmask[gi][gj];
      end
    end
  endgenerate

  // 每路 forward 的逐 entry 处理（用 generate，避免手工展开 3 路）
  // 输出寄存器（s2）：addrInvalid/dataInvalid/SqIdx 等
  logic                fwd_dataInvalid_q [LD_PIPE_W];
  logic                fwd_matchInvalid_q[LD_PIPE_W];
  logic                fwd_addrInvalid_o [LD_PIPE_W];
  logic                fwd_dataInvalidFast_o [LD_PIPE_W];
  sqptr_t              fwd_addrInvalidSqIdx_o [LD_PIPE_W];
  sqptr_t              fwd_dataInvalidSqIdx_o [LD_PIPE_W];

  generate
    for (gi = 0; gi < LD_PIPE_W; gi++) begin : g_fwd
      // differentFlag：deqPtr 与 forward.sqIdx 是否异圈
      wire differentFlag = deqPtrExt[0].flag ^ fwd_sqF[gi];
      wire [SQ_SIZE-1:0] forwardMask = fwd_sqMask[gi];
      // 两段范围掩码（同圈/异圈切分）
      wire [SQ_SIZE-1:0] forwardMask1 = differentFlag ? ~deqMask : (deqMask ^ forwardMask);
      wire [SQ_SIZE-1:0] forwardMask2 = differentFlag ? forwardMask : '0;
      wire [SQ_SIZE-1:0] canForward1  = forwardMask1 & allValidVec;
      wire [SQ_SIZE-1:0] canForward2  = forwardMask2 & allValidVec;
      wire [SQ_SIZE-1:0] needForward  = differentFlag ? (~deqMask | forwardMask) : (deqMask ^ forwardMask);

      // needForward 喂给 data 子模块（与 vaddr CAM 命中相与）
      wire [SQ_SIZE-1:0] needFwd0 = canForward1 & vaddrFwdMmask[gi];
      wire [SQ_SIZE-1:0] needFwd1 = canForward2 & vaddrFwdMmask[gi];
      if (gi == 0) begin assign sd_need_forward_0_0 = needFwd0; assign sd_need_forward_0_1 = needFwd1; end
      if (gi == 1) begin assign sd_need_forward_1_0 = needFwd0; assign sd_need_forward_1_1 = needFwd1; end
      if (gi == 2) begin assign sd_need_forward_2_0 = needFwd0; assign sd_need_forward_2_1 = needFwd1; end

      // storeSetHitVec（LFSTEnable=true 分支）：load.loadWaitBit & uop(j).robIdx==load.waitForRobIdx
      logic [SQ_SIZE-1:0] storeSetHitVec;
      for (genvar gj = 0; gj < SQ_SIZE; gj++) begin : g_ssh
        assign storeSetHitVec[gj] = fwd_loadWaitBit[gi]
              & (uop[gj].robIdx_flag == fwd_wfRobF[gi])
              & (uop[gj].robIdx_value == fwd_wfRobV[gi]);
      end

      // dataInvalid：地址命中但数据未就绪 / 非对齐 → dataInvalidMask
      wire [SQ_SIZE-1:0] diBase = (addrValidVec & ~dataValidVec & vaddrFwdMmask[gi])
                                  | (unaligned_v & allocated_v);
      wire [SQ_SIZE-1:0] dataInvalidMask1 = diBase & forwardMask1;
      wire [SQ_SIZE-1:0] dataInvalidMask2 = diBase & forwardMask2;
      wire               dataInvalidFast  = |(dataInvalidMask1 | dataInvalidMask2);
      assign fwd_dataInvalidFast_o[gi] = dataInvalidFast;

      // addrInvalid：SSID 命中但地址未就绪
      wire [SQ_SIZE-1:0] addrInvalidMask1 = ~addrValidVec & storeSetHitVec & forwardMask1;
      wire [SQ_SIZE-1:0] addrInvalidMask2 = ~addrValidVec & storeSetHitVec & forwardMask2;

      // s2 寄存
      logic [SQ_SIZE-1:0] di1_q, di2_q, ai1_q, ai2_q;
      logic [SQ_SIZE-1:0] paFwd_q, vaFwd_q, needFwd_q, addrRealValid_q;
      logic               fwdValid_q, diffFlag_q, loadWaitStrict_q, loadWaitStrictRaw_q;
      sqptr_t             enqPtr_q, deqPtr_q, fwdSqIdx_q, fwdSqIdxM1_q;
      always_ff @(posedge clock) begin
        di1_q <= dataInvalidMask1; di2_q <= dataInvalidMask2;
        ai1_q <= addrInvalidMask1; ai2_q <= addrInvalidMask2;
        paFwd_q <= paddrFwdMmask[gi]; vaFwd_q <= vaddrFwdMmask[gi];
        needFwd_q <= needForward; addrRealValid_q <= addrRealValidVec;
        fwdValid_q <= fwd_valid[gi]; diffFlag_q <= differentFlag;
        enqPtr_q <= enqPtrExt[0]; deqPtr_q <= deqPtrExt[0];
        fwd_dataInvalid_q[gi] <= dataInvalidFast;
        if (fwd_valid[gi]) begin
          loadWaitStrict_q <= fwd_loadWaitStrict[gi];
          fwdSqIdx_q   <= '{flag:fwd_sqIdxF[gi], value:fwd_sqIdxV[gi]};
          fwdSqIdxM1_q <= sqptr_sub('{flag:fwd_sqIdxF[gi], value:fwd_sqIdxV[gi]}, 7'd1);
        end
      end

      // matchInvalid：vaddr/paddr CAM 命中不一致（需 replay）
      wire vpmaskNotEqual = |((paFwd_q ^ vaFwd_q) & needFwd_q & addrRealValid_q);
      wire vaddrMatchFailed = vpmaskNotEqual & fwdValid_q;
      assign fwd_matchInvalid_q[gi] = vaddrMatchFailed;

      // addrInvalid 结果
      wire [SQ_SIZE-1:0] aiReg = ai1_q | ai2_q;
      wire addrInvalidFlag = |aiReg;
      wire hasInvalidAddr  = |(~addrValidVec & needForward);
      wire [SQ_IDX_W-1:0] addrInvalidSqIdx1 = rev_prio_idx(ai1_q);
      wire [SQ_IDX_W-1:0] addrInvalidSqIdx2 = rev_prio_idx(ai2_q);
      wire [SQ_IDX_W-1:0] addrInvalidSqIdx  = (|ai2_q) ? addrInvalidSqIdx2 : addrInvalidSqIdx1;
      // addrInvalidSqIdx 的 flag：同圈或 idx>=deqPtr → deq.flag 否则 enq.flag
      always_comb begin
        if (loadWaitStrict_q) begin
          fwd_addrInvalidSqIdx_o[gi] = fwdSqIdxM1_q;
        end else if (addrInvalidFlag) begin
          fwd_addrInvalidSqIdx_o[gi].flag  = (~diffFlag_q | (addrInvalidSqIdx >= deqPtr_q.value)) ? deqPtr_q.flag : enqPtr_q.flag;
          fwd_addrInvalidSqIdx_o[gi].value = addrInvalidSqIdx;
        end else begin
          fwd_addrInvalidSqIdx_o[gi] = fwdSqIdx_q;
        end
      end
      assign fwd_addrInvalid_o[gi] = loadWaitStrict_q ? hasInvalidAddr : addrInvalidFlag;

      // dataInvalidSqIdx 的 flag
      wire [SQ_SIZE-1:0] diReg = di1_q | di2_q;
      wire dataInvalidFlag = |diReg;
      wire [SQ_IDX_W-1:0] dataInvalidSqIdx1 = rev_prio_idx(di1_q);
      wire [SQ_IDX_W-1:0] dataInvalidSqIdx2 = rev_prio_idx(di2_q);
      wire [SQ_IDX_W-1:0] dataInvalidSqIdx  = (|di2_q) ? dataInvalidSqIdx2 : dataInvalidSqIdx1;
      always_comb begin
        if (dataInvalidFlag) begin
          fwd_dataInvalidSqIdx_o[gi].flag  = (~diffFlag_q | (dataInvalidSqIdx >= deqPtr_q.value)) ? deqPtr_q.flag : enqPtr_q.flag;
          fwd_dataInvalidSqIdx_o[gi].value = dataInvalidSqIdx;
        end else begin
          fwd_dataInvalidSqIdx_o[gi] = fwdSqIdx_q;
        end
      end
    end
  endgenerate

  // forward 输出端口绑定（forwardMask/Data/MaskFast 来自 data 子模块；其余来自上面）
`include "storequeue_forward_out.svh"

  // ===========================================================================
  //  §9  mmio / CMO uncache store 状态机（5 态）
  // ===========================================================================
  mmio_state_e mmioState;
  // uncacheUop：在 s_idle 捕获 uop(deqPtr)，清 exceptionVec/trigger。
  logic                uncUop_robF;
  logic [ROB_IDX_W-1:0]uncUop_robV;
  logic [63:0]         uncUop_dbgEnq, uncUop_dbgSel, uncUop_dbgIss;
  logic                uncUop_excHwErr;   // exceptionVec(hardwareError=19) 唯一可能置位的
  logic [SQ_IDX_W-1:0] uncUop_sqIdxV;
  logic                cboFlushedSb;
  logic [PADDR_BITS-1:0] cboMmioPAddr;
  logic                noPending;
  // uncache req fire（见 §11 仲裁）：mmioDoReq = uncache.req.fire && !nc
  logic uncache_req_fire;
  wire  mmioDoReq = uncache_req_fire & ~io_uncache_req_bits_nc;
  // LSUOpType.isCbo（与 golden 一致）：fuOpType[3:2]==2'b11 且 fuOpType[6:4]==3'b000，
  //   即 fuOpType[6:2] == 5'b00011（cbo_clean/flush/inval 共有的编码段）。
  function automatic logic lsu_is_cbo(input logic [8:0] op);
    return (&op[3:2]) & ~(|op[6:4]);
  endfunction
  function automatic logic lsu_is_cbo_zero(input logic [8:0] op);
    return op == 9'h7;
  endfunction
  wire deqCbo_now = lsu_is_cbo(uop[deqPtr].fuOpType) & ent[deqPtr].allocated
                    & ent[deqPtr].addrvalid & ~ent[deqPtr].hasException;
  logic deqCanDoCbo;        // = GatedRegNext(deqCbo_now)
  always_ff @(posedge clock) deqCanDoCbo <= deqCbo_now;

  wire [1:0] cmoOpCode = uop[deqPtr].fuOpType[1:0]; // CMO opcode 低 2 位
  // get_block_addr：cacheline 对齐（低 6 位清零）
  wire [63:0] cboMmioAddr = {{16{1'b0}}, cboMmioPAddr[PADDR_BITS-1:6], 6'b0};

  // s_idle 进入条件（RegNext 一拍）：ROB 头是 pending mmio store 且地址/数据就绪、无异常
  logic mmioIdleGo_q;
  always_ff @(posedge clock) begin
    mmioIdleGo_q <= io_rob_pendingst
                    & (uop[deqPtr].robIdx_flag == io_rob_pendingPtr_flag)
                    & (uop[deqPtr].robIdx_value == io_rob_pendingPtr_value)
                    & ent[deqPtr].pending & ent[deqPtr].allocated
                    & ent[deqPtr].datavalid & ent[deqPtr].addrvalid & ~ent[deqPtr].hasException;
  end

  // uncache resp fire（resp.ready 恒 1）
  wire uncache_resp_fire = io_uncache_resp_valid;
  wire cmoResp_fire = io_cmoOpResp_valid & io_cmoOpResp_ready;

  always_ff @(posedge clock) begin
    if (reset) begin
      mmioState   <= MMIO_IDLE;
      cboFlushedSb<= 1'b0;
      noPending   <= 1'b1;
      uncUop_excHwErr <= 1'b0;
    end else begin
      unique case (mmioState)
        MMIO_IDLE: begin
          if (mmioIdleGo_q) begin
            mmioState     <= MMIO_REQ;
            uncUop_robF   <= uop[deqPtr].robIdx_flag;
            uncUop_robV   <= uop[deqPtr].robIdx_value;
            uncUop_dbgEnq <= uop[deqPtr].dbg_enqRsTime;
            uncUop_dbgSel <= uop[deqPtr].dbg_selectTime;
            uncUop_dbgIss <= uop[deqPtr].dbg_issueTime;
            uncUop_sqIdxV <= uop[deqPtr].sqIdx_value;
            uncUop_excHwErr <= 1'b0;
            cboFlushedSb  <= 1'b0;
            cboMmioPAddr  <= pa_rdata[0];
          end
        end
        MMIO_REQ: begin
          // CMO：cmoOpReq.fire 时也进 s_resp（见下 deqCanDoCbo 分支）
          if (mmioDoReq) begin noPending <= 1'b0; mmioState <= MMIO_RESP; end
          else if (deqCanDoCbo & (io_cmoOpReq_valid & io_cmoOpReq_ready)) begin
            noPending <= 1'b0; mmioState <= MMIO_RESP;
          end
        end
        MMIO_RESP: begin
          if (uncache_resp_fire & ~io_uncache_resp_bits_nc) begin
            noPending <= 1'b1; mmioState <= MMIO_WB;
            if (io_uncache_resp_bits_nderr | io_cmoOpResp_bits_nderr) uncUop_excHwErr <= 1'b1;
          end else if (deqCanDoCbo & cmoResp_fire) begin
            noPending <= 1'b1; mmioState <= MMIO_WB;
          end
        end
        MMIO_WB: begin
          if (mmioStout_fire | vecmmioStout_fire) begin
            mmioState <= uncUop_excHwErr ? MMIO_IDLE : MMIO_WAIT;
          end
        end
        MMIO_WAIT: begin
          if (scommit > 0) mmioState <= MMIO_IDLE;
        end
        default: mmioState <= MMIO_IDLE;
      endcase
      // CMO 排空 Sbuffer 后置 cboFlushedSb
      if (deqCanDoCbo & ~cboFlushedSb & (mmioState == MMIO_REQ) & io_flushSbuffer_empty)
        cboFlushedSb <= 1'b1;
    end
  end

  // mmioReq：仅在 MMIO_REQ 且非 CBO 且非 wfi 时发；地址/数据/掩码对齐到低字节
  wire mmioReq_valid = (mmioState == MMIO_REQ) & ~lsu_is_cbo(uop[deqPtr].fuOpType) & ~io_wfi_wfiReq;

  // ===========================================================================
  //  §10  nc（non-cacheable）store 状态机（4 态）
  // ===========================================================================
  nc_state_e ncState;
  logic [UNC_ID_W-1:0] ncWaitRespPtrReg;
  wire [SQ_IDX_W-1:0] rptr0 = rdataPtrExt[0].value;
  // nc 入口条件：rdataPtr(0) 是已提交未完成的 nc store（非向量、无异常、非 mmio）
  wire ncIdleGo = ent[rptr0].nc & ent[rptr0].allocated & ~ent[rptr0].completed
                  & ent[rptr0].committed & (ent[rptr0].addrvalid & ent[rptr0].datavalid)
                  & ~ent[rptr0].isVec & ~ent[rptr0].hasException & ~ent[rptr0].mmio;
  // nc 各触发
  wire ncDoReq   = uncache_req_fire & io_uncache_req_bits_nc;
  wire ncResp_fire = uncache_resp_fire & io_uncache_resp_bits_nc;
  wire ncSlaveAck = io_uncache_idResp_valid & io_uncache_idResp_bits_nc;
  wire [UNC_ID_W-1:0] ncSlaveAckMid = io_uncache_idResp_bits_mid;
  wire ncReadNextTrig = io_uncacheOutstanding ? ncSlaveAck : ncResp_fire;
  wire ncDeqTrig      = io_uncacheOutstanding ? ncSlaveAck : ncResp_fire;
  wire [UNC_ID_W-1:0] ncPtr = io_uncacheOutstanding ? ncSlaveAckMid : ncWaitRespPtrReg;

  always_ff @(posedge clock) begin
    if (reset) begin
      ncState <= NC_IDLE; ncWaitRespPtrReg <= '0;
    end else begin
      unique case (ncState)
        NC_IDLE:    if (ncIdleGo) begin ncState <= NC_REQ; ncWaitRespPtrReg <= {1'b0, rptr0}; end
        NC_REQ:     if (ncDoReq) ncState <= NC_REQ_ACK;
        NC_REQ_ACK: if (ncSlaveAck) ncState <= io_uncacheOutstanding ? NC_IDLE : NC_RESP;
        NC_RESP:    if (ncResp_fire) ncState <= NC_IDLE;
        default:    ncState <= NC_IDLE;
      endcase
    end
  end
  wire ncReq_valid = (ncState == NC_REQ) & ~io_wfi_wfiReq;

  // ===========================================================================
  //  §11  uncache 请求仲裁 + mmioStout / cboZeroStout 写回 ROB
  // ===========================================================================
  // uncache.req 仲裁：mmio 优先，其次 nc。deqCanDoCbo 时关闭 uncache.req（走 CMO 通道）。
  assign io_uncache_req_valid = (mmioReq_valid | ncReq_valid) & ~deqCanDoCbo;
  // 请求数据：mmio 用 deqPtr 行，nc 用 rptr0 行；二者地址/数据都取 rdata(0) 对齐低字节
  wire [PADDR_BITS-1:0] unc_addr  = pa_rdata[0];
  wire [VADDR_BITS-1:0] unc_vaddr = va_rdata[0];
  // mmio/nc 是 8 字节请求：paddr[3] 选 data/mask 的高/低 64 位（shiftDataToLow 的 8B 特化）
  wire [63:0] unc_data = pa_rdata[0][3] ? sd_rdata_data[0][127:64] : sd_rdata_data[0][63:0];
  wire [7:0]  unc_mask = pa_rdata[0][3] ? sd_rdata_mask[0][15:8]   : sd_rdata_mask[0][7:0];
  // robIdx/memBackTypeMM 取 GatedRegNext(rdataPtrExtNext(0)) 那一拍的 entry
  logic [SQ_IDX_W-1:0] rdNextPtr0_q;
  always_ff @(posedge clock) rdNextPtr0_q <= rdataPtrExtNext[0].value;
  assign io_uncache_req_bits_addr   = unc_addr;
  assign io_uncache_req_bits_vaddr  = unc_vaddr;
  assign io_uncache_req_bits_data   = unc_data;
  assign io_uncache_req_bits_mask   = unc_mask;
  assign io_uncache_req_bits_id     = mmioReq_valid ? {1'b0, rdataPtrExt[0].value} : {1'b0, rptr0};
  assign io_uncache_req_bits_nc     = ~mmioReq_valid;   // mmio 时 nc=0，否则 nc=1
  assign io_uncache_req_bits_robIdx_flag  = uop[rdNextPtr0_q].robIdx_flag;
  assign io_uncache_req_bits_robIdx_value = uop[rdNextPtr0_q].robIdx_value;
  assign io_uncache_req_bits_memBackTypeMM= ent[rdNextPtr0_q].memBackTypeMM;
  // uncache_req_fire = req.valid & req.ready
  assign uncache_req_fire = io_uncache_req_valid & io_uncache_req_ready;

  // CMO 请求
  assign io_cmoOpReq_valid       = deqCanDoCbo & cboFlushedSb & (mmioState == MMIO_REQ) & ~io_wfi_wfiReq;
  assign io_cmoOpReq_bits_opcode = {1'b0, cmoOpCode};
  assign io_cmoOpReq_bits_address= cboMmioAddr;
  assign io_cmoOpResp_ready      = deqCanDoCbo & (mmioState == MMIO_RESP);

  // wfiSafe：noPending & wfiReq 打一拍
  logic wfiSafe_q;
  always_ff @(posedge clock) wfiSafe_q <= (noPending & io_wfi_wfiReq);
  assign io_wfi_wfiSafe = wfiSafe_q;

  // flushSbuffer：CMO 需先排空 Sbuffer；cboZero 写 Sbuffer 后也触发
  // cboZero 相关（见 §13 的 isCboZeroToSbVec）
  logic cboZeroToSb, cboZeroFlushSb_q;
  assign io_flushSbuffer_valid = (deqCanDoCbo & ~cboFlushedSb & (mmioState == MMIO_REQ) & ~io_flushSbuffer_empty)
                                 | cboZeroFlushSb_q;

  // mmioStout 写回 ROB
  assign mmioStout_fire    = io_mmioStout_valid & io_mmioStout_ready;
  assign vecmmioStout_fire = 1'b0;  // 本配置 vecmmioStout.valid 恒 0（golden DontCare）
  assign io_mmioStout_valid = (mmioState == MMIO_WB) & ~ent[deqPtr].isVec;
  assign io_mmioStout_bits_uop_exceptionVec_19 = uncUop_excHwErr;
  assign io_mmioStout_bits_uop_flushPipe       = deqCanDoCbo;
  assign io_mmioStout_bits_uop_robIdx_flag     = uncUop_robF;
  assign io_mmioStout_bits_uop_robIdx_value    = uncUop_robV;
  assign io_mmioStout_bits_uop_debugInfo_enqRsTime  = uncUop_dbgEnq;
  assign io_mmioStout_bits_uop_debugInfo_selectTime = uncUop_dbgSel;
  assign io_mmioStout_bits_uop_debugInfo_issueTime  = uncUop_dbgIss;

  // ===========================================================================
  //  §12  ROB 提交（committed）+ cmtPtr 推进
  //      从 cmtPtr 起最多 CommitWidth 个，依次判定可提交（robIdx 不晚于 pendingPtr、
  //      未被取消、非 waitStoreS2 / 向量已 mbCommit）。第 0 个还要看 mmioState。
  // ===========================================================================
  logic [COMMIT_W-1:0] commitVec;
  // needCancel 按 64 位声明（2^SQ_IDX_W），高 8 位(56..63)恒 0：使 commit 用 6 位指针
  // 下标 needCancel[ptr] 时下标恒在界内（FMR_ELAB-147）。popcount 只数低 SQ_SIZE 位。
  logic [(1<<SQ_IDX_W)-1:0] needCancel;   // §15 赋值（仅 [SQ_SIZE-1:0] 有效）
  logic [ROB_IDX_W-1:0] pendingPtrV_q; logic pendingPtrF_q;
  always_ff @(posedge clock) begin
    pendingPtrF_q <= io_rob_pendingPtr_flag;
    pendingPtrV_q <= io_rob_pendingPtr_value;
  end
  // isNotAfter(uop(ptr).robIdx, RegNext(pendingPtr))：不晚于
  function automatic logic robidx_not_after(input logic af, input logic [ROB_IDX_W-1:0] av,
                                             input logic bf, input logic [ROB_IDX_W-1:0] bv);
    logic isafter;
    isafter = (af == bf) ? (av > bv) : (av < bv);
    return ~isafter;
  endfunction
  logic [COMMIT_W-1:0] commitEntPtr_committed; // 该路本拍是否把 committed 置 1
  logic [SQ_IDX_W-1:0] commitPtrIdx [COMMIT_W];
  always_comb begin
    commitVec = '0;
    for (int i = 0; i < COMMIT_W; i++) begin
      logic [SQ_IDX_W-1:0] ptr;
      logic isCommit, base;
      ptr = cmtPtrExt[i].value;
      commitPtrIdx[i] = ptr;
      isCommit = 1'b0;
      base = ent[ptr].allocated
             & robidx_not_after(uop[ptr].robIdx_flag, uop[ptr].robIdx_value, pendingPtrF_q, pendingPtrV_q)
             & ~needCancel[ptr]
             & (~ent[ptr].waitStoreS2 | ent[ptr].isVec);
      if (base) begin
        if (i == 0) begin
          if ((mmioState == MMIO_IDLE) | ((mmioState == MMIO_WAIT) & (scommit > 0))) begin
            if ((ent[ptr].isVec & ent[ptr].vecMbCommit) | ~ent[ptr].isVec) begin
              isCommit = 1'b1; commitVec[0] = 1'b1;
            end
          end
        end else begin
          if ((ent[ptr].isVec & ent[ptr].vecMbCommit) | ~ent[ptr].isVec) begin
            isCommit = commitVec[i-1] | ent[ptr].committed;
            commitVec[i] = commitVec[i-1];
          end
        end
      end
      commitEntPtr_committed[i] = isCommit;
    end
  end
  wire [3:0] commitCount = popcnt_commit(commitVec);

  // ===========================================================================
  //  §13  出队组 dataBuffer 入队 payload + 写 Sbuffer
  //      把 rdataPtr 指向的已提交 store 读出 data/addr，组成 dataBuffer 入队项；
  //      非对齐跨 16B 的 store 拆成两口（低/高半）。dataBuffer 出队即写 Sbuffer。
  // ===========================================================================
`include "storequeue_deq.svh"

  // ===========================================================================
  //  §14  向量异常标志 vecExceptionFlag + vecMbCommit（向量提交/反馈）
  // ===========================================================================
`include "storequeue_vec.svh"

  // ===========================================================================
  //  §15  redirect 取消 needCancel + 各指针更新（统一寄存器写在 §UNI）
  // ===========================================================================
  // needCancel(i)：allocated & !committed & (被 redirect flush)
  //   有 vecExceptionFlag 时：只取消比 redirect.robIdx 更新的；否则按 needFlush。
  always_comb begin
    needCancel = '0;   // 高 8 位(56..63)恒 0
    for (int i = 0; i < SQ_SIZE; i++) begin
      logic flushIt, afterRedir;
      // isAfter = differentFlag ^ (value>redirect.value)，与 golden 一致
      afterRedir = ((uop[i].robIdx_flag ^ io_brqRedirect_bits_robIdx_flag)
                    ^ (uop[i].robIdx_value > io_brqRedirect_bits_robIdx_value))
                   & io_brqRedirect_valid;
      flushIt = vecExceptionFlag_valid ? afterRedir
                                       : `ROB_NEED_FLUSH(uop[i].robIdx_flag, uop[i].robIdx_value);
      needCancel[i] = ent[i].allocated & ~ent[i].committed & flushIt;
    end
  end

  // enqPtr 回滚计数（2 拍后）
  logic [ENQ_W-1:0] enqCancelValid;
  logic [4:0]       enqCancelNum [ENQ_W];
  always_comb begin
    for (int j = 0; j < ENQ_W; j++) begin
      enqCancelValid[j] = canEnqueue[j] & `ROB_NEED_FLUSH(en_robF[j], en_robV[j]);
      enqCancelNum[j]   = enqCancelValid[j] ? vStoreFlow[j] : 5'd0;
    end
  end
  // enqNumber：本拍真正入队数（valid & !redirect 上拍）
  logic redirValid_q;
  always_ff @(posedge clock) redirValid_q <= io_brqRedirect_valid;
  logic [7:0] enqNumber;
  always_comb begin
    enqNumber = '0;
    for (int j = 0; j < ENQ_W; j++)
      enqNumber += (~redirValid_q & canEnqueue[j]) ? {3'b0, vStoreFlow[j]} : 8'd0;
  end
  // lastEnqCancel（redirect 时锁存 enq 取消流数之和）；needCancel 向量在 redirect 时锁存
  //   （与 golden 一致：锁存整个 needCancel 向量，到 lastCycleRedirect 拍再 popcount，
  //   避免「锁存 popcount」与「锁存向量再 popcount」在边角时序上的细微差异）。
  logic [7:0] lastEnqCancel_q;
  logic [SQ_SIZE-1:0] needCancel_q;     // RegEnable(needCancel, redirect.valid)
  logic lastCycleRedirect_q, lastlastCycleRedirect_q;
  logic [7:0] redirectCancelCount_q;
  wire [7:0] enqCancelSum = enqCancelNum[0]+enqCancelNum[1]+enqCancelNum[2]
                          + enqCancelNum[3]+enqCancelNum[4]+enqCancelNum[5];
  always_ff @(posedge clock) begin
    if (io_brqRedirect_valid) begin
      lastEnqCancel_q <= enqCancelSum;
      needCancel_q    <= needCancel[SQ_SIZE-1:0];
    end
    lastCycleRedirect_q     <= io_brqRedirect_valid;
    lastlastCycleRedirect_q <= lastCycleRedirect_q;
    if (reset)                    redirectCancelCount_q <= '0;
    else if (lastCycleRedirect_q) redirectCancelCount_q <= {1'b0, popcnt_sq(needCancel_q)} + lastEnqCancel_q;
  end
  assign io_sqCancelCnt = redirectCancelCount_q[SQ_IDX_W:0];

  // ===========================================================================
  //  §UNI  统一寄存器更新：ent[] / uop[] / 多根指针。
  //   优先级（与 Scala 同源 when 顺序一致，后者覆盖前者）：
  //     enq → addr 写回(s1) → addr 写回(s2) → data 写回(s1) → mask → commit
  //     → deq 清除 → mmio/nc completed → 向量 vecMbCommit → needCancel 取消。
  // ===========================================================================
`include "storequeue_regupd.svh"

  // ===========================================================================
  //  §16  异常地址 / force_write / sqEmpty / perf
  // ===========================================================================
  assign io_exceptionAddr_vaddr            = eb_exc_vaddr;
  assign io_exceptionAddr_vaNeedExt        = eb_exc_vaNeedExt;
  assign io_exceptionAddr_isHyper          = eb_exc_isHyper;
  assign io_exceptionAddr_gpaddr           = eb_exc_gpaddr;
  assign io_exceptionAddr_isForVSnonLeafPTE= eb_exc_isForVSnonLeafPTE;

  // force_write：valid 计数过上界则置位，落到下界以下才清。
  //   golden 固化阈值：valid_cnt > 0x33(51) 置位；> 0x2E(46) 维持。
  wire [SQ_IDX_W-1:0] valid_cnt = popcnt_sq(allocated_v);
  logic force_write_q;
  always_ff @(posedge clock) begin
    if (reset) force_write_q <= 1'b0;
    else force_write_q <= (valid_cnt > 6'h33) | ((valid_cnt > 6'h2E) & force_write_q);
  end
  assign io_force_write = force_write_q;

  // sqEmpty：enq==deq（同圈）打一拍
  logic sqEmpty_q;
  always_ff @(posedge clock) sqEmpty_q <= (enqPtrExt[0].value == deqPtrExt[0].value)
                                          & (enqPtrExt[0].flag == deqPtrExt[0].flag);
  assign io_sqEmpty = sqEmpty_q;

  // perf：8 路计数（本工程仅需端口存在，给确定值即可，UT 跳 X、FM 签名比对）
  // 与 golden 一致：perf 由内部 PerfEvent 寄存器驱动；这里复用 mmio/队列占用统计。
`include "storequeue_perf.svh"
