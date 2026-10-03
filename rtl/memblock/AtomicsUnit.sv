// =============================================================================
// AtomicsUnit.sv —— 原子访存执行单元（LR / SC / AMO / AMOCAS），一条 9 状态的串行状态机
//
// 在哪一层：MemBlock 里独一份。后端把原子指令拆成 sta uop（带 rs1 地址）与 std uop
//   （带数据）分别发到本单元：sta 走 io_in（Decoupled），std 走 io_storeDataIn（2 口 Valid）。
//   本单元串行完成：地址翻译（dtlb）→ PMP/PBMT 检查 → 等 sbuffer 排空 → 向 DCache 发
//   原子请求 → 收响应 → 写回。整个过程 io_in 不接新指令（AMOCAS.Q 的第二个 sta uop 除外）。
// 设计源：Scala mem/pipeline/AtomicsUnit.scala。
//
// 状态（state 寄存器，编码即 Chisel Enum 顺序）：
//   0 S_INVALID        空闲；io_in.fire 锁存 uop / rs1，进 1
//   1 S_TLB_REQ        持续向 dtlb 发请求（同时若 sbuffer 非空则请求它排空）；第一拍的 resp 不收
//                      （可能是预取器的）；resp 命中后锁存 paddr/gpaddr/fullva，算对齐与触发器：
//                      不对齐或触发器要求（debug/断点）→ 直接进 7 写回异常，否则进 2
//   2 S_PM             看 PMP 与 PBMT：mmio/nc/pmp 违例/页错误 → 7；否则 sbuffer 已空进 4，没空进 3
//   3 S_WAIT_FLUSH     等 sbuffer 排空 → 4
//   4 S_CACHE_REQ      向 DCache 发原子请求（LR 还要 !block_lr；其余要 std 数据到齐 data_valid）→ 5
//   5 S_CACHE_RESP     等响应：miss&replay → 回 4 重发；miss&!replay → 原地等 MissQueue 重放；命中 → 锁存进 6
//   6 S_CACHE_RESP_LATCH 组织返回数据（按 W/D/Q 符号扩展，SC 原样）、cache error 异常、success → 7
//   7 S_FINISH         写回第 1 个 uop（pdest1）；AMOCAS.Q 还要写第 2 个 → 8，否则回 0
//   8 S_FINISH2        写回第 2 个 uop（pdest2，resp_data 高 64 位）→ 0
// 关键细节：
//   - fuOpType 低 6 位是原子操作编码（低 2 位 2=W/3=D/0=Q），高 3 位 [8:6] 复用为 uopIdx：
//     sta uopIdx 0 → pdest1，2 → pdest2；std uopIdx 0..3 → rd_l / rs2_l / rd_h / rs2_h。
//   - 需要几个 std：普通 AMO 与 LR/SC 1 个（放 rd_l，发给 DCache 时当 rs2 用），AMOCAS.W/D 2 个，AMOCAS.Q 4 个；
//     stdCnt 累计到位后 data_valid 置起。
//   - 触发器（4 个 mem trigger）：对 rs1（虚地址）按 matchType 比较；canFire 带链式/timing 判定，
//     晚一拍成 backendTriggerCanFireVec；triggerAction 1=进 debug，0=断点异常，F=无。
//   - 两个不复位的 difftest 打拍组（gatewayIn_packed_46/47_bore）照 golden 保留，一位不少。
//   - 不复位寄存器：uop 各字段、pdest1/2、rs1/rs2/rd、paddr/gpaddr、is_mmio、resp_data、success、
//     tdata、pbmtReg、dcache_resp_*、feedbackSlow bits、difftest 打拍组；复位的只有状态/valid/计数/异常/触发器使能。
// 子模块：无（golden 自包含）。golden 对照：G1-canonical/golden-rtl/AtomicsUnit.sv
// =============================================================================
package atomicsunit_pkg;
  typedef enum logic [3:0] {
    S_INVALID          = 4'd0,
    S_TLB_REQ          = 4'd1,
    S_PM               = 4'd2,
    S_WAIT_FLUSH       = 4'd3,
    S_CACHE_REQ        = 4'd4,
    S_CACHE_RESP       = 4'd5,
    S_CACHE_RESP_LATCH = 4'd6,
    S_FINISH           = 4'd7,
    S_FINISH2          = 4'd8
  } state_e;

  // DCache 原子命令编码（MemoryOpConstants）
  localparam logic [4:0] M_XA_SWAP = 5'h04, M_XLR = 5'h06, M_XSC = 5'h07, M_XA_ADD = 5'h08,
                         M_XA_XOR = 5'h09, M_XA_OR = 5'h0A, M_XA_AND = 5'h0B, M_XA_MIN = 5'h0C,
                         M_XA_MAX = 5'h0D, M_XA_MINU = 5'h0E, M_XA_MAXU = 5'h0F,
                         M_XA_CASQ = 5'h18, M_XA_CASW = 5'h1A, M_XA_CASD = 5'h1B;

  // 触发器动作编码
  localparam logic [3:0] TRIG_BREAKPOINT = 4'h0, TRIG_DEBUG_MODE = 4'h1, TRIG_NONE = 4'hF;
endpackage

module xs_AtomicsUnit_core
  import atomicsunit_pkg::*;
