// =============================================================================
// xs_iq_entry_acfd —— 香山 V2R2(昆明湖) 发射队列「单条目」可读重写 (AluCsrFenceDiv 变体)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{EntryBundles,EnqEntry,OthersEntry}.scala
// golden 对照:EnqEntry_6.sv(入队条目) / OthersEntry_66.sv(简单条目) / OthersEntry_72.sv(复杂条目)
//
// ★ 这是乱序调度「唤醒-选择」机制的最小单元 ★
// 发射队列把每条等待发射的 uop 存成一个「条目(entry)」。本模块就是一个条目:它持有
// 一拍寄存的 uop 状态 entry_reg,每拍做三件事:
//   1) 监听唤醒(wakeup):写回总线(WB) + 发射总线(IQ)广播了某个物理寄存器 pdest 产出。
//      若本条目某个源操作数的 psrc == 该 pdest 且类型匹配(整数 rfWen),则该源被唤醒置就绪。
//   2) 取消(cancel):被唤醒的源若依赖了一条「后来被判失败的 load」(load 推测唤醒),
//      要按 load 依赖移位寄存器 + ldCancel 把该源「撤销就绪」;0 周期旁路源还要看 og0Cancel。
//   3) 发射/响应(issue/resp):被选中发射(deqSel)则置 issued;发射响应失败(block)或被
//      load 取消则把 issued 退回,允许重发。
// 当一条目的**全部源就绪 && 未发射 && 未阻塞**时,它「可发射(canIssue)」;上层 Entries +
// AgeDetector 在所有可发射条目里按**年龄**选最老的发射。
//
// 三种条目变体由参数选择(对应 golden 的三个 leaf 模块):
//   IS_ENQ=1            入队条目(EnqEntry):新 uop 先落这里,带 2 拍「入队延迟唤醒」流水,
//                       处理 uop 在进队列的气泡期间到达的唤醒(enqDelayIn1/In2)。
//   IS_ENQ=0,IS_COMP=0 简单条目(OthersEntry simp):无 canIssueBypass,输出用「已取消」的唤醒。
//   IS_ENQ=0,IS_COMP=1 复杂条目(OthersEntry comp):有 canIssueBypass(用未取消的唤醒提前
//                       一拍宣告可发射),组合输出口(dataSources/exuSources/cancelBypass/
//                       srcLoadDependency)按「未取消的唤醒(WithoutCancel)」即时前递。
//
// 关键时序/X 处理:
//   * 全部状态在 entry_reg 里,复位无关(firtool 用随机初始化,综合下为 X)。UT 用
//     `!$isunknown` 跳过复位后未写过的条目。
//   * exuSources 的「唤醒源 OH → 源序号」编码,golden 用 UIntCompressor(把 27 位全局
//     EXU one-hot 压成本 IQ 的 7 路再优先编码)。该压缩器拓扑与 BackendParams 绑定,
//     这里**作 golden 黑盒例化**(见 u_exucomp_*),只重写其外围的唤醒匹配/选择逻辑。
// =============================================================================
module xs_iq_entry_acfd import iq_acfd_pkg::*; #(
  parameter bit IS_ENQ  = 1'b0,  // 是否入队条目(带 enqDelay 流水)
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
  input  wk_wb_t [NUM_WK_WB-1:0]       wk_wb,   // 写回唤醒(仅 rfWen)
  input  wk_iq_t [NUM_WK_IQ-1:0]       wk_iq,   // 发射唤醒(rfWen + loadDep + is0Lat + rcDest)

  // ---- 入队延迟唤醒(仅 IS_ENQ 用):同一总线打 1 拍 / 2 拍 ----
  input  wk_wb_t [NUM_WK_WB-1:0]       wk_wb_d1,
  input  wk_iq_t [NUM_WK_IQ-1:0]       wk_iq_d1,
  input  logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] enqd1_src_ld,   // RegEnable 后的入队源 load 依赖
  input  logic [NUM_EXU-1:0]           enqd1_og0cancel,            // RegNext(og0Cancel)
  input  ld_cancel_t [LDPW-1:0]        enqd1_ldcancel,             // RegNext(ldCancel)
  input  wk_wb_t [NUM_WK_WB-1:0]       wk_wb_d2,
  input  wk_iq_t [NUM_WK_IQ-1:0]       wk_iq_d2,
  input  logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] enqd2_src_ld,   // DelayN(...,2)
  input  logic [NUM_EXU-1:0]           enqd2_og0cancel,
  input  ld_cancel_t [LDPW-1:0]        enqd2_ldcancel,

  // ---- 取消 ----
  input  logic [NUM_EXU-1:0]           og0cancel,  // og0 阶段取消(按全局 EXU 号)
  input  logic [NUM_EXU-1:0]           og1cancel,  // og1 阶段取消(本变体条目逻辑未用,IQ 顶层用)
  input  ld_cancel_t [LDPW-1:0]        ldcancel,   // 各 load 流水道两级取消

  // ---- 发射选择 / 响应 / 转移 ----
  input  logic                         deq_sel,         // 本条目被选中发射
  input  logic                         deq_port_write,  // 发射走的 deq 端口
  input  deq_resp_t                    issue_resp,      // 发射响应(block/success)
  input  logic                         trans_sel,       // 本条目被转移到 comp/simp 条目(出队)

  // ---- 状态输出 ----
  output logic                         o_valid,
  output logic                         o_issued,
  output logic                         o_can_issue,
  output logic [FU_NUM-1:0]            o_fu_type,
  output logic [NUM_REGSRC-1:0][3:0]   o_data_src,   // dataSources[src].value
  output logic [NUM_REGSRC-1:0][2:0]   o_exu_src,    // exuSources[src].value
  output entry_t                       o_entry,      // commonOut.entry.bits(=entry_reg, enq 条目用 currentStatus)
  output logic                         o_cancel_bypass,
  output logic                         o_deq_port_read,
  output logic [1:0]                   o_issue_timer_read,
  output logic                         o_enq_ready,
  output logic                         o_trans_valid,
  output entry_t                       o_trans_entry // commonOut.transEntry.bits(=entryUpdate)
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
  //      dataSources/loadDep/regcache(见 §7),其余仍取 entry_reg.status。
  // ===========================================================================
  status_t current_status;

  // ===========================================================================
  // 2. 冲刷判定 flushed:本条目的 robIdx 是否落在被冲刷区间(环形指针比较)。
  //    needFlush = flush.valid && (level&&相等 || flag^flag ^ value>value)
  // ===========================================================================
  logic flushed;
  always_comb begin
    logic gt; // robIdx「更年轻」比较:flag 相同则 value 大者新,flag 不同则 value 小者新
    gt = (current_status.rob_flag ^ flush_rob_flag) ^ (current_status.rob_value > flush_rob_value);
    flushed = flush_valid & ((flush_level &
                ({current_status.rob_flag, current_status.rob_value} ==
                 {flush_rob_flag, flush_rob_value})) | gt);
  end

  // ===========================================================================
  // 3. load 取消:LoadShouldCancel。本 IQ 只接 ld2Cancel(ld1Cancel 全局未接)。
  //    某依赖向量 dep 被取消 = OR_pipe( ldcancel[pipe].ld2 & dep[pipe][1] )。
  // ===========================================================================
  function automatic logic load_should_cancel(input logic [LDPW-1:0][LDW-1:0] dep,
                                              input ld_cancel_t [LDPW-1:0] ldc);
    logic c;
    c = 1'b0;
    for (int p = 0; p < LDPW; p++) c |= ldc[p].ld2_cancel & dep[p][1];
    return c;
  endfunction

  // ===========================================================================
  // 4. 唤醒匹配函数:pdest==psrc && srcType.isXp(=srcType[0]) && rfWen [&& valid]
  //    WB 唤醒带 valid;IQ 唤醒无 valid(总线常驻,valid 隐含在 rfWen 里)。
  // ===========================================================================
  function automatic logic match_wb(input wk_wb_t w, input src_status_t s);
    return (w.pdest == s.psrc) & s.src_type[0] & w.rf_wen & w.valid;
  endfunction
  function automatic logic match_iq(input wk_iq_t w, input src_status_t s);
    return (w.pdest == s.psrc) & s.src_type[0] & w.rf_wen;
  endfunction

  // 把 IQ 唤醒源的 loadDependency 左移 1 位(shiftedWakeupLoadDependency)。本变体唤醒源
  // 都不是 load EXU(load 自身那一路会被钉成常量 1),故一律 << 1。golden:{dep[0],1'h0}。
  function automatic logic [LDW-1:0] shift_dep(input logic [LDW-1:0] d);
    return {d[0], 1'b0};
  endfunction

  // ===========================================================================
  // 5. 唤醒/取消组合逻辑(逐源)
  //    wk_iq_vec[s][i]   : 源 s 是否被 IQ 唤醒源 i 命中(纯匹配,未去 cancel)
  //    iq_cancel_sel[i]  : 唤醒源 i 是否被 og0 取消(og0cancel[exuIdx] && is0Lat)
  //    wk_iq_nc[s][i]    : 去掉 og0 取消后的命中(srcWakeupByIQ)
  //    本变体 og0Cancel 实际命中位:源0→og0[0]&is0Lat, 源1→og0[2]&is0Lat,
  //    源2→og0[4], 源3→og0[6], 源4..6 无 og0 取消(golden 实测)。
  // ===========================================================================
  logic [NUM_REGSRC-1:0][NUM_WK_IQ-1:0] wk_iq_vec;    // 纯匹配(WithoutCancel)
  logic [NUM_REGSRC-1:0][NUM_WK_IQ-1:0] wk_iq_nc;     // 去 og0 取消
  logic [NUM_WK_IQ-1:0]                 iq_cancel_sel;
  logic [NUM_REGSRC-1:0][NUM_WK_WB-1:0] wk_wb_vec;    // WB 命中

  // og0Cancel 对各唤醒源的取消位(源 i 对应的全局 EXU 号 + 是否 0 延迟)
  // 与 golden 完全一致:仅源 0/1 有 is0Lat,源 0..3 才被 og0 取消。
  always_comb begin
    iq_cancel_sel = '0;
    iq_cancel_sel[0] = og0cancel[0] & wk_iq[0].is0lat;
    iq_cancel_sel[1] = og0cancel[2] & wk_iq[1].is0lat;
    iq_cancel_sel[2] = og0cancel[4];
    iq_cancel_sel[3] = og0cancel[6];
    // 源 4/5/6:无 og0 取消(对应 EXU 不是 0 延迟旁路源)
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

  // srcLoadTransCancel:被 IQ 唤醒的源,其(唤醒源的)load 依赖是否要取消该次唤醒。
  // = OR_i ( wk_iq_vec[s][i] && load_should_cancel(wk_iq[i].ld_dep, ldcancel) )
  logic [NUM_REGSRC-1:0] src_ld_trans_cancel;
  // srcLoadCancel:本条目当前持有的(已寄存的)源 load 依赖被取消(cancelBypassVec)。
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

  // wakeupByIQ:源 s 本拍被 IQ 有效唤醒(去 og0 取消)且未被 load 撤销。
  logic [NUM_REGSRC-1:0] wakeup_by_iq;
  logic [NUM_REGSRC-1:0] wakeup_by_wb;
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      wakeup_by_iq[s] = (|wk_iq_nc[s]) & ~src_ld_trans_cancel[s];
      wakeup_by_wb[s] = |wk_wb_vec[s];
    end
  end

  // ===========================================================================
  // 6. exuSources 编码:把「未取消的唤醒 OH」(7 路)按 BackendParams 映射回全局 EXU
  //    空间再压缩成 3 位源序号。该压缩器拓扑与配置绑定,作 golden 黑盒例化。
  //    输入布局严格对齐 golden:bit{0,2,4,6}=源{0,1,2,3}, bit{20,21,22}=源{4,5,6}。
  // ===========================================================================
  // 进入压缩器的 OH:reg 更新路径用 srcWakeupByIQ(去 og0 取消, 即 wk_iq_nc);
  // 注意源 4/5/6 无 og0 取消, wk_iq_nc==wk_iq_vec, 这里统一用 wk_iq_nc。
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

  // 把压缩器 7 位输出按 golden 的 T_17/T_22 优先编码成 3 位源序号。
  function automatic logic [2:0] enc_exu_src(input logic [6:0] c);
    logic [2:0] t17;
    t17 = c[6:4] | c[2:0];
    return {|c[6:3], |t17[2:1], t17[2] | t17[0]};
  endfunction

  // wakeup_by_iq_raw:任一源被任一 IQ 源命中(含被 og0 取消的, = srcWakeupByIQWithoutCancel)
  logic [NUM_REGSRC-1:0] wakeup_by_iq_raw;
  always_comb
    for (int s = 0; s < NUM_REGSRC; s++) wakeup_by_iq_raw[s] = |wk_iq_vec[s];

  // ===========================================================================
  // 7. RegCache:被任一 IQ 源唤醒且本源是整数 → 取该唤醒源的 rcDest 作新索引(wakeupRC);
  //    若该源原 regcache 索引被某个写回 rfWen 的源覆盖(replaceRC)则失效。
  // ===========================================================================
  logic [NUM_REGSRC-1:0]            wakeup_rc;
  logic [NUM_REGSRC-1:0][RC_IDX_W-1:0] wakeup_rc_idx;
  logic [NUM_REGSRC-1:0]            replace_rc;
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      logic [RC_IDX_W-1:0] idx;
      logic rep;
      // wakeupRC 用「去 og0 取消」的命中(wk_iq_nc:源 0..3 去 og0,源 4..6 本就无 og0),
      // 不是用于输出前递的 raw 命中。
      wakeup_rc[s] = (|wk_iq_nc[s]) & current_status.src[s].src_type[0];
      idx = '0; rep = 1'b0;
      // replaceRC 比对当前(enqd 窗口可能被改写的)regCacheIdx,故用 current_status
      for (int i = 0; i < NUM_WK_IQ; i++) begin
        if (wk_iq_nc[s][i]) idx |= wk_iq[i].rc_dest;
        rep |= wk_iq[i].rf_wen & (wk_iq[i].rc_dest == current_status.src[s].rc_idx);
      end
      wakeup_rc_idx[s] = idx;
      replace_rc[s] = rep;
    end
  end

  // ===========================================================================
  // 8. shiftedWakeupLoadDependency:被 IQ 唤醒时,源的 load 依赖换成「唤醒源的依赖<<1」
  //    (Mux1H over wk_iq_nc);否则自增移位(自身 dep<<1)。
  // ===========================================================================
  logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] wk_shift_dep; // Mux1H(wk_iq_nc, shifted wk dep)
  logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] self_shift_dep; // 自身 dep<<1
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      for (int p = 0; p < LDPW; p++) begin
        logic [LDW-1:0] acc;
        acc = '0;
        // 源 0..3:用去 og0 取消命中(wk_iq_nc)的依赖<<1;源 4..6 无 loadDep 端口,但其命中
        // 要把「该 load 流水道自身位」钉进对应 pipe 的 bit0(src4→p0, src5→p1, src6→p2)。
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
  logic deq_success;   // 发射成功(可清条目)
  logic resp_fail;     // 发射响应阻塞(issued 退回)
  logic enq_ready;
  logic clear;         // 条目本拍被清(冲刷/成功/转移)
  logic valid_reg_next;

  // 逐源 cancelBypass:comp 在「未取消唤醒」命中时用 transCancel,否则用 srcLoadCancel(已存依赖)。
  // simp/enq 一律 srcLoadCancel。用于 issued 的 deqSel-置位门控(与 cancelBypass 输出同源)。
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
  // 10. entry_update:条目下一拍状态(未入队时)。即 EntryRegCommonConnect。
  // ===========================================================================
  entry_t entry_update;
  always_comb begin
    entry_update = entry_reg;
    // fuType 只保留本变体相关位(IQFuType.readFuType)
    entry_update.status.fu_type = '0;
    entry_update.status.fu_type[FU_ALU]   = current_status.fu_type[FU_ALU];
    entry_update.status.fu_type[FU_CSR]   = current_status.fu_type[FU_CSR];
    entry_update.status.fu_type[FU_FENCE] = current_status.fu_type[FU_FENCE];
    entry_update.status.fu_type[FU_DIV]   = current_status.fu_type[FU_DIV];
    entry_update.status.rob_flag  = current_status.rob_flag;
    entry_update.status.rob_value = current_status.rob_value;

    for (int s = 0; s < NUM_REGSRC; s++) begin
      // srcState:被 load 取消则清,被 WB/IQ 唤醒则置(ignoreOldVd 本变体恒 0)
      entry_update.status.src[s].src_state =
        (current_status.src[s].src_state & ~src_ld_cancel[s]) | wakeup_by_wb[s] | wakeup_by_iq[s];
      entry_update.status.src[s].src_type = current_status.src[s].src_type; // ignoreOldVd=0
      entry_update.status.src[s].psrc     = current_status.src[s].psrc;
      // dataSources:被 IQ 唤醒→bypass;原本是 bypass(4'h2)→reg(4'h8);否则保持
      if (wakeup_by_iq[s])
        entry_update.status.src[s].data_src = DS_BYPASS;
      else if (current_status.src[s].data_src == DS_BYPASS)
        entry_update.status.src[s].data_src = DS_REG;
      else
        entry_update.status.src[s].data_src = current_status.src[s].data_src;
      // exuSources:有未取消唤醒命中才更新(否则保持)
      if (|wk_iq_nc[s])
        entry_update.status.src[s].exu_src = enc_exu_src(exu_comp_out[s]);
      else
        entry_update.status.src[s].exu_src = current_status.src[s].exu_src;
      // srcLoadDependency:被 IQ 唤醒用唤醒源依赖<<1,否则自身<<1。
      // 用 if/else(而非三元)以匹配 golden 的 `if (wakeupByIQ)`:当 wakeupByIQ 为 X(空条目
      // psrc 为 X 时),Verilog 取 else 分支 → 自身<<1,使空条目 ld_dep 仍随移位收敛到 0。
      for (int p = 0; p < LDPW; p++)
        if (wakeup_by_iq[s]) entry_update.status.src[s].ld_dep[p] = wk_shift_dep[s][p];
        else                 entry_update.status.src[s].ld_dep[p] = self_shift_dep[s][p];
      // RegCache
      entry_update.status.src[s].use_rc =
        (current_status.src[s].use_rc & ~(src_ld_cancel[s] | replace_rc[s])) | wakeup_rc[s];
      entry_update.status.src[s].rc_idx =
        wakeup_rc[s] ? wakeup_rc_idx[s] : current_status.src[s].rc_idx;
    end

    entry_update.status.blocked = 1'b0;
    // issued(对齐 golden 的 OR 形式):
    //   置位 = deqSel & 无 cancelBypass(comp 用 transCancel 形式);
    //   保持 = ~(srcLoadCancel 任一 | 响应 block) & 当前 issued。
    entry_update.status.issued =
      (deq_sel & ~(|cancel_bypass_vec))
      | (~((|src_ld_cancel) | resp_fail) & current_status.issued);
    entry_update.status.first_issue = deq_sel | current_status.first_issue;
    // issueTimer:发射当拍清 0;已发射则 0→1→2→3 饱和;未发射置 3(b11)
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
    // imm/payload 保持
    entry_update.imm     = entry_reg.imm;
    entry_update.payload = entry_reg.payload;
  end

  // ===========================================================================
  // 11. 时序:valid_reg / entry_reg。入队覆写,否则取 entry_update。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) valid_reg <= 1'b0;
    else       valid_reg <= valid_reg_next;
  end

  // EnqEntry 与 OthersEntry 的入队差异(见 EnqEntry.scala / OthersEntry 的 RTL):
  //   - OthersEntry:enq 来自 transEntry,issued/issueTimer/deqPortIdx 直接取自 enq.bits。
  //   - EnqEntry  :新 uop 从未发射过,golden 在入队拍强制 issued=0 / deqPortIdx=0 /
  //                issueTimer=2'h3(外部 enq.bits 不含这三个字段)。其余数据字段照常取 enq.bits。
  entry_t enq_load;
  always_comb begin
    enq_load = enq_bits;
    if (IS_ENQ) begin
      enq_load.status.issued      = 1'b0;
      enq_load.status.deq_port    = 1'b0;
      enq_load.status.issue_timer = 2'h3;
      enq_load.status.first_issue = 1'b0;
      enq_load.status.blocked     = 1'b0;
    end
  end

  always_ff @(posedge clock) begin
    if (enq_valid & (IS_ENQ ? enq_ready : 1'b1)) entry_reg <= enq_load;
    else                                         entry_reg <= entry_update;
  end

  // ===========================================================================
  // 12. 入队延迟唤醒(仅 IS_ENQ):入队后下一拍,用 delay1 总线再唤醒一次,覆盖
  //     current_status。delay 路与当拍路同构(EnqDelayWakeupConnect),这里实现
  //     delay1(主)逻辑;delay2 主要影响 dataSources/exuSources,本变体整数路
  //     dataSources 仅取 bypass,故 delay1 已覆盖 srcState/loadDep/regcache。
  //     完整 delay2 的 dataSources 细化见下方 generate(IS_ENQ)。
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
    //   d1_iqvec[s][i] : 源 s 被 delay1 IQ 源 i 命中(纯匹配, i=0..6)
    //   d1_iqnc[s][i]  : i=0..3 去 og0 取消(cancelSel);i=4..6 无 og0 取消
    //   d1_iq4[s]      : 源 s 被 delay1 IQ 源 4/5/6 命中(无 loadDep / 无 og0 取消)
    //   d1_iq[s]       : srcWakeUpByIQ = (|全部 7 路命中) & ~loadCancel(仅 0..3 有 loadDep)
    //   d1_iq2[s]      : srcWakeUpByIQVec OR(=_GEN_2, 不经 loadCancel)→ 用于 ld_dep 更新门控
    logic [NUM_REGSRC-1:0] d1_wb, d1_iq, d1_iq2;
    logic [NUM_REGSRC-1:0][NUM_WK_IQ-1:0] d1_iqvec, d1_iqnc;
    logic [NUM_WK_IQ-1:0] d1_cancel;
    logic [NUM_REGSRC-1:0] d1_ldcancel;       // enqDelaySrcLoadDependency 被 ld 取消
    logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] d1_shift_dep; // vec0..3 的 shifted dep OR
    logic [NUM_REGSRC-1:0] d1_wakeup_rc;
    logic [NUM_REGSRC-1:0] d1_replace_rc;
    logic [NUM_REGSRC-1:0][RC_IDX_W-1:0] d1_rc_idx;
    always_comb begin
      d1_cancel = '0;
      d1_cancel[0] = enqd1_og0cancel[0] & wk_iq_d1[0].is0lat;
      d1_cancel[1] = enqd1_og0cancel[2] & wk_iq_d1[1].is0lat;
      d1_cancel[2] = enqd1_og0cancel[4];
      d1_cancel[3] = enqd1_og0cancel[6];
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
          // loadCancel 仅源 0..3 有 loadDependency(4..6 的 ld_dep 恒 0)。
          // 必须用「去 og0 取消」的命中 d1_iqnc(=golden 的 enqDelayOut1_srcWakeUpByIQVec,
          //   该 vec 已含 ~cancelSel);否则被 og0 取消的源仍会错误地触发 load-trans-cancel,
          //   把本应有效的 delay1 唤醒(如源 6)误撤销 → dataSources/currentStatus 分叉。
          if (i < 4) ldtc |= d1_iqnc[s][i] & load_should_cancel(wk_iq_d1[i].ld_dep, enqd1_ldcancel);
          // replaceRC:任一 IQ 源 rfWen 且 rcDest 命中本源已存 regCacheIdx
          rep |= wk_iq_d1[i].rf_wen & (wk_iq_d1[i].rc_dest == entry_reg.status.src[s].rc_idx);
        end
        // WakeupRCIdx:源 0..3 用去 cancel 命中(d1_iqnc),源 4..6 用纯命中(d1_iqvec)
        for (int i = 0; i < 4; i++)       if (d1_iqnc[s][i]) idx |= wk_iq_d1[i].rc_dest;
        for (int i = 4; i < NUM_WK_IQ; i++) if (d1_iqvec[s][i]) idx |= wk_iq_d1[i].rc_dest;
        d1_replace_rc[s] = rep;
        // _GEN_2 / WakeupRC 用 srcWakeUpByIQVec:源 0..3 去 og0 取消(d1_iqnc),源 4..6 纯命中。
        d1_iq2[s] = (|d1_iqnc[s][3:0]) | d1_iqvec[s][4] | d1_iqvec[s][5] | d1_iqvec[s][6];
        d1_iq[s]  = d1_iq2[s] & ~ldtc;            // srcWakeUpByIQ:再去 loadCancel(仅 0..3 有 dep)
        d1_ldcancel[s] = load_should_cancel(enqd1_src_ld[s], enqd1_ldcancel);
        // shiftedWakeupLoadDependency:vec 0..3 各自 dep<<1 的 OR;源 4/5/6 命中则在
        // pipe{0,1,2} 的 bit0 各 OR 入命中位(load 源自身 pipe 钉 1)。
        for (int p = 0; p < LDPW; p++) begin
          logic [LDW-1:0] acc; acc = '0;
          for (int i = 0; i < 4; i++) if (d1_iqnc[s][i]) acc |= shift_dep(wk_iq_d1[i].ld_dep[p]);
          acc |= {1'b0, d1_iqvec[s][4 + p]};      // src4→p0, src5→p1, src6→p2
          d1_shift_dep[s][p] = acc;
        end
        d1_wakeup_rc[s] = d1_iq2[s] & entry_reg.status.src[s].src_type[0];
        d1_rc_idx[s] = idx;
      end
    end

    // enqDelay exuSources:用压缩器把 delay1 命中 OH 编码成 3 位源序号(同 §6 拓扑)。
    // 输入用 srcWakeUpByIQVec(vec0..3 去 og0 取消)+ wakeupVec 4/5/6(纯命中)。
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

    // current_status:enqd 窗口内用 delay1 唤醒覆盖 srcState/dataSources/loadDep/exu/regcache。
    always_comb begin
      current_status = entry_reg.status;
      if (enqd_valid_reg) begin
        for (int s = 0; s < NUM_REGSRC; s++) begin
          current_status.src[s].src_state =
            (~d1_ldcancel[s] & entry_reg.status.src[s].src_state) | d1_wb[s] | d1_iq[s];
          // dataSources:_GEN_1 = srcWakeUpByIQ(loadCancel-gated)→ bypass,否则保持 reg
          current_status.src[s].data_src =
            d1_iq[s] ? DS_BYPASS : entry_reg.status.src[s].data_src;
          // ld_dep:_GEN_2 = 命中 OR(不去 loadCancel)→ shifted,否则保持 reg
          for (int p = 0; p < LDPW; p++)
            current_status.src[s].ld_dep[p] =
              d1_iq2[s] ? d1_shift_dep[s][p] : entry_reg.status.src[s].ld_dep[p];
          // exuSources:enqd 窗口直接取压缩结果(golden 无 enqd&hit 门控,直接覆盖)
          current_status.src[s].exu_src = enc_exu_src(d1_exu_out[s]);
          // useRegCache:reg & ~(cancelByLoad | replaceRC) | wakeupRC
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
  // —— comp 输出用「未取消唤醒(raw)」的 exuSources 压缩(声明在使用前)——
  logic [NUM_EXU-1:0] exu_comp_in_raw [NUM_REGSRC];
  logic [6:0]         exu_comp_out_raw [NUM_REGSRC];
  // —— srcLoadDependencyOut(声明在使用前)——
  logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] src_ld_dep_out;
  logic [NUM_REGSRC-1:0][LDPW-1:0][LDW-1:0] wk_shift_dep_raw;

  assign o_valid    = valid_reg;
  assign o_issued   = entry_reg.status.issued;
  assign o_enq_ready = enq_ready;
  assign o_deq_port_read = current_status.deq_port;
  assign o_issue_timer_read = current_status.issue_timer;

  // canIssue:simp/enq = 全源就绪&未发射&未阻塞&未冲刷;comp 额外允许「未取消唤醒」提前置位
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

  // fuType 输出(IQFuType.readFuType:仅保留本变体功能位)
  always_comb begin
    o_fu_type = '0;
    o_fu_type[FU_ALU]   = current_status.fu_type[FU_ALU];
    o_fu_type[FU_CSR]   = current_status.fu_type[FU_CSR];
    o_fu_type[FU_FENCE] = current_status.fu_type[FU_FENCE];
    o_fu_type[FU_DIV]   = current_status.fu_type[FU_DIV];
  end

  // dataSources / exuSources 输出
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      logic use_rc_reg;
      use_rc_reg = current_status.src[s].use_rc & current_status.src[s].data_src[3]; // readReg
      if (IS_COMP & wakeup_by_iq_raw[s]) begin
        o_data_src[s] = DS_FORWARD;                       // 复杂条目:未取消唤醒→forward
        o_exu_src[s]  = enc_exu_src(exu_comp_out_raw[s]);
      end else begin
        o_data_src[s] = use_rc_reg ? DS_REGCACHE : current_status.src[s].data_src;
        o_exu_src[s]  = current_status.src[s].exu_src;
      end
    end
  end

  // comp 的输出 exuSources 用「未取消唤醒(raw)」的压缩;simp/enq 不用(直接取 reg)。
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

  // o_entry:commonOut.entry.bits。enq 条目用 current_status 覆盖 status(其余= entry_reg)。
  always_comb begin
    o_entry = entry_reg;
    if (IS_ENQ) o_entry.status = current_status;
    // entry.bits.status.srcStatus[*].srcLoadDependency 用 srcLoadDependencyOut(见下)
    for (int s = 0; s < NUM_REGSRC; s++)
      for (int p = 0; p < LDPW; p++)
        o_entry.status.src[s].ld_dep[p] = src_ld_dep_out[s][p];
  end

  // srcLoadDependencyOut:comp 用「未取消唤醒源依赖<<1」否则自身<<1;simp/enq 一律自身<<1。
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++)
      for (int p = 0; p < LDPW; p++) begin
        logic [LDW-1:0] acc; acc = '0;
        // 输出路用 raw 命中(wk_iq_vec):源 0..3 的依赖<<1 + 源 4/5/6 命中钉对应 pipe bit0。
        for (int i = 0; i < 4; i++) if (wk_iq_vec[s][i]) acc |= shift_dep(wk_iq[i].ld_dep[p]);
        acc |= {1'b0, wk_iq_vec[s][4 + p]};
        wk_shift_dep_raw[s][p] = acc;
        src_ld_dep_out[s][p] = (IS_COMP & wakeup_by_iq_raw[s]) ? wk_shift_dep_raw[s][p]
                                                               : self_shift_dep[s][p];
      end
  end

  // cancelBypass:comp = 有未取消唤醒则用 transCancel 否则 srcLoadCancel,再 OR;simp/enq = srcLoadCancel OR。
  always_comb begin
    logic c;
    c = 1'b0;
    for (int s = 0; s < NUM_REGSRC; s++)
      c |= (IS_COMP & wakeup_by_iq_raw[s]) ? src_ld_trans_cancel[s] : src_ld_cancel[s];
    o_cancel_bypass = c;
  end

  // transEntry:出队转移到 comp/simp 时携带的「更新后」条目 = entry_update(寄存器次态)。
  // valid = valid && !flushed && !issued。
  // 注意:transEntry 的 srcLoadDependency 必须用「寄存器次态」语义(entry_update.ld_dep,
  //   即 wakeupByIQ? 取消门控唤醒依赖<<1 : 自身<<1),而非输出口 src_ld_dep_out(raw 唤醒、
  //   comp 专用)。golden 的 transEntry.srcLoadDependency == 寄存器 else 分支的 next-state
  //   (EnqEntry: wakeupByIQ? _GEN_7 : common_srcLoadDependencyNext;
  //    Simp:     wakeupByIQ? _GEN_1 : srcLoadDependencyOut(=自身<<1))。
  //   原先误用 src_ld_dep_out(总是自身<<1,丢了 simp 的唤醒依赖),导致转移后 comp 条目
  //   loadDependency 缺失 → srcLoadCancel/wakeupByIQ 分叉 → dataSources/useRegCache 连锁错。
  assign o_trans_valid = valid_reg & ~flushed & ~current_status.issued;
  always_comb o_trans_entry = entry_update;

endmodule
