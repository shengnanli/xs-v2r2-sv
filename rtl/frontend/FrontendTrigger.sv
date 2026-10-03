// FrontendTrigger.sv —— 前端取指断点触发器（Sdtrig mcontrol 的 execute 触发，golden 模块 FrontendTrigger 的重写）
//
// 对应 Chisel: xiangshan.frontend.FrontendTrigger（PreDecode.scala）+ SdtrigExt（backend/fu/util/Trigger.scala）
// 配置（KunminghuV2Config）：TriggerNum=4，PredictWidth=16，VAddrBits=50。
//
// 位置：NewIFU 的 f3 级。IFU 把一个取指包里 16 个半字位置各自的 PC 送进来，本模块对每个位置
// 给出「触发动作」io_triggered[i]（4 位 TriggerAction），随指令一路带进后端，在提交时兑现。
//
// 机制：
//   1. CSR 侧经 tUpdate 逐个写 4 个触发器的配置（matchType / select / action / chain / tdata2），
//      tEnableVec 是 CSR 按当前特权级算好的使能，打一拍用。
//   2. 比较：16 个 PC 是「同一个包里连续的地址」，高位至多差 1。于是高 45 位只对 pc[0] 的
//      高位 highPC 和 highPC+1 各比一次（每个触发器 6 个 45 位比较器），每个位置只再比低 5 位，
//      再按 carry（该位置的 pc[5] 与 pc[0][5] 不同 = 高位进了 1）二选一。这是省面积的关键。
//   3. 链（chain）：触发器 j 的 chain=1 表示「我和 j+1 必须同时命中才算数」。所以
//        canFire[j] = 自己命中 & 自己不是链的中间节点(!chain[j])
//                     & 前一个若链到我(chain[j-1])则前一个也得命中、且两者 timing 相同。
//   4. 动作：有 canFire 且 action=1(进 debug) → DebugMode(1)；否则有 canFire 且 action=0 且
//      允许抛断点异常 → BreakpointExp(0)；否则 None(0xF)。
//
// 怪癖（照搬 golden，不要「修」）：
//   - timing 位：tUpdate 的 bundle 里 timing 恒 0（CSR 写入时 MControlData.Write 钉死为
//     false），firtool 把这个输入端口折掉了，但寄存器还在：更新时写 0，否则保持。它复位为 0，
//     所以实际恒 0，trigger2TimingSame 恒真——保留寄存器只为与 golden 状态点一一对应。
//   - matchType 只有 2 位（golden 端口如此）：0=EQ，2=GE，3=LT，1（NAPOT）不支持 → 永不命中。
//   - select=1（比较指令码而非地址）不支持 → 不命中；debugMode 下全部不命中。
//   - GE 的低位判据写成 lowEqual | lowGreaterEqual（Scala 里 lowPCGreater 用的就是 >=），
//     冗余但等价。
//   - 全部寄存器异步复位（posedge reset）。

package frontendtrigger_pkg;
  localparam int unsigned TRIGGER_NUM   = 4;
  localparam int unsigned PREDICT_WIDTH = 16;
  localparam int unsigned VADDR_BITS    = 50;
  // 低位宽度：log2(PredictWidth)+1 = 5 位（16 个半字 = 32 字节，一个包内低 5 位至多回绕一次）
  localparam int unsigned LOW_BITS      = 5;
  localparam int unsigned HIGH_BITS     = VADDR_BITS - LOW_BITS;

  // tdata1.match 的 2 位编码
  localparam logic [1:0] MATCH_EQ = 2'd0;
  localparam logic [1:0] MATCH_GE = 2'd2;
  localparam logic [1:0] MATCH_LT = 2'd3;

  // tdata1.action（配置侧）
  localparam logic [3:0] ACTION_BKPT_EXCPT = 4'd0;
  localparam logic [3:0] ACTION_DEBUG_MODE = 4'd1;

  // TriggerAction（输出侧）
  localparam logic [3:0] TRIG_BREAKPOINT_EXP = 4'h0;
  localparam logic [3:0] TRIG_DEBUG_MODE     = 4'h1;
  localparam logic [3:0] TRIG_NONE           = 4'hF;

  // 一个触发器的配置（MatchTriggerIO）
  typedef struct packed {
    logic [1:0]  matchType;
    logic        select;
    logic        timing;
    logic [3:0]  action;
    logic        chain;
    logic [63:0] tdata2;
  } tdata_t;
endpackage

module xs_FrontendTrigger_core
  import frontendtrigger_pkg::*;
