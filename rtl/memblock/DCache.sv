// =============================================================================
// DCache.sv —— L1 数据缓存顶层（DCacheImp）：把 22 类子模块接成一个 cache，外加本层胶水
//
// 对应 Chisel: xiangshan.cache.DCacheImp（src/main/scala/xiangshan/cache/dcache/DCacheWrapper.scala）
//
// 在核里的位置：MemBlock 的 load/store/原子单元 ──io.lsu──> DCache ──TileLink A/B/C/D/E──> L2
//
// 本层几乎不存数据，它是"接线板"：
//   · 3 条 LoadPipe（ldu_0..2）各自读 tag / 数据 / meta 阵列，miss 了把请求送 MissQueue；
//   · MainPipe 是唯一会写 cache 的流水：store、原子、probe、回填、替换都在这里过；
//   · MissQueue 发 Acquire（A 通道）、收 Grant（D 通道）、给 MainPipe 发回填请求；
//   · ProbeQueue 收 L2 的 Probe（B 通道），WritebackQueue 发 Release / ProbeAck（C 通道）；
//   · 阵列：BankedDataArray（8 bank 数据）、DuplicatedTagArray、L1CohMetaArray（一致性状态）、
//     L1ErrorMetaArray / L1PrefetchSourceArray / L1FlagMetaArray（每行的错误 / 预取来源 / 访问位）。
// 本层自己的逻辑（xs_DCache_core，手写）只有下面这些，按通道分节：
//   §1 TileLink D 通道：按 opcode 把 Grant/GrantData/CBOAck 分给 MissQueue、ReleaseAck 分给
//      WritebackQueue；GrantData 同时前递给 3 条 load（forward_D，带"最后一拍"计数）与 LSQ 唤醒；
//   §2 TileLink B 通道：Probe 在 MissQueue 喊 block 时挡住；给 MissQueue 拼出带别名位的 vaddr；
//   §3 L2 提示与配置打拍（l2_hint / l2_pf_store_only 各打一拍再给 MissQueue）；
//   §4 阵列口的小胶水：tag 写意图挡 load 读 tag、伪 ECC 错误注入的 ready 汇总、断言寄存器；
//   §5 替换算法：256 组 × 4 路树形伪 LRU（3 位/组），4 个 touch 口（3 load + MainPipe），
//      1 个查询口（MainPipe 选牺牲路）；
//   §6 MainPipe 的各种回应打一拍再送出：原子回应（给 LSU 与 MissQueue）、store replay、
//      Release 通知（给 LSQ）、LR/SC 保留集失效；
//   §7 错误上报：MainPipe + 3 条 load 的 ECC 错误，打拍后按固定优先级选一个，再打一拍报 BEU；
//   §8 预取效果统计：给 PrefetcherMonitor / FDPrefetcherMonitor 的汇总信号；
//   §9 性能事件：40 个子模块事件各打两拍输出。
//
// 本配置（KunminghuV2Config）下的事实（照 golden 端口表与寄存器表核对过）：
//   · StorePrefetchL1Enabled = false：两条 StorePipe（stu_0/1）在 golden 里只剩 5 行、0 输出、
//     0 寄存器（死码 stub，见 docs/fm_predictions/StorePipe.json）；FDPrefetcherMonitor 同样
//     0 输出、0 寄存器（连 clock 都没有）。两侧照 golden 例化、照 golden 接线，它们不产生任何比较点。
//   · 没有 WPU（dwpuParam.enWPU=false）、没有 HyuCnt：load 读口就是 ldu_0..2 + MainPipe。
//   · 替换查询：只有 MainPipe 的 replace_way 有读者（load 的 replace_way 被 firtool 消掉）。
//   · XSPerfAccumulate 的探针（miss_queue_fire / num_loads / useless_prefetch ……）综合口径下
//     没有读者，golden 里只剩悬空的组合线，本文件不写。
//   · 断言 assert(!RegNext(!tag_write_intend && tagArray.io.write.valid)) 的打拍寄存器在 golden
//     里仍是真寄存器（无读者），§4 照留；`ifndef SYNTHESIS 里的 $fwrite 断言体不写。
//
// 复位域（与 golden 两个 always 块逐个对齐）：
//   异步复位：l2_pf_store_only 打拍、错误 valid 两拍、forward_D 的 3 个拍计数器、256 组 PLRU 状态
//   不复位  ：其余全部（l2_hint 打拍、错误数据、各回应打拍、预取标志、断言寄存器、perf 两拍）
//
// 本文件导航：
//   package dcache_pkg …… 配置常量、TileLink opcode、树形 PLRU 的两个函数
//   xs_DCache_core ……… §1..§9（手写，上面列的全部胶水）
//   DCache（wrapper）…… golden 端口表 + 子模块例化（实例名同 golden）+ 核例化；
//                         端口表与全部连线由 scripts/gen_dcache.py 从 golden 机械生成（--check）。
// =============================================================================
package dcache_pkg;

  // ---- KunminghuV2Config 下的配置常量（由 golden 端口 / 寄存器数量核实）----
  localparam int N_LDU      = 3;     // LoadPipelineWidth
  localparam int N_SETS     = 256;   // DCacheSets（替换状态每组一份）
  localparam int SET_W      = 8;
  localparam int N_WAYS     = 4;     // DCacheWays
  localparam int WAY_W      = 2;
  localparam int PLRU_W     = 3;     // 4 路树形伪 LRU：根 1 位 + 两棵子树各 1 位
  localparam int N_PERF     = 40;    // wb 5 + mainPipe 4 + missQueue 5 + probeQueue 5 + ldu 3×7
  localparam int PADDR_W    = 48;
  localparam int VADDR_W    = 50;
  localparam int BEAT_W     = 256;   // TileLink 数据宽度（l1BusDataWidth）
  localparam int N_ERR_SRC  = N_LDU + 1;   // 错误来源：MainPipe + 3 条 load

  // ---- TileLink D 通道 opcode ----
  localparam logic [3:0] TL_GRANT       = 4'd4;
  localparam logic [3:0] TL_GRANT_DATA  = 4'd5;
  localparam logic [3:0] TL_RELEASE_ACK = 4'd6;
  localparam logic [3:0] TL_CBO_ACK     = 4'd8;

  // MainPipe 回应的来源：原子操作（AMO_SOURCE）
  localparam logic [3:0] AMO_SOURCE     = 4'd2;

  // ---- 4 路树形伪 LRU（rocket-chip PseudoLRU，n_ways = 4）----
  // 状态 3 位：[2] 根，指向"下次该淘汰的那一半"（1 = 高半 way2/3，0 = 低半 way0/1）；
  //            [1] 高半子树，指向 way3(1) / way2(0)；[0] 低半子树，指向 way1(1) / way0(0)。
  // 访问某一路 = 把通往它的每个节点都翻向另一边。
  function automatic logic [PLRU_W-1:0] plru_touch(input logic [PLRU_W-1:0] state,
                                                    input logic [WAY_W-1:0]  way);
    logic [PLRU_W-1:0] next;
    next[2] = ~way[1];
    next[1] = way[1] ? ~way[0] : state[1];
    next[0] = way[1] ? state[0] : ~way[0];
    return next;
  endfunction

  // 沿着指针走到叶子 = 牺牲路
  function automatic logic [WAY_W-1:0] plru_victim(input logic [PLRU_W-1:0] state);
    return {state[2], state[2] ? state[1] : state[0]};
  endfunction

endpackage


// -----------------------------------------------------------------------------
// xs_DCache_core —— 可读核：本层全部胶水逻辑（子模块在 wrapper 里例化）
// -----------------------------------------------------------------------------
module xs_DCache_core
  import dcache_pkg::*;
