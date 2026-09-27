// =============================================================================
// DiffRatStateBuffer.sv —— difftest 用的「已提交」重命名表快照缓冲
// -----------------------------------------------------------------------------
// 设计源: XiangShan src/main/scala/xiangshan/backend/rob/DiffRatStateBuffer.scala
// golden 对照: G1-canonical/golden-rtl/DiffRatStateBuffer.sv（10,187 行）
// 层次位置: SimTop…backend.inner.ctrlBlock.rename.renameTableWrapper.diffRatBuffer
//
// ★ 它是什么 ★
// difftest 要看的是**提交序**的重命名表，而 RenameTable 里的架构表随 RAB 提交更新，
// 时序与 Rob 提交不对齐。本模块在 rename 时就把「本拍 rename 之后的整张表」
// （97 项 × 8 位 = 776 位）按 robIdx 存进快照存储，Rob 提交某条指令时按其 robIdx 读回：
//   lane 链：laneRat[0] = 架构表基线(diffRatBase)，laneRat[k+1] = laneRat[k] 被第 k 路
//            rename 更新（ldest 命中且对应 xxWen）后的表；
//   写：第 k 路 rename 的 lastUop 时，把 laneRat[k+1] 写进第 k 个 bank 的槽 slotOf(robIdx)，
//       同时在 tags 存储记下「这个槽在 bank k」、置该槽 valid；
//   读：commitRobIdx 有效且槽 valid 时读 6 个 bank + tags（同步读、1 拍），下一拍按 tags 的
//       one-hot 选 bank 得到 readState，写进 committedRat；同拍输出 readState，否则输出 committedRat。
// slotOf(ptr) = ptr.value + (ptr.flag ? RobSize : 0)，两代 robIdx 分开存（320 = 2×160 槽）。
//
// ★ golden 事实 ★
//   - 存储叶子 diff_rat_state_bank_320x776 ×6 与 stateBankTags_320x3 是 firtool 行为级
//     存储，深度 320 / 地址 9 位（2^9=512>320，白盒化必触发 FMR_ELAB-147）。本核直接例化
//     golden 那两份（APPROVED_MEMORY_MACRO_MODEL，verif/vendor_boundary.tsv 逐条审定），
//     FM 两侧对称黑盒，仿真两侧共用 golden 叶子 —— 与 L2TlbMissQueue 的 ram_40x47 同一处置。
//   - stateSlotValid 320 项：提交读清零压过同拍写置位；**越界下标**（slot ≥ 320）读到的是
//     第 0 项（firtool 对 Vec 越界读的展开结果），写则无效果 —— 照抄。
//   - committedRat 复位值 = DiffRatState.init：int 全 0、fp[i]=i、vec[i]=i+1、v0=0、vl=0。
//   - bankReadData / readBankOH 无复位（RegEnable(readRequestValid)）；readValid 复位 0。
//   - 快照位序（asUInt）：{intRat[31:0], fpRat[31:0], vecRat[30:0], v0Rat, vlRat}，intRat[31] 在 MSB。
// =============================================================================

