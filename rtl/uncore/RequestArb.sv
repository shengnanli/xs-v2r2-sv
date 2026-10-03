// RequestArb.sv —— L2 slice 主流水线 MainPipe 的入口仲裁（s0 ~ s2）
//
// 对照 coupledL2/src/main/scala/coupledL2/RequestArb.scala。在 Slice 里的位置：
//   SinkA（L1 的 Acquire/Get/Hint）、RXSNP（CHI snoop，走 sinkB 口）、SinkC（L1 的 Release/ProbeAck）、
//   MSHR（mshrTask：回填/释放/响应等内部任务）四路任务 → 本模块 → MainPipe 的 s2（io_taskToPipe_s2）。
//
// 流水：
//   s0  MSHR 任务入口：没有被下游（GrantBuffer / TXDAT / TXRSP / TXREQ）挡住、s1 的 MSHR 任务不是在等
//       目录读的回填任务、且 s1→s2 能走时才收；收下后锁进 s1 寄存器 mshr_task_s1。
//   s1  MSHR 任务优先；没有 MSHR 任务时在三个通道里按 C > B > A 的固定优先级挑一个（各自没被 MSHRCtl /
//       MainPipe / GrantBuffer / TX 通道挡住才算有效）。通道任务与"需要读替换信息的回填任务"要读目录：
//       目录读口 ready 是进入 s2 的前提。s1 同时向 MainPipe 报本拍的任务（taskInfo_s1）、向 SinkA 报
//       本拍进入的 set（s1Entrance，用于挡同 set 的 A 请求）。
//   s2  task_s2 寄存器（= taskToPipe_s2）。DataStorage 是 MCP2（两拍一访问）：除 A 通道 Hint 外，
//       任何任务进 s2 都可能访问 DS，于是下一拍 s2_ready=0（ds_mcp2_stall）。
//       s2 还决定要不要读 MSHR 数据缓冲：refillBuf（回填数据要送上去 / 写回 DS）、releaseBuf（probe 回来的
//       数据、snoop 命中正在 release 的块）。
// 上电：resetIdx 从 511 数到 0（与目录初始化同步），这期间通道任务一律不收（MSHR 任务不受限）。
// golden 里的 assert 在 `ifndef SYNTHESIS 内；perf 计数器（XSPerfAccumulate）只被 perf 打印读，不属于电路。
// 本文件导航（共 2186 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L196   上电计数：resetIdx 511 -> 0，数完后 resetFinish=1
//   L211   s0：MSHR 任务入口
//   L231   s1：挑任务
//   L295   s2：任务寄存器、DS 两拍一访问的 stall、MSHR 数据缓冲读
//

package requestarb_pkg;
  // BEGIN GENERATED(task_t) —— scripts/gen_l2_requestarb.py 从 golden 端口表生成
  // TaskBundle（94 个字段，383 位）：字段顺序与位宽逐字取自 golden 端口 io_taskToPipe_s2_bits_*
  typedef struct packed {
    logic [2:0] channel;
    logic [2:0] txChannel;
    logic [8:0] set;
    logic [30:0] tag;
    logic [5:0] off;
    logic [1:0] alias_;
    logic [43:0] vaddr;
    logic isKeyword;
    logic [3:0] opcode;
    logic [2:0] param;
    logic [2:0] size;
    logic [6:0] sourceId;
    logic [1:0] bufIdx;
    logic needProbeAckData;
    logic denied;
    logic corrupt;
    logic mshrTask;
    logic [7:0] mshrId;
    logic aliasTask;
    logic useProbeData;
    logic mshrRetry;
    logic readProbeDataDown;
    logic fromL2pft;
    logic needHint;
    logic dirty;
    logic [2:0] way;
    logic meta_dirty;
    logic [1:0] meta_state;
    logic meta_clients;
    logic [1:0] meta_alias;
    logic meta_prefetch;
    logic [2:0] meta_prefetchSrc;
    logic meta_accessed;
    logic meta_tagErr;
    logic meta_dataErr;
    logic metaWen;
    logic tagWen;
    logic dsWen;
    logic [7:0] wayMask;
    logic replTask;
    logic cmoTask;
    logic cmoAll;
    logic [4:0] reqSource;
    logic mergeA;
    logic [5:0] aMergeTask_off;
    logic [1:0] aMergeTask_alias;
    logic [43:0] aMergeTask_vaddr;
    logic aMergeTask_isKeyword;
    logic [2:0] aMergeTask_opcode;
    logic [2:0] aMergeTask_param;
    logic [6:0] aMergeTask_sourceId;
    logic aMergeTask_meta_dirty;
    logic [1:0] aMergeTask_meta_state;
    logic aMergeTask_meta_clients;
    logic [1:0] aMergeTask_meta_alias;
    logic aMergeTask_meta_prefetch;
    logic [2:0] aMergeTask_meta_prefetchSrc;
    logic aMergeTask_meta_accessed;
    logic aMergeTask_meta_tagErr;
    logic aMergeTask_meta_dataErr;
    logic snpHitRelease;
    logic snpHitReleaseToInval;
    logic snpHitReleaseToClean;
    logic snpHitReleaseWithData;
    logic [7:0] snpHitReleaseIdx;
    logic snpHitReleaseMeta_dirty;
    logic [1:0] snpHitReleaseMeta_state;
    logic snpHitReleaseMeta_clients;
    logic [1:0] snpHitReleaseMeta_alias;
    logic snpHitReleaseMeta_prefetch;
    logic [2:0] snpHitReleaseMeta_prefetchSrc;
    logic snpHitReleaseMeta_accessed;
    logic snpHitReleaseMeta_tagErr;
    logic snpHitReleaseMeta_dataErr;
    logic [10:0] tgtID;
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [10:0] homeNID;
    logic [11:0] dbID;
    logic [10:0] fwdNID;
    logic [11:0] fwdTxnID;
    logic [6:0] chiOpcode;
    logic [2:0] resp;
    logic [2:0] fwdState;
    logic [3:0] pCrdType;
    logic retToSrc;
    logic likelyshared;
    logic expCompAck;
    logic allowRetry;
    logic memAttr_allocate;
    logic memAttr_cacheable;
    logic memAttr_device;
    logic memAttr_ewa;
    logic traceTag;
  } task_t;
  // END GENERATED(task_t)

  // TileLink D 通道 opcode（MSHR 回给上游的响应类型）
  localparam logic [3:0] AccessAckData = 4'd1;
  localparam logic [3:0] HintAck       = 4'd2;
  localparam logic [3:0] Grant         = 4'd4;
  localparam logic [3:0] GrantData     = 4'd5;
  localparam logic [3:0] A_Hint        = 4'd5;   // A 通道 Hint
  // CHI REQ opcode（回填后写回下游时用到的几种）
  localparam logic [6:0] CHI_Evict             = 7'h0D;
  localparam logic [6:0] CHI_WriteEvictFull    = 7'h15;
  localparam logic [6:0] CHI_WriteBackFull     = 7'h1B;
  localparam logic [6:0] CHI_WriteEvictOrEvict = 7'h42;
endpackage

module xs_RequestArb_core
  import requestarb_pkg::*;
