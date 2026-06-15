// =============================================================================
//  Uncache —— 非缓存 / MMIO 访问单元（可读重写核 xs_Uncache_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/cache/dcache/Uncache.scala
//  类型/常量/纯函数集中在 uncache_pkg（见 uncache_pkg.sv 文件头的整体说明）。
//
//  本核维护一张 UNC_SIZE 项的 ubuffer：每项 entries[i] 是 payload（unc_entry_t），
//  states[i] 是它的小状态机（unc_state_t 四 bool）。三个并发处理面：
//    · Enter   (e0/e1)  请求进 buffer：merge 到同 block 老 entry 或 alloc 新 entry；
//    · UncReq  (q0)     择一可上总线的 entry，组 TileLink Get/Put 发 A 通道；
//    · UncResp / Return 收 D 写回 entry，再择机 resp 回 LSQ；
//  外加 forward 面（f0/f1）：把在途 store 数据按 vaddr/paddr CAM 前递给 load 流水。
//
//  ⚠ 端口集合/命名与 golden Uncache 完全一致（扁平 io_*/auto_*），便于 wrapper 直通、
//    UT 双例化逐位比对、FM 按签名配对。可读性体现在「内部」用 struct/enum/function/
//    generate 表达微架构，而非照抄 golden 的 _GEN_/_T_ 展平 wire。
// =============================================================================
module xs_Uncache_core
  import uncache_pkg::*;
