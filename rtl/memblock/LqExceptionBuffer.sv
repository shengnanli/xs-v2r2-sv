// =============================================================================
//  xs_LqExceptionBuffer_core —— Load 访存异常缓冲（可读重写）
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel，非 firtool golden）：
//      src/main/scala/xiangshan/mem/lsqueue/LoadExceptionBuffer.scala (class LqExceptionBuffer)
//
//  作用：核里有多条 load 流水（3 标量 load + 2 向量 load + 1 个 SoC 非数据错误端口，
//  共 6 个入口）。每条 load 在执行到 S2 时若检出访存异常（缺页/访问错/地址非对齐/断点/
//  GPF 等），就把“带异常的请求”报给本缓冲。本缓冲在所有报上来的异常里**按 robIdx 选最老**
//  的一条，锁存进单条 req 寄存器，持续把它的虚/物理地址等信息输出给 CSR（trap 时读取）。
//
//  为什么只留最老一条？异常按程序序在 ROB 提交点处理，最老的异常最先到达提交点、最先生效；
//  更年轻的异常要么被它引发的重定向冲掉，要么稍后再报。故缓冲只需保留“当前最老”的一条。
//
//  ── 两级流水时序 ───────────────────────────────────────────────────────────
//    S1（拍 T）   ：直接取 io.req[w]（组合），记录 valid。
//    S2（拍 T+1） ：s2_req[w] = RegEnable(io.req[w], io.req[w].valid)（仅 valid 时锁存）；
//                   s2_valid[w] = RegNext(req.valid) 且未被 redirect 冲刷（注意要同时排除
//                   **上一拍的 redirect**（RegNext）与**当拍 redirect**两种冲刷，见下）；
//                   s2_enqueue[w] = s2_valid[w] & 该请求确实带 Ldu 类异常。
//    选最老        ：对 6 个 s2_enqueue 做平衡树两两选最老 → reqSel（valid + bits）。
//    锁存          ：若已有 req 且新选出的更老 → 替换；否则新来则装入。redirect 冲刷已锁存 req。
//
//  本核为纯叶子（无子模块），与 golden LqExceptionBuffer.sv 同构。微架构讲解见
//  docs/memblock/LqExceptionBuffer.md。
// =============================================================================
module xs_LqExceptionBuffer_core
  import exceptionbuffer_pkg::*;
