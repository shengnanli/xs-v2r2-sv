// =============================================================================
//  storequeue_deq.svh —— §13 出队组 dataBuffer 入队 payload + 写 Sbuffer
//   把 rdataPtr 指向的已提交 store 读出 data/addr 组成 dataBuffer 入队项；非对齐
//   跨 16B 的首条 store 拆成低/高两口写入。dataBuffer 出队直接接 io_sbuffer。
// =============================================================================

  // 两口都能进 dataBuffer 才允许出队非对齐 store
  wire canDeqMisaligned   = db_enq_ready[0] & db_enq_ready[1];
  wire firstWithMisalign  = entR[rdataPtrExt[0].value].unaligned;
  wire firstWithCross16B   = entR[rdataPtrExt[0].value].cross16Byte;

  // 跨 4K 页（来自 misalign buffer 控制）
  wire isCross4KPage      = io_maControl_toStoreQueue_crossPageWithHit;
  wire isCross4KPageCanDeq= io_maControl_toStoreQueue_crossPageCanDeq;

  // toStoreMisalignBuffer：把 rdataPtr(0) 的 sqPtr/uop 送出，doDeq 在跨页且首口 fire 时
  assign io_maControl_toStoreMisalignBuffer_sqPtr_flag  = rdataPtrExt[0].flag;
  assign io_maControl_toStoreMisalignBuffer_sqPtr_value = rdataPtrExt[0].value;
  assign io_maControl_toStoreMisalignBuffer_doDeq       = isCross4KPage & isCross4KPageCanDeq & db_enq0_fire;
  assign io_maControl_toStoreMisalignBuffer_uop_uopIdx     = uopR[rdataPtrExt[0].value].uopIdx;
  assign io_maControl_toStoreMisalignBuffer_uop_robIdx_flag= uopR[rdataPtrExt[0].value].robIdx_flag;
  assign io_maControl_toStoreMisalignBuffer_uop_robIdx_value=uopR[rdataPtrExt[0].value].robIdx_value;

  // 首条非对齐跨 16B 拆分后的低/高半 mask/data（按 vaddr 低 4 位移位）
  wire [3:0] cross16ByteAddrLow4 = va_rdata[0][3:0];
  wire [31:0]  Cross16ByteMask = {16'b0, sd_rdata_mask[0]} << cross16ByteAddrLow4;
  // golden: << {vaddr[3:0], 3'h0}（= addrLow4*8 的拼接，宽度足、不截断）。
  //   之前 `({1'b0,addrLow4}<<3)` 的移位量表达式只有 5 位，addrLow4>=4 时 *8>=32 溢出被截断
  //   → 与 golden 分叉。改用拼接。
  wire [255:0] Cross16ByteData = {128'b0, sd_rdata_data[0]} << {cross16ByteAddrLow4, 3'b0};
  wire [PADDR_BITS-1:0] paddrLow  = {pa_rdata[0][PADDR_BITS-1:3], 3'b0};
  wire [PADDR_BITS-1:0] paddrHigh = {pa_rdata[0][PADDR_BITS-1:3], 3'b0} + 48'h8;
  wire [VADDR_BITS-1:0] vaddrLow  = {va_rdata[0][VADDR_BITS-1:3], 3'b0};
  wire [VADDR_BITS-1:0] vaddrHigh = {va_rdata[0][VADDR_BITS-1:3], 3'b0} + 50'h8;
  wire [VLEN_BYTES-1:0] maskLow   = Cross16ByteMask[15:0];
  wire [VLEN_BYTES-1:0] maskHigh  = Cross16ByteMask[31:16];
  wire [VLEN-1:0]  dataLow        = Cross16ByteData[127:0];
  wire [VLEN-1:0]  dataHigh       = Cross16ByteData[255:128];

  // 每口出队判定与 payload：用 generate 展开 2 口
  // mmioStall/ncStall/exceptionValid（第 1 口要看第 0 口）
  wire mmio0 = entR[rdataPtrExt[0].value].mmio;
  wire mmio1 = entR[rdataPtrExt[1].value].mmio;
  wire nc0   = entR[rdataPtrExt[0].value].nc;
  wire nc1   = entR[rdataPtrExt[1].value].nc;
  wire mmioStall0 = mmio0;
  wire mmioStall1 = mmio1 | mmio0;
  wire ncStall0   = nc0;
  wire ncStall1   = nc1 | nc0;
  wire exc0 = entR[rdataPtrExt[0].value].hasException;
  // golden 的口 1 异常仅取 hasException[dp1]（_dataBuffer_io_enq_1_valid_T_12 = allvalid|hasException，
  // 无「dp1 继承 dp0 同 robIdx 异常」项）。此前 impl 多了 robIdx 继承 → 把 uop.robIdx 引入
  // dataBuffer enq 锥，FM 判 uop_N_robIdx 在 impl 锥、ref 锥没有（171/134 点失配根因）。
  // 移除以位级对齐 golden。
  wire exc1 = entR[rdataPtrExt[1].value].hasException;

  // vecHasExceptionFlagValid（第 i 口）：向量异常标志命中该 entry 的 robIdx
  // toSbufferVecValid（第 i 口）：是否真正写 Sbuffer 的字节有效
  wire firstSplit = canDeqMisaligned & firstWithMisalign & firstWithCross16B;

  // 第 0 口
  wire [SQ_IDX_W-1:0] dp0 = rdataPtrExt[0].value;
  wire vec0   = entR[dp0].isVec;
  wire vecMb0 = entR[dp0].vecMbCommit;
  wire allv0  = entR[dp0].addrvalid & entR[dp0].datavalid;
  wire vecNotAllMask0 = |sd_rdata_mask[0];
  wire vecHasExcFlag0 = vecExceptionFlag_valid & vec0
                        & (vecExceptionFlag_robIdx_flag == uopR[dp0].robIdx_flag)
                        & (vecExceptionFlag_robIdx_value == uopR[dp0].robIdx_value);
  wire toSbufferVecValid0 = (~vec0 | (vecMb0 & allv0 & vecNotAllMask0)) & ~exc0 & ~vecHasExcFlag0;
  // misalignToDataBufferValid（首条非对齐跨 16B 的合法出队）
  wire misalignToDataBufferValid = entR[dp0].allocated & entR[dp0].committed
        & ((~vec0 & allv0) | vecMb0)
        & canDeqMisaligned & (~isCross4KPage | isCross4KPageCanDeq | exc0);

  // 第 1 口
  wire [SQ_IDX_W-1:0] dp1 = rdataPtrExt[1].value;
  wire vec1   = entR[dp1].isVec;
  wire vecMb1 = entR[dp1].vecMbCommit;
  wire allv1  = entR[dp1].addrvalid & entR[dp1].datavalid;
  wire vecNotAllMask1 = |sd_rdata_mask[1];
  wire vecHasExcFlag1 = vecExceptionFlag_valid & vec1
                        & (vecExceptionFlag_robIdx_flag == uopR[dp1].robIdx_flag)
                        & (vecExceptionFlag_robIdx_value == uopR[dp1].robIdx_value);
  wire toSbufferVecValid1 = (~vec1 | (vecMb1 & allv1 & vecNotAllMask1)) & ~exc1 & ~vecHasExcFlag1;

  wire [3:0] addrLow4_0 = va_rdata[0][3:0];
  wire [3:0] addrLow4_1 = va_rdata[1][3:0];

  // ---- 第 0 口 valid + payload ----
  always_comb begin
    // valid
    if (firstWithMisalign & firstWithCross16B)
      db_enq_0_valid = misalignToDataBufferValid;
    else
      db_enq_0_valid = entR[dp0].allocated & entR[dp0].committed
            & ((~vec0 & (allv0 | exc0)) | vecMb0)
            & ~mmioStall0 & ~ncStall0
            & (~entR[dp0].unaligned | (~entR[dp0].cross16Byte & (allv0 | exc0)));
    // payload
    if (canDeqMisaligned & firstWithMisalign & firstWithCross16B) begin
      // 首条非对齐跨 16B → 低半（口 0 永远走 paddrLow）
      db_enq_0_bits_addr  = paddrLow;
      db_enq_0_bits_vaddr = vaddrLow;
      db_enq_0_bits_data  = dataLow;
      db_enq_0_bits_mask  = maskLow;
      db_enq_0_bits_wline = 1'b0;
      db_enq_0_bits_sqPtr_value = rdataPtrExt[0].value;
      db_enq_0_bits_vecValid    = toSbufferVecValid0;
    end else if (~entR[dp0].cross16Byte & entR[dp0].unaligned) begin
      // 非对齐但不跨 16B → 整体右移对齐（按 vaddr 低 4 位清零基址）
      db_enq_0_bits_addr  = {pa_rdata[0][PADDR_BITS-1:4], 4'b0};
      db_enq_0_bits_vaddr = {va_rdata[0][VADDR_BITS-1:4], 4'b0};
      db_enq_0_bits_data  = sd_rdata_data[0] << {addrLow4_0, 3'b0};
      db_enq_0_bits_mask  = sd_rdata_mask[0];
      db_enq_0_bits_wline = pa_rlineflag[0];
      db_enq_0_bits_sqPtr_value = rdataPtrExt[0].value;
      db_enq_0_bits_vecValid    = toSbufferVecValid0;
    end else begin
      // 对齐 store：原样
      db_enq_0_bits_addr  = pa_rdata[0];
      db_enq_0_bits_vaddr = va_rdata[0];
      db_enq_0_bits_data  = sd_rdata_data[0];
      db_enq_0_bits_mask  = sd_rdata_mask[0];
      db_enq_0_bits_wline = pa_rlineflag[0];
      db_enq_0_bits_sqPtr_value = rdataPtrExt[0].value;
      db_enq_0_bits_vecValid    = toSbufferVecValid0;
    end
  end

  // ---- 第 1 口 valid + payload ----
  always_comb begin
    if (firstWithMisalign & firstWithCross16B)
      db_enq_1_valid = misalignToDataBufferValid;
    else
      db_enq_1_valid = entR[dp1].allocated & entR[dp1].committed
            & ((~vec1 & (allv1 | exc1)) | vecMb1)
            & ~mmioStall1 & ~ncStall1
            & (~entR[dp1].unaligned | (~entR[dp1].cross16Byte & (allv1 | exc1)));
    if (canDeqMisaligned & firstWithMisalign & firstWithCross16B) begin
      // 首条非对齐跨 16B 的高半（口 1）；跨 4K 页时高半地址来自 misalign buffer
      db_enq_1_bits_addr  = (isCross4KPage & isCross4KPageCanDeq) ? io_maControl_toStoreQueue_paddr : paddrHigh;
      db_enq_1_bits_vaddr = vaddrHigh;
      db_enq_1_bits_data  = dataHigh;
      db_enq_1_bits_mask  = maskHigh;
      db_enq_1_bits_wline = 1'b0;
      db_enq_1_bits_sqPtr_value = rdataPtrExt[0].value;   // 同首条 sqPtr
      db_enq_1_bits_vecValid    = db_enq_0_bits_vecValid; // 跟随口 0
      db_enq_1_bits_sqNeedDeq   = 1'b0;                   // 高半不推进 deq（首条只 deq 一次）
    end else if (~entR[dp1].cross16Byte & entR[dp1].unaligned) begin
      db_enq_1_bits_addr  = {pa_rdata[1][PADDR_BITS-1:4], 4'b0};
      db_enq_1_bits_vaddr = {va_rdata[1][VADDR_BITS-1:4], 4'b0};
      db_enq_1_bits_data  = sd_rdata_data[1] << {addrLow4_1, 3'b0};
      db_enq_1_bits_mask  = sd_rdata_mask[1];
      db_enq_1_bits_wline = pa_rlineflag[1];
      db_enq_1_bits_sqPtr_value = rdataPtrExt[1].value;
      db_enq_1_bits_vecValid    = toSbufferVecValid1;
      db_enq_1_bits_sqNeedDeq   = 1'b1;
    end else begin
      db_enq_1_bits_addr  = pa_rdata[1];
      db_enq_1_bits_vaddr = va_rdata[1];
      db_enq_1_bits_data  = sd_rdata_data[1];
      db_enq_1_bits_mask  = sd_rdata_mask[1];
      db_enq_1_bits_wline = pa_rlineflag[1];
      db_enq_1_bits_sqPtr_value = rdataPtrExt[1].value;
      db_enq_1_bits_vecValid    = toSbufferVecValid1;
      db_enq_1_bits_sqNeedDeq   = 1'b1;
    end
  end

  // dataBuffer 出队 → Sbuffer（直通）
  assign io_sbuffer_0_valid       = db_deq_0_valid;
  assign io_sbuffer_0_bits_addr   = db_deq_0_bits_addr;
  assign io_sbuffer_0_bits_vaddr  = db_deq_0_bits_vaddr;
  assign io_sbuffer_0_bits_data   = db_deq_0_bits_data;
  assign io_sbuffer_0_bits_mask   = db_deq_0_bits_mask;
  // golden: io_sbuffer_0_bits_wline = deq_0_wline & deq_0_vecValid（wline 需 vecValid 门控）。
  assign io_sbuffer_0_bits_wline  = db_deq_0_bits_wline & db_deq_0_bits_vecValid;
  assign io_sbuffer_0_bits_vecValid = db_deq_0_bits_vecValid;
  assign io_sbuffer_1_valid       = db_deq_1_valid;
  assign io_sbuffer_1_bits_addr   = db_deq_1_bits_addr;
  assign io_sbuffer_1_bits_vaddr  = db_deq_1_bits_vaddr;
  assign io_sbuffer_1_bits_data   = db_deq_1_bits_data;
  assign io_sbuffer_1_bits_mask   = db_deq_1_bits_mask;
  assign io_sbuffer_1_bits_wline  = db_deq_1_bits_wline & db_deq_1_bits_vecValid;
  assign io_sbuffer_1_bits_vecValid = db_deq_1_bits_vecValid;
  wire sbuffer0_fire = io_sbuffer_0_valid & io_sbuffer_0_ready;
  wire sbuffer1_fire = io_sbuffer_1_valid & io_sbuffer_1_ready;

  // cbo zero 写 Sbuffer 检测（RegNext(sbuffer.fire & vecValid & wline) & allocated(deqPtr(i))）
  logic sbuf0_fire_q, sbuf1_fire_q;
  logic sbuf0_vw_q, sbuf1_vw_q;
  always_ff @(posedge clock) begin
    sbuf0_fire_q <= sbuffer0_fire & db_deq_0_bits_vecValid & db_deq_0_bits_wline;
    sbuf1_fire_q <= sbuffer1_fire & db_deq_1_bits_vecValid & db_deq_1_bits_wline;
  end
  wire [1:0] isCboZeroToSbVec = {sbuf1_fire_q & entR[deqPtrExt[1].value].allocated,
                                 sbuf0_fire_q & entR[deqPtrExt[0].value].allocated};
  assign cboZeroToSb = |isCboZeroToSbVec;
  // golden cboZeroFlushSb_next_r 异步复位到 0（reg block 行 50858）——补复位，消 FM 锥不对称。
  always_ff @(posedge clock or posedge reset)
    if (reset) cboZeroFlushSb_q <= 1'b0;
    else       cboZeroFlushSb_q <= cboZeroToSb;

  // cboZero 写回 ROB（cboZeroStout）
  // 捕获 cboZeroUop / sqIdx
  logic                cbz_robF;  logic [ROB_IDX_W-1:0] cbz_robV;
  logic                cbz_flushPipe; logic [3:0] cbz_trigger;
  logic [23:0]         cbz_excVec;
  logic [63:0]         cbz_dbgEnq, cbz_dbgSel, cbz_dbgIss;
  logic                cboZeroValid, cboZeroWaitFlushSb;
  // ---- 复位寄存器（golden 有 reset）：cboZeroValid / cboZeroWaitFlushSb ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin cboZeroValid <= 1'b0; cboZeroWaitFlushSb <= 1'b0; end
    else begin
      if (cboZeroToSb) begin
        cboZeroValid <= 1'b1; cboZeroWaitFlushSb <= 1'b1;
      end
      if (cboZeroWaitFlushSb & io_flushSbuffer_empty) cboZeroWaitFlushSb <= 1'b0;
      if (io_cboZeroStout_valid & io_cboZeroStout_ready) cboZeroValid <= 1'b0;
    end
  end

  // ---- cboZeroUop payload 锁存：**无复位**（golden always @(posedge clock)，行 17777 块）。
  //      写条件 cboZeroToSb 与上一致；PriorityMux(isCboZeroToSbVec, deqPtr.map(uop))。
  //      拆离 reset 块以消除 async-reset 进入 FM 锥的两侧不对称（uncacheUop/cboZeroUop
  //      debugInfo / exceptionVec / robIdx / trigger 大批失配根因）。----
  always_ff @(posedge clock) begin
    if (cboZeroToSb) begin
      if (isCboZeroToSbVec[0]) begin
        cbz_robF <= uopR[deqPtrExt[0].value].robIdx_flag;
        cbz_robV <= uopR[deqPtrExt[0].value].robIdx_value;
        cbz_flushPipe <= uopR[deqPtrExt[0].value].flushPipe;
        cbz_trigger   <= uopR[deqPtrExt[0].value].trigger;
        cbz_excVec    <= uopR[deqPtrExt[0].value].exceptionVec;
        cbz_dbgEnq <= uopR[deqPtrExt[0].value].dbg_enqRsTime;
        cbz_dbgSel <= uopR[deqPtrExt[0].value].dbg_selectTime;
        cbz_dbgIss <= uopR[deqPtrExt[0].value].dbg_issueTime;
      end else begin
        cbz_robF <= uopR[deqPtrExt[1].value].robIdx_flag;
        cbz_robV <= uopR[deqPtrExt[1].value].robIdx_value;
        cbz_flushPipe <= uopR[deqPtrExt[1].value].flushPipe;
        cbz_trigger   <= uopR[deqPtrExt[1].value].trigger;
        cbz_excVec    <= uopR[deqPtrExt[1].value].exceptionVec;
        cbz_dbgEnq <= uopR[deqPtrExt[1].value].dbg_enqRsTime;
        cbz_dbgSel <= uopR[deqPtrExt[1].value].dbg_selectTime;
        cbz_dbgIss <= uopR[deqPtrExt[1].value].dbg_issueTime;
      end
    end
  end
  assign io_cboZeroStout_valid = cboZeroValid & ~cboZeroWaitFlushSb;
  assign io_cboZeroStout_bits_uop_flushPipe    = cbz_flushPipe;
  assign io_cboZeroStout_bits_uop_trigger      = cbz_trigger;
  assign io_cboZeroStout_bits_uop_robIdx_flag  = cbz_robF;
  assign io_cboZeroStout_bits_uop_robIdx_value = cbz_robV;
  assign io_cboZeroStout_bits_uop_debugInfo_enqRsTime  = cbz_dbgEnq;
  assign io_cboZeroStout_bits_uop_debugInfo_selectTime = cbz_dbgSel;
  assign io_cboZeroStout_bits_uop_debugInfo_issueTime  = cbz_dbgIss;
  // cboZeroStout exceptionVec：golden 从 per-entry uop.exceptionVec 经 cboZeroUop 寄存后上报
  `define SQ_CBZ_EV(I) assign io_cboZeroStout_bits_uop_exceptionVec_``I = cbz_excVec[I];
  `SQ_CBZ_EV(0) `SQ_CBZ_EV(1) `SQ_CBZ_EV(2) `SQ_CBZ_EV(3) `SQ_CBZ_EV(4) `SQ_CBZ_EV(5)
  `SQ_CBZ_EV(6) `SQ_CBZ_EV(7) `SQ_CBZ_EV(8) `SQ_CBZ_EV(9) `SQ_CBZ_EV(10) `SQ_CBZ_EV(11)
  `SQ_CBZ_EV(12) `SQ_CBZ_EV(13) `SQ_CBZ_EV(14) `SQ_CBZ_EV(15) `SQ_CBZ_EV(16) `SQ_CBZ_EV(17)
  `SQ_CBZ_EV(18) `SQ_CBZ_EV(19) `SQ_CBZ_EV(20) `SQ_CBZ_EV(21) `SQ_CBZ_EV(22) `SQ_CBZ_EV(23)
  `undef SQ_CBZ_EV
