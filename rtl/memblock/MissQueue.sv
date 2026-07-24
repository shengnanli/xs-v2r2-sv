// =============================================================================
//  MissQueue —— DCache 未命中处理队列（可读重写核 xs_MissQueue_core）
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel）：
//      src/main/scala/xiangshan/cache/dcache/mainpipe/MissQueue.scala（class MissQueue）
//  golden（firtool 生成，仅 UT/FM 对照）：golden/chisel-rtl/MissQueue.sv（8444 行）
//
//  类型/常量/纯函数集中在 missqueue_pkg（见 missqueue_pkg.sv 文件头的整体说明）。
//  本核重写「队列级」逻辑；每条 MSHR 的状态机封装在子模块 MissEntry 里（当 golden 黑盒，
//  UT/FM 两侧共用），CMO 状态机用 CMOUnit 黑盒，amo main_pipe_req 仲裁用 FastArbiter 黑盒。
//
//  队列级逻辑（对应 Scala class MissQueue body）分节如下，与下方 ===== 分节一一对应：
//    A. entry/cmo/arb 接口线聚合（用数组 + genvar 统一处理 16 条 MSHR）
//    B. 入队 s0 arbiter：alloc / merge / reject / accept；req_handled / resp
//    C. miss_req_pipe_reg（入队第二级流水）+ acquire_from_pipereg（pipereg 直发 acquire）
//    D. 4 路 queryMQ ready（与主请求同构的提前判定）
//    E. 每条 entry 例化（genvar）：primary_valid（最低空闲分配）、grant 路由、pipe_reg 注入、
//       l2_hint / mainpipe 信号按 id 匹配
//    F. mem_acquire 仲裁（lowest：cmo>pipereg>entry，18 源，单 beat）
//    G. mem_finish 仲裁（lowest：entry0..15，16 源，单 beat）
//    H. CMOUnit / FastArbiter 例化 + mem_grant.ready
//    I. refill_info（Mux1H by s2_miss_id）、probe/replace block、btot/occupy 冲突
//    J. 3 路 load forward（从在途 MSHR 前递尚未写回 DCache 的 refill 数据）
//    K. memSetPattenDetected / prefetch_info / wfi / debugTopDown / l1Miss / perf
//
//  本配置端口集合/命名与 golden MissQueue 完全一致（扁平 io_*）。可读性体现在「内部」用
//  struct/enum/function/generate 表达微架构。难点（坑）见文档与各分节注释。
// =============================================================================
import missqueue_pkg::*;

