// =============================================================================
// xs_EntriesVlduVstu_core —— 香山 V2R2(昆明湖) 发射队列条目阵列 可读重写
//                            (VlduVstu 变体, hasCompAndSimp 路)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/Entries.scala
// golden 对照:EntriesVlduVstu.sv(例化 2×EnqEntryVecMem_2 + 2×OthersEntryVecMem_14(simp)
//             + 12×OthersEntryVecMem_16(comp) + 2×EnqPolicy_14(simp/comp 转移策略))
//
// ★ 本模块 = 条目阵列 + 转移策略 + 年龄最老选择 + ★mem 响应折算★ ★
// 单条目「唤醒-选择」逻辑全在 xs_iq_entry_vlduvstu(IqEntryVlduVstu.sv);本层做:
//   1) 例化 16 个单条目:2 enq + 2 simp + 12 comp。
//   2) ★ mem 响应折算(本变体核心,见 §1)★:把 og0/1/2Resp(timer 窗口)与三路按
//      {sqIdx,lqIdx} 匹配的 mem 响应(vecLdIn.resp / fromMem.slowResp / vecLdIn.finalIssueResp)
//      折算成每条目的 issueResp。
//   3) 转移策略(hasCompAndSimp 分支):simp 为转移源,提级到 comp(结构同 VfDiv)。
//   4) 年龄最老选择(numDeq=1):comp 优先于 simp 优先于 enq(三级 Mux)。
//   5) 阵列状态汇聚:valid/issued/canIssue/fuType/dataSources;deqEntry 三级最老选择。
//
// ★ 与向量样板(EntriesVfdivVidiv)的差异 ★
//   * numEntries 10→16(2/2/12);numOthers 8→14。
//   * issueResp 折算多了「issueTimer 饱和(b11)窗口的三路 mem 响应按索引匹配」:
//       timer0→og0(BLOCK), timer1→og1(UNCERTAIN), timer2→og2(og2.resp),
//       timer3→ (hitResp0|hitResp1|hitResp2),resp = 命中路 resp 的 OR。
//     —— VfDiv 是 timer2 出 og2 真响应、timer3 给 0;本变体把真正的「成功/重发」推迟到
//        饱和窗口由按索引匹配的 mem 响应给出(向量访存长延迟)。
//   * 透传 lqDeqPtr 给各条目做 blocked 重算。
//
// X 铁律:oldest / Mux1H 用「sel[i] ? entry[i] : 0」OR 累加,sel=0 不引 X。
// =============================================================================
module xs_EntriesVlduVstu_core import iq_vlduvstu_pkg::*; (
  input  logic clock,
  input  logic reset,

  // ---- flush / enq ----
  input  logic                 flush_valid,
  input  logic                 flush_rob_flag,
  input  logic [ROB_PTR_W-1:0] flush_rob_value,
  input  logic                 flush_level,
  input  logic [NUM_ENQ-1:0]   enq_valid,
  input  entry_t [NUM_ENQ-1:0] enq_bits,

  // ---- WB 唤醒(当拍 + 入队延迟 1)----
  input  wk_wb_t [NUM_WK_WB-1:0] wk_wb,
  input  wk_wb_t [NUM_WK_WB-1:0] wk_wb_d,   // wakeUpFromWBDelayed

  // ---- vl 信息(ignoreOldVd)----
  input  vl_info_t               vl_info,

  // ---- og 响应(单 deq 端口,timer 窗口)----
  input  logic                   og0resp_valid,
  input  logic                   og1resp_valid,
  input  logic                   og2resp_valid,
  input  logic [1:0]             og2resp_resp,

  // ---- ★ 三路按索引匹配的 mem 响应(timer 饱和窗口)★ ----
  input  mem_resp_t              vecld_resp,         // vecLdIn.resp(向量 load 发射响应)
  input  mem_resp_t              frommem_slow_resp,  // fromMem.slowResp(慢响应)
  input  mem_resp_t              vecld_final_resp,   // vecLdIn.finalIssueResp(最终发射响应)

  // ---- 向量访存:LoadQueue 出队指针(透传给条目做 blocked)----
  input  logic                   lq_deq_ptr_flag,
  input  logic [LQ_PTR_W-1:0]    lq_deq_ptr_value,

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

  // ---- deq 出口(单 deq 端口的最老条目)----
  output entry_t o_deq_entry,

  // ---- 转移选择输出(给上层 IQ 做年龄登记)----
  output logic [NUM_ENQ-1:0][NUM_SIMP-1:0] o_simp_enq_sel_vec,
  output logic [NUM_ENQ-1:0][NUM_COMP-1:0] o_comp_enq_sel_vec
);

  // ===========================================================================
  // 0. 条目分区:索引 [0..1]=enq, [2..3]=simp(2), [4..15]=comp(12)
  // ===========================================================================
  localparam int SIMP_BASE = NUM_ENQ;            // 2
  localparam int COMP_BASE = NUM_ENQ + NUM_SIMP; // 4

  // 每个条目的输出线
  logic [NUM_ENTRIES-1:0]                      ety_valid;
  logic [NUM_ENTRIES-1:0]                      ety_issued;
  logic [NUM_ENTRIES-1:0]                      ety_can_issue;
  logic [NUM_ENTRIES-1:0][FU_NUM-1:0]          ety_fu_type;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][3:0] ety_data_src;
  entry_t [NUM_ENTRIES-1:0]                    ety_entry;
  entry_t [NUM_ENTRIES-1:0]                    ety_trans_entry;
  logic [NUM_ENTRIES-1:0]                      ety_trans_valid;
  logic [NUM_ENTRIES-1:0][1:0]                 ety_issue_timer;
  logic [NUM_ENTRIES-1:0]                      ety_enq_ready;

  // 每个条目的输入线
  logic   [NUM_ENTRIES-1:0]    ety_enq_valid;
  entry_t [NUM_ENTRIES-1:0]    ety_enq_bits;
  logic   [NUM_ENTRIES-1:0]    ety_deq_sel;
  deq_resp_t [NUM_ENTRIES-1:0] ety_issue_resp;
  logic   [NUM_ENTRIES-1:0]    ety_trans_sel;

  logic [NUM_ENTRIES-1:0]      valid_for_trans; // valid && !issued

  // ===========================================================================
  // 1. ★ issueResp 折算 ★:resp/valid = f(issueTimer)。
  //    timer0→og0(valid=og0.valid, resp=BLOCK)
  //    timer1→og1(valid=og1.valid, resp=UNCERTAIN)
  //    timer2→og2(valid=og2.valid, resp=og2.bits.resp)
  //    timer3(饱和)→ 三路 mem 响应按 {sqIdx,lqIdx} 与本条目匹配:
  //        valid = hit0 | hit1 | hit2
  //        resp  = (hit0?vecLd.resp:0) | (hit1?slow.resp:0) | (hit2?final.resp:0)
  // ===========================================================================
  // 某条目 e 是否被某路 mem 响应命中(按 {sqIdx,lqIdx})。用条目 payload 的 sqIdx/lqIdx。
  function automatic logic mem_hit(input mem_resp_t r, input entry_t e);
    return r.valid
      & ({r.sq_flag, r.sq_value} == {e.payload.sq_flag, e.payload.sq_value})
      & ({r.lq_flag, r.lq_value} == {e.payload.lq_flag, e.payload.lq_value});
  endfunction

  // 三路 mem 响应对每条目的命中(纯组合,按 {sqIdx,lqIdx} 匹配)。
  // ★ 无条件赋值 ★:必须在所有路径上驱动,否则 FM 前端把它当条件锁存推成
  //   impl-only 死寄存器(h0_reg/h1_reg/h2_reg,写而不被读的比较点 → strict PARTIAL)。
  //   逐拍全条目重算,仅在 timer 饱和窗口被 issueResp 消费。
  logic [NUM_ENTRIES-1:0] ety_mem_hit0, ety_mem_hit1, ety_mem_hit2;
  always_comb begin
    for (int e = 0; e < NUM_ENTRIES; e++) begin
      ety_mem_hit0[e] = mem_hit(vecld_resp,        ety_entry[e]);
      ety_mem_hit1[e] = mem_hit(frommem_slow_resp, ety_entry[e]);
      ety_mem_hit2[e] = mem_hit(vecld_final_resp,  ety_entry[e]);
    end
  end

  always_comb begin
    for (int e = 0; e < NUM_ENTRIES; e++) begin
      logic [1:0] tmr;
      logic       v;
      logic [1:0] r;
      logic       h0, h1, h2;
      tmr = ety_issue_timer[e];
      h0  = ety_mem_hit0[e];
      h1  = ety_mem_hit1[e];
      h2  = ety_mem_hit2[e];
      v = 1'b0; r = 2'h0;
      if (tmr == 2'h0) begin
        v = og0resp_valid;       r = RESP_BLOCK;
      end else if (tmr == 2'h1) begin
        v = og1resp_valid;       r = RESP_UNCERTAIN;
      end else if (tmr == 2'h2) begin
        v = og2resp_valid;       r = og2resp_resp;
      end else begin
        // timer 饱和窗口:三路 mem 响应按索引匹配。
        v  = h0 | h1 | h2;
        r  = (h0 ? vecld_resp.resp        : 2'h0)
           | (h1 ? frommem_slow_resp.resp : 2'h0)
           | (h2 ? vecld_final_resp.resp  : 2'h0);
      end
      ety_issue_resp[e].valid = v;
      ety_issue_resp[e].resp  = resp_type_e'(r);
    end
  end

  // ===========================================================================
  // 2. deqSel:某条目被 deq 端口选中。
  // ===========================================================================
  always_comb
    for (int e = 0; e < NUM_ENTRIES; e++)
      ety_deq_sel[e] = deq_sel_oh_valid & deq_sel_oh_bits[e];

  // ===========================================================================
  // 3. 转移策略(hasCompAndSimp 分支,结构同 VfDiv,维度 8→14)
  // ===========================================================================
  logic [NUM_SIMP-1:0] simp_enq_ready;
  always_comb
    for (int i = 0; i < NUM_SIMP; i++) simp_enq_ready[i] = ety_enq_ready[SIMP_BASE + i];

  // EnqPolicy 黑盒输入 canEnq(NUM_OTHERS=14 位):
  //   simp 用 simp_enq_ready(高位补 0);comp 用「comp 条目 !valid」。
  logic [NUM_OTHERS-1:0] simp_can_enq, comp_can_enq;
  always_comb begin
    simp_can_enq = '0;
    simp_can_enq[NUM_SIMP-1:0] = simp_enq_ready;
    comp_can_enq = '0;
    for (int i = 0; i < NUM_COMP; i++) comp_can_enq[i] = ~ety_valid[COMP_BASE + i];
  end

  logic                  simp_sel0_valid, simp_sel1_valid, comp_sel0_valid, comp_sel1_valid;
  logic [NUM_OTHERS-1:0] simp_sel0_bits,  simp_sel1_bits,  comp_sel0_bits,  comp_sel1_bits;

  EnqPolicy_14 u_simp_trans_policy (
    .io_canEnq             (simp_can_enq),
    .io_enqSelOHVec_0_valid(simp_sel0_valid),
    .io_enqSelOHVec_0_bits (simp_sel0_bits),
    .io_enqSelOHVec_1_valid(simp_sel1_valid),
    .io_enqSelOHVec_1_bits (simp_sel1_bits)
  );
  EnqPolicy_14 u_comp_trans_policy (
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
    n_enq_valid  = ety_valid[0] + ety_valid[1];
    n_comp_empty = 0;
    // ~ 是定宽运算符,32 位加法上下文会按 32 位取反致下溢;须用逻辑非 !(单比特)。
    for (int i = 0; i < NUM_COMP; i++) n_comp_empty += !ety_valid[COMP_BASE + i];
    n_simp_ready = 0;
    for (int i = 0; i < NUM_SIMP; i++) n_simp_ready += simp_enq_ready[i];
    simp_any_valid = |ety_valid[COMP_BASE-1:SIMP_BASE];
  end

  logic enq_can_trans2comp, enq_can_trans2simp;
  logic [NUM_ENQ-1:0] simp_can_trans2comp;
  always_comb begin
    enq_can_trans2comp = (n_enq_valid <= n_comp_empty) & ~simp_any_valid;
    enq_can_trans2simp = ~enq_can_trans2comp & (n_enq_valid <= n_simp_ready);
    for (int i = 0; i < NUM_ENQ; i++)
      simp_can_trans2comp[i] = ~enq_can_trans2comp & (n_comp_empty >= (i + 1));
  end

  always_comb
    for (int e = 0; e < NUM_ENTRIES; e++)
      valid_for_trans[e] = ety_valid[e] & ~ety_issued[e];

  logic                  simp_tsel0_valid, simp_tsel1_valid, comp_tsel0_valid, comp_tsel1_valid;
  logic [NUM_OTHERS-1:0] simp_tsel1_src_bits, comp_tsel1_src_bits;
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
  // finalCompTransSelVec(enq):两支都用 selValid gate 的 selOH(与 VfDiv 同构)。
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

  // simpEntryEnq[s]:由 finalSimpTransSel one-hot(over enq)选出 enqEntryTransVec
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

  // compEnqVec[q]:enqCanTrans2Comp ? enqEntryTransVec : Mux1H(simpDeqSel, simpTransVec)
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

  // compEntryEnq[c]:由 finalCompTransSel one-hot(over enq)选出 compEnqVec
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
  // 5. 例化 16 个单条目。enq 延迟唤醒:把当拍 WB 总线打 1 拍(由顶层提供 wk_wb_d)。
  // ===========================================================================
  genvar e;
  generate
    for (e = 0; e < NUM_ENTRIES; e++) begin : g_entry
      localparam bit IS_ENQ_E   = (e < NUM_ENQ);
      localparam bit IS_TRANS_E = (e >= SIMP_BASE) && (e < COMP_BASE);

      xs_iq_entry_vlduvstu #(.IS_ENQ(IS_ENQ_E), .IS_TRANS(IS_TRANS_E)) u_ety (
        .clock          (clock),
        .reset          (reset),
        .flush_valid    (flush_valid),
        .flush_rob_flag (flush_rob_flag),
        .flush_rob_value(flush_rob_value),
        .flush_level    (flush_level),
        .enq_valid      (ety_enq_valid[e]),
        .enq_bits       (ety_enq_bits[e]),
        .wk_wb          (wk_wb),
        .wk_wb_d1       (wk_wb_d),
        .vl_info        (vl_info),
        .deq_sel        (ety_deq_sel[e]),
        .issue_resp     (ety_issue_resp[e]),
        .trans_sel      (ety_trans_sel[e]),
        .from_lsq_lq_deq_ptr_flag  (lq_deq_ptr_flag),
        .from_lsq_lq_deq_ptr_value (lq_deq_ptr_value),
        .o_valid        (ety_valid[e]),
        .o_issued       (ety_issued[e]),
        .o_can_issue    (ety_can_issue[e]),
        .o_fu_type      (ety_fu_type[e]),
        .o_data_src     (ety_data_src[e]),
        .o_entry        (ety_entry[e]),
        .o_issue_timer_read(ety_issue_timer[e]),
        .o_enq_ready    (ety_enq_ready[e]),
        .o_trans_valid  (ety_trans_valid[e]),
        .o_trans_entry  (ety_trans_entry[e])
      );
    end
  endgenerate

  // ===========================================================================
  // 6. 阵列状态汇聚输出
  // ===========================================================================
  always_comb begin
    for (int i = 0; i < NUM_ENTRIES; i++) begin
      o_valid[i]        = ety_valid[i];
      o_issued[i]       = ety_issued[i];
      o_can_issue[i]    = ety_can_issue[i];
      o_fu_type[i]      = ety_fu_type[i];
      o_data_sources[i] = ety_data_src[i];
    end
  end

  // ===========================================================================
  // 7. 年龄最老选择(oldest mux) + deqEntry 三级选择(numDeq=1)
  //    deqEntry = compSel.valid ? compOldest : (simpSel.valid ? simpOldest : enqOldest)
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
