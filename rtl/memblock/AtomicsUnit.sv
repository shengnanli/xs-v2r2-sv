// ============================================================================
// AtomicsUnit —— RISC-V 原子访存执行单元(可读手写核 xs_AtomicsUnit_core)
// ----------------------------------------------------------------------------
// 忠实重写 golden AtomicsUnit.sv(firtool 展开)。逻辑 bug-for-bug 一致。
//
// 功能: 处理 LR/SC/AMO(含 AMOCAS)原子指令。一条状态机(state 0..8)串起:
//   s_invalid(0)      : 空闲, 接收 io_in(锁存 uop/pdest), 收齐 store-data(std) 后进 tlb
//   s_tlb(1)          : 发 dtlb 请求(io_dtlb_req_valid), 收 resp 拿 paddr/pbmt, 算触发器
//   s_pm(2)           : PMP 检查(io_pmpResp), 判 MMIO/异常, 决定进 cache 或 flush_sbuffer
//   s_wait_flush(3)   : 等 sbuffer 排空(io_flush_sbuffer_empty)后进 cache_req
//   s_cache_req(4)    : 发 dcache 原子请求(io_dcache_req)
//   s_cache_resp(5)   : 等 dcache resp; miss→replay 回 4, 否则锁存 resp
//   s_finish(6)       : 组织结果(resp_data / success), 判 cache error, 进 s_sc/s_amo
//   s_sc(7)           : SC 结果输出(第一拍, pdest1), difftest LrSc 事件
//   s_amo(8)          : AMOCAS 第二拍输出(pdest2)
//
// 关键子结构:
//   * dcache cmd 编码(dcacheCmd): 由 fuOpType 查表映射到 M_XA_* 命令;
//   * amo_data/amo_mask/amo_cmp: 按 word/doubleword/quadword 对齐组织操作数;
//   * backend trigger(tdata_0..3 + tEnableVec): 地址断点比较 → triggerAction/exceptionVec_3;
//   * store-data 收集(sels_*/stdCnt): 从两个 storeDataIn 口按 uopIdx(fuOpType[8:6])分拣
//     到 rd_l/rs2_l/rd_h/rs2_h(AMOCAS 需 4 份, 普通 AMO 1 份);
//   * feedbackSlow: io_in_valid 打两拍(慢反馈), 携带 sqIdx。
//
// 子模块 DummyDPICWrapper_50(difftest LrSc 事件探针, 纯 DPI 副作用无输出)在两侧
// elaborate 同一 golden 定义(其内部 DiffExtLrScEvent 为 DPI import, 两侧对称黑盒)。
// ============================================================================
module xs_AtomicsUnit_core(
  input          clock,
  input          reset,
  input  [5:0]   io_hartId,
  output         io_in_ready,
  input          io_in_valid,
  input  [8:0]   io_in_bits_uop_fuOpType,
  input          io_in_bits_uop_rfWen,
  input  [7:0]   io_in_bits_uop_pdest,
  input          io_in_bits_uop_robIdx_flag,
  input  [7:0]   io_in_bits_uop_robIdx_value,
  input  [63:0]  io_in_bits_uop_debugInfo_enqRsTime,
  input  [63:0]  io_in_bits_uop_debugInfo_selectTime,
  input  [63:0]  io_in_bits_uop_debugInfo_issueTime,
  input          io_in_bits_uop_sqIdx_flag,
  input  [5:0]   io_in_bits_uop_sqIdx_value,
  input  [63:0]  io_in_bits_src_0,
  input          io_storeDataIn_0_valid,
  input  [8:0]   io_storeDataIn_0_bits_uop_fuOpType,
  input  [63:0]  io_storeDataIn_0_bits_data,
  input          io_storeDataIn_1_valid,
  input  [8:0]   io_storeDataIn_1_bits_uop_fuOpType,
  input  [63:0]  io_storeDataIn_1_bits_data,
  output         io_out_valid,
  output         io_out_bits_uop_exceptionVec_3,
  output         io_out_bits_uop_exceptionVec_4,
  output         io_out_bits_uop_exceptionVec_5,
  output         io_out_bits_uop_exceptionVec_6,
  output         io_out_bits_uop_exceptionVec_7,
  output         io_out_bits_uop_exceptionVec_13,
  output         io_out_bits_uop_exceptionVec_15,
  output         io_out_bits_uop_exceptionVec_21,
  output         io_out_bits_uop_exceptionVec_23,
  output [3:0]   io_out_bits_uop_trigger,
  output         io_out_bits_uop_rfWen,
  output [7:0]   io_out_bits_uop_pdest,
  output         io_out_bits_uop_robIdx_flag,
  output [7:0]   io_out_bits_uop_robIdx_value,
  output [63:0]  io_out_bits_uop_debugInfo_enqRsTime,
  output [63:0]  io_out_bits_uop_debugInfo_selectTime,
  output [63:0]  io_out_bits_uop_debugInfo_issueTime,
  output [63:0]  io_out_bits_data,
  output         io_out_bits_debug_isMMIO,
  input          io_dcache_req_ready,
  output         io_dcache_req_valid,
  output [4:0]   io_dcache_req_bits_cmd,
  output [49:0]  io_dcache_req_bits_vaddr,
  output [47:0]  io_dcache_req_bits_addr,
  output [2:0]   io_dcache_req_bits_word_idx,
  output [127:0] io_dcache_req_bits_amo_data,
  output [15:0]  io_dcache_req_bits_amo_mask,
  output [127:0] io_dcache_req_bits_amo_cmp,
  input          io_dcache_resp_valid,
  input  [127:0] io_dcache_resp_bits_data,
  input          io_dcache_resp_bits_miss,
  input          io_dcache_resp_bits_replay,
  input          io_dcache_resp_bits_error,
  input  [5:0]   io_dcache_resp_bits_id,
  input          io_dcache_block_lr,
  output         io_dtlb_req_valid,
  output [49:0]  io_dtlb_req_bits_vaddr,
  output [63:0]  io_dtlb_req_bits_fullva,
  output [2:0]   io_dtlb_req_bits_cmd,
  output         io_dtlb_req_bits_debug_robIdx_flag,
  output [7:0]   io_dtlb_req_bits_debug_robIdx_value,
  input          io_dtlb_resp_valid,
  input  [47:0]  io_dtlb_resp_bits_paddr_0,
  input  [63:0]  io_dtlb_resp_bits_gpaddr_0,
  input  [63:0]  io_dtlb_resp_bits_fullva,
  input  [1:0]   io_dtlb_resp_bits_pbmt_0,
  input          io_dtlb_resp_bits_miss,
  input          io_dtlb_resp_bits_isForVSnonLeafPTE,
  input          io_dtlb_resp_bits_excp_0_gpf_ld,
  input          io_dtlb_resp_bits_excp_0_gpf_st,
  input          io_dtlb_resp_bits_excp_0_pf_ld,
  input          io_dtlb_resp_bits_excp_0_pf_st,
  input          io_dtlb_resp_bits_excp_0_af_ld,
  input          io_dtlb_resp_bits_excp_0_af_st,
  input          io_pmpResp_ld,
  input          io_pmpResp_st,
  input          io_pmpResp_mmio,
  output         io_flush_sbuffer_valid,
  input          io_flush_sbuffer_empty,
  output         io_feedbackSlow_valid,
  output         io_feedbackSlow_bits_sqIdx_flag,
  output [5:0]   io_feedbackSlow_bits_sqIdx_value,
  input          io_redirect_valid,
  output         io_exceptionInfo_valid,
  output [63:0]  io_exceptionInfo_bits_vaddr,
  output [63:0]  io_exceptionInfo_bits_gpaddr,
  output         io_exceptionInfo_bits_isForVSnonLeafPTE,
  input          io_csrCtrl_cache_error_enable,
  input          io_csrCtrl_mem_trigger_tUpdate_valid,
  input  [1:0]   io_csrCtrl_mem_trigger_tUpdate_bits_addr,
  input  [1:0]   io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType,
  input          io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select,
  input  [3:0]   io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action,
  input          io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain,
  input          io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store,
  input          io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load,
  input  [63:0]  io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2,
  input          io_csrCtrl_mem_trigger_tEnableVec_0,
  input          io_csrCtrl_mem_trigger_tEnableVec_1,
  input          io_csrCtrl_mem_trigger_tEnableVec_2,
  input          io_csrCtrl_mem_trigger_tEnableVec_3,
  input          io_csrCtrl_mem_trigger_debugMode,
  input          io_csrCtrl_mem_trigger_triggerCanRaiseBpExp
);

  // ---- 状态编码(与 golden 数值一致) ---------------------------------------
  localparam [3:0] S_INVALID     = 4'h0;
  localparam [3:0] S_TLB         = 4'h1;
  localparam [3:0] S_PM          = 4'h2;
  localparam [3:0] S_WAIT_FLUSH  = 4'h3;
  localparam [3:0] S_CACHE_REQ   = 4'h4;
  localparam [3:0] S_CACHE_RESP  = 4'h5;
  localparam [3:0] S_FINISH      = 4'h6;
  localparam [3:0] S_SC          = 4'h7;
  localparam [3:0] S_AMO         = 4'h8;

  // ---- 状态寄存器 ----------------------------------------------------------
  reg  [3:0]   state;
  reg          out_valid;
  reg          data_valid;
  reg  [8:0]   uop_fuOpType;
  reg          uop_rfWen;
  reg          uop_robIdx_flag;
  reg  [7:0]   uop_robIdx_value;
  reg  [63:0]  uop_debugInfo_enqRsTime;
  reg  [63:0]  uop_debugInfo_selectTime;
  reg  [63:0]  uop_debugInfo_issueTime;
  reg  [7:0]   pdest1;
  reg  [7:0]   pdest2;
  reg          pdest1Valid;
  reg          pdest2Valid;
  reg  [63:0]  rs1;
  reg  [63:0]  rs2_l;
  reg  [63:0]  rs2_h;
  reg  [63:0]  rd_l;
  reg  [63:0]  rd_h;
  reg  [2:0]   stdCnt;
  reg          exceptionVec_3;
  reg          exceptionVec_4;
  reg          exceptionVec_5;
  reg          exceptionVec_6;
  reg          exceptionVec_7;
  reg          exceptionVec_13;
  reg          exceptionVec_15;
  reg          exceptionVec_21;
  reg          exceptionVec_23;
  reg  [3:0]   trigger;
  reg          atom_override_xtval;
  reg          have_sent_first_tlb_req;
  reg  [47:0]  paddr;
  reg  [63:0]  gpaddr;
  reg          is_mmio;
  reg          isForVSnonLeafPTE;
  reg  [127:0] resp_data;
  reg          success;
  reg  [1:0]   pbmtReg;
  reg  [127:0] dcache_resp_data;
  reg  [5:0]   dcache_resp_id;
  reg          dcache_resp_error;
  // backend trigger tdata[0..3]
  reg  [1:0]   tdata_0_matchType, tdata_1_matchType, tdata_2_matchType, tdata_3_matchType;
  reg          tdata_0_select,    tdata_1_select,    tdata_2_select,    tdata_3_select;
  reg          tdata_0_timing,    tdata_1_timing,    tdata_2_timing,    tdata_3_timing;
  reg  [3:0]   tdata_0_action,    tdata_1_action,    tdata_2_action,    tdata_3_action;
  reg          tdata_0_chain,     tdata_1_chain,     tdata_2_chain,     tdata_3_chain;
  reg          tdata_0_store,     tdata_1_store,     tdata_2_store,     tdata_3_store;
  reg          tdata_0_load,      tdata_1_load,      tdata_2_load,      tdata_3_load;
  reg  [63:0]  tdata_0_tdata2,    tdata_1_tdata2,    tdata_2_tdata2,    tdata_3_tdata2;
  reg          tEnableVec_0, tEnableVec_1, tEnableVec_2, tEnableVec_3;
  reg          backendTriggerCanFireVec_0, backendTriggerCanFireVec_1;
  reg          backendTriggerCanFireVec_2, backendTriggerCanFireVec_3;
  reg          io_feedbackSlow_valid_last_REG;
  reg          io_feedbackSlow_valid_last_REG_1;
  reg          io_feedbackSlow_bits_sqIdx_r_flag;
  reg  [5:0]   io_feedbackSlow_bits_sqIdx_r_value;

  // ---- 指令类别(基于已锁存 uop_fuOpType) ----------------------------------
  wire isLr     = uop_fuOpType == 9'h2 | uop_fuOpType == 9'h3;
  wire isSc     = uop_fuOpType == 9'h6 | uop_fuOpType == 9'h7;
  wire isAMOCAS = uop_fuOpType[5:2] == 4'hB;
  wire [63:0] rs2_lo_sel = isAMOCAS ? rs2_l : rd_l;

  // ---- 状态谓词 ------------------------------------------------------------
  wire at_invalid    = state == S_INVALID;
  wire at_tlb        = state == S_TLB;
  wire at_pm         = state == S_PM;
  wire at_wait_flush = state == S_WAIT_FLUSH;
  wire at_cache_req  = state == S_CACHE_REQ;
  wire at_cache_resp = state == S_CACHE_RESP;
  wire at_finish     = state == S_FINISH;      // at_finish
  wire at_sc         = state == S_SC;          // at_sc
  wire at_amo        = state == S_AMO;         // at_amo
  wire is_amocas_2c  = uop_fuOpType == 9'h2C;  // AMOCAS.Q 需要第二拍(is_amocas_2c)

  wire io_in_ready_0 = at_invalid | is_amocas_2c & (~pdest2Valid | ~pdest1Valid);

  // ---- store-data 分拣: 按 uopIdx = fuOpType[8:6] 选择 std 端口 -------------
  wire sels_0   = io_storeDataIn_0_valid & io_storeDataIn_0_bits_uop_fuOpType[8:6] == 3'h0;
  wire sels_1   = io_storeDataIn_1_valid & io_storeDataIn_1_bits_uop_fuOpType[8:6] == 3'h0;
  wire sels_0_1 = io_storeDataIn_0_valid & io_storeDataIn_0_bits_uop_fuOpType[8:6] == 3'h1;
  wire sels_1_1 = io_storeDataIn_1_valid & io_storeDataIn_1_bits_uop_fuOpType[8:6] == 3'h1;
  wire sels_0_2 = io_storeDataIn_0_valid & io_storeDataIn_0_bits_uop_fuOpType[8:6] == 3'h2;
  wire sels_1_2 = io_storeDataIn_1_valid & io_storeDataIn_1_bits_uop_fuOpType[8:6] == 3'h2;
  wire sels_0_3 = io_storeDataIn_0_valid & io_storeDataIn_0_bits_uop_fuOpType[8:6] == 3'h3;
  wire sels_1_3 = io_storeDataIn_1_valid & io_storeDataIn_1_bits_uop_fuOpType[8:6] == 3'h3;

  // ---- 入队 / uopIdx 分派使能 ---------------------------------------------
  wire io_in_fire   = io_in_ready_0 & io_in_valid;                              // io_in.fire
  wire enq_fire = at_invalid & io_in_fire;                                        // 首拍入队
  wire enq_pdest1 = io_in_fire & ~(|(io_in_bits_uop_fuOpType[8:6]));                // uopIdx==0 → pdest1
  wire uopIdx_is2 = io_in_bits_uop_fuOpType[8:6] == 3'h2;
  wire enq_pdest2 = io_in_fire & (|(io_in_bits_uop_fuOpType[8:6])) & uopIdx_is2;        // uopIdx==2 → pdest2

  // ---- TLB 交互 ------------------------------------------------------------
  wire io_dtlb_req_valid_0 = at_tlb;
  wire tlb_resp_fire  = io_dtlb_resp_valid & have_sent_first_tlb_req;
  wire tlb_resp_at_tlb  = io_dtlb_req_valid_0 & tlb_resp_fire;                            // tlb resp 有效落寄存器

  // ---- dcache 命令编码(M_XA_* / M_XLR / M_XSC / M_XA_CAS_*) ----------------
  // 逐位复刻 golden firtool 展开表(fuOpType→cmd), 与 golden _T_60/_T_73 逐位一致。
  wire [4:0] dcacheCmdLo =
    {1'h0,
     {uop_fuOpType == 9'hE,
      (uop_fuOpType == 9'h2 ? 3'h6 : 3'h0) | {3{uop_fuOpType == 9'h6}}
        | {uop_fuOpType == 9'hA, 2'h0}} | (uop_fuOpType == 9'h12 ? 4'h9 : 4'h0)
       | (uop_fuOpType == 9'h16 ? 4'hB : 4'h0) | (uop_fuOpType == 9'h1A ? 4'hA : 4'h0)
       | (uop_fuOpType == 9'h1E ? 4'hC : 4'h0) | (uop_fuOpType == 9'h22 ? 4'hD : 4'h0)
       | (uop_fuOpType == 9'h26 ? 4'hE : 4'h0) | {4{uop_fuOpType == 9'h2A}}}
    | (uop_fuOpType == 9'h2E ? 5'h1A : 5'h0);
  wire [4:0] dcacheCmd =
    {dcacheCmdLo[4],
     {dcacheCmdLo[3] | uop_fuOpType == 9'hF,
      dcacheCmdLo[2:0] | (uop_fuOpType == 9'h3 ? 3'h6 : 3'h0)
        | {3{uop_fuOpType == 9'h7}} | {uop_fuOpType == 9'hB, 2'h0}}
       | (uop_fuOpType == 9'h13 ? 4'h9 : 4'h0) | (uop_fuOpType == 9'h17 ? 4'hB : 4'h0)
       | (uop_fuOpType == 9'h1B ? 4'hA : 4'h0) | (uop_fuOpType == 9'h1F ? 4'hC : 4'h0)
       | (uop_fuOpType == 9'h23 ? 4'hD : 4'h0) | (uop_fuOpType == 9'h27 ? 4'hE : 4'h0)
       | {4{uop_fuOpType == 9'h2B}}} | (uop_fuOpType == 9'h2F ? 5'h1B : 5'h0)
    | (uop_fuOpType == 9'h2C ? 5'h18 : 5'h0);

  wire [10:0] amoMaskWord =
    uop_fuOpType[1:0] == 2'h2 ? 11'hF << paddr[2:0] : 11'h0;

  // ---- dcache req valid: LR(cmd==6) 需 ~block_lr, 其他需 data_valid, 且在 s_cache_req ----
  wire io_dcache_req_valid_0 =
    (dcacheCmd == 5'h6 ? ~io_dcache_block_lr : data_valid)
    & at_cache_req;

  // ---- 输出有效(s_amo 看 pdest2Valid, 否则 pdest1Valid) --------------------
  wire out_valid_can_out = at_amo ? pdest2Valid : pdest1Valid;
  wire io_out_valid_0 = out_valid & out_valid_can_out;

  // ---- difftest / dcache resp / tlb 状态推进的中间量 -----------------------
  wire difftest_valid = io_out_valid_0 & at_sc & isSc;
  wire dcache_resp_fire  = at_cache_resp & io_dcache_resp_valid;
  wire tlb_resp_hit = io_dtlb_req_valid_0 & tlb_resp_fire & ~io_dtlb_resp_bits_miss;
  wire dcache_req_fire = at_cache_req & io_dcache_req_ready & io_dcache_req_valid_0;

  // ---- backend trigger 命中比较(tdata_0..3 各自 store/load 两条断点) ------
  wire tdata0_mtEq0   = tdata_0_matchType == 2'h0;
  wire tdata0_mtEq2 = tdata_0_matchType == 2'h2;
  wire tdata1_mtEq0   = tdata_1_matchType == 2'h0;
  wire tdata1_mtEq2 = tdata_1_matchType == 2'h2;
  wire tdata2_mtEq0   = tdata_2_matchType == 2'h0;
  wire tdata2_mtEq2 = tdata_2_matchType == 2'h2;
  wire tdata3_mtEq0   = tdata_3_matchType == 2'h0;
  wire tdata3_mtEq2 = tdata_3_matchType == 2'h2;

  wire backendTriggerHitVec_0 =
    ~tdata_0_select & ~io_csrCtrl_mem_trigger_debugMode & ~isLr
    & ((&tdata_0_matchType) ? rs1[49:0] < tdata_0_tdata2[49:0]
         : tdata0_mtEq2 ? rs1[49:0] >= tdata_0_tdata2[49:0]
             : tdata0_mtEq0 & rs1[49:0] == tdata_0_tdata2[49:0]) & tEnableVec_0
    & tdata_0_store | ~tdata_0_select & ~io_csrCtrl_mem_trigger_debugMode & ~isSc
    & ((&tdata_0_matchType) ? rs1[49:0] < tdata_0_tdata2[49:0]
         : tdata0_mtEq2 ? rs1[49:0] >= tdata_0_tdata2[49:0]
             : tdata0_mtEq0 & rs1[49:0] == tdata_0_tdata2[49:0]) & tEnableVec_0
    & tdata_0_load;
  wire backendTriggerHitVec_1 =
    ~tdata_1_select & ~io_csrCtrl_mem_trigger_debugMode & ~isLr
    & ((&tdata_1_matchType) ? rs1[49:0] < tdata_1_tdata2[49:0]
         : tdata1_mtEq2 ? rs1[49:0] >= tdata_1_tdata2[49:0]
             : tdata1_mtEq0 & rs1[49:0] == tdata_1_tdata2[49:0]) & tEnableVec_1
    & tdata_1_store | ~tdata_1_select & ~io_csrCtrl_mem_trigger_debugMode & ~isSc
    & ((&tdata_1_matchType) ? rs1[49:0] < tdata_1_tdata2[49:0]
         : tdata1_mtEq2 ? rs1[49:0] >= tdata_1_tdata2[49:0]
             : tdata1_mtEq0 & rs1[49:0] == tdata_1_tdata2[49:0]) & tEnableVec_1
    & tdata_1_load;
  wire backendTriggerHitVec_2 =
    ~tdata_2_select & ~io_csrCtrl_mem_trigger_debugMode & ~isLr
    & ((&tdata_2_matchType) ? rs1[49:0] < tdata_2_tdata2[49:0]
         : tdata2_mtEq2 ? rs1[49:0] >= tdata_2_tdata2[49:0]
             : tdata2_mtEq0 & rs1[49:0] == tdata_2_tdata2[49:0]) & tEnableVec_2
    & tdata_2_store | ~tdata_2_select & ~io_csrCtrl_mem_trigger_debugMode & ~isSc
    & ((&tdata_2_matchType) ? rs1[49:0] < tdata_2_tdata2[49:0]
         : tdata2_mtEq2 ? rs1[49:0] >= tdata_2_tdata2[49:0]
             : tdata2_mtEq0 & rs1[49:0] == tdata_2_tdata2[49:0]) & tEnableVec_2
    & tdata_2_load;
  // 注: HitVec_3 未单独命名(golden 直接内联进 backendTriggerCanFireVec_3 更新), 见下方 always。

  wire [3:0] triggerCanFireVec =
    {backendTriggerCanFireVec_3, backendTriggerCanFireVec_2,
     backendTriggerCanFireVec_1, backendTriggerCanFireVec_0};
  wire [2:0] triggerFireOH_enc =
    backendTriggerCanFireVec_0 ? 3'h1
      : backendTriggerCanFireVec_1 ? 3'h2 : {backendTriggerCanFireVec_2, 2'h0};
  wire [3:0] triggerFireAction =
    triggerFireOH_enc[0] ? tdata_0_action
      : triggerFireOH_enc[1] ? tdata_1_action
          : triggerFireOH_enc[2] ? tdata_2_action : tdata_3_action;
  wire [3:0] triggerAction =
    (|triggerCanFireVec) & triggerFireAction == 4'h0
    & io_csrCtrl_mem_trigger_triggerCanRaiseBpExp ? 4'h0
      : (|triggerCanFireVec) & triggerFireAction == 4'h1 ? 4'h1 : 4'hF;
  wire triggerBreakpoint = triggerAction == 4'h0;

  // ---- 地址对齐检查(按访问宽度: word/doubleword/quadword) ------------------
  wire addrAligned =
    uop_fuOpType[1:0] == 2'h2 & rs1[1:0] == 2'h0 | (&(uop_fuOpType[1:0]))
    & rs1[2:0] == 3'h0 | ~(|(uop_fuOpType[1:0])) & rs1[3:0] == 4'h0;
  wire req_abort = ~addrAligned | triggerAction == 4'h1 | triggerBreakpoint;
  wire tlb_hit_abort = io_dtlb_req_valid_0 & tlb_resp_fire & ~io_dtlb_resp_bits_miss & req_abort;

  // ---- PMP / pbmt 异常汇总 -------------------------------------------------
  wire pbmt_is_nc = pbmtReg == 2'h2;
  wire exception_pa_mmio_nc = io_pmpResp_mmio | pbmt_is_nc | pbmtReg == 2'h1;
  wire pm_exception =
    exceptionVec_15 | exceptionVec_13 | exceptionVec_23 | exceptionVec_21 | exceptionVec_7
    | exceptionVec_5 | io_pmpResp_st | io_pmpResp_ld | exception_pa_mmio_nc;
  wire pm_exc_or_abort = pm_exception | tlb_hit_abort;

  // ---- 输出握手推进 --------------------------------------------------------
  wire sc_out_fire = at_sc & io_out_valid_0;
  wire keep_going = ~sc_out_fire | is_amocas_2c;
  wire amo_out_fire = at_amo & io_out_valid_0;
  wire [3:0] nextTlbMux = req_abort ? 4'h7 : 4'h2;
  wire [3:0] nextPmMux = pm_exception ? 4'h7 : io_flush_sbuffer_empty ? 4'h4 : 4'h3;
  wire [3:0] nextFlushExc = {1'h0, pm_exception, 2'h3};
  wire pm_ld_or_nc = io_pmpResp_ld | exception_pa_mmio_nc;
  // cache error 检查(仅在 s_finish, dcache_resp_error & csr enable)
  wire cache_error_fire = at_finish & dcache_resp_error & io_csrCtrl_cache_error_enable;

  // ---- 时序块 1: 主状态机 + 大多数控制寄存器(异步 reset) ------------------
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      state <= S_INVALID;
      out_valid <= 1'h0;
      data_valid <= 1'h0;
      pdest1Valid <= 1'h0;
      pdest2Valid <= 1'h0;
      stdCnt <= 3'h0;
      exceptionVec_3 <= 1'h0;
      exceptionVec_4 <= 1'h0;
      exceptionVec_5 <= 1'h0;
      exceptionVec_6 <= 1'h0;
      exceptionVec_7 <= 1'h0;
      exceptionVec_13 <= 1'h0;
      exceptionVec_15 <= 1'h0;
      exceptionVec_21 <= 1'h0;
      exceptionVec_23 <= 1'h0;
      trigger <= 4'hF;
      atom_override_xtval <= 1'h0;
      have_sent_first_tlb_req <= 1'h0;
      tEnableVec_0 <= 1'h0;
      tEnableVec_1 <= 1'h0;
      tEnableVec_2 <= 1'h0;
      tEnableVec_3 <= 1'h0;
      backendTriggerCanFireVec_0 <= 1'h0;
      backendTriggerCanFireVec_1 <= 1'h0;
      backendTriggerCanFireVec_2 <= 1'h0;
      backendTriggerCanFireVec_3 <= 1'h0;
      io_feedbackSlow_valid_last_REG <= 1'h0;
      io_feedbackSlow_valid_last_REG_1 <= 1'h0;
    end
    else begin
      // ---- 状态转移(优先级链, 与 golden 完全一致) ----
      if (amo_out_fire)
        state <= S_INVALID;
      else if (sc_out_fire)
        state <= {is_amocas_2c, 3'h0};           // AMOCAS.Q → s_amo(8), 否则 s_invalid(0)
      else if (at_finish)
        state <= S_SC;
      else if (dcache_resp_fire) begin                      // s_cache_resp & dcache_resp_valid
        if (io_dcache_resp_bits_miss) begin
          if (io_dcache_resp_bits_replay)
            state <= S_CACHE_REQ;
          else if (dcache_req_fire)
            state <= S_CACHE_RESP;
          else if (at_wait_flush) begin
            if (io_flush_sbuffer_empty)
              state <= S_CACHE_REQ;
            else if (at_pm)
              state <= nextFlushExc;
            else if (tlb_resp_hit)
              state <= nextTlbMux;
            else if (enq_fire)
              state <= S_TLB;
          end
          else if (at_pm)
            state <= nextPmMux;
          else if (tlb_resp_hit)
            state <= nextTlbMux;
          else if (enq_fire)
            state <= S_TLB;
        end
        else
          state <= S_FINISH;
      end
      else if (dcache_req_fire)
        state <= S_CACHE_RESP;
      else if (at_wait_flush) begin
        if (io_flush_sbuffer_empty)
          state <= S_CACHE_REQ;
        else if (at_pm)
          state <= nextFlushExc;
        else if (tlb_resp_hit)
          state <= nextTlbMux;
        else if (enq_fire)
          state <= S_TLB;
      end
      else if (at_pm)
        state <= nextPmMux;
      else if (tlb_resp_hit)
        state <= nextTlbMux;
      else if (enq_fire)
        state <= S_TLB;

      out_valid <=
        ~amo_out_fire
        & (sc_out_fire ? is_amocas_2c
             : at_finish
               | (at_pm ? pm_exc_or_abort | out_valid
                        : tlb_hit_abort | out_valid));
      data_valid <=
        ~amo_out_fire & keep_going
        & (data_valid ? data_valid
             : (|state)
               & (is_amocas_2c & stdCnt == 3'h4
                  | (uop_fuOpType == 9'h2E | uop_fuOpType == 9'h2F) & stdCnt == 3'h2
                  | ~isAMOCAS & stdCnt == 3'h1));
      pdest1Valid <= ~amo_out_fire & keep_going & (enq_pdest1 | pdest1Valid);
      pdest2Valid <= ~amo_out_fire & keep_going & (enq_pdest2 | pdest2Valid);
      if (amo_out_fire | ~keep_going)
        stdCnt <= 3'h0;
      else
        stdCnt <=
          3'(stdCnt
             + {1'h0, 2'({1'h0, io_storeDataIn_0_valid} + {1'h0, io_storeDataIn_1_valid})});
      if (tlb_resp_at_tlb) begin
        exceptionVec_3 <= triggerBreakpoint;
        exceptionVec_4 <= ~addrAligned & isLr;
        exceptionVec_6 <= ~addrAligned & ~isLr;
        exceptionVec_13 <= io_dtlb_resp_bits_excp_0_pf_ld;
        exceptionVec_15 <= io_dtlb_resp_bits_excp_0_pf_st;
        exceptionVec_21 <= io_dtlb_resp_bits_excp_0_gpf_ld;
        exceptionVec_23 <= io_dtlb_resp_bits_excp_0_gpf_st;
        trigger <= triggerAction;
      end
      if (cache_error_fire) begin
        exceptionVec_5 <= isLr;
        exceptionVec_7 <= ~isLr;
      end
      else if (at_pm) begin
        exceptionVec_5 <= exceptionVec_5 | pm_ld_or_nc & isLr;
        exceptionVec_7 <= exceptionVec_7 | io_pmpResp_st | pm_ld_or_nc & ~isLr;
      end
      else if (tlb_resp_at_tlb) begin
        exceptionVec_5 <= io_dtlb_resp_bits_excp_0_af_ld;
        exceptionVec_7 <= io_dtlb_resp_bits_excp_0_af_st;
      end
      atom_override_xtval <=
        ~io_redirect_valid
        & (at_pm ? pm_exc_or_abort | atom_override_xtval
                 : tlb_hit_abort | atom_override_xtval);
      have_sent_first_tlb_req <= io_dtlb_req_valid_0 | ~enq_fire & have_sent_first_tlb_req;
      tEnableVec_0 <= io_csrCtrl_mem_trigger_tEnableVec_0;
      tEnableVec_1 <= io_csrCtrl_mem_trigger_tEnableVec_1;
      tEnableVec_2 <= io_csrCtrl_mem_trigger_tEnableVec_2;
      tEnableVec_3 <= io_csrCtrl_mem_trigger_tEnableVec_3;
      backendTriggerCanFireVec_0 <= backendTriggerHitVec_0 & ~tdata_0_chain;
      backendTriggerCanFireVec_1 <=
        (tdata_0_chain & backendTriggerHitVec_0 | ~tdata_0_chain)
        & (tdata_0_chain & ~tdata_1_chain & tdata_0_timing == tdata_1_timing
           | ~tdata_0_chain) & backendTriggerHitVec_1 & ~tdata_1_chain;
      backendTriggerCanFireVec_2 <=
        (tdata_1_chain & backendTriggerHitVec_1 | ~tdata_1_chain)
        & (tdata_1_chain & ~tdata_2_chain & tdata_1_timing == tdata_2_timing
           | ~tdata_1_chain) & backendTriggerHitVec_2 & ~tdata_2_chain;
      backendTriggerCanFireVec_3 <=
        (tdata_2_chain & backendTriggerHitVec_2 | ~tdata_2_chain)
        & (tdata_2_chain & ~tdata_3_chain & tdata_2_timing == tdata_3_timing
           | ~tdata_2_chain)
        & (~tdata_3_select & ~io_csrCtrl_mem_trigger_debugMode & ~isLr
           & ((&tdata_3_matchType) ? rs1[49:0] < tdata_3_tdata2[49:0]
                : tdata3_mtEq2 ? rs1[49:0] >= tdata_3_tdata2[49:0]
                    : tdata3_mtEq0 & rs1[49:0] == tdata_3_tdata2[49:0])
           & tEnableVec_3 & tdata_3_store | ~tdata_3_select
           & ~io_csrCtrl_mem_trigger_debugMode & ~isSc
           & ((&tdata_3_matchType) ? rs1[49:0] < tdata_3_tdata2[49:0]
                : tdata3_mtEq2 ? rs1[49:0] >= tdata_3_tdata2[49:0]
                    : tdata3_mtEq0 & rs1[49:0] == tdata_3_tdata2[49:0])
           & tEnableVec_3 & tdata_3_load) & ~tdata_3_chain;
      io_feedbackSlow_valid_last_REG <= io_in_valid;
      io_feedbackSlow_valid_last_REG_1 <= io_feedbackSlow_valid_last_REG;
    end
  end

  // ---- rdataSel: 按 paddr 低位选高/低 64 位 -------------------------------
  wire [127:0] rdataSel =
    (|(paddr[2:0])) ? {32'h0, dcache_resp_data[127:32]} : dcache_resp_data;

  // ---- trigger tdata 更新使能(按 tUpdate.addr 选 tdata 槽) ----------------
  wire tdata_wr0 = io_csrCtrl_mem_trigger_tUpdate_valid & io_csrCtrl_mem_trigger_tUpdate_bits_addr == 2'h0;
  wire tdata_wr1 = io_csrCtrl_mem_trigger_tUpdate_valid & io_csrCtrl_mem_trigger_tUpdate_bits_addr == 2'h1;
  wire tdata_wr2 = io_csrCtrl_mem_trigger_tUpdate_valid & io_csrCtrl_mem_trigger_tUpdate_bits_addr == 2'h2;
  wire tdata_wr3 = io_csrCtrl_mem_trigger_tUpdate_valid & (&io_csrCtrl_mem_trigger_tUpdate_bits_addr);

  // ---- 时序块 2: 数据通路寄存器(同步, 无异步 reset) -----------------------
  always @(posedge clock) begin
    if (enq_fire) begin
      uop_fuOpType <= io_in_bits_uop_fuOpType;
      uop_rfWen <= io_in_bits_uop_rfWen;
      uop_robIdx_flag <= io_in_bits_uop_robIdx_flag;
      uop_robIdx_value <= io_in_bits_uop_robIdx_value;
      uop_debugInfo_enqRsTime <= io_in_bits_uop_debugInfo_enqRsTime;
      uop_debugInfo_selectTime <= io_in_bits_uop_debugInfo_selectTime;
      uop_debugInfo_issueTime <= io_in_bits_uop_debugInfo_issueTime;
    end
    if (enq_pdest1)
      pdest1 <= io_in_bits_uop_pdest;
    if (enq_pdest2)
      pdest2 <= io_in_bits_uop_pdest;
    if (tlb_resp_at_tlb) begin
      rs1 <= io_dtlb_resp_bits_fullva;
      paddr <= io_dtlb_resp_bits_paddr_0;
      gpaddr <= io_dtlb_resp_bits_gpaddr_0;
      isForVSnonLeafPTE <= io_dtlb_resp_bits_isForVSnonLeafPTE;
    end
    else if (enq_fire)
      rs1 <= io_in_bits_src_0;
    // store-data 分拣落库(端口 1 优先于端口 0, 与 golden 一致)
    if (sels_1_1)      rs2_l <= io_storeDataIn_1_bits_data;
    else if (sels_0_1) rs2_l <= io_storeDataIn_0_bits_data;
    if (sels_1_3)      rs2_h <= io_storeDataIn_1_bits_data;
    else if (sels_0_3) rs2_h <= io_storeDataIn_0_bits_data;
    if (sels_1)        rd_l <= io_storeDataIn_1_bits_data;
    else if (sels_0)   rd_l <= io_storeDataIn_0_bits_data;
    if (sels_1_2)      rd_h <= io_storeDataIn_1_bits_data;
    else if (sels_0_2) rd_h <= io_storeDataIn_0_bits_data;
    if (at_pm)
      is_mmio <= pbmt_is_nc | pbmtReg == 2'h0 & io_pmpResp_mmio;
    if (at_finish) begin
      resp_data <=
        isSc ? dcache_resp_data
          : (uop_fuOpType[1:0] == 2'h2 ? {{96{rdataSel[31]}}, rdataSel[31:0]} : 128'h0)
            | ((&(uop_fuOpType[1:0])) ? {{64{rdataSel[63]}}, rdataSel[63:0]} : 128'h0)
            | ((|(uop_fuOpType[1:0])) ? 128'h0 : rdataSel);
      success <= dcache_resp_id[0];
    end
    // backend trigger tdata[0..3] 更新
    if (tdata_wr0) begin
      tdata_0_matchType <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType;
      tdata_0_select <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select;
      tdata_0_action <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action;
      tdata_0_chain <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain;
      tdata_0_store <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store;
      tdata_0_load <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load;
      tdata_0_tdata2 <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2;
    end
    tdata_0_timing <= ~tdata_wr0 & tdata_0_timing;
    if (tdata_wr1) begin
      tdata_1_matchType <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType;
      tdata_1_select <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select;
      tdata_1_action <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action;
      tdata_1_chain <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain;
      tdata_1_store <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store;
      tdata_1_load <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load;
      tdata_1_tdata2 <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2;
    end
    tdata_1_timing <= ~tdata_wr1 & tdata_1_timing;
    if (tdata_wr2) begin
      tdata_2_matchType <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType;
      tdata_2_select <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select;
      tdata_2_action <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action;
      tdata_2_chain <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain;
      tdata_2_store <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store;
      tdata_2_load <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load;
      tdata_2_tdata2 <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2;
    end
    tdata_2_timing <= ~tdata_wr2 & tdata_2_timing;
    if (tdata_wr3) begin
      tdata_3_matchType <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType;
      tdata_3_select <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select;
      tdata_3_action <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action;
      tdata_3_chain <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain;
      tdata_3_store <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store;
      tdata_3_load <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load;
      tdata_3_tdata2 <= io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2;
    end
    tdata_3_timing <= ~tdata_wr3 & tdata_3_timing;
    if (io_dtlb_resp_valid & ~io_dtlb_resp_bits_miss)
      pbmtReg <= io_dtlb_resp_bits_pbmt_0;
    if (~dcache_resp_fire | io_dcache_resp_bits_miss) begin
    end
    else begin
      dcache_resp_data <= io_dcache_resp_bits_data;
      dcache_resp_id <= io_dcache_resp_bits_id;
      dcache_resp_error <= io_dcache_resp_bits_error;
    end
    if (io_in_valid) begin
      io_feedbackSlow_bits_sqIdx_r_flag <= io_in_bits_uop_sqIdx_flag;
      io_feedbackSlow_bits_sqIdx_r_value <= io_in_bits_uop_sqIdx_value;
    end
  end

  // ---- difftest LrSc 事件探针(纯 DPI 副作用, 无功能输出; 两侧 elaborate 同一 golden) ----
  DummyDPICWrapper_50 difftest_module (
    .clock           (clock),
    .io_valid        (difftest_valid),
    .io_bits_valid   (difftest_valid),
    .io_bits_success (success),
    .io_bits_coreid  ({2'h0, io_hartId})
  );

  // ---- 组合输出 ------------------------------------------------------------
  assign io_in_ready = io_in_ready_0;
  assign io_out_valid = io_out_valid_0;
  assign io_out_bits_uop_exceptionVec_3 = exceptionVec_3;
  assign io_out_bits_uop_exceptionVec_4 = exceptionVec_4;
  assign io_out_bits_uop_exceptionVec_5 = exceptionVec_5;
  assign io_out_bits_uop_exceptionVec_6 = exceptionVec_6;
  assign io_out_bits_uop_exceptionVec_7 = exceptionVec_7;
  assign io_out_bits_uop_exceptionVec_13 = exceptionVec_13;
  assign io_out_bits_uop_exceptionVec_15 = exceptionVec_15;
  assign io_out_bits_uop_exceptionVec_21 = exceptionVec_21;
  assign io_out_bits_uop_exceptionVec_23 = exceptionVec_23;
  assign io_out_bits_uop_trigger = trigger;
  assign io_out_bits_uop_rfWen = uop_rfWen;
  assign io_out_bits_uop_pdest = at_amo ? pdest2 : pdest1;
  assign io_out_bits_uop_robIdx_flag = uop_robIdx_flag;
  assign io_out_bits_uop_robIdx_value = uop_robIdx_value;
  assign io_out_bits_uop_debugInfo_enqRsTime = uop_debugInfo_enqRsTime;
  assign io_out_bits_uop_debugInfo_selectTime = uop_debugInfo_selectTime;
  assign io_out_bits_uop_debugInfo_issueTime = uop_debugInfo_issueTime;
  assign io_out_bits_data = at_amo ? resp_data[127:64] : resp_data[63:0];
  assign io_out_bits_debug_isMMIO = is_mmio;
  assign io_dcache_req_valid = io_dcache_req_valid_0;
  assign io_dcache_req_bits_cmd = dcacheCmd;
  assign io_dcache_req_bits_vaddr = {rs1[49:6], 6'h0};
  assign io_dcache_req_bits_addr = {paddr[47:6], 6'h0};
  assign io_dcache_req_bits_word_idx = paddr[5:3];
  assign io_dcache_req_bits_amo_data =
    (uop_fuOpType[1:0] == 2'h2 ? {2{{2{rs2_lo_sel[31:0]}}}} : 128'h0)
    | ((&(uop_fuOpType[1:0])) ? {2{rs2_lo_sel}} : 128'h0)
    | ((|(uop_fuOpType[1:0])) ? 128'h0 : {rs2_h, rs2_lo_sel});
  assign io_dcache_req_bits_amo_mask =
    {5'h0,
     amoMaskWord[10:8],
     amoMaskWord[7:0] | {8{&(uop_fuOpType[1:0])}}}
    | {16{~(|(uop_fuOpType[1:0]))}};
  assign io_dcache_req_bits_amo_cmp =
    (uop_fuOpType[1:0] == 2'h2 ? {2{{2{rd_l[31:0]}}}} : 128'h0)
    | ((&(uop_fuOpType[1:0])) ? {2{rd_l}} : 128'h0)
    | ((|(uop_fuOpType[1:0])) ? 128'h0 : {rd_h, rd_l});
  assign io_dtlb_req_valid = io_dtlb_req_valid_0;
  assign io_dtlb_req_bits_vaddr = rs1[49:0];
  assign io_dtlb_req_bits_fullva = rs1;
  assign io_dtlb_req_bits_cmd = {2'h2, ~isLr};
  assign io_dtlb_req_bits_debug_robIdx_flag = uop_robIdx_flag;
  assign io_dtlb_req_bits_debug_robIdx_value = uop_robIdx_value;
  assign io_flush_sbuffer_valid =
    ~io_flush_sbuffer_empty & (io_dtlb_req_valid_0 | at_pm | at_wait_flush);
  assign io_feedbackSlow_valid = io_feedbackSlow_valid_last_REG_1;
  assign io_feedbackSlow_bits_sqIdx_flag = io_feedbackSlow_bits_sqIdx_r_flag;
  assign io_feedbackSlow_bits_sqIdx_value = io_feedbackSlow_bits_sqIdx_r_value;
  assign io_exceptionInfo_valid = atom_override_xtval;
  assign io_exceptionInfo_bits_vaddr = rs1;
  assign io_exceptionInfo_bits_gpaddr = gpaddr;
  assign io_exceptionInfo_bits_isForVSnonLeafPTE = isForVSnonLeafPTE;

endmodule