package diffrat_pkg;
  localparam int unsigned PREG_W    = 8;
  localparam int unsigned INT_N     = 32;
  localparam int unsigned FP_N      = 32;
  localparam int unsigned VEC_N     = 31;
  localparam int unsigned V0_N      = 1;
  localparam int unsigned VL_N      = 1;
  localparam int unsigned RENAME_W  = 6;
  localparam int unsigned ROB_SIZE  = 160;
  localparam int unsigned SLOTS     = 2 * ROB_SIZE;   // 320
  localparam int unsigned SLOT_W    = 9;
  localparam int unsigned LDEST_W   = 6;
  localparam int unsigned STATE_W   = (INT_N + FP_N + VEC_N + V0_N + VL_N) * PREG_W;   // 776

  // 整张「difftest 视角」的重命名表；packed 顺序 = golden asUInt 位序（intRat 在 MSB）
  typedef struct packed {
    logic [INT_N-1:0][PREG_W-1:0] intRat;
    logic [FP_N-1:0][PREG_W-1:0]  fpRat;
    logic [VEC_N-1:0][PREG_W-1:0] vecRat;
    logic [V0_N-1:0][PREG_W-1:0]  v0Rat;
    logic [VL_N-1:0][PREG_W-1:0]  vlRat;
  } diff_rat_state_t;

  // 一路 rename 的更新请求
  typedef struct packed {
    logic              robIdx_flag;
    logic [PREG_W-1:0] robIdx_value;
    logic              lastUop;
    logic [LDEST_W-1:0] ldest;
    logic [PREG_W-1:0] pdest;
    logic              rfWen, fpWen, vecWen, v0Wen, vlWen;
  } diff_rat_update_t;

  function automatic logic [SLOT_W-1:0] slot_of(input logic flag, input logic [PREG_W-1:0] value);
    return {1'b0, value} + (flag ? SLOT_W'(ROB_SIZE) : SLOT_W'(0));
  endfunction

  function automatic diff_rat_state_t init_state();
    diff_rat_state_t s;
    for (int i = 0; i < INT_N; i++) s.intRat[i] = '0;
    for (int i = 0; i < FP_N;  i++) s.fpRat[i]  = PREG_W'(i);
    for (int i = 0; i < VEC_N; i++) s.vecRat[i] = PREG_W'(i + V0_N);
    for (int i = 0; i < V0_N;  i++) s.v0Rat[i]  = PREG_W'(i);
    for (int i = 0; i < VL_N;  i++) s.vlRat[i]  = PREG_W'(i);
    return s;
  endfunction
endpackage

module xs_DiffRatStateBuffer_core
  import diffrat_pkg::*;
(
  input  logic                              clock,
  input  logic                              reset,
  input  diff_rat_state_t                   diffRatBase,
  input  logic [RENAME_W-1:0]               renameUpdates_valid,
  input  diff_rat_update_t [RENAME_W-1:0]   renameUpdates,
  input  logic                              commitRobIdx_valid,
  input  logic                              commitRobIdx_flag,
  input  logic [PREG_W-1:0]                 commitRobIdx_value,
  output diff_rat_state_t                   diffRat
);

  // ---------------------------------------------------------------------------
  // lane 链：每路 rename 按 ldest 命中把 pdest 写进对应类别的表
  // ---------------------------------------------------------------------------
  diff_rat_state_t [RENAME_W:0] laneRat;
  assign laneRat[0] = diffRatBase;

  for (genvar k = 0; k < RENAME_W; k++) begin : g_lane
    always_comb begin
      logic v; diff_rat_update_t u;
      v = renameUpdates_valid[k]; u = renameUpdates[k];
      laneRat[k+1] = laneRat[k];
      for (int r = 0; r < INT_N; r++) if (v & u.rfWen  & (u.ldest == LDEST_W'(r)))        laneRat[k+1].intRat[r] = u.pdest;
      for (int r = 0; r < FP_N;  r++) if (v & u.fpWen  & (u.ldest == LDEST_W'(r)))        laneRat[k+1].fpRat[r]  = u.pdest;
      for (int r = 0; r < VEC_N; r++) if (v & u.vecWen & (u.ldest == LDEST_W'(r + V0_N))) laneRat[k+1].vecRat[r] = u.pdest;
      for (int r = 0; r < V0_N;  r++) if (v & u.v0Wen  & (u.ldest == LDEST_W'(r)))        laneRat[k+1].v0Rat[r]  = u.pdest;
      for (int r = 0; r < VL_N;  r++) if (v & u.vlWen  & (u.ldest == LDEST_W'(r)))        laneRat[k+1].vlRat[r]  = u.pdest;
    end
  end

  // ---------------------------------------------------------------------------
  // 写：lastUop 时把 laneRat[k+1] 存进 bank k 的槽 slotOf(robIdx)
  // ---------------------------------------------------------------------------
  logic [RENAME_W-1:0]              stateWriteValid;
  logic [RENAME_W-1:0][SLOT_W-1:0]  stateWriteSlot;
  always_comb
    for (int k = 0; k < RENAME_W; k++) begin
      stateWriteValid[k] = renameUpdates_valid[k] & renameUpdates[k].lastUop;
      stateWriteSlot[k]  = slot_of(renameUpdates[k].robIdx_flag, renameUpdates[k].robIdx_value);
    end

  wire [SLOT_W-1:0] readSlot = slot_of(commitRobIdx_flag, commitRobIdx_value);

  // 槽有效位（复位 0）：提交读清零压过同拍写置位；越界读取第 0 项、越界写无效（照 golden）
  logic [SLOTS-1:0] stateSlotValid;
  // 读选择照 golden 的做法把 320 位扩成 2^SLOT_W=512 位（越界那 192 项都是第 0 项）再用 9 位下标索引：
  // 这样下标的声明位宽与向量深度精确相等。写成 `in_range ? v[slot] : v[0]` 时 FM 只按下标声明
  // 位宽判越界、不传播守卫，impl 侧 set_top 会 FMR_ELAB-147（2026-09-27 实测，见 CONVENTIONS）。
  wire  [(1 << SLOT_W)-1:0] stateSlotValidExt = {{((1 << SLOT_W) - SLOTS){stateSlotValid[0]}}, stateSlotValid};
  wire  readSlotValid     = stateSlotValidExt[readSlot];
  wire  readRequestValid  = commitRobIdx_valid & readSlotValid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) stateSlotValid <= '0;
    else
      for (int s = 0; s < SLOTS; s++) begin
        logic set_hit;
        set_hit = 1'b0;
        for (int k = 0; k < RENAME_W; k++)
          set_hit |= stateWriteValid[k] & (stateWriteSlot[k] == SLOT_W'(s));
        stateSlotValid[s] <= ~(commitRobIdx_valid & (readSlot == SLOT_W'(s))) & (set_hit | stateSlotValid[s]);
      end
  end

  // 6 个 bank（每路 rename 独占一个）+ tags（记槽在哪个 bank）
  logic [RENAME_W-1:0][STATE_W-1:0] bank_rdata;
  logic [2:0]                       tag_rdata;
  for (genvar k = 0; k < RENAME_W; k++) begin : g_bank
    diff_rat_state_bank_320x776 diff_rat_state_bank_ext (
      .R0_addr (readSlot),
      .R0_en   (1'b1),
      .R0_clk  (clock),
      .R0_data (bank_rdata[k]),
      .W0_addr (stateWriteSlot[k]),
      .W0_en   (stateWriteValid[k]),
      .W0_clk  (clock),
      .W0_data (laneRat[k+1])
    );
  end
  // tags 的 6 个写口在 golden 里按 lane 4,3,2,1,5,0 的顺序接 W0..W5（firtool 展开序），照抄
  stateBankTags_320x3 stateBankTags_ext (
    .R0_addr (readSlot), .R0_en (1'b1), .R0_clk (clock), .R0_data (tag_rdata),
    .W0_addr (stateWriteSlot[4]), .W0_en (stateWriteValid[4]), .W0_clk (clock), .W0_data (3'd4),
    .W1_addr (stateWriteSlot[3]), .W1_en (stateWriteValid[3]), .W1_clk (clock), .W1_data (3'd3),
    .W2_addr (stateWriteSlot[2]), .W2_en (stateWriteValid[2]), .W2_clk (clock), .W2_data (3'd2),
    .W3_addr (stateWriteSlot[1]), .W3_en (stateWriteValid[1]), .W3_clk (clock), .W3_data (3'd1),
    .W4_addr (stateWriteSlot[5]), .W4_en (stateWriteValid[5]), .W4_clk (clock), .W4_data (3'd5),
    .W5_addr (stateWriteSlot[0]), .W5_en (stateWriteValid[0]), .W5_clk (clock), .W5_data (3'd0)
  );

  // ---------------------------------------------------------------------------
  // 读：下一拍按 tags 的 one-hot 选 bank；写进 committedRat；同拍直接输出
  // ---------------------------------------------------------------------------
  logic [RENAME_W-1:0][STATE_W-1:0] bankReadData;   // 无复位
  logic [RENAME_W-1:0]              readBankOH;     // 无复位（UIntToOH 截到 6 位）
  logic                             readValid;
  diff_rat_state_t                  committedRat;

  always_ff @(posedge clock)
    if (readRequestValid) begin
      bankReadData <= bank_rdata;
      readBankOH   <= RENAME_W'(8'h1 << tag_rdata);
    end

  diff_rat_state_t readState;
  always_comb begin
    readState = '0;
    for (int k = 0; k < RENAME_W; k++)
      readState |= readBankOH[k] ? diff_rat_state_t'(bankReadData[k]) : '0;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      readValid    <= 1'b0;
      committedRat <= init_state();
    end else begin
      readValid <= readRequestValid;
      if (readValid) committedRat <= readState;
    end
  end

  assign diffRat = readValid ? readState : committedRat;

endmodule : xs_DiffRatStateBuffer_core

// BEGIN GENERATED(diffrat_wrapper) —— 由 scripts/gen_renametablewrapper.py 从 golden 端口表产出
module DiffRatStateBuffer(
  input  clock,
  input  reset,
  input  [7:0] io_diffRatBase_intRat_0,
  input  [7:0] io_diffRatBase_intRat_1,
  input  [7:0] io_diffRatBase_intRat_2,
  input  [7:0] io_diffRatBase_intRat_3,
  input  [7:0] io_diffRatBase_intRat_4,
  input  [7:0] io_diffRatBase_intRat_5,
  input  [7:0] io_diffRatBase_intRat_6,
  input  [7:0] io_diffRatBase_intRat_7,
  input  [7:0] io_diffRatBase_intRat_8,
  input  [7:0] io_diffRatBase_intRat_9,
  input  [7:0] io_diffRatBase_intRat_10,
  input  [7:0] io_diffRatBase_intRat_11,
  input  [7:0] io_diffRatBase_intRat_12,
  input  [7:0] io_diffRatBase_intRat_13,
  input  [7:0] io_diffRatBase_intRat_14,
  input  [7:0] io_diffRatBase_intRat_15,
  input  [7:0] io_diffRatBase_intRat_16,
  input  [7:0] io_diffRatBase_intRat_17,
  input  [7:0] io_diffRatBase_intRat_18,
  input  [7:0] io_diffRatBase_intRat_19,
  input  [7:0] io_diffRatBase_intRat_20,
  input  [7:0] io_diffRatBase_intRat_21,
  input  [7:0] io_diffRatBase_intRat_22,
  input  [7:0] io_diffRatBase_intRat_23,
  input  [7:0] io_diffRatBase_intRat_24,
  input  [7:0] io_diffRatBase_intRat_25,
  input  [7:0] io_diffRatBase_intRat_26,
  input  [7:0] io_diffRatBase_intRat_27,
  input  [7:0] io_diffRatBase_intRat_28,
  input  [7:0] io_diffRatBase_intRat_29,
  input  [7:0] io_diffRatBase_intRat_30,
  input  [7:0] io_diffRatBase_intRat_31,
  input  [7:0] io_diffRatBase_fpRat_0,
  input  [7:0] io_diffRatBase_fpRat_1,
  input  [7:0] io_diffRatBase_fpRat_2,
  input  [7:0] io_diffRatBase_fpRat_3,
  input  [7:0] io_diffRatBase_fpRat_4,
  input  [7:0] io_diffRatBase_fpRat_5,
  input  [7:0] io_diffRatBase_fpRat_6,
  input  [7:0] io_diffRatBase_fpRat_7,
  input  [7:0] io_diffRatBase_fpRat_8,
  input  [7:0] io_diffRatBase_fpRat_9,
  input  [7:0] io_diffRatBase_fpRat_10,
  input  [7:0] io_diffRatBase_fpRat_11,
  input  [7:0] io_diffRatBase_fpRat_12,
  input  [7:0] io_diffRatBase_fpRat_13,
  input  [7:0] io_diffRatBase_fpRat_14,
  input  [7:0] io_diffRatBase_fpRat_15,
  input  [7:0] io_diffRatBase_fpRat_16,
  input  [7:0] io_diffRatBase_fpRat_17,
  input  [7:0] io_diffRatBase_fpRat_18,
  input  [7:0] io_diffRatBase_fpRat_19,
  input  [7:0] io_diffRatBase_fpRat_20,
  input  [7:0] io_diffRatBase_fpRat_21,
  input  [7:0] io_diffRatBase_fpRat_22,
  input  [7:0] io_diffRatBase_fpRat_23,
  input  [7:0] io_diffRatBase_fpRat_24,
  input  [7:0] io_diffRatBase_fpRat_25,
  input  [7:0] io_diffRatBase_fpRat_26,
  input  [7:0] io_diffRatBase_fpRat_27,
  input  [7:0] io_diffRatBase_fpRat_28,
  input  [7:0] io_diffRatBase_fpRat_29,
  input  [7:0] io_diffRatBase_fpRat_30,
  input  [7:0] io_diffRatBase_fpRat_31,
  input  [7:0] io_diffRatBase_vecRat_0,
  input  [7:0] io_diffRatBase_vecRat_1,
  input  [7:0] io_diffRatBase_vecRat_2,
  input  [7:0] io_diffRatBase_vecRat_3,
  input  [7:0] io_diffRatBase_vecRat_4,
  input  [7:0] io_diffRatBase_vecRat_5,
  input  [7:0] io_diffRatBase_vecRat_6,
  input  [7:0] io_diffRatBase_vecRat_7,
  input  [7:0] io_diffRatBase_vecRat_8,
  input  [7:0] io_diffRatBase_vecRat_9,
  input  [7:0] io_diffRatBase_vecRat_10,
  input  [7:0] io_diffRatBase_vecRat_11,
  input  [7:0] io_diffRatBase_vecRat_12,
  input  [7:0] io_diffRatBase_vecRat_13,
  input  [7:0] io_diffRatBase_vecRat_14,
  input  [7:0] io_diffRatBase_vecRat_15,
  input  [7:0] io_diffRatBase_vecRat_16,
  input  [7:0] io_diffRatBase_vecRat_17,
  input  [7:0] io_diffRatBase_vecRat_18,
  input  [7:0] io_diffRatBase_vecRat_19,
  input  [7:0] io_diffRatBase_vecRat_20,
  input  [7:0] io_diffRatBase_vecRat_21,
  input  [7:0] io_diffRatBase_vecRat_22,
  input  [7:0] io_diffRatBase_vecRat_23,
  input  [7:0] io_diffRatBase_vecRat_24,
  input  [7:0] io_diffRatBase_vecRat_25,
  input  [7:0] io_diffRatBase_vecRat_26,
  input  [7:0] io_diffRatBase_vecRat_27,
  input  [7:0] io_diffRatBase_vecRat_28,
  input  [7:0] io_diffRatBase_vecRat_29,
  input  [7:0] io_diffRatBase_vecRat_30,
  input  [7:0] io_diffRatBase_v0Rat_0,
  input  [7:0] io_diffRatBase_vlRat_0,
  input  io_renameUpdates_0_valid,
  input  io_renameUpdates_0_bits_robIdx_flag,
  input  [7:0] io_renameUpdates_0_bits_robIdx_value,
  input  io_renameUpdates_0_bits_lastUop,
  input  [5:0] io_renameUpdates_0_bits_ldest,
  input  [7:0] io_renameUpdates_0_bits_pdest,
  input  io_renameUpdates_0_bits_rfWen,
  input  io_renameUpdates_0_bits_fpWen,
  input  io_renameUpdates_0_bits_vecWen,
  input  io_renameUpdates_0_bits_v0Wen,
  input  io_renameUpdates_0_bits_vlWen,
  input  io_renameUpdates_1_valid,
  input  io_renameUpdates_1_bits_robIdx_flag,
  input  [7:0] io_renameUpdates_1_bits_robIdx_value,
  input  io_renameUpdates_1_bits_lastUop,
  input  [5:0] io_renameUpdates_1_bits_ldest,
  input  [7:0] io_renameUpdates_1_bits_pdest,
  input  io_renameUpdates_1_bits_rfWen,
  input  io_renameUpdates_1_bits_fpWen,
  input  io_renameUpdates_1_bits_vecWen,
  input  io_renameUpdates_1_bits_v0Wen,
  input  io_renameUpdates_1_bits_vlWen,
  input  io_renameUpdates_2_valid,
  input  io_renameUpdates_2_bits_robIdx_flag,
  input  [7:0] io_renameUpdates_2_bits_robIdx_value,
  input  io_renameUpdates_2_bits_lastUop,
  input  [5:0] io_renameUpdates_2_bits_ldest,
  input  [7:0] io_renameUpdates_2_bits_pdest,
  input  io_renameUpdates_2_bits_rfWen,
  input  io_renameUpdates_2_bits_fpWen,
  input  io_renameUpdates_2_bits_vecWen,
  input  io_renameUpdates_2_bits_v0Wen,
  input  io_renameUpdates_2_bits_vlWen,
  input  io_renameUpdates_3_valid,
  input  io_renameUpdates_3_bits_robIdx_flag,
  input  [7:0] io_renameUpdates_3_bits_robIdx_value,
  input  io_renameUpdates_3_bits_lastUop,
  input  [5:0] io_renameUpdates_3_bits_ldest,
  input  [7:0] io_renameUpdates_3_bits_pdest,
  input  io_renameUpdates_3_bits_rfWen,
  input  io_renameUpdates_3_bits_fpWen,
  input  io_renameUpdates_3_bits_vecWen,
  input  io_renameUpdates_3_bits_v0Wen,
  input  io_renameUpdates_3_bits_vlWen,
  input  io_renameUpdates_4_valid,
  input  io_renameUpdates_4_bits_robIdx_flag,
  input  [7:0] io_renameUpdates_4_bits_robIdx_value,
  input  io_renameUpdates_4_bits_lastUop,
  input  [5:0] io_renameUpdates_4_bits_ldest,
  input  [7:0] io_renameUpdates_4_bits_pdest,
  input  io_renameUpdates_4_bits_rfWen,
  input  io_renameUpdates_4_bits_fpWen,
  input  io_renameUpdates_4_bits_vecWen,
  input  io_renameUpdates_4_bits_v0Wen,
  input  io_renameUpdates_4_bits_vlWen,
  input  io_renameUpdates_5_valid,
  input  io_renameUpdates_5_bits_robIdx_flag,
  input  [7:0] io_renameUpdates_5_bits_robIdx_value,
  input  io_renameUpdates_5_bits_lastUop,
  input  [5:0] io_renameUpdates_5_bits_ldest,
  input  [7:0] io_renameUpdates_5_bits_pdest,
  input  io_renameUpdates_5_bits_rfWen,
  input  io_renameUpdates_5_bits_fpWen,
  input  io_renameUpdates_5_bits_vecWen,
  input  io_renameUpdates_5_bits_v0Wen,
  input  io_renameUpdates_5_bits_vlWen,
  input  io_commitRobIdx_valid,
  input  io_commitRobIdx_bits_flag,
  input  [7:0] io_commitRobIdx_bits_value,
  output [7:0] io_diffRat_intRat_0,
  output [7:0] io_diffRat_intRat_1,
  output [7:0] io_diffRat_intRat_2,
  output [7:0] io_diffRat_intRat_3,
  output [7:0] io_diffRat_intRat_4,
  output [7:0] io_diffRat_intRat_5,
  output [7:0] io_diffRat_intRat_6,
  output [7:0] io_diffRat_intRat_7,
  output [7:0] io_diffRat_intRat_8,
  output [7:0] io_diffRat_intRat_9,
  output [7:0] io_diffRat_intRat_10,
  output [7:0] io_diffRat_intRat_11,
  output [7:0] io_diffRat_intRat_12,
  output [7:0] io_diffRat_intRat_13,
  output [7:0] io_diffRat_intRat_14,
  output [7:0] io_diffRat_intRat_15,
  output [7:0] io_diffRat_intRat_16,
  output [7:0] io_diffRat_intRat_17,
  output [7:0] io_diffRat_intRat_18,
  output [7:0] io_diffRat_intRat_19,
  output [7:0] io_diffRat_intRat_20,
  output [7:0] io_diffRat_intRat_21,
  output [7:0] io_diffRat_intRat_22,
  output [7:0] io_diffRat_intRat_23,
  output [7:0] io_diffRat_intRat_24,
  output [7:0] io_diffRat_intRat_25,
  output [7:0] io_diffRat_intRat_26,
  output [7:0] io_diffRat_intRat_27,
  output [7:0] io_diffRat_intRat_28,
  output [7:0] io_diffRat_intRat_29,
  output [7:0] io_diffRat_intRat_30,
  output [7:0] io_diffRat_intRat_31,
  output [7:0] io_diffRat_fpRat_0,
  output [7:0] io_diffRat_fpRat_1,
  output [7:0] io_diffRat_fpRat_2,
  output [7:0] io_diffRat_fpRat_3,
  output [7:0] io_diffRat_fpRat_4,
  output [7:0] io_diffRat_fpRat_5,
  output [7:0] io_diffRat_fpRat_6,
  output [7:0] io_diffRat_fpRat_7,
  output [7:0] io_diffRat_fpRat_8,
  output [7:0] io_diffRat_fpRat_9,
  output [7:0] io_diffRat_fpRat_10,
  output [7:0] io_diffRat_fpRat_11,
  output [7:0] io_diffRat_fpRat_12,
  output [7:0] io_diffRat_fpRat_13,
  output [7:0] io_diffRat_fpRat_14,
  output [7:0] io_diffRat_fpRat_15,
  output [7:0] io_diffRat_fpRat_16,
  output [7:0] io_diffRat_fpRat_17,
  output [7:0] io_diffRat_fpRat_18,
  output [7:0] io_diffRat_fpRat_19,
  output [7:0] io_diffRat_fpRat_20,
  output [7:0] io_diffRat_fpRat_21,
  output [7:0] io_diffRat_fpRat_22,
  output [7:0] io_diffRat_fpRat_23,
  output [7:0] io_diffRat_fpRat_24,
  output [7:0] io_diffRat_fpRat_25,
  output [7:0] io_diffRat_fpRat_26,
  output [7:0] io_diffRat_fpRat_27,
  output [7:0] io_diffRat_fpRat_28,
  output [7:0] io_diffRat_fpRat_29,
  output [7:0] io_diffRat_fpRat_30,
  output [7:0] io_diffRat_fpRat_31,
  output [7:0] io_diffRat_vecRat_0,
  output [7:0] io_diffRat_vecRat_1,
  output [7:0] io_diffRat_vecRat_2,
  output [7:0] io_diffRat_vecRat_3,
  output [7:0] io_diffRat_vecRat_4,
  output [7:0] io_diffRat_vecRat_5,
  output [7:0] io_diffRat_vecRat_6,
  output [7:0] io_diffRat_vecRat_7,
  output [7:0] io_diffRat_vecRat_8,
  output [7:0] io_diffRat_vecRat_9,
  output [7:0] io_diffRat_vecRat_10,
  output [7:0] io_diffRat_vecRat_11,
  output [7:0] io_diffRat_vecRat_12,
  output [7:0] io_diffRat_vecRat_13,
  output [7:0] io_diffRat_vecRat_14,
  output [7:0] io_diffRat_vecRat_15,
  output [7:0] io_diffRat_vecRat_16,
  output [7:0] io_diffRat_vecRat_17,
  output [7:0] io_diffRat_vecRat_18,
  output [7:0] io_diffRat_vecRat_19,
  output [7:0] io_diffRat_vecRat_20,
  output [7:0] io_diffRat_vecRat_21,
  output [7:0] io_diffRat_vecRat_22,
  output [7:0] io_diffRat_vecRat_23,
  output [7:0] io_diffRat_vecRat_24,
  output [7:0] io_diffRat_vecRat_25,
  output [7:0] io_diffRat_vecRat_26,
  output [7:0] io_diffRat_vecRat_27,
  output [7:0] io_diffRat_vecRat_28,
  output [7:0] io_diffRat_vecRat_29,
  output [7:0] io_diffRat_vecRat_30,
  output [7:0] io_diffRat_v0Rat_0,
  output [7:0] io_diffRat_vlRat_0
);
  import diffrat_pkg::*;
  diff_rat_state_t diffRatBase, diffRat;
  diff_rat_update_t [RENAME_W-1:0] renameUpdates;
  logic [RENAME_W-1:0] renameUpdates_valid;
  always_comb begin
    diffRatBase.intRat[0] = io_diffRatBase_intRat_0;
    diffRatBase.intRat[1] = io_diffRatBase_intRat_1;
    diffRatBase.intRat[2] = io_diffRatBase_intRat_2;
    diffRatBase.intRat[3] = io_diffRatBase_intRat_3;
    diffRatBase.intRat[4] = io_diffRatBase_intRat_4;
    diffRatBase.intRat[5] = io_diffRatBase_intRat_5;
    diffRatBase.intRat[6] = io_diffRatBase_intRat_6;
    diffRatBase.intRat[7] = io_diffRatBase_intRat_7;
    diffRatBase.intRat[8] = io_diffRatBase_intRat_8;
    diffRatBase.intRat[9] = io_diffRatBase_intRat_9;
    diffRatBase.intRat[10] = io_diffRatBase_intRat_10;
    diffRatBase.intRat[11] = io_diffRatBase_intRat_11;
    diffRatBase.intRat[12] = io_diffRatBase_intRat_12;
    diffRatBase.intRat[13] = io_diffRatBase_intRat_13;
    diffRatBase.intRat[14] = io_diffRatBase_intRat_14;
    diffRatBase.intRat[15] = io_diffRatBase_intRat_15;
    diffRatBase.intRat[16] = io_diffRatBase_intRat_16;
    diffRatBase.intRat[17] = io_diffRatBase_intRat_17;
    diffRatBase.intRat[18] = io_diffRatBase_intRat_18;
    diffRatBase.intRat[19] = io_diffRatBase_intRat_19;
    diffRatBase.intRat[20] = io_diffRatBase_intRat_20;
    diffRatBase.intRat[21] = io_diffRatBase_intRat_21;
    diffRatBase.intRat[22] = io_diffRatBase_intRat_22;
    diffRatBase.intRat[23] = io_diffRatBase_intRat_23;
    diffRatBase.intRat[24] = io_diffRatBase_intRat_24;
    diffRatBase.intRat[25] = io_diffRatBase_intRat_25;
    diffRatBase.intRat[26] = io_diffRatBase_intRat_26;
    diffRatBase.intRat[27] = io_diffRatBase_intRat_27;
    diffRatBase.intRat[28] = io_diffRatBase_intRat_28;
    diffRatBase.intRat[29] = io_diffRatBase_intRat_29;
    diffRatBase.intRat[30] = io_diffRatBase_intRat_30;
    diffRatBase.intRat[31] = io_diffRatBase_intRat_31;
    diffRatBase.fpRat[0] = io_diffRatBase_fpRat_0;
    diffRatBase.fpRat[1] = io_diffRatBase_fpRat_1;
    diffRatBase.fpRat[2] = io_diffRatBase_fpRat_2;
    diffRatBase.fpRat[3] = io_diffRatBase_fpRat_3;
    diffRatBase.fpRat[4] = io_diffRatBase_fpRat_4;
    diffRatBase.fpRat[5] = io_diffRatBase_fpRat_5;
    diffRatBase.fpRat[6] = io_diffRatBase_fpRat_6;
    diffRatBase.fpRat[7] = io_diffRatBase_fpRat_7;
    diffRatBase.fpRat[8] = io_diffRatBase_fpRat_8;
    diffRatBase.fpRat[9] = io_diffRatBase_fpRat_9;
    diffRatBase.fpRat[10] = io_diffRatBase_fpRat_10;
    diffRatBase.fpRat[11] = io_diffRatBase_fpRat_11;
    diffRatBase.fpRat[12] = io_diffRatBase_fpRat_12;
    diffRatBase.fpRat[13] = io_diffRatBase_fpRat_13;
    diffRatBase.fpRat[14] = io_diffRatBase_fpRat_14;
    diffRatBase.fpRat[15] = io_diffRatBase_fpRat_15;
    diffRatBase.fpRat[16] = io_diffRatBase_fpRat_16;
    diffRatBase.fpRat[17] = io_diffRatBase_fpRat_17;
    diffRatBase.fpRat[18] = io_diffRatBase_fpRat_18;
    diffRatBase.fpRat[19] = io_diffRatBase_fpRat_19;
    diffRatBase.fpRat[20] = io_diffRatBase_fpRat_20;
    diffRatBase.fpRat[21] = io_diffRatBase_fpRat_21;
    diffRatBase.fpRat[22] = io_diffRatBase_fpRat_22;
    diffRatBase.fpRat[23] = io_diffRatBase_fpRat_23;
    diffRatBase.fpRat[24] = io_diffRatBase_fpRat_24;
    diffRatBase.fpRat[25] = io_diffRatBase_fpRat_25;
    diffRatBase.fpRat[26] = io_diffRatBase_fpRat_26;
    diffRatBase.fpRat[27] = io_diffRatBase_fpRat_27;
    diffRatBase.fpRat[28] = io_diffRatBase_fpRat_28;
    diffRatBase.fpRat[29] = io_diffRatBase_fpRat_29;
    diffRatBase.fpRat[30] = io_diffRatBase_fpRat_30;
    diffRatBase.fpRat[31] = io_diffRatBase_fpRat_31;
    diffRatBase.vecRat[0] = io_diffRatBase_vecRat_0;
    diffRatBase.vecRat[1] = io_diffRatBase_vecRat_1;
    diffRatBase.vecRat[2] = io_diffRatBase_vecRat_2;
    diffRatBase.vecRat[3] = io_diffRatBase_vecRat_3;
    diffRatBase.vecRat[4] = io_diffRatBase_vecRat_4;
    diffRatBase.vecRat[5] = io_diffRatBase_vecRat_5;
    diffRatBase.vecRat[6] = io_diffRatBase_vecRat_6;
    diffRatBase.vecRat[7] = io_diffRatBase_vecRat_7;
    diffRatBase.vecRat[8] = io_diffRatBase_vecRat_8;
    diffRatBase.vecRat[9] = io_diffRatBase_vecRat_9;
    diffRatBase.vecRat[10] = io_diffRatBase_vecRat_10;
    diffRatBase.vecRat[11] = io_diffRatBase_vecRat_11;
    diffRatBase.vecRat[12] = io_diffRatBase_vecRat_12;
    diffRatBase.vecRat[13] = io_diffRatBase_vecRat_13;
    diffRatBase.vecRat[14] = io_diffRatBase_vecRat_14;
    diffRatBase.vecRat[15] = io_diffRatBase_vecRat_15;
    diffRatBase.vecRat[16] = io_diffRatBase_vecRat_16;
    diffRatBase.vecRat[17] = io_diffRatBase_vecRat_17;
    diffRatBase.vecRat[18] = io_diffRatBase_vecRat_18;
    diffRatBase.vecRat[19] = io_diffRatBase_vecRat_19;
    diffRatBase.vecRat[20] = io_diffRatBase_vecRat_20;
    diffRatBase.vecRat[21] = io_diffRatBase_vecRat_21;
    diffRatBase.vecRat[22] = io_diffRatBase_vecRat_22;
    diffRatBase.vecRat[23] = io_diffRatBase_vecRat_23;
    diffRatBase.vecRat[24] = io_diffRatBase_vecRat_24;
    diffRatBase.vecRat[25] = io_diffRatBase_vecRat_25;
    diffRatBase.vecRat[26] = io_diffRatBase_vecRat_26;
    diffRatBase.vecRat[27] = io_diffRatBase_vecRat_27;
    diffRatBase.vecRat[28] = io_diffRatBase_vecRat_28;
    diffRatBase.vecRat[29] = io_diffRatBase_vecRat_29;
    diffRatBase.vecRat[30] = io_diffRatBase_vecRat_30;
    diffRatBase.v0Rat[0] = io_diffRatBase_v0Rat_0;
    diffRatBase.vlRat[0] = io_diffRatBase_vlRat_0;
    renameUpdates_valid[0] = io_renameUpdates_0_valid;
    renameUpdates[0].robIdx_flag = io_renameUpdates_0_bits_robIdx_flag;
    renameUpdates[0].robIdx_value = io_renameUpdates_0_bits_robIdx_value;
    renameUpdates[0].lastUop = io_renameUpdates_0_bits_lastUop;
    renameUpdates[0].ldest = io_renameUpdates_0_bits_ldest;
    renameUpdates[0].pdest = io_renameUpdates_0_bits_pdest;
    renameUpdates[0].rfWen = io_renameUpdates_0_bits_rfWen;
    renameUpdates[0].fpWen = io_renameUpdates_0_bits_fpWen;
    renameUpdates[0].vecWen = io_renameUpdates_0_bits_vecWen;
    renameUpdates[0].v0Wen = io_renameUpdates_0_bits_v0Wen;
    renameUpdates[0].vlWen = io_renameUpdates_0_bits_vlWen;
    renameUpdates_valid[1] = io_renameUpdates_1_valid;
    renameUpdates[1].robIdx_flag = io_renameUpdates_1_bits_robIdx_flag;
    renameUpdates[1].robIdx_value = io_renameUpdates_1_bits_robIdx_value;
    renameUpdates[1].lastUop = io_renameUpdates_1_bits_lastUop;
    renameUpdates[1].ldest = io_renameUpdates_1_bits_ldest;
    renameUpdates[1].pdest = io_renameUpdates_1_bits_pdest;
    renameUpdates[1].rfWen = io_renameUpdates_1_bits_rfWen;
    renameUpdates[1].fpWen = io_renameUpdates_1_bits_fpWen;
    renameUpdates[1].vecWen = io_renameUpdates_1_bits_vecWen;
    renameUpdates[1].v0Wen = io_renameUpdates_1_bits_v0Wen;
    renameUpdates[1].vlWen = io_renameUpdates_1_bits_vlWen;
    renameUpdates_valid[2] = io_renameUpdates_2_valid;
    renameUpdates[2].robIdx_flag = io_renameUpdates_2_bits_robIdx_flag;
    renameUpdates[2].robIdx_value = io_renameUpdates_2_bits_robIdx_value;
    renameUpdates[2].lastUop = io_renameUpdates_2_bits_lastUop;
    renameUpdates[2].ldest = io_renameUpdates_2_bits_ldest;
    renameUpdates[2].pdest = io_renameUpdates_2_bits_pdest;
    renameUpdates[2].rfWen = io_renameUpdates_2_bits_rfWen;
    renameUpdates[2].fpWen = io_renameUpdates_2_bits_fpWen;
    renameUpdates[2].vecWen = io_renameUpdates_2_bits_vecWen;
    renameUpdates[2].v0Wen = io_renameUpdates_2_bits_v0Wen;
    renameUpdates[2].vlWen = io_renameUpdates_2_bits_vlWen;
    renameUpdates_valid[3] = io_renameUpdates_3_valid;
    renameUpdates[3].robIdx_flag = io_renameUpdates_3_bits_robIdx_flag;
    renameUpdates[3].robIdx_value = io_renameUpdates_3_bits_robIdx_value;
    renameUpdates[3].lastUop = io_renameUpdates_3_bits_lastUop;
    renameUpdates[3].ldest = io_renameUpdates_3_bits_ldest;
    renameUpdates[3].pdest = io_renameUpdates_3_bits_pdest;
    renameUpdates[3].rfWen = io_renameUpdates_3_bits_rfWen;
    renameUpdates[3].fpWen = io_renameUpdates_3_bits_fpWen;
    renameUpdates[3].vecWen = io_renameUpdates_3_bits_vecWen;
    renameUpdates[3].v0Wen = io_renameUpdates_3_bits_v0Wen;
    renameUpdates[3].vlWen = io_renameUpdates_3_bits_vlWen;
    renameUpdates_valid[4] = io_renameUpdates_4_valid;
    renameUpdates[4].robIdx_flag = io_renameUpdates_4_bits_robIdx_flag;
    renameUpdates[4].robIdx_value = io_renameUpdates_4_bits_robIdx_value;
    renameUpdates[4].lastUop = io_renameUpdates_4_bits_lastUop;
    renameUpdates[4].ldest = io_renameUpdates_4_bits_ldest;
    renameUpdates[4].pdest = io_renameUpdates_4_bits_pdest;
    renameUpdates[4].rfWen = io_renameUpdates_4_bits_rfWen;
    renameUpdates[4].fpWen = io_renameUpdates_4_bits_fpWen;
    renameUpdates[4].vecWen = io_renameUpdates_4_bits_vecWen;
    renameUpdates[4].v0Wen = io_renameUpdates_4_bits_v0Wen;
    renameUpdates[4].vlWen = io_renameUpdates_4_bits_vlWen;
    renameUpdates_valid[5] = io_renameUpdates_5_valid;
    renameUpdates[5].robIdx_flag = io_renameUpdates_5_bits_robIdx_flag;
    renameUpdates[5].robIdx_value = io_renameUpdates_5_bits_robIdx_value;
    renameUpdates[5].lastUop = io_renameUpdates_5_bits_lastUop;
    renameUpdates[5].ldest = io_renameUpdates_5_bits_ldest;
    renameUpdates[5].pdest = io_renameUpdates_5_bits_pdest;
    renameUpdates[5].rfWen = io_renameUpdates_5_bits_rfWen;
    renameUpdates[5].fpWen = io_renameUpdates_5_bits_fpWen;
    renameUpdates[5].vecWen = io_renameUpdates_5_bits_vecWen;
    renameUpdates[5].v0Wen = io_renameUpdates_5_bits_v0Wen;
    renameUpdates[5].vlWen = io_renameUpdates_5_bits_vlWen;
  end
  assign io_diffRat_intRat_0 = diffRat.intRat[0];
  assign io_diffRat_intRat_1 = diffRat.intRat[1];
  assign io_diffRat_intRat_2 = diffRat.intRat[2];
  assign io_diffRat_intRat_3 = diffRat.intRat[3];
  assign io_diffRat_intRat_4 = diffRat.intRat[4];
  assign io_diffRat_intRat_5 = diffRat.intRat[5];
  assign io_diffRat_intRat_6 = diffRat.intRat[6];
  assign io_diffRat_intRat_7 = diffRat.intRat[7];
  assign io_diffRat_intRat_8 = diffRat.intRat[8];
  assign io_diffRat_intRat_9 = diffRat.intRat[9];
  assign io_diffRat_intRat_10 = diffRat.intRat[10];
  assign io_diffRat_intRat_11 = diffRat.intRat[11];
  assign io_diffRat_intRat_12 = diffRat.intRat[12];
  assign io_diffRat_intRat_13 = diffRat.intRat[13];
  assign io_diffRat_intRat_14 = diffRat.intRat[14];
  assign io_diffRat_intRat_15 = diffRat.intRat[15];
  assign io_diffRat_intRat_16 = diffRat.intRat[16];
  assign io_diffRat_intRat_17 = diffRat.intRat[17];
  assign io_diffRat_intRat_18 = diffRat.intRat[18];
  assign io_diffRat_intRat_19 = diffRat.intRat[19];
  assign io_diffRat_intRat_20 = diffRat.intRat[20];
  assign io_diffRat_intRat_21 = diffRat.intRat[21];
  assign io_diffRat_intRat_22 = diffRat.intRat[22];
  assign io_diffRat_intRat_23 = diffRat.intRat[23];
  assign io_diffRat_intRat_24 = diffRat.intRat[24];
  assign io_diffRat_intRat_25 = diffRat.intRat[25];
  assign io_diffRat_intRat_26 = diffRat.intRat[26];
  assign io_diffRat_intRat_27 = diffRat.intRat[27];
  assign io_diffRat_intRat_28 = diffRat.intRat[28];
  assign io_diffRat_intRat_29 = diffRat.intRat[29];
  assign io_diffRat_intRat_30 = diffRat.intRat[30];
  assign io_diffRat_intRat_31 = diffRat.intRat[31];
  assign io_diffRat_fpRat_0 = diffRat.fpRat[0];
  assign io_diffRat_fpRat_1 = diffRat.fpRat[1];
  assign io_diffRat_fpRat_2 = diffRat.fpRat[2];
  assign io_diffRat_fpRat_3 = diffRat.fpRat[3];
  assign io_diffRat_fpRat_4 = diffRat.fpRat[4];
  assign io_diffRat_fpRat_5 = diffRat.fpRat[5];
  assign io_diffRat_fpRat_6 = diffRat.fpRat[6];
  assign io_diffRat_fpRat_7 = diffRat.fpRat[7];
  assign io_diffRat_fpRat_8 = diffRat.fpRat[8];
  assign io_diffRat_fpRat_9 = diffRat.fpRat[9];
  assign io_diffRat_fpRat_10 = diffRat.fpRat[10];
  assign io_diffRat_fpRat_11 = diffRat.fpRat[11];
  assign io_diffRat_fpRat_12 = diffRat.fpRat[12];
  assign io_diffRat_fpRat_13 = diffRat.fpRat[13];
  assign io_diffRat_fpRat_14 = diffRat.fpRat[14];
  assign io_diffRat_fpRat_15 = diffRat.fpRat[15];
  assign io_diffRat_fpRat_16 = diffRat.fpRat[16];
  assign io_diffRat_fpRat_17 = diffRat.fpRat[17];
  assign io_diffRat_fpRat_18 = diffRat.fpRat[18];
  assign io_diffRat_fpRat_19 = diffRat.fpRat[19];
  assign io_diffRat_fpRat_20 = diffRat.fpRat[20];
  assign io_diffRat_fpRat_21 = diffRat.fpRat[21];
  assign io_diffRat_fpRat_22 = diffRat.fpRat[22];
  assign io_diffRat_fpRat_23 = diffRat.fpRat[23];
  assign io_diffRat_fpRat_24 = diffRat.fpRat[24];
  assign io_diffRat_fpRat_25 = diffRat.fpRat[25];
  assign io_diffRat_fpRat_26 = diffRat.fpRat[26];
  assign io_diffRat_fpRat_27 = diffRat.fpRat[27];
  assign io_diffRat_fpRat_28 = diffRat.fpRat[28];
  assign io_diffRat_fpRat_29 = diffRat.fpRat[29];
  assign io_diffRat_fpRat_30 = diffRat.fpRat[30];
  assign io_diffRat_fpRat_31 = diffRat.fpRat[31];
  assign io_diffRat_vecRat_0 = diffRat.vecRat[0];
  assign io_diffRat_vecRat_1 = diffRat.vecRat[1];
  assign io_diffRat_vecRat_2 = diffRat.vecRat[2];
  assign io_diffRat_vecRat_3 = diffRat.vecRat[3];
  assign io_diffRat_vecRat_4 = diffRat.vecRat[4];
  assign io_diffRat_vecRat_5 = diffRat.vecRat[5];
  assign io_diffRat_vecRat_6 = diffRat.vecRat[6];
  assign io_diffRat_vecRat_7 = diffRat.vecRat[7];
  assign io_diffRat_vecRat_8 = diffRat.vecRat[8];
  assign io_diffRat_vecRat_9 = diffRat.vecRat[9];
  assign io_diffRat_vecRat_10 = diffRat.vecRat[10];
  assign io_diffRat_vecRat_11 = diffRat.vecRat[11];
  assign io_diffRat_vecRat_12 = diffRat.vecRat[12];
  assign io_diffRat_vecRat_13 = diffRat.vecRat[13];
  assign io_diffRat_vecRat_14 = diffRat.vecRat[14];
  assign io_diffRat_vecRat_15 = diffRat.vecRat[15];
  assign io_diffRat_vecRat_16 = diffRat.vecRat[16];
  assign io_diffRat_vecRat_17 = diffRat.vecRat[17];
  assign io_diffRat_vecRat_18 = diffRat.vecRat[18];
  assign io_diffRat_vecRat_19 = diffRat.vecRat[19];
  assign io_diffRat_vecRat_20 = diffRat.vecRat[20];
  assign io_diffRat_vecRat_21 = diffRat.vecRat[21];
  assign io_diffRat_vecRat_22 = diffRat.vecRat[22];
  assign io_diffRat_vecRat_23 = diffRat.vecRat[23];
  assign io_diffRat_vecRat_24 = diffRat.vecRat[24];
  assign io_diffRat_vecRat_25 = diffRat.vecRat[25];
  assign io_diffRat_vecRat_26 = diffRat.vecRat[26];
  assign io_diffRat_vecRat_27 = diffRat.vecRat[27];
  assign io_diffRat_vecRat_28 = diffRat.vecRat[28];
  assign io_diffRat_vecRat_29 = diffRat.vecRat[29];
  assign io_diffRat_vecRat_30 = diffRat.vecRat[30];
  assign io_diffRat_v0Rat_0 = diffRat.v0Rat[0];
  assign io_diffRat_vlRat_0 = diffRat.vlRat[0];
  xs_DiffRatStateBuffer_core u_core (
    .clock               (clock),
    .reset               (reset),
    .diffRatBase         (diffRatBase),
    .renameUpdates_valid (renameUpdates_valid),
    .renameUpdates       (renameUpdates),
    .commitRobIdx_valid  (io_commitRobIdx_valid),
    .commitRobIdx_flag   (io_commitRobIdx_bits_flag),
    .commitRobIdx_value  (io_commitRobIdx_bits_value),
    .diffRat             (diffRat)
  );
endmodule
// END GENERATED
