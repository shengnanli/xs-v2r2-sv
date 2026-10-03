// RXSNP.sv —— coupledL2（tl2chi）slice 的 CHI SNP 接收通道：把互联发来的 snoop 变成 MainPipe 任务
//
// 对照 coupledL2/src/main/scala/coupledL2/tl2chi/RXSNP.scala。在 Slice 里的位置：
//   CHI 互联 --SNP flit--> [2 项队列 Queue2_CHISNP] --> 本模块判"能不能现在处理" --> RequestArb（io_task）
//
// 核心问题：snoop 的地址可能正被某个 MSHR 处理。对 16 个 MSHR 的状态（io_msInfo）逐个判：
//   * 阻塞（stall，snoop 留在队列里等）：
//       reqBlock      ：MSHR 在为同一地址取数（Acquire），且已收到第一拍 CompData 还没写回 DS，
//                       或正在为 alias 替换 probe L1 —— 此时 snoop 不能插队。
//       cmoBlock      ：有 CMO 事务命中目录、还没发完 cmo 响应且 release/probe/meta 写还没做完。
//       replaceBlock  ：MSHR 要替换掉的那一行正是 snoop 地址，且还在 probe L1 / 等 release ack /
//                       替换决定刚出来那一拍（!RegNext(w_replResp)）。
//   * 嵌套（nest，snoop 放行，但带上"命中了一个正在 release 的行"的信息）：
//       replaceNest   ：同一行已 probe 完、release 已发出但还没收到 ReleaseAck。任务里带上
//                       snpHitRelease*、命中的 MSHR 号（优先编码）与那一行的 meta。
//   任务的其余字段由 snoop 报文直接换算：地址按 slice 拆成 tag/set/off（snoop 地址少低 3 位），
//   其余 TaskBundle 字段在 golden 里已被 firtool 删掉（常量），不出现在端口上。
//
// 寄存器：两组 16 个 RegNext(w_replResp)（replaceBlock / replaceNest 各自一份，golden 就是两份，
//   不合并）；stallCnt 是死锁检测计数器，只被 `ifndef SYNTHESIS 的 assert 读，照 golden 保留。

package rxsnp_pkg;
  // MetaEntry（KunminghuV2Config 下的字段集）
  typedef struct packed {
    logic       dirty;
    logic [1:0] state;
    logic       clients;
    logic [1:0] alias_;
    logic       prefetch;
    logic [2:0] prefetchSrc;
    logic       accessed;
    logic       tagErr;
    logic       dataErr;
  } meta_t;

  localparam int unsigned N_MSHR = 16;   // mshrsAll
  localparam logic [1:0] INVALID = 2'd0; // MetaData.INVALID
endpackage

module xs_RXSNP_core
  import rxsnp_pkg::*;
