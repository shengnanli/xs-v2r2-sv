// JumpUnit.sv —— 跳转执行单元 jal / jalr / auipc（FuncUnit 包装层，0 拍延迟，纯组合）
//
// 位置：后端整数执行单元里的 JMP 功能单元。发射队列送来一条无条件跳转或 auipc，
//   本单元当拍算出写回值（link 地址或 pc+imm）与跳转目标，并在"前端预测的目标不对"
//   或"目标地址非法"时向 CtrlBlock 发重定向。
// 机制（对应 Chisel xiangshan/backend/fu/wrapper/JumpUnit.scala）：
//   1. pc 先扩到 64 位：sv39/sv48（地址应符号扩展的模式）下按 pc[49] 符号扩展，其余零扩展。
//   2. JumpDataModule 算 target = (jalr ? src : pc) + imm（最低位清 0）与
//      result = auipc ? pc+imm : pc + 顺序偏移（link 地址）。
//   3. isMisPred = target[49:0] != 预测目标  或  预测为不跳（跳转指令必 taken）。
//   4. 对 64 位目标地址按当前取指地址翻译模式做合法性检查（与 BranchUnit 完全相同）：
//        IAF  ：bare 模式，高 16 位必须全 0；
//        IPF  ：sv39 要求 [63:39] 是 bit38 的符号扩展，sv48 要求 [63:48] 是 bit47 的符号扩展；
//        IGPF ：sv39x4 要求 [63:41] 全 0，sv48x4 要求 [63:50] 全 0。
//   5. redirect.valid = in.valid & !auipc & (isMisPred | 任一后端取指异常)。
//      auipc 不是控制流指令，永不重定向；但它的 isMisPred / 异常位照常算、照常送出。
// 边界与怪癖：
//   - cfiUpdate.taken 与 cfiUpdate.predTaken 都恒 1（predTaken 不是"前端的预测"，是写死的 true）。
//   - io_in_bits_data_imm 是 64 位端口，只有低 33 位进 JumpDataModule。
//   - Chisel 里算了 flushed / isRVC 但没人用，golden 无对应逻辑。
//   - 多个翻译模式同时为 1 是非法输入，golden 各项直接相或，这里照抄。
// 子模块：JumpDataModule（本仓已重写签核的件，实例名与 golden 一致）。

module xs_JumpUnit_core (
  input  logic        in_valid,
  input  logic [63:0] src,               // jalr 的基址 rs1
  input  logic [8:0]  fu_op_type,        // bit0: jalr；bit1: auipc
  input  logic [49:0] pc,
  input  logic [32:0] imm,
  input  logic [4:0]  next_pc_offset,    // 顺序下一条相对 pc 的偏移（半字单位）
  input  logic        pred_taken,        // 前端是否预测为跳
  input  logic [49:0] pred_target,       // 前端预测的目标
  input  logic        trans_bare,        // 取指地址翻译模式（one-hot，由 CSR 给出）
  input  logic        trans_sv39,
  input  logic        trans_sv39x4,
  input  logic        trans_sv48,
  input  logic        trans_sv48x4,
  output logic [63:0] result,            // 写回 rd 的值
  output logic [63:0] target,
  output logic        mispredict,
  output logic        fault_iaf,         // 目标地址取指 access fault
  output logic        fault_ipf,         // 目标地址取指 page fault
  output logic        fault_igpf,        // 目标地址取指 guest page fault
  output logic        redirect_valid
);
  // ---- §1 pc 扩展到 64 位 ----
  logic        pc_should_sext;
  logic [63:0] pc_extend;
  assign pc_should_sext = trans_sv39 | trans_sv48;
  assign pc_extend      = {{14{pc_should_sext & pc[49]}}, pc};

  // ---- §2 写回值与跳转目标 ----
  logic is_auipc;
  JumpDataModule jumpDataModule (
    .io_src          (src),
    .io_pc           (pc_extend),
    .io_imm          (imm),
    .io_nextPcOffset (next_pc_offset),
    .io_func         (fu_op_type),
    .io_result       (result),
    .io_target       (target),
    .io_isAuipc      (is_auipc)
  );

  // ---- §3 预测对不对：目标不同，或者前端压根没预测要跳 ----
  assign mispredict = (target[49:0] != pred_target) | ~pred_taken;

  // ---- §4 目标地址合法性检查（后端取指异常）----
  assign fault_iaf  = trans_bare & (|target[63:48]);
  assign fault_ipf  = (trans_sv39 & (target[63:39] != {25{target[38]}}))
                    | (trans_sv48 & (target[63:48] != {16{target[47]}}));
  assign fault_igpf = (trans_sv39x4 & (|target[63:41]))
                    | (trans_sv48x4 & (|target[63:50]));

  // ---- §5 重定向请求（auipc 不重定向）----
  assign redirect_valid = in_valid & ~is_auipc
                        & (mispredict | fault_igpf | fault_ipf | fault_iaf);
endmodule

module JumpUnit (
  output logic         io_in_ready,
  input  logic         io_in_valid,
  input  logic [8:0]   io_in_bits_ctrl_fuOpType,
  input  logic         io_in_bits_ctrl_robIdx_flag,
  input  logic [7:0]   io_in_bits_ctrl_robIdx_value,
  input  logic [7:0]   io_in_bits_ctrl_pdest,
  input  logic         io_in_bits_ctrl_rfWen,
  input  logic         io_in_bits_ctrl_preDecode_valid,
  input  logic         io_in_bits_ctrl_preDecode_isRVC,
  input  logic [1:0]   io_in_bits_ctrl_preDecode_brType,
  input  logic         io_in_bits_ctrl_preDecode_isCall,
  input  logic         io_in_bits_ctrl_preDecode_isRet,
  input  logic         io_in_bits_ctrl_ftqIdx_flag,
  input  logic [5:0]   io_in_bits_ctrl_ftqIdx_value,
  input  logic [3:0]   io_in_bits_ctrl_ftqOffset,
  input  logic [49:0]  io_in_bits_ctrl_predictInfo_target,
  input  logic         io_in_bits_ctrl_predictInfo_taken,
  input  logic [63:0]  io_in_bits_data_src_0,
  input  logic [63:0]  io_in_bits_data_imm,
  input  logic [49:0]  io_in_bits_data_pc,
  input  logic [4:0]   io_in_bits_data_nextPcOffset,
  input  logic         io_in_bits_perfDebugInfo_eliminatedMove,
  input  logic [63:0]  io_in_bits_perfDebugInfo_renameTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_dispatchTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_enqRsTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_selectTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_issueTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_writebackTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_tlbRespTime,
  input  logic [55:0]  io_in_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_in_bits_debug_seqNum_uopIdx,
  input  logic         io_out_ready,
  output logic         io_out_valid,
  output logic         io_out_bits_ctrl_robIdx_flag,
  output logic [7:0]   io_out_bits_ctrl_robIdx_value,
  output logic [7:0]   io_out_bits_ctrl_pdest,
  output logic         io_out_bits_ctrl_rfWen,
  output logic         io_out_bits_ctrl_preDecode_valid,
  output logic         io_out_bits_ctrl_preDecode_isRVC,
  output logic [1:0]   io_out_bits_ctrl_preDecode_brType,
  output logic         io_out_bits_ctrl_preDecode_isCall,
  output logic         io_out_bits_ctrl_preDecode_isRet,
  output logic [63:0]  io_out_bits_res_data,
  output logic         io_out_bits_res_redirect_valid,
  output logic         io_out_bits_res_redirect_bits_isRVC,
  output logic         io_out_bits_res_redirect_bits_robIdx_flag,
  output logic [7:0]   io_out_bits_res_redirect_bits_robIdx_value,
  output logic         io_out_bits_res_redirect_bits_ftqIdx_flag,
  output logic [5:0]   io_out_bits_res_redirect_bits_ftqIdx_value,
  output logic [3:0]   io_out_bits_res_redirect_bits_ftqOffset,
  output logic         io_out_bits_res_redirect_bits_level,
  output logic         io_out_bits_res_redirect_bits_interrupt,
  output logic [49:0]  io_out_bits_res_redirect_bits_cfiUpdate_pc,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_pd_valid,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC,
  output logic [1:0]   io_out_bits_res_redirect_bits_cfiUpdate_pd_brType,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet,
  output logic [3:0]   io_out_bits_res_redirect_bits_cfiUpdate_ssp,
  output logic [2:0]   io_out_bits_res_redirect_bits_cfiUpdate_sctr,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag,
  output logic [4:0]   io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag,
  output logic [4:0]   io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag,
  output logic [4:0]   io_out_bits_res_redirect_bits_cfiUpdate_NOS_value,
  output logic [49:0]  io_out_bits_res_redirect_bits_cfiUpdate_topAddr,
  output logic [10:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist,
  output logic [10:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist,
  output logic [6:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist,
  output logic [7:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist,
  output logic [8:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist,
  output logic [3:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist,
  output logic [7:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist,
  output logic [8:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist,
  output logic [6:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist,
  output logic [7:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist,
  output logic [6:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist,
  output logic [8:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist,
  output logic [6:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist,
  output logic [7:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist,
  output logic [7:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist,
  output logic [7:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist,
  output logic [10:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist,
  output logic [7:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3,
  output logic [2:0]   io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH,
  output logic [3:0]   io_out_bits_res_redirect_bits_cfiUpdate_ghr,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag,
  output logic [7:0]   io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value,
  output logic [9:0]   io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0,
  output logic [9:0]   io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_br_hit,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_jr_hit,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_sc_hit,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_predTaken,
  output logic [49:0]  io_out_bits_res_redirect_bits_cfiUpdate_target,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_taken,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_isMisPred,
  output logic [1:0]   io_out_bits_res_redirect_bits_cfiUpdate_shift,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_backendIPF,
  output logic         io_out_bits_res_redirect_bits_cfiUpdate_backendIAF,
  output logic [63:0]  io_out_bits_res_redirect_bits_fullTarget,
  output logic         io_out_bits_res_redirect_bits_satpFlush,
  output logic         io_out_bits_res_redirect_bits_isVlsException,
  output logic         io_out_bits_res_redirect_bits_stFtqIdx_flag,
  output logic [5:0]   io_out_bits_res_redirect_bits_stFtqIdx_value,
  output logic [3:0]   io_out_bits_res_redirect_bits_stFtqOffset,
  output logic [63:0]  io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id,
  output logic         io_out_bits_res_redirect_bits_debugIsCtrl,
  output logic         io_out_bits_res_redirect_bits_debugIsMemVio,
  output logic         io_out_bits_perfDebugInfo_eliminatedMove,
  output logic [63:0]  io_out_bits_perfDebugInfo_renameTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_dispatchTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_enqRsTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_selectTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_issueTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_writebackTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output logic [63:0]  io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_tlbRespTime,
  output logic [55:0]  io_out_bits_debug_seqNum_seqNum,
  output logic [7:0]   io_out_bits_debug_seqNum_uopIdx,
  input  logic         io_instrAddrTransType_bare,
  input  logic         io_instrAddrTransType_sv39,
  input  logic         io_instrAddrTransType_sv39x4,
  input  logic         io_instrAddrTransType_sv48,
  input  logic         io_instrAddrTransType_sv48x4
);
  logic [63:0] result;
  logic [63:0] target;
  logic        mispredict;
  logic        fault_iaf;
  logic        fault_ipf;
  logic        fault_igpf;
  logic        redirect_valid;

  xs_JumpUnit_core u_core (
    .in_valid       (io_in_valid),
    .src            (io_in_bits_data_src_0),
    .fu_op_type     (io_in_bits_ctrl_fuOpType),
    .pc             (io_in_bits_data_pc),
    .imm            (io_in_bits_data_imm[32:0]),
    .next_pc_offset (io_in_bits_data_nextPcOffset),
    .pred_taken     (io_in_bits_ctrl_predictInfo_taken),
    .pred_target    (io_in_bits_ctrl_predictInfo_target),
    .trans_bare     (io_instrAddrTransType_bare),
    .trans_sv39     (io_instrAddrTransType_sv39),
    .trans_sv39x4   (io_instrAddrTransType_sv39x4),
    .trans_sv48     (io_instrAddrTransType_sv48),
    .trans_sv48x4   (io_instrAddrTransType_sv48x4),
    .result         (result),
    .target         (target),
    .mispredict     (mispredict),
    .fault_iaf      (fault_iaf),
    .fault_ipf      (fault_ipf),
    .fault_igpf     (fault_igpf),
    .redirect_valid (redirect_valid)
  );

  // ---- 握手与随指令直通的字段（0 拍延迟：ctrl / perfDebugInfo / debug_seqNum 原样带出）----
  assign io_in_ready = io_out_ready;
  assign io_out_valid = io_in_valid;
  assign io_out_bits_ctrl_robIdx_flag = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_ctrl_pdest = io_in_bits_ctrl_pdest;
  assign io_out_bits_ctrl_rfWen = io_in_bits_ctrl_rfWen;
  assign io_out_bits_ctrl_preDecode_valid = io_in_bits_ctrl_preDecode_valid;
  assign io_out_bits_ctrl_preDecode_isRVC = io_in_bits_ctrl_preDecode_isRVC;
  assign io_out_bits_ctrl_preDecode_brType = io_in_bits_ctrl_preDecode_brType;
  assign io_out_bits_ctrl_preDecode_isCall = io_in_bits_ctrl_preDecode_isCall;
  assign io_out_bits_ctrl_preDecode_isRet = io_in_bits_ctrl_preDecode_isRet;
  assign io_out_bits_perfDebugInfo_eliminatedMove = io_in_bits_perfDebugInfo_eliminatedMove;
  assign io_out_bits_perfDebugInfo_renameTime = io_in_bits_perfDebugInfo_renameTime;
  assign io_out_bits_perfDebugInfo_dispatchTime = io_in_bits_perfDebugInfo_dispatchTime;
  assign io_out_bits_perfDebugInfo_enqRsTime = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime = io_in_bits_perfDebugInfo_issueTime;
  assign io_out_bits_perfDebugInfo_writebackTime = io_in_bits_perfDebugInfo_writebackTime;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime = io_in_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_out_bits_perfDebugInfo_tlbRespTime = io_in_bits_perfDebugInfo_tlbRespTime;
  assign io_out_bits_debug_seqNum_seqNum = io_in_bits_debug_seqNum_seqNum;
  assign io_out_bits_debug_seqNum_uopIdx = io_in_bits_debug_seqNum_uopIdx;

  // ---- 重定向包里取自本条指令的字段 ----
  assign io_out_bits_res_redirect_bits_robIdx_flag = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_res_redirect_bits_robIdx_value = io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_res_redirect_bits_ftqIdx_flag = io_in_bits_ctrl_ftqIdx_flag;
  assign io_out_bits_res_redirect_bits_ftqIdx_value = io_in_bits_ctrl_ftqIdx_value;
  assign io_out_bits_res_redirect_bits_ftqOffset = io_in_bits_ctrl_ftqOffset;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pc = io_in_bits_data_pc;

  // ---- 写回数据与重定向包里由核算出的字段 ----
  assign io_out_bits_res_data = result;
  assign io_out_bits_res_redirect_valid = redirect_valid;
  assign io_out_bits_res_redirect_bits_cfiUpdate_target = target[49:0];
  assign io_out_bits_res_redirect_bits_cfiUpdate_isMisPred = mispredict;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF = fault_igpf;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIPF = fault_ipf;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIAF = fault_iaf;
  assign io_out_bits_res_redirect_bits_fullTarget = target;

  // ---- 跳转必然 taken：实际方向与"预测方向"字段都恒 1 ----
  assign io_out_bits_res_redirect_bits_cfiUpdate_predTaken = 1'b1;
  assign io_out_bits_res_redirect_bits_cfiUpdate_taken = 1'b1;

  // ---- 跳转单元不产生的字段：Chisel 先整包清零（redirect := 0.U.asTypeOf），
  //      level = RedirectLevel.flushAfter 的编码恰好也是 0 ----
  assign io_out_bits_res_redirect_bits_isRVC = '0;
  assign io_out_bits_res_redirect_bits_level = '0;
  assign io_out_bits_res_redirect_bits_interrupt = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_valid = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_brType = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_ssp = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_sctr = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_NOS_value = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_topAddr = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_ghr = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1 = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_br_hit = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_jr_hit = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_sc_hit = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_shift = '0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist = '0;
  assign io_out_bits_res_redirect_bits_satpFlush = '0;
  assign io_out_bits_res_redirect_bits_isVlsException = '0;
  assign io_out_bits_res_redirect_bits_stFtqIdx_flag = '0;
  assign io_out_bits_res_redirect_bits_stFtqIdx_value = '0;
  assign io_out_bits_res_redirect_bits_stFtqOffset = '0;
  assign io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id = '0;
  assign io_out_bits_res_redirect_bits_debugIsCtrl = '0;
  assign io_out_bits_res_redirect_bits_debugIsMemVio = '0;
endmodule