(
  input  logic                                           clock,
  input  logic                                           reset,
  // CSR 写触发器配置
  input  logic                                           io_frontendTrigger_tUpdate_valid,
  input  logic [1:0]                                     io_frontendTrigger_tUpdate_bits_addr,
  input  logic [1:0]                                     io_frontendTrigger_tUpdate_bits_tdata_matchType,
  input  logic                                           io_frontendTrigger_tUpdate_bits_tdata_select,
  input  logic [3:0]                                     io_frontendTrigger_tUpdate_bits_tdata_action,
  input  logic                                           io_frontendTrigger_tUpdate_bits_tdata_chain,
  input  logic [63:0]                                    io_frontendTrigger_tUpdate_bits_tdata_tdata2,
  input  logic [TRIGGER_NUM-1:0]                         io_frontendTrigger_tEnableVec,
  input  logic                                           io_frontendTrigger_debugMode,
  input  logic                                           io_frontendTrigger_triggerCanRaiseBpExp,
  // 取指包里每个半字位置的 PC 与触发动作
  input  logic [PREDICT_WIDTH-1:0][VADDR_BITS-1:0]       io_pc,
  output logic [PREDICT_WIDTH-1:0][3:0]                  io_triggered
);

  // ===========================================================================
  // §1 配置寄存器：4 个触发器的 tdata + 打一拍的使能
  // ===========================================================================
  // 按字段分开存（每个触发器一组寄存器，与 golden 的 tdataVec_<j>_<field> 一一对应）；
  // 组合逻辑里再拼回结构体 tdata[j] 使用。
  logic [1:0]             tdata_matchType_q [TRIGGER_NUM];
  logic                   tdata_select_q    [TRIGGER_NUM];
  logic                   tdata_timing_q    [TRIGGER_NUM];
  logic [3:0]             tdata_action_q    [TRIGGER_NUM];
  logic                   tdata_chain_q     [TRIGGER_NUM];
  logic [63:0]            tdata_tdata2_q    [TRIGGER_NUM];
  logic [TRIGGER_NUM-1:0] enable_q;
  tdata_t                 tdata [TRIGGER_NUM];

  for (genvar j = 0; j < TRIGGER_NUM; j++) begin : g_tdata
    wire update_this = io_frontendTrigger_tUpdate_valid & (io_frontendTrigger_tUpdate_bits_addr == 2'(j));
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        tdata_matchType_q[j] <= '0;
        tdata_select_q[j]    <= 1'b0;
        tdata_timing_q[j]    <= 1'b0;
        tdata_action_q[j]    <= '0;
        tdata_chain_q[j]     <= 1'b0;
        tdata_tdata2_q[j]    <= '0;
      end
      else if (update_this) begin
        tdata_matchType_q[j] <= io_frontendTrigger_tUpdate_bits_tdata_matchType;
        tdata_select_q[j]    <= io_frontendTrigger_tUpdate_bits_tdata_select;
        tdata_timing_q[j]    <= 1'b0;   // 更新 bundle 里 timing 恒 0（见文件头怪癖）
        tdata_action_q[j]    <= io_frontendTrigger_tUpdate_bits_tdata_action;
        tdata_chain_q[j]     <= io_frontendTrigger_tUpdate_bits_tdata_chain;
        tdata_tdata2_q[j]    <= io_frontendTrigger_tUpdate_bits_tdata_tdata2;
      end
    end
    assign tdata[j] = '{matchType: tdata_matchType_q[j], select: tdata_select_q[j],
                        timing:    tdata_timing_q[j],    action: tdata_action_q[j],
                        chain:     tdata_chain_q[j],     tdata2: tdata_tdata2_q[j]};
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) enable_q <= '0;
    else       enable_q <= io_frontendTrigger_tEnableVec;
  end

  // ===========================================================================
  // §2 地址比较（TriggerCmpConsecutive）：hit[j][i] = 触发器 j 在位置 i 命中
  // ===========================================================================
  logic [PREDICT_WIDTH-1:0] hit [TRIGGER_NUM];

  // 高位只取 io_pc[0]；位置 i 的高位要么等于它（carry=0）、要么是它 +1（carry=1）
  wire [HIGH_BITS-1:0] high_pc  = io_pc[0][VADDR_BITS-1:LOW_BITS];
  wire [HIGH_BITS-1:0] high_pc1 = high_pc + 1'b1;

  logic [PREDICT_WIDTH-1:0] carry;
  for (genvar i = 0; i < PREDICT_WIDTH; i++) begin : g_carry
    assign carry[i] = io_pc[i][LOW_BITS] != io_pc[0][LOW_BITS];
  end

  for (genvar j = 0; j < TRIGGER_NUM; j++) begin : g_cmp
    wire [HIGH_BITS-1:0] high_tdata = tdata[j].tdata2[VADDR_BITS-1:LOW_BITS];
    wire [LOW_BITS-1:0]  low_tdata  = tdata[j].tdata2[LOW_BITS-1:0];

    // 每个触发器 6 个高位比较器，16 个位置共用
    wire high_eq   = high_pc  == high_tdata;
    wire high1_eq  = high_pc1 == high_tdata;
    wire high_gt   = high_pc  >  high_tdata;
    wire high1_gt  = high_pc1 >  high_tdata;
    wire high_lt   = high_pc  <  high_tdata;
    wire high1_lt  = high_pc1 <  high_tdata;

    // 这个触发器整体「可以命中」的前提：已使能、是地址触发、不在 debug 模式
    wire armed = enable_q[j] & ~tdata[j].select & ~io_frontendTrigger_debugMode;

    for (genvar i = 0; i < PREDICT_WIDTH; i++) begin : g_pos
      wire [LOW_BITS-1:0] low_pc = io_pc[i][LOW_BITS-1:0];
      wire low_eq = low_pc == low_tdata;
      wire low_ge = low_pc >= low_tdata;
      wire low_lt = low_pc <  low_tdata;

      // 按 carry 选「高位 = highPC」还是「高位 = highPC+1」那一组结果
      wire sel_high_eq = carry[i] ? high1_eq : high_eq;
      wire sel_high_gt = carry[i] ? high1_gt : high_gt;
      wire sel_high_lt = carry[i] ? high1_lt : high_lt;

      wire overall_eq = sel_high_eq & low_eq;
      wire overall_ge = sel_high_gt | (sel_high_eq & (low_eq | low_ge));
      wire overall_lt = sel_high_lt | (sel_high_eq & low_lt);

      logic match;
      always_comb begin
        unique case (tdata[j].matchType)
          MATCH_EQ: match = overall_eq;
          MATCH_GE: match = overall_ge;
          MATCH_LT: match = overall_lt;
          default:  match = 1'b0;      // NAPOT 等不支持的类型永不命中
        endcase
      end

      assign hit[j][i] = match & armed;
    end
  end

  // ===========================================================================
  // §3 链检查（TriggerCheckCanFire）+ 动作选择（triggerActionGen），逐位置
  // ===========================================================================
  for (genvar i = 0; i < PREDICT_WIDTH; i++) begin : g_fire
    logic [TRIGGER_NUM-1:0] can_fire;
    logic [TRIGGER_NUM-1:0] fire_debug;   // canFire 且动作 = 进 debug 模式
    logic [TRIGGER_NUM-1:0] fire_bkpt;    // canFire 且动作 = 断点异常

    for (genvar j = 0; j < TRIGGER_NUM; j++) begin : g_trig
      if (j == 0) begin : g_first
        // 0 号触发器前面没有人，链条件恒满足
        assign can_fire[j] = hit[j][i] & ~tdata[j].chain;
      end
      else begin : g_chained
        wire prev_chain  = tdata[j-1].chain;
        // 前一个链到我：它也得命中
        wire chain_ok    = ~prev_chain | hit[j-1][i];
        // 前一个链到我：我必须是链尾（自己不再往后链），且两者 timing 相同
        wire timing_same = tdata[j-1].timing == tdata[j].timing;
        wire timing_ok   = ~prev_chain | (~tdata[j].chain & timing_same);
        assign can_fire[j] = chain_ok & timing_ok & hit[j][i] & ~tdata[j].chain;
      end
      assign fire_debug[j] = can_fire[j] & (tdata[j].action == ACTION_DEBUG_MODE);
      assign fire_bkpt[j]  = can_fire[j] & (tdata[j].action == ACTION_BKPT_EXCPT);
    end

    // 进 debug 模式优先于断点异常；断点异常还要 CSR 允许（triggerCanRaiseBpExp）
    wire raise_bkpt = (|fire_bkpt) & io_frontendTrigger_triggerCanRaiseBpExp;
    assign io_triggered[i] = (|fire_debug) ? TRIG_DEBUG_MODE
                           : raise_bkpt    ? TRIG_BREAKPOINT_EXP
                           :                 TRIG_NONE;
  end