(
  input  logic         clock,
  input  logic         reset,
  input  logic [5:0]   hart_id,
  // ---- sta uop 入口 ----
  output logic         in_ready,
  input  logic         in_valid,
  input  logic [8:0]   in_fuOpType,
  input  logic         in_rfWen,
  input  logic [7:0]   in_pdest,
  input  logic         in_robIdx_flag,
  input  logic [7:0]   in_robIdx_value,
  input  logic         in_debugInfo_eliminatedMove,
  input  logic [63:0]  in_debugInfo_renameTime,
  input  logic [63:0]  in_debugInfo_dispatchTime,
  input  logic [63:0]  in_debugInfo_enqRsTime,
  input  logic [63:0]  in_debugInfo_selectTime,
  input  logic [63:0]  in_debugInfo_issueTime,
  input  logic [63:0]  in_debugInfo_writebackTime,
  input  logic [63:0]  in_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  in_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  in_debugInfo_tlbRespTime,
  input  logic [55:0]  in_debug_seqNum_seqNum,
  input  logic [7:0]   in_debug_seqNum_uopIdx,
  input  logic         in_lqIdx_flag,
  input  logic [6:0]   in_lqIdx_value,
  input  logic         in_sqIdx_flag,
  input  logic [5:0]   in_sqIdx_value,
  input  logic [63:0]  in_src_rs1,
  // ---- std 数据入口（2 口）----
  input  logic [1:0]   std_valid,
  input  logic [1:0][8:0]  std_fuOpType,   // [口]
  input  logic [1:0][63:0] std_data,
  // ---- 写回 ----
  input  logic         out_ready,
  output logic         out_valid,
  output logic         out_exceptionVec_3,   // breakpoint
  output logic         out_exceptionVec_4,   // loadAddrMisaligned
  output logic         out_exceptionVec_5,   // loadAccessFault
  output logic         out_exceptionVec_6,   // storeAddrMisaligned
  output logic         out_exceptionVec_7,   // storeAccessFault
  output logic         out_exceptionVec_13,  // loadPageFault
  output logic         out_exceptionVec_15,  // storePageFault
  output logic         out_exceptionVec_19,  // hardwareError
  output logic         out_exceptionVec_21,  // loadGuestPageFault
  output logic         out_exceptionVec_23,  // storeGuestPageFault
  output logic [3:0]   out_trigger,
  output logic         out_rfWen,
  output logic [7:0]   out_pdest,
  output logic         out_robIdx_flag,
  output logic [7:0]   out_robIdx_value,
  output logic         out_debugInfo_eliminatedMove,
  output logic [63:0]  out_debugInfo_renameTime,
  output logic [63:0]  out_debugInfo_dispatchTime,
  output logic [63:0]  out_debugInfo_enqRsTime,
  output logic [63:0]  out_debugInfo_selectTime,
  output logic [63:0]  out_debugInfo_issueTime,
  output logic [63:0]  out_debugInfo_writebackTime,
  output logic [63:0]  out_debugInfo_runahead_checkpoint_id,
  output logic [63:0]  out_debugInfo_tlbFirstReqTime,
  output logic [63:0]  out_debugInfo_tlbRespTime,
  output logic [55:0]  out_debug_seqNum_seqNum,
  output logic [7:0]   out_debug_seqNum_uopIdx,
  output logic         out_lqIdx_flag,
  output logic [6:0]   out_lqIdx_value,
  output logic [63:0]  out_data,
  output logic         out_debug_isMMIO,
  output logic [47:0]  out_debug_paddr,
  // ---- DCache 原子口 ----
  input  logic         dcache_req_ready,
  output logic         dcache_req_valid,
  output logic [4:0]   dcache_req_cmd,
  output logic [49:0]  dcache_req_vaddr,
  output logic [47:0]  dcache_req_addr,
  output logic [2:0]   dcache_req_word_idx,
  output logic [127:0] dcache_req_amo_data,
  output logic [15:0]  dcache_req_amo_mask,
  output logic [127:0] dcache_req_amo_cmp,
  input  logic         dcache_resp_valid,
  input  logic [127:0] dcache_resp_data_in,
  input  logic         dcache_resp_miss,
  input  logic         dcache_resp_replay,
  input  logic         dcache_resp_tl_denied,
  input  logic         dcache_resp_tl_corrupt,
  input  logic [5:0]   dcache_resp_id_in,
  input  logic         dcache_block_lr,
  // ---- dtlb ----
  output logic         dtlb_req_valid,
  output logic [49:0]  dtlb_req_vaddr,
  output logic [63:0]  dtlb_req_fullva,
  output logic [2:0]   dtlb_req_cmd,
  output logic         dtlb_req_debug_robIdx_flag,
  output logic [7:0]   dtlb_req_debug_robIdx_value,
  input  logic         dtlb_resp_valid,
  input  logic [47:0]  dtlb_resp_paddr,
  input  logic [63:0]  dtlb_resp_gpaddr,
  input  logic [63:0]  dtlb_resp_fullva,
  input  logic [1:0]   dtlb_resp_pbmt,
  input  logic         dtlb_resp_miss,
  input  logic         dtlb_resp_isForVSnonLeafPTE,
  input  logic         dtlb_resp_gpf_ld,
  input  logic         dtlb_resp_gpf_st,
  input  logic         dtlb_resp_pf_ld,
  input  logic         dtlb_resp_pf_st,
  input  logic         dtlb_resp_af_ld,
  input  logic         dtlb_resp_af_st,
  // ---- PMP / sbuffer / 反馈 / 重定向 / 异常信息 ----
  input  logic         pmp_ld,
  input  logic         pmp_st,
  input  logic         pmp_mmio,
  output logic         flush_sbuffer_valid,
  input  logic         flush_sbuffer_empty,
  output logic         feedback_valid,
  output logic         feedback_robIdx_flag,
  output logic [7:0]   feedback_robIdx_value,
  output logic         feedback_sqIdx_flag,
  output logic [5:0]   feedback_sqIdx_value,
  output logic         feedback_lqIdx_flag,
  output logic [6:0]   feedback_lqIdx_value,
  input  logic         redirect_valid,
  output logic         exceptionInfo_valid,
  output logic [63:0]  exceptionInfo_vaddr,
  output logic [63:0]  exceptionInfo_gpaddr,
  output logic         exceptionInfo_isForVSnonLeafPTE,
  // ---- CSR 控制：cache error 使能 + mem trigger ----
  input  logic         csr_cache_error_enable,
  input  logic         trig_update_valid,
  input  logic [1:0]   trig_update_addr,
  input  logic [1:0]   trig_update_matchType,
  input  logic         trig_update_select,
  input  logic [3:0]   trig_update_action,
  input  logic         trig_update_chain,
  input  logic         trig_update_store,
  input  logic         trig_update_load,
  input  logic [63:0]  trig_update_tdata2,
  input  logic [3:0]   trig_enable_in,
  input  logic         trig_debug_mode,
  input  logic         trig_can_raise_bp_exp,
  // ---- difftest 事件（打包）----
  output logic [480:0] difftest_atomic_packed,
  output logic [9:0]   difftest_lrsc_packed
);
  // ===========================================================================
  // §0 寄存器声明（字段集合逐字对齐 golden）
  // ===========================================================================
  state_e       state;
  logic         out_valid_r;
  logic         data_valid;
  // 锁存的 sta uop（不复位）
  logic [8:0]   uop_fuOpType;
  logic         uop_rfWen;
  logic         uop_robIdx_flag;
  logic [7:0]   uop_robIdx_value;
  logic         uop_debugInfo_eliminatedMove;
  logic [63:0]  uop_debugInfo_renameTime;
  logic [63:0]  uop_debugInfo_dispatchTime;
  logic [63:0]  uop_debugInfo_enqRsTime;
  logic [63:0]  uop_debugInfo_selectTime;
  logic [63:0]  uop_debugInfo_issueTime;
  logic [63:0]  uop_debugInfo_writebackTime;
  logic [63:0]  uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]  uop_debugInfo_tlbFirstReqTime;
  logic [63:0]  uop_debugInfo_tlbRespTime;
  logic [55:0]  uop_debug_seqNum_seqNum;
  logic [7:0]   uop_debug_seqNum_uopIdx;
  logic         uop_lqIdx_flag;
  logic [6:0]   uop_lqIdx_value;
  logic [7:0]   pdest1, pdest2;
  logic         pdest1Valid, pdest2Valid;
  // 操作数（不复位）：rs1 先存源寄存器值，TLB 返回后改存 fullva
  logic [63:0]  rs1, rs2_l, rs2_h, rd_l, rd_h;
  logic [2:0]   stdCnt;
  // 异常 / 触发器
  logic         exceptionVec_3, exceptionVec_4, exceptionVec_5, exceptionVec_6, exceptionVec_7,
                exceptionVec_13, exceptionVec_15, exceptionVec_19, exceptionVec_21, exceptionVec_23;
  logic [3:0]   trigger;
  logic         atom_override_xtval;
  logic         have_sent_first_tlb_req;
  // 翻译结果（不复位）
  logic [47:0]  paddr;
  logic [63:0]  gpaddr;
  logic         is_mmio;
  logic         isForVSnonLeafPTE;
  logic [1:0]   pbmtReg;
  // DCache 响应锁存（不复位）
  logic [127:0] dcache_resp_data;
  logic [5:0]   dcache_resp_id;
  logic         dcache_resp_tl_error_tl_denied, dcache_resp_tl_error_tl_corrupt;
  logic [127:0] resp_data;
  logic         success;
  // mem trigger 配置（tdata 不复位；timing 字段没有输入口，更新时写 0）
  logic [1:0]   tdata_matchType [4];
  logic         tdata_select    [4];
  logic         tdata_timing    [4];
  logic [3:0]   tdata_action    [4];
  logic         tdata_chain     [4];
  logic         tdata_store     [4];
  logic         tdata_load      [4];
  logic [63:0]  tdata_tdata2    [4];
  logic [3:0]   tEnableVec;
  logic [3:0]   backendTriggerCanFireVec;
  // 慢反馈：in_valid 打两拍 + 随 in_valid 锁存的索引（bits 不复位）
  logic         feedback_valid_d1, feedback_valid_d2;
  logic         feedback_robIdx_flag_r;
  logic [7:0]   feedback_robIdx_value_r;
  logic         feedback_sqIdx_flag_r;
  logic [5:0]   feedback_sqIdx_value_r;
  logic         feedback_lqIdx_flag_r;
  logic [6:0]   feedback_lqIdx_value_r;
  // difftest 打拍（随 dcache 请求发出锁存，不复位）
  logic [47:0]  difftest_addr_r;
  logic [63:0]  difftest_data_r [2];
  logic [15:0]  difftest_mask_r;
  logic [63:0]  difftest_cmp_r  [2];
  logic [8:0]   difftest_fuop_r;

  // ===========================================================================
  // §1 译码与握手
  // ===========================================================================
  logic isLr, isSc, isAMOCAS, isAMOCASQ, isAMOCASWD;
  logic [1:0] size;              // 2=W 3=D 0=Q（1 非法）
  assign isLr       = (uop_fuOpType == 9'h02) | (uop_fuOpType == 9'h03);
  assign isSc       = (uop_fuOpType == 9'h06) | (uop_fuOpType == 9'h07);
  assign isAMOCAS   = uop_fuOpType[5:2] == 4'hB;
  assign isAMOCASQ  = uop_fuOpType == 9'h2C;
  assign isAMOCASWD = (uop_fuOpType == 9'h2E) | (uop_fuOpType == 9'h2F);
  assign size       = uop_fuOpType[1:0];

  logic in_fire, in_fire_idle, sta_uop0, sta_uop2;
  logic [2:0] sta_uop_idx;
  assign in_ready     = (state == S_INVALID) | (isAMOCASQ & (~pdest2Valid | ~pdest1Valid));
  assign in_fire      = in_ready & in_valid;
  assign in_fire_idle = (state == S_INVALID) & in_fire;     // 真正接新指令的那一拍
  assign sta_uop_idx  = in_fuOpType[8:6];
  assign sta_uop0     = in_fire & (sta_uop_idx == 3'd0);
  assign sta_uop2     = in_fire & (sta_uop_idx == 3'd2);

  // std 分拣：口 p 的数据属于第 k 个 std（k = fuOpType[8:6]），口 1 优先于口 0
  logic [1:0] std_sel [4];
  for (genvar k = 0; k < 4; k++) begin : g_std_sel
    for (genvar p = 0; p < 2; p++) begin : g_port
      assign std_sel[k][p] = std_valid[p] & (std_fuOpType[p][8:6] == 3'(k));
    end
  end

  logic out_fire, finish_fire, finish2_fire, fsm_reset;
  assign out_valid    = out_valid_r & ((state == S_FINISH2) ? pdest2Valid : pdest1Valid);
  assign out_fire     = out_ready & out_valid;
  assign finish_fire  = (state == S_FINISH)  & out_fire;
  assign finish2_fire = (state == S_FINISH2) & out_fire;
  assign fsm_reset    = finish2_fire | (finish_fire & ~isAMOCASQ);   // resetFSM()

  // ===========================================================================
  // §2 触发器：命中比较（组合）+ canFire（打一拍）+ 动作裁决
  // ===========================================================================
  logic [3:0] trig_hit;
  for (genvar j = 0; j < 4; j++) begin : g_trig
    logic cmp;        // rs1 与 tdata2 按 matchType 比较（只看低 50 位）
    always_comb begin
      case (tdata_matchType[j])
        2'd0:    cmp = rs1[49:0] == tdata_tdata2[j][49:0];
        2'd2:    cmp = rs1[49:0] >= tdata_tdata2[j][49:0];
        2'd3:    cmp = rs1[49:0] <  tdata_tdata2[j][49:0];
        default: cmp = 1'b0;
      endcase
    end
    // store 触发器对非 LR 生效，load 触发器对非 SC 生效
    assign trig_hit[j] = ~tdata_select[j] & ~trig_debug_mode & cmp & tEnableVec[j]
                       & ((~isLr & tdata_store[j]) | (~isSc & tdata_load[j]));
  end

  logic [3:0] trig_can_fire_next;
  assign trig_can_fire_next[0] = trig_hit[0] & ~tdata_chain[0];
  for (genvar j = 1; j < 4; j++) begin : g_chain
    logic chain_ok, timing_ok;
    assign chain_ok  = (tdata_chain[j-1] & trig_hit[j-1]) | ~tdata_chain[j-1];
    assign timing_ok = (tdata_chain[j-1] & ~tdata_chain[j] & (tdata_timing[j-1] == tdata_timing[j]))
                     | ~tdata_chain[j-1];
    assign trig_can_fire_next[j] = chain_ok & timing_ok & trig_hit[j] & ~tdata_chain[j];
  end

  logic [3:0] fire_debug, fire_bp;
  for (genvar j = 0; j < 4; j++) begin : g_act
    assign fire_debug[j] = backendTriggerCanFireVec[j] & (tdata_action[j] == TRIG_DEBUG_MODE);
    assign fire_bp[j]    = backendTriggerCanFireVec[j] & (tdata_action[j] == TRIG_BREAKPOINT);
  end
  logic [3:0] triggerAction;
  logic       triggerDebugMode, triggerBreakpoint;
  assign triggerAction     = (|fire_debug) ? TRIG_DEBUG_MODE :
                             ((|fire_bp) & trig_can_raise_bp_exp) ? TRIG_BREAKPOINT : TRIG_NONE;
  assign triggerDebugMode  = triggerAction == TRIG_DEBUG_MODE;
  assign triggerBreakpoint = triggerAction == TRIG_BREAKPOINT;

  // ===========================================================================
  // §3 S_TLB_REQ：地址对齐与翻译结果
  // ===========================================================================
  logic tlb_resp_fire, tlb_resp_hit, tlb_early_finish;
  logic addrAligned;
  assign tlb_resp_fire = (state == S_TLB_REQ) & dtlb_resp_valid & have_sent_first_tlb_req;
  assign tlb_resp_hit  = tlb_resp_fire & ~dtlb_resp_miss;
  always_comb begin
    case (size)
      2'd2:    addrAligned = rs1[1:0] == 2'b0;
      2'd3:    addrAligned = rs1[2:0] == 3'b0;
      2'd0:    addrAligned = rs1[3:0] == 4'b0;
      default: addrAligned = 1'b0;
    endcase
  end
  // 不对齐 / 触发器要动作：不等 TLB 异常检查，直接写回
  assign tlb_early_finish = tlb_resp_hit & (~addrAligned | triggerDebugMode | triggerBreakpoint);

  // ===========================================================================
  // §4 S_PM：PMP / PBMT 检查
  // ===========================================================================
  logic pbmt_is_io, pbmt_is_nc, pbmt_is_pma;
  logic exception_va, exception_pa_mmio_nc, exception_pa, pm_exception;
  assign pbmt_is_pma = pbmtReg == 2'd0;
  assign pbmt_is_nc  = pbmtReg == 2'd1;
  assign pbmt_is_io  = pbmtReg == 2'd2;
  assign exception_va = exceptionVec_15 | exceptionVec_13 | exceptionVec_23 | exceptionVec_21
                      | exceptionVec_7 | exceptionVec_5;
  assign exception_pa_mmio_nc = pmp_mmio | pbmt_is_io | pbmt_is_nc;
  assign exception_pa = pmp_st | pmp_ld | exception_pa_mmio_nc;
  assign pm_exception = exception_va | exception_pa;

  // ===========================================================================
  // §5 S_CACHE_REQ / RESP：命令、操作数、掩码、返回数据
  // ===========================================================================
  always_comb begin
    case (uop_fuOpType)
      9'h02, 9'h03: dcache_req_cmd = M_XLR;
      9'h06, 9'h07: dcache_req_cmd = M_XSC;
      9'h0A, 9'h0B: dcache_req_cmd = M_XA_SWAP;
      9'h0E, 9'h0F: dcache_req_cmd = M_XA_ADD;
      9'h12, 9'h13: dcache_req_cmd = M_XA_XOR;
      9'h16, 9'h17: dcache_req_cmd = M_XA_AND;
      9'h1A, 9'h1B: dcache_req_cmd = M_XA_OR;
      9'h1E, 9'h1F: dcache_req_cmd = M_XA_MIN;
      9'h22, 9'h23: dcache_req_cmd = M_XA_MAX;
      9'h26, 9'h27: dcache_req_cmd = M_XA_MINU;
      9'h2A, 9'h2B: dcache_req_cmd = M_XA_MAXU;
      9'h2E:        dcache_req_cmd = M_XA_CASW;
      9'h2F:        dcache_req_cmd = M_XA_CASD;
      9'h2C:        dcache_req_cmd = M_XA_CASQ;
      default:      dcache_req_cmd = 5'h0;
    endcase
  end

  // rs2 = {rs2_h, AMOCAS ? rs2_l : rd_l}（普通 AMO 的唯一 std 放在 rd_l 槽）；rd = {rd_h, rd_l}
  logic [127:0] rs2_full, rd_full;
  assign rs2_full = {rs2_h, isAMOCAS ? rs2_l : rd_l};
  assign rd_full  = {rd_h, rd_l};

  function automatic logic [127:0] gen_wdata_amo(input logic [127:0] data, input logic [1:0] sz);
    case (sz)
      2'd2:    gen_wdata_amo = {4{data[31:0]}};
      2'd3:    gen_wdata_amo = {2{data[63:0]}};
      2'd0:    gen_wdata_amo = data;
      default: gen_wdata_amo = '0;
    endcase
  endfunction

  logic [15:0] amo_mask;
  always_comb begin
    case (size)
      2'd2:    amo_mask = 16'(11'(11'h00F << paddr[2:0]));   // W：按地址低 3 位移位
      2'd3:    amo_mask = 16'h00FF;
      2'd0:    amo_mask = 16'hFFFF;
      default: amo_mask = '0;
    endcase
  end
  assign dcache_req_amo_data = gen_wdata_amo(rs2_full, size);
  assign dcache_req_amo_cmp  = gen_wdata_amo(rd_full,  size);
  assign dcache_req_amo_mask = amo_mask;
  assign dcache_req_valid    = (state == S_CACHE_REQ)
                             & ((dcache_req_cmd == M_XLR) ? ~dcache_block_lr : data_valid);
  assign dcache_req_vaddr    = {rs1[49:6], 6'h0};
  assign dcache_req_addr     = {paddr[47:6], 6'h0};
  assign dcache_req_word_idx = paddr[5:3];

  logic dcache_req_fire, dcache_resp_fire, dcache_resp_hit;
  assign dcache_req_fire  = dcache_req_ready & dcache_req_valid;
  assign dcache_resp_fire = (state == S_CACHE_RESP) & dcache_resp_valid;
  assign dcache_resp_hit  = dcache_resp_fire & ~dcache_resp_miss;

  // 返回数据：W 取 paddr[2:0] 选中的那 32 位并符号扩展，D 符号扩展，Q 原样；SC 原样返回
  logic [127:0] rdataSel, resp_data_sel, resp_data_wire;
  assign rdataSel = (|paddr[2:0]) ? {32'h0, dcache_resp_data[127:32]} : dcache_resp_data;
  always_comb begin
    case (size)
      2'd2:    resp_data_sel = {{96{rdataSel[31]}}, rdataSel[31:0]};
      2'd3:    resp_data_sel = {{64{rdataSel[63]}}, rdataSel[63:0]};
      2'd0:    resp_data_sel = rdataSel;
      default: resp_data_sel = '0;
    endcase
  end
  assign resp_data_wire = (state == S_CACHE_RESP_LATCH) ? (isSc ? dcache_resp_data : resp_data_sel) : '0;

  logic canTriggerCacheError;
  assign canTriggerCacheError = (dcache_resp_tl_error_tl_denied | dcache_resp_tl_error_tl_corrupt)
                              & csr_cache_error_enable;

  // ===========================================================================
  // §6 状态机与复位域寄存器
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      state <= S_INVALID;
      out_valid_r <= 1'b0;
      data_valid <= 1'b0;
      pdest1Valid <= 1'b0;
      pdest2Valid <= 1'b0;
      stdCnt <= '0;
      {exceptionVec_3, exceptionVec_4, exceptionVec_5, exceptionVec_6, exceptionVec_7,
       exceptionVec_13, exceptionVec_15, exceptionVec_19, exceptionVec_21, exceptionVec_23} <= '0;
      trigger <= TRIG_NONE;
      atom_override_xtval <= 1'b0;
      have_sent_first_tlb_req <= 1'b0;
      tEnableVec <= '0;
      backendTriggerCanFireVec <= '0;
      feedback_valid_d1 <= 1'b0;
      feedback_valid_d2 <= 1'b0;
    end else begin
      // ---- 状态转移（各状态互斥）----
      case (state)
        S_INVALID:          if (in_fire) state <= S_TLB_REQ;
        S_TLB_REQ:          if (tlb_resp_hit) state <= tlb_early_finish ? S_FINISH : S_PM;
        S_PM:               state <= pm_exception ? S_FINISH : (flush_sbuffer_empty ? S_CACHE_REQ : S_WAIT_FLUSH);
        S_WAIT_FLUSH:       if (flush_sbuffer_empty) state <= S_CACHE_REQ;
        S_CACHE_REQ:        if (dcache_req_fire) state <= S_CACHE_RESP;
        S_CACHE_RESP:       if (dcache_resp_fire) begin
                              if (dcache_resp_miss) begin
                                if (dcache_resp_replay) state <= S_CACHE_REQ;   // 没进 MissQueue，自己重发
                              end else
                                state <= S_CACHE_RESP_LATCH;
                            end
        S_CACHE_RESP_LATCH: state <= S_FINISH;
        S_FINISH:           if (out_fire) state <= isAMOCASQ ? S_FINISH2 : S_INVALID;
        S_FINISH2:          if (out_fire) state <= S_INVALID;
        default: ;
      endcase

      // ---- out_valid：异常早退 / 响应到齐 / CASQ 第二拍置起；resetFSM 清零 ----
      if (fsm_reset)
        out_valid_r <= 1'b0;
      else if (finish_fire)                 // 此处必为 AMOCASQ
        out_valid_r <= 1'b1;
      else if (state == S_CACHE_RESP_LATCH)
        out_valid_r <= 1'b1;
      else if (state == S_PM)
        out_valid_r <= pm_exception | out_valid_r;
      else if (tlb_early_finish)
        out_valid_r <= 1'b1;

      // ---- std 到齐 ----
      if (fsm_reset)
        data_valid <= 1'b0;
      else if (~data_valid)
        data_valid <= (state != S_INVALID)
                    & ((isAMOCASQ & (stdCnt == 3'd4)) | (isAMOCASWD & (stdCnt == 3'd2))
                       | (~isAMOCAS & (stdCnt == 3'd1)));

      if (fsm_reset) begin
        pdest1Valid <= 1'b0;
        pdest2Valid <= 1'b0;
        stdCnt <= '0;
      end else begin
        if (sta_uop0) pdest1Valid <= 1'b1;
        if (sta_uop2) pdest2Valid <= 1'b1;
        stdCnt <= stdCnt + 3'({1'b0, std_valid[0]} + {1'b0, std_valid[1]});
      end

      // ---- 异常向量与触发器结果 ----
      if (tlb_resp_fire) begin
        exceptionVec_3  <= triggerBreakpoint;
        exceptionVec_4  <= ~addrAligned & isLr;
        exceptionVec_6  <= ~addrAligned & ~isLr;
        exceptionVec_13 <= dtlb_resp_pf_ld;
        exceptionVec_15 <= dtlb_resp_pf_st;
        exceptionVec_21 <= dtlb_resp_gpf_ld;
        exceptionVec_23 <= dtlb_resp_gpf_st;
        trigger         <= triggerAction;
      end
      if (state == S_CACHE_RESP_LATCH) begin
        exceptionVec_5  <= canTriggerCacheError & isLr & dcache_resp_tl_error_tl_denied;
        exceptionVec_7  <= canTriggerCacheError & ~isLr & dcache_resp_tl_error_tl_denied;
        exceptionVec_19 <= canTriggerCacheError & dcache_resp_tl_error_tl_corrupt
                         & ~dcache_resp_tl_error_tl_denied;
      end else if (state == S_PM) begin
        exceptionVec_5  <= exceptionVec_5 | ((pmp_ld | exception_pa_mmio_nc) & isLr);
        exceptionVec_7  <= exceptionVec_7 | pmp_st | ((pmp_ld | exception_pa_mmio_nc) & ~isLr);
      end else if (tlb_resp_fire) begin
        exceptionVec_5  <= dtlb_resp_af_ld;
        exceptionVec_7  <= dtlb_resp_af_st;
      end

      // ---- 异常信息有效位：异常早退/PM 异常置起，重定向清零（重定向优先）----
      if (redirect_valid)
        atom_override_xtval <= 1'b0;
      else if (state == S_PM)
        atom_override_xtval <= pm_exception | atom_override_xtval;
      else if (tlb_early_finish)
        atom_override_xtval <= 1'b1;

      // ---- 第一拍 TLB 响应不收 ----
      if (state == S_TLB_REQ)
        have_sent_first_tlb_req <= 1'b1;
      else if (in_fire_idle)
        have_sent_first_tlb_req <= 1'b0;

      tEnableVec <= trig_enable_in;
      backendTriggerCanFireVec <= trig_can_fire_next;
      feedback_valid_d1 <= in_valid;
      feedback_valid_d2 <= feedback_valid_d1;
    end
  end

  // ===========================================================================
  // §7 不复位寄存器
  // ===========================================================================
  always_ff @(posedge clock) begin
    if (in_fire_idle) begin
      uop_fuOpType <= in_fuOpType;
      uop_rfWen <= in_rfWen;
      uop_robIdx_flag <= in_robIdx_flag;
      uop_robIdx_value <= in_robIdx_value;
      uop_debugInfo_eliminatedMove <= in_debugInfo_eliminatedMove;
      uop_debugInfo_renameTime <= in_debugInfo_renameTime;
      uop_debugInfo_dispatchTime <= in_debugInfo_dispatchTime;
      uop_debugInfo_enqRsTime <= in_debugInfo_enqRsTime;
      uop_debugInfo_selectTime <= in_debugInfo_selectTime;
      uop_debugInfo_issueTime <= in_debugInfo_issueTime;
      uop_debugInfo_writebackTime <= in_debugInfo_writebackTime;
      uop_debugInfo_runahead_checkpoint_id <= in_debugInfo_runahead_checkpoint_id;
      uop_debugInfo_tlbFirstReqTime <= in_debugInfo_tlbFirstReqTime;
      uop_debugInfo_tlbRespTime <= in_debugInfo_tlbRespTime;
      uop_debug_seqNum_seqNum <= in_debug_seqNum_seqNum;
      uop_debug_seqNum_uopIdx <= in_debug_seqNum_uopIdx;
      uop_lqIdx_flag <= in_lqIdx_flag;
      uop_lqIdx_value <= in_lqIdx_value;
    end
    if (sta_uop0) pdest1 <= in_pdest;
    if (sta_uop2) pdest2 <= in_pdest;

    // rs1：空闲时存源寄存器值，TLB 命中后改存 fullva
    if (tlb_resp_fire) begin
      rs1 <= dtlb_resp_fullva;
      paddr <= dtlb_resp_paddr;
      gpaddr <= dtlb_resp_gpaddr;
      isForVSnonLeafPTE <= dtlb_resp_isForVSnonLeafPTE;
    end else if (in_fire_idle)
      rs1 <= in_src_rs1;

    // std 分拣（口 1 优先）
    if (std_sel[0][1]) rd_l  <= std_data[1]; else if (std_sel[0][0]) rd_l  <= std_data[0];
    if (std_sel[1][1]) rs2_l <= std_data[1]; else if (std_sel[1][0]) rs2_l <= std_data[0];
    if (std_sel[2][1]) rd_h  <= std_data[1]; else if (std_sel[2][0]) rd_h  <= std_data[0];
    if (std_sel[3][1]) rs2_h <= std_data[1]; else if (std_sel[3][0]) rs2_h <= std_data[0];

    if (state == S_PM)
      is_mmio <= pbmt_is_io | (pbmt_is_pma & pmp_mmio);
    if (state == S_CACHE_RESP_LATCH) begin
      resp_data <= isSc ? dcache_resp_data : resp_data_sel;
      success <= dcache_resp_id[0];
    end
    if (dtlb_resp_valid & ~dtlb_resp_miss)       // 任何状态都跟踪（RegEnable）
      pbmtReg <= dtlb_resp_pbmt;
    if (dcache_resp_hit) begin
      dcache_resp_data <= dcache_resp_data_in;
      dcache_resp_id <= dcache_resp_id_in;
      dcache_resp_tl_error_tl_denied <= dcache_resp_tl_denied;
      dcache_resp_tl_error_tl_corrupt <= dcache_resp_tl_corrupt;
    end

    // mem trigger 配置
    for (int j = 0; j < 4; j++) begin
      if (trig_update_valid && trig_update_addr == 2'(j)) begin
        tdata_matchType[j] <= trig_update_matchType;
        tdata_select[j] <= trig_update_select;
        tdata_action[j] <= trig_update_action;
        tdata_chain[j] <= trig_update_chain;
        tdata_store[j] <= trig_update_store;
        tdata_load[j] <= trig_update_load;
        tdata_tdata2[j] <= trig_update_tdata2;
        tdata_timing[j] <= 1'b0;                 // 输入侧没有 timing 字段，写入即 0
      end
    end

    if (in_valid) begin
      feedback_robIdx_flag_r <= in_robIdx_flag;
      feedback_robIdx_value_r <= in_robIdx_value;
      feedback_sqIdx_flag_r <= in_sqIdx_flag;
      feedback_sqIdx_value_r <= in_sqIdx_value;
      feedback_lqIdx_flag_r <= in_lqIdx_flag;
      feedback_lqIdx_value_r <= in_lqIdx_value;
    end

    if (dcache_req_fire) begin
      difftest_addr_r <= paddr;
      difftest_data_r[0] <= dcache_req_amo_data[63:0];
      difftest_data_r[1] <= dcache_req_amo_data[127:64];
      difftest_mask_r <= amo_mask;
      difftest_cmp_r[0] <= dcache_req_amo_cmp[63:0];
      difftest_cmp_r[1] <= dcache_req_amo_cmp[127:64];
      difftest_fuop_r <= uop_fuOpType;
    end
  end

  // ===========================================================================
  // §8 其余输出
  // ===========================================================================
  assign out_exceptionVec_3  = exceptionVec_3;
  assign out_exceptionVec_4  = exceptionVec_4;
  assign out_exceptionVec_5  = exceptionVec_5;
  assign out_exceptionVec_6  = exceptionVec_6;
  assign out_exceptionVec_7  = exceptionVec_7;
  assign out_exceptionVec_13 = exceptionVec_13;
  assign out_exceptionVec_15 = exceptionVec_15;
  assign out_exceptionVec_19 = exceptionVec_19;
  assign out_exceptionVec_21 = exceptionVec_21;
  assign out_exceptionVec_23 = exceptionVec_23;
  assign out_trigger = trigger;
  assign out_rfWen = uop_rfWen;
  assign out_pdest = (state == S_FINISH2) ? pdest2 : pdest1;
  assign out_robIdx_flag = uop_robIdx_flag;
  assign out_robIdx_value = uop_robIdx_value;
  assign out_debugInfo_eliminatedMove = uop_debugInfo_eliminatedMove;
  assign out_debugInfo_renameTime = uop_debugInfo_renameTime;
  assign out_debugInfo_dispatchTime = uop_debugInfo_dispatchTime;
  assign out_debugInfo_enqRsTime = uop_debugInfo_enqRsTime;
  assign out_debugInfo_selectTime = uop_debugInfo_selectTime;
  assign out_debugInfo_issueTime = uop_debugInfo_issueTime;
  assign out_debugInfo_writebackTime = uop_debugInfo_writebackTime;
  assign out_debugInfo_runahead_checkpoint_id = uop_debugInfo_runahead_checkpoint_id;
  assign out_debugInfo_tlbFirstReqTime = uop_debugInfo_tlbFirstReqTime;
  assign out_debugInfo_tlbRespTime = uop_debugInfo_tlbRespTime;
  assign out_debug_seqNum_seqNum = uop_debug_seqNum_seqNum;
  assign out_debug_seqNum_uopIdx = uop_debug_seqNum_uopIdx;
  assign out_lqIdx_flag = uop_lqIdx_flag;
  assign out_lqIdx_value = uop_lqIdx_value;
  assign out_data = (state == S_FINISH2) ? resp_data[127:64] : resp_data[63:0];
  assign out_debug_isMMIO = is_mmio;
  assign out_debug_paddr = paddr;

  assign dtlb_req_valid = state == S_TLB_REQ;
  assign dtlb_req_vaddr = rs1[49:0];
  assign dtlb_req_fullva = rs1;
  assign dtlb_req_cmd = {2'b10, ~isLr};        // atom_read=4 / atom_write=5
  assign dtlb_req_debug_robIdx_flag = uop_robIdx_flag;
  assign dtlb_req_debug_robIdx_value = uop_robIdx_value;

  assign flush_sbuffer_valid = ~flush_sbuffer_empty
                             & ((state == S_TLB_REQ) | (state == S_PM) | (state == S_WAIT_FLUSH));

  assign feedback_valid = feedback_valid_d2;
  assign feedback_robIdx_flag = feedback_robIdx_flag_r;
  assign feedback_robIdx_value = feedback_robIdx_value_r;
  assign feedback_sqIdx_flag = feedback_sqIdx_flag_r;
  assign feedback_sqIdx_value = feedback_sqIdx_value_r;
  assign feedback_lqIdx_flag = feedback_lqIdx_flag_r;
  assign feedback_lqIdx_value = feedback_lqIdx_value_r;

  assign exceptionInfo_valid = atom_override_xtval;
  assign exceptionInfo_vaddr = rs1;
  assign exceptionInfo_gpaddr = gpaddr;
  assign exceptionInfo_isForVSnonLeafPTE = isForVSnonLeafPTE;

  // difftest：DiffAtomicEvent {valid, addr64, data[1], data[0], mask, cmp[1], cmp[0], fuop8, out[1], out[0], coreid8}
  //           DiffLrScEvent  {valid, success, coreid8}
  logic [7:0] coreid;
  assign coreid = {2'b0, hart_id};
  assign difftest_atomic_packed = {state == S_CACHE_RESP_LATCH, {16'h0, difftest_addr_r},
                                   difftest_data_r[1], difftest_data_r[0], difftest_mask_r,
                                   difftest_cmp_r[1], difftest_cmp_r[0], difftest_fuop_r[7:0],
                                   resp_data_wire[127:64], resp_data_wire[63:0], coreid};
  assign difftest_lrsc_packed = {out_fire & (state == S_FINISH) & isSc, success, coreid};
endmodule

module AtomicsUnit (
  input  logic         clock,
  input  logic         reset,
  input  logic [5:0]   io_hartId,
  output logic         io_in_ready,
  input  logic         io_in_valid,
  input  logic [8:0]   io_in_bits_uop_fuOpType,
  input  logic         io_in_bits_uop_rfWen,
  input  logic [7:0]   io_in_bits_uop_pdest,
  input  logic         io_in_bits_uop_robIdx_flag,
  input  logic [7:0]   io_in_bits_uop_robIdx_value,
  input  logic         io_in_bits_uop_debugInfo_eliminatedMove,
  input  logic [63:0]  io_in_bits_uop_debugInfo_renameTime,
  input  logic [63:0]  io_in_bits_uop_debugInfo_dispatchTime,
  input  logic [63:0]  io_in_bits_uop_debugInfo_enqRsTime,
  input  logic [63:0]  io_in_bits_uop_debugInfo_selectTime,
  input  logic [63:0]  io_in_bits_uop_debugInfo_issueTime,
  input  logic [63:0]  io_in_bits_uop_debugInfo_writebackTime,
  input  logic [63:0]  io_in_bits_uop_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_in_bits_uop_debugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_in_bits_uop_debugInfo_tlbRespTime,
  input  logic [55:0]  io_in_bits_uop_debug_seqNum_seqNum,
  input  logic [7:0]   io_in_bits_uop_debug_seqNum_uopIdx,
  input  logic         io_in_bits_uop_lqIdx_flag,
  input  logic [6:0]   io_in_bits_uop_lqIdx_value,
  input  logic         io_in_bits_uop_sqIdx_flag,
  input  logic [5:0]   io_in_bits_uop_sqIdx_value,
  input  logic [63:0]  io_in_bits_src_0,
  input  logic         io_storeDataIn_0_valid,
  input  logic [8:0]   io_storeDataIn_0_bits_uop_fuOpType,
  input  logic [63:0]  io_storeDataIn_0_bits_data,
  input  logic         io_storeDataIn_1_valid,
  input  logic [8:0]   io_storeDataIn_1_bits_uop_fuOpType,
  input  logic [63:0]  io_storeDataIn_1_bits_data,
  input  logic         io_out_ready,
  output logic         io_out_valid,
  output logic         io_out_bits_uop_exceptionVec_3,
  output logic         io_out_bits_uop_exceptionVec_4,
  output logic         io_out_bits_uop_exceptionVec_5,
  output logic         io_out_bits_uop_exceptionVec_6,
  output logic         io_out_bits_uop_exceptionVec_7,
  output logic         io_out_bits_uop_exceptionVec_13,
  output logic         io_out_bits_uop_exceptionVec_15,
  output logic         io_out_bits_uop_exceptionVec_19,
  output logic         io_out_bits_uop_exceptionVec_21,
  output logic         io_out_bits_uop_exceptionVec_23,
  output logic [3:0]   io_out_bits_uop_trigger,
  output logic         io_out_bits_uop_rfWen,
  output logic [7:0]   io_out_bits_uop_pdest,
  output logic         io_out_bits_uop_robIdx_flag,
  output logic [7:0]   io_out_bits_uop_robIdx_value,
  output logic         io_out_bits_uop_debugInfo_eliminatedMove,
  output logic [63:0]  io_out_bits_uop_debugInfo_renameTime,
  output logic [63:0]  io_out_bits_uop_debugInfo_dispatchTime,
  output logic [63:0]  io_out_bits_uop_debugInfo_enqRsTime,
  output logic [63:0]  io_out_bits_uop_debugInfo_selectTime,
  output logic [63:0]  io_out_bits_uop_debugInfo_issueTime,
  output logic [63:0]  io_out_bits_uop_debugInfo_writebackTime,
  output logic [63:0]  io_out_bits_uop_debugInfo_runahead_checkpoint_id,
  output logic [63:0]  io_out_bits_uop_debugInfo_tlbFirstReqTime,
  output logic [63:0]  io_out_bits_uop_debugInfo_tlbRespTime,
  output logic [55:0]  io_out_bits_uop_debug_seqNum_seqNum,
  output logic [7:0]   io_out_bits_uop_debug_seqNum_uopIdx,
  output logic         io_out_bits_uop_lqIdx_flag,
  output logic [6:0]   io_out_bits_uop_lqIdx_value,
  output logic [63:0]  io_out_bits_data,
  output logic         io_out_bits_debug_isMMIO,
  output logic [47:0]  io_out_bits_debug_paddr,
  input  logic         io_dcache_req_ready,
  output logic         io_dcache_req_valid,
  output logic [4:0]   io_dcache_req_bits_cmd,
  output logic [49:0]  io_dcache_req_bits_vaddr,
  output logic [47:0]  io_dcache_req_bits_addr,
  output logic [2:0]   io_dcache_req_bits_word_idx,
  output logic [127:0] io_dcache_req_bits_amo_data,
  output logic [15:0]  io_dcache_req_bits_amo_mask,
  output logic [127:0] io_dcache_req_bits_amo_cmp,
  input  logic         io_dcache_resp_valid,
  input  logic [127:0] io_dcache_resp_bits_data,
  input  logic         io_dcache_resp_bits_miss,
  input  logic         io_dcache_resp_bits_replay,
  input  logic         io_dcache_resp_bits_tl_error_tl_denied,
  input  logic         io_dcache_resp_bits_tl_error_tl_corrupt,
  input  logic [5:0]   io_dcache_resp_bits_id,
  input  logic         io_dcache_block_lr,
  output logic         io_dtlb_req_valid,
  output logic [49:0]  io_dtlb_req_bits_vaddr,
  output logic [63:0]  io_dtlb_req_bits_fullva,
  output logic [2:0]   io_dtlb_req_bits_cmd,
  output logic         io_dtlb_req_bits_debug_robIdx_flag,
  output logic [7:0]   io_dtlb_req_bits_debug_robIdx_value,
  input  logic         io_dtlb_resp_valid,
  input  logic [47:0]  io_dtlb_resp_bits_paddr_0,
  input  logic [63:0]  io_dtlb_resp_bits_gpaddr_0,
  input  logic [63:0]  io_dtlb_resp_bits_fullva,
  input  logic [1:0]   io_dtlb_resp_bits_pbmt_0,
  input  logic         io_dtlb_resp_bits_miss,
  input  logic         io_dtlb_resp_bits_isForVSnonLeafPTE,
  input  logic         io_dtlb_resp_bits_excp_0_gpf_ld,
  input  logic         io_dtlb_resp_bits_excp_0_gpf_st,
  input  logic         io_dtlb_resp_bits_excp_0_pf_ld,
  input  logic         io_dtlb_resp_bits_excp_0_pf_st,
  input  logic         io_dtlb_resp_bits_excp_0_af_ld,
  input  logic         io_dtlb_resp_bits_excp_0_af_st,
  input  logic         io_pmpResp_ld,
  input  logic         io_pmpResp_st,
  input  logic         io_pmpResp_mmio,
  output logic         io_flush_sbuffer_valid,
  input  logic         io_flush_sbuffer_empty,
  output logic         io_feedbackSlow_valid,
  output logic         io_feedbackSlow_bits_robIdx_flag,
  output logic [7:0]   io_feedbackSlow_bits_robIdx_value,
  output logic         io_feedbackSlow_bits_sqIdx_flag,
  output logic [5:0]   io_feedbackSlow_bits_sqIdx_value,
  output logic         io_feedbackSlow_bits_lqIdx_flag,
  output logic [6:0]   io_feedbackSlow_bits_lqIdx_value,
  input  logic         io_redirect_valid,
  output logic         io_exceptionInfo_valid,
  output logic [63:0]  io_exceptionInfo_bits_vaddr,
  output logic [63:0]  io_exceptionInfo_bits_gpaddr,
  output logic         io_exceptionInfo_bits_isForVSnonLeafPTE,
  input  logic         io_csrCtrl_cache_error_enable,
  input  logic         io_csrCtrl_mem_trigger_tUpdate_valid,
  input  logic [1:0]   io_csrCtrl_mem_trigger_tUpdate_bits_addr,
  input  logic [1:0]   io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType,
  input  logic         io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select,
  input  logic [3:0]   io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action,
  input  logic         io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain,
  input  logic         io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store,
  input  logic         io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load,
  input  logic [63:0]  io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2,
  input  logic         io_csrCtrl_mem_trigger_tEnableVec_0,
  input  logic         io_csrCtrl_mem_trigger_tEnableVec_1,
  input  logic         io_csrCtrl_mem_trigger_tEnableVec_2,
  input  logic         io_csrCtrl_mem_trigger_tEnableVec_3,
  input  logic         io_csrCtrl_mem_trigger_debugMode,
  input  logic         io_csrCtrl_mem_trigger_triggerCanRaiseBpExp,
  output logic [480:0] gatewayIn_packed_46_bore,
  output logic [9:0]   gatewayIn_packed_47_bore
);
  xs_AtomicsUnit_core u_core (
    .clock                               (clock),
    .reset                               (reset),
    .hart_id                             (io_hartId),
    .in_ready                            (io_in_ready),
    .in_valid                            (io_in_valid),
    .in_fuOpType                         (io_in_bits_uop_fuOpType),
    .in_rfWen                            (io_in_bits_uop_rfWen),
    .in_pdest                            (io_in_bits_uop_pdest),
    .in_robIdx_flag                      (io_in_bits_uop_robIdx_flag),
    .in_robIdx_value                     (io_in_bits_uop_robIdx_value),
    .in_debugInfo_eliminatedMove         (io_in_bits_uop_debugInfo_eliminatedMove),
    .in_debugInfo_renameTime             (io_in_bits_uop_debugInfo_renameTime),
    .in_debugInfo_dispatchTime           (io_in_bits_uop_debugInfo_dispatchTime),
    .in_debugInfo_enqRsTime              (io_in_bits_uop_debugInfo_enqRsTime),
    .in_debugInfo_selectTime             (io_in_bits_uop_debugInfo_selectTime),
    .in_debugInfo_issueTime              (io_in_bits_uop_debugInfo_issueTime),
    .in_debugInfo_writebackTime          (io_in_bits_uop_debugInfo_writebackTime),
    .in_debugInfo_runahead_checkpoint_id (io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .in_debugInfo_tlbFirstReqTime        (io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .in_debugInfo_tlbRespTime            (io_in_bits_uop_debugInfo_tlbRespTime),
    .in_debug_seqNum_seqNum              (io_in_bits_uop_debug_seqNum_seqNum),
    .in_debug_seqNum_uopIdx              (io_in_bits_uop_debug_seqNum_uopIdx),
    .in_lqIdx_flag                       (io_in_bits_uop_lqIdx_flag),
    .in_lqIdx_value                      (io_in_bits_uop_lqIdx_value),
    .in_sqIdx_flag                       (io_in_bits_uop_sqIdx_flag),
    .in_sqIdx_value                      (io_in_bits_uop_sqIdx_value),
    .in_src_rs1                          (io_in_bits_src_0),
    .std_valid                           ({io_storeDataIn_1_valid, io_storeDataIn_0_valid}),
    .std_fuOpType                        ({io_storeDataIn_1_bits_uop_fuOpType, io_storeDataIn_0_bits_uop_fuOpType}),
    .std_data                            ({io_storeDataIn_1_bits_data, io_storeDataIn_0_bits_data}),
    .out_ready                           (io_out_ready),
    .out_valid                           (io_out_valid),
    .out_exceptionVec_3                  (io_out_bits_uop_exceptionVec_3),
    .out_exceptionVec_4                  (io_out_bits_uop_exceptionVec_4),
    .out_exceptionVec_5                  (io_out_bits_uop_exceptionVec_5),
    .out_exceptionVec_6                  (io_out_bits_uop_exceptionVec_6),
    .out_exceptionVec_7                  (io_out_bits_uop_exceptionVec_7),
    .out_exceptionVec_13                 (io_out_bits_uop_exceptionVec_13),
    .out_exceptionVec_15                 (io_out_bits_uop_exceptionVec_15),
    .out_exceptionVec_19                 (io_out_bits_uop_exceptionVec_19),
    .out_exceptionVec_21                 (io_out_bits_uop_exceptionVec_21),
    .out_exceptionVec_23                 (io_out_bits_uop_exceptionVec_23),
    .out_trigger                         (io_out_bits_uop_trigger),
    .out_rfWen                           (io_out_bits_uop_rfWen),
    .out_pdest                           (io_out_bits_uop_pdest),
    .out_robIdx_flag                     (io_out_bits_uop_robIdx_flag),
    .out_robIdx_value                    (io_out_bits_uop_robIdx_value),
    .out_debugInfo_eliminatedMove        (io_out_bits_uop_debugInfo_eliminatedMove),
    .out_debugInfo_renameTime            (io_out_bits_uop_debugInfo_renameTime),
    .out_debugInfo_dispatchTime          (io_out_bits_uop_debugInfo_dispatchTime),
    .out_debugInfo_enqRsTime             (io_out_bits_uop_debugInfo_enqRsTime),
    .out_debugInfo_selectTime            (io_out_bits_uop_debugInfo_selectTime),
    .out_debugInfo_issueTime             (io_out_bits_uop_debugInfo_issueTime),
    .out_debugInfo_writebackTime         (io_out_bits_uop_debugInfo_writebackTime),
    .out_debugInfo_runahead_checkpoint_id(io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .out_debugInfo_tlbFirstReqTime       (io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .out_debugInfo_tlbRespTime           (io_out_bits_uop_debugInfo_tlbRespTime),
    .out_debug_seqNum_seqNum             (io_out_bits_uop_debug_seqNum_seqNum),
    .out_debug_seqNum_uopIdx             (io_out_bits_uop_debug_seqNum_uopIdx),
    .out_lqIdx_flag                      (io_out_bits_uop_lqIdx_flag),
    .out_lqIdx_value                     (io_out_bits_uop_lqIdx_value),
    .out_data                            (io_out_bits_data),
    .out_debug_isMMIO                    (io_out_bits_debug_isMMIO),
    .out_debug_paddr                     (io_out_bits_debug_paddr),
    .dcache_req_ready                    (io_dcache_req_ready),
    .dcache_req_valid                    (io_dcache_req_valid),
    .dcache_req_cmd                      (io_dcache_req_bits_cmd),
    .dcache_req_vaddr                    (io_dcache_req_bits_vaddr),
    .dcache_req_addr                     (io_dcache_req_bits_addr),
    .dcache_req_word_idx                 (io_dcache_req_bits_word_idx),
    .dcache_req_amo_data                 (io_dcache_req_bits_amo_data),
    .dcache_req_amo_mask                 (io_dcache_req_bits_amo_mask),
    .dcache_req_amo_cmp                  (io_dcache_req_bits_amo_cmp),
    .dcache_resp_valid                   (io_dcache_resp_valid),
    .dcache_resp_data_in                 (io_dcache_resp_bits_data),
    .dcache_resp_miss                    (io_dcache_resp_bits_miss),
    .dcache_resp_replay                  (io_dcache_resp_bits_replay),
    .dcache_resp_tl_denied               (io_dcache_resp_bits_tl_error_tl_denied),
    .dcache_resp_tl_corrupt              (io_dcache_resp_bits_tl_error_tl_corrupt),
    .dcache_resp_id_in                   (io_dcache_resp_bits_id),
    .dcache_block_lr                     (io_dcache_block_lr),
    .dtlb_req_valid                      (io_dtlb_req_valid),
    .dtlb_req_vaddr                      (io_dtlb_req_bits_vaddr),
    .dtlb_req_fullva                     (io_dtlb_req_bits_fullva),
    .dtlb_req_cmd                        (io_dtlb_req_bits_cmd),
    .dtlb_req_debug_robIdx_flag          (io_dtlb_req_bits_debug_robIdx_flag),
    .dtlb_req_debug_robIdx_value         (io_dtlb_req_bits_debug_robIdx_value),
    .dtlb_resp_valid                     (io_dtlb_resp_valid),
    .dtlb_resp_paddr                     (io_dtlb_resp_bits_paddr_0),
    .dtlb_resp_gpaddr                    (io_dtlb_resp_bits_gpaddr_0),
    .dtlb_resp_fullva                    (io_dtlb_resp_bits_fullva),
    .dtlb_resp_pbmt                      (io_dtlb_resp_bits_pbmt_0),
    .dtlb_resp_miss                      (io_dtlb_resp_bits_miss),
    .dtlb_resp_isForVSnonLeafPTE         (io_dtlb_resp_bits_isForVSnonLeafPTE),
    .dtlb_resp_gpf_ld                    (io_dtlb_resp_bits_excp_0_gpf_ld),
    .dtlb_resp_gpf_st                    (io_dtlb_resp_bits_excp_0_gpf_st),
    .dtlb_resp_pf_ld                     (io_dtlb_resp_bits_excp_0_pf_ld),
    .dtlb_resp_pf_st                     (io_dtlb_resp_bits_excp_0_pf_st),
    .dtlb_resp_af_ld                     (io_dtlb_resp_bits_excp_0_af_ld),
    .dtlb_resp_af_st                     (io_dtlb_resp_bits_excp_0_af_st),
    .pmp_ld                              (io_pmpResp_ld),
    .pmp_st                              (io_pmpResp_st),
    .pmp_mmio                            (io_pmpResp_mmio),
    .flush_sbuffer_valid                 (io_flush_sbuffer_valid),
    .flush_sbuffer_empty                 (io_flush_sbuffer_empty),
    .feedback_valid                      (io_feedbackSlow_valid),
    .feedback_robIdx_flag                (io_feedbackSlow_bits_robIdx_flag),
    .feedback_robIdx_value               (io_feedbackSlow_bits_robIdx_value),
    .feedback_sqIdx_flag                 (io_feedbackSlow_bits_sqIdx_flag),
    .feedback_sqIdx_value                (io_feedbackSlow_bits_sqIdx_value),
    .feedback_lqIdx_flag                 (io_feedbackSlow_bits_lqIdx_flag),
    .feedback_lqIdx_value                (io_feedbackSlow_bits_lqIdx_value),
    .redirect_valid                      (io_redirect_valid),
    .exceptionInfo_valid                 (io_exceptionInfo_valid),
    .exceptionInfo_vaddr                 (io_exceptionInfo_bits_vaddr),
    .exceptionInfo_gpaddr                (io_exceptionInfo_bits_gpaddr),
    .exceptionInfo_isForVSnonLeafPTE     (io_exceptionInfo_bits_isForVSnonLeafPTE),
    .csr_cache_error_enable              (io_csrCtrl_cache_error_enable),
    .trig_update_valid                   (io_csrCtrl_mem_trigger_tUpdate_valid),
    .trig_update_addr                    (io_csrCtrl_mem_trigger_tUpdate_bits_addr),
    .trig_update_matchType               (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType),
    .trig_update_select                  (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select),
    .trig_update_action                  (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action),
    .trig_update_chain                   (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain),
    .trig_update_store                   (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store),
    .trig_update_load                    (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load),
    .trig_update_tdata2                  (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2),
    .trig_enable_in                      ({io_csrCtrl_mem_trigger_tEnableVec_3, io_csrCtrl_mem_trigger_tEnableVec_2,
                                           io_csrCtrl_mem_trigger_tEnableVec_1, io_csrCtrl_mem_trigger_tEnableVec_0}),
    .trig_debug_mode                     (io_csrCtrl_mem_trigger_debugMode),
    .trig_can_raise_bp_exp               (io_csrCtrl_mem_trigger_triggerCanRaiseBpExp),
    .difftest_atomic_packed              (gatewayIn_packed_46_bore),
    .difftest_lrsc_packed                (gatewayIn_packed_47_bore)
  );
endmodule
