// =============================================================================
//  xs_StoreExceptionBuffer_core —— Store 访存异常缓冲（可读重写）
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel，非 firtool golden）：
//      src/main/scala/xiangshan/mem/lsqueue/StoreQueue.scala (class StoreExceptionBuffer)
//
//  作用：与 LqExceptionBuffer 同构，只是服务 store 流水。store 的异常缓冲有 7 个入口
//  （enqPortNum = StorePipelineWidth*2 + VecStorePipelineWidth + 1 = 2*2 + 2 + 1）：
//      · 入口 0,1（StorePipelineWidth）：sta 在 S1 产生的异常（除 access fault 外）
//      · 入口 2,3（再一组 StorePipelineWidth）：sta 的 access fault，在 S2 产生
//      · 入口 4,5（VecStorePipelineWidth）：向量 store 异常
//      · 入口 6：SoC 侧产生的非数据错误（只可能是 hardwareError，故仅 excVec bit19）
//  在所有报上来的 store 异常里**按 robIdx 选最老**的一条，锁存进单条 req 寄存器，
//  持续把它的虚/物理地址信息输出给 CSR。
//
//  ── 与 Lq 的关键差异（务必区分，否则 FM/UT 不过）─────────────────────────────
//    1. 入队过滤时机：Store 在 **S1** 就把 “valid & !flush(当拍redirect) & 带异常” 算进
//       s1_valid；S2 只再排除一次 **当拍 redirect**（不像 Lq 还要排除 RegNext(redirect)），
//       且 S2 不再重判异常（S1 已判）。s2_req 的写使能是完整的 s1_valid。
//    2. 锁存替换的“平手维度”：Store 用 isNotBefore（>=，含 flag 异常情形），Lq 用严格相等。
//
//  本核为纯叶子，与 golden StoreExceptionBuffer.sv 同构。讲解见
//  docs/memblock/StoreExceptionBuffer.md。
// =============================================================================
module xs_StoreExceptionBuffer_core
  import exceptionbuffer_pkg::*;
