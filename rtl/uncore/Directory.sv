// =============================================================================
//  Directory —— coupledL2 (tl2chi) L2 缓存目录 可读重写核 (xs_Directory_core)
//          ★ 与 MSHR 配对, 构成 L2 一致性核心 ★
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/Directory.scala
//            + coupledL2/src/main/scala/coupledL2/utils/Replacer.scala (DRRIP)
//
//  目录负责: 给定 (set, tag) 查 8 路 tagArray/metaArray, 在 stage3 判命中/选受害路,
//  并维护 DRRIP 替换状态。SRAM (tagArray/metaArray/replacer/origin_bit) 为黑盒, 在
//  golden 同名 wrapper 内例化, 本核仅暴露 SRAM 读数据输入 + 写控制输出。
//
//  ===== 三级流水 (SRAM 单端口, 高频下读延迟大) =====
//    stage1: io.read.fire, 发起 Tag/Meta/replacer/origin SRAM 读
//    stage2: SRAM 读数据返回, RegEnable 锁存进 *_s3
//    stage3: 算 hit/way、受害路 (DRRIP)、错误, 出 io.resp / io.replResp; 更新替换状态
//
//  ===== DRRIP 替换 (Dynamic Re-Reference Interval Prediction) =====
//    每路 2-bit RRPV (Re-Reference Prediction Value), 越大越"快被替换"。
//    get_replace_way : 选 RRPV 最大的路 (并列取最低 way 号)。
//    set-dueling     : 用 PSEL(10b) 计数器在 SRRIP / BRRIP 两种插入策略间动态择优,
//                      监控集 match_a→固定 SRRIP, match_b→固定 BRRIP, 其余→看 PSEL[9]。
//    SRRIP 插入 RRPV=2, BRRIP 插入 RRPV=3; 命中提升到 0; 其余路按需老化(+increment)。
//
//  ===== Tag SECDED ECC =====
//    写: 31-bit tag → 6 个 Hamming 校验位 + 1 总奇偶位 = 38-bit (tag_ecc_encode)。
//    读: 从 38-bit 重算综合征(syndrome)与总奇偶, 判错 (tag_ecc_error)。
//
//  ===== X 铁律 =====
//    复位前 reqValid_s2/s3=0 门控所有输出; 数组 way_s3/finalWay 索引恒在 [0,7];
//    优先级编码严格对齐 golden 的 ParallelPriorityMux / PriorityEncoder。
// =============================================================================
module xs_Directory_core
  import directory_pkg::*;
