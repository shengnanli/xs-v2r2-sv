// 自动生成: scripts/gen_rob_arr160_tb.py —— 边界定向 UT, 勿手改
`timescale 1ns/1ps
import rob_pkg::*;
module tb;
  bit clk = 0; logic clock, reset; assign clock = clk;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_redirect_valid;
  logic io_redirect_bits_robIdx_flag;
  logic [PTR_W-1:0] io_redirect_bits_robIdx_value;
  logic io_redirect_bits_level;
  logic [RENAME_WIDTH-1:0] enq_valid;
  logic [RENAME_WIDTH-1:0] enq_first_uop;
  logic [RENAME_WIDTH-1:0] enq_need_write_rf;
  logic [RENAME_WIDTH-1:0] enq_write_std;
  logic [RENAME_WIDTH-1:0] enq_block_backward;
  logic [RENAME_WIDTH-1:0] enq_wait_forward;
  logic [RENAME_WIDTH-1:0] enq_is_wfi;
  logic [RENAME_WIDTH-1:0] enq_has_exception;
  logic [RENAME_WIDTH-1:0] enq_trigger_dmode;
  logic [RENAME_WIDTH-1:0] enq_allow_interrupt;
  logic [UOP_CNT_W-1:0] enq_num_wb [RENAME_WIDTH];
  logic [PTR_W-1:0] enq_robidx_value [RENAME_WIDTH];
  rob_entry_t enq_info [RENAME_WIDTH];
  logic [NUM_EXU_WB-1:0] wb_valid;
  logic [PTR_W-1:0] wb_robidx [NUM_EXU_WB];
  logic [4:0] wb_num [NUM_EXU_WB];
  logic [NUM_EXU_WB-1:0] wb_is_std;
  logic [NUM_EXU_WB-1:0] wb_fflags_valid;
  logic [4:0] wb_fflags [NUM_EXU_WB];
  logic [NUM_EXU_WB-1:0] wb_vxsat_valid;
  logic [NUM_EXU_WB-1:0] wb_vxsat;
  logic [NUM_EXU_WB-1:0] wb_branch_taken;
  logic [NUM_WB-1:0] excp_wb_valid;
  logic [PTR_W-1:0] excp_wb_robidx [NUM_WB];
  logic [NUM_WB-1:0] excp_wb_need_flush;
  logic eg_valid;
  logic eg_robidx_flag;
  logic [PTR_W-1:0] eg_robidx_value;
  logic eg_is_exception;
  logic eg_flush_pipe;
  logic eg_replay_inst;
  logic eg_is_vls;
  logic eg_is_enq_excp;
  logic eg_is_vset;
  rob_ptr_t deq_ptr_vec [COMMIT_WIDTH];
  rob_ptr_t deq_ptr_next0;
  rob_ptr_t enq_ptr_vec [RENAME_WIDTH];
  rob_ptr_t snap_ptr0;
  logic io_csr_intrBitSet;
  logic io_csr_wfiEvent;
  logic io_csr_criticalErrorState;
  logic io_snpt_useSnpt;
  logic io_wfi_enable;
  logic io_wfi_safeFromMem;
  logic io_wfi_safeFromFrontend;
  logic io_fromVecExcpMod_busy;
  logic io_trace_blockCommit;
  logic rab_can_enq;
  logic rab_status_commit_end;
  logic rab_status_walk_end;
  logic vtype_status_walk_end;
  logic io_misPredWb;
  logic io_wb1_redir;
  logic io_wb3_redir;
  logic io_wb5_redir;
  // ---- [pLsqDeep] lsq→mmio 核输入(本定向 UT 恒 0) ----
  logic [2:0] lsq_mmio;
  logic [PTR_W-1:0] lsq_uop_robidx_value [3];
  logic io_eg_vstartEn;
  logic [63:0] io_eg_vstart;
  logic io_vstartIsZero;
  logic [34:0] enq_fuType [RENAME_WIDTH];
  logic io_debugHeadLsIssue;
  logic [PTR_W-1:0] io_lsTopdown_s1_robIdx [3];
  logic [2:0] io_lsTopdown_s1_valid;
  logic [49:0] io_lsTopdown_s1_bits [3];
  logic [PTR_W-1:0] io_lsTopdown_s2_robIdx [3];
  logic [2:0] io_lsTopdown_s2_valid;
  logic [47:0] io_lsTopdown_s2_bits [3];
  logic [6:0] eg_state_vstart;
  logic [1:0] eg_state_vsew;
  logic [1:0] eg_state_veew;
  logic [2:0] eg_state_vlmul;
  logic [2:0] eg_state_nf;
  logic eg_state_isStrided;
  logic eg_state_isIndexed;
  logic eg_state_isWhole;
  logic eg_state_isVlm;
  logic eg_state_vstartEn;
  logic eg_state_isVecLoad;
  logic eg_state_isEnqExcp;
  rob_state_e o_state;
  logic o_commits_isCommit;
  logic o_commits_isWalk;
  logic [COMMIT_WIDTH-1:0] o_commits_commitValid;
  logic [COMMIT_WIDTH-1:0] o_commits_walkValid;
  rob_commit_entry_t o_commit_info [COMMIT_WIDTH];
  rob_ptr_t o_commits_robIdx [COMMIT_WIDTH];
  logic [COMMIT_WIDTH-1:0] o_deq_commit_v;
  logic [COMMIT_WIDTH-1:0] o_deq_commit_w;
  logic o_intrBitSetReg;
  logic o_hasNoSpecExec;
  logic o_allowOnlyOneCommit;
  logic o_blockCommit;
  logic [COMMIT_WIDTH-1:0] o_hasCommitted;
  logic o_allCommitted;
  logic o_allowEnqueue;
  logic o_hasBlockBackward;
  logic [RENAME_WIDTH-1:0] o_enq_for_ptr;
  logic o_eg_flush;
  logic [UOP_CNT_W:0] o_rab_commitSize;
  logic [UOP_CNT_W:0] o_rab_walkSize;
  logic o_rab_walkEnd;
  logic o_flushOut_valid;
  logic o_flushOut_robIdx_flag;
  logic [PTR_W-1:0] o_flushOut_robIdx_value;
  logic o_flushOut_level;
  logic o_flushOut_isRVC;
  logic [FTQ_PTR_W-1:0] o_flushOut_ftqIdx_value;
  logic o_flushOut_ftqIdx_flag;
  logic [FTQ_OFFSET_W-1:0] o_flushOut_ftqOffset;
  logic o_exception_valid;
  logic o_exceptionHappen;
  logic o_deqHasException;
  logic o_intrEnable;
  logic o_enq_canAccept;
  logic o_enq_canAcceptForDispatch;
  logic o_robFull;
  logic o_headNotReady;
  logic o_cpu_halt;
  logic o_wfiReq;
  logic [PTR_W:0] o_numValidEntries;
  logic [5:0] o_perf_0_value;
  logic [5:0] o_perf_1_value;
  logic [5:0] o_perf_2_value;
  logic [5:0] o_perf_3_value;
  logic [5:0] o_perf_4_value;
  logic [5:0] o_perf_5_value;
  logic [5:0] o_perf_6_value;
  logic [5:0] o_perf_7_value;
  logic [5:0] o_perf_8_value;
  logic [5:0] o_perf_9_value;
  logic [5:0] o_perf_10_value;
  logic [5:0] o_perf_11_value;
  logic [5:0] o_perf_12_value;
  logic [5:0] o_perf_13_value;
  logic [5:0] o_perf_14_value;
  logic [5:0] o_perf_15_value;
  logic [5:0] o_perf_16_value;
  logic [5:0] o_perf_17_value;
  logic [COMMIT_WIDTH-1:0] o_trace_valid;
  logic [FTQ_PTR_W-1:0] o_trace_ftqIdx_value [COMMIT_WIDTH];
  logic [FTQ_OFFSET_W-1:0] o_trace_ftqOffset [COMMIT_WIDTH];
  logic [ITYPE_W-1:0] o_trace_itype [COMMIT_WIDTH];
  logic [IRETIRE_W-1:0] o_trace_iretire [COMMIT_WIDTH];
  logic [COMMIT_WIDTH-1:0] o_trace_ilastsize;
  logic o_csr_fflags_valid;
  logic [4:0] o_csr_fflags_bits;
  logic o_csr_vxsat_valid;
  logic o_csr_vxsat_bits;
  logic o_csr_vstart_valid;
  logic [63:0] o_csr_vstart_bits;
  logic o_csr_dirty_fs;
  logic o_csr_dirty_vs;
  logic [6:0] o_csr_perfinfo_retiredInstr;
  logic [34:0] o_debugRobHead_fuType;
  logic o_debugTopDown_robHeadLsIssue;
  logic o_debugTopDown_robHeadVaddr_valid;
  logic [49:0] o_debugTopDown_robHeadVaddr_bits;
  logic o_debugTopDown_robHeadPaddr_valid;
  logic [47:0] o_debugTopDown_robHeadPaddr_bits;
  logic o_toVecExcpMod_excpInfo_valid;
  logic [6:0] o_toVecExcpMod_excpInfo_bits_vstart;
  logic [1:0] o_toVecExcpMod_excpInfo_bits_vsew;
  logic [1:0] o_toVecExcpMod_excpInfo_bits_veew;
  logic [2:0] o_toVecExcpMod_excpInfo_bits_vlmul;
  logic [2:0] o_toVecExcpMod_excpInfo_bits_nf;
  logic o_toVecExcpMod_excpInfo_bits_isStride;
  logic o_toVecExcpMod_excpInfo_bits_isIndexed;
  logic o_toVecExcpMod_excpInfo_bits_isWhole;
  logic o_toVecExcpMod_excpInfo_bits_isVlm;
  logic [COMMIT_WIDTH-1:0] o_deq_entry_vls;
  logic o_deq_entry_valid_0;
  logic o_deq_entry_mmio_0;
  logic o_deqHasFlushed;

  xs_Rob_core u_core (
    .clock(clock),
    .reset(reset),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .enq_valid(enq_valid),
    .enq_first_uop(enq_first_uop),
    .enq_need_write_rf(enq_need_write_rf),
    .enq_write_std(enq_write_std),
    .enq_block_backward(enq_block_backward),
    .enq_wait_forward(enq_wait_forward),
    .enq_is_wfi(enq_is_wfi),
    .enq_has_exception(enq_has_exception),
    .enq_trigger_dmode(enq_trigger_dmode),
    .enq_allow_interrupt(enq_allow_interrupt),
    .enq_num_wb(enq_num_wb),
    .enq_robidx_value(enq_robidx_value),
    .enq_info(enq_info),
    .wb_valid(wb_valid),
    .wb_robidx(wb_robidx),
    .wb_num(wb_num),
    .wb_is_std(wb_is_std),
    .wb_fflags_valid(wb_fflags_valid),
    .wb_fflags(wb_fflags),
    .wb_vxsat_valid(wb_vxsat_valid),
    .wb_vxsat(wb_vxsat),
    .wb_branch_taken(wb_branch_taken),
    .excp_wb_valid(excp_wb_valid),
    .excp_wb_robidx(excp_wb_robidx),
    .excp_wb_need_flush(excp_wb_need_flush),
    .eg_valid(eg_valid),
    .eg_robidx_flag(eg_robidx_flag),
    .eg_robidx_value(eg_robidx_value),
    .eg_is_exception(eg_is_exception),
    .eg_flush_pipe(eg_flush_pipe),
    .eg_replay_inst(eg_replay_inst),
    .eg_is_vls(eg_is_vls),
    .eg_is_enq_excp(eg_is_enq_excp),
    .eg_is_vset(eg_is_vset),
    .deq_ptr_vec(deq_ptr_vec),
    .deq_ptr_next0(deq_ptr_next0),
    .enq_ptr_vec(enq_ptr_vec),
    .snap_ptr0(snap_ptr0),
    .io_csr_intrBitSet(io_csr_intrBitSet),
    .io_csr_wfiEvent(io_csr_wfiEvent),
    .io_csr_criticalErrorState(io_csr_criticalErrorState),
    .io_snpt_useSnpt(io_snpt_useSnpt),
    .io_wfi_enable(io_wfi_enable),
    .io_wfi_safeFromMem(io_wfi_safeFromMem),
    .io_wfi_safeFromFrontend(io_wfi_safeFromFrontend),
    .io_fromVecExcpMod_busy(io_fromVecExcpMod_busy),
    .io_trace_blockCommit(io_trace_blockCommit),
    .rab_can_enq(rab_can_enq),
    .rab_can_enq_for_dispatch(rab_can_enq),
    .rab_status_commit_end(rab_status_commit_end),
    .rab_status_walk_end(rab_status_walk_end),
    .vtype_status_walk_end(vtype_status_walk_end),
    .io_misPredWb(io_misPredWb),
    .io_wb1_redir(io_wb1_redir),
    .io_wb3_redir(io_wb3_redir),
    .io_wb5_redir(io_wb5_redir),
    .lsq_mmio(lsq_mmio),
    .lsq_uop_robidx_value(lsq_uop_robidx_value),
    .io_eg_vstartEn(io_eg_vstartEn),
    .io_eg_vstart(io_eg_vstart),
    .io_vstartIsZero(io_vstartIsZero),
    .enq_fuType(enq_fuType),
    .io_debugHeadLsIssue(io_debugHeadLsIssue),
    .io_lsTopdown_s1_robIdx(io_lsTopdown_s1_robIdx),
    .io_lsTopdown_s1_valid(io_lsTopdown_s1_valid),
    .io_lsTopdown_s1_bits(io_lsTopdown_s1_bits),
    .io_lsTopdown_s2_robIdx(io_lsTopdown_s2_robIdx),
    .io_lsTopdown_s2_valid(io_lsTopdown_s2_valid),
    .io_lsTopdown_s2_bits(io_lsTopdown_s2_bits),
    .eg_state_vstart(eg_state_vstart),
    .eg_state_vsew(eg_state_vsew),
    .eg_state_veew(eg_state_veew),
    .eg_state_vlmul(eg_state_vlmul),
    .eg_state_nf(eg_state_nf),
    .eg_state_isStrided(eg_state_isStrided),
    .eg_state_isIndexed(eg_state_isIndexed),
    .eg_state_isWhole(eg_state_isWhole),
    .eg_state_isVlm(eg_state_isVlm),
    .eg_state_vstartEn(eg_state_vstartEn),
    .eg_state_isVecLoad(eg_state_isVecLoad),
    .eg_state_isEnqExcp(eg_state_isEnqExcp),
    .o_state(o_state),
    .o_commits_isCommit(o_commits_isCommit),
    .o_commits_isWalk(o_commits_isWalk),
    .o_commits_commitValid(o_commits_commitValid),
    .o_commits_walkValid(o_commits_walkValid),
    .o_commit_info(o_commit_info),
    .o_commits_robIdx(o_commits_robIdx),
    .o_deq_commit_v(o_deq_commit_v),
    .o_deq_commit_w(o_deq_commit_w),
    .o_intrBitSetReg(o_intrBitSetReg),
    .o_hasNoSpecExec(o_hasNoSpecExec),
    .o_allowOnlyOneCommit(o_allowOnlyOneCommit),
    .o_blockCommit(o_blockCommit),
    .o_hasCommitted(o_hasCommitted),
    .o_allCommitted(o_allCommitted),
    .o_allowEnqueue(o_allowEnqueue),
    .o_hasBlockBackward(o_hasBlockBackward),
    .o_enq_for_ptr(o_enq_for_ptr),
    .o_eg_flush(o_eg_flush),
    .o_rab_commitSize(o_rab_commitSize),
    .o_rab_walkSize(o_rab_walkSize),
    .o_rab_walkEnd(o_rab_walkEnd),
    .o_flushOut_valid(o_flushOut_valid),
    .o_flushOut_robIdx_flag(o_flushOut_robIdx_flag),
    .o_flushOut_robIdx_value(o_flushOut_robIdx_value),
    .o_flushOut_level(o_flushOut_level),
    .o_flushOut_isRVC(o_flushOut_isRVC),
    .o_flushOut_ftqIdx_value(o_flushOut_ftqIdx_value),
    .o_flushOut_ftqIdx_flag(o_flushOut_ftqIdx_flag),
    .o_flushOut_ftqOffset(o_flushOut_ftqOffset),
    .o_exception_valid(o_exception_valid),
    .o_exceptionHappen(o_exceptionHappen),
    .o_deqHasException(o_deqHasException),
    .o_intrEnable(o_intrEnable),
    .o_enq_canAccept(o_enq_canAccept),
    .o_enq_canAcceptForDispatch(o_enq_canAcceptForDispatch),
    .o_robFull(o_robFull),
    .o_headNotReady(o_headNotReady),
    .o_cpu_halt(o_cpu_halt),
    .o_wfiReq(o_wfiReq),
    .o_numValidEntries(o_numValidEntries),
    .o_perf_0_value(o_perf_0_value),
    .o_perf_1_value(o_perf_1_value),
    .o_perf_2_value(o_perf_2_value),
    .o_perf_3_value(o_perf_3_value),
    .o_perf_4_value(o_perf_4_value),
    .o_perf_5_value(o_perf_5_value),
    .o_perf_6_value(o_perf_6_value),
    .o_perf_7_value(o_perf_7_value),
    .o_perf_8_value(o_perf_8_value),
    .o_perf_9_value(o_perf_9_value),
    .o_perf_10_value(o_perf_10_value),
    .o_perf_11_value(o_perf_11_value),
    .o_perf_12_value(o_perf_12_value),
    .o_perf_13_value(o_perf_13_value),
    .o_perf_14_value(o_perf_14_value),
    .o_perf_15_value(o_perf_15_value),
    .o_perf_16_value(o_perf_16_value),
    .o_perf_17_value(o_perf_17_value),
    .o_trace_valid(o_trace_valid),
    .o_trace_ftqIdx_value(o_trace_ftqIdx_value),
    .o_trace_ftqOffset(o_trace_ftqOffset),
    .o_trace_itype(o_trace_itype),
    .o_trace_iretire(o_trace_iretire),
    .o_trace_ilastsize(o_trace_ilastsize),
    .o_csr_fflags_valid(o_csr_fflags_valid),
    .o_csr_fflags_bits(o_csr_fflags_bits),
    .o_csr_vxsat_valid(o_csr_vxsat_valid),
    .o_csr_vxsat_bits(o_csr_vxsat_bits),
    .o_csr_vstart_valid(o_csr_vstart_valid),
    .o_csr_vstart_bits(o_csr_vstart_bits),
    .o_csr_dirty_fs(o_csr_dirty_fs),
    .o_csr_dirty_vs(o_csr_dirty_vs),
    .o_csr_perfinfo_retiredInstr(o_csr_perfinfo_retiredInstr),
    .o_debugRobHead_fuType(o_debugRobHead_fuType),
    .o_debugTopDown_robHeadLsIssue(o_debugTopDown_robHeadLsIssue),
    .o_debugTopDown_robHeadVaddr_valid(o_debugTopDown_robHeadVaddr_valid),
    .o_debugTopDown_robHeadVaddr_bits(o_debugTopDown_robHeadVaddr_bits),
    .o_debugTopDown_robHeadPaddr_valid(o_debugTopDown_robHeadPaddr_valid),
    .o_debugTopDown_robHeadPaddr_bits(o_debugTopDown_robHeadPaddr_bits),
    .o_toVecExcpMod_excpInfo_valid(o_toVecExcpMod_excpInfo_valid),
    .o_toVecExcpMod_excpInfo_bits_vstart(o_toVecExcpMod_excpInfo_bits_vstart),
    .o_toVecExcpMod_excpInfo_bits_vsew(o_toVecExcpMod_excpInfo_bits_vsew),
    .o_toVecExcpMod_excpInfo_bits_veew(o_toVecExcpMod_excpInfo_bits_veew),
    .o_toVecExcpMod_excpInfo_bits_vlmul(o_toVecExcpMod_excpInfo_bits_vlmul),
    .o_toVecExcpMod_excpInfo_bits_nf(o_toVecExcpMod_excpInfo_bits_nf),
    .o_toVecExcpMod_excpInfo_bits_isStride(o_toVecExcpMod_excpInfo_bits_isStride),
    .o_toVecExcpMod_excpInfo_bits_isIndexed(o_toVecExcpMod_excpInfo_bits_isIndexed),
    .o_toVecExcpMod_excpInfo_bits_isWhole(o_toVecExcpMod_excpInfo_bits_isWhole),
    .o_toVecExcpMod_excpInfo_bits_isVlm(o_toVecExcpMod_excpInfo_bits_isVlm),
    .o_deq_entry_vls(o_deq_entry_vls),
    .o_deq_entry_valid_0(o_deq_entry_valid_0),
    .o_deq_entry_mmio_0(o_deq_entry_mmio_0),
    .o_deqHasFlushed(o_deqHasFlushed)
  );


  // ===================================================================
  // 边界定向验证: ROB_SIZE=160 + index_in_range() guard
  //   合法下标 158/159 → 读出正确 entry(功能 bit-exact)
  //   越界下标 160/255 → guard 使输出为 X(不 clamp/wrap/取 entry-0)
  // ===================================================================
  task automatic zero_inputs();
    reset = 1'b1;
    io_redirect_valid = 0; io_redirect_bits_robIdx_flag = 0;
    io_redirect_bits_robIdx_value = 0; io_redirect_bits_level = 0;
    enq_valid = 0; enq_first_uop = 0; enq_need_write_rf = 0; enq_write_std = 0;
    enq_block_backward = 0; enq_wait_forward = 0; enq_is_wfi = 0;
    enq_has_exception = 0; enq_trigger_dmode = 0; enq_allow_interrupt = '1;
    wb_valid = 0; wb_is_std = 0; wb_fflags_valid = 0; wb_vxsat_valid = 0;
    wb_vxsat = 0; wb_branch_taken = 0; excp_wb_valid = 0; excp_wb_need_flush = 0;
    eg_valid = 0; eg_robidx_flag = 0; eg_robidx_value = 0; eg_is_exception = 0;
    eg_flush_pipe = 0; eg_replay_inst = 0; eg_is_vls = 0; eg_is_enq_excp = 0; eg_is_vset = 0;
    io_eg_vstartEn = 0; io_eg_vstart = 0;
    eg_state_vstart = 0; eg_state_vsew = 0; eg_state_veew = 0; eg_state_vlmul = 0;
    eg_state_nf = 0; eg_state_isStrided = 0; eg_state_isIndexed = 0; eg_state_isWhole = 0;
    eg_state_isVlm = 0; eg_state_vstartEn = 0; eg_state_isVecLoad = 0; eg_state_isEnqExcp = 0;
    io_csr_intrBitSet = 0; io_csr_wfiEvent = 0; io_csr_criticalErrorState = 0;
    io_snpt_useSnpt = 0; io_wfi_enable = 1; io_wfi_safeFromMem = 1; io_wfi_safeFromFrontend = 1;
    io_fromVecExcpMod_busy = 0; io_trace_blockCommit = 0;
    rab_can_enq = 1; rab_status_commit_end = 1; rab_status_walk_end = 1; vtype_status_walk_end = 1;
    io_misPredWb = 0; io_wb1_redir = 0; io_wb3_redir = 0; io_wb5_redir = 0;
    lsq_mmio = '0; lsq_uop_robidx_value[0] = '0; lsq_uop_robidx_value[1] = '0; lsq_uop_robidx_value[2] = '0;
    io_debugHeadLsIssue = 0;
    io_vstartIsZero = 0;
    io_lsTopdown_s1_valid = 0; io_lsTopdown_s2_valid = 0;
    for (int i=0;i<3;i++) begin
      io_lsTopdown_s1_robIdx[i]=0; io_lsTopdown_s1_bits[i]=0;
      io_lsTopdown_s2_robIdx[i]=0; io_lsTopdown_s2_bits[i]=0;
    end
    for (int i=0;i<RENAME_WIDTH;i++) begin
      enq_num_wb[i]=1; enq_robidx_value[i]=0; enq_info[i]='0; enq_fuType[i]=0;
    end
    for (int i=0;i<NUM_EXU_WB;i++) begin wb_robidx[i]=0; wb_num[i]=1; wb_fflags[i]=0; end
    for (int i=0;i<NUM_WB;i++) excp_wb_robidx[i]=0;
    for (int i=0;i<COMMIT_WIDTH;i++) deq_ptr_vec[i]='{flag:0, value:PTR_W'(i)};
    deq_ptr_next0 = '{flag:0, value:0};
    for (int i=0;i<RENAME_WIDTH;i++) enq_ptr_vec[i]='{flag:0, value:PTR_W'(i)};
    snap_ptr0 = '{flag:0, value:0};
    // debug head-issue arrays are difftest sinks; leave defaults
  endtask

  task automatic chk(input string nm, input logic got, input logic exp);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("  [MISMATCH] %s got=%b exp=%b @%0t", nm, got, exp, $time);
    end
  endtask

  task automatic chk_x(input string nm, input logic got);
    checks++;
    if (!$isunknown(got)) begin
      errors++;
      $display("  [NOT-X] %s expected X(unreachable idx) got=%b @%0t", nm, got, $time);
    end
  endtask

  // 驱动一条 enqueue: 口 slot 在 robIdx=idx 处置入 vls=vls_v
  task automatic do_enq(input int slot, input logic [PTR_W-1:0] idx, input logic vls_v);
    enq_ptr_vec[slot] = '{flag:0, value:idx};
    enq_valid[slot] = 1'b1;
    enq_first_uop[slot] = 1'b1;
    enq_num_wb[slot] = 1;
    enq_write_std[slot] = 1'b1;  // std → std_writebacked=~1=0 → not committable, stays valid
    enq_info[slot] = '0;
    enq_info[slot].vls = vls_v;
  endtask

  initial begin
    zero_inputs();
    // reset 3 cycles
    repeat (3) @(posedge clk);
    #1 reset = 1'b0;
    @(posedge clk); #1;

    // ---- 入队 robIdx=158 (vls=1) 和 159 (vls=0) ----
    zero_inputs(); reset = 1'b0;
    do_enq(0, PTR_W'(158), 1'b1);
    do_enq(1, PTR_W'(159), 1'b0);
    @(posedge clk);   // 采样入队
    #1;
    // 停止入队, 保持条目
    enq_valid = 0; enq_first_uop = 0;
    @(posedge clk); #1;   // 条目已落 rob_entries[158]/[159]

    // ---- 合法下标读: deqPtr=158 → valid=1, vls=1 ----
    deq_ptr_vec[0] = '{flag:0, value:PTR_W'(158)};
    #1;
    chk("valid@158", o_deq_entry_valid_0, 1'b1);
    chk("vls@158",   o_deq_entry_vls[0],  1'b1);

    // ---- 合法下标读: deqPtr=159 → valid=1, vls=0 ----
    deq_ptr_vec[0] = '{flag:0, value:PTR_W'(159)};
    #1;
    chk("valid@159", o_deq_entry_valid_0, 1'b1);
    chk("vls@159",   o_deq_entry_vls[0],  1'b0);

    // ---- 空条目下标(0, 未入队) → valid=0 ----
    deq_ptr_vec[0] = '{flag:0, value:PTR_W'(0)};
    #1;
    chk("valid@0-empty", o_deq_entry_valid_0, 1'b0);

    // ---- 越界下标 160 → guard → X (不 clamp 到 159, 不 wrap 到 0, 不取 entry-0) ----
    deq_ptr_vec[0] = '{flag:0, value:PTR_W'(160)};
    #1;
    chk_x("valid@160-oob", o_deq_entry_valid_0);
    chk_x("vls@160-oob",   o_deq_entry_vls[0]);
    chk_x("mmio@160-oob",  o_deq_entry_mmio_0);

    // ---- 越界下标 255 → guard → X ----
    deq_ptr_vec[0] = '{flag:0, value:PTR_W'(255)};
    #1;
    chk_x("valid@255-oob", o_deq_entry_valid_0);
    chk_x("vls@255-oob",   o_deq_entry_vls[0]);
    chk_x("mmio@255-oob",  o_deq_entry_mmio_0);

    // ---- 关键反例: 越界读出的 X 必须 ≠ entry-0 数据(entry0 未入队 valid=0)。
    //      若实现是 clamp→0 或 wrap→0 则会读出 valid=0(非 X); chk_x 已覆盖(要求 X)。
    //      再显式确认 158(vls=1) 处的合法读 ≠ 越界读(X), 证明无「返回正常 entry 数据」。
    deq_ptr_vec[0] = '{flag:0, value:PTR_W'(160)};
    #1;
    if (o_deq_entry_vls[0] === 1'b1) begin
      errors++; $display("  [GAP] oob idx 160 returned entry-158 data(vls=1)! not undefined");
    end

    if (errors == 0)
      $display("=== boundary UT PASSED: checks=%0d errors=0 ===", checks);
    else
      $display("=== boundary UT FAILED: checks=%0d errors=%0d ===", checks, errors);
    // TEST PASSED sentinel for ut_common.mk grep
    if (errors == 0) $display("TEST PASSED");
    else             $display("TEST FAILED");
    $finish;
  end

endmodule