// =============================================================================
// xs_EntriesFaluFcvtF2vFmacFdiv_core —— 香山 V2R2(昆明湖) 发射队列条目阵列 可读重写
//                                (FaluFcvtF2vFmacFdiv 变体, hasCompAndSimp 路)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/Entries.scala
// golden 对照:EntriesFaluFcvtF2vFmacFdiv.sv(例化 2×EnqEntry_8 + 2×OthersEntry_88(simp)
//             + 14×OthersEntry_90(comp) + 2×EnqPolicy_8(simp/comp 转移策略))
//
// ★ 本模块 = 条目阵列 + 转移策略 + 年龄最老选择(每发射端口一套)★
// 本模块直接 fork 自 FaluFmacFdiv 变体(xs_EntriesFaluFmacFdiv_core):阵列框架、
// 双发射端口、转移策略全部**逐字相同**。差异只在单条目核携带的 entry_t 多了
// 两位 fuType(F2v/Fcvt)与两位 payload 写使能(vec_wen/v0_wen)——这些都封装在
// entry_t struct 里随条目透传,本阵列层「FU 类型无关」,无需任何改动。
//
//   1) numDeq = 2:deqSelOH / og0Resp / og1Resp / oldestSel(enq/simp/comp) / deqEntry
//      全部成对(端口 0 / 端口 1)。端口 0 = Falu/Fmac/Fcvt/F2v,端口 1 = Fdiv。
//   2) deqSel[e] = 任一端口选中本条目;deq_port_idx_write[e] = 端口 1 选中(写入 deqPortIdx)。
//   3) issueResp[e]:按本条目的 deq_port_idx_read[e] 选择对应端口的 (valid,resp):
//        - 端口 0:resp 硬编码 timer1=SUCCESS;valid 取 og{0,1}Resp_0。
//        - 端口 1:resp 取 og1Resp_1_bits_resp(timer1);valid 取 og{0,1}Resp_1。
//      (golden _GEN/_GEN_14/_GEN_15/_GEN_16,见 pkg 头部说明)。
//   4) deqEntry_0 / deqEntry_1:各自用 oldestSel_0 / oldestSel_1 做三级 mux(comp>simp>enq)。
//   5) fuType 现含 5 位(F2v/Falu/Fmac/Fcvt/Fdiv,由单条目核携带,本层只汇聚)。
//
// 转移策略(EnqPolicy / finalSimp/CompTransSel / simp→comp 提级)与 FaluFmacFdiv 逐字相同。
// X 铁律:oldest/Mux1H 用「sel[i] ? entry[i] : 0」累加(OR),sel 为 0 时不引 X。
// =============================================================================
module xs_EntriesFaluFcvtF2vFmacFdiv_core import iq_ffcfmacfdiv_pkg::*; (
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

  // ---- 发射响应(og0/og1, 双 deq 端口)----
  //   端口 0:仅用 valid。端口 1:用 valid + og1Resp_1.bits.resp。
  input  logic [NUM_DEQ-1:0]    og0resp_valid,
  input  logic [NUM_DEQ-1:0]    og1resp_valid,
  input  logic [1:0]            og1resp1_resp,   // og1Resp_1_bits_resp(仅端口 1 有)

  // ---- 发射选择(双端口)----
  input  logic [NUM_DEQ-1:0]                   deq_sel_oh_valid,
  input  logic [NUM_DEQ-1:0][NUM_ENTRIES-1:0]  deq_sel_oh_bits,
  input  logic [NUM_DEQ-1:0][NUM_ENQ-1:0]      enq_oldest_sel_bits,
  input  logic [NUM_DEQ-1:0]                   simp_oldest_sel_valid,
  input  logic [NUM_DEQ-1:0][NUM_SIMP-1:0]     simp_oldest_sel_bits,
  input  logic [NUM_DEQ-1:0]                   comp_oldest_sel_valid,
  input  logic [NUM_DEQ-1:0][NUM_COMP-1:0]     comp_oldest_sel_bits,

  // ---- 转移:simp→comp 的 deq 选择(上层 IQ 给)----
  input  logic [NUM_ENQ-1:0][NUM_SIMP-1:0]    simp_deq_sel_vec,

  // ---- 阵列状态输出 ----
  output logic [NUM_ENTRIES-1:0]                       o_valid,
  output logic [NUM_ENTRIES-1:0]                       o_issued,
  output logic [NUM_ENTRIES-1:0]                       o_can_issue,
  output logic [NUM_ENTRIES-1:0][FU_NUM-1:0]           o_fu_type,
  output logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][3:0]  o_data_sources,
  output logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][EXU_SRC_W-1:0] o_exu_sources,

  // ---- deq 出口(每个 deq 端口的最老条目)----
  output entry_t [NUM_DEQ-1:0] o_deq_entry,

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
  logic [NUM_ENTRIES-1:0]                      ety_deq_port_idx; // deqPortIdxRead
  logic [NUM_ENTRIES-1:0]                      ety_enq_ready;

  // 每个条目的输入线
  logic   [NUM_ENTRIES-1:0]      ety_enq_valid;
  entry_t [NUM_ENTRIES-1:0]      ety_enq_bits;
  logic   [NUM_ENTRIES-1:0]      ety_deq_sel;
  logic   [NUM_ENTRIES-1:0]      ety_deq_port_idx_write;
  deq_resp_t [NUM_ENTRIES-1:0]   ety_issue_resp;
  logic   [NUM_ENTRIES-1:0]      ety_trans_sel;

  // validForTrans
  logic [NUM_ENTRIES-1:0]        valid_for_trans; // valid && !issued

  // ===========================================================================
  // 1. issueRespVec:按每条目 deqPortIdxRead 选对应端口的 (valid,resp)。
  //    端口 0:valid=_GEN_14[timer]={0,0,og1Resp_0.valid,og0Resp_0.valid};
  //            resp =_GEN[timer]='{0,0,SUCCESS,0} → 仅 timer1=SUCCESS。
  //    端口 1:valid=_GEN_15[timer]={0,0,og1Resp_1.valid,og0Resp_1.valid};
  //            resp =_GEN_16[timer]={0,0,og1Resp_1.bits.resp,0} → timer1 取动态 resp。
  // ===========================================================================
  always_comb begin
    for (int e = 0; e < NUM_ENTRIES; e++) begin
      logic [1:0] tmr;
      logic       port1;
      logic       v;
      resp_type_e r;
      tmr   = ety_issue_timer[e];
      port1 = ety_deq_port_idx[e];
      v = 1'b0; r = RESP_BLOCK;
      if (tmr == 2'h0) begin
        // timer0:仅 valid 有效(og0Resp.valid),resp=BLOCK。
        v = port1 ? og0resp_valid[1] : og0resp_valid[0];
        r = RESP_BLOCK;
      end else if (tmr == 2'h1) begin
        // timer1:valid 取 og1Resp.valid;端口 0 resp 硬编码 SUCCESS,端口 1 取动态 resp。
        v = port1 ? og1resp_valid[1] : og1resp_valid[0];
        r = port1 ? resp_type_e'(og1resp1_resp) : RESP_SUCCESS;
      end
      ety_issue_resp[e].valid     = v;
      ety_issue_resp[e].resp      = r;
      ety_issue_resp[e].rob_flag  = 1'b0;
      ety_issue_resp[e].rob_value = '0;
      ety_issue_resp[e].fu_type   = '0;
    end
  end

  // ===========================================================================
  // 2. deqSel / deqPortIdxWrite:任一端口选中本条目 → deqSel;端口 1 选中 → 写 deqPortIdx=1。
  // ===========================================================================
  always_comb begin
    for (int e = 0; e < NUM_ENTRIES; e++) begin
      logic sel0, sel1;
      sel0 = deq_sel_oh_valid[0] & deq_sel_oh_bits[0][e];
      sel1 = deq_sel_oh_valid[1] & deq_sel_oh_bits[1][e];
      ety_deq_sel[e]            = sel0 | sel1;
      ety_deq_port_idx_write[e] = sel1;
    end
  end

  // ===========================================================================
  // 3. 转移策略(hasCompAndSimp 分支)——与 FaluFmac 逐字相同
  // ===========================================================================
  logic [NUM_SIMP-1:0] simp_enq_ready;
  logic [NUM_COMP-1:0] comp_enq_ready;
  always_comb begin
    for (int i = 0; i < NUM_SIMP; i++) simp_enq_ready[i] = ety_enq_ready[SIMP_BASE + i];
    for (int i = 0; i < NUM_COMP; i++) comp_enq_ready[i] = ety_enq_ready[COMP_BASE + i];
  end

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

  int unsigned n_enq_valid, n_comp_empty, n_simp_ready;
  logic        simp_any_valid;
  always_comb begin
    n_enq_valid    = ety_valid[0] + ety_valid[1];
    n_comp_empty   = 0;
    // ~ 是定宽运算符会按 32 位取反致下溢;要的是 1 位「该 comp 是否空」,必须用 !。
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

  always_comb
    for (int e = 0; e < NUM_ENTRIES; e++)
      valid_for_trans[e] = ety_valid[e] & ~ety_issued[e];

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

  logic [NUM_ENQ-1:0][NUM_SIMP-1:0] final_simp_trans_sel;
  always_comb begin
    final_simp_trans_sel[0] = {NUM_SIMP{enq_can_trans2simp & simp_tsel0_valid}} & simp_sel0_bits[NUM_SIMP-1:0];
    final_simp_trans_sel[1] = {NUM_SIMP{enq_can_trans2simp & simp_tsel1_valid}} & simp_tsel1_src_bits[NUM_SIMP-1:0];
  end
  logic [NUM_ENQ-1:0][NUM_COMP-1:0] final_comp_trans_sel;
  always_comb begin
    final_comp_trans_sel[0] = enq_can_trans2comp
      ? ({NUM_COMP{comp_tsel0_valid}} & comp_sel0_bits[NUM_COMP-1:0])
      : ({NUM_COMP{comp_sel0_valid}}  & comp_sel0_bits[NUM_COMP-1:0]);
    final_comp_trans_sel[1] = enq_can_trans2comp
      ? ({NUM_COMP{comp_tsel1_valid}} & comp_tsel1_src_bits[NUM_COMP-1:0])
      : ({NUM_COMP{comp_sel1_valid}}  & comp_sel1_bits[NUM_COMP-1:0]);
  end

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
    for (int q = 0; q < NUM_ENQ; q++) begin
      ety_enq_valid[q] = enq_valid[q];
      ety_enq_bits[q]  = enq_bits[q];
      ety_trans_sel[q] = (enq_can_trans2simp & (q==0 ? simp_tsel0_valid : simp_tsel1_valid))
                       | (enq_can_trans2comp & (q==0 ? comp_tsel0_valid : comp_tsel1_valid));
    end
    for (int s = 0; s < NUM_SIMP; s++) begin
      logic tsel;
      ety_enq_valid[SIMP_BASE + s] = simp_entry_enq_valid[s];
      ety_enq_bits[SIMP_BASE + s]  = simp_entry_enq[s];
      tsel = 1'b0;
      for (int q = 0; q < NUM_ENQ; q++)
        tsel |= simp_deq_sel_vec[q][s] & simp_can_trans2comp[q];
      ety_trans_sel[SIMP_BASE + s] = tsel;
    end
    for (int c = 0; c < NUM_COMP; c++) begin
      ety_enq_valid[COMP_BASE + c] = comp_entry_enq_valid[c];
      ety_enq_bits[COMP_BASE + c]  = comp_entry_enq[c];
      ety_trans_sel[COMP_BASE + c] = 1'b0;
    end
  end

  // ===========================================================================
  // 5. 例化 18 个单条目
  // ===========================================================================
  logic [NUM_EXU-1:0] og0_d1;
  always_ff @(posedge clock) og0_d1 <= og0cancel;

  genvar e;
  generate
    for (e = 0; e < NUM_ENTRIES; e++) begin : g_entry
      localparam bit IS_ENQ_E  = (e < NUM_ENQ);
      localparam bit IS_COMP_E = (e < NUM_ENQ) || (e >= COMP_BASE);

      xs_iq_entry_ffcfmacfdiv #(.IS_ENQ(IS_ENQ_E), .IS_COMP(IS_COMP_E)) u_ety (
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
        .deq_port_idx_write(ety_deq_port_idx_write[e]),
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
        .o_deq_port_idx_read(ety_deq_port_idx[e]),
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
      o_exu_sources[i]  = ety_exu_src[i];
    end
  end

  // ===========================================================================
  // 7. 年龄最老选择(每发射端口一套 三级 mux:comp>simp>enq)
  // ===========================================================================
  always_comb begin
    for (int d = 0; d < NUM_DEQ; d++) begin
      entry_t enq_oldest, simp_oldest, comp_oldest;
      enq_oldest = '0; simp_oldest = '0; comp_oldest = '0;
      for (int i = 0; i < NUM_ENQ; i++)
        if (enq_oldest_sel_bits[d][i]) enq_oldest |= ety_entry[i];
      for (int i = 0; i < NUM_SIMP; i++)
        if (simp_oldest_sel_bits[d][i]) simp_oldest |= ety_entry[SIMP_BASE + i];
      for (int i = 0; i < NUM_COMP; i++)
        if (comp_oldest_sel_bits[d][i]) comp_oldest |= ety_entry[COMP_BASE + i];
      o_deq_entry[d] = comp_oldest_sel_valid[d] ? comp_oldest
                     : (simp_oldest_sel_valid[d] ? simp_oldest : enq_oldest);
    end
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
