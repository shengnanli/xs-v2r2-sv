// =============================================================================
// xs_BranchUnit_core —— 香山 V2R2(昆明湖) 条件分支执行单元(可读重写)
// -----------------------------------------------------------------------------
// 设计源: fu/wrapper/BranchUnit.scala (class BranchUnit + AddrAddModule)
//          fu/Branch.scala (class BranchModule)
//
// 功能定位: 整数执行簇(ExuBlock)里的 0 延迟分支单元。后端发射的条件分支 uop
//   (beq/bne/blt/bge/bltu/bgeu)在此判定真实走向, 与前端 BPU 的预测对比, 若错则
//   生成后端重定向冲刷错误路径并把正确目标回填前端 ftq/cfiUpdate。
//
// 数据流(纯组合, 当拍进当拍出):
//   src0,src1 ┐
//   fuOpType  ├─► branchCmp(条件) ─► taken ─► mispredict = predTaken ^ taken
//   predTaken ┘                       │
//   pc,imm,nextPcOffset,transType ─► branchTarget ─► fullTarget(64) ─► cfiUpdate.target/faults
//   redirect.valid = io.in.valid & mispredict
//
// 端口名沿用 golden 扁平名(io_*), 以便 wrapper/_xs 透传 + FM 签名比对; 可读性体现在
// 内部的 enum/struct/function 与中文注释。其余 cfiUpdate/折叠历史等字段本单元不产生,
// 在 wrapper 里恒置 0(详见 BranchUnit_wrapper.sv)。
//
// 结构闸门(自检): typedef enum>0, typedef struct>0, function automatic>0; 0 生成痕迹。
// =============================================================================
module xs_BranchUnit_core
  import branchunit_pkg::*;
