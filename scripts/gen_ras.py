#!/usr/bin/env python3
"""
RAS 生成器：解析 golden/chisel-rtl/RAS.sv 端口表，生成
  - rtl/frontend/RAS_core_top.sv  : 模块 xs_RAS_core，与 golden RAS 同端口；含 s1/s2/s3
        pc 复制、redirect/update 打拍、s3_meta 锁存、jalr/targets 改写，以及实例化
        rtl/frontend/RAS.sv 里的可读 xs_RASStack。绝大多数 io_out_* 为 io_in_* 透传。
  - rtl/frontend/RAS_wrapper.sv   : 模块 RAS (golden 同名), 例化 xs_RAS_core u_core，端口 1:1。
  - verif/ut/RAS/variants_xs.sv   : 模块 RAS_xs，同 wrapper 改名，UT 用。
  - verif/ut/RAS/tb.sv            : golden RAS vs RAS_xs 双例化随机比对。

手写核心逻辑 (流水寄存器/RASStack 连接/输出改写) 以模板形式内嵌于本脚本；
透传 assign 由端口表自动推导 (io_out_X -> io_in_bits_resp_in_0_X，少数特例单列)。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"


def parse_ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def decl_str(d, w, n, kind="port"):
    ws = f"[{w-1}:0] " if w > 1 else ""
    if kind == "port":
        return f"  {d:6s} {ws}{n}"
    return f"  {d:6s} {ws}{n}"


# 顶层手写逻辑体 (xs_RAS_core 的 module 头之后到 endmodule 之前)。
CORE_BODY = r"""
  // RASStack 输出连线 (提前声明, 供各段引用)
  wire        s2_spec_push, s2_spec_pop;
  wire [49:0] _RASStack_io_spec_pop_addr;
  wire [3:0]  _RASStack_io_ssp;
  wire [2:0]  _RASStack_io_sctr;
  wire        _RASStack_io_TOSR_flag;  wire [4:0] _RASStack_io_TOSR_value;
  wire        _RASStack_io_TOSW_flag;  wire [4:0] _RASStack_io_TOSW_value;
  wire        _RASStack_io_NOS_flag;   wire [4:0] _RASStack_io_NOS_value;
  wire        _RASStack_io_spec_near_overflow;

  // s2->s3 锁存 (提前声明)
  reg  [49:0] s3_top;
  reg  [49:0] s3_spec_new_addr;
  reg         s3_pushed_in_s2, s3_popped_in_s2;
  reg  [3:0]  s3_meta_ssp;
  reg  [2:0]  s3_meta_sctr;
  reg         s3_meta_TOSW_flag;  reg [4:0] s3_meta_TOSW_value;
  reg         s3_meta_TOSR_flag;  reg [4:0] s3_meta_TOSR_value;
  reg         s3_meta_NOS_flag;   reg [4:0] s3_meta_NOS_value;

  // ==========================================================================
  // 1. s2/s3 推测 push/pop 触发条件 (来自 s2/s3 full_pred(2))
  // ==========================================================================
  // hit_taken_on_call/ret 的展开 (Chisel BranchPrediction.hit_taken_on_*)
  wire s2_realtaken_0 = io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0
                      & io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0;
  wire s2_realtaken_1 = io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing
                      & io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1;
  // taken_on_tail = !(br0 taken) & slot1 valid & (br1taken | !sharing) & hit & !sharing
  wire s2_taken_on_tail =
        ~(s2_realtaken_0 & io_in_bits_resp_in_0_s2_full_pred_2_hit)
      & io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1
      & (s2_realtaken_1 | ~io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing)
      & io_in_bits_resp_in_0_s2_full_pred_2_hit
      & ~io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing;
  assign s2_spec_push = io_s2_fire_2 & s2_taken_on_tail
                      & io_in_bits_resp_in_0_s2_full_pred_2_is_call & ~io_s3_redirect_2;
  assign s2_spec_pop  = io_s2_fire_2 & s2_taken_on_tail
                      & io_in_bits_resp_in_0_s2_full_pred_2_is_ret  & ~io_s3_redirect_2;

  // s2 推测新地址 = fallThroughAddr + (last_may_be_rvi_call ? 2 : 0)
  wire [49:0] s2_spec_new_addr =
        io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr
      + {48'h0, io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call, 1'h0};

  // s2 ret 命中时用栈顶覆盖 jalr_target
  wire s2_use_ras = io_in_bits_resp_in_0_s2_full_pred_2_is_ret & io_ctrl_ras_enable;
  wire [49:0] s2_jalr_target_0 = s2_use_ras ? _RASStack_io_spec_pop_addr
                                            : io_in_bits_resp_in_0_s2_full_pred_0_jalr_target;
  wire [49:0] s2_jalr_target_1 = s2_use_ras ? _RASStack_io_spec_pop_addr
                                            : io_in_bits_resp_in_0_s2_full_pred_1_jalr_target;
  wire [49:0] s2_jalr_target_2 = s2_use_ras ? _RASStack_io_spec_pop_addr
                                            : io_in_bits_resp_in_0_s2_full_pred_2_jalr_target;
  wire [49:0] s2_jalr_target_3 = s2_use_ras ? _RASStack_io_spec_pop_addr
                                            : io_in_bits_resp_in_0_s2_full_pred_3_jalr_target;

  // s3 阶段
  wire s3_is_jalr = io_in_bits_resp_in_0_s3_full_pred_2_is_jalr
                  & ~io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr;
  wire s3_use_ras = io_in_bits_resp_in_0_s3_full_pred_2_is_ret
                  & ~io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr & io_ctrl_ras_enable;
  wire [49:0] s3_jalr_target_0 = s3_use_ras ? s3_top : io_in_bits_resp_in_0_s3_full_pred_0_jalr_target;
  wire [49:0] s3_jalr_target_1 = s3_use_ras ? s3_top : io_in_bits_resp_in_0_s3_full_pred_1_jalr_target;
  wire [49:0] s3_jalr_target_2 = s3_use_ras ? s3_top : io_in_bits_resp_in_0_s3_full_pred_2_jalr_target;
  wire [49:0] s3_jalr_target_3 = s3_use_ras ? s3_top : io_in_bits_resp_in_0_s3_full_pred_3_jalr_target;

  wire s3_realtaken_0 = io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0
                      & io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0;
  wire s3_realtaken_1 = io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing
                      & io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1;
  wire s3_taken_on_tail =
        ~(s3_realtaken_0 & io_in_bits_resp_in_0_s3_full_pred_2_hit)
      & io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1
      & (s3_realtaken_1 | ~io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing)
      & io_in_bits_resp_in_0_s3_full_pred_2_hit
      & ~io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing;
  wire s3_push = s3_taken_on_tail & io_in_bits_resp_in_0_s3_full_pred_2_is_call
               & ~io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr;
  wire s3_pop  = s3_taken_on_tail & io_in_bits_resp_in_0_s3_full_pred_2_is_ret
               & ~io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr;
  wire s3_cancel = io_s3_fire_2 & ((s3_pushed_in_s2 != s3_push) | (s3_popped_in_s2 != s3_pop));

  // ==========================================================================
  // 2. 流水 pc 复制寄存器 (debug 用，原样复刻 firtool 的分段更新)
  // ==========================================================================
  reg  [49:0] s1_pc_dup_0, s1_pc_dup_1, s1_pc_dup_2, s1_pc_dup_3;
  reg  [25:0] s2_pc_seg0 [0:3];
  reg  [11:0] s2_pc_seg1 [0:3];
  reg  [11:0] s2_pc_seg2 [0:3];
  reg  [25:0] s3_pc_seg0 [0:3];
  reg  [11:0] s3_pc_seg1 [0:3];
  reg  [11:0] s3_pc_seg2 [0:3];
  reg         REG, REG_1;

  wire [49:0] s1_pc [0:3];
  assign s1_pc[0] = s1_pc_dup_0; assign s1_pc[1] = s1_pc_dup_1;
  assign s1_pc[2] = s1_pc_dup_2; assign s1_pc[3] = s1_pc_dup_3;
  wire [49:0] s0_pc [0:3];
  assign s0_pc[0] = io_in_bits_s0_pc_0; assign s0_pc[1] = io_in_bits_s0_pc_1;
  assign s0_pc[2] = io_in_bits_s0_pc_2; assign s0_pc[3] = io_in_bits_s0_pc_3;
  wire [3:0] s0_fire = {io_s0_fire_3, io_s0_fire_2, io_s0_fire_1, io_s0_fire_0};
  wire [3:0] s1_fire = {io_s1_fire_3, io_s1_fire_2, io_s1_fire_1, io_s1_fire_0};
  wire [3:0] s2_fire = {io_s2_fire_3, io_s2_fire_2, io_s2_fire_1, io_s2_fire_0};

  wire [49:0] _rstvec = {2'h0, io_reset_vector};

  // s2_pc 重组地址 (供 io_out_s2_pc_*)
  wire [49:0] s2_pc_addr [0:3];
  wire [49:0] s3_pc_addr [0:3];
  genvar gp;
  generate
    for (gp = 0; gp < 4; gp = gp + 1) begin : g_pc_addr
      assign s2_pc_addr[gp] = {s2_pc_seg0[gp], s2_pc_seg1[gp], s2_pc_seg2[gp]};
      assign s3_pc_addr[gp] = {s3_pc_seg0[gp], s3_pc_seg1[gp], s3_pc_seg2[gp]};
    end
  endgenerate

  always @(posedge clock) begin
    if (REG_1) begin
      s1_pc_dup_0 <= _rstvec; s1_pc_dup_1 <= _rstvec;
      s1_pc_dup_2 <= _rstvec; s1_pc_dup_3 <= _rstvec;
    end else begin
      if (io_s0_fire_0) s1_pc_dup_0 <= io_in_bits_s0_pc_0;
      if (io_s0_fire_1) s1_pc_dup_1 <= io_in_bits_s0_pc_1;
      if (io_s0_fire_2) s1_pc_dup_2 <= io_in_bits_s0_pc_2;
      if (io_s0_fire_3) s1_pc_dup_3 <= io_in_bits_s0_pc_3;
    end
    REG   <= reset;
    REG_1 <= REG & ~reset;
  end

  integer pi;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      for (pi = 0; pi < 4; pi = pi + 1) begin
        s2_pc_seg0[pi] <= 26'h0; s2_pc_seg1[pi] <= 12'h0; s2_pc_seg2[pi] <= 12'h0;
        s3_pc_seg0[pi] <= 26'h0; s3_pc_seg1[pi] <= 12'h0; s3_pc_seg2[pi] <= 12'h0;
      end
    end else begin
      for (pi = 0; pi < 4; pi = pi + 1) begin
        // s2 段: 仅当对应段与 s1_pc 不同且 s1_fire 时更新
        if ((s2_pc_seg0[pi] != s1_pc[pi][49:24]) & s1_fire[pi]) s2_pc_seg0[pi] <= s1_pc[pi][49:24];
        if ((s2_pc_seg1[pi] != s1_pc[pi][23:12]) & s1_fire[pi]) s2_pc_seg1[pi] <= s1_pc[pi][23:12];
        if (s1_fire[pi])                                        s2_pc_seg2[pi] <= s1_pc[pi][11:0];
        // s3 段: 与 s2 段比较
        if ((s3_pc_seg0[pi] != s2_pc_seg0[pi]) & s2_fire[pi]) s3_pc_seg0[pi] <= s2_pc_seg0[pi];
        if ((s3_pc_seg1[pi] != s2_pc_seg1[pi]) & s2_fire[pi]) s3_pc_seg1[pi] <= s2_pc_seg1[pi];
        if (s2_fire[pi])                                      s3_pc_seg2[pi] <= s2_pc_seg2[pi];
      end
    end
  end

  // ==========================================================================
  // 3. s2->s3 meta / 推测信息打拍
  // ==========================================================================
  always @(posedge clock) begin
    if (io_s2_fire_2) begin
      s3_top            <= _RASStack_io_spec_pop_addr;
      s3_spec_new_addr  <= s2_spec_new_addr;
      s3_pushed_in_s2   <= s2_spec_push;
      s3_popped_in_s2   <= s2_spec_pop;
      s3_meta_ssp       <= _RASStack_io_ssp;
      s3_meta_sctr      <= _RASStack_io_sctr;
      s3_meta_TOSW_flag <= _RASStack_io_TOSW_flag;
      s3_meta_TOSW_value<= _RASStack_io_TOSW_value;
      s3_meta_TOSR_flag <= _RASStack_io_TOSR_flag;
      s3_meta_TOSR_value<= _RASStack_io_TOSR_value;
      s3_meta_NOS_flag  <= _RASStack_io_NOS_flag;
      s3_meta_NOS_value <= _RASStack_io_NOS_value;
    end
  end

  // ==========================================================================
  // 4. redirect / update 输入打拍
  // ==========================================================================
  reg         redirect_valid_q;
  reg         redirect_level_q;
  reg  [49:0] redirect_pc_q;
  reg         redirect_pd_valid_q, redirect_pd_isRVC_q, redirect_pd_isCall_q, redirect_pd_isRet_q;
  reg  [3:0]  redirect_ssp_q;
  reg  [2:0]  redirect_sctr_q;
  reg         redirect_TOSW_flag_q;  reg [4:0] redirect_TOSW_value_q;
  reg         redirect_TOSR_flag_q;  reg [4:0] redirect_TOSR_value_q;
  reg         redirect_NOS_flag_q;   reg [4:0] redirect_NOS_value_q;

  reg         updateValid;
  reg         update_isCall_q, update_isRet_q;
  reg  [3:0]  update_tailOff_q;
  reg         update_tailValid_q;
  reg         update_cfiValid_q;
  reg  [3:0]  update_cfiBits_q;
  reg         update_jmpTaken_q;
  reg  [3:0]  updateMeta_ssp;
  reg         updateMeta_TOSW_flag;  reg [4:0] updateMeta_TOSW_value;

  always @(posedge clock) begin
    if (io_redirect_valid) begin
      redirect_level_q     <= io_redirect_bits_level;
      redirect_pc_q        <= io_redirect_bits_cfiUpdate_pc;
      redirect_pd_valid_q  <= io_redirect_bits_cfiUpdate_pd_valid;
      redirect_pd_isRVC_q  <= io_redirect_bits_cfiUpdate_pd_isRVC;
      redirect_pd_isCall_q <= io_redirect_bits_cfiUpdate_pd_isCall;
      redirect_pd_isRet_q  <= io_redirect_bits_cfiUpdate_pd_isRet;
      redirect_ssp_q       <= io_redirect_bits_cfiUpdate_ssp;
      redirect_sctr_q      <= io_redirect_bits_cfiUpdate_sctr;
      redirect_TOSW_flag_q <= io_redirect_bits_cfiUpdate_TOSW_flag;
      redirect_TOSW_value_q<= io_redirect_bits_cfiUpdate_TOSW_value;
      redirect_TOSR_flag_q <= io_redirect_bits_cfiUpdate_TOSR_flag;
      redirect_TOSR_value_q<= io_redirect_bits_cfiUpdate_TOSR_value;
      redirect_NOS_flag_q  <= io_redirect_bits_cfiUpdate_NOS_flag;
      redirect_NOS_value_q <= io_redirect_bits_cfiUpdate_NOS_value;
    end
    if (io_update_valid) begin
      update_isCall_q   <= io_update_bits_ftb_entry_isCall;
      update_isRet_q    <= io_update_bits_ftb_entry_isRet;
      update_tailOff_q  <= io_update_bits_ftb_entry_tailSlot_offset;
      update_tailValid_q<= io_update_bits_ftb_entry_tailSlot_valid;
      update_cfiValid_q <= io_update_bits_cfi_idx_valid;
      update_cfiBits_q  <= io_update_bits_cfi_idx_bits;
      update_jmpTaken_q <= io_update_bits_jmp_taken;
      updateMeta_ssp        <= io_update_bits_meta[9:6];
      updateMeta_TOSW_flag  <= io_update_bits_meta[5];
      updateMeta_TOSW_value <= io_update_bits_meta[4:0];
    end
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      redirect_valid_q <= 1'h0;
      updateValid      <= 1'h0;
    end else begin
      redirect_valid_q <= io_redirect_valid;
      updateValid      <= io_update_valid;
    end
  end

  // ==========================================================================
  // 5. RASStack 输入构造 + 实例化
  // ==========================================================================
  // commit push/pop 限定: updateValid & tailSlot 有效 & isCall/isRet & jmp_taken & cfi 有效 & cfi==tailOff
  wire update_cfi_at_tail = (update_cfiBits_q == update_tailOff_q);
  wire commit_base = updateValid & update_tailValid_q & update_jmpTaken_q
                   & update_cfiValid_q & update_cfi_at_tail;
  wire commit_push = commit_base & update_isCall_q;
  wire commit_pop  = commit_base & update_isRet_q;

  // redirect 恢复条件: isBefore(redirect_TOSW, stack_TOSW) | !near_overflow
  wire redirect_isBefore_TOSW =
        (redirect_TOSW_flag_q ^ _RASStack_io_TOSW_flag)
      ^ (redirect_TOSW_value_q < _RASStack_io_TOSW_value);
  wire stack_redirect_valid = redirect_valid_q
                            & (redirect_isBefore_TOSW | ~_RASStack_io_spec_near_overflow);
  wire stack_redirect_isCall = redirect_valid_q & ~redirect_level_q
                             & redirect_pd_isCall_q & redirect_pd_valid_q;
  wire stack_redirect_isRet  = redirect_valid_q & ~redirect_level_q
                             & redirect_pd_isRet_q  & redirect_pd_valid_q;
  wire [49:0] redirect_callAddr =
        redirect_pc_q + {47'h0, redirect_pd_isRVC_q ? 3'h2 : 3'h4};

  xs_RASStack RASStack (
    .clock(clock), .reset(reset),
    .io_spec_push_valid (s2_spec_push & ~_RASStack_io_spec_near_overflow),
    .io_spec_pop_valid  (s2_spec_pop  & ~_RASStack_io_spec_near_overflow),
    .io_spec_push_addr  (s2_spec_new_addr),
    .io_s2_fire         (io_s2_fire_2),
    .io_s3_fire         (io_s3_fire_2),
    .io_s3_cancel       (s3_cancel & ~_RASStack_io_spec_near_overflow),
    .io_s3_meta_ssp        (s3_meta_ssp),
    .io_s3_meta_sctr       (s3_meta_sctr),
    .io_s3_meta_TOSW_flag  (s3_meta_TOSW_flag),
    .io_s3_meta_TOSW_value (s3_meta_TOSW_value),
    .io_s3_meta_TOSR_flag  (s3_meta_TOSR_flag),
    .io_s3_meta_TOSR_value (s3_meta_TOSR_value),
    .io_s3_meta_NOS_flag   (s3_meta_NOS_flag),
    .io_s3_meta_NOS_value  (s3_meta_NOS_value),
    .io_s3_missed_pop   (s3_pop  & ~s3_popped_in_s2),
    .io_s3_missed_push  (s3_push & ~s3_pushed_in_s2),
    .io_s3_pushAddr     (s3_spec_new_addr),
    .io_spec_pop_addr   (_RASStack_io_spec_pop_addr),
    .io_commit_valid      (updateValid),
    .io_commit_push_valid (commit_push),
    .io_commit_pop_valid  (commit_pop),
    .io_commit_meta_TOSW_flag  (updateMeta_TOSW_flag),
    .io_commit_meta_TOSW_value (updateMeta_TOSW_value),
    .io_commit_meta_ssp        (updateMeta_ssp),
    .io_redirect_valid   (stack_redirect_valid),
    .io_redirect_isCall  (stack_redirect_isCall),
    .io_redirect_isRet   (stack_redirect_isRet),
    .io_redirect_meta_ssp        (redirect_ssp_q),
    .io_redirect_meta_sctr       (redirect_sctr_q),
    .io_redirect_meta_TOSW_flag  (redirect_TOSW_flag_q),
    .io_redirect_meta_TOSW_value (redirect_TOSW_value_q),
    .io_redirect_meta_TOSR_flag  (redirect_TOSR_flag_q),
    .io_redirect_meta_TOSR_value (redirect_TOSR_value_q),
    .io_redirect_meta_NOS_flag   (redirect_NOS_flag_q),
    .io_redirect_meta_NOS_value  (redirect_NOS_value_q),
    .io_redirect_callAddr (redirect_callAddr),
    .io_ssp(_RASStack_io_ssp), .io_sctr(_RASStack_io_sctr),
    .io_TOSR_flag(_RASStack_io_TOSR_flag), .io_TOSR_value(_RASStack_io_TOSR_value),
    .io_TOSW_flag(_RASStack_io_TOSW_flag), .io_TOSW_value(_RASStack_io_TOSW_value),
    .io_NOS_flag(_RASStack_io_NOS_flag),   .io_NOS_value(_RASStack_io_NOS_value),
    .io_spec_near_overflow(_RASStack_io_spec_near_overflow)
  );

  // ==========================================================================
  // 6. 输出
  // ==========================================================================
  assign io_out_s2_pc_0 = s2_pc_addr[0];
  assign io_out_s2_pc_1 = s2_pc_addr[1];
  assign io_out_s2_pc_2 = s2_pc_addr[2];
  assign io_out_s2_pc_3 = s2_pc_addr[3];
  assign io_out_s3_pc_0 = s3_pc_addr[0];
  assign io_out_s3_pc_1 = s3_pc_addr[1];
  assign io_out_s3_pc_2 = s3_pc_addr[2];
  assign io_out_s3_pc_3 = s3_pc_addr[3];

  assign io_out_last_stage_meta =
    {506'h0, s3_meta_ssp, s3_meta_TOSW_flag, s3_meta_TOSW_value};
  assign io_out_last_stage_spec_info_ssp        = s3_meta_ssp;
  assign io_out_last_stage_spec_info_sctr       = s3_meta_sctr;
  assign io_out_last_stage_spec_info_TOSW_flag  = s3_meta_TOSW_flag;
  assign io_out_last_stage_spec_info_TOSW_value = s3_meta_TOSW_value;
  assign io_out_last_stage_spec_info_TOSR_flag  = s3_meta_TOSR_flag;
  assign io_out_last_stage_spec_info_TOSR_value = s3_meta_TOSR_value;
  assign io_out_last_stage_spec_info_NOS_flag   = s3_meta_NOS_flag;
  assign io_out_last_stage_spec_info_NOS_value  = s3_meta_NOS_value;
  assign io_out_last_stage_spec_info_topAddr    = s3_top;

  // s2/s3 各通道的 jalr_target / targets_1 改写
__JALR_ASSIGNS__
  // 其余 io_out_* 透传
__PASSTHRU_ASSIGNS__
"""


def gen_core_top(ps):
    # jalr 改写信号查表
    jalr_map = {}
    for i in range(4):
        jalr_map[f"io_out_s2_full_pred_{i}_jalr_target"] = f"s2_jalr_target_{i}"
        jalr_map[f"io_out_s3_full_pred_{i}_jalr_target"] = f"s3_jalr_target_{i}"
    jalr_lines = []
    for i in range(4):
        jalr_lines.append(f"  assign io_out_s2_full_pred_{i}_jalr_target = s2_jalr_target_{i};")
        jalr_lines.append(
            f"  assign io_out_s2_full_pred_{i}_targets_1 = "
            f"io_in_bits_resp_in_0_s2_full_pred_2_is_jalr ? s2_jalr_target_{i} : "
            f"io_in_bits_resp_in_0_s2_full_pred_{i}_targets_1;")
    for i in range(4):
        jalr_lines.append(f"  assign io_out_s3_full_pred_{i}_jalr_target = s3_jalr_target_{i};")
        jalr_lines.append(
            f"  assign io_out_s3_full_pred_{i}_targets_1 = "
            f"s3_is_jalr ? s3_jalr_target_{i} : "
            f"io_in_bits_resp_in_0_s3_full_pred_{i}_targets_1;")

    # 已被显式驱动的 io_out_* (不参与默认透传)
    driven = set(jalr_map.keys())
    for i in range(4):
        driven.add(f"io_out_s2_full_pred_{i}_targets_1")
        driven.add(f"io_out_s3_full_pred_{i}_targets_1")
    for n in ("io_out_s2_pc_0", "io_out_s2_pc_1", "io_out_s2_pc_2", "io_out_s2_pc_3",
              "io_out_s3_pc_0", "io_out_s3_pc_1", "io_out_s3_pc_2", "io_out_s3_pc_3",
              "io_out_last_stage_meta",
              "io_out_last_stage_spec_info_ssp", "io_out_last_stage_spec_info_sctr",
              "io_out_last_stage_spec_info_TOSW_flag", "io_out_last_stage_spec_info_TOSW_value",
              "io_out_last_stage_spec_info_TOSR_flag", "io_out_last_stage_spec_info_TOSR_value",
              "io_out_last_stage_spec_info_NOS_flag", "io_out_last_stage_spec_info_NOS_value",
              "io_out_last_stage_spec_info_topAddr"):
        driven.add(n)

    # 透传: io_out_X -> 对应 io_in 名。规则:
    #   io_out_s2_full_pred_<i>_<f>   -> io_in_bits_resp_in_0_s2_full_pred_<i>_<f>
    #   io_out_s3_full_pred_<i>_<f>   -> io_in_bits_resp_in_0_s3_full_pred_<i>_<f>
    #   io_out_last_stage_spec_info_<f> -> io_in_bits_resp_in_0_last_stage_spec_info_<f>
    #   io_out_last_stage_ftb_entry_<f> -> io_in_bits_resp_in_0_last_stage_ftb_entry_<f>
    pass_lines = []
    for d, w, n in ps:
        if d != "output" or n in driven:
            continue
        if n.startswith("io_out_"):
            rest = n[len("io_out_"):]
            src = f"io_in_bits_resp_in_0_{rest}"
            pass_lines.append(f"  assign {n} = {src};")

    body = CORE_BODY.replace("__JALR_ASSIGNS__", "\n".join(jalr_lines))
    body = body.replace("__PASSTHRU_ASSIGNS__", "\n".join(pass_lines))

    decls = ",\n".join(decl_str(d, w, n) for d, w, n in ps)
    return ("// 自动生成：scripts/gen_ras.py —— 勿手改\n"
            "// xs_RAS_core: RAS 顶层 (BasePredictor 包装层)，与 golden RAS 同端口。\n"
            "module xs_RAS_core(\n" + decls + "\n);\n" + body + "\nendmodule\n")


def emit_wrapper(modname, ps):
    decls = ",\n".join(decl_str(d, w, n) for d, w, n in ps)
    conns = ",\n".join(f"    .{n}({n})" for d, w, n in ps)
    return ("// 自动生成：scripts/gen_ras.py —— 勿手改\n"
            f"module {modname}(\n" + decls + "\n);\n"
            "  xs_RAS_core u_core (\n" + conns + "\n  );\n"
            "endmodule\n")


def emit_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = ["// 自动生成：scripts/gen_ras.py —— 勿手改",
         "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 40000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;"]
    for w, n in ins:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  logic {ws}{n};")
    for w, n in outs:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")
    base = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = base + [f".{n}(g_{n})" for _, n in outs]
    ig = base + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  RAS    u_g ({', '.join(gg)});")
    T.append(f"  RAS_xs u_i ({', '.join(ig)});")
    # 随机激励
    T.append("  task automatic drive();")
    for w, n in ins:
        if n in ("io_s0_fire_0", "io_s0_fire_1", "io_s0_fire_2", "io_s0_fire_3",
                 "io_s1_fire_0", "io_s1_fire_1", "io_s1_fire_2", "io_s1_fire_3",
                 "io_s2_fire_0", "io_s2_fire_1", "io_s2_fire_2", "io_s2_fire_3",
                 "io_s3_fire_2"):
            T.append(f"    {n} <= ($urandom_range(0,1));")
        elif n in ("io_update_valid", "io_redirect_valid"):
            T.append(f"    {n} <= ($urandom_range(0,3)==0);")
        elif n == "io_ctrl_ras_enable":
            T.append(f"    {n} <= ($urandom_range(0,7)!=0);")
        elif w <= 32:
            T.append(f"    {n} <= {w}'($urandom);")
        else:
            rep = (w + 31) // 32
            T.append(f"    {n} <= {w}'({{{', '.join(['$urandom()']*rep)}}});")
    T.append("  endtask")
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    T.append("      io_s0_fire_0<=0; io_s0_fire_1<=0; io_s0_fire_2<=0; io_s0_fire_3<=0;")
    T.append("      io_s1_fire_0<=0; io_s1_fire_1<=0; io_s1_fire_2<=0; io_s1_fire_3<=0;")
    T.append("      io_s2_fire_0<=0; io_s2_fire_1<=0; io_s2_fire_2<=0; io_s2_fire_3<=0;")
    T.append("      io_s3_fire_2<=0; io_update_valid<=0; io_redirect_valid<=0;")
    T.append("    end else drive();")
    T.append("  end")
    # 比对 (跳过复位后 warmup, 避开 golden 寄存器随机初值未冲刷干净的瞬态)
    T.append("  int warm = 0;")
    T.append("  always @(negedge clk) if (!rst) warm++;")
    T.append("  always @(negedge clk) if (!rst && warm > 40) begin")
    T.append("    #2; checks++;")
    for w, n in outs:
        T.append(f"    if (g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=30) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def main():
    ps = parse_ports("RAS")
    (XSSV / "rtl/frontend/RAS_core_top.sv").write_text(gen_core_top(ps))
    (XSSV / "rtl/frontend/RAS_wrapper.sv").write_text(emit_wrapper("RAS", ps))
    ut = XSSV / "verif/ut/RAS"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(emit_wrapper("RAS_xs", ps))
    (ut / "tb.sv").write_text(emit_tb(ps))
    print(f"RAS: {len(ps)} ports, "
          f"{sum(1 for d,_,_ in ps if d=='output')} outputs")


if __name__ == "__main__":
    main()