endmodule

// BEGIN GENERATED(wrapper)
// 自动生成：scripts/gen_newifu_lane.py —— 勿手改（端口表照抄 G1 golden，体里只做打包/拆包）
module FrontendTrigger (
  input         clock,
  input         reset,
  input         io_frontendTrigger_tUpdate_valid,
  input  [1:0]  io_frontendTrigger_tUpdate_bits_addr,
  input  [1:0]  io_frontendTrigger_tUpdate_bits_tdata_matchType,
  input         io_frontendTrigger_tUpdate_bits_tdata_select,
  input  [3:0]  io_frontendTrigger_tUpdate_bits_tdata_action,
  input         io_frontendTrigger_tUpdate_bits_tdata_chain,
  input  [63:0] io_frontendTrigger_tUpdate_bits_tdata_tdata2,
  input         io_frontendTrigger_tEnableVec_0,
  input         io_frontendTrigger_tEnableVec_1,
  input         io_frontendTrigger_tEnableVec_2,
  input         io_frontendTrigger_tEnableVec_3,
  input         io_frontendTrigger_debugMode,
  input         io_frontendTrigger_triggerCanRaiseBpExp,
  output [3:0]  io_triggered_0,
  output [3:0]  io_triggered_1,
  output [3:0]  io_triggered_2,
  output [3:0]  io_triggered_3,
  output [3:0]  io_triggered_4,
  output [3:0]  io_triggered_5,
  output [3:0]  io_triggered_6,
  output [3:0]  io_triggered_7,
  output [3:0]  io_triggered_8,
  output [3:0]  io_triggered_9,
  output [3:0]  io_triggered_10,
  output [3:0]  io_triggered_11,
  output [3:0]  io_triggered_12,
  output [3:0]  io_triggered_13,
  output [3:0]  io_triggered_14,
  output [3:0]  io_triggered_15,
  input  [49:0] io_pc_0,
  input  [49:0] io_pc_1,
  input  [49:0] io_pc_2,
  input  [49:0] io_pc_3,
  input  [49:0] io_pc_4,
  input  [49:0] io_pc_5,
  input  [49:0] io_pc_6,
  input  [49:0] io_pc_7,
  input  [49:0] io_pc_8,
  input  [49:0] io_pc_9,
  input  [49:0] io_pc_10,
  input  [49:0] io_pc_11,
  input  [49:0] io_pc_12,
  input  [49:0] io_pc_13,
  input  [49:0] io_pc_14,
  input  [49:0] io_pc_15
);
  wire [3:0] io_frontendTrigger_tEnableVec = {
    io_frontendTrigger_tEnableVec_3, io_frontendTrigger_tEnableVec_2, io_frontendTrigger_tEnableVec_1,
    io_frontendTrigger_tEnableVec_0};
  wire [15:0][3:0] io_triggered;
  wire [15:0][49:0] io_pc = {
    io_pc_15, io_pc_14, io_pc_13, io_pc_12, io_pc_11, io_pc_10, io_pc_9, io_pc_8, io_pc_7, io_pc_6, io_pc_5,
    io_pc_4, io_pc_3, io_pc_2, io_pc_1, io_pc_0};

  xs_FrontendTrigger_core u_core (
    .clock                                           (clock),
    .reset                                           (reset),
    .io_frontendTrigger_tUpdate_valid                (io_frontendTrigger_tUpdate_valid),
    .io_frontendTrigger_tUpdate_bits_addr            (io_frontendTrigger_tUpdate_bits_addr),
    .io_frontendTrigger_tUpdate_bits_tdata_matchType (io_frontendTrigger_tUpdate_bits_tdata_matchType),
    .io_frontendTrigger_tUpdate_bits_tdata_select    (io_frontendTrigger_tUpdate_bits_tdata_select),
    .io_frontendTrigger_tUpdate_bits_tdata_action    (io_frontendTrigger_tUpdate_bits_tdata_action),
    .io_frontendTrigger_tUpdate_bits_tdata_chain     (io_frontendTrigger_tUpdate_bits_tdata_chain),
    .io_frontendTrigger_tUpdate_bits_tdata_tdata2    (io_frontendTrigger_tUpdate_bits_tdata_tdata2),
    .io_frontendTrigger_tEnableVec                   (io_frontendTrigger_tEnableVec),
    .io_frontendTrigger_debugMode                    (io_frontendTrigger_debugMode),
    .io_frontendTrigger_triggerCanRaiseBpExp         (io_frontendTrigger_triggerCanRaiseBpExp),
    .io_triggered                                    (io_triggered),
    .io_pc                                           (io_pc)
  );

  assign io_triggered_0 = io_triggered[0];
  assign io_triggered_1 = io_triggered[1];
  assign io_triggered_2 = io_triggered[2];
  assign io_triggered_3 = io_triggered[3];
  assign io_triggered_4 = io_triggered[4];
  assign io_triggered_5 = io_triggered[5];
  assign io_triggered_6 = io_triggered[6];
  assign io_triggered_7 = io_triggered[7];
  assign io_triggered_8 = io_triggered[8];
  assign io_triggered_9 = io_triggered[9];
  assign io_triggered_10 = io_triggered[10];
  assign io_triggered_11 = io_triggered[11];
  assign io_triggered_12 = io_triggered[12];
  assign io_triggered_13 = io_triggered[13];
  assign io_triggered_14 = io_triggered[14];
  assign io_triggered_15 = io_triggered[15];
endmodule
// END GENERATED(wrapper)