(
  // ---- 输入: 来自 DataPath/发射的分支 uop ----
  input  logic        io_in_valid,
  input  logic [8:0]  io_in_bits_ctrl_fuOpType,
  input  logic        io_in_bits_ctrl_robIdx_flag,
  input  logic [7:0]  io_in_bits_ctrl_robIdx_value,
  input  logic [7:0]  io_in_bits_ctrl_pdest,
  input  logic        io_in_bits_ctrl_ftqIdx_flag,
  input  logic [5:0]  io_in_bits_ctrl_ftqIdx_value,
  input  logic [3:0]  io_in_bits_ctrl_ftqOffset,
  input  logic        io_in_bits_ctrl_predictInfo_taken,
  input  logic [63:0] io_in_bits_data_src_1,
  input  logic [63:0] io_in_bits_data_src_0,
  input  logic [63:0] io_in_bits_data_imm,
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
  // ---- 输出: 写回 + 重定向(本单元真正驱动的字段) ----
  output logic        io_out_valid,
  output logic        io_out_bits_ctrl_robIdx_flag,
  output logic [7:0]  io_out_bits_ctrl_robIdx_value,
  output logic [7:0]  io_out_bits_ctrl_pdest,
  output logic [63:0] io_out_bits_res_data,
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
  // 1) 分支条件判定 (对应 BranchModule)
  //    branchType = fuOpType[3:1], invert = fuOpType[0]
  //    taken = branchCmp(type) ^ invert
  //      例: blt → cmp=slt, invert=0 → taken=slt
  //          bge → cmp=slt, invert=1 → taken=!slt
  //    mispredict = 前端预测 ^ 实际走向
  // ---------------------------------------------------------------------------
  br_type_e br_type;
  logic     br_invert;
  logic     taken, mispredict;
  logic     pred_taken;

  assign br_type    = br_type_e'(io_in_bits_ctrl_fuOpType[3:1]);
  assign br_invert  = io_in_bits_ctrl_fuOpType[0];
  assign pred_taken = io_in_bits_ctrl_predictInfo_taken;
  assign taken      = branchCmp(br_type,
                                io_in_bits_data_src_0,
                                io_in_bits_data_src_1) ^ br_invert;
  assign mispredict = pred_taken ^ taken;

  // ---------------------------------------------------------------------------
  // 2) 目标地址计算 (对应 AddrAddModule)
  //    pcExtend(51): 顶位是否要做符号扩展取决于翻译模式(sv39/sv48 时按 pc[49] 扩展,
  //    其余 zext)。target = sext( taken ? pc+sext(imm) : pc+(nextPcOffset<<1) , 64)
  // ---------------------------------------------------------------------------
  addr_trans_e trans;
  logic        pc_should_sext;
  logic [VAddrBits:0]   pc_extend; // 51 位
  logic [XLEN-1:0]      full_target;

  assign trans = '{bare:   io_instrAddrTransType_bare,
                   sv39:   io_instrAddrTransType_sv39,
                   sv39x4: io_instrAddrTransType_sv39x4,
                   sv48:   io_instrAddrTransType_sv48,
                   sv48x4: io_instrAddrTransType_sv48x4};
  // 仅 Sv39/Sv48 一阶段需要按虚地址最高有效位做符号扩展(规范要求高位为符号扩展)
  assign pc_should_sext = (trans.sv39 | trans.sv48) & io_in_bits_data_pc[VAddrBits-1];
  assign pc_extend      = {pc_should_sext, io_in_bits_data_pc};
  assign full_target    = branchTarget(pc_extend, taken,
                                       io_in_bits_data_imm[BrImmWidth-1:0],
                                       io_in_bits_data_nextPcOffset);

  // ---------------------------------------------------------------------------
  // 3) 目标地址合法性检查 (跨 canonical 区即异常, 取指阶段会用)
  //    IAF : bare 模式下高 16 位非 0 (物理地址越界)
  //    IPF : Sv39/Sv48 高位非符号扩展(非 canonical 虚地址)
  //    IGPF: Sv39x4/Sv48x4 G-stage 客户物理地址高位非 0
  // ---------------------------------------------------------------------------
  cfi_payload_t cfi;
  assign cfi.target     = full_target[VAddrBits-1:0];
  assign cfi.taken      = taken;
  assign cfi.predTaken  = pred_taken;
  assign cfi.isMisPred  = mispredict;
  assign cfi.backendIAF = trans.bare   & (|full_target[63:48]);
  assign cfi.backendIPF = (trans.sv39 & (full_target[63:39] != {25{full_target[38]}}))
                        | (trans.sv48 & (full_target[63:48] != {16{full_target[47]}}));
  assign cfi.backendIGPF= (trans.sv39x4 & (|full_target[63:41]))
                        | (trans.sv48x4 & (|full_target[63:50]));

  // ---------------------------------------------------------------------------
  // 4) 输出驱动: 直通字段 + 重定向
  //    redirect.valid 仅在 in.valid & mispredict 时拉高(预测错误才冲刷)。
  //    res.data 恒 0: 分支不写回通用寄存器结果。
  // ---------------------------------------------------------------------------
  assign io_out_valid                 = io_in_valid;
  assign io_out_bits_ctrl_robIdx_flag = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value= io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_ctrl_pdest       = io_in_bits_ctrl_pdest;
  assign io_out_bits_res_data         = 64'h0;

  assign io_out_bits_res_redirect_valid           = io_in_valid & mispredict;
  assign io_out_bits_res_redirect_bits_robIdx_flag = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_res_redirect_bits_robIdx_value= io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_res_redirect_bits_ftqIdx_flag = io_in_bits_ctrl_ftqIdx_flag;
  assign io_out_bits_res_redirect_bits_ftqIdx_value= io_in_bits_ctrl_ftqIdx_value;
  assign io_out_bits_res_redirect_bits_ftqOffset   = io_in_bits_ctrl_ftqOffset;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pc        = io_in_bits_data_pc;
  assign io_out_bits_res_redirect_bits_cfiUpdate_predTaken = cfi.predTaken;
  assign io_out_bits_res_redirect_bits_cfiUpdate_target    = cfi.target;
  assign io_out_bits_res_redirect_bits_cfiUpdate_taken     = cfi.taken;
  assign io_out_bits_res_redirect_bits_cfiUpdate_isMisPred = cfi.isMisPred;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF = cfi.backendIGPF;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIPF  = cfi.backendIPF;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIAF  = cfi.backendIAF;
  assign io_out_bits_res_redirect_bits_fullTarget = full_target;

  // 性能调试信息直通
  assign io_out_bits_perfDebugInfo_enqRsTime  = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime  = io_in_bits_perfDebugInfo_issueTime;

endmodule
