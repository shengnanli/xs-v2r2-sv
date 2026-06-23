// 手写可读核 glue 时序逻辑(从 Backend.scala 设计意图重写,非 golden 转写)。
// 对应 golden Backend.sv 两个 always 块:
//   always @(posedge clock)               —— 全部 RegNext/RegEnable 打拍(无复位)
//   always @(posedge clock or posedge reset) —— vsetvlVType + issueTimeout 计数(带复位)
// 命名:golden inner_xxx 临时名已映射到核内 struct/具名信号(见 gen_backend.py)。
// =====================================================================

  // ---- 唤醒总线源别名(可读聚合):四调度器 wakeupVec 各路 ----
  // int 0..3, fp 0..2, mem 0..2 -> wakeupDelayed[0..9]。各路字段异构(并集取)。
  // 用 always_ff 逐路 RegNext;缺省字段(该路无)golden 不锁存,这里也不写(保持 0)。

  always_ff @(posedge clock) begin
    // ---- ① 唤醒打拍:int 调度器 wakeupVec 0..3 -> wakeupDelayed[0..3] ----
    wakeupDelayed[0].rfWen            <= _inner_intScheduler_io_toSchedulers_wakeupVec_0_bits_rfWen;
    wakeupDelayed[0].pdest            <= _inner_intScheduler_io_toSchedulers_wakeupVec_0_bits_pdest;
    wakeupDelayed[0].loadDependency_0 <= _inner_intScheduler_io_toSchedulers_wakeupVec_0_bits_loadDependency_0;
    wakeupDelayed[0].loadDependency_1 <= _inner_intScheduler_io_toSchedulers_wakeupVec_0_bits_loadDependency_1;
    wakeupDelayed[0].loadDependency_2 <= _inner_intScheduler_io_toSchedulers_wakeupVec_0_bits_loadDependency_2;
    wakeupDelayed[0].is0Lat           <= _inner_intScheduler_io_toSchedulers_wakeupVec_0_bits_is0Lat;
    wakeupDelayed[0].rcDest           <= _inner_intScheduler_io_toSchedulers_wakeupVec_0_bits_rcDest;
    wakeupDelayed[1].rfWen            <= _inner_intScheduler_io_toSchedulers_wakeupVec_1_bits_rfWen;
    wakeupDelayed[1].pdest            <= _inner_intScheduler_io_toSchedulers_wakeupVec_1_bits_pdest;
    wakeupDelayed[1].loadDependency_0 <= _inner_intScheduler_io_toSchedulers_wakeupVec_1_bits_loadDependency_0;
    wakeupDelayed[1].loadDependency_1 <= _inner_intScheduler_io_toSchedulers_wakeupVec_1_bits_loadDependency_1;
    wakeupDelayed[1].loadDependency_2 <= _inner_intScheduler_io_toSchedulers_wakeupVec_1_bits_loadDependency_2;
    wakeupDelayed[1].is0Lat           <= _inner_intScheduler_io_toSchedulers_wakeupVec_1_bits_is0Lat;
    wakeupDelayed[1].rcDest           <= _inner_intScheduler_io_toSchedulers_wakeupVec_1_bits_rcDest;
    wakeupDelayed[2].rfWen            <= _inner_intScheduler_io_toSchedulers_wakeupVec_2_bits_rfWen;
    wakeupDelayed[2].pdest            <= _inner_intScheduler_io_toSchedulers_wakeupVec_2_bits_pdest;
    wakeupDelayed[2].loadDependency_0 <= _inner_intScheduler_io_toSchedulers_wakeupVec_2_bits_loadDependency_0;
    wakeupDelayed[2].loadDependency_1 <= _inner_intScheduler_io_toSchedulers_wakeupVec_2_bits_loadDependency_1;
    wakeupDelayed[2].loadDependency_2 <= _inner_intScheduler_io_toSchedulers_wakeupVec_2_bits_loadDependency_2;
    wakeupDelayed[2].rcDest           <= _inner_intScheduler_io_toSchedulers_wakeupVec_2_bits_rcDest;
    wakeupDelayed[3].rfWen            <= _inner_intScheduler_io_toSchedulers_wakeupVec_3_bits_rfWen;
    wakeupDelayed[3].pdest            <= _inner_intScheduler_io_toSchedulers_wakeupVec_3_bits_pdest;
    wakeupDelayed[3].loadDependency_0 <= _inner_intScheduler_io_toSchedulers_wakeupVec_3_bits_loadDependency_0;
    wakeupDelayed[3].loadDependency_1 <= _inner_intScheduler_io_toSchedulers_wakeupVec_3_bits_loadDependency_1;
    wakeupDelayed[3].loadDependency_2 <= _inner_intScheduler_io_toSchedulers_wakeupVec_3_bits_loadDependency_2;
    wakeupDelayed[3].rcDest           <= _inner_intScheduler_io_toSchedulers_wakeupVec_3_bits_rcDest;
    // fp 调度器 wakeupVec 0..2 -> wakeupDelayed[4..6]
    wakeupDelayed[4].fpWen            <= _inner_fpScheduler_io_toSchedulers_wakeupVec_0_bits_fpWen;
    wakeupDelayed[4].pdest            <= _inner_fpScheduler_io_toSchedulers_wakeupVec_0_bits_pdest;
    wakeupDelayed[4].is0Lat           <= _inner_fpScheduler_io_toSchedulers_wakeupVec_0_bits_is0Lat;
    wakeupDelayed[5].fpWen            <= _inner_fpScheduler_io_toSchedulers_wakeupVec_1_bits_fpWen;
    wakeupDelayed[5].pdest            <= _inner_fpScheduler_io_toSchedulers_wakeupVec_1_bits_pdest;
    wakeupDelayed[6].fpWen            <= _inner_fpScheduler_io_toSchedulers_wakeupVec_2_bits_fpWen;
    wakeupDelayed[6].pdest            <= _inner_fpScheduler_io_toSchedulers_wakeupVec_2_bits_pdest;
    // mem 调度器 wakeupVec 0..2 -> wakeupDelayed[7..9]
    wakeupDelayed[7].rfWen            <= _inner_memScheduler_io_toSchedulers_wakeupVec_0_bits_rfWen;
    wakeupDelayed[7].fpWen            <= _inner_memScheduler_io_toSchedulers_wakeupVec_0_bits_fpWen;
    wakeupDelayed[7].pdest            <= _inner_memScheduler_io_toSchedulers_wakeupVec_0_bits_pdest;
    wakeupDelayed[7].rcDest           <= _inner_memScheduler_io_toSchedulers_wakeupVec_0_bits_rcDest;
    wakeupDelayed[8].rfWen            <= _inner_memScheduler_io_toSchedulers_wakeupVec_1_bits_rfWen;
    wakeupDelayed[8].fpWen            <= _inner_memScheduler_io_toSchedulers_wakeupVec_1_bits_fpWen;
    wakeupDelayed[8].pdest            <= _inner_memScheduler_io_toSchedulers_wakeupVec_1_bits_pdest;
    wakeupDelayed[8].rcDest           <= _inner_memScheduler_io_toSchedulers_wakeupVec_1_bits_rcDest;
    wakeupDelayed[9].rfWen            <= _inner_memScheduler_io_toSchedulers_wakeupVec_2_bits_rfWen;
    wakeupDelayed[9].fpWen            <= _inner_memScheduler_io_toSchedulers_wakeupVec_2_bits_fpWen;
    wakeupDelayed[9].pdest            <= _inner_memScheduler_io_toSchedulers_wakeupVec_2_bits_pdest;
    wakeupDelayed[9].rcDest           <= _inner_memScheduler_io_toSchedulers_wakeupVec_2_bits_rcDest;

    // ---- ③ CSR<->Mem 边界:instrAddrTransType RegNext ----
    instrTransTypeR.bare   <= _inner_intExuBlock_io_csrio_instrAddrTransType_bare;
    instrTransTypeR.sv39   <= _inner_intExuBlock_io_csrio_instrAddrTransType_sv39;
    instrTransTypeR.sv39x4 <= _inner_intExuBlock_io_csrio_instrAddrTransType_sv39x4;
    instrTransTypeR.sv48   <= _inner_intExuBlock_io_csrio_instrAddrTransType_sv48;
    instrTransTypeR.sv48x4 <= _inner_intExuBlock_io_csrio_instrAddrTransType_sv48x4;

    // ---- ② 写回打拍:int(0,1,2,4)/fp(0..5)/vf(0..5)/v0(0..5)/vl(0..3) ----
    //      wen/typeWen 走 RegNext;addr 走 RegEnable(by 该路 wbDataPath.wen)。
    intWbDelayed[0].wen     <= _inner_wbDataPath_io_toIntPreg_0_wen;
    intWbDelayed[0].typeWen <= _inner_wbDataPath_io_toIntPreg_0_intWen;
    if (_inner_wbDataPath_io_toIntPreg_0_wen) intWbDelayed[0].addr <= _inner_wbDataPath_io_toIntPreg_0_addr;
    intWbDelayed[1].wen     <= _inner_wbDataPath_io_toIntPreg_1_wen;
    intWbDelayed[1].typeWen <= _inner_wbDataPath_io_toIntPreg_1_intWen;
    if (_inner_wbDataPath_io_toIntPreg_1_wen) intWbDelayed[1].addr <= _inner_wbDataPath_io_toIntPreg_1_addr;
    intWbDelayed[2].wen     <= _inner_wbDataPath_io_toIntPreg_2_wen;
    intWbDelayed[2].typeWen <= _inner_wbDataPath_io_toIntPreg_2_intWen;
    if (_inner_wbDataPath_io_toIntPreg_2_wen) intWbDelayed[2].addr <= _inner_wbDataPath_io_toIntPreg_2_addr;
    intWbDelayed[4].wen     <= _inner_wbDataPath_io_toIntPreg_4_wen;
    intWbDelayed[4].typeWen <= _inner_wbDataPath_io_toIntPreg_4_intWen;
    if (_inner_wbDataPath_io_toIntPreg_4_wen) intWbDelayed[4].addr <= _inner_wbDataPath_io_toIntPreg_4_addr;

    fpWbDelayed[0].wen     <= _inner_wbDataPath_io_toFpPreg_0_wen;
    fpWbDelayed[0].typeWen <= _inner_wbDataPath_io_toFpPreg_0_fpWen;
    if (_inner_wbDataPath_io_toFpPreg_0_wen) fpWbDelayed[0].addr <= _inner_wbDataPath_io_toFpPreg_0_addr;
    fpWbDelayed[1].wen     <= _inner_wbDataPath_io_toFpPreg_1_wen;
    fpWbDelayed[1].typeWen <= _inner_wbDataPath_io_toFpPreg_1_fpWen;
    if (_inner_wbDataPath_io_toFpPreg_1_wen) fpWbDelayed[1].addr <= _inner_wbDataPath_io_toFpPreg_1_addr;
    fpWbDelayed[2].wen     <= _inner_wbDataPath_io_toFpPreg_2_wen;
    fpWbDelayed[2].typeWen <= _inner_wbDataPath_io_toFpPreg_2_fpWen;
    if (_inner_wbDataPath_io_toFpPreg_2_wen) fpWbDelayed[2].addr <= _inner_wbDataPath_io_toFpPreg_2_addr;
    fpWbDelayed[3].wen     <= _inner_wbDataPath_io_toFpPreg_3_wen;
    fpWbDelayed[3].typeWen <= _inner_wbDataPath_io_toFpPreg_3_fpWen;
    if (_inner_wbDataPath_io_toFpPreg_3_wen) fpWbDelayed[3].addr <= _inner_wbDataPath_io_toFpPreg_3_addr;
    fpWbDelayed[4].wen     <= _inner_wbDataPath_io_toFpPreg_4_wen;
    fpWbDelayed[4].typeWen <= _inner_wbDataPath_io_toFpPreg_4_fpWen;
    if (_inner_wbDataPath_io_toFpPreg_4_wen) fpWbDelayed[4].addr <= _inner_wbDataPath_io_toFpPreg_4_addr;
    fpWbDelayed[5].wen     <= _inner_wbDataPath_io_toFpPreg_5_wen;
    fpWbDelayed[5].typeWen <= _inner_wbDataPath_io_toFpPreg_5_fpWen;
    if (_inner_wbDataPath_io_toFpPreg_5_wen) fpWbDelayed[5].addr <= _inner_wbDataPath_io_toFpPreg_5_addr;

    vfWbDelayed[0].wen     <= _inner_wbDataPath_io_toVfPreg_0_wen;
    vfWbDelayed[0].typeWen <= _inner_wbDataPath_io_toVfPreg_0_vecWen;
    if (_inner_wbDataPath_io_toVfPreg_0_wen) vfWbDelayed[0].addr <= _inner_wbDataPath_io_toVfPreg_0_addr;
    vfWbDelayed[1].wen     <= _inner_wbDataPath_io_toVfPreg_1_wen;
    vfWbDelayed[1].typeWen <= _inner_wbDataPath_io_toVfPreg_1_vecWen;
    if (_inner_wbDataPath_io_toVfPreg_1_wen) vfWbDelayed[1].addr <= _inner_wbDataPath_io_toVfPreg_1_addr;
    vfWbDelayed[2].wen     <= _inner_wbDataPath_io_toVfPreg_2_wen;
    vfWbDelayed[2].typeWen <= _inner_wbDataPath_io_toVfPreg_2_vecWen;
    if (_inner_wbDataPath_io_toVfPreg_2_wen) vfWbDelayed[2].addr <= _inner_wbDataPath_io_toVfPreg_2_addr;
    vfWbDelayed[3].wen     <= _inner_wbDataPath_io_toVfPreg_3_wen;
    vfWbDelayed[3].typeWen <= _inner_wbDataPath_io_toVfPreg_3_vecWen;
    if (_inner_wbDataPath_io_toVfPreg_3_wen) vfWbDelayed[3].addr <= _inner_wbDataPath_io_toVfPreg_3_addr;
    vfWbDelayed[4].wen     <= _inner_wbDataPath_io_toVfPreg_4_wen;
    vfWbDelayed[4].typeWen <= _inner_wbDataPath_io_toVfPreg_4_vecWen;
    if (_inner_wbDataPath_io_toVfPreg_4_wen) vfWbDelayed[4].addr <= _inner_wbDataPath_io_toVfPreg_4_addr;
    vfWbDelayed[5].wen     <= _inner_wbDataPath_io_toVfPreg_5_wen;
    vfWbDelayed[5].typeWen <= _inner_wbDataPath_io_toVfPreg_5_vecWen;
    if (_inner_wbDataPath_io_toVfPreg_5_wen) vfWbDelayed[5].addr <= _inner_wbDataPath_io_toVfPreg_5_addr;

    v0WbDelayed[0].wen     <= _inner_wbDataPath_io_toV0Preg_0_wen;
    v0WbDelayed[0].typeWen <= _inner_wbDataPath_io_toV0Preg_0_v0Wen;
    if (_inner_wbDataPath_io_toV0Preg_0_wen) v0WbDelayed[0].addr <= _inner_wbDataPath_io_toV0Preg_0_addr;
    v0WbDelayed[1].wen     <= _inner_wbDataPath_io_toV0Preg_1_wen;
    v0WbDelayed[1].typeWen <= _inner_wbDataPath_io_toV0Preg_1_v0Wen;
    if (_inner_wbDataPath_io_toV0Preg_1_wen) v0WbDelayed[1].addr <= _inner_wbDataPath_io_toV0Preg_1_addr;
    v0WbDelayed[2].wen     <= _inner_wbDataPath_io_toV0Preg_2_wen;
    v0WbDelayed[2].typeWen <= _inner_wbDataPath_io_toV0Preg_2_v0Wen;
    if (_inner_wbDataPath_io_toV0Preg_2_wen) v0WbDelayed[2].addr <= _inner_wbDataPath_io_toV0Preg_2_addr;
    v0WbDelayed[3].wen     <= _inner_wbDataPath_io_toV0Preg_3_wen;
    v0WbDelayed[3].typeWen <= _inner_wbDataPath_io_toV0Preg_3_v0Wen;
    if (_inner_wbDataPath_io_toV0Preg_3_wen) v0WbDelayed[3].addr <= _inner_wbDataPath_io_toV0Preg_3_addr;
    v0WbDelayed[4].wen     <= _inner_wbDataPath_io_toV0Preg_4_wen;
    v0WbDelayed[4].typeWen <= _inner_wbDataPath_io_toV0Preg_4_v0Wen;
    if (_inner_wbDataPath_io_toV0Preg_4_wen) v0WbDelayed[4].addr <= _inner_wbDataPath_io_toV0Preg_4_addr;
    v0WbDelayed[5].wen     <= _inner_wbDataPath_io_toV0Preg_5_wen;
    v0WbDelayed[5].typeWen <= _inner_wbDataPath_io_toV0Preg_5_v0Wen;
    if (_inner_wbDataPath_io_toV0Preg_5_wen) v0WbDelayed[5].addr <= _inner_wbDataPath_io_toV0Preg_5_addr;

    vlWbDelayed[0].wen     <= _inner_wbDataPath_io_toVlPreg_0_wen;
    vlWbDelayed[0].typeWen <= _inner_wbDataPath_io_toVlPreg_0_vlWen;
    if (_inner_wbDataPath_io_toVlPreg_0_wen) vlWbDelayed[0].addr <= _inner_wbDataPath_io_toVlPreg_0_addr;
    vlWbDelayed[1].wen     <= _inner_wbDataPath_io_toVlPreg_1_wen;
    vlWbDelayed[1].typeWen <= _inner_wbDataPath_io_toVlPreg_1_vlWen;
    if (_inner_wbDataPath_io_toVlPreg_1_wen) vlWbDelayed[1].addr <= _inner_wbDataPath_io_toVlPreg_1_addr;
    vlWbDelayed[2].wen     <= _inner_wbDataPath_io_toVlPreg_2_wen;
    vlWbDelayed[2].typeWen <= _inner_wbDataPath_io_toVlPreg_2_vlWen;
    if (_inner_wbDataPath_io_toVlPreg_2_wen) vlWbDelayed[2].addr <= _inner_wbDataPath_io_toVlPreg_2_addr;
    vlWbDelayed[3].wen     <= _inner_wbDataPath_io_toVlPreg_3_wen;
    vlWbDelayed[3].typeWen <= _inner_wbDataPath_io_toVlPreg_3_vlWen;
    if (_inner_wbDataPath_io_toVlPreg_3_wen) vlWbDelayed[3].addr <= _inner_wbDataPath_io_toVlPreg_3_addr;

    // ---- ⑥ 杂项打拍 ----
    topDownL1MissR <= io_topDownInfo_l1Miss;
    // CSR<->Mem 信息打拍(来自 io_fromTop_*,送 intExuBlock.csrin)
    msiInfoValidR  <= io_fromTop_msiInfo_valid;
    if (io_fromTop_msiInfo_valid)  msiInfoBitsR   <= io_fromTop_msiInfo_bits;
    clintTimeValidR <= io_fromTop_clintTime_valid;
    if (io_fromTop_clintTime_valid) clintTimeBitsR <= io_fromTop_clintTime_bits;
    l2FlushDoneR   <= io_fromTop_l2FlushDone;
    debugVlS1R     <= _inner_dataPath_io_diffVl;
    // 外部中断打拍(送 intExuBlock.csrio.externalInterrupt)
    extIntR.mtip   <= io_fromTop_externalInterrupt_mtip;
    extIntR.msip   <= io_fromTop_externalInterrupt_msip;
    extIntR.meip   <= io_fromTop_externalInterrupt_meip;
    extIntR.seip   <= io_fromTop_externalInterrupt_seip;
    extIntR.debug  <= io_fromTop_externalInterrupt_debug;
    extIntR.nmi31  <= io_fromTop_externalInterrupt_nmi_nmi_31;
    extIntR.nmi43  <= io_fromTop_externalInterrupt_nmi_nmi_43;
    // topDownInfo.noUopsIssued RegNext(送顶层 io)
    noUopsIssuedR  <= _inner_dataPath_io_topDownInfo_noUopsIssued;
    // pfevent CSR 分发打拍
    pfeventCsrR.valid <= _inner_intExuBlock_io_csrio_customCtrl_distribute_csr_w_valid;
    pfeventCsrR.addr  <= _inner_intExuBlock_io_csrio_customCtrl_distribute_csr_w_bits_addr;
    pfeventCsrR.data  <= _inner_intExuBlock_io_csrio_customCtrl_distribute_csr_w_bits_data;
  end

  // ---- ⑤ vsetvl vtype 锁存 + ④ issueTimeout 计数(带同步复位)----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      vsetvlVType        <= '0;
      issueTimeoutCnt[0] <= '0;
      issueTimeoutCnt[1] <= '0;
      issueTimeoutCnt[2] <= '0;
      issueTimeoutCnt[3] <= '0;
      issueTimeoutCnt[4] <= '0;
    end else begin
      // vsetvl:int/vf 任一路 vtype 有效时锁存,int 优先。
      if (_inner_intExuBlock_io_vtype_valid | _inner_vfExuBlock_io_vtype_valid) begin
        vsetvlVType.illegal <= _inner_intExuBlock_io_vtype_valid
            ? _inner_intExuBlock_io_vtype_bits_illegal : _inner_vfExuBlock_io_vtype_bits_illegal;
        vsetvlVType.vma     <= _inner_intExuBlock_io_vtype_valid
            ? _inner_intExuBlock_io_vtype_bits_vma : _inner_vfExuBlock_io_vtype_bits_vma;
        vsetvlVType.vta     <= _inner_intExuBlock_io_vtype_valid
            ? _inner_intExuBlock_io_vtype_bits_vta : _inner_vfExuBlock_io_vtype_bits_vta;
        vsetvlVType.vsew    <= _inner_intExuBlock_io_vtype_valid
            ? _inner_intExuBlock_io_vtype_bits_vsew : _inner_vfExuBlock_io_vtype_bits_vsew;
        vsetvlVType.vlmul   <= _inner_intExuBlock_io_vtype_valid
            ? _inner_intExuBlock_io_vtype_bits_vlmul : _inner_vfExuBlock_io_vtype_bits_vlmul;
      end
      // 发射超时饱和计数(golden 优先级):新一拍发射(memIssueOutFire)清零;
      // 否则若仍卡(issueStuck)则 +1;否则保持。
      if (memIssueOutFire[0])  issueTimeoutCnt[0] <= '0;
      else if (issueStuck0)    issueTimeoutCnt[0] <= issueTimeoutCnt[0] + 4'h1;
      if (memIssueOutFire[1])  issueTimeoutCnt[1] <= '0;
      else if (issueStuck1)    issueTimeoutCnt[1] <= issueTimeoutCnt[1] + 4'h1;
      if (memIssueOutFire[2])  issueTimeoutCnt[2] <= '0;
      else if (issueStuck2)    issueTimeoutCnt[2] <= issueTimeoutCnt[2] + 4'h1;
      if (memIssueOutFire[3])  issueTimeoutCnt[3] <= '0;
      else if (issueStuck3)    issueTimeoutCnt[3] <= issueTimeoutCnt[3] + 4'h1;
      if (memIssueOutFire[4])  issueTimeoutCnt[4] <= '0;
      else if (issueStuck4)    issueTimeoutCnt[4] <= issueTimeoutCnt[4] + 4'h1;
    end
  end
