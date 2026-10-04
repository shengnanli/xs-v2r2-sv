// CSR —— CSR 功能单元外壳（把 CSR 指令 uop 翻译成对 NewCSR 的读写/特权请求）
// 设计意图：src/main/scala/xiangshan/backend/fu/wrapper/CSR.scala（class CSR，FuncUnit）
//
// 子模块（实例名同 golden）：
//   csrMod        NewCSR      CSR 寄存器堆 + 特权态机（本 lane 重写）
//   trapInstMod   TrapInstMod 记录引发异常的指令编码（给 xtval/xtinst）
//   trapTvalMod   TrapTvalMod 记录取指地址异常的 tval
//   satpFlushMod  SatpFlushMod 写 satp 后第一条取指异常用的"旧"特权态 / 旧 satp.MODE
//   imsic         IMSIC_WRAP  AIA 中断控制器（间接 CSR mireg/sireg/vsireg 的后端）
//
// 本层逻辑：
//   1. uop 解码：fuOpType 区分 CSR 访问（读/写/置位/清零，寄存器或立即数源）与系统指令
//      （ecall/ebreak/xret，按 imm[11:0] 即指令 funct12 区分）；
//   2. 写数据：读-改-写在本层算好（用 NewCSR 的 regOut = 寄存器字段原值），在请求被接收
//      那拍锁进 wdata_q —— NewCSR 的写发生在下一拍，用的就是这个锁存值；
//   3. ecall/ebreak 的异常位、xret 的重定向在请求被接收那拍锁存，输出期间保持；
//   4. 重定向冲刷：本条 CSR 指令（或上一条被接收的）在 flush 范围内时通知 NewCSR 丢弃。
//
// fuOpType 编码（CSROpType）：bit4=系统指令(jmp)；bit3=CSR 访问；bit2=立即数源；
//   [1:0]：01=读写(wrt) 10=置位(set) 11=清零(clr)。即 9=wrt A=set B=clr D=wrti E=seti F=clri 10=jmp。
module CSR(
// BEGIN GENERATED(csr-ports) —— 由 scripts/gen_newcsr.py 从 golden 机械产出，勿手改
  input           clock,
  input           reset,
  input           io_flush_valid,
  input           io_flush_bits_robIdx_flag,
  input  [7:0]    io_flush_bits_robIdx_value,
  input           io_flush_bits_ftqIdx_flag,
  input  [5:0]    io_flush_bits_ftqIdx_value,
  input  [3:0]    io_flush_bits_ftqOffset,
  input           io_flush_bits_level,
  input           io_flush_bits_cfiUpdate_backendIGPF,
  input           io_flush_bits_cfiUpdate_backendIPF,
  input           io_flush_bits_cfiUpdate_backendIAF,
  input  [63:0]   io_flush_bits_fullTarget,
  output          io_in_ready,
  input           io_in_valid,
  input  [8:0]    io_in_bits_ctrl_fuOpType,
  input           io_in_bits_ctrl_robIdx_flag,
  input  [7:0]    io_in_bits_ctrl_robIdx_value,
  input  [7:0]    io_in_bits_ctrl_pdest,
  input           io_in_bits_ctrl_rfWen,
  input           io_in_bits_ctrl_preDecode_valid,
  input           io_in_bits_ctrl_preDecode_isRVC,
  input  [1:0]    io_in_bits_ctrl_preDecode_brType,
  input           io_in_bits_ctrl_preDecode_isCall,
  input           io_in_bits_ctrl_preDecode_isRet,
  input           io_in_bits_ctrl_ftqIdx_flag,
  input  [5:0]    io_in_bits_ctrl_ftqIdx_value,
  input  [3:0]    io_in_bits_ctrl_ftqOffset,
  input  [63:0]   io_in_bits_data_src_0,
  input  [63:0]   io_in_bits_data_imm,
  input           io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]   io_in_bits_perfDebugInfo_renameTime,
  input  [63:0]   io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0]   io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0]   io_in_bits_perfDebugInfo_selectTime,
  input  [63:0]   io_in_bits_perfDebugInfo_issueTime,
  input  [63:0]   io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0]   io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]   io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]   io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]   io_in_bits_debug_seqNum_seqNum,
  input  [7:0]    io_in_bits_debug_seqNum_uopIdx,
  input           io_out_ready,
  output          io_out_valid,
  output          io_out_bits_ctrl_robIdx_flag,
  output [7:0]    io_out_bits_ctrl_robIdx_value,
  output [7:0]    io_out_bits_ctrl_pdest,
  output          io_out_bits_ctrl_rfWen,
  output          io_out_bits_ctrl_exceptionVec_2,
  output          io_out_bits_ctrl_exceptionVec_3,
  output          io_out_bits_ctrl_exceptionVec_8,
  output          io_out_bits_ctrl_exceptionVec_9,
  output          io_out_bits_ctrl_exceptionVec_10,
  output          io_out_bits_ctrl_exceptionVec_11,
  output          io_out_bits_ctrl_exceptionVec_22,
  output          io_out_bits_ctrl_flushPipe,
  output          io_out_bits_ctrl_satpFlushPipe,
  output          io_out_bits_ctrl_preDecode_valid,
  output          io_out_bits_ctrl_preDecode_isRVC,
  output [1:0]    io_out_bits_ctrl_preDecode_brType,
  output          io_out_bits_ctrl_preDecode_isCall,
  output          io_out_bits_ctrl_preDecode_isRet,
  output [63:0]   io_out_bits_res_data,
  output          io_out_bits_res_redirect_valid,
  output          io_out_bits_res_redirect_bits_isRVC,
  output          io_out_bits_res_redirect_bits_robIdx_flag,
  output [7:0]    io_out_bits_res_redirect_bits_robIdx_value,
  output          io_out_bits_res_redirect_bits_ftqIdx_flag,
  output [5:0]    io_out_bits_res_redirect_bits_ftqIdx_value,
  output [3:0]    io_out_bits_res_redirect_bits_ftqOffset,
  output          io_out_bits_res_redirect_bits_level,
  output          io_out_bits_res_redirect_bits_interrupt,
  output [49:0]   io_out_bits_res_redirect_bits_cfiUpdate_pc,
  output          io_out_bits_res_redirect_bits_cfiUpdate_pd_valid,
  output          io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC,
  output [1:0]    io_out_bits_res_redirect_bits_cfiUpdate_pd_brType,
  output          io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall,
  output          io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet,
  output [3:0]    io_out_bits_res_redirect_bits_cfiUpdate_ssp,
  output [2:0]    io_out_bits_res_redirect_bits_cfiUpdate_sctr,
  output          io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag,
  output [4:0]    io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value,
  output          io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag,
  output [4:0]    io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value,
  output          io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag,
  output [4:0]    io_out_bits_res_redirect_bits_cfiUpdate_NOS_value,
  output [49:0]   io_out_bits_res_redirect_bits_cfiUpdate_topAddr,
  output [10:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist,
  output [10:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist,
  output [6:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist,
  output [7:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist,
  output [8:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist,
  output [3:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist,
  output [7:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist,
  output [8:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist,
  output [6:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist,
  output [7:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist,
  output [6:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist,
  output [8:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist,
  output [6:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist,
  output [7:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist,
  output [7:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist,
  output [7:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist,
  output [10:0]   io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist,
  output [7:0]    io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2,
  output          io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3,
  output [2:0]    io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH,
  output [3:0]    io_out_bits_res_redirect_bits_cfiUpdate_ghr,
  output          io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag,
  output [7:0]    io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value,
  output [9:0]    io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0,
  output [9:0]    io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1,
  output          io_out_bits_res_redirect_bits_cfiUpdate_br_hit,
  output          io_out_bits_res_redirect_bits_cfiUpdate_jr_hit,
  output          io_out_bits_res_redirect_bits_cfiUpdate_sc_hit,
  output          io_out_bits_res_redirect_bits_cfiUpdate_predTaken,
  output [49:0]   io_out_bits_res_redirect_bits_cfiUpdate_target,
  output          io_out_bits_res_redirect_bits_cfiUpdate_taken,
  output          io_out_bits_res_redirect_bits_cfiUpdate_isMisPred,
  output [1:0]    io_out_bits_res_redirect_bits_cfiUpdate_shift,
  output          io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist,
  output          io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF,
  output          io_out_bits_res_redirect_bits_cfiUpdate_backendIPF,
  output          io_out_bits_res_redirect_bits_cfiUpdate_backendIAF,
  output [63:0]   io_out_bits_res_redirect_bits_fullTarget,
  output          io_out_bits_res_redirect_bits_satpFlush,
  output          io_out_bits_res_redirect_bits_isVlsException,
  output          io_out_bits_res_redirect_bits_stFtqIdx_flag,
  output [5:0]    io_out_bits_res_redirect_bits_stFtqIdx_value,
  output [3:0]    io_out_bits_res_redirect_bits_stFtqOffset,
  output [63:0]   io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id,
  output          io_out_bits_res_redirect_bits_debugIsCtrl,
  output          io_out_bits_res_redirect_bits_debugIsMemVio,
  output          io_out_bits_perfDebugInfo_eliminatedMove,
  output [63:0]   io_out_bits_perfDebugInfo_renameTime,
  output [63:0]   io_out_bits_perfDebugInfo_dispatchTime,
  output [63:0]   io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0]   io_out_bits_perfDebugInfo_selectTime,
  output [63:0]   io_out_bits_perfDebugInfo_issueTime,
  output [63:0]   io_out_bits_perfDebugInfo_writebackTime,
  output [63:0]   io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]   io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]   io_out_bits_perfDebugInfo_tlbRespTime,
  output [55:0]   io_out_bits_debug_seqNum_seqNum,
  output [7:0]    io_out_bits_debug_seqNum_uopIdx,
  input  [7:0]    io_csrin_hartId,
  input           io_csrin_msiInfo_valid,
  input  [11:0]   io_csrin_msiInfo_bits,
  input           io_csrin_criticalErrorState,
  input           io_csrin_clintTime_valid,
  input  [63:0]   io_csrin_clintTime_bits,
  input           io_csrin_l2FlushDone,
  input           io_csrin_trapInstInfo_valid,
  input  [31:0]   io_csrin_trapInstInfo_bits_instr,
  input           io_csrin_trapInstInfo_bits_ftqPtr_flag,
  input  [5:0]    io_csrin_trapInstInfo_bits_ftqPtr_value,
  input  [3:0]    io_csrin_trapInstInfo_bits_ftqOffset,
  input           io_csrin_fromVecExcpMod_busy,
  input  [5:0]    io_csrio_perf_perfEventsFrontend_0_value,
  input  [5:0]    io_csrio_perf_perfEventsFrontend_1_value,
  input  [5:0]    io_csrio_perf_perfEventsFrontend_2_value,
  input  [5:0]    io_csrio_perf_perfEventsFrontend_3_value,
  input  [5:0]    io_csrio_perf_perfEventsFrontend_4_value,
  input  [5:0]    io_csrio_perf_perfEventsFrontend_5_value,
  input  [5:0]    io_csrio_perf_perfEventsFrontend_6_value,
  input  [5:0]    io_csrio_perf_perfEventsFrontend_7_value,
  input  [5:0]    io_csrio_perf_perfEventsBackend_0_value,
  input  [5:0]    io_csrio_perf_perfEventsBackend_1_value,
  input  [5:0]    io_csrio_perf_perfEventsBackend_2_value,
  input  [5:0]    io_csrio_perf_perfEventsBackend_3_value,
  input  [5:0]    io_csrio_perf_perfEventsBackend_4_value,
  input  [5:0]    io_csrio_perf_perfEventsBackend_5_value,
  input  [5:0]    io_csrio_perf_perfEventsBackend_6_value,
  input  [5:0]    io_csrio_perf_perfEventsBackend_7_value,
  input  [5:0]    io_csrio_perf_perfEventsLsu_0_value,
  input  [5:0]    io_csrio_perf_perfEventsLsu_1_value,
  input  [5:0]    io_csrio_perf_perfEventsLsu_2_value,
  input  [5:0]    io_csrio_perf_perfEventsLsu_3_value,
  input  [5:0]    io_csrio_perf_perfEventsLsu_4_value,
  input  [5:0]    io_csrio_perf_perfEventsLsu_5_value,
  input  [5:0]    io_csrio_perf_perfEventsLsu_6_value,
  input  [5:0]    io_csrio_perf_perfEventsLsu_7_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_0_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_1_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_2_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_3_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_4_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_5_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_6_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_7_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_8_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_9_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_10_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_11_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_12_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_13_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_14_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_15_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_16_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_17_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_18_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_19_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_20_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_21_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_22_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_23_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_24_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_25_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_26_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_27_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_28_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_29_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_30_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_31_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_32_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_33_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_34_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_35_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_36_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_37_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_38_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_39_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_40_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_41_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_42_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_43_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_44_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_45_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_46_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_47_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_48_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_49_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_50_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_51_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_52_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_53_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_54_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_55_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_56_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_57_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_58_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_59_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_60_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_61_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_62_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_63_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_64_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_65_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_66_value,
  input  [5:0]    io_csrio_perf_perfEventsHc_67_value,
  input  [6:0]    io_csrio_perf_retiredInstr,
  output          io_csrio_criticalErrorState,
  output          io_csrio_isPerfCnt,
  input           io_csrio_fpu_fflags_valid,
  input  [4:0]    io_csrio_fpu_fflags_bits,
  input           io_csrio_fpu_dirty_fs,
  output [2:0]    io_csrio_fpu_frm,
  output [63:0]   io_csrio_vpu_vstart,
  output [1:0]    io_csrio_vpu_vxrm,
  input  [63:0]   io_csrio_vpu_vl,
  input           io_csrio_vpu_set_vstart_valid,
  input  [63:0]   io_csrio_vpu_set_vstart_bits,
  input           io_csrio_vpu_set_vtype_valid,
  input  [63:0]   io_csrio_vpu_set_vtype_bits,
  input           io_csrio_vpu_set_vxsat_valid,
  input           io_csrio_vpu_set_vxsat_bits,
  input           io_csrio_vpu_dirty_vs,
  input           io_csrio_exception_valid,
  input  [49:0]   io_csrio_exception_bits_pc,
  input  [31:0]   io_csrio_exception_bits_instr,
  input           io_csrio_exception_bits_exceptionVec_0,
  input           io_csrio_exception_bits_exceptionVec_1,
  input           io_csrio_exception_bits_exceptionVec_2,
  input           io_csrio_exception_bits_exceptionVec_3,
  input           io_csrio_exception_bits_exceptionVec_4,
  input           io_csrio_exception_bits_exceptionVec_5,
  input           io_csrio_exception_bits_exceptionVec_6,
  input           io_csrio_exception_bits_exceptionVec_7,
  input           io_csrio_exception_bits_exceptionVec_8,
  input           io_csrio_exception_bits_exceptionVec_9,
  input           io_csrio_exception_bits_exceptionVec_10,
  input           io_csrio_exception_bits_exceptionVec_11,
  input           io_csrio_exception_bits_exceptionVec_12,
  input           io_csrio_exception_bits_exceptionVec_13,
  input           io_csrio_exception_bits_exceptionVec_14,
  input           io_csrio_exception_bits_exceptionVec_15,
  input           io_csrio_exception_bits_exceptionVec_16,
  input           io_csrio_exception_bits_exceptionVec_17,
  input           io_csrio_exception_bits_exceptionVec_18,
  input           io_csrio_exception_bits_exceptionVec_19,
  input           io_csrio_exception_bits_exceptionVec_20,
  input           io_csrio_exception_bits_exceptionVec_21,
  input           io_csrio_exception_bits_exceptionVec_22,
  input           io_csrio_exception_bits_exceptionVec_23,
  input           io_csrio_exception_bits_isPcBkpt,
  input           io_csrio_exception_bits_isFetchMalAddr,
  input           io_csrio_exception_bits_satpFlushFirstFetchFault,
  input  [63:0]   io_csrio_exception_bits_gpaddr,
  input           io_csrio_exception_bits_singleStep,
  input           io_csrio_exception_bits_crossPageIPFFix,
  input           io_csrio_exception_bits_isInterrupt,
  input           io_csrio_exception_bits_isHls,
  input  [3:0]    io_csrio_exception_bits_trigger,
  input           io_csrio_exception_bits_isForVSnonLeafPTE,
  input           io_csrio_robDeqPtr_flag,
  input  [7:0]    io_csrio_robDeqPtr_value,
  output [63:0]   io_csrio_trapTarget_pc,
  output          io_csrio_trapTarget_raiseIPF,
  output          io_csrio_trapTarget_raiseIAF,
  output          io_csrio_trapTarget_raiseIGPF,
  output          io_csrio_interrupt,
  output          io_csrio_wfi_event,
  output [63:0]   io_csrio_traceCSR_cause,
  output [49:0]   io_csrio_traceCSR_tval,
  output [63:0]   io_csrio_traceCSR_mstatus,
  output [2:0]    io_csrio_traceCSR_lastPriv,
  output [2:0]    io_csrio_traceCSR_currentPriv,
  input  [63:0]   io_csrio_memExceptionVAddr,
  input  [63:0]   io_csrio_memExceptionGPAddr,
  input           io_csrio_memExceptionIsForVSnonLeafPTE,
  input           io_csrio_externalInterrupt_mtip,
  input           io_csrio_externalInterrupt_msip,
  input           io_csrio_externalInterrupt_meip,
  input           io_csrio_externalInterrupt_seip,
  input           io_csrio_externalInterrupt_debug,
  input           io_csrio_externalInterrupt_nmi_nmi_31,
  input           io_csrio_externalInterrupt_nmi_nmi_43,
  output [3:0]    io_csrio_tlb_satp_mode,
  output [15:0]   io_csrio_tlb_satp_asid,
  output [43:0]   io_csrio_tlb_satp_ppn,
  output          io_csrio_tlb_satp_changed,
  output [3:0]    io_csrio_tlb_vsatp_mode,
  output [15:0]   io_csrio_tlb_vsatp_asid,
  output [43:0]   io_csrio_tlb_vsatp_ppn,
  output          io_csrio_tlb_vsatp_changed,
  output [3:0]    io_csrio_tlb_hgatp_mode,
  output [15:0]   io_csrio_tlb_hgatp_vmid,
  output [43:0]   io_csrio_tlb_hgatp_ppn,
  output          io_csrio_tlb_hgatp_changed,
  output          io_csrio_tlb_mbmc_BME,
  output          io_csrio_tlb_mbmc_CMODE,
  output          io_csrio_tlb_mbmc_BCLEAR,
  output [57:0]   io_csrio_tlb_mbmc_BMA,
  output          io_csrio_tlb_priv_mxr,
  output          io_csrio_tlb_priv_sum,
  output          io_csrio_tlb_priv_vmxr,
  output          io_csrio_tlb_priv_vsum,
  output          io_csrio_tlb_priv_virt,
  output          io_csrio_tlb_priv_virt_changed,
  output          io_csrio_tlb_priv_spvp,
  output [1:0]    io_csrio_tlb_priv_imode,
  output [1:0]    io_csrio_tlb_priv_dmode,
  output          io_csrio_tlb_priv_debug,
  output          io_csrio_tlb_mPBMTE,
  output          io_csrio_tlb_hPBMTE,
  output [1:0]    io_csrio_tlb_pmm_mseccfg,
  output [1:0]    io_csrio_tlb_pmm_menvcfg,
  output [1:0]    io_csrio_tlb_pmm_henvcfg,
  output [1:0]    io_csrio_tlb_pmm_hstatus,
  output [1:0]    io_csrio_tlb_pmm_senvcfg,
  output          io_csrio_customCtrl_pf_ctrl_l1I_pf_enable,
  output          io_csrio_customCtrl_pf_ctrl_l2_pf_enable,
  output          io_csrio_customCtrl_pf_ctrl_l1D_pf_enable,
  output          io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit,
  output          io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt,
  output          io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht,
  output [3:0]    io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold,
  output [5:0]    io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride,
  output          io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride,
  output          io_csrio_customCtrl_pf_ctrl_l2_pf_store_only,
  output          io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable,
  output          io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable,
  output          io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable,
  output [9:0]    io_csrio_customCtrl_pf_ctrl_l2_pf_delay_latency,
  output [4:0]    io_csrio_customCtrl_lvpred_timeout,
  output          io_csrio_customCtrl_bp_ctrl_ubtb_enable,
  output          io_csrio_customCtrl_bp_ctrl_btb_enable,
  output          io_csrio_customCtrl_bp_ctrl_tage_enable,
  output          io_csrio_customCtrl_bp_ctrl_sc_enable,
  output          io_csrio_customCtrl_bp_ctrl_ras_enable,
  output [21:0]   io_csrio_customCtrl_sbuffer_timeout,
  output          io_csrio_customCtrl_ldld_vio_check_enable,
  output          io_csrio_customCtrl_cache_error_enable,
  output          io_csrio_customCtrl_uncache_write_outstanding_enable,
  output          io_csrio_customCtrl_hd_misalign_st_enable,
  output          io_csrio_customCtrl_hd_misalign_ld_enable,
  output          io_csrio_customCtrl_power_down_enable,
  output          io_csrio_customCtrl_flush_l2_enable,
  output          io_csrio_customCtrl_fusion_enable,
  output          io_csrio_customCtrl_wfi_enable,
  output          io_csrio_customCtrl_distribute_csr_w_valid,
  output [11:0]   io_csrio_customCtrl_distribute_csr_w_bits_addr,
  output [63:0]   io_csrio_customCtrl_distribute_csr_w_bits_data,
  output          io_csrio_customCtrl_singlestep,
  output          io_csrio_customCtrl_frontend_trigger_tUpdate_valid,
  output [1:0]    io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr,
  output [1:0]    io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType,
  output          io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select,
  output [3:0]    io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action,
  output          io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain,
  output [63:0]   io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2,
  output          io_csrio_customCtrl_frontend_trigger_tEnableVec_0,
  output          io_csrio_customCtrl_frontend_trigger_tEnableVec_1,
  output          io_csrio_customCtrl_frontend_trigger_tEnableVec_2,
  output          io_csrio_customCtrl_frontend_trigger_tEnableVec_3,
  output          io_csrio_customCtrl_frontend_trigger_debugMode,
  output          io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp,
  output          io_csrio_customCtrl_mem_trigger_tUpdate_valid,
  output [1:0]    io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr,
  output [1:0]    io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType,
  output          io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select,
  output [3:0]    io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action,
  output          io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain,
  output          io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store,
  output          io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load,
  output [63:0]   io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2,
  output          io_csrio_customCtrl_mem_trigger_tEnableVec_0,
  output          io_csrio_customCtrl_mem_trigger_tEnableVec_1,
  output          io_csrio_customCtrl_mem_trigger_tEnableVec_2,
  output          io_csrio_customCtrl_mem_trigger_tEnableVec_3,
  output          io_csrio_customCtrl_mem_trigger_debugMode,
  output          io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp,
  output          io_csrio_customCtrl_fsIsOff,
  output          io_csrio_instrAddrTransType_bare,
  output          io_csrio_instrAddrTransType_sv39,
  output          io_csrio_instrAddrTransType_sv39x4,
  output          io_csrio_instrAddrTransType_sv48,
  output          io_csrio_instrAddrTransType_sv48x4,
  output          io_csrio_msiAck,
  output          io_csrToDecode_illegalInst_sfenceVMA,
  output          io_csrToDecode_illegalInst_sfencePart,
  output          io_csrToDecode_illegalInst_hfenceGVMA,
  output          io_csrToDecode_illegalInst_hfenceVVMA,
  output          io_csrToDecode_illegalInst_hlsv,
  output          io_csrToDecode_illegalInst_fsIsOff,
  output          io_csrToDecode_illegalInst_vsIsOff,
  output          io_csrToDecode_illegalInst_wfi,
  output          io_csrToDecode_illegalInst_wrs_nto,
  output          io_csrToDecode_illegalInst_frm,
  output          io_csrToDecode_illegalInst_cboZ,
  output          io_csrToDecode_illegalInst_cboCF,
  output          io_csrToDecode_illegalInst_cboI,
  output          io_csrToDecode_virtualInst_sfenceVMA,
  output          io_csrToDecode_virtualInst_sfencePart,
  output          io_csrToDecode_virtualInst_hfence,
  output          io_csrToDecode_virtualInst_hlsv,
  output          io_csrToDecode_virtualInst_wfi,
  output          io_csrToDecode_virtualInst_wrs_nto,
  output          io_csrToDecode_virtualInst_cboZ,
  output          io_csrToDecode_virtualInst_cboCF,
  output          io_csrToDecode_virtualInst_cboI,
  output          io_csrToDecode_special_cboI2F,
  output          io_error_0,
  output [172:0]  gatewayIn_packed_29_bore,
  output [9:0]    gatewayIn_packed_30_bore,
  output [1159:0] gatewayIn_packed_31_bore,
  output [264:0]  gatewayIn_packed_32_bore,
  output [199:0]  gatewayIn_packed_33_bore,
  output [455:0]  gatewayIn_packed_34_bore,
  output [71:0]   gatewayIn_packed_35_bore,
  output [1095:0] gatewayIn_packed_36_bore,
  output [18:0]   gatewayIn_packed_37_bore,
  output [72:0]   gatewayIn_packed_38_bore,
  output [264:0]  gatewayIn_packed_39_bore,
  output [9:0]    gatewayIn_packed_40_bore
// END GENERATED(csr-ports)
);

  // 子模块输出线（GENERATED）
// BEGIN GENERATED(csr-childnets) —— 由 scripts/gen_newcsr.py 从 golden 机械产出，勿手改
  // csrMod
  wire           csrMod_io_in_ready;
  wire           csrMod_io_out_valid;
  wire           csrMod_io_out_bits_EX_II;
  wire           csrMod_io_out_bits_EX_VI;
  wire           csrMod_io_out_bits_targetPcUpdate;
  wire [63:0]    csrMod_io_out_bits_targetPc_pc;
  wire           csrMod_io_out_bits_targetPc_raiseIPF;
  wire           csrMod_io_out_bits_targetPc_raiseIAF;
  wire           csrMod_io_out_bits_targetPc_raiseIGPF;
  wire [63:0]    csrMod_io_out_bits_regOut;
  wire           csrMod_io_out_bits_isPerfCnt;
  wire [1:0]     csrMod_io_status_privState_PRVM;
  wire           csrMod_io_status_privState_V;
  wire           csrMod_io_status_satp_valid;
  wire [3:0]     csrMod_io_status_satp_bits;
  wire           csrMod_io_status_vsatp_valid;
  wire [3:0]     csrMod_io_status_vsatp_bits;
  wire [6:0]     csrMod_io_status_vecState_vstart;
  wire [13:0]    csrMod_io_tlb_hgatp_VMID;
  wire           csrMod_io_tlb_dvirt;
  wire           csrMod_io_toDecode_illegalInst_fsIsOff;
  wire           csrMod_toAIA_addr_valid;
  wire [11:0]    csrMod_toAIA_addr_bits_addr;
  wire           csrMod_toAIA_addr_bits_v;
  wire [1:0]     csrMod_toAIA_addr_bits_prvm;
  wire [5:0]     csrMod_toAIA_vgein;
  wire           csrMod_toAIA_wdata_valid;
  wire [1:0]     csrMod_toAIA_wdata_bits_op;
  wire [63:0]    csrMod_toAIA_wdata_bits_data;
  wire           csrMod_toAIA_mClaim;
  wire           csrMod_toAIA_sClaim;
  wire           csrMod_toAIA_vsClaim;
  wire           csrMod_io_error_0;
  // trapInstMod
  wire           trapInstMod_io_currentTrapInst_valid;
  wire [31:0]    trapInstMod_io_currentTrapInst_bits;
  // trapTvalMod
  wire [63:0]    trapTvalMod_io_tval;
  // satpFlushMod
  wire [1:0]     satpFlushMod_out_oldPrivState_PRVM;
  wire           satpFlushMod_out_oldPrivState_V;
  wire [3:0]     satpFlushMod_out_oldSatpMode;
  wire [3:0]     satpFlushMod_out_oldVsatpMode;
  // imsic
  wire           imsic_toCSR_rdata_valid;
  wire [63:0]    imsic_toCSR_rdata_bits;
  wire           imsic_toCSR_illegal;
  wire [8:0]     imsic_toCSR_pendings;
  wire [31:0]    imsic_toCSR_topeis_0;
  wire [31:0]    imsic_toCSR_topeis_1;
  wire [31:0]    imsic_toCSR_topeis_2;
// END GENERATED(csr-childnets)

  // ==========================================================================
  // 1. uop 解码
  // ==========================================================================
  wire [8:0]  func      = io_in_bits_ctrl_fuOpType;
  wire [11:0] funct12   = io_in_bits_data_imm[11:0];       // CSR 地址 / 系统指令 funct12
  wire [4:0]  rs1_imm5  = io_in_bits_data_imm[16:12];      // rs1 号，或 csr*i 的 5 位立即数
  wire [4:0]  rd        = io_in_bits_data_imm[21:17];
  wire [63:0] csri      = {59'h0, rs1_imm5};

  wire is_system = func[4];
  wire is_ecall  = is_system & funct12 == 12'h000;
  wire is_ebreak = is_system & funct12 == 12'h001;
  wire is_mnret  = is_system & funct12 == 12'h702;
  wire is_mret   = is_system & funct12 == 12'h302;
  wire is_sret   = is_system & funct12 == 12'h102;
  wire is_dret   = is_system & funct12 == 12'h7B2;

  // 读写请求：csrrw 一定写、rd!=0 才读；csrrs/csrrc 一定读、rs1!=0 才写
  wire is_csrrw    = func[3] & func[1:0] == 2'h1;
  wire is_csrrs_rc = func[3] & func[1];
  wire csr_wen = io_in_valid & (is_csrrw | is_csrrs_rc & (|rs1_imm5));
  wire csr_ren = io_in_valid & (is_csrrw & (|rd) | is_csrrs_rc);
  wire [63:0] csr_src = func[2] ? csri : io_in_bits_data_src_0;

  wire in_fire = csrMod_io_in_ready & io_in_valid;

  // ==========================================================================
  // 2. 写数据（读-改-写），在 in_fire 拍锁存
  // ==========================================================================
  wire [63:0] reg_out = csrMod_io_out_bits_regOut;
  wire [63:0] wdata_now =
      (func == 9'h9 ? io_in_bits_data_src_0            : 64'h0)   // csrrw
    | (func == 9'hA ? reg_out | io_in_bits_data_src_0  : 64'h0)   // csrrs
    | (func == 9'hB ? reg_out & ~io_in_bits_data_src_0 : 64'h0)   // csrrc
    | (func == 9'hD ? csri                             : 64'h0)   // csrrwi
    | (func == 9'hE ? reg_out | csri                   : 64'h0)   // csrrsi
    | (func == 9'hF ? reg_out & ~csri                  : 64'h0);  // csrrci

  logic [11:0] waddr_q;
  logic [63:0] wdata_q;
  // ecall/ebreak 异常位（DataHoldBypass：接收那拍直通，之后保持）
  logic        ex_bp_q, ex_mcall_q, ex_hscall_q, ex_vscall_q, ex_ucall_q;
  logic        xret_redirect_q;     // 本条是 xret，输出时要发重定向
  logic        not_jmp_q;           // 本条不是系统指令（isPerfCnt 只对 CSR 访问有意义）

  wire priv_m  = csrMod_io_status_privState_PRVM == 2'h3;
  wire priv_hs = ~csrMod_io_status_privState_V & csrMod_io_status_privState_PRVM == 2'h1;
  wire priv_vs =  csrMod_io_status_privState_V & csrMod_io_status_privState_PRVM == 2'h1;
  wire priv_u  = csrMod_io_status_privState_PRVM == 2'h0;   // HU 或 VU
  wire ex_mcall_now  = is_ecall & priv_m;
  wire ex_hscall_now = is_ecall & priv_hs;
  wire ex_vscall_now = is_ecall & priv_vs;
  wire ex_ucall_now  = is_ecall & priv_u;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      waddr_q         <= 12'h0;
      wdata_q         <= 64'h0;
      ex_bp_q         <= 1'b0;
      ex_mcall_q      <= 1'b0;
      ex_hscall_q     <= 1'b0;
      ex_vscall_q     <= 1'b0;
      ex_ucall_q      <= 1'b0;
      xret_redirect_q <= 1'b0;
      not_jmp_q       <= 1'b0;
    end
    else if (in_fire) begin
      waddr_q         <= funct12;
      wdata_q         <= wdata_now;
      ex_bp_q         <= is_ebreak;
      ex_mcall_q      <= ex_mcall_now;
      ex_hscall_q     <= ex_hscall_now;
      ex_vscall_q     <= ex_vscall_now;
      ex_ucall_q      <= ex_ucall_now;
      xret_redirect_q <= io_in_valid & func == 9'h10 & ~is_ecall & ~is_ebreak;
      not_jmp_q       <= func != 9'h10;
    end
  end

  // ==========================================================================
  // 3. 本条指令的 robIdx 与重定向冲刷判断
  // ==========================================================================
  logic       rob_idx_flag_q;
  logic [7:0] rob_idx_value_q;
  always @(posedge clock)
    if (in_fire) begin
      rob_idx_flag_q  <= io_in_bits_ctrl_robIdx_flag;
      rob_idx_value_q <= io_in_bits_ctrl_robIdx_value;
    end
  wire       this_rob_flag  = io_in_valid ? io_in_bits_ctrl_robIdx_flag  : rob_idx_flag_q;
  wire [7:0] this_rob_value = io_in_valid ? io_in_bits_ctrl_robIdx_value : rob_idx_value_q;
  // RobPtr.needFlush：flush 就是本条且 level=1（冲刷自身），或本条在 flush 点之后
  // （环形指针比较：两者 flag 不同时大小关系取反）
  wire redirect_flush = io_flush_valid
    & (io_flush_bits_level & {this_rob_flag, this_rob_value}
                              == {io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value}
       | this_rob_flag ^ io_flush_bits_robIdx_flag ^ this_rob_value > io_flush_bits_robIdx_value);

  // ==========================================================================
  // 4. TrapInstMod 的输入
  // ==========================================================================
  // 译码送来的"可能引发异常的指令编码"打一拍
  logic        trap_inst_info_valid_q;
  logic [31:0] trap_inst_info_instr_q;
  logic        trap_inst_info_ftq_flag_q;
  logic [5:0]  trap_inst_info_ftq_value_q;
  logic [3:0]  trap_inst_info_ftq_offset_q;
  always @(posedge clock or posedge reset) begin
    if (reset)
      trap_inst_info_valid_q <= 1'b0;
    else
      trap_inst_info_valid_q <= io_csrin_trapInstInfo_valid;
  end
  always @(posedge clock)
    if (io_csrin_trapInstInfo_valid) begin
      trap_inst_info_instr_q      <= io_csrin_trapInstInfo_bits_instr;
      trap_inst_info_ftq_flag_q   <= io_csrin_trapInstInfo_bits_ftqPtr_flag;
      trap_inst_info_ftq_value_q  <= io_csrin_trapInstInfo_bits_ftqPtr_value;
      trap_inst_info_ftq_offset_q <= io_csrin_trapInstInfo_bits_ftqOffset;
    end

  // CSR 指令本身出错（EX_II/EX_VI）时，把这条 CSR uop 的信息交给 TrapInstMod（接收拍直通）。
  // TrapInstMod 只读 fuOpType[2:0]（CSR 操作类）与 imm[21:0]（rd/rs1/csr 地址），所以只锁这些位
  // （golden 锁全宽，多出来的高位写了但没人读，见 verif/dead_ref/CSR.json）。
  logic [2:0]  fault_fuoptype_q;
  logic [21:0] fault_imm_q;
  logic        fault_ftq_flag_q;
  logic [5:0]  fault_ftq_value_q;
  logic [3:0]  fault_ftq_offset_q;
  always @(posedge clock)
    if (in_fire) begin
      fault_fuoptype_q   <= io_in_bits_ctrl_fuOpType[2:0];
      fault_imm_q        <= io_in_bits_data_imm[21:0];
      fault_ftq_flag_q   <= io_in_bits_ctrl_ftqIdx_flag;
      fault_ftq_value_q  <= io_in_bits_ctrl_ftqIdx_value;
      fault_ftq_offset_q <= io_in_bits_ctrl_ftqOffset;
    end
  wire        fault_csr_uop_valid      = csrMod_io_out_valid & (csrMod_io_out_bits_EX_II | csrMod_io_out_bits_EX_VI);
  wire [8:0]  fault_csr_uop_fuoptype   = in_fire ? io_in_bits_ctrl_fuOpType : {6'h0, fault_fuoptype_q};
  wire [21:0] fault_csr_uop_imm        = in_fire ? io_in_bits_data_imm[21:0] : fault_imm_q;
  wire        fault_csr_uop_ftq_flag   = in_fire ? io_in_bits_ctrl_ftqIdx_flag  : fault_ftq_flag_q;
  wire [5:0]  fault_csr_uop_ftq_value  = in_fire ? io_in_bits_ctrl_ftqIdx_value : fault_ftq_value_q;
  wire [3:0]  fault_csr_uop_ftq_offset = in_fire ? io_in_bits_ctrl_ftqOffset    : fault_ftq_offset_q;
  // 非法/虚拟指令异常进入 trap 时，清掉记录的指令（已被用掉）
  wire trap_inst_read_clear = io_csrio_exception_valid & ~io_csrio_exception_bits_isInterrupt
                            & (io_csrio_exception_bits_exceptionVec_2 | io_csrio_exception_bits_exceptionVec_22);
  // 取指地址非法异常进入 trap 时清 tval 记录
  wire trap_tval_clear = io_csrio_exception_valid & io_csrio_exception_bits_isFetchMalAddr;

  // ==========================================================================
  // 5. 输出
  // ==========================================================================
  // 随 uop 透传的控制/调试信息：接收拍锁存（不复位）
  logic       out_ftq_flag_q;
  logic [5:0] out_ftq_value_q;
  logic [3:0] out_ftq_offset_q;
  logic       out_rob_flag_q;
  logic [7:0] out_rob_value_q;
  logic [7:0] out_pdest_q;
  logic       out_rf_wen_q;
  logic       out_pd_valid_q, out_pd_is_rvc_q, out_pd_is_call_q, out_pd_is_ret_q;
  logic [1:0] out_pd_br_type_q;
  logic        perf_eliminated_move_q;
  logic [63:0] perf_rename_time_q, perf_dispatch_time_q, perf_enq_rs_time_q, perf_select_time_q;
  logic [63:0] perf_issue_time_q, perf_writeback_time_q, perf_runahead_checkpoint_id_q;
  logic [63:0] perf_tlb_first_req_time_q, perf_tlb_resp_time_q;
  logic [55:0] debug_seq_num_q;
  logic [7:0]  debug_uop_idx_q;
  always @(posedge clock)
    if (in_fire) begin
      out_ftq_flag_q                <= io_in_bits_ctrl_ftqIdx_flag;
      out_ftq_value_q               <= io_in_bits_ctrl_ftqIdx_value;
      out_ftq_offset_q              <= io_in_bits_ctrl_ftqOffset;
      out_rob_flag_q                <= io_in_bits_ctrl_robIdx_flag;
      out_rob_value_q               <= io_in_bits_ctrl_robIdx_value;
      out_pdest_q                   <= io_in_bits_ctrl_pdest;
      out_rf_wen_q                  <= io_in_bits_ctrl_rfWen;
      out_pd_valid_q                <= io_in_bits_ctrl_preDecode_valid;
      out_pd_is_rvc_q               <= io_in_bits_ctrl_preDecode_isRVC;
      out_pd_br_type_q              <= io_in_bits_ctrl_preDecode_brType;
      out_pd_is_call_q              <= io_in_bits_ctrl_preDecode_isCall;
      out_pd_is_ret_q               <= io_in_bits_ctrl_preDecode_isRet;
      perf_eliminated_move_q        <= io_in_bits_perfDebugInfo_eliminatedMove;
      perf_rename_time_q            <= io_in_bits_perfDebugInfo_renameTime;
      perf_dispatch_time_q          <= io_in_bits_perfDebugInfo_dispatchTime;
      perf_enq_rs_time_q            <= io_in_bits_perfDebugInfo_enqRsTime;
      perf_select_time_q            <= io_in_bits_perfDebugInfo_selectTime;
      perf_issue_time_q             <= io_in_bits_perfDebugInfo_issueTime;
      perf_writeback_time_q         <= io_in_bits_perfDebugInfo_writebackTime;
      perf_runahead_checkpoint_id_q <= io_in_bits_perfDebugInfo_runahead_checkpoint_id;
      perf_tlb_first_req_time_q     <= io_in_bits_perfDebugInfo_tlbFirstReqTime;
      perf_tlb_resp_time_q          <= io_in_bits_perfDebugInfo_tlbRespTime;
      debug_seq_num_q               <= io_in_bits_debug_seqNum_seqNum;
      debug_uop_idx_q               <= io_in_bits_debug_seqNum_uopIdx;
    end

  // tlb.priv.virt 变化检测（DataChanged：和上一拍比）、critical error 打两拍（均不复位）
  logic dvirt_q;
  logic critical_error_d1, critical_error_d2;
  always @(posedge clock) begin
    dvirt_q           <= csrMod_io_tlb_dvirt;
    critical_error_d1 <= csrMod_io_error_0;
    critical_error_d2 <= critical_error_d1;
  end

  assign io_in_ready  = csrMod_io_in_ready;
  assign io_out_valid = csrMod_io_out_valid;

  assign io_out_bits_ctrl_robIdx_flag     = out_rob_flag_q;
  assign io_out_bits_ctrl_robIdx_value    = out_rob_value_q;
  assign io_out_bits_ctrl_pdest           = out_pdest_q;
  assign io_out_bits_ctrl_rfWen           = out_rf_wen_q;
  // 异常向量：2=非法指令 3=断点 8/9/10/11=U/HS/VS/M ecall 22=虚拟指令
  assign io_out_bits_ctrl_exceptionVec_2  = csrMod_io_out_bits_EX_II;
  assign io_out_bits_ctrl_exceptionVec_3  = in_fire ? is_ebreak     : ex_bp_q;
  assign io_out_bits_ctrl_exceptionVec_8  = in_fire ? ex_ucall_now  : ex_ucall_q;
  assign io_out_bits_ctrl_exceptionVec_9  = in_fire ? ex_hscall_now : ex_hscall_q;
  assign io_out_bits_ctrl_exceptionVec_10 = in_fire ? ex_vscall_now : ex_vscall_q;
  assign io_out_bits_ctrl_exceptionVec_11 = in_fire ? ex_mcall_now  : ex_mcall_q;
  assign io_out_bits_ctrl_exceptionVec_22 = csrMod_io_out_bits_EX_VI;
  assign io_out_bits_ctrl_satpFlushPipe   = csrMod_io_status_satp_valid | csrMod_io_status_vsatp_valid;
  assign io_out_bits_ctrl_preDecode_valid  = out_pd_valid_q;
  assign io_out_bits_ctrl_preDecode_isRVC  = out_pd_is_rvc_q;
  assign io_out_bits_ctrl_preDecode_brType = out_pd_br_type_q;
  assign io_out_bits_ctrl_preDecode_isCall = out_pd_is_call_q;
  assign io_out_bits_ctrl_preDecode_isRet  = out_pd_is_ret_q;

  // xret 重定向：flushAfter，目标取 NewCSR 给出的 targetPc；其余字段为 0
  assign io_out_bits_res_redirect_valid              = csrMod_io_out_valid & xret_redirect_q;
  assign io_out_bits_res_redirect_bits_isRVC         = 1'b0;
  assign io_out_bits_res_redirect_bits_robIdx_flag   = rob_idx_flag_q;
  assign io_out_bits_res_redirect_bits_robIdx_value  = rob_idx_value_q;
  assign io_out_bits_res_redirect_bits_ftqIdx_flag   = out_ftq_flag_q;
  assign io_out_bits_res_redirect_bits_ftqIdx_value  = out_ftq_value_q;
  assign io_out_bits_res_redirect_bits_ftqOffset     = out_ftq_offset_q;
  assign io_out_bits_res_redirect_bits_level         = 1'b0;
  assign io_out_bits_res_redirect_bits_interrupt     = 1'b0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pc = 50'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_valid = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_brType = 2'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_ssp = 4'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_sctr = 3'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value = 5'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value = 5'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_NOS_value = 5'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_topAddr = 50'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist = 11'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist = 11'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist = 7'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist = 9'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist = 4'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist = 9'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist = 7'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist = 7'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist = 9'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist = 7'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist = 11'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH = 3'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_ghr = 4'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0 = 10'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1 = 10'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_br_hit = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_jr_hit = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_sc_hit = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_isMisPred = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_shift = 2'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist = 1'h0;
  assign io_out_bits_res_redirect_bits_fullTarget = 64'h0;
  assign io_out_bits_res_redirect_bits_satpFlush = 1'h0;
  assign io_out_bits_res_redirect_bits_isVlsException = 1'h0;
  assign io_out_bits_res_redirect_bits_stFtqIdx_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_stFtqIdx_value = 6'h0;
  assign io_out_bits_res_redirect_bits_stFtqOffset = 4'h0;
  assign io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id = 64'h0;
  assign io_out_bits_res_redirect_bits_debugIsCtrl = 1'h0;
  assign io_out_bits_res_redirect_bits_debugIsMemVio = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_predTaken   = 1'b1;
  assign io_out_bits_res_redirect_bits_cfiUpdate_taken       = 1'b1;
  assign io_out_bits_res_redirect_bits_cfiUpdate_target      = csrMod_io_out_bits_targetPc_pc[49:0];
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF = csrMod_io_out_bits_targetPc_raiseIGPF;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIPF  = csrMod_io_out_bits_targetPc_raiseIPF;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIAF  = csrMod_io_out_bits_targetPc_raiseIAF;

  assign io_out_bits_perfDebugInfo_eliminatedMove        = perf_eliminated_move_q;
  assign io_out_bits_perfDebugInfo_renameTime            = perf_rename_time_q;
  assign io_out_bits_perfDebugInfo_dispatchTime          = perf_dispatch_time_q;
  assign io_out_bits_perfDebugInfo_enqRsTime             = perf_enq_rs_time_q;
  assign io_out_bits_perfDebugInfo_selectTime            = perf_select_time_q;
  assign io_out_bits_perfDebugInfo_issueTime             = perf_issue_time_q;
  assign io_out_bits_perfDebugInfo_writebackTime         = perf_writeback_time_q;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = perf_runahead_checkpoint_id_q;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime       = perf_tlb_first_req_time_q;
  assign io_out_bits_perfDebugInfo_tlbRespTime           = perf_tlb_resp_time_q;
  assign io_out_bits_debug_seqNum_seqNum                 = debug_seq_num_q;
  assign io_out_bits_debug_seqNum_uopIdx                 = debug_uop_idx_q;

  assign io_csrio_isPerfCnt = csrMod_io_out_valid & csrMod_io_out_bits_isPerfCnt & not_jmp_q;
  assign io_csrio_vpu_vstart = {57'h0, csrMod_io_status_vecState_vstart};
  assign io_csrio_trapTarget_pc        = csrMod_io_out_bits_targetPc_pc;
  assign io_csrio_trapTarget_raiseIPF  = csrMod_io_out_bits_targetPc_raiseIPF;
  assign io_csrio_trapTarget_raiseIAF  = csrMod_io_out_bits_targetPc_raiseIAF;
  assign io_csrio_trapTarget_raiseIGPF = csrMod_io_out_bits_targetPc_raiseIGPF;
  assign io_csrio_tlb_hgatp_vmid       = {2'h0, csrMod_io_tlb_hgatp_VMID};
  assign io_csrio_tlb_priv_virt         = csrMod_io_tlb_dvirt;
  assign io_csrio_tlb_priv_virt_changed = csrMod_io_tlb_dvirt != dvirt_q;
  // 自定义 CSR 写广播（地址/数据随写一起送出，供分布式 CSR 副本更新）
  assign io_csrio_customCtrl_distribute_csr_w_bits_addr = waddr_q;
  assign io_csrio_customCtrl_distribute_csr_w_bits_data = wdata_q;
  assign io_csrio_customCtrl_fsIsOff  = csrMod_io_toDecode_illegalInst_fsIsOff;
  assign io_csrToDecode_illegalInst_fsIsOff = csrMod_io_toDecode_illegalInst_fsIsOff;
  assign io_error_0 = critical_error_d2;

  // ==========================================================================
  // 子模块例化（GENERATED；实例名与 golden 相同）
  // ==========================================================================
// BEGIN GENERATED(csr-insts) —— 由 scripts/gen_newcsr.py 从 golden 机械产出，勿手改
  NewCSR csrMod (
    .clock                                                  (clock),
    .reset                                                  (reset),
    .platformIRP_MEIP                                       (io_csrio_externalInterrupt_meip),
    .platformIRP_MTIP                                       (io_csrio_externalInterrupt_mtip),
    .platformIRP_MSIP                                       (io_csrio_externalInterrupt_msip),
    .platformIRP_SEIP                                       (io_csrio_externalInterrupt_seip),
    .platformIRP_debugIP                                    (io_csrio_externalInterrupt_debug),
    .nonMaskableIRP_NMI_43                                  (io_csrio_externalInterrupt_nmi_nmi_43),
    .nonMaskableIRP_NMI_31                                  (io_csrio_externalInterrupt_nmi_nmi_31),
    .io_fromTop_hartId                                      (io_csrin_hartId[5:0]),
    .io_fromTop_clintTime_valid                             (io_csrin_clintTime_valid),
    .io_fromTop_clintTime_bits                              (io_csrin_clintTime_bits),
    .io_fromTop_l2FlushDone                                 (io_csrin_l2FlushDone),
    .io_fromTop_criticalErrorState                          (io_csrin_criticalErrorState),
    .io_in_ready                                            (csrMod_io_in_ready),
    .io_in_valid                                            (io_in_valid),
    .io_in_bits_wen                                         (csr_wen),
    .io_in_bits_ren                                         (csr_ren),
    .io_in_bits_op                                          (io_in_bits_ctrl_fuOpType[1:0]),
    .io_in_bits_addr                                        (io_in_bits_data_imm[11:0]),
    .io_in_bits_src                                         (csr_src),
    .io_in_bits_wdata                                       (wdata_q),
    .io_in_bits_mnret                                       (is_mnret),
    .io_in_bits_mret                                        (is_mret),
    .io_in_bits_sret                                        (is_sret),
    .io_in_bits_dret                                        (is_dret),
    .io_in_bits_redirectFlush                               (redirect_flush),
    .io_trapInst_valid                                      (trapInstMod_io_currentTrapInst_valid),
    .io_trapInst_bits                                       (trapInstMod_io_currentTrapInst_bits),
    .io_fromMem_excpVA                                      (io_csrio_memExceptionVAddr),
    .io_fromMem_excpGPA                                     (io_csrio_memExceptionGPAddr),
    .io_fromMem_excpIsForVSnonLeafPTE                       (io_csrio_memExceptionIsForVSnonLeafPTE),
    .io_fromRob_trap_valid                                  (io_csrio_exception_valid),
    .io_fromRob_trap_bits_pc                                (io_csrio_exception_bits_pc),
    .io_fromRob_trap_bits_pcGPA                             (io_csrio_exception_bits_gpaddr[55:0]),
    .io_fromRob_trap_bits_instr                             (io_csrio_exception_bits_instr),
    .io_fromRob_trap_bits_trapVec                           ({40'h0, io_csrio_exception_bits_exceptionVec_23, io_csrio_exception_bits_exceptionVec_22, io_csrio_exception_bits_exceptionVec_21, io_csrio_exception_bits_exceptionVec_20, io_csrio_exception_bits_exceptionVec_19, io_csrio_exception_bits_exceptionVec_18, io_csrio_exception_bits_exceptionVec_17, io_csrio_exception_bits_exceptionVec_16, io_csrio_exception_bits_exceptionVec_15, io_csrio_exception_bits_exceptionVec_14, io_csrio_exception_bits_exceptionVec_13, io_csrio_exception_bits_exceptionVec_12, io_csrio_exception_bits_exceptionVec_11, io_csrio_exception_bits_exceptionVec_10, io_csrio_exception_bits_exceptionVec_9, io_csrio_exception_bits_exceptionVec_8, io_csrio_exception_bits_exceptionVec_7, io_csrio_exception_bits_exceptionVec_6, io_csrio_exception_bits_exceptionVec_5, io_csrio_exception_bits_exceptionVec_4, io_csrio_exception_bits_exceptionVec_3, io_csrio_exception_bits_exceptionVec_2, io_csrio_exception_bits_exceptionVec_1, io_csrio_exception_bits_exceptionVec_0}),
    .io_fromRob_trap_bits_isFetchBkpt                       (io_csrio_exception_bits_isPcBkpt),
    .io_fromRob_trap_bits_singleStep                        (io_csrio_exception_bits_singleStep),
    .io_fromRob_trap_bits_trigger                           (io_csrio_exception_bits_trigger),
    .io_fromRob_trap_bits_crossPageIPFFix                   (io_csrio_exception_bits_crossPageIPFFix),
    .io_fromRob_trap_bits_isInterrupt                       (io_csrio_exception_bits_isInterrupt),
    .io_fromRob_trap_bits_isHls                             (io_csrio_exception_bits_isHls),
    .io_fromRob_trap_bits_isFetchMalAddr                    (io_csrio_exception_bits_isFetchMalAddr),
    .io_fromRob_trap_bits_isForVSnonLeafPTE                 (io_csrio_exception_bits_isForVSnonLeafPTE),
    .io_fromRob_trap_bits_satpFlushFirstFetchFault          (io_csrio_exception_bits_satpFlushFirstFetchFault),
    .io_fromRob_commit_instNum_bits                         (io_csrio_perf_retiredInstr),
    .io_fromRob_commit_fflags_valid                         (io_csrio_fpu_fflags_valid),
    .io_fromRob_commit_fflags_bits                          (io_csrio_fpu_fflags_bits),
    .io_fromRob_commit_fsDirty                              (io_csrio_fpu_dirty_fs),
    .io_fromRob_commit_vxsat_valid                          (io_csrio_vpu_set_vxsat_valid),
    .io_fromRob_commit_vxsat_bits                           (io_csrio_vpu_set_vxsat_bits),
    .io_fromRob_commit_vsDirty                              (io_csrio_vpu_dirty_vs),
    .io_fromRob_commit_vtype_valid                          (io_csrio_vpu_set_vtype_valid),
    .io_fromRob_commit_vtype_bits_VILL                      (io_csrio_vpu_set_vtype_bits[63]),
    .io_fromRob_commit_vtype_bits_VMA                       (io_csrio_vpu_set_vtype_bits[7]),
    .io_fromRob_commit_vtype_bits_VTA                       (io_csrio_vpu_set_vtype_bits[6]),
    .io_fromRob_commit_vtype_bits_VSEW                      (io_csrio_vpu_set_vtype_bits[5:3]),
    .io_fromRob_commit_vtype_bits_VLMUL                     (io_csrio_vpu_set_vtype_bits[2:0]),
    .io_fromRob_commit_vl                                   (io_csrio_vpu_vl[7:0]),
    .io_fromRob_commit_vstart_valid                         (io_csrio_vpu_set_vstart_valid),
    .io_fromRob_commit_vstart_bits                          (io_csrio_vpu_set_vstart_bits[6:0]),
    .io_fromVecExcpMod_busy                                 (io_csrin_fromVecExcpMod_busy),
    .io_perf_perfEventsFrontend_0_value                     (io_csrio_perf_perfEventsFrontend_0_value),
    .io_perf_perfEventsFrontend_1_value                     (io_csrio_perf_perfEventsFrontend_1_value),
    .io_perf_perfEventsFrontend_2_value                     (io_csrio_perf_perfEventsFrontend_2_value),
    .io_perf_perfEventsFrontend_3_value                     (io_csrio_perf_perfEventsFrontend_3_value),
    .io_perf_perfEventsFrontend_4_value                     (io_csrio_perf_perfEventsFrontend_4_value),
    .io_perf_perfEventsFrontend_5_value                     (io_csrio_perf_perfEventsFrontend_5_value),
    .io_perf_perfEventsFrontend_6_value                     (io_csrio_perf_perfEventsFrontend_6_value),
    .io_perf_perfEventsFrontend_7_value                     (io_csrio_perf_perfEventsFrontend_7_value),
    .io_perf_perfEventsBackend_0_value                      (io_csrio_perf_perfEventsBackend_0_value),
    .io_perf_perfEventsBackend_1_value                      (io_csrio_perf_perfEventsBackend_1_value),
    .io_perf_perfEventsBackend_2_value                      (io_csrio_perf_perfEventsBackend_2_value),
    .io_perf_perfEventsBackend_3_value                      (io_csrio_perf_perfEventsBackend_3_value),
    .io_perf_perfEventsBackend_4_value                      (io_csrio_perf_perfEventsBackend_4_value),
    .io_perf_perfEventsBackend_5_value                      (io_csrio_perf_perfEventsBackend_5_value),
    .io_perf_perfEventsBackend_6_value                      (io_csrio_perf_perfEventsBackend_6_value),
    .io_perf_perfEventsBackend_7_value                      (io_csrio_perf_perfEventsBackend_7_value),
    .io_perf_perfEventsLsu_0_value                          (io_csrio_perf_perfEventsLsu_0_value),
    .io_perf_perfEventsLsu_1_value                          (io_csrio_perf_perfEventsLsu_1_value),
    .io_perf_perfEventsLsu_2_value                          (io_csrio_perf_perfEventsLsu_2_value),
    .io_perf_perfEventsLsu_3_value                          (io_csrio_perf_perfEventsLsu_3_value),
    .io_perf_perfEventsLsu_4_value                          (io_csrio_perf_perfEventsLsu_4_value),
    .io_perf_perfEventsLsu_5_value                          (io_csrio_perf_perfEventsLsu_5_value),
    .io_perf_perfEventsLsu_6_value                          (io_csrio_perf_perfEventsLsu_6_value),
    .io_perf_perfEventsLsu_7_value                          (io_csrio_perf_perfEventsLsu_7_value),
    .io_perf_perfEventsHc_0_value                           (io_csrio_perf_perfEventsHc_0_value),
    .io_perf_perfEventsHc_1_value                           (io_csrio_perf_perfEventsHc_1_value),
    .io_perf_perfEventsHc_2_value                           (io_csrio_perf_perfEventsHc_2_value),
    .io_perf_perfEventsHc_3_value                           (io_csrio_perf_perfEventsHc_3_value),
    .io_perf_perfEventsHc_4_value                           (io_csrio_perf_perfEventsHc_4_value),
    .io_perf_perfEventsHc_5_value                           (io_csrio_perf_perfEventsHc_5_value),
    .io_perf_perfEventsHc_6_value                           (io_csrio_perf_perfEventsHc_6_value),
    .io_perf_perfEventsHc_7_value                           (io_csrio_perf_perfEventsHc_7_value),
    .io_perf_perfEventsHc_8_value                           (io_csrio_perf_perfEventsHc_8_value),
    .io_perf_perfEventsHc_9_value                           (io_csrio_perf_perfEventsHc_9_value),
    .io_perf_perfEventsHc_10_value                          (io_csrio_perf_perfEventsHc_10_value),
    .io_perf_perfEventsHc_11_value                          (io_csrio_perf_perfEventsHc_11_value),
    .io_perf_perfEventsHc_12_value                          (io_csrio_perf_perfEventsHc_12_value),
    .io_perf_perfEventsHc_13_value                          (io_csrio_perf_perfEventsHc_13_value),
    .io_perf_perfEventsHc_14_value                          (io_csrio_perf_perfEventsHc_14_value),
    .io_perf_perfEventsHc_15_value                          (io_csrio_perf_perfEventsHc_15_value),
    .io_perf_perfEventsHc_16_value                          (io_csrio_perf_perfEventsHc_16_value),
    .io_perf_perfEventsHc_17_value                          (io_csrio_perf_perfEventsHc_17_value),
    .io_perf_perfEventsHc_18_value                          (io_csrio_perf_perfEventsHc_18_value),
    .io_perf_perfEventsHc_19_value                          (io_csrio_perf_perfEventsHc_19_value),
    .io_perf_perfEventsHc_20_value                          (io_csrio_perf_perfEventsHc_20_value),
    .io_perf_perfEventsHc_21_value                          (io_csrio_perf_perfEventsHc_21_value),
    .io_perf_perfEventsHc_22_value                          (io_csrio_perf_perfEventsHc_22_value),
    .io_perf_perfEventsHc_23_value                          (io_csrio_perf_perfEventsHc_23_value),
    .io_perf_perfEventsHc_24_value                          (io_csrio_perf_perfEventsHc_24_value),
    .io_perf_perfEventsHc_25_value                          (io_csrio_perf_perfEventsHc_25_value),
    .io_perf_perfEventsHc_26_value                          (io_csrio_perf_perfEventsHc_26_value),
    .io_perf_perfEventsHc_27_value                          (io_csrio_perf_perfEventsHc_27_value),
    .io_perf_perfEventsHc_28_value                          (io_csrio_perf_perfEventsHc_28_value),
    .io_perf_perfEventsHc_29_value                          (io_csrio_perf_perfEventsHc_29_value),
    .io_perf_perfEventsHc_30_value                          (io_csrio_perf_perfEventsHc_30_value),
    .io_perf_perfEventsHc_31_value                          (io_csrio_perf_perfEventsHc_31_value),
    .io_perf_perfEventsHc_32_value                          (io_csrio_perf_perfEventsHc_32_value),
    .io_perf_perfEventsHc_33_value                          (io_csrio_perf_perfEventsHc_33_value),
    .io_perf_perfEventsHc_34_value                          (io_csrio_perf_perfEventsHc_34_value),
    .io_perf_perfEventsHc_35_value                          (io_csrio_perf_perfEventsHc_35_value),
    .io_perf_perfEventsHc_36_value                          (io_csrio_perf_perfEventsHc_36_value),
    .io_perf_perfEventsHc_37_value                          (io_csrio_perf_perfEventsHc_37_value),
    .io_perf_perfEventsHc_38_value                          (io_csrio_perf_perfEventsHc_38_value),
    .io_perf_perfEventsHc_39_value                          (io_csrio_perf_perfEventsHc_39_value),
    .io_perf_perfEventsHc_40_value                          (io_csrio_perf_perfEventsHc_40_value),
    .io_perf_perfEventsHc_41_value                          (io_csrio_perf_perfEventsHc_41_value),
    .io_perf_perfEventsHc_42_value                          (io_csrio_perf_perfEventsHc_42_value),
    .io_perf_perfEventsHc_43_value                          (io_csrio_perf_perfEventsHc_43_value),
    .io_perf_perfEventsHc_44_value                          (io_csrio_perf_perfEventsHc_44_value),
    .io_perf_perfEventsHc_45_value                          (io_csrio_perf_perfEventsHc_45_value),
    .io_perf_perfEventsHc_46_value                          (io_csrio_perf_perfEventsHc_46_value),
    .io_perf_perfEventsHc_47_value                          (io_csrio_perf_perfEventsHc_47_value),
    .io_perf_perfEventsHc_48_value                          (io_csrio_perf_perfEventsHc_48_value),
    .io_perf_perfEventsHc_49_value                          (io_csrio_perf_perfEventsHc_49_value),
    .io_perf_perfEventsHc_50_value                          (io_csrio_perf_perfEventsHc_50_value),
    .io_perf_perfEventsHc_51_value                          (io_csrio_perf_perfEventsHc_51_value),
    .io_perf_perfEventsHc_52_value                          (io_csrio_perf_perfEventsHc_52_value),
    .io_perf_perfEventsHc_53_value                          (io_csrio_perf_perfEventsHc_53_value),
    .io_perf_perfEventsHc_54_value                          (io_csrio_perf_perfEventsHc_54_value),
    .io_perf_perfEventsHc_55_value                          (io_csrio_perf_perfEventsHc_55_value),
    .io_perf_perfEventsHc_56_value                          (io_csrio_perf_perfEventsHc_56_value),
    .io_perf_perfEventsHc_57_value                          (io_csrio_perf_perfEventsHc_57_value),
    .io_perf_perfEventsHc_58_value                          (io_csrio_perf_perfEventsHc_58_value),
    .io_perf_perfEventsHc_59_value                          (io_csrio_perf_perfEventsHc_59_value),
    .io_perf_perfEventsHc_60_value                          (io_csrio_perf_perfEventsHc_60_value),
    .io_perf_perfEventsHc_61_value                          (io_csrio_perf_perfEventsHc_61_value),
    .io_perf_perfEventsHc_62_value                          (io_csrio_perf_perfEventsHc_62_value),
    .io_perf_perfEventsHc_63_value                          (io_csrio_perf_perfEventsHc_63_value),
    .io_perf_perfEventsHc_64_value                          (io_csrio_perf_perfEventsHc_64_value),
    .io_perf_perfEventsHc_65_value                          (io_csrio_perf_perfEventsHc_65_value),
    .io_perf_perfEventsHc_66_value                          (io_csrio_perf_perfEventsHc_66_value),
    .io_perf_perfEventsHc_67_value                          (io_csrio_perf_perfEventsHc_67_value),
    .io_out_ready                                           (io_out_ready),
    .io_out_valid                                           (csrMod_io_out_valid),
    .io_out_bits_EX_II                                      (csrMod_io_out_bits_EX_II),
    .io_out_bits_EX_VI                                      (csrMod_io_out_bits_EX_VI),
    .io_out_bits_flushPipe                                  (io_out_bits_ctrl_flushPipe),
    .io_out_bits_rData                                      (io_out_bits_res_data),
    .io_out_bits_targetPcUpdate                             (csrMod_io_out_bits_targetPcUpdate),
    .io_out_bits_targetPc_pc                                (csrMod_io_out_bits_targetPc_pc),
    .io_out_bits_targetPc_raiseIPF                          (csrMod_io_out_bits_targetPc_raiseIPF),
    .io_out_bits_targetPc_raiseIAF                          (csrMod_io_out_bits_targetPc_raiseIAF),
    .io_out_bits_targetPc_raiseIGPF                         (csrMod_io_out_bits_targetPc_raiseIGPF),
    .io_out_bits_regOut                                     (csrMod_io_out_bits_regOut),
    .io_out_bits_isPerfCnt                                  (csrMod_io_out_bits_isPerfCnt),
    .io_status_privState_PRVM                               (csrMod_io_status_privState_PRVM),
    .io_status_privState_V                                  (csrMod_io_status_privState_V),
    .io_status_interrupt                                    (io_csrio_interrupt),
    .io_status_wfiEvent                                     (io_csrio_wfi_event),
    .io_status_satp_valid                                   (csrMod_io_status_satp_valid),
    .io_status_satp_bits                                    (csrMod_io_status_satp_bits),
    .io_status_vsatp_valid                                  (csrMod_io_status_vsatp_valid),
    .io_status_vsatp_bits                                   (csrMod_io_status_vsatp_bits),
    .io_status_fpState_frm                                  (io_csrio_fpu_frm),
    .io_status_vecState_vstart                              (csrMod_io_status_vecState_vstart),
    .io_status_vecState_vxrm                                (io_csrio_vpu_vxrm),
    .io_status_singleStepFlag                               (io_csrio_customCtrl_singlestep),
    .io_status_frontendTrigger_tUpdate_valid                (io_csrio_customCtrl_frontend_trigger_tUpdate_valid),
    .io_status_frontendTrigger_tUpdate_bits_addr            (io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr),
    .io_status_frontendTrigger_tUpdate_bits_tdata_matchType (io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType),
    .io_status_frontendTrigger_tUpdate_bits_tdata_select    (io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select),
    .io_status_frontendTrigger_tUpdate_bits_tdata_action    (io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action),
    .io_status_frontendTrigger_tUpdate_bits_tdata_chain     (io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain),
    .io_status_frontendTrigger_tUpdate_bits_tdata_tdata2    (io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2),
    .io_status_frontendTrigger_tEnableVec_0                 (io_csrio_customCtrl_frontend_trigger_tEnableVec_0),
    .io_status_frontendTrigger_tEnableVec_1                 (io_csrio_customCtrl_frontend_trigger_tEnableVec_1),
    .io_status_frontendTrigger_tEnableVec_2                 (io_csrio_customCtrl_frontend_trigger_tEnableVec_2),
    .io_status_frontendTrigger_tEnableVec_3                 (io_csrio_customCtrl_frontend_trigger_tEnableVec_3),
    .io_status_frontendTrigger_debugMode                    (io_csrio_customCtrl_frontend_trigger_debugMode),
    .io_status_frontendTrigger_triggerCanRaiseBpExp         (io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp),
    .io_status_memTrigger_tUpdate_valid                     (io_csrio_customCtrl_mem_trigger_tUpdate_valid),
    .io_status_memTrigger_tUpdate_bits_addr                 (io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr),
    .io_status_memTrigger_tUpdate_bits_tdata_matchType      (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType),
    .io_status_memTrigger_tUpdate_bits_tdata_select         (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select),
    .io_status_memTrigger_tUpdate_bits_tdata_action         (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action),
    .io_status_memTrigger_tUpdate_bits_tdata_chain          (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain),
    .io_status_memTrigger_tUpdate_bits_tdata_store          (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store),
    .io_status_memTrigger_tUpdate_bits_tdata_load           (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load),
    .io_status_memTrigger_tUpdate_bits_tdata_tdata2         (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2),
    .io_status_memTrigger_tEnableVec_0                      (io_csrio_customCtrl_mem_trigger_tEnableVec_0),
    .io_status_memTrigger_tEnableVec_1                      (io_csrio_customCtrl_mem_trigger_tEnableVec_1),
    .io_status_memTrigger_tEnableVec_2                      (io_csrio_customCtrl_mem_trigger_tEnableVec_2),
    .io_status_memTrigger_tEnableVec_3                      (io_csrio_customCtrl_mem_trigger_tEnableVec_3),
    .io_status_memTrigger_debugMode                         (io_csrio_customCtrl_mem_trigger_debugMode),
    .io_status_memTrigger_triggerCanRaiseBpExp              (io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp),
    .io_status_instrAddrTransType_bare                      (io_csrio_instrAddrTransType_bare),
    .io_status_instrAddrTransType_sv39                      (io_csrio_instrAddrTransType_sv39),
    .io_status_instrAddrTransType_sv39x4                    (io_csrio_instrAddrTransType_sv39x4),
    .io_status_instrAddrTransType_sv48                      (io_csrio_instrAddrTransType_sv48),
    .io_status_instrAddrTransType_sv48x4                    (io_csrio_instrAddrTransType_sv48x4),
    .io_status_traceCSR_cause                               (io_csrio_traceCSR_cause),
    .io_status_traceCSR_tval                                (io_csrio_traceCSR_tval),
    .io_status_traceCSR_mstatus                             (io_csrio_traceCSR_mstatus),
    .io_status_traceCSR_lastPriv                            (io_csrio_traceCSR_lastPriv),
    .io_status_traceCSR_currentPriv                         (io_csrio_traceCSR_currentPriv),
    .io_status_custom_pf_ctrl_l1I_pf_enable                 (io_csrio_customCtrl_pf_ctrl_l1I_pf_enable),
    .io_status_custom_pf_ctrl_l2_pf_enable                  (io_csrio_customCtrl_pf_ctrl_l2_pf_enable),
    .io_status_custom_pf_ctrl_l1D_pf_enable                 (io_csrio_customCtrl_pf_ctrl_l1D_pf_enable),
    .io_status_custom_pf_ctrl_l1D_pf_train_on_hit           (io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit),
    .io_status_custom_pf_ctrl_l1D_pf_enable_agt             (io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt),
    .io_status_custom_pf_ctrl_l1D_pf_enable_pht             (io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht),
    .io_status_custom_pf_ctrl_l1D_pf_active_threshold       (io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold),
    .io_status_custom_pf_ctrl_l1D_pf_active_stride          (io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride),
    .io_status_custom_pf_ctrl_l1D_pf_enable_stride          (io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride),
    .io_status_custom_pf_ctrl_l2_pf_store_only              (io_csrio_customCtrl_pf_ctrl_l2_pf_store_only),
    .io_status_custom_pf_ctrl_l2_pf_recv_enable             (io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable),
    .io_status_custom_pf_ctrl_l2_pf_pbop_enable             (io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable),
    .io_status_custom_pf_ctrl_l2_pf_vbop_enable             (io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable),
    .io_status_custom_pf_ctrl_l2_pf_delay_latency           (io_csrio_customCtrl_pf_ctrl_l2_pf_delay_latency),
    .io_status_custom_lvpred_timeout                        (io_csrio_customCtrl_lvpred_timeout),
    .io_status_custom_bp_ctrl_ubtb_enable                   (io_csrio_customCtrl_bp_ctrl_ubtb_enable),
    .io_status_custom_bp_ctrl_btb_enable                    (io_csrio_customCtrl_bp_ctrl_btb_enable),
    .io_status_custom_bp_ctrl_tage_enable                   (io_csrio_customCtrl_bp_ctrl_tage_enable),
    .io_status_custom_bp_ctrl_sc_enable                     (io_csrio_customCtrl_bp_ctrl_sc_enable),
    .io_status_custom_bp_ctrl_ras_enable                    (io_csrio_customCtrl_bp_ctrl_ras_enable),
    .io_status_custom_sbuffer_timeout                       (io_csrio_customCtrl_sbuffer_timeout),
    .io_status_custom_ldld_vio_check_enable                 (io_csrio_customCtrl_ldld_vio_check_enable),
    .io_status_custom_cache_error_enable                    (io_csrio_customCtrl_cache_error_enable),
    .io_status_custom_uncache_write_outstanding_enable      (io_csrio_customCtrl_uncache_write_outstanding_enable),
    .io_status_custom_hd_misalign_st_enable                 (io_csrio_customCtrl_hd_misalign_st_enable),
    .io_status_custom_hd_misalign_ld_enable                 (io_csrio_customCtrl_hd_misalign_ld_enable),
    .io_status_custom_power_down_enable                     (io_csrio_customCtrl_power_down_enable),
    .io_status_custom_flush_l2_enable                       (io_csrio_customCtrl_flush_l2_enable),
    .io_status_custom_fusion_enable                         (io_csrio_customCtrl_fusion_enable),
    .io_status_custom_wfi_enable                            (io_csrio_customCtrl_wfi_enable),
    .io_status_criticalErrorState                           (io_csrio_criticalErrorState),
    .io_tlb_satpASIDChanged                                 (io_csrio_tlb_satp_changed),
    .io_tlb_vsatpASIDChanged                                (io_csrio_tlb_vsatp_changed),
    .io_tlb_hgatpVMIDChanged                                (io_csrio_tlb_hgatp_changed),
    .io_tlb_satp_MODE                                       (io_csrio_tlb_satp_mode),
    .io_tlb_satp_ASID                                       (io_csrio_tlb_satp_asid),
    .io_tlb_satp_PPN                                        (io_csrio_tlb_satp_ppn),
    .io_tlb_vsatp_MODE                                      (io_csrio_tlb_vsatp_mode),
    .io_tlb_vsatp_ASID                                      (io_csrio_tlb_vsatp_asid),
    .io_tlb_vsatp_PPN                                       (io_csrio_tlb_vsatp_ppn),
    .io_tlb_hgatp_MODE                                      (io_csrio_tlb_hgatp_mode),
    .io_tlb_hgatp_VMID                                      (csrMod_io_tlb_hgatp_VMID),
    .io_tlb_hgatp_PPN                                       (io_csrio_tlb_hgatp_ppn),
    .io_tlb_mbmc_BMA                                        (io_csrio_tlb_mbmc_BMA),
    .io_tlb_mbmc_BME                                        (io_csrio_tlb_mbmc_BME),
    .io_tlb_mbmc_BCLEAR                                     (io_csrio_tlb_mbmc_BCLEAR),
    .io_tlb_mbmc_CMODE                                      (io_csrio_tlb_mbmc_CMODE),
    .io_tlb_mxr                                             (io_csrio_tlb_priv_mxr),
    .io_tlb_sum                                             (io_csrio_tlb_priv_sum),
    .io_tlb_vmxr                                            (io_csrio_tlb_priv_vmxr),
    .io_tlb_vsum                                            (io_csrio_tlb_priv_vsum),
    .io_tlb_spvp                                            (io_csrio_tlb_priv_spvp),
    .io_tlb_imode                                           (io_csrio_tlb_priv_imode),
    .io_tlb_dmode                                           (io_csrio_tlb_priv_dmode),
    .io_tlb_debug                                           (io_csrio_tlb_priv_debug),
    .io_tlb_dvirt                                           (csrMod_io_tlb_dvirt),
    .io_tlb_mPBMTE                                          (io_csrio_tlb_mPBMTE),
    .io_tlb_hPBMTE                                          (io_csrio_tlb_hPBMTE),
    .io_tlb_pmm_mseccfg                                     (io_csrio_tlb_pmm_mseccfg),
    .io_tlb_pmm_menvcfg                                     (io_csrio_tlb_pmm_menvcfg),
    .io_tlb_pmm_henvcfg                                     (io_csrio_tlb_pmm_henvcfg),
    .io_tlb_pmm_hstatus                                     (io_csrio_tlb_pmm_hstatus),
    .io_tlb_pmm_senvcfg                                     (io_csrio_tlb_pmm_senvcfg),
    .io_toDecode_illegalInst_sfenceVMA                      (io_csrToDecode_illegalInst_sfenceVMA),
    .io_toDecode_illegalInst_sfencePart                     (io_csrToDecode_illegalInst_sfencePart),
    .io_toDecode_illegalInst_hfenceGVMA                     (io_csrToDecode_illegalInst_hfenceGVMA),
    .io_toDecode_illegalInst_hfenceVVMA                     (io_csrToDecode_illegalInst_hfenceVVMA),
    .io_toDecode_illegalInst_hlsv                           (io_csrToDecode_illegalInst_hlsv),
    .io_toDecode_illegalInst_fsIsOff                        (csrMod_io_toDecode_illegalInst_fsIsOff),
    .io_toDecode_illegalInst_vsIsOff                        (io_csrToDecode_illegalInst_vsIsOff),
    .io_toDecode_illegalInst_wfi                            (io_csrToDecode_illegalInst_wfi),
    .io_toDecode_illegalInst_wrs_nto                        (io_csrToDecode_illegalInst_wrs_nto),
    .io_toDecode_illegalInst_frm                            (io_csrToDecode_illegalInst_frm),
    .io_toDecode_illegalInst_cboZ                           (io_csrToDecode_illegalInst_cboZ),
    .io_toDecode_illegalInst_cboCF                          (io_csrToDecode_illegalInst_cboCF),
    .io_toDecode_illegalInst_cboI                           (io_csrToDecode_illegalInst_cboI),
    .io_toDecode_virtualInst_sfenceVMA                      (io_csrToDecode_virtualInst_sfenceVMA),
    .io_toDecode_virtualInst_sfencePart                     (io_csrToDecode_virtualInst_sfencePart),
    .io_toDecode_virtualInst_hfence                         (io_csrToDecode_virtualInst_hfence),
    .io_toDecode_virtualInst_hlsv                           (io_csrToDecode_virtualInst_hlsv),
    .io_toDecode_virtualInst_wfi                            (io_csrToDecode_virtualInst_wfi),
    .io_toDecode_virtualInst_wrs_nto                        (io_csrToDecode_virtualInst_wrs_nto),
    .io_toDecode_virtualInst_cboZ                           (io_csrToDecode_virtualInst_cboZ),
    .io_toDecode_virtualInst_cboCF                          (io_csrToDecode_virtualInst_cboCF),
    .io_toDecode_virtualInst_cboI                           (io_csrToDecode_virtualInst_cboI),
    .io_toDecode_special_cboI2F                             (io_csrToDecode_special_cboI2F),
    .io_fetchMalTval                                        (trapTvalMod_io_tval),
    .io_oldPrivSate_PRVM                                    (satpFlushMod_out_oldPrivState_PRVM),
    .io_oldPrivSate_V                                       (satpFlushMod_out_oldPrivState_V),
    .io_oldSatpMode                                         (satpFlushMod_out_oldSatpMode),
    .io_oldVsatpMode                                        (satpFlushMod_out_oldVsatpMode),
    .io_distributedWenLegal                                 (io_csrio_customCtrl_distribute_csr_w_valid),
    .toAIA_addr_valid                                       (csrMod_toAIA_addr_valid),
    .toAIA_addr_bits_addr                                   (csrMod_toAIA_addr_bits_addr),
    .toAIA_addr_bits_v                                      (csrMod_toAIA_addr_bits_v),
    .toAIA_addr_bits_prvm                                   (csrMod_toAIA_addr_bits_prvm),
    .toAIA_vgein                                            (csrMod_toAIA_vgein),
    .toAIA_wdata_valid                                      (csrMod_toAIA_wdata_valid),
    .toAIA_wdata_bits_op                                    (csrMod_toAIA_wdata_bits_op),
    .toAIA_wdata_bits_data                                  (csrMod_toAIA_wdata_bits_data),
    .toAIA_mClaim                                           (csrMod_toAIA_mClaim),
    .toAIA_sClaim                                           (csrMod_toAIA_sClaim),
    .toAIA_vsClaim                                          (csrMod_toAIA_vsClaim),
    .fromAIA_rdata_valid                                    (imsic_toCSR_rdata_valid),
    .fromAIA_rdata_bits_data                                (imsic_toCSR_rdata_bits),
    .fromAIA_rdata_bits_illegal                             (imsic_toCSR_illegal),
    .fromAIA_meip                                           (imsic_toCSR_pendings[0]),
    .fromAIA_seip                                           (imsic_toCSR_pendings[1]),
    .fromAIA_notice_pending                                 (1'h0),
    .fromAIA_vseip                                          (imsic_toCSR_pendings[8:2]),
    .fromAIA_mtopei_IID                                     (imsic_toCSR_topeis_0[26:16]),
    .fromAIA_mtopei_IPRIO                                   (imsic_toCSR_topeis_0[10:0]),
    .fromAIA_stopei_IID                                     (imsic_toCSR_topeis_1[26:16]),
    .fromAIA_stopei_IPRIO                                   (imsic_toCSR_topeis_1[10:0]),
    .fromAIA_vstopei_IID                                    (imsic_toCSR_topeis_2[26:16]),
    .fromAIA_vstopei_IPRIO                                  (imsic_toCSR_topeis_2[10:0]),
    .io_error_0                                             (csrMod_io_error_0),
    .gatewayIn_packed_29_bore                               (gatewayIn_packed_29_bore),
    .gatewayIn_packed_30_bore                               (gatewayIn_packed_30_bore),
    .gatewayIn_packed_31_bore                               (gatewayIn_packed_31_bore),
    .gatewayIn_packed_32_bore                               (gatewayIn_packed_32_bore),
    .gatewayIn_packed_33_bore                               (gatewayIn_packed_33_bore),
    .gatewayIn_packed_34_bore                               (gatewayIn_packed_34_bore),
    .gatewayIn_packed_35_bore                               (gatewayIn_packed_35_bore),
    .gatewayIn_packed_36_bore                               (gatewayIn_packed_36_bore),
    .gatewayIn_packed_37_bore                               (gatewayIn_packed_37_bore),
    .gatewayIn_packed_38_bore                               (gatewayIn_packed_38_bore),
    .gatewayIn_packed_39_bore                               (gatewayIn_packed_39_bore),
    .gatewayIn_packed_40_bore                               (gatewayIn_packed_40_bore)
  );
  TrapInstMod trapInstMod (
    .clock                                        (clock),
    .reset                                        (reset),
    .io_fromDecode_trapInstInfo_valid             (trap_inst_info_valid_q),
    .io_fromDecode_trapInstInfo_bits_instr        (trap_inst_info_instr_q),
    .io_fromDecode_trapInstInfo_bits_ftqPtr_flag  (trap_inst_info_ftq_flag_q),
    .io_fromDecode_trapInstInfo_bits_ftqPtr_value (trap_inst_info_ftq_value_q),
    .io_fromDecode_trapInstInfo_bits_ftqOffset    (trap_inst_info_ftq_offset_q),
    .io_fromRob_flush_valid                       (io_flush_valid),
    .io_fromRob_flush_bits_ftqPtr_flag            (io_flush_bits_ftqIdx_flag),
    .io_fromRob_flush_bits_ftqPtr_value           (io_flush_bits_ftqIdx_value),
    .io_fromRob_flush_bits_ftqOffset              (io_flush_bits_ftqOffset),
    .io_fromRob_isInterrupt_valid                 (io_csrio_exception_valid),
    .io_fromRob_isInterrupt_bits                  (io_csrio_exception_bits_isInterrupt),
    .io_faultCsrUop_valid                         (fault_csr_uop_valid),
    .io_faultCsrUop_bits_fuOpType                 (fault_csr_uop_fuoptype),
    .io_faultCsrUop_bits_imm                      (fault_csr_uop_imm),
    .io_faultCsrUop_bits_ftqInfo_ftqPtr_flag      (fault_csr_uop_ftq_flag),
    .io_faultCsrUop_bits_ftqInfo_ftqPtr_value     (fault_csr_uop_ftq_value),
    .io_faultCsrUop_bits_ftqInfo_ftqOffset        (fault_csr_uop_ftq_offset),
    .io_readClear                                 (trap_inst_read_clear),
    .io_currentTrapInst_valid                     (trapInstMod_io_currentTrapInst_valid),
    .io_currentTrapInst_bits                      (trapInstMod_io_currentTrapInst_bits)
  );
  TrapTvalMod trapTvalMod (
    .clock                                             (clock),
    .reset                                             (reset),
    .io_fromCtrlBlock_flush_valid                      (io_flush_valid),
    .io_fromCtrlBlock_flush_bits_robIdx_flag           (io_flush_bits_robIdx_flag),
    .io_fromCtrlBlock_flush_bits_robIdx_value          (io_flush_bits_robIdx_value),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF (io_flush_bits_cfiUpdate_backendIGPF),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF  (io_flush_bits_cfiUpdate_backendIPF),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF  (io_flush_bits_cfiUpdate_backendIAF),
    .io_fromCtrlBlock_flush_bits_fullTarget            (io_flush_bits_fullTarget),
    .io_fromCtrlBlock_robDeqPtr_flag                   (io_csrio_robDeqPtr_flag),
    .io_fromCtrlBlock_robDeqPtr_value                  (io_csrio_robDeqPtr_value),
    .io_targetPc_valid                                 (csrMod_io_out_bits_targetPcUpdate),
    .io_targetPc_bits_pc                               (csrMod_io_out_bits_targetPc_pc),
    .io_targetPc_bits_raiseIPF                         (csrMod_io_out_bits_targetPc_raiseIPF),
    .io_targetPc_bits_raiseIAF                         (csrMod_io_out_bits_targetPc_raiseIAF),
    .io_targetPc_bits_raiseIGPF                        (csrMod_io_out_bits_targetPc_raiseIGPF),
    .io_clear                                          (trap_tval_clear),
    .io_tval                                           (trapTvalMod_io_tval)
  );
  SatpFlushMod satpFlushMod (
    .clock                 (clock),
    .in_satp_valid         (csrMod_io_status_satp_valid),
    .in_satp_bits          (csrMod_io_status_satp_bits),
    .in_vsatp_valid        (csrMod_io_status_vsatp_valid),
    .in_vsatp_bits         (csrMod_io_status_vsatp_bits),
    .in_privState_PRVM     (csrMod_io_status_privState_PRVM),
    .in_privState_V        (csrMod_io_status_privState_V),
    .out_oldPrivState_PRVM (satpFlushMod_out_oldPrivState_PRVM),
    .out_oldPrivState_V    (satpFlushMod_out_oldPrivState_V),
    .out_oldSatpMode       (satpFlushMod_out_oldSatpMode),
    .out_oldVsatpMode      (satpFlushMod_out_oldVsatpMode)
  );
  IMSIC_WRAP imsic (
    .clock                   (clock),
    .reset                   (reset),
    .toCSR_rdata_valid       (imsic_toCSR_rdata_valid),
    .toCSR_rdata_bits        (imsic_toCSR_rdata_bits),
    .toCSR_illegal           (imsic_toCSR_illegal),
    .toCSR_pendings          (imsic_toCSR_pendings),
    .toCSR_topeis_0          (imsic_toCSR_topeis_0),
    .toCSR_topeis_1          (imsic_toCSR_topeis_1),
    .toCSR_topeis_2          (imsic_toCSR_topeis_2),
    .fromCSR_addr_valid      (csrMod_toAIA_addr_valid),
    .fromCSR_addr_bits_addr  (csrMod_toAIA_addr_bits_addr),
    .fromCSR_addr_bits_virt  (csrMod_toAIA_addr_bits_v),
    .fromCSR_addr_bits_priv  (csrMod_toAIA_addr_bits_prvm),
    .fromCSR_vgein           (csrMod_toAIA_vgein),
    .fromCSR_wdata_valid     (csrMod_toAIA_wdata_valid),
    .fromCSR_wdata_bits_op   (csrMod_toAIA_wdata_bits_op),
    .fromCSR_wdata_bits_data (csrMod_toAIA_wdata_bits_data),
    .fromCSR_claims_0        (csrMod_toAIA_mClaim),
    .fromCSR_claims_1        (csrMod_toAIA_sClaim),
    .fromCSR_claims_2        (csrMod_toAIA_vsClaim),
    .msiio_vld_req           (io_csrin_msiInfo_valid),
    .msiio_data              (io_csrin_msiInfo_bits),
    .msiio_vld_ack           (io_csrio_msiAck)
  );
// END GENERATED(csr-insts)

endmodule