(
  input  logic        clock,
  input  logic        reset,

  // ---- 四路任务入口 ----
  input  logic        sinkA_valid,
  output logic        sinkA_ready,
  input  task_t       sinkA_task,
  input  logic        sinkB_valid,
  output logic        sinkB_ready,
  input  task_t       sinkB_task,
  input  logic        sinkC_valid,
  output logic        sinkC_ready,
  input  task_t       sinkC_task,
  input  logic        mshrTask_valid,
  output logic        mshrTask_ready,
  input  task_t       mshrTask_task,

  // ---- 挡请求的外部条件 ----
  input  logic        blockA_mshrCtl,  blockB_mshrCtl,  blockC_mshrCtl,
  input  logic        blockA_mainPipe, blockB_mainPipe, blockC_mainPipe, blockG_mainPipe,
  input  logic        blockA_grantBuf, blockB_grantBuf, blockC_grantBuf, blockMSHR_grantBuf,
  input  logic        blockSinkB_txdat, blockMSHR_txdat,
  input  logic        blockSinkB_txrsp, blockMSHR_txrsp,
  input  logic        blockMSHR_txreq,

  // ---- s1：目录读 ----
  input  logic        dirRead_ready,
  output logic        dirRead_valid,
  output logic [7:0]  dirRead_wayMask,
  output logic        dirRead_refill_prefetch,
  output logic        dirRead_refill,

  // ---- s1 / s2 任务 ----
  output logic        task_s1_valid,
  output task_t       task_s1,
  output logic        s1_fire,
  output logic        task_s2_valid,
  output task_t       task_s2_bits,

  output logic        s1Entrance_valid,
  output logic [8:0]  s1Entrance_set,
  output logic [30:0] mshrTaskS1_tag,
  output logic [8:0]  mshrTaskS1_set,

  // ---- s2：MSHR 数据缓冲读 ----
  output logic        refillBufRead_valid,
  output logic [7:0]  refillBufRead_id,
  output logic        releaseBufRead_valid,
  output logic [7:0]  releaseBufRead_id
);

  // ===========================================================================
  // 上电计数：resetIdx 511 -> 0，数完后 resetFinish=1
  // ===========================================================================
  logic       resetFinish;
  logic [8:0] resetIdx;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      resetFinish <= 1'b0;
      resetIdx    <= 9'h1FF;
    end else begin
      resetFinish <= (resetIdx == 9'h0) | resetFinish;
      if (!resetFinish) resetIdx <= resetIdx - 9'd1;
    end
  end

  // ===========================================================================
  // s0：MSHR 任务入口
  // ===========================================================================
  logic  mshr_task_s1_valid;
  task_t mshr_task_s1_bits;
  logic  ds_mcp2_stall;          // 上一拍有可能访问 DS 的任务进了 s2
  logic  s2_ready;
  logic  s1_needs_replRead;      // s1 的 MSHR 任务是"回填上游 + 要选替换路"：得读目录
  logic  s0_fire;

  assign s2_ready = ~ds_mcp2_stall;

  assign s1_needs_replRead = mshr_task_s1_valid && mshr_task_s1_bits.channel[0] && mshr_task_s1_bits.replTask &&
                             (mshr_task_s1_bits.opcode == Grant || mshr_task_s1_bits.opcode == GrantData ||
                              mshr_task_s1_bits.opcode == AccessAckData || mshr_task_s1_bits.opcode == HintAck);

  assign mshrTask_ready = ~blockMSHR_grantBuf & ~s1_needs_replRead & ~(mshr_task_s1_valid & ~s2_ready) &
                          ~blockMSHR_txdat & ~blockMSHR_txrsp & ~blockMSHR_txreq;
  assign s0_fire = mshrTask_valid & mshrTask_ready;

  // ===========================================================================
  // s1：挑任务
  // ===========================================================================
  logic block_A, block_B, block_C;
  logic validC, validB, validA;               // 各通道"有请求且没被挡"
  logic sinkReadyBasic;
  logic chnl_valid;
  task_t chnl_task;
  logic replReadStall;                        // 回填任务在等目录读 / 被 MainPipe 挡住

  assign block_A = blockA_mshrCtl | blockA_mainPipe | blockA_grantBuf;
  assign block_B = blockB_mshrCtl | blockB_mainPipe | blockB_grantBuf | blockSinkB_txdat | blockSinkB_txrsp;
  assign block_C = blockC_mshrCtl | blockC_mainPipe | blockC_grantBuf;

  assign validC = sinkC_valid & ~block_C;
  assign validB = sinkB_valid & ~block_B;
  assign validA = sinkA_valid & ~block_A;

  // 通道任务只在：目录可读、初始化已完成、s1 没有 MSHR 任务、s2 能收 时才被接受；优先级 C > B > A
  assign sinkReadyBasic = dirRead_ready & resetFinish & ~mshr_task_s1_valid & s2_ready;
  assign sinkC_ready    = sinkReadyBasic & ~block_C;
  assign sinkB_ready    = sinkReadyBasic & ~block_B & ~validC;
  assign sinkA_ready    = sinkReadyBasic & ~block_A & ~validB & ~validC;

  assign chnl_valid = dirRead_ready & (validA | validB | validC) & resetFinish;
  assign chnl_task  = validC ? sinkC_task : (validB ? sinkB_task : sinkA_task);

  // MSHR 任务优先于通道任务
  assign task_s1_valid = mshr_task_s1_valid ? 1'b1 : chnl_valid;
  assign task_s1       = mshr_task_s1_valid ? mshr_task_s1_bits : chnl_task;

  assign replReadStall = mshr_task_s1_valid & s1_needs_replRead & (~dirRead_ready | blockG_mainPipe);
  assign s1_fire       = task_s1_valid & ~replReadStall & s2_ready;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      mshr_task_s1_valid <= 1'b0;
      mshr_task_s1_bits  <= '0;
    end else begin
      mshr_task_s1_valid <= (mshr_task_s1_valid & ~s1_fire) | s0_fire;
      if (s0_fire) mshr_task_s1_bits <= mshrTask_task;
    end
  end

  // 目录读：通道任务，或不被挡住的回填任务
  assign dirRead_valid = s2_ready & ((chnl_valid & ~mshr_task_s1_valid) | (s1_needs_replRead & ~blockG_mainPipe));
  // 上次因这一路冲突而 retry 的 MSHR 任务：把那一路从候选里去掉
  assign dirRead_wayMask = (mshr_task_s1_valid && mshr_task_s1_bits.mshrRetry)
                         ? ~(8'd1 << mshr_task_s1_bits.way) : 8'hFF;
  assign dirRead_refill_prefetch = s1_needs_replRead & (mshr_task_s1_bits.opcode == HintAck) & mshr_task_s1_bits.dsWen;
  assign dirRead_refill          = s1_needs_replRead;

  // 同 set 的 A 请求要被挡：报本拍进入 s1 的 set（MSHR 写 meta 的任务 / C / B 进入）
  logic sinkC_fire, sinkB_fire, sinkA_fire;
  assign sinkC_fire = sinkC_ready & sinkC_valid;
  assign sinkB_fire = sinkB_ready & sinkB_valid;
  assign sinkA_fire = sinkA_ready & sinkA_valid;

  assign s1Entrance_valid = (mshr_task_s1_valid & s2_ready & mshr_task_s1_bits.metaWen) | sinkC_fire | sinkB_fire;
  assign s1Entrance_set   = (mshr_task_s1_valid & mshr_task_s1_bits.metaWen) ? mshr_task_s1_bits.set
                          : (sinkC_fire ? sinkC_task.set : sinkB_task.set);
  assign mshrTaskS1_tag   = mshr_task_s1_bits.tag;
  assign mshrTaskS1_set   = mshr_task_s1_bits.set;

  // ===========================================================================
  // s2：任务寄存器、DS 两拍一访问的 stall、MSHR 数据缓冲读
  // ===========================================================================
  always_ff @(posedge clock) begin
    // 除 A 通道 Hint 外的任何任务进 s2，下一拍都不许再进（DS 两拍一访问）
    ds_mcp2_stall <= s1_fire & ~(sinkA_fire & (sinkA_task.opcode == A_Hint));
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      task_s2_valid <= 1'b0;
      task_s2_bits  <= '0;
    end else begin
      task_s2_valid <= s1_fire;
      if (s1_fire) task_s2_bits <= task_s1;
    end
  end

  // MSHR 数据缓冲读
  logic mshrTask_s2, aUpwards_s2, releaseRefillData;
  assign mshrTask_s2 = task_s2_valid & task_s2_bits.mshrTask;
  // 往上游（A 通道）送数据或要写 DS 的回填响应
  assign aUpwards_s2 = task_s2_bits.channel[0] &
                       (task_s2_bits.opcode == GrantData || (task_s2_bits.opcode == Grant && task_s2_bits.dsWen) ||
                        task_s2_bits.opcode == AccessAckData || (task_s2_bits.opcode == HintAck && task_s2_bits.dsWen));
  // 替换出去的块要写回下游（走 TXREQ 的 WriteBack/WriteEvict/Evict）：数据还在 refillBuf
  assign releaseRefillData = task_s2_bits.replTask & task_s2_bits.txChannel[0] &
                             (task_s2_bits.chiOpcode == CHI_WriteBackFull || task_s2_bits.chiOpcode == CHI_WriteEvictFull ||
                              task_s2_bits.chiOpcode == CHI_WriteEvictOrEvict || task_s2_bits.chiOpcode == CHI_Evict);

  assign refillBufRead_valid = mshrTask_s2 & (releaseRefillData | (aUpwards_s2 & ~task_s2_bits.useProbeData));
  assign refillBufRead_id    = task_s2_bits.mshrId;

  assign releaseBufRead_valid = task_s2_valid & (mshrTask_s2
                              ? (task_s2_bits.readProbeDataDown | (aUpwards_s2 & task_s2_bits.useProbeData))
                              : (task_s2_bits.channel[1] & task_s2_bits.snpHitReleaseWithData));
  assign releaseBufRead_id    = task_s2_bits.snpHitRelease ? task_s2_bits.snpHitReleaseIdx : task_s2_bits.mshrId;

endmodule

// BEGIN GENERATED(wrapper) —— scripts/gen_l2_requestarb.py 从 golden 端口表生成
module RequestArb
  import requestarb_pkg::*;
(
  input  logic clock,
  input  logic reset,
  output logic io_sinkA_ready,
  input  logic io_sinkA_valid,
  input  logic [2:0] io_sinkA_bits_channel,
  input  logic [2:0] io_sinkA_bits_txChannel,
  input  logic [8:0] io_sinkA_bits_set,
  input  logic [30:0] io_sinkA_bits_tag,
  input  logic [5:0] io_sinkA_bits_off,
  input  logic [1:0] io_sinkA_bits_alias,
  input  logic [43:0] io_sinkA_bits_vaddr,
  input  logic io_sinkA_bits_isKeyword,
  input  logic [3:0] io_sinkA_bits_opcode,
  input  logic [2:0] io_sinkA_bits_param,
  input  logic [2:0] io_sinkA_bits_size,
  input  logic [6:0] io_sinkA_bits_sourceId,
  input  logic [1:0] io_sinkA_bits_bufIdx,
  input  logic io_sinkA_bits_needProbeAckData,
  input  logic io_sinkA_bits_denied,
  input  logic io_sinkA_bits_corrupt,
  input  logic io_sinkA_bits_mshrTask,
  input  logic [7:0] io_sinkA_bits_mshrId,
  input  logic io_sinkA_bits_aliasTask,
  input  logic io_sinkA_bits_useProbeData,
  input  logic io_sinkA_bits_mshrRetry,
  input  logic io_sinkA_bits_readProbeDataDown,
  input  logic io_sinkA_bits_fromL2pft,
  input  logic io_sinkA_bits_needHint,
  input  logic io_sinkA_bits_dirty,
  input  logic [2:0] io_sinkA_bits_way,
  input  logic io_sinkA_bits_meta_dirty,
  input  logic [1:0] io_sinkA_bits_meta_state,
  input  logic io_sinkA_bits_meta_clients,
  input  logic [1:0] io_sinkA_bits_meta_alias,
  input  logic io_sinkA_bits_meta_prefetch,
  input  logic [2:0] io_sinkA_bits_meta_prefetchSrc,
  input  logic io_sinkA_bits_meta_accessed,
  input  logic io_sinkA_bits_meta_tagErr,
  input  logic io_sinkA_bits_meta_dataErr,
  input  logic io_sinkA_bits_metaWen,
  input  logic io_sinkA_bits_tagWen,
  input  logic io_sinkA_bits_dsWen,
  input  logic [7:0] io_sinkA_bits_wayMask,
  input  logic io_sinkA_bits_replTask,
  input  logic io_sinkA_bits_cmoTask,
  input  logic io_sinkA_bits_cmoAll,
  input  logic [4:0] io_sinkA_bits_reqSource,
  input  logic io_sinkA_bits_mergeA,
  input  logic [5:0] io_sinkA_bits_aMergeTask_off,
  input  logic [1:0] io_sinkA_bits_aMergeTask_alias,
  input  logic [43:0] io_sinkA_bits_aMergeTask_vaddr,
  input  logic io_sinkA_bits_aMergeTask_isKeyword,
  input  logic [2:0] io_sinkA_bits_aMergeTask_opcode,
  input  logic [2:0] io_sinkA_bits_aMergeTask_param,
  input  logic [6:0] io_sinkA_bits_aMergeTask_sourceId,
  input  logic io_sinkA_bits_aMergeTask_meta_dirty,
  input  logic [1:0] io_sinkA_bits_aMergeTask_meta_state,
  input  logic io_sinkA_bits_aMergeTask_meta_clients,
  input  logic [1:0] io_sinkA_bits_aMergeTask_meta_alias,
  input  logic io_sinkA_bits_aMergeTask_meta_prefetch,
  input  logic [2:0] io_sinkA_bits_aMergeTask_meta_prefetchSrc,
  input  logic io_sinkA_bits_aMergeTask_meta_accessed,
  input  logic io_sinkA_bits_aMergeTask_meta_tagErr,
  input  logic io_sinkA_bits_aMergeTask_meta_dataErr,
  input  logic io_sinkA_bits_snpHitRelease,
  input  logic io_sinkA_bits_snpHitReleaseToInval,
  input  logic io_sinkA_bits_snpHitReleaseToClean,
  input  logic io_sinkA_bits_snpHitReleaseWithData,
  input  logic [7:0] io_sinkA_bits_snpHitReleaseIdx,
  input  logic io_sinkA_bits_snpHitReleaseMeta_dirty,
  input  logic [1:0] io_sinkA_bits_snpHitReleaseMeta_state,
  input  logic io_sinkA_bits_snpHitReleaseMeta_clients,
  input  logic [1:0] io_sinkA_bits_snpHitReleaseMeta_alias,
  input  logic io_sinkA_bits_snpHitReleaseMeta_prefetch,
  input  logic [2:0] io_sinkA_bits_snpHitReleaseMeta_prefetchSrc,
  input  logic io_sinkA_bits_snpHitReleaseMeta_accessed,
  input  logic io_sinkA_bits_snpHitReleaseMeta_tagErr,
  input  logic io_sinkA_bits_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_sinkA_bits_tgtID,
  input  logic [10:0] io_sinkA_bits_srcID,
  input  logic [11:0] io_sinkA_bits_txnID,
  input  logic [10:0] io_sinkA_bits_homeNID,
  input  logic [11:0] io_sinkA_bits_dbID,
  input  logic [10:0] io_sinkA_bits_fwdNID,
  input  logic [11:0] io_sinkA_bits_fwdTxnID,
  input  logic [6:0] io_sinkA_bits_chiOpcode,
  input  logic [2:0] io_sinkA_bits_resp,
  input  logic [2:0] io_sinkA_bits_fwdState,
  input  logic [3:0] io_sinkA_bits_pCrdType,
  input  logic io_sinkA_bits_retToSrc,
  input  logic io_sinkA_bits_likelyshared,
  input  logic io_sinkA_bits_expCompAck,
  input  logic io_sinkA_bits_allowRetry,
  input  logic io_sinkA_bits_memAttr_allocate,
  input  logic io_sinkA_bits_memAttr_cacheable,
  input  logic io_sinkA_bits_memAttr_device,
  input  logic io_sinkA_bits_memAttr_ewa,
  input  logic io_sinkA_bits_traceTag,
  input  logic [30:0] io_ATag,
  input  logic [8:0] io_ASet,
  output logic io_s1Entrance_valid,
  output logic [8:0] io_s1Entrance_bits_set,
  output logic io_sinkB_ready,
  input  logic io_sinkB_valid,
  input  logic [2:0] io_sinkB_bits_channel,
  input  logic [2:0] io_sinkB_bits_txChannel,
  input  logic [8:0] io_sinkB_bits_set,
  input  logic [30:0] io_sinkB_bits_tag,
  input  logic [5:0] io_sinkB_bits_off,
  input  logic [1:0] io_sinkB_bits_alias,
  input  logic [43:0] io_sinkB_bits_vaddr,
  input  logic io_sinkB_bits_isKeyword,
  input  logic [3:0] io_sinkB_bits_opcode,
  input  logic [2:0] io_sinkB_bits_param,
  input  logic [2:0] io_sinkB_bits_size,
  input  logic [6:0] io_sinkB_bits_sourceId,
  input  logic [1:0] io_sinkB_bits_bufIdx,
  input  logic io_sinkB_bits_needProbeAckData,
  input  logic io_sinkB_bits_denied,
  input  logic io_sinkB_bits_corrupt,
  input  logic io_sinkB_bits_mshrTask,
  input  logic [7:0] io_sinkB_bits_mshrId,
  input  logic io_sinkB_bits_aliasTask,
  input  logic io_sinkB_bits_useProbeData,
  input  logic io_sinkB_bits_mshrRetry,
  input  logic io_sinkB_bits_readProbeDataDown,
  input  logic io_sinkB_bits_fromL2pft,
  input  logic io_sinkB_bits_needHint,
  input  logic io_sinkB_bits_dirty,
  input  logic [2:0] io_sinkB_bits_way,
  input  logic io_sinkB_bits_meta_dirty,
  input  logic [1:0] io_sinkB_bits_meta_state,
  input  logic io_sinkB_bits_meta_clients,
  input  logic [1:0] io_sinkB_bits_meta_alias,
  input  logic io_sinkB_bits_meta_prefetch,
  input  logic [2:0] io_sinkB_bits_meta_prefetchSrc,
  input  logic io_sinkB_bits_meta_accessed,
  input  logic io_sinkB_bits_meta_tagErr,
  input  logic io_sinkB_bits_meta_dataErr,
  input  logic io_sinkB_bits_metaWen,
  input  logic io_sinkB_bits_tagWen,
  input  logic io_sinkB_bits_dsWen,
  input  logic [7:0] io_sinkB_bits_wayMask,
  input  logic io_sinkB_bits_replTask,
  input  logic io_sinkB_bits_cmoTask,
  input  logic io_sinkB_bits_cmoAll,
  input  logic [4:0] io_sinkB_bits_reqSource,
  input  logic io_sinkB_bits_mergeA,
  input  logic [5:0] io_sinkB_bits_aMergeTask_off,
  input  logic [1:0] io_sinkB_bits_aMergeTask_alias,
  input  logic [43:0] io_sinkB_bits_aMergeTask_vaddr,
  input  logic io_sinkB_bits_aMergeTask_isKeyword,
  input  logic [2:0] io_sinkB_bits_aMergeTask_opcode,
  input  logic [2:0] io_sinkB_bits_aMergeTask_param,
  input  logic [6:0] io_sinkB_bits_aMergeTask_sourceId,
  input  logic io_sinkB_bits_aMergeTask_meta_dirty,
  input  logic [1:0] io_sinkB_bits_aMergeTask_meta_state,
  input  logic io_sinkB_bits_aMergeTask_meta_clients,
  input  logic [1:0] io_sinkB_bits_aMergeTask_meta_alias,
  input  logic io_sinkB_bits_aMergeTask_meta_prefetch,
  input  logic [2:0] io_sinkB_bits_aMergeTask_meta_prefetchSrc,
  input  logic io_sinkB_bits_aMergeTask_meta_accessed,
  input  logic io_sinkB_bits_aMergeTask_meta_tagErr,
  input  logic io_sinkB_bits_aMergeTask_meta_dataErr,
  input  logic io_sinkB_bits_snpHitRelease,
  input  logic io_sinkB_bits_snpHitReleaseToInval,
  input  logic io_sinkB_bits_snpHitReleaseToClean,
  input  logic io_sinkB_bits_snpHitReleaseWithData,
  input  logic [7:0] io_sinkB_bits_snpHitReleaseIdx,
  input  logic io_sinkB_bits_snpHitReleaseMeta_dirty,
  input  logic [1:0] io_sinkB_bits_snpHitReleaseMeta_state,
  input  logic io_sinkB_bits_snpHitReleaseMeta_clients,
  input  logic [1:0] io_sinkB_bits_snpHitReleaseMeta_alias,
  input  logic io_sinkB_bits_snpHitReleaseMeta_prefetch,
  input  logic [2:0] io_sinkB_bits_snpHitReleaseMeta_prefetchSrc,
  input  logic io_sinkB_bits_snpHitReleaseMeta_accessed,
  input  logic io_sinkB_bits_snpHitReleaseMeta_tagErr,
  input  logic io_sinkB_bits_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_sinkB_bits_tgtID,
  input  logic [10:0] io_sinkB_bits_srcID,
  input  logic [11:0] io_sinkB_bits_txnID,
  input  logic [10:0] io_sinkB_bits_homeNID,
  input  logic [11:0] io_sinkB_bits_dbID,
  input  logic [10:0] io_sinkB_bits_fwdNID,
  input  logic [11:0] io_sinkB_bits_fwdTxnID,
  input  logic [6:0] io_sinkB_bits_chiOpcode,
  input  logic [2:0] io_sinkB_bits_resp,
  input  logic [2:0] io_sinkB_bits_fwdState,
  input  logic [3:0] io_sinkB_bits_pCrdType,
  input  logic io_sinkB_bits_retToSrc,
  input  logic io_sinkB_bits_likelyshared,
  input  logic io_sinkB_bits_expCompAck,
  input  logic io_sinkB_bits_allowRetry,
  input  logic io_sinkB_bits_memAttr_allocate,
  input  logic io_sinkB_bits_memAttr_cacheable,
  input  logic io_sinkB_bits_memAttr_device,
  input  logic io_sinkB_bits_memAttr_ewa,
  input  logic io_sinkB_bits_traceTag,
  output logic io_sinkC_ready,
  input  logic io_sinkC_valid,
  input  logic [2:0] io_sinkC_bits_channel,
  input  logic [2:0] io_sinkC_bits_txChannel,
  input  logic [8:0] io_sinkC_bits_set,
  input  logic [30:0] io_sinkC_bits_tag,
  input  logic [5:0] io_sinkC_bits_off,
  input  logic [1:0] io_sinkC_bits_alias,
  input  logic [43:0] io_sinkC_bits_vaddr,
  input  logic io_sinkC_bits_isKeyword,
  input  logic [3:0] io_sinkC_bits_opcode,
  input  logic [2:0] io_sinkC_bits_param,
  input  logic [2:0] io_sinkC_bits_size,
  input  logic [6:0] io_sinkC_bits_sourceId,
  input  logic [1:0] io_sinkC_bits_bufIdx,
  input  logic io_sinkC_bits_needProbeAckData,
  input  logic io_sinkC_bits_denied,
  input  logic io_sinkC_bits_corrupt,
  input  logic io_sinkC_bits_mshrTask,
  input  logic [7:0] io_sinkC_bits_mshrId,
  input  logic io_sinkC_bits_aliasTask,
  input  logic io_sinkC_bits_useProbeData,
  input  logic io_sinkC_bits_mshrRetry,
  input  logic io_sinkC_bits_readProbeDataDown,
  input  logic io_sinkC_bits_fromL2pft,
  input  logic io_sinkC_bits_needHint,
  input  logic io_sinkC_bits_dirty,
  input  logic [2:0] io_sinkC_bits_way,
  input  logic io_sinkC_bits_meta_dirty,
  input  logic [1:0] io_sinkC_bits_meta_state,
  input  logic io_sinkC_bits_meta_clients,
  input  logic [1:0] io_sinkC_bits_meta_alias,
  input  logic io_sinkC_bits_meta_prefetch,
  input  logic [2:0] io_sinkC_bits_meta_prefetchSrc,
  input  logic io_sinkC_bits_meta_accessed,
  input  logic io_sinkC_bits_meta_tagErr,
  input  logic io_sinkC_bits_meta_dataErr,
  input  logic io_sinkC_bits_metaWen,
  input  logic io_sinkC_bits_tagWen,
  input  logic io_sinkC_bits_dsWen,
  input  logic [7:0] io_sinkC_bits_wayMask,
  input  logic io_sinkC_bits_replTask,
  input  logic io_sinkC_bits_cmoTask,
  input  logic io_sinkC_bits_cmoAll,
  input  logic [4:0] io_sinkC_bits_reqSource,
  input  logic io_sinkC_bits_mergeA,
  input  logic [5:0] io_sinkC_bits_aMergeTask_off,
  input  logic [1:0] io_sinkC_bits_aMergeTask_alias,
  input  logic [43:0] io_sinkC_bits_aMergeTask_vaddr,
  input  logic io_sinkC_bits_aMergeTask_isKeyword,
  input  logic [2:0] io_sinkC_bits_aMergeTask_opcode,
  input  logic [2:0] io_sinkC_bits_aMergeTask_param,
  input  logic [6:0] io_sinkC_bits_aMergeTask_sourceId,
  input  logic io_sinkC_bits_aMergeTask_meta_dirty,
  input  logic [1:0] io_sinkC_bits_aMergeTask_meta_state,
  input  logic io_sinkC_bits_aMergeTask_meta_clients,
  input  logic [1:0] io_sinkC_bits_aMergeTask_meta_alias,
  input  logic io_sinkC_bits_aMergeTask_meta_prefetch,
  input  logic [2:0] io_sinkC_bits_aMergeTask_meta_prefetchSrc,
  input  logic io_sinkC_bits_aMergeTask_meta_accessed,
  input  logic io_sinkC_bits_aMergeTask_meta_tagErr,
  input  logic io_sinkC_bits_aMergeTask_meta_dataErr,
  input  logic io_sinkC_bits_snpHitRelease,
  input  logic io_sinkC_bits_snpHitReleaseToInval,
  input  logic io_sinkC_bits_snpHitReleaseToClean,
  input  logic io_sinkC_bits_snpHitReleaseWithData,
  input  logic [7:0] io_sinkC_bits_snpHitReleaseIdx,
  input  logic io_sinkC_bits_snpHitReleaseMeta_dirty,
  input  logic [1:0] io_sinkC_bits_snpHitReleaseMeta_state,
  input  logic io_sinkC_bits_snpHitReleaseMeta_clients,
  input  logic [1:0] io_sinkC_bits_snpHitReleaseMeta_alias,
  input  logic io_sinkC_bits_snpHitReleaseMeta_prefetch,
  input  logic [2:0] io_sinkC_bits_snpHitReleaseMeta_prefetchSrc,
  input  logic io_sinkC_bits_snpHitReleaseMeta_accessed,
  input  logic io_sinkC_bits_snpHitReleaseMeta_tagErr,
  input  logic io_sinkC_bits_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_sinkC_bits_tgtID,
  input  logic [10:0] io_sinkC_bits_srcID,
  input  logic [11:0] io_sinkC_bits_txnID,
  input  logic [10:0] io_sinkC_bits_homeNID,
  input  logic [11:0] io_sinkC_bits_dbID,
  input  logic [10:0] io_sinkC_bits_fwdNID,
  input  logic [11:0] io_sinkC_bits_fwdTxnID,
  input  logic [6:0] io_sinkC_bits_chiOpcode,
  input  logic [2:0] io_sinkC_bits_resp,
  input  logic [2:0] io_sinkC_bits_fwdState,
  input  logic [3:0] io_sinkC_bits_pCrdType,
  input  logic io_sinkC_bits_retToSrc,
  input  logic io_sinkC_bits_likelyshared,
  input  logic io_sinkC_bits_expCompAck,
  input  logic io_sinkC_bits_allowRetry,
  input  logic io_sinkC_bits_memAttr_allocate,
  input  logic io_sinkC_bits_memAttr_cacheable,
  input  logic io_sinkC_bits_memAttr_device,
  input  logic io_sinkC_bits_memAttr_ewa,
  input  logic io_sinkC_bits_traceTag,
  output logic io_mshrTask_ready,
  input  logic io_mshrTask_valid,
  input  logic [2:0] io_mshrTask_bits_channel,
  input  logic [2:0] io_mshrTask_bits_txChannel,
  input  logic [8:0] io_mshrTask_bits_set,
  input  logic [30:0] io_mshrTask_bits_tag,
  input  logic [5:0] io_mshrTask_bits_off,
  input  logic [1:0] io_mshrTask_bits_alias,
  input  logic [43:0] io_mshrTask_bits_vaddr,
  input  logic io_mshrTask_bits_isKeyword,
  input  logic [3:0] io_mshrTask_bits_opcode,
  input  logic [2:0] io_mshrTask_bits_param,
  input  logic [2:0] io_mshrTask_bits_size,
  input  logic [6:0] io_mshrTask_bits_sourceId,
  input  logic [1:0] io_mshrTask_bits_bufIdx,
  input  logic io_mshrTask_bits_needProbeAckData,
  input  logic io_mshrTask_bits_denied,
  input  logic io_mshrTask_bits_corrupt,
  input  logic io_mshrTask_bits_mshrTask,
  input  logic [7:0] io_mshrTask_bits_mshrId,
  input  logic io_mshrTask_bits_aliasTask,
  input  logic io_mshrTask_bits_useProbeData,
  input  logic io_mshrTask_bits_mshrRetry,
  input  logic io_mshrTask_bits_readProbeDataDown,
  input  logic io_mshrTask_bits_fromL2pft,
  input  logic io_mshrTask_bits_needHint,
  input  logic io_mshrTask_bits_dirty,
  input  logic [2:0] io_mshrTask_bits_way,
  input  logic io_mshrTask_bits_meta_dirty,
  input  logic [1:0] io_mshrTask_bits_meta_state,
  input  logic io_mshrTask_bits_meta_clients,
  input  logic [1:0] io_mshrTask_bits_meta_alias,
  input  logic io_mshrTask_bits_meta_prefetch,
  input  logic [2:0] io_mshrTask_bits_meta_prefetchSrc,
  input  logic io_mshrTask_bits_meta_accessed,
  input  logic io_mshrTask_bits_meta_tagErr,
  input  logic io_mshrTask_bits_meta_dataErr,
  input  logic io_mshrTask_bits_metaWen,
  input  logic io_mshrTask_bits_tagWen,
  input  logic io_mshrTask_bits_dsWen,
  input  logic [7:0] io_mshrTask_bits_wayMask,
  input  logic io_mshrTask_bits_replTask,
  input  logic io_mshrTask_bits_cmoTask,
  input  logic io_mshrTask_bits_cmoAll,
  input  logic [4:0] io_mshrTask_bits_reqSource,
  input  logic io_mshrTask_bits_mergeA,
  input  logic [5:0] io_mshrTask_bits_aMergeTask_off,
  input  logic [1:0] io_mshrTask_bits_aMergeTask_alias,
  input  logic [43:0] io_mshrTask_bits_aMergeTask_vaddr,
  input  logic io_mshrTask_bits_aMergeTask_isKeyword,
  input  logic [2:0] io_mshrTask_bits_aMergeTask_opcode,
  input  logic [2:0] io_mshrTask_bits_aMergeTask_param,
  input  logic [6:0] io_mshrTask_bits_aMergeTask_sourceId,
  input  logic io_mshrTask_bits_aMergeTask_meta_dirty,
  input  logic [1:0] io_mshrTask_bits_aMergeTask_meta_state,
  input  logic io_mshrTask_bits_aMergeTask_meta_clients,
  input  logic [1:0] io_mshrTask_bits_aMergeTask_meta_alias,
  input  logic io_mshrTask_bits_aMergeTask_meta_prefetch,
  input  logic [2:0] io_mshrTask_bits_aMergeTask_meta_prefetchSrc,
  input  logic io_mshrTask_bits_aMergeTask_meta_accessed,
  input  logic io_mshrTask_bits_aMergeTask_meta_tagErr,
  input  logic io_mshrTask_bits_aMergeTask_meta_dataErr,
  input  logic io_mshrTask_bits_snpHitRelease,
  input  logic io_mshrTask_bits_snpHitReleaseToInval,
  input  logic io_mshrTask_bits_snpHitReleaseToClean,
  input  logic io_mshrTask_bits_snpHitReleaseWithData,
  input  logic [7:0] io_mshrTask_bits_snpHitReleaseIdx,
  input  logic io_mshrTask_bits_snpHitReleaseMeta_dirty,
  input  logic [1:0] io_mshrTask_bits_snpHitReleaseMeta_state,
  input  logic io_mshrTask_bits_snpHitReleaseMeta_clients,
  input  logic [1:0] io_mshrTask_bits_snpHitReleaseMeta_alias,
  input  logic io_mshrTask_bits_snpHitReleaseMeta_prefetch,
  input  logic [2:0] io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc,
  input  logic io_mshrTask_bits_snpHitReleaseMeta_accessed,
  input  logic io_mshrTask_bits_snpHitReleaseMeta_tagErr,
  input  logic io_mshrTask_bits_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_mshrTask_bits_tgtID,
  input  logic [10:0] io_mshrTask_bits_srcID,
  input  logic [11:0] io_mshrTask_bits_txnID,
  input  logic [10:0] io_mshrTask_bits_homeNID,
  input  logic [11:0] io_mshrTask_bits_dbID,
  input  logic [10:0] io_mshrTask_bits_fwdNID,
  input  logic [11:0] io_mshrTask_bits_fwdTxnID,
  input  logic [6:0] io_mshrTask_bits_chiOpcode,
  input  logic [2:0] io_mshrTask_bits_resp,
  input  logic [2:0] io_mshrTask_bits_fwdState,
  input  logic [3:0] io_mshrTask_bits_pCrdType,
  input  logic io_mshrTask_bits_retToSrc,
  input  logic io_mshrTask_bits_likelyshared,
  input  logic io_mshrTask_bits_expCompAck,
  input  logic io_mshrTask_bits_allowRetry,
  input  logic io_mshrTask_bits_memAttr_allocate,
  input  logic io_mshrTask_bits_memAttr_cacheable,
  input  logic io_mshrTask_bits_memAttr_device,
  input  logic io_mshrTask_bits_memAttr_ewa,
  input  logic io_mshrTask_bits_traceTag,
  input  logic io_dirRead_s1_ready,
  output logic io_dirRead_s1_valid,
  output logic [30:0] io_dirRead_s1_bits_tag,
  output logic [8:0] io_dirRead_s1_bits_set,
  output logic [7:0] io_dirRead_s1_bits_wayMask,
  output logic [2:0] io_dirRead_s1_bits_replacerInfo_channel,
  output logic [2:0] io_dirRead_s1_bits_replacerInfo_opcode,
  output logic [4:0] io_dirRead_s1_bits_replacerInfo_reqSource,
  output logic io_dirRead_s1_bits_replacerInfo_refill_prefetch,
  output logic io_dirRead_s1_bits_refill,
  output logic [7:0] io_dirRead_s1_bits_mshrId,
  output logic io_dirRead_s1_bits_cmoAll,
  output logic [2:0] io_dirRead_s1_bits_cmoWay,
  output logic io_taskToPipe_s2_valid,
  output logic [2:0] io_taskToPipe_s2_bits_channel,
  output logic [2:0] io_taskToPipe_s2_bits_txChannel,
  output logic [8:0] io_taskToPipe_s2_bits_set,
  output logic [30:0] io_taskToPipe_s2_bits_tag,
  output logic [5:0] io_taskToPipe_s2_bits_off,
  output logic [1:0] io_taskToPipe_s2_bits_alias,
  output logic [43:0] io_taskToPipe_s2_bits_vaddr,
  output logic io_taskToPipe_s2_bits_isKeyword,
  output logic [3:0] io_taskToPipe_s2_bits_opcode,
  output logic [2:0] io_taskToPipe_s2_bits_param,
  output logic [2:0] io_taskToPipe_s2_bits_size,
  output logic [6:0] io_taskToPipe_s2_bits_sourceId,
  output logic [1:0] io_taskToPipe_s2_bits_bufIdx,
  output logic io_taskToPipe_s2_bits_needProbeAckData,
  output logic io_taskToPipe_s2_bits_denied,
  output logic io_taskToPipe_s2_bits_corrupt,
  output logic io_taskToPipe_s2_bits_mshrTask,
  output logic [7:0] io_taskToPipe_s2_bits_mshrId,
  output logic io_taskToPipe_s2_bits_aliasTask,
  output logic io_taskToPipe_s2_bits_useProbeData,
  output logic io_taskToPipe_s2_bits_mshrRetry,
  output logic io_taskToPipe_s2_bits_readProbeDataDown,
  output logic io_taskToPipe_s2_bits_fromL2pft,
  output logic io_taskToPipe_s2_bits_needHint,
  output logic io_taskToPipe_s2_bits_dirty,
  output logic [2:0] io_taskToPipe_s2_bits_way,
  output logic io_taskToPipe_s2_bits_meta_dirty,
  output logic [1:0] io_taskToPipe_s2_bits_meta_state,
  output logic io_taskToPipe_s2_bits_meta_clients,
  output logic [1:0] io_taskToPipe_s2_bits_meta_alias,
  output logic io_taskToPipe_s2_bits_meta_prefetch,
  output logic [2:0] io_taskToPipe_s2_bits_meta_prefetchSrc,
  output logic io_taskToPipe_s2_bits_meta_accessed,
  output logic io_taskToPipe_s2_bits_meta_tagErr,
  output logic io_taskToPipe_s2_bits_meta_dataErr,
  output logic io_taskToPipe_s2_bits_metaWen,
  output logic io_taskToPipe_s2_bits_tagWen,
  output logic io_taskToPipe_s2_bits_dsWen,
  output logic [7:0] io_taskToPipe_s2_bits_wayMask,
  output logic io_taskToPipe_s2_bits_replTask,
  output logic io_taskToPipe_s2_bits_cmoTask,
  output logic io_taskToPipe_s2_bits_cmoAll,
  output logic [4:0] io_taskToPipe_s2_bits_reqSource,
  output logic io_taskToPipe_s2_bits_mergeA,
  output logic [5:0] io_taskToPipe_s2_bits_aMergeTask_off,
  output logic [1:0] io_taskToPipe_s2_bits_aMergeTask_alias,
  output logic [43:0] io_taskToPipe_s2_bits_aMergeTask_vaddr,
  output logic io_taskToPipe_s2_bits_aMergeTask_isKeyword,
  output logic [2:0] io_taskToPipe_s2_bits_aMergeTask_opcode,
  output logic [2:0] io_taskToPipe_s2_bits_aMergeTask_param,
  output logic [6:0] io_taskToPipe_s2_bits_aMergeTask_sourceId,
  output logic io_taskToPipe_s2_bits_aMergeTask_meta_dirty,
  output logic [1:0] io_taskToPipe_s2_bits_aMergeTask_meta_state,
  output logic io_taskToPipe_s2_bits_aMergeTask_meta_clients,
  output logic [1:0] io_taskToPipe_s2_bits_aMergeTask_meta_alias,
  output logic io_taskToPipe_s2_bits_aMergeTask_meta_prefetch,
  output logic [2:0] io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc,
  output logic io_taskToPipe_s2_bits_aMergeTask_meta_accessed,
  output logic io_taskToPipe_s2_bits_aMergeTask_meta_tagErr,
  output logic io_taskToPipe_s2_bits_aMergeTask_meta_dataErr,
  output logic io_taskToPipe_s2_bits_snpHitRelease,
  output logic io_taskToPipe_s2_bits_snpHitReleaseToInval,
  output logic io_taskToPipe_s2_bits_snpHitReleaseToClean,
  output logic io_taskToPipe_s2_bits_snpHitReleaseWithData,
  output logic [7:0] io_taskToPipe_s2_bits_snpHitReleaseIdx,
  output logic io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty,
  output logic [1:0] io_taskToPipe_s2_bits_snpHitReleaseMeta_state,
  output logic io_taskToPipe_s2_bits_snpHitReleaseMeta_clients,
  output logic [1:0] io_taskToPipe_s2_bits_snpHitReleaseMeta_alias,
  output logic io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch,
  output logic [2:0] io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc,
  output logic io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed,
  output logic io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr,
  output logic io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr,
  output logic [10:0] io_taskToPipe_s2_bits_tgtID,
  output logic [10:0] io_taskToPipe_s2_bits_srcID,
  output logic [11:0] io_taskToPipe_s2_bits_txnID,
  output logic [10:0] io_taskToPipe_s2_bits_homeNID,
  output logic [11:0] io_taskToPipe_s2_bits_dbID,
  output logic [10:0] io_taskToPipe_s2_bits_fwdNID,
  output logic [11:0] io_taskToPipe_s2_bits_fwdTxnID,
  output logic [6:0] io_taskToPipe_s2_bits_chiOpcode,
  output logic [2:0] io_taskToPipe_s2_bits_resp,
  output logic [2:0] io_taskToPipe_s2_bits_fwdState,
  output logic [3:0] io_taskToPipe_s2_bits_pCrdType,
  output logic io_taskToPipe_s2_bits_retToSrc,
  output logic io_taskToPipe_s2_bits_likelyshared,
  output logic io_taskToPipe_s2_bits_expCompAck,
  output logic io_taskToPipe_s2_bits_allowRetry,
  output logic io_taskToPipe_s2_bits_memAttr_allocate,
  output logic io_taskToPipe_s2_bits_memAttr_cacheable,
  output logic io_taskToPipe_s2_bits_memAttr_device,
  output logic io_taskToPipe_s2_bits_memAttr_ewa,
  output logic io_taskToPipe_s2_bits_traceTag,
  output logic io_taskInfo_s1_valid,
  output logic [2:0] io_taskInfo_s1_bits_channel,
  output logic [2:0] io_taskInfo_s1_bits_txChannel,
  output logic [8:0] io_taskInfo_s1_bits_set,
  output logic [30:0] io_taskInfo_s1_bits_tag,
  output logic [5:0] io_taskInfo_s1_bits_off,
  output logic [1:0] io_taskInfo_s1_bits_alias,
  output logic [43:0] io_taskInfo_s1_bits_vaddr,
  output logic io_taskInfo_s1_bits_isKeyword,
  output logic [3:0] io_taskInfo_s1_bits_opcode,
  output logic [2:0] io_taskInfo_s1_bits_param,
  output logic [2:0] io_taskInfo_s1_bits_size,
  output logic [6:0] io_taskInfo_s1_bits_sourceId,
  output logic [1:0] io_taskInfo_s1_bits_bufIdx,
  output logic io_taskInfo_s1_bits_needProbeAckData,
  output logic io_taskInfo_s1_bits_denied,
  output logic io_taskInfo_s1_bits_corrupt,
  output logic io_taskInfo_s1_bits_mshrTask,
  output logic [7:0] io_taskInfo_s1_bits_mshrId,
  output logic io_taskInfo_s1_bits_aliasTask,
  output logic io_taskInfo_s1_bits_useProbeData,
  output logic io_taskInfo_s1_bits_mshrRetry,
  output logic io_taskInfo_s1_bits_readProbeDataDown,
  output logic io_taskInfo_s1_bits_fromL2pft,
  output logic io_taskInfo_s1_bits_needHint,
  output logic io_taskInfo_s1_bits_dirty,
  output logic [2:0] io_taskInfo_s1_bits_way,
  output logic io_taskInfo_s1_bits_meta_dirty,
  output logic [1:0] io_taskInfo_s1_bits_meta_state,
  output logic io_taskInfo_s1_bits_meta_clients,
  output logic [1:0] io_taskInfo_s1_bits_meta_alias,
  output logic io_taskInfo_s1_bits_meta_prefetch,
  output logic [2:0] io_taskInfo_s1_bits_meta_prefetchSrc,
  output logic io_taskInfo_s1_bits_meta_accessed,
  output logic io_taskInfo_s1_bits_meta_tagErr,
  output logic io_taskInfo_s1_bits_meta_dataErr,
  output logic io_taskInfo_s1_bits_metaWen,
  output logic io_taskInfo_s1_bits_tagWen,
  output logic io_taskInfo_s1_bits_dsWen,
  output logic [7:0] io_taskInfo_s1_bits_wayMask,
  output logic io_taskInfo_s1_bits_replTask,
  output logic io_taskInfo_s1_bits_cmoTask,
  output logic io_taskInfo_s1_bits_cmoAll,
  output logic [4:0] io_taskInfo_s1_bits_reqSource,
  output logic io_taskInfo_s1_bits_mergeA,
  output logic [5:0] io_taskInfo_s1_bits_aMergeTask_off,
  output logic [1:0] io_taskInfo_s1_bits_aMergeTask_alias,
  output logic [43:0] io_taskInfo_s1_bits_aMergeTask_vaddr,
  output logic io_taskInfo_s1_bits_aMergeTask_isKeyword,
  output logic [2:0] io_taskInfo_s1_bits_aMergeTask_opcode,
  output logic [2:0] io_taskInfo_s1_bits_aMergeTask_param,
  output logic [6:0] io_taskInfo_s1_bits_aMergeTask_sourceId,
  output logic io_taskInfo_s1_bits_aMergeTask_meta_dirty,
  output logic [1:0] io_taskInfo_s1_bits_aMergeTask_meta_state,
  output logic io_taskInfo_s1_bits_aMergeTask_meta_clients,
  output logic [1:0] io_taskInfo_s1_bits_aMergeTask_meta_alias,
  output logic io_taskInfo_s1_bits_aMergeTask_meta_prefetch,
  output logic [2:0] io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc,
  output logic io_taskInfo_s1_bits_aMergeTask_meta_accessed,
  output logic io_taskInfo_s1_bits_aMergeTask_meta_tagErr,
  output logic io_taskInfo_s1_bits_aMergeTask_meta_dataErr,
  output logic io_taskInfo_s1_bits_snpHitRelease,
  output logic io_taskInfo_s1_bits_snpHitReleaseToInval,
  output logic io_taskInfo_s1_bits_snpHitReleaseToClean,
  output logic io_taskInfo_s1_bits_snpHitReleaseWithData,
  output logic [7:0] io_taskInfo_s1_bits_snpHitReleaseIdx,
  output logic io_taskInfo_s1_bits_snpHitReleaseMeta_dirty,
  output logic [1:0] io_taskInfo_s1_bits_snpHitReleaseMeta_state,
  output logic io_taskInfo_s1_bits_snpHitReleaseMeta_clients,
  output logic [1:0] io_taskInfo_s1_bits_snpHitReleaseMeta_alias,
  output logic io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch,
  output logic [2:0] io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc,
  output logic io_taskInfo_s1_bits_snpHitReleaseMeta_accessed,
  output logic io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr,
  output logic io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr,
  output logic [10:0] io_taskInfo_s1_bits_tgtID,
  output logic [10:0] io_taskInfo_s1_bits_srcID,
  output logic [11:0] io_taskInfo_s1_bits_txnID,
  output logic [10:0] io_taskInfo_s1_bits_homeNID,
  output logic [11:0] io_taskInfo_s1_bits_dbID,
  output logic [10:0] io_taskInfo_s1_bits_fwdNID,
  output logic [11:0] io_taskInfo_s1_bits_fwdTxnID,
  output logic [6:0] io_taskInfo_s1_bits_chiOpcode,
  output logic [2:0] io_taskInfo_s1_bits_resp,
  output logic [2:0] io_taskInfo_s1_bits_fwdState,
  output logic [3:0] io_taskInfo_s1_bits_pCrdType,
  output logic io_taskInfo_s1_bits_retToSrc,
  output logic io_taskInfo_s1_bits_likelyshared,
  output logic io_taskInfo_s1_bits_expCompAck,
  output logic io_taskInfo_s1_bits_allowRetry,
  output logic io_taskInfo_s1_bits_memAttr_allocate,
  output logic io_taskInfo_s1_bits_memAttr_cacheable,
  output logic io_taskInfo_s1_bits_memAttr_device,
  output logic io_taskInfo_s1_bits_memAttr_ewa,
  output logic io_taskInfo_s1_bits_traceTag,
  output logic io_refillBufRead_s2_valid,
  output logic [7:0] io_refillBufRead_s2_bits_id,
  output logic io_releaseBufRead_s2_valid,
  output logic [7:0] io_releaseBufRead_s2_bits_id,
  output logic [30:0] io_status_s1_tags_0,
  output logic [30:0] io_status_s1_tags_1,
  output logic [30:0] io_status_s1_tags_2,
  output logic [30:0] io_status_s1_tags_3,
  output logic [8:0] io_status_s1_sets_0,
  output logic [8:0] io_status_s1_sets_1,
  output logic [8:0] io_status_s1_sets_2,
  output logic [8:0] io_status_s1_sets_3,
  output logic io_status_vec_0_valid,
  output logic [2:0] io_status_vec_0_bits_channel,
  output logic io_status_vec_1_valid,
  output logic [2:0] io_status_vec_1_bits_channel,
  output logic io_status_vec_toTX_0_valid,
  output logic [2:0] io_status_vec_toTX_0_bits_channel,
  output logic [2:0] io_status_vec_toTX_0_bits_txChannel,
  output logic io_status_vec_toTX_0_bits_mshrTask,
  output logic io_status_vec_toTX_1_valid,
  output logic [2:0] io_status_vec_toTX_1_bits_channel,
  output logic [2:0] io_status_vec_toTX_1_bits_txChannel,
  output logic io_status_vec_toTX_1_bits_mshrTask,
  input  logic io_fromMSHRCtl_blockG_s1,
  input  logic io_fromMSHRCtl_blockA_s1,
  input  logic io_fromMSHRCtl_blockB_s1,
  input  logic io_fromMSHRCtl_blockC_s1,
  input  logic io_fromMainPipe_blockG_s1,
  input  logic io_fromMainPipe_blockA_s1,
  input  logic io_fromMainPipe_blockB_s1,
  input  logic io_fromMainPipe_blockC_s1,
  input  logic io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1,
  input  logic io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1,
  input  logic io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1,
  input  logic io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1,
  input  logic io_fromGrantBuffer_blockMSHRReqEntrance,
  input  logic io_fromTXDAT_blockMSHRReqEntrance,
  input  logic io_fromTXDAT_blockSinkBReqEntrance,
  input  logic io_fromTXRSP_blockMSHRReqEntrance,
  input  logic io_fromTXRSP_blockSinkBReqEntrance,
  input  logic io_fromTXREQ_blockMSHRReqEntrance,
  input  logic io_msInfo_0_valid,
  input  logic [2:0] io_msInfo_0_bits_channel,
  input  logic [8:0] io_msInfo_0_bits_set,
  input  logic [2:0] io_msInfo_0_bits_way,
  input  logic [30:0] io_msInfo_0_bits_reqTag,
  input  logic io_msInfo_0_bits_willFree,
  input  logic io_msInfo_0_bits_aliasTask,
  input  logic io_msInfo_0_bits_needRelease,
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
  input  logic io_msInfo_0_bits_isAcqOrPrefetch,
  input  logic io_msInfo_0_bits_isPrefetch,
  input  logic [2:0] io_msInfo_0_bits_param,
  input  logic io_msInfo_0_bits_mergeA,
  input  logic io_msInfo_0_bits_w_grantfirst,
  input  logic io_msInfo_0_bits_s_release,
  input  logic io_msInfo_0_bits_s_refill,
  input  logic io_msInfo_0_bits_s_cmoresp,
  input  logic io_msInfo_0_bits_s_cmometaw,
  input  logic io_msInfo_0_bits_w_releaseack,
  input  logic io_msInfo_0_bits_w_replResp,
  input  logic io_msInfo_0_bits_w_rprobeacklast,
  input  logic io_msInfo_0_bits_replaceData,
  input  logic io_msInfo_0_bits_releaseToClean,
  input  logic io_msInfo_1_valid,
  input  logic [2:0] io_msInfo_1_bits_channel,
  input  logic [8:0] io_msInfo_1_bits_set,
  input  logic [2:0] io_msInfo_1_bits_way,
  input  logic [30:0] io_msInfo_1_bits_reqTag,
  input  logic io_msInfo_1_bits_willFree,
  input  logic io_msInfo_1_bits_aliasTask,
  input  logic io_msInfo_1_bits_needRelease,
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
  input  logic io_msInfo_1_bits_isAcqOrPrefetch,
  input  logic io_msInfo_1_bits_isPrefetch,
  input  logic [2:0] io_msInfo_1_bits_param,
  input  logic io_msInfo_1_bits_mergeA,
  input  logic io_msInfo_1_bits_w_grantfirst,
  input  logic io_msInfo_1_bits_s_release,
  input  logic io_msInfo_1_bits_s_refill,
  input  logic io_msInfo_1_bits_s_cmoresp,
  input  logic io_msInfo_1_bits_s_cmometaw,
  input  logic io_msInfo_1_bits_w_releaseack,
  input  logic io_msInfo_1_bits_w_replResp,
  input  logic io_msInfo_1_bits_w_rprobeacklast,
  input  logic io_msInfo_1_bits_replaceData,
  input  logic io_msInfo_1_bits_releaseToClean,
  input  logic io_msInfo_2_valid,
  input  logic [2:0] io_msInfo_2_bits_channel,
  input  logic [8:0] io_msInfo_2_bits_set,
  input  logic [2:0] io_msInfo_2_bits_way,
  input  logic [30:0] io_msInfo_2_bits_reqTag,
  input  logic io_msInfo_2_bits_willFree,
  input  logic io_msInfo_2_bits_aliasTask,
  input  logic io_msInfo_2_bits_needRelease,
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
  input  logic io_msInfo_2_bits_isAcqOrPrefetch,
  input  logic io_msInfo_2_bits_isPrefetch,
  input  logic [2:0] io_msInfo_2_bits_param,
  input  logic io_msInfo_2_bits_mergeA,
  input  logic io_msInfo_2_bits_w_grantfirst,
  input  logic io_msInfo_2_bits_s_release,
  input  logic io_msInfo_2_bits_s_refill,
  input  logic io_msInfo_2_bits_s_cmoresp,
  input  logic io_msInfo_2_bits_s_cmometaw,
  input  logic io_msInfo_2_bits_w_releaseack,
  input  logic io_msInfo_2_bits_w_replResp,
  input  logic io_msInfo_2_bits_w_rprobeacklast,
  input  logic io_msInfo_2_bits_replaceData,
  input  logic io_msInfo_2_bits_releaseToClean,
  input  logic io_msInfo_3_valid,
  input  logic [2:0] io_msInfo_3_bits_channel,
  input  logic [8:0] io_msInfo_3_bits_set,
  input  logic [2:0] io_msInfo_3_bits_way,
  input  logic [30:0] io_msInfo_3_bits_reqTag,
  input  logic io_msInfo_3_bits_willFree,
  input  logic io_msInfo_3_bits_aliasTask,
  input  logic io_msInfo_3_bits_needRelease,
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
  input  logic io_msInfo_3_bits_isAcqOrPrefetch,
  input  logic io_msInfo_3_bits_isPrefetch,
  input  logic [2:0] io_msInfo_3_bits_param,
  input  logic io_msInfo_3_bits_mergeA,
  input  logic io_msInfo_3_bits_w_grantfirst,
  input  logic io_msInfo_3_bits_s_release,
  input  logic io_msInfo_3_bits_s_refill,
  input  logic io_msInfo_3_bits_s_cmoresp,
  input  logic io_msInfo_3_bits_s_cmometaw,
  input  logic io_msInfo_3_bits_w_releaseack,
  input  logic io_msInfo_3_bits_w_replResp,
  input  logic io_msInfo_3_bits_w_rprobeacklast,
  input  logic io_msInfo_3_bits_replaceData,
  input  logic io_msInfo_3_bits_releaseToClean,
  input  logic io_msInfo_4_valid,
  input  logic [2:0] io_msInfo_4_bits_channel,
  input  logic [8:0] io_msInfo_4_bits_set,
  input  logic [2:0] io_msInfo_4_bits_way,
  input  logic [30:0] io_msInfo_4_bits_reqTag,
  input  logic io_msInfo_4_bits_willFree,
  input  logic io_msInfo_4_bits_aliasTask,
  input  logic io_msInfo_4_bits_needRelease,
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
  input  logic io_msInfo_4_bits_isAcqOrPrefetch,
  input  logic io_msInfo_4_bits_isPrefetch,
  input  logic [2:0] io_msInfo_4_bits_param,
  input  logic io_msInfo_4_bits_mergeA,
  input  logic io_msInfo_4_bits_w_grantfirst,
  input  logic io_msInfo_4_bits_s_release,
  input  logic io_msInfo_4_bits_s_refill,
  input  logic io_msInfo_4_bits_s_cmoresp,
  input  logic io_msInfo_4_bits_s_cmometaw,
  input  logic io_msInfo_4_bits_w_releaseack,
  input  logic io_msInfo_4_bits_w_replResp,
  input  logic io_msInfo_4_bits_w_rprobeacklast,
  input  logic io_msInfo_4_bits_replaceData,
  input  logic io_msInfo_4_bits_releaseToClean,
  input  logic io_msInfo_5_valid,
  input  logic [2:0] io_msInfo_5_bits_channel,
  input  logic [8:0] io_msInfo_5_bits_set,
  input  logic [2:0] io_msInfo_5_bits_way,
  input  logic [30:0] io_msInfo_5_bits_reqTag,
  input  logic io_msInfo_5_bits_willFree,
  input  logic io_msInfo_5_bits_aliasTask,
  input  logic io_msInfo_5_bits_needRelease,
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
  input  logic io_msInfo_5_bits_isAcqOrPrefetch,
  input  logic io_msInfo_5_bits_isPrefetch,
  input  logic [2:0] io_msInfo_5_bits_param,
  input  logic io_msInfo_5_bits_mergeA,
  input  logic io_msInfo_5_bits_w_grantfirst,
  input  logic io_msInfo_5_bits_s_release,
  input  logic io_msInfo_5_bits_s_refill,
  input  logic io_msInfo_5_bits_s_cmoresp,
  input  logic io_msInfo_5_bits_s_cmometaw,
  input  logic io_msInfo_5_bits_w_releaseack,
  input  logic io_msInfo_5_bits_w_replResp,
  input  logic io_msInfo_5_bits_w_rprobeacklast,
  input  logic io_msInfo_5_bits_replaceData,
  input  logic io_msInfo_5_bits_releaseToClean,
  input  logic io_msInfo_6_valid,
  input  logic [2:0] io_msInfo_6_bits_channel,
  input  logic [8:0] io_msInfo_6_bits_set,
  input  logic [2:0] io_msInfo_6_bits_way,
  input  logic [30:0] io_msInfo_6_bits_reqTag,
  input  logic io_msInfo_6_bits_willFree,
  input  logic io_msInfo_6_bits_aliasTask,
  input  logic io_msInfo_6_bits_needRelease,
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
  input  logic io_msInfo_6_bits_isAcqOrPrefetch,
  input  logic io_msInfo_6_bits_isPrefetch,
  input  logic [2:0] io_msInfo_6_bits_param,
  input  logic io_msInfo_6_bits_mergeA,
  input  logic io_msInfo_6_bits_w_grantfirst,
  input  logic io_msInfo_6_bits_s_release,
  input  logic io_msInfo_6_bits_s_refill,
  input  logic io_msInfo_6_bits_s_cmoresp,
  input  logic io_msInfo_6_bits_s_cmometaw,
  input  logic io_msInfo_6_bits_w_releaseack,
  input  logic io_msInfo_6_bits_w_replResp,
  input  logic io_msInfo_6_bits_w_rprobeacklast,
  input  logic io_msInfo_6_bits_replaceData,
  input  logic io_msInfo_6_bits_releaseToClean,
  input  logic io_msInfo_7_valid,
  input  logic [2:0] io_msInfo_7_bits_channel,
  input  logic [8:0] io_msInfo_7_bits_set,
  input  logic [2:0] io_msInfo_7_bits_way,
  input  logic [30:0] io_msInfo_7_bits_reqTag,
  input  logic io_msInfo_7_bits_willFree,
  input  logic io_msInfo_7_bits_aliasTask,
  input  logic io_msInfo_7_bits_needRelease,
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
  input  logic io_msInfo_7_bits_isAcqOrPrefetch,
  input  logic io_msInfo_7_bits_isPrefetch,
  input  logic [2:0] io_msInfo_7_bits_param,
  input  logic io_msInfo_7_bits_mergeA,
  input  logic io_msInfo_7_bits_w_grantfirst,
  input  logic io_msInfo_7_bits_s_release,
  input  logic io_msInfo_7_bits_s_refill,
  input  logic io_msInfo_7_bits_s_cmoresp,
  input  logic io_msInfo_7_bits_s_cmometaw,
  input  logic io_msInfo_7_bits_w_releaseack,
  input  logic io_msInfo_7_bits_w_replResp,
  input  logic io_msInfo_7_bits_w_rprobeacklast,
  input  logic io_msInfo_7_bits_replaceData,
  input  logic io_msInfo_7_bits_releaseToClean,
  input  logic io_msInfo_8_valid,
  input  logic [2:0] io_msInfo_8_bits_channel,
  input  logic [8:0] io_msInfo_8_bits_set,
  input  logic [2:0] io_msInfo_8_bits_way,
  input  logic [30:0] io_msInfo_8_bits_reqTag,
  input  logic io_msInfo_8_bits_willFree,
  input  logic io_msInfo_8_bits_aliasTask,
  input  logic io_msInfo_8_bits_needRelease,
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
  input  logic io_msInfo_8_bits_isAcqOrPrefetch,
  input  logic io_msInfo_8_bits_isPrefetch,
  input  logic [2:0] io_msInfo_8_bits_param,
  input  logic io_msInfo_8_bits_mergeA,
  input  logic io_msInfo_8_bits_w_grantfirst,
  input  logic io_msInfo_8_bits_s_release,
  input  logic io_msInfo_8_bits_s_refill,
  input  logic io_msInfo_8_bits_s_cmoresp,
  input  logic io_msInfo_8_bits_s_cmometaw,
  input  logic io_msInfo_8_bits_w_releaseack,
  input  logic io_msInfo_8_bits_w_replResp,
  input  logic io_msInfo_8_bits_w_rprobeacklast,
  input  logic io_msInfo_8_bits_replaceData,
  input  logic io_msInfo_8_bits_releaseToClean,
  input  logic io_msInfo_9_valid,
  input  logic [2:0] io_msInfo_9_bits_channel,
  input  logic [8:0] io_msInfo_9_bits_set,
  input  logic [2:0] io_msInfo_9_bits_way,
  input  logic [30:0] io_msInfo_9_bits_reqTag,
  input  logic io_msInfo_9_bits_willFree,
  input  logic io_msInfo_9_bits_aliasTask,
  input  logic io_msInfo_9_bits_needRelease,
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
  input  logic io_msInfo_9_bits_isAcqOrPrefetch,
  input  logic io_msInfo_9_bits_isPrefetch,
  input  logic [2:0] io_msInfo_9_bits_param,
  input  logic io_msInfo_9_bits_mergeA,
  input  logic io_msInfo_9_bits_w_grantfirst,
  input  logic io_msInfo_9_bits_s_release,
  input  logic io_msInfo_9_bits_s_refill,
  input  logic io_msInfo_9_bits_s_cmoresp,
  input  logic io_msInfo_9_bits_s_cmometaw,
  input  logic io_msInfo_9_bits_w_releaseack,
  input  logic io_msInfo_9_bits_w_replResp,
  input  logic io_msInfo_9_bits_w_rprobeacklast,
  input  logic io_msInfo_9_bits_replaceData,
  input  logic io_msInfo_9_bits_releaseToClean,
  input  logic io_msInfo_10_valid,
  input  logic [2:0] io_msInfo_10_bits_channel,
  input  logic [8:0] io_msInfo_10_bits_set,
  input  logic [2:0] io_msInfo_10_bits_way,
  input  logic [30:0] io_msInfo_10_bits_reqTag,
  input  logic io_msInfo_10_bits_willFree,
  input  logic io_msInfo_10_bits_aliasTask,
  input  logic io_msInfo_10_bits_needRelease,
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
  input  logic io_msInfo_10_bits_isAcqOrPrefetch,
  input  logic io_msInfo_10_bits_isPrefetch,
  input  logic [2:0] io_msInfo_10_bits_param,
  input  logic io_msInfo_10_bits_mergeA,
  input  logic io_msInfo_10_bits_w_grantfirst,
  input  logic io_msInfo_10_bits_s_release,
  input  logic io_msInfo_10_bits_s_refill,
  input  logic io_msInfo_10_bits_s_cmoresp,
  input  logic io_msInfo_10_bits_s_cmometaw,
  input  logic io_msInfo_10_bits_w_releaseack,
  input  logic io_msInfo_10_bits_w_replResp,
  input  logic io_msInfo_10_bits_w_rprobeacklast,
  input  logic io_msInfo_10_bits_replaceData,
  input  logic io_msInfo_10_bits_releaseToClean,
  input  logic io_msInfo_11_valid,
  input  logic [2:0] io_msInfo_11_bits_channel,
  input  logic [8:0] io_msInfo_11_bits_set,
  input  logic [2:0] io_msInfo_11_bits_way,
  input  logic [30:0] io_msInfo_11_bits_reqTag,
  input  logic io_msInfo_11_bits_willFree,
  input  logic io_msInfo_11_bits_aliasTask,
  input  logic io_msInfo_11_bits_needRelease,
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
  input  logic io_msInfo_11_bits_isAcqOrPrefetch,
  input  logic io_msInfo_11_bits_isPrefetch,
  input  logic [2:0] io_msInfo_11_bits_param,
  input  logic io_msInfo_11_bits_mergeA,
  input  logic io_msInfo_11_bits_w_grantfirst,
  input  logic io_msInfo_11_bits_s_release,
  input  logic io_msInfo_11_bits_s_refill,
  input  logic io_msInfo_11_bits_s_cmoresp,
  input  logic io_msInfo_11_bits_s_cmometaw,
  input  logic io_msInfo_11_bits_w_releaseack,
  input  logic io_msInfo_11_bits_w_replResp,
  input  logic io_msInfo_11_bits_w_rprobeacklast,
  input  logic io_msInfo_11_bits_replaceData,
  input  logic io_msInfo_11_bits_releaseToClean,
  input  logic io_msInfo_12_valid,
  input  logic [2:0] io_msInfo_12_bits_channel,
  input  logic [8:0] io_msInfo_12_bits_set,
  input  logic [2:0] io_msInfo_12_bits_way,
  input  logic [30:0] io_msInfo_12_bits_reqTag,
  input  logic io_msInfo_12_bits_willFree,
  input  logic io_msInfo_12_bits_aliasTask,
  input  logic io_msInfo_12_bits_needRelease,
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
  input  logic io_msInfo_12_bits_isAcqOrPrefetch,
  input  logic io_msInfo_12_bits_isPrefetch,
  input  logic [2:0] io_msInfo_12_bits_param,
  input  logic io_msInfo_12_bits_mergeA,
  input  logic io_msInfo_12_bits_w_grantfirst,
  input  logic io_msInfo_12_bits_s_release,
  input  logic io_msInfo_12_bits_s_refill,
  input  logic io_msInfo_12_bits_s_cmoresp,
  input  logic io_msInfo_12_bits_s_cmometaw,
  input  logic io_msInfo_12_bits_w_releaseack,
  input  logic io_msInfo_12_bits_w_replResp,
  input  logic io_msInfo_12_bits_w_rprobeacklast,
  input  logic io_msInfo_12_bits_replaceData,
  input  logic io_msInfo_12_bits_releaseToClean,
  input  logic io_msInfo_13_valid,
  input  logic [2:0] io_msInfo_13_bits_channel,
  input  logic [8:0] io_msInfo_13_bits_set,
  input  logic [2:0] io_msInfo_13_bits_way,
  input  logic [30:0] io_msInfo_13_bits_reqTag,
  input  logic io_msInfo_13_bits_willFree,
  input  logic io_msInfo_13_bits_aliasTask,
  input  logic io_msInfo_13_bits_needRelease,
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
  input  logic io_msInfo_13_bits_isAcqOrPrefetch,
  input  logic io_msInfo_13_bits_isPrefetch,
  input  logic [2:0] io_msInfo_13_bits_param,
  input  logic io_msInfo_13_bits_mergeA,
  input  logic io_msInfo_13_bits_w_grantfirst,
  input  logic io_msInfo_13_bits_s_release,
  input  logic io_msInfo_13_bits_s_refill,
  input  logic io_msInfo_13_bits_s_cmoresp,
  input  logic io_msInfo_13_bits_s_cmometaw,
  input  logic io_msInfo_13_bits_w_releaseack,
  input  logic io_msInfo_13_bits_w_replResp,
  input  logic io_msInfo_13_bits_w_rprobeacklast,
  input  logic io_msInfo_13_bits_replaceData,
  input  logic io_msInfo_13_bits_releaseToClean,
  input  logic io_msInfo_14_valid,
  input  logic [2:0] io_msInfo_14_bits_channel,
  input  logic [8:0] io_msInfo_14_bits_set,
  input  logic [2:0] io_msInfo_14_bits_way,
  input  logic [30:0] io_msInfo_14_bits_reqTag,
  input  logic io_msInfo_14_bits_willFree,
  input  logic io_msInfo_14_bits_aliasTask,
  input  logic io_msInfo_14_bits_needRelease,
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
  input  logic io_msInfo_14_bits_isAcqOrPrefetch,
  input  logic io_msInfo_14_bits_isPrefetch,
  input  logic [2:0] io_msInfo_14_bits_param,
  input  logic io_msInfo_14_bits_mergeA,
  input  logic io_msInfo_14_bits_w_grantfirst,
  input  logic io_msInfo_14_bits_s_release,
  input  logic io_msInfo_14_bits_s_refill,
  input  logic io_msInfo_14_bits_s_cmoresp,
  input  logic io_msInfo_14_bits_s_cmometaw,
  input  logic io_msInfo_14_bits_w_releaseack,
  input  logic io_msInfo_14_bits_w_replResp,
  input  logic io_msInfo_14_bits_w_rprobeacklast,
  input  logic io_msInfo_14_bits_replaceData,
  input  logic io_msInfo_14_bits_releaseToClean,
  input  logic io_msInfo_15_valid,
  input  logic [2:0] io_msInfo_15_bits_channel,
  input  logic [8:0] io_msInfo_15_bits_set,
  input  logic [2:0] io_msInfo_15_bits_way,
  input  logic [30:0] io_msInfo_15_bits_reqTag,
  input  logic io_msInfo_15_bits_willFree,
  input  logic io_msInfo_15_bits_aliasTask,
  input  logic io_msInfo_15_bits_needRelease,
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
  input  logic io_msInfo_15_bits_isAcqOrPrefetch,
  input  logic io_msInfo_15_bits_isPrefetch,
  input  logic [2:0] io_msInfo_15_bits_param,
  input  logic io_msInfo_15_bits_mergeA,
  input  logic io_msInfo_15_bits_w_grantfirst,
  input  logic io_msInfo_15_bits_s_release,
  input  logic io_msInfo_15_bits_s_refill,
  input  logic io_msInfo_15_bits_s_cmoresp,
  input  logic io_msInfo_15_bits_s_cmometaw,
  input  logic io_msInfo_15_bits_w_releaseack,
  input  logic io_msInfo_15_bits_w_replResp,
  input  logic io_msInfo_15_bits_w_rprobeacklast,
  input  logic io_msInfo_15_bits_replaceData,
  input  logic io_msInfo_15_bits_releaseToClean
);

  task_t sinkA_task, sinkB_task, sinkC_task, mshrTask_task, task_s1, task_s2_bits;
  logic  task_s1_valid, s1_fire, task_s2_valid;
  logic [30:0] mshrTaskS1_tag;
  logic [8:0]  mshrTaskS1_set;

  // 四路输入按字段装成 task_t
  assign sinkA_task = '{
    io_sinkA_bits_channel,
    io_sinkA_bits_txChannel,
    io_sinkA_bits_set,
    io_sinkA_bits_tag,
    io_sinkA_bits_off,
    io_sinkA_bits_alias,
    io_sinkA_bits_vaddr,
    io_sinkA_bits_isKeyword,
    io_sinkA_bits_opcode,
    io_sinkA_bits_param,
    io_sinkA_bits_size,
    io_sinkA_bits_sourceId,
    io_sinkA_bits_bufIdx,
    io_sinkA_bits_needProbeAckData,
    io_sinkA_bits_denied,
    io_sinkA_bits_corrupt,
    io_sinkA_bits_mshrTask,
    io_sinkA_bits_mshrId,
    io_sinkA_bits_aliasTask,
    io_sinkA_bits_useProbeData,
    io_sinkA_bits_mshrRetry,
    io_sinkA_bits_readProbeDataDown,
    io_sinkA_bits_fromL2pft,
    io_sinkA_bits_needHint,
    io_sinkA_bits_dirty,
    io_sinkA_bits_way,
    io_sinkA_bits_meta_dirty,
    io_sinkA_bits_meta_state,
    io_sinkA_bits_meta_clients,
    io_sinkA_bits_meta_alias,
    io_sinkA_bits_meta_prefetch,
    io_sinkA_bits_meta_prefetchSrc,
    io_sinkA_bits_meta_accessed,
    io_sinkA_bits_meta_tagErr,
    io_sinkA_bits_meta_dataErr,
    io_sinkA_bits_metaWen,
    io_sinkA_bits_tagWen,
    io_sinkA_bits_dsWen,
    io_sinkA_bits_wayMask,
    io_sinkA_bits_replTask,
    io_sinkA_bits_cmoTask,
    io_sinkA_bits_cmoAll,
    io_sinkA_bits_reqSource,
    io_sinkA_bits_mergeA,
    io_sinkA_bits_aMergeTask_off,
    io_sinkA_bits_aMergeTask_alias,
    io_sinkA_bits_aMergeTask_vaddr,
    io_sinkA_bits_aMergeTask_isKeyword,
    io_sinkA_bits_aMergeTask_opcode,
    io_sinkA_bits_aMergeTask_param,
    io_sinkA_bits_aMergeTask_sourceId,
    io_sinkA_bits_aMergeTask_meta_dirty,
    io_sinkA_bits_aMergeTask_meta_state,
    io_sinkA_bits_aMergeTask_meta_clients,
    io_sinkA_bits_aMergeTask_meta_alias,
    io_sinkA_bits_aMergeTask_meta_prefetch,
    io_sinkA_bits_aMergeTask_meta_prefetchSrc,
    io_sinkA_bits_aMergeTask_meta_accessed,
    io_sinkA_bits_aMergeTask_meta_tagErr,
    io_sinkA_bits_aMergeTask_meta_dataErr,
    io_sinkA_bits_snpHitRelease,
    io_sinkA_bits_snpHitReleaseToInval,
    io_sinkA_bits_snpHitReleaseToClean,
    io_sinkA_bits_snpHitReleaseWithData,
    io_sinkA_bits_snpHitReleaseIdx,
    io_sinkA_bits_snpHitReleaseMeta_dirty,
    io_sinkA_bits_snpHitReleaseMeta_state,
    io_sinkA_bits_snpHitReleaseMeta_clients,
    io_sinkA_bits_snpHitReleaseMeta_alias,
    io_sinkA_bits_snpHitReleaseMeta_prefetch,
    io_sinkA_bits_snpHitReleaseMeta_prefetchSrc,
    io_sinkA_bits_snpHitReleaseMeta_accessed,
    io_sinkA_bits_snpHitReleaseMeta_tagErr,
    io_sinkA_bits_snpHitReleaseMeta_dataErr,
    io_sinkA_bits_tgtID,
    io_sinkA_bits_srcID,
    io_sinkA_bits_txnID,
    io_sinkA_bits_homeNID,
    io_sinkA_bits_dbID,
    io_sinkA_bits_fwdNID,
    io_sinkA_bits_fwdTxnID,
    io_sinkA_bits_chiOpcode,
    io_sinkA_bits_resp,
    io_sinkA_bits_fwdState,
    io_sinkA_bits_pCrdType,
    io_sinkA_bits_retToSrc,
    io_sinkA_bits_likelyshared,
    io_sinkA_bits_expCompAck,
    io_sinkA_bits_allowRetry,
    io_sinkA_bits_memAttr_allocate,
    io_sinkA_bits_memAttr_cacheable,
    io_sinkA_bits_memAttr_device,
    io_sinkA_bits_memAttr_ewa,
    io_sinkA_bits_traceTag
  };
  assign sinkB_task = '{
    io_sinkB_bits_channel,
    io_sinkB_bits_txChannel,
    io_sinkB_bits_set,
    io_sinkB_bits_tag,
    io_sinkB_bits_off,
    io_sinkB_bits_alias,
    io_sinkB_bits_vaddr,
    io_sinkB_bits_isKeyword,
    io_sinkB_bits_opcode,
    io_sinkB_bits_param,
    io_sinkB_bits_size,
    io_sinkB_bits_sourceId,
    io_sinkB_bits_bufIdx,
    io_sinkB_bits_needProbeAckData,
    io_sinkB_bits_denied,
    io_sinkB_bits_corrupt,
    io_sinkB_bits_mshrTask,
    io_sinkB_bits_mshrId,
    io_sinkB_bits_aliasTask,
    io_sinkB_bits_useProbeData,
    io_sinkB_bits_mshrRetry,
    io_sinkB_bits_readProbeDataDown,
    io_sinkB_bits_fromL2pft,
    io_sinkB_bits_needHint,
    io_sinkB_bits_dirty,
    io_sinkB_bits_way,
    io_sinkB_bits_meta_dirty,
    io_sinkB_bits_meta_state,
    io_sinkB_bits_meta_clients,
    io_sinkB_bits_meta_alias,
    io_sinkB_bits_meta_prefetch,
    io_sinkB_bits_meta_prefetchSrc,
    io_sinkB_bits_meta_accessed,
    io_sinkB_bits_meta_tagErr,
    io_sinkB_bits_meta_dataErr,
    io_sinkB_bits_metaWen,
    io_sinkB_bits_tagWen,
    io_sinkB_bits_dsWen,
    io_sinkB_bits_wayMask,
    io_sinkB_bits_replTask,
    io_sinkB_bits_cmoTask,
    io_sinkB_bits_cmoAll,
    io_sinkB_bits_reqSource,
    io_sinkB_bits_mergeA,
    io_sinkB_bits_aMergeTask_off,
    io_sinkB_bits_aMergeTask_alias,
    io_sinkB_bits_aMergeTask_vaddr,
    io_sinkB_bits_aMergeTask_isKeyword,
    io_sinkB_bits_aMergeTask_opcode,
    io_sinkB_bits_aMergeTask_param,
    io_sinkB_bits_aMergeTask_sourceId,
    io_sinkB_bits_aMergeTask_meta_dirty,
    io_sinkB_bits_aMergeTask_meta_state,
    io_sinkB_bits_aMergeTask_meta_clients,
    io_sinkB_bits_aMergeTask_meta_alias,
    io_sinkB_bits_aMergeTask_meta_prefetch,
    io_sinkB_bits_aMergeTask_meta_prefetchSrc,
    io_sinkB_bits_aMergeTask_meta_accessed,
    io_sinkB_bits_aMergeTask_meta_tagErr,
    io_sinkB_bits_aMergeTask_meta_dataErr,
    io_sinkB_bits_snpHitRelease,
    io_sinkB_bits_snpHitReleaseToInval,
    io_sinkB_bits_snpHitReleaseToClean,
    io_sinkB_bits_snpHitReleaseWithData,
    io_sinkB_bits_snpHitReleaseIdx,
    io_sinkB_bits_snpHitReleaseMeta_dirty,
    io_sinkB_bits_snpHitReleaseMeta_state,
    io_sinkB_bits_snpHitReleaseMeta_clients,
    io_sinkB_bits_snpHitReleaseMeta_alias,
    io_sinkB_bits_snpHitReleaseMeta_prefetch,
    io_sinkB_bits_snpHitReleaseMeta_prefetchSrc,
    io_sinkB_bits_snpHitReleaseMeta_accessed,
    io_sinkB_bits_snpHitReleaseMeta_tagErr,
    io_sinkB_bits_snpHitReleaseMeta_dataErr,
    io_sinkB_bits_tgtID,
    io_sinkB_bits_srcID,
    io_sinkB_bits_txnID,
    io_sinkB_bits_homeNID,
    io_sinkB_bits_dbID,
    io_sinkB_bits_fwdNID,
    io_sinkB_bits_fwdTxnID,
    io_sinkB_bits_chiOpcode,
    io_sinkB_bits_resp,
    io_sinkB_bits_fwdState,
    io_sinkB_bits_pCrdType,
    io_sinkB_bits_retToSrc,
    io_sinkB_bits_likelyshared,
    io_sinkB_bits_expCompAck,
    io_sinkB_bits_allowRetry,
    io_sinkB_bits_memAttr_allocate,
    io_sinkB_bits_memAttr_cacheable,
    io_sinkB_bits_memAttr_device,
    io_sinkB_bits_memAttr_ewa,
    io_sinkB_bits_traceTag
  };
  assign sinkC_task = '{
    io_sinkC_bits_channel,
    io_sinkC_bits_txChannel,
    io_sinkC_bits_set,
    io_sinkC_bits_tag,
    io_sinkC_bits_off,
    io_sinkC_bits_alias,
    io_sinkC_bits_vaddr,
    io_sinkC_bits_isKeyword,
    io_sinkC_bits_opcode,
    io_sinkC_bits_param,
    io_sinkC_bits_size,
    io_sinkC_bits_sourceId,
    io_sinkC_bits_bufIdx,
    io_sinkC_bits_needProbeAckData,
    io_sinkC_bits_denied,
    io_sinkC_bits_corrupt,
    io_sinkC_bits_mshrTask,
    io_sinkC_bits_mshrId,
    io_sinkC_bits_aliasTask,
    io_sinkC_bits_useProbeData,
    io_sinkC_bits_mshrRetry,
    io_sinkC_bits_readProbeDataDown,
    io_sinkC_bits_fromL2pft,
    io_sinkC_bits_needHint,
    io_sinkC_bits_dirty,
    io_sinkC_bits_way,
    io_sinkC_bits_meta_dirty,
    io_sinkC_bits_meta_state,
    io_sinkC_bits_meta_clients,
    io_sinkC_bits_meta_alias,
    io_sinkC_bits_meta_prefetch,
    io_sinkC_bits_meta_prefetchSrc,
    io_sinkC_bits_meta_accessed,
    io_sinkC_bits_meta_tagErr,
    io_sinkC_bits_meta_dataErr,
    io_sinkC_bits_metaWen,
    io_sinkC_bits_tagWen,
    io_sinkC_bits_dsWen,
    io_sinkC_bits_wayMask,
    io_sinkC_bits_replTask,
    io_sinkC_bits_cmoTask,
    io_sinkC_bits_cmoAll,
    io_sinkC_bits_reqSource,
    io_sinkC_bits_mergeA,
    io_sinkC_bits_aMergeTask_off,
    io_sinkC_bits_aMergeTask_alias,
    io_sinkC_bits_aMergeTask_vaddr,
    io_sinkC_bits_aMergeTask_isKeyword,
    io_sinkC_bits_aMergeTask_opcode,
    io_sinkC_bits_aMergeTask_param,
    io_sinkC_bits_aMergeTask_sourceId,
    io_sinkC_bits_aMergeTask_meta_dirty,
    io_sinkC_bits_aMergeTask_meta_state,
    io_sinkC_bits_aMergeTask_meta_clients,
    io_sinkC_bits_aMergeTask_meta_alias,
    io_sinkC_bits_aMergeTask_meta_prefetch,
    io_sinkC_bits_aMergeTask_meta_prefetchSrc,
    io_sinkC_bits_aMergeTask_meta_accessed,
    io_sinkC_bits_aMergeTask_meta_tagErr,
    io_sinkC_bits_aMergeTask_meta_dataErr,
    io_sinkC_bits_snpHitRelease,
    io_sinkC_bits_snpHitReleaseToInval,
    io_sinkC_bits_snpHitReleaseToClean,
    io_sinkC_bits_snpHitReleaseWithData,
    io_sinkC_bits_snpHitReleaseIdx,
    io_sinkC_bits_snpHitReleaseMeta_dirty,
    io_sinkC_bits_snpHitReleaseMeta_state,
    io_sinkC_bits_snpHitReleaseMeta_clients,
    io_sinkC_bits_snpHitReleaseMeta_alias,
    io_sinkC_bits_snpHitReleaseMeta_prefetch,
    io_sinkC_bits_snpHitReleaseMeta_prefetchSrc,
    io_sinkC_bits_snpHitReleaseMeta_accessed,
    io_sinkC_bits_snpHitReleaseMeta_tagErr,
    io_sinkC_bits_snpHitReleaseMeta_dataErr,
    io_sinkC_bits_tgtID,
    io_sinkC_bits_srcID,
    io_sinkC_bits_txnID,
    io_sinkC_bits_homeNID,
    io_sinkC_bits_dbID,
    io_sinkC_bits_fwdNID,
    io_sinkC_bits_fwdTxnID,
    io_sinkC_bits_chiOpcode,
    io_sinkC_bits_resp,
    io_sinkC_bits_fwdState,
    io_sinkC_bits_pCrdType,
    io_sinkC_bits_retToSrc,
    io_sinkC_bits_likelyshared,
    io_sinkC_bits_expCompAck,
    io_sinkC_bits_allowRetry,
    io_sinkC_bits_memAttr_allocate,
    io_sinkC_bits_memAttr_cacheable,
    io_sinkC_bits_memAttr_device,
    io_sinkC_bits_memAttr_ewa,
    io_sinkC_bits_traceTag
  };
  assign mshrTask_task = '{
    io_mshrTask_bits_channel,
    io_mshrTask_bits_txChannel,
    io_mshrTask_bits_set,
    io_mshrTask_bits_tag,
    io_mshrTask_bits_off,
    io_mshrTask_bits_alias,
    io_mshrTask_bits_vaddr,
    io_mshrTask_bits_isKeyword,
    io_mshrTask_bits_opcode,
    io_mshrTask_bits_param,
    io_mshrTask_bits_size,
    io_mshrTask_bits_sourceId,
    io_mshrTask_bits_bufIdx,
    io_mshrTask_bits_needProbeAckData,
    io_mshrTask_bits_denied,
    io_mshrTask_bits_corrupt,
    io_mshrTask_bits_mshrTask,
    io_mshrTask_bits_mshrId,
    io_mshrTask_bits_aliasTask,
    io_mshrTask_bits_useProbeData,
    io_mshrTask_bits_mshrRetry,
    io_mshrTask_bits_readProbeDataDown,
    io_mshrTask_bits_fromL2pft,
    io_mshrTask_bits_needHint,
    io_mshrTask_bits_dirty,
    io_mshrTask_bits_way,
    io_mshrTask_bits_meta_dirty,
    io_mshrTask_bits_meta_state,
    io_mshrTask_bits_meta_clients,
    io_mshrTask_bits_meta_alias,
    io_mshrTask_bits_meta_prefetch,
    io_mshrTask_bits_meta_prefetchSrc,
    io_mshrTask_bits_meta_accessed,
    io_mshrTask_bits_meta_tagErr,
    io_mshrTask_bits_meta_dataErr,
    io_mshrTask_bits_metaWen,
    io_mshrTask_bits_tagWen,
    io_mshrTask_bits_dsWen,
    io_mshrTask_bits_wayMask,
    io_mshrTask_bits_replTask,
    io_mshrTask_bits_cmoTask,
    io_mshrTask_bits_cmoAll,
    io_mshrTask_bits_reqSource,
    io_mshrTask_bits_mergeA,
    io_mshrTask_bits_aMergeTask_off,
    io_mshrTask_bits_aMergeTask_alias,
    io_mshrTask_bits_aMergeTask_vaddr,
    io_mshrTask_bits_aMergeTask_isKeyword,
    io_mshrTask_bits_aMergeTask_opcode,
    io_mshrTask_bits_aMergeTask_param,
    io_mshrTask_bits_aMergeTask_sourceId,
    io_mshrTask_bits_aMergeTask_meta_dirty,
    io_mshrTask_bits_aMergeTask_meta_state,
    io_mshrTask_bits_aMergeTask_meta_clients,
    io_mshrTask_bits_aMergeTask_meta_alias,
    io_mshrTask_bits_aMergeTask_meta_prefetch,
    io_mshrTask_bits_aMergeTask_meta_prefetchSrc,
    io_mshrTask_bits_aMergeTask_meta_accessed,
    io_mshrTask_bits_aMergeTask_meta_tagErr,
    io_mshrTask_bits_aMergeTask_meta_dataErr,
    io_mshrTask_bits_snpHitRelease,
    io_mshrTask_bits_snpHitReleaseToInval,
    io_mshrTask_bits_snpHitReleaseToClean,
    io_mshrTask_bits_snpHitReleaseWithData,
    io_mshrTask_bits_snpHitReleaseIdx,
    io_mshrTask_bits_snpHitReleaseMeta_dirty,
    io_mshrTask_bits_snpHitReleaseMeta_state,
    io_mshrTask_bits_snpHitReleaseMeta_clients,
    io_mshrTask_bits_snpHitReleaseMeta_alias,
    io_mshrTask_bits_snpHitReleaseMeta_prefetch,
    io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc,
    io_mshrTask_bits_snpHitReleaseMeta_accessed,
    io_mshrTask_bits_snpHitReleaseMeta_tagErr,
    io_mshrTask_bits_snpHitReleaseMeta_dataErr,
    io_mshrTask_bits_tgtID,
    io_mshrTask_bits_srcID,
    io_mshrTask_bits_txnID,
    io_mshrTask_bits_homeNID,
    io_mshrTask_bits_dbID,
    io_mshrTask_bits_fwdNID,
    io_mshrTask_bits_fwdTxnID,
    io_mshrTask_bits_chiOpcode,
    io_mshrTask_bits_resp,
    io_mshrTask_bits_fwdState,
    io_mshrTask_bits_pCrdType,
    io_mshrTask_bits_retToSrc,
    io_mshrTask_bits_likelyshared,
    io_mshrTask_bits_expCompAck,
    io_mshrTask_bits_allowRetry,
    io_mshrTask_bits_memAttr_allocate,
    io_mshrTask_bits_memAttr_cacheable,
    io_mshrTask_bits_memAttr_device,
    io_mshrTask_bits_memAttr_ewa,
    io_mshrTask_bits_traceTag
  };

  xs_RequestArb_core u_core (
    .clock                    (clock),
    .reset                    (reset),
    .sinkA_valid              (io_sinkA_valid),
    .sinkA_ready              (io_sinkA_ready),
    .sinkA_task               (sinkA_task),
    .sinkB_valid              (io_sinkB_valid),
    .sinkB_ready              (io_sinkB_ready),
    .sinkB_task               (sinkB_task),
    .sinkC_valid              (io_sinkC_valid),
    .sinkC_ready              (io_sinkC_ready),
    .sinkC_task               (sinkC_task),
    .mshrTask_valid           (io_mshrTask_valid),
    .mshrTask_ready           (io_mshrTask_ready),
    .mshrTask_task            (mshrTask_task),
    .blockA_mshrCtl           (io_fromMSHRCtl_blockA_s1),
    .blockB_mshrCtl           (io_fromMSHRCtl_blockB_s1),
    .blockC_mshrCtl           (io_fromMSHRCtl_blockC_s1),
    .blockA_mainPipe          (io_fromMainPipe_blockA_s1),
    .blockB_mainPipe          (io_fromMainPipe_blockB_s1),
    .blockC_mainPipe          (io_fromMainPipe_blockC_s1),
    .blockG_mainPipe          (io_fromMainPipe_blockG_s1),
    .blockA_grantBuf          (io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1),
    .blockB_grantBuf          (io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1),
    .blockC_grantBuf          (io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1),
    .blockMSHR_grantBuf       (io_fromGrantBuffer_blockMSHRReqEntrance),
    .blockSinkB_txdat         (io_fromTXDAT_blockSinkBReqEntrance),
    .blockMSHR_txdat          (io_fromTXDAT_blockMSHRReqEntrance),
    .blockSinkB_txrsp         (io_fromTXRSP_blockSinkBReqEntrance),
    .blockMSHR_txrsp          (io_fromTXRSP_blockMSHRReqEntrance),
    .blockMSHR_txreq          (io_fromTXREQ_blockMSHRReqEntrance),
    .dirRead_ready            (io_dirRead_s1_ready),
    .dirRead_valid            (io_dirRead_s1_valid),
    .dirRead_wayMask          (io_dirRead_s1_bits_wayMask),
    .dirRead_refill_prefetch  (io_dirRead_s1_bits_replacerInfo_refill_prefetch),
    .dirRead_refill           (io_dirRead_s1_bits_refill),
    .task_s1_valid            (task_s1_valid),
    .task_s1                  (task_s1),
    .s1_fire                  (s1_fire),
    .task_s2_valid            (task_s2_valid),
    .task_s2_bits             (task_s2_bits),
    .s1Entrance_valid         (io_s1Entrance_valid),
    .s1Entrance_set           (io_s1Entrance_bits_set),
    .mshrTaskS1_tag           (mshrTaskS1_tag),
    .mshrTaskS1_set           (mshrTaskS1_set),
    .refillBufRead_valid      (io_refillBufRead_s2_valid),
    .refillBufRead_id         (io_refillBufRead_s2_bits_id),
    .releaseBufRead_valid     (io_releaseBufRead_s2_valid),
    .releaseBufRead_id        (io_releaseBufRead_s2_bits_id)
  );

  // s1：目录读请求的其余字段直接取自 s1 任务
  assign io_dirRead_s1_bits_tag                   = task_s1.tag;
  assign io_dirRead_s1_bits_set                   = task_s1.set;
  assign io_dirRead_s1_bits_replacerInfo_channel   = task_s1.channel;
  assign io_dirRead_s1_bits_replacerInfo_opcode    = task_s1.opcode[2:0];
  assign io_dirRead_s1_bits_replacerInfo_reqSource = task_s1.reqSource;
  assign io_dirRead_s1_bits_mshrId                = task_s1.mshrId;
  assign io_dirRead_s1_bits_cmoAll                = task_s1.cmoAll;
  assign io_dirRead_s1_bits_cmoWay                = task_s1.way;

  // 各级状态（给 MSHRCtl / MainPipe / TX 通道做冲突与反压判断）
  assign io_status_s1_tags_0 = io_sinkC_bits_tag;
  assign io_status_s1_tags_1 = io_sinkB_bits_tag;
  assign io_status_s1_tags_2 = io_ATag;
  assign io_status_s1_tags_3 = mshrTaskS1_tag;
  assign io_status_s1_sets_0 = io_sinkC_bits_set;
  assign io_status_s1_sets_1 = io_sinkB_bits_set;
  assign io_status_s1_sets_2 = io_ASet;
  assign io_status_s1_sets_3 = mshrTaskS1_set;
  assign io_status_vec_0_valid              = task_s1_valid;
  assign io_status_vec_0_bits_channel       = task_s1.channel;
  assign io_status_vec_1_valid              = task_s2_valid;
  assign io_status_vec_1_bits_channel       = task_s2_bits.channel;
  assign io_status_vec_toTX_0_valid         = task_s1_valid;
  assign io_status_vec_toTX_0_bits_channel  = task_s1.channel;
  assign io_status_vec_toTX_0_bits_txChannel = task_s1.txChannel;
  assign io_status_vec_toTX_0_bits_mshrTask = task_s1.mshrTask;
  assign io_status_vec_toTX_1_valid         = task_s2_valid;
  assign io_status_vec_toTX_1_bits_channel  = task_s2_bits.channel;
  assign io_status_vec_toTX_1_bits_txChannel = task_s2_bits.txChannel;
  assign io_status_vec_toTX_1_bits_mshrTask = task_s2_bits.mshrTask;

  // s2 任务送 MainPipe；s1 任务信息（valid = s1_fire）
  assign io_taskToPipe_s2_valid = task_s2_valid;
  assign io_taskInfo_s1_valid   = s1_fire;
  assign io_taskToPipe_s2_bits_channel = task_s2_bits.channel;
  assign io_taskToPipe_s2_bits_txChannel = task_s2_bits.txChannel;
  assign io_taskToPipe_s2_bits_set = task_s2_bits.set;
  assign io_taskToPipe_s2_bits_tag = task_s2_bits.tag;
  assign io_taskToPipe_s2_bits_off = task_s2_bits.off;
  assign io_taskToPipe_s2_bits_alias = task_s2_bits.alias_;
  assign io_taskToPipe_s2_bits_vaddr = task_s2_bits.vaddr;
  assign io_taskToPipe_s2_bits_isKeyword = task_s2_bits.isKeyword;
  assign io_taskToPipe_s2_bits_opcode = task_s2_bits.opcode;
  assign io_taskToPipe_s2_bits_param = task_s2_bits.param;
  assign io_taskToPipe_s2_bits_size = task_s2_bits.size;
  assign io_taskToPipe_s2_bits_sourceId = task_s2_bits.sourceId;
  assign io_taskToPipe_s2_bits_bufIdx = task_s2_bits.bufIdx;
  assign io_taskToPipe_s2_bits_needProbeAckData = task_s2_bits.needProbeAckData;
  assign io_taskToPipe_s2_bits_denied = task_s2_bits.denied;
  assign io_taskToPipe_s2_bits_corrupt = task_s2_bits.corrupt;
  assign io_taskToPipe_s2_bits_mshrTask = task_s2_bits.mshrTask;
  assign io_taskToPipe_s2_bits_mshrId = task_s2_bits.mshrId;
  assign io_taskToPipe_s2_bits_aliasTask = task_s2_bits.aliasTask;
  assign io_taskToPipe_s2_bits_useProbeData = task_s2_bits.useProbeData;
  assign io_taskToPipe_s2_bits_mshrRetry = task_s2_bits.mshrRetry;
  assign io_taskToPipe_s2_bits_readProbeDataDown = task_s2_bits.readProbeDataDown;
  assign io_taskToPipe_s2_bits_fromL2pft = task_s2_bits.fromL2pft;
  assign io_taskToPipe_s2_bits_needHint = task_s2_bits.needHint;
  assign io_taskToPipe_s2_bits_dirty = task_s2_bits.dirty;
  assign io_taskToPipe_s2_bits_way = task_s2_bits.way;
  assign io_taskToPipe_s2_bits_meta_dirty = task_s2_bits.meta_dirty;
  assign io_taskToPipe_s2_bits_meta_state = task_s2_bits.meta_state;
  assign io_taskToPipe_s2_bits_meta_clients = task_s2_bits.meta_clients;
  assign io_taskToPipe_s2_bits_meta_alias = task_s2_bits.meta_alias;
  assign io_taskToPipe_s2_bits_meta_prefetch = task_s2_bits.meta_prefetch;
  assign io_taskToPipe_s2_bits_meta_prefetchSrc = task_s2_bits.meta_prefetchSrc;
  assign io_taskToPipe_s2_bits_meta_accessed = task_s2_bits.meta_accessed;
  assign io_taskToPipe_s2_bits_meta_tagErr = task_s2_bits.meta_tagErr;
  assign io_taskToPipe_s2_bits_meta_dataErr = task_s2_bits.meta_dataErr;
  assign io_taskToPipe_s2_bits_metaWen = task_s2_bits.metaWen;
  assign io_taskToPipe_s2_bits_tagWen = task_s2_bits.tagWen;
  assign io_taskToPipe_s2_bits_dsWen = task_s2_bits.dsWen;
  assign io_taskToPipe_s2_bits_wayMask = task_s2_bits.wayMask;
  assign io_taskToPipe_s2_bits_replTask = task_s2_bits.replTask;
  assign io_taskToPipe_s2_bits_cmoTask = task_s2_bits.cmoTask;
  assign io_taskToPipe_s2_bits_cmoAll = task_s2_bits.cmoAll;
  assign io_taskToPipe_s2_bits_reqSource = task_s2_bits.reqSource;
  assign io_taskToPipe_s2_bits_mergeA = task_s2_bits.mergeA;
  assign io_taskToPipe_s2_bits_aMergeTask_off = task_s2_bits.aMergeTask_off;
  assign io_taskToPipe_s2_bits_aMergeTask_alias = task_s2_bits.aMergeTask_alias;
  assign io_taskToPipe_s2_bits_aMergeTask_vaddr = task_s2_bits.aMergeTask_vaddr;
  assign io_taskToPipe_s2_bits_aMergeTask_isKeyword = task_s2_bits.aMergeTask_isKeyword;
  assign io_taskToPipe_s2_bits_aMergeTask_opcode = task_s2_bits.aMergeTask_opcode;
  assign io_taskToPipe_s2_bits_aMergeTask_param = task_s2_bits.aMergeTask_param;
  assign io_taskToPipe_s2_bits_aMergeTask_sourceId = task_s2_bits.aMergeTask_sourceId;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_dirty = task_s2_bits.aMergeTask_meta_dirty;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_state = task_s2_bits.aMergeTask_meta_state;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_clients = task_s2_bits.aMergeTask_meta_clients;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_alias = task_s2_bits.aMergeTask_meta_alias;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_prefetch = task_s2_bits.aMergeTask_meta_prefetch;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc = task_s2_bits.aMergeTask_meta_prefetchSrc;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_accessed = task_s2_bits.aMergeTask_meta_accessed;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_tagErr = task_s2_bits.aMergeTask_meta_tagErr;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_dataErr = task_s2_bits.aMergeTask_meta_dataErr;
  assign io_taskToPipe_s2_bits_snpHitRelease = task_s2_bits.snpHitRelease;
  assign io_taskToPipe_s2_bits_snpHitReleaseToInval = task_s2_bits.snpHitReleaseToInval;
  assign io_taskToPipe_s2_bits_snpHitReleaseToClean = task_s2_bits.snpHitReleaseToClean;
  assign io_taskToPipe_s2_bits_snpHitReleaseWithData = task_s2_bits.snpHitReleaseWithData;
  assign io_taskToPipe_s2_bits_snpHitReleaseIdx = task_s2_bits.snpHitReleaseIdx;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty = task_s2_bits.snpHitReleaseMeta_dirty;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_state = task_s2_bits.snpHitReleaseMeta_state;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_clients = task_s2_bits.snpHitReleaseMeta_clients;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_alias = task_s2_bits.snpHitReleaseMeta_alias;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch = task_s2_bits.snpHitReleaseMeta_prefetch;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc = task_s2_bits.snpHitReleaseMeta_prefetchSrc;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed = task_s2_bits.snpHitReleaseMeta_accessed;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr = task_s2_bits.snpHitReleaseMeta_tagErr;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr = task_s2_bits.snpHitReleaseMeta_dataErr;
  assign io_taskToPipe_s2_bits_tgtID = task_s2_bits.tgtID;
  assign io_taskToPipe_s2_bits_srcID = task_s2_bits.srcID;
  assign io_taskToPipe_s2_bits_txnID = task_s2_bits.txnID;
  assign io_taskToPipe_s2_bits_homeNID = task_s2_bits.homeNID;
  assign io_taskToPipe_s2_bits_dbID = task_s2_bits.dbID;
  assign io_taskToPipe_s2_bits_fwdNID = task_s2_bits.fwdNID;
  assign io_taskToPipe_s2_bits_fwdTxnID = task_s2_bits.fwdTxnID;
  assign io_taskToPipe_s2_bits_chiOpcode = task_s2_bits.chiOpcode;
  assign io_taskToPipe_s2_bits_resp = task_s2_bits.resp;
  assign io_taskToPipe_s2_bits_fwdState = task_s2_bits.fwdState;
  assign io_taskToPipe_s2_bits_pCrdType = task_s2_bits.pCrdType;
  assign io_taskToPipe_s2_bits_retToSrc = task_s2_bits.retToSrc;
  assign io_taskToPipe_s2_bits_likelyshared = task_s2_bits.likelyshared;
  assign io_taskToPipe_s2_bits_expCompAck = task_s2_bits.expCompAck;
  assign io_taskToPipe_s2_bits_allowRetry = task_s2_bits.allowRetry;
  assign io_taskToPipe_s2_bits_memAttr_allocate = task_s2_bits.memAttr_allocate;
  assign io_taskToPipe_s2_bits_memAttr_cacheable = task_s2_bits.memAttr_cacheable;
  assign io_taskToPipe_s2_bits_memAttr_device = task_s2_bits.memAttr_device;
  assign io_taskToPipe_s2_bits_memAttr_ewa = task_s2_bits.memAttr_ewa;
  assign io_taskToPipe_s2_bits_traceTag = task_s2_bits.traceTag;
  assign io_taskInfo_s1_bits_channel = task_s1.channel;
  assign io_taskInfo_s1_bits_txChannel = task_s1.txChannel;
  assign io_taskInfo_s1_bits_set = task_s1.set;
  assign io_taskInfo_s1_bits_tag = task_s1.tag;
  assign io_taskInfo_s1_bits_off = task_s1.off;
  assign io_taskInfo_s1_bits_alias = task_s1.alias_;
  assign io_taskInfo_s1_bits_vaddr = task_s1.vaddr;
  assign io_taskInfo_s1_bits_isKeyword = task_s1.isKeyword;
  assign io_taskInfo_s1_bits_opcode = task_s1.opcode;
  assign io_taskInfo_s1_bits_param = task_s1.param;
  assign io_taskInfo_s1_bits_size = task_s1.size;
  assign io_taskInfo_s1_bits_sourceId = task_s1.sourceId;
  assign io_taskInfo_s1_bits_bufIdx = task_s1.bufIdx;
  assign io_taskInfo_s1_bits_needProbeAckData = task_s1.needProbeAckData;
  assign io_taskInfo_s1_bits_denied = task_s1.denied;
  assign io_taskInfo_s1_bits_corrupt = task_s1.corrupt;
  assign io_taskInfo_s1_bits_mshrTask = task_s1.mshrTask;
  assign io_taskInfo_s1_bits_mshrId = task_s1.mshrId;
  assign io_taskInfo_s1_bits_aliasTask = task_s1.aliasTask;
  assign io_taskInfo_s1_bits_useProbeData = task_s1.useProbeData;
  assign io_taskInfo_s1_bits_mshrRetry = task_s1.mshrRetry;
  assign io_taskInfo_s1_bits_readProbeDataDown = task_s1.readProbeDataDown;
  assign io_taskInfo_s1_bits_fromL2pft = task_s1.fromL2pft;
  assign io_taskInfo_s1_bits_needHint = task_s1.needHint;
  assign io_taskInfo_s1_bits_dirty = task_s1.dirty;
  assign io_taskInfo_s1_bits_way = task_s1.way;
  assign io_taskInfo_s1_bits_meta_dirty = task_s1.meta_dirty;
  assign io_taskInfo_s1_bits_meta_state = task_s1.meta_state;
  assign io_taskInfo_s1_bits_meta_clients = task_s1.meta_clients;
  assign io_taskInfo_s1_bits_meta_alias = task_s1.meta_alias;
  assign io_taskInfo_s1_bits_meta_prefetch = task_s1.meta_prefetch;
  assign io_taskInfo_s1_bits_meta_prefetchSrc = task_s1.meta_prefetchSrc;
  assign io_taskInfo_s1_bits_meta_accessed = task_s1.meta_accessed;
  assign io_taskInfo_s1_bits_meta_tagErr = task_s1.meta_tagErr;
  assign io_taskInfo_s1_bits_meta_dataErr = task_s1.meta_dataErr;
  assign io_taskInfo_s1_bits_metaWen = task_s1.metaWen;
  assign io_taskInfo_s1_bits_tagWen = task_s1.tagWen;
  assign io_taskInfo_s1_bits_dsWen = task_s1.dsWen;
  assign io_taskInfo_s1_bits_wayMask = task_s1.wayMask;
  assign io_taskInfo_s1_bits_replTask = task_s1.replTask;
  assign io_taskInfo_s1_bits_cmoTask = task_s1.cmoTask;
  assign io_taskInfo_s1_bits_cmoAll = task_s1.cmoAll;
  assign io_taskInfo_s1_bits_reqSource = task_s1.reqSource;
  assign io_taskInfo_s1_bits_mergeA = task_s1.mergeA;
  assign io_taskInfo_s1_bits_aMergeTask_off = task_s1.aMergeTask_off;
  assign io_taskInfo_s1_bits_aMergeTask_alias = task_s1.aMergeTask_alias;
  assign io_taskInfo_s1_bits_aMergeTask_vaddr = task_s1.aMergeTask_vaddr;
  assign io_taskInfo_s1_bits_aMergeTask_isKeyword = task_s1.aMergeTask_isKeyword;
  assign io_taskInfo_s1_bits_aMergeTask_opcode = task_s1.aMergeTask_opcode;
  assign io_taskInfo_s1_bits_aMergeTask_param = task_s1.aMergeTask_param;
  assign io_taskInfo_s1_bits_aMergeTask_sourceId = task_s1.aMergeTask_sourceId;
  assign io_taskInfo_s1_bits_aMergeTask_meta_dirty = task_s1.aMergeTask_meta_dirty;
  assign io_taskInfo_s1_bits_aMergeTask_meta_state = task_s1.aMergeTask_meta_state;
  assign io_taskInfo_s1_bits_aMergeTask_meta_clients = task_s1.aMergeTask_meta_clients;
  assign io_taskInfo_s1_bits_aMergeTask_meta_alias = task_s1.aMergeTask_meta_alias;
  assign io_taskInfo_s1_bits_aMergeTask_meta_prefetch = task_s1.aMergeTask_meta_prefetch;
  assign io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc = task_s1.aMergeTask_meta_prefetchSrc;
  assign io_taskInfo_s1_bits_aMergeTask_meta_accessed = task_s1.aMergeTask_meta_accessed;
  assign io_taskInfo_s1_bits_aMergeTask_meta_tagErr = task_s1.aMergeTask_meta_tagErr;
  assign io_taskInfo_s1_bits_aMergeTask_meta_dataErr = task_s1.aMergeTask_meta_dataErr;
  assign io_taskInfo_s1_bits_snpHitRelease = task_s1.snpHitRelease;
  assign io_taskInfo_s1_bits_snpHitReleaseToInval = task_s1.snpHitReleaseToInval;
  assign io_taskInfo_s1_bits_snpHitReleaseToClean = task_s1.snpHitReleaseToClean;
  assign io_taskInfo_s1_bits_snpHitReleaseWithData = task_s1.snpHitReleaseWithData;
  assign io_taskInfo_s1_bits_snpHitReleaseIdx = task_s1.snpHitReleaseIdx;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_dirty = task_s1.snpHitReleaseMeta_dirty;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_state = task_s1.snpHitReleaseMeta_state;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_clients = task_s1.snpHitReleaseMeta_clients;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_alias = task_s1.snpHitReleaseMeta_alias;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch = task_s1.snpHitReleaseMeta_prefetch;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc = task_s1.snpHitReleaseMeta_prefetchSrc;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_accessed = task_s1.snpHitReleaseMeta_accessed;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr = task_s1.snpHitReleaseMeta_tagErr;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr = task_s1.snpHitReleaseMeta_dataErr;
  assign io_taskInfo_s1_bits_tgtID = task_s1.tgtID;
  assign io_taskInfo_s1_bits_srcID = task_s1.srcID;
  assign io_taskInfo_s1_bits_txnID = task_s1.txnID;
  assign io_taskInfo_s1_bits_homeNID = task_s1.homeNID;
  assign io_taskInfo_s1_bits_dbID = task_s1.dbID;
  assign io_taskInfo_s1_bits_fwdNID = task_s1.fwdNID;
  assign io_taskInfo_s1_bits_fwdTxnID = task_s1.fwdTxnID;
  assign io_taskInfo_s1_bits_chiOpcode = task_s1.chiOpcode;
  assign io_taskInfo_s1_bits_resp = task_s1.resp;
  assign io_taskInfo_s1_bits_fwdState = task_s1.fwdState;
  assign io_taskInfo_s1_bits_pCrdType = task_s1.pCrdType;
  assign io_taskInfo_s1_bits_retToSrc = task_s1.retToSrc;
  assign io_taskInfo_s1_bits_likelyshared = task_s1.likelyshared;
  assign io_taskInfo_s1_bits_expCompAck = task_s1.expCompAck;
  assign io_taskInfo_s1_bits_allowRetry = task_s1.allowRetry;
  assign io_taskInfo_s1_bits_memAttr_allocate = task_s1.memAttr_allocate;
  assign io_taskInfo_s1_bits_memAttr_cacheable = task_s1.memAttr_cacheable;
  assign io_taskInfo_s1_bits_memAttr_device = task_s1.memAttr_device;
  assign io_taskInfo_s1_bits_memAttr_ewa = task_s1.memAttr_ewa;
  assign io_taskInfo_s1_bits_traceTag = task_s1.traceTag;

endmodule
// END GENERATED(wrapper)
