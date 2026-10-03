// Queue1_ChosenQBundle.sv —— RequestBuffer 的 chosenQ：仲裁出的那一项（含 buffer 下标 id）在此等 MainPipe 收，pipe
//
// chisel3 Queue(entries=1, pipe=true, flow=false) 的单态化（父模块 RequestBuffer）。控制与存储在
// rtl/common/xs_ChiselQueue1_core.sv；本文件只把 Bundle 字段按 golden 的顺序拼成 407 位字、再拆回来。
// ★照 golden 保留的两类"没用的位"★：
//   * 补零段：入队时恒为 0 的 TaskBundle 字段（SinkA 送来的 A 请求里这些字段是常量 0），golden 仍占着 ram 的位，
//     出队时照样从 ram 读出（上电后第一次入队之前它们是 ram 的初值）；
//   * 出队没人要的字段：bits_waitMS, bits_waitMP, bits_rdy, bits_valid —— 存进 ram 但无读者（FM 里两侧对称的未读位）。
// golden 383 行；由 scripts/gen_l2_queues.py 从 golden 机械生成并逐字段校验切片。

// BEGIN GENERATED(Queue1_ChosenQBundle) —— scripts/gen_l2_queues.py
module Queue1_ChosenQBundle (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic io_enq_bits_bits_valid,
  input  logic io_enq_bits_bits_rdy,
  input  logic [2:0] io_enq_bits_bits_task_channel,
  input  logic [8:0] io_enq_bits_bits_task_set,
  input  logic [30:0] io_enq_bits_bits_task_tag,
  input  logic [5:0] io_enq_bits_bits_task_off,
  input  logic [1:0] io_enq_bits_bits_task_alias,
  input  logic [43:0] io_enq_bits_bits_task_vaddr,
  input  logic io_enq_bits_bits_task_isKeyword,
  input  logic [3:0] io_enq_bits_bits_task_opcode,
  input  logic [2:0] io_enq_bits_bits_task_param,
  input  logic [2:0] io_enq_bits_bits_task_size,
  input  logic [6:0] io_enq_bits_bits_task_sourceId,
  input  logic io_enq_bits_bits_task_corrupt,
  input  logic io_enq_bits_bits_task_fromL2pft,
  input  logic io_enq_bits_bits_task_needHint,
  input  logic [4:0] io_enq_bits_bits_task_reqSource,
  input  logic [3:0] io_enq_bits_bits_waitMP,
  input  logic [15:0] io_enq_bits_bits_waitMS,
  input  logic [1:0] io_enq_bits_id,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [2:0] io_deq_bits_bits_task_channel,
  output logic [2:0] io_deq_bits_bits_task_txChannel,
  output logic [8:0] io_deq_bits_bits_task_set,
  output logic [30:0] io_deq_bits_bits_task_tag,
  output logic [5:0] io_deq_bits_bits_task_off,
  output logic [1:0] io_deq_bits_bits_task_alias,
  output logic [43:0] io_deq_bits_bits_task_vaddr,
  output logic io_deq_bits_bits_task_isKeyword,
  output logic [3:0] io_deq_bits_bits_task_opcode,
  output logic [2:0] io_deq_bits_bits_task_param,
  output logic [2:0] io_deq_bits_bits_task_size,
  output logic [6:0] io_deq_bits_bits_task_sourceId,
  output logic [1:0] io_deq_bits_bits_task_bufIdx,
  output logic io_deq_bits_bits_task_needProbeAckData,
  output logic io_deq_bits_bits_task_denied,
  output logic io_deq_bits_bits_task_corrupt,
  output logic io_deq_bits_bits_task_mshrTask,
  output logic [7:0] io_deq_bits_bits_task_mshrId,
  output logic io_deq_bits_bits_task_aliasTask,
  output logic io_deq_bits_bits_task_useProbeData,
  output logic io_deq_bits_bits_task_mshrRetry,
  output logic io_deq_bits_bits_task_readProbeDataDown,
  output logic io_deq_bits_bits_task_fromL2pft,
  output logic io_deq_bits_bits_task_needHint,
  output logic io_deq_bits_bits_task_dirty,
  output logic [2:0] io_deq_bits_bits_task_way,
  output logic io_deq_bits_bits_task_meta_dirty,
  output logic [1:0] io_deq_bits_bits_task_meta_state,
  output logic io_deq_bits_bits_task_meta_clients,
  output logic [1:0] io_deq_bits_bits_task_meta_alias,
  output logic io_deq_bits_bits_task_meta_prefetch,
  output logic [2:0] io_deq_bits_bits_task_meta_prefetchSrc,
  output logic io_deq_bits_bits_task_meta_accessed,
  output logic io_deq_bits_bits_task_meta_tagErr,
  output logic io_deq_bits_bits_task_meta_dataErr,
  output logic io_deq_bits_bits_task_metaWen,
  output logic io_deq_bits_bits_task_tagWen,
  output logic io_deq_bits_bits_task_dsWen,
  output logic io_deq_bits_bits_task_replTask,
  output logic io_deq_bits_bits_task_cmoTask,
  output logic io_deq_bits_bits_task_cmoAll,
  output logic [4:0] io_deq_bits_bits_task_reqSource,
  output logic io_deq_bits_bits_task_mergeA,
  output logic [5:0] io_deq_bits_bits_task_aMergeTask_off,
  output logic [1:0] io_deq_bits_bits_task_aMergeTask_alias,
  output logic [43:0] io_deq_bits_bits_task_aMergeTask_vaddr,
  output logic io_deq_bits_bits_task_aMergeTask_isKeyword,
  output logic [2:0] io_deq_bits_bits_task_aMergeTask_opcode,
  output logic [2:0] io_deq_bits_bits_task_aMergeTask_param,
  output logic [6:0] io_deq_bits_bits_task_aMergeTask_sourceId,
  output logic io_deq_bits_bits_task_aMergeTask_meta_dirty,
  output logic [1:0] io_deq_bits_bits_task_aMergeTask_meta_state,
  output logic io_deq_bits_bits_task_aMergeTask_meta_clients,
  output logic [1:0] io_deq_bits_bits_task_aMergeTask_meta_alias,
  output logic io_deq_bits_bits_task_aMergeTask_meta_prefetch,
  output logic [2:0] io_deq_bits_bits_task_aMergeTask_meta_prefetchSrc,
  output logic io_deq_bits_bits_task_aMergeTask_meta_accessed,
  output logic io_deq_bits_bits_task_aMergeTask_meta_tagErr,
  output logic io_deq_bits_bits_task_aMergeTask_meta_dataErr,
  output logic io_deq_bits_bits_task_snpHitRelease,
  output logic io_deq_bits_bits_task_snpHitReleaseToInval,
  output logic io_deq_bits_bits_task_snpHitReleaseToClean,
  output logic io_deq_bits_bits_task_snpHitReleaseWithData,
  output logic [7:0] io_deq_bits_bits_task_snpHitReleaseIdx,
  output logic io_deq_bits_bits_task_snpHitReleaseMeta_dirty,
  output logic [1:0] io_deq_bits_bits_task_snpHitReleaseMeta_state,
  output logic io_deq_bits_bits_task_snpHitReleaseMeta_clients,
  output logic [1:0] io_deq_bits_bits_task_snpHitReleaseMeta_alias,
  output logic io_deq_bits_bits_task_snpHitReleaseMeta_prefetch,
  output logic [2:0] io_deq_bits_bits_task_snpHitReleaseMeta_prefetchSrc,
  output logic io_deq_bits_bits_task_snpHitReleaseMeta_accessed,
  output logic io_deq_bits_bits_task_snpHitReleaseMeta_tagErr,
  output logic io_deq_bits_bits_task_snpHitReleaseMeta_dataErr,
  output logic [10:0] io_deq_bits_bits_task_tgtID,
  output logic [10:0] io_deq_bits_bits_task_srcID,
  output logic [11:0] io_deq_bits_bits_task_txnID,
  output logic [10:0] io_deq_bits_bits_task_homeNID,
  output logic [11:0] io_deq_bits_bits_task_dbID,
  output logic [10:0] io_deq_bits_bits_task_fwdNID,
  output logic [11:0] io_deq_bits_bits_task_fwdTxnID,
  output logic [6:0] io_deq_bits_bits_task_chiOpcode,
  output logic [2:0] io_deq_bits_bits_task_resp,
  output logic [2:0] io_deq_bits_bits_task_fwdState,
  output logic [3:0] io_deq_bits_bits_task_pCrdType,
  output logic io_deq_bits_bits_task_retToSrc,
  output logic io_deq_bits_bits_task_likelyshared,
  output logic io_deq_bits_bits_task_expCompAck,
  output logic io_deq_bits_bits_task_allowRetry,
  output logic io_deq_bits_bits_task_memAttr_allocate,
  output logic io_deq_bits_bits_task_memAttr_cacheable,
  output logic io_deq_bits_bits_task_memAttr_device,
  output logic io_deq_bits_bits_task_memAttr_ewa,
  output logic io_deq_bits_bits_task_traceTag,
  output logic [1:0] io_deq_bits_id
);

  logic [406:0] enqWord, deqWord;

  // 入队字（高位在前；补零段是恒 0 的 Bundle 字段）
  assign enqWord = {
    io_enq_bits_id,
    io_enq_bits_bits_waitMS,
    io_enq_bits_bits_waitMP,
    211'h0,
    io_enq_bits_bits_task_reqSource,
    31'h0,
    io_enq_bits_bits_task_needHint,
    io_enq_bits_bits_task_fromL2pft,
    13'h0,
    io_enq_bits_bits_task_corrupt,
    4'h0,
    io_enq_bits_bits_task_sourceId,
    io_enq_bits_bits_task_size,
    io_enq_bits_bits_task_param,
    io_enq_bits_bits_task_opcode,
    io_enq_bits_bits_task_isKeyword,
    io_enq_bits_bits_task_vaddr,
    io_enq_bits_bits_task_alias,
    io_enq_bits_bits_task_off,
    io_enq_bits_bits_task_tag,
    io_enq_bits_bits_task_set,
    3'h0,
    io_enq_bits_bits_task_channel,
    io_enq_bits_bits_rdy,
    io_enq_bits_bits_valid
  };

  xs_ChiselQueue1_core #(.W(407), .PIPE(1'b1)) u_core (
    .clock     (clock),
    .reset     (reset),
    .enq_valid (io_enq_valid),
    .enq_ready (io_enq_ready),
    .enq_word  (enqWord),
    .deq_valid (io_deq_valid),
    .deq_ready (io_deq_ready),
    .deq_word  (deqWord)
  );

  assign io_deq_bits_bits_task_channel = deqWord[4:2];
  assign io_deq_bits_bits_task_txChannel = deqWord[7:5];
  assign io_deq_bits_bits_task_set = deqWord[16:8];
  assign io_deq_bits_bits_task_tag = deqWord[47:17];
  assign io_deq_bits_bits_task_off = deqWord[53:48];
  assign io_deq_bits_bits_task_alias = deqWord[55:54];
  assign io_deq_bits_bits_task_vaddr = deqWord[99:56];
  assign io_deq_bits_bits_task_isKeyword = deqWord[100];
  assign io_deq_bits_bits_task_opcode = deqWord[104:101];
  assign io_deq_bits_bits_task_param = deqWord[107:105];
  assign io_deq_bits_bits_task_size = deqWord[110:108];
  assign io_deq_bits_bits_task_sourceId = deqWord[117:111];
  assign io_deq_bits_bits_task_bufIdx = deqWord[119:118];
  assign io_deq_bits_bits_task_needProbeAckData = deqWord[120];
  assign io_deq_bits_bits_task_denied = deqWord[121];
  assign io_deq_bits_bits_task_corrupt = deqWord[122];
  assign io_deq_bits_bits_task_mshrTask = deqWord[123];
  assign io_deq_bits_bits_task_mshrId = deqWord[131:124];
  assign io_deq_bits_bits_task_aliasTask = deqWord[132];
  assign io_deq_bits_bits_task_useProbeData = deqWord[133];
  assign io_deq_bits_bits_task_mshrRetry = deqWord[134];
  assign io_deq_bits_bits_task_readProbeDataDown = deqWord[135];
  assign io_deq_bits_bits_task_fromL2pft = deqWord[136];
  assign io_deq_bits_bits_task_needHint = deqWord[137];
  assign io_deq_bits_bits_task_dirty = deqWord[138];
  assign io_deq_bits_bits_task_way = deqWord[141:139];
  assign io_deq_bits_bits_task_meta_dirty = deqWord[142];
  assign io_deq_bits_bits_task_meta_state = deqWord[144:143];
  assign io_deq_bits_bits_task_meta_clients = deqWord[145];
  assign io_deq_bits_bits_task_meta_alias = deqWord[147:146];
  assign io_deq_bits_bits_task_meta_prefetch = deqWord[148];
  assign io_deq_bits_bits_task_meta_prefetchSrc = deqWord[151:149];
  assign io_deq_bits_bits_task_meta_accessed = deqWord[152];
  assign io_deq_bits_bits_task_meta_tagErr = deqWord[153];
  assign io_deq_bits_bits_task_meta_dataErr = deqWord[154];
  assign io_deq_bits_bits_task_metaWen = deqWord[155];
  assign io_deq_bits_bits_task_tagWen = deqWord[156];
  assign io_deq_bits_bits_task_dsWen = deqWord[157];
  assign io_deq_bits_bits_task_replTask = deqWord[166];
  assign io_deq_bits_bits_task_cmoTask = deqWord[167];
  assign io_deq_bits_bits_task_cmoAll = deqWord[168];
  assign io_deq_bits_bits_task_reqSource = deqWord[173:169];
  assign io_deq_bits_bits_task_mergeA = deqWord[174];
  assign io_deq_bits_bits_task_aMergeTask_off = deqWord[180:175];
  assign io_deq_bits_bits_task_aMergeTask_alias = deqWord[182:181];
  assign io_deq_bits_bits_task_aMergeTask_vaddr = deqWord[226:183];
  assign io_deq_bits_bits_task_aMergeTask_isKeyword = deqWord[227];
  assign io_deq_bits_bits_task_aMergeTask_opcode = deqWord[230:228];
  assign io_deq_bits_bits_task_aMergeTask_param = deqWord[233:231];
  assign io_deq_bits_bits_task_aMergeTask_sourceId = deqWord[240:234];
  assign io_deq_bits_bits_task_aMergeTask_meta_dirty = deqWord[241];
  assign io_deq_bits_bits_task_aMergeTask_meta_state = deqWord[243:242];
  assign io_deq_bits_bits_task_aMergeTask_meta_clients = deqWord[244];
  assign io_deq_bits_bits_task_aMergeTask_meta_alias = deqWord[246:245];
  assign io_deq_bits_bits_task_aMergeTask_meta_prefetch = deqWord[247];
  assign io_deq_bits_bits_task_aMergeTask_meta_prefetchSrc = deqWord[250:248];
  assign io_deq_bits_bits_task_aMergeTask_meta_accessed = deqWord[251];
  assign io_deq_bits_bits_task_aMergeTask_meta_tagErr = deqWord[252];
  assign io_deq_bits_bits_task_aMergeTask_meta_dataErr = deqWord[253];
  assign io_deq_bits_bits_task_snpHitRelease = deqWord[254];
  assign io_deq_bits_bits_task_snpHitReleaseToInval = deqWord[255];
  assign io_deq_bits_bits_task_snpHitReleaseToClean = deqWord[256];
  assign io_deq_bits_bits_task_snpHitReleaseWithData = deqWord[257];
  assign io_deq_bits_bits_task_snpHitReleaseIdx = deqWord[265:258];
  assign io_deq_bits_bits_task_snpHitReleaseMeta_dirty = deqWord[266];
  assign io_deq_bits_bits_task_snpHitReleaseMeta_state = deqWord[268:267];
  assign io_deq_bits_bits_task_snpHitReleaseMeta_clients = deqWord[269];
  assign io_deq_bits_bits_task_snpHitReleaseMeta_alias = deqWord[271:270];
  assign io_deq_bits_bits_task_snpHitReleaseMeta_prefetch = deqWord[272];
  assign io_deq_bits_bits_task_snpHitReleaseMeta_prefetchSrc = deqWord[275:273];
  assign io_deq_bits_bits_task_snpHitReleaseMeta_accessed = deqWord[276];
  assign io_deq_bits_bits_task_snpHitReleaseMeta_tagErr = deqWord[277];
  assign io_deq_bits_bits_task_snpHitReleaseMeta_dataErr = deqWord[278];
  assign io_deq_bits_bits_task_tgtID = deqWord[289:279];
  assign io_deq_bits_bits_task_srcID = deqWord[300:290];
  assign io_deq_bits_bits_task_txnID = deqWord[312:301];
  assign io_deq_bits_bits_task_homeNID = deqWord[323:313];
  assign io_deq_bits_bits_task_dbID = deqWord[335:324];
  assign io_deq_bits_bits_task_fwdNID = deqWord[346:336];
  assign io_deq_bits_bits_task_fwdTxnID = deqWord[358:347];
  assign io_deq_bits_bits_task_chiOpcode = deqWord[365:359];
  assign io_deq_bits_bits_task_resp = deqWord[368:366];
  assign io_deq_bits_bits_task_fwdState = deqWord[371:369];
  assign io_deq_bits_bits_task_pCrdType = deqWord[375:372];
  assign io_deq_bits_bits_task_retToSrc = deqWord[376];
  assign io_deq_bits_bits_task_likelyshared = deqWord[377];
  assign io_deq_bits_bits_task_expCompAck = deqWord[378];
  assign io_deq_bits_bits_task_allowRetry = deqWord[379];
  assign io_deq_bits_bits_task_memAttr_allocate = deqWord[380];
  assign io_deq_bits_bits_task_memAttr_cacheable = deqWord[381];
  assign io_deq_bits_bits_task_memAttr_device = deqWord[382];
  assign io_deq_bits_bits_task_memAttr_ewa = deqWord[383];
  assign io_deq_bits_bits_task_traceTag = deqWord[384];
  assign io_deq_bits_id = deqWord[406:405];

endmodule
// END GENERATED(Queue1_ChosenQBundle)
