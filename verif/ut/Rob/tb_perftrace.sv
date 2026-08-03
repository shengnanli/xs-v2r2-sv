// tb_perftrace.sv — 局部验证 xs_Rob_core 的 perf(18)+trace(48)=66 个 C_DEEP 端口
// owner: rob-perf-trace (codex 0090 P2)
//
// 方法: 复用 smoke tb 的随机激励驱动 u_core, 另建一个「golden 公式参考块」,
//   逐字复刻 golden Rob.sv 的 perf/trace 状态方程, 其输入 = 核内部信号
//   (层次探针 u_core.<sig>) 与核对外提交输出 (o_commits_*, o_commit_info)。
//   每拍比对 66 个端口 vs 参考, 任一失配 errors++。
//
//   关键: 参考块用的所有输入都取自「核内部/核输出」的同一份信号, 因此比对证明
//   「核的 perf/trace RTL == golden perf/trace 公式」(给定相同上游信号), 即
//   忠实复刻。golden 端口的深数据通路上游 (commitValid/commitInfo/flushOut/...)
//   由核控制锥产生, 在 assembly FM 里再与 golden 端口面对齐。

`timescale 1ns/1ps
import rob_pkg::*;
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int perr = 0, terr = 0;
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
  logic io_wb1_redir, io_wb3_redir, io_wb5_redir;   // <-- 新增 (perf_16)
  // ---- 核输出 ----
  rob_state_e o_state;
  logic o_commits_isCommit, o_commits_isWalk;
  logic [COMMIT_WIDTH-1:0] o_commits_commitValid, o_commits_walkValid;
  rob_commit_entry_t o_commit_info [COMMIT_WIDTH]; rob_ptr_t o_commits_robIdx [COMMIT_WIDTH];
  logic [COMMIT_WIDTH-1:0] o_deq_commit_v, o_deq_commit_w, o_hasCommitted;
  logic o_intrBitSetReg, o_hasNoSpecExec, o_allowOnlyOneCommit, o_blockCommit, o_allCommitted;
  logic o_allowEnqueue, o_hasBlockBackward; logic [RENAME_WIDTH-1:0] o_enq_for_ptr;
  logic o_eg_flush; logic [UOP_CNT_W:0] o_rab_commitSize, o_rab_walkSize; logic o_rab_walkEnd;
  logic o_flushOut_valid, o_flushOut_robIdx_flag; logic [PTR_W-1:0] o_flushOut_robIdx_value;
  logic o_flushOut_level, o_flushOut_isRVC; logic [FTQ_PTR_W-1:0] o_flushOut_ftqIdx_value;
  logic o_flushOut_ftqIdx_flag; logic [FTQ_OFFSET_W-1:0] o_flushOut_ftqOffset;
  logic o_exception_valid, o_intrEnable;
  logic o_enq_canAccept, o_enq_canAcceptForDispatch, o_robFull, o_headNotReady;
  logic o_cpu_halt, o_wfiReq; logic [PTR_W:0] o_numValidEntries;
  // perf/trace 输出 (被验对象)
  logic [5:0] o_perf_0_value,o_perf_1_value,o_perf_2_value,o_perf_3_value,o_perf_4_value,
              o_perf_5_value,o_perf_6_value,o_perf_7_value,o_perf_8_value,o_perf_9_value,
              o_perf_10_value,o_perf_11_value,o_perf_12_value,o_perf_13_value,o_perf_14_value,
              o_perf_15_value,o_perf_16_value,o_perf_17_value;
  logic [COMMIT_WIDTH-1:0] o_trace_valid, o_trace_ilastsize;
  logic [FTQ_PTR_W-1:0]    o_trace_ftqIdx_value [COMMIT_WIDTH];
  logic [FTQ_OFFSET_W-1:0] o_trace_ftqOffset    [COMMIT_WIDTH];
  logic [ITYPE_W-1:0]      o_trace_itype        [COMMIT_WIDTH];
  logic [IRETIRE_W-1:0]    o_trace_iretire      [COMMIT_WIDTH];

  // ---- tb 环形指针模型 ----
  rob_ptr_t tb_enq, tb_deq;
  function automatic rob_ptr_t padd(input rob_ptr_t p, input int unsigned n);
    int unsigned v; rob_ptr_t o;
    v = p.value + n;
    if (v >= ROB_SIZE) begin o.value = v - ROB_SIZE; o.flag = ~p.flag; end
    else begin o.value = v[PTR_W-1:0]; o.flag = p.flag; end
    return o;
  endfunction
  int unsigned enq_cnt, commit_cnt;
  always_comb begin
    enq_cnt = 0;
    for (int i=0;i<RENAME_WIDTH;i++) if (o_enq_for_ptr[i] && o_enq_canAccept) enq_cnt++;
    commit_cnt = 0;
    for (int i=0;i<COMMIT_WIDTH;i++) if (o_commits_isCommit && o_commits_commitValid[i]) commit_cnt++;
  end
  always_comb begin
    for (int i=0;i<RENAME_WIDTH;i++) enq_ptr_vec[i] = padd(tb_enq, i);
    for (int i=0;i<COMMIT_WIDTH;i++) deq_ptr_vec[i] = padd(tb_deq, i);
    deq_ptr_next0 = padd(tb_deq, commit_cnt);
    snap_ptr0 = tb_deq;
  end

  logic clock, reset; assign clock = clk; assign reset = rst;
  xs_Rob_core u_core (.*);

  always_ff @(posedge clk) begin
    if (rst) begin tb_enq <= '0; tb_deq <= '0; end
    else begin
      if (io_redirect_valid)
        tb_enq <= '{flag:io_redirect_bits_robIdx_flag, value:io_redirect_bits_robIdx_value};
      else tb_enq <= padd(tb_enq, enq_cnt);
      tb_deq <= padd(tb_deq, commit_cnt);
    end
  end

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
        // enq_info: 随机 commit_type / instr_size / trace 字段, 制造 perf/trace 多样性
        enq_info[i] <= '0;
        enq_info[i].commit_type <= $urandom_range(0,4);
        enq_info[i].instr_size  <= $urandom_range(0,4);
        enq_info[i].is_rvc      <= $urandom_range(0,1);
        enq_info[i].itype       <= $urandom_range(0,15);
        enq_info[i].iretire     <= $urandom_range(0,15);
        enq_info[i].ilastsize   <= $urandom_range(0,3);
        enq_info[i].ftq_offset  <= $urandom_range(0,15);
        enq_info[i].ftq_idx_value <= $urandom_range(0,63);
      end
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

  // =====================================================================
  // golden 公式参考块 —— 输入取自核内部/核输出的同一份信号 (层次探针)。
  // =====================================================================
  // 层次探针别名 (核内部信号)
  wire        u_intrEnable       = u_core.intrEnable;
  wire        u_deqHasException  = u_core.deqHasException;
  wire        u_isFlushPipe      = u_core.isFlushPipe;
  wire        u_deqHasReplayInst = u_core.deqHasReplayInst;
  wire        u_exceptionHappen  = u_core.exceptionHappen;
  wire        u_exceptionValidReg= u_core.exceptionValidReg;
  wire [7:0]  u_numVE8           = u_core.numValidEntries[7:0];
  wire [COMMIT_WIDTH-1:0] u_shouldWalkVec = u_core.shouldWalkVec;
  // commitInfo (= robDeqGroup[deqPtr_N bank]) — 与核 trace 同源
  rob_commit_entry_t u_cinfo [COMMIT_WIDTH];
  always_comb for (int i=0;i<COMMIT_WIDTH;i++) u_cinfo[i] = u_core.commitInfo[i];

  // popcount
  function automatic logic [3:0] rpc8(input logic [COMMIT_WIDTH-1:0] v);
    logic [3:0] s; s='0; for (int i=0;i<COMMIT_WIDTH;i++) s += 4'(v[i]); return s;
  endfunction

  // 分类向量
  logic [COMMIT_WIDTH-1:0] rLoad,rBranch,rStore,rFuse;
  always_comb for (int i=0;i<COMMIT_WIDTH;i++) begin
    rLoad[i]   = o_commits_commitValid[i] & (u_cinfo[i].commit_type==3'h2);
    rBranch[i] = o_commits_commitValid[i] & (u_cinfo[i].commit_type==3'h1);
    rStore[i]  = o_commits_commitValid[i] & (u_cinfo[i].commit_type==3'h3);
    rFuse[i]   = o_commits_commitValid[i] &  u_cinfo[i].commit_type[2];
  end

  // RegEnable 族 + RegNext(isCommit) + trueCommitCnt (参考实现, 独立复刻)
  logic rIsCommitLast;
  logic [COMMIT_WIDTH-1:0] rLoad_r,rBranch_r,rStore_r,rFuse_r;
  logic [9:0] rTrueCC;
  logic rIsInterrupt;
  logic [9:0] rTrueCC_next;
  always_comb begin
    rTrueCC_next='0;
    for (int i=0;i<COMMIT_WIDTH;i++) if (o_commits_commitValid[i]) rTrueCC_next += 10'(u_cinfo[i].instr_size);
  end
  always_ff @(posedge clk or posedge rst)
    if (rst) begin rIsCommitLast<=0; rLoad_r<='0; rBranch_r<='0; rStore_r<='0; rFuse_r<='0; rTrueCC<='0; end
    else begin
      rIsCommitLast <= o_commits_isCommit;
      if (o_commits_isCommit) begin
        rLoad_r<=rLoad; rBranch_r<=rBranch; rStore_r<=rStore; rFuse_r<=rFuse; rTrueCC<=rTrueCC_next;
      end
    end
  always_ff @(posedge clk or posedge rst)
    if (rst) rIsInterrupt<=0; else if (u_exceptionHappen) rIsInterrupt<=u_intrEnable;

  logic [3:0] rFuseCC; always_comb rFuseCC = rpc8(rFuse_r);
  logic [10:0] rRetire; always_comb rRetire = rIsCommitLast ? (11'({1'b0,rTrueCC})+11'({7'h0,rFuseCC})) : 11'h0;
  logic [3:0] rCommitCnt; always_comb rCommitCnt = o_commits_isCommit ? rpc8(o_commits_commitValid) : 4'h0;
  logic [3:0] rWalkCnt; always_comb rWalkCnt = (o_state==S_WALK) ? rpc8(u_shouldWalkVec) : 4'h0;
  logic [2:0] rMisPred; always_comb begin
    logic [1:0] mp; mp = 2'({1'b0,io_wb1_redir})+2'({1'b0,io_wb3_redir})+2'({1'b0,io_wb5_redir});
    rMisPred = 3'({1'b0,mp})+3'({1'b0,mp});
  end
  // src
  logic rp0,rp1,rp2,rp3,rp11,rp12,rp13,rp14,rp15,rp17;
  always_comb begin
    rp0  = o_flushOut_valid & u_intrEnable;
    rp1  = o_flushOut_valid & u_deqHasException;
    rp2  = o_flushOut_valid & u_isFlushPipe;
    rp3  = rp2 & u_deqHasReplayInst;
    rp11 = (o_state==S_WALK);
    rp12 = u_numVE8 <  8'h29;
    rp13 = (u_numVE8 > 8'h28) & (u_numVE8 < 8'h51);
    rp14 = (u_numVE8 > 8'h50) & (u_numVE8 < 8'h79);
    rp15 = u_numVE8 >  8'h78;
    rp17 = o_flushOut_valid;
  end
  // 2 拍寄存器 (参考)
  logic       q0,q0b,q1,q1b,q2,q2b,q3,q3b,q11,q11b,q12,q12b,q13,q13b,q14,q14b,q15,q15b,q17,q17b;
  logic [3:0] q4,q4b,q6,q6b,q7,q7b,q8,q8b,q9,q9b,q10,q10b;
  logic [10:0] q5,q5b; logic [2:0] q16,q16b;
  always_ff @(posedge clk) begin
    q0<=rp0; q1<=rp1; q2<=rp2; q3<=rp3; q4<=rCommitCnt; q5<=rRetire;
    q6<= rIsCommitLast ? rFuseCC : 4'h0;
    q7<= rIsCommitLast ? rpc8(rLoad_r)   : 4'h0;
    q8<= rIsCommitLast ? rpc8(rBranch_r) : 4'h0;
    q9<= rIsCommitLast ? rpc8(rStore_r)  : 4'h0;
    q10<=rWalkCnt; q11<=rp11; q12<=rp12; q13<=rp13; q14<=rp14; q15<=rp15; q16<=rMisPred; q17<=rp17;
    q0b<=q0; q1b<=q1; q2b<=q2; q3b<=q3; q4b<=q4; q5b<=q5; q6b<=q6; q7b<=q7; q8b<=q8; q9b<=q9;
    q10b<=q10; q11b<=q11; q12b<=q12; q13b<=q13; q14b<=q14; q15b<=q15; q16b<=q16; q17b<=q17;
  end
  // 参考端口
  logic [5:0] rperf [18];
  always_comb begin
    rperf[0]={5'h0,q0b}; rperf[1]={5'h0,q1b}; rperf[2]={5'h0,q2b}; rperf[3]={5'h0,q3b};
    rperf[4]={2'h0,q4b}; rperf[5]=q5b[5:0]; rperf[6]={2'h0,q6b}; rperf[7]={2'h0,q7b};
    rperf[8]={2'h0,q8b}; rperf[9]={2'h0,q9b}; rperf[10]={2'h0,q10b}; rperf[11]={5'h0,q11b};
    rperf[12]={5'h0,q12b}; rperf[13]={5'h0,q13b}; rperf[14]={5'h0,q14b}; rperf[15]={5'h0,q15b};
    rperf[16]={3'h0,q16b}; rperf[17]={5'h0,q17b};
  end
  logic [5:0] dperf [18];
  always_comb begin
    dperf[0]=o_perf_0_value; dperf[1]=o_perf_1_value; dperf[2]=o_perf_2_value; dperf[3]=o_perf_3_value;
    dperf[4]=o_perf_4_value; dperf[5]=o_perf_5_value; dperf[6]=o_perf_6_value; dperf[7]=o_perf_7_value;
    dperf[8]=o_perf_8_value; dperf[9]=o_perf_9_value; dperf[10]=o_perf_10_value; dperf[11]=o_perf_11_value;
    dperf[12]=o_perf_12_value; dperf[13]=o_perf_13_value; dperf[14]=o_perf_14_value; dperf[15]=o_perf_15_value;
    dperf[16]=o_perf_16_value; dperf[17]=o_perf_17_value;
  end

  // 参考 trace
  logic [COMMIT_WIDTH-1:0] rt_valid, rt_ilast;
  logic [FTQ_PTR_W-1:0]    rt_ftqidx [COMMIT_WIDTH];
  logic [FTQ_OFFSET_W-1:0] rt_ftqoff [COMMIT_WIDTH];
  logic [ITYPE_W-1:0]      rt_itype  [COMMIT_WIDTH];
  logic [IRETIRE_W-1:0]    rt_iret   [COMMIT_WIDTH];
  always_comb begin
    for (int i=0;i<COMMIT_WIDTH;i++) begin
      rt_valid[i]  = o_commits_isCommit & o_commits_commitValid[i];
      rt_ftqidx[i] = u_cinfo[i].ftq_idx_value;
      rt_ftqoff[i] = u_cinfo[i].ftq_offset;
      rt_itype[i]  = u_cinfo[i].itype;
      rt_iret[i]   = u_cinfo[i].iretire;
      rt_ilast[i]  = u_cinfo[i].ilastsize;
    end
    rt_valid[0]  = u_exceptionValidReg | (o_commits_isCommit & o_commits_commitValid[0]);
    rt_itype[0]  = u_exceptionValidReg ? {2'h0,(rIsInterrupt?2'h2:2'h1)} : u_cinfo[0].itype;
    rt_iret[0]   = u_exceptionValidReg ? 4'h0 : u_cinfo[0].iretire;
  end

  // =====================================================================
  // 比对
  // =====================================================================
  int settle;
  always_ff @(posedge clk) if (rst) settle<=0; else if (settle<8) settle<=settle+1;
  always @(negedge clk) if (!rst && settle>=6) begin
    #4; checks++;
    for (int k=0;k<18;k++)
      if (dperf[k] !== rperf[k]) begin
        perr++; errors++;
        if (errors<=60) $display("[%0t] PERF[%0d] mismatch dut=%h ref=%h",$time,k,dperf[k],rperf[k]);
      end
    for (int i=0;i<COMMIT_WIDTH;i++) begin
      if (o_trace_valid[i]        !== rt_valid[i])  begin terr++; errors++; if(errors<=60) $display("[%0t] TRACE valid[%0d] dut=%b ref=%b",$time,i,o_trace_valid[i],rt_valid[i]); end
      if (o_trace_ftqIdx_value[i] !== rt_ftqidx[i]) begin terr++; errors++; if(errors<=60) $display("[%0t] TRACE ftqIdx[%0d] dut=%h ref=%h",$time,i,o_trace_ftqIdx_value[i],rt_ftqidx[i]); end
      if (o_trace_ftqOffset[i]    !== rt_ftqoff[i]) begin terr++; errors++; if(errors<=60) $display("[%0t] TRACE ftqOff[%0d] dut=%h ref=%h",$time,i,o_trace_ftqOffset[i],rt_ftqoff[i]); end
      if (o_trace_itype[i]        !== rt_itype[i])  begin terr++; errors++; if(errors<=60) $display("[%0t] TRACE itype[%0d] dut=%h ref=%h",$time,i,o_trace_itype[i],rt_itype[i]); end
      if (o_trace_iretire[i]      !== rt_iret[i])   begin terr++; errors++; if(errors<=60) $display("[%0t] TRACE iret[%0d] dut=%h ref=%h",$time,i,o_trace_iretire[i],rt_iret[i]); end
      if (o_trace_ilastsize[i]    !== rt_ilast[i])  begin terr++; errors++; if(errors<=60) $display("[%0t] TRACE ilast[%0d] dut=%b ref=%b",$time,i,o_trace_ilastsize[i],rt_ilast[i]); end
    end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d (perf_err=%0d trace_err=%0d)", checks, errors, perr, terr);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
