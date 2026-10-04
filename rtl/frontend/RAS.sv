// RAS.sv —— 分支预测器 RAS（返回地址栈）的外层：识别 call/ret、驱动 RASStack、改写 ret 的跳转目标
//
// 位置：BPU Composer 里的第五个预测器（frontend/newRAS.scala:96 class RAS，BasePredictor）。
//   它不自己存返回地址 —— 那是 child RASStack（已独立签核，rtl/frontend/RASStack.sv）的事；
//   本层负责把 s2/s3 两级流水上的"这一块是不是 taken 的 call/ret"翻译成对栈的操作，并把栈顶
//   填回预测结果：
//
//     s2：用 s2 的 FTB 预测（full_pred 第 2 份复制）判 hit_taken_on_call / _ret
//         → 投机 push（压返回地址 = fallThroughAddr，RVI call 再 +2）/ 投机 pop；
//         is_ret 时把四份复制的 jalr_target 换成栈顶（spec_pop_addr），is_jalr 时 targets[1] 跟着换。
//     s3：同样判一遍（s3 的预测可能与 s2 不同、且多了 fallThroughErr 屏蔽）；与 s2 当时做的
//         push/pop 不一致就 s3_cancel，并补做漏掉的 push/pop（s3_missed_push / _pop）；
//         ret 目标改用 s2 fire 时锁存的栈顶 s3_top。
//     redirect（后端/IFU 纠错）：打一拍后带着当时的栈快照（ssp/sctr/TOSW/TOSR/NOS）让栈回滚，
//         预测错的 call 要重新 push（地址 = pc + (RVC ? 2 : 4)），预测错的 ret 要重新 pop。
//     update（提交）：打一拍后通知栈提交真正发生的 call/ret（commit_push/pop）。
//
// 栈快照（RASInternalMeta）：s2 时从栈读出 {ssp, sctr, TOSW, TOSR, NOS}，s2 fire 时锁进 s3_meta，
//   s3 用来做 cancel 回滚，同时作为 last_stage_spec_info 下发、{ssp, TOSW} 作为 last_stage_meta 下发
//   （516 位宽的 meta 总线只用低 10 位）。
//
// ★s2/s3 PC 流水是"分段地址寄存器"（SegmentedAddrNext）★：50 位 PC 按 [49:24]/[23:12]/[11:0] 分三段
//   存，只在本段确实变了时才写（省时钟翻转，Chisel 的设计意图）；低段每次 fire 都写。四份复制
//   （dup 0..3）各自独立跟各自的 fire。s1_pc 不复位，复位放开后第一拍装 reset_vector（modified_reset）。
//
// 本层其余字段（br_taken_mask、offsets、fallThroughAddr、last_stage_ftb_entry 等）原样直通。
// golden 1341 行 / 402 端口；唯一子模块 RASStack，按 golden 同层同名例化在 wrapper 里（两侧白盒）。
// wrapper 与 FM 钉点由 scripts/gen_ras.py 从 golden 机械生成。

package ras_pred_pkg;
  localparam int unsigned PC_W     = 50;  // VAddrBits
  localparam int unsigned NUM_DUP  = 4;   // 预测结果 / PC 流水的复制份数
  localparam int unsigned SSP_W    = 4;   // log2(RasSize=16)
  localparam int unsigned SCTR_W   = 3;   // RasCtrSize
  localparam int unsigned SPTR_W   = 5;   // log2(RasSpecSize=32)
  localparam int unsigned META_W   = 516; // BPU meta 总线宽

  // 投机栈环形指针 RASPtr
  typedef struct packed {
    logic              flag;
    logic [SPTR_W-1:0] value;
  } ras_pred_ptr_t;

  // 栈快照 RASInternalMeta
  typedef struct packed {
    logic [SSP_W-1:0]  ssp;
    logic [SCTR_W-1:0] sctr;
    ras_pred_ptr_t     tosw;
    ras_pred_ptr_t     tosr;
    ras_pred_ptr_t     nos;
  } ras_snap_t;

  // 一份 FullBranchPrediction 里判 call/ret 需要的字段（第 2 份复制）
  typedef struct packed {
    logic [1:0]    br_taken_mask;
    logic [1:0]    slot_valids;     // [0] = 分支槽，[1] = 尾槽
    logic          is_br_sharing;   // 尾槽装的是条件分支
    logic          hit;
    logic          is_call;
    logic          is_ret;
    logic          is_jalr;
    logic          fall_through_err;
  } cfi_pred_t;

  // FullBranchPrediction.hit_taken_on_jmp：命中、分支槽没 taken、尾槽是 taken 的无条件跳转
  //   taken_mask_on_slot = {尾槽: valid & (sharing ? taken[1] : 1), 分支槽: valid & taken[0]}，再与 hit 相与
  function automatic logic hit_taken_on_jmp(input cfi_pred_t p);
    logic br_slot_taken, tail_slot_taken;
    br_slot_taken   = p.slot_valids[0] & p.br_taken_mask[0] & p.hit;
    tail_slot_taken = p.slot_valids[1] & (p.is_br_sharing & p.br_taken_mask[1] | ~p.is_br_sharing) & p.hit;
    return ~br_slot_taken & tail_slot_taken & ~p.is_br_sharing;
  endfunction
endpackage

module xs_RAS_core
  import ras_pred_pkg::*;
