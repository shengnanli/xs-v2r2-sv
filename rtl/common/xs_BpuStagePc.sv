// =============================================================================
// xs_BpuStagePc —— BPU 预测器公共外壳里的"各级 PC"寄存器（共享辅助件，非 golden 模块）
//
// 对应 Chisel: xiangshan.frontend.BasePredictor（BPU.scala）里每个预测器都有的
//   s1_pc_dup = s0_pc_dup.zip(s0_fire).map { RegEnable(pc, fire) }，复位脉冲时装复位向量
//   s2_pc_dup = s1_pc_dup.zip(s1_fire).map { SegmentedAddrNext(pc, fire) }
//   s3_pc_dup = s2_pc_dup.zip(s2_fire).map { SegmentedAddrNext(pc, fire) }
// Chisel 把它内联进每个预测器（FauFTB / Tage_SC / ITTage / FTB / RAS 各一份），golden
// 里没有独立模块；这里抽成一个讲清楚的公共实现，供各预测器重写核例化。
// （Composer 层自己那一份写在 rtl/frontend/Composer.sv 里，早于本件，未改。）
//
// 【4 份 dup】请求/PC 在 BPU 里复制 4 份（纯扇出复制，缓解布线时序），值恒等，逐份独立打拍。
//
// 【modified_reset】"复位刚放开"的一拍脉冲：异步复位期间恒 1，复位放开后的第一个
//   时钟沿仍为 1（这一沿把 s1_pc 装成复位向量），同沿清 0。
//
// 【SegmentedAddrNext：分段打拍】50 位 PC 切三段 [49:24] / [23:12] / [11:0]，
//   高两段"值变了且本级 fire"才打拍（顺序取指时高位长期不变 → 省翻转功耗），
//   最低段每次 fire 都打（golden 把它的 modified 条件常量化成 1）。读出时三段拼回。
//
// 复位域（与 golden 逐一对齐）：s1_pc 无复位端（初值靠 modified_reset 那一拍灌入）；
//   modified_reset 与 s2/s3 段寄存器异步复位（段清 0）。
// =============================================================================
module xs_BpuStagePc #(
  parameter int unsigned NUM_DUP = 4,
  parameter int unsigned PC_W    = 50
)(
  input  logic            clock,
  input  logic            reset,
  input  logic [47:0]     reset_vector,
  input  logic [PC_W-1:0] s0_pc   [NUM_DUP],
  input  logic            s0_fire [NUM_DUP],
  input  logic            s1_fire [NUM_DUP],
  input  logic            s2_fire [NUM_DUP],
  output logic [PC_W-1:0] s1_pc   [NUM_DUP],
  output logic [PC_W-1:0] s2_pc   [NUM_DUP],
  output logic [PC_W-1:0] s3_pc   [NUM_DUP]
);

  localparam int unsigned HI_W  = 26;  // pc[49:24]
  localparam int unsigned MID_W = 12;  // pc[23:12]
  localparam int unsigned LO_W  = 12;  // pc[11:0]

  logic             modified_reset;
  logic [HI_W-1:0]  s2_hi  [NUM_DUP];
  logic [MID_W-1:0] s2_mid [NUM_DUP];
  logic [LO_W-1:0]  s2_lo  [NUM_DUP];
  logic [HI_W-1:0]  s3_hi  [NUM_DUP];
  logic [MID_W-1:0] s3_mid [NUM_DUP];
  logic [LO_W-1:0]  s3_lo  [NUM_DUP];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) modified_reset <= 1'b1;
    else       modified_reset <= 1'b0;
  end

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_dup
    assign s2_pc[d] = {s2_hi[d], s2_mid[d], s2_lo[d]};
    assign s3_pc[d] = {s3_hi[d], s3_mid[d], s3_lo[d]};

    // s1：s0 fire 时锁存；复位脉冲那一拍装复位向量（优先）
    always_ff @(posedge clock) begin
      if (modified_reset)  s1_pc[d] <= {2'h0, reset_vector};
      else if (s0_fire[d]) s1_pc[d] <= s0_pc[d];
    end

    // s2 / s3：分段打拍（高两段变了才打，最低段每次 fire 都打）
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        s2_hi[d] <= '0;  s2_mid[d] <= '0;  s2_lo[d] <= '0;
        s3_hi[d] <= '0;  s3_mid[d] <= '0;  s3_lo[d] <= '0;
      end else begin
        if (s1_fire[d] && s2_hi[d]  != s1_pc[d][49:24]) s2_hi[d]  <= s1_pc[d][49:24];
        if (s1_fire[d] && s2_mid[d] != s1_pc[d][23:12]) s2_mid[d] <= s1_pc[d][23:12];
        if (s1_fire[d])                                  s2_lo[d]  <= s1_pc[d][11:0];
        if (s2_fire[d] && s3_hi[d]  != s2_hi[d])         s3_hi[d]  <= s2_hi[d];
        if (s2_fire[d] && s3_mid[d] != s2_mid[d])        s3_mid[d] <= s2_mid[d];
        if (s2_fire[d])                                  s3_lo[d]  <= s2_lo[d];
      end
    end
  end

endmodule
