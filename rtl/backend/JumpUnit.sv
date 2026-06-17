// =============================================================================
// xs_JumpUnit_core —— 香山 V2R2(昆明湖) 无条件跳转执行单元(可读重写)
// -----------------------------------------------------------------------------
// 设计源: fu/wrapper/JumpUnit.scala (class JumpUnit) + fu/Jump.scala (JumpDataModule)
//
// 功能定位: 整数执行簇里的 0 延迟跳转单元, 处理 jal/jalr/auipc。
//   jal/jalr 在前端 BPU 已做目标预测, 后端必须用真实计算的目标校验, 因此除 auipc 外
//   恒生成重定向(redirect.valid = in.valid & !isAuipc), 用 isMisPred 标记是否预测错误。
//   auipc 不是跳转, 只把 pc+imm 写回 rd, 不产生重定向。
//
// 数据流(纯组合):
//   src0(rs1) ┐
//   pc        ├─► jumpCalc ─► {result(写回 rd), target(跳转目标), isAuipc}
//   imm,func  ┘                  │
//                                ├─► res.data = result
//                                ├─► fullTarget = target ─► cfiUpdate.target/faults
//                                └─► isMisPred = (target[49:0] != predTarget) | !predTaken
//   redirect.valid = in.valid & !isAuipc
//
// 结构闸门(自检): typedef enum>0, typedef struct>0, function automatic>0; 0 生成痕迹。
// =============================================================================
module xs_JumpUnit_core
  import jumpunit_pkg::*;
