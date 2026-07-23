// =============================================================================
// xs_iq_entry_ffmac —— 香山 V2R2(昆明湖) 发射队列「单条目」可读重写 (FaluFmac 变体)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{EntryBundles,EnqEntry,OthersEntry}.scala
// golden 对照:EnqEntry_12.sv(入队条目) / OthersEntry_120.sv(简单条目) / OthersEntry_122.sv(复杂条目)
//
// ★ 这是乱序调度「唤醒-选择」机制的最小单元(浮点 FaluFmac 变体)★
// 发射队列把每条等待发射的 uop 存成一个「条目(entry)」。本模块就是一个条目:它持有
// 一拍寄存的 uop 状态 entry_reg,每拍做两件事:
//   1) 监听唤醒(wakeup):写回总线(WB) + 发射总线(IQ)广播了某个物理寄存器 pdest 产出。
//      若本条目某个源操作数 psrc == 该 pdest 且 srcType.isFp(srcType[1]) && fpWen,则该源置就绪。
//   2) 发射/响应(issue/resp):被选中发射(deqSel)则置 issued;响应阻塞(block)把 issued 退回。
// 当一条目的**全部源就绪 && 未发射**时它「可发射(canIssue)」;复杂条目还能用「本拍唤醒」
// 提前一拍宣告。上层 Entries + AgeDetector 在所有可发射条目里按年龄选最老的发射。
//
// 三种条目变体由参数选择(对应 golden 的三个 leaf 模块):
//   IS_ENQ=1            入队条目(EnqEntry):新 uop 先落这里,带 1 拍「入队延迟唤醒」(enqDelayIn1)。
//   IS_ENQ=0,IS_COMP=0 简单条目(OthersEntry simp):无 canIssueBypass,输出直接取 entry_reg。
//   IS_ENQ=0,IS_COMP=1 复杂条目(OthersEntry comp):有 canIssueBypass(用本拍唤醒提前置可发射),
//                       组合输出口(dataSources/exuSources)按「本拍唤醒(raw)」即时前递。
//
// ★ 与 AluCsrFenceDiv 样板相比,本变体省去了所有 load 相关机制 ★
//   无 LoadShouldCancel / srcLoadCancel / srcLoadTransCancel / loadDependency,
//   无 RegCache,无 imm,无双 deq 端口。og0Cancel 仅作用于 IQ 唤醒源 0(og0Cancel[8])。
//
// 关键时序/X 处理:
//   * 全部状态在 entry_reg 里,复位无关(firtool 随机初始化,综合下为 X)。UT 用
//     `!$isunknown` 跳过复位后未写过的条目。
//   * exuSources 的「唤醒源 OH → 源序号」编码,golden 用 UIntCompressor 把 27 位全局
//     EXU one-hot 压成本 IQ 的 3 路(bit{8,10,12})再优先编码。该压缩器拓扑与配置绑定,
//     这里**作 golden 黑盒例化**(见 u_exucomp_*),只重写其外围的唤醒匹配/选择逻辑。
// =============================================================================
module xs_iq_entry_ffmac import iq_ffmac_pkg::*; #(
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
  input  logic                         deq_sel,         // 本条目被选中发射
  input  deq_resp_t                    issue_resp,      // 发射响应(block/success)
  input  logic                         trans_sel,       // 本条目被转移到 comp/simp 条目(出队)

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
  output logic                         o_enq_ready,
  output logic                         o_trans_valid,
  output entry_t                       o_trans_entry // commonOut.transEntry.bits(=entry_update)
);

  // ===========================================================================
  // 0. 寄存器:条目本体 + valid。所有条目状态都在这里。
  // ===========================================================================
  entry_t entry_reg;
  logic   valid_reg;
  logic   enqd_valid_reg; // 仅 IS_ENQ:入队后下一拍为高,标志「入队延迟唤醒」窗口

  // ===========================================================================
  // 1. 当前状态 current_status
  //    - OthersEntry:直接用 entry_reg.status。
  //    - EnqEntry:入队后下一拍(enqd_valid_reg)用「入队延迟唤醒」结果覆盖 srcState/
  //      dataSources/exuSources(见 §11),其余仍取 entry_reg.status。
  // ===========================================================================
  status_t current_status;

  // ===========================================================================
  // 2. 冲刷判定 flushed:本条目的 robIdx 是否落在被冲刷区间(环形指针比较)。
  //    needFlush = flush.valid && (level&&相等 || flag^flag ^ value>value)
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
  //    WB 唤醒带 valid;IQ 唤醒无 valid(valid 隐含在 fpWen / 总线常驻里)。
  // ===========================================================================
  function automatic logic match_wb(input wk_wb_t w, input src_status_t s);
    return (w.pdest == s.psrc) & s.src_type[1] & w.fp_wen & w.valid;
  endfunction
  function automatic logic match_iq(input wk_iq_t w, input src_status_t s);
    return (w.pdest == s.psrc) & s.src_type[1] & w.fp_wen;
  endfunction

  // ===========================================================================
  // 4. 唤醒匹配组合逻辑(逐源)
  //    wk_iq_vec[s][i] : 源 s 被 IQ 唤醒源 i 命中(纯匹配,未去 og0 取消)
  //    iq_cancel_sel   : 仅 IQ 唤醒源 0 可被 og0 取消(og0cancel[8] && is0Lat)
  //    wk_iq_nc[s][0]  : 去掉 og0 取消后的源 0 命中(srcWakeupByIQ);源 1/2 无 og0,直接用 raw。
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

  // wakeupByIQ:源 s 本拍被 IQ 唤醒(去 og0 取消的命中);wakeupByWB:被任一 WB 命中。
  // wakeup_by_iq_raw:任一源被任一 IQ 源命中(含被 og0 取消的源 0)= dataSources 输出门控。
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
  // 5. exuSources 编码:把「唤醒 OH」(3 路)按 BackendParams 映射回全局 EXU 空间
  //    (bit{8,10,12})再压缩成 2 位源序号。压缩器拓扑与配置绑定,作 golden 黑盒例化。
  //    golden 布局:{14'h0, IQ2, 1'h0, IQ1, 1'h0, IQ0, 8'h0} → bit8=IQ0,bit10=IQ1,bit12=IQ2。
  //    输出编码:{|out[2:1], out[2]|out[0]}。
  // ===========================================================================
  // reg 更新路用「去 og0 取消」的命中(源 0 用 wk_iq_nc[s][0],源 1/2 同 raw)。
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
  logic clear;         // 条目本拍被清(冲刷/成功)
  logic valid_reg_next;

  always_comb begin
    // common_clear = flushed | (issueResp.valid && resp==SUCCESS)。(无 trans 在 clear 里)
    deq_success = issue_resp.valid & (issue_resp.resp == RESP_SUCCESS);
    enq_ready   = ~valid_reg | trans_sel;
    clear       = flushed | deq_success | trans_sel;
    // golden validReg 次态:enq_valid | ~common_clear & validReg。trans_sel 通过 clear 清空。
    if (IS_ENQ) valid_reg_next = enq_valid & enq_ready ? 1'b1 : (clear ? 1'b0 : valid_reg);
    else        valid_reg_next = enq_valid           ? 1'b1 : (clear ? 1'b0 : valid_reg);
  end

  // ===========================================================================
  // 7. entry_update:条目下一拍状态(未入队时)。即 EntryRegCommonConnect。
  //    注意 dataSources 更新用 wakeupByIQ(去 og0 取消),其余源类型/exu 同理。
  // ===========================================================================
  entry_t entry_update;
  always_comb begin
    entry_update = entry_reg;
    // fuType 紧凑存储只含保留位({FALU,FMAC}),enq 后不变,直接沿用
    // (等价于 golden 的"清零其余位后仅回写 FALU/FMAC")。
    entry_update.status.fu_type = current_status.fu_type;
    entry_update.status.rob_flag  = current_status.rob_flag;
    entry_update.status.rob_value = current_status.rob_value;

    for (int s = 0; s < NUM_REGSRC; s++) begin
      // srcState:被 WB/IQ 唤醒置就绪(无 load 取消)。golden: reg | (|wbHit) | (|wakeupByIQ)。
      entry_update.status.src[s].src_state =
        current_status.src[s].src_state | wakeup_by_wb[s] | wakeup_by_iq[s];
      entry_update.status.src[s].src_type = current_status.src[s].src_type;
      entry_update.status.src[s].psrc     = current_status.src[s].psrc;
      // dataSources:被 IQ 唤醒→bypass(2);原本是 bypass(2)→reg(8);否则保持。
      if (wakeup_by_iq[s])
        entry_update.status.src[s].data_src = DS_BYPASS;
      else if (current_status.src[s].data_src == DS_BYPASS)
        entry_update.status.src[s].data_src = DS_REG;
      else
        entry_update.status.src[s].data_src = current_status.src[s].data_src;
      // exuSources:有 IQ 唤醒命中(去 og0 取消)才更新(否则保持)。
      if (|wk_iq_nc[s])
        entry_update.status.src[s].exu_src = enc_exu_src(exu_comp_out[s]);
      else
        entry_update.status.src[s].exu_src = current_status.src[s].exu_src;
    end

    // issued(对齐 golden):置位 = deqSel;保持 = ~(响应 block) & 当前 issued。(无 load 取消)
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
  //   - OthersEntry:enq 来自 transEntry,issued/issueTimer 直接取自 enq.bits。
  //   - EnqEntry  :新 uop 从未发射过,golden 在入队拍强制 issued=0 / issueTimer=2'h3。
  entry_t enq_load;
  always_comb begin
    enq_load = enq_bits;
    if (IS_ENQ) begin
      enq_load.status.issued      = 1'b0;
      enq_load.status.issue_timer = 2'h3;
    end
  end

  always_ff @(posedge clock) begin
    if (enq_valid & (IS_ENQ ? enq_ready : 1'b1)) entry_reg <= enq_load;
    else                                         entry_reg <= entry_update;
  end

  // ===========================================================================
  // 9. 入队延迟唤醒(仅 IS_ENQ):入队后下一拍,用 enqDelayIn1 总线再唤醒一次,覆盖
  //    current_status 的 srcState/dataSources/exuSources。
  // ===========================================================================
  generate
  if (IS_ENQ) begin : g_enq_delay
    logic enqd_valid_reg_next;
    always_comb enqd_valid_reg_next = enq_valid & enq_ready;
    always_ff @(posedge clock or posedge reset) begin
      if (reset) enqd_valid_reg <= 1'b0;
      else       enqd_valid_reg <= enqd_valid_reg_next;
    end

    // delay1 唤醒匹配(对 entry_reg.status,入队后下一拍 entry_reg 已是新 uop)。
    //   d1_wbhit[s] : 源 s 被任一 delay1 WB 源命中
    //   d1_iqvec    : 源 s 被 delay1 IQ 源 i 命中(纯匹配);源 0 去 og0 取消(cancelSel_0_1)
    //   d1_iq[s]    : srcWakeUpByIQ = |{vec2, vec1, vec0_nc}
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

    // enqDelay exuSources:用压缩器把 delay1 命中 OH 编码成 2 位源序号(同 §5 拓扑)。
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

    // current_status:enqd 窗口内用 delay1 唤醒覆盖 srcState/dataSources/exuSources。
    // golden:srcState = enqdValid & (wbHit | iqHit) | reg.srcState(注意是 AND 在 enqdValid 上)。
    always_comb begin
      current_status = entry_reg.status;
      for (int s = 0; s < NUM_REGSRC; s++) begin
        current_status.src[s].src_state =
          (enqd_valid_reg & (d1_wb[s] | d1_iq[s])) | entry_reg.status.src[s].src_state;
        // dataSources:_GEN = enqdValid & iqHit → bypass(2),否则保持 reg。
        current_status.src[s].data_src =
          (enqd_valid_reg & d1_iq[s]) ? DS_BYPASS : entry_reg.status.src[s].data_src;
        // exuSources:enqdValid 时取压缩结果,否则保持 reg(golden 三元在 enqdValid 上)。
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
  // —— comp 输出用「本拍唤醒(raw)」的 exuSources 压缩(声明在使用前)——
  logic [NUM_EXU-1:0] exu_comp_in_raw [NUM_REGSRC];
  logic [2:0]         exu_comp_out_raw [NUM_REGSRC];

  assign o_valid    = valid_reg;
  assign o_issued   = entry_reg.status.issued;
  assign o_enq_ready = enq_ready;
  assign o_issue_timer_read = current_status.issue_timer;
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

  // fuType 输出:紧凑存储复原成 35 位 one-hot(未保留位为 0,IQFuType.readFuType)
  always_comb begin
    o_fu_type = unpack_fu_type(current_status.fu_type);
  end

  // dataSources / exuSources 输出
  //   comp:本拍有 IQ 唤醒(raw)→ dataSources=forward(1)、exuSources=raw 压缩;否则取 reg。
  //   simp/enq:直接取 current_status(simp 即 entry_reg;enq 即 enqDelay 覆盖后)。
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

  // o_entry:commonOut.entry.bits。enq 条目用 current_status 覆盖 status(其余= entry_reg)。
  // 注意:golden commonOut.entry 只带 psrc/srcType(不带 srcState/dataSources/exuSources),
  //   但本结构整字段输出;转移时由 Entries 顶层从 transEntry 取完整 status,故此处无害。
  always_comb begin
    o_entry = entry_reg;
    if (IS_ENQ) o_entry.status = current_status;
  end

  // transEntry:出队转移到 comp/simp 时携带的「更新后」条目 = entry_update(寄存器次态)。
  // valid = valid && !flushed && !issued。
  assign o_trans_valid = valid_reg & ~flushed & ~current_status.issued;
  always_comb o_trans_entry = entry_update;

endmodule