module xs_MissQueue_core (
  input  logic                  clock,
  input  logic                  reset,
`include "missqueue_ports.svh"
);

  // ===========================================================================
  //  A. entry / cmo / arb 接口线聚合
  // ---------------------------------------------------------------------------
  //  golden 顶层把每条 MissEntry 的端口展平成 _entries_<i>_io_*。这里改用「下标数组」
  //  聚合，便于 for/genvar 归约（命名表意，不照抄展平名）。
  // ===========================================================================
  // -- entry 输出（被队列级逻辑读取）--
  logic [N_ENTRY-1:0]            e_primary_ready;
  logic [N_ENTRY-1:0]            e_secondary_ready;
  logic [N_ENTRY-1:0]            e_secondary_reject;
  logic [N_ENTRY-1:0]            e_req_handled;          // 这条请求被本 entry 收下（alloc/merge）
  // queryME（每 entry × 4 路 query）
  logic [N_ENTRY-1:0]           qme_primary_ready  [N_QUERY];
  logic [N_ENTRY-1:0]           qme_secondary_ready[N_QUERY];
  logic [N_ENTRY-1:0]           qme_secondary_reject[N_QUERY];
  // mem_acquire（A 通道）payload
  logic [N_ENTRY-1:0]           e_acq_valid;
  logic [3:0]                   e_acq_opcode    [N_ENTRY];
  logic [2:0]                   e_acq_param     [N_ENTRY];
  logic [SRC_BITS-1:0]          e_acq_source    [N_ENTRY];
  logic [PADDR_BITS-1:0]        e_acq_address   [N_ENTRY];
  logic [1:0]                   e_acq_alias     [N_ENTRY];
  logic [43:0]                  e_acq_vaddr     [N_ENTRY];
  logic [4:0]                   e_acq_reqsrc    [N_ENTRY];
  logic [N_ENTRY-1:0]           e_acq_needhint;
  logic [N_ENTRY-1:0]           e_acq_iskeyword;
  // mem_finish（E 通道）payload
  logic [N_ENTRY-1:0]           e_fin_valid;
  logic [9:0]                   e_fin_sink      [N_ENTRY];
  // refill_info（给 MainPipe s2）
  logic [N_ENTRY-1:0]           e_refill_valid;
  logic [BLOCK_BITS-1:0]        e_refill_data   [N_ENTRY];
  logic [1:0]                   e_refill_param  [N_ENTRY];
  logic [N_ENTRY-1:0]           e_refill_error;
  // occupy / btot
  logic [3:0]                   e_occupy_way    [N_ENTRY];
  logic [N_ENTRY-1:0]           e_req_isBtoT;
  logic [N_ENTRY-1:0]           e_req_vaddr_valid;
  logic [VADDR_BITS-1:0]        e_req_vaddr     [N_ENTRY];
  // probe / replace block
  logic [N_ENTRY-1:0]           e_probe_block;
  logic [N_ENTRY-1:0]           e_replace_block;
  // forward（在途 refill 数据前递）
  logic [N_ENTRY-1:0]           e_fwd_inflight;
  logic [PADDR_BITS-1:0]        e_fwd_paddr     [N_ENTRY];
  logic [63:0]                  e_fwd_raw       [N_ENTRY][FWD_BEATS];
  logic [N_ENTRY-1:0]           e_fwd_firstbeat;
  logic [N_ENTRY-1:0]           e_fwd_lastbeat;
  logic [N_ENTRY-1:0]           e_fwd_corrupt;
  // 杂项输出
  logic [N_ENTRY-1:0]           e_perf_pending_prefetch;
  logic [N_ENTRY-1:0]           e_perf_pending_normal;
  logic [N_ENTRY-1:0]           e_rob_head_resp;
  logic [N_ENTRY-1:0]           e_lat_load, e_lat_store, e_lat_amo, e_lat_pf;
  logic [N_ENTRY-1:0]           e_late_prefetch;
  logic [N_ENTRY-1:0]           e_matched;
  logic [N_ENTRY-1:0]           e_l1Miss;
  logic [N_ENTRY-1:0]           e_wfi_safe;
  // main_pipe_req（喂 FastArbiter 黑盒）—— bundle 各字段
  logic [N_ENTRY-1:0]           e_mpr_valid;
  logic [3:0]                   e_mpr_miss_id   [N_ENTRY];
  logic [3:0]                   e_mpr_occupy_way[N_ENTRY];
  logic [N_ENTRY-1:0]           e_mpr_evict_btot;
  logic [3:0]                   e_mpr_source    [N_ENTRY];
  logic [4:0]                   e_mpr_cmd       [N_ENTRY];
  logic [VADDR_BITS-1:0]        e_mpr_vaddr     [N_ENTRY];
  logic [PADDR_BITS-1:0]        e_mpr_addr      [N_ENTRY];
  logic [2:0]                   e_mpr_word_idx  [N_ENTRY];
  logic [127:0]                 e_mpr_amo_data  [N_ENTRY];
  logic [15:0]                  e_mpr_amo_mask  [N_ENTRY];
  logic [127:0]                 e_mpr_amo_cmp   [N_ENTRY];
  logic [2:0]                   e_mpr_pf_source [N_ENTRY];
  logic [N_ENTRY-1:0]           e_mpr_access;
  logic [5:0]                   e_mpr_id        [N_ENTRY];
  logic [N_ENTRY-1:0]           e_mpr_ready;            // FastArbiter 回给各 entry 的 ready

  // FastArbiter 输出（= io_main_pipe_req）
  // CMOUnit 接口
  logic                         cmo_acq_valid;
  logic [3:0]                   cmo_acq_opcode;
  logic [PADDR_BITS-1:0]        cmo_acq_address;
  logic                         cmo_respD_ready;
  logic                         cmo_wfi_safe;

  // ===========================================================================
  //  B. 入队 s0 arbiter：alloc / merge / reject / accept
  // ---------------------------------------------------------------------------
  //  merge = 「pipereg 可合并这条请求」 | 任一 entry secondary_ready。
  //  reject= 「pipereg 拒绝这条请求」 | 任一 entry secondary_reject。
  //  alloc = 不 reject 且不 merge 且有空 entry（任一 primary_ready）。
  //  pipereg 的 merge/reject 判定（merge_req/reject_req）：同 block 且 pipereg 正 alloc，
  //  按「alias 是否相同 + 来路是否可合并(load 合并到 load/store/pf；store 合并到 load/pf)」决定。
  // ===========================================================================
  // miss_req_pipe_reg（入队第二级流水寄存器）—— 声明前置（B/D 节判定即引用，时序更新见 C 末）。
  miss_req_t mqpr;
  logic      mqpr_merge, mqpr_alloc, mqpr_cancel;
  logic [ENTRY_IDX_W-1:0] mqpr_mshr_id;

  // pipereg 来路谓词（与 golden _acquire_from_pipereg_bits_T* 一致）
  wire pr_is_load   = (mqpr.source == SRC_LOAD);
  wire pr_is_store  = (mqpr.source == SRC_STORE);
  wire pr_is_pref   = (mqpr.source >  SRC_AMO);   // source>2 → prefetch
  wire req_is_load  = (io_req_bits_source == SRC_LOAD);
  wire req_is_store = (io_req_bits_source == SRC_STORE);

  // 同 block（block = addr[47:6]）+ 同 alias（vaddr[13:12]）
  wire pr_block_match_req = (mqpr.addr[PADDR_BITS-1:6] == io_req_bits_addr[PADDR_BITS-1:6]);
  wire pr_alias_match_req = (mqpr.vaddr[13:12]         == io_req_bits_vaddr[13:12]);
  // 来路可合并：merge_load=(pr is load|store|pf)&req_load；merge_store=(pr is load|pf)&req_store
  wire pr_mergeable_req = (pr_is_load | pr_is_store | pr_is_pref) & req_is_load
                        | (pr_is_load | pr_is_pref)              & req_is_store;

  // pipereg.merge_req / reject_req（仅当 pipereg.alloc 时有效，对应 Mux(alloc, ..., false)）
  wire pr_merge_req  = mqpr_alloc & pr_block_match_req & pr_alias_match_req & pr_mergeable_req;
  wire pr_reject_req = mqpr_alloc & pr_block_match_req
                     & (~pr_alias_match_req | ~pr_mergeable_req);

  wire merge  = pr_merge_req  | (|e_secondary_ready);
  wire reject = pr_reject_req | (|e_secondary_reject);
  wire alloc  = ~reject & ~merge & (|e_primary_ready);
  wire accept = alloc | merge;

  assign io_req_ready  = accept;
  assign io_resp_merged = merge;

  // req_pipeline_reg_handled：这条请求被「pipereg 合并」处理（不进 mshr）
  wire req_pipeline_reg_handled = pr_merge_req & io_req_valid;

  // resp.id：若被 pipereg 处理 → mshr_id；否则 = 命中 entry 的下标（OHToUInt(req_handled)）
  logic [ENTRY_IDX_W-1:0] req_handled_idx;
  always_comb begin
    req_handled_idx = '0;
    for (int i = 0; i < N_ENTRY; i++)
      if (e_req_handled[i]) req_handled_idx |= ENTRY_IDX_W'(i);
  end
  assign io_resp_id      = req_pipeline_reg_handled ? mqpr_mshr_id : req_handled_idx;
  assign io_resp_handled = (|e_req_handled) | req_pipeline_reg_handled;

  // ===========================================================================
  //  C. miss_req_pipe_reg（入队第二级流水）+ acquire_from_pipereg
  // ---------------------------------------------------------------------------
  //  入队分两拍（Scala 注释的 s0 arbiter → pipeline reg → s1 alloc/merge）：
  //    · io_req.valid 这拍：锁存 payload 到 mqpr.req（无条件锁 payload）；
  //    · 同时按本拍 alloc/merge/cancel 结果置 mqpr_alloc/mqpr_merge/mqpr_cancel；
  //    · 下一拍 mqpr 注入对应 entry（见 E 节，按 mshr_id 匹配）。
  //  acquire_from_pipereg：pipereg 正 alloc 且「不会被一条新 store 合并进来」时，立刻替这条
  //  请求发一条 acquire（降低 miss 延迟）。它在 A 通道里以 idx1（优先级仅次于 CMO）参与仲裁。
  //  （mqpr/mqpr_alloc/... 已在 B 节前置声明，时序更新在本核末尾。）
  // ===========================================================================
  // can_send_acquire = alloc && !(io_req.valid && merge_req(new) && new.isFromStore)
  //   即：pipereg 正 alloc，且不是「正要被一条新 store 合并」的情况。
  wire pr_merge_by_new_store = io_req_valid & pr_merge_req & req_is_store;
  wire acquire_from_pipereg_valid = mqpr_alloc & ~pr_merge_by_new_store & ~io_wfi_wfiReq;

  // get_acquire bits（pipereg 直发的 acquire 各字段）
  wire [2:0] pr_acq_param  = grow_param(mqpr.cmd, mqpr.req_coh_state);
  // opcode：full_overwrite → AcquirePerm(opcode 7=0b0111)；否则 AcquireBlock(opcode 6=0b0110)
  //   golden 用 {3'h3, full_overwrite} = full?7:6。
  wire [3:0] pr_acq_opcode  = {3'h3, mqpr.full_overwrite};
  // acquire source = 分配到的 MSHR 下标（mshr_id），不是 LSU 请求 id（mqpr.id）。
  wire [SRC_BITS-1:0] pr_acq_source = {2'h0, mqpr_mshr_id};
  wire [PADDR_BITS-1:0] pr_acq_address = {mqpr.addr[PADDR_BITS-1:6], 6'h0};
  wire [1:0]  pr_acq_alias  = mqpr.vaddr[13:12];
  wire [43:0] pr_acq_vaddr  = mqpr.vaddr[VADDR_BITS-1:6];
  // reqSource：load→2，store→3，否则 L1DataPrefetch 编码 {3'h1, src!=AMO, 1'h0}
  wire [4:0]  pr_acq_reqsrc = pr_is_load  ? REQSRC_CPU_LOAD
                            : pr_is_store ? REQSRC_CPU_STORE
                            : {3'h1, (mqpr.source != SRC_AMO), 1'h0};
  // needHint：!l2_pf_store_only | store；isKeyword：仅 load 且 vaddr[5]
  wire pr_acq_needhint  = ~io_l2_pf_store_only | pr_is_store;
  // isKeyword()（Scala MissReq.isKeyword，new_req=req 自身）：
  //   Mux(merge_req(req), merge_isKeyword(req), alloc && load && vaddr[5])
  //   self-merge 时 isAfter(lqIdx,lqIdx)=false → 仍取 req.vaddr[5]；
  //   golden 展开 = (alloc&((load|store|pf)&load | (load|pf)&store) | alloc&load) & vaddr[5]。
  wire pr_self_merge = mqpr_alloc & ((pr_is_load | pr_is_store | pr_is_pref) & pr_is_load
                                   | (pr_is_load | pr_is_pref) & pr_is_store);
  wire pr_acq_iskeyword = (pr_self_merge | (mqpr_alloc & pr_is_load)) & mqpr.vaddr[5];

  // ===========================================================================
  //  D. 4 路 queryMQ ready（与主请求同构的提前判定，给上游 timing）
  // ---------------------------------------------------------------------------
  //  每路 query：_merge = pipereg.merge_req(q) | 任一 entry queryME.secondary_ready；
  //              _reject= pipereg.reject_req(q)| 任一 entry queryME.secondary_reject；
  //              ready  = (_merge) | (~_reject & ~_merge & 任一 queryME.primary_ready)。
  //  golden 把它整理为 (~rejectTerm & primaryAny) | mergeAny，等价。这里用 for 展开 4 路。
  // ===========================================================================
  // query 端口聚合
  logic [3:0]            q_source [N_QUERY];
  logic [PADDR_BITS-1:0] q_addr   [N_QUERY];
  logic [VADDR_BITS-1:0] q_vaddr  [N_QUERY];
  always_comb begin
    q_source[0]=io_queryMQ_0_req_bits_source; q_addr[0]=io_queryMQ_0_req_bits_addr; q_vaddr[0]=io_queryMQ_0_req_bits_vaddr;
    q_source[1]=io_queryMQ_1_req_bits_source; q_addr[1]=io_queryMQ_1_req_bits_addr; q_vaddr[1]=io_queryMQ_1_req_bits_vaddr;
    q_source[2]=io_queryMQ_2_req_bits_source; q_addr[2]=io_queryMQ_2_req_bits_addr; q_vaddr[2]=io_queryMQ_2_req_bits_vaddr;
    q_source[3]=io_queryMQ_3_req_bits_source; q_addr[3]=io_queryMQ_3_req_bits_addr; q_vaddr[3]=io_queryMQ_3_req_bits_vaddr;
  end

  logic [N_QUERY-1:0] q_ready;
  always_comb
    for (int k = 0; k < N_QUERY; k++) begin
      automatic logic q_is_load  = (q_source[k] == SRC_LOAD);
      automatic logic q_is_store = (q_source[k] == SRC_STORE);
      automatic logic q_block    = (mqpr.addr[PADDR_BITS-1:6] == q_addr[k][PADDR_BITS-1:6]);
      automatic logic q_alias    = (mqpr.vaddr[13:12]         == q_vaddr[k][13:12]);
      automatic logic q_mergeable = (pr_is_load | pr_is_store | pr_is_pref) & q_is_load
                                  | (pr_is_load | pr_is_pref)              & q_is_store;
      automatic logic pr_merge_q  = mqpr_alloc & q_block & q_alias & q_mergeable;
      automatic logic pr_reject_q = mqpr_alloc & q_block & (~q_alias | ~q_mergeable);
      automatic logic merge_any   = pr_merge_q  | (|qme_secondary_ready[k]);
      automatic logic reject_any  = pr_reject_q | (|qme_secondary_reject[k]);
      automatic logic primary_any = (|qme_primary_ready[k]);
      q_ready[k] = (~reject_any & primary_any) | merge_any;
    end
  assign io_queryMQ_0_ready = q_ready[0];
  assign io_queryMQ_1_ready = q_ready[1];
  assign io_queryMQ_2_ready = q_ready[2];
  assign io_queryMQ_3_ready = q_ready[3];

  // ===========================================================================
  //  E. 每条 entry 例化（genvar）
  // ---------------------------------------------------------------------------
  //  primary_valid（分配 one-hot）：io_req.valid & !merge & !reject & 本 entry primary_ready
  //    & 比它低的 entry 都不 primary_ready（former_primary_ready）—— 选「最低空闲下标」。
  //  pipe_reg 注入：仅当 mqpr 有效（merge|alloc）且 mqpr_mshr_id==i 时把 mqpr 灌给这条 entry，
  //    否则该 entry 的 pipe_reg.merge/alloc 拉 0。
  //  mem_grant 按 source==i 路由；l2_hint 按 sourceId==i；mainpipe resp/replay/evict/refill
  //    按各自 miss_id==i 匹配。详见 missqueue_entry_inst.svh。
  // ===========================================================================
  // former_primary_ready[i] = |primary_ready[0..i-1]
  logic [N_ENTRY-1:0] former_primary_ready;
  always_comb begin
    former_primary_ready[0] = 1'b0;
    for (int i = 1; i < N_ENTRY; i++)
      former_primary_ready[i] = former_primary_ready[i-1] | e_primary_ready[i-1];
  end

  // pipe_reg 有效（merge|alloc）
  wire mqpr_reg_valid = mqpr_merge | mqpr_alloc;

  // mainpipe 信号公共项
  wire mp_resp_hit   = io_main_pipe_resp_valid & io_main_pipe_resp_bits_ack_miss_queue;
  wire mp_replay_hit = io_mainpipe_info_s2_valid & io_mainpipe_info_s2_replay_to_mq;
  wire mp_evict_hit  = io_mainpipe_info_s2_valid & io_mainpipe_info_s2_evict_BtoT_way;
  wire mp_refill_hit = io_mainpipe_info_s3_valid & io_mainpipe_info_s3_refill_resp;

  // acquire_from_pipereg 是否真的发出（用于 entry 的 acquire_fired_by_pipe_reg）
  // = io_mem_acquire_ready & allowed_pipereg & acquire_from_pipereg_valid
  // golden allowed_1 = beatsLeft ? state_1 : ~cmo_valid（TLArbiter 突发锁定，见 F 节 acq_grant）。
  logic [N_ACQ_SRC-1:0] acq_grant;   // 前向声明（F 节赋值）：ready 分配掩码 = beatsLeft ? state : readys
  wire acquire_pipereg_allowed = acq_grant[1];
  wire acquire_pipereg_fired   = io_mem_acquire_ready & acquire_pipereg_allowed & acquire_from_pipereg_valid;

  // 前向声明（被 entry genvar 例化引用，其驱动逻辑在 F/G/H 节）：A/E 通道仲裁 one-hot
  // winner 与 mem_grant 路由信号。generate 作用域内引用须先声明。
  logic [N_ACQ_SRC-1:0] acq_allowed;       // mem_acquire：源 i 无更高优先级阻挡（给 ready）
  logic [N_ACQ_SRC-1:0] acq_winner;        // mem_acquire：allowed & valid（给 payload mux）
  logic [N_FIN_SRC-1:0] fin_allowed;       // mem_finish 同上
  logic [N_FIN_SRC-1:0] fin_winner;
  logic [N_FIN_SRC-1:0] fin_grant;         // mem_finish ready 分配掩码（G 节赋值，含突发锁定）
  logic                 grant_is_cbo;      // grant.opcode==CBOAck → 交 CMOUnit
  logic [N_ENTRY-1:0]   grant_hit_entry;   // grant.source==i
  // memset 检测寄存器：entry 例化用它做 memSetPattenDetected 输入；驱动在 K 节。
  logic                 memset_detected_q;
  logic [9:0]           source_except_load_cnt;

`include "missqueue_entry_inst.svh"

  // ===========================================================================
  //  F. mem_acquire 仲裁（TLArbiter.lowest：cmo(0) > pipereg(1) > entry0..15(2..17)）
  // ---------------------------------------------------------------------------
  //  A 通道每源都是单 beat（AcquireBlock/Perm 的 numBeats1=0），故 beatsLeft 恒 0，仲裁退化
  //  为「idle lowest 优先」：winner = lowest_winner(valids)。golden 保留了 beatsLeft/state
  //  寄存器（突发锁定通用框架），本配置功能上 state 永远跟随 winner、beatsLeft 永远 0；这里
  //  直接用组合 lowest 选择 + Mux1H 拼 payload（与 golden 在 valids 下的取值逐位一致）。
  //  详见 missqueue_acq_arb.svh。
  // ===========================================================================
  logic [N_ACQ_SRC-1:0] acq_valids;   // [0]=cmo [1]=pipereg [2+i]=entry i（acq_winner 已前向声明）
  always_comb begin
    acq_valids[0] = cmo_acq_valid;
    acq_valids[1] = acquire_from_pipereg_valid;
    for (int i = 0; i < N_ENTRY; i++) acq_valids[2+i] = e_acq_valid[i];
  end
  assign acq_allowed = lowest_allowed_acq(acq_valids);
  assign acq_winner  = acq_allowed & acq_valids;

  // ---- TLArbiter 突发锁定框架（bug-for-bug 复刻 golden beatsLeft / state_0..17）----
  // FM 语义上 beatsLeft/state 是真实状态（golden 保留了寄存器，opcode 对 FM 是自由变量，
  // 组合「idle lowest」不可证等价）。beats1 = ~opcode[2]（Put* 2 beat）；pipereg 的
  // opcode 恒 {3'h3,x}（bit2=1）→ 不贡献（golden 表达式中亦无 winner_1 项）。
  logic                 acq_beatsLeft;
  logic [N_ACQ_SRC-1:0] acq_state;
  logic                 acq_beats1_sel;
  always_comb begin
    acq_beats1_sel = acq_winner[0] & ~cmo_acq_opcode[2];
    for (int i = 0; i < N_ENTRY; i++)
      acq_beats1_sel |= acq_winner[2+i] & ~e_acq_opcode[i][2];
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      acq_beatsLeft <= 1'b0;
      acq_state     <= '0;
    end else begin
      if (~acq_beatsLeft & io_mem_acquire_ready) acq_beatsLeft <= acq_beats1_sel;
      else acq_beatsLeft <= 1'(acq_beatsLeft - (io_mem_acquire_ready & io_mem_acquire_valid));
      if (~acq_beatsLeft) acq_state <= acq_winner;   // idle 拍锁存 winner（不看 ready）
    end
  end
  // payload 选择 muxState / ready 分配 allowed（golden muxState_k / allowed_k）
  wire [N_ACQ_SRC-1:0] acq_mux = acq_beatsLeft ? acq_state : acq_winner;
  assign acq_grant = acq_beatsLeft ? acq_state : acq_allowed;
  // out.valid = beatsLeft ? |(state&valids) : |valids（golden io_mem_acquire_valid_0）
  assign io_mem_acquire_valid = acq_beatsLeft ? |(acq_state & acq_valids) : |acq_valids;

`include "missqueue_acq_arb.svh"

  // ===========================================================================
  //  G. mem_finish 仲裁（TLArbiter.lowest：entry0..15，单 beat）
  // ===========================================================================
  assign fin_allowed = lowest_allowed_fin(e_fin_valid);  // fin_allowed/winner 已前向声明
  assign fin_winner  = fin_allowed & e_fin_valid;
  // ---- TLArbiter 突发锁定（golden beatsLeft_1 / state_1_0..15；E 通道 beats1 恒 0）----
  logic                 fin_beatsLeft;
  logic [N_FIN_SRC-1:0] fin_state;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fin_beatsLeft <= 1'b0;
      fin_state     <= '0;
    end else begin
      // golden: beatsLeft_1 <= ~(~b & ready) & (b - fire)：idle&ready 拍装载 0，否则递减
      if (~fin_beatsLeft & io_mem_finish_ready) fin_beatsLeft <= 1'b0;
      else fin_beatsLeft <= 1'(fin_beatsLeft - (io_mem_finish_ready & io_mem_finish_valid));
      if (~fin_beatsLeft) fin_state <= fin_winner;
    end
  end
  wire [N_FIN_SRC-1:0] fin_mux = fin_beatsLeft ? fin_state : fin_winner;
  assign fin_grant = fin_beatsLeft ? fin_state : fin_allowed;
  assign io_mem_finish_valid = fin_beatsLeft ? |(fin_state & e_fin_valid) : |e_fin_valid;
  always_comb begin
    io_mem_finish_bits_sink = '0;
    for (int i = 0; i < N_FIN_SRC; i++)
      if (fin_mux[i]) io_mem_finish_bits_sink |= e_fin_sink[i];
  end

  // ===========================================================================
  //  H. mem_grant.ready + CMOUnit / FastArbiter 例化
  // ---------------------------------------------------------------------------
  //  mem_grant 路由：opcode==CBOAck(8) → 交给 CMOUnit 的 resp_chanD；否则按 source==i 交给
  //  对应 entry（entry 的 mem_grant.ready 恒 1）。io_mem_grant_ready 据此选 cmo 或 entry。
  // ===========================================================================
  // grant_is_cbo / grant_hit_entry 已前向声明（在 entry 例化前），此处给出驱动。
  assign grant_is_cbo = io_mem_grant_valid & (io_mem_grant_bits_opcode == 4'h8);
  always_comb
    for (int i = 0; i < N_ENTRY; i++)
      grant_hit_entry[i] = (io_mem_grant_bits_source == SRC_BITS'(i));
  assign io_mem_grant_ready = grant_is_cbo ? cmo_respD_ready : (|grant_hit_entry);

`include "missqueue_subinst.svh"

  // ===========================================================================
  //  I. refill_info / probe / replace / btot / occupy
  // ===========================================================================
  // refill_info：Mux1H by s2_miss_id（选中那条 entry 的 refill_info，且本拍 s2_valid & entry valid）
  logic [N_ENTRY-1:0] s2_sel;   // s2_miss_id == i
  always_comb
    for (int i = 0; i < N_ENTRY; i++) s2_sel[i] = (io_mainpipe_info_s2_miss_id == ENTRY_IDX_W'(i));

  logic refill_valid_acc;
  logic [BLOCK_BITS-1:0] refill_data_acc;
  logic [1:0] refill_param_acc;
  logic refill_error_acc;
  always_comb begin
    refill_valid_acc = 1'b0;
    refill_data_acc  = '0;
    refill_param_acc = '0;
    refill_error_acc = 1'b0;
    for (int i = 0; i < N_ENTRY; i++) begin
      refill_valid_acc |= e_refill_valid[i] & io_mainpipe_info_s2_valid & s2_sel[i];
      if (s2_sel[i]) begin
        refill_data_acc  |= e_refill_data[i];
        refill_param_acc |= e_refill_param[i];
        refill_error_acc |= e_refill_error[i];
      end
    end
  end
  assign io_refill_info_valid           = refill_valid_acc;
  assign io_refill_info_bits_store_data = refill_data_acc;
  assign io_refill_info_bits_miss_param = refill_param_acc;
  assign io_refill_info_bits_error      = refill_error_acc;
  // store_mask 在 refill 恒为全 1（entry 内 = ~0）；这里随 s2_sel 任一命中即全 1
  assign io_refill_info_bits_store_mask = {BLOCK_MASK_W{|s2_sel}};

  // probe.block / replace.block：任一 entry block（replace 还含 pipereg 同 block+alias）
  assign io_probe_block = |e_probe_block;
  wire pr_replace_block = mqpr_reg_valid
      & (mqpr.addr[PADDR_BITS-1:6] == io_replace_req_bits_addr[PADDR_BITS-1:6])
      & (mqpr.vaddr[13:12]         == io_replace_req_bits_vaddr[13:12]);
  assign io_replace_block = (|e_replace_block) | pr_replace_block;

`include "missqueue_btot_occupy.svh"

  // ===========================================================================
  //  J. 3 路 load forward（从在途 MSHR 前递尚未写回 DCache 的 refill 数据）
  // ---------------------------------------------------------------------------
  //  上游给 mshrid + paddr，要求前递该 MSHR 已 refill 回的 128bit（2×64bit beat）。
  //    forward_result_valid = RegNext(valid & inflight[mshrid] & paddr.block==entry.paddr.block)
  //    forward_mshr = RegNext( paddr[5] ? lastbeat_valid[mshrid] : firstbeat_valid[mshrid] )
  //    forwardData  = RegNext( 选 raw_data[mshrid] 里 paddr[5:3] 起的 2 个 64bit 字 )
  //    corrupt      = RegNext(corrupt[mshrid])
  //  详见 missqueue_forward.svh。
  // ===========================================================================
`include "missqueue_forward.svh"

  // ===========================================================================
  //  K. memSetPattenDetected / prefetch_info / wfi / debugTopDown / l1Miss / perf
  // ===========================================================================
  // memset 检测：连续 >=8 条非 load（store）请求被处理 且 lqEmpty → 判定为 memset，放宽 prefetch entry。
  //  （source_except_load_cnt / memset_detected_q 已在 entry 例化前前置声明。）
  wire        any_handled = (|e_req_handled) | req_pipeline_reg_handled;
  always_ff @(posedge clock or posedge reset) begin   // golden 异步复位块
    if (reset) begin
      source_except_load_cnt <= '0;
      memset_detected_q      <= 1'b0;
    end else begin
      if (any_handled) begin
        if (req_is_load)       source_except_load_cnt <= '0;
        else if (req_is_store) source_except_load_cnt <= source_except_load_cnt + 10'h1;
      end
      // Threshold=8 → cnt>=8 等价于 cnt[9:3] 非 0
      memset_detected_q <= (|source_except_load_cnt[9:3]) & io_lqEmpty;
    end
  end
  assign io_memSetPattenDetected = memset_detected_q;

  // prefetch_info
  //   naive.late_miss_prefetch：本拍是 PrefetchRead(source==3 & cmd==M_PFR=2) 且 撞上 pipereg
  //     正 alloc 同 block（非 prefetch 来路）或撞上任一 entry matched。
  wire req_is_prefetch_read = (io_req_bits_source == SRC_PREF) & (io_req_bits_cmd == 5'h2);
  wire pr_matched_req = pr_block_match_req & mqpr_reg_valid & ~pr_is_pref;
  assign io_prefetch_info_naive_late_miss_prefetch =
      io_req_valid & req_is_prefetch_read & (pr_matched_req | (|e_matched));

  //   fdp.late_miss_prefetch：pipereg prefetch_late_en（pipereg alloc 同 block 且 pipereg 是
  //     prefetch、新请求非 prefetch）或任一 entry late_prefetch。
  wire pr_prefetch_late_en = io_req_valid & mqpr_alloc & pr_block_match_req
                           & pr_is_pref & ~(io_req_bits_source > SRC_AMO);
  assign io_prefetch_info_fdp_late_miss_prefetch = pr_prefetch_late_en | (|e_late_prefetch);
  assign io_prefetch_info_fdp_prefetch_monitor_cnt = io_main_pipe_req_ready & io_main_pipe_req_valid;
  // total_prefetch = alloc & req.valid & !cancel & isFromL1Prefetch(pf_source)（pf_source[2:1] 非 0）
  assign io_prefetch_info_fdp_total_prefetch =
      alloc & io_req_valid & ~io_req_bits_cancel & (|io_req_bits_pf_source[2:1]);

  // wfi.safe = cmo & 所有 entry safe
  assign io_wfi_wfiSafe = cmo_wfi_safe & (&e_wfi_safe);

  // debugTopDown.robHeadMissInDCache = 任一 entry rob_head_query.resp
  assign io_debugTopDown_robHeadMissInDCache = |e_rob_head_resp;

  // l1Miss = RegNext(任一 entry l1Miss)
  logic l1Miss_q;
  always_ff @(posedge clock) l1Miss_q <= |e_l1Miss;
  assign io_l1Miss = l1Miss_q;

  // perf：在途 entry 数（!primary_ready）分桶，各打 2 拍（与 golden 一致）
  logic [4:0] perf_valid_cnt;
  always_comb begin
    perf_valid_cnt = '0;
    for (int i = 0; i < N_ENTRY; i++) perf_valid_cnt += 5'(~e_primary_ready[i]);
  end
  wire perf_req = accept & io_req_valid;
  logic [4:0] perf_valid_cnt_q;
  logic p0,p0b,p1,p1b,p2,p2b,p3,p3b,p4,p4b;
  always_ff @(posedge clock) begin
    perf_valid_cnt_q <= perf_valid_cnt;
    p0 <= perf_req;                                                  p0b <= p0;
    p1 <= perf_valid_cnt_q < 5'h4;                                   p1b <= p1;
    p2 <= (perf_valid_cnt_q > 5'h4) & (perf_valid_cnt_q < 5'h9);     p2b <= p2;
    p3 <= (perf_valid_cnt_q > 5'h8) & ({2'h0,perf_valid_cnt_q} < 7'hD); p3b <= p3;
    p4 <= ({2'h0,perf_valid_cnt_q} > 7'hC);                          p4b <= p4;
  end
  assign io_perf_0_value = {5'h0, p0b};
  assign io_perf_1_value = {5'h0, p1b};
  assign io_perf_2_value = {5'h0, p2b};
  assign io_perf_3_value = {5'h0, p3b};
  assign io_perf_4_value = {5'h0, p4b};

  // ===========================================================================
  //  C(续). miss_req_pipe_reg 时序更新（放最后，靠近其使用的判定信号定义）
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin   // golden 异步复位块（3062 行）
    if (reset) begin
      mqpr         <= '0;
      mqpr_merge   <= 1'b0;
      mqpr_alloc   <= 1'b0;
      mqpr_cancel  <= 1'b0;
      mqpr_mshr_id <= '0;
    end else begin
      if (io_req_valid) begin
        mqpr.source         <= io_req_bits_source;
        mqpr.pf_source      <= io_req_bits_pf_source;
        mqpr.cmd            <= io_req_bits_cmd;
        // addr 只存 block 粒度(bit[47:6])——低 6 位全程不读, 见 pkg struct 注释。
        mqpr.addr           <= io_req_bits_addr[PADDR_BITS-1:6];
        mqpr.vaddr          <= io_req_bits_vaddr;
        mqpr.full_overwrite <= io_req_bits_full_overwrite;
        mqpr.word_idx       <= io_req_bits_word_idx;
        mqpr.amo_data       <= io_req_bits_amo_data;
        mqpr.amo_mask       <= io_req_bits_amo_mask;
        mqpr.amo_cmp        <= io_req_bits_amo_cmp;
        mqpr.req_coh_state  <= io_req_bits_req_coh_state;
        mqpr.id             <= io_req_bits_id;
        mqpr.isBtoT         <= io_req_bits_isBtoT;
        mqpr.occupy_way     <= io_req_bits_occupy_way;
        mqpr.store_data     <= io_req_bits_store_data;
        mqpr.store_mask     <= io_req_bits_store_mask;
      end
      mqpr_alloc  <= alloc  & io_req_valid & ~io_req_bits_cancel & ~io_wbq_block_miss_req;
      mqpr_merge  <= merge  & io_req_valid & ~io_req_bits_cancel & ~io_wbq_block_miss_req;
      mqpr_cancel <= io_wbq_block_miss_req;
      // mshr_id：被 pipereg 处理时保持，否则更新为本拍 resp.id
      if (!req_pipeline_reg_handled)
        mqpr_mshr_id <= io_resp_id;
    end
  end

endmodule