(
  input  logic                       clock,
  input  logic                       reset,
  input  logic [47:0]                reset_vector,
  input  logic                       ras_enable,          // ctrl.ras_enable
  // ---- 流水握手（每份复制一位；s3 只用到第 2 份）----
  input  logic [NUM_DUP-1:0]         s0_fire,
  input  logic [NUM_DUP-1:0]         s1_fire,
  input  logic [NUM_DUP-1:0]         s2_fire,
  input  logic                       s3_fire,             // s3_fire(2)
  input  logic                       s3_redirect,         // s3_redirect(2)
  // ---- PC 流水 ----
  input  logic [NUM_DUP-1:0][PC_W-1:0] s0_pc,
  output logic [NUM_DUP-1:0][PC_W-1:0] s2_pc,
  output logic [NUM_DUP-1:0][PC_W-1:0] s3_pc,
  // ---- s2 / s3 预测（第 2 份复制）----
  input  cfi_pred_t                  s2_pred,
  input  logic [PC_W-1:0]            s2_fall_through_addr,
  input  logic                       s2_last_may_be_rvi_call,
  input  cfi_pred_t                  s3_pred,
  // ---- 四份复制的跳转目标：进来的原值 / 出去的改写值 ----
  input  logic [NUM_DUP-1:0][PC_W-1:0] s2_jalr_target_in,
  input  logic [NUM_DUP-1:0][PC_W-1:0] s2_last_target_in,   // targets(1)，即 targets.last
  output logic [NUM_DUP-1:0][PC_W-1:0] s2_jalr_target_out,
  output logic [NUM_DUP-1:0][PC_W-1:0] s2_last_target_out,
  input  logic [NUM_DUP-1:0][PC_W-1:0] s3_jalr_target_in,
  input  logic [NUM_DUP-1:0][PC_W-1:0] s3_last_target_in,
  output logic [NUM_DUP-1:0][PC_W-1:0] s3_jalr_target_out,
  output logic [NUM_DUP-1:0][PC_W-1:0] s3_last_target_out,
  // ---- 下发给 FTQ 的末级信息 ----
  output logic [META_W-1:0]          last_stage_meta,
  output ras_snap_t                  last_stage_snap,
  output logic [PC_W-1:0]            last_stage_top_addr,
  // ---- redirect（未打拍）----
  input  logic                       redirect_valid,
  input  logic                       redirect_level,
  input  logic [PC_W-1:0]            redirect_pc,
  input  logic                       redirect_pd_valid,
  input  logic                       redirect_pd_is_rvc,
  input  logic                       redirect_pd_is_call,
  input  logic                       redirect_pd_is_ret,
  input  ras_snap_t                  redirect_snap,
  // ---- update（提交，未打拍）----
  input  logic                       update_valid,
  input  logic                       update_entry_is_call,
  input  logic                       update_entry_is_ret,
  input  logic [3:0]                 update_tail_slot_offset,
  input  logic                       update_tail_slot_valid,
  input  logic                       update_cfi_idx_valid,
  input  logic [3:0]                 update_cfi_idx_bits,
  input  logic                       update_jmp_taken,
  input  logic [META_W-1:0]          update_meta,
  // ---- 与 RASStack 的接口（RASStack 例化在 wrapper 里）----
  input  logic [PC_W-1:0]            stack_top_addr,      // spec_pop_addr
  input  ras_snap_t                  stack_snap,          // {ssp, sctr, TOSW, TOSR, NOS}
  input  logic                       stack_near_overflow,
  output logic                       stack_spec_push,
  output logic                       stack_spec_pop,
  output logic [PC_W-1:0]            stack_spec_push_addr,
  output logic                       stack_s3_cancel,
  output ras_snap_t                  stack_s3_snap,
  output logic                       stack_s3_missed_pop,
  output logic                       stack_s3_missed_push,
  output logic [PC_W-1:0]            stack_s3_push_addr,
  output logic                       stack_commit_valid,
  output logic                       stack_commit_push,
  output logic                       stack_commit_pop,
  output ras_pred_ptr_t              stack_commit_tosw,
  output logic [SSP_W-1:0]           stack_commit_ssp,
  output logic                       stack_redirect_valid,
  output logic                       stack_redirect_is_call,
  output logic                       stack_redirect_is_ret,
  output ras_snap_t                  stack_redirect_snap,
  output logic [PC_W-1:0]            stack_redirect_call_addr
);

  // ===========================================================================
  // 1. PC 流水 s0 → s1 → s2 → s3（四份复制，分段地址寄存器）
  // ===========================================================================
  logic                  modified_reset;    // 复位放开后的第一拍
  logic [PC_W-1:0]       s1_pc     [NUM_DUP];
  logic [25:0]           s2_pc_hi  [NUM_DUP];   // PC[49:24]
  logic [11:0]           s2_pc_mid [NUM_DUP];   // PC[23:12]
  logic [11:0]           s2_pc_lo  [NUM_DUP];   // PC[11:0]
  logic [25:0]           s3_pc_hi  [NUM_DUP];
  logic [11:0]           s3_pc_mid [NUM_DUP];
  logic [11:0]           s3_pc_lo  [NUM_DUP];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) modified_reset <= 1'b1;
    else       modified_reset <= 1'b0;
  end

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_pc
    // s1：s0 fire 时锁存；复位放开那一拍装复位向量。无复位端（golden 同）。
    always_ff @(posedge clock) begin
      if (modified_reset)  s1_pc[d] <= {2'h0, reset_vector};
      else if (s0_fire[d]) s1_pc[d] <= s0_pc[d];
    end

    // s2 / s3：异步复位到 0；高、中段只在值变了时写，低段每次 fire 都写
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        s2_pc_hi[d]  <= '0;
        s2_pc_mid[d] <= '0;
        s2_pc_lo[d]  <= '0;
        s3_pc_hi[d]  <= '0;
        s3_pc_mid[d] <= '0;
        s3_pc_lo[d]  <= '0;
      end else begin
        if (s1_fire[d] && s2_pc_hi[d]  != s1_pc[d][49:24]) s2_pc_hi[d]  <= s1_pc[d][49:24];
        if (s1_fire[d] && s2_pc_mid[d] != s1_pc[d][23:12]) s2_pc_mid[d] <= s1_pc[d][23:12];
        if (s1_fire[d])                                     s2_pc_lo[d]  <= s1_pc[d][11:0];
        if (s2_fire[d] && s3_pc_hi[d]  != s2_pc_hi[d])      s3_pc_hi[d]  <= s2_pc_hi[d];
        if (s2_fire[d] && s3_pc_mid[d] != s2_pc_mid[d])     s3_pc_mid[d] <= s2_pc_mid[d];
        if (s2_fire[d])                                     s3_pc_lo[d]  <= s2_pc_lo[d];
      end
    end

    assign s2_pc[d] = {s2_pc_hi[d], s2_pc_mid[d], s2_pc_lo[d]};
    assign s3_pc[d] = {s3_pc_hi[d], s3_pc_mid[d], s3_pc_lo[d]};
  end

  // ===========================================================================
  // 2. s2：投机 push / pop，ret 目标换成栈顶
  // ===========================================================================
  logic s2_push, s2_pop;
  // 返回地址 = 落地址；最后一条若是 RVI call，落地址落在它中间，要再 +2
  assign stack_spec_push_addr = s2_fall_through_addr + {48'h0, s2_last_may_be_rvi_call, 1'b0};
  assign s2_push = s2_fire[2] & hit_taken_on_jmp(s2_pred) & s2_pred.is_call & ~s3_redirect;
  assign s2_pop  = s2_fire[2] & hit_taken_on_jmp(s2_pred) & s2_pred.is_ret  & ~s3_redirect;
  // 栈快要溢出时投机操作一律不做
  assign stack_spec_push = s2_push & ~stack_near_overflow;
  assign stack_spec_pop  = s2_pop  & ~stack_near_overflow;

  logic s2_use_top;
  assign s2_use_top = s2_pred.is_ret & ras_enable;

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_s2_target
    assign s2_jalr_target_out[d] = s2_use_top ? stack_top_addr : s2_jalr_target_in[d];
    assign s2_last_target_out[d] = s2_pred.is_jalr ? s2_jalr_target_out[d] : s2_last_target_in[d];
  end

  // ===========================================================================
  // 3. s2 → s3 锁存（s2_fire(2) 时）：栈顶、push 地址、s2 做过什么、栈快照。不复位。
  // ===========================================================================
  logic [PC_W-1:0] s3_top, s3_push_addr;
  logic            s3_pushed_in_s2, s3_popped_in_s2;
  ras_snap_t       s3_snap;

  always_ff @(posedge clock) begin
    if (s2_fire[2]) begin
      s3_top          <= stack_top_addr;
      s3_push_addr    <= stack_spec_push_addr;
      s3_pushed_in_s2 <= s2_push;
      s3_popped_in_s2 <= s2_pop;
      s3_snap         <= stack_snap;
    end
  end

  // ===========================================================================
  // 4. s3：再判一次，与 s2 不一致就 cancel 并补做；ret 目标换成 s3_top
  // ===========================================================================
  logic s3_push, s3_pop, s3_cancel;
  assign s3_push   = hit_taken_on_jmp(s3_pred) & s3_pred.is_call & ~s3_pred.fall_through_err;
  assign s3_pop    = hit_taken_on_jmp(s3_pred) & s3_pred.is_ret  & ~s3_pred.fall_through_err;
  assign s3_cancel = s3_fire & ((s3_pushed_in_s2 != s3_push) | (s3_popped_in_s2 != s3_pop));

  assign stack_s3_cancel      = s3_cancel & ~stack_near_overflow;
  assign stack_s3_snap        = s3_snap;
  assign stack_s3_missed_pop  = s3_pop  & ~s3_popped_in_s2;
  assign stack_s3_missed_push = s3_push & ~s3_pushed_in_s2;
  assign stack_s3_push_addr   = s3_push_addr;

  logic s3_is_jalr, s3_use_top;
  assign s3_is_jalr = s3_pred.is_jalr & ~s3_pred.fall_through_err;
  assign s3_use_top = s3_pred.is_ret & ~s3_pred.fall_through_err & ras_enable;

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_s3_target
    assign s3_jalr_target_out[d] = s3_use_top ? s3_top : s3_jalr_target_in[d];
    assign s3_last_target_out[d] = s3_is_jalr ? s3_jalr_target_out[d] : s3_last_target_in[d];
  end

  // 末级下发：spec_info 带完整快照 + 栈顶；meta 只带 RASMeta{ssp, TOSW}（低 10 位）
  assign last_stage_snap     = s3_snap;
  assign last_stage_top_addr = s3_top;
  assign last_stage_meta     = META_W'({s3_snap.ssp, s3_snap.tosw});

  // ===========================================================================
  // 5. redirect 回滚（RegNextWithEnable：valid 打一拍且异步复位，bits 在 valid 时锁存）
  // ===========================================================================
  logic            rd_valid;
  logic            rd_level;
  logic [PC_W-1:0] rd_pc;
  logic            rd_pd_valid, rd_pd_is_rvc, rd_pd_is_call, rd_pd_is_ret;
  ras_snap_t       rd_snap;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) rd_valid <= 1'b0;
    else       rd_valid <= redirect_valid;
  end

  always_ff @(posedge clock) begin
    if (redirect_valid) begin
      rd_level      <= redirect_level;
      rd_pc         <= redirect_pc;
      rd_pd_valid   <= redirect_pd_valid;
      rd_pd_is_rvc  <= redirect_pd_is_rvc;
      rd_pd_is_call <= redirect_pd_is_call;
      rd_pd_is_ret  <= redirect_pd_is_ret;
      rd_snap       <= redirect_snap;
    end
  end

  // isBefore(redirect.TOSW, stack.TOSW)：环形指针比较
  logic rd_tosw_before_stack;
  assign rd_tosw_before_stack = rd_snap.tosw.flag ^ stack_snap.tosw.flag ^
                                (rd_snap.tosw.value < stack_snap.tosw.value);

  // 栈快溢出时只接受"回到更早位置"的 redirect
  assign stack_redirect_valid     = rd_valid & (rd_tosw_before_stack | ~stack_near_overflow);
  // level==0 的 redirect 才是本条指令自己预测错（call/ret 要重做）
  assign stack_redirect_is_call   = rd_valid & ~rd_level & rd_pd_is_call & rd_pd_valid;
  assign stack_redirect_is_ret    = rd_valid & ~rd_level & rd_pd_is_ret  & rd_pd_valid;
  assign stack_redirect_snap      = rd_snap;
  assign stack_redirect_call_addr = rd_pc + (rd_pd_is_rvc ? PC_W'(2) : PC_W'(4));

  // ===========================================================================
  // 6. update（提交）：valid 打一拍（异步复位），字段在 valid 时锁存
  // ===========================================================================
  logic                upd_valid;
  logic                upd_is_call, upd_is_ret, upd_tail_valid, upd_cfi_valid, upd_jmp_taken;
  logic [3:0]          upd_tail_offset, upd_cfi_idx;
  logic [SSP_W-1:0]    upd_ssp;
  ras_pred_ptr_t       upd_tosw;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) upd_valid <= 1'b0;
    else       upd_valid <= update_valid;
  end

  always_ff @(posedge clock) begin
    if (update_valid) begin
      upd_is_call     <= update_entry_is_call;
      upd_is_ret      <= update_entry_is_ret;
      upd_tail_offset <= update_tail_slot_offset;
      upd_tail_valid  <= update_tail_slot_valid;
      upd_cfi_valid   <= update_cfi_idx_valid;
      upd_cfi_idx     <= update_cfi_idx_bits;
      upd_jmp_taken   <= update_jmp_taken;
      // RASMeta 在 meta 总线低 10 位：{ssp[9:6], TOSW.flag[5], TOSW.value[4:0]}
      upd_ssp         <= update_meta[9:6];
      upd_tosw        <= update_meta[5:0];
    end
  end

  // is_call_taken / is_ret_taken：尾槽有效、是 call/ret、跳了、且实际跳转点就是尾槽
  logic upd_tail_jumped;
  assign upd_tail_jumped = upd_tail_valid & upd_jmp_taken & upd_cfi_valid & (upd_cfi_idx == upd_tail_offset);

  assign stack_commit_valid = upd_valid;
  assign stack_commit_push  = upd_valid & upd_tail_jumped & upd_is_call;
  assign stack_commit_pop   = upd_valid & upd_tail_jumped & upd_is_ret;
  assign stack_commit_tosw  = upd_tosw;
  assign stack_commit_ssp   = upd_ssp;

