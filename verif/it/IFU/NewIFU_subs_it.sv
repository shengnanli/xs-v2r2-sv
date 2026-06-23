// ===========================================================================
// IFU 簇 IT —— NewIFU 子模块适配器（重写叶子版）
//
// 与 rtl/frontend/NewIFU_subs.sv 端口逐字相同的五个 xs_newifu_* 适配器，
// 但内部把 golden 算法叶子替换为重写核（honest IT swap）：
//
//   xs_newifu_rvcexpander  -> xs_RVCExpander_core   （重写）
//   xs_newifu_predecode    -> xs_PreDecode_core     （重写）
//   xs_newifu_f3predecoder -> xs_F3Predecoder_core  （重写）
//   xs_newifu_predchecker  -> golden PredChecker    （工程无重写核，保留 golden）
//   xs_newifu_frontendtrigger -> golden FrontendTrigger （工程无重写核，保留 golden）
//
// 注意：本工程仅对 RVCExpander / PreDecode / F3Predecoder 提供了独立重写核
// （rtl/frontend/{RVCExpander,PreDecode,F3Predecoder}.sv 内 xs_*_core）。
// PredChecker / FrontendTrigger 没有独立重写核，IT 如实保留 golden 叶子。
//
// xs_NewIFU_core（rtl/frontend/NewIFU.sv，重写 glue）按名例化这些 xs_newifu_*，
// 因此本文件把 IT 链路的「重写 glue ↔ 重写叶子」边界真实连起来跑。
// IT 编译时用本文件代替 rtl/frontend/NewIFU_subs.sv（模块名相同，二选一）。
// ===========================================================================

// ---- xs_newifu_rvcexpander：重写 xs_RVCExpander_core ----
module xs_newifu_rvcexpander(
  input  wire [31:0] io_in,
  input  wire        io_fsIsOff,
  output wire [31:0] io_out_bits,
  output wire        io_ill
);
  // 重写核端口与 golden RVCExpander 完全一致，直接直连
  xs_RVCExpander_core u(.io_in(io_in), .io_fsIsOff(io_fsIsOff),
                        .io_out_bits(io_out_bits), .io_ill(io_ill));
endmodule

// ---- xs_newifu_predecode：重写 xs_PreDecode_core ----
module xs_newifu_predecode
  import xs_newifu_pkg::*;
(
  input  wire        clock,
  input  wire        reset,
  input  wire        in_valid,
  input  wire [PredictWidth:0][15:0] in_data,
  input  wire [PredictWidth-1:0][VAddrBits-1:0] pc, // golden 已裁剪，仅占位
  output pd_info_t [PredictWidth-1:0]    out_pd,
  output wire [PredictWidth-1:0][31:0]   out_instr,
  output wire [PredictWidth-1:0][63:0]   out_jumpOffset,
  output wire [PredictWidth-1:0]         out_hasHalfValid
);
  // 重写核全宽输出
  wire [PredictWidth-1:0]      c_valid, c_isRVC, c_isCall, c_isRet, c_hasHalfValid;
  wire [PredictWidth-1:0][1:0] c_brType;
  wire [PredictWidth-1:0][31:0] c_instr;
  wire [PredictWidth-1:0][63:0] c_jumpOffset;

  xs_PreDecode_core #(.PW(PredictWidth), .XLEN(64)) u (
    .io_data(in_data),
    .pd_valid(c_valid), .pd_isRVC(c_isRVC), .pd_brType(c_brType),
    .pd_isCall(c_isCall), .pd_isRet(c_isRet), .hasHalfValid(c_hasHalfValid),
    .instr(c_instr), .jumpOffset(c_jumpOffset)
  );

  // golden 裁掉了 pd_0_valid(恒1)、hasHalfValid_0/1(恒0)：在此与原 golden 适配器一致地置默认值，
  // 其余位置取重写核输出。（与 rtl/frontend/NewIFU_subs.sv 的 golden 版语义逐字一致。）
  assign out_pd[0].valid     = 1'b1;
  assign out_pd[0].isRVC     = c_isRVC[0];
  assign out_pd[0].brType    = c_brType[0];
  assign out_pd[0].isCall    = c_isCall[0];
  assign out_pd[0].isRet     = c_isRet[0];
  assign out_hasHalfValid[0] = 1'b0;
  assign out_hasHalfValid[1] = 1'b0;

  for (genvar i = 1; i < PredictWidth; i++) begin : g_pd
    assign out_pd[i].valid  = c_valid[i];
    assign out_pd[i].isRVC  = c_isRVC[i];
    assign out_pd[i].brType = c_brType[i];
    assign out_pd[i].isCall = c_isCall[i];
    assign out_pd[i].isRet  = c_isRet[i];
  end
  for (genvar i = 2; i < PredictWidth; i++) begin : g_hhv
    assign out_hasHalfValid[i] = c_hasHalfValid[i];
  end

  assign out_instr      = c_instr;
  assign out_jumpOffset = c_jumpOffset;
