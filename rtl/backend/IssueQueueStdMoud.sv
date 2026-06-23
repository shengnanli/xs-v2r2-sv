// =============================================================================
// xs_IssueQueueStdMoud_core —— 香山 V2R2 发射队列 StdMoud(store-data)变体 可读核
// -----------------------------------------------------------------------------
// 设计源: src/main/scala/xiangshan/backend/issue/IssueQueue.scala
//         (class IssueQueueImp —— StdMoud 是普通整数派生, 非 MemAddr 子类)
//
// 本核与整数样板 / 访存样板 xs_IssueQueueStaMou_core 同构(把条目阵列 EntriesStdMoud
// 包起来, 做 enq 分配 / canIssue 合并 / 年龄仲裁 / deq 发射 / deqDelay 寄存), 但它是
// 「裁瘦版整数 IQ」, 差异(详见 iq_stdmoud_pkg 顶部)逐项标注:
//
//   [A] 无 mem feedback / 无 isFirstIssue: store-data 不做地址翻译, issued 条目仅靠
//       og0/og1Resp 普通响应推进。条目阵列 EntriesStdMoud 没有 io_fromMem / io_isFirstIssue。
//   [B] 单源 / 单发射端口: numRegSrc=1, numDeq=1。Mux1H 只对源 0 / 端口 0 做。
//   [C] deqDelay 极薄: 输出 srcType_0(StdExeUnit 据此区分 int/fp 数据源)+ 数据源寻址
//       字段 + common.{fuType,fuOpType,robIdx,sqIdx,dataSources,exuSources,loadDependency}。
//       *没有* imm/immType/pdest/rfWen/ftq/isFirstIssue。
//   [D] sqIdx 透传: store-data 要把数据写回 StoreQueue 的数据域, robIdx/sqIdx 随发射送出。
//   [E] 无 FuBusyTable / 无 wakeupToIQ / 无 validCntDeqVec 输出。
//   [F] FP 唤醒: WB_4..9 / IQDelayed_4..6 带 fpWen(数据源可能来自浮点写回)。唤醒匹配
//       全在条目阵列(黑盒)内完成, 本核仅按 golden 原样透传这些唤醒端口。
//   [G] 端口承担功能单元: deqCanAccept = fuType[16] | fuType[17]。
//
// 子模块(均为 golden 黑盒, 端口已扁平): EntriesStdMoud(16 条目阵列)、NewAgeDetector_6
// (入队 2 条目)、AgeDetector_12(simp 2 条目, 3 路: deq/trans0/trans1)、AgeDetector_21
// (comp 12 条目)。本核负责把它们连起来并实现上述调度逻辑。
// =============================================================================
module xs_IssueQueueStdMoud_core import iq_stdmoud_pkg::*; (
  input         clock,
  input         reset,
`include "issuequeue_stdmoud_ports.svh"
);

  // ===========================================================================
  // 发射端口承载 uop 公共字段(deqEntry → deqBeforeDly → deqDelay 寄存器)。
  // 单发射端口 / 单源, 故只有一个 deq_common_t。store-data 极薄: 无 imm/pdest/rfWen/ftq。
  // ===========================================================================
  typedef struct packed {
    logic [7:0]  rf_0_0_addr;   // 源0 物理寄存器号(rf read addr)
    logic [3:0]  src_type_0;    // [C] 源0 srcType(int/fp 数据源判别)
    logic [4:0]  rc_idx_0;      // 源0 regCache 索引
    logic [34:0] fu_type;       // 功能单元 one-hot(只保留 16/17 位)
    logic [8:0]  fu_op_type;
    logic        rob_flag;
    logic [7:0]  rob_value;
    logic        sq_flag;       // [D] sqIdx.flag
    logic [5:0]  sq_value;      // [D] sqIdx.value
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
  // deqEntry 端口(单端口)
  wire        e_deq0_robflag, e_deq0_ft16, e_deq0_ft17, e_deq0_sqflag;
  wire [7:0]  e_deq0_robval, e_deq0_s0psrc;
  wire [3:0]  e_deq0_s0type;
  wire [4:0]  e_deq0_s0rc;
  wire [8:0]  e_deq0_fuop;
  wire [5:0]  e_deq0_sqval;

  // ---- 年龄检测器输出 ----
  wire [1:0]  age_enq_out;       // NewAgeDetector_6: 入队 2 条目 one-hot
  wire [1:0]  age_simp_out [3];  // AgeDetector_12: simp 2 条目, 3 路(deq/trans0/trans1)
  wire [11:0] age_comp_out;      // AgeDetector_21: comp 12 条目

  // ===========================================================================
  // 1. enq 分配: ready / s0_doEnq
  // ---------------------------------------------------------------------------
  // simpCanotIn: 2 个简单条目(idx2/3)里已占用 >=1 个 → 简单区将满, 不能再收 2 条。
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
  // 2. canIssue + 端口功能单元筛([E] 无 FuBusyTable, [G] 16/17)
  // ---------------------------------------------------------------------------
  //   deqCanAccept = fuType[16] | fuType[17]; deqCanIssue = canIssue & deqCanAccept。
  // ===========================================================================
  wire [15:0] canIssueVec = e_can_issue;
  wire [15:0] port_fu;
  genvar gi;
  generate
    for (gi = 0; gi < 16; gi++) begin : g_portfu
      assign port_fu[gi] = e_fu_type[gi][FU_BIT_LO] | e_fu_type[gi][FU_BIT_HI];
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

  // ===========================================================================
  // 6. deqDelay 寄存器: 发射 uop 经一拍寄存后送 DataPath。
  //   bits 部分仅在「队列非空」(|e_valid)时更新(golden 同款门控)。
  //   valid 每拍无条件更新为 deqBeforeDly_0_valid。
  // ===========================================================================
  deq_common_t d0;
  reg          d0_valid;

  always @(posedge clock) begin
    d0_valid <= deqBeforeDly_0_valid;
    if (|e_valid) begin
      d0.rf_0_0_addr <= e_deq0_s0psrc;
      d0.src_type_0  <= e_deq0_s0type;       // [C]
      d0.rc_idx_0    <= e_deq0_s0rc;
      d0.fu_type     <= {17'h0, e_deq0_ft17, e_deq0_ft16, 16'h0};
      d0.fu_op_type  <= e_deq0_fuop;
      d0.rob_flag    <= e_deq0_robflag;
      d0.rob_value   <= e_deq0_robval;
      d0.sq_flag     <= e_deq0_sqflag;       // [D]
      d0.sq_value    <= e_deq0_sqval;        // [D]
      d0.ds0         <= finalDataSources_0_0;
      d0.exu0        <= finalExuSources_0_0;
      d0.ld0         <= finalLoadDependency_0[0];
      d0.ld1         <= finalLoadDependency_0[1];
      d0.ld2         <= finalLoadDependency_0[2];
    end
  end

  // deqDelay 输出绑定
  assign io_deqDelay_0_valid                       = d0_valid;
  assign io_deqDelay_0_bits_rf_0_0_addr            = d0.rf_0_0_addr;
  assign io_deqDelay_0_bits_srcType_0              = d0.src_type_0;
  assign io_deqDelay_0_bits_rcIdx_0                = d0.rc_idx_0;
  assign io_deqDelay_0_bits_common_fuType          = d0.fu_type;
  assign io_deqDelay_0_bits_common_fuOpType        = d0.fu_op_type;
  assign io_deqDelay_0_bits_common_robIdx_flag     = d0.rob_flag;
  assign io_deqDelay_0_bits_common_robIdx_value    = d0.rob_value;
  assign io_deqDelay_0_bits_common_sqIdx_flag      = d0.sq_flag;
  assign io_deqDelay_0_bits_common_sqIdx_value     = d0.sq_value;
  assign io_deqDelay_0_bits_common_dataSources_0_value = d0.ds0;
  assign io_deqDelay_0_bits_common_exuSources_0_value  = d0.exu0;
  assign io_deqDelay_0_bits_common_loadDependency_0 = d0.ld0;
  assign io_deqDelay_0_bits_common_loadDependency_1 = d0.ld1;
  assign io_deqDelay_0_bits_common_loadDependency_2 = d0.ld2;

  // ===========================================================================
  // 7. 子模块例化(均为 golden 黑盒)
  // ---------------------------------------------------------------------------
  // 条目阵列例化连线由 gen 脚本从 golden 机械抽取(纯结构透传 + 上述可读信号替换),
  // 放在 issuequeue_stdmoud_entries.svh; 年龄检测器 3 个手写。
  // ===========================================================================
`include "issuequeue_stdmoud_entries.svh"

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
// IssueQueueStdMoud —— golden 同名顶层。本变体 IQ 顶层端口与可读核完全一致
// (核已直接持平 golden 扁平接口), 故这里是纯穿透 wrapper, 仅做命名对齐。
// =============================================================================
module IssueQueueStdMoud (
  input         clock,
  input         reset,
`include "issuequeue_stdmoud_ports.svh"
);
`include "issuequeue_stdmoud_connect.svh"
endmodule
