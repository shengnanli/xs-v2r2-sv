// =============================================================================
// TL2CHICoupledL2 —— 香山 L2 Cache 顶层（TileLink 进、CHI 出）：4 个 Slice + 预取 + MMIO 桥 + CHI 链路层
//
// Scala：coupledL2/src/main/scala/coupledL2/tl2chi/TL2CHICoupledL2.scala（class TL2CHICoupledL2.CoupledL2Imp）
//        + coupledL2/src/main/scala/coupledL2/CoupledL2.scala（BaseCoupledL2Imp：预取、hint、ECC、TopDown、perf）。
// 位置：L2Top 里（实例名 inner_l2cache）。上面 4 组 TileLink-C 口（auto_in_0..3，按地址 bit[7:6] 分 bank）
//   各接一个 Slice；下面一组 CHI 物理链路 io_chi_*（经 LinkMonitor）；旁路一组 TileLink-UL MMIO 口进 MMIOBridge。
//
// 结构（golden 7663 行，绝大部分是 32 个 child 的逐端口连线；child 全部是已签核的重写件）：
//
//   auto_in_i ⇄ slices_i（Slice / Slice_1 / Slice_2 / Slice_3）
//                 │ tx.req ─┐                        ┌─ txreq_arb（轮转，4 slice + MMIO）─┐
//                 │ tx.rsp ─┼────────────────────────┼─ txrsp_arb（FastArbiter）─────────┼─▶ linkMonitor ⇄ io_chi
//                 │ tx.dat ─┘     mmioBridge ─tx─────┴─ txdat_arb（FastArbiter）─────────┘        │
//                 │ rx.snp/rsp/dat ◀── 按 addr / txnID 分发（本层，§6 §7）◀── rxrspPipe / rxdatPipe ◀┘
//                 │ pCrd 查询 ×16 ─┐  mmioBridge pCrd 查询 ×16 ─┐
//                 │                └──── §8 P-Credit 两级队列 + 命中仲裁（pcrdgrant_arb）
//                 │ prefetch train/resp ─▶ train_pipeline_i / resp_pipeline_i ─▶ prefetch_*_arb ─▶ prefetcher
//                 │ prefetch req ◀─ 按 set[1:0] 选 slice（§2）◀─ prefetcher
//                 │ l1Hint ─▶ l1HintArb ─▶ io_l2_hint（§1）；error ─▶ l2ECCArb ─▶ io_error（§3）
//                 └ TopDown 状态 ─▶ topDown；MBIST ─▶ mbistPl（L2Cache）◀─ l2MbistIntf
//
// 本层手写的只有胶合逻辑（xs_TL2CHICoupledL2_core）：
//   §1 hint 引导的 D 通道放行（enableHintGuidedGrant）：L1 Hint 选中 slice X 后第 2、3 拍优先放 X 的 D；
//      X 那拍没有 D 就"释放"，所有 slice 都可放（allCanFire）。hint 每两拍最多发一次（GrantData 两拍）。
//   §2 预取：slice 的训练地址补回 bank 号；prefetcher 的请求按 set[1:0] 送对应 slice。
//   §3 地址补 bank：B 通道地址、ECC 错误地址都在 [7:6] 插回 bank 号。
//   §4 perf 计数打两拍输出；l2Miss 打一拍。
//   §5 TXREQ：链路层未进入一致性（syscoreq & syscoack）时挡住可缓存请求，MMIO 总放行；txnID 编码 slice 号 / MMIO 位。
//   §6 RXSNP：按地址 bit[7:6]（snoop 地址字段的 [4:3]）分发到 slice。
//   §7 RXRSP / RXDAT：按 txnID 分发——bit11=1 给 MMIO，否则 [10:9] 是 slice 号；送下去前还原成 slice 内部 txnID。
//      PCrdGrant 响应不给任何 slice / MMIO，进 §8。
//   §8 P-Credit：PCrdGrant 打一拍进 pCrdQueue_s2（78 项）→ pCrdQueue_s3（2 项）；s3 队头与 80 个 MSHR 查询
//      （MMIO 16 + 4×16）逐个比 {pCrdType, srcID}，命中的送 pcrdgrant_arb，仲裁出一个就出队并授给它。
//
// 怪癖（照 golden）：
//   * §1 的 RegNextN(x, 2) / RegNextN(x, 3) 是两条独立的打拍链（前两级不共用），golden 每条都留着，本文件也逐个保留。
//   * Slice 的 RXRSP / RXDAT 恒可收（golden Slice 已没有这两个 ready 口），分发的 ready 里 slice 那项在 wrapper 里接 1。
//   * 以下寄存器在 golden 里没有任何读者，照样保留（Scala dontTouch / XSPerf 的残留，FM 的 matched-unread 点）：
//     grantCnt（P-Credit 授出计数，64 位）、grant_data_fire_first_r_counter*（GrantData 首拍识别，只给 perf 探针用）。
//     这两组按 golden 原名命名：无读者的寄存器 FM 只能按名配对。
//   * perf 第 2 号事件（每 slice 的 index 2）在 slice 里恒 0（golden 已消掉该口），wrapper 接常 0，两级寄存器照留。
//
// 本文件导航：xs_TL2CHICoupledL2_core（手写 §1–§8）→ TL2CHICoupledL2（golden 同名端口表 + 32 个 child，
//   实例名同 golden；scripts/gen_tl2chi.py 从 golden 机械生成，每个 child 端口必须恰好有一个来源，否则生成失败）
// =============================================================================

module xs_TL2CHICoupledL2_core #(
  parameter int unsigned NUM_SLICES     = 4,
  parameter int unsigned PERF_PER_SLICE = 17,
  parameter int unsigned NUM_PCRD       = 80    // MSHR P-Credit 查询口：MMIO 16 + 4 slice × 16
) (
  input  logic        clock,
  input  logic        reset,

  // §1 L1 Hint 与 D 通道放行
  input  logic                  hintArb_valid,
  input  logic [31:0]           hintArb_sourceId,
  input  logic [1:0]            hintArb_chosen,      // 被选中的 slice 号（Arbiter 的 chosen）
  output logic                  hintArb_ready,
  output logic                  hintFire,            // = io_l2_hint_valid
  input  logic [NUM_SLICES-1:0] slice_dValid,
  input  logic [3:0]            slice_dOpcode [NUM_SLICES],
  output logic [NUM_SLICES-1:0] slice_dReady,
  input  logic [NUM_SLICES-1:0] in_dReady,           // 上游（auto_in_i）D 的 ready
  output logic [NUM_SLICES-1:0] in_dValid,

  // §2 预取
  input  logic                  pf_reqValid,
  input  logic [8:0]            pf_reqSet,
  input  logic [NUM_SLICES-1:0] slice_pfReqReady,
  output logic [NUM_SLICES-1:0] slice_pfReqValid,
  output logic                  pf_reqReady,
  input  logic [32:0]           train_tag [NUM_SLICES],     // slice 内的 tag / set（不含 bank 号）
  input  logic [8:0]            train_set [NUM_SLICES],
  output logic [32:0]           trainArb_tag [NUM_SLICES],  // 补回 bank 号后的全局 tag / set
  output logic [8:0]            trainArb_set [NUM_SLICES],

  // §3 地址补 bank
  input  logic [47:0]           slice_bAddr [NUM_SLICES],
  output logic [47:0]           in_bAddr [NUM_SLICES],
  input  logic [45:0]           slice_errAddr [NUM_SLICES],
  output logic [45:0]           eccArb_addr [NUM_SLICES],
  input  logic                  eccArb_outValid,
  input  logic                  eccArb_outBitsValid,
  output logic                  errorValid,

  // §4 perf / l2Miss
  input  logic [5:0]            slice_perf [NUM_SLICES][PERF_PER_SLICE],
  output logic [5:0]            perf [NUM_SLICES*PERF_PER_SLICE],
  input  logic [NUM_SLICES-1:0] slice_l2Miss,
  output logic                  l2Miss,

  // §5 TXREQ
  input  logic                  txReqArb_outValid,
  input  logic [2:0]            txReqArb_chosen,     // 0..3 = slice，4 = MMIO
  input  logic [11:0]           txReqArb_outTxnID,
  input  logic                  txReqArb_mmioReady,  // 仲裁器给 MMIO 那一路的 ready
  input  logic                  mmio_txReqValid,
  input  logic                  lm_txReqReady,
  input  logic                  lm_syscoreq,
  input  logic                  chi_syscoack,
  output logic                  lm_txReqValid,
  output logic [11:0]           lm_txReqTxnID,
  output logic                  txReqArb_outReady,

  // §6 RXSNP
  input  logic                  rxSnp_valid,
  input  logic [1:0]            rxSnp_bank,          // snoop 地址字段 [4:3] = 物理地址 [7:6]
  input  logic [NUM_SLICES-1:0] slice_rxSnpReady,
  output logic [NUM_SLICES-1:0] slice_rxSnpValid,
  output logic                  rxSnp_ready,

  // §7 RXRSP / RXDAT
  input  logic                  rxRsp_valid,
  input  logic [4:0]            rxRsp_opcode,
  input  logic [11:0]           rxRsp_txnID,
  input  logic [NUM_SLICES-1:0] slice_rxRspReady,
  input  logic                  mmio_rxRspReady,
  output logic [NUM_SLICES-1:0] slice_rxRspValid,
  output logic                  mmio_rxRspValid,
  output logic [11:0]           rxRsp_innerTxnID,
  output logic                  rxRsp_ready,
  input  logic                  rxDat_valid,
  input  logic [11:0]           rxDat_txnID,
  input  logic [NUM_SLICES-1:0] slice_rxDatReady,
  input  logic                  mmio_rxDatReady,
  output logic [NUM_SLICES-1:0] slice_rxDatValid,
  output logic                  mmio_rxDatValid,
  output logic [11:0]           rxDat_innerTxnID,
  output logic                  rxDat_ready,

  // §8 P-Credit
  input  logic [3:0]            rxRsp_pCrdType,
  input  logic [10:0]           rxRsp_srcID,
  output logic                  pcrdEnq_valid,       // → pCrdQueue_s2
  output logic [3:0]            pcrdEnq_pCrdType,
  output logic [10:0]           pcrdEnq_srcID,
  input  logic                  pcrdHead_valid,      // pCrdQueue_s3 队头
  input  logic [3:0]            pcrdHead_pCrdType,
  input  logic [10:0]           pcrdHead_srcID,
  input  logic [NUM_PCRD-1:0]   pcrdQuery_valid,
  input  logic [3:0]            pcrdQuery_pCrdType [NUM_PCRD],
  input  logic [10:0]           pcrdQuery_srcID [NUM_PCRD],
  output logic [NUM_PCRD-1:0]   pcrdHit,             // → pcrdgrant_arb 各路 valid
  input  logic                  pcrdArb_outValid     // 仲裁出一个 = s3 出队、授出一个 P-Credit
);

  localparam logic [4:0] CHI_RSP_PCRDGRANT = 5'h07;
  localparam logic [3:0] TL_D_GRANTDATA    = 4'h5;
  localparam logic [5:0] DCACHE_SOURCE_END = 6'h24;  // DCache 的 TileLink source 是 0..35

  // ===========================================================================
  // §1 L1 Hint 与 D 通道放行
  // ===========================================================================
  // hint 只发给 DCache（source < 36）；发过一拍就停一拍（GrantData 占两拍）
  logic hintSentLastCycle;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) hintSentLastCycle <= 1'b0;
    else       hintSentLastCycle <= hintFire;
  end

  assign hintArb_ready = ~hintSentLastCycle;
  assign hintFire      = hintArb_ready & hintArb_valid
                         & (hintArb_sourceId[31:6] == 26'h0) & (hintArb_sourceId[5:0] < DCACHE_SOURCE_END);

  // allCanFire = RegNextN(!hintFire, 2) && RegNextN(!hintFire, 3) || 任一 slice 释放
  logic noHint2_d1, noHint2_d2;               // RegNextN(!hintFire, 2)
  logic noHint3_d1, noHint3_d2, noHint3_d3;   // RegNextN(!hintFire, 3)（独立的另一条链）

  always_ff @(posedge clock) begin
    noHint2_d1 <= ~hintFire;
    noHint2_d2 <= noHint2_d1;
    noHint3_d1 <= ~hintFire;
    noHint3_d2 <= noHint3_d1;
    noHint3_d3 <= noHint3_d2;
  end

  // sliceCanFire(i) = RegNextN(hint 选中 i, 2) || RegNextN(hint 选中 i, 3)
  logic [NUM_SLICES-1:0] hintPick;
  logic [NUM_SLICES-1:0] pick2_d1, pick2_d2;
  logic [NUM_SLICES-1:0] pick3_d1, pick3_d2, pick3_d3;
  logic [NUM_SLICES-1:0] sliceCanFire;
  logic [NUM_SLICES-1:0] releaseSourceD;
  logic                  allCanFire;

  always_comb begin
    for (int i = 0; i < NUM_SLICES; i++) hintPick[i] = hintFire & (hintArb_chosen == 2'(i));
  end

  always_ff @(posedge clock) begin
    pick2_d1 <= hintPick;
    pick2_d2 <= pick2_d1;
    pick3_d1 <= hintPick;
    pick3_d2 <= pick3_d1;
    pick3_d3 <= pick3_d2;
  end

  assign sliceCanFire   = pick2_d2 | pick3_d3;
  assign releaseSourceD = sliceCanFire & ~slice_dValid;   // 轮到我却没有 D：让给别人
  assign allCanFire     = (noHint2_d2 & noHint3_d3) | (|releaseSourceD);

  always_comb begin
    for (int i = 0; i < NUM_SLICES; i++) begin
      slice_dReady[i] = in_dReady[i] & (sliceCanFire[i] | allCanFire);
      in_dValid[i]    = slice_dValid[i] & (sliceCanFire[i] | allCanFire);
    end
  end

  // GrantData 首拍识别（TileLink edge.count：数据 beat 计数）——只给 perf 探针用，无读者，照 golden 保留
  logic grant_data_fire_first_r_counter;
  logic grant_data_fire_first_r_counter_1;
  logic grant_data_fire_first_r_counter_2;
  logic grant_data_fire_first_r_counter_3;
  logic [NUM_SLICES-1:0] dFire;

  assign dFire = slice_dReady & slice_dValid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      grant_data_fire_first_r_counter   <= 1'b0;
      grant_data_fire_first_r_counter_1 <= 1'b0;
      grant_data_fire_first_r_counter_2 <= 1'b0;
      grant_data_fire_first_r_counter_3 <= 1'b0;
    end else begin
      // 剩余 beat 数：非 0 就减 1，否则装入"本消息共几拍 - 1"（带数据的 D 消息 opcode[0]=1，两拍）
      if (dFire[0]) grant_data_fire_first_r_counter   <= grant_data_fire_first_r_counter   ? 1'b0 : slice_dOpcode[0][0];
      if (dFire[1]) grant_data_fire_first_r_counter_1 <= grant_data_fire_first_r_counter_1 ? 1'b0 : slice_dOpcode[1][0];
      if (dFire[2]) grant_data_fire_first_r_counter_2 <= grant_data_fire_first_r_counter_2 ? 1'b0 : slice_dOpcode[2][0];
      if (dFire[3]) grant_data_fire_first_r_counter_3 <= grant_data_fire_first_r_counter_3 ? 1'b0 : slice_dOpcode[3][0];
    end
  end

  // ===========================================================================
  // §2 预取：训练地址补 bank 号；预取请求按 set[1:0]（= bank 号）选 slice
  // ===========================================================================
  // 全地址 = {tag, set, bank, offset}；slice 内的 set 不含 bank，全局的 set 低 2 位是 bank 号，
  // 于是全局 tag 吃掉 slice set 的高 2 位（tag 宽度不变，最高 2 位丢掉）。
  always_comb begin
    for (int i = 0; i < NUM_SLICES; i++) begin
      trainArb_tag[i] = {train_tag[i][30:0], train_set[i][8:7]};
      trainArb_set[i] = {train_set[i][6:0], 2'(i)};
    end
  end

  always_comb begin
    for (int i = 0; i < NUM_SLICES; i++) slice_pfReqValid[i] = pf_reqValid & (pf_reqSet[1:0] == 2'(i));
  end

  // prefetchReqsReady(i) = slice i 的 ready 且请求就是发给 i 的
  logic [NUM_SLICES-1:0] pfReqReadyHit;

  always_comb begin
    for (int i = 0; i < NUM_SLICES; i++) pfReqReadyHit[i] = slice_pfReqReady[i] & (pf_reqSet[1:0] == 2'(i));
  end

  assign pf_reqReady = |pfReqReadyHit;

  // ===========================================================================
  // §3 地址补 bank：slice 输出的地址在 [7:6] 处插回 bank 号（restoreAddress）
  // ===========================================================================
  always_comb begin
    for (int i = 0; i < NUM_SLICES; i++) begin
      in_bAddr[i]    = {slice_bAddr[i][45:6], 2'(i), slice_bAddr[i][5:0]};
      eccArb_addr[i] = {slice_errAddr[i][43:6], 2'(i), slice_errAddr[i][5:0]};
    end
  end

  assign errorValid = eccArb_outValid & eccArb_outBitsValid;   // 仲裁器 out.ready 恒 1，valid 即 fire

  // ===========================================================================
  // §4 perf 计数（每个打两拍）与 l2Miss（打一拍）
  // ===========================================================================
  logic [5:0] perf_d1 [NUM_SLICES*PERF_PER_SLICE];
  logic [5:0] perf_d2 [NUM_SLICES*PERF_PER_SLICE];

  always_ff @(posedge clock) begin
    for (int i = 0; i < NUM_SLICES; i++) begin
      for (int k = 0; k < PERF_PER_SLICE; k++) begin
        perf_d1[i*PERF_PER_SLICE + k] <= slice_perf[i][k];
        perf_d2[i*PERF_PER_SLICE + k] <= perf_d1[i*PERF_PER_SLICE + k];
      end
    end
  end

  assign perf = perf_d2;

  always_ff @(posedge clock) begin
    l2Miss <= |slice_l2Miss;
  end

  // ===========================================================================
  // §5 TXREQ：一致性门控 + txnID 编码
  // ===========================================================================
  // 编码：可缓存请求 {0, slice 号[1:0], slice 内 txnID[8:0]}；MMIO 请求 {1, MMIO 内 txnID[10:0]}
  logic coEnable;     // 链路层已进入一致性
  logic reqPass;      // 本拍仲裁出的请求可以发
  logic mmioFire;     // 仲裁器正在收 MMIO 那一路

  assign coEnable          = lm_syscoreq & chi_syscoack;
  assign reqPass           = coEnable | (txReqArb_chosen == 3'd4);
  assign lm_txReqValid     = txReqArb_outValid & reqPass;
  assign txReqArb_outReady = lm_txReqReady & reqPass;
  assign mmioFire          = txReqArb_mmioReady & mmio_txReqValid;
  assign lm_txReqTxnID     = mmioFire ? {1'b1, txReqArb_outTxnID[10:0]}
                                      : {1'b0, txReqArb_chosen[1:0], txReqArb_outTxnID[8:0]};

  // ===========================================================================
  // §6 RXSNP：按地址 bank 分发
  // ===========================================================================
  logic [NUM_SLICES-1:0] snpSliceHit;

  always_comb begin
    for (int i = 0; i < NUM_SLICES; i++) snpSliceHit[i] = rxSnp_bank == 2'(i);
  end

  assign slice_rxSnpValid = {NUM_SLICES{rxSnp_valid}} & snpSliceHit;
  assign rxSnp_ready      = |(slice_rxSnpReady & snpSliceHit);

  // ===========================================================================
  // §7 RXRSP / RXDAT：按 txnID 分发；还原 slice / MMIO 内部 txnID
  // ===========================================================================
  // restoreTXNID：MMIO → {0, txnID[10:0]}；可缓存 → {0, 00, txnID[8:0]}（去掉 slice 号）
  function automatic logic [11:0] restore_txnID(input logic [11:0] txnID);
    restore_txnID = txnID[11] ? {1'b0, txnID[10:0]} : {3'b000, txnID[8:0]};
  endfunction

  logic                  rspIsMMIO, rspIsPCrdGrant;
  logic [NUM_SLICES-1:0] rspSliceHit;
  logic                  datIsMMIO;
  logic [NUM_SLICES-1:0] datSliceHit;

  assign rspIsMMIO      = rxRsp_txnID[11];
  assign rspIsPCrdGrant = rxRsp_valid & (rxRsp_opcode == CHI_RSP_PCRDGRANT);
  assign datIsMMIO      = rxDat_txnID[11];

  always_comb begin
    for (int i = 0; i < NUM_SLICES; i++) begin
      rspSliceHit[i] = rxRsp_txnID[10:9] == 2'(i);
      datSliceHit[i] = rxDat_txnID[10:9] == 2'(i);
    end
  end

  assign slice_rxRspValid = {NUM_SLICES{rxRsp_valid & ~rspIsMMIO & ~rspIsPCrdGrant}} & rspSliceHit;
  assign mmio_rxRspValid  = rxRsp_valid & rspIsMMIO & ~rspIsPCrdGrant;
  assign rxRsp_innerTxnID = restore_txnID(rxRsp_txnID);
  assign rxRsp_ready      = (rxRsp_opcode == CHI_RSP_PCRDGRANT)
                            | (rspIsMMIO ? mmio_rxRspReady : |(slice_rxRspReady & rspSliceHit));

  assign slice_rxDatValid = {NUM_SLICES{rxDat_valid & ~datIsMMIO}} & datSliceHit;
  assign mmio_rxDatValid  = rxDat_valid & datIsMMIO;
  assign rxDat_innerTxnID = restore_txnID(rxDat_txnID);
  assign rxDat_ready      = datIsMMIO ? mmio_rxDatReady : |(slice_rxDatReady & datSliceHit);

  // ===========================================================================
  // §8 P-Credit：收到 PCrdGrant 打一拍入队；队头与各 MSHR 的查询比对
  // ===========================================================================
  always_ff @(posedge clock) begin
    pcrdEnq_valid    <= rspIsPCrdGrant;
    pcrdEnq_pCrdType <= rxRsp_pCrdType;
    pcrdEnq_srcID    <= rxRsp_srcID;
  end

  always_comb begin
    for (int k = 0; k < NUM_PCRD; k++) begin
      pcrdHit[k] = pcrdQuery_valid[k] & pcrdHead_valid
                   & (pcrdQuery_pCrdType[k] == pcrdHead_pCrdType)
                   & (pcrdQuery_srcID[k] == pcrdHead_srcID);
    end
  end

  // 授出计数（Scala dontTouch，无读者）
  logic [63:0] grantCnt;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)                 grantCnt <= 64'h0;
    else if (pcrdArb_outValid) grantCnt <= grantCnt + 64'h1;
  end

endmodule

// BEGIN GENERATED(tl2chi-wrapper)
module TL2CHICoupledL2 (
  input           clock,
  input           reset,
  output          auto_mmioBridge_mmio_in_a_ready,
  input           auto_mmioBridge_mmio_in_a_valid,
  input  [3:0]    auto_mmioBridge_mmio_in_a_bits_opcode,
  input  [2:0]    auto_mmioBridge_mmio_in_a_bits_param,
  input  [1:0]    auto_mmioBridge_mmio_in_a_bits_size,
  input  [4:0]    auto_mmioBridge_mmio_in_a_bits_source,
  input  [47:0]   auto_mmioBridge_mmio_in_a_bits_address,
  input           auto_mmioBridge_mmio_in_a_bits_user_memBackType_MM,
  input           auto_mmioBridge_mmio_in_a_bits_user_memPageType_NC,
  input  [7:0]    auto_mmioBridge_mmio_in_a_bits_mask,
  input  [63:0]   auto_mmioBridge_mmio_in_a_bits_data,
  input           auto_mmioBridge_mmio_in_a_bits_corrupt,
  input           auto_mmioBridge_mmio_in_d_ready,
  output          auto_mmioBridge_mmio_in_d_valid,
  output [3:0]    auto_mmioBridge_mmio_in_d_bits_opcode,
  output [1:0]    auto_mmioBridge_mmio_in_d_bits_param,
  output [1:0]    auto_mmioBridge_mmio_in_d_bits_size,
  output [4:0]    auto_mmioBridge_mmio_in_d_bits_source,
  output          auto_mmioBridge_mmio_in_d_bits_sink,
  output          auto_mmioBridge_mmio_in_d_bits_denied,
  output [63:0]   auto_mmioBridge_mmio_in_d_bits_data,
  output          auto_mmioBridge_mmio_in_d_bits_corrupt,
  output          auto_in_3_a_ready,
  input           auto_in_3_a_valid,
  input  [3:0]    auto_in_3_a_bits_opcode,
  input  [2:0]    auto_in_3_a_bits_param,
  input  [2:0]    auto_in_3_a_bits_size,
  input  [6:0]    auto_in_3_a_bits_source,
  input  [47:0]   auto_in_3_a_bits_address,
  input  [4:0]    auto_in_3_a_bits_user_reqSource,
  input  [1:0]    auto_in_3_a_bits_user_alias,
  input  [43:0]   auto_in_3_a_bits_user_vaddr,
  input           auto_in_3_a_bits_user_needHint,
  input           auto_in_3_a_bits_echo_isKeyword,
  input           auto_in_3_a_bits_corrupt,
  input           auto_in_3_b_ready,
  output          auto_in_3_b_valid,
  output [2:0]    auto_in_3_b_bits_opcode,
  output [1:0]    auto_in_3_b_bits_param,
  output [47:0]   auto_in_3_b_bits_address,
  output [255:0]  auto_in_3_b_bits_data,
  output          auto_in_3_c_ready,
  input           auto_in_3_c_valid,
  input  [2:0]    auto_in_3_c_bits_opcode,
  input  [2:0]    auto_in_3_c_bits_param,
  input  [2:0]    auto_in_3_c_bits_size,
  input  [6:0]    auto_in_3_c_bits_source,
  input  [47:0]   auto_in_3_c_bits_address,
  input  [255:0]  auto_in_3_c_bits_data,
  input           auto_in_3_c_bits_corrupt,
  input           auto_in_3_d_ready,
  output          auto_in_3_d_valid,
  output [3:0]    auto_in_3_d_bits_opcode,
  output [1:0]    auto_in_3_d_bits_param,
  output [6:0]    auto_in_3_d_bits_source,
  output [7:0]    auto_in_3_d_bits_sink,
  output          auto_in_3_d_bits_denied,
  output          auto_in_3_d_bits_echo_isKeyword,
  output [255:0]  auto_in_3_d_bits_data,
  output          auto_in_3_d_bits_corrupt,
  input           auto_in_3_e_valid,
  input  [7:0]    auto_in_3_e_bits_sink,
  output          auto_in_2_a_ready,
  input           auto_in_2_a_valid,
  input  [3:0]    auto_in_2_a_bits_opcode,
  input  [2:0]    auto_in_2_a_bits_param,
  input  [2:0]    auto_in_2_a_bits_size,
  input  [6:0]    auto_in_2_a_bits_source,
  input  [47:0]   auto_in_2_a_bits_address,
  input  [4:0]    auto_in_2_a_bits_user_reqSource,
  input  [1:0]    auto_in_2_a_bits_user_alias,
  input  [43:0]   auto_in_2_a_bits_user_vaddr,
  input           auto_in_2_a_bits_user_needHint,
  input           auto_in_2_a_bits_echo_isKeyword,
  input           auto_in_2_a_bits_corrupt,
  input           auto_in_2_b_ready,
  output          auto_in_2_b_valid,
  output [2:0]    auto_in_2_b_bits_opcode,
  output [1:0]    auto_in_2_b_bits_param,
  output [47:0]   auto_in_2_b_bits_address,
  output [255:0]  auto_in_2_b_bits_data,
  output          auto_in_2_c_ready,
  input           auto_in_2_c_valid,
  input  [2:0]    auto_in_2_c_bits_opcode,
  input  [2:0]    auto_in_2_c_bits_param,
  input  [2:0]    auto_in_2_c_bits_size,
  input  [6:0]    auto_in_2_c_bits_source,
  input  [47:0]   auto_in_2_c_bits_address,
  input  [255:0]  auto_in_2_c_bits_data,
  input           auto_in_2_c_bits_corrupt,
  input           auto_in_2_d_ready,
  output          auto_in_2_d_valid,
  output [3:0]    auto_in_2_d_bits_opcode,
  output [1:0]    auto_in_2_d_bits_param,
  output [6:0]    auto_in_2_d_bits_source,
  output [7:0]    auto_in_2_d_bits_sink,
  output          auto_in_2_d_bits_denied,
  output          auto_in_2_d_bits_echo_isKeyword,
  output [255:0]  auto_in_2_d_bits_data,
  output          auto_in_2_d_bits_corrupt,
  input           auto_in_2_e_valid,
  input  [7:0]    auto_in_2_e_bits_sink,
  output          auto_in_1_a_ready,
  input           auto_in_1_a_valid,
  input  [3:0]    auto_in_1_a_bits_opcode,
  input  [2:0]    auto_in_1_a_bits_param,
  input  [2:0]    auto_in_1_a_bits_size,
  input  [6:0]    auto_in_1_a_bits_source,
  input  [47:0]   auto_in_1_a_bits_address,
  input  [4:0]    auto_in_1_a_bits_user_reqSource,
  input  [1:0]    auto_in_1_a_bits_user_alias,
  input  [43:0]   auto_in_1_a_bits_user_vaddr,
  input           auto_in_1_a_bits_user_needHint,
  input           auto_in_1_a_bits_echo_isKeyword,
  input           auto_in_1_a_bits_corrupt,
  input           auto_in_1_b_ready,
  output          auto_in_1_b_valid,
  output [2:0]    auto_in_1_b_bits_opcode,
  output [1:0]    auto_in_1_b_bits_param,
  output [47:0]   auto_in_1_b_bits_address,
  output [255:0]  auto_in_1_b_bits_data,
  output          auto_in_1_c_ready,
  input           auto_in_1_c_valid,
  input  [2:0]    auto_in_1_c_bits_opcode,
  input  [2:0]    auto_in_1_c_bits_param,
  input  [2:0]    auto_in_1_c_bits_size,
  input  [6:0]    auto_in_1_c_bits_source,
  input  [47:0]   auto_in_1_c_bits_address,
  input  [255:0]  auto_in_1_c_bits_data,
  input           auto_in_1_c_bits_corrupt,
  input           auto_in_1_d_ready,
  output          auto_in_1_d_valid,
  output [3:0]    auto_in_1_d_bits_opcode,
  output [1:0]    auto_in_1_d_bits_param,
  output [6:0]    auto_in_1_d_bits_source,
  output [7:0]    auto_in_1_d_bits_sink,
  output          auto_in_1_d_bits_denied,
  output          auto_in_1_d_bits_echo_isKeyword,
  output [255:0]  auto_in_1_d_bits_data,
  output          auto_in_1_d_bits_corrupt,
  input           auto_in_1_e_valid,
  input  [7:0]    auto_in_1_e_bits_sink,
  output          auto_in_0_a_ready,
  input           auto_in_0_a_valid,
  input  [3:0]    auto_in_0_a_bits_opcode,
  input  [2:0]    auto_in_0_a_bits_param,
  input  [2:0]    auto_in_0_a_bits_size,
  input  [6:0]    auto_in_0_a_bits_source,
  input  [47:0]   auto_in_0_a_bits_address,
  input  [4:0]    auto_in_0_a_bits_user_reqSource,
  input  [1:0]    auto_in_0_a_bits_user_alias,
  input  [43:0]   auto_in_0_a_bits_user_vaddr,
  input           auto_in_0_a_bits_user_needHint,
  input           auto_in_0_a_bits_echo_isKeyword,
  input           auto_in_0_a_bits_corrupt,
  input           auto_in_0_b_ready,
  output          auto_in_0_b_valid,
  output [2:0]    auto_in_0_b_bits_opcode,
  output [1:0]    auto_in_0_b_bits_param,
  output [47:0]   auto_in_0_b_bits_address,
  output [255:0]  auto_in_0_b_bits_data,
  output          auto_in_0_c_ready,
  input           auto_in_0_c_valid,
  input  [2:0]    auto_in_0_c_bits_opcode,
  input  [2:0]    auto_in_0_c_bits_param,
  input  [2:0]    auto_in_0_c_bits_size,
  input  [6:0]    auto_in_0_c_bits_source,
  input  [47:0]   auto_in_0_c_bits_address,
  input  [255:0]  auto_in_0_c_bits_data,
  input           auto_in_0_c_bits_corrupt,
  input           auto_in_0_d_ready,
  output          auto_in_0_d_valid,
  output [3:0]    auto_in_0_d_bits_opcode,
  output [1:0]    auto_in_0_d_bits_param,
  output [6:0]    auto_in_0_d_bits_source,
  output [7:0]    auto_in_0_d_bits_sink,
  output          auto_in_0_d_bits_denied,
  output          auto_in_0_d_bits_echo_isKeyword,
  output [255:0]  auto_in_0_d_bits_data,
  output          auto_in_0_d_bits_corrupt,
  input           auto_in_0_e_valid,
  input  [7:0]    auto_in_0_e_bits_sink,
  input  [63:0]   auto_pf_recv_in_addr,
  input  [4:0]    auto_pf_recv_in_pf_source,
  input           auto_pf_recv_in_addr_valid,
  input           io_pfCtrlFromCore_l2_pf_master_en,
  input           io_pfCtrlFromCore_l2_pf_recv_en,
  input           io_pfCtrlFromCore_l2_pbop_en,
  input           io_pfCtrlFromCore_l2_vbop_en,
  input  [9:0]    io_pfCtrlFromCore_l2_pf_delay_latency,
  output          io_l2_hint_valid,
  output [31:0]   io_l2_hint_bits_sourceId,
  output          io_l2_hint_bits_isKeyword,
  output          io_l2_tlb_req_req_valid,
  output [49:0]   io_l2_tlb_req_req_bits_vaddr,
  output [2:0]    io_l2_tlb_req_req_bits_cmd,
  output          io_l2_tlb_req_req_bits_isPrefetch,
  output          io_l2_tlb_req_req_bits_kill,
  output          io_l2_tlb_req_req_bits_no_translate,
  input           io_l2_tlb_req_resp_valid,
  input  [47:0]   io_l2_tlb_req_resp_bits_paddr_0,
  input  [1:0]    io_l2_tlb_req_resp_bits_pbmt,
  input           io_l2_tlb_req_resp_bits_miss,
  input           io_l2_tlb_req_resp_bits_excp_0_gpf_ld,
  input           io_l2_tlb_req_resp_bits_excp_0_pf_ld,
  input           io_l2_tlb_req_resp_bits_excp_0_af_ld,
  input           io_l2_tlb_req_pmp_resp_ld,
  input           io_l2_tlb_req_pmp_resp_mmio,
  input           io_debugTopDown_robHeadPaddr_valid,
  input  [35:0]   io_debugTopDown_robHeadPaddr_bits,
  output          io_debugTopDown_l2MissMatch,
  output          io_l2Miss,
  output          io_error_valid,
  output [45:0]   io_error_address,
  input           io_dft_ram_hold,
  input           io_dft_ram_bypass,
  input           io_dft_ram_bp_clken,
  input           io_dft_ram_aux_clk,
  input           io_dft_ram_aux_ckbp,
  input           io_dft_ram_mcp_hold,
  input           io_dft_cgen,
  output [5:0]    io_perf_1_value,
  output [5:0]    io_perf_2_value,
  output [5:0]    io_perf_3_value,
  output [5:0]    io_perf_4_value,
  output [5:0]    io_perf_5_value,
  output [5:0]    io_perf_6_value,
  output [5:0]    io_perf_7_value,
  output [5:0]    io_perf_8_value,
  output [5:0]    io_perf_9_value,
  output [5:0]    io_perf_10_value,
  output [5:0]    io_perf_11_value,
  output [5:0]    io_perf_12_value,
  output [5:0]    io_perf_13_value,
  output [5:0]    io_perf_14_value,
  output [5:0]    io_perf_15_value,
  output [5:0]    io_perf_16_value,
  output [5:0]    io_perf_17_value,
  output [5:0]    io_perf_18_value,
  output [5:0]    io_perf_19_value,
  output [5:0]    io_perf_20_value,
  output [5:0]    io_perf_21_value,
  output [5:0]    io_perf_22_value,
  output [5:0]    io_perf_23_value,
  output [5:0]    io_perf_24_value,
  output [5:0]    io_perf_25_value,
  output [5:0]    io_perf_26_value,
  output [5:0]    io_perf_27_value,
  output [5:0]    io_perf_28_value,
  output [5:0]    io_perf_29_value,
  output [5:0]    io_perf_30_value,
  output [5:0]    io_perf_31_value,
  output [5:0]    io_perf_32_value,
  output [5:0]    io_perf_33_value,
  output [5:0]    io_perf_34_value,
  output [5:0]    io_perf_35_value,
  output [5:0]    io_perf_36_value,
  output [5:0]    io_perf_37_value,
  output [5:0]    io_perf_38_value,
  output [5:0]    io_perf_39_value,
  output [5:0]    io_perf_40_value,
  output [5:0]    io_perf_41_value,
  output [5:0]    io_perf_42_value,
  output [5:0]    io_perf_43_value,
  output [5:0]    io_perf_44_value,
  output [5:0]    io_perf_45_value,
  output [5:0]    io_perf_46_value,
  output [5:0]    io_perf_47_value,
  output [5:0]    io_perf_48_value,
  output [5:0]    io_perf_49_value,
  output [5:0]    io_perf_50_value,
  output [5:0]    io_perf_51_value,
  output [5:0]    io_perf_52_value,
  output [5:0]    io_perf_53_value,
  output [5:0]    io_perf_54_value,
  output [5:0]    io_perf_55_value,
  output [5:0]    io_perf_56_value,
  output [5:0]    io_perf_57_value,
  output [5:0]    io_perf_58_value,
  output [5:0]    io_perf_59_value,
  output [5:0]    io_perf_60_value,
  output [5:0]    io_perf_61_value,
  output [5:0]    io_perf_62_value,
  output [5:0]    io_perf_63_value,
  output [5:0]    io_perf_64_value,
  output [5:0]    io_perf_65_value,
  output [5:0]    io_perf_66_value,
  output [5:0]    io_perf_67_value,
  output [5:0]    io_perf_68_value,
  output          io_chi_txsactive,
  input           io_chi_rxsactive,
  output          io_chi_syscoreq,
  input           io_chi_syscoack,
  output          io_chi_tx_linkactivereq,
  input           io_chi_tx_linkactiveack,
  output          io_chi_tx_req_flitpend,
  output          io_chi_tx_req_flitv,
  output [161:0]  io_chi_tx_req_flit,
  input           io_chi_tx_req_lcrdv,
  output          io_chi_tx_rsp_flitpend,
  output          io_chi_tx_rsp_flitv,
  output [72:0]   io_chi_tx_rsp_flit,
  input           io_chi_tx_rsp_lcrdv,
  output          io_chi_tx_dat_flitpend,
  output          io_chi_tx_dat_flitv,
  output [421:0]  io_chi_tx_dat_flit,
  input           io_chi_tx_dat_lcrdv,
  input           io_chi_rx_linkactivereq,
  output          io_chi_rx_linkactiveack,
  input           io_chi_rx_rsp_flitpend,
  input           io_chi_rx_rsp_flitv,
  input  [72:0]   io_chi_rx_rsp_flit,
  output          io_chi_rx_rsp_lcrdv,
  input           io_chi_rx_dat_flitpend,
  input           io_chi_rx_dat_flitv,
  input  [421:0]  io_chi_rx_dat_flit,
  output          io_chi_rx_dat_lcrdv,
  input           io_chi_rx_snp_flitpend,
  input           io_chi_rx_snp_flitv,
  input  [114:0]  io_chi_rx_snp_flit,
  output          io_chi_rx_snp_lcrdv,
  input  [10:0]   io_nodeID
);

  // ---- child 输出线（<实例名>_<端口名>）----
  logic [31:0] hintPipe1_io_out_bits;
  logic hintPipe1_io_out_valid;
  logic [31:0] hintPipe2_io_out_bits;
  logic hintPipe2_io_out_valid;
  logic [1:0] l1HintArb_io_chosen;
  logic l1HintArb_io_in_0_ready;
  logic l1HintArb_io_in_1_ready;
  logic l1HintArb_io_in_2_ready;
  logic l1HintArb_io_in_3_ready;
  logic [31:0] l1HintArb_io_out_bits_sourceId;
  logic l1HintArb_io_out_valid;
  logic l2ECCArb_io_out_bits_valid;
  logic l2ECCArb_io_out_valid;
  logic [12:0] l2MbistIntf_toPipeline_0_addr;
  logic [12:0] l2MbistIntf_toPipeline_0_addr_rd;
  logic l2MbistIntf_toPipeline_0_all;
  logic [5:0] l2MbistIntf_toPipeline_0_array;
  logic [7:0] l2MbistIntf_toPipeline_0_be;
  logic [136:0] l2MbistIntf_toPipeline_0_indata;
  logic l2MbistIntf_toPipeline_0_readen;
  logic l2MbistIntf_toPipeline_0_req;
  logic l2MbistIntf_toPipeline_0_writeen;
  logic [31:0] linkMonitor_io_in_rx_dat_bits_be;
  logic [2:0] linkMonitor_io_in_rx_dat_bits_cBusy;
  logic [1:0] linkMonitor_io_in_rx_dat_bits_ccID;
  logic [255:0] linkMonitor_io_in_rx_dat_bits_data;
  logic [31:0] linkMonitor_io_in_rx_dat_bits_dataCheck;
  logic [1:0] linkMonitor_io_in_rx_dat_bits_dataID;
  logic [3:0] linkMonitor_io_in_rx_dat_bits_dataSource;
  logic [11:0] linkMonitor_io_in_rx_dat_bits_dbID;
  logic [10:0] linkMonitor_io_in_rx_dat_bits_homeNID;
  logic [3:0] linkMonitor_io_in_rx_dat_bits_opcode;
  logic [3:0] linkMonitor_io_in_rx_dat_bits_poison;
  logic [3:0] linkMonitor_io_in_rx_dat_bits_qos;
  logic [2:0] linkMonitor_io_in_rx_dat_bits_resp;
  logic [1:0] linkMonitor_io_in_rx_dat_bits_respErr;
  logic [3:0] linkMonitor_io_in_rx_dat_bits_rsvdc;
  logic [10:0] linkMonitor_io_in_rx_dat_bits_srcID;
  logic [7:0] linkMonitor_io_in_rx_dat_bits_tag;
  logic [1:0] linkMonitor_io_in_rx_dat_bits_tagOp;
  logic [10:0] linkMonitor_io_in_rx_dat_bits_tgtID;
  logic linkMonitor_io_in_rx_dat_bits_traceTag;
  logic [1:0] linkMonitor_io_in_rx_dat_bits_tu;
  logic [11:0] linkMonitor_io_in_rx_dat_bits_txnID;
  logic linkMonitor_io_in_rx_dat_valid;
  logic [2:0] linkMonitor_io_in_rx_rsp_bits_cBusy;
  logic [11:0] linkMonitor_io_in_rx_rsp_bits_dbID;
  logic [2:0] linkMonitor_io_in_rx_rsp_bits_fwdState;
  logic [4:0] linkMonitor_io_in_rx_rsp_bits_opcode;
  logic [3:0] linkMonitor_io_in_rx_rsp_bits_pCrdType;
  logic [3:0] linkMonitor_io_in_rx_rsp_bits_qos;
  logic [2:0] linkMonitor_io_in_rx_rsp_bits_resp;
  logic [1:0] linkMonitor_io_in_rx_rsp_bits_respErr;
  logic [10:0] linkMonitor_io_in_rx_rsp_bits_srcID;
  logic [1:0] linkMonitor_io_in_rx_rsp_bits_tagOp;
  logic [10:0] linkMonitor_io_in_rx_rsp_bits_tgtID;
  logic linkMonitor_io_in_rx_rsp_bits_traceTag;
  logic [11:0] linkMonitor_io_in_rx_rsp_bits_txnID;
  logic linkMonitor_io_in_rx_rsp_valid;
  logic [44:0] linkMonitor_io_in_rx_snp_bits_addr;
  logic linkMonitor_io_in_rx_snp_bits_doNotGoToSD;
  logic [10:0] linkMonitor_io_in_rx_snp_bits_fwdNID;
  logic [11:0] linkMonitor_io_in_rx_snp_bits_fwdTxnID;
  logic linkMonitor_io_in_rx_snp_bits_mpam_mpamNS;
  logic [8:0] linkMonitor_io_in_rx_snp_bits_mpam_partID;
  logic linkMonitor_io_in_rx_snp_bits_mpam_perfMonGroup;
  logic linkMonitor_io_in_rx_snp_bits_ns;
  logic [4:0] linkMonitor_io_in_rx_snp_bits_opcode;
  logic [3:0] linkMonitor_io_in_rx_snp_bits_qos;
  logic linkMonitor_io_in_rx_snp_bits_retToSrc;
  logic [10:0] linkMonitor_io_in_rx_snp_bits_srcID;
  logic linkMonitor_io_in_rx_snp_bits_traceTag;
  logic [11:0] linkMonitor_io_in_rx_snp_bits_txnID;
  logic linkMonitor_io_in_rx_snp_valid;
  logic linkMonitor_io_in_tx_dat_ready;
  logic linkMonitor_io_in_tx_req_ready;
  logic linkMonitor_io_in_tx_rsp_ready;
  logic linkMonitor_io_out_syscoreq;
  logic mbistPl_mbist_ack;
  logic [136:0] mbistPl_mbist_outdata;
  logic [8:0] mbistPl_toNextPipeline_0_addr;
  logic [8:0] mbistPl_toNextPipeline_0_addr_rd;
  logic mbistPl_toNextPipeline_0_all;
  logic mbistPl_toNextPipeline_0_array;
  logic mbistPl_toNextPipeline_0_be;
  logic [12:0] mbistPl_toNextPipeline_0_indata;
  logic mbistPl_toNextPipeline_0_readen;
  logic mbistPl_toNextPipeline_0_req;
  logic mbistPl_toNextPipeline_0_writeen;
  logic [12:0] mbistPl_toNextPipeline_1_addr;
  logic [12:0] mbistPl_toNextPipeline_1_addr_rd;
  logic mbistPl_toNextPipeline_1_all;
  logic [3:0] mbistPl_toNextPipeline_1_array;
  logic [7:0] mbistPl_toNextPipeline_1_be;
  logic [136:0] mbistPl_toNextPipeline_1_indata;
  logic mbistPl_toNextPipeline_1_readen;
  logic mbistPl_toNextPipeline_1_req;
  logic mbistPl_toNextPipeline_1_writeen;
  logic [12:0] mbistPl_toNextPipeline_2_addr;
  logic [12:0] mbistPl_toNextPipeline_2_addr_rd;
  logic mbistPl_toNextPipeline_2_all;
  logic [4:0] mbistPl_toNextPipeline_2_array;
  logic [7:0] mbistPl_toNextPipeline_2_be;
  logic [136:0] mbistPl_toNextPipeline_2_indata;
  logic mbistPl_toNextPipeline_2_readen;
  logic mbistPl_toNextPipeline_2_req;
  logic mbistPl_toNextPipeline_2_writeen;
  logic [12:0] mbistPl_toNextPipeline_3_addr;
  logic [12:0] mbistPl_toNextPipeline_3_addr_rd;
  logic mbistPl_toNextPipeline_3_all;
  logic [5:0] mbistPl_toNextPipeline_3_array;
  logic [7:0] mbistPl_toNextPipeline_3_be;
  logic [136:0] mbistPl_toNextPipeline_3_indata;
  logic mbistPl_toNextPipeline_3_readen;
  logic mbistPl_toNextPipeline_3_req;
  logic mbistPl_toNextPipeline_3_writeen;
  logic [12:0] mbistPl_toNextPipeline_4_addr;
  logic [12:0] mbistPl_toNextPipeline_4_addr_rd;
  logic mbistPl_toNextPipeline_4_all;
  logic [5:0] mbistPl_toNextPipeline_4_array;
  logic [7:0] mbistPl_toNextPipeline_4_be;
  logic [136:0] mbistPl_toNextPipeline_4_indata;
  logic mbistPl_toNextPipeline_4_readen;
  logic mbistPl_toNextPipeline_4_req;
  logic mbistPl_toNextPipeline_4_writeen;
  logic [3:0] mmioBridge_io_pCrd_0_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_0_query_bits_srcID;
  logic mmioBridge_io_pCrd_0_query_valid;
  logic [3:0] mmioBridge_io_pCrd_1_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_1_query_bits_srcID;
  logic mmioBridge_io_pCrd_1_query_valid;
  logic [3:0] mmioBridge_io_pCrd_2_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_2_query_bits_srcID;
  logic mmioBridge_io_pCrd_2_query_valid;
  logic [3:0] mmioBridge_io_pCrd_3_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_3_query_bits_srcID;
  logic mmioBridge_io_pCrd_3_query_valid;
  logic [3:0] mmioBridge_io_pCrd_4_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_4_query_bits_srcID;
  logic mmioBridge_io_pCrd_4_query_valid;
  logic [3:0] mmioBridge_io_pCrd_5_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_5_query_bits_srcID;
  logic mmioBridge_io_pCrd_5_query_valid;
  logic [3:0] mmioBridge_io_pCrd_6_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_6_query_bits_srcID;
  logic mmioBridge_io_pCrd_6_query_valid;
  logic [3:0] mmioBridge_io_pCrd_7_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_7_query_bits_srcID;
  logic mmioBridge_io_pCrd_7_query_valid;
  logic [3:0] mmioBridge_io_pCrd_8_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_8_query_bits_srcID;
  logic mmioBridge_io_pCrd_8_query_valid;
  logic [3:0] mmioBridge_io_pCrd_9_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_9_query_bits_srcID;
  logic mmioBridge_io_pCrd_9_query_valid;
  logic [3:0] mmioBridge_io_pCrd_10_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_10_query_bits_srcID;
  logic mmioBridge_io_pCrd_10_query_valid;
  logic [3:0] mmioBridge_io_pCrd_11_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_11_query_bits_srcID;
  logic mmioBridge_io_pCrd_11_query_valid;
  logic [3:0] mmioBridge_io_pCrd_12_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_12_query_bits_srcID;
  logic mmioBridge_io_pCrd_12_query_valid;
  logic [3:0] mmioBridge_io_pCrd_13_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_13_query_bits_srcID;
  logic mmioBridge_io_pCrd_13_query_valid;
  logic [3:0] mmioBridge_io_pCrd_14_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_14_query_bits_srcID;
  logic mmioBridge_io_pCrd_14_query_valid;
  logic [3:0] mmioBridge_io_pCrd_15_query_bits_pCrdType;
  logic [10:0] mmioBridge_io_pCrd_15_query_bits_srcID;
  logic mmioBridge_io_pCrd_15_query_valid;
  logic mmioBridge_io_rx_dat_ready;
  logic mmioBridge_io_rx_rsp_ready;
  logic [31:0] mmioBridge_io_tx_dat_bits_be;
  logic [2:0] mmioBridge_io_tx_dat_bits_cBusy;
  logic [1:0] mmioBridge_io_tx_dat_bits_ccID;
  logic [255:0] mmioBridge_io_tx_dat_bits_data;
  logic [31:0] mmioBridge_io_tx_dat_bits_dataCheck;
  logic [1:0] mmioBridge_io_tx_dat_bits_dataID;
  logic [3:0] mmioBridge_io_tx_dat_bits_dataSource;
  logic [11:0] mmioBridge_io_tx_dat_bits_dbID;
  logic [10:0] mmioBridge_io_tx_dat_bits_homeNID;
  logic [3:0] mmioBridge_io_tx_dat_bits_opcode;
  logic [3:0] mmioBridge_io_tx_dat_bits_poison;
  logic [3:0] mmioBridge_io_tx_dat_bits_qos;
  logic [2:0] mmioBridge_io_tx_dat_bits_resp;
  logic [1:0] mmioBridge_io_tx_dat_bits_respErr;
  logic [3:0] mmioBridge_io_tx_dat_bits_rsvdc;
  logic [7:0] mmioBridge_io_tx_dat_bits_tag;
  logic [1:0] mmioBridge_io_tx_dat_bits_tagOp;
  logic [10:0] mmioBridge_io_tx_dat_bits_tgtID;
  logic mmioBridge_io_tx_dat_bits_traceTag;
  logic [1:0] mmioBridge_io_tx_dat_bits_tu;
  logic [11:0] mmioBridge_io_tx_dat_bits_txnID;
  logic mmioBridge_io_tx_dat_valid;
  logic [47:0] mmioBridge_io_tx_req_bits_addr;
  logic mmioBridge_io_tx_req_bits_allowRetry;
  logic mmioBridge_io_tx_req_bits_expCompAck;
  logic mmioBridge_io_tx_req_bits_likelyshared;
  logic [7:0] mmioBridge_io_tx_req_bits_lpIDWithPadding;
  logic mmioBridge_io_tx_req_bits_memAttr_allocate;
  logic mmioBridge_io_tx_req_bits_memAttr_cacheable;
  logic mmioBridge_io_tx_req_bits_memAttr_device;
  logic mmioBridge_io_tx_req_bits_memAttr_ewa;
  logic mmioBridge_io_tx_req_bits_mpam_mpamNS;
  logic [8:0] mmioBridge_io_tx_req_bits_mpam_partID;
  logic mmioBridge_io_tx_req_bits_mpam_perfMonGroup;
  logic mmioBridge_io_tx_req_bits_ns;
  logic [6:0] mmioBridge_io_tx_req_bits_opcode;
  logic [1:0] mmioBridge_io_tx_req_bits_order;
  logic [3:0] mmioBridge_io_tx_req_bits_pCrdType;
  logic [3:0] mmioBridge_io_tx_req_bits_qos;
  logic [10:0] mmioBridge_io_tx_req_bits_returnNID;
  logic [11:0] mmioBridge_io_tx_req_bits_returnTxnID;
  logic [3:0] mmioBridge_io_tx_req_bits_rsvdc;
  logic [2:0] mmioBridge_io_tx_req_bits_size;
  logic mmioBridge_io_tx_req_bits_snoopMe;
  logic mmioBridge_io_tx_req_bits_snpAttr;
  logic mmioBridge_io_tx_req_bits_stashNIDValid;
  logic [1:0] mmioBridge_io_tx_req_bits_tagOp;
  logic [10:0] mmioBridge_io_tx_req_bits_tgtID;
  logic mmioBridge_io_tx_req_bits_traceTag;
  logic [11:0] mmioBridge_io_tx_req_bits_txnID;
  logic mmioBridge_io_tx_req_valid;
  logic [3:0] pCrdQueue_s2_io_deq_bits_pCrdType;
  logic [10:0] pCrdQueue_s2_io_deq_bits_srcID;
  logic pCrdQueue_s2_io_deq_valid;
  logic pCrdQueue_s2_io_enq_ready;
  logic [3:0] pCrdQueue_s3_io_deq_bits_pCrdType;
  logic [10:0] pCrdQueue_s3_io_deq_bits_srcID;
  logic pCrdQueue_s3_io_deq_valid;
  logic pCrdQueue_s3_io_enq_ready;
  logic pcrdgrant_arb_io_in_0_ready;
  logic pcrdgrant_arb_io_in_1_ready;
  logic pcrdgrant_arb_io_in_2_ready;
  logic pcrdgrant_arb_io_in_3_ready;
  logic pcrdgrant_arb_io_in_4_ready;
  logic pcrdgrant_arb_io_in_5_ready;
  logic pcrdgrant_arb_io_in_6_ready;
  logic pcrdgrant_arb_io_in_7_ready;
  logic pcrdgrant_arb_io_in_8_ready;
  logic pcrdgrant_arb_io_in_9_ready;
  logic pcrdgrant_arb_io_in_10_ready;
  logic pcrdgrant_arb_io_in_11_ready;
  logic pcrdgrant_arb_io_in_12_ready;
  logic pcrdgrant_arb_io_in_13_ready;
  logic pcrdgrant_arb_io_in_14_ready;
  logic pcrdgrant_arb_io_in_15_ready;
  logic pcrdgrant_arb_io_in_16_ready;
  logic pcrdgrant_arb_io_in_17_ready;
  logic pcrdgrant_arb_io_in_18_ready;
  logic pcrdgrant_arb_io_in_19_ready;
  logic pcrdgrant_arb_io_in_20_ready;
  logic pcrdgrant_arb_io_in_21_ready;
  logic pcrdgrant_arb_io_in_22_ready;
  logic pcrdgrant_arb_io_in_23_ready;
  logic pcrdgrant_arb_io_in_24_ready;
  logic pcrdgrant_arb_io_in_25_ready;
  logic pcrdgrant_arb_io_in_26_ready;
  logic pcrdgrant_arb_io_in_27_ready;
  logic pcrdgrant_arb_io_in_28_ready;
  logic pcrdgrant_arb_io_in_29_ready;
  logic pcrdgrant_arb_io_in_30_ready;
  logic pcrdgrant_arb_io_in_31_ready;
  logic pcrdgrant_arb_io_in_32_ready;
  logic pcrdgrant_arb_io_in_33_ready;
  logic pcrdgrant_arb_io_in_34_ready;
  logic pcrdgrant_arb_io_in_35_ready;
  logic pcrdgrant_arb_io_in_36_ready;
  logic pcrdgrant_arb_io_in_37_ready;
  logic pcrdgrant_arb_io_in_38_ready;
  logic pcrdgrant_arb_io_in_39_ready;
  logic pcrdgrant_arb_io_in_40_ready;
  logic pcrdgrant_arb_io_in_41_ready;
  logic pcrdgrant_arb_io_in_42_ready;
  logic pcrdgrant_arb_io_in_43_ready;
  logic pcrdgrant_arb_io_in_44_ready;
  logic pcrdgrant_arb_io_in_45_ready;
  logic pcrdgrant_arb_io_in_46_ready;
  logic pcrdgrant_arb_io_in_47_ready;
  logic pcrdgrant_arb_io_in_48_ready;
  logic pcrdgrant_arb_io_in_49_ready;
  logic pcrdgrant_arb_io_in_50_ready;
  logic pcrdgrant_arb_io_in_51_ready;
  logic pcrdgrant_arb_io_in_52_ready;
  logic pcrdgrant_arb_io_in_53_ready;
  logic pcrdgrant_arb_io_in_54_ready;
  logic pcrdgrant_arb_io_in_55_ready;
  logic pcrdgrant_arb_io_in_56_ready;
  logic pcrdgrant_arb_io_in_57_ready;
  logic pcrdgrant_arb_io_in_58_ready;
  logic pcrdgrant_arb_io_in_59_ready;
  logic pcrdgrant_arb_io_in_60_ready;
  logic pcrdgrant_arb_io_in_61_ready;
  logic pcrdgrant_arb_io_in_62_ready;
  logic pcrdgrant_arb_io_in_63_ready;
  logic pcrdgrant_arb_io_in_64_ready;
  logic pcrdgrant_arb_io_in_65_ready;
  logic pcrdgrant_arb_io_in_66_ready;
  logic pcrdgrant_arb_io_in_67_ready;
  logic pcrdgrant_arb_io_in_68_ready;
  logic pcrdgrant_arb_io_in_69_ready;
  logic pcrdgrant_arb_io_in_70_ready;
  logic pcrdgrant_arb_io_in_71_ready;
  logic pcrdgrant_arb_io_in_72_ready;
  logic pcrdgrant_arb_io_in_73_ready;
  logic pcrdgrant_arb_io_in_74_ready;
  logic pcrdgrant_arb_io_in_75_ready;
  logic pcrdgrant_arb_io_in_76_ready;
  logic pcrdgrant_arb_io_in_77_ready;
  logic pcrdgrant_arb_io_in_78_ready;
  logic pcrdgrant_arb_io_in_79_ready;
  logic pcrdgrant_arb_io_out_valid;
  logic prefetch_resp_arb_io_in_0_ready;
  logic prefetch_resp_arb_io_in_1_ready;
  logic prefetch_resp_arb_io_in_2_ready;
  logic prefetch_resp_arb_io_in_3_ready;
  logic [4:0] prefetch_resp_arb_io_out_bits_pfSource;
  logic prefetch_resp_arb_io_out_valid;
  logic prefetch_train_arb_io_in_0_ready;
  logic prefetch_train_arb_io_in_1_ready;
  logic prefetch_train_arb_io_in_2_ready;
  logic prefetch_train_arb_io_in_3_ready;
  logic prefetch_train_arb_io_out_bits_needT;
  logic [4:0] prefetch_train_arb_io_out_bits_reqsource;
  logic [8:0] prefetch_train_arb_io_out_bits_set;
  logic [6:0] prefetch_train_arb_io_out_bits_source;
  logic [32:0] prefetch_train_arb_io_out_bits_tag;
  logic [43:0] prefetch_train_arb_io_out_bits_vaddr;
  logic prefetch_train_arb_io_out_valid;
  logic prefetcher_boreChildrenBd_bore_ack;
  logic [12:0] prefetcher_boreChildrenBd_bore_outdata;
  logic prefetcher_io_req_bits_needT;
  logic [4:0] prefetcher_io_req_bits_pfSource;
  logic [8:0] prefetcher_io_req_bits_set;
  logic [6:0] prefetcher_io_req_bits_source;
  logic [32:0] prefetcher_io_req_bits_tag;
  logic [43:0] prefetcher_io_req_bits_vaddr;
  logic prefetcher_io_req_valid;
  logic prefetcher_io_resp_ready;
  logic prefetcher_io_train_ready;
  logic resp_pipeline_1_io_in_ready;
  logic [4:0] resp_pipeline_1_io_out_bits_pfSource;
  logic resp_pipeline_1_io_out_valid;
  logic resp_pipeline_2_io_in_ready;
  logic [4:0] resp_pipeline_2_io_out_bits_pfSource;
  logic resp_pipeline_2_io_out_valid;
  logic resp_pipeline_3_io_in_ready;
  logic [4:0] resp_pipeline_3_io_out_bits_pfSource;
  logic resp_pipeline_3_io_out_valid;
  logic resp_pipeline_io_in_ready;
  logic [4:0] resp_pipeline_io_out_bits_pfSource;
  logic resp_pipeline_io_out_valid;
  logic rxdatPipe_pipeline_io_in_ready;
  logic [31:0] rxdatPipe_pipeline_io_out_bits_be;
  logic [2:0] rxdatPipe_pipeline_io_out_bits_cBusy;
  logic [1:0] rxdatPipe_pipeline_io_out_bits_ccID;
  logic [255:0] rxdatPipe_pipeline_io_out_bits_data;
  logic [31:0] rxdatPipe_pipeline_io_out_bits_dataCheck;
  logic [1:0] rxdatPipe_pipeline_io_out_bits_dataID;
  logic [3:0] rxdatPipe_pipeline_io_out_bits_dataSource;
  logic [11:0] rxdatPipe_pipeline_io_out_bits_dbID;
  logic [10:0] rxdatPipe_pipeline_io_out_bits_homeNID;
  logic [3:0] rxdatPipe_pipeline_io_out_bits_opcode;
  logic [3:0] rxdatPipe_pipeline_io_out_bits_poison;
  logic [3:0] rxdatPipe_pipeline_io_out_bits_qos;
  logic [2:0] rxdatPipe_pipeline_io_out_bits_resp;
  logic [1:0] rxdatPipe_pipeline_io_out_bits_respErr;
  logic [3:0] rxdatPipe_pipeline_io_out_bits_rsvdc;
  logic [10:0] rxdatPipe_pipeline_io_out_bits_srcID;
  logic [7:0] rxdatPipe_pipeline_io_out_bits_tag;
  logic [1:0] rxdatPipe_pipeline_io_out_bits_tagOp;
  logic [10:0] rxdatPipe_pipeline_io_out_bits_tgtID;
  logic rxdatPipe_pipeline_io_out_bits_traceTag;
  logic [1:0] rxdatPipe_pipeline_io_out_bits_tu;
  logic [11:0] rxdatPipe_pipeline_io_out_bits_txnID;
  logic rxdatPipe_pipeline_io_out_valid;
  logic rxrspPipe_pipeline_io_in_ready;
  logic [2:0] rxrspPipe_pipeline_io_out_bits_cBusy;
  logic [11:0] rxrspPipe_pipeline_io_out_bits_dbID;
  logic [2:0] rxrspPipe_pipeline_io_out_bits_fwdState;
  logic [4:0] rxrspPipe_pipeline_io_out_bits_opcode;
  logic [3:0] rxrspPipe_pipeline_io_out_bits_pCrdType;
  logic [3:0] rxrspPipe_pipeline_io_out_bits_qos;
  logic [2:0] rxrspPipe_pipeline_io_out_bits_resp;
  logic [1:0] rxrspPipe_pipeline_io_out_bits_respErr;
  logic [10:0] rxrspPipe_pipeline_io_out_bits_srcID;
  logic [1:0] rxrspPipe_pipeline_io_out_bits_tagOp;
  logic [10:0] rxrspPipe_pipeline_io_out_bits_tgtID;
  logic rxrspPipe_pipeline_io_out_bits_traceTag;
  logic [11:0] rxrspPipe_pipeline_io_out_bits_txnID;
  logic rxrspPipe_pipeline_io_out_valid;
  logic slices_0_boreChildrenBd_bore_ack;
  logic [136:0] slices_0_boreChildrenBd_bore_outdata;
  logic slices_0_io_dirResult_bits_hit;
  logic slices_0_io_dirResult_bits_meta_prefetch;
  logic [2:0] slices_0_io_dirResult_bits_meta_prefetchSrc;
  logic [2:0] slices_0_io_dirResult_bits_replacerInfo_channel;
  logic [4:0] slices_0_io_dirResult_bits_replacerInfo_reqSource;
  logic slices_0_io_dirResult_valid;
  logic [45:0] slices_0_io_error_bits_address;
  logic slices_0_io_error_bits_valid;
  logic slices_0_io_error_valid;
  logic [2:0] slices_0_io_hitPfInMSHR_bits;
  logic slices_0_io_hitPfInMSHR_valid;
  logic [47:0] slices_0_io_in_b_bits_address;
  logic [3:0] slices_0_io_in_d_bits_opcode;
  logic [6:0] slices_0_io_in_d_bits_source;
  logic slices_0_io_in_d_valid;
  logic slices_0_io_l1Hint_bits_isKeyword;
  logic [31:0] slices_0_io_l1Hint_bits_sourceId;
  logic slices_0_io_l1Hint_valid;
  logic slices_0_io_l2Miss;
  logic [2:0] slices_0_io_msAlloc_0_bits_channel;
  logic slices_0_io_msAlloc_0_bits_is_miss;
  logic slices_0_io_msAlloc_0_bits_is_prefetch;
  logic slices_0_io_msAlloc_0_valid;
  logic [2:0] slices_0_io_msAlloc_1_bits_channel;
  logic slices_0_io_msAlloc_1_bits_is_miss;
  logic slices_0_io_msAlloc_1_bits_is_prefetch;
  logic slices_0_io_msAlloc_1_valid;
  logic [2:0] slices_0_io_msAlloc_2_bits_channel;
  logic slices_0_io_msAlloc_2_bits_is_miss;
  logic slices_0_io_msAlloc_2_bits_is_prefetch;
  logic slices_0_io_msAlloc_2_valid;
  logic [2:0] slices_0_io_msAlloc_3_bits_channel;
  logic slices_0_io_msAlloc_3_bits_is_miss;
  logic slices_0_io_msAlloc_3_bits_is_prefetch;
  logic slices_0_io_msAlloc_3_valid;
  logic [2:0] slices_0_io_msAlloc_4_bits_channel;
  logic slices_0_io_msAlloc_4_bits_is_miss;
  logic slices_0_io_msAlloc_4_bits_is_prefetch;
  logic slices_0_io_msAlloc_4_valid;
  logic [2:0] slices_0_io_msAlloc_5_bits_channel;
  logic slices_0_io_msAlloc_5_bits_is_miss;
  logic slices_0_io_msAlloc_5_bits_is_prefetch;
  logic slices_0_io_msAlloc_5_valid;
  logic [2:0] slices_0_io_msAlloc_6_bits_channel;
  logic slices_0_io_msAlloc_6_bits_is_miss;
  logic slices_0_io_msAlloc_6_bits_is_prefetch;
  logic slices_0_io_msAlloc_6_valid;
  logic [2:0] slices_0_io_msAlloc_7_bits_channel;
  logic slices_0_io_msAlloc_7_bits_is_miss;
  logic slices_0_io_msAlloc_7_bits_is_prefetch;
  logic slices_0_io_msAlloc_7_valid;
  logic [2:0] slices_0_io_msAlloc_8_bits_channel;
  logic slices_0_io_msAlloc_8_bits_is_miss;
  logic slices_0_io_msAlloc_8_bits_is_prefetch;
  logic slices_0_io_msAlloc_8_valid;
  logic [2:0] slices_0_io_msAlloc_9_bits_channel;
  logic slices_0_io_msAlloc_9_bits_is_miss;
  logic slices_0_io_msAlloc_9_bits_is_prefetch;
  logic slices_0_io_msAlloc_9_valid;
  logic [2:0] slices_0_io_msAlloc_10_bits_channel;
  logic slices_0_io_msAlloc_10_bits_is_miss;
  logic slices_0_io_msAlloc_10_bits_is_prefetch;
  logic slices_0_io_msAlloc_10_valid;
  logic [2:0] slices_0_io_msAlloc_11_bits_channel;
  logic slices_0_io_msAlloc_11_bits_is_miss;
  logic slices_0_io_msAlloc_11_bits_is_prefetch;
  logic slices_0_io_msAlloc_11_valid;
  logic [2:0] slices_0_io_msAlloc_12_bits_channel;
  logic slices_0_io_msAlloc_12_bits_is_miss;
  logic slices_0_io_msAlloc_12_bits_is_prefetch;
  logic slices_0_io_msAlloc_12_valid;
  logic [2:0] slices_0_io_msAlloc_13_bits_channel;
  logic slices_0_io_msAlloc_13_bits_is_miss;
  logic slices_0_io_msAlloc_13_bits_is_prefetch;
  logic slices_0_io_msAlloc_13_valid;
  logic [2:0] slices_0_io_msAlloc_14_bits_channel;
  logic slices_0_io_msAlloc_14_bits_is_miss;
  logic slices_0_io_msAlloc_14_bits_is_prefetch;
  logic slices_0_io_msAlloc_14_valid;
  logic [2:0] slices_0_io_msAlloc_15_bits_channel;
  logic slices_0_io_msAlloc_15_bits_is_miss;
  logic slices_0_io_msAlloc_15_bits_is_prefetch;
  logic slices_0_io_msAlloc_15_valid;
  logic [2:0] slices_0_io_msStatus_0_bits_channel;
  logic slices_0_io_msStatus_0_bits_is_miss;
  logic slices_0_io_msStatus_0_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_0_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_0_bits_set;
  logic slices_0_io_msStatus_0_valid;
  logic [2:0] slices_0_io_msStatus_1_bits_channel;
  logic slices_0_io_msStatus_1_bits_is_miss;
  logic slices_0_io_msStatus_1_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_1_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_1_bits_set;
  logic slices_0_io_msStatus_1_valid;
  logic [2:0] slices_0_io_msStatus_2_bits_channel;
  logic slices_0_io_msStatus_2_bits_is_miss;
  logic slices_0_io_msStatus_2_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_2_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_2_bits_set;
  logic slices_0_io_msStatus_2_valid;
  logic [2:0] slices_0_io_msStatus_3_bits_channel;
  logic slices_0_io_msStatus_3_bits_is_miss;
  logic slices_0_io_msStatus_3_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_3_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_3_bits_set;
  logic slices_0_io_msStatus_3_valid;
  logic [2:0] slices_0_io_msStatus_4_bits_channel;
  logic slices_0_io_msStatus_4_bits_is_miss;
  logic slices_0_io_msStatus_4_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_4_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_4_bits_set;
  logic slices_0_io_msStatus_4_valid;
  logic [2:0] slices_0_io_msStatus_5_bits_channel;
  logic slices_0_io_msStatus_5_bits_is_miss;
  logic slices_0_io_msStatus_5_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_5_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_5_bits_set;
  logic slices_0_io_msStatus_5_valid;
  logic [2:0] slices_0_io_msStatus_6_bits_channel;
  logic slices_0_io_msStatus_6_bits_is_miss;
  logic slices_0_io_msStatus_6_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_6_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_6_bits_set;
  logic slices_0_io_msStatus_6_valid;
  logic [2:0] slices_0_io_msStatus_7_bits_channel;
  logic slices_0_io_msStatus_7_bits_is_miss;
  logic slices_0_io_msStatus_7_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_7_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_7_bits_set;
  logic slices_0_io_msStatus_7_valid;
  logic [2:0] slices_0_io_msStatus_8_bits_channel;
  logic slices_0_io_msStatus_8_bits_is_miss;
  logic slices_0_io_msStatus_8_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_8_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_8_bits_set;
  logic slices_0_io_msStatus_8_valid;
  logic [2:0] slices_0_io_msStatus_9_bits_channel;
  logic slices_0_io_msStatus_9_bits_is_miss;
  logic slices_0_io_msStatus_9_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_9_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_9_bits_set;
  logic slices_0_io_msStatus_9_valid;
  logic [2:0] slices_0_io_msStatus_10_bits_channel;
  logic slices_0_io_msStatus_10_bits_is_miss;
  logic slices_0_io_msStatus_10_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_10_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_10_bits_set;
  logic slices_0_io_msStatus_10_valid;
  logic [2:0] slices_0_io_msStatus_11_bits_channel;
  logic slices_0_io_msStatus_11_bits_is_miss;
  logic slices_0_io_msStatus_11_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_11_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_11_bits_set;
  logic slices_0_io_msStatus_11_valid;
  logic [2:0] slices_0_io_msStatus_12_bits_channel;
  logic slices_0_io_msStatus_12_bits_is_miss;
  logic slices_0_io_msStatus_12_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_12_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_12_bits_set;
  logic slices_0_io_msStatus_12_valid;
  logic [2:0] slices_0_io_msStatus_13_bits_channel;
  logic slices_0_io_msStatus_13_bits_is_miss;
  logic slices_0_io_msStatus_13_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_13_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_13_bits_set;
  logic slices_0_io_msStatus_13_valid;
  logic [2:0] slices_0_io_msStatus_14_bits_channel;
  logic slices_0_io_msStatus_14_bits_is_miss;
  logic slices_0_io_msStatus_14_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_14_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_14_bits_set;
  logic slices_0_io_msStatus_14_valid;
  logic [2:0] slices_0_io_msStatus_15_bits_channel;
  logic slices_0_io_msStatus_15_bits_is_miss;
  logic slices_0_io_msStatus_15_bits_is_prefetch;
  logic [30:0] slices_0_io_msStatus_15_bits_reqTag;
  logic [8:0] slices_0_io_msStatus_15_bits_set;
  logic slices_0_io_msStatus_15_valid;
  logic slices_0_io_out_rx_snp_ready;
  logic [31:0] slices_0_io_out_tx_dat_bits_be;
  logic [1:0] slices_0_io_out_tx_dat_bits_ccID;
  logic [255:0] slices_0_io_out_tx_dat_bits_data;
  logic [31:0] slices_0_io_out_tx_dat_bits_dataCheck;
  logic [1:0] slices_0_io_out_tx_dat_bits_dataID;
  logic [3:0] slices_0_io_out_tx_dat_bits_dataSource;
  logic [11:0] slices_0_io_out_tx_dat_bits_dbID;
  logic [10:0] slices_0_io_out_tx_dat_bits_homeNID;
  logic [3:0] slices_0_io_out_tx_dat_bits_opcode;
  logic [3:0] slices_0_io_out_tx_dat_bits_poison;
  logic [2:0] slices_0_io_out_tx_dat_bits_resp;
  logic [1:0] slices_0_io_out_tx_dat_bits_respErr;
  logic [10:0] slices_0_io_out_tx_dat_bits_tgtID;
  logic slices_0_io_out_tx_dat_bits_traceTag;
  logic [11:0] slices_0_io_out_tx_dat_bits_txnID;
  logic slices_0_io_out_tx_dat_valid;
  logic [47:0] slices_0_io_out_tx_req_bits_addr;
  logic slices_0_io_out_tx_req_bits_allowRetry;
  logic slices_0_io_out_tx_req_bits_expCompAck;
  logic slices_0_io_out_tx_req_bits_likelyshared;
  logic [7:0] slices_0_io_out_tx_req_bits_lpIDWithPadding;
  logic slices_0_io_out_tx_req_bits_memAttr_allocate;
  logic slices_0_io_out_tx_req_bits_memAttr_cacheable;
  logic slices_0_io_out_tx_req_bits_memAttr_device;
  logic slices_0_io_out_tx_req_bits_memAttr_ewa;
  logic slices_0_io_out_tx_req_bits_mpam_mpamNS;
  logic [8:0] slices_0_io_out_tx_req_bits_mpam_partID;
  logic slices_0_io_out_tx_req_bits_mpam_perfMonGroup;
  logic slices_0_io_out_tx_req_bits_ns;
  logic [6:0] slices_0_io_out_tx_req_bits_opcode;
  logic [1:0] slices_0_io_out_tx_req_bits_order;
  logic [3:0] slices_0_io_out_tx_req_bits_pCrdType;
  logic [3:0] slices_0_io_out_tx_req_bits_qos;
  logic [10:0] slices_0_io_out_tx_req_bits_returnNID;
  logic [11:0] slices_0_io_out_tx_req_bits_returnTxnID;
  logic [3:0] slices_0_io_out_tx_req_bits_rsvdc;
  logic slices_0_io_out_tx_req_bits_snoopMe;
  logic slices_0_io_out_tx_req_bits_snpAttr;
  logic slices_0_io_out_tx_req_bits_stashNIDValid;
  logic [1:0] slices_0_io_out_tx_req_bits_tagOp;
  logic slices_0_io_out_tx_req_bits_traceTag;
  logic [11:0] slices_0_io_out_tx_req_bits_txnID;
  logic slices_0_io_out_tx_req_valid;
  logic [2:0] slices_0_io_out_tx_rsp_bits_cBusy;
  logic [11:0] slices_0_io_out_tx_rsp_bits_dbID;
  logic [2:0] slices_0_io_out_tx_rsp_bits_fwdState;
  logic [4:0] slices_0_io_out_tx_rsp_bits_opcode;
  logic [3:0] slices_0_io_out_tx_rsp_bits_pCrdType;
  logic [3:0] slices_0_io_out_tx_rsp_bits_qos;
  logic [2:0] slices_0_io_out_tx_rsp_bits_resp;
  logic [1:0] slices_0_io_out_tx_rsp_bits_respErr;
  logic [1:0] slices_0_io_out_tx_rsp_bits_tagOp;
  logic [10:0] slices_0_io_out_tx_rsp_bits_tgtID;
  logic slices_0_io_out_tx_rsp_bits_traceTag;
  logic [11:0] slices_0_io_out_tx_rsp_bits_txnID;
  logic slices_0_io_out_tx_rsp_valid;
  logic [3:0] slices_0_io_pCrd_0_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_0_query_bits_srcID;
  logic slices_0_io_pCrd_0_query_valid;
  logic [3:0] slices_0_io_pCrd_1_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_1_query_bits_srcID;
  logic slices_0_io_pCrd_1_query_valid;
  logic [3:0] slices_0_io_pCrd_2_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_2_query_bits_srcID;
  logic slices_0_io_pCrd_2_query_valid;
  logic [3:0] slices_0_io_pCrd_3_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_3_query_bits_srcID;
  logic slices_0_io_pCrd_3_query_valid;
  logic [3:0] slices_0_io_pCrd_4_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_4_query_bits_srcID;
  logic slices_0_io_pCrd_4_query_valid;
  logic [3:0] slices_0_io_pCrd_5_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_5_query_bits_srcID;
  logic slices_0_io_pCrd_5_query_valid;
  logic [3:0] slices_0_io_pCrd_6_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_6_query_bits_srcID;
  logic slices_0_io_pCrd_6_query_valid;
  logic [3:0] slices_0_io_pCrd_7_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_7_query_bits_srcID;
  logic slices_0_io_pCrd_7_query_valid;
  logic [3:0] slices_0_io_pCrd_8_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_8_query_bits_srcID;
  logic slices_0_io_pCrd_8_query_valid;
  logic [3:0] slices_0_io_pCrd_9_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_9_query_bits_srcID;
  logic slices_0_io_pCrd_9_query_valid;
  logic [3:0] slices_0_io_pCrd_10_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_10_query_bits_srcID;
  logic slices_0_io_pCrd_10_query_valid;
  logic [3:0] slices_0_io_pCrd_11_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_11_query_bits_srcID;
  logic slices_0_io_pCrd_11_query_valid;
  logic [3:0] slices_0_io_pCrd_12_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_12_query_bits_srcID;
  logic slices_0_io_pCrd_12_query_valid;
  logic [3:0] slices_0_io_pCrd_13_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_13_query_bits_srcID;
  logic slices_0_io_pCrd_13_query_valid;
  logic [3:0] slices_0_io_pCrd_14_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_14_query_bits_srcID;
  logic slices_0_io_pCrd_14_query_valid;
  logic [3:0] slices_0_io_pCrd_15_query_bits_pCrdType;
  logic [10:0] slices_0_io_pCrd_15_query_bits_srcID;
  logic slices_0_io_pCrd_15_query_valid;
  logic [5:0] slices_0_io_perf_0_value;
  logic [5:0] slices_0_io_perf_1_value;
  logic [5:0] slices_0_io_perf_3_value;
  logic [5:0] slices_0_io_perf_4_value;
  logic [5:0] slices_0_io_perf_5_value;
  logic [5:0] slices_0_io_perf_6_value;
  logic [5:0] slices_0_io_perf_7_value;
  logic [5:0] slices_0_io_perf_8_value;
  logic [5:0] slices_0_io_perf_9_value;
  logic [5:0] slices_0_io_perf_10_value;
  logic [5:0] slices_0_io_perf_11_value;
  logic [5:0] slices_0_io_perf_12_value;
  logic [5:0] slices_0_io_perf_13_value;
  logic [5:0] slices_0_io_perf_14_value;
  logic [5:0] slices_0_io_perf_15_value;
  logic [5:0] slices_0_io_perf_16_value;
  logic [4:0] slices_0_io_pfLateInMSHR_bits;
  logic slices_0_io_pfLateInMSHR_valid;
  logic [4:0] slices_0_io_pfSent_bits;
  logic slices_0_io_pfSent_valid;
  logic slices_0_io_prefetch_req_ready;
  logic [4:0] slices_0_io_prefetch_resp_bits_pfSource;
  logic [8:0] slices_0_io_prefetch_resp_bits_set;
  logic [32:0] slices_0_io_prefetch_resp_bits_tag;
  logic [43:0] slices_0_io_prefetch_resp_bits_vaddr;
  logic slices_0_io_prefetch_resp_valid;
  logic slices_0_io_prefetch_train_bits_hit;
  logic slices_0_io_prefetch_train_bits_needT;
  logic [2:0] slices_0_io_prefetch_train_bits_pfsource;
  logic slices_0_io_prefetch_train_bits_prefetched;
  logic [4:0] slices_0_io_prefetch_train_bits_reqsource;
  logic [8:0] slices_0_io_prefetch_train_bits_set;
  logic [6:0] slices_0_io_prefetch_train_bits_source;
  logic [32:0] slices_0_io_prefetch_train_bits_tag;
  logic [43:0] slices_0_io_prefetch_train_bits_vaddr;
  logic slices_0_io_prefetch_train_valid;
  logic slices_1_boreChildrenBd_bore_ack;
  logic [136:0] slices_1_boreChildrenBd_bore_outdata;
  logic slices_1_io_dirResult_bits_hit;
  logic slices_1_io_dirResult_bits_meta_prefetch;
  logic [2:0] slices_1_io_dirResult_bits_meta_prefetchSrc;
  logic [2:0] slices_1_io_dirResult_bits_replacerInfo_channel;
  logic [4:0] slices_1_io_dirResult_bits_replacerInfo_reqSource;
  logic slices_1_io_dirResult_valid;
  logic [45:0] slices_1_io_error_bits_address;
  logic slices_1_io_error_bits_valid;
  logic slices_1_io_error_valid;
  logic [2:0] slices_1_io_hitPfInMSHR_bits;
  logic slices_1_io_hitPfInMSHR_valid;
  logic [47:0] slices_1_io_in_b_bits_address;
  logic [3:0] slices_1_io_in_d_bits_opcode;
  logic [6:0] slices_1_io_in_d_bits_source;
  logic slices_1_io_in_d_valid;
  logic slices_1_io_l1Hint_bits_isKeyword;
  logic [31:0] slices_1_io_l1Hint_bits_sourceId;
  logic slices_1_io_l1Hint_valid;
  logic slices_1_io_l2Miss;
  logic [2:0] slices_1_io_msAlloc_0_bits_channel;
  logic slices_1_io_msAlloc_0_bits_is_miss;
  logic slices_1_io_msAlloc_0_bits_is_prefetch;
  logic slices_1_io_msAlloc_0_valid;
  logic [2:0] slices_1_io_msAlloc_1_bits_channel;
  logic slices_1_io_msAlloc_1_bits_is_miss;
  logic slices_1_io_msAlloc_1_bits_is_prefetch;
  logic slices_1_io_msAlloc_1_valid;
  logic [2:0] slices_1_io_msAlloc_2_bits_channel;
  logic slices_1_io_msAlloc_2_bits_is_miss;
  logic slices_1_io_msAlloc_2_bits_is_prefetch;
  logic slices_1_io_msAlloc_2_valid;
  logic [2:0] slices_1_io_msAlloc_3_bits_channel;
  logic slices_1_io_msAlloc_3_bits_is_miss;
  logic slices_1_io_msAlloc_3_bits_is_prefetch;
  logic slices_1_io_msAlloc_3_valid;
  logic [2:0] slices_1_io_msAlloc_4_bits_channel;
  logic slices_1_io_msAlloc_4_bits_is_miss;
  logic slices_1_io_msAlloc_4_bits_is_prefetch;
  logic slices_1_io_msAlloc_4_valid;
  logic [2:0] slices_1_io_msAlloc_5_bits_channel;
  logic slices_1_io_msAlloc_5_bits_is_miss;
  logic slices_1_io_msAlloc_5_bits_is_prefetch;
  logic slices_1_io_msAlloc_5_valid;
  logic [2:0] slices_1_io_msAlloc_6_bits_channel;
  logic slices_1_io_msAlloc_6_bits_is_miss;
  logic slices_1_io_msAlloc_6_bits_is_prefetch;
  logic slices_1_io_msAlloc_6_valid;
  logic [2:0] slices_1_io_msAlloc_7_bits_channel;
  logic slices_1_io_msAlloc_7_bits_is_miss;
  logic slices_1_io_msAlloc_7_bits_is_prefetch;
  logic slices_1_io_msAlloc_7_valid;
  logic [2:0] slices_1_io_msAlloc_8_bits_channel;
  logic slices_1_io_msAlloc_8_bits_is_miss;
  logic slices_1_io_msAlloc_8_bits_is_prefetch;
  logic slices_1_io_msAlloc_8_valid;
  logic [2:0] slices_1_io_msAlloc_9_bits_channel;
  logic slices_1_io_msAlloc_9_bits_is_miss;
  logic slices_1_io_msAlloc_9_bits_is_prefetch;
  logic slices_1_io_msAlloc_9_valid;
  logic [2:0] slices_1_io_msAlloc_10_bits_channel;
  logic slices_1_io_msAlloc_10_bits_is_miss;
  logic slices_1_io_msAlloc_10_bits_is_prefetch;
  logic slices_1_io_msAlloc_10_valid;
  logic [2:0] slices_1_io_msAlloc_11_bits_channel;
  logic slices_1_io_msAlloc_11_bits_is_miss;
  logic slices_1_io_msAlloc_11_bits_is_prefetch;
  logic slices_1_io_msAlloc_11_valid;
  logic [2:0] slices_1_io_msAlloc_12_bits_channel;
  logic slices_1_io_msAlloc_12_bits_is_miss;
  logic slices_1_io_msAlloc_12_bits_is_prefetch;
  logic slices_1_io_msAlloc_12_valid;
  logic [2:0] slices_1_io_msAlloc_13_bits_channel;
  logic slices_1_io_msAlloc_13_bits_is_miss;
  logic slices_1_io_msAlloc_13_bits_is_prefetch;
  logic slices_1_io_msAlloc_13_valid;
  logic [2:0] slices_1_io_msAlloc_14_bits_channel;
  logic slices_1_io_msAlloc_14_bits_is_miss;
  logic slices_1_io_msAlloc_14_bits_is_prefetch;
  logic slices_1_io_msAlloc_14_valid;
  logic [2:0] slices_1_io_msAlloc_15_bits_channel;
  logic slices_1_io_msAlloc_15_bits_is_miss;
  logic slices_1_io_msAlloc_15_bits_is_prefetch;
  logic slices_1_io_msAlloc_15_valid;
  logic [2:0] slices_1_io_msStatus_0_bits_channel;
  logic slices_1_io_msStatus_0_bits_is_miss;
  logic slices_1_io_msStatus_0_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_0_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_0_bits_set;
  logic slices_1_io_msStatus_0_valid;
  logic [2:0] slices_1_io_msStatus_1_bits_channel;
  logic slices_1_io_msStatus_1_bits_is_miss;
  logic slices_1_io_msStatus_1_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_1_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_1_bits_set;
  logic slices_1_io_msStatus_1_valid;
  logic [2:0] slices_1_io_msStatus_2_bits_channel;
  logic slices_1_io_msStatus_2_bits_is_miss;
  logic slices_1_io_msStatus_2_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_2_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_2_bits_set;
  logic slices_1_io_msStatus_2_valid;
  logic [2:0] slices_1_io_msStatus_3_bits_channel;
  logic slices_1_io_msStatus_3_bits_is_miss;
  logic slices_1_io_msStatus_3_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_3_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_3_bits_set;
  logic slices_1_io_msStatus_3_valid;
  logic [2:0] slices_1_io_msStatus_4_bits_channel;
  logic slices_1_io_msStatus_4_bits_is_miss;
  logic slices_1_io_msStatus_4_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_4_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_4_bits_set;
  logic slices_1_io_msStatus_4_valid;
  logic [2:0] slices_1_io_msStatus_5_bits_channel;
  logic slices_1_io_msStatus_5_bits_is_miss;
  logic slices_1_io_msStatus_5_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_5_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_5_bits_set;
  logic slices_1_io_msStatus_5_valid;
  logic [2:0] slices_1_io_msStatus_6_bits_channel;
  logic slices_1_io_msStatus_6_bits_is_miss;
  logic slices_1_io_msStatus_6_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_6_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_6_bits_set;
  logic slices_1_io_msStatus_6_valid;
  logic [2:0] slices_1_io_msStatus_7_bits_channel;
  logic slices_1_io_msStatus_7_bits_is_miss;
  logic slices_1_io_msStatus_7_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_7_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_7_bits_set;
  logic slices_1_io_msStatus_7_valid;
  logic [2:0] slices_1_io_msStatus_8_bits_channel;
  logic slices_1_io_msStatus_8_bits_is_miss;
  logic slices_1_io_msStatus_8_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_8_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_8_bits_set;
  logic slices_1_io_msStatus_8_valid;
  logic [2:0] slices_1_io_msStatus_9_bits_channel;
  logic slices_1_io_msStatus_9_bits_is_miss;
  logic slices_1_io_msStatus_9_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_9_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_9_bits_set;
  logic slices_1_io_msStatus_9_valid;
  logic [2:0] slices_1_io_msStatus_10_bits_channel;
  logic slices_1_io_msStatus_10_bits_is_miss;
  logic slices_1_io_msStatus_10_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_10_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_10_bits_set;
  logic slices_1_io_msStatus_10_valid;
  logic [2:0] slices_1_io_msStatus_11_bits_channel;
  logic slices_1_io_msStatus_11_bits_is_miss;
  logic slices_1_io_msStatus_11_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_11_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_11_bits_set;
  logic slices_1_io_msStatus_11_valid;
  logic [2:0] slices_1_io_msStatus_12_bits_channel;
  logic slices_1_io_msStatus_12_bits_is_miss;
  logic slices_1_io_msStatus_12_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_12_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_12_bits_set;
  logic slices_1_io_msStatus_12_valid;
  logic [2:0] slices_1_io_msStatus_13_bits_channel;
  logic slices_1_io_msStatus_13_bits_is_miss;
  logic slices_1_io_msStatus_13_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_13_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_13_bits_set;
  logic slices_1_io_msStatus_13_valid;
  logic [2:0] slices_1_io_msStatus_14_bits_channel;
  logic slices_1_io_msStatus_14_bits_is_miss;
  logic slices_1_io_msStatus_14_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_14_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_14_bits_set;
  logic slices_1_io_msStatus_14_valid;
  logic [2:0] slices_1_io_msStatus_15_bits_channel;
  logic slices_1_io_msStatus_15_bits_is_miss;
  logic slices_1_io_msStatus_15_bits_is_prefetch;
  logic [30:0] slices_1_io_msStatus_15_bits_reqTag;
  logic [8:0] slices_1_io_msStatus_15_bits_set;
  logic slices_1_io_msStatus_15_valid;
  logic slices_1_io_out_rx_snp_ready;
  logic [31:0] slices_1_io_out_tx_dat_bits_be;
  logic [1:0] slices_1_io_out_tx_dat_bits_ccID;
  logic [255:0] slices_1_io_out_tx_dat_bits_data;
  logic [31:0] slices_1_io_out_tx_dat_bits_dataCheck;
  logic [1:0] slices_1_io_out_tx_dat_bits_dataID;
  logic [3:0] slices_1_io_out_tx_dat_bits_dataSource;
  logic [11:0] slices_1_io_out_tx_dat_bits_dbID;
  logic [10:0] slices_1_io_out_tx_dat_bits_homeNID;
  logic [3:0] slices_1_io_out_tx_dat_bits_opcode;
  logic [3:0] slices_1_io_out_tx_dat_bits_poison;
  logic [2:0] slices_1_io_out_tx_dat_bits_resp;
  logic [1:0] slices_1_io_out_tx_dat_bits_respErr;
  logic [10:0] slices_1_io_out_tx_dat_bits_tgtID;
  logic slices_1_io_out_tx_dat_bits_traceTag;
  logic [11:0] slices_1_io_out_tx_dat_bits_txnID;
  logic slices_1_io_out_tx_dat_valid;
  logic [47:0] slices_1_io_out_tx_req_bits_addr;
  logic slices_1_io_out_tx_req_bits_allowRetry;
  logic slices_1_io_out_tx_req_bits_expCompAck;
  logic slices_1_io_out_tx_req_bits_likelyshared;
  logic [7:0] slices_1_io_out_tx_req_bits_lpIDWithPadding;
  logic slices_1_io_out_tx_req_bits_memAttr_allocate;
  logic slices_1_io_out_tx_req_bits_memAttr_cacheable;
  logic slices_1_io_out_tx_req_bits_memAttr_device;
  logic slices_1_io_out_tx_req_bits_memAttr_ewa;
  logic slices_1_io_out_tx_req_bits_mpam_mpamNS;
  logic [8:0] slices_1_io_out_tx_req_bits_mpam_partID;
  logic slices_1_io_out_tx_req_bits_mpam_perfMonGroup;
  logic slices_1_io_out_tx_req_bits_ns;
  logic [6:0] slices_1_io_out_tx_req_bits_opcode;
  logic [1:0] slices_1_io_out_tx_req_bits_order;
  logic [3:0] slices_1_io_out_tx_req_bits_pCrdType;
  logic [3:0] slices_1_io_out_tx_req_bits_qos;
  logic [10:0] slices_1_io_out_tx_req_bits_returnNID;
  logic [11:0] slices_1_io_out_tx_req_bits_returnTxnID;
  logic [3:0] slices_1_io_out_tx_req_bits_rsvdc;
  logic slices_1_io_out_tx_req_bits_snoopMe;
  logic slices_1_io_out_tx_req_bits_snpAttr;
  logic slices_1_io_out_tx_req_bits_stashNIDValid;
  logic [1:0] slices_1_io_out_tx_req_bits_tagOp;
  logic slices_1_io_out_tx_req_bits_traceTag;
  logic [11:0] slices_1_io_out_tx_req_bits_txnID;
  logic slices_1_io_out_tx_req_valid;
  logic [2:0] slices_1_io_out_tx_rsp_bits_cBusy;
  logic [11:0] slices_1_io_out_tx_rsp_bits_dbID;
  logic [2:0] slices_1_io_out_tx_rsp_bits_fwdState;
  logic [4:0] slices_1_io_out_tx_rsp_bits_opcode;
  logic [3:0] slices_1_io_out_tx_rsp_bits_pCrdType;
  logic [3:0] slices_1_io_out_tx_rsp_bits_qos;
  logic [2:0] slices_1_io_out_tx_rsp_bits_resp;
  logic [1:0] slices_1_io_out_tx_rsp_bits_respErr;
  logic [1:0] slices_1_io_out_tx_rsp_bits_tagOp;
  logic [10:0] slices_1_io_out_tx_rsp_bits_tgtID;
  logic slices_1_io_out_tx_rsp_bits_traceTag;
  logic [11:0] slices_1_io_out_tx_rsp_bits_txnID;
  logic slices_1_io_out_tx_rsp_valid;
  logic [3:0] slices_1_io_pCrd_0_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_0_query_bits_srcID;
  logic slices_1_io_pCrd_0_query_valid;
  logic [3:0] slices_1_io_pCrd_1_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_1_query_bits_srcID;
  logic slices_1_io_pCrd_1_query_valid;
  logic [3:0] slices_1_io_pCrd_2_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_2_query_bits_srcID;
  logic slices_1_io_pCrd_2_query_valid;
  logic [3:0] slices_1_io_pCrd_3_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_3_query_bits_srcID;
  logic slices_1_io_pCrd_3_query_valid;
  logic [3:0] slices_1_io_pCrd_4_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_4_query_bits_srcID;
  logic slices_1_io_pCrd_4_query_valid;
  logic [3:0] slices_1_io_pCrd_5_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_5_query_bits_srcID;
  logic slices_1_io_pCrd_5_query_valid;
  logic [3:0] slices_1_io_pCrd_6_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_6_query_bits_srcID;
  logic slices_1_io_pCrd_6_query_valid;
  logic [3:0] slices_1_io_pCrd_7_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_7_query_bits_srcID;
  logic slices_1_io_pCrd_7_query_valid;
  logic [3:0] slices_1_io_pCrd_8_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_8_query_bits_srcID;
  logic slices_1_io_pCrd_8_query_valid;
  logic [3:0] slices_1_io_pCrd_9_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_9_query_bits_srcID;
  logic slices_1_io_pCrd_9_query_valid;
  logic [3:0] slices_1_io_pCrd_10_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_10_query_bits_srcID;
  logic slices_1_io_pCrd_10_query_valid;
  logic [3:0] slices_1_io_pCrd_11_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_11_query_bits_srcID;
  logic slices_1_io_pCrd_11_query_valid;
  logic [3:0] slices_1_io_pCrd_12_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_12_query_bits_srcID;
  logic slices_1_io_pCrd_12_query_valid;
  logic [3:0] slices_1_io_pCrd_13_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_13_query_bits_srcID;
  logic slices_1_io_pCrd_13_query_valid;
  logic [3:0] slices_1_io_pCrd_14_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_14_query_bits_srcID;
  logic slices_1_io_pCrd_14_query_valid;
  logic [3:0] slices_1_io_pCrd_15_query_bits_pCrdType;
  logic [10:0] slices_1_io_pCrd_15_query_bits_srcID;
  logic slices_1_io_pCrd_15_query_valid;
  logic [5:0] slices_1_io_perf_0_value;
  logic [5:0] slices_1_io_perf_1_value;
  logic [5:0] slices_1_io_perf_3_value;
  logic [5:0] slices_1_io_perf_4_value;
  logic [5:0] slices_1_io_perf_5_value;
  logic [5:0] slices_1_io_perf_6_value;
  logic [5:0] slices_1_io_perf_7_value;
  logic [5:0] slices_1_io_perf_8_value;
  logic [5:0] slices_1_io_perf_9_value;
  logic [5:0] slices_1_io_perf_10_value;
  logic [5:0] slices_1_io_perf_11_value;
  logic [5:0] slices_1_io_perf_12_value;
  logic [5:0] slices_1_io_perf_13_value;
  logic [5:0] slices_1_io_perf_14_value;
  logic [5:0] slices_1_io_perf_15_value;
  logic [5:0] slices_1_io_perf_16_value;
  logic [4:0] slices_1_io_pfLateInMSHR_bits;
  logic slices_1_io_pfLateInMSHR_valid;
  logic [4:0] slices_1_io_pfSent_bits;
  logic slices_1_io_pfSent_valid;
  logic slices_1_io_prefetch_req_ready;
  logic [4:0] slices_1_io_prefetch_resp_bits_pfSource;
  logic [8:0] slices_1_io_prefetch_resp_bits_set;
  logic [32:0] slices_1_io_prefetch_resp_bits_tag;
  logic [43:0] slices_1_io_prefetch_resp_bits_vaddr;
  logic slices_1_io_prefetch_resp_valid;
  logic slices_1_io_prefetch_train_bits_hit;
  logic slices_1_io_prefetch_train_bits_needT;
  logic [2:0] slices_1_io_prefetch_train_bits_pfsource;
  logic slices_1_io_prefetch_train_bits_prefetched;
  logic [4:0] slices_1_io_prefetch_train_bits_reqsource;
  logic [8:0] slices_1_io_prefetch_train_bits_set;
  logic [6:0] slices_1_io_prefetch_train_bits_source;
  logic [32:0] slices_1_io_prefetch_train_bits_tag;
  logic [43:0] slices_1_io_prefetch_train_bits_vaddr;
  logic slices_1_io_prefetch_train_valid;
  logic slices_2_boreChildrenBd_bore_ack;
  logic [136:0] slices_2_boreChildrenBd_bore_outdata;
  logic slices_2_io_dirResult_bits_hit;
  logic slices_2_io_dirResult_bits_meta_prefetch;
  logic [2:0] slices_2_io_dirResult_bits_meta_prefetchSrc;
  logic [2:0] slices_2_io_dirResult_bits_replacerInfo_channel;
  logic [4:0] slices_2_io_dirResult_bits_replacerInfo_reqSource;
  logic slices_2_io_dirResult_valid;
  logic [45:0] slices_2_io_error_bits_address;
  logic slices_2_io_error_bits_valid;
  logic slices_2_io_error_valid;
  logic [2:0] slices_2_io_hitPfInMSHR_bits;
  logic slices_2_io_hitPfInMSHR_valid;
  logic [47:0] slices_2_io_in_b_bits_address;
  logic [3:0] slices_2_io_in_d_bits_opcode;
  logic [6:0] slices_2_io_in_d_bits_source;
  logic slices_2_io_in_d_valid;
  logic slices_2_io_l1Hint_bits_isKeyword;
  logic [31:0] slices_2_io_l1Hint_bits_sourceId;
  logic slices_2_io_l1Hint_valid;
  logic slices_2_io_l2Miss;
  logic [2:0] slices_2_io_msAlloc_0_bits_channel;
  logic slices_2_io_msAlloc_0_bits_is_miss;
  logic slices_2_io_msAlloc_0_bits_is_prefetch;
  logic slices_2_io_msAlloc_0_valid;
  logic [2:0] slices_2_io_msAlloc_1_bits_channel;
  logic slices_2_io_msAlloc_1_bits_is_miss;
  logic slices_2_io_msAlloc_1_bits_is_prefetch;
  logic slices_2_io_msAlloc_1_valid;
  logic [2:0] slices_2_io_msAlloc_2_bits_channel;
  logic slices_2_io_msAlloc_2_bits_is_miss;
  logic slices_2_io_msAlloc_2_bits_is_prefetch;
  logic slices_2_io_msAlloc_2_valid;
  logic [2:0] slices_2_io_msAlloc_3_bits_channel;
  logic slices_2_io_msAlloc_3_bits_is_miss;
  logic slices_2_io_msAlloc_3_bits_is_prefetch;
  logic slices_2_io_msAlloc_3_valid;
  logic [2:0] slices_2_io_msAlloc_4_bits_channel;
  logic slices_2_io_msAlloc_4_bits_is_miss;
  logic slices_2_io_msAlloc_4_bits_is_prefetch;
  logic slices_2_io_msAlloc_4_valid;
  logic [2:0] slices_2_io_msAlloc_5_bits_channel;
  logic slices_2_io_msAlloc_5_bits_is_miss;
  logic slices_2_io_msAlloc_5_bits_is_prefetch;
  logic slices_2_io_msAlloc_5_valid;
  logic [2:0] slices_2_io_msAlloc_6_bits_channel;
  logic slices_2_io_msAlloc_6_bits_is_miss;
  logic slices_2_io_msAlloc_6_bits_is_prefetch;
  logic slices_2_io_msAlloc_6_valid;
  logic [2:0] slices_2_io_msAlloc_7_bits_channel;
  logic slices_2_io_msAlloc_7_bits_is_miss;
  logic slices_2_io_msAlloc_7_bits_is_prefetch;
  logic slices_2_io_msAlloc_7_valid;
  logic [2:0] slices_2_io_msAlloc_8_bits_channel;
  logic slices_2_io_msAlloc_8_bits_is_miss;
  logic slices_2_io_msAlloc_8_bits_is_prefetch;
  logic slices_2_io_msAlloc_8_valid;
  logic [2:0] slices_2_io_msAlloc_9_bits_channel;
  logic slices_2_io_msAlloc_9_bits_is_miss;
  logic slices_2_io_msAlloc_9_bits_is_prefetch;
  logic slices_2_io_msAlloc_9_valid;
  logic [2:0] slices_2_io_msAlloc_10_bits_channel;
  logic slices_2_io_msAlloc_10_bits_is_miss;
  logic slices_2_io_msAlloc_10_bits_is_prefetch;
  logic slices_2_io_msAlloc_10_valid;
  logic [2:0] slices_2_io_msAlloc_11_bits_channel;
  logic slices_2_io_msAlloc_11_bits_is_miss;
  logic slices_2_io_msAlloc_11_bits_is_prefetch;
  logic slices_2_io_msAlloc_11_valid;
  logic [2:0] slices_2_io_msAlloc_12_bits_channel;
  logic slices_2_io_msAlloc_12_bits_is_miss;
  logic slices_2_io_msAlloc_12_bits_is_prefetch;
  logic slices_2_io_msAlloc_12_valid;
  logic [2:0] slices_2_io_msAlloc_13_bits_channel;
  logic slices_2_io_msAlloc_13_bits_is_miss;
  logic slices_2_io_msAlloc_13_bits_is_prefetch;
  logic slices_2_io_msAlloc_13_valid;
  logic [2:0] slices_2_io_msAlloc_14_bits_channel;
  logic slices_2_io_msAlloc_14_bits_is_miss;
  logic slices_2_io_msAlloc_14_bits_is_prefetch;
  logic slices_2_io_msAlloc_14_valid;
  logic [2:0] slices_2_io_msAlloc_15_bits_channel;
  logic slices_2_io_msAlloc_15_bits_is_miss;
  logic slices_2_io_msAlloc_15_bits_is_prefetch;
  logic slices_2_io_msAlloc_15_valid;
  logic [2:0] slices_2_io_msStatus_0_bits_channel;
  logic slices_2_io_msStatus_0_bits_is_miss;
  logic slices_2_io_msStatus_0_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_0_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_0_bits_set;
  logic slices_2_io_msStatus_0_valid;
  logic [2:0] slices_2_io_msStatus_1_bits_channel;
  logic slices_2_io_msStatus_1_bits_is_miss;
  logic slices_2_io_msStatus_1_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_1_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_1_bits_set;
  logic slices_2_io_msStatus_1_valid;
  logic [2:0] slices_2_io_msStatus_2_bits_channel;
  logic slices_2_io_msStatus_2_bits_is_miss;
  logic slices_2_io_msStatus_2_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_2_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_2_bits_set;
  logic slices_2_io_msStatus_2_valid;
  logic [2:0] slices_2_io_msStatus_3_bits_channel;
  logic slices_2_io_msStatus_3_bits_is_miss;
  logic slices_2_io_msStatus_3_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_3_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_3_bits_set;
  logic slices_2_io_msStatus_3_valid;
  logic [2:0] slices_2_io_msStatus_4_bits_channel;
  logic slices_2_io_msStatus_4_bits_is_miss;
  logic slices_2_io_msStatus_4_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_4_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_4_bits_set;
  logic slices_2_io_msStatus_4_valid;
  logic [2:0] slices_2_io_msStatus_5_bits_channel;
  logic slices_2_io_msStatus_5_bits_is_miss;
  logic slices_2_io_msStatus_5_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_5_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_5_bits_set;
  logic slices_2_io_msStatus_5_valid;
  logic [2:0] slices_2_io_msStatus_6_bits_channel;
  logic slices_2_io_msStatus_6_bits_is_miss;
  logic slices_2_io_msStatus_6_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_6_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_6_bits_set;
  logic slices_2_io_msStatus_6_valid;
  logic [2:0] slices_2_io_msStatus_7_bits_channel;
  logic slices_2_io_msStatus_7_bits_is_miss;
  logic slices_2_io_msStatus_7_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_7_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_7_bits_set;
  logic slices_2_io_msStatus_7_valid;
  logic [2:0] slices_2_io_msStatus_8_bits_channel;
  logic slices_2_io_msStatus_8_bits_is_miss;
  logic slices_2_io_msStatus_8_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_8_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_8_bits_set;
  logic slices_2_io_msStatus_8_valid;
  logic [2:0] slices_2_io_msStatus_9_bits_channel;
  logic slices_2_io_msStatus_9_bits_is_miss;
  logic slices_2_io_msStatus_9_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_9_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_9_bits_set;
  logic slices_2_io_msStatus_9_valid;
  logic [2:0] slices_2_io_msStatus_10_bits_channel;
  logic slices_2_io_msStatus_10_bits_is_miss;
  logic slices_2_io_msStatus_10_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_10_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_10_bits_set;
  logic slices_2_io_msStatus_10_valid;
  logic [2:0] slices_2_io_msStatus_11_bits_channel;
  logic slices_2_io_msStatus_11_bits_is_miss;
  logic slices_2_io_msStatus_11_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_11_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_11_bits_set;
  logic slices_2_io_msStatus_11_valid;
  logic [2:0] slices_2_io_msStatus_12_bits_channel;
  logic slices_2_io_msStatus_12_bits_is_miss;
  logic slices_2_io_msStatus_12_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_12_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_12_bits_set;
  logic slices_2_io_msStatus_12_valid;
  logic [2:0] slices_2_io_msStatus_13_bits_channel;
  logic slices_2_io_msStatus_13_bits_is_miss;
  logic slices_2_io_msStatus_13_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_13_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_13_bits_set;
  logic slices_2_io_msStatus_13_valid;
  logic [2:0] slices_2_io_msStatus_14_bits_channel;
  logic slices_2_io_msStatus_14_bits_is_miss;
  logic slices_2_io_msStatus_14_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_14_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_14_bits_set;
  logic slices_2_io_msStatus_14_valid;
  logic [2:0] slices_2_io_msStatus_15_bits_channel;
  logic slices_2_io_msStatus_15_bits_is_miss;
  logic slices_2_io_msStatus_15_bits_is_prefetch;
  logic [30:0] slices_2_io_msStatus_15_bits_reqTag;
  logic [8:0] slices_2_io_msStatus_15_bits_set;
  logic slices_2_io_msStatus_15_valid;
  logic slices_2_io_out_rx_snp_ready;
  logic [31:0] slices_2_io_out_tx_dat_bits_be;
  logic [1:0] slices_2_io_out_tx_dat_bits_ccID;
  logic [255:0] slices_2_io_out_tx_dat_bits_data;
  logic [31:0] slices_2_io_out_tx_dat_bits_dataCheck;
  logic [1:0] slices_2_io_out_tx_dat_bits_dataID;
  logic [3:0] slices_2_io_out_tx_dat_bits_dataSource;
  logic [11:0] slices_2_io_out_tx_dat_bits_dbID;
  logic [10:0] slices_2_io_out_tx_dat_bits_homeNID;
  logic [3:0] slices_2_io_out_tx_dat_bits_opcode;
  logic [3:0] slices_2_io_out_tx_dat_bits_poison;
  logic [2:0] slices_2_io_out_tx_dat_bits_resp;
  logic [1:0] slices_2_io_out_tx_dat_bits_respErr;
  logic [10:0] slices_2_io_out_tx_dat_bits_tgtID;
  logic slices_2_io_out_tx_dat_bits_traceTag;
  logic [11:0] slices_2_io_out_tx_dat_bits_txnID;
  logic slices_2_io_out_tx_dat_valid;
  logic [47:0] slices_2_io_out_tx_req_bits_addr;
  logic slices_2_io_out_tx_req_bits_allowRetry;
  logic slices_2_io_out_tx_req_bits_expCompAck;
  logic slices_2_io_out_tx_req_bits_likelyshared;
  logic [7:0] slices_2_io_out_tx_req_bits_lpIDWithPadding;
  logic slices_2_io_out_tx_req_bits_memAttr_allocate;
  logic slices_2_io_out_tx_req_bits_memAttr_cacheable;
  logic slices_2_io_out_tx_req_bits_memAttr_device;
  logic slices_2_io_out_tx_req_bits_memAttr_ewa;
  logic slices_2_io_out_tx_req_bits_mpam_mpamNS;
  logic [8:0] slices_2_io_out_tx_req_bits_mpam_partID;
  logic slices_2_io_out_tx_req_bits_mpam_perfMonGroup;
  logic slices_2_io_out_tx_req_bits_ns;
  logic [6:0] slices_2_io_out_tx_req_bits_opcode;
  logic [1:0] slices_2_io_out_tx_req_bits_order;
  logic [3:0] slices_2_io_out_tx_req_bits_pCrdType;
  logic [3:0] slices_2_io_out_tx_req_bits_qos;
  logic [10:0] slices_2_io_out_tx_req_bits_returnNID;
  logic [11:0] slices_2_io_out_tx_req_bits_returnTxnID;
  logic [3:0] slices_2_io_out_tx_req_bits_rsvdc;
  logic slices_2_io_out_tx_req_bits_snoopMe;
  logic slices_2_io_out_tx_req_bits_snpAttr;
  logic slices_2_io_out_tx_req_bits_stashNIDValid;
  logic [1:0] slices_2_io_out_tx_req_bits_tagOp;
  logic slices_2_io_out_tx_req_bits_traceTag;
  logic [11:0] slices_2_io_out_tx_req_bits_txnID;
  logic slices_2_io_out_tx_req_valid;
  logic [2:0] slices_2_io_out_tx_rsp_bits_cBusy;
  logic [11:0] slices_2_io_out_tx_rsp_bits_dbID;
  logic [2:0] slices_2_io_out_tx_rsp_bits_fwdState;
  logic [4:0] slices_2_io_out_tx_rsp_bits_opcode;
  logic [3:0] slices_2_io_out_tx_rsp_bits_pCrdType;
  logic [3:0] slices_2_io_out_tx_rsp_bits_qos;
  logic [2:0] slices_2_io_out_tx_rsp_bits_resp;
  logic [1:0] slices_2_io_out_tx_rsp_bits_respErr;
  logic [1:0] slices_2_io_out_tx_rsp_bits_tagOp;
  logic [10:0] slices_2_io_out_tx_rsp_bits_tgtID;
  logic slices_2_io_out_tx_rsp_bits_traceTag;
  logic [11:0] slices_2_io_out_tx_rsp_bits_txnID;
  logic slices_2_io_out_tx_rsp_valid;
  logic [3:0] slices_2_io_pCrd_0_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_0_query_bits_srcID;
  logic slices_2_io_pCrd_0_query_valid;
  logic [3:0] slices_2_io_pCrd_1_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_1_query_bits_srcID;
  logic slices_2_io_pCrd_1_query_valid;
  logic [3:0] slices_2_io_pCrd_2_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_2_query_bits_srcID;
  logic slices_2_io_pCrd_2_query_valid;
  logic [3:0] slices_2_io_pCrd_3_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_3_query_bits_srcID;
  logic slices_2_io_pCrd_3_query_valid;
  logic [3:0] slices_2_io_pCrd_4_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_4_query_bits_srcID;
  logic slices_2_io_pCrd_4_query_valid;
  logic [3:0] slices_2_io_pCrd_5_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_5_query_bits_srcID;
  logic slices_2_io_pCrd_5_query_valid;
  logic [3:0] slices_2_io_pCrd_6_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_6_query_bits_srcID;
  logic slices_2_io_pCrd_6_query_valid;
  logic [3:0] slices_2_io_pCrd_7_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_7_query_bits_srcID;
  logic slices_2_io_pCrd_7_query_valid;
  logic [3:0] slices_2_io_pCrd_8_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_8_query_bits_srcID;
  logic slices_2_io_pCrd_8_query_valid;
  logic [3:0] slices_2_io_pCrd_9_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_9_query_bits_srcID;
  logic slices_2_io_pCrd_9_query_valid;
  logic [3:0] slices_2_io_pCrd_10_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_10_query_bits_srcID;
  logic slices_2_io_pCrd_10_query_valid;
  logic [3:0] slices_2_io_pCrd_11_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_11_query_bits_srcID;
  logic slices_2_io_pCrd_11_query_valid;
  logic [3:0] slices_2_io_pCrd_12_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_12_query_bits_srcID;
  logic slices_2_io_pCrd_12_query_valid;
  logic [3:0] slices_2_io_pCrd_13_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_13_query_bits_srcID;
  logic slices_2_io_pCrd_13_query_valid;
  logic [3:0] slices_2_io_pCrd_14_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_14_query_bits_srcID;
  logic slices_2_io_pCrd_14_query_valid;
  logic [3:0] slices_2_io_pCrd_15_query_bits_pCrdType;
  logic [10:0] slices_2_io_pCrd_15_query_bits_srcID;
  logic slices_2_io_pCrd_15_query_valid;
  logic [5:0] slices_2_io_perf_0_value;
  logic [5:0] slices_2_io_perf_1_value;
  logic [5:0] slices_2_io_perf_3_value;
  logic [5:0] slices_2_io_perf_4_value;
  logic [5:0] slices_2_io_perf_5_value;
  logic [5:0] slices_2_io_perf_6_value;
  logic [5:0] slices_2_io_perf_7_value;
  logic [5:0] slices_2_io_perf_8_value;
  logic [5:0] slices_2_io_perf_9_value;
  logic [5:0] slices_2_io_perf_10_value;
  logic [5:0] slices_2_io_perf_11_value;
  logic [5:0] slices_2_io_perf_12_value;
  logic [5:0] slices_2_io_perf_13_value;
  logic [5:0] slices_2_io_perf_14_value;
  logic [5:0] slices_2_io_perf_15_value;
  logic [5:0] slices_2_io_perf_16_value;
  logic [4:0] slices_2_io_pfLateInMSHR_bits;
  logic slices_2_io_pfLateInMSHR_valid;
  logic [4:0] slices_2_io_pfSent_bits;
  logic slices_2_io_pfSent_valid;
  logic slices_2_io_prefetch_req_ready;
  logic [4:0] slices_2_io_prefetch_resp_bits_pfSource;
  logic [8:0] slices_2_io_prefetch_resp_bits_set;
  logic [32:0] slices_2_io_prefetch_resp_bits_tag;
  logic [43:0] slices_2_io_prefetch_resp_bits_vaddr;
  logic slices_2_io_prefetch_resp_valid;
  logic slices_2_io_prefetch_train_bits_hit;
  logic slices_2_io_prefetch_train_bits_needT;
  logic [2:0] slices_2_io_prefetch_train_bits_pfsource;
  logic slices_2_io_prefetch_train_bits_prefetched;
  logic [4:0] slices_2_io_prefetch_train_bits_reqsource;
  logic [8:0] slices_2_io_prefetch_train_bits_set;
  logic [6:0] slices_2_io_prefetch_train_bits_source;
  logic [32:0] slices_2_io_prefetch_train_bits_tag;
  logic [43:0] slices_2_io_prefetch_train_bits_vaddr;
  logic slices_2_io_prefetch_train_valid;
  logic slices_3_boreChildrenBd_bore_ack;
  logic [136:0] slices_3_boreChildrenBd_bore_outdata;
  logic slices_3_io_dirResult_bits_hit;
  logic slices_3_io_dirResult_bits_meta_prefetch;
  logic [2:0] slices_3_io_dirResult_bits_meta_prefetchSrc;
  logic [2:0] slices_3_io_dirResult_bits_replacerInfo_channel;
  logic [4:0] slices_3_io_dirResult_bits_replacerInfo_reqSource;
  logic slices_3_io_dirResult_valid;
  logic [45:0] slices_3_io_error_bits_address;
  logic slices_3_io_error_bits_valid;
  logic slices_3_io_error_valid;
  logic [2:0] slices_3_io_hitPfInMSHR_bits;
  logic slices_3_io_hitPfInMSHR_valid;
  logic [47:0] slices_3_io_in_b_bits_address;
  logic [3:0] slices_3_io_in_d_bits_opcode;
  logic [6:0] slices_3_io_in_d_bits_source;
  logic slices_3_io_in_d_valid;
  logic slices_3_io_l1Hint_bits_isKeyword;
  logic [31:0] slices_3_io_l1Hint_bits_sourceId;
  logic slices_3_io_l1Hint_valid;
  logic slices_3_io_l2Miss;
  logic [2:0] slices_3_io_msAlloc_0_bits_channel;
  logic slices_3_io_msAlloc_0_bits_is_miss;
  logic slices_3_io_msAlloc_0_bits_is_prefetch;
  logic slices_3_io_msAlloc_0_valid;
  logic [2:0] slices_3_io_msAlloc_1_bits_channel;
  logic slices_3_io_msAlloc_1_bits_is_miss;
  logic slices_3_io_msAlloc_1_bits_is_prefetch;
  logic slices_3_io_msAlloc_1_valid;
  logic [2:0] slices_3_io_msAlloc_2_bits_channel;
  logic slices_3_io_msAlloc_2_bits_is_miss;
  logic slices_3_io_msAlloc_2_bits_is_prefetch;
  logic slices_3_io_msAlloc_2_valid;
  logic [2:0] slices_3_io_msAlloc_3_bits_channel;
  logic slices_3_io_msAlloc_3_bits_is_miss;
  logic slices_3_io_msAlloc_3_bits_is_prefetch;
  logic slices_3_io_msAlloc_3_valid;
  logic [2:0] slices_3_io_msAlloc_4_bits_channel;
  logic slices_3_io_msAlloc_4_bits_is_miss;
  logic slices_3_io_msAlloc_4_bits_is_prefetch;
  logic slices_3_io_msAlloc_4_valid;
  logic [2:0] slices_3_io_msAlloc_5_bits_channel;
  logic slices_3_io_msAlloc_5_bits_is_miss;
  logic slices_3_io_msAlloc_5_bits_is_prefetch;
  logic slices_3_io_msAlloc_5_valid;
  logic [2:0] slices_3_io_msAlloc_6_bits_channel;
  logic slices_3_io_msAlloc_6_bits_is_miss;
  logic slices_3_io_msAlloc_6_bits_is_prefetch;
  logic slices_3_io_msAlloc_6_valid;
  logic [2:0] slices_3_io_msAlloc_7_bits_channel;
  logic slices_3_io_msAlloc_7_bits_is_miss;
  logic slices_3_io_msAlloc_7_bits_is_prefetch;
  logic slices_3_io_msAlloc_7_valid;
  logic [2:0] slices_3_io_msAlloc_8_bits_channel;
  logic slices_3_io_msAlloc_8_bits_is_miss;
  logic slices_3_io_msAlloc_8_bits_is_prefetch;
  logic slices_3_io_msAlloc_8_valid;
  logic [2:0] slices_3_io_msAlloc_9_bits_channel;
  logic slices_3_io_msAlloc_9_bits_is_miss;
  logic slices_3_io_msAlloc_9_bits_is_prefetch;
  logic slices_3_io_msAlloc_9_valid;
  logic [2:0] slices_3_io_msAlloc_10_bits_channel;
  logic slices_3_io_msAlloc_10_bits_is_miss;
  logic slices_3_io_msAlloc_10_bits_is_prefetch;
  logic slices_3_io_msAlloc_10_valid;
  logic [2:0] slices_3_io_msAlloc_11_bits_channel;
  logic slices_3_io_msAlloc_11_bits_is_miss;
  logic slices_3_io_msAlloc_11_bits_is_prefetch;
  logic slices_3_io_msAlloc_11_valid;
  logic [2:0] slices_3_io_msAlloc_12_bits_channel;
  logic slices_3_io_msAlloc_12_bits_is_miss;
  logic slices_3_io_msAlloc_12_bits_is_prefetch;
  logic slices_3_io_msAlloc_12_valid;
  logic [2:0] slices_3_io_msAlloc_13_bits_channel;
  logic slices_3_io_msAlloc_13_bits_is_miss;
  logic slices_3_io_msAlloc_13_bits_is_prefetch;
  logic slices_3_io_msAlloc_13_valid;
  logic [2:0] slices_3_io_msAlloc_14_bits_channel;
  logic slices_3_io_msAlloc_14_bits_is_miss;
  logic slices_3_io_msAlloc_14_bits_is_prefetch;
  logic slices_3_io_msAlloc_14_valid;
  logic [2:0] slices_3_io_msAlloc_15_bits_channel;
  logic slices_3_io_msAlloc_15_bits_is_miss;
  logic slices_3_io_msAlloc_15_bits_is_prefetch;
  logic slices_3_io_msAlloc_15_valid;
  logic [2:0] slices_3_io_msStatus_0_bits_channel;
  logic slices_3_io_msStatus_0_bits_is_miss;
  logic slices_3_io_msStatus_0_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_0_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_0_bits_set;
  logic slices_3_io_msStatus_0_valid;
  logic [2:0] slices_3_io_msStatus_1_bits_channel;
  logic slices_3_io_msStatus_1_bits_is_miss;
  logic slices_3_io_msStatus_1_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_1_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_1_bits_set;
  logic slices_3_io_msStatus_1_valid;
  logic [2:0] slices_3_io_msStatus_2_bits_channel;
  logic slices_3_io_msStatus_2_bits_is_miss;
  logic slices_3_io_msStatus_2_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_2_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_2_bits_set;
  logic slices_3_io_msStatus_2_valid;
  logic [2:0] slices_3_io_msStatus_3_bits_channel;
  logic slices_3_io_msStatus_3_bits_is_miss;
  logic slices_3_io_msStatus_3_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_3_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_3_bits_set;
  logic slices_3_io_msStatus_3_valid;
  logic [2:0] slices_3_io_msStatus_4_bits_channel;
  logic slices_3_io_msStatus_4_bits_is_miss;
  logic slices_3_io_msStatus_4_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_4_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_4_bits_set;
  logic slices_3_io_msStatus_4_valid;
  logic [2:0] slices_3_io_msStatus_5_bits_channel;
  logic slices_3_io_msStatus_5_bits_is_miss;
  logic slices_3_io_msStatus_5_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_5_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_5_bits_set;
  logic slices_3_io_msStatus_5_valid;
  logic [2:0] slices_3_io_msStatus_6_bits_channel;
  logic slices_3_io_msStatus_6_bits_is_miss;
  logic slices_3_io_msStatus_6_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_6_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_6_bits_set;
  logic slices_3_io_msStatus_6_valid;
  logic [2:0] slices_3_io_msStatus_7_bits_channel;
  logic slices_3_io_msStatus_7_bits_is_miss;
  logic slices_3_io_msStatus_7_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_7_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_7_bits_set;
  logic slices_3_io_msStatus_7_valid;
  logic [2:0] slices_3_io_msStatus_8_bits_channel;
  logic slices_3_io_msStatus_8_bits_is_miss;
  logic slices_3_io_msStatus_8_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_8_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_8_bits_set;
  logic slices_3_io_msStatus_8_valid;
  logic [2:0] slices_3_io_msStatus_9_bits_channel;
  logic slices_3_io_msStatus_9_bits_is_miss;
  logic slices_3_io_msStatus_9_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_9_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_9_bits_set;
  logic slices_3_io_msStatus_9_valid;
  logic [2:0] slices_3_io_msStatus_10_bits_channel;
  logic slices_3_io_msStatus_10_bits_is_miss;
  logic slices_3_io_msStatus_10_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_10_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_10_bits_set;
  logic slices_3_io_msStatus_10_valid;
  logic [2:0] slices_3_io_msStatus_11_bits_channel;
  logic slices_3_io_msStatus_11_bits_is_miss;
  logic slices_3_io_msStatus_11_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_11_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_11_bits_set;
  logic slices_3_io_msStatus_11_valid;
  logic [2:0] slices_3_io_msStatus_12_bits_channel;
  logic slices_3_io_msStatus_12_bits_is_miss;
  logic slices_3_io_msStatus_12_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_12_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_12_bits_set;
  logic slices_3_io_msStatus_12_valid;
  logic [2:0] slices_3_io_msStatus_13_bits_channel;
  logic slices_3_io_msStatus_13_bits_is_miss;
  logic slices_3_io_msStatus_13_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_13_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_13_bits_set;
  logic slices_3_io_msStatus_13_valid;
  logic [2:0] slices_3_io_msStatus_14_bits_channel;
  logic slices_3_io_msStatus_14_bits_is_miss;
  logic slices_3_io_msStatus_14_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_14_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_14_bits_set;
  logic slices_3_io_msStatus_14_valid;
  logic [2:0] slices_3_io_msStatus_15_bits_channel;
  logic slices_3_io_msStatus_15_bits_is_miss;
  logic slices_3_io_msStatus_15_bits_is_prefetch;
  logic [30:0] slices_3_io_msStatus_15_bits_reqTag;
  logic [8:0] slices_3_io_msStatus_15_bits_set;
  logic slices_3_io_msStatus_15_valid;
  logic slices_3_io_out_rx_snp_ready;
  logic [31:0] slices_3_io_out_tx_dat_bits_be;
  logic [1:0] slices_3_io_out_tx_dat_bits_ccID;
  logic [255:0] slices_3_io_out_tx_dat_bits_data;
  logic [31:0] slices_3_io_out_tx_dat_bits_dataCheck;
  logic [1:0] slices_3_io_out_tx_dat_bits_dataID;
  logic [3:0] slices_3_io_out_tx_dat_bits_dataSource;
  logic [11:0] slices_3_io_out_tx_dat_bits_dbID;
  logic [10:0] slices_3_io_out_tx_dat_bits_homeNID;
  logic [3:0] slices_3_io_out_tx_dat_bits_opcode;
  logic [3:0] slices_3_io_out_tx_dat_bits_poison;
  logic [2:0] slices_3_io_out_tx_dat_bits_resp;
  logic [1:0] slices_3_io_out_tx_dat_bits_respErr;
  logic [10:0] slices_3_io_out_tx_dat_bits_tgtID;
  logic slices_3_io_out_tx_dat_bits_traceTag;
  logic [11:0] slices_3_io_out_tx_dat_bits_txnID;
  logic slices_3_io_out_tx_dat_valid;
  logic [47:0] slices_3_io_out_tx_req_bits_addr;
  logic slices_3_io_out_tx_req_bits_allowRetry;
  logic slices_3_io_out_tx_req_bits_expCompAck;
  logic slices_3_io_out_tx_req_bits_likelyshared;
  logic [7:0] slices_3_io_out_tx_req_bits_lpIDWithPadding;
  logic slices_3_io_out_tx_req_bits_memAttr_allocate;
  logic slices_3_io_out_tx_req_bits_memAttr_cacheable;
  logic slices_3_io_out_tx_req_bits_memAttr_device;
  logic slices_3_io_out_tx_req_bits_memAttr_ewa;
  logic slices_3_io_out_tx_req_bits_mpam_mpamNS;
  logic [8:0] slices_3_io_out_tx_req_bits_mpam_partID;
  logic slices_3_io_out_tx_req_bits_mpam_perfMonGroup;
  logic slices_3_io_out_tx_req_bits_ns;
  logic [6:0] slices_3_io_out_tx_req_bits_opcode;
  logic [1:0] slices_3_io_out_tx_req_bits_order;
  logic [3:0] slices_3_io_out_tx_req_bits_pCrdType;
  logic [3:0] slices_3_io_out_tx_req_bits_qos;
  logic [10:0] slices_3_io_out_tx_req_bits_returnNID;
  logic [11:0] slices_3_io_out_tx_req_bits_returnTxnID;
  logic [3:0] slices_3_io_out_tx_req_bits_rsvdc;
  logic slices_3_io_out_tx_req_bits_snoopMe;
  logic slices_3_io_out_tx_req_bits_snpAttr;
  logic slices_3_io_out_tx_req_bits_stashNIDValid;
  logic [1:0] slices_3_io_out_tx_req_bits_tagOp;
  logic slices_3_io_out_tx_req_bits_traceTag;
  logic [11:0] slices_3_io_out_tx_req_bits_txnID;
  logic slices_3_io_out_tx_req_valid;
  logic [2:0] slices_3_io_out_tx_rsp_bits_cBusy;
  logic [11:0] slices_3_io_out_tx_rsp_bits_dbID;
  logic [2:0] slices_3_io_out_tx_rsp_bits_fwdState;
  logic [4:0] slices_3_io_out_tx_rsp_bits_opcode;
  logic [3:0] slices_3_io_out_tx_rsp_bits_pCrdType;
  logic [3:0] slices_3_io_out_tx_rsp_bits_qos;
  logic [2:0] slices_3_io_out_tx_rsp_bits_resp;
  logic [1:0] slices_3_io_out_tx_rsp_bits_respErr;
  logic [1:0] slices_3_io_out_tx_rsp_bits_tagOp;
  logic [10:0] slices_3_io_out_tx_rsp_bits_tgtID;
  logic slices_3_io_out_tx_rsp_bits_traceTag;
  logic [11:0] slices_3_io_out_tx_rsp_bits_txnID;
  logic slices_3_io_out_tx_rsp_valid;
  logic [3:0] slices_3_io_pCrd_0_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_0_query_bits_srcID;
  logic slices_3_io_pCrd_0_query_valid;
  logic [3:0] slices_3_io_pCrd_1_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_1_query_bits_srcID;
  logic slices_3_io_pCrd_1_query_valid;
  logic [3:0] slices_3_io_pCrd_2_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_2_query_bits_srcID;
  logic slices_3_io_pCrd_2_query_valid;
  logic [3:0] slices_3_io_pCrd_3_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_3_query_bits_srcID;
  logic slices_3_io_pCrd_3_query_valid;
  logic [3:0] slices_3_io_pCrd_4_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_4_query_bits_srcID;
  logic slices_3_io_pCrd_4_query_valid;
  logic [3:0] slices_3_io_pCrd_5_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_5_query_bits_srcID;
  logic slices_3_io_pCrd_5_query_valid;
  logic [3:0] slices_3_io_pCrd_6_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_6_query_bits_srcID;
  logic slices_3_io_pCrd_6_query_valid;
  logic [3:0] slices_3_io_pCrd_7_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_7_query_bits_srcID;
  logic slices_3_io_pCrd_7_query_valid;
  logic [3:0] slices_3_io_pCrd_8_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_8_query_bits_srcID;
  logic slices_3_io_pCrd_8_query_valid;
  logic [3:0] slices_3_io_pCrd_9_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_9_query_bits_srcID;
  logic slices_3_io_pCrd_9_query_valid;
  logic [3:0] slices_3_io_pCrd_10_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_10_query_bits_srcID;
  logic slices_3_io_pCrd_10_query_valid;
  logic [3:0] slices_3_io_pCrd_11_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_11_query_bits_srcID;
  logic slices_3_io_pCrd_11_query_valid;
  logic [3:0] slices_3_io_pCrd_12_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_12_query_bits_srcID;
  logic slices_3_io_pCrd_12_query_valid;
  logic [3:0] slices_3_io_pCrd_13_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_13_query_bits_srcID;
  logic slices_3_io_pCrd_13_query_valid;
  logic [3:0] slices_3_io_pCrd_14_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_14_query_bits_srcID;
  logic slices_3_io_pCrd_14_query_valid;
  logic [3:0] slices_3_io_pCrd_15_query_bits_pCrdType;
  logic [10:0] slices_3_io_pCrd_15_query_bits_srcID;
  logic slices_3_io_pCrd_15_query_valid;
  logic [5:0] slices_3_io_perf_0_value;
  logic [5:0] slices_3_io_perf_1_value;
  logic [5:0] slices_3_io_perf_3_value;
  logic [5:0] slices_3_io_perf_4_value;
  logic [5:0] slices_3_io_perf_5_value;
  logic [5:0] slices_3_io_perf_6_value;
  logic [5:0] slices_3_io_perf_7_value;
  logic [5:0] slices_3_io_perf_8_value;
  logic [5:0] slices_3_io_perf_9_value;
  logic [5:0] slices_3_io_perf_10_value;
  logic [5:0] slices_3_io_perf_11_value;
  logic [5:0] slices_3_io_perf_12_value;
  logic [5:0] slices_3_io_perf_13_value;
  logic [5:0] slices_3_io_perf_14_value;
  logic [5:0] slices_3_io_perf_15_value;
  logic [5:0] slices_3_io_perf_16_value;
  logic [4:0] slices_3_io_pfLateInMSHR_bits;
  logic slices_3_io_pfLateInMSHR_valid;
  logic [4:0] slices_3_io_pfSent_bits;
  logic slices_3_io_pfSent_valid;
  logic slices_3_io_prefetch_req_ready;
  logic [4:0] slices_3_io_prefetch_resp_bits_pfSource;
  logic [8:0] slices_3_io_prefetch_resp_bits_set;
  logic [32:0] slices_3_io_prefetch_resp_bits_tag;
  logic [43:0] slices_3_io_prefetch_resp_bits_vaddr;
  logic slices_3_io_prefetch_resp_valid;
  logic slices_3_io_prefetch_train_bits_hit;
  logic slices_3_io_prefetch_train_bits_needT;
  logic [2:0] slices_3_io_prefetch_train_bits_pfsource;
  logic slices_3_io_prefetch_train_bits_prefetched;
  logic [4:0] slices_3_io_prefetch_train_bits_reqsource;
  logic [8:0] slices_3_io_prefetch_train_bits_set;
  logic [6:0] slices_3_io_prefetch_train_bits_source;
  logic [32:0] slices_3_io_prefetch_train_bits_tag;
  logic [43:0] slices_3_io_prefetch_train_bits_vaddr;
  logic slices_3_io_prefetch_train_valid;
  logic topDown_io_debugTopDown_l2MissMatch;
  logic train_pipeline_1_io_in_ready;
  logic train_pipeline_1_io_out_bits_needT;
  logic [4:0] train_pipeline_1_io_out_bits_reqsource;
  logic [8:0] train_pipeline_1_io_out_bits_set;
  logic [6:0] train_pipeline_1_io_out_bits_source;
  logic [32:0] train_pipeline_1_io_out_bits_tag;
  logic [43:0] train_pipeline_1_io_out_bits_vaddr;
  logic train_pipeline_1_io_out_valid;
  logic train_pipeline_2_io_in_ready;
  logic train_pipeline_2_io_out_bits_needT;
  logic [4:0] train_pipeline_2_io_out_bits_reqsource;
  logic [8:0] train_pipeline_2_io_out_bits_set;
  logic [6:0] train_pipeline_2_io_out_bits_source;
  logic [32:0] train_pipeline_2_io_out_bits_tag;
  logic [43:0] train_pipeline_2_io_out_bits_vaddr;
  logic train_pipeline_2_io_out_valid;
  logic train_pipeline_3_io_in_ready;
  logic train_pipeline_3_io_out_bits_needT;
  logic [4:0] train_pipeline_3_io_out_bits_reqsource;
  logic [8:0] train_pipeline_3_io_out_bits_set;
  logic [6:0] train_pipeline_3_io_out_bits_source;
  logic [32:0] train_pipeline_3_io_out_bits_tag;
  logic [43:0] train_pipeline_3_io_out_bits_vaddr;
  logic train_pipeline_3_io_out_valid;
  logic train_pipeline_io_in_ready;
  logic train_pipeline_io_out_bits_needT;
  logic [4:0] train_pipeline_io_out_bits_reqsource;
  logic [8:0] train_pipeline_io_out_bits_set;
  logic [6:0] train_pipeline_io_out_bits_source;
  logic [32:0] train_pipeline_io_out_bits_tag;
  logic [43:0] train_pipeline_io_out_bits_vaddr;
  logic train_pipeline_io_out_valid;
  logic txdat_arb_io_in_0_ready;
  logic txdat_arb_io_in_1_ready;
  logic txdat_arb_io_in_2_ready;
  logic txdat_arb_io_in_3_ready;
  logic txdat_arb_io_in_4_ready;
  logic [31:0] txdat_arb_io_out_bits_be;
  logic [2:0] txdat_arb_io_out_bits_cBusy;
  logic [1:0] txdat_arb_io_out_bits_ccID;
  logic [255:0] txdat_arb_io_out_bits_data;
  logic [31:0] txdat_arb_io_out_bits_dataCheck;
  logic [1:0] txdat_arb_io_out_bits_dataID;
  logic [3:0] txdat_arb_io_out_bits_dataSource;
  logic [11:0] txdat_arb_io_out_bits_dbID;
  logic [10:0] txdat_arb_io_out_bits_homeNID;
  logic [3:0] txdat_arb_io_out_bits_opcode;
  logic [3:0] txdat_arb_io_out_bits_poison;
  logic [3:0] txdat_arb_io_out_bits_qos;
  logic [2:0] txdat_arb_io_out_bits_resp;
  logic [1:0] txdat_arb_io_out_bits_respErr;
  logic [3:0] txdat_arb_io_out_bits_rsvdc;
  logic [7:0] txdat_arb_io_out_bits_tag;
  logic [1:0] txdat_arb_io_out_bits_tagOp;
  logic [10:0] txdat_arb_io_out_bits_tgtID;
  logic txdat_arb_io_out_bits_traceTag;
  logic [1:0] txdat_arb_io_out_bits_tu;
  logic [11:0] txdat_arb_io_out_bits_txnID;
  logic txdat_arb_io_out_valid;
  logic [2:0] txreq_arb_io_chosen;
  logic txreq_arb_io_in_0_ready;
  logic txreq_arb_io_in_1_ready;
  logic txreq_arb_io_in_2_ready;
  logic txreq_arb_io_in_3_ready;
  logic txreq_arb_io_in_4_ready;
  logic [47:0] txreq_arb_io_out_bits_addr;
  logic txreq_arb_io_out_bits_allowRetry;
  logic txreq_arb_io_out_bits_expCompAck;
  logic txreq_arb_io_out_bits_likelyshared;
  logic [7:0] txreq_arb_io_out_bits_lpIDWithPadding;
  logic txreq_arb_io_out_bits_memAttr_allocate;
  logic txreq_arb_io_out_bits_memAttr_cacheable;
  logic txreq_arb_io_out_bits_memAttr_device;
  logic txreq_arb_io_out_bits_memAttr_ewa;
  logic txreq_arb_io_out_bits_mpam_mpamNS;
  logic [8:0] txreq_arb_io_out_bits_mpam_partID;
  logic txreq_arb_io_out_bits_mpam_perfMonGroup;
  logic txreq_arb_io_out_bits_ns;
  logic [6:0] txreq_arb_io_out_bits_opcode;
  logic [1:0] txreq_arb_io_out_bits_order;
  logic [3:0] txreq_arb_io_out_bits_pCrdType;
  logic [3:0] txreq_arb_io_out_bits_qos;
  logic [10:0] txreq_arb_io_out_bits_returnNID;
  logic [11:0] txreq_arb_io_out_bits_returnTxnID;
  logic [3:0] txreq_arb_io_out_bits_rsvdc;
  logic [2:0] txreq_arb_io_out_bits_size;
  logic txreq_arb_io_out_bits_snoopMe;
  logic txreq_arb_io_out_bits_snpAttr;
  logic txreq_arb_io_out_bits_stashNIDValid;
  logic [1:0] txreq_arb_io_out_bits_tagOp;
  logic [10:0] txreq_arb_io_out_bits_tgtID;
  logic txreq_arb_io_out_bits_traceTag;
  logic [11:0] txreq_arb_io_out_bits_txnID;
  logic txreq_arb_io_out_valid;
  logic txrsp_arb_io_in_0_ready;
  logic txrsp_arb_io_in_1_ready;
  logic txrsp_arb_io_in_2_ready;
  logic txrsp_arb_io_in_3_ready;
  logic [2:0] txrsp_arb_io_out_bits_cBusy;
  logic [11:0] txrsp_arb_io_out_bits_dbID;
  logic [2:0] txrsp_arb_io_out_bits_fwdState;
  logic [4:0] txrsp_arb_io_out_bits_opcode;
  logic [3:0] txrsp_arb_io_out_bits_pCrdType;
  logic [3:0] txrsp_arb_io_out_bits_qos;
  logic [2:0] txrsp_arb_io_out_bits_resp;
  logic [1:0] txrsp_arb_io_out_bits_respErr;
  logic [1:0] txrsp_arb_io_out_bits_tagOp;
  logic [10:0] txrsp_arb_io_out_bits_tgtID;
  logic txrsp_arb_io_out_bits_traceTag;
  logic [11:0] txrsp_arb_io_out_bits_txnID;
  logic txrsp_arb_io_out_valid;

  // ---- 胶合核的端口 ----
  logic hintArb_valid;
  logic [31:0] hintArb_sourceId;
  logic [1:0] hintArb_chosen;
  logic hintArb_ready;
  logic hintFire;
  logic [4-1:0] slice_dValid;
  logic [3:0] slice_dOpcode [4];
  logic [4-1:0] slice_dReady;
  logic [4-1:0] in_dReady;
  logic [4-1:0] in_dValid;
  logic pf_reqValid;
  logic [8:0] pf_reqSet;
  logic [4-1:0] slice_pfReqReady;
  logic [4-1:0] slice_pfReqValid;
  logic pf_reqReady;
  logic [32:0] train_tag [4];
  logic [8:0] train_set [4];
  logic [32:0] trainArb_tag [4];
  logic [8:0] trainArb_set [4];
  logic [47:0] slice_bAddr [4];
  logic [47:0] in_bAddr [4];
  logic [45:0] slice_errAddr [4];
  logic [45:0] eccArb_addr [4];
  logic eccArb_outValid;
  logic eccArb_outBitsValid;
  logic errorValid;
  logic [5:0] slice_perf [4][17];
  logic [5:0] perf [4*17];
  logic [4-1:0] slice_l2Miss;
  logic l2Miss;
  logic txReqArb_outValid;
  logic [2:0] txReqArb_chosen;
  logic [11:0] txReqArb_outTxnID;
  logic txReqArb_mmioReady;
  logic mmio_txReqValid;
  logic lm_txReqReady;
  logic lm_syscoreq;
  logic chi_syscoack;
  logic lm_txReqValid;
  logic [11:0] lm_txReqTxnID;
  logic txReqArb_outReady;
  logic rxSnp_valid;
  logic [1:0] rxSnp_bank;
  logic [4-1:0] slice_rxSnpReady;
  logic [4-1:0] slice_rxSnpValid;
  logic rxSnp_ready;
  logic rxRsp_valid;
  logic [4:0] rxRsp_opcode;
  logic [11:0] rxRsp_txnID;
  logic [4-1:0] slice_rxRspReady;
  logic mmio_rxRspReady;
  logic [4-1:0] slice_rxRspValid;
  logic mmio_rxRspValid;
  logic [11:0] rxRsp_innerTxnID;
  logic rxRsp_ready;
  logic rxDat_valid;
  logic [11:0] rxDat_txnID;
  logic [4-1:0] slice_rxDatReady;
  logic mmio_rxDatReady;
  logic [4-1:0] slice_rxDatValid;
  logic mmio_rxDatValid;
  logic [11:0] rxDat_innerTxnID;
  logic rxDat_ready;
  logic [3:0] rxRsp_pCrdType;
  logic [10:0] rxRsp_srcID;
  logic pcrdEnq_valid;
  logic [3:0] pcrdEnq_pCrdType;
  logic [10:0] pcrdEnq_srcID;
  logic pcrdHead_valid;
  logic [3:0] pcrdHead_pCrdType;
  logic [10:0] pcrdHead_srcID;
  logic [80-1:0] pcrdQuery_valid;
  logic [3:0] pcrdQuery_pCrdType [80];
  logic [10:0] pcrdQuery_srcID [80];
  logic [80-1:0] pcrdHit;
  logic pcrdArb_outValid;

  // ---- 核的输入：从 child 输出 / 顶层输入收集 ----
  assign hintArb_valid = l1HintArb_io_out_valid;
  assign hintArb_sourceId = l1HintArb_io_out_bits_sourceId;
  assign hintArb_chosen = l1HintArb_io_chosen;
  assign slice_dValid[0] = slices_0_io_in_d_valid;
  assign slice_dValid[1] = slices_1_io_in_d_valid;
  assign slice_dValid[2] = slices_2_io_in_d_valid;
  assign slice_dValid[3] = slices_3_io_in_d_valid;
  assign slice_dOpcode[0] = slices_0_io_in_d_bits_opcode;
  assign slice_dOpcode[1] = slices_1_io_in_d_bits_opcode;
  assign slice_dOpcode[2] = slices_2_io_in_d_bits_opcode;
  assign slice_dOpcode[3] = slices_3_io_in_d_bits_opcode;
  assign in_dReady[0] = auto_in_0_d_ready;
  assign in_dReady[1] = auto_in_1_d_ready;
  assign in_dReady[2] = auto_in_2_d_ready;
  assign in_dReady[3] = auto_in_3_d_ready;
  assign pf_reqValid = prefetcher_io_req_valid;
  assign pf_reqSet = prefetcher_io_req_bits_set;
  assign slice_pfReqReady[0] = slices_0_io_prefetch_req_ready;
  assign slice_pfReqReady[1] = slices_1_io_prefetch_req_ready;
  assign slice_pfReqReady[2] = slices_2_io_prefetch_req_ready;
  assign slice_pfReqReady[3] = slices_3_io_prefetch_req_ready;
  assign train_tag[0] = train_pipeline_io_out_bits_tag;
  assign train_tag[1] = train_pipeline_1_io_out_bits_tag;
  assign train_tag[2] = train_pipeline_2_io_out_bits_tag;
  assign train_tag[3] = train_pipeline_3_io_out_bits_tag;
  assign train_set[0] = train_pipeline_io_out_bits_set;
  assign train_set[1] = train_pipeline_1_io_out_bits_set;
  assign train_set[2] = train_pipeline_2_io_out_bits_set;
  assign train_set[3] = train_pipeline_3_io_out_bits_set;
  assign slice_bAddr[0] = slices_0_io_in_b_bits_address;
  assign slice_bAddr[1] = slices_1_io_in_b_bits_address;
  assign slice_bAddr[2] = slices_2_io_in_b_bits_address;
  assign slice_bAddr[3] = slices_3_io_in_b_bits_address;
  assign slice_errAddr[0] = slices_0_io_error_bits_address;
  assign slice_errAddr[1] = slices_1_io_error_bits_address;
  assign slice_errAddr[2] = slices_2_io_error_bits_address;
  assign slice_errAddr[3] = slices_3_io_error_bits_address;
  assign eccArb_outValid = l2ECCArb_io_out_valid;
  assign eccArb_outBitsValid = l2ECCArb_io_out_bits_valid;
  assign slice_perf[0][0] = slices_0_io_perf_0_value;
  assign slice_perf[0][1] = slices_0_io_perf_1_value;
  assign slice_perf[0][2] = 6'h0;
  assign slice_perf[0][3] = slices_0_io_perf_3_value;
  assign slice_perf[0][4] = slices_0_io_perf_4_value;
  assign slice_perf[0][5] = slices_0_io_perf_5_value;
  assign slice_perf[0][6] = slices_0_io_perf_6_value;
  assign slice_perf[0][7] = slices_0_io_perf_7_value;
  assign slice_perf[0][8] = slices_0_io_perf_8_value;
  assign slice_perf[0][9] = slices_0_io_perf_9_value;
  assign slice_perf[0][10] = slices_0_io_perf_10_value;
  assign slice_perf[0][11] = slices_0_io_perf_11_value;
  assign slice_perf[0][12] = slices_0_io_perf_12_value;
  assign slice_perf[0][13] = slices_0_io_perf_13_value;
  assign slice_perf[0][14] = slices_0_io_perf_14_value;
  assign slice_perf[0][15] = slices_0_io_perf_15_value;
  assign slice_perf[0][16] = slices_0_io_perf_16_value;
  assign slice_perf[1][0] = slices_1_io_perf_0_value;
  assign slice_perf[1][1] = slices_1_io_perf_1_value;
  assign slice_perf[1][2] = 6'h0;
  assign slice_perf[1][3] = slices_1_io_perf_3_value;
  assign slice_perf[1][4] = slices_1_io_perf_4_value;
  assign slice_perf[1][5] = slices_1_io_perf_5_value;
  assign slice_perf[1][6] = slices_1_io_perf_6_value;
  assign slice_perf[1][7] = slices_1_io_perf_7_value;
  assign slice_perf[1][8] = slices_1_io_perf_8_value;
  assign slice_perf[1][9] = slices_1_io_perf_9_value;
  assign slice_perf[1][10] = slices_1_io_perf_10_value;
  assign slice_perf[1][11] = slices_1_io_perf_11_value;
  assign slice_perf[1][12] = slices_1_io_perf_12_value;
  assign slice_perf[1][13] = slices_1_io_perf_13_value;
  assign slice_perf[1][14] = slices_1_io_perf_14_value;
  assign slice_perf[1][15] = slices_1_io_perf_15_value;
  assign slice_perf[1][16] = slices_1_io_perf_16_value;
  assign slice_perf[2][0] = slices_2_io_perf_0_value;
  assign slice_perf[2][1] = slices_2_io_perf_1_value;
  assign slice_perf[2][2] = 6'h0;
  assign slice_perf[2][3] = slices_2_io_perf_3_value;
  assign slice_perf[2][4] = slices_2_io_perf_4_value;
  assign slice_perf[2][5] = slices_2_io_perf_5_value;
  assign slice_perf[2][6] = slices_2_io_perf_6_value;
  assign slice_perf[2][7] = slices_2_io_perf_7_value;
  assign slice_perf[2][8] = slices_2_io_perf_8_value;
  assign slice_perf[2][9] = slices_2_io_perf_9_value;
  assign slice_perf[2][10] = slices_2_io_perf_10_value;
  assign slice_perf[2][11] = slices_2_io_perf_11_value;
  assign slice_perf[2][12] = slices_2_io_perf_12_value;
  assign slice_perf[2][13] = slices_2_io_perf_13_value;
  assign slice_perf[2][14] = slices_2_io_perf_14_value;
  assign slice_perf[2][15] = slices_2_io_perf_15_value;
  assign slice_perf[2][16] = slices_2_io_perf_16_value;
  assign slice_perf[3][0] = slices_3_io_perf_0_value;
  assign slice_perf[3][1] = slices_3_io_perf_1_value;
  assign slice_perf[3][2] = 6'h0;
  assign slice_perf[3][3] = slices_3_io_perf_3_value;
  assign slice_perf[3][4] = slices_3_io_perf_4_value;
  assign slice_perf[3][5] = slices_3_io_perf_5_value;
  assign slice_perf[3][6] = slices_3_io_perf_6_value;
  assign slice_perf[3][7] = slices_3_io_perf_7_value;
  assign slice_perf[3][8] = slices_3_io_perf_8_value;
  assign slice_perf[3][9] = slices_3_io_perf_9_value;
  assign slice_perf[3][10] = slices_3_io_perf_10_value;
  assign slice_perf[3][11] = slices_3_io_perf_11_value;
  assign slice_perf[3][12] = slices_3_io_perf_12_value;
  assign slice_perf[3][13] = slices_3_io_perf_13_value;
  assign slice_perf[3][14] = slices_3_io_perf_14_value;
  assign slice_perf[3][15] = slices_3_io_perf_15_value;
  assign slice_perf[3][16] = slices_3_io_perf_16_value;
  assign slice_l2Miss[0] = slices_0_io_l2Miss;
  assign slice_l2Miss[1] = slices_1_io_l2Miss;
  assign slice_l2Miss[2] = slices_2_io_l2Miss;
  assign slice_l2Miss[3] = slices_3_io_l2Miss;
  assign txReqArb_outValid = txreq_arb_io_out_valid;
  assign txReqArb_chosen = txreq_arb_io_chosen;
  assign txReqArb_outTxnID = txreq_arb_io_out_bits_txnID;
  assign txReqArb_mmioReady = txreq_arb_io_in_4_ready;
  assign mmio_txReqValid = mmioBridge_io_tx_req_valid;
  assign lm_txReqReady = linkMonitor_io_in_tx_req_ready;
  assign lm_syscoreq = linkMonitor_io_out_syscoreq;
  assign chi_syscoack = io_chi_syscoack;
  assign rxSnp_valid = linkMonitor_io_in_rx_snp_valid;
  assign rxSnp_bank = linkMonitor_io_in_rx_snp_bits_addr[4:3];
  assign slice_rxSnpReady[0] = slices_0_io_out_rx_snp_ready;
  assign slice_rxSnpReady[1] = slices_1_io_out_rx_snp_ready;
  assign slice_rxSnpReady[2] = slices_2_io_out_rx_snp_ready;
  assign slice_rxSnpReady[3] = slices_3_io_out_rx_snp_ready;
  assign rxRsp_valid = rxrspPipe_pipeline_io_out_valid;
  assign rxRsp_opcode = rxrspPipe_pipeline_io_out_bits_opcode;
  assign rxRsp_txnID = rxrspPipe_pipeline_io_out_bits_txnID;
  assign slice_rxRspReady[0] = 1'b1;
  assign slice_rxRspReady[1] = 1'b1;
  assign slice_rxRspReady[2] = 1'b1;
  assign slice_rxRspReady[3] = 1'b1;
  assign mmio_rxRspReady = mmioBridge_io_rx_rsp_ready;
  assign rxDat_valid = rxdatPipe_pipeline_io_out_valid;
  assign rxDat_txnID = rxdatPipe_pipeline_io_out_bits_txnID;
  assign slice_rxDatReady[0] = 1'b1;
  assign slice_rxDatReady[1] = 1'b1;
  assign slice_rxDatReady[2] = 1'b1;
  assign slice_rxDatReady[3] = 1'b1;
  assign mmio_rxDatReady = mmioBridge_io_rx_dat_ready;
  assign rxRsp_pCrdType = rxrspPipe_pipeline_io_out_bits_pCrdType;
  assign rxRsp_srcID = rxrspPipe_pipeline_io_out_bits_srcID;
  assign pcrdHead_valid = pCrdQueue_s3_io_deq_valid;
  assign pcrdHead_pCrdType = pCrdQueue_s3_io_deq_bits_pCrdType;
  assign pcrdHead_srcID = pCrdQueue_s3_io_deq_bits_srcID;
  assign pcrdQuery_valid[0] = mmioBridge_io_pCrd_0_query_valid;
  assign pcrdQuery_valid[1] = mmioBridge_io_pCrd_1_query_valid;
  assign pcrdQuery_valid[2] = mmioBridge_io_pCrd_2_query_valid;
  assign pcrdQuery_valid[3] = mmioBridge_io_pCrd_3_query_valid;
  assign pcrdQuery_valid[4] = mmioBridge_io_pCrd_4_query_valid;
  assign pcrdQuery_valid[5] = mmioBridge_io_pCrd_5_query_valid;
  assign pcrdQuery_valid[6] = mmioBridge_io_pCrd_6_query_valid;
  assign pcrdQuery_valid[7] = mmioBridge_io_pCrd_7_query_valid;
  assign pcrdQuery_valid[8] = mmioBridge_io_pCrd_8_query_valid;
  assign pcrdQuery_valid[9] = mmioBridge_io_pCrd_9_query_valid;
  assign pcrdQuery_valid[10] = mmioBridge_io_pCrd_10_query_valid;
  assign pcrdQuery_valid[11] = mmioBridge_io_pCrd_11_query_valid;
  assign pcrdQuery_valid[12] = mmioBridge_io_pCrd_12_query_valid;
  assign pcrdQuery_valid[13] = mmioBridge_io_pCrd_13_query_valid;
  assign pcrdQuery_valid[14] = mmioBridge_io_pCrd_14_query_valid;
  assign pcrdQuery_valid[15] = mmioBridge_io_pCrd_15_query_valid;
  assign pcrdQuery_valid[16] = slices_0_io_pCrd_0_query_valid;
  assign pcrdQuery_valid[17] = slices_0_io_pCrd_1_query_valid;
  assign pcrdQuery_valid[18] = slices_0_io_pCrd_2_query_valid;
  assign pcrdQuery_valid[19] = slices_0_io_pCrd_3_query_valid;
  assign pcrdQuery_valid[20] = slices_0_io_pCrd_4_query_valid;
  assign pcrdQuery_valid[21] = slices_0_io_pCrd_5_query_valid;
  assign pcrdQuery_valid[22] = slices_0_io_pCrd_6_query_valid;
  assign pcrdQuery_valid[23] = slices_0_io_pCrd_7_query_valid;
  assign pcrdQuery_valid[24] = slices_0_io_pCrd_8_query_valid;
  assign pcrdQuery_valid[25] = slices_0_io_pCrd_9_query_valid;
  assign pcrdQuery_valid[26] = slices_0_io_pCrd_10_query_valid;
  assign pcrdQuery_valid[27] = slices_0_io_pCrd_11_query_valid;
  assign pcrdQuery_valid[28] = slices_0_io_pCrd_12_query_valid;
  assign pcrdQuery_valid[29] = slices_0_io_pCrd_13_query_valid;
  assign pcrdQuery_valid[30] = slices_0_io_pCrd_14_query_valid;
  assign pcrdQuery_valid[31] = slices_0_io_pCrd_15_query_valid;
  assign pcrdQuery_valid[32] = slices_1_io_pCrd_0_query_valid;
  assign pcrdQuery_valid[33] = slices_1_io_pCrd_1_query_valid;
  assign pcrdQuery_valid[34] = slices_1_io_pCrd_2_query_valid;
  assign pcrdQuery_valid[35] = slices_1_io_pCrd_3_query_valid;
  assign pcrdQuery_valid[36] = slices_1_io_pCrd_4_query_valid;
  assign pcrdQuery_valid[37] = slices_1_io_pCrd_5_query_valid;
  assign pcrdQuery_valid[38] = slices_1_io_pCrd_6_query_valid;
  assign pcrdQuery_valid[39] = slices_1_io_pCrd_7_query_valid;
  assign pcrdQuery_valid[40] = slices_1_io_pCrd_8_query_valid;
  assign pcrdQuery_valid[41] = slices_1_io_pCrd_9_query_valid;
  assign pcrdQuery_valid[42] = slices_1_io_pCrd_10_query_valid;
  assign pcrdQuery_valid[43] = slices_1_io_pCrd_11_query_valid;
  assign pcrdQuery_valid[44] = slices_1_io_pCrd_12_query_valid;
  assign pcrdQuery_valid[45] = slices_1_io_pCrd_13_query_valid;
  assign pcrdQuery_valid[46] = slices_1_io_pCrd_14_query_valid;
  assign pcrdQuery_valid[47] = slices_1_io_pCrd_15_query_valid;
  assign pcrdQuery_valid[48] = slices_2_io_pCrd_0_query_valid;
  assign pcrdQuery_valid[49] = slices_2_io_pCrd_1_query_valid;
  assign pcrdQuery_valid[50] = slices_2_io_pCrd_2_query_valid;
  assign pcrdQuery_valid[51] = slices_2_io_pCrd_3_query_valid;
  assign pcrdQuery_valid[52] = slices_2_io_pCrd_4_query_valid;
  assign pcrdQuery_valid[53] = slices_2_io_pCrd_5_query_valid;
  assign pcrdQuery_valid[54] = slices_2_io_pCrd_6_query_valid;
  assign pcrdQuery_valid[55] = slices_2_io_pCrd_7_query_valid;
  assign pcrdQuery_valid[56] = slices_2_io_pCrd_8_query_valid;
  assign pcrdQuery_valid[57] = slices_2_io_pCrd_9_query_valid;
  assign pcrdQuery_valid[58] = slices_2_io_pCrd_10_query_valid;
  assign pcrdQuery_valid[59] = slices_2_io_pCrd_11_query_valid;
  assign pcrdQuery_valid[60] = slices_2_io_pCrd_12_query_valid;
  assign pcrdQuery_valid[61] = slices_2_io_pCrd_13_query_valid;
  assign pcrdQuery_valid[62] = slices_2_io_pCrd_14_query_valid;
  assign pcrdQuery_valid[63] = slices_2_io_pCrd_15_query_valid;
  assign pcrdQuery_valid[64] = slices_3_io_pCrd_0_query_valid;
  assign pcrdQuery_valid[65] = slices_3_io_pCrd_1_query_valid;
  assign pcrdQuery_valid[66] = slices_3_io_pCrd_2_query_valid;
  assign pcrdQuery_valid[67] = slices_3_io_pCrd_3_query_valid;
  assign pcrdQuery_valid[68] = slices_3_io_pCrd_4_query_valid;
  assign pcrdQuery_valid[69] = slices_3_io_pCrd_5_query_valid;
  assign pcrdQuery_valid[70] = slices_3_io_pCrd_6_query_valid;
  assign pcrdQuery_valid[71] = slices_3_io_pCrd_7_query_valid;
  assign pcrdQuery_valid[72] = slices_3_io_pCrd_8_query_valid;
  assign pcrdQuery_valid[73] = slices_3_io_pCrd_9_query_valid;
  assign pcrdQuery_valid[74] = slices_3_io_pCrd_10_query_valid;
  assign pcrdQuery_valid[75] = slices_3_io_pCrd_11_query_valid;
  assign pcrdQuery_valid[76] = slices_3_io_pCrd_12_query_valid;
  assign pcrdQuery_valid[77] = slices_3_io_pCrd_13_query_valid;
  assign pcrdQuery_valid[78] = slices_3_io_pCrd_14_query_valid;
  assign pcrdQuery_valid[79] = slices_3_io_pCrd_15_query_valid;
  assign pcrdQuery_pCrdType[0] = mmioBridge_io_pCrd_0_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[1] = mmioBridge_io_pCrd_1_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[2] = mmioBridge_io_pCrd_2_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[3] = mmioBridge_io_pCrd_3_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[4] = mmioBridge_io_pCrd_4_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[5] = mmioBridge_io_pCrd_5_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[6] = mmioBridge_io_pCrd_6_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[7] = mmioBridge_io_pCrd_7_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[8] = mmioBridge_io_pCrd_8_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[9] = mmioBridge_io_pCrd_9_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[10] = mmioBridge_io_pCrd_10_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[11] = mmioBridge_io_pCrd_11_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[12] = mmioBridge_io_pCrd_12_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[13] = mmioBridge_io_pCrd_13_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[14] = mmioBridge_io_pCrd_14_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[15] = mmioBridge_io_pCrd_15_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[16] = slices_0_io_pCrd_0_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[17] = slices_0_io_pCrd_1_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[18] = slices_0_io_pCrd_2_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[19] = slices_0_io_pCrd_3_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[20] = slices_0_io_pCrd_4_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[21] = slices_0_io_pCrd_5_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[22] = slices_0_io_pCrd_6_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[23] = slices_0_io_pCrd_7_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[24] = slices_0_io_pCrd_8_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[25] = slices_0_io_pCrd_9_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[26] = slices_0_io_pCrd_10_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[27] = slices_0_io_pCrd_11_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[28] = slices_0_io_pCrd_12_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[29] = slices_0_io_pCrd_13_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[30] = slices_0_io_pCrd_14_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[31] = slices_0_io_pCrd_15_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[32] = slices_1_io_pCrd_0_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[33] = slices_1_io_pCrd_1_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[34] = slices_1_io_pCrd_2_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[35] = slices_1_io_pCrd_3_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[36] = slices_1_io_pCrd_4_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[37] = slices_1_io_pCrd_5_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[38] = slices_1_io_pCrd_6_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[39] = slices_1_io_pCrd_7_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[40] = slices_1_io_pCrd_8_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[41] = slices_1_io_pCrd_9_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[42] = slices_1_io_pCrd_10_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[43] = slices_1_io_pCrd_11_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[44] = slices_1_io_pCrd_12_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[45] = slices_1_io_pCrd_13_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[46] = slices_1_io_pCrd_14_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[47] = slices_1_io_pCrd_15_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[48] = slices_2_io_pCrd_0_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[49] = slices_2_io_pCrd_1_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[50] = slices_2_io_pCrd_2_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[51] = slices_2_io_pCrd_3_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[52] = slices_2_io_pCrd_4_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[53] = slices_2_io_pCrd_5_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[54] = slices_2_io_pCrd_6_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[55] = slices_2_io_pCrd_7_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[56] = slices_2_io_pCrd_8_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[57] = slices_2_io_pCrd_9_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[58] = slices_2_io_pCrd_10_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[59] = slices_2_io_pCrd_11_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[60] = slices_2_io_pCrd_12_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[61] = slices_2_io_pCrd_13_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[62] = slices_2_io_pCrd_14_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[63] = slices_2_io_pCrd_15_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[64] = slices_3_io_pCrd_0_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[65] = slices_3_io_pCrd_1_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[66] = slices_3_io_pCrd_2_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[67] = slices_3_io_pCrd_3_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[68] = slices_3_io_pCrd_4_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[69] = slices_3_io_pCrd_5_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[70] = slices_3_io_pCrd_6_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[71] = slices_3_io_pCrd_7_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[72] = slices_3_io_pCrd_8_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[73] = slices_3_io_pCrd_9_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[74] = slices_3_io_pCrd_10_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[75] = slices_3_io_pCrd_11_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[76] = slices_3_io_pCrd_12_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[77] = slices_3_io_pCrd_13_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[78] = slices_3_io_pCrd_14_query_bits_pCrdType;
  assign pcrdQuery_pCrdType[79] = slices_3_io_pCrd_15_query_bits_pCrdType;
  assign pcrdQuery_srcID[0] = mmioBridge_io_pCrd_0_query_bits_srcID;
  assign pcrdQuery_srcID[1] = mmioBridge_io_pCrd_1_query_bits_srcID;
  assign pcrdQuery_srcID[2] = mmioBridge_io_pCrd_2_query_bits_srcID;
  assign pcrdQuery_srcID[3] = mmioBridge_io_pCrd_3_query_bits_srcID;
  assign pcrdQuery_srcID[4] = mmioBridge_io_pCrd_4_query_bits_srcID;
  assign pcrdQuery_srcID[5] = mmioBridge_io_pCrd_5_query_bits_srcID;
  assign pcrdQuery_srcID[6] = mmioBridge_io_pCrd_6_query_bits_srcID;
  assign pcrdQuery_srcID[7] = mmioBridge_io_pCrd_7_query_bits_srcID;
  assign pcrdQuery_srcID[8] = mmioBridge_io_pCrd_8_query_bits_srcID;
  assign pcrdQuery_srcID[9] = mmioBridge_io_pCrd_9_query_bits_srcID;
  assign pcrdQuery_srcID[10] = mmioBridge_io_pCrd_10_query_bits_srcID;
  assign pcrdQuery_srcID[11] = mmioBridge_io_pCrd_11_query_bits_srcID;
  assign pcrdQuery_srcID[12] = mmioBridge_io_pCrd_12_query_bits_srcID;
  assign pcrdQuery_srcID[13] = mmioBridge_io_pCrd_13_query_bits_srcID;
  assign pcrdQuery_srcID[14] = mmioBridge_io_pCrd_14_query_bits_srcID;
  assign pcrdQuery_srcID[15] = mmioBridge_io_pCrd_15_query_bits_srcID;
  assign pcrdQuery_srcID[16] = slices_0_io_pCrd_0_query_bits_srcID;
  assign pcrdQuery_srcID[17] = slices_0_io_pCrd_1_query_bits_srcID;
  assign pcrdQuery_srcID[18] = slices_0_io_pCrd_2_query_bits_srcID;
  assign pcrdQuery_srcID[19] = slices_0_io_pCrd_3_query_bits_srcID;
  assign pcrdQuery_srcID[20] = slices_0_io_pCrd_4_query_bits_srcID;
  assign pcrdQuery_srcID[21] = slices_0_io_pCrd_5_query_bits_srcID;
  assign pcrdQuery_srcID[22] = slices_0_io_pCrd_6_query_bits_srcID;
  assign pcrdQuery_srcID[23] = slices_0_io_pCrd_7_query_bits_srcID;
  assign pcrdQuery_srcID[24] = slices_0_io_pCrd_8_query_bits_srcID;
  assign pcrdQuery_srcID[25] = slices_0_io_pCrd_9_query_bits_srcID;
  assign pcrdQuery_srcID[26] = slices_0_io_pCrd_10_query_bits_srcID;
  assign pcrdQuery_srcID[27] = slices_0_io_pCrd_11_query_bits_srcID;
  assign pcrdQuery_srcID[28] = slices_0_io_pCrd_12_query_bits_srcID;
  assign pcrdQuery_srcID[29] = slices_0_io_pCrd_13_query_bits_srcID;
  assign pcrdQuery_srcID[30] = slices_0_io_pCrd_14_query_bits_srcID;
  assign pcrdQuery_srcID[31] = slices_0_io_pCrd_15_query_bits_srcID;
  assign pcrdQuery_srcID[32] = slices_1_io_pCrd_0_query_bits_srcID;
  assign pcrdQuery_srcID[33] = slices_1_io_pCrd_1_query_bits_srcID;
  assign pcrdQuery_srcID[34] = slices_1_io_pCrd_2_query_bits_srcID;
  assign pcrdQuery_srcID[35] = slices_1_io_pCrd_3_query_bits_srcID;
  assign pcrdQuery_srcID[36] = slices_1_io_pCrd_4_query_bits_srcID;
  assign pcrdQuery_srcID[37] = slices_1_io_pCrd_5_query_bits_srcID;
  assign pcrdQuery_srcID[38] = slices_1_io_pCrd_6_query_bits_srcID;
  assign pcrdQuery_srcID[39] = slices_1_io_pCrd_7_query_bits_srcID;
  assign pcrdQuery_srcID[40] = slices_1_io_pCrd_8_query_bits_srcID;
  assign pcrdQuery_srcID[41] = slices_1_io_pCrd_9_query_bits_srcID;
  assign pcrdQuery_srcID[42] = slices_1_io_pCrd_10_query_bits_srcID;
  assign pcrdQuery_srcID[43] = slices_1_io_pCrd_11_query_bits_srcID;
  assign pcrdQuery_srcID[44] = slices_1_io_pCrd_12_query_bits_srcID;
  assign pcrdQuery_srcID[45] = slices_1_io_pCrd_13_query_bits_srcID;
  assign pcrdQuery_srcID[46] = slices_1_io_pCrd_14_query_bits_srcID;
  assign pcrdQuery_srcID[47] = slices_1_io_pCrd_15_query_bits_srcID;
  assign pcrdQuery_srcID[48] = slices_2_io_pCrd_0_query_bits_srcID;
  assign pcrdQuery_srcID[49] = slices_2_io_pCrd_1_query_bits_srcID;
  assign pcrdQuery_srcID[50] = slices_2_io_pCrd_2_query_bits_srcID;
  assign pcrdQuery_srcID[51] = slices_2_io_pCrd_3_query_bits_srcID;
  assign pcrdQuery_srcID[52] = slices_2_io_pCrd_4_query_bits_srcID;
  assign pcrdQuery_srcID[53] = slices_2_io_pCrd_5_query_bits_srcID;
  assign pcrdQuery_srcID[54] = slices_2_io_pCrd_6_query_bits_srcID;
  assign pcrdQuery_srcID[55] = slices_2_io_pCrd_7_query_bits_srcID;
  assign pcrdQuery_srcID[56] = slices_2_io_pCrd_8_query_bits_srcID;
  assign pcrdQuery_srcID[57] = slices_2_io_pCrd_9_query_bits_srcID;
  assign pcrdQuery_srcID[58] = slices_2_io_pCrd_10_query_bits_srcID;
  assign pcrdQuery_srcID[59] = slices_2_io_pCrd_11_query_bits_srcID;
  assign pcrdQuery_srcID[60] = slices_2_io_pCrd_12_query_bits_srcID;
  assign pcrdQuery_srcID[61] = slices_2_io_pCrd_13_query_bits_srcID;
  assign pcrdQuery_srcID[62] = slices_2_io_pCrd_14_query_bits_srcID;
  assign pcrdQuery_srcID[63] = slices_2_io_pCrd_15_query_bits_srcID;
  assign pcrdQuery_srcID[64] = slices_3_io_pCrd_0_query_bits_srcID;
  assign pcrdQuery_srcID[65] = slices_3_io_pCrd_1_query_bits_srcID;
  assign pcrdQuery_srcID[66] = slices_3_io_pCrd_2_query_bits_srcID;
  assign pcrdQuery_srcID[67] = slices_3_io_pCrd_3_query_bits_srcID;
  assign pcrdQuery_srcID[68] = slices_3_io_pCrd_4_query_bits_srcID;
  assign pcrdQuery_srcID[69] = slices_3_io_pCrd_5_query_bits_srcID;
  assign pcrdQuery_srcID[70] = slices_3_io_pCrd_6_query_bits_srcID;
  assign pcrdQuery_srcID[71] = slices_3_io_pCrd_7_query_bits_srcID;
  assign pcrdQuery_srcID[72] = slices_3_io_pCrd_8_query_bits_srcID;
  assign pcrdQuery_srcID[73] = slices_3_io_pCrd_9_query_bits_srcID;
  assign pcrdQuery_srcID[74] = slices_3_io_pCrd_10_query_bits_srcID;
  assign pcrdQuery_srcID[75] = slices_3_io_pCrd_11_query_bits_srcID;
  assign pcrdQuery_srcID[76] = slices_3_io_pCrd_12_query_bits_srcID;
  assign pcrdQuery_srcID[77] = slices_3_io_pCrd_13_query_bits_srcID;
  assign pcrdQuery_srcID[78] = slices_3_io_pCrd_14_query_bits_srcID;
  assign pcrdQuery_srcID[79] = slices_3_io_pCrd_15_query_bits_srcID;
  assign pcrdArb_outValid = pcrdgrant_arb_io_out_valid;

  xs_TL2CHICoupledL2_core u_core (
    .clock                (clock),
    .reset                (reset),
    .hintArb_valid        (hintArb_valid),
    .hintArb_sourceId     (hintArb_sourceId),
    .hintArb_chosen       (hintArb_chosen),
    .hintArb_ready        (hintArb_ready),
    .hintFire             (hintFire),
    .slice_dValid         (slice_dValid),
    .slice_dOpcode        (slice_dOpcode),
    .slice_dReady         (slice_dReady),
    .in_dReady            (in_dReady),
    .in_dValid            (in_dValid),
    .pf_reqValid          (pf_reqValid),
    .pf_reqSet            (pf_reqSet),
    .slice_pfReqReady     (slice_pfReqReady),
    .slice_pfReqValid     (slice_pfReqValid),
    .pf_reqReady          (pf_reqReady),
    .train_tag            (train_tag),
    .train_set            (train_set),
    .trainArb_tag         (trainArb_tag),
    .trainArb_set         (trainArb_set),
    .slice_bAddr          (slice_bAddr),
    .in_bAddr             (in_bAddr),
    .slice_errAddr        (slice_errAddr),
    .eccArb_addr          (eccArb_addr),
    .eccArb_outValid      (eccArb_outValid),
    .eccArb_outBitsValid  (eccArb_outBitsValid),
    .errorValid           (errorValid),
    .slice_perf           (slice_perf),
    .perf                 (perf),
    .slice_l2Miss         (slice_l2Miss),
    .l2Miss               (l2Miss),
    .txReqArb_outValid    (txReqArb_outValid),
    .txReqArb_chosen      (txReqArb_chosen),
    .txReqArb_outTxnID    (txReqArb_outTxnID),
    .txReqArb_mmioReady   (txReqArb_mmioReady),
    .mmio_txReqValid      (mmio_txReqValid),
    .lm_txReqReady        (lm_txReqReady),
    .lm_syscoreq          (lm_syscoreq),
    .chi_syscoack         (chi_syscoack),
    .lm_txReqValid        (lm_txReqValid),
    .lm_txReqTxnID        (lm_txReqTxnID),
    .txReqArb_outReady    (txReqArb_outReady),
    .rxSnp_valid          (rxSnp_valid),
    .rxSnp_bank           (rxSnp_bank),
    .slice_rxSnpReady     (slice_rxSnpReady),
    .slice_rxSnpValid     (slice_rxSnpValid),
    .rxSnp_ready          (rxSnp_ready),
    .rxRsp_valid          (rxRsp_valid),
    .rxRsp_opcode         (rxRsp_opcode),
    .rxRsp_txnID          (rxRsp_txnID),
    .slice_rxRspReady     (slice_rxRspReady),
    .mmio_rxRspReady      (mmio_rxRspReady),
    .slice_rxRspValid     (slice_rxRspValid),
    .mmio_rxRspValid      (mmio_rxRspValid),
    .rxRsp_innerTxnID     (rxRsp_innerTxnID),
    .rxRsp_ready          (rxRsp_ready),
    .rxDat_valid          (rxDat_valid),
    .rxDat_txnID          (rxDat_txnID),
    .slice_rxDatReady     (slice_rxDatReady),
    .mmio_rxDatReady      (mmio_rxDatReady),
    .slice_rxDatValid     (slice_rxDatValid),
    .mmio_rxDatValid      (mmio_rxDatValid),
    .rxDat_innerTxnID     (rxDat_innerTxnID),
    .rxDat_ready          (rxDat_ready),
    .rxRsp_pCrdType       (rxRsp_pCrdType),
    .rxRsp_srcID          (rxRsp_srcID),
    .pcrdEnq_valid        (pcrdEnq_valid),
    .pcrdEnq_pCrdType     (pcrdEnq_pCrdType),
    .pcrdEnq_srcID        (pcrdEnq_srcID),
    .pcrdHead_valid       (pcrdHead_valid),
    .pcrdHead_pCrdType    (pcrdHead_pCrdType),
    .pcrdHead_srcID       (pcrdHead_srcID),
    .pcrdQuery_valid      (pcrdQuery_valid),
    .pcrdQuery_pCrdType   (pcrdQuery_pCrdType),
    .pcrdQuery_srcID      (pcrdQuery_srcID),
    .pcrdHit              (pcrdHit),
    .pcrdArb_outValid     (pcrdArb_outValid)
  );

  // ---- 32 个 child（实例名 / 顺序同 golden）----
  MMIOBridge mmioBridge (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_mmio_in_a_ready                     (auto_mmioBridge_mmio_in_a_ready),
    .auto_mmio_in_a_valid                     (auto_mmioBridge_mmio_in_a_valid),
    .auto_mmio_in_a_bits_opcode               (auto_mmioBridge_mmio_in_a_bits_opcode),
    .auto_mmio_in_a_bits_param                (auto_mmioBridge_mmio_in_a_bits_param),
    .auto_mmio_in_a_bits_size                 (auto_mmioBridge_mmio_in_a_bits_size),
    .auto_mmio_in_a_bits_source               (auto_mmioBridge_mmio_in_a_bits_source),
    .auto_mmio_in_a_bits_address              (auto_mmioBridge_mmio_in_a_bits_address),
    .auto_mmio_in_a_bits_user_memBackType_MM  (auto_mmioBridge_mmio_in_a_bits_user_memBackType_MM),
    .auto_mmio_in_a_bits_user_memPageType_NC  (auto_mmioBridge_mmio_in_a_bits_user_memPageType_NC),
    .auto_mmio_in_a_bits_mask                 (auto_mmioBridge_mmio_in_a_bits_mask),
    .auto_mmio_in_a_bits_data                 (auto_mmioBridge_mmio_in_a_bits_data),
    .auto_mmio_in_a_bits_corrupt              (auto_mmioBridge_mmio_in_a_bits_corrupt),
    .auto_mmio_in_d_ready                     (auto_mmioBridge_mmio_in_d_ready),
    .auto_mmio_in_d_valid                     (auto_mmioBridge_mmio_in_d_valid),
    .auto_mmio_in_d_bits_opcode               (auto_mmioBridge_mmio_in_d_bits_opcode),
    .auto_mmio_in_d_bits_param                (auto_mmioBridge_mmio_in_d_bits_param),
    .auto_mmio_in_d_bits_size                 (auto_mmioBridge_mmio_in_d_bits_size),
    .auto_mmio_in_d_bits_source               (auto_mmioBridge_mmio_in_d_bits_source),
    .auto_mmio_in_d_bits_sink                 (auto_mmioBridge_mmio_in_d_bits_sink),
    .auto_mmio_in_d_bits_denied               (auto_mmioBridge_mmio_in_d_bits_denied),
    .auto_mmio_in_d_bits_data                 (auto_mmioBridge_mmio_in_d_bits_data),
    .auto_mmio_in_d_bits_corrupt              (auto_mmioBridge_mmio_in_d_bits_corrupt),
    .io_tx_req_ready                          (txreq_arb_io_in_4_ready),
    .io_tx_req_valid                          (mmioBridge_io_tx_req_valid),
    .io_tx_req_bits_qos                       (mmioBridge_io_tx_req_bits_qos),
    .io_tx_req_bits_tgtID                     (mmioBridge_io_tx_req_bits_tgtID),
    .io_tx_req_bits_srcID                     (),
    .io_tx_req_bits_txnID                     (mmioBridge_io_tx_req_bits_txnID),
    .io_tx_req_bits_returnNID                 (mmioBridge_io_tx_req_bits_returnNID),
    .io_tx_req_bits_stashNIDValid             (mmioBridge_io_tx_req_bits_stashNIDValid),
    .io_tx_req_bits_returnTxnID               (mmioBridge_io_tx_req_bits_returnTxnID),
    .io_tx_req_bits_opcode                    (mmioBridge_io_tx_req_bits_opcode),
    .io_tx_req_bits_size                      (mmioBridge_io_tx_req_bits_size),
    .io_tx_req_bits_addr                      (mmioBridge_io_tx_req_bits_addr),
    .io_tx_req_bits_ns                        (mmioBridge_io_tx_req_bits_ns),
    .io_tx_req_bits_likelyshared              (mmioBridge_io_tx_req_bits_likelyshared),
    .io_tx_req_bits_allowRetry                (mmioBridge_io_tx_req_bits_allowRetry),
    .io_tx_req_bits_order                     (mmioBridge_io_tx_req_bits_order),
    .io_tx_req_bits_pCrdType                  (mmioBridge_io_tx_req_bits_pCrdType),
    .io_tx_req_bits_memAttr_allocate          (mmioBridge_io_tx_req_bits_memAttr_allocate),
    .io_tx_req_bits_memAttr_cacheable         (mmioBridge_io_tx_req_bits_memAttr_cacheable),
    .io_tx_req_bits_memAttr_device            (mmioBridge_io_tx_req_bits_memAttr_device),
    .io_tx_req_bits_memAttr_ewa               (mmioBridge_io_tx_req_bits_memAttr_ewa),
    .io_tx_req_bits_snpAttr                   (mmioBridge_io_tx_req_bits_snpAttr),
    .io_tx_req_bits_lpIDWithPadding           (mmioBridge_io_tx_req_bits_lpIDWithPadding),
    .io_tx_req_bits_snoopMe                   (mmioBridge_io_tx_req_bits_snoopMe),
    .io_tx_req_bits_expCompAck                (mmioBridge_io_tx_req_bits_expCompAck),
    .io_tx_req_bits_tagOp                     (mmioBridge_io_tx_req_bits_tagOp),
    .io_tx_req_bits_traceTag                  (mmioBridge_io_tx_req_bits_traceTag),
    .io_tx_req_bits_mpam_perfMonGroup         (mmioBridge_io_tx_req_bits_mpam_perfMonGroup),
    .io_tx_req_bits_mpam_partID               (mmioBridge_io_tx_req_bits_mpam_partID),
    .io_tx_req_bits_mpam_mpamNS               (mmioBridge_io_tx_req_bits_mpam_mpamNS),
    .io_tx_req_bits_rsvdc                     (mmioBridge_io_tx_req_bits_rsvdc),
    .io_tx_dat_ready                          (txdat_arb_io_in_4_ready),
    .io_tx_dat_valid                          (mmioBridge_io_tx_dat_valid),
    .io_tx_dat_bits_qos                       (mmioBridge_io_tx_dat_bits_qos),
    .io_tx_dat_bits_tgtID                     (mmioBridge_io_tx_dat_bits_tgtID),
    .io_tx_dat_bits_srcID                     (),
    .io_tx_dat_bits_txnID                     (mmioBridge_io_tx_dat_bits_txnID),
    .io_tx_dat_bits_homeNID                   (mmioBridge_io_tx_dat_bits_homeNID),
    .io_tx_dat_bits_opcode                    (mmioBridge_io_tx_dat_bits_opcode),
    .io_tx_dat_bits_respErr                   (mmioBridge_io_tx_dat_bits_respErr),
    .io_tx_dat_bits_resp                      (mmioBridge_io_tx_dat_bits_resp),
    .io_tx_dat_bits_dataSource                (mmioBridge_io_tx_dat_bits_dataSource),
    .io_tx_dat_bits_cBusy                     (mmioBridge_io_tx_dat_bits_cBusy),
    .io_tx_dat_bits_dbID                      (mmioBridge_io_tx_dat_bits_dbID),
    .io_tx_dat_bits_ccID                      (mmioBridge_io_tx_dat_bits_ccID),
    .io_tx_dat_bits_dataID                    (mmioBridge_io_tx_dat_bits_dataID),
    .io_tx_dat_bits_tagOp                     (mmioBridge_io_tx_dat_bits_tagOp),
    .io_tx_dat_bits_tag                       (mmioBridge_io_tx_dat_bits_tag),
    .io_tx_dat_bits_tu                        (mmioBridge_io_tx_dat_bits_tu),
    .io_tx_dat_bits_traceTag                  (mmioBridge_io_tx_dat_bits_traceTag),
    .io_tx_dat_bits_rsvdc                     (mmioBridge_io_tx_dat_bits_rsvdc),
    .io_tx_dat_bits_be                        (mmioBridge_io_tx_dat_bits_be),
    .io_tx_dat_bits_data                      (mmioBridge_io_tx_dat_bits_data),
    .io_tx_dat_bits_dataCheck                 (mmioBridge_io_tx_dat_bits_dataCheck),
    .io_tx_dat_bits_poison                    (mmioBridge_io_tx_dat_bits_poison),
    .io_rx_rsp_ready                          (mmioBridge_io_rx_rsp_ready),
    .io_rx_rsp_valid                          (mmio_rxRspValid),
    .io_rx_rsp_bits_qos                       (rxrspPipe_pipeline_io_out_bits_qos),
    .io_rx_rsp_bits_tgtID                     (rxrspPipe_pipeline_io_out_bits_tgtID),
    .io_rx_rsp_bits_srcID                     (rxrspPipe_pipeline_io_out_bits_srcID),
    .io_rx_rsp_bits_txnID                     (rxRsp_innerTxnID),
    .io_rx_rsp_bits_opcode                    (rxrspPipe_pipeline_io_out_bits_opcode),
    .io_rx_rsp_bits_respErr                   (rxrspPipe_pipeline_io_out_bits_respErr),
    .io_rx_rsp_bits_resp                      (rxrspPipe_pipeline_io_out_bits_resp),
    .io_rx_rsp_bits_fwdState                  (rxrspPipe_pipeline_io_out_bits_fwdState),
    .io_rx_rsp_bits_cBusy                     (rxrspPipe_pipeline_io_out_bits_cBusy),
    .io_rx_rsp_bits_dbID                      (rxrspPipe_pipeline_io_out_bits_dbID),
    .io_rx_rsp_bits_pCrdType                  (rxrspPipe_pipeline_io_out_bits_pCrdType),
    .io_rx_rsp_bits_tagOp                     (rxrspPipe_pipeline_io_out_bits_tagOp),
    .io_rx_rsp_bits_traceTag                  (rxrspPipe_pipeline_io_out_bits_traceTag),
    .io_rx_dat_ready                          (mmioBridge_io_rx_dat_ready),
    .io_rx_dat_valid                          (mmio_rxDatValid),
    .io_rx_dat_bits_qos                       (rxdatPipe_pipeline_io_out_bits_qos),
    .io_rx_dat_bits_tgtID                     (rxdatPipe_pipeline_io_out_bits_tgtID),
    .io_rx_dat_bits_srcID                     (rxdatPipe_pipeline_io_out_bits_srcID),
    .io_rx_dat_bits_txnID                     (rxDat_innerTxnID),
    .io_rx_dat_bits_homeNID                   (rxdatPipe_pipeline_io_out_bits_homeNID),
    .io_rx_dat_bits_opcode                    (rxdatPipe_pipeline_io_out_bits_opcode),
    .io_rx_dat_bits_respErr                   (rxdatPipe_pipeline_io_out_bits_respErr),
    .io_rx_dat_bits_resp                      (rxdatPipe_pipeline_io_out_bits_resp),
    .io_rx_dat_bits_dataSource                (rxdatPipe_pipeline_io_out_bits_dataSource),
    .io_rx_dat_bits_cBusy                     (rxdatPipe_pipeline_io_out_bits_cBusy),
    .io_rx_dat_bits_dbID                      (rxdatPipe_pipeline_io_out_bits_dbID),
    .io_rx_dat_bits_ccID                      (rxdatPipe_pipeline_io_out_bits_ccID),
    .io_rx_dat_bits_dataID                    (rxdatPipe_pipeline_io_out_bits_dataID),
    .io_rx_dat_bits_tagOp                     (rxdatPipe_pipeline_io_out_bits_tagOp),
    .io_rx_dat_bits_tag                       (rxdatPipe_pipeline_io_out_bits_tag),
    .io_rx_dat_bits_tu                        (rxdatPipe_pipeline_io_out_bits_tu),
    .io_rx_dat_bits_traceTag                  (rxdatPipe_pipeline_io_out_bits_traceTag),
    .io_rx_dat_bits_rsvdc                     (rxdatPipe_pipeline_io_out_bits_rsvdc),
    .io_rx_dat_bits_be                        (rxdatPipe_pipeline_io_out_bits_be),
    .io_rx_dat_bits_data                      (rxdatPipe_pipeline_io_out_bits_data),
    .io_rx_dat_bits_dataCheck                 (rxdatPipe_pipeline_io_out_bits_dataCheck),
    .io_rx_dat_bits_poison                    (rxdatPipe_pipeline_io_out_bits_poison),
    .io_pCrd_0_query_valid                    (mmioBridge_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType            (mmioBridge_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID               (mmioBridge_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant                          (pcrdgrant_arb_io_in_0_ready),
    .io_pCrd_1_query_valid                    (mmioBridge_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType            (mmioBridge_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID               (mmioBridge_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant                          (pcrdgrant_arb_io_in_1_ready),
    .io_pCrd_2_query_valid                    (mmioBridge_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType            (mmioBridge_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID               (mmioBridge_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant                          (pcrdgrant_arb_io_in_2_ready),
    .io_pCrd_3_query_valid                    (mmioBridge_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType            (mmioBridge_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID               (mmioBridge_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant                          (pcrdgrant_arb_io_in_3_ready),
    .io_pCrd_4_query_valid                    (mmioBridge_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType            (mmioBridge_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID               (mmioBridge_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant                          (pcrdgrant_arb_io_in_4_ready),
    .io_pCrd_5_query_valid                    (mmioBridge_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType            (mmioBridge_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID               (mmioBridge_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant                          (pcrdgrant_arb_io_in_5_ready),
    .io_pCrd_6_query_valid                    (mmioBridge_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType            (mmioBridge_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID               (mmioBridge_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant                          (pcrdgrant_arb_io_in_6_ready),
    .io_pCrd_7_query_valid                    (mmioBridge_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType            (mmioBridge_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID               (mmioBridge_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant                          (pcrdgrant_arb_io_in_7_ready),
    .io_pCrd_8_query_valid                    (mmioBridge_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType            (mmioBridge_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID               (mmioBridge_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant                          (pcrdgrant_arb_io_in_8_ready),
    .io_pCrd_9_query_valid                    (mmioBridge_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType            (mmioBridge_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID               (mmioBridge_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant                          (pcrdgrant_arb_io_in_9_ready),
    .io_pCrd_10_query_valid                   (mmioBridge_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType           (mmioBridge_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID              (mmioBridge_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant                         (pcrdgrant_arb_io_in_10_ready),
    .io_pCrd_11_query_valid                   (mmioBridge_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType           (mmioBridge_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID              (mmioBridge_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant                         (pcrdgrant_arb_io_in_11_ready),
    .io_pCrd_12_query_valid                   (mmioBridge_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType           (mmioBridge_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID              (mmioBridge_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant                         (pcrdgrant_arb_io_in_12_ready),
    .io_pCrd_13_query_valid                   (mmioBridge_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType           (mmioBridge_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID              (mmioBridge_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant                         (pcrdgrant_arb_io_in_13_ready),
    .io_pCrd_14_query_valid                   (mmioBridge_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType           (mmioBridge_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID              (mmioBridge_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant                         (pcrdgrant_arb_io_in_14_ready),
    .io_pCrd_15_query_valid                   (mmioBridge_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType           (mmioBridge_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID              (mmioBridge_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant                         (pcrdgrant_arb_io_in_15_ready)
  );
  Prefetcher prefetcher (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_train_ready                           (prefetcher_io_train_ready),
    .io_train_valid                           (prefetch_train_arb_io_out_valid),
    .io_train_bits_tag                        (prefetch_train_arb_io_out_bits_tag),
    .io_train_bits_set                        (prefetch_train_arb_io_out_bits_set),
    .io_train_bits_needT                      (prefetch_train_arb_io_out_bits_needT),
    .io_train_bits_source                     (prefetch_train_arb_io_out_bits_source),
    .io_train_bits_vaddr                      (prefetch_train_arb_io_out_bits_vaddr),
    .io_train_bits_reqsource                  (prefetch_train_arb_io_out_bits_reqsource),
    .io_tlb_req_req_valid                     (io_l2_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr                (io_l2_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_cmd                  (io_l2_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_isPrefetch           (io_l2_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_kill                 (io_l2_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_no_translate         (io_l2_tlb_req_req_bits_no_translate),
    .io_tlb_req_resp_valid                    (io_l2_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0             (io_l2_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt                (io_l2_tlb_req_resp_bits_pbmt),
    .io_tlb_req_resp_bits_miss                (io_l2_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld       (io_l2_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld        (io_l2_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld        (io_l2_tlb_req_resp_bits_excp_0_af_ld),
    .io_tlb_req_pmp_resp_ld                   (io_l2_tlb_req_pmp_resp_ld),
    .io_tlb_req_pmp_resp_mmio                 (io_l2_tlb_req_pmp_resp_mmio),
    .io_req_ready                             (pf_reqReady),
    .io_req_valid                             (prefetcher_io_req_valid),
    .io_req_bits_tag                          (prefetcher_io_req_bits_tag),
    .io_req_bits_set                          (prefetcher_io_req_bits_set),
    .io_req_bits_vaddr                        (prefetcher_io_req_bits_vaddr),
    .io_req_bits_needT                        (prefetcher_io_req_bits_needT),
    .io_req_bits_source                       (prefetcher_io_req_bits_source),
    .io_req_bits_pfSource                     (prefetcher_io_req_bits_pfSource),
    .io_resp_ready                            (prefetcher_io_resp_ready),
    .io_resp_valid                            (prefetch_resp_arb_io_out_valid),
    .io_resp_bits_pfSource                    (prefetch_resp_arb_io_out_bits_pfSource),
    .io_recv_addr_valid                       (auto_pf_recv_in_addr_valid),
    .io_recv_addr_bits_addr                   (auto_pf_recv_in_addr),
    .io_recv_addr_bits_pfSource               (auto_pf_recv_in_pf_source),
    .pfCtrlFromCore_l2_pf_master_en           (io_pfCtrlFromCore_l2_pf_master_en),
    .pfCtrlFromCore_l2_pf_recv_en             (io_pfCtrlFromCore_l2_pf_recv_en),
    .pfCtrlFromCore_l2_pbop_en                (io_pfCtrlFromCore_l2_pbop_en),
    .pfCtrlFromCore_l2_vbop_en                (io_pfCtrlFromCore_l2_vbop_en),
    .pfCtrlFromCore_l2_pf_delay_latency       (io_pfCtrlFromCore_l2_pf_delay_latency),
    .sigFromSrams_bore_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_1_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (io_dft_cgen),
    .boreChildrenBd_bore_array                (mbistPl_toNextPipeline_0_array),
    .boreChildrenBd_bore_all                  (mbistPl_toNextPipeline_0_all),
    .boreChildrenBd_bore_req                  (mbistPl_toNextPipeline_0_req),
    .boreChildrenBd_bore_ack                  (prefetcher_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen              (mbistPl_toNextPipeline_0_writeen),
    .boreChildrenBd_bore_be                   (mbistPl_toNextPipeline_0_be),
    .boreChildrenBd_bore_addr                 (mbistPl_toNextPipeline_0_addr),
    .boreChildrenBd_bore_indata               (mbistPl_toNextPipeline_0_indata),
    .boreChildrenBd_bore_readen               (mbistPl_toNextPipeline_0_readen),
    .boreChildrenBd_bore_addr_rd              (mbistPl_toNextPipeline_0_addr_rd),
    .boreChildrenBd_bore_outdata              (prefetcher_boreChildrenBd_bore_outdata)
  );
  FastArbiter prefetch_train_arb (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_0_ready                            (prefetch_train_arb_io_in_0_ready),
    .io_in_0_valid                            (train_pipeline_io_out_valid),
    .io_in_0_bits_tag                         (trainArb_tag[0]),
    .io_in_0_bits_set                         (trainArb_set[0]),
    .io_in_0_bits_needT                       (train_pipeline_io_out_bits_needT),
    .io_in_0_bits_source                      (train_pipeline_io_out_bits_source),
    .io_in_0_bits_vaddr                       (train_pipeline_io_out_bits_vaddr),
    .io_in_0_bits_reqsource                   (train_pipeline_io_out_bits_reqsource),
    .io_in_1_ready                            (prefetch_train_arb_io_in_1_ready),
    .io_in_1_valid                            (train_pipeline_1_io_out_valid),
    .io_in_1_bits_tag                         (trainArb_tag[1]),
    .io_in_1_bits_set                         (trainArb_set[1]),
    .io_in_1_bits_needT                       (train_pipeline_1_io_out_bits_needT),
    .io_in_1_bits_source                      (train_pipeline_1_io_out_bits_source),
    .io_in_1_bits_vaddr                       (train_pipeline_1_io_out_bits_vaddr),
    .io_in_1_bits_reqsource                   (train_pipeline_1_io_out_bits_reqsource),
    .io_in_2_ready                            (prefetch_train_arb_io_in_2_ready),
    .io_in_2_valid                            (train_pipeline_2_io_out_valid),
    .io_in_2_bits_tag                         (trainArb_tag[2]),
    .io_in_2_bits_set                         (trainArb_set[2]),
    .io_in_2_bits_needT                       (train_pipeline_2_io_out_bits_needT),
    .io_in_2_bits_source                      (train_pipeline_2_io_out_bits_source),
    .io_in_2_bits_vaddr                       (train_pipeline_2_io_out_bits_vaddr),
    .io_in_2_bits_reqsource                   (train_pipeline_2_io_out_bits_reqsource),
    .io_in_3_ready                            (prefetch_train_arb_io_in_3_ready),
    .io_in_3_valid                            (train_pipeline_3_io_out_valid),
    .io_in_3_bits_tag                         (trainArb_tag[3]),
    .io_in_3_bits_set                         (trainArb_set[3]),
    .io_in_3_bits_needT                       (train_pipeline_3_io_out_bits_needT),
    .io_in_3_bits_source                      (train_pipeline_3_io_out_bits_source),
    .io_in_3_bits_vaddr                       (train_pipeline_3_io_out_bits_vaddr),
    .io_in_3_bits_reqsource                   (train_pipeline_3_io_out_bits_reqsource),
    .io_out_ready                             (prefetcher_io_train_ready),
    .io_out_valid                             (prefetch_train_arb_io_out_valid),
    .io_out_bits_tag                          (prefetch_train_arb_io_out_bits_tag),
    .io_out_bits_set                          (prefetch_train_arb_io_out_bits_set),
    .io_out_bits_needT                        (prefetch_train_arb_io_out_bits_needT),
    .io_out_bits_source                       (prefetch_train_arb_io_out_bits_source),
    .io_out_bits_vaddr                        (prefetch_train_arb_io_out_bits_vaddr),
    .io_out_bits_reqsource                    (prefetch_train_arb_io_out_bits_reqsource)
  );
  FastArbiter_1 prefetch_resp_arb (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_0_ready                            (prefetch_resp_arb_io_in_0_ready),
    .io_in_0_valid                            (resp_pipeline_io_out_valid),
    .io_in_0_bits_pfSource                    (resp_pipeline_io_out_bits_pfSource),
    .io_in_1_ready                            (prefetch_resp_arb_io_in_1_ready),
    .io_in_1_valid                            (resp_pipeline_1_io_out_valid),
    .io_in_1_bits_pfSource                    (resp_pipeline_1_io_out_bits_pfSource),
    .io_in_2_ready                            (prefetch_resp_arb_io_in_2_ready),
    .io_in_2_valid                            (resp_pipeline_2_io_out_valid),
    .io_in_2_bits_pfSource                    (resp_pipeline_2_io_out_bits_pfSource),
    .io_in_3_ready                            (prefetch_resp_arb_io_in_3_ready),
    .io_in_3_valid                            (resp_pipeline_3_io_out_valid),
    .io_in_3_bits_pfSource                    (resp_pipeline_3_io_out_bits_pfSource),
    .io_out_ready                             (prefetcher_io_resp_ready),
    .io_out_valid                             (prefetch_resp_arb_io_out_valid),
    .io_out_bits_pfSource                     (prefetch_resp_arb_io_out_bits_pfSource)
  );
  Slice slices_0 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_a_ready                            (auto_in_0_a_ready),
    .io_in_a_valid                            (auto_in_0_a_valid),
    .io_in_a_bits_opcode                      (auto_in_0_a_bits_opcode),
    .io_in_a_bits_param                       (auto_in_0_a_bits_param),
    .io_in_a_bits_size                        (auto_in_0_a_bits_size),
    .io_in_a_bits_source                      (auto_in_0_a_bits_source),
    .io_in_a_bits_address                     (auto_in_0_a_bits_address),
    .io_in_a_bits_user_reqSource              (auto_in_0_a_bits_user_reqSource),
    .io_in_a_bits_user_alias                  (auto_in_0_a_bits_user_alias),
    .io_in_a_bits_user_vaddr                  (auto_in_0_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint               (auto_in_0_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword              (auto_in_0_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt                     (auto_in_0_a_bits_corrupt),
    .io_in_b_ready                            (auto_in_0_b_ready),
    .io_in_b_valid                            (auto_in_0_b_valid),
    .io_in_b_bits_opcode                      (auto_in_0_b_bits_opcode),
    .io_in_b_bits_param                       (auto_in_0_b_bits_param),
    .io_in_b_bits_address                     (slices_0_io_in_b_bits_address),
    .io_in_b_bits_data                        (auto_in_0_b_bits_data),
    .io_in_c_ready                            (auto_in_0_c_ready),
    .io_in_c_valid                            (auto_in_0_c_valid),
    .io_in_c_bits_opcode                      (auto_in_0_c_bits_opcode),
    .io_in_c_bits_param                       (auto_in_0_c_bits_param),
    .io_in_c_bits_size                        (auto_in_0_c_bits_size),
    .io_in_c_bits_source                      (auto_in_0_c_bits_source),
    .io_in_c_bits_address                     (auto_in_0_c_bits_address),
    .io_in_c_bits_data                        (auto_in_0_c_bits_data),
    .io_in_c_bits_corrupt                     (auto_in_0_c_bits_corrupt),
    .io_in_d_ready                            (slice_dReady[0]),
    .io_in_d_valid                            (slices_0_io_in_d_valid),
    .io_in_d_bits_opcode                      (slices_0_io_in_d_bits_opcode),
    .io_in_d_bits_param                       (auto_in_0_d_bits_param),
    .io_in_d_bits_source                      (slices_0_io_in_d_bits_source),
    .io_in_d_bits_sink                        (auto_in_0_d_bits_sink),
    .io_in_d_bits_denied                      (auto_in_0_d_bits_denied),
    .io_in_d_bits_echo_isKeyword              (auto_in_0_d_bits_echo_isKeyword),
    .io_in_d_bits_data                        (auto_in_0_d_bits_data),
    .io_in_d_bits_corrupt                     (auto_in_0_d_bits_corrupt),
    .io_in_e_valid                            (auto_in_0_e_valid),
    .io_in_e_bits_sink                        (auto_in_0_e_bits_sink),
    .io_l1Hint_ready                          (l1HintArb_io_in_0_ready),
    .io_l1Hint_valid                          (slices_0_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId                  (slices_0_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword                 (slices_0_io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready                  (train_pipeline_io_in_ready),
    .io_prefetch_train_valid                  (slices_0_io_prefetch_train_valid),
    .io_prefetch_train_bits_tag               (slices_0_io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set               (slices_0_io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT             (slices_0_io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source            (slices_0_io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr             (slices_0_io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit               (slices_0_io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched        (slices_0_io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource          (slices_0_io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource         (slices_0_io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready                    (slices_0_io_prefetch_req_ready),
    .io_prefetch_req_valid                    (slice_pfReqValid[0]),
    .io_prefetch_req_bits_tag                 (prefetcher_io_req_bits_tag),
    .io_prefetch_req_bits_set                 (prefetcher_io_req_bits_set),
    .io_prefetch_req_bits_vaddr               (prefetcher_io_req_bits_vaddr),
    .io_prefetch_req_bits_needT               (prefetcher_io_req_bits_needT),
    .io_prefetch_req_bits_source              (prefetcher_io_req_bits_source),
    .io_prefetch_req_bits_pfSource            (prefetcher_io_req_bits_pfSource),
    .io_prefetch_resp_ready                   (resp_pipeline_io_in_ready),
    .io_prefetch_resp_valid                   (slices_0_io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag                (slices_0_io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set                (slices_0_io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr              (slices_0_io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource           (slices_0_io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid                       (slices_0_io_dirResult_valid),
    .io_dirResult_bits_hit                    (slices_0_io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch          (slices_0_io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc       (slices_0_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_bits_replacerInfo_channel   (slices_0_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_bits_replacerInfo_reqSource (slices_0_io_dirResult_bits_replacerInfo_reqSource),
    .io_hitPfInMSHR_valid                     (slices_0_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits                      (slices_0_io_hitPfInMSHR_bits),
    .io_pfSent_valid                          (slices_0_io_pfSent_valid),
    .io_pfSent_bits                           (slices_0_io_pfSent_bits),
    .io_pfLateInMSHR_valid                    (slices_0_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits                     (slices_0_io_pfLateInMSHR_bits),
    .io_error_valid                           (slices_0_io_error_valid),
    .io_error_bits_valid                      (slices_0_io_error_bits_valid),
    .io_error_bits_address                    (slices_0_io_error_bits_address),
    .io_l2Miss                                (slices_0_io_l2Miss),
    .io_msStatus_0_valid                      (slices_0_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel               (slices_0_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set                   (slices_0_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag                (slices_0_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss               (slices_0_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch           (slices_0_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid                      (slices_0_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel               (slices_0_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set                   (slices_0_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag                (slices_0_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss               (slices_0_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch           (slices_0_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid                      (slices_0_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel               (slices_0_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set                   (slices_0_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag                (slices_0_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss               (slices_0_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch           (slices_0_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid                      (slices_0_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel               (slices_0_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set                   (slices_0_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag                (slices_0_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss               (slices_0_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch           (slices_0_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid                      (slices_0_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel               (slices_0_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set                   (slices_0_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag                (slices_0_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss               (slices_0_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch           (slices_0_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid                      (slices_0_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel               (slices_0_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set                   (slices_0_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag                (slices_0_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss               (slices_0_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch           (slices_0_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid                      (slices_0_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel               (slices_0_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set                   (slices_0_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag                (slices_0_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss               (slices_0_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch           (slices_0_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid                      (slices_0_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel               (slices_0_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set                   (slices_0_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag                (slices_0_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss               (slices_0_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch           (slices_0_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid                      (slices_0_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel               (slices_0_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set                   (slices_0_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag                (slices_0_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss               (slices_0_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch           (slices_0_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid                      (slices_0_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel               (slices_0_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set                   (slices_0_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag                (slices_0_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss               (slices_0_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch           (slices_0_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid                     (slices_0_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel              (slices_0_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set                  (slices_0_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag               (slices_0_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss              (slices_0_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch          (slices_0_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid                     (slices_0_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel              (slices_0_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set                  (slices_0_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag               (slices_0_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss              (slices_0_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch          (slices_0_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid                     (slices_0_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel              (slices_0_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set                  (slices_0_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag               (slices_0_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss              (slices_0_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch          (slices_0_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid                     (slices_0_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel              (slices_0_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set                  (slices_0_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag               (slices_0_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss              (slices_0_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch          (slices_0_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid                     (slices_0_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel              (slices_0_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set                  (slices_0_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag               (slices_0_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss              (slices_0_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch          (slices_0_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid                     (slices_0_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel              (slices_0_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set                  (slices_0_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag               (slices_0_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss              (slices_0_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch          (slices_0_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid                       (slices_0_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel                (slices_0_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss                (slices_0_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch            (slices_0_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid                       (slices_0_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel                (slices_0_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss                (slices_0_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch            (slices_0_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid                       (slices_0_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel                (slices_0_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss                (slices_0_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch            (slices_0_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid                       (slices_0_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel                (slices_0_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss                (slices_0_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch            (slices_0_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid                       (slices_0_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel                (slices_0_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss                (slices_0_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch            (slices_0_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid                       (slices_0_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel                (slices_0_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss                (slices_0_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch            (slices_0_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid                       (slices_0_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel                (slices_0_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss                (slices_0_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch            (slices_0_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid                       (slices_0_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel                (slices_0_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss                (slices_0_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch            (slices_0_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid                       (slices_0_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel                (slices_0_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss                (slices_0_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch            (slices_0_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid                       (slices_0_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel                (slices_0_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss                (slices_0_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch            (slices_0_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid                      (slices_0_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel               (slices_0_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss               (slices_0_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch           (slices_0_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid                      (slices_0_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel               (slices_0_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss               (slices_0_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch           (slices_0_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid                      (slices_0_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel               (slices_0_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss               (slices_0_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch           (slices_0_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid                      (slices_0_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel               (slices_0_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss               (slices_0_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch           (slices_0_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid                      (slices_0_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel               (slices_0_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss               (slices_0_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch           (slices_0_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid                      (slices_0_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel               (slices_0_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss               (slices_0_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch           (slices_0_io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready                      (txreq_arb_io_in_0_ready),
    .io_out_tx_req_valid                      (slices_0_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos                   (slices_0_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID                 (slices_0_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID             (slices_0_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid         (slices_0_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID           (slices_0_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode                (slices_0_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr                  (slices_0_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns                    (slices_0_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared          (slices_0_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry            (slices_0_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order                 (slices_0_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType              (slices_0_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate      (slices_0_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable     (slices_0_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device        (slices_0_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa           (slices_0_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr               (slices_0_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding       (slices_0_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe               (slices_0_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck            (slices_0_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp                 (slices_0_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag              (slices_0_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup     (slices_0_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID           (slices_0_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS           (slices_0_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc                 (slices_0_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready                      (txrsp_arb_io_in_0_ready),
    .io_out_tx_rsp_valid                      (slices_0_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos                   (slices_0_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID                 (slices_0_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID                 (slices_0_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode                (slices_0_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr               (slices_0_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp                  (slices_0_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState              (slices_0_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy                 (slices_0_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID                  (slices_0_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType              (slices_0_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp                 (slices_0_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag              (slices_0_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready                      (txdat_arb_io_in_0_ready),
    .io_out_tx_dat_valid                      (slices_0_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID                 (slices_0_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID                 (slices_0_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID               (slices_0_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode                (slices_0_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr               (slices_0_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp                  (slices_0_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource            (slices_0_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID                  (slices_0_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID                  (slices_0_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID                (slices_0_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag              (slices_0_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be                    (slices_0_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data                  (slices_0_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck             (slices_0_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison                (slices_0_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid                      (slice_rxRspValid[0]),
    .io_out_rx_rsp_bits_srcID                 (rxrspPipe_pipeline_io_out_bits_srcID),
    .io_out_rx_rsp_bits_txnID                 (rxRsp_innerTxnID),
    .io_out_rx_rsp_bits_opcode                (rxrspPipe_pipeline_io_out_bits_opcode),
    .io_out_rx_rsp_bits_respErr               (rxrspPipe_pipeline_io_out_bits_respErr),
    .io_out_rx_rsp_bits_resp                  (rxrspPipe_pipeline_io_out_bits_resp),
    .io_out_rx_rsp_bits_dbID                  (rxrspPipe_pipeline_io_out_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType              (rxrspPipe_pipeline_io_out_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag              (rxrspPipe_pipeline_io_out_bits_traceTag),
    .io_out_rx_dat_valid                      (slice_rxDatValid[0]),
    .io_out_rx_dat_bits_txnID                 (rxDat_innerTxnID),
    .io_out_rx_dat_bits_homeNID               (rxdatPipe_pipeline_io_out_bits_homeNID),
    .io_out_rx_dat_bits_opcode                (rxdatPipe_pipeline_io_out_bits_opcode),
    .io_out_rx_dat_bits_respErr               (rxdatPipe_pipeline_io_out_bits_respErr),
    .io_out_rx_dat_bits_resp                  (rxdatPipe_pipeline_io_out_bits_resp),
    .io_out_rx_dat_bits_dbID                  (rxdatPipe_pipeline_io_out_bits_dbID),
    .io_out_rx_dat_bits_dataID                (rxdatPipe_pipeline_io_out_bits_dataID),
    .io_out_rx_dat_bits_traceTag              (rxdatPipe_pipeline_io_out_bits_traceTag),
    .io_out_rx_dat_bits_data                  (rxdatPipe_pipeline_io_out_bits_data),
    .io_out_rx_dat_bits_dataCheck             (rxdatPipe_pipeline_io_out_bits_dataCheck),
    .io_out_rx_dat_bits_poison                (rxdatPipe_pipeline_io_out_bits_poison),
    .io_out_rx_snp_ready                      (slices_0_io_out_rx_snp_ready),
    .io_out_rx_snp_valid                      (slice_rxSnpValid[0]),
    .io_out_rx_snp_bits_qos                   (linkMonitor_io_in_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID                 (linkMonitor_io_in_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID                 (linkMonitor_io_in_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID                (linkMonitor_io_in_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID              (linkMonitor_io_in_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode                (linkMonitor_io_in_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr                  (linkMonitor_io_in_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns                    (linkMonitor_io_in_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD           (linkMonitor_io_in_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc              (linkMonitor_io_in_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag              (linkMonitor_io_in_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup     (linkMonitor_io_in_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID           (linkMonitor_io_in_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS           (linkMonitor_io_in_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid                    (slices_0_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType            (slices_0_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID               (slices_0_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant                          (pcrdgrant_arb_io_in_16_ready),
    .io_pCrd_1_query_valid                    (slices_0_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType            (slices_0_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID               (slices_0_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant                          (pcrdgrant_arb_io_in_17_ready),
    .io_pCrd_2_query_valid                    (slices_0_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType            (slices_0_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID               (slices_0_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant                          (pcrdgrant_arb_io_in_18_ready),
    .io_pCrd_3_query_valid                    (slices_0_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType            (slices_0_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID               (slices_0_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant                          (pcrdgrant_arb_io_in_19_ready),
    .io_pCrd_4_query_valid                    (slices_0_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType            (slices_0_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID               (slices_0_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant                          (pcrdgrant_arb_io_in_20_ready),
    .io_pCrd_5_query_valid                    (slices_0_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType            (slices_0_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID               (slices_0_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant                          (pcrdgrant_arb_io_in_21_ready),
    .io_pCrd_6_query_valid                    (slices_0_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType            (slices_0_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID               (slices_0_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant                          (pcrdgrant_arb_io_in_22_ready),
    .io_pCrd_7_query_valid                    (slices_0_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType            (slices_0_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID               (slices_0_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant                          (pcrdgrant_arb_io_in_23_ready),
    .io_pCrd_8_query_valid                    (slices_0_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType            (slices_0_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID               (slices_0_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant                          (pcrdgrant_arb_io_in_24_ready),
    .io_pCrd_9_query_valid                    (slices_0_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType            (slices_0_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID               (slices_0_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant                          (pcrdgrant_arb_io_in_25_ready),
    .io_pCrd_10_query_valid                   (slices_0_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType           (slices_0_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID              (slices_0_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant                         (pcrdgrant_arb_io_in_26_ready),
    .io_pCrd_11_query_valid                   (slices_0_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType           (slices_0_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID              (slices_0_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant                         (pcrdgrant_arb_io_in_27_ready),
    .io_pCrd_12_query_valid                   (slices_0_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType           (slices_0_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID              (slices_0_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant                         (pcrdgrant_arb_io_in_28_ready),
    .io_pCrd_13_query_valid                   (slices_0_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType           (slices_0_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID              (slices_0_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant                         (pcrdgrant_arb_io_in_29_ready),
    .io_pCrd_14_query_valid                   (slices_0_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType           (slices_0_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID              (slices_0_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant                         (pcrdgrant_arb_io_in_30_ready),
    .io_pCrd_15_query_valid                   (slices_0_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType           (slices_0_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID              (slices_0_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant                         (pcrdgrant_arb_io_in_31_ready),
    .io_perf_0_value                          (slices_0_io_perf_0_value),
    .io_perf_1_value                          (slices_0_io_perf_1_value),
    .io_perf_3_value                          (slices_0_io_perf_3_value),
    .io_perf_4_value                          (slices_0_io_perf_4_value),
    .io_perf_5_value                          (slices_0_io_perf_5_value),
    .io_perf_6_value                          (slices_0_io_perf_6_value),
    .io_perf_7_value                          (slices_0_io_perf_7_value),
    .io_perf_8_value                          (slices_0_io_perf_8_value),
    .io_perf_9_value                          (slices_0_io_perf_9_value),
    .io_perf_10_value                         (slices_0_io_perf_10_value),
    .io_perf_11_value                         (slices_0_io_perf_11_value),
    .io_perf_12_value                         (slices_0_io_perf_12_value),
    .io_perf_13_value                         (slices_0_io_perf_13_value),
    .io_perf_14_value                         (slices_0_io_perf_14_value),
    .io_perf_15_value                         (slices_0_io_perf_15_value),
    .io_perf_16_value                         (slices_0_io_perf_16_value),
    .sigFromSrams_bore_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_1_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_2_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_2_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_3_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_3_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_4_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_4_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_5_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_5_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_6_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_6_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_7_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_7_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_8_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_8_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_9_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_9_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_10_ram_hold            (io_dft_ram_hold),
    .sigFromSrams_bore_10_ram_bypass          (io_dft_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken        (io_dft_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk         (io_dft_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp        (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold        (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                (io_dft_cgen),
    .boreChildrenBd_bore_array                (mbistPl_toNextPipeline_1_array),
    .boreChildrenBd_bore_all                  (mbistPl_toNextPipeline_1_all),
    .boreChildrenBd_bore_req                  (mbistPl_toNextPipeline_1_req),
    .boreChildrenBd_bore_ack                  (slices_0_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen              (mbistPl_toNextPipeline_1_writeen),
    .boreChildrenBd_bore_be                   (mbistPl_toNextPipeline_1_be),
    .boreChildrenBd_bore_addr                 (mbistPl_toNextPipeline_1_addr),
    .boreChildrenBd_bore_indata               (mbistPl_toNextPipeline_1_indata),
    .boreChildrenBd_bore_readen               (mbistPl_toNextPipeline_1_readen),
    .boreChildrenBd_bore_addr_rd              (mbistPl_toNextPipeline_1_addr_rd),
    .boreChildrenBd_bore_outdata              (slices_0_boreChildrenBd_bore_outdata)
  );
  Pipeline_2 train_pipeline (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_ready                              (train_pipeline_io_in_ready),
    .io_in_valid                              (slices_0_io_prefetch_train_valid),
    .io_in_bits_tag                           (slices_0_io_prefetch_train_bits_tag),
    .io_in_bits_set                           (slices_0_io_prefetch_train_bits_set),
    .io_in_bits_needT                         (slices_0_io_prefetch_train_bits_needT),
    .io_in_bits_source                        (slices_0_io_prefetch_train_bits_source),
    .io_in_bits_vaddr                         (slices_0_io_prefetch_train_bits_vaddr),
    .io_in_bits_hit                           (slices_0_io_prefetch_train_bits_hit),
    .io_in_bits_prefetched                    (slices_0_io_prefetch_train_bits_prefetched),
    .io_in_bits_pfsource                      (slices_0_io_prefetch_train_bits_pfsource),
    .io_in_bits_reqsource                     (slices_0_io_prefetch_train_bits_reqsource),
    .io_out_ready                             (prefetch_train_arb_io_in_0_ready),
    .io_out_valid                             (train_pipeline_io_out_valid),
    .io_out_bits_tag                          (train_pipeline_io_out_bits_tag),
    .io_out_bits_set                          (train_pipeline_io_out_bits_set),
    .io_out_bits_needT                        (train_pipeline_io_out_bits_needT),
    .io_out_bits_source                       (train_pipeline_io_out_bits_source),
    .io_out_bits_vaddr                        (train_pipeline_io_out_bits_vaddr),
    .io_out_bits_reqsource                    (train_pipeline_io_out_bits_reqsource)
  );
  Pipeline_3 resp_pipeline (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_ready                              (resp_pipeline_io_in_ready),
    .io_in_valid                              (slices_0_io_prefetch_resp_valid),
    .io_in_bits_tag                           (slices_0_io_prefetch_resp_bits_tag),
    .io_in_bits_set                           (slices_0_io_prefetch_resp_bits_set),
    .io_in_bits_vaddr                         (slices_0_io_prefetch_resp_bits_vaddr),
    .io_in_bits_pfSource                      (slices_0_io_prefetch_resp_bits_pfSource),
    .io_out_ready                             (prefetch_resp_arb_io_in_0_ready),
    .io_out_valid                             (resp_pipeline_io_out_valid),
    .io_out_bits_pfSource                     (resp_pipeline_io_out_bits_pfSource)
  );
  Slice_1 slices_1 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_a_ready                            (auto_in_1_a_ready),
    .io_in_a_valid                            (auto_in_1_a_valid),
    .io_in_a_bits_opcode                      (auto_in_1_a_bits_opcode),
    .io_in_a_bits_param                       (auto_in_1_a_bits_param),
    .io_in_a_bits_size                        (auto_in_1_a_bits_size),
    .io_in_a_bits_source                      (auto_in_1_a_bits_source),
    .io_in_a_bits_address                     (auto_in_1_a_bits_address),
    .io_in_a_bits_user_reqSource              (auto_in_1_a_bits_user_reqSource),
    .io_in_a_bits_user_alias                  (auto_in_1_a_bits_user_alias),
    .io_in_a_bits_user_vaddr                  (auto_in_1_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint               (auto_in_1_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword              (auto_in_1_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt                     (auto_in_1_a_bits_corrupt),
    .io_in_b_ready                            (auto_in_1_b_ready),
    .io_in_b_valid                            (auto_in_1_b_valid),
    .io_in_b_bits_opcode                      (auto_in_1_b_bits_opcode),
    .io_in_b_bits_param                       (auto_in_1_b_bits_param),
    .io_in_b_bits_address                     (slices_1_io_in_b_bits_address),
    .io_in_b_bits_data                        (auto_in_1_b_bits_data),
    .io_in_c_ready                            (auto_in_1_c_ready),
    .io_in_c_valid                            (auto_in_1_c_valid),
    .io_in_c_bits_opcode                      (auto_in_1_c_bits_opcode),
    .io_in_c_bits_param                       (auto_in_1_c_bits_param),
    .io_in_c_bits_size                        (auto_in_1_c_bits_size),
    .io_in_c_bits_source                      (auto_in_1_c_bits_source),
    .io_in_c_bits_address                     (auto_in_1_c_bits_address),
    .io_in_c_bits_data                        (auto_in_1_c_bits_data),
    .io_in_c_bits_corrupt                     (auto_in_1_c_bits_corrupt),
    .io_in_d_ready                            (slice_dReady[1]),
    .io_in_d_valid                            (slices_1_io_in_d_valid),
    .io_in_d_bits_opcode                      (slices_1_io_in_d_bits_opcode),
    .io_in_d_bits_param                       (auto_in_1_d_bits_param),
    .io_in_d_bits_source                      (slices_1_io_in_d_bits_source),
    .io_in_d_bits_sink                        (auto_in_1_d_bits_sink),
    .io_in_d_bits_denied                      (auto_in_1_d_bits_denied),
    .io_in_d_bits_echo_isKeyword              (auto_in_1_d_bits_echo_isKeyword),
    .io_in_d_bits_data                        (auto_in_1_d_bits_data),
    .io_in_d_bits_corrupt                     (auto_in_1_d_bits_corrupt),
    .io_in_e_valid                            (auto_in_1_e_valid),
    .io_in_e_bits_sink                        (auto_in_1_e_bits_sink),
    .io_l1Hint_ready                          (l1HintArb_io_in_1_ready),
    .io_l1Hint_valid                          (slices_1_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId                  (slices_1_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword                 (slices_1_io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready                  (train_pipeline_1_io_in_ready),
    .io_prefetch_train_valid                  (slices_1_io_prefetch_train_valid),
    .io_prefetch_train_bits_tag               (slices_1_io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set               (slices_1_io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT             (slices_1_io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source            (slices_1_io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr             (slices_1_io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit               (slices_1_io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched        (slices_1_io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource          (slices_1_io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource         (slices_1_io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready                    (slices_1_io_prefetch_req_ready),
    .io_prefetch_req_valid                    (slice_pfReqValid[1]),
    .io_prefetch_req_bits_tag                 (prefetcher_io_req_bits_tag),
    .io_prefetch_req_bits_set                 (prefetcher_io_req_bits_set),
    .io_prefetch_req_bits_vaddr               (prefetcher_io_req_bits_vaddr),
    .io_prefetch_req_bits_needT               (prefetcher_io_req_bits_needT),
    .io_prefetch_req_bits_source              (prefetcher_io_req_bits_source),
    .io_prefetch_req_bits_pfSource            (prefetcher_io_req_bits_pfSource),
    .io_prefetch_resp_ready                   (resp_pipeline_1_io_in_ready),
    .io_prefetch_resp_valid                   (slices_1_io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag                (slices_1_io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set                (slices_1_io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr              (slices_1_io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource           (slices_1_io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid                       (slices_1_io_dirResult_valid),
    .io_dirResult_bits_hit                    (slices_1_io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch          (slices_1_io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc       (slices_1_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_bits_replacerInfo_channel   (slices_1_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_bits_replacerInfo_reqSource (slices_1_io_dirResult_bits_replacerInfo_reqSource),
    .io_hitPfInMSHR_valid                     (slices_1_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits                      (slices_1_io_hitPfInMSHR_bits),
    .io_pfSent_valid                          (slices_1_io_pfSent_valid),
    .io_pfSent_bits                           (slices_1_io_pfSent_bits),
    .io_pfLateInMSHR_valid                    (slices_1_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits                     (slices_1_io_pfLateInMSHR_bits),
    .io_error_valid                           (slices_1_io_error_valid),
    .io_error_bits_valid                      (slices_1_io_error_bits_valid),
    .io_error_bits_address                    (slices_1_io_error_bits_address),
    .io_l2Miss                                (slices_1_io_l2Miss),
    .io_msStatus_0_valid                      (slices_1_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel               (slices_1_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set                   (slices_1_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag                (slices_1_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss               (slices_1_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch           (slices_1_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid                      (slices_1_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel               (slices_1_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set                   (slices_1_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag                (slices_1_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss               (slices_1_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch           (slices_1_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid                      (slices_1_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel               (slices_1_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set                   (slices_1_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag                (slices_1_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss               (slices_1_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch           (slices_1_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid                      (slices_1_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel               (slices_1_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set                   (slices_1_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag                (slices_1_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss               (slices_1_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch           (slices_1_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid                      (slices_1_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel               (slices_1_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set                   (slices_1_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag                (slices_1_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss               (slices_1_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch           (slices_1_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid                      (slices_1_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel               (slices_1_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set                   (slices_1_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag                (slices_1_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss               (slices_1_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch           (slices_1_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid                      (slices_1_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel               (slices_1_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set                   (slices_1_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag                (slices_1_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss               (slices_1_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch           (slices_1_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid                      (slices_1_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel               (slices_1_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set                   (slices_1_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag                (slices_1_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss               (slices_1_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch           (slices_1_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid                      (slices_1_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel               (slices_1_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set                   (slices_1_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag                (slices_1_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss               (slices_1_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch           (slices_1_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid                      (slices_1_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel               (slices_1_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set                   (slices_1_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag                (slices_1_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss               (slices_1_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch           (slices_1_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid                     (slices_1_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel              (slices_1_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set                  (slices_1_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag               (slices_1_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss              (slices_1_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch          (slices_1_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid                     (slices_1_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel              (slices_1_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set                  (slices_1_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag               (slices_1_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss              (slices_1_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch          (slices_1_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid                     (slices_1_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel              (slices_1_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set                  (slices_1_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag               (slices_1_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss              (slices_1_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch          (slices_1_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid                     (slices_1_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel              (slices_1_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set                  (slices_1_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag               (slices_1_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss              (slices_1_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch          (slices_1_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid                     (slices_1_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel              (slices_1_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set                  (slices_1_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag               (slices_1_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss              (slices_1_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch          (slices_1_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid                     (slices_1_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel              (slices_1_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set                  (slices_1_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag               (slices_1_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss              (slices_1_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch          (slices_1_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid                       (slices_1_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel                (slices_1_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss                (slices_1_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch            (slices_1_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid                       (slices_1_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel                (slices_1_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss                (slices_1_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch            (slices_1_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid                       (slices_1_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel                (slices_1_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss                (slices_1_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch            (slices_1_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid                       (slices_1_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel                (slices_1_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss                (slices_1_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch            (slices_1_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid                       (slices_1_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel                (slices_1_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss                (slices_1_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch            (slices_1_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid                       (slices_1_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel                (slices_1_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss                (slices_1_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch            (slices_1_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid                       (slices_1_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel                (slices_1_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss                (slices_1_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch            (slices_1_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid                       (slices_1_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel                (slices_1_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss                (slices_1_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch            (slices_1_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid                       (slices_1_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel                (slices_1_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss                (slices_1_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch            (slices_1_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid                       (slices_1_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel                (slices_1_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss                (slices_1_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch            (slices_1_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid                      (slices_1_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel               (slices_1_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss               (slices_1_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch           (slices_1_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid                      (slices_1_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel               (slices_1_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss               (slices_1_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch           (slices_1_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid                      (slices_1_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel               (slices_1_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss               (slices_1_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch           (slices_1_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid                      (slices_1_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel               (slices_1_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss               (slices_1_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch           (slices_1_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid                      (slices_1_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel               (slices_1_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss               (slices_1_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch           (slices_1_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid                      (slices_1_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel               (slices_1_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss               (slices_1_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch           (slices_1_io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready                      (txreq_arb_io_in_1_ready),
    .io_out_tx_req_valid                      (slices_1_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos                   (slices_1_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID                 (slices_1_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID             (slices_1_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid         (slices_1_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID           (slices_1_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode                (slices_1_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr                  (slices_1_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns                    (slices_1_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared          (slices_1_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry            (slices_1_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order                 (slices_1_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType              (slices_1_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate      (slices_1_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable     (slices_1_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device        (slices_1_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa           (slices_1_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr               (slices_1_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding       (slices_1_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe               (slices_1_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck            (slices_1_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp                 (slices_1_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag              (slices_1_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup     (slices_1_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID           (slices_1_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS           (slices_1_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc                 (slices_1_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready                      (txrsp_arb_io_in_1_ready),
    .io_out_tx_rsp_valid                      (slices_1_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos                   (slices_1_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID                 (slices_1_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID                 (slices_1_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode                (slices_1_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr               (slices_1_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp                  (slices_1_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState              (slices_1_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy                 (slices_1_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID                  (slices_1_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType              (slices_1_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp                 (slices_1_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag              (slices_1_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready                      (txdat_arb_io_in_1_ready),
    .io_out_tx_dat_valid                      (slices_1_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID                 (slices_1_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID                 (slices_1_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID               (slices_1_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode                (slices_1_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr               (slices_1_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp                  (slices_1_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource            (slices_1_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID                  (slices_1_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID                  (slices_1_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID                (slices_1_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag              (slices_1_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be                    (slices_1_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data                  (slices_1_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck             (slices_1_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison                (slices_1_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid                      (slice_rxRspValid[1]),
    .io_out_rx_rsp_bits_srcID                 (rxrspPipe_pipeline_io_out_bits_srcID),
    .io_out_rx_rsp_bits_txnID                 (rxRsp_innerTxnID),
    .io_out_rx_rsp_bits_opcode                (rxrspPipe_pipeline_io_out_bits_opcode),
    .io_out_rx_rsp_bits_respErr               (rxrspPipe_pipeline_io_out_bits_respErr),
    .io_out_rx_rsp_bits_resp                  (rxrspPipe_pipeline_io_out_bits_resp),
    .io_out_rx_rsp_bits_dbID                  (rxrspPipe_pipeline_io_out_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType              (rxrspPipe_pipeline_io_out_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag              (rxrspPipe_pipeline_io_out_bits_traceTag),
    .io_out_rx_dat_valid                      (slice_rxDatValid[1]),
    .io_out_rx_dat_bits_txnID                 (rxDat_innerTxnID),
    .io_out_rx_dat_bits_homeNID               (rxdatPipe_pipeline_io_out_bits_homeNID),
    .io_out_rx_dat_bits_opcode                (rxdatPipe_pipeline_io_out_bits_opcode),
    .io_out_rx_dat_bits_respErr               (rxdatPipe_pipeline_io_out_bits_respErr),
    .io_out_rx_dat_bits_resp                  (rxdatPipe_pipeline_io_out_bits_resp),
    .io_out_rx_dat_bits_dbID                  (rxdatPipe_pipeline_io_out_bits_dbID),
    .io_out_rx_dat_bits_dataID                (rxdatPipe_pipeline_io_out_bits_dataID),
    .io_out_rx_dat_bits_traceTag              (rxdatPipe_pipeline_io_out_bits_traceTag),
    .io_out_rx_dat_bits_data                  (rxdatPipe_pipeline_io_out_bits_data),
    .io_out_rx_dat_bits_dataCheck             (rxdatPipe_pipeline_io_out_bits_dataCheck),
    .io_out_rx_dat_bits_poison                (rxdatPipe_pipeline_io_out_bits_poison),
    .io_out_rx_snp_ready                      (slices_1_io_out_rx_snp_ready),
    .io_out_rx_snp_valid                      (slice_rxSnpValid[1]),
    .io_out_rx_snp_bits_qos                   (linkMonitor_io_in_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID                 (linkMonitor_io_in_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID                 (linkMonitor_io_in_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID                (linkMonitor_io_in_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID              (linkMonitor_io_in_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode                (linkMonitor_io_in_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr                  (linkMonitor_io_in_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns                    (linkMonitor_io_in_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD           (linkMonitor_io_in_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc              (linkMonitor_io_in_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag              (linkMonitor_io_in_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup     (linkMonitor_io_in_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID           (linkMonitor_io_in_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS           (linkMonitor_io_in_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid                    (slices_1_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType            (slices_1_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID               (slices_1_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant                          (pcrdgrant_arb_io_in_32_ready),
    .io_pCrd_1_query_valid                    (slices_1_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType            (slices_1_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID               (slices_1_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant                          (pcrdgrant_arb_io_in_33_ready),
    .io_pCrd_2_query_valid                    (slices_1_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType            (slices_1_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID               (slices_1_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant                          (pcrdgrant_arb_io_in_34_ready),
    .io_pCrd_3_query_valid                    (slices_1_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType            (slices_1_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID               (slices_1_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant                          (pcrdgrant_arb_io_in_35_ready),
    .io_pCrd_4_query_valid                    (slices_1_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType            (slices_1_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID               (slices_1_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant                          (pcrdgrant_arb_io_in_36_ready),
    .io_pCrd_5_query_valid                    (slices_1_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType            (slices_1_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID               (slices_1_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant                          (pcrdgrant_arb_io_in_37_ready),
    .io_pCrd_6_query_valid                    (slices_1_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType            (slices_1_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID               (slices_1_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant                          (pcrdgrant_arb_io_in_38_ready),
    .io_pCrd_7_query_valid                    (slices_1_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType            (slices_1_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID               (slices_1_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant                          (pcrdgrant_arb_io_in_39_ready),
    .io_pCrd_8_query_valid                    (slices_1_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType            (slices_1_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID               (slices_1_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant                          (pcrdgrant_arb_io_in_40_ready),
    .io_pCrd_9_query_valid                    (slices_1_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType            (slices_1_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID               (slices_1_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant                          (pcrdgrant_arb_io_in_41_ready),
    .io_pCrd_10_query_valid                   (slices_1_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType           (slices_1_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID              (slices_1_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant                         (pcrdgrant_arb_io_in_42_ready),
    .io_pCrd_11_query_valid                   (slices_1_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType           (slices_1_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID              (slices_1_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant                         (pcrdgrant_arb_io_in_43_ready),
    .io_pCrd_12_query_valid                   (slices_1_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType           (slices_1_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID              (slices_1_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant                         (pcrdgrant_arb_io_in_44_ready),
    .io_pCrd_13_query_valid                   (slices_1_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType           (slices_1_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID              (slices_1_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant                         (pcrdgrant_arb_io_in_45_ready),
    .io_pCrd_14_query_valid                   (slices_1_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType           (slices_1_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID              (slices_1_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant                         (pcrdgrant_arb_io_in_46_ready),
    .io_pCrd_15_query_valid                   (slices_1_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType           (slices_1_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID              (slices_1_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant                         (pcrdgrant_arb_io_in_47_ready),
    .io_perf_0_value                          (slices_1_io_perf_0_value),
    .io_perf_1_value                          (slices_1_io_perf_1_value),
    .io_perf_3_value                          (slices_1_io_perf_3_value),
    .io_perf_4_value                          (slices_1_io_perf_4_value),
    .io_perf_5_value                          (slices_1_io_perf_5_value),
    .io_perf_6_value                          (slices_1_io_perf_6_value),
    .io_perf_7_value                          (slices_1_io_perf_7_value),
    .io_perf_8_value                          (slices_1_io_perf_8_value),
    .io_perf_9_value                          (slices_1_io_perf_9_value),
    .io_perf_10_value                         (slices_1_io_perf_10_value),
    .io_perf_11_value                         (slices_1_io_perf_11_value),
    .io_perf_12_value                         (slices_1_io_perf_12_value),
    .io_perf_13_value                         (slices_1_io_perf_13_value),
    .io_perf_14_value                         (slices_1_io_perf_14_value),
    .io_perf_15_value                         (slices_1_io_perf_15_value),
    .io_perf_16_value                         (slices_1_io_perf_16_value),
    .sigFromSrams_bore_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_1_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_2_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_2_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_3_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_3_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_4_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_4_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_5_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_5_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_6_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_6_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_7_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_7_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_8_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_8_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_9_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_9_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_10_ram_hold            (io_dft_ram_hold),
    .sigFromSrams_bore_10_ram_bypass          (io_dft_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken        (io_dft_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk         (io_dft_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp        (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold        (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                (io_dft_cgen),
    .boreChildrenBd_bore_array                (mbistPl_toNextPipeline_2_array),
    .boreChildrenBd_bore_all                  (mbistPl_toNextPipeline_2_all),
    .boreChildrenBd_bore_req                  (mbistPl_toNextPipeline_2_req),
    .boreChildrenBd_bore_ack                  (slices_1_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen              (mbistPl_toNextPipeline_2_writeen),
    .boreChildrenBd_bore_be                   (mbistPl_toNextPipeline_2_be),
    .boreChildrenBd_bore_addr                 (mbistPl_toNextPipeline_2_addr),
    .boreChildrenBd_bore_indata               (mbistPl_toNextPipeline_2_indata),
    .boreChildrenBd_bore_readen               (mbistPl_toNextPipeline_2_readen),
    .boreChildrenBd_bore_addr_rd              (mbistPl_toNextPipeline_2_addr_rd),
    .boreChildrenBd_bore_outdata              (slices_1_boreChildrenBd_bore_outdata)
  );
  Pipeline_2 train_pipeline_1 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_ready                              (train_pipeline_1_io_in_ready),
    .io_in_valid                              (slices_1_io_prefetch_train_valid),
    .io_in_bits_tag                           (slices_1_io_prefetch_train_bits_tag),
    .io_in_bits_set                           (slices_1_io_prefetch_train_bits_set),
    .io_in_bits_needT                         (slices_1_io_prefetch_train_bits_needT),
    .io_in_bits_source                        (slices_1_io_prefetch_train_bits_source),
    .io_in_bits_vaddr                         (slices_1_io_prefetch_train_bits_vaddr),
    .io_in_bits_hit                           (slices_1_io_prefetch_train_bits_hit),
    .io_in_bits_prefetched                    (slices_1_io_prefetch_train_bits_prefetched),
    .io_in_bits_pfsource                      (slices_1_io_prefetch_train_bits_pfsource),
    .io_in_bits_reqsource                     (slices_1_io_prefetch_train_bits_reqsource),
    .io_out_ready                             (prefetch_train_arb_io_in_1_ready),
    .io_out_valid                             (train_pipeline_1_io_out_valid),
    .io_out_bits_tag                          (train_pipeline_1_io_out_bits_tag),
    .io_out_bits_set                          (train_pipeline_1_io_out_bits_set),
    .io_out_bits_needT                        (train_pipeline_1_io_out_bits_needT),
    .io_out_bits_source                       (train_pipeline_1_io_out_bits_source),
    .io_out_bits_vaddr                        (train_pipeline_1_io_out_bits_vaddr),
    .io_out_bits_reqsource                    (train_pipeline_1_io_out_bits_reqsource)
  );
  Pipeline_3 resp_pipeline_1 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_ready                              (resp_pipeline_1_io_in_ready),
    .io_in_valid                              (slices_1_io_prefetch_resp_valid),
    .io_in_bits_tag                           (slices_1_io_prefetch_resp_bits_tag),
    .io_in_bits_set                           (slices_1_io_prefetch_resp_bits_set),
    .io_in_bits_vaddr                         (slices_1_io_prefetch_resp_bits_vaddr),
    .io_in_bits_pfSource                      (slices_1_io_prefetch_resp_bits_pfSource),
    .io_out_ready                             (prefetch_resp_arb_io_in_1_ready),
    .io_out_valid                             (resp_pipeline_1_io_out_valid),
    .io_out_bits_pfSource                     (resp_pipeline_1_io_out_bits_pfSource)
  );
  Slice_2 slices_2 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_a_ready                            (auto_in_2_a_ready),
    .io_in_a_valid                            (auto_in_2_a_valid),
    .io_in_a_bits_opcode                      (auto_in_2_a_bits_opcode),
    .io_in_a_bits_param                       (auto_in_2_a_bits_param),
    .io_in_a_bits_size                        (auto_in_2_a_bits_size),
    .io_in_a_bits_source                      (auto_in_2_a_bits_source),
    .io_in_a_bits_address                     (auto_in_2_a_bits_address),
    .io_in_a_bits_user_reqSource              (auto_in_2_a_bits_user_reqSource),
    .io_in_a_bits_user_alias                  (auto_in_2_a_bits_user_alias),
    .io_in_a_bits_user_vaddr                  (auto_in_2_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint               (auto_in_2_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword              (auto_in_2_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt                     (auto_in_2_a_bits_corrupt),
    .io_in_b_ready                            (auto_in_2_b_ready),
    .io_in_b_valid                            (auto_in_2_b_valid),
    .io_in_b_bits_opcode                      (auto_in_2_b_bits_opcode),
    .io_in_b_bits_param                       (auto_in_2_b_bits_param),
    .io_in_b_bits_address                     (slices_2_io_in_b_bits_address),
    .io_in_b_bits_data                        (auto_in_2_b_bits_data),
    .io_in_c_ready                            (auto_in_2_c_ready),
    .io_in_c_valid                            (auto_in_2_c_valid),
    .io_in_c_bits_opcode                      (auto_in_2_c_bits_opcode),
    .io_in_c_bits_param                       (auto_in_2_c_bits_param),
    .io_in_c_bits_size                        (auto_in_2_c_bits_size),
    .io_in_c_bits_source                      (auto_in_2_c_bits_source),
    .io_in_c_bits_address                     (auto_in_2_c_bits_address),
    .io_in_c_bits_data                        (auto_in_2_c_bits_data),
    .io_in_c_bits_corrupt                     (auto_in_2_c_bits_corrupt),
    .io_in_d_ready                            (slice_dReady[2]),
    .io_in_d_valid                            (slices_2_io_in_d_valid),
    .io_in_d_bits_opcode                      (slices_2_io_in_d_bits_opcode),
    .io_in_d_bits_param                       (auto_in_2_d_bits_param),
    .io_in_d_bits_source                      (slices_2_io_in_d_bits_source),
    .io_in_d_bits_sink                        (auto_in_2_d_bits_sink),
    .io_in_d_bits_denied                      (auto_in_2_d_bits_denied),
    .io_in_d_bits_echo_isKeyword              (auto_in_2_d_bits_echo_isKeyword),
    .io_in_d_bits_data                        (auto_in_2_d_bits_data),
    .io_in_d_bits_corrupt                     (auto_in_2_d_bits_corrupt),
    .io_in_e_valid                            (auto_in_2_e_valid),
    .io_in_e_bits_sink                        (auto_in_2_e_bits_sink),
    .io_l1Hint_ready                          (l1HintArb_io_in_2_ready),
    .io_l1Hint_valid                          (slices_2_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId                  (slices_2_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword                 (slices_2_io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready                  (train_pipeline_2_io_in_ready),
    .io_prefetch_train_valid                  (slices_2_io_prefetch_train_valid),
    .io_prefetch_train_bits_tag               (slices_2_io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set               (slices_2_io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT             (slices_2_io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source            (slices_2_io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr             (slices_2_io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit               (slices_2_io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched        (slices_2_io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource          (slices_2_io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource         (slices_2_io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready                    (slices_2_io_prefetch_req_ready),
    .io_prefetch_req_valid                    (slice_pfReqValid[2]),
    .io_prefetch_req_bits_tag                 (prefetcher_io_req_bits_tag),
    .io_prefetch_req_bits_set                 (prefetcher_io_req_bits_set),
    .io_prefetch_req_bits_vaddr               (prefetcher_io_req_bits_vaddr),
    .io_prefetch_req_bits_needT               (prefetcher_io_req_bits_needT),
    .io_prefetch_req_bits_source              (prefetcher_io_req_bits_source),
    .io_prefetch_req_bits_pfSource            (prefetcher_io_req_bits_pfSource),
    .io_prefetch_resp_ready                   (resp_pipeline_2_io_in_ready),
    .io_prefetch_resp_valid                   (slices_2_io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag                (slices_2_io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set                (slices_2_io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr              (slices_2_io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource           (slices_2_io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid                       (slices_2_io_dirResult_valid),
    .io_dirResult_bits_hit                    (slices_2_io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch          (slices_2_io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc       (slices_2_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_bits_replacerInfo_channel   (slices_2_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_bits_replacerInfo_reqSource (slices_2_io_dirResult_bits_replacerInfo_reqSource),
    .io_hitPfInMSHR_valid                     (slices_2_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits                      (slices_2_io_hitPfInMSHR_bits),
    .io_pfSent_valid                          (slices_2_io_pfSent_valid),
    .io_pfSent_bits                           (slices_2_io_pfSent_bits),
    .io_pfLateInMSHR_valid                    (slices_2_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits                     (slices_2_io_pfLateInMSHR_bits),
    .io_error_valid                           (slices_2_io_error_valid),
    .io_error_bits_valid                      (slices_2_io_error_bits_valid),
    .io_error_bits_address                    (slices_2_io_error_bits_address),
    .io_l2Miss                                (slices_2_io_l2Miss),
    .io_msStatus_0_valid                      (slices_2_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel               (slices_2_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set                   (slices_2_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag                (slices_2_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss               (slices_2_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch           (slices_2_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid                      (slices_2_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel               (slices_2_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set                   (slices_2_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag                (slices_2_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss               (slices_2_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch           (slices_2_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid                      (slices_2_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel               (slices_2_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set                   (slices_2_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag                (slices_2_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss               (slices_2_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch           (slices_2_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid                      (slices_2_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel               (slices_2_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set                   (slices_2_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag                (slices_2_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss               (slices_2_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch           (slices_2_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid                      (slices_2_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel               (slices_2_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set                   (slices_2_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag                (slices_2_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss               (slices_2_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch           (slices_2_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid                      (slices_2_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel               (slices_2_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set                   (slices_2_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag                (slices_2_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss               (slices_2_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch           (slices_2_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid                      (slices_2_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel               (slices_2_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set                   (slices_2_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag                (slices_2_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss               (slices_2_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch           (slices_2_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid                      (slices_2_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel               (slices_2_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set                   (slices_2_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag                (slices_2_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss               (slices_2_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch           (slices_2_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid                      (slices_2_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel               (slices_2_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set                   (slices_2_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag                (slices_2_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss               (slices_2_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch           (slices_2_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid                      (slices_2_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel               (slices_2_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set                   (slices_2_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag                (slices_2_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss               (slices_2_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch           (slices_2_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid                     (slices_2_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel              (slices_2_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set                  (slices_2_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag               (slices_2_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss              (slices_2_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch          (slices_2_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid                     (slices_2_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel              (slices_2_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set                  (slices_2_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag               (slices_2_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss              (slices_2_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch          (slices_2_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid                     (slices_2_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel              (slices_2_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set                  (slices_2_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag               (slices_2_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss              (slices_2_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch          (slices_2_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid                     (slices_2_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel              (slices_2_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set                  (slices_2_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag               (slices_2_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss              (slices_2_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch          (slices_2_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid                     (slices_2_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel              (slices_2_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set                  (slices_2_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag               (slices_2_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss              (slices_2_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch          (slices_2_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid                     (slices_2_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel              (slices_2_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set                  (slices_2_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag               (slices_2_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss              (slices_2_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch          (slices_2_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid                       (slices_2_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel                (slices_2_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss                (slices_2_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch            (slices_2_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid                       (slices_2_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel                (slices_2_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss                (slices_2_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch            (slices_2_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid                       (slices_2_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel                (slices_2_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss                (slices_2_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch            (slices_2_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid                       (slices_2_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel                (slices_2_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss                (slices_2_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch            (slices_2_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid                       (slices_2_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel                (slices_2_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss                (slices_2_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch            (slices_2_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid                       (slices_2_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel                (slices_2_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss                (slices_2_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch            (slices_2_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid                       (slices_2_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel                (slices_2_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss                (slices_2_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch            (slices_2_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid                       (slices_2_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel                (slices_2_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss                (slices_2_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch            (slices_2_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid                       (slices_2_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel                (slices_2_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss                (slices_2_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch            (slices_2_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid                       (slices_2_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel                (slices_2_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss                (slices_2_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch            (slices_2_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid                      (slices_2_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel               (slices_2_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss               (slices_2_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch           (slices_2_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid                      (slices_2_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel               (slices_2_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss               (slices_2_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch           (slices_2_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid                      (slices_2_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel               (slices_2_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss               (slices_2_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch           (slices_2_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid                      (slices_2_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel               (slices_2_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss               (slices_2_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch           (slices_2_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid                      (slices_2_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel               (slices_2_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss               (slices_2_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch           (slices_2_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid                      (slices_2_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel               (slices_2_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss               (slices_2_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch           (slices_2_io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready                      (txreq_arb_io_in_2_ready),
    .io_out_tx_req_valid                      (slices_2_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos                   (slices_2_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID                 (slices_2_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID             (slices_2_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid         (slices_2_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID           (slices_2_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode                (slices_2_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr                  (slices_2_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns                    (slices_2_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared          (slices_2_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry            (slices_2_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order                 (slices_2_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType              (slices_2_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate      (slices_2_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable     (slices_2_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device        (slices_2_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa           (slices_2_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr               (slices_2_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding       (slices_2_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe               (slices_2_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck            (slices_2_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp                 (slices_2_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag              (slices_2_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup     (slices_2_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID           (slices_2_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS           (slices_2_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc                 (slices_2_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready                      (txrsp_arb_io_in_2_ready),
    .io_out_tx_rsp_valid                      (slices_2_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos                   (slices_2_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID                 (slices_2_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID                 (slices_2_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode                (slices_2_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr               (slices_2_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp                  (slices_2_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState              (slices_2_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy                 (slices_2_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID                  (slices_2_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType              (slices_2_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp                 (slices_2_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag              (slices_2_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready                      (txdat_arb_io_in_2_ready),
    .io_out_tx_dat_valid                      (slices_2_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID                 (slices_2_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID                 (slices_2_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID               (slices_2_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode                (slices_2_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr               (slices_2_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp                  (slices_2_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource            (slices_2_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID                  (slices_2_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID                  (slices_2_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID                (slices_2_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag              (slices_2_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be                    (slices_2_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data                  (slices_2_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck             (slices_2_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison                (slices_2_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid                      (slice_rxRspValid[2]),
    .io_out_rx_rsp_bits_srcID                 (rxrspPipe_pipeline_io_out_bits_srcID),
    .io_out_rx_rsp_bits_txnID                 (rxRsp_innerTxnID),
    .io_out_rx_rsp_bits_opcode                (rxrspPipe_pipeline_io_out_bits_opcode),
    .io_out_rx_rsp_bits_respErr               (rxrspPipe_pipeline_io_out_bits_respErr),
    .io_out_rx_rsp_bits_resp                  (rxrspPipe_pipeline_io_out_bits_resp),
    .io_out_rx_rsp_bits_dbID                  (rxrspPipe_pipeline_io_out_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType              (rxrspPipe_pipeline_io_out_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag              (rxrspPipe_pipeline_io_out_bits_traceTag),
    .io_out_rx_dat_valid                      (slice_rxDatValid[2]),
    .io_out_rx_dat_bits_txnID                 (rxDat_innerTxnID),
    .io_out_rx_dat_bits_homeNID               (rxdatPipe_pipeline_io_out_bits_homeNID),
    .io_out_rx_dat_bits_opcode                (rxdatPipe_pipeline_io_out_bits_opcode),
    .io_out_rx_dat_bits_respErr               (rxdatPipe_pipeline_io_out_bits_respErr),
    .io_out_rx_dat_bits_resp                  (rxdatPipe_pipeline_io_out_bits_resp),
    .io_out_rx_dat_bits_dbID                  (rxdatPipe_pipeline_io_out_bits_dbID),
    .io_out_rx_dat_bits_dataID                (rxdatPipe_pipeline_io_out_bits_dataID),
    .io_out_rx_dat_bits_traceTag              (rxdatPipe_pipeline_io_out_bits_traceTag),
    .io_out_rx_dat_bits_data                  (rxdatPipe_pipeline_io_out_bits_data),
    .io_out_rx_dat_bits_dataCheck             (rxdatPipe_pipeline_io_out_bits_dataCheck),
    .io_out_rx_dat_bits_poison                (rxdatPipe_pipeline_io_out_bits_poison),
    .io_out_rx_snp_ready                      (slices_2_io_out_rx_snp_ready),
    .io_out_rx_snp_valid                      (slice_rxSnpValid[2]),
    .io_out_rx_snp_bits_qos                   (linkMonitor_io_in_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID                 (linkMonitor_io_in_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID                 (linkMonitor_io_in_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID                (linkMonitor_io_in_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID              (linkMonitor_io_in_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode                (linkMonitor_io_in_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr                  (linkMonitor_io_in_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns                    (linkMonitor_io_in_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD           (linkMonitor_io_in_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc              (linkMonitor_io_in_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag              (linkMonitor_io_in_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup     (linkMonitor_io_in_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID           (linkMonitor_io_in_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS           (linkMonitor_io_in_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid                    (slices_2_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType            (slices_2_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID               (slices_2_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant                          (pcrdgrant_arb_io_in_48_ready),
    .io_pCrd_1_query_valid                    (slices_2_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType            (slices_2_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID               (slices_2_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant                          (pcrdgrant_arb_io_in_49_ready),
    .io_pCrd_2_query_valid                    (slices_2_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType            (slices_2_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID               (slices_2_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant                          (pcrdgrant_arb_io_in_50_ready),
    .io_pCrd_3_query_valid                    (slices_2_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType            (slices_2_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID               (slices_2_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant                          (pcrdgrant_arb_io_in_51_ready),
    .io_pCrd_4_query_valid                    (slices_2_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType            (slices_2_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID               (slices_2_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant                          (pcrdgrant_arb_io_in_52_ready),
    .io_pCrd_5_query_valid                    (slices_2_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType            (slices_2_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID               (slices_2_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant                          (pcrdgrant_arb_io_in_53_ready),
    .io_pCrd_6_query_valid                    (slices_2_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType            (slices_2_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID               (slices_2_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant                          (pcrdgrant_arb_io_in_54_ready),
    .io_pCrd_7_query_valid                    (slices_2_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType            (slices_2_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID               (slices_2_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant                          (pcrdgrant_arb_io_in_55_ready),
    .io_pCrd_8_query_valid                    (slices_2_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType            (slices_2_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID               (slices_2_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant                          (pcrdgrant_arb_io_in_56_ready),
    .io_pCrd_9_query_valid                    (slices_2_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType            (slices_2_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID               (slices_2_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant                          (pcrdgrant_arb_io_in_57_ready),
    .io_pCrd_10_query_valid                   (slices_2_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType           (slices_2_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID              (slices_2_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant                         (pcrdgrant_arb_io_in_58_ready),
    .io_pCrd_11_query_valid                   (slices_2_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType           (slices_2_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID              (slices_2_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant                         (pcrdgrant_arb_io_in_59_ready),
    .io_pCrd_12_query_valid                   (slices_2_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType           (slices_2_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID              (slices_2_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant                         (pcrdgrant_arb_io_in_60_ready),
    .io_pCrd_13_query_valid                   (slices_2_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType           (slices_2_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID              (slices_2_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant                         (pcrdgrant_arb_io_in_61_ready),
    .io_pCrd_14_query_valid                   (slices_2_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType           (slices_2_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID              (slices_2_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant                         (pcrdgrant_arb_io_in_62_ready),
    .io_pCrd_15_query_valid                   (slices_2_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType           (slices_2_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID              (slices_2_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant                         (pcrdgrant_arb_io_in_63_ready),
    .io_perf_0_value                          (slices_2_io_perf_0_value),
    .io_perf_1_value                          (slices_2_io_perf_1_value),
    .io_perf_3_value                          (slices_2_io_perf_3_value),
    .io_perf_4_value                          (slices_2_io_perf_4_value),
    .io_perf_5_value                          (slices_2_io_perf_5_value),
    .io_perf_6_value                          (slices_2_io_perf_6_value),
    .io_perf_7_value                          (slices_2_io_perf_7_value),
    .io_perf_8_value                          (slices_2_io_perf_8_value),
    .io_perf_9_value                          (slices_2_io_perf_9_value),
    .io_perf_10_value                         (slices_2_io_perf_10_value),
    .io_perf_11_value                         (slices_2_io_perf_11_value),
    .io_perf_12_value                         (slices_2_io_perf_12_value),
    .io_perf_13_value                         (slices_2_io_perf_13_value),
    .io_perf_14_value                         (slices_2_io_perf_14_value),
    .io_perf_15_value                         (slices_2_io_perf_15_value),
    .io_perf_16_value                         (slices_2_io_perf_16_value),
    .sigFromSrams_bore_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_1_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_2_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_2_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_3_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_3_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_4_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_4_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_5_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_5_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_6_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_6_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_7_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_7_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_8_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_8_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_9_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_9_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_10_ram_hold            (io_dft_ram_hold),
    .sigFromSrams_bore_10_ram_bypass          (io_dft_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken        (io_dft_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk         (io_dft_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp        (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold        (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                (io_dft_cgen),
    .boreChildrenBd_bore_array                (mbistPl_toNextPipeline_3_array),
    .boreChildrenBd_bore_all                  (mbistPl_toNextPipeline_3_all),
    .boreChildrenBd_bore_req                  (mbistPl_toNextPipeline_3_req),
    .boreChildrenBd_bore_ack                  (slices_2_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen              (mbistPl_toNextPipeline_3_writeen),
    .boreChildrenBd_bore_be                   (mbistPl_toNextPipeline_3_be),
    .boreChildrenBd_bore_addr                 (mbistPl_toNextPipeline_3_addr),
    .boreChildrenBd_bore_indata               (mbistPl_toNextPipeline_3_indata),
    .boreChildrenBd_bore_readen               (mbistPl_toNextPipeline_3_readen),
    .boreChildrenBd_bore_addr_rd              (mbistPl_toNextPipeline_3_addr_rd),
    .boreChildrenBd_bore_outdata              (slices_2_boreChildrenBd_bore_outdata)
  );
  Pipeline_2 train_pipeline_2 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_ready                              (train_pipeline_2_io_in_ready),
    .io_in_valid                              (slices_2_io_prefetch_train_valid),
    .io_in_bits_tag                           (slices_2_io_prefetch_train_bits_tag),
    .io_in_bits_set                           (slices_2_io_prefetch_train_bits_set),
    .io_in_bits_needT                         (slices_2_io_prefetch_train_bits_needT),
    .io_in_bits_source                        (slices_2_io_prefetch_train_bits_source),
    .io_in_bits_vaddr                         (slices_2_io_prefetch_train_bits_vaddr),
    .io_in_bits_hit                           (slices_2_io_prefetch_train_bits_hit),
    .io_in_bits_prefetched                    (slices_2_io_prefetch_train_bits_prefetched),
    .io_in_bits_pfsource                      (slices_2_io_prefetch_train_bits_pfsource),
    .io_in_bits_reqsource                     (slices_2_io_prefetch_train_bits_reqsource),
    .io_out_ready                             (prefetch_train_arb_io_in_2_ready),
    .io_out_valid                             (train_pipeline_2_io_out_valid),
    .io_out_bits_tag                          (train_pipeline_2_io_out_bits_tag),
    .io_out_bits_set                          (train_pipeline_2_io_out_bits_set),
    .io_out_bits_needT                        (train_pipeline_2_io_out_bits_needT),
    .io_out_bits_source                       (train_pipeline_2_io_out_bits_source),
    .io_out_bits_vaddr                        (train_pipeline_2_io_out_bits_vaddr),
    .io_out_bits_reqsource                    (train_pipeline_2_io_out_bits_reqsource)
  );
  Pipeline_3 resp_pipeline_2 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_ready                              (resp_pipeline_2_io_in_ready),
    .io_in_valid                              (slices_2_io_prefetch_resp_valid),
    .io_in_bits_tag                           (slices_2_io_prefetch_resp_bits_tag),
    .io_in_bits_set                           (slices_2_io_prefetch_resp_bits_set),
    .io_in_bits_vaddr                         (slices_2_io_prefetch_resp_bits_vaddr),
    .io_in_bits_pfSource                      (slices_2_io_prefetch_resp_bits_pfSource),
    .io_out_ready                             (prefetch_resp_arb_io_in_2_ready),
    .io_out_valid                             (resp_pipeline_2_io_out_valid),
    .io_out_bits_pfSource                     (resp_pipeline_2_io_out_bits_pfSource)
  );
  Slice_3 slices_3 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_a_ready                            (auto_in_3_a_ready),
    .io_in_a_valid                            (auto_in_3_a_valid),
    .io_in_a_bits_opcode                      (auto_in_3_a_bits_opcode),
    .io_in_a_bits_param                       (auto_in_3_a_bits_param),
    .io_in_a_bits_size                        (auto_in_3_a_bits_size),
    .io_in_a_bits_source                      (auto_in_3_a_bits_source),
    .io_in_a_bits_address                     (auto_in_3_a_bits_address),
    .io_in_a_bits_user_reqSource              (auto_in_3_a_bits_user_reqSource),
    .io_in_a_bits_user_alias                  (auto_in_3_a_bits_user_alias),
    .io_in_a_bits_user_vaddr                  (auto_in_3_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint               (auto_in_3_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword              (auto_in_3_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt                     (auto_in_3_a_bits_corrupt),
    .io_in_b_ready                            (auto_in_3_b_ready),
    .io_in_b_valid                            (auto_in_3_b_valid),
    .io_in_b_bits_opcode                      (auto_in_3_b_bits_opcode),
    .io_in_b_bits_param                       (auto_in_3_b_bits_param),
    .io_in_b_bits_address                     (slices_3_io_in_b_bits_address),
    .io_in_b_bits_data                        (auto_in_3_b_bits_data),
    .io_in_c_ready                            (auto_in_3_c_ready),
    .io_in_c_valid                            (auto_in_3_c_valid),
    .io_in_c_bits_opcode                      (auto_in_3_c_bits_opcode),
    .io_in_c_bits_param                       (auto_in_3_c_bits_param),
    .io_in_c_bits_size                        (auto_in_3_c_bits_size),
    .io_in_c_bits_source                      (auto_in_3_c_bits_source),
    .io_in_c_bits_address                     (auto_in_3_c_bits_address),
    .io_in_c_bits_data                        (auto_in_3_c_bits_data),
    .io_in_c_bits_corrupt                     (auto_in_3_c_bits_corrupt),
    .io_in_d_ready                            (slice_dReady[3]),
    .io_in_d_valid                            (slices_3_io_in_d_valid),
    .io_in_d_bits_opcode                      (slices_3_io_in_d_bits_opcode),
    .io_in_d_bits_param                       (auto_in_3_d_bits_param),
    .io_in_d_bits_source                      (slices_3_io_in_d_bits_source),
    .io_in_d_bits_sink                        (auto_in_3_d_bits_sink),
    .io_in_d_bits_denied                      (auto_in_3_d_bits_denied),
    .io_in_d_bits_echo_isKeyword              (auto_in_3_d_bits_echo_isKeyword),
    .io_in_d_bits_data                        (auto_in_3_d_bits_data),
    .io_in_d_bits_corrupt                     (auto_in_3_d_bits_corrupt),
    .io_in_e_valid                            (auto_in_3_e_valid),
    .io_in_e_bits_sink                        (auto_in_3_e_bits_sink),
    .io_l1Hint_ready                          (l1HintArb_io_in_3_ready),
    .io_l1Hint_valid                          (slices_3_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId                  (slices_3_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword                 (slices_3_io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready                  (train_pipeline_3_io_in_ready),
    .io_prefetch_train_valid                  (slices_3_io_prefetch_train_valid),
    .io_prefetch_train_bits_tag               (slices_3_io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set               (slices_3_io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT             (slices_3_io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source            (slices_3_io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr             (slices_3_io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit               (slices_3_io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched        (slices_3_io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource          (slices_3_io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource         (slices_3_io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready                    (slices_3_io_prefetch_req_ready),
    .io_prefetch_req_valid                    (slice_pfReqValid[3]),
    .io_prefetch_req_bits_tag                 (prefetcher_io_req_bits_tag),
    .io_prefetch_req_bits_set                 (prefetcher_io_req_bits_set),
    .io_prefetch_req_bits_vaddr               (prefetcher_io_req_bits_vaddr),
    .io_prefetch_req_bits_needT               (prefetcher_io_req_bits_needT),
    .io_prefetch_req_bits_source              (prefetcher_io_req_bits_source),
    .io_prefetch_req_bits_pfSource            (prefetcher_io_req_bits_pfSource),
    .io_prefetch_resp_ready                   (resp_pipeline_3_io_in_ready),
    .io_prefetch_resp_valid                   (slices_3_io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag                (slices_3_io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set                (slices_3_io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr              (slices_3_io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource           (slices_3_io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid                       (slices_3_io_dirResult_valid),
    .io_dirResult_bits_hit                    (slices_3_io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch          (slices_3_io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc       (slices_3_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_bits_replacerInfo_channel   (slices_3_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_bits_replacerInfo_reqSource (slices_3_io_dirResult_bits_replacerInfo_reqSource),
    .io_hitPfInMSHR_valid                     (slices_3_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits                      (slices_3_io_hitPfInMSHR_bits),
    .io_pfSent_valid                          (slices_3_io_pfSent_valid),
    .io_pfSent_bits                           (slices_3_io_pfSent_bits),
    .io_pfLateInMSHR_valid                    (slices_3_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits                     (slices_3_io_pfLateInMSHR_bits),
    .io_error_valid                           (slices_3_io_error_valid),
    .io_error_bits_valid                      (slices_3_io_error_bits_valid),
    .io_error_bits_address                    (slices_3_io_error_bits_address),
    .io_l2Miss                                (slices_3_io_l2Miss),
    .io_msStatus_0_valid                      (slices_3_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel               (slices_3_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set                   (slices_3_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag                (slices_3_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss               (slices_3_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch           (slices_3_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid                      (slices_3_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel               (slices_3_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set                   (slices_3_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag                (slices_3_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss               (slices_3_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch           (slices_3_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid                      (slices_3_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel               (slices_3_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set                   (slices_3_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag                (slices_3_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss               (slices_3_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch           (slices_3_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid                      (slices_3_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel               (slices_3_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set                   (slices_3_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag                (slices_3_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss               (slices_3_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch           (slices_3_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid                      (slices_3_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel               (slices_3_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set                   (slices_3_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag                (slices_3_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss               (slices_3_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch           (slices_3_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid                      (slices_3_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel               (slices_3_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set                   (slices_3_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag                (slices_3_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss               (slices_3_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch           (slices_3_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid                      (slices_3_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel               (slices_3_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set                   (slices_3_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag                (slices_3_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss               (slices_3_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch           (slices_3_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid                      (slices_3_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel               (slices_3_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set                   (slices_3_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag                (slices_3_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss               (slices_3_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch           (slices_3_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid                      (slices_3_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel               (slices_3_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set                   (slices_3_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag                (slices_3_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss               (slices_3_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch           (slices_3_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid                      (slices_3_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel               (slices_3_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set                   (slices_3_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag                (slices_3_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss               (slices_3_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch           (slices_3_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid                     (slices_3_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel              (slices_3_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set                  (slices_3_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag               (slices_3_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss              (slices_3_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch          (slices_3_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid                     (slices_3_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel              (slices_3_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set                  (slices_3_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag               (slices_3_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss              (slices_3_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch          (slices_3_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid                     (slices_3_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel              (slices_3_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set                  (slices_3_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag               (slices_3_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss              (slices_3_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch          (slices_3_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid                     (slices_3_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel              (slices_3_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set                  (slices_3_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag               (slices_3_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss              (slices_3_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch          (slices_3_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid                     (slices_3_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel              (slices_3_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set                  (slices_3_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag               (slices_3_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss              (slices_3_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch          (slices_3_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid                     (slices_3_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel              (slices_3_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set                  (slices_3_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag               (slices_3_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss              (slices_3_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch          (slices_3_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid                       (slices_3_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel                (slices_3_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss                (slices_3_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch            (slices_3_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid                       (slices_3_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel                (slices_3_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss                (slices_3_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch            (slices_3_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid                       (slices_3_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel                (slices_3_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss                (slices_3_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch            (slices_3_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid                       (slices_3_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel                (slices_3_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss                (slices_3_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch            (slices_3_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid                       (slices_3_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel                (slices_3_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss                (slices_3_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch            (slices_3_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid                       (slices_3_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel                (slices_3_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss                (slices_3_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch            (slices_3_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid                       (slices_3_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel                (slices_3_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss                (slices_3_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch            (slices_3_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid                       (slices_3_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel                (slices_3_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss                (slices_3_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch            (slices_3_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid                       (slices_3_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel                (slices_3_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss                (slices_3_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch            (slices_3_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid                       (slices_3_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel                (slices_3_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss                (slices_3_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch            (slices_3_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid                      (slices_3_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel               (slices_3_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss               (slices_3_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch           (slices_3_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid                      (slices_3_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel               (slices_3_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss               (slices_3_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch           (slices_3_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid                      (slices_3_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel               (slices_3_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss               (slices_3_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch           (slices_3_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid                      (slices_3_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel               (slices_3_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss               (slices_3_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch           (slices_3_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid                      (slices_3_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel               (slices_3_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss               (slices_3_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch           (slices_3_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid                      (slices_3_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel               (slices_3_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss               (slices_3_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch           (slices_3_io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready                      (txreq_arb_io_in_3_ready),
    .io_out_tx_req_valid                      (slices_3_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos                   (slices_3_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID                 (slices_3_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID             (slices_3_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid         (slices_3_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID           (slices_3_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode                (slices_3_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr                  (slices_3_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns                    (slices_3_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared          (slices_3_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry            (slices_3_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order                 (slices_3_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType              (slices_3_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate      (slices_3_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable     (slices_3_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device        (slices_3_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa           (slices_3_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr               (slices_3_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding       (slices_3_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe               (slices_3_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck            (slices_3_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp                 (slices_3_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag              (slices_3_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup     (slices_3_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID           (slices_3_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS           (slices_3_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc                 (slices_3_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready                      (txrsp_arb_io_in_3_ready),
    .io_out_tx_rsp_valid                      (slices_3_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos                   (slices_3_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID                 (slices_3_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID                 (slices_3_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode                (slices_3_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr               (slices_3_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp                  (slices_3_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState              (slices_3_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy                 (slices_3_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID                  (slices_3_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType              (slices_3_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp                 (slices_3_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag              (slices_3_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready                      (txdat_arb_io_in_3_ready),
    .io_out_tx_dat_valid                      (slices_3_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID                 (slices_3_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID                 (slices_3_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID               (slices_3_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode                (slices_3_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr               (slices_3_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp                  (slices_3_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource            (slices_3_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID                  (slices_3_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID                  (slices_3_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID                (slices_3_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag              (slices_3_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be                    (slices_3_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data                  (slices_3_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck             (slices_3_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison                (slices_3_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid                      (slice_rxRspValid[3]),
    .io_out_rx_rsp_bits_srcID                 (rxrspPipe_pipeline_io_out_bits_srcID),
    .io_out_rx_rsp_bits_txnID                 (rxRsp_innerTxnID),
    .io_out_rx_rsp_bits_opcode                (rxrspPipe_pipeline_io_out_bits_opcode),
    .io_out_rx_rsp_bits_respErr               (rxrspPipe_pipeline_io_out_bits_respErr),
    .io_out_rx_rsp_bits_resp                  (rxrspPipe_pipeline_io_out_bits_resp),
    .io_out_rx_rsp_bits_dbID                  (rxrspPipe_pipeline_io_out_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType              (rxrspPipe_pipeline_io_out_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag              (rxrspPipe_pipeline_io_out_bits_traceTag),
    .io_out_rx_dat_valid                      (slice_rxDatValid[3]),
    .io_out_rx_dat_bits_txnID                 (rxDat_innerTxnID),
    .io_out_rx_dat_bits_homeNID               (rxdatPipe_pipeline_io_out_bits_homeNID),
    .io_out_rx_dat_bits_opcode                (rxdatPipe_pipeline_io_out_bits_opcode),
    .io_out_rx_dat_bits_respErr               (rxdatPipe_pipeline_io_out_bits_respErr),
    .io_out_rx_dat_bits_resp                  (rxdatPipe_pipeline_io_out_bits_resp),
    .io_out_rx_dat_bits_dbID                  (rxdatPipe_pipeline_io_out_bits_dbID),
    .io_out_rx_dat_bits_dataID                (rxdatPipe_pipeline_io_out_bits_dataID),
    .io_out_rx_dat_bits_traceTag              (rxdatPipe_pipeline_io_out_bits_traceTag),
    .io_out_rx_dat_bits_data                  (rxdatPipe_pipeline_io_out_bits_data),
    .io_out_rx_dat_bits_dataCheck             (rxdatPipe_pipeline_io_out_bits_dataCheck),
    .io_out_rx_dat_bits_poison                (rxdatPipe_pipeline_io_out_bits_poison),
    .io_out_rx_snp_ready                      (slices_3_io_out_rx_snp_ready),
    .io_out_rx_snp_valid                      (slice_rxSnpValid[3]),
    .io_out_rx_snp_bits_qos                   (linkMonitor_io_in_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID                 (linkMonitor_io_in_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID                 (linkMonitor_io_in_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID                (linkMonitor_io_in_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID              (linkMonitor_io_in_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode                (linkMonitor_io_in_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr                  (linkMonitor_io_in_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns                    (linkMonitor_io_in_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD           (linkMonitor_io_in_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc              (linkMonitor_io_in_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag              (linkMonitor_io_in_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup     (linkMonitor_io_in_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID           (linkMonitor_io_in_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS           (linkMonitor_io_in_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid                    (slices_3_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType            (slices_3_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID               (slices_3_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant                          (pcrdgrant_arb_io_in_64_ready),
    .io_pCrd_1_query_valid                    (slices_3_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType            (slices_3_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID               (slices_3_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant                          (pcrdgrant_arb_io_in_65_ready),
    .io_pCrd_2_query_valid                    (slices_3_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType            (slices_3_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID               (slices_3_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant                          (pcrdgrant_arb_io_in_66_ready),
    .io_pCrd_3_query_valid                    (slices_3_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType            (slices_3_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID               (slices_3_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant                          (pcrdgrant_arb_io_in_67_ready),
    .io_pCrd_4_query_valid                    (slices_3_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType            (slices_3_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID               (slices_3_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant                          (pcrdgrant_arb_io_in_68_ready),
    .io_pCrd_5_query_valid                    (slices_3_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType            (slices_3_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID               (slices_3_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant                          (pcrdgrant_arb_io_in_69_ready),
    .io_pCrd_6_query_valid                    (slices_3_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType            (slices_3_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID               (slices_3_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant                          (pcrdgrant_arb_io_in_70_ready),
    .io_pCrd_7_query_valid                    (slices_3_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType            (slices_3_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID               (slices_3_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant                          (pcrdgrant_arb_io_in_71_ready),
    .io_pCrd_8_query_valid                    (slices_3_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType            (slices_3_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID               (slices_3_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant                          (pcrdgrant_arb_io_in_72_ready),
    .io_pCrd_9_query_valid                    (slices_3_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType            (slices_3_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID               (slices_3_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant                          (pcrdgrant_arb_io_in_73_ready),
    .io_pCrd_10_query_valid                   (slices_3_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType           (slices_3_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID              (slices_3_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant                         (pcrdgrant_arb_io_in_74_ready),
    .io_pCrd_11_query_valid                   (slices_3_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType           (slices_3_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID              (slices_3_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant                         (pcrdgrant_arb_io_in_75_ready),
    .io_pCrd_12_query_valid                   (slices_3_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType           (slices_3_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID              (slices_3_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant                         (pcrdgrant_arb_io_in_76_ready),
    .io_pCrd_13_query_valid                   (slices_3_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType           (slices_3_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID              (slices_3_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant                         (pcrdgrant_arb_io_in_77_ready),
    .io_pCrd_14_query_valid                   (slices_3_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType           (slices_3_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID              (slices_3_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant                         (pcrdgrant_arb_io_in_78_ready),
    .io_pCrd_15_query_valid                   (slices_3_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType           (slices_3_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID              (slices_3_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant                         (pcrdgrant_arb_io_in_79_ready),
    .io_perf_0_value                          (slices_3_io_perf_0_value),
    .io_perf_1_value                          (slices_3_io_perf_1_value),
    .io_perf_3_value                          (slices_3_io_perf_3_value),
    .io_perf_4_value                          (slices_3_io_perf_4_value),
    .io_perf_5_value                          (slices_3_io_perf_5_value),
    .io_perf_6_value                          (slices_3_io_perf_6_value),
    .io_perf_7_value                          (slices_3_io_perf_7_value),
    .io_perf_8_value                          (slices_3_io_perf_8_value),
    .io_perf_9_value                          (slices_3_io_perf_9_value),
    .io_perf_10_value                         (slices_3_io_perf_10_value),
    .io_perf_11_value                         (slices_3_io_perf_11_value),
    .io_perf_12_value                         (slices_3_io_perf_12_value),
    .io_perf_13_value                         (slices_3_io_perf_13_value),
    .io_perf_14_value                         (slices_3_io_perf_14_value),
    .io_perf_15_value                         (slices_3_io_perf_15_value),
    .io_perf_16_value                         (slices_3_io_perf_16_value),
    .sigFromSrams_bore_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_1_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_2_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_2_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_3_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_3_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_4_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_4_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_5_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_5_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_6_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_6_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_7_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_7_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_8_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_8_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_9_ram_hold             (io_dft_ram_hold),
    .sigFromSrams_bore_9_ram_bypass           (io_dft_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken         (io_dft_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk          (io_dft_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp         (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold         (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                 (io_dft_cgen),
    .sigFromSrams_bore_10_ram_hold            (io_dft_ram_hold),
    .sigFromSrams_bore_10_ram_bypass          (io_dft_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken        (io_dft_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk         (io_dft_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp        (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold        (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                (io_dft_cgen),
    .boreChildrenBd_bore_array                (mbistPl_toNextPipeline_4_array),
    .boreChildrenBd_bore_all                  (mbistPl_toNextPipeline_4_all),
    .boreChildrenBd_bore_req                  (mbistPl_toNextPipeline_4_req),
    .boreChildrenBd_bore_ack                  (slices_3_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen              (mbistPl_toNextPipeline_4_writeen),
    .boreChildrenBd_bore_be                   (mbistPl_toNextPipeline_4_be),
    .boreChildrenBd_bore_addr                 (mbistPl_toNextPipeline_4_addr),
    .boreChildrenBd_bore_indata               (mbistPl_toNextPipeline_4_indata),
    .boreChildrenBd_bore_readen               (mbistPl_toNextPipeline_4_readen),
    .boreChildrenBd_bore_addr_rd              (mbistPl_toNextPipeline_4_addr_rd),
    .boreChildrenBd_bore_outdata              (slices_3_boreChildrenBd_bore_outdata)
  );
  Pipeline_2 train_pipeline_3 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_ready                              (train_pipeline_3_io_in_ready),
    .io_in_valid                              (slices_3_io_prefetch_train_valid),
    .io_in_bits_tag                           (slices_3_io_prefetch_train_bits_tag),
    .io_in_bits_set                           (slices_3_io_prefetch_train_bits_set),
    .io_in_bits_needT                         (slices_3_io_prefetch_train_bits_needT),
    .io_in_bits_source                        (slices_3_io_prefetch_train_bits_source),
    .io_in_bits_vaddr                         (slices_3_io_prefetch_train_bits_vaddr),
    .io_in_bits_hit                           (slices_3_io_prefetch_train_bits_hit),
    .io_in_bits_prefetched                    (slices_3_io_prefetch_train_bits_prefetched),
    .io_in_bits_pfsource                      (slices_3_io_prefetch_train_bits_pfsource),
    .io_in_bits_reqsource                     (slices_3_io_prefetch_train_bits_reqsource),
    .io_out_ready                             (prefetch_train_arb_io_in_3_ready),
    .io_out_valid                             (train_pipeline_3_io_out_valid),
    .io_out_bits_tag                          (train_pipeline_3_io_out_bits_tag),
    .io_out_bits_set                          (train_pipeline_3_io_out_bits_set),
    .io_out_bits_needT                        (train_pipeline_3_io_out_bits_needT),
    .io_out_bits_source                       (train_pipeline_3_io_out_bits_source),
    .io_out_bits_vaddr                        (train_pipeline_3_io_out_bits_vaddr),
    .io_out_bits_reqsource                    (train_pipeline_3_io_out_bits_reqsource)
  );
  Pipeline_3 resp_pipeline_3 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_ready                              (resp_pipeline_3_io_in_ready),
    .io_in_valid                              (slices_3_io_prefetch_resp_valid),
    .io_in_bits_tag                           (slices_3_io_prefetch_resp_bits_tag),
    .io_in_bits_set                           (slices_3_io_prefetch_resp_bits_set),
    .io_in_bits_vaddr                         (slices_3_io_prefetch_resp_bits_vaddr),
    .io_in_bits_pfSource                      (slices_3_io_prefetch_resp_bits_pfSource),
    .io_out_ready                             (prefetch_resp_arb_io_in_3_ready),
    .io_out_valid                             (resp_pipeline_3_io_out_valid),
    .io_out_bits_pfSource                     (resp_pipeline_3_io_out_bits_pfSource)
  );
  Arbiter4_L2CacheErrorInfo l2ECCArb (
    .io_in_0_valid                            (slices_0_io_error_valid),
    .io_in_0_bits_valid                       (slices_0_io_error_bits_valid),
    .io_in_0_bits_address                     (eccArb_addr[0]),
    .io_in_1_valid                            (slices_1_io_error_valid),
    .io_in_1_bits_valid                       (slices_1_io_error_bits_valid),
    .io_in_1_bits_address                     (eccArb_addr[1]),
    .io_in_2_valid                            (slices_2_io_error_valid),
    .io_in_2_bits_valid                       (slices_2_io_error_bits_valid),
    .io_in_2_bits_address                     (eccArb_addr[2]),
    .io_in_3_valid                            (slices_3_io_error_valid),
    .io_in_3_bits_valid                       (slices_3_io_error_bits_valid),
    .io_in_3_bits_address                     (eccArb_addr[3]),
    .io_out_valid                             (l2ECCArb_io_out_valid),
    .io_out_bits_valid                        (l2ECCArb_io_out_bits_valid),
    .io_out_bits_address                      (io_error_address)
  );
  Arbiter4_L2ToL1Hint l1HintArb (
    .io_in_0_ready                            (l1HintArb_io_in_0_ready),
    .io_in_0_valid                            (slices_0_io_l1Hint_valid),
    .io_in_0_bits_sourceId                    (slices_0_io_l1Hint_bits_sourceId),
    .io_in_0_bits_isKeyword                   (slices_0_io_l1Hint_bits_isKeyword),
    .io_in_1_ready                            (l1HintArb_io_in_1_ready),
    .io_in_1_valid                            (slices_1_io_l1Hint_valid),
    .io_in_1_bits_sourceId                    (slices_1_io_l1Hint_bits_sourceId),
    .io_in_1_bits_isKeyword                   (slices_1_io_l1Hint_bits_isKeyword),
    .io_in_2_ready                            (l1HintArb_io_in_2_ready),
    .io_in_2_valid                            (slices_2_io_l1Hint_valid),
    .io_in_2_bits_sourceId                    (slices_2_io_l1Hint_bits_sourceId),
    .io_in_2_bits_isKeyword                   (slices_2_io_l1Hint_bits_isKeyword),
    .io_in_3_ready                            (l1HintArb_io_in_3_ready),
    .io_in_3_valid                            (slices_3_io_l1Hint_valid),
    .io_in_3_bits_sourceId                    (slices_3_io_l1Hint_bits_sourceId),
    .io_in_3_bits_isKeyword                   (slices_3_io_l1Hint_bits_isKeyword),
    .io_out_ready                             (hintArb_ready),
    .io_out_valid                             (l1HintArb_io_out_valid),
    .io_out_bits_sourceId                     (l1HintArb_io_out_bits_sourceId),
    .io_out_bits_isKeyword                    (io_l2_hint_bits_isKeyword),
    .io_chosen                                (l1HintArb_io_chosen)
  );
  TopDownMonitor topDown (
    .io_dirResult_0_valid                     (slices_0_io_dirResult_valid),
    .io_dirResult_0_bits_hit                  (slices_0_io_dirResult_bits_hit),
    .io_dirResult_0_bits_meta_prefetch        (slices_0_io_dirResult_bits_meta_prefetch),
    .io_dirResult_0_bits_meta_prefetchSrc     (slices_0_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_0_bits_replacerInfo_channel (slices_0_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_0_bits_replacerInfo_reqSource (slices_0_io_dirResult_bits_replacerInfo_reqSource),
    .io_dirResult_1_valid                     (slices_1_io_dirResult_valid),
    .io_dirResult_1_bits_hit                  (slices_1_io_dirResult_bits_hit),
    .io_dirResult_1_bits_meta_prefetch        (slices_1_io_dirResult_bits_meta_prefetch),
    .io_dirResult_1_bits_meta_prefetchSrc     (slices_1_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_1_bits_replacerInfo_channel (slices_1_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_1_bits_replacerInfo_reqSource (slices_1_io_dirResult_bits_replacerInfo_reqSource),
    .io_dirResult_2_valid                     (slices_2_io_dirResult_valid),
    .io_dirResult_2_bits_hit                  (slices_2_io_dirResult_bits_hit),
    .io_dirResult_2_bits_meta_prefetch        (slices_2_io_dirResult_bits_meta_prefetch),
    .io_dirResult_2_bits_meta_prefetchSrc     (slices_2_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_2_bits_replacerInfo_channel (slices_2_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_2_bits_replacerInfo_reqSource (slices_2_io_dirResult_bits_replacerInfo_reqSource),
    .io_dirResult_3_valid                     (slices_3_io_dirResult_valid),
    .io_dirResult_3_bits_hit                  (slices_3_io_dirResult_bits_hit),
    .io_dirResult_3_bits_meta_prefetch        (slices_3_io_dirResult_bits_meta_prefetch),
    .io_dirResult_3_bits_meta_prefetchSrc     (slices_3_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_3_bits_replacerInfo_channel (slices_3_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_3_bits_replacerInfo_reqSource (slices_3_io_dirResult_bits_replacerInfo_reqSource),
    .io_msStatus_0_0_valid                    (slices_0_io_msStatus_0_valid),
    .io_msStatus_0_0_bits_channel             (slices_0_io_msStatus_0_bits_channel),
    .io_msStatus_0_0_bits_set                 (slices_0_io_msStatus_0_bits_set),
    .io_msStatus_0_0_bits_reqTag              (slices_0_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_0_bits_is_miss             (slices_0_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_0_bits_is_prefetch         (slices_0_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_0_1_valid                    (slices_0_io_msStatus_1_valid),
    .io_msStatus_0_1_bits_channel             (slices_0_io_msStatus_1_bits_channel),
    .io_msStatus_0_1_bits_set                 (slices_0_io_msStatus_1_bits_set),
    .io_msStatus_0_1_bits_reqTag              (slices_0_io_msStatus_1_bits_reqTag),
    .io_msStatus_0_1_bits_is_miss             (slices_0_io_msStatus_1_bits_is_miss),
    .io_msStatus_0_1_bits_is_prefetch         (slices_0_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_0_2_valid                    (slices_0_io_msStatus_2_valid),
    .io_msStatus_0_2_bits_channel             (slices_0_io_msStatus_2_bits_channel),
    .io_msStatus_0_2_bits_set                 (slices_0_io_msStatus_2_bits_set),
    .io_msStatus_0_2_bits_reqTag              (slices_0_io_msStatus_2_bits_reqTag),
    .io_msStatus_0_2_bits_is_miss             (slices_0_io_msStatus_2_bits_is_miss),
    .io_msStatus_0_2_bits_is_prefetch         (slices_0_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_0_3_valid                    (slices_0_io_msStatus_3_valid),
    .io_msStatus_0_3_bits_channel             (slices_0_io_msStatus_3_bits_channel),
    .io_msStatus_0_3_bits_set                 (slices_0_io_msStatus_3_bits_set),
    .io_msStatus_0_3_bits_reqTag              (slices_0_io_msStatus_3_bits_reqTag),
    .io_msStatus_0_3_bits_is_miss             (slices_0_io_msStatus_3_bits_is_miss),
    .io_msStatus_0_3_bits_is_prefetch         (slices_0_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_0_4_valid                    (slices_0_io_msStatus_4_valid),
    .io_msStatus_0_4_bits_channel             (slices_0_io_msStatus_4_bits_channel),
    .io_msStatus_0_4_bits_set                 (slices_0_io_msStatus_4_bits_set),
    .io_msStatus_0_4_bits_reqTag              (slices_0_io_msStatus_4_bits_reqTag),
    .io_msStatus_0_4_bits_is_miss             (slices_0_io_msStatus_4_bits_is_miss),
    .io_msStatus_0_4_bits_is_prefetch         (slices_0_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_0_5_valid                    (slices_0_io_msStatus_5_valid),
    .io_msStatus_0_5_bits_channel             (slices_0_io_msStatus_5_bits_channel),
    .io_msStatus_0_5_bits_set                 (slices_0_io_msStatus_5_bits_set),
    .io_msStatus_0_5_bits_reqTag              (slices_0_io_msStatus_5_bits_reqTag),
    .io_msStatus_0_5_bits_is_miss             (slices_0_io_msStatus_5_bits_is_miss),
    .io_msStatus_0_5_bits_is_prefetch         (slices_0_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_0_6_valid                    (slices_0_io_msStatus_6_valid),
    .io_msStatus_0_6_bits_channel             (slices_0_io_msStatus_6_bits_channel),
    .io_msStatus_0_6_bits_set                 (slices_0_io_msStatus_6_bits_set),
    .io_msStatus_0_6_bits_reqTag              (slices_0_io_msStatus_6_bits_reqTag),
    .io_msStatus_0_6_bits_is_miss             (slices_0_io_msStatus_6_bits_is_miss),
    .io_msStatus_0_6_bits_is_prefetch         (slices_0_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_0_7_valid                    (slices_0_io_msStatus_7_valid),
    .io_msStatus_0_7_bits_channel             (slices_0_io_msStatus_7_bits_channel),
    .io_msStatus_0_7_bits_set                 (slices_0_io_msStatus_7_bits_set),
    .io_msStatus_0_7_bits_reqTag              (slices_0_io_msStatus_7_bits_reqTag),
    .io_msStatus_0_7_bits_is_miss             (slices_0_io_msStatus_7_bits_is_miss),
    .io_msStatus_0_7_bits_is_prefetch         (slices_0_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_0_8_valid                    (slices_0_io_msStatus_8_valid),
    .io_msStatus_0_8_bits_channel             (slices_0_io_msStatus_8_bits_channel),
    .io_msStatus_0_8_bits_set                 (slices_0_io_msStatus_8_bits_set),
    .io_msStatus_0_8_bits_reqTag              (slices_0_io_msStatus_8_bits_reqTag),
    .io_msStatus_0_8_bits_is_miss             (slices_0_io_msStatus_8_bits_is_miss),
    .io_msStatus_0_8_bits_is_prefetch         (slices_0_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_0_9_valid                    (slices_0_io_msStatus_9_valid),
    .io_msStatus_0_9_bits_channel             (slices_0_io_msStatus_9_bits_channel),
    .io_msStatus_0_9_bits_set                 (slices_0_io_msStatus_9_bits_set),
    .io_msStatus_0_9_bits_reqTag              (slices_0_io_msStatus_9_bits_reqTag),
    .io_msStatus_0_9_bits_is_miss             (slices_0_io_msStatus_9_bits_is_miss),
    .io_msStatus_0_9_bits_is_prefetch         (slices_0_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_0_10_valid                   (slices_0_io_msStatus_10_valid),
    .io_msStatus_0_10_bits_channel            (slices_0_io_msStatus_10_bits_channel),
    .io_msStatus_0_10_bits_set                (slices_0_io_msStatus_10_bits_set),
    .io_msStatus_0_10_bits_reqTag             (slices_0_io_msStatus_10_bits_reqTag),
    .io_msStatus_0_10_bits_is_miss            (slices_0_io_msStatus_10_bits_is_miss),
    .io_msStatus_0_10_bits_is_prefetch        (slices_0_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_0_11_valid                   (slices_0_io_msStatus_11_valid),
    .io_msStatus_0_11_bits_channel            (slices_0_io_msStatus_11_bits_channel),
    .io_msStatus_0_11_bits_set                (slices_0_io_msStatus_11_bits_set),
    .io_msStatus_0_11_bits_reqTag             (slices_0_io_msStatus_11_bits_reqTag),
    .io_msStatus_0_11_bits_is_miss            (slices_0_io_msStatus_11_bits_is_miss),
    .io_msStatus_0_11_bits_is_prefetch        (slices_0_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_0_12_valid                   (slices_0_io_msStatus_12_valid),
    .io_msStatus_0_12_bits_channel            (slices_0_io_msStatus_12_bits_channel),
    .io_msStatus_0_12_bits_set                (slices_0_io_msStatus_12_bits_set),
    .io_msStatus_0_12_bits_reqTag             (slices_0_io_msStatus_12_bits_reqTag),
    .io_msStatus_0_12_bits_is_miss            (slices_0_io_msStatus_12_bits_is_miss),
    .io_msStatus_0_12_bits_is_prefetch        (slices_0_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_0_13_valid                   (slices_0_io_msStatus_13_valid),
    .io_msStatus_0_13_bits_channel            (slices_0_io_msStatus_13_bits_channel),
    .io_msStatus_0_13_bits_set                (slices_0_io_msStatus_13_bits_set),
    .io_msStatus_0_13_bits_reqTag             (slices_0_io_msStatus_13_bits_reqTag),
    .io_msStatus_0_13_bits_is_miss            (slices_0_io_msStatus_13_bits_is_miss),
    .io_msStatus_0_13_bits_is_prefetch        (slices_0_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_0_14_valid                   (slices_0_io_msStatus_14_valid),
    .io_msStatus_0_14_bits_channel            (slices_0_io_msStatus_14_bits_channel),
    .io_msStatus_0_14_bits_set                (slices_0_io_msStatus_14_bits_set),
    .io_msStatus_0_14_bits_reqTag             (slices_0_io_msStatus_14_bits_reqTag),
    .io_msStatus_0_14_bits_is_miss            (slices_0_io_msStatus_14_bits_is_miss),
    .io_msStatus_0_14_bits_is_prefetch        (slices_0_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_0_15_valid                   (slices_0_io_msStatus_15_valid),
    .io_msStatus_0_15_bits_channel            (slices_0_io_msStatus_15_bits_channel),
    .io_msStatus_0_15_bits_set                (slices_0_io_msStatus_15_bits_set),
    .io_msStatus_0_15_bits_reqTag             (slices_0_io_msStatus_15_bits_reqTag),
    .io_msStatus_0_15_bits_is_miss            (slices_0_io_msStatus_15_bits_is_miss),
    .io_msStatus_0_15_bits_is_prefetch        (slices_0_io_msStatus_15_bits_is_prefetch),
    .io_msStatus_1_0_valid                    (slices_1_io_msStatus_0_valid),
    .io_msStatus_1_0_bits_channel             (slices_1_io_msStatus_0_bits_channel),
    .io_msStatus_1_0_bits_set                 (slices_1_io_msStatus_0_bits_set),
    .io_msStatus_1_0_bits_reqTag              (slices_1_io_msStatus_0_bits_reqTag),
    .io_msStatus_1_0_bits_is_miss             (slices_1_io_msStatus_0_bits_is_miss),
    .io_msStatus_1_0_bits_is_prefetch         (slices_1_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_1_valid                    (slices_1_io_msStatus_1_valid),
    .io_msStatus_1_1_bits_channel             (slices_1_io_msStatus_1_bits_channel),
    .io_msStatus_1_1_bits_set                 (slices_1_io_msStatus_1_bits_set),
    .io_msStatus_1_1_bits_reqTag              (slices_1_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_1_bits_is_miss             (slices_1_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_1_bits_is_prefetch         (slices_1_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_1_2_valid                    (slices_1_io_msStatus_2_valid),
    .io_msStatus_1_2_bits_channel             (slices_1_io_msStatus_2_bits_channel),
    .io_msStatus_1_2_bits_set                 (slices_1_io_msStatus_2_bits_set),
    .io_msStatus_1_2_bits_reqTag              (slices_1_io_msStatus_2_bits_reqTag),
    .io_msStatus_1_2_bits_is_miss             (slices_1_io_msStatus_2_bits_is_miss),
    .io_msStatus_1_2_bits_is_prefetch         (slices_1_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_1_3_valid                    (slices_1_io_msStatus_3_valid),
    .io_msStatus_1_3_bits_channel             (slices_1_io_msStatus_3_bits_channel),
    .io_msStatus_1_3_bits_set                 (slices_1_io_msStatus_3_bits_set),
    .io_msStatus_1_3_bits_reqTag              (slices_1_io_msStatus_3_bits_reqTag),
    .io_msStatus_1_3_bits_is_miss             (slices_1_io_msStatus_3_bits_is_miss),
    .io_msStatus_1_3_bits_is_prefetch         (slices_1_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_1_4_valid                    (slices_1_io_msStatus_4_valid),
    .io_msStatus_1_4_bits_channel             (slices_1_io_msStatus_4_bits_channel),
    .io_msStatus_1_4_bits_set                 (slices_1_io_msStatus_4_bits_set),
    .io_msStatus_1_4_bits_reqTag              (slices_1_io_msStatus_4_bits_reqTag),
    .io_msStatus_1_4_bits_is_miss             (slices_1_io_msStatus_4_bits_is_miss),
    .io_msStatus_1_4_bits_is_prefetch         (slices_1_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_1_5_valid                    (slices_1_io_msStatus_5_valid),
    .io_msStatus_1_5_bits_channel             (slices_1_io_msStatus_5_bits_channel),
    .io_msStatus_1_5_bits_set                 (slices_1_io_msStatus_5_bits_set),
    .io_msStatus_1_5_bits_reqTag              (slices_1_io_msStatus_5_bits_reqTag),
    .io_msStatus_1_5_bits_is_miss             (slices_1_io_msStatus_5_bits_is_miss),
    .io_msStatus_1_5_bits_is_prefetch         (slices_1_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_1_6_valid                    (slices_1_io_msStatus_6_valid),
    .io_msStatus_1_6_bits_channel             (slices_1_io_msStatus_6_bits_channel),
    .io_msStatus_1_6_bits_set                 (slices_1_io_msStatus_6_bits_set),
    .io_msStatus_1_6_bits_reqTag              (slices_1_io_msStatus_6_bits_reqTag),
    .io_msStatus_1_6_bits_is_miss             (slices_1_io_msStatus_6_bits_is_miss),
    .io_msStatus_1_6_bits_is_prefetch         (slices_1_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_1_7_valid                    (slices_1_io_msStatus_7_valid),
    .io_msStatus_1_7_bits_channel             (slices_1_io_msStatus_7_bits_channel),
    .io_msStatus_1_7_bits_set                 (slices_1_io_msStatus_7_bits_set),
    .io_msStatus_1_7_bits_reqTag              (slices_1_io_msStatus_7_bits_reqTag),
    .io_msStatus_1_7_bits_is_miss             (slices_1_io_msStatus_7_bits_is_miss),
    .io_msStatus_1_7_bits_is_prefetch         (slices_1_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_1_8_valid                    (slices_1_io_msStatus_8_valid),
    .io_msStatus_1_8_bits_channel             (slices_1_io_msStatus_8_bits_channel),
    .io_msStatus_1_8_bits_set                 (slices_1_io_msStatus_8_bits_set),
    .io_msStatus_1_8_bits_reqTag              (slices_1_io_msStatus_8_bits_reqTag),
    .io_msStatus_1_8_bits_is_miss             (slices_1_io_msStatus_8_bits_is_miss),
    .io_msStatus_1_8_bits_is_prefetch         (slices_1_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_1_9_valid                    (slices_1_io_msStatus_9_valid),
    .io_msStatus_1_9_bits_channel             (slices_1_io_msStatus_9_bits_channel),
    .io_msStatus_1_9_bits_set                 (slices_1_io_msStatus_9_bits_set),
    .io_msStatus_1_9_bits_reqTag              (slices_1_io_msStatus_9_bits_reqTag),
    .io_msStatus_1_9_bits_is_miss             (slices_1_io_msStatus_9_bits_is_miss),
    .io_msStatus_1_9_bits_is_prefetch         (slices_1_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_1_10_valid                   (slices_1_io_msStatus_10_valid),
    .io_msStatus_1_10_bits_channel            (slices_1_io_msStatus_10_bits_channel),
    .io_msStatus_1_10_bits_set                (slices_1_io_msStatus_10_bits_set),
    .io_msStatus_1_10_bits_reqTag             (slices_1_io_msStatus_10_bits_reqTag),
    .io_msStatus_1_10_bits_is_miss            (slices_1_io_msStatus_10_bits_is_miss),
    .io_msStatus_1_10_bits_is_prefetch        (slices_1_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_1_11_valid                   (slices_1_io_msStatus_11_valid),
    .io_msStatus_1_11_bits_channel            (slices_1_io_msStatus_11_bits_channel),
    .io_msStatus_1_11_bits_set                (slices_1_io_msStatus_11_bits_set),
    .io_msStatus_1_11_bits_reqTag             (slices_1_io_msStatus_11_bits_reqTag),
    .io_msStatus_1_11_bits_is_miss            (slices_1_io_msStatus_11_bits_is_miss),
    .io_msStatus_1_11_bits_is_prefetch        (slices_1_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_1_12_valid                   (slices_1_io_msStatus_12_valid),
    .io_msStatus_1_12_bits_channel            (slices_1_io_msStatus_12_bits_channel),
    .io_msStatus_1_12_bits_set                (slices_1_io_msStatus_12_bits_set),
    .io_msStatus_1_12_bits_reqTag             (slices_1_io_msStatus_12_bits_reqTag),
    .io_msStatus_1_12_bits_is_miss            (slices_1_io_msStatus_12_bits_is_miss),
    .io_msStatus_1_12_bits_is_prefetch        (slices_1_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_1_13_valid                   (slices_1_io_msStatus_13_valid),
    .io_msStatus_1_13_bits_channel            (slices_1_io_msStatus_13_bits_channel),
    .io_msStatus_1_13_bits_set                (slices_1_io_msStatus_13_bits_set),
    .io_msStatus_1_13_bits_reqTag             (slices_1_io_msStatus_13_bits_reqTag),
    .io_msStatus_1_13_bits_is_miss            (slices_1_io_msStatus_13_bits_is_miss),
    .io_msStatus_1_13_bits_is_prefetch        (slices_1_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_1_14_valid                   (slices_1_io_msStatus_14_valid),
    .io_msStatus_1_14_bits_channel            (slices_1_io_msStatus_14_bits_channel),
    .io_msStatus_1_14_bits_set                (slices_1_io_msStatus_14_bits_set),
    .io_msStatus_1_14_bits_reqTag             (slices_1_io_msStatus_14_bits_reqTag),
    .io_msStatus_1_14_bits_is_miss            (slices_1_io_msStatus_14_bits_is_miss),
    .io_msStatus_1_14_bits_is_prefetch        (slices_1_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_1_15_valid                   (slices_1_io_msStatus_15_valid),
    .io_msStatus_1_15_bits_channel            (slices_1_io_msStatus_15_bits_channel),
    .io_msStatus_1_15_bits_set                (slices_1_io_msStatus_15_bits_set),
    .io_msStatus_1_15_bits_reqTag             (slices_1_io_msStatus_15_bits_reqTag),
    .io_msStatus_1_15_bits_is_miss            (slices_1_io_msStatus_15_bits_is_miss),
    .io_msStatus_1_15_bits_is_prefetch        (slices_1_io_msStatus_15_bits_is_prefetch),
    .io_msStatus_2_0_valid                    (slices_2_io_msStatus_0_valid),
    .io_msStatus_2_0_bits_channel             (slices_2_io_msStatus_0_bits_channel),
    .io_msStatus_2_0_bits_set                 (slices_2_io_msStatus_0_bits_set),
    .io_msStatus_2_0_bits_reqTag              (slices_2_io_msStatus_0_bits_reqTag),
    .io_msStatus_2_0_bits_is_miss             (slices_2_io_msStatus_0_bits_is_miss),
    .io_msStatus_2_0_bits_is_prefetch         (slices_2_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_2_1_valid                    (slices_2_io_msStatus_1_valid),
    .io_msStatus_2_1_bits_channel             (slices_2_io_msStatus_1_bits_channel),
    .io_msStatus_2_1_bits_set                 (slices_2_io_msStatus_1_bits_set),
    .io_msStatus_2_1_bits_reqTag              (slices_2_io_msStatus_1_bits_reqTag),
    .io_msStatus_2_1_bits_is_miss             (slices_2_io_msStatus_1_bits_is_miss),
    .io_msStatus_2_1_bits_is_prefetch         (slices_2_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_2_valid                    (slices_2_io_msStatus_2_valid),
    .io_msStatus_2_2_bits_channel             (slices_2_io_msStatus_2_bits_channel),
    .io_msStatus_2_2_bits_set                 (slices_2_io_msStatus_2_bits_set),
    .io_msStatus_2_2_bits_reqTag              (slices_2_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_2_bits_is_miss             (slices_2_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_2_bits_is_prefetch         (slices_2_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_2_3_valid                    (slices_2_io_msStatus_3_valid),
    .io_msStatus_2_3_bits_channel             (slices_2_io_msStatus_3_bits_channel),
    .io_msStatus_2_3_bits_set                 (slices_2_io_msStatus_3_bits_set),
    .io_msStatus_2_3_bits_reqTag              (slices_2_io_msStatus_3_bits_reqTag),
    .io_msStatus_2_3_bits_is_miss             (slices_2_io_msStatus_3_bits_is_miss),
    .io_msStatus_2_3_bits_is_prefetch         (slices_2_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_2_4_valid                    (slices_2_io_msStatus_4_valid),
    .io_msStatus_2_4_bits_channel             (slices_2_io_msStatus_4_bits_channel),
    .io_msStatus_2_4_bits_set                 (slices_2_io_msStatus_4_bits_set),
    .io_msStatus_2_4_bits_reqTag              (slices_2_io_msStatus_4_bits_reqTag),
    .io_msStatus_2_4_bits_is_miss             (slices_2_io_msStatus_4_bits_is_miss),
    .io_msStatus_2_4_bits_is_prefetch         (slices_2_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_2_5_valid                    (slices_2_io_msStatus_5_valid),
    .io_msStatus_2_5_bits_channel             (slices_2_io_msStatus_5_bits_channel),
    .io_msStatus_2_5_bits_set                 (slices_2_io_msStatus_5_bits_set),
    .io_msStatus_2_5_bits_reqTag              (slices_2_io_msStatus_5_bits_reqTag),
    .io_msStatus_2_5_bits_is_miss             (slices_2_io_msStatus_5_bits_is_miss),
    .io_msStatus_2_5_bits_is_prefetch         (slices_2_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_2_6_valid                    (slices_2_io_msStatus_6_valid),
    .io_msStatus_2_6_bits_channel             (slices_2_io_msStatus_6_bits_channel),
    .io_msStatus_2_6_bits_set                 (slices_2_io_msStatus_6_bits_set),
    .io_msStatus_2_6_bits_reqTag              (slices_2_io_msStatus_6_bits_reqTag),
    .io_msStatus_2_6_bits_is_miss             (slices_2_io_msStatus_6_bits_is_miss),
    .io_msStatus_2_6_bits_is_prefetch         (slices_2_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_2_7_valid                    (slices_2_io_msStatus_7_valid),
    .io_msStatus_2_7_bits_channel             (slices_2_io_msStatus_7_bits_channel),
    .io_msStatus_2_7_bits_set                 (slices_2_io_msStatus_7_bits_set),
    .io_msStatus_2_7_bits_reqTag              (slices_2_io_msStatus_7_bits_reqTag),
    .io_msStatus_2_7_bits_is_miss             (slices_2_io_msStatus_7_bits_is_miss),
    .io_msStatus_2_7_bits_is_prefetch         (slices_2_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_2_8_valid                    (slices_2_io_msStatus_8_valid),
    .io_msStatus_2_8_bits_channel             (slices_2_io_msStatus_8_bits_channel),
    .io_msStatus_2_8_bits_set                 (slices_2_io_msStatus_8_bits_set),
    .io_msStatus_2_8_bits_reqTag              (slices_2_io_msStatus_8_bits_reqTag),
    .io_msStatus_2_8_bits_is_miss             (slices_2_io_msStatus_8_bits_is_miss),
    .io_msStatus_2_8_bits_is_prefetch         (slices_2_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_2_9_valid                    (slices_2_io_msStatus_9_valid),
    .io_msStatus_2_9_bits_channel             (slices_2_io_msStatus_9_bits_channel),
    .io_msStatus_2_9_bits_set                 (slices_2_io_msStatus_9_bits_set),
    .io_msStatus_2_9_bits_reqTag              (slices_2_io_msStatus_9_bits_reqTag),
    .io_msStatus_2_9_bits_is_miss             (slices_2_io_msStatus_9_bits_is_miss),
    .io_msStatus_2_9_bits_is_prefetch         (slices_2_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_2_10_valid                   (slices_2_io_msStatus_10_valid),
    .io_msStatus_2_10_bits_channel            (slices_2_io_msStatus_10_bits_channel),
    .io_msStatus_2_10_bits_set                (slices_2_io_msStatus_10_bits_set),
    .io_msStatus_2_10_bits_reqTag             (slices_2_io_msStatus_10_bits_reqTag),
    .io_msStatus_2_10_bits_is_miss            (slices_2_io_msStatus_10_bits_is_miss),
    .io_msStatus_2_10_bits_is_prefetch        (slices_2_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_2_11_valid                   (slices_2_io_msStatus_11_valid),
    .io_msStatus_2_11_bits_channel            (slices_2_io_msStatus_11_bits_channel),
    .io_msStatus_2_11_bits_set                (slices_2_io_msStatus_11_bits_set),
    .io_msStatus_2_11_bits_reqTag             (slices_2_io_msStatus_11_bits_reqTag),
    .io_msStatus_2_11_bits_is_miss            (slices_2_io_msStatus_11_bits_is_miss),
    .io_msStatus_2_11_bits_is_prefetch        (slices_2_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_2_12_valid                   (slices_2_io_msStatus_12_valid),
    .io_msStatus_2_12_bits_channel            (slices_2_io_msStatus_12_bits_channel),
    .io_msStatus_2_12_bits_set                (slices_2_io_msStatus_12_bits_set),
    .io_msStatus_2_12_bits_reqTag             (slices_2_io_msStatus_12_bits_reqTag),
    .io_msStatus_2_12_bits_is_miss            (slices_2_io_msStatus_12_bits_is_miss),
    .io_msStatus_2_12_bits_is_prefetch        (slices_2_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_2_13_valid                   (slices_2_io_msStatus_13_valid),
    .io_msStatus_2_13_bits_channel            (slices_2_io_msStatus_13_bits_channel),
    .io_msStatus_2_13_bits_set                (slices_2_io_msStatus_13_bits_set),
    .io_msStatus_2_13_bits_reqTag             (slices_2_io_msStatus_13_bits_reqTag),
    .io_msStatus_2_13_bits_is_miss            (slices_2_io_msStatus_13_bits_is_miss),
    .io_msStatus_2_13_bits_is_prefetch        (slices_2_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_2_14_valid                   (slices_2_io_msStatus_14_valid),
    .io_msStatus_2_14_bits_channel            (slices_2_io_msStatus_14_bits_channel),
    .io_msStatus_2_14_bits_set                (slices_2_io_msStatus_14_bits_set),
    .io_msStatus_2_14_bits_reqTag             (slices_2_io_msStatus_14_bits_reqTag),
    .io_msStatus_2_14_bits_is_miss            (slices_2_io_msStatus_14_bits_is_miss),
    .io_msStatus_2_14_bits_is_prefetch        (slices_2_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_2_15_valid                   (slices_2_io_msStatus_15_valid),
    .io_msStatus_2_15_bits_channel            (slices_2_io_msStatus_15_bits_channel),
    .io_msStatus_2_15_bits_set                (slices_2_io_msStatus_15_bits_set),
    .io_msStatus_2_15_bits_reqTag             (slices_2_io_msStatus_15_bits_reqTag),
    .io_msStatus_2_15_bits_is_miss            (slices_2_io_msStatus_15_bits_is_miss),
    .io_msStatus_2_15_bits_is_prefetch        (slices_2_io_msStatus_15_bits_is_prefetch),
    .io_msStatus_3_0_valid                    (slices_3_io_msStatus_0_valid),
    .io_msStatus_3_0_bits_channel             (slices_3_io_msStatus_0_bits_channel),
    .io_msStatus_3_0_bits_set                 (slices_3_io_msStatus_0_bits_set),
    .io_msStatus_3_0_bits_reqTag              (slices_3_io_msStatus_0_bits_reqTag),
    .io_msStatus_3_0_bits_is_miss             (slices_3_io_msStatus_0_bits_is_miss),
    .io_msStatus_3_0_bits_is_prefetch         (slices_3_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_3_1_valid                    (slices_3_io_msStatus_1_valid),
    .io_msStatus_3_1_bits_channel             (slices_3_io_msStatus_1_bits_channel),
    .io_msStatus_3_1_bits_set                 (slices_3_io_msStatus_1_bits_set),
    .io_msStatus_3_1_bits_reqTag              (slices_3_io_msStatus_1_bits_reqTag),
    .io_msStatus_3_1_bits_is_miss             (slices_3_io_msStatus_1_bits_is_miss),
    .io_msStatus_3_1_bits_is_prefetch         (slices_3_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_3_2_valid                    (slices_3_io_msStatus_2_valid),
    .io_msStatus_3_2_bits_channel             (slices_3_io_msStatus_2_bits_channel),
    .io_msStatus_3_2_bits_set                 (slices_3_io_msStatus_2_bits_set),
    .io_msStatus_3_2_bits_reqTag              (slices_3_io_msStatus_2_bits_reqTag),
    .io_msStatus_3_2_bits_is_miss             (slices_3_io_msStatus_2_bits_is_miss),
    .io_msStatus_3_2_bits_is_prefetch         (slices_3_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_3_valid                    (slices_3_io_msStatus_3_valid),
    .io_msStatus_3_3_bits_channel             (slices_3_io_msStatus_3_bits_channel),
    .io_msStatus_3_3_bits_set                 (slices_3_io_msStatus_3_bits_set),
    .io_msStatus_3_3_bits_reqTag              (slices_3_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_3_bits_is_miss             (slices_3_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_3_bits_is_prefetch         (slices_3_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_3_4_valid                    (slices_3_io_msStatus_4_valid),
    .io_msStatus_3_4_bits_channel             (slices_3_io_msStatus_4_bits_channel),
    .io_msStatus_3_4_bits_set                 (slices_3_io_msStatus_4_bits_set),
    .io_msStatus_3_4_bits_reqTag              (slices_3_io_msStatus_4_bits_reqTag),
    .io_msStatus_3_4_bits_is_miss             (slices_3_io_msStatus_4_bits_is_miss),
    .io_msStatus_3_4_bits_is_prefetch         (slices_3_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_3_5_valid                    (slices_3_io_msStatus_5_valid),
    .io_msStatus_3_5_bits_channel             (slices_3_io_msStatus_5_bits_channel),
    .io_msStatus_3_5_bits_set                 (slices_3_io_msStatus_5_bits_set),
    .io_msStatus_3_5_bits_reqTag              (slices_3_io_msStatus_5_bits_reqTag),
    .io_msStatus_3_5_bits_is_miss             (slices_3_io_msStatus_5_bits_is_miss),
    .io_msStatus_3_5_bits_is_prefetch         (slices_3_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_3_6_valid                    (slices_3_io_msStatus_6_valid),
    .io_msStatus_3_6_bits_channel             (slices_3_io_msStatus_6_bits_channel),
    .io_msStatus_3_6_bits_set                 (slices_3_io_msStatus_6_bits_set),
    .io_msStatus_3_6_bits_reqTag              (slices_3_io_msStatus_6_bits_reqTag),
    .io_msStatus_3_6_bits_is_miss             (slices_3_io_msStatus_6_bits_is_miss),
    .io_msStatus_3_6_bits_is_prefetch         (slices_3_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_3_7_valid                    (slices_3_io_msStatus_7_valid),
    .io_msStatus_3_7_bits_channel             (slices_3_io_msStatus_7_bits_channel),
    .io_msStatus_3_7_bits_set                 (slices_3_io_msStatus_7_bits_set),
    .io_msStatus_3_7_bits_reqTag              (slices_3_io_msStatus_7_bits_reqTag),
    .io_msStatus_3_7_bits_is_miss             (slices_3_io_msStatus_7_bits_is_miss),
    .io_msStatus_3_7_bits_is_prefetch         (slices_3_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_3_8_valid                    (slices_3_io_msStatus_8_valid),
    .io_msStatus_3_8_bits_channel             (slices_3_io_msStatus_8_bits_channel),
    .io_msStatus_3_8_bits_set                 (slices_3_io_msStatus_8_bits_set),
    .io_msStatus_3_8_bits_reqTag              (slices_3_io_msStatus_8_bits_reqTag),
    .io_msStatus_3_8_bits_is_miss             (slices_3_io_msStatus_8_bits_is_miss),
    .io_msStatus_3_8_bits_is_prefetch         (slices_3_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_3_9_valid                    (slices_3_io_msStatus_9_valid),
    .io_msStatus_3_9_bits_channel             (slices_3_io_msStatus_9_bits_channel),
    .io_msStatus_3_9_bits_set                 (slices_3_io_msStatus_9_bits_set),
    .io_msStatus_3_9_bits_reqTag              (slices_3_io_msStatus_9_bits_reqTag),
    .io_msStatus_3_9_bits_is_miss             (slices_3_io_msStatus_9_bits_is_miss),
    .io_msStatus_3_9_bits_is_prefetch         (slices_3_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_3_10_valid                   (slices_3_io_msStatus_10_valid),
    .io_msStatus_3_10_bits_channel            (slices_3_io_msStatus_10_bits_channel),
    .io_msStatus_3_10_bits_set                (slices_3_io_msStatus_10_bits_set),
    .io_msStatus_3_10_bits_reqTag             (slices_3_io_msStatus_10_bits_reqTag),
    .io_msStatus_3_10_bits_is_miss            (slices_3_io_msStatus_10_bits_is_miss),
    .io_msStatus_3_10_bits_is_prefetch        (slices_3_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_3_11_valid                   (slices_3_io_msStatus_11_valid),
    .io_msStatus_3_11_bits_channel            (slices_3_io_msStatus_11_bits_channel),
    .io_msStatus_3_11_bits_set                (slices_3_io_msStatus_11_bits_set),
    .io_msStatus_3_11_bits_reqTag             (slices_3_io_msStatus_11_bits_reqTag),
    .io_msStatus_3_11_bits_is_miss            (slices_3_io_msStatus_11_bits_is_miss),
    .io_msStatus_3_11_bits_is_prefetch        (slices_3_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_3_12_valid                   (slices_3_io_msStatus_12_valid),
    .io_msStatus_3_12_bits_channel            (slices_3_io_msStatus_12_bits_channel),
    .io_msStatus_3_12_bits_set                (slices_3_io_msStatus_12_bits_set),
    .io_msStatus_3_12_bits_reqTag             (slices_3_io_msStatus_12_bits_reqTag),
    .io_msStatus_3_12_bits_is_miss            (slices_3_io_msStatus_12_bits_is_miss),
    .io_msStatus_3_12_bits_is_prefetch        (slices_3_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_3_13_valid                   (slices_3_io_msStatus_13_valid),
    .io_msStatus_3_13_bits_channel            (slices_3_io_msStatus_13_bits_channel),
    .io_msStatus_3_13_bits_set                (slices_3_io_msStatus_13_bits_set),
    .io_msStatus_3_13_bits_reqTag             (slices_3_io_msStatus_13_bits_reqTag),
    .io_msStatus_3_13_bits_is_miss            (slices_3_io_msStatus_13_bits_is_miss),
    .io_msStatus_3_13_bits_is_prefetch        (slices_3_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_3_14_valid                   (slices_3_io_msStatus_14_valid),
    .io_msStatus_3_14_bits_channel            (slices_3_io_msStatus_14_bits_channel),
    .io_msStatus_3_14_bits_set                (slices_3_io_msStatus_14_bits_set),
    .io_msStatus_3_14_bits_reqTag             (slices_3_io_msStatus_14_bits_reqTag),
    .io_msStatus_3_14_bits_is_miss            (slices_3_io_msStatus_14_bits_is_miss),
    .io_msStatus_3_14_bits_is_prefetch        (slices_3_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_3_15_valid                   (slices_3_io_msStatus_15_valid),
    .io_msStatus_3_15_bits_channel            (slices_3_io_msStatus_15_bits_channel),
    .io_msStatus_3_15_bits_set                (slices_3_io_msStatus_15_bits_set),
    .io_msStatus_3_15_bits_reqTag             (slices_3_io_msStatus_15_bits_reqTag),
    .io_msStatus_3_15_bits_is_miss            (slices_3_io_msStatus_15_bits_is_miss),
    .io_msStatus_3_15_bits_is_prefetch        (slices_3_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_0_valid                     (slices_0_io_msAlloc_0_valid),
    .io_msAlloc_0_0_bits_channel              (slices_0_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_0_bits_is_miss              (slices_0_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_0_bits_is_prefetch          (slices_0_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_0_1_valid                     (slices_0_io_msAlloc_1_valid),
    .io_msAlloc_0_1_bits_channel              (slices_0_io_msAlloc_1_bits_channel),
    .io_msAlloc_0_1_bits_is_miss              (slices_0_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_0_1_bits_is_prefetch          (slices_0_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_0_2_valid                     (slices_0_io_msAlloc_2_valid),
    .io_msAlloc_0_2_bits_channel              (slices_0_io_msAlloc_2_bits_channel),
    .io_msAlloc_0_2_bits_is_miss              (slices_0_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_0_2_bits_is_prefetch          (slices_0_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_0_3_valid                     (slices_0_io_msAlloc_3_valid),
    .io_msAlloc_0_3_bits_channel              (slices_0_io_msAlloc_3_bits_channel),
    .io_msAlloc_0_3_bits_is_miss              (slices_0_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_0_3_bits_is_prefetch          (slices_0_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_0_4_valid                     (slices_0_io_msAlloc_4_valid),
    .io_msAlloc_0_4_bits_channel              (slices_0_io_msAlloc_4_bits_channel),
    .io_msAlloc_0_4_bits_is_miss              (slices_0_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_0_4_bits_is_prefetch          (slices_0_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_0_5_valid                     (slices_0_io_msAlloc_5_valid),
    .io_msAlloc_0_5_bits_channel              (slices_0_io_msAlloc_5_bits_channel),
    .io_msAlloc_0_5_bits_is_miss              (slices_0_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_0_5_bits_is_prefetch          (slices_0_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_0_6_valid                     (slices_0_io_msAlloc_6_valid),
    .io_msAlloc_0_6_bits_channel              (slices_0_io_msAlloc_6_bits_channel),
    .io_msAlloc_0_6_bits_is_miss              (slices_0_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_0_6_bits_is_prefetch          (slices_0_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_0_7_valid                     (slices_0_io_msAlloc_7_valid),
    .io_msAlloc_0_7_bits_channel              (slices_0_io_msAlloc_7_bits_channel),
    .io_msAlloc_0_7_bits_is_miss              (slices_0_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_0_7_bits_is_prefetch          (slices_0_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_0_8_valid                     (slices_0_io_msAlloc_8_valid),
    .io_msAlloc_0_8_bits_channel              (slices_0_io_msAlloc_8_bits_channel),
    .io_msAlloc_0_8_bits_is_miss              (slices_0_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_0_8_bits_is_prefetch          (slices_0_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_0_9_valid                     (slices_0_io_msAlloc_9_valid),
    .io_msAlloc_0_9_bits_channel              (slices_0_io_msAlloc_9_bits_channel),
    .io_msAlloc_0_9_bits_is_miss              (slices_0_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_0_9_bits_is_prefetch          (slices_0_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_0_10_valid                    (slices_0_io_msAlloc_10_valid),
    .io_msAlloc_0_10_bits_channel             (slices_0_io_msAlloc_10_bits_channel),
    .io_msAlloc_0_10_bits_is_miss             (slices_0_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_0_10_bits_is_prefetch         (slices_0_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_0_11_valid                    (slices_0_io_msAlloc_11_valid),
    .io_msAlloc_0_11_bits_channel             (slices_0_io_msAlloc_11_bits_channel),
    .io_msAlloc_0_11_bits_is_miss             (slices_0_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_0_11_bits_is_prefetch         (slices_0_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_0_12_valid                    (slices_0_io_msAlloc_12_valid),
    .io_msAlloc_0_12_bits_channel             (slices_0_io_msAlloc_12_bits_channel),
    .io_msAlloc_0_12_bits_is_miss             (slices_0_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_0_12_bits_is_prefetch         (slices_0_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_0_13_valid                    (slices_0_io_msAlloc_13_valid),
    .io_msAlloc_0_13_bits_channel             (slices_0_io_msAlloc_13_bits_channel),
    .io_msAlloc_0_13_bits_is_miss             (slices_0_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_0_13_bits_is_prefetch         (slices_0_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_0_14_valid                    (slices_0_io_msAlloc_14_valid),
    .io_msAlloc_0_14_bits_channel             (slices_0_io_msAlloc_14_bits_channel),
    .io_msAlloc_0_14_bits_is_miss             (slices_0_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_0_14_bits_is_prefetch         (slices_0_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_0_15_valid                    (slices_0_io_msAlloc_15_valid),
    .io_msAlloc_0_15_bits_channel             (slices_0_io_msAlloc_15_bits_channel),
    .io_msAlloc_0_15_bits_is_miss             (slices_0_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_0_15_bits_is_prefetch         (slices_0_io_msAlloc_15_bits_is_prefetch),
    .io_msAlloc_1_0_valid                     (slices_1_io_msAlloc_0_valid),
    .io_msAlloc_1_0_bits_channel              (slices_1_io_msAlloc_0_bits_channel),
    .io_msAlloc_1_0_bits_is_miss              (slices_1_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_1_0_bits_is_prefetch          (slices_1_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_1_valid                     (slices_1_io_msAlloc_1_valid),
    .io_msAlloc_1_1_bits_channel              (slices_1_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_1_bits_is_miss              (slices_1_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_1_bits_is_prefetch          (slices_1_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_1_2_valid                     (slices_1_io_msAlloc_2_valid),
    .io_msAlloc_1_2_bits_channel              (slices_1_io_msAlloc_2_bits_channel),
    .io_msAlloc_1_2_bits_is_miss              (slices_1_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_1_2_bits_is_prefetch          (slices_1_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_1_3_valid                     (slices_1_io_msAlloc_3_valid),
    .io_msAlloc_1_3_bits_channel              (slices_1_io_msAlloc_3_bits_channel),
    .io_msAlloc_1_3_bits_is_miss              (slices_1_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_1_3_bits_is_prefetch          (slices_1_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_1_4_valid                     (slices_1_io_msAlloc_4_valid),
    .io_msAlloc_1_4_bits_channel              (slices_1_io_msAlloc_4_bits_channel),
    .io_msAlloc_1_4_bits_is_miss              (slices_1_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_1_4_bits_is_prefetch          (slices_1_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_1_5_valid                     (slices_1_io_msAlloc_5_valid),
    .io_msAlloc_1_5_bits_channel              (slices_1_io_msAlloc_5_bits_channel),
    .io_msAlloc_1_5_bits_is_miss              (slices_1_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_1_5_bits_is_prefetch          (slices_1_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_1_6_valid                     (slices_1_io_msAlloc_6_valid),
    .io_msAlloc_1_6_bits_channel              (slices_1_io_msAlloc_6_bits_channel),
    .io_msAlloc_1_6_bits_is_miss              (slices_1_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_1_6_bits_is_prefetch          (slices_1_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_1_7_valid                     (slices_1_io_msAlloc_7_valid),
    .io_msAlloc_1_7_bits_channel              (slices_1_io_msAlloc_7_bits_channel),
    .io_msAlloc_1_7_bits_is_miss              (slices_1_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_1_7_bits_is_prefetch          (slices_1_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_1_8_valid                     (slices_1_io_msAlloc_8_valid),
    .io_msAlloc_1_8_bits_channel              (slices_1_io_msAlloc_8_bits_channel),
    .io_msAlloc_1_8_bits_is_miss              (slices_1_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_1_8_bits_is_prefetch          (slices_1_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_1_9_valid                     (slices_1_io_msAlloc_9_valid),
    .io_msAlloc_1_9_bits_channel              (slices_1_io_msAlloc_9_bits_channel),
    .io_msAlloc_1_9_bits_is_miss              (slices_1_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_1_9_bits_is_prefetch          (slices_1_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_1_10_valid                    (slices_1_io_msAlloc_10_valid),
    .io_msAlloc_1_10_bits_channel             (slices_1_io_msAlloc_10_bits_channel),
    .io_msAlloc_1_10_bits_is_miss             (slices_1_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_1_10_bits_is_prefetch         (slices_1_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_1_11_valid                    (slices_1_io_msAlloc_11_valid),
    .io_msAlloc_1_11_bits_channel             (slices_1_io_msAlloc_11_bits_channel),
    .io_msAlloc_1_11_bits_is_miss             (slices_1_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_1_11_bits_is_prefetch         (slices_1_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_1_12_valid                    (slices_1_io_msAlloc_12_valid),
    .io_msAlloc_1_12_bits_channel             (slices_1_io_msAlloc_12_bits_channel),
    .io_msAlloc_1_12_bits_is_miss             (slices_1_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_1_12_bits_is_prefetch         (slices_1_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_1_13_valid                    (slices_1_io_msAlloc_13_valid),
    .io_msAlloc_1_13_bits_channel             (slices_1_io_msAlloc_13_bits_channel),
    .io_msAlloc_1_13_bits_is_miss             (slices_1_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_1_13_bits_is_prefetch         (slices_1_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_1_14_valid                    (slices_1_io_msAlloc_14_valid),
    .io_msAlloc_1_14_bits_channel             (slices_1_io_msAlloc_14_bits_channel),
    .io_msAlloc_1_14_bits_is_miss             (slices_1_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_1_14_bits_is_prefetch         (slices_1_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_1_15_valid                    (slices_1_io_msAlloc_15_valid),
    .io_msAlloc_1_15_bits_channel             (slices_1_io_msAlloc_15_bits_channel),
    .io_msAlloc_1_15_bits_is_miss             (slices_1_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_1_15_bits_is_prefetch         (slices_1_io_msAlloc_15_bits_is_prefetch),
    .io_msAlloc_2_0_valid                     (slices_2_io_msAlloc_0_valid),
    .io_msAlloc_2_0_bits_channel              (slices_2_io_msAlloc_0_bits_channel),
    .io_msAlloc_2_0_bits_is_miss              (slices_2_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_2_0_bits_is_prefetch          (slices_2_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_2_1_valid                     (slices_2_io_msAlloc_1_valid),
    .io_msAlloc_2_1_bits_channel              (slices_2_io_msAlloc_1_bits_channel),
    .io_msAlloc_2_1_bits_is_miss              (slices_2_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_2_1_bits_is_prefetch          (slices_2_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_2_valid                     (slices_2_io_msAlloc_2_valid),
    .io_msAlloc_2_2_bits_channel              (slices_2_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_2_bits_is_miss              (slices_2_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_2_bits_is_prefetch          (slices_2_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_2_3_valid                     (slices_2_io_msAlloc_3_valid),
    .io_msAlloc_2_3_bits_channel              (slices_2_io_msAlloc_3_bits_channel),
    .io_msAlloc_2_3_bits_is_miss              (slices_2_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_2_3_bits_is_prefetch          (slices_2_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_2_4_valid                     (slices_2_io_msAlloc_4_valid),
    .io_msAlloc_2_4_bits_channel              (slices_2_io_msAlloc_4_bits_channel),
    .io_msAlloc_2_4_bits_is_miss              (slices_2_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_2_4_bits_is_prefetch          (slices_2_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_2_5_valid                     (slices_2_io_msAlloc_5_valid),
    .io_msAlloc_2_5_bits_channel              (slices_2_io_msAlloc_5_bits_channel),
    .io_msAlloc_2_5_bits_is_miss              (slices_2_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_2_5_bits_is_prefetch          (slices_2_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_2_6_valid                     (slices_2_io_msAlloc_6_valid),
    .io_msAlloc_2_6_bits_channel              (slices_2_io_msAlloc_6_bits_channel),
    .io_msAlloc_2_6_bits_is_miss              (slices_2_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_2_6_bits_is_prefetch          (slices_2_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_2_7_valid                     (slices_2_io_msAlloc_7_valid),
    .io_msAlloc_2_7_bits_channel              (slices_2_io_msAlloc_7_bits_channel),
    .io_msAlloc_2_7_bits_is_miss              (slices_2_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_2_7_bits_is_prefetch          (slices_2_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_2_8_valid                     (slices_2_io_msAlloc_8_valid),
    .io_msAlloc_2_8_bits_channel              (slices_2_io_msAlloc_8_bits_channel),
    .io_msAlloc_2_8_bits_is_miss              (slices_2_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_2_8_bits_is_prefetch          (slices_2_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_2_9_valid                     (slices_2_io_msAlloc_9_valid),
    .io_msAlloc_2_9_bits_channel              (slices_2_io_msAlloc_9_bits_channel),
    .io_msAlloc_2_9_bits_is_miss              (slices_2_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_2_9_bits_is_prefetch          (slices_2_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_2_10_valid                    (slices_2_io_msAlloc_10_valid),
    .io_msAlloc_2_10_bits_channel             (slices_2_io_msAlloc_10_bits_channel),
    .io_msAlloc_2_10_bits_is_miss             (slices_2_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_2_10_bits_is_prefetch         (slices_2_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_2_11_valid                    (slices_2_io_msAlloc_11_valid),
    .io_msAlloc_2_11_bits_channel             (slices_2_io_msAlloc_11_bits_channel),
    .io_msAlloc_2_11_bits_is_miss             (slices_2_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_2_11_bits_is_prefetch         (slices_2_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_2_12_valid                    (slices_2_io_msAlloc_12_valid),
    .io_msAlloc_2_12_bits_channel             (slices_2_io_msAlloc_12_bits_channel),
    .io_msAlloc_2_12_bits_is_miss             (slices_2_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_2_12_bits_is_prefetch         (slices_2_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_2_13_valid                    (slices_2_io_msAlloc_13_valid),
    .io_msAlloc_2_13_bits_channel             (slices_2_io_msAlloc_13_bits_channel),
    .io_msAlloc_2_13_bits_is_miss             (slices_2_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_2_13_bits_is_prefetch         (slices_2_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_2_14_valid                    (slices_2_io_msAlloc_14_valid),
    .io_msAlloc_2_14_bits_channel             (slices_2_io_msAlloc_14_bits_channel),
    .io_msAlloc_2_14_bits_is_miss             (slices_2_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_2_14_bits_is_prefetch         (slices_2_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_2_15_valid                    (slices_2_io_msAlloc_15_valid),
    .io_msAlloc_2_15_bits_channel             (slices_2_io_msAlloc_15_bits_channel),
    .io_msAlloc_2_15_bits_is_miss             (slices_2_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_2_15_bits_is_prefetch         (slices_2_io_msAlloc_15_bits_is_prefetch),
    .io_msAlloc_3_0_valid                     (slices_3_io_msAlloc_0_valid),
    .io_msAlloc_3_0_bits_channel              (slices_3_io_msAlloc_0_bits_channel),
    .io_msAlloc_3_0_bits_is_miss              (slices_3_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_3_0_bits_is_prefetch          (slices_3_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_3_1_valid                     (slices_3_io_msAlloc_1_valid),
    .io_msAlloc_3_1_bits_channel              (slices_3_io_msAlloc_1_bits_channel),
    .io_msAlloc_3_1_bits_is_miss              (slices_3_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_3_1_bits_is_prefetch          (slices_3_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_3_2_valid                     (slices_3_io_msAlloc_2_valid),
    .io_msAlloc_3_2_bits_channel              (slices_3_io_msAlloc_2_bits_channel),
    .io_msAlloc_3_2_bits_is_miss              (slices_3_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_3_2_bits_is_prefetch          (slices_3_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_3_valid                     (slices_3_io_msAlloc_3_valid),
    .io_msAlloc_3_3_bits_channel              (slices_3_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_3_bits_is_miss              (slices_3_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_3_bits_is_prefetch          (slices_3_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_3_4_valid                     (slices_3_io_msAlloc_4_valid),
    .io_msAlloc_3_4_bits_channel              (slices_3_io_msAlloc_4_bits_channel),
    .io_msAlloc_3_4_bits_is_miss              (slices_3_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_3_4_bits_is_prefetch          (slices_3_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_3_5_valid                     (slices_3_io_msAlloc_5_valid),
    .io_msAlloc_3_5_bits_channel              (slices_3_io_msAlloc_5_bits_channel),
    .io_msAlloc_3_5_bits_is_miss              (slices_3_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_3_5_bits_is_prefetch          (slices_3_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_3_6_valid                     (slices_3_io_msAlloc_6_valid),
    .io_msAlloc_3_6_bits_channel              (slices_3_io_msAlloc_6_bits_channel),
    .io_msAlloc_3_6_bits_is_miss              (slices_3_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_3_6_bits_is_prefetch          (slices_3_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_3_7_valid                     (slices_3_io_msAlloc_7_valid),
    .io_msAlloc_3_7_bits_channel              (slices_3_io_msAlloc_7_bits_channel),
    .io_msAlloc_3_7_bits_is_miss              (slices_3_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_3_7_bits_is_prefetch          (slices_3_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_3_8_valid                     (slices_3_io_msAlloc_8_valid),
    .io_msAlloc_3_8_bits_channel              (slices_3_io_msAlloc_8_bits_channel),
    .io_msAlloc_3_8_bits_is_miss              (slices_3_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_3_8_bits_is_prefetch          (slices_3_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_3_9_valid                     (slices_3_io_msAlloc_9_valid),
    .io_msAlloc_3_9_bits_channel              (slices_3_io_msAlloc_9_bits_channel),
    .io_msAlloc_3_9_bits_is_miss              (slices_3_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_3_9_bits_is_prefetch          (slices_3_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_3_10_valid                    (slices_3_io_msAlloc_10_valid),
    .io_msAlloc_3_10_bits_channel             (slices_3_io_msAlloc_10_bits_channel),
    .io_msAlloc_3_10_bits_is_miss             (slices_3_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_3_10_bits_is_prefetch         (slices_3_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_3_11_valid                    (slices_3_io_msAlloc_11_valid),
    .io_msAlloc_3_11_bits_channel             (slices_3_io_msAlloc_11_bits_channel),
    .io_msAlloc_3_11_bits_is_miss             (slices_3_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_3_11_bits_is_prefetch         (slices_3_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_3_12_valid                    (slices_3_io_msAlloc_12_valid),
    .io_msAlloc_3_12_bits_channel             (slices_3_io_msAlloc_12_bits_channel),
    .io_msAlloc_3_12_bits_is_miss             (slices_3_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_3_12_bits_is_prefetch         (slices_3_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_3_13_valid                    (slices_3_io_msAlloc_13_valid),
    .io_msAlloc_3_13_bits_channel             (slices_3_io_msAlloc_13_bits_channel),
    .io_msAlloc_3_13_bits_is_miss             (slices_3_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_3_13_bits_is_prefetch         (slices_3_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_3_14_valid                    (slices_3_io_msAlloc_14_valid),
    .io_msAlloc_3_14_bits_channel             (slices_3_io_msAlloc_14_bits_channel),
    .io_msAlloc_3_14_bits_is_miss             (slices_3_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_3_14_bits_is_prefetch         (slices_3_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_3_15_valid                    (slices_3_io_msAlloc_15_valid),
    .io_msAlloc_3_15_bits_channel             (slices_3_io_msAlloc_15_bits_channel),
    .io_msAlloc_3_15_bits_is_miss             (slices_3_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_3_15_bits_is_prefetch         (slices_3_io_msAlloc_15_bits_is_prefetch),
    .io_hitPfInMSHR_0_valid                   (slices_0_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_0_bits                    (slices_0_io_hitPfInMSHR_bits),
    .io_hitPfInMSHR_1_valid                   (slices_1_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_1_bits                    (slices_1_io_hitPfInMSHR_bits),
    .io_hitPfInMSHR_2_valid                   (slices_2_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_2_bits                    (slices_2_io_hitPfInMSHR_bits),
    .io_hitPfInMSHR_3_valid                   (slices_3_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_3_bits                    (slices_3_io_hitPfInMSHR_bits),
    .io_pfSent_0_valid                        (slices_0_io_pfSent_valid),
    .io_pfSent_0_bits                         (slices_0_io_pfSent_bits),
    .io_pfSent_1_valid                        (slices_1_io_pfSent_valid),
    .io_pfSent_1_bits                         (slices_1_io_pfSent_bits),
    .io_pfSent_2_valid                        (slices_2_io_pfSent_valid),
    .io_pfSent_2_bits                         (slices_2_io_pfSent_bits),
    .io_pfSent_3_valid                        (slices_3_io_pfSent_valid),
    .io_pfSent_3_bits                         (slices_3_io_pfSent_bits),
    .io_pfLateInMSHR_0_valid                  (slices_0_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_0_bits                   (slices_0_io_pfLateInMSHR_bits),
    .io_pfLateInMSHR_1_valid                  (slices_1_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_1_bits                   (slices_1_io_pfLateInMSHR_bits),
    .io_pfLateInMSHR_2_valid                  (slices_2_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_2_bits                   (slices_2_io_pfLateInMSHR_bits),
    .io_pfLateInMSHR_3_valid                  (slices_3_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_3_bits                   (slices_3_io_pfLateInMSHR_bits),
    .io_debugTopDown_robHeadPaddr_valid       (io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits        (io_debugTopDown_robHeadPaddr_bits),
    .io_debugTopDown_l2MissMatch              (topDown_io_debugTopDown_l2MissMatch)
  );
  Pipeline_10 hintPipe2 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_valid                              (hintFire),
    .io_in_bits                               (l1HintArb_io_out_bits_sourceId),
    .io_out_valid                             (hintPipe2_io_out_valid),
    .io_out_bits                              (hintPipe2_io_out_bits)
  );
  Pipeline_11 hintPipe1 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_valid                              (hintFire),
    .io_in_bits                               (l1HintArb_io_out_bits_sourceId),
    .io_out_valid                             (hintPipe1_io_out_valid),
    .io_out_bits                              (hintPipe1_io_out_bits)
  );
  L2Cache mbistPl (
    .clock                                    (clock),
    .reset                                    (reset),
    .mbist_array                              (l2MbistIntf_toPipeline_0_array),
    .mbist_all                                (l2MbistIntf_toPipeline_0_all),
    .mbist_req                                (l2MbistIntf_toPipeline_0_req),
    .mbist_ack                                (mbistPl_mbist_ack),
    .mbist_writeen                            (l2MbistIntf_toPipeline_0_writeen),
    .mbist_be                                 (l2MbistIntf_toPipeline_0_be),
    .mbist_addr                               (l2MbistIntf_toPipeline_0_addr),
    .mbist_indata                             (l2MbistIntf_toPipeline_0_indata),
    .mbist_readen                             (l2MbistIntf_toPipeline_0_readen),
    .mbist_addr_rd                            (l2MbistIntf_toPipeline_0_addr_rd),
    .mbist_outdata                            (mbistPl_mbist_outdata),
    .toNextPipeline_0_array                   (mbistPl_toNextPipeline_0_array),
    .toNextPipeline_0_all                     (mbistPl_toNextPipeline_0_all),
    .toNextPipeline_0_req                     (mbistPl_toNextPipeline_0_req),
    .toNextPipeline_0_ack                     (prefetcher_boreChildrenBd_bore_ack),
    .toNextPipeline_0_writeen                 (mbistPl_toNextPipeline_0_writeen),
    .toNextPipeline_0_be                      (mbistPl_toNextPipeline_0_be),
    .toNextPipeline_0_addr                    (mbistPl_toNextPipeline_0_addr),
    .toNextPipeline_0_indata                  (mbistPl_toNextPipeline_0_indata),
    .toNextPipeline_0_readen                  (mbistPl_toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd                 (mbistPl_toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata                 (prefetcher_boreChildrenBd_bore_outdata),
    .toNextPipeline_1_array                   (mbistPl_toNextPipeline_1_array),
    .toNextPipeline_1_all                     (mbistPl_toNextPipeline_1_all),
    .toNextPipeline_1_req                     (mbistPl_toNextPipeline_1_req),
    .toNextPipeline_1_ack                     (slices_0_boreChildrenBd_bore_ack),
    .toNextPipeline_1_writeen                 (mbistPl_toNextPipeline_1_writeen),
    .toNextPipeline_1_be                      (mbistPl_toNextPipeline_1_be),
    .toNextPipeline_1_addr                    (mbistPl_toNextPipeline_1_addr),
    .toNextPipeline_1_indata                  (mbistPl_toNextPipeline_1_indata),
    .toNextPipeline_1_readen                  (mbistPl_toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd                 (mbistPl_toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata                 (slices_0_boreChildrenBd_bore_outdata),
    .toNextPipeline_2_array                   (mbistPl_toNextPipeline_2_array),
    .toNextPipeline_2_all                     (mbistPl_toNextPipeline_2_all),
    .toNextPipeline_2_req                     (mbistPl_toNextPipeline_2_req),
    .toNextPipeline_2_ack                     (slices_1_boreChildrenBd_bore_ack),
    .toNextPipeline_2_writeen                 (mbistPl_toNextPipeline_2_writeen),
    .toNextPipeline_2_be                      (mbistPl_toNextPipeline_2_be),
    .toNextPipeline_2_addr                    (mbistPl_toNextPipeline_2_addr),
    .toNextPipeline_2_indata                  (mbistPl_toNextPipeline_2_indata),
    .toNextPipeline_2_readen                  (mbistPl_toNextPipeline_2_readen),
    .toNextPipeline_2_addr_rd                 (mbistPl_toNextPipeline_2_addr_rd),
    .toNextPipeline_2_outdata                 (slices_1_boreChildrenBd_bore_outdata),
    .toNextPipeline_3_array                   (mbistPl_toNextPipeline_3_array),
    .toNextPipeline_3_all                     (mbistPl_toNextPipeline_3_all),
    .toNextPipeline_3_req                     (mbistPl_toNextPipeline_3_req),
    .toNextPipeline_3_ack                     (slices_2_boreChildrenBd_bore_ack),
    .toNextPipeline_3_writeen                 (mbistPl_toNextPipeline_3_writeen),
    .toNextPipeline_3_be                      (mbistPl_toNextPipeline_3_be),
    .toNextPipeline_3_addr                    (mbistPl_toNextPipeline_3_addr),
    .toNextPipeline_3_indata                  (mbistPl_toNextPipeline_3_indata),
    .toNextPipeline_3_readen                  (mbistPl_toNextPipeline_3_readen),
    .toNextPipeline_3_addr_rd                 (mbistPl_toNextPipeline_3_addr_rd),
    .toNextPipeline_3_outdata                 (slices_2_boreChildrenBd_bore_outdata),
    .toNextPipeline_4_array                   (mbistPl_toNextPipeline_4_array),
    .toNextPipeline_4_all                     (mbistPl_toNextPipeline_4_all),
    .toNextPipeline_4_req                     (mbistPl_toNextPipeline_4_req),
    .toNextPipeline_4_ack                     (slices_3_boreChildrenBd_bore_ack),
    .toNextPipeline_4_writeen                 (mbistPl_toNextPipeline_4_writeen),
    .toNextPipeline_4_be                      (mbistPl_toNextPipeline_4_be),
    .toNextPipeline_4_addr                    (mbistPl_toNextPipeline_4_addr),
    .toNextPipeline_4_indata                  (mbistPl_toNextPipeline_4_indata),
    .toNextPipeline_4_readen                  (mbistPl_toNextPipeline_4_readen),
    .toNextPipeline_4_addr_rd                 (mbistPl_toNextPipeline_4_addr_rd),
    .toNextPipeline_4_outdata                 (slices_3_boreChildrenBd_bore_outdata)
  );
  MbistIntfL2 l2MbistIntf (
    .toPipeline_0_array                       (l2MbistIntf_toPipeline_0_array),
    .toPipeline_0_all                         (l2MbistIntf_toPipeline_0_all),
    .toPipeline_0_req                         (l2MbistIntf_toPipeline_0_req),
    .toPipeline_0_ack                         (mbistPl_mbist_ack),
    .toPipeline_0_writeen                     (l2MbistIntf_toPipeline_0_writeen),
    .toPipeline_0_be                          (l2MbistIntf_toPipeline_0_be),
    .toPipeline_0_addr                        (l2MbistIntf_toPipeline_0_addr),
    .toPipeline_0_indata                      (l2MbistIntf_toPipeline_0_indata),
    .toPipeline_0_readen                      (l2MbistIntf_toPipeline_0_readen),
    .toPipeline_0_addr_rd                     (l2MbistIntf_toPipeline_0_addr_rd),
    .toPipeline_0_outdata                     (mbistPl_mbist_outdata),
    .mbist_array                              (6'h0),
    .mbist_all                                (1'h0),
    .mbist_req                                (1'h0),
    .mbist_ack                                (),
    .mbist_writeen                            (1'h0),
    .mbist_be                                 (8'h0),
    .mbist_addr                               (13'h0),
    .mbist_indata                             (137'h0),
    .mbist_readen                             (1'h0),
    .mbist_addr_rd                            (13'h0),
    .mbist_outdata                            ()
  );
  RRArbiterInit_20 txreq_arb (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_0_ready                            (txreq_arb_io_in_0_ready),
    .io_in_0_valid                            (slices_0_io_out_tx_req_valid),
    .io_in_0_bits_qos                         (slices_0_io_out_tx_req_bits_qos),
    .io_in_0_bits_txnID                       (slices_0_io_out_tx_req_bits_txnID),
    .io_in_0_bits_returnNID                   (slices_0_io_out_tx_req_bits_returnNID),
    .io_in_0_bits_stashNIDValid               (slices_0_io_out_tx_req_bits_stashNIDValid),
    .io_in_0_bits_returnTxnID                 (slices_0_io_out_tx_req_bits_returnTxnID),
    .io_in_0_bits_opcode                      (slices_0_io_out_tx_req_bits_opcode),
    .io_in_0_bits_addr                        (slices_0_io_out_tx_req_bits_addr),
    .io_in_0_bits_ns                          (slices_0_io_out_tx_req_bits_ns),
    .io_in_0_bits_likelyshared                (slices_0_io_out_tx_req_bits_likelyshared),
    .io_in_0_bits_allowRetry                  (slices_0_io_out_tx_req_bits_allowRetry),
    .io_in_0_bits_order                       (slices_0_io_out_tx_req_bits_order),
    .io_in_0_bits_pCrdType                    (slices_0_io_out_tx_req_bits_pCrdType),
    .io_in_0_bits_memAttr_allocate            (slices_0_io_out_tx_req_bits_memAttr_allocate),
    .io_in_0_bits_memAttr_cacheable           (slices_0_io_out_tx_req_bits_memAttr_cacheable),
    .io_in_0_bits_memAttr_device              (slices_0_io_out_tx_req_bits_memAttr_device),
    .io_in_0_bits_memAttr_ewa                 (slices_0_io_out_tx_req_bits_memAttr_ewa),
    .io_in_0_bits_snpAttr                     (slices_0_io_out_tx_req_bits_snpAttr),
    .io_in_0_bits_lpIDWithPadding             (slices_0_io_out_tx_req_bits_lpIDWithPadding),
    .io_in_0_bits_snoopMe                     (slices_0_io_out_tx_req_bits_snoopMe),
    .io_in_0_bits_expCompAck                  (slices_0_io_out_tx_req_bits_expCompAck),
    .io_in_0_bits_tagOp                       (slices_0_io_out_tx_req_bits_tagOp),
    .io_in_0_bits_traceTag                    (slices_0_io_out_tx_req_bits_traceTag),
    .io_in_0_bits_mpam_perfMonGroup           (slices_0_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_in_0_bits_mpam_partID                 (slices_0_io_out_tx_req_bits_mpam_partID),
    .io_in_0_bits_mpam_mpamNS                 (slices_0_io_out_tx_req_bits_mpam_mpamNS),
    .io_in_0_bits_rsvdc                       (slices_0_io_out_tx_req_bits_rsvdc),
    .io_in_1_ready                            (txreq_arb_io_in_1_ready),
    .io_in_1_valid                            (slices_1_io_out_tx_req_valid),
    .io_in_1_bits_qos                         (slices_1_io_out_tx_req_bits_qos),
    .io_in_1_bits_txnID                       (slices_1_io_out_tx_req_bits_txnID),
    .io_in_1_bits_returnNID                   (slices_1_io_out_tx_req_bits_returnNID),
    .io_in_1_bits_stashNIDValid               (slices_1_io_out_tx_req_bits_stashNIDValid),
    .io_in_1_bits_returnTxnID                 (slices_1_io_out_tx_req_bits_returnTxnID),
    .io_in_1_bits_opcode                      (slices_1_io_out_tx_req_bits_opcode),
    .io_in_1_bits_addr                        (slices_1_io_out_tx_req_bits_addr),
    .io_in_1_bits_ns                          (slices_1_io_out_tx_req_bits_ns),
    .io_in_1_bits_likelyshared                (slices_1_io_out_tx_req_bits_likelyshared),
    .io_in_1_bits_allowRetry                  (slices_1_io_out_tx_req_bits_allowRetry),
    .io_in_1_bits_order                       (slices_1_io_out_tx_req_bits_order),
    .io_in_1_bits_pCrdType                    (slices_1_io_out_tx_req_bits_pCrdType),
    .io_in_1_bits_memAttr_allocate            (slices_1_io_out_tx_req_bits_memAttr_allocate),
    .io_in_1_bits_memAttr_cacheable           (slices_1_io_out_tx_req_bits_memAttr_cacheable),
    .io_in_1_bits_memAttr_device              (slices_1_io_out_tx_req_bits_memAttr_device),
    .io_in_1_bits_memAttr_ewa                 (slices_1_io_out_tx_req_bits_memAttr_ewa),
    .io_in_1_bits_snpAttr                     (slices_1_io_out_tx_req_bits_snpAttr),
    .io_in_1_bits_lpIDWithPadding             (slices_1_io_out_tx_req_bits_lpIDWithPadding),
    .io_in_1_bits_snoopMe                     (slices_1_io_out_tx_req_bits_snoopMe),
    .io_in_1_bits_expCompAck                  (slices_1_io_out_tx_req_bits_expCompAck),
    .io_in_1_bits_tagOp                       (slices_1_io_out_tx_req_bits_tagOp),
    .io_in_1_bits_traceTag                    (slices_1_io_out_tx_req_bits_traceTag),
    .io_in_1_bits_mpam_perfMonGroup           (slices_1_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_in_1_bits_mpam_partID                 (slices_1_io_out_tx_req_bits_mpam_partID),
    .io_in_1_bits_mpam_mpamNS                 (slices_1_io_out_tx_req_bits_mpam_mpamNS),
    .io_in_1_bits_rsvdc                       (slices_1_io_out_tx_req_bits_rsvdc),
    .io_in_2_ready                            (txreq_arb_io_in_2_ready),
    .io_in_2_valid                            (slices_2_io_out_tx_req_valid),
    .io_in_2_bits_qos                         (slices_2_io_out_tx_req_bits_qos),
    .io_in_2_bits_txnID                       (slices_2_io_out_tx_req_bits_txnID),
    .io_in_2_bits_returnNID                   (slices_2_io_out_tx_req_bits_returnNID),
    .io_in_2_bits_stashNIDValid               (slices_2_io_out_tx_req_bits_stashNIDValid),
    .io_in_2_bits_returnTxnID                 (slices_2_io_out_tx_req_bits_returnTxnID),
    .io_in_2_bits_opcode                      (slices_2_io_out_tx_req_bits_opcode),
    .io_in_2_bits_addr                        (slices_2_io_out_tx_req_bits_addr),
    .io_in_2_bits_ns                          (slices_2_io_out_tx_req_bits_ns),
    .io_in_2_bits_likelyshared                (slices_2_io_out_tx_req_bits_likelyshared),
    .io_in_2_bits_allowRetry                  (slices_2_io_out_tx_req_bits_allowRetry),
    .io_in_2_bits_order                       (slices_2_io_out_tx_req_bits_order),
    .io_in_2_bits_pCrdType                    (slices_2_io_out_tx_req_bits_pCrdType),
    .io_in_2_bits_memAttr_allocate            (slices_2_io_out_tx_req_bits_memAttr_allocate),
    .io_in_2_bits_memAttr_cacheable           (slices_2_io_out_tx_req_bits_memAttr_cacheable),
    .io_in_2_bits_memAttr_device              (slices_2_io_out_tx_req_bits_memAttr_device),
    .io_in_2_bits_memAttr_ewa                 (slices_2_io_out_tx_req_bits_memAttr_ewa),
    .io_in_2_bits_snpAttr                     (slices_2_io_out_tx_req_bits_snpAttr),
    .io_in_2_bits_lpIDWithPadding             (slices_2_io_out_tx_req_bits_lpIDWithPadding),
    .io_in_2_bits_snoopMe                     (slices_2_io_out_tx_req_bits_snoopMe),
    .io_in_2_bits_expCompAck                  (slices_2_io_out_tx_req_bits_expCompAck),
    .io_in_2_bits_tagOp                       (slices_2_io_out_tx_req_bits_tagOp),
    .io_in_2_bits_traceTag                    (slices_2_io_out_tx_req_bits_traceTag),
    .io_in_2_bits_mpam_perfMonGroup           (slices_2_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_in_2_bits_mpam_partID                 (slices_2_io_out_tx_req_bits_mpam_partID),
    .io_in_2_bits_mpam_mpamNS                 (slices_2_io_out_tx_req_bits_mpam_mpamNS),
    .io_in_2_bits_rsvdc                       (slices_2_io_out_tx_req_bits_rsvdc),
    .io_in_3_ready                            (txreq_arb_io_in_3_ready),
    .io_in_3_valid                            (slices_3_io_out_tx_req_valid),
    .io_in_3_bits_qos                         (slices_3_io_out_tx_req_bits_qos),
    .io_in_3_bits_txnID                       (slices_3_io_out_tx_req_bits_txnID),
    .io_in_3_bits_returnNID                   (slices_3_io_out_tx_req_bits_returnNID),
    .io_in_3_bits_stashNIDValid               (slices_3_io_out_tx_req_bits_stashNIDValid),
    .io_in_3_bits_returnTxnID                 (slices_3_io_out_tx_req_bits_returnTxnID),
    .io_in_3_bits_opcode                      (slices_3_io_out_tx_req_bits_opcode),
    .io_in_3_bits_addr                        (slices_3_io_out_tx_req_bits_addr),
    .io_in_3_bits_ns                          (slices_3_io_out_tx_req_bits_ns),
    .io_in_3_bits_likelyshared                (slices_3_io_out_tx_req_bits_likelyshared),
    .io_in_3_bits_allowRetry                  (slices_3_io_out_tx_req_bits_allowRetry),
    .io_in_3_bits_order                       (slices_3_io_out_tx_req_bits_order),
    .io_in_3_bits_pCrdType                    (slices_3_io_out_tx_req_bits_pCrdType),
    .io_in_3_bits_memAttr_allocate            (slices_3_io_out_tx_req_bits_memAttr_allocate),
    .io_in_3_bits_memAttr_cacheable           (slices_3_io_out_tx_req_bits_memAttr_cacheable),
    .io_in_3_bits_memAttr_device              (slices_3_io_out_tx_req_bits_memAttr_device),
    .io_in_3_bits_memAttr_ewa                 (slices_3_io_out_tx_req_bits_memAttr_ewa),
    .io_in_3_bits_snpAttr                     (slices_3_io_out_tx_req_bits_snpAttr),
    .io_in_3_bits_lpIDWithPadding             (slices_3_io_out_tx_req_bits_lpIDWithPadding),
    .io_in_3_bits_snoopMe                     (slices_3_io_out_tx_req_bits_snoopMe),
    .io_in_3_bits_expCompAck                  (slices_3_io_out_tx_req_bits_expCompAck),
    .io_in_3_bits_tagOp                       (slices_3_io_out_tx_req_bits_tagOp),
    .io_in_3_bits_traceTag                    (slices_3_io_out_tx_req_bits_traceTag),
    .io_in_3_bits_mpam_perfMonGroup           (slices_3_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_in_3_bits_mpam_partID                 (slices_3_io_out_tx_req_bits_mpam_partID),
    .io_in_3_bits_mpam_mpamNS                 (slices_3_io_out_tx_req_bits_mpam_mpamNS),
    .io_in_3_bits_rsvdc                       (slices_3_io_out_tx_req_bits_rsvdc),
    .io_in_4_ready                            (txreq_arb_io_in_4_ready),
    .io_in_4_valid                            (mmioBridge_io_tx_req_valid),
    .io_in_4_bits_qos                         (mmioBridge_io_tx_req_bits_qos),
    .io_in_4_bits_tgtID                       (mmioBridge_io_tx_req_bits_tgtID),
    .io_in_4_bits_txnID                       (mmioBridge_io_tx_req_bits_txnID),
    .io_in_4_bits_returnNID                   (mmioBridge_io_tx_req_bits_returnNID),
    .io_in_4_bits_stashNIDValid               (mmioBridge_io_tx_req_bits_stashNIDValid),
    .io_in_4_bits_returnTxnID                 (mmioBridge_io_tx_req_bits_returnTxnID),
    .io_in_4_bits_opcode                      (mmioBridge_io_tx_req_bits_opcode),
    .io_in_4_bits_size                        (mmioBridge_io_tx_req_bits_size),
    .io_in_4_bits_addr                        (mmioBridge_io_tx_req_bits_addr),
    .io_in_4_bits_ns                          (mmioBridge_io_tx_req_bits_ns),
    .io_in_4_bits_likelyshared                (mmioBridge_io_tx_req_bits_likelyshared),
    .io_in_4_bits_allowRetry                  (mmioBridge_io_tx_req_bits_allowRetry),
    .io_in_4_bits_order                       (mmioBridge_io_tx_req_bits_order),
    .io_in_4_bits_pCrdType                    (mmioBridge_io_tx_req_bits_pCrdType),
    .io_in_4_bits_memAttr_allocate            (mmioBridge_io_tx_req_bits_memAttr_allocate),
    .io_in_4_bits_memAttr_cacheable           (mmioBridge_io_tx_req_bits_memAttr_cacheable),
    .io_in_4_bits_memAttr_device              (mmioBridge_io_tx_req_bits_memAttr_device),
    .io_in_4_bits_memAttr_ewa                 (mmioBridge_io_tx_req_bits_memAttr_ewa),
    .io_in_4_bits_snpAttr                     (mmioBridge_io_tx_req_bits_snpAttr),
    .io_in_4_bits_lpIDWithPadding             (mmioBridge_io_tx_req_bits_lpIDWithPadding),
    .io_in_4_bits_snoopMe                     (mmioBridge_io_tx_req_bits_snoopMe),
    .io_in_4_bits_expCompAck                  (mmioBridge_io_tx_req_bits_expCompAck),
    .io_in_4_bits_tagOp                       (mmioBridge_io_tx_req_bits_tagOp),
    .io_in_4_bits_traceTag                    (mmioBridge_io_tx_req_bits_traceTag),
    .io_in_4_bits_mpam_perfMonGroup           (mmioBridge_io_tx_req_bits_mpam_perfMonGroup),
    .io_in_4_bits_mpam_partID                 (mmioBridge_io_tx_req_bits_mpam_partID),
    .io_in_4_bits_mpam_mpamNS                 (mmioBridge_io_tx_req_bits_mpam_mpamNS),
    .io_in_4_bits_rsvdc                       (mmioBridge_io_tx_req_bits_rsvdc),
    .io_out_ready                             (txReqArb_outReady),
    .io_out_valid                             (txreq_arb_io_out_valid),
    .io_out_bits_qos                          (txreq_arb_io_out_bits_qos),
    .io_out_bits_tgtID                        (txreq_arb_io_out_bits_tgtID),
    .io_out_bits_txnID                        (txreq_arb_io_out_bits_txnID),
    .io_out_bits_returnNID                    (txreq_arb_io_out_bits_returnNID),
    .io_out_bits_stashNIDValid                (txreq_arb_io_out_bits_stashNIDValid),
    .io_out_bits_returnTxnID                  (txreq_arb_io_out_bits_returnTxnID),
    .io_out_bits_opcode                       (txreq_arb_io_out_bits_opcode),
    .io_out_bits_size                         (txreq_arb_io_out_bits_size),
    .io_out_bits_addr                         (txreq_arb_io_out_bits_addr),
    .io_out_bits_ns                           (txreq_arb_io_out_bits_ns),
    .io_out_bits_likelyshared                 (txreq_arb_io_out_bits_likelyshared),
    .io_out_bits_allowRetry                   (txreq_arb_io_out_bits_allowRetry),
    .io_out_bits_order                        (txreq_arb_io_out_bits_order),
    .io_out_bits_pCrdType                     (txreq_arb_io_out_bits_pCrdType),
    .io_out_bits_memAttr_allocate             (txreq_arb_io_out_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable            (txreq_arb_io_out_bits_memAttr_cacheable),
    .io_out_bits_memAttr_device               (txreq_arb_io_out_bits_memAttr_device),
    .io_out_bits_memAttr_ewa                  (txreq_arb_io_out_bits_memAttr_ewa),
    .io_out_bits_snpAttr                      (txreq_arb_io_out_bits_snpAttr),
    .io_out_bits_lpIDWithPadding              (txreq_arb_io_out_bits_lpIDWithPadding),
    .io_out_bits_snoopMe                      (txreq_arb_io_out_bits_snoopMe),
    .io_out_bits_expCompAck                   (txreq_arb_io_out_bits_expCompAck),
    .io_out_bits_tagOp                        (txreq_arb_io_out_bits_tagOp),
    .io_out_bits_traceTag                     (txreq_arb_io_out_bits_traceTag),
    .io_out_bits_mpam_perfMonGroup            (txreq_arb_io_out_bits_mpam_perfMonGroup),
    .io_out_bits_mpam_partID                  (txreq_arb_io_out_bits_mpam_partID),
    .io_out_bits_mpam_mpamNS                  (txreq_arb_io_out_bits_mpam_mpamNS),
    .io_out_bits_rsvdc                        (txreq_arb_io_out_bits_rsvdc),
    .io_chosen                                (txreq_arb_io_chosen)
  );
  FastArbiter_26 txrsp_arb (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_0_ready                            (txrsp_arb_io_in_0_ready),
    .io_in_0_valid                            (slices_0_io_out_tx_rsp_valid),
    .io_in_0_bits_qos                         (slices_0_io_out_tx_rsp_bits_qos),
    .io_in_0_bits_tgtID                       (slices_0_io_out_tx_rsp_bits_tgtID),
    .io_in_0_bits_txnID                       (slices_0_io_out_tx_rsp_bits_txnID),
    .io_in_0_bits_opcode                      (slices_0_io_out_tx_rsp_bits_opcode),
    .io_in_0_bits_respErr                     (slices_0_io_out_tx_rsp_bits_respErr),
    .io_in_0_bits_resp                        (slices_0_io_out_tx_rsp_bits_resp),
    .io_in_0_bits_fwdState                    (slices_0_io_out_tx_rsp_bits_fwdState),
    .io_in_0_bits_cBusy                       (slices_0_io_out_tx_rsp_bits_cBusy),
    .io_in_0_bits_dbID                        (slices_0_io_out_tx_rsp_bits_dbID),
    .io_in_0_bits_pCrdType                    (slices_0_io_out_tx_rsp_bits_pCrdType),
    .io_in_0_bits_tagOp                       (slices_0_io_out_tx_rsp_bits_tagOp),
    .io_in_0_bits_traceTag                    (slices_0_io_out_tx_rsp_bits_traceTag),
    .io_in_1_ready                            (txrsp_arb_io_in_1_ready),
    .io_in_1_valid                            (slices_1_io_out_tx_rsp_valid),
    .io_in_1_bits_qos                         (slices_1_io_out_tx_rsp_bits_qos),
    .io_in_1_bits_tgtID                       (slices_1_io_out_tx_rsp_bits_tgtID),
    .io_in_1_bits_txnID                       (slices_1_io_out_tx_rsp_bits_txnID),
    .io_in_1_bits_opcode                      (slices_1_io_out_tx_rsp_bits_opcode),
    .io_in_1_bits_respErr                     (slices_1_io_out_tx_rsp_bits_respErr),
    .io_in_1_bits_resp                        (slices_1_io_out_tx_rsp_bits_resp),
    .io_in_1_bits_fwdState                    (slices_1_io_out_tx_rsp_bits_fwdState),
    .io_in_1_bits_cBusy                       (slices_1_io_out_tx_rsp_bits_cBusy),
    .io_in_1_bits_dbID                        (slices_1_io_out_tx_rsp_bits_dbID),
    .io_in_1_bits_pCrdType                    (slices_1_io_out_tx_rsp_bits_pCrdType),
    .io_in_1_bits_tagOp                       (slices_1_io_out_tx_rsp_bits_tagOp),
    .io_in_1_bits_traceTag                    (slices_1_io_out_tx_rsp_bits_traceTag),
    .io_in_2_ready                            (txrsp_arb_io_in_2_ready),
    .io_in_2_valid                            (slices_2_io_out_tx_rsp_valid),
    .io_in_2_bits_qos                         (slices_2_io_out_tx_rsp_bits_qos),
    .io_in_2_bits_tgtID                       (slices_2_io_out_tx_rsp_bits_tgtID),
    .io_in_2_bits_txnID                       (slices_2_io_out_tx_rsp_bits_txnID),
    .io_in_2_bits_opcode                      (slices_2_io_out_tx_rsp_bits_opcode),
    .io_in_2_bits_respErr                     (slices_2_io_out_tx_rsp_bits_respErr),
    .io_in_2_bits_resp                        (slices_2_io_out_tx_rsp_bits_resp),
    .io_in_2_bits_fwdState                    (slices_2_io_out_tx_rsp_bits_fwdState),
    .io_in_2_bits_cBusy                       (slices_2_io_out_tx_rsp_bits_cBusy),
    .io_in_2_bits_dbID                        (slices_2_io_out_tx_rsp_bits_dbID),
    .io_in_2_bits_pCrdType                    (slices_2_io_out_tx_rsp_bits_pCrdType),
    .io_in_2_bits_tagOp                       (slices_2_io_out_tx_rsp_bits_tagOp),
    .io_in_2_bits_traceTag                    (slices_2_io_out_tx_rsp_bits_traceTag),
    .io_in_3_ready                            (txrsp_arb_io_in_3_ready),
    .io_in_3_valid                            (slices_3_io_out_tx_rsp_valid),
    .io_in_3_bits_qos                         (slices_3_io_out_tx_rsp_bits_qos),
    .io_in_3_bits_tgtID                       (slices_3_io_out_tx_rsp_bits_tgtID),
    .io_in_3_bits_txnID                       (slices_3_io_out_tx_rsp_bits_txnID),
    .io_in_3_bits_opcode                      (slices_3_io_out_tx_rsp_bits_opcode),
    .io_in_3_bits_respErr                     (slices_3_io_out_tx_rsp_bits_respErr),
    .io_in_3_bits_resp                        (slices_3_io_out_tx_rsp_bits_resp),
    .io_in_3_bits_fwdState                    (slices_3_io_out_tx_rsp_bits_fwdState),
    .io_in_3_bits_cBusy                       (slices_3_io_out_tx_rsp_bits_cBusy),
    .io_in_3_bits_dbID                        (slices_3_io_out_tx_rsp_bits_dbID),
    .io_in_3_bits_pCrdType                    (slices_3_io_out_tx_rsp_bits_pCrdType),
    .io_in_3_bits_tagOp                       (slices_3_io_out_tx_rsp_bits_tagOp),
    .io_in_3_bits_traceTag                    (slices_3_io_out_tx_rsp_bits_traceTag),
    .io_out_ready                             (linkMonitor_io_in_tx_rsp_ready),
    .io_out_valid                             (txrsp_arb_io_out_valid),
    .io_out_bits_qos                          (txrsp_arb_io_out_bits_qos),
    .io_out_bits_tgtID                        (txrsp_arb_io_out_bits_tgtID),
    .io_out_bits_txnID                        (txrsp_arb_io_out_bits_txnID),
    .io_out_bits_opcode                       (txrsp_arb_io_out_bits_opcode),
    .io_out_bits_respErr                      (txrsp_arb_io_out_bits_respErr),
    .io_out_bits_resp                         (txrsp_arb_io_out_bits_resp),
    .io_out_bits_fwdState                     (txrsp_arb_io_out_bits_fwdState),
    .io_out_bits_cBusy                        (txrsp_arb_io_out_bits_cBusy),
    .io_out_bits_dbID                         (txrsp_arb_io_out_bits_dbID),
    .io_out_bits_pCrdType                     (txrsp_arb_io_out_bits_pCrdType),
    .io_out_bits_tagOp                        (txrsp_arb_io_out_bits_tagOp),
    .io_out_bits_traceTag                     (txrsp_arb_io_out_bits_traceTag),
    .io_chosen                                ()
  );
  FastArbiter_27 txdat_arb (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_0_ready                            (txdat_arb_io_in_0_ready),
    .io_in_0_valid                            (slices_0_io_out_tx_dat_valid),
    .io_in_0_bits_tgtID                       (slices_0_io_out_tx_dat_bits_tgtID),
    .io_in_0_bits_txnID                       (slices_0_io_out_tx_dat_bits_txnID),
    .io_in_0_bits_homeNID                     (slices_0_io_out_tx_dat_bits_homeNID),
    .io_in_0_bits_opcode                      (slices_0_io_out_tx_dat_bits_opcode),
    .io_in_0_bits_respErr                     (slices_0_io_out_tx_dat_bits_respErr),
    .io_in_0_bits_resp                        (slices_0_io_out_tx_dat_bits_resp),
    .io_in_0_bits_dataSource                  (slices_0_io_out_tx_dat_bits_dataSource),
    .io_in_0_bits_dbID                        (slices_0_io_out_tx_dat_bits_dbID),
    .io_in_0_bits_ccID                        (slices_0_io_out_tx_dat_bits_ccID),
    .io_in_0_bits_dataID                      (slices_0_io_out_tx_dat_bits_dataID),
    .io_in_0_bits_traceTag                    (slices_0_io_out_tx_dat_bits_traceTag),
    .io_in_0_bits_be                          (slices_0_io_out_tx_dat_bits_be),
    .io_in_0_bits_data                        (slices_0_io_out_tx_dat_bits_data),
    .io_in_0_bits_dataCheck                   (slices_0_io_out_tx_dat_bits_dataCheck),
    .io_in_0_bits_poison                      (slices_0_io_out_tx_dat_bits_poison),
    .io_in_1_ready                            (txdat_arb_io_in_1_ready),
    .io_in_1_valid                            (slices_1_io_out_tx_dat_valid),
    .io_in_1_bits_tgtID                       (slices_1_io_out_tx_dat_bits_tgtID),
    .io_in_1_bits_txnID                       (slices_1_io_out_tx_dat_bits_txnID),
    .io_in_1_bits_homeNID                     (slices_1_io_out_tx_dat_bits_homeNID),
    .io_in_1_bits_opcode                      (slices_1_io_out_tx_dat_bits_opcode),
    .io_in_1_bits_respErr                     (slices_1_io_out_tx_dat_bits_respErr),
    .io_in_1_bits_resp                        (slices_1_io_out_tx_dat_bits_resp),
    .io_in_1_bits_dataSource                  (slices_1_io_out_tx_dat_bits_dataSource),
    .io_in_1_bits_dbID                        (slices_1_io_out_tx_dat_bits_dbID),
    .io_in_1_bits_ccID                        (slices_1_io_out_tx_dat_bits_ccID),
    .io_in_1_bits_dataID                      (slices_1_io_out_tx_dat_bits_dataID),
    .io_in_1_bits_traceTag                    (slices_1_io_out_tx_dat_bits_traceTag),
    .io_in_1_bits_be                          (slices_1_io_out_tx_dat_bits_be),
    .io_in_1_bits_data                        (slices_1_io_out_tx_dat_bits_data),
    .io_in_1_bits_dataCheck                   (slices_1_io_out_tx_dat_bits_dataCheck),
    .io_in_1_bits_poison                      (slices_1_io_out_tx_dat_bits_poison),
    .io_in_2_ready                            (txdat_arb_io_in_2_ready),
    .io_in_2_valid                            (slices_2_io_out_tx_dat_valid),
    .io_in_2_bits_tgtID                       (slices_2_io_out_tx_dat_bits_tgtID),
    .io_in_2_bits_txnID                       (slices_2_io_out_tx_dat_bits_txnID),
    .io_in_2_bits_homeNID                     (slices_2_io_out_tx_dat_bits_homeNID),
    .io_in_2_bits_opcode                      (slices_2_io_out_tx_dat_bits_opcode),
    .io_in_2_bits_respErr                     (slices_2_io_out_tx_dat_bits_respErr),
    .io_in_2_bits_resp                        (slices_2_io_out_tx_dat_bits_resp),
    .io_in_2_bits_dataSource                  (slices_2_io_out_tx_dat_bits_dataSource),
    .io_in_2_bits_dbID                        (slices_2_io_out_tx_dat_bits_dbID),
    .io_in_2_bits_ccID                        (slices_2_io_out_tx_dat_bits_ccID),
    .io_in_2_bits_dataID                      (slices_2_io_out_tx_dat_bits_dataID),
    .io_in_2_bits_traceTag                    (slices_2_io_out_tx_dat_bits_traceTag),
    .io_in_2_bits_be                          (slices_2_io_out_tx_dat_bits_be),
    .io_in_2_bits_data                        (slices_2_io_out_tx_dat_bits_data),
    .io_in_2_bits_dataCheck                   (slices_2_io_out_tx_dat_bits_dataCheck),
    .io_in_2_bits_poison                      (slices_2_io_out_tx_dat_bits_poison),
    .io_in_3_ready                            (txdat_arb_io_in_3_ready),
    .io_in_3_valid                            (slices_3_io_out_tx_dat_valid),
    .io_in_3_bits_tgtID                       (slices_3_io_out_tx_dat_bits_tgtID),
    .io_in_3_bits_txnID                       (slices_3_io_out_tx_dat_bits_txnID),
    .io_in_3_bits_homeNID                     (slices_3_io_out_tx_dat_bits_homeNID),
    .io_in_3_bits_opcode                      (slices_3_io_out_tx_dat_bits_opcode),
    .io_in_3_bits_respErr                     (slices_3_io_out_tx_dat_bits_respErr),
    .io_in_3_bits_resp                        (slices_3_io_out_tx_dat_bits_resp),
    .io_in_3_bits_dataSource                  (slices_3_io_out_tx_dat_bits_dataSource),
    .io_in_3_bits_dbID                        (slices_3_io_out_tx_dat_bits_dbID),
    .io_in_3_bits_ccID                        (slices_3_io_out_tx_dat_bits_ccID),
    .io_in_3_bits_dataID                      (slices_3_io_out_tx_dat_bits_dataID),
    .io_in_3_bits_traceTag                    (slices_3_io_out_tx_dat_bits_traceTag),
    .io_in_3_bits_be                          (slices_3_io_out_tx_dat_bits_be),
    .io_in_3_bits_data                        (slices_3_io_out_tx_dat_bits_data),
    .io_in_3_bits_dataCheck                   (slices_3_io_out_tx_dat_bits_dataCheck),
    .io_in_3_bits_poison                      (slices_3_io_out_tx_dat_bits_poison),
    .io_in_4_ready                            (txdat_arb_io_in_4_ready),
    .io_in_4_valid                            (mmioBridge_io_tx_dat_valid),
    .io_in_4_bits_qos                         (mmioBridge_io_tx_dat_bits_qos),
    .io_in_4_bits_tgtID                       (mmioBridge_io_tx_dat_bits_tgtID),
    .io_in_4_bits_txnID                       (mmioBridge_io_tx_dat_bits_txnID),
    .io_in_4_bits_homeNID                     (mmioBridge_io_tx_dat_bits_homeNID),
    .io_in_4_bits_opcode                      (mmioBridge_io_tx_dat_bits_opcode),
    .io_in_4_bits_respErr                     (mmioBridge_io_tx_dat_bits_respErr),
    .io_in_4_bits_resp                        (mmioBridge_io_tx_dat_bits_resp),
    .io_in_4_bits_dataSource                  (mmioBridge_io_tx_dat_bits_dataSource),
    .io_in_4_bits_cBusy                       (mmioBridge_io_tx_dat_bits_cBusy),
    .io_in_4_bits_dbID                        (mmioBridge_io_tx_dat_bits_dbID),
    .io_in_4_bits_ccID                        (mmioBridge_io_tx_dat_bits_ccID),
    .io_in_4_bits_dataID                      (mmioBridge_io_tx_dat_bits_dataID),
    .io_in_4_bits_tagOp                       (mmioBridge_io_tx_dat_bits_tagOp),
    .io_in_4_bits_tag                         (mmioBridge_io_tx_dat_bits_tag),
    .io_in_4_bits_tu                          (mmioBridge_io_tx_dat_bits_tu),
    .io_in_4_bits_traceTag                    (mmioBridge_io_tx_dat_bits_traceTag),
    .io_in_4_bits_rsvdc                       (mmioBridge_io_tx_dat_bits_rsvdc),
    .io_in_4_bits_be                          (mmioBridge_io_tx_dat_bits_be),
    .io_in_4_bits_data                        (mmioBridge_io_tx_dat_bits_data),
    .io_in_4_bits_dataCheck                   (mmioBridge_io_tx_dat_bits_dataCheck),
    .io_in_4_bits_poison                      (mmioBridge_io_tx_dat_bits_poison),
    .io_out_ready                             (linkMonitor_io_in_tx_dat_ready),
    .io_out_valid                             (txdat_arb_io_out_valid),
    .io_out_bits_qos                          (txdat_arb_io_out_bits_qos),
    .io_out_bits_tgtID                        (txdat_arb_io_out_bits_tgtID),
    .io_out_bits_txnID                        (txdat_arb_io_out_bits_txnID),
    .io_out_bits_homeNID                      (txdat_arb_io_out_bits_homeNID),
    .io_out_bits_opcode                       (txdat_arb_io_out_bits_opcode),
    .io_out_bits_respErr                      (txdat_arb_io_out_bits_respErr),
    .io_out_bits_resp                         (txdat_arb_io_out_bits_resp),
    .io_out_bits_dataSource                   (txdat_arb_io_out_bits_dataSource),
    .io_out_bits_cBusy                        (txdat_arb_io_out_bits_cBusy),
    .io_out_bits_dbID                         (txdat_arb_io_out_bits_dbID),
    .io_out_bits_ccID                         (txdat_arb_io_out_bits_ccID),
    .io_out_bits_dataID                       (txdat_arb_io_out_bits_dataID),
    .io_out_bits_tagOp                        (txdat_arb_io_out_bits_tagOp),
    .io_out_bits_tag                          (txdat_arb_io_out_bits_tag),
    .io_out_bits_tu                           (txdat_arb_io_out_bits_tu),
    .io_out_bits_traceTag                     (txdat_arb_io_out_bits_traceTag),
    .io_out_bits_rsvdc                        (txdat_arb_io_out_bits_rsvdc),
    .io_out_bits_be                           (txdat_arb_io_out_bits_be),
    .io_out_bits_data                         (txdat_arb_io_out_bits_data),
    .io_out_bits_dataCheck                    (txdat_arb_io_out_bits_dataCheck),
    .io_out_bits_poison                       (txdat_arb_io_out_bits_poison)
  );
  Queue78_PCrdGranted pCrdQueue_s2 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_enq_ready                             (pCrdQueue_s2_io_enq_ready),
    .io_enq_valid                             (pcrdEnq_valid),
    .io_enq_bits_pCrdType                     (pcrdEnq_pCrdType),
    .io_enq_bits_srcID                        (pcrdEnq_srcID),
    .io_deq_ready                             (pCrdQueue_s3_io_enq_ready),
    .io_deq_valid                             (pCrdQueue_s2_io_deq_valid),
    .io_deq_bits_pCrdType                     (pCrdQueue_s2_io_deq_bits_pCrdType),
    .io_deq_bits_srcID                        (pCrdQueue_s2_io_deq_bits_srcID)
  );
  Queue2_PCrdGranted pCrdQueue_s3 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_enq_ready                             (pCrdQueue_s3_io_enq_ready),
    .io_enq_valid                             (pCrdQueue_s2_io_deq_valid),
    .io_enq_bits_pCrdType                     (pCrdQueue_s2_io_deq_bits_pCrdType),
    .io_enq_bits_srcID                        (pCrdQueue_s2_io_deq_bits_srcID),
    .io_deq_ready                             (pcrdgrant_arb_io_out_valid),
    .io_deq_valid                             (pCrdQueue_s3_io_deq_valid),
    .io_deq_bits_pCrdType                     (pCrdQueue_s3_io_deq_bits_pCrdType),
    .io_deq_bits_srcID                        (pCrdQueue_s3_io_deq_bits_srcID)
  );
  FastArbiter_28 pcrdgrant_arb (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_0_ready                            (pcrdgrant_arb_io_in_0_ready),
    .io_in_0_valid                            (pcrdHit[0]),
    .io_in_1_ready                            (pcrdgrant_arb_io_in_1_ready),
    .io_in_1_valid                            (pcrdHit[1]),
    .io_in_2_ready                            (pcrdgrant_arb_io_in_2_ready),
    .io_in_2_valid                            (pcrdHit[2]),
    .io_in_3_ready                            (pcrdgrant_arb_io_in_3_ready),
    .io_in_3_valid                            (pcrdHit[3]),
    .io_in_4_ready                            (pcrdgrant_arb_io_in_4_ready),
    .io_in_4_valid                            (pcrdHit[4]),
    .io_in_5_ready                            (pcrdgrant_arb_io_in_5_ready),
    .io_in_5_valid                            (pcrdHit[5]),
    .io_in_6_ready                            (pcrdgrant_arb_io_in_6_ready),
    .io_in_6_valid                            (pcrdHit[6]),
    .io_in_7_ready                            (pcrdgrant_arb_io_in_7_ready),
    .io_in_7_valid                            (pcrdHit[7]),
    .io_in_8_ready                            (pcrdgrant_arb_io_in_8_ready),
    .io_in_8_valid                            (pcrdHit[8]),
    .io_in_9_ready                            (pcrdgrant_arb_io_in_9_ready),
    .io_in_9_valid                            (pcrdHit[9]),
    .io_in_10_ready                           (pcrdgrant_arb_io_in_10_ready),
    .io_in_10_valid                           (pcrdHit[10]),
    .io_in_11_ready                           (pcrdgrant_arb_io_in_11_ready),
    .io_in_11_valid                           (pcrdHit[11]),
    .io_in_12_ready                           (pcrdgrant_arb_io_in_12_ready),
    .io_in_12_valid                           (pcrdHit[12]),
    .io_in_13_ready                           (pcrdgrant_arb_io_in_13_ready),
    .io_in_13_valid                           (pcrdHit[13]),
    .io_in_14_ready                           (pcrdgrant_arb_io_in_14_ready),
    .io_in_14_valid                           (pcrdHit[14]),
    .io_in_15_ready                           (pcrdgrant_arb_io_in_15_ready),
    .io_in_15_valid                           (pcrdHit[15]),
    .io_in_16_ready                           (pcrdgrant_arb_io_in_16_ready),
    .io_in_16_valid                           (pcrdHit[16]),
    .io_in_17_ready                           (pcrdgrant_arb_io_in_17_ready),
    .io_in_17_valid                           (pcrdHit[17]),
    .io_in_18_ready                           (pcrdgrant_arb_io_in_18_ready),
    .io_in_18_valid                           (pcrdHit[18]),
    .io_in_19_ready                           (pcrdgrant_arb_io_in_19_ready),
    .io_in_19_valid                           (pcrdHit[19]),
    .io_in_20_ready                           (pcrdgrant_arb_io_in_20_ready),
    .io_in_20_valid                           (pcrdHit[20]),
    .io_in_21_ready                           (pcrdgrant_arb_io_in_21_ready),
    .io_in_21_valid                           (pcrdHit[21]),
    .io_in_22_ready                           (pcrdgrant_arb_io_in_22_ready),
    .io_in_22_valid                           (pcrdHit[22]),
    .io_in_23_ready                           (pcrdgrant_arb_io_in_23_ready),
    .io_in_23_valid                           (pcrdHit[23]),
    .io_in_24_ready                           (pcrdgrant_arb_io_in_24_ready),
    .io_in_24_valid                           (pcrdHit[24]),
    .io_in_25_ready                           (pcrdgrant_arb_io_in_25_ready),
    .io_in_25_valid                           (pcrdHit[25]),
    .io_in_26_ready                           (pcrdgrant_arb_io_in_26_ready),
    .io_in_26_valid                           (pcrdHit[26]),
    .io_in_27_ready                           (pcrdgrant_arb_io_in_27_ready),
    .io_in_27_valid                           (pcrdHit[27]),
    .io_in_28_ready                           (pcrdgrant_arb_io_in_28_ready),
    .io_in_28_valid                           (pcrdHit[28]),
    .io_in_29_ready                           (pcrdgrant_arb_io_in_29_ready),
    .io_in_29_valid                           (pcrdHit[29]),
    .io_in_30_ready                           (pcrdgrant_arb_io_in_30_ready),
    .io_in_30_valid                           (pcrdHit[30]),
    .io_in_31_ready                           (pcrdgrant_arb_io_in_31_ready),
    .io_in_31_valid                           (pcrdHit[31]),
    .io_in_32_ready                           (pcrdgrant_arb_io_in_32_ready),
    .io_in_32_valid                           (pcrdHit[32]),
    .io_in_33_ready                           (pcrdgrant_arb_io_in_33_ready),
    .io_in_33_valid                           (pcrdHit[33]),
    .io_in_34_ready                           (pcrdgrant_arb_io_in_34_ready),
    .io_in_34_valid                           (pcrdHit[34]),
    .io_in_35_ready                           (pcrdgrant_arb_io_in_35_ready),
    .io_in_35_valid                           (pcrdHit[35]),
    .io_in_36_ready                           (pcrdgrant_arb_io_in_36_ready),
    .io_in_36_valid                           (pcrdHit[36]),
    .io_in_37_ready                           (pcrdgrant_arb_io_in_37_ready),
    .io_in_37_valid                           (pcrdHit[37]),
    .io_in_38_ready                           (pcrdgrant_arb_io_in_38_ready),
    .io_in_38_valid                           (pcrdHit[38]),
    .io_in_39_ready                           (pcrdgrant_arb_io_in_39_ready),
    .io_in_39_valid                           (pcrdHit[39]),
    .io_in_40_ready                           (pcrdgrant_arb_io_in_40_ready),
    .io_in_40_valid                           (pcrdHit[40]),
    .io_in_41_ready                           (pcrdgrant_arb_io_in_41_ready),
    .io_in_41_valid                           (pcrdHit[41]),
    .io_in_42_ready                           (pcrdgrant_arb_io_in_42_ready),
    .io_in_42_valid                           (pcrdHit[42]),
    .io_in_43_ready                           (pcrdgrant_arb_io_in_43_ready),
    .io_in_43_valid                           (pcrdHit[43]),
    .io_in_44_ready                           (pcrdgrant_arb_io_in_44_ready),
    .io_in_44_valid                           (pcrdHit[44]),
    .io_in_45_ready                           (pcrdgrant_arb_io_in_45_ready),
    .io_in_45_valid                           (pcrdHit[45]),
    .io_in_46_ready                           (pcrdgrant_arb_io_in_46_ready),
    .io_in_46_valid                           (pcrdHit[46]),
    .io_in_47_ready                           (pcrdgrant_arb_io_in_47_ready),
    .io_in_47_valid                           (pcrdHit[47]),
    .io_in_48_ready                           (pcrdgrant_arb_io_in_48_ready),
    .io_in_48_valid                           (pcrdHit[48]),
    .io_in_49_ready                           (pcrdgrant_arb_io_in_49_ready),
    .io_in_49_valid                           (pcrdHit[49]),
    .io_in_50_ready                           (pcrdgrant_arb_io_in_50_ready),
    .io_in_50_valid                           (pcrdHit[50]),
    .io_in_51_ready                           (pcrdgrant_arb_io_in_51_ready),
    .io_in_51_valid                           (pcrdHit[51]),
    .io_in_52_ready                           (pcrdgrant_arb_io_in_52_ready),
    .io_in_52_valid                           (pcrdHit[52]),
    .io_in_53_ready                           (pcrdgrant_arb_io_in_53_ready),
    .io_in_53_valid                           (pcrdHit[53]),
    .io_in_54_ready                           (pcrdgrant_arb_io_in_54_ready),
    .io_in_54_valid                           (pcrdHit[54]),
    .io_in_55_ready                           (pcrdgrant_arb_io_in_55_ready),
    .io_in_55_valid                           (pcrdHit[55]),
    .io_in_56_ready                           (pcrdgrant_arb_io_in_56_ready),
    .io_in_56_valid                           (pcrdHit[56]),
    .io_in_57_ready                           (pcrdgrant_arb_io_in_57_ready),
    .io_in_57_valid                           (pcrdHit[57]),
    .io_in_58_ready                           (pcrdgrant_arb_io_in_58_ready),
    .io_in_58_valid                           (pcrdHit[58]),
    .io_in_59_ready                           (pcrdgrant_arb_io_in_59_ready),
    .io_in_59_valid                           (pcrdHit[59]),
    .io_in_60_ready                           (pcrdgrant_arb_io_in_60_ready),
    .io_in_60_valid                           (pcrdHit[60]),
    .io_in_61_ready                           (pcrdgrant_arb_io_in_61_ready),
    .io_in_61_valid                           (pcrdHit[61]),
    .io_in_62_ready                           (pcrdgrant_arb_io_in_62_ready),
    .io_in_62_valid                           (pcrdHit[62]),
    .io_in_63_ready                           (pcrdgrant_arb_io_in_63_ready),
    .io_in_63_valid                           (pcrdHit[63]),
    .io_in_64_ready                           (pcrdgrant_arb_io_in_64_ready),
    .io_in_64_valid                           (pcrdHit[64]),
    .io_in_65_ready                           (pcrdgrant_arb_io_in_65_ready),
    .io_in_65_valid                           (pcrdHit[65]),
    .io_in_66_ready                           (pcrdgrant_arb_io_in_66_ready),
    .io_in_66_valid                           (pcrdHit[66]),
    .io_in_67_ready                           (pcrdgrant_arb_io_in_67_ready),
    .io_in_67_valid                           (pcrdHit[67]),
    .io_in_68_ready                           (pcrdgrant_arb_io_in_68_ready),
    .io_in_68_valid                           (pcrdHit[68]),
    .io_in_69_ready                           (pcrdgrant_arb_io_in_69_ready),
    .io_in_69_valid                           (pcrdHit[69]),
    .io_in_70_ready                           (pcrdgrant_arb_io_in_70_ready),
    .io_in_70_valid                           (pcrdHit[70]),
    .io_in_71_ready                           (pcrdgrant_arb_io_in_71_ready),
    .io_in_71_valid                           (pcrdHit[71]),
    .io_in_72_ready                           (pcrdgrant_arb_io_in_72_ready),
    .io_in_72_valid                           (pcrdHit[72]),
    .io_in_73_ready                           (pcrdgrant_arb_io_in_73_ready),
    .io_in_73_valid                           (pcrdHit[73]),
    .io_in_74_ready                           (pcrdgrant_arb_io_in_74_ready),
    .io_in_74_valid                           (pcrdHit[74]),
    .io_in_75_ready                           (pcrdgrant_arb_io_in_75_ready),
    .io_in_75_valid                           (pcrdHit[75]),
    .io_in_76_ready                           (pcrdgrant_arb_io_in_76_ready),
    .io_in_76_valid                           (pcrdHit[76]),
    .io_in_77_ready                           (pcrdgrant_arb_io_in_77_ready),
    .io_in_77_valid                           (pcrdHit[77]),
    .io_in_78_ready                           (pcrdgrant_arb_io_in_78_ready),
    .io_in_78_valid                           (pcrdHit[78]),
    .io_in_79_ready                           (pcrdgrant_arb_io_in_79_ready),
    .io_in_79_valid                           (pcrdHit[79]),
    .io_out_valid                             (pcrdgrant_arb_io_out_valid)
  );
  LinkMonitor linkMonitor (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_tx_req_ready                       (linkMonitor_io_in_tx_req_ready),
    .io_in_tx_req_valid                       (lm_txReqValid),
    .io_in_tx_req_bits_qos                    (txreq_arb_io_out_bits_qos),
    .io_in_tx_req_bits_tgtID                  (txreq_arb_io_out_bits_tgtID),
    .io_in_tx_req_bits_txnID                  (lm_txReqTxnID),
    .io_in_tx_req_bits_returnNID              (txreq_arb_io_out_bits_returnNID),
    .io_in_tx_req_bits_stashNIDValid          (txreq_arb_io_out_bits_stashNIDValid),
    .io_in_tx_req_bits_returnTxnID            (txreq_arb_io_out_bits_returnTxnID),
    .io_in_tx_req_bits_opcode                 (txreq_arb_io_out_bits_opcode),
    .io_in_tx_req_bits_size                   (txreq_arb_io_out_bits_size),
    .io_in_tx_req_bits_addr                   (txreq_arb_io_out_bits_addr),
    .io_in_tx_req_bits_ns                     (txreq_arb_io_out_bits_ns),
    .io_in_tx_req_bits_likelyshared           (txreq_arb_io_out_bits_likelyshared),
    .io_in_tx_req_bits_allowRetry             (txreq_arb_io_out_bits_allowRetry),
    .io_in_tx_req_bits_order                  (txreq_arb_io_out_bits_order),
    .io_in_tx_req_bits_pCrdType               (txreq_arb_io_out_bits_pCrdType),
    .io_in_tx_req_bits_memAttr_allocate       (txreq_arb_io_out_bits_memAttr_allocate),
    .io_in_tx_req_bits_memAttr_cacheable      (txreq_arb_io_out_bits_memAttr_cacheable),
    .io_in_tx_req_bits_memAttr_device         (txreq_arb_io_out_bits_memAttr_device),
    .io_in_tx_req_bits_memAttr_ewa            (txreq_arb_io_out_bits_memAttr_ewa),
    .io_in_tx_req_bits_snpAttr                (txreq_arb_io_out_bits_snpAttr),
    .io_in_tx_req_bits_lpIDWithPadding        (txreq_arb_io_out_bits_lpIDWithPadding),
    .io_in_tx_req_bits_snoopMe                (txreq_arb_io_out_bits_snoopMe),
    .io_in_tx_req_bits_expCompAck             (txreq_arb_io_out_bits_expCompAck),
    .io_in_tx_req_bits_tagOp                  (txreq_arb_io_out_bits_tagOp),
    .io_in_tx_req_bits_traceTag               (txreq_arb_io_out_bits_traceTag),
    .io_in_tx_req_bits_mpam_perfMonGroup      (txreq_arb_io_out_bits_mpam_perfMonGroup),
    .io_in_tx_req_bits_mpam_partID            (txreq_arb_io_out_bits_mpam_partID),
    .io_in_tx_req_bits_mpam_mpamNS            (txreq_arb_io_out_bits_mpam_mpamNS),
    .io_in_tx_req_bits_rsvdc                  (txreq_arb_io_out_bits_rsvdc),
    .io_in_tx_rsp_ready                       (linkMonitor_io_in_tx_rsp_ready),
    .io_in_tx_rsp_valid                       (txrsp_arb_io_out_valid),
    .io_in_tx_rsp_bits_qos                    (txrsp_arb_io_out_bits_qos),
    .io_in_tx_rsp_bits_tgtID                  (txrsp_arb_io_out_bits_tgtID),
    .io_in_tx_rsp_bits_txnID                  (txrsp_arb_io_out_bits_txnID),
    .io_in_tx_rsp_bits_opcode                 (txrsp_arb_io_out_bits_opcode),
    .io_in_tx_rsp_bits_respErr                (txrsp_arb_io_out_bits_respErr),
    .io_in_tx_rsp_bits_resp                   (txrsp_arb_io_out_bits_resp),
    .io_in_tx_rsp_bits_fwdState               (txrsp_arb_io_out_bits_fwdState),
    .io_in_tx_rsp_bits_cBusy                  (txrsp_arb_io_out_bits_cBusy),
    .io_in_tx_rsp_bits_dbID                   (txrsp_arb_io_out_bits_dbID),
    .io_in_tx_rsp_bits_pCrdType               (txrsp_arb_io_out_bits_pCrdType),
    .io_in_tx_rsp_bits_tagOp                  (txrsp_arb_io_out_bits_tagOp),
    .io_in_tx_rsp_bits_traceTag               (txrsp_arb_io_out_bits_traceTag),
    .io_in_tx_dat_ready                       (linkMonitor_io_in_tx_dat_ready),
    .io_in_tx_dat_valid                       (txdat_arb_io_out_valid),
    .io_in_tx_dat_bits_qos                    (txdat_arb_io_out_bits_qos),
    .io_in_tx_dat_bits_tgtID                  (txdat_arb_io_out_bits_tgtID),
    .io_in_tx_dat_bits_txnID                  (txdat_arb_io_out_bits_txnID),
    .io_in_tx_dat_bits_homeNID                (txdat_arb_io_out_bits_homeNID),
    .io_in_tx_dat_bits_opcode                 (txdat_arb_io_out_bits_opcode),
    .io_in_tx_dat_bits_respErr                (txdat_arb_io_out_bits_respErr),
    .io_in_tx_dat_bits_resp                   (txdat_arb_io_out_bits_resp),
    .io_in_tx_dat_bits_dataSource             (txdat_arb_io_out_bits_dataSource),
    .io_in_tx_dat_bits_cBusy                  (txdat_arb_io_out_bits_cBusy),
    .io_in_tx_dat_bits_dbID                   (txdat_arb_io_out_bits_dbID),
    .io_in_tx_dat_bits_ccID                   (txdat_arb_io_out_bits_ccID),
    .io_in_tx_dat_bits_dataID                 (txdat_arb_io_out_bits_dataID),
    .io_in_tx_dat_bits_tagOp                  (txdat_arb_io_out_bits_tagOp),
    .io_in_tx_dat_bits_tag                    (txdat_arb_io_out_bits_tag),
    .io_in_tx_dat_bits_tu                     (txdat_arb_io_out_bits_tu),
    .io_in_tx_dat_bits_traceTag               (txdat_arb_io_out_bits_traceTag),
    .io_in_tx_dat_bits_rsvdc                  (txdat_arb_io_out_bits_rsvdc),
    .io_in_tx_dat_bits_be                     (txdat_arb_io_out_bits_be),
    .io_in_tx_dat_bits_data                   (txdat_arb_io_out_bits_data),
    .io_in_tx_dat_bits_dataCheck              (txdat_arb_io_out_bits_dataCheck),
    .io_in_tx_dat_bits_poison                 (txdat_arb_io_out_bits_poison),
    .io_in_rx_rsp_ready                       (rxrspPipe_pipeline_io_in_ready),
    .io_in_rx_rsp_valid                       (linkMonitor_io_in_rx_rsp_valid),
    .io_in_rx_rsp_bits_qos                    (linkMonitor_io_in_rx_rsp_bits_qos),
    .io_in_rx_rsp_bits_tgtID                  (linkMonitor_io_in_rx_rsp_bits_tgtID),
    .io_in_rx_rsp_bits_srcID                  (linkMonitor_io_in_rx_rsp_bits_srcID),
    .io_in_rx_rsp_bits_txnID                  (linkMonitor_io_in_rx_rsp_bits_txnID),
    .io_in_rx_rsp_bits_opcode                 (linkMonitor_io_in_rx_rsp_bits_opcode),
    .io_in_rx_rsp_bits_respErr                (linkMonitor_io_in_rx_rsp_bits_respErr),
    .io_in_rx_rsp_bits_resp                   (linkMonitor_io_in_rx_rsp_bits_resp),
    .io_in_rx_rsp_bits_fwdState               (linkMonitor_io_in_rx_rsp_bits_fwdState),
    .io_in_rx_rsp_bits_cBusy                  (linkMonitor_io_in_rx_rsp_bits_cBusy),
    .io_in_rx_rsp_bits_dbID                   (linkMonitor_io_in_rx_rsp_bits_dbID),
    .io_in_rx_rsp_bits_pCrdType               (linkMonitor_io_in_rx_rsp_bits_pCrdType),
    .io_in_rx_rsp_bits_tagOp                  (linkMonitor_io_in_rx_rsp_bits_tagOp),
    .io_in_rx_rsp_bits_traceTag               (linkMonitor_io_in_rx_rsp_bits_traceTag),
    .io_in_rx_dat_ready                       (rxdatPipe_pipeline_io_in_ready),
    .io_in_rx_dat_valid                       (linkMonitor_io_in_rx_dat_valid),
    .io_in_rx_dat_bits_qos                    (linkMonitor_io_in_rx_dat_bits_qos),
    .io_in_rx_dat_bits_tgtID                  (linkMonitor_io_in_rx_dat_bits_tgtID),
    .io_in_rx_dat_bits_srcID                  (linkMonitor_io_in_rx_dat_bits_srcID),
    .io_in_rx_dat_bits_txnID                  (linkMonitor_io_in_rx_dat_bits_txnID),
    .io_in_rx_dat_bits_homeNID                (linkMonitor_io_in_rx_dat_bits_homeNID),
    .io_in_rx_dat_bits_opcode                 (linkMonitor_io_in_rx_dat_bits_opcode),
    .io_in_rx_dat_bits_respErr                (linkMonitor_io_in_rx_dat_bits_respErr),
    .io_in_rx_dat_bits_resp                   (linkMonitor_io_in_rx_dat_bits_resp),
    .io_in_rx_dat_bits_dataSource             (linkMonitor_io_in_rx_dat_bits_dataSource),
    .io_in_rx_dat_bits_cBusy                  (linkMonitor_io_in_rx_dat_bits_cBusy),
    .io_in_rx_dat_bits_dbID                   (linkMonitor_io_in_rx_dat_bits_dbID),
    .io_in_rx_dat_bits_ccID                   (linkMonitor_io_in_rx_dat_bits_ccID),
    .io_in_rx_dat_bits_dataID                 (linkMonitor_io_in_rx_dat_bits_dataID),
    .io_in_rx_dat_bits_tagOp                  (linkMonitor_io_in_rx_dat_bits_tagOp),
    .io_in_rx_dat_bits_tag                    (linkMonitor_io_in_rx_dat_bits_tag),
    .io_in_rx_dat_bits_tu                     (linkMonitor_io_in_rx_dat_bits_tu),
    .io_in_rx_dat_bits_traceTag               (linkMonitor_io_in_rx_dat_bits_traceTag),
    .io_in_rx_dat_bits_rsvdc                  (linkMonitor_io_in_rx_dat_bits_rsvdc),
    .io_in_rx_dat_bits_be                     (linkMonitor_io_in_rx_dat_bits_be),
    .io_in_rx_dat_bits_data                   (linkMonitor_io_in_rx_dat_bits_data),
    .io_in_rx_dat_bits_dataCheck              (linkMonitor_io_in_rx_dat_bits_dataCheck),
    .io_in_rx_dat_bits_poison                 (linkMonitor_io_in_rx_dat_bits_poison),
    .io_in_rx_snp_ready                       (rxSnp_ready),
    .io_in_rx_snp_valid                       (linkMonitor_io_in_rx_snp_valid),
    .io_in_rx_snp_bits_qos                    (linkMonitor_io_in_rx_snp_bits_qos),
    .io_in_rx_snp_bits_srcID                  (linkMonitor_io_in_rx_snp_bits_srcID),
    .io_in_rx_snp_bits_txnID                  (linkMonitor_io_in_rx_snp_bits_txnID),
    .io_in_rx_snp_bits_fwdNID                 (linkMonitor_io_in_rx_snp_bits_fwdNID),
    .io_in_rx_snp_bits_fwdTxnID               (linkMonitor_io_in_rx_snp_bits_fwdTxnID),
    .io_in_rx_snp_bits_opcode                 (linkMonitor_io_in_rx_snp_bits_opcode),
    .io_in_rx_snp_bits_addr                   (linkMonitor_io_in_rx_snp_bits_addr),
    .io_in_rx_snp_bits_ns                     (linkMonitor_io_in_rx_snp_bits_ns),
    .io_in_rx_snp_bits_doNotGoToSD            (linkMonitor_io_in_rx_snp_bits_doNotGoToSD),
    .io_in_rx_snp_bits_retToSrc               (linkMonitor_io_in_rx_snp_bits_retToSrc),
    .io_in_rx_snp_bits_traceTag               (linkMonitor_io_in_rx_snp_bits_traceTag),
    .io_in_rx_snp_bits_mpam_perfMonGroup      (linkMonitor_io_in_rx_snp_bits_mpam_perfMonGroup),
    .io_in_rx_snp_bits_mpam_partID            (linkMonitor_io_in_rx_snp_bits_mpam_partID),
    .io_in_rx_snp_bits_mpam_mpamNS            (linkMonitor_io_in_rx_snp_bits_mpam_mpamNS),
    .io_out_txsactive                         (io_chi_txsactive),
    .io_out_rxsactive                         (io_chi_rxsactive),
    .io_out_syscoreq                          (linkMonitor_io_out_syscoreq),
    .io_out_syscoack                          (io_chi_syscoack),
    .io_out_tx_linkactivereq                  (io_chi_tx_linkactivereq),
    .io_out_tx_linkactiveack                  (io_chi_tx_linkactiveack),
    .io_out_tx_req_flitpend                   (io_chi_tx_req_flitpend),
    .io_out_tx_req_flitv                      (io_chi_tx_req_flitv),
    .io_out_tx_req_flit                       (io_chi_tx_req_flit),
    .io_out_tx_req_lcrdv                      (io_chi_tx_req_lcrdv),
    .io_out_tx_rsp_flitpend                   (io_chi_tx_rsp_flitpend),
    .io_out_tx_rsp_flitv                      (io_chi_tx_rsp_flitv),
    .io_out_tx_rsp_flit                       (io_chi_tx_rsp_flit),
    .io_out_tx_rsp_lcrdv                      (io_chi_tx_rsp_lcrdv),
    .io_out_tx_dat_flitpend                   (io_chi_tx_dat_flitpend),
    .io_out_tx_dat_flitv                      (io_chi_tx_dat_flitv),
    .io_out_tx_dat_flit                       (io_chi_tx_dat_flit),
    .io_out_tx_dat_lcrdv                      (io_chi_tx_dat_lcrdv),
    .io_out_rx_linkactivereq                  (io_chi_rx_linkactivereq),
    .io_out_rx_linkactiveack                  (io_chi_rx_linkactiveack),
    .io_out_rx_rsp_flitpend                   (io_chi_rx_rsp_flitpend),
    .io_out_rx_rsp_flitv                      (io_chi_rx_rsp_flitv),
    .io_out_rx_rsp_flit                       (io_chi_rx_rsp_flit),
    .io_out_rx_rsp_lcrdv                      (io_chi_rx_rsp_lcrdv),
    .io_out_rx_dat_flitpend                   (io_chi_rx_dat_flitpend),
    .io_out_rx_dat_flitv                      (io_chi_rx_dat_flitv),
    .io_out_rx_dat_flit                       (io_chi_rx_dat_flit),
    .io_out_rx_dat_lcrdv                      (io_chi_rx_dat_lcrdv),
    .io_out_rx_snp_flitpend                   (io_chi_rx_snp_flitpend),
    .io_out_rx_snp_flitv                      (io_chi_rx_snp_flitv),
    .io_out_rx_snp_flit                       (io_chi_rx_snp_flit),
    .io_out_rx_snp_lcrdv                      (io_chi_rx_snp_lcrdv),
    .io_nodeID                                (io_nodeID)
  );
  Pipeline_12 rxdatPipe_pipeline (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_ready                              (rxdatPipe_pipeline_io_in_ready),
    .io_in_valid                              (linkMonitor_io_in_rx_dat_valid),
    .io_in_bits_qos                           (linkMonitor_io_in_rx_dat_bits_qos),
    .io_in_bits_tgtID                         (linkMonitor_io_in_rx_dat_bits_tgtID),
    .io_in_bits_srcID                         (linkMonitor_io_in_rx_dat_bits_srcID),
    .io_in_bits_txnID                         (linkMonitor_io_in_rx_dat_bits_txnID),
    .io_in_bits_homeNID                       (linkMonitor_io_in_rx_dat_bits_homeNID),
    .io_in_bits_opcode                        (linkMonitor_io_in_rx_dat_bits_opcode),
    .io_in_bits_respErr                       (linkMonitor_io_in_rx_dat_bits_respErr),
    .io_in_bits_resp                          (linkMonitor_io_in_rx_dat_bits_resp),
    .io_in_bits_dataSource                    (linkMonitor_io_in_rx_dat_bits_dataSource),
    .io_in_bits_cBusy                         (linkMonitor_io_in_rx_dat_bits_cBusy),
    .io_in_bits_dbID                          (linkMonitor_io_in_rx_dat_bits_dbID),
    .io_in_bits_ccID                          (linkMonitor_io_in_rx_dat_bits_ccID),
    .io_in_bits_dataID                        (linkMonitor_io_in_rx_dat_bits_dataID),
    .io_in_bits_tagOp                         (linkMonitor_io_in_rx_dat_bits_tagOp),
    .io_in_bits_tag                           (linkMonitor_io_in_rx_dat_bits_tag),
    .io_in_bits_tu                            (linkMonitor_io_in_rx_dat_bits_tu),
    .io_in_bits_traceTag                      (linkMonitor_io_in_rx_dat_bits_traceTag),
    .io_in_bits_rsvdc                         (linkMonitor_io_in_rx_dat_bits_rsvdc),
    .io_in_bits_be                            (linkMonitor_io_in_rx_dat_bits_be),
    .io_in_bits_data                          (linkMonitor_io_in_rx_dat_bits_data),
    .io_in_bits_dataCheck                     (linkMonitor_io_in_rx_dat_bits_dataCheck),
    .io_in_bits_poison                        (linkMonitor_io_in_rx_dat_bits_poison),
    .io_out_ready                             (rxDat_ready),
    .io_out_valid                             (rxdatPipe_pipeline_io_out_valid),
    .io_out_bits_qos                          (rxdatPipe_pipeline_io_out_bits_qos),
    .io_out_bits_tgtID                        (rxdatPipe_pipeline_io_out_bits_tgtID),
    .io_out_bits_srcID                        (rxdatPipe_pipeline_io_out_bits_srcID),
    .io_out_bits_txnID                        (rxdatPipe_pipeline_io_out_bits_txnID),
    .io_out_bits_homeNID                      (rxdatPipe_pipeline_io_out_bits_homeNID),
    .io_out_bits_opcode                       (rxdatPipe_pipeline_io_out_bits_opcode),
    .io_out_bits_respErr                      (rxdatPipe_pipeline_io_out_bits_respErr),
    .io_out_bits_resp                         (rxdatPipe_pipeline_io_out_bits_resp),
    .io_out_bits_dataSource                   (rxdatPipe_pipeline_io_out_bits_dataSource),
    .io_out_bits_cBusy                        (rxdatPipe_pipeline_io_out_bits_cBusy),
    .io_out_bits_dbID                         (rxdatPipe_pipeline_io_out_bits_dbID),
    .io_out_bits_ccID                         (rxdatPipe_pipeline_io_out_bits_ccID),
    .io_out_bits_dataID                       (rxdatPipe_pipeline_io_out_bits_dataID),
    .io_out_bits_tagOp                        (rxdatPipe_pipeline_io_out_bits_tagOp),
    .io_out_bits_tag                          (rxdatPipe_pipeline_io_out_bits_tag),
    .io_out_bits_tu                           (rxdatPipe_pipeline_io_out_bits_tu),
    .io_out_bits_traceTag                     (rxdatPipe_pipeline_io_out_bits_traceTag),
    .io_out_bits_rsvdc                        (rxdatPipe_pipeline_io_out_bits_rsvdc),
    .io_out_bits_be                           (rxdatPipe_pipeline_io_out_bits_be),
    .io_out_bits_data                         (rxdatPipe_pipeline_io_out_bits_data),
    .io_out_bits_dataCheck                    (rxdatPipe_pipeline_io_out_bits_dataCheck),
    .io_out_bits_poison                       (rxdatPipe_pipeline_io_out_bits_poison)
  );
  Pipeline_13 rxrspPipe_pipeline (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_ready                              (rxrspPipe_pipeline_io_in_ready),
    .io_in_valid                              (linkMonitor_io_in_rx_rsp_valid),
    .io_in_bits_qos                           (linkMonitor_io_in_rx_rsp_bits_qos),
    .io_in_bits_tgtID                         (linkMonitor_io_in_rx_rsp_bits_tgtID),
    .io_in_bits_srcID                         (linkMonitor_io_in_rx_rsp_bits_srcID),
    .io_in_bits_txnID                         (linkMonitor_io_in_rx_rsp_bits_txnID),
    .io_in_bits_opcode                        (linkMonitor_io_in_rx_rsp_bits_opcode),
    .io_in_bits_respErr                       (linkMonitor_io_in_rx_rsp_bits_respErr),
    .io_in_bits_resp                          (linkMonitor_io_in_rx_rsp_bits_resp),
    .io_in_bits_fwdState                      (linkMonitor_io_in_rx_rsp_bits_fwdState),
    .io_in_bits_cBusy                         (linkMonitor_io_in_rx_rsp_bits_cBusy),
    .io_in_bits_dbID                          (linkMonitor_io_in_rx_rsp_bits_dbID),
    .io_in_bits_pCrdType                      (linkMonitor_io_in_rx_rsp_bits_pCrdType),
    .io_in_bits_tagOp                         (linkMonitor_io_in_rx_rsp_bits_tagOp),
    .io_in_bits_traceTag                      (linkMonitor_io_in_rx_rsp_bits_traceTag),
    .io_out_ready                             (rxRsp_ready),
    .io_out_valid                             (rxrspPipe_pipeline_io_out_valid),
    .io_out_bits_qos                          (rxrspPipe_pipeline_io_out_bits_qos),
    .io_out_bits_tgtID                        (rxrspPipe_pipeline_io_out_bits_tgtID),
    .io_out_bits_srcID                        (rxrspPipe_pipeline_io_out_bits_srcID),
    .io_out_bits_txnID                        (rxrspPipe_pipeline_io_out_bits_txnID),
    .io_out_bits_opcode                       (rxrspPipe_pipeline_io_out_bits_opcode),
    .io_out_bits_respErr                      (rxrspPipe_pipeline_io_out_bits_respErr),
    .io_out_bits_resp                         (rxrspPipe_pipeline_io_out_bits_resp),
    .io_out_bits_fwdState                     (rxrspPipe_pipeline_io_out_bits_fwdState),
    .io_out_bits_cBusy                        (rxrspPipe_pipeline_io_out_bits_cBusy),
    .io_out_bits_dbID                         (rxrspPipe_pipeline_io_out_bits_dbID),
    .io_out_bits_pCrdType                     (rxrspPipe_pipeline_io_out_bits_pCrdType),
    .io_out_bits_tagOp                        (rxrspPipe_pipeline_io_out_bits_tagOp),
    .io_out_bits_traceTag                     (rxrspPipe_pipeline_io_out_bits_traceTag)
  );

  // ---- 顶层输出 ----
  assign auto_in_3_b_bits_address = in_bAddr[3];
  assign auto_in_3_d_valid = in_dValid[3];
  assign auto_in_3_d_bits_opcode = slices_3_io_in_d_bits_opcode;
  assign auto_in_3_d_bits_source = slices_3_io_in_d_bits_source;
  assign auto_in_2_b_bits_address = in_bAddr[2];
  assign auto_in_2_d_valid = in_dValid[2];
  assign auto_in_2_d_bits_opcode = slices_2_io_in_d_bits_opcode;
  assign auto_in_2_d_bits_source = slices_2_io_in_d_bits_source;
  assign auto_in_1_b_bits_address = in_bAddr[1];
  assign auto_in_1_d_valid = in_dValid[1];
  assign auto_in_1_d_bits_opcode = slices_1_io_in_d_bits_opcode;
  assign auto_in_1_d_bits_source = slices_1_io_in_d_bits_source;
  assign auto_in_0_b_bits_address = in_bAddr[0];
  assign auto_in_0_d_valid = in_dValid[0];
  assign auto_in_0_d_bits_opcode = slices_0_io_in_d_bits_opcode;
  assign auto_in_0_d_bits_source = slices_0_io_in_d_bits_source;
  assign io_l2_hint_valid = hintFire;
  assign io_l2_hint_bits_sourceId = l1HintArb_io_out_bits_sourceId;
  assign io_debugTopDown_l2MissMatch = topDown_io_debugTopDown_l2MissMatch;
  assign io_l2Miss = l2Miss;
  assign io_error_valid = errorValid;
  assign io_perf_1_value = perf[0];
  assign io_perf_2_value = perf[1];
  assign io_perf_3_value = perf[2];
  assign io_perf_4_value = perf[3];
  assign io_perf_5_value = perf[4];
  assign io_perf_6_value = perf[5];
  assign io_perf_7_value = perf[6];
  assign io_perf_8_value = perf[7];
  assign io_perf_9_value = perf[8];
  assign io_perf_10_value = perf[9];
  assign io_perf_11_value = perf[10];
  assign io_perf_12_value = perf[11];
  assign io_perf_13_value = perf[12];
  assign io_perf_14_value = perf[13];
  assign io_perf_15_value = perf[14];
  assign io_perf_16_value = perf[15];
  assign io_perf_17_value = perf[16];
  assign io_perf_18_value = perf[17];
  assign io_perf_19_value = perf[18];
  assign io_perf_20_value = perf[19];
  assign io_perf_21_value = perf[20];
  assign io_perf_22_value = perf[21];
  assign io_perf_23_value = perf[22];
  assign io_perf_24_value = perf[23];
  assign io_perf_25_value = perf[24];
  assign io_perf_26_value = perf[25];
  assign io_perf_27_value = perf[26];
  assign io_perf_28_value = perf[27];
  assign io_perf_29_value = perf[28];
  assign io_perf_30_value = perf[29];
  assign io_perf_31_value = perf[30];
  assign io_perf_32_value = perf[31];
  assign io_perf_33_value = perf[32];
  assign io_perf_34_value = perf[33];
  assign io_perf_35_value = perf[34];
  assign io_perf_36_value = perf[35];
  assign io_perf_37_value = perf[36];
  assign io_perf_38_value = perf[37];
  assign io_perf_39_value = perf[38];
  assign io_perf_40_value = perf[39];
  assign io_perf_41_value = perf[40];
  assign io_perf_42_value = perf[41];
  assign io_perf_43_value = perf[42];
  assign io_perf_44_value = perf[43];
  assign io_perf_45_value = perf[44];
  assign io_perf_46_value = perf[45];
  assign io_perf_47_value = perf[46];
  assign io_perf_48_value = perf[47];
  assign io_perf_49_value = perf[48];
  assign io_perf_50_value = perf[49];
  assign io_perf_51_value = perf[50];
  assign io_perf_52_value = perf[51];
  assign io_perf_53_value = perf[52];
  assign io_perf_54_value = perf[53];
  assign io_perf_55_value = perf[54];
  assign io_perf_56_value = perf[55];
  assign io_perf_57_value = perf[56];
  assign io_perf_58_value = perf[57];
  assign io_perf_59_value = perf[58];
  assign io_perf_60_value = perf[59];
  assign io_perf_61_value = perf[60];
  assign io_perf_62_value = perf[61];
  assign io_perf_63_value = perf[62];
  assign io_perf_64_value = perf[63];
  assign io_perf_65_value = perf[64];
  assign io_perf_66_value = perf[65];
  assign io_perf_67_value = perf[66];
  assign io_perf_68_value = perf[67];
  assign io_chi_syscoreq = linkMonitor_io_out_syscoreq;

endmodule
// END GENERATED
