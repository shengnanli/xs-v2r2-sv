// =============================================================================
//  Sbuffer —— store 写合并缓冲（可读重写核 xs_Sbuffer_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/mem/sbuffer/Sbuffer.scala
//  类型/常量/纯函数集中在 sbuffer_pkg（见 sbuffer_pkg.sv 文件头的整体说明）。
//
//  本核维护 SB_SIZE(=16) 个 cacheline 缓冲 entry：
//    · meta[i]      = {ptag, vtag}（cacheline 物理/虚拟 tag）
//    · stateVec[i]  = {valid, inflight, w_timeout, w_sameblock_inflight}（小状态机）
//    · cline_data[i]/cline_mask[i] = 该行 4×16B 数据与逐字节掩码（write coalescing 目标）
//    · cohCount[i]  = 攒数据超时计数；missqReplayCount[i] = replay 重发延时计数
//  四个并发处理面（对应 Scala 分节）：
//    (1) Enq   (in_s0/s1/s2)  收 2 路 store：merge 到同 ptag 老 entry，或 alloc 新 entry
//    (2) Deq   (out_s0/s1)    选 evictionIdx 置 inflight，组 DCache 整行写请求
//    (3) Resp                 收 DCache hit_resp 释放 entry / replay_resp 挂超时重发
//    (4) Forward (f0/f1)      load 用 vaddr CAM 前递在途 store 的最新字节
//  外加全局 4 态状态机 sbuffer_state 控制逐出优先级与是否收新 store。
//
//  ⚠ 端口集合/命名与 golden Sbuffer 完全一致（扁平 io_*）。本配置 golden 已裁剪
//    difftest / csrCtrl / hartId / store_prefetch 握手 / memSetPattenDetected，threshold
//    /base 固化为 7/4。store_prefetch 由黑盒 StorePfWrapper（wrapper 层例化）直驱。
//    可读性体现在「内部」用 struct/enum/function/generate 表达微架构。
// =============================================================================
module xs_Sbuffer_core
  import sbuffer_pkg::*;