#(
  parameter int ENQ_NUM = 7   // StorePipelineWidth*2 + VecStorePipelineWidth + 1
)(
  input  logic clock,
  input  logic reset,

  // ---- 重定向 ----
  input  logic     redirect_valid,
  input  rob_ptr_t redirect_robIdx,
  input  logic     redirect_level,

  // ---- 各 store 流水 S1 报上来的请求 ----
  input  logic       [ENQ_NUM-1:0]      req_valid,
  input  rob_ptr_t   [ENQ_NUM-1:0]      req_robIdx,
  input  logic [ENQ_NUM-1:0][UOPIDX_W-1:0] req_uopIdx,
  input  logic [ENQ_NUM-1:0][5:0]       req_excVec,   // 6 个相关 Sta 异常位（见 pkg/doc）
  input  logic [ENQ_NUM-1:0][63:0]      req_fullva,
  input  logic       [ENQ_NUM-1:0]      req_vaNeedExt,
  input  logic [ENQ_NUM-1:0][63:0]      req_gpaddr,
  input  logic       [ENQ_NUM-1:0]      req_isHyper,
  input  logic       [ENQ_NUM-1:0]      req_isForVSnonLeafPTE,

  // ---- 输出 ----
  output logic [63:0] exc_vaddr,
  output logic        exc_vaNeedExt,
  output logic        exc_isHyper,
  output logic [63:0] exc_gpaddr,
  output logic        exc_isForVSnonLeafPTE
);

  // ===========================================================================
  //  S1 入队过滤（组合）：valid 且未被当拍 redirect 冲刷 且 确实带 Sta 异常
  // ===========================================================================
  logic [ENQ_NUM-1:0] s1_valid;
  always_comb begin
    for (int w = 0; w < ENQ_NUM; w++) begin
      logic flush, has_exc;
      flush   = rob_need_flush(redirect_valid, redirect_level, req_robIdx[w], redirect_robIdx);
      has_exc = |req_excVec[w];
      s1_valid[w] = req_valid[w] & ~flush & has_exc;
    end
  end

  // ===========================================================================
  //  S2 流水寄存器（delay 1 cycle）：仅当 s1_valid[w] 时锁存该入口 payload。
  //  s2_valid_q = RegNext(s1_valid)。
  //
  //  ── golden 逐入口寄存器裁剪（firtool DCE）────────────────────────────────
  //    wrapper 已把缺失端口折成常量喂进本核（见 StoreExceptionBuffer_wrapper.sv）：
  //        · isHyper           入口 4,5,6 恒 0
  //        · vaNeedExt         入口 6     恒 1
  //        · gpaddr            入口 6     恒 0
  //        · isForVSnonLeafPTE 入口 6     恒 0
  //    golden 对这些恒定字段**不生成 S2 寄存器**（s2_req_4/5 无 isHyper 寄存器；
  //    s2_req_6 只有 uopIdx/robIdx/fullva 寄存器）。若本核对所有入口统一存全字段，
  //    这些恒定字段会成为 impl-only 死寄存器 → FM 判 4 个 unmatched compare point。
  //    故此处**按 golden 形状逐入口裁剪存储**：折叠字段不进 s2_req 寄存器，改由组合
  //    view（s2_view）把常量补回，供后续选择树读取（与 golden 逐字段选择等价）。
  // ===========================================================================
  typedef struct packed {
    rob_ptr_t            robIdx;
    logic [UOPIDX_W-1:0] uopIdx;
    logic [63:0]         fullva;
    logic                vaNeedExt;
    logic [63:0]         gpaddr;
    logic                isHyper;
    logic                isForVSnonLeafPTE;
  } s2_entry_t;

  // 仅存 golden 为该入口生成的寄存器字段：
  //   入口 0..3：全字段     入口 4,5：除 isHyper 外全字段     入口 6：仅 uopIdx/robIdx/fullva
  rob_ptr_t            s2_robIdx      [ENQ_NUM];   // 全入口有
  logic [UOPIDX_W-1:0] s2_uopIdx      [ENQ_NUM];   // 全入口有
  logic [63:0]         s2_fullva      [ENQ_NUM];   // 全入口有
  logic                s2_vaNeedExt   [0:5];       // 入口 0..5（6 折常量 1）
  logic [63:0]         s2_gpaddr      [0:5];       // 入口 0..5（6 折常量 0）
  logic                s2_isHyper     [0:3];       // 入口 0..3（4,5,6 折常量 0）
  logic                s2_isForVS     [0:5];       // 入口 0..5（6 折常量 0）
  logic [ENQ_NUM-1:0]  s2_valid_q;

  always_ff @(posedge clock) begin
    for (int w = 0; w < ENQ_NUM; w++) begin
      if (s1_valid[w]) begin
        s2_robIdx[w] <= req_robIdx[w];
        s2_uopIdx[w] <= req_uopIdx[w];
        s2_fullva[w] <= req_fullva[w];
      end
    end
    for (int w = 0; w <= 5; w++) begin
      if (s1_valid[w]) begin
        s2_vaNeedExt[w] <= req_vaNeedExt[w];
        s2_gpaddr[w]    <= req_gpaddr[w];
        s2_isForVS[w]   <= req_isForVSnonLeafPTE[w];
      end
    end
    for (int w = 0; w <= 3; w++) begin
      if (s1_valid[w]) begin
        s2_isHyper[w] <= req_isHyper[w];
      end
    end
    // 对齐 golden：s2_valid_REG* 为无复位 RegNext（golden 仅 req_valid 有异步复位）。
    s2_valid_q <= s1_valid;
  end

  // 组合 view：把 golden DCE 折掉的恒定字段补回常量，供选择树按统一 struct 读取。
  s2_entry_t [ENQ_NUM-1:0] s2_req;
  always_comb begin
    for (int w = 0; w < ENQ_NUM; w++) begin
      s2_req[w].robIdx            = s2_robIdx[w];
      s2_req[w].uopIdx            = s2_uopIdx[w];
      s2_req[w].fullva            = s2_fullva[w];
      s2_req[w].vaNeedExt         = (w <= 5) ? s2_vaNeedExt[w] : 1'b1;  // 入口6折常量1
      s2_req[w].gpaddr            = (w <= 5) ? s2_gpaddr[w]    : 64'h0; // 入口6折常量0
      s2_req[w].isHyper           = (w <= 3) ? s2_isHyper[w]   : 1'b0;  // 入口4,5,6折常量0
      s2_req[w].isForVSnonLeafPTE = (w <= 5) ? s2_isForVS[w]   : 1'b0;  // 入口6折常量0
    end
  end

  // ===========================================================================
  //  S2 入队判定：RegNext(s1_valid) 且未被**当拍** redirect 冲刷（仅此一次，无 RegNext）
  // ===========================================================================
  logic [ENQ_NUM-1:0] s2_enqueue;
  always_comb begin
    for (int w = 0; w < ENQ_NUM; w++) begin
      logic flush;
      flush = rob_need_flush(redirect_valid, redirect_level, s2_req[w].robIdx, redirect_robIdx);
      s2_enqueue[w] = s2_valid_q[w] & ~flush;
    end
  end

  // ===========================================================================
  //  选最老（平衡归约树）
  //  Chisel selectOldest 把 7 路递归二分：左 {0,1,2}，右 {3,4,5,6}。
  //    左   = pick2(0, pick2(1,2))
  //    右   = pick2( pick2(3,4), pick2(5,6) )
  //    根   = pick2(左, 右)
  //  Store 的“平手维度”同样用严格语义（eq_is_not_before=0）；区别仅在最终锁存替换。
  // ===========================================================================
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

  logic      sel_v;
  s2_entry_t sel_e;
  always_comb begin
    logic      l_v, r_v, l12_v, r34_v, r56_v;
    s2_entry_t l_e, r_e, l12_e, r34_e, r56_e;
    // 左 {0,1,2}
    pick2(s2_enqueue[1], s2_req[1], s2_enqueue[2], s2_req[2], l12_v, l12_e);
    pick2(s2_enqueue[0], s2_req[0], l12_v,         l12_e,     l_v,   l_e);
    // 右 {3,4,5,6}
    pick2(s2_enqueue[3], s2_req[3], s2_enqueue[4], s2_req[4], r34_v, r34_e);
    pick2(s2_enqueue[5], s2_req[5], s2_enqueue[6], s2_req[6], r56_v, r56_e);
    pick2(r34_v, r34_e, r56_v, r56_e, r_v, r_e);
    // 根
    pick2(l_v, l_e, r_v, r_e, sel_v, sel_e);
  end

  // ===========================================================================
  //  锁存最老异常（单条 req 寄存器）
  // ===========================================================================
  logic      req_valid_r;
  s2_entry_t req_r;
  logic      any_enqueue;
  assign any_enqueue = |s2_enqueue;

  logic req_flush;
  assign req_flush = rob_need_flush(redirect_valid, redirect_level, req_r.robIdx, redirect_robIdx);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) req_valid_r <= 1'b0;
    else if (req_valid_r & req_flush) req_valid_r <= any_enqueue;
    else if (any_enqueue)             req_valid_r <= 1'b1;
  end

  // 替换条件 = sel_v & ( isAfter(req,sel) || (isNotBefore(req,sel) && req.uopIdx>sel.uopIdx) )
  //   注意：Store 用 isNotBefore（>=）作平手维度（eq_is_not_before=1），与 Lq 的严格相等不同。
  logic replace_by_sel;
  assign replace_by_sel = older_pick_b(req_valid_r ? 1'b1 : 1'b0, sel_v,
                                       req_r.robIdx, sel_e.robIdx,
                                       req_r.uopIdx, sel_e.uopIdx, 1'b1)
                          & sel_v;
  always_ff @(posedge clock) begin
    if (req_valid_r) begin
      if (replace_by_sel) req_r <= sel_e;
    end else if (any_enqueue) begin
      req_r <= sel_e;
    end
  end

  // ===========================================================================
  //  输出
  // ===========================================================================
  assign exc_vaddr             = req_r.fullva;
  assign exc_vaNeedExt         = req_r.vaNeedExt;
  assign exc_isHyper           = req_r.isHyper;
  assign exc_gpaddr            = req_r.gpaddr;
  assign exc_isForVSnonLeafPTE = req_r.isForVSnonLeafPTE;

endmodule