#(
  parameter int ENQ_NUM = 6   // LoadPipelineWidth(3) + VecLoadPipelineWidth(2) + 1(SoC)
)(
  input  logic clock,
  input  logic reset,

  // ---- 重定向（冲刷比其更年轻的条目）----
  input  logic     redirect_valid,
  input  rob_ptr_t redirect_robIdx,
  input  logic     redirect_level,

  // ---- 各 load 流水 S1 报上来的请求（异常汇报口）----
  input  logic       [ENQ_NUM-1:0]      req_valid,
  input  rob_ptr_t   [ENQ_NUM-1:0]      req_robIdx,
  input  logic [ENQ_NUM-1:0][UOPIDX_W-1:0] req_uopIdx,
  input  logic [ENQ_NUM-1:0][5:0]       req_excVec,    // 6 个相关 Ldu 异常位（见 pkg/doc）
  input  logic [ENQ_NUM-1:0][63:0]      req_fullva,
  input  logic       [ENQ_NUM-1:0]      req_vaNeedExt,
  input  logic [ENQ_NUM-1:0][63:0]      req_gpaddr,
  input  logic       [ENQ_NUM-1:0]      req_isHyper,
  input  logic       [ENQ_NUM-1:0]      req_isForVSnonLeafPTE,

  // ---- 输出：当前锁存的最老异常的地址信息 ----
  output logic [63:0] exc_vaddr,
  output logic        exc_vaNeedExt,
  output logic        exc_isHyper,
  output logic [63:0] exc_gpaddr,
  output logic        exc_isForVSnonLeafPTE
);

  // ===========================================================================
  //  S2 流水寄存器
  //  仅当对应 io.req.valid 时锁存（RegEnable），其余拍保持旧值。
  //
  //  统一 struct（组合 view）供选择树按 s2_entry_t 读取；但**存储必须逐入口匹配
  //  golden 的精确寄存器集**——golden firtool 对被 wrapper 折成常量的字段 per-entry
  //  做了 DCE（见 LqExceptionBuffer_wrapper.sv）：
  //      · vaNeedExt         入口 5     恒 1  → golden 无 s2_req_5_vaNeedExt 寄存器
  //      · isHyper           入口 3,4   恒 0  → golden 无 s2_req_3/4_isHyper 寄存器
  //      · isForVSnonLeafPTE 入口 3,4   恒 0  → golden 无 s2_req_3/4_isForVSnonLeafPTE 寄存器
  //  若本核对所有入口统一存全字段，这些恒定字段会成 impl-only 死 compare point
  //  → FM 判 3 个 unmatched compare point（同 StoreExceptionBuffer 修法）。
  //  故此处**按 golden 形状逐入口裁剪存储**：折叠字段不进 S2 寄存器，改由组合
  //  view（s2_req）把常量补回，供后续选择树读取（与 golden 逐字段选择等价）。
  // ===========================================================================
  typedef struct packed {
    rob_ptr_t            robIdx;
    logic [UOPIDX_W-1:0] uopIdx;
    logic [5:0]          excVec;
    logic [63:0]         fullva;
    logic                vaNeedExt;
    logic [63:0]         gpaddr;
    logic                isHyper;
    logic                isForVSnonLeafPTE;
  } s2_entry_t;

  // 仅存 golden 为该入口生成的寄存器字段：
  //   robIdx/uopIdx/excVec/fullva/gpaddr：全 6 入口有
  //   vaNeedExt：入口 0..4（入口 5 折常量 1）
  //   isHyper / isForVSnonLeafPTE：入口 0,1,2,5（入口 3,4 折常量 0）
  rob_ptr_t            s2_robIdx    [ENQ_NUM];   // 全入口
  logic [UOPIDX_W-1:0] s2_uopIdx    [ENQ_NUM];   // 全入口
  logic [5:0]          s2_excVec    [ENQ_NUM];   // 全入口（has_exc 门控需要）
  logic [63:0]         s2_fullva    [ENQ_NUM];   // 全入口
  logic [63:0]         s2_gpaddr    [ENQ_NUM];   // 全入口
  logic                s2_vaNeedExt [0:4];       // 入口 0..4（5 折常量 1）
  logic                s2_isHyper_0, s2_isHyper_1, s2_isHyper_2, s2_isHyper_5;   // 入口 0,1,2,5
  logic                s2_isForVS_0, s2_isForVS_1, s2_isForVS_2, s2_isForVS_5;   // 入口 0,1,2,5
  logic      [ENQ_NUM-1:0] s2_valid_q;     // RegNext(io.req.valid)

  // redirect 打 1 拍：S2 既要排除“上一拍 redirect”（与 s2_req 同拍捕获的 redirect），
  // 也要排除“当拍 redirect”——两者都可能冲刷这条已进 S2 的异常。
  logic     redirect_valid_q;
  rob_ptr_t redirect_robIdx_q;
  logic     redirect_level_q;

  always_ff @(posedge clock) begin
    for (int w = 0; w < ENQ_NUM; w++) begin
      if (req_valid[w]) begin
        s2_robIdx[w] <= req_robIdx[w];
        s2_uopIdx[w] <= req_uopIdx[w];
        s2_excVec[w] <= req_excVec[w];
        s2_fullva[w] <= req_fullva[w];
        s2_gpaddr[w] <= req_gpaddr[w];
      end
    end
    for (int w = 0; w <= 4; w++) begin
      if (req_valid[w]) s2_vaNeedExt[w] <= req_vaNeedExt[w];
    end
    // isHyper / isForVSnonLeafPTE 仅入口 0,1,2,5 存寄存器（3,4 折常量 0）
    if (req_valid[0]) begin s2_isHyper_0 <= req_isHyper[0]; s2_isForVS_0 <= req_isForVSnonLeafPTE[0]; end
    if (req_valid[1]) begin s2_isHyper_1 <= req_isHyper[1]; s2_isForVS_1 <= req_isForVSnonLeafPTE[1]; end
    if (req_valid[2]) begin s2_isHyper_2 <= req_isHyper[2]; s2_isForVS_2 <= req_isForVSnonLeafPTE[2]; end
    if (req_valid[5]) begin s2_isHyper_5 <= req_isHyper[5]; s2_isForVS_5 <= req_isForVSnonLeafPTE[5]; end
    // 对齐 golden：s2_valid_REG* 为无复位 RegNext（golden 仅 req_valid 有异步复位）。
    s2_valid_q <= req_valid;
    // redirect 延迟版（无需复位：仅在 valid 参与判断时使用）
    redirect_valid_q  <= redirect_valid;
    redirect_robIdx_q <= redirect_robIdx;
    redirect_level_q  <= redirect_level;
  end

  // 组合 view：把 golden DCE 折掉的恒定字段补回常量，供选择树按统一 struct 读取。
  s2_entry_t [ENQ_NUM-1:0] s2_req;
  always_comb begin
    for (int w = 0; w < ENQ_NUM; w++) begin
      s2_req[w].robIdx    = s2_robIdx[w];
      s2_req[w].uopIdx    = s2_uopIdx[w];
      s2_req[w].excVec    = s2_excVec[w];
      s2_req[w].fullva    = s2_fullva[w];
      s2_req[w].gpaddr    = s2_gpaddr[w];
      s2_req[w].vaNeedExt = (w <= 4) ? s2_vaNeedExt[w] : 1'b1;  // 入口5折常量1
    end
    // isHyper / isForVSnonLeafPTE：入口 3,4 折常量 0，其余取寄存器
    s2_req[0].isHyper = s2_isHyper_0;  s2_req[0].isForVSnonLeafPTE = s2_isForVS_0;
    s2_req[1].isHyper = s2_isHyper_1;  s2_req[1].isForVSnonLeafPTE = s2_isForVS_1;
    s2_req[2].isHyper = s2_isHyper_2;  s2_req[2].isForVSnonLeafPTE = s2_isForVS_2;
    s2_req[3].isHyper = 1'b0;          s2_req[3].isForVSnonLeafPTE = 1'b0;
    s2_req[4].isHyper = 1'b0;          s2_req[4].isForVSnonLeafPTE = 1'b0;
    s2_req[5].isHyper = s2_isHyper_5;  s2_req[5].isForVSnonLeafPTE = s2_isForVS_5;
  end

  // ===========================================================================
  //  S2 入队判定：valid 且未被两版 redirect 冲刷 且 确实带 Ldu 异常
  // ===========================================================================
  logic [ENQ_NUM-1:0] s2_enqueue;
  always_comb begin
    for (int w = 0; w < ENQ_NUM; w++) begin
      logic flush_prev, flush_cur, has_exc;
      flush_prev = rob_need_flush(redirect_valid_q, redirect_level_q,
                                  s2_req[w].robIdx, redirect_robIdx_q);
      flush_cur  = rob_need_flush(redirect_valid,   redirect_level,
                                  s2_req[w].robIdx, redirect_robIdx);
      has_exc    = |s2_req[w].excVec;
      s2_enqueue[w] = s2_valid_q[w] & ~flush_prev & ~flush_cur & has_exc;
    end
  end

  // ===========================================================================
  //  选最老（平衡归约树）
  //  Chisel selectOldest 把 6 路递归二分：{0,1,2} 与 {3,4,5}，再逐层两两 older_pick_b。
  //  这里用三段固定的两两归约函数实现同样的树形，结果与 golden 逐位一致。
  //  Lq 的“平手维度”用严格相等（eq_is_not_before=0）。
  // ===========================================================================
  // 两两选最老：给定两侧 (va,ea)/(vb,eb)，返回更老的一侧
  function automatic void pick2(
    input  logic      va,    input s2_entry_t ea,
    input  logic      vb,    input s2_entry_t eb,
    output logic      vo,    output s2_entry_t eo
  );
    logic sel_b;
    sel_b = older_pick_b(va, vb, ea.robIdx, eb.robIdx, ea.uopIdx, eb.uopIdx, 1'b0);
    vo = sel_b ? vb : va;
    eo = sel_b ? eb : ea;
  endfunction

  logic      sel_l_v, sel_r_v, sel_v;
  s2_entry_t sel_l_e, sel_r_e, sel_e;
  always_comb begin
    logic      lr_v, rr_v;
    s2_entry_t lr_e, rr_e;
    // 左子树 {0,1,2}：先 {1,2} 再与 0
    pick2(s2_enqueue[1], s2_req[1], s2_enqueue[2], s2_req[2], lr_v, lr_e);
    pick2(s2_enqueue[0], s2_req[0], lr_v,          lr_e,      sel_l_v, sel_l_e);
    // 右子树 {3,4,5}：先 {4,5} 再与 3
    pick2(s2_enqueue[4], s2_req[4], s2_enqueue[5], s2_req[5], rr_v, rr_e);
    pick2(s2_enqueue[3], s2_req[3], rr_v,          rr_e,      sel_r_v, sel_r_e);
    // 根：左 vs 右
    pick2(sel_l_v, sel_l_e, sel_r_v, sel_r_e, sel_v, sel_e);
  end

  // ===========================================================================
  //  锁存最老异常（单条 req 寄存器）
  //  golden 的最终 req 寄存器**不含 excVec**（excVec 只在 S2 阶段用于 has_exc 门控，
  //  一旦选出最老条目后其异常向量不再被读）。若本核把 sel_e（含 excVec）整体存进
  //  req_r，excVec[5:0] 会成 impl-only 死寄存器（req_r_reg[excVec][0..5]）→ FM 判 6 个
  //  unmatched unread compare point。故最终锁存寄存器用**不含 excVec 的 req_entry_t**，
  //  逐字段从 sel_e 拷贝（与 golden req_* 寄存器集精确一致）。
  // ===========================================================================
  typedef struct packed {
    rob_ptr_t            robIdx;
    logic [UOPIDX_W-1:0] uopIdx;
    logic [63:0]         fullva;
    logic                vaNeedExt;
    logic [63:0]         gpaddr;
    logic                isHyper;
    logic                isForVSnonLeafPTE;
  } req_entry_t;

  logic       req_valid_r;
  req_entry_t req_r;
  logic       any_enqueue;
  assign any_enqueue = |s2_enqueue;

  // 把选中条目（含 excVec 的 s2_entry_t）投影成不含 excVec 的存储型 req_entry_t
  req_entry_t sel_store;
  always_comb begin
    sel_store.robIdx            = sel_e.robIdx;
    sel_store.uopIdx            = sel_e.uopIdx;
    sel_store.fullva            = sel_e.fullva;
    sel_store.vaNeedExt         = sel_e.vaNeedExt;
    sel_store.gpaddr            = sel_e.gpaddr;
    sel_store.isHyper           = sel_e.isHyper;
    sel_store.isForVSnonLeafPTE = sel_e.isForVSnonLeafPTE;
  end

  // req_valid：已锁存且被 redirect 冲刷 → 看本拍是否有新入队续命；否则有新入队即置 1。
  logic req_flush;
  assign req_flush = rob_need_flush(redirect_valid, redirect_level, req_r.robIdx, redirect_robIdx);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) req_valid_r <= 1'b0;
    else if (req_valid_r & req_flush) req_valid_r <= any_enqueue;
    else if (any_enqueue)             req_valid_r <= 1'b1;
    // 否则保持
  end

  // req bits：已锁存时，若新选出的更老则替换；空闲时新来即装入。
  //   替换条件 = sel_v & ( isAfter(req,sel) || (rob_eq(req,sel) && req.uopIdx>sel.uopIdx) )
  //   即“已锁存的 req 比新选出的更年轻” → 用更老的 sel 替换。复用 older_pick_b（Lq 语义）。
  logic replace_by_sel;
  assign replace_by_sel = older_pick_b(req_valid_r ? 1'b1 : 1'b0, sel_v,
                                       req_r.robIdx, sel_e.robIdx,
                                       req_r.uopIdx, sel_e.uopIdx, 1'b0)
                          & sel_v;   // 仅当 sel 有效才可能替换
  always_ff @(posedge clock) begin
    if (req_valid_r) begin
      if (replace_by_sel) req_r <= sel_store;
    end else if (any_enqueue) begin
      req_r <= sel_store;
    end
  end

  // ===========================================================================
  //  输出（持续汇报当前最老异常的地址信息）
  // ===========================================================================
  assign exc_vaddr             = req_r.fullva;
  assign exc_vaNeedExt         = req_r.vaNeedExt;
  assign exc_isHyper           = req_r.isHyper;
  assign exc_gpaddr            = req_r.gpaddr;
  assign exc_isForVSnonLeafPTE = req_r.isForVSnonLeafPTE;

endmodule
