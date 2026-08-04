// 自动生成: scripts/gen_rob.py —— 勿手改

`timescale 1ns/1ps
import rob_pkg::*;
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // ---- 核接口信号 ----
  logic io_redirect_valid;
  logic io_redirect_bits_robIdx_flag; logic [PTR_W-1:0] io_redirect_bits_robIdx_value;
  logic io_redirect_bits_level;
  logic [RENAME_WIDTH-1:0] enq_valid, enq_first_uop, enq_need_write_rf, enq_write_std;
  logic [RENAME_WIDTH-1:0] enq_block_backward, enq_wait_forward, enq_is_wfi;
  logic [RENAME_WIDTH-1:0] enq_has_exception, enq_trigger_dmode, enq_allow_interrupt;
  logic [UOP_CNT_W-1:0] enq_num_wb [RENAME_WIDTH];
  logic [PTR_W-1:0] enq_robidx_value [RENAME_WIDTH];
  rob_entry_t enq_info [RENAME_WIDTH];
  logic [NUM_EXU_WB-1:0] wb_valid; logic [PTR_W-1:0] wb_robidx [NUM_EXU_WB];
  logic [4:0] wb_num [NUM_EXU_WB]; logic [NUM_EXU_WB-1:0] wb_is_std;
  logic [NUM_EXU_WB-1:0] wb_fflags_valid; logic [4:0] wb_fflags [NUM_EXU_WB];
  logic [NUM_EXU_WB-1:0] wb_vxsat_valid, wb_vxsat, wb_branch_taken;
  logic [NUM_WB-1:0] excp_wb_valid; logic [PTR_W-1:0] excp_wb_robidx [NUM_WB];
  logic [NUM_WB-1:0] excp_wb_need_flush;
  logic eg_valid, eg_robidx_flag; logic [PTR_W-1:0] eg_robidx_value;
  logic eg_is_exception, eg_flush_pipe, eg_replay_inst, eg_is_vls, eg_is_enq_excp, eg_is_vset;
  rob_ptr_t deq_ptr_vec [COMMIT_WIDTH]; rob_ptr_t deq_ptr_next0;
  rob_ptr_t enq_ptr_vec [RENAME_WIDTH]; rob_ptr_t snap_ptr0;
  logic io_csr_intrBitSet, io_csr_wfiEvent, io_csr_criticalErrorState;
  logic io_snpt_useSnpt, io_wfi_enable, io_wfi_safeFromMem, io_wfi_safeFromFrontend;
  logic io_fromVecExcpMod_busy, io_trace_blockCommit;
  logic rab_can_enq, rab_can_enq_for_dispatch, rab_status_commit_end, rab_status_walk_end, vtype_status_walk_end;
  logic io_misPredWb;
  logic io_wb1_redir, io_wb3_redir, io_wb5_redir;   // perf_16 misPred 输入 (rob-perf-trace)
  // ---- 核输出 ----
  rob_state_e o_state;
  logic o_commits_isCommit, o_commits_isWalk;
  logic [COMMIT_WIDTH-1:0] o_commits_commitValid, o_commits_walkValid;
  rob_commit_entry_t o_commit_info [COMMIT_WIDTH]; rob_ptr_t o_commits_robIdx [COMMIT_WIDTH];
  logic [COMMIT_WIDTH-1:0] o_deq_commit_v, o_deq_commit_w, o_hasCommitted;
  logic o_intrBitSetReg, o_hasNoSpecExec, o_allowOnlyOneCommit, o_blockCommit, o_allCommitted;
  logic o_allowEnqueue, o_hasBlockBackward; logic [RENAME_WIDTH-1:0] o_enq_for_ptr;
  logic o_eg_flush; logic [UOP_CNT_W:0] o_rab_commitSize, o_rab_walkSize; logic o_rab_walkEnd;
  logic [UOP_CNT_W:0] o_vtype_commitSize, o_vtype_walkSize;
  logic [UOP_CNT_W:0] o_vtype_commitSize_ref, o_vtype_walkSize_ref;
  logic o_enq_isEmpty_ref;
  logic o_flushOut_valid, o_flushOut_robIdx_flag; logic [PTR_W-1:0] o_flushOut_robIdx_value;
  logic o_flushOut_level, o_flushOut_isRVC; logic [FTQ_PTR_W-1:0] o_flushOut_ftqIdx_value;
  logic o_flushOut_ftqIdx_flag; logic [FTQ_OFFSET_W-1:0] o_flushOut_ftqOffset;
  logic o_exception_valid, o_intrEnable;
  logic o_enq_canAccept, o_enq_canAcceptForDispatch, o_robFull, o_enq_isEmpty, o_headNotReady;
  logic o_cpu_halt, o_wfiReq; logic [PTR_W:0] o_numValidEntries;
  // ---- perf/trace 输出 (rob-perf-trace; smoke tb 仅接住 .*, 不做 cycle-exact 比对) ----
  logic [5:0] o_perf_0_value,o_perf_1_value,o_perf_2_value,o_perf_3_value,o_perf_4_value,
              o_perf_5_value,o_perf_6_value,o_perf_7_value,o_perf_8_value,o_perf_9_value,
              o_perf_10_value,o_perf_11_value,o_perf_12_value,o_perf_13_value,o_perf_14_value,
              o_perf_15_value,o_perf_16_value,o_perf_17_value;
  logic [COMMIT_WIDTH-1:0] o_trace_valid, o_trace_ilastsize;
  logic [FTQ_PTR_W-1:0]    o_trace_ftqIdx_value [COMMIT_WIDTH];
  logic [FTQ_OFFSET_W-1:0] o_trace_ftqOffset    [COMMIT_WIDTH];
  logic [ITYPE_W-1:0]      o_trace_itype        [COMMIT_WIDTH];
  logic [IRETIRE_W-1:0]    o_trace_iretire      [COMMIT_WIDTH];

  // ---- testbench 侧 enqPtr/deqPtr 环形模型(模拟两个黑盒 wrapper) ----
  // 简单实现: enqPtr 按本拍入队数前进, deqPtr 按提交数前进。
  rob_ptr_t tb_enq, tb_deq;
  function automatic rob_ptr_t padd(input rob_ptr_t p, input int unsigned n);
    int unsigned v; rob_ptr_t o;
    v = p.value + n;
    if (v >= ROB_SIZE) begin o.value = v - ROB_SIZE; o.flag = ~p.flag; end
    else begin o.value = v[PTR_W-1:0]; o.flag = p.flag; end
    return o;
  endfunction

  // 入队/提交计数
  int unsigned enq_cnt, commit_cnt;
  always_comb begin
    enq_cnt = 0;
    for (int i=0;i<RENAME_WIDTH;i++) if (o_enq_for_ptr[i] && o_enq_canAccept) enq_cnt++;
    commit_cnt = 0;
    for (int i=0;i<COMMIT_WIDTH;i++) if (o_commits_isCommit && o_commits_commitValid[i]) commit_cnt++;
  end

  // enqPtrVec / deqPtrVec / snap 由 tb 模型生成喂给核
  always_comb begin
    for (int i=0;i<RENAME_WIDTH;i++) enq_ptr_vec[i] = padd(tb_enq, i);
    for (int i=0;i<COMMIT_WIDTH;i++) deq_ptr_vec[i] = padd(tb_deq, i);
    deq_ptr_next0 = padd(tb_deq, commit_cnt);
    snap_ptr0 = tb_deq;
  end

  // ---- 例化可读核 ----
  logic clock, reset; assign clock = clk; assign reset = rst;
  // ---- 未驱动输入 tie-0(两核共享同源) ----
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
  assign io_eg_vstartEn='0;
  assign io_eg_vstart='0;
  assign io_vstartIsZero='0;
  initial for (int _i=0;_i<RENAME_WIDTH;_i++) enq_fuType[_i]='0;
  assign io_debugHeadLsIssue='0;
  initial for (int _i=0;_i<3;_i++) io_lsTopdown_s1_robIdx[_i]='0;
  assign io_lsTopdown_s1_valid='0;
  initial for (int _i=0;_i<3;_i++) io_lsTopdown_s1_bits[_i]='0;
  initial for (int _i=0;_i<3;_i++) io_lsTopdown_s2_robIdx[_i]='0;
  assign io_lsTopdown_s2_valid='0;
  initial for (int _i=0;_i<3;_i++) io_lsTopdown_s2_bits[_i]='0;
  assign eg_state_vstart='0;
  assign eg_state_vsew='0;
  assign eg_state_veew='0;
  assign eg_state_vlmul='0;
  assign eg_state_nf='0;
  assign eg_state_isStrided='0;
  assign eg_state_isIndexed='0;
  assign eg_state_isWhole='0;
  assign eg_state_isVlm='0;
  assign eg_state_vstartEn='0;
  assign eg_state_isVecLoad='0;
  assign eg_state_isEnqExcp='0;
  // ---- 补齐 SoA 侧共享输出信号(原 tb 未声明的) ----
  logic o_exceptionHappen;
  logic o_deqHasException;
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
  // ---- packed-ref 输出信号(*_ref) ----
  rob_state_e o_state_ref;
  logic o_commits_isCommit_ref;
  logic o_commits_isWalk_ref;
  logic [COMMIT_WIDTH-1:0] o_commits_commitValid_ref;
  logic [COMMIT_WIDTH-1:0] o_commits_walkValid_ref;
  rob_commit_entry_t o_commit_info_ref [COMMIT_WIDTH];
  rob_ptr_t o_commits_robIdx_ref [COMMIT_WIDTH];
  logic [COMMIT_WIDTH-1:0] o_deq_commit_v_ref;
  logic [COMMIT_WIDTH-1:0] o_deq_commit_w_ref;
  logic o_intrBitSetReg_ref;
  logic o_hasNoSpecExec_ref;
  logic o_allowOnlyOneCommit_ref;
  logic o_blockCommit_ref;
  logic [COMMIT_WIDTH-1:0] o_hasCommitted_ref;
  logic o_allCommitted_ref;
  logic o_allowEnqueue_ref;
  logic o_hasBlockBackward_ref;
  logic [RENAME_WIDTH-1:0] o_enq_for_ptr_ref;
  logic o_eg_flush_ref;
  logic [UOP_CNT_W:0] o_rab_commitSize_ref;
  logic [UOP_CNT_W:0] o_rab_walkSize_ref;
  logic o_rab_walkEnd_ref;
  logic o_flushOut_valid_ref;
  logic o_flushOut_robIdx_flag_ref;
  logic [PTR_W-1:0] o_flushOut_robIdx_value_ref;
  logic o_flushOut_level_ref;
  logic o_flushOut_isRVC_ref;
  logic [FTQ_PTR_W-1:0] o_flushOut_ftqIdx_value_ref;
  logic o_flushOut_ftqIdx_flag_ref;
  logic [FTQ_OFFSET_W-1:0] o_flushOut_ftqOffset_ref;
  logic o_exception_valid_ref;
  logic o_exceptionHappen_ref;
  logic o_deqHasException_ref;
  logic o_intrEnable_ref;
  logic o_enq_canAccept_ref;
  logic o_enq_canAcceptForDispatch_ref;
  logic o_robFull_ref;
  logic o_headNotReady_ref;
  logic o_cpu_halt_ref;
  logic o_wfiReq_ref;
  logic [PTR_W:0] o_numValidEntries_ref;
  logic [5:0] o_perf_0_value_ref;
  logic [5:0] o_perf_1_value_ref;
  logic [5:0] o_perf_2_value_ref;
  logic [5:0] o_perf_3_value_ref;
  logic [5:0] o_perf_4_value_ref;
  logic [5:0] o_perf_5_value_ref;
  logic [5:0] o_perf_6_value_ref;
  logic [5:0] o_perf_7_value_ref;
  logic [5:0] o_perf_8_value_ref;
  logic [5:0] o_perf_9_value_ref;
  logic [5:0] o_perf_10_value_ref;
  logic [5:0] o_perf_11_value_ref;
  logic [5:0] o_perf_12_value_ref;
  logic [5:0] o_perf_13_value_ref;
  logic [5:0] o_perf_14_value_ref;
  logic [5:0] o_perf_15_value_ref;
  logic [5:0] o_perf_16_value_ref;
  logic [5:0] o_perf_17_value_ref;
  logic [COMMIT_WIDTH-1:0] o_trace_valid_ref;
  logic [FTQ_PTR_W-1:0] o_trace_ftqIdx_value_ref [COMMIT_WIDTH];
  logic [FTQ_OFFSET_W-1:0] o_trace_ftqOffset_ref [COMMIT_WIDTH];
  logic [ITYPE_W-1:0] o_trace_itype_ref [COMMIT_WIDTH];
  logic [IRETIRE_W-1:0] o_trace_iretire_ref [COMMIT_WIDTH];
  logic [COMMIT_WIDTH-1:0] o_trace_ilastsize_ref;
  logic o_csr_fflags_valid_ref;
  logic [4:0] o_csr_fflags_bits_ref;
  logic o_csr_vxsat_valid_ref;
  logic o_csr_vxsat_bits_ref;
  logic o_csr_vstart_valid_ref;
  logic [63:0] o_csr_vstart_bits_ref;
  logic o_csr_dirty_fs_ref;
  logic o_csr_dirty_vs_ref;
  logic [6:0] o_csr_perfinfo_retiredInstr_ref;
  logic [34:0] o_debugRobHead_fuType_ref;
  logic o_debugTopDown_robHeadLsIssue_ref;
  logic o_debugTopDown_robHeadVaddr_valid_ref;
  logic [49:0] o_debugTopDown_robHeadVaddr_bits_ref;
  logic o_debugTopDown_robHeadPaddr_valid_ref;
  logic [47:0] o_debugTopDown_robHeadPaddr_bits_ref;
  logic o_toVecExcpMod_excpInfo_valid_ref;
  logic [6:0] o_toVecExcpMod_excpInfo_bits_vstart_ref;
  logic [1:0] o_toVecExcpMod_excpInfo_bits_vsew_ref;
  logic [1:0] o_toVecExcpMod_excpInfo_bits_veew_ref;
  logic [2:0] o_toVecExcpMod_excpInfo_bits_vlmul_ref;
  logic [2:0] o_toVecExcpMod_excpInfo_bits_nf_ref;
  logic o_toVecExcpMod_excpInfo_bits_isStride_ref;
  logic o_toVecExcpMod_excpInfo_bits_isIndexed_ref;
  logic o_toVecExcpMod_excpInfo_bits_isWhole_ref;
  logic o_toVecExcpMod_excpInfo_bits_isVlm_ref;
  logic [COMMIT_WIDTH-1:0] o_deq_entry_vls_ref;
  logic o_deq_entry_valid_0_ref;
  logic o_deq_entry_mmio_0_ref;
  logic o_deqHasFlushed_ref;


  // ---- 时序模型: 推进 tb_enq/tb_deq ----
  always_ff @(posedge clk) begin
    if (rst) begin tb_enq <= '0; tb_deq <= '0; end
    else begin
      if (io_redirect_valid)
        tb_enq <= '{flag:io_redirect_bits_robIdx_flag, value:io_redirect_bits_robIdx_value};
      else tb_enq <= padd(tb_enq, enq_cnt);
      tb_deq <= padd(tb_deq, commit_cnt);
    end
  end

  // ---- 随机激励 ----
  function automatic logic [UOP_CNT_W-1:0] rnwb(); return UOP_CNT_W'($urandom_range(1,4)); endfunction
  always @(negedge clk) begin
    if (rst) begin
      io_redirect_valid<=0; io_redirect_bits_robIdx_flag<=0; io_redirect_bits_robIdx_value<=0;
      io_redirect_bits_level<=0;
      enq_valid<=0; enq_first_uop<=0; enq_need_write_rf<=0; enq_write_std<=0;
      enq_block_backward<=0; enq_wait_forward<=0; enq_is_wfi<=0;
      enq_has_exception<=0; enq_trigger_dmode<=0; enq_allow_interrupt<='1;
      wb_valid<=0; wb_is_std<=0; wb_fflags_valid<=0; wb_vxsat_valid<=0; wb_vxsat<=0; wb_branch_taken<=0;
      excp_wb_valid<=0; excp_wb_need_flush<=0;
      eg_valid<=0; eg_is_exception<=0; eg_flush_pipe<=0; eg_replay_inst<=0;
      eg_is_vls<=0; eg_is_enq_excp<=0; eg_is_vset<=0; eg_robidx_flag<=0; eg_robidx_value<=0;
      io_csr_intrBitSet<=0; io_csr_wfiEvent<=0; io_csr_criticalErrorState<=0;
      io_snpt_useSnpt<=0; io_wfi_enable<=1; io_wfi_safeFromMem<=1; io_wfi_safeFromFrontend<=1;
      io_fromVecExcpMod_busy<=0; io_trace_blockCommit<=0;
      rab_can_enq<=1; rab_can_enq_for_dispatch<=1; rab_status_commit_end<=1; rab_status_walk_end<=1; vtype_status_walk_end<=1;
      io_misPredWb<=0; io_wb1_redir<=0; io_wb3_redir<=0; io_wb5_redir<=0;
      for (int i=0;i<RENAME_WIDTH;i++) begin enq_num_wb[i]<=1; enq_robidx_value[i]<=0; enq_info[i]<='0; end
      for (int i=0;i<NUM_EXU_WB;i++) begin wb_robidx[i]<=0; wb_num[i]<=1; wb_fflags[i]<=0; end
      for (int i=0;i<NUM_WB;i++) excp_wb_robidx[i]<=0;
    end else begin
      // enqueue: 70% 概率有效; robIdx 跟 enqPtrVec; numWB 小随机
      io_redirect_valid <= ($urandom_range(0,99) < 2);
      io_redirect_bits_robIdx_flag <= tb_deq.flag;
      io_redirect_bits_robIdx_value <= deq_ptr_vec[$urandom_range(0,7)].value;
      io_redirect_bits_level <= $urandom_range(0,1);
      for (int i=0;i<RENAME_WIDTH;i++) begin
        enq_valid[i] <= ($urandom_range(0,99)<70);
        enq_first_uop[i] <= 1;
        enq_need_write_rf[i] <= ($urandom_range(0,99)<60);
        enq_write_std[i] <= ($urandom_range(0,99)<15);
        enq_block_backward[i] <= ($urandom_range(0,99)<3);
        enq_wait_forward[i] <= ($urandom_range(0,99)<3);
        enq_is_wfi[i] <= ($urandom_range(0,99)<2);
        enq_has_exception[i] <= ($urandom_range(0,99)<5);
        enq_trigger_dmode[i] <= 0;
        enq_allow_interrupt[i] <= ($urandom_range(0,99)<70);
        enq_num_wb[i] <= rnwb();
        enq_robidx_value[i] <= padd(tb_enq, i).value;
        enq_info[i] <= '0;
      end
      // writeback: 各口随机命中某个在飞 robIdx
      for (int i=0;i<NUM_EXU_WB;i++) begin
        wb_valid[i] <= ($urandom_range(0,99)<40);
        wb_robidx[i] <= $urandom_range(0,ROB_SIZE-1);
        wb_num[i] <= $urandom_range(0,2);
        wb_is_std[i] <= ($urandom_range(0,99)<20);
        wb_fflags_valid[i] <= ($urandom_range(0,99)<10); wb_fflags[i] <= $urandom_range(0,31);
        wb_vxsat_valid[i] <= ($urandom_range(0,99)<5); wb_vxsat[i] <= $urandom_range(0,1);
        wb_branch_taken[i] <= ($urandom_range(0,99)<10);
      end
      for (int i=0;i<NUM_WB;i++) begin
        excp_wb_valid[i] <= ($urandom_range(0,99)<8);
        excp_wb_robidx[i] <= $urandom_range(0,ROB_SIZE-1);
        excp_wb_need_flush[i] <= ($urandom_range(0,99)<30);
      end
      // exceptionGen: 偶发命中队头
      eg_valid <= ($urandom_range(0,99)<10);
      eg_robidx_flag <= tb_deq.flag; eg_robidx_value <= tb_deq.value;
      eg_is_exception <= ($urandom_range(0,99)<50); eg_flush_pipe <= ($urandom_range(0,99)<30);
      eg_replay_inst <= ($urandom_range(0,99)<10); eg_is_vls <= ($urandom_range(0,99)<10);
      io_csr_intrBitSet <= ($urandom_range(0,99)<3);
      io_csr_criticalErrorState <= 0; io_trace_blockCommit <= ($urandom_range(0,99)<2);
      io_snpt_useSnpt <= $urandom_range(0,1);
      io_fromVecExcpMod_busy <= ($urandom_range(0,99)<2);
      rab_can_enq <= ($urandom_range(0,99)<95);
      rab_can_enq_for_dispatch <= ($urandom_range(0,99)<95);
      rab_status_walk_end <= ($urandom_range(0,99)<60); vtype_status_walk_end <= ($urandom_range(0,99)<60);
      io_misPredWb <= ($urandom_range(0,99)<3);
      io_wb1_redir <= ($urandom_range(0,99)<8);
      io_wb3_redir <= ($urandom_range(0,99)<8);
      io_wb5_redir <= ($urandom_range(0,99)<8);
    end
  end
  // ---- 双核: SoA(B, 被测, 输出接 o_*) + packed-ref(A, 输出接 *_ref), 同激励 ----
  xs_Rob_core            u_soa (.*);
  xs_Rob_core_packed_ref u_ref (
    .*,
    .o_state(o_state_ref),
    .o_commits_isCommit(o_commits_isCommit_ref),
    .o_commits_isWalk(o_commits_isWalk_ref),
    .o_commits_commitValid(o_commits_commitValid_ref),
    .o_commits_walkValid(o_commits_walkValid_ref),
    .o_commit_info(o_commit_info_ref),
    .o_commits_robIdx(o_commits_robIdx_ref),
    .o_deq_commit_v(o_deq_commit_v_ref),
    .o_deq_commit_w(o_deq_commit_w_ref),
    .o_intrBitSetReg(o_intrBitSetReg_ref),
    .o_hasNoSpecExec(o_hasNoSpecExec_ref),
    .o_allowOnlyOneCommit(o_allowOnlyOneCommit_ref),
    .o_blockCommit(o_blockCommit_ref),
    .o_hasCommitted(o_hasCommitted_ref),
    .o_allCommitted(o_allCommitted_ref),
    .o_allowEnqueue(o_allowEnqueue_ref),
    .o_hasBlockBackward(o_hasBlockBackward_ref),
    .o_enq_for_ptr(o_enq_for_ptr_ref),
    .o_eg_flush(o_eg_flush_ref),
    .o_rab_commitSize(o_rab_commitSize_ref),
    .o_vtype_commitSize(o_vtype_commitSize_ref),
    .o_vtype_walkSize(o_vtype_walkSize_ref),
    .o_enq_isEmpty(o_enq_isEmpty_ref),
    .o_rab_walkSize(o_rab_walkSize_ref),
    .o_rab_walkEnd(o_rab_walkEnd_ref),
    .o_flushOut_valid(o_flushOut_valid_ref),
    .o_flushOut_robIdx_flag(o_flushOut_robIdx_flag_ref),
    .o_flushOut_robIdx_value(o_flushOut_robIdx_value_ref),
    .o_flushOut_level(o_flushOut_level_ref),
    .o_flushOut_isRVC(o_flushOut_isRVC_ref),
    .o_flushOut_ftqIdx_value(o_flushOut_ftqIdx_value_ref),
    .o_flushOut_ftqIdx_flag(o_flushOut_ftqIdx_flag_ref),
    .o_flushOut_ftqOffset(o_flushOut_ftqOffset_ref),
    .o_exception_valid(o_exception_valid_ref),
    .o_exceptionHappen(o_exceptionHappen_ref),
    .o_deqHasException(o_deqHasException_ref),
    .o_intrEnable(o_intrEnable_ref),
    .o_enq_canAccept(o_enq_canAccept_ref),
    .o_enq_canAcceptForDispatch(o_enq_canAcceptForDispatch_ref),
    .o_robFull(o_robFull_ref),
    .o_headNotReady(o_headNotReady_ref),
    .o_cpu_halt(o_cpu_halt_ref),
    .o_wfiReq(o_wfiReq_ref),
    .o_numValidEntries(o_numValidEntries_ref),
    .o_perf_0_value(o_perf_0_value_ref),
    .o_perf_1_value(o_perf_1_value_ref),
    .o_perf_2_value(o_perf_2_value_ref),
    .o_perf_3_value(o_perf_3_value_ref),
    .o_perf_4_value(o_perf_4_value_ref),
    .o_perf_5_value(o_perf_5_value_ref),
    .o_perf_6_value(o_perf_6_value_ref),
    .o_perf_7_value(o_perf_7_value_ref),
    .o_perf_8_value(o_perf_8_value_ref),
    .o_perf_9_value(o_perf_9_value_ref),
    .o_perf_10_value(o_perf_10_value_ref),
    .o_perf_11_value(o_perf_11_value_ref),
    .o_perf_12_value(o_perf_12_value_ref),
    .o_perf_13_value(o_perf_13_value_ref),
    .o_perf_14_value(o_perf_14_value_ref),
    .o_perf_15_value(o_perf_15_value_ref),
    .o_perf_16_value(o_perf_16_value_ref),
    .o_perf_17_value(o_perf_17_value_ref),
    .o_trace_valid(o_trace_valid_ref),
    .o_trace_ftqIdx_value(o_trace_ftqIdx_value_ref),
    .o_trace_ftqOffset(o_trace_ftqOffset_ref),
    .o_trace_itype(o_trace_itype_ref),
    .o_trace_iretire(o_trace_iretire_ref),
    .o_trace_ilastsize(o_trace_ilastsize_ref),
    .o_csr_fflags_valid(o_csr_fflags_valid_ref),
    .o_csr_fflags_bits(o_csr_fflags_bits_ref),
    .o_csr_vxsat_valid(o_csr_vxsat_valid_ref),
    .o_csr_vxsat_bits(o_csr_vxsat_bits_ref),
    .o_csr_vstart_valid(o_csr_vstart_valid_ref),
    .o_csr_vstart_bits(o_csr_vstart_bits_ref),
    .o_csr_dirty_fs(o_csr_dirty_fs_ref),
    .o_csr_dirty_vs(o_csr_dirty_vs_ref),
    .o_csr_perfinfo_retiredInstr(o_csr_perfinfo_retiredInstr_ref),
    .o_debugRobHead_fuType(o_debugRobHead_fuType_ref),
    .o_debugTopDown_robHeadLsIssue(o_debugTopDown_robHeadLsIssue_ref),
    .o_debugTopDown_robHeadVaddr_valid(o_debugTopDown_robHeadVaddr_valid_ref),
    .o_debugTopDown_robHeadVaddr_bits(o_debugTopDown_robHeadVaddr_bits_ref),
    .o_debugTopDown_robHeadPaddr_valid(o_debugTopDown_robHeadPaddr_valid_ref),
    .o_debugTopDown_robHeadPaddr_bits(o_debugTopDown_robHeadPaddr_bits_ref),
    .o_toVecExcpMod_excpInfo_valid(o_toVecExcpMod_excpInfo_valid_ref),
    .o_toVecExcpMod_excpInfo_bits_vstart(o_toVecExcpMod_excpInfo_bits_vstart_ref),
    .o_toVecExcpMod_excpInfo_bits_vsew(o_toVecExcpMod_excpInfo_bits_vsew_ref),
    .o_toVecExcpMod_excpInfo_bits_veew(o_toVecExcpMod_excpInfo_bits_veew_ref),
    .o_toVecExcpMod_excpInfo_bits_vlmul(o_toVecExcpMod_excpInfo_bits_vlmul_ref),
    .o_toVecExcpMod_excpInfo_bits_nf(o_toVecExcpMod_excpInfo_bits_nf_ref),
    .o_toVecExcpMod_excpInfo_bits_isStride(o_toVecExcpMod_excpInfo_bits_isStride_ref),
    .o_toVecExcpMod_excpInfo_bits_isIndexed(o_toVecExcpMod_excpInfo_bits_isIndexed_ref),
    .o_toVecExcpMod_excpInfo_bits_isWhole(o_toVecExcpMod_excpInfo_bits_isWhole_ref),
    .o_toVecExcpMod_excpInfo_bits_isVlm(o_toVecExcpMod_excpInfo_bits_isVlm_ref),
    .o_deq_entry_vls(o_deq_entry_vls_ref),
    .o_deq_entry_valid_0(o_deq_entry_valid_0_ref),
    .o_deq_entry_mmio_0(o_deq_entry_mmio_0_ref),
    .o_deqHasFlushed(o_deqHasFlushed_ref)
  );

  // ---- A/B co-sim: SoA vs packed-ref 逐拍全输出等价 ----
  logic [3:0] settle;
  always_ff @(posedge clk) if (rst) settle<=0; else if (settle!=4'hF) settle<=settle+1;
  always @(negedge clk) if (!rst && settle>4'd2) begin
    #4; checks++;
    if (o_state !== o_state_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_state soa=%p ref=%p",$time,o_state,o_state_ref); end
    if (o_commits_isCommit !== o_commits_isCommit_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_commits_isCommit soa=%p ref=%p",$time,o_commits_isCommit,o_commits_isCommit_ref); end
    if (o_commits_isWalk !== o_commits_isWalk_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_commits_isWalk soa=%p ref=%p",$time,o_commits_isWalk,o_commits_isWalk_ref); end
    if (o_commits_commitValid !== o_commits_commitValid_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_commits_commitValid soa=%p ref=%p",$time,o_commits_commitValid,o_commits_commitValid_ref); end
    if (o_commits_walkValid !== o_commits_walkValid_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_commits_walkValid soa=%p ref=%p",$time,o_commits_walkValid,o_commits_walkValid_ref); end
    for (int _j=0;_j<COMMIT_WIDTH;_j++) if (o_commit_info[_j] !== o_commit_info_ref[_j]) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_commit_info[%0d] soa=%p ref=%p",$time,_j,o_commit_info[_j],o_commit_info_ref[_j]); end
    for (int _j=0;_j<COMMIT_WIDTH;_j++) if (o_commits_robIdx[_j] !== o_commits_robIdx_ref[_j]) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_commits_robIdx[%0d] soa=%p ref=%p",$time,_j,o_commits_robIdx[_j],o_commits_robIdx_ref[_j]); end
    if (o_deq_commit_v !== o_deq_commit_v_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_deq_commit_v soa=%p ref=%p",$time,o_deq_commit_v,o_deq_commit_v_ref); end
    if (o_deq_commit_w !== o_deq_commit_w_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_deq_commit_w soa=%p ref=%p",$time,o_deq_commit_w,o_deq_commit_w_ref); end
    if (o_intrBitSetReg !== o_intrBitSetReg_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_intrBitSetReg soa=%p ref=%p",$time,o_intrBitSetReg,o_intrBitSetReg_ref); end
    if (o_hasNoSpecExec !== o_hasNoSpecExec_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_hasNoSpecExec soa=%p ref=%p",$time,o_hasNoSpecExec,o_hasNoSpecExec_ref); end
    if (o_allowOnlyOneCommit !== o_allowOnlyOneCommit_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_allowOnlyOneCommit soa=%p ref=%p",$time,o_allowOnlyOneCommit,o_allowOnlyOneCommit_ref); end
    if (o_blockCommit !== o_blockCommit_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_blockCommit soa=%p ref=%p",$time,o_blockCommit,o_blockCommit_ref); end
    if (o_hasCommitted !== o_hasCommitted_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_hasCommitted soa=%p ref=%p",$time,o_hasCommitted,o_hasCommitted_ref); end
    if (o_allCommitted !== o_allCommitted_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_allCommitted soa=%p ref=%p",$time,o_allCommitted,o_allCommitted_ref); end
    if (o_allowEnqueue !== o_allowEnqueue_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_allowEnqueue soa=%p ref=%p",$time,o_allowEnqueue,o_allowEnqueue_ref); end
    if (o_hasBlockBackward !== o_hasBlockBackward_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_hasBlockBackward soa=%p ref=%p",$time,o_hasBlockBackward,o_hasBlockBackward_ref); end
    if (o_enq_for_ptr !== o_enq_for_ptr_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_enq_for_ptr soa=%p ref=%p",$time,o_enq_for_ptr,o_enq_for_ptr_ref); end
    if (o_eg_flush !== o_eg_flush_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_eg_flush soa=%p ref=%p",$time,o_eg_flush,o_eg_flush_ref); end
    if (o_rab_commitSize !== o_rab_commitSize_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_rab_commitSize soa=%p ref=%p",$time,o_rab_commitSize,o_rab_commitSize_ref); end
    if (o_vtype_commitSize !== o_vtype_commitSize_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_vtype_commitSize soa=%p ref=%p",$time,o_vtype_commitSize,o_vtype_commitSize_ref); end
    if (o_vtype_walkSize !== o_vtype_walkSize_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_vtype_walkSize soa=%p ref=%p",$time,o_vtype_walkSize,o_vtype_walkSize_ref); end
    if (o_enq_isEmpty !== o_enq_isEmpty_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_enq_isEmpty soa=%p ref=%p",$time,o_enq_isEmpty,o_enq_isEmpty_ref); end
    if (o_rab_walkSize !== o_rab_walkSize_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_rab_walkSize soa=%p ref=%p",$time,o_rab_walkSize,o_rab_walkSize_ref); end
    if (o_rab_walkEnd !== o_rab_walkEnd_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_rab_walkEnd soa=%p ref=%p",$time,o_rab_walkEnd,o_rab_walkEnd_ref); end
    if (o_flushOut_valid !== o_flushOut_valid_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_flushOut_valid soa=%p ref=%p",$time,o_flushOut_valid,o_flushOut_valid_ref); end
    if (o_flushOut_robIdx_flag !== o_flushOut_robIdx_flag_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_flushOut_robIdx_flag soa=%p ref=%p",$time,o_flushOut_robIdx_flag,o_flushOut_robIdx_flag_ref); end
    if (o_flushOut_robIdx_value !== o_flushOut_robIdx_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_flushOut_robIdx_value soa=%p ref=%p",$time,o_flushOut_robIdx_value,o_flushOut_robIdx_value_ref); end
    if (o_flushOut_level !== o_flushOut_level_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_flushOut_level soa=%p ref=%p",$time,o_flushOut_level,o_flushOut_level_ref); end
    if (o_flushOut_isRVC !== o_flushOut_isRVC_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_flushOut_isRVC soa=%p ref=%p",$time,o_flushOut_isRVC,o_flushOut_isRVC_ref); end
    if (o_flushOut_ftqIdx_value !== o_flushOut_ftqIdx_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_flushOut_ftqIdx_value soa=%p ref=%p",$time,o_flushOut_ftqIdx_value,o_flushOut_ftqIdx_value_ref); end
    if (o_flushOut_ftqIdx_flag !== o_flushOut_ftqIdx_flag_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_flushOut_ftqIdx_flag soa=%p ref=%p",$time,o_flushOut_ftqIdx_flag,o_flushOut_ftqIdx_flag_ref); end
    if (o_flushOut_ftqOffset !== o_flushOut_ftqOffset_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_flushOut_ftqOffset soa=%p ref=%p",$time,o_flushOut_ftqOffset,o_flushOut_ftqOffset_ref); end
    if (o_exception_valid !== o_exception_valid_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_exception_valid soa=%p ref=%p",$time,o_exception_valid,o_exception_valid_ref); end
    if (o_exceptionHappen !== o_exceptionHappen_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_exceptionHappen soa=%p ref=%p",$time,o_exceptionHappen,o_exceptionHappen_ref); end
    if (o_deqHasException !== o_deqHasException_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_deqHasException soa=%p ref=%p",$time,o_deqHasException,o_deqHasException_ref); end
    if (o_intrEnable !== o_intrEnable_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_intrEnable soa=%p ref=%p",$time,o_intrEnable,o_intrEnable_ref); end
    if (o_enq_canAccept !== o_enq_canAccept_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_enq_canAccept soa=%p ref=%p",$time,o_enq_canAccept,o_enq_canAccept_ref); end
    if (o_enq_canAcceptForDispatch !== o_enq_canAcceptForDispatch_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_enq_canAcceptForDispatch soa=%p ref=%p",$time,o_enq_canAcceptForDispatch,o_enq_canAcceptForDispatch_ref); end
    if (o_robFull !== o_robFull_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_robFull soa=%p ref=%p",$time,o_robFull,o_robFull_ref); end
    if (o_headNotReady !== o_headNotReady_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_headNotReady soa=%p ref=%p",$time,o_headNotReady,o_headNotReady_ref); end
    if (o_cpu_halt !== o_cpu_halt_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_cpu_halt soa=%p ref=%p",$time,o_cpu_halt,o_cpu_halt_ref); end
    if (o_wfiReq !== o_wfiReq_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_wfiReq soa=%p ref=%p",$time,o_wfiReq,o_wfiReq_ref); end
    if (o_numValidEntries !== o_numValidEntries_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_numValidEntries soa=%p ref=%p",$time,o_numValidEntries,o_numValidEntries_ref); end
    if (o_perf_0_value !== o_perf_0_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_0_value soa=%p ref=%p",$time,o_perf_0_value,o_perf_0_value_ref); end
    if (o_perf_1_value !== o_perf_1_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_1_value soa=%p ref=%p",$time,o_perf_1_value,o_perf_1_value_ref); end
    if (o_perf_2_value !== o_perf_2_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_2_value soa=%p ref=%p",$time,o_perf_2_value,o_perf_2_value_ref); end
    if (o_perf_3_value !== o_perf_3_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_3_value soa=%p ref=%p",$time,o_perf_3_value,o_perf_3_value_ref); end
    if (o_perf_4_value !== o_perf_4_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_4_value soa=%p ref=%p",$time,o_perf_4_value,o_perf_4_value_ref); end
    if (o_perf_5_value !== o_perf_5_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_5_value soa=%p ref=%p",$time,o_perf_5_value,o_perf_5_value_ref); end
    if (o_perf_6_value !== o_perf_6_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_6_value soa=%p ref=%p",$time,o_perf_6_value,o_perf_6_value_ref); end
    if (o_perf_7_value !== o_perf_7_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_7_value soa=%p ref=%p",$time,o_perf_7_value,o_perf_7_value_ref); end
    if (o_perf_8_value !== o_perf_8_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_8_value soa=%p ref=%p",$time,o_perf_8_value,o_perf_8_value_ref); end
    if (o_perf_9_value !== o_perf_9_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_9_value soa=%p ref=%p",$time,o_perf_9_value,o_perf_9_value_ref); end
    if (o_perf_10_value !== o_perf_10_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_10_value soa=%p ref=%p",$time,o_perf_10_value,o_perf_10_value_ref); end
    if (o_perf_11_value !== o_perf_11_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_11_value soa=%p ref=%p",$time,o_perf_11_value,o_perf_11_value_ref); end
    if (o_perf_12_value !== o_perf_12_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_12_value soa=%p ref=%p",$time,o_perf_12_value,o_perf_12_value_ref); end
    if (o_perf_13_value !== o_perf_13_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_13_value soa=%p ref=%p",$time,o_perf_13_value,o_perf_13_value_ref); end
    if (o_perf_14_value !== o_perf_14_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_14_value soa=%p ref=%p",$time,o_perf_14_value,o_perf_14_value_ref); end
    if (o_perf_15_value !== o_perf_15_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_15_value soa=%p ref=%p",$time,o_perf_15_value,o_perf_15_value_ref); end
    if (o_perf_16_value !== o_perf_16_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_16_value soa=%p ref=%p",$time,o_perf_16_value,o_perf_16_value_ref); end
    if (o_perf_17_value !== o_perf_17_value_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_perf_17_value soa=%p ref=%p",$time,o_perf_17_value,o_perf_17_value_ref); end
    if (o_trace_valid !== o_trace_valid_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_trace_valid soa=%p ref=%p",$time,o_trace_valid,o_trace_valid_ref); end
    for (int _j=0;_j<COMMIT_WIDTH;_j++) if (o_trace_ftqIdx_value[_j] !== o_trace_ftqIdx_value_ref[_j]) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_trace_ftqIdx_value[%0d] soa=%p ref=%p",$time,_j,o_trace_ftqIdx_value[_j],o_trace_ftqIdx_value_ref[_j]); end
    for (int _j=0;_j<COMMIT_WIDTH;_j++) if (o_trace_ftqOffset[_j] !== o_trace_ftqOffset_ref[_j]) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_trace_ftqOffset[%0d] soa=%p ref=%p",$time,_j,o_trace_ftqOffset[_j],o_trace_ftqOffset_ref[_j]); end
    for (int _j=0;_j<COMMIT_WIDTH;_j++) if (o_trace_itype[_j] !== o_trace_itype_ref[_j]) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_trace_itype[%0d] soa=%p ref=%p",$time,_j,o_trace_itype[_j],o_trace_itype_ref[_j]); end
    for (int _j=0;_j<COMMIT_WIDTH;_j++) if (o_trace_iretire[_j] !== o_trace_iretire_ref[_j]) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_trace_iretire[%0d] soa=%p ref=%p",$time,_j,o_trace_iretire[_j],o_trace_iretire_ref[_j]); end
    if (o_trace_ilastsize !== o_trace_ilastsize_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_trace_ilastsize soa=%p ref=%p",$time,o_trace_ilastsize,o_trace_ilastsize_ref); end
    if (o_csr_fflags_valid !== o_csr_fflags_valid_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_csr_fflags_valid soa=%p ref=%p",$time,o_csr_fflags_valid,o_csr_fflags_valid_ref); end
    if (o_csr_fflags_bits !== o_csr_fflags_bits_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_csr_fflags_bits soa=%p ref=%p",$time,o_csr_fflags_bits,o_csr_fflags_bits_ref); end
    if (o_csr_vxsat_valid !== o_csr_vxsat_valid_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_csr_vxsat_valid soa=%p ref=%p",$time,o_csr_vxsat_valid,o_csr_vxsat_valid_ref); end
    if (o_csr_vxsat_bits !== o_csr_vxsat_bits_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_csr_vxsat_bits soa=%p ref=%p",$time,o_csr_vxsat_bits,o_csr_vxsat_bits_ref); end
    if (o_csr_vstart_valid !== o_csr_vstart_valid_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_csr_vstart_valid soa=%p ref=%p",$time,o_csr_vstart_valid,o_csr_vstart_valid_ref); end
    if (o_csr_vstart_bits !== o_csr_vstart_bits_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_csr_vstart_bits soa=%p ref=%p",$time,o_csr_vstart_bits,o_csr_vstart_bits_ref); end
    if (o_csr_dirty_fs !== o_csr_dirty_fs_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_csr_dirty_fs soa=%p ref=%p",$time,o_csr_dirty_fs,o_csr_dirty_fs_ref); end
    if (o_csr_dirty_vs !== o_csr_dirty_vs_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_csr_dirty_vs soa=%p ref=%p",$time,o_csr_dirty_vs,o_csr_dirty_vs_ref); end
    if (o_csr_perfinfo_retiredInstr !== o_csr_perfinfo_retiredInstr_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_csr_perfinfo_retiredInstr soa=%p ref=%p",$time,o_csr_perfinfo_retiredInstr,o_csr_perfinfo_retiredInstr_ref); end
    if (o_debugRobHead_fuType !== o_debugRobHead_fuType_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_debugRobHead_fuType soa=%p ref=%p",$time,o_debugRobHead_fuType,o_debugRobHead_fuType_ref); end
    if (o_debugTopDown_robHeadLsIssue !== o_debugTopDown_robHeadLsIssue_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_debugTopDown_robHeadLsIssue soa=%p ref=%p",$time,o_debugTopDown_robHeadLsIssue,o_debugTopDown_robHeadLsIssue_ref); end
    if (o_debugTopDown_robHeadVaddr_valid !== o_debugTopDown_robHeadVaddr_valid_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_debugTopDown_robHeadVaddr_valid soa=%p ref=%p",$time,o_debugTopDown_robHeadVaddr_valid,o_debugTopDown_robHeadVaddr_valid_ref); end
    if (o_debugTopDown_robHeadVaddr_bits !== o_debugTopDown_robHeadVaddr_bits_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_debugTopDown_robHeadVaddr_bits soa=%p ref=%p",$time,o_debugTopDown_robHeadVaddr_bits,o_debugTopDown_robHeadVaddr_bits_ref); end
    if (o_debugTopDown_robHeadPaddr_valid !== o_debugTopDown_robHeadPaddr_valid_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_debugTopDown_robHeadPaddr_valid soa=%p ref=%p",$time,o_debugTopDown_robHeadPaddr_valid,o_debugTopDown_robHeadPaddr_valid_ref); end
    if (o_debugTopDown_robHeadPaddr_bits !== o_debugTopDown_robHeadPaddr_bits_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_debugTopDown_robHeadPaddr_bits soa=%p ref=%p",$time,o_debugTopDown_robHeadPaddr_bits,o_debugTopDown_robHeadPaddr_bits_ref); end
    if (o_toVecExcpMod_excpInfo_valid !== o_toVecExcpMod_excpInfo_valid_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_toVecExcpMod_excpInfo_valid soa=%p ref=%p",$time,o_toVecExcpMod_excpInfo_valid,o_toVecExcpMod_excpInfo_valid_ref); end
    if (o_toVecExcpMod_excpInfo_bits_vstart !== o_toVecExcpMod_excpInfo_bits_vstart_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_toVecExcpMod_excpInfo_bits_vstart soa=%p ref=%p",$time,o_toVecExcpMod_excpInfo_bits_vstart,o_toVecExcpMod_excpInfo_bits_vstart_ref); end
    if (o_toVecExcpMod_excpInfo_bits_vsew !== o_toVecExcpMod_excpInfo_bits_vsew_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_toVecExcpMod_excpInfo_bits_vsew soa=%p ref=%p",$time,o_toVecExcpMod_excpInfo_bits_vsew,o_toVecExcpMod_excpInfo_bits_vsew_ref); end
    if (o_toVecExcpMod_excpInfo_bits_veew !== o_toVecExcpMod_excpInfo_bits_veew_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_toVecExcpMod_excpInfo_bits_veew soa=%p ref=%p",$time,o_toVecExcpMod_excpInfo_bits_veew,o_toVecExcpMod_excpInfo_bits_veew_ref); end
    if (o_toVecExcpMod_excpInfo_bits_vlmul !== o_toVecExcpMod_excpInfo_bits_vlmul_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_toVecExcpMod_excpInfo_bits_vlmul soa=%p ref=%p",$time,o_toVecExcpMod_excpInfo_bits_vlmul,o_toVecExcpMod_excpInfo_bits_vlmul_ref); end
    if (o_toVecExcpMod_excpInfo_bits_nf !== o_toVecExcpMod_excpInfo_bits_nf_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_toVecExcpMod_excpInfo_bits_nf soa=%p ref=%p",$time,o_toVecExcpMod_excpInfo_bits_nf,o_toVecExcpMod_excpInfo_bits_nf_ref); end
    if (o_toVecExcpMod_excpInfo_bits_isStride !== o_toVecExcpMod_excpInfo_bits_isStride_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_toVecExcpMod_excpInfo_bits_isStride soa=%p ref=%p",$time,o_toVecExcpMod_excpInfo_bits_isStride,o_toVecExcpMod_excpInfo_bits_isStride_ref); end
    if (o_toVecExcpMod_excpInfo_bits_isIndexed !== o_toVecExcpMod_excpInfo_bits_isIndexed_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_toVecExcpMod_excpInfo_bits_isIndexed soa=%p ref=%p",$time,o_toVecExcpMod_excpInfo_bits_isIndexed,o_toVecExcpMod_excpInfo_bits_isIndexed_ref); end
    if (o_toVecExcpMod_excpInfo_bits_isWhole !== o_toVecExcpMod_excpInfo_bits_isWhole_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_toVecExcpMod_excpInfo_bits_isWhole soa=%p ref=%p",$time,o_toVecExcpMod_excpInfo_bits_isWhole,o_toVecExcpMod_excpInfo_bits_isWhole_ref); end
    if (o_toVecExcpMod_excpInfo_bits_isVlm !== o_toVecExcpMod_excpInfo_bits_isVlm_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_toVecExcpMod_excpInfo_bits_isVlm soa=%p ref=%p",$time,o_toVecExcpMod_excpInfo_bits_isVlm,o_toVecExcpMod_excpInfo_bits_isVlm_ref); end
    if (o_deq_entry_vls !== o_deq_entry_vls_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_deq_entry_vls soa=%p ref=%p",$time,o_deq_entry_vls,o_deq_entry_vls_ref); end
    if (o_deq_entry_valid_0 !== o_deq_entry_valid_0_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_deq_entry_valid_0 soa=%p ref=%p",$time,o_deq_entry_valid_0,o_deq_entry_valid_0_ref); end
    if (o_deq_entry_mmio_0 !== o_deq_entry_mmio_0_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_deq_entry_mmio_0 soa=%p ref=%p",$time,o_deq_entry_mmio_0,o_deq_entry_mmio_0_ref); end
    if (o_deqHasFlushed !== o_deqHasFlushed_ref) begin errors++; if(errors<=80) $display("[%0t] MISMATCH o_deqHasFlushed soa=%p ref=%p",$time,o_deqHasFlushed,o_deqHasFlushed_ref); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule