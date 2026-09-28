// MemTrigger.sv —— 访存 load 的调试触发器（Sdtrig mcontrol6）地址匹配：LoadUnit s1 的 child。
//
// 位置：LoadUnit s1 拿到 TLB 返回的 fullva 后送进来，本模块纯组合地判定 4 个触发器
//   （TriggerNum=4）里哪些命中、该触发什么动作，结果回到 s1_out.uop.trigger /
//   exceptionVec(breakPoint) / vecVaddrOffset / vecTriggerMask。
// 核心机制（Scala: xiangshan.backend.fu.NewCSR.Debug.scala 的 BaseTrigger/MemTrigger(LOAD)）：
//   1. 每个触发器单独判"地址命中"：标量按 matchType 比 EQ/GE/LT；向量 unit-stride 128bit
//      访问改成"16B 块号相等 且 tdata2 低 4 位指向的字节在 mask 里"。软件 prefetch(isPrf)
//      对标量比较不命中。select=1(数据匹配)/debugMode 下一律不命中。
//   2. 链(chain)：第 i 个触发器 chain=1 表示它要和第 i+1 个"与"起来一起判；链中间的
//      触发器自己不能触发，只有链尾（chain=0）才能触发，且链上相邻两个 timing 要相同。
//   3. 动作：能触发者里只要有一个 action=DebugMode(1) 就进 debug mode；否则有
//      action=BreakpointExp(0) 且 CSR 允许时报断点异常；都没有则 None(0xF)。
//      回报的 vaddr/mask 取"本动作类别里编号最小的那个"触发器的 tdata2。
// 本 LOAD 变体没有 isCbo 口（Scala Option 只给 STORE），所以缓存行匹配分支恒不选。

