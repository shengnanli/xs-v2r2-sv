// =============================================================================
// VecExcpDataMergeModule.sv —— 向量访存异常后的目的寄存器（vd）数据拼接器
//
// 在哪一层：Backend/CtrlBlock 旁。向量 load 在 vstart 处触发异常时，同一条指令前面
//   已经写过的元素（新 vd）要保留，异常点及之后的元素要恢复成旧 vd 的值。本模块在
//   ROB 提交异常后接管：从 RAB 收齐这条指令每个 vd 的 {逻辑寄存器号, 新物理号}，
//   从 RAT 收齐旧物理号，再逐个 vd 读 VPRF 的旧/新两份数据，按字节拼起来写回新物理号。
// 设计源：xiangshan/backend/VecExcpDataMergeModule.scala（kunminghu-v2，VLEN=128，
//   maxMergeNumPerCycle=4，RabCommitWidth=6）。
//
// 状态机（state，异步复位到 noExcp）：
//   noExcp  —— 等 ExceptionGen 送来异常信息；当拍把各种"直到第几个 vd"的边界算好锁存
//              （sWaitRab_*，无复位、以 fromExceptionGen.valid 为写使能），并按 maxVdIdx
//              置 commitNeeded。
//   waitRab —— RAB/RAT 每拍最多送 6 条映射；第一批要跳过前 1 条（strided 跳 2 条：这些
//              uop 只搬数据不写 vd），第二批不跳。收齐（collectedAllRegMap）后转 mergeVd，
//              currentIdx 从 useNewVdUntil（第一个含 vstart 的 vd）开始。
//   mergeVd —— currentIdx..+3 这 4 个 vd 同时读旧/新两份；字节号 >= e8offset 取旧值，
//              否则取新值。合并到 needMergeUntil 为止。
//   mvOldVd —— 余下的 vd 全部原样搬旧值（只读旧 vd）。到 handleUntil 为止。
//   finish  —— 清所有记账位，回 noExcp。
//   写回：读口 valid 打一拍即为写口 valid；currentIdx 每拍按写口 valid 个数前进。
//
// 怪癖（照 golden，bug-for-bug）：
//   * currentIdx 是 4 位，索引 8 项数组时只取低 3 位（回绕），比较边界时用全 4 位。
//   * maxVdIdx 只有 7 位，handleUntil 取其低 4 位：nf=7、EMUL=8 时 64 截成 0。
//   * needMergeUntil = (useNewVdUntil + nf) 先在 3 位里回绕，再 +1 扩成 4 位。
//   * nonSegIndexed 时用 "(vdIdx+1)<<n - 1"（RAB）/ "vdIdx<<n"（RAT）挑记账位，算出来 >= 8
//     的位置按 Chisel 写法退回第 0 项（不是 0）。
//   * sWaitRab_e8offset 是对 one-hot 的 Mux1H（四路同值），所以 deewOH 全 0 时为 0。
//   * 读口只有 r(0)/r(4) 的 isV0 可能为 1（其余恒 0，golden 端口表里已删）。
// 子模块：GetE8OffsetInVreg / NfMappedElemIdx / DelayN_13（busy 延一拍），本仓重写件。
// golden 对照：G1-canonical/golden-rtl/VecExcpDataMergeModule.sv
// =============================================================================
package vecexcpmerge_pkg;
  localparam int MAX_LMUL = 8;   // 一条向量指令最多 8 个 vd
  localparam int MERGE_N  = 4;   // 每拍合并/搬运的 vd 个数（maxMergeNumPerCycle）
  localparam int RAB_N    = 6;   // RAB/RAT 每拍提交宽度（RabCommitWidth）
  localparam int VLEN     = 128;
  localparam int VLENB    = VLEN / 8;

  typedef enum logic [2:0] {
    S_NO_EXCP  = 3'd0,
    S_WAIT_RAB = 3'd1,
    S_MERGE_VD = 3'd2,
    S_MV_OLDVD = 3'd3,
    S_FINISH   = 3'd4
  } state_e;

  // 来自 ExceptionGen 的向量异常描述（VecExcpInfo）
  typedef struct packed {
    logic [6:0] vstart;
    logic [1:0] vsew;
    logic [1:0] veew;
    logic [2:0] vlmul;
    logic [2:0] nf;
    logic       isStride;
    logic       isIndexed;
    logic       isWhole;
    logic       isVlm;
  } excp_info_t;

  // VLmul.makeNoLessThanM1(..).take(2)：分数 LMUL 当 1 看，结果 0..3 = log2(EMUL)
  function automatic logic [1:0] no_less_than_m1(input logic [2:0] lmul);
    return lmul[2] ? 2'd0 : lmul[1:0];
  endfunction

  // segShuffledRegIdxTable(nf)(dvemul)(vdIdx)：分段 load 的 vd 在寄存器组里的实际位置。
  // 只有 4 种 (字段数, EMUL) 组合需要重排，其余直通。
  function automatic logic [2:0] seg_shuffle(input logic [2:0] nf, input logic [1:0] dvemul,
                                             input logic [2:0] vd_idx);
    logic [2:0] tbl [MAX_LMUL];
    tbl = '{3'd0, 3'd1, 3'd2, 3'd3, 3'd4, 3'd5, 3'd6, 3'd7};
    if      (nf == 3'd1 && dvemul == 2'd1) tbl = '{3'd0, 3'd2, 3'd1, 3'd3, 3'd0, 3'd0, 3'd0, 3'd0}; // 2 字段 × EMUL2
    else if (nf == 3'd1 && dvemul == 2'd2) tbl = '{3'd0, 3'd4, 3'd1, 3'd5, 3'd2, 3'd6, 3'd3, 3'd7}; // 2 字段 × EMUL4
    else if (nf == 3'd2 && dvemul == 2'd1) tbl = '{3'd0, 3'd2, 3'd4, 3'd1, 3'd3, 3'd5, 3'd0, 3'd0}; // 3 字段 × EMUL2
    else if (nf == 3'd3 && dvemul == 2'd1) tbl = '{3'd0, 3'd2, 3'd4, 3'd6, 3'd1, 3'd3, 3'd5, 3'd7}; // 4 字段 × EMUL2
    return tbl[vd_idx];
  endfunction