endmodule

// ---- xs_newifu_f3predecoder：重写 xs_F3Predecoder_core ----
module xs_newifu_f3predecoder
  import xs_newifu_pkg::*;
(
  input  wire [PredictWidth-1:0][31:0] instr,
  output wire [PredictWidth-1:0][1:0]  brType,
  output wire [PredictWidth-1:0]       isCall,
  output wire [PredictWidth-1:0]       isRet
);
  xs_F3Predecoder_core #(.PW(PredictWidth)) u (
    .io_instr(instr),
    .pd_brType(brType),
    .pd_isCall(isCall),
    .pd_isRet(isRet)
  );
endmodule

// ---- xs_newifu_predchecker：golden PredChecker（工程无独立重写核，保留 golden） ----
module xs_newifu_predchecker
  import xs_newifu_pkg::*;
(
  input  wire        clock,
  input  wire        ftqOffset_valid,
  input  wire [3:0]  ftqOffset_bits,
  input  wire [PredictWidth-1:0][63:0] jumpOffset,
  input  wire [VAddrBits-1:0]          target,
  input  wire [PredictWidth-1:0]       instrRange,
  input  wire [PredictWidth-1:0]       instrValid,
  input  pd_info_t [PredictWidth-1:0]  pds,
  input  wire [PredictWidth-1:0][VAddrBits-1:0] pc,
  input  wire        fire_in,
  output wire [PredictWidth-1:0]       fixedRange,
  output wire [PredictWidth-1:0]       fixedTaken,
  output wire [PredictWidth-1:0][VAddrBits-1:0] fixedTarget,
  output wire [PredictWidth-1:0][VAddrBits-1:0] jalTarget,
  output wire [PredictWidth-1:0]       fixedMissPred,
  output wire [PredictWidth-1:0][2:0]  faultType
);
  PredChecker u (
    .clock(clock),
    .io_in_ftqOffset_valid(ftqOffset_valid),
    .io_in_ftqOffset_bits(ftqOffset_bits),
    .io_in_jumpOffset_0(jumpOffset[0]),
    .io_in_jumpOffset_1(jumpOffset[1]),
    .io_in_jumpOffset_2(jumpOffset[2]),
    .io_in_jumpOffset_3(jumpOffset[3]),
    .io_in_jumpOffset_4(jumpOffset[4]),
    .io_in_jumpOffset_5(jumpOffset[5]),
    .io_in_jumpOffset_6(jumpOffset[6]),
    .io_in_jumpOffset_7(jumpOffset[7]),
    .io_in_jumpOffset_8(jumpOffset[8]),
    .io_in_jumpOffset_9(jumpOffset[9]),
    .io_in_jumpOffset_10(jumpOffset[10]),
    .io_in_jumpOffset_11(jumpOffset[11]),
    .io_in_jumpOffset_12(jumpOffset[12]),
    .io_in_jumpOffset_13(jumpOffset[13]),
    .io_in_jumpOffset_14(jumpOffset[14]),
    .io_in_jumpOffset_15(jumpOffset[15]),
    .io_in_target(target),
    .io_in_instrRange_0(instrRange[0]),
    .io_in_instrRange_1(instrRange[1]),
    .io_in_instrRange_2(instrRange[2]),
    .io_in_instrRange_3(instrRange[3]),
    .io_in_instrRange_4(instrRange[4]),
    .io_in_instrRange_5(instrRange[5]),
    .io_in_instrRange_6(instrRange[6]),
    .io_in_instrRange_7(instrRange[7]),
    .io_in_instrRange_8(instrRange[8]),
    .io_in_instrRange_9(instrRange[9]),
    .io_in_instrRange_10(instrRange[10]),
    .io_in_instrRange_11(instrRange[11]),
    .io_in_instrRange_12(instrRange[12]),
    .io_in_instrRange_13(instrRange[13]),
    .io_in_instrRange_14(instrRange[14]),
    .io_in_instrRange_15(instrRange[15]),
    .io_in_instrValid_0(instrValid[0]),
    .io_in_instrValid_1(instrValid[1]),
    .io_in_instrValid_2(instrValid[2]),
    .io_in_instrValid_3(instrValid[3]),
    .io_in_instrValid_4(instrValid[4]),
    .io_in_instrValid_5(instrValid[5]),
    .io_in_instrValid_6(instrValid[6]),
    .io_in_instrValid_7(instrValid[7]),
    .io_in_instrValid_8(instrValid[8]),
    .io_in_instrValid_9(instrValid[9]),
    .io_in_instrValid_10(instrValid[10]),
    .io_in_instrValid_11(instrValid[11]),
    .io_in_instrValid_12(instrValid[12]),
    .io_in_instrValid_13(instrValid[13]),
    .io_in_instrValid_14(instrValid[14]),
    .io_in_instrValid_15(instrValid[15]),
    .io_in_pds_0_isRVC(pds[0].isRVC),
    .io_in_pds_0_brType(pds[0].brType),
    .io_in_pds_0_isRet(pds[0].isRet),
    .io_in_pds_1_isRVC(pds[1].isRVC),
    .io_in_pds_1_brType(pds[1].brType),
    .io_in_pds_1_isRet(pds[1].isRet),
    .io_in_pds_2_isRVC(pds[2].isRVC),
    .io_in_pds_2_brType(pds[2].brType),
    .io_in_pds_2_isRet(pds[2].isRet),
    .io_in_pds_3_isRVC(pds[3].isRVC),
    .io_in_pds_3_brType(pds[3].brType),
    .io_in_pds_3_isRet(pds[3].isRet),
    .io_in_pds_4_isRVC(pds[4].isRVC),
    .io_in_pds_4_brType(pds[4].brType),
    .io_in_pds_4_isRet(pds[4].isRet),
    .io_in_pds_5_isRVC(pds[5].isRVC),
    .io_in_pds_5_brType(pds[5].brType),
    .io_in_pds_5_isRet(pds[5].isRet),
    .io_in_pds_6_isRVC(pds[6].isRVC),
    .io_in_pds_6_brType(pds[6].brType),
    .io_in_pds_6_isRet(pds[6].isRet),
    .io_in_pds_7_isRVC(pds[7].isRVC),
    .io_in_pds_7_brType(pds[7].brType),
    .io_in_pds_7_isRet(pds[7].isRet),
    .io_in_pds_8_isRVC(pds[8].isRVC),
    .io_in_pds_8_brType(pds[8].brType),
    .io_in_pds_8_isRet(pds[8].isRet),
    .io_in_pds_9_isRVC(pds[9].isRVC),
    .io_in_pds_9_brType(pds[9].brType),
    .io_in_pds_9_isRet(pds[9].isRet),
    .io_in_pds_10_isRVC(pds[10].isRVC),
    .io_in_pds_10_brType(pds[10].brType),
    .io_in_pds_10_isRet(pds[10].isRet),
    .io_in_pds_11_isRVC(pds[11].isRVC),
    .io_in_pds_11_brType(pds[11].brType),
    .io_in_pds_11_isRet(pds[11].isRet),
    .io_in_pds_12_isRVC(pds[12].isRVC),
    .io_in_pds_12_brType(pds[12].brType),
    .io_in_pds_12_isRet(pds[12].isRet),
    .io_in_pds_13_isRVC(pds[13].isRVC),
    .io_in_pds_13_brType(pds[13].brType),
    .io_in_pds_13_isRet(pds[13].isRet),
    .io_in_pds_14_isRVC(pds[14].isRVC),
    .io_in_pds_14_brType(pds[14].brType),
    .io_in_pds_14_isRet(pds[14].isRet),
    .io_in_pds_15_isRVC(pds[15].isRVC),
    .io_in_pds_15_brType(pds[15].brType),
    .io_in_pds_15_isRet(pds[15].isRet),
    .io_in_pc_0(pc[0]),
    .io_in_pc_1(pc[1]),
    .io_in_pc_2(pc[2]),
    .io_in_pc_3(pc[3]),
    .io_in_pc_4(pc[4]),
    .io_in_pc_5(pc[5]),
    .io_in_pc_6(pc[6]),
    .io_in_pc_7(pc[7]),
    .io_in_pc_8(pc[8]),
    .io_in_pc_9(pc[9]),
    .io_in_pc_10(pc[10]),
    .io_in_pc_11(pc[11]),
    .io_in_pc_12(pc[12]),
    .io_in_pc_13(pc[13]),
    .io_in_pc_14(pc[14]),
    .io_in_pc_15(pc[15]),
    .io_in_fire_in(fire_in),
    .io_out_stage1Out_fixedRange_0(fixedRange[0]),
    .io_out_stage1Out_fixedRange_1(fixedRange[1]),
    .io_out_stage1Out_fixedRange_2(fixedRange[2]),
    .io_out_stage1Out_fixedRange_3(fixedRange[3]),
    .io_out_stage1Out_fixedRange_4(fixedRange[4]),
    .io_out_stage1Out_fixedRange_5(fixedRange[5]),
    .io_out_stage1Out_fixedRange_6(fixedRange[6]),
    .io_out_stage1Out_fixedRange_7(fixedRange[7]),
    .io_out_stage1Out_fixedRange_8(fixedRange[8]),
    .io_out_stage1Out_fixedRange_9(fixedRange[9]),
    .io_out_stage1Out_fixedRange_10(fixedRange[10]),
    .io_out_stage1Out_fixedRange_11(fixedRange[11]),
    .io_out_stage1Out_fixedRange_12(fixedRange[12]),
    .io_out_stage1Out_fixedRange_13(fixedRange[13]),
    .io_out_stage1Out_fixedRange_14(fixedRange[14]),
    .io_out_stage1Out_fixedRange_15(fixedRange[15]),
    .io_out_stage1Out_fixedTaken_0(fixedTaken[0]),
    .io_out_stage1Out_fixedTaken_1(fixedTaken[1]),
    .io_out_stage1Out_fixedTaken_2(fixedTaken[2]),
    .io_out_stage1Out_fixedTaken_3(fixedTaken[3]),
    .io_out_stage1Out_fixedTaken_4(fixedTaken[4]),
    .io_out_stage1Out_fixedTaken_5(fixedTaken[5]),
    .io_out_stage1Out_fixedTaken_6(fixedTaken[6]),
    .io_out_stage1Out_fixedTaken_7(fixedTaken[7]),
    .io_out_stage1Out_fixedTaken_8(fixedTaken[8]),
    .io_out_stage1Out_fixedTaken_9(fixedTaken[9]),
    .io_out_stage1Out_fixedTaken_10(fixedTaken[10]),
    .io_out_stage1Out_fixedTaken_11(fixedTaken[11]),
    .io_out_stage1Out_fixedTaken_12(fixedTaken[12]),
    .io_out_stage1Out_fixedTaken_13(fixedTaken[13]),
    .io_out_stage1Out_fixedTaken_14(fixedTaken[14]),
    .io_out_stage1Out_fixedTaken_15(fixedTaken[15]),
    .io_out_stage2Out_fixedTarget_0(fixedTarget[0]),
    .io_out_stage2Out_fixedTarget_1(fixedTarget[1]),
    .io_out_stage2Out_fixedTarget_2(fixedTarget[2]),
    .io_out_stage2Out_fixedTarget_3(fixedTarget[3]),
    .io_out_stage2Out_fixedTarget_4(fixedTarget[4]),
    .io_out_stage2Out_fixedTarget_5(fixedTarget[5]),
    .io_out_stage2Out_fixedTarget_6(fixedTarget[6]),
    .io_out_stage2Out_fixedTarget_7(fixedTarget[7]),
    .io_out_stage2Out_fixedTarget_8(fixedTarget[8]),
    .io_out_stage2Out_fixedTarget_9(fixedTarget[9]),
    .io_out_stage2Out_fixedTarget_10(fixedTarget[10]),
    .io_out_stage2Out_fixedTarget_11(fixedTarget[11]),
    .io_out_stage2Out_fixedTarget_12(fixedTarget[12]),
    .io_out_stage2Out_fixedTarget_13(fixedTarget[13]),
    .io_out_stage2Out_fixedTarget_14(fixedTarget[14]),
    .io_out_stage2Out_fixedTarget_15(fixedTarget[15]),
    .io_out_stage2Out_jalTarget_0(jalTarget[0]),
    .io_out_stage2Out_jalTarget_1(jalTarget[1]),
    .io_out_stage2Out_jalTarget_2(jalTarget[2]),
    .io_out_stage2Out_jalTarget_3(jalTarget[3]),
    .io_out_stage2Out_jalTarget_4(jalTarget[4]),
    .io_out_stage2Out_jalTarget_5(jalTarget[5]),
    .io_out_stage2Out_jalTarget_6(jalTarget[6]),
    .io_out_stage2Out_jalTarget_7(jalTarget[7]),
    .io_out_stage2Out_jalTarget_8(jalTarget[8]),
    .io_out_stage2Out_jalTarget_9(jalTarget[9]),
    .io_out_stage2Out_jalTarget_10(jalTarget[10]),
    .io_out_stage2Out_jalTarget_11(jalTarget[11]),
    .io_out_stage2Out_jalTarget_12(jalTarget[12]),
    .io_out_stage2Out_jalTarget_13(jalTarget[13]),
    .io_out_stage2Out_jalTarget_14(jalTarget[14]),
    .io_out_stage2Out_jalTarget_15(jalTarget[15]),
    .io_out_stage2Out_fixedMissPred_0(fixedMissPred[0]),
    .io_out_stage2Out_fixedMissPred_1(fixedMissPred[1]),
    .io_out_stage2Out_fixedMissPred_2(fixedMissPred[2]),
    .io_out_stage2Out_fixedMissPred_3(fixedMissPred[3]),
    .io_out_stage2Out_fixedMissPred_4(fixedMissPred[4]),
    .io_out_stage2Out_fixedMissPred_5(fixedMissPred[5]),
    .io_out_stage2Out_fixedMissPred_6(fixedMissPred[6]),
    .io_out_stage2Out_fixedMissPred_7(fixedMissPred[7]),
    .io_out_stage2Out_fixedMissPred_8(fixedMissPred[8]),
    .io_out_stage2Out_fixedMissPred_9(fixedMissPred[9]),
    .io_out_stage2Out_fixedMissPred_10(fixedMissPred[10]),
    .io_out_stage2Out_fixedMissPred_11(fixedMissPred[11]),
    .io_out_stage2Out_fixedMissPred_12(fixedMissPred[12]),
    .io_out_stage2Out_fixedMissPred_13(fixedMissPred[13]),
    .io_out_stage2Out_fixedMissPred_14(fixedMissPred[14]),
    .io_out_stage2Out_fixedMissPred_15(fixedMissPred[15]),
    .io_out_stage2Out_faultType_0_value(faultType[0]),
    .io_out_stage2Out_faultType_1_value(faultType[1]),
    .io_out_stage2Out_faultType_2_value(faultType[2]),
    .io_out_stage2Out_faultType_3_value(faultType[3]),
    .io_out_stage2Out_faultType_4_value(faultType[4]),
    .io_out_stage2Out_faultType_5_value(faultType[5]),
    .io_out_stage2Out_faultType_6_value(faultType[6]),
    .io_out_stage2Out_faultType_7_value(faultType[7]),
    .io_out_stage2Out_faultType_8_value(faultType[8]),
    .io_out_stage2Out_faultType_9_value(faultType[9]),
    .io_out_stage2Out_faultType_10_value(faultType[10]),
    .io_out_stage2Out_faultType_11_value(faultType[11]),
    .io_out_stage2Out_faultType_12_value(faultType[12]),
    .io_out_stage2Out_faultType_13_value(faultType[13]),
    .io_out_stage2Out_faultType_14_value(faultType[14]),
    .io_out_stage2Out_faultType_15_value(faultType[15])
  );
