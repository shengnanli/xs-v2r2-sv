// 自动生成 scripts/gen_grantbuffer.py —— 勿手改
// coupledL2 (tl2chi) L2 slice 公共 TaskBundle 结构体, GrantBuffer/RequestArb 共用。
// 字段顺序/位宽与 firtool 展平的 io_*_bits_task_* 完全一致。
`ifndef L2_TASK_PKG_SV
`define L2_TASK_PKG_SV
package l2_task_pkg;

  // L2 slice 主流水 TaskBundle (单态化: tl2chi, 95 字段)
  typedef struct packed {
    logic [2:0]     channel;
    logic [2:0]     txChannel;
    logic [8:0]     set;
    logic [30:0]    tag;
    logic [5:0]     off;
    logic [1:0]     alias_;
    logic [43:0]    vaddr;
    logic           isKeyword;
    logic [3:0]     opcode;
    logic [2:0]     param;
    logic [2:0]     size;
    logic [6:0]     sourceId;
    logic [1:0]     bufIdx;
    logic           needProbeAckData;
    logic           denied;
    logic           corrupt;
    logic           mshrTask;
    logic [7:0]     mshrId;
    logic           aliasTask;
    logic           useProbeData;
    logic           mshrRetry;
    logic           readProbeDataDown;
    logic           fromL2pft;
    logic           needHint;
    logic           dirty;
    logic [2:0]     way;
    logic           meta_dirty;
    logic [1:0]     meta_state;
    logic           meta_clients;
    logic [1:0]     meta_alias;
    logic           meta_prefetch;
    logic [2:0]     meta_prefetchSrc;
    logic           meta_accessed;
    logic           meta_tagErr;
    logic           meta_dataErr;
    logic           metaWen;
    logic           tagWen;
    logic           dsWen;
    logic [7:0]     wayMask;
    logic           replTask;
    logic           cmoTask;
    logic           cmoAll;
    logic [4:0]     reqSource;
    logic           mergeA;
    logic [5:0]     aMergeTask_off;
    logic [1:0]     aMergeTask_alias;
    logic [43:0]    aMergeTask_vaddr;
    logic           aMergeTask_isKeyword;
    logic [2:0]     aMergeTask_opcode;
    logic [2:0]     aMergeTask_param;
    logic [6:0]     aMergeTask_sourceId;
    logic           aMergeTask_meta_dirty;
    logic [1:0]     aMergeTask_meta_state;
    logic           aMergeTask_meta_clients;
    logic [1:0]     aMergeTask_meta_alias;
    logic           aMergeTask_meta_prefetch;
    logic [2:0]     aMergeTask_meta_prefetchSrc;
    logic           aMergeTask_meta_accessed;
    logic           aMergeTask_meta_tagErr;
    logic           aMergeTask_meta_dataErr;
    logic           snpHitRelease;
    logic           snpHitReleaseToInval;
    logic           snpHitReleaseToClean;
    logic           snpHitReleaseWithData;
    logic [7:0]     snpHitReleaseIdx;
    logic           snpHitReleaseMeta_dirty;
    logic [1:0]     snpHitReleaseMeta_state;
    logic           snpHitReleaseMeta_clients;
    logic [1:0]     snpHitReleaseMeta_alias;
    logic           snpHitReleaseMeta_prefetch;
    logic [2:0]     snpHitReleaseMeta_prefetchSrc;
    logic           snpHitReleaseMeta_accessed;
    logic           snpHitReleaseMeta_tagErr;
    logic           snpHitReleaseMeta_dataErr;
    logic [10:0]    tgtID;
    logic [10:0]    srcID;
    logic [11:0]    txnID;
    logic [10:0]    homeNID;
    logic [11:0]    dbID;
    logic [10:0]    fwdNID;
    logic [11:0]    fwdTxnID;
    logic [6:0]     chiOpcode;
    logic [2:0]     resp;
    logic [2:0]     fwdState;
    logic [3:0]     pCrdType;
    logic           retToSrc;
    logic           likelyshared;
    logic           expCompAck;
    logic           allowRetry;
    logic           memAttr_allocate;
    logic           memAttr_cacheable;
    logic           memAttr_device;
    logic           memAttr_ewa;
    logic           traceTag;
    logic           dataCheckErr;
  } task_bundle_t;

endpackage
`endif
