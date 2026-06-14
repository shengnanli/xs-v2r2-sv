// =============================================================================
// xs_FauFTB_core —— uFTB（Fast FTB，全相联微 FTB）预测器核
//
// 对应 Chisel: xiangshan.frontend.FauFTB (extends BasePredictor)
//
// 结构：
//   - NUM_WAYS 路全相联 FauFTBWay（每路寄存一个 FTB 条目 + tag + valid）。
//   - 预测 (s1)：用 s1_pc 的 tag 并行查询所有路 → one-hot 命中 → Mux1H 合成
//     FullBranchPrediction（fromFtbEntry：目标地址、fallThrough、is_jal/jalr/...）。
//   - 更新 (s0→s1 两级)：tag 比较命中则更新该路，否则 PLRU 选一路替换写入；
//     同时按 br_taken 更新 2bit 饱和计数器 ctrs。
//   - PLRU 替换器：state_reg 为二叉树状态（NUM_WAYS-1 位）。
//   - s1_pc / fauftb_enable / meta 等流水透传。
//
// 端口与 Chisel 生成 RTL（golden FauFTB.sv）完全一致（io_* 扁平命名），子模块
// FauFTBWay 复用 golden 同名 wrapper（其内部用 xs_FauFTBWay 核）。
//
// 注：golden 含被 firtool 保留但无观测路径的 s2_pc/s3_pc 流水寄存器、断言块与
// 性能计数 _probe 中间量；它们对所有模块输出无影响（unread compare point），故本核
// 不实现。FM 已设 verification_verify_unread_compare_points=false。
// =============================================================================
module xs_FauFTB_core #(
  parameter int unsigned NUM_WAYS  = 32,
  parameter int unsigned NUM_BR    = 2,
  parameter int unsigned TAG_W     = 16,
  parameter int unsigned PC_W      = 50,
  parameter int unsigned RV_W      = 48,  // reset_vector 宽度
  parameter int unsigned META_W    = 516
)(
  input  logic                clock,
  input  logic                reset,
  input  logic [RV_W-1:0]     io_reset_vector,

  // ---- 预测输入流水（s0_pc 四份 dup） ----
  input  logic [PC_W-1:0]     io_in_bits_s0_pc_0,
  input  logic [PC_W-1:0]     io_in_bits_s0_pc_1,
  input  logic [PC_W-1:0]     io_in_bits_s0_pc_2,
  input  logic [PC_W-1:0]     io_in_bits_s0_pc_3,

  // ---- 预测输出 s1：四份 dup，但内容完全相同（fromFtbEntry of hit way） ----
  output logic [PC_W-1:0]     io_out_s1_pc_0,
  output logic [PC_W-1:0]     io_out_s1_pc_1,
  output logic [PC_W-1:0]     io_out_s1_pc_2,
  output logic [PC_W-1:0]     io_out_s1_pc_3,

  // full_pred 字段（一份逻辑值，输出到 4 个 dup）
  output logic                fp_br_taken_mask_0,
  output logic                fp_br_taken_mask_1,
  output logic                fp_slot_valids_0,
  output logic                fp_slot_valids_1,
  output logic [PC_W-1:0]     fp_targets_0,
  output logic [PC_W-1:0]     fp_targets_1,
  output logic [PC_W-1:0]     fp_jalr_target,
  output logic [3:0]          fp_offsets_0,
  output logic [3:0]          fp_offsets_1,
  output logic [PC_W-1:0]     fp_fallThroughAddr,
  output logic                fp_fallThroughErr,
  output logic                fp_is_jal,
  output logic                fp_is_jalr,
  output logic                fp_is_call,
  output logic                fp_is_ret,
  output logic                fp_last_may_be_rvi_call,
  output logic                fp_is_br_sharing,
  output logic                fp_hit,

  output logic [META_W-1:0]   io_out_last_stage_meta,

  // ---- fauftb_entry_out：命中路原始 FauFTBEntry（Mux1H 字段） ----
  output logic                io_fauftb_entry_out_isCall,
  output logic                io_fauftb_entry_out_isRet,
  output logic                io_fauftb_entry_out_isJalr,
  output logic                io_fauftb_entry_out_valid,
  output logic [3:0]          io_fauftb_entry_out_brSlots_0_offset,
  output logic                io_fauftb_entry_out_brSlots_0_sharing,
  output logic                io_fauftb_entry_out_brSlots_0_valid,
  output logic [11:0]         io_fauftb_entry_out_brSlots_0_lower,
  output logic [1:0]          io_fauftb_entry_out_brSlots_0_tarStat,
  output logic [3:0]          io_fauftb_entry_out_tailSlot_offset,
  output logic                io_fauftb_entry_out_tailSlot_sharing,
  output logic                io_fauftb_entry_out_tailSlot_valid,
  output logic [19:0]         io_fauftb_entry_out_tailSlot_lower,
  output logic [1:0]          io_fauftb_entry_out_tailSlot_tarStat,
  output logic [3:0]          io_fauftb_entry_out_pftAddr,
  output logic                io_fauftb_entry_out_carry,
  output logic                io_fauftb_entry_out_last_may_be_rvi_call,
  output logic                io_fauftb_entry_out_strong_bias_0,
  output logic                io_fauftb_entry_out_strong_bias_1,
  output logic                io_fauftb_entry_hit_out,

  // ---- 控制 / fire ----
  input  logic                io_ctrl_ubtb_enable,
  input  logic                io_s0_fire_0,
  input  logic                io_s0_fire_1,
  input  logic                io_s0_fire_2,
  input  logic                io_s0_fire_3,
  input  logic                io_s1_fire_0,
  input  logic                io_s1_fire_1,
  input  logic                io_s1_fire_2,
  input  logic                io_s1_fire_3,
  input  logic                io_s2_fire_0,
  input  logic                io_s2_fire_1,
  input  logic                io_s2_fire_2,
  input  logic                io_s2_fire_3,

  // ---- 更新输入 ----
  input  logic                io_update_valid,
  input  logic [PC_W-1:0]     io_update_bits_pc,
  input  logic                io_update_bits_ftb_entry_isCall,
  input  logic                io_update_bits_ftb_entry_isRet,
  input  logic                io_update_bits_ftb_entry_isJalr,
  input  logic                io_update_bits_ftb_entry_valid,
  input  logic [3:0]          io_update_bits_ftb_entry_brSlots_0_offset,
  input  logic                io_update_bits_ftb_entry_brSlots_0_sharing,
  input  logic                io_update_bits_ftb_entry_brSlots_0_valid,
  input  logic [11:0]         io_update_bits_ftb_entry_brSlots_0_lower,
  input  logic [1:0]          io_update_bits_ftb_entry_brSlots_0_tarStat,
  input  logic [3:0]          io_update_bits_ftb_entry_tailSlot_offset,
  input  logic                io_update_bits_ftb_entry_tailSlot_sharing,
  input  logic                io_update_bits_ftb_entry_tailSlot_valid,
  input  logic [19:0]         io_update_bits_ftb_entry_tailSlot_lower,
  input  logic [1:0]          io_update_bits_ftb_entry_tailSlot_tarStat,
  input  logic [3:0]          io_update_bits_ftb_entry_pftAddr,
  input  logic                io_update_bits_ftb_entry_carry,
  input  logic                io_update_bits_ftb_entry_last_may_be_rvi_call,
  input  logic                io_update_bits_ftb_entry_strong_bias_0,
  input  logic                io_update_bits_ftb_entry_strong_bias_1,
  input  logic                io_update_bits_br_taken_mask_0,
  input  logic                io_update_bits_br_taken_mask_1,
  input  logic [META_W-1:0]   io_update_bits_meta,

  // ---- perf ----
  output logic [5:0]          io_perf_0_value,
  output logic [5:0]          io_perf_1_value
);

  localparam int WAY_IDX_W = $clog2(NUM_WAYS);   // 5

  // ===========================================================================
  // s1_pc 流水透传（4 dup）
  //   复位释放后第一拍把 reset_vector 写入；否则 s0_fire 时载入 s0_pc。
  // ===========================================================================
  logic [PC_W-1:0] s1_pc_dup_0, s1_pc_dup_1, s1_pc_dup_2, s1_pc_dup_3;
  logic            reg_rst_d0, reg_rst_d1;   // golden: REG / REG_1
  wire  [PC_W-1:0] reset_pc = {{(PC_W-RV_W){1'b0}}, io_reset_vector};

  always_ff @(posedge clock) begin
    if (reg_rst_d1) begin
      s1_pc_dup_0 <= reset_pc;
      s1_pc_dup_1 <= reset_pc;
      s1_pc_dup_2 <= reset_pc;
      s1_pc_dup_3 <= reset_pc;
    end else begin
      if (io_s0_fire_0) s1_pc_dup_0 <= io_in_bits_s0_pc_0;
      if (io_s0_fire_1) s1_pc_dup_1 <= io_in_bits_s0_pc_1;
      if (io_s0_fire_2) s1_pc_dup_2 <= io_in_bits_s0_pc_2;
      if (io_s0_fire_3) s1_pc_dup_3 <= io_in_bits_s0_pc_3;
    end
    reg_rst_d0 <= reset;
    reg_rst_d1 <= reg_rst_d0 & ~reset;
  end

  assign io_out_s1_pc_0 = s1_pc_dup_0;
  assign io_out_s1_pc_1 = s1_pc_dup_1;
  assign io_out_s1_pc_2 = s1_pc_dup_2;
  assign io_out_s1_pc_3 = s1_pc_dup_3;

  // ===========================================================================
  // 更新流水 s0：寄存 update 请求（u_valid / u_bits_*）
  // ===========================================================================
  logic        u_valid;
  logic        u_bits_ftb_entry_isCall, u_bits_ftb_entry_isRet, u_bits_ftb_entry_isJalr;
  logic        u_bits_ftb_entry_valid;
  logic [3:0]  u_bits_ftb_entry_brSlots_0_offset;
  logic        u_bits_ftb_entry_brSlots_0_sharing, u_bits_ftb_entry_brSlots_0_valid;
  logic [11:0] u_bits_ftb_entry_brSlots_0_lower;
  logic [1:0]  u_bits_ftb_entry_brSlots_0_tarStat;
  logic [3:0]  u_bits_ftb_entry_tailSlot_offset;
  logic        u_bits_ftb_entry_tailSlot_sharing, u_bits_ftb_entry_tailSlot_valid;
  logic [19:0] u_bits_ftb_entry_tailSlot_lower;
  logic [1:0]  u_bits_ftb_entry_tailSlot_tarStat;
  logic [3:0]  u_bits_ftb_entry_pftAddr;
  logic        u_bits_ftb_entry_carry, u_bits_ftb_entry_last_may_be_rvi_call;
  logic        u_bits_ftb_entry_strong_bias_0, u_bits_ftb_entry_strong_bias_1;
  logic        u_bits_br_taken_mask_0, u_bits_br_taken_mask_1;
  logic [META_W-1:0] u_bits_meta;

  // ===========================================================================
  // 32 路 FauFTBWay 例化 + 命中向量
  // ===========================================================================
  // per-way resp 字段
  logic               w_resp_isCall   [NUM_WAYS];
  logic               w_resp_isRet    [NUM_WAYS];
  logic               w_resp_isJalr   [NUM_WAYS];
  logic               w_resp_valid    [NUM_WAYS];
  logic [3:0]         w_resp_brOff    [NUM_WAYS];
  logic               w_resp_brShar   [NUM_WAYS];
  logic               w_resp_brVal    [NUM_WAYS];
  logic [11:0]        w_resp_brLow    [NUM_WAYS];
  logic [1:0]         w_resp_brTar    [NUM_WAYS];
  logic [3:0]         w_resp_tailOff  [NUM_WAYS];
  logic               w_resp_tailShar [NUM_WAYS];
  logic               w_resp_tailVal  [NUM_WAYS];
  logic [19:0]        w_resp_tailLow  [NUM_WAYS];
  logic [1:0]         w_resp_tailTar  [NUM_WAYS];
  logic [3:0]         w_resp_pftAddr  [NUM_WAYS];
  logic               w_resp_carry    [NUM_WAYS];
  logic               w_resp_lmbrc    [NUM_WAYS];
  logic               w_resp_sb0      [NUM_WAYS];
  logic               w_resp_sb1      [NUM_WAYS];
  logic               w_resp_hit      [NUM_WAYS];
  logic               w_update_hit    [NUM_WAYS];

  // 更新写使能 / counters 更新有效（s1 级）
  logic               u_s1_ways_write_valid [NUM_WAYS];
  logic [1:0]         ctrs [NUM_WAYS][NUM_BR];

  // s1 写信息
  logic [TAG_W-1:0]   u_s1_tag;
  logic               u_s1_ftb_entry_isCall, u_s1_ftb_entry_isRet, u_s1_ftb_entry_isJalr;
  logic               u_s1_ftb_entry_valid;
  logic [3:0]         u_s1_ftb_entry_brSlots_0_offset;
  logic               u_s1_ftb_entry_brSlots_0_sharing, u_s1_ftb_entry_brSlots_0_valid;
  logic [11:0]        u_s1_ftb_entry_brSlots_0_lower;
  logic [1:0]         u_s1_ftb_entry_brSlots_0_tarStat;
  logic [3:0]         u_s1_ftb_entry_tailSlot_offset;
  logic               u_s1_ftb_entry_tailSlot_sharing, u_s1_ftb_entry_tailSlot_valid;
  logic [19:0]        u_s1_ftb_entry_tailSlot_lower;
  logic [1:0]         u_s1_ftb_entry_tailSlot_tarStat;
  logic [3:0]         u_s1_ftb_entry_pftAddr;
  logic               u_s1_ftb_entry_carry, u_s1_ftb_entry_last_may_be_rvi_call;
  logic               u_s1_ftb_entry_strong_bias_0, u_s1_ftb_entry_strong_bias_1;

  wire  [TAG_W-1:0]   pred_tag   = s1_pc_dup_0[TAG_W:1];
  wire  [TAG_W-1:0]   update_tag = io_update_bits_pc[TAG_W:1];

  genvar gw;
  generate
    for (gw = 0; gw < NUM_WAYS; gw++) begin : g_ways
      FauFTBWay ways (
        .clock                               (clock),
        .reset                               (reset),
        .io_req_tag                          (pred_tag),
        .io_resp_isCall                      (w_resp_isCall[gw]),
        .io_resp_isRet                       (w_resp_isRet[gw]),
        .io_resp_isJalr                      (w_resp_isJalr[gw]),
        .io_resp_valid                       (w_resp_valid[gw]),
        .io_resp_brSlots_0_offset            (w_resp_brOff[gw]),
        .io_resp_brSlots_0_sharing           (w_resp_brShar[gw]),
        .io_resp_brSlots_0_valid             (w_resp_brVal[gw]),
        .io_resp_brSlots_0_lower             (w_resp_brLow[gw]),
        .io_resp_brSlots_0_tarStat           (w_resp_brTar[gw]),
        .io_resp_tailSlot_offset             (w_resp_tailOff[gw]),
        .io_resp_tailSlot_sharing            (w_resp_tailShar[gw]),
        .io_resp_tailSlot_valid              (w_resp_tailVal[gw]),
        .io_resp_tailSlot_lower              (w_resp_tailLow[gw]),
        .io_resp_tailSlot_tarStat            (w_resp_tailTar[gw]),
        .io_resp_pftAddr                     (w_resp_pftAddr[gw]),
        .io_resp_carry                       (w_resp_carry[gw]),
        .io_resp_last_may_be_rvi_call        (w_resp_lmbrc[gw]),
        .io_resp_strong_bias_0               (w_resp_sb0[gw]),
        .io_resp_strong_bias_1               (w_resp_sb1[gw]),
        .io_resp_hit                         (w_resp_hit[gw]),
        .io_update_req_tag                   (update_tag),
        .io_update_hit                       (w_update_hit[gw]),
        .io_write_valid                      (u_s1_ways_write_valid[gw]),
        .io_write_entry_isCall               (u_s1_ftb_entry_isCall),
        .io_write_entry_isRet                (u_s1_ftb_entry_isRet),
        .io_write_entry_isJalr               (u_s1_ftb_entry_isJalr),
        .io_write_entry_valid                (u_s1_ftb_entry_valid),
        .io_write_entry_brSlots_0_offset     (u_s1_ftb_entry_brSlots_0_offset),
        .io_write_entry_brSlots_0_sharing    (u_s1_ftb_entry_brSlots_0_sharing),
        .io_write_entry_brSlots_0_valid      (u_s1_ftb_entry_brSlots_0_valid),
        .io_write_entry_brSlots_0_lower      (u_s1_ftb_entry_brSlots_0_lower),
        .io_write_entry_brSlots_0_tarStat    (u_s1_ftb_entry_brSlots_0_tarStat),
        .io_write_entry_tailSlot_offset      (u_s1_ftb_entry_tailSlot_offset),
        .io_write_entry_tailSlot_sharing     (u_s1_ftb_entry_tailSlot_sharing),
        .io_write_entry_tailSlot_valid       (u_s1_ftb_entry_tailSlot_valid),
        .io_write_entry_tailSlot_lower       (u_s1_ftb_entry_tailSlot_lower),
        .io_write_entry_tailSlot_tarStat     (u_s1_ftb_entry_tailSlot_tarStat),
        .io_write_entry_pftAddr              (u_s1_ftb_entry_pftAddr),
        .io_write_entry_carry                (u_s1_ftb_entry_carry),
        .io_write_entry_last_may_be_rvi_call (u_s1_ftb_entry_last_may_be_rvi_call),
        .io_write_entry_strong_bias_0        (u_s1_ftb_entry_strong_bias_0),
        .io_write_entry_strong_bias_1        (u_s1_ftb_entry_strong_bias_1),
        .io_write_tag                        (u_s1_tag)
      );
    end
  endgenerate

  // 命中向量
  logic [NUM_WAYS-1:0] s1_hit_oh, u_s0_hit_oh;
  always_comb begin
    for (int i = 0; i < NUM_WAYS; i++) begin
      s1_hit_oh[i]   = w_resp_hit[i];
      u_s0_hit_oh[i] = w_update_hit[i];
    end
  end
  wire s1_hit = |s1_hit_oh;

  // OHToUInt：one-hot → 二进制（按位 OR 命中索引）
  logic [WAY_IDX_W-1:0] s1_hit_way;
  always_comb begin
    s1_hit_way = '0;
    for (int b = 0; b < WAY_IDX_W; b++) begin
      logic acc;
      acc = 1'b0;
      for (int i = 0; i < NUM_WAYS; i++)
        if (i[b]) acc = acc | s1_hit_oh[i];
      s1_hit_way[b] = acc;
    end
  end

  // ===========================================================================
  // fromFtbEntry：每路把 FauFTBEntry 解码为 FullBranchPrediction 字段
  //   再用 s1_hit_oh 做 Mux1H（命中为一热，OR 形式）。
  // ===========================================================================
  // 高位部分（与 golden 完全一致的位宽计算）
  wire [36:0] higher_plus_one_br  = s1_pc_dup_0[49:13] + 37'h1;
  wire [36:0] higher_minus_one_br = s1_pc_dup_0[49:13] - 37'h1;
  wire [44:0] pft_hi_plus_one     = s1_pc_dup_0[49:5] + 45'h1;   // for fallThrough
  wire [28:0] tail_hi_plus_one    = s1_pc_dup_0[49:21] + 29'h1;  // tail target non-sharing
  wire [28:0] tail_hi_minus_one   = s1_pc_dup_0[49:21] - 29'h1;
  wire [PC_W-1:0] fallThroughAddr_ovf = s1_pc_dup_0 + 50'h20;
  wire [4:0]  startLowerHalf = {1'b0, s1_pc_dup_0[4:1]};         // _GEN

  // 每路解码
  logic               p_is_br_sharing   [NUM_WAYS];
  logic               p_last_may_rvi    [NUM_WAYS];
  logic               p_is_ret          [NUM_WAYS];
  logic               p_is_call         [NUM_WAYS];
  logic               p_is_jalr         [NUM_WAYS];
  logic               p_is_jal          [NUM_WAYS];
  logic               p_fallThroughErr  [NUM_WAYS];
  logic [PC_W-1:0]    p_fallThroughAddr [NUM_WAYS];
  logic [PC_W-1:0]    p_jalr_target     [NUM_WAYS];  // tail target (50b)
  logic [3:0]         p_offsets_0       [NUM_WAYS];
  logic [3:0]         p_offsets_1       [NUM_WAYS];
  logic [PC_W-1:0]    p_targets_0       [NUM_WAYS];  // br slot target
  logic [PC_W-1:0]    p_targets_1       [NUM_WAYS];  // tail target (== jalr_target)
  logic               p_slot_valids_0   [NUM_WAYS];
  logic               p_slot_valids_1   [NUM_WAYS];
  logic               p_br_taken_0      [NUM_WAYS];
  logic               p_br_taken_1      [NUM_WAYS];

  generate
    for (gw = 0; gw < NUM_WAYS; gw++) begin : g_decode
      wire [4:0] endLowerWithCarry = {w_resp_carry[gw], w_resp_pftAddr[gw]};
      // tail slot target (sharing → low 12 bits replaced; else 20 bits)
      wire [36:0] tail_hi_share =
          (w_resp_tailTar[gw] == 2'h1 ? higher_plus_one_br  : 37'h0)
        | (w_resp_tailTar[gw] == 2'h2 ? higher_minus_one_br : 37'h0)
        | (w_resp_tailTar[gw] == 2'h0 ? s1_pc_dup_0[49:13]  : 37'h0);
      wire [28:0] tail_hi_nshare =
          (w_resp_tailTar[gw] == 2'h1 ? tail_hi_plus_one  : 29'h0)
        | (w_resp_tailTar[gw] == 2'h2 ? tail_hi_minus_one : 29'h0)
        | (w_resp_tailTar[gw] == 2'h0 ? s1_pc_dup_0[49:21] : 29'h0);
      wire [PC_W-1:0] tail_target =
          { (w_resp_tailShar[gw] ? {tail_hi_share, w_resp_tailLow[gw][11:0]}
                                 : {tail_hi_nshare, w_resp_tailLow[gw]}), 1'b0 };

      // br slot target
      wire [36:0] br_hi =
          (w_resp_brTar[gw] == 2'h1 ? higher_plus_one_br  : 37'h0)
        | (w_resp_brTar[gw] == 2'h2 ? higher_minus_one_br : 37'h0)
        | (w_resp_brTar[gw] == 2'h0 ? s1_pc_dup_0[49:13]  : 37'h0);

      assign p_targets_0[gw]      = {br_hi, w_resp_brLow[gw], 1'b0};
      assign p_targets_1[gw]      = tail_target;
      assign p_jalr_target[gw]    = tail_target;

      assign p_fallThroughErr[gw] =
          (startLowerHalf >= endLowerWithCarry) |
          (endLowerWithCarry > (startLowerHalf - 5'h10));
      assign p_fallThroughAddr[gw] =
          p_fallThroughErr[gw] ? fallThroughAddr_ovf
                               : {(w_resp_carry[gw] ? pft_hi_plus_one : s1_pc_dup_0[49:5]),
                                  w_resp_pftAddr[gw], 1'b0};

      assign p_is_br_sharing[gw] = w_resp_tailVal[gw] & w_resp_tailShar[gw];
      assign p_last_may_rvi[gw]  = w_resp_lmbrc[gw];
      assign p_is_ret[gw]        = w_resp_tailVal[gw] & w_resp_isRet[gw];
      assign p_is_call[gw]       = w_resp_tailVal[gw] & w_resp_isCall[gw];
      assign p_is_jalr[gw]       = w_resp_tailVal[gw] & w_resp_isJalr[gw];
      assign p_is_jal[gw]        = w_resp_tailVal[gw] & ~w_resp_isJalr[gw];
      assign p_offsets_0[gw]     = w_resp_brOff[gw];
      assign p_offsets_1[gw]     = w_resp_tailOff[gw];
      assign p_slot_valids_0[gw] = w_resp_brVal[gw];
      assign p_slot_valids_1[gw] = w_resp_tailVal[gw];
      assign p_br_taken_0[gw]    = ctrs[gw][0][1] | w_resp_sb0[gw];
      assign p_br_taken_1[gw]    = ctrs[gw][1][1] | w_resp_sb1[gw];
    end
  endgenerate

  // Mux1H 合成（hit 一热 → OR）
  logic            m_is_br_sharing, m_last_may_rvi, m_is_ret, m_is_call, m_is_jalr, m_is_jal;
  logic            m_fallThroughErr, m_slot_valids_0, m_slot_valids_1, m_br_taken_0, m_br_taken_1;
  logic [PC_W-1:0] m_fallThroughAddr, m_jalr_target, m_targets_0, m_targets_1;
  logic [3:0]      m_offsets_0, m_offsets_1;
  // fauftb_entry_out raw fields
  logic            e_isCall, e_isRet, e_isJalr, e_valid;
  logic [3:0]      e_brOff;  logic e_brShar, e_brVal;  logic [11:0] e_brLow;  logic [1:0] e_brTar;
  logic [3:0]      e_tailOff; logic e_tailShar, e_tailVal; logic [19:0] e_tailLow; logic [1:0] e_tailTar;
  logic [3:0]      e_pftAddr; logic e_carry, e_lmbrc, e_sb0, e_sb1;

  always_comb begin
    m_is_br_sharing  = 1'b0; m_last_may_rvi = 1'b0; m_is_ret = 1'b0; m_is_call = 1'b0;
    m_is_jalr = 1'b0; m_is_jal = 1'b0; m_fallThroughErr = 1'b0;
    m_slot_valids_0 = 1'b0; m_slot_valids_1 = 1'b0; m_br_taken_0 = 1'b0; m_br_taken_1 = 1'b0;
    m_fallThroughAddr = '0; m_jalr_target = '0; m_targets_0 = '0; m_targets_1 = '0;
    m_offsets_0 = '0; m_offsets_1 = '0;
    e_isCall='0; e_isRet='0; e_isJalr='0; e_valid='0;
    e_brOff='0; e_brShar='0; e_brVal='0; e_brLow='0; e_brTar='0;
    e_tailOff='0; e_tailShar='0; e_tailVal='0; e_tailLow='0; e_tailTar='0;
    e_pftAddr='0; e_carry='0; e_lmbrc='0; e_sb0='0; e_sb1='0;
    for (int i = 0; i < NUM_WAYS; i++) begin
      if (w_resp_hit[i]) begin
        m_is_br_sharing   = m_is_br_sharing   | p_is_br_sharing[i];
        m_last_may_rvi    = m_last_may_rvi    | p_last_may_rvi[i];
        m_is_ret          = m_is_ret          | p_is_ret[i];
        m_is_call         = m_is_call         | p_is_call[i];
        m_is_jalr         = m_is_jalr         | p_is_jalr[i];
        m_is_jal          = m_is_jal          | p_is_jal[i];
        m_fallThroughErr  = m_fallThroughErr  | p_fallThroughErr[i];
        m_slot_valids_0   = m_slot_valids_0   | p_slot_valids_0[i];
        m_slot_valids_1   = m_slot_valids_1   | p_slot_valids_1[i];
        m_br_taken_0      = m_br_taken_0      | p_br_taken_0[i];
        m_br_taken_1      = m_br_taken_1      | p_br_taken_1[i];
        m_fallThroughAddr = m_fallThroughAddr | p_fallThroughAddr[i];
        m_jalr_target     = m_jalr_target     | p_jalr_target[i];
        m_targets_0       = m_targets_0       | p_targets_0[i];
        m_targets_1       = m_targets_1       | p_targets_1[i];
        m_offsets_0       = m_offsets_0       | p_offsets_0[i];
        m_offsets_1       = m_offsets_1       | p_offsets_1[i];
        e_isCall   = e_isCall   | w_resp_isCall[i];
        e_isRet    = e_isRet    | w_resp_isRet[i];
        e_isJalr   = e_isJalr   | w_resp_isJalr[i];
        e_valid    = e_valid    | w_resp_valid[i];
        e_brOff    = e_brOff    | w_resp_brOff[i];
        e_brShar   = e_brShar   | w_resp_brShar[i];
        e_brVal    = e_brVal    | w_resp_brVal[i];
        e_brLow    = e_brLow    | w_resp_brLow[i];
        e_brTar    = e_brTar    | w_resp_brTar[i];
        e_tailOff  = e_tailOff  | w_resp_tailOff[i];
        e_tailShar = e_tailShar | w_resp_tailShar[i];
        e_tailVal  = e_tailVal  | w_resp_tailVal[i];
        e_tailLow  = e_tailLow  | w_resp_tailLow[i];
        e_tailTar  = e_tailTar  | w_resp_tailTar[i];
        e_pftAddr  = e_pftAddr  | w_resp_pftAddr[i];
        e_carry    = e_carry    | w_resp_carry[i];
        e_lmbrc    = e_lmbrc    | w_resp_lmbrc[i];
        e_sb0      = e_sb0      | w_resp_sb0[i];
        e_sb1      = e_sb1      | w_resp_sb1[i];
      end
    end
  end

  // fauftb_enable = RegNext(io_ctrl_ubtb_enable)
  logic fauftb_enable;
  always_ff @(posedge clock) fauftb_enable <= io_ctrl_ubtb_enable;

  wire entry_hit = s1_hit & fauftb_enable;

  // full_pred 输出（hit 字段 = entry_hit；其余直接 Mux1H 值）
  assign fp_br_taken_mask_0      = m_br_taken_0;
  assign fp_br_taken_mask_1      = m_br_taken_1;
  assign fp_slot_valids_0        = m_slot_valids_0;
  assign fp_slot_valids_1        = m_slot_valids_1;
  assign fp_targets_0            = m_targets_0;
  assign fp_targets_1            = m_targets_1;
  assign fp_jalr_target          = m_jalr_target;
  assign fp_offsets_0            = m_offsets_0;
  assign fp_offsets_1            = m_offsets_1;
  assign fp_fallThroughAddr      = m_fallThroughAddr;
  assign fp_fallThroughErr       = m_fallThroughErr;
  assign fp_is_jal               = m_is_jal;
  assign fp_is_jalr              = m_is_jalr;
  assign fp_is_call              = m_is_call;
  assign fp_is_ret               = m_is_ret;
  assign fp_last_may_be_rvi_call = m_last_may_rvi;
  assign fp_is_br_sharing        = m_is_br_sharing;
  assign fp_hit                  = entry_hit;

  // fauftb_entry_out
  assign io_fauftb_entry_out_isCall              = e_isCall;
  assign io_fauftb_entry_out_isRet               = e_isRet;
  assign io_fauftb_entry_out_isJalr              = e_isJalr;
  assign io_fauftb_entry_out_valid               = e_valid;
  assign io_fauftb_entry_out_brSlots_0_offset    = e_brOff;
  assign io_fauftb_entry_out_brSlots_0_sharing   = e_brShar;
  assign io_fauftb_entry_out_brSlots_0_valid     = e_brVal;
  assign io_fauftb_entry_out_brSlots_0_lower     = e_brLow;
  assign io_fauftb_entry_out_brSlots_0_tarStat   = e_brTar;
  assign io_fauftb_entry_out_tailSlot_offset     = e_tailOff;
  assign io_fauftb_entry_out_tailSlot_sharing    = e_tailShar;
  assign io_fauftb_entry_out_tailSlot_valid      = e_tailVal;
  assign io_fauftb_entry_out_tailSlot_lower      = e_tailLow;
  assign io_fauftb_entry_out_tailSlot_tarStat    = e_tailTar;
  assign io_fauftb_entry_out_pftAddr             = e_pftAddr;
  assign io_fauftb_entry_out_carry               = e_carry;
  assign io_fauftb_entry_out_last_may_be_rvi_call = e_lmbrc;
  assign io_fauftb_entry_out_strong_bias_0       = e_sb0;
  assign io_fauftb_entry_out_strong_bias_1       = e_sb1;
  assign io_fauftb_entry_hit_out                 = entry_hit;

  // ===========================================================================
  // meta：last_stage_meta = {0..., pred_way_r_1[4:0], hit_r_1}  (516 位)
  //   两级流水：s1_fire 锁存 {hit, way}，s2_fire 再延一拍。
  // ===========================================================================
  logic                  resp_meta_hit_r,  resp_meta_hit_r_1;
  logic [WAY_IDX_W-1:0]  resp_meta_pred_way_r, resp_meta_pred_way_r_1;
  always_ff @(posedge clock) begin
    if (io_s1_fire_0) begin
      resp_meta_hit_r      <= s1_hit;
      resp_meta_pred_way_r <= s1_hit_way;
    end
    if (io_s2_fire_0) begin
      resp_meta_hit_r_1      <= resp_meta_hit_r;
      resp_meta_pred_way_r_1 <= resp_meta_pred_way_r;
    end
  end
  assign io_out_last_stage_meta =
      {{(META_W-1-WAY_IDX_W){1'b0}}, resp_meta_pred_way_r_1, resp_meta_hit_r_1};

  // ===========================================================================
  // 更新逻辑
  //   s0：寄存 update 请求（u_valid / u_bits_*）+ 计算 update 命中。
  //   s1：寄存命中/tag/entry，alloc_way（PLRU），生成 write_way_oh / write_valid。
  // ===========================================================================
  always_ff @(posedge clock) begin
    if (io_update_valid) begin
      u_bits_ftb_entry_isCall            <= io_update_bits_ftb_entry_isCall;
      u_bits_ftb_entry_isRet             <= io_update_bits_ftb_entry_isRet;
      u_bits_ftb_entry_isJalr            <= io_update_bits_ftb_entry_isJalr;
      u_bits_ftb_entry_valid             <= io_update_bits_ftb_entry_valid;
      u_bits_ftb_entry_brSlots_0_offset  <= io_update_bits_ftb_entry_brSlots_0_offset;
      u_bits_ftb_entry_brSlots_0_sharing <= io_update_bits_ftb_entry_brSlots_0_sharing;
      u_bits_ftb_entry_brSlots_0_valid   <= io_update_bits_ftb_entry_brSlots_0_valid;
      u_bits_ftb_entry_brSlots_0_lower   <= io_update_bits_ftb_entry_brSlots_0_lower;
      u_bits_ftb_entry_brSlots_0_tarStat <= io_update_bits_ftb_entry_brSlots_0_tarStat;
      u_bits_ftb_entry_tailSlot_offset   <= io_update_bits_ftb_entry_tailSlot_offset;
      u_bits_ftb_entry_tailSlot_sharing  <= io_update_bits_ftb_entry_tailSlot_sharing;
      u_bits_ftb_entry_tailSlot_valid    <= io_update_bits_ftb_entry_tailSlot_valid;
      u_bits_ftb_entry_tailSlot_lower    <= io_update_bits_ftb_entry_tailSlot_lower;
      u_bits_ftb_entry_tailSlot_tarStat  <= io_update_bits_ftb_entry_tailSlot_tarStat;
      u_bits_ftb_entry_pftAddr           <= io_update_bits_ftb_entry_pftAddr;
      u_bits_ftb_entry_carry             <= io_update_bits_ftb_entry_carry;
      u_bits_ftb_entry_last_may_be_rvi_call <= io_update_bits_ftb_entry_last_may_be_rvi_call;
      u_bits_ftb_entry_strong_bias_0     <= io_update_bits_ftb_entry_strong_bias_0;
      u_bits_ftb_entry_strong_bias_1     <= io_update_bits_ftb_entry_strong_bias_1;
      u_bits_br_taken_mask_0             <= io_update_bits_br_taken_mask_0;
      u_bits_br_taken_mask_1             <= io_update_bits_br_taken_mask_1;
      u_bits_meta                        <= io_update_bits_meta;
    end
  end

  // s1 流水寄存
  logic                u_s1_valid;
  logic [NUM_WAYS-1:0] u_s1_hit_oh;
  logic                u_s1_hit;
  logic                u_s1_br_update_valids_0, u_s1_br_update_valids_1;
  logic                u_s1_br_takens_0, u_s1_br_takens_1;

  always_ff @(posedge clock) begin
    u_s1_valid <= u_valid;
    if (u_valid) begin
      u_s1_tag    <= io_update_bits_pc[TAG_W:1];
      u_s1_hit_oh <= u_s0_hit_oh;
      u_s1_hit    <= |u_s0_hit_oh;
      u_s1_ftb_entry_isCall            <= u_bits_ftb_entry_isCall;
      u_s1_ftb_entry_isRet             <= u_bits_ftb_entry_isRet;
      u_s1_ftb_entry_isJalr            <= u_bits_ftb_entry_isJalr;
      u_s1_ftb_entry_valid             <= u_bits_ftb_entry_valid;
      u_s1_ftb_entry_brSlots_0_offset  <= u_bits_ftb_entry_brSlots_0_offset;
      u_s1_ftb_entry_brSlots_0_sharing <= u_bits_ftb_entry_brSlots_0_sharing;
      u_s1_ftb_entry_brSlots_0_valid   <= u_bits_ftb_entry_brSlots_0_valid;
      u_s1_ftb_entry_brSlots_0_lower   <= u_bits_ftb_entry_brSlots_0_lower;
      u_s1_ftb_entry_brSlots_0_tarStat <= u_bits_ftb_entry_brSlots_0_tarStat;
      u_s1_ftb_entry_tailSlot_offset   <= u_bits_ftb_entry_tailSlot_offset;
      u_s1_ftb_entry_tailSlot_sharing  <= u_bits_ftb_entry_tailSlot_sharing;
      u_s1_ftb_entry_tailSlot_valid    <= u_bits_ftb_entry_tailSlot_valid;
      u_s1_ftb_entry_tailSlot_lower    <= u_bits_ftb_entry_tailSlot_lower;
      u_s1_ftb_entry_tailSlot_tarStat  <= u_bits_ftb_entry_tailSlot_tarStat;
      u_s1_ftb_entry_pftAddr           <= u_bits_ftb_entry_pftAddr;
      u_s1_ftb_entry_carry             <= u_bits_ftb_entry_carry;
      u_s1_ftb_entry_last_may_be_rvi_call <= u_bits_ftb_entry_last_may_be_rvi_call;
      u_s1_ftb_entry_strong_bias_0     <= u_bits_ftb_entry_strong_bias_0;
      u_s1_ftb_entry_strong_bias_1     <= u_bits_ftb_entry_strong_bias_1;
      u_s1_br_update_valids_0 <=
          u_bits_ftb_entry_brSlots_0_valid & u_valid & ~u_bits_ftb_entry_strong_bias_0;
      u_s1_br_update_valids_1 <=
          u_bits_ftb_entry_tailSlot_valid & u_bits_ftb_entry_tailSlot_sharing & u_valid
          & ~u_bits_ftb_entry_strong_bias_1 & ~u_bits_br_taken_mask_0;
      u_s1_br_takens_0 <= u_bits_br_taken_mask_0;
      u_s1_br_takens_1 <= u_bits_br_taken_mask_1;
    end
  end

  // u_valid = RegNext(io_update.valid, init=0)  (在带 reset 的 always 中)
  always_ff @(posedge clock or posedge reset) begin
    if (reset) u_valid <= 1'b0;
    else       u_valid <= io_update_valid;
  end

  // ---- PLRU 替换器 ----
  logic [NUM_WAYS-2:0] state_reg;  // 31 位

  // alloc_way：自树根向下遍历（golden 位编号）
  wire [3:0] alloc_low =
    state_reg[30] ?
      {state_reg[29],
       state_reg[29] ?
         {state_reg[28],
          state_reg[28] ? {state_reg[27], state_reg[27] ? state_reg[26] : state_reg[25]}
                        : {state_reg[24], state_reg[24] ? state_reg[23] : state_reg[22]}}
       : {state_reg[21],
          state_reg[21] ? {state_reg[20], state_reg[20] ? state_reg[19] : state_reg[18]}
                        : {state_reg[17], state_reg[17] ? state_reg[16] : state_reg[15]}}}
    : {state_reg[14],
       state_reg[14] ?
         {state_reg[13],
          state_reg[13] ? {state_reg[12], state_reg[12] ? state_reg[11] : state_reg[10]}
                        : {state_reg[9],  state_reg[9]  ? state_reg[8]  : state_reg[7]}}
       : {state_reg[6],
          state_reg[6]  ? {state_reg[5],  state_reg[5]  ? state_reg[4]  : state_reg[3]}
                        : {state_reg[2],  state_reg[2]  ? state_reg[1]  : state_reg[0]}}};
  wire [WAY_IDX_W-1:0] u_s1_alloc_way = {state_reg[30], alloc_low};

  wire [NUM_WAYS-1:0] u_s1_write_way_oh =
      u_s1_hit ? u_s1_hit_oh
               : (32'h1 << {27'h0, state_reg[30], alloc_low});

  // 写使能
  always_comb begin
    for (int i = 0; i < NUM_WAYS; i++)
      u_s1_ways_write_valid[i] = u_s1_write_way_oh[i] & u_s1_valid;
  end

  // ---- replacer touch（s1_fire 命中：pred touch；u_s1_valid：commit touch） ----
  logic                 rtw0_valid;       // replacer_touch_ways_0_valid_REG
  logic [WAY_IDX_W-1:0] rtw0_bits;        // replacer_touch_ways_0_bits_r
  always_ff @(posedge clock) begin
    rtw0_valid <= io_s1_fire_0 & s1_hit;
    if (io_s1_fire_0 & s1_hit) rtw0_bits <= s1_hit_way;
  end

  // commit touch way = OHToUInt(u_s1_write_way_oh)
  logic [WAY_IDX_W-1:0] rtw1_bits;
  always_comb begin
    rtw1_bits = '0;
    for (int b = 0; b < WAY_IDX_W; b++) begin
      logic acc; acc = 1'b0;
      for (int i = 0; i < NUM_WAYS; i++) if (i[b]) acc = acc | u_s1_write_way_oh[i];
      rtw1_bits[b] = acc;
    end
  end

  // PLRU 状态更新：先按 pred touch (rtw0)，再按 commit touch (rtw1)。
  // golden: state_reg 先组合出 _state_reg_T_107（pred touch 结果），再在 always 中
  // 用 u_s1_valid（commit）做第二次更新。两次 touch 用同一棵树的翻转规则。
  // 这里用通用 PLRU 翻转函数（高半 [29:15] 与低半 [14:0]）。

  // pred-touch 后的 [29:0]（[30] 由 commit 决定，pred 不动 root? — golden 中 root
  // 在 pred touch 不更新到 [30]，见 _state_reg_T_107 仅覆盖 [29:0]，[30] 保持）
  //   PLRU 翻转：访问 way 后，从树根到该叶的路径上各节点指向"另一侧"（~way_bit），
  //   未在路径上的子树保持不变。二叉树自顶向下递归，节点位 = ~way 当前层比特。
  //   3 位子树（4 叶，2bit way）：
  function automatic [2:0] plru_upd3(input [2:0] st, input [1:0] b2);
    plru_upd3 = {~b2[1], b2[1] ? ~b2[0] : st[1], b2[1] ? st[0] : ~b2[0]};
  endfunction
  //   7 位子树（8 叶，3bit way）：
  function automatic [6:0] plru_upd7(input [6:0] st, input [2:0] b3);
    plru_upd7 = {~b3[2],
                 b3[2] ? plru_upd3(st[5:3], b3[1:0]) : st[5:3],
                 b3[2] ? st[2:0] : plru_upd3(st[2:0], b3[1:0])};
  endfunction
  //   15 位子树（16 叶，4bit way）：
  function automatic [14:0] plru_upd15(input [14:0] st, input [3:0] b4);
    plru_upd15 = {~b4[3],
                  b4[3] ? plru_upd7(st[13:7], b4[2:0]) : st[13:7],
                  b4[3] ? st[6:0] : plru_upd7(st[6:0], b4[2:0])};
  endfunction

  // pred touch（rtw0_bits）：bit4 选高/低半，未选半保持
  wire [14:0] pt_hi = rtw0_bits[4] ? plru_upd15(state_reg[29:15], rtw0_bits[3:0])
                                   : state_reg[29:15];
  wire [14:0] pt_lo = rtw0_bits[4] ? state_reg[14:0]
                                   : plru_upd15(state_reg[14:0], rtw0_bits[3:0]);
  wire [29:0] state_after_pred = rtw0_valid ? {pt_hi, pt_lo} : state_reg[29:0];
  wire        root_after_pred  = rtw0_valid ? ~rtw0_bits[4]  : state_reg[30];

  // commit touch（rtw1_bits, when u_s1_valid）：作用在 pred 之后的状态上
  wire [14:0] ct_hi = rtw1_bits[4] ? plru_upd15(state_after_pred[29:15], rtw1_bits[3:0])
                                   : state_after_pred[29:15];
  wire [14:0] ct_lo = rtw1_bits[4] ? state_after_pred[14:0]
                                   : plru_upd15(state_after_pred[14:0], rtw1_bits[3:0]);
  wire [29:0] state_after_commit = u_s1_valid ? {ct_hi, ct_lo} : state_after_pred;
  wire        root_after_commit  = u_s1_valid ? ~rtw1_bits[4]  : root_after_pred;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) state_reg <= '0;
    else       state_reg <= {root_after_commit, state_after_commit};
  end

  // ---- 饱和计数器 ctrs（每路每 br） ----
  genvar gc, gb;
  generate
    for (gc = 0; gc < NUM_WAYS; gc++) begin : g_ctrs
      for (gb = 0; gb < NUM_BR; gb++) begin : g_br
        wire upd_valid = (gb == 0) ? u_s1_br_update_valids_0 : u_s1_br_update_valids_1;
        wire taken     = (gb == 0) ? u_s1_br_takens_0        : u_s1_br_takens_1;
        always_ff @(posedge clock or posedge reset) begin
          if (reset) ctrs[gc][gb] <= 2'h2;
          else if (u_s1_ways_write_valid[gc] & upd_valid) begin
            if ((&ctrs[gc][gb]) & taken)            ctrs[gc][gb] <= 2'h3;
            else if (ctrs[gc][gb] == 2'h0 & ~taken) ctrs[gc][gb] <= 2'h0;
            else if (taken)                         ctrs[gc][gb] <= ctrs[gc][gb] + 2'h1;
            else                                    ctrs[gc][gb] <= ctrs[gc][gb] - 2'h1;
          end
        end
      end
    end
  endgenerate

  // ===========================================================================
  // 性能计数：io_perf_*_value = {5'h0, REG_1}
  //   io_perf_0: 延两拍的 (u_valid & meta[0])
  //   io_perf_1: 延两拍的 (u_valid & ~meta[0])
  // ===========================================================================
  logic perf0_d0, perf0_d1, perf1_d0, perf1_d1;
  always_ff @(posedge clock) begin
    perf0_d0 <= u_valid &  u_bits_meta[0];
    perf0_d1 <= perf0_d0;
    perf1_d0 <= u_valid & ~u_bits_meta[0];
    perf1_d1 <= perf1_d0;
  end
  assign io_perf_0_value = {5'h0, perf0_d1};
  assign io_perf_1_value = {5'h0, perf1_d1};

  // 抑制未使用端口（s1/s2 fire 的 dup 1..3、s2_fire_0 在本核无观测使用）警告
  wire _unused = &{1'b0, io_s1_fire_1, io_s1_fire_2, io_s1_fire_3,
                   io_s2_fire_1, io_s2_fire_2, io_s2_fire_3, 1'b0};

endmodule