(
  // ---- 输入: 跳转 uop ----
  input  logic        io_in_valid,
  input  logic [8:0]  io_in_bits_ctrl_fuOpType,
  input  logic        io_in_bits_ctrl_robIdx_flag,
  input  logic [7:0]  io_in_bits_ctrl_robIdx_value,
  input  logic [7:0]  io_in_bits_ctrl_pdest,
  input  logic        io_in_bits_ctrl_rfWen,
  input  logic        io_in_bits_ctrl_ftqIdx_flag,
  input  logic [5:0]  io_in_bits_ctrl_ftqIdx_value,
  input  logic [3:0]  io_in_bits_ctrl_ftqOffset,
  input  logic [49:0] io_in_bits_ctrl_predictInfo_target, // 前端预测目标(低 50 位)
  input  logic        io_in_bits_ctrl_predictInfo_taken,  // 前端是否预测 taken
  input  logic [63:0] io_in_bits_data_src_0,              // rs1
  input  logic [63:0] io_in_bits_data_imm,                // imm(低 33 位有效)
  input  logic [49:0] io_in_bits_data_pc,
  input  logic [4:0]  io_in_bits_data_nextPcOffset,
  input  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_issueTime,
  // ---- 地址翻译模式(one-hot) ----
  input  logic        io_instrAddrTransType_bare,
  input  logic        io_instrAddrTransType_sv39,
  input  logic        io_instrAddrTransType_sv39x4,
  input  logic        io_instrAddrTransType_sv48,
  input  logic        io_instrAddrTransType_sv48x4,
  // ---- 输出 ----
  output logic        io_out_valid,
  output logic        io_out_bits_ctrl_robIdx_flag,
  output logic [7:0]  io_out_bits_ctrl_robIdx_value,
  output logic [7:0]  io_out_bits_ctrl_pdest,
  output logic        io_out_bits_ctrl_rfWen,
  output logic [63:0] io_out_bits_res_data,               // 写回 rd
  output logic        io_out_bits_res_redirect_valid,
  output logic        io_out_bits_res_redirect_bits_robIdx_flag,
  output logic [7:0]  io_out_bits_res_redirect_bits_robIdx_value,
  output logic        io_out_bits_res_redirect_bits_ftqIdx_flag,
  output logic [5:0]  io_out_bits_res_redirect_bits_ftqIdx_value,
  output logic [3:0]  io_out_bits_res_redirect_bits_ftqOffset,
  output logic [49:0] io_out_bits_res_redirect_bits_cfiUpdate_pc,
  output logic        io_out_bits_res_redirect_bits_cfiUpdate_predTaken,
  output logic [49:0] io_out_bits_res_redirect_bits_cfiUpdate_target,
  output logic        io_out_bits_res_redirect_bits_cfiUpdate_taken,
  output logic        io_out_bits_res_redirect_bits_cfiUpdate_isMisPred,
  output logic        io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF,
  output logic        io_out_bits_res_redirect_bits_cfiUpdate_backendIPF,
  output logic        io_out_bits_res_redirect_bits_cfiUpdate_backendIAF,
  output logic [63:0] io_out_bits_res_redirect_bits_fullTarget,
  output logic [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output logic [63:0] io_out_bits_perfDebugInfo_selectTime,
  output logic [63:0] io_out_bits_perfDebugInfo_issueTime
);

  // ---------------------------------------------------------------------------
  // 1) pc 扩展: Sv39/Sv48 一阶段按 pc[49] 符号扩展, 其余补 0
  // ---------------------------------------------------------------------------
  addr_trans_e     trans;
  logic            pc_should_sext;
  logic [XLEN-1:0] pc_ext;

  assign trans = '{bare:   io_instrAddrTransType_bare,
                   sv39:   io_instrAddrTransType_sv39,
                   sv39x4: io_instrAddrTransType_sv39x4,
                   sv48:   io_instrAddrTransType_sv48,
                   sv48x4: io_instrAddrTransType_sv48x4};
  assign pc_should_sext = (trans.sv39 | trans.sv48) & io_in_bits_data_pc[VAddrBits-1];
  // pc[49:0] 扩到 64 位: 高 14 位填扩展位
  assign pc_ext = {{(XLEN-VAddrBits){pc_should_sext}}, io_in_bits_data_pc};

  // ---------------------------------------------------------------------------
  // 2) 目标/返回地址计算 (JumpDataModule)
  // ---------------------------------------------------------------------------
  jmp_type_e  jmp_type;
  jump_calc_t calc;
  assign jmp_type = jmp_type_e'(io_in_bits_ctrl_fuOpType[1:0]); // 仅作可读标注
  assign calc = jumpCalc(io_in_bits_data_src_0, pc_ext,
                         io_in_bits_data_imm[ImmWidth-1:0],
                         io_in_bits_data_nextPcOffset,
                         io_in_bits_ctrl_fuOpType);

  // ---------------------------------------------------------------------------
  // 3) 目标合法性检查(同 BranchUnit 语义)
  // ---------------------------------------------------------------------------
  logic [XLEN-1:0] tgt;
  logic            backendIAF, backendIPF, backendIGPF;
  assign tgt = calc.target;
  assign backendIAF = trans.bare & (|tgt[63:48]);
  assign backendIPF = (trans.sv39 & (tgt[63:39] != {25{tgt[38]}}))
                    | (trans.sv48 & (tgt[63:48] != {16{tgt[47]}}));
  assign backendIGPF= (trans.sv39x4 & (|tgt[63:41]))
                    | (trans.sv48x4 & (|tgt[63:50]));

  // ---------------------------------------------------------------------------
  // 4) 重定向: jal/jalr 恒重定向(校验目标); auipc 不重定向。
  //    isMisPred = 真实目标低 50 位与前端预测目标不符, 或前端没预测 taken。
  //    taken/predTaken 对跳转恒为 1(跳转必定 taken)。
  // ---------------------------------------------------------------------------
  logic mispredict;
  assign mispredict =
      (tgt[VAddrBits-1:0] != io_in_bits_ctrl_predictInfo_target)
    | ~io_in_bits_ctrl_predictInfo_taken;

  // ---- 输出驱动 ----
  assign io_out_valid                  = io_in_valid;
  assign io_out_bits_ctrl_robIdx_flag  = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_ctrl_pdest        = io_in_bits_ctrl_pdest;
  assign io_out_bits_ctrl_rfWen        = io_in_bits_ctrl_rfWen;
  assign io_out_bits_res_data          = calc.result;

  assign io_out_bits_res_redirect_valid            = io_in_valid & ~calc.isAuipc;
  assign io_out_bits_res_redirect_bits_robIdx_flag = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_res_redirect_bits_robIdx_value= io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_res_redirect_bits_ftqIdx_flag = io_in_bits_ctrl_ftqIdx_flag;
  assign io_out_bits_res_redirect_bits_ftqIdx_value= io_in_bits_ctrl_ftqIdx_value;
  assign io_out_bits_res_redirect_bits_ftqOffset   = io_in_bits_ctrl_ftqOffset;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pc        = io_in_bits_data_pc;
  assign io_out_bits_res_redirect_bits_cfiUpdate_predTaken = 1'b1;
  assign io_out_bits_res_redirect_bits_cfiUpdate_target    = tgt[VAddrBits-1:0];
  assign io_out_bits_res_redirect_bits_cfiUpdate_taken     = 1'b1;
  assign io_out_bits_res_redirect_bits_cfiUpdate_isMisPred = mispredict;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF = backendIGPF;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIPF  = backendIPF;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIAF  = backendIAF;
  assign io_out_bits_res_redirect_bits_fullTarget = tgt;

  assign io_out_bits_perfDebugInfo_enqRsTime  = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime  = io_in_bits_perfDebugInfo_issueTime;

endmodule