(
  input          clock,
  input          reset,
  // ---- 入口：EnsbufferWidth=2 路已提交 store ----
  output         io_in_0_ready,
  input          io_in_0_valid,
  input  [49:0]  io_in_0_bits_vaddr,
  input  [127:0] io_in_0_bits_data,
  input  [15:0]  io_in_0_bits_mask,
  input  [47:0]  io_in_0_bits_addr,
  input          io_in_0_bits_wline,
  input          io_in_0_bits_vecValid,
  output         io_in_1_ready,
  input          io_in_1_valid,
  input  [49:0]  io_in_1_bits_vaddr,
  input  [127:0] io_in_1_bits_data,
  input  [15:0]  io_in_1_bits_mask,
  input  [47:0]  io_in_1_bits_addr,
  input          io_in_1_bits_wline,
  input          io_in_1_bits_vecValid,
  // ---- DCache 写口（整行 512b 数据 + 64B 掩码）----
  input          io_dcache_req_ready,
  output         io_dcache_req_valid,
  output [49:0]  io_dcache_req_bits_vaddr,
  output [47:0]  io_dcache_req_bits_addr,
  output [511:0] io_dcache_req_bits_data,
  output [63:0]  io_dcache_req_bits_mask,
  output [5:0]   io_dcache_req_bits_id,
  // ---- DCache 回应：hit（释放）/ replay（挂超时重发）----
  input          io_dcache_main_pipe_hit_resp_valid,
  input  [5:0]   io_dcache_main_pipe_hit_resp_bits_id,
  input          io_dcache_replay_resp_valid,
  input  [5:0]   io_dcache_replay_resp_bits_id,
  // ---- load forward（3 路）----
  input  [49:0]  io_forward_0_vaddr,
  input  [47:0]  io_forward_0_paddr,
  input          io_forward_0_valid,
  output         io_forward_0_forwardMask_0,
  output         io_forward_0_forwardMask_1,
  output         io_forward_0_forwardMask_2,
  output         io_forward_0_forwardMask_3,
  output         io_forward_0_forwardMask_4,
  output         io_forward_0_forwardMask_5,
  output         io_forward_0_forwardMask_6,
  output         io_forward_0_forwardMask_7,
  output         io_forward_0_forwardMask_8,
  output         io_forward_0_forwardMask_9,
  output         io_forward_0_forwardMask_10,
  output         io_forward_0_forwardMask_11,
  output         io_forward_0_forwardMask_12,
  output         io_forward_0_forwardMask_13,
  output         io_forward_0_forwardMask_14,
  output         io_forward_0_forwardMask_15,
  output [7:0]   io_forward_0_forwardData_0,
  output [7:0]   io_forward_0_forwardData_1,
  output [7:0]   io_forward_0_forwardData_2,
  output [7:0]   io_forward_0_forwardData_3,
  output [7:0]   io_forward_0_forwardData_4,
  output [7:0]   io_forward_0_forwardData_5,
  output [7:0]   io_forward_0_forwardData_6,
  output [7:0]   io_forward_0_forwardData_7,
  output [7:0]   io_forward_0_forwardData_8,
  output [7:0]   io_forward_0_forwardData_9,
  output [7:0]   io_forward_0_forwardData_10,
  output [7:0]   io_forward_0_forwardData_11,
  output [7:0]   io_forward_0_forwardData_12,
  output [7:0]   io_forward_0_forwardData_13,
  output [7:0]   io_forward_0_forwardData_14,
  output [7:0]   io_forward_0_forwardData_15,
  output         io_forward_0_matchInvalid,
  input  [49:0]  io_forward_1_vaddr,
  input  [47:0]  io_forward_1_paddr,
  input          io_forward_1_valid,
  output         io_forward_1_forwardMask_0,
  output         io_forward_1_forwardMask_1,
  output         io_forward_1_forwardMask_2,
  output         io_forward_1_forwardMask_3,
  output         io_forward_1_forwardMask_4,
  output         io_forward_1_forwardMask_5,
  output         io_forward_1_forwardMask_6,
  output         io_forward_1_forwardMask_7,
  output         io_forward_1_forwardMask_8,
  output         io_forward_1_forwardMask_9,
  output         io_forward_1_forwardMask_10,
  output         io_forward_1_forwardMask_11,
  output         io_forward_1_forwardMask_12,
  output         io_forward_1_forwardMask_13,
  output         io_forward_1_forwardMask_14,
  output         io_forward_1_forwardMask_15,
  output [7:0]   io_forward_1_forwardData_0,
  output [7:0]   io_forward_1_forwardData_1,
  output [7:0]   io_forward_1_forwardData_2,
  output [7:0]   io_forward_1_forwardData_3,
  output [7:0]   io_forward_1_forwardData_4,
  output [7:0]   io_forward_1_forwardData_5,
  output [7:0]   io_forward_1_forwardData_6,
  output [7:0]   io_forward_1_forwardData_7,
  output [7:0]   io_forward_1_forwardData_8,
  output [7:0]   io_forward_1_forwardData_9,
  output [7:0]   io_forward_1_forwardData_10,
  output [7:0]   io_forward_1_forwardData_11,
  output [7:0]   io_forward_1_forwardData_12,
  output [7:0]   io_forward_1_forwardData_13,
  output [7:0]   io_forward_1_forwardData_14,
  output [7:0]   io_forward_1_forwardData_15,
  output         io_forward_1_matchInvalid,
  input  [49:0]  io_forward_2_vaddr,
  input  [47:0]  io_forward_2_paddr,
  input          io_forward_2_valid,
  output         io_forward_2_forwardMask_0,
  output         io_forward_2_forwardMask_1,
  output         io_forward_2_forwardMask_2,
  output         io_forward_2_forwardMask_3,
  output         io_forward_2_forwardMask_4,
  output         io_forward_2_forwardMask_5,
  output         io_forward_2_forwardMask_6,
  output         io_forward_2_forwardMask_7,
  output         io_forward_2_forwardMask_8,
  output         io_forward_2_forwardMask_9,
  output         io_forward_2_forwardMask_10,
  output         io_forward_2_forwardMask_11,
  output         io_forward_2_forwardMask_12,
  output         io_forward_2_forwardMask_13,
  output         io_forward_2_forwardMask_14,
  output         io_forward_2_forwardMask_15,
  output [7:0]   io_forward_2_forwardData_0,
  output [7:0]   io_forward_2_forwardData_1,
  output [7:0]   io_forward_2_forwardData_2,
  output [7:0]   io_forward_2_forwardData_3,
  output [7:0]   io_forward_2_forwardData_4,
  output [7:0]   io_forward_2_forwardData_5,
  output [7:0]   io_forward_2_forwardData_6,
  output [7:0]   io_forward_2_forwardData_7,
  output [7:0]   io_forward_2_forwardData_8,
  output [7:0]   io_forward_2_forwardData_9,
  output [7:0]   io_forward_2_forwardData_10,
  output [7:0]   io_forward_2_forwardData_11,
  output [7:0]   io_forward_2_forwardData_12,
  output [7:0]   io_forward_2_forwardData_13,
  output [7:0]   io_forward_2_forwardData_14,
  output [7:0]   io_forward_2_forwardData_15,
  output         io_forward_2_matchInvalid,
  // ---- 空标志 / flush ----
  input          io_sqempty,
  output         io_sbempty,
  input          io_flush_valid,
  output         io_flush_empty,
  // ---- store 预取请求（本配置仅黑盒 prefetcher 直驱 vaddr，无握手）----
  output [49:0]  io_store_prefetch_0_bits_vaddr,
  output [49:0]  io_store_prefetch_1_bits_vaddr,
  // ---- 逐出阈值放宽 ----
  input          io_force_write,
  // ---- perf 事件计数（16 路，2 拍延迟）----
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
  output [5:0]   io_perf_15_value
);

  // store_prefetch：本配置 prefetcher 是黑盒，vaddr 由 wrapper 例化的 StorePfWrapper
  // 直接驱动这两个端口；核内不产生（接 0，wrapper 不连这两个端口到核）。
  assign io_store_prefetch_0_bits_vaddr = '0;
  assign io_store_prefetch_1_bits_vaddr = '0;

  // ===========================================================================
  //  入口端口聚合成数组（用 for/genvar 统一处理 2 路 store）
  // ===========================================================================
  sbuf_inreq_t in_req [ENSB_W];
  logic        in_valid [ENSB_W];
  always_comb begin
    in_req[0] = '{ vaddr:io_in_0_bits_vaddr, data:io_in_0_bits_data, mask:io_in_0_bits_mask,
                   addr:io_in_0_bits_addr, wline:io_in_0_bits_wline, vecValid:io_in_0_bits_vecValid };
    in_req[1] = '{ vaddr:io_in_1_bits_vaddr, data:io_in_1_bits_data, mask:io_in_1_bits_mask,
                   addr:io_in_1_bits_addr, wline:io_in_1_bits_wline, vecValid:io_in_1_bits_vecValid };
    in_valid[0] = io_in_0_valid;
    in_valid[1] = io_in_1_valid;
  end

  // ===========================================================================
  //  entry 存储：meta / state / cohCount / replayCount，data/mask 单列
  // ===========================================================================
  // golden 顶层是独立的 vtag_<l>/ptag_<l> 寄存器（无 struct）；命名对齐使 FM 自动配对
  logic [PTAG_W-1:0] ptag [SB_SIZE];
  logic [VTAG_W-1:0] vtag [SB_SIZE];
  sbuf_state_t stateVec [SB_SIZE];
  logic [SB_SIZE-1:0]        waitInflightMask [SB_SIZE]; // 该 entry 等待哪个在途 entry 写完
  logic [EVICT_CNT_W-1:0]    cohCount         [SB_SIZE];
  logic [REPLAY_CNT_W-1:0]   missqReplayCount [SB_SIZE];

  // cacheline 数据/掩码：每行 CLINE_VWORDS(=4) 个 16B word
  logic [VDATA_BYTES-1:0][7:0] cline_data [SB_SIZE][CLINE_VWORDS];
  logic [VDATA_BYTES-1:0]      cline_mask [SB_SIZE][CLINE_VWORDS];

  // 状态向量（组合派生）
  logic [SB_SIZE-1:0] activeMask, validMask, invalidMask, inflightMask;
  always_comb
    for (int i = 0; i < SB_SIZE; i++) begin
      activeMask[i]   = st_is_active  (stateVec[i]);
      validMask[i]    = st_is_valid   (stateVec[i]);
      invalidMask[i]  = st_is_invalid (stateVec[i]);
      inflightMask[i] = st_is_inflight(stateVec[i]);
    end

  // 前向声明（跨节使用）
  logic                 sbuffer_out_s0_fire;
  logic [SB_IDX_W-1:0]  sbuffer_out_s0_evictionIdx;
  logic [SB_SIZE-1:0]   writeReq_wvec [ENSB_W];
  logic                 writeReq_valid [ENSB_W];

  // ===========================================================================
  //  全局 4 态状态机 sbuffer_state
  // ===========================================================================
  sbuf_gstate_e sbuffer_state;
  wire need_drain = sbuffer_state[1];          // needDrain = state(1)

  // ===========================================================================
  //  PLRU（ValidPseudoLRU(16)）：在「DCache 写候选」里选最旧的有效 way
  // ---------------------------------------------------------------------------
  //   plru_state 是 15 位树状态（n_ways-1）。candidateVec = isDcacheReqCandidate。
  //   Scala 用 plru.way(candidateVec.reverse)：valids 序 MSB=way0 反序传入。这里把
  //   16 个 candidate 反序后喂给标准 ValidPseudoLRU way() 递归（4 层平衡树）。
  // ===========================================================================
  logic [14:0]        plru_state;
  logic [SB_SIZE-1:0] candidateVec;
  always_comb
    for (int i = 0; i < SB_SIZE; i++) candidateVec[i] = st_is_dcache_cand(stateVec[i]);

  // ---- ValidPseudoLRU.way()：返回 (valid, idx)。平衡 16-way 树展开为 4 层 ----
  //   树状态位布局（PseudoLRU 注释）：top=state[14]，left子树=state[13:7]，right子树=state[6:0]；
  //   依此每层递归。下面用 4 个 helper 函数逐层归约（leaf→pair→quad→oct→root）。
  //   pair：两个相邻 leaf 选一（state 单 bit）。返回 {valid, idx[0]}。
  function automatic logic [1:0] plru_pair(input logic c_hi, input logic c_lo, input logic s);
    // c_hi=高 way，c_lo=低 way；左旧?选左:选右（way() 用 state(0) 作 idx lsb）
    logic v; logic idx;
    v   = c_hi | c_lo;
    idx = (c_hi & c_lo) ? s : (c_hi ? 1'b1 : 1'b0); // 都有效→看 state；否则选有效的那个
    return {v, idx};
  endfunction
  // quad：两个 pair 结果（各 1 位 idx）+ 1 个 state bit → {valid, top, sub} = {valid, idx[1:0]}
  function automatic logic [2:0] plru_join(input logic lv, input logic lidx,
                                           input logic rv, input logic ridx,
                                           input logic s);
    // 左旧?递归左:递归右，top bit = left_older(=s 当两侧都有效)
    logic v; logic top; logic sub;
    v = lv | rv;
    if (lv & rv) begin top = s;    sub = s ? lidx : ridx; end
    else         begin top = lv;   sub = lv ? lidx : ridx; end
    return {v, top, sub};
  endfunction

  // ── 树叶布局（与 Rocket PseudoLRU 注释 + golden 一致）──────────────────────
  //   最左叶 = way15，最右叶 = way0；每个分支节点 state bit「left_older」当两子都有效
  //   时作为选择位，否则选有效的那侧（左→msb=1，右→msb=0）。输出即实际 way 下标。
  //   state bit 与节点对应（4 层平衡树，自底向上）：
  //     pair（叶对）：way15/14→s[11]  13/12→s[10] 11/10→s[8]  9/8→s[7]
  //                   7/6→s[4]   5/4→s[3]   3/2→s[1]   1/0→s[0]
  //     quad：s[12] s[9] s[5] s[2]   oct：s[13] s[6]   root：s[14]
  //   pair 输出 1 位 idx；quad 2 位；oct 3 位；root 4 位。idx 内 msb=「左子（高 way）」。
  logic       p_v [8]; logic p_i [8];
  always_comb begin
    {p_v[0],p_i[0]} = plru_pair(candidateVec[15], candidateVec[14], plru_state[11]);
    {p_v[1],p_i[1]} = plru_pair(candidateVec[13], candidateVec[12], plru_state[10]);
    {p_v[2],p_i[2]} = plru_pair(candidateVec[11], candidateVec[10], plru_state[8]);
    {p_v[3],p_i[3]} = plru_pair(candidateVec[9],  candidateVec[8],  plru_state[7]);
    {p_v[4],p_i[4]} = plru_pair(candidateVec[7],  candidateVec[6],  plru_state[4]);
    {p_v[5],p_i[5]} = plru_pair(candidateVec[5],  candidateVec[4],  plru_state[3]);
    {p_v[6],p_i[6]} = plru_pair(candidateVec[3],  candidateVec[2],  plru_state[1]);
    {p_v[7],p_i[7]} = plru_pair(candidateVec[1],  candidateVec[0],  plru_state[0]);
  end
  // quad：合并相邻两 pair（左子=高 way 半区），idx = {top, sub}
  logic       q_v [4]; logic [1:0] q_i [4];
  always_comb begin
    {q_v[0], q_i[0]} = plru_join(p_v[0],p_i[0], p_v[1],p_i[1], plru_state[12]);
    {q_v[1], q_i[1]} = plru_join(p_v[2],p_i[2], p_v[3],p_i[3], plru_state[9]);
    {q_v[2], q_i[2]} = plru_join(p_v[4],p_i[4], p_v[5],p_i[5], plru_state[5]);
    {q_v[3], q_i[3]} = plru_join(p_v[6],p_i[6], p_v[7],p_i[7], plru_state[2]);
  end
  // oct：合并相邻两 quad
  logic       o_v [2]; logic [2:0] o_i [2];
  always_comb begin
    o_v[0] = q_v[0] | q_v[1];
    o_i[0] = (q_v[0]&q_v[1]) ? {plru_state[13], plru_state[13]?q_i[0]:q_i[1]}
           : q_v[0] ? {1'b1,q_i[0]} : {1'b0,q_i[1]};
    o_v[1] = q_v[2] | q_v[3];
    o_i[1] = (q_v[2]&q_v[3]) ? {plru_state[6], plru_state[6]?q_i[2]:q_i[3]}
           : q_v[2] ? {1'b1,q_i[2]} : {1'b0,q_i[3]};
  end
  // root：合并两 oct，得到实际 way 下标（左 oct=way15..8 给 msb=1）
  logic       way_valid; logic [3:0] way_idx;
  always_comb begin
    way_valid = o_v[0] | o_v[1];
    way_idx = (o_v[0]&o_v[1]) ? {plru_state[14], plru_state[14]?o_i[0]:o_i[1]}
            : o_v[0] ? {1'b1,o_i[0]} : {1'b0,o_i[1]};
  end
  wire [SB_IDX_W-1:0] replaceAlgoIdx = way_idx;
  wire [SB_IDX_W-1:0] replaceIdx     = replaceAlgoIdx;

  // ===========================================================================
  //  cohCount 超时逐出 / missqReplay 重发超时
  // ===========================================================================
  logic [SB_SIZE-1:0] cohTimeOutMask;
  always_comb
    for (int i = 0; i < SB_SIZE; i++)
      cohTimeOutMask[i] = cohCount[i][EVICT_CNT_W-1] & st_is_active(stateVec[i]);
  wire [SB_IDX_W-1:0] cohTimeOutIdx = prio_enc16_deflast(cohTimeOutMask);  // golden 默认末项 15
  wire                cohHasTimeOut = |cohTimeOutMask;

  logic [SB_SIZE-1:0] missqReplayTimeOutMask;
  always_comb
    for (int i = 0; i < SB_SIZE; i++)
      missqReplayTimeOutMask[i] = missqReplayCount[i][REPLAY_CNT_W-1] & stateVec[i].w_timeout;
  wire [SB_IDX_W-1:0] missqReplayTimeOutIdxGen = prio_enc16(missqReplayTimeOutMask);
  wire                missqReplayHasTimeOutGen = |missqReplayTimeOutMask;

  // missqReplayHasTimeOut = RegNext(gen) & !RegNext(out_s0_fire)；Idx = RegEnable(gen,gen)
  logic                missqReplayHasTimeOut_q, out_s0_fire_q;
  logic [SB_IDX_W-1:0] missqReplayTimeOutIdx;
  // golden 复位寄存器统一在异步复位块（posedge reset）——对齐
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin missqReplayHasTimeOut_q <= 1'b0; out_s0_fire_q <= 1'b0; end
    else begin
      missqReplayHasTimeOut_q <= missqReplayHasTimeOutGen;
      out_s0_fire_q           <= sbuffer_out_s0_fire;
    end
  end
  always_ff @(posedge clock)
    if (missqReplayHasTimeOutGen) missqReplayTimeOutIdx <= missqReplayTimeOutIdxGen;
  wire missqReplayHasTimeOut = missqReplayHasTimeOut_q & ~out_s0_fire_q;

  // ===========================================================================
  //  Enq — in_s0/s1：merge / insert 判定（单拍组合）
  // ===========================================================================
  logic [PTAG_W-1:0] inptag [ENSB_W];
  logic [VTAG_W-1:0] invtag [ENSB_W];
  always_comb
    for (int i = 0; i < ENSB_W; i++) begin
      inptag[i] = get_ptag(in_req[i].addr);
      invtag[i] = get_vtag(in_req[i].vaddr);
    end
  // 两路同 cacheline（同 ptag 且都 vecValid）：第二路 insert 复用第一路下标
  wire sameTag = (inptag[0] == inptag[1]) & io_in_0_valid & io_in_1_valid
               & in_req[0].vecValid & in_req[1].vecValid;
  // 行内 VWord 偏移（用于 data 写入定位）
  wire [VWORDS_W-1:0] firstWord  = get_vword_off(in_req[0].addr);
  wire [VWORDS_W-1:0] secondWord = get_vword_off(in_req[1].addr);

  // merge 候选：同 ptag 且 active
  logic [SB_SIZE-1:0] mergeMask [ENSB_W];
  logic [SB_IDX_W-1:0] mergeIdx [ENSB_W];
  logic                canMerge [ENSB_W];
  always_comb
    for (int i = 0; i < ENSB_W; i++) begin
      for (int j = 0; j < SB_SIZE; j++)
        mergeMask[i][j] = (inptag[i] == ptag[j]) & activeMask[j];
      mergeIdx[i] = prio_enc16(mergeMask[i]);
      canMerge[i] = |mergeMask[i];
    end

  // insert：在 invalid entry 里按奇/偶分组取「第一个空位」，两路用不同组避免冲突
  logic [7:0] evenInvalidMask, oddInvalidMask;
  logic [7:0] evenRawInsertVec, oddRawInsertVec;
  // 还原回 16 位 one-hot（偶位 / 奇位）
  logic [SB_SIZE-1:0] evenInsertVec, oddInsertVec;
  always_comb begin
    for (int k = 0; k < 8; k++) begin
      evenInvalidMask[k] = invalidMask[2*k];
      oddInvalidMask[k]  = invalidMask[2*k+1];
    end
    evenRawInsertVec = first_one_oh8(evenInvalidMask);
    oddRawInsertVec  = first_one_oh8(oddInvalidMask);
    for (int k = 0; k < 8; k++) begin
      evenInsertVec[2*k]   = evenRawInsertVec[k]; evenInsertVec[2*k+1] = 1'b0;
      oddInsertVec[2*k]    = 1'b0;                oddInsertVec[2*k+1]  = oddRawInsertVec[k];
    end
  end
  wire        evenCanInsert = |evenInvalidMask;
  wire        oddCanInsert  = |oddInvalidMask;

  // enbufferSelReg：每个有效拍翻转，决定第一路用奇/偶组（轮流，均衡占用）
  logic enbufferSelReg;
  always_ff @(posedge clock or posedge reset)
    if (reset) enbufferSelReg <= 1'b0;
    else if (io_in_0_valid) enbufferSelReg <= ~enbufferSelReg;

  logic [SB_SIZE-1:0] firstInsertVec, secondInsertVec;
  logic               firstCanInsert, secondCanInsert;
  wire drain_block = (sbuffer_state != X_DRAIN_SBUFFER);
  always_comb begin
    firstInsertVec  = enbufferSelReg ? evenInsertVec : oddInsertVec;
    secondInsertVec = sameTag ? firstInsertVec
                    : (~enbufferSelReg ? evenInsertVec : oddInsertVec);
    firstCanInsert  = drain_block & (enbufferSelReg ? evenCanInsert : oddCanInsert);
    secondCanInsert = drain_block & (sameTag ? firstCanInsert
                    : (~enbufferSelReg ? evenCanInsert : oddCanInsert));
  end

  // micro-arch drain：forward vtag 失配 / merge vtag 失配 → 抽干 sbuffer（重做）
  logic forward_need_uarch_drain, merge_need_uarch_drain;
  logic fwd_drain_q, merge_drain_q, merge_drain_q2;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin fwd_drain_q<=0; merge_drain_q<=0; merge_drain_q2<=0; end
    else begin
      fwd_drain_q    <= forward_need_uarch_drain;
      merge_drain_q  <= merge_need_uarch_drain;
      merge_drain_q2 <= merge_drain_q;
    end
  end
  wire do_uarch_drain = fwd_drain_q | merge_drain_q2;

  assign io_in_0_ready = firstCanInsert;
  assign io_in_1_ready = secondCanInsert & firstCanInsert;

  // 每路最终落点 insertVec / insertIdx，及是否真正写入
  logic [SB_SIZE-1:0] insertVec [ENSB_W];
  logic [SB_IDX_W-1:0] insertIdx [ENSB_W];
  logic                accessValid [ENSB_W];
  always_comb begin
    insertVec[0] = firstInsertVec;  insertVec[1] = secondInsertVec;
    for (int i = 0; i < ENSB_W; i++) insertIdx[i] = prio_enc16(insertVec[i]);
    accessValid[0] = io_in_0_valid  & io_in_0_bits_vecValid & io_in_0_ready;
    accessValid[1] = io_in_1_valid  & io_in_1_bits_vecValid & io_in_1_ready;
  end

  // 同 block 在途掩码（alloc 时判定是否需挂 w_sameblock_inflight）：
  //   对入口两路 ptag 各算一份「哪些在途 entry 与它同 block」。直接用 always_comb
  //   读模块级 inflightMask/meta（不写成读非局部变量的 function，便于形式化解释）。
  logic [SB_SIZE-1:0] sameBlockInflight [ENSB_W];
  always_comb
    for (int i = 0; i < ENSB_W; i++)
      for (int j = 0; j < SB_SIZE; j++)
        sameBlockInflight[i][j] = inflightMask[j] & (inptag[i] == ptag[j]);

  // writeReq（给 data/mask 写入流水）：merge 用 mergeVec，alloc 用 insertVec
  logic [VLEN-1:0]        writeReq_data [ENSB_W];
  logic [VDATA_BYTES-1:0] writeReq_mask [ENSB_W];
  logic                   writeReq_wline [ENSB_W];
  logic [VWORDS_W-1:0]    writeReq_voff  [ENSB_W];
  always_comb
    for (int i = 0; i < ENSB_W; i++) begin
      writeReq_valid[i] = accessValid[i];
      writeReq_data[i]  = in_req[i].data;
      writeReq_mask[i]  = in_req[i].mask;
      writeReq_wline[i] = in_req[i].wline;
      writeReq_voff[i]  = (i == 0) ? firstWord : secondWord;
      writeReq_wvec[i]  = canMerge[i] ? mergeMask[i] : insertVec[i];
    end

  // accessIdx（喂 PLRU touch）：0/1 路 = RegNext(merge?mergeIdx:insertIdx)
  logic                accessIdx0_valid_q, accessIdx1_valid_q;
  logic [SB_IDX_W-1:0] accessIdx0_idx_q,  accessIdx1_idx_q;
  // golden accessIdx_N_valid_REG 无复位（在纯时钟块），对齐：不带 reset
  always_ff @(posedge clock) begin
    accessIdx0_valid_q <= accessValid[0]; accessIdx1_valid_q <= accessValid[1];
    if (accessValid[0]) accessIdx0_idx_q <= canMerge[0] ? mergeIdx[0] : insertIdx[0];
    if (accessValid[1]) accessIdx1_idx_q <= canMerge[1] ? mergeIdx[1] : insertIdx[1];
  end

  // ===========================================================================
  //  逐出触发 do_eviction / 空标志 / 状态机转移
  // ===========================================================================
  wire sbuffer_empty = &invalidMask;
  wire sq_empty      = ~(io_in_0_valid | io_in_1_valid);
  wire empty         = sbuffer_empty & sq_empty;
  wire [4:0] ActiveCount = popcnt16(activeMask);
  wire [4:0] ValidCount  = popcnt16(validMask);
  // forceThreshold = force_write ? (7-4=3) : 7  = {2'h0, ~force_write, 2'h3}
  wire [4:0] forceThreshold = {2'h0, ~io_force_write, 2'h3};
  logic do_eviction_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) do_eviction_q <= 1'b0;
    else do_eviction_q <= (ActiveCount >= forceThreshold)
                        | (ActiveCount == 5'(SB_SIZE-1))
                        | (ValidCount  == 5'(SB_SIZE));
  end
  wire do_eviction = do_eviction_q;

  // io_sbempty / io_flush_empty 打一拍
  logic sbempty_q, flush_empty_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin sbempty_q<=0; flush_empty_q<=0; end
    else begin sbempty_q <= empty; flush_empty_q <= empty & io_sqempty; end
  end
  assign io_sbempty    = sbempty_q;
  assign io_flush_empty = flush_empty_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) sbuffer_state <= X_IDLE;
    else unique case (sbuffer_state)
      X_IDLE:          if (io_flush_valid)   sbuffer_state <= X_DRAIN_ALL;
                       else if (do_uarch_drain) sbuffer_state <= X_DRAIN_SBUFFER;
                       else if (do_eviction)    sbuffer_state <= X_REPLACE;
      X_DRAIN_ALL:     if (empty)            sbuffer_state <= X_IDLE;
      X_DRAIN_SBUFFER: if (io_flush_valid)   sbuffer_state <= X_DRAIN_ALL;
                       else if (sbuffer_empty) sbuffer_state <= X_IDLE;
      X_REPLACE:       if (io_flush_valid)   sbuffer_state <= X_DRAIN_ALL;
                       else if (do_uarch_drain) sbuffer_state <= X_DRAIN_SBUFFER;
                       else if (~do_eviction)   sbuffer_state <= X_IDLE;
      default: ;
    endcase
  end

  // ===========================================================================
  //  Deq — out_s0：选 evictionIdx，valid 判定
  // ===========================================================================
  wire [SB_IDX_W-1:0] drainIdx = prio_enc16_deflast(activeMask);  // golden 默认末项 15
  wire need_replace = do_eviction | (sbuffer_state == X_REPLACE);
  always_comb begin
    // 优先级：missqReplayTimeOut > drain > cohTimeOut > replace(PLRU)
    if (missqReplayHasTimeOut)       sbuffer_out_s0_evictionIdx = missqReplayTimeOutIdx;
    else if (need_drain)             sbuffer_out_s0_evictionIdx = drainIdx;
    else if (cohHasTimeOut)          sbuffer_out_s0_evictionIdx = cohTimeOutIdx;
    else                             sbuffer_out_s0_evictionIdx = replaceIdx;
  end
  wire sbuffer_out_s0_valid = missqReplayHasTimeOut
    | (st_is_dcache_cand(stateVec[sbuffer_out_s0_evictionIdx])
       & (need_drain | cohHasTimeOut | need_replace));

  // ===========================================================================
  //  Deq — out_s1：DCache 写请求流水寄存器
  // ===========================================================================
  logic                sbuffer_out_s1_valid;
  logic [SB_IDX_W-1:0] sbuffer_out_s1_evictionIdx;
  logic [PTAG_W-1:0]   sbuffer_out_s1_evictionPTag;
  logic [VTAG_W-1:0]   sbuffer_out_s1_evictionVTag;

  // 读/写冒险：被逐出 entry 这拍正被 writeReq 写 → 阻塞 DCache 写一拍
  logic shouldWaitWriteFinish_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) shouldWaitWriteFinish_q <= 1'b0;
    else shouldWaitWriteFinish_q <=
      ((|(writeReq_wvec[1] & (16'h1 << sbuffer_out_s0_evictionIdx))) & writeReq_valid[1]) |
      ((|(writeReq_wvec[0] & (16'h1 << sbuffer_out_s0_evictionIdx))) & writeReq_valid[0]);
  end
  wire blockDcacheWrite = shouldWaitWriteFinish_q;

  wire sbuffer_out_s1_ready = (io_dcache_req_ready & ~blockDcacheWrite) | ~sbuffer_out_s1_valid;
  wire sbuffer_out_s0_cango = sbuffer_out_s1_ready;
  assign sbuffer_out_s0_fire = sbuffer_out_s0_valid & sbuffer_out_s0_cango;
  wire sbuffer_out_s1_fire = io_dcache_req_valid & io_dcache_req_ready;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) sbuffer_out_s1_valid <= 1'b0;
    else begin
      if (sbuffer_out_s1_fire) sbuffer_out_s1_valid <= 1'b0;
      if (sbuffer_out_s0_cango) sbuffer_out_s1_valid <= sbuffer_out_s0_valid;
    end
  end
  always_ff @(posedge clock)
    if (sbuffer_out_s0_fire) begin
      sbuffer_out_s1_evictionIdx  <= sbuffer_out_s0_evictionIdx;
      sbuffer_out_s1_evictionPTag <= ptag[sbuffer_out_s0_evictionIdx];
      sbuffer_out_s1_evictionVTag <= vtag[sbuffer_out_s0_evictionIdx];
    end

  // 整行 data/mask 拼接输出
  logic [CLINE_BITS-1:0] dcache_line_data;
  logic [CLINE_BYTES-1:0] dcache_line_mask;
  always_comb
    for (int w = 0; w < CLINE_VWORDS; w++) begin
      dcache_line_data[w*VLEN +: VLEN]            = cline_data[sbuffer_out_s1_evictionIdx][w];
      dcache_line_mask[w*VDATA_BYTES +: VDATA_BYTES] = cline_mask[sbuffer_out_s1_evictionIdx][w];
    end

  assign io_dcache_req_valid     = sbuffer_out_s1_valid & ~blockDcacheWrite;
  assign io_dcache_req_bits_addr  = addr_from_ptag(sbuffer_out_s1_evictionPTag);
  assign io_dcache_req_bits_vaddr = {sbuffer_out_s1_evictionVTag, {OFFSET_W{1'b0}}};
  assign io_dcache_req_bits_data  = dcache_line_data;
  assign io_dcache_req_bits_mask  = dcache_line_mask;
  assign io_dcache_req_bits_id    = {2'h0, sbuffer_out_s1_evictionIdx};

  // accessIdx[2]（PLRU touch replaceIdx）
  wire accessIdx2_valid = invalidMask[replaceIdx]
    | (need_replace & ~need_drain & ~cohHasTimeOut & ~missqReplayHasTimeOut
       & sbuffer_out_s0_cango & activeMask[replaceIdx]);

  // ===========================================================================
  //  Resp — DCache hit_resp（释放 entry）/ replay_resp（挂超时重发）
  // ===========================================================================
  wire        hit_resp_fire = io_dcache_main_pipe_hit_resp_valid;
  wire [SB_IDX_W-1:0] hit_resp_id   = io_dcache_main_pipe_hit_resp_bits_id[SB_IDX_W-1:0];
  wire        replay_resp_fire = io_dcache_replay_resp_valid;
  wire [SB_IDX_W-1:0] replay_resp_id = io_dcache_replay_resp_bits_id[SB_IDX_W-1:0];

  // hit_resp 解除同 block w_sameblock_inflight：延迟一拍判定
  logic                hit_resp_fire_q;
  logic [SB_IDX_W-1:0] hit_resp_id_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) hit_resp_fire_q <= 1'b0;
    else hit_resp_fire_q <= hit_resp_fire;
  end
  always_ff @(posedge clock)
    if (hit_resp_fire) hit_resp_id_q <= hit_resp_id;

  // ===========================================================================
  //  entry 状态/计数统一时序更新（每 entry 一份，用 genvar 展开）
  // ---------------------------------------------------------------------------
  //   每个静态下标 ge 与各动态选择下标比较，避免对 stateVec 做动态下标写。
  // ===========================================================================
  genvar ge;
  generate
    for (ge = 0; ge < SB_SIZE; ge++) begin : g_entry
      // 本 entry 被各处理面选中
      wire sel_merge0 = accessValid[0] & canMerge[0] & mergeMask[0][ge];
      wire sel_merge1 = accessValid[1] & canMerge[1] & mergeMask[1][ge];
      wire sel_ins0   = accessValid[0] & ~canMerge[0] & insertVec[0][ge];
      wire sel_ins1   = accessValid[1] & ~canMerge[1] & insertVec[1][ge];
      wire sel_evict  = sbuffer_out_s0_fire & (sbuffer_out_s0_evictionIdx == ge[SB_IDX_W-1:0]);
      wire sel_hit    = hit_resp_fire   & (hit_resp_id    == ge[SB_IDX_W-1:0]);
      wire sel_replay = replay_resp_fire & (replay_resp_id == ge[SB_IDX_W-1:0]);

      // alloc 时同 block 在途掩码（用 inptag）；两路 alloc，第二路用 inptag[1]
      wire [SB_SIZE-1:0] sb0 = sameBlockInflight[0];
      wire [SB_SIZE-1:0] sb1 = sameBlockInflight[1];

      // waitInflightMask / ptag / vtag：golden 无复位、更新不受 reset 门控（纯时钟块）
      // golden 的 Chisel foreach 覆盖链是**port1 覆盖 port0**（后写胜）；sameTag 时
      // 两口可同拍命中同 entry，ptag/掩码两口等值可证，但 vtag 两口不等值，
      // 优先级必须与 golden 一致取 port1。
      always_ff @(posedge clock) begin
        if (sel_ins1 & (|sb1)) waitInflightMask[ge] <= sb1;
        else if (sel_ins0 & (|sb0)) waitInflightMask[ge] <= sb0;
        if (sel_ins1) begin ptag[ge] <= inptag[1]; vtag[ge] <= invtag[1]; end
        else if (sel_ins0) begin ptag[ge] <= inptag[0]; vtag[ge] <= invtag[0]; end
      end

      // stateVec / cohCount / missqReplayCount：golden 异步复位块
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          stateVec[ge]         <= '0;
          cohCount[ge]         <= '0;   // golden RegInit(0)
          missqReplayCount[ge] <= '0;   // golden RegInit(0)
        end else begin
          // ---- (1) Enq alloc：占新 entry（merge 不动 state，只 reset cohCount，见下）----
          //   两路若同时命中本 entry，sameTag 时第二路与第一路同下标，写值一致。
          if (sel_ins1) begin
            stateVec[ge].state_valid          <= 1'b1;
            stateVec[ge].w_sameblock_inflight <= |sb1;
          end else if (sel_ins0) begin
            stateVec[ge].state_valid          <= 1'b1;
            stateVec[ge].w_sameblock_inflight <= |sb0;
          end

          // ---- (2) Deq fire：置 inflight、清 w_timeout ----
          if (sel_evict) begin
            stateVec[ge].state_inflight <= 1'b1;
            stateVec[ge].w_timeout      <= 1'b0;
          end

          // ---- (3) hit_resp：释放 entry（清 valid/inflight）----
          if (sel_hit) begin
            stateVec[ge].state_inflight <= 1'b0;
            stateVec[ge].state_valid    <= 1'b0;
          end
          // 解除同 block 等待：golden 为每拍无条件 `~release & (插入mux)`，release
          // **不与 sel_hit 互斥**、且覆盖同拍 alloc 的写值——放在 alloc 之后独立 if。
          if (stateVec[ge].w_sameblock_inflight & stateVec[ge].state_valid
              & hit_resp_fire_q
              & (waitInflightMask[ge] == (16'h1 << hit_resp_id_q))) begin
            stateVec[ge].w_sameblock_inflight <= 1'b0;
          end

          // ---- (4) replay_resp：挂 w_timeout 等重发 ----
          if (sel_replay) stateVec[ge].w_timeout <= 1'b1;

          // cohCount：注意优先级与 golden 一致——「active & 未超时 → +1」**优先于**
          //   「alloc/merge → 清 0」。即对一个已 active 的 entry，即便这拍正被 merge，
          //   也是 +1（Chisel 里 +1 的 when 在源码后出现，last-wins 覆盖 merge 的 :=0）；
          //   只有 entry 这拍非 active（如刚 alloc 的空位、inflight）时 alloc 才把它清 0。
          if (st_is_active(stateVec[ge]) & ~cohTimeOutMask[ge])
            cohCount[ge] <= cohCount[ge] + 1'b1;
          else if (sel_merge0 | sel_merge1 | sel_ins0 | sel_ins1)
            cohCount[ge] <= '0;

          // missqReplayCount：同样 +1 优先于 replay_resp 清 0（与 golden 一致）。
          //   w_timeout & inflight & 未到顶 → +1；否则若收到该 entry 的 replay_resp → 清 0。
          if (stateVec[ge].w_timeout & stateVec[ge].state_inflight
              & ~missqReplayCount[ge][REPLAY_CNT_W-1])
            missqReplayCount[ge] <= missqReplayCount[ge] + 1'b1;
          else if (sel_replay)
            missqReplayCount[ge] <= '0;
        end
      end
    end
  endgenerate

  // merge vtag 失配检测（触发 micro-arch drain）
  always_comb begin
    merge_need_uarch_drain = 1'b0;
    for (int i = 0; i < ENSB_W; i++)
      for (int j = 0; j < SB_SIZE; j++)
        if (accessValid[i] & canMerge[i] & mergeMask[i][j] & (invtag[i] != vtag[j]))
          merge_need_uarch_drain = 1'b1;
  end

  // ===========================================================================
  //  cacheline data/mask 写入流水（2 拍：s1 锁存写值，s2 落 data/mask）+ mask 清除
  // ---------------------------------------------------------------------------
  //   对应 Scala SbufferData：写入端把 wvec/data/mask/wline/offset RegNext 一拍后，
  //   逐 (word,byte) 判定是否写；deq hit_resp 后延迟一拍把整行 mask 清 0。
  // ===========================================================================
  // per (port, line) 写值锁存（s1→s2）
  logic [SB_SIZE-1:0]     s2_line_wen   [ENSB_W];
  logic [VLEN-1:0]        s2_data       [ENSB_W][SB_SIZE];
  logic                   s2_wline      [ENSB_W][SB_SIZE];
  logic [VDATA_BYTES-1:0] s2_mask       [ENSB_W][SB_SIZE];
  logic [VWORDS_W-1:0]    s2_offset     [ENSB_W][SB_SIZE];

  // mask 清除：hit_resp 命中某 line → 延迟一拍清整行 mask
  logic [SB_SIZE-1:0] line_mask_clean_q;

  genvar gp, gl;
  generate
    for (gl = 0; gl < SB_SIZE; gl++) begin : g_dataline
      // mask 清除标志：本行被 hit_resp 选中（maskFlushReq.wvec = UIntToOH(resp.id)）
      always_ff @(posedge clock or posedge reset)
        if (reset) line_mask_clean_q[gl] <= 1'b0;
        // golden wvec = (64'h1 << 全 6 位 id)[15:0]：id>=16 时全 0，须比较全宽 id
        else       line_mask_clean_q[gl] <= hit_resp_fire
                     & (io_dcache_main_pipe_hit_resp_bits_id == 6'(gl));

      for (gp = 0; gp < ENSB_W; gp++) begin : g_dataport
        wire s1_wen = writeReq_valid[gp] & writeReq_wvec[gp][gl];
        always_ff @(posedge clock or posedge reset)
          if (reset) s2_line_wen[gp][gl] <= 1'b0;
          else       s2_line_wen[gp][gl] <= s1_wen;
        always_ff @(posedge clock)
          if (s1_wen) begin
            s2_data[gp][gl]   <= writeReq_data[gp];
            s2_wline[gp][gl]  <= writeReq_wline[gp];
            s2_mask[gp][gl]   <= writeReq_mask[gp];
            s2_offset[gp][gl] <= writeReq_voff[gp];
          end
      end

      // 落 data/mask：先看 mask 清除（与写入不会同拍冲突，硬件保证），再看两端口写
      for (genvar w = 0; w < CLINE_VWORDS; w++) begin : g_word
        for (genvar b = 0; b < VDATA_BYTES; b++) begin : g_byte
          // mask：golden RegInit(false) 在**异步**复位块；data 普通 Reg 无复位、
          // 写使能不被 reset 门控（golden data 在纯时钟块）——两个寄存器分块。
          always_ff @(posedge clock or posedge reset) begin
            if (reset) begin
              cline_mask[gl][w][b] <= 1'b0;
            end else begin
              if (line_mask_clean_q[gl]) begin
                cline_mask[gl][w][b] <= 1'b0;
              end
              for (int p = 0; p < ENSB_W; p++) begin
                if (s2_line_wen[p][gl] &
                    ((s2_mask[p][gl][b] & (s2_offset[p][gl] == w[VWORDS_W-1:0])) | s2_wline[p][gl])) begin
                  cline_mask[gl][w][b] <= 1'b1;
                end
              end
            end
          end
          always_ff @(posedge clock) begin
            for (int p = 0; p < ENSB_W; p++) begin
              // write_byte = s2_wen & (mask[b] & offset==w | wline)
              if (s2_line_wen[p][gl] &
                  ((s2_mask[p][gl][b] & (s2_offset[p][gl] == w[VWORDS_W-1:0])) | s2_wline[p][gl])) begin
                cline_data[gl][w][b] <= s2_data[p][gl][b*8 +: 8];
              end
            end
          end
        end
      end
    end
  endgenerate

  // ===========================================================================
  //  Load Data Forward（f0/f1）：把在途 store 的字节前递给 load 流水
  // ---------------------------------------------------------------------------
  //   f0：用 forward.vaddr 对所有 entry 做 vtag CAM，按 active/inflight 分两类候选。
  //   f1：打一拍后用 paddr 复核（ptag CAM）；valid(active) 优先于 inflight，逐字节
  //        给 forwardMask/forwardData；vtag 命中而 ptag 失配 → matchInvalid + drain。
  // ===========================================================================
  logic [VADDR_BITS-1:0] fwd_vaddr [LD_WIDTH];
  logic [PADDR_BITS-1:0] fwd_paddr [LD_WIDTH];
  logic                  fwd_valid [LD_WIDTH];
  always_comb begin
    fwd_vaddr[0]=io_forward_0_vaddr; fwd_paddr[0]=io_forward_0_paddr; fwd_valid[0]=io_forward_0_valid;
    fwd_vaddr[1]=io_forward_1_vaddr; fwd_paddr[1]=io_forward_1_paddr; fwd_valid[1]=io_forward_1_valid;
    fwd_vaddr[2]=io_forward_2_vaddr; fwd_paddr[2]=io_forward_2_paddr; fwd_valid[2]=io_forward_2_valid;
  end

  // 输出聚合
  logic [VDATA_BYTES-1:0]      fwd_o_mask [LD_WIDTH];
  logic [VDATA_BYTES-1:0][7:0] fwd_o_data [LD_WIDTH];
  logic                        fwd_o_minv [LD_WIDTH];
  logic [LD_WIDTH-1:0]         fwd_mismatch;

  genvar gf;
  generate
    for (gf = 0; gf < LD_WIDTH; gf++) begin : g_fwd
      // f0：vtag/ptag 匹配
      logic [SB_SIZE-1:0] vtag_match, ptag_match_q;
      always_comb
        for (int w = 0; w < SB_SIZE; w++)
          vtag_match[w] = (vtag[w] == get_vtag(fwd_vaddr[gf]));

      // ptag 匹配：RegEnable(ptag, fwd_valid) vs RegEnable(getPTag(paddr), fwd_valid)
      //   寄存器边界与 golden 完全一致：
      //   * ptag_q/fwd_ptag_q（↔ ptag_matches_r 对）：enable=fwd_valid，无复位；
      //   * vtag_match_q（↔ tag_mismatch_last_REG_{2w+1}）：**无使能**逐拍采样，异步复位 0；
      //   * act_or_infl_q（↔ tag_mismatch_last_REG_{2w+2} = activeMask|state_inflight）：
      //     同样无使能、异步复位 0；
      //   * fwd_valid_q（↔ tag_mismatch_last_REG）：无使能、异步复位 0；
      //   * valid_tag_match_q/inflight_tag_match_q（↔ valid/inflight_tag_match_reg =
      //     RegEnable(vtag_match & activeMask / & state_inflight, fwd_valid)）：golden 把
      //     AND **后**的结果寄存（与 vtag_match_q 是不同寄存器组），不能只存分量。
      logic [PTAG_W-1:0] ptag_q [SB_SIZE];
      logic [PTAG_W-1:0] fwd_ptag_q;
      logic              fwd_valid_q;
      logic [SB_SIZE-1:0] vtag_match_q, act_or_infl_q;
      logic [SB_SIZE-1:0] valid_tag_match_q, inflight_tag_match_q;
      always_ff @(posedge clock) begin
        if (fwd_valid[gf]) begin
          for (int w = 0; w < SB_SIZE; w++) ptag_q[w] <= ptag[w];
          fwd_ptag_q   <= get_ptag(fwd_paddr[gf]);
          for (int w = 0; w < SB_SIZE; w++) begin
            valid_tag_match_q[w]    <= vtag_match[w] & activeMask[w];
            inflight_tag_match_q[w] <= vtag_match[w] & stateVec[w].state_inflight;
          end
        end
      end
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          fwd_valid_q   <= 1'b0;
          vtag_match_q  <= '0;
          act_or_infl_q <= '0;
        end else begin
          fwd_valid_q  <= fwd_valid[gf];
          vtag_match_q <= vtag_match;
          for (int w = 0; w < SB_SIZE; w++)
            act_or_infl_q[w] <= activeMask[w] | stateVec[w].state_inflight;
        end
      end
      always_comb
        for (int w = 0; w < SB_SIZE; w++) ptag_match_q[w] = (ptag_q[w] == fwd_ptag_q);

      // vtag 命中 ^ ptag 命中 且该 entry active/inflight → 失配
      logic mism;
      always_comb begin
        mism = 1'b0;
        for (int w = 0; w < SB_SIZE; w++)
          if (fwd_valid_q & (vtag_match_q[w] != ptag_match_q[w]) & act_or_infl_q[w])
            mism = 1'b1;
      end
      assign fwd_mismatch[gf] = mism;

      // 候选 mask/data：RegEnable(行内对应 VWord 的 mask/data, fwd_valid)
      logic [VDATA_BYTES-1:0]      mask_cand_q [SB_SIZE];
      logic [VDATA_BYTES-1:0][7:0] data_cand_q [SB_SIZE];
      always_ff @(posedge clock)
        if (fwd_valid[gf])
          for (int w = 0; w < SB_SIZE; w++) begin
            mask_cand_q[w] <= cline_mask[w][get_vword_off(fwd_paddr[gf])];
            data_cand_q[w] <= cline_data[w][get_vword_off(fwd_paddr[gf])];
          end

      // Mux1H：选中 entry 的 mask/data（OR 归约，命中唯一）
      //   选择位就是 golden 的 valid/inflight_tag_match_reg（AND 后寄存的版本）
      logic [VDATA_BYTES-1:0]      selValidMask, selInflMask;
      logic [VDATA_BYTES-1:0][7:0] selValidData, selInflData;
      always_comb begin
        selValidMask='0; selInflMask='0; selValidData='0; selInflData='0;
        for (int w = 0; w < SB_SIZE; w++) begin
          if (valid_tag_match_q[w])    begin selValidMask |= mask_cand_q[w]; selValidData |= data_cand_q[w]; end
          if (inflight_tag_match_q[w]) begin selInflMask  |= mask_cand_q[w]; selInflData  |= data_cand_q[w]; end
        end
      end

      // 逐字节：mask = infl|valid（valid 优先覆盖）；
      //   data 与 golden 一致 = selValidMask[j] ? selValidData[j] : selInflData[j]
      //   （golden forwardData 不被整体 mask 门控为 0，而是按 valid 命中选 valid/inflight 数据）
      always_comb
        for (int j = 0; j < VDATA_BYTES; j++) begin
          fwd_o_mask[gf][j] = selInflMask[j] | selValidMask[j];
          fwd_o_data[gf][j] = selValidMask[j] ? selValidData[j] : selInflData[j];
        end
      assign fwd_o_minv[gf] = mism;
    end
  endgenerate

  // forward vtag 失配 → micro-arch drain
  always_comb forward_need_uarch_drain = |fwd_mismatch;

  // ---- 拆回扁平 forward 输出 ----
  assign io_forward_0_forwardMask_0=fwd_o_mask[0][0];   assign io_forward_0_forwardMask_1=fwd_o_mask[0][1];
  assign io_forward_0_forwardMask_2=fwd_o_mask[0][2];   assign io_forward_0_forwardMask_3=fwd_o_mask[0][3];
  assign io_forward_0_forwardMask_4=fwd_o_mask[0][4];   assign io_forward_0_forwardMask_5=fwd_o_mask[0][5];
  assign io_forward_0_forwardMask_6=fwd_o_mask[0][6];   assign io_forward_0_forwardMask_7=fwd_o_mask[0][7];
  assign io_forward_0_forwardMask_8=fwd_o_mask[0][8];   assign io_forward_0_forwardMask_9=fwd_o_mask[0][9];
  assign io_forward_0_forwardMask_10=fwd_o_mask[0][10]; assign io_forward_0_forwardMask_11=fwd_o_mask[0][11];
  assign io_forward_0_forwardMask_12=fwd_o_mask[0][12]; assign io_forward_0_forwardMask_13=fwd_o_mask[0][13];
  assign io_forward_0_forwardMask_14=fwd_o_mask[0][14]; assign io_forward_0_forwardMask_15=fwd_o_mask[0][15];
  assign io_forward_0_forwardData_0=fwd_o_data[0][0];   assign io_forward_0_forwardData_1=fwd_o_data[0][1];
  assign io_forward_0_forwardData_2=fwd_o_data[0][2];   assign io_forward_0_forwardData_3=fwd_o_data[0][3];
  assign io_forward_0_forwardData_4=fwd_o_data[0][4];   assign io_forward_0_forwardData_5=fwd_o_data[0][5];
  assign io_forward_0_forwardData_6=fwd_o_data[0][6];   assign io_forward_0_forwardData_7=fwd_o_data[0][7];
  assign io_forward_0_forwardData_8=fwd_o_data[0][8];   assign io_forward_0_forwardData_9=fwd_o_data[0][9];
  assign io_forward_0_forwardData_10=fwd_o_data[0][10]; assign io_forward_0_forwardData_11=fwd_o_data[0][11];
  assign io_forward_0_forwardData_12=fwd_o_data[0][12]; assign io_forward_0_forwardData_13=fwd_o_data[0][13];
  assign io_forward_0_forwardData_14=fwd_o_data[0][14]; assign io_forward_0_forwardData_15=fwd_o_data[0][15];
  assign io_forward_0_matchInvalid=fwd_o_minv[0];

  assign io_forward_1_forwardMask_0=fwd_o_mask[1][0];   assign io_forward_1_forwardMask_1=fwd_o_mask[1][1];
  assign io_forward_1_forwardMask_2=fwd_o_mask[1][2];   assign io_forward_1_forwardMask_3=fwd_o_mask[1][3];
  assign io_forward_1_forwardMask_4=fwd_o_mask[1][4];   assign io_forward_1_forwardMask_5=fwd_o_mask[1][5];
  assign io_forward_1_forwardMask_6=fwd_o_mask[1][6];   assign io_forward_1_forwardMask_7=fwd_o_mask[1][7];
  assign io_forward_1_forwardMask_8=fwd_o_mask[1][8];   assign io_forward_1_forwardMask_9=fwd_o_mask[1][9];
  assign io_forward_1_forwardMask_10=fwd_o_mask[1][10]; assign io_forward_1_forwardMask_11=fwd_o_mask[1][11];
  assign io_forward_1_forwardMask_12=fwd_o_mask[1][12]; assign io_forward_1_forwardMask_13=fwd_o_mask[1][13];
  assign io_forward_1_forwardMask_14=fwd_o_mask[1][14]; assign io_forward_1_forwardMask_15=fwd_o_mask[1][15];
  assign io_forward_1_forwardData_0=fwd_o_data[1][0];   assign io_forward_1_forwardData_1=fwd_o_data[1][1];
  assign io_forward_1_forwardData_2=fwd_o_data[1][2];   assign io_forward_1_forwardData_3=fwd_o_data[1][3];
  assign io_forward_1_forwardData_4=fwd_o_data[1][4];   assign io_forward_1_forwardData_5=fwd_o_data[1][5];
  assign io_forward_1_forwardData_6=fwd_o_data[1][6];   assign io_forward_1_forwardData_7=fwd_o_data[1][7];
  assign io_forward_1_forwardData_8=fwd_o_data[1][8];   assign io_forward_1_forwardData_9=fwd_o_data[1][9];
  assign io_forward_1_forwardData_10=fwd_o_data[1][10]; assign io_forward_1_forwardData_11=fwd_o_data[1][11];
  assign io_forward_1_forwardData_12=fwd_o_data[1][12]; assign io_forward_1_forwardData_13=fwd_o_data[1][13];
  assign io_forward_1_forwardData_14=fwd_o_data[1][14]; assign io_forward_1_forwardData_15=fwd_o_data[1][15];
  assign io_forward_1_matchInvalid=fwd_o_minv[1];

  assign io_forward_2_forwardMask_0=fwd_o_mask[2][0];   assign io_forward_2_forwardMask_1=fwd_o_mask[2][1];
  assign io_forward_2_forwardMask_2=fwd_o_mask[2][2];   assign io_forward_2_forwardMask_3=fwd_o_mask[2][3];
  assign io_forward_2_forwardMask_4=fwd_o_mask[2][4];   assign io_forward_2_forwardMask_5=fwd_o_mask[2][5];
  assign io_forward_2_forwardMask_6=fwd_o_mask[2][6];   assign io_forward_2_forwardMask_7=fwd_o_mask[2][7];
  assign io_forward_2_forwardMask_8=fwd_o_mask[2][8];   assign io_forward_2_forwardMask_9=fwd_o_mask[2][9];
  assign io_forward_2_forwardMask_10=fwd_o_mask[2][10]; assign io_forward_2_forwardMask_11=fwd_o_mask[2][11];
  assign io_forward_2_forwardMask_12=fwd_o_mask[2][12]; assign io_forward_2_forwardMask_13=fwd_o_mask[2][13];
  assign io_forward_2_forwardMask_14=fwd_o_mask[2][14]; assign io_forward_2_forwardMask_15=fwd_o_mask[2][15];
  assign io_forward_2_forwardData_0=fwd_o_data[2][0];   assign io_forward_2_forwardData_1=fwd_o_data[2][1];
  assign io_forward_2_forwardData_2=fwd_o_data[2][2];   assign io_forward_2_forwardData_3=fwd_o_data[2][3];
  assign io_forward_2_forwardData_4=fwd_o_data[2][4];   assign io_forward_2_forwardData_5=fwd_o_data[2][5];
  assign io_forward_2_forwardData_6=fwd_o_data[2][6];   assign io_forward_2_forwardData_7=fwd_o_data[2][7];
  assign io_forward_2_forwardData_8=fwd_o_data[2][8];   assign io_forward_2_forwardData_9=fwd_o_data[2][9];
  assign io_forward_2_forwardData_10=fwd_o_data[2][10]; assign io_forward_2_forwardData_11=fwd_o_data[2][11];
  assign io_forward_2_forwardData_12=fwd_o_data[2][12]; assign io_forward_2_forwardData_13=fwd_o_data[2][13];
  assign io_forward_2_forwardData_14=fwd_o_data[2][14]; assign io_forward_2_forwardData_15=fwd_o_data[2][15];
  assign io_forward_2_matchInvalid=fwd_o_minv[2];

  // ===========================================================================
  //  PLRU access（touch）：accessIdx0/1（enq）与 accessIdx2（replaceIdx）
  // ---------------------------------------------------------------------------
  //   get_next_state：把 touch way 路径上的节点 bit 设成「指向另一侧」（远离 touch）。
  //   优先级 golden：accessIdx2 > accessIdx1 > accessIdx0（后者覆盖前者无意义，三选一）。
  // ===========================================================================
  function automatic logic [14:0] plru_touch(input logic [14:0] st, input logic [3:0] way);
    logic [14:0] ns;
    ns = st;
    // 每个节点 bit 置成 ~way[此层选择位]，即「远离被 touch 的子树」。
    //   way[3]：oct 选择（1=左/高 ways15..8 → node13；0=右 ways7..0 → node6）
    //   节点编号见 way() 树叶布局注释。
    // root（node14）：left_older = ~way[3]
    ns[14] = ~way[3];
    // 第 3 层 oct：way[3]=1 → node13；=0 → node6
    if (way[3]) ns[13] = ~way[2]; else ns[6] = ~way[2];
    // 第 2 层 quad：左 oct 的 node12/9；右 oct 的 node5/2
    if (way[3]) begin
      if (way[2]) ns[12] = ~way[1]; else ns[9] = ~way[1];
    end else begin
      if (way[2]) ns[5]  = ~way[1]; else ns[2] = ~way[1];
    end
    // 第 1 层 pair：node11/10/8/7（左 oct）；node4/3/1/0（右 oct）
    if (way[3]) begin
      if (way[2]) begin if (way[1]) ns[11]=~way[0]; else ns[10]=~way[0]; end
      else        begin if (way[1]) ns[8] =~way[0]; else ns[7] =~way[0]; end
    end else begin
      if (way[2]) begin if (way[1]) ns[4] =~way[0]; else ns[3] =~way[0]; end
      else        begin if (way[1]) ns[1] =~way[0]; else ns[0] =~way[0]; end
    end
    return ns;
  endfunction

  // ValidPseudoLRU.access(Seq(touch0,touch1,touch2))：把所有 valid 的 touch 按 0→1→2
  //   顺序「依次」叠加到同一拍（不是三选一），后者基于前者结果的状态再更新。
  //   下一态是当前 plru_state 的**纯组合**函数（三个 touch 依次叠加），因此在
  //   always_comb 里算好放到 plru_next；always_ff 只寄存真状态 plru_state。
  //   （若把中间累积量声明在 always_ff 内用阻塞赋值，FM 前端会把它推成一组死寄存器。）
  logic [14:0] plru_next;
  always_comb begin
    logic [14:0] s;
    s = plru_state;
    if (accessIdx0_valid_q) s = plru_touch(s, accessIdx0_idx_q);
    if (accessIdx1_valid_q) s = plru_touch(s, accessIdx1_idx_q);
    if (accessIdx2_valid)   s = plru_touch(s, replaceAlgoIdx);
    plru_next = s;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) plru_state <= '0;
    else if (accessIdx0_valid_q | accessIdx1_valid_q | accessIdx2_valid)
      plru_state <= plru_next;
  end

  // ===========================================================================
  //  perf 事件计数（16 路，各延迟 2 拍）。非功能关键，仅与 golden 对齐。
  // ===========================================================================
  wire [4:0] validEntryCnt_c = popcnt16(~invalidMask); // !isInvalid 计数
  logic [4:0] perf_valid_entry_count;
  always_ff @(posedge clock) perf_valid_entry_count <= validEntryCnt_c;

  // perf 各事件原值（与 Scala perfEvents Seq 对应）
  wire [1:0] pe0  = {1'b0,io_in_0_valid} + {1'b0,io_in_1_valid};                 // req_valid
  wire f0 = io_in_0_valid & io_in_0_ready; wire f1 = io_in_1_valid & io_in_1_ready;
  wire [1:0] pe1r = {1'b0,f0} + {1'b0,f1};                                       // req_fire（in.fire，不含 vecValid）
  wire [1:0] pe2  = {1'b0,f0&canMerge[0]} + {1'b0,f1&canMerge[1]};               // merge
  wire [1:0] pe3  = {1'b0,f0&~canMerge[0]} + {1'b0,f1&~canMerge[1]};             // newline
  wire pe4 = io_dcache_req_valid;                                               // dcache_req_valid
  wire pe5 = io_dcache_req_ready & io_dcache_req_valid;                         // dcache_req_fire
  wire pe6 = ~(|sbuffer_state);                                                 // idle
  wire pe7 = &sbuffer_state;                                                    // drain_sbuffer
  wire pe8 = (sbuffer_state == X_REPLACE);                                      // replace
  wire pe9 = io_dcache_main_pipe_hit_resp_valid;                               // mpipe_resp
  wire pe10= io_dcache_replay_resp_valid;                                       // replay_resp
  wire pe11= cohHasTimeOut;                                                     // coh_timeout
  wire pe12= perf_valid_entry_count < 5'h4;                                     // 1/4
  wire pe13= (perf_valid_entry_count > 5'h4) & (perf_valid_entry_count < 5'h9); // 2/4
  wire pe14= (perf_valid_entry_count > 5'h8) & (perf_valid_entry_count < 7'hD); // 3/4
  wire pe15= perf_valid_entry_count > 7'hC;                                     // full

  // 2 拍延迟寄存器组
  logic [1:0] p0a,p0b,p1a,p1b,p2a,p2b,p3a,p3b;
  logic p4a,p4b,p5a,p5b,p6a,p6b,p7a,p7b,p8a,p8b,p9a,p9b,p10a,p10b,p11a,p11b,p12a,p12b,p13a,p13b,p14a,p14b,p15a,p15b;
  always_ff @(posedge clock) begin
    p0a<=pe0;   p0b<=p0a;   p1a<=pe1r;  p1b<=p1a;
    p2a<=pe2;   p2b<=p2a;   p3a<=pe3;   p3b<=p3a;
    p4a<=pe4;   p4b<=p4a;   p5a<=pe5;   p5b<=p5a;
    p6a<=pe6;   p6b<=p6a;   p7a<=pe7;   p7b<=p7a;
    p8a<=pe8;   p8b<=p8a;   p9a<=pe9;   p9b<=p9a;
    p10a<=pe10; p10b<=p10a; p11a<=pe11; p11b<=p11a;
    p12a<=pe12; p12b<=p12a; p13a<=pe13; p13b<=p13a;
    p14a<=pe14; p14b<=p14a; p15a<=pe15; p15b<=p15a;
  end
  assign io_perf_0_value ={4'h0,p0b};  assign io_perf_1_value ={4'h0,p1b};
  assign io_perf_2_value ={4'h0,p2b};  assign io_perf_3_value ={4'h0,p3b};
  assign io_perf_4_value ={5'h0,p4b};  assign io_perf_5_value ={5'h0,p5b};
  assign io_perf_6_value ={5'h0,p6b};  assign io_perf_7_value ={5'h0,p7b};
  assign io_perf_8_value ={5'h0,p8b};  assign io_perf_9_value ={5'h0,p9b};
  assign io_perf_10_value={5'h0,p10b}; assign io_perf_11_value={5'h0,p11b};
  assign io_perf_12_value={5'h0,p12b}; assign io_perf_13_value={5'h0,p13b};
  assign io_perf_14_value={5'h0,p14b}; assign io_perf_15_value={5'h0,p15b};

endmodule
