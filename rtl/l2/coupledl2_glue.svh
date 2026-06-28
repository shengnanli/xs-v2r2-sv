// 自动生成:scripts/gen_coupledl2.py —— 勿手改(顶层 glue 为从 firtool 意图的具名可读重写)

// ===================================================================
// TL2CHICoupledL2 顶层 glue —— 从 firtool 产出的匿名流水(_REG_<n>/_T_<n>/
// _GEN_<n>)重写为具名可读信号 + 数组 + generate-for,语义逐拍等价。
// 共 6 组:
//   (1) MBIST 广播常量(全 0,未接,dontTouch);
//   (2) L2->L1 hint 与 D 通道发射仲裁(hintFire / sliceCanFire / allCanFire);
//   (3) Grant 数据节拍计数 + hint 命中精度探针(dontTouch 统计);
//   (4) 48 路性能计数 2 级打拍(4 slice × 12 事件;事件 #2 恒 0);
//   (5) l2Miss 汇聚打拍;
//   (6) CHI rx 五通道按 bank 路由译码 + P-Credit grant 流水。
// ===================================================================

  // ---- (1) MBIST 广播接口:本配置未接外部广播,全部恒 0(dontTouch,未驱动输出)。
  wire         bd_all     = 1'h0;
  wire         bd_req     = 1'h0;
  wire         bd_writeen = 1'h0;
  wire         bd_readen  = 1'h0;
  wire [103:0] bd_indata  = 104'h0;
  wire [12:0]  bd_addr    = 13'h0;
  wire [12:0]  bd_addr_rd = 13'h0;
  wire [7:0]   bd_be      = 8'h0;
  wire [5:0]   bd_array   = 6'h0;
  // bd_ack / bd_outdata 声明见 decls,这里直连 mbistPl 返回(未被下游消费)。
  assign bd_ack     = _mbistPl_mbist_ack;
  assign bd_outdata = _mbistPl_mbist_outdata;

  // ---- (2) L2->L1 hint 与各 slice D 通道发射仲裁 ----------------------
  // hintArbOutReadyReg:hint 仲裁输出 ready 的上一拍(用于产生发射沿)。
  reg          hintArbOutReadyReg;
  // hintFire:本拍 L1HintArb 选出的 hint 真正发射 = 上拍未 ready & 本拍 valid
  //           & 目标 sourceId 落在 L1 范围(高位为 0 且低 6 位 < 0x24)。
  wire         hintFire =
    ~hintArbOutReadyReg & _l1HintArb_io_out_valid
    & _l1HintArb_io_out_bits_sourceId[31:6] == 26'h0
    & _l1HintArb_io_out_bits_sourceId[5:0] < 6'h24;
  // hintChosen[i]:本拍 hint 仲裁选中的 slice(L1HintArb.chosen == i)。
  wire [3:0]   hintChosen;
  assign hintChosen[0] = _l1HintArb_io_chosen == 2'h0;
  assign hintChosen[1] = _l1HintArb_io_chosen == 2'h1;
  assign hintChosen[2] = _l1HintArb_io_chosen == 2'h2;
  assign hintChosen[3] = &_l1HintArb_io_chosen;          // == 2'h3

  // 每个 slice 一组「hint 发射阻塞」延迟链:hint 命中该 slice 时,把它的 D 通道
  // 释放延后——A 链 2 拍、B 链 3 拍,任一有效即该 slice 本拍可发射(sliceCanFire)。
  // 每个寄存器是 4 bit 向量(每 bit 一个 slice),逐拍移位。
  reg  [3:0]   hintBlockA0, hintBlockA1;             // A 链两级
  reg  [3:0]   hintBlockB0, hintBlockB1, hintBlockB2; // B 链三级
  wire [3:0]   sliceCanFire = hintBlockA1 | hintBlockB2;

  // allCanFire:无 hint 命中(~hintFire 同样经 2 拍 / 3 拍延迟)时全体可发射,
  //            或任一 slice 已请求释放 D(releaseSourceD)。
  reg          allBlockA0, allBlockA1;               // A 链两级(~hintFire)
  reg          allBlockB0, allBlockB1, allBlockB2;   // B 链三级
  wire         allCanFire =
    allBlockA1 & allBlockB2
    | (|{releaseSourceD_0, releaseSourceD_1, releaseSourceD_2, releaseSourceD_3});

  // sliceDArbWin[i]:slice i 本拍赢得 D 仲裁(可向 L1 发 D)= 自身可发射 或 全体可发射。
  wire [3:0]   sliceDArbWin = sliceCanFire | {4{allCanFire}};
  // sliceDReady[i]:slice i 的 D 通道 ready = 上游 TileLink d_ready & 赢得仲裁。
  wire [3:0]   sliceDReady;
  assign sliceDReady[0] = auto_in_0_d_ready & sliceDArbWin[0];
  assign sliceDReady[1] = auto_in_1_d_ready & sliceDArbWin[1];
  assign sliceDReady[2] = auto_in_2_d_ready & sliceDArbWin[2];
  assign sliceDReady[3] = auto_in_3_d_ready & sliceDArbWin[3];

  // releaseSourceD[i]:slice i 本拍可发射但其 D 无数据(让出 D 给 hint)。
  assign releaseSourceD_0 = sliceCanFire[0] & ~_slices_0_io_in_d_valid;
  assign releaseSourceD_1 = sliceCanFire[1] & ~_slices_1_io_in_d_valid;
  assign releaseSourceD_2 = sliceCanFire[2] & ~_slices_2_io_in_d_valid;
  assign releaseSourceD_3 = sliceCanFire[3] & ~_slices_3_io_in_d_valid;

  // prefetchReqsReady[i]:prefetch 请求按地址 bank(set[1:0])路由到目标 slice 的 ready。
  assign prefetchReqsReady_0 =
    _slices_0_io_prefetch_req_ready & _prefetcher_io_req_bits_set[1:0] == 2'h0;
  assign prefetchReqsReady_1 =
    _slices_1_io_prefetch_req_ready & _prefetcher_io_req_bits_set[1:0] == 2'h1;
  assign prefetchReqsReady_2 =
    _slices_2_io_prefetch_req_ready & _prefetcher_io_req_bits_set[1:0] == 2'h2;
  assign prefetchReqsReady_3 =
    _slices_3_io_prefetch_req_ready & (&(_prefetcher_io_req_bits_set[1:0]));

  // ---- (3) Grant 数据节拍计数 + L2->L1 hint 命中精度探针(dontTouch 统计)----
  // grantDValidReady[i]:slice i 的 D 通道本拍成功握手(valid & ready)。
  wire [3:0]   grantDValidReady;
  assign grantDValidReady[0] = sliceDReady[0] & _slices_0_io_in_d_valid;
  assign grantDValidReady[1] = sliceDReady[1] & _slices_1_io_in_d_valid;
  assign grantDValidReady[2] = sliceDReady[2] & _slices_2_io_in_d_valid;
  assign grantDValidReady[3] = sliceDReady[3] & _slices_3_io_in_d_valid;
  // grantBeatRest[i]:多拍 GrantData 的「后续节拍」标志(首拍按 opcode[0] 置位,逐拍递减)。
  reg  [3:0]   grantBeatRest;
  // grantDataFire[i]:slice i 本拍发出 GrantData 首拍(opcode==4'h5 且非后续节拍)。
  wire [3:0]   grantDataFire;
  assign grantDataFire[0] =
    grantDValidReady[0] & ~grantBeatRest[0] & _slices_0_io_in_d_bits_opcode == 4'h5;
  assign grantDataFire[1] =
    grantDValidReady[1] & ~grantBeatRest[1] & _slices_1_io_in_d_bits_opcode == 4'h5;
  assign grantDataFire[2] =
    grantDValidReady[2] & ~grantBeatRest[2] & _slices_2_io_in_d_bits_opcode == 4'h5;
  assign grantDataFire[3] =
    grantDValidReady[3] & ~grantBeatRest[3] & _slices_3_io_in_d_bits_opcode == 4'h5;
  // 以下三者均为 dontTouch 统计/探针,不驱动任何功能输出:
  //   grantDataFireCount:本拍发出 GrantData 的 slice 数(0..4);
  wire [2:0]   grantDataFireCount =
    3'(grantDataFire[0] + grantDataFire[1] + grantDataFire[2] + grantDataFire[3]);
  wire         grantDataFireAny = |grantDataFire;
  //   grantDataSource:本拍发射 grant 的 sourceId(优先 slice0>1>2>3),零扩展到 32 位;
  wire [31:0]  grantDataSource =
    {25'h0,
     grantDValidReady[0] | grantDValidReady[1]
       ? (grantDValidReady[0]
            ? _slices_0_io_in_d_bits_source
            : _slices_1_io_in_d_bits_source)
       : grantDValidReady[2]
           ? _slices_2_io_in_d_bits_source
           : _slices_3_io_in_d_bits_source};
  //   accurateHint/okHint:hint 预测(hintPipe2/1 的 sourceId)与实际 grant 是否一致。
  wire         accurateHint_probe =
    grantDataFireAny & _hintPipe2_io_out_valid & _hintPipe2_io_out_bits == grantDataSource;
  wire         okHint_probe =
    grantDataFireAny & _hintPipe1_io_out_valid & _hintPipe1_io_out_bits == grantDataSource;

  // ---- (4) 性能计数 2 级打拍:48 路 = 4 slice × 12 事件,各打两拍(RegNext∘RegNext)。
  //          事件 #2(每 slice 第 3 路)在本层恒 0(占位)。slicePerfRaw[N] 源映射
  //          收割自 golden(io_perf_<N>_value_REG <= <src>),与 golden 逐拍等价。
  wire [5:0]   slicePerfRaw [1:48];   // 各 slice 的 12 路 perf 原始值(事件 #2 = 0)
  assign slicePerfRaw[1] = _slices_0_io_perf_0_value;
  assign slicePerfRaw[2] = _slices_0_io_perf_1_value;
  assign slicePerfRaw[3] = 6'h0;
  assign slicePerfRaw[4] = _slices_0_io_perf_3_value;
  assign slicePerfRaw[5] = _slices_0_io_perf_4_value;
  assign slicePerfRaw[6] = _slices_0_io_perf_5_value;
  assign slicePerfRaw[7] = _slices_0_io_perf_6_value;
  assign slicePerfRaw[8] = _slices_0_io_perf_7_value;
  assign slicePerfRaw[9] = _slices_0_io_perf_8_value;
  assign slicePerfRaw[10] = _slices_0_io_perf_9_value;
  assign slicePerfRaw[11] = _slices_0_io_perf_10_value;
  assign slicePerfRaw[12] = _slices_0_io_perf_11_value;
  assign slicePerfRaw[13] = _slices_1_io_perf_0_value;
  assign slicePerfRaw[14] = _slices_1_io_perf_1_value;
  assign slicePerfRaw[15] = 6'h0;
  assign slicePerfRaw[16] = _slices_1_io_perf_3_value;
  assign slicePerfRaw[17] = _slices_1_io_perf_4_value;
  assign slicePerfRaw[18] = _slices_1_io_perf_5_value;
  assign slicePerfRaw[19] = _slices_1_io_perf_6_value;
  assign slicePerfRaw[20] = _slices_1_io_perf_7_value;
  assign slicePerfRaw[21] = _slices_1_io_perf_8_value;
  assign slicePerfRaw[22] = _slices_1_io_perf_9_value;
  assign slicePerfRaw[23] = _slices_1_io_perf_10_value;
  assign slicePerfRaw[24] = _slices_1_io_perf_11_value;
  assign slicePerfRaw[25] = _slices_2_io_perf_0_value;
  assign slicePerfRaw[26] = _slices_2_io_perf_1_value;
  assign slicePerfRaw[27] = 6'h0;
  assign slicePerfRaw[28] = _slices_2_io_perf_3_value;
  assign slicePerfRaw[29] = _slices_2_io_perf_4_value;
  assign slicePerfRaw[30] = _slices_2_io_perf_5_value;
  assign slicePerfRaw[31] = _slices_2_io_perf_6_value;
  assign slicePerfRaw[32] = _slices_2_io_perf_7_value;
  assign slicePerfRaw[33] = _slices_2_io_perf_8_value;
  assign slicePerfRaw[34] = _slices_2_io_perf_9_value;
  assign slicePerfRaw[35] = _slices_2_io_perf_10_value;
  assign slicePerfRaw[36] = _slices_2_io_perf_11_value;
  assign slicePerfRaw[37] = _slices_3_io_perf_0_value;
  assign slicePerfRaw[38] = _slices_3_io_perf_1_value;
  assign slicePerfRaw[39] = 6'h0;
  assign slicePerfRaw[40] = _slices_3_io_perf_3_value;
  assign slicePerfRaw[41] = _slices_3_io_perf_4_value;
  assign slicePerfRaw[42] = _slices_3_io_perf_5_value;
  assign slicePerfRaw[43] = _slices_3_io_perf_6_value;
  assign slicePerfRaw[44] = _slices_3_io_perf_7_value;
  assign slicePerfRaw[45] = _slices_3_io_perf_8_value;
  assign slicePerfRaw[46] = _slices_3_io_perf_9_value;
  assign slicePerfRaw[47] = _slices_3_io_perf_10_value;
  assign slicePerfRaw[48] = _slices_3_io_perf_11_value;
  reg  [5:0]   perfStage1 [1:48];     // 第 1 拍
  reg  [5:0]   perfStage2 [1:48];     // 第 2 拍(经 outassign 直送 io_perf_*_value)

  // ---- (5) l2Miss 汇聚打拍:io.l2Miss := RegNext(OR(各 slice l2Miss))。
  reg          l2MissReg;

  // ---- (6) CHI rx 五通道按 bank 路由译码 + P-Credit grant 流水 ----------
  // 按 txnID[10:9](rsp/dat)/ snp addr[4:3] 选 bank 0..2(bank3 在消费处用 & 取默认)。
  wire         snpBankSel0 = _linkMonitor_io_in_rx_snp_bits_addr[4:3] == 2'h0;
  wire         snpBankSel1 = _linkMonitor_io_in_rx_snp_bits_addr[4:3] == 2'h1;
  wire         snpBankSel2 = _linkMonitor_io_in_rx_snp_bits_addr[4:3] == 2'h2;
  wire         rspIsPCrdGrantOp = _linkMonitor_io_in_rx_rsp_bits_opcode == 5'h7;
  wire         isPCrdGrant = _linkMonitor_io_in_rx_rsp_valid & rspIsPCrdGrantOp;
  wire         rspBankSel0 = _linkMonitor_io_in_rx_rsp_bits_txnID[10:9] == 2'h0;
  wire         rspBankSel1 = _linkMonitor_io_in_rx_rsp_bits_txnID[10:9] == 2'h1;
  wire         rspBankSel2 = _linkMonitor_io_in_rx_rsp_bits_txnID[10:9] == 2'h2;
  wire         datBankSel0 = _linkMonitor_io_in_rx_dat_bits_txnID[10:9] == 2'h0;
  wire         datBankSel1 = _linkMonitor_io_in_rx_dat_bits_txnID[10:9] == 2'h1;
  wire         datBankSel2 = _linkMonitor_io_in_rx_dat_bits_txnID[10:9] == 2'h2;
  // P-Credit grant 流水:rxrsp 为 PCrdGrant 时,把 (type, srcID) 打一拍送入 pCrdQueue。
  reg          pCrdGrantValid_s1;
  reg  [3:0]   pCrdGrantType_s1;
  reg  [10:0]  pCrdGrantSrcID_s1;
  wire         pCrdQueueEnqFire = _pCrdQueue_io_enq_ready & pCrdGrantValid_s1; // dontTouch
  reg  [63:0]  grantCnt;             // pCrdGrant 仲裁发射计数(dontTouch 统计)

  // ================= 时序逻辑 =================
  // (a) 同步块(无复位):hint/all 延迟链、perf 2 级打拍、l2Miss 汇聚、pCrdGrant 打拍。
  integer pi;
  always @(posedge clock) begin
    // hint 发射阻塞延迟链(每 bit 一个 slice;allBlock 为标量,全体共用)。
    hintBlockA0 <= {4{hintFire}} & hintChosen;
    hintBlockA1 <= hintBlockA0;
    hintBlockB0 <= {4{hintFire}} & hintChosen;
    hintBlockB1 <= hintBlockB0;
    hintBlockB2 <= hintBlockB1;
    allBlockA0  <= ~hintFire;
    allBlockA1  <= allBlockA0;
    allBlockB0  <= ~hintFire;
    allBlockB1  <= allBlockB0;
    allBlockB2  <= allBlockB1;
    // perf 2 级打拍(48 路)。
    for (pi = 1; pi <= 48; pi = pi + 1) begin
      perfStage1[pi] <= slicePerfRaw[pi];
      perfStage2[pi] <= perfStage1[pi];
    end
    // l2Miss 汇聚打拍。
    l2MissReg <=
      _slices_0_io_l2Miss | _slices_1_io_l2Miss | _slices_2_io_l2Miss
      | _slices_3_io_l2Miss;
    // P-Credit grant 打拍。
    pCrdGrantValid_s1 <= isPCrdGrant;
    if (isPCrdGrant) begin
      pCrdGrantType_s1  <= _linkMonitor_io_in_rx_rsp_bits_pCrdType;
      pCrdGrantSrcID_s1 <= _linkMonitor_io_in_rx_rsp_bits_srcID;
    end
  end

  // (b) 异步复位块:hint ready 沿、grant 节拍计数、pCrdGrant 仲裁计数。
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      hintArbOutReadyReg <= 1'h0;
      grantBeatRest      <= 4'h0;
      grantCnt           <= 64'h0;
    end
    else begin
      hintArbOutReadyReg <= hintFire;
      // 各 slice 的多拍 GrantData 节拍跟踪:首拍按 opcode[0] 置位,其后逐拍递减(到 0)。
      if (grantDValidReady[0])
        grantBeatRest[0] <=
          grantBeatRest[0] ? 1'h0 : _slices_0_io_in_d_bits_opcode[0];
      if (grantDValidReady[1])
        grantBeatRest[1] <=
          grantBeatRest[1] ? 1'h0 : _slices_1_io_in_d_bits_opcode[0];
      if (grantDValidReady[2])
        grantBeatRest[2] <=
          grantBeatRest[2] ? 1'h0 : _slices_2_io_in_d_bits_opcode[0];
      if (grantDValidReady[3])
        grantBeatRest[3] <=
          grantBeatRest[3] ? 1'h0 : _slices_3_io_in_d_bits_opcode[0];
      if (_pcrdgrant_arb_io_out_valid)
        grantCnt <= 64'(grantCnt + 64'h1);
    end
  end
