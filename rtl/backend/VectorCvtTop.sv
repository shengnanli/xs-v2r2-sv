// VectorCvtTop.sv —— 128 位向量浮点转换顶层：两份 64 位 VectorCvt 并排（XiangShan VectorCvtTop，2 拍流水）
// -----------------------------------------------------------------------------
// 在哪一层：VCVT_8 功能单元直接例化本模块；下面是两个 VectorCvt（各管 64 位）。
// 机制（Scala: backend/fu/wrapper/VCVT.scala class VectorCvtTop）：
//   1. 送数：同宽 / 变窄时，vectorCvt0 吃 vs2 的低 64 位、vectorCvt1 吃高 64 位；
//      变宽时一条 uop 只转 64 位源（产生 128 位结果），vuopIdx[0] 选 vs2 的低半还是高半，
//      再把这 64 位拆成两个 32 位分别送两个 VectorCvt（各自高 32 位补 0）。
//   2. 拼结果：同宽 / 变宽时两份 64 位结果直接拼成 128 位；变窄时每份只出 32 位有效结果，
//      拼成 64 位放低半（高 64 位给 0，由 VCVT_8 再拼进旧 vd）。
//   3. 拼 fflags：每个 VectorCvt 出 20 位（4 通道 × 5 位），按结果元素宽度（打两拍对齐）
//      决定各取几个通道：8/16 位结果 4 个通道都有效；32 位 2 个；64 位 1 个；变窄时再减半
//      （变窄时源宽是结果的两倍，每个 VectorCvt 实际只用到一半通道）。
// 怪癖（照 golden）：fflags 是 Mux1H（与门后按位或）；两级对齐寄存器不复位，第二级用
//   fire 打一拍（GatedValidRegNext）使能。isFpToVecInst 在本配置下恒 0，端口已被 firtool 消掉。
// 子模块：VectorCvt × 2（本 lane 重写）。
// golden 对照：G1-canonical/golden-rtl/VectorCvtTop.sv
// =============================================================================

module xs_VectorCvtTop_core (
  input  logic         clock,
  input  logic         reset,
  input  logic         fire,
  input  logic         uop_idx,           // vuopIdx[0]：变宽时选 vs2 的高/低 64 位
  input  logic [63:0]  src_lo,            // vs2[63:0]
  input  logic [63:0]  src_hi,            // vs2[127:64]
  input  logic [7:0]   op_type,
  input  logic [1:0]   sew,
  input  logic [2:0]   rm,
  input  logic [3:0]   output_width_1h,   // 结果元素宽度独热（上层已译码）
  input  logic         is_widen,
  input  logic         is_narrow,
  output logic [127:0] result,
  output logic [39:0]  fflags
);

  // ===========================================================================
  // §1 送数
  // ===========================================================================
  logic [63:0] widen_src;     // 变宽时本 uop 要转的那 64 位
  logic [63:0] in0, in1;
  assign widen_src = uop_idx ? src_hi : src_lo;
  assign in0 = is_widen ? {32'h0, widen_src[31:0]}  : src_lo;
  assign in1 = is_widen ? {32'h0, widen_src[63:32]} : src_hi;

  logic [63:0] res0, res1;
  logic [19:0] ff0, ff1;

  VectorCvt vectorCvt0 (
    .clock     (clock),
    .reset     (reset),
    .io_fire   (fire),
    .io_src    (in0),
    .io_opType (op_type),
    .io_sew    (sew),
    .io_rm     (rm),
    .io_result (res0),
    .io_fflags (ff0)
  );

  VectorCvt vectorCvt1 (
    .clock     (clock),
    .reset     (reset),
    .io_fire   (fire),
    .io_src    (in1),
    .io_opType (op_type),
    .io_sew    (sew),
    .io_rm     (rm),
    .io_result (res1),
    .io_fflags (ff1)
  );

  // ===========================================================================
  // §2 isNarrow / outputWidth1H 打两拍，与 VectorCvt 的结果对齐
  // ===========================================================================
  logic       fireReg_last_r;       // fire 打一拍（GatedValidRegNext）
  logic       isNarrowCycle2_r, isNarrowCycle2;
  logic [3:0] outputWidth1HCycle2_r, outputWidth1HCycle2;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      fireReg_last_r <= 1'b0;
    else if (fire | fireReg_last_r)
      fireReg_last_r <= fire;
  end

  always_ff @(posedge clock) begin
    if (fire) begin
      isNarrowCycle2_r      <= is_narrow;
      outputWidth1HCycle2_r <= output_width_1h;
    end
    if (fireReg_last_r) begin
      isNarrowCycle2      <= isNarrowCycle2_r;
      outputWidth1HCycle2 <= outputWidth1HCycle2_r;
    end
  end

  // ===========================================================================
  // §3 拼结果与 fflags
  // ===========================================================================
  assign result = isNarrowCycle2 ? {64'h0, res1[31:0], res0[31:0]} : {res1, res0};

  logic [39:0] ff_all;              // 两份全部 8 个通道
  assign ff_all = {ff1, ff0};
  assign fflags =
      (outputWidth1HCycle2[0] ? ff_all                                                    : 40'h0)
    | (outputWidth1HCycle2[1] ? (isNarrowCycle2 ? 40'({ff1[9:0], ff0[9:0]}) : ff_all)      : 40'h0)
    | (outputWidth1HCycle2[2] ? (isNarrowCycle2 ? 40'({ff1[4:0], ff0[4:0]})
                                                : 40'({ff1[9:0], ff0[9:0]}))               : 40'h0)
    | (outputWidth1HCycle2[3] ? 40'({ff1[4:0], ff0[4:0]})                                  : 40'h0);

endmodule

module VectorCvtTop(
  input          clock,
  input          reset,
  input          io_fire,
  input          io_uopIdx,
  input  [63:0]  io_src_0,
  input  [63:0]  io_src_1,
  input  [7:0]   io_opType,
  input  [1:0]   io_sew,
  input  [2:0]   io_rm,
  input  [3:0]   io_outputWidth1H,
  input          io_isWiden,
  input          io_isNarrow,
  output [127:0] io_result,
  output [39:0]  io_fflags
);

  xs_VectorCvtTop_core u_core (
    .clock           (clock),
    .reset           (reset),
    .fire            (io_fire),
    .uop_idx         (io_uopIdx),
    .src_lo          (io_src_0),
    .src_hi          (io_src_1),
    .op_type         (io_opType),
    .sew             (io_sew),
    .rm              (io_rm),
    .output_width_1h (io_outputWidth1H),
    .is_widen        (io_isWiden),
    .is_narrow       (io_isNarrow),
    .result          (io_result),
    .fflags          (io_fflags)
  );

endmodule