(
  input  logic                              clock,
  input  logic                              reset,

  // ---- §1 TileLink D 通道（L2 -> DCache）----
  input  logic                              d_valid,
  input  logic [3:0]                        d_opcode,
  input  logic [2:0]                        d_size,
  input  logic [5:0]                        d_source,
  input  logic [BEAT_W-1:0]                 d_data,
  input  logic                              d_denied,
  input  logic                              d_corrupt,
  input  logic                              d_echo_is_keyword,
  output logic                              d_ready,
  input  logic                              mq_grant_ready,     // MissQueue 能收 Grant
  output logic                              mq_grant_valid,
  output logic                              wb_grant_valid,     // ReleaseAck 给 WritebackQueue
  output logic                              tl_d_channel_valid, // 给 LSQ：有 Grant/GrantData 到
  output logic [3:0]                        tl_d_channel_mshrid,
  output logic [N_LDU-1:0]                  fwd_d_valid,        // 给 3 条 load 的 D 通道前递
  output logic [N_LDU-1:0][BEAT_W-1:0]      fwd_d_data,
  output logic [N_LDU-1:0][3:0]             fwd_d_mshrid,
  output logic [N_LDU-1:0]                  fwd_d_last,
  output logic [N_LDU-1:0]                  fwd_d_denied,
  output logic [N_LDU-1:0]                  fwd_d_corrupt,

  // ---- §2 TileLink B 通道（Probe）----
  input  logic                              b_valid,
  input  logic [PADDR_W-1:0]                b_address,
  input  logic [BEAT_W-1:0]                 b_data,
  output logic                              b_ready,
  input  logic                              pq_probe_ready,     // ProbeQueue 能收
  input  logic                              mq_probe_block,     // MissQueue 要求挡 probe
  output logic                              pq_probe_valid,
  output logic [VADDR_W-1:0]                mq_probe_vaddr,

  // ---- §3 L2 提示 / 配置 ----
  input  logic                              l2_hint_valid,
  input  logic [3:0]                        l2_hint_source_id,
  input  logic                              l2_pf_store_only,
  output logic                              mq_l2_hint_valid,
  output logic [3:0]                        mq_l2_hint_source_id,
  output logic                              mq_l2_pf_store_only,

  // ---- §4 阵列口胶水 ----
  input  logic                              mp_tag_write_intend,
  input  logic                              tag_array_write_valid,  // tag_write_arb 的输出 valid
  output logic                              ldu_tag_read_ready,
  input  logic                              mp_pseudo_tag_inj_done,
  input  logic [N_LDU-1:0]                  ldu_pseudo_tag_inj_done,
  input  logic                              mp_pseudo_data_inj_done,
  input  logic [N_LDU-1:0]                  ldu_pseudo_data_inj_done,
  input  logic                              bda_pseudo_error_ready,
  output logic                              pseudo_tag_error_ready,
  output logic                              pseudo_data_error_ready,

  // ---- §5 替换算法 ----
  input  logic [N_LDU-1:0]                  ldu_repl_valid,
  input  logic [N_LDU-1:0][SET_W-1:0]       ldu_repl_set,
  input  logic [N_LDU-1:0][WAY_W-1:0]       ldu_repl_way,
  input  logic                              mp_repl_valid,
  input  logic [SET_W-1:0]                  mp_repl_set,
  input  logic [WAY_W-1:0]                  mp_repl_way,
  input  logic [SET_W-1:0]                  mp_victim_set,
  output logic [WAY_W-1:0]                  mp_victim_way,

  // ---- §6 MainPipe 回应 ----
  input  logic                              mp_atomic_valid,
  input  logic [3:0]                        mp_atomic_source,
  input  logic [127:0]                      mp_atomic_data,
  input  logic                              mp_atomic_miss,
  input  logic                              mp_atomic_replay,
  input  logic                              mp_atomic_denied,
  input  logic                              mp_atomic_corrupt,
  input  logic [5:0]                        mp_atomic_id,
  input  logic [3:0]                        mp_atomic_miss_id,
  input  logic                              mp_atomic_ack_miss_queue,
  output logic                              lsu_atomic_valid,
  output logic [127:0]                      lsu_atomic_data,
  output logic                              lsu_atomic_miss,
  output logic                              lsu_atomic_replay,
  output logic                              lsu_atomic_denied,
  output logic                              lsu_atomic_corrupt,
  output logic [5:0]                        lsu_atomic_id,
  output logic                              mq_mp_resp_valid,
  output logic [3:0]                        mq_mp_resp_miss_id,
  output logic                              mq_mp_resp_ack_miss_queue,
  input  logic                              mp_store_replay_valid,
  input  logic [5:0]                        mp_store_replay_id,
  output logic                              lsu_store_replay_valid,
  output logic [5:0]                        lsu_store_replay_id,
  input  logic                              wb_req_ready,
  input  logic                              mp_wb_valid,
  input  logic [PADDR_W-1:0]                mp_wb_addr,
  input  logic                              mp_lrsc_valid,
  input  logic [PADDR_W-1:0]                mp_lrsc_block,
  output logic                              lsu_release_valid,
  output logic [PADDR_W-1:0]                lsu_release_paddr,
  output logic                              mp_invalid_resv_set,

  // ---- §7 错误上报 ----
  input  logic [N_ERR_SRC-1:0]              err_valid,          // [0] MainPipe，[1+i] ldu_i
  input  logic [N_ERR_SRC-1:0][PADDR_W-1:0] err_paddr,
  input  logic [N_ERR_SRC-1:0]              err_report_to_beu,
  output logic                              error_valid,
  output logic [PADDR_W-1:0]                error_paddr,
  output logic                              error_report_to_beu,

  // ---- §8 预取效果统计 ----
  input  logic [N_LDU-1:0]                  ldu_pf_total,       // prefetch_info.naive.total_prefetch
  input  logic [N_LDU-1:0]                  ldu_pf_late_hit,    // prefetch_info.naive.late_hit_prefetch
  input  logic                              mp_pf_flag_write_valid,
  input  logic [N_WAYS-1:0]                 mp_pf_flag_write_way_en,
  input  logic [N_WAYS-1:0][2:0]            pf_array_last_resp, // prefetchArray 最后一个读口
  input  logic [N_WAYS-1:0]                 access_array_last_resp,
  input  logic [1:0]                        ldu_pf_flag_write_valid,  // 只比较 ldu_0 / ldu_1
  input  logic [1:0][SET_W-1:0]             ldu_pf_flag_write_idx,
  input  logic [1:0][N_WAYS-1:0]            ldu_pf_flag_write_way_en,
  input  logic [N_LDU-1:0]                  ldu_fdp_useful,     // prefetch_info.fdp.useful_prefetch
  output logic                              pfm_total_prefetch,
  output logic                              pfm_late_hit_prefetch,
  output logic                              pfm_good_prefetch,
  output logic                              pfm_bad_prefetch,
  output logic [N_LDU-1:0]                  fdp_useful_prefetch,

  // ---- §9 性能事件 ----
  input  logic [N_PERF-1:0][5:0]            perf_in,
  output logic [N_PERF-1:0][5:0]            perf_out
);

  // ===========================================================================
  // §1 TileLink D 通道
  // ---------------------------------------------------------------------------
  // DCache 只该收到四种 D 消息：Grant / GrantData / CBOAck 归 MissQueue，ReleaseAck 归
  // WritebackQueue。WritebackQueue 收 ReleaseAck 永远 ready，所以 ReleaseAck 时 d_ready 恒 1；
  // 其它 opcode 不该出现（golden 里是断言），d_ready = 0。
  // GrantData 的每一拍还同时前递给 3 条 load（forward_D）：load 若正等这条 MSHR 的数据，
  // 可以直接从 D 通道上取，不必等回填写进阵列。"最后一拍"由每条 load 各自一份的拍计数器
  // 给出（edge.count：64B 一行 = 2 拍 × 32B）；isKeyword 回来时关键字先到，last 位要翻转。
  // ===========================================================================
  logic d_to_miss_queue, d_is_release_ack, d_is_grant_data, d_fire;

  assign d_to_miss_queue  = d_opcode == TL_GRANT | d_opcode == TL_GRANT_DATA | d_opcode == TL_CBO_ACK;
  assign d_is_release_ack = d_opcode == TL_RELEASE_ACK;
  assign d_is_grant_data  = d_opcode == TL_GRANT_DATA;

  assign d_ready        = d_to_miss_queue ? mq_grant_ready : d_is_release_ack;
  assign d_fire         = d_ready & d_valid;
  assign mq_grant_valid = d_to_miss_queue & d_valid;
  assign wb_grant_valid = ~d_to_miss_queue & d_is_release_ack & d_valid;

  // LSQ 唤醒：有 Grant / GrantData 到（mshrid = source 低 4 位 = MSHR 编号）
  assign tl_d_channel_valid  = (d_opcode == TL_GRANT_DATA | d_opcode == TL_GRANT) & d_valid;
  assign tl_d_channel_mshrid = d_source[3:0];

  // edge.count 的"这条消息还剩几拍 - 1"：有数据且 size >= 64B 时为 1（两拍），否则 0。
  // （golden 的写法是 opcode[0] & ~((13'h3F << size)[5])，即 size > 5。）
  logic d_beats_minus1;
  assign d_beats_minus1 = d_opcode[0] & (d_size > 3'd5);

  // 每条 load 一份拍计数器（Chisel 每次 apply 都新建一个 edge.count，golden 三份照留）
  logic fwd_d_beat_cnt [N_LDU];   // 1 = 本消息还有一拍没来

  always_ff @(posedge clock or posedge reset)
    if (reset)
      for (int i = 0; i < N_LDU; i++)
        fwd_d_beat_cnt[i] <= 1'b0;
    else if (d_fire)
      for (int i = 0; i < N_LDU; i++)
        fwd_d_beat_cnt[i] <= fwd_d_beat_cnt[i] ? 1'b0 : d_beats_minus1;

  always_comb
    for (int i = 0; i < N_LDU; i++) begin
      fwd_d_valid[i]   = d_is_grant_data & d_valid;
      fwd_d_data[i]    = d_data;
      fwd_d_mshrid[i]  = d_source[3:0];
      // done = 最后一拍且握手；计数器为 1（还剩一拍）或本消息只有一拍，都算最后一拍
      fwd_d_last[i]    = d_echo_is_keyword ^ ((fwd_d_beat_cnt[i] | ~d_beats_minus1) & d_fire);
      fwd_d_denied[i]  = d_is_grant_data & d_denied;
      fwd_d_corrupt[i] = d_is_grant_data & d_corrupt;
    end

  // ===========================================================================
  // §2 TileLink B 通道（Probe）
  // ---------------------------------------------------------------------------
  // block_decoupled：MissQueue 正在处理同一行时（probe_block）把 Probe 挡在 B 通道上，
  // valid 与 ready 两边一起挡。
  // MissQueue 还要用 probe 的地址查自己的 MSHR，它按 vaddr 索引：DCache 组号用到 vaddr[13:12]
  // （超出 4KB 页），L2 把这两位别名位放在 Probe 的 data[2:1] 里带回来，这里拼进去。
  // ===========================================================================
  assign b_ready        = pq_probe_ready & ~mq_probe_block;
  assign pq_probe_valid = b_valid & ~mq_probe_block;
  assign mq_probe_vaddr = {2'b00, b_address[47:14], b_data[2:1], b_address[11:0]};

  // ===========================================================================
  // §3 L2 提示与配置打拍
  // ---------------------------------------------------------------------------
  // l2_hint（L2 预告"某 MSHR 的 Grant 快到了"）RegNext 一拍给 MissQueue，不复位；
  // l2_pf_store_only RegNext(init = false)，异步复位。
  // ===========================================================================
  logic       l2_hint_valid_q;
  logic [3:0] l2_hint_source_id_q;
  logic       l2_pf_store_only_q;

  always_ff @(posedge clock) begin
    l2_hint_valid_q     <= l2_hint_valid;
    l2_hint_source_id_q <= l2_hint_source_id;
  end

  always_ff @(posedge clock or posedge reset)
    if (reset)
      l2_pf_store_only_q <= 1'b0;
    else
      l2_pf_store_only_q <= l2_pf_store_only;

  assign mq_l2_hint_valid     = l2_hint_valid_q;
  assign mq_l2_hint_source_id = l2_hint_source_id_q;
  assign mq_l2_pf_store_only  = l2_pf_store_only_q;

  // ===========================================================================
  // §4 阵列口的小胶水
  // ---------------------------------------------------------------------------
  // tag 阵列单口写：MainPipe 下一拍要写 tag 时（tag_write_intend）提前一拍挡住 3 条 load 读 tag。
  // 伪 ECC 错误注入（CtrlUnit 的两个注入口）：tag 错误由 MainPipe 或任一 load 注入成功即完成；
  //   data 错误还要 BankedDataArray 这边也 ready。
  // 断言 assert(!RegNext(!tag_write_intend && tagArray.io.write.valid)) 的打拍寄存器照留。
  // ===========================================================================
  logic tag_write_unintended_q;

  assign ldu_tag_read_ready      = ~mp_tag_write_intend;
  assign pseudo_tag_error_ready  = mp_pseudo_tag_inj_done | (|ldu_pseudo_tag_inj_done);
  assign pseudo_data_error_ready = bda_pseudo_error_ready
                                   & (mp_pseudo_data_inj_done | (|ldu_pseudo_data_inj_done));

  always_ff @(posedge clock)
    tag_write_unintended_q <= ~mp_tag_write_intend & tag_array_write_valid;

  // ===========================================================================
  // §5 替换算法：256 组 × 4 路树形伪 LRU
  // ---------------------------------------------------------------------------
  // 每组 3 位状态（plru_touch / plru_victim 见 dcache_pkg），异步复位为 0。
  // 一拍内最多 4 个访问（ldu_0, ldu_1, ldu_2, MainPipe，按这个顺序依次作用）：
  //   同一组被几个口同时访问时，状态按顺序折叠 —— 后面的口在前面口更新后的状态上再翻。
  // 查询只有 MainPipe 一个口（替换时选牺牲路），读的是本拍更新前的状态。
  // ===========================================================================
  logic [PLRU_W-1:0] plru_state [N_SETS];
  logic [PLRU_W-1:0] plru_next  [N_SETS];
  logic              plru_touched [N_SETS];

  logic [N_LDU:0]               touch_valid;   // 4 个访问口：[0..2] ldu，[3] MainPipe
  logic [N_LDU:0][SET_W-1:0]    touch_set;
  logic [N_LDU:0][WAY_W-1:0]    touch_way;

  assign touch_valid = {mp_repl_valid, ldu_repl_valid};
  assign touch_set   = {mp_repl_set, ldu_repl_set};
  assign touch_way   = {mp_repl_way, ldu_repl_way};

  always_comb
    for (int s = 0; s < N_SETS; s++) begin
      plru_next[s]    = plru_state[s];
      plru_touched[s] = 1'b0;
      for (int p = 0; p <= N_LDU; p++)
        if (touch_valid[p] && touch_set[p] == SET_W'(s)) begin
          plru_next[s]    = plru_touch(plru_next[s], touch_way[p]);
          plru_touched[s] = 1'b1;
        end
    end

  always_ff @(posedge clock or posedge reset)
    if (reset)
      for (int s = 0; s < N_SETS; s++)
        plru_state[s] <= '0;
    else
      for (int s = 0; s < N_SETS; s++)
        if (plru_touched[s])
          plru_state[s] <= plru_next[s];

  assign mp_victim_way = plru_victim(plru_state[mp_victim_set]);

  // ===========================================================================
  // §6 MainPipe 的回应，各打一拍再送出（均不复位）
  // ---------------------------------------------------------------------------
  // 原子回应：MainPipe 的 atomic_resp 既回 LSU（只认 source == AMO 的那些），又回 MissQueue
  //   （回填流程里的 AMO 结束确认，不看 source）。两边各一套 RegNext / RegEnable。
  // store replay 回应：RegNext valid + RegEnable id。
  // Release 通知：MainPipe 往 WritebackQueue 发出一条（wb.io.req 握手）时，下一拍告诉 LSQ
  //   "这一行被放掉了"（load 违例检查要用）；同时若放掉的正是 LR 锁住的那一行，
  //   下一拍让 MainPipe 作废保留集。
  // ===========================================================================
  logic         atomic_to_lsu;
  logic         wb_req_fire;

  assign atomic_to_lsu = mp_atomic_valid & mp_atomic_source == AMO_SOURCE;
  assign wb_req_fire   = wb_req_ready & mp_wb_valid;

  logic         lsu_atomic_valid_q;
  logic [127:0] lsu_atomic_data_q;
  logic         lsu_atomic_miss_q;
  logic         lsu_atomic_replay_q;
  logic         lsu_atomic_denied_q;
  logic         lsu_atomic_corrupt_q;
  logic [5:0]   lsu_atomic_id_q;
  logic         mq_mp_resp_valid_q;
  logic [3:0]   mq_mp_resp_miss_id_q;
  logic         mq_mp_resp_ack_q;
  logic         store_replay_valid_q;
  logic [5:0]   store_replay_id_q;
  logic         invalid_resv_set_q;
  logic         release_valid_q;
  logic [PADDR_W-1:0] release_paddr_q;

  always_ff @(posedge clock) begin
    lsu_atomic_valid_q <= atomic_to_lsu;
    if (atomic_to_lsu) begin
      lsu_atomic_data_q    <= mp_atomic_data;
      lsu_atomic_miss_q    <= mp_atomic_miss;
      lsu_atomic_replay_q  <= mp_atomic_replay;
      lsu_atomic_denied_q  <= mp_atomic_denied;
      lsu_atomic_corrupt_q <= mp_atomic_corrupt;
      lsu_atomic_id_q      <= mp_atomic_id;
    end

    mq_mp_resp_valid_q <= mp_atomic_valid;
    if (mp_atomic_valid) begin
      mq_mp_resp_miss_id_q <= mp_atomic_miss_id;
      mq_mp_resp_ack_q     <= mp_atomic_ack_miss_queue;
    end

    store_replay_valid_q <= mp_store_replay_valid;
    if (mp_store_replay_valid)
      store_replay_id_q <= mp_store_replay_id;

    invalid_resv_set_q <= wb_req_fire & mp_wb_addr == mp_lrsc_block & mp_lrsc_valid;

    release_valid_q <= wb_req_fire;
    if (wb_req_fire)
      release_paddr_q <= mp_wb_addr;
  end

  assign lsu_atomic_valid          = lsu_atomic_valid_q;
  assign lsu_atomic_data           = lsu_atomic_data_q;
  assign lsu_atomic_miss           = lsu_atomic_miss_q;
  assign lsu_atomic_replay         = lsu_atomic_replay_q;
  assign lsu_atomic_denied         = lsu_atomic_denied_q;
  assign lsu_atomic_corrupt        = lsu_atomic_corrupt_q;
  assign lsu_atomic_id             = lsu_atomic_id_q;
  assign mq_mp_resp_valid          = mq_mp_resp_valid_q;
  assign mq_mp_resp_miss_id        = mq_mp_resp_miss_id_q;
  assign mq_mp_resp_ack_miss_queue = mq_mp_resp_ack_q;
  assign lsu_store_replay_valid    = store_replay_valid_q;
  assign lsu_store_replay_id       = store_replay_id_q;
  assign mp_invalid_resv_set       = invalid_resv_set_q;
  assign lsu_release_valid         = release_valid_q;
  assign lsu_release_paddr         = release_paddr_q;

  // ===========================================================================
  // §7 错误上报
  // ---------------------------------------------------------------------------
  //   io.error.bits  := RegEnable(ParallelPriorityMux(errors.map(e => RegNext(e.valid) ->
  //                                                    RegEnable(e.bits, e.valid))),
  //                               RegNext(error_valid))
  //   io.error.valid := RegNext(RegNext(error_valid, false), false)
  // 第 1 拍：每个来源各自锁存 bits（valid 时才更新）并 RegNext 它的 valid；
  // 第 2 拍：上一拍有任何错误时，按固定优先级 MainPipe > ldu_0 > ldu_1 > ldu_2 选一个锁存。
  //   最后一个来源是优先级链的默认项，它的 valid 打拍不需要（golden 里也没有）。
  // valid 两拍都异步复位，其余不复位。
  // ===========================================================================
  logic                    err_any;
  logic [N_ERR_SRC-2:0]    err_src_valid_q;                 // 只有前 3 个来源需要
  logic [PADDR_W-1:0]      err_src_paddr_q [N_ERR_SRC];
  logic                    err_src_beu_q   [N_ERR_SRC];
  logic                    err_any_q;
  logic [PADDR_W-1:0]      err_sel_paddr;
  logic                    err_sel_beu;
  logic [PADDR_W-1:0]      err_out_paddr_q;
  logic                    err_out_beu_q;
  logic                    err_valid_q1, err_valid_q2;

  assign err_any = |err_valid;

  always_ff @(posedge clock) begin
    err_src_valid_q <= err_valid[N_ERR_SRC-2:0];
    for (int k = 0; k < N_ERR_SRC; k++)
      if (err_valid[k]) begin
        err_src_paddr_q[k] <= err_paddr[k];
        err_src_beu_q[k]   <= err_report_to_beu[k];
      end
    err_any_q <= err_any;
    if (err_any_q) begin
      err_out_paddr_q <= err_sel_paddr;
      err_out_beu_q   <= err_sel_beu;
    end
  end

  always_comb begin
    err_sel_paddr = err_src_paddr_q[N_ERR_SRC-1];
    err_sel_beu   = err_src_beu_q[N_ERR_SRC-1];
    for (int k = N_ERR_SRC - 2; k >= 0; k--)
      if (err_src_valid_q[k]) begin
        err_sel_paddr = err_src_paddr_q[k];
        err_sel_beu   = err_src_beu_q[k];
      end
  end

  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      err_valid_q1 <= 1'b0;
      err_valid_q2 <= 1'b0;
    end
    else begin
      err_valid_q1 <= err_any;
      err_valid_q2 <= err_valid_q1;
    end

  assign error_valid         = err_valid_q2;
  assign error_paddr         = err_out_paddr_q;
  assign error_report_to_beu = err_out_beu_q;

  // ===========================================================================
  // §8 预取效果统计
  // ---------------------------------------------------------------------------
  // PrefetcherMonitor（调节硬件预取的激进程度）要两类信息：
  //   timely：任一 load 本拍碰到"预取来的行"/ 迟到的预取命中；
  //   validity：MainPipe 改写某行的预取标志时（该行要被替换或降级），下一拍读回这一行的
  //     预取来源与访问位（prefetchArray / accessArray 的最后一个读口在 MainPipe 写的同拍读）：
  //     是预取来的且被访问过 = 好预取，没被访问过 = 坏预取。
  // FDPrefetcherMonitor 的 useful_prefetch：ldu_0 与 ldu_1 同拍改写同一行同一路的预取标志时，
  //   只算一次（ldu_1、ldu_2 的那份被压掉 —— 照 Scala 原样，ldu_2 也被同一个条件压）。
  // ===========================================================================
  logic                   extra_flag_valid_q;
  logic [N_WAYS-1:0]      extra_flag_way_en_q;
  logic [2:0]             extra_flag_prefetch;
  logic                   extra_flag_access;
  logic                   same_cycle_update_pf_flag;

  always_ff @(posedge clock) begin
    extra_flag_valid_q <= mp_pf_flag_write_valid;
    if (mp_pf_flag_write_valid)
      extra_flag_way_en_q <= mp_pf_flag_write_way_en;
  end

  // Mux1H（按位或）
  always_comb begin
    extra_flag_prefetch = '0;
    extra_flag_access   = 1'b0;
    for (int w = 0; w < N_WAYS; w++) begin
      extra_flag_prefetch |= extra_flag_way_en_q[w] ? pf_array_last_resp[w] : 3'b000;
      extra_flag_access   |= extra_flag_way_en_q[w] & access_array_last_resp[w];
    end
  end

  // isPrefetchRelated(source) = source >= L1_HW_PREFETCH_CLEAR(1)，即非 0
  assign pfm_good_prefetch     = extra_flag_valid_q & (extra_flag_prefetch != 3'd0) & extra_flag_access;
  assign pfm_bad_prefetch      = extra_flag_valid_q & (extra_flag_prefetch != 3'd0) & ~extra_flag_access;
  assign pfm_total_prefetch    = |ldu_pf_total;
  assign pfm_late_hit_prefetch = |ldu_pf_late_hit;

  assign same_cycle_update_pf_flag = ldu_pf_flag_write_valid[0] & ldu_pf_flag_write_valid[1]
                                     & ldu_pf_flag_write_idx[0] == ldu_pf_flag_write_idx[1]
                                     & ldu_pf_flag_write_way_en[0] == ldu_pf_flag_write_way_en[1];

  always_comb
    for (int w = 0; w < N_LDU; w++)
      fdp_useful_prefetch[w] = (w == 0) ? ldu_fdp_useful[w]
                                        : ~same_cycle_update_pf_flag & ldu_fdp_useful[w];

  // ===========================================================================
  // §9 性能事件
  // ---------------------------------------------------------------------------
  // generatePerfEvent：子模块的 40 个事件（wb 0..4 / mainPipe 5..8 / missQueue 9..13 /
  // probeQueue 14..18 / ldu_0 19..25 / ldu_1 26..32 / ldu_2 33..39）各 RegNext 两拍，不复位。
  // ===========================================================================
  logic [5:0] perf_q1 [N_PERF];
  logic [5:0] perf_q2 [N_PERF];

  always_ff @(posedge clock)
    for (int k = 0; k < N_PERF; k++) begin
      perf_q1[k] <= perf_in[k];
      perf_q2[k] <= perf_q1[k];
    end

  always_comb
    for (int k = 0; k < N_PERF; k++)
      perf_out[k] = perf_q2[k];

endmodule


// =============================================================================
// DCache —— golden 同名 wrapper：例化核与全部子模块（实例名、端口顺序同 golden）。
//   全部由 scripts/gen_dcache.py 从 golden 端口表与例化连线生成，改请改生成器。
// =============================================================================
module DCache
  import dcache_pkg::*;
(
  // BEGIN GENERATED(dcache-ports)
  input          clock,
  input          reset,
  output         auto_cacheCtrlOpt_in_a_ready,
  input          auto_cacheCtrlOpt_in_a_valid,
  input  [3:0]   auto_cacheCtrlOpt_in_a_bits_opcode,
  input  [1:0]   auto_cacheCtrlOpt_in_a_bits_size,
  input  [3:0]   auto_cacheCtrlOpt_in_a_bits_source,
  input  [29:0]  auto_cacheCtrlOpt_in_a_bits_address,
  input  [7:0]   auto_cacheCtrlOpt_in_a_bits_mask,
  input  [63:0]  auto_cacheCtrlOpt_in_a_bits_data,
  input          auto_cacheCtrlOpt_in_d_ready,
  output         auto_cacheCtrlOpt_in_d_valid,
  output [3:0]   auto_cacheCtrlOpt_in_d_bits_opcode,
  output [1:0]   auto_cacheCtrlOpt_in_d_bits_size,
  output [3:0]   auto_cacheCtrlOpt_in_d_bits_source,
  output [63:0]  auto_cacheCtrlOpt_in_d_bits_data,
  input          auto_client_out_a_ready,
  output         auto_client_out_a_valid,
  output [3:0]   auto_client_out_a_bits_opcode,
  output [2:0]   auto_client_out_a_bits_param,
  output [2:0]   auto_client_out_a_bits_size,
  output [5:0]   auto_client_out_a_bits_source,
  output [47:0]  auto_client_out_a_bits_address,
  output [1:0]   auto_client_out_a_bits_user_alias,
  output [43:0]  auto_client_out_a_bits_user_vaddr,
  output [4:0]   auto_client_out_a_bits_user_reqSource,
  output         auto_client_out_a_bits_user_needHint,
  output         auto_client_out_a_bits_echo_isKeyword,
  output [31:0]  auto_client_out_a_bits_mask,
  output         auto_client_out_b_ready,
  input          auto_client_out_b_valid,
  input  [2:0]   auto_client_out_b_bits_opcode,
  input  [1:0]   auto_client_out_b_bits_param,
  input  [47:0]  auto_client_out_b_bits_address,
  input  [255:0] auto_client_out_b_bits_data,
  input          auto_client_out_c_ready,
  output         auto_client_out_c_valid,
  output [2:0]   auto_client_out_c_bits_opcode,
  output [2:0]   auto_client_out_c_bits_param,
  output [2:0]   auto_client_out_c_bits_size,
  output [5:0]   auto_client_out_c_bits_source,
  output [47:0]  auto_client_out_c_bits_address,
  output [255:0] auto_client_out_c_bits_data,
  output         auto_client_out_c_bits_corrupt,
  output         auto_client_out_d_ready,
  input          auto_client_out_d_valid,
  input  [3:0]   auto_client_out_d_bits_opcode,
  input  [1:0]   auto_client_out_d_bits_param,
  input  [2:0]   auto_client_out_d_bits_size,
  input  [5:0]   auto_client_out_d_bits_source,
  input  [9:0]   auto_client_out_d_bits_sink,
  input          auto_client_out_d_bits_denied,
  input          auto_client_out_d_bits_echo_isKeyword,
  input  [255:0] auto_client_out_d_bits_data,
  input          auto_client_out_d_bits_corrupt,
  input          auto_client_out_e_ready,
  output         auto_client_out_e_valid,
  output [9:0]   auto_client_out_e_bits_sink,
  input  [5:0]   io_hartId,
  input          io_l2_pf_store_only,
  output         io_lsu_load_0_req_ready,
  input          io_lsu_load_0_req_valid,
  input  [4:0]   io_lsu_load_0_req_bits_cmd,
  input  [49:0]  io_lsu_load_0_req_bits_vaddr,
  input  [49:0]  io_lsu_load_0_req_bits_vaddr_dup,
  input  [3:0]   io_lsu_load_0_req_bits_instrtype,
  input          io_lsu_load_0_req_bits_isFirstIssue,
  input          io_lsu_load_0_req_bits_lqIdx_flag,
  input  [6:0]   io_lsu_load_0_req_bits_lqIdx_value,
  output         io_lsu_load_0_resp_valid,
  output [127:0] io_lsu_load_0_resp_bits_data,
  output [127:0] io_lsu_load_0_resp_bits_data_delayed,
  output         io_lsu_load_0_resp_bits_miss,
  output [3:0]   io_lsu_load_0_resp_bits_mshr_id,
  output [2:0]   io_lsu_load_0_resp_bits_meta_prefetch,
  output         io_lsu_load_0_resp_bits_handled,
  output         io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied,
  output         io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt,
  input          io_lsu_load_0_s1_kill_data_read,
  input          io_lsu_load_0_s1_kill,
  input          io_lsu_load_0_s2_kill,
  input          io_lsu_load_0_is128Req,
  input  [2:0]   io_lsu_load_0_pf_source,
  input  [47:0]  io_lsu_load_0_s1_paddr_dup_lsu,
  input  [47:0]  io_lsu_load_0_s1_paddr_dup_dcache,
  output         io_lsu_load_0_s2_bank_conflict,
  output         io_lsu_load_0_s2_mq_nack,
  output         io_lsu_load_1_req_ready,
  input          io_lsu_load_1_req_valid,
  input  [4:0]   io_lsu_load_1_req_bits_cmd,
  input  [49:0]  io_lsu_load_1_req_bits_vaddr,
  input  [49:0]  io_lsu_load_1_req_bits_vaddr_dup,
  input  [3:0]   io_lsu_load_1_req_bits_instrtype,
  input          io_lsu_load_1_req_bits_isFirstIssue,
  input          io_lsu_load_1_req_bits_lqIdx_flag,
  input  [6:0]   io_lsu_load_1_req_bits_lqIdx_value,
  output         io_lsu_load_1_resp_valid,
  output [127:0] io_lsu_load_1_resp_bits_data,
  output         io_lsu_load_1_resp_bits_miss,
  output [3:0]   io_lsu_load_1_resp_bits_mshr_id,
  output [2:0]   io_lsu_load_1_resp_bits_meta_prefetch,
  output         io_lsu_load_1_resp_bits_handled,
  output         io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied,
  output         io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt,
  input          io_lsu_load_1_s1_kill_data_read,
  input          io_lsu_load_1_s1_kill,
  input          io_lsu_load_1_s2_kill,
  input          io_lsu_load_1_is128Req,
  input  [2:0]   io_lsu_load_1_pf_source,
  input  [47:0]  io_lsu_load_1_s1_paddr_dup_lsu,
  input  [47:0]  io_lsu_load_1_s1_paddr_dup_dcache,
  output         io_lsu_load_1_s2_bank_conflict,
  output         io_lsu_load_1_s2_mq_nack,
  output         io_lsu_load_2_req_ready,
  input          io_lsu_load_2_req_valid,
  input  [4:0]   io_lsu_load_2_req_bits_cmd,
  input  [49:0]  io_lsu_load_2_req_bits_vaddr,
  input  [49:0]  io_lsu_load_2_req_bits_vaddr_dup,
  input  [3:0]   io_lsu_load_2_req_bits_instrtype,
  input          io_lsu_load_2_req_bits_isFirstIssue,
  input          io_lsu_load_2_req_bits_lqIdx_flag,
  input  [6:0]   io_lsu_load_2_req_bits_lqIdx_value,
  output         io_lsu_load_2_resp_valid,
  output [127:0] io_lsu_load_2_resp_bits_data,
  output         io_lsu_load_2_resp_bits_miss,
  output [3:0]   io_lsu_load_2_resp_bits_mshr_id,
  output [2:0]   io_lsu_load_2_resp_bits_meta_prefetch,
  output         io_lsu_load_2_resp_bits_handled,
  output         io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied,
  output         io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt,
  input          io_lsu_load_2_s1_kill_data_read,
  input          io_lsu_load_2_s1_kill,
  input          io_lsu_load_2_s2_kill,
  input          io_lsu_load_2_is128Req,
  input  [2:0]   io_lsu_load_2_pf_source,
  input  [47:0]  io_lsu_load_2_s1_paddr_dup_lsu,
  input  [47:0]  io_lsu_load_2_s1_paddr_dup_dcache,
  output         io_lsu_load_2_s2_bank_conflict,
  output         io_lsu_load_2_s2_mq_nack,
  input          io_lsu_sta_0_req_valid,
  input          io_lsu_sta_1_req_valid,
  output         io_lsu_tl_d_channel_valid,
  output [3:0]   io_lsu_tl_d_channel_mshrid,
  output         io_lsu_store_req_ready,
  input          io_lsu_store_req_valid,
  input  [49:0]  io_lsu_store_req_bits_vaddr,
  input  [47:0]  io_lsu_store_req_bits_addr,
  input  [511:0] io_lsu_store_req_bits_data,
  input  [63:0]  io_lsu_store_req_bits_mask,
  input  [5:0]   io_lsu_store_req_bits_id,
  output         io_lsu_store_main_pipe_hit_resp_valid,
  output [5:0]   io_lsu_store_main_pipe_hit_resp_bits_id,
  output         io_lsu_store_replay_resp_valid,
  output [5:0]   io_lsu_store_replay_resp_bits_id,
  output         io_lsu_atomics_req_ready,
  input          io_lsu_atomics_req_valid,
  input  [4:0]   io_lsu_atomics_req_bits_cmd,
  input  [49:0]  io_lsu_atomics_req_bits_vaddr,
  input  [47:0]  io_lsu_atomics_req_bits_addr,
  input  [2:0]   io_lsu_atomics_req_bits_word_idx,
  input  [127:0] io_lsu_atomics_req_bits_amo_data,
  input  [15:0]  io_lsu_atomics_req_bits_amo_mask,
  input  [127:0] io_lsu_atomics_req_bits_amo_cmp,
  output         io_lsu_atomics_resp_valid,
  output [127:0] io_lsu_atomics_resp_bits_data,
  output         io_lsu_atomics_resp_bits_miss,
  output         io_lsu_atomics_resp_bits_replay,
  output         io_lsu_atomics_resp_bits_tl_error_tl_denied,
  output         io_lsu_atomics_resp_bits_tl_error_tl_corrupt,
  output [5:0]   io_lsu_atomics_resp_bits_id,
  output         io_lsu_atomics_block_lr,
  output         io_lsu_release_valid,
  output [47:0]  io_lsu_release_bits_paddr,
  output         io_lsu_forward_D_0_valid,
  output [255:0] io_lsu_forward_D_0_data,
  output [3:0]   io_lsu_forward_D_0_mshrid,
  output         io_lsu_forward_D_0_last,
  output         io_lsu_forward_D_0_denied,
  output         io_lsu_forward_D_0_corrupt,
  output         io_lsu_forward_D_1_valid,
  output [255:0] io_lsu_forward_D_1_data,
  output [3:0]   io_lsu_forward_D_1_mshrid,
  output         io_lsu_forward_D_1_last,
  output         io_lsu_forward_D_1_denied,
  output         io_lsu_forward_D_1_corrupt,
  output         io_lsu_forward_D_2_valid,
  output [255:0] io_lsu_forward_D_2_data,
  output [3:0]   io_lsu_forward_D_2_mshrid,
  output         io_lsu_forward_D_2_last,
  output         io_lsu_forward_D_2_denied,
  output         io_lsu_forward_D_2_corrupt,
  input          io_lsu_forward_mshr_0_valid,
  input  [3:0]   io_lsu_forward_mshr_0_mshrid,
  input  [47:0]  io_lsu_forward_mshr_0_paddr,
  output         io_lsu_forward_mshr_0_forward_mshr,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_0,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_1,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_2,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_3,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_4,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_5,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_6,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_7,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_8,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_9,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_10,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_11,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_12,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_13,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_14,
  output [7:0]   io_lsu_forward_mshr_0_forwardData_15,
  output         io_lsu_forward_mshr_0_forward_result_valid,
  output         io_lsu_forward_mshr_0_denied,
  output         io_lsu_forward_mshr_0_corrupt,
  input          io_lsu_forward_mshr_1_valid,
  input  [3:0]   io_lsu_forward_mshr_1_mshrid,
  input  [47:0]  io_lsu_forward_mshr_1_paddr,
  output         io_lsu_forward_mshr_1_forward_mshr,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_0,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_1,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_2,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_3,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_4,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_5,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_6,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_7,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_8,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_9,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_10,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_11,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_12,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_13,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_14,
  output [7:0]   io_lsu_forward_mshr_1_forwardData_15,
  output         io_lsu_forward_mshr_1_forward_result_valid,
  output         io_lsu_forward_mshr_1_denied,
  output         io_lsu_forward_mshr_1_corrupt,
  input          io_lsu_forward_mshr_2_valid,
  input  [3:0]   io_lsu_forward_mshr_2_mshrid,
  input  [47:0]  io_lsu_forward_mshr_2_paddr,
  output         io_lsu_forward_mshr_2_forward_mshr,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_0,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_1,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_2,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_3,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_4,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_5,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_6,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_7,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_8,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_9,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_10,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_11,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_12,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_13,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_14,
  output [7:0]   io_lsu_forward_mshr_2_forwardData_15,
  output         io_lsu_forward_mshr_2_forward_result_valid,
  output         io_lsu_forward_mshr_2_denied,
  output         io_lsu_forward_mshr_2_corrupt,
  output         io_error_valid,
  output [47:0]  io_error_bits_paddr,
  output         io_error_bits_report_to_beu,
  input          io_lqEmpty,
  output         io_pf_ctrl_enable,
  output         io_pf_ctrl_confidence,
  output         io_sms_agt_evict_req_valid,
  output [49:0]  io_sms_agt_evict_req_bits_vaddr,
  input          io_debugTopDown_robHeadVaddr_valid,
  input  [49:0]  io_debugTopDown_robHeadVaddr_bits,
  output         io_debugTopDown_robHeadMissInDCache,
  input          io_l2_hint_valid,
  input  [3:0]   io_l2_hint_bits_sourceId,
  output         io_cmoOpReq_ready,
  input          io_cmoOpReq_valid,
  input  [2:0]   io_cmoOpReq_bits_opcode,
  input  [63:0]  io_cmoOpReq_bits_address,
  input          io_cmoOpResp_ready,
  output         io_cmoOpResp_valid,
  output         io_cmoOpResp_bits_denied,
  output         io_cmoOpResp_bits_corrupt,
  output         io_l1Miss,
  input          io_wfi_wfiReq,
  output         io_wfi_wfiSafe,
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value,
  output [5:0]   io_perf_2_value,
  output [5:0]   io_perf_3_value,
  output [5:0]   io_perf_4_value,
  output [5:0]   io_perf_5_value,
  output [5:0]   io_perf_6_value,
  output [5:0]   io_perf_7_value,
  output [5:0]   io_perf_8_value,
  output [5:0]   io_perf_9_value,
  output [5:0]   io_perf_10_value,
  output [5:0]   io_perf_11_value,
  output [5:0]   io_perf_12_value,
  output [5:0]   io_perf_13_value,
  output [5:0]   io_perf_14_value,
  output [5:0]   io_perf_15_value,
  output [5:0]   io_perf_16_value,
  output [5:0]   io_perf_17_value,
  output [5:0]   io_perf_18_value,
  output [5:0]   io_perf_19_value,
  output [5:0]   io_perf_20_value,
  output [5:0]   io_perf_21_value,
  output [5:0]   io_perf_22_value,
  output [5:0]   io_perf_23_value,
  output [5:0]   io_perf_24_value,
  output [5:0]   io_perf_25_value,
  output [5:0]   io_perf_26_value,
  output [5:0]   io_perf_27_value,
  output [5:0]   io_perf_28_value,
  output [5:0]   io_perf_29_value,
  output [5:0]   io_perf_30_value,
  output [5:0]   io_perf_31_value,
  output [5:0]   io_perf_32_value,
  output [5:0]   io_perf_33_value,
  output [5:0]   io_perf_34_value,
  output [5:0]   io_perf_35_value,
  output [5:0]   io_perf_36_value,
  output [5:0]   io_perf_37_value,
  output [5:0]   io_perf_38_value,
  output [5:0]   io_perf_39_value,
  input  [4:0]   boreChildrenBd_bore_array,
  input          boreChildrenBd_bore_all,
  input          boreChildrenBd_bore_req,
  output         boreChildrenBd_bore_ack,
  input          boreChildrenBd_bore_writeen,
  input          boreChildrenBd_bore_be,
  input  [8:0]   boreChildrenBd_bore_addr,
  input  [71:0]  boreChildrenBd_bore_indata,
  input          boreChildrenBd_bore_readen,
  input  [8:0]   boreChildrenBd_bore_addr_rd,
  output [71:0]  boreChildrenBd_bore_outdata,
  input  [5:0]   boreChildrenBd_bore_1_array,
  input          boreChildrenBd_bore_1_all,
  input          boreChildrenBd_bore_1_req,
  output         boreChildrenBd_bore_1_ack,
  input          boreChildrenBd_bore_1_writeen,
  input  [1:0]   boreChildrenBd_bore_1_be,
  input  [8:0]   boreChildrenBd_bore_1_addr,
  input  [85:0]  boreChildrenBd_bore_1_indata,
  input          boreChildrenBd_bore_1_readen,
  input  [8:0]   boreChildrenBd_bore_1_addr_rd,
  output [85:0]  boreChildrenBd_bore_1_outdata,
  input          sigFromSrams_bore_ram_hold,
  input          sigFromSrams_bore_ram_bypass,
  input          sigFromSrams_bore_ram_bp_clken,
  input          sigFromSrams_bore_ram_aux_clk,
  input          sigFromSrams_bore_ram_aux_ckbp,
  input          sigFromSrams_bore_ram_mcp_hold,
  input          sigFromSrams_bore_cgen,
  input          sigFromSrams_bore_1_ram_hold,
  input          sigFromSrams_bore_1_ram_bypass,
  input          sigFromSrams_bore_1_ram_bp_clken,
  input          sigFromSrams_bore_1_ram_aux_clk,
  input          sigFromSrams_bore_1_ram_aux_ckbp,
  input          sigFromSrams_bore_1_ram_mcp_hold,
  input          sigFromSrams_bore_1_cgen,
  input          sigFromSrams_bore_2_ram_hold,
  input          sigFromSrams_bore_2_ram_bypass,
  input          sigFromSrams_bore_2_ram_bp_clken,
  input          sigFromSrams_bore_2_ram_aux_clk,
  input          sigFromSrams_bore_2_ram_aux_ckbp,
  input          sigFromSrams_bore_2_ram_mcp_hold,
  input          sigFromSrams_bore_2_cgen,
  input          sigFromSrams_bore_3_ram_hold,
  input          sigFromSrams_bore_3_ram_bypass,
  input          sigFromSrams_bore_3_ram_bp_clken,
  input          sigFromSrams_bore_3_ram_aux_clk,
  input          sigFromSrams_bore_3_ram_aux_ckbp,
  input          sigFromSrams_bore_3_ram_mcp_hold,
  input          sigFromSrams_bore_3_cgen,
  input          sigFromSrams_bore_4_ram_hold,
  input          sigFromSrams_bore_4_ram_bypass,
  input          sigFromSrams_bore_4_ram_bp_clken,
  input          sigFromSrams_bore_4_ram_aux_clk,
  input          sigFromSrams_bore_4_ram_aux_ckbp,
  input          sigFromSrams_bore_4_ram_mcp_hold,
  input          sigFromSrams_bore_4_cgen,
  input          sigFromSrams_bore_5_ram_hold,
  input          sigFromSrams_bore_5_ram_bypass,
  input          sigFromSrams_bore_5_ram_bp_clken,
  input          sigFromSrams_bore_5_ram_aux_clk,
  input          sigFromSrams_bore_5_ram_aux_ckbp,
  input          sigFromSrams_bore_5_ram_mcp_hold,
  input          sigFromSrams_bore_5_cgen,
  input          sigFromSrams_bore_6_ram_hold,
  input          sigFromSrams_bore_6_ram_bypass,
  input          sigFromSrams_bore_6_ram_bp_clken,
  input          sigFromSrams_bore_6_ram_aux_clk,
  input          sigFromSrams_bore_6_ram_aux_ckbp,
  input          sigFromSrams_bore_6_ram_mcp_hold,
  input          sigFromSrams_bore_6_cgen,
  input          sigFromSrams_bore_7_ram_hold,
  input          sigFromSrams_bore_7_ram_bypass,
  input          sigFromSrams_bore_7_ram_bp_clken,
  input          sigFromSrams_bore_7_ram_aux_clk,
  input          sigFromSrams_bore_7_ram_aux_ckbp,
  input          sigFromSrams_bore_7_ram_mcp_hold,
  input          sigFromSrams_bore_7_cgen,
  input          sigFromSrams_bore_8_ram_hold,
  input          sigFromSrams_bore_8_ram_bypass,
  input          sigFromSrams_bore_8_ram_bp_clken,
  input          sigFromSrams_bore_8_ram_aux_clk,
  input          sigFromSrams_bore_8_ram_aux_ckbp,
  input          sigFromSrams_bore_8_ram_mcp_hold,
  input          sigFromSrams_bore_8_cgen,
  input          sigFromSrams_bore_9_ram_hold,
  input          sigFromSrams_bore_9_ram_bypass,
  input          sigFromSrams_bore_9_ram_bp_clken,
  input          sigFromSrams_bore_9_ram_aux_clk,
  input          sigFromSrams_bore_9_ram_aux_ckbp,
  input          sigFromSrams_bore_9_ram_mcp_hold,
  input          sigFromSrams_bore_9_cgen,
  input          sigFromSrams_bore_10_ram_hold,
  input          sigFromSrams_bore_10_ram_bypass,
  input          sigFromSrams_bore_10_ram_bp_clken,
  input          sigFromSrams_bore_10_ram_aux_clk,
  input          sigFromSrams_bore_10_ram_aux_ckbp,
  input          sigFromSrams_bore_10_ram_mcp_hold,
  input          sigFromSrams_bore_10_cgen,
  input          sigFromSrams_bore_11_ram_hold,
  input          sigFromSrams_bore_11_ram_bypass,
  input          sigFromSrams_bore_11_ram_bp_clken,
  input          sigFromSrams_bore_11_ram_aux_clk,
  input          sigFromSrams_bore_11_ram_aux_ckbp,
  input          sigFromSrams_bore_11_ram_mcp_hold,
  input          sigFromSrams_bore_11_cgen,
  input          sigFromSrams_bore_12_ram_hold,
  input          sigFromSrams_bore_12_ram_bypass,
  input          sigFromSrams_bore_12_ram_bp_clken,
  input          sigFromSrams_bore_12_ram_aux_clk,
  input          sigFromSrams_bore_12_ram_aux_ckbp,
  input          sigFromSrams_bore_12_ram_mcp_hold,
  input          sigFromSrams_bore_12_cgen,
  input          sigFromSrams_bore_13_ram_hold,
  input          sigFromSrams_bore_13_ram_bypass,
  input          sigFromSrams_bore_13_ram_bp_clken,
  input          sigFromSrams_bore_13_ram_aux_clk,
  input          sigFromSrams_bore_13_ram_aux_ckbp,
  input          sigFromSrams_bore_13_ram_mcp_hold,
  input          sigFromSrams_bore_13_cgen,
  input          sigFromSrams_bore_14_ram_hold,
  input          sigFromSrams_bore_14_ram_bypass,
  input          sigFromSrams_bore_14_ram_bp_clken,
  input          sigFromSrams_bore_14_ram_aux_clk,
  input          sigFromSrams_bore_14_ram_aux_ckbp,
  input          sigFromSrams_bore_14_ram_mcp_hold,
  input          sigFromSrams_bore_14_cgen,
  input          sigFromSrams_bore_15_ram_hold,
  input          sigFromSrams_bore_15_ram_bypass,
  input          sigFromSrams_bore_15_ram_bp_clken,
  input          sigFromSrams_bore_15_ram_aux_clk,
  input          sigFromSrams_bore_15_ram_aux_ckbp,
  input          sigFromSrams_bore_15_ram_mcp_hold,
  input          sigFromSrams_bore_15_cgen,
  input          sigFromSrams_bore_16_ram_hold,
  input          sigFromSrams_bore_16_ram_bypass,
  input          sigFromSrams_bore_16_ram_bp_clken,
  input          sigFromSrams_bore_16_ram_aux_clk,
  input          sigFromSrams_bore_16_ram_aux_ckbp,
  input          sigFromSrams_bore_16_ram_mcp_hold,
  input          sigFromSrams_bore_16_cgen,
  input          sigFromSrams_bore_17_ram_hold,
  input          sigFromSrams_bore_17_ram_bypass,
  input          sigFromSrams_bore_17_ram_bp_clken,
  input          sigFromSrams_bore_17_ram_aux_clk,
  input          sigFromSrams_bore_17_ram_aux_ckbp,
  input          sigFromSrams_bore_17_ram_mcp_hold,
  input          sigFromSrams_bore_17_cgen,
  input          sigFromSrams_bore_18_ram_hold,
  input          sigFromSrams_bore_18_ram_bypass,
  input          sigFromSrams_bore_18_ram_bp_clken,
  input          sigFromSrams_bore_18_ram_aux_clk,
  input          sigFromSrams_bore_18_ram_aux_ckbp,
  input          sigFromSrams_bore_18_ram_mcp_hold,
  input          sigFromSrams_bore_18_cgen,
  input          sigFromSrams_bore_19_ram_hold,
  input          sigFromSrams_bore_19_ram_bypass,
  input          sigFromSrams_bore_19_ram_bp_clken,
  input          sigFromSrams_bore_19_ram_aux_clk,
  input          sigFromSrams_bore_19_ram_aux_ckbp,
  input          sigFromSrams_bore_19_ram_mcp_hold,
  input          sigFromSrams_bore_19_cgen,
  input          sigFromSrams_bore_20_ram_hold,
  input          sigFromSrams_bore_20_ram_bypass,
  input          sigFromSrams_bore_20_ram_bp_clken,
  input          sigFromSrams_bore_20_ram_aux_clk,
  input          sigFromSrams_bore_20_ram_aux_ckbp,
  input          sigFromSrams_bore_20_ram_mcp_hold,
  input          sigFromSrams_bore_20_cgen,
  input          sigFromSrams_bore_21_ram_hold,
  input          sigFromSrams_bore_21_ram_bypass,
  input          sigFromSrams_bore_21_ram_bp_clken,
  input          sigFromSrams_bore_21_ram_aux_clk,
  input          sigFromSrams_bore_21_ram_aux_ckbp,
  input          sigFromSrams_bore_21_ram_mcp_hold,
  input          sigFromSrams_bore_21_cgen,
  input          sigFromSrams_bore_22_ram_hold,
  input          sigFromSrams_bore_22_ram_bypass,
  input          sigFromSrams_bore_22_ram_bp_clken,
  input          sigFromSrams_bore_22_ram_aux_clk,
  input          sigFromSrams_bore_22_ram_aux_ckbp,
  input          sigFromSrams_bore_22_ram_mcp_hold,
  input          sigFromSrams_bore_22_cgen,
  input          sigFromSrams_bore_23_ram_hold,
  input          sigFromSrams_bore_23_ram_bypass,
  input          sigFromSrams_bore_23_ram_bp_clken,
  input          sigFromSrams_bore_23_ram_aux_clk,
  input          sigFromSrams_bore_23_ram_aux_ckbp,
  input          sigFromSrams_bore_23_ram_mcp_hold,
  input          sigFromSrams_bore_23_cgen,
  input          sigFromSrams_bore_24_ram_hold,
  input          sigFromSrams_bore_24_ram_bypass,
  input          sigFromSrams_bore_24_ram_bp_clken,
  input          sigFromSrams_bore_24_ram_aux_clk,
  input          sigFromSrams_bore_24_ram_aux_ckbp,
  input          sigFromSrams_bore_24_ram_mcp_hold,
  input          sigFromSrams_bore_24_cgen,
  input          sigFromSrams_bore_25_ram_hold,
  input          sigFromSrams_bore_25_ram_bypass,
  input          sigFromSrams_bore_25_ram_bp_clken,
  input          sigFromSrams_bore_25_ram_aux_clk,
  input          sigFromSrams_bore_25_ram_aux_ckbp,
  input          sigFromSrams_bore_25_ram_mcp_hold,
  input          sigFromSrams_bore_25_cgen,
  input          sigFromSrams_bore_26_ram_hold,
  input          sigFromSrams_bore_26_ram_bypass,
  input          sigFromSrams_bore_26_ram_bp_clken,
  input          sigFromSrams_bore_26_ram_aux_clk,
  input          sigFromSrams_bore_26_ram_aux_ckbp,
  input          sigFromSrams_bore_26_ram_mcp_hold,
  input          sigFromSrams_bore_26_cgen,
  input          sigFromSrams_bore_27_ram_hold,
  input          sigFromSrams_bore_27_ram_bypass,
  input          sigFromSrams_bore_27_ram_bp_clken,
  input          sigFromSrams_bore_27_ram_aux_clk,
  input          sigFromSrams_bore_27_ram_aux_ckbp,
  input          sigFromSrams_bore_27_ram_mcp_hold,
  input          sigFromSrams_bore_27_cgen,
  input          sigFromSrams_bore_28_ram_hold,
  input          sigFromSrams_bore_28_ram_bypass,
  input          sigFromSrams_bore_28_ram_bp_clken,
  input          sigFromSrams_bore_28_ram_aux_clk,
  input          sigFromSrams_bore_28_ram_aux_ckbp,
  input          sigFromSrams_bore_28_ram_mcp_hold,
  input          sigFromSrams_bore_28_cgen,
  input          sigFromSrams_bore_29_ram_hold,
  input          sigFromSrams_bore_29_ram_bypass,
  input          sigFromSrams_bore_29_ram_bp_clken,
  input          sigFromSrams_bore_29_ram_aux_clk,
  input          sigFromSrams_bore_29_ram_aux_ckbp,
  input          sigFromSrams_bore_29_ram_mcp_hold,
  input          sigFromSrams_bore_29_cgen,
  input          sigFromSrams_bore_30_ram_hold,
  input          sigFromSrams_bore_30_ram_bypass,
  input          sigFromSrams_bore_30_ram_bp_clken,
  input          sigFromSrams_bore_30_ram_aux_clk,
  input          sigFromSrams_bore_30_ram_aux_ckbp,
  input          sigFromSrams_bore_30_ram_mcp_hold,
  input          sigFromSrams_bore_30_cgen,
  input          sigFromSrams_bore_31_ram_hold,
  input          sigFromSrams_bore_31_ram_bypass,
  input          sigFromSrams_bore_31_ram_bp_clken,
  input          sigFromSrams_bore_31_ram_aux_clk,
  input          sigFromSrams_bore_31_ram_aux_ckbp,
  input          sigFromSrams_bore_31_ram_mcp_hold,
  input          sigFromSrams_bore_31_cgen,
  input          sigFromSrams_bore_32_ram_hold,
  input          sigFromSrams_bore_32_ram_bypass,
  input          sigFromSrams_bore_32_ram_bp_clken,
  input          sigFromSrams_bore_32_ram_aux_clk,
  input          sigFromSrams_bore_32_ram_aux_ckbp,
  input          sigFromSrams_bore_32_ram_mcp_hold,
  input          sigFromSrams_bore_32_cgen,
  input          sigFromSrams_bore_33_ram_hold,
  input          sigFromSrams_bore_33_ram_bypass,
  input          sigFromSrams_bore_33_ram_bp_clken,
  input          sigFromSrams_bore_33_ram_aux_clk,
  input          sigFromSrams_bore_33_ram_aux_ckbp,
  input          sigFromSrams_bore_33_ram_mcp_hold,
  input          sigFromSrams_bore_33_cgen,
  input          sigFromSrams_bore_34_ram_hold,
  input          sigFromSrams_bore_34_ram_bypass,
  input          sigFromSrams_bore_34_ram_bp_clken,
  input          sigFromSrams_bore_34_ram_aux_clk,
  input          sigFromSrams_bore_34_ram_aux_ckbp,
  input          sigFromSrams_bore_34_ram_mcp_hold,
  input          sigFromSrams_bore_34_cgen,
  input          sigFromSrams_bore_35_ram_hold,
  input          sigFromSrams_bore_35_ram_bypass,
  input          sigFromSrams_bore_35_ram_bp_clken,
  input          sigFromSrams_bore_35_ram_aux_clk,
  input          sigFromSrams_bore_35_ram_aux_ckbp,
  input          sigFromSrams_bore_35_ram_mcp_hold,
  input          sigFromSrams_bore_35_cgen,
  input          sigFromSrams_bore_36_ram_hold,
  input          sigFromSrams_bore_36_ram_bypass,
  input          sigFromSrams_bore_36_ram_bp_clken,
  input          sigFromSrams_bore_36_ram_aux_clk,
  input          sigFromSrams_bore_36_ram_aux_ckbp,
  input          sigFromSrams_bore_36_ram_mcp_hold,
  input          sigFromSrams_bore_36_cgen,
  input          sigFromSrams_bore_37_ram_hold,
  input          sigFromSrams_bore_37_ram_bypass,
  input          sigFromSrams_bore_37_ram_bp_clken,
  input          sigFromSrams_bore_37_ram_aux_clk,
  input          sigFromSrams_bore_37_ram_aux_ckbp,
  input          sigFromSrams_bore_37_ram_mcp_hold,
  input          sigFromSrams_bore_37_cgen,
  input          sigFromSrams_bore_38_ram_hold,
  input          sigFromSrams_bore_38_ram_bypass,
  input          sigFromSrams_bore_38_ram_bp_clken,
  input          sigFromSrams_bore_38_ram_aux_clk,
  input          sigFromSrams_bore_38_ram_aux_ckbp,
  input          sigFromSrams_bore_38_ram_mcp_hold,
  input          sigFromSrams_bore_38_cgen,
  input          sigFromSrams_bore_39_ram_hold,
  input          sigFromSrams_bore_39_ram_bypass,
  input          sigFromSrams_bore_39_ram_bp_clken,
  input          sigFromSrams_bore_39_ram_aux_clk,
  input          sigFromSrams_bore_39_ram_aux_ckbp,
  input          sigFromSrams_bore_39_ram_mcp_hold,
  input          sigFromSrams_bore_39_cgen,
  output [600:0] gatewayIn_packed_41_bore
  // END GENERATED
);

  // BEGIN GENERATED(dcache-body)
  // ---- 子模块输出线（<简称>_<端口名去掉 io_>）----
  // CtrlUnit cacheCtrlOpt
  logic ctrl_pseudoError_0_valid;
  logic ctrl_pseudoError_0_bits_0_valid;
  logic [63:0] ctrl_pseudoError_0_bits_0_mask;
  logic ctrl_pseudoError_1_valid;
  logic ctrl_pseudoError_1_bits_0_valid;
  logic [63:0] ctrl_pseudoError_1_bits_0_mask;
  logic ctrl_pseudoError_1_bits_1_valid;
  logic [63:0] ctrl_pseudoError_1_bits_1_mask;
  logic ctrl_pseudoError_1_bits_2_valid;
  logic [63:0] ctrl_pseudoError_1_bits_2_mask;
  logic ctrl_pseudoError_1_bits_3_valid;
  logic [63:0] ctrl_pseudoError_1_bits_3_mask;
  logic ctrl_pseudoError_1_bits_4_valid;
  logic [63:0] ctrl_pseudoError_1_bits_4_mask;
  logic ctrl_pseudoError_1_bits_5_valid;
  logic [63:0] ctrl_pseudoError_1_bits_5_mask;
  logic ctrl_pseudoError_1_bits_6_valid;
  logic [63:0] ctrl_pseudoError_1_bits_6_mask;
  logic ctrl_pseudoError_1_bits_7_valid;
  logic [63:0] ctrl_pseudoError_1_bits_7_mask;
  // BankedDataArray bankedDataArray
  logic data_array_read_0_ready;
  logic data_array_read_1_ready;
  logic data_array_read_2_ready;
  logic data_array_readline_ready;
  logic [63:0] data_array_readline_resp_0_raw_data;
  logic [63:0] data_array_readline_resp_1_raw_data;
  logic [63:0] data_array_readline_resp_2_raw_data;
  logic [63:0] data_array_readline_resp_3_raw_data;
  logic [63:0] data_array_readline_resp_4_raw_data;
  logic [63:0] data_array_readline_resp_5_raw_data;
  logic [63:0] data_array_readline_resp_6_raw_data;
  logic [63:0] data_array_readline_resp_7_raw_data;
  logic data_array_readline_error_delayed;
  logic [63:0] data_array_read_resp_0_0_raw_data;
  logic [63:0] data_array_read_resp_0_1_raw_data;
  logic [63:0] data_array_read_resp_1_0_raw_data;
  logic [63:0] data_array_read_resp_1_1_raw_data;
  logic [63:0] data_array_read_resp_2_0_raw_data;
  logic [63:0] data_array_read_resp_2_1_raw_data;
  logic data_array_read_error_delayed_0_0;
  logic data_array_read_error_delayed_0_1;
  logic data_array_read_error_delayed_1_0;
  logic data_array_read_error_delayed_1_1;
  logic data_array_read_error_delayed_2_0;
  logic data_array_read_error_delayed_2_1;
  logic data_array_bank_conflict_slow_0;
  logic data_array_bank_conflict_slow_1;
  logic data_array_bank_conflict_slow_2;
  logic data_array_disable_ld_fast_wakeup_0;
  logic data_array_disable_ld_fast_wakeup_1;
  logic data_array_disable_ld_fast_wakeup_2;
  logic data_array_pseudo_error_ready;
  // L1CohMetaArray metaArray
  logic [1:0] meta_array_resp_0_0_coh_state;
  logic [1:0] meta_array_resp_0_1_coh_state;
  logic [1:0] meta_array_resp_0_2_coh_state;
  logic [1:0] meta_array_resp_0_3_coh_state;
  logic [1:0] meta_array_resp_1_0_coh_state;
  logic [1:0] meta_array_resp_1_1_coh_state;
  logic [1:0] meta_array_resp_1_2_coh_state;
  logic [1:0] meta_array_resp_1_3_coh_state;
  logic [1:0] meta_array_resp_2_0_coh_state;
  logic [1:0] meta_array_resp_2_1_coh_state;
  logic [1:0] meta_array_resp_2_2_coh_state;
  logic [1:0] meta_array_resp_2_3_coh_state;
  logic [1:0] meta_array_resp_3_0_coh_state;
  logic [1:0] meta_array_resp_3_1_coh_state;
  logic [1:0] meta_array_resp_3_2_coh_state;
  logic [1:0] meta_array_resp_3_3_coh_state;
  // L1ErrorMetaArray errorArray
  logic error_array_resp_0_0_tl_denied;
  logic error_array_resp_0_0_tl_corrupt;
  logic error_array_resp_0_1_tl_denied;
  logic error_array_resp_0_1_tl_corrupt;
  logic error_array_resp_0_2_tl_denied;
  logic error_array_resp_0_2_tl_corrupt;
  logic error_array_resp_0_3_tl_denied;
  logic error_array_resp_0_3_tl_corrupt;
  logic error_array_resp_1_0_tl_denied;
  logic error_array_resp_1_0_tl_corrupt;
  logic error_array_resp_1_1_tl_denied;
  logic error_array_resp_1_1_tl_corrupt;
  logic error_array_resp_1_2_tl_denied;
  logic error_array_resp_1_2_tl_corrupt;
  logic error_array_resp_1_3_tl_denied;
  logic error_array_resp_1_3_tl_corrupt;
  logic error_array_resp_2_0_tl_denied;
  logic error_array_resp_2_0_tl_corrupt;
  logic error_array_resp_2_1_tl_denied;
  logic error_array_resp_2_1_tl_corrupt;
  logic error_array_resp_2_2_tl_denied;
  logic error_array_resp_2_2_tl_corrupt;
  logic error_array_resp_2_3_tl_denied;
  logic error_array_resp_2_3_tl_corrupt;
  logic error_array_resp_3_0_tl_denied;
  logic error_array_resp_3_0_tl_corrupt;
  logic error_array_resp_3_1_tl_denied;
  logic error_array_resp_3_1_tl_corrupt;
  logic error_array_resp_3_2_tl_denied;
  logic error_array_resp_3_2_tl_corrupt;
  logic error_array_resp_3_3_tl_denied;
  logic error_array_resp_3_3_tl_corrupt;
  // L1PrefetchSourceArray prefetchArray
  logic [2:0] pf_array_resp_0_0;
  logic [2:0] pf_array_resp_0_1;
  logic [2:0] pf_array_resp_0_2;
  logic [2:0] pf_array_resp_0_3;
  logic [2:0] pf_array_resp_1_0;
  logic [2:0] pf_array_resp_1_1;
  logic [2:0] pf_array_resp_1_2;
  logic [2:0] pf_array_resp_1_3;
  logic [2:0] pf_array_resp_2_0;
  logic [2:0] pf_array_resp_2_1;
  logic [2:0] pf_array_resp_2_2;
  logic [2:0] pf_array_resp_2_3;
  logic [2:0] pf_array_resp_3_0;
  logic [2:0] pf_array_resp_3_1;
  logic [2:0] pf_array_resp_3_2;
  logic [2:0] pf_array_resp_3_3;
  logic [2:0] pf_array_resp_4_0;
  logic [2:0] pf_array_resp_4_1;
  logic [2:0] pf_array_resp_4_2;
  logic [2:0] pf_array_resp_4_3;
  // L1FlagMetaArray accessArray
  logic access_array_resp_0_0;
  logic access_array_resp_0_1;
  logic access_array_resp_0_2;
  logic access_array_resp_0_3;
  logic access_array_resp_1_0;
  logic access_array_resp_1_1;
  logic access_array_resp_1_2;
  logic access_array_resp_1_3;
  logic access_array_resp_2_0;
  logic access_array_resp_2_1;
  logic access_array_resp_2_2;
  logic access_array_resp_2_3;
  logic access_array_resp_3_0;
  logic access_array_resp_3_1;
  logic access_array_resp_3_2;
  logic access_array_resp_3_3;
  logic access_array_resp_4_0;
  logic access_array_resp_4_1;
  logic access_array_resp_4_2;
  logic access_array_resp_4_3;
  // DuplicatedTagArray tagArray
  logic tag_array_read_3_ready;
  logic [42:0] tag_array_resp_0_0;
  logic [42:0] tag_array_resp_0_1;
  logic [42:0] tag_array_resp_0_2;
  logic [42:0] tag_array_resp_0_3;
  logic [42:0] tag_array_resp_1_0;
  logic [42:0] tag_array_resp_1_1;
  logic [42:0] tag_array_resp_1_2;
  logic [42:0] tag_array_resp_1_3;
  logic [42:0] tag_array_resp_2_0;
  logic [42:0] tag_array_resp_2_1;
  logic [42:0] tag_array_resp_2_2;
  logic [42:0] tag_array_resp_2_3;
  logic [42:0] tag_array_resp_3_0;
  logic [42:0] tag_array_resp_3_1;
  logic [42:0] tag_array_resp_3_2;
  logic [42:0] tag_array_resp_3_3;
  // BloomFilter bloomFilter
  logic bloom_resp_0_valid;
  logic bloom_resp_0_bits_res;
  logic bloom_resp_1_valid;
  logic bloom_resp_1_bits_res;
  logic bloom_resp_2_valid;
  logic bloom_resp_2_bits_res;
  // CounterFilter counterFilter
  logic counter_filter_query_0_resp;
  logic counter_filter_query_1_resp;
  logic counter_filter_query_2_resp;
  // LoadPipe ldu_0
  logic ldu0_lsu_req_ready;
  logic ldu0_meta_read_valid;
  logic [7:0] ldu0_meta_read_bits_idx;
  logic ldu0_tag_read_valid;
  logic [7:0] ldu0_tag_read_bits_idx;
  logic ldu0_banked_data_read_valid;
  logic [3:0] ldu0_banked_data_read_bits_way_en;
  logic [47:0] ldu0_banked_data_read_bits_addr;
  logic [47:0] ldu0_banked_data_read_bits_addr_dup;
  logic [7:0] ldu0_banked_data_read_bits_bankMask;
  logic ldu0_banked_data_read_bits_lqIdx_flag;
  logic [6:0] ldu0_banked_data_read_bits_lqIdx_value;
  logic ldu0_is128Req;
  logic ldu0_access_flag_write_valid;
  logic [7:0] ldu0_access_flag_write_bits_idx;
  logic [3:0] ldu0_access_flag_write_bits_way_en;
  logic ldu0_prefetch_flag_write_valid;
  logic [7:0] ldu0_prefetch_flag_write_bits_idx;
  logic [3:0] ldu0_prefetch_flag_write_bits_way_en;
  logic ldu0_miss_req_valid;
  logic [3:0] ldu0_miss_req_bits_source;
  logic [2:0] ldu0_miss_req_bits_pf_source;
  logic [4:0] ldu0_miss_req_bits_cmd;
  logic [47:0] ldu0_miss_req_bits_addr;
  logic [49:0] ldu0_miss_req_bits_vaddr;
  logic [1:0] ldu0_miss_req_bits_req_coh_state;
  logic ldu0_miss_req_bits_isBtoT;
  logic [3:0] ldu0_miss_req_bits_occupy_way;
  logic ldu0_miss_req_bits_cancel;
  logic ldu0_wbq_conflict_check_valid;
  logic [47:0] ldu0_wbq_conflict_check_bits;
  logic ldu0_replace_access_valid;
  logic [7:0] ldu0_replace_access_bits_set;
  logic [1:0] ldu0_replace_access_bits_way;
  logic [7:0] ldu0_occupy_set;
  logic ldu0_error_valid;
  logic [47:0] ldu0_error_bits_paddr;
  logic ldu0_error_bits_report_to_beu;
  logic ldu0_pseudo_tag_error_inj_done;
  logic ldu0_pseudo_data_error_inj_done;
  logic ldu0_prefetch_info_naive_total_prefetch;
  logic ldu0_prefetch_info_naive_late_hit_prefetch;
  logic ldu0_prefetch_info_naive_late_prefetch_hit;
  logic ldu0_prefetch_info_naive_late_load_hit;
  logic ldu0_prefetch_info_naive_useful_prefetch;
  logic ldu0_prefetch_info_naive_prefetch_hit;
  logic ldu0_prefetch_info_fdp_useful_prefetch;
  logic ldu0_prefetch_info_fdp_demand_miss;
  logic ldu0_prefetch_info_fdp_pollution;
  logic ldu0_bloom_filter_query_query_valid;
  logic [11:0] ldu0_bloom_filter_query_query_bits_addr;
  logic ldu0_counter_filter_query_req_valid;
  logic [7:0] ldu0_counter_filter_query_req_bits_idx;
  logic [1:0] ldu0_counter_filter_query_req_bits_way;
  logic ldu0_counter_filter_enq_valid;
  logic [7:0] ldu0_counter_filter_enq_bits_idx;
  logic [1:0] ldu0_counter_filter_enq_bits_way;
  logic [5:0] ldu0_perf_0_value;
  logic [5:0] ldu0_perf_1_value;
  logic [5:0] ldu0_perf_2_value;
  logic [5:0] ldu0_perf_3_value;
  logic [5:0] ldu0_perf_4_value;
  logic [5:0] ldu0_perf_5_value;
  logic [5:0] ldu0_perf_6_value;
  // LoadPipe ldu_1
  logic ldu1_lsu_req_ready;
  logic ldu1_meta_read_valid;
  logic [7:0] ldu1_meta_read_bits_idx;
  logic ldu1_tag_read_valid;
  logic [7:0] ldu1_tag_read_bits_idx;
  logic ldu1_banked_data_read_valid;
  logic [3:0] ldu1_banked_data_read_bits_way_en;
  logic [47:0] ldu1_banked_data_read_bits_addr;
  logic [47:0] ldu1_banked_data_read_bits_addr_dup;
  logic [7:0] ldu1_banked_data_read_bits_bankMask;
  logic ldu1_banked_data_read_bits_lqIdx_flag;
  logic [6:0] ldu1_banked_data_read_bits_lqIdx_value;
  logic ldu1_is128Req;
  logic ldu1_access_flag_write_valid;
  logic [7:0] ldu1_access_flag_write_bits_idx;
  logic [3:0] ldu1_access_flag_write_bits_way_en;
  logic ldu1_prefetch_flag_write_valid;
  logic [7:0] ldu1_prefetch_flag_write_bits_idx;
  logic [3:0] ldu1_prefetch_flag_write_bits_way_en;
  logic ldu1_miss_req_valid;
  logic [3:0] ldu1_miss_req_bits_source;
  logic [2:0] ldu1_miss_req_bits_pf_source;
  logic [4:0] ldu1_miss_req_bits_cmd;
  logic [47:0] ldu1_miss_req_bits_addr;
  logic [49:0] ldu1_miss_req_bits_vaddr;
  logic [1:0] ldu1_miss_req_bits_req_coh_state;
  logic ldu1_miss_req_bits_isBtoT;
  logic [3:0] ldu1_miss_req_bits_occupy_way;
  logic ldu1_miss_req_bits_cancel;
  logic ldu1_wbq_conflict_check_valid;
  logic [47:0] ldu1_wbq_conflict_check_bits;
  logic ldu1_replace_access_valid;
  logic [7:0] ldu1_replace_access_bits_set;
  logic [1:0] ldu1_replace_access_bits_way;
  logic [7:0] ldu1_occupy_set;
  logic ldu1_error_valid;
  logic [47:0] ldu1_error_bits_paddr;
  logic ldu1_error_bits_report_to_beu;
  logic ldu1_pseudo_tag_error_inj_done;
  logic ldu1_pseudo_data_error_inj_done;
  logic ldu1_prefetch_info_naive_total_prefetch;
  logic ldu1_prefetch_info_naive_late_hit_prefetch;
  logic ldu1_prefetch_info_naive_late_prefetch_hit;
  logic ldu1_prefetch_info_naive_late_load_hit;
  logic ldu1_prefetch_info_naive_useful_prefetch;
  logic ldu1_prefetch_info_naive_prefetch_hit;
  logic ldu1_prefetch_info_fdp_useful_prefetch;
  logic ldu1_prefetch_info_fdp_demand_miss;
  logic ldu1_prefetch_info_fdp_pollution;
  logic ldu1_bloom_filter_query_query_valid;
  logic [11:0] ldu1_bloom_filter_query_query_bits_addr;
  logic ldu1_counter_filter_query_req_valid;
  logic [7:0] ldu1_counter_filter_query_req_bits_idx;
  logic [1:0] ldu1_counter_filter_query_req_bits_way;
  logic ldu1_counter_filter_enq_valid;
  logic [7:0] ldu1_counter_filter_enq_bits_idx;
  logic [1:0] ldu1_counter_filter_enq_bits_way;
  logic [5:0] ldu1_perf_0_value;
  logic [5:0] ldu1_perf_1_value;
  logic [5:0] ldu1_perf_2_value;
  logic [5:0] ldu1_perf_3_value;
  logic [5:0] ldu1_perf_4_value;
  logic [5:0] ldu1_perf_5_value;
  logic [5:0] ldu1_perf_6_value;
  // LoadPipe ldu_2
  logic ldu2_lsu_req_ready;
  logic ldu2_meta_read_valid;
  logic [7:0] ldu2_meta_read_bits_idx;
  logic ldu2_tag_read_valid;
  logic [7:0] ldu2_tag_read_bits_idx;
  logic ldu2_banked_data_read_valid;
  logic [3:0] ldu2_banked_data_read_bits_way_en;
  logic [47:0] ldu2_banked_data_read_bits_addr;
  logic [47:0] ldu2_banked_data_read_bits_addr_dup;
  logic [7:0] ldu2_banked_data_read_bits_bankMask;
  logic ldu2_banked_data_read_bits_lqIdx_flag;
  logic [6:0] ldu2_banked_data_read_bits_lqIdx_value;
  logic ldu2_is128Req;
  logic ldu2_access_flag_write_valid;
  logic [7:0] ldu2_access_flag_write_bits_idx;
  logic [3:0] ldu2_access_flag_write_bits_way_en;
  logic ldu2_prefetch_flag_write_valid;
  logic [7:0] ldu2_prefetch_flag_write_bits_idx;
  logic [3:0] ldu2_prefetch_flag_write_bits_way_en;
  logic ldu2_miss_req_valid;
  logic [3:0] ldu2_miss_req_bits_source;
  logic [2:0] ldu2_miss_req_bits_pf_source;
  logic [4:0] ldu2_miss_req_bits_cmd;
  logic [47:0] ldu2_miss_req_bits_addr;
  logic [49:0] ldu2_miss_req_bits_vaddr;
  logic [1:0] ldu2_miss_req_bits_req_coh_state;
  logic ldu2_miss_req_bits_isBtoT;
  logic [3:0] ldu2_miss_req_bits_occupy_way;
  logic ldu2_miss_req_bits_cancel;
  logic ldu2_wbq_conflict_check_valid;
  logic [47:0] ldu2_wbq_conflict_check_bits;
  logic ldu2_replace_access_valid;
  logic [7:0] ldu2_replace_access_bits_set;
  logic [1:0] ldu2_replace_access_bits_way;
  logic [7:0] ldu2_occupy_set;
  logic ldu2_error_valid;
  logic [47:0] ldu2_error_bits_paddr;
  logic ldu2_error_bits_report_to_beu;
  logic ldu2_pseudo_tag_error_inj_done;
  logic ldu2_pseudo_data_error_inj_done;
  logic ldu2_prefetch_info_naive_total_prefetch;
  logic ldu2_prefetch_info_naive_late_hit_prefetch;
  logic ldu2_prefetch_info_naive_late_prefetch_hit;
  logic ldu2_prefetch_info_naive_late_load_hit;
  logic ldu2_prefetch_info_naive_useful_prefetch;
  logic ldu2_prefetch_info_naive_prefetch_hit;
  logic ldu2_prefetch_info_fdp_useful_prefetch;
  logic ldu2_prefetch_info_fdp_demand_miss;
  logic ldu2_prefetch_info_fdp_pollution;
  logic ldu2_bloom_filter_query_query_valid;
  logic [11:0] ldu2_bloom_filter_query_query_bits_addr;
  logic ldu2_counter_filter_query_req_valid;
  logic [7:0] ldu2_counter_filter_query_req_bits_idx;
  logic [1:0] ldu2_counter_filter_query_req_bits_way;
  logic ldu2_counter_filter_enq_valid;
  logic [7:0] ldu2_counter_filter_enq_bits_idx;
  logic [1:0] ldu2_counter_filter_enq_bits_way;
  logic [5:0] ldu2_perf_0_value;
  logic [5:0] ldu2_perf_1_value;
  logic [5:0] ldu2_perf_2_value;
  logic [5:0] ldu2_perf_3_value;
  logic [5:0] ldu2_perf_4_value;
  logic [5:0] ldu2_perf_5_value;
  logic [5:0] ldu2_perf_6_value;
  // MainPipe mainPipe
  logic mp_probe_req_ready;
  logic mp_miss_req_valid;
  logic [3:0] mp_miss_req_bits_source;
  logic [4:0] mp_miss_req_bits_cmd;
  logic [47:0] mp_miss_req_bits_addr;
  logic [49:0] mp_miss_req_bits_vaddr;
  logic mp_miss_req_bits_full_overwrite;
  logic [2:0] mp_miss_req_bits_word_idx;
  logic [127:0] mp_miss_req_bits_amo_data;
  logic [15:0] mp_miss_req_bits_amo_mask;
  logic [127:0] mp_miss_req_bits_amo_cmp;
  logic [1:0] mp_miss_req_bits_req_coh_state;
  logic [5:0] mp_miss_req_bits_id;
  logic mp_miss_req_bits_isBtoT;
  logic [3:0] mp_miss_req_bits_occupy_way;
  logic mp_miss_req_bits_cancel;
  logic [511:0] mp_miss_req_bits_store_data;
  logic [63:0] mp_miss_req_bits_store_mask;
  logic mp_refill_req_ready;
  logic mp_wbq_conflict_check_valid;
  logic [47:0] mp_wbq_conflict_check_bits;
  logic mp_store_replay_resp_valid;
  logic [5:0] mp_store_replay_resp_bits_id;
  logic mp_atomic_resp_valid;
  logic [3:0] mp_atomic_resp_bits_source;
  logic [127:0] mp_atomic_resp_bits_data;
  logic mp_atomic_resp_bits_miss;
  logic [3:0] mp_atomic_resp_bits_miss_id;
  logic mp_atomic_resp_bits_replay;
  logic mp_atomic_resp_bits_tl_error_tl_denied;
  logic mp_atomic_resp_bits_tl_error_tl_corrupt;
  logic mp_atomic_resp_bits_ack_miss_queue;
  logic [5:0] mp_atomic_resp_bits_id;
  logic mp_mainpipe_info_s2_valid;
  logic [3:0] mp_mainpipe_info_s2_miss_id;
  logic mp_mainpipe_info_s2_replay_to_mq;
  logic mp_mainpipe_info_s2_evict_BtoT_way;
  logic [3:0] mp_mainpipe_info_s2_next_evict_way;
  logic mp_mainpipe_info_s3_valid;
  logic [3:0] mp_mainpipe_info_s3_miss_id;
  logic mp_mainpipe_info_s3_refill_resp;
  logic mp_wb_valid;
  logic [2:0] mp_wb_bits_param;
  logic mp_wb_bits_voluntary;
  logic mp_wb_bits_hasData;
  logic mp_wb_bits_corrupt;
  logic mp_wb_bits_dirty;
  logic [47:0] mp_wb_bits_addr;
  logic [511:0] mp_wb_bits_data;
  logic mp_data_read_intend;
  logic mp_data_readline_valid;
  logic [3:0] mp_data_readline_bits_way_en;
  logic [47:0] mp_data_readline_bits_addr;
  logic [7:0] mp_data_readline_bits_rmask;
  logic mp_data_readline_can_go;
  logic mp_data_readline_stall;
  logic mp_data_readline_can_resp;
  logic mp_data_write_valid;
  logic [7:0] mp_data_write_bits_wmask;
  logic [63:0] mp_data_write_bits_data_0;
  logic [63:0] mp_data_write_bits_data_1;
  logic [63:0] mp_data_write_bits_data_2;
  logic [63:0] mp_data_write_bits_data_3;
  logic [63:0] mp_data_write_bits_data_4;
  logic [63:0] mp_data_write_bits_data_5;
  logic [63:0] mp_data_write_bits_data_6;
  logic [63:0] mp_data_write_bits_data_7;
  logic mp_data_write_dup_0_valid;
  logic [3:0] mp_data_write_dup_0_bits_way_en;
  logic [47:0] mp_data_write_dup_0_bits_addr;
  logic mp_data_write_dup_1_valid;
  logic [3:0] mp_data_write_dup_1_bits_way_en;
  logic [47:0] mp_data_write_dup_1_bits_addr;
  logic mp_data_write_dup_2_valid;
  logic [3:0] mp_data_write_dup_2_bits_way_en;
  logic [47:0] mp_data_write_dup_2_bits_addr;
  logic mp_data_write_dup_3_valid;
  logic [3:0] mp_data_write_dup_3_bits_way_en;
  logic [47:0] mp_data_write_dup_3_bits_addr;
  logic mp_data_write_dup_4_valid;
  logic [3:0] mp_data_write_dup_4_bits_way_en;
  logic [47:0] mp_data_write_dup_4_bits_addr;
  logic mp_data_write_dup_5_valid;
  logic [3:0] mp_data_write_dup_5_bits_way_en;
  logic [47:0] mp_data_write_dup_5_bits_addr;
  logic mp_data_write_dup_6_valid;
  logic [3:0] mp_data_write_dup_6_bits_way_en;
  logic [47:0] mp_data_write_dup_6_bits_addr;
  logic mp_data_write_dup_7_valid;
  logic [3:0] mp_data_write_dup_7_bits_way_en;
  logic [47:0] mp_data_write_dup_7_bits_addr;
  logic mp_meta_read_valid;
  logic [7:0] mp_meta_read_bits_idx;
  logic mp_meta_write_valid;
  logic [7:0] mp_meta_write_bits_idx;
  logic [3:0] mp_meta_write_bits_way_en;
  logic [1:0] mp_meta_write_bits_meta_coh_state;
  logic mp_error_flag_write_valid;
  logic [7:0] mp_error_flag_write_bits_idx;
  logic [3:0] mp_error_flag_write_bits_way_en;
  logic mp_error_flag_write_bits_error_tl_denied;
  logic mp_error_flag_write_bits_error_tl_corrupt;
  logic mp_prefetch_flag_write_valid;
  logic [7:0] mp_prefetch_flag_write_bits_idx;
  logic [3:0] mp_prefetch_flag_write_bits_way_en;
  logic [2:0] mp_prefetch_flag_write_bits_source;
  logic mp_access_flag_write_valid;
  logic [7:0] mp_access_flag_write_bits_idx;
  logic [3:0] mp_access_flag_write_bits_way_en;
  logic mp_access_flag_write_bits_flag;
  logic mp_tag_read_valid;
  logic [7:0] mp_tag_read_bits_idx;
  logic mp_tag_write_valid;
  logic [7:0] mp_tag_write_bits_idx;
  logic [3:0] mp_tag_write_bits_way_en;
  logic [35:0] mp_tag_write_bits_tag;
  logic mp_tag_write_intend;
  logic mp_replace_access_valid;
  logic [7:0] mp_replace_access_bits_set;
  logic [1:0] mp_replace_access_bits_way;
  logic [7:0] mp_replace_way_set_bits;
  logic [7:0] mp_evict_set;
  logic [47:0] mp_replace_req_bits_addr;
  logic [49:0] mp_replace_req_bits_vaddr;
  logic mp_lrsc_locked_block_valid;
  logic [47:0] mp_lrsc_locked_block_bits;
  logic mp_update_resv_set;
  logic mp_error_valid;
  logic [47:0] mp_error_bits_paddr;
  logic mp_error_bits_report_to_beu;
  logic mp_pseudo_tag_error_inj_done;
  logic mp_pseudo_data_error_inj_done;
  logic mp_bloom_filter_query_set_valid;
  logic [11:0] mp_bloom_filter_query_set_bits_addr;
  logic mp_bloom_filter_query_clr_valid;
  logic [11:0] mp_bloom_filter_query_clr_bits_addr;
  logic [5:0] mp_perf_0_value;
  logic [5:0] mp_perf_1_value;
  logic [5:0] mp_perf_2_value;
  logic [5:0] mp_perf_3_value;
  // MissQueue missQueue
  logic mq_req_ready;
  logic [3:0] mq_resp_id;
  logic mq_resp_handled;
  logic mq_resp_merged;
  logic mq_queryMQ_0_ready;
  logic mq_queryMQ_1_ready;
  logic mq_queryMQ_2_ready;
  logic mq_queryMQ_3_ready;
  logic mq_mem_acquire_valid;
  logic [47:0] mq_mem_acquire_bits_address;
  logic mq_mem_grant_ready;
  logic mq_main_pipe_req_valid;
  logic [3:0] mq_main_pipe_req_bits_miss_id;
  logic [3:0] mq_main_pipe_req_bits_occupy_way;
  logic mq_main_pipe_req_bits_miss_fail_cause_evict_btot;
  logic [3:0] mq_main_pipe_req_bits_source;
  logic [4:0] mq_main_pipe_req_bits_cmd;
  logic [49:0] mq_main_pipe_req_bits_vaddr;
  logic [47:0] mq_main_pipe_req_bits_addr;
  logic [2:0] mq_main_pipe_req_bits_word_idx;
  logic [127:0] mq_main_pipe_req_bits_amo_data;
  logic [15:0] mq_main_pipe_req_bits_amo_mask;
  logic [127:0] mq_main_pipe_req_bits_amo_cmp;
  logic [2:0] mq_main_pipe_req_bits_pf_source;
  logic mq_main_pipe_req_bits_access;
  logic [5:0] mq_main_pipe_req_bits_id;
  logic mq_refill_info_valid;
  logic [511:0] mq_refill_info_bits_store_data;
  logic [63:0] mq_refill_info_bits_store_mask;
  logic [1:0] mq_refill_info_bits_miss_param;
  logic mq_refill_info_bits_error_tl_denied;
  logic mq_refill_info_bits_error_tl_corrupt;
  logic mq_probe_block;
  logic mq_replace_block;
  logic [3:0] mq_btot_ways_for_set;
  logic mq_occupy_fail_0;
  logic mq_occupy_fail_1;
  logic mq_occupy_fail_2;
  logic mq_prefetch_info_naive_late_miss_prefetch;
  logic mq_prefetch_info_fdp_late_miss_prefetch;
  logic [5:0] mq_perf_0_value;
  logic [5:0] mq_perf_1_value;
  logic [5:0] mq_perf_2_value;
  logic [5:0] mq_perf_3_value;
  logic [5:0] mq_perf_4_value;
  // ProbeQueue probeQueue
  logic pq_mem_probe_ready;
  logic pq_pipe_req_valid;
  logic [1:0] pq_pipe_req_bits_probe_param;
  logic pq_pipe_req_bits_probe_need_data;
  logic [49:0] pq_pipe_req_bits_vaddr;
  logic [47:0] pq_pipe_req_bits_addr;
  logic [5:0] pq_pipe_req_bits_id;
  logic [5:0] pq_perf_0_value;
  logic [5:0] pq_perf_1_value;
  logic [5:0] pq_perf_2_value;
  logic [5:0] pq_perf_3_value;
  logic [5:0] pq_perf_4_value;
  // WritebackQueue wb
  logic wbq_req_ready;
  logic wbq_mem_release_valid;
  logic [47:0] wbq_mem_release_bits_address;
  logic wbq_block_miss_req_0;
  logic wbq_block_miss_req_1;
  logic wbq_block_miss_req_2;
  logic wbq_block_miss_req_3;
  logic wbq_block_miss_req_4;
  logic [5:0] wbq_perf_0_value;
  logic [5:0] wbq_perf_1_value;
  logic [5:0] wbq_perf_2_value;
  logic [5:0] wbq_perf_3_value;
  logic [5:0] wbq_perf_4_value;
  // Arbiter1_TagWriteReq tag_write_arb
  logic tag_write_arb_out_valid;
  logic [7:0] tag_write_arb_out_bits_idx;
  logic [3:0] tag_write_arb_out_bits_way_en;
  logic [35:0] tag_write_arb_out_bits_tag;
  // Arbiter1_L1BankedDataWriteReq dataWriteArb
  logic data_write_arb_out_valid;
  logic [7:0] data_write_arb_out_bits_wmask;
  logic [63:0] data_write_arb_out_bits_data_0;
  logic [63:0] data_write_arb_out_bits_data_1;
  logic [63:0] data_write_arb_out_bits_data_2;
  logic [63:0] data_write_arb_out_bits_data_3;
  logic [63:0] data_write_arb_out_bits_data_4;
  logic [63:0] data_write_arb_out_bits_data_5;
  logic [63:0] data_write_arb_out_bits_data_6;
  logic [63:0] data_write_arb_out_bits_data_7;
  // Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup
  logic data_write_arb_dup0_out_valid;
  logic [3:0] data_write_arb_dup0_out_bits_way_en;
  logic [47:0] data_write_arb_dup0_out_bits_addr;
  // Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_1
  logic data_write_arb_dup1_out_valid;
  logic [3:0] data_write_arb_dup1_out_bits_way_en;
  logic [47:0] data_write_arb_dup1_out_bits_addr;
  // Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_2
  logic data_write_arb_dup2_out_valid;
  logic [3:0] data_write_arb_dup2_out_bits_way_en;
  logic [47:0] data_write_arb_dup2_out_bits_addr;
  // Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_3
  logic data_write_arb_dup3_out_valid;
  logic [3:0] data_write_arb_dup3_out_bits_way_en;
  logic [47:0] data_write_arb_dup3_out_bits_addr;
  // Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_4
  logic data_write_arb_dup4_out_valid;
  logic [3:0] data_write_arb_dup4_out_bits_way_en;
  logic [47:0] data_write_arb_dup4_out_bits_addr;
  // Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_5
  logic data_write_arb_dup5_out_valid;
  logic [3:0] data_write_arb_dup5_out_bits_way_en;
  logic [47:0] data_write_arb_dup5_out_bits_addr;
  // Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_6
  logic data_write_arb_dup6_out_valid;
  logic [3:0] data_write_arb_dup6_out_bits_way_en;
  logic [47:0] data_write_arb_dup6_out_bits_addr;
  // Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_7
  logic data_write_arb_dup7_out_valid;
  logic [3:0] data_write_arb_dup7_out_bits_way_en;
  logic [47:0] data_write_arb_dup7_out_bits_addr;
  // TreeArbiter missReqArb
  logic miss_req_arb_in_0_ready;
  logic miss_req_arb_in_1_ready;
  logic miss_req_arb_in_2_ready;
  logic miss_req_arb_in_3_ready;
  logic miss_req_arb_out_valid;
  logic [3:0] miss_req_arb_out_bits_source;
  logic [2:0] miss_req_arb_out_bits_pf_source;
  logic [4:0] miss_req_arb_out_bits_cmd;
  logic [47:0] miss_req_arb_out_bits_addr;
  logic [49:0] miss_req_arb_out_bits_vaddr;
  logic miss_req_arb_out_bits_full_overwrite;
  logic [2:0] miss_req_arb_out_bits_word_idx;
  logic [127:0] miss_req_arb_out_bits_amo_data;
  logic [15:0] miss_req_arb_out_bits_amo_mask;
  logic [127:0] miss_req_arb_out_bits_amo_cmp;
  logic [1:0] miss_req_arb_out_bits_req_coh_state;
  logic [5:0] miss_req_arb_out_bits_id;
  logic miss_req_arb_out_bits_isBtoT;
  logic [3:0] miss_req_arb_out_bits_occupy_way;
  logic miss_req_arb_out_bits_cancel;
  logic [511:0] miss_req_arb_out_bits_store_data;
  logic [63:0] miss_req_arb_out_bits_store_mask;
  // MissReadyGen missReadyGen
  logic miss_ready_gen_in_0_ready;
  logic miss_ready_gen_in_1_ready;
  logic miss_ready_gen_in_2_ready;
  logic miss_ready_gen_in_3_ready;
  logic [3:0] miss_ready_gen_queryMQ_0_req_bits_source;
  logic [47:0] miss_ready_gen_queryMQ_0_req_bits_addr;
  logic [49:0] miss_ready_gen_queryMQ_0_req_bits_vaddr;
  logic [3:0] miss_ready_gen_queryMQ_1_req_bits_source;
  logic [47:0] miss_ready_gen_queryMQ_1_req_bits_addr;
  logic [49:0] miss_ready_gen_queryMQ_1_req_bits_vaddr;
  logic [3:0] miss_ready_gen_queryMQ_2_req_bits_source;
  logic [47:0] miss_ready_gen_queryMQ_2_req_bits_addr;
  logic [49:0] miss_ready_gen_queryMQ_2_req_bits_vaddr;
  logic [3:0] miss_ready_gen_queryMQ_3_req_bits_source;
  logic [47:0] miss_ready_gen_queryMQ_3_req_bits_addr;
  logic [49:0] miss_ready_gen_queryMQ_3_req_bits_vaddr;

  // ---- 胶水核的输出线 ----
  logic core_d_ready;
  logic core_mq_grant_valid;
  logic core_wb_grant_valid;
  logic core_tl_d_channel_valid;
  logic [3:0] core_tl_d_channel_mshrid;
  logic [2:0] core_fwd_d_valid;
  logic [2:0][255:0] core_fwd_d_data;
  logic [2:0][3:0] core_fwd_d_mshrid;
  logic [2:0] core_fwd_d_last;
  logic [2:0] core_fwd_d_denied;
  logic [2:0] core_fwd_d_corrupt;
  logic core_b_ready;
  logic core_pq_probe_valid;
  logic [49:0] core_mq_probe_vaddr;
  logic core_mq_l2_hint_valid;
  logic [3:0] core_mq_l2_hint_source_id;
  logic core_mq_l2_pf_store_only;
  logic core_ldu_tag_read_ready;
  logic core_pseudo_tag_error_ready;
  logic core_pseudo_data_error_ready;
  logic [1:0] core_mp_victim_way;
  logic core_lsu_atomic_valid;
  logic [127:0] core_lsu_atomic_data;
  logic core_lsu_atomic_miss;
  logic core_lsu_atomic_replay;
  logic core_lsu_atomic_denied;
  logic core_lsu_atomic_corrupt;
  logic [5:0] core_lsu_atomic_id;
  logic core_mq_mp_resp_valid;
  logic [3:0] core_mq_mp_resp_miss_id;
  logic core_mq_mp_resp_ack_miss_queue;
  logic core_lsu_store_replay_valid;
  logic [5:0] core_lsu_store_replay_id;
  logic core_lsu_release_valid;
  logic [47:0] core_lsu_release_paddr;
  logic core_mp_invalid_resv_set;
  logic core_error_valid;
  logic [47:0] core_error_paddr;
  logic core_error_report_to_beu;
  logic core_pfm_total_prefetch;
  logic core_pfm_late_hit_prefetch;
  logic core_pfm_good_prefetch;
  logic core_pfm_bad_prefetch;
  logic [2:0] core_fdp_useful_prefetch;
  logic [39:0][5:0] core_perf_out;

  xs_DCache_core u_core (
    .clock                     (clock),
    .reset                     (reset),
    .d_valid                   (auto_client_out_d_valid),
    .d_opcode                  (auto_client_out_d_bits_opcode),
    .d_size                    (auto_client_out_d_bits_size),
    .d_source                  (auto_client_out_d_bits_source),
    .d_data                    (auto_client_out_d_bits_data),
    .d_denied                  (auto_client_out_d_bits_denied),
    .d_corrupt                 (auto_client_out_d_bits_corrupt),
    .d_echo_is_keyword         (auto_client_out_d_bits_echo_isKeyword),
    .d_ready                   (core_d_ready),
    .mq_grant_ready            (mq_mem_grant_ready),
    .mq_grant_valid            (core_mq_grant_valid),
    .wb_grant_valid            (core_wb_grant_valid),
    .tl_d_channel_valid        (core_tl_d_channel_valid),
    .tl_d_channel_mshrid       (core_tl_d_channel_mshrid),
    .fwd_d_valid               (core_fwd_d_valid),
    .fwd_d_data                (core_fwd_d_data),
    .fwd_d_mshrid              (core_fwd_d_mshrid),
    .fwd_d_last                (core_fwd_d_last),
    .fwd_d_denied              (core_fwd_d_denied),
    .fwd_d_corrupt             (core_fwd_d_corrupt),
    .b_valid                   (auto_client_out_b_valid),
    .b_address                 (auto_client_out_b_bits_address),
    .b_data                    (auto_client_out_b_bits_data),
    .b_ready                   (core_b_ready),
    .pq_probe_ready            (pq_mem_probe_ready),
    .mq_probe_block            (mq_probe_block),
    .pq_probe_valid            (core_pq_probe_valid),
    .mq_probe_vaddr            (core_mq_probe_vaddr),
    .l2_hint_valid             (io_l2_hint_valid),
    .l2_hint_source_id         (io_l2_hint_bits_sourceId),
    .l2_pf_store_only          (io_l2_pf_store_only),
    .mq_l2_hint_valid          (core_mq_l2_hint_valid),
    .mq_l2_hint_source_id      (core_mq_l2_hint_source_id),
    .mq_l2_pf_store_only       (core_mq_l2_pf_store_only),
    .mp_tag_write_intend       (mp_tag_write_intend),
    .tag_array_write_valid     (tag_write_arb_out_valid),
    .ldu_tag_read_ready        (core_ldu_tag_read_ready),
    .mp_pseudo_tag_inj_done    (mp_pseudo_tag_error_inj_done),
    .ldu_pseudo_tag_inj_done   ({ldu2_pseudo_tag_error_inj_done, ldu1_pseudo_tag_error_inj_done,
                                 ldu0_pseudo_tag_error_inj_done}),
    .mp_pseudo_data_inj_done   (mp_pseudo_data_error_inj_done),
    .ldu_pseudo_data_inj_done  ({ldu2_pseudo_data_error_inj_done, ldu1_pseudo_data_error_inj_done,
                                 ldu0_pseudo_data_error_inj_done}),
    .bda_pseudo_error_ready    (data_array_pseudo_error_ready),
    .pseudo_tag_error_ready    (core_pseudo_tag_error_ready),
    .pseudo_data_error_ready   (core_pseudo_data_error_ready),
    .ldu_repl_valid            ({ldu2_replace_access_valid, ldu1_replace_access_valid,
                                 ldu0_replace_access_valid}),
    .ldu_repl_set              ({ldu2_replace_access_bits_set, ldu1_replace_access_bits_set,
                                 ldu0_replace_access_bits_set}),
    .ldu_repl_way              ({ldu2_replace_access_bits_way, ldu1_replace_access_bits_way,
                                 ldu0_replace_access_bits_way}),
    .mp_repl_valid             (mp_replace_access_valid),
    .mp_repl_set               (mp_replace_access_bits_set),
    .mp_repl_way               (mp_replace_access_bits_way),
    .mp_victim_set             (mp_replace_way_set_bits),
    .mp_victim_way             (core_mp_victim_way),
    .mp_atomic_valid           (mp_atomic_resp_valid),
    .mp_atomic_source          (mp_atomic_resp_bits_source),
    .mp_atomic_data            (mp_atomic_resp_bits_data),
    .mp_atomic_miss            (mp_atomic_resp_bits_miss),
    .mp_atomic_replay          (mp_atomic_resp_bits_replay),
    .mp_atomic_denied          (mp_atomic_resp_bits_tl_error_tl_denied),
    .mp_atomic_corrupt         (mp_atomic_resp_bits_tl_error_tl_corrupt),
    .mp_atomic_id              (mp_atomic_resp_bits_id),
    .mp_atomic_miss_id         (mp_atomic_resp_bits_miss_id),
    .mp_atomic_ack_miss_queue  (mp_atomic_resp_bits_ack_miss_queue),
    .lsu_atomic_valid          (core_lsu_atomic_valid),
    .lsu_atomic_data           (core_lsu_atomic_data),
    .lsu_atomic_miss           (core_lsu_atomic_miss),
    .lsu_atomic_replay         (core_lsu_atomic_replay),
    .lsu_atomic_denied         (core_lsu_atomic_denied),
    .lsu_atomic_corrupt        (core_lsu_atomic_corrupt),
    .lsu_atomic_id             (core_lsu_atomic_id),
    .mq_mp_resp_valid          (core_mq_mp_resp_valid),
    .mq_mp_resp_miss_id        (core_mq_mp_resp_miss_id),
    .mq_mp_resp_ack_miss_queue (core_mq_mp_resp_ack_miss_queue),
    .mp_store_replay_valid     (mp_store_replay_resp_valid),
    .mp_store_replay_id        (mp_store_replay_resp_bits_id),
    .lsu_store_replay_valid    (core_lsu_store_replay_valid),
    .lsu_store_replay_id       (core_lsu_store_replay_id),
    .wb_req_ready              (wbq_req_ready),
    .mp_wb_valid               (mp_wb_valid),
    .mp_wb_addr                (mp_wb_bits_addr),
    .mp_lrsc_valid             (mp_lrsc_locked_block_valid),
    .mp_lrsc_block             (mp_lrsc_locked_block_bits),
    .lsu_release_valid         (core_lsu_release_valid),
    .lsu_release_paddr         (core_lsu_release_paddr),
    .mp_invalid_resv_set       (core_mp_invalid_resv_set),
    .err_valid                 ({ldu2_error_valid, ldu1_error_valid, ldu0_error_valid,
                                 mp_error_valid}),
    .err_paddr                 ({ldu2_error_bits_paddr, ldu1_error_bits_paddr,
                                 ldu0_error_bits_paddr, mp_error_bits_paddr}),
    .err_report_to_beu         ({ldu2_error_bits_report_to_beu, ldu1_error_bits_report_to_beu,
                                 ldu0_error_bits_report_to_beu, mp_error_bits_report_to_beu}),
    .error_valid               (core_error_valid),
    .error_paddr               (core_error_paddr),
    .error_report_to_beu       (core_error_report_to_beu),
    .ldu_pf_total              ({ldu2_prefetch_info_naive_total_prefetch,
                                 ldu1_prefetch_info_naive_total_prefetch,
                                 ldu0_prefetch_info_naive_total_prefetch}),
    .ldu_pf_late_hit           ({ldu2_prefetch_info_naive_late_hit_prefetch,
                                 ldu1_prefetch_info_naive_late_hit_prefetch,
                                 ldu0_prefetch_info_naive_late_hit_prefetch}),
    .mp_pf_flag_write_valid    (mp_prefetch_flag_write_valid),
    .mp_pf_flag_write_way_en   (mp_prefetch_flag_write_bits_way_en),
    .pf_array_last_resp        ({pf_array_resp_4_3, pf_array_resp_4_2, pf_array_resp_4_1,
                                 pf_array_resp_4_0}),
    .access_array_last_resp    ({access_array_resp_4_3, access_array_resp_4_2,
                                 access_array_resp_4_1, access_array_resp_4_0}),
    .ldu_pf_flag_write_valid   ({ldu1_prefetch_flag_write_valid, ldu0_prefetch_flag_write_valid}),
    .ldu_pf_flag_write_idx     ({ldu1_prefetch_flag_write_bits_idx,
                                 ldu0_prefetch_flag_write_bits_idx}),
    .ldu_pf_flag_write_way_en  ({ldu1_prefetch_flag_write_bits_way_en,
                                 ldu0_prefetch_flag_write_bits_way_en}),
    .ldu_fdp_useful            ({ldu2_prefetch_info_fdp_useful_prefetch,
                                 ldu1_prefetch_info_fdp_useful_prefetch,
                                 ldu0_prefetch_info_fdp_useful_prefetch}),
    .pfm_total_prefetch        (core_pfm_total_prefetch),
    .pfm_late_hit_prefetch     (core_pfm_late_hit_prefetch),
    .pfm_good_prefetch         (core_pfm_good_prefetch),
    .pfm_bad_prefetch          (core_pfm_bad_prefetch),
    .fdp_useful_prefetch       (core_fdp_useful_prefetch),
    .perf_in                   ({ldu2_perf_6_value, ldu2_perf_5_value, ldu2_perf_4_value,
                                 ldu2_perf_3_value, ldu2_perf_2_value, ldu2_perf_1_value,
                                 ldu2_perf_0_value, ldu1_perf_6_value, ldu1_perf_5_value,
                                 ldu1_perf_4_value, ldu1_perf_3_value, ldu1_perf_2_value,
                                 ldu1_perf_1_value, ldu1_perf_0_value, ldu0_perf_6_value,
                                 ldu0_perf_5_value, ldu0_perf_4_value, ldu0_perf_3_value,
                                 ldu0_perf_2_value, ldu0_perf_1_value, ldu0_perf_0_value,
                                 pq_perf_4_value, pq_perf_3_value, pq_perf_2_value, pq_perf_1_value,
                                 pq_perf_0_value, mq_perf_4_value, mq_perf_3_value, mq_perf_2_value,
                                 mq_perf_1_value, mq_perf_0_value, mp_perf_3_value, mp_perf_2_value,
                                 mp_perf_1_value, mp_perf_0_value, wbq_perf_4_value,
                                 wbq_perf_3_value, wbq_perf_2_value, wbq_perf_1_value,
                                 wbq_perf_0_value}),
    .perf_out                  (core_perf_out)
  );

  CtrlUnit cacheCtrlOpt (
    .clock                         (clock),
    .reset                         (reset),
    .auto_in_a_ready               (auto_cacheCtrlOpt_in_a_ready),
    .auto_in_a_valid               (auto_cacheCtrlOpt_in_a_valid),
    .auto_in_a_bits_opcode         (auto_cacheCtrlOpt_in_a_bits_opcode),
    .auto_in_a_bits_size           (auto_cacheCtrlOpt_in_a_bits_size),
    .auto_in_a_bits_source         (auto_cacheCtrlOpt_in_a_bits_source),
    .auto_in_a_bits_address        (auto_cacheCtrlOpt_in_a_bits_address),
    .auto_in_a_bits_mask           (auto_cacheCtrlOpt_in_a_bits_mask),
    .auto_in_a_bits_data           (auto_cacheCtrlOpt_in_a_bits_data),
    .auto_in_d_ready               (auto_cacheCtrlOpt_in_d_ready),
    .auto_in_d_valid               (auto_cacheCtrlOpt_in_d_valid),
    .auto_in_d_bits_opcode         (auto_cacheCtrlOpt_in_d_bits_opcode),
    .auto_in_d_bits_size           (auto_cacheCtrlOpt_in_d_bits_size),
    .auto_in_d_bits_source         (auto_cacheCtrlOpt_in_d_bits_source),
    .auto_in_d_bits_data           (auto_cacheCtrlOpt_in_d_bits_data),
    .io_pseudoError_0_ready        (core_pseudo_tag_error_ready),
    .io_pseudoError_0_valid        (ctrl_pseudoError_0_valid),
    .io_pseudoError_0_bits_0_valid (ctrl_pseudoError_0_bits_0_valid),
    .io_pseudoError_0_bits_0_mask  (ctrl_pseudoError_0_bits_0_mask),
    .io_pseudoError_1_ready        (core_pseudo_data_error_ready),
    .io_pseudoError_1_valid        (ctrl_pseudoError_1_valid),
    .io_pseudoError_1_bits_0_valid (ctrl_pseudoError_1_bits_0_valid),
    .io_pseudoError_1_bits_0_mask  (ctrl_pseudoError_1_bits_0_mask),
    .io_pseudoError_1_bits_1_valid (ctrl_pseudoError_1_bits_1_valid),
    .io_pseudoError_1_bits_1_mask  (ctrl_pseudoError_1_bits_1_mask),
    .io_pseudoError_1_bits_2_valid (ctrl_pseudoError_1_bits_2_valid),
    .io_pseudoError_1_bits_2_mask  (ctrl_pseudoError_1_bits_2_mask),
    .io_pseudoError_1_bits_3_valid (ctrl_pseudoError_1_bits_3_valid),
    .io_pseudoError_1_bits_3_mask  (ctrl_pseudoError_1_bits_3_mask),
    .io_pseudoError_1_bits_4_valid (ctrl_pseudoError_1_bits_4_valid),
    .io_pseudoError_1_bits_4_mask  (ctrl_pseudoError_1_bits_4_mask),
    .io_pseudoError_1_bits_5_valid (ctrl_pseudoError_1_bits_5_valid),
    .io_pseudoError_1_bits_5_mask  (ctrl_pseudoError_1_bits_5_mask),
    .io_pseudoError_1_bits_6_valid (ctrl_pseudoError_1_bits_6_valid),
    .io_pseudoError_1_bits_6_mask  (ctrl_pseudoError_1_bits_6_mask),
    .io_pseudoError_1_bits_7_valid (ctrl_pseudoError_1_bits_7_valid),
    .io_pseudoError_1_bits_7_mask  (ctrl_pseudoError_1_bits_7_mask)
  );

  BankedDataArray bankedDataArray (
    .clock                             (clock),
    .reset                             (reset),
    .io_read_0_ready                   (data_array_read_0_ready),
    .io_read_0_valid                   (ldu0_banked_data_read_valid),
    .io_read_0_bits_way_en             (ldu0_banked_data_read_bits_way_en),
    .io_read_0_bits_addr               (ldu0_banked_data_read_bits_addr),
    .io_read_0_bits_addr_dup           (ldu0_banked_data_read_bits_addr_dup),
    .io_read_0_bits_bankMask           (ldu0_banked_data_read_bits_bankMask),
    .io_read_0_bits_lqIdx_flag         (ldu0_banked_data_read_bits_lqIdx_flag),
    .io_read_0_bits_lqIdx_value        (ldu0_banked_data_read_bits_lqIdx_value),
    .io_read_1_ready                   (data_array_read_1_ready),
    .io_read_1_valid                   (ldu1_banked_data_read_valid),
    .io_read_1_bits_way_en             (ldu1_banked_data_read_bits_way_en),
    .io_read_1_bits_addr               (ldu1_banked_data_read_bits_addr),
    .io_read_1_bits_addr_dup           (ldu1_banked_data_read_bits_addr_dup),
    .io_read_1_bits_bankMask           (ldu1_banked_data_read_bits_bankMask),
    .io_read_1_bits_lqIdx_flag         (ldu1_banked_data_read_bits_lqIdx_flag),
    .io_read_1_bits_lqIdx_value        (ldu1_banked_data_read_bits_lqIdx_value),
    .io_read_2_ready                   (data_array_read_2_ready),
    .io_read_2_valid                   (ldu2_banked_data_read_valid),
    .io_read_2_bits_way_en             (ldu2_banked_data_read_bits_way_en),
    .io_read_2_bits_addr               (ldu2_banked_data_read_bits_addr),
    .io_read_2_bits_addr_dup           (ldu2_banked_data_read_bits_addr_dup),
    .io_read_2_bits_bankMask           (ldu2_banked_data_read_bits_bankMask),
    .io_read_2_bits_lqIdx_flag         (ldu2_banked_data_read_bits_lqIdx_flag),
    .io_read_2_bits_lqIdx_value        (ldu2_banked_data_read_bits_lqIdx_value),
    .io_is128Req_0                     (ldu0_is128Req),
    .io_is128Req_1                     (ldu1_is128Req),
    .io_is128Req_2                     (ldu2_is128Req),
    .io_readline_intend                (mp_data_read_intend),
    .io_readline_ready                 (data_array_readline_ready),
    .io_readline_valid                 (mp_data_readline_valid),
    .io_readline_bits_way_en           (mp_data_readline_bits_way_en),
    .io_readline_bits_addr             (mp_data_readline_bits_addr),
    .io_readline_bits_rmask            (mp_data_readline_bits_rmask),
    .io_readline_can_go                (mp_data_readline_can_go),
    .io_readline_stall                 (mp_data_readline_stall),
    .io_readline_can_resp              (mp_data_readline_can_resp),
    .io_write_valid                    (data_write_arb_out_valid),
    .io_write_bits_wmask               (data_write_arb_out_bits_wmask),
    .io_write_bits_data_0              (data_write_arb_out_bits_data_0),
    .io_write_bits_data_1              (data_write_arb_out_bits_data_1),
    .io_write_bits_data_2              (data_write_arb_out_bits_data_2),
    .io_write_bits_data_3              (data_write_arb_out_bits_data_3),
    .io_write_bits_data_4              (data_write_arb_out_bits_data_4),
    .io_write_bits_data_5              (data_write_arb_out_bits_data_5),
    .io_write_bits_data_6              (data_write_arb_out_bits_data_6),
    .io_write_bits_data_7              (data_write_arb_out_bits_data_7),
    .io_write_dup_0_valid              (data_write_arb_dup0_out_valid),
    .io_write_dup_0_bits_way_en        (data_write_arb_dup0_out_bits_way_en),
    .io_write_dup_0_bits_addr          (data_write_arb_dup0_out_bits_addr),
    .io_write_dup_1_valid              (data_write_arb_dup1_out_valid),
    .io_write_dup_1_bits_way_en        (data_write_arb_dup1_out_bits_way_en),
    .io_write_dup_1_bits_addr          (data_write_arb_dup1_out_bits_addr),
    .io_write_dup_2_valid              (data_write_arb_dup2_out_valid),
    .io_write_dup_2_bits_way_en        (data_write_arb_dup2_out_bits_way_en),
    .io_write_dup_2_bits_addr          (data_write_arb_dup2_out_bits_addr),
    .io_write_dup_3_valid              (data_write_arb_dup3_out_valid),
    .io_write_dup_3_bits_way_en        (data_write_arb_dup3_out_bits_way_en),
    .io_write_dup_3_bits_addr          (data_write_arb_dup3_out_bits_addr),
    .io_write_dup_4_valid              (data_write_arb_dup4_out_valid),
    .io_write_dup_4_bits_way_en        (data_write_arb_dup4_out_bits_way_en),
    .io_write_dup_4_bits_addr          (data_write_arb_dup4_out_bits_addr),
    .io_write_dup_5_valid              (data_write_arb_dup5_out_valid),
    .io_write_dup_5_bits_way_en        (data_write_arb_dup5_out_bits_way_en),
    .io_write_dup_5_bits_addr          (data_write_arb_dup5_out_bits_addr),
    .io_write_dup_6_valid              (data_write_arb_dup6_out_valid),
    .io_write_dup_6_bits_way_en        (data_write_arb_dup6_out_bits_way_en),
    .io_write_dup_6_bits_addr          (data_write_arb_dup6_out_bits_addr),
    .io_write_dup_7_valid              (data_write_arb_dup7_out_valid),
    .io_write_dup_7_bits_way_en        (data_write_arb_dup7_out_bits_way_en),
    .io_write_dup_7_bits_addr          (data_write_arb_dup7_out_bits_addr),
    .io_readline_resp_0_raw_data       (data_array_readline_resp_0_raw_data),
    .io_readline_resp_1_raw_data       (data_array_readline_resp_1_raw_data),
    .io_readline_resp_2_raw_data       (data_array_readline_resp_2_raw_data),
    .io_readline_resp_3_raw_data       (data_array_readline_resp_3_raw_data),
    .io_readline_resp_4_raw_data       (data_array_readline_resp_4_raw_data),
    .io_readline_resp_5_raw_data       (data_array_readline_resp_5_raw_data),
    .io_readline_resp_6_raw_data       (data_array_readline_resp_6_raw_data),
    .io_readline_resp_7_raw_data       (data_array_readline_resp_7_raw_data),
    .io_readline_error_delayed         (data_array_readline_error_delayed),
    .io_read_resp_0_0_raw_data         (data_array_read_resp_0_0_raw_data),
    .io_read_resp_0_1_raw_data         (data_array_read_resp_0_1_raw_data),
    .io_read_resp_1_0_raw_data         (data_array_read_resp_1_0_raw_data),
    .io_read_resp_1_1_raw_data         (data_array_read_resp_1_1_raw_data),
    .io_read_resp_2_0_raw_data         (data_array_read_resp_2_0_raw_data),
    .io_read_resp_2_1_raw_data         (data_array_read_resp_2_1_raw_data),
    .io_read_error_delayed_0_0         (data_array_read_error_delayed_0_0),
    .io_read_error_delayed_0_1         (data_array_read_error_delayed_0_1),
    .io_read_error_delayed_1_0         (data_array_read_error_delayed_1_0),
    .io_read_error_delayed_1_1         (data_array_read_error_delayed_1_1),
    .io_read_error_delayed_2_0         (data_array_read_error_delayed_2_0),
    .io_read_error_delayed_2_1         (data_array_read_error_delayed_2_1),
    .io_bank_conflict_slow_0           (data_array_bank_conflict_slow_0),
    .io_bank_conflict_slow_1           (data_array_bank_conflict_slow_1),
    .io_bank_conflict_slow_2           (data_array_bank_conflict_slow_2),
    .io_disable_ld_fast_wakeup_0       (data_array_disable_ld_fast_wakeup_0),
    .io_disable_ld_fast_wakeup_1       (data_array_disable_ld_fast_wakeup_1),
    .io_disable_ld_fast_wakeup_2       (data_array_disable_ld_fast_wakeup_2),
    .io_pseudo_error_ready             (data_array_pseudo_error_ready),
    .io_pseudo_error_valid             (ctrl_pseudoError_1_valid),
    .io_pseudo_error_bits_0_valid      (ctrl_pseudoError_1_bits_0_valid),
    .io_pseudo_error_bits_0_mask       (ctrl_pseudoError_1_bits_0_mask),
    .io_pseudo_error_bits_1_valid      (ctrl_pseudoError_1_bits_1_valid),
    .io_pseudo_error_bits_1_mask       (ctrl_pseudoError_1_bits_1_mask),
    .io_pseudo_error_bits_2_valid      (ctrl_pseudoError_1_bits_2_valid),
    .io_pseudo_error_bits_2_mask       (ctrl_pseudoError_1_bits_2_mask),
    .io_pseudo_error_bits_3_valid      (ctrl_pseudoError_1_bits_3_valid),
    .io_pseudo_error_bits_3_mask       (ctrl_pseudoError_1_bits_3_mask),
    .io_pseudo_error_bits_4_valid      (ctrl_pseudoError_1_bits_4_valid),
    .io_pseudo_error_bits_4_mask       (ctrl_pseudoError_1_bits_4_mask),
    .io_pseudo_error_bits_5_valid      (ctrl_pseudoError_1_bits_5_valid),
    .io_pseudo_error_bits_5_mask       (ctrl_pseudoError_1_bits_5_mask),
    .io_pseudo_error_bits_6_valid      (ctrl_pseudoError_1_bits_6_valid),
    .io_pseudo_error_bits_6_mask       (ctrl_pseudoError_1_bits_6_mask),
    .io_pseudo_error_bits_7_valid      (ctrl_pseudoError_1_bits_7_valid),
    .io_pseudo_error_bits_7_mask       (ctrl_pseudoError_1_bits_7_mask),
    .boreChildrenBd_bore_array         (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all           (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req           (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack           (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen       (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be            (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr          (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata        (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen        (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd       (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata       (boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold        (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass      (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken    (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk     (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp    (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold    (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen            (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold      (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass    (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken  (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk   (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp  (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold  (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen          (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold      (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass    (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken  (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk   (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp  (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold  (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen          (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold      (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass    (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken  (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk   (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp  (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold  (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen          (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold      (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass    (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken  (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk   (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp  (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold  (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen          (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold      (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass    (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken  (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk   (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp  (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold  (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen          (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold      (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass    (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken  (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk   (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp  (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold  (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen          (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold      (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass    (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken  (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk   (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp  (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold  (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen          (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold      (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass    (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken  (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk   (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp  (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold  (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen          (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold      (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass    (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken  (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk   (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp  (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold  (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen          (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold     (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass   (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk  (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen         (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold     (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass   (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk  (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen         (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold     (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass   (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk  (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen         (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold     (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass   (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk  (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen         (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold     (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass   (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk  (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen         (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold     (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass   (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk  (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen         (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold     (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass   (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk  (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen         (sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold     (sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass   (sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken (sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk  (sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp (sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold (sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen         (sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold     (sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass   (sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken (sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk  (sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp (sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold (sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen         (sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold     (sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass   (sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken (sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk  (sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp (sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold (sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen         (sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold     (sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass   (sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken (sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk  (sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp (sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold (sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen         (sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_21_ram_hold     (sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_21_ram_bypass   (sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken (sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk  (sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp (sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold (sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen         (sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_22_ram_hold     (sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_22_ram_bypass   (sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken (sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk  (sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp (sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold (sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen         (sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_23_ram_hold     (sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_23_ram_bypass   (sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken (sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk  (sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp (sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold (sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen         (sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_24_ram_hold     (sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_24_ram_bypass   (sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken (sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk  (sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp (sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold (sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen         (sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_25_ram_hold     (sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_25_ram_bypass   (sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken (sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk  (sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp (sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold (sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen         (sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_26_ram_hold     (sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_26_ram_bypass   (sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken (sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk  (sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp (sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold (sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen         (sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_27_ram_hold     (sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_27_ram_bypass   (sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken (sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk  (sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp (sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold (sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen         (sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_28_ram_hold     (sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_28_ram_bypass   (sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken (sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk  (sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp (sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold (sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen         (sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_29_ram_hold     (sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_29_ram_bypass   (sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken (sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk  (sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp (sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold (sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen         (sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_30_ram_hold     (sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_30_ram_bypass   (sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken (sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk  (sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp (sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold (sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen         (sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_31_ram_hold     (sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_31_ram_bypass   (sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken (sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk  (sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp (sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold (sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen         (sigFromSrams_bore_31_cgen)
  );

  L1CohMetaArray metaArray (
    .clock                          (clock),
    .reset                          (reset),
    .io_read_0_valid                (ldu0_meta_read_valid),
    .io_read_0_bits_idx             (ldu0_meta_read_bits_idx),
    .io_read_1_valid                (ldu1_meta_read_valid),
    .io_read_1_bits_idx             (ldu1_meta_read_bits_idx),
    .io_read_2_valid                (ldu2_meta_read_valid),
    .io_read_2_bits_idx             (ldu2_meta_read_bits_idx),
    .io_read_3_valid                (mp_meta_read_valid),
    .io_read_3_bits_idx             (mp_meta_read_bits_idx),
    .io_resp_0_0_coh_state          (meta_array_resp_0_0_coh_state),
    .io_resp_0_1_coh_state          (meta_array_resp_0_1_coh_state),
    .io_resp_0_2_coh_state          (meta_array_resp_0_2_coh_state),
    .io_resp_0_3_coh_state          (meta_array_resp_0_3_coh_state),
    .io_resp_1_0_coh_state          (meta_array_resp_1_0_coh_state),
    .io_resp_1_1_coh_state          (meta_array_resp_1_1_coh_state),
    .io_resp_1_2_coh_state          (meta_array_resp_1_2_coh_state),
    .io_resp_1_3_coh_state          (meta_array_resp_1_3_coh_state),
    .io_resp_2_0_coh_state          (meta_array_resp_2_0_coh_state),
    .io_resp_2_1_coh_state          (meta_array_resp_2_1_coh_state),
    .io_resp_2_2_coh_state          (meta_array_resp_2_2_coh_state),
    .io_resp_2_3_coh_state          (meta_array_resp_2_3_coh_state),
    .io_resp_3_0_coh_state          (meta_array_resp_3_0_coh_state),
    .io_resp_3_1_coh_state          (meta_array_resp_3_1_coh_state),
    .io_resp_3_2_coh_state          (meta_array_resp_3_2_coh_state),
    .io_resp_3_3_coh_state          (meta_array_resp_3_3_coh_state),
    .io_write_0_valid               (mp_meta_write_valid),
    .io_write_0_bits_idx            (mp_meta_write_bits_idx),
    .io_write_0_bits_way_en         (mp_meta_write_bits_way_en),
    .io_write_0_bits_meta_coh_state (mp_meta_write_bits_meta_coh_state)
  );

  L1ErrorMetaArray errorArray (
    .clock                            (clock),
    .reset                            (reset),
    .io_read_0_valid                  (ldu0_meta_read_valid),
    .io_read_0_bits_idx               (ldu0_meta_read_bits_idx),
    .io_read_1_valid                  (ldu1_meta_read_valid),
    .io_read_1_bits_idx               (ldu1_meta_read_bits_idx),
    .io_read_2_valid                  (ldu2_meta_read_valid),
    .io_read_2_bits_idx               (ldu2_meta_read_bits_idx),
    .io_read_3_valid                  (mp_meta_read_valid),
    .io_read_3_bits_idx               (mp_meta_read_bits_idx),
    .io_resp_0_0_tl_denied            (error_array_resp_0_0_tl_denied),
    .io_resp_0_0_tl_corrupt           (error_array_resp_0_0_tl_corrupt),
    .io_resp_0_1_tl_denied            (error_array_resp_0_1_tl_denied),
    .io_resp_0_1_tl_corrupt           (error_array_resp_0_1_tl_corrupt),
    .io_resp_0_2_tl_denied            (error_array_resp_0_2_tl_denied),
    .io_resp_0_2_tl_corrupt           (error_array_resp_0_2_tl_corrupt),
    .io_resp_0_3_tl_denied            (error_array_resp_0_3_tl_denied),
    .io_resp_0_3_tl_corrupt           (error_array_resp_0_3_tl_corrupt),
    .io_resp_1_0_tl_denied            (error_array_resp_1_0_tl_denied),
    .io_resp_1_0_tl_corrupt           (error_array_resp_1_0_tl_corrupt),
    .io_resp_1_1_tl_denied            (error_array_resp_1_1_tl_denied),
    .io_resp_1_1_tl_corrupt           (error_array_resp_1_1_tl_corrupt),
    .io_resp_1_2_tl_denied            (error_array_resp_1_2_tl_denied),
    .io_resp_1_2_tl_corrupt           (error_array_resp_1_2_tl_corrupt),
    .io_resp_1_3_tl_denied            (error_array_resp_1_3_tl_denied),
    .io_resp_1_3_tl_corrupt           (error_array_resp_1_3_tl_corrupt),
    .io_resp_2_0_tl_denied            (error_array_resp_2_0_tl_denied),
    .io_resp_2_0_tl_corrupt           (error_array_resp_2_0_tl_corrupt),
    .io_resp_2_1_tl_denied            (error_array_resp_2_1_tl_denied),
    .io_resp_2_1_tl_corrupt           (error_array_resp_2_1_tl_corrupt),
    .io_resp_2_2_tl_denied            (error_array_resp_2_2_tl_denied),
    .io_resp_2_2_tl_corrupt           (error_array_resp_2_2_tl_corrupt),
    .io_resp_2_3_tl_denied            (error_array_resp_2_3_tl_denied),
    .io_resp_2_3_tl_corrupt           (error_array_resp_2_3_tl_corrupt),
    .io_resp_3_0_tl_denied            (error_array_resp_3_0_tl_denied),
    .io_resp_3_0_tl_corrupt           (error_array_resp_3_0_tl_corrupt),
    .io_resp_3_1_tl_denied            (error_array_resp_3_1_tl_denied),
    .io_resp_3_1_tl_corrupt           (error_array_resp_3_1_tl_corrupt),
    .io_resp_3_2_tl_denied            (error_array_resp_3_2_tl_denied),
    .io_resp_3_2_tl_corrupt           (error_array_resp_3_2_tl_corrupt),
    .io_resp_3_3_tl_denied            (error_array_resp_3_3_tl_denied),
    .io_resp_3_3_tl_corrupt           (error_array_resp_3_3_tl_corrupt),
    .io_write_0_valid                 (mp_error_flag_write_valid),
    .io_write_0_bits_idx              (mp_error_flag_write_bits_idx),
    .io_write_0_bits_way_en           (mp_error_flag_write_bits_way_en),
    .io_write_0_bits_error_tl_denied  (mp_error_flag_write_bits_error_tl_denied),
    .io_write_0_bits_error_tl_corrupt (mp_error_flag_write_bits_error_tl_corrupt)
  );

  L1PrefetchSourceArray prefetchArray (
    .clock                  (clock),
    .reset                  (reset),
    .io_read_0_valid        (ldu0_meta_read_valid),
    .io_read_0_bits_idx     (ldu0_meta_read_bits_idx),
    .io_read_1_valid        (ldu1_meta_read_valid),
    .io_read_1_bits_idx     (ldu1_meta_read_bits_idx),
    .io_read_2_valid        (ldu2_meta_read_valid),
    .io_read_2_bits_idx     (ldu2_meta_read_bits_idx),
    .io_read_3_valid        (mp_meta_read_valid),
    .io_read_3_bits_idx     (mp_meta_read_bits_idx),
    .io_read_4_valid        (mp_prefetch_flag_write_valid),
    .io_read_4_bits_idx     (mp_prefetch_flag_write_bits_idx),
    .io_resp_0_0            (pf_array_resp_0_0),
    .io_resp_0_1            (pf_array_resp_0_1),
    .io_resp_0_2            (pf_array_resp_0_2),
    .io_resp_0_3            (pf_array_resp_0_3),
    .io_resp_1_0            (pf_array_resp_1_0),
    .io_resp_1_1            (pf_array_resp_1_1),
    .io_resp_1_2            (pf_array_resp_1_2),
    .io_resp_1_3            (pf_array_resp_1_3),
    .io_resp_2_0            (pf_array_resp_2_0),
    .io_resp_2_1            (pf_array_resp_2_1),
    .io_resp_2_2            (pf_array_resp_2_2),
    .io_resp_2_3            (pf_array_resp_2_3),
    .io_resp_3_0            (pf_array_resp_3_0),
    .io_resp_3_1            (pf_array_resp_3_1),
    .io_resp_3_2            (pf_array_resp_3_2),
    .io_resp_3_3            (pf_array_resp_3_3),
    .io_resp_4_0            (pf_array_resp_4_0),
    .io_resp_4_1            (pf_array_resp_4_1),
    .io_resp_4_2            (pf_array_resp_4_2),
    .io_resp_4_3            (pf_array_resp_4_3),
    .io_write_0_valid       (ldu0_prefetch_flag_write_valid),
    .io_write_0_bits_idx    (ldu0_prefetch_flag_write_bits_idx),
    .io_write_0_bits_way_en (ldu0_prefetch_flag_write_bits_way_en),
    .io_write_1_valid       (ldu1_prefetch_flag_write_valid),
    .io_write_1_bits_idx    (ldu1_prefetch_flag_write_bits_idx),
    .io_write_1_bits_way_en (ldu1_prefetch_flag_write_bits_way_en),
    .io_write_2_valid       (ldu2_prefetch_flag_write_valid),
    .io_write_2_bits_idx    (ldu2_prefetch_flag_write_bits_idx),
    .io_write_2_bits_way_en (ldu2_prefetch_flag_write_bits_way_en),
    .io_write_3_valid       (mp_prefetch_flag_write_valid),
    .io_write_3_bits_idx    (mp_prefetch_flag_write_bits_idx),
    .io_write_3_bits_way_en (mp_prefetch_flag_write_bits_way_en),
    .io_write_3_bits_source (mp_prefetch_flag_write_bits_source)
  );

  L1FlagMetaArray accessArray (
    .clock                  (clock),
    .reset                  (reset),
    .io_read_0_valid        (ldu0_meta_read_valid),
    .io_read_0_bits_idx     (ldu0_meta_read_bits_idx),
    .io_read_1_valid        (ldu1_meta_read_valid),
    .io_read_1_bits_idx     (ldu1_meta_read_bits_idx),
    .io_read_2_valid        (ldu2_meta_read_valid),
    .io_read_2_bits_idx     (ldu2_meta_read_bits_idx),
    .io_read_3_valid        (mp_meta_read_valid),
    .io_read_3_bits_idx     (mp_meta_read_bits_idx),
    .io_read_4_valid        (mp_prefetch_flag_write_valid),
    .io_read_4_bits_idx     (mp_prefetch_flag_write_bits_idx),
    .io_resp_0_0            (access_array_resp_0_0),
    .io_resp_0_1            (access_array_resp_0_1),
    .io_resp_0_2            (access_array_resp_0_2),
    .io_resp_0_3            (access_array_resp_0_3),
    .io_resp_1_0            (access_array_resp_1_0),
    .io_resp_1_1            (access_array_resp_1_1),
    .io_resp_1_2            (access_array_resp_1_2),
    .io_resp_1_3            (access_array_resp_1_3),
    .io_resp_2_0            (access_array_resp_2_0),
    .io_resp_2_1            (access_array_resp_2_1),
    .io_resp_2_2            (access_array_resp_2_2),
    .io_resp_2_3            (access_array_resp_2_3),
    .io_resp_3_0            (access_array_resp_3_0),
    .io_resp_3_1            (access_array_resp_3_1),
    .io_resp_3_2            (access_array_resp_3_2),
    .io_resp_3_3            (access_array_resp_3_3),
    .io_resp_4_0            (access_array_resp_4_0),
    .io_resp_4_1            (access_array_resp_4_1),
    .io_resp_4_2            (access_array_resp_4_2),
    .io_resp_4_3            (access_array_resp_4_3),
    .io_write_0_valid       (ldu0_access_flag_write_valid),
    .io_write_0_bits_idx    (ldu0_access_flag_write_bits_idx),
    .io_write_0_bits_way_en (ldu0_access_flag_write_bits_way_en),
    .io_write_1_valid       (ldu1_access_flag_write_valid),
    .io_write_1_bits_idx    (ldu1_access_flag_write_bits_idx),
    .io_write_1_bits_way_en (ldu1_access_flag_write_bits_way_en),
    .io_write_2_valid       (ldu2_access_flag_write_valid),
    .io_write_2_bits_idx    (ldu2_access_flag_write_bits_idx),
    .io_write_2_bits_way_en (ldu2_access_flag_write_bits_way_en),
    .io_write_3_valid       (mp_access_flag_write_valid),
    .io_write_3_bits_idx    (mp_access_flag_write_bits_idx),
    .io_write_3_bits_way_en (mp_access_flag_write_bits_way_en),
    .io_write_3_bits_flag   (mp_access_flag_write_bits_flag)
  );

  DuplicatedTagArray tagArray (
    .clock                            (clock),
    .reset                            (reset),
    .io_read_0_valid                  (ldu0_tag_read_valid),
    .io_read_0_bits_idx               (ldu0_tag_read_bits_idx),
    .io_read_1_valid                  (ldu1_tag_read_valid),
    .io_read_1_bits_idx               (ldu1_tag_read_bits_idx),
    .io_read_2_valid                  (ldu2_tag_read_valid),
    .io_read_2_bits_idx               (ldu2_tag_read_bits_idx),
    .io_read_3_ready                  (tag_array_read_3_ready),
    .io_read_3_valid                  (mp_tag_read_valid),
    .io_read_3_bits_idx               (mp_tag_read_bits_idx),
    .io_resp_0_0                      (tag_array_resp_0_0),
    .io_resp_0_1                      (tag_array_resp_0_1),
    .io_resp_0_2                      (tag_array_resp_0_2),
    .io_resp_0_3                      (tag_array_resp_0_3),
    .io_resp_1_0                      (tag_array_resp_1_0),
    .io_resp_1_1                      (tag_array_resp_1_1),
    .io_resp_1_2                      (tag_array_resp_1_2),
    .io_resp_1_3                      (tag_array_resp_1_3),
    .io_resp_2_0                      (tag_array_resp_2_0),
    .io_resp_2_1                      (tag_array_resp_2_1),
    .io_resp_2_2                      (tag_array_resp_2_2),
    .io_resp_2_3                      (tag_array_resp_2_3),
    .io_resp_3_0                      (tag_array_resp_3_0),
    .io_resp_3_1                      (tag_array_resp_3_1),
    .io_resp_3_2                      (tag_array_resp_3_2),
    .io_resp_3_3                      (tag_array_resp_3_3),
    .io_write_valid                   (tag_write_arb_out_valid),
    .io_write_bits_idx                (tag_write_arb_out_bits_idx),
    .io_write_bits_way_en             (tag_write_arb_out_bits_way_en),
    .io_write_bits_tag                (tag_write_arb_out_bits_tag),
    .boreChildrenBd_bore_array        (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_all          (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_req          (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_ack          (boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_writeen      (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_be           (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_addr         (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_indata       (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_readen       (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_addr_rd      (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_outdata      (boreChildrenBd_bore_1_outdata),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_32_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_32_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_32_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_32_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_32_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_32_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_32_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_33_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_33_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_33_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_33_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_33_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_33_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_33_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_34_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_34_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_34_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_34_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_34_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_34_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_34_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_35_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_35_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_35_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_35_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_35_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_35_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_35_cgen),
    .sigFromSrams_bore_4_ram_hold     (sigFromSrams_bore_36_ram_hold),
    .sigFromSrams_bore_4_ram_bypass   (sigFromSrams_bore_36_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken (sigFromSrams_bore_36_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk  (sigFromSrams_bore_36_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp (sigFromSrams_bore_36_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold (sigFromSrams_bore_36_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen         (sigFromSrams_bore_36_cgen),
    .sigFromSrams_bore_5_ram_hold     (sigFromSrams_bore_37_ram_hold),
    .sigFromSrams_bore_5_ram_bypass   (sigFromSrams_bore_37_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken (sigFromSrams_bore_37_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk  (sigFromSrams_bore_37_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp (sigFromSrams_bore_37_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold (sigFromSrams_bore_37_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen         (sigFromSrams_bore_37_cgen),
    .sigFromSrams_bore_6_ram_hold     (sigFromSrams_bore_38_ram_hold),
    .sigFromSrams_bore_6_ram_bypass   (sigFromSrams_bore_38_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken (sigFromSrams_bore_38_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk  (sigFromSrams_bore_38_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp (sigFromSrams_bore_38_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold (sigFromSrams_bore_38_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen         (sigFromSrams_bore_38_cgen),
    .sigFromSrams_bore_7_ram_hold     (sigFromSrams_bore_39_ram_hold),
    .sigFromSrams_bore_7_ram_bypass   (sigFromSrams_bore_39_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken (sigFromSrams_bore_39_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk  (sigFromSrams_bore_39_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp (sigFromSrams_bore_39_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold (sigFromSrams_bore_39_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen         (sigFromSrams_bore_39_cgen)
  );

  PrefetcherMonitor prefetcherMonitor (
    .clock                        (clock),
    .reset                        (reset),
    .io_timely_total_prefetch     (core_pfm_total_prefetch),
    .io_timely_late_hit_prefetch  (core_pfm_late_hit_prefetch),
    .io_timely_late_miss_prefetch (mq_prefetch_info_naive_late_miss_prefetch),
    .io_validity_good_prefetch    (core_pfm_good_prefetch),
    .io_validity_bad_prefetch     (core_pfm_bad_prefetch),
    .io_pf_ctrl_enable            (io_pf_ctrl_enable),
    .io_pf_ctrl_confidence        (io_pf_ctrl_confidence)
  );

  FDPrefetcherMonitor fdpMonitor (
    .io_accuracy_useful_prefetch_0  (core_fdp_useful_prefetch[0]),
    .io_accuracy_useful_prefetch_1  (core_fdp_useful_prefetch[1]),
    .io_accuracy_useful_prefetch_2  (core_fdp_useful_prefetch[2]),
    .io_timely_late_prefetch        (mq_prefetch_info_fdp_late_miss_prefetch),
    .io_pollution_demand_miss_0     (ldu0_prefetch_info_fdp_demand_miss),
    .io_pollution_demand_miss_1     (ldu1_prefetch_info_fdp_demand_miss),
    .io_pollution_demand_miss_2     (ldu2_prefetch_info_fdp_demand_miss),
    .io_pollution_cache_pollution_0 (ldu0_prefetch_info_fdp_pollution),
    .io_pollution_cache_pollution_1 (ldu1_prefetch_info_fdp_pollution),
    .io_pollution_cache_pollution_2 (ldu2_prefetch_info_fdp_pollution)
  );

  BloomFilter bloomFilter (
    .clock                (clock),
    .reset                (reset),
    .io_set_valid         (mp_bloom_filter_query_set_valid),
    .io_set_bits_addr     (mp_bloom_filter_query_set_bits_addr),
    .io_clr_valid         (mp_bloom_filter_query_clr_valid),
    .io_clr_bits_addr     (mp_bloom_filter_query_clr_bits_addr),
    .io_query_0_valid     (ldu0_bloom_filter_query_query_valid),
    .io_query_0_bits_addr (ldu0_bloom_filter_query_query_bits_addr),
    .io_query_1_valid     (ldu1_bloom_filter_query_query_valid),
    .io_query_1_bits_addr (ldu1_bloom_filter_query_query_bits_addr),
    .io_query_2_valid     (ldu2_bloom_filter_query_query_valid),
    .io_query_2_bits_addr (ldu2_bloom_filter_query_query_bits_addr),
    .io_resp_0_valid      (bloom_resp_0_valid),
    .io_resp_0_bits_res   (bloom_resp_0_bits_res),
    .io_resp_1_valid      (bloom_resp_1_valid),
    .io_resp_1_bits_res   (bloom_resp_1_bits_res),
    .io_resp_2_valid      (bloom_resp_2_valid),
    .io_resp_2_bits_res   (bloom_resp_2_bits_res)
  );

  CounterFilter counterFilter (
    .clock                   (clock),
    .reset                   (reset),
    .io_ld_in_0_valid        (ldu0_counter_filter_enq_valid),
    .io_ld_in_0_bits_idx     (ldu0_counter_filter_enq_bits_idx),
    .io_ld_in_0_bits_way     (ldu0_counter_filter_enq_bits_way),
    .io_ld_in_1_valid        (ldu1_counter_filter_enq_valid),
    .io_ld_in_1_bits_idx     (ldu1_counter_filter_enq_bits_idx),
    .io_ld_in_1_bits_way     (ldu1_counter_filter_enq_bits_way),
    .io_ld_in_2_valid        (ldu2_counter_filter_enq_valid),
    .io_ld_in_2_bits_idx     (ldu2_counter_filter_enq_bits_idx),
    .io_ld_in_2_bits_way     (ldu2_counter_filter_enq_bits_way),
    .io_query_0_req_valid    (ldu0_counter_filter_query_req_valid),
    .io_query_0_req_bits_idx (ldu0_counter_filter_query_req_bits_idx),
    .io_query_0_req_bits_way (ldu0_counter_filter_query_req_bits_way),
    .io_query_0_resp         (counter_filter_query_0_resp),
    .io_query_1_req_valid    (ldu1_counter_filter_query_req_valid),
    .io_query_1_req_bits_idx (ldu1_counter_filter_query_req_bits_idx),
    .io_query_1_req_bits_way (ldu1_counter_filter_query_req_bits_way),
    .io_query_1_resp         (counter_filter_query_1_resp),
    .io_query_2_req_valid    (ldu2_counter_filter_query_req_valid),
    .io_query_2_req_bits_idx (ldu2_counter_filter_query_req_bits_idx),
    .io_query_2_req_bits_way (ldu2_counter_filter_query_req_bits_way),
    .io_query_2_resp         (counter_filter_query_2_resp)
  );

  LoadPipe ldu_0 (
    .clock                                        (clock),
    .reset                                        (reset),
    .io_lsu_req_ready                             (ldu0_lsu_req_ready),
    .io_lsu_req_valid                             (io_lsu_load_0_req_valid),
    .io_lsu_req_bits_cmd                          (io_lsu_load_0_req_bits_cmd),
    .io_lsu_req_bits_vaddr                        (io_lsu_load_0_req_bits_vaddr),
    .io_lsu_req_bits_vaddr_dup                    (io_lsu_load_0_req_bits_vaddr_dup),
    .io_lsu_req_bits_instrtype                    (io_lsu_load_0_req_bits_instrtype),
    .io_lsu_req_bits_isFirstIssue                 (io_lsu_load_0_req_bits_isFirstIssue),
    .io_lsu_req_bits_lqIdx_flag                   (io_lsu_load_0_req_bits_lqIdx_flag),
    .io_lsu_req_bits_lqIdx_value                  (io_lsu_load_0_req_bits_lqIdx_value),
    .io_lsu_resp_valid                            (io_lsu_load_0_resp_valid),
    .io_lsu_resp_bits_data                        (io_lsu_load_0_resp_bits_data),
    .io_lsu_resp_bits_data_delayed                (io_lsu_load_0_resp_bits_data_delayed),
    .io_lsu_resp_bits_miss                        (io_lsu_load_0_resp_bits_miss),
    .io_lsu_resp_bits_mshr_id                     (io_lsu_load_0_resp_bits_mshr_id),
    .io_lsu_resp_bits_meta_prefetch               (io_lsu_load_0_resp_bits_meta_prefetch),
    .io_lsu_resp_bits_handled                     (io_lsu_load_0_resp_bits_handled),
    .io_lsu_resp_bits_tl_error_delayed_tl_denied  (io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied),
    .io_lsu_resp_bits_tl_error_delayed_tl_corrupt (io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt),
    .io_lsu_s1_kill_data_read                     (io_lsu_load_0_s1_kill_data_read),
    .io_lsu_s1_kill                               (io_lsu_load_0_s1_kill),
    .io_lsu_s2_kill                               (io_lsu_load_0_s2_kill),
    .io_lsu_pf_source                             (io_lsu_load_0_pf_source),
    .io_lsu_s1_paddr_dup_lsu                      (io_lsu_load_0_s1_paddr_dup_lsu),
    .io_lsu_s1_paddr_dup_dcache                   (io_lsu_load_0_s1_paddr_dup_dcache),
    .io_lsu_s2_bank_conflict                      (io_lsu_load_0_s2_bank_conflict),
    .io_lsu_s2_mq_nack                            (io_lsu_load_0_s2_mq_nack),
    .io_load128Req                                (io_lsu_load_0_is128Req),
    .io_meta_read_valid                           (ldu0_meta_read_valid),
    .io_meta_read_bits_idx                        (ldu0_meta_read_bits_idx),
    .io_meta_resp_0_coh_state                     (meta_array_resp_0_0_coh_state),
    .io_meta_resp_1_coh_state                     (meta_array_resp_0_1_coh_state),
    .io_meta_resp_2_coh_state                     (meta_array_resp_0_2_coh_state),
    .io_meta_resp_3_coh_state                     (meta_array_resp_0_3_coh_state),
    .io_extra_meta_resp_0_error_tl_denied         (error_array_resp_0_0_tl_denied),
    .io_extra_meta_resp_0_error_tl_corrupt        (error_array_resp_0_0_tl_corrupt),
    .io_extra_meta_resp_0_prefetch                (pf_array_resp_0_0),
    .io_extra_meta_resp_0_access                  (access_array_resp_0_0),
    .io_extra_meta_resp_1_error_tl_denied         (error_array_resp_0_1_tl_denied),
    .io_extra_meta_resp_1_error_tl_corrupt        (error_array_resp_0_1_tl_corrupt),
    .io_extra_meta_resp_1_prefetch                (pf_array_resp_0_1),
    .io_extra_meta_resp_1_access                  (access_array_resp_0_1),
    .io_extra_meta_resp_2_error_tl_denied         (error_array_resp_0_2_tl_denied),
    .io_extra_meta_resp_2_error_tl_corrupt        (error_array_resp_0_2_tl_corrupt),
    .io_extra_meta_resp_2_prefetch                (pf_array_resp_0_2),
    .io_extra_meta_resp_2_access                  (access_array_resp_0_2),
    .io_extra_meta_resp_3_error_tl_denied         (error_array_resp_0_3_tl_denied),
    .io_extra_meta_resp_3_error_tl_corrupt        (error_array_resp_0_3_tl_corrupt),
    .io_extra_meta_resp_3_prefetch                (pf_array_resp_0_3),
    .io_extra_meta_resp_3_access                  (access_array_resp_0_3),
    .io_tag_read_ready                            (core_ldu_tag_read_ready),
    .io_tag_read_valid                            (ldu0_tag_read_valid),
    .io_tag_read_bits_idx                         (ldu0_tag_read_bits_idx),
    .io_tag_resp_0                                (tag_array_resp_0_0),
    .io_tag_resp_1                                (tag_array_resp_0_1),
    .io_tag_resp_2                                (tag_array_resp_0_2),
    .io_tag_resp_3                                (tag_array_resp_0_3),
    .io_banked_data_read_ready                    (data_array_read_0_ready),
    .io_banked_data_read_valid                    (ldu0_banked_data_read_valid),
    .io_banked_data_read_bits_way_en              (ldu0_banked_data_read_bits_way_en),
    .io_banked_data_read_bits_addr                (ldu0_banked_data_read_bits_addr),
    .io_banked_data_read_bits_addr_dup            (ldu0_banked_data_read_bits_addr_dup),
    .io_banked_data_read_bits_bankMask            (ldu0_banked_data_read_bits_bankMask),
    .io_banked_data_read_bits_lqIdx_flag          (ldu0_banked_data_read_bits_lqIdx_flag),
    .io_banked_data_read_bits_lqIdx_value         (ldu0_banked_data_read_bits_lqIdx_value),
    .io_is128Req                                  (ldu0_is128Req),
    .io_banked_data_resp_0_raw_data               (data_array_read_resp_0_0_raw_data),
    .io_banked_data_resp_1_raw_data               (data_array_read_resp_0_1_raw_data),
    .io_read_error_delayed_0                      (data_array_read_error_delayed_0_0),
    .io_read_error_delayed_1                      (data_array_read_error_delayed_0_1),
    .io_access_flag_write_valid                   (ldu0_access_flag_write_valid),
    .io_access_flag_write_bits_idx                (ldu0_access_flag_write_bits_idx),
    .io_access_flag_write_bits_way_en             (ldu0_access_flag_write_bits_way_en),
    .io_prefetch_flag_write_valid                 (ldu0_prefetch_flag_write_valid),
    .io_prefetch_flag_write_bits_idx              (ldu0_prefetch_flag_write_bits_idx),
    .io_prefetch_flag_write_bits_way_en           (ldu0_prefetch_flag_write_bits_way_en),
    .io_bank_conflict_slow                        (data_array_bank_conflict_slow_0),
    .io_miss_req_ready                            (miss_ready_gen_in_1_ready),
    .io_miss_req_valid                            (ldu0_miss_req_valid),
    .io_miss_req_bits_source                      (ldu0_miss_req_bits_source),
    .io_miss_req_bits_pf_source                   (ldu0_miss_req_bits_pf_source),
    .io_miss_req_bits_cmd                         (ldu0_miss_req_bits_cmd),
    .io_miss_req_bits_addr                        (ldu0_miss_req_bits_addr),
    .io_miss_req_bits_vaddr                       (ldu0_miss_req_bits_vaddr),
    .io_miss_req_bits_req_coh_state               (ldu0_miss_req_bits_req_coh_state),
    .io_miss_req_bits_isBtoT                      (ldu0_miss_req_bits_isBtoT),
    .io_miss_req_bits_occupy_way                  (ldu0_miss_req_bits_occupy_way),
    .io_miss_req_bits_cancel                      (ldu0_miss_req_bits_cancel),
    .io_miss_resp_id                              (mq_resp_id),
    .io_miss_resp_handled                         (mq_resp_handled),
    .io_miss_resp_merged                          (mq_resp_merged),
    .io_wbq_conflict_check_valid                  (ldu0_wbq_conflict_check_valid),
    .io_wbq_conflict_check_bits                   (ldu0_wbq_conflict_check_bits),
    .io_wbq_block_miss_req                        (wbq_block_miss_req_0),
    .io_replace_access_valid                      (ldu0_replace_access_valid),
    .io_replace_access_bits_set                   (ldu0_replace_access_bits_set),
    .io_replace_access_bits_way                   (ldu0_replace_access_bits_way),
    .io_occupy_set                                (ldu0_occupy_set),
    .io_occupy_fail                               (mq_occupy_fail_0),
    .io_disable_ld_fast_wakeup                    (data_array_disable_ld_fast_wakeup_0),
    .io_error_valid                               (ldu0_error_valid),
    .io_error_bits_paddr                          (ldu0_error_bits_paddr),
    .io_error_bits_report_to_beu                  (ldu0_error_bits_report_to_beu),
    .io_pseudo_error_valid                        (ctrl_pseudoError_0_valid),
    .io_pseudo_error_bits_0_valid                 (ctrl_pseudoError_0_bits_0_valid),
    .io_pseudo_error_bits_0_mask                  (ctrl_pseudoError_0_bits_0_mask),
    .io_pseudo_tag_error_inj_done                 (ldu0_pseudo_tag_error_inj_done),
    .io_pseudo_data_error_inj_done                (ldu0_pseudo_data_error_inj_done),
    .io_prefetch_info_naive_total_prefetch        (ldu0_prefetch_info_naive_total_prefetch),
    .io_prefetch_info_naive_late_hit_prefetch     (ldu0_prefetch_info_naive_late_hit_prefetch),
    .io_prefetch_info_naive_late_prefetch_hit     (ldu0_prefetch_info_naive_late_prefetch_hit),
    .io_prefetch_info_naive_late_load_hit         (ldu0_prefetch_info_naive_late_load_hit),
    .io_prefetch_info_naive_useful_prefetch       (ldu0_prefetch_info_naive_useful_prefetch),
    .io_prefetch_info_naive_prefetch_hit          (ldu0_prefetch_info_naive_prefetch_hit),
    .io_prefetch_info_fdp_useful_prefetch         (ldu0_prefetch_info_fdp_useful_prefetch),
    .io_prefetch_info_fdp_demand_miss             (ldu0_prefetch_info_fdp_demand_miss),
    .io_prefetch_info_fdp_pollution               (ldu0_prefetch_info_fdp_pollution),
    .io_bloom_filter_query_query_valid            (ldu0_bloom_filter_query_query_valid),
    .io_bloom_filter_query_query_bits_addr        (ldu0_bloom_filter_query_query_bits_addr),
    .io_bloom_filter_query_resp_valid             (bloom_resp_0_valid),
    .io_bloom_filter_query_resp_bits_res          (bloom_resp_0_bits_res),
    .io_counter_filter_query_req_valid            (ldu0_counter_filter_query_req_valid),
    .io_counter_filter_query_req_bits_idx         (ldu0_counter_filter_query_req_bits_idx),
    .io_counter_filter_query_req_bits_way         (ldu0_counter_filter_query_req_bits_way),
    .io_counter_filter_query_resp                 (counter_filter_query_0_resp),
    .io_counter_filter_enq_valid                  (ldu0_counter_filter_enq_valid),
    .io_counter_filter_enq_bits_idx               (ldu0_counter_filter_enq_bits_idx),
    .io_counter_filter_enq_bits_way               (ldu0_counter_filter_enq_bits_way),
    .io_perf_0_value                              (ldu0_perf_0_value),
    .io_perf_1_value                              (ldu0_perf_1_value),
    .io_perf_2_value                              (ldu0_perf_2_value),
    .io_perf_3_value                              (ldu0_perf_3_value),
    .io_perf_4_value                              (ldu0_perf_4_value),
    .io_perf_5_value                              (ldu0_perf_5_value),
    .io_perf_6_value                              (ldu0_perf_6_value)
  );

  LoadPipe ldu_1 (
    .clock                                        (clock),
    .reset                                        (reset),
    .io_lsu_req_ready                             (ldu1_lsu_req_ready),
    .io_lsu_req_valid                             (io_lsu_load_1_req_valid),
    .io_lsu_req_bits_cmd                          (io_lsu_load_1_req_bits_cmd),
    .io_lsu_req_bits_vaddr                        (io_lsu_load_1_req_bits_vaddr),
    .io_lsu_req_bits_vaddr_dup                    (io_lsu_load_1_req_bits_vaddr_dup),
    .io_lsu_req_bits_instrtype                    (io_lsu_load_1_req_bits_instrtype),
    .io_lsu_req_bits_isFirstIssue                 (io_lsu_load_1_req_bits_isFirstIssue),
    .io_lsu_req_bits_lqIdx_flag                   (io_lsu_load_1_req_bits_lqIdx_flag),
    .io_lsu_req_bits_lqIdx_value                  (io_lsu_load_1_req_bits_lqIdx_value),
    .io_lsu_resp_valid                            (io_lsu_load_1_resp_valid),
    .io_lsu_resp_bits_data                        (io_lsu_load_1_resp_bits_data),
    .io_lsu_resp_bits_data_delayed                (),
    .io_lsu_resp_bits_miss                        (io_lsu_load_1_resp_bits_miss),
    .io_lsu_resp_bits_mshr_id                     (io_lsu_load_1_resp_bits_mshr_id),
    .io_lsu_resp_bits_meta_prefetch               (io_lsu_load_1_resp_bits_meta_prefetch),
    .io_lsu_resp_bits_handled                     (io_lsu_load_1_resp_bits_handled),
    .io_lsu_resp_bits_tl_error_delayed_tl_denied  (io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied),
    .io_lsu_resp_bits_tl_error_delayed_tl_corrupt (io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt),
    .io_lsu_s1_kill_data_read                     (io_lsu_load_1_s1_kill_data_read),
    .io_lsu_s1_kill                               (io_lsu_load_1_s1_kill),
    .io_lsu_s2_kill                               (io_lsu_load_1_s2_kill),
    .io_lsu_pf_source                             (io_lsu_load_1_pf_source),
    .io_lsu_s1_paddr_dup_lsu                      (io_lsu_load_1_s1_paddr_dup_lsu),
    .io_lsu_s1_paddr_dup_dcache                   (io_lsu_load_1_s1_paddr_dup_dcache),
    .io_lsu_s2_bank_conflict                      (io_lsu_load_1_s2_bank_conflict),
    .io_lsu_s2_mq_nack                            (io_lsu_load_1_s2_mq_nack),
    .io_load128Req                                (io_lsu_load_1_is128Req),
    .io_meta_read_valid                           (ldu1_meta_read_valid),
    .io_meta_read_bits_idx                        (ldu1_meta_read_bits_idx),
    .io_meta_resp_0_coh_state                     (meta_array_resp_1_0_coh_state),
    .io_meta_resp_1_coh_state                     (meta_array_resp_1_1_coh_state),
    .io_meta_resp_2_coh_state                     (meta_array_resp_1_2_coh_state),
    .io_meta_resp_3_coh_state                     (meta_array_resp_1_3_coh_state),
    .io_extra_meta_resp_0_error_tl_denied         (error_array_resp_1_0_tl_denied),
    .io_extra_meta_resp_0_error_tl_corrupt        (error_array_resp_1_0_tl_corrupt),
    .io_extra_meta_resp_0_prefetch                (pf_array_resp_1_0),
    .io_extra_meta_resp_0_access                  (access_array_resp_1_0),
    .io_extra_meta_resp_1_error_tl_denied         (error_array_resp_1_1_tl_denied),
    .io_extra_meta_resp_1_error_tl_corrupt        (error_array_resp_1_1_tl_corrupt),
    .io_extra_meta_resp_1_prefetch                (pf_array_resp_1_1),
    .io_extra_meta_resp_1_access                  (access_array_resp_1_1),
    .io_extra_meta_resp_2_error_tl_denied         (error_array_resp_1_2_tl_denied),
    .io_extra_meta_resp_2_error_tl_corrupt        (error_array_resp_1_2_tl_corrupt),
    .io_extra_meta_resp_2_prefetch                (pf_array_resp_1_2),
    .io_extra_meta_resp_2_access                  (access_array_resp_1_2),
    .io_extra_meta_resp_3_error_tl_denied         (error_array_resp_1_3_tl_denied),
    .io_extra_meta_resp_3_error_tl_corrupt        (error_array_resp_1_3_tl_corrupt),
    .io_extra_meta_resp_3_prefetch                (pf_array_resp_1_3),
    .io_extra_meta_resp_3_access                  (access_array_resp_1_3),
    .io_tag_read_ready                            (core_ldu_tag_read_ready),
    .io_tag_read_valid                            (ldu1_tag_read_valid),
    .io_tag_read_bits_idx                         (ldu1_tag_read_bits_idx),
    .io_tag_resp_0                                (tag_array_resp_1_0),
    .io_tag_resp_1                                (tag_array_resp_1_1),
    .io_tag_resp_2                                (tag_array_resp_1_2),
    .io_tag_resp_3                                (tag_array_resp_1_3),
    .io_banked_data_read_ready                    (data_array_read_1_ready),
    .io_banked_data_read_valid                    (ldu1_banked_data_read_valid),
    .io_banked_data_read_bits_way_en              (ldu1_banked_data_read_bits_way_en),
    .io_banked_data_read_bits_addr                (ldu1_banked_data_read_bits_addr),
    .io_banked_data_read_bits_addr_dup            (ldu1_banked_data_read_bits_addr_dup),
    .io_banked_data_read_bits_bankMask            (ldu1_banked_data_read_bits_bankMask),
    .io_banked_data_read_bits_lqIdx_flag          (ldu1_banked_data_read_bits_lqIdx_flag),
    .io_banked_data_read_bits_lqIdx_value         (ldu1_banked_data_read_bits_lqIdx_value),
    .io_is128Req                                  (ldu1_is128Req),
    .io_banked_data_resp_0_raw_data               (data_array_read_resp_1_0_raw_data),
    .io_banked_data_resp_1_raw_data               (data_array_read_resp_1_1_raw_data),
    .io_read_error_delayed_0                      (data_array_read_error_delayed_1_0),
    .io_read_error_delayed_1                      (data_array_read_error_delayed_1_1),
    .io_access_flag_write_valid                   (ldu1_access_flag_write_valid),
    .io_access_flag_write_bits_idx                (ldu1_access_flag_write_bits_idx),
    .io_access_flag_write_bits_way_en             (ldu1_access_flag_write_bits_way_en),
    .io_prefetch_flag_write_valid                 (ldu1_prefetch_flag_write_valid),
    .io_prefetch_flag_write_bits_idx              (ldu1_prefetch_flag_write_bits_idx),
    .io_prefetch_flag_write_bits_way_en           (ldu1_prefetch_flag_write_bits_way_en),
    .io_bank_conflict_slow                        (data_array_bank_conflict_slow_1),
    .io_miss_req_ready                            (miss_ready_gen_in_2_ready),
    .io_miss_req_valid                            (ldu1_miss_req_valid),
    .io_miss_req_bits_source                      (ldu1_miss_req_bits_source),
    .io_miss_req_bits_pf_source                   (ldu1_miss_req_bits_pf_source),
    .io_miss_req_bits_cmd                         (ldu1_miss_req_bits_cmd),
    .io_miss_req_bits_addr                        (ldu1_miss_req_bits_addr),
    .io_miss_req_bits_vaddr                       (ldu1_miss_req_bits_vaddr),
    .io_miss_req_bits_req_coh_state               (ldu1_miss_req_bits_req_coh_state),
    .io_miss_req_bits_isBtoT                      (ldu1_miss_req_bits_isBtoT),
    .io_miss_req_bits_occupy_way                  (ldu1_miss_req_bits_occupy_way),
    .io_miss_req_bits_cancel                      (ldu1_miss_req_bits_cancel),
    .io_miss_resp_id                              (mq_resp_id),
    .io_miss_resp_handled                         (mq_resp_handled),
    .io_miss_resp_merged                          (mq_resp_merged),
    .io_wbq_conflict_check_valid                  (ldu1_wbq_conflict_check_valid),
    .io_wbq_conflict_check_bits                   (ldu1_wbq_conflict_check_bits),
    .io_wbq_block_miss_req                        (wbq_block_miss_req_1),
    .io_replace_access_valid                      (ldu1_replace_access_valid),
    .io_replace_access_bits_set                   (ldu1_replace_access_bits_set),
    .io_replace_access_bits_way                   (ldu1_replace_access_bits_way),
    .io_occupy_set                                (ldu1_occupy_set),
    .io_occupy_fail                               (mq_occupy_fail_1),
    .io_disable_ld_fast_wakeup                    (data_array_disable_ld_fast_wakeup_1),
    .io_error_valid                               (ldu1_error_valid),
    .io_error_bits_paddr                          (ldu1_error_bits_paddr),
    .io_error_bits_report_to_beu                  (ldu1_error_bits_report_to_beu),
    .io_pseudo_error_valid                        (ctrl_pseudoError_0_valid),
    .io_pseudo_error_bits_0_valid                 (ctrl_pseudoError_0_bits_0_valid),
    .io_pseudo_error_bits_0_mask                  (ctrl_pseudoError_0_bits_0_mask),
    .io_pseudo_tag_error_inj_done                 (ldu1_pseudo_tag_error_inj_done),
    .io_pseudo_data_error_inj_done                (ldu1_pseudo_data_error_inj_done),
    .io_prefetch_info_naive_total_prefetch        (ldu1_prefetch_info_naive_total_prefetch),
    .io_prefetch_info_naive_late_hit_prefetch     (ldu1_prefetch_info_naive_late_hit_prefetch),
    .io_prefetch_info_naive_late_prefetch_hit     (ldu1_prefetch_info_naive_late_prefetch_hit),
    .io_prefetch_info_naive_late_load_hit         (ldu1_prefetch_info_naive_late_load_hit),
    .io_prefetch_info_naive_useful_prefetch       (ldu1_prefetch_info_naive_useful_prefetch),
    .io_prefetch_info_naive_prefetch_hit          (ldu1_prefetch_info_naive_prefetch_hit),
    .io_prefetch_info_fdp_useful_prefetch         (ldu1_prefetch_info_fdp_useful_prefetch),
    .io_prefetch_info_fdp_demand_miss             (ldu1_prefetch_info_fdp_demand_miss),
    .io_prefetch_info_fdp_pollution               (ldu1_prefetch_info_fdp_pollution),
    .io_bloom_filter_query_query_valid            (ldu1_bloom_filter_query_query_valid),
    .io_bloom_filter_query_query_bits_addr        (ldu1_bloom_filter_query_query_bits_addr),
    .io_bloom_filter_query_resp_valid             (bloom_resp_1_valid),
    .io_bloom_filter_query_resp_bits_res          (bloom_resp_1_bits_res),
    .io_counter_filter_query_req_valid            (ldu1_counter_filter_query_req_valid),
    .io_counter_filter_query_req_bits_idx         (ldu1_counter_filter_query_req_bits_idx),
    .io_counter_filter_query_req_bits_way         (ldu1_counter_filter_query_req_bits_way),
    .io_counter_filter_query_resp                 (counter_filter_query_1_resp),
    .io_counter_filter_enq_valid                  (ldu1_counter_filter_enq_valid),
    .io_counter_filter_enq_bits_idx               (ldu1_counter_filter_enq_bits_idx),
    .io_counter_filter_enq_bits_way               (ldu1_counter_filter_enq_bits_way),
    .io_perf_0_value                              (ldu1_perf_0_value),
    .io_perf_1_value                              (ldu1_perf_1_value),
    .io_perf_2_value                              (ldu1_perf_2_value),
    .io_perf_3_value                              (ldu1_perf_3_value),
    .io_perf_4_value                              (ldu1_perf_4_value),
    .io_perf_5_value                              (ldu1_perf_5_value),
    .io_perf_6_value                              (ldu1_perf_6_value)
  );

  LoadPipe ldu_2 (
    .clock                                        (clock),
    .reset                                        (reset),
    .io_lsu_req_ready                             (ldu2_lsu_req_ready),
    .io_lsu_req_valid                             (io_lsu_load_2_req_valid),
    .io_lsu_req_bits_cmd                          (io_lsu_load_2_req_bits_cmd),
    .io_lsu_req_bits_vaddr                        (io_lsu_load_2_req_bits_vaddr),
    .io_lsu_req_bits_vaddr_dup                    (io_lsu_load_2_req_bits_vaddr_dup),
    .io_lsu_req_bits_instrtype                    (io_lsu_load_2_req_bits_instrtype),
    .io_lsu_req_bits_isFirstIssue                 (io_lsu_load_2_req_bits_isFirstIssue),
    .io_lsu_req_bits_lqIdx_flag                   (io_lsu_load_2_req_bits_lqIdx_flag),
    .io_lsu_req_bits_lqIdx_value                  (io_lsu_load_2_req_bits_lqIdx_value),
    .io_lsu_resp_valid                            (io_lsu_load_2_resp_valid),
    .io_lsu_resp_bits_data                        (io_lsu_load_2_resp_bits_data),
    .io_lsu_resp_bits_data_delayed                (),
    .io_lsu_resp_bits_miss                        (io_lsu_load_2_resp_bits_miss),
    .io_lsu_resp_bits_mshr_id                     (io_lsu_load_2_resp_bits_mshr_id),
    .io_lsu_resp_bits_meta_prefetch               (io_lsu_load_2_resp_bits_meta_prefetch),
    .io_lsu_resp_bits_handled                     (io_lsu_load_2_resp_bits_handled),
    .io_lsu_resp_bits_tl_error_delayed_tl_denied  (io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied),
    .io_lsu_resp_bits_tl_error_delayed_tl_corrupt (io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt),
    .io_lsu_s1_kill_data_read                     (io_lsu_load_2_s1_kill_data_read),
    .io_lsu_s1_kill                               (io_lsu_load_2_s1_kill),
    .io_lsu_s2_kill                               (io_lsu_load_2_s2_kill),
    .io_lsu_pf_source                             (io_lsu_load_2_pf_source),
    .io_lsu_s1_paddr_dup_lsu                      (io_lsu_load_2_s1_paddr_dup_lsu),
    .io_lsu_s1_paddr_dup_dcache                   (io_lsu_load_2_s1_paddr_dup_dcache),
    .io_lsu_s2_bank_conflict                      (io_lsu_load_2_s2_bank_conflict),
    .io_lsu_s2_mq_nack                            (io_lsu_load_2_s2_mq_nack),
    .io_load128Req                                (io_lsu_load_2_is128Req),
    .io_meta_read_valid                           (ldu2_meta_read_valid),
    .io_meta_read_bits_idx                        (ldu2_meta_read_bits_idx),
    .io_meta_resp_0_coh_state                     (meta_array_resp_2_0_coh_state),
    .io_meta_resp_1_coh_state                     (meta_array_resp_2_1_coh_state),
    .io_meta_resp_2_coh_state                     (meta_array_resp_2_2_coh_state),
    .io_meta_resp_3_coh_state                     (meta_array_resp_2_3_coh_state),
    .io_extra_meta_resp_0_error_tl_denied         (error_array_resp_2_0_tl_denied),
    .io_extra_meta_resp_0_error_tl_corrupt        (error_array_resp_2_0_tl_corrupt),
    .io_extra_meta_resp_0_prefetch                (pf_array_resp_2_0),
    .io_extra_meta_resp_0_access                  (access_array_resp_2_0),
    .io_extra_meta_resp_1_error_tl_denied         (error_array_resp_2_1_tl_denied),
    .io_extra_meta_resp_1_error_tl_corrupt        (error_array_resp_2_1_tl_corrupt),
    .io_extra_meta_resp_1_prefetch                (pf_array_resp_2_1),
    .io_extra_meta_resp_1_access                  (access_array_resp_2_1),
    .io_extra_meta_resp_2_error_tl_denied         (error_array_resp_2_2_tl_denied),
    .io_extra_meta_resp_2_error_tl_corrupt        (error_array_resp_2_2_tl_corrupt),
    .io_extra_meta_resp_2_prefetch                (pf_array_resp_2_2),
    .io_extra_meta_resp_2_access                  (access_array_resp_2_2),
    .io_extra_meta_resp_3_error_tl_denied         (error_array_resp_2_3_tl_denied),
    .io_extra_meta_resp_3_error_tl_corrupt        (error_array_resp_2_3_tl_corrupt),
    .io_extra_meta_resp_3_prefetch                (pf_array_resp_2_3),
    .io_extra_meta_resp_3_access                  (access_array_resp_2_3),
    .io_tag_read_ready                            (core_ldu_tag_read_ready),
    .io_tag_read_valid                            (ldu2_tag_read_valid),
    .io_tag_read_bits_idx                         (ldu2_tag_read_bits_idx),
    .io_tag_resp_0                                (tag_array_resp_2_0),
    .io_tag_resp_1                                (tag_array_resp_2_1),
    .io_tag_resp_2                                (tag_array_resp_2_2),
    .io_tag_resp_3                                (tag_array_resp_2_3),
    .io_banked_data_read_ready                    (data_array_read_2_ready),
    .io_banked_data_read_valid                    (ldu2_banked_data_read_valid),
    .io_banked_data_read_bits_way_en              (ldu2_banked_data_read_bits_way_en),
    .io_banked_data_read_bits_addr                (ldu2_banked_data_read_bits_addr),
    .io_banked_data_read_bits_addr_dup            (ldu2_banked_data_read_bits_addr_dup),
    .io_banked_data_read_bits_bankMask            (ldu2_banked_data_read_bits_bankMask),
    .io_banked_data_read_bits_lqIdx_flag          (ldu2_banked_data_read_bits_lqIdx_flag),
    .io_banked_data_read_bits_lqIdx_value         (ldu2_banked_data_read_bits_lqIdx_value),
    .io_is128Req                                  (ldu2_is128Req),
    .io_banked_data_resp_0_raw_data               (data_array_read_resp_2_0_raw_data),
    .io_banked_data_resp_1_raw_data               (data_array_read_resp_2_1_raw_data),
    .io_read_error_delayed_0                      (data_array_read_error_delayed_2_0),
    .io_read_error_delayed_1                      (data_array_read_error_delayed_2_1),
    .io_access_flag_write_valid                   (ldu2_access_flag_write_valid),
    .io_access_flag_write_bits_idx                (ldu2_access_flag_write_bits_idx),
    .io_access_flag_write_bits_way_en             (ldu2_access_flag_write_bits_way_en),
    .io_prefetch_flag_write_valid                 (ldu2_prefetch_flag_write_valid),
    .io_prefetch_flag_write_bits_idx              (ldu2_prefetch_flag_write_bits_idx),
    .io_prefetch_flag_write_bits_way_en           (ldu2_prefetch_flag_write_bits_way_en),
    .io_bank_conflict_slow                        (data_array_bank_conflict_slow_2),
    .io_miss_req_ready                            (miss_ready_gen_in_3_ready),
    .io_miss_req_valid                            (ldu2_miss_req_valid),
    .io_miss_req_bits_source                      (ldu2_miss_req_bits_source),
    .io_miss_req_bits_pf_source                   (ldu2_miss_req_bits_pf_source),
    .io_miss_req_bits_cmd                         (ldu2_miss_req_bits_cmd),
    .io_miss_req_bits_addr                        (ldu2_miss_req_bits_addr),
    .io_miss_req_bits_vaddr                       (ldu2_miss_req_bits_vaddr),
    .io_miss_req_bits_req_coh_state               (ldu2_miss_req_bits_req_coh_state),
    .io_miss_req_bits_isBtoT                      (ldu2_miss_req_bits_isBtoT),
    .io_miss_req_bits_occupy_way                  (ldu2_miss_req_bits_occupy_way),
    .io_miss_req_bits_cancel                      (ldu2_miss_req_bits_cancel),
    .io_miss_resp_id                              (mq_resp_id),
    .io_miss_resp_handled                         (mq_resp_handled),
    .io_miss_resp_merged                          (mq_resp_merged),
    .io_wbq_conflict_check_valid                  (ldu2_wbq_conflict_check_valid),
    .io_wbq_conflict_check_bits                   (ldu2_wbq_conflict_check_bits),
    .io_wbq_block_miss_req                        (wbq_block_miss_req_2),
    .io_replace_access_valid                      (ldu2_replace_access_valid),
    .io_replace_access_bits_set                   (ldu2_replace_access_bits_set),
    .io_replace_access_bits_way                   (ldu2_replace_access_bits_way),
    .io_occupy_set                                (ldu2_occupy_set),
    .io_occupy_fail                               (mq_occupy_fail_2),
    .io_disable_ld_fast_wakeup                    (data_array_disable_ld_fast_wakeup_2),
    .io_error_valid                               (ldu2_error_valid),
    .io_error_bits_paddr                          (ldu2_error_bits_paddr),
    .io_error_bits_report_to_beu                  (ldu2_error_bits_report_to_beu),
    .io_pseudo_error_valid                        (ctrl_pseudoError_0_valid),
    .io_pseudo_error_bits_0_valid                 (ctrl_pseudoError_0_bits_0_valid),
    .io_pseudo_error_bits_0_mask                  (ctrl_pseudoError_0_bits_0_mask),
    .io_pseudo_tag_error_inj_done                 (ldu2_pseudo_tag_error_inj_done),
    .io_pseudo_data_error_inj_done                (ldu2_pseudo_data_error_inj_done),
    .io_prefetch_info_naive_total_prefetch        (ldu2_prefetch_info_naive_total_prefetch),
    .io_prefetch_info_naive_late_hit_prefetch     (ldu2_prefetch_info_naive_late_hit_prefetch),
    .io_prefetch_info_naive_late_prefetch_hit     (ldu2_prefetch_info_naive_late_prefetch_hit),
    .io_prefetch_info_naive_late_load_hit         (ldu2_prefetch_info_naive_late_load_hit),
    .io_prefetch_info_naive_useful_prefetch       (ldu2_prefetch_info_naive_useful_prefetch),
    .io_prefetch_info_naive_prefetch_hit          (ldu2_prefetch_info_naive_prefetch_hit),
    .io_prefetch_info_fdp_useful_prefetch         (ldu2_prefetch_info_fdp_useful_prefetch),
    .io_prefetch_info_fdp_demand_miss             (ldu2_prefetch_info_fdp_demand_miss),
    .io_prefetch_info_fdp_pollution               (ldu2_prefetch_info_fdp_pollution),
    .io_bloom_filter_query_query_valid            (ldu2_bloom_filter_query_query_valid),
    .io_bloom_filter_query_query_bits_addr        (ldu2_bloom_filter_query_query_bits_addr),
    .io_bloom_filter_query_resp_valid             (bloom_resp_2_valid),
    .io_bloom_filter_query_resp_bits_res          (bloom_resp_2_bits_res),
    .io_counter_filter_query_req_valid            (ldu2_counter_filter_query_req_valid),
    .io_counter_filter_query_req_bits_idx         (ldu2_counter_filter_query_req_bits_idx),
    .io_counter_filter_query_req_bits_way         (ldu2_counter_filter_query_req_bits_way),
    .io_counter_filter_query_resp                 (counter_filter_query_2_resp),
    .io_counter_filter_enq_valid                  (ldu2_counter_filter_enq_valid),
    .io_counter_filter_enq_bits_idx               (ldu2_counter_filter_enq_bits_idx),
    .io_counter_filter_enq_bits_way               (ldu2_counter_filter_enq_bits_way),
    .io_perf_0_value                              (ldu2_perf_0_value),
    .io_perf_1_value                              (ldu2_perf_1_value),
    .io_perf_2_value                              (ldu2_perf_2_value),
    .io_perf_3_value                              (ldu2_perf_3_value),
    .io_perf_4_value                              (ldu2_perf_4_value),
    .io_perf_5_value                              (ldu2_perf_5_value),
    .io_perf_6_value                              (ldu2_perf_6_value)
  );

  StorePipe stu_0 (
    .io_lsu_req_valid (io_lsu_sta_0_req_valid)
  );

  StorePipe stu_1 (
    .io_lsu_req_valid (io_lsu_sta_1_req_valid)
  );

  MainPipe mainPipe (
    .clock                                         (clock),
    .reset                                         (reset),
    .io_probe_req_ready                            (mp_probe_req_ready),
    .io_probe_req_valid                            (pq_pipe_req_valid),
    .io_probe_req_bits_probe_param                 (pq_pipe_req_bits_probe_param),
    .io_probe_req_bits_probe_need_data             (pq_pipe_req_bits_probe_need_data),
    .io_probe_req_bits_vaddr                       (pq_pipe_req_bits_vaddr),
    .io_probe_req_bits_addr                        (pq_pipe_req_bits_addr),
    .io_probe_req_bits_id                          (pq_pipe_req_bits_id),
    .io_miss_req_ready                             (miss_ready_gen_in_0_ready),
    .io_miss_req_valid                             (mp_miss_req_valid),
    .io_miss_req_bits_source                       (mp_miss_req_bits_source),
    .io_miss_req_bits_cmd                          (mp_miss_req_bits_cmd),
    .io_miss_req_bits_addr                         (mp_miss_req_bits_addr),
    .io_miss_req_bits_vaddr                        (mp_miss_req_bits_vaddr),
    .io_miss_req_bits_full_overwrite               (mp_miss_req_bits_full_overwrite),
    .io_miss_req_bits_word_idx                     (mp_miss_req_bits_word_idx),
    .io_miss_req_bits_amo_data                     (mp_miss_req_bits_amo_data),
    .io_miss_req_bits_amo_mask                     (mp_miss_req_bits_amo_mask),
    .io_miss_req_bits_amo_cmp                      (mp_miss_req_bits_amo_cmp),
    .io_miss_req_bits_req_coh_state                (mp_miss_req_bits_req_coh_state),
    .io_miss_req_bits_id                           (mp_miss_req_bits_id),
    .io_miss_req_bits_isBtoT                       (mp_miss_req_bits_isBtoT),
    .io_miss_req_bits_occupy_way                   (mp_miss_req_bits_occupy_way),
    .io_miss_req_bits_cancel                       (mp_miss_req_bits_cancel),
    .io_miss_req_bits_store_data                   (mp_miss_req_bits_store_data),
    .io_miss_req_bits_store_mask                   (mp_miss_req_bits_store_mask),
    .io_refill_req_ready                           (mp_refill_req_ready),
    .io_refill_req_valid                           (mq_main_pipe_req_valid),
    .io_refill_req_bits_miss_id                    (mq_main_pipe_req_bits_miss_id),
    .io_refill_req_bits_occupy_way                 (mq_main_pipe_req_bits_occupy_way),
    .io_refill_req_bits_miss_fail_cause_evict_btot (mq_main_pipe_req_bits_miss_fail_cause_evict_btot),
    .io_refill_req_bits_source                     (mq_main_pipe_req_bits_source),
    .io_refill_req_bits_cmd                        (mq_main_pipe_req_bits_cmd),
    .io_refill_req_bits_vaddr                      (mq_main_pipe_req_bits_vaddr),
    .io_refill_req_bits_addr                       (mq_main_pipe_req_bits_addr),
    .io_refill_req_bits_word_idx                   (mq_main_pipe_req_bits_word_idx),
    .io_refill_req_bits_amo_data                   (mq_main_pipe_req_bits_amo_data),
    .io_refill_req_bits_amo_mask                   (mq_main_pipe_req_bits_amo_mask),
    .io_refill_req_bits_amo_cmp                    (mq_main_pipe_req_bits_amo_cmp),
    .io_refill_req_bits_pf_source                  (mq_main_pipe_req_bits_pf_source),
    .io_refill_req_bits_access                     (mq_main_pipe_req_bits_access),
    .io_refill_req_bits_id                         (mq_main_pipe_req_bits_id),
    .io_wbq_conflict_check_valid                   (mp_wbq_conflict_check_valid),
    .io_wbq_conflict_check_bits                    (mp_wbq_conflict_check_bits),
    .io_wbq_block_miss_req                         (wbq_block_miss_req_3),
    .io_store_req_ready                            (io_lsu_store_req_ready),
    .io_store_req_valid                            (io_lsu_store_req_valid),
    .io_store_req_bits_vaddr                       (io_lsu_store_req_bits_vaddr),
    .io_store_req_bits_addr                        (io_lsu_store_req_bits_addr),
    .io_store_req_bits_data                        (io_lsu_store_req_bits_data),
    .io_store_req_bits_mask                        (io_lsu_store_req_bits_mask),
    .io_store_req_bits_id                          (io_lsu_store_req_bits_id),
    .io_store_replay_resp_valid                    (mp_store_replay_resp_valid),
    .io_store_replay_resp_bits_id                  (mp_store_replay_resp_bits_id),
    .io_store_hit_resp_valid                       (io_lsu_store_main_pipe_hit_resp_valid),
    .io_store_hit_resp_bits_id                     (io_lsu_store_main_pipe_hit_resp_bits_id),
    .io_atomic_req_ready                           (io_lsu_atomics_req_ready),
    .io_atomic_req_valid                           (io_lsu_atomics_req_valid),
    .io_atomic_req_bits_cmd                        (io_lsu_atomics_req_bits_cmd),
    .io_atomic_req_bits_vaddr                      (io_lsu_atomics_req_bits_vaddr),
    .io_atomic_req_bits_addr                       (io_lsu_atomics_req_bits_addr),
    .io_atomic_req_bits_word_idx                   (io_lsu_atomics_req_bits_word_idx),
    .io_atomic_req_bits_amo_data                   (io_lsu_atomics_req_bits_amo_data),
    .io_atomic_req_bits_amo_mask                   (io_lsu_atomics_req_bits_amo_mask),
    .io_atomic_req_bits_amo_cmp                    (io_lsu_atomics_req_bits_amo_cmp),
    .io_atomic_resp_valid                          (mp_atomic_resp_valid),
    .io_atomic_resp_bits_source                    (mp_atomic_resp_bits_source),
    .io_atomic_resp_bits_data                      (mp_atomic_resp_bits_data),
    .io_atomic_resp_bits_miss                      (mp_atomic_resp_bits_miss),
    .io_atomic_resp_bits_miss_id                   (mp_atomic_resp_bits_miss_id),
    .io_atomic_resp_bits_replay                    (mp_atomic_resp_bits_replay),
    .io_atomic_resp_bits_tl_error_tl_denied        (mp_atomic_resp_bits_tl_error_tl_denied),
    .io_atomic_resp_bits_tl_error_tl_corrupt       (mp_atomic_resp_bits_tl_error_tl_corrupt),
    .io_atomic_resp_bits_ack_miss_queue            (mp_atomic_resp_bits_ack_miss_queue),
    .io_atomic_resp_bits_id                        (mp_atomic_resp_bits_id),
    .io_mainpipe_info_s2_valid                     (mp_mainpipe_info_s2_valid),
    .io_mainpipe_info_s2_miss_id                   (mp_mainpipe_info_s2_miss_id),
    .io_mainpipe_info_s2_replay_to_mq              (mp_mainpipe_info_s2_replay_to_mq),
    .io_mainpipe_info_s2_evict_BtoT_way            (mp_mainpipe_info_s2_evict_BtoT_way),
    .io_mainpipe_info_s2_next_evict_way            (mp_mainpipe_info_s2_next_evict_way),
    .io_mainpipe_info_s3_valid                     (mp_mainpipe_info_s3_valid),
    .io_mainpipe_info_s3_miss_id                   (mp_mainpipe_info_s3_miss_id),
    .io_mainpipe_info_s3_refill_resp               (mp_mainpipe_info_s3_refill_resp),
    .io_refill_info_valid                          (mq_refill_info_valid),
    .io_refill_info_bits_store_data                (mq_refill_info_bits_store_data),
    .io_refill_info_bits_store_mask                (mq_refill_info_bits_store_mask),
    .io_refill_info_bits_miss_param                (mq_refill_info_bits_miss_param),
    .io_refill_info_bits_error_tl_denied           (mq_refill_info_bits_error_tl_denied),
    .io_refill_info_bits_error_tl_corrupt          (mq_refill_info_bits_error_tl_corrupt),
    .io_wb_ready                                   (wbq_req_ready),
    .io_wb_valid                                   (mp_wb_valid),
    .io_wb_bits_param                              (mp_wb_bits_param),
    .io_wb_bits_voluntary                          (mp_wb_bits_voluntary),
    .io_wb_bits_hasData                            (mp_wb_bits_hasData),
    .io_wb_bits_corrupt                            (mp_wb_bits_corrupt),
    .io_wb_bits_dirty                              (mp_wb_bits_dirty),
    .io_wb_bits_addr                               (mp_wb_bits_addr),
    .io_wb_bits_data                               (mp_wb_bits_data),
    .io_data_read_intend                           (mp_data_read_intend),
    .io_data_readline_ready                        (data_array_readline_ready),
    .io_data_readline_valid                        (mp_data_readline_valid),
    .io_data_readline_bits_way_en                  (mp_data_readline_bits_way_en),
    .io_data_readline_bits_addr                    (mp_data_readline_bits_addr),
    .io_data_readline_bits_rmask                   (mp_data_readline_bits_rmask),
    .io_data_readline_can_go                       (mp_data_readline_can_go),
    .io_data_readline_stall                        (mp_data_readline_stall),
    .io_data_readline_can_resp                     (mp_data_readline_can_resp),
    .io_data_resp_0_raw_data                       (data_array_readline_resp_0_raw_data),
    .io_data_resp_1_raw_data                       (data_array_readline_resp_1_raw_data),
    .io_data_resp_2_raw_data                       (data_array_readline_resp_2_raw_data),
    .io_data_resp_3_raw_data                       (data_array_readline_resp_3_raw_data),
    .io_data_resp_4_raw_data                       (data_array_readline_resp_4_raw_data),
    .io_data_resp_5_raw_data                       (data_array_readline_resp_5_raw_data),
    .io_data_resp_6_raw_data                       (data_array_readline_resp_6_raw_data),
    .io_data_resp_7_raw_data                       (data_array_readline_resp_7_raw_data),
    .io_readline_error_delayed                     (data_array_readline_error_delayed),
    .io_data_write_valid                           (mp_data_write_valid),
    .io_data_write_bits_wmask                      (mp_data_write_bits_wmask),
    .io_data_write_bits_data_0                     (mp_data_write_bits_data_0),
    .io_data_write_bits_data_1                     (mp_data_write_bits_data_1),
    .io_data_write_bits_data_2                     (mp_data_write_bits_data_2),
    .io_data_write_bits_data_3                     (mp_data_write_bits_data_3),
    .io_data_write_bits_data_4                     (mp_data_write_bits_data_4),
    .io_data_write_bits_data_5                     (mp_data_write_bits_data_5),
    .io_data_write_bits_data_6                     (mp_data_write_bits_data_6),
    .io_data_write_bits_data_7                     (mp_data_write_bits_data_7),
    .io_data_write_dup_0_valid                     (mp_data_write_dup_0_valid),
    .io_data_write_dup_0_bits_way_en               (mp_data_write_dup_0_bits_way_en),
    .io_data_write_dup_0_bits_addr                 (mp_data_write_dup_0_bits_addr),
    .io_data_write_dup_1_valid                     (mp_data_write_dup_1_valid),
    .io_data_write_dup_1_bits_way_en               (mp_data_write_dup_1_bits_way_en),
    .io_data_write_dup_1_bits_addr                 (mp_data_write_dup_1_bits_addr),
    .io_data_write_dup_2_valid                     (mp_data_write_dup_2_valid),
    .io_data_write_dup_2_bits_way_en               (mp_data_write_dup_2_bits_way_en),
    .io_data_write_dup_2_bits_addr                 (mp_data_write_dup_2_bits_addr),
    .io_data_write_dup_3_valid                     (mp_data_write_dup_3_valid),
    .io_data_write_dup_3_bits_way_en               (mp_data_write_dup_3_bits_way_en),
    .io_data_write_dup_3_bits_addr                 (mp_data_write_dup_3_bits_addr),
    .io_data_write_dup_4_valid                     (mp_data_write_dup_4_valid),
    .io_data_write_dup_4_bits_way_en               (mp_data_write_dup_4_bits_way_en),
    .io_data_write_dup_4_bits_addr                 (mp_data_write_dup_4_bits_addr),
    .io_data_write_dup_5_valid                     (mp_data_write_dup_5_valid),
    .io_data_write_dup_5_bits_way_en               (mp_data_write_dup_5_bits_way_en),
    .io_data_write_dup_5_bits_addr                 (mp_data_write_dup_5_bits_addr),
    .io_data_write_dup_6_valid                     (mp_data_write_dup_6_valid),
    .io_data_write_dup_6_bits_way_en               (mp_data_write_dup_6_bits_way_en),
    .io_data_write_dup_6_bits_addr                 (mp_data_write_dup_6_bits_addr),
    .io_data_write_dup_7_valid                     (mp_data_write_dup_7_valid),
    .io_data_write_dup_7_bits_way_en               (mp_data_write_dup_7_bits_way_en),
    .io_data_write_dup_7_bits_addr                 (mp_data_write_dup_7_bits_addr),
    .io_meta_read_valid                            (mp_meta_read_valid),
    .io_meta_read_bits_idx                         (mp_meta_read_bits_idx),
    .io_meta_resp_0_coh_state                      (meta_array_resp_3_0_coh_state),
    .io_meta_resp_1_coh_state                      (meta_array_resp_3_1_coh_state),
    .io_meta_resp_2_coh_state                      (meta_array_resp_3_2_coh_state),
    .io_meta_resp_3_coh_state                      (meta_array_resp_3_3_coh_state),
    .io_meta_write_valid                           (mp_meta_write_valid),
    .io_meta_write_bits_idx                        (mp_meta_write_bits_idx),
    .io_meta_write_bits_way_en                     (mp_meta_write_bits_way_en),
    .io_meta_write_bits_meta_coh_state             (mp_meta_write_bits_meta_coh_state),
    .io_extra_meta_resp_0_error_tl_denied          (error_array_resp_3_0_tl_denied),
    .io_extra_meta_resp_0_error_tl_corrupt         (error_array_resp_3_0_tl_corrupt),
    .io_extra_meta_resp_0_prefetch                 (pf_array_resp_3_0),
    .io_extra_meta_resp_0_access                   (access_array_resp_3_0),
    .io_extra_meta_resp_1_error_tl_denied          (error_array_resp_3_1_tl_denied),
    .io_extra_meta_resp_1_error_tl_corrupt         (error_array_resp_3_1_tl_corrupt),
    .io_extra_meta_resp_1_prefetch                 (pf_array_resp_3_1),
    .io_extra_meta_resp_1_access                   (access_array_resp_3_1),
    .io_extra_meta_resp_2_error_tl_denied          (error_array_resp_3_2_tl_denied),
    .io_extra_meta_resp_2_error_tl_corrupt         (error_array_resp_3_2_tl_corrupt),
    .io_extra_meta_resp_2_prefetch                 (pf_array_resp_3_2),
    .io_extra_meta_resp_2_access                   (access_array_resp_3_2),
    .io_extra_meta_resp_3_error_tl_denied          (error_array_resp_3_3_tl_denied),
    .io_extra_meta_resp_3_error_tl_corrupt         (error_array_resp_3_3_tl_corrupt),
    .io_extra_meta_resp_3_prefetch                 (pf_array_resp_3_3),
    .io_extra_meta_resp_3_access                   (access_array_resp_3_3),
    .io_error_flag_write_valid                     (mp_error_flag_write_valid),
    .io_error_flag_write_bits_idx                  (mp_error_flag_write_bits_idx),
    .io_error_flag_write_bits_way_en               (mp_error_flag_write_bits_way_en),
    .io_error_flag_write_bits_error_tl_denied      (mp_error_flag_write_bits_error_tl_denied),
    .io_error_flag_write_bits_error_tl_corrupt     (mp_error_flag_write_bits_error_tl_corrupt),
    .io_prefetch_flag_write_valid                  (mp_prefetch_flag_write_valid),
    .io_prefetch_flag_write_bits_idx               (mp_prefetch_flag_write_bits_idx),
    .io_prefetch_flag_write_bits_way_en            (mp_prefetch_flag_write_bits_way_en),
    .io_prefetch_flag_write_bits_source            (mp_prefetch_flag_write_bits_source),
    .io_access_flag_write_valid                    (mp_access_flag_write_valid),
    .io_access_flag_write_bits_idx                 (mp_access_flag_write_bits_idx),
    .io_access_flag_write_bits_way_en              (mp_access_flag_write_bits_way_en),
    .io_access_flag_write_bits_flag                (mp_access_flag_write_bits_flag),
    .io_tag_read_ready                             (tag_array_read_3_ready),
    .io_tag_read_valid                             (mp_tag_read_valid),
    .io_tag_read_bits_idx                          (mp_tag_read_bits_idx),
    .io_tag_resp_0                                 (tag_array_resp_3_0),
    .io_tag_resp_1                                 (tag_array_resp_3_1),
    .io_tag_resp_2                                 (tag_array_resp_3_2),
    .io_tag_resp_3                                 (tag_array_resp_3_3),
    .io_tag_write_valid                            (mp_tag_write_valid),
    .io_tag_write_bits_idx                         (mp_tag_write_bits_idx),
    .io_tag_write_bits_way_en                      (mp_tag_write_bits_way_en),
    .io_tag_write_bits_tag                         (mp_tag_write_bits_tag),
    .io_tag_write_intend                           (mp_tag_write_intend),
    .io_replace_access_valid                       (mp_replace_access_valid),
    .io_replace_access_bits_set                    (mp_replace_access_bits_set),
    .io_replace_access_bits_way                    (mp_replace_access_bits_way),
    .io_replace_way_set_bits                       (mp_replace_way_set_bits),
    .io_replace_way_way                            (core_mp_victim_way),
    .io_evict_set                                  (mp_evict_set),
    .io_btot_ways_for_set                          (mq_btot_ways_for_set),
    .io_replace_req_bits_addr                      (mp_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                     (mp_replace_req_bits_vaddr),
    .io_replace_block                              (mq_replace_block),
    .io_sms_agt_evict_req_valid                    (io_sms_agt_evict_req_valid),
    .io_sms_agt_evict_req_bits_vaddr               (io_sms_agt_evict_req_bits_vaddr),
    .io_status_dup_0_s1_valid                      (),
    .io_status_dup_0_s1_bits_set                   (),
    .io_status_dup_0_s1_bits_way_en                (),
    .io_status_dup_0_s2_valid                      (),
    .io_status_dup_0_s2_bits_set                   (),
    .io_status_dup_0_s2_bits_way_en                (),
    .io_status_dup_0_s3_valid                      (),
    .io_status_dup_0_s3_bits_set                   (),
    .io_status_dup_0_s3_bits_way_en                (),
    .io_status_dup_1_s1_valid                      (),
    .io_status_dup_1_s1_bits_set                   (),
    .io_status_dup_1_s1_bits_way_en                (),
    .io_status_dup_1_s2_valid                      (),
    .io_status_dup_1_s2_bits_set                   (),
    .io_status_dup_1_s2_bits_way_en                (),
    .io_status_dup_1_s3_valid                      (),
    .io_status_dup_1_s3_bits_set                   (),
    .io_status_dup_1_s3_bits_way_en                (),
    .io_status_dup_2_s1_valid                      (),
    .io_status_dup_2_s1_bits_set                   (),
    .io_status_dup_2_s1_bits_way_en                (),
    .io_status_dup_2_s2_valid                      (),
    .io_status_dup_2_s2_bits_set                   (),
    .io_status_dup_2_s2_bits_way_en                (),
    .io_status_dup_2_s3_valid                      (),
    .io_status_dup_2_s3_bits_set                   (),
    .io_status_dup_2_s3_bits_way_en                (),
    .io_status_dup_3_s1_valid                      (),
    .io_status_dup_3_s1_bits_set                   (),
    .io_status_dup_3_s1_bits_way_en                (),
    .io_status_dup_3_s2_valid                      (),
    .io_status_dup_3_s2_bits_set                   (),
    .io_status_dup_3_s2_bits_way_en                (),
    .io_status_dup_3_s3_valid                      (),
    .io_status_dup_3_s3_bits_set                   (),
    .io_status_dup_3_s3_bits_way_en                (),
    .io_status_dup_4_s1_valid                      (),
    .io_status_dup_4_s1_bits_set                   (),
    .io_status_dup_4_s1_bits_way_en                (),
    .io_status_dup_4_s2_valid                      (),
    .io_status_dup_4_s2_bits_set                   (),
    .io_status_dup_4_s2_bits_way_en                (),
    .io_status_dup_4_s3_valid                      (),
    .io_status_dup_4_s3_bits_set                   (),
    .io_status_dup_4_s3_bits_way_en                (),
    .io_status_dup_5_s1_valid                      (),
    .io_status_dup_5_s1_bits_set                   (),
    .io_status_dup_5_s1_bits_way_en                (),
    .io_status_dup_5_s2_valid                      (),
    .io_status_dup_5_s2_bits_set                   (),
    .io_status_dup_5_s2_bits_way_en                (),
    .io_status_dup_5_s3_valid                      (),
    .io_status_dup_5_s3_bits_set                   (),
    .io_status_dup_5_s3_bits_way_en                (),
    .io_status_dup_6_s1_valid                      (),
    .io_status_dup_6_s1_bits_set                   (),
    .io_status_dup_6_s1_bits_way_en                (),
    .io_status_dup_6_s2_valid                      (),
    .io_status_dup_6_s2_bits_set                   (),
    .io_status_dup_6_s2_bits_way_en                (),
    .io_status_dup_6_s3_valid                      (),
    .io_status_dup_6_s3_bits_set                   (),
    .io_status_dup_6_s3_bits_way_en                (),
    .io_status_dup_7_s1_valid                      (),
    .io_status_dup_7_s1_bits_set                   (),
    .io_status_dup_7_s1_bits_way_en                (),
    .io_status_dup_7_s2_valid                      (),
    .io_status_dup_7_s2_bits_set                   (),
    .io_status_dup_7_s2_bits_way_en                (),
    .io_status_dup_7_s3_valid                      (),
    .io_status_dup_7_s3_bits_set                   (),
    .io_status_dup_7_s3_bits_way_en                (),
    .io_status_dup_8_s1_valid                      (),
    .io_status_dup_8_s1_bits_set                   (),
    .io_status_dup_8_s1_bits_way_en                (),
    .io_status_dup_8_s2_valid                      (),
    .io_status_dup_8_s2_bits_set                   (),
    .io_status_dup_8_s2_bits_way_en                (),
    .io_status_dup_8_s3_valid                      (),
    .io_status_dup_8_s3_bits_set                   (),
    .io_status_dup_8_s3_bits_way_en                (),
    .io_status_dup_9_s1_valid                      (),
    .io_status_dup_9_s1_bits_set                   (),
    .io_status_dup_9_s1_bits_way_en                (),
    .io_status_dup_9_s2_valid                      (),
    .io_status_dup_9_s2_bits_set                   (),
    .io_status_dup_9_s2_bits_way_en                (),
    .io_status_dup_9_s3_valid                      (),
    .io_status_dup_9_s3_bits_set                   (),
    .io_status_dup_9_s3_bits_way_en                (),
    .io_status_dup_10_s1_valid                     (),
    .io_status_dup_10_s1_bits_set                  (),
    .io_status_dup_10_s1_bits_way_en               (),
    .io_status_dup_10_s2_valid                     (),
    .io_status_dup_10_s2_bits_set                  (),
    .io_status_dup_10_s2_bits_way_en               (),
    .io_status_dup_10_s3_valid                     (),
    .io_status_dup_10_s3_bits_set                  (),
    .io_status_dup_10_s3_bits_way_en               (),
    .io_status_dup_11_s1_valid                     (),
    .io_status_dup_11_s1_bits_set                  (),
    .io_status_dup_11_s1_bits_way_en               (),
    .io_status_dup_11_s2_valid                     (),
    .io_status_dup_11_s2_bits_set                  (),
    .io_status_dup_11_s2_bits_way_en               (),
    .io_status_dup_11_s3_valid                     (),
    .io_status_dup_11_s3_bits_set                  (),
    .io_status_dup_11_s3_bits_way_en               (),
    .io_status_dup_12_s1_valid                     (),
    .io_status_dup_12_s1_bits_set                  (),
    .io_status_dup_12_s1_bits_way_en               (),
    .io_status_dup_12_s2_valid                     (),
    .io_status_dup_12_s2_bits_set                  (),
    .io_status_dup_12_s2_bits_way_en               (),
    .io_status_dup_12_s3_valid                     (),
    .io_status_dup_12_s3_bits_set                  (),
    .io_status_dup_12_s3_bits_way_en               (),
    .io_status_dup_13_s1_valid                     (),
    .io_status_dup_13_s1_bits_set                  (),
    .io_status_dup_13_s1_bits_way_en               (),
    .io_status_dup_13_s2_valid                     (),
    .io_status_dup_13_s2_bits_set                  (),
    .io_status_dup_13_s2_bits_way_en               (),
    .io_status_dup_13_s3_valid                     (),
    .io_status_dup_13_s3_bits_set                  (),
    .io_status_dup_13_s3_bits_way_en               (),
    .io_status_dup_14_s1_valid                     (),
    .io_status_dup_14_s1_bits_set                  (),
    .io_status_dup_14_s1_bits_way_en               (),
    .io_status_dup_14_s2_valid                     (),
    .io_status_dup_14_s2_bits_set                  (),
    .io_status_dup_14_s2_bits_way_en               (),
    .io_status_dup_14_s3_valid                     (),
    .io_status_dup_14_s3_bits_set                  (),
    .io_status_dup_14_s3_bits_way_en               (),
    .io_status_dup_15_s1_valid                     (),
    .io_status_dup_15_s1_bits_set                  (),
    .io_status_dup_15_s1_bits_way_en               (),
    .io_status_dup_15_s2_valid                     (),
    .io_status_dup_15_s2_bits_set                  (),
    .io_status_dup_15_s2_bits_way_en               (),
    .io_status_dup_15_s3_valid                     (),
    .io_status_dup_15_s3_bits_set                  (),
    .io_status_dup_15_s3_bits_way_en               (),
    .io_status_dup_16_s1_valid                     (),
    .io_status_dup_16_s1_bits_set                  (),
    .io_status_dup_16_s1_bits_way_en               (),
    .io_status_dup_16_s2_valid                     (),
    .io_status_dup_16_s2_bits_set                  (),
    .io_status_dup_16_s2_bits_way_en               (),
    .io_status_dup_16_s3_valid                     (),
    .io_status_dup_16_s3_bits_set                  (),
    .io_status_dup_16_s3_bits_way_en               (),
    .io_status_dup_17_s1_valid                     (),
    .io_status_dup_17_s1_bits_set                  (),
    .io_status_dup_17_s1_bits_way_en               (),
    .io_status_dup_17_s2_valid                     (),
    .io_status_dup_17_s2_bits_set                  (),
    .io_status_dup_17_s2_bits_way_en               (),
    .io_status_dup_17_s3_valid                     (),
    .io_status_dup_17_s3_bits_set                  (),
    .io_status_dup_17_s3_bits_way_en               (),
    .io_status_dup_18_s1_valid                     (),
    .io_status_dup_18_s1_bits_set                  (),
    .io_status_dup_18_s1_bits_way_en               (),
    .io_status_dup_18_s2_valid                     (),
    .io_status_dup_18_s2_bits_set                  (),
    .io_status_dup_18_s2_bits_way_en               (),
    .io_status_dup_18_s3_valid                     (),
    .io_status_dup_18_s3_bits_set                  (),
    .io_status_dup_18_s3_bits_way_en               (),
    .io_status_dup_19_s1_valid                     (),
    .io_status_dup_19_s1_bits_set                  (),
    .io_status_dup_19_s1_bits_way_en               (),
    .io_status_dup_19_s2_valid                     (),
    .io_status_dup_19_s2_bits_set                  (),
    .io_status_dup_19_s2_bits_way_en               (),
    .io_status_dup_19_s3_valid                     (),
    .io_status_dup_19_s3_bits_set                  (),
    .io_status_dup_19_s3_bits_way_en               (),
    .io_status_dup_20_s1_valid                     (),
    .io_status_dup_20_s1_bits_set                  (),
    .io_status_dup_20_s1_bits_way_en               (),
    .io_status_dup_20_s2_valid                     (),
    .io_status_dup_20_s2_bits_set                  (),
    .io_status_dup_20_s2_bits_way_en               (),
    .io_status_dup_20_s3_valid                     (),
    .io_status_dup_20_s3_bits_set                  (),
    .io_status_dup_20_s3_bits_way_en               (),
    .io_status_dup_21_s1_valid                     (),
    .io_status_dup_21_s1_bits_set                  (),
    .io_status_dup_21_s1_bits_way_en               (),
    .io_status_dup_21_s2_valid                     (),
    .io_status_dup_21_s2_bits_set                  (),
    .io_status_dup_21_s2_bits_way_en               (),
    .io_status_dup_21_s3_valid                     (),
    .io_status_dup_21_s3_bits_set                  (),
    .io_status_dup_21_s3_bits_way_en               (),
    .io_status_dup_22_s1_valid                     (),
    .io_status_dup_22_s1_bits_set                  (),
    .io_status_dup_22_s1_bits_way_en               (),
    .io_status_dup_22_s2_valid                     (),
    .io_status_dup_22_s2_bits_set                  (),
    .io_status_dup_22_s2_bits_way_en               (),
    .io_status_dup_22_s3_valid                     (),
    .io_status_dup_22_s3_bits_set                  (),
    .io_status_dup_22_s3_bits_way_en               (),
    .io_status_dup_23_s1_valid                     (),
    .io_status_dup_23_s1_bits_set                  (),
    .io_status_dup_23_s1_bits_way_en               (),
    .io_status_dup_23_s2_valid                     (),
    .io_status_dup_23_s2_bits_set                  (),
    .io_status_dup_23_s2_bits_way_en               (),
    .io_status_dup_23_s3_valid                     (),
    .io_status_dup_23_s3_bits_set                  (),
    .io_status_dup_23_s3_bits_way_en               (),
    .io_lrsc_locked_block_valid                    (mp_lrsc_locked_block_valid),
    .io_lrsc_locked_block_bits                     (mp_lrsc_locked_block_bits),
    .io_invalid_resv_set                           (core_mp_invalid_resv_set),
    .io_update_resv_set                            (mp_update_resv_set),
    .io_block_lr                                   (io_lsu_atomics_block_lr),
    .io_error_valid                                (mp_error_valid),
    .io_error_bits_paddr                           (mp_error_bits_paddr),
    .io_error_bits_report_to_beu                   (mp_error_bits_report_to_beu),
    .io_pseudo_error_valid                         (ctrl_pseudoError_0_valid),
    .io_pseudo_error_bits_0_valid                  (ctrl_pseudoError_0_bits_0_valid),
    .io_pseudo_error_bits_0_mask                   (ctrl_pseudoError_0_bits_0_mask),
    .io_pseudo_tag_error_inj_done                  (mp_pseudo_tag_error_inj_done),
    .io_pseudo_data_error_inj_done                 (mp_pseudo_data_error_inj_done),
    .io_bloom_filter_query_set_valid               (mp_bloom_filter_query_set_valid),
    .io_bloom_filter_query_set_bits_addr           (mp_bloom_filter_query_set_bits_addr),
    .io_bloom_filter_query_clr_valid               (mp_bloom_filter_query_clr_valid),
    .io_bloom_filter_query_clr_bits_addr           (mp_bloom_filter_query_clr_bits_addr),
    .io_perf_0_value                               (mp_perf_0_value),
    .io_perf_1_value                               (mp_perf_1_value),
    .io_perf_2_value                               (mp_perf_2_value),
    .io_perf_3_value                               (mp_perf_3_value)
  );

  MissQueue missQueue (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_hartId                                        (io_hartId),
    .io_req_ready                                     (mq_req_ready),
    .io_req_valid                                     (miss_req_arb_out_valid),
    .io_req_bits_source                               (miss_req_arb_out_bits_source),
    .io_req_bits_pf_source                            (miss_req_arb_out_bits_pf_source),
    .io_req_bits_cmd                                  (miss_req_arb_out_bits_cmd),
    .io_req_bits_addr                                 (miss_req_arb_out_bits_addr),
    .io_req_bits_vaddr                                (miss_req_arb_out_bits_vaddr),
    .io_req_bits_full_overwrite                       (miss_req_arb_out_bits_full_overwrite),
    .io_req_bits_word_idx                             (miss_req_arb_out_bits_word_idx),
    .io_req_bits_amo_data                             (miss_req_arb_out_bits_amo_data),
    .io_req_bits_amo_mask                             (miss_req_arb_out_bits_amo_mask),
    .io_req_bits_amo_cmp                              (miss_req_arb_out_bits_amo_cmp),
    .io_req_bits_req_coh_state                        (miss_req_arb_out_bits_req_coh_state),
    .io_req_bits_id                                   (miss_req_arb_out_bits_id),
    .io_req_bits_isBtoT                               (miss_req_arb_out_bits_isBtoT),
    .io_req_bits_occupy_way                           (miss_req_arb_out_bits_occupy_way),
    .io_req_bits_cancel                               (miss_req_arb_out_bits_cancel),
    .io_req_bits_store_data                           (miss_req_arb_out_bits_store_data),
    .io_req_bits_store_mask                           (miss_req_arb_out_bits_store_mask),
    .io_resp_id                                       (mq_resp_id),
    .io_resp_handled                                  (mq_resp_handled),
    .io_resp_merged                                   (mq_resp_merged),
    .io_cmo_req_ready                                 (io_cmoOpReq_ready),
    .io_cmo_req_valid                                 (io_cmoOpReq_valid),
    .io_cmo_req_bits_opcode                           (io_cmoOpReq_bits_opcode),
    .io_cmo_req_bits_address                          (io_cmoOpReq_bits_address),
    .io_cmo_resp_ready                                (io_cmoOpResp_ready),
    .io_cmo_resp_valid                                (io_cmoOpResp_valid),
    .io_cmo_resp_bits_denied                          (io_cmoOpResp_bits_denied),
    .io_cmo_resp_bits_corrupt                         (io_cmoOpResp_bits_corrupt),
    .io_queryMQ_0_req_bits_source                     (miss_ready_gen_queryMQ_0_req_bits_source),
    .io_queryMQ_0_req_bits_addr                       (miss_ready_gen_queryMQ_0_req_bits_addr),
    .io_queryMQ_0_req_bits_vaddr                      (miss_ready_gen_queryMQ_0_req_bits_vaddr),
    .io_queryMQ_0_ready                               (mq_queryMQ_0_ready),
    .io_queryMQ_1_req_bits_source                     (miss_ready_gen_queryMQ_1_req_bits_source),
    .io_queryMQ_1_req_bits_addr                       (miss_ready_gen_queryMQ_1_req_bits_addr),
    .io_queryMQ_1_req_bits_vaddr                      (miss_ready_gen_queryMQ_1_req_bits_vaddr),
    .io_queryMQ_1_ready                               (mq_queryMQ_1_ready),
    .io_queryMQ_2_req_bits_source                     (miss_ready_gen_queryMQ_2_req_bits_source),
    .io_queryMQ_2_req_bits_addr                       (miss_ready_gen_queryMQ_2_req_bits_addr),
    .io_queryMQ_2_req_bits_vaddr                      (miss_ready_gen_queryMQ_2_req_bits_vaddr),
    .io_queryMQ_2_ready                               (mq_queryMQ_2_ready),
    .io_queryMQ_3_req_bits_source                     (miss_ready_gen_queryMQ_3_req_bits_source),
    .io_queryMQ_3_req_bits_addr                       (miss_ready_gen_queryMQ_3_req_bits_addr),
    .io_queryMQ_3_req_bits_vaddr                      (miss_ready_gen_queryMQ_3_req_bits_vaddr),
    .io_queryMQ_3_ready                               (mq_queryMQ_3_ready),
    .io_mem_acquire_ready                             (auto_client_out_a_ready),
    .io_mem_acquire_valid                             (mq_mem_acquire_valid),
    .io_mem_acquire_bits_opcode                       (auto_client_out_a_bits_opcode),
    .io_mem_acquire_bits_param                        (auto_client_out_a_bits_param),
    .io_mem_acquire_bits_size                         (auto_client_out_a_bits_size),
    .io_mem_acquire_bits_source                       (auto_client_out_a_bits_source),
    .io_mem_acquire_bits_address                      (mq_mem_acquire_bits_address),
    .io_mem_acquire_bits_user_alias                   (auto_client_out_a_bits_user_alias),
    .io_mem_acquire_bits_user_vaddr                   (auto_client_out_a_bits_user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (auto_client_out_a_bits_user_reqSource),
    .io_mem_acquire_bits_user_needHint                (auto_client_out_a_bits_user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (auto_client_out_a_bits_echo_isKeyword),
    .io_mem_acquire_bits_mask                         (auto_client_out_a_bits_mask),
    .io_mem_grant_ready                               (mq_mem_grant_ready),
    .io_mem_grant_valid                               (core_mq_grant_valid),
    .io_mem_grant_bits_opcode                         (auto_client_out_d_bits_opcode),
    .io_mem_grant_bits_param                          (auto_client_out_d_bits_param),
    .io_mem_grant_bits_size                           (auto_client_out_d_bits_size),
    .io_mem_grant_bits_source                         (auto_client_out_d_bits_source),
    .io_mem_grant_bits_sink                           (auto_client_out_d_bits_sink),
    .io_mem_grant_bits_denied                         (auto_client_out_d_bits_denied),
    .io_mem_grant_bits_data                           (auto_client_out_d_bits_data),
    .io_mem_grant_bits_corrupt                        (auto_client_out_d_bits_corrupt),
    .io_mem_finish_ready                              (auto_client_out_e_ready),
    .io_mem_finish_valid                              (auto_client_out_e_valid),
    .io_mem_finish_bits_sink                          (auto_client_out_e_bits_sink),
    .io_l2_hint_valid                                 (core_mq_l2_hint_valid),
    .io_l2_hint_bits_sourceId                         (core_mq_l2_hint_source_id),
    .io_main_pipe_req_ready                           (mp_refill_req_ready),
    .io_main_pipe_req_valid                           (mq_main_pipe_req_valid),
    .io_main_pipe_req_bits_miss_id                    (mq_main_pipe_req_bits_miss_id),
    .io_main_pipe_req_bits_occupy_way                 (mq_main_pipe_req_bits_occupy_way),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (mq_main_pipe_req_bits_miss_fail_cause_evict_btot),
    .io_main_pipe_req_bits_source                     (mq_main_pipe_req_bits_source),
    .io_main_pipe_req_bits_cmd                        (mq_main_pipe_req_bits_cmd),
    .io_main_pipe_req_bits_vaddr                      (mq_main_pipe_req_bits_vaddr),
    .io_main_pipe_req_bits_addr                       (mq_main_pipe_req_bits_addr),
    .io_main_pipe_req_bits_word_idx                   (mq_main_pipe_req_bits_word_idx),
    .io_main_pipe_req_bits_amo_data                   (mq_main_pipe_req_bits_amo_data),
    .io_main_pipe_req_bits_amo_mask                   (mq_main_pipe_req_bits_amo_mask),
    .io_main_pipe_req_bits_amo_cmp                    (mq_main_pipe_req_bits_amo_cmp),
    .io_main_pipe_req_bits_pf_source                  (mq_main_pipe_req_bits_pf_source),
    .io_main_pipe_req_bits_access                     (mq_main_pipe_req_bits_access),
    .io_main_pipe_req_bits_id                         (mq_main_pipe_req_bits_id),
    .io_main_pipe_resp_valid                          (core_mq_mp_resp_valid),
    .io_main_pipe_resp_bits_miss_id                   (core_mq_mp_resp_miss_id),
    .io_main_pipe_resp_bits_ack_miss_queue            (core_mq_mp_resp_ack_miss_queue),
    .io_mainpipe_info_s2_valid                        (mp_mainpipe_info_s2_valid),
    .io_mainpipe_info_s2_miss_id                      (mp_mainpipe_info_s2_miss_id),
    .io_mainpipe_info_s2_replay_to_mq                 (mp_mainpipe_info_s2_replay_to_mq),
    .io_mainpipe_info_s2_evict_BtoT_way               (mp_mainpipe_info_s2_evict_BtoT_way),
    .io_mainpipe_info_s2_next_evict_way               (mp_mainpipe_info_s2_next_evict_way),
    .io_mainpipe_info_s3_valid                        (mp_mainpipe_info_s3_valid),
    .io_mainpipe_info_s3_miss_id                      (mp_mainpipe_info_s3_miss_id),
    .io_mainpipe_info_s3_refill_resp                  (mp_mainpipe_info_s3_refill_resp),
    .io_refill_info_valid                             (mq_refill_info_valid),
    .io_refill_info_bits_store_data                   (mq_refill_info_bits_store_data),
    .io_refill_info_bits_store_mask                   (mq_refill_info_bits_store_mask),
    .io_refill_info_bits_miss_param                   (mq_refill_info_bits_miss_param),
    .io_refill_info_bits_error_tl_denied              (mq_refill_info_bits_error_tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (mq_refill_info_bits_error_tl_corrupt),
    .io_probe_req_bits_addr                           (auto_client_out_b_bits_address),
    .io_probe_req_bits_vaddr                          (core_mq_probe_vaddr),
    .io_probe_block                                   (mq_probe_block),
    .io_replace_req_bits_addr                         (mp_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (mp_replace_req_bits_vaddr),
    .io_replace_block                                 (mq_replace_block),
    .io_evict_set                                     (mp_evict_set),
    .io_btot_ways_for_set                             (mq_btot_ways_for_set),
    .io_occupy_set_0                                  (ldu0_occupy_set),
    .io_occupy_set_1                                  (ldu1_occupy_set),
    .io_occupy_set_2                                  (ldu2_occupy_set),
    .io_occupy_fail_0                                 (mq_occupy_fail_0),
    .io_occupy_fail_1                                 (mq_occupy_fail_1),
    .io_occupy_fail_2                                 (mq_occupy_fail_2),
    .io_wbq_block_miss_req                            (wbq_block_miss_req_4),
    .io_forward_0_valid                               (io_lsu_forward_mshr_0_valid),
    .io_forward_0_mshrid                              (io_lsu_forward_mshr_0_mshrid),
    .io_forward_0_paddr                               (io_lsu_forward_mshr_0_paddr),
    .io_forward_0_forward_mshr                        (io_lsu_forward_mshr_0_forward_mshr),
    .io_forward_0_forwardData_0                       (io_lsu_forward_mshr_0_forwardData_0),
    .io_forward_0_forwardData_1                       (io_lsu_forward_mshr_0_forwardData_1),
    .io_forward_0_forwardData_2                       (io_lsu_forward_mshr_0_forwardData_2),
    .io_forward_0_forwardData_3                       (io_lsu_forward_mshr_0_forwardData_3),
    .io_forward_0_forwardData_4                       (io_lsu_forward_mshr_0_forwardData_4),
    .io_forward_0_forwardData_5                       (io_lsu_forward_mshr_0_forwardData_5),
    .io_forward_0_forwardData_6                       (io_lsu_forward_mshr_0_forwardData_6),
    .io_forward_0_forwardData_7                       (io_lsu_forward_mshr_0_forwardData_7),
    .io_forward_0_forwardData_8                       (io_lsu_forward_mshr_0_forwardData_8),
    .io_forward_0_forwardData_9                       (io_lsu_forward_mshr_0_forwardData_9),
    .io_forward_0_forwardData_10                      (io_lsu_forward_mshr_0_forwardData_10),
    .io_forward_0_forwardData_11                      (io_lsu_forward_mshr_0_forwardData_11),
    .io_forward_0_forwardData_12                      (io_lsu_forward_mshr_0_forwardData_12),
    .io_forward_0_forwardData_13                      (io_lsu_forward_mshr_0_forwardData_13),
    .io_forward_0_forwardData_14                      (io_lsu_forward_mshr_0_forwardData_14),
    .io_forward_0_forwardData_15                      (io_lsu_forward_mshr_0_forwardData_15),
    .io_forward_0_forward_result_valid                (io_lsu_forward_mshr_0_forward_result_valid),
    .io_forward_0_denied                              (io_lsu_forward_mshr_0_denied),
    .io_forward_0_corrupt                             (io_lsu_forward_mshr_0_corrupt),
    .io_forward_1_valid                               (io_lsu_forward_mshr_1_valid),
    .io_forward_1_mshrid                              (io_lsu_forward_mshr_1_mshrid),
    .io_forward_1_paddr                               (io_lsu_forward_mshr_1_paddr),
    .io_forward_1_forward_mshr                        (io_lsu_forward_mshr_1_forward_mshr),
    .io_forward_1_forwardData_0                       (io_lsu_forward_mshr_1_forwardData_0),
    .io_forward_1_forwardData_1                       (io_lsu_forward_mshr_1_forwardData_1),
    .io_forward_1_forwardData_2                       (io_lsu_forward_mshr_1_forwardData_2),
    .io_forward_1_forwardData_3                       (io_lsu_forward_mshr_1_forwardData_3),
    .io_forward_1_forwardData_4                       (io_lsu_forward_mshr_1_forwardData_4),
    .io_forward_1_forwardData_5                       (io_lsu_forward_mshr_1_forwardData_5),
    .io_forward_1_forwardData_6                       (io_lsu_forward_mshr_1_forwardData_6),
    .io_forward_1_forwardData_7                       (io_lsu_forward_mshr_1_forwardData_7),
    .io_forward_1_forwardData_8                       (io_lsu_forward_mshr_1_forwardData_8),
    .io_forward_1_forwardData_9                       (io_lsu_forward_mshr_1_forwardData_9),
    .io_forward_1_forwardData_10                      (io_lsu_forward_mshr_1_forwardData_10),
    .io_forward_1_forwardData_11                      (io_lsu_forward_mshr_1_forwardData_11),
    .io_forward_1_forwardData_12                      (io_lsu_forward_mshr_1_forwardData_12),
    .io_forward_1_forwardData_13                      (io_lsu_forward_mshr_1_forwardData_13),
    .io_forward_1_forwardData_14                      (io_lsu_forward_mshr_1_forwardData_14),
    .io_forward_1_forwardData_15                      (io_lsu_forward_mshr_1_forwardData_15),
    .io_forward_1_forward_result_valid                (io_lsu_forward_mshr_1_forward_result_valid),
    .io_forward_1_denied                              (io_lsu_forward_mshr_1_denied),
    .io_forward_1_corrupt                             (io_lsu_forward_mshr_1_corrupt),
    .io_forward_2_valid                               (io_lsu_forward_mshr_2_valid),
    .io_forward_2_mshrid                              (io_lsu_forward_mshr_2_mshrid),
    .io_forward_2_paddr                               (io_lsu_forward_mshr_2_paddr),
    .io_forward_2_forward_mshr                        (io_lsu_forward_mshr_2_forward_mshr),
    .io_forward_2_forwardData_0                       (io_lsu_forward_mshr_2_forwardData_0),
    .io_forward_2_forwardData_1                       (io_lsu_forward_mshr_2_forwardData_1),
    .io_forward_2_forwardData_2                       (io_lsu_forward_mshr_2_forwardData_2),
    .io_forward_2_forwardData_3                       (io_lsu_forward_mshr_2_forwardData_3),
    .io_forward_2_forwardData_4                       (io_lsu_forward_mshr_2_forwardData_4),
    .io_forward_2_forwardData_5                       (io_lsu_forward_mshr_2_forwardData_5),
    .io_forward_2_forwardData_6                       (io_lsu_forward_mshr_2_forwardData_6),
    .io_forward_2_forwardData_7                       (io_lsu_forward_mshr_2_forwardData_7),
    .io_forward_2_forwardData_8                       (io_lsu_forward_mshr_2_forwardData_8),
    .io_forward_2_forwardData_9                       (io_lsu_forward_mshr_2_forwardData_9),
    .io_forward_2_forwardData_10                      (io_lsu_forward_mshr_2_forwardData_10),
    .io_forward_2_forwardData_11                      (io_lsu_forward_mshr_2_forwardData_11),
    .io_forward_2_forwardData_12                      (io_lsu_forward_mshr_2_forwardData_12),
    .io_forward_2_forwardData_13                      (io_lsu_forward_mshr_2_forwardData_13),
    .io_forward_2_forwardData_14                      (io_lsu_forward_mshr_2_forwardData_14),
    .io_forward_2_forwardData_15                      (io_lsu_forward_mshr_2_forwardData_15),
    .io_forward_2_forward_result_valid                (io_lsu_forward_mshr_2_forward_result_valid),
    .io_forward_2_denied                              (io_lsu_forward_mshr_2_denied),
    .io_forward_2_corrupt                             (io_lsu_forward_mshr_2_corrupt),
    .io_l2_pf_store_only                              (core_mq_l2_pf_store_only),
    .io_lqEmpty                                       (io_lqEmpty),
    .io_prefetch_info_naive_late_miss_prefetch        (mq_prefetch_info_naive_late_miss_prefetch),
    .io_prefetch_info_fdp_late_miss_prefetch          (mq_prefetch_info_fdp_late_miss_prefetch),
    .io_prefetch_info_fdp_prefetch_monitor_cnt        (),
    .io_prefetch_info_fdp_total_prefetch              (),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (io_wfi_wfiSafe),
    .io_debugTopDown_robHeadVaddr_valid               (io_debugTopDown_robHeadVaddr_valid),
    .io_debugTopDown_robHeadVaddr_bits                (io_debugTopDown_robHeadVaddr_bits),
    .io_debugTopDown_robHeadMissInDCache              (io_debugTopDown_robHeadMissInDCache),
    .io_l1Miss                                        (io_l1Miss),
    .io_perf_0_value                                  (mq_perf_0_value),
    .io_perf_1_value                                  (mq_perf_1_value),
    .io_perf_2_value                                  (mq_perf_2_value),
    .io_perf_3_value                                  (mq_perf_3_value),
    .io_perf_4_value                                  (mq_perf_4_value),
    .gatewayIn_packed_41_bore                         (gatewayIn_packed_41_bore)
  );

  ProbeQueue probeQueue (
    .clock                            (clock),
    .reset                            (reset),
    .io_mem_probe_ready               (pq_mem_probe_ready),
    .io_mem_probe_valid               (core_pq_probe_valid),
    .io_mem_probe_bits_opcode         (auto_client_out_b_bits_opcode),
    .io_mem_probe_bits_param          (auto_client_out_b_bits_param),
    .io_mem_probe_bits_address        (auto_client_out_b_bits_address),
    .io_mem_probe_bits_data           (auto_client_out_b_bits_data),
    .io_pipe_req_ready                (mp_probe_req_ready),
    .io_pipe_req_valid                (pq_pipe_req_valid),
    .io_pipe_req_bits_probe_param     (pq_pipe_req_bits_probe_param),
    .io_pipe_req_bits_probe_need_data (pq_pipe_req_bits_probe_need_data),
    .io_pipe_req_bits_vaddr           (pq_pipe_req_bits_vaddr),
    .io_pipe_req_bits_addr            (pq_pipe_req_bits_addr),
    .io_pipe_req_bits_id              (pq_pipe_req_bits_id),
    .io_lrsc_locked_block_valid       (mp_lrsc_locked_block_valid),
    .io_lrsc_locked_block_bits        (mp_lrsc_locked_block_bits),
    .io_update_resv_set               (mp_update_resv_set),
    .io_perf_0_value                  (pq_perf_0_value),
    .io_perf_1_value                  (pq_perf_1_value),
    .io_perf_2_value                  (pq_perf_2_value),
    .io_perf_3_value                  (pq_perf_3_value),
    .io_perf_4_value                  (pq_perf_4_value)
  );

  WritebackQueue wb (
    .clock                              (clock),
    .reset                              (reset),
    .io_req_ready                       (wbq_req_ready),
    .io_req_valid                       (mp_wb_valid),
    .io_req_bits_param                  (mp_wb_bits_param),
    .io_req_bits_voluntary              (mp_wb_bits_voluntary),
    .io_req_bits_hasData                (mp_wb_bits_hasData),
    .io_req_bits_corrupt                (mp_wb_bits_corrupt),
    .io_req_bits_dirty                  (mp_wb_bits_dirty),
    .io_req_bits_addr                   (mp_wb_bits_addr),
    .io_req_bits_data                   (mp_wb_bits_data),
    .io_mem_release_ready               (auto_client_out_c_ready),
    .io_mem_release_valid               (wbq_mem_release_valid),
    .io_mem_release_bits_opcode         (auto_client_out_c_bits_opcode),
    .io_mem_release_bits_param          (auto_client_out_c_bits_param),
    .io_mem_release_bits_size           (auto_client_out_c_bits_size),
    .io_mem_release_bits_source         (auto_client_out_c_bits_source),
    .io_mem_release_bits_address        (wbq_mem_release_bits_address),
    .io_mem_release_bits_data           (auto_client_out_c_bits_data),
    .io_mem_release_bits_corrupt        (auto_client_out_c_bits_corrupt),
    .io_mem_grant_valid                 (core_wb_grant_valid),
    .io_mem_grant_bits_source           (auto_client_out_d_bits_source),
    .io_miss_req_conflict_check_0_valid (ldu0_wbq_conflict_check_valid),
    .io_miss_req_conflict_check_0_bits  (ldu0_wbq_conflict_check_bits),
    .io_miss_req_conflict_check_1_valid (ldu1_wbq_conflict_check_valid),
    .io_miss_req_conflict_check_1_bits  (ldu1_wbq_conflict_check_bits),
    .io_miss_req_conflict_check_2_valid (ldu2_wbq_conflict_check_valid),
    .io_miss_req_conflict_check_2_bits  (ldu2_wbq_conflict_check_bits),
    .io_miss_req_conflict_check_3_valid (mp_wbq_conflict_check_valid),
    .io_miss_req_conflict_check_3_bits  (mp_wbq_conflict_check_bits),
    .io_miss_req_conflict_check_4_valid (miss_req_arb_out_valid),
    .io_miss_req_conflict_check_4_bits  (miss_req_arb_out_bits_addr),
    .io_block_miss_req_0                (wbq_block_miss_req_0),
    .io_block_miss_req_1                (wbq_block_miss_req_1),
    .io_block_miss_req_2                (wbq_block_miss_req_2),
    .io_block_miss_req_3                (wbq_block_miss_req_3),
    .io_block_miss_req_4                (wbq_block_miss_req_4),
    .io_perf_0_value                    (wbq_perf_0_value),
    .io_perf_1_value                    (wbq_perf_1_value),
    .io_perf_2_value                    (wbq_perf_2_value),
    .io_perf_3_value                    (wbq_perf_3_value),
    .io_perf_4_value                    (wbq_perf_4_value)
  );

  Arbiter1_TagWriteReq tag_write_arb (
    .io_in_0_valid       (mp_tag_write_valid),
    .io_in_0_bits_idx    (mp_tag_write_bits_idx),
    .io_in_0_bits_way_en (mp_tag_write_bits_way_en),
    .io_in_0_bits_tag    (mp_tag_write_bits_tag),
    .io_out_valid        (tag_write_arb_out_valid),
    .io_out_bits_idx     (tag_write_arb_out_bits_idx),
    .io_out_bits_way_en  (tag_write_arb_out_bits_way_en),
    .io_out_bits_tag     (tag_write_arb_out_bits_tag)
  );

  Arbiter1_L1BankedDataWriteReq dataWriteArb (
    .io_in_0_valid       (mp_data_write_valid),
    .io_in_0_bits_wmask  (mp_data_write_bits_wmask),
    .io_in_0_bits_data_0 (mp_data_write_bits_data_0),
    .io_in_0_bits_data_1 (mp_data_write_bits_data_1),
    .io_in_0_bits_data_2 (mp_data_write_bits_data_2),
    .io_in_0_bits_data_3 (mp_data_write_bits_data_3),
    .io_in_0_bits_data_4 (mp_data_write_bits_data_4),
    .io_in_0_bits_data_5 (mp_data_write_bits_data_5),
    .io_in_0_bits_data_6 (mp_data_write_bits_data_6),
    .io_in_0_bits_data_7 (mp_data_write_bits_data_7),
    .io_out_valid        (data_write_arb_out_valid),
    .io_out_bits_wmask   (data_write_arb_out_bits_wmask),
    .io_out_bits_data_0  (data_write_arb_out_bits_data_0),
    .io_out_bits_data_1  (data_write_arb_out_bits_data_1),
    .io_out_bits_data_2  (data_write_arb_out_bits_data_2),
    .io_out_bits_data_3  (data_write_arb_out_bits_data_3),
    .io_out_bits_data_4  (data_write_arb_out_bits_data_4),
    .io_out_bits_data_5  (data_write_arb_out_bits_data_5),
    .io_out_bits_data_6  (data_write_arb_out_bits_data_6),
    .io_out_bits_data_7  (data_write_arb_out_bits_data_7)
  );

  Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup (
    .io_in_0_valid       (mp_data_write_dup_0_valid),
    .io_in_0_bits_way_en (mp_data_write_dup_0_bits_way_en),
    .io_in_0_bits_addr   (mp_data_write_dup_0_bits_addr),
    .io_out_valid        (data_write_arb_dup0_out_valid),
    .io_out_bits_way_en  (data_write_arb_dup0_out_bits_way_en),
    .io_out_bits_addr    (data_write_arb_dup0_out_bits_addr)
  );

  Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_1 (
    .io_in_0_valid       (mp_data_write_dup_1_valid),
    .io_in_0_bits_way_en (mp_data_write_dup_1_bits_way_en),
    .io_in_0_bits_addr   (mp_data_write_dup_1_bits_addr),
    .io_out_valid        (data_write_arb_dup1_out_valid),
    .io_out_bits_way_en  (data_write_arb_dup1_out_bits_way_en),
    .io_out_bits_addr    (data_write_arb_dup1_out_bits_addr)
  );

  Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_2 (
    .io_in_0_valid       (mp_data_write_dup_2_valid),
    .io_in_0_bits_way_en (mp_data_write_dup_2_bits_way_en),
    .io_in_0_bits_addr   (mp_data_write_dup_2_bits_addr),
    .io_out_valid        (data_write_arb_dup2_out_valid),
    .io_out_bits_way_en  (data_write_arb_dup2_out_bits_way_en),
    .io_out_bits_addr    (data_write_arb_dup2_out_bits_addr)
  );

  Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_3 (
    .io_in_0_valid       (mp_data_write_dup_3_valid),
    .io_in_0_bits_way_en (mp_data_write_dup_3_bits_way_en),
    .io_in_0_bits_addr   (mp_data_write_dup_3_bits_addr),
    .io_out_valid        (data_write_arb_dup3_out_valid),
    .io_out_bits_way_en  (data_write_arb_dup3_out_bits_way_en),
    .io_out_bits_addr    (data_write_arb_dup3_out_bits_addr)
  );

  Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_4 (
    .io_in_0_valid       (mp_data_write_dup_4_valid),
    .io_in_0_bits_way_en (mp_data_write_dup_4_bits_way_en),
    .io_in_0_bits_addr   (mp_data_write_dup_4_bits_addr),
    .io_out_valid        (data_write_arb_dup4_out_valid),
    .io_out_bits_way_en  (data_write_arb_dup4_out_bits_way_en),
    .io_out_bits_addr    (data_write_arb_dup4_out_bits_addr)
  );

  Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_5 (
    .io_in_0_valid       (mp_data_write_dup_5_valid),
    .io_in_0_bits_way_en (mp_data_write_dup_5_bits_way_en),
    .io_in_0_bits_addr   (mp_data_write_dup_5_bits_addr),
    .io_out_valid        (data_write_arb_dup5_out_valid),
    .io_out_bits_way_en  (data_write_arb_dup5_out_bits_way_en),
    .io_out_bits_addr    (data_write_arb_dup5_out_bits_addr)
  );

  Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_6 (
    .io_in_0_valid       (mp_data_write_dup_6_valid),
    .io_in_0_bits_way_en (mp_data_write_dup_6_bits_way_en),
    .io_in_0_bits_addr   (mp_data_write_dup_6_bits_addr),
    .io_out_valid        (data_write_arb_dup6_out_valid),
    .io_out_bits_way_en  (data_write_arb_dup6_out_bits_way_en),
    .io_out_bits_addr    (data_write_arb_dup6_out_bits_addr)
  );

  Arbiter1_L1BankedDataWriteReqCtrl dataWriteArb_dup_7 (
    .io_in_0_valid       (mp_data_write_dup_7_valid),
    .io_in_0_bits_way_en (mp_data_write_dup_7_bits_way_en),
    .io_in_0_bits_addr   (mp_data_write_dup_7_bits_addr),
    .io_out_valid        (data_write_arb_dup7_out_valid),
    .io_out_bits_way_en  (data_write_arb_dup7_out_bits_way_en),
    .io_out_bits_addr    (data_write_arb_dup7_out_bits_addr)
  );

  TreeArbiter missReqArb (
    .io_in_0_ready               (miss_req_arb_in_0_ready),
    .io_in_0_valid               (mp_miss_req_valid),
    .io_in_0_bits_source         (mp_miss_req_bits_source),
    .io_in_0_bits_cmd            (mp_miss_req_bits_cmd),
    .io_in_0_bits_addr           (mp_miss_req_bits_addr),
    .io_in_0_bits_vaddr          (mp_miss_req_bits_vaddr),
    .io_in_0_bits_full_overwrite (mp_miss_req_bits_full_overwrite),
    .io_in_0_bits_word_idx       (mp_miss_req_bits_word_idx),
    .io_in_0_bits_amo_data       (mp_miss_req_bits_amo_data),
    .io_in_0_bits_amo_mask       (mp_miss_req_bits_amo_mask),
    .io_in_0_bits_amo_cmp        (mp_miss_req_bits_amo_cmp),
    .io_in_0_bits_req_coh_state  (mp_miss_req_bits_req_coh_state),
    .io_in_0_bits_id             (mp_miss_req_bits_id),
    .io_in_0_bits_isBtoT         (mp_miss_req_bits_isBtoT),
    .io_in_0_bits_occupy_way     (mp_miss_req_bits_occupy_way),
    .io_in_0_bits_cancel         (mp_miss_req_bits_cancel),
    .io_in_0_bits_store_data     (mp_miss_req_bits_store_data),
    .io_in_0_bits_store_mask     (mp_miss_req_bits_store_mask),
    .io_in_1_ready               (miss_req_arb_in_1_ready),
    .io_in_1_valid               (ldu0_miss_req_valid),
    .io_in_1_bits_source         (ldu0_miss_req_bits_source),
    .io_in_1_bits_pf_source      (ldu0_miss_req_bits_pf_source),
    .io_in_1_bits_cmd            (ldu0_miss_req_bits_cmd),
    .io_in_1_bits_addr           (ldu0_miss_req_bits_addr),
    .io_in_1_bits_vaddr          (ldu0_miss_req_bits_vaddr),
    .io_in_1_bits_req_coh_state  (ldu0_miss_req_bits_req_coh_state),
    .io_in_1_bits_isBtoT         (ldu0_miss_req_bits_isBtoT),
    .io_in_1_bits_occupy_way     (ldu0_miss_req_bits_occupy_way),
    .io_in_1_bits_cancel         (ldu0_miss_req_bits_cancel),
    .io_in_2_ready               (miss_req_arb_in_2_ready),
    .io_in_2_valid               (ldu1_miss_req_valid),
    .io_in_2_bits_source         (ldu1_miss_req_bits_source),
    .io_in_2_bits_pf_source      (ldu1_miss_req_bits_pf_source),
    .io_in_2_bits_cmd            (ldu1_miss_req_bits_cmd),
    .io_in_2_bits_addr           (ldu1_miss_req_bits_addr),
    .io_in_2_bits_vaddr          (ldu1_miss_req_bits_vaddr),
    .io_in_2_bits_req_coh_state  (ldu1_miss_req_bits_req_coh_state),
    .io_in_2_bits_isBtoT         (ldu1_miss_req_bits_isBtoT),
    .io_in_2_bits_occupy_way     (ldu1_miss_req_bits_occupy_way),
    .io_in_2_bits_cancel         (ldu1_miss_req_bits_cancel),
    .io_in_3_ready               (miss_req_arb_in_3_ready),
    .io_in_3_valid               (ldu2_miss_req_valid),
    .io_in_3_bits_source         (ldu2_miss_req_bits_source),
    .io_in_3_bits_pf_source      (ldu2_miss_req_bits_pf_source),
    .io_in_3_bits_cmd            (ldu2_miss_req_bits_cmd),
    .io_in_3_bits_addr           (ldu2_miss_req_bits_addr),
    .io_in_3_bits_vaddr          (ldu2_miss_req_bits_vaddr),
    .io_in_3_bits_req_coh_state  (ldu2_miss_req_bits_req_coh_state),
    .io_in_3_bits_isBtoT         (ldu2_miss_req_bits_isBtoT),
    .io_in_3_bits_occupy_way     (ldu2_miss_req_bits_occupy_way),
    .io_in_3_bits_cancel         (ldu2_miss_req_bits_cancel),
    .io_out_ready                (mq_req_ready),
    .io_out_valid                (miss_req_arb_out_valid),
    .io_out_bits_source          (miss_req_arb_out_bits_source),
    .io_out_bits_pf_source       (miss_req_arb_out_bits_pf_source),
    .io_out_bits_cmd             (miss_req_arb_out_bits_cmd),
    .io_out_bits_addr            (miss_req_arb_out_bits_addr),
    .io_out_bits_vaddr           (miss_req_arb_out_bits_vaddr),
    .io_out_bits_full_overwrite  (miss_req_arb_out_bits_full_overwrite),
    .io_out_bits_word_idx        (miss_req_arb_out_bits_word_idx),
    .io_out_bits_amo_data        (miss_req_arb_out_bits_amo_data),
    .io_out_bits_amo_mask        (miss_req_arb_out_bits_amo_mask),
    .io_out_bits_amo_cmp         (miss_req_arb_out_bits_amo_cmp),
    .io_out_bits_req_coh_state   (miss_req_arb_out_bits_req_coh_state),
    .io_out_bits_id              (miss_req_arb_out_bits_id),
    .io_out_bits_isBtoT          (miss_req_arb_out_bits_isBtoT),
    .io_out_bits_occupy_way      (miss_req_arb_out_bits_occupy_way),
    .io_out_bits_cancel          (miss_req_arb_out_bits_cancel),
    .io_out_bits_store_data      (miss_req_arb_out_bits_store_data),
    .io_out_bits_store_mask      (miss_req_arb_out_bits_store_mask)
  );

  MissReadyGen missReadyGen (
    .io_in_0_ready                (miss_ready_gen_in_0_ready),
    .io_in_0_valid                (mp_miss_req_valid),
    .io_in_0_bits_source          (mp_miss_req_bits_source),
    .io_in_0_bits_addr            (mp_miss_req_bits_addr),
    .io_in_0_bits_vaddr           (mp_miss_req_bits_vaddr),
    .io_in_1_ready                (miss_ready_gen_in_1_ready),
    .io_in_1_valid                (ldu0_miss_req_valid),
    .io_in_1_bits_source          (ldu0_miss_req_bits_source),
    .io_in_1_bits_addr            (ldu0_miss_req_bits_addr),
    .io_in_1_bits_vaddr           (ldu0_miss_req_bits_vaddr),
    .io_in_2_ready                (miss_ready_gen_in_2_ready),
    .io_in_2_valid                (ldu1_miss_req_valid),
    .io_in_2_bits_source          (ldu1_miss_req_bits_source),
    .io_in_2_bits_addr            (ldu1_miss_req_bits_addr),
    .io_in_2_bits_vaddr           (ldu1_miss_req_bits_vaddr),
    .io_in_3_ready                (miss_ready_gen_in_3_ready),
    .io_in_3_bits_source          (ldu2_miss_req_bits_source),
    .io_in_3_bits_addr            (ldu2_miss_req_bits_addr),
    .io_in_3_bits_vaddr           (ldu2_miss_req_bits_vaddr),
    .io_queryMQ_0_req_bits_source (miss_ready_gen_queryMQ_0_req_bits_source),
    .io_queryMQ_0_req_bits_addr   (miss_ready_gen_queryMQ_0_req_bits_addr),
    .io_queryMQ_0_req_bits_vaddr  (miss_ready_gen_queryMQ_0_req_bits_vaddr),
    .io_queryMQ_0_ready           (mq_queryMQ_0_ready),
    .io_queryMQ_1_req_bits_source (miss_ready_gen_queryMQ_1_req_bits_source),
    .io_queryMQ_1_req_bits_addr   (miss_ready_gen_queryMQ_1_req_bits_addr),
    .io_queryMQ_1_req_bits_vaddr  (miss_ready_gen_queryMQ_1_req_bits_vaddr),
    .io_queryMQ_1_ready           (mq_queryMQ_1_ready),
    .io_queryMQ_2_req_bits_source (miss_ready_gen_queryMQ_2_req_bits_source),
    .io_queryMQ_2_req_bits_addr   (miss_ready_gen_queryMQ_2_req_bits_addr),
    .io_queryMQ_2_req_bits_vaddr  (miss_ready_gen_queryMQ_2_req_bits_vaddr),
    .io_queryMQ_2_ready           (mq_queryMQ_2_ready),
    .io_queryMQ_3_req_bits_source (miss_ready_gen_queryMQ_3_req_bits_source),
    .io_queryMQ_3_req_bits_addr   (miss_ready_gen_queryMQ_3_req_bits_addr),
    .io_queryMQ_3_req_bits_vaddr  (miss_ready_gen_queryMQ_3_req_bits_vaddr),
    .io_queryMQ_3_ready           (mq_queryMQ_3_ready)
  );

  // ---- 本层输出 ----
  assign auto_client_out_a_valid = mq_mem_acquire_valid;
  assign auto_client_out_a_bits_address = mq_mem_acquire_bits_address;
  assign auto_client_out_b_ready = core_b_ready;
  assign auto_client_out_c_valid = wbq_mem_release_valid;
  assign auto_client_out_c_bits_address = wbq_mem_release_bits_address;
  assign auto_client_out_d_ready = core_d_ready;
  assign io_lsu_load_0_req_ready = ldu0_lsu_req_ready;
  assign io_lsu_load_1_req_ready = ldu1_lsu_req_ready;
  assign io_lsu_load_2_req_ready = ldu2_lsu_req_ready;
  assign io_lsu_tl_d_channel_valid = core_tl_d_channel_valid;
  assign io_lsu_tl_d_channel_mshrid = core_tl_d_channel_mshrid;
  assign io_lsu_store_replay_resp_valid = core_lsu_store_replay_valid;
  assign io_lsu_store_replay_resp_bits_id = core_lsu_store_replay_id;
  assign io_lsu_atomics_resp_valid = core_lsu_atomic_valid;
  assign io_lsu_atomics_resp_bits_data = core_lsu_atomic_data;
  assign io_lsu_atomics_resp_bits_miss = core_lsu_atomic_miss;
  assign io_lsu_atomics_resp_bits_replay = core_lsu_atomic_replay;
  assign io_lsu_atomics_resp_bits_tl_error_tl_denied = core_lsu_atomic_denied;
  assign io_lsu_atomics_resp_bits_tl_error_tl_corrupt = core_lsu_atomic_corrupt;
  assign io_lsu_atomics_resp_bits_id = core_lsu_atomic_id;
  assign io_lsu_release_valid = core_lsu_release_valid;
  assign io_lsu_release_bits_paddr = core_lsu_release_paddr;
  assign io_lsu_forward_D_0_valid = core_fwd_d_valid[0];
  assign io_lsu_forward_D_0_data = core_fwd_d_data[0];
  assign io_lsu_forward_D_0_mshrid = core_fwd_d_mshrid[0];
  assign io_lsu_forward_D_0_last = core_fwd_d_last[0];
  assign io_lsu_forward_D_0_denied = core_fwd_d_denied[0];
  assign io_lsu_forward_D_0_corrupt = core_fwd_d_corrupt[0];
  assign io_lsu_forward_D_1_valid = core_fwd_d_valid[1];
  assign io_lsu_forward_D_1_data = core_fwd_d_data[1];
  assign io_lsu_forward_D_1_mshrid = core_fwd_d_mshrid[1];
  assign io_lsu_forward_D_1_last = core_fwd_d_last[1];
  assign io_lsu_forward_D_1_denied = core_fwd_d_denied[1];
  assign io_lsu_forward_D_1_corrupt = core_fwd_d_corrupt[1];
  assign io_lsu_forward_D_2_valid = core_fwd_d_valid[2];
  assign io_lsu_forward_D_2_data = core_fwd_d_data[2];
  assign io_lsu_forward_D_2_mshrid = core_fwd_d_mshrid[2];
  assign io_lsu_forward_D_2_last = core_fwd_d_last[2];
  assign io_lsu_forward_D_2_denied = core_fwd_d_denied[2];
  assign io_lsu_forward_D_2_corrupt = core_fwd_d_corrupt[2];
  assign io_error_valid = core_error_valid;
  assign io_error_bits_paddr = core_error_paddr;
  assign io_error_bits_report_to_beu = core_error_report_to_beu;
  assign io_perf_0_value = core_perf_out[0];
  assign io_perf_1_value = core_perf_out[1];
  assign io_perf_2_value = core_perf_out[2];
  assign io_perf_3_value = core_perf_out[3];
  assign io_perf_4_value = core_perf_out[4];
  assign io_perf_5_value = core_perf_out[5];
  assign io_perf_6_value = core_perf_out[6];
  assign io_perf_7_value = core_perf_out[7];
  assign io_perf_8_value = core_perf_out[8];
  assign io_perf_9_value = core_perf_out[9];
  assign io_perf_10_value = core_perf_out[10];
  assign io_perf_11_value = core_perf_out[11];
  assign io_perf_12_value = core_perf_out[12];
  assign io_perf_13_value = core_perf_out[13];
  assign io_perf_14_value = core_perf_out[14];
  assign io_perf_15_value = core_perf_out[15];
  assign io_perf_16_value = core_perf_out[16];
  assign io_perf_17_value = core_perf_out[17];
  assign io_perf_18_value = core_perf_out[18];
  assign io_perf_19_value = core_perf_out[19];
  assign io_perf_20_value = core_perf_out[20];
  assign io_perf_21_value = core_perf_out[21];
  assign io_perf_22_value = core_perf_out[22];
  assign io_perf_23_value = core_perf_out[23];
  assign io_perf_24_value = core_perf_out[24];
  assign io_perf_25_value = core_perf_out[25];
  assign io_perf_26_value = core_perf_out[26];
  assign io_perf_27_value = core_perf_out[27];
  assign io_perf_28_value = core_perf_out[28];
  assign io_perf_29_value = core_perf_out[29];
  assign io_perf_30_value = core_perf_out[30];
  assign io_perf_31_value = core_perf_out[31];
  assign io_perf_32_value = core_perf_out[32];
  assign io_perf_33_value = core_perf_out[33];
  assign io_perf_34_value = core_perf_out[34];
  assign io_perf_35_value = core_perf_out[35];
  assign io_perf_36_value = core_perf_out[36];
  assign io_perf_37_value = core_perf_out[37];
  assign io_perf_38_value = core_perf_out[38];
  assign io_perf_39_value = core_perf_out[39];
  // END GENERATED

endmodule
