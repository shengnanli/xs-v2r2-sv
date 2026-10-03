// =============================================================================
// StridePF —— SMS 预取器里的 PC 步长检测器（本配置下只剩"表的维护"这一半）
//
// 位置：SMSPrefetcher.stride。设计意图：按 pc 查 16 项步长表，连续访问的块地址差
//   稳定时按 last_addr + stride 生成一条预取（s2_gen_req）。
//
// ★本配置的 golden 形态★：SMSPrefetcher 把 io.stride_en 接 0、不接 s2_gen_req，
//   firtool 把"步长/置信度/地址/预取生成"整条数据通路（entries_conf / last_addr /
//   stride、s1_vaddr/paddr、s2_*）连同 vaddr/paddr/stride_en 端口全部裁掉，只剩：
//   去抖（prev_valid/prev_pc）、pc CAM、s1 命中/分配打拍、valids、entries_pc、
//   s1_match_vec 与 16 路 PLRU。模块**没有任何输出端口**；FM 比较的是这 53 个寄存器。
//   核照 golden 幸存的部分写，被裁掉的逻辑不复活（否则两侧寄存器集合对不上）。
//
// 幸存逻辑：
//   s0  s0_valid = lookup.valid 且不是"与上一拍同 pc"的重复查询；CAM：valid 且 pc 相等。
//   s1  s1_hit = RegNext(s0_hit) & io.s1_valid；s1_alloc = RegNext(s0_miss) & io.s1_valid；
//       分配：PLRU 给出的替换项 valid<=1、entries_pc<=prev_pc（= s0 那拍锁存的 pc）；
//       PLRU：命中则 touch 命中项（OHToUInt 按位或编码），否则分配时 touch 替换项。
//
// 怪癖（照 golden）：
//   1. prev_pc / entries_pc / s1_match_vec 不复位；prev_valid、valids、两个 s1 打拍与 PLRU 异步复位。
//   2. CAM 比较不受 s0_valid 门控，s0_hit 才与 s0_valid 相与。
//   3. PLRU 用 rtl/common/xs_PlruReplacer（16 路，编码与 rocket-chip 一致）。
// =============================================================================

module xs_StridePF_core #(
  parameter int unsigned PC_W    = 10,
  parameter int unsigned ENTRIES = 16
) (
  input  logic            clock,
  input  logic            reset,
  input  logic            s0_lookup_valid,
  input  logic [PC_W-1:0] s0_lookup_pc,
  input  logic            s1_valid_in
);

  localparam int unsigned IDX_W = $clog2(ENTRIES);

  // ---------------------------------------------------------------------------
  // s0：去抖 + CAM
  // ---------------------------------------------------------------------------
  logic            prev_valid;
  logic [PC_W-1:0] prev_pc;
  logic            s0_valid;
  logic            ent_valid [ENTRIES];
  logic [PC_W-1:0] ent_pc    [ENTRIES];
  logic            s0_match  [ENTRIES];
  logic            s0_any_match;
  logic            s0_hit, s0_miss;

  assign s0_valid = s0_lookup_valid & ~(prev_valid & (prev_pc == s0_lookup_pc));

  always_comb begin
    s0_any_match = 1'b0;
    for (int i = 0; i < ENTRIES; i++) begin
      s0_match[i] = ent_valid[i] & (ent_pc[i] == s0_lookup_pc);
      if (s0_match[i]) s0_any_match = 1'b1;
    end
  end
  assign s0_hit  = s0_valid &  s0_any_match;
  assign s0_miss = s0_valid & ~s0_any_match;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) prev_valid <= 1'b0;
    else       prev_valid <= s0_lookup_valid;
  end
  always_ff @(posedge clock) begin
    if (s0_lookup_valid) prev_pc <= s0_lookup_pc;
  end

  // ---------------------------------------------------------------------------
  // s1：命中 / 分配 / PLRU
  // ---------------------------------------------------------------------------
  logic             s1_hit_q, s1_alloc_q;
  logic             s1_hit, s1_alloc;
  logic             s1_match [ENTRIES];
  logic [IDX_W-1:0] s1_hit_index;
  logic [IDX_W-1:0] s1_replace_index;

  assign s1_hit   = s1_hit_q   & s1_valid_in;
  assign s1_alloc = s1_alloc_q & s1_valid_in;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_hit_q   <= 1'b0;
      s1_alloc_q <= 1'b0;
    end else begin
      s1_hit_q   <= s0_hit;
      s1_alloc_q <= s0_miss;
    end
  end

  always_comb begin
    s1_hit_index = '0;
    for (int i = 0; i < ENTRIES; i++)
      if (s1_match[i]) s1_hit_index = s1_hit_index | IDX_W'(i);   // OHToUInt：按位或
  end

  xs_PlruReplacer #(.NUM_WAYS(ENTRIES)) u_plru (
    .clock      (clock),
    .reset      (reset),
    .touch_valid(s1_hit | s1_alloc),
    .touch_way  (s1_hit ? s1_hit_index : s1_replace_index),
    .replace_way(s1_replace_index)
  );

  for (genvar i = 0; i < ENTRIES; i++) begin : g_entry
    logic alloc_here;
    assign alloc_here = s1_alloc & (s1_replace_index == IDX_W'(i));
    always_ff @(posedge clock or posedge reset) begin
      if (reset) ent_valid[i] <= 1'b0;
      else       ent_valid[i] <= alloc_here | ent_valid[i];
    end
    always_ff @(posedge clock) begin
      if (alloc_here) ent_pc[i]   <= prev_pc;
      if (s0_valid)   s1_match[i] <= s0_match[i];
    end
  end

endmodule

module StridePF(
  input       clock,
  input       reset,
  input       io_s0_lookup_valid,
  input [9:0] io_s0_lookup_bits_pc,
  input       io_s1_valid
);

  xs_StridePF_core #(
    .PC_W   (10),
    .ENTRIES(16)
  ) u_core (
    .clock          (clock),
    .reset          (reset),
    .s0_lookup_valid(io_s0_lookup_valid),
    .s0_lookup_pc   (io_s0_lookup_bits_pc),
    .s1_valid_in    (io_s1_valid)
  );

endmodule
