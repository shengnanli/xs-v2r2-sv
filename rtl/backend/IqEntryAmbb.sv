// =============================================================================
// xs_iq_entry_ambb —— 香山 V2R2(昆明湖) 发射队列「单条目」可读重写 (AluMulBkuBrhJmp 变体)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{EntryBundles,EnqEntry,OthersEntry}.scala
// golden 对照:EnqEntry.sv(入队条目) / OthersEntry.sv(简单条目) / OthersEntry_6.sv(复杂条目)
//
// ★ 这是乱序调度「唤醒-选择」机制的最小单元 ★(机理同 AluCsrFenceDiv 样板,见 IqEntryAcfd.sv)
// 本变体相对样板的**唯一实质差异**集中在两处,其余唤醒/取消/RegCache/loadDep/issued/
// issueTimer/transEntry 逻辑与样板逐行同构(同一颗 UIntCompressor、同一组 og0Cancel 命中位):
//   A) FuType 保留位:本变体 = {brh(0),jmp(1),alu(6),mul(7),bku(10)};
//   B) payload 字段:本变体携带分支预测 preDecodeInfo.isRVC / pred_taken,无 flushPipe。
//      ——这两个字段是纯透传(随条目寄存/转移搬运),不参与唤醒选择逻辑。
//
// 三种条目变体由参数选择(对应 golden 三个 leaf):
//   IS_ENQ=1            入队条目(EnqEntry):带 2 拍「入队延迟唤醒」流水。
//   IS_ENQ=0,IS_COMP=0 简单条目(OthersEntry):无 canIssueBypass。
//   IS_ENQ=0,IS_COMP=1 复杂条目(OthersEntry_6):有 canIssueBypass + 即时前递输出。
//
// X 处理与样板一致:状态全在 entry_reg(复位无关,UT 用 `!$isunknown` + initreg 收敛);
// 三元 mux / if-else 选择避免 X 传播;exuSources 编码作 golden 黑盒 UIntCompressor。
// =============================================================================
module xs_iq_entry_ambb import iq_ambb_pkg::*; #(
  parameter bit IS_ENQ  = 1'b0,
  parameter bit IS_COMP = 1'b0
) (
  input  logic                         clock,
  input  logic                         reset,

  // ---- 冲刷 / 入队 ----
  input  logic                         flush_valid,
  input  logic                         flush_rob_flag,
  input  logic [ROB_PTR_W-1:0]         flush_rob_value,
  input  logic                         flush_level,
  input  logic                         enq_valid,
  input  entry_t                       enq_bits,

  // ---- 唤醒总线(当拍) ----
  input  wk_wb_t [NUM_WK_WB-1:0]       wk_wb,
  input  wk_iq_t [NUM_WK_IQ-1:0]       wk_iq,

  // ---- 入队延迟唤醒(仅 IS_ENQ 用):同一总线打 1 拍 ----
  input  wk_wb_t [NUM_WK_WB-1:0]       wk_wb_d1,
  input  wk_iq_t [NUM_WK_IQ-1:0]       wk_iq_d1,
  input  logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] enqd1_src_ld,   // RegEnable 后的入队源 load 依赖
  // RegNext(og0Cancel):仅 4 个 is0Lat 源 {全局EXU 0,2,4,6} 被读,按序打包成 [3:0]
  //   (golden delay1 只寄存这 4 位 REG_0/2/4/6,其余 og0Cancel 位在本层不被读)。
  input  logic [3:0]                   enqd1_og0cancel,
  input  logic [LDPW-1:0]              enqd1_ldcancel,             // RegNext(ldCancel.ld2)(仅 ld2Cancel)
  // 注:本变体 golden EnqEntry 仅有 enqDelayIn1(单级延迟唤醒),无 enqDelayIn2。
  //   整数路 dataSources 只取 bypass,delay1 已覆盖 srcState/loadDep/regcache,
  //   故不实现 delay2,亦不引 delay2 输入(移除后消除 Entries 顶层死流水寄存器)。

  // ---- 取消 ----
  input  logic [NUM_EXU-1:0]           og0cancel,
  input  logic [NUM_EXU-1:0]           og1cancel,
  input  ld_cancel_t [LDPW-1:0]        ldcancel,

  // ---- 发射选择 / 响应 / 转移 ----
  input  logic                         deq_sel,
  input  logic                         deq_port_write,
  input  deq_resp_t                    issue_resp,
  input  logic                         trans_sel,

  // ---- 状态输出 ----
  output logic                         o_valid,
  output logic                         o_issued,
  output logic                         o_can_issue,
  output logic [FU_NUM-1:0]            o_fu_type,
  output logic [NUM_REGSRC-1:0][3:0]   o_data_src,
  output logic [NUM_REGSRC-1:0][2:0]   o_exu_src,
  output entry_t                       o_entry,
  output logic                         o_cancel_bypass,
  output logic                         o_deq_port_read,
  output logic [1:0]                   o_issue_timer_read,
  output logic                         o_enq_ready,
  output logic                         o_trans_valid,
  output entry_t                       o_trans_entry
);

  // ===========================================================================
  // 0. 寄存器:条目本体 + valid
  // ===========================================================================
  entry_t entry_reg;
  logic   valid_reg;
  logic   enqd_valid_reg; // 仅 IS_ENQ:入队后下一拍为高

  // ===========================================================================
  // 1. 当前状态 current_status
  // ===========================================================================
  status_t current_status;

  // ===========================================================================
  // 2. 冲刷判定 flushed(环形 robIdx 比较)
  // ===========================================================================
  logic flushed;
  always_comb begin
    logic gt;
    gt = (current_status.rob_flag ^ flush_rob_flag) ^ (current_status.rob_value > flush_rob_value);
    flushed = flush_valid & ((flush_level &
                ({current_status.rob_flag, current_status.rob_value} ==
                 {flush_rob_flag, flush_rob_value})) | gt);
  end

  // ===========================================================================
  // 3. load 取消:LoadShouldCancel(只接 ld2Cancel)
  // ===========================================================================
  function automatic logic load_should_cancel(input logic [LDPW-1:0][LDW-1:0] dep,
                                              input ld_cancel_t [LDPW-1:0] ldc);
    logic c;
    c = 1'b0;
    for (int p = 0; p < LDPW; p++) c |= ldc[p].ld2_cancel & dep[p][1];
    return c;
  endfunction
  // 仅取 ld2Cancel 位向量的重载(入队延迟路:golden 的 delay1 ldCancel 只寄存 ld2Cancel,
  //   ld1Cancel 全局未接 → 不寄存,避免 impl-only 死寄存器)。
  function automatic logic load_should_cancel_ld2(input logic [LDPW-1:0][LDW-1:0] dep,
                                                  input logic [LDPW-1:0] ld2c);
    logic c;
    c = 1'b0;
    for (int p = 0; p < LDPW; p++) c |= ld2c[p] & dep[p][1];
    return c;
  endfunction

  // ===========================================================================
  // 4. 唤醒匹配函数:pdest==psrc && srcType.isXp && rfWen [&& valid]
  // ===========================================================================
  function automatic logic match_wb(input wk_wb_t w, input src_status_t s);
    return (w.pdest == s.psrc) & s.src_type[0] & w.rf_wen & w.valid;
  endfunction
  function automatic logic match_iq(input wk_iq_t w, input src_status_t s);
    return (w.pdest == s.psrc) & s.src_type[0] & w.rf_wen;
  endfunction

  // IQ 唤醒源 loadDependency 左移 1 位
  function automatic logic [LDW-1:0] shift_dep(input logic [LDW-1:0] d);
    return {d[0], 1'b0};
  endfunction

  // ===========================================================================
  // 5. 唤醒/取消组合逻辑(逐源)
  // ===========================================================================
  logic [NUM_REGSRC-1:0][NUM_WK_IQ-1:0] wk_iq_vec;
  logic [NUM_REGSRC-1:0][NUM_WK_IQ-1:0] wk_iq_nc;
  logic [NUM_WK_IQ-1:0]                 iq_cancel_sel;
  logic [NUM_REGSRC-1:0][NUM_WK_WB-1:0] wk_wb_vec;

  // og0Cancel 对各唤醒源的取消位(拓扑与 ACFD 一致:仅源 0/1 有 is0Lat,源 0..3 被 og0 取消)
  always_comb begin
    iq_cancel_sel = '0;
    iq_cancel_sel[0] = og0cancel[0] & wk_iq[0].is0lat;
    iq_cancel_sel[1] = og0cancel[2] & wk_iq[1].is0lat;
    iq_cancel_sel[2] = og0cancel[4];
    iq_cancel_sel[3] = og0cancel[6];
  end

  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      for (int i = 0; i < NUM_WK_IQ; i++) begin
        wk_iq_vec[s][i] = match_iq(wk_iq[i], entry_reg.status.src[s]);
        wk_iq_nc[s][i]  = wk_iq_vec[s][i] & ~iq_cancel_sel[i];
      end
      for (int i = 0; i < NUM_WK_WB; i++)
        wk_wb_vec[s][i] = match_wb(wk_wb[i], entry_reg.status.src[s]);
    end
  end

  logic [NUM_REGSRC-1:0] src_ld_trans_cancel;
  logic [NUM_REGSRC-1:0] src_ld_cancel;
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      logic t;
      t = 1'b0;
      for (int i = 0; i < NUM_WK_IQ; i++)
        t |= wk_iq_vec[s][i] & load_should_cancel(wk_iq[i].ld_dep, ldcancel);
      src_ld_trans_cancel[s] = t;
      src_ld_cancel[s] = load_should_cancel(current_status.src[s].ld_dep, ldcancel);
    end
  end

  logic [NUM_REGSRC-1:0] wakeup_by_iq;
  logic [NUM_REGSRC-1:0] wakeup_by_wb;
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      wakeup_by_iq[s] = (|wk_iq_nc[s]) & ~src_ld_trans_cancel[s];
      wakeup_by_wb[s] = |wk_wb_vec[s];
    end
  end

  // ===========================================================================
  // 6. exuSources 编码(同 ACFD:UIntCompressor 黑盒,输入布局 bit{0,2,4,6}+{20,21,22})
  // ===========================================================================
  logic [NUM_EXU-1:0] exu_comp_in [NUM_REGSRC];
  logic [6:0]         exu_comp_out [NUM_REGSRC];
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      exu_comp_in[s] = '0;
      exu_comp_in[s][0]  = wk_iq_nc[s][0];
      exu_comp_in[s][2]  = wk_iq_nc[s][1];
      exu_comp_in[s][4]  = wk_iq_nc[s][2];
      exu_comp_in[s][6]  = wk_iq_nc[s][3];
      exu_comp_in[s][20] = wk_iq_nc[s][4];
      exu_comp_in[s][21] = wk_iq_nc[s][5];
      exu_comp_in[s][22] = wk_iq_nc[s][6];
    end
  end

  genvar gs;
  generate
    for (gs = 0; gs < NUM_REGSRC; gs++) begin : g_exucomp
      UIntCompressor_27_000011100000000000001010101 u_exucomp (
        .io_in  (exu_comp_in[gs]),
        .io_out (exu_comp_out[gs])
      );
    end
  endgenerate

  function automatic logic [2:0] enc_exu_src(input logic [6:0] c);
    logic [2:0] t17;
    t17 = c[6:4] | c[2:0];
    return {|c[6:3], |t17[2:1], t17[2] | t17[0]};
  endfunction

  logic [NUM_REGSRC-1:0] wakeup_by_iq_raw;
  always_comb
    for (int s = 0; s < NUM_REGSRC; s++) wakeup_by_iq_raw[s] = |wk_iq_vec[s];

  // ===========================================================================
  // 7. RegCache(同 ACFD)
  // ===========================================================================
  logic [NUM_REGSRC-1:0]            wakeup_rc;
  logic [NUM_REGSRC-1:0][RC_IDX_W-1:0] wakeup_rc_idx;
  logic [NUM_REGSRC-1:0]            replace_rc;
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      logic [RC_IDX_W-1:0] idx;
      logic rep;
      wakeup_rc[s] = (|wk_iq_nc[s]) & current_status.src[s].src_type[0];
      idx = '0; rep = 1'b0;
      for (int i = 0; i < NUM_WK_IQ; i++) begin
        if (wk_iq_nc[s][i]) idx |= wk_iq[i].rc_dest;
        rep |= wk_iq[i].rf_wen & (wk_iq[i].rc_dest == current_status.src[s].rc_idx);
      end
      wakeup_rc_idx[s] = idx;
      replace_rc[s] = rep;
    end
  end

  // ===========================================================================
  // 8. shiftedWakeupLoadDependency(同 ACFD)
  // ===========================================================================
  logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] wk_shift_dep;
  logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] self_shift_dep;
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      for (int p = 0; p < LDPW; p++) begin
        logic [LDW-1:0] acc;
        acc = '0;
        for (int i = 0; i < 4; i++)
          if (wk_iq_nc[s][i]) acc |= shift_dep(wk_iq[i].ld_dep[p]);
        acc |= {1'b0, wk_iq_vec[s][4 + p]};
        wk_shift_dep[s][p]   = acc;
        self_shift_dep[s][p] = shift_dep(current_status.src[s].ld_dep[p]);
      end
    end
  end

  // ===========================================================================
  // 9. 公共控制信号
  // ===========================================================================
  logic deq_success;
  logic resp_fail;
  logic enq_ready;
  logic clear;
  logic valid_reg_next;

  logic [NUM_REGSRC-1:0] cancel_bypass_vec;
  always_comb
    for (int s = 0; s < NUM_REGSRC; s++)
      cancel_bypass_vec[s] = (IS_COMP & wakeup_by_iq_raw[s]) ? src_ld_trans_cancel[s] : src_ld_cancel[s];

  always_comb begin
    deq_success = issue_resp.valid & (issue_resp.resp == RESP_SUCCESS) & ~(|src_ld_cancel);
    resp_fail   = issue_resp.valid & (issue_resp.resp == RESP_BLOCK);
    enq_ready   = ~valid_reg | trans_sel;
    clear       = flushed | deq_success | trans_sel;
    if (IS_ENQ) valid_reg_next = enq_valid & enq_ready ? 1'b1 : (clear ? 1'b0 : valid_reg);
    else        valid_reg_next = enq_valid           ? 1'b1 : (clear ? 1'b0 : valid_reg);
  end

  // ===========================================================================
  // 10. entry_update:条目下一拍状态(EntryRegCommonConnect)
  // ===========================================================================
  entry_t entry_update;
  always_comb begin
    entry_update = entry_reg;
    // fuType 紧凑存储:直接透传保留位(IQFuType.readFuType 的剪枝已在 pack 时完成)
    entry_update.status.fu_type = current_status.fu_type;
    entry_update.status.rob_flag  = current_status.rob_flag;
    entry_update.status.rob_value = current_status.rob_value;

    for (int s = 0; s < NUM_REGSRC; s++) begin
      entry_update.status.src[s].src_state =
        (current_status.src[s].src_state & ~src_ld_cancel[s]) | wakeup_by_wb[s] | wakeup_by_iq[s];
      entry_update.status.src[s].src_type = current_status.src[s].src_type;
      entry_update.status.src[s].psrc     = current_status.src[s].psrc;
      if (wakeup_by_iq[s])
        entry_update.status.src[s].data_src = DS_BYPASS;
      else if (current_status.src[s].data_src == DS_BYPASS)
        entry_update.status.src[s].data_src = DS_REG;
      else
        entry_update.status.src[s].data_src = current_status.src[s].data_src;
      if (|wk_iq_nc[s])
        entry_update.status.src[s].exu_src = enc_exu_src(exu_comp_out[s]);
      else
        entry_update.status.src[s].exu_src = current_status.src[s].exu_src;
      for (int p = 0; p < LDPW; p++)
        if (wakeup_by_iq[s]) entry_update.status.src[s].ld_dep[p] = wk_shift_dep[s][p];
        else                 entry_update.status.src[s].ld_dep[p] = self_shift_dep[s][p];
      entry_update.status.src[s].use_rc =
        (current_status.src[s].use_rc & ~(src_ld_cancel[s] | replace_rc[s])) | wakeup_rc[s];
      entry_update.status.src[s].rc_idx =
        wakeup_rc[s] ? wakeup_rc_idx[s] : current_status.src[s].rc_idx;
    end

    entry_update.status.issued =
      (deq_sel & ~(|cancel_bypass_vec))
      | (~((|src_ld_cancel) | resp_fail) & current_status.issued);
    if (deq_sel)
      entry_update.status.issue_timer = 2'h0;
    else if (current_status.issued)
      entry_update.status.issue_timer =
        (current_status.issue_timer == 2'h3) ? current_status.issue_timer
                                             : (current_status.issue_timer + 2'h1);
    else
      entry_update.status.issue_timer = 2'h3;
    entry_update.status.deq_port =
      deq_sel ? deq_port_write : (current_status.issued ? current_status.deq_port : 1'b0);
    entry_update.imm     = entry_reg.imm;
    entry_update.payload = entry_reg.payload;
  end

  // ===========================================================================
  // 11. 时序:valid_reg / entry_reg
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) valid_reg <= 1'b0;
    else       valid_reg <= valid_reg_next;
  end

  entry_t enq_load;
  always_comb begin
    enq_load = enq_bits;
    if (IS_ENQ) begin
      enq_load.status.issued      = 1'b0;
      enq_load.status.deq_port    = 1'b0;
      enq_load.status.issue_timer = 2'h3;
    end
  end

  always_ff @(posedge clock) begin
    if (enq_valid & (IS_ENQ ? enq_ready : 1'b1)) entry_reg <= enq_load;
    else                                         entry_reg <= entry_update;
  end

  // ===========================================================================
  // 12. 入队延迟唤醒(仅 IS_ENQ),逻辑同 ACFD
  // ===========================================================================
  generate
  if (IS_ENQ) begin : g_enq_delay
    logic enqd_valid_reg_next;
    always_comb enqd_valid_reg_next = enq_valid & enq_ready;
    always_ff @(posedge clock or posedge reset) begin
      if (reset) enqd_valid_reg <= 1'b0;
      else       enqd_valid_reg <= enqd_valid_reg_next;
    end

    logic [NUM_REGSRC-1:0] d1_wb, d1_iq, d1_iq2;
    logic [NUM_REGSRC-1:0][NUM_WK_IQ-1:0] d1_iqvec, d1_iqnc;
    logic [NUM_WK_IQ-1:0] d1_cancel;
    logic [NUM_REGSRC-1:0] d1_ldcancel;
    logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] d1_shift_dep;
    logic [NUM_REGSRC-1:0] d1_wakeup_rc;
    logic [NUM_REGSRC-1:0] d1_replace_rc;
    logic [NUM_REGSRC-1:0][RC_IDX_W-1:0] d1_rc_idx;
    always_comb begin
      // enqd1_og0cancel[0..3] = 打包后的 og0Cancel 全局EXU 位 {0,2,4,6}
      d1_cancel = '0;
      d1_cancel[0] = enqd1_og0cancel[0] & wk_iq_d1[0].is0lat;
      d1_cancel[1] = enqd1_og0cancel[1] & wk_iq_d1[1].is0lat;
      d1_cancel[2] = enqd1_og0cancel[2];
      d1_cancel[3] = enqd1_og0cancel[3];
      for (int s = 0; s < NUM_REGSRC; s++) begin
        logic wbhit, ldtc, rep;
        logic [RC_IDX_W-1:0] idx;
        wbhit = 1'b0;
        for (int i = 0; i < NUM_WK_WB; i++) wbhit |= match_wb(wk_wb_d1[i], entry_reg.status.src[s]);
        d1_wb[s] = wbhit;
        ldtc = 1'b0;
        idx  = '0;
        rep  = 1'b0;
        for (int i = 0; i < NUM_WK_IQ; i++) begin
          d1_iqvec[s][i] = match_iq(wk_iq_d1[i], entry_reg.status.src[s]);
          d1_iqnc[s][i]  = d1_iqvec[s][i] & ~d1_cancel[i];
          if (i < 4) ldtc |= d1_iqnc[s][i] & load_should_cancel_ld2(wk_iq_d1[i].ld_dep, enqd1_ldcancel);
          rep |= wk_iq_d1[i].rf_wen & (wk_iq_d1[i].rc_dest == entry_reg.status.src[s].rc_idx);
        end
        for (int i = 0; i < 4; i++)       if (d1_iqnc[s][i]) idx |= wk_iq_d1[i].rc_dest;
        for (int i = 4; i < NUM_WK_IQ; i++) if (d1_iqvec[s][i]) idx |= wk_iq_d1[i].rc_dest;
        d1_replace_rc[s] = rep;
        d1_iq2[s] = (|d1_iqnc[s][3:0]) | d1_iqvec[s][4] | d1_iqvec[s][5] | d1_iqvec[s][6];
        d1_iq[s]  = d1_iq2[s] & ~ldtc;
        d1_ldcancel[s] = load_should_cancel_ld2(enqd1_src_ld[s], enqd1_ldcancel);
        for (int p = 0; p < LDPW; p++) begin
          logic [LDW-1:0] acc; acc = '0;
          for (int i = 0; i < 4; i++) if (d1_iqnc[s][i]) acc |= shift_dep(wk_iq_d1[i].ld_dep[p]);
          acc |= {1'b0, d1_iqvec[s][4 + p]};
          d1_shift_dep[s][p] = acc;
        end
        d1_wakeup_rc[s] = d1_iq2[s] & entry_reg.status.src[s].src_type[0];
        d1_rc_idx[s] = idx;
      end
    end

    logic [NUM_EXU-1:0] d1_exu_in [NUM_REGSRC];
    logic [6:0]         d1_exu_out [NUM_REGSRC];
    always_comb begin
      for (int s = 0; s < NUM_REGSRC; s++) begin
        d1_exu_in[s] = '0;
        d1_exu_in[s][0]  = d1_iqnc[s][0];
        d1_exu_in[s][2]  = d1_iqnc[s][1];
        d1_exu_in[s][4]  = d1_iqnc[s][2];
        d1_exu_in[s][6]  = d1_iqnc[s][3];
        d1_exu_in[s][20] = d1_iqvec[s][4];
        d1_exu_in[s][21] = d1_iqvec[s][5];
        d1_exu_in[s][22] = d1_iqvec[s][6];
      end
    end
    for (gs = 0; gs < NUM_REGSRC; gs++) begin : g_d1_exucomp
      UIntCompressor_27_000011100000000000001010101 u_d1_exucomp (
        .io_in  (d1_exu_in[gs]),
        .io_out (d1_exu_out[gs])
      );
    end

    always_comb begin
      current_status = entry_reg.status;
      if (enqd_valid_reg) begin
        for (int s = 0; s < NUM_REGSRC; s++) begin
          current_status.src[s].src_state =
            (~d1_ldcancel[s] & entry_reg.status.src[s].src_state) | d1_wb[s] | d1_iq[s];
          current_status.src[s].data_src =
            d1_iq[s] ? DS_BYPASS : entry_reg.status.src[s].data_src;
          for (int p = 0; p < LDPW; p++)
            current_status.src[s].ld_dep[p] =
              d1_iq2[s] ? d1_shift_dep[s][p] : entry_reg.status.src[s].ld_dep[p];
          current_status.src[s].exu_src = enc_exu_src(d1_exu_out[s]);
          current_status.src[s].use_rc =
            (entry_reg.status.src[s].use_rc & ~(d1_ldcancel[s] | d1_replace_rc[s])) | d1_wakeup_rc[s];
          current_status.src[s].rc_idx =
            d1_wakeup_rc[s] ? d1_rc_idx[s] : entry_reg.status.src[s].rc_idx;
        end
      end
    end
  end else begin : g_others_status
    always_comb current_status = entry_reg.status;
  end
  endgenerate

  // ===========================================================================
  // 13. 组合输出
  // ===========================================================================
  logic [NUM_EXU-1:0] exu_comp_in_raw [NUM_REGSRC];
  logic [6:0]         exu_comp_out_raw [NUM_REGSRC];
  logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] src_ld_dep_out;
  logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] wk_shift_dep_raw;

  assign o_valid    = valid_reg;
  assign o_issued   = entry_reg.status.issued;
  assign o_enq_ready = enq_ready;
  assign o_deq_port_read = current_status.deq_port;
  assign o_issue_timer_read = current_status.issue_timer;

  logic all_src_rdy, can_issue_base, can_issue_bypass;
  always_comb begin
    all_src_rdy = 1'b1;
    for (int s = 0; s < NUM_REGSRC; s++) all_src_rdy &= current_status.src[s].src_state;
    can_issue_base = valid_reg & all_src_rdy & ~current_status.issued;
    can_issue_bypass = valid_reg & ~current_status.issued;
    for (int s = 0; s < NUM_REGSRC; s++)
      can_issue_bypass &= (wakeup_by_iq_raw[s] | current_status.src[s].src_state);
  end
  assign o_can_issue = (IS_COMP ? (can_issue_base | can_issue_bypass) : can_issue_base) & ~flushed;

  // fuType 输出:紧凑保留位复原成 35 位 one-hot(unpack_fu_type)
  always_comb o_fu_type = unpack_fu_type(current_status.fu_type);

  // dataSources / exuSources 输出
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      logic use_rc_reg;
      use_rc_reg = current_status.src[s].use_rc & current_status.src[s].data_src[3];
      if (IS_COMP & wakeup_by_iq_raw[s]) begin
        o_data_src[s] = DS_FORWARD;
        o_exu_src[s]  = enc_exu_src(exu_comp_out_raw[s]);
      end else begin
        o_data_src[s] = use_rc_reg ? DS_REGCACHE : current_status.src[s].data_src;
        o_exu_src[s]  = current_status.src[s].exu_src;
      end
    end
  end

  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      exu_comp_in_raw[s] = '0;
      exu_comp_in_raw[s][0]  = wk_iq_vec[s][0];
      exu_comp_in_raw[s][2]  = wk_iq_vec[s][1];
      exu_comp_in_raw[s][4]  = wk_iq_vec[s][2];
      exu_comp_in_raw[s][6]  = wk_iq_vec[s][3];
      exu_comp_in_raw[s][20] = wk_iq_vec[s][4];
      exu_comp_in_raw[s][21] = wk_iq_vec[s][5];
      exu_comp_in_raw[s][22] = wk_iq_vec[s][6];
    end
  end
  generate
    for (gs = 0; gs < NUM_REGSRC; gs++) begin : g_exucomp_raw
      UIntCompressor_27_000011100000000000001010101 u_exucomp_raw (
        .io_in  (exu_comp_in_raw[gs]),
        .io_out (exu_comp_out_raw[gs])
      );
    end
  endgenerate

  always_comb begin
    o_entry = entry_reg;
    if (IS_ENQ) o_entry.status = current_status;
    for (int s = 0; s < NUM_REGSRC; s++)
      for (int p = 0; p < LDPW; p++)
        o_entry.status.src[s].ld_dep[p] = src_ld_dep_out[s][p];
  end

  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++)
      for (int p = 0; p < LDPW; p++) begin
        logic [LDW-1:0] acc; acc = '0;
        for (int i = 0; i < 4; i++) if (wk_iq_vec[s][i]) acc |= shift_dep(wk_iq[i].ld_dep[p]);
        acc |= {1'b0, wk_iq_vec[s][4 + p]};
        wk_shift_dep_raw[s][p] = acc;
        src_ld_dep_out[s][p] = (IS_COMP & wakeup_by_iq_raw[s]) ? wk_shift_dep_raw[s][p]
                                                               : self_shift_dep[s][p];
      end
  end

  always_comb begin
    logic c;
    c = 1'b0;
    for (int s = 0; s < NUM_REGSRC; s++)
      c |= (IS_COMP & wakeup_by_iq_raw[s]) ? src_ld_trans_cancel[s] : src_ld_cancel[s];
    o_cancel_bypass = c;
  end

  assign o_trans_valid = valid_reg & ~flushed & ~current_status.issued;
  always_comb o_trans_entry = entry_update;

endmodule
