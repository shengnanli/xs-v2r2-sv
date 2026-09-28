// xs_Directory_core.sv —— L2 目录（tag + meta + DRRIP 替换）的三级流水查询核（Directory* 共用）
//
// 对照 coupledL2/src/main/scala/coupledL2/Directory.scala 与 utils/Replacer.scala（DRRIP）。
// 配置（KunminghuV2Config 每个 slice）：512 组 x 8 路；tag 31 位带 SECDED(31)=38 位；替换算法 drrip。
// Directory / Directory_1..3 是四个 slice 的单态化，逻辑完全相同，只差子模块是哪个单态化
// （由各自薄 wrapper 例化，scripts/gen_l2_directory.py 生成）。本核不含任何 SRAM，只接它们的读写口。
//
// 流水线（MainPipe 的 s1 发读，s3 拿结果）：
//   s1  io.read 握手（fire = valid && ready）：同拍向 tag / meta / 替换状态 / origin 位四块 SRAM 发读。
//       ready = 本拍没有 meta 写、没有 tag 写、没有替换状态写（单口 SRAM，写优先）。
//   s2  SRAM 出数据；锁存请求；refill 读在这一拍算"哪些路正被 MSHR 占着"（occWayMask）。
//   s3  锁存全部 8 路的 tag / meta / ECC 错误 / 替换状态，算：
//         命中（tag 相等且 meta 有效，且恰好一路命中）或 CMO 指定路；
//         未命中时的受害路：优先挑无效路，否则按 DRRIP 挑 RRPV 最大的路；若该路被占用，
//         改挑空闲路里编号最小的；所有路都被占 ⇒ replResp.retry。
//       并在 s3 按命中/回填更新 DRRIP 状态与 origin 位（写回 SRAM）。
//
// DRRIP（动态 RRIP，集合决斗）：
//   * 每组每路 2 位 RRPV（越大越"不会再被用"），替换时挑 RRPV 最大的那一路（多个取编号最小）。
//   * 两种插入策略：SRRIP（插入 RRPV=2）与 BRRIP（插入 RRPV=3）。组号 set[8:4]==set[4:0] 的是 SRRIP
//     专用监视组（match_a），set[8:4]==~set[4:0] 的是 BRRIP 专用监视组（match_b），其余组由 10 位
//     饱和计数器 PSEL 的最高位决定（0=SRRIP，1=BRRIP）。监视组里发生 refill 未命中时 PSEL 往对方偏。
//   * 被访问的路按请求类型 rrip_req_type = {复用位, 是释放, 是预取, 是回填} 设新 RRPV（见 §5 注释）；
//     其余路：命中或有无效路时不动，否则一起老化 +(3 - 被访问路旧 RRPV)。
//   * origin 位（每组每路 1 位）记"这一块是否被复用过"，命中写 1、回填写 0。
//
// 上电初始化：resetIdx 从 511 递减到 0，期间每拍把替换状态写成 0xAAAA（每路 RRPV=2）、origin 写 0；
// 初始化结束前读请求照样被接受（写优先的 ready 规则把读挡在写之后）。

// directory_pkg（MetaEntry 等类型/常量）在 rtl/uncore/uncore_common_pkg.sv：Directory / Directory_1..3 的 wrapper 与本核共用。

module xs_Directory_core
  import directory_pkg::*;
