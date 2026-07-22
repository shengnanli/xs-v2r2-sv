// =============================================================================
// xs_iq_entry_ffmacfdiv —— 香山 V2R2(昆明湖) 发射队列「单条目」可读重写
//                          (FaluFmacFdiv 变体)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{EntryBundles,EnqEntry,OthersEntry}.scala
// golden 对照:EnqEntry_10.sv / OthersEntry_104.sv(simp) / OthersEntry_106.sv(comp)
//
// ★ 乱序调度「唤醒-选择」的最小单元(浮点 FaluFmacFdiv 变体)★
// 机制总览见 xs_iq_entry_ffmac(FaluFmac 样板)。本文件是它的「近邻」fork:
// 唤醒匹配 / exuSources 压缩 / dataSources / canIssue / enqDelay 全部与 FaluFmac **逐字相同**,
// 仅在以下四处真重写以支持 Fdiv:
//
//   ① fuType 多保留 Fdiv 位(FU_FDIV=14):enq/entry_update/输出三处加一位。
//   ② status 多一个 deq_port_idx(1 bit)寄存:
//        - deqSel 时:写为 deq_port_idx_write(=被发射端口 1 选中)。
//        - 否则:issued ? 保持 : 0(对齐 golden entryUpdate_status_deqPortIdx)。
//        - EnqEntry:与 issued 一样,在 enqDelay 窗口被 ~enqDelayValidRegNext 强清 0。
//        - OthersEntry:入队拍取自 enq.bits.status.deq_port_idx(随 transEntry 透传)。
//   ③ deqSel 现在是「两个发射端口任一选中」(由上层 Entries 合成后传入,本模块只收 1 位)。
//   ④ issueResp:由上层 Entries 按本条目的 deq_port_idx_read 选好对应端口的 resp 后传入,
//      本模块仍只收 1 个 issue_resp(语义不变)。deq_port_idx_read 由本模块输出给上层。
//
// 唤醒/X 处理细则同 FaluFmac(此处不赘述,见 IqEntryFfmac.sv)。
// =============================================================================
module xs_iq_entry_ffmacfdiv import iq_ffmacfdiv_pkg::*; #(
  parameter bit IS_ENQ  = 1'b0,  // 是否入队条目(带 enqDelay)
  parameter bit IS_COMP = 1'b0   // 是否复杂条目(带 canIssueBypass / 即时前递输出)
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
  input  wk_wb_t [NUM_WK_WB-1:0]       wk_wb,   // 写回唤醒(fpWen + pdest + valid)
  input  wk_iq_t [NUM_WK_IQ-1:0]       wk_iq,   // 发射唤醒(fpWen + pdest + is0Lat)

  // ---- 入队延迟唤醒(仅 IS_ENQ 用):同一总线打 1 拍(enqDelayIn1) ----
  input  wk_wb_t [NUM_WK_WB-1:0]       wk_wb_d1,
  input  wk_iq_t [NUM_WK_IQ-1:0]       wk_iq_d1,
  input  logic [NUM_EXU-1:0]           enqd1_og0cancel, // RegNext(og0Cancel)

  // ---- 取消 ----
  input  logic [NUM_EXU-1:0]           og0cancel,  // og0 阶段取消(按全局 EXU 号,仅 [8] 被用)

  // ---- 发射选择 / 响应 / 转移 ----
  input  logic                         deq_sel,            // 本条目被选中发射(两端口任一)
  input  logic                         deq_port_idx_write, // 被发射端口 1 选中(写入 deq_port_idx)
  input  deq_resp_t                    issue_resp,         // 发射响应(上层已按 deq_port_idx 选好端口)
  input  logic                         trans_sel,          // 本条目被转移到 comp/simp 条目(出队)

  // ---- 状态输出 ----
  output logic                         o_valid,
  output logic                         o_issued,
  output logic                         o_can_issue,
  output logic [FU_NUM-1:0]            o_fu_type,
  output logic [NUM_REGSRC-1:0][3:0]   o_data_src,   // dataSources[src].value
  output logic [NUM_REGSRC-1:0][EXU_SRC_W-1:0] o_exu_src, // exuSources[src].value
  output entry_t                       o_entry,      // commonOut.entry.bits
  output logic                         o_deq_valid,  // commonOut.entryOutDeqValid (valid & clear)
  output logic [1:0]                   o_issue_timer_read,
  output logic                         o_deq_port_idx_read, // ★ 该条目的出队端口号(给上层选 resp)
  output logic                         o_enq_ready,
  output logic                         o_trans_valid,
  output entry_t                       o_trans_entry // commonOut.transEntry.bits(=entry_update)
);

  // ===========================================================================
  // 0. 寄存器:条目本体 + valid。
  // ===========================================================================
  entry_t entry_reg;
  logic   valid_reg;
  logic   enqd_valid_reg; // 仅 IS_ENQ:入队后下一拍为高,标志「入队延迟唤醒」窗口

  // ===========================================================================
  // 1. 当前状态 current_status
  // ===========================================================================
  status_t current_status;

  // ===========================================================================
  // 2. 冲刷判定 flushed(环形指针比较,与 FaluFmac 同)
  // ===========================================================================
  logic flushed;
  always_comb begin
    logic gt; // robIdx「更年轻」比较
    gt = (current_status.rob_flag ^ flush_rob_flag) ^ (current_status.rob_value > flush_rob_value);
    flushed = flush_valid & ((flush_level &
                ({current_status.rob_flag, current_status.rob_value} ==
                 {flush_rob_flag, flush_rob_value})) | gt);
  end

  // ===========================================================================
  // 3. 唤醒匹配函数:pdest==psrc && srcType.isFp(=srcType[1]) && fpWen [&& valid]
  // ===========================================================================
  function automatic logic match_wb(input wk_wb_t w, input src_status_t s);
    return (w.pdest == s.psrc) & s.src_type[1] & w.fp_wen & w.valid;
  endfunction
  function automatic logic match_iq(input wk_iq_t w, input src_status_t s);
    return (w.pdest == s.psrc) & s.src_type[1] & w.fp_wen;
  endfunction

  // ===========================================================================
  // 4. 唤醒匹配组合逻辑(逐源)——与 FaluFmac 完全一致
  // ===========================================================================
  logic [NUM_REGSRC-1:0][NUM_WK_IQ-1:0] wk_iq_vec;  // 纯匹配(WithoutCancel)
  logic [NUM_REGSRC-1:0][NUM_WK_IQ-1:0] wk_iq_nc;   // 去 og0 取消(仅源 0 不同)
  logic [NUM_REGSRC-1:0][NUM_WK_WB-1:0] wk_wb_vec;  // WB 命中
  logic                                 iq_cancel_sel0;

  always_comb iq_cancel_sel0 = og0cancel[8] & wk_iq[0].is0lat;

  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      for (int i = 0; i < NUM_WK_IQ; i++) begin
        wk_iq_vec[s][i] = match_iq(wk_iq[i], entry_reg.status.src[s]);
        wk_iq_nc[s][i]  = (i == 0) ? (wk_iq_vec[s][0] & ~iq_cancel_sel0) : wk_iq_vec[s][i];
      end
      for (int i = 0; i < NUM_WK_WB; i++)
        wk_wb_vec[s][i] = match_wb(wk_wb[i], entry_reg.status.src[s]);
    end
  end

  logic [NUM_REGSRC-1:0] wakeup_by_iq;
  logic [NUM_REGSRC-1:0] wakeup_by_wb;
  logic [NUM_REGSRC-1:0] wakeup_by_iq_raw;
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      wakeup_by_iq[s]     = |wk_iq_nc[s];
      wakeup_by_wb[s]     = |wk_wb_vec[s];
      wakeup_by_iq_raw[s] = |wk_iq_vec[s];
    end
  end

  // ===========================================================================
  // 5. exuSources 编码:压缩器拓扑与 FaluFmac 同(bit{8,10,12},作 golden 黑盒)
  // ===========================================================================
  logic [NUM_EXU-1:0] exu_comp_in [NUM_REGSRC];
  logic [2:0]         exu_comp_out [NUM_REGSRC];
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      exu_comp_in[s] = '0;
      exu_comp_in[s][8]  = wk_iq_nc[s][0];
      exu_comp_in[s][10] = wk_iq_vec[s][1];
      exu_comp_in[s][12] = wk_iq_vec[s][2];
    end
  end

  genvar gs;
  generate
    for (gs = 0; gs < NUM_REGSRC; gs++) begin : g_exucomp
      UIntCompressor_27_000000000000001010100000000 u_exucomp (
        .io_in  (exu_comp_in[gs]),
        .io_out (exu_comp_out[gs])
      );
    end
  endgenerate

  function automatic logic [EXU_SRC_W-1:0] enc_exu_src(input logic [2:0] c);
    return {|c[2:1], c[2] | c[0]};
  endfunction

  // ===========================================================================
  // 6. 公共控制信号
  // ===========================================================================
  logic deq_success;   // 发射成功(可清条目)
  logic enq_ready;
  logic clear;         // 条目本拍被清(冲刷/成功/转移)
  logic valid_reg_next;

  always_comb begin
    deq_success = issue_resp.valid & (issue_resp.resp == RESP_SUCCESS);
    enq_ready   = ~valid_reg | trans_sel;
    clear       = flushed | deq_success | trans_sel;
    if (IS_ENQ) valid_reg_next = enq_valid & enq_ready ? 1'b1 : (clear ? 1'b0 : valid_reg);
    else        valid_reg_next = enq_valid           ? 1'b1 : (clear ? 1'b0 : valid_reg);
  end

  // ===========================================================================
  // 7. entry_update:条目下一拍状态(未入队时)。即 EntryRegCommonConnect。
  // ===========================================================================
  entry_t entry_update;
  always_comb begin
    entry_update = entry_reg;
    // fuType 紧凑存储只含保留位({FALU,FMAC,FDIV}),enq 后不变,直接沿用
    entry_update.status.fu_type = current_status.fu_type;
    entry_update.status.rob_flag  = current_status.rob_flag;
    entry_update.status.rob_value = current_status.rob_value;

    for (int s = 0; s < NUM_REGSRC; s++) begin
      entry_update.status.src[s].src_state =
        current_status.src[s].src_state | wakeup_by_wb[s] | wakeup_by_iq[s];
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
    end

    // issued(对齐 golden):置位 = deqSel;保持 = ~(响应 block) & 当前 issued。
    entry_update.status.issued =
      deq_sel | (~(issue_resp.valid & (issue_resp.resp == RESP_BLOCK)) & current_status.issued);
    // issueTimer:发射当拍清 0;已发射则 0→1→2→3 饱和;未发射置 3(b11)
    if (deq_sel)
      entry_update.status.issue_timer = 2'h0;
    else if (current_status.issued)
      entry_update.status.issue_timer =
        (current_status.issue_timer == 2'h3) ? current_status.issue_timer
                                             : (current_status.issue_timer + 2'h1);
    else
      entry_update.status.issue_timer = 2'h3;
    // ★ deqPortIdx:deqSel 时写入端口号;否则 issued 才保持,空闲清 0。
    //   对齐 golden:entryUpdate_status_deqPortIdx = deqSel ? deqPortIdxWrite
    //                                                      : (issued & deqPortIdx)。
    entry_update.status.deq_port_idx =
      deq_sel ? deq_port_idx_write : (current_status.issued & current_status.deq_port_idx);
    // payload 保持
    entry_update.payload = entry_reg.payload;
  end

  // ===========================================================================
  // 8. 时序:valid_reg / entry_reg。入队覆写,否则取 entry_update。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) valid_reg <= 1'b0;
    else       valid_reg <= valid_reg_next;
  end

  // EnqEntry 与 OthersEntry 的入队差异:
  //   - OthersEntry:enq 来自 transEntry,issued/issueTimer/deqPortIdx 直接取自 enq.bits。
  //   - EnqEntry  :新 uop 从未发射过,入队拍强制 issued=0 / issueTimer=2'h3 / deqPortIdx=0。
  entry_t enq_load;
  always_comb begin
    enq_load = enq_bits;
    if (IS_ENQ) begin
      enq_load.status.issued       = 1'b0;
      enq_load.status.issue_timer  = 2'h3;
      enq_load.status.deq_port_idx = 1'b0;
    end
  end

  always_ff @(posedge clock) begin
    if (enq_valid & (IS_ENQ ? enq_ready : 1'b1)) entry_reg <= enq_load;
    else                                         entry_reg <= entry_update;
  end

  // ===========================================================================
  // 9. 入队延迟唤醒(仅 IS_ENQ):与 FaluFmac 完全一致
  // ===========================================================================
  generate
  if (IS_ENQ) begin : g_enq_delay
    logic enqd_valid_reg_next;
    always_comb enqd_valid_reg_next = enq_valid & enq_ready;
    always_ff @(posedge clock or posedge reset) begin
      if (reset) enqd_valid_reg <= 1'b0;
      else       enqd_valid_reg <= enqd_valid_reg_next;
    end

    logic [NUM_REGSRC-1:0] d1_wb, d1_iq;
    logic [NUM_REGSRC-1:0][NUM_WK_IQ-1:0] d1_iqvec, d1_iqnc;
    logic d1_cancel0;
    always_comb begin
      d1_cancel0 = enqd1_og0cancel[8] & wk_iq_d1[0].is0lat;
      for (int s = 0; s < NUM_REGSRC; s++) begin
        logic wbhit;
        wbhit = 1'b0;
        for (int i = 0; i < NUM_WK_WB; i++) wbhit |= match_wb(wk_wb_d1[i], entry_reg.status.src[s]);
        d1_wb[s] = wbhit;
        for (int i = 0; i < NUM_WK_IQ; i++) begin
          d1_iqvec[s][i] = match_iq(wk_iq_d1[i], entry_reg.status.src[s]);
          d1_iqnc[s][i]  = (i == 0) ? (d1_iqvec[s][0] & ~d1_cancel0) : d1_iqvec[s][i];
        end
        d1_iq[s] = |d1_iqnc[s];
      end
    end

    logic [NUM_EXU-1:0] d1_exu_in [NUM_REGSRC];
    logic [2:0]         d1_exu_out [NUM_REGSRC];
    logic [EXU_SRC_W-1:0] d1_exu_val [NUM_REGSRC];
    always_comb begin
      for (int s = 0; s < NUM_REGSRC; s++) begin
        d1_exu_in[s] = '0;
        d1_exu_in[s][8]  = d1_iqnc[s][0];
        d1_exu_in[s][10] = d1_iqvec[s][1];
        d1_exu_in[s][12] = d1_iqvec[s][2];
      end
    end
    for (gs = 0; gs < NUM_REGSRC; gs++) begin : g_d1_exucomp
      UIntCompressor_27_000000000000001010100000000 u_d1_exucomp (
        .io_in  (d1_exu_in[gs]),
        .io_out (d1_exu_out[gs])
      );
    end
    always_comb for (int s = 0; s < NUM_REGSRC; s++) d1_exu_val[s] = enc_exu_src(d1_exu_out[s]);

    always_comb begin
      current_status = entry_reg.status;
      for (int s = 0; s < NUM_REGSRC; s++) begin
        current_status.src[s].src_state =
          (enqd_valid_reg & (d1_wb[s] | d1_iq[s])) | entry_reg.status.src[s].src_state;
        current_status.src[s].data_src =
          (enqd_valid_reg & d1_iq[s]) ? DS_BYPASS : entry_reg.status.src[s].data_src;
        current_status.src[s].exu_src =
          enqd_valid_reg ? d1_exu_val[s] : entry_reg.status.src[s].exu_src;
      end
    end
  end else begin : g_others_status
    always_comb current_status = entry_reg.status;
  end
  endgenerate

  // ===========================================================================
  // 10. 组合输出
  // ===========================================================================
  logic [NUM_EXU-1:0] exu_comp_in_raw [NUM_REGSRC];
  logic [2:0]         exu_comp_out_raw [NUM_REGSRC];

  assign o_valid    = valid_reg;
  assign o_issued   = entry_reg.status.issued;
  assign o_enq_ready = enq_ready;
  assign o_issue_timer_read = current_status.issue_timer;
  assign o_deq_port_idx_read = entry_reg.status.deq_port_idx; // golden: deqPortIdxRead = entryReg
  assign o_deq_valid = valid_reg & clear; // entryOutDeqValid = validReg & common_clear

  // canIssue:simp/enq = 全源就绪&未发射&未冲刷;comp 额外允许「本拍唤醒(raw)」提前置位。
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

  // fuType 输出(IQFuType.readFuType:Falu/Fmac/Fdiv)
  always_comb begin
    o_fu_type = unpack_fu_type(current_status.fu_type);
  end

  // dataSources / exuSources 输出
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      if (IS_COMP & wakeup_by_iq_raw[s]) begin
        o_data_src[s] = DS_FORWARD;
        o_exu_src[s]  = enc_exu_src(exu_comp_out_raw[s]);
      end else begin
        o_data_src[s] = current_status.src[s].data_src;
        o_exu_src[s]  = current_status.src[s].exu_src;
      end
    end
  end

  // comp 的输出 exuSources 用「本拍唤醒(raw)」的压缩(源 0 用 raw wakeupVec[0],不去 og0)。
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      exu_comp_in_raw[s] = '0;
      exu_comp_in_raw[s][8]  = wk_iq_vec[s][0];
      exu_comp_in_raw[s][10] = wk_iq_vec[s][1];
      exu_comp_in_raw[s][12] = wk_iq_vec[s][2];
    end
  end
  generate
    for (gs = 0; gs < NUM_REGSRC; gs++) begin : g_exucomp_raw
      UIntCompressor_27_000000000000001010100000000 u_exucomp_raw (
        .io_in  (exu_comp_in_raw[gs]),
        .io_out (exu_comp_out_raw[gs])
      );
    end
  endgenerate

  // o_entry:commonOut.entry.bits。enq 条目用 current_status 覆盖 status。
  always_comb begin
    o_entry = entry_reg;
    if (IS_ENQ) o_entry.status = current_status;
  end

  // transEntry:出队转移携带的「更新后」条目 = entry_update(寄存器次态)。
  assign o_trans_valid = valid_reg & ~flushed & ~current_status.issued;
  always_comb o_trans_entry = entry_update;

endmodule
