// xs_IssueQueue_core.sv —— 发射队列（IssueQueue*）自身的调度逻辑（家族共享参数化核）
// =============================================================================
// 对应 Chisel: xiangshan.backend.issue.IssueQueueImp 及其子类
//   (src/main/scala/xiangshan/backend/issue/IssueQueue.scala)
//
// 位置：后端每个调度器（Scheduler*）里有若干个 IssueQueue*。IQ 从 Dispatch 收指令（enq），
//   存进条目阵列（Entries*，已签核子模块），每拍从"已就绪"的条目里为每个发射口挑出**最老**
//   的一条送出（deq），打一拍后交给 DataPath 读寄存器堆。
//
// 本核只写 golden 模块体里"子模块之外"的逻辑；子模块（Entries* / FuBusyTable* /
// MultiWakeupQueue* / NewAgeDetector* / AgeDetector*）由各变体 wrapper 原名例化，
// 它们的输出以数组形式送进本核，本核的输出再由 wrapper 接回它们的输入。
//
// 流水线/数据流按节：
//   §1 入队（s0）：enq.fire 条件、ready 反压；把 Dispatch 给的 srcType/psrc/srcState
//      翻译成条目状态里的 srcState / dataSources，srcLoadDependency 左移一位。
//   §2 可发射请求：canIssue & ~忙表 mask & 本口能接受的 FuType → deqCanIssue；
//      切成 enq / simp / comp 三段，分别作为三个年龄选择器的请求。
//   §3 选最老：comp 段有请求就选 comp 的最老；否则 simp；否则 enq（Chisel 的 Cat+Fill）。
//      得到每口的 deqSelOH（= addrOH）与 deqSelValid，回送 Entries。
//   §4 出队（deqBeforeDly）：valid = 选中 & !cancelDeq；按 selOH 做 Mux1H 取
//      dataSources / exuSources / loadDependency；iqIdx = OHToUInt(selOH)（按 Chisel 的
//      递归二分实现，位宽截断照 golden）；性能计时器 selectTime / issueTime。
//   §5 deqDelay：出队负载打一拍（使能 = 队里有任一有效条目，不复位）；负载按变体由
//      wrapper 拼包（Entries 出口字段 + §4 算出的字段），本核不关心字段语义。
//   §6 validCntDeqVec：每口"能进本口的有效条目数 - 本拍 deqDelay.fire"打一拍。
//   §7 wakeupToIQ：MultiWakeupQueue 的 lat 查表（FuType → 唤醒延迟）、is0Lat、og1 失败冲刷、
//      写使能门控；Ldu 没有 MWQ，load 流水的唤醒直接打一拍送出（LDW_ON）。
//   另有两处只属于个别变体的开关：写回忙表的 deqResp.valid（出队 valid && 写使能）、
//      向量访存 IQ 入队时的 blocked（VECMEM_BLOCKED）。
//
// ★三处容易写错、已对着 golden 核过的地方★
//   (a) 三段选择是"comp 优先"，不是"enq 优先"：老条目在 comp 段（Chisel 注释：
//       enq → simp → comp 是条目的迁移方向，越往后越老）。
//   (b) Mux1H 按位或，不是优先级（selOH 合法时 one-hot，非法时各项相或）。
//   (c) iqIdx 用 Chisel OHToUInt 的递归二分：非 2 的幂宽度时它**不等于**"置位下标相或"，
//       且 IQ 的 iqIdx 端口比 log2(条目数) 窄时截掉的是**最高位**（24 条目 → 5 位 → 取低 4 位）。
// =============================================================================
module xs_IssueQueue_core #(
  parameter int N_ENTRIES  = 24,
  parameter int N_ENQ      = 2,
  parameter int N_SIMP     = 6,
  parameter int N_COMP     = 16,
  parameter int N_DEQ      = 2,
  parameter int N_SRC      = 2,     // 条目状态里的源操作数个数（入队翻译、dataSources 出口）
  parameter int PSRC_W     = 8,
  parameter int LD_CNT     = 3,     // loadDependency 路数（0 = 本 IQ 无 load 依赖跟踪）
  parameter int N_EXU      = 2,     // 每条目 exuSources 个数（0 = 无）
  parameter int EXU_W      = 3,
  parameter int N_BUSY     = 1,     // 每口忙表 mask 个数（wrapper 不足的接 '0）
  parameter logic [34:0] ACCEPT [N_DEQ] = '{35'h40, 35'h320},  // 每口能接受的 FuType 位
  parameter int IQIDX_W    = 4,     // iqIdx 端口位宽
  parameter bit HAS_VCNT [N_DEQ] = '{1'b1, 1'b0},  // 每口是否有 validCntDeqVec 输出
  parameter int VCNT_OUT_W = 5,     // validCntDeqVec 端口位宽
  parameter int W0         = 1,     // 口 0 deqDelay 负载位宽（wrapper 拼包）
  parameter int W1         = 1,     // 口 1 deqDelay 负载位宽（N_DEQ=1 时不用）
  // MultiWakeupQueue 的唤醒延迟查表（口 0）：FuType 位 LAT_FU[k] 置位 → 延迟 LAT_VAL[k]
  parameter int N_LAT      = 1,
  parameter int LAT_FU  [N_LAT] = '{0},
  parameter int LAT_VAL [N_LAT] = '{0},
  parameter int LAT_W      = 1,
  // 访存 IQ 的两个专属开关
  parameter bit LDW_ON     = 1'b0,  // Ldu：load 唤醒打一拍送 wakeupToIQ（Chisel: RegNext(uop.fire) 一族）
  parameter int LDW_COPY   = 6,     //       唤醒复制件份数
  parameter bit VECMEM_BLOCKED = 1'b0,  // VlduVstu*：入队时 vleff 且不是最老 load → blocked
  parameter int LQ_W       = 7,     //       lqIdx.value 位宽
  // 零长度数组占位
  localparam int LD_SLOTS  = (LD_CNT > 0) ? LD_CNT : 1,
  localparam int EXU_SLOTS = (N_EXU  > 0) ? N_EXU  : 1,
  localparam int N_SIMP_REQ = N_DEQ + N_ENQ,   // simp 年龄选择器口数：每发射口 1 + 转移请求 N_ENQ
  // validCnt：enq 段 popcount 位宽 +& others 段 popcount 位宽
  localparam int ENQ_CNT_W = $clog2(N_ENQ + 1),
  localparam int OTH_CNT_W = $clog2(N_ENTRIES - N_ENQ + 1),
  localparam int VCNT_W    = ((ENQ_CNT_W > OTH_CNT_W) ? ENQ_CNT_W : OTH_CNT_W) + 1
) (
  input  logic                   clock,
  input  logic                   reset,
  input  logic                   flush_valid,

  // ---- §1 入队 ----
  input  logic                   enq_valid     [N_ENQ],
  output logic                   enq_ready     [N_ENQ],
  output logic                   enq_do        [N_ENQ],  // s0_doEnqSelValidVec：写进条目阵列
  input  logic [3:0]             enq_src_type  [N_ENQ][N_SRC],
  input  logic [PSRC_W-1:0]      enq_psrc      [N_ENQ][N_SRC],
  input  logic                   enq_src_state [N_ENQ][N_SRC],
  input  logic [1:0]             enq_src_ld    [N_ENQ][N_SRC][LD_SLOTS],
  input  logic [LQ_W:0]          enq_lq_idx    [N_ENQ],    // {flag, value}（VECMEM_BLOCKED）
  input  logic                   enq_is_vleff  [N_ENQ],
  input  logic [LQ_W:0]          lq_deq_ptr,
  output logic                   st_blocked    [N_ENQ],
  output logic                   st_src_state  [N_ENQ][N_SRC],
  output logic [3:0]             st_data_src   [N_ENQ][N_SRC],
  output logic [1:0]             st_src_ld     [N_ENQ][N_SRC][LD_SLOTS],

  // ---- 条目阵列出口 ----
  input  logic [N_ENTRIES-1:0]   ent_valid,
  input  logic [N_ENTRIES-1:0]   ent_issued,
  input  logic [N_ENTRIES-1:0]   ent_can_issue,
  input  logic [34:0]            ent_fu_type   [N_ENTRIES],
  input  logic [3:0]             ent_data_src  [N_ENTRIES][N_SRC],
  input  logic [EXU_W-1:0]       ent_exu_src   [N_ENTRIES][EXU_SLOTS],
  input  logic [1:0]             ent_ld_dep    [N_ENTRIES][LD_SLOTS],
  input  logic                   ent_cancel_deq [N_DEQ],

  // ---- §2/§3 选择 ----
  input  logic [N_ENTRIES-1:0]   busy_mask     [N_DEQ][N_BUSY],
  output logic [N_ENQ-1:0]       age_enq_req   [N_DEQ],
  output logic [N_SIMP-1:0]      age_simp_req  [N_SIMP_REQ],
  output logic [N_COMP-1:0]      age_comp_req  [N_DEQ],
  input  logic [N_ENQ-1:0]       age_enq_out   [N_DEQ],
  input  logic [N_SIMP-1:0]      age_simp_out  [N_SIMP_REQ],
  input  logic [N_COMP-1:0]      age_comp_out  [N_DEQ],
  output logic                   sel_valid     [N_DEQ],
  output logic [N_ENTRIES-1:0]   sel_oh        [N_DEQ],
  output logic                   simp_oldest_valid [N_DEQ],
  output logic                   comp_oldest_valid [N_DEQ],

  // ---- §4 出队 ----
  output logic                   deq_valid     [N_DEQ],
  output logic [IQIDX_W-1:0]     deq_iq_idx    [N_DEQ],
  output logic [3:0]             deq_data_src  [N_DEQ][N_SRC],
  output logic [EXU_W-1:0]       deq_exu_src   [N_DEQ][EXU_SLOTS],
  output logic [1:0]             deq_ld_dep    [N_DEQ][LD_SLOTS],
  output logic [63:0]            deq_select_time [N_DEQ],
  output logic [63:0]            deq_issue_time  [N_DEQ],
  // 出队口的写使能（rfWen, fpWen, vecWen, v0Wen, vlWen；本变体没有的接 0）与 valid 相与：写回忙表的 deqResp.valid
  input  logic [4:0]             deq_wen       [N_DEQ],
  output logic [4:0]             deq_wen_valid [N_DEQ],

  // ---- §5 deqDelay ----
  input  logic [W0-1:0]          deq0_payload,
  input  logic [W1-1:0]          deq1_payload,
  output logic                   dly_valid     [N_DEQ],
  output logic [W0-1:0]          dly0_payload,
  output logic [W1-1:0]          dly1_payload,
  input  logic                   dly_ready     [N_DEQ],

  // ---- §6 validCntDeqVec ----
  output logic [VCNT_OUT_W-1:0]  valid_cnt     [N_DEQ],

  // ---- §7 wakeupToIQ（口 0 的 MultiWakeupQueue）----
  input  logic [34:0]            wk_enq_fu_type,   // 送进 MWQ 的 fuType（= 口 0 出队 fuType）
  output logic [LAT_W-1:0]       wk_enq_lat,
  input  logic                   wk_og1_valid,     // 口 0 的 og1 响应
  input  logic [1:0]             wk_og1_resp,
  output logic                   wk_og1_fail,      // og1 响应为 block → MWQ 里 lat=2 的流水出口冲刷
  input  logic                   wk_deq_valid,
  input  logic [34:0]            wk_deq_fu_type,   // MWQ 出口的 fuType（算 is0Lat）
  input  logic [4:0]             wk_deq_wen,       // MWQ 出口的写使能 {vl, v0, vec, fp, rf}
  output logic [4:0]             wk_out_wen,       // valid && wen
  output logic                   wk_is0lat,        // getDeqLat(出口 fuType) == 0
  // Ldu 的 load 唤醒（LDW_ON）
  input  logic                   ldw_valid,
  input  logic                   ldw_rf_wen,
  input  logic                   ldw_fp_wen,
  input  logic [7:0]             ldw_pdest,
  output logic                   ldw_q_valid,
  output logic                   ldw_q_rf_wen,
  output logic                   ldw_q_fp_wen,
  output logic [7:0]             ldw_q_pdest,
  output logic                   ldw_q_rf_wen_copy [LDW_COPY],
  output logic                   ldw_q_fp_wen_copy [LDW_COPY],
  output logic [7:0]             ldw_q_pdest_copy  [LDW_COPY]
);

  localparam int ENQ_LO  = 0;
  localparam int SIMP_LO = N_ENQ;
  localparam int COMP_LO = N_ENQ + N_SIMP;

  // ===========================================================================
  // §1 入队
  // ===========================================================================
  // 入队 ready：入队条目区（前 N_ENQ 条）里有已发射未离开的条目就不收；否则只要 simp 段
  // 还能再装下（空位 >= 2），或入队条目区是空的，就收。simp 段"装不下"= 全满或只剩 1 个空位。
  logic enq_has_valid, enq_has_issued, simp_left_one, simp_all_valid, simp_cannot_in;

  always_comb begin
    logic [N_SIMP-1:0] simp_valid;
    enq_has_valid  = 1'b0;
    enq_has_issued = 1'b0;
    for (int i = 0; i < N_ENQ; i++) begin
      enq_has_valid  |= ent_valid[ENQ_LO + i];
      enq_has_issued |= ent_valid[ENQ_LO + i] & ent_issued[ENQ_LO + i];
    end
    simp_valid     = ent_valid[SIMP_LO +: N_SIMP];
    simp_all_valid = &simp_valid;
    simp_left_one  = 1'b0;
    for (int i = 0; i < N_SIMP; i++)
      simp_left_one |= (simp_valid == ~(N_SIMP'(1) << i));
    simp_cannot_in = simp_left_one | simp_all_valid;
  end

  always_comb
    for (int e = 0; e < N_ENQ; e++) begin
      enq_ready[e] = (~simp_cannot_in | ~enq_has_valid) & ~enq_has_issued;
      enq_do[e]    = enq_valid[e] & enq_ready[e] & ~flush_valid;
    end

  // 源状态翻译（Chisel 里的 SrcType 编码：bit0 = 整数寄存器 Xp，bit2 = 向量寄存器 Vp，全 0 = 非寄存器/立即数）
  //   前 3 个源：
  //     srcState    = (Vp && psrc==0) ? rdy : 原 srcState   —— v0 号向量寄存器恒就绪
  //     dataSources = (Xp && psrc==0) ? zero(0)             —— x0 恒为 0
  //                 : 非寄存器        ? imm(4)
  //                 : (Vp && psrc==0) ? v0(5)
  //                 :                   reg(8)
  //   第 3 个以后的源（向量 IQ 才有）：srcState 原样；dataSources = 非寄存器 ? imm : reg
  //   srcLoadDependency 每路左移一位（进入 IQ 这一拍算一拍"老化"）。
  localparam logic [3:0] DS_ZERO = 4'h0;
  localparam logic [3:0] DS_IMM  = 4'h4;
  localparam logic [3:0] DS_V0   = 4'h5;
  localparam logic [3:0] DS_REG  = 4'h8;

  always_comb
    for (int e = 0; e < N_ENQ; e++)
      for (int s = 0; s < N_SRC; s++) begin
        logic is_xp, is_vp, not_reg, psrc_zero;
        is_xp     = enq_src_type[e][s][0];
        is_vp     = enq_src_type[e][s][2];
        not_reg   = (enq_src_type[e][s] == 4'h0);
        psrc_zero = (enq_psrc[e][s] == '0);
        if (s < 3) begin
          st_src_state[e][s] = (is_vp & psrc_zero) | enq_src_state[e][s];
          st_data_src[e][s]  = (is_xp & psrc_zero) ? DS_ZERO :
                               not_reg             ? DS_IMM  :
                               (is_vp & psrc_zero) ? DS_V0   : DS_REG;
        end else begin
          st_src_state[e][s] = enq_src_state[e][s];
          st_data_src[e][s]  = not_reg ? DS_IMM : DS_REG;
        end
        for (int k = 0; k < LD_SLOTS; k++)
          st_src_ld[e][s][k] = (LD_CNT > 0) ? (enq_src_ld[e][s][k] << 1) : 2'h0;
      end

  // 向量访存 IQ：vleff（fault-only-first）load 若不是当前最老的 load（lqIdx 在 lqDeqPtr 之后），
  // 入队即 blocked，等它变成最老再放行（Chisel: blocked := !isFirstLoad && isVleff，
  // isFirstLoad = lqIdx <= lqDeqPtr；环形指针比较 = flag^flag'^(value > value')）。
  always_comb
    for (int e = 0; e < N_ENQ; e++)
      st_blocked[e] = VECMEM_BLOCKED &
                      (enq_lq_idx[e][LQ_W] ^ lq_deq_ptr[LQ_W] ^ (enq_lq_idx[e][LQ_W-1:0] > lq_deq_ptr[LQ_W-1:0])) &
                      enq_is_vleff[e];

  // ===========================================================================
  // §2 可发射请求
  // ===========================================================================
  logic [N_ENTRIES-1:0] deq_can_issue [N_DEQ];

  always_comb
    for (int d = 0; d < N_DEQ; d++) begin
      logic [N_ENTRIES-1:0] merged, accept;
      merged = ent_can_issue;
      for (int b = 0; b < N_BUSY; b++)
        merged &= ~busy_mask[d][b];                  // canIssueMergeAllBusy
      for (int i = 0; i < N_ENTRIES; i++)
        accept[i] = |(ent_fu_type[i] & ACCEPT[d]);   // FuTypeOrR(本口的 FU 集合)
      deq_can_issue[d] = merged & accept;
    end

  // 三段请求：enq 段给 NewAgeDetector，simp / comp 段给各自的 AgeDetector
  logic [N_SIMP-1:0] request_for_trans;   // simp 段"有效且未发射"：可以迁往 comp 段的条目

  always_comb begin
    for (int i = 0; i < N_SIMP; i++)
      request_for_trans[i] = ent_valid[SIMP_LO + i] & ~ent_issued[SIMP_LO + i];
    for (int d = 0; d < N_DEQ; d++) begin
      age_enq_req[d]  = deq_can_issue[d][ENQ_LO  +: N_ENQ];
      age_simp_req[d] = deq_can_issue[d][SIMP_LO +: N_SIMP];
      age_comp_req[d] = deq_can_issue[d][COMP_LO +: N_COMP];
    end
    // simp 年龄选择器多出来的 N_ENQ 个口：挑 simp → comp 的迁移对象（最老的两个未发射条目）
    age_simp_req[N_DEQ] = request_for_trans;
    if (N_ENQ == 2)
      age_simp_req[N_DEQ + 1] = request_for_trans & ~age_simp_out[N_DEQ];
  end

  // ===========================================================================
  // §3 选最老：comp > simp > enq
  // ===========================================================================
  always_comb
    for (int d = 0; d < N_DEQ; d++) begin
      logic comp_any, simp_any, enq_any;
      comp_any = |age_comp_req[d];
      simp_any = |age_simp_req[d];
      enq_any  = |age_enq_req[d];
      comp_oldest_valid[d] = comp_any;
      simp_oldest_valid[d] = simp_any;
      sel_valid[d] = comp_any | simp_any | enq_any;
      sel_oh[d] = {age_comp_out[d],
                   {N_SIMP{~comp_any}} & age_simp_out[d],
                   {N_ENQ{~comp_any & ~simp_any}} & age_enq_out[d]};
    end

  // ===========================================================================
  // §4 出队（deqBeforeDly）
  // ===========================================================================
  // Chisel OHToUInt(in, width)：width<=2 时取 in[1]（width<2 为 0）；否则
  //   mid = 1 << (log2Ceil(width)-1)，结果 = Cat(|in[width-1:mid], OHToUInt(in_hi | in_lo, mid))。
  //   这里按层展开成循环（每层宽度、mid 都是常量），结果再截到 IQIDX_W 位。
  localparam int OH_BITS = $clog2(N_ENTRIES);

  function automatic logic [OH_BITS-1:0] oh_to_uint(input logic [N_ENTRIES-1:0] in);
    logic [N_ENTRIES-1:0] cur;
    logic [OH_BITS-1:0]   res;
    int w, mid;
    cur = in;
    w   = N_ENTRIES;
    res = '0;
    for (int lvl = OH_BITS - 1; lvl >= 1; lvl--) begin
      mid      = 1 << ($clog2(w) - 1);
      res[lvl] = |(cur >> mid);
      cur      = (cur >> mid) | (cur & ((N_ENTRIES'(1) << mid) - 1));
      w        = mid;
    end
    res[0] = (w == 2) ? cur[1] : 1'b0;
    return res;
  endfunction

  always_comb
    for (int d = 0; d < N_DEQ; d++) begin
      logic [OH_BITS-1:0] idx_full;
      deq_valid[d]  = sel_valid[d] & ~ent_cancel_deq[d];
      idx_full      = oh_to_uint(sel_oh[d]);
      deq_iq_idx[d] = idx_full[IQIDX_W-1:0];
      // Mux1H(selOH, 各条目的 X) = 按位或
      for (int s = 0; s < N_SRC; s++) begin
        deq_data_src[d][s] = '0;
        for (int i = 0; i < N_ENTRIES; i++)
          deq_data_src[d][s] |= sel_oh[d][i] ? ent_data_src[i][s] : 4'h0;
      end
      for (int s = 0; s < EXU_SLOTS; s++) begin
        deq_exu_src[d][s] = '0;
        if (N_EXU > 0)
          for (int i = 0; i < N_ENTRIES; i++)
            deq_exu_src[d][s] |= sel_oh[d][i] ? ent_exu_src[i][s] : '0;
      end
      for (int k = 0; k < LD_SLOTS; k++) begin
        deq_ld_dep[d][k] = '0;
        if (LD_CNT > 0)
          for (int i = 0; i < N_ENTRIES; i++)
            deq_ld_dep[d][k] |= sel_oh[d][i] ? ent_ld_dep[i][k] : 2'h0;
      end
    end

  // 性能计时器（GTimer）：每口两个 64 位自由计数器，异步复位清 0。
  //   selectTime = 计数器 A 当前值；issueTime = 计数器 B 当前值 + 1（B 每拍 <= B+1）。
  //   两个计数器数值恒等，但 golden 是两个独立寄存器 —— 照写。
  logic [63:0] select_timer [N_DEQ];
  logic [63:0] issue_timer  [N_DEQ];

  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      for (int d = 0; d < N_DEQ; d++) begin
        select_timer[d] <= 64'h0;
        issue_timer[d]  <= 64'h0;
      end
    end else begin
      for (int d = 0; d < N_DEQ; d++) begin
        select_timer[d] <= select_timer[d] + 64'h1;
        issue_timer[d]  <= issue_timer[d] + 64'h1;
      end
    end

  // 写回忙表（FuBusyTableWrite: int/fp/vf/v0/vlWbBusyTable）的 deqResp.valid = 出队 valid && 对应写使能
  always_comb
    for (int d = 0; d < N_DEQ; d++)
      deq_wen_valid[d] = {5{deq_valid[d]}} & deq_wen[d];

  always_comb
    for (int d = 0; d < N_DEQ; d++) begin
      deq_select_time[d] = select_timer[d];
      deq_issue_time[d]  = issue_timer[d] + 64'h1;
    end

  // ===========================================================================
  // §5 deqDelay：valid 每拍跟随；负载只在"队里有任一有效条目"时更新。均不复位。
  // ===========================================================================
  logic            dly_valid_q [N_DEQ];
  logic [W0-1:0]   dly0_q;
  logic [W1-1:0]   dly1_q;
  logic            any_valid;

  assign any_valid = |ent_valid;

  always_ff @(posedge clock) begin
    for (int d = 0; d < N_DEQ; d++)
      dly_valid_q[d] <= deq_valid[d];
    if (any_valid)
      dly0_q <= deq0_payload;
  end

  if (N_DEQ > 1) begin : g_dly1
    always_ff @(posedge clock)
      if (any_valid)
        dly1_q <= deq1_payload;
  end else begin : g_no_dly1
    assign dly1_q = '0;
  end

  assign dly_valid    = dly_valid_q;
  assign dly0_payload = dly0_q;
  assign dly1_payload = dly1_q;

  // ===========================================================================
  // §6 validCntDeqVec：RegNext(enq 段本口可接受的有效数 +& others 段本口可接受的有效数
  //                            - 本口 deqDelay.fire)，端口取低 VCNT_OUT_W 位
  // ===========================================================================
  for (genvar d = 0; d < N_DEQ; d++) begin : g_vcnt
    if (HAS_VCNT[d]) begin : g_on
      logic [ENQ_CNT_W-1:0] enq_cnt;   // enq 段里能进本口的有效条目数
      logic [OTH_CNT_W-1:0] oth_cnt;   // 其余条目里能进本口的有效条目数
      logic [VCNT_W-1:0]    vcnt_q;

      always_comb begin
        enq_cnt = '0;
        oth_cnt = '0;
        for (int i = 0; i < N_ENQ; i++)
          enq_cnt += ENQ_CNT_W'(ent_valid[i] & |(ent_fu_type[i] & ACCEPT[d]));
        for (int i = N_ENQ; i < N_ENTRIES; i++)
          oth_cnt += OTH_CNT_W'(ent_valid[i] & |(ent_fu_type[i] & ACCEPT[d]));
      end

      always_ff @(posedge clock)
        vcnt_q <= VCNT_W'(enq_cnt) + VCNT_W'(oth_cnt) - VCNT_W'(dly_ready[d] & dly_valid_q[d]);

      assign valid_cnt[d] = vcnt_q[VCNT_OUT_W-1:0];
    end else begin : g_off
      assign valid_cnt[d] = '0;
    end
  end

  // ===========================================================================
  // §7 wakeupToIQ（口 0 的 MultiWakeupQueue）
  // ===========================================================================
  // getDeqLat(fuType) = Mux1H(fuType 位 → 该 FU 的唤醒延迟)，按位或
  function automatic logic [LAT_W-1:0] deq_lat(input logic [34:0] fu);
    logic [LAT_W-1:0] lat;
    lat = '0;
    for (int k = 0; k < N_LAT; k++)
      lat |= fu[LAT_FU[k]] ? LAT_W'(LAT_VAL[k]) : '0;
    return lat;
  endfunction

  localparam logic [1:0] RESP_BLOCK = 2'h0;   // RespType.block

  assign wk_enq_lat  = deq_lat(wk_enq_fu_type);
  assign wk_is0lat   = (deq_lat(wk_deq_fu_type) == '0);
  assign wk_og1_fail = wk_og1_valid & (wk_og1_resp == RESP_BLOCK);
  assign wk_out_wen  = {5{wk_deq_valid}} & wk_deq_wen;

  // Ldu：load 流水的唤醒直接打一拍送出（不经 MultiWakeupQueue）。不复位。
  //   valid / pdest 直接打拍；写使能先与 valid 相与再打拍；复制件各自独立寄存器（照 golden）。
  if (LDW_ON) begin : g_ldw
    always_ff @(posedge clock) begin
      ldw_q_valid  <= ldw_valid;
      ldw_q_rf_wen <= ldw_rf_wen & ldw_valid;
      ldw_q_fp_wen <= ldw_fp_wen & ldw_valid;
      ldw_q_pdest  <= ldw_pdest;
      for (int k = 0; k < LDW_COPY; k++) begin
        ldw_q_rf_wen_copy[k] <= ldw_rf_wen & ldw_valid;
        ldw_q_fp_wen_copy[k] <= ldw_fp_wen & ldw_valid;
        ldw_q_pdest_copy[k]  <= ldw_pdest;
      end
    end
  end else begin : g_no_ldw
    always_comb begin
      ldw_q_valid  = 1'b0;
      ldw_q_rf_wen = 1'b0;
      ldw_q_fp_wen = 1'b0;
      ldw_q_pdest  = '0;
      for (int k = 0; k < LDW_COPY; k++) begin
        ldw_q_rf_wen_copy[k] = 1'b0;
        ldw_q_fp_wen_copy[k] = 1'b0;
        ldw_q_pdest_copy[k]  = '0;
      end
    end
  end

endmodule