(
  input  logic        clock,
  input  logic        reset,

  // ---- io.read (DecoupledIO, 目录查询请求) ----
  output logic        io_read_ready,
  input  logic        io_read_valid,
  input  logic [30:0] io_read_bits_tag,
  input  logic [8:0]  io_read_bits_set,
  input  logic [7:0]  io_read_bits_wayMask,
  input  logic [2:0]  io_read_bits_replacerInfo_channel,
  input  logic [2:0]  io_read_bits_replacerInfo_opcode,
  input  logic [4:0]  io_read_bits_replacerInfo_reqSource,
  input  logic        io_read_bits_replacerInfo_refill_prefetch,
  input  logic        io_read_bits_refill,
  input  logic [7:0]  io_read_bits_mshrId,
  input  logic        io_read_bits_cmoAll,
  input  logic [2:0]  io_read_bits_cmoWay,

  // ---- io.resp (ValidIO, 查询结果, stage3) ----
  output logic        io_resp_valid,
  output logic        io_resp_bits_hit,
  output logic [30:0] io_resp_bits_tag,
  output logic [8:0]  io_resp_bits_set,
  output logic [2:0]  io_resp_bits_way,
  output logic        io_resp_bits_meta_dirty,
  output logic [1:0]  io_resp_bits_meta_state,
  output logic        io_resp_bits_meta_clients,
  output logic [1:0]  io_resp_bits_meta_alias,
  output logic        io_resp_bits_meta_prefetch,
  output logic [2:0]  io_resp_bits_meta_prefetchSrc,
  output logic        io_resp_bits_meta_accessed,
  output logic        io_resp_bits_meta_tagErr,
  output logic        io_resp_bits_meta_dataErr,
  output logic        io_resp_bits_error,
  output logic [2:0]  io_resp_bits_replacerInfo_channel,
  output logic [2:0]  io_resp_bits_replacerInfo_opcode,
  output logic [4:0]  io_resp_bits_replacerInfo_reqSource,
  output logic        io_resp_bits_replacerInfo_refill_prefetch,

  // ---- io.metaWReq (ValidIO, 元数据写, 直连 metaArray) ----
  input  logic        io_metaWReq_valid,
  input  logic [8:0]  io_metaWReq_bits_set,
  input  logic [7:0]  io_metaWReq_bits_wayOH,
  input  logic        io_metaWReq_bits_wmeta_dirty,
  input  logic [1:0]  io_metaWReq_bits_wmeta_state,
  input  logic        io_metaWReq_bits_wmeta_clients,
  input  logic [1:0]  io_metaWReq_bits_wmeta_alias,
  input  logic        io_metaWReq_bits_wmeta_prefetch,
  input  logic [2:0]  io_metaWReq_bits_wmeta_prefetchSrc,
  input  logic        io_metaWReq_bits_wmeta_accessed,
  input  logic        io_metaWReq_bits_wmeta_tagErr,
  input  logic        io_metaWReq_bits_wmeta_dataErr,

  // ---- io.tagWReq (ValidIO, 标签写; 本核做 ECC 编码后给 tagArray) ----
  input  logic        io_tagWReq_valid,
  input  logic [8:0]  io_tagWReq_bits_set,
  input  logic [2:0]  io_tagWReq_bits_way,
  input  logic [30:0] io_tagWReq_bits_wtag,

  // ---- io.replResp (ValidIO, 替换选路结果, refill 时回 MSHR) ----
  output logic        io_replResp_valid,
  output logic [30:0] io_replResp_bits_tag,
  output logic [8:0]  io_replResp_bits_set,
  output logic [2:0]  io_replResp_bits_way,
  output logic        io_replResp_bits_meta_dirty,
  output logic [1:0]  io_replResp_bits_meta_state,
  output logic        io_replResp_bits_meta_clients,
  output logic [1:0]  io_replResp_bits_meta_alias,
  output logic        io_replResp_bits_meta_prefetch,
  output logic [2:0]  io_replResp_bits_meta_prefetchSrc,
  output logic        io_replResp_bits_meta_accessed,
  output logic        io_replResp_bits_meta_tagErr,
  output logic        io_replResp_bits_meta_dataErr,
  output logic [7:0]  io_replResp_bits_mshrId,
  output logic        io_replResp_bits_retry,

  // ---- io.msInfo (16 路 MSHR 状态, 仅用其中 valid/set/way/blockRefill/dirHit
  //                 计算 refill 时哪些 way 被占用, 不能用于替换) ----
  input  logic        io_msInfo_0_valid,  input  logic [8:0] io_msInfo_0_bits_set,  input  logic [2:0] io_msInfo_0_bits_way,  input  logic io_msInfo_0_bits_blockRefill,  input  logic io_msInfo_0_bits_dirHit,
  input  logic        io_msInfo_1_valid,  input  logic [8:0] io_msInfo_1_bits_set,  input  logic [2:0] io_msInfo_1_bits_way,  input  logic io_msInfo_1_bits_blockRefill,  input  logic io_msInfo_1_bits_dirHit,
  input  logic        io_msInfo_2_valid,  input  logic [8:0] io_msInfo_2_bits_set,  input  logic [2:0] io_msInfo_2_bits_way,  input  logic io_msInfo_2_bits_blockRefill,  input  logic io_msInfo_2_bits_dirHit,
  input  logic        io_msInfo_3_valid,  input  logic [8:0] io_msInfo_3_bits_set,  input  logic [2:0] io_msInfo_3_bits_way,  input  logic io_msInfo_3_bits_blockRefill,  input  logic io_msInfo_3_bits_dirHit,
  input  logic        io_msInfo_4_valid,  input  logic [8:0] io_msInfo_4_bits_set,  input  logic [2:0] io_msInfo_4_bits_way,  input  logic io_msInfo_4_bits_blockRefill,  input  logic io_msInfo_4_bits_dirHit,
  input  logic        io_msInfo_5_valid,  input  logic [8:0] io_msInfo_5_bits_set,  input  logic [2:0] io_msInfo_5_bits_way,  input  logic io_msInfo_5_bits_blockRefill,  input  logic io_msInfo_5_bits_dirHit,
  input  logic        io_msInfo_6_valid,  input  logic [8:0] io_msInfo_6_bits_set,  input  logic [2:0] io_msInfo_6_bits_way,  input  logic io_msInfo_6_bits_blockRefill,  input  logic io_msInfo_6_bits_dirHit,
  input  logic        io_msInfo_7_valid,  input  logic [8:0] io_msInfo_7_bits_set,  input  logic [2:0] io_msInfo_7_bits_way,  input  logic io_msInfo_7_bits_blockRefill,  input  logic io_msInfo_7_bits_dirHit,
  input  logic        io_msInfo_8_valid,  input  logic [8:0] io_msInfo_8_bits_set,  input  logic [2:0] io_msInfo_8_bits_way,  input  logic io_msInfo_8_bits_blockRefill,  input  logic io_msInfo_8_bits_dirHit,
  input  logic        io_msInfo_9_valid,  input  logic [8:0] io_msInfo_9_bits_set,  input  logic [2:0] io_msInfo_9_bits_way,  input  logic io_msInfo_9_bits_blockRefill,  input  logic io_msInfo_9_bits_dirHit,
  input  logic        io_msInfo_10_valid, input  logic [8:0] io_msInfo_10_bits_set, input  logic [2:0] io_msInfo_10_bits_way, input  logic io_msInfo_10_bits_blockRefill, input  logic io_msInfo_10_bits_dirHit,
  input  logic        io_msInfo_11_valid, input  logic [8:0] io_msInfo_11_bits_set, input  logic [2:0] io_msInfo_11_bits_way, input  logic io_msInfo_11_bits_blockRefill, input  logic io_msInfo_11_bits_dirHit,
  input  logic        io_msInfo_12_valid, input  logic [8:0] io_msInfo_12_bits_set, input  logic [2:0] io_msInfo_12_bits_way, input  logic io_msInfo_12_bits_blockRefill, input  logic io_msInfo_12_bits_dirHit,
  input  logic        io_msInfo_13_valid, input  logic [8:0] io_msInfo_13_bits_set, input  logic [2:0] io_msInfo_13_bits_way, input  logic io_msInfo_13_bits_blockRefill, input  logic io_msInfo_13_bits_dirHit,
  input  logic        io_msInfo_14_valid, input  logic [8:0] io_msInfo_14_bits_set, input  logic [2:0] io_msInfo_14_bits_way, input  logic io_msInfo_14_bits_blockRefill, input  logic io_msInfo_14_bits_dirHit,
  input  logic        io_msInfo_15_valid, input  logic [8:0] io_msInfo_15_bits_set, input  logic [2:0] io_msInfo_15_bits_way, input  logic io_msInfo_15_bits_blockRefill, input  logic io_msInfo_15_bits_dirHit,

  // ---- 与 SRAM 黑盒对接: 读数据输入 ----
  input  logic [37:0] i_tagRead_0, i_tagRead_1, i_tagRead_2, i_tagRead_3,
  input  logic [37:0] i_tagRead_4, i_tagRead_5, i_tagRead_6, i_tagRead_7,
  input  meta_entry_t i_metaRead_0, i_metaRead_1, i_metaRead_2, i_metaRead_3,
  input  meta_entry_t i_metaRead_4, i_metaRead_5, i_metaRead_6, i_metaRead_7,
  input  logic [15:0] i_replRead,
  input  logic        i_originRead_0, i_originRead_1, i_originRead_2, i_originRead_3,
  input  logic        i_originRead_4, i_originRead_5, i_originRead_6, i_originRead_7,

  // ---- 与 SRAM 黑盒对接: 读使能 + 写控制输出 ----
  output logic        o_ren,           // 四块 SRAM 共用读使能 (= read.fire)
  output logic [37:0] o_tagWdata,      // tagArray 写数据 (ECC 编码后)
  output logic        o_replWen,       // replacer & origin 共用写使能
  output logic [8:0]  o_replWset,      // replacer & origin 共用写地址
  output logic [15:0] o_replWdata,     // replacer 写数据
  output logic        o_originWdata,   // origin_bit 写数据 (按 way 广播)
  output logic [7:0]  o_originWaymask  // origin_bit 写 waymask (1<<way_s3)
);

  // ===========================================================================
  //  纯组合辅助函数 (只用入参, 不读模块信号 —— 避免 generate 捕获陷阱)
  // ===========================================================================
  // one-hot → 路号 (8 路标准编码; one-hot 假设下与 golden OHToUInt 一致)
  function automatic logic [2:0] oh_to_way(input logic [7:0] oh);
    oh_to_way[0] = oh[1] | oh[3] | oh[5] | oh[7];
    oh_to_way[1] = oh[2] | oh[3] | oh[6] | oh[7];
    oh_to_way[2] = oh[4] | oh[5] | oh[6] | oh[7];
  endfunction

  // 优先级编码: 取最低置位 bit 号; 全 0 / 仅 bit7 → 返回 7 (与 golden 默认一致)
  function automatic logic [2:0] prio_way(input logic [7:0] v);
    prio_way = v[0] ? 3'd0 : v[1] ? 3'd1 : v[2] ? 3'd2 : v[3] ? 3'd3 :
               v[4] ? 3'd4 : v[5] ? 3'd5 : v[6] ? 3'd6 : 3'd7;
  endfunction

  // Tag SECDED 编码: 31-bit tag → 38-bit (6 Hamming 校验 + 1 总奇偶)
  function automatic logic [37:0] tag_ecc_encode(input logic [30:0] wtag);
    logic [5:0] syn;
    logic       par;
    syn[0] = ^(wtag & 31'h56AAAD5B);
    syn[1] = ^(wtag & 31'h1B33366D);
    syn[2] = ^(wtag & 31'h63C3C78E);
    syn[3] = ^(wtag & 31'h03FC07F0);
    syn[4] = ^(wtag & 31'h03FFF800);
    syn[5] = ^(wtag & 31'h7C000000);
    par    = ^{syn, wtag};                 // 全部校验位 + 数据位的总奇偶
    tag_ecc_encode = {par, syn, wtag};     // [37]=par, [36:31]=syn, [30:0]=wtag
  endfunction

  // Tag SECDED 解码错误: 总奇偶非零(单错) 或 (奇偶为零但综合征非零, 双错)
  function automatic logic tag_ecc_error(input logic [37:0] x);
    logic [5:0] s;
    s[5] = ^(x[36:26] & 11'h41F);
    s[4] = ^(x[35:11] & 25'h1007FFF);
    s[3] = ^(x[34:4]  & 31'h403FC07F);
    s[2] = ^(x[33:1]  & 33'h131E1E3C7);
    s[1] = ^(x[32:0]  & 33'h11B33366D);
    s[0] = ^(x[31:0]  & 32'hD6AAAD5B);
    tag_ecc_error = (^x) | (~(^x) & (|s));
  endfunction

  // ===========================================================================
  //  复位扫描 (上电把 replacer/origin SRAM 逐 set 清成初值)
  // ===========================================================================
  logic       resetFinish;
  logic [8:0] resetIdx;

  // ===========================================================================
  //  流水寄存器
  // ===========================================================================
  logic        reqValid_s2, reqValid_s3;
  logic        refillReqValid_s2, refillReqValid_s3;

  // req_s2 / req_s3: 把 io.read.bits 沿流水打拍
  logic [30:0] req_s2_tag,  req_s3_tag;
  logic [8:0]  req_s2_set,  req_s3_set;
  logic [7:0]  req_s2_wayMask, req_s3_wayMask;
  logic [2:0]  req_s2_replacerInfo_channel, req_s3_replacerInfo_channel;
  logic [2:0]  req_s2_replacerInfo_opcode,  req_s3_replacerInfo_opcode;
  logic [4:0]  req_s2_replacerInfo_reqSource, req_s3_replacerInfo_reqSource;
  logic        req_s2_replacerInfo_refill_prefetch, req_s3_replacerInfo_refill_prefetch;
  logic        req_s2_refill, req_s3_refill;
  logic [7:0]  req_s2_mshrId, req_s3_mshrId;
  logic        req_s2_cmoAll, req_s3_cmoAll;
  logic [2:0]  req_s2_cmoWay, req_s3_cmoWay;

  // stage3 锁存的 8 路 meta/tag/error 与 replacer 状态
  meta_entry_t metaAll_s3 [WAYS];
  logic [30:0] tagAll_s3  [WAYS];
  logic        errorAll_s3[WAYS];
  logic [15:0] repl_state_s3;

  // origin-bit 的 HoldUnless: REG=RegNext(read.fire); r=RegEnable(originRead, REG)
  logic        REG;
  logic        r_hold [WAYS];

  // refill 时空闲 way 掩码 (上一拍算的 ~占用掩码)
  logic [7:0]  freeWayMask_s3;

  // DRRIP set-dueling 计数器
  logic [9:0]  PSEL;

  // ===========================================================================
  //  stage1: 读使能 / ready
  // ===========================================================================
  logic replacerWen;
  assign io_read_ready = ~io_metaWReq_valid & ~io_tagWReq_valid & ~replacerWen;
  assign o_ren         = io_read_ready & io_read_valid;       // io.read.fire

  // tagArray 写数据 = ECC 编码
  assign o_tagWdata = tag_ecc_encode(io_tagWReq_bits_wtag);

  // ===========================================================================
  //  stage3 组合: 命中 / 受害路 / DRRIP
  // ===========================================================================
  logic [7:0] hitVec, invalidVec;
  logic       hit_s3, has_invalid_way;
  logic [2:0] hitWay, invalidWay, replaceWay, chosenWay, finalWay, way_s3;

  always_comb begin
    for (int w = 0; w < WAYS; w++) begin
      hitVec[w]     = (tagAll_s3[w] == req_s3_tag) & (metaAll_s3[w].state != 2'h0);
      invalidVec[w] = (metaAll_s3[w].state == 2'h0);
    end
  end
  assign hit_s3          = (|hitVec) | req_s3_cmoAll;
  assign has_invalid_way = |invalidVec;
  assign hitWay          = oh_to_way(hitVec);
  assign invalidWay      = prio_way(invalidVec);

  // DRRIP get_replace_way: 选 RRPV 最大的路 (并列取最低 way 号)
  logic [1:0] rrpv [WAYS];
  logic [7:0] isMaxRRPV;
  always_comb begin
    for (int w = 0; w < WAYS; w++) rrpv[w] = repl_state_s3[2*w +: 2];
    for (int i = 0; i < WAYS; i++) begin
      logic noLarger;
      noLarger = 1'b1;
      for (int j = 0; j < WAYS; j++)
        if (rrpv[j] > rrpv[i]) noLarger = 1'b0;
      isMaxRRPV[i] = noLarger;   // 第 i 路 RRPV 为最大
    end
  end
  assign replaceWay = prio_way(isMaxRRPV);

  // 有空闲路则选最低空闲路, 否则用 DRRIP 选出的 replaceWay
  assign chosenWay = has_invalid_way ? invalidWay : replaceWay;
  // refill 选路: chosenWay 若在 freeWayMask 内就用它, 否则取最低空闲位
  assign finalWay  = freeWayMask_s3[chosenWay] ? chosenWay : prio_way(freeWayMask_s3);
  // 最终 way: cmoAll 强制用 cmoWay; 命中用 hitWay; 否则受害路 finalWay
  assign way_s3    = req_s3_cmoAll ? req_s3_cmoWay : (hit_s3 ? hitWay : finalWay);

  logic refillRetry;
  assign refillRetry = ~(|freeWayMask_s3);

  // ===========================================================================
  //  io.resp / io.replResp 输出 (stage3)
  // ===========================================================================
  meta_entry_t respMeta, replMeta;
  assign respMeta = metaAll_s3[way_s3];
  assign replMeta = metaAll_s3[finalWay];

  assign io_resp_valid                 = reqValid_s3;
  assign io_resp_bits_hit              = hit_s3;
  assign io_resp_bits_tag              = tagAll_s3[way_s3];
  assign io_resp_bits_set              = req_s3_set;
  assign io_resp_bits_way              = way_s3;
  assign io_resp_bits_meta_dirty       = respMeta.dirty;
  assign io_resp_bits_meta_state       = respMeta.state;
  assign io_resp_bits_meta_clients     = respMeta.clients;
  assign io_resp_bits_meta_alias       = respMeta.alias_bits;
  assign io_resp_bits_meta_prefetch    = respMeta.prefetch;
  assign io_resp_bits_meta_prefetchSrc = respMeta.prefetchSrc;
  assign io_resp_bits_meta_accessed    = respMeta.accessed;
  assign io_resp_bits_meta_tagErr      = respMeta.tagErr;
  assign io_resp_bits_meta_dataErr     = respMeta.dataErr;
  // error: ECC 检出 且 本拍有效 且 非 cmoAll 且该路非 INVALID
  assign io_resp_bits_error =
      errorAll_s3[way_s3] & reqValid_s3 & ~req_s3_cmoAll & (respMeta.state != 2'h0);
  assign io_resp_bits_replacerInfo_channel        = req_s3_replacerInfo_channel;
  assign io_resp_bits_replacerInfo_opcode         = req_s3_replacerInfo_opcode;
  assign io_resp_bits_replacerInfo_reqSource      = req_s3_replacerInfo_reqSource;
  assign io_resp_bits_replacerInfo_refill_prefetch = req_s3_replacerInfo_refill_prefetch;

  assign io_replResp_valid             = refillReqValid_s3;
  assign io_replResp_bits_tag          = tagAll_s3[finalWay];
  assign io_replResp_bits_set          = req_s3_set;
  assign io_replResp_bits_way          = finalWay;
  assign io_replResp_bits_meta_dirty       = replMeta.dirty;
  assign io_replResp_bits_meta_state       = replMeta.state;
  assign io_replResp_bits_meta_clients     = replMeta.clients;
  assign io_replResp_bits_meta_alias       = replMeta.alias_bits;
  assign io_replResp_bits_meta_prefetch    = replMeta.prefetch;
  assign io_replResp_bits_meta_prefetchSrc = replMeta.prefetchSrc;
  assign io_replResp_bits_meta_accessed    = replMeta.accessed;
  assign io_replResp_bits_meta_tagErr      = replMeta.tagErr;
  assign io_replResp_bits_meta_dataErr     = replMeta.dataErr;
  assign io_replResp_bits_mshrId       = req_s3_mshrId;
  assign io_replResp_bits_retry        = refillRetry;

  // ===========================================================================
  //  替换状态更新使能 (PLRU/RRIP: A-命中 或 C-命中 或 refill 时更新)
  // ===========================================================================
  logic ch0_update, ch2_update, updateHit, updateRefill;
  // channel(0): AcquireBlock(6)/AcquirePerm(7)/Hint(5) 命中时更新
  assign ch0_update = req_s3_replacerInfo_channel[0] &
      ((&req_s3_replacerInfo_opcode) | (req_s3_replacerInfo_opcode == 3'h6) | (req_s3_replacerInfo_opcode == 3'h5));
  // channel(2): Release(6)/ReleaseData(7) 命中时更新
  assign ch2_update = req_s3_replacerInfo_channel[2] &
      ((req_s3_replacerInfo_opcode == 3'h6) | (&req_s3_replacerInfo_opcode));
  assign updateHit    = reqValid_s3 & hit_s3 & (ch0_update | ch2_update);
  assign updateRefill = refillReqValid_s3 & (|freeWayMask_s3);
  assign replacerWen  = updateHit | updateRefill;

  // ===========================================================================
  //  DRRIP next_state 计算 (set-dueling 选 SRRIP/BRRIP)
  // ===========================================================================
  // origin-bit HoldUnless: REG ? originRead : r_hold
  logic [7:0] originHold;
  always_comb begin
    originHold[0] = REG ? i_originRead_0 : r_hold[0];
    originHold[1] = REG ? i_originRead_1 : r_hold[1];
    originHold[2] = REG ? i_originRead_2 : r_hold[2];
    originHold[3] = REG ? i_originRead_3 : r_hold[3];
    originHold[4] = REG ? i_originRead_4 : r_hold[4];
    originHold[5] = REG ? i_originRead_5 : r_hold[5];
    originHold[6] = REG ? i_originRead_6 : r_hold[6];
    originHold[7] = REG ? i_originRead_7 : r_hold[7];
  end

  // rrip_req_type[3]=reuse(origin), [2]=release(channel2), [1]=prefetch, [0]=refill
  logic       rrip_prefetch;
  logic [3:0] rrip_req_type;
  assign rrip_prefetch =
      (~refillReqValid_s3 & req_s3_replacerInfo_channel[0] & (req_s3_replacerInfo_opcode == 3'h5)) |
      (req_s3_replacerInfo_channel[2] & metaAll_s3[way_s3].prefetch) |
      (refillReqValid_s3 & req_s3_replacerInfo_refill_prefetch);
  assign rrip_req_type = {originHold[way_s3], req_s3_replacerInfo_channel[2], rrip_prefetch, req_s3_refill};

  // set-dueling: match_a→监控集 SRRIP, match_b→监控集 BRRIP, 其余看 PSEL[9]
  logic match_a, match_b, chosen_brrip;
  assign match_a = (req_s3_set[8:4] == req_s3_set[4:0]);
  assign match_b = (req_s3_set[8:4] == ~req_s3_set[4:0]);
  assign chosen_brrip = ~match_a & (match_b | PSEL[9]);   // 1: BRRIP, 0: SRRIP

  // get_next_state: 命中提升 RRPV→0; 插入 SRRIP=2/BRRIP=3; 其余路按需老化
  logic [1:0] insert_val, increment;
  logic [2:0] req3;
  logic       otherKeep;
  assign insert_val = chosen_brrip ? 2'h3 : 2'h2;
  assign increment  = 2'h3 - rrpv[way_s3];
  assign req3       = rrip_req_type[2:0];
  assign otherKeep  = hit_s3 | has_invalid_way;   // 命中或有空闲路时其它路不老化

  logic [1:0] nextRRPV [WAYS];
  logic [15:0] next_state_s3;
  always_comb begin
    for (int w = 0; w < WAYS; w++) begin
      if (w == way_s3) begin
        // touch way
        if (((req3 == 3'h0) & hit_s3) | (req3 == 3'h1) | (rrip_req_type == 4'hC))
          nextRRPV[w] = 2'h0;                 // 命中/复用 → 最近被引用
        else if (req3 == 3'h3)
          nextRRPV[w] = 2'h1;                 // 预取 refill
        else if ((rrip_req_type == 4'h4) | (req3 == 3'h6))
          nextRRPV[w] = insert_val;           // miss 插入 (SRRIP=2/BRRIP=3)
        else
          nextRRPV[w] = rrpv[w];
      end else begin
        nextRRPV[w] = otherKeep ? rrpv[w] : (rrpv[w] + increment);
      end
    end
    for (int w = 0; w < WAYS; w++) next_state_s3[2*w +: 2] = nextRRPV[w];
  end

  // ===========================================================================
  //  replacer / origin SRAM 写控制输出
  // ===========================================================================
  assign o_replWen      = ~resetFinish | replacerWen;
  assign o_replWset     = resetFinish ? req_s3_set : resetIdx;
  // 复位期写入 RRPV 初值 2 (16'hAAAA = 8 路各 2'b10), 正常期写 next_state
  assign o_replWdata    = resetFinish ? next_state_s3 : 16'hAAAA;
  assign o_originWdata  = resetFinish & hit_s3;           // 复位期写 0
  assign o_originWaymask = 8'h1 << way_s3;

  // ===========================================================================
  //  refill 占用 way 掩码 (stage2 算, 给 stage3 用)
  // ===========================================================================
  logic [7:0] occWayMask_s2;
  // 注意: set 比较的目标 req_s2_set 显式作参数传入 (不在函数内捕获模块信号)
  function automatic logic [7:0] occ_of(input logic [8:0] cmpset, input logic v, input logic [8:0] s,
                                        input logic [2:0] way, input logic br, input logic dh);
    occ_of = (v & (s == cmpset) & (br | dh)) ? (8'h1 << way) : 8'h0;
  endfunction
  assign occWayMask_s2 =
      occ_of(req_s2_set, io_msInfo_0_valid,  io_msInfo_0_bits_set,  io_msInfo_0_bits_way,  io_msInfo_0_bits_blockRefill,  io_msInfo_0_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_1_valid,  io_msInfo_1_bits_set,  io_msInfo_1_bits_way,  io_msInfo_1_bits_blockRefill,  io_msInfo_1_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_2_valid,  io_msInfo_2_bits_set,  io_msInfo_2_bits_way,  io_msInfo_2_bits_blockRefill,  io_msInfo_2_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_3_valid,  io_msInfo_3_bits_set,  io_msInfo_3_bits_way,  io_msInfo_3_bits_blockRefill,  io_msInfo_3_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_4_valid,  io_msInfo_4_bits_set,  io_msInfo_4_bits_way,  io_msInfo_4_bits_blockRefill,  io_msInfo_4_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_5_valid,  io_msInfo_5_bits_set,  io_msInfo_5_bits_way,  io_msInfo_5_bits_blockRefill,  io_msInfo_5_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_6_valid,  io_msInfo_6_bits_set,  io_msInfo_6_bits_way,  io_msInfo_6_bits_blockRefill,  io_msInfo_6_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_7_valid,  io_msInfo_7_bits_set,  io_msInfo_7_bits_way,  io_msInfo_7_bits_blockRefill,  io_msInfo_7_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_8_valid,  io_msInfo_8_bits_set,  io_msInfo_8_bits_way,  io_msInfo_8_bits_blockRefill,  io_msInfo_8_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_9_valid,  io_msInfo_9_bits_set,  io_msInfo_9_bits_way,  io_msInfo_9_bits_blockRefill,  io_msInfo_9_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_10_valid, io_msInfo_10_bits_set, io_msInfo_10_bits_way, io_msInfo_10_bits_blockRefill, io_msInfo_10_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_11_valid, io_msInfo_11_bits_set, io_msInfo_11_bits_way, io_msInfo_11_bits_blockRefill, io_msInfo_11_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_12_valid, io_msInfo_12_bits_set, io_msInfo_12_bits_way, io_msInfo_12_bits_blockRefill, io_msInfo_12_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_13_valid, io_msInfo_13_bits_set, io_msInfo_13_bits_way, io_msInfo_13_bits_blockRefill, io_msInfo_13_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_14_valid, io_msInfo_14_bits_set, io_msInfo_14_bits_way, io_msInfo_14_bits_blockRefill, io_msInfo_14_bits_dirHit) |
      occ_of(req_s2_set, io_msInfo_15_valid, io_msInfo_15_bits_set, io_msInfo_15_bits_way, io_msInfo_15_bits_blockRefill, io_msInfo_15_bits_dirHit);

  // SRAM 读数据打包 (i_metaRead_* / i_tagRead_* / i_originRead_* → 数组, stage2 锁存用)
  meta_entry_t metaRead [WAYS];
  logic [37:0] tagRead  [WAYS];
  logic        originRead [WAYS];
  always_comb begin
    metaRead[0]=i_metaRead_0; metaRead[1]=i_metaRead_1; metaRead[2]=i_metaRead_2; metaRead[3]=i_metaRead_3;
    metaRead[4]=i_metaRead_4; metaRead[5]=i_metaRead_5; metaRead[6]=i_metaRead_6; metaRead[7]=i_metaRead_7;
    tagRead[0]=i_tagRead_0; tagRead[1]=i_tagRead_1; tagRead[2]=i_tagRead_2; tagRead[3]=i_tagRead_3;
    tagRead[4]=i_tagRead_4; tagRead[5]=i_tagRead_5; tagRead[6]=i_tagRead_6; tagRead[7]=i_tagRead_7;
    originRead[0]=i_originRead_0; originRead[1]=i_originRead_1; originRead[2]=i_originRead_2; originRead[3]=i_originRead_3;
    originRead[4]=i_originRead_4; originRead[5]=i_originRead_5; originRead[6]=i_originRead_6; originRead[7]=i_originRead_7;
  end

  // ===========================================================================
  //  时序逻辑
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      resetFinish <= 1'b0;
      resetIdx    <= 9'h1FF;           // sets-1 = 511
      reqValid_s2 <= 1'b0;  reqValid_s3 <= 1'b0;
      refillReqValid_s2 <= 1'b0;  refillReqValid_s3 <= 1'b0;
      req_s2_tag <= '0; req_s2_set <= '0; req_s2_wayMask <= '0;
      req_s2_replacerInfo_channel <= '0; req_s2_replacerInfo_opcode <= '0;
      req_s2_replacerInfo_reqSource <= '0; req_s2_replacerInfo_refill_prefetch <= 1'b0;
      req_s2_refill <= 1'b0; req_s2_mshrId <= '0; req_s2_cmoAll <= 1'b0; req_s2_cmoWay <= '0;
      req_s3_tag <= '0; req_s3_set <= '0; req_s3_wayMask <= '0;
      req_s3_replacerInfo_channel <= '0; req_s3_replacerInfo_opcode <= '0;
      req_s3_replacerInfo_reqSource <= '0; req_s3_replacerInfo_refill_prefetch <= 1'b0;
      req_s3_refill <= 1'b0; req_s3_mshrId <= '0; req_s3_cmoAll <= 1'b0; req_s3_cmoWay <= '0;
      for (int w = 0; w < WAYS; w++) begin
        metaAll_s3[w] <= '0; tagAll_s3[w] <= '0; errorAll_s3[w] <= 1'b0; r_hold[w] <= 1'b0;
      end
      repl_state_s3 <= '0;
      REG <= 1'b0;
      PSEL <= 10'h200;                 // 512, 10-bit PSEL 中值
    end else begin
      // 复位扫描推进
      resetFinish <= (resetIdx == 9'h0) | resetFinish;
      if (!resetFinish) resetIdx <= resetIdx - 9'h1;

      // stage1→2 valid
      reqValid_s2 <= o_ren;
      reqValid_s3 <= reqValid_s2;
      refillReqValid_s2 <= o_ren & io_read_bits_refill;
      refillReqValid_s3 <= refillReqValid_s2;

      // req_s2 = RegEnable(io.read.bits, read.fire)
      if (o_ren) begin
        req_s2_tag <= io_read_bits_tag;
        req_s2_set <= io_read_bits_set;
        req_s2_wayMask <= io_read_bits_wayMask;
        req_s2_replacerInfo_channel <= io_read_bits_replacerInfo_channel;
        req_s2_replacerInfo_opcode  <= io_read_bits_replacerInfo_opcode;
        req_s2_replacerInfo_reqSource <= io_read_bits_replacerInfo_reqSource;
        req_s2_replacerInfo_refill_prefetch <= io_read_bits_replacerInfo_refill_prefetch;
        req_s2_refill <= io_read_bits_refill;
        req_s2_mshrId <= io_read_bits_mshrId;
        req_s2_cmoAll <= io_read_bits_cmoAll;
        req_s2_cmoWay <= io_read_bits_cmoWay;
      end

      // req_s3 + meta/tag/error/repl 锁存 = RegEnable(_, reqValid_s2)
      if (reqValid_s2) begin
        req_s3_tag <= req_s2_tag;
        req_s3_set <= req_s2_set;
        req_s3_wayMask <= req_s2_wayMask;
        req_s3_replacerInfo_channel <= req_s2_replacerInfo_channel;
        req_s3_replacerInfo_opcode  <= req_s2_replacerInfo_opcode;
        req_s3_replacerInfo_reqSource <= req_s2_replacerInfo_reqSource;
        req_s3_replacerInfo_refill_prefetch <= req_s2_replacerInfo_refill_prefetch;
        req_s3_refill <= req_s2_refill;
        req_s3_mshrId <= req_s2_mshrId;
        req_s3_cmoAll <= req_s2_cmoAll;
        req_s3_cmoWay <= req_s2_cmoWay;
        for (int w = 0; w < WAYS; w++) begin
          metaAll_s3[w]  <= metaRead[w];
          tagAll_s3[w]   <= tagRead[w][30:0];
          errorAll_s3[w] <= tag_ecc_error(tagRead[w]);
        end
        repl_state_s3 <= i_replRead;
      end

      // origin-bit HoldUnless 寄存器
      REG <= o_ren;
      if (REG) begin
        for (int w = 0; w < WAYS; w++) r_hold[w] <= originRead[w];
      end

      // PSEL set-dueling 更新 (refill miss 时, 监控集 a/b 反向调整)
      if (refillReqValid_s3 & match_a & ~hit_s3 & (PSEL != 10'h3FF))
        PSEL <= PSEL + 10'h1;
      else if (refillReqValid_s3 & match_b & ~hit_s3 & (|PSEL))
        PSEL <= PSEL - 10'h1;
    end
  end

  // freeWayMask_s3 = RegEnable(~occWayMask_s2, refillReqValid_s2) —— 无复位
  always_ff @(posedge clock) begin
    if (refillReqValid_s2) freeWayMask_s3 <= ~occWayMask_s2;
  end

endmodule