(
  input  logic         clock,
  input  logic         reset,

  // ---- 队列出口（待处理的 snoop）----
  input  logic         snp_valid,
  output logic         snp_ready,
  input  logic [44:0]  snp_addr,        // CHI SNP 地址 = 物理地址 [47:3]
  input  logic [11:0]  snp_txnID,
  input  logic [4:0]   snp_opcode,

  // ---- 16 个 MSHR 的状态 ----
  input  logic         ms_valid           [N_MSHR],
  input  logic [8:0]   ms_set             [N_MSHR],
  input  logic [30:0]  ms_reqTag          [N_MSHR],
  input  logic [30:0]  ms_metaTag         [N_MSHR],
  input  meta_t        ms_meta            [N_MSHR],
  input  logic         ms_willFree        [N_MSHR],
  input  logic         ms_aliasTask       [N_MSHR],
  input  logic         ms_blockRefill     [N_MSHR],
  input  logic         ms_dirHit          [N_MSHR],
  input  logic         ms_w_grantfirst    [N_MSHR],
  input  logic         ms_s_release       [N_MSHR],
  input  logic         ms_s_cmoresp       [N_MSHR],
  input  logic         ms_s_cmometaw      [N_MSHR],
  input  logic         ms_w_releaseack    [N_MSHR],
  input  logic         ms_w_replResp      [N_MSHR],
  input  logic         ms_w_rprobeacklast [N_MSHR],
  input  logic         ms_replaceData     [N_MSHR],
  input  logic         ms_releaseToClean  [N_MSHR],

  // ---- 发往 RequestArb 的 snoop 任务 ----
  input  logic         task_ready,
  output logic         task_valid,
  output logic [8:0]   task_set,
  output logic [30:0]  task_tag,
  output logic [5:0]   task_off,
  output logic         task_snpHitRelease,
  output logic         task_snpHitReleaseToInval,
  output logic         task_snpHitReleaseToClean,
  output logic         task_snpHitReleaseWithData,
  output logic [7:0]   task_snpHitReleaseIdx,
  output meta_t        task_snpHitReleaseMeta,
  output logic [11:0]  task_txnID,
  output logic [6:0]   task_chiOpcode
);

  // ===========================================================================
  // §1 snoop 地址拆分（parseAddress：{tag 31, set 9, bank 2, offset 6}，snoop 地址少低 3 位）
  // ===========================================================================
  assign task_tag       = snp_addr[44:14];
  assign task_set       = snp_addr[13:5];
  assign task_off       = {snp_addr[2:0], 3'b000};
  assign task_txnID     = snp_txnID;
  assign task_chiOpcode = {2'b00, snp_opcode};

  // ===========================================================================
  // §2 与 16 个 MSHR 逐个比对
  // ===========================================================================
  logic                replPrevForBlock [N_MSHR];   // RegNext(w_replResp)，replaceBlock 用的那份
  logic                replPrevForNest  [N_MSHR];   // RegNext(w_replResp)，replaceNest 用的那份
  logic [N_MSHR-1:0]   reqBlockMask, cmoBlockMask, replaceBlockMask, replaceNestMask;

  always_ff @(posedge clock) begin
    for (int i = 0; i < N_MSHR; i++) begin
      replPrevForBlock[i] <= ms_w_replResp[i];
      replPrevForNest[i]  <= ms_w_replResp[i];
    end
  end

  always_comb begin
    for (int i = 0; i < N_MSHR; i++) begin
      logic sameSet;
      logic metaValid;
      sameSet   = ms_set[i] == task_set;
      metaValid = ms_meta[i].state != INVALID;

      // 请求阻塞：同地址的 Acquire 已收到首拍数据（或 alias probe 未完），refill 未写入 DS
      reqBlockMask[i] = ms_valid[i] && sameSet && ms_reqTag[i] == task_tag
                     && (ms_w_grantfirst[i] || (ms_aliasTask[i] && !ms_w_rprobeacklast[i]))
                     && (ms_blockRefill[i] || ms_w_releaseack[i])
                     && !ms_willFree[i];

      // CMO 阻塞：命中目录的 CMO 还没收尾（注意：不比地址，任何在飞 CMO 都挡）
      cmoBlockMask[i] = ms_valid[i] && ms_dirHit[i] && metaValid && !ms_s_cmoresp[i]
                     && (!ms_s_release[i] || !ms_w_rprobeacklast[i] || !ms_s_cmometaw[i])
                     && !ms_willFree[i];

      // 替换阻塞：被替换的行就是 snoop 地址，且 probe 未完 / 等 ReleaseAck / 替换决定刚到
      replaceBlockMask[i] = ms_valid[i] && sameSet && ms_metaTag[i] == task_tag && !ms_dirHit[i]
                         && metaValid && ms_s_cmoresp[i] && ms_w_replResp[i]
                         && (!ms_w_rprobeacklast[i] || ms_w_releaseack[i] || !replPrevForBlock[i])
                         && !ms_willFree[i];

      // 替换嵌套：probe 已完、release 已发、ReleaseAck 未到 —— snoop 放行并带上 release 信息
      replaceNestMask[i] = ms_valid[i] && sameSet && ms_metaTag[i] == task_tag
                        && (!ms_dirHit[i] || !ms_s_cmoresp[i]) && metaValid
                        && replPrevForNest[i] && ms_w_rprobeacklast[i] && !ms_w_releaseack[i];
    end
  end

  // ===========================================================================
  // §3 放行 / 阻塞
  // ===========================================================================
  logic stall;
  assign stall      = (|reqBlockMask) | (|replaceBlockMask) | (|cmoBlockMask);
  assign task_valid = snp_valid & ~stall;
  assign snp_ready  = task_ready & ~stall;

  // ===========================================================================
  // §4 嵌套信息
  // ===========================================================================
  logic [N_MSHR-1:0] toCleanMask, replaceDataMask;
  always_comb begin
    for (int i = 0; i < N_MSHR; i++) begin
      toCleanMask[i]     = ms_releaseToClean[i];
      replaceDataMask[i] = ms_replaceData[i];
    end
  end

  assign task_snpHitRelease         = |replaceNestMask;
  assign task_snpHitReleaseToInval  = |(replaceNestMask & ~toCleanMask);
  assign task_snpHitReleaseToClean  = |(replaceNestMask &  toCleanMask);
  assign task_snpHitReleaseWithData = |(replaceNestMask & replaceDataMask);

  // PriorityEncoder：最低的命中位；全不命中时 Chisel 给最后一个下标 15。高 4 位（mshrBits=8）补 0。
  always_comb begin
    task_snpHitReleaseIdx = 8'(N_MSHR - 1);
    for (int i = N_MSHR - 1; i >= 0; i--)
      if (replaceNestMask[i]) task_snpHitReleaseIdx = 8'(i);
  end

  // 命中 MSHR 的 meta 按位或（正常至多一个命中，assert 保证；这里照 golden 做 ParallelOR）
  always_comb begin
    task_snpHitReleaseMeta = '0;
    for (int i = 0; i < N_MSHR; i++)
      if (replaceNestMask[i]) task_snpHitReleaseMeta |= ms_meta[i];
  end

  // ===========================================================================
  // §5 死锁检测计数器（只被 assert 读；照 golden 保留）
  // ===========================================================================
  logic [63:0] stallCnt;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      stallCnt <= '0;
    else if (snp_ready & snp_valid)
      stallCnt <= '0;
    else if (snp_valid & ~snp_ready)
      stallCnt <= stallCnt + 64'd1;
  end

endmodule

// =============================================================================
// RXSNP —— golden 同名 wrapper：队列 queue（实例名同 golden）+ 可读核；把 msInfo_<i>_* 打包成数组
// =============================================================================
module RXSNP
  import rxsnp_pkg::*;
(
  input  logic clock,
  input  logic reset,
  output logic io_rxsnp_ready,
  input  logic io_rxsnp_valid,
  input  logic [3:0] io_rxsnp_bits_qos,
  input  logic [10:0] io_rxsnp_bits_srcID,
  input  logic [11:0] io_rxsnp_bits_txnID,
  input  logic [10:0] io_rxsnp_bits_fwdNID,
  input  logic [11:0] io_rxsnp_bits_fwdTxnID,
  input  logic [4:0] io_rxsnp_bits_opcode,
  input  logic [44:0] io_rxsnp_bits_addr,
  input  logic io_rxsnp_bits_ns,
  input  logic io_rxsnp_bits_doNotGoToSD,
  input  logic io_rxsnp_bits_retToSrc,
  input  logic io_rxsnp_bits_traceTag,
  input  logic io_rxsnp_bits_mpam_perfMonGroup,
  input  logic [8:0] io_rxsnp_bits_mpam_partID,
  input  logic io_rxsnp_bits_mpam_mpamNS,
  input  logic io_task_ready,
  output logic io_task_valid,
  output logic [8:0] io_task_bits_set,
  output logic [30:0] io_task_bits_tag,
  output logic [5:0] io_task_bits_off,
  output logic io_task_bits_snpHitRelease,
  output logic io_task_bits_snpHitReleaseToInval,
  output logic io_task_bits_snpHitReleaseToClean,
  output logic io_task_bits_snpHitReleaseWithData,
  output logic [7:0] io_task_bits_snpHitReleaseIdx,
  output logic io_task_bits_snpHitReleaseMeta_dirty,
  output logic [1:0] io_task_bits_snpHitReleaseMeta_state,
  output logic io_task_bits_snpHitReleaseMeta_clients,
  output logic [1:0] io_task_bits_snpHitReleaseMeta_alias,
  output logic io_task_bits_snpHitReleaseMeta_prefetch,
  output logic [2:0] io_task_bits_snpHitReleaseMeta_prefetchSrc,
  output logic io_task_bits_snpHitReleaseMeta_accessed,
  output logic io_task_bits_snpHitReleaseMeta_tagErr,
  output logic io_task_bits_snpHitReleaseMeta_dataErr,
  output logic [10:0] io_task_bits_srcID,
  output logic [11:0] io_task_bits_txnID,
  output logic [10:0] io_task_bits_fwdNID,
  output logic [11:0] io_task_bits_fwdTxnID,
  output logic [6:0] io_task_bits_chiOpcode,
  output logic io_task_bits_retToSrc,
  output logic io_task_bits_traceTag,
  input  logic io_msInfo_0_valid,
  input  logic [8:0] io_msInfo_0_bits_set,
  input  logic [30:0] io_msInfo_0_bits_reqTag,
  input  logic io_msInfo_0_bits_willFree,
  input  logic io_msInfo_0_bits_aliasTask,
  input  logic io_msInfo_0_bits_blockRefill,
  input  logic io_msInfo_0_bits_meta_dirty,
  input  logic [1:0] io_msInfo_0_bits_meta_state,
  input  logic io_msInfo_0_bits_meta_clients,
  input  logic [1:0] io_msInfo_0_bits_meta_alias,
  input  logic io_msInfo_0_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_0_bits_meta_prefetchSrc,
  input  logic io_msInfo_0_bits_meta_accessed,
  input  logic io_msInfo_0_bits_meta_tagErr,
  input  logic io_msInfo_0_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_0_bits_metaTag,
  input  logic io_msInfo_0_bits_dirHit,
  input  logic io_msInfo_0_bits_w_grantfirst,
  input  logic io_msInfo_0_bits_s_release,
  input  logic io_msInfo_0_bits_s_cmoresp,
  input  logic io_msInfo_0_bits_s_cmometaw,
  input  logic io_msInfo_0_bits_w_releaseack,
  input  logic io_msInfo_0_bits_w_replResp,
  input  logic io_msInfo_0_bits_w_rprobeacklast,
  input  logic io_msInfo_0_bits_replaceData,
  input  logic io_msInfo_0_bits_releaseToClean,
  input  logic io_msInfo_1_valid,
  input  logic [8:0] io_msInfo_1_bits_set,
  input  logic [30:0] io_msInfo_1_bits_reqTag,
  input  logic io_msInfo_1_bits_willFree,
  input  logic io_msInfo_1_bits_aliasTask,
  input  logic io_msInfo_1_bits_blockRefill,
  input  logic io_msInfo_1_bits_meta_dirty,
  input  logic [1:0] io_msInfo_1_bits_meta_state,
  input  logic io_msInfo_1_bits_meta_clients,
  input  logic [1:0] io_msInfo_1_bits_meta_alias,
  input  logic io_msInfo_1_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_1_bits_meta_prefetchSrc,
  input  logic io_msInfo_1_bits_meta_accessed,
  input  logic io_msInfo_1_bits_meta_tagErr,
  input  logic io_msInfo_1_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_1_bits_metaTag,
  input  logic io_msInfo_1_bits_dirHit,
  input  logic io_msInfo_1_bits_w_grantfirst,
  input  logic io_msInfo_1_bits_s_release,
  input  logic io_msInfo_1_bits_s_cmoresp,
  input  logic io_msInfo_1_bits_s_cmometaw,
  input  logic io_msInfo_1_bits_w_releaseack,
  input  logic io_msInfo_1_bits_w_replResp,
  input  logic io_msInfo_1_bits_w_rprobeacklast,
  input  logic io_msInfo_1_bits_replaceData,
  input  logic io_msInfo_1_bits_releaseToClean,
  input  logic io_msInfo_2_valid,
  input  logic [8:0] io_msInfo_2_bits_set,
  input  logic [30:0] io_msInfo_2_bits_reqTag,
  input  logic io_msInfo_2_bits_willFree,
  input  logic io_msInfo_2_bits_aliasTask,
  input  logic io_msInfo_2_bits_blockRefill,
  input  logic io_msInfo_2_bits_meta_dirty,
  input  logic [1:0] io_msInfo_2_bits_meta_state,
  input  logic io_msInfo_2_bits_meta_clients,
  input  logic [1:0] io_msInfo_2_bits_meta_alias,
  input  logic io_msInfo_2_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_2_bits_meta_prefetchSrc,
  input  logic io_msInfo_2_bits_meta_accessed,
  input  logic io_msInfo_2_bits_meta_tagErr,
  input  logic io_msInfo_2_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_2_bits_metaTag,
  input  logic io_msInfo_2_bits_dirHit,
  input  logic io_msInfo_2_bits_w_grantfirst,
  input  logic io_msInfo_2_bits_s_release,
  input  logic io_msInfo_2_bits_s_cmoresp,
  input  logic io_msInfo_2_bits_s_cmometaw,
  input  logic io_msInfo_2_bits_w_releaseack,
  input  logic io_msInfo_2_bits_w_replResp,
  input  logic io_msInfo_2_bits_w_rprobeacklast,
  input  logic io_msInfo_2_bits_replaceData,
  input  logic io_msInfo_2_bits_releaseToClean,
  input  logic io_msInfo_3_valid,
  input  logic [8:0] io_msInfo_3_bits_set,
  input  logic [30:0] io_msInfo_3_bits_reqTag,
  input  logic io_msInfo_3_bits_willFree,
  input  logic io_msInfo_3_bits_aliasTask,
  input  logic io_msInfo_3_bits_blockRefill,
  input  logic io_msInfo_3_bits_meta_dirty,
  input  logic [1:0] io_msInfo_3_bits_meta_state,
  input  logic io_msInfo_3_bits_meta_clients,
  input  logic [1:0] io_msInfo_3_bits_meta_alias,
  input  logic io_msInfo_3_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_3_bits_meta_prefetchSrc,
  input  logic io_msInfo_3_bits_meta_accessed,
  input  logic io_msInfo_3_bits_meta_tagErr,
  input  logic io_msInfo_3_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_3_bits_metaTag,
  input  logic io_msInfo_3_bits_dirHit,
  input  logic io_msInfo_3_bits_w_grantfirst,
  input  logic io_msInfo_3_bits_s_release,
  input  logic io_msInfo_3_bits_s_cmoresp,
  input  logic io_msInfo_3_bits_s_cmometaw,
  input  logic io_msInfo_3_bits_w_releaseack,
  input  logic io_msInfo_3_bits_w_replResp,
  input  logic io_msInfo_3_bits_w_rprobeacklast,
  input  logic io_msInfo_3_bits_replaceData,
  input  logic io_msInfo_3_bits_releaseToClean,
  input  logic io_msInfo_4_valid,
  input  logic [8:0] io_msInfo_4_bits_set,
  input  logic [30:0] io_msInfo_4_bits_reqTag,
  input  logic io_msInfo_4_bits_willFree,
  input  logic io_msInfo_4_bits_aliasTask,
  input  logic io_msInfo_4_bits_blockRefill,
  input  logic io_msInfo_4_bits_meta_dirty,
  input  logic [1:0] io_msInfo_4_bits_meta_state,
  input  logic io_msInfo_4_bits_meta_clients,
  input  logic [1:0] io_msInfo_4_bits_meta_alias,
  input  logic io_msInfo_4_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_4_bits_meta_prefetchSrc,
  input  logic io_msInfo_4_bits_meta_accessed,
  input  logic io_msInfo_4_bits_meta_tagErr,
  input  logic io_msInfo_4_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_4_bits_metaTag,
  input  logic io_msInfo_4_bits_dirHit,
  input  logic io_msInfo_4_bits_w_grantfirst,
  input  logic io_msInfo_4_bits_s_release,
  input  logic io_msInfo_4_bits_s_cmoresp,
  input  logic io_msInfo_4_bits_s_cmometaw,
  input  logic io_msInfo_4_bits_w_releaseack,
  input  logic io_msInfo_4_bits_w_replResp,
  input  logic io_msInfo_4_bits_w_rprobeacklast,
  input  logic io_msInfo_4_bits_replaceData,
  input  logic io_msInfo_4_bits_releaseToClean,
  input  logic io_msInfo_5_valid,
  input  logic [8:0] io_msInfo_5_bits_set,
  input  logic [30:0] io_msInfo_5_bits_reqTag,
  input  logic io_msInfo_5_bits_willFree,
  input  logic io_msInfo_5_bits_aliasTask,
  input  logic io_msInfo_5_bits_blockRefill,
  input  logic io_msInfo_5_bits_meta_dirty,
  input  logic [1:0] io_msInfo_5_bits_meta_state,
  input  logic io_msInfo_5_bits_meta_clients,
  input  logic [1:0] io_msInfo_5_bits_meta_alias,
  input  logic io_msInfo_5_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_5_bits_meta_prefetchSrc,
  input  logic io_msInfo_5_bits_meta_accessed,
  input  logic io_msInfo_5_bits_meta_tagErr,
  input  logic io_msInfo_5_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_5_bits_metaTag,
  input  logic io_msInfo_5_bits_dirHit,
  input  logic io_msInfo_5_bits_w_grantfirst,
  input  logic io_msInfo_5_bits_s_release,
  input  logic io_msInfo_5_bits_s_cmoresp,
  input  logic io_msInfo_5_bits_s_cmometaw,
  input  logic io_msInfo_5_bits_w_releaseack,
  input  logic io_msInfo_5_bits_w_replResp,
  input  logic io_msInfo_5_bits_w_rprobeacklast,
  input  logic io_msInfo_5_bits_replaceData,
  input  logic io_msInfo_5_bits_releaseToClean,
  input  logic io_msInfo_6_valid,
  input  logic [8:0] io_msInfo_6_bits_set,
  input  logic [30:0] io_msInfo_6_bits_reqTag,
  input  logic io_msInfo_6_bits_willFree,
  input  logic io_msInfo_6_bits_aliasTask,
  input  logic io_msInfo_6_bits_blockRefill,
  input  logic io_msInfo_6_bits_meta_dirty,
  input  logic [1:0] io_msInfo_6_bits_meta_state,
  input  logic io_msInfo_6_bits_meta_clients,
  input  logic [1:0] io_msInfo_6_bits_meta_alias,
  input  logic io_msInfo_6_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_6_bits_meta_prefetchSrc,
  input  logic io_msInfo_6_bits_meta_accessed,
  input  logic io_msInfo_6_bits_meta_tagErr,
  input  logic io_msInfo_6_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_6_bits_metaTag,
  input  logic io_msInfo_6_bits_dirHit,
  input  logic io_msInfo_6_bits_w_grantfirst,
  input  logic io_msInfo_6_bits_s_release,
  input  logic io_msInfo_6_bits_s_cmoresp,
  input  logic io_msInfo_6_bits_s_cmometaw,
  input  logic io_msInfo_6_bits_w_releaseack,
  input  logic io_msInfo_6_bits_w_replResp,
  input  logic io_msInfo_6_bits_w_rprobeacklast,
  input  logic io_msInfo_6_bits_replaceData,
  input  logic io_msInfo_6_bits_releaseToClean,
  input  logic io_msInfo_7_valid,
  input  logic [8:0] io_msInfo_7_bits_set,
  input  logic [30:0] io_msInfo_7_bits_reqTag,
  input  logic io_msInfo_7_bits_willFree,
  input  logic io_msInfo_7_bits_aliasTask,
  input  logic io_msInfo_7_bits_blockRefill,
  input  logic io_msInfo_7_bits_meta_dirty,
  input  logic [1:0] io_msInfo_7_bits_meta_state,
  input  logic io_msInfo_7_bits_meta_clients,
  input  logic [1:0] io_msInfo_7_bits_meta_alias,
  input  logic io_msInfo_7_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_7_bits_meta_prefetchSrc,
  input  logic io_msInfo_7_bits_meta_accessed,
  input  logic io_msInfo_7_bits_meta_tagErr,
  input  logic io_msInfo_7_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_7_bits_metaTag,
  input  logic io_msInfo_7_bits_dirHit,
  input  logic io_msInfo_7_bits_w_grantfirst,
  input  logic io_msInfo_7_bits_s_release,
  input  logic io_msInfo_7_bits_s_cmoresp,
  input  logic io_msInfo_7_bits_s_cmometaw,
  input  logic io_msInfo_7_bits_w_releaseack,
  input  logic io_msInfo_7_bits_w_replResp,
  input  logic io_msInfo_7_bits_w_rprobeacklast,
  input  logic io_msInfo_7_bits_replaceData,
  input  logic io_msInfo_7_bits_releaseToClean,
  input  logic io_msInfo_8_valid,
  input  logic [8:0] io_msInfo_8_bits_set,
  input  logic [30:0] io_msInfo_8_bits_reqTag,
  input  logic io_msInfo_8_bits_willFree,
  input  logic io_msInfo_8_bits_aliasTask,
  input  logic io_msInfo_8_bits_blockRefill,
  input  logic io_msInfo_8_bits_meta_dirty,
  input  logic [1:0] io_msInfo_8_bits_meta_state,
  input  logic io_msInfo_8_bits_meta_clients,
  input  logic [1:0] io_msInfo_8_bits_meta_alias,
  input  logic io_msInfo_8_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_8_bits_meta_prefetchSrc,
  input  logic io_msInfo_8_bits_meta_accessed,
  input  logic io_msInfo_8_bits_meta_tagErr,
  input  logic io_msInfo_8_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_8_bits_metaTag,
  input  logic io_msInfo_8_bits_dirHit,
  input  logic io_msInfo_8_bits_w_grantfirst,
  input  logic io_msInfo_8_bits_s_release,
  input  logic io_msInfo_8_bits_s_cmoresp,
  input  logic io_msInfo_8_bits_s_cmometaw,
  input  logic io_msInfo_8_bits_w_releaseack,
  input  logic io_msInfo_8_bits_w_replResp,
  input  logic io_msInfo_8_bits_w_rprobeacklast,
  input  logic io_msInfo_8_bits_replaceData,
  input  logic io_msInfo_8_bits_releaseToClean,
  input  logic io_msInfo_9_valid,
  input  logic [8:0] io_msInfo_9_bits_set,
  input  logic [30:0] io_msInfo_9_bits_reqTag,
  input  logic io_msInfo_9_bits_willFree,
  input  logic io_msInfo_9_bits_aliasTask,
  input  logic io_msInfo_9_bits_blockRefill,
  input  logic io_msInfo_9_bits_meta_dirty,
  input  logic [1:0] io_msInfo_9_bits_meta_state,
  input  logic io_msInfo_9_bits_meta_clients,
  input  logic [1:0] io_msInfo_9_bits_meta_alias,
  input  logic io_msInfo_9_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_9_bits_meta_prefetchSrc,
  input  logic io_msInfo_9_bits_meta_accessed,
  input  logic io_msInfo_9_bits_meta_tagErr,
  input  logic io_msInfo_9_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_9_bits_metaTag,
  input  logic io_msInfo_9_bits_dirHit,
  input  logic io_msInfo_9_bits_w_grantfirst,
  input  logic io_msInfo_9_bits_s_release,
  input  logic io_msInfo_9_bits_s_cmoresp,
  input  logic io_msInfo_9_bits_s_cmometaw,
  input  logic io_msInfo_9_bits_w_releaseack,
  input  logic io_msInfo_9_bits_w_replResp,
  input  logic io_msInfo_9_bits_w_rprobeacklast,
  input  logic io_msInfo_9_bits_replaceData,
  input  logic io_msInfo_9_bits_releaseToClean,
  input  logic io_msInfo_10_valid,
  input  logic [8:0] io_msInfo_10_bits_set,
  input  logic [30:0] io_msInfo_10_bits_reqTag,
  input  logic io_msInfo_10_bits_willFree,
  input  logic io_msInfo_10_bits_aliasTask,
  input  logic io_msInfo_10_bits_blockRefill,
  input  logic io_msInfo_10_bits_meta_dirty,
  input  logic [1:0] io_msInfo_10_bits_meta_state,
  input  logic io_msInfo_10_bits_meta_clients,
  input  logic [1:0] io_msInfo_10_bits_meta_alias,
  input  logic io_msInfo_10_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_10_bits_meta_prefetchSrc,
  input  logic io_msInfo_10_bits_meta_accessed,
  input  logic io_msInfo_10_bits_meta_tagErr,
  input  logic io_msInfo_10_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_10_bits_metaTag,
  input  logic io_msInfo_10_bits_dirHit,
  input  logic io_msInfo_10_bits_w_grantfirst,
  input  logic io_msInfo_10_bits_s_release,
  input  logic io_msInfo_10_bits_s_cmoresp,
  input  logic io_msInfo_10_bits_s_cmometaw,
  input  logic io_msInfo_10_bits_w_releaseack,
  input  logic io_msInfo_10_bits_w_replResp,
  input  logic io_msInfo_10_bits_w_rprobeacklast,
  input  logic io_msInfo_10_bits_replaceData,
  input  logic io_msInfo_10_bits_releaseToClean,
  input  logic io_msInfo_11_valid,
  input  logic [8:0] io_msInfo_11_bits_set,
  input  logic [30:0] io_msInfo_11_bits_reqTag,
  input  logic io_msInfo_11_bits_willFree,
  input  logic io_msInfo_11_bits_aliasTask,
  input  logic io_msInfo_11_bits_blockRefill,
  input  logic io_msInfo_11_bits_meta_dirty,
  input  logic [1:0] io_msInfo_11_bits_meta_state,
  input  logic io_msInfo_11_bits_meta_clients,
  input  logic [1:0] io_msInfo_11_bits_meta_alias,
  input  logic io_msInfo_11_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_11_bits_meta_prefetchSrc,
  input  logic io_msInfo_11_bits_meta_accessed,
  input  logic io_msInfo_11_bits_meta_tagErr,
  input  logic io_msInfo_11_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_11_bits_metaTag,
  input  logic io_msInfo_11_bits_dirHit,
  input  logic io_msInfo_11_bits_w_grantfirst,
  input  logic io_msInfo_11_bits_s_release,
  input  logic io_msInfo_11_bits_s_cmoresp,
  input  logic io_msInfo_11_bits_s_cmometaw,
  input  logic io_msInfo_11_bits_w_releaseack,
  input  logic io_msInfo_11_bits_w_replResp,
  input  logic io_msInfo_11_bits_w_rprobeacklast,
  input  logic io_msInfo_11_bits_replaceData,
  input  logic io_msInfo_11_bits_releaseToClean,
  input  logic io_msInfo_12_valid,
  input  logic [8:0] io_msInfo_12_bits_set,
  input  logic [30:0] io_msInfo_12_bits_reqTag,
  input  logic io_msInfo_12_bits_willFree,
  input  logic io_msInfo_12_bits_aliasTask,
  input  logic io_msInfo_12_bits_blockRefill,
  input  logic io_msInfo_12_bits_meta_dirty,
  input  logic [1:0] io_msInfo_12_bits_meta_state,
  input  logic io_msInfo_12_bits_meta_clients,
  input  logic [1:0] io_msInfo_12_bits_meta_alias,
  input  logic io_msInfo_12_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_12_bits_meta_prefetchSrc,
  input  logic io_msInfo_12_bits_meta_accessed,
  input  logic io_msInfo_12_bits_meta_tagErr,
  input  logic io_msInfo_12_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_12_bits_metaTag,
  input  logic io_msInfo_12_bits_dirHit,
  input  logic io_msInfo_12_bits_w_grantfirst,
  input  logic io_msInfo_12_bits_s_release,
  input  logic io_msInfo_12_bits_s_cmoresp,
  input  logic io_msInfo_12_bits_s_cmometaw,
  input  logic io_msInfo_12_bits_w_releaseack,
  input  logic io_msInfo_12_bits_w_replResp,
  input  logic io_msInfo_12_bits_w_rprobeacklast,
  input  logic io_msInfo_12_bits_replaceData,
  input  logic io_msInfo_12_bits_releaseToClean,
  input  logic io_msInfo_13_valid,
  input  logic [8:0] io_msInfo_13_bits_set,
  input  logic [30:0] io_msInfo_13_bits_reqTag,
  input  logic io_msInfo_13_bits_willFree,
  input  logic io_msInfo_13_bits_aliasTask,
  input  logic io_msInfo_13_bits_blockRefill,
  input  logic io_msInfo_13_bits_meta_dirty,
  input  logic [1:0] io_msInfo_13_bits_meta_state,
  input  logic io_msInfo_13_bits_meta_clients,
  input  logic [1:0] io_msInfo_13_bits_meta_alias,
  input  logic io_msInfo_13_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_13_bits_meta_prefetchSrc,
  input  logic io_msInfo_13_bits_meta_accessed,
  input  logic io_msInfo_13_bits_meta_tagErr,
  input  logic io_msInfo_13_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_13_bits_metaTag,
  input  logic io_msInfo_13_bits_dirHit,
  input  logic io_msInfo_13_bits_w_grantfirst,
  input  logic io_msInfo_13_bits_s_release,
  input  logic io_msInfo_13_bits_s_cmoresp,
  input  logic io_msInfo_13_bits_s_cmometaw,
  input  logic io_msInfo_13_bits_w_releaseack,
  input  logic io_msInfo_13_bits_w_replResp,
  input  logic io_msInfo_13_bits_w_rprobeacklast,
  input  logic io_msInfo_13_bits_replaceData,
  input  logic io_msInfo_13_bits_releaseToClean,
  input  logic io_msInfo_14_valid,
  input  logic [8:0] io_msInfo_14_bits_set,
  input  logic [30:0] io_msInfo_14_bits_reqTag,
  input  logic io_msInfo_14_bits_willFree,
  input  logic io_msInfo_14_bits_aliasTask,
  input  logic io_msInfo_14_bits_blockRefill,
  input  logic io_msInfo_14_bits_meta_dirty,
  input  logic [1:0] io_msInfo_14_bits_meta_state,
  input  logic io_msInfo_14_bits_meta_clients,
  input  logic [1:0] io_msInfo_14_bits_meta_alias,
  input  logic io_msInfo_14_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_14_bits_meta_prefetchSrc,
  input  logic io_msInfo_14_bits_meta_accessed,
  input  logic io_msInfo_14_bits_meta_tagErr,
  input  logic io_msInfo_14_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_14_bits_metaTag,
  input  logic io_msInfo_14_bits_dirHit,
  input  logic io_msInfo_14_bits_w_grantfirst,
  input  logic io_msInfo_14_bits_s_release,
  input  logic io_msInfo_14_bits_s_cmoresp,
  input  logic io_msInfo_14_bits_s_cmometaw,
  input  logic io_msInfo_14_bits_w_releaseack,
  input  logic io_msInfo_14_bits_w_replResp,
  input  logic io_msInfo_14_bits_w_rprobeacklast,
  input  logic io_msInfo_14_bits_replaceData,
  input  logic io_msInfo_14_bits_releaseToClean,
  input  logic io_msInfo_15_valid,
  input  logic [8:0] io_msInfo_15_bits_set,
  input  logic [30:0] io_msInfo_15_bits_reqTag,
  input  logic io_msInfo_15_bits_willFree,
  input  logic io_msInfo_15_bits_aliasTask,
  input  logic io_msInfo_15_bits_blockRefill,
  input  logic io_msInfo_15_bits_meta_dirty,
  input  logic [1:0] io_msInfo_15_bits_meta_state,
  input  logic io_msInfo_15_bits_meta_clients,
  input  logic [1:0] io_msInfo_15_bits_meta_alias,
  input  logic io_msInfo_15_bits_meta_prefetch,
  input  logic [2:0] io_msInfo_15_bits_meta_prefetchSrc,
  input  logic io_msInfo_15_bits_meta_accessed,
  input  logic io_msInfo_15_bits_meta_tagErr,
  input  logic io_msInfo_15_bits_meta_dataErr,
  input  logic [30:0] io_msInfo_15_bits_metaTag,
  input  logic io_msInfo_15_bits_dirHit,
  input  logic io_msInfo_15_bits_w_grantfirst,
  input  logic io_msInfo_15_bits_s_release,
  input  logic io_msInfo_15_bits_s_cmoresp,
  input  logic io_msInfo_15_bits_s_cmometaw,
  input  logic io_msInfo_15_bits_w_releaseack,
  input  logic io_msInfo_15_bits_w_replResp,
  input  logic io_msInfo_15_bits_w_rprobeacklast,
  input  logic io_msInfo_15_bits_replaceData,
  input  logic io_msInfo_15_bits_releaseToClean
);

  logic        snp_valid, snp_ready;
  logic [44:0] snp_addr;
  logic [11:0] snp_txnID;
  logic [4:0]  snp_opcode;
  meta_t       ms_meta [N_MSHR];
  meta_t       hitMeta;

  Queue2_CHISNP queue (
    .clock                           (clock),
    .reset                           (reset),
    .io_enq_ready                    (io_rxsnp_ready),
    .io_enq_valid                    (io_rxsnp_valid),
    .io_enq_bits_qos                 (io_rxsnp_bits_qos),
    .io_enq_bits_srcID               (io_rxsnp_bits_srcID),
    .io_enq_bits_txnID               (io_rxsnp_bits_txnID),
    .io_enq_bits_fwdNID              (io_rxsnp_bits_fwdNID),
    .io_enq_bits_fwdTxnID            (io_rxsnp_bits_fwdTxnID),
    .io_enq_bits_opcode              (io_rxsnp_bits_opcode),
    .io_enq_bits_addr                (io_rxsnp_bits_addr),
    .io_enq_bits_ns                  (io_rxsnp_bits_ns),
    .io_enq_bits_doNotGoToSD         (io_rxsnp_bits_doNotGoToSD),
    .io_enq_bits_retToSrc            (io_rxsnp_bits_retToSrc),
    .io_enq_bits_traceTag            (io_rxsnp_bits_traceTag),
    .io_enq_bits_mpam_perfMonGroup   (io_rxsnp_bits_mpam_perfMonGroup),
    .io_enq_bits_mpam_partID         (io_rxsnp_bits_mpam_partID),
    .io_enq_bits_mpam_mpamNS         (io_rxsnp_bits_mpam_mpamNS),
    .io_deq_ready                    (snp_ready),
    .io_deq_valid                    (snp_valid),
    .io_deq_bits_srcID               (io_task_bits_srcID),
    .io_deq_bits_txnID               (snp_txnID),
    .io_deq_bits_fwdNID              (io_task_bits_fwdNID),
    .io_deq_bits_fwdTxnID            (io_task_bits_fwdTxnID),
    .io_deq_bits_opcode              (snp_opcode),
    .io_deq_bits_addr                (snp_addr),
    .io_deq_bits_retToSrc            (io_task_bits_retToSrc),
    .io_deq_bits_traceTag            (io_task_bits_traceTag)
  );

  // 每个 MSHR 的 meta 装成结构体
  assign ms_meta[0] = '{io_msInfo_0_bits_meta_dirty, io_msInfo_0_bits_meta_state, io_msInfo_0_bits_meta_clients, io_msInfo_0_bits_meta_alias, io_msInfo_0_bits_meta_prefetch, io_msInfo_0_bits_meta_prefetchSrc, io_msInfo_0_bits_meta_accessed, io_msInfo_0_bits_meta_tagErr, io_msInfo_0_bits_meta_dataErr};
  assign ms_meta[1] = '{io_msInfo_1_bits_meta_dirty, io_msInfo_1_bits_meta_state, io_msInfo_1_bits_meta_clients, io_msInfo_1_bits_meta_alias, io_msInfo_1_bits_meta_prefetch, io_msInfo_1_bits_meta_prefetchSrc, io_msInfo_1_bits_meta_accessed, io_msInfo_1_bits_meta_tagErr, io_msInfo_1_bits_meta_dataErr};
  assign ms_meta[2] = '{io_msInfo_2_bits_meta_dirty, io_msInfo_2_bits_meta_state, io_msInfo_2_bits_meta_clients, io_msInfo_2_bits_meta_alias, io_msInfo_2_bits_meta_prefetch, io_msInfo_2_bits_meta_prefetchSrc, io_msInfo_2_bits_meta_accessed, io_msInfo_2_bits_meta_tagErr, io_msInfo_2_bits_meta_dataErr};
  assign ms_meta[3] = '{io_msInfo_3_bits_meta_dirty, io_msInfo_3_bits_meta_state, io_msInfo_3_bits_meta_clients, io_msInfo_3_bits_meta_alias, io_msInfo_3_bits_meta_prefetch, io_msInfo_3_bits_meta_prefetchSrc, io_msInfo_3_bits_meta_accessed, io_msInfo_3_bits_meta_tagErr, io_msInfo_3_bits_meta_dataErr};
  assign ms_meta[4] = '{io_msInfo_4_bits_meta_dirty, io_msInfo_4_bits_meta_state, io_msInfo_4_bits_meta_clients, io_msInfo_4_bits_meta_alias, io_msInfo_4_bits_meta_prefetch, io_msInfo_4_bits_meta_prefetchSrc, io_msInfo_4_bits_meta_accessed, io_msInfo_4_bits_meta_tagErr, io_msInfo_4_bits_meta_dataErr};
  assign ms_meta[5] = '{io_msInfo_5_bits_meta_dirty, io_msInfo_5_bits_meta_state, io_msInfo_5_bits_meta_clients, io_msInfo_5_bits_meta_alias, io_msInfo_5_bits_meta_prefetch, io_msInfo_5_bits_meta_prefetchSrc, io_msInfo_5_bits_meta_accessed, io_msInfo_5_bits_meta_tagErr, io_msInfo_5_bits_meta_dataErr};
  assign ms_meta[6] = '{io_msInfo_6_bits_meta_dirty, io_msInfo_6_bits_meta_state, io_msInfo_6_bits_meta_clients, io_msInfo_6_bits_meta_alias, io_msInfo_6_bits_meta_prefetch, io_msInfo_6_bits_meta_prefetchSrc, io_msInfo_6_bits_meta_accessed, io_msInfo_6_bits_meta_tagErr, io_msInfo_6_bits_meta_dataErr};
  assign ms_meta[7] = '{io_msInfo_7_bits_meta_dirty, io_msInfo_7_bits_meta_state, io_msInfo_7_bits_meta_clients, io_msInfo_7_bits_meta_alias, io_msInfo_7_bits_meta_prefetch, io_msInfo_7_bits_meta_prefetchSrc, io_msInfo_7_bits_meta_accessed, io_msInfo_7_bits_meta_tagErr, io_msInfo_7_bits_meta_dataErr};
  assign ms_meta[8] = '{io_msInfo_8_bits_meta_dirty, io_msInfo_8_bits_meta_state, io_msInfo_8_bits_meta_clients, io_msInfo_8_bits_meta_alias, io_msInfo_8_bits_meta_prefetch, io_msInfo_8_bits_meta_prefetchSrc, io_msInfo_8_bits_meta_accessed, io_msInfo_8_bits_meta_tagErr, io_msInfo_8_bits_meta_dataErr};
  assign ms_meta[9] = '{io_msInfo_9_bits_meta_dirty, io_msInfo_9_bits_meta_state, io_msInfo_9_bits_meta_clients, io_msInfo_9_bits_meta_alias, io_msInfo_9_bits_meta_prefetch, io_msInfo_9_bits_meta_prefetchSrc, io_msInfo_9_bits_meta_accessed, io_msInfo_9_bits_meta_tagErr, io_msInfo_9_bits_meta_dataErr};
  assign ms_meta[10] = '{io_msInfo_10_bits_meta_dirty, io_msInfo_10_bits_meta_state, io_msInfo_10_bits_meta_clients, io_msInfo_10_bits_meta_alias, io_msInfo_10_bits_meta_prefetch, io_msInfo_10_bits_meta_prefetchSrc, io_msInfo_10_bits_meta_accessed, io_msInfo_10_bits_meta_tagErr, io_msInfo_10_bits_meta_dataErr};
  assign ms_meta[11] = '{io_msInfo_11_bits_meta_dirty, io_msInfo_11_bits_meta_state, io_msInfo_11_bits_meta_clients, io_msInfo_11_bits_meta_alias, io_msInfo_11_bits_meta_prefetch, io_msInfo_11_bits_meta_prefetchSrc, io_msInfo_11_bits_meta_accessed, io_msInfo_11_bits_meta_tagErr, io_msInfo_11_bits_meta_dataErr};
  assign ms_meta[12] = '{io_msInfo_12_bits_meta_dirty, io_msInfo_12_bits_meta_state, io_msInfo_12_bits_meta_clients, io_msInfo_12_bits_meta_alias, io_msInfo_12_bits_meta_prefetch, io_msInfo_12_bits_meta_prefetchSrc, io_msInfo_12_bits_meta_accessed, io_msInfo_12_bits_meta_tagErr, io_msInfo_12_bits_meta_dataErr};
  assign ms_meta[13] = '{io_msInfo_13_bits_meta_dirty, io_msInfo_13_bits_meta_state, io_msInfo_13_bits_meta_clients, io_msInfo_13_bits_meta_alias, io_msInfo_13_bits_meta_prefetch, io_msInfo_13_bits_meta_prefetchSrc, io_msInfo_13_bits_meta_accessed, io_msInfo_13_bits_meta_tagErr, io_msInfo_13_bits_meta_dataErr};
  assign ms_meta[14] = '{io_msInfo_14_bits_meta_dirty, io_msInfo_14_bits_meta_state, io_msInfo_14_bits_meta_clients, io_msInfo_14_bits_meta_alias, io_msInfo_14_bits_meta_prefetch, io_msInfo_14_bits_meta_prefetchSrc, io_msInfo_14_bits_meta_accessed, io_msInfo_14_bits_meta_tagErr, io_msInfo_14_bits_meta_dataErr};
  assign ms_meta[15] = '{io_msInfo_15_bits_meta_dirty, io_msInfo_15_bits_meta_state, io_msInfo_15_bits_meta_clients, io_msInfo_15_bits_meta_alias, io_msInfo_15_bits_meta_prefetch, io_msInfo_15_bits_meta_prefetchSrc, io_msInfo_15_bits_meta_accessed, io_msInfo_15_bits_meta_tagErr, io_msInfo_15_bits_meta_dataErr};

  xs_RXSNP_core u_core (
    .clock                      (clock),
    .reset                      (reset),
    .snp_valid                  (snp_valid),
    .snp_ready                  (snp_ready),
    .snp_addr                   (snp_addr),
    .snp_txnID                  (snp_txnID),
    .snp_opcode                 (snp_opcode),
    .ms_valid                   ('{io_msInfo_0_valid, io_msInfo_1_valid, io_msInfo_2_valid, io_msInfo_3_valid, io_msInfo_4_valid, io_msInfo_5_valid, io_msInfo_6_valid, io_msInfo_7_valid, io_msInfo_8_valid, io_msInfo_9_valid, io_msInfo_10_valid, io_msInfo_11_valid, io_msInfo_12_valid, io_msInfo_13_valid, io_msInfo_14_valid, io_msInfo_15_valid}),
    .ms_set                     ('{io_msInfo_0_bits_set, io_msInfo_1_bits_set, io_msInfo_2_bits_set, io_msInfo_3_bits_set, io_msInfo_4_bits_set, io_msInfo_5_bits_set, io_msInfo_6_bits_set, io_msInfo_7_bits_set, io_msInfo_8_bits_set, io_msInfo_9_bits_set, io_msInfo_10_bits_set, io_msInfo_11_bits_set, io_msInfo_12_bits_set, io_msInfo_13_bits_set, io_msInfo_14_bits_set, io_msInfo_15_bits_set}),
    .ms_reqTag                  ('{io_msInfo_0_bits_reqTag, io_msInfo_1_bits_reqTag, io_msInfo_2_bits_reqTag, io_msInfo_3_bits_reqTag, io_msInfo_4_bits_reqTag, io_msInfo_5_bits_reqTag, io_msInfo_6_bits_reqTag, io_msInfo_7_bits_reqTag, io_msInfo_8_bits_reqTag, io_msInfo_9_bits_reqTag, io_msInfo_10_bits_reqTag, io_msInfo_11_bits_reqTag, io_msInfo_12_bits_reqTag, io_msInfo_13_bits_reqTag, io_msInfo_14_bits_reqTag, io_msInfo_15_bits_reqTag}),
    .ms_willFree                ('{io_msInfo_0_bits_willFree, io_msInfo_1_bits_willFree, io_msInfo_2_bits_willFree, io_msInfo_3_bits_willFree, io_msInfo_4_bits_willFree, io_msInfo_5_bits_willFree, io_msInfo_6_bits_willFree, io_msInfo_7_bits_willFree, io_msInfo_8_bits_willFree, io_msInfo_9_bits_willFree, io_msInfo_10_bits_willFree, io_msInfo_11_bits_willFree, io_msInfo_12_bits_willFree, io_msInfo_13_bits_willFree, io_msInfo_14_bits_willFree, io_msInfo_15_bits_willFree}),
    .ms_aliasTask               ('{io_msInfo_0_bits_aliasTask, io_msInfo_1_bits_aliasTask, io_msInfo_2_bits_aliasTask, io_msInfo_3_bits_aliasTask, io_msInfo_4_bits_aliasTask, io_msInfo_5_bits_aliasTask, io_msInfo_6_bits_aliasTask, io_msInfo_7_bits_aliasTask, io_msInfo_8_bits_aliasTask, io_msInfo_9_bits_aliasTask, io_msInfo_10_bits_aliasTask, io_msInfo_11_bits_aliasTask, io_msInfo_12_bits_aliasTask, io_msInfo_13_bits_aliasTask, io_msInfo_14_bits_aliasTask, io_msInfo_15_bits_aliasTask}),
    .ms_blockRefill             ('{io_msInfo_0_bits_blockRefill, io_msInfo_1_bits_blockRefill, io_msInfo_2_bits_blockRefill, io_msInfo_3_bits_blockRefill, io_msInfo_4_bits_blockRefill, io_msInfo_5_bits_blockRefill, io_msInfo_6_bits_blockRefill, io_msInfo_7_bits_blockRefill, io_msInfo_8_bits_blockRefill, io_msInfo_9_bits_blockRefill, io_msInfo_10_bits_blockRefill, io_msInfo_11_bits_blockRefill, io_msInfo_12_bits_blockRefill, io_msInfo_13_bits_blockRefill, io_msInfo_14_bits_blockRefill, io_msInfo_15_bits_blockRefill}),
    .ms_metaTag                 ('{io_msInfo_0_bits_metaTag, io_msInfo_1_bits_metaTag, io_msInfo_2_bits_metaTag, io_msInfo_3_bits_metaTag, io_msInfo_4_bits_metaTag, io_msInfo_5_bits_metaTag, io_msInfo_6_bits_metaTag, io_msInfo_7_bits_metaTag, io_msInfo_8_bits_metaTag, io_msInfo_9_bits_metaTag, io_msInfo_10_bits_metaTag, io_msInfo_11_bits_metaTag, io_msInfo_12_bits_metaTag, io_msInfo_13_bits_metaTag, io_msInfo_14_bits_metaTag, io_msInfo_15_bits_metaTag}),
    .ms_dirHit                  ('{io_msInfo_0_bits_dirHit, io_msInfo_1_bits_dirHit, io_msInfo_2_bits_dirHit, io_msInfo_3_bits_dirHit, io_msInfo_4_bits_dirHit, io_msInfo_5_bits_dirHit, io_msInfo_6_bits_dirHit, io_msInfo_7_bits_dirHit, io_msInfo_8_bits_dirHit, io_msInfo_9_bits_dirHit, io_msInfo_10_bits_dirHit, io_msInfo_11_bits_dirHit, io_msInfo_12_bits_dirHit, io_msInfo_13_bits_dirHit, io_msInfo_14_bits_dirHit, io_msInfo_15_bits_dirHit}),
    .ms_w_grantfirst            ('{io_msInfo_0_bits_w_grantfirst, io_msInfo_1_bits_w_grantfirst, io_msInfo_2_bits_w_grantfirst, io_msInfo_3_bits_w_grantfirst, io_msInfo_4_bits_w_grantfirst, io_msInfo_5_bits_w_grantfirst, io_msInfo_6_bits_w_grantfirst, io_msInfo_7_bits_w_grantfirst, io_msInfo_8_bits_w_grantfirst, io_msInfo_9_bits_w_grantfirst, io_msInfo_10_bits_w_grantfirst, io_msInfo_11_bits_w_grantfirst, io_msInfo_12_bits_w_grantfirst, io_msInfo_13_bits_w_grantfirst, io_msInfo_14_bits_w_grantfirst, io_msInfo_15_bits_w_grantfirst}),
    .ms_s_release               ('{io_msInfo_0_bits_s_release, io_msInfo_1_bits_s_release, io_msInfo_2_bits_s_release, io_msInfo_3_bits_s_release, io_msInfo_4_bits_s_release, io_msInfo_5_bits_s_release, io_msInfo_6_bits_s_release, io_msInfo_7_bits_s_release, io_msInfo_8_bits_s_release, io_msInfo_9_bits_s_release, io_msInfo_10_bits_s_release, io_msInfo_11_bits_s_release, io_msInfo_12_bits_s_release, io_msInfo_13_bits_s_release, io_msInfo_14_bits_s_release, io_msInfo_15_bits_s_release}),
    .ms_s_cmoresp               ('{io_msInfo_0_bits_s_cmoresp, io_msInfo_1_bits_s_cmoresp, io_msInfo_2_bits_s_cmoresp, io_msInfo_3_bits_s_cmoresp, io_msInfo_4_bits_s_cmoresp, io_msInfo_5_bits_s_cmoresp, io_msInfo_6_bits_s_cmoresp, io_msInfo_7_bits_s_cmoresp, io_msInfo_8_bits_s_cmoresp, io_msInfo_9_bits_s_cmoresp, io_msInfo_10_bits_s_cmoresp, io_msInfo_11_bits_s_cmoresp, io_msInfo_12_bits_s_cmoresp, io_msInfo_13_bits_s_cmoresp, io_msInfo_14_bits_s_cmoresp, io_msInfo_15_bits_s_cmoresp}),
    .ms_s_cmometaw              ('{io_msInfo_0_bits_s_cmometaw, io_msInfo_1_bits_s_cmometaw, io_msInfo_2_bits_s_cmometaw, io_msInfo_3_bits_s_cmometaw, io_msInfo_4_bits_s_cmometaw, io_msInfo_5_bits_s_cmometaw, io_msInfo_6_bits_s_cmometaw, io_msInfo_7_bits_s_cmometaw, io_msInfo_8_bits_s_cmometaw, io_msInfo_9_bits_s_cmometaw, io_msInfo_10_bits_s_cmometaw, io_msInfo_11_bits_s_cmometaw, io_msInfo_12_bits_s_cmometaw, io_msInfo_13_bits_s_cmometaw, io_msInfo_14_bits_s_cmometaw, io_msInfo_15_bits_s_cmometaw}),
    .ms_w_releaseack            ('{io_msInfo_0_bits_w_releaseack, io_msInfo_1_bits_w_releaseack, io_msInfo_2_bits_w_releaseack, io_msInfo_3_bits_w_releaseack, io_msInfo_4_bits_w_releaseack, io_msInfo_5_bits_w_releaseack, io_msInfo_6_bits_w_releaseack, io_msInfo_7_bits_w_releaseack, io_msInfo_8_bits_w_releaseack, io_msInfo_9_bits_w_releaseack, io_msInfo_10_bits_w_releaseack, io_msInfo_11_bits_w_releaseack, io_msInfo_12_bits_w_releaseack, io_msInfo_13_bits_w_releaseack, io_msInfo_14_bits_w_releaseack, io_msInfo_15_bits_w_releaseack}),
    .ms_w_replResp              ('{io_msInfo_0_bits_w_replResp, io_msInfo_1_bits_w_replResp, io_msInfo_2_bits_w_replResp, io_msInfo_3_bits_w_replResp, io_msInfo_4_bits_w_replResp, io_msInfo_5_bits_w_replResp, io_msInfo_6_bits_w_replResp, io_msInfo_7_bits_w_replResp, io_msInfo_8_bits_w_replResp, io_msInfo_9_bits_w_replResp, io_msInfo_10_bits_w_replResp, io_msInfo_11_bits_w_replResp, io_msInfo_12_bits_w_replResp, io_msInfo_13_bits_w_replResp, io_msInfo_14_bits_w_replResp, io_msInfo_15_bits_w_replResp}),
    .ms_w_rprobeacklast         ('{io_msInfo_0_bits_w_rprobeacklast, io_msInfo_1_bits_w_rprobeacklast, io_msInfo_2_bits_w_rprobeacklast, io_msInfo_3_bits_w_rprobeacklast, io_msInfo_4_bits_w_rprobeacklast, io_msInfo_5_bits_w_rprobeacklast, io_msInfo_6_bits_w_rprobeacklast, io_msInfo_7_bits_w_rprobeacklast, io_msInfo_8_bits_w_rprobeacklast, io_msInfo_9_bits_w_rprobeacklast, io_msInfo_10_bits_w_rprobeacklast, io_msInfo_11_bits_w_rprobeacklast, io_msInfo_12_bits_w_rprobeacklast, io_msInfo_13_bits_w_rprobeacklast, io_msInfo_14_bits_w_rprobeacklast, io_msInfo_15_bits_w_rprobeacklast}),
    .ms_replaceData             ('{io_msInfo_0_bits_replaceData, io_msInfo_1_bits_replaceData, io_msInfo_2_bits_replaceData, io_msInfo_3_bits_replaceData, io_msInfo_4_bits_replaceData, io_msInfo_5_bits_replaceData, io_msInfo_6_bits_replaceData, io_msInfo_7_bits_replaceData, io_msInfo_8_bits_replaceData, io_msInfo_9_bits_replaceData, io_msInfo_10_bits_replaceData, io_msInfo_11_bits_replaceData, io_msInfo_12_bits_replaceData, io_msInfo_13_bits_replaceData, io_msInfo_14_bits_replaceData, io_msInfo_15_bits_replaceData}),
    .ms_releaseToClean          ('{io_msInfo_0_bits_releaseToClean, io_msInfo_1_bits_releaseToClean, io_msInfo_2_bits_releaseToClean, io_msInfo_3_bits_releaseToClean, io_msInfo_4_bits_releaseToClean, io_msInfo_5_bits_releaseToClean, io_msInfo_6_bits_releaseToClean, io_msInfo_7_bits_releaseToClean, io_msInfo_8_bits_releaseToClean, io_msInfo_9_bits_releaseToClean, io_msInfo_10_bits_releaseToClean, io_msInfo_11_bits_releaseToClean, io_msInfo_12_bits_releaseToClean, io_msInfo_13_bits_releaseToClean, io_msInfo_14_bits_releaseToClean, io_msInfo_15_bits_releaseToClean}),
    .ms_meta                    (ms_meta),
    .task_ready                 (io_task_ready),
    .task_valid                 (io_task_valid),
    .task_set                   (io_task_bits_set),
    .task_tag                   (io_task_bits_tag),
    .task_off                   (io_task_bits_off),
    .task_snpHitRelease         (io_task_bits_snpHitRelease),
    .task_snpHitReleaseToInval  (io_task_bits_snpHitReleaseToInval),
    .task_snpHitReleaseToClean  (io_task_bits_snpHitReleaseToClean),
    .task_snpHitReleaseWithData (io_task_bits_snpHitReleaseWithData),
    .task_snpHitReleaseIdx      (io_task_bits_snpHitReleaseIdx),
    .task_snpHitReleaseMeta     (hitMeta),
    .task_txnID                 (io_task_bits_txnID),
    .task_chiOpcode             (io_task_bits_chiOpcode)
  );

  assign io_task_bits_snpHitReleaseMeta_dirty       = hitMeta.dirty;
  assign io_task_bits_snpHitReleaseMeta_state       = hitMeta.state;
  assign io_task_bits_snpHitReleaseMeta_clients     = hitMeta.clients;
  assign io_task_bits_snpHitReleaseMeta_alias       = hitMeta.alias_;
  assign io_task_bits_snpHitReleaseMeta_prefetch    = hitMeta.prefetch;
  assign io_task_bits_snpHitReleaseMeta_prefetchSrc = hitMeta.prefetchSrc;
  assign io_task_bits_snpHitReleaseMeta_accessed    = hitMeta.accessed;
  assign io_task_bits_snpHitReleaseMeta_tagErr      = hitMeta.tagErr;
  assign io_task_bits_snpHitReleaseMeta_dataErr     = hitMeta.dataErr;

endmodule
