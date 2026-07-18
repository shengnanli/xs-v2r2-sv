// §6/§7  topdown + perf
// -----------------------------------------------------------------------------
//  topdown：在所有 allocated 且 debug_vaddr == robHeadVaddr 的 entry 中，按 robIdx
//  归约出程序序最老者（rob_head_lq_match），用其 cause 点亮各 topdown 信号。这是纯
//  调试可视化逻辑，无功能副作用。
//
//  perf：13 个 perf event 计数，每个经两级寄存（HasPerfEvents 的 RegNext∘RegNext），
//  输出零扩展到 6 位。计数语义见各注释。

  // ---- topdown：归约找 robHeadVaddr 命中的最老 entry ----
  // ★golden = ParallelOperation(zip(lq_match_vec, uop_wrapper), combine)：**平衡二叉树**
  //   归约(split-at-size/2 递归)，combine 取「都有效时 robIdx 较老者，否则有效的一方」。
  //   最终 winner.uop.lqIdx.value 去 index cause 阵列(越界折叠视图)。
  //   ★原实现用「顺序 fold + 按 lqIdx 比较 + 用 entry 下标读 cause」三处均与 golden 分叉：
  //     (a) 比较键应为 robIdx 非 lqIdx；(b) cause 索引键应为 winner.lqIdx.value 非 entry 下标；
  //     (c) 归约树形状应为 ParallelOperation 平衡树非左结合 fold(平局/相同 robIdx 时结果不同)。
  //   FM analyze_points 实证：impl 的 robHead* 锥缺 uop_*_robIdx 输入(顺序 fold 按 lqIdx 比)。
  //   此处逐叶构造 td_leaf，再按 ParallelOperation 树(size/2 递归)显式归约到 td_n[142]。★
  logic [LQ_REPLAY_SIZE-1:0] lqMatchVec;
  always_comb
    for (int i = 0; i < LQ_REPLAY_SIZE; i++)
      lqMatchVec[i] = ent[i].allocated & (debug_vaddr[i] == dtd_robHeadVaddr_bits);

  td_node_t td_leaf [LQ_REPLAY_SIZE];
  always_comb
    for (int i = 0; i < LQ_REPLAY_SIZE; i++)
      td_leaf[i] = '{v: lqMatchVec[i], robF: uop[i].robIdx.flag,
                     robV: uop[i].robIdx.value, lqV: uop[i].lqIdx.value};

  // ParallelOperation 平衡树(143 节点：72 叶 + 71 merge, 根=142), 由脚本按 size/2 递归展开
  td_node_t td_n [143];
  always_comb begin
`include "loadqueuereplay_td_tree.svh"
  end

  wire lq_match = td_n[142].v & dtd_robHeadVaddr_valid;
  // 命中项的 cause：golden 用 winner.lqIdx.value 去 index 越界折叠 cause 阵列(_GEN_11)。
  wire [N_CAUSES-1:0] matchCause = causeR[td_n[142].lqV];

  wire rob_head_tlb_miss = lq_match & matchCause[C_TM];
  assign dtd_robHeadTlbReplay = rob_head_tlb_miss & ~dtd_robHeadMissInDTlb;
  assign dtd_robHeadTlbMiss   = rob_head_tlb_miss &  dtd_robHeadMissInDTlb;
  assign dtd_robHeadLoadVio   = (lq_match & matchCause[C_NK]) | (lq_match & matchCause[C_MA]);
  // ★golden robHeadLoadMSHR := rob_head_mshrfull_replay = cause(C_DR)（_GEN_1182[3]=C_DR），
  //   **不是 C_DM**（名字误导）。原实现取 C_DM(bit4) 与 golden 分叉。★
  assign dtd_robHeadLoadMSHR  = lq_match & matchCause[C_DR];

  // ---- perf 计数 ----
  //  按 enq.fire（=valid，enq.ready 恒 1）且非 isLoadReplay 统计各 cause 入队数；
  //  deq=replay.fire；deq_block=replay.valid & ~ready。
  //  「本拍非 replay 入队」的口掩码（多处复用），就地算出避免函数引用非局部变量（FM 友好）。
  logic [LD_PIPE_W-1:0] newEnqFire;
  always_comb
    for (int w = 0; w < LD_PIPE_W; w++)
      newEnqFire[w] = enq_valid[w] & ~enq_isLoadReplay[w];

  // 按 cause 统计入队口数（0..LD_PIPE_W）
  function automatic logic [1:0] cnt_cause(input logic [LD_PIPE_W-1:0] fire,
                                           input logic [LD_PIPE_W-1:0] hasc);
    logic [1:0] n;
    n = '0;
    for (int w = 0; w < LD_PIPE_W; w++) if (fire[w] & hasc[w]) n += 1'b1;
    return n;
  endfunction

  // 各 cause 在 3 口上的命中位（供 cnt_cause）
  function automatic logic [LD_PIPE_W-1:0] cause_bits(input logic [LD_PIPE_W-1:0][N_CAUSES-1:0] cv,
                                                      input int c);
    logic [LD_PIPE_W-1:0] r;
    for (int w = 0; w < LD_PIPE_W; w++) r[w] = cv[w][c];
    return r;
  endfunction

  logic [1:0] perfNext [13];
  logic       perfFullNext;
  always_comb begin
    perfNext[0]  = cnt_cause(newEnqFire, '1);                        // enq（任意 cause→全 1 掩码）
    perfNext[1]  = replay_fire[0] + replay_fire[1] + replay_fire[2]; // deq
    perfNext[2]  = (replay_valid[0]&~replay_ready[0]) + (replay_valid[1]&~replay_ready[1])
                 + (replay_valid[2]&~replay_ready[2]);               // deq_block
    perfFullNext = lqFull;                                           // replay_full（perf_3，1bit）
    perfNext[4]  = cnt_cause(newEnqFire, cause_bits(enq_cause, C_RAR));
    perfNext[5]  = cnt_cause(newEnqFire, cause_bits(enq_cause, C_RAW));
    perfNext[6]  = cnt_cause(newEnqFire, cause_bits(enq_cause, C_NK));
    perfNext[7]  = cnt_cause(newEnqFire, cause_bits(enq_cause, C_MA));
    perfNext[8]  = cnt_cause(newEnqFire, cause_bits(enq_cause, C_TM));
    perfNext[9]  = cnt_cause(newEnqFire, cause_bits(enq_cause, C_BC));
    perfNext[10] = cnt_cause(newEnqFire, cause_bits(enq_cause, C_DR));
    perfNext[11] = cnt_cause(newEnqFire, cause_bits(enq_cause, C_FF));
    perfNext[12] = cnt_cause(newEnqFire, cause_bits(enq_cause, C_DM));
    perfNext[3]  = '0;  // 占位（perf_3 用 perfFull 单独处理）
  end

  // 两级流水寄存
  logic [1:0] perfReg0 [13], perfReg1 [13];
  logic       perfFull0, perfFull1;
  always_ff @(posedge clock) begin
    for (int k = 0; k < 13; k++) begin
      perfReg0[k] <= perfNext[k];
      perfReg1[k] <= perfReg0[k];
    end
    perfFull0 <= perfFullNext;
    perfFull1 <= perfFull0;
  end
  always_comb begin
    for (int k = 0; k < 13; k++) perf_value[k] = {4'b0, perfReg1[k]};
    perf_value[3] = {5'b0, perfFull1};
  end