(
  input  logic               clock,
  input  logic               reset,

  // ---- 查询请求（MainPipe s1）----
  input  logic               read_valid,
  output logic               read_ready,
  input  logic [TAG_W-1:0]   read_tag,
  input  logic [8:0]         read_set,
  input  logic [7:0]         read_wayMask,
  input  logic [2:0]         read_channel,
  input  logic [2:0]         read_opcode,
  input  logic [4:0]         read_reqSource,
  input  logic               read_refill_prefetch,
  input  logic               read_refill,
  input  logic [7:0]         read_mshrId,
  input  logic               read_cmoAll,
  input  logic [2:0]         read_cmoWay,

  // ---- 写请求（只用来决定 read_ready；写数据由 wrapper 直接送 SRAM）----
  input  logic               metaWReq_valid,
  input  logic               tagWReq_valid,
  input  logic [2:0]         tagWReq_way,
  input  logic [TAG_W-1:0]   tagWReq_wtag,

  // ---- 16 个 MSHR 的状态（只用到判"占用路"的几个字段）----
  input  logic               ms_valid       [N_MSHR],
  input  logic [8:0]         ms_set         [N_MSHR],
  input  logic [2:0]         ms_way         [N_MSHR],
  input  logic               ms_blockRefill [N_MSHR],
  input  logic               ms_dirHit      [N_MSHR],

  // ---- 查询结果（s3）----
  output logic               resp_valid,
  output logic               resp_hit,
  output logic [TAG_W-1:0]   resp_tag,
  output logic [8:0]         resp_set,
  output logic [2:0]         resp_way,
  output meta_t              resp_meta,
  output logic               resp_error,
  output logic [2:0]         resp_channel,
  output logic [2:0]         resp_opcode,
  output logic [4:0]         resp_reqSource,
  output logic               resp_refill_prefetch,

  // ---- 替换结果（refill 读的 s3）----
  output logic               replResp_valid,
  output logic [TAG_W-1:0]   replResp_tag,
  output logic [8:0]         replResp_set,
  output logic [2:0]         replResp_way,
  output meta_t              replResp_meta,
  output logic [7:0]         replResp_mshrId,
  output logic               replResp_retry,
  output logic               replResp_error,

  // ---- 四块 SRAM 的读口（读地址 = read_set，由 wrapper 直连）----
  output logic               arrReadFire,
  input  logic [ENC_W-1:0]   tagRead    [WAYS],
  input  meta_t              metaRead   [WAYS],
  input  logic [2*WAYS-1:0]  replRead,
  input  logic               originRead [WAYS],

  // ---- SRAM 写口 ----
  output logic [ENC_W-1:0]   tagWriteData,        // 已编码的 tag，8 路同一份
  output logic [WAYS-1:0]    tagWriteWayMask,
  output logic               stateWriteValid,     // 替换状态 / origin 位共用
  output logic [8:0]         stateWriteSet,
  output logic [2*WAYS-1:0]  replWriteData,
  output logic               originWriteData,     // 8 路同一份
  output logic [WAYS-1:0]    originWriteWayMask
);

  // ===========================================================================
  // §0 SECDED(31)：与 DataStorage 同一套 Parity(SEC(x))，校验矩阵 elaborate 期由定义算出
  // ===========================================================================
  localparam int unsigned SEC_W = ENC_W - 1;      // 37
  localparam int unsigned CHK_W = SEC_W - TAG_W;  // 6

  function automatic int unsigned clog2_int(input int unsigned v);
    int unsigned r;
    r = 0;
    while ((1 << r) < v) r++;
    return r;
  endfunction

  function automatic logic [SEC_W-1:0] syndrome_mask(input int unsigned j);
    logic [SEC_W-1:0] mask;
    int unsigned sys;
    mask = '0;
    for (int unsigned h = 1; h <= SEC_W; h++) begin
      if ((h & (h - 1)) == 0) sys = TAG_W + clog2_int(h);
      else                    sys = h - 1 - clog2_int(h);
      if ((h >> j) & 1) mask[sys] = 1'b1;
    end
    return mask;
  endfunction

  function automatic logic [ENC_W-1:0] secded_encode(input logic [TAG_W-1:0] x);
    logic [CHK_W-1:0] chk;
    logic [SEC_W-1:0] secWord;
    for (int unsigned j = 0; j < CHK_W; j++)
      chk[j] = ^(syndrome_mask(j) & {{CHK_W{1'b0}}, x});
    secWord = {chk, x};
    return {^secWord, secWord};
  endfunction

  function automatic logic secded_error(input logic [ENC_W-1:0] y);
    logic             parityErr;
    logic [CHK_W-1:0] syn;
    parityErr = ^y;
    for (int unsigned j = 0; j < CHK_W; j++)
      syn[j] = ^(syndrome_mask(j) & y[SEC_W-1:0]);
    return parityErr | (~parityErr & (|syn));
  endfunction

  // ===========================================================================
  // §1 s1：读握手与写数据
  // ===========================================================================
  logic replacerWen;          // s3 要写替换状态（见 §6），与读抢单口 SRAM
  logic readFire;

  assign read_ready  = ~metaWReq_valid & ~tagWReq_valid & ~replacerWen;
  assign readFire    = read_ready & read_valid;
  assign arrReadFire = readFire;

  assign tagWriteData    = secded_encode(tagWReq_wtag);
  assign tagWriteWayMask = WAYS'(1) << tagWReq_way;

  // ===========================================================================
  // §2 s2 / s3 请求流水寄存器（全部异步复位清 0）
  // ===========================================================================
  logic               reqValid_s2, reqValid_s3;
  logic               refillReqValid_s2, refillReqValid_s3;
  logic [TAG_W-1:0]   req_s2_tag,     req_s3_tag;
  logic [8:0]         req_s2_set,     req_s3_set;
  logic [7:0]         req_s2_wayMask, req_s3_wayMask;   // 目前不参与选路（Scala 里 TODO），照存
  logic [2:0]         req_s2_channel, req_s3_channel;
  logic [2:0]         req_s2_opcode,  req_s3_opcode;
  logic [4:0]         req_s2_reqSource, req_s3_reqSource;
  logic               req_s2_refill_prefetch, req_s3_refill_prefetch;
  logic               req_s2_refill,  req_s3_refill;
  logic [7:0]         req_s2_mshrId,  req_s3_mshrId;
  logic               req_s2_cmoAll,  req_s3_cmoAll;
  logic [2:0]         req_s2_cmoWay,  req_s3_cmoWay;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      reqValid_s2 <= 1'b0;  reqValid_s3 <= 1'b0;
      refillReqValid_s2 <= 1'b0;  refillReqValid_s3 <= 1'b0;
      req_s2_tag <= '0;  req_s2_set <= '0;  req_s2_wayMask <= '0;
      req_s2_channel <= '0;  req_s2_opcode <= '0;  req_s2_reqSource <= '0;
      req_s2_refill_prefetch <= 1'b0;  req_s2_refill <= 1'b0;  req_s2_mshrId <= '0;
      req_s2_cmoAll <= 1'b0;  req_s2_cmoWay <= '0;
      req_s3_tag <= '0;  req_s3_set <= '0;  req_s3_wayMask <= '0;
      req_s3_channel <= '0;  req_s3_opcode <= '0;  req_s3_reqSource <= '0;
      req_s3_refill_prefetch <= 1'b0;  req_s3_refill <= 1'b0;  req_s3_mshrId <= '0;
      req_s3_cmoAll <= 1'b0;  req_s3_cmoWay <= '0;
    end else begin
      reqValid_s2       <= readFire;
      reqValid_s3       <= reqValid_s2;
      refillReqValid_s2 <= readFire & read_refill;
      refillReqValid_s3 <= refillReqValid_s2;
      if (readFire) begin
        req_s2_tag <= read_tag;  req_s2_set <= read_set;  req_s2_wayMask <= read_wayMask;
        req_s2_channel <= read_channel;  req_s2_opcode <= read_opcode;
        req_s2_reqSource <= read_reqSource;  req_s2_refill_prefetch <= read_refill_prefetch;
        req_s2_refill <= read_refill;  req_s2_mshrId <= read_mshrId;
        req_s2_cmoAll <= read_cmoAll;  req_s2_cmoWay <= read_cmoWay;
      end
      if (reqValid_s2) begin
        req_s3_tag <= req_s2_tag;  req_s3_set <= req_s2_set;  req_s3_wayMask <= req_s2_wayMask;
        req_s3_channel <= req_s2_channel;  req_s3_opcode <= req_s2_opcode;
        req_s3_reqSource <= req_s2_reqSource;  req_s3_refill_prefetch <= req_s2_refill_prefetch;
        req_s3_refill <= req_s2_refill;  req_s3_mshrId <= req_s2_mshrId;
        req_s3_cmoAll <= req_s2_cmoAll;  req_s3_cmoWay <= req_s2_cmoWay;
      end
    end
  end

  // ===========================================================================
  // §3 s2 -> s3：锁存 8 路 SRAM 读出（per-field 数组）与占用路掩码
  // ===========================================================================
  logic               metaAll_s3_dirty       [WAYS];
  logic [1:0]         metaAll_s3_state       [WAYS];
  logic               metaAll_s3_clients     [WAYS];
  logic [1:0]         metaAll_s3_alias       [WAYS];
  logic               metaAll_s3_prefetch    [WAYS];
  logic [2:0]         metaAll_s3_prefetchSrc [WAYS];
  logic               metaAll_s3_accessed    [WAYS];
  logic               metaAll_s3_tagErr      [WAYS];
  logic               metaAll_s3_dataErr     [WAYS];
  logic [TAG_W-1:0]   tagAll_s3              [WAYS];
  logic               errorAll_s3            [WAYS];   // 该路 tag 码字 ECC 出错
  logic [2*WAYS-1:0]  repl_state_s3;                   // 本组 8 路 RRPV
  logic [WAYS-1:0]    freeWayMask_s3;                  // 没被 MSHR 占着的路

  // refill 读在 s2 就比对 MSHR：同组、且（refill 数据还没写进 DS 或 目录命中）的那一路被占
  logic [WAYS-1:0] occWayMask_s2;
  always_comb begin
    occWayMask_s2 = '0;
    for (int i = 0; i < N_MSHR; i++)
      if (ms_valid[i] && ms_set[i] == req_s2_set && (ms_blockRefill[i] || ms_dirHit[i]))
        occWayMask_s2 |= WAYS'(1) << ms_way[i];
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int w = 0; w < WAYS; w++) begin
        metaAll_s3_dirty[w] <= 1'b0;  metaAll_s3_state[w] <= '0;  metaAll_s3_clients[w] <= 1'b0;
        metaAll_s3_alias[w] <= '0;  metaAll_s3_prefetch[w] <= 1'b0;  metaAll_s3_prefetchSrc[w] <= '0;
        metaAll_s3_accessed[w] <= 1'b0;  metaAll_s3_tagErr[w] <= 1'b0;  metaAll_s3_dataErr[w] <= 1'b0;
        tagAll_s3[w] <= '0;
        errorAll_s3[w] <= 1'b0;
      end
      repl_state_s3  <= '0;
      freeWayMask_s3 <= '0;
    end else begin
      if (reqValid_s2) begin
        for (int w = 0; w < WAYS; w++) begin
          metaAll_s3_dirty[w]       <= metaRead[w].dirty;
          metaAll_s3_state[w]       <= metaRead[w].state;
          metaAll_s3_clients[w]     <= metaRead[w].clients;
          metaAll_s3_alias[w]       <= metaRead[w].alias_;
          metaAll_s3_prefetch[w]    <= metaRead[w].prefetch;
          metaAll_s3_prefetchSrc[w] <= metaRead[w].prefetchSrc;
          metaAll_s3_accessed[w]    <= metaRead[w].accessed;
          metaAll_s3_tagErr[w]      <= metaRead[w].tagErr;
          metaAll_s3_dataErr[w]     <= metaRead[w].dataErr;
          tagAll_s3[w]              <= tagRead[w][TAG_W-1:0];
          errorAll_s3[w]            <= secded_error(tagRead[w]);
        end
        repl_state_s3 <= replRead;
      end
      if (refillReqValid_s2)
        freeWayMask_s3 <= ~occWayMask_s2;
    end
  end

  // ===========================================================================
  // §4 s3：命中判定与选路
  // ===========================================================================
  logic [WAYS-1:0] metaValid, hitVec, invalidVec, errorVec;
  logic [3:0]      hitCount;
  logic            multiHit, hasInvalid;
  logic [2:0]      hitWay, invalidWay, replaceWay, chosenWay, freeLowest, finalWay;
  logic            hit_s3;
  logic [2:0]      way_s3;
  logic [1:0]      rrpv [WAYS];

  always_comb begin
    for (int w = 0; w < WAYS; w++) begin
      metaValid[w]  = metaAll_s3_state[w] != INVALID;
      invalidVec[w] = ~metaValid[w];
      hitVec[w]     = tagAll_s3[w] == req_s3_tag && metaValid[w];
      errorVec[w]   = errorAll_s3[w] && metaValid[w];
      rrpv[w]       = repl_state_s3[2*w +: 2];
    end

    hitCount = '0;
    for (int w = 0; w < WAYS; w++) hitCount += 4'(hitVec[w]);
    multiHit = hitCount > 4'd1;

    // OHToUInt：命中路号 = 各命中路号按位或（正常只一路命中）
    hitWay = '0;
    for (int w = 0; w < WAYS; w++) if (hitVec[w]) hitWay |= 3'(w);

    // 无效路：编号最小的那一路
    hasInvalid = |invalidVec;
    invalidWay = '0;
    for (int w = WAYS - 1; w >= 0; w--) if (invalidVec[w]) invalidWay = 3'(w);

    // DRRIP 受害路：RRPV 最大的路里编号最小的（PriorityEncoder，全无时缺省 7）
    replaceWay = 3'd7;
    for (int w = WAYS - 1; w >= 0; w--) begin
      logic someoneLarger;
      someoneLarger = 1'b0;
      for (int j = 0; j < WAYS; j++) if (rrpv[j] > rrpv[w]) someoneLarger = 1'b1;
      if (!someoneLarger) replaceWay = 3'(w);
    end

    chosenWay = hasInvalid ? invalidWay : replaceWay;

    // 选中的路被 MSHR 占着 ⇒ 改挑空闲路里编号最小的（全占时 PriorityEncoder 缺省 7，靠 retry 兜底）
    freeLowest = 3'd7;
    for (int w = WAYS - 1; w >= 0; w--) if (freeWayMask_s3[w]) freeLowest = 3'(w);
    finalWay = freeWayMask_s3[chosenWay] ? chosenWay : freeLowest;

    // 命中：恰好一路命中；或 CMO 全扫时指定路有效
    hit_s3 = ((|hitVec) && !multiHit) || (req_s3_cmoAll && metaValid[req_s3_cmoWay]);
    way_s3 = req_s3_cmoAll ? req_s3_cmoWay : (hit_s3 ? hitWay : finalWay);
  end

  // tag ECC 错误：命中时看命中路（非 CMO、有效），未命中时任一有效路出错或多路命中都算
  logic error_s3;
  assign error_s3 = hit_s3 ? (errorAll_s3[way_s3] && reqValid_s3 && !req_s3_cmoAll && metaValid[way_s3])
                           : ((|errorVec) || multiHit);

  // ===========================================================================
  // §5 输出
  // ===========================================================================
  // 按路号取 meta（注意：不能写成读模块级数组的 function 再 assign —— 连续赋值只对实参敏感，
  // 数组内容变了不会重算，仿真与综合语义不一致；这里用 always_comb 直接索引）
  always_comb begin
    resp_meta     = '{metaAll_s3_dirty[way_s3], metaAll_s3_state[way_s3], metaAll_s3_clients[way_s3],
                      metaAll_s3_alias[way_s3], metaAll_s3_prefetch[way_s3], metaAll_s3_prefetchSrc[way_s3],
                      metaAll_s3_accessed[way_s3], metaAll_s3_tagErr[way_s3], metaAll_s3_dataErr[way_s3]};
    replResp_meta = '{metaAll_s3_dirty[finalWay], metaAll_s3_state[finalWay], metaAll_s3_clients[finalWay],
                      metaAll_s3_alias[finalWay], metaAll_s3_prefetch[finalWay], metaAll_s3_prefetchSrc[finalWay],
                      metaAll_s3_accessed[finalWay], metaAll_s3_tagErr[finalWay], metaAll_s3_dataErr[finalWay]};
  end

  assign resp_valid           = reqValid_s3;
  assign resp_hit             = hit_s3;
  assign resp_way             = way_s3;
  assign resp_tag             = tagAll_s3[way_s3];
  assign resp_set             = req_s3_set;
  assign resp_error           = error_s3;
  assign resp_channel         = req_s3_channel;
  assign resp_opcode          = req_s3_opcode;
  assign resp_reqSource       = req_s3_reqSource;
  assign resp_refill_prefetch = req_s3_refill_prefetch;

  assign replResp_valid  = refillReqValid_s3;
  assign replResp_way    = finalWay;
  assign replResp_tag    = tagAll_s3[finalWay];
  assign replResp_set    = req_s3_set;
  assign replResp_mshrId = req_s3_mshrId;
  assign replResp_retry  = ~(|freeWayMask_s3);
  assign replResp_error  = error_s3;

  // ===========================================================================
  // §6 替换状态更新（DRRIP）与 origin 位
  // ===========================================================================
  // 何时写：A 通道 AcquirePerm/AcquireBlock/Hint 命中、C 通道 Release/ReleaseData 命中，或 refill 未 retry
  logic updateHit, updateRefill;
  assign updateHit = reqValid_s3 && hit_s3 &&
                     ((req_s3_channel[0] && (req_s3_opcode == A_AcquirePerm || req_s3_opcode == A_AcquireBlock ||
                                             req_s3_opcode == A_Hint)) ||
                      (req_s3_channel[2] && (req_s3_opcode == C_Release || req_s3_opcode == C_ReleaseData)));
  assign updateRefill = refillReqValid_s3 && (|freeWayMask_s3);
  assign replacerWen  = updateHit || updateRefill;

  // origin 位读出：只在读后一拍有效，之后保持（HoldUnless）
  logic       originReadValid;          // RegNext(read.fire)
  logic       originHold [WAYS];        // 上一次读到的 origin 位
  logic [7:0] originBits;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      originReadValid <= 1'b0;
      for (int w = 0; w < WAYS; w++) originHold[w] <= 1'b0;
    end else begin
      originReadValid <= readFire;
      if (originReadValid)
        for (int w = 0; w < WAYS; w++) originHold[w] <= originRead[w];
    end
  end
  always_comb for (int w = 0; w < WAYS; w++) originBits[w] = originReadValid ? originRead[w] : originHold[w];

  // rrip_req_type = {复用过, 是 C 通道(释放), 是预取, 是回填}
  logic [3:0] rripReqType;
  assign rripReqType = {originBits[way_s3],
                        req_s3_channel[2],
                        (!refillReqValid_s3 && req_s3_channel[0] && req_s3_opcode == A_Hint) ||
                          (req_s3_channel[2] && metaAll_s3_prefetch[way_s3]) ||
                          (refillReqValid_s3 && req_s3_refill_prefetch),
                        req_s3_refill};

  // 集合决斗
  logic [9:0] PSEL;
  logic       match_a, match_b, useBRRIP;
  assign match_a  = req_s3_set[8:4] == req_s3_set[4:0];      // SRRIP 监视组
  assign match_b  = req_s3_set[8:4] == ~req_s3_set[4:0];     // BRRIP 监视组
  assign useBRRIP = match_a ? 1'b0 : (match_b ? 1'b1 : PSEL[9]);

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      PSEL <= 10'h200;
    else if (refillReqValid_s3 && match_a && !hit_s3 && PSEL != 10'h3FF)
      PSEL <= PSEL + 10'd1;          // SRRIP 监视组 miss：往 BRRIP 偏
    else if (refillReqValid_s3 && match_b && !hit_s3 && PSEL != 10'h000)
      PSEL <= PSEL - 10'd1;          // BRRIP 监视组 miss：往 SRRIP 偏
  end

  // 下一状态：被访问路按请求类型设 RRPV，其他路老化
  //   非预取命中 / 非预取回填 / 非预取的复用释放(1100) -> 0；预取回填(x011) -> 1；
  //   非预取的首次释放(0100) / 预取释放(x110) -> SRRIP 2，BRRIP 3；其余（预取命中等）不变
  logic [2*WAYS-1:0] next_state_s3;
  always_comb begin
    logic [1:0] increment;
    increment = 2'd3 - rrpv[way_s3];
    for (int w = 0; w < WAYS; w++) begin
      logic [1:0] nv;
      if (3'(w) == way_s3) begin
        if ((rripReqType[2:0] == 3'd0 && hit_s3) || rripReqType[2:0] == 3'd1 || rripReqType == 4'd12)
          nv = 2'd0;
        else if (rripReqType[2:0] == 3'd3)
          nv = 2'd1;
        else if (rripReqType == 4'd4 || rripReqType[2:0] == 3'd6)
          nv = useBRRIP ? 2'd3 : 2'd2;
        else
          nv = rrpv[w];
      end else begin
        nv = (hit_s3 || hasInvalid) ? rrpv[w] : 2'(rrpv[w] + increment);
      end
      next_state_s3[2*w +: 2] = nv;
    end
  end

  // 上电初始化计数器
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

  assign stateWriteValid    = !resetFinish || replacerWen;
  assign stateWriteSet      = resetFinish ? req_s3_set : resetIdx;
  assign replWriteData      = resetFinish ? next_state_s3 : 16'hAAAA;   // 初始化：每路 RRPV=2
  assign originWriteData    = resetFinish & hit_s3;
  assign originWriteWayMask = WAYS'(1) << way_s3;

endmodule
