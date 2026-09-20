// =============================================================================
// DelayN_214 —— 固定级数的载荷打拍链（xs_DelayN_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 2；载荷宽度 = 183 位，分 37 个字段；
//   golden 模块体 = 366 个 reg 位（2 级 × 183 位），无复位 / 无使能 / 无子模块；
//   端口 75 个 = clock + 37 个 io_in_* + 37 个 io_out_*。
//   载荷字段：valid=1b, bits_pc=50b, bits_instr=32b, bits_exceptionVec_0=1b, bits_exceptionVec_1=1b …共 37 个字段，明细见端口表。
//   使用者：ExeUnit_7（向量执行单元）—— 183 位微操作包打两拍。
//
// 结构：golden 同名端口表 -> 打包成一根 183 位扁平载荷 -> 设参例化
//   xs_DelayN_core（核体见 xs_DelayN_core.sv，打拍语义与不变式都在那里讲）
//   -> 拆包回 golden 的 io_out_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（本轮已发生 3 次位宽静默错事故）。
// 自动生成：verif/ut/DelayN/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayN_214(
  input         clock,
  input         io_in_valid,
  input  [49:0] io_in_bits_pc,
  input  [31:0] io_in_bits_instr,
  input         io_in_bits_exceptionVec_0,
  input         io_in_bits_exceptionVec_1,
  input         io_in_bits_exceptionVec_2,
  input         io_in_bits_exceptionVec_3,
  input         io_in_bits_exceptionVec_4,
  input         io_in_bits_exceptionVec_5,
  input         io_in_bits_exceptionVec_6,
  input         io_in_bits_exceptionVec_7,
  input         io_in_bits_exceptionVec_8,
  input         io_in_bits_exceptionVec_9,
  input         io_in_bits_exceptionVec_10,
  input         io_in_bits_exceptionVec_11,
  input         io_in_bits_exceptionVec_12,
  input         io_in_bits_exceptionVec_13,
  input         io_in_bits_exceptionVec_14,
  input         io_in_bits_exceptionVec_15,
  input         io_in_bits_exceptionVec_16,
  input         io_in_bits_exceptionVec_17,
  input         io_in_bits_exceptionVec_18,
  input         io_in_bits_exceptionVec_19,
  input         io_in_bits_exceptionVec_20,
  input         io_in_bits_exceptionVec_21,
  input         io_in_bits_exceptionVec_22,
  input         io_in_bits_exceptionVec_23,
  input         io_in_bits_isPcBkpt,
  input         io_in_bits_isFetchMalAddr,
  input         io_in_bits_satpFlushFirstFetchFault,
  input  [63:0] io_in_bits_gpaddr,
  input         io_in_bits_singleStep,
  input         io_in_bits_crossPageIPFFix,
  input         io_in_bits_isInterrupt,
  input         io_in_bits_isHls,
  input  [3:0]  io_in_bits_trigger,
  input         io_in_bits_isForVSnonLeafPTE,
  output        io_out_valid,
  output [49:0] io_out_bits_pc,
  output [31:0] io_out_bits_instr,
  output        io_out_bits_exceptionVec_0,
  output        io_out_bits_exceptionVec_1,
  output        io_out_bits_exceptionVec_2,
  output        io_out_bits_exceptionVec_3,
  output        io_out_bits_exceptionVec_4,
  output        io_out_bits_exceptionVec_5,
  output        io_out_bits_exceptionVec_6,
  output        io_out_bits_exceptionVec_7,
  output        io_out_bits_exceptionVec_8,
  output        io_out_bits_exceptionVec_9,
  output        io_out_bits_exceptionVec_10,
  output        io_out_bits_exceptionVec_11,
  output        io_out_bits_exceptionVec_12,
  output        io_out_bits_exceptionVec_13,
  output        io_out_bits_exceptionVec_14,
  output        io_out_bits_exceptionVec_15,
  output        io_out_bits_exceptionVec_16,
  output        io_out_bits_exceptionVec_17,
  output        io_out_bits_exceptionVec_18,
  output        io_out_bits_exceptionVec_19,
  output        io_out_bits_exceptionVec_20,
  output        io_out_bits_exceptionVec_21,
  output        io_out_bits_exceptionVec_22,
  output        io_out_bits_exceptionVec_23,
  output        io_out_bits_isPcBkpt,
  output        io_out_bits_isFetchMalAddr,
  output        io_out_bits_satpFlushFirstFetchFault,
  output [63:0] io_out_bits_gpaddr,
  output        io_out_bits_singleStep,
  output        io_out_bits_crossPageIPFFix,
  output        io_out_bits_isInterrupt,
  output        io_out_bits_isHls,
  output [3:0]  io_out_bits_trigger,
  output        io_out_bits_isForVSnonLeafPTE
);

  localparam int unsigned STAGES          = 2;
  localparam int unsigned GOLDEN_REG_BITS = 366;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部输入 / 输出端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_in_valid, io_in_bits_pc, io_in_bits_instr, io_in_bits_exceptionVec_0,
     io_in_bits_exceptionVec_1, io_in_bits_exceptionVec_2, io_in_bits_exceptionVec_3,
     io_in_bits_exceptionVec_4, io_in_bits_exceptionVec_5, io_in_bits_exceptionVec_6,
     io_in_bits_exceptionVec_7, io_in_bits_exceptionVec_8, io_in_bits_exceptionVec_9,
     io_in_bits_exceptionVec_10, io_in_bits_exceptionVec_11, io_in_bits_exceptionVec_12,
     io_in_bits_exceptionVec_13, io_in_bits_exceptionVec_14, io_in_bits_exceptionVec_15,
     io_in_bits_exceptionVec_16, io_in_bits_exceptionVec_17, io_in_bits_exceptionVec_18,
     io_in_bits_exceptionVec_19, io_in_bits_exceptionVec_20, io_in_bits_exceptionVec_21,
     io_in_bits_exceptionVec_22, io_in_bits_exceptionVec_23, io_in_bits_isPcBkpt,
     io_in_bits_isFetchMalAddr, io_in_bits_satpFlushFirstFetchFault, io_in_bits_gpaddr,
     io_in_bits_singleStep, io_in_bits_crossPageIPFFix, io_in_bits_isInterrupt,
     io_in_bits_isHls, io_in_bits_trigger, io_in_bits_isForVSnonLeafPTE});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_out_valid, io_out_bits_pc, io_out_bits_instr, io_out_bits_exceptionVec_0,
     io_out_bits_exceptionVec_1, io_out_bits_exceptionVec_2, io_out_bits_exceptionVec_3,
     io_out_bits_exceptionVec_4, io_out_bits_exceptionVec_5, io_out_bits_exceptionVec_6,
     io_out_bits_exceptionVec_7, io_out_bits_exceptionVec_8, io_out_bits_exceptionVec_9,
     io_out_bits_exceptionVec_10, io_out_bits_exceptionVec_11,
     io_out_bits_exceptionVec_12, io_out_bits_exceptionVec_13,
     io_out_bits_exceptionVec_14, io_out_bits_exceptionVec_15,
     io_out_bits_exceptionVec_16, io_out_bits_exceptionVec_17,
     io_out_bits_exceptionVec_18, io_out_bits_exceptionVec_19,
     io_out_bits_exceptionVec_20, io_out_bits_exceptionVec_21,
     io_out_bits_exceptionVec_22, io_out_bits_exceptionVec_23, io_out_bits_isPcBkpt,
     io_out_bits_isFetchMalAddr, io_out_bits_satpFlushFirstFetchFault, io_out_bits_gpaddr,
     io_out_bits_singleStep, io_out_bits_crossPageIPFFix, io_out_bits_isInterrupt,
     io_out_bits_isHls, io_out_bits_trigger, io_out_bits_isForVSnonLeafPTE});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_in_valid, io_in_bits_pc, io_in_bits_instr, io_in_bits_exceptionVec_0,
     io_in_bits_exceptionVec_1, io_in_bits_exceptionVec_2, io_in_bits_exceptionVec_3,
     io_in_bits_exceptionVec_4, io_in_bits_exceptionVec_5, io_in_bits_exceptionVec_6,
     io_in_bits_exceptionVec_7, io_in_bits_exceptionVec_8, io_in_bits_exceptionVec_9,
     io_in_bits_exceptionVec_10, io_in_bits_exceptionVec_11, io_in_bits_exceptionVec_12,
     io_in_bits_exceptionVec_13, io_in_bits_exceptionVec_14, io_in_bits_exceptionVec_15,
     io_in_bits_exceptionVec_16, io_in_bits_exceptionVec_17, io_in_bits_exceptionVec_18,
     io_in_bits_exceptionVec_19, io_in_bits_exceptionVec_20, io_in_bits_exceptionVec_21,
     io_in_bits_exceptionVec_22, io_in_bits_exceptionVec_23, io_in_bits_isPcBkpt,
     io_in_bits_isFetchMalAddr, io_in_bits_satpFlushFirstFetchFault, io_in_bits_gpaddr,
     io_in_bits_singleStep, io_in_bits_crossPageIPFFix, io_in_bits_isInterrupt,
     io_in_bits_isHls, io_in_bits_trigger, io_in_bits_isForVSnonLeafPTE};

  xs_DelayN_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT),
    .GOLDEN_HAS_CLOCK(1)
  ) u_core (
    .clock(clock),
    .d_in (payload_in),
    .d_out(payload_out)
  );

  assign
    {io_out_valid, io_out_bits_pc, io_out_bits_instr, io_out_bits_exceptionVec_0,
     io_out_bits_exceptionVec_1, io_out_bits_exceptionVec_2, io_out_bits_exceptionVec_3,
     io_out_bits_exceptionVec_4, io_out_bits_exceptionVec_5, io_out_bits_exceptionVec_6,
     io_out_bits_exceptionVec_7, io_out_bits_exceptionVec_8, io_out_bits_exceptionVec_9,
     io_out_bits_exceptionVec_10, io_out_bits_exceptionVec_11,
     io_out_bits_exceptionVec_12, io_out_bits_exceptionVec_13,
     io_out_bits_exceptionVec_14, io_out_bits_exceptionVec_15,
     io_out_bits_exceptionVec_16, io_out_bits_exceptionVec_17,
     io_out_bits_exceptionVec_18, io_out_bits_exceptionVec_19,
     io_out_bits_exceptionVec_20, io_out_bits_exceptionVec_21,
     io_out_bits_exceptionVec_22, io_out_bits_exceptionVec_23, io_out_bits_isPcBkpt,
     io_out_bits_isFetchMalAddr, io_out_bits_satpFlushFirstFetchFault, io_out_bits_gpaddr,
     io_out_bits_singleStep, io_out_bits_crossPageIPFFix, io_out_bits_isInterrupt,
     io_out_bits_isHls, io_out_bits_trigger, io_out_bits_isForVSnonLeafPTE} = payload_out;

endmodule
