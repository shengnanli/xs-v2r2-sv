// PredChecker.sv —— 分支预测结果的预译码检查（golden 模块 PredChecker 的重写）
//
// 对应 Chisel: xiangshan.frontend.PredChecker（PreDecode.scala）。PredictWidth=16，VAddrBits=50。
//
// 位置：NewIFU 的 f3 级（第 1 拍，组合）与 wb 级（第 2 拍）。BPU 的预测是在「还没看到指令」时
// 做的；取回指令并预译码之后，这里拿真实的指令类型去核对预测，发现明显的错就让 IFU 提前
// 冲刷（predecode redirect），不必等后端执行。
//
// 输入是一个取指包：16 个半字位置，各有 pd（isRVC / brType / isRet）、pc、jumpOffset、
// instrValid（该位置是一条指令的起点）、instrRange（该位置在 BPU 给的取指范围内）；
// 以及 BPU 的预测：ftqOffset.valid（预测包内有跳转）/ .bits（跳转指令的位置）、target。
//
// 两步检查：
//   第 1 拍（stage1，组合输出，给 IBuffer 入队用）——「漏跳」类错误（remask fault）：
//     包里有一条无条件跳转（jal / jalr / ret）在预测的跳转位置之前（或 BPU 根本没预测跳），
//     那么它之后的指令都不该取。取最靠前的那条，把取指范围截到它为止 → fixedRange；
//     fixedTaken[i] = 位置 i 这条指令（修正后）确实会跳。
//   第 2 拍（stage2，所有量打一拍后给 FTQ 写回）——在 fixedRange 之内再查三种「错跳」：
//     notCFITaken  预测跳的那条不是控制流指令；
//     invalidTaken 预测跳的位置不是指令起点（落在一条 RVI 的后半）；
//     targetFault  预测跳的那条是 jal/br，但预测目标 != pc + 偏移（jalr 的目标预译码算不出，不查）。
//     并给出修正后的目标 fixedTarget：jal 漏跳或目标错 → 跳转目标；其余 → 顺序下一条。
//
// 怪癖（照搬 golden）：
//   - remask 类错误可以和别的错同时出现，其余几类两两互斥——因为都只在 takenIdx 一个位置成立，
//     且都以 fixedRange 为前提（先截断再查）。faultType 用优先级 MuxCase 编码。
//   - seqTarget 对「不是指令起点」的位置按 +2 算（invalidTaken 时从该半字的下一个半字重取）。
//   - 无 reset 端口：stage2 寄存器全部不复位，只在 fire_in 时更新。
//   - pdsNext 只留下 brType（isRVC / isRet 在第 2 拍没人用，firtool 已消掉）。

package predchecker_pkg;
  localparam int unsigned PW         = 16;   // PredictWidth
  localparam int unsigned VADDR_BITS = 50;
  localparam int unsigned XLEN       = 64;

  // PreDecodeInfo.brType
  localparam logic [1:0] BR_NOT_CFI = 2'd0;
  localparam logic [1:0] BR_BRANCH  = 2'd1;
  localparam logic [1:0] BR_JAL     = 2'd2;
  localparam logic [1:0] BR_JALR    = 2'd3;

  // FaultType
  localparam logic [2:0] FAULT_NONE          = 3'b000;
  localparam logic [2:0] FAULT_JAL           = 3'b001;
  localparam logic [2:0] FAULT_RET           = 3'b010;
  localparam logic [2:0] FAULT_TARGET        = 3'b011;
  localparam logic [2:0] FAULT_NOT_CFI       = 3'b100;
  localparam logic [2:0] FAULT_INVALID_TAKEN = 3'b101;
  localparam logic [2:0] FAULT_JALR          = 3'b110;
endpackage

module xs_PredChecker_core
  import predchecker_pkg::*;