(
  input         clock,
  input         reset,
  // ---- TileLink-UL 主端口 A 通道（uncache → 总线）----
  input         auto_client_out_a_ready,
  output        auto_client_out_a_valid,
  output [3:0]  auto_client_out_a_bits_opcode,
  output [1:0]  auto_client_out_a_bits_size,
  output [1:0]  auto_client_out_a_bits_source,
  output [47:0] auto_client_out_a_bits_address,
  output        auto_client_out_a_bits_user_memPageType_NC,
  output        auto_client_out_a_bits_user_memBackType_MM,
  output [7:0]  auto_client_out_a_bits_mask,
  output [63:0] auto_client_out_a_bits_data,
  // ---- TileLink-UL 主端口 D 通道（总线 → uncache）----
  input         auto_client_out_d_valid,
  input  [1:0]  auto_client_out_d_bits_source,
  input         auto_client_out_d_bits_denied,
  input  [63:0] auto_client_out_d_bits_data,
  input         auto_client_out_d_bits_corrupt,
  // ---- 控制 ----
  input         io_enableOutstanding,
  input         io_flush_valid,
  output        io_flush_empty,
  // ---- LSQ 请求/响应 ----
  output        io_lsq_req_ready,
  input         io_lsq_req_valid,
  input  [4:0]  io_lsq_req_bits_cmd,
  input  [47:0] io_lsq_req_bits_addr,
  input  [49:0] io_lsq_req_bits_vaddr,
  input  [63:0] io_lsq_req_bits_data,
  input  [7:0]  io_lsq_req_bits_mask,
  input  [6:0]  io_lsq_req_bits_id,
  input         io_lsq_req_bits_nc,
  input         io_lsq_req_bits_memBackTypeMM,
  output        io_lsq_idResp_valid,
  output [6:0]  io_lsq_idResp_bits_mid,
  output [1:0]  io_lsq_idResp_bits_sid,
  output        io_lsq_idResp_bits_is2lq,
  output        io_lsq_idResp_bits_nc,
  input         io_lsq_resp_ready,
  output        io_lsq_resp_valid,
  output [63:0] io_lsq_resp_bits_data,
  output [1:0]  io_lsq_resp_bits_id,
  output        io_lsq_resp_bits_nc,
  output        io_lsq_resp_bits_is2lq,
  output        io_lsq_resp_bits_nderr,
  // ---- load 前递（3 路）：vaddr/paddr 进，forwardMask/Data 出 ----
  input  [49:0] io_forward_0_vaddr,
  input  [47:0] io_forward_0_paddr,
  input         io_forward_0_valid,
  output        io_forward_0_forwardMask_0,
  output        io_forward_0_forwardMask_1,
  output        io_forward_0_forwardMask_2,
  output        io_forward_0_forwardMask_3,
  output        io_forward_0_forwardMask_4,
  output        io_forward_0_forwardMask_5,
  output        io_forward_0_forwardMask_6,
  output        io_forward_0_forwardMask_7,
  output        io_forward_0_forwardMask_8,
  output        io_forward_0_forwardMask_9,
  output        io_forward_0_forwardMask_10,
  output        io_forward_0_forwardMask_11,
  output        io_forward_0_forwardMask_12,
  output        io_forward_0_forwardMask_13,
  output        io_forward_0_forwardMask_14,
  output        io_forward_0_forwardMask_15,
  output [7:0]  io_forward_0_forwardData_0,
  output [7:0]  io_forward_0_forwardData_1,
  output [7:0]  io_forward_0_forwardData_2,
  output [7:0]  io_forward_0_forwardData_3,
  output [7:0]  io_forward_0_forwardData_4,
  output [7:0]  io_forward_0_forwardData_5,
  output [7:0]  io_forward_0_forwardData_6,
  output [7:0]  io_forward_0_forwardData_7,
  output [7:0]  io_forward_0_forwardData_8,
  output [7:0]  io_forward_0_forwardData_9,
  output [7:0]  io_forward_0_forwardData_10,
  output [7:0]  io_forward_0_forwardData_11,
  output [7:0]  io_forward_0_forwardData_12,
  output [7:0]  io_forward_0_forwardData_13,
  output [7:0]  io_forward_0_forwardData_14,
  output [7:0]  io_forward_0_forwardData_15,
  output        io_forward_0_matchInvalid,
  input  [49:0] io_forward_1_vaddr,
  input  [47:0] io_forward_1_paddr,
  input         io_forward_1_valid,
  output        io_forward_1_forwardMask_0,
  output        io_forward_1_forwardMask_1,
  output        io_forward_1_forwardMask_2,
  output        io_forward_1_forwardMask_3,
  output        io_forward_1_forwardMask_4,
  output        io_forward_1_forwardMask_5,
  output        io_forward_1_forwardMask_6,
  output        io_forward_1_forwardMask_7,
  output        io_forward_1_forwardMask_8,
  output        io_forward_1_forwardMask_9,
  output        io_forward_1_forwardMask_10,
  output        io_forward_1_forwardMask_11,
  output        io_forward_1_forwardMask_12,
  output        io_forward_1_forwardMask_13,
  output        io_forward_1_forwardMask_14,
  output        io_forward_1_forwardMask_15,
  output [7:0]  io_forward_1_forwardData_0,
  output [7:0]  io_forward_1_forwardData_1,
  output [7:0]  io_forward_1_forwardData_2,
  output [7:0]  io_forward_1_forwardData_3,
  output [7:0]  io_forward_1_forwardData_4,
  output [7:0]  io_forward_1_forwardData_5,
  output [7:0]  io_forward_1_forwardData_6,
  output [7:0]  io_forward_1_forwardData_7,
  output [7:0]  io_forward_1_forwardData_8,
  output [7:0]  io_forward_1_forwardData_9,
  output [7:0]  io_forward_1_forwardData_10,
  output [7:0]  io_forward_1_forwardData_11,
  output [7:0]  io_forward_1_forwardData_12,
  output [7:0]  io_forward_1_forwardData_13,
  output [7:0]  io_forward_1_forwardData_14,
  output [7:0]  io_forward_1_forwardData_15,
  output        io_forward_1_matchInvalid,
  input  [49:0] io_forward_2_vaddr,
  input  [47:0] io_forward_2_paddr,
  input         io_forward_2_valid,
  output        io_forward_2_forwardMask_0,
  output        io_forward_2_forwardMask_1,
  output        io_forward_2_forwardMask_2,
  output        io_forward_2_forwardMask_3,
  output        io_forward_2_forwardMask_4,
  output        io_forward_2_forwardMask_5,
  output        io_forward_2_forwardMask_6,
  output        io_forward_2_forwardMask_7,
  output        io_forward_2_forwardMask_8,
  output        io_forward_2_forwardMask_9,
  output        io_forward_2_forwardMask_10,
  output        io_forward_2_forwardMask_11,
  output        io_forward_2_forwardMask_12,
  output        io_forward_2_forwardMask_13,
  output        io_forward_2_forwardMask_14,
  output        io_forward_2_forwardMask_15,
  output [7:0]  io_forward_2_forwardData_0,
  output [7:0]  io_forward_2_forwardData_1,
  output [7:0]  io_forward_2_forwardData_2,
  output [7:0]  io_forward_2_forwardData_3,
  output [7:0]  io_forward_2_forwardData_4,
  output [7:0]  io_forward_2_forwardData_5,
  output [7:0]  io_forward_2_forwardData_6,
  output [7:0]  io_forward_2_forwardData_7,
  output [7:0]  io_forward_2_forwardData_8,
  output [7:0]  io_forward_2_forwardData_9,
  output [7:0]  io_forward_2_forwardData_10,
  output [7:0]  io_forward_2_forwardData_11,
  output [7:0]  io_forward_2_forwardData_12,
  output [7:0]  io_forward_2_forwardData_13,
  output [7:0]  io_forward_2_forwardData_14,
  output [7:0]  io_forward_2_forwardData_15,
  output        io_forward_2_matchInvalid,
  // ---- WFI（wait-for-interrupt）握手 ----
  input         io_wfi_wfiReq,
  output        io_wfi_wfiSafe,
  // ---- 总线错误上报 ----
  output        io_busError_ecc_error_valid,
  output [47:0] io_busError_ecc_error_bits
);

  // ===========================================================================
  //  端口聚合：把扁平 forward 端口收成数组，便于用 for/genvar 统一处理
  // ===========================================================================
  logic [VADDR_BITS-1:0] fwd_vaddr [LD_WIDTH];
  logic [PADDR_BITS-1:0] fwd_paddr [LD_WIDTH];
  logic                  fwd_valid [LD_WIDTH];
  // 输出（每路 16 字节 mask/data + matchInvalid）
  logic [VDATA_BYTES-1:0]       fwd_o_mask  [LD_WIDTH];
  logic [VDATA_BYTES-1:0][7:0]  fwd_o_data  [LD_WIDTH];
  logic                         fwd_o_minv  [LD_WIDTH];

  always_comb begin
    fwd_vaddr[0] = io_forward_0_vaddr; fwd_paddr[0] = io_forward_0_paddr; fwd_valid[0] = io_forward_0_valid;
    fwd_vaddr[1] = io_forward_1_vaddr; fwd_paddr[1] = io_forward_1_paddr; fwd_valid[1] = io_forward_1_valid;
    fwd_vaddr[2] = io_forward_2_vaddr; fwd_paddr[2] = io_forward_2_paddr; fwd_valid[2] = io_forward_2_valid;
  end

  // ===========================================================================
  //  数据结构：ubuffer 的 entry payload 与状态
  // ===========================================================================
  unc_entry_t entries [UNC_SIZE];
  unc_state_t states  [UNC_SIZE];
  logic       noPending [UNC_SIZE];   // 该 entry 是否「无在途」（A 已发未回则为 0），WFI 用

  // 别名：把 TileLink 通道映射到设计语义名（与 Scala 一致）
  wire        req_valid   = io_lsq_req_valid;
  wire        mem_a_ready = auto_client_out_a_ready;
  wire        mem_d_valid = auto_client_out_d_valid;
  wire [1:0]  mem_d_src   = auto_client_out_d_bits_source;

  // ===========================================================================
  //  状态「能否」判定（对应 Scala UncacheEntryState 的方法），用纯组合表达
  // ===========================================================================
  function automatic logic st_is_valid     (input unc_state_t s); return s.valid; endfunction
  function automatic logic st_is_wait_return(input unc_state_t s); return s.valid &  s.waitReturn; endfunction
  function automatic logic st_can2bus       (input unc_state_t s); return s.valid & ~s.inflight & ~s.waitSame & ~s.waitReturn; endfunction
  function automatic logic st_can2lsq       (input unc_state_t s); return s.valid &  s.waitReturn; endfunction
  function automatic logic st_can_merge     (input unc_state_t s); return s.valid & ~s.inflight; endfunction
  function automatic logic st_is_fwd_old    (input unc_state_t s); return s.valid & ( s.inflight | s.waitReturn); endfunction
  function automatic logic st_is_fwd_new    (input unc_state_t s); return s.valid & ~s.inflight & ~s.waitReturn; endfunction

  // ===========================================================================
  //  drain buffer：forward 发现 vaddr/paddr CAM 失配，或外部 flush，需把 buffer 抽干
  //  （drain 期间拒绝新请求入 buffer，直到 empty）。对应 Scala do_uarch_drain。
  // ===========================================================================
  logic empty;
  logic f1_needDrain;
  logic do_uarch_drain;
  always_ff @(posedge clock) begin
    if (reset) do_uarch_drain <= 1'b0;
    // next = ((f1_needDrain | flush) & ~empty)；写成单表达式以利形式化按签名配对
    else       do_uarch_drain <= (f1_needDrain || io_flush_valid) && !empty;
  end

  // ===========================================================================
  //  非 outstanding 全局串行状态机 uState
  // ===========================================================================
  ustate_e uState;
  // 前向声明：q0 发 A、resp 回 LSQ 的 fire 在后文定义
  logic mem_acquire_fire;
  logic resp_fire;
  always_ff @(posedge clock) begin
    if (reset) uState <= US_IDLE;
    else begin
      unique case (uState)
        US_IDLE:        if (mem_acquire_fire) uState <= US_INFLIGHT;
        US_INFLIGHT:    if (mem_d_valid)      uState <= US_WAIT_RETURN; // mem_grant.ready 恒 1，fire==valid
        US_WAIT_RETURN: if (resp_fire)        uState <= US_IDLE;
        default:        uState <= US_IDLE;
      endcase
    end
  end

  // ===========================================================================
  //  Enter Buffer — e0：对 3/merge/alloc 做判定（单拍解决，better performance 版）
  // ---------------------------------------------------------------------------
  //  对每个 entry 判断它与新请求的关系：
  //    reject        ：同 block 但不能合并（属性不符 / 掩码不连续 / 老 entry 在回程）
  //    merge         ：同 block 且能合并到该 entry（primary & secondary 均满足）
  //    allocWaitSame ：同 block 且 primary 满足但 secondary 不满足 → 新分配并挂 waitSame
  // ===========================================================================
  // 先把 q0 选中的 entry 与 fire 前向声明，merge 判定要用
  logic [IDX_W-1:0] q0_canSentIdx;
  logic             q0_canSent;

  // req → entry 的「待写值」（用于 set/update）
  unc_entry_t e0_req_entry;
  always_comb begin
    e0_req_entry.cmd           = io_lsq_req_bits_cmd;
    e0_req_entry.addr          = io_lsq_req_bits_addr;
    e0_req_entry.vaddr         = io_lsq_req_bits_vaddr;
    e0_req_entry.data          = io_lsq_req_bits_data;
    e0_req_entry.mask          = io_lsq_req_bits_mask;
    e0_req_entry.nc            = io_lsq_req_bits_nc;
    e0_req_entry.memBackTypeMM = io_lsq_req_bits_memBackTypeMM;
    e0_req_entry.resp_nderr    = 1'b0;
  end

  logic [UNC_SIZE-1:0] e0_rejectVec, e0_mergeVec, e0_allocWaitSameVec, e0_invalidVec;
  always_comb begin
    for (int i = 0; i < UNC_SIZE; i++) begin
      // canMergePrimary：vaddr 同 block、cmd 同、双方都是 nc、memBackTypeMM 同、
      //   合并后掩码连续对齐，且老 entry 这拍不在「收到 D」或「等回写」（无唤醒冲突）。
      logic v, am, cm1, cm2;
      logic d_fire_eid;
      d_fire_eid = mem_d_valid & (mem_d_src == i[1:0]);
      v   = req_valid & st_is_valid(states[i]);
      am  = addr_match_p(io_lsq_req_bits_addr, entries[i].addr);
      cm1 = addr_match_v(io_lsq_req_bits_vaddr, entries[i].vaddr) &&
            (io_lsq_req_bits_cmd == entries[i].cmd) &&
            io_lsq_req_bits_nc && entries[i].nc &&
            (io_lsq_req_bits_memBackTypeMM == entries[i].memBackTypeMM) &&
            continue_and_align(io_lsq_req_bits_mask | entries[i].mask) &&
            !(d_fire_eid || st_is_wait_return(states[i]));
      // canMergeSecondary：老 entry 可合并(valid & !inflight) 且这拍不是正被 q0 选去发送。
      cm2 = st_can_merge(states[i]) && !(q0_canSent && (q0_canSentIdx == i[1:0]));

      e0_rejectVec[i]        = v & am & ~cm1;
      e0_mergeVec[i]         = v & am &  cm1 &  cm2;
      e0_allocWaitSameVec[i] = v & am &  cm1 & ~cm2;
      e0_invalidVec[i]       = ~st_is_valid(states[i]);
    end
  end

  // merge/alloc 优先级编码（PriorityEncoderWithFlag：选最低位的 1）
  logic [IDX_W-1:0] e0_mergeIdx, e0_allocIdx;
  logic             e0_canMerge, e0_canAlloc, e0_allocWaitSame;
  always_comb begin
    e0_mergeIdx = '0; e0_canMerge = 1'b0;
    for (int i = UNC_SIZE-1; i >= 0; i--)
      if (e0_mergeVec[i]) begin e0_mergeIdx = i[IDX_W-1:0]; e0_canMerge = 1'b1; end
    e0_allocIdx = '0; e0_canAlloc = 1'b0;
    for (int i = UNC_SIZE-1; i >= 0; i--)
      if (e0_invalidVec[i]) begin e0_allocIdx = i[IDX_W-1:0]; e0_canAlloc = 1'b1; end
    e0_allocWaitSame = |e0_allocWaitSameVec;
  end

  // sid（分配/合并到的下标）；reject：drain 中 / 满且不可合并 / 任一 entry 显式拒绝
  wire [IDX_W-1:0] e0_sid    = e0_canMerge ? e0_mergeIdx : e0_allocIdx;
  wire             e0_reject = do_uarch_drain || (!e0_canMerge && !(|e0_invalidVec)) || (|e0_rejectVec);
  wire             e0_fire   = req_valid && !e0_reject;   // req.fire = valid & ready
  assign io_lsq_req_ready = ~e0_reject;

  // ===========================================================================
  //  Enter Buffer — 写 entries/states（merge 用 valid 即写；alloc 用 fire 才写）
  //   注意 merge 条件是 e0_canMerge & req_valid（不是 fire），与 Scala 一致：merge
  //   到已有 entry 不消耗 ready/握手，只是把数据合并进去。
  // ===========================================================================
  // 计算 merge 后该 entry 的新 data/mask/addr（在 always_ff 内对 mergeIdx 应用）
  //   等价于 Scala 的 (getBlockAddr(addr)<<BLOCK_OFFSET)|off：保留高位 [.. :3]、低 3 位换成
  //   合并后首个有效字节偏移。用拼接而非 >>/<<，避免移位丢失最高位。
  function automatic logic [PADDR_BITS-1:0] realign_p(input logic [PADDR_BITS-1:0] a,
                                                      input logic [BLOCK_OFFSET-1:0] off);
    return {a[PADDR_BITS-1:BLOCK_OFFSET], off};
  endfunction
  function automatic logic [VADDR_BITS-1:0] realign_v(input logic [VADDR_BITS-1:0] a,
                                                      input logic [BLOCK_OFFSET-1:0] off);
    return {a[VADDR_BITS-1:BLOCK_OFFSET], off};
  endfunction

  // ===========================================================================
  //  Uncache Req — q0：选一个可上总线的 entry，组 TileLink A 请求
  // ===========================================================================
  logic [UNC_SIZE-1:0] q0_canSentVec;
  always_comb
    for (int i = 0; i < UNC_SIZE; i++)
      q0_canSentVec[i] = (io_enableOutstanding || (uState == US_IDLE)) && st_can2bus(states[i]);

  always_comb begin
    q0_canSentIdx = '0; q0_canSent = 1'b0;
    for (int i = UNC_SIZE-1; i >= 0; i--)
      if (q0_canSentVec[i]) begin q0_canSentIdx = i[IDX_W-1:0]; q0_canSent = 1'b1; end
  end

  unc_entry_t        q0_entry;
  assign             q0_entry = entries[q0_canSentIdx];
  wire               q0_isStore = is_store(q0_entry.cmd);
  wire [1:0]         q0_lgSize  = tl_lg_size(q0_entry.mask);
  wire [7:0]         q0_loadMask = tl_get_mask(q0_entry.addr[2:0], q0_lgSize);

  // A 通道 valid：有可发 entry 且未在等 WFI。mem_acquire.ready = a_ready。
  assign auto_client_out_a_valid = q0_canSent & ~io_wfi_wfiReq;
  assign mem_acquire_fire = auto_client_out_a_valid & mem_a_ready;

  assign auto_client_out_a_bits_opcode  = q0_isStore ? TL_PUTPARTIALDATA : TL_GET;
  assign auto_client_out_a_bits_size    = q0_lgSize;
  assign auto_client_out_a_bits_source  = q0_canSentIdx;
  assign auto_client_out_a_bits_address = q0_entry.addr;
  assign auto_client_out_a_bits_user_memPageType_NC = q0_entry.nc;
  assign auto_client_out_a_bits_user_memBackType_MM = q0_entry.memBackTypeMM;
  assign auto_client_out_a_bits_mask    = q0_isStore ? q0_entry.mask : q0_loadMask;
  assign auto_client_out_a_bits_data    = q0_isStore ? q0_entry.data : 64'h0;

  // ===========================================================================
  //  Uncache Resp — 收 TileLink D：写回选中 entry，并解除同 block 的 waitSame
  // ===========================================================================
  wire mem_grant_fire = mem_d_valid;   // mem_grant.ready 恒 1

  // ===========================================================================
  //  Return to LSQ — r0：在所有 waitReturn 的 entry 里择一回写
  // ===========================================================================
  logic [UNC_SIZE-1:0] r0_canSentVec;
  logic [IDX_W-1:0]    r0_canSentIdx;
  logic                r0_canSent;
  always_comb begin
    for (int i = 0; i < UNC_SIZE; i++) r0_canSentVec[i] = st_can2lsq(states[i]);
    r0_canSentIdx = '0; r0_canSent = 1'b0;
    for (int i = UNC_SIZE-1; i >= 0; i--)
      if (r0_canSentVec[i]) begin r0_canSentIdx = i[IDX_W-1:0]; r0_canSent = 1'b1; end
  end

  assign io_lsq_resp_valid       = r0_canSent;
  assign io_lsq_resp_bits_data   = entries[r0_canSentIdx].data;
  assign io_lsq_resp_bits_id     = r0_canSentIdx;
  assign io_lsq_resp_bits_nc     = entries[r0_canSentIdx].nc;
  assign io_lsq_resp_bits_is2lq  = (entries[r0_canSentIdx].cmd == M_XRD);
  assign io_lsq_resp_bits_nderr  = entries[r0_canSentIdx].resp_nderr;
  assign resp_fire = io_lsq_resp_valid & io_lsq_resp_ready;

  // ===========================================================================
  //  状态/数据更新（统一时序块）：按优先级把 e0 / q0 / D / resp 的副作用落到寄存器
  // ===========================================================================
  //   ── 用 genvar 按 entry 展开，每个 entry 用「静态下标 i」与各动态选择下标比较 ──
  //   （e0_mergeIdx==i / e0_allocIdx==i / q0_canSentIdx==i / mem_d_src==i / r0_canSentIdx==i）
  //   这与 golden 的 per-entry _GEN_45/46/47 结构一致，且避免对 entries 做动态下标
  //   写/读（动态下标会在形式化里综合出对未初始化 reg 取值的 X 传播节点）。
  //   merge 合并的 data/mask/重对齐地址均在「本 entry 即合并目标」时用自身寄存器算。
  genvar ge;
  generate
    for (ge = 0; ge < UNC_SIZE; ge++) begin : g_entry
      // 本 entry 是否被各动态下标选中
      wire sel_merge = e0_canMerge   && req_valid && (e0_mergeIdx   == ge[IDX_W-1:0]);
      wire sel_alloc = e0_canAlloc   && e0_fire   && (e0_allocIdx   == ge[IDX_W-1:0]);
      wire sel_qfire = mem_acquire_fire           && (q0_canSentIdx == ge[IDX_W-1:0]);
      wire sel_dfire = mem_grant_fire             && (mem_d_src     == ge[IDX_W-1:0]);
      wire sel_rfire = resp_fire                  && (r0_canSentIdx == ge[IDX_W-1:0]);

      // merge：用本 entry 自身寄存器（静态 ge）算合并值
      wire [XLEN-1:0]         m_nd  = merge_data(entries[ge].data, io_lsq_req_bits_data, io_lsq_req_bits_mask);
      wire [DATA_BYTES-1:0]   m_nm  = entries[ge].mask | io_lsq_req_bits_mask;
      wire [BLOCK_OFFSET-1:0] m_off = res_offset(m_nm);

      always_ff @(posedge clock) begin
        if (reset) begin
          states[ge]    <= '0;
          noPending[ge] <= 1'b1;
        end else begin
          // ---- (1) Enter：merge 优先于 alloc ----
          if (sel_merge) begin
            entries[ge].data <= m_nd;
            entries[ge].mask <= m_nm;
            if (res_flag(m_nm)) begin
              entries[ge].addr  <= realign_p(entries[ge].addr,  m_off);
              entries[ge].vaddr <= realign_v(entries[ge].vaddr, m_off);
            end
          end else if (sel_alloc) begin
            entries[ge]        <= e0_req_entry;
            states[ge].valid   <= 1'b1;
            if (e0_allocWaitSame) states[ge].waitSame <= 1'b1;
          end

          // ---- (2) UncReq fire：被发送的 entry 置 inflight/清 noPending；
          //          其余同 block 且未在回程的 valid entry 挂 waitSame ----
          if (sel_qfire) begin
            states[ge].inflight <= 1'b1;
            noPending[ge]       <= 1'b0;
          end else if (mem_acquire_fire && st_is_valid(states[ge]) &&
                       !st_is_wait_return(states[ge]) && addr_match_p(q0_entry.addr, entries[ge].addr)) begin
            states[ge].waitSame <= 1'b1;
          end

          // ---- (3) UncResp fire：被回应的 entry 写回 data/nderr 并 inflight→waitReturn；
          //          其余同 block 的 waitSame 等待者解除 ----
          if (sel_dfire) begin
            if (entries[ge].cmd == M_XRD) entries[ge].data <= auto_client_out_d_bits_data;
            entries[ge].resp_nderr <= auto_client_out_d_bits_denied | auto_client_out_d_bits_corrupt;
            states[ge].inflight    <= 1'b0;
            states[ge].waitReturn  <= 1'b1;
            noPending[ge]          <= 1'b1;
          end else if (mem_grant_fire && st_is_valid(states[ge]) && states[ge].waitSame &&
                       addr_match_p(entries[mem_d_src].addr, entries[ge].addr)) begin
            states[ge].waitSame <= 1'b0;
          end

          // ---- (4) Return fire：清空该 entry 全部状态 ----
          if (sel_rfire) states[ge] <= '0;
        end
      end
    end
  endgenerate

  // ===========================================================================
  //  Enter Buffer — e1：打一拍把分配/合并结果通过 idResp 返回 LSQ（握手 sid）
  // ===========================================================================
  logic              idResp_valid_q;
  logic [MID_W-1:0]  idResp_mid_q;
  logic [IDX_W-1:0]  idResp_sid_q;
  logic              idResp_is2lq_q;
  logic              idResp_nc_q;
  always_ff @(posedge clock) begin
    if (reset) idResp_valid_q <= 1'b0;
    else       idResp_valid_q <= e0_fire;
    if (e0_fire) begin
      idResp_mid_q   <= io_lsq_req_bits_id;
      idResp_sid_q   <= e0_sid;
      idResp_is2lq_q <= ~is_store(io_lsq_req_bits_cmd);
      idResp_nc_q    <= io_lsq_req_bits_nc;
    end
  end
  assign io_lsq_idResp_valid     = idResp_valid_q;
  assign io_lsq_idResp_bits_mid  = idResp_mid_q;
  assign io_lsq_idResp_bits_sid  = idResp_sid_q;
  assign io_lsq_idResp_bits_is2lq= idResp_is2lq_q;
  assign io_lsq_idResp_bits_nc   = idResp_nc_q;

  // ===========================================================================
  //  empty / flush / busError / WFI
  // ===========================================================================
  logic [UNC_SIZE-1:0] valid_vec;
  always_comb for (int i = 0; i < UNC_SIZE; i++) valid_vec[i] = st_is_valid(states[i]);
  assign empty = ~(|valid_vec);
  assign io_flush_empty = empty;

  // busError：store 且总线 denied/corrupt → 上报该 entry 的 block 基址
  assign io_busError_ecc_error_valid =
    mem_grant_fire & is_store(entries[mem_d_src].cmd) &
    (auto_client_out_d_bits_denied | auto_client_out_d_bits_corrupt);
  assign io_busError_ecc_error_bits  =
    {entries[mem_d_src].addr[PADDR_BITS-1:CACHE_BLK_OFF], {CACHE_BLK_OFF{1'b0}}};

  // WFI safe：所有 entry 无在途 且 收到 wfiReq → 打一拍输出
  logic wfi_safe_q;
  always_ff @(posedge clock) begin
    if (reset) wfi_safe_q <= 1'b0;
    else begin
      logic all_no_pending;
      all_no_pending = 1'b1;
      for (int i = 0; i < UNC_SIZE; i++) if (!noPending[i]) all_no_pending = 1'b0;
      wfi_safe_q <= all_no_pending & io_wfi_wfiReq;
    end
  end
  assign io_wfi_wfiSafe = wfi_safe_q;

  // ===========================================================================
  //  Load Data Forward（f0/f1）：把在途 store 的字节前递给 load 流水
  // ---------------------------------------------------------------------------
  //   f0：用 forward.vaddr 对所有「有效 store」entry 做 block CAM；按状态分两类：
  //        fly  = 在途/等回写（isFwdOld）—— 旧数据；
  //        idle = 已 alloc 未发（isFwdNew）—— 新数据。
  //        给出 forwardMaskFast（vaddr 命中即给，时序友好）。
  //   f1：打一拍后用 paddr 复核；merge 旧/新（new 覆盖 old），按 paddr[3] 移到高/低
  //        16B 半区输出 forwardMask/forwardData；vaddr 命中而 paddr 失配 → matchInvalid，
  //        并触发 needDrain 抽干 buffer（重做）。
  // ===========================================================================
  // f0 候选：每 entry 是否「有效 store」，及其 mask/data
  logic [UNC_SIZE-1:0] f0_validMask;
  always_comb
    for (int i = 0; i < UNC_SIZE; i++)
      f0_validMask[i] = is_store(entries[i].cmd) & st_is_valid(states[i]);

  // f1 候选寄存器：仅在该 entry 是有效 store 时打拍（RegEnable(f0_validMask)）
  logic [DATA_BYTES-1:0] f1_maskCand [UNC_SIZE];
  logic [XLEN-1:0]       f1_dataCand [UNC_SIZE];
  always_ff @(posedge clock)
    for (int i = 0; i < UNC_SIZE; i++)
      if (f0_validMask[i]) begin
        f1_maskCand[i] <= entries[i].mask;
        f1_dataCand[i] <= entries[i].data;
      end

  // entry.addr 打一拍（f0 fwdValid 时），f1 复核 paddr 用
  logic [PADDR_BITS-1:0] f1_addrCand [LD_WIDTH][UNC_SIZE];

  logic [LD_WIDTH-1:0] f1_tagMismatch;
  assign f1_needDrain = (|f1_tagMismatch) & ~empty;

  genvar gi;
  generate
    for (gi = 0; gi < LD_WIDTH; gi++) begin : g_fwd
      // ---- f0 ----
      logic                f0_fwdValid;
      logic [UNC_SIZE-1:0] f0_vtagMatch, f0_flyMatch, f0_idleMatch;
      assign f0_fwdValid = fwd_valid[gi];
      always_comb
        for (int w = 0; w < UNC_SIZE; w++) begin
          f0_vtagMatch[w] = addr_match_v(entries[w].vaddr, fwd_vaddr[gi]);
          f0_flyMatch[w]  = f0_vtagMatch[w] & f0_validMask[w] & f0_fwdValid & st_is_fwd_old(states[w]);
          f0_idleMatch[w] = f0_vtagMatch[w] & f0_validMask[w] & f0_fwdValid & st_is_fwd_new(states[w]);
        end

      // ---- f0→f1 打拍 ----
      logic                f1_fwdValid;
      logic [UNC_SIZE-1:0] f1_flyMatch, f1_idleMatch, f1_vtagMatch_q, f1_validMask_q;
      logic [PADDR_BITS-1:0] f1_fwdPAddr;
      always_ff @(posedge clock) begin
        f1_fwdValid <= f0_fwdValid;
        if (f0_fwdValid) begin
          f1_flyMatch    <= f0_flyMatch;
          f1_idleMatch   <= f0_idleMatch;
          f1_vtagMatch_q <= f0_vtagMatch;
          f1_validMask_q <= f0_validMask;
          f1_fwdPAddr    <= fwd_paddr[gi];
          for (int w = 0; w < UNC_SIZE; w++) f1_addrCand[gi][w] <= entries[w].addr;
        end
      end

      // ---- f1：Mux1H 选 fly/idle 的 mask/data，merge（new 覆盖 old）----
      logic [DATA_BYTES-1:0] f1_flyMask, f1_idleMask;
      logic [XLEN-1:0]       f1_flyData, f1_idleData;
      always_comb begin
        f1_flyMask = '0; f1_idleMask = '0; f1_flyData = '0; f1_idleData = '0;
        for (int w = 0; w < UNC_SIZE; w++) begin
          if (f1_flyMatch[w])  begin f1_flyMask  |= f1_maskCand[w]; f1_flyData  |= f1_dataCand[w]; end
          if (f1_idleMatch[w]) begin f1_idleMask |= f1_maskCand[w]; f1_idleData |= f1_dataCand[w]; end
        end
      end
      // merge：idle(new) 覆盖 fly(old)；mask = fly|idle
      logic [XLEN-1:0]       f1_mergeData;
      logic [DATA_BYTES-1:0] f1_mergeMask;
      assign f1_mergeData = merge_data(f1_flyData, f1_idleData, f1_idleMask);
      assign f1_mergeMask = f1_flyMask | f1_idleMask;

      // 按 paddr[3] 移到 16B 高/低半区
      logic [VDATA_BYTES-1:0]      f1_fwdMask;
      logic [VDATA_BYTES-1:0][7:0] f1_fwdData;
      assign f1_fwdMask = ({{(VDATA_BYTES-DATA_BYTES){1'b0}}, f1_mergeMask})
                          << (f1_fwdPAddr[3] ? DATA_BYTES : 0);
      assign f1_fwdData = {{(XLEN){1'b0}}, f1_mergeData} << (f1_fwdPAddr[3] ? XLEN : 0);

      // paddr 复核：vaddr 命中 ^ paddr 命中 且该项是有效 store → 失配
      logic [UNC_SIZE-1:0] f1_ptagMatch;
      always_comb
        for (int w = 0; w < UNC_SIZE; w++)
          f1_ptagMatch[w] = addr_match_p(f1_addrCand[gi][w], f1_fwdPAddr);
      always_comb begin
        f1_tagMismatch[gi] = 1'b0;
        for (int w = 0; w < UNC_SIZE; w++)
          if ((f1_vtagMatch_q[w] != f1_ptagMatch[w]) && f1_validMask_q[w] && f1_fwdValid)
            f1_tagMismatch[gi] = 1'b1;
      end

      // ---- 输出 ----
      //   本配置 golden 暴露的 forwardMask = f1_fwdMask & f1_fwdValid（paddr 复核后的
      //   稳定结果），forwardData = f1_fwdData，matchInvalid = f1_tagMismatch。
      //   （forwardMaskFast 是另一个端口，本顶层配置已裁剪，不在端口表里。）
      assign fwd_o_minv[gi] = f1_tagMismatch[gi];
      always_comb
        for (int j = 0; j < VDATA_BYTES; j++) begin
          fwd_o_mask[gi][j] = f1_fwdMask[j] & f1_fwdValid;
          fwd_o_data[gi][j] = f1_fwdData[j];
        end
    end
  endgenerate

  // ---- 拆回扁平输出端口 ----
  assign io_forward_0_forwardMask_0  = fwd_o_mask[0][0];
  assign io_forward_0_forwardMask_1  = fwd_o_mask[0][1];
  assign io_forward_0_forwardMask_2  = fwd_o_mask[0][2];
  assign io_forward_0_forwardMask_3  = fwd_o_mask[0][3];
  assign io_forward_0_forwardMask_4  = fwd_o_mask[0][4];
  assign io_forward_0_forwardMask_5  = fwd_o_mask[0][5];
  assign io_forward_0_forwardMask_6  = fwd_o_mask[0][6];
  assign io_forward_0_forwardMask_7  = fwd_o_mask[0][7];
  assign io_forward_0_forwardMask_8  = fwd_o_mask[0][8];
  assign io_forward_0_forwardMask_9  = fwd_o_mask[0][9];
  assign io_forward_0_forwardMask_10 = fwd_o_mask[0][10];
  assign io_forward_0_forwardMask_11 = fwd_o_mask[0][11];
  assign io_forward_0_forwardMask_12 = fwd_o_mask[0][12];
  assign io_forward_0_forwardMask_13 = fwd_o_mask[0][13];
  assign io_forward_0_forwardMask_14 = fwd_o_mask[0][14];
  assign io_forward_0_forwardMask_15 = fwd_o_mask[0][15];
  assign io_forward_0_forwardData_0  = fwd_o_data[0][0];
  assign io_forward_0_forwardData_1  = fwd_o_data[0][1];
  assign io_forward_0_forwardData_2  = fwd_o_data[0][2];
  assign io_forward_0_forwardData_3  = fwd_o_data[0][3];
  assign io_forward_0_forwardData_4  = fwd_o_data[0][4];
  assign io_forward_0_forwardData_5  = fwd_o_data[0][5];
  assign io_forward_0_forwardData_6  = fwd_o_data[0][6];
  assign io_forward_0_forwardData_7  = fwd_o_data[0][7];
  assign io_forward_0_forwardData_8  = fwd_o_data[0][8];
  assign io_forward_0_forwardData_9  = fwd_o_data[0][9];
  assign io_forward_0_forwardData_10 = fwd_o_data[0][10];
  assign io_forward_0_forwardData_11 = fwd_o_data[0][11];
  assign io_forward_0_forwardData_12 = fwd_o_data[0][12];
  assign io_forward_0_forwardData_13 = fwd_o_data[0][13];
  assign io_forward_0_forwardData_14 = fwd_o_data[0][14];
  assign io_forward_0_forwardData_15 = fwd_o_data[0][15];
  assign io_forward_0_matchInvalid   = fwd_o_minv[0];

  assign io_forward_1_forwardMask_0  = fwd_o_mask[1][0];
  assign io_forward_1_forwardMask_1  = fwd_o_mask[1][1];
  assign io_forward_1_forwardMask_2  = fwd_o_mask[1][2];
  assign io_forward_1_forwardMask_3  = fwd_o_mask[1][3];
  assign io_forward_1_forwardMask_4  = fwd_o_mask[1][4];
  assign io_forward_1_forwardMask_5  = fwd_o_mask[1][5];
  assign io_forward_1_forwardMask_6  = fwd_o_mask[1][6];
  assign io_forward_1_forwardMask_7  = fwd_o_mask[1][7];
  assign io_forward_1_forwardMask_8  = fwd_o_mask[1][8];
  assign io_forward_1_forwardMask_9  = fwd_o_mask[1][9];
  assign io_forward_1_forwardMask_10 = fwd_o_mask[1][10];
  assign io_forward_1_forwardMask_11 = fwd_o_mask[1][11];
  assign io_forward_1_forwardMask_12 = fwd_o_mask[1][12];
  assign io_forward_1_forwardMask_13 = fwd_o_mask[1][13];
  assign io_forward_1_forwardMask_14 = fwd_o_mask[1][14];
  assign io_forward_1_forwardMask_15 = fwd_o_mask[1][15];
  assign io_forward_1_forwardData_0  = fwd_o_data[1][0];
  assign io_forward_1_forwardData_1  = fwd_o_data[1][1];
  assign io_forward_1_forwardData_2  = fwd_o_data[1][2];
  assign io_forward_1_forwardData_3  = fwd_o_data[1][3];
  assign io_forward_1_forwardData_4  = fwd_o_data[1][4];
  assign io_forward_1_forwardData_5  = fwd_o_data[1][5];
  assign io_forward_1_forwardData_6  = fwd_o_data[1][6];
  assign io_forward_1_forwardData_7  = fwd_o_data[1][7];
  assign io_forward_1_forwardData_8  = fwd_o_data[1][8];
  assign io_forward_1_forwardData_9  = fwd_o_data[1][9];
  assign io_forward_1_forwardData_10 = fwd_o_data[1][10];
  assign io_forward_1_forwardData_11 = fwd_o_data[1][11];
  assign io_forward_1_forwardData_12 = fwd_o_data[1][12];
  assign io_forward_1_forwardData_13 = fwd_o_data[1][13];
  assign io_forward_1_forwardData_14 = fwd_o_data[1][14];
  assign io_forward_1_forwardData_15 = fwd_o_data[1][15];
  assign io_forward_1_matchInvalid   = fwd_o_minv[1];

  assign io_forward_2_forwardMask_0  = fwd_o_mask[2][0];
  assign io_forward_2_forwardMask_1  = fwd_o_mask[2][1];
  assign io_forward_2_forwardMask_2  = fwd_o_mask[2][2];
  assign io_forward_2_forwardMask_3  = fwd_o_mask[2][3];
  assign io_forward_2_forwardMask_4  = fwd_o_mask[2][4];
  assign io_forward_2_forwardMask_5  = fwd_o_mask[2][5];
  assign io_forward_2_forwardMask_6  = fwd_o_mask[2][6];
  assign io_forward_2_forwardMask_7  = fwd_o_mask[2][7];
  assign io_forward_2_forwardMask_8  = fwd_o_mask[2][8];
  assign io_forward_2_forwardMask_9  = fwd_o_mask[2][9];
  assign io_forward_2_forwardMask_10 = fwd_o_mask[2][10];
  assign io_forward_2_forwardMask_11 = fwd_o_mask[2][11];
  assign io_forward_2_forwardMask_12 = fwd_o_mask[2][12];
  assign io_forward_2_forwardMask_13 = fwd_o_mask[2][13];
  assign io_forward_2_forwardMask_14 = fwd_o_mask[2][14];
  assign io_forward_2_forwardMask_15 = fwd_o_mask[2][15];
  assign io_forward_2_forwardData_0  = fwd_o_data[2][0];
  assign io_forward_2_forwardData_1  = fwd_o_data[2][1];
  assign io_forward_2_forwardData_2  = fwd_o_data[2][2];
  assign io_forward_2_forwardData_3  = fwd_o_data[2][3];
  assign io_forward_2_forwardData_4  = fwd_o_data[2][4];
  assign io_forward_2_forwardData_5  = fwd_o_data[2][5];
  assign io_forward_2_forwardData_6  = fwd_o_data[2][6];
  assign io_forward_2_forwardData_7  = fwd_o_data[2][7];
  assign io_forward_2_forwardData_8  = fwd_o_data[2][8];
  assign io_forward_2_forwardData_9  = fwd_o_data[2][9];
  assign io_forward_2_forwardData_10 = fwd_o_data[2][10];
  assign io_forward_2_forwardData_11 = fwd_o_data[2][11];
  assign io_forward_2_forwardData_12 = fwd_o_data[2][12];
  assign io_forward_2_forwardData_13 = fwd_o_data[2][13];
  assign io_forward_2_forwardData_14 = fwd_o_data[2][14];
  assign io_forward_2_forwardData_15 = fwd_o_data[2][15];
  assign io_forward_2_matchInvalid   = fwd_o_minv[2];

endmodule