endmodule

// ---- xs_newifu_frontendtrigger：golden FrontendTrigger（工程无独立重写核，保留 golden） ----
module xs_newifu_frontendtrigger
  import xs_newifu_pkg::*;
(
  input  wire        clock,
  input  wire        reset,
  input  wire        tUpdate_valid,
  input  wire [1:0]  tUpdate_addr,
  input  wire [1:0]  tUpdate_matchType,
  input  wire        tUpdate_select,
  input  wire [3:0]  tUpdate_action,
  input  wire        tUpdate_chain,
  input  wire [63:0] tUpdate_tdata2,
  input  wire [3:0]  tEnableVec,
  input  wire        debugMode,
  input  wire        triggerCanRaiseBpExp,
  input  wire [PredictWidth-1:0][VAddrBits-1:0] pc,
  output wire [PredictWidth-1:0][3:0] triggered
);
  FrontendTrigger u (
    .clock(clock),
    .reset(reset),
    .io_frontendTrigger_tUpdate_valid(tUpdate_valid),
    .io_frontendTrigger_tUpdate_bits_addr(tUpdate_addr),
    .io_frontendTrigger_tUpdate_bits_tdata_matchType(tUpdate_matchType),
    .io_frontendTrigger_tUpdate_bits_tdata_select(tUpdate_select),
    .io_frontendTrigger_tUpdate_bits_tdata_action(tUpdate_action),
    .io_frontendTrigger_tUpdate_bits_tdata_chain(tUpdate_chain),
    .io_frontendTrigger_tUpdate_bits_tdata_tdata2(tUpdate_tdata2),
    .io_frontendTrigger_tEnableVec_0(tEnableVec[0]),
    .io_frontendTrigger_tEnableVec_1(tEnableVec[1]),
    .io_frontendTrigger_tEnableVec_2(tEnableVec[2]),
    .io_frontendTrigger_tEnableVec_3(tEnableVec[3]),
    .io_frontendTrigger_debugMode(debugMode),
    .io_frontendTrigger_triggerCanRaiseBpExp(triggerCanRaiseBpExp),
    .io_triggered_0(triggered[0]),
    .io_triggered_1(triggered[1]),
    .io_triggered_2(triggered[2]),
    .io_triggered_3(triggered[3]),
    .io_triggered_4(triggered[4]),
    .io_triggered_5(triggered[5]),
    .io_triggered_6(triggered[6]),
    .io_triggered_7(triggered[7]),
    .io_triggered_8(triggered[8]),
    .io_triggered_9(triggered[9]),
    .io_triggered_10(triggered[10]),
    .io_triggered_11(triggered[11]),
    .io_triggered_12(triggered[12]),
    .io_triggered_13(triggered[13]),
    .io_triggered_14(triggered[14]),
    .io_triggered_15(triggered[15]),
    .io_pc_0(pc[0]),
    .io_pc_1(pc[1]),
    .io_pc_2(pc[2]),
    .io_pc_3(pc[3]),
    .io_pc_4(pc[4]),
    .io_pc_5(pc[5]),
    .io_pc_6(pc[6]),
    .io_pc_7(pc[7]),
    .io_pc_8(pc[8]),
    .io_pc_9(pc[9]),
    .io_pc_10(pc[10]),
    .io_pc_11(pc[11]),
    .io_pc_12(pc[12]),
    .io_pc_13(pc[13]),
    .io_pc_14(pc[14]),
    .io_pc_15(pc[15])
  );
endmodule