(
  input  logic                              clock,
  // BPU 的预测
  input  logic                              io_in_ftqOffset_valid,   // 预测包内有跳转
  input  logic [3:0]                        io_in_ftqOffset_bits,    // 跳转指令的位置
  input  logic [VADDR_BITS-1:0]             io_in_target,
  // 取指包（预译码结果）
  input  logic [PW-1:0][XLEN-1:0]           io_in_jumpOffset,
  input  logic [PW-1:0]                     io_in_instrRange,
  input  logic [PW-1:0]                     io_in_instrValid,
  input  logic [PW-1:0]                     io_in_pds_isRVC,
  input  logic [PW-1:0][1:0]                io_in_pds_brType,
  input  logic [PW-1:0]                     io_in_pds_isRet,
  input  logic [PW-1:0][VADDR_BITS-1:0]     io_in_pc,
  input  logic                              io_in_fire_in,           // f3 握手：stage2 寄存器使能
  // stage1（组合）
  output logic [PW-1:0]                     io_out_stage1Out_fixedRange,
  output logic [PW-1:0]                     io_out_stage1Out_fixedTaken,
  // stage2（打一拍）
  output logic [PW-1:0][VADDR_BITS-1:0]     io_out_stage2Out_fixedTarget,
  output logic [PW-1:0][VADDR_BITS-1:0]     io_out_stage2Out_jalTarget,
  output logic [PW-1:0]                     io_out_stage2Out_fixedMissPred,
  output logic [PW-1:0][2:0]                io_out_stage2Out_faultType_value
);

  // 与 Scala 同名的别名
  wire                  predTaken  = io_in_ftqOffset_valid;
  wire [3:0]            takenIdx   = io_in_ftqOffset_bits;
  wire [VADDR_BITS-1:0] predTarget = io_in_target;

  // ===========================================================================
  // §1 stage1：漏跳检查（remask fault）与取指范围修正
  // ===========================================================================
  logic [PW-1:0] is_jal, is_jalr, is_br, is_not_cfi;
  logic [PW-1:0] jal_fault, jalr_fault, ret_fault, remask_fault;

  for (genvar i = 0; i < PW; i++) begin : g_remask
    assign is_jal[i]     = io_in_pds_brType[i] == BR_JAL;
    assign is_jalr[i]    = io_in_pds_brType[i] == BR_JALR;
    assign is_br[i]      = io_in_pds_brType[i] == BR_BRANCH;
    assign is_not_cfi[i] = io_in_pds_brType[i] == BR_NOT_CFI;

    // 这条指令在「预测的跳转位置」之前（或压根没预测跳）：它若是无条件跳转，就是漏跳
    wire before_pred_taken = ~predTaken | (takenIdx > 4'(i));
    wire in_packet         = io_in_instrRange[i] & io_in_instrValid[i];

    assign jal_fault[i]    = is_jal[i]                 & in_packet & before_pred_taken;
    assign jalr_fault[i]   = is_jalr[i] & ~io_in_pds_isRet[i] & in_packet & before_pred_taken;
    assign ret_fault[i]    = io_in_pds_isRet[i]               & in_packet & before_pred_taken;
    assign remask_fault[i] = jal_fault[i] | jalr_fault[i] | ret_fault[i];
  end

  // 截断掩码：有漏跳时只保留「最靠前那条漏跳指令及其之前」的位置
  // （Scala: Fill(PW,!needRemask) | (全 1 >> ~remaskIdx)，remaskIdx = 最低位优先编码）
  logic [PW-1:0] keep_mask;
  always_comb begin
    logic seen;   // 更低的位置上已经出现过漏跳
    seen = 1'b0;
    for (int i = 0; i < PW; i++) begin
      keep_mask[i] = ~seen;
      seen         = seen | remask_fault[i];
    end
  end

  wire [PW-1:0] fixed_range = io_in_instrRange & keep_mask;
  assign io_out_stage1Out_fixedRange = fixed_range;

  // 修正后「会跳」：无条件跳转一定跳；否则是 BPU 预测跳的那条且确实是控制流指令
  wire [PW-1:0] at_taken_idx;
  for (genvar i = 0; i < PW; i++) begin : g_taken
    assign at_taken_idx[i]  = (takenIdx == 4'(i)) & predTaken;
    assign io_out_stage1Out_fixedTaken[i] = io_in_instrValid[i] & fixed_range[i]
                            & (io_in_pds_isRet[i] | is_jal[i] | is_jalr[i] | (at_taken_idx[i] & ~is_not_cfi[i]));
  end

  // 错跳检查里可以在 stage1 就算好的两类
  wire [PW-1:0] not_cfi_taken = fixed_range &  io_in_instrValid & at_taken_idx & is_not_cfi;
  wire [PW-1:0] invalid_taken = fixed_range & ~io_in_instrValid & at_taken_idx;

  // 两种候选目标：跳转目标 io_in_pc+offset；顺序目标 io_in_pc+2/4
  logic [PW-1:0][VADDR_BITS-1:0] jump_target, seq_target;
  for (genvar i = 0; i < PW; i++) begin : g_target
    wire two_bytes = io_in_pds_isRVC[i] | ~io_in_instrValid[i];
    assign jump_target[i] = io_in_pc[i] + io_in_jumpOffset[i][VADDR_BITS-1:0];
    assign seq_target[i]  = io_in_pc[i] + (two_bytes ? VADDR_BITS'(2) : VADDR_BITS'(4));
  end

  // ===========================================================================
  // §2 stage1 → stage2 流水寄存器（RegEnable(io_in_fire_in)，全部不复位）
  // ===========================================================================
  // 按位置的量用 unpacked 数组（每个位置一组寄存器，与 golden 的 xxxNext_<i> 一一对应）
  logic [PW-1:0]         fixedRange_q;
  logic [3:0]            takenIdx_q;
  logic                  predTaken_q;
  logic [VADDR_BITS-1:0] predTarget_q;
  logic                  instrValid_q   [PW];
  logic [VADDR_BITS-1:0] jumpTarget_q   [PW];
  logic [VADDR_BITS-1:0] seqTarget_q    [PW];
  logic [1:0]            brType_q       [PW];
  logic                  jalFault_q     [PW];
  logic                  jalrFault_q    [PW];
  logic                  retFault_q     [PW];
  logic                  notCfiTaken_q  [PW];
  logic                  invalidTaken_q [PW];

  always_ff @(posedge clock) begin
    if (io_in_fire_in) begin
      fixedRange_q <= fixed_range;
      takenIdx_q   <= takenIdx;
      predTaken_q  <= predTaken;
      predTarget_q <= predTarget;
      for (int i = 0; i < PW; i++) begin
        instrValid_q[i]   <= io_in_instrValid[i];
        jumpTarget_q[i]   <= jump_target[i];
        seqTarget_q[i]    <= seq_target[i];
        brType_q[i]       <= io_in_pds_brType[i];
        jalFault_q[i]     <= jal_fault[i];
        jalrFault_q[i]    <= jalr_fault[i];
        retFault_q[i]     <= ret_fault[i];
        notCfiTaken_q[i]  <= not_cfi_taken[i];
        invalidTaken_q[i] <= invalid_taken[i];
      end
    end
  end

  // ===========================================================================
  // §3 stage2：目标检查与结果编码（给 FTQ 写回）
  // ===========================================================================
  for (genvar i = 0; i < PW; i++) begin : g_s2
    // 预测跳的这条是 jal / br，目标可由预译码算出，与预测目标不符
    wire direct_cfi   = (brType_q[i] == BR_JAL) | (brType_q[i] == BR_BRANCH);
    wire target_fault = fixedRange_q[i] & instrValid_q[i] & direct_cfi
                      & (takenIdx_q == 4'(i)) & predTaken_q
                      & (predTarget_q != jumpTarget_q[i]);

    always_comb begin
      if      (jalFault_q[i])     io_out_stage2Out_faultType_value[i] = FAULT_JAL;
      else if (jalrFault_q[i])    io_out_stage2Out_faultType_value[i] = FAULT_JALR;
      else if (retFault_q[i])     io_out_stage2Out_faultType_value[i] = FAULT_RET;
      else if (target_fault)      io_out_stage2Out_faultType_value[i] = FAULT_TARGET;
      else if (notCfiTaken_q[i])  io_out_stage2Out_faultType_value[i] = FAULT_NOT_CFI;
      else if (invalidTaken_q[i]) io_out_stage2Out_faultType_value[i] = FAULT_INVALID_TAKEN;
      else                        io_out_stage2Out_faultType_value[i] = FAULT_NONE;
    end

    assign io_out_stage2Out_fixedMissPred[i] = jalFault_q[i] | jalrFault_q[i] | retFault_q[i]
                               | notCfiTaken_q[i] | invalidTaken_q[i] | target_fault;
    // jal 漏跳 / 目标错：正确目标就是 io_in_pc+offset；其它错误一律从顺序下一条重取
    assign io_out_stage2Out_fixedTarget[i]   = (jalFault_q[i] | target_fault) ? jumpTarget_q[i] : seqTarget_q[i];
    assign io_out_stage2Out_jalTarget[i]     = jumpTarget_q[i];
  end

endmodule

// BEGIN GENERATED(wrapper)
// 自动生成：scripts/gen_newifu_lane.py —— 勿手改（端口表照抄 G1 golden，体里只做打包/拆包）
module PredChecker (
  input         clock,
  input         io_in_ftqOffset_valid,
  input  [3:0]  io_in_ftqOffset_bits,
  input  [63:0] io_in_jumpOffset_0,
  input  [63:0] io_in_jumpOffset_1,
  input  [63:0] io_in_jumpOffset_2,
  input  [63:0] io_in_jumpOffset_3,
  input  [63:0] io_in_jumpOffset_4,
  input  [63:0] io_in_jumpOffset_5,
  input  [63:0] io_in_jumpOffset_6,
  input  [63:0] io_in_jumpOffset_7,
  input  [63:0] io_in_jumpOffset_8,
  input  [63:0] io_in_jumpOffset_9,
  input  [63:0] io_in_jumpOffset_10,
  input  [63:0] io_in_jumpOffset_11,
  input  [63:0] io_in_jumpOffset_12,
  input  [63:0] io_in_jumpOffset_13,
  input  [63:0] io_in_jumpOffset_14,
  input  [63:0] io_in_jumpOffset_15,
  input  [49:0] io_in_target,
  input         io_in_instrRange_0,
  input         io_in_instrRange_1,
  input         io_in_instrRange_2,
  input         io_in_instrRange_3,
  input         io_in_instrRange_4,
  input         io_in_instrRange_5,
  input         io_in_instrRange_6,
  input         io_in_instrRange_7,
  input         io_in_instrRange_8,
  input         io_in_instrRange_9,
  input         io_in_instrRange_10,
  input         io_in_instrRange_11,
  input         io_in_instrRange_12,
  input         io_in_instrRange_13,
  input         io_in_instrRange_14,
  input         io_in_instrRange_15,
  input         io_in_instrValid_0,
  input         io_in_instrValid_1,
  input         io_in_instrValid_2,
  input         io_in_instrValid_3,
  input         io_in_instrValid_4,
  input         io_in_instrValid_5,
  input         io_in_instrValid_6,
  input         io_in_instrValid_7,
  input         io_in_instrValid_8,
  input         io_in_instrValid_9,
  input         io_in_instrValid_10,
  input         io_in_instrValid_11,
  input         io_in_instrValid_12,
  input         io_in_instrValid_13,
  input         io_in_instrValid_14,
  input         io_in_instrValid_15,
  input         io_in_pds_0_isRVC,
  input  [1:0]  io_in_pds_0_brType,
  input         io_in_pds_0_isRet,
  input         io_in_pds_1_isRVC,
  input  [1:0]  io_in_pds_1_brType,
  input         io_in_pds_1_isRet,
  input         io_in_pds_2_isRVC,
  input  [1:0]  io_in_pds_2_brType,
  input         io_in_pds_2_isRet,
  input         io_in_pds_3_isRVC,
  input  [1:0]  io_in_pds_3_brType,
  input         io_in_pds_3_isRet,
  input         io_in_pds_4_isRVC,
  input  [1:0]  io_in_pds_4_brType,
  input         io_in_pds_4_isRet,
  input         io_in_pds_5_isRVC,
  input  [1:0]  io_in_pds_5_brType,
  input         io_in_pds_5_isRet,
  input         io_in_pds_6_isRVC,
  input  [1:0]  io_in_pds_6_brType,
  input         io_in_pds_6_isRet,
  input         io_in_pds_7_isRVC,
  input  [1:0]  io_in_pds_7_brType,
  input         io_in_pds_7_isRet,
  input         io_in_pds_8_isRVC,
  input  [1:0]  io_in_pds_8_brType,
  input         io_in_pds_8_isRet,
  input         io_in_pds_9_isRVC,
  input  [1:0]  io_in_pds_9_brType,
  input         io_in_pds_9_isRet,
  input         io_in_pds_10_isRVC,
  input  [1:0]  io_in_pds_10_brType,
  input         io_in_pds_10_isRet,
  input         io_in_pds_11_isRVC,
  input  [1:0]  io_in_pds_11_brType,
  input         io_in_pds_11_isRet,
  input         io_in_pds_12_isRVC,
  input  [1:0]  io_in_pds_12_brType,
  input         io_in_pds_12_isRet,
  input         io_in_pds_13_isRVC,
  input  [1:0]  io_in_pds_13_brType,
  input         io_in_pds_13_isRet,
  input         io_in_pds_14_isRVC,
  input  [1:0]  io_in_pds_14_brType,
  input         io_in_pds_14_isRet,
  input         io_in_pds_15_isRVC,
  input  [1:0]  io_in_pds_15_brType,
  input         io_in_pds_15_isRet,
  input  [49:0] io_in_pc_0,
  input  [49:0] io_in_pc_1,
  input  [49:0] io_in_pc_2,
  input  [49:0] io_in_pc_3,
  input  [49:0] io_in_pc_4,
  input  [49:0] io_in_pc_5,
  input  [49:0] io_in_pc_6,
  input  [49:0] io_in_pc_7,
  input  [49:0] io_in_pc_8,
  input  [49:0] io_in_pc_9,
  input  [49:0] io_in_pc_10,
  input  [49:0] io_in_pc_11,
  input  [49:0] io_in_pc_12,
  input  [49:0] io_in_pc_13,
  input  [49:0] io_in_pc_14,
  input  [49:0] io_in_pc_15,
  input         io_in_fire_in,
  output        io_out_stage1Out_fixedRange_0,
  output        io_out_stage1Out_fixedRange_1,
  output        io_out_stage1Out_fixedRange_2,
  output        io_out_stage1Out_fixedRange_3,
  output        io_out_stage1Out_fixedRange_4,
  output        io_out_stage1Out_fixedRange_5,
  output        io_out_stage1Out_fixedRange_6,
  output        io_out_stage1Out_fixedRange_7,
  output        io_out_stage1Out_fixedRange_8,
  output        io_out_stage1Out_fixedRange_9,
  output        io_out_stage1Out_fixedRange_10,
  output        io_out_stage1Out_fixedRange_11,
  output        io_out_stage1Out_fixedRange_12,
  output        io_out_stage1Out_fixedRange_13,
  output        io_out_stage1Out_fixedRange_14,
  output        io_out_stage1Out_fixedRange_15,
  output        io_out_stage1Out_fixedTaken_0,
  output        io_out_stage1Out_fixedTaken_1,
  output        io_out_stage1Out_fixedTaken_2,
  output        io_out_stage1Out_fixedTaken_3,
  output        io_out_stage1Out_fixedTaken_4,
  output        io_out_stage1Out_fixedTaken_5,
  output        io_out_stage1Out_fixedTaken_6,
  output        io_out_stage1Out_fixedTaken_7,
  output        io_out_stage1Out_fixedTaken_8,
  output        io_out_stage1Out_fixedTaken_9,
  output        io_out_stage1Out_fixedTaken_10,
  output        io_out_stage1Out_fixedTaken_11,
  output        io_out_stage1Out_fixedTaken_12,
  output        io_out_stage1Out_fixedTaken_13,
  output        io_out_stage1Out_fixedTaken_14,
  output        io_out_stage1Out_fixedTaken_15,
  output [49:0] io_out_stage2Out_fixedTarget_0,
  output [49:0] io_out_stage2Out_fixedTarget_1,
  output [49:0] io_out_stage2Out_fixedTarget_2,
  output [49:0] io_out_stage2Out_fixedTarget_3,
  output [49:0] io_out_stage2Out_fixedTarget_4,
  output [49:0] io_out_stage2Out_fixedTarget_5,
  output [49:0] io_out_stage2Out_fixedTarget_6,
  output [49:0] io_out_stage2Out_fixedTarget_7,
  output [49:0] io_out_stage2Out_fixedTarget_8,
  output [49:0] io_out_stage2Out_fixedTarget_9,
  output [49:0] io_out_stage2Out_fixedTarget_10,
  output [49:0] io_out_stage2Out_fixedTarget_11,
  output [49:0] io_out_stage2Out_fixedTarget_12,
  output [49:0] io_out_stage2Out_fixedTarget_13,
  output [49:0] io_out_stage2Out_fixedTarget_14,
  output [49:0] io_out_stage2Out_fixedTarget_15,
  output [49:0] io_out_stage2Out_jalTarget_0,
  output [49:0] io_out_stage2Out_jalTarget_1,
  output [49:0] io_out_stage2Out_jalTarget_2,
  output [49:0] io_out_stage2Out_jalTarget_3,
  output [49:0] io_out_stage2Out_jalTarget_4,
  output [49:0] io_out_stage2Out_jalTarget_5,
  output [49:0] io_out_stage2Out_jalTarget_6,
  output [49:0] io_out_stage2Out_jalTarget_7,
  output [49:0] io_out_stage2Out_jalTarget_8,
  output [49:0] io_out_stage2Out_jalTarget_9,
  output [49:0] io_out_stage2Out_jalTarget_10,
  output [49:0] io_out_stage2Out_jalTarget_11,
  output [49:0] io_out_stage2Out_jalTarget_12,
  output [49:0] io_out_stage2Out_jalTarget_13,
  output [49:0] io_out_stage2Out_jalTarget_14,
  output [49:0] io_out_stage2Out_jalTarget_15,
  output        io_out_stage2Out_fixedMissPred_0,
  output        io_out_stage2Out_fixedMissPred_1,
  output        io_out_stage2Out_fixedMissPred_2,
  output        io_out_stage2Out_fixedMissPred_3,
  output        io_out_stage2Out_fixedMissPred_4,
  output        io_out_stage2Out_fixedMissPred_5,
  output        io_out_stage2Out_fixedMissPred_6,
  output        io_out_stage2Out_fixedMissPred_7,
  output        io_out_stage2Out_fixedMissPred_8,
  output        io_out_stage2Out_fixedMissPred_9,
  output        io_out_stage2Out_fixedMissPred_10,
  output        io_out_stage2Out_fixedMissPred_11,
  output        io_out_stage2Out_fixedMissPred_12,
  output        io_out_stage2Out_fixedMissPred_13,
  output        io_out_stage2Out_fixedMissPred_14,
  output        io_out_stage2Out_fixedMissPred_15,
  output [2:0]  io_out_stage2Out_faultType_0_value,
  output [2:0]  io_out_stage2Out_faultType_1_value,
  output [2:0]  io_out_stage2Out_faultType_2_value,
  output [2:0]  io_out_stage2Out_faultType_3_value,
  output [2:0]  io_out_stage2Out_faultType_4_value,
  output [2:0]  io_out_stage2Out_faultType_5_value,
  output [2:0]  io_out_stage2Out_faultType_6_value,
  output [2:0]  io_out_stage2Out_faultType_7_value,
  output [2:0]  io_out_stage2Out_faultType_8_value,
  output [2:0]  io_out_stage2Out_faultType_9_value,
  output [2:0]  io_out_stage2Out_faultType_10_value,
  output [2:0]  io_out_stage2Out_faultType_11_value,
  output [2:0]  io_out_stage2Out_faultType_12_value,
  output [2:0]  io_out_stage2Out_faultType_13_value,
  output [2:0]  io_out_stage2Out_faultType_14_value,
  output [2:0]  io_out_stage2Out_faultType_15_value
);
  wire [15:0][63:0] io_in_jumpOffset = {
    io_in_jumpOffset_15, io_in_jumpOffset_14, io_in_jumpOffset_13, io_in_jumpOffset_12, io_in_jumpOffset_11,
    io_in_jumpOffset_10, io_in_jumpOffset_9, io_in_jumpOffset_8, io_in_jumpOffset_7, io_in_jumpOffset_6,
    io_in_jumpOffset_5, io_in_jumpOffset_4, io_in_jumpOffset_3, io_in_jumpOffset_2, io_in_jumpOffset_1,
    io_in_jumpOffset_0};
  wire [15:0] io_in_instrRange = {
    io_in_instrRange_15, io_in_instrRange_14, io_in_instrRange_13, io_in_instrRange_12, io_in_instrRange_11,
    io_in_instrRange_10, io_in_instrRange_9, io_in_instrRange_8, io_in_instrRange_7, io_in_instrRange_6,
    io_in_instrRange_5, io_in_instrRange_4, io_in_instrRange_3, io_in_instrRange_2, io_in_instrRange_1,
    io_in_instrRange_0};
  wire [15:0] io_in_instrValid = {
    io_in_instrValid_15, io_in_instrValid_14, io_in_instrValid_13, io_in_instrValid_12, io_in_instrValid_11,
    io_in_instrValid_10, io_in_instrValid_9, io_in_instrValid_8, io_in_instrValid_7, io_in_instrValid_6,
    io_in_instrValid_5, io_in_instrValid_4, io_in_instrValid_3, io_in_instrValid_2, io_in_instrValid_1,
    io_in_instrValid_0};
  wire [15:0] io_in_pds_isRVC = {
    io_in_pds_15_isRVC, io_in_pds_14_isRVC, io_in_pds_13_isRVC, io_in_pds_12_isRVC, io_in_pds_11_isRVC,
    io_in_pds_10_isRVC, io_in_pds_9_isRVC, io_in_pds_8_isRVC, io_in_pds_7_isRVC, io_in_pds_6_isRVC,
    io_in_pds_5_isRVC, io_in_pds_4_isRVC, io_in_pds_3_isRVC, io_in_pds_2_isRVC, io_in_pds_1_isRVC,
    io_in_pds_0_isRVC};
  wire [15:0][1:0] io_in_pds_brType = {
    io_in_pds_15_brType, io_in_pds_14_brType, io_in_pds_13_brType, io_in_pds_12_brType, io_in_pds_11_brType,
    io_in_pds_10_brType, io_in_pds_9_brType, io_in_pds_8_brType, io_in_pds_7_brType, io_in_pds_6_brType,
    io_in_pds_5_brType, io_in_pds_4_brType, io_in_pds_3_brType, io_in_pds_2_brType, io_in_pds_1_brType,
    io_in_pds_0_brType};
  wire [15:0] io_in_pds_isRet = {
    io_in_pds_15_isRet, io_in_pds_14_isRet, io_in_pds_13_isRet, io_in_pds_12_isRet, io_in_pds_11_isRet,
    io_in_pds_10_isRet, io_in_pds_9_isRet, io_in_pds_8_isRet, io_in_pds_7_isRet, io_in_pds_6_isRet,
    io_in_pds_5_isRet, io_in_pds_4_isRet, io_in_pds_3_isRet, io_in_pds_2_isRet, io_in_pds_1_isRet,
    io_in_pds_0_isRet};
  wire [15:0][49:0] io_in_pc = {
    io_in_pc_15, io_in_pc_14, io_in_pc_13, io_in_pc_12, io_in_pc_11, io_in_pc_10, io_in_pc_9, io_in_pc_8,
    io_in_pc_7, io_in_pc_6, io_in_pc_5, io_in_pc_4, io_in_pc_3, io_in_pc_2, io_in_pc_1, io_in_pc_0};
  wire [15:0] io_out_stage1Out_fixedRange;
  wire [15:0] io_out_stage1Out_fixedTaken;
  wire [15:0][49:0] io_out_stage2Out_fixedTarget;
  wire [15:0][49:0] io_out_stage2Out_jalTarget;
  wire [15:0] io_out_stage2Out_fixedMissPred;
  wire [15:0][2:0] io_out_stage2Out_faultType_value;

  xs_PredChecker_core u_core (
    .clock                            (clock),
    .io_in_ftqOffset_valid            (io_in_ftqOffset_valid),
    .io_in_ftqOffset_bits             (io_in_ftqOffset_bits),
    .io_in_jumpOffset                 (io_in_jumpOffset),
    .io_in_target                     (io_in_target),
    .io_in_instrRange                 (io_in_instrRange),
    .io_in_instrValid                 (io_in_instrValid),
    .io_in_pds_isRVC                  (io_in_pds_isRVC),
    .io_in_pds_brType                 (io_in_pds_brType),
    .io_in_pds_isRet                  (io_in_pds_isRet),
    .io_in_pc                         (io_in_pc),
    .io_in_fire_in                    (io_in_fire_in),
    .io_out_stage1Out_fixedRange      (io_out_stage1Out_fixedRange),
    .io_out_stage1Out_fixedTaken      (io_out_stage1Out_fixedTaken),
    .io_out_stage2Out_fixedTarget     (io_out_stage2Out_fixedTarget),
    .io_out_stage2Out_jalTarget       (io_out_stage2Out_jalTarget),
    .io_out_stage2Out_fixedMissPred   (io_out_stage2Out_fixedMissPred),
    .io_out_stage2Out_faultType_value (io_out_stage2Out_faultType_value)
  );

  assign io_out_stage1Out_fixedRange_0 = io_out_stage1Out_fixedRange[0];
  assign io_out_stage1Out_fixedRange_1 = io_out_stage1Out_fixedRange[1];
  assign io_out_stage1Out_fixedRange_2 = io_out_stage1Out_fixedRange[2];
  assign io_out_stage1Out_fixedRange_3 = io_out_stage1Out_fixedRange[3];
  assign io_out_stage1Out_fixedRange_4 = io_out_stage1Out_fixedRange[4];
  assign io_out_stage1Out_fixedRange_5 = io_out_stage1Out_fixedRange[5];
  assign io_out_stage1Out_fixedRange_6 = io_out_stage1Out_fixedRange[6];
  assign io_out_stage1Out_fixedRange_7 = io_out_stage1Out_fixedRange[7];
  assign io_out_stage1Out_fixedRange_8 = io_out_stage1Out_fixedRange[8];
  assign io_out_stage1Out_fixedRange_9 = io_out_stage1Out_fixedRange[9];
  assign io_out_stage1Out_fixedRange_10 = io_out_stage1Out_fixedRange[10];
  assign io_out_stage1Out_fixedRange_11 = io_out_stage1Out_fixedRange[11];
  assign io_out_stage1Out_fixedRange_12 = io_out_stage1Out_fixedRange[12];
  assign io_out_stage1Out_fixedRange_13 = io_out_stage1Out_fixedRange[13];
  assign io_out_stage1Out_fixedRange_14 = io_out_stage1Out_fixedRange[14];
  assign io_out_stage1Out_fixedRange_15 = io_out_stage1Out_fixedRange[15];
  assign io_out_stage1Out_fixedTaken_0 = io_out_stage1Out_fixedTaken[0];
  assign io_out_stage1Out_fixedTaken_1 = io_out_stage1Out_fixedTaken[1];
  assign io_out_stage1Out_fixedTaken_2 = io_out_stage1Out_fixedTaken[2];
  assign io_out_stage1Out_fixedTaken_3 = io_out_stage1Out_fixedTaken[3];
  assign io_out_stage1Out_fixedTaken_4 = io_out_stage1Out_fixedTaken[4];
  assign io_out_stage1Out_fixedTaken_5 = io_out_stage1Out_fixedTaken[5];
  assign io_out_stage1Out_fixedTaken_6 = io_out_stage1Out_fixedTaken[6];
  assign io_out_stage1Out_fixedTaken_7 = io_out_stage1Out_fixedTaken[7];
  assign io_out_stage1Out_fixedTaken_8 = io_out_stage1Out_fixedTaken[8];
  assign io_out_stage1Out_fixedTaken_9 = io_out_stage1Out_fixedTaken[9];
  assign io_out_stage1Out_fixedTaken_10 = io_out_stage1Out_fixedTaken[10];
  assign io_out_stage1Out_fixedTaken_11 = io_out_stage1Out_fixedTaken[11];
  assign io_out_stage1Out_fixedTaken_12 = io_out_stage1Out_fixedTaken[12];
  assign io_out_stage1Out_fixedTaken_13 = io_out_stage1Out_fixedTaken[13];
  assign io_out_stage1Out_fixedTaken_14 = io_out_stage1Out_fixedTaken[14];
  assign io_out_stage1Out_fixedTaken_15 = io_out_stage1Out_fixedTaken[15];
  assign io_out_stage2Out_fixedTarget_0 = io_out_stage2Out_fixedTarget[0];
  assign io_out_stage2Out_fixedTarget_1 = io_out_stage2Out_fixedTarget[1];
  assign io_out_stage2Out_fixedTarget_2 = io_out_stage2Out_fixedTarget[2];
  assign io_out_stage2Out_fixedTarget_3 = io_out_stage2Out_fixedTarget[3];
  assign io_out_stage2Out_fixedTarget_4 = io_out_stage2Out_fixedTarget[4];
  assign io_out_stage2Out_fixedTarget_5 = io_out_stage2Out_fixedTarget[5];
  assign io_out_stage2Out_fixedTarget_6 = io_out_stage2Out_fixedTarget[6];
  assign io_out_stage2Out_fixedTarget_7 = io_out_stage2Out_fixedTarget[7];
  assign io_out_stage2Out_fixedTarget_8 = io_out_stage2Out_fixedTarget[8];
  assign io_out_stage2Out_fixedTarget_9 = io_out_stage2Out_fixedTarget[9];
  assign io_out_stage2Out_fixedTarget_10 = io_out_stage2Out_fixedTarget[10];
  assign io_out_stage2Out_fixedTarget_11 = io_out_stage2Out_fixedTarget[11];
  assign io_out_stage2Out_fixedTarget_12 = io_out_stage2Out_fixedTarget[12];
  assign io_out_stage2Out_fixedTarget_13 = io_out_stage2Out_fixedTarget[13];
  assign io_out_stage2Out_fixedTarget_14 = io_out_stage2Out_fixedTarget[14];
  assign io_out_stage2Out_fixedTarget_15 = io_out_stage2Out_fixedTarget[15];
  assign io_out_stage2Out_jalTarget_0 = io_out_stage2Out_jalTarget[0];
  assign io_out_stage2Out_jalTarget_1 = io_out_stage2Out_jalTarget[1];
  assign io_out_stage2Out_jalTarget_2 = io_out_stage2Out_jalTarget[2];
  assign io_out_stage2Out_jalTarget_3 = io_out_stage2Out_jalTarget[3];
  assign io_out_stage2Out_jalTarget_4 = io_out_stage2Out_jalTarget[4];
  assign io_out_stage2Out_jalTarget_5 = io_out_stage2Out_jalTarget[5];
  assign io_out_stage2Out_jalTarget_6 = io_out_stage2Out_jalTarget[6];
  assign io_out_stage2Out_jalTarget_7 = io_out_stage2Out_jalTarget[7];
  assign io_out_stage2Out_jalTarget_8 = io_out_stage2Out_jalTarget[8];
  assign io_out_stage2Out_jalTarget_9 = io_out_stage2Out_jalTarget[9];
  assign io_out_stage2Out_jalTarget_10 = io_out_stage2Out_jalTarget[10];
  assign io_out_stage2Out_jalTarget_11 = io_out_stage2Out_jalTarget[11];
  assign io_out_stage2Out_jalTarget_12 = io_out_stage2Out_jalTarget[12];
  assign io_out_stage2Out_jalTarget_13 = io_out_stage2Out_jalTarget[13];
  assign io_out_stage2Out_jalTarget_14 = io_out_stage2Out_jalTarget[14];
  assign io_out_stage2Out_jalTarget_15 = io_out_stage2Out_jalTarget[15];
  assign io_out_stage2Out_fixedMissPred_0 = io_out_stage2Out_fixedMissPred[0];
  assign io_out_stage2Out_fixedMissPred_1 = io_out_stage2Out_fixedMissPred[1];
  assign io_out_stage2Out_fixedMissPred_2 = io_out_stage2Out_fixedMissPred[2];
  assign io_out_stage2Out_fixedMissPred_3 = io_out_stage2Out_fixedMissPred[3];
  assign io_out_stage2Out_fixedMissPred_4 = io_out_stage2Out_fixedMissPred[4];
  assign io_out_stage2Out_fixedMissPred_5 = io_out_stage2Out_fixedMissPred[5];
  assign io_out_stage2Out_fixedMissPred_6 = io_out_stage2Out_fixedMissPred[6];
  assign io_out_stage2Out_fixedMissPred_7 = io_out_stage2Out_fixedMissPred[7];
  assign io_out_stage2Out_fixedMissPred_8 = io_out_stage2Out_fixedMissPred[8];
  assign io_out_stage2Out_fixedMissPred_9 = io_out_stage2Out_fixedMissPred[9];
  assign io_out_stage2Out_fixedMissPred_10 = io_out_stage2Out_fixedMissPred[10];
  assign io_out_stage2Out_fixedMissPred_11 = io_out_stage2Out_fixedMissPred[11];
  assign io_out_stage2Out_fixedMissPred_12 = io_out_stage2Out_fixedMissPred[12];
  assign io_out_stage2Out_fixedMissPred_13 = io_out_stage2Out_fixedMissPred[13];
  assign io_out_stage2Out_fixedMissPred_14 = io_out_stage2Out_fixedMissPred[14];
  assign io_out_stage2Out_fixedMissPred_15 = io_out_stage2Out_fixedMissPred[15];
  assign io_out_stage2Out_faultType_0_value = io_out_stage2Out_faultType_value[0];
  assign io_out_stage2Out_faultType_1_value = io_out_stage2Out_faultType_value[1];
  assign io_out_stage2Out_faultType_2_value = io_out_stage2Out_faultType_value[2];
  assign io_out_stage2Out_faultType_3_value = io_out_stage2Out_faultType_value[3];
  assign io_out_stage2Out_faultType_4_value = io_out_stage2Out_faultType_value[4];
  assign io_out_stage2Out_faultType_5_value = io_out_stage2Out_faultType_value[5];
  assign io_out_stage2Out_faultType_6_value = io_out_stage2Out_faultType_value[6];
  assign io_out_stage2Out_faultType_7_value = io_out_stage2Out_faultType_value[7];
  assign io_out_stage2Out_faultType_8_value = io_out_stage2Out_faultType_value[8];
  assign io_out_stage2Out_faultType_9_value = io_out_stage2Out_faultType_value[9];
  assign io_out_stage2Out_faultType_10_value = io_out_stage2Out_faultType_value[10];
  assign io_out_stage2Out_faultType_11_value = io_out_stage2Out_faultType_value[11];
  assign io_out_stage2Out_faultType_12_value = io_out_stage2Out_faultType_value[12];
  assign io_out_stage2Out_faultType_13_value = io_out_stage2Out_faultType_value[13];
  assign io_out_stage2Out_faultType_14_value = io_out_stage2Out_faultType_value[14];
  assign io_out_stage2Out_faultType_15_value = io_out_stage2Out_faultType_value[15];
endmodule
// END GENERATED(wrapper)
