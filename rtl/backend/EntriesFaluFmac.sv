// =============================================================================
// xs_EntriesFaluFmac_core —— 香山 V2R2(昆明湖) 发射队列条目阵列 可读重写
//                            (FaluFmac 变体, hasCompAndSimp 路)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/Entries.scala
// golden 对照:EntriesFaluFmac.sv(例化 2×EnqEntry_12 + 2×OthersEntry_120(simp)
//             + 14×OthersEntry_122(comp) + 2×EnqPolicy_8(simp/comp 转移策略))
//
// ★ 本模块 = 条目阵列 + 转移策略(transfer policy) + 年龄最老选择(oldest mux)★
// 单条目「唤醒-选择」逻辑全在 xs_iq_entry_ffmac(IqEntryFfmac.sv)里;本层做:
//   1) 例化 18 个单条目(genvar):2 enq(IS_ENQ) + 2 simp + 14 comp(IS_COMP)。
//   2) 转移策略(EntryBundles 的 hasCompAndSimp 分支),与样板 AluCsrFenceDiv 同构。
//   3) 年龄最老选择:上层 IQ 的 AgeDetector 给出各组每个 deq 端口的 oldest one-hot,
//      comp 命中优先于 simp 优先于 enq(三级 Mux)。本变体 numDeq=1。
//   4) 阵列状态汇聚:valid/issued/canIssue/fuType/dataSources/exuSources。
//      ★ 本变体无 loadDependency 输出 ★(浮点 IQ 无 load 依赖)。
//
// ★ 与样板 AluCsrFenceDiv 的差异 ★
//   * numEntries 18(2/2/14)、numDeq 1(单端口)、numRegSrc 3。
//   * 无 loadDependency / ldCancel / RegCache / og1/og2 双端口 → 无 §样板里的 enq 延迟
//     load 流水寄存器、无 og0/ld delay 管线。enqDelay 仅 1 级(delay1),只需把当拍
//     wakeUp 总线打 1 拍(wk_*_d)喂给 EnqEntry,以及 og0Cancel 打 1 拍。
//   * issueResp:单端口,resp = _GEN[issueTimer]('{0,0,SUCCESS,0}:仅 timer1→success),
//     valid = (timer0→og0Resp.valid, timer1→og1Resp.valid, else 0)。og0/og1Resp.bits 不消费。
//
// X 铁律:Mux1H/oldest 选择用「sel[i] ? entry[i] : 0」累加(OR),sel 为 0 时不引 X。
// =============================================================================
module xs_EntriesFaluFmac_core import iq_ffmac_pkg::*; (
  input  logic clock,
  input  logic reset,

  // ---- flush / enq ----
  input  logic                 flush_valid,
  input  logic                 flush_rob_flag,
  input  logic [ROB_PTR_W-1:0] flush_rob_value,
  input  logic                 flush_level,
  input  logic [NUM_ENQ-1:0]   enq_valid,
  input  entry_t [NUM_ENQ-1:0] enq_bits,

  // ---- 唤醒(当拍 + 入队延迟 1)----
  input  wk_wb_t [NUM_WK_WB-1:0] wk_wb,
  input  wk_iq_t [NUM_WK_IQ-1:0] wk_iq,
  input  wk_wb_t [NUM_WK_WB-1:0] wk_wb_d,   // wakeUpFromWBDelayed
  input  wk_iq_t [NUM_WK_IQ-1:0] wk_iq_d,   // wakeUpFromIQDelayed

  // ---- 取消(本变体仅 og0Cancel[8] 被用)----
  input  logic [NUM_EXU-1:0]    og0cancel,

  // ---- 发射响应(og0/og1, 单 deq 端口;仅用 valid)----
  input  logic                  og0resp_valid,
  input  logic                  og1resp_valid,

  // ---- 发射选择 ----
  input  logic                                deq_sel_oh_valid,
  input  logic [NUM_ENTRIES-1:0]              deq_sel_oh_bits,
  input  logic [NUM_ENQ-1:0]                  enq_oldest_sel_bits,
  input  logic                                simp_oldest_sel_valid,
  input  logic [NUM_SIMP-1:0]                 simp_oldest_sel_bits,
  input  logic                                comp_oldest_sel_valid,
  input  logic [NUM_COMP-1:0]                 comp_oldest_sel_bits,

  // ---- 转移:simp→comp 的 deq 选择(上层 IQ 给)----
  input  logic [NUM_ENQ-1:0][NUM_SIMP-1:0]    simp_deq_sel_vec,

  // ---- 阵列状态输出 ----
  output logic [NUM_ENTRIES-1:0]                       o_valid,
  output logic [NUM_ENTRIES-1:0]                       o_issued,
  output logic [NUM_ENTRIES-1:0]                       o_can_issue,
  output logic [NUM_ENTRIES-1:0][FU_NUM-1:0]           o_fu_type,
  output logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][3:0]  o_data_sources,
  output logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][EXU_SRC_W-1:0] o_exu_sources,

  // ---- deq 出口(单 deq 端口的最老条目)----
  output entry_t o_deq_entry,
  output logic   o_cancel_deq,

  // ---- 转移选择输出(给上层 IQ 做 NewAgeDetector 入队登记)----
  output logic [NUM_ENQ-1:0][NUM_SIMP-1:0] o_simp_enq_sel_vec,
  output logic [NUM_ENQ-1:0][NUM_COMP-1:0] o_comp_enq_sel_vec
);

  // ===========================================================================
  // 0. 条目分区:索引 [0..1]=enq, [2..3]=simp(2), [4..17]=comp(14)
  // ===========================================================================
  localparam int SIMP_BASE = NUM_ENQ;                 // 2
  localparam int COMP_BASE = NUM_ENQ + NUM_SIMP;      // 4

  // 每个条目的输出线
  logic [NUM_ENTRIES-1:0]                      ety_valid;
  logic [NUM_ENTRIES-1:0]                      ety_issued;
  logic [NUM_ENTRIES-1:0]                      ety_can_issue;
  logic [NUM_ENTRIES-1:0][FU_NUM-1:0]          ety_fu_type;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][3:0] ety_data_src;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][EXU_SRC_W-1:0] ety_exu_src;
  entry_t [NUM_ENTRIES-1:0]                    ety_entry;       // commonOut.entry.bits
  entry_t [NUM_ENTRIES-1:0]                    ety_trans_entry; // commonOut.transEntry.bits
  logic [NUM_ENTRIES-1:0]                      ety_trans_valid;
  logic [NUM_ENTRIES-1:0][1:0]                 ety_issue_timer;
  logic [NUM_ENTRIES-1:0]                      ety_enq_ready;

  // 每个条目的输入线
  logic   [NUM_ENTRIES-1:0]      ety_enq_valid;
  entry_t [NUM_ENTRIES-1:0]      ety_enq_bits;
  logic   [NUM_ENTRIES-1:0]      ety_deq_sel;
  deq_resp_t [NUM_ENTRIES-1:0]   ety_issue_resp;
  logic   [NUM_ENTRIES-1:0]      ety_trans_sel;

  // validForTrans
  logic [NUM_ENTRIES-1:0]        valid_for_trans; // valid && !issued

  // ===========================================================================
  // 1. issueRespVec:resps(issueTimer)。本变体 numDeq=1,无 og2Resp。
  //    golden:resp = _GEN[issueTimer],_GEN='{0,0,SUCCESS,0} → 仅 timer1=SUCCESS,其余 BLOCK。
  //          valid = _GEN_14[issueTimer],_GEN_14={0,0,og1Resp.valid,og0Resp.valid}
  //                → timer0=og0Resp.valid,timer1=og1Resp.valid,timer2/3=0。
  //    og0/og1Resp.bits 不消费(条目 deqSuccess 只看 valid + resp)。
  // ===========================================================================
  always_comb begin
    for (int e = 0; e < NUM_ENTRIES; e++) begin
      logic [1:0] tmr;
      logic       v;
      resp_type_e r;
      tmr = ety_issue_timer[e];
      v = 1'b0; r = RESP_BLOCK;
      if (tmr == 2'h0) begin
        v = og0resp_valid;
        r = RESP_BLOCK;
      end else if (tmr == 2'h1) begin
        v = og1resp_valid;
        r = RESP_SUCCESS;
      end
      ety_issue_resp[e].valid     = v;
      ety_issue_resp[e].resp      = r;
      ety_issue_resp[e].rob_flag  = 1'b0;
      ety_issue_resp[e].rob_value = '0;
      ety_issue_resp[e].fu_type   = '0;
    end
  end

  // ===========================================================================
  // 2. deqSel:某条目被 deq 端口选中(deqSelOH.valid && bits[e])。本变体 deqReady 折叠为 1。
  // ===========================================================================
  always_comb
    for (int e = 0; e < NUM_ENTRIES; e++)
      ety_deq_sel[e] = deq_sel_oh_valid & deq_sel_oh_bits[e];

  // ===========================================================================
  // 3. 转移策略(hasCompAndSimp 分支, 见 Entries.scala 203-264)
  // ===========================================================================
  logic [NUM_SIMP-1:0] simp_enq_ready;
  logic [NUM_COMP-1:0] comp_enq_ready;
  always_comb begin
    for (int i = 0; i < NUM_SIMP; i++) simp_enq_ready[i] = ety_enq_ready[SIMP_BASE + i];
    for (int i = 0; i < NUM_COMP; i++) comp_enq_ready[i] = ety_enq_ready[COMP_BASE + i];
  end

  // EnqPolicy 黑盒输入 canEnq(16 位):simp 用 simp_enq_ready(高位补 0),
  // comp 用「comp 条目 !valid」(高位补 0)。golden EnqPolicy_8 的 io_canEnq 宽 16(=numOthers)。
  logic [15:0] simp_can_enq, comp_can_enq;
  always_comb begin
    simp_can_enq = '0;
    simp_can_enq[NUM_SIMP-1:0] = simp_enq_ready;
    comp_can_enq = '0;
    for (int i = 0; i < NUM_COMP; i++) comp_can_enq[i] = ~ety_valid[COMP_BASE + i];
  end

  logic        simp_sel0_valid, simp_sel1_valid;
  logic [15:0] simp_sel0_bits,  simp_sel1_bits;
  logic        comp_sel0_valid, comp_sel1_valid;
  logic [15:0] comp_sel0_bits,  comp_sel1_bits;

  EnqPolicy_8 u_simp_trans_policy (
    .io_canEnq             (simp_can_enq),
    .io_enqSelOHVec_0_valid(simp_sel0_valid),
    .io_enqSelOHVec_0_bits (simp_sel0_bits),
    .io_enqSelOHVec_1_valid(simp_sel1_valid),
    .io_enqSelOHVec_1_bits (simp_sel1_bits)
  );
  EnqPolicy_8 u_comp_trans_policy (
    .io_canEnq             (comp_can_enq),
    .io_enqSelOHVec_0_valid(comp_sel0_valid),
    .io_enqSelOHVec_0_bits (comp_sel0_bits),
    .io_enqSelOHVec_1_valid(comp_sel1_valid),
    .io_enqSelOHVec_1_bits (comp_sel1_bits)
  );

  // enq 有效数 / 空 comp 数 / simp 是否任一 valid / 空 simp 数
  int unsigned n_enq_valid, n_comp_empty, n_simp_ready;
  logic        simp_any_valid;
  always_comb begin
    n_enq_valid    = ety_valid[0] + ety_valid[1];
    n_comp_empty   = 0;
    // 注:~ 是上下文定宽运算符,在 32 位加法上下文里会按 32 位取反导致下溢。
    //     要的是"该 comp 条目是否为空"的 1 位量,必须用逻辑非 !(单比特)累加。
    for (int i = 0; i < NUM_COMP; i++) n_comp_empty += !ety_valid[COMP_BASE + i];
    n_simp_ready   = 0;
    for (int i = 0; i < NUM_SIMP; i++) n_simp_ready += simp_enq_ready[i];
    simp_any_valid = |ety_valid[COMP_BASE-1:SIMP_BASE]; // simp 区任一 valid
  end

  logic enq_can_trans2comp, enq_can_trans2simp;
  logic [NUM_ENQ-1:0] simp_can_trans2comp;
  always_comb begin
    enq_can_trans2comp = (n_enq_valid <= n_comp_empty) & ~simp_any_valid;
    enq_can_trans2simp = ~enq_can_trans2comp & (n_enq_valid <= n_simp_ready);
    for (int i = 0; i < NUM_ENQ; i++)
      simp_can_trans2comp[i] = ~enq_can_trans2comp & (n_comp_empty >= (i + 1));
  end

  // validForTrans[entry]
  always_comb
    for (int e = 0; e < NUM_ENTRIES; e++)
      valid_for_trans[e] = ety_valid[e] & ~ety_issued[e];

  // simp/compTransSelVec(0/1):带 validForTrans gate,enq[1] 在 enq[0] 无效时复用 sel0。
  logic        simp_tsel0_valid, simp_tsel1_valid, comp_tsel0_valid, comp_tsel1_valid;
  logic [15:0] simp_tsel1_src_bits, comp_tsel1_src_bits;
  always_comb begin
    simp_tsel0_valid = simp_sel0_valid & valid_for_trans[0];
    comp_tsel0_valid = comp_sel0_valid & valid_for_trans[0];
    simp_tsel1_valid = (~valid_for_trans[0] ? simp_sel0_valid : simp_sel1_valid) & valid_for_trans[1];
    comp_tsel1_valid = (~valid_for_trans[0] ? comp_sel0_valid : comp_sel1_valid) & valid_for_trans[1];
    simp_tsel1_src_bits = ~valid_for_trans[0] ? simp_sel0_bits : simp_sel1_bits;
    comp_tsel1_src_bits = ~valid_for_trans[0] ? comp_sel0_bits : comp_sel1_bits;
  end

  // finalSimpTransSelVec(enq):enqCanTrans2Simp && selValid → 取 selOH(低 NUM_SIMP 位)
  logic [NUM_ENQ-1:0][NUM_SIMP-1:0] final_simp_trans_sel;
  always_comb begin
    final_simp_trans_sel[0] = {NUM_SIMP{enq_can_trans2simp & simp_tsel0_valid}} & simp_sel0_bits[NUM_SIMP-1:0];
    final_simp_trans_sel[1] = {NUM_SIMP{enq_can_trans2simp & simp_tsel1_valid}} & simp_tsel1_src_bits[NUM_SIMP-1:0];
  end
  // finalCompTransSelVec(enq):enqCanTrans2Comp ? (selValid?selOH) : (origSelOH)
  logic [NUM_ENQ-1:0][NUM_COMP-1:0] final_comp_trans_sel;
  always_comb begin
    final_comp_trans_sel[0] = enq_can_trans2comp
      ? ({NUM_COMP{comp_tsel0_valid}} & comp_sel0_bits[NUM_COMP-1:0])
      : ({NUM_COMP{comp_sel0_valid}}  & comp_sel0_bits[NUM_COMP-1:0]);
    final_comp_trans_sel[1] = enq_can_trans2comp
      ? ({NUM_COMP{comp_tsel1_valid}} & comp_tsel1_src_bits[NUM_COMP-1:0])
      : ({NUM_COMP{comp_sel1_valid}}  & comp_sel1_bits[NUM_COMP-1:0]);
  end

  // enq / simp 条目的 transEntry(出队携带)
  entry_t [NUM_ENQ-1:0]  enq_trans_entry;
  logic   [NUM_ENQ-1:0]  enq_trans_valid;
  entry_t [NUM_SIMP-1:0] simp_trans_entry;
  logic   [NUM_SIMP-1:0] simp_trans_valid;
  always_comb begin
    for (int i = 0; i < NUM_ENQ; i++) begin
      enq_trans_entry[i] = ety_trans_entry[i];
      enq_trans_valid[i] = ety_trans_valid[i];
    end
    for (int i = 0; i < NUM_SIMP; i++) begin
      simp_trans_entry[i] = ety_trans_entry[SIMP_BASE + i];
      simp_trans_valid[i] = ety_trans_valid[SIMP_BASE + i];
    end
  end

  // simpEntryEnq[simpIdx]:由 finalSimpTransSel one-hot(over enq)选出 enqEntryTransVec
  entry_t [NUM_SIMP-1:0] simp_entry_enq;
  logic   [NUM_SIMP-1:0] simp_entry_enq_valid;
  always_comb begin
    for (int s = 0; s < NUM_SIMP; s++) begin
      entry_t acc; logic accv;
      acc = '0; accv = 1'b0;
      for (int q = 0; q < NUM_ENQ; q++)
        if (final_simp_trans_sel[q][s]) begin
          acc  |= enq_trans_entry[q];
          accv |= enq_trans_valid[q];
        end
      simp_entry_enq[s]       = acc;
      simp_entry_enq_valid[s] = accv;
    end
  end

  // compEnqVec[enqIdx]:enqCanTrans2Comp ? enqEntryTransVec : Mux1H(simpDeqSel, simpTransVec)
  entry_t [NUM_ENQ-1:0] comp_enq_src;
  logic   [NUM_ENQ-1:0] comp_enq_src_valid;
  always_comb begin
    for (int q = 0; q < NUM_ENQ; q++) begin
      entry_t mux_simp; logic mux_simp_v;
      mux_simp = '0; mux_simp_v = 1'b0;
      for (int s = 0; s < NUM_SIMP; s++)
        if (simp_deq_sel_vec[q][s]) begin
          mux_simp   |= simp_trans_entry[s];
          mux_simp_v |= simp_trans_valid[s];
        end
      comp_enq_src[q]       = enq_can_trans2comp ? enq_trans_entry[q] : mux_simp;
      comp_enq_src_valid[q] = enq_can_trans2comp ? enq_trans_valid[q] : mux_simp_v;
    end
  end

  // compEntryEnq[compIdx]:由 finalCompTransSel one-hot(over enq)选出 compEnqVec
  entry_t [NUM_COMP-1:0] comp_entry_enq;
  logic   [NUM_COMP-1:0] comp_entry_enq_valid;
  always_comb begin
    for (int c = 0; c < NUM_COMP; c++) begin
      entry_t acc; logic accv;
      acc = '0; accv = 1'b0;
      for (int q = 0; q < NUM_ENQ; q++)
        if (final_comp_trans_sel[q][c]) begin
          acc  |= comp_enq_src[q];
          accv |= comp_enq_src_valid[q];
        end
      comp_entry_enq[c]       = acc;
      comp_entry_enq_valid[c] = accv;
    end
  end

  // ===========================================================================
  // 4. 每个条目的 enq / transSel 输入装配
  // ===========================================================================
  always_comb begin
    // enq 条目:外部 enq
    for (int q = 0; q < NUM_ENQ; q++) begin
      ety_enq_valid[q] = enq_valid[q];
      ety_enq_bits[q]  = enq_bits[q];
      ety_trans_sel[q] = (enq_can_trans2simp & (q==0 ? simp_tsel0_valid : simp_tsel1_valid))
                       | (enq_can_trans2comp & (q==0 ? comp_tsel0_valid : comp_tsel1_valid));
    end
    // simp 条目:enq=simpEntryEnq, transSel=被提级到 comp
    for (int s = 0; s < NUM_SIMP; s++) begin
      logic tsel;
      ety_enq_valid[SIMP_BASE + s] = simp_entry_enq_valid[s];
      ety_enq_bits[SIMP_BASE + s]  = simp_entry_enq[s];
      tsel = 1'b0;
      for (int q = 0; q < NUM_ENQ; q++)
        tsel |= simp_deq_sel_vec[q][s] & simp_can_trans2comp[q];
      ety_trans_sel[SIMP_BASE + s] = tsel;
    end
    // comp 条目:enq=compEntryEnq, 无 transSel
    for (int c = 0; c < NUM_COMP; c++) begin
      ety_enq_valid[COMP_BASE + c] = comp_entry_enq_valid[c];
      ety_enq_bits[COMP_BASE + c]  = comp_entry_enq[c];
      ety_trans_sel[COMP_BASE + c] = 1'b0;
    end
  end

  // ===========================================================================
  // 5. 例化 18 个单条目
  //    enq 延迟唤醒:本变体仅需把当拍 wakeUp 总线打 1 拍(由顶层 IQ 已提供 wk_*_d),
  //    以及 og0Cancel 打 1 拍(此处生成 og0_d1)。无 load 流水寄存器。
  // ===========================================================================
  // golden 只有 io_og0Cancel_8:唯一被引用的 og0Cancel EXU 槽是 OG0_EXU=8,其余 EXU 的
  // og0Cancel 母线恒 0。故只把 EXU 8 那一位打 1 拍存储,再重构成核所需的 NUM_EXU 位母线
  // (其余位恒 0),避免存 26 个恒 0 的死寄存器。语义(打拍/无复位/每拍更新)与原完全一致。
  localparam int OG0_EXU = 8;
  logic og0_d1_kept;
  always_ff @(posedge clock) og0_d1_kept <= og0cancel[OG0_EXU];
  logic [NUM_EXU-1:0] og0_d1;
  always_comb begin
    og0_d1 = '0;
    og0_d1[OG0_EXU] = og0_d1_kept;
  end

  genvar e;
  generate
    for (e = 0; e < NUM_ENTRIES; e++) begin : g_entry
      // enq 条目在 Entries.scala 里以 isComp=true 例化(EnqEntry(isComp=true))。
      localparam bit IS_ENQ_E  = (e < NUM_ENQ);
      localparam bit IS_COMP_E = (e < NUM_ENQ) || (e >= COMP_BASE);

      xs_iq_entry_ffmac #(.IS_ENQ(IS_ENQ_E), .IS_COMP(IS_COMP_E)) u_ety (
        .clock          (clock),
        .reset          (reset),
        .flush_valid    (flush_valid),
        .flush_rob_flag (flush_rob_flag),
        .flush_rob_value(flush_rob_value),
        .flush_level    (flush_level),
        .enq_valid      (ety_enq_valid[e]),
        .enq_bits       (ety_enq_bits[e]),
        .wk_wb          (wk_wb),
        .wk_iq          (wk_iq),
        .wk_wb_d1       (wk_wb_d),
        .wk_iq_d1       (wk_iq_d),
        .enqd1_og0cancel(og0_d1),
        .og0cancel      (og0cancel),
        .deq_sel        (ety_deq_sel[e]),
        .issue_resp     (ety_issue_resp[e]),
        .trans_sel      (ety_trans_sel[e]),
        .o_valid        (ety_valid[e]),
        .o_issued       (ety_issued[e]),
        .o_can_issue    (ety_can_issue[e]),
        .o_fu_type      (ety_fu_type[e]),
        .o_data_src     (ety_data_src[e]),
        .o_exu_src      (ety_exu_src[e]),
        .o_entry        (ety_entry[e]),
        .o_deq_valid    (),
        .o_issue_timer_read(ety_issue_timer[e]),
        .o_enq_ready    (ety_enq_ready[e]),
        .o_trans_valid  (ety_trans_valid[e]),
        .o_trans_entry  (ety_trans_entry[e])
      );
    end
  endgenerate

  // ===========================================================================
  // 6. 阵列状态汇聚输出(本变体无 loadDependency)
  // ===========================================================================
  always_comb begin
    for (int i = 0; i < NUM_ENTRIES; i++) begin
      o_valid[i]        = ety_valid[i];
      o_issued[i]       = ety_issued[i];
      o_can_issue[i]    = ety_can_issue[i];
      o_fu_type[i]      = ety_fu_type[i];
      o_data_sources[i] = ety_data_src[i];
      o_exu_sources[i]  = ety_exu_src[i];
    end
  end

  // ===========================================================================
  // 7. 年龄最老选择(oldest mux) + deqEntry 三级选择(numDeq=1)
  //    deqEntry = compSel.valid ? compOldest : (simpSel.valid ? simpOldest : enqOldest)
  //    cancelDeqVec:本变体单条目无 cancelBypass(无 load 取消),恒 0。
  // ===========================================================================
  always_comb begin
    entry_t enq_oldest, simp_oldest, comp_oldest;
    enq_oldest = '0; simp_oldest = '0; comp_oldest = '0;
    for (int i = 0; i < NUM_ENQ; i++)
      if (enq_oldest_sel_bits[i]) enq_oldest |= ety_entry[i];
    for (int i = 0; i < NUM_SIMP; i++)
      if (simp_oldest_sel_bits[i]) simp_oldest |= ety_entry[SIMP_BASE + i];
    for (int i = 0; i < NUM_COMP; i++)
      if (comp_oldest_sel_bits[i]) comp_oldest |= ety_entry[COMP_BASE + i];
    o_deq_entry = comp_oldest_sel_valid ? comp_oldest
                : (simp_oldest_sel_valid ? simp_oldest : enq_oldest);
    o_cancel_deq = 1'b0;
  end

  // ===========================================================================
  // 8. 转移选择输出(给上层 IQ 登记新条目年龄)
  // ===========================================================================
  always_comb begin
    for (int q = 0; q < NUM_ENQ; q++) begin
      o_simp_enq_sel_vec[q] = final_simp_trans_sel[q] & {NUM_SIMP{enq_trans_valid[q]}};
      o_comp_enq_sel_vec[q] = final_comp_trans_sel[q] & {NUM_COMP{comp_enq_src_valid[q]}};
    end
  end

endmodule