module xs_MemTrigger_core #(
  parameter int NUM_TRIGGERS = 4,     // TriggerNum
  parameter int VADDR_W      = 50,    // VAddrBits
  parameter int MASK_W       = 16     // VLEN/8：向量访问的字节掩码宽
) (
  // ---- 来自 CSR 的触发器配置（每个触发器一份 tdata1 解码字段 + tdata2）----
  input  logic [NUM_TRIGGERS-1:0][1:0]  matchType,     // 0=EQ 2=GE 3=LT（1 保留，恒不命中）
  input  logic [NUM_TRIGGERS-1:0]       select,        // 1=按数据匹配（本实现不支持 → 不命中）
  input  logic [NUM_TRIGGERS-1:0]       timing,        // 链上相邻触发器须同 timing
  input  logic [NUM_TRIGGERS-1:0][3:0]  action,        // 0=断点异常 1=进 debug mode
  input  logic [NUM_TRIGGERS-1:0]       chain,         // 与下一个触发器串成链
  input  logic [NUM_TRIGGERS-1:0]       load,          // 对 load 生效
  input  logic [NUM_TRIGGERS-1:0][63:0] tdata2,        // 比较地址
  input  logic [NUM_TRIGGERS-1:0]       tEnable,       // 当前特权级下是否使能
  input  logic                          debugMode,     // 已在 debug mode：任何触发器都不命中
  input  logic                          triggerCanRaiseBpExp,
  // ---- 来自 load 流水 ----
  input  logic [VADDR_W-1:0]            vaddr,         // 本次访问的虚地址（fullva 低位）
  input  logic                          isVectorUnitStride,  // 向量 128bit unit-stride 访问
  input  logic [MASK_W-1:0]             mask,          // 该访问覆盖的字节
  input  logic                          isPrf,         // 软件 prefetch：标量比较一律不命中
  // ---- 回 load 流水 ----
  output logic [3:0]                    triggerAction, // 1=DebugMode 0=BreakpointExp 0xF=None
  output logic [VADDR_W-1:0]            triggerVaddr,
  output logic [MASK_W-1:0]             triggerMask
);

  localparam int LOW_W = $clog2(MASK_W);     // 16B 块内偏移位宽 = 4

  localparam logic [1:0] MATCH_EQ = 2'd0;
  localparam logic [1:0] MATCH_GE = 2'd2;
  localparam logic [1:0] MATCH_LT = 2'd3;

  localparam logic [3:0] ACT_BREAKPOINT_EXP = 4'h0;
  localparam logic [3:0] ACT_DEBUG_MODE     = 4'h1;
  localparam logic [3:0] ACT_NONE           = 4'hF;

  // -------------------------------------------------------------------
  // 1. 每个触发器的地址命中
  // -------------------------------------------------------------------
  logic [NUM_TRIGGERS-1:0] scalarHit;     // 标量：按 matchType 比较整段 vaddr
  logic [NUM_TRIGGERS-1:0] vectorHit;     // 向量 unit-stride：16B 块号相等 且 字节在 mask 内
  logic [NUM_TRIGGERS-1:0] addrHit;       // 按访问类型二选一
  logic [NUM_TRIGGERS-1:0][MASK_W-1:0] tdata2ByteOH;  // tdata2 低 4 位译成 one-hot 字节

  always_comb begin
    for (int i = 0; i < NUM_TRIGGERS; i++) begin
      logic [VADDR_W-1:0] taddr;
      logic               cmp;
      taddr = tdata2[i][VADDR_W-1:0];
      case (matchType[i])
        MATCH_EQ: cmp = (vaddr == taddr);
        MATCH_GE: cmp = (vaddr >= taddr);
        MATCH_LT: cmp = (vaddr <  taddr);
        default:  cmp = 1'b0;
      endcase
      scalarHit[i] = ~select[i] & ~debugMode & ~isPrf & cmp & tEnable[i] & load[i];

      tdata2ByteOH[i] = MASK_W'(1) << tdata2[i][LOW_W-1:0];
      // 块号比较：vaddr 右移后零扩展到 tdata2 的 60 位，tdata2 高于 VAddrBits 的位必须为 0
      vectorHit[i] = ~select[i] & ~debugMode & tEnable[i] & load[i]
                   & (64'(vaddr >> LOW_W) == 64'(tdata2[i] >> LOW_W))
                   & (|(tdata2ByteOH[i] & mask));

      addrHit[i] = isVectorUnitStride ? vectorHit[i] : scalarHit[i];
    end
  end

  // -------------------------------------------------------------------
  // 2. 链：只有链尾能触发，且链上每一环都命中、相邻 timing 相同
  //    (Scala TriggerCheckCanFire：第 0 个触发器前面没有链，视为 chainOk/timingOk)
  // -------------------------------------------------------------------
  logic [NUM_TRIGGERS-1:0] canFire;
  always_comb begin
    for (int i = 0; i < NUM_TRIGGERS; i++) begin
      logic chainOk, timingOk;
      if (i == 0) begin
        chainOk  = 1'b1;
        timingOk = 1'b1;
      end else begin
        // 前一个在链上 → 它必须命中；前一个不在链上 → 无约束
        chainOk  = chain[i-1] & addrHit[i-1] | ~chain[i-1];
        // 前一个在链上且本个是链尾 → 两者 timing 须相同
        timingOk = chain[i-1] & ~chain[i] & (timing[i-1] == timing[i]) | ~chain[i-1];
      end
      canFire[i] = chainOk & timingOk & addrHit[i] & ~chain[i];
    end
  end

  // -------------------------------------------------------------------
  // 3. 动作仲裁：DebugMode 优先于 BreakpointExp
  // -------------------------------------------------------------------
  logic [NUM_TRIGGERS-1:0] fireDebugMode, fireBreakpoint, fireVec;
  logic                    anyDebugMode, breakPointExp;
  always_comb begin
    for (int i = 0; i < NUM_TRIGGERS; i++) begin
      fireDebugMode[i]  = canFire[i] & (action[i] == ACT_DEBUG_MODE);
      fireBreakpoint[i] = canFire[i] & (action[i] == ACT_BREAKPOINT_EXP);
    end
    anyDebugMode  = |fireDebugMode;
    breakPointExp = (|fireBreakpoint) & triggerCanRaiseBpExp;
    // 真正触发的集合：进 debug mode 时取 debug 类；否则断点异常类（须被允许）
    fireVec = anyDebugMode ? fireDebugMode
                           : (breakPointExp ? fireBreakpoint : '0);
    triggerAction = anyDebugMode ? ACT_DEBUG_MODE
                  : breakPointExp ? ACT_BREAKPOINT_EXP : ACT_NONE;
  end

  // -------------------------------------------------------------------
  // 4. 回报 vaddr / mask：取触发集合里编号最小者（全不触发时回 0）
  // -------------------------------------------------------------------
  always_comb begin
    triggerVaddr = '0;
    triggerMask  = '0;
    for (int i = NUM_TRIGGERS - 1; i >= 0; i--)
      if (fireVec[i]) begin
        triggerVaddr = tdata2[i][VADDR_W-1:0];
        triggerMask  = tdata2ByteOH[i];
      end
  end

endmodule

// golden 同名 wrapper：端口逐位同 golden MemTrigger，打包成数组交给核
module MemTrigger (
  input  [1:0]  tdataVec_io_fromCsrTrigger_tdataVec_0_matchType,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_select,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_timing,
  input  [3:0]  tdataVec_io_fromCsrTrigger_tdataVec_0_action,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_chain,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_load,
  input  [63:0] tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2,
  input  [1:0]  tdataVec_io_fromCsrTrigger_tdataVec_1_matchType,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_select,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_timing,
  input  [3:0]  tdataVec_io_fromCsrTrigger_tdataVec_1_action,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_chain,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_load,
  input  [63:0] tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2,
  input  [1:0]  tdataVec_io_fromCsrTrigger_tdataVec_2_matchType,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_select,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_timing,
  input  [3:0]  tdataVec_io_fromCsrTrigger_tdataVec_2_action,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_chain,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_load,
  input  [63:0] tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2,
  input  [1:0]  tdataVec_io_fromCsrTrigger_tdataVec_3_matchType,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_select,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_timing,
  input  [3:0]  tdataVec_io_fromCsrTrigger_tdataVec_3_action,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_chain,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_load,
  input  [63:0] tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2,
  input         tdataVec_io_fromCsrTrigger_tEnableVec_0,
  input         tdataVec_io_fromCsrTrigger_tEnableVec_1,
  input         tdataVec_io_fromCsrTrigger_tEnableVec_2,
  input         tdataVec_io_fromCsrTrigger_tEnableVec_3,
  input         tdataVec_io_fromCsrTrigger_debugMode,
  input         tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp,
  input  [49:0] tdataVec_io_fromLoadStore_vaddr,
  input         tdataVec_io_fromLoadStore_isVectorUnitStride,
  input  [15:0] tdataVec_io_fromLoadStore_mask,
  output [3:0]  tdataVec_io_toLoadStore_triggerAction,
  output [49:0] tdataVec_io_toLoadStore_triggerVaddr,
  output [15:0] tdataVec_io_toLoadStore_triggerMask,
  input         tdataVec_io_isPrf
);

  xs_MemTrigger_core u_core (
    .matchType            ({tdataVec_io_fromCsrTrigger_tdataVec_3_matchType,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_matchType,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_matchType,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_matchType}),
    .select               ({tdataVec_io_fromCsrTrigger_tdataVec_3_select,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_select,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_select,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_select}),
    .timing               ({tdataVec_io_fromCsrTrigger_tdataVec_3_timing,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_timing,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_timing,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_timing}),
    .action               ({tdataVec_io_fromCsrTrigger_tdataVec_3_action,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_action,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_action,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_action}),
    .chain                ({tdataVec_io_fromCsrTrigger_tdataVec_3_chain,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_chain,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_chain,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_chain}),
    .load                 ({tdataVec_io_fromCsrTrigger_tdataVec_3_load,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_load,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_load,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_load}),
    .tdata2               ({tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2}),
    .tEnable              ({tdataVec_io_fromCsrTrigger_tEnableVec_3,
                            tdataVec_io_fromCsrTrigger_tEnableVec_2,
                            tdataVec_io_fromCsrTrigger_tEnableVec_1,
                            tdataVec_io_fromCsrTrigger_tEnableVec_0}),
    .debugMode            (tdataVec_io_fromCsrTrigger_debugMode),
    .triggerCanRaiseBpExp (tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp),
    .vaddr                (tdataVec_io_fromLoadStore_vaddr),
    .isVectorUnitStride   (tdataVec_io_fromLoadStore_isVectorUnitStride),
    .mask                 (tdataVec_io_fromLoadStore_mask),
    .isPrf                (tdataVec_io_isPrf),
    .triggerAction        (tdataVec_io_toLoadStore_triggerAction),
    .triggerVaddr         (tdataVec_io_toLoadStore_triggerVaddr),
    .triggerMask          (tdataVec_io_toLoadStore_triggerMask)
  );

endmodule