endpackage

module xs_VecExcpDataMergeModule_core
  import vecexcpmerge_pkg::*;
(
  input  logic             clock,
  input  logic             reset,
  // ExceptionGen
  input  logic             excp_valid,
  input  excp_info_t       excp,
  // RAB 提交：{lreg, 新 preg}
  input  logic             rab_valid   [RAB_N],
  input  logic [5:0]       rab_lreg    [RAB_N],
  input  logic [6:0]       rab_preg    [RAB_N],
  // RAT 提交：旧 preg（向量 vd 与 v0 两路，任一有效即算）
  input  logic             rat_vec_valid [RAB_N],
  input  logic [6:0]       rat_vec_pdest [RAB_N],
  input  logic             rat_v0_valid  [RAB_N],
  input  logic [6:0]       rat_v0_pdest  [RAB_N],
  // VPRF 读回：[0..3] 旧 vd，[4..7] 新 vd（只有前 4 个带 valid）
  input  logic             vprf_valid  [MERGE_N],
  input  logic [VLEN-1:0]  vprf_data   [2*MERGE_N],
  // 去 VPRF 的读口（[0..3] 读旧 vd，[4..7] 读新 vd）与写口
  output logic             r_valid     [2*MERGE_N],
  output logic             r_isV0      [2*MERGE_N],
  output logic [6:0]       r_addr      [2*MERGE_N],
  output logic             w_valid     [MERGE_N],
  output logic             w_isV0      [MERGE_N],
  output logic [6:0]       w_addr      [MERGE_N],
  output logic [VLEN-1:0]  w_data      [MERGE_N],
  output logic             busy
);

  // ===========================================================================
  // §0 状态与记账寄存器
  // ===========================================================================
  state_e state;                                  // 异步复位
  logic [3:0] currentIdx;                         // 异步复位；当前处理到第几个 vd
  logic commitNeeded [MAX_LMUL];                  // 异步复位；该 vd 需要收映射
  logic rabCommitted [MAX_LMUL];                  // 异步复位；RAB 已送来该 vd 的映射
  logic ratCommitted [MAX_LMUL];                  // 异步复位；RAT 已送来该 vd 的旧 preg
  logic hasReadRf    [MAX_LMUL];                  // 异步复位；该 vd 已发过读

  logic [5:0] regMaps_lreg    [MAX_LMUL];         // 无复位：每个 vd 的映射
  logic [6:0] regMaps_newPreg [MAX_LMUL];
  logic [6:0] regMaps_oldPreg [MAX_LMUL];
  logic [VLEN-1:0] mergedVd   [MERGE_N];          // 无复位：拼好的待写数据
  logic w_valid_q             [MERGE_N];          // 无复位：读 valid 打一拍 = 写 valid

  // sWaitRab_*：进入 waitRab 时锁存的异常参数与边界（无复位，excp_valid 为写使能）
  logic [2:0] sWaitRab_nf;
  logic       sWaitRab_isStride;
  logic       sWaitRab_isWhole;
  logic [2:0] sWaitRab_useNewVdUntil;             // 第一个含 vstart 的 vd（之前全用新值）
  logic [3:0] sWaitRab_needMergeUntil;            // 合并到此为止（不含）
  logic [3:0] sWaitRab_e8offset;                  // vstart 在 vd 内的字节偏移
  logic [3:0] sWaitRab_handleUntil;               // 需要写回的 vd 总数（不含）
  logic       sWaitRab_nonSegIndexed;
  logic [3:0] sWaitRab_vemul_i_d;                 // [n]：index EMUL = data EMUL << n
  logic [1:0] sWaitRab_dvemulNoLessThanM1;
  logic [3:0] sWaitRab_rabWriteOffset;            // 无复位：RAB 已收映射条数（0 = 第一批）
  logic [3:0] sWaitRab_ratWriteOffset;            // 无复位：RAT 已收条数

  // ===========================================================================
  // §1 noExcp：当拍把异常描述翻译成边界
  // ===========================================================================
  logic [2:0] vemul, dvemul;
  logic [1:0] dvemulM1, ivemulM1;
  logic [3:0] deewOH;
  logic [2:0] nfEff;                              // whole-register 指令不分字段
  logic [3:0] e8offsetRaw;
  logic [7:0] rangeFrom  [MAX_LMUL];
  logic [7:0] rangeUntil [MAX_LMUL];
  logic       inRange    [MAX_LMUL];
  logic [2:0] useNewVdUntil;
  logic [3:0] needMergeUntil;
  logic [6:0] maxVdIdx;
  logic [3:0] vemul_i_d;

  assign vemul    = 3'(excp.vlmul + {1'b0, excp.veew} - {1'b0, excp.vsew}); // 索引的 EMUL
  assign dvemul   = excp.isIndexed ? excp.vlmul : vemul;                    // 数据的 EMUL
  assign dvemulM1 = no_less_than_m1(dvemul);
  assign ivemulM1 = no_less_than_m1(vemul);
  assign deewOH   = 4'b1 << (excp.isIndexed ? excp.vsew : excp.veew);       // 数据元素宽 one-hot
  assign nfEff    = excp.isWhole ? 3'd0 : excp.nf;

  GetE8OffsetInVreg GetE8OffsetInVreg (
    .in_eewOH   (deewOH),
    .in_idx     (excp.vstart),
    .out_offset (e8offsetRaw)
  );

  NfMappedElemIdx NfMappedElemIdx (
    .in_nf                   (nfEff),
    .in_eewOH                (deewOH),
    .out_idxRangeVec_0_from  (rangeFrom[0]),
    .out_idxRangeVec_0_until (rangeUntil[0]),
    .out_idxRangeVec_1_from  (rangeFrom[1]),
    .out_idxRangeVec_1_until (rangeUntil[1]),
    .out_idxRangeVec_2_from  (rangeFrom[2]),
    .out_idxRangeVec_2_until (rangeUntil[2]),
    .out_idxRangeVec_3_from  (rangeFrom[3]),
    .out_idxRangeVec_3_until (rangeUntil[3]),
    .out_idxRangeVec_4_from  (rangeFrom[4]),
    .out_idxRangeVec_4_until (rangeUntil[4]),
    .out_idxRangeVec_5_from  (rangeFrom[5]),
    .out_idxRangeVec_5_until (rangeUntil[5]),
    .out_idxRangeVec_6_from  (rangeFrom[6]),
    .out_idxRangeVec_6_until (rangeUntil[6]),
    .out_idxRangeVec_7_from  (rangeFrom[7]),
    .out_idxRangeVec_7_until (rangeUntil[7])
  );

  // vd k 的元素区间是否含 vstart；vlm（掩码 load）只有 1 个 vd，恒视为 vd0
  always_comb begin
    for (int k = 0; k < MAX_LMUL; k++) begin
      inRange[k] = ({1'b0, excp.vstart} >= rangeFrom[k]) && ({1'b0, excp.vstart} < rangeUntil[k]);
      inRange[k] = (k == 0) ? (excp.isVlm || inRange[k]) : (!excp.isVlm && inRange[k]);
    end
  end

  // PriorityEncoder：第一个命中的 vd；一个都没命中时为 7
  always_comb begin
    useNewVdUntil = 3'd7;
    for (int k = MAX_LMUL - 1; k >= 0; k--)
      if (inRange[k]) useNewVdUntil = 3'(k);
  end

  assign needMergeUntil = {1'b0, 3'(useNewVdUntil + nfEff)} + 4'd1;

  // 需要写回的 vd 个数：vlm 1 个；whole 为 nf+1；其余 (nf+1) * EMUL
  always_comb begin
    if (!excp_valid)        maxVdIdx = 7'd0;
    else if (excp.isVlm)    maxVdIdx = 7'd1;
    else if (excp.isWhole)  maxVdIdx = 7'({1'b0, excp.nf} + 4'd1);
    else                    maxVdIdx = 7'({1'b0, excp.nf} + 4'd1) << dvemulM1;
  end

  // index EMUL 与 data EMUL 的倍数关系（n=0 还包括 index 更小的情况）
  always_comb begin
    for (int n = 0; n < 4; n++)
      vemul_i_d[n] = ({1'b0, ivemulM1} == 3'({1'b0, dvemulM1} + 3'(n)));
    vemul_i_d[0] = vemul_i_d[0] || (ivemulM1 < dvemulM1);
  end

  always_ff @(posedge clock) begin
    if (excp_valid) begin
      sWaitRab_nf                 <= excp.nf;
      sWaitRab_isStride           <= excp.isStride;
      sWaitRab_isWhole            <= excp.isWhole;
      sWaitRab_useNewVdUntil      <= useNewVdUntil;
      sWaitRab_needMergeUntil     <= needMergeUntil;
      sWaitRab_e8offset           <= (|deewOH) ? e8offsetRaw : 4'd0;
      sWaitRab_handleUntil        <= maxVdIdx[3:0];
      sWaitRab_nonSegIndexed      <= excp.isIndexed && (excp.nf == 3'd0);
      sWaitRab_vemul_i_d          <= vemul_i_d;
      sWaitRab_dvemulNoLessThanM1 <= dvemulM1;
    end
  end

  // ===========================================================================
  // §2 waitRab：收 RAB/RAT 映射
  // ===========================================================================
  logic       oldPregValid [RAB_N];
  logic [6:0] oldPreg      [RAB_N];
  always_comb begin
    for (int p = 0; p < RAB_N; p++) begin
      oldPregValid[p] = rat_vec_valid[p] || rat_v0_valid[p];
      oldPreg[p]      = (rat_vec_valid[p] ? rat_vec_pdest[p] : 7'd0)
                      | (rat_v0_valid[p]  ? rat_v0_pdest[p]  : 7'd0);
    end
  end

  // 本拍送来的条数 = 最高有效口号 + 1（PriorityMux 从 5 口往下找）
  function automatic logic [2:0] batch_count(input logic v [RAB_N]);
    batch_count = 3'd1;
    for (int p = 1; p < RAB_N; p++)
      if (v[p]) batch_count = 3'(p + 1);
  endfunction

  // 第 p 口在本批对应哪个 vd：第一批跳过 skip 条（1，strided 为 2），第二批续在 6-skip 之后
  function automatic int port_to_vd(input int p, input logic first_batch, input logic is_stride);
    int skip;
    skip = is_stride ? 2 : 1;
    return first_batch ? (p - skip) : (p - skip + RAB_N);
  endfunction

  // nonSegIndexed 时每个 vd 实际看哪一位记账位（越界退回第 0 项）
  logic filteredRabCommitted [MAX_LMUL];
  logic filteredRatCommitted [MAX_LMUL];
  logic collectedAllRegMap;
  always_comb begin
    for (int vd = 0; vd < MAX_LMUL; vd++) begin
      if (sWaitRab_nonSegIndexed) begin
        filteredRabCommitted[vd] = 1'b0;
        filteredRatCommitted[vd] = 1'b0;
        for (int n = 0; n < 4; n++) begin
          int rabLoc, ratLoc;
          rabLoc = ((vd + 1) << n) - 1;
          ratLoc = vd << n;
          filteredRabCommitted[vd] |= sWaitRab_vemul_i_d[n] && rabCommitted[rabLoc >= MAX_LMUL ? 0 : rabLoc];
          filteredRatCommitted[vd] |= sWaitRab_vemul_i_d[n] && ratCommitted[ratLoc >= MAX_LMUL ? 0 : ratLoc];
        end
      end else begin
        filteredRabCommitted[vd] = rabCommitted[vd];
        filteredRatCommitted[vd] = ratCommitted[vd];
      end
    end
    collectedAllRegMap = 1'b1;
    for (int vd = 0; vd < MAX_LMUL; vd++)
      collectedAllRegMap &= !commitNeeded[vd] || (filteredRabCommitted[vd] && filteredRatCommitted[vd]);
  end

  // ===========================================================================
  // §3 状态转移与 currentIdx
  // ===========================================================================
  logic [3:0] currentIdxVec [MERGE_N];            // currentIdx + 0..3（4 位回绕）
  logic       mergeFinished, mvFinished;
  logic [2:0] wValidCount;
  state_e     stateNext;

  always_comb begin
    for (int j = 0; j < MERGE_N; j++) currentIdxVec[j] = currentIdx + 4'(j);
  end
  assign mergeFinished = currentIdx >= sWaitRab_needMergeUntil;
  assign mvFinished    = currentIdx >= sWaitRab_handleUntil;
  always_comb begin
    wValidCount = 3'd0;
    for (int j = 0; j < MERGE_N; j++) wValidCount += 3'(w_valid_q[j]);
  end

  always_comb begin
    stateNext = state;
    case (state)
      S_NO_EXCP:  if (excp_valid)         stateNext = S_WAIT_RAB;
      S_WAIT_RAB: if (collectedAllRegMap) stateNext = S_MERGE_VD;
      S_MERGE_VD: if (mvFinished)         stateNext = S_FINISH;
                  else if (mergeFinished) stateNext = S_MV_OLDVD;
      S_MV_OLDVD: if (mvFinished)         stateNext = S_FINISH;
      S_FINISH:                           stateNext = S_NO_EXCP;
      default: ;
    endcase
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      state      <= S_NO_EXCP;
      currentIdx <= 4'd0;
    end else begin
      state <= stateNext;
      case (state)
        S_WAIT_RAB: if (collectedAllRegMap) currentIdx <= {1'b0, sWaitRab_useNewVdUntil};
        S_MERGE_VD,
        S_MV_OLDVD: if (w_valid_q[0])       currentIdx <= currentIdx + {1'b0, wValidCount};
        S_FINISH:                           currentIdx <= 4'd0;
        default: ;
      endcase
    end
  end

  // ===========================================================================
  // §4 记账位（commitNeeded / rabCommitted / ratCommitted / hasReadRf）
  // ===========================================================================
  logic firstRabBatch, firstRatBatch;
  assign firstRabBatch = sWaitRab_rabWriteOffset == 4'd0;
  assign firstRatBatch = sWaitRab_ratWriteOffset == 4'd0;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int vd = 0; vd < MAX_LMUL; vd++) begin
        commitNeeded[vd] <= 1'b0;
        rabCommitted[vd] <= 1'b0;
        ratCommitted[vd] <= 1'b0;
        hasReadRf[vd]    <= 1'b0;
      end
    end else begin
      case (state)
        S_NO_EXCP:
          if (stateNext == S_WAIT_RAB)
            for (int vd = 0; vd < MAX_LMUL; vd++) commitNeeded[vd] <= maxVdIdx > 7'(vd);
        S_WAIT_RAB:
          for (int p = 0; p < RAB_N; p++) begin
            int vdRab, vdRat;
            vdRab = port_to_vd(p, firstRabBatch, sWaitRab_isStride);
            vdRat = port_to_vd(p, firstRatBatch, sWaitRab_isStride);
            if (vdRab >= 0 && vdRab < MAX_LMUL && rab_valid[p])    rabCommitted[vdRab] <= 1'b1;
            if (vdRat >= 0 && vdRat < MAX_LMUL && oldPregValid[p]) ratCommitted[vdRat] <= 1'b1;
          end
        S_MERGE_VD:
          for (int j = 0; j < MERGE_N; j++)
            hasReadRf[currentIdxVec[j][2:0]] <= currentIdxVec[j] < sWaitRab_needMergeUntil;
        S_MV_OLDVD:
          for (int j = 0; j < MERGE_N; j++)
            hasReadRf[currentIdxVec[j][2:0]] <= currentIdxVec[j] < sWaitRab_handleUntil;
        S_FINISH:
          for (int vd = 0; vd < MAX_LMUL; vd++) begin
            commitNeeded[vd] <= 1'b0;
            rabCommitted[vd] <= 1'b0;
            ratCommitted[vd] <= 1'b0;
            hasReadRf[vd]    <= 1'b0;
          end
        default: ;
      endcase
    end
  end

  // 映射表与批计数（无复位）
  always_ff @(posedge clock) begin
    case (state)
      S_NO_EXCP:
        if (stateNext == S_WAIT_RAB) begin
          sWaitRab_rabWriteOffset <= 4'd0;
          sWaitRab_ratWriteOffset <= 4'd0;
        end
      S_WAIT_RAB: begin
        if (rab_valid[0])    sWaitRab_rabWriteOffset <= sWaitRab_rabWriteOffset + {1'b0, batch_count(rab_valid)};
        if (oldPregValid[0]) sWaitRab_ratWriteOffset <= sWaitRab_ratWriteOffset + {1'b0, batch_count(oldPregValid)};
        for (int p = 0; p < RAB_N; p++) begin
          int vdRab, vdRat;
          vdRab = port_to_vd(p, firstRabBatch, sWaitRab_isStride);
          vdRat = port_to_vd(p, firstRatBatch, sWaitRab_isStride);
          if (vdRab >= 0 && vdRab < MAX_LMUL && rab_valid[p]) begin
            regMaps_lreg[vdRab]    <= rab_lreg[p];
            regMaps_newPreg[vdRab] <= rab_preg[p];
          end
          if (vdRat >= 0 && vdRat < MAX_LMUL && oldPregValid[p])
            regMaps_oldPreg[vdRat] <= oldPreg[p];
        end
      end
      S_FINISH: begin
        sWaitRab_rabWriteOffset <= 4'd0;
        sWaitRab_ratWriteOffset <= 4'd0;
      end
      default: ;
    endcase
  end

  // ===========================================================================
  // §5 读口：mergeVd 读旧+新，mvOldVd 只读旧
  // ===========================================================================
  // vd 在寄存器组里的位置：nonSegIndexed 按 EMUL 倍数展开（旧取组首、新取组尾），
  // whole 直通，其余查分段重排表。
  logic [2:0] oldVdLoc [MERGE_N];
  logic [2:0] newVdLoc [MERGE_N];
  always_comb begin
    for (int j = 0; j < MERGE_N; j++) begin
      logic [3:0] idx;
      idx = currentIdxVec[j];
      if (sWaitRab_nonSegIndexed) begin
        oldVdLoc[j] = 3'd0;
        newVdLoc[j] = 3'd0;
        for (int n = 0; n < 4; n++) begin
          if (sWaitRab_vemul_i_d[n]) begin
            oldVdLoc[j] |= 3'(idx << n);
            newVdLoc[j] |= 3'((idx << n) | ((1 << n) - 1));
          end
        end
      end else if (sWaitRab_isWhole) begin
        oldVdLoc[j] = idx[2:0];
        newVdLoc[j] = idx[2:0];
      end else begin
        oldVdLoc[j] = seg_shuffle(sWaitRab_nf, sWaitRab_dvemulNoLessThanM1, idx[2:0]);
        newVdLoc[j] = oldVdLoc[j];
      end
    end
  end

  always_comb begin
    for (int j = 0; j < 2 * MERGE_N; j++) begin
      r_valid[j] = 1'b0;
      r_isV0[j]  = 1'b0;
      r_addr[j]  = 7'd0;
    end
    for (int j = 0; j < MERGE_N; j++) begin
      logic [3:0] vdIdx;
      logic       want;
      vdIdx = currentIdxVec[j];
      want  = commitNeeded[vdIdx[2:0]] && !hasReadRf[vdIdx[2:0]];
      if (state == S_MERGE_VD) begin
        r_valid[j]           = want && (vdIdx < sWaitRab_needMergeUntil);
        r_addr[j]            = regMaps_oldPreg[oldVdLoc[j]];
        r_isV0[j]            = (j == 0) && (regMaps_lreg[oldVdLoc[j]] == 6'd0);
        r_valid[j + MERGE_N] = r_valid[j];
        r_addr[j + MERGE_N]  = regMaps_newPreg[newVdLoc[j]];
        r_isV0[j + MERGE_N]  = (j == 0) && (regMaps_lreg[newVdLoc[j]] == 6'd0);
      end else if (state == S_MV_OLDVD) begin
        r_valid[j]           = want && (vdIdx < sWaitRab_handleUntil);
        r_addr[j]            = regMaps_oldPreg[oldVdLoc[j]];
        r_isV0[j]            = (j == 0) && (regMaps_lreg[oldVdLoc[j]] == 6'd0);
      end
    end
  end

  // ===========================================================================
  // §6 拼数据（读回当拍写进 mergedVd）与写口
  // ===========================================================================
  always_ff @(posedge clock) begin
    for (int j = 0; j < MERGE_N; j++) begin
      w_valid_q[j] <= vprf_valid[j];
      if ((state == S_MERGE_VD || state == S_MV_OLDVD) && vprf_valid[j]) begin
        for (int e = 0; e < VLENB; e++) begin
          // mergeVd：vstart 所在字节及之后取旧值，之前取新值；mvOldVd：整条旧值
          if (state == S_MERGE_VD && !(4'(e) >= sWaitRab_e8offset))
            mergedVd[j][8*e +: 8] <= vprf_data[j + MERGE_N][8*e +: 8];
          else
            mergedVd[j][8*e +: 8] <= vprf_data[j][8*e +: 8];
        end
      end
    end
  end

  always_comb begin
    for (int j = 0; j < MERGE_N; j++) begin
      w_valid[j] = w_valid_q[j];
      w_isV0[j]  = (j == 0) && (regMaps_lreg[newVdLoc[j]] == 6'd0);
      w_addr[j]  = regMaps_newPreg[newVdLoc[j]];
      w_data[j]  = mergedVd[j];
    end
  end

  // busy：waitRab/mergeVd/mvOldVd 期间，延一拍送出
  DelayN_13 o_status_busy_delay (
    .clock  (clock),
    .io_in  (state == S_WAIT_RAB || state == S_MERGE_VD || state == S_MV_OLDVD),
    .io_out (busy)
  );
endmodule

module VecExcpDataMergeModule
  import vecexcpmerge_pkg::*;
(
  input  logic         clock,
  input  logic         reset,
  input  logic         i_fromExceptionGen_valid,
  input  logic [6:0]   i_fromExceptionGen_bits_vstart,
  input  logic [1:0]   i_fromExceptionGen_bits_vsew,
  input  logic [1:0]   i_fromExceptionGen_bits_veew,
  input  logic [2:0]   i_fromExceptionGen_bits_vlmul,
  input  logic [2:0]   i_fromExceptionGen_bits_nf,
  input  logic         i_fromExceptionGen_bits_isStride,
  input  logic         i_fromExceptionGen_bits_isIndexed,
  input  logic         i_fromExceptionGen_bits_isWhole,
  input  logic         i_fromExceptionGen_bits_isVlm,
  input  logic         i_fromRab_logicPhyRegMap_0_valid,
  input  logic [5:0]   i_fromRab_logicPhyRegMap_0_bits_lreg,
  input  logic [6:0]   i_fromRab_logicPhyRegMap_0_bits_preg,
  input  logic         i_fromRab_logicPhyRegMap_1_valid,
  input  logic [5:0]   i_fromRab_logicPhyRegMap_1_bits_lreg,
  input  logic [6:0]   i_fromRab_logicPhyRegMap_1_bits_preg,
  input  logic         i_fromRab_logicPhyRegMap_2_valid,
  input  logic [5:0]   i_fromRab_logicPhyRegMap_2_bits_lreg,
  input  logic [6:0]   i_fromRab_logicPhyRegMap_2_bits_preg,
  input  logic         i_fromRab_logicPhyRegMap_3_valid,
  input  logic [5:0]   i_fromRab_logicPhyRegMap_3_bits_lreg,
  input  logic [6:0]   i_fromRab_logicPhyRegMap_3_bits_preg,
  input  logic         i_fromRab_logicPhyRegMap_4_valid,
  input  logic [5:0]   i_fromRab_logicPhyRegMap_4_bits_lreg,
  input  logic [6:0]   i_fromRab_logicPhyRegMap_4_bits_preg,
  input  logic         i_fromRab_logicPhyRegMap_5_valid,
  input  logic [5:0]   i_fromRab_logicPhyRegMap_5_bits_lreg,
  input  logic [6:0]   i_fromRab_logicPhyRegMap_5_bits_preg,
  input  logic         i_fromRat_vecOldVdPdest_0_valid,
  input  logic [6:0]   i_fromRat_vecOldVdPdest_0_bits,
  input  logic         i_fromRat_vecOldVdPdest_1_valid,
  input  logic [6:0]   i_fromRat_vecOldVdPdest_1_bits,
  input  logic         i_fromRat_vecOldVdPdest_2_valid,
  input  logic [6:0]   i_fromRat_vecOldVdPdest_2_bits,
  input  logic         i_fromRat_vecOldVdPdest_3_valid,
  input  logic [6:0]   i_fromRat_vecOldVdPdest_3_bits,
  input  logic         i_fromRat_vecOldVdPdest_4_valid,
  input  logic [6:0]   i_fromRat_vecOldVdPdest_4_bits,
  input  logic         i_fromRat_vecOldVdPdest_5_valid,
  input  logic [6:0]   i_fromRat_vecOldVdPdest_5_bits,
  input  logic         i_fromRat_v0OldVdPdest_0_valid,
  input  logic [6:0]   i_fromRat_v0OldVdPdest_0_bits,
  input  logic         i_fromRat_v0OldVdPdest_1_valid,
  input  logic [6:0]   i_fromRat_v0OldVdPdest_1_bits,
  input  logic         i_fromRat_v0OldVdPdest_2_valid,
  input  logic [6:0]   i_fromRat_v0OldVdPdest_2_bits,
  input  logic         i_fromRat_v0OldVdPdest_3_valid,
  input  logic [6:0]   i_fromRat_v0OldVdPdest_3_bits,
  input  logic         i_fromRat_v0OldVdPdest_4_valid,
  input  logic [6:0]   i_fromRat_v0OldVdPdest_4_bits,
  input  logic         i_fromRat_v0OldVdPdest_5_valid,
  input  logic [6:0]   i_fromRat_v0OldVdPdest_5_bits,
  input  logic         i_fromVprf_rdata_0_valid,
  input  logic [127:0] i_fromVprf_rdata_0_bits,
  input  logic         i_fromVprf_rdata_1_valid,
  input  logic [127:0] i_fromVprf_rdata_1_bits,
  input  logic         i_fromVprf_rdata_2_valid,
  input  logic [127:0] i_fromVprf_rdata_2_bits,
  input  logic         i_fromVprf_rdata_3_valid,
  input  logic [127:0] i_fromVprf_rdata_3_bits,
  input  logic [127:0] i_fromVprf_rdata_4_bits,
  input  logic [127:0] i_fromVprf_rdata_5_bits,
  input  logic [127:0] i_fromVprf_rdata_6_bits,
  input  logic [127:0] i_fromVprf_rdata_7_bits,
  output logic         o_toVPRF_r_0_valid,
  output logic         o_toVPRF_r_0_bits_isV0,
  output logic [6:0]   o_toVPRF_r_0_bits_addr,
  output logic         o_toVPRF_r_1_valid,
  output logic [6:0]   o_toVPRF_r_1_bits_addr,
  output logic         o_toVPRF_r_2_valid,
  output logic [6:0]   o_toVPRF_r_2_bits_addr,
  output logic         o_toVPRF_r_3_valid,
  output logic [6:0]   o_toVPRF_r_3_bits_addr,
  output logic         o_toVPRF_r_4_valid,
  output logic         o_toVPRF_r_4_bits_isV0,
  output logic [6:0]   o_toVPRF_r_4_bits_addr,
  output logic         o_toVPRF_r_5_valid,
  output logic [6:0]   o_toVPRF_r_5_bits_addr,
  output logic         o_toVPRF_r_6_valid,
  output logic [6:0]   o_toVPRF_r_6_bits_addr,
  output logic         o_toVPRF_r_7_valid,
  output logic [6:0]   o_toVPRF_r_7_bits_addr,
  output logic         o_toVPRF_w_0_valid,
  output logic         o_toVPRF_w_0_bits_isV0,
  output logic [6:0]   o_toVPRF_w_0_bits_newVdAddr,
  output logic [127:0] o_toVPRF_w_0_bits_newVdData,
  output logic         o_toVPRF_w_1_valid,
  output logic [6:0]   o_toVPRF_w_1_bits_newVdAddr,
  output logic [127:0] o_toVPRF_w_1_bits_newVdData,
  output logic         o_toVPRF_w_2_valid,
  output logic [6:0]   o_toVPRF_w_2_bits_newVdAddr,
  output logic [127:0] o_toVPRF_w_2_bits_newVdData,
  output logic         o_toVPRF_w_3_valid,
  output logic [6:0]   o_toVPRF_w_3_bits_newVdAddr,
  output logic [127:0] o_toVPRF_w_3_bits_newVdData,
  output logic         o_status_busy
);
  excp_info_t excp;
  logic       rab_valid     [RAB_N];
  logic [5:0] rab_lreg      [RAB_N];
  logic [6:0] rab_preg      [RAB_N];
  logic       rat_vec_valid [RAB_N];
  logic [6:0] rat_vec_pdest [RAB_N];
  logic       rat_v0_valid  [RAB_N];
  logic [6:0] rat_v0_pdest  [RAB_N];
  logic       vprf_valid    [MERGE_N];
  logic [127:0] vprf_data   [2*MERGE_N];
  logic       r_valid [2*MERGE_N];
  logic       r_isV0  [2*MERGE_N];
  logic [6:0] r_addr  [2*MERGE_N];
  logic       w_valid [MERGE_N];
  logic       w_isV0  [MERGE_N];
  logic [6:0] w_addr  [MERGE_N];
  logic [127:0] w_data [MERGE_N];

  assign excp = '{
    vstart:    i_fromExceptionGen_bits_vstart,
    vsew:      i_fromExceptionGen_bits_vsew,
    veew:      i_fromExceptionGen_bits_veew,
    vlmul:     i_fromExceptionGen_bits_vlmul,
    nf:        i_fromExceptionGen_bits_nf,
    isStride:  i_fromExceptionGen_bits_isStride,
    isIndexed: i_fromExceptionGen_bits_isIndexed,
    isWhole:   i_fromExceptionGen_bits_isWhole,
    isVlm:     i_fromExceptionGen_bits_isVlm
  };

  assign rab_valid = '{i_fromRab_logicPhyRegMap_0_valid, i_fromRab_logicPhyRegMap_1_valid,
                       i_fromRab_logicPhyRegMap_2_valid, i_fromRab_logicPhyRegMap_3_valid,
                       i_fromRab_logicPhyRegMap_4_valid, i_fromRab_logicPhyRegMap_5_valid};
  assign rab_lreg  = '{i_fromRab_logicPhyRegMap_0_bits_lreg, i_fromRab_logicPhyRegMap_1_bits_lreg,
                       i_fromRab_logicPhyRegMap_2_bits_lreg, i_fromRab_logicPhyRegMap_3_bits_lreg,
                       i_fromRab_logicPhyRegMap_4_bits_lreg, i_fromRab_logicPhyRegMap_5_bits_lreg};
  assign rab_preg  = '{i_fromRab_logicPhyRegMap_0_bits_preg, i_fromRab_logicPhyRegMap_1_bits_preg,
                       i_fromRab_logicPhyRegMap_2_bits_preg, i_fromRab_logicPhyRegMap_3_bits_preg,
                       i_fromRab_logicPhyRegMap_4_bits_preg, i_fromRab_logicPhyRegMap_5_bits_preg};
  assign rat_vec_valid = '{i_fromRat_vecOldVdPdest_0_valid, i_fromRat_vecOldVdPdest_1_valid,
                           i_fromRat_vecOldVdPdest_2_valid, i_fromRat_vecOldVdPdest_3_valid,
                           i_fromRat_vecOldVdPdest_4_valid, i_fromRat_vecOldVdPdest_5_valid};
  assign rat_vec_pdest = '{i_fromRat_vecOldVdPdest_0_bits, i_fromRat_vecOldVdPdest_1_bits,
                           i_fromRat_vecOldVdPdest_2_bits, i_fromRat_vecOldVdPdest_3_bits,
                           i_fromRat_vecOldVdPdest_4_bits, i_fromRat_vecOldVdPdest_5_bits};
  assign rat_v0_valid  = '{i_fromRat_v0OldVdPdest_0_valid, i_fromRat_v0OldVdPdest_1_valid,
                           i_fromRat_v0OldVdPdest_2_valid, i_fromRat_v0OldVdPdest_3_valid,
                           i_fromRat_v0OldVdPdest_4_valid, i_fromRat_v0OldVdPdest_5_valid};
  assign rat_v0_pdest  = '{i_fromRat_v0OldVdPdest_0_bits, i_fromRat_v0OldVdPdest_1_bits,
                           i_fromRat_v0OldVdPdest_2_bits, i_fromRat_v0OldVdPdest_3_bits,
                           i_fromRat_v0OldVdPdest_4_bits, i_fromRat_v0OldVdPdest_5_bits};
  assign vprf_valid = '{i_fromVprf_rdata_0_valid, i_fromVprf_rdata_1_valid,
                        i_fromVprf_rdata_2_valid, i_fromVprf_rdata_3_valid};
  assign vprf_data  = '{i_fromVprf_rdata_0_bits, i_fromVprf_rdata_1_bits,
                        i_fromVprf_rdata_2_bits, i_fromVprf_rdata_3_bits,
                        i_fromVprf_rdata_4_bits, i_fromVprf_rdata_5_bits,
                        i_fromVprf_rdata_6_bits, i_fromVprf_rdata_7_bits};

  xs_VecExcpDataMergeModule_core u_core (
    .clock         (clock),
    .reset         (reset),
    .excp_valid    (i_fromExceptionGen_valid),
    .excp          (excp),
    .rab_valid     (rab_valid),
    .rab_lreg      (rab_lreg),
    .rab_preg      (rab_preg),
    .rat_vec_valid (rat_vec_valid),
    .rat_vec_pdest (rat_vec_pdest),
    .rat_v0_valid  (rat_v0_valid),
    .rat_v0_pdest  (rat_v0_pdest),
    .vprf_valid    (vprf_valid),
    .vprf_data     (vprf_data),
    .r_valid       (r_valid),
    .r_isV0        (r_isV0),
    .r_addr        (r_addr),
    .w_valid       (w_valid),
    .w_isV0        (w_isV0),
    .w_addr        (w_addr),
    .w_data        (w_data),
    .busy          (o_status_busy)
  );

  assign o_toVPRF_r_0_valid          = r_valid[0];
  assign o_toVPRF_r_0_bits_isV0      = r_isV0[0];
  assign o_toVPRF_r_0_bits_addr      = r_addr[0];
  assign o_toVPRF_r_1_valid          = r_valid[1];
  assign o_toVPRF_r_1_bits_addr      = r_addr[1];
  assign o_toVPRF_r_2_valid          = r_valid[2];
  assign o_toVPRF_r_2_bits_addr      = r_addr[2];
  assign o_toVPRF_r_3_valid          = r_valid[3];
  assign o_toVPRF_r_3_bits_addr      = r_addr[3];
  assign o_toVPRF_r_4_valid          = r_valid[4];
  assign o_toVPRF_r_4_bits_isV0      = r_isV0[4];
  assign o_toVPRF_r_4_bits_addr      = r_addr[4];
  assign o_toVPRF_r_5_valid          = r_valid[5];
  assign o_toVPRF_r_5_bits_addr      = r_addr[5];
  assign o_toVPRF_r_6_valid          = r_valid[6];
  assign o_toVPRF_r_6_bits_addr      = r_addr[6];
  assign o_toVPRF_r_7_valid          = r_valid[7];
  assign o_toVPRF_r_7_bits_addr      = r_addr[7];
  assign o_toVPRF_w_0_valid          = w_valid[0];
  assign o_toVPRF_w_0_bits_isV0      = w_isV0[0];
  assign o_toVPRF_w_0_bits_newVdAddr = w_addr[0];
  assign o_toVPRF_w_0_bits_newVdData = w_data[0];
  assign o_toVPRF_w_1_valid          = w_valid[1];
  assign o_toVPRF_w_1_bits_newVdAddr = w_addr[1];
  assign o_toVPRF_w_1_bits_newVdData = w_data[1];
  assign o_toVPRF_w_2_valid          = w_valid[2];
  assign o_toVPRF_w_2_bits_newVdAddr = w_addr[2];
  assign o_toVPRF_w_2_bits_newVdData = w_data[2];
  assign o_toVPRF_w_3_valid          = w_valid[3];
  assign o_toVPRF_w_3_bits_newVdAddr = w_addr[3];
  assign o_toVPRF_w_3_bits_newVdData = w_data[3];
endmodule
