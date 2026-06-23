// =============================================================================
// xs_IssueQueueStaMou_core —— 香山 V2R2 发射队列 StaMou(访存地址)变体 可读核
// -----------------------------------------------------------------------------
// 设计源: src/main/scala/xiangshan/backend/issue/IssueQueue.scala
//         (class IssueQueueImp + class IssueQueueMemAddrImp:1094)
//
// 本核与整数样板 xs_IssueQueueAluCsrFenceDiv_core 同构(把条目阵列 EntriesStaMou 包起来,
// 做 enq 分配 / canIssue 合并 / 年龄仲裁 / deq 发射 / deqDelay 寄存 / 统计), 差异全在
// 「访存特征」(详见 iq_stamou_pkg 顶部说明), 逐项标注:
//
//   [A] mem feedback(关键): 把执行端慢响应 memIO.feedbackIO_0.feedbackSlow 折算成
//       条目阵列认识的 fromMem.slowResp(valid/resp/sqIdx), resp = hit ? success : block。
//       条目阵列据此把对应 sqIdx 的 issued 条目打回未发射(阻塞)或确认成功。
//   [B] 单源 / 单发射端口: numRegSrc=1, numDeq=1。dataSources/exuSources/loadDependency
//       的 Mux1H 只对「源 0」「端口 0」做。
//   [C] sqIdx 透传: enq 带入 sqIdx → 条目 payload; deqEntry 读出 sqIdx → deqDelay 输出。
//   [D] isFirstIssue 输出: 取条目阵列 io_isFirstIssue_0(条目 firstIssue 状态)。
//   [E] 无 FuBusyTable: canIssue 直接进仲裁(访存地址 IQ 不过功能单元忙表)。
//   [F] 无 wakeupToIQ / MultiWakeupQueue: STA 不产生寄存器写回唤醒。
//   [G] 端口承担功能单元: deqCanAccept = fuType[STA] | fuType[MOU]。
//
// 子模块(均为 golden 黑盒, 端口已扁平): EntriesStaMou(16 条目阵列)、NewAgeDetector_6
// (入队 2 条目)、AgeDetector_12(simp 2 条目, 3 路: deq/trans0/trans1)、AgeDetector_21
// (comp 12 条目)。本核负责把它们连起来并实现上述访存胶合逻辑。
// =============================================================================
module xs_IssueQueueStaMou_core import iq_stamou_pkg::*; (
  input         clock,
  input         reset,
  input         io_flush_valid,
  input         io_flush_bits_robIdx_flag,
  input  [7:0]  io_flush_bits_robIdx_value,
  input         io_flush_bits_level,
  output        io_enq_0_ready,
  input         io_enq_0_valid,
  input  [5:0]  io_enq_0_bits_ftqPtr_value,
  input  [3:0]  io_enq_0_bits_ftqOffset,
  input  [3:0]  io_enq_0_bits_srcType_0,
  input  [34:0] io_enq_0_bits_fuType,
  input  [8:0]  io_enq_0_bits_fuOpType,
  input         io_enq_0_bits_rfWen,
  input  [3:0]  io_enq_0_bits_selImm,
  input  [31:0] io_enq_0_bits_imm,
  input         io_enq_0_bits_srcState_0,
  input  [1:0]  io_enq_0_bits_srcLoadDependency_0_0,
  input  [1:0]  io_enq_0_bits_srcLoadDependency_0_1,
  input  [1:0]  io_enq_0_bits_srcLoadDependency_0_2,
  input  [7:0]  io_enq_0_bits_psrc_0,
  input  [7:0]  io_enq_0_bits_pdest,
  input         io_enq_0_bits_useRegCache_0,
  input  [4:0]  io_enq_0_bits_regCacheIdx_0,
  input         io_enq_0_bits_robIdx_flag,
  input  [7:0]  io_enq_0_bits_robIdx_value,
  input         io_enq_0_bits_sqIdx_flag,
  input  [5:0]  io_enq_0_bits_sqIdx_value,
  output        io_enq_1_ready,
  input         io_enq_1_valid,
  input  [5:0]  io_enq_1_bits_ftqPtr_value,
  input  [3:0]  io_enq_1_bits_ftqOffset,
  input  [3:0]  io_enq_1_bits_srcType_0,
  input  [34:0] io_enq_1_bits_fuType,
  input  [8:0]  io_enq_1_bits_fuOpType,
  input         io_enq_1_bits_rfWen,
  input  [3:0]  io_enq_1_bits_selImm,
  input  [31:0] io_enq_1_bits_imm,
  input         io_enq_1_bits_srcState_0,
  input  [1:0]  io_enq_1_bits_srcLoadDependency_0_0,
  input  [1:0]  io_enq_1_bits_srcLoadDependency_0_1,
  input  [1:0]  io_enq_1_bits_srcLoadDependency_0_2,
  input  [7:0]  io_enq_1_bits_psrc_0,
  input  [7:0]  io_enq_1_bits_pdest,
  input         io_enq_1_bits_useRegCache_0,
  input  [4:0]  io_enq_1_bits_regCacheIdx_0,
  input         io_enq_1_bits_robIdx_flag,
  input  [7:0]  io_enq_1_bits_robIdx_value,
  input         io_enq_1_bits_sqIdx_flag,
  input  [5:0]  io_enq_1_bits_sqIdx_value,
  input         io_og0Resp_0_valid,
  input         io_og1Resp_0_valid,
  input  [1:0]  io_og1Resp_0_bits_resp,
  input         io_wakeupFromWB_3_valid,
  input         io_wakeupFromWB_3_bits_rfWen,
  input  [7:0]  io_wakeupFromWB_3_bits_pdest,
  input         io_wakeupFromWB_2_valid,
  input         io_wakeupFromWB_2_bits_rfWen,
  input  [7:0]  io_wakeupFromWB_2_bits_pdest,
  input         io_wakeupFromWB_1_valid,
  input         io_wakeupFromWB_1_bits_rfWen,
  input  [7:0]  io_wakeupFromWB_1_bits_pdest,
  input         io_wakeupFromWB_0_valid,
  input         io_wakeupFromWB_0_bits_rfWen,
  input  [7:0]  io_wakeupFromWB_0_bits_pdest,
  input         io_wakeupFromIQ_6_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_6_bits_pdest,
  input  [4:0]  io_wakeupFromIQ_6_bits_rcDest,
  input         io_wakeupFromIQ_5_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_5_bits_pdest,
  input  [4:0]  io_wakeupFromIQ_5_bits_rcDest,
  input         io_wakeupFromIQ_4_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_4_bits_pdest,
  input  [4:0]  io_wakeupFromIQ_4_bits_rcDest,
  input         io_wakeupFromIQ_3_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_3_bits_pdest,
  input  [1:0]  io_wakeupFromIQ_3_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQ_3_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQ_3_bits_loadDependency_2,
  input  [4:0]  io_wakeupFromIQ_3_bits_rcDest,
  input         io_wakeupFromIQ_2_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_2_bits_pdest,
  input  [1:0]  io_wakeupFromIQ_2_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQ_2_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQ_2_bits_loadDependency_2,
  input  [4:0]  io_wakeupFromIQ_2_bits_rcDest,
  input         io_wakeupFromIQ_1_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_1_bits_pdest,
  input  [1:0]  io_wakeupFromIQ_1_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQ_1_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQ_1_bits_loadDependency_2,
  input         io_wakeupFromIQ_1_bits_is0Lat,
  input  [4:0]  io_wakeupFromIQ_1_bits_rcDest,
  input         io_wakeupFromIQ_0_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_0_bits_pdest,
  input  [1:0]  io_wakeupFromIQ_0_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQ_0_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQ_0_bits_loadDependency_2,
  input         io_wakeupFromIQ_0_bits_is0Lat,
  input  [4:0]  io_wakeupFromIQ_0_bits_rcDest,
  input         io_wakeupFromWBDelayed_3_valid,
  input         io_wakeupFromWBDelayed_3_bits_rfWen,
  input  [7:0]  io_wakeupFromWBDelayed_3_bits_pdest,
  input         io_wakeupFromWBDelayed_2_valid,
  input         io_wakeupFromWBDelayed_2_bits_rfWen,
  input  [7:0]  io_wakeupFromWBDelayed_2_bits_pdest,
  input         io_wakeupFromWBDelayed_1_valid,
  input         io_wakeupFromWBDelayed_1_bits_rfWen,
  input  [7:0]  io_wakeupFromWBDelayed_1_bits_pdest,
  input         io_wakeupFromWBDelayed_0_valid,
  input         io_wakeupFromWBDelayed_0_bits_rfWen,
  input  [7:0]  io_wakeupFromWBDelayed_0_bits_pdest,
  input         io_wakeupFromIQDelayed_6_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_6_bits_pdest,
  input  [4:0]  io_wakeupFromIQDelayed_6_bits_rcDest,
  input         io_wakeupFromIQDelayed_5_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_5_bits_pdest,
  input  [4:0]  io_wakeupFromIQDelayed_5_bits_rcDest,
  input         io_wakeupFromIQDelayed_4_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_4_bits_pdest,
  input  [4:0]  io_wakeupFromIQDelayed_4_bits_rcDest,
  input         io_wakeupFromIQDelayed_3_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_3_bits_pdest,
  input  [1:0]  io_wakeupFromIQDelayed_3_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQDelayed_3_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQDelayed_3_bits_loadDependency_2,
  input  [4:0]  io_wakeupFromIQDelayed_3_bits_rcDest,
  input         io_wakeupFromIQDelayed_2_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_2_bits_pdest,
  input  [1:0]  io_wakeupFromIQDelayed_2_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQDelayed_2_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQDelayed_2_bits_loadDependency_2,
  input  [4:0]  io_wakeupFromIQDelayed_2_bits_rcDest,
  input         io_wakeupFromIQDelayed_1_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_1_bits_pdest,
  input  [1:0]  io_wakeupFromIQDelayed_1_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQDelayed_1_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQDelayed_1_bits_loadDependency_2,
  input         io_wakeupFromIQDelayed_1_bits_is0Lat,
  input  [4:0]  io_wakeupFromIQDelayed_1_bits_rcDest,
  input         io_wakeupFromIQDelayed_0_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_0_bits_pdest,
  input  [1:0]  io_wakeupFromIQDelayed_0_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQDelayed_0_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQDelayed_0_bits_loadDependency_2,
  input         io_wakeupFromIQDelayed_0_bits_is0Lat,
  input  [4:0]  io_wakeupFromIQDelayed_0_bits_rcDest,
  input         io_og0Cancel_0,
  input         io_og0Cancel_2,
  input         io_og0Cancel_4,
  input         io_og0Cancel_6,
  input         io_ldCancel_0_ld2Cancel,
  input         io_ldCancel_1_ld2Cancel,
  input         io_ldCancel_2_ld2Cancel,
  output [4:0]  io_validCntDeqVec_0,
  input         io_deqDelay_0_ready,
  output        io_deqDelay_0_valid,
  output [7:0]  io_deqDelay_0_bits_rf_0_0_addr,
  output [4:0]  io_deqDelay_0_bits_rcIdx_0,
  output [3:0]  io_deqDelay_0_bits_immType,
  output [34:0] io_deqDelay_0_bits_common_fuType,
  output [8:0]  io_deqDelay_0_bits_common_fuOpType,
  output [63:0] io_deqDelay_0_bits_common_imm,
  output        io_deqDelay_0_bits_common_robIdx_flag,
  output [7:0]  io_deqDelay_0_bits_common_robIdx_value,
  output        io_deqDelay_0_bits_common_isFirstIssue,
  output [7:0]  io_deqDelay_0_bits_common_pdest,
  output        io_deqDelay_0_bits_common_rfWen,
  output [5:0]  io_deqDelay_0_bits_common_ftqIdx_value,
  output [3:0]  io_deqDelay_0_bits_common_ftqOffset,
  output        io_deqDelay_0_bits_common_sqIdx_flag,
  output [5:0]  io_deqDelay_0_bits_common_sqIdx_value,
  output [3:0]  io_deqDelay_0_bits_common_dataSources_0_value,
  output [2:0]  io_deqDelay_0_bits_common_exuSources_0_value,
  output [1:0]  io_deqDelay_0_bits_common_loadDependency_0,
  output [1:0]  io_deqDelay_0_bits_common_loadDependency_1,
  output [1:0]  io_deqDelay_0_bits_common_loadDependency_2,
  input         io_memIO_feedbackIO_0_feedbackSlow_valid,
  input         io_memIO_feedbackIO_0_feedbackSlow_bits_hit,
  input         io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_flag,
  input  [5:0]  io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_value
);

  // ===========================================================================
  // 发射端口承载 uop 公共字段(deqEntry → deqBeforeDly → deqDelay 寄存器)。
  // 单发射端口 / 单源, 故只有一个 deq_common_t。
  // ===========================================================================
  typedef struct packed {
    logic [7:0]  rf_0_0_addr;   // 源0 物理寄存器号(rf read addr)
    logic [4:0]  rc_idx_0;      // 源0 regCache 索引
    logic [3:0]  imm_type;      // selImm
    logic [34:0] fu_type;       // 功能单元 one-hot(只保留 16/17 位)
    logic [8:0]  fu_op_type;
    logic [63:0] imm;
    logic        rob_flag;
    logic [7:0]  rob_value;
    logic        first_issue;   // 访存特有: isFirstIssue
    logic [7:0]  pdest;
    logic        rf_wen;
    logic [5:0]  ftq_value;
    logic [3:0]  ftq_offset;
    logic        sq_flag;       // 访存特有: sqIdx.flag
    logic [5:0]  sq_value;      // 访存特有: sqIdx.value
    logic [3:0]  ds0;           // dataSources 源0
    logic [2:0]  exu0;          // exuSources 源0
    logic [1:0]  ld0;           // loadDependency pipe0
    logic [1:0]  ld1;
    logic [1:0]  ld2;
  } deq_common_t;

  // ---- entries 黑盒输出线 ----
  wire [15:0] e_valid, e_issued, e_can_issue;
  wire [34:0] e_fu_type   [16];
  wire [3:0]  e_data_src  [16];      // 单源, 仅 [k][0]
  wire [2:0]  e_exu_src   [16];
  wire [1:0]  e_load_dep  [16][3];
  wire [1:0]  e_simp_enq_sel [2];
  wire [11:0] e_comp_enq_sel [2];
  wire        e_cancel_deq;
  wire        e_first_issue;
  // deqEntry 端口(单端口)
  wire        e_deq0_robflag, e_deq0_ft16, e_deq0_ft17, e_deq0_rfwen, e_deq0_sqflag;
  wire [7:0]  e_deq0_robval, e_deq0_s0psrc, e_deq0_pdest;
  wire [3:0]  e_deq0_s0type, e_deq0_selimm, e_deq0_ftqoff;
  wire [4:0]  e_deq0_s0rc;
  wire [11:0] e_deq0_imm;
  wire [8:0]  e_deq0_fuop;
  wire [5:0]  e_deq0_ftqval, e_deq0_sqval;

  // ---- 年龄检测器输出 ----
  wire [1:0]  age_enq_out;       // NewAgeDetector_6: 入队 2 条目 one-hot
  wire [1:0]  age_simp_out [3];  // AgeDetector_12: simp 2 条目, 3 路(deq/trans0/trans1)
  wire [11:0] age_comp_out;      // AgeDetector_21: comp 12 条目

  // ===========================================================================
  // 1. enq 分配: ready / s0_doEnq
  // ---------------------------------------------------------------------------
  // simpCanotIn: 2 个简单条目(idx2/3)里已占用 >=1 个 → 简单区将满, 不能再收 2 条。
  //   golden 用 valid[3:2]==2'h2 | ==2'h1 | (valid[2]&valid[3]) 表达「至少占 1」。
  // ===========================================================================
  wire [1:0] simp_valid = e_valid[3:2];
  wire simpCanotIn =
    (simp_valid == 2'h2) | (simp_valid == 2'h1) | (e_valid[2] & e_valid[3]);
  wire enqHasValid  = e_valid[0] | e_valid[1];
  wire enqHasIssued = (e_valid[0] & e_issued[0]) | (e_valid[1] & e_issued[1]);
  wire enq_ready = (~simpCanotIn | ~enqHasValid) & ~enqHasIssued;
  assign io_enq_0_ready = enq_ready;
  assign io_enq_1_ready = enq_ready;

  wire s0_doEnq_0 = io_enq_0_valid & enq_ready & ~io_flush_valid;
  wire s0_doEnq_1 = io_enq_1_valid & enq_ready & ~io_flush_valid;

  // enq.bits 折算(单源): srcState/dataSources 初值由 srcType/psrc 决定(对照 golden)。
  //   psrc==0 视为常零源; srcType[0]=reg(可被唤醒), [2]=imm/zero(立即就绪)。
  function automatic logic [3:0] enq_data_src(input logic [3:0] stype, input logic psrc_zero);
    if (stype[0] & psrc_zero)            enq_data_src = 4'h0;  // reg 源且 psrc=0 → 常零
    else if (stype == 4'h0)              enq_data_src = 4'h4;  // 纯 reg → 等 WB
    else if (stype[2] & psrc_zero)       enq_data_src = 4'h5;
    else                                 enq_data_src = 4'h8;  // imm/pc 等立即就绪
  endfunction
  function automatic logic enq_src_state(input logic [3:0] stype, input logic psrc_zero,
                                         input logic ext_state);
    enq_src_state = (stype[2] & psrc_zero) | ext_state;
  endfunction

  wire p0_0_zero = (io_enq_0_bits_psrc_0 == 8'h0);
  wire p1_0_zero = (io_enq_1_bits_psrc_0 == 8'h0);

  // ===========================================================================
  // 2. canIssue + 端口功能单元筛([E] 无 FuBusyTable, [G] STA/MOU)
  // ---------------------------------------------------------------------------
  //   deqCanAccept = fuType[STA] | fuType[MOU]; deqCanIssue = canIssue & deqCanAccept。
  // ===========================================================================
  wire [15:0] canIssueVec = e_can_issue;
  wire [15:0] port_fu;
  genvar gi;
  generate
    for (gi = 0; gi < 16; gi++) begin : g_portfu
      assign port_fu[gi] = e_fu_type[gi][FU_STA] | e_fu_type[gi][FU_MOU];
    end
  endgenerate
  wire [15:0] deqCanIssue_0 = canIssueVec & port_fu;

  // 三段年龄请求: enq=[1:0], simp=[3:2], comp=[15:4]。
  wire [1:0]  enqReq_0  = deqCanIssue_0[1:0];
  wire [1:0]  simpReq_0 = deqCanIssue_0[3:2];
  wire [11:0] compReq_0 = deqCanIssue_0[15:4];

  // 转移请求(simp→comp): 简单条目有效且未发射 → 请求转移到复杂区。
  //   simpReq_2 给转移端口0; simpReq_3 = simpReq_2 & ~age 端口0(转移)选中(避免重选)。
  wire [1:0] requestForTrans;
  generate
    for (gi = 0; gi < 2; gi++) begin : g_trans
      assign requestForTrans[gi] = e_valid[2+gi] & ~e_issued[2+gi];
    end
  endgenerate
  wire [1:0] simpReq_2 = requestForTrans;
  wire [1:0] simpReq_3 = requestForTrans & ~age_simp_out[1];

  // ===========================================================================
  // 3. deq one-hot 选择([B] 单端口)
  // ---------------------------------------------------------------------------
  //   优先级: comp > simp > enq。
  //   deqSimpOH = simp one-hot(仅当 comp 空时有效);
  //   deqEnqOH  = enq one-hot(仅当 comp、simp 都空时有效)。
  // ===========================================================================
  wire deqValid_0 = (|compReq_0) | (|simpReq_0) | (|enqReq_0);

  wire [1:0] deqSimpOH_0 = {2{~(|compReq_0)}} & age_simp_out[0];
  wire [1:0] deqEnqOH_0  = {2{~(|compReq_0) & ~(|simpReq_0)}} & age_enq_out;

  // 16 位发射 one-hot: {comp[11:0], simp[1:0], enq[1:0]}。
  wire [15:0] deqSelOH_0 = {age_comp_out, deqSimpOH_0, deqEnqOH_0};

  // ===========================================================================
  // 4. Mux1H: 用发射 one-hot 在 16 条目里选出 dataSources/loadDependency/exuSources
  // ---------------------------------------------------------------------------
  // 16-way one-hot 归约(单源 / 单端口)。用 always_comb 显式展开。
  // ===========================================================================
  logic [3:0] finalDataSources_0_0;
  logic [1:0] finalLoadDependency_0 [3];
  logic [2:0] finalExuSources_0_0;
  always_comb begin
    finalDataSources_0_0 = '0;
    finalExuSources_0_0  = '0;
    for (int k = 0; k < 16; k++) begin
      finalDataSources_0_0 |= ({4{deqSelOH_0[k]}} & e_data_src[k]);
      finalExuSources_0_0  |= ({3{deqSelOH_0[k]}} & e_exu_src[k]);
    end
    for (int p = 0; p < 3; p++) begin
      finalLoadDependency_0[p] = '0;
      for (int k = 0; k < 16; k++)
        finalLoadDependency_0[p] |= ({2{deqSelOH_0[k]}} & e_load_dep[k][p]);
    end
  end

  // ===========================================================================
  // 5. deqBeforeDly: 选中且未被 cancelDeqVec 撤销 → 本拍真正发射
  // ===========================================================================
  wire deqBeforeDly_0_valid = deqValid_0 & ~e_cancel_deq;

  // 端口0 fuType 重组(deqEntry 只给 16/17 位, 拼回 35 位 one-hot 形式)。
  wire [34:0] deqBeforeDly_0_fuType = {17'h0, e_deq0_ft17, e_deq0_ft16, 16'h0};

  // ===========================================================================
  // 6. deqDelay 寄存器: 发射 uop 经一拍寄存后送 DataPath。
  //   bits 部分仅在「队列非空」(|e_valid)时更新(golden 同款门控)。
  //   valid 每拍无条件更新为 deqBeforeDly_0_valid。
  // ===========================================================================
  deq_common_t d0;
  reg          d0_valid;
  reg  [4:0]   validCntDeqVec0_reg;

  // 在队的「可被本端口发射(STA/MOU)」uop 数(popcount of valid[k] & deqCanAccept[k])。
  logic [4:0] cnt_valid_acc;
  always_comb begin
    cnt_valid_acc = '0;
    for (int k = 0; k < 16; k++) cnt_valid_acc += 5'(e_valid[k] & port_fu[k]);
  end

  always @(posedge clock) begin
    d0_valid <= deqBeforeDly_0_valid;
    if (|e_valid) begin
      d0.rf_0_0_addr <= e_deq0_s0psrc;
      d0.rc_idx_0    <= e_deq0_s0rc;
      d0.imm_type    <= e_deq0_selimm;
      d0.fu_type     <= {17'h0, e_deq0_ft17, e_deq0_ft16, 16'h0};
      d0.fu_op_type  <= e_deq0_fuop;
      d0.imm         <= {52'h0, e_deq0_imm};
      d0.rob_flag    <= e_deq0_robflag;
      d0.rob_value   <= e_deq0_robval;
      d0.first_issue <= e_first_issue;       // [D]
      d0.pdest       <= e_deq0_pdest;
      d0.rf_wen      <= e_deq0_rfwen;
      d0.ftq_value   <= e_deq0_ftqval;
      d0.ftq_offset  <= e_deq0_ftqoff;
      d0.sq_flag     <= e_deq0_sqflag;       // [C]
      d0.sq_value    <= e_deq0_sqval;        // [C]
      d0.ds0         <= finalDataSources_0_0;
      d0.exu0        <= finalExuSources_0_0;
      d0.ld0         <= finalLoadDependency_0[0];
      d0.ld1         <= finalLoadDependency_0[1];
      d0.ld2         <= finalLoadDependency_0[2];
    end
    // validCntDeqVec_0: 在队的「本端口同类」uop 数, 减去本拍出队消耗。
    validCntDeqVec0_reg <=
      5'(cnt_valid_acc - {4'h0, (io_deqDelay_0_ready & d0_valid)});
  end

  // deqDelay 输出绑定
  assign io_deqDelay_0_valid                       = d0_valid;
  assign io_deqDelay_0_bits_rf_0_0_addr            = d0.rf_0_0_addr;
  assign io_deqDelay_0_bits_rcIdx_0                = d0.rc_idx_0;
  assign io_deqDelay_0_bits_immType                = d0.imm_type;
  assign io_deqDelay_0_bits_common_fuType          = d0.fu_type;
  assign io_deqDelay_0_bits_common_fuOpType        = d0.fu_op_type;
  assign io_deqDelay_0_bits_common_imm             = d0.imm;
  assign io_deqDelay_0_bits_common_robIdx_flag     = d0.rob_flag;
  assign io_deqDelay_0_bits_common_robIdx_value    = d0.rob_value;
  assign io_deqDelay_0_bits_common_isFirstIssue    = d0.first_issue;
  assign io_deqDelay_0_bits_common_pdest           = d0.pdest;
  assign io_deqDelay_0_bits_common_rfWen           = d0.rf_wen;
  assign io_deqDelay_0_bits_common_ftqIdx_value    = d0.ftq_value;
  assign io_deqDelay_0_bits_common_ftqOffset       = d0.ftq_offset;
  assign io_deqDelay_0_bits_common_sqIdx_flag      = d0.sq_flag;
  assign io_deqDelay_0_bits_common_sqIdx_value     = d0.sq_value;
  assign io_deqDelay_0_bits_common_dataSources_0_value = d0.ds0;
  assign io_deqDelay_0_bits_common_exuSources_0_value  = d0.exu0;
  assign io_deqDelay_0_bits_common_loadDependency_0 = d0.ld0;
  assign io_deqDelay_0_bits_common_loadDependency_1 = d0.ld1;
  assign io_deqDelay_0_bits_common_loadDependency_2 = d0.ld2;

  assign io_validCntDeqVec_0 = validCntDeqVec0_reg;

  // ===========================================================================
  // 7. [A] mem feedback 折算: feedbackSlow → entries.fromMem.slowResp
  // ---------------------------------------------------------------------------
  //   resp = hit ? success(2'b11) : block(2'b00); golden 写作 {2{hit}}, 等价。
  //   valid/sqIdx 直通。条目阵列据此把 issued 条目打回未发射或确认成功。
  // ===========================================================================
  wire        fromMem_slowResp_0_valid = io_memIO_feedbackIO_0_feedbackSlow_valid;
  wire [1:0]  fromMem_slowResp_0_resp  =
                io_memIO_feedbackIO_0_feedbackSlow_bits_hit ? RESP_SUCCESS : RESP_BLOCK;
  wire        fromMem_slowResp_0_sqflag = io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_flag;
  wire [5:0]  fromMem_slowResp_0_sqval  = io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_value;

  // ===========================================================================
  // 8. 子模块例化(均为 golden 黑盒)
  // ===========================================================================
  EntriesStaMou entries (
    .clock (clock), .reset (reset),
    .io_flush_valid (io_flush_valid),
    .io_flush_bits_robIdx_flag (io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value (io_flush_bits_robIdx_value),
    .io_flush_bits_level (io_flush_bits_level),
    .io_enq_0_valid (s0_doEnq_0),
    .io_enq_0_bits_status_robIdx_flag (io_enq_0_bits_robIdx_flag),
    .io_enq_0_bits_status_robIdx_value (io_enq_0_bits_robIdx_value),
    .io_enq_0_bits_status_fuType_16 (io_enq_0_bits_fuType[FU_STA]),
    .io_enq_0_bits_status_fuType_17 (io_enq_0_bits_fuType[FU_MOU]),
    .io_enq_0_bits_status_srcStatus_0_psrc (io_enq_0_bits_psrc_0),
    .io_enq_0_bits_status_srcStatus_0_srcType (io_enq_0_bits_srcType_0),
    .io_enq_0_bits_status_srcStatus_0_srcState (enq_src_state(io_enq_0_bits_srcType_0, p0_0_zero, io_enq_0_bits_srcState_0)),
    .io_enq_0_bits_status_srcStatus_0_dataSources_value (enq_data_src(io_enq_0_bits_srcType_0, p0_0_zero)),
    .io_enq_0_bits_status_srcStatus_0_srcLoadDependency_0 ({io_enq_0_bits_srcLoadDependency_0_0[0], 1'h0}),
    .io_enq_0_bits_status_srcStatus_0_srcLoadDependency_1 ({io_enq_0_bits_srcLoadDependency_0_1[0], 1'h0}),
    .io_enq_0_bits_status_srcStatus_0_srcLoadDependency_2 ({io_enq_0_bits_srcLoadDependency_0_2[0], 1'h0}),
    .io_enq_0_bits_status_srcStatus_0_useRegCache (io_enq_0_bits_useRegCache_0),
    .io_enq_0_bits_status_srcStatus_0_regCacheIdx (io_enq_0_bits_regCacheIdx_0),
    .io_enq_0_bits_imm (io_enq_0_bits_imm[11:0]),
    .io_enq_0_bits_payload_ftqPtr_value (io_enq_0_bits_ftqPtr_value),
    .io_enq_0_bits_payload_ftqOffset (io_enq_0_bits_ftqOffset),
    .io_enq_0_bits_payload_fuOpType (io_enq_0_bits_fuOpType),
    .io_enq_0_bits_payload_rfWen (io_enq_0_bits_rfWen),
    .io_enq_0_bits_payload_selImm (io_enq_0_bits_selImm),
    .io_enq_0_bits_payload_srcLoadDependency_0_0 (io_enq_0_bits_srcLoadDependency_0_0),
    .io_enq_0_bits_payload_srcLoadDependency_0_1 (io_enq_0_bits_srcLoadDependency_0_1),
    .io_enq_0_bits_payload_srcLoadDependency_0_2 (io_enq_0_bits_srcLoadDependency_0_2),
    .io_enq_0_bits_payload_pdest (io_enq_0_bits_pdest),
    .io_enq_0_bits_payload_sqIdx_flag (io_enq_0_bits_sqIdx_flag),
    .io_enq_0_bits_payload_sqIdx_value (io_enq_0_bits_sqIdx_value),
    .io_enq_1_valid (s0_doEnq_1),
    .io_enq_1_bits_status_robIdx_flag (io_enq_1_bits_robIdx_flag),
    .io_enq_1_bits_status_robIdx_value (io_enq_1_bits_robIdx_value),
    .io_enq_1_bits_status_fuType_16 (io_enq_1_bits_fuType[FU_STA]),
    .io_enq_1_bits_status_fuType_17 (io_enq_1_bits_fuType[FU_MOU]),
    .io_enq_1_bits_status_srcStatus_0_psrc (io_enq_1_bits_psrc_0),
    .io_enq_1_bits_status_srcStatus_0_srcType (io_enq_1_bits_srcType_0),
    .io_enq_1_bits_status_srcStatus_0_srcState (enq_src_state(io_enq_1_bits_srcType_0, p1_0_zero, io_enq_1_bits_srcState_0)),
    .io_enq_1_bits_status_srcStatus_0_dataSources_value (enq_data_src(io_enq_1_bits_srcType_0, p1_0_zero)),
    .io_enq_1_bits_status_srcStatus_0_srcLoadDependency_0 ({io_enq_1_bits_srcLoadDependency_0_0[0], 1'h0}),
    .io_enq_1_bits_status_srcStatus_0_srcLoadDependency_1 ({io_enq_1_bits_srcLoadDependency_0_1[0], 1'h0}),
    .io_enq_1_bits_status_srcStatus_0_srcLoadDependency_2 ({io_enq_1_bits_srcLoadDependency_0_2[0], 1'h0}),
    .io_enq_1_bits_status_srcStatus_0_useRegCache (io_enq_1_bits_useRegCache_0),
    .io_enq_1_bits_status_srcStatus_0_regCacheIdx (io_enq_1_bits_regCacheIdx_0),
    .io_enq_1_bits_imm (io_enq_1_bits_imm[11:0]),
    .io_enq_1_bits_payload_ftqPtr_value (io_enq_1_bits_ftqPtr_value),
    .io_enq_1_bits_payload_ftqOffset (io_enq_1_bits_ftqOffset),
    .io_enq_1_bits_payload_fuOpType (io_enq_1_bits_fuOpType),
    .io_enq_1_bits_payload_rfWen (io_enq_1_bits_rfWen),
    .io_enq_1_bits_payload_selImm (io_enq_1_bits_selImm),
    .io_enq_1_bits_payload_srcLoadDependency_0_0 (io_enq_1_bits_srcLoadDependency_0_0),
    .io_enq_1_bits_payload_srcLoadDependency_0_1 (io_enq_1_bits_srcLoadDependency_0_1),
    .io_enq_1_bits_payload_srcLoadDependency_0_2 (io_enq_1_bits_srcLoadDependency_0_2),
    .io_enq_1_bits_payload_pdest (io_enq_1_bits_pdest),
    .io_enq_1_bits_payload_sqIdx_flag (io_enq_1_bits_sqIdx_flag),
    .io_enq_1_bits_payload_sqIdx_value (io_enq_1_bits_sqIdx_value),
    .io_og0Resp_0_valid (io_og0Resp_0_valid),
    .io_og1Resp_0_valid (io_og1Resp_0_valid),
    .io_og1Resp_0_bits_resp (io_og1Resp_0_bits_resp),
    .io_deqSelOH_0_valid (deqValid_0),
    .io_deqSelOH_0_bits (deqSelOH_0),
    .io_enqEntryOldestSel_0_bits (age_enq_out),
    .io_simpEntryOldestSel_0_valid (|simpReq_0),
    .io_simpEntryOldestSel_0_bits (age_simp_out[0]),
    .io_compEntryOldestSel_0_valid (|compReq_0),
    .io_compEntryOldestSel_0_bits (age_comp_out),
    .io_wakeUpFromWB_3_valid (io_wakeupFromWB_3_valid),
    .io_wakeUpFromWB_3_bits_rfWen (io_wakeupFromWB_3_bits_rfWen),
    .io_wakeUpFromWB_3_bits_pdest (io_wakeupFromWB_3_bits_pdest),
    .io_wakeUpFromWB_2_valid (io_wakeupFromWB_2_valid),
    .io_wakeUpFromWB_2_bits_rfWen (io_wakeupFromWB_2_bits_rfWen),
    .io_wakeUpFromWB_2_bits_pdest (io_wakeupFromWB_2_bits_pdest),
    .io_wakeUpFromWB_1_valid (io_wakeupFromWB_1_valid),
    .io_wakeUpFromWB_1_bits_rfWen (io_wakeupFromWB_1_bits_rfWen),
    .io_wakeUpFromWB_1_bits_pdest (io_wakeupFromWB_1_bits_pdest),
    .io_wakeUpFromWB_0_valid (io_wakeupFromWB_0_valid),
    .io_wakeUpFromWB_0_bits_rfWen (io_wakeupFromWB_0_bits_rfWen),
    .io_wakeUpFromWB_0_bits_pdest (io_wakeupFromWB_0_bits_pdest),
    .io_wakeUpFromIQ_6_bits_rfWen (io_wakeupFromIQ_6_bits_rfWen),
    .io_wakeUpFromIQ_6_bits_pdest (io_wakeupFromIQ_6_bits_pdest),
    .io_wakeUpFromIQ_6_bits_rcDest (io_wakeupFromIQ_6_bits_rcDest),
    .io_wakeUpFromIQ_5_bits_rfWen (io_wakeupFromIQ_5_bits_rfWen),
    .io_wakeUpFromIQ_5_bits_pdest (io_wakeupFromIQ_5_bits_pdest),
    .io_wakeUpFromIQ_5_bits_rcDest (io_wakeupFromIQ_5_bits_rcDest),
    .io_wakeUpFromIQ_4_bits_rfWen (io_wakeupFromIQ_4_bits_rfWen),
    .io_wakeUpFromIQ_4_bits_pdest (io_wakeupFromIQ_4_bits_pdest),
    .io_wakeUpFromIQ_4_bits_rcDest (io_wakeupFromIQ_4_bits_rcDest),
    .io_wakeUpFromIQ_3_bits_rfWen (io_wakeupFromIQ_3_bits_rfWen),
    .io_wakeUpFromIQ_3_bits_pdest (io_wakeupFromIQ_3_bits_pdest),
    .io_wakeUpFromIQ_3_bits_loadDependency_0 (io_wakeupFromIQ_3_bits_loadDependency_0),
    .io_wakeUpFromIQ_3_bits_loadDependency_1 (io_wakeupFromIQ_3_bits_loadDependency_1),
    .io_wakeUpFromIQ_3_bits_loadDependency_2 (io_wakeupFromIQ_3_bits_loadDependency_2),
    .io_wakeUpFromIQ_3_bits_rcDest (io_wakeupFromIQ_3_bits_rcDest),
    .io_wakeUpFromIQ_2_bits_rfWen (io_wakeupFromIQ_2_bits_rfWen),
    .io_wakeUpFromIQ_2_bits_pdest (io_wakeupFromIQ_2_bits_pdest),
    .io_wakeUpFromIQ_2_bits_loadDependency_0 (io_wakeupFromIQ_2_bits_loadDependency_0),
    .io_wakeUpFromIQ_2_bits_loadDependency_1 (io_wakeupFromIQ_2_bits_loadDependency_1),
    .io_wakeUpFromIQ_2_bits_loadDependency_2 (io_wakeupFromIQ_2_bits_loadDependency_2),
    .io_wakeUpFromIQ_2_bits_rcDest (io_wakeupFromIQ_2_bits_rcDest),
    .io_wakeUpFromIQ_1_bits_rfWen (io_wakeupFromIQ_1_bits_rfWen),
    .io_wakeUpFromIQ_1_bits_pdest (io_wakeupFromIQ_1_bits_pdest),
    .io_wakeUpFromIQ_1_bits_loadDependency_0 (io_wakeupFromIQ_1_bits_loadDependency_0),
    .io_wakeUpFromIQ_1_bits_loadDependency_1 (io_wakeupFromIQ_1_bits_loadDependency_1),
    .io_wakeUpFromIQ_1_bits_loadDependency_2 (io_wakeupFromIQ_1_bits_loadDependency_2),
    .io_wakeUpFromIQ_1_bits_is0Lat (io_wakeupFromIQ_1_bits_is0Lat),
    .io_wakeUpFromIQ_1_bits_rcDest (io_wakeupFromIQ_1_bits_rcDest),
    .io_wakeUpFromIQ_0_bits_rfWen (io_wakeupFromIQ_0_bits_rfWen),
    .io_wakeUpFromIQ_0_bits_pdest (io_wakeupFromIQ_0_bits_pdest),
    .io_wakeUpFromIQ_0_bits_loadDependency_0 (io_wakeupFromIQ_0_bits_loadDependency_0),
    .io_wakeUpFromIQ_0_bits_loadDependency_1 (io_wakeupFromIQ_0_bits_loadDependency_1),
    .io_wakeUpFromIQ_0_bits_loadDependency_2 (io_wakeupFromIQ_0_bits_loadDependency_2),
    .io_wakeUpFromIQ_0_bits_is0Lat (io_wakeupFromIQ_0_bits_is0Lat),
    .io_wakeUpFromIQ_0_bits_rcDest (io_wakeupFromIQ_0_bits_rcDest),
    .io_wakeUpFromWBDelayed_3_valid (io_wakeupFromWBDelayed_3_valid),
    .io_wakeUpFromWBDelayed_3_bits_rfWen (io_wakeupFromWBDelayed_3_bits_rfWen),
    .io_wakeUpFromWBDelayed_3_bits_pdest (io_wakeupFromWBDelayed_3_bits_pdest),
    .io_wakeUpFromWBDelayed_2_valid (io_wakeupFromWBDelayed_2_valid),
    .io_wakeUpFromWBDelayed_2_bits_rfWen (io_wakeupFromWBDelayed_2_bits_rfWen),
    .io_wakeUpFromWBDelayed_2_bits_pdest (io_wakeupFromWBDelayed_2_bits_pdest),
    .io_wakeUpFromWBDelayed_1_valid (io_wakeupFromWBDelayed_1_valid),
    .io_wakeUpFromWBDelayed_1_bits_rfWen (io_wakeupFromWBDelayed_1_bits_rfWen),
    .io_wakeUpFromWBDelayed_1_bits_pdest (io_wakeupFromWBDelayed_1_bits_pdest),
    .io_wakeUpFromWBDelayed_0_valid (io_wakeupFromWBDelayed_0_valid),
    .io_wakeUpFromWBDelayed_0_bits_rfWen (io_wakeupFromWBDelayed_0_bits_rfWen),
    .io_wakeUpFromWBDelayed_0_bits_pdest (io_wakeupFromWBDelayed_0_bits_pdest),
    .io_wakeUpFromIQDelayed_6_bits_rfWen (io_wakeupFromIQDelayed_6_bits_rfWen),
    .io_wakeUpFromIQDelayed_6_bits_pdest (io_wakeupFromIQDelayed_6_bits_pdest),
    .io_wakeUpFromIQDelayed_6_bits_rcDest (io_wakeupFromIQDelayed_6_bits_rcDest),
    .io_wakeUpFromIQDelayed_5_bits_rfWen (io_wakeupFromIQDelayed_5_bits_rfWen),
    .io_wakeUpFromIQDelayed_5_bits_pdest (io_wakeupFromIQDelayed_5_bits_pdest),
    .io_wakeUpFromIQDelayed_5_bits_rcDest (io_wakeupFromIQDelayed_5_bits_rcDest),
    .io_wakeUpFromIQDelayed_4_bits_rfWen (io_wakeupFromIQDelayed_4_bits_rfWen),
    .io_wakeUpFromIQDelayed_4_bits_pdest (io_wakeupFromIQDelayed_4_bits_pdest),
    .io_wakeUpFromIQDelayed_4_bits_rcDest (io_wakeupFromIQDelayed_4_bits_rcDest),
    .io_wakeUpFromIQDelayed_3_bits_rfWen (io_wakeupFromIQDelayed_3_bits_rfWen),
    .io_wakeUpFromIQDelayed_3_bits_pdest (io_wakeupFromIQDelayed_3_bits_pdest),
    .io_wakeUpFromIQDelayed_3_bits_loadDependency_0 (io_wakeupFromIQDelayed_3_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_3_bits_loadDependency_1 (io_wakeupFromIQDelayed_3_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_3_bits_loadDependency_2 (io_wakeupFromIQDelayed_3_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_3_bits_rcDest (io_wakeupFromIQDelayed_3_bits_rcDest),
    .io_wakeUpFromIQDelayed_2_bits_rfWen (io_wakeupFromIQDelayed_2_bits_rfWen),
    .io_wakeUpFromIQDelayed_2_bits_pdest (io_wakeupFromIQDelayed_2_bits_pdest),
    .io_wakeUpFromIQDelayed_2_bits_loadDependency_0 (io_wakeupFromIQDelayed_2_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_2_bits_loadDependency_1 (io_wakeupFromIQDelayed_2_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_2_bits_loadDependency_2 (io_wakeupFromIQDelayed_2_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_2_bits_rcDest (io_wakeupFromIQDelayed_2_bits_rcDest),
    .io_wakeUpFromIQDelayed_1_bits_rfWen (io_wakeupFromIQDelayed_1_bits_rfWen),
    .io_wakeUpFromIQDelayed_1_bits_pdest (io_wakeupFromIQDelayed_1_bits_pdest),
    .io_wakeUpFromIQDelayed_1_bits_loadDependency_0 (io_wakeupFromIQDelayed_1_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_1_bits_loadDependency_1 (io_wakeupFromIQDelayed_1_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_1_bits_loadDependency_2 (io_wakeupFromIQDelayed_1_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_1_bits_is0Lat (io_wakeupFromIQDelayed_1_bits_is0Lat),
    .io_wakeUpFromIQDelayed_1_bits_rcDest (io_wakeupFromIQDelayed_1_bits_rcDest),
    .io_wakeUpFromIQDelayed_0_bits_rfWen (io_wakeupFromIQDelayed_0_bits_rfWen),
    .io_wakeUpFromIQDelayed_0_bits_pdest (io_wakeupFromIQDelayed_0_bits_pdest),
    .io_wakeUpFromIQDelayed_0_bits_loadDependency_0 (io_wakeupFromIQDelayed_0_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_0_bits_loadDependency_1 (io_wakeupFromIQDelayed_0_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_0_bits_loadDependency_2 (io_wakeupFromIQDelayed_0_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_0_bits_is0Lat (io_wakeupFromIQDelayed_0_bits_is0Lat),
    .io_wakeUpFromIQDelayed_0_bits_rcDest (io_wakeupFromIQDelayed_0_bits_rcDest),
    .io_og0Cancel_0 (io_og0Cancel_0),
    .io_og0Cancel_2 (io_og0Cancel_2),
    .io_og0Cancel_4 (io_og0Cancel_4),
    .io_og0Cancel_6 (io_og0Cancel_6),
    .io_ldCancel_0_ld2Cancel (io_ldCancel_0_ld2Cancel),
    .io_ldCancel_1_ld2Cancel (io_ldCancel_1_ld2Cancel),
    .io_ldCancel_2_ld2Cancel (io_ldCancel_2_ld2Cancel),
    .io_valid (e_valid),
    .io_issued (e_issued),
    .io_canIssue (e_can_issue),
    .io_fuType_0 (e_fu_type[0]),   .io_fuType_1 (e_fu_type[1]),
    .io_fuType_2 (e_fu_type[2]),   .io_fuType_3 (e_fu_type[3]),
    .io_fuType_4 (e_fu_type[4]),   .io_fuType_5 (e_fu_type[5]),
    .io_fuType_6 (e_fu_type[6]),   .io_fuType_7 (e_fu_type[7]),
    .io_fuType_8 (e_fu_type[8]),   .io_fuType_9 (e_fu_type[9]),
    .io_fuType_10 (e_fu_type[10]), .io_fuType_11 (e_fu_type[11]),
    .io_fuType_12 (e_fu_type[12]), .io_fuType_13 (e_fu_type[13]),
    .io_fuType_14 (e_fu_type[14]), .io_fuType_15 (e_fu_type[15]),
    .io_dataSources_0_0_value (e_data_src[0]),   .io_dataSources_1_0_value (e_data_src[1]),
    .io_dataSources_2_0_value (e_data_src[2]),   .io_dataSources_3_0_value (e_data_src[3]),
    .io_dataSources_4_0_value (e_data_src[4]),   .io_dataSources_5_0_value (e_data_src[5]),
    .io_dataSources_6_0_value (e_data_src[6]),   .io_dataSources_7_0_value (e_data_src[7]),
    .io_dataSources_8_0_value (e_data_src[8]),   .io_dataSources_9_0_value (e_data_src[9]),
    .io_dataSources_10_0_value (e_data_src[10]), .io_dataSources_11_0_value (e_data_src[11]),
    .io_dataSources_12_0_value (e_data_src[12]), .io_dataSources_13_0_value (e_data_src[13]),
    .io_dataSources_14_0_value (e_data_src[14]), .io_dataSources_15_0_value (e_data_src[15]),
    .io_loadDependency_0_0 (e_load_dep[0][0]),   .io_loadDependency_0_1 (e_load_dep[0][1]),   .io_loadDependency_0_2 (e_load_dep[0][2]),
    .io_loadDependency_1_0 (e_load_dep[1][0]),   .io_loadDependency_1_1 (e_load_dep[1][1]),   .io_loadDependency_1_2 (e_load_dep[1][2]),
    .io_loadDependency_2_0 (e_load_dep[2][0]),   .io_loadDependency_2_1 (e_load_dep[2][1]),   .io_loadDependency_2_2 (e_load_dep[2][2]),
    .io_loadDependency_3_0 (e_load_dep[3][0]),   .io_loadDependency_3_1 (e_load_dep[3][1]),   .io_loadDependency_3_2 (e_load_dep[3][2]),
    .io_loadDependency_4_0 (e_load_dep[4][0]),   .io_loadDependency_4_1 (e_load_dep[4][1]),   .io_loadDependency_4_2 (e_load_dep[4][2]),
    .io_loadDependency_5_0 (e_load_dep[5][0]),   .io_loadDependency_5_1 (e_load_dep[5][1]),   .io_loadDependency_5_2 (e_load_dep[5][2]),
    .io_loadDependency_6_0 (e_load_dep[6][0]),   .io_loadDependency_6_1 (e_load_dep[6][1]),   .io_loadDependency_6_2 (e_load_dep[6][2]),
    .io_loadDependency_7_0 (e_load_dep[7][0]),   .io_loadDependency_7_1 (e_load_dep[7][1]),   .io_loadDependency_7_2 (e_load_dep[7][2]),
    .io_loadDependency_8_0 (e_load_dep[8][0]),   .io_loadDependency_8_1 (e_load_dep[8][1]),   .io_loadDependency_8_2 (e_load_dep[8][2]),
    .io_loadDependency_9_0 (e_load_dep[9][0]),   .io_loadDependency_9_1 (e_load_dep[9][1]),   .io_loadDependency_9_2 (e_load_dep[9][2]),
    .io_loadDependency_10_0 (e_load_dep[10][0]), .io_loadDependency_10_1 (e_load_dep[10][1]), .io_loadDependency_10_2 (e_load_dep[10][2]),
    .io_loadDependency_11_0 (e_load_dep[11][0]), .io_loadDependency_11_1 (e_load_dep[11][1]), .io_loadDependency_11_2 (e_load_dep[11][2]),
    .io_loadDependency_12_0 (e_load_dep[12][0]), .io_loadDependency_12_1 (e_load_dep[12][1]), .io_loadDependency_12_2 (e_load_dep[12][2]),
    .io_loadDependency_13_0 (e_load_dep[13][0]), .io_loadDependency_13_1 (e_load_dep[13][1]), .io_loadDependency_13_2 (e_load_dep[13][2]),
    .io_loadDependency_14_0 (e_load_dep[14][0]), .io_loadDependency_14_1 (e_load_dep[14][1]), .io_loadDependency_14_2 (e_load_dep[14][2]),
    .io_loadDependency_15_0 (e_load_dep[15][0]), .io_loadDependency_15_1 (e_load_dep[15][1]), .io_loadDependency_15_2 (e_load_dep[15][2]),
    .io_exuSources_0_0_value (e_exu_src[0]),   .io_exuSources_1_0_value (e_exu_src[1]),
    .io_exuSources_2_0_value (e_exu_src[2]),   .io_exuSources_3_0_value (e_exu_src[3]),
    .io_exuSources_4_0_value (e_exu_src[4]),   .io_exuSources_5_0_value (e_exu_src[5]),
    .io_exuSources_6_0_value (e_exu_src[6]),   .io_exuSources_7_0_value (e_exu_src[7]),
    .io_exuSources_8_0_value (e_exu_src[8]),   .io_exuSources_9_0_value (e_exu_src[9]),
    .io_exuSources_10_0_value (e_exu_src[10]), .io_exuSources_11_0_value (e_exu_src[11]),
    .io_exuSources_12_0_value (e_exu_src[12]), .io_exuSources_13_0_value (e_exu_src[13]),
    .io_exuSources_14_0_value (e_exu_src[14]), .io_exuSources_15_0_value (e_exu_src[15]),
    .io_isFirstIssue_0 (e_first_issue),
    .io_deqEntry_0_bits_status_robIdx_flag (e_deq0_robflag),
    .io_deqEntry_0_bits_status_robIdx_value (e_deq0_robval),
    .io_deqEntry_0_bits_status_fuType_16 (e_deq0_ft16),
    .io_deqEntry_0_bits_status_fuType_17 (e_deq0_ft17),
    .io_deqEntry_0_bits_status_srcStatus_0_psrc (e_deq0_s0psrc),
    .io_deqEntry_0_bits_status_srcStatus_0_srcType (e_deq0_s0type),
    .io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx (e_deq0_s0rc),
    .io_deqEntry_0_bits_imm (e_deq0_imm),
    .io_deqEntry_0_bits_payload_ftqPtr_value (e_deq0_ftqval),
    .io_deqEntry_0_bits_payload_ftqOffset (e_deq0_ftqoff),
    .io_deqEntry_0_bits_payload_fuOpType (e_deq0_fuop),
    .io_deqEntry_0_bits_payload_rfWen (e_deq0_rfwen),
    .io_deqEntry_0_bits_payload_selImm (e_deq0_selimm),
    .io_deqEntry_0_bits_payload_pdest (e_deq0_pdest),
    .io_deqEntry_0_bits_payload_sqIdx_flag (e_deq0_sqflag),
    .io_deqEntry_0_bits_payload_sqIdx_value (e_deq0_sqval),
    .io_cancelDeqVec_0 (e_cancel_deq),
    // [A] mem feedback → 条目阵列 fromMem.slowResp
    .io_fromMem_slowResp_0_valid (fromMem_slowResp_0_valid),
    .io_fromMem_slowResp_0_bits_resp (fromMem_slowResp_0_resp),
    .io_fromMem_slowResp_0_bits_sqIdx_flag (fromMem_slowResp_0_sqflag),
    .io_fromMem_slowResp_0_bits_sqIdx_value (fromMem_slowResp_0_sqval),
    .io_simpEntryDeqSelVec_0 (age_simp_out[1]),
    .io_simpEntryDeqSelVec_1 (age_simp_out[2]),
    .io_simpEntryEnqSelVec_0 (e_simp_enq_sel[0]),
    .io_simpEntryEnqSelVec_1 (e_simp_enq_sel[1]),
    .io_compEntryEnqSelVec_0 (e_comp_enq_sel[0]),
    .io_compEntryEnqSelVec_1 (e_comp_enq_sel[1])
  );

  NewAgeDetector_6 age (
    .clock (clock), .reset (reset),
    .io_enq_0 (s0_doEnq_0), .io_enq_1 (s0_doEnq_1),
    .io_canIssue_0 (enqReq_0),
    .io_out_0 (age_enq_out)
  );
  AgeDetector_12 age_1 (
    .clock (clock), .reset (reset),
    .io_enq_0 (e_simp_enq_sel[0]), .io_enq_1 (e_simp_enq_sel[1]),
    .io_canIssue_0 (simpReq_0),
    .io_canIssue_1 (simpReq_2),
    .io_canIssue_2 (simpReq_3),
    .io_out_0 (age_simp_out[0]), .io_out_1 (age_simp_out[1]),
    .io_out_2 (age_simp_out[2])
  );
  AgeDetector_21 age_2 (
    .clock (clock), .reset (reset),
    .io_enq_0 (e_comp_enq_sel[0]), .io_enq_1 (e_comp_enq_sel[1]),
    .io_canIssue_0 (compReq_0),
    .io_out_0 (age_comp_out)
  );
endmodule

// =============================================================================
// IssueQueueStaMou —— golden 同名顶层。本变体 IQ 顶层端口与可读核完全一致
// (核已直接持平 golden 扁平接口), 故这里是纯穿透 wrapper, 仅做命名对齐。
// =============================================================================
module IssueQueueStaMou (
  input         clock,
  input         reset,
`include "issuequeue_stamou_ports.svh"
);
`include "issuequeue_stamou_connect.svh"
endmodule
