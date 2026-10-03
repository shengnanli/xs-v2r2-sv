// =============================================================================
// PipelineRegModule_6 —— MemBlock 里 uncache 应答回 LSQ 前的一拍 ready/valid 流水寄存器
//
// 在哪一层：MemBlock.scala `AddPipelineReg(uncache.io.lsq.resp, uncacheResp, false.B)`（实例 inner_pipelineReg_1；
//   "delay dcache refill for 1 cycle for better timing"）。载荷是 Uncache 给 LSQ 的应答：
//   data（64 位读数据）、id（Uncache 表项号）、nc（非 MMIO 的 NC 访问）、is2lq（回 LoadQueue 还是 StoreQueue）、
//   denied / corrupt（总线报错）。Scala：mem/MemCommon.scala `AddPipelineReg.PipelineRegModule`。
// 机制（Scala 原样）：
//   · valid：out.fire 清、in.fire 置（置优先），isFlush 清——这里 isFlush 接常量 false.B，firtool 删掉了端口；
//   · in.ready = !valid || out.ready：空着、或这一拍正被取走，就能收；
//   · 载荷 = RegEnable(in.bits, in.fire)：只在 in.fire 时更新，其余保持。
// 复位：★只有 valid 异步复位★；载荷寄存器没有复位（golden 是单独的 always @(posedge clock)）。
//   所以载荷必须写在不带复位的 always_ff 里——若放进带 posedge reset 的块，复位期间 in.fire 时
//   golden 会更新载荷而这里不会，两者就不等价了。
// golden 对照：G1-canonical/golden-rtl/PipelineRegModule_6.sv（172 行）
// =============================================================================
module PipelineRegModule_6 (
  input  logic        clock,
  input  logic        reset,
  output logic        io_in_ready,
  input  logic        io_in_valid,
  input  logic [63:0] io_in_bits_data,
  input  logic [3:0]  io_in_bits_id,
  input  logic        io_in_bits_nc,
  input  logic        io_in_bits_is2lq,
  input  logic        io_in_bits_denied,
  input  logic        io_in_bits_corrupt,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [63:0] io_out_bits_data,
  output logic [3:0]  io_out_bits_id,
  output logic        io_out_bits_nc,
  output logic        io_out_bits_is2lq,
  output logic        io_out_bits_denied,
  output logic        io_out_bits_corrupt
);

  // ---- 握手 ----
  logic pipeline_reg_valid;
  logic in_fire;
  logic out_fire;

  assign io_in_ready  = ~pipeline_reg_valid | io_out_ready;
  assign in_fire      = io_in_valid & io_in_ready;
  assign out_fire     = pipeline_reg_valid & io_out_ready;
  assign io_out_valid = pipeline_reg_valid;

  // ---- valid：取走清 0、收进置 1（同拍置 1 赢），异步复位 ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      pipeline_reg_valid <= 1'b0;
    else if (in_fire)
      pipeline_reg_valid <= 1'b1;
    else if (out_fire)
      pipeline_reg_valid <= 1'b0;
  end

  // ---- 载荷：RegEnable(in.bits, in.fire)，不复位 ----
  always_ff @(posedge clock) begin
    if (in_fire) begin
      io_out_bits_data    <= io_in_bits_data;
      io_out_bits_id      <= io_in_bits_id;
      io_out_bits_nc      <= io_in_bits_nc;
      io_out_bits_is2lq   <= io_in_bits_is2lq;
      io_out_bits_denied  <= io_in_bits_denied;
      io_out_bits_corrupt <= io_in_bits_corrupt;
    end
  end
endmodule
