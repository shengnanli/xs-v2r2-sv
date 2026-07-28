// xs_VSMergeBufferImp_core —— 向量 store 16 条目 merge buffer 可读核。
// 手写重写, bug-for-bug 对齐 golden VSMergeBufferImp.sv(firtool-1.62.1)。
// generate-for 单条目模板 + 数组; 组合 glue 用 always_comb; 子模块
// FreeList_1 / NewPipelineConnectPipe_27 由 wrapper 例化(两侧同 elaborate)。
// _GEN_/_T_ 密度 = 0(仅注释引用 golden 名)。
// 依赖 xs_vsmergebuffer_pkg(由编译列表 RTL_SRCS 先行编译)。

module xs_VSMergeBufferImp_core
  import xs_vsmergebuffer_pkg::*;
(
  input          clock,
  input          reset,
  // redirect
  input          io_redirect_valid,
  input          io_redirect_bits_robIdx_flag,
  input  [7:0]   io_redirect_bits_robIdx_value,
  input          io_redirect_bits_level,
  // fromPipeline(flow 回填)
  input          io_fromPipeline_0_valid,
  input  [3:0]   io_fromPipeline_0_bits_mBIndex,
  input          io_fromPipeline_0_bits_hit,
  input  [3:0]   io_fromPipeline_0_bits_trigger,
  input          io_fromPipeline_0_bits_exceptionVec_3,
  input          io_fromPipeline_0_bits_exceptionVec_6,
  input          io_fromPipeline_0_bits_exceptionVec_7,
  input          io_fromPipeline_0_bits_exceptionVec_15,
  input          io_fromPipeline_0_bits_exceptionVec_19,
  input          io_fromPipeline_0_bits_exceptionVec_23,
  input          io_fromPipeline_0_bits_hasException,
  input  [63:0]  io_fromPipeline_0_bits_vaddr,
  input          io_fromPipeline_0_bits_vaNeedExt,
  input  [63:0]  io_fromPipeline_0_bits_gpaddr,
  input          io_fromPipeline_0_bits_isForVSnonLeafPTE,
  input  [7:0]   io_fromPipeline_0_bits_vstart,
  input  [7:0]   io_fromPipeline_0_bits_elemIdx,
  input  [15:0]  io_fromPipeline_0_bits_mask,
  // fromSplit(分配入队)
  output         io_fromSplit_0_req_ready,
  input          io_fromSplit_0_req_valid,
  input  [15:0]  io_fromSplit_0_req_bits_mask,
  input  [49:0]  io_fromSplit_0_req_bits_vaddr,
  input  [4:0]   io_fromSplit_0_req_bits_flowNum,
  input  [8:0]   io_fromSplit_0_req_bits_uop_fuOpType,
  input          io_fromSplit_0_req_bits_uop_vecWen,
  input          io_fromSplit_0_req_bits_uop_v0Wen,
  input          io_fromSplit_0_req_bits_uop_vlWen,
  input          io_fromSplit_0_req_bits_uop_vpu_vma,
  input          io_fromSplit_0_req_bits_uop_vpu_vta,
  input  [1:0]   io_fromSplit_0_req_bits_uop_vpu_vsew,
  input  [2:0]   io_fromSplit_0_req_bits_uop_vpu_vlmul,
  input          io_fromSplit_0_req_bits_uop_vpu_vm,
  input  [6:0]   io_fromSplit_0_req_bits_uop_vpu_vuopIdx,
  input  [127:0] io_fromSplit_0_req_bits_uop_vpu_vmask,
  input  [7:0]   io_fromSplit_0_req_bits_uop_vpu_vl,
  input  [2:0]   io_fromSplit_0_req_bits_uop_vpu_nf,
  input  [1:0]   io_fromSplit_0_req_bits_uop_vpu_veew,
  input  [6:0]   io_fromSplit_0_req_bits_uop_uopIdx,
  input  [7:0]   io_fromSplit_0_req_bits_uop_pdest,
  input          io_fromSplit_0_req_bits_uop_robIdx_flag,
  input  [7:0]   io_fromSplit_0_req_bits_uop_robIdx_value,
  input  [63:0]  io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime,
  input  [63:0]  io_fromSplit_0_req_bits_uop_debugInfo_selectTime,
  input  [63:0]  io_fromSplit_0_req_bits_uop_debugInfo_issueTime,
  input          io_fromSplit_0_req_bits_uop_lqIdx_flag,
  input  [6:0]   io_fromSplit_0_req_bits_uop_lqIdx_value,
  input          io_fromSplit_0_req_bits_uop_sqIdx_flag,
  input  [5:0]   io_fromSplit_0_req_bits_uop_sqIdx_value,
  input  [7:0]   io_fromSplit_0_req_bits_vlmax,
  output         io_fromSplit_0_resp_valid,
  output [3:0]   io_fromSplit_0_resp_bits_mBIndex,
  // toLsq
  output         io_toLsq_0_valid,
  output         io_toLsq_0_bits_robidx_flag,
  output [7:0]   io_toLsq_0_bits_robidx_value,
  output [6:0]   io_toLsq_0_bits_uopidx,
  output [63:0]  io_toLsq_0_bits_vaddr,
  output         io_toLsq_0_bits_vaNeedExt,
  output [49:0]  io_toLsq_0_bits_gpaddr,
  output         io_toLsq_0_bits_isForVSnonLeafPTE,
  output         io_toLsq_0_bits_feedback_0,
  output         io_toLsq_0_bits_feedback_1,
  output         io_toLsq_0_bits_exceptionVec_3,
  output         io_toLsq_0_bits_exceptionVec_6,
  output         io_toLsq_0_bits_exceptionVec_7,
  output         io_toLsq_0_bits_exceptionVec_15,
  output         io_toLsq_0_bits_exceptionVec_19,
  output         io_toLsq_0_bits_exceptionVec_23,
  // feedback(打拍 REG)
  output         io_feedback_0_valid,
  output         io_feedback_0_bits_hit,
  output         io_feedback_0_bits_sqIdx_flag,
  output [5:0]   io_feedback_0_bits_sqIdx_value,
  output         io_feedback_0_bits_lqIdx_flag,
  output [6:0]   io_feedback_0_bits_lqIdx_value,
  input  [3:0]   io_fromMisalignBuffer_mbIndex,
  input          io_fromMisalignBuffer_flush,
  // 与子模块(wrapper 例化)连接的端口
  input  [3:0]   allocateSlot,      // FreeList io_allocateSlot_0
  output         doAllocate,        // FreeList io_doAllocate_0 (= _GEN)
  output logic [15:0] freeMaskVec,  // FreeList io_free(always_comb 驱动)
  input  [4:0]   validCount,        // FreeList io_validCount
  // pipelineConnect(NewPipelineConnectPipe_27)
  output         pc_in_valid,
  input          pc_in_ready,
  output         pc_isFlush,
  input          pc_out_robIdx_flag,
  input  [7:0]   pc_out_robIdx_value,
  // pipelineConnect io_in_bits(uop payload, 从 entries[entryIdx] 取)
  output         pc_in_uop_exceptionVec_3,
  output         pc_in_uop_exceptionVec_6,
  output         pc_in_uop_exceptionVec_7,
  output         pc_in_uop_exceptionVec_15,
  output         pc_in_uop_exceptionVec_19,
  output         pc_in_uop_exceptionVec_23,
  output [3:0]   pc_in_uop_trigger,
  output [8:0]   pc_in_uop_fuOpType,
  output         pc_in_uop_vecWen,
  output         pc_in_uop_v0Wen,
  output         pc_in_uop_vlWen,
  output         pc_in_uop_flushPipe,
  output         pc_in_uop_vpu_vma,
  output         pc_in_uop_vpu_vta,
  output [1:0]   pc_in_uop_vpu_vsew,
  output [2:0]   pc_in_uop_vpu_vlmul,
  output         pc_in_uop_vpu_vm,
  output [7:0]   pc_in_uop_vpu_vstart,
  output [6:0]   pc_in_uop_vpu_vuopIdx,
  output [127:0] pc_in_uop_vpu_vmask,
  output [7:0]   pc_in_uop_vpu_vl,
  output [2:0]   pc_in_uop_vpu_nf,
  output [1:0]   pc_in_uop_vpu_veew,
  output [7:0]   pc_in_uop_pdest,
  output         pc_in_uop_robIdx_flag,
  output [7:0]   pc_in_uop_robIdx_value,
  output [63:0]  pc_in_uop_debugInfo_enqRsTime,
  output [63:0]  pc_in_uop_debugInfo_selectTime,
  output [63:0]  pc_in_uop_debugInfo_issueTime,
  output         pc_in_uop_replayInst
);

  // ============================================================
  // 状态寄存器: 16 条目 + allocated/uopFinish/needRSReplay 位向量
  // ============================================================
  vsmb_entry_t entries [VS_SIZE];
  logic [VS_SIZE-1:0] allocated;
  logic [VS_SIZE-1:0] uopFinish;
  logic [VS_SIZE-1:0] needRSReplay;

  // feedback 打拍 REG(golden io_feedback_0_*_REG / _r_*)
  logic       fb_valid_reg;
  logic       fb_hit_reg;
  logic       fb_sqIdx_flag_reg;
  logic [5:0] fb_sqIdx_value_reg;
  logic       fb_lqIdx_flag_reg;
  logic [6:0] fb_lqIdx_value_reg;

  // ============================================================
  // 分配决策(golden _GEN / _GEN_0..15)
  // ============================================================
  // _flushItself_T_6 = {redirect robIdx}
  wire [8:0] redirRobIdx = {io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value};
  // _freeCount_T = 16 - validCount
  wire [4:0] freeCount = 5'(5'h10 - validCount);

  // req 命中重定向判定(golden _GEN 中的重定向屏蔽项)
  wire reqFlushed =
    io_redirect_valid
    & (io_redirect_bits_level
       & {io_fromSplit_0_req_bits_uop_robIdx_flag,
          io_fromSplit_0_req_bits_uop_robIdx_value} == redirRobIdx
       | io_fromSplit_0_req_bits_uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ io_fromSplit_0_req_bits_uop_robIdx_value > io_redirect_bits_robIdx_value);
  // _GEN = req 有效 & 未被 flush & 有空槽
  wire doAlloc = io_fromSplit_0_req_valid & ~reqFlushed & (|freeCount);
  assign doAllocate = doAlloc;

  // one-hot 入队: allocEnq[i] = _GEN & allocateSlot==i (golden _GEN_0.._GEN_15)
  logic [VS_SIZE-1:0] allocEnq;
  always_comb begin
    for (int i = 0; i < VS_SIZE; i++)
      allocEnq[i] = doAlloc & (allocateSlot == 4'(i));
  end

  // needCancel[i]: 重定向命中且已分配(golden needCancel_0..15)
  logic [VS_SIZE-1:0] needCancel;
  always_comb begin
    for (int i = 0; i < VS_SIZE; i++)
      needCancel[i] =
        io_redirect_valid
        & (io_redirect_bits_level
           & {entries[i].uop_robIdx_flag, entries[i].uop_robIdx_value} == redirRobIdx
           | entries[i].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
           ^ entries[i].uop_robIdx_value > io_redirect_bits_robIdx_value)
        & allocated[i];
  end

  // ============================================================
  // fromPipeline flow 命中 slot 判定(golden _GEN_25.._GEN_39, entryIsUS 等)
  // ============================================================
  wire [3:0] mBidx = io_fromPipeline_0_bits_mBIndex;
  // pipeHit[i] = mBIndex == i (仅用于 flowNum/异常合并的按槽写)
  // 组合流水更新数据(golden 一律用 [mBIndex] 索引取值)

  // _entries_flowNum_T = flowNum[mBIndex] - 1
  wire [4:0] flowNumDec = 5'(entries[mBidx].flowNum - 5'h1);

  // mergePortMatrixHasExcp_0_0
  wire mergeHasExcp =
    io_fromPipeline_0_bits_hasException | io_fromPipeline_0_bits_trigger == 4'h1;

  // entryIsUS(unit-stride 判定, 基于目标槽 fuOpType)
  wire entryIsUS =
    entries[mBidx].uop_fuOpType[6:5] == 2'h0
    & (entries[mBidx].uop_fuOpType[8] ^ entries[mBidx].uop_fuOpType[7]);

  // entryExcp: 目标槽当前是否已有异常(golden entryExcp)
  wire entryExcp =
    ((|{entries[mBidx].exceptionVec_23,
        entries[mBidx].exceptionVec_19,
        entries[mBidx].exceptionVec_15,
        entries[mBidx].exceptionVec_7,
        entries[mBidx].exceptionVec_6,
        entries[mBidx].exceptionVec_3})
     | entries[mBidx].uop_trigger == 4'h1)
    & (|entries[mBidx].mask);

  // new merge 值(golden _sel_oldest_T_5_* / new_vec_2_*)
  wire [3:0]  sel_trigger  = mergeHasExcp ? io_fromPipeline_0_bits_trigger : 4'h0;
  wire        new_vec_3    = mergeHasExcp & io_fromPipeline_0_bits_exceptionVec_3;
  wire        new_vec_6    = mergeHasExcp & io_fromPipeline_0_bits_exceptionVec_6;
  wire        new_vec_7    = mergeHasExcp & io_fromPipeline_0_bits_exceptionVec_7;
  wire        new_vec_15   = mergeHasExcp & io_fromPipeline_0_bits_exceptionVec_15;
  wire        new_vec_19   = mergeHasExcp & io_fromPipeline_0_bits_exceptionVec_19;
  wire        new_vec_23   = mergeHasExcp & io_fromPipeline_0_bits_exceptionVec_23;
  wire        sel_vaNeedExt = mergeHasExcp & io_fromPipeline_0_bits_vaNeedExt;
  wire [49:0] sel_gpaddr   = mergeHasExcp ? io_fromPipeline_0_bits_gpaddr[49:0] : 50'h0;
  wire        sel_isForVSnonLeafPTE = mergeHasExcp & io_fromPipeline_0_bits_isForVSnonLeafPTE;
  wire [7:0]  sel_elemIdx  = mergeHasExcp ? io_fromPipeline_0_bits_elemIdx : 8'h0;
  wire [15:0] sel_mask     = mergeHasExcp ? io_fromPipeline_0_bits_mask : 16'h0;

  // 计算 sel_mask 首个置位下标偏移(golden _vaddr_T 中的优先编码)
  logic [3:0] maskFirstIdx;
  always_comb begin
    if (~entryIsUS | sel_mask[0])       maskFirstIdx = 4'h0;
    else if (sel_mask[1])               maskFirstIdx = 4'h1;
    else if (sel_mask[2])               maskFirstIdx = 4'h2;
    else if (sel_mask[3])               maskFirstIdx = 4'h3;
    else if (sel_mask[4])               maskFirstIdx = 4'h4;
    else if (sel_mask[5])               maskFirstIdx = 4'h5;
    else if (sel_mask[6])               maskFirstIdx = 4'h6;
    else if (sel_mask[7])               maskFirstIdx = 4'h7;
    else if (sel_mask[8])               maskFirstIdx = 4'h8;
    else if (sel_mask[9])               maskFirstIdx = 4'h9;
    else if (sel_mask[10])              maskFirstIdx = 4'hA;
    else if (sel_mask[11])              maskFirstIdx = 4'hB;
    else if (sel_mask[12])              maskFirstIdx = 4'hC;
    else if (sel_mask[13])              maskFirstIdx = 4'hD;
    else if (sel_mask[14])              maskFirstIdx = 4'hE;
    else                                maskFirstIdx = {4{sel_mask[15]}};
  end
  // _vaddr_T
  wire [63:0] merge_vaddr =
    64'((mergeHasExcp ? io_fromPipeline_0_bits_vaddr : 64'h0) + {60'h0, maskFirstIdx});

  // vstart(golden vstart)
  wire [7:0] merge_vstart =
    entryIsUS
      ? (mergeHasExcp ? io_fromPipeline_0_bits_vstart : 8'h0)
      : sel_elemIdx & 8'(entries[mBidx].vlmax - 8'h1);

  // _GEN_111: 是否在本拍更新目标槽的异常数据
  wire updateExcp =
    (entries[mBidx].elemIdx >= sel_elemIdx & entryExcp & mergeHasExcp
     | ~entryExcp & mergeHasExcp) & io_fromPipeline_0_valid;

  // _GEN_107: 分配时 vaddr 复位值 = {14'h0, req_vaddr}
  wire [63:0] allocVaddr = {14'h0, io_fromSplit_0_req_bits_vaddr};

  // ============================================================
  // 选择写回(PriorityEncoder, 最低置位优先) —— golden entryIdx/selFire
  // ============================================================
  logic [3:0] entryIdx;
  always_comb begin
    entryIdx = 4'h0;
    for (int i = VS_SIZE-1; i >= 0; i--)
      if (uopFinish[i]) entryIdx = 4'(i);
  end
  wire selFire = (|uopFinish) & pc_in_ready;

  // selHit[i] = entryIdx==i(golden _GEN_43/45/../73 的相等项)
  logic [VS_SIZE-1:0] selHit;
  always_comb begin
    for (int i = 0; i < VS_SIZE; i++)
      selHit[i] = (entryIdx == 4'(i));
  end
  // selFireHit[i] = selFire & entryIdx==i(golden _GEN_44/46/../73)
  wire [VS_SIZE-1:0] selFireHit = {VS_SIZE{selFire}} & selHit;

  // freeMaskVec[i]: golden freeMaskVec_i = selFireHit ? allocated[entryIdx] : needCancel_i
  always_comb begin
    for (int i = 0; i < VS_SIZE; i++)
      freeMaskVec[i] = selFireHit[i] ? allocated[entryIdx] : needCancel[i];
  end

  // feedbackValid = selFire & allocated[entryIdx]
  wire feedbackValid = selFire & allocated[entryIdx];

  // pipelineOut_0_valid(是否推入 pipelineConnect)
  wire [8:0] selRobIdx = {entries[entryIdx].uop_robIdx_flag, entries[entryIdx].uop_robIdx_value};
  wire differentFlag = entries[entryIdx].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag;
  wire compare = entries[entryIdx].uop_robIdx_value > io_redirect_bits_robIdx_value;
  wire pipelineOut_0_valid =
    feedbackValid & ~needRSReplay[entryIdx]
    & ~(io_redirect_valid
        & (io_redirect_bits_level & selRobIdx == redirRobIdx | differentFlag ^ compare));

  // _GEN_102: 选中槽异常向量(用于 feedback_0/1)
  wire [5:0] selExcpVec =
    {entries[entryIdx].exceptionVec_23,
     entries[entryIdx].exceptionVec_19,
     entries[entryIdx].exceptionVec_15,
     entries[entryIdx].exceptionVec_7,
     entries[entryIdx].exceptionVec_6,
     entries[entryIdx].exceptionVec_3};

  // ============================================================
  // 状态更新辅助(golden _GEN_112..127 / _GEN_128..143 / _GEN_144)
  // ============================================================
  wire [VS_SIZE-1:0] allocOrAllocated = allocEnq | allocated;         // _GEN_112..127
  wire [VS_SIZE-1:0] cancelOrAlloc    = needCancel | allocEnq;         // _GEN_128..143
  wire pipeMiss = io_fromPipeline_0_valid & ~io_fromPipeline_0_bits_hit; // _GEN_144

  // ============================================================
  // 时序块 1: entries 装填 + flow 更新 + 异常合并 + feedback REG
  // (golden always @(posedge clock), 无 reset)
  // ============================================================
  always_ff @(posedge clock) begin
    for (int i = 0; i < VS_SIZE; i++) begin
      // 分配装填(_GEN_i)
      if (allocEnq[i]) begin
        entries[i].mask                    <= io_fromSplit_0_req_bits_mask;
        entries[i].uop_fuOpType            <= io_fromSplit_0_req_bits_uop_fuOpType;
        entries[i].uop_vecWen              <= io_fromSplit_0_req_bits_uop_vecWen;
        entries[i].uop_v0Wen               <= io_fromSplit_0_req_bits_uop_v0Wen;
        entries[i].uop_vlWen               <= io_fromSplit_0_req_bits_uop_vlWen;
        entries[i].uop_vpu_vma             <= io_fromSplit_0_req_bits_uop_vpu_vma;
        entries[i].uop_vpu_vta             <= io_fromSplit_0_req_bits_uop_vpu_vta;
        entries[i].uop_vpu_vsew            <= io_fromSplit_0_req_bits_uop_vpu_vsew;
        entries[i].uop_vpu_vlmul           <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
        entries[i].uop_vpu_vm              <= io_fromSplit_0_req_bits_uop_vpu_vm;
        entries[i].uop_vpu_vuopIdx         <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
        entries[i].uop_vpu_vmask           <= io_fromSplit_0_req_bits_uop_vpu_vmask;
        entries[i].uop_vpu_vl              <= io_fromSplit_0_req_bits_uop_vpu_vl;
        entries[i].uop_vpu_nf              <= io_fromSplit_0_req_bits_uop_vpu_nf;
        entries[i].uop_vpu_veew            <= io_fromSplit_0_req_bits_uop_vpu_veew;
        entries[i].uop_uopIdx              <= io_fromSplit_0_req_bits_uop_uopIdx;
        entries[i].uop_pdest               <= io_fromSplit_0_req_bits_uop_pdest;
        entries[i].uop_robIdx_flag         <= io_fromSplit_0_req_bits_uop_robIdx_flag;
        entries[i].uop_robIdx_value        <= io_fromSplit_0_req_bits_uop_robIdx_value;
        entries[i].uop_debugInfo_enqRsTime  <= io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
        entries[i].uop_debugInfo_selectTime <= io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
        entries[i].uop_debugInfo_issueTime  <= io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
        entries[i].uop_lqIdx_flag          <= io_fromSplit_0_req_bits_uop_lqIdx_flag;
        entries[i].uop_lqIdx_value         <= io_fromSplit_0_req_bits_uop_lqIdx_value;
        entries[i].uop_sqIdx_flag          <= io_fromSplit_0_req_bits_uop_sqIdx_flag;
        entries[i].uop_sqIdx_value         <= io_fromSplit_0_req_bits_uop_sqIdx_value;
        entries[i].vlmax                   <= io_fromSplit_0_req_bits_vlmax;
      end

      // flowNum: flow 命中该槽时 --, 否则分配时载入
      if (io_fromPipeline_0_valid & (mBidx == 4'(i)))
        entries[i].flowNum <= flowNumDec;
      else if (allocEnq[i])
        entries[i].flowNum <= io_fromSplit_0_req_bits_flowNum;

      // 异常合并 / 分配复位
      if (updateExcp & (mBidx == 4'(i))) begin
        entries[i].exceptionVec_3    <= new_vec_3;
        entries[i].exceptionVec_6    <= new_vec_6;
        entries[i].exceptionVec_7    <= new_vec_7;
        entries[i].exceptionVec_15   <= new_vec_15;
        entries[i].exceptionVec_19   <= new_vec_19;
        entries[i].exceptionVec_23   <= new_vec_23;
        entries[i].uop_trigger       <= sel_trigger;
        entries[i].elemIdx           <= sel_elemIdx;
        entries[i].vstart            <= merge_vstart;
        entries[i].vaNeedExt         <= sel_vaNeedExt;
        entries[i].vaddr             <= merge_vaddr;
        entries[i].gpaddr            <= sel_gpaddr;
        entries[i].isForVSnonLeafPTE <= sel_isForVSnonLeafPTE;
      end
      else begin
        entries[i].exceptionVec_3    <= ~allocEnq[i] & entries[i].exceptionVec_3;
        entries[i].exceptionVec_6    <= ~allocEnq[i] & entries[i].exceptionVec_6;
        entries[i].exceptionVec_7    <= ~allocEnq[i] & entries[i].exceptionVec_7;
        entries[i].exceptionVec_15   <= ~allocEnq[i] & entries[i].exceptionVec_15;
        entries[i].exceptionVec_19   <= ~allocEnq[i] & entries[i].exceptionVec_19;
        entries[i].exceptionVec_23   <= ~allocEnq[i] & entries[i].exceptionVec_23;
        if (allocEnq[i]) begin
          entries[i].uop_trigger <= 4'h0;
          entries[i].elemIdx     <= 8'hFF;
          entries[i].vstart      <= 8'h0;
          entries[i].vaddr       <= allocVaddr;
        end
      end

      // flushPipe / replayInst: 分配时清 0, 否则保持
      entries[i].uop_flushPipe  <= ~allocEnq[i] & entries[i].uop_flushPipe;
      entries[i].uop_replayInst <= ~allocEnq[i] & entries[i].uop_replayInst;
    end

    // feedback 打拍 REG(golden 尾部)
    fb_valid_reg <= feedbackValid;
    if (feedbackValid) begin
      fb_hit_reg        <= ~needRSReplay[entryIdx];
      fb_sqIdx_flag_reg  <= entries[entryIdx].uop_sqIdx_flag;
      fb_sqIdx_value_reg <= entries[entryIdx].uop_sqIdx_value;
      fb_lqIdx_flag_reg  <= entries[entryIdx].uop_lqIdx_flag;
      fb_lqIdx_value_reg <= entries[entryIdx].uop_lqIdx_value;
    end
  end

  // ============================================================
  // 时序块 2: allocated / uopFinish / needRSReplay 状态机
  // (golden always @(posedge clock or posedge reset))
  // ============================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      allocated    <= '0;
      uopFinish    <= '0;
      needRSReplay <= '0;
    end
    else begin
      for (int i = 0; i < VS_SIZE; i++) begin
        // allocated
        if (selFire)
          allocated[i] <= ~(selHit[i] | needCancel[i]) & allocOrAllocated[i];
        else
          allocated[i] <= ~needCancel[i] & allocOrAllocated[i];

        // uopFinish
        uopFinish[i] <=
          ~selFireHit[i]
          & (allocated[i] & entries[i].flowNum == 5'h0 & ~needCancel[i]
             | ~cancelOrAlloc[i] & uopFinish[i]);

        // needRSReplay
        needRSReplay[i] <=
          io_fromMisalignBuffer_flush & (io_fromMisalignBuffer_mbIndex == 4'(i))
          | ~selFireHit[i]
            & (pipeMiss & (mBidx == 4'(i)) | ~cancelOrAlloc[i] & needRSReplay[i]);
      end
    end
  end

  // ============================================================
  // 输出连线(golden 末端 assign)
  // ============================================================
  assign io_fromSplit_0_req_ready   = |freeCount;
  assign io_fromSplit_0_resp_valid  = |freeCount;
  assign io_fromSplit_0_resp_bits_mBIndex = allocateSlot;
  // uopWriteback 全部 payload 由 wrapper 内 pipelineConnect 直连输出(含 valid/robIdx)。

  // toLsq
  assign io_toLsq_0_valid                = feedbackValid & ~needRSReplay[entryIdx];
  assign io_toLsq_0_bits_robidx_flag     = entries[entryIdx].uop_robIdx_flag;
  assign io_toLsq_0_bits_robidx_value    = entries[entryIdx].uop_robIdx_value;
  assign io_toLsq_0_bits_uopidx          = entries[entryIdx].uop_uopIdx;
  assign io_toLsq_0_bits_vaddr           = entries[entryIdx].vaddr;
  assign io_toLsq_0_bits_vaNeedExt       = entries[entryIdx].vaNeedExt;
  assign io_toLsq_0_bits_gpaddr          = entries[entryIdx].gpaddr;
  assign io_toLsq_0_bits_isForVSnonLeafPTE = entries[entryIdx].isForVSnonLeafPTE;
  assign io_toLsq_0_bits_feedback_0      = |selExcpVec;
  assign io_toLsq_0_bits_feedback_1      = ~(|selExcpVec);
  assign io_toLsq_0_bits_exceptionVec_3  = entries[entryIdx].exceptionVec_3;
  assign io_toLsq_0_bits_exceptionVec_6  = entries[entryIdx].exceptionVec_6;
  assign io_toLsq_0_bits_exceptionVec_7  = entries[entryIdx].exceptionVec_7;
  assign io_toLsq_0_bits_exceptionVec_15 = entries[entryIdx].exceptionVec_15;
  assign io_toLsq_0_bits_exceptionVec_19 = entries[entryIdx].exceptionVec_19;
  assign io_toLsq_0_bits_exceptionVec_23 = entries[entryIdx].exceptionVec_23;

  // feedback(打拍 REG 输出)
  assign io_feedback_0_valid            = fb_valid_reg;
  assign io_feedback_0_bits_hit         = fb_hit_reg;
  assign io_feedback_0_bits_sqIdx_flag  = fb_sqIdx_flag_reg;
  assign io_feedback_0_bits_sqIdx_value = fb_sqIdx_value_reg;
  assign io_feedback_0_bits_lqIdx_flag  = fb_lqIdx_flag_reg;
  assign io_feedback_0_bits_lqIdx_value = fb_lqIdx_value_reg;

  // ============================================================
  // 子模块驱动信号
  // ============================================================
  // FreeList io_free = freeMaskVec(已在上方 always_comb 计算)。
  // pipelineConnect io_in payload 从 entries[entryIdx] 取。
  assign pc_in_valid = pipelineOut_0_valid;
  assign pc_in_uop_exceptionVec_3  = entries[entryIdx].exceptionVec_3;
  assign pc_in_uop_exceptionVec_6  = entries[entryIdx].exceptionVec_6;
  assign pc_in_uop_exceptionVec_7  = entries[entryIdx].exceptionVec_7;
  assign pc_in_uop_exceptionVec_15 = entries[entryIdx].exceptionVec_15;
  assign pc_in_uop_exceptionVec_19 = entries[entryIdx].exceptionVec_19;
  assign pc_in_uop_exceptionVec_23 = entries[entryIdx].exceptionVec_23;
  assign pc_in_uop_trigger      = entries[entryIdx].uop_trigger;
  assign pc_in_uop_fuOpType     = entries[entryIdx].uop_fuOpType;
  assign pc_in_uop_vecWen       = entries[entryIdx].uop_vecWen;
  assign pc_in_uop_v0Wen        = entries[entryIdx].uop_v0Wen;
  assign pc_in_uop_vlWen        = entries[entryIdx].uop_vlWen;
  assign pc_in_uop_flushPipe    = entries[entryIdx].uop_flushPipe;
  assign pc_in_uop_vpu_vma      = entries[entryIdx].uop_vpu_vma;
  assign pc_in_uop_vpu_vta      = entries[entryIdx].uop_vpu_vta;
  assign pc_in_uop_vpu_vsew     = entries[entryIdx].uop_vpu_vsew;
  assign pc_in_uop_vpu_vlmul    = entries[entryIdx].uop_vpu_vlmul;
  assign pc_in_uop_vpu_vm       = entries[entryIdx].uop_vpu_vm;
  assign pc_in_uop_vpu_vstart   = entries[entryIdx].vstart;
  assign pc_in_uop_vpu_vuopIdx  = entries[entryIdx].uop_vpu_vuopIdx;
  assign pc_in_uop_vpu_vmask    = entries[entryIdx].uop_vpu_vmask;
  assign pc_in_uop_vpu_vl       = entries[entryIdx].uop_vpu_vl;
  assign pc_in_uop_vpu_nf       = entries[entryIdx].uop_vpu_nf;
  assign pc_in_uop_vpu_veew     = entries[entryIdx].uop_vpu_veew;
  assign pc_in_uop_pdest        = entries[entryIdx].uop_pdest;
  assign pc_in_uop_robIdx_flag  = entries[entryIdx].uop_robIdx_flag;
  assign pc_in_uop_robIdx_value = entries[entryIdx].uop_robIdx_value;
  assign pc_in_uop_debugInfo_enqRsTime  = entries[entryIdx].uop_debugInfo_enqRsTime;
  assign pc_in_uop_debugInfo_selectTime = entries[entryIdx].uop_debugInfo_selectTime;
  assign pc_in_uop_debugInfo_issueTime  = entries[entryIdx].uop_debugInfo_issueTime;
  assign pc_in_uop_replayInst   = entries[entryIdx].uop_replayInst;

  // pipelineConnect io_isFlush(golden 内联表达式)
  assign pc_isFlush =
    pc_in_ready & pipelineOut_0_valid
      ? io_redirect_valid
        & (io_redirect_bits_level & selRobIdx == redirRobIdx | differentFlag ^ compare)
      : io_redirect_valid
        & (io_redirect_bits_level
           & {pc_out_robIdx_flag, pc_out_robIdx_value} == redirRobIdx
           | pc_out_robIdx_flag ^ io_redirect_bits_robIdx_flag
           ^ pc_out_robIdx_value > io_redirect_bits_robIdx_value);

endmodule