endmodule

// BEGIN GENERATED(RAS) —— scripts/gen_ras.py
module RAS
  import ras_pred_pkg::*;
(
  input  logic         clock,
  input  logic         reset,
  input  logic [47:0]  io_reset_vector,
  input  logic [49:0]  io_in_bits_s0_pc_0,
  input  logic [49:0]  io_in_bits_s0_pc_1,
  input  logic [49:0]  io_in_bits_s0_pc_2,
  input  logic [49:0]  io_in_bits_s0_pc_3,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_0_targets_0,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_0_targets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_0_jalr_target,
  input  logic [3:0]   io_in_bits_resp_in_0_s2_full_pred_0_offsets_0,
  input  logic [3:0]   io_in_bits_resp_in_0_s2_full_pred_0_offsets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_0_is_jal,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_0_is_jalr,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_0_is_call,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_0_is_ret,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_0_hit,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_1_targets_0,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_1_targets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_1_jalr_target,
  input  logic [3:0]   io_in_bits_resp_in_0_s2_full_pred_1_offsets_0,
  input  logic [3:0]   io_in_bits_resp_in_0_s2_full_pred_1_offsets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_1_is_jal,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_1_is_jalr,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_1_is_call,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_1_is_ret,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_1_hit,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_2_targets_0,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_2_targets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_2_jalr_target,
  input  logic [3:0]   io_in_bits_resp_in_0_s2_full_pred_2_offsets_0,
  input  logic [3:0]   io_in_bits_resp_in_0_s2_full_pred_2_offsets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_2_is_jal,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_2_is_jalr,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_2_is_call,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_2_is_ret,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_2_hit,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_3_targets_0,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_3_targets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_3_jalr_target,
  input  logic [3:0]   io_in_bits_resp_in_0_s2_full_pred_3_offsets_0,
  input  logic [3:0]   io_in_bits_resp_in_0_s2_full_pred_3_offsets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_3_is_jal,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_3_is_jalr,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_3_is_call,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_3_is_ret,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing,
  input  logic         io_in_bits_resp_in_0_s2_full_pred_3_hit,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_0_targets_0,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_0_targets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_0_jalr_target,
  input  logic [3:0]   io_in_bits_resp_in_0_s3_full_pred_0_offsets_0,
  input  logic [3:0]   io_in_bits_resp_in_0_s3_full_pred_0_offsets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_multiHit,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_is_jal,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_is_jalr,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_is_call,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_is_ret,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_0_hit,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_1_targets_0,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_1_targets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_1_jalr_target,
  input  logic [3:0]   io_in_bits_resp_in_0_s3_full_pred_1_offsets_0,
  input  logic [3:0]   io_in_bits_resp_in_0_s3_full_pred_1_offsets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_multiHit,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_is_jal,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_is_jalr,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_is_call,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_is_ret,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_1_hit,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_2_targets_0,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_2_targets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_2_jalr_target,
  input  logic [3:0]   io_in_bits_resp_in_0_s3_full_pred_2_offsets_0,
  input  logic [3:0]   io_in_bits_resp_in_0_s3_full_pred_2_offsets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_multiHit,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_is_jal,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_is_jalr,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_is_call,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_is_ret,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_2_hit,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_3_targets_0,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_3_targets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_3_jalr_target,
  input  logic [3:0]   io_in_bits_resp_in_0_s3_full_pred_3_offsets_0,
  input  logic [3:0]   io_in_bits_resp_in_0_s3_full_pred_3_offsets_1,
  input  logic [49:0]  io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_multiHit,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_is_jal,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_is_jalr,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_is_call,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_is_ret,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing,
  input  logic         io_in_bits_resp_in_0_s3_full_pred_3_hit,
  input  logic         io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0,
  input  logic         io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1,
  input  logic         io_in_bits_resp_in_0_last_stage_ftb_entry_isCall,
  input  logic         io_in_bits_resp_in_0_last_stage_ftb_entry_isRet,
  input  logic         io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr,
  input  logic         io_in_bits_resp_in_0_last_stage_ftb_entry_valid,
  input  logic [3:0]   io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset,
  input  logic         io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing,
  input  logic         io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid,
  input  logic [11:0]  io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower,
  input  logic [1:0]   io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat,
  input  logic [3:0]   io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset,
  input  logic         io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing,
  input  logic         io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid,
  input  logic [19:0]  io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower,
  input  logic [1:0]   io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat,
  input  logic [3:0]   io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr,
  input  logic         io_in_bits_resp_in_0_last_stage_ftb_entry_carry,
  input  logic         io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call,
  input  logic         io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0,
  input  logic         io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1,
  output logic [49:0]  io_out_s2_pc_0,
  output logic [49:0]  io_out_s2_pc_1,
  output logic [49:0]  io_out_s2_pc_2,
  output logic [49:0]  io_out_s2_pc_3,
  output logic         io_out_s2_full_pred_0_br_taken_mask_0,
  output logic         io_out_s2_full_pred_0_br_taken_mask_1,
  output logic         io_out_s2_full_pred_0_slot_valids_0,
  output logic         io_out_s2_full_pred_0_slot_valids_1,
  output logic [49:0]  io_out_s2_full_pred_0_targets_0,
  output logic [49:0]  io_out_s2_full_pred_0_targets_1,
  output logic [49:0]  io_out_s2_full_pred_0_jalr_target,
  output logic [3:0]   io_out_s2_full_pred_0_offsets_0,
  output logic [3:0]   io_out_s2_full_pred_0_offsets_1,
  output logic [49:0]  io_out_s2_full_pred_0_fallThroughAddr,
  output logic         io_out_s2_full_pred_0_fallThroughErr,
  output logic         io_out_s2_full_pred_0_is_jal,
  output logic         io_out_s2_full_pred_0_is_jalr,
  output logic         io_out_s2_full_pred_0_is_call,
  output logic         io_out_s2_full_pred_0_is_ret,
  output logic         io_out_s2_full_pred_0_last_may_be_rvi_call,
  output logic         io_out_s2_full_pred_0_is_br_sharing,
  output logic         io_out_s2_full_pred_0_hit,
  output logic         io_out_s2_full_pred_1_br_taken_mask_0,
  output logic         io_out_s2_full_pred_1_br_taken_mask_1,
  output logic         io_out_s2_full_pred_1_slot_valids_0,
  output logic         io_out_s2_full_pred_1_slot_valids_1,
  output logic [49:0]  io_out_s2_full_pred_1_targets_0,
  output logic [49:0]  io_out_s2_full_pred_1_targets_1,
  output logic [49:0]  io_out_s2_full_pred_1_jalr_target,
  output logic [3:0]   io_out_s2_full_pred_1_offsets_0,
  output logic [3:0]   io_out_s2_full_pred_1_offsets_1,
  output logic [49:0]  io_out_s2_full_pred_1_fallThroughAddr,
  output logic         io_out_s2_full_pred_1_fallThroughErr,
  output logic         io_out_s2_full_pred_1_is_jal,
  output logic         io_out_s2_full_pred_1_is_jalr,
  output logic         io_out_s2_full_pred_1_is_call,
  output logic         io_out_s2_full_pred_1_is_ret,
  output logic         io_out_s2_full_pred_1_last_may_be_rvi_call,
  output logic         io_out_s2_full_pred_1_is_br_sharing,
  output logic         io_out_s2_full_pred_1_hit,
  output logic         io_out_s2_full_pred_2_br_taken_mask_0,
  output logic         io_out_s2_full_pred_2_br_taken_mask_1,
  output logic         io_out_s2_full_pred_2_slot_valids_0,
  output logic         io_out_s2_full_pred_2_slot_valids_1,
  output logic [49:0]  io_out_s2_full_pred_2_targets_0,
  output logic [49:0]  io_out_s2_full_pred_2_targets_1,
  output logic [49:0]  io_out_s2_full_pred_2_jalr_target,
  output logic [3:0]   io_out_s2_full_pred_2_offsets_0,
  output logic [3:0]   io_out_s2_full_pred_2_offsets_1,
  output logic [49:0]  io_out_s2_full_pred_2_fallThroughAddr,
  output logic         io_out_s2_full_pred_2_fallThroughErr,
  output logic         io_out_s2_full_pred_2_is_jal,
  output logic         io_out_s2_full_pred_2_is_jalr,
  output logic         io_out_s2_full_pred_2_is_call,
  output logic         io_out_s2_full_pred_2_is_ret,
  output logic         io_out_s2_full_pred_2_last_may_be_rvi_call,
  output logic         io_out_s2_full_pred_2_is_br_sharing,
  output logic         io_out_s2_full_pred_2_hit,
  output logic         io_out_s2_full_pred_3_br_taken_mask_0,
  output logic         io_out_s2_full_pred_3_br_taken_mask_1,
  output logic         io_out_s2_full_pred_3_slot_valids_0,
  output logic         io_out_s2_full_pred_3_slot_valids_1,
  output logic [49:0]  io_out_s2_full_pred_3_targets_0,
  output logic [49:0]  io_out_s2_full_pred_3_targets_1,
  output logic [49:0]  io_out_s2_full_pred_3_jalr_target,
  output logic [3:0]   io_out_s2_full_pred_3_offsets_0,
  output logic [3:0]   io_out_s2_full_pred_3_offsets_1,
  output logic [49:0]  io_out_s2_full_pred_3_fallThroughAddr,
  output logic         io_out_s2_full_pred_3_fallThroughErr,
  output logic         io_out_s2_full_pred_3_is_jal,
  output logic         io_out_s2_full_pred_3_is_jalr,
  output logic         io_out_s2_full_pred_3_is_call,
  output logic         io_out_s2_full_pred_3_is_ret,
  output logic         io_out_s2_full_pred_3_last_may_be_rvi_call,
  output logic         io_out_s2_full_pred_3_is_br_sharing,
  output logic         io_out_s2_full_pred_3_hit,
  output logic [49:0]  io_out_s3_pc_0,
  output logic [49:0]  io_out_s3_pc_1,
  output logic [49:0]  io_out_s3_pc_2,
  output logic [49:0]  io_out_s3_pc_3,
  output logic         io_out_s3_full_pred_0_br_taken_mask_0,
  output logic         io_out_s3_full_pred_0_br_taken_mask_1,
  output logic         io_out_s3_full_pred_0_slot_valids_0,
  output logic         io_out_s3_full_pred_0_slot_valids_1,
  output logic [49:0]  io_out_s3_full_pred_0_targets_0,
  output logic [49:0]  io_out_s3_full_pred_0_targets_1,
  output logic [49:0]  io_out_s3_full_pred_0_jalr_target,
  output logic [3:0]   io_out_s3_full_pred_0_offsets_0,
  output logic [3:0]   io_out_s3_full_pred_0_offsets_1,
  output logic [49:0]  io_out_s3_full_pred_0_fallThroughAddr,
  output logic         io_out_s3_full_pred_0_fallThroughErr,
  output logic         io_out_s3_full_pred_0_multiHit,
  output logic         io_out_s3_full_pred_0_is_jal,
  output logic         io_out_s3_full_pred_0_is_jalr,
  output logic         io_out_s3_full_pred_0_is_call,
  output logic         io_out_s3_full_pred_0_is_ret,
  output logic         io_out_s3_full_pred_0_last_may_be_rvi_call,
  output logic         io_out_s3_full_pred_0_is_br_sharing,
  output logic         io_out_s3_full_pred_0_hit,
  output logic         io_out_s3_full_pred_1_br_taken_mask_0,
  output logic         io_out_s3_full_pred_1_br_taken_mask_1,
  output logic         io_out_s3_full_pred_1_slot_valids_0,
  output logic         io_out_s3_full_pred_1_slot_valids_1,
  output logic [49:0]  io_out_s3_full_pred_1_targets_0,
  output logic [49:0]  io_out_s3_full_pred_1_targets_1,
  output logic [49:0]  io_out_s3_full_pred_1_jalr_target,
  output logic [3:0]   io_out_s3_full_pred_1_offsets_0,
  output logic [3:0]   io_out_s3_full_pred_1_offsets_1,
  output logic [49:0]  io_out_s3_full_pred_1_fallThroughAddr,
  output logic         io_out_s3_full_pred_1_fallThroughErr,
  output logic         io_out_s3_full_pred_1_multiHit,
  output logic         io_out_s3_full_pred_1_is_jal,
  output logic         io_out_s3_full_pred_1_is_jalr,
  output logic         io_out_s3_full_pred_1_is_call,
  output logic         io_out_s3_full_pred_1_is_ret,
  output logic         io_out_s3_full_pred_1_last_may_be_rvi_call,
  output logic         io_out_s3_full_pred_1_is_br_sharing,
  output logic         io_out_s3_full_pred_1_hit,
  output logic         io_out_s3_full_pred_2_br_taken_mask_0,
  output logic         io_out_s3_full_pred_2_br_taken_mask_1,
  output logic         io_out_s3_full_pred_2_slot_valids_0,
  output logic         io_out_s3_full_pred_2_slot_valids_1,
  output logic [49:0]  io_out_s3_full_pred_2_targets_0,
  output logic [49:0]  io_out_s3_full_pred_2_targets_1,
  output logic [49:0]  io_out_s3_full_pred_2_jalr_target,
  output logic [3:0]   io_out_s3_full_pred_2_offsets_0,
  output logic [3:0]   io_out_s3_full_pred_2_offsets_1,
  output logic [49:0]  io_out_s3_full_pred_2_fallThroughAddr,
  output logic         io_out_s3_full_pred_2_fallThroughErr,
  output logic         io_out_s3_full_pred_2_multiHit,
  output logic         io_out_s3_full_pred_2_is_jal,
  output logic         io_out_s3_full_pred_2_is_jalr,
  output logic         io_out_s3_full_pred_2_is_call,
  output logic         io_out_s3_full_pred_2_is_ret,
  output logic         io_out_s3_full_pred_2_last_may_be_rvi_call,
  output logic         io_out_s3_full_pred_2_is_br_sharing,
  output logic         io_out_s3_full_pred_2_hit,
  output logic         io_out_s3_full_pred_3_br_taken_mask_0,
  output logic         io_out_s3_full_pred_3_br_taken_mask_1,
  output logic         io_out_s3_full_pred_3_slot_valids_0,
  output logic         io_out_s3_full_pred_3_slot_valids_1,
  output logic [49:0]  io_out_s3_full_pred_3_targets_0,
  output logic [49:0]  io_out_s3_full_pred_3_targets_1,
  output logic [49:0]  io_out_s3_full_pred_3_jalr_target,
  output logic [3:0]   io_out_s3_full_pred_3_offsets_0,
  output logic [3:0]   io_out_s3_full_pred_3_offsets_1,
  output logic [49:0]  io_out_s3_full_pred_3_fallThroughAddr,
  output logic         io_out_s3_full_pred_3_fallThroughErr,
  output logic         io_out_s3_full_pred_3_multiHit,
  output logic         io_out_s3_full_pred_3_is_jal,
  output logic         io_out_s3_full_pred_3_is_jalr,
  output logic         io_out_s3_full_pred_3_is_call,
  output logic         io_out_s3_full_pred_3_is_ret,
  output logic         io_out_s3_full_pred_3_last_may_be_rvi_call,
  output logic         io_out_s3_full_pred_3_is_br_sharing,
  output logic         io_out_s3_full_pred_3_hit,
  output logic [515:0] io_out_last_stage_meta,
  output logic [3:0]   io_out_last_stage_spec_info_ssp,
  output logic [2:0]   io_out_last_stage_spec_info_sctr,
  output logic         io_out_last_stage_spec_info_TOSW_flag,
  output logic [4:0]   io_out_last_stage_spec_info_TOSW_value,
  output logic         io_out_last_stage_spec_info_TOSR_flag,
  output logic [4:0]   io_out_last_stage_spec_info_TOSR_value,
  output logic         io_out_last_stage_spec_info_NOS_flag,
  output logic [4:0]   io_out_last_stage_spec_info_NOS_value,
  output logic [49:0]  io_out_last_stage_spec_info_topAddr,
  output logic         io_out_last_stage_spec_info_sc_disagree_0,
  output logic         io_out_last_stage_spec_info_sc_disagree_1,
  output logic         io_out_last_stage_ftb_entry_isCall,
  output logic         io_out_last_stage_ftb_entry_isRet,
  output logic         io_out_last_stage_ftb_entry_isJalr,
  output logic         io_out_last_stage_ftb_entry_valid,
  output logic [3:0]   io_out_last_stage_ftb_entry_brSlots_0_offset,
  output logic         io_out_last_stage_ftb_entry_brSlots_0_sharing,
  output logic         io_out_last_stage_ftb_entry_brSlots_0_valid,
  output logic [11:0]  io_out_last_stage_ftb_entry_brSlots_0_lower,
  output logic [1:0]   io_out_last_stage_ftb_entry_brSlots_0_tarStat,
  output logic [3:0]   io_out_last_stage_ftb_entry_tailSlot_offset,
  output logic         io_out_last_stage_ftb_entry_tailSlot_sharing,
  output logic         io_out_last_stage_ftb_entry_tailSlot_valid,
  output logic [19:0]  io_out_last_stage_ftb_entry_tailSlot_lower,
  output logic [1:0]   io_out_last_stage_ftb_entry_tailSlot_tarStat,
  output logic [3:0]   io_out_last_stage_ftb_entry_pftAddr,
  output logic         io_out_last_stage_ftb_entry_carry,
  output logic         io_out_last_stage_ftb_entry_last_may_be_rvi_call,
  output logic         io_out_last_stage_ftb_entry_strong_bias_0,
  output logic         io_out_last_stage_ftb_entry_strong_bias_1,
  input  logic         io_ctrl_ras_enable,
  input  logic         io_s0_fire_0,
  input  logic         io_s0_fire_1,
  input  logic         io_s0_fire_2,
  input  logic         io_s0_fire_3,
  input  logic         io_s1_fire_0,
  input  logic         io_s1_fire_1,
  input  logic         io_s1_fire_2,
  input  logic         io_s1_fire_3,
  input  logic         io_s2_fire_0,
  input  logic         io_s2_fire_1,
  input  logic         io_s2_fire_2,
  input  logic         io_s2_fire_3,
  input  logic         io_s3_fire_2,
  input  logic         io_s3_redirect_2,
  input  logic         io_update_valid,
  input  logic         io_update_bits_ftb_entry_isCall,
  input  logic         io_update_bits_ftb_entry_isRet,
  input  logic [3:0]   io_update_bits_ftb_entry_tailSlot_offset,
  input  logic         io_update_bits_ftb_entry_tailSlot_valid,
  input  logic         io_update_bits_cfi_idx_valid,
  input  logic [3:0]   io_update_bits_cfi_idx_bits,
  input  logic         io_update_bits_jmp_taken,
  input  logic [515:0] io_update_bits_meta,
  input  logic         io_redirect_valid,
  input  logic         io_redirect_bits_level,
  input  logic [49:0]  io_redirect_bits_cfiUpdate_pc,
  input  logic         io_redirect_bits_cfiUpdate_pd_valid,
  input  logic         io_redirect_bits_cfiUpdate_pd_isRVC,
  input  logic         io_redirect_bits_cfiUpdate_pd_isCall,
  input  logic         io_redirect_bits_cfiUpdate_pd_isRet,
  input  logic [3:0]   io_redirect_bits_cfiUpdate_ssp,
  input  logic [2:0]   io_redirect_bits_cfiUpdate_sctr,
  input  logic         io_redirect_bits_cfiUpdate_TOSW_flag,
  input  logic [4:0]   io_redirect_bits_cfiUpdate_TOSW_value,
  input  logic         io_redirect_bits_cfiUpdate_TOSR_flag,
  input  logic [4:0]   io_redirect_bits_cfiUpdate_TOSR_value,
  input  logic         io_redirect_bits_cfiUpdate_NOS_flag,
  input  logic [4:0]   io_redirect_bits_cfiUpdate_NOS_value
);

  // 核 <-> RASStack
  logic [PC_W-1:0]  stack_top_addr, stack_spec_push_addr, stack_s3_push_addr, stack_redirect_call_addr;
  ras_snap_t        stack_snap, stack_s3_snap, stack_redirect_snap;
  ras_pred_ptr_t    stack_commit_tosw;
  logic [SSP_W-1:0] stack_commit_ssp;
  logic             stack_near_overflow, stack_spec_push, stack_spec_pop, stack_s3_cancel;
  logic             stack_s3_missed_pop, stack_s3_missed_push;
  logic             stack_commit_valid, stack_commit_push, stack_commit_pop;
  logic             stack_redirect_valid, stack_redirect_is_call, stack_redirect_is_ret;

  xs_RAS_core u_core (
    .clock                    (clock),
    .reset                    (reset),
    .reset_vector             (io_reset_vector),
    .ras_enable               (io_ctrl_ras_enable),
    .s0_fire                  ({io_s0_fire_3, io_s0_fire_2, io_s0_fire_1, io_s0_fire_0}),
    .s1_fire                  ({io_s1_fire_3, io_s1_fire_2, io_s1_fire_1, io_s1_fire_0}),
    .s2_fire                  ({io_s2_fire_3, io_s2_fire_2, io_s2_fire_1, io_s2_fire_0}),
    .s3_fire                  (io_s3_fire_2),
    .s3_redirect              (io_s3_redirect_2),
    .s0_pc                    ({io_in_bits_s0_pc_3, io_in_bits_s0_pc_2, io_in_bits_s0_pc_1, io_in_bits_s0_pc_0}),
    .s2_pc                    ({io_out_s2_pc_3, io_out_s2_pc_2, io_out_s2_pc_1, io_out_s2_pc_0}),
    .s3_pc                    ({io_out_s3_pc_3, io_out_s3_pc_2, io_out_s3_pc_1, io_out_s3_pc_0}),
    .s2_pred                  ({io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1, io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0, io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1, io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0, io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing, io_in_bits_resp_in_0_s2_full_pred_2_hit, io_in_bits_resp_in_0_s2_full_pred_2_is_call, io_in_bits_resp_in_0_s2_full_pred_2_is_ret, io_in_bits_resp_in_0_s2_full_pred_2_is_jalr, io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr}),
    .s3_pred                  ({io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1, io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0, io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1, io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0, io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing, io_in_bits_resp_in_0_s3_full_pred_2_hit, io_in_bits_resp_in_0_s3_full_pred_2_is_call, io_in_bits_resp_in_0_s3_full_pred_2_is_ret, io_in_bits_resp_in_0_s3_full_pred_2_is_jalr, io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr}),
    .s2_fall_through_addr     (io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr),
    .s2_last_may_be_rvi_call  (io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call),
    .s2_jalr_target_in        ({io_in_bits_resp_in_0_s2_full_pred_3_jalr_target, io_in_bits_resp_in_0_s2_full_pred_2_jalr_target, io_in_bits_resp_in_0_s2_full_pred_1_jalr_target, io_in_bits_resp_in_0_s2_full_pred_0_jalr_target}),
    .s2_last_target_in        ({io_in_bits_resp_in_0_s2_full_pred_3_targets_1, io_in_bits_resp_in_0_s2_full_pred_2_targets_1, io_in_bits_resp_in_0_s2_full_pred_1_targets_1, io_in_bits_resp_in_0_s2_full_pred_0_targets_1}),
    .s2_jalr_target_out       ({io_out_s2_full_pred_3_jalr_target, io_out_s2_full_pred_2_jalr_target, io_out_s2_full_pred_1_jalr_target, io_out_s2_full_pred_0_jalr_target}),
    .s2_last_target_out       ({io_out_s2_full_pred_3_targets_1, io_out_s2_full_pred_2_targets_1, io_out_s2_full_pred_1_targets_1, io_out_s2_full_pred_0_targets_1}),
    .s3_jalr_target_in        ({io_in_bits_resp_in_0_s3_full_pred_3_jalr_target, io_in_bits_resp_in_0_s3_full_pred_2_jalr_target, io_in_bits_resp_in_0_s3_full_pred_1_jalr_target, io_in_bits_resp_in_0_s3_full_pred_0_jalr_target}),
    .s3_last_target_in        ({io_in_bits_resp_in_0_s3_full_pred_3_targets_1, io_in_bits_resp_in_0_s3_full_pred_2_targets_1, io_in_bits_resp_in_0_s3_full_pred_1_targets_1, io_in_bits_resp_in_0_s3_full_pred_0_targets_1}),
    .s3_jalr_target_out       ({io_out_s3_full_pred_3_jalr_target, io_out_s3_full_pred_2_jalr_target, io_out_s3_full_pred_1_jalr_target, io_out_s3_full_pred_0_jalr_target}),
    .s3_last_target_out       ({io_out_s3_full_pred_3_targets_1, io_out_s3_full_pred_2_targets_1, io_out_s3_full_pred_1_targets_1, io_out_s3_full_pred_0_targets_1}),
    .last_stage_meta          (io_out_last_stage_meta),
    .last_stage_snap          ({io_out_last_stage_spec_info_ssp, io_out_last_stage_spec_info_sctr, io_out_last_stage_spec_info_TOSW_flag, io_out_last_stage_spec_info_TOSW_value, io_out_last_stage_spec_info_TOSR_flag, io_out_last_stage_spec_info_TOSR_value, io_out_last_stage_spec_info_NOS_flag, io_out_last_stage_spec_info_NOS_value}),
    .last_stage_top_addr      (io_out_last_stage_spec_info_topAddr),
    .redirect_valid           (io_redirect_valid),
    .redirect_level           (io_redirect_bits_level),
    .redirect_pc              (io_redirect_bits_cfiUpdate_pc),
    .redirect_pd_valid        (io_redirect_bits_cfiUpdate_pd_valid),
    .redirect_pd_is_rvc       (io_redirect_bits_cfiUpdate_pd_isRVC),
    .redirect_pd_is_call      (io_redirect_bits_cfiUpdate_pd_isCall),
    .redirect_pd_is_ret       (io_redirect_bits_cfiUpdate_pd_isRet),
    .redirect_snap            ({io_redirect_bits_cfiUpdate_ssp, io_redirect_bits_cfiUpdate_sctr, io_redirect_bits_cfiUpdate_TOSW_flag, io_redirect_bits_cfiUpdate_TOSW_value, io_redirect_bits_cfiUpdate_TOSR_flag, io_redirect_bits_cfiUpdate_TOSR_value, io_redirect_bits_cfiUpdate_NOS_flag, io_redirect_bits_cfiUpdate_NOS_value}),
    .update_valid             (io_update_valid),
    .update_entry_is_call     (io_update_bits_ftb_entry_isCall),
    .update_entry_is_ret      (io_update_bits_ftb_entry_isRet),
    .update_tail_slot_offset  (io_update_bits_ftb_entry_tailSlot_offset),
    .update_tail_slot_valid   (io_update_bits_ftb_entry_tailSlot_valid),
    .update_cfi_idx_valid     (io_update_bits_cfi_idx_valid),
    .update_cfi_idx_bits      (io_update_bits_cfi_idx_bits),
    .update_jmp_taken         (io_update_bits_jmp_taken),
    .update_meta              (io_update_bits_meta),
    .stack_top_addr           (stack_top_addr),
    .stack_snap               (stack_snap),
    .stack_near_overflow      (stack_near_overflow),
    .stack_spec_push          (stack_spec_push),
    .stack_spec_pop           (stack_spec_pop),
    .stack_spec_push_addr     (stack_spec_push_addr),
    .stack_s3_cancel          (stack_s3_cancel),
    .stack_s3_snap            (stack_s3_snap),
    .stack_s3_missed_pop      (stack_s3_missed_pop),
    .stack_s3_missed_push     (stack_s3_missed_push),
    .stack_s3_push_addr       (stack_s3_push_addr),
    .stack_commit_valid       (stack_commit_valid),
    .stack_commit_push        (stack_commit_push),
    .stack_commit_pop         (stack_commit_pop),
    .stack_commit_tosw        (stack_commit_tosw),
    .stack_commit_ssp         (stack_commit_ssp),
    .stack_redirect_valid     (stack_redirect_valid),
    .stack_redirect_is_call   (stack_redirect_is_call),
    .stack_redirect_is_ret    (stack_redirect_is_ret),
    .stack_redirect_snap      (stack_redirect_snap),
    .stack_redirect_call_addr (stack_redirect_call_addr)
  );

  RASStack RASStack (
    .clock                       (clock),
    .reset                       (reset),
    .io_spec_push_valid          (stack_spec_push),
    .io_spec_pop_valid           (stack_spec_pop),
    .io_spec_push_addr           (stack_spec_push_addr),
    .io_s2_fire                  (io_s2_fire_2),
    .io_s3_fire                  (io_s3_fire_2),
    .io_s3_cancel                (stack_s3_cancel),
    .io_s3_meta_ssp              (stack_s3_snap.ssp),
    .io_s3_meta_sctr             (stack_s3_snap.sctr),
    .io_s3_meta_TOSW_flag        (stack_s3_snap.tosw.flag),
    .io_s3_meta_TOSW_value       (stack_s3_snap.tosw.value),
    .io_s3_meta_TOSR_flag        (stack_s3_snap.tosr.flag),
    .io_s3_meta_TOSR_value       (stack_s3_snap.tosr.value),
    .io_s3_meta_NOS_flag         (stack_s3_snap.nos.flag),
    .io_s3_meta_NOS_value        (stack_s3_snap.nos.value),
    .io_s3_missed_pop            (stack_s3_missed_pop),
    .io_s3_missed_push           (stack_s3_missed_push),
    .io_s3_pushAddr              (stack_s3_push_addr),
    .io_spec_pop_addr            (stack_top_addr),
    .io_commit_valid             (stack_commit_valid),
    .io_commit_push_valid        (stack_commit_push),
    .io_commit_pop_valid         (stack_commit_pop),
    .io_commit_meta_TOSW_flag    (stack_commit_tosw.flag),
    .io_commit_meta_TOSW_value   (stack_commit_tosw.value),
    .io_commit_meta_ssp          (stack_commit_ssp),
    .io_redirect_valid           (stack_redirect_valid),
    .io_redirect_isCall          (stack_redirect_is_call),
    .io_redirect_isRet           (stack_redirect_is_ret),
    .io_redirect_meta_ssp        (stack_redirect_snap.ssp),
    .io_redirect_meta_sctr       (stack_redirect_snap.sctr),
    .io_redirect_meta_TOSW_flag  (stack_redirect_snap.tosw.flag),
    .io_redirect_meta_TOSW_value (stack_redirect_snap.tosw.value),
    .io_redirect_meta_TOSR_flag  (stack_redirect_snap.tosr.flag),
    .io_redirect_meta_TOSR_value (stack_redirect_snap.tosr.value),
    .io_redirect_meta_NOS_flag   (stack_redirect_snap.nos.flag),
    .io_redirect_meta_NOS_value  (stack_redirect_snap.nos.value),
    .io_redirect_callAddr        (stack_redirect_call_addr),
    .io_ssp                      (stack_snap.ssp),
    .io_sctr                     (stack_snap.sctr),
    .io_TOSR_flag                (stack_snap.tosr.flag),
    .io_TOSR_value               (stack_snap.tosr.value),
    .io_TOSW_flag                (stack_snap.tosw.flag),
    .io_TOSW_value               (stack_snap.tosw.value),
    .io_NOS_flag                 (stack_snap.nos.flag),
    .io_NOS_value                (stack_snap.nos.value),
    .io_spec_near_overflow       (stack_near_overflow)
  );

  // 本层不改动的预测字段：原样直通
  assign io_out_s2_full_pred_0_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0;
  assign io_out_s2_full_pred_0_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1;
  assign io_out_s2_full_pred_0_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0;
  assign io_out_s2_full_pred_0_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1;
  assign io_out_s2_full_pred_0_targets_0 = io_in_bits_resp_in_0_s2_full_pred_0_targets_0;
  assign io_out_s2_full_pred_0_offsets_0 = io_in_bits_resp_in_0_s2_full_pred_0_offsets_0;
  assign io_out_s2_full_pred_0_offsets_1 = io_in_bits_resp_in_0_s2_full_pred_0_offsets_1;
  assign io_out_s2_full_pred_0_fallThroughAddr = io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr;
  assign io_out_s2_full_pred_0_fallThroughErr = io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr;
  assign io_out_s2_full_pred_0_is_jal = io_in_bits_resp_in_0_s2_full_pred_0_is_jal;
  assign io_out_s2_full_pred_0_is_jalr = io_in_bits_resp_in_0_s2_full_pred_0_is_jalr;
  assign io_out_s2_full_pred_0_is_call = io_in_bits_resp_in_0_s2_full_pred_0_is_call;
  assign io_out_s2_full_pred_0_is_ret = io_in_bits_resp_in_0_s2_full_pred_0_is_ret;
  assign io_out_s2_full_pred_0_last_may_be_rvi_call = io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call;
  assign io_out_s2_full_pred_0_is_br_sharing = io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing;
  assign io_out_s2_full_pred_0_hit = io_in_bits_resp_in_0_s2_full_pred_0_hit;
  assign io_out_s2_full_pred_1_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0;
  assign io_out_s2_full_pred_1_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1;
  assign io_out_s2_full_pred_1_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0;
  assign io_out_s2_full_pred_1_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1;
  assign io_out_s2_full_pred_1_targets_0 = io_in_bits_resp_in_0_s2_full_pred_1_targets_0;
  assign io_out_s2_full_pred_1_offsets_0 = io_in_bits_resp_in_0_s2_full_pred_1_offsets_0;
  assign io_out_s2_full_pred_1_offsets_1 = io_in_bits_resp_in_0_s2_full_pred_1_offsets_1;
  assign io_out_s2_full_pred_1_fallThroughAddr = io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr;
  assign io_out_s2_full_pred_1_fallThroughErr = io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr;
  assign io_out_s2_full_pred_1_is_jal = io_in_bits_resp_in_0_s2_full_pred_1_is_jal;
  assign io_out_s2_full_pred_1_is_jalr = io_in_bits_resp_in_0_s2_full_pred_1_is_jalr;
  assign io_out_s2_full_pred_1_is_call = io_in_bits_resp_in_0_s2_full_pred_1_is_call;
  assign io_out_s2_full_pred_1_is_ret = io_in_bits_resp_in_0_s2_full_pred_1_is_ret;
  assign io_out_s2_full_pred_1_last_may_be_rvi_call = io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call;
  assign io_out_s2_full_pred_1_is_br_sharing = io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing;
  assign io_out_s2_full_pred_1_hit = io_in_bits_resp_in_0_s2_full_pred_1_hit;
  assign io_out_s2_full_pred_2_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0;
  assign io_out_s2_full_pred_2_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1;
  assign io_out_s2_full_pred_2_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0;
  assign io_out_s2_full_pred_2_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1;
  assign io_out_s2_full_pred_2_targets_0 = io_in_bits_resp_in_0_s2_full_pred_2_targets_0;
  assign io_out_s2_full_pred_2_offsets_0 = io_in_bits_resp_in_0_s2_full_pred_2_offsets_0;
  assign io_out_s2_full_pred_2_offsets_1 = io_in_bits_resp_in_0_s2_full_pred_2_offsets_1;
  assign io_out_s2_full_pred_2_fallThroughAddr = io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr;
  assign io_out_s2_full_pred_2_fallThroughErr = io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr;
  assign io_out_s2_full_pred_2_is_jal = io_in_bits_resp_in_0_s2_full_pred_2_is_jal;
  assign io_out_s2_full_pred_2_is_jalr = io_in_bits_resp_in_0_s2_full_pred_2_is_jalr;
  assign io_out_s2_full_pred_2_is_call = io_in_bits_resp_in_0_s2_full_pred_2_is_call;
  assign io_out_s2_full_pred_2_is_ret = io_in_bits_resp_in_0_s2_full_pred_2_is_ret;
  assign io_out_s2_full_pred_2_last_may_be_rvi_call = io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call;
  assign io_out_s2_full_pred_2_is_br_sharing = io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing;
  assign io_out_s2_full_pred_2_hit = io_in_bits_resp_in_0_s2_full_pred_2_hit;
  assign io_out_s2_full_pred_3_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0;
  assign io_out_s2_full_pred_3_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1;
  assign io_out_s2_full_pred_3_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0;
  assign io_out_s2_full_pred_3_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1;
  assign io_out_s2_full_pred_3_targets_0 = io_in_bits_resp_in_0_s2_full_pred_3_targets_0;
  assign io_out_s2_full_pred_3_offsets_0 = io_in_bits_resp_in_0_s2_full_pred_3_offsets_0;
  assign io_out_s2_full_pred_3_offsets_1 = io_in_bits_resp_in_0_s2_full_pred_3_offsets_1;
  assign io_out_s2_full_pred_3_fallThroughAddr = io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr;
  assign io_out_s2_full_pred_3_fallThroughErr = io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr;
  assign io_out_s2_full_pred_3_is_jal = io_in_bits_resp_in_0_s2_full_pred_3_is_jal;
  assign io_out_s2_full_pred_3_is_jalr = io_in_bits_resp_in_0_s2_full_pred_3_is_jalr;
  assign io_out_s2_full_pred_3_is_call = io_in_bits_resp_in_0_s2_full_pred_3_is_call;
  assign io_out_s2_full_pred_3_is_ret = io_in_bits_resp_in_0_s2_full_pred_3_is_ret;
  assign io_out_s2_full_pred_3_last_may_be_rvi_call = io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call;
  assign io_out_s2_full_pred_3_is_br_sharing = io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing;
  assign io_out_s2_full_pred_3_hit = io_in_bits_resp_in_0_s2_full_pred_3_hit;
  assign io_out_s3_full_pred_0_br_taken_mask_0 = io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0;
  assign io_out_s3_full_pred_0_br_taken_mask_1 = io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1;
  assign io_out_s3_full_pred_0_slot_valids_0 = io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0;
  assign io_out_s3_full_pred_0_slot_valids_1 = io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1;
  assign io_out_s3_full_pred_0_targets_0 = io_in_bits_resp_in_0_s3_full_pred_0_targets_0;
  assign io_out_s3_full_pred_0_offsets_0 = io_in_bits_resp_in_0_s3_full_pred_0_offsets_0;
  assign io_out_s3_full_pred_0_offsets_1 = io_in_bits_resp_in_0_s3_full_pred_0_offsets_1;
  assign io_out_s3_full_pred_0_fallThroughAddr = io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr;
  assign io_out_s3_full_pred_0_fallThroughErr = io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr;
  assign io_out_s3_full_pred_0_multiHit = io_in_bits_resp_in_0_s3_full_pred_0_multiHit;
  assign io_out_s3_full_pred_0_is_jal = io_in_bits_resp_in_0_s3_full_pred_0_is_jal;
  assign io_out_s3_full_pred_0_is_jalr = io_in_bits_resp_in_0_s3_full_pred_0_is_jalr;
  assign io_out_s3_full_pred_0_is_call = io_in_bits_resp_in_0_s3_full_pred_0_is_call;
  assign io_out_s3_full_pred_0_is_ret = io_in_bits_resp_in_0_s3_full_pred_0_is_ret;
  assign io_out_s3_full_pred_0_last_may_be_rvi_call = io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call;
  assign io_out_s3_full_pred_0_is_br_sharing = io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing;
  assign io_out_s3_full_pred_0_hit = io_in_bits_resp_in_0_s3_full_pred_0_hit;
  assign io_out_s3_full_pred_1_br_taken_mask_0 = io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0;
  assign io_out_s3_full_pred_1_br_taken_mask_1 = io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1;
  assign io_out_s3_full_pred_1_slot_valids_0 = io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0;
  assign io_out_s3_full_pred_1_slot_valids_1 = io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1;
  assign io_out_s3_full_pred_1_targets_0 = io_in_bits_resp_in_0_s3_full_pred_1_targets_0;
  assign io_out_s3_full_pred_1_offsets_0 = io_in_bits_resp_in_0_s3_full_pred_1_offsets_0;
  assign io_out_s3_full_pred_1_offsets_1 = io_in_bits_resp_in_0_s3_full_pred_1_offsets_1;
  assign io_out_s3_full_pred_1_fallThroughAddr = io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr;
  assign io_out_s3_full_pred_1_fallThroughErr = io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr;
  assign io_out_s3_full_pred_1_multiHit = io_in_bits_resp_in_0_s3_full_pred_1_multiHit;
  assign io_out_s3_full_pred_1_is_jal = io_in_bits_resp_in_0_s3_full_pred_1_is_jal;
  assign io_out_s3_full_pred_1_is_jalr = io_in_bits_resp_in_0_s3_full_pred_1_is_jalr;
  assign io_out_s3_full_pred_1_is_call = io_in_bits_resp_in_0_s3_full_pred_1_is_call;
  assign io_out_s3_full_pred_1_is_ret = io_in_bits_resp_in_0_s3_full_pred_1_is_ret;
  assign io_out_s3_full_pred_1_last_may_be_rvi_call = io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call;
  assign io_out_s3_full_pred_1_is_br_sharing = io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing;
  assign io_out_s3_full_pred_1_hit = io_in_bits_resp_in_0_s3_full_pred_1_hit;
  assign io_out_s3_full_pred_2_br_taken_mask_0 = io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0;
  assign io_out_s3_full_pred_2_br_taken_mask_1 = io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1;
  assign io_out_s3_full_pred_2_slot_valids_0 = io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0;
  assign io_out_s3_full_pred_2_slot_valids_1 = io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1;
  assign io_out_s3_full_pred_2_targets_0 = io_in_bits_resp_in_0_s3_full_pred_2_targets_0;
  assign io_out_s3_full_pred_2_offsets_0 = io_in_bits_resp_in_0_s3_full_pred_2_offsets_0;
  assign io_out_s3_full_pred_2_offsets_1 = io_in_bits_resp_in_0_s3_full_pred_2_offsets_1;
  assign io_out_s3_full_pred_2_fallThroughAddr = io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr;
  assign io_out_s3_full_pred_2_fallThroughErr = io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr;
  assign io_out_s3_full_pred_2_multiHit = io_in_bits_resp_in_0_s3_full_pred_2_multiHit;
  assign io_out_s3_full_pred_2_is_jal = io_in_bits_resp_in_0_s3_full_pred_2_is_jal;
  assign io_out_s3_full_pred_2_is_jalr = io_in_bits_resp_in_0_s3_full_pred_2_is_jalr;
  assign io_out_s3_full_pred_2_is_call = io_in_bits_resp_in_0_s3_full_pred_2_is_call;
  assign io_out_s3_full_pred_2_is_ret = io_in_bits_resp_in_0_s3_full_pred_2_is_ret;
  assign io_out_s3_full_pred_2_last_may_be_rvi_call = io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call;
  assign io_out_s3_full_pred_2_is_br_sharing = io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing;
  assign io_out_s3_full_pred_2_hit = io_in_bits_resp_in_0_s3_full_pred_2_hit;
  assign io_out_s3_full_pred_3_br_taken_mask_0 = io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0;
  assign io_out_s3_full_pred_3_br_taken_mask_1 = io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1;
  assign io_out_s3_full_pred_3_slot_valids_0 = io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0;
  assign io_out_s3_full_pred_3_slot_valids_1 = io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1;
  assign io_out_s3_full_pred_3_targets_0 = io_in_bits_resp_in_0_s3_full_pred_3_targets_0;
  assign io_out_s3_full_pred_3_offsets_0 = io_in_bits_resp_in_0_s3_full_pred_3_offsets_0;
  assign io_out_s3_full_pred_3_offsets_1 = io_in_bits_resp_in_0_s3_full_pred_3_offsets_1;
  assign io_out_s3_full_pred_3_fallThroughAddr = io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr;
  assign io_out_s3_full_pred_3_fallThroughErr = io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr;
  assign io_out_s3_full_pred_3_multiHit = io_in_bits_resp_in_0_s3_full_pred_3_multiHit;
  assign io_out_s3_full_pred_3_is_jal = io_in_bits_resp_in_0_s3_full_pred_3_is_jal;
  assign io_out_s3_full_pred_3_is_jalr = io_in_bits_resp_in_0_s3_full_pred_3_is_jalr;
  assign io_out_s3_full_pred_3_is_call = io_in_bits_resp_in_0_s3_full_pred_3_is_call;
  assign io_out_s3_full_pred_3_is_ret = io_in_bits_resp_in_0_s3_full_pred_3_is_ret;
  assign io_out_s3_full_pred_3_last_may_be_rvi_call = io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call;
  assign io_out_s3_full_pred_3_is_br_sharing = io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing;
  assign io_out_s3_full_pred_3_hit = io_in_bits_resp_in_0_s3_full_pred_3_hit;
  assign io_out_last_stage_spec_info_sc_disagree_0 = io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0;
  assign io_out_last_stage_spec_info_sc_disagree_1 = io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1;
  assign io_out_last_stage_ftb_entry_isCall = io_in_bits_resp_in_0_last_stage_ftb_entry_isCall;
  assign io_out_last_stage_ftb_entry_isRet = io_in_bits_resp_in_0_last_stage_ftb_entry_isRet;
  assign io_out_last_stage_ftb_entry_isJalr = io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr;
  assign io_out_last_stage_ftb_entry_valid = io_in_bits_resp_in_0_last_stage_ftb_entry_valid;
  assign io_out_last_stage_ftb_entry_brSlots_0_offset = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset;
  assign io_out_last_stage_ftb_entry_brSlots_0_sharing = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing;
  assign io_out_last_stage_ftb_entry_brSlots_0_valid = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid;
  assign io_out_last_stage_ftb_entry_brSlots_0_lower = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower;
  assign io_out_last_stage_ftb_entry_brSlots_0_tarStat = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat;
  assign io_out_last_stage_ftb_entry_tailSlot_offset = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset;
  assign io_out_last_stage_ftb_entry_tailSlot_sharing = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing;
  assign io_out_last_stage_ftb_entry_tailSlot_valid = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid;
  assign io_out_last_stage_ftb_entry_tailSlot_lower = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower;
  assign io_out_last_stage_ftb_entry_tailSlot_tarStat = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat;
  assign io_out_last_stage_ftb_entry_pftAddr = io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr;
  assign io_out_last_stage_ftb_entry_carry = io_in_bits_resp_in_0_last_stage_ftb_entry_carry;
  assign io_out_last_stage_ftb_entry_last_may_be_rvi_call = io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call;
  assign io_out_last_stage_ftb_entry_strong_bias_0 = io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0;
  assign io_out_last_stage_ftb_entry_strong_bias_1 = io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1;

endmodule
// END GENERATED(RAS)
